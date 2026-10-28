extends Node3D
signal progress(value: float)
var data: Dictionary
var foliage_materials: Array[ShaderMaterial]=[]
var cached: Dictionary={}
var colliders: Dictionary={}
var flowers: Array[Vector3]=[]
var sun: DirectionalLight3D
var environment: Environment
var butterflies: Array=[]
var birds: Array=[]
var t:=0.0
var observer: Node3D
var cared:=false
var wind_repaired:=false
var wind_rotors:Array=[]

func _ready() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))

func build() -> void:
	_lighting()
	for atom in data.atoms: colliders[atom.id]=atom.get("collider","none")
	var grouped: Dictionary={}
	for item in data.instances:
		var a:String=item.atom
		var p:=v3(item.position)
		var key:=a+"@"+str(floori(p.x/18.))+","+str(floori(p.z/18.))
		if not grouped.has(key): grouped[key]=[]
		grouped[key].append(item)
		if a.begins_with("flora_") and ("flower" in a): flowers.append(p)
	var total:=grouped.size()
	var done:=0
	for key in grouped:
		var items:Array=grouped[key]
		var atom:String=items[0].atom
		var parts:=_asset(atom)
		if atom=="stock_windmill_blades":
			for item in items:
				var rotor:=Node3D.new()
				rotor.transform=_placement(item)
				add_child(rotor)
				for part in parts:
					var piece:=MeshInstance3D.new()
					piece.mesh=part.mesh
					piece.transform=part.transform
					rotor.add_child(piece)
				wind_rotors.append(rotor)
			continue
		for part in parts:
			var batch:=MultiMeshInstance3D.new()
			var mm:=MultiMesh.new()
			mm.transform_format=MultiMesh.TRANSFORM_3D
			mm.mesh=part.mesh
			mm.instance_count=items.size()
			for i in items.size():
				mm.set_instance_transform(i,_placement(items[i])*part.transform)
			batch.multimesh=mm
			batch.name=atom
			batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if (atom.begins_with("flora_") or "paving" in atom or "water" in atom) else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			batch.visibility_range_end=85. if atom.begins_with("flora_") else 260.
			batch.visibility_range_end_margin=12.
			add_child(batch)
			var collision_type:String=colliders.get(atom,"none")
			if collision_type=="mesh" and not "paving" in atom:
				var shape:Shape3D=part.mesh.create_trimesh_shape()
				for item in items:
					var body:=StaticBody3D.new()
					body.transform=_placement(item)*part.transform
					var collision:=CollisionShape3D.new()
					collision.shape=shape
					body.add_child(collision)
					add_child(body)
		if colliders.get(atom)=="trunk":
			for item in items:
				var body:=StaticBody3D.new()
				body.transform=_placement(item)
				var collision:=CollisionShape3D.new()
				var cylinder:=CylinderShape3D.new()
				cylinder.radius=.25
				cylinder.height=2.
				collision.position.y=1.
				collision.shape=cylinder
				body.add_child(collision)
				add_child(body)
		done+=1
		if done%8==0:
			progress.emit(float(done)/total)
			await get_tree().process_frame
	_wildlife()
	print("WORLD_READY instances=",data.instances.size()," batches=",total," flower_patches=",flowers.size())

func v3(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func _placement(i: Dictionary) -> Transform3D:
	var basis:=Basis(Vector3.UP,deg_to_rad(float(i.get("yaw",0))))
	if i.has("rotation"):
		var q:Array=i.rotation
		basis=Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized())
	var s:Variant=i.get("scale",1.)
	basis=basis.scaled(v3(s) if s is Array else Vector3.ONE*float(s))
	return Transform3D(basis,v3(i.position))

func _asset(atom: String) -> Array:
	if cached.has(atom): return cached[atom]
	var path:="res://assets/models/"+atom+".glb"
	if not ResourceLoader.exists(path): return []
	var scene:Node3D=load(path).instantiate()
	var parts:Array=[]
	_collect(scene,Transform3D.IDENTITY,parts,atom)
	scene.free()
	cached[atom]=parts
	return parts

func _collect(n: Node, parent: Transform3D, out: Array, atom: String) -> void:
	var tr:=parent
	if n is Node3D: tr=parent*n.transform
	if n is MeshInstance3D and n.mesh:
		var mesh:Mesh=n.mesh.duplicate()
		for s in mesh.get_surface_count():
			var original:Material=n.get_active_material(s)
			var material:Material=original.duplicate() if original else StandardMaterial3D.new()
			if atom=="terrain":
				material=ShaderMaterial.new()
				material.shader=load("res://shaders/meadow.gdshader")
				material.set_shader_parameter("painted_ground",load("res://assets/textures/painted-earth.jpg"))
			elif "water" in atom:
				material=ShaderMaterial.new()
				material.shader=load("res://shaders/water.gdshader")
			elif atom.begins_with("flora_") and original is BaseMaterial3D:
				material=ShaderMaterial.new()
				material.shader=load("res://shaders/foliage.gdshader")
				material.set_shader_parameter("albedo_tex",original.albedo_texture)
				var leaf_tint:=Color("699841")
				var material_name:String=original.resource_name.to_lower()
				if atom=="flora_starflower" and s==1:leaf_tint=Color("eee2b5")
				if atom=="flora_wildflower":leaf_tint=Color("d4adce")
				if "fern" in atom:leaf_tint=Color("4c8e58")
				material.set_shader_parameter("tint",leaf_tint)
				material.set_shader_parameter("height",maxf(mesh.get_aabb().size.y,.2))
				foliage_materials.append(material)
			elif material is BaseMaterial3D:
				material.roughness=maxf(material.roughness,.78)
				material.metallic_specular=.16
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
					material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					material.alpha_scissor_threshold=.42
					material.cull_mode=BaseMaterial3D.CULL_DISABLED
				if atom=="cloud_cumulus_soft":
					material.albedo_color=Color(.97,.98,.91)
					material.emission_enabled=true
					material.emission=Color(.18,.2,.21)
			mesh.surface_set_material(s,material)
		out.append({"mesh":mesh,"transform":tr})
	for child in n.get_children(): _collect(child,tr,out,atom)

func _lighting() -> void:
	var worldenv:=WorldEnvironment.new()
	environment=Environment.new()
	worldenv.environment=environment
	add_child(worldenv)
	environment.background_mode=Environment.BG_SKY
	var sky:=Sky.new()
	var sky_mat:=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("5192bd")
	sky_mat.sky_horizon_color=Color("c4dfe1")
	sky_mat.ground_bottom_color=Color("849882")
	sky_mat.ground_horizon_color=Color("cdded5")
	sky_mat.sky_curve=.18
	sky_mat.sun_angle_max=12.
	sky.sky_material=sky_mat
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("bddae4")
	environment.ambient_light_energy=.52
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure=.9
	# Restrained film curve: cool shadow floor and warm, compressed highlights.
	environment.adjustment_enabled=true
	environment.adjustment_contrast=1.04
	environment.adjustment_saturation=.94
	var film_gradient:=Gradient.new()
	film_gradient.offsets=PackedFloat32Array([0.0,.2,.5,.8,1.0])
	film_gradient.colors=PackedColorArray([Color(.009,.016,.023),Color(.176,.194,.201),Color(.50,.51,.49),Color(.817,.800,.758),Color(.994,.974,.930)])
	var film_curve:=GradientTexture1D.new()
	film_curve.width=256
	film_curve.gradient=film_gradient
	environment.adjustment_color_correction=film_curve
	environment.ssao_enabled=true
	environment.ssao_radius=.55
	environment.ssao_intensity=.7
	environment.glow_enabled=true
	environment.glow_intensity=.35
	environment.glow_hdr_threshold=1.35
	environment.fog_enabled=true
	# Distance haze separates the valley planes without whitening the foreground.
	environment.fog_mode=Environment.FOG_MODE_DEPTH
	environment.fog_light_color=Color("a4c7d6")
	environment.fog_depth_begin=18.0
	environment.fog_depth_end=105.0
	environment.fog_depth_curve=1.35
	environment.fog_density=.32
	environment.fog_sky_affect=.06
	environment.fog_sun_scatter=.12
	environment.volumetric_fog_enabled=not OS.has_feature("web")
	environment.volumetric_fog_density=.0025
	environment.volumetric_fog_albedo=Color("e7e5c9")
	environment.volumetric_fog_anisotropy=.65
	environment.volumetric_fog_length=95
	environment.volumetric_fog_ambient_inject=.25
	sun=DirectionalLight3D.new()
	sun.name="Morning sunlight"
	sun.rotation_degrees=Vector3(-32,-32,0)
	sun.light_color=Color("fff0c6")
	sun.light_energy=1.2
	sun.light_volumetric_fog_energy=3.0
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=80
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_blur=1.5
	add_child(sun)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-65,140,0)
	fill.light_color=Color("b6dbe6")
	fill.light_energy=.22
	add_child(fill)
	# Two canopy apertures strengthen the same morning-sun direction.
	for p in [Vector3(-6,8,-9),Vector3(8,10,-32)]:
		var beam:=SpotLight3D.new()
		beam.position=p
		beam.rotation_degrees=Vector3(-55,-30,0)
		beam.spot_range=18
		beam.spot_angle=12
		beam.spot_angle_attenuation=.65
		beam.light_color=Color("fff0bc")
		beam.light_energy=2.2
		beam.light_volumetric_fog_energy=9
		add_child(beam)
		if OS.has_feature("web"):
			# Crossed translucent shafts replace native volumetric scattering on WebGL.
			for angle in [0.,PI*.5]:
				var shaft:=MeshInstance3D.new()
				var plane:=QuadMesh.new()
				plane.size=Vector2(2.2,9.)
				shaft.mesh=plane
				shaft.position=p+Vector3(1.8,-4.,1.)
				shaft.rotation=Vector3(0,angle,-.36)
				shaft.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var mist:=ShaderMaterial.new()
				mist.shader=load("res://shaders/web_sunshaft.gdshader")
				shaft.material_override=mist
				add_child(shaft)

func ground_at(p: Vector3) -> Vector3:
	var query:=PhysicsRayQueryParameters3D.create(Vector3(p.x,40,p.z),Vector3(p.x,-20,p.z),1)
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else p

func _wildlife() -> void:
	if flowers.is_empty(): return
	for i in 18:
		var butterfly:Node3D=load("res://assets/models/valley_butterfly.glb").instantiate()
		add_child(butterfly)
		var mat:=ShaderMaterial.new()
		mat.shader=load("res://shaders/butterfly.gdshader")
		mat.set_shader_parameter("atlas",load("res://assets/textures/Butterfly_0"+str(i%3+1)+".png"))
		mat.set_shader_parameter("phase",i*1.7)
		_override(butterfly,mat)
		butterflies.append({"root":butterfly,"home":flowers[(i*31)%flowers.size()],"phase":i*1.7})
	for i in 9:
		var bird:Node3D=load("res://assets/models/valley_bird.glb").instantiate()
		add_child(bird)
		bird.scale=Vector3.ONE*.6
		var player:AnimationPlayer=_find_animation(bird)
		if player:
			var names:=player.get_animation_list()
			for name in names:
				if name!="RESET":
					player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
					player.play(name)
					break
		birds.append(bird)

func _find_animation(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:return n
	for c in n.get_children():
		var a:=_find_animation(c)
		if a:return a
	return null
func _override(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		n.material_override=mat
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():_override(c,mat)

func _process(dt: float) -> void:
	t+=dt
	if wind_repaired:
		for rotor in wind_rotors:rotor.rotate_object_local(Vector3.FORWARD,dt*.28)
	if observer:
		for mat in foliage_materials:mat.set_shader_parameter("walker",observer.global_position)
	for b in butterflies:
		var phase:float=t*.8+b.phase
		var home:Vector3=b.home
		var p:=home+Vector3(sin(phase)*.7,.55+sin(phase*1.8)*.12,cos(phase*.7)*.6)
		if observer and observer.global_position.distance_to(p)<1.3:
			p.y+=.5
		b.root.position=b.root.position.lerp(p,minf(1,dt*4))
		b.root.rotation.y=-phase
	for i in birds.size():
		var a:=t*.15+i*.12
		birds[i].position=Vector3(cos(a)*18,9+sin(a*2+i)*.8,-22+sin(a)*16)
		birds[i].rotation.y=-a

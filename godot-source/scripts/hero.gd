extends CharacterBody3D
# Camera-relative locomotion follows the Godot MIT Platformer 3D pattern.
# Coyote time, input buffering and compact doll stride are added here.
signal jumped
signal stepped
var active := false
var camera: Camera3D
var lens: CameraAttributesPractical
var focus_distance := 4.0
var web_lens:ShaderMaterial
var visual: Node3D
var skeleton: Skeleton3D
var pivot: Node3D
var spawn := Vector3.ZERO
var camera_yaw := 0.0
var camera_pitch := -.12
var coyote := 0.0
var buffer := 0.0
var distance_walked := 0.0
var takes := {}
var bindings: Array = []
var bone_rests: Array = []
var current := "idle"
var clock := 0.0
var forced := ""
var forced_time := 0.0
var jump_cooldown := 0.0
var run_toggle := false
var camera_distance := 4.0
var drag_look := false
var free_look := false
var was_captured := false

func capture_look() -> void:
	if not active:return
	free_look=true
	# Some embedded/background browser hosts deny Pointer Lock. Mouse orbit remains usable.
	if not OS.has_feature("web") or JavaScriptBridge.eval("document.hasFocus()",true):
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func release_look() -> void:
	drag_look=false
	free_look=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	floor_snap_length = .3
	floor_max_angle = deg_to_rad(48)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .22
	capsule.height = 1.18
	collider.shape = capsule
	collider.position.y = .6
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	var model: Node3D = load("res://assets/models/moss.glb").instantiate()
	visual.add_child(model)
	visual.scale = Vector3.ONE * 1.3
	skeleton = _find_skeleton(model)
	_load_motion(model)
	pivot = Node3D.new()
	get_parent().add_child(pivot)
	camera = Camera3D.new()
	pivot.add_child(camera)
	camera.current = true
	camera.fov = 51
	camera.near = .08
	camera.far = 300
	# Keep the doll and the next few steps legible; soften only distant scenery.
	lens = CameraAttributesPractical.new()
	lens.dof_blur_amount = .018
	lens.dof_blur_far_enabled = true
	lens.dof_blur_far_distance = 13.0
	lens.dof_blur_far_transition = 32.0
	lens.dof_blur_near_enabled = false
	lens.dof_blur_near_distance = 1.2
	lens.dof_blur_near_transition = .8
	camera.attributes = lens
	if OS.has_feature("web"):
		lens.dof_blur_far_enabled=false
		var screen:=MeshInstance3D.new()
		var quad:=QuadMesh.new()
		quad.size=Vector2(2,2)
		screen.mesh=quad
		screen.extra_cull_margin=10000
		screen.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		web_lens=ShaderMaterial.new()
		web_lens.shader=load("res://shaders/web_depth.gdshader")
		web_lens.render_priority=120
		screen.material_override=web_lens
		camera.add_child(screen)
	pivot.global_position = global_position + Vector3.UP * .85
	_update_camera(1.0)
	print("HERO_READY skeleton=", skeleton.get_bone_count(), " actions=", takes.keys())

func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for child in n.get_children():
		var found := _find_skeleton(child)
		if found: return found
	return null

func _transform(a: Array, offset: int = 0) -> Transform3D:
	var q := Quaternion(-a[offset+3], -a[offset+4], a[offset+5], a[offset+6]).normalized()
	return Transform3D(Basis(q), Vector3(a[offset],a[offset+1],-a[offset+2]))

func _load_motion(model: Node3D) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moss-motion.json"))
	for take in data.takes: takes[take.name] = take
	var skel_to_model := model.global_transform.affine_inverse() * skeleton.global_transform
	for i in skeleton.get_bone_count(): bone_rests.append(skeleton.get_bone_global_rest(i))
	for b in data.bones:
		var index := skeleton.find_bone(b.name)
		if index < 0: continue
		bindings.append({"index":index,"offset":data.bones.find(b)*7,"unity_inverse":_transform(b.rest).affine_inverse(),"rest":skel_to_model*skeleton.get_bone_global_rest(index),"skel_inverse":skel_to_model.affine_inverse()})

func play_action(action: String) -> void:
	if not takes.has(action): return
	forced = action
	forced_time = float(takes[action].duration)
	current = action
	clock = 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_R and active:
		run_toggle=not run_toggle
	if event is InputEventMouseButton and active:
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:capture_look()
		if event.button_index==MOUSE_BUTTON_RIGHT:drag_look=event.pressed
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:camera_distance=clampf(camera_distance-.35,2.2,7.5)
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera_distance=clampf(camera_distance+.35,2.2,7.5)
	if event is InputEventMouseMotion and active and (free_look or Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or drag_look):
		# Unscaled screen motion keeps sensitivity stable at every browser/window size.
		camera_yaw=wrapf(camera_yaw-event.screen_relative.x*.0026,-PI,PI)
		camera_pitch=clampf(camera_pitch-event.screen_relative.y*.0023,-1.12,0.0)

func _physics_process(dt: float) -> void:
	var captured:=Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
	if was_captured and not captured:
		free_look=false
		drag_look=false
	was_captured=captured
	# Fallback hosts can still orbit a full circle by holding the cursor near a side edge.
	if active and free_look and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
		var mouse:=get_viewport().get_mouse_position()
		var extent:=get_viewport().get_visible_rect().size
		if mouse.y>70 and mouse.y<extent.y-70 and mouse.x>=0 and mouse.x<=extent.x:
			if mouse.x<28:camera_yaw=wrapf(camera_yaw+dt*.75,-PI,PI)
			elif mouse.x>extent.x-28:camera_yaw=wrapf(camera_yaw-dt*.75,-PI,PI)
	jump_cooldown = maxf(0,jump_cooldown-dt)
	var axis := Input.get_vector("left","right","forward","back") if active and forced_time<=0 else Vector2.ZERO
	var dir := Basis(Vector3.UP,camera_yaw)*Vector3(axis.x,0,axis.y)
	var speed := 2.6 if (run_toggle or Input.is_action_pressed("run") or Input.is_key_pressed(KEY_SHIFT)) else 1.35
	var old_position := global_position
	velocity.x = move_toward(velocity.x,dir.x*speed,dt*8)
	velocity.z = move_toward(velocity.z,dir.z*speed,dt*8)
	if is_on_floor(): coyote = .12
	else: coyote = maxf(0,coyote-dt)
	if active and Input.is_action_just_pressed("jump") and forced_time<=0: buffer = .14
	else: buffer = maxf(0,buffer-dt)
	if buffer>0 and coyote>0:
		velocity.y = 4.3
		buffer=0
		coyote=0
		current="jump"
		clock=0
		if jump_cooldown<=0:
			jumped.emit()
			jump_cooldown=1.7
	if not is_on_floor(): velocity.y -= 12.0*dt
	if active and Input.is_action_just_released("jump") and velocity.y>0: velocity.y *= .72
	# Short stairs and bridge thresholds can be stepped onto without a full jump.
	if is_on_floor() and dir.length_squared()>.1:
		var probe:=dir.normalized()*.18
		if test_move(global_transform,probe):
			var raised:=global_transform
			raised.origin.y+=.23
			if not test_move(raised,probe):
				var ray:=PhysicsRayQueryParameters3D.create(raised.origin+probe,global_position+probe-Vector3.UP*.02,1,[get_rid()])
				var step:=get_world_3d().direct_space_state.intersect_ray(ray)
				if not step.is_empty() and step.position.y>global_position.y+.025:
					global_position.y=step.position.y+.015
	move_and_slide()
	if global_position.y < -8:
		global_position=spawn
		velocity=Vector3.ZERO
	var horizontal_speed := Vector2(velocity.x,velocity.z).length()
	if horizontal_speed>.07:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-velocity.x,-velocity.z),1-exp(-dt*12))
	if is_on_floor():
		distance_walked+=Vector2(global_position.x-old_position.x,global_position.z-old_position.z).length()
		if distance_walked>.34:
			distance_walked=0
			stepped.emit()
	forced_time=maxf(0,forced_time-dt)
	var next := forced if forced_time>0 else ("jump" if not is_on_floor() else ("run" if horizontal_speed>1.7 else ("walk" if horizontal_speed>.08 else "idle")))
	if next != current:
		current=next
		clock=0
	clock += dt*(clampf(horizontal_speed/1.35,.45,1.2)*1.65 if current=="walk" else (1.6 if current=="run" else 1.))
	_animate(dt)
	_update_camera(dt)

func _animate(dt: float) -> void:
	if not takes.has(current) or not skeleton: return
	var take: Dictionary=takes[current]
	var t: float=fmod(clock,float(take.duration)) if take.loop else minf(clock,float(take.duration)-.001)
	var frame := t*30
	var a: int=mini(int(frame),take.frames.size()-1)
	var b: int=mini(a+1,take.frames.size()-1)
	var fraction := frame-floorf(frame)
	var globals: Array=bone_rests.duplicate()
	for bind in bindings:
		var ta := _transform(take.frames[a].transforms,bind.offset)
		var tb := _transform(take.frames[b].transforms,bind.offset)
		var sample := ta.interpolate_with(tb,fraction)
		globals[bind.index]=bind.skel_inverse*sample*bind.unity_inverse*bind.rest
	var blend := 1.-exp(-dt*15.)
	for bind in bindings:
		var i: int=bind.index
		var parent:=skeleton.get_bone_parent(i)
		var local: Transform3D=globals[parent].affine_inverse()*globals[i] if parent>=0 else globals[i]
		var q:=local.basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i).slerp(q,blend))
		# Segment translations remain anatomical; only the pelvis carries vertical motion.
		if skeleton.get_bone_name(i)=="Hips":
			var pos:=local.origin
			pos.x=0
			pos.z=0
			skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i).lerp(pos,blend))

func _update_camera(dt: float) -> void:
	pivot.global_position=pivot.global_position.lerp(global_position+Vector3.UP*.85,1-exp(-dt*9))
	pivot.rotation=Vector3(camera_pitch,camera_yaw,0)
	var target:=pivot.global_position
	var end:=target+pivot.global_basis*Vector3(0,.45,camera_distance)
	var query:=PhysicsRayQueryParameters3D.create(target,end,1,[get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): end=hit.position+(target-hit.position).normalized()*.22
	camera.global_position=end
	camera.look_at(target,Vector3.UP)
	# Focus follows the subject, not whichever leaf crosses the camera ray.
	var subject_distance := camera.global_position.distance_to(global_position+Vector3.UP*.8)
	focus_distance = lerpf(focus_distance,subject_distance,1.-exp(-dt*3.))
	lens.dof_blur_far_distance = maxf(11.0,focus_distance+9.0)
	if web_lens:web_lens.set_shader_parameter("focus_end",lens.dof_blur_far_distance)
	# A wall can push the camera close; never let foreground blur cover the face.
	lens.dof_blur_near_distance = minf(1.2,maxf(.05,subject_distance-1.4))
	lens.dof_blur_near_transition = minf(.8,lens.dof_blur_near_distance)

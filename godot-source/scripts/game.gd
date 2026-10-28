extends Node3D
const HeroScript=preload("res://scripts/hero.gd")
const WorldScript=preload("res://scripts/planet_world.gd")
const MapScript=preload("res://scripts/planet_map.gd")
const MenuScript=preload("res://scripts/journey_menu.gd")
var world
var hero
var ui:Control
var title:Control
var goal_label:Label
var detail_label:Label
var prompt:Label
var subtitle:Label
var chapter:Label
var inventory:Label
var map
var ending:Control
var quest_step:=0
var started:=false
var ready_to_play:=false
var paused:=false
var subtitle_time:=0.
var quest_points:Dictionary={}
var marker:Label3D
var music:AudioStreamPlayer
var ambience:AudioStreamPlayer
var speech:AudioStreamPlayer
var effect:AudioStreamPlayer
var footsteps:AudioStreamPlayer
var step_index:=0
var flower:Node3D
var heart_thread:Node3D
var chime:AudioStreamPlayer3D
var windmill_blades:Node3D
var story_time:=0.
var choice:=""
var target:=Vector3.ZERO
var font:Font
var web_import_callback:JavaScriptObject
var controls:Label
var goal_names:=["听听那朵花的请求","去溪边装一滴水","把水带回小花身边","找到风铃缺失的心线","让风重新拥有声音","沿石板路前往观星亭","写下你的回信","这颗星球记得你"]
var hints:=["走近银白小花，按 E 倾听。","溪水在石桥前。沿浅色小路前行。","你带着一滴水。回到初遇的花旁。","风车停了。屋旁的草地上有一束心线。","带着心线回到风车旁，按 E 修复。","过桥，向左走。那里能看到更远的天空。","到观星亭坐一会儿，再选择你的回答。","花会继续长，风铃会继续响。按 J 重读来信。"]

func _ready()->void:
	_setup_input()
	font=load("res://assets/ui/NotoSansSC.ttf")
	_create_ui()
	_audio()
	await get_tree().process_frame
	world=Node3D.new()
	world.set_script(WorldScript)
	add_child(world)
	world.progress.connect(func(v:float):title.set_progress(v))
	await world.build()
	hero=CharacterBody3D.new()
	hero.name="Taitai"
	hero.set_script(HeroScript)
	add_child(hero)
	hero.spawn=world.v3(world.data.spawn)
	hero.position=hero.spawn
	world.observer=hero
	hero.jumped.connect(_jump)
	hero.stepped.connect(_footstep)
	map.actor=hero
	await get_tree().physics_frame
	_setup_story()
	_load_save()
	if OS.has_feature("web"):
		web_import_callback=JavaScriptBridge.create_callback(_import_web_save)
		JavaScriptBridge.get_interface("window").wakukuImportSave=web_import_callback
		_publish_web_save()
	ready_to_play=true
	title.set_ready(quest_step>0)
	ui.size=get_viewport().get_visible_rect().size
	print("WAKUKU_GODOT_READY viewport=",get_viewport().get_visible_rect()," ui=",ui.size," title=",title.size)

func _setup_input()->void:
	var keys:={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"run":KEY_SHIFT,"jump":KEY_SPACE,"interact":KEY_E,"pause":KEY_ESCAPE,"map":KEY_M,"journal":KEY_J}
	for action in keys:
		if not InputMap.has_action(action):InputMap.add_action(action)
		var event:=InputEventKey.new()
		if action=="run":event.keycode=keys[action]
		else:event.physical_keycode=keys[action]
		InputMap.action_add_event(action,event)

func _create_ui()->void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	ui=Control.new()
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui.size=Vector2(1680,720)
	get_viewport().size_changed.connect(func():ui.size=get_viewport().get_visible_rect().size)
	var theme:=Theme.new()
	theme.default_font=font
	theme.default_font_size=18
	ui.theme=theme
	var mission:=_panel(ui,Vector2(32,30),Vector2(390,160),Color(.10,.20,.17,.84))
	chapter=_label(mission,"星球来信  /  第一封",Vector2(22,17),Vector2(346,24),15,Color("dfc892"))
	goal_label=_label(mission,"一朵需要你的花",Vector2(22,51),Vector2(346,35),25)
	detail_label=_label(mission,"",Vector2(22,98),Vector2(346,49),15)
	detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	inventory=_label(ui,"苔苔  ·  口袋里装着好奇心",Vector2(34,818),Vector2(480,32),18)
	_place(inventory,Control.PRESET_BOTTOM_LEFT,34,-76,514,-44)
	controls=_label(ui,"WASD 走动    SHIFT 小跑    SPACE 跳跃    鼠标环视    滚轮远近    ESC 释放光标",Vector2(0,0),Vector2(1100,28),14,Color("e3e4d2"))
	_place(controls,Control.PRESET_CENTER_BOTTOM,-550,-34,550,-6)
	controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt=_label(ui,"",Vector2.ZERO,Vector2(650,42),21,Color("fff4c7"))
	_place(prompt,Control.PRESET_CENTER_BOTTOM,-325,-125,325,-83)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle=_label(ui,"",Vector2.ZERO,Vector2(850,85),22)
	_place(subtitle,Control.PRESET_CENTER_BOTTOM,-425,-225,425,-140)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	map=Control.new()
	map.set_script(MapScript)
	ui.add_child(map)
	_place(map,Control.PRESET_TOP_RIGHT,-238,24,-34,228)
	map.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_label(map,"N",Vector2(92,4),Vector2(20,20),13)
	var map_name:=_label(map,"小小的归途",Vector2(0,208),Vector2(204,25),14)
	map_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var menu_button:=_button(ui,"旅程选择",Vector2.ZERO,Vector2(132,34),_return_to_menu)
	_place(menu_button,Control.PRESET_BOTTOM_RIGHT,-170,-46,-38,-12)
	menu_button.add_theme_font_size_override("font_size",15)
	title=Control.new()
	title.set_script(MenuScript)
	ui.add_child(title)
	title.enter_requested.connect(func(restart:bool):
		if restart:_restart_story()
		else:_start())
	title.ui_sound.connect(func():_play("ui-select"))

func _panel(parent:Node,p:Vector2,s:Vector2,c:Color)->Panel:
	var node:=Panel.new()
	parent.add_child(node)
	node.position=p
	node.size=s
	var box:=StyleBoxFlat.new()
	box.bg_color=c
	box.corner_radius_top_left=12
	box.corner_radius_top_right=12
	box.corner_radius_bottom_left=12
	box.corner_radius_bottom_right=12
	box.border_width_left=2
	box.border_color=Color("c9bc8e")
	node.add_theme_stylebox_override("panel",box)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func _label(parent:Node,text:String,p:Vector2,s:Vector2,fs:int=18,c:Color=Color("fff9df"))->Label:
	var l:=Label.new()
	parent.add_child(l)
	l.text=text
	l.position=p
	l.size=s
	l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",c)
	l.add_theme_color_override("font_shadow_color",Color(0,.08,.06,.65))
	l.add_theme_constant_override("shadow_offset_y",2)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _button(parent:Node,text:String,p:Vector2,s:Vector2,callback:Callable)->Button:
	var b:=Button.new()
	parent.add_child(b)
	b.position=p
	b.size=s
	b.text=text
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("ead7a2")
	box.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal",box)
	var hover:=box.duplicate()
	hover.bg_color=Color("fff2cb")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",hover)
	b.add_theme_color_override("font_color",Color("26473c"))
	b.add_theme_color_override("font_hover_color",Color("26473c"))
	b.add_theme_font_size_override("font_size",20)
	b.pressed.connect(callback)
	return b

func _setup_story()->void:
	quest_points={"flower":Vector3(-2,0,-5),"water":Vector3(-1.7,0,-18.0),"thread":Vector3(-1.1,0,-13),"bell":Vector3(-6.5,0,-17),"stars":Vector3(-18.8,0,-32)}
	for key in quest_points:quest_points[key]=world.ground_at(quest_points[key])
	for p in quest_points.values():map.places.append(p)
	flower=Node3D.new()
	for part in world._asset("flora_starflower"):
		var mesh_node:=MeshInstance3D.new()
		mesh_node.mesh=part.mesh
		mesh_node.transform=part.transform
		flower.add_child(mesh_node)
	world.add_child(flower)
	flower.position=quest_points.flower
	flower.scale=Vector3.ONE*1.6
	heart_thread=load("res://assets/models/statue_ring.glb").instantiate()
	world.add_child(heart_thread)
	heart_thread.scale=Vector3.ONE*.24
	heart_thread.position=quest_points.thread
	marker=Label3D.new()
	marker.text="✧"
	marker.font=font
	marker.font_size=48
	marker.pixel_size=.006
	marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate=Color("ffe7a3")
	marker.no_depth_test=false
	world.add_child(marker)
	chime=AudioStreamPlayer3D.new()
	world.add_child(chime)
	chime.position=quest_points.bell
	chime.max_distance=18
	chime.volume_db=-12
	if ResourceLoader.exists("res://assets/audio/repair.ogg"):chime.stream=load("res://assets/audio/repair.ogg")
	_refresh_goal()

func _start()->void:
	if not ready_to_play:return
	title.visible=false
	started=true
	paused=false
	hero.active=true
	_play("ui-select")
	hero.free_look=true
	if quest_step==0:_say("planet-intro","苔苔：这颗星球这么小，连风都绕着同一朵花走。那朵花，好像在等水。",8)

func _return_to_menu()->void:
	if not ready_to_play:return
	started=false
	paused=false
	hero.active=false
	hero.velocity=Vector3.ZERO
	hero.release_look()
	if is_instance_valid(ending):ending.queue_free();ending=null
	title.set_ready(quest_step>0)
	title.reopen()

func _audio()->void:
	music=AudioStreamPlayer.new()
	add_child(music)
	music.stream=load("res://assets/audio/valley-score.ogg")
	music.stream.loop=true
	music.volume_db=-20
	music.play()
	ambience=AudioStreamPlayer.new()
	add_child(ambience)
	ambience.stream=load("res://assets/audio/creek.ogg")
	ambience.stream.loop=true
	ambience.volume_db=-32
	ambience.play()
	speech=AudioStreamPlayer.new()
	add_child(speech)
	speech.volume_db=-1
	effect=AudioStreamPlayer.new()
	add_child(effect)
	effect.volume_db=-11
	footsteps=AudioStreamPlayer.new()
	add_child(footsteps)
	footsteps.volume_db=-13
func _play(id:String)->void:
	var path:="res://assets/audio/"+id+".ogg"
	if ResourceLoader.exists(path):effect.stream=load(path);effect.play()
func _say(id:String,text:String,duration:float=6.)->void:
	subtitle.text=text
	subtitle_time=duration
	var path:="res://assets/audio/"+id+".ogg"
	if ResourceLoader.exists(path):speech.stream=load(path);speech.play()
func _jump()->void:
	if speech.playing:_play("jump");return
	var names:=["jump-waku","jump-hoo","jump-hey"]
	speech.stream=load("res://assets/audio/"+names[randi()%3]+".ogg")
	speech.play()
func _footstep()->void:
	var p:Vector3=hero.global_position
	var surface:="grass"
	if absf(p.x-sin(p.z*.13)*1.5)<1.4:surface="earth"
	if absf(p.z+23)<2.4 and absf(p.x)<2.:surface="wood"
	var path:="res://assets/audio/Footsteps/"+surface+"/step-"+str(step_index%5)+".ogg"
	step_index+=1
	footsteps.stream=load(path)
	footsteps.pitch_scale=randf_range(.96,1.04)
	footsteps.play()

func _refresh_goal()->void:
	goal_label.text=goal_names[quest_step]
	detail_label.text=hints[quest_step]
	chapter.text="星球来信  /  "+("一朵花" if quest_step<=2 else ("一阵风" if quest_step<=4 else "一个约定"))
	var keys:=["flower","water","flower","thread","bell","stars","stars","flower"]
	target=quest_points[keys[quest_step]]
	map.target=target
	marker.position=target+Vector3.UP*1.1
	marker.visible=quest_step<7
	heart_thread.visible=quest_step<4
	inventory.text="苔苔  ·  "+("口袋里有一滴水" if quest_step==2 else ("口袋里有一束心线" if quest_step==4 else "已留下 %d 个约定"%int(quest_step/3)))

func _interact()->void:
	if hero.global_position.distance_to(target)>2.0 or hero.forced_time>0:return
	match quest_step:
		0:
			hero.play_action("talk")
			_say("","小花：我不需要整片海。今天的一滴水，就足够让我等到明天。",5)
		1:
			hero.play_action("pickup_ground")
			_play("collect")
			_say("","你小心地收起一滴水。回去的路，忽然有了方向。",4)
		2:
			hero.play_action("pickup_ground")
			_say("planet-flower","苔苔：原来它不是不爱说话，只是太渴了。我明天也会来看你。",6)
			world.cared=true
			var tween:=create_tween()
			tween.tween_property(flower,"scale",Vector3.ONE*2.0,2.)
		3:
			hero.play_action("pickup_ground")
			_play("collect")
			_say("","心线轻轻缠住手指。风车上的风铃，已经很久没有响过了。",5)
		4:
			hero.play_action("talk")
			chime.play()
			world.wind_repaired=true
			_say("planet-bell","苔苔：风铃修好了。现在，风经过这里，也有一件值得告诉别人的事。",6)
		5:
			hero.play_action("look_distance")
			_say("planet-end","苔苔：我曾经以为，去远方才算出发。现在才知道，愿意回来，也是一种勇敢。",8)
		6:
			_show_ending()
			return
		_:
			return
	print("STORY_INTERACTION step=",quest_step," at=",hero.global_position)
	quest_step=mini(quest_step+1,7)
	_refresh_goal()
	_save()

func _show_ending()->void:
	hero.active=false
	hero.release_look()
	ending=_panel(ui,Vector2.ZERO,Vector2(680,340),Color(.08,.17,.14,.97))
	_place(ending,Control.PRESET_CENTER,-340,-170,340,170)
	_label(ending,"寄给远方，也寄给自己",Vector2(40,34),Vector2(600,50),30)
	var body:=_label(ending,"这颗星球曾经只是地图上的一个点。\n如今，一朵花记得你的脚步，一阵风记得你的声音。\n\n你的下一封信，会从哪里寄来？",Vector2(40,101),Vector2(600,130),19)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(ending,"留下，照料这颗星球",Vector2(40,260),Vector2(285,52),func():_choose("stay"))
	_button(ending,"出发，并约好回来",Vector2(350,260),Vector2(285,52),func():_choose("return"))
func _choose(answer:String)->void:
	choice=answer
	quest_step=7
	ending.queue_free()
	ending=null
	hero.active=true
	hero.capture_look()
	hero.play_action("goodbye" if answer=="return" else "laugh")
	_say("","第一封信 · 完\n"+("你留了下来。故事从照料开始，也将在照料中继续。" if answer=="stay" else "你约好回来。远方不再意味着离开一切。"),8)
	_refresh_goal()
	_save()

func _save()->void:
	var f:=FileAccess.open("user://planet-letter.json",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"step":quest_step,"choice":choice}))
		f.close()
	if OS.has_feature("web"):_publish_web_save()

func _publish_web_save()->void:
	var payload:=JSON.stringify({"game":"wakuku-planet-letter","version":1,"step":quest_step,"choice":choice})
	JavaScriptBridge.eval("window.wakukuSave="+JSON.stringify(payload)+";try{localStorage.setItem('wakuku.planet-letter.v1',window.wakukuSave)}catch(e){};",true)

func _import_web_save(args:Array)->void:
	if args.is_empty():return
	var record:Variant=JSON.parse_string(str(args[0]))
	if not record is Dictionary or record.get("game","")!="wakuku-planet-letter" or record.get("version",0)!=1:return
	var step:int=int(record.get("step",-1))
	if step<0 or step>7 or not str(record.get("choice","")).is_empty() and record.get("choice") not in ["stay","return"]:return
	quest_step=step
	choice=record.get("choice","")
	flower.scale=Vector3.ONE*(2. if step>=3 else 1.6)
	world.wind_repaired=step>=5
	_refresh_goal()
	_save()
	_return_to_menu()

func _load_save()->void:
	var contents:=""
	if OS.has_feature("web"):
		var stored:Variant=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('wakuku.planet-letter.v1')||''}catch(e){return ''}})()",true)
		if stored is String:contents=stored
	if contents.is_empty() and FileAccess.file_exists("user://planet-letter.json"):
		contents=FileAccess.get_file_as_string("user://planet-letter.json")
	if contents.is_empty():return
	var saved:Variant=JSON.parse_string(contents)
	if saved is Dictionary:
		quest_step=clampi(int(saved.get("step",0)),0,7)
		choice=saved.get("choice","")
		if quest_step>=3:flower.scale=Vector3.ONE*2.
		world.wind_repaired=quest_step>=5
		_refresh_goal()

func _unhandled_input(event:InputEvent)->void:
	if not ready_to_play or not started:return
	if paused and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not is_instance_valid(ending):
		paused=false
		hero.active=true
		hero.capture_look()
		return
	if event.is_action_pressed("interact") and not paused and not is_instance_valid(ending):_interact()
	if event.is_action_pressed("pause"):
		paused=not paused
		hero.active=not paused and not is_instance_valid(ending)
		if paused:hero.release_look()
		else:hero.capture_look()
		prompt.text="已暂停 · 点击场景或 ESC 继续" if paused else ""
	if event.is_action_pressed("map"):
		var large:bool=map.size.x<300
		_place(map,Control.PRESET_TOP_RIGHT,-490 if large else -238,24,-40 if large else -34,474 if large else 228)
	if event.is_action_pressed("journal"):
		_say("","来信札记\n"+hints[quest_step]+("\n我们不需要占有整颗星球，只需要认真照料其中的一小部分。" if quest_step>=3 else ""),7)

func _process(dt:float)->void:
	story_time+=dt
	if music and speech:music.volume_db=lerpf(music.volume_db,-28. if speech.playing else -20.,minf(1.,dt*4))
	if not ready_to_play:return
	if started:
		controls.text="WASD 走动   SHIFT 小跑   SPACE 跳跃   鼠标环视   滚轮远近   E 互动   ESC 释放光标" if hero.free_look else "点击场景进入鼠标环视   /   也可按住右键拖动   ·   E 互动   M 地图"
	if subtitle_time>0:
		subtitle_time-=dt
		if subtitle_time<=0:subtitle.text=""
	if marker:marker.position.y=target.y+1.1+sin(story_time*1.7)*.07
	if not started or paused or is_instance_valid(ending):return
	var dist:float=hero.global_position.distance_to(target)
	prompt.text=("E  ·  "+goal_names[quest_step]) if dist<2. else ("%s   ·   %d 米"%[goal_names[quest_step],int(dist)] if quest_step<7 else "J  ·  重读星球来信")
	ambience.volume_db=lerpf(-19.,-36.,clampf(absf(hero.global_position.z+23)/18.,0,1))

func _place(c:Control,preset:int,left:float,top:float,right:float,bottom:float)->void:
	c.set_anchors_preset(preset)
	c.offset_left=left
	c.offset_top=top
	c.offset_right=right
	c.offset_bottom=bottom

func _restart_story()->void:
	if not ready_to_play:return
	quest_step=0
	choice=""
	flower.scale=Vector3.ONE*1.6
	world.wind_repaired=false
	hero.position=hero.spawn
	hero.velocity=Vector3.ZERO
	_save()
	_refresh_goal()
	_start()

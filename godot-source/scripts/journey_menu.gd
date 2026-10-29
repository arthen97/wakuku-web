extends Control
# Native adaptation of React Bits AnimatedContent / ShinyText. See licenses/React-Bits.md.
signal enter_requested(restart:bool)
signal ui_sound
var available:=false
var has_save:=false
var stage:=0
var body:Control
var status:Label
var next_button:Button
var restart_box:CheckBox
var transitioning:=false
var web_menu:JavaScriptObject
var web_menu_callback:JavaScriptObject
var backdrop:TextureRect
const INK=Color("102c2d")
const GOLD=Color("e9d6a2")
const CREAM=Color("fff5da")

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	if OS.has_feature("web"):
		web_menu=JavaScriptBridge.get_interface("wakukuMenu")
		if web_menu:
			web_menu_callback=JavaScriptBridge.create_callback(_web_action)
			web_menu.bind(web_menu_callback)
			return
	backdrop=_image(self,"cover",Vector2.ZERO,Vector2(1680,720))
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil:=ColorRect.new()
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shade:=ShaderMaterial.new()
	shade.shader=load("res://shaders/menu_shade.gdshader")
	veil.material=shade
	_text(self,"A R T H E N   P R E S E N T S",Vector2(92,42),Vector2(600,26),15,GOLD)
	var edition:=_text(self,"EARLY JOURNEY  /  抢先体验",Vector2(1200,42),Vector2(385,28),15,GOLD)
	edition.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	status=_text(self,"正在准备这颗小星球…",Vector2(92,668),Vector2(720,28),15,Color("c4d1c6"))
	var footer:=_text(self,"当前开放  1 位旅伴 · 1 个环境",Vector2(1110,668),Vector2(475,28),15,Color("c4d1c6"))
	footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	body=Control.new()
	add_child(body)
	body.position=Vector2(120,112)
	body.size=Vector2(1440,530)
	_build_page()

func set_progress(value:float)->void:
	if web_menu:
		web_menu.progress(value)
		return
	status.text="正在铺开小星球  ·  %d%%"%int(value*100)
func set_ready(saved:bool)->void:
	available=true
	has_save=saved
	if web_menu:
		web_menu.ready(saved)
		return
	status.text="小星球已准备好  ·  当前为首个环境的可玩预览"
	if stage==2 and is_instance_valid(next_button):next_button.disabled=false
func reopen()->void:
	visible=true
	modulate.a=1.
	stage=0
	if web_menu:
		web_menu.open()
		return
	_build_page()

func _web_action(args:Array)->void:
	if args.is_empty():return
	if str(args[0])=="sound":
		ui_sound.emit()
	elif str(args[0])=="enter" and available and not transitioning:
		transitioning=true
		if JavaScriptBridge.eval("document.hasFocus()",true):Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		enter_requested.emit(bool(args[1]) if args.size()>1 else false)
		transitioning=false

func _text(parent:Node,value:String,p:Vector2,s:Vector2,fs:int=20,color:Color=CREAM)->Label:
	var l:=Label.new()
	parent.add_child(l)
	l.position=p
	l.size=s
	l.text=value
	l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l
func _image(parent:Node,id:String,p:Vector2,s:Vector2)->TextureRect:
	var img:=TextureRect.new()
	parent.add_child(img)
	img.position=p
	img.size=s
	img.texture=load("res://assets/ui/"+id+".png")
	img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return img
func _button(parent:Node,value:String,p:Vector2,s:Vector2,callback:Callable,primary:bool=true)->Button:
	var b:=Button.new()
	parent.add_child(b)
	b.position=p
	b.size=s
	b.text=value
	var base:=StyleBoxFlat.new()
	base.bg_color=GOLD if primary else Color(.03,.12,.12,.82)
	base.set_corner_radius_all(4)
	base.set_border_width_all(1)
	base.border_color=GOLD
	var hover:=base.duplicate()
	hover.bg_color=Color("fff0c1") if primary else Color("285453")
	b.add_theme_stylebox_override("normal",base)
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("focus",hover)
	b.add_theme_stylebox_override("pressed",hover)
	b.add_theme_color_override("font_color",INK if primary else CREAM)
	b.add_theme_color_override("font_hover_color",INK if primary else CREAM)
	b.add_theme_color_override("font_focus_color",INK if primary else CREAM)
	b.add_theme_font_size_override("font_size",20)
	b.pressed.connect(func():ui_sound.emit();callback.call())
	return b

func _build_page()->void:
	backdrop.texture=load("res://assets/ui/menu-destination.webp" if stage==2 else "res://assets/ui/menu-ensemble.webp")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	next_button=null
	if stage==0:
		var logo:=_text(body,"WAKUKU",Vector2(0,68),Vector2(650,100),86)
		var shimmer:=ShaderMaterial.new()
		shimmer.shader=load("res://shaders/menu_shine.gdshader")
		logo.material=shimmer
		_text(body,"星 球 来 信",Vector2(6,174),Vector2(600,50),32,GOLD)
		_text(body,"从一朵花开始，认识整个世界。",Vector2(6,264),Vector2(630,42),25)
		_text(body,"第一站：风铃草甸。更多旅伴与星球，正在途中。",Vector2(6,311),Vector2(680,34),18,Color("c4d1c6"))
		_button(body,"选择旅伴    →",Vector2(6,404),Vector2(294,58),func():_navigate(1))
		_text(body,"01  /  一封尚未写完的星球来信",Vector2(6,478),Vector2(700,26),14,GOLD)
	elif stage==1:
		_header("01 / TRAVELLER","选择你的旅伴","每位旅伴都会有自己的来信。当前仅开放苔苔。")
		var ids:=["moss","pearl","candy","bonbon","lilac"]
		var names:=["苔苔","珍珠","糖糖","邦邦","丁香"]
		var taglines:=["照料一朵花，认识整个世界","在月光里，听见溪流的来信","把好奇心，交给远方的风","循着微光，发现森林的秘密","为每一颗星，留下一个约定"]
		for i in 5:_card("poster-"+ids[i],names[i],taglines[i],Vector2(i*285,106),Vector2(264,328),i==0,true)
		_button(body,"←  返回",Vector2(0,450),Vector2(160,52),func():_navigate(0),false)
		next_button=_button(body,"带苔苔去旅行    →",Vector2(1104,450),Vector2(300,52),func():_navigate(2))
	else:
		_header("02 / DESTINATION","下一封信，从哪里开始？","当前是一个独立环境的可玩篇章；其余目的地尚未开放。")
		_card("meadow","风铃草甸","01 · 可进入   /   一朵花，一阵风，一个约定",Vector2(0,106),Vector2(456,308),true,false)
		_card("canopy","回声树海","02 · 尚未开放   /   概念预览",Vector2(480,106),Vector2(456,308),false,false)
		_card("creek","星露溪谷","03 · 尚未开放   /   概念预览",Vector2(960,106),Vector2(456,308),false,false)
		_button(body,"←  旅伴",Vector2(0,450),Vector2(160,52),func():_navigate(1),false)
		restart_box=CheckBox.new()
		body.add_child(restart_box)
		restart_box.position=Vector2(200,458)
		restart_box.text="从第一封信重新开始" if has_save else "从第一封信出发"
		restart_box.disabled=not has_save
		restart_box.add_theme_font_size_override("font_size",17)
		next_button=_button(body,"继续草甸来信    →" if has_save else "进入风铃草甸    →",Vector2(1116,450),Vector2(300,52),_enter)
		next_button.disabled=not available
	_animate_content()

func _header(kicker:String,heading:String,description:String)->void:
	_text(body,kicker,Vector2.ZERO,Vector2(600,24),14,GOLD)
	_text(body,heading,Vector2(0,30),Vector2(1400,48),34)
	_text(body,description,Vector2(0,80),Vector2(1400,26),16,Color("c4d1c6"))

func _card(id:String,heading:String,description:String,p:Vector2,s:Vector2,unlocked:bool,portrait:bool)->void:
	var card:=Panel.new()
	body.add_child(card)
	card.position=p
	card.size=s
	card.pivot_offset=s*.5
	var frame:=StyleBoxFlat.new()
	frame.bg_color=INK
	frame.set_border_width_all(2 if unlocked else 1)
	frame.border_color=GOLD if unlocked else Color("566864")
	frame.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel",frame)
	var photo:=_image(card,id,Vector2(3,3),s-Vector2(6,6 if portrait else 74))
	if not unlocked:photo.modulate=Color(.82,.86,.86,1.)
	var caption:=ColorRect.new()
	card.add_child(caption)
	caption.position=Vector2(2,s.y-74)
	caption.size=Vector2(s.x-4,72)
	caption.color=Color(.04,.13,.14,.88) if portrait else (Color("153c3a") if unlocked else Color("172b2d"))
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_text(card,heading,Vector2(18,s.y-68),Vector2(s.x-36,32),23,GOLD if unlocked else Color("b5c4bf"))
	_text(card,description,Vector2(18,s.y-32),Vector2(s.x-36,27),13,Color("d1d9c7"))
	var badge:=_text(card,"●  已选择" if unlocked else "◇  未开放",Vector2(14,12),Vector2(130,25),14,CREAM)
	badge.add_theme_color_override("font_shadow_color",Color(0,0,0,.6))
	badge.add_theme_constant_override("shadow_offset_y",1)
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
	card.mouse_entered.connect(func():_hover_card(card,p,true,unlocked))
	card.mouse_exited.connect(func():_hover_card(card,p,false,unlocked))
	card.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			ui_sound.emit()
			status.text="已选择苔苔，请前往目的地。" if unlocked and portrait else ("已选择风铃草甸，准备好就出发。" if unlocked else heading+"尚未开放，当前版本可游玩苔苔的草甸来信。"))

func _hover_card(card:Control,base:Vector2,hovered:bool,unlocked:bool)->void:
	if not unlocked:return
	if card.has_meta("hover_tween"):
		var old:Tween=card.get_meta("hover_tween")
		if old.is_valid():old.kill()
	var tween:=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card,"position",base-Vector2(0,7) if hovered else base,.25)
	tween.tween_property(card,"scale",Vector2.ONE*(1.015 if hovered else 1.),.25)
	card.set_meta("hover_tween",tween)

func _animate_content()->void:
	# AnimatedContent mapping: translate + opacity, cubic out, staggered children.
	var i:=0
	for child in body.get_children():
		if not child is Control:continue
		var base:Vector2=child.position
		child.position.y+=18
		child.modulate.a=0
		var tween:=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(child,"position",base,.5).set_delay(i*.035)
		tween.tween_property(child,"modulate:a",1.,.5).set_delay(i*.035)
		i+=1

func _navigate(page:int)->void:
	stage=page
	_build_page()
func _enter()->void:
	if not available or transitioning:return
	# Request browser pointer lock from the real button gesture, before the fade tween.
	if not OS.has_feature("web") or JavaScriptBridge.eval("document.hasFocus()",true):
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	transitioning=true
	next_button.disabled=true
	var restart:=restart_box.button_pressed
	var tween:=create_tween()
	tween.tween_property(self,"modulate:a",0.,.45)
	tween.tween_callback(func():enter_requested.emit(restart);transitioning=false)

extends Control
var actor: Node3D
var target := Vector3.ZERO
var places:Array=[]
func _process(_dt:float)->void:queue_redraw()
func _draw()->void:
	var center:=size*.5
	var r:=minf(size.x,size.y)*.46
	draw_circle(center,r+5,Color("d0c5a2"))
	draw_circle(center,r,Color("28493f"))
	draw_arc(center,r-8,0,TAU,80,Color(.7,.8,.6,.25),1.5,true)
	var outline:=PackedVector2Array()
	for i in 80:
		var a:=TAU*i/80.
		var k:=r*(.76+sin(a*5.)*.07+cos(a*3.)*.08)
		outline.append(center+Vector2(cos(a),sin(a))*k)
	draw_colored_polygon(outline,Color("769775"))
	var trail:=PackedVector2Array()
	for i in 30:trail.append(center+Vector2(sin(i*.3)*5,(float(i)/29.-.5)*r*1.25))
	draw_polyline(trail,Color("d6c79a"),3,true)
	for p in places:draw_circle(_point(p,center,r),3,Color("f5df9c"))
	draw_circle(_point(target,center,r),5,Color("ffd574"))
	if actor:
		var pos:=_point(actor.global_position,center,r)
		draw_circle(pos,4.5,Color("ffffff"))
		draw_arc(pos,8,0,TAU,20,Color(1,1,1,.5),1,true)
func _point(p:Vector3,c:Vector2,r:float)->Vector2:return c+Vector2(p.x,(p.z+20))*r/44.

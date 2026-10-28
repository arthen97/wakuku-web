shader_type canvas_item;
// Godot adaptation of React Bits ShinyText's moving, softened highlight band.
uniform float span = 650.0;
varying vec2 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 float progress=mod(TIME,7.)/3.;
 float x=(local_position.x+local_position.y*.3)/span;
 float band=1.-smoothstep(.025,.13,abs(x-(progress*1.7-.25)));
 COLOR.rgb=mix(COLOR.rgb,vec3(1.,.98,.87),band*.65);
}

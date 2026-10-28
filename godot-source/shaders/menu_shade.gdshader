shader_type canvas_item;
void fragment(){
 float shade=mix(.87,.18,smoothstep(.08,.83,UV.x));
 float edge=smoothstep(.4,.72,length((UV-.5)*vec2(.8,1.)));
 COLOR=vec4(.025,.075,.075,clamp(shade+edge*.23,0.,.95));
}

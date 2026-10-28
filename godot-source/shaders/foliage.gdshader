shader_type spatial;
render_mode cull_disabled,diffuse_burley;
uniform sampler2D albedo_tex:source_color,filter_linear_mipmap_anisotropic;
uniform vec4 tint:source_color=vec4(1.);
uniform vec3 walker=vec3(999.);
uniform float height=.4;
uniform bool sway=true;
varying float sunlight;
void vertex(){
 vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 float weight=clamp(VERTEX.y/max(height,.1),0.,1.);
 if(sway){
  float wave=sin(TIME*1.1+w.x*.8+w.z*.45)*.022+sin(TIME*1.8+w.z)*.009;
  VERTEX.x+=wave*weight;
  vec3 away=w-walker;float push=(1.-smoothstep(.1,.75,length(away.xz)))*weight;
  vec3 local=(inverse(MODEL_MATRIX)*vec4(normalize(away+vec3(.001))*push*.24,0.)).xyz;
  VERTEX+=local;VERTEX.y-=push*.08;
 }
 sunlight=.12;
}
void fragment(){vec4 c=texture(albedo_tex,UV)*tint;ALBEDO=tint.rgb*(.8+c.r*.2);ALPHA=texture(albedo_tex,UV).r;ALPHA_SCISSOR_THRESHOLD=.42;ROUGHNESS=.94;SPECULAR=.04;BACKLIGHT=c.rgb*.25;}

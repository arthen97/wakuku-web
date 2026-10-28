shader_type spatial;
render_mode diffuse_burley;
#include "res://shaders/caustics.gdshaderinc"
uniform sampler2D painted_ground:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float n=noise(world.xz*.13)*.72+noise(world.xz*.37)*.28;
 vec3 grass=mix(vec3(.17,.26,.055),vec3(.30,.40,.115),smoothstep(.15,.86,n));
 float footpath=1.-smoothstep(1.0,2.5,abs(world.x-sin(world.z*.13)*1.5));
 vec3 soil=mix(vec3(.40,.31,.16),vec3(.57,.47,.27),noise(world.xz*.6));
 float grain=noise(world.xz*9.)*.025;
 vec3 paint=texture(painted_ground,world.xz*.12).rgb;
 float brush=dot(paint,vec3(.3,.5,.2));
 ALBEDO=(mix(grass,soil,footpath*.82)+grain)*(.84+brush*.48);
 float bank=1.-smoothstep(1.6,3.1,abs(world.z+23.));
 if(bank>.001){
  float caustic=creek_caustics(world.xz*2.8,TIME)*bank;
  ALBEDO+=vec3(.025,.035,.023)*caustic;
  EMISSION=vec3(.012,.018,.011)*caustic;
 }
 ROUGHNESS=.94;SPECULAR=.1;
}

shader_type spatial;
render_mode diffuse_burley;
#include "res://shaders/caustics.gdshaderinc"
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;VERTEX.y+=sin(world.x*1.8+TIME*.7)*.009;}
void fragment(){
 float ripple=sin(world.x*8.+world.z*1.7+TIME*.7)*sin(world.z*5.-TIME*.4);
 float caustic=creek_caustics(world.xz*2.8,TIME);
 ALBEDO=mix(vec3(.08,.34,.32),vec3(.27,.56,.48),ripple*.15+.4)+vec3(.055,.09,.07)*caustic;
 EMISSION=vec3(.015,.025,.018)*caustic;
 ROUGHNESS=.30;SPECULAR=.45;METALLIC=.02;
}

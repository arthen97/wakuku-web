shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled;
uniform sampler2D scene_color:hint_screen_texture,filter_linear;
uniform sampler2D scene_depth:hint_depth_texture,filter_nearest;
uniform float focus_end=13.0;
void vertex(){POSITION=vec4(VERTEX.xy,0.,1.);}
float distance_at(vec2 uv, mat4 inverse_projection){
 float z=texture(scene_depth,uv).r;
 vec4 p=inverse_projection*vec4(vec3(uv,z)*2.-1.,1.);
 return -p.z/p.w;
}
void fragment(){
 vec2 uv=SCREEN_UV;
 float depth=distance_at(uv,INV_PROJECTION_MATRIX);
 float blur=smoothstep(focus_end,focus_end+32.,depth)*1.05;
 vec2 pixel=vec2(1.)/VIEWPORT_SIZE;
 vec3 color=texture(scene_color,uv).rgb;
 float weight=1.;
 for(int i=0;i<8;i++){
  float angle=float(i)*.785398;
  vec2 sample_uv=clamp(uv+vec2(cos(angle),sin(angle))*pixel*blur,vec2(.001),vec2(.999));
  float edge=1.-smoothstep(.5,3.,abs(distance_at(sample_uv,INV_PROJECTION_MATRIX)-depth));
  color+=texture(scene_color,sample_uv).rgb*edge;
  weight+=edge;
 }
 ALBEDO=color/weight;
}

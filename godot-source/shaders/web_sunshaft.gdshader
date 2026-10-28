shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
void fragment(){
 float side=pow(max(0.,1.-abs(UV.x-.5)*2.),2.);
 float ends=smoothstep(0.,.18,UV.y)*(1.-smoothstep(.7,1.,UV.y));
 float veil=.8+.2*sin(UV.y*6.+TIME*.18);
 ALBEDO=vec3(1.,.88,.58);
 ALPHA=side*ends*veil*.045;
}

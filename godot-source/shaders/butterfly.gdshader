shader_type spatial;
render_mode cull_disabled,unshaded;
uniform sampler2D atlas:source_color,filter_linear_mipmap;
uniform float phase=0.;
void fragment(){vec2 uv=vec2(UV.x,(UV.y+mod(floor(TIME*22.+phase),8.))/8.);vec4 c=texture(atlas,uv);ALBEDO=c.rgb;ALPHA=c.a;ALPHA_SCISSOR_THRESHOLD=.42;}

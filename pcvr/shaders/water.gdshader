shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D water_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
    vec2 p = UV * 43.0;
    vec2 wave = vec2(sin(p.y * 0.18 + TIME * 0.7), cos(p.x * 0.22 + TIME * 0.55)) * 0.11;
    vec3 tex = texture(water_tex, p + wave + vec2(TIME * 0.016, TIME * 0.009)).rgb;
    ALBEDO = mix(tex, vec3(0.13, 0.56, 0.78), 0.30);
    ROUGHNESS = 0.24;
    METALLIC = 0.05;
}

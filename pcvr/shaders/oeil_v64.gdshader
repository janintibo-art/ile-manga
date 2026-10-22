shader_type spatial;
// V64 : l'œil — blanc veiné, iris coloré (texture de fibres en niveaux de gris), pupille, reflet humide.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 iris : source_color = vec3(0.35, 0.25, 0.15);
uniform float lueur = 0.0;

void fragment() {
	vec4 e = texture(tex, UV);
	vec3 col = mix(e.rgb, e.rgb * iris * 2.2, e.a);
	ALBEDO = col;
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
	EMISSION = col * lueur;
}

shader_type spatial;
// V70 : l'œil d'un démon de Pandémonia — le même œil que oeil_v64 (blanc veiné, iris de fibres,
// pupille, reflet humide), mais l'iris luit comme une braise : seules les fibres de l'iris
// émettent (pas le blanc de l'œil, pas la pupille). « lueur » monte à la nuit tombée.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 iris : source_color = vec3(1.0, 0.5, 0.15);
uniform float lueur = 0.5;

void fragment() {
	vec4 e = texture(tex, UV);
	vec3 col = mix(e.rgb, e.rgb * iris * 2.2, e.a);
	ALBEDO = col;
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
	float fibres = smoothstep(0.06, 0.42, dot(e.rgb, vec3(0.333)));
	EMISSION = iris * e.a * lueur * (0.2 + 0.9 * fibres);
}

shader_type spatial;
// V64 : la peau des habitants — teint, lèvres, sourcils, barbe rasée, cheveux ras peints,
// rides selon l'âge, grain de peau, diffusion sous la surface (Forward+).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D teint : hint_default_white, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D masques1 : hint_default_black, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D masques2 : hint_default_black, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D grain_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D rides_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;

uniform vec3 peau : source_color = vec3(0.86, 0.66, 0.54);
uniform vec3 levres : source_color = vec3(0.72, 0.38, 0.36);
uniform float levres_force = 0.7;
uniform vec3 sourcils : source_color = vec3(0.18, 0.11, 0.07);
uniform float sourcils_epais = 0.5;
uniform vec3 poils : source_color = vec3(0.12, 0.08, 0.05);
uniform vec3 barbe = vec3(0.0);          // densité (moustache, menton, joues)
uniform vec3 cheveux : source_color = vec3(0.12, 0.08, 0.05);
uniform float crane = 0.0;               // cheveux ras peints sur le crâne
uniform float age = 0.0;                 // rides
uniform vec3 fard : source_color = vec3(0.45, 0.32, 0.4);
uniform float fard_force = 0.0;
uniform float rose = 0.25;
uniform float diffusion = 0.35;
uniform float lueur = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float follicles(vec2 uv, float scale) {
	vec2 g = uv * scale;
	vec2 i = floor(g);
	vec2 f = fract(g) - 0.5;
	vec2 o = vec2(hash(i), hash(i + 17.0)) - 0.5;
	float d = length(f - o * 0.6);
	return smoothstep(0.42, 0.12, d);
}

void fragment() {
	vec3 t = texture(teint, UV).rgb * 2.0;
	vec3 col = peau * t;
	vec4 m1 = texture(masques1, UV);
	vec4 m2 = texture(masques2, UV);
	// lèvres
	float lip = clamp(m1.r * 1.15, 0.0, 1.0) * levres_force;
	col = mix(col, levres * mix(vec3(1.0), t, 0.6), lip);
	// rose aux joues, fard aux paupières
	col *= mix(vec3(1.0), vec3(1.0, 0.86, 0.86), m2.a * rose);
	col = mix(col, col * fard * 2.0, m2.b * fard_force);
	// barbe rasée ou de quelques jours : ombre + points
	float dens = clamp(dot(barbe, vec3(m1.b, m1.a, m2.r)), 0.0, 1.5);
	float fol = follicles(UV, 1900.0);
	float stub = clamp(dens * (0.45 + 0.75 * fol), 0.0, 0.92);
	col = mix(col, mix(col, poils, 0.75), stub);
	// cheveux ras peints sur le crâne
	float sc = clamp(m2.g * crane, 0.0, 1.0);
	float fol2 = follicles(UV + 0.37, 2300.0);
	col = mix(col, cheveux * (0.75 + 0.35 * fol2), sc * (0.7 + 0.3 * fol2));
	// sourcils
	float b = smoothstep(0.42 - 0.3 * sourcils_epais, 0.82 - 0.3 * sourcils_epais, m1.g);
	col = mix(col, sourcils, b * 0.92);
	ALBEDO = col;
	// relief : grain + rides (âge)
	vec2 g = texture(grain_n, UV).xy * 2.0 - 1.0;
	vec2 r = texture(rides_n, UV).xy * 2.0 - 1.0;
	vec2 n = g * 1.0 + r * age + vec2(fol - 0.5) * 0.0;
	NORMAL_MAP = vec3(n * 0.5 + 0.5, 1.0);
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = mix(0.58, 0.42, lip) + 0.12 * max(stub, sc) + 0.08 * b;
	SPECULAR = 0.42;
	SSS_STRENGTH = diffusion;
	EMISSION = col * lueur;
}

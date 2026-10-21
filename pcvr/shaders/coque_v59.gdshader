// V59 : la coque du Léviathan, l'épave géante de Carène.
// Le bordé de chêne vieilli ; sous la ligne de flottaison, la carène se couvre de moules,
// de balanes et d'algues ; juste au-dessus, une bande de sel blanchie et une coque mouillée
// qui sèche en remontant ; la peinture se délave vers le haut.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D planks_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D planks_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fouling_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fouling_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float water_level = -0.42;
uniform float fouling_top = 1.2;
uniform vec3 tint : source_color = vec3(1.0);
// V59 : la peinture du Léviathan, posée selon la hauteur dans le repère du navire
uniform mat4 hull_inv = mat4(1.0);
uniform bool hull_paint = false;
uniform float deck_h = 19.5;
// V60 : la couleur de la bande des sabords et l'échelle des bandes (navires plus petits)
uniform vec3 band_color : source_color = vec3(0.74, 0.52, 0.22);
uniform float band_scale = 1.0;

varying vec3 world_position;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x),
		mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 wp = world_position;
	float wave = noise2(wp.xz * 0.35 + vec2(wp.y)) * 0.6 + noise2(UV * 3.0) * 0.5;
	float foul = 1.0 - smoothstep(fouling_top - 0.6, fouling_top + 0.4, wp.y + (wave - 0.5) * 0.9);
	vec3 wood = texture(planks_tex, UV).rgb * tint;
	if (hull_paint) {
		vec3 lp = (hull_inv * vec4(wp, 1.0)).xyz;
		lp.y = deck_h - (deck_h - lp.y) / band_scale;
		float flake = smoothstep(0.18, 0.45, noise2(UV * vec2(9.0, 3.0)) * 0.7 + noise2(UV * 31.0) * 0.4);
		// sous la préceinte : brai noir délavé ; la préceinte noire ; la bande ocre des sabords ; le liston noir
		float low = 1.0 - smoothstep(deck_h - 6.2, deck_h - 6.0, lp.y);
		float wale = smoothstep(deck_h - 6.0, deck_h - 5.9, lp.y) * (1.0 - smoothstep(deck_h - 4.7, deck_h - 4.6, lp.y));
		float ochre = smoothstep(deck_h - 4.6, deck_h - 4.5, lp.y) * (1.0 - smoothstep(deck_h - 1.3, deck_h - 1.2, lp.y));
		float top = smoothstep(deck_h - 1.2, deck_h - 1.1, lp.y);
		vec3 tar = vec3(0.09, 0.085, 0.08);
		vec3 och = band_color;
		wood = mix(wood, wood * 0.62 + tar * 0.3, low * 0.45 * flake);
		wood = mix(wood, tar * (0.9 + 0.3 * noise2(UV * 40.0)), (wale + top) * mix(0.5, 0.92, flake));
		wood = mix(wood, och * (0.8 + 0.35 * noise2(UV * 23.0)), ochre * 0.95 * flake);
		// coulures de rouille sous les cadènes et les ferrures
		float rust = smoothstep(0.82, 0.95, noise2(vec2(lp.x * 0.7, 0.0))) * smoothstep(deck_h - 1.0, deck_h - 9.0, lp.y) * smoothstep(deck_h - 14.0, deck_h - 3.0, lp.y);
		wood = mix(wood, vec3(0.38, 0.18, 0.08), rust * 0.45 * noise2(vec2(lp.x * 3.0, lp.y * 0.4)));
	}
	vec3 shell = texture(fouling_tex, UV * 0.8).rgb;
	// une bande de sel au-dessus de la ligne d'eau, la coque mouillée qui sèche en montant
	float salt = smoothstep(fouling_top - 0.2, fouling_top + 0.3, wp.y) * (1.0 - smoothstep(fouling_top + 0.6, fouling_top + 2.4, wp.y + wave));
	float wet = 1.0 - smoothstep(water_level, water_level + 1.6, wp.y);
	vec3 albedo = mix(wood, shell, foul);
	albedo = mix(albedo, vec3(0.78, 0.76, 0.7), salt * 0.45 * (1.0 - foul));
	albedo *= mix(1.0, 0.6, wet);
	// sous l'eau, tout se fonce et verdit
	albedo *= mix(vec3(1.0), vec3(0.55, 0.7, 0.65), 1.0 - smoothstep(water_level - 3.0, water_level, wp.y));
	vec3 nm = mix(texture(planks_n, UV).xyz, texture(fouling_n, UV * 0.8).xyz, foul);
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = 1.2;
	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.86, 0.95, foul), 0.35, wet * 0.8);
	SPECULAR = mix(0.35, 0.6, wet);
}

// V75 : sol de l'Île du Boucan (même famille que les sols V69, V70, V71). Une carte des sols
// (« biome », cuite par ile_boucan_v75.gd) dit où vont la terre noire (R : les chemins, l'enceinte de
// l'usine), le gravier (G : la casse, le feu de camp), la mousse bleu-vert des spores (B : le
// Gazomètre) et le béton de la ville-friche (A : avec des plaques d'asphalte). Ailleurs, l'herbe sèche
// des friches ; sur les grèves, le sable gris (au nord-ouest, la plage du cargo) ou les galets ; les
// murs des quais et du bassin (les pentes raides de la ville) sont en béton.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D herbe_seche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_seche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravier_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravier_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalte_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalte_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_noire_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_noire_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D galets_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D galets_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mousse_spores_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mousse_spores_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_gris_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_gris_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);   // x0, z0, largeur, profondeur
uniform vec2 center = vec2(-30.0, 790.0);
uniform bool extra_detail = false;
uniform float water_level = -0.42;
uniform float glow = 0.0;                            // la mousse des spores luit la nuit (temps_v56)

varying vec3 world_position;
varying vec3 world_normal;

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

vec2 rot_uv(vec2 uv) {
	return mat2(vec2(0.857, 0.515), vec2(-0.515, 0.857)) * uv * 0.71 + vec2(0.37, 0.61);
}

vec4 untiled(sampler2D t, vec2 uv, float mixer) {
	return mix(texture(t, uv), texture(t, rot_uv(uv)), mixer);
}

vec3 untiled_normal(sampler2D t, vec2 uv, float mixer) {
	vec3 a = texture(t, uv).xyz * 2.0 - 1.0;
	vec3 b = texture(t, rot_uv(uv)).xyz * 2.0 - 1.0;
	return normalize(mix(a, b, mixer));
}

vec3 triplanar(sampler2D t, vec3 p, vec3 w, float s) {
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}

vec3 triplanar_n(sampler2D t, vec3 p, vec3 w, float s) {
	return (texture(t, p.zy * s).xyz * w.x + texture(t, p.xz * s).xyz * w.y + texture(t, p.xy * s).xyz * w.z) * 2.0 - 1.0;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wp = world_position;
	vec3 n = normalize(world_normal);
	float slope = 1.0 - clamp(n.y, 0.0, 1.0);
	float dist = length(CAMERA_POSITION_WORLD - wp);
	vec2 uv = wp.xz * 0.2;
	float mixer = smoothstep(0.25, 0.75, noise2(wp.xz * 0.045));
	float macro = noise2(wp.xz * 0.018);
	float patch = noise2(wp.xz * 0.09 + 13.0);
	vec2 lc = wp.xz - center;

	vec4 b = texture(biome, (wp.xz - biome_rect.xy) / biome_rect.zw);
	float wob = (patch - 0.5) * 0.3;
	float w_dirt = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_gravel = smoothstep(0.25, 0.7, b.g + wob * 0.4);
	float w_moss = clamp(b.b + wob * 0.6, 0.0, 1.0);
	float w_town = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.08);

	// les grèves : le sable gris de la plage du cargo, ailleurs les galets
	float beach = (1.0 - smoothstep(0.7, 2.0, wp.y + (macro - 0.5) * 1.2)) * (1.0 - w_town);
	float sandy = smoothstep(-100.0, -130.0, lc.x) * smoothstep(-100.0, -140.0, lc.y);
	// les murs des quais, du bassin, de la cale sèche : du béton (les pentes raides de la ville) ;
	// ailleurs, la terre nue
	float steep = smoothstep(0.42, 0.6, slope + (patch - 0.5) * 0.08);

	vec3 grass = mix(untiled(herbe_seche_tex, uv * 1.1, mixer).rgb, untiled(herbe_seche_tex, uv * 0.41 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	// des nuances : de l'herbe sèche dorée, du vert des friches, du roux
	grass *= mix(vec3(0.92, 0.98, 0.86), vec3(1.08, 1.02, 0.86), macro);
	grass = mix(grass, grass * vec3(0.86, 1.06, 0.8), smoothstep(0.62, 0.92, patch) * 0.4);
	vec3 dirt = untiled(terre_noire_tex, uv * 1.2, mixer).rgb;
	vec3 gravel = untiled(gravier_tex, uv * 1.3, mixer).rgb;
	vec3 moss = untiled(mousse_spores_tex, uv * 1.1, mixer).rgb;
	vec3 conc = untiled(beton_tex, uv * 0.8, mixer).rgb;
	vec3 asph = untiled(asphalte_tex, uv * 0.9, mixer).rgb;
	float asph_w = smoothstep(0.45, 0.6, noise2(wp.xz * 0.022 + 7.0));
	vec3 town = mix(conc, asph, asph_w);
	vec3 sand = mix(untiled(galets_tex, uv * 1.2, mixer).rgb, untiled(sable_gris_tex, uv * 1.15, mixer).rgb, sandy);
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(herbe_seche_tex, uv * 3.3).rgb, 0.2 * near);
		dirt = mix(dirt, texture(terre_noire_tex, uv * 3.1).rgb, 0.18 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 wall_town = triplanar(beton_tex, wp, tri, 0.18);
	vec3 wall_wild = triplanar(terre_noire_tex, wp, tri, 0.12);

	vec3 ground = grass;
	ground = mix(ground, moss, w_moss);
	ground = mix(ground, gravel, w_gravel);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, town, w_town);
	vec3 albedo = mix(ground, sand, beach);
	float town_near = max(w_town, smoothstep(-60.0, -110.0, lc.y));
	albedo = mix(albedo, mix(wall_wild, wall_town, town_near), steep);

	// mouillé au bord de l'eau
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * max(beach, steep);
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.7, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = untiled_normal(herbe_seche_n, uv * 1.1, mixer);
	nm_ground = normalize(mix(nm_ground, untiled_normal(mousse_spores_n, uv * 1.1, mixer), w_moss));
	nm_ground = normalize(mix(nm_ground, untiled_normal(gravier_n, uv * 1.3, mixer), w_gravel));
	nm_ground = normalize(mix(nm_ground, untiled_normal(terre_noire_n, uv * 1.2, mixer), w_dirt));
	vec3 nm_town = normalize(mix(untiled_normal(beton_n, uv * 0.8, mixer), untiled_normal(asphalte_n, uv * 0.9, mixer), asph_w));
	nm_ground = normalize(mix(nm_ground, nm_town, w_town));
	nm_ground = normalize(mix(nm_ground, mix(untiled_normal(galets_n, uv * 1.2, mixer), untiled_normal(sable_gris_n, uv * 1.15, mixer), sandy), beach));
	vec3 nm_wall = normalize(triplanar_n(beton_n, wp, tri, 0.18));
	vec3 nm = normalize(mix(nm_ground, nm_wall, steep));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = 0.94;
	ROUGHNESS = mix(ROUGHNESS, 0.88, w_town);
	ROUGHNESS = mix(ROUGHNESS, 0.8, w_town * asph_w);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.38, 0.55, wet);
	// la mousse des spores : une lueur bleu-vert la nuit, en taches
	EMISSION = moss * vec3(0.3, 0.9, 1.0) * w_moss * glow * smoothstep(0.35, 0.75, patch) * 0.6;
}

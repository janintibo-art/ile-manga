// V69 : sol de l'Île des Trois Soleils (même famille que les sols V68). Une carte des sols
// (« biome », cuite par ile_soleils_v69.gd) dit où vont le sable du plateau de Rê (R), le sol
// de la jungle (G), le limon noir des berges et des champs (B) et le dallage (A : l'esplanade
// de Yaxché, blanchie à la chaux ; Aztlán et ses chaussées). Ailleurs, l'herbe grasse des
// prairies ; la roche sur les pentes raides et le haut du Mont Fumant (cendres) ; du sable sur
// les grèves.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D herbe_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D jungle_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D jungle_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D limon_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D limon_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dalles_soleil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dalles_soleil_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);   // x0, z0, largeur, profondeur
uniform vec4 plaza_m = vec4(0.0, 0.0, 1.0, 1.0);      // centre x, z, demi-largeur, demi-profondeur
uniform vec4 volcano = vec4(0.0, 0.0, 40.0, 140.0);   // centre x, z, rayon de la cendre, rayon d'influence
uniform float lake_y = 6.0;
uniform bool extra_detail = false;
uniform float water_level = -0.42;

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
	float macro = noise2(wp.xz * 0.02);
	float patch = noise2(wp.xz * 0.09 + 13.0);

	vec4 b = texture(biome, (wp.xz - biome_rect.xy) / biome_rect.zw);
	// les bords de la carte des sols, un peu brouillés (pas de lignes droites)
	float wob = (patch - 0.5) * 0.35;
	float w_sand = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_jungle = clamp(b.g + wob * 0.6, 0.0, 1.0) * (1.0 - w_sand);
	float w_silt = clamp(b.b + wob * 0.5, 0.0, 1.0);
	float w_pave = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.08);

	// la grève : jusqu'à ~1,5 m au-dessus de la mer (pas sur les berges du fleuve : du limon)
	float beach = (1.0 - smoothstep(0.9, 2.1, wp.y + (macro - 0.5) * 1.4)) * (1.0 - w_silt) * (1.0 - w_pave);
	// le Mont Fumant : des cendres et de la roche nue vers le sommet
	float vd = length(wp.xz - volcano.xy);
	float ash = smoothstep(42.0, 70.0, wp.y + (macro - 0.5) * 16.0) * (1.0 - smoothstep(volcano.w * 0.6, volcano.w, vd));
	float rock_w = max(smoothstep(0.5, 0.6, slope + (patch - 0.5) * 0.06) * (1.0 - w_pave), ash);

	vec3 grass = mix(untiled(herbe_tex, uv * 1.1, mixer).rgb, untiled(herbe_tex, uv * 0.43 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	grass *= mix(vec3(0.88, 0.94, 0.82), vec3(1.06, 1.02, 0.9), macro);
	vec3 jungle = untiled(jungle_tex, uv * 1.25, mixer).rgb * mix(vec3(0.85, 0.92, 0.82), vec3(1.05, 1.0, 0.92), macro);
	vec3 sand = untiled(sable_tex, uv * 1.15, mixer).rgb * mix(vec3(0.96, 0.92, 0.84), vec3(1.04, 1.0, 0.94), macro);
	vec3 silt = untiled(limon_tex, uv * 1.3, mixer).rgb * mix(vec3(0.9), vec3(1.06), macro);
	vec3 pave = untiled(dalles_soleil_tex, uv * 0.75, 0.0).rgb;
	// l'esplanade de Yaxché : un sol de stuc blanchi à la chaux
	vec2 pd = abs(wp.xz - plaza_m.xy) - plaza_m.zw;
	float maya = 1.0 - smoothstep(0.0, 6.0, length(max(pd, vec2(0.0))));
	pave *= mix(vec3(0.94, 0.9, 0.84), vec3(1.08, 1.06, 1.02), maya);
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(herbe_tex, uv * 3.3).rgb, 0.22 * near);
		jungle = mix(jungle, texture(jungle_tex, uv * 3.0).rgb, 0.22 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(roche_tex, wp, tri, 0.09);
	rock *= mix(0.82, 1.05, smoothstep(0.0, 40.0, wp.y));
	rock = mix(rock, rock * vec3(0.55, 0.52, 0.5), ash * 0.6);

	vec3 ground = mix(grass, jungle, w_jungle);
	ground = mix(ground, sand, w_sand);
	ground = mix(ground, silt, w_silt * (1.0 - w_sand * 0.5));
	ground = mix(ground, pave, w_pave);
	vec3 albedo = mix(ground, sand, beach);
	albedo = mix(albedo, rock, rock_w);

	// mouillé au bord de l'eau (la mer, le fleuve, le lac)
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * max(beach, w_silt);
	float lake_wet = (1.0 - smoothstep(lake_y + 0.02, lake_y + 0.55, wp.y)) * smoothstep(lake_y - 3.5, lake_y - 0.2, wp.y) * (1.0 - w_pave);
	wet = max(wet, lake_wet * 0.8);
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = normalize(mix(untiled_normal(herbe_n, uv * 1.1, mixer), untiled_normal(jungle_n, uv * 1.25, mixer), w_jungle));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_n, uv * 1.15, mixer), max(w_sand, beach)));
	nm_ground = normalize(mix(nm_ground, untiled_normal(limon_n, uv * 1.3, mixer), w_silt));
	nm_ground = normalize(mix(nm_ground, texture(dalles_soleil_n, uv * 0.75).xyz * 2.0 - 1.0, w_pave));
	vec3 nm_rock = normalize(triplanar_n(roche_n, wp, tri, 0.09));
	vec3 nm = normalize(mix(nm_ground, nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.93, 0.96, w_jungle), 0.72, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.8, w_pave);
	ROUGHNESS = mix(ROUGHNESS, 0.32, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
}

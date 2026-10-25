// V71 : sol de l'Île de Montjoie (même famille que les sols V69 et V70). Une carte des sols
// (« biome », cuite par ile_montjoie_v71.gd) dit où vont la terre battue (R : les chemins, la cour
// de la ferme, le camp des gobelins), les champs labourés (G), le sous-bois (B : le Bois des Lutins)
// et les pavés de la ville et du quai (A). Ailleurs, la prairie, plus ou moins verte ; la roche
// grise et ocre sur les pentes raides et sur les Crocs ; le sable sur les grèves et au bord du lac.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D prairie_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D prairie_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D champ_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D champ_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D chemin_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D chemin_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sous_bois_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sous_bois_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_crocs_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_crocs_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_lac_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_lac_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);   // x0, z0, largeur, profondeur
uniform vec4 lake = vec4(0.0, 0.0, 50.0, 40.0);       // centre x, z, demi-axes
uniform float lake_y = 3.2;
uniform vec4 town = vec4(0.0, 0.0, 162.0, 0.0);       // centre x, z, rayon du rempart
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
	float macro = noise2(wp.xz * 0.018);
	float patch = noise2(wp.xz * 0.09 + 13.0);

	vec4 b = texture(biome, (wp.xz - biome_rect.xy) / biome_rect.zw);
	float wob = (patch - 0.5) * 0.3;
	float w_dirt = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_field = smoothstep(0.3, 0.7, b.g);
	float w_forest = clamp(b.b + wob * 0.5, 0.0, 1.0);
	float w_pave = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.06);

	// les grèves de sable (la mer) et le bord du lac
	float beach = (1.0 - smoothstep(0.9, 2.2, wp.y + (macro - 0.5) * 1.4)) * (1.0 - w_pave);
	vec2 lk = (wp.xz - lake.xy) / lake.zw;
	float lq = length(lk);
	float shore = (1.0 - smoothstep(1.02, 1.16 + (patch - 0.5) * 0.06, lq)) * (1.0 - smoothstep(lake_y + 0.9, lake_y + 1.6, wp.y));
	beach = max(beach, shore);
	// la roche : les pentes raides (pas dans la ville : ses murs les cachent)
	float in_town = 1.0 - smoothstep(town.z - 2.0, town.z + 4.0, length(wp.xz - town.xy));
	float rock_w = smoothstep(0.5, 0.62, slope + (patch - 0.5) * 0.08) * (1.0 - w_pave);
	// les Crocs : la roche affleure aussi sur les sommets
	float high = smoothstep(18.0, 30.0, wp.y + (macro - 0.5) * 10.0) * (1.0 - in_town);
	rock_w = max(rock_w, high * smoothstep(0.18, 0.32, slope + (patch - 0.5) * 0.1));

	vec3 grass = mix(untiled(prairie_tex, uv * 1.1, mixer).rgb, untiled(prairie_tex, uv * 0.41 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	// des nuances : vert tendre, vert profond, un peu de jaune sec
	grass *= mix(vec3(0.86, 0.95, 0.82), vec3(1.08, 1.04, 0.9), macro);
	grass = mix(grass, grass * vec3(1.12, 1.05, 0.78), smoothstep(0.6, 0.9, patch) * 0.35);
	vec3 field = untiled(champ_tex, uv * 0.9, 0.0).rgb;
	vec3 dirt = untiled(chemin_tex, uv * 1.2, mixer).rgb;
	vec3 forest = untiled(sous_bois_tex, uv * 1.15, mixer).rgb;
	vec3 sand = untiled(sable_lac_tex, uv * 1.15, mixer).rgb;
	vec3 pave = untiled(paves_tex, uv * 0.85, 0.0).rgb;
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(prairie_tex, uv * 3.3).rgb, 0.2 * near);
		dirt = mix(dirt, texture(chemin_tex, uv * 3.1).rgb, 0.18 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(roche_crocs_tex, wp, tri, 0.08);

	vec3 ground = grass;
	ground = mix(ground, forest, w_forest);
	ground = mix(ground, field, w_field);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, pave, w_pave);
	vec3 albedo = mix(ground, sand, beach);
	albedo = mix(albedo, rock, rock_w);

	// mouillé au bord de l'eau
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * beach;
	wet = max(wet, (1.0 - smoothstep(lake_y + 0.05, lake_y + 0.5, wp.y)) * shore);
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = untiled_normal(prairie_n, uv * 1.1, mixer);
	nm_ground = normalize(mix(nm_ground, untiled_normal(sous_bois_n, uv * 1.15, mixer), w_forest));
	nm_ground = normalize(mix(nm_ground, texture(champ_n, uv * 0.9).xyz * 2.0 - 1.0, w_field));
	nm_ground = normalize(mix(nm_ground, untiled_normal(chemin_n, uv * 1.2, mixer), w_dirt));
	nm_ground = normalize(mix(nm_ground, texture(paves_n, uv * 0.85).xyz * 2.0 - 1.0, w_pave));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_lac_n, uv * 1.15, mixer), beach));
	vec3 nm_rock = normalize(triplanar_n(roche_crocs_n, wp, tri, 0.08));
	vec3 nm = normalize(mix(nm_ground, nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.93, 0.85, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.95, w_field);
	ROUGHNESS = mix(ROUGHNESS, 0.76, w_pave);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
}

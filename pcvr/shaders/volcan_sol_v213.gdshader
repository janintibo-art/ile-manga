// V213 : le sol de l'Île Foraine, devenue volcanique (d'après le sol de l'Île des Géants, V142).
// La cendre grise à la place de la prairie, le sable noir sur les grèves, le basalte sombre sur les
// pentes (et tout le volcan), la mousse rase par plaques. La carte des sols (« biome », cuite par
// ile_foraine_v209.gd) : R la terre battue, G la lave (une croûte noire, ses fissures rougeoient et
// éclairent la nuit), B la mousse, A les dalles.
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
uniform float gscale = 0.45;
uniform sampler2D lave_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lave_e : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float lave_force = 2.6;
uniform vec3 volcan = vec3(0.0, 0.0, 96.0);       // centre x, z, rayon du volcan

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
	float w_field = 0.0;
	float w_lave = smoothstep(0.25, 0.6, b.g + (patch - 0.5) * 0.25 * b.g);
	float w_forest = smoothstep(0.62, 0.86, b.b + (noise2(wp.xz * 0.31) - 0.5) * 0.5 + (patch - 0.5) * 0.3) * step(0.02, b.b);
	float w_pave = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.06);
	w_pave *= 1.0 - smoothstep(0.22, 0.4, slope);

	// les grèves de sable (la mer) et le bord du lac
	float beach = (1.0 - smoothstep(0.9, 2.2, wp.y + (macro - 0.5) * 1.4)) * (1.0 - w_pave);
	vec2 lk = (wp.xz - lake.xy) / lake.zw;
	float lq = length(lk);
	float shore = (1.0 - smoothstep(1.02, 1.16 + (patch - 0.5) * 0.06, lq)) * (1.0 - smoothstep(lake_y + 0.9, lake_y + 1.6, wp.y));
	beach = max(beach, shore);
	// la roche : les pentes raides (pas dans la ville : ses murs les cachent)
	float in_town = 1.0 - smoothstep(town.z - 2.0, town.z + 4.0, length(wp.xz - town.xy));
	float rock_w = smoothstep(0.2, 0.34, slope + (patch - 0.5) * 0.1) * (1.0 - w_pave);
	float sur_volcan = 1.0 - smoothstep(volcan.z * 0.82, volcan.z, length(wp.xz - volcan.xy) + (macro - 0.5) * 14.0);
	rock_w = max(rock_w, sur_volcan * (1.0 - w_pave) * (1.0 - b.r));
	// les Crocs : la roche affleure aussi sur les sommets
	float high = smoothstep(18.0, 30.0, wp.y + (macro - 0.5) * 10.0) * (1.0 - in_town);
	rock_w = max(rock_w, high * smoothstep(0.18, 0.32, slope + (patch - 0.5) * 0.1));

	vec3 grass = mix(untiled(prairie_tex, uv * 1.1, mixer).rgb, untiled(prairie_tex, uv * 0.41 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	// la cendre : gris sombre, des plaques plus brunes
	grass *= mix(vec3(0.42, 0.41, 0.44), vec3(0.62, 0.57, 0.55), macro);
	vec3 field = vec3(0.0);
	vec3 dirt = untiled(chemin_tex, uv * 1.2 * gscale, mixer).rgb * vec3(0.5, 0.46, 0.44);
	vec3 forest = untiled(sous_bois_tex, uv * 1.15 * gscale, mixer).rgb;
	vec3 sand = untiled(sable_lac_tex, uv * 1.15 * gscale, mixer).rgb;
	vec3 pave = untiled(paves_tex, uv * 0.85 * gscale, 0.0).rgb;
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(prairie_tex, uv * 3.3).rgb, 0.2 * near);
		dirt = mix(dirt, texture(chemin_tex, uv * 3.1 * gscale).rgb, 0.18 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(roche_crocs_tex, wp, tri, 0.08 * gscale) * mix(vec3(0.5, 0.49, 0.52), vec3(0.76, 0.7, 0.68), macro);

	vec3 ground = grass;
	ground = mix(ground, forest, w_forest);
	ground = mix(ground, field, w_field);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, pave, w_pave);
	vec3 albedo = mix(ground, sand, beach);
	albedo = mix(albedo, rock, rock_w);
	// la lave : la croûte noire, ses fissures qui rougeoient (elles battent lentement)
	vec2 luv = uv * 1.3;
	vec3 croute = untiled(lave_tex, luv, mixer).rgb;
	vec3 feu = untiled(lave_e, luv, mixer).rgb * vec3(1.0, 0.42, 0.12);
	float bat = 0.75 + 0.25 * sin(TIME * 0.7 + noise2(wp.xz * 0.12) * 6.283);
	albedo = mix(albedo, croute, w_lave);
	// tout autour, la roche est roussie
	float roussi = smoothstep(0.04, 0.3, b.g) * (1.0 - w_lave);
	albedo = mix(albedo, albedo * vec3(0.62, 0.46, 0.4), roussi);

	// mouillé au bord de l'eau
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * beach;
	wet = max(wet, (1.0 - smoothstep(lake_y + 0.05, lake_y + 0.5, wp.y)) * shore);
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = untiled_normal(prairie_n, uv * 1.1, mixer);
	nm_ground = normalize(mix(nm_ground, untiled_normal(sous_bois_n, uv * 1.15 * gscale, mixer), w_forest));
		nm_ground = normalize(mix(nm_ground, untiled_normal(chemin_n, uv * 1.2 * gscale, mixer), w_dirt));
	nm_ground = normalize(mix(nm_ground, texture(paves_n, uv * 0.85 * gscale).xyz * 2.0 - 1.0, w_pave));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_lac_n, uv * 1.15 * gscale, mixer), beach));
	vec3 nm_rock = normalize(triplanar_n(roche_crocs_n, wp, tri, 0.08 * gscale));
	vec3 nm = normalize(mix(nm_ground, nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.93, 0.85, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.7, w_lave);
	EMISSION = (feu * lave_force * bat + vec3(1.0, 0.24, 0.03) * 0.25 * roussi) * max(w_lave, roussi * 0.35);
	ROUGHNESS = mix(ROUGHNESS, 0.76, w_pave);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
}

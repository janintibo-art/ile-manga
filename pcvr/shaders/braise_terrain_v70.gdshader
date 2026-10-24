// V70 : sol de l'Île de Braise (même famille que les sols V69). Une carte des sols (« biome »,
// cuite par ile_braise_v70.gd) dit où vont la cendre (R : le volcan, le Bois de Cendre, les
// chemins), la mousse sombre aux reflets cuivrés (G), la lave refroidie dont les fissures luisent
// encore (B) et les pavés de basalte de la cité et du port (A). Ailleurs, un sol mêlé de mousse et
// de cendre ; le basalte sur les pentes raides, la roche rouge du volcan en hauteur ; le sable noir
// sur les grèves ; le soufre autour des sources chaudes.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D mousse_braise_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mousse_braise_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cendre_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cendre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_noir_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_noir_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D basalte_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D basalte_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_volcan_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_volcan_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_basalte_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_basalte_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lave_croute_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lave_croute_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lave_croute_e : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soufre_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soufre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);   // x0, z0, largeur, profondeur
uniform vec4 volcano = vec4(0.0, 0.0, 24.0, 120.0);   // centre x, z, rayon du cratère, rayon d'influence
uniform vec4 springs[3];                              // x, z, rayon du soufre
uniform bool extra_detail = false;
uniform float water_level = -0.42;
uniform float glow = 1.0;                             // la lueur des fissures (plus forte la nuit)

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
	float wob = (patch - 0.5) * 0.35;
	float w_ash = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_moss = clamp(b.g + wob * 0.6, 0.0, 1.0);
	float w_lava = smoothstep(0.25, 0.7, b.b + wob * 0.3);
	float w_pave = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.08);

	// les grèves de sable noir
	float beach = (1.0 - smoothstep(0.8, 2.0, wp.y + (macro - 0.5) * 1.4)) * (1.0 - w_pave);
	// le volcan : de la cendre et de la roche rouge vers le sommet
	float vd = length(wp.xz - volcano.xy);
	float high = smoothstep(38.0, 70.0, wp.y + (macro - 0.5) * 14.0) * (1.0 - smoothstep(volcano.w * 0.7, volcano.w * 1.2, vd));
	float rock_w = smoothstep(0.52, 0.62, slope + (patch - 0.5) * 0.06) * (1.0 - w_pave);
	// le soufre autour des sources
	float sulf = 0.0;
	for (int i = 0; i < 3; i++) {
		float ds = length(wp.xz - springs[i].xy);
		sulf = max(sulf, 1.0 - smoothstep(springs[i].z * 0.45, springs[i].z, ds + (patch - 0.5) * 3.0));
	}

	vec3 moss = mix(untiled(mousse_braise_tex, uv * 1.1, mixer).rgb, untiled(mousse_braise_tex, uv * 0.43 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	moss *= mix(vec3(0.9, 0.92, 0.88), vec3(1.06, 1.0, 0.94), macro);
	vec3 ash = untiled(cendre_tex, uv * 1.2, mixer).rgb * mix(vec3(0.92), vec3(1.05), macro);
	vec3 sand = untiled(sable_noir_tex, uv * 1.15, mixer).rgb;
	vec3 pave = untiled(paves_basalte_tex, uv * 0.8, 0.0).rgb;
	vec3 crust = untiled(lave_croute_tex, uv * 0.6, mixer).rgb;
	vec3 sulfur = untiled(soufre_tex, uv * 1.4, mixer).rgb;
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		moss = mix(moss, texture(mousse_braise_tex, uv * 3.3).rgb, 0.22 * near);
		ash = mix(ash, texture(cendre_tex, uv * 3.1).rgb, 0.2 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 basalt = triplanar(basalte_tex, wp, tri, 0.09);
	vec3 vrock = triplanar(roche_volcan_tex, wp, tri, 0.07);
	vec3 rock = mix(basalt, vrock, high);

	// le sol ordinaire : de la mousse, mêlée de cendre là où la carte le dit
	vec3 ground = mix(moss, ash, clamp(w_ash + (1.0 - w_moss) * 0.45, 0.0, 1.0));
	ground = mix(ground, crust, w_lava);
	ground = mix(ground, ash * vec3(0.85, 0.82, 0.8), high * (1.0 - w_lava));
	ground = mix(ground, pave, w_pave);
	ground = mix(ground, sulfur, sulf * (1.0 - w_pave));
	vec3 albedo = mix(ground, sand, beach);
	albedo = mix(albedo, rock, max(rock_w * (1.0 - sulf), high * smoothstep(0.35, 0.5, slope)));

	// mouillé au bord de l'eau
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * beach;
	albedo *= mix(1.0, 0.6, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = normalize(mix(untiled_normal(mousse_braise_n, uv * 1.1, mixer), untiled_normal(cendre_n, uv * 1.2, mixer), clamp(w_ash + high, 0.0, 1.0)));
	nm_ground = normalize(mix(nm_ground, untiled_normal(lave_croute_n, uv * 0.6, mixer), w_lava));
	nm_ground = normalize(mix(nm_ground, texture(paves_basalte_n, uv * 0.8).xyz * 2.0 - 1.0, w_pave));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_noir_n, uv * 1.15, mixer), beach));
	nm_ground = normalize(mix(nm_ground, untiled_normal(soufre_n, uv * 1.4, mixer), sulf * (1.0 - w_pave)));
	vec3 nm_rock = normalize(mix(triplanar_n(basalte_n, wp, tri, 0.09), triplanar_n(roche_volcan_n, wp, tri, 0.07), high));
	vec3 nm = normalize(mix(nm_ground, nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.94, 0.97, w_ash), 0.78, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.74, w_pave);
	ROUGHNESS = mix(ROUGHNESS, 0.55, w_lava * 0.5);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
	// les fissures de la lave refroidie respirent encore
	float cracks = untiled(lave_croute_e, uv * 0.6, mixer).r;
	float pulse = 0.75 + 0.25 * sin(TIME * 0.7 + macro * 12.0);
	EMISSION = vec3(1.0, 0.32, 0.06) * cracks * w_lava * (1.0 - rock_w) * 2.4 * glow * pulse;
}

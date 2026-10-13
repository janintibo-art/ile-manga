// V24 : sol réaliste — relief (normal maps), anti-répétition, sable mouillé, roche sur les pentes.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
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

// Deux lectures décalées et tournées, mélangées par un bruit : la répétition disparaît.
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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wp = world_position;
	vec3 n = normalize(world_normal);
	float slope = 1.0 - clamp(n.y, 0.0, 1.0);
	float dist = length(CAMERA_POSITION_WORLD - wp);

	vec2 uv = wp.xz * 0.21;
	float mixer = smoothstep(0.25, 0.75, noise2(wp.xz * 0.045));
	float macro = noise2(wp.xz * 0.018);
	float patch = noise2(wp.xz * 0.11);

	float h = wp.y + (macro - 0.5) * 1.6 + (patch - 0.5) * 0.35;
	float grass_w = smoothstep(0.15, 1.35, h);
	float rock_w = clamp(smoothstep(0.32, 0.55, slope) + smoothstep(5.6, 7.6, h) * 0.55, 0.0, 1.0);

	vec3 sand = untiled(sand_tex, uv * 1.15, mixer).rgb * vec3(0.93, 0.88, 0.78);
	vec3 grass = untiled(grass_tex, uv, mixer).rgb;
	// Variations naturelles de la prairie : zones plus sèches, plus sombres, plus jaunes.
	grass *= mix(vec3(0.82, 0.92, 0.78), vec3(1.06, 1.02, 0.86), macro);
	grass = mix(grass, grass * vec3(1.18, 1.05, 0.62), smoothstep(0.62, 0.86, patch) * 0.45);
	if (extra_detail) {
		grass = mix(grass, texture(grass_tex, uv * 3.3).rgb * vec3(0.9, 1.0, 0.85), 0.25 * (1.0 - smoothstep(10.0, 40.0, dist)));
	}

	// Roche en projection triplanaire : pas d'étirement sur les pentes raides.
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 stone = texture(stone_tex, wp.zy * 0.16).rgb * tri.x
		+ untiled(stone_tex, wp.xz * 0.16, mixer).rgb * tri.y
		+ texture(stone_tex, wp.xy * 0.16).rgb * tri.z;
	stone *= vec3(0.86, 0.84, 0.8);

	vec3 albedo = mix(sand, grass, grass_w);
	albedo = mix(albedo, stone, rock_w);

	// Sable mouillé au bord de l'eau : plus sombre et plus brillant.
	float wet = 1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y);
	wet *= (1.0 - grass_w);
	albedo *= mix(1.0, 0.58, wet);
	// Fond marin : légèrement plus sombre sous l'eau.
	albedo *= mix(1.0, 0.75, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	// Relief fin : normal maps mélangées comme les couleurs, orientées sur le plan XZ.
	vec3 nm_sand = untiled_normal(sand_n, uv * 1.15, mixer);
	vec3 nm_grass = untiled_normal(grass_n, uv, mixer);
	vec3 nm_stone = untiled_normal(stone_n, wp.xz * 0.16, mixer);
	vec3 nm = normalize(mix(mix(nm_sand, nm_grass, grass_w), nm_stone, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.92, 0.97, grass_w), 0.82, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.32, wet);
	SPECULAR = mix(0.35, 0.5, wet);
	METALLIC = 0.0;
}

// V87 : sol de l'Île aux Moaïs (même famille que les sols V69 à V75). Une carte des sols
// (« biome », cuite par ile_moai_v87.gd) dit où vont la terre des chemins (R), la roche de basalte
// (G : les falaises, les bords des volcans), le sable blanc (B : la Plage Blanche) et l'herbe rase
// (A : le Plateau des Anciens et les ahu). Ailleurs, la prairie de l'île : une herbe verte mêlée
// d'herbe sèche dorée, en grandes vagues ; sur les pentes raides, la roche.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D herbe_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_seche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_seche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);
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
	float macro = noise2(wp.xz * 0.016);
	float patch = noise2(wp.xz * 0.08 + 13.0);

	vec4 b = texture(biome, (wp.xz - biome_rect.xy) / biome_rect.zw);
	float wob = (patch - 0.5) * 0.3;
	float w_dirt = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_rock = smoothstep(0.25, 0.7, b.g + wob * 0.4);
	float w_sand = clamp(b.b + wob * 0.5, 0.0, 1.0);
	float w_lawn = clamp(b.a, 0.0, 1.0);
	float steep = smoothstep(0.38, 0.58, slope + (patch - 0.5) * 0.1);

	// la prairie : de l'herbe verte et de l'herbe sèche dorée, en grandes vagues (le vent)
	vec3 green = untiled(herbe_tex, uv * 1.1, mixer).rgb * vec3(0.78, 0.84, 0.6);
	vec3 dry = untiled(herbe_seche_tex, uv * 1.0, mixer).rgb * vec3(1.08, 1.02, 0.86);
	float dryk = smoothstep(0.25, 0.7, macro + (patch - 0.5) * 0.25);
	vec3 grass = mix(green, dry, dryk * 0.85);
	// l'herbe rase des lieux sacrés : plus verte, plus égale
	grass = mix(grass, green * vec3(1.0, 1.04, 0.95), w_lawn * 0.6);
	vec3 rock = untiled(roche_tex, uv * 0.9, mixer).rgb;
	vec3 sand = untiled(sable_tex, uv * 1.0, mixer).rgb * vec3(1.08, 1.06, 1.0);
	vec3 dirt = untiled(terre_tex, uv * 1.2, mixer).rgb * vec3(1.45, 1.12, 0.86);
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(herbe_tex, uv * 3.3).rgb * vec3(0.78, 0.84, 0.6), 0.2 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 cliff = triplanar(roche_tex, wp, tri, 0.12);

	vec3 ground = grass;
	ground = mix(ground, rock, w_rock * 0.85);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, sand, w_sand);
	vec3 albedo = mix(ground, cliff, steep * (1.0 - w_sand * 0.8));
	// la grève au pied des falaises : les galets de basalte mouillés
	float shore = 1.0 - smoothstep(0.4, 1.6, wp.y + (macro - 0.5) * 0.8);
	albedo = mix(albedo, mix(cliff * 0.8, sand, w_sand), shore * (1.0 - w_sand));
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y));
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.7, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = normalize(mix(untiled_normal(herbe_n, uv * 1.1, mixer), untiled_normal(herbe_seche_n, uv, mixer), dryk * 0.75));
	nm_ground = normalize(mix(nm_ground, untiled_normal(roche_n, uv * 0.9, mixer), w_rock * 0.85));
	nm_ground = normalize(mix(nm_ground, untiled_normal(terre_n, uv * 1.2, mixer), w_dirt));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_n, uv, mixer), w_sand));
	vec3 nm_wall = normalize(triplanar_n(roche_n, wp, tri, 0.12));
	vec3 nm = normalize(mix(nm_ground, nm_wall, steep));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.93, 0.3, wet);
	SPECULAR = mix(0.38, 0.55, wet);
}

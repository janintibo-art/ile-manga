// V146 : sol de l'Île Perchée (Far West). La prairie dorée et sèche ; la terre rouge autour des mesas ;
// la verdure le long du ruisseau et autour de la mare ; les rues de terre battue ; la place pavée ; le
// grès rouge en strates (orange, rouille, crème) sur les falaises des mesas et sous l'île.
// La carte des sols (« biome », cuite par ile_perchee_v146.gd) : R la terre battue, G la terre rouge,
// B la verdure, A les pavés de la place.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D prairie_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D prairie_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D chemin_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D chemin_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_rouge_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_rouge_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D verdure_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D verdure_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gres_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gres_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paves_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float y0 = 270.0;
uniform float eau_y = 269.45;
uniform bool extra_detail = false;

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

// les strates du grès : des bandes de couleur selon la hauteur, un peu ondulées
vec3 strates(float y, float wob) {
	float h = y * 0.38 + wob * 1.6;
	float k = fract(h * 0.21);
	vec3 rouille = vec3(0.78, 0.36, 0.2);
	vec3 orange = vec3(1.0, 0.62, 0.36);
	vec3 creme = vec3(1.0, 0.8, 0.6);
	vec3 brun = vec3(0.6, 0.32, 0.22);
	vec3 c = mix(rouille, orange, smoothstep(0.0, 0.18, k));
	c = mix(c, creme, smoothstep(0.38, 0.46, k) * (1.0 - smoothstep(0.52, 0.6, k)));
	c = mix(c, brun, smoothstep(0.72, 0.8, k) * (1.0 - smoothstep(0.86, 0.94, k)));
	// de fines lignes entre les bancs
	c *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.06, abs(fract(h * 0.84) - 0.5) - 0.44));
	return c;
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
	float w_red = smoothstep(0.15, 0.75, b.g + wob);
	float w_vert = clamp(b.b + wob * 0.6, 0.0, 1.0);
	float w_pave = smoothstep(0.35, 0.65, b.a + (patch - 0.5) * 0.06);
	// sous l'île et sur les falaises : le grès
	float below = 1.0 - smoothstep(y0 - 6.0, y0 - 3.0, wp.y);
	float rock_w = smoothstep(0.48, 0.6, slope + (patch - 0.5) * 0.1) * (1.0 - w_pave);
	rock_w = max(rock_w, below);
	// le dessus des mesas : des dalles de grès nues, avec un peu d'herbe rase
	float haut = smoothstep(y0 + 9.0, y0 + 13.0, wp.y + (macro - 0.5) * 4.0);
	rock_w = max(rock_w, haut * smoothstep(0.12, 0.3, slope + (patch - 0.5) * 0.2));
	w_red = max(w_red, haut * 0.85);

	vec3 grass = mix(untiled(prairie_tex, uv * 1.1, mixer).rgb, untiled(prairie_tex, uv * 0.41 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	// la prairie dorée : de l'herbe sèche, quelques plaques encore vertes
	float lum = dot(grass, vec3(0.3, 0.55, 0.15));
	vec3 doree = vec3(lum * 1.75, lum * 1.42, lum * 0.62);
	grass = mix(doree, grass * vec3(0.95, 1.0, 0.8), smoothstep(0.55, 0.9, macro) * 0.55);
	grass *= mix(0.88, 1.1, patch);
	vec3 dirt = untiled(chemin_tex, uv * 1.2, mixer).rgb * vec3(1.12, 0.9, 0.74);
	vec3 red = mix(untiled(terre_rouge_tex, uv * 0.9, mixer).rgb, untiled(chemin_tex, uv * 0.8 + vec2(0.3, 0.1), mixer).rgb, 0.55) * vec3(1.08, 0.7, 0.56);
	vec3 vert = untiled(verdure_tex, uv * 1.1, mixer).rgb;
	vert = mix(vert, vec3(dot(vert, vec3(0.33))) * vec3(1.05, 1.08, 0.7), 0.35) * vec3(1.0, 0.95, 0.85);
	vec3 pave = untiled(paves_tex, uv * 0.9, 0.0).rgb * vec3(1.05, 0.95, 0.85);
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(prairie_tex, uv * 3.3).rgb * vec3(1.3, 1.1, 0.6), 0.18 * near);
		dirt = mix(dirt, texture(chemin_tex, uv * 3.1).rgb * vec3(1.12, 0.9, 0.74), 0.18 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(gres_tex, wp, tri, 0.09);
	float rl = dot(rock, vec3(0.33));
	rock = (0.2 + rl * 2.0) * strates(wp.y, noise2(wp.xz * 0.03) + noise2(vec2(wp.x + wp.z, wp.y) * 0.05));

	vec3 ground = grass;
	ground = mix(ground, red, w_red);
	ground = mix(ground, vert, w_vert);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, pave, w_pave);
	vec3 albedo = mix(ground, rock, rock_w);

	// mouillé au bord de l'eau
	float wet = (1.0 - smoothstep(eau_y + 0.05, eau_y + 0.6 + (patch - 0.5) * 0.3, wp.y)) * (1.0 - below);
	albedo *= mix(1.0, 0.6, wet);
	// le dessous s'assombrit vers la pointe
	albedo *= mix(1.0, 0.8, smoothstep(y0 - 20.0, y0 - 170.0, wp.y));

	vec3 nm_ground = untiled_normal(prairie_n, uv * 1.1, mixer);
	nm_ground = normalize(mix(nm_ground, untiled_normal(terre_rouge_n, uv * 0.9, mixer), w_red));
	nm_ground = normalize(mix(nm_ground, untiled_normal(verdure_n, uv * 1.1, mixer), w_vert));
	nm_ground = normalize(mix(nm_ground, untiled_normal(chemin_n, uv * 1.2, mixer), w_dirt));
	nm_ground = normalize(mix(nm_ground, texture(paves_n, uv * 0.9).xyz * 2.0 - 1.0, w_pave));
	vec3 nm_rock = normalize(triplanar_n(gres_n, wp, tri, 0.09));
	vec3 nm = normalize(mix(nm_ground, nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.93, 0.86, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.78, w_pave);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(mix(0.38, 0.22, rock_w), 0.55, wet) * mix(1.0, 0.35, below);
	// la lumière que la mer renvoie sous l'île (sinon le dessous serait noir)
	EMISSION = albedo * 0.22 * clamp(-n.y + 0.2, 0.0, 1.0) * below;
}

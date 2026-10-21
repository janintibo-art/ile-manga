// V59 : le sol de la grande île de l'est — quatre régions, quatre sols.
// Les poids des régions arrivent par la couleur des sommets (COLOR) :
//   r : la côte ouest (prairies rases, dunes, plages blondes) — le port de Carène ;
//   g : les hautes terres du nord (landes, herbes rousses, rochers, neige sur les crêtes) ;
//   b : la forêt des brumes à l'est (mousse épaisse, terre noire, vasières) ;
//   a : le désert du sud (dunes ocre, touffes sèches, roches rouges).
// La roche prend les pentes partout (projection triplanaire), avec sa teinte régionale.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dry_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dry_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool extra_detail = false;
uniform float water_level = -0.42;
uniform float snow_line = 44.0;

varying vec3 world_position;
varying vec3 world_normal;
varying vec4 region;

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
	region = COLOR;
}

void fragment() {
	vec3 wp = world_position;
	vec3 n = normalize(world_normal);
	float slope = 1.0 - clamp(n.y, 0.0, 1.0);
	float dist = length(CAMERA_POSITION_WORLD - wp);
	vec2 uv = wp.xz * 0.18;
	float mixer = smoothstep(0.25, 0.75, noise2(wp.xz * 0.045));
	float macro = noise2(wp.xz * 0.017);
	float patch = noise2(wp.xz * 0.08 + 13.0);
	vec4 w = region / max(region.r + region.g + region.b + region.a, 0.001);

	// textures de base
	vec3 sand = untiled(sand_tex, uv * 1.25, mixer).rgb;
	vec3 grass = untiled(grass_tex, uv * 0.9, mixer).rgb;
	vec3 dry = untiled(dry_tex, uv * 0.95, mixer).rgb;
	vec3 moss = untiled(moss_tex, uv * 0.9, mixer).rgb;
	vec3 soil = untiled(soil_tex, uv * 1.6, mixer).rgb;
	if (extra_detail) {
		float near_k = 1.0 - smoothstep(8.0, 35.0, dist);
		grass = mix(grass, texture(grass_tex, uv * 3.1).rgb, 0.25 * near_k);
		moss = mix(moss, texture(moss_tex, uv * 3.1).rgb, 0.25 * near_k);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(rock_tex, wp, tri, 0.07);

	float beach = 1.0 - smoothstep(0.9, 2.3, wp.y + (macro - 0.5) * 1.6);

	// côte ouest : prairie rase, plaques d'herbe sèche, sable blond
	vec3 g_w = mix(grass * vec3(0.95, 1.0, 0.85), dry, smoothstep(0.55, 0.8, patch) * 0.6);
	vec3 s_w = sand * vec3(1.0, 0.95, 0.84);
	vec3 r_w = rock * vec3(0.92, 0.92, 0.9);
	// hautes terres : lande (herbe rousse et bruyère), roche grise
	vec3 heath = mix(dry * vec3(0.85, 0.7, 0.62), grass * vec3(0.72, 0.74, 0.5), smoothstep(0.6, 0.85, patch) * 0.6);
	heath = mix(heath, heath * vec3(0.95, 0.72, 0.95), smoothstep(0.62, 0.8, noise2(wp.xz * 0.21)) * 0.6);
	vec3 s_n = sand * vec3(0.82, 0.8, 0.76);
	vec3 r_n = rock * vec3(0.85, 0.87, 0.9);
	// forêt des brumes : mousse épaisse et terre noire, vase sur les rives
	vec3 g_e = mix(soil * vec3(0.55, 0.52, 0.46), moss * vec3(0.5, 0.62, 0.42), smoothstep(0.3, 0.6, patch * 0.7 + macro * 0.5));
	vec3 s_e = soil * vec3(0.55, 0.5, 0.42);
	vec3 r_e = rock * vec3(0.7, 0.78, 0.68);
	// désert du sud : dunes ocre, touffes sèches éparses, roche rouge
	vec3 dune = sand * vec3(1.18, 0.88, 0.58);
	vec3 g_s = mix(dune, dry * vec3(1.05, 0.9, 0.65), smoothstep(0.66, 0.82, patch) * 0.7);
	vec3 s_s = sand * vec3(1.1, 0.92, 0.7);
	vec3 r_s = rock * vec3(1.15, 0.72, 0.5);

	vec3 ground = g_w * w.r + heath * w.g + g_e * w.b + g_s * w.a;
	vec3 shore = s_w * w.r + s_n * w.g + s_e * w.b + s_s * w.a;
	vec3 rocky = r_w * w.r + r_n * w.g + r_e * w.b + r_s * w.a;
	float rock_th = 0.52 - 0.08 * w.g + 0.1 * w.a;
	float rock_w = smoothstep(rock_th, rock_th + 0.1, slope + (patch - 0.5) * 0.08);

	vec3 albedo = mix(ground, shore, beach);
	albedo = mix(albedo, rocky, rock_w);
	// la neige des crêtes du nord (et du sommet du massif)
	float snow = smoothstep(snow_line, snow_line + 8.0, wp.y + (macro - 0.5) * 10.0) * (1.0 - smoothstep(0.55, 0.8, slope)) * smoothstep(0.25, 0.7, w.g);
	vec3 snow_c = vec3(0.93, 0.95, 0.98) * (0.9 + 0.1 * noise2(wp.xz * 1.7));
	albedo = mix(albedo, snow_c, snow);

	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * beach;
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_ground = normalize(untiled_normal(grass_n, uv * 0.9, mixer) * (w.r + w.g * 0.5) + untiled_normal(dry_n, uv * 0.95, mixer) * (w.g * 0.5 + w.a * 0.3)
		+ untiled_normal(moss_n, uv * 0.9, mixer) * w.b + untiled_normal(sand_n, uv * 1.25, mixer) * w.a * 0.7 + vec3(0.0, 0.0, 0.01));
	vec3 nm_sand = untiled_normal(sand_n, uv * 1.25, mixer);
	vec3 nm_rock = normalize(triplanar_n(rock_n, wp, tri, 0.07));
	vec3 nm = normalize(mix(mix(nm_ground, nm_sand, beach), nm_rock, rock_w));
	nm = normalize(mix(nm, vec3(0.0, 0.0, 1.0), snow * 0.7));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.9, 0.95, w.b), 0.72, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.55, snow);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
}

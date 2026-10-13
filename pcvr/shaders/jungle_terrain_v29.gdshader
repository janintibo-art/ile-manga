// V29 : sol de l'île-jungle — plage, sous-bois de feuilles mortes, mousse épaisse,
// calcaire humide sur les pentes (projection triplanaire) avec de la mousse sur les replats.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
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
	vec2 uv = wp.xz * 0.18;
	float mixer = smoothstep(0.25, 0.75, noise2(wp.xz * 0.045));
	float macro = noise2(wp.xz * 0.02);
	float patch = noise2(wp.xz * 0.09 + 13.0);

	// Plage : jusqu'à ~1,5 m au-dessus de l'eau, bord irrégulier.
	float beach = 1.0 - smoothstep(0.9, 2.1, wp.y + (macro - 0.5) * 1.4);
	// Sous-bois : feuilles mortes là où la mousse ne prend pas.
	float moss_w = smoothstep(0.35, 0.65, patch * 0.7 + macro * 0.5 - slope * 0.4);
	// Calcaire sur les pentes raides ; la mousse reprend sur les replats des rochers.
	float rock_w = smoothstep(0.52, 0.62, slope + (patch - 0.5) * 0.06);

	vec3 sand = untiled(sand_tex, uv * 1.25, mixer).rgb * vec3(0.98, 0.93, 0.82);
	vec3 soil = untiled(soil_tex, uv * 0.8, mixer).rgb;
	vec3 moss = untiled(moss_tex, uv * 0.9, mixer).rgb * mix(vec3(0.85, 0.9, 0.8), vec3(1.05, 1.0, 0.9), macro);
	if (extra_detail) {
		moss = mix(moss, texture(moss_tex, uv * 3.1).rgb, 0.25 * (1.0 - smoothstep(8.0, 35.0, dist)));
		soil = mix(soil, texture(soil_tex, uv * 2.3).rgb, 0.2 * (1.0 - smoothstep(8.0, 30.0, dist)));
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(rock_tex, wp, tri, 0.09);
	// Les parois ruissellent : plus sombres vers le bas.
	rock *= mix(0.8, 1.05, smoothstep(0.0, 30.0, wp.y));

	vec3 ground = mix(soil, moss, moss_w);
	vec3 albedo = mix(ground, sand, beach);
	albedo = mix(albedo, rock, rock_w);

	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y)) * beach;
	albedo *= mix(1.0, 0.6, wet);
	albedo *= mix(1.0, 0.72, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	vec3 nm_sand = untiled_normal(sand_n, uv * 1.25, mixer);
	vec3 nm_ground = normalize(mix(untiled_normal(soil_n, uv * 0.8, mixer), untiled_normal(moss_n, uv * 0.9, mixer), moss_w));
	vec3 nm_rock = normalize(triplanar_n(rock_n, wp, tri, 0.09));
	vec3 nm = normalize(mix(mix(nm_ground, nm_sand, beach), nm_rock, rock_w));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.9, 0.96, moss_w), 0.7, rock_w);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wet);
	SPECULAR = mix(0.4, 0.55, max(wet, rock_w * 0.5));
}

// V76 : le sol d'Astralys, l'île flottante des Lumens (même famille que les sols V69 à V75). Une
// carte des sols (« biome », cuite par ile_astrale_v76.gd) dit où vont les dalles de nacre de la
// ville (R), les dalles de cristal des places (G : un peu lumineuses), la mousse astrale des
// jardins (B : elle luit la nuit) et le sable stellaire des allées (A). Ailleurs, l'herbe
// argentée. Les pentes raides (le bord, les îlots) : la roche sombre veinée de cristaux.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D herbe_lunaire_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_lunaire_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nacre_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nacre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cristal_sol_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cristal_sol_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mousse_astrale_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mousse_astrale_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_stellaire_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_stellaire_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_astrale_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_astrale_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 center = vec2(-820.0, -760.0);
uniform float y0 = 380.0;
uniform bool extra_detail = false;
uniform float glow = 0.0;                            // la nuit : la mousse et le cristal luisent (temps_v56)

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
	vec2 uv = wp.xz * 0.25;
	float mixer = smoothstep(0.25, 0.75, noise2(wp.xz * 0.045));
	float macro = noise2(wp.xz * 0.018);
	float patch = noise2(wp.xz * 0.09 + 13.0);

	vec4 b = texture(biome, (wp.xz - biome_rect.xy) / biome_rect.zw);
	float w_nacre = smoothstep(0.35, 0.65, b.r + (patch - 0.5) * 0.05);
	float w_plaza = smoothstep(0.3, 0.7, b.g);
	float w_moss = clamp(b.b + (patch - 0.5) * 0.4 * b.b, 0.0, 1.0);
	float w_sand = smoothstep(0.3, 0.7, b.a);
	float steep = smoothstep(0.45, 0.65, slope + (patch - 0.5) * 0.08);

	vec3 grass = mix(untiled(herbe_lunaire_tex, uv * 1.0, mixer).rgb, untiled(herbe_lunaire_tex, uv * 0.41 + vec2(0.37, 0.61), 1.0 - mixer).rgb, 0.3);
	grass *= mix(vec3(0.94, 0.98, 1.04), vec3(1.04, 1.0, 1.06), macro);
	// les dalles de nacre : de grands carreaux (une dalle de 2 m)
	vec3 nacre = texture(nacre_tex, wp.xz * 0.125).rgb;
	nacre *= mix(vec3(1.0, 0.98, 1.02), vec3(0.98, 1.0, 1.04), noise2(floor(wp.xz * 0.5) * 3.1));
	vec3 plaza = texture(cristal_sol_tex, wp.xz * 0.14).rgb;
	vec3 moss = untiled(mousse_astrale_tex, uv * 1.1, mixer).rgb;
	vec3 sand = untiled(sable_stellaire_tex, uv * 1.2, mixer).rgb;
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(herbe_lunaire_tex, uv * 3.3).rgb, 0.2 * near);
	}
	// V76 : la prairie lunaire n'est pas grise : un argent bleu-vert, des plaques lilas
	float lum = dot(grass, vec3(0.333));
	vec3 tint = mix(vec3(0.46, 0.86, 0.74), vec3(0.78, 0.6, 0.98), smoothstep(0.3, 0.75, macro));
	grass = mix(grass, lum * tint * 1.25, 0.72);
	sand *= vec3(1.06, 0.98, 0.86);
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 rock = triplanar(roche_astrale_tex, wp, tri, 0.09);

	vec3 ground = grass;
	ground = mix(ground, moss, w_moss);
	ground = mix(ground, nacre, w_nacre);
	ground = mix(ground, sand, w_sand);
	ground = mix(ground, plaza, w_plaza);
	vec3 albedo = mix(ground, rock, steep);

	vec3 nm_ground = untiled_normal(herbe_lunaire_n, uv * 1.0, mixer);
	nm_ground = normalize(mix(nm_ground, untiled_normal(mousse_astrale_n, uv * 1.1, mixer), w_moss));
	nm_ground = normalize(mix(nm_ground, texture(nacre_n, wp.xz * 0.125).xyz * 2.0 - 1.0, w_nacre));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_stellaire_n, uv * 1.2, mixer), w_sand));
	nm_ground = normalize(mix(nm_ground, texture(cristal_sol_n, wp.xz * 0.14).xyz * 2.0 - 1.0, w_plaza));
	vec3 nm = normalize(mix(nm_ground, normalize(triplanar_n(roche_astrale_n, wp, tri, 0.09)), steep));
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist));
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	ALBEDO = albedo;
	ROUGHNESS = mix(0.9, 0.3, w_nacre * (1.0 - steep));
	ROUGHNESS = mix(ROUGHNESS, 0.12, w_plaza * (1.0 - steep));
	SPECULAR = mix(0.4, 0.7, max(w_nacre, w_plaza));
	CLEARCOAT = w_nacre * 0.4;
	// la nuit : la mousse luit en taches, les dalles de cristal laissent passer une lueur bleue,
	// les veines de la roche brillent
	vec3 e = moss * vec3(0.4, 0.7, 1.0) * w_moss * smoothstep(0.35, 0.75, patch) * 0.7;
	e += plaza * vec3(0.3, 0.55, 1.0) * w_plaza * 0.35;
	e += rock * vec3(0.5, 0.4, 1.0) * steep * smoothstep(0.55, 0.75, max(rock.b - rock.r, 0.0) * 4.0) * 0.6;
	EMISSION = e * glow;
}

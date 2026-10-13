// V26 : roche réaliste — texture et relief projetés sur trois axes (aucun étirement),
// mousse sur les faces tournées vers le ciel, roche mouillée et brillante près des cascades.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D stone_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(0.72, 0.7, 0.66);
uniform float moss_amount : hint_range(0.0, 1.0) = 0.45;
uniform float texture_scale = 0.12;
uniform vec4 wet_zone = vec4(0.0, -1000.0, 0.0, 0.0); // xyz = centre, w = rayon

varying vec3 wpos;
varying vec3 wnormal;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = normalize(wnormal);
	vec3 w = pow(abs(n), vec3(5.0));
	w /= (w.x + w.y + w.z);
	vec2 uv_x = wpos.zy * texture_scale;
	vec2 uv_y = wpos.xz * texture_scale;
	vec2 uv_z = wpos.xy * texture_scale;
	vec3 stone = texture(stone_tex, uv_x).rgb * w.x + texture(stone_tex, uv_y).rgb * w.y + texture(stone_tex, uv_z).rgb * w.z;
	// Couleur de roche légèrement désaturée, teintée par matériau et par instance.
	float luma = dot(stone, vec3(0.299, 0.587, 0.114));
	stone = mix(vec3(luma), stone, 0.85) * 1.2 * tint * COLOR.rgb;
	stone *= mix(0.82, 1.12, noise2(wpos.xz * 0.35 + wpos.y * 0.2));

	// Relief triplanaire : chaque projection perturbe la normale sur son plan.
	vec3 nx = texture(stone_n, uv_x).xyz * 2.0 - 1.0;
	vec3 ny = texture(stone_n, uv_y).xyz * 2.0 - 1.0;
	vec3 nz = texture(stone_n, uv_z).xyz * 2.0 - 1.0;
	vec3 bumped = normalize(n + vec3(0.0, nx.y, nx.x) * w.x * 0.9 + vec3(ny.x, 0.0, ny.y) * w.y * 0.9 + vec3(nz.x, nz.y, 0.0) * w.z * 0.9);

	// Mousse sur les dessus, avec des bords irréguliers.
	float up = smoothstep(0.45, 0.85, n.y + (noise2(wpos.xz * 0.6) - 0.5) * 0.5);
	float moss = up * moss_amount;
	vec3 moss_col = texture(moss_tex, uv_y * 1.6).rgb * vec3(0.75, 0.9, 0.62);
	vec3 albedo = mix(stone, moss_col, moss);

	// Roche mouillée près de la chute : plus sombre et plus brillante.
	float wet = 0.0;
	if (wet_zone.w > 0.0) {
		wet = 1.0 - smoothstep(wet_zone.w * 0.4, wet_zone.w, distance(wpos, wet_zone.xyz));
	}
	albedo *= mix(1.0, 0.62, wet);

	ALBEDO = albedo;
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped, 0.0)).xyz);
	ROUGHNESS = mix(mix(0.86, 0.95, moss), 0.25, wet);
	SPECULAR = mix(0.35, 0.6, wet);
}

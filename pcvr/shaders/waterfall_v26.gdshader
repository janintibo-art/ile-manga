// V26 : chute d'eau — filets d'eau qui descendent, écume blanche en bas, bords transparents.
// UV.x : travers de la chute (0 à 1), UV.y : de la lèvre (0) au bassin (1).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_opaque;

uniform float fall_length = 10.0;
uniform float flow_speed = 1.8;
uniform vec3 water_color : source_color = vec3(0.5, 0.72, 0.76);

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float streaks(vec2 uv) {
	// Bruit très étiré dans le sens de la chute, qui défile vers le bas.
	float v = noise2(vec2(uv.x * 14.0, uv.y * 0.9 - TIME * flow_speed * 0.55));
	v += 0.5 * noise2(vec2(uv.x * 31.0, uv.y * 2.1 - TIME * flow_speed * 0.9));
	v += 0.25 * noise2(vec2(uv.x * 63.0, uv.y * 4.3 - TIME * flow_speed * 1.4));
	return v / 1.75;
}

void vertex() {
	// Légère ondulation de la nappe d'eau.
	VERTEX += NORMAL * sin(UV.y * fall_length * 1.7 - TIME * 6.0 + UV.x * 9.0) * 0.04 * UV.y;
}

void fragment() {
	vec2 uv = vec2(UV.x, UV.y * fall_length * 0.5);
	float s = streaks(uv);
	float churn = smoothstep(0.7, 1.0, UV.y);
	float white = clamp(smoothstep(0.3, 0.7, s) * (0.55 + 0.45 * UV.y) + churn * 0.85, 0.0, 1.0);
	vec3 col = mix(water_color, vec3(0.95, 0.97, 0.98), white);
	float edges = smoothstep(0.0, 0.14, UV.x) * (1.0 - smoothstep(0.86, 1.0, UV.x));
	float lip = smoothstep(0.0, 0.04, UV.y);
	ALBEDO = col;
	ALPHA = clamp((0.62 + 0.4 * s + white * 0.4) * edges * lip, 0.0, 0.97);
	ROUGHNESS = mix(0.08, 0.5, white);
	SPECULAR = 0.6;
	EMISSION = col * 0.06;
	BACKLIGHT = col * 0.5;
}

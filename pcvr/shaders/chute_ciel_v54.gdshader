// V54 : les chutes de l'île flottante — 150 m de chute libre jusqu'à l'océan.
// En haut, une nappe d'eau lisse et vitreuse ; plus bas, elle s'effiloche en filets et en
// voiles, puis se change en brume (une si haute chute n'arrive jamais entière en bas).
// UV.x : travers de la chute (0 à 1), UV.y : de la lèvre (0) à la mer (1).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_never;

uniform float fall_length = 150.0;
uniform float flow_speed = 2.6;
uniform vec3 water_color : source_color = vec3(0.55, 0.74, 0.8);

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
	// Le vent fait onduler le bas du rideau d'eau.
	float sway = sin(TIME * 0.7 + UV.y * 6.0) * 1.6 + sin(TIME * 1.3 + UV.y * 11.0 + UV.x * 3.0) * 0.6;
	VERTEX += NORMAL * sway * UV.y * UV.y;
}

void fragment() {
	float t = UV.y;
	float speed = flow_speed * (1.0 + t * 1.8);
	vec2 uv = vec2(UV.x, t * fall_length * 0.12);
	float s = noise2(vec2(uv.x * 11.0, uv.y * 0.8 - TIME * speed * 0.5));
	s += 0.5 * noise2(vec2(uv.x * 27.0, uv.y * 1.9 - TIME * speed * 0.85));
	s += 0.25 * noise2(vec2(uv.x * 55.0, uv.y * 4.0 - TIME * speed * 1.3));
	s /= 1.75;
	// Filets : le rideau se déchire en mèches à mesure qu'il tombe
	float strands = smoothstep(0.35 + 0.25 * t, 0.75, s + 0.25 * (1.0 - t));
	float mist = smoothstep(0.35, 1.0, t);
	float white = clamp(smoothstep(0.3, 0.7, s) * (0.45 + 0.55 * t) + mist * 0.7, 0.0, 1.0);
	vec3 col = mix(water_color, vec3(0.94, 0.96, 0.98), white);
	float edges = smoothstep(0.0, 0.18 + 0.12 * t, UV.x) * (1.0 - smoothstep(0.82 - 0.12 * t, 1.0, UV.x));
	float lip = smoothstep(0.0, 0.01, t);
	float body = mix(0.9, strands * 0.75, smoothstep(0.08, 0.5, t));
	float fade = 1.0 - smoothstep(0.7, 1.0, t);
	ALBEDO = col;
	ALPHA = clamp(body * edges * lip * fade * (0.75 + 0.25 * s), 0.0, 0.95);
	ROUGHNESS = mix(0.06, 0.6, white);
	SPECULAR = 0.6;
	EMISSION = col * 0.08;
	BACKLIGHT = col * 0.6;
}

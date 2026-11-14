// V142 : le linge des géants qui sèche sur la corde (draps, chemises, robe, chaussettes) : il gonfle
// et ondule au vent, plus fort en bas qu'en haut (là où les pinces le tiennent). Des rayures, parfois.
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform vec3 couleur : source_color = vec3(0.95, 0.94, 0.9);
uniform float rayures = 0.0;
uniform float vent = 1.0;

void vertex() {
	float v = UV.y;
	vec3 o = MODEL_MATRIX[3].xyz;
	float ph = dot(o.xz, vec2(0.13, 0.21));
	float gust = 0.6 + 0.4 * sin(TIME * 0.37 + ph);
	float wave = sin(TIME * 1.7 + UV.x * 3.1 + v * 2.3 + ph) * 0.6 + sin(TIME * 2.9 + UV.x * 5.7 + ph * 1.7) * 0.25;
	VERTEX += NORMAL * (v * v) * (1.6 * gust + wave * 0.9) * vent;
	VERTEX.y += v * v * 0.35 * gust * vent;
}

void fragment() {
	vec3 c = couleur;
	if (rayures > 0.5) {
		float s = step(0.5, fract(UV.x * 7.0));
		c = mix(c, vec3(0.25, 0.42, 0.72), s);
	}
	// un peu de grain de tissu et l'ombre des plis
	float grain = fract(sin(dot(floor(UV * 220.0), vec2(12.9898, 78.233))) * 43758.5453);
	c *= 0.94 + 0.06 * grain;
	c *= 0.86 + 0.14 * sin(UV.x * 18.0 + UV.y * 3.0);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	BACKLIGHT = c * 0.45;
}

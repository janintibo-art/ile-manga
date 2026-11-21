// Extension « Le Château d'Ombrelac » : le lambris peint de la Grande Salle. Des planches (le long
// de la pente), peintes d'un bleu de nuit semé d'étoiles d'or à huit branches ; des couvre-joints
// de chêne. Repère : le monde (la salle est dans l'axe des x).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 bleu : source_color = vec3(0.1, 0.16, 0.42);
uniform vec3 or_c : source_color = vec3(0.86, 0.64, 0.26);
uniform vec3 chene : source_color = vec3(0.42, 0.27, 0.16);

varying vec3 wp;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// les planches : 0,32 m de large le long de x ; un couvre-joint tous les 2,6 m (les travées)
	float px = wp.x / 0.32;
	float joint = smoothstep(0.04, 0.0, abs(fract(px) - 0.5) - 0.46);
	float couvre = 1.0 - smoothstep(0.06, 0.09, (0.5 - abs(fract(wp.x / 2.6) - 0.5)) * 2.6);
	// les étoiles, sur une grille décalée (le long de la pente : y)
	vec2 g = vec2(wp.x / 1.3, wp.y / 1.1);
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	f.x += (mod(cell.y, 2.0) - 0.5) * 0.5;
	f = f - round(f);
	float r = length(f * vec2(1.3, 1.1));
	float a = atan(f.y, f.x);
	float s = h(cell) * 0.35 + 0.65;
	float etoile = step(r, 0.17 * s * (0.35 + 0.65 * pow(abs(cos(a * 4.0)), 6.0)));
	float usure = 0.85 + 0.15 * h(floor(vec2(px, wp.y * 2.0)));
	vec3 c = mix(bleu * usure, or_c, etoile);
	c = mix(c, bleu * 0.45, joint);
	c = mix(c, chene, couvre);
	ALBEDO = c;
	METALLIC = etoile * 0.7;
	ROUGHNESS = mix(0.85, 0.35, etoile);
	// l'or des étoiles accroche la lueur des bougies
	EMISSION = or_c * etoile * 0.18;
}

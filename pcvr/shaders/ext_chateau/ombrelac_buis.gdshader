// Extension « Le Château d'Ombrelac » : les haies de buis taillées du jardin du cloître (v10). Une
// masse de petites feuilles, peinte dans l'espace du monde : des feuilles plus claires au soleil, des
// trous sombres entre les rameaux, quelques pousses jeunes vert tendre qui dépassent de la taille.
shader_type spatial;
render_mode cull_back, diffuse_burley;

varying vec3 wp;
varying vec3 wn;

float h3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float n3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// la masse des feuilles : des cellules (les feuilles), des creux
float feuilles(vec3 p) {
	return n3(p * 22.0) * 0.45 + n3(p * 7.0) * 0.35 + n3(p * 2.0) * 0.2;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(8.0, 40.0, dist);
	float f = feuilles(wp);
	float creux = smoothstep(0.55, 0.25, f);
	vec3 col = mix(vec3(0.07, 0.13, 0.035), vec3(0.17, 0.28, 0.07), smoothstep(0.25, 0.8, mix(0.5, f, 0.4 + 0.6 * fin)));
	col = mix(col, vec3(0.32, 0.42, 0.12), smoothstep(0.8, 0.92, n3(wp * 24.0 + 4.0)) * 0.5 * fin);
	// les jeunes pousses, plus claires, sur le dessus
	col = mix(col, vec3(0.38, 0.5, 0.14), smoothstep(0.72, 0.85, n3(wp * 6.0 + 2.0)) * smoothstep(0.3, 0.9, n.y) * 0.5);
	col *= 0.85 + 0.3 * n3(wp * 0.7);
	ALBEDO = col;
	ROUGHNESS = 0.75;
	SPECULAR = 0.35;
	float e = 0.01;
	float f0 = feuilles(wp);
	vec3 g = vec3(feuilles(wp + vec3(e, 0, 0)) - f0, feuilles(wp + vec3(0, e, 0)) - f0, feuilles(wp + vec3(0, 0, e)) - f0) / e;
	g -= dot(g, n) * n;
	vec3 nb = normalize(n - g * 0.035 * (0.3 + 0.7 * fin));
	NORMAL = normalize((VIEW_MATRIX * vec4(nb, 0.0)).xyz);
	AO = 1.0 - 0.45 * creux * (0.3 + 0.7 * fin);
	AO_LIGHT_AFFECT = 0.5;
	BACKLIGHT = vec3(0.08, 0.12, 0.02);
}

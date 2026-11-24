// Extension « Le Château d'Ombrelac » : les étoffes (v11) : le velours des rideaux, des édredons, des
// fauteuils ; le drap des lits. Dans l'espace du monde : la trame fine (de près), de grands plis doux
// (plus sombres au creux), le reflet rasant du velours (plus clair au bord, quand on le voit de
// biais), l'usure plus claire par endroits, un peu de poussière.
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform vec3 teinte = vec3(0.1, 0.14, 0.36);
uniform float velours = 1.0;           // 1 : le velours (le reflet rasant) ; 0 : le drap, la toile
uniform float rugosite = 0.85;

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

float plis(vec3 p) {
	return n3(p * vec3(3.0, 0.8, 3.0)) * 0.65 + n3(p * vec3(7.0, 1.6, 7.0)) * 0.35;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	if (!FRONT_FACING) {
		n = -n;
	}
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(0.6, 3.0, dist);
	// la trame : deux fils croisés, très fins (s'efface au loin)
	vec3 w = abs(n);
	vec2 q = w.y > max(w.x, w.z) ? wp.xz : (w.x > w.z ? wp.zy : wp.xy);
	float trame = (sin(q.x * 420.0) * sin(q.y * 420.0)) * 0.5 + 0.5;
	float pl = plis(wp);
	vec3 col = teinte * (0.78 + 0.4 * pl);
	col *= 1.0 + (trame - 0.5) * 0.12 * fin * (1.0 - velours * 0.5);
	// l'usure, la poussière
	col = mix(col, col * 1.25 + vec3(0.02), smoothstep(0.7, 0.9, n3(wp * 4.0 + 5.0)) * 0.35);
	col *= 0.92 + 0.16 * n3(wp * 23.0);
	ALBEDO = col;
	ROUGHNESS = rugosite;
	SPECULAR = mix(0.35, 0.2, velours);
	// le reflet rasant du velours
	RIM = velours * 0.6;
	RIM_TINT = 0.7;
	// les plis : la normale suit la pente des plis
	float e = 0.02;
	float p0 = plis(wp);
	vec3 g = vec3(plis(wp + vec3(e, 0, 0)) - p0, plis(wp + vec3(0, e, 0)) - p0, plis(wp + vec3(0, 0, e)) - p0) / e;
	g -= dot(g, n) * n;
	vec3 nb = normalize(n - g * 0.04);
	NORMAL = normalize((VIEW_MATRIX * vec4(nb, 0.0)).xyz);
	AO = 0.75 + 0.25 * pl;
	AO_LIGHT_AFFECT = 0.3;
}

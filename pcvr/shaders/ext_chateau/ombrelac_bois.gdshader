// Extension « Le Château d'Ombrelac » : le bois (v11), dessiné dans l'espace du monde, le fil dans le
// sens de la pièce. Le kit donne l'axe de chaque pièce (sa plus grande longueur) dans COLOR (rgb :
// l'axe, a = 1) ; sans axe (a = 0), le fil suit x. Les cernes (le bois de printemps clair, le bois
// d'été sombre) ondulent autour du cœur ; les pores en fines stries le long du fil ; chaque planche
// sa nuance ; les nœuds, rares ; le vernis (des reflets) sur le chêne ciré.
// « planches » = 1 : un plancher (des lames de 16 cm, leurs joints, les bouts décalés).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 teinte = vec3(0.55, 0.38, 0.24);
uniform vec3 teinte_ete = vec3(0.32, 0.2, 0.11);
uniform float rugosite = 0.6;
uniform float vernis = 0.0;
uniform float planches = 0.0;
uniform float largeur_lame = 0.16;

varying vec3 wp;
varying vec3 wn;
varying vec4 axe;

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

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 d = (MODEL_MATRIX * vec4(COLOR.rgb * 2.0 - 1.0, 0.0)).xyz;
	axe = vec4(normalize(d + vec3(1e-5)) * 0.5 + 0.5, COLOR.a);
}

// le motif du bois en q (a : le long du fil ; uv : en travers) : (le cerne d'été 0..1, les pores, la planche)
vec3 motif(float a, vec2 uv, float fin) {
	// le cœur de la grume : une ligne parallèle au fil, une tous les 0,6 m
	vec2 cell = floor(uv / 0.6);
	vec2 coeur = (cell + 0.5 + (vec2(h3(vec3(cell, 1.0)), h3(vec3(cell, 2.0))) - 0.5) * 0.8) * 0.6;
	vec2 d = uv - coeur;
	// les cernes ondulent le long du fil
	float r = length(d) + (n3(vec3(a * 0.7, uv * 3.0)) - 0.5) * 0.035 + (n3(vec3(a * 0.15, uv * 0.8)) - 0.5) * 0.06;
	float cerne = fract(r * 55.0);
	float ete = smoothstep(0.55, 0.8, cerne) * (1.0 - smoothstep(0.92, 1.0, cerne));
	// au loin, les cernes trop serrés pour l'écran se fondent dans leur teinte moyenne (pas de moiré)
	float fw = fwidth(r * 55.0);
	ete = mix(0.22, ete, 1.0 - smoothstep(0.25, 0.7, fw));
	float pores = n3(vec3(a * 2.0, uv * 160.0)) * fin;
	float planche = h3(vec3(cell, 7.0));
	return vec3(ete, pores, planche);
}

void fragment() {
	vec3 ax = axe.a > 0.5 ? normalize(axe.rgb * 2.0 - 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 t1 = normalize(cross(ax, abs(ax.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 t2 = cross(ax, t1);
	float a = dot(wp, ax);
	vec2 uv = vec2(dot(wp, t1), dot(wp, t2));
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(3.0, 20.0, dist);
	float joint = 0.0;
	float lame_id = 0.0;
	if (planches > 0.5) {
		// le plancher : les lames dans le sens de l'axe, les joints, les bouts décalés
		vec3 n = normalize(wn);
		vec3 tr = normalize(cross(n, ax));
		float w = dot(wp, tr) / largeur_lame;
		float li = floor(w);
		float lf = fract(w);
		float bout = (a + h3(vec3(li, 3.0, 1.0)) * 3.0) / 2.4;
		float bi = floor(bout);
		lame_id = h3(vec3(li, bi, 5.0));
		joint = max(1.0 - smoothstep(0.0, 0.035, min(lf, 1.0 - lf)), 1.0 - smoothstep(0.0, 0.006, min(fract(bout), 1.0 - fract(bout)) * 2.4));
		uv += vec2(li * 0.37, bi * 0.53);
	}
	vec3 m = motif(a, uv, fin);
	vec3 col = mix(teinte, teinte_ete, m.x * mix(0.45, 0.8, fin));
	col *= 0.9 + 0.2 * mix(m.z, lame_id, planches);
	col *= 1.0 - 0.18 * smoothstep(0.55, 0.9, m.y);
	// les nœuds : rares, sombres, entourés de cernes serrés
	vec2 kn = floor(vec2(a / 0.9, dot(uv, vec2(1.0)) / 0.25));
	if (h3(vec3(kn, 11.0)) > 0.93) {
		vec2 kc = vec2((kn.x + 0.5) * 0.9, (kn.y + 0.5) * 0.25);
		float dk = length(vec2((a - kc.x) * 0.5, dot(uv, vec2(1.0)) - kc.y));
		col = mix(col, teinte_ete * 0.6, (1.0 - smoothstep(0.012, 0.025, dk)) * 0.9);
	}
	// la patine : plus sombre là où l'on touche peu (les grandes nuances)
	col *= 0.88 + 0.24 * n3(wp * 0.9);
	col = mix(col, col * 0.35, joint);
	ALBEDO = col;
	ROUGHNESS = clamp(mix(rugosite, 0.28, vernis) + 0.12 * m.x - 0.05 * m.y + 0.3 * joint, 0.05, 1.0);
	SPECULAR = mix(0.4, 0.55, vernis);
	// un léger relief : les cernes d'été un peu en creux (le bois brut), les joints du plancher
	float e = 0.002;
	float h0 = motif(a, uv, fin).x;
	float hx = motif(a, uv + vec2(e, 0.0), fin).x;
	float hy = motif(a, uv + vec2(0.0, e), fin).x;
	vec3 n = normalize(wn);
	vec3 g = (t1 * (hx - h0) + t2 * (hy - h0)) / e;
	g -= dot(g, n) * n;
	vec3 nb = normalize(n - g * 0.0015 * (1.0 - vernis * 0.6) * fin);
	NORMAL = normalize((VIEW_MATRIX * vec4(nb, 0.0)).xyz);
	AO = 1.0 - 0.5 * joint;
}

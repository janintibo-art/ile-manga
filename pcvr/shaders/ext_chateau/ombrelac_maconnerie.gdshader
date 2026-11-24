// Extension « Le Château d'Ombrelac » : la maçonnerie (v13), dessinée dans l'espace du monde (rien
// d'étiré, aucune répétition visible). Des assises de hauteurs inégales, des pierres de longueurs
// inégales, chaque pierre sa nuance et son grain, les arêtes émoussées, quelques épaufrures ; les
// joints de mortier en creux ; dehors, le lichen, la mousse dans les joints du bas, les coulures
// sombres ; dedans, la patine (un peu de suie en haut des murs).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 teinte = vec3(0.62, 0.57, 0.5);
uniform vec3 mortier = vec3(0.55, 0.52, 0.47);
uniform float assise = 0.42;          // la hauteur moyenne d'une assise
uniform float longueur = 0.85;        // la longueur moyenne d'une pierre
uniform float joint = 0.016;          // la largeur d'un joint
uniform float dehors = 1.0;           // 1 : dehors (lichen, mousse, coulures) ; 0 : dedans (suie)
uniform float mousse = 0.6;
uniform float variete = 1.0;          // l'écart des nuances d'une pierre à l'autre

varying vec3 wp;
varying vec3 wn;

float h1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

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

float fbm(vec3 p) {
	return n3(p) * 0.5 + n3(p * 2.03) * 0.3 + n3(p * 4.1) * 0.2;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// L'appareil en q (u le long du mur, v vers le haut) : (la distance au joint en m, l'id de la pierre,
// la hauteur dans la pierre 0..1)
vec3 appareil(vec2 q) {
	// les assises : des hauteurs inégales (par paquets de 4 assises, une hauteur chacune)
	float paquet = floor(q.y / (assise * 4.0));
	float y0 = paquet * assise * 4.0;
	float acc = 0.0;
	float rang = 0.0;
	float ha = assise;
	float yb = y0;
	for (int i = 0; i < 4; i++) {
		float hi = assise * (0.6 + 0.85 * h1(paquet * 4.0 + float(i) + 0.37));
		if (q.y >= y0 + acc) {
			rang = paquet * 4.0 + float(i);
			yb = y0 + acc;
			ha = hi;
		}
		acc += hi;
	}
	// (les hauteurs d'un paquet ne font pas tout à fait 4 assises : la dernière comble)
	float yt = (rang - paquet * 4.0 > 2.5) ? y0 + assise * 4.0 : yb + ha;
	ha = max(yt - yb, assise * 0.3);
	// les pierres de l'assise : décalées d'une assise à l'autre, de longueurs inégales
	float u = q.x + h1(rang * 1.7) * 3.1;
	float c = floor(u / longueur);
	float f = u / longueur - c;
	float coupe = 0.3 + 0.4 * h2(vec2(c, rang));
	bool deux = h2(vec2(c + 0.5, rang + 0.3)) > 0.45;
	float id;
	float g;
	if (deux) {
		id = f < coupe ? c * 2.0 : c * 2.0 + 1.0;
		g = f < coupe ? min(f, coupe - f) : min(f - coupe, 1.0 - f);
	} else {
		id = c * 2.0;
		g = min(f, 1.0 - f);
	}
	float dx = g * longueur;
	float dy = min(q.y - yb, yt - q.y);
	return vec3(min(dx, dy), h2(vec2(id, rang * 3.1)), (q.y - yb) / ha);
}

void fragment() {
	vec3 n = normalize(wn);
	vec2 q;
	vec3 tu;
	if (abs(n.y) > 0.7) {
		q = wp.xz;
		tu = vec3(1.0, 0.0, 0.0);
	} else {
		tu = normalize(cross(vec3(0.0, 1.0, 0.0), n));
		q = vec2(dot(wp, tu), wp.y);
	}
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(6.0, 40.0, dist);
	vec3 a = appareil(q);
	float d = a.x;
	float id = a.y;
	// l'arête émoussée, rongée par endroits (les épaufrures)
	float ronge = (fbm(wp * 9.0 + id * 7.0) - 0.5) * 0.018 * (0.4 + 0.6 * h1(id * 9.1));
	float dj = d + ronge;
	float aa = max(fwidth(d) * 1.5, 0.002);
	float j = 1.0 - smoothstep(joint * 0.5 - aa, joint * 0.5 + aa, dj);
	float arete = 1.0 - smoothstep(joint * 0.5, joint * 0.5 + 0.05, dj);
	// la pierre : sa nuance, son grain, ses taches
	vec3 pierre = teinte * (1.0 + (id - 0.5) * 0.22 * variete);
	pierre = mix(pierre, pierre * vec3(1.05, 0.98, 0.9), h1(id * 3.3) * 0.6 * variete);
	pierre = mix(pierre, pierre * vec3(0.93, 0.97, 1.04), h1(id * 5.7) * 0.4 * variete);
	float grain = fbm(wp * 3.0 + id * 11.0);
	pierre *= 0.84 + 0.3 * grain;
	// les marbrures de la pierre (des veines plus claires, des taches plus sombres, propres à chaque bloc)
	float marb = fbm(wp * vec3(1.4, 2.6, 1.4) + id * 17.0);
	pierre *= 0.8 + 0.4 * marb;
	pierre = mix(pierre, pierre * vec3(1.08, 1.04, 0.95), smoothstep(0.6, 0.75, fbm(wp * 5.0 + id * 3.0)) * 0.5);
	// la crasse le long des joints (le bord des pierres plus sombre que le milieu)
	pierre *= 1.0 - 0.16 * (1.0 - smoothstep(0.0, 0.14, dj)) * (0.5 + fbm(wp * 6.0));
	pierre *= 0.94 + 0.12 * n3(wp * 40.0) * fin;
	pierre *= 1.0 - 0.12 * arete;
	// le mortier, un peu sableux
	vec3 mo = mortier * (0.85 + 0.3 * n3(wp * 60.0));
	vec3 col = mix(pierre, mo * 0.78, j);
	float ao = 1.0 - 0.35 * j - 0.12 * arete;
	if (dehors > 0.5) {
		// le lichen : des taches pâles et ocre ; la mousse dans les joints du bas des pierres ; les coulures
		float li = smoothstep(0.7, 0.82, fbm(wp * 1.6 + 3.0)) * smoothstep(0.4, 0.8, n3(wp * 13.0));
		col = mix(col, vec3(0.72, 0.7, 0.55), li * 0.35 * mousse);
		col = mix(col, vec3(0.6, 0.48, 0.2), smoothstep(0.85, 0.92, fbm(wp * 2.3 + 9.0)) * 0.4 * mousse);
		float mo2 = j * smoothstep(0.5, 0.75, fbm(wp * 4.0)) * (1.0 - smoothstep(0.0, 0.5, a.z));
		col = mix(col, vec3(0.16, 0.22, 0.08), mo2 * mousse * (0.3 + 0.7 * max(n.y, 0.0) + 0.5));
		float coul = smoothstep(0.62, 0.8, n3(vec3(q.x * 2.2, wp.y * 0.12, wn.x * 3.0 + wn.z * 5.0)));
		col *= 1.0 - coul * 0.22 * (1.0 - abs(n.y));
		// les grandes nuances de l'usure (vues de loin : la pierre n'est jamais d'un seul ton)
		col *= 0.78 + 0.34 * fbm(wp * vec3(0.06, 0.03, 0.06) + 5.0);
		col = mix(col, col * vec3(1.06, 1.0, 0.9), smoothstep(0.55, 0.8, fbm(wp * 0.11 + 13.0)) * 0.6);
	} else {
		// la patine du dedans : la suie, plus haut ; les pierres frottées, plus claires à hauteur de main
		col *= 1.0 - smoothstep(4.0, 12.0, fract(wp.y / 40.0) * 40.0) * 0.12 * fbm(wp * 0.7);
	}
	ALBEDO = col;
	ROUGHNESS = clamp(0.82 + 0.12 * j - 0.1 * grain, 0.0, 1.0);
	SPECULAR = 0.35;
	// le relief : les joints en creux, l'arête arrondie, le grain de la taille
	float e = 0.004;
	float b0 = smoothstep(0.0, joint * 0.5 + 0.03, dj) + (grain - 0.5) * 0.08;
	vec3 aux = appareil(q + vec2(e, 0.0));
	vec3 auy = appareil(q + vec2(0.0, e));
	float bx = smoothstep(0.0, joint * 0.5 + 0.03, aux.x + ronge) + (grain - 0.5) * 0.08;
	float by = smoothstep(0.0, joint * 0.5 + 0.03, auy.x + ronge) + (grain - 0.5) * 0.08;
	vec3 tv = abs(n.y) > 0.7 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
	vec3 g = (tu * (bx - b0) + tv * (by - b0)) / e;
	float s = 0.02 * (0.35 + 0.65 * fin);
	vec3 nb = normalize(n - g * s);
	// le grain de surface (les coups de la taille)
	float gs = 0.02;
	float g0 = fbm(wp * 18.0 + id);
	vec3 gg = vec3(fbm((wp + vec3(gs, 0, 0)) * 18.0 + id) - g0, fbm((wp + vec3(0, gs, 0)) * 18.0 + id) - g0, fbm((wp + vec3(0, 0, gs)) * 18.0 + id) - g0) / gs;
	gg -= dot(gg, n) * n;
	nb = normalize(nb - gg * 0.009 * fin);
	NORMAL = normalize((VIEW_MATRIX * vec4(nb, 0.0)).xyz);
	AO = ao;
	AO_LIGHT_AFFECT = 0.25;
}

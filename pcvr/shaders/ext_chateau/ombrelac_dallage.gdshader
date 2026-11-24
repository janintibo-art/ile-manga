// Extension « Le Château d'Ombrelac » : le dallage (v10), dessiné dans l'espace du monde. Des rangs
// de dalles de longueurs inégales ; chaque dalle a sa pierre (grise, beige, bleutée, ocre), son
// usure (les arêtes arrondies, un peu de jeu : elle penche à peine), son grain ; les joints sombres ;
// dehors, la mousse et l'herbe dans les joints, les lichens, les flaques séchées, la saleté le long
// des joints ; dedans (dehors = 0), la pierre polie par les pas.
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform float dehors = 1.0;
uniform float rang = 0.85;              // la largeur d'un rang de dalles (m)
uniform float longueur = 1.15;          // la longueur moyenne d'une dalle (m)
uniform vec3 teinte = vec3(1.08, 0.99, 0.86);   // une pierre blonde : à l'ombre, le ciel bleuit le sol
uniform float poli = 0.0;               // 1 : la pierre polie (les reflets)

varying vec3 wp;
varying vec3 wn;

float h2(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), f.x), mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm2(vec2 p) {
	return n2(p) * 0.5 + n2(p * 2.1 + 3.7) * 0.25 + n2(p * 4.3 + 7.1) * 0.125 + n2(p * 8.7 + 1.3) * 0.0625;
}

// la dalle sous le point q : (la distance au bord, l'identifiant de la dalle, la position dans la dalle)
vec4 dalle(vec2 q, out vec2 id) {
	float r = floor(q.y / rang);
	float x = q.x + h2(vec2(r, 3.0)) * longueur;
	float i0 = floor(x / longueur);
	float b0 = (i0 + (h2(vec2(i0, r)) - 0.5) * 0.6) * longueur;
	float b1 = (i0 + 1.0 + (h2(vec2(i0 + 1.0, r)) - 0.5) * 0.6) * longueur;
	float s = i0;
	float lo = b0;
	float hi = b1;
	if (x < b0) {
		s = i0 - 1.0;
		hi = b0;
		lo = (i0 - 1.0 + (h2(vec2(i0 - 1.0, r)) - 0.5) * 0.6) * longueur;
	} else if (x >= b1) {
		s = i0 + 1.0;
		lo = b1;
		hi = (i0 + 2.0 + (h2(vec2(i0 + 2.0, r)) - 0.5) * 0.6) * longueur;
	}
	id = vec2(s, r);
	float dx = min(x - lo, hi - x);
	float dz = min(q.y - r * rang, (r + 1.0) * rang - q.y);
	vec2 loc = vec2((x - lo) / (hi - lo), q.y / rang - r) * 2.0 - 1.0;
	return vec4(min(dx, dz), dx, loc);
}

// la hauteur du dallage en q (pour le relief)
float relief_h(vec2 q, float fin) {
	vec2 id;
	vec4 d = dalle(q, id);
	float e = d.x + (n2(q * 9.0) - 0.5) * 0.025;
	float h = smoothstep(0.0, 0.07, e) * 0.02;
	// la dalle penche à peine
	h += (h2(id + 1.7) - 0.5) * 0.01 * d.z + (h2(id + 4.1) - 0.5) * 0.01 * d.w;
	h += (fbm2(q * 6.0) - 0.5) * 0.006 * fin;
	return h;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	vec2 q;
	bool sol = abs(n.y) > 0.6;
	if (sol) {
		q = wp.xz;
	} else if (abs(n.x) > abs(n.z)) {
		q = vec2(wp.z, wp.y);
	} else {
		q = vec2(wp.x, wp.y);
	}
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(12.0, 60.0, dist);
	vec2 id;
	vec4 d = dalle(q, id);
	float r1 = h2(id + 0.37);
	float r2 = h2(id + 11.9);
	float r3 = h2(id + 23.3);
	// la pierre de la dalle
	vec3 pierre = vec3(0.56, 0.545, 0.52);
	pierre = mix(pierre, vec3(0.63, 0.58, 0.49), step(0.45, r1));
	pierre = mix(pierre, vec3(0.5, 0.52, 0.54), step(0.8, r1));
	pierre = mix(pierre, vec3(0.6, 0.5, 0.41), step(0.93, r1));
	pierre *= 0.84 + 0.26 * r2;
	pierre *= teinte;
	// le grain, les veines
	float gr = fbm2(q * 5.0 + id * 1.3);
	pierre *= 0.86 + 0.28 * mix(0.5, gr, fin * 0.7 + 0.3);
	float veine = 1.0 - smoothstep(0.0, 0.04, abs(n2(q * vec2(1.3, 3.1) + id * 5.0) - 0.5));
	pierre *= 1.0 - 0.12 * veine * step(0.6, r3) * fin;
	// l'usure : le centre de la dalle plus clair (les pas), les arêtes ébréchées
	float e = d.x + (n2(q * 9.0) - 0.5) * 0.025;
	pierre *= 1.0 + 0.08 * (1.0 - max(abs(d.z), abs(d.w)));
	// la saleté le long des joints, le joint
	float bord = 1.0 - smoothstep(0.0, 0.09, e);
	vec3 col = pierre * (1.0 - 0.22 * bord);
	float jw = 0.008 + 0.006 * n2(q * 3.0);
	float joint = 1.0 - smoothstep(jw, jw + 0.012, e);
	vec3 mortier = vec3(0.2, 0.19, 0.17);
	// dehors : la mousse et l'herbe dans les joints, les lichens, les taches d'humidité
	float mousse = 0.0;
	if (dehors > 0.5) {
		float mz = smoothstep(0.45, 0.75, fbm2(q * 0.35 + 5.0));
		mousse = joint * mz;
		mortier = mix(mortier, vec3(0.16, 0.22, 0.07) * (0.8 + 0.5 * n2(q * 20.0)), mz);
		float touffe = smoothstep(0.82, 0.92, n2(q * 2.3 + 9.0)) * (1.0 - smoothstep(0.0, 0.09, e));
		col = mix(col, vec3(0.2, 0.3, 0.08) * (0.7 + 0.6 * n2(q * 31.0)), touffe * 0.9 * (sol ? 1.0 : 0.0));
		float lich = smoothstep(0.78, 0.86, n2(q * 1.7 + id * 3.0)) * smoothstep(0.4, 0.6, n2(q * 9.0)) * step(0.5, r3);
		col = mix(col, vec3(0.66, 0.65, 0.55), lich * 0.4 * fin);
		float humide = smoothstep(0.55, 0.8, fbm2(q * 0.12 + 1.0));
		col *= 1.0 - 0.18 * humide;
		col *= 0.9 + 0.2 * fbm2(q * 0.05);
	}
	col = mix(col, mortier, joint);
	ALBEDO = col;
	float rough = mix(0.86, 0.5, poli) - 0.08 * r2 * poli;
	if (dehors > 0.5) {
		rough -= 0.15 * smoothstep(0.6, 0.85, fbm2(q * 0.12 + 1.0));
	}
	ROUGHNESS = mix(rough, 0.95, joint);
	SPECULAR = mix(0.32, 0.5, poli);
	// le relief
	if (sol) {
		float ep = 0.01;
		float h0 = relief_h(q, fin);
		float hx = relief_h(q + vec2(ep, 0.0), fin);
		float hz = relief_h(q + vec2(0.0, ep), fin);
		vec3 nw = normalize(vec3(-(hx - h0) / ep, 1.0, -(hz - h0) / ep) * vec3(1.0, 1.0, 1.0));
		nw = normalize(mix(vec3(0.0, 1.0, 0.0), nw, 0.25 + 0.75 * fin));
		if (n.y < 0.0) {
			nw = -nw;
		}
		NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
		// la lumière du ciel arrive mal au fond d'une cour entourée de hauts murs : moins de bleu à
		// l'ombre (le soleil, lui, n'est pas touché)
		AO = (1.0 - 0.5 * joint - 0.15 * bord) * mix(0.85, 0.72, dehors);
		AO_LIGHT_AFFECT = 0.0;
	}
}

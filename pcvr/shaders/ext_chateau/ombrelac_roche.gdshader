// Extension « Le Château d'Ombrelac » : la roche des falaises du Roc et de l'Aiguille (v10), peinte
// dans l'espace du monde (pas d'étirement sur les parois à pic) :
//  - la couleur : des bandes selon la hauteur (les strates, grises, beiges, un banc ocre), de grandes
//    taches, le grain ;
//  - le relief (normales) : le grain, les fissures, les joints des bancs ;
//  - le temps : la mousse sur ce qui regarde le ciel, les lichens, les coulures sous les corniches,
//    le pied mouillé et sombre près de l'eau.
// COLOR (facultatif) : R l'avancée de la roche (les creux plus sombres), G le banc, B près du pied.
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform float pied = 3.0;               // le niveau de l'eau au pied
uniform float avec_couleur = 1.0;       // 0 : sans couleurs de sommets (les blocs d'éboulis)
uniform float relief = 0.9;
uniform vec3 teinte = vec3(1.0);

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

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * n3(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return s;
}

// les fissures : des lignes fines, plutôt verticales
float fissure(vec3 p) {
	vec3 q = p + vec3(n3(p * 0.7), 0.0, n3(p * 0.7 + 4.0)) * 0.2;
	float r = 1.0 - abs(n3(q * vec3(0.3, 0.04, 0.3)) * 2.0 - 1.0);
	return smoothstep(0.975, 0.997, r) * smoothstep(0.35, 0.6, n3(p * vec3(0.2, 0.08, 0.2) + 9.0));
}

// les joints des bancs : des lignes à peu près horizontales, ondulées
float joint(vec3 p) {
	float y = p.y * 0.4 + n3(p * 0.06) * 2.5 + n3(p * 0.4) * 0.2;
	float t = abs(fract(y) - 0.5) * 2.0;
	return smoothstep(0.93, 0.99, t) * smoothstep(0.45, 0.75, n3(p * 0.25 + 2.0));
}

float hauteur(vec3 p, float fin) {
	float h = fbm(p * 1.6) * 0.7;
	h += (n3(p * 4.2) - 0.5) * 0.3;
	h += (n3(p * 11.0) - 0.5) * 0.16 * fin;
	h -= fissure(p) * 0.55;
	h -= joint(p) * 0.4;
	return h;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 p = wp;
	vec3 n = normalize(wn);
	float dist = length(p - CAMERA_POSITION_WORLD);
	float fin = 1.0 - smoothstep(30.0, 140.0, dist);
	// le relief : la pente de la hauteur, projetée sur la paroi
	float e = 0.04;
	float h0 = hauteur(p, fin);
	vec3 g = vec3(hauteur(p + vec3(e, 0, 0), fin) - h0, hauteur(p + vec3(0, e, 0), fin) - h0, hauteur(p + vec3(0, 0, e), fin) - h0) / e;
	g -= dot(g, n) * n;
	float force = relief * mix(0.35, 1.0, fin);
	vec3 nb = normalize(n - g * 0.17 * force);
	// les strates
	float band = n3(vec3(0.0, p.y * 0.42 + n3(p * 0.025) * 3.0, 0.0));
	vec3 c1 = vec3(0.23, 0.215, 0.195);
	vec3 c2 = vec3(0.36, 0.335, 0.295);
	vec3 col = mix(c1, c2, smoothstep(0.2, 0.8, band));
	float ocre = smoothstep(0.72, 0.86, n3(vec3(3.1, p.y * 0.23 + n3(p * 0.02) * 2.0, 1.7)));
	col = mix(col, vec3(0.42, 0.33, 0.23), ocre * 0.7);
	if (avec_couleur > 0.5) {
		col *= 0.9 + 0.2 * fract(COLOR.g * 7.31);
	}
	col *= 0.78 + 0.42 * fbm(p * 0.12);
	col *= 0.85 + 0.3 * n3(p * 2.3);
	col *= 0.86 + 0.28 * n3(p * 5.0) * fin + 0.14 * (1.0 - fin);
	col *= teinte;
	// les fissures et les joints, sombres
	float fis = fissure(p);
	float jo = joint(p);
	col *= 1.0 - 0.45 * fis;
	col *= 1.0 - 0.2 * jo;
	// les creux de la paroi
	float cav = avec_couleur > 0.5 ? COLOR.r : 0.6;
	col *= mix(0.62, 1.0, smoothstep(0.0, 0.7, cav));
	// les coulures : des traînées verticales, plus sombres sur les parois
	float verticale = 1.0 - abs(n.y);
	float coul = smoothstep(0.55, 0.85, n3(vec3(p.x * 1.3, p.y * 0.04, p.z * 1.3))) * verticale;
	col *= 1.0 - 0.3 * coul;
	// les lichens : des taches pâles, quelques-unes orangées
	float lt = smoothstep(0.76, 0.82, n3(p * 1.1 + 11.0)) * smoothstep(0.45, 0.7, n3(p * 4.0));
	vec3 lc = mix(vec3(0.66, 0.64, 0.52), vec3(0.72, 0.47, 0.18), step(0.7, n3(p * 0.5 + 3.0)));
	col = mix(col, lc * 0.8, lt * 0.35 * (1.0 - fis));
	// la mousse : sur les corniches et les bancs qui regardent le ciel
	float haut = n.y + (fbm(p * 0.35) - 0.5) * 0.7 + (nb.y - n.y) * 2.0;
	float mousse = smoothstep(0.35, 0.7, haut);
	mousse = max(mousse, smoothstep(0.6, 0.9, n3(p * 0.5 + 7.0)) * smoothstep(0.75, 1.0, cav) * 0.5 * smoothstep(-0.2, 0.3, n.y));
	vec3 mc = mix(vec3(0.13, 0.19, 0.07), vec3(0.27, 0.32, 0.11), n3(p * 3.0)) * (0.8 + 0.4 * n3(p * 14.0));
	col = mix(col, mc, mousse * 0.9);
	// le pied : mouillé, sombre, une ligne d'eau
	float pres = smoothstep(pied + 9.0, pied + 0.5, p.y);
	if (avec_couleur > 0.5) {
		pres = max(pres, COLOR.b * 0.4);
	}
	col *= 1.0 - 0.35 * pres;
	float ligne = smoothstep(pied + 1.2, pied + 0.2, p.y);
	col = mix(col, col * vec3(0.55, 0.6, 0.55), ligne);
	ALBEDO = col;
	ROUGHNESS = mix(0.9, 0.55, max(pres * 0.6, ligne)) - 0.05 * mousse;
	SPECULAR = 0.3;
	NORMAL = normalize((VIEW_MATRIX * vec4(mix(nb, n, mousse * 0.5), 0.0)).xyz);
	AO = mix(0.6, 0.85, smoothstep(0.0, 0.6, cav)) * (1.0 - 0.4 * fis);
	AO_LIGHT_AFFECT = 0.0;
}

// Extension « Le Château d'Ombrelac » : les portraits des Recteurs, peints à l'huile : un fond
// sombre et chaud qui s'éclaire derrière la tête, le buste dans sa robe de cérémonie (le col doré),
// le visage éclairé de trois quarts, la barbe ou le chapeau pointu selon le portrait, le vernis
// craquelé. UV : x de n à n + 1 (n : le numéro du portrait), y de 0 (bas) à 1 (haut).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform float aspect = 0.78;          // largeur / hauteur

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

// un ovale plein et doux : 1 dedans, 0 dehors
float ovale(vec2 p, vec2 c, vec2 r, float flou) {
	float d = length((p - c) / r);
	return 1.0 - smoothstep(1.0 - flou, 1.0 + flou, d);
}

void fragment() {
	float n = floor(UV.x);
	vec2 uv = vec2(fract(UV.x), UV.y);
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y);
	float s1 = h(vec2(n, 1.3));
	float s2 = h(vec2(n, 7.1));
	float s3 = h(vec2(n, 3.7));
	float s4 = h(vec2(n, 9.9));
	// le fond : un brun-vert sombre, plus clair derrière la tête, des coups de pinceau
	float coup = bruit(vec2(p.x * 9.0, p.y * 3.0) + n * 4.0) * 0.5 + bruit(p * 25.0 + n) * 0.25;
	vec3 fond = mix(vec3(0.07, 0.06, 0.04), vec3(0.2, 0.17, 0.1), s3);
	fond = mix(fond, fond * 2.1 + vec3(0.03, 0.02, 0.0), ovale(p, vec2(0.0, 0.62), vec2(0.42, 0.38), 0.6));
	vec3 col = fond * (0.8 + 0.4 * coup);
	// la robe : les épaules qui s'arrondissent ; la couleur selon le portrait
	vec3 robes[4] = vec3[](vec3(0.08, 0.11, 0.3), vec3(0.3, 0.06, 0.12), vec3(0.08, 0.22, 0.12), vec3(0.16, 0.14, 0.18));
	vec3 robe = robes[int(mod(n, 4.0))];
	float buste = ovale(p, vec2(0.0, 0.02), vec2(0.4, 0.4), 0.03);
	float pli = bruit(vec2(p.x * 14.0, p.y * 3.0) + n);
	vec3 rc = robe * (0.7 + 0.5 * pli) * (1.0 - 0.6 * smoothstep(-0.05, 0.35, p.x));
	col = mix(col, rc, buste);
	// le col doré en V, la chaîne de la charge
	float colv = abs(abs(p.x) * 1.3 - (0.42 - p.y));
	float orc = (1.0 - smoothstep(0.012, 0.022, colv)) * step(p.y, 0.42) * buste;
	float chaine = (1.0 - smoothstep(0.006, 0.012, abs(length(p - vec2(0.0, 0.42)) - 0.2))) * step(p.y, 0.38) * buste;
	vec3 or_c = vec3(0.85, 0.64, 0.27);
	col = mix(col, or_c * (0.8 + 0.4 * bruit(p * 60.0)), max(orc, chaine * 0.9));
	// le cou, le visage : éclairé de la gauche
	vec2 tc = vec2(0.0, 0.6 + 0.03 * s4);
	float cou = ovale(p, vec2(0.0, 0.43), vec2(0.06, 0.08), 0.1);
	float vis = ovale(p, tc, vec2(0.105, 0.14), 0.06);
	vec3 peau = mix(vec3(0.78, 0.6, 0.48), vec3(0.55, 0.38, 0.27), s2);
	float lum = 1.05 - 0.75 * smoothstep(-0.08, 0.1, p.x - 0.02 * (p.y - tc.y));
	vec3 pc = peau * lum;
	col = mix(col, pc * 0.75, cou);
	col = mix(col, pc, vis);
	// les yeux, les sourcils, le nez, la bouche
	for (int i = -1; i <= 1; i += 2) {
		vec2 e = tc + vec2(float(i) * 0.042, 0.02);
		col = mix(col, vec3(0.08, 0.05, 0.04), ovale(p, e, vec2(0.016, 0.009), 0.3) * vis);
		col = mix(col, peau * 0.35, ovale(p, e + vec2(0.0, 0.026), vec2(0.026, 0.006), 0.4) * vis);
	}
	col = mix(col, peau * lum * 0.6, ovale(p, tc + vec2(0.012, -0.03), vec2(0.008, 0.03), 0.5) * vis);
	col = mix(col, vec3(0.35, 0.13, 0.1) * lum, ovale(p, tc + vec2(0.0, -0.075), vec2(0.03, 0.007), 0.4) * vis);
	// les cheveux (gris, blancs, sombres)
	vec3 poil = mix(vec3(0.82, 0.8, 0.76), vec3(0.14, 0.1, 0.07), step(0.6, s1));
	poil = mix(poil, vec3(0.5, 0.48, 0.45), step(0.3, s1) * step(s1, 0.6));
	float cheveux = ovale(p, tc + vec2(0.0, 0.04), vec2(0.125, 0.14), 0.05) * (1.0 - ovale(p, tc + vec2(0.0, -0.01), vec2(0.1, 0.13), 0.05));
	col = mix(col, poil * (0.6 + 0.5 * lum) * (0.8 + 0.3 * bruit(p * 80.0)), cheveux);
	// la barbe (un portrait sur deux)
	if (s2 > 0.45) {
		float lg = 0.12 + 0.12 * s4;
		vec2 bc = tc + vec2(0.0, -0.08 - lg * 0.35);
		float barbe = ovale(p, bc, vec2(0.095, lg * 0.75), 0.15) * step(p.y, tc.y - 0.045);
		barbe = max(barbe, ovale(p, tc + vec2(0.0, -0.06), vec2(0.1, 0.05), 0.2) * (1.0 - ovale(p, tc + vec2(0.0, -0.075), vec2(0.035, 0.012), 0.3)));
		barbe *= 1.0 - smoothstep(tc.y - 0.03, tc.y - 0.01, p.y);
		float meches = 0.75 + 0.35 * bruit(vec2(p.x * 90.0, p.y * 12.0));
		col = mix(col, poil * (0.55 + 0.5 * lum) * meches, barbe);
	}
	// le chapeau pointu (un portrait sur trois) : un cône penché, son bord
	if (s3 > 0.62) {
		float hy = p.y - (tc.y + 0.1);
		float larg = 0.15 * (1.0 - hy / 0.3);
		float pointe = step(0.0, hy) * step(hy, 0.3) * step(abs(p.x + hy * 0.25), larg);
		float bord = ovale(p, tc + vec2(0.0, 0.1), vec2(0.19, 0.03), 0.1);
		vec3 ch = robe * 1.2 * (0.7 + 0.5 * lum);
		col = mix(col, ch, max(pointe, bord));
		col = mix(col, or_c, (1.0 - smoothstep(0.004, 0.009, abs(hy - 0.04))) * pointe);
	}
	// le vernis : jauni, craquelé, plus sombre aux bords
	float cr = bruit(p * 70.0 + n * 3.0);
	float craq = 1.0 - smoothstep(0.0, 0.035, abs(cr - 0.5));
	col *= 1.0 - craq * 0.18;
	col = mix(col, col * vec3(1.05, 0.95, 0.7), 0.35);
	float bords = min(min(uv.x, 1.0 - uv.x) * aspect, min(uv.y, 1.0 - uv.y));
	col *= 0.55 + 0.45 * smoothstep(0.0, 0.18, bords);
	ALBEDO = col;
	ROUGHNESS = 0.42 + 0.2 * cr;
	SPECULAR = 0.35;
}

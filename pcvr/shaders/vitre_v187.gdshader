// V187 : les vitres de la Tour Kumo (Néopolis). Derrière chaque vitre, une pièce en profondeur (le plafond et
// ses dalles de lumière, le sol, les murs, le fond avec ses meubles) : on la voit glisser quand on marche
// devant, sans un seul polygone de plus. Le jour, la vitre reflète le ciel ; la nuit, les pièces allumées
// éclairent la rue, les autres restent dans l'ombre. Un store descend plus ou moins selon la vitre.
// Par sommet : UV = la place dans la vitre (0..1, y vers le haut) ; UV2 = sa taille en mètres ;
// COLOR = (hasard, chaleur de la lumière, part du store, allumée la nuit).
shader_type spatial;
render_mode cull_back;

uniform float nuit : hint_range(0.0, 1.0) = 0.0;
uniform float profondeur = 4.5;
uniform vec3 ciel : source_color = vec3(0.45, 0.62, 0.8);

varying vec3 v_vue;      // le regard, dans le repère de la vitre (x le long du mur, y vers le haut, z vers le dedans)

float h1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void vertex() {
	vec3 pw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 nw = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 tw = normalize((MODEL_MATRIX * vec4(TANGENT, 0.0)).xyz);
	vec3 v = pw - CAMERA_POSITION_WORLD;
	v_vue = vec3(dot(v, tw), v.y, -dot(v, nw));
}

void fragment() {
	vec2 taille = UV2;
	vec3 p = vec3(UV.x * taille.x, UV.y * taille.y, 0.0);
	vec3 d = normalize(v_vue);
	d.z = max(d.z, 0.02);
	float graine = COLOR.r;
	float chaud = COLOR.g;
	float store = COLOR.b;
	float allume = step(0.5, COLOR.a);
	// la pièce : large comme la vitre, haute comme elle, profonde de « profondeur »
	float tx = d.x > 0.0 ? (taille.x - p.x) / d.x : (abs(d.x) > 1e-4 ? -p.x / d.x : 1e6);
	float ty = d.y > 0.0 ? (taille.y - p.y) / d.y : (abs(d.y) > 1e-4 ? -p.y / d.y : 1e6);
	float tz = profondeur / d.z;
	float t = min(tx, min(ty, tz));
	vec3 hit = p + d * t;
	vec3 mur = mix(vec3(0.62, 0.66, 0.72), vec3(0.78, 0.72, 0.62), chaud);
	vec3 c;
	float lum = 0.55;
	if (t == ty && d.y > 0.0) {
		// le plafond : des dalles, une rangée de dalles de lumière
		vec2 q = vec2(hit.x, hit.z) / 0.6;
		float joint = step(0.06, fract(q.x)) * step(0.06, fract(q.y));
		float dalle = step(0.5, h1(floor(q.x) * 3.1 + floor(q.y) * 7.7 + graine * 31.0)) * step(1.0, mod(floor(q.y), 3.0));
		c = mix(vec3(0.42), vec3(0.86, 0.86, 0.84), joint);
		c = mix(c, vec3(1.0, 0.98, 0.94), (1.0 - dalle) * joint * 0.9 * step(mod(floor(q.y), 3.0), 0.5));
		lum = 0.75 + 0.9 * (1.0 - dalle) * step(mod(floor(q.y), 3.0), 0.5);
	} else if (t == ty) {
		// le sol : une moquette, plus sombre vers le fond
		c = mix(vec3(0.16, 0.2, 0.3), vec3(0.3, 0.22, 0.16), chaud) * (1.0 - 0.3 * hit.z / profondeur);
		lum = 0.4;
	} else if (t == tz) {
		// le fond : le mur, une porte ou une étagère, un bureau et son écran
		vec2 q = vec2(hit.x / taille.x, hit.y / taille.y);
		c = mur * 0.92;
		float sorte = h1(graine * 17.0);
		if (sorte < 0.35) {
			// une porte
			float porte = step(0.3, q.x) * step(q.x, 0.62) * step(q.y, 0.78);
			c = mix(c, vec3(0.3, 0.24, 0.2), porte);
		} else if (sorte < 0.7) {
			// une étagère et ses dossiers de couleur
			float et = step(0.1, q.x) * step(q.x, 0.9) * step(0.12, q.y) * step(q.y, 0.8);
			vec2 cs = vec2(q.x * 14.0, q.y * 4.0);
			vec3 dos = 0.35 + 0.4 * vec3(h1(floor(cs.x) + floor(cs.y) * 9.0 + graine), h1(floor(cs.x) * 2.0 + floor(cs.y) + graine * 3.0), h1(floor(cs.x) * 5.0 + graine * 7.0));
			c = mix(c, dos * step(0.12, fract(cs.y)), et);
		} else {
			// un tableau lumineux
			float tab = step(0.2, q.x) * step(q.x, 0.8) * step(0.4, q.y) * step(q.y, 0.8);
			c = mix(c, vec3(0.2, 0.75, 0.95) * (0.6 + 0.4 * sin(q.x * 40.0 + graine * 9.0)), tab);
			lum += tab * 0.6;
		}
		// le bureau, devant le fond
		float bur = step(0.08, q.x) * step(q.x, 0.92) * step(q.y, 0.24);
		c = mix(c, vec3(0.18, 0.17, 0.17), bur * step(0.5, h1(graine * 5.0)));
	} else {
		// les murs de côté
		c = mur * (0.8 - 0.25 * hit.z / profondeur);
	}
	c *= 1.0 - 0.35 * t / (profondeur * 1.6);
	// le store : il descend du haut de la vitre
	float st = step(1.0 - store, UV.y);
	vec3 cs2 = vec3(0.8, 0.8, 0.76) * (0.75 + 0.25 * step(0.5, fract(UV.y * taille.y * 14.0)));
	c = mix(c, cs2, st);
	lum = mix(lum, 0.28, st);
	// le jour : la vitre reflète le ciel, la pièce est dans la pénombre ; la nuit : les pièces allumées brillent
	vec3 teinte = mix(vec3(0.75, 0.88, 1.0), vec3(1.0, 0.82, 0.58), chaud);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 jour = mix(c * 0.38, ciel, 0.28 + 0.6 * fres);
	vec3 soir = c * 0.05;
	ALBEDO = mix(jour, soir, nuit);
	ROUGHNESS = 0.07;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	// (la nuit : assez de lumière pour éclairer la rue, pas assez pour effacer les meubles et les stores)
	EMISSION = c * teinte * min(lum, 1.1) * allume * nuit * 0.8 + c * teinte * lum * 0.05 * (1.0 - nuit);
}

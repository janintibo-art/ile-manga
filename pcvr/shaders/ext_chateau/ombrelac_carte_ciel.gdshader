// Extension « Le Château d'Ombrelac » : une carte du ciel (un planisphère céleste) : un papier bleu
// de nuit, la bordure dorée, les cercles et les rayons des coordonnées, l'écliptique en tirets, des
// étoiles de toutes grandeurs, quelques constellations reliées. UV de 0 à 1.
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform float aspect = 0.75;          // largeur / hauteur

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	vec2 c = vec2(aspect * 0.5, 0.5);
	float R = min(aspect, 1.0) * 0.44;
	vec2 d = p - c;
	float r = length(d);
	float a = atan(d.y, d.x);
	float or_l = 0.0;
	// la bordure
	float bord = min(min(p.x, aspect - p.x), min(p.y, 1.0 - p.y));
	or_l = max(or_l, step(bord, 0.02) * step(0.012, bord));
	// le cercle du planisphère, les cercles et les rayons
	or_l = max(or_l, 1.0 - smoothstep(0.002, 0.005, abs(r - R)));
	float grille = 0.0;
	for (int i = 1; i < 4; i++) {
		grille = max(grille, 1.0 - smoothstep(0.001, 0.003, abs(r - R * float(i) / 4.0)));
	}
	float ray = abs(fract(a / 6.2832 * 12.0 + 0.5) - 0.5) * r * 0.52;
	grille = max(grille, (1.0 - smoothstep(0.001, 0.003, ray)) * step(r, R));
	// l'écliptique : un cercle décentré, en tirets
	float ec = abs(length(d - vec2(0.05, 0.08)) - R * 0.7);
	or_l = max(or_l, (1.0 - smoothstep(0.002, 0.004, ec)) * step(0.5, fract(a * 12.0)) * step(r, R));
	// les étoiles
	float et = 0.0;
	vec2 g = p * 26.0;
	vec2 cell = floor(g);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cc = cell + vec2(float(i), float(j));
			vec2 sp = (cc + vec2(h(cc), h(cc + 3.1))) / 26.0;
			float mag = pow(h(cc + 7.7), 3.0);
			float s = 0.0015 + 0.006 * mag;
			et = max(et, 1.0 - smoothstep(s * 0.6, s, length(p - sp)));
			// une ligne vers la voisine (une constellation), pour les plus brillantes
			if (mag > 0.35) {
				vec2 cn = cc + vec2(1.0, 0.0);
				vec2 sn = (cn + vec2(h(cn), h(cn + 3.1))) / 26.0;
				if (pow(h(cn + 7.7), 3.0) > 0.2) {
					et = max(et, (1.0 - smoothstep(0.0006, 0.0014, segment(p, sp, sn))) * 0.7);
				}
			}
		}
	}
	et *= step(r, R);
	vec3 papier = vec3(0.05, 0.07, 0.17) * (0.9 + 0.15 * h(floor(p * 90.0)));
	vec3 col = papier + vec3(0.25, 0.3, 0.45) * grille * 0.5;
	col = mix(col, vec3(0.95, 0.92, 0.78), et);
	col = mix(col, vec3(0.85, 0.64, 0.27), or_l);
	ALBEDO = col;
	METALLIC = or_l * 0.6;
	ROUGHNESS = mix(0.85, 0.35, or_l);
	EMISSION = vec3(0.95, 0.92, 0.78) * et * 0.12;
}

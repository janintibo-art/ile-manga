// Extension « Le Château d'Ombrelac » : un grand tableau d'ardoise couvert de figures à la craie.
// UV : x de 0 à 1 sur la largeur, y de 0 (bas) à 1 ; « aspect » : largeur / hauteur.
// mode 0 (la Salle des Astres) : des orbites, un astre, des rayons, des lignes d'écriture ;
// mode 1 (l'Amphithéâtre) : un cercle et ses cordes, un triangle, une spirale, des calculs.
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform int mode = 0;
uniform float aspect = 2.4;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float trait(float d, float w) {
	return 1.0 - smoothstep(w * 0.5, w, abs(d));
}

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

// des lignes d'écriture : des tirets inégaux sur des rangées, dans le rectangle r (x0, y0, x1, y1)
float ecriture(vec2 p, vec4 r, float graine) {
	if (p.x < r.x || p.x > r.z || p.y < r.y || p.y > r.w) {
		return 0.0;
	}
	float ligne = floor((p.y - r.y) / 0.07);
	float fy = fract((p.y - r.y) / 0.07);
	float mot = floor(p.x / 0.045 + h(vec2(ligne, graine)) * 3.0);
	float plein = step(0.25, h(vec2(mot, ligne + graine)));
	float fin = step(p.x, r.x + (r.z - r.x) * (0.45 + 0.55 * h(vec2(ligne, graine + 4.0))));
	float lettres = step(0.35, h(floor(vec2(p.x * 160.0, ligne))));
	return plein * fin * step(0.35, fy) * step(fy, 0.62) * (0.5 + 0.5 * lettres);
}

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	float craie = 0.0;
	if (mode == 0) {
		vec2 c = vec2(aspect * 0.33, 0.52);
		float r = length((p - c) * vec2(1.0, 1.35));
		for (int i = 1; i <= 4; i++) {
			craie = max(craie, trait(r - float(i) * 0.085, 0.006));
		}
		craie = max(craie, 1.0 - smoothstep(0.03, 0.036, length(p - c)));
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785;
			craie = max(craie, trait(segment(p, c + vec2(cos(a), sin(a)) * 0.045, c + vec2(cos(a), sin(a)) * 0.07), 0.006));
		}
		for (int i = 1; i <= 4; i++) {
			float a = float(i) * 1.9;
			vec2 q = c + vec2(cos(a), sin(a) / 1.35) * float(i) * 0.085;
			craie = max(craie, trait(length(p - q) - 0.014, 0.006));
		}
		craie = max(craie, ecriture(p, vec4(aspect * 0.6, 0.18, aspect * 0.95, 0.85), 3.0));
	} else {
		vec2 c = vec2(aspect * 0.2, 0.52);
		float r = length(p - c);
		craie = trait(r - 0.3, 0.006);
		craie = max(craie, trait(segment(p, c + vec2(-0.3, 0.0), c + vec2(0.3, 0.0)), 0.006));
		craie = max(craie, trait(segment(p, c + vec2(-0.3, 0.0), c + vec2(0.12, 0.275)), 0.006));
		craie = max(craie, trait(segment(p, c + vec2(0.3, 0.0), c + vec2(0.12, 0.275)), 0.006));
		vec2 t0 = vec2(aspect * 0.45, 0.2);
		craie = max(craie, trait(segment(p, t0, t0 + vec2(0.4, 0.0)), 0.006));
		craie = max(craie, trait(segment(p, t0, t0 + vec2(0.0, 0.3)), 0.006));
		craie = max(craie, trait(segment(p, t0 + vec2(0.0, 0.3), t0 + vec2(0.4, 0.0)), 0.006));
		vec2 s = p - vec2(aspect * 0.52, 0.68);
		float ang = atan(s.y, s.x);
		float rs = length(s);
		float spi = mod(rs - 0.018 * (ang + 3.14159), 0.11) - 0.055;
		craie = max(craie, trait(spi, 0.006) * step(rs, 0.2));
		craie = max(craie, ecriture(p, vec4(aspect * 0.68, 0.15, aspect * 0.97, 0.88), 9.0));
	}
	// l'ardoise, ses traces d'éponge
	float tache = h(floor(p * 18.0)) * 0.5 + h(floor(p * 5.0)) * 0.5;
	vec3 ardoise = vec3(0.07, 0.09, 0.085) * (0.85 + 0.3 * tache);
	vec3 blanc = vec3(0.82, 0.83, 0.8) * (0.75 + 0.25 * h(floor(p * 300.0)));
	ALBEDO = mix(ardoise, blanc, craie * 0.9);
	ROUGHNESS = 0.9;
}

// V91 : les yourtes de l'Île de Larsen. Un seul shader pour toutes les pièces d'une yourte
// (le mur de feutre, le toit de toile, le lambrequin, le bois, la porte peinte, les cordes, le tuyau
// du poêle) ; chaque yourte garde ses couleurs (INSTANCE_CUSTOM : rgb = la couleur du feutre,
// a = une graine). style 0 : le Camp des Fleurs (feutre clair, bandeau de losanges et de zigzags aux
// couleurs vives, porte orange peinte de fleurs) ; style 1 : Rainville (toiles sombres rapiécées de
// carreaux de flanelle, bois gris, porte noire écaillée).
// UV : en mètres (mur : u = la longueur du tour, v = la hauteur ; toit : u = le pan, v = la pente ;
// porte et lambrequin : 0..1).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform int part = 0;      // 0 mur, 1 toit, 2 bois, 3 porte, 4 corde, 5 lambrequin, 6 métal
uniform int style = 0;
uniform float wall_h = 1.8;

varying flat vec4 custom;
varying vec3 obj;

float h1(float n) { return fract(sin(mod(n, 61.0) * 12.9898 + 0.5) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * noise2(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

vec3 palette(float k) {
	// les couleurs du Camp des Fleurs
	int i = int(floor(k * 6.0));
	if (i == 0) return vec3(0.86, 0.22, 0.16);
	if (i == 1) return vec3(0.95, 0.62, 0.12);
	if (i == 2) return vec3(0.96, 0.84, 0.25);
	if (i == 3) return vec3(0.22, 0.58, 0.36);
	if (i == 4) return vec3(0.18, 0.42, 0.72);
	return vec3(0.55, 0.28, 0.62);
}

// les carreaux d'une chemise de flanelle (deux couleurs et le noir)
vec3 flanelle(vec2 uv, vec3 a, vec3 b) {
	vec2 c = fract(uv * 2.2);
	float sx = step(0.62, c.x) + step(0.86, c.x) * 0.6;
	float sy = step(0.62, c.y) + step(0.86, c.y) * 0.6;
	vec3 col = mix(a, b * 0.35, clamp((sx + sy) * 0.45, 0.0, 1.0));
	float fine = step(0.47, fract(uv.x * 14.0)) * step(0.47, fract(uv.y * 14.0));
	col = mix(col, b, fine * 0.12);
	// le tissage : une petite diagonale
	col *= 0.93 + 0.07 * step(0.5, fract((uv.x + uv.y) * 60.0));
	return col;
}

void vertex() {
	custom = INSTANCE_CUSTOM;
	obj = VERTEX;
}

void fragment() {
	vec2 uv = UV;
	float seed = floor(custom.a * 97.0) + 0.37;
	vec3 felt = custom.rgb;
	vec3 col = felt;
	float rough = 0.94;
	float metal = 0.0;
	float bump = 0.0;
	if (part == 0) {
		// le feutre : des fibres en nuages, un peu plus sombre en bas (la poussière, l'eau)
		float f = fbm(uv * vec2(6.0, 6.0) + seed);
		float fib = noise2(uv * vec2(60.0, 40.0) + seed);
		col = felt * (0.86 + 0.2 * f) * (0.95 + 0.08 * fib);
		bump = f * 0.5 + fib * 0.3;
		if (style == 0) {
			// le bandeau peint : des losanges entre deux zigzags
			float y0 = wall_h * 0.58;
			float y1 = wall_h * 0.82;
			if (uv.y > y0 && uv.y < y1) {
				float t = (uv.y - y0) / (y1 - y0);
				float u = uv.x / 0.5;
				float cell = floor(u);
				float x = fract(u);
				vec3 c1 = palette(h1(seed + 1.0));
				vec3 c2 = palette(h1(seed + 2.0));
				vec3 c3 = palette(h1(seed + 3.0 + cell * 0.0));
				vec3 band = mix(vec3(0.95, 0.9, 0.8), c1, 0.15);
				float zz = abs(x - 0.5) * 2.0;
				if (t < 0.22) {
					band = (t / 0.22 > zz) ? c2 : band;
				} else if (t > 0.78) {
					band = ((1.0 - t) / 0.22 > zz) ? c2 : band;
				} else {
					float d = abs(x - 0.5) + abs((t - 0.5) / 0.56 * 0.5);
					band = d < 0.32 ? (d < 0.14 ? c3 : c1) : band;
				}
				col = band * (0.88 + 0.16 * f);
			}
			// des fleurs peintes à la main, ici et là, en bas du mur
			vec2 g = uv / vec2(1.1, 0.7);
			vec2 gi = floor(g);
			vec2 gf = fract(g) - 0.5;
			if (uv.y < wall_h * 0.5 && h1(gi.x * 7.0 + gi.y * 3.0 + seed) > 0.62) {
				float ang = atan(gf.y, gf.x);
				float r = length(gf);
				float petal = 0.22 + 0.08 * cos(ang * 5.0 + seed);
				if (r < petal) {
					col = r < 0.09 ? vec3(0.98, 0.85, 0.2) : palette(h1(gi.x + gi.y * 13.0 + seed));
					col *= 0.9 + 0.1 * f;
				}
			}
		} else {
			// Rainville : des pièces cousues, de la flanelle, des taches d'eau
			vec2 g = uv / vec2(0.9, 0.6);
			vec2 gi = floor(g + vec2(floor(uv.y / 0.6) * 0.37, 0.0));
			float r = h1(gi.x * 17.0 + gi.y * 5.0 + seed);
			vec2 gf = fract(g + vec2(floor(uv.y / 0.6) * 0.37, 0.0));
			if (r > 0.55) {
				vec3 a = r > 0.8 ? vec3(0.5, 0.08, 0.07) : (r > 0.68 ? vec3(0.16, 0.3, 0.2) : vec3(0.18, 0.24, 0.42));
				vec3 pc = flanelle(uv, a, vec3(0.05));
				float edge = min(min(gf.x, 1.0 - gf.x), min(gf.y, 1.0 - gf.y));
				col = mix(col, pc * (0.85 + 0.2 * f), step(0.05, edge));
				// la couture
				col *= 1.0 - 0.35 * (step(edge, 0.05) * step(0.5, fract(uv.x * 22.0 + uv.y * 22.0)));
			}
			float drip = fbm(vec2(uv.x * 3.0, uv.y * 0.6) + seed);
			col *= mix(1.0, 0.72, smoothstep(0.5, 0.75, drip) * smoothstep(wall_h, 0.0, uv.y));
		}
		col *= mix(0.62, 1.0, smoothstep(0.0, 0.35, uv.y));
	} else if (part == 1) {
		// le toit : une toile tendue, les coutures entre les pans, plus claire vers la couronne
		float f = fbm(uv * vec2(5.0, 3.0) + seed * 2.0);
		float seam = smoothstep(0.035, 0.0, abs(fract(uv.x) - 0.5) - 0.465);
		vec3 can = style == 0 ? vec3(0.93, 0.89, 0.8) : mix(felt, vec3(0.2, 0.21, 0.2), 0.6);
		col = can * (0.84 + 0.22 * f);
		col *= 1.0 - 0.18 * seam;
		col *= mix(0.78, 1.04, smoothstep(0.0, 2.6, uv.y));
		// les traînées de pluie depuis la couronne ; un peu de mousse en bas (Rainville)
		float streak = noise2(vec2(uv.x * 9.0, uv.y * 0.5) + seed);
		col *= 1.0 - 0.12 * smoothstep(0.55, 0.9, streak);
		if (style == 1) {
			float moss = fbm(uv * 2.0 + seed);
			col = mix(col, vec3(0.16, 0.22, 0.1), smoothstep(0.55, 0.8, moss) * smoothstep(1.2, 0.0, uv.y) * 0.7);
			// une bâche bleue rapiécée, sur un pan sur trois
			if (h1(floor(uv.x) + seed) > 0.72 && uv.y > 0.4 && uv.y < 1.9) {
				col = vec3(0.12, 0.25, 0.48) * (0.8 + 0.25 * f);
			}
		}
		bump = f * 0.6 + seam;
	} else if (part == 2) {
		// le bois : peint en orange au Camp des Fleurs, gris et nu à Rainville
		float grain = noise2(vec2(uv.x * 2.0, uv.y * 30.0) + seed) * 0.6 + noise2(vec2(uv.x * 8.0, uv.y * 90.0)) * 0.4;
		vec3 w = style == 0 ? vec3(0.86, 0.38, 0.1) : vec3(0.42, 0.39, 0.35);
		col = w * (0.78 + 0.3 * grain);
		if (style == 0) {
			// la peinture usée laisse voir le bois
			col = mix(col, vec3(0.5, 0.34, 0.2) * (0.8 + 0.3 * grain), smoothstep(0.72, 0.85, fbm(uv * 6.0 + seed)));
		}
		rough = 0.7;
		bump = grain;
	} else if (part == 3) {
		// la porte
		vec2 p = uv - 0.5;
		float f = fbm(uv * 8.0 + seed);
		if (style == 0) {
			col = vec3(0.9, 0.45, 0.08) * (0.86 + 0.18 * f);
			// les deux battants, le cadre, une grande fleur et des spirales
			float frame = step(0.42, max(abs(p.x), abs(p.y)));
			float mid = step(abs(p.x), 0.012);
			vec2 q = vec2(abs(p.x) - 0.22, p.y * 0.55);
			float ang = atan(q.y, q.x);
			float r = length(q);
			float fl = step(r, 0.1 + 0.035 * cos(ang * 6.0));
			vec3 c1 = palette(h1(seed + 5.0));
			col = mix(col, c1, fl);
			col = mix(col, vec3(0.98, 0.86, 0.2), step(r, 0.035));
			col = mix(col, vec3(0.2, 0.42, 0.68), step(0.5, sin(length(p) * 50.0 + atan(p.y, p.x)) ) * step(0.38, abs(p.y)) * 0.6);
			col = mix(col, vec3(0.55, 0.2, 0.05), max(frame, mid));
		} else {
			col = vec3(0.06, 0.07, 0.07) * (0.9 + 0.2 * f);
			// la peinture écaillée : du bois gris dessous, de la rouille autour de la poignée
			float chip = fbm(uv * 14.0 + seed);
			col = mix(col, vec3(0.42, 0.4, 0.36), smoothstep(0.66, 0.72, chip));
			col = mix(col, vec3(0.4, 0.18, 0.06), smoothstep(0.08, 0.0, length(p - vec2(0.3, 0.0))) * 0.8);
			float frame = step(0.43, max(abs(p.x), abs(p.y)));
			col = mix(col, vec3(0.25, 0.24, 0.22), frame);
		}
		rough = 0.6;
		bump = f;
	} else if (part == 4) {
		// une corde de chanvre torsadée
		float tw = 0.5 + 0.5 * sin(uv.x * 140.0 + uv.y * 30.0);
		col = vec3(0.55, 0.43, 0.27) * (0.7 + 0.35 * tw);
		if (style == 1) col *= 0.6;
		bump = tw;
	} else if (part == 5) {
		// le lambrequin : la bordure festonnée qui pend sous le toit
		float x = fract(uv.x / 0.45);
		float lim = 0.45 + 0.55 * (1.0 - pow(abs(x - 0.5) * 2.0, 2.0));
		if (uv.y > lim) discard;
		if (style == 0) {
			col = palette(h1(floor(uv.x / 0.45) * 0.37 + seed));
			col = mix(col, vec3(0.98, 0.94, 0.85), step(uv.y, 0.12));
		} else {
			col = flanelle(uv * vec2(1.0, 0.4), vec3(0.45, 0.07, 0.06), vec3(0.04));
		}
		col *= 0.9 + 0.15 * fbm(uv * 10.0 + seed);
	} else {
		// le tuyau du poêle, en tôle noircie, avec sa rouille
		float f = fbm(uv * vec2(4.0, 10.0) + seed);
		col = vec3(0.12, 0.12, 0.12) * (0.8 + 0.4 * f);
		col = mix(col, vec3(0.38, 0.17, 0.06), smoothstep(0.6, 0.8, f) * 0.8);
		rough = 0.55;
		metal = 0.6;
		bump = f;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
	// les creux de la matière retiennent un peu d'ombre
	AO = 0.82 + 0.18 * clamp(bump, 0.0, 1.0);
	AO_LIGHT_AFFECT = 0.4;
}

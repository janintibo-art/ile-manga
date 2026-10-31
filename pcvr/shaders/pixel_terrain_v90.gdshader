// V90 : le sol de l'Île Pixelithique, en blocs de 50 cm peints de pixels fins (16 par mètre).
// Chaque matière a quatre teintes pour le dessus et quatre pour les côtés ; chaque pixel tire la
// sienne au hasard (avec des plaques plus claires ou plus sombres, bloc par bloc) ; un liseré sombre
// d'un pixel dessine le contour des blocs ; sur les côtés, l'herbe déborde de quelques pixels
// (une frange irrégulière) au-dessus de la terre ; quelques fleurs-pixels dans la prairie ; la lave
// coule et brille. De loin, les pixels se fondent dans la teinte moyenne (pas de scintillement).
// COLOR.r : la matière ((m + 0,5) / 16) ; UV.x : le haut de la colonne (côtés).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform bool detail = true;
uniform float px_per_m = 16.0;

const int NM = 12;
// SABLE, HERBE, JUNGLE, TERRE, PIERRE, BASALTE, LAVE, CENDRE, BOUE, MOUSSE, OS, PRAIRIE
const vec3 TOP[48] = vec3[48](
	vec3(0.86, 0.78, 0.55), vec3(0.80, 0.72, 0.50), vec3(0.91, 0.84, 0.63), vec3(0.75, 0.67, 0.47),
	vec3(0.38, 0.58, 0.22), vec3(0.32, 0.51, 0.18), vec3(0.44, 0.63, 0.26), vec3(0.28, 0.45, 0.16),
	vec3(0.17, 0.40, 0.15), vec3(0.13, 0.34, 0.12), vec3(0.22, 0.46, 0.18), vec3(0.10, 0.28, 0.10),
	vec3(0.55, 0.40, 0.25), vec3(0.49, 0.35, 0.22), vec3(0.61, 0.45, 0.29), vec3(0.44, 0.31, 0.19),
	vec3(0.50, 0.50, 0.49), vec3(0.44, 0.44, 0.44), vec3(0.57, 0.56, 0.54), vec3(0.38, 0.38, 0.39),
	vec3(0.22, 0.20, 0.21), vec3(0.18, 0.17, 0.18), vec3(0.28, 0.26, 0.26), vec3(0.14, 0.13, 0.14),
	vec3(1.00, 0.45, 0.06), vec3(1.00, 0.26, 0.03), vec3(1.00, 0.74, 0.22), vec3(0.72, 0.12, 0.02),
	vec3(0.36, 0.33, 0.31), vec3(0.31, 0.29, 0.28), vec3(0.42, 0.39, 0.36), vec3(0.27, 0.25, 0.24),
	vec3(0.36, 0.28, 0.18), vec3(0.31, 0.24, 0.16), vec3(0.41, 0.32, 0.21), vec3(0.27, 0.21, 0.14),
	vec3(0.30, 0.46, 0.22), vec3(0.25, 0.40, 0.19), vec3(0.36, 0.52, 0.26), vec3(0.42, 0.44, 0.40),
	vec3(0.80, 0.74, 0.60), vec3(0.74, 0.68, 0.54), vec3(0.86, 0.80, 0.66), vec3(0.68, 0.62, 0.49),
	vec3(0.55, 0.66, 0.27), vec3(0.49, 0.60, 0.23), vec3(0.62, 0.72, 0.31), vec3(0.45, 0.54, 0.21)
);
const vec3 SIDE[48] = vec3[48](
	vec3(0.80, 0.71, 0.49), vec3(0.74, 0.65, 0.45), vec3(0.85, 0.77, 0.56), vec3(0.69, 0.60, 0.42),
	vec3(0.50, 0.36, 0.22), vec3(0.44, 0.31, 0.19), vec3(0.56, 0.41, 0.26), vec3(0.40, 0.28, 0.17),
	vec3(0.40, 0.29, 0.18), vec3(0.35, 0.25, 0.16), vec3(0.45, 0.33, 0.21), vec3(0.31, 0.22, 0.14),
	vec3(0.50, 0.36, 0.22), vec3(0.44, 0.31, 0.19), vec3(0.56, 0.41, 0.26), vec3(0.40, 0.28, 0.17),
	vec3(0.58, 0.55, 0.51), vec3(0.51, 0.48, 0.45), vec3(0.64, 0.61, 0.57), vec3(0.46, 0.43, 0.41),
	vec3(0.20, 0.18, 0.19), vec3(0.16, 0.15, 0.16), vec3(0.25, 0.23, 0.23), vec3(0.12, 0.11, 0.12),
	vec3(0.30, 0.12, 0.08), vec3(0.22, 0.09, 0.06), vec3(0.40, 0.16, 0.08), vec3(0.16, 0.07, 0.05),
	vec3(0.33, 0.30, 0.29), vec3(0.28, 0.26, 0.25), vec3(0.38, 0.35, 0.33), vec3(0.24, 0.22, 0.22),
	vec3(0.33, 0.26, 0.17), vec3(0.28, 0.22, 0.15), vec3(0.38, 0.30, 0.20), vec3(0.24, 0.19, 0.13),
	vec3(0.45, 0.45, 0.43), vec3(0.39, 0.40, 0.38), vec3(0.30, 0.44, 0.22), vec3(0.34, 0.35, 0.33),
	vec3(0.72, 0.66, 0.52), vec3(0.66, 0.60, 0.47), vec3(0.78, 0.72, 0.58), vec3(0.60, 0.54, 0.42),
	vec3(0.50, 0.36, 0.22), vec3(0.44, 0.31, 0.19), vec3(0.56, 0.41, 0.26), vec3(0.40, 0.28, 0.17)
);

varying vec3 lp;
varying float top_y;
varying float mat_f;
varying vec3 ln;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	lp = VERTEX;
	top_y = UV.x;
	mat_f = COLOR.r;
	ln = NORMAL;
}

void fragment() {
	int m = clamp(int(mat_f * 16.0), 0, NM - 1);
	vec3 wn = ln;
	bool is_top = wn.y > 0.5;
	vec2 p = is_top ? lp.xz : (abs(wn.x) > 0.5 ? vec2(lp.z, lp.y) : vec2(lp.x, lp.y));
	vec2 pp = p * px_per_m;
	vec2 pix = floor(pp);
	float r = h21(pix + float(m) * 17.0 + (is_top ? 0.0 : 91.0));
	vec2 blk = floor(p * 2.0);
	float rb = h21(blk * 1.7 + 3.1 + float(m));
	// la teinte : un pixel au hasard, des plaques par bloc
	float pick = clamp(r * 0.75 + rb * 0.45 - 0.1, 0.0, 0.999);
	int k = int(pick * 4.0);
	vec3 c;
	vec3 avg;
	bool herbeux = (m == 1 || m == 2 || m == 9 || m == 11);
	if (is_top) {
		c = TOP[m * 4 + k];
		avg = (TOP[m * 4] + TOP[m * 4 + 1] + TOP[m * 4 + 2] + TOP[m * 4 + 3]) * 0.25;
		// des fleurs-pixels dans la prairie, des cailloux dans le sable
		if (m == 11 && r > 0.985) { c = (rb > 0.5) ? vec3(0.95, 0.85, 0.25) : vec3(0.95, 0.95, 0.92); }
		if (m == 1 && r > 0.993) { c = vec3(0.9, 0.35, 0.5); }
		if (m == 0 && r > 0.98) { c = vec3(0.6, 0.56, 0.48); }
	} else {
		c = SIDE[m * 4 + k];
		avg = (SIDE[m * 4] + SIDE[m * 4 + 1] + SIDE[m * 4 + 2] + SIDE[m * 4 + 3]) * 0.25;
		if (herbeux) {
			// la frange d'herbe : 2 à 4 pixels sous le haut de la colonne, irrégulière
			float fr = (2.0 + floor(h21(vec2(pix.x, 7.0) + float(m)) * 3.0)) / px_per_m;
			if (top_y - lp.y < fr) {
				c = TOP[m * 4 + k] * 0.92;
				avg = mix(avg, TOP[m * 4 + 1], 0.5);
			}
		}
	}
	// le liseré des blocs (un pixel plus sombre)
	// la roche des falaises : des strates (des bandes plus claires ou plus sombres)
	if (!is_top && (m == 4 || m == 9)) {
		c *= 0.86 + 0.26 * h21(vec2(floor(lp.y * 3.0), 17.0 + floor(p.x * 0.25)));
	}
	vec2 inb = fract(p * 2.0);
	float edge = min(min(inb.x, 1.0 - inb.x), min(inb.y, 1.0 - inb.y));
	float lis = 1.0 - 0.13 * step(edge, 1.0 / (px_per_m * 0.5) * 0.5);
	c *= lis;
	// de loin : les pixels se fondent (pas de scintillement)
	vec2 fw = fwidth(pp);
	float near = clamp(1.6 - max(fw.x, fw.y), 0.0, 1.0);
	c = mix(avg * 0.97, c, near);
	ALBEDO = c;
	ROUGHNESS = (m == 5) ? 0.55 : ((m == 0 || m == 7) ? 0.95 : 0.88);
	SPECULAR = 0.35;
	if (m == 6) {
		// la lave : elle coule et brille
		float t = TIME * 0.35;
		float f = h21(floor(pp * 0.5 + vec2(t * 3.0, t * 1.7)));
		float g = h21(floor(pp * 0.25 - vec2(t * 1.3, t * 2.1)) + 5.0);
		vec3 hot = mix(TOP[24], TOP[26], step(0.72, f * 0.6 + g * 0.5));
		hot = mix(hot, TOP[27], step(0.8, g));
		ALBEDO = hot * 0.3;
		EMISSION = (is_top ? hot : c) * (is_top ? 3.2 : 0.6);
		ROUGHNESS = 0.6;
	}
}

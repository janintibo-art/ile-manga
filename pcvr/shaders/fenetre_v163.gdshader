// V163 : les fenêtres de Port-Azur, en profondeur. Une seule plaque (le quad de la fenêtre, azur_kit_v56.window)
// dessine : le dormant et les deux vantaux peints, le battement du milieu, les petits bois (trois ou
// quatre carreaux par vantail, l'allège pleine d'une porte-fenêtre), le mastic ; derrière le verre, une
// vraie pièce provençale (« interior mapping ») : les murs passés à la chaux de leur couleur, les poutres du
// plafond et la suspension, les tomettes ou le parquet, un buffet, un tableau, une porte, une table à
// mi-profondeur ; des rideaux (un voilage, des doubles rideaux, un brise-bise). La vitre reflète vraiment
// le ciel (le moteur) ; la nuit, les pièces des fenêtres allumées s'éclairent (glow : temps_v56).
// La taille de la fenêtre et son repère sont retrouvés à partir des dérivées (dFdx, dFdy) : pas de
// tangentes à fournir. UV : u = 0 à gauche vu de dehors, v = 0 en haut.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float glow = 0.0;
uniform vec4 cadre : source_color = vec4(0.93, 0.91, 0.86, 1.0);

varying vec3 wpos;
varying vec3 wnrm;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float rect(vec2 p, vec4 r) {
	return step(r.x, p.x) * step(p.x, r.z) * step(r.y, p.y) * step(p.y, r.w);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// La pièce derrière la vitre. p0 : le point d'entrée (x le long du mur, y au-dessus du plancher, z = 0) ;
// rd : le regard (z vers le fond) ; dim : largeur, hauteur, profondeur ; r : le hasard. Rend la couleur
// (rgb) et l'éclairage de la lampe (a).
vec4 piece(vec3 p0, vec3 rd, vec3 dim, vec4 r) {
	vec3 ird = 1.0 / max(abs(rd), vec3(0.0001));
	float tx = (rd.x > 0.0 ? dim.x - p0.x : p0.x) * ird.x;
	float ty = (rd.y > 0.0 ? dim.y - p0.y : p0.y) * ird.y;
	float tz = dim.z * ird.z;
	float t = min(min(tx, ty), tz);
	vec3 h = p0 + rd * t;
	// les murs à la chaux : crème, jaune pâle, bleu lavande, vert sauge, rose
	vec3 murs[5] = vec3[5](vec3(0.9, 0.85, 0.74), vec3(0.93, 0.84, 0.6), vec3(0.7, 0.76, 0.84), vec3(0.72, 0.78, 0.66), vec3(0.9, 0.74, 0.68));
	vec3 mur = murs[int(r.x * 4.99)];
	bool tomettes = r.y < 0.62;
	vec3 bois = mix(vec3(0.3, 0.19, 0.11), vec3(0.5, 0.36, 0.22), r.w);
	vec3 col = mur;
	float lumiere = 0.0;
	if (t == tz) {
		vec2 b = h.xy;
		// un buffet bas, ou une armoire ; un tableau ; une petite lampe
		float buffet = rect(b, vec4(0.5 + r.z * 0.6, 0.0, 1.9 + r.z * 0.6, 0.95)) * step(0.35, r.z);
		float armoire = rect(b, vec4(dim.x - 1.5, 0.0, dim.x - 0.4, 2.05)) * step(r.z, 0.35);
		float tiroir = step(0.9, fract(b.y * 3.3)) * buffet;
		col = mix(col, bois * (1.0 - 0.3 * tiroir), clamp(buffet + armoire, 0.0, 1.0));
		col = mix(col, bois * 0.7, rect(b, vec4(dim.x - 0.97, 0.05, dim.x - 0.93, 1.95)) * armoire);
		vec3 vif = 0.45 + 0.4 * cos(6.2831 * (r.w + vec3(0.0, 0.33, 0.67)));
		vec4 tab = vec4(0.7 + r.w * 0.8, 1.35, 1.5 + r.w * 0.8, 1.95);
		float cadre_t = rect(b, tab + vec4(-0.05, -0.05, 0.05, 0.05)) * (1.0 - rect(b, tab));
		float toile = rect(b, tab);
		float paysage = smoothstep(0.0, 0.02, b.y - (tab.y + 0.25 + 0.08 * sin(b.x * 9.0 + r.z * 5.0)));
		col = mix(col, vec3(0.62, 0.48, 0.22), cadre_t * (1.0 - armoire));
		col = mix(col, mix(vif * 0.7, vec3(0.55, 0.72, 0.85), paysage), toile * (1.0 - armoire));
		float lampe = rect(b, vec4(1.1 + r.z * 0.6, 0.95, 1.2 + r.z * 0.6, 1.35)) * buffet;
		float abat = rect(b, vec4(1.0 + r.z * 0.6, 1.3, 1.3 + r.z * 0.6, 1.5)) * buffet;
		col = mix(col, vec3(0.2), lampe);
		col = mix(col, vec3(0.95, 0.88, 0.7), abat);
		lumiere += abat * 1.5;
		col *= 0.92;
	} else if (t == ty) {
		if (rd.y > 0.0) {
			// le plafond blanc, les poutres sombres, la suspension
			col = vec3(0.9, 0.88, 0.84);
			float poutre = step(0.78, fract(h.x / 0.65 + r.z));
			col = mix(col, bois * 0.8, poutre);
			vec2 lp = vec2(h.x - dim.x * 0.5, h.z - dim.z * 0.5);
			float susp = step(length(lp), 0.22);
			col = mix(col, vec3(0.97, 0.9, 0.75), susp);
			lumiere += susp * 2.0;
			col *= 0.85;
		} else {
			// les tomettes (rouges, en hexagones) ou un vieux parquet ; un tapis
			if (tomettes) {
				vec2 g = h.xz * vec2(5.0, 5.77);
				vec2 gi = floor(g + vec2(0.5 * mod(floor(g.y), 2.0), 0.0));
				vec2 gf = fract(g + vec2(0.5 * mod(floor(g.y), 2.0), 0.0));
				float j = step(0.92, max(gf.x, gf.y)) + step(max(gf.x, gf.y), 0.06);
				col = mix(vec3(0.62, 0.3, 0.18), vec3(0.72, 0.42, 0.26), h2(gi + r.xy * 9.0));
				col = mix(col, vec3(0.5, 0.45, 0.4), clamp(j, 0.0, 1.0));
			} else {
				col = bois * (1.15 + 0.15 * step(0.5, fract(h.x * 6.0))) * (0.9 + 0.2 * h2(vec2(floor(h.x * 6.0), floor(h.z * 1.5))));
			}
			vec3 tapis = 0.4 + 0.3 * cos(6.2831 * (r.z + vec3(0.0, 0.25, 0.5)));
			col = mix(col, tapis, rect(h.xz, vec4(0.7, 0.9, dim.x - 0.7, dim.z - 1.0)) * step(0.45, r.w));
		}
	} else {
		// les murs de côté, un peu plus sombres ; une porte, parfois
		col = mur * 0.86;
		float porte = rect(vec2(h.z, h.y), vec4(dim.z - 1.5, 0.0, dim.z - 0.65, 2.1)) * step(0.5, r.y);
		col = mix(col, bois * 1.2, porte);
	}
	// le fond s'assombrit (la lumière du jour vient de la fenêtre)
	float prof = clamp(h.z / dim.z, 0.0, 1.0);
	col *= mix(1.0, 0.55, prof);
	// à mi-profondeur : une table, deux chaises (ou une plante)
	float zm = dim.z * 0.45;
	float tm = zm * ird.z;
	if (tm < t) {
		vec2 m = (p0 + rd * tm).xy;
		float cx = dim.x * (0.35 + 0.3 * r.z);
		float dessus = rect(m, vec4(cx - 0.6, 0.72, cx + 0.6, 0.77));
		float pieds = rect(m, vec4(cx - 0.55, 0.0, cx - 0.5, 0.72)) + rect(m, vec4(cx + 0.5, 0.0, cx + 0.55, 0.72));
		float nappe = rect(m, vec4(cx - 0.63, 0.5, cx + 0.63, 0.77)) * step(0.5, r.x);
		float chaise = rect(m, vec4(cx + 0.75, 0.0, cx + 0.79, 0.95)) + rect(m, vec4(cx + 0.75, 0.43, cx + 1.15, 0.47)) + rect(m, vec4(cx + 1.11, 0.0, cx + 1.15, 0.45));
		vec2 vp = m - vec2(cx, 0.95);
		float bouquet = step(length(vp * vec2(1.0, 1.2)), 0.13) * step(0.3, r.w);
		float a = clamp(dessus + pieds + nappe + chaise + bouquet, 0.0, 1.0);
		vec3 mc = bois * 0.9;
		mc = mix(mc, vec3(0.86, 0.84, 0.78) * (0.9 + 0.1 * step(0.5, fract(m.x * 8.0))), nappe);
		mc = mix(mc, vec3(0.85, 0.3, 0.4) * (0.7 + 0.5 * h2(floor(m * 30.0))), bouquet);
		col = mix(col, mc * 0.8, a);
	}
	return vec4(col, lumiere);
}

void fragment() {
	// la taille de la fenêtre d'après les dérivées (arrondie à 5 cm : les tailles du kit), son repère
	// d'après la normale (les fenêtres sont verticales : la droite est horizontale) ; ainsi le coin de la
	// fenêtre, et son hasard, ne tremblent pas d'un pixel à l'autre
	vec3 dpx = dFdx(wpos);
	vec3 dpy = dFdy(wpos);
	vec2 dux = dFdx(UV);
	vec2 duy = dFdy(UV);
	float det = dux.x * duy.y - duy.x * dux.y;
	vec3 N = normalize(wnrm);
	vec3 R = cross(vec3(0.0, 1.0, 0.0), N);
	R = length(R) > 0.01 ? normalize(R) : vec3(1.0, 0.0, 0.0);    // la droite, vu de dehors
	vec3 U = vec3(0.0, 1.0, 0.0);
	float W = 0.95;
	float H = 1.4;
	if (abs(det) > 1e-14) {
		vec3 dpdu = (dpx * duy.y - dpy * dux.y) / det;
		vec3 dpdv = (dpy * dux.x - dpx * duy.x) / det;
		W = round(clamp(length(dpdu), 0.2, 4.0) * 20.0) / 20.0;
		H = round(clamp(length(dpdv), 0.2, 4.0) * 20.0) / 20.0;
	}
	float lx = UV.x * W;
	float ly = (1.0 - UV.y) * H;
	vec3 coin = floor((wpos - R * lx - U * ly) * 4.0 + 0.5);
	vec4 rnd = vec4(h3(coin), h3(coin + 3.1), h3(coin + 7.7), h3(coin + 13.3));
	bool porte_f = H > 1.8;
	// --- la menuiserie
	float f0 = 0.06;
	float fb = 0.035;          // la moitié du battement
	float fv = 0.045;          // le cadre des vantaux
	float pb = 0.012;          // la moitié d'un petit bois
	int rangs = clamp(int(round((H - 2.0 * f0) / 0.42)), 2, 5);
	float bord = min(min(lx, W - lx), min(ly, H - ly));
	float dorm = step(bord, f0);
	float mx = abs(lx - W * 0.5);
	float batt = step(mx, fb);
	// la position dans un vantail
	float vx0 = lx < W * 0.5 ? f0 : W * 0.5 + fb;
	float vx1 = lx < W * 0.5 ? W * 0.5 - fb : W - f0;
	float vl = min(min(lx - vx0, vx1 - lx), min(ly - f0, H - f0 - ly));
	float vant = step(vl, fv) * (1.0 - dorm) * (1.0 - batt);
	float allege = 0.0;
	float y_bas = f0 + fv;
	if (porte_f) {
		allege = step(ly, 0.48) * (1.0 - dorm) * (1.0 - batt);
		y_bas = 0.48 + 0.03;
	}
	float hv = (H - f0 - fv) - y_bas;
	float py = (ly - y_bas) / max(hv, 0.01) * float(rangs);
	float petit = step(abs(fract(py + 0.5) - 0.5) * hv / float(rangs), pb) * step(0.5, py) * step(py, float(rangs) - 0.5);
	float bois = clamp(dorm + batt + vant + allege + petit, 0.0, 1.0);
	// --- derrière le verre
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 V = normalize(wpos - cam);
	// le verre ancien, un peu ondulé
	vec2 ond = vec2(bruit(vec2(lx, ly) * 7.0 + rnd.xy * 20.0), bruit(vec2(lx, ly) * 7.0 + 4.0)) - 0.5;
	vec3 rd = normalize(vec3(dot(V, R), dot(V, U), dot(V, -N)) + vec3(ond * 0.035, 0.0));
	rd.z = max(rd.z, 0.02);
	float allege_y = porte_f ? 0.0 : 0.9;
	vec3 dim = vec3(W + 2.2 + rnd.y * 1.5, 2.75, 3.4 + rnd.z * 1.6);
	vec3 p0 = vec3(lx + (dim.x - W) * 0.5, ly + allege_y, 0.0);
	vec4 pc = piece(p0, rd, dim, rnd);
	vec3 interieur = pc.rgb;
	// les rideaux : un voilage, des doubles rideaux, un brise-bise
	int genre = int(rnd.w * 5.99);
	vec3 voile = vec3(0.92, 0.91, 0.87);
	float plis = 0.75 + 0.25 * sin(lx * 55.0 + sin(ly * 3.0) * 0.6);
	if (genre == 1) {
		interieur = mix(interieur, voile * plis, 0.62);
	} else if (genre == 2) {
		vec3 tissu = 0.42 + 0.32 * cos(6.2831 * (rnd.x + vec3(0.0, 0.3, 0.6)));
		float cote = 1.0 - step(W * 0.24, lx) * step(lx, W * 0.76);
		interieur = mix(interieur, tissu * plis * 0.8, cote);
	} else if (genre == 3) {
		float bas = step(ly, H * 0.45) * step(f0, ly);
		vec3 vichy = mix(vec3(0.9, 0.88, 0.84), vec3(0.75, 0.2, 0.18), step(0.5, fract(lx * 9.0)) * 0.5 + step(0.5, fract(ly * 9.0)) * 0.5);
		interieur = mix(interieur, vichy * plis, bas * 0.9);
	}
	// le mastic : une ombre fine contre le bois
	float ombre = 0.0;
	ombre = max(ombre, step(bord, f0 + 0.012) * (1.0 - dorm));
	ombre = max(ombre, step(mx, fb + 0.01) * (1.0 - batt));
	interieur *= 1.0 - 0.45 * ombre;
	// la peinture du bois : un peu écaillée, plus sale en bas
	vec3 peint = cadre.rgb * (0.95 + 0.08 * rnd.x);
	float ecaille = smoothstep(0.8, 0.83, bruit(vec2(lx, ly) * 30.0 + rnd.zw * 40.0)) * step(0.7, rnd.y);
	peint = mix(peint, vec3(0.64, 0.6, 0.52), ecaille);
	peint *= 1.0 - 0.15 * smoothstep(0.3, 0.0, ly);
	// les arêtes du bois (un peu d'ombre et de lumière)
	float arete = smoothstep(0.012, 0.0, abs(bord - f0)) + smoothstep(0.008, 0.0, abs(mx - fb));
	peint *= 1.0 - 0.18 * clamp(arete, 0.0, 1.0);
	float lampe = glow * (0.55 + 0.45 * rnd.y);
	ALBEDO = mix(interieur * 0.42, peint, bois);
	ROUGHNESS = mix(0.04, 0.55, bois);
	METALLIC = 0.0;
	SPECULAR = mix(0.5, 0.45, bois);
	vec3 chaud = vec3(1.0, 0.74, 0.46);
	EMISSION = (1.0 - bois) * lampe * (pc.rgb * chaud * (0.55 + pc.a * 0.8)) * 0.7;
}

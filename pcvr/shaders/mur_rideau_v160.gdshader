// V160 : le mur-rideau des tours (la Cité des Nuées, le Dôme d'Azur), en haute définition. Il remplace la
// texture peinte (facade.png) : les montants d'aluminium (arrondis, avec leur reflet), les traverses, les
// allèges de verre émaillé, le nez de dalle blanc ; et derrière chaque vitre, une vraie pièce, en
// profondeur (« interior mapping », comme les tours de Néopolis) : des bureaux, des appartements, des
// jardins d'hiver, des salles de réunion, avec leurs meubles à mi-profondeur, des stores baissés, des
// voilages. La vitre reflète le ciel (chacune un peu de travers, comme les vraies) ; le soir, les pièces
// s'allument. Au loin, les pièces se fondent en une couleur moyenne (pas de scintillement).
// Les UV sont ceux du kit (nuees_kit_v113.facade_panel) : u = 1 pour 6 m, v = 1 pour 7,2 m (deux étages),
// v = 0 en haut (le plancher) ; u croît vers la droite, vu de dehors.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float nuit : hint_range(0.0, 1.0) = 0.0;          // 0 le jour, 1 la nuit (le ciel des vitres)
uniform float glow = 0.0;                                  // les lampes des pièces (temps_v56.register_glow)
uniform float lampes_jour : hint_range(0.0, 1.0) = 0.0;   // des lampes allumées même le jour (sous la mer)
uniform float eau : hint_range(0.0, 1.0) = 0.0;           // 1 : sous la mer (la vitre reflète l'eau)
uniform float tex_l = 6.0;
uniform float tex_h = 7.2;

varying vec3 wpos;
varying vec3 wnrm;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float h00 = h3(vec3(a, 1.0));
	float h10 = h3(vec3(a + vec2(1.0, 0.0), 1.0));
	float h01 = h3(vec3(a + vec2(0.0, 1.0), 1.0));
	float h11 = h3(vec3(a + vec2(1.0, 1.0), 1.0));
	return mix(mix(h00, h10, f.x), mix(h01, h11, f.x), f.y);
}

// 1 dans le rectangle (x0, y0, x1, y1)
float rect(vec2 p, vec4 r) {
	return step(r.x, p.x) * step(p.x, r.z) * step(r.y, p.y) * step(p.y, r.w);
}

// Le ciel (ou la mer) dans la vitre, dans la direction R
vec3 ciel(vec3 R) {
	float y = R.y;
	vec3 haut = mix(vec3(0.3, 0.48, 0.74), vec3(0.012, 0.02, 0.05), nuit);
	vec3 horiz = mix(vec3(0.74, 0.82, 0.9), vec3(0.05, 0.06, 0.1), nuit);
	vec3 bas = mix(vec3(0.3, 0.33, 0.32), vec3(0.015, 0.018, 0.02), nuit);
	vec3 c = y > 0.0 ? mix(horiz, haut, sqrt(clamp(y, 0.0, 1.0))) : mix(horiz, bas, clamp(-y * 5.0, 0.0, 1.0));
	if (y > 0.02) {
		// des nuages, qui glissent dans la vitre quand on bouge
		vec2 q = R.xz / (y + 0.15) * 1.6;
		float nu = bruit(q) * 0.6 + bruit(q * 2.3 + 4.0) * 0.4;
		c = mix(c, mix(vec3(0.97, 0.98, 1.0), vec3(0.07, 0.08, 0.11), nuit), smoothstep(0.5, 0.82, nu) * 0.75 * clamp(y * 3.0, 0.0, 1.0));
	}
	vec3 mer = mix(vec3(0.05, 0.3, 0.38), vec3(0.01, 0.05, 0.09), nuit) * (0.6 + 0.6 * clamp(y + 0.3, 0.0, 1.0));
	return mix(c, mer, eau);
}

// Une pièce derrière la vitre. p0 : le point de la vitre dans la pièce (x le long du mur, y au-dessus du
// sol, z = 0) ; rd : le regard (z vers le fond) ; dim : la pièce (largeur, hauteur, profondeur) ; r : quatre
// nombres au hasard ; lampe, jour : la lumière. Rend la couleur vue.
vec3 piece(vec3 p0, vec3 rd, vec3 dim, vec4 r, float lampe, float jour) {
	vec3 ird = 1.0 / max(abs(rd), vec3(0.0001));
	float tx = (rd.x > 0.0 ? dim.x - p0.x : p0.x) * ird.x;
	float ty = (rd.y > 0.0 ? dim.y - p0.y : p0.y) * ird.y;
	float tz = dim.z * ird.z;
	float t = min(min(tx, ty), tz);
	vec3 h = p0 + rd * t;
	bool bureau = r.x < 0.4;
	bool appart = r.x >= 0.4 && r.x < 0.74;
	bool jardin = r.x >= 0.74 && r.x < 0.87;
	vec3 mur = bureau ? mix(vec3(0.86, 0.87, 0.88), vec3(0.7, 0.75, 0.8), r.y) : (appart ? mix(vec3(0.9, 0.84, 0.74), mix(vec3(0.62, 0.72, 0.68), vec3(0.84, 0.7, 0.64), r.z), r.y * 0.7) : vec3(0.88, 0.89, 0.87));
	vec3 vif = 0.5 + 0.42 * cos(6.2831 * (r.z + vec3(0.0, 0.33, 0.67)));
	vec3 vert = mix(vec3(0.1, 0.27, 0.08), vec3(0.24, 0.4, 0.12), r.w);
	vec3 col = mur;
	vec3 emis = vec3(0.0);
	float face = 0.9;
	if (t == tz) {
		// le mur du fond
		vec2 b = h.xy;
		if (bureau) {
			col = mix(col, vec3(0.93, 0.93, 0.91), rect(b, vec4(0.15, 0.0, dim.x - 0.15, 0.95)) * step(0.45, r.w));
			col = mix(col, vec3(0.97), rect(b, vec4(0.4 + r.z * 0.8, 1.2, 1.5 + r.z * 0.8, 2.0)));
		} else if (appart) {
			float bib = rect(b, vec4(dim.x - 1.2, 0.0, dim.x - 0.15, 2.2)) * step(0.5, r.w);
			float rayon = step(0.85, fract(b.y * 2.6));
			vec3 livres = 0.32 + 0.3 * cos(6.2831 * (h3(vec3(floor(b.x * 14.0), floor(b.y * 2.6), r.z * 50.0)) + vec3(0.0, 0.3, 0.6)));
			col = mix(col, mix(livres, vec3(0.45, 0.32, 0.22), rayon), bib);
			float tab = rect(b, vec4(0.5, 1.25, 1.4, 1.9)) * (1.0 - bib);
			col = mix(col, vec3(0.92), rect(b, vec4(0.45, 1.2, 1.45, 1.95)) * (1.0 - bib));
			col = mix(col, vif * 0.85, tab);
		} else if (jardin) {
			float f = bruit(b * 7.0 + r.z * 20.0) * 0.6 + bruit(b * 19.0) * 0.4;
			col = mix(vert * 0.6, vert * 1.5, f);
		} else {
			float ecran = rect(b, vec4(0.7, 1.0, 2.3, 1.9));
			col = mix(col, vec3(0.03), ecran);
			emis += vec3(0.2, 0.35, 0.6) * ecran * (0.2 + lampe * 0.8);
		}
		face = 0.85;
	} else if (t == ty) {
		if (rd.y > 0.0) {
			// le plafond et ses luminaires
			col = vec3(0.86, 0.86, 0.85);
			vec2 lp = vec2(h.x - dim.x * 0.5, h.z - dim.z * 0.5);
			float lum = appart || jardin ? step(length(lp), 0.2) : step(abs(lp.x), dim.x * 0.32) * step(0.38, fract(h.z / 1.2)) * step(fract(h.z / 1.2), 0.62);
			col = mix(col, vec3(0.96), lum);
			emis += vec3(1.0, 0.92, 0.8) * lum * lampe * 2.2;
			face = 0.6;
		} else {
			// le sol : la moquette, le parquet, la pierre
			col = bureau ? vec3(0.34, 0.37, 0.42) : (appart ? mix(vec3(0.5, 0.34, 0.2), vec3(0.62, 0.5, 0.36), r.y) * (0.9 + 0.1 * step(0.5, fract(h.x * 5.0))) : vec3(0.58, 0.56, 0.52));
			if (appart) {
				col = mix(col, vif * 0.55, rect(h.xz, vec4(0.6, 0.8, dim.x - 0.6, 2.6)) * step(0.3, r.w));
			}
			face = 1.0;
		}
	} else {
		// les murs de côté : une porte, parfois
		col = mur * 0.92;
		float porte = rect(vec2(h.z, h.y), vec4(dim.z - 1.6, 0.0, dim.z - 0.7, 2.1)) * step(0.5, r.y);
		col = mix(col, bureau ? vec3(0.75, 0.77, 0.8) : vec3(0.55, 0.4, 0.28), porte);
	}
	float prof = h.z / dim.z;
	vec3 ph = h;
	// le milieu de la pièce : un plan à mi-profondeur (les bureaux, une table, des plantes)
	float zm = dim.z * (appart ? 0.5 : 0.42);
	float tm = zm * ird.z;
	if (tm < t) {
		vec2 m = (p0 + rd * tm).xy;
		vec3 mc = vec3(0.0);
		float a = 0.0;
		if (bureau) {
			float dessus = rect(m, vec4(0.2, 0.7, dim.x - 0.2, 0.76));
			float panneau = rect(m, vec4(0.25, 0.32, dim.x - 0.25, 0.7));
			float pieds = (rect(m, vec4(0.25, 0.0, 0.3, 0.32)) + rect(m, vec4(dim.x - 0.3, 0.0, dim.x - 0.25, 0.32)));
			float ecrans = rect(m, vec4(0.55, 0.84, 1.15, 1.2)) + rect(m, vec4(1.85, 0.84, 2.45, 1.2)) * step(0.3, r.z);
			float pied_e = rect(m, vec4(0.82, 0.76, 0.88, 0.84)) + rect(m, vec4(2.12, 0.76, 2.18, 0.84)) * step(0.3, r.z);
			mc = vec3(0.88, 0.88, 0.86) * dessus + vec3(0.42, 0.44, 0.47) * panneau + vec3(0.25) * pieds + vec3(0.06) * clamp(ecrans + pied_e, 0.0, 1.0);
			a = clamp(dessus + panneau + pieds + ecrans + pied_e, 0.0, 1.0);
		} else if (appart) {
			float dessus = rect(m, vec4(0.7, 0.72, 2.1, 0.77));
			float pieds = rect(m, vec4(0.75, 0.0, 0.8, 0.72)) + rect(m, vec4(2.0, 0.0, 2.05, 0.72));
			vec2 pc = m - vec2(dim.x - 0.42, 1.05);
			float feuilles = step(length(pc * vec2(1.0, 0.85)), 0.36 + 0.06 * sin(atan(pc.y, pc.x) * 7.0 + r.z * 9.0)) * step(0.0, pc.y + 0.55);
			float pot = rect(m, vec4(dim.x - 0.6, 0.0, dim.x - 0.24, 0.42));
			float pied_l = rect(m, vec4(0.28, 0.0, 0.31, 1.5)) * step(0.4, r.y);
			float abat = rect(m, vec4(0.14, 1.5, 0.45, 1.76)) * step(0.4, r.y);
			vec3 bois = mix(vec3(0.4, 0.26, 0.16), vec3(0.6, 0.46, 0.3), r.w);
			mc = bois * clamp(dessus + pieds, 0.0, 1.0) + vert * (0.8 + 0.4 * bruit(m * 12.0)) * feuilles * (1.0 - pot) + vec3(0.55, 0.3, 0.2) * pot + vec3(0.2) * pied_l + vec3(0.95, 0.9, 0.8) * abat;
			a = clamp(dessus + pieds + feuilles + pot + pied_l + abat, 0.0, 1.0);
			emis += vec3(1.0, 0.8, 0.55) * abat * lampe * 1.6;
		} else if (jardin) {
			float f = bruit(m * 4.0 + r.z * 30.0) * 0.65 + bruit(m * 11.0) * 0.35;
			float haut_p = 1.1 + 0.9 * bruit(vec2(m.x * 1.4 + r.w * 10.0, 3.0));
			a = step(0.42, f) * step(m.y, haut_p);
			mc = mix(vert * 0.7, vert * 1.6, f);
		} else {
			float dessus = rect(m, vec4(0.15, 0.72, dim.x - 0.15, 0.78));
			float fc = fract(m.x / 0.75);
			float chaises = step(0.3, fc) * step(fc, 0.7) * rect(m, vec4(0.0, 0.42, dim.x, 1.02)) * (1.0 - dessus);
			mc = vec3(0.86) * dessus + vec3(0.18, 0.2, 0.24) * chaises;
			a = clamp(dessus + chaises, 0.0, 1.0);
		}
		col = mix(col, mc, a);
		prof = mix(prof, zm / dim.z, a);
		ph = mix(ph, vec3(m, zm), a);
		face = mix(face, 0.9, a);
	}
	vec3 l_jour = vec3(1.0, 1.0, 1.03) * jour * mix(0.64, 0.28, prof);
	// la lampe du plafond : une flaque de lumière au milieu de la pièce, plus sombre dans les coins
	vec3 dl = ph - vec3(dim.x * 0.5, dim.y - 0.05, dim.z * 0.5);
	float pres = 1.7 / (1.0 + 0.3 * dot(dl, dl));
	vec3 l_lampe = (appart ? vec3(1.0, 0.8, 0.56) : vec3(0.95, 0.96, 1.0)) * lampe * pres;
	return col * (l_jour + l_lampe) * face + emis;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	float xm = UV.x * tex_l;
	float ym = UV.y * tex_h;
	float fe = fract(ym / 3.6);
	float hu = (1.0 - fe) * 3.6;                      // au-dessus du plancher de l'étage
	float px = max(fwidth(xm), 0.0005);               // la taille d'un pixel, en mètres
	float py = max(fwidth(ym), 0.0005);
	vec3 n = normalize(wnrm);
	vec3 tg = normalize(cross(vec3(0.0, 1.0, 0.0), n)); // le sens où u croît
	vec3 up = cross(n, tg);
	vec3 rdw = normalize(wpos - INV_VIEW_MATRIX[3].xyz);

	// la pièce : 3 m de large (deux vitres) ; son identité : l'immeuble, l'étage, sa place
	float rw = 3.0;
	float ix = floor(xm / rw);
	vec3 centre = wpos + tg * ((ix + 0.5) * rw - xm) + vec3(0.0, (fe - 0.5) * 3.6, 0.0);
	float bat = h3(vec3(floor(centre.x / 23.0), floor(centre.z / 23.0), 5.3)) * 91.0;
	float fy = floor(centre.y * 0.731 + 0.123);
	vec4 r = vec4(h3(vec3(ix, fy, bat)), h3(vec3(ix, fy, bat + 7.7)), h3(vec3(ix, fy, bat + 13.1)), h3(vec3(ix, fy, bat + 19.9)));
	float jour = (1.0 - nuit) * (1.0 - eau * 0.6);
	float on = step(h3(vec3(ix, fy, bat + 29.3)), 0.56);
	float lampe = max(glow * 0.62, lampes_jour) * on * mix(0.6, 1.15, h3(vec3(ix, fy, bat + 31.0)));

	// les vitres : chacune un peu de travers (le reflet se brise d'une vitre à l'autre)
	float ip = floor(xm / 1.5);
	float hp = h3(vec3(ip, fy, bat + 41.0));
	float hp2 = h3(vec3(ip, fy, bat + 43.0));
	vec3 ng = normalize(n + tg * (hp - 0.5) * 0.035 + up * (hp2 - 0.5) * 0.035);
	vec3 R = reflect(rdw, ng);
	float cv = clamp(dot(-rdw, ng), 0.0, 1.0);
	float F = 0.07 + 0.93 * pow(1.0 - cv, 5.0);
	vec3 refl = ciel(R);

	// les bandes de l'étage (de bas en haut) : l'allège sombre, la traverse, la vitre, la traverse,
	// l'allège émaillée claire, le nez de dalle
	float vis = smoothstep(0.36 - py, 0.36 + py, hu) * (1.0 - smoothstep(2.94 - py, 2.94 + py, hu));
	float al_b = 1.0 - smoothstep(0.3 - py, 0.3 + py, hu);
	float al_h = smoothstep(3.0 - py, 3.0 + py, hu) * (1.0 - smoothstep(3.5 - py, 3.5 + py, hu));
	float dalle = smoothstep(3.5 - py, 3.5 + py, hu);
	float trav = clamp(1.0 - vis - al_b - al_h - dalle, 0.0, 1.0);
	float dx = (fract(xm / 1.5 + 0.5) - 0.5) * 1.5;   // la distance au montant, en mètres (signée)
	float montant = (1.0 - smoothstep(0.03 - px, 0.03 + px, abs(dx))) * (1.0 - dalle);

	// la pièce (seulement derrière la vitre)
	vec3 dedans = vec3(0.0);
	if (vis * (1.0 - montant) > 0.001) {
		vec3 rd = vec3(dot(rdw, tg), dot(rdw, up), dot(rdw, -n));
		vec3 p0 = vec3(xm - ix * rw, hu - 0.3, 0.0);
		vec3 dim = vec3(rw, 2.7, 4.2 + r.y * 1.2);
		dedans = piece(p0, rd, dim, r, lampe, jour);
		vec3 l_tissu = vec3(jour * 0.5) + lampe * 0.6 * vec3(1.0, 0.85, 0.65);
		// les voilages des appartements
		bool appart = r.x >= 0.4 && r.x < 0.74;
		float voile = (appart && r.w > 0.55) ? (1.0 - step(0.38, p0.x) * step(p0.x, rw - 0.38)) : 0.0;
		dedans = mix(dedans, vec3(0.93, 0.91, 0.87) * (0.8 + 0.2 * sin(p0.x * 45.0)) * l_tissu, voile * 0.9);
		// les stores baissés (ici ou là)
		float hs = h3(vec3(ip, fy, bat + 3.0));
		float bas_store = hs < 0.3 ? mix(0.6, 2.4, h3(vec3(ip, fy, bat + 5.0))) : 9.0;
		float store = step(bas_store, p0.y);
		float lame = 0.86 + 0.14 * step(0.5, fract(p0.y / 0.05));
		vec3 c_store = vec3(0.86, 0.86, 0.83) * lame * l_tissu;
		c_store *= 1.0 - 0.6 * step(p0.y, bas_store + 0.04);
		dedans = mix(dedans, c_store, store);
		// au loin : une couleur moyenne
		vec3 moy = vec3(0.58, 0.57, 0.55) * (vec3(jour * 0.42) + lampe * 0.85 * vec3(1.0, 0.88, 0.7));
		dedans = mix(dedans, moy, smoothstep(0.03, 0.12, max(px, py)));
	}

	// les montants : arrondis (la normale tourne sur leurs bords)
	vec3 nm = normalize(n + tg * clamp(dx / 0.03, -1.0, 1.0) * 0.45);
	vec3 nf = normalize(mix(mix(n, ng, vis + al_h + al_b), nm, montant));
	NORMAL = normalize((VIEW_MATRIX * vec4(nf, 0.0)).xyz);

	// les matières : l'aluminium (montants, traverses), le verre (la vitre, les allèges), le béton blanc
	float alu = clamp(montant + trav * (1.0 - montant), 0.0, 1.0);
	float verre = vis * (1.0 - montant);
	float email = (al_h + al_b) * (1.0 - montant);
	float beton = dalle;
	vec3 c_email = al_h > 0.5 ? vec3(0.56, 0.64, 0.7) : vec3(0.16, 0.18, 0.2);
	ALBEDO = vec3(0.74, 0.76, 0.78) * alu + c_email * (1.0 - F) * email + vec3(0.88, 0.88, 0.86) * beton;
	METALLIC = 0.6 * alu;
	ROUGHNESS = 0.3 * alu + 0.05 * verre + 0.12 * email + 0.8 * beton;
	SPECULAR = 0.5 * alu + 0.15 * (verre + email) + 0.5 * beton;
	EMISSION = (dedans * vec3(0.82, 0.9, 0.9) * (1.0 - F) + refl * F) * verre + refl * F * email;
}

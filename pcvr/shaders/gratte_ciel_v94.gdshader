// V94 : les façades des tours de Néopolis. Chaque tour est une boîte (un MultiMesh de cubes) ; ce
// shader y dessine les étages et les fenêtres d'après la taille de la boîte et la hauteur dans le
// monde, sans aucune texture. Quatre façons de bâtir (INSTANCE_CUSTOM.y) :
//   0 : le mur-rideau des tours de bureaux (verre bleu-vert, montants fins, liserés de lumière aux angles)
//   1 : le béton des immeubles d'habitation (fenêtres creusées, balcons sombres)
//   2 : le métal sombre et les bandeaux de fenêtres (les tours des Hauts)
//   3 : les vieux immeubles des Ruelles (petites fenêtres, coulures, climatiseurs)
// Le soir (« nuit »), les fenêtres s'allument une à une, chacune à sa façon (chaude, froide, un peu
// rose) ; au pied des tours, les vitrines des boutiques brillent. Au loin, les fenêtres se fondent
// en une couleur moyenne (pas de scintillement).
// INSTANCE_CUSTOM : x = graine, y = façon (0..3) / 4, z = teinte, w = part des fenêtres allumées.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float nuit : hint_range(0.0, 1.0) = 0.0;
uniform float sol_y = 1.4;

varying vec3 wpos;
varying vec3 lnrm;
varying vec3 taille;
varying vec3 lpos;
varying flat vec4 inst;

float h1(float n) {
	return fract(sin(n) * 43758.5453);
}

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float h00 = fract(sin(dot(a, vec2(127.1, 311.7))) * 43758.5453);
	float h10 = fract(sin(dot(a + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float h01 = fract(sin(dot(a + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float h11 = fract(sin(dot(a + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(h00, h10, f.x), mix(h01, h11, f.x), f.y);
}

vec3 teinte(float h) {
	// du cyan au magenta, en passant par l'ambre
	vec3 a = vec3(0.1, 0.85, 1.0);
	vec3 b = vec3(1.0, 0.2, 0.75);
	vec3 c = vec3(1.0, 0.62, 0.15);
	return h < 0.5 ? mix(a, b, h * 2.0) : mix(b, c, (h - 0.5) * 2.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	lnrm = NORMAL;
	taille = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	lpos = (VERTEX + 0.5) * taille;
	inst = INSTANCE_CUSTOM;
}

void fragment() {
	float seed = inst.x * 97.0;
	int style = int(inst.y * 4.0 + 0.5);
	vec3 tint = teinte(inst.z);
	float base_y = wpos.y - lpos.y;           // le bas de la boîte, dans le monde
	bool au_sol = base_y < sol_y + 0.6;
	vec3 col;
	float rough;
	float metal = 0.0;
	vec3 emit = vec3(0.0);
	if (lnrm.y > 0.5) {
		// le toit : un béton sombre, des dalles, des traînées
		vec2 t = lpos.xz;
		float j = step(0.94, fract(t.x / 4.0)) + step(0.94, fract(t.y / 4.0));
		col = vec3(0.2, 0.2, 0.22) * (0.8 + 0.3 * noise2(t * 0.3 + seed));
		col *= 1.0 - min(j, 1.0) * 0.3;
		rough = 0.85;
	} else if (lnrm.y < -0.5) {
		col = vec3(0.08);
		rough = 0.9;
	} else {
		// la façade : u = la distance au bord, le long du mur ; y = la hauteur depuis le bas
		bool sur_x = abs(lnrm.x) > 0.5;
		float u = sur_x ? lpos.z : lpos.x;
		float largeur = sur_x ? taille.z : taille.x;
		float face = sur_x ? (lnrm.x > 0.0 ? 1.0 : 2.0) : (lnrm.z > 0.0 ? 3.0 : 4.0);
		float y = wpos.y - sol_y;
		float etage = style == 3 ? 3.1 : (style == 2 ? 3.8 : 3.5);
		float colw = style == 0 ? 1.5 : (style == 1 ? 2.6 : (style == 2 ? 3.0 : 2.2));
		// on centre les colonnes sur le mur
		float ncol = max(floor(largeur / colw), 1.0);
		float cw = largeur / ncol;
		float cu = u / cw;
		float cy = y / etage;
		vec2 cell = vec2(fract(cu), fract(cy));
		vec3 cid = vec3(floor(cu), floor(cy), face + seed);
		float hr = h3(cid);
		float hr2 = h3(cid + 17.3);
		// la fenêtre dans sa case (les marges dépendent de la façon de bâtir)
		vec2 mg = style == 0 ? vec2(0.04, 0.08) : (style == 1 ? vec2(0.18, 0.22) : (style == 2 ? vec2(0.0, 0.3) : vec2(0.25, 0.25)));
		float win = step(mg.x, cell.x) * step(cell.x, 1.0 - mg.x) * step(mg.y, cell.y) * step(cell.y, 1.0 - mg.y * 0.6);
		// les murs entre les fenêtres
		vec3 mur;
		float mur_r;
		if (style == 0) {
			mur = vec3(0.32, 0.36, 0.4);
			mur_r = 0.35;
		} else if (style == 1) {
			mur = mix(vec3(0.55, 0.53, 0.5), vec3(0.45, 0.47, 0.5), inst.z) * (0.85 + 0.2 * noise2(vec2(u, y) * 0.4 + seed));
			mur_r = 0.8;
		} else if (style == 2) {
			mur = vec3(0.11, 0.115, 0.13);
			mur_r = 0.4;
		} else {
			mur = mix(vec3(0.42, 0.33, 0.27), vec3(0.36, 0.38, 0.36), inst.z) * (0.7 + 0.4 * noise2(vec2(u * 0.7, y * 0.12) + seed));
			// les coulures sous les fenêtres
			mur *= 1.0 - 0.25 * smoothstep(0.6, 1.0, noise2(vec2(u * 2.0, y * 0.25) + seed)) ;
			mur_r = 0.9;
		}
		// la vitre : elle reflète le ciel (chaque vitre un peu différemment) ; certaines sont allumées le soir
		vec3 verre = style == 0 ? mix(vec3(0.16, 0.26, 0.3), vec3(0.3, 0.4, 0.46), hr2) : (style == 2 ? vec3(0.08, 0.1, 0.12) : vec3(0.1, 0.12, 0.14) * (0.8 + 0.4 * hr2));
		// les montants : le mur-rideau a des vitres en deux, les bandeaux des Hauts des vitres en trois
		float sub = style == 0 ? 2.0 : (style == 2 ? 3.0 : 1.0);
		float mont = sub > 1.0 ? step(1.0 - 0.06, abs(fract(cell.x * sub) - 0.5) * 2.0) : 0.0;
		// la dalle de chaque étage (un trait plus clair, ou plus sombre sur le verre)
		float dalle = step(cell.y, mg.y * 0.45);
		float part = inst.w * (0.05 + 0.95 * nuit);
		float allumee = step(hr, part);
		vec3 lumiere = hr2 < 0.55 ? vec3(1.0, 0.78, 0.52) : (hr2 < 0.85 ? vec3(0.72, 0.86, 1.0) : mix(vec3(1.0, 0.45, 0.85), tint, 0.5));
		// des stores à moitié baissés, un peu de profondeur dans la pièce (le plafond plus clair)
		float store = step(0.7, h3(cid + 3.1)) * smoothstep(0.55, 0.6, cell.y);
		float piece = 0.55 + 0.45 * smoothstep(0.1, 0.9, cell.y) * (1.0 - store * 0.7);
		vec3 e_win = lumiere * allumee * piece * (0.45 + 0.85 * h3(cid + 9.0));
		// au loin : la moyenne (la part de fenêtres, leur lumière moyenne)
		float far = clamp(max(fwidth(cu), fwidth(cy)) * 1.6 - 0.3, 0.0, 1.0);
		float aire = (1.0 - 2.0 * mg.x) * (1.0 - 1.6 * mg.y);
		vec3 vitre = mix(verre, vec3(0.05), mont);
		vec3 col_near = mix(mur, vitre, win * (1.0 - mont * 0.0));
		col_near = mix(col_near, style == 0 || style == 2 ? vec3(0.05, 0.055, 0.06) : mur * 1.25, dalle * (1.0 - win));
		vec3 col_far = mix(mur, verre, aire);
		col = mix(col_near, col_far, far);
		float r_win = style == 0 ? 0.03 : 0.07;
		rough = mix(mix(mur_r, r_win, win * (1.0 - mont)), mix(mur_r, r_win, aire), far);
		metal = mix(win * (1.0 - mont) * (style == 0 ? 0.85 : 0.45), aire * 0.5, far);
		// une vitre allumée ne fait plus miroir (on voit la pièce)
		float vue = allumee * nuit * win * (1.0 - far);
		metal *= 1.0 - vue;
		rough = mix(rough, 0.35, vue);
		emit = mix(e_win * win * (1.0 - mont), vec3(1.0, 0.82, 0.6) * part * aire * 0.5, far) * nuit;
		emit += mix(e_win * win * (1.0 - mont), vec3(0.0), far) * (1.0 - nuit) * 0.08;
		// au pied des tours : une travée de 4 m sur trois est une vitrine, sinon une porte ou un rideau de fer
		if (au_sol && y < 4.6) {
			float bay = floor(u / 4.0);
			float hb = h1(bay * 7.13 + seed);
			float fu = fract(u / 4.0);
			vec3 v_col = mix(vec3(1.0, 0.85, 0.65), tint, 0.35 * h1(bay + seed));
			float cadre = step(0.06, fu) * step(fu, 0.94) * step(0.35, y) * step(y, 3.9);
			if (hb < 0.55) {
				// la vitrine : du verre, et derrière, la boutique éclairée (plus clair en haut)
				float fond = 0.35 + 0.65 * smoothstep(0.4, 3.6, y);
				col = mix(vec3(0.07, 0.07, 0.08), vec3(0.03, 0.035, 0.04), cadre);
				rough = mix(0.45, 0.04, cadre);
				metal = cadre * 0.5;
				emit = v_col * cadre * fond * (0.1 + nuit * 0.85) * (0.6 + 0.4 * h1(bay + seed * 3.0));
			} else if (hb < 0.75) {
				// une porte vitrée, au milieu de la travée
				float porte = step(0.3, fu) * step(fu, 0.7) * step(y, 2.6);
				col = mix(vec3(0.12, 0.12, 0.13), vec3(0.03, 0.035, 0.04), porte);
				rough = mix(0.5, 0.05, porte);
				emit = v_col * porte * (0.05 + nuit * 0.5) * step(0.3, y);
			} else {
				// un rideau de fer baissé (ses lames)
				float lame = 0.75 + 0.25 * step(0.5, fract(y * 6.0));
				col = mix(vec3(0.1, 0.1, 0.11), vec3(0.42, 0.43, 0.45) * lame, cadre);
				rough = 0.55;
				metal = cadre * 0.7;
				emit = vec3(0.0);
			}
			// le bandeau lumineux au-dessus des devantures
			emit += tint * smoothstep(4.05, 4.15, y) * smoothstep(4.5, 4.4, y) * (0.15 + nuit * 1.8);
		}
		// les tours de bureaux et des Hauts : un liseré de lumière aux angles, et en haut
		if (style == 0 || style == 2) {
			float angle = 1.0 - smoothstep(0.12, 0.3, min(u, largeur - u));
			float haut = smoothstep(taille.y - 1.2, taille.y - 0.6, lpos.y) * step(lpos.y, taille.y - 0.2);
			float pulse = 0.75 + 0.25 * sin(TIME * 1.3 + seed);
			emit += tint * max(angle, haut) * (0.2 + nuit * 2.2) * pulse * step(0.35, inst.z + 0.2 * h1(seed));
		}
		// les vieux immeubles : des climatiseurs sous certaines fenêtres
		if (style == 3) {
			float clim = step(0.82, hr2) * step(0.3, cell.x) * step(cell.x, 0.7) * step(0.02, cell.y) * step(cell.y, 0.2);
			col = mix(col, vec3(0.55, 0.56, 0.55), clim);
			emit *= 1.0 - clim;
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = emit;
}

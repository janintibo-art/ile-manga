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
// V157 : en haute définition. Les murs ont leur matière et leur relief (le béton banché des immeubles,
// les briques des Ruelles, le bardage de métal des Hauts) ; les fenêtres ont un cadre, un appui ; et
// derrière chaque vitre, une vraie pièce, en profondeur (« interior mapping ») : le plafond, le sol,
// les murs, un meuble, un tableau, qui bougent avec le regard ; le soir, la lampe du plafond. Au pied
// des tours, derrière les vitrines, la boutique et ses étagères. Le toit : du gravier et du bitume.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float nuit : hint_range(0.0, 1.0) = 0.0;
uniform float sol_y = 1.4;
uniform sampler2D tex_banche : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_banche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_briques : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_briques_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_panneaux : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_panneaux_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_toit : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_toit_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;

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

// Une pièce derrière la vitre : p0 (le point de la vitre dans la pièce, en mètres), rd (le regard, dans le
// repère de la pièce : x le long du mur, y vers le haut, z vers l'intérieur), la taille de la pièce (l, h,
// profondeur). Rend la couleur vue, et dans .w la profondeur atteinte (0..1).
vec4 piece_v157(vec3 p0, vec3 rd, vec3 dim, vec3 cid, bool bureau, bool boutique, float lampe_on) {
	float tx = rd.x > 0.0001 ? (dim.x - p0.x) / rd.x : (rd.x < -0.0001 ? -p0.x / rd.x : 1e6);
	float ty = rd.y > 0.0001 ? (dim.y - p0.y) / rd.y : (rd.y < -0.0001 ? -p0.y / rd.y : 1e6);
	float tz = dim.z / max(rd.z, 0.0001);
	float t = min(min(tx, ty), tz);
	vec3 h = p0 + rd * t;
	float r1 = h3(cid + 11.0);
	float r2 = h3(cid + 12.0);
	float r3 = h3(cid + 13.0);
	vec3 mur = bureau ? mix(vec3(0.82, 0.83, 0.85), vec3(0.62, 0.66, 0.7), r1) : mix(vec3(0.82, 0.76, 0.66), mix(vec3(0.58, 0.68, 0.72), vec3(0.78, 0.6, 0.58), r2), r1 * 0.7);
	vec3 col;
	if (t == tz) {
		// le mur du fond : un meuble en bas, un tableau (ou un écran), une porte parfois
		vec2 b = vec2(h.x / dim.x, h.y / dim.y);
		col = mur;
		if (boutique) {
			// des étagères, chargées de couleurs
			float et = step(0.12, fract(b.y * 6.0)) * step(0.12, b.y) * step(b.y, 0.85);
			float prod = h3(vec3(floor(b.x * 14.0), floor(b.y * 6.0), cid.z));
			vec3 pc = mix(vec3(0.62, 0.6, 0.57), 0.5 + 0.5 * cos(6.2831 * (prod + vec3(0.0, 0.33, 0.67))), 0.4);
			col = mix(vec3(0.3, 0.28, 0.26), pc * 0.9, et * step(0.25, prod));
		} else {
			float meuble = step(b.y, bureau ? 0.3 : 0.28) * step(0.12 + 0.3 * r3, b.x) * step(b.x, 0.62 + 0.3 * r3);
			col = mix(col, bureau ? vec3(0.9, 0.9, 0.88) : mix(vec3(0.25, 0.18, 0.13), vec3(0.4, 0.32, 0.28), r2), meuble);
			float tab = step(0.42, b.y) * step(b.y, 0.66) * step(0.2 + 0.4 * r2, b.x) * step(b.x, 0.4 + 0.4 * r2);
			vec3 tc = bureau ? vec3(0.2, 0.45, 0.8) : 0.5 + 0.5 * cos(6.2831 * (r3 + vec3(0.0, 0.33, 0.67)));
			col = mix(col, tc, tab * step(0.35, r1));
		}
		col *= 0.9;
	} else if (t == ty) {
		if (rd.y > 0.0) {
			// le plafond, et son luminaire
			col = vec3(0.88, 0.88, 0.86);
			vec2 lp = vec2(h.x / dim.x - 0.5, h.z / dim.z - 0.5);
			col += vec3(0.1 + 2.4 * lampe_on) * step(abs(lp.x), bureau ? 0.3 : 0.08) * step(abs(lp.y), bureau ? 0.06 : 0.08);
		} else {
			// le sol : le parquet, la moquette, un tapis
			col = bureau ? vec3(0.32, 0.34, 0.38) : mix(vec3(0.42, 0.28, 0.18), vec3(0.36, 0.36, 0.4), r2);
			float tapis = step(0.25, h.x / dim.x) * step(h.x / dim.x, 0.75) * step(0.3, h.z / dim.z) * step(h.z / dim.z, 0.8);
			col = mix(col, mix(vec3(0.55, 0.15, 0.15), vec3(0.2, 0.3, 0.5), r3), tapis * (bureau ? 0.0 : 0.8));
		}
	} else {
		// les murs de côté (une étagère, parfois)
		col = mur * 0.82;
		if (boutique) {
			float et2 = step(0.12, fract(h.y / dim.y * 6.0)) * step(0.15, h.y / dim.y) * step(h.y / dim.y, 0.85);
			float prod2 = h3(vec3(floor(h.z * 3.0), floor(h.y / dim.y * 6.0), cid.z + 4.0));
			col = mix(col * 0.6, mix(vec3(0.6, 0.58, 0.55), 0.5 + 0.5 * cos(6.2831 * (prod2 + vec3(0.0, 0.33, 0.67))), 0.4) * 0.8, et2 * step(0.3, prod2));
		}
	}
	return vec4(col, clamp(h.z / dim.z, 0.0, 1.0));
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
		col = texture(tex_toit, wpos.xz / 4.0).rgb * (0.75 + 0.3 * noise2(t * 0.3 + seed));
		col *= 1.0 - min(j, 1.0) * 0.3;
		rough = 0.85;
		vec3 tn = texture(tex_toit_n, wpos.xz / 4.0).xyz * 2.0 - 1.0;
		NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(tn.x, 0.0, -tn.y, 0.0)).xyz * 0.6);
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
		// les murs entre les fenêtres : leur matière (V157 : en textures), et le relief de la matière
		vec3 mur;
		float mur_r;
		vec3 mn = vec3(0.0, 0.0, 1.0);
		vec2 muv = vec2(u + seed * 3.7, -y);
		if (style == 0) {
			mur = vec3(0.32, 0.36, 0.4) * (0.75 + 0.5 * texture(tex_panneaux, muv / 3.0).rgb);
			mn = texture(tex_panneaux_n, muv / 3.0).xyz * 2.0 - 1.0;
			mur_r = 0.35;
		} else if (style == 1) {
			mur = mix(vec3(1.0, 0.97, 0.92), vec3(0.85, 0.9, 0.98), inst.z) * texture(tex_banche, muv / 5.0).rgb * 1.05;
			mn = texture(tex_banche_n, muv / 5.0).xyz * 2.0 - 1.0;
			mur_r = 0.8;
		} else if (style == 2) {
			mur = texture(tex_panneaux, muv / 3.0).rgb * 0.45;
			mn = texture(tex_panneaux_n, muv / 3.0).xyz * 2.0 - 1.0;
			mur_r = 0.4;
		} else {
			bool brique = inst.z < 0.6;
			mur = brique ? texture(tex_briques, muv / 2.0).rgb * mix(vec3(0.95, 0.9, 0.88), vec3(0.75, 0.7, 0.68), inst.z) : texture(tex_banche, muv / 5.0).rgb * mix(vec3(0.9, 0.82, 0.72), vec3(0.8, 0.86, 0.82), inst.z);
			mn = (brique ? texture(tex_briques_n, muv / 2.0).xyz : texture(tex_banche_n, muv / 5.0).xyz) * 2.0 - 1.0;
			mur *= 0.75 + 0.35 * noise2(vec2(u * 0.7, y * 0.12) + seed);
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
		// V157 : la pièce derrière la vitre (de près seulement)
		vec3 au = sur_x ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
		vec3 wn = sur_x ? vec3(sign(lnrm.x), 0.0, 0.0) : vec3(0.0, 0.0, sign(lnrm.z));
		vec3 rdw = normalize(wpos - CAMERA_POSITION_WORLD);
		float fresnel = pow(1.0 - clamp(dot(-rdw, wn), 0.0, 1.0), 4.0);
		vec3 e_piece = vec3(0.0);
		float near_k = 1.0 - clamp(max(fwidth(cu), fwidth(cy)) * 3.0 - 0.2, 0.0, 1.0);
		if (near_k > 0.01 && win > 0.5) {
			vec3 rdl = vec3(dot(rdw, au), rdw.y, dot(rdw, -wn));
			vec4 pc = piece_v157(vec3(cell.x * cw, cell.y * etage, 0.0), rdl, vec3(cw, etage, 3.0 + 2.5 * h3(cid + 5.0)), cid, style == 0 || style == 2, false, allumee * nuit);
			// le jour, la pièce prend la lumière de la fenêtre (plus sombre au fond) ; le soir, celle de sa lampe
			float jour = (1.0 - nuit) * mix(0.42, 0.14, pc.w);   // V161 : plus clair (on voit dedans)
			vec3 lampe = lumiere * allumee * nuit * mix(1.15, 0.6, pc.w) * (0.6 + 0.6 * h3(cid + 9.0));
			e_piece = pc.rgb * (jour + lampe + 0.015) * (1.0 - store * 0.85) * (1.0 - fresnel * 0.85);
			e_piece += vec3(0.75, 0.7, 0.6) * store * (jour * 0.8 + allumee * nuit * 0.35);
			e_piece *= near_k;
			e_win *= 1.0 - near_k;
		}
		// au loin : la moyenne (la part de fenêtres, leur lumière moyenne)
		float far = clamp(max(fwidth(cu), fwidth(cy)) * 1.6 - 0.3, 0.0, 1.0);
		float aire = (1.0 - 2.0 * mg.x) * (1.0 - 1.6 * mg.y);
		vec3 vitre = mix(verre, vec3(0.05), mont);
		// V157 : le cadre de la fenêtre (un profilé sombre), l'appui en dessous
		float ex = min(cell.x - mg.x, 1.0 - mg.x - cell.x) * cw;
		float ey = min(cell.y - mg.y, 1.0 - mg.y * 0.6 - cell.y) * etage;
		float cadre_f = win * (1.0 - step(0.055, min(ex, ey)));
		float appui = (style == 1 || style == 3) ? step(mg.x, cell.x) * step(cell.x, 1.0 - mg.x) * step(mg.y - 0.06 / etage, cell.y) * step(cell.y, mg.y) : 0.0;
		vitre = mix(vitre, vec3(0.06, 0.065, 0.07), cadre_f);
		vec3 col_near = mix(mur, vitre, win * (1.0 - mont * 0.0));
		col_near = mix(col_near, vec3(0.62, 0.6, 0.57), appui);
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
		emit += e_piece * win * (1.0 - mont) * (1.0 - cadre_f) * (1.0 - far);
		// le relief : la matière des murs ; le cadre et l'appui qui ressortent
		float relief = (1.0 - win) * (1.0 - far) * 0.8;
		vec3 pert = au * mn.x * relief + vec3(0.0, 1.0, 0.0) * mn.y * relief;
		pert += vec3(0.0, 1.0, 0.0) * appui * 0.6;
		NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(pert, 0.0)).xyz);
		// au pied des tours : une travée de 4 m sur trois est une vitrine, sinon une porte ou un rideau de fer
		if (au_sol && y < 4.6) {
			float bay = floor(u / 4.0);
			float hb = h1(bay * 7.13 + seed);
			float fu = fract(u / 4.0);
			vec3 v_col = mix(vec3(1.0, 0.85, 0.65), tint, 0.35 * h1(bay + seed));
			float cadre = step(0.06, fu) * step(fu, 0.94) * step(0.35, y) * step(y, 3.9);
			if (hb < 0.55) {
				// la vitrine : du verre, et derrière, la boutique éclairée (V157 : en profondeur, ses étagères)
				col = mix(vec3(0.07, 0.07, 0.08), vec3(0.03, 0.035, 0.04), cadre);
				rough = mix(0.45, 0.04, cadre);
				metal = cadre * 0.5;
				vec3 au2 = abs(lnrm.x) > 0.5 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
				vec3 wn2 = abs(lnrm.x) > 0.5 ? vec3(sign(lnrm.x), 0.0, 0.0) : vec3(0.0, 0.0, sign(lnrm.z));
				vec3 rd2 = normalize(wpos - CAMERA_POSITION_WORLD);
				vec3 rdl2 = vec3(dot(rd2, au2), rd2.y, dot(rd2, -wn2));
				vec4 bq = piece_v157(vec3(fu * 4.0, y, 0.0), rdl2, vec3(4.0, 4.0, 5.5), vec3(bay, 0.0, seed), false, true, 1.0);
				float f2 = pow(1.0 - clamp(dot(-rd2, wn2), 0.0, 1.0), 4.0);
				emit = mix(bq.rgb, bq.rgb * v_col, 0.35) * cadre * mix(1.0, 0.55, bq.w) * (0.3 + nuit * 0.6) * (0.6 + 0.4 * h1(bay + seed * 3.0)) * (1.0 - f2 * 0.8);
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

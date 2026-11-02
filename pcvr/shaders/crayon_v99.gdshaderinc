// V99 : le rendu « coloriage » de l'Île Crayonnée. Tant que le joueur ne lui a pas rendu ses
// couleurs, l'île est une page de cahier de coloriage : du papier blanc, des traits d'encre (les
// contours, les hachures dans l'ombre, les veines des pierres, le bord de chaque feuille, les
// vaguelettes de l'eau). Une carte des couleurs (« crayon_masque », peinte par crayon_v99.gd, vue
// de dessus sur toute l'île) dit, pour chaque endroit, s'il a retrouvé ses couleurs : là, on voit
// la vraie matière (le rendu réaliste habituel), avec un liseré d'aquarelle au bord de la tache.
// Ce fichier est inclus par le sol de l'île (crayon_terrain_v99), par les contours
// (crayon_contour_v99) et, ajouté au vol par crayon_v99.gd, par tous les autres matériaux de l'île.

global uniform sampler2D crayon_masque;
global uniform vec4 crayon_rect;
global uniform vec3 crayon_soleil;
global uniform float crayon_jour;

#ifndef CR_KIND
#define CR_KIND 0
#endif

float cr_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float cr_noise(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cr_hash(a), cr_hash(a + vec2(1.0, 0.0)), f.x),
		mix(cr_hash(a + vec2(0.0, 1.0)), cr_hash(a + vec2(1.0, 1.0)), f.x), f.y);
}

// 0 : la page blanche (le trait seul) ; 1 : en couleurs. Hors de l'île : toujours en couleurs.
// Le bord d'une tache de couleur est irrégulier, comme un lavis.
float cr_couleur(vec3 wp) {
	vec2 uv = (wp.xz - crayon_rect.xy) / crayon_rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 1.0;
	}
	float m = textureLod(crayon_masque, uv, 0.0).r;
	float n = cr_noise(wp.xz * 0.45) * 0.6 + cr_noise(wp.xz * 2.1 + 7.0) * 0.4;
	return smoothstep(0.4, 0.6, m + (n - 0.5) * 0.4);
}

// Le papier : blanc cassé, un grain très léger.
vec3 cr_papier(vec3 wp) {
	float g = cr_noise(wp.xz * 3.1 + wp.y * 1.7) * 0.6 + cr_noise(wp.zx * 11.0 - wp.y) * 0.4;
	return vec3(0.965, 0.957, 0.936) * (0.982 + 0.03 * g);
}

// Des traits réguliers (un tous les 1 de x, épais de w, fraction de la période), nets, sans
// crénelage ; de loin, quand ils deviennent trop serrés, ils se fondent en un gris (leur moyenne).
float cr_trait(float x, float w) {
	float fw = fwidth(x);
	float d = abs(fract(x + 0.5) - 0.5);
	float l = 1.0 - smoothstep(w * 0.5, w * 0.5 + fw, d);
	return mix(l, w * 0.8, smoothstep(0.22, 0.55, fw));
}

// Un trait le long de la ligne où v vaut s, épais de px pixels.
float cr_bord(float v, float s, float px) {
	float fw = max(fwidth(v), 1e-5);
	return 1.0 - smoothstep(px * 0.5, px * 0.5 + 1.0, abs(v - s) / fw);
}

// Les hachures dans l'ombre (par rapport au soleil) : un premier sens dans la pénombre, un deuxième
// (croisé) dans l'ombre franche. Les traits suivent la face la plus proche (projection triplanaire).
float cr_hachures(vec3 wp, vec3 nw, float dens) {
	float sh = 1.0 - clamp(dot(nw, normalize(crayon_soleil)) * 0.5 + 0.5, 0.0, 1.0);
	vec3 an = abs(nw);
	vec2 p = an.y > max(an.x, an.z) ? wp.xz : (an.x > an.z ? wp.zy : wp.xy);
	float wob = cr_noise(p * 0.7) * 0.35;
	float h1 = cr_trait(dot(p, vec2(0.707, 0.707)) * dens + wob, 0.15) * smoothstep(0.52, 0.62, sh);
	float h2 = cr_trait(dot(p, vec2(0.707, -0.707)) * dens + wob, 0.15) * smoothstep(0.7, 0.8, sh);
	return max(h1, h2);
}

// Le contour : là où la surface fuit le regard.
float cr_contour(vec3 nw, vec3 vw) {
	float ndv = abs(dot(nw, vw));
	return 1.0 - smoothstep(0.1, 0.24, ndv);
}

// Les joints des pierres (cellules de Voronoï) : p en mètres / taille d'une pierre.
float cr_pierres(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(cr_hash(i + g), cr_hash(i + g + 19.13)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	float e = d2 - d1;
	float fw = max(fwidth(p.x) + fwidth(p.y), 1e-4);
	float l = 1.0 - smoothstep(fw * 0.7, fw * 1.9, e);
	return l * (1.0 - smoothstep(0.18, 0.4, fw));
}

// Les vaguelettes de l'eau : des traits ondulés, interrompus.
float cr_vagues(vec3 wp, float t) {
	vec2 p = wp.xz;
	float x = p.y * 0.85 + sin(p.x * 0.31 + t * 0.35) * 0.55 + cr_noise(p * 0.12) * 2.2;
	float l = cr_trait(x, 0.11);
	float gate = smoothstep(0.36, 0.5, cr_noise(vec2(p.x * 0.22, floor(x) * 3.7)));
	return l * gate;
}

// L'encre d'un matériau de l'île, selon son genre (CR_KIND) :
// 0 : un objet (contour, hachures) ; 1 : l'eau ; 2 : un feuillage découpé (le bord de chaque
// feuille) ; 3 : l'écorce (de longs traits verticaux) ; 4 : la pierre (ses joints) ; 5 : le bois
// en planches ; 6 : l'herbe et les fleurs (seulement leurs contours) ; 7 : une chute d'eau.
float crayon_encre(vec3 wp, vec3 nw, vec3 vw, vec2 uv, float alpha, float t) {
	float ink = 0.0;
#if CR_KIND == 1
	ink = cr_vagues(wp, t);
	ink = max(ink, cr_contour(nw, vw) * 0.0);
#elif CR_KIND == 7
	// la cascade : de longs traits verticaux, interrompus, qui descendent
	float sv = uv.x * 8.0 + cr_noise(vec2(uv.x * 8.0, 0.5)) * 0.6;
	float gv = smoothstep(0.35, 0.55, cr_noise(vec2(floor(sv) * 3.1, uv.y * 4.0 - t * 1.6)));
	ink = cr_trait(sv, 0.13) * gv;
#elif CR_KIND == 2
	ink = max(cr_hachures(wp, nw, 6.0) * 0.35, cr_bord(alpha, 0.55, 1.1) * 0.7);
	ink = max(ink, cr_contour(nw, vw) * 0.5);
#elif CR_KIND == 3
	float s = uv.x * 9.0 + cr_noise(vec2(uv.x * 9.0, uv.y * 1.3)) * 0.8;
	ink = max(cr_trait(s, 0.1) * smoothstep(0.3, 0.7, cr_noise(vec2(floor(s) * 2.3, uv.y * 0.9))), cr_hachures(wp, nw, 7.0));
	ink = max(ink, cr_contour(nw, vw));
#elif CR_KIND == 4
	vec3 an = abs(nw);
	vec2 p = an.y > max(an.x, an.z) ? wp.xz : (an.x > an.z ? wp.zy : wp.xy);
	ink = max(cr_pierres(p * 2.2) * 0.85, cr_hachures(wp, nw, 7.0));
	ink = max(ink, cr_contour(nw, vw));
#elif CR_KIND == 5
	ink = max(cr_trait(uv.y * 5.0, 0.07), cr_hachures(wp, nw, 7.0));
	ink = max(ink, cr_contour(nw, vw));
#elif CR_KIND == 6
	ink = cr_contour(nw, vw) * 0.5 + cr_hachures(wp, nw, 5.0) * 0.25;
#else
	ink = max(cr_hachures(wp, nw, 7.0), cr_contour(nw, vw));
#endif
	return clamp(ink, 0.0, 1.0);
}

// Le mélange final : la page (papier et encre) ou la vraie couleur, selon la carte des couleurs.
vec3 crayon_melange(vec3 reel, vec3 wp, float encre, out float c) {
	c = cr_couleur(wp);
	vec3 trait = cr_papier(wp) * (1.0 - 0.9 * encre);
	// le liseré d'aquarelle, au bord de la tache de couleur
	float bord = smoothstep(0.0, 0.5, c) * smoothstep(1.0, 0.5, c);
	vec3 col = reel * (1.0 - 0.32 * bord);
	return mix(trait, col, c);
}

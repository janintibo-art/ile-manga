// Extension « Le Château d'Ombrelac » : les toits d'ardoises taillées en écailles. Les UV sont en
// mètres : u le long de l'égout du toit, v le long de la pente (0 en bas). Chaque rang d'ardoises
// est décalé d'une demi-ardoise ; le bas de chaque ardoise est arrondi (l'écaille) ; chaque ardoise
// a sa nuance (bleu-gris, gris-violet, presque noir), un peu de lichen et de mousse sur les plus
// vieilles, et l'ombre de la suivante qui la recouvre. Le grain est procédural (v10).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D grain : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grain_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 teinte : source_color = vec3(0.25, 0.27, 0.31);
uniform vec3 teinte2 : source_color = vec3(0.23, 0.22, 0.26);
uniform float largeur = 0.42;        // largeur d'une ardoise (m)
uniform float rang = 0.30;           // hauteur visible d'un rang (m)
uniform float mousse = 0.6;
uniform float usure = 1.0;

varying vec3 wp;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV;
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float row = floor(uv.y / rang);
	float off = mod(row, 2.0) * 0.5;
	float col = floor(uv.x / largeur + off);
	vec2 id = vec2(col, row);
	// la position dans l'ardoise : x de -1 à 1, y de 0 (bas) à 1 (haut du rang visible)
	float lx = fract(uv.x / largeur + off) * 2.0 - 1.0;
	float ly = fract(uv.y / rang);
	// l'écaille : le bas arrondi (au-dessous de la courbe, c'est l'ardoise du rang d'en dessous)
	float courbe = 0.42 * (1.0 - sqrt(max(0.0, 1.0 - lx * lx)));
	float dans = step(courbe, ly);
	vec2 tid = mix(id + vec2(off > 0.0 ? 0.5 : 0.0, -1.0), id, dans);
	float r1 = h2(tid);
	float r2 = h2(tid + 17.3);
	vec3 base = mix(teinte, teinte2, r1);
	base *= 0.78 + 0.38 * r2;
	// le grain de la pierre
	// (v10) un grain procédural : la texture d'ardoise portait ses propres rangs et des taches de
	// lichen qui, agrandies, faisaient de grandes traînées pâles sur les toits
	vec2 gq = uv * vec2(9.0, 26.0) + tid * 3.1;
	float g = n2(gq) * 0.6 + n2(gq * 2.7) * 0.4;
	float fin = smoothstep(40.0, 6.0, dist);
	base *= 1.0 + (g - 0.5) * 0.22 * fin;
	// un éclat plus clair sur l'arête basse de l'écaille (la tranche de l'ardoise)
	base *= 1.0 + 0.18 * (1.0 - smoothstep(0.0, 0.035, ly - courbe)) * dans * smoothstep(50.0, 8.0, dist);
	// l'ombre portée de l'ardoise du dessus (en haut du rang) et le bord de l'écaille (en bas)
	float ombre = smoothstep(0.75, 1.0, ly) * 0.45 + (1.0 - smoothstep(0.0, 0.07, abs(ly - courbe))) * 0.35;
	base *= 1.0 - ombre * smoothstep(60.0, 8.0, dist);
	// les joints entre deux ardoises du même rang
	base *= mix(1.0, 0.55, (1.0 - smoothstep(0.0, 0.06, 1.0 - abs(lx))) * dans * smoothstep(80.0, 10.0, dist));
	// l'usure : quelques ardoises plus claires, du lichen, de la mousse vers le bas du toit
	// (v10) le lichen pousse par ardoise : quelques ardoises seulement, en petites taches rondes
	// (avant : une grande tache continue qui faisait des traînées pâles, comme de la neige)
	float vieille = step(0.88, h2(tid + 5.1)) * usure;
	vec2 pl = vec2(lx, (ly - 0.5) * 2.0 * rang / largeur * 2.0);
	float tache = smoothstep(0.55, 0.75, n2(pl * 3.0 + tid * 7.0)) * (1.0 - smoothstep(0.6, 1.0, length(pl)));
	float lich = vieille * tache * dans * smoothstep(90.0, 20.0, dist);
	base = mix(base, mix(vec3(0.5, 0.5, 0.4), vec3(0.62, 0.5, 0.26), step(0.5, h2(tid + 9.7))), lich * 0.45);
	// de grandes nuances très douces (les ardoises posées à des époques différentes)
	base *= 0.92 + 0.12 * n2(wp.xz * 0.11 + wp.y * 0.05);
	float m = smoothstep(0.55, 0.8, n2(uv * vec2(0.6, 1.4) + 3.0)) * (1.0 - smoothstep(0.0, 3.0, uv.y)) * mousse;
	base = mix(base, vec3(0.2, 0.27, 0.1), m * 0.8);
	ALBEDO = base;
	ROUGHNESS = mix(0.68, 0.95, m + lich * 0.5) - r2 * 0.12 + (g - 0.5) * 0.1;
	SPECULAR = 0.3;
	// le relief : chaque ardoise est un peu inclinée (le bas se soulève) ; le grain
	float gx = n2(gq + vec2(0.05, 0.0)) - n2(gq);
	float gy = n2(gq + vec2(0.0, 0.05)) - n2(gq);
	float tilt = (ly - 0.5) * 0.5 * dans;
	vec3 nt = normalize(vec3(gx * 1.6 * fin + (r1 - 0.5) * 0.14, gy * 1.6 * fin - tilt + (r2 - 0.5) * 0.08, 1.0));
	NORMAL_MAP = nt * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
}

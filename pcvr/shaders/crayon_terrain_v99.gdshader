// V99 : le sol de l'Île Crayonnée. Deux rendus, mêlés par la carte des couleurs (crayon_v99.gdshaderinc) :
//  - la page de coloriage : le papier, et les traits d'encre d'un dessin à la plume : le trait de côte,
//    le bord des chemins (et leurs pavés), de la plage (des points) et des rochers (leurs strates),
//    des touffes d'herbe, de petites fleurs dans les Prés Blancs, des feuilles mortes dans le Bois
//    des Hachures, et des hachures sur les pentes à l'ombre ;
//  - la vraie couleur, une fois l'endroit colorié : prairie verte, herbe sèche, terre des chemins,
//    sable blanc, roche grise, sous-bois brun, prés fleuris.
// Une carte des sols (« biome », cuite par ile_crayon_v99.gd) : R la terre des chemins, G la roche, B le
// sable, A l'herbe rase de la Clairière des Géants ; « biome2 » : R le sous-bois, G les prés fleuris.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/crayon_v99.gdshaderinc"

uniform sampler2D herbe_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_seche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_seche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D terre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D biome : filter_linear, repeat_disable;
uniform sampler2D biome2 : filter_linear, repeat_disable;
uniform vec4 biome_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool extra_detail = false;
uniform float water_level = -0.42;
uniform vec4 etang = vec4(0.0, 0.0, 0.0, -100.0);   // x, z, rayon, niveau de l'eau

varying vec3 world_position;
varying vec3 world_normal;

vec2 rot_uv(vec2 uv) {
	return mat2(vec2(0.857, 0.515), vec2(-0.515, 0.857)) * uv * 0.71 + vec2(0.37, 0.61);
}

vec4 untiled(sampler2D t, vec2 uv, float mixer) {
	return mix(texture(t, uv), texture(t, rot_uv(uv)), mixer);
}

vec3 untiled_normal(sampler2D t, vec2 uv, float mixer) {
	vec3 a = texture(t, uv).xyz * 2.0 - 1.0;
	vec3 b = texture(t, rot_uv(uv)).xyz * 2.0 - 1.0;
	return normalize(mix(a, b, mixer));
}

vec3 triplanar(sampler2D t, vec3 p, vec3 w, float s) {
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}

vec3 triplanar_n(sampler2D t, vec3 p, vec3 w, float s) {
	return (texture(t, p.zy * s).xyz * w.x + texture(t, p.xz * s).xyz * w.y + texture(t, p.xy * s).xyz * w.z) * 2.0 - 1.0;
}

// Un petit segment d'encre (de a à b, épais de w mètres), net à l'écran.
// (fw : la taille d'un pixel, en mètres, calculée hors des boucles : les dérivées n'ont pas de sens
// dans une branche)
float seg(vec2 p, vec2 a, vec2 b, float w, float fw) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	float d = length(pa - ba * h);
	return 1.0 - smoothstep(w, w + fw, d);
}

// Des motifs semés dans une grille (une case de « cell » mètres) : 0 touffes d'herbe, 1 fleurs,
// 2 feuilles mortes, 3 points de sable.
float seme(vec2 wp, float cell, int kind, float dens, float fw0) {
	vec2 g = wp / cell;
	vec2 i = floor(g);
	float ink = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = i + vec2(float(x), float(y));
			float h = cr_hash(c * 1.37 + float(kind) * 3.1);
			if (h > dens) {
				continue;
			}
			vec2 o = (c + vec2(cr_hash(c + 5.2), cr_hash(c + 11.7)) * 0.8 + 0.1) * cell;
			vec2 p = wp - o;
			float s = 0.7 + 0.6 * cr_hash(c + 2.9);
			float r = cr_hash(c + 8.3) * 6.283;
			mat2 m = mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
			p = m * p / s;
			float fw = fw0 / s;
			if (kind == 0) {
				// une touffe : trois petits brins, côte à côte, un peu penchés
				ink = max(ink, seg(p, vec2(-0.07, 0.0), vec2(-0.12, -0.16), 0.009, fw));
				ink = max(ink, seg(p, vec2(0.0, 0.02), vec2(0.01, -0.21), 0.009, fw));
				ink = max(ink, seg(p, vec2(0.07, 0.0), vec2(0.13, -0.14), 0.009, fw));
			} else if (kind == 1) {
				// une petite fleur : cinq pétales en cercles, un cœur
				float a = atan(p.y, p.x);
				float rr = length(p);
				float petal = 0.11 + 0.05 * cos(a * 5.0);
				float fwr = fw * 1.2;
				ink = max(ink, 1.0 - smoothstep(0.012, 0.012 + fwr, abs(rr - petal)));
				ink = max(ink, 1.0 - smoothstep(0.01, 0.01 + fwr, abs(rr - 0.03)));
			} else if (kind == 2) {
				// une feuille : une amande et sa nervure
				vec2 q = p * vec2(1.0, 2.1);
				float rr = length(q);
				float fwr = fw * 1.2;
				ink = max(ink, 1.0 - smoothstep(0.014, 0.014 + fwr, abs(rr - 0.12)));
				ink = max(ink, seg(p, vec2(-0.12, 0.0), vec2(0.12, 0.0), 0.008, fw));
			} else {
				// un point de sable
				float rr = length(p);
				float fwr = fw * 1.2;
				ink = max(ink, 1.0 - smoothstep(0.018, 0.018 + fwr, rr));
			}
		}
	}
	// de loin, un point d'un pixel deviendrait une tache : les motifs s'effacent
	return ink * (1.0 - smoothstep(0.015, 0.05, fw0));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wp = world_position;
	vec3 n = normalize(world_normal);
	float slope = 1.0 - clamp(n.y, 0.0, 1.0);
	float dist = length(CAMERA_POSITION_WORLD - wp);
	vec2 uv = wp.xz * 0.2;
	float mixer = smoothstep(0.25, 0.75, cr_noise(wp.xz * 0.045));
	float macro = cr_noise(wp.xz * 0.016);
	float patch = cr_noise(wp.xz * 0.08 + 13.0);

	vec2 buv = (wp.xz - biome_rect.xy) / biome_rect.zw;
	vec4 b = texture(biome, buv);
	vec4 b2 = texture(biome2, buv);
	float wob = (patch - 0.5) * 0.3;
	float w_dirt = clamp(b.r + wob * b.r, 0.0, 1.0);
	float w_rock = smoothstep(0.25, 0.7, b.g + wob * 0.4);
	float w_sand = clamp(b.b + wob * 0.5, 0.0, 1.0);
	float w_lawn = clamp(b.a, 0.0, 1.0);
	float w_bois = clamp(b2.r, 0.0, 1.0);
	float w_fleur = clamp(b2.g, 0.0, 1.0);
	float steep = smoothstep(0.42, 0.62, slope + (patch - 0.5) * 0.1);
	steep *= 1.0 - smoothstep(0.3, 0.7, b.r) * 0.85;

	// ------------------------------------------------ la vraie couleur
	vec3 green = untiled(herbe_tex, uv * 1.1, mixer).rgb * vec3(0.8, 0.9, 0.62);
	vec3 dry = untiled(herbe_seche_tex, uv, mixer).rgb * vec3(1.05, 1.02, 0.85);
	float dryk = smoothstep(0.35, 0.8, macro + (patch - 0.5) * 0.25);
	vec3 grass = mix(green, dry, dryk * 0.5);
	grass = mix(grass, green * vec3(0.98, 1.05, 0.92), w_lawn * 0.6);
	// les prés fleuris : des taches de couleur (blanc, jaune, rose, mauve)
	float fl = cr_noise(wp.xz * 1.9);
	vec3 petales = mix(mix(vec3(0.95, 0.92, 0.85), vec3(0.95, 0.8, 0.25), step(0.5, cr_noise(wp.xz * 0.7))), vec3(0.85, 0.5, 0.75), step(0.7, cr_noise(wp.xz * 0.5 + 3.0)));
	grass = mix(grass, petales, w_fleur * smoothstep(0.72, 0.8, fl) * 0.7);
	vec3 litter = untiled(terre_tex, uv * 1.3, mixer).rgb * vec3(1.25, 1.0, 0.75);
	grass = mix(grass, mix(litter, green * 0.7, 0.35), w_bois * 0.8);
	vec3 rock = untiled(roche_tex, uv * 0.8, mixer).rgb * vec3(0.95, 0.95, 0.98);
	vec3 sand = untiled(sable_tex, uv, mixer).rgb * vec3(1.12, 1.1, 1.02);
	vec3 dirt = untiled(terre_tex, uv * 1.2, mixer).rgb * vec3(1.55, 1.22, 0.92);
	if (extra_detail) {
		float near = 1.0 - smoothstep(8.0, 32.0, dist);
		grass = mix(grass, texture(herbe_tex, uv * 3.3).rgb * vec3(0.8, 0.9, 0.62), 0.2 * near);
	}
	vec3 tri = pow(abs(n), vec3(4.0));
	tri /= (tri.x + tri.y + tri.z);
	vec3 cliff = triplanar(roche_tex, wp, tri, 0.12);
	vec3 ground = grass;
	ground = mix(ground, rock, w_rock * 0.85);
	ground = mix(ground, dirt, w_dirt);
	ground = mix(ground, sand, w_sand);
	vec3 albedo = mix(ground, cliff, steep * (1.0 - w_sand * 0.8));
	float shore = 1.0 - smoothstep(0.4, 1.6, wp.y + (macro - 0.5) * 0.8);
	albedo = mix(albedo, mix(cliff * 0.85, sand, w_sand), shore * (1.0 - w_sand));
	float wet = (1.0 - smoothstep(water_level + 0.05, water_level + 0.9 + (patch - 0.5) * 0.4, wp.y));
	albedo *= mix(1.0, 0.62, wet);
	albedo *= mix(1.0, 0.7, 1.0 - smoothstep(water_level - 2.0, water_level, wp.y));

	// ------------------------------------------------ l'encre
	float near_k = 1.0 - smoothstep(55.0, 95.0, dist);
	float mid_k = 1.0 - smoothstep(110.0, 190.0, dist);
	float ink = 0.0;
	float fwp = fwidth(wp.x) + fwidth(wp.z);
	// le trait de côte (et celui des berges, un peu plus haut)
	ink = max(ink, cr_bord(wp.y, water_level + 0.12, 1.8));
	// la berge de l'Étang Gommé
	float de = length(wp.xz - etang.xy);
	ink = max(ink, cr_bord(wp.y, etang.w + 0.08, 1.8) * (1.0 - smoothstep(etang.z + 2.0, etang.z + 4.0, de)));
	// les bords des chemins, de la plage, des rochers (un peu tremblés : c'est dessiné à la main)
	float tremble = (cr_noise(wp.xz * 0.9) - 0.5) * 0.12;
	float flat_k = 1.0 - steep;
	ink = max(ink, cr_bord(b.r + tremble, 0.42, 1.3) * mid_k * flat_k);
	ink = max(ink, cr_bord(b.b + tremble, 0.5, 1.2) * mid_k * flat_k);
	ink = max(ink, cr_bord(b.g + tremble, 0.5, 1.2) * mid_k * flat_k);
	ink = max(ink, cr_bord(b.a + tremble, 0.5, 1.1) * mid_k * 0.8 * flat_k);
	// les pavés des chemins ; les points du sable
	ink = max(ink, cr_pierres(wp.xz * 1.5) * smoothstep(0.55, 0.8, b.r) * near_k * 0.85);
	ink = max(ink, seme(wp.xz, 0.55, 3, 0.55, fwp) * w_sand * near_k * (1.0 - steep));
	// les strates de la roche (sur les pentes raides) et les fentes du haut du mont
	float strate = cr_trait(wp.y * 1.4 + cr_noise(wp.xz * 0.35) * 1.4, 0.07);
	ink = max(ink, strate * steep * mid_k);
	ink = max(ink, cr_pierres(wp.xz * 0.45) * w_rock * (1.0 - steep) * mid_k * 0.8);
	// l'herbe : des touffes ; les fleurs des Prés Blancs ; les feuilles mortes du Bois des Hachures
	float herbe_k = (1.0 - w_dirt) * (1.0 - w_sand) * (1.0 - w_rock) * (1.0 - steep);
	ink = max(ink, seme(wp.xz, 1.25, 0, 0.3 * (1.0 - w_lawn * 0.6), fwp) * herbe_k * (1.0 - w_bois) * near_k);
	ink = max(ink, seme(wp.xz, 1.6, 1, 0.5, fwp) * herbe_k * w_fleur * near_k);
	ink = max(ink, seme(wp.xz, 0.9, 2, 0.4, fwp) * herbe_k * w_bois * near_k);
	// les hachures, sur les pentes à l'ombre
	ink = max(ink, cr_hachures(wp, n, 4.5) * smoothstep(0.08, 0.3, slope) * mid_k);
	ink = clamp(ink, 0.0, 1.0);

	vec3 nm_ground = normalize(mix(untiled_normal(herbe_n, uv * 1.1, mixer), untiled_normal(herbe_seche_n, uv, mixer), dryk * 0.5));
	nm_ground = normalize(mix(nm_ground, untiled_normal(roche_n, uv * 0.8, mixer), w_rock * 0.85));
	nm_ground = normalize(mix(nm_ground, untiled_normal(terre_n, uv * 1.2, mixer), max(w_dirt, w_bois * 0.6)));
	nm_ground = normalize(mix(nm_ground, untiled_normal(sable_n, uv, mixer), w_sand));
	vec3 nm_wall = normalize(triplanar_n(roche_n, wp, tri, 0.12));
	vec3 nm = normalize(mix(nm_ground, nm_wall, steep));
	float c = cr_couleur(wp);
	// le papier est presque plat : le relief fin ne se voit qu'en couleurs
	nm.xy *= mix(1.0, 0.35, smoothstep(25.0, 90.0, dist)) * mix(1.0, 0.4, wet) * mix(0.15, 1.0, c);
	vec3 t_axis = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	vec3 b_axis = normalize(cross(n, t_axis));
	vec3 detailed = normalize(t_axis * nm.x + b_axis * nm.y + n * nm.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(detailed, 0.0)).xyz);

	float cc = max(cr_couleur(wp), smoothstep(water_level - 0.4, water_level - 1.8, wp.y));
	vec3 trait = cr_papier(wp) * (1.0 - 0.9 * ink);
	float bord = smoothstep(0.0, 0.5, cc) * smoothstep(1.0, 0.5, cc);
	ALBEDO = mix(trait, albedo * (1.0 - 0.32 * bord), cc);
	ROUGHNESS = mix(0.95, mix(0.93, 0.3, wet), cc);
	SPECULAR = mix(0.0, mix(0.38, 0.55, wet), cc);
	EMISSION = cr_papier(wp) * (1.0 - cc) * 0.2 * crayon_jour * (1.0 - ink);
}

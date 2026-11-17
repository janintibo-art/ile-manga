// V163 : l'enduit des façades de Port-Azur, vieilli. Sur la texture de l'enduit (azur/enduit.png, sa
// teinte) : les grandes nuances du badigeon refait par morceaux, les plaques passées par le soleil, les
// coulures grises de la pluie, l'humidité qui remonte au pied des murs (plus sombre, un peu verte) et la
// ligne de sel au-dessus, et, çà et là, l'enduit tombé par plaques qui laisse voir les moellons (le bord
// cassé, son ombre). Tout est pris dans le repère du monde : deux maisons voisines ne vieillissent pas
// pareil. Les UV sont ceux du kit (azur_kit_v56.box : une répétition pour 3 m).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_pierre : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_pierre_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 teinte : source_color = vec4(0.95, 0.92, 0.86, 1.0);
uniform float sol_y = 1.2;                 // le sol de la ville basse (l'humidité monte de là)
uniform float normal_force = 0.7;
uniform float plaques : hint_range(0.0, 1.0) = 1.0;   // l'enduit tombé
uniform float humidite : hint_range(0.0, 1.0) = 1.0;  // V164 : la bande humide au pied (0 : aucune)
uniform float echelle_dessous = 2.6;       // V164 : la taille du motif sous l'enduit (moellons, pisé)

varying vec3 wpos;
varying vec3 wnrm;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * bruit(p);
		p = p * 2.03 + vec2(17.1, 9.3);
		a *= 0.5;
	}
	return s / 0.9375;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 alb = texture(tex_albedo, UV).rgb * teinte.rgb;
	vec3 nm = texture(tex_normal, UV).rgb;
	// le repère du mur : h le long du mur, y la hauteur (un toit plat : x, z)
	vec2 hz = normalize(vec2(-wnrm.z, wnrm.x) + vec2(0.0001));
	vec2 q = abs(wnrm.y) > 0.7 ? wpos.xz : vec2(dot(wpos.xz, hz), wpos.y);
	float hb = wpos.y - sol_y;
	// les grandes nuances : le badigeon refait par morceaux, le soleil qui l'a passé
	float n1 = fbm(q * 0.13 + vec2(3.1, 7.7));
	float n2 = fbm(q * 0.42 + vec2(11.0, 2.0));
	alb *= 0.93 + 0.13 * n1;
	float passe = smoothstep(0.58, 0.78, n2);
	alb = mix(alb, mix(alb, vec3(dot(alb, vec3(0.33))), 0.4) * 1.07, passe * 0.6);
	// les coulures : de longues traînées verticales, grises
	float st = bruit(vec2(q.x * 4.2, q.y * 0.22)) * 0.65 + bruit(vec2(q.x * 11.0, q.y * 0.5)) * 0.35;
	float coul = smoothstep(0.62, 0.86, st) * smoothstep(0.35, 0.7, fbm(vec2(q.x * 0.35, 1.3)));
	alb = mix(alb, alb * vec3(0.74, 0.74, 0.76), coul * 0.55);
	// l'humidité au pied du mur, la ligne de sel
	float pied = 0.0;
	float sel = 0.0;
	if (abs(wnrm.y) < 0.7) {
		float lim = 0.85 + 0.55 * fbm(vec2(q.x * 0.6, 4.0));
		pied = smoothstep(lim, lim - 0.6, hb) * step(-0.3, hb);
		sel = smoothstep(0.1, 0.0, abs(hb - lim + 0.05)) * 0.35 * step(0.0, hb) * smoothstep(0.35, 0.65, fbm(vec2(q.x * 0.9, 7.0)));
	}
	pied *= humidite;
	sel *= humidite;
	alb = mix(alb, alb * vec3(0.66, 0.68, 0.62), pied * 0.75);
	alb = mix(alb, vec3(0.9, 0.89, 0.85), sel * (0.5 + 0.5 * bruit(q * 9.0)));
	// l'enduit tombé par plaques (plus souvent en bas) : les moellons, le bord cassé
	float pl = fbm(q * 0.75 + vec2(5.3, 1.7));
	float seuil = mix(0.82, 0.74, smoothstep(2.5, 0.3, hb));
	float trou = smoothstep(seuil, seuil + 0.012, pl) * plaques * step(abs(wnrm.y), 0.7);
	float lev = smoothstep(seuil - 0.03, seuil, pl) * (1.0 - trou) * plaques * step(abs(wnrm.y), 0.7);
	vec2 qs = q / echelle_dessous;
	vec3 pierre = texture(tex_pierre, qs).rgb * vec3(1.02, 0.94, 0.82);
	vec3 pn = texture(tex_pierre_n, qs).rgb;
	alb = mix(alb, alb * 0.82, lev);
	alb = mix(alb, pierre * (0.85 + 0.15 * n1), trou);
	ALBEDO = alb;
	NORMAL_MAP = mix(nm, pn, trou);
	NORMAL_MAP_DEPTH = mix(normal_force, 1.4, trou);
	ROUGHNESS = 0.93 - 0.05 * pied;
	SPECULAR = 0.35;
}

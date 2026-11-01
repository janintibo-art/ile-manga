// V94 : le sol de Néopolis, la ville cyberpunk. Tout est calculé ici, d'après la position dans la
// ville : le quadrillage des rues (une rue tous les 60 m, le Boulevard des Néons plus large au
// milieu), l'asphalte et ses marquages (les lignes, les passages piétons), les trottoirs en dalles
// de béton et leurs bordures, l'intérieur des îlots, la Place des Hologrammes et ses anneaux de
// lumière, la promenade du front de mer, et les murs des quais (béton, en projection triplanaire).
// La ville est toujours un peu mouillée : des flaques où les néons se reflètent, et le soir
// (« mouille » monte) tout l'asphalte brille.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D asphalte_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalte_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 centre = vec2(0.0, 0.0);
uniform float pas = 60.0;          // une rue tous les 60 m
uniform float anneau = 180.0;      // la rue du tour de ville
uniform vec2 place = vec2(-30.0, -30.0);
uniform float mouille : hint_range(0.0, 1.0) = 0.4;
uniform float nuit : hint_range(0.0, 1.0) = 0.0;

varying vec3 wpos;
varying vec3 wnrm;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise2(p) * 0.55 + noise2(p * 2.07 + 3.1) * 0.28 + noise2(p * 4.3 + 7.7) * 0.17;
}

// demi-largeur de la chaussée et du trottoir d'une rue (le Boulevard, au milieu, est plus large)
vec2 largeur(float k) {
	return abs(k) < 0.5 ? vec2(6.0, 9.5) : vec2(4.0, 7.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 l = wpos.xz - centre;
	vec3 aw = abs(wnrm);
	aw = pow(aw, vec3(4.0));
	aw /= (aw.x + aw.y + aw.z);
	float slope = 1.0 - wnrm.y;
	// --- le béton (trottoirs, murs des quais)
	vec3 beton = texture(beton_tex, wpos.xz * 0.25).rgb;
	vec3 beton_w = texture(beton_tex, wpos.zy * 0.2).rgb * aw.x + beton * aw.y + texture(beton_tex, wpos.xy * 0.2).rgb * aw.z;
	vec3 asph = texture(asphalte_tex, wpos.xz * 0.18).rgb;
	asph = mix(asph, texture(asphalte_tex, wpos.zx * 0.043 + 0.37).rgb, 0.4);
	vec3 col;
	float rough;
	float spec = 0.5;
	vec3 emit = vec3(0.0);
	vec3 nmap = vec3(0.5, 0.5, 1.0);
	float sol_route = 0.0;
	// --- les rues
	float m = max(abs(l.x), abs(l.y));
	float kx = clamp(round(l.x / pas), -3.0, 3.0);
	float kz = clamp(round(l.y / pas), -3.0, 3.0);
	float dx = abs(l.x - kx * pas);           // distance à la rue nord-sud la plus proche
	float dz = abs(l.y - kz * pas);           // distance à la rue est-ouest la plus proche
	vec2 wx = largeur(kx);
	vec2 wz = largeur(kz);
	bool dans_ville = m < anneau + 8.0;
	bool route_x = dans_ville && dx < wx.x && abs(l.y) < anneau + wx.x;
	bool route_z = dans_ville && dz < wz.x && abs(l.x) < anneau + wz.x;
	bool trottoir = dans_ville && ((dx < wx.y && abs(l.y) < anneau + wx.y) || (dz < wz.y && abs(l.x) < anneau + wz.y));
	// les tuiles de béton (1,5 m), et leurs joints
	vec2 tq = fract(wpos.xz / 1.5);
	float joint = 1.0 - smoothstep(0.0, 0.035, min(min(tq.x, 1.0 - tq.x), min(tq.y, 1.0 - tq.y)));
	float tvar = hash2(floor(wpos.xz / 1.5));
	if (route_x || route_z) {
		sol_route = 1.0;
		col = asph * vec3(0.78, 0.78, 0.82);
		rough = 0.62;
		nmap = texture(asphalte_n, wpos.xz * 0.18).xyz;
		// les marquages : sur une rue nord-sud (hors carrefour)
		float paint = 0.0;
		if (route_x && !route_z) {
			// la ligne du milieu, en tirets (le Boulevard : deux lignes pleines)
			if (abs(kx) < 0.5) {
				paint = max(paint, step(abs(dx - 0.25), 0.07));
			} else {
				paint = max(paint, step(dx, 0.07) * step(fract(l.y / 6.0), 0.5));
			}
			paint = max(paint, step(abs(dx - (wx.x - 0.35)), 0.07));
			// le passage piéton, juste avant le carrefour
			float avant = dz - wz.y;
			if (avant > 0.6 && avant < 3.8) {
				paint = max(paint, step(fract(l.x / 1.1), 0.5) * step(dx, wx.x - 0.6));
			}
		}
		if (route_z && !route_x) {
			paint = max(paint, step(dz, 0.07) * step(fract(l.x / 6.0), 0.5));
			paint = max(paint, step(abs(dz - (wz.x - 0.35)), 0.07));
			float avant2 = dx - wx.y;
			if (avant2 > 0.6 && avant2 < 3.8) {
				paint = max(paint, step(fract(l.y / 1.1), 0.5) * step(dz, wz.x - 0.6));
			}
		}
		paint *= 0.75 + 0.25 * noise2(wpos.xz * 3.0);       // la peinture usée
		col = mix(col, vec3(0.78, 0.78, 0.74), paint);
		rough = mix(rough, 0.45, paint);
		// le Boulevard : entre ses deux lignes, une bande de diodes qui s'allume le soir
		if (route_x && !route_z && abs(kx) < 0.5 && dx < 0.12) {
			float diode = step(fract(l.y / 1.4 - TIME * 0.6), 0.3);
			emit += vec3(0.1, 0.9, 1.0) * diode * nuit * 2.2;
		}
	} else if (trottoir) {
		col = beton * mix(vec3(0.5, 0.5, 0.52), vec3(0.6, 0.6, 0.62), tvar);
		col *= 1.0 - joint * 0.35;
		rough = 0.7;
		nmap = texture(beton_n, wpos.xz * 0.25).xyz;
		// la bordure, au bord de la chaussée
		float bx = route_x ? 99.0 : abs(dx - wx.x);
		float bz = route_z ? 99.0 : abs(dz - wz.x);
		float bord = 1.0 - smoothstep(0.18, 0.3, min(bx, bz));
		col = mix(col, vec3(0.36, 0.36, 0.38) * beton, bord);
	} else if (m < anneau) {
		// l'intérieur des îlots : de grandes dalles sombres (les pieds des tours, les cours)
		vec2 tq2 = fract(wpos.xz / 3.0);
		float j2 = 1.0 - smoothstep(0.0, 0.02, min(min(tq2.x, 1.0 - tq2.x), min(tq2.y, 1.0 - tq2.y)));
		col = beton * vec3(0.38, 0.38, 0.41) * (0.85 + 0.25 * hash2(floor(wpos.xz / 3.0)));
		col *= 1.0 - j2 * 0.4;
		rough = 0.6;
		// la Place des Hologrammes : un dallage clair, en cercles, et des anneaux de lumière
		float dp = length(l - place);
		if (dp < 22.5) {
			float ring = fract(dp / 4.0);
			col = beton * mix(vec3(0.62, 0.62, 0.66), vec3(0.48, 0.5, 0.56), step(ring, 0.5));
			float glow = (1.0 - smoothstep(0.0, 0.08, abs(ring - 0.5))) * step(4.0, dp);
			emit += vec3(0.2, 0.8, 1.0) * glow * (0.25 + nuit * 2.0) * (0.6 + 0.4 * sin(TIME * 1.5 - dp * 0.4));
			rough = 0.35;
		}
	} else {
		// la promenade du front de mer : des dalles claires, des bandes de bois
		col = beton * vec3(0.62, 0.6, 0.57) * (0.88 + 0.2 * tvar);
		col *= 1.0 - joint * 0.3;
		float planche = step(0.5, fract((m - anneau) / 9.0));
		col = mix(col, vec3(0.32, 0.22, 0.15) * (0.8 + 0.4 * noise2(vec2(wpos.x + wpos.z, m) * vec2(0.6, 6.0))), planche * step(anneau + 14.0, m) * 0.85);
		rough = 0.65;
	}
	// --- les murs des quais : béton, des coulures, des algues en bas
	if (slope > 0.35) {
		col = beton_w * vec3(0.48, 0.48, 0.5);
		float coul = noise2(vec2(wpos.x + wpos.z, wpos.y * 0.15) * vec2(1.6, 1.0));
		col *= 0.75 + 0.3 * coul;
		col = mix(col, vec3(0.1, 0.16, 0.1), smoothstep(0.6, -0.8, wpos.y) * 0.8);
		rough = 0.85;
		sol_route = 0.0;
		nmap = vec3(0.5, 0.5, 1.0);
	}
	// --- l'eau : des flaques (plus grandes là où l'on roule), et un voile mouillé le soir
	float flaque = smoothstep(0.62, 0.7, fbm(wpos.xz * 0.11) + sol_route * 0.06 - joint * 0.05);
	float w = clamp(mouille, 0.0, 1.0) * (1.0 - step(0.35, slope));
	col *= 1.0 - w * 0.15;
	rough = mix(rough, rough * 0.45, w);
	col = mix(col, col * 0.6, flaque * w);
	rough = mix(rough, 0.03, flaque * w);
	nmap = mix(nmap, vec3(0.5, 0.5, 1.0), flaque * w);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = spec;
	NORMAL_MAP = nmap;
	NORMAL_MAP_DEPTH = 0.8;
	EMISSION = emit;
}

// V121 : le sol de Sombreval, la ville morte. Les couleurs des sommets disent ce qu'il y a là
// (r : l'asphalte des rues, g : les herbes qui ont tout envahi, b : la roche de la Butte du Comte,
// a : les vieux pavés de la route du château et de la cour). Ici : l'asphalte craquelé, ses
// fissures où pousse la mousse, les lignes effacées ; la terre battue et les gravats entre les
// immeubles ; l'herbe haute ; la roche noire et ses lichens ; les pavés luisants ; la grève grise
// au bord de l'eau, mouillée là où la mer monte.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D asphalte_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalte_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D herbe_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D pave_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D pave_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float plateau_y = 2.2;
uniform float mouille : hint_range(0.0, 1.0) = 0.35;

varying vec3 wpos;
varying vec3 wnrm;
varying vec4 masque;

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

// des fissures : les bords d'un pavage de Voronoï, déformé
float fissures(vec2 p) {
	p += vec2(fbm(p * 0.7), fbm(p * 0.7 + 9.0)) * 1.4;
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash2(i + g), hash2(i + g + 31.7));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return 1.0 - smoothstep(0.0, 0.07, d2 - d1);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	masque = COLOR;
}

void fragment() {
	vec2 p = wpos.xz;
	float big = fbm(p * 0.035);
	float mid = fbm(p * 0.21 + 5.0);
	// --- la terre battue, les gravats
	vec3 terre = texture(sable_tex, p * 0.23).rgb;
	terre = mix(vec3(dot(terre, vec3(0.3, 0.55, 0.15))), terre, 0.35) * vec3(0.4, 0.37, 0.33);
	terre = mix(terre, terre * vec3(0.7, 0.68, 0.66), smoothstep(0.45, 0.75, mid));
	float grav = smoothstep(0.62, 0.8, fbm(p * 0.9 + 2.0));
	terre = mix(terre, vec3(0.42, 0.41, 0.4) * (0.7 + 0.5 * noise2(p * 7.0)), grav * 0.7);
	vec3 col = terre;
	vec3 nrm_t = texture(sable_n, p * 0.23).rgb;
	float rough = 0.95;
	// --- l'asphalte craquelé
	float a = masque.r;
	if (a > 0.01) {
		vec3 asph = texture(asphalte_tex, p * 0.16).rgb * 0.82;
		asph = mix(asph, texture(asphalte_tex, p * 0.041 + 0.37).rgb * 0.7, 0.4);
		asph *= 0.85 + 0.3 * big;
		float cr = fissures(p * 0.42) * smoothstep(0.25, 0.6, mid + 0.25);
		vec3 mousse = vec3(0.16, 0.22, 0.08) * (0.7 + 0.6 * noise2(p * 13.0));
		asph = mix(asph, mix(vec3(0.05, 0.05, 0.045), mousse, 0.75), cr);
		// les lignes blanches, presque effacées
		float ligne = (1.0 - smoothstep(0.08, 0.14, abs(fract(p.x / 50.0 + 0.5) - 0.5) * 50.0)) * step(0.5, fract(p.y * 0.25));
		ligne += (1.0 - smoothstep(0.08, 0.14, abs(fract(p.y / 50.0 + 0.5) - 0.5) * 50.0)) * step(0.5, fract(p.x * 0.25));
		asph = mix(asph, vec3(0.62, 0.6, 0.55), clamp(ligne, 0.0, 1.0) * 0.45 * smoothstep(0.35, 0.7, noise2(p * 0.8)));
		col = mix(col, asph, a);
		nrm_t = mix(nrm_t, texture(asphalte_n, p * 0.16).rgb, a);
		rough = mix(rough, 0.88 - 0.3 * mouille, a);
	}
	// --- les vieux pavés
	float pv = masque.a;
	if (pv > 0.01) {
		vec3 pave = texture(pave_tex, p * 0.33).rgb * vec3(0.55, 0.53, 0.52);
		pave *= 0.8 + 0.4 * big;
		float joint = smoothstep(0.5, 0.75, fbm(p * 2.0));
		pave = mix(pave, vec3(0.12, 0.16, 0.07), joint * 0.6);
		col = mix(col, pave, pv);
		nrm_t = mix(nrm_t, texture(pave_n, p * 0.33).rgb, pv);
		rough = mix(rough, 0.55 - 0.25 * mouille, pv);
	}
	// --- la roche noire de la Butte (projection triplanaire : les pentes sont raides)
	float rk = masque.b;
	if (rk > 0.01) {
		vec3 aw = pow(abs(wnrm), vec3(4.0));
		aw /= (aw.x + aw.y + aw.z);
		vec3 roche = texture(roche_tex, wpos.zy * 0.12).rgb * aw.x + texture(roche_tex, p * 0.12).rgb * aw.y + texture(roche_tex, wpos.xy * 0.12).rgb * aw.z;
		roche *= vec3(0.42, 0.41, 0.42);
		roche = mix(roche, vec3(0.32, 0.36, 0.22), smoothstep(0.55, 0.8, fbm(wpos.xy * 0.3 + wpos.zz * 0.2)) * 0.5);
		col = mix(col, roche, rk);
		nrm_t = mix(nrm_t, texture(roche_n, p * 0.12).rgb, rk);
		rough = mix(rough, 0.9, rk);
	}
	// --- les herbes : elles ont tout envahi (par plaques ; plus touffues au pied des murs)
	float g = masque.g;
	float gm = smoothstep(0.35, 0.65, g + (mid - 0.5) * 0.8);
	vec3 herbe = texture(herbe_tex, p * 0.21).rgb * vec3(0.55, 0.62, 0.45);
	herbe = mix(herbe, herbe * vec3(0.85, 0.8, 0.5), smoothstep(0.4, 0.8, big));
	col = mix(col, herbe, gm);
	nrm_t = mix(nrm_t, texture(herbe_n, p * 0.21).rgb, gm);
	rough = mix(rough, 0.95, gm);
	// --- la grève grise, mouillée près de l'eau
	float sable = 1.0 - smoothstep(plateau_y - 1.2, plateau_y - 0.4, wpos.y);
	if (sable > 0.01) {
		vec3 sb = texture(sable_tex, p * 0.3).rgb * vec3(0.5, 0.49, 0.47);
		float wet = 1.0 - smoothstep(-0.6, 0.5, wpos.y);
		sb = mix(sb, sb * 0.45, wet);
		col = mix(col, sb, sable);
		nrm_t = mix(nrm_t, texture(sable_n, p * 0.3).rgb, sable);
		rough = mix(rough, mix(0.9, 0.25, wet), sable);
	}
	ALBEDO = col;
	NORMAL_MAP = nrm_t;
	NORMAL_MAP_DEPTH = 0.9;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}

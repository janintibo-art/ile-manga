// V121 : les façades des immeubles en ruine de Sombreval (des boîtes d'un MultiMesh). Tout est
// calculé d'après la position dans le monde : les étages (3,2 m), les fenêtres crevées (des trous
// noirs, des cadres arrachés, quelques planches clouées, de rares vitres sales), les vitrines du
// rez-de-chaussée, la brique, le béton ou l'enduit écaillé, les coulures de crasse sous les
// appuis, les traces de feu, et le lierre qui grimpe depuis le pied des murs et pend des toits.
// INSTANCE_CUSTOM : x hasard, y matière (0 brique, 0,5 béton, 1 enduit), z lierre, w teinte.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D brique_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brique_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D beton_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D feuilles_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D bois_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float sol_y = 2.2;

varying vec3 wpos;
varying vec3 wnrm;
varying vec4 cust;

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

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	cust = INSTANCE_CUSTOM;
}

void fragment() {
	float seed = cust.x * 97.0;
	float mat = cust.y;
	vec3 tint = mix(vec3(1.0), vec3(0.85 + 0.3 * cust.w, 0.82 + 0.15 * cust.w, 0.78), 0.6);
	vec3 col;
	vec3 nrm;
	float rough = 0.92;
	float spec = 0.3;
	if (abs(wnrm.y) > 0.5) {
		// le dessus : des gravats, de la mousse, des herbes
		vec2 p = wpos.xz;
		col = texture(beton_tex, p * 0.25).rgb * vec3(0.45, 0.44, 0.42);
		float m = smoothstep(0.35, 0.65, fbm(p * 0.4 + seed));
		col = mix(col, vec3(0.15, 0.22, 0.08) * (0.7 + 0.6 * noise2(p * 6.0)), m);
		nrm = texture(beton_n, p * 0.25).rgb;
	} else {
		vec2 tg = normalize(vec2(-wnrm.z, wnrm.x));
		float u = dot(wpos.xz, tg);
		float v = wpos.y - sol_y;
		vec2 uv = vec2(u, v);
		// la matière du mur
		vec3 bri = texture(brique_tex, uv * vec2(0.45, 0.45)).rgb * vec3(0.72, 0.58, 0.5);
		vec3 bet = texture(beton_tex, uv * 0.22).rgb * vec3(0.6, 0.59, 0.57);
		vec3 enduit = mix(vec3(0.62, 0.58, 0.5), vec3(0.5, 0.52, 0.5), cust.w) * (0.85 + 0.25 * fbm(uv * 0.6 + seed));
		// l'enduit écaillé laisse voir la brique
		float ecaille = smoothstep(0.5, 0.62, fbm(uv * 0.35 + seed * 1.3));
		enduit = mix(enduit, bri, ecaille);
		col = mat < 0.25 ? bri : (mat < 0.75 ? bet : enduit);
		nrm = mat < 0.25 ? texture(brique_n, uv * 0.45).rgb : texture(beton_n, uv * 0.22).rgb;
		col *= tint;
		// les étages, les fenêtres
		float etage = floor(v / 3.2);
		float fy = fract(v / 3.2);
		float fx = fract(u / 2.8 + seed * 0.13);
		vec2 cell = vec2(floor(u / 2.8 + seed * 0.13), etage);
		float h = hash2(cell + seed);
		float win;
		float rdc = 1.0 - step(1.0, etage);
		if (rdc > 0.5) {
			// les vitrines et les portes du rez-de-chaussée : de grands trous noirs, des rideaux de fer
			float fxs = fract(u / 5.6 + seed * 0.07);
			win = step(0.08, fxs) * step(fxs, 0.92) * step(0.02, fy) * step(fy, 0.78);
			fx = fxs;
		} else {
			win = step(0.27, fx) * step(fx, 0.73) * step(0.3, fy) * step(fy, 0.86);
		}
		// le bandeau entre deux étages
		float bandeau = (1.0 - smoothstep(0.0, 0.04, fy)) * step(0.5, etage);
		col = mix(col, col * 0.72, bandeau);
		if (win > 0.5) {
			vec3 trou = vec3(0.015, 0.014, 0.013) * (0.6 + 0.8 * noise2(uv * 3.0));
			// le bord intérieur (l'épaisseur du mur) un peu éclairé
			float bx = min(fx - (rdc > 0.5 ? 0.08 : 0.27), (rdc > 0.5 ? 0.92 : 0.73) - fx);
			float by = min(fy - (rdc > 0.5 ? 0.02 : 0.3), (rdc > 0.5 ? 0.78 : 0.86) - fy);
			float bord = 1.0 - smoothstep(0.0, 0.035, min(bx, by));
			trou = mix(trou, col * 0.35, bord);
			if (h < 0.14) {
				// des planches clouées en travers
				vec2 pu = vec2(fx * 3.0, fy * 9.0);
				vec3 bois = texture(bois_tex, pu * 0.5 + h).rgb * vec3(0.42, 0.33, 0.25);
				float planche = step(0.18, fract(fy * 4.0 + h * 3.0));
				trou = mix(trou, bois, planche);
			} else if (h < 0.24 && rdc < 0.5) {
				// une vitre sale, fendue
				trou = vec3(0.07, 0.08, 0.08) + vec3(0.04) * noise2(uv * 9.0);
				spec = 0.6;
				rough = 0.25;
			} else if (h < 0.34 && rdc > 0.5) {
				// un rideau de fer rouillé, à moitié baissé
				float rid = step(fy, 0.45 + 0.3 * h);
				vec3 fer = vec3(0.28, 0.17, 0.1) * (0.7 + 0.5 * step(0.5, fract(fy * 40.0)));
				trou = mix(trou, fer, rid);
			}
			col = trou;
		}
		// les coulures de crasse sous les appuis, les traces de feu
		float coul = smoothstep(0.55, 0.9, noise2(vec2(u * 2.3, v * 0.08) + seed)) * (1.0 - smoothstep(0.3, 1.0, fy));
		col *= 1.0 - 0.35 * coul;
		float feu = smoothstep(0.66, 0.8, fbm(uv * 0.12 + seed * 2.0)) * step(0.55, cust.x);
		col = mix(col, vec3(0.03, 0.028, 0.025), feu * 0.85);
		// le lierre : il grimpe depuis le pied des murs, et pend du haut
		float lierre = fbm(uv * 0.18 + seed) + cust.z * 0.6 - smoothstep(0.0, 18.0, v) * 0.55 + 0.1 + (noise2(uv * 1.7) - 0.5) * 0.18;
		float iv = smoothstep(0.62, 0.7, lierre);
		if (iv > 0.01) {
			vec4 lf = texture(feuilles_tex, uv * 1.7 + vec2(noise2(uv * 0.9), noise2(uv * 0.9 + 4.0)) * 0.6);
			vec4 lf2 = texture(feuilles_tex, uv * 1.1 + 0.37);
			vec3 vert = mix(lf.rgb, lf2.rgb, 0.5) * vec3(0.3, 0.38, 0.2) * (0.55 + 0.6 * noise2(uv * 3.0));
			float couvre = iv * smoothstep(0.2, 0.6, max(lf.a, lf2.a) + 0.25);
			col = mix(col, vert, couvre);
			rough = mix(rough, 0.75, couvre);
		}
	}
	ALBEDO = col;
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = 0.8;
	ROUGHNESS = rough;
	SPECULAR = spec;
}

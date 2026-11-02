// V97 : la sauce tomate de l'Île Al Dente, quand elle est épaisse et opaque : la Marmite (le cratère
// du Mont Bolognaise, qui bouillonne : des bulles gonflent et éclatent), le Lac Napolitain (calme, qui
// frémit à peine), la fontaine du parvis. mode 0 : la Marmite ; 1 : le lac ; 2 : la fontaine.
// boil (0 à 1) : la Marmite s'agite avant une éruption.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform int mode = 0;

uniform float speed = 0.55;
uniform float boil = 0.0;
uniform float bubble_scale = 1.0;

varying vec3 wpos;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 h22(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(a), h21(a + vec2(1.0, 0.0)), f.x), mix(h21(a + vec2(0.0, 1.0)), h21(a + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += vnoise(p) * a;
		p = p * 2.07 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

// Les bulles : une cellule par bulle ; chaque bulle gonfle, puis éclate (rayon, hauteur du dôme).
// Renvoie (hauteur, distance au centre / rayon, éclat).
vec3 bubbles(vec2 p, float t, float rate) {
	vec2 cell = floor(p);
	vec3 best = vec3(0.0, 9.0, 0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 c = cell + vec2(float(i), float(j));
			vec2 o = h22(c);
			float ph = fract(t * (0.18 + 0.25 * o.x) * rate + o.y * 7.0);
			float r = 0.34 * smoothstep(0.0, 0.85, ph) * (0.4 + 0.6 * o.x) * step(0.35, o.y);
			float d = length(p - (c + 0.15 + o * 0.7));
			if (r > 0.01 && d < r) {
				float k = d / r;
				float hgt = sqrt(max(1.0 - k * k, 0.0)) * r * 0.6 * (1.0 - smoothstep(0.9, 1.0, ph));
				if (hgt > best.x) {
					best = vec3(hgt, k, smoothstep(0.88, 1.0, ph));
				}
			}
		}
	}
	return best;
}

// La couleur de la sauce : un rouge tomate profond, plus clair là où elle est mince ou étirée, des
// morceaux de tomate, quelques feuilles de basilic et des grains d'herbes, des reflets d'huile.
vec3 sauce_color(vec2 p, float stretch, out float rough, out float chunk) {
	float n1 = fbm(p * 0.9);
	float n2 = fbm(p * 3.1 + 4.0);
	vec3 deep = vec3(0.30, 0.025, 0.012);
	vec3 mid = vec3(0.52, 0.06, 0.02);
	vec3 bright = vec3(0.70, 0.16, 0.04);
	vec3 col = mix(deep, mid, smoothstep(0.25, 0.75, n1));
	col = mix(col, bright, smoothstep(0.55, 0.9, n2) * (0.35 + 0.5 * stretch));
	// les morceaux de tomate : de petites taches plus claires, en relief
	vec2 cc = p * 2.6;
	vec2 ci = floor(cc);
	vec2 co = h22(ci);
	float cd = length(fract(cc) - (0.25 + co * 0.5));
	chunk = (1.0 - smoothstep(0.12, 0.2 + co.x * 0.08, cd)) * step(0.55, co.y);
	col = mix(col, vec3(0.78, 0.17, 0.07), chunk * 0.7);
	// le basilic et les herbes
	vec2 bc = p * 4.3 + 11.0;
	vec2 bi = floor(bc);
	vec2 bo = h22(bi);
	float bd = length((fract(bc) - (0.3 + bo * 0.4)) * vec2(1.0, 1.8));
	float leaf = (1.0 - smoothstep(0.08, 0.13, bd)) * step(0.93, bo.x);
	col = mix(col, vec3(0.08, 0.2, 0.04), leaf);
	float herb = (1.0 - smoothstep(0.02, 0.04, length(fract(p * 9.0) - h22(floor(p * 9.0))))) * step(0.8, h21(floor(p * 9.0) + 3.0));
	col = mix(col, vec3(0.12, 0.08, 0.03), herb * 0.8);
	rough = mix(0.16, 0.42, max(chunk, leaf));
	return col;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	float rate = mode == 0 ? (1.0 + 2.5 * boil) : (mode == 1 ? 0.35 : 0.8);
	vec3 b = bubbles(wpos.xz * 0.9 / bubble_scale, t, rate);
	float swell = (fbm(wpos.xz * 0.15 + vec2(t * 0.05, -t * 0.04)) - 0.5) * (mode == 0 ? 0.25 + 0.4 * boil : 0.05);
	VERTEX.y += b.x * bubble_scale * (mode == 1 ? 0.4 : 1.0) + swell;
}

void fragment() {
	float t = TIME;
	vec2 p = wpos.xz;
	// la sauce tourne doucement (dans la Marmite) ou dérive (le lac)
	vec2 drift = mode == 0 ? vec2(sin(t * 0.07), cos(t * 0.05)) * 1.5 : vec2(t * 0.02, t * 0.013);
	float rough;
	float chunk;
	vec3 col = sauce_color(p * 0.7 + drift, 0.2, rough, chunk);
	float rate = mode == 0 ? (1.0 + 2.5 * boil) : (mode == 1 ? 0.35 : 0.8);
	vec3 b = bubbles(p * 0.9 / bubble_scale, t, rate);
	// la peau des bulles : plus claire, plus brillante ; l'éclat : une tache sombre qui se referme
	float skin = step(b.y, 1.0) * (1.0 - b.y);
	col = mix(col, vec3(0.66, 0.12, 0.04), skin * 0.35);
	col *= 1.0 - 0.35 * b.z;
	// le relief : des rides lentes, les morceaux, les bulles
	float e = 0.08;
	float h0 = fbm(p * 1.6 + drift * 1.3);
	float hx = fbm((p + vec2(e, 0.0)) * 1.6 + drift * 1.3);
	float hz = fbm((p + vec2(0.0, e)) * 1.6 + drift * 1.3);
	vec3 n = normalize(vec3((h0 - hx) * 0.9 - chunk * 0.2, 1.0, (h0 - hz) * 0.9));
	if (b.y < 1.0) {
		vec2 dir = normalize(fract(p * 0.9 / bubble_scale) - 0.5 + vec2(0.0001));
		n = normalize(n + vec3(dir.x, 0.0, dir.y) * b.y * 1.4);
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	// l'huile : un reflet orangé là où la sauce est lisse
	float oil = smoothstep(0.55, 0.85, fbm(p * 0.45 - drift * 0.5));
	ALBEDO = col * 0.85 + vec3(0.06, 0.015, 0.0) * oil;
	ROUGHNESS = mix(rough + 0.08, 0.12, oil * 0.5);
	SPECULAR = 0.4;
	SSS_STRENGTH = 0.25;
	BACKLIGHT = vec3(0.25, 0.03, 0.01);
}

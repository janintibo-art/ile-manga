// V97 : la sauce tomate qui coule, en rubans aux bords fondus : les deux rivières de sauce du Mont
// Bolognaise, le déversoir du Lac Napolitain, la Cascade Arrabbiata (qui tombe de la falaise dans la
// mer), et le panache rouge qui se dilue dans la mer au pied de la cascade.
// mode 0 : rivière (UV.y : le long du courant, en mètres ; UV.x : en travers, de 0 à 1) ;
// mode 1 : cascade (pareil, la sauce tombe vite et s'étire) ; mode 2 : le panache dans la mer (UV de 0
// à 1, le centre au milieu).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

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
			float r = 0.42 * smoothstep(0.0, 0.85, ph) * (0.5 + 0.5 * o.x);
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
	if (mode == 0) {
		float across = UV.x * 2.0 - 1.0;
		// la sauce bombe un peu au milieu du lit, et roule en vaguelettes
		VERTEX.y += (1.0 - across * across) * 0.12 + sin(UV.y * 1.7 - TIME * speed * 6.0) * 0.025;
	} else if (mode == 1) {
		VERTEX += NORMAL * (sin(UV.y * 2.3 + TIME * 9.0) * 0.06 + (vnoise(vec2(UV.x * 5.0, UV.y * 0.8 + TIME * 3.0)) - 0.5) * 0.18);
	}
}

void fragment() {
	float t = TIME;
	float a = 1.0;
	vec3 col;
	float rough;
	float chunk;
	vec3 n = vec3(0.0, 0.0, 1.0);
	if (mode == 2) {
		vec2 q = UV - 0.5;
		float r = length(q) * 2.0;
		float sw = fbm(q * 7.0 + vec2(t * 0.04, -t * 0.03)) + fbm(q * 15.0 - t * 0.05) * 0.5;
		a = (1.0 - smoothstep(0.2, 1.0, r + (sw - 0.7) * 0.5)) * 0.85;
		col = mix(vec3(0.45, 0.05, 0.03), vec3(0.32, 0.12, 0.1), smoothstep(0.1, 0.9, r));
		rough = 0.12;
		chunk = 0.0;
		float e = 0.02;
		float h0 = fbm(q * 20.0 + t * 0.08);
		n = normalize(vec3((h0 - fbm((q + vec2(e, 0.0)) * 20.0 + t * 0.08)) * 0.5, (h0 - fbm((q + vec2(0.0, e)) * 20.0 + t * 0.08)) * 0.5, 1.0));
	} else {
		float sp = mode == 1 ? speed * 7.0 : speed;
		// le courant : la sauce avance le long du ruban, plus vite au milieu qu'au bord
		float across = UV.x * 2.0 - 1.0;
		float v = UV.y - t * sp * (1.0 - 0.45 * across * across);
		vec2 p = vec2(UV.x * 2.4, v * (mode == 1 ? 0.35 : 0.8));
		col = sauce_color(p, mode == 1 ? 0.9 : 0.35, rough, chunk);
		float ridges = fbm(vec2(UV.x * 6.0, v * 1.4)) ;
		float e = 0.05;
		float hx = fbm(vec2((UV.x + e) * 6.0, v * 1.4));
		float hy = fbm(vec2(UV.x * 6.0, (v + e) * 1.4));
		n = normalize(vec3((ridges - hx) * 1.3 - chunk * 0.15, (ridges - hy) * 1.3, 1.0));
		// les bords : la sauce s'amincit, fonce un peu (elle colle au lit) et fond dans la croûte
		float edge = min(UV.x, 1.0 - UV.x);
		float wob = (vnoise(vec2(UV.y * 0.6 - t * sp * 0.4, 3.0)) - 0.5) * 0.08;
		a = smoothstep(0.02, 0.2 + wob, edge);
		col *= mix(0.7, 1.0, smoothstep(0.05, 0.3, edge));
		if (mode == 1) {
			// la cascade : des filets plus clairs, des trous de lumière, l'écume rose au pied
			float streak = fbm(vec2(UV.x * 14.0, v * 0.15));
			col = mix(col, vec3(0.74, 0.2, 0.08), smoothstep(0.55, 0.8, streak) * 0.5);
			a *= smoothstep(0.18, 0.4, streak + 0.2);
		}
	}
	vec3 tn = normalize(TANGENT * n.x + BINORMAL * n.y + NORMAL * n.z);
	NORMAL = tn;
	ALBEDO = col;
	ALPHA = a;
	ROUGHNESS = rough;
	SPECULAR = 0.55;
	BACKLIGHT = vec3(0.3, 0.04, 0.01);
}

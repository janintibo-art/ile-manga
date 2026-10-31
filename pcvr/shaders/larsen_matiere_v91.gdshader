// V91 : les matières de l'Île de Larsen qui n'ont pas de texture : la tôle ondulée et rouillée des
// garages de Rainville, la peinture des bus du Camp des Fleurs (des fleurs, des vagues, des soleils),
// la toile et le vinyle des amplis, les fanions de prières qui flottent au vent, le chrome, les pneus,
// les vitres. UV en mètres (sauf les fanions : u le long du fil, v de 0, le fil, à 1, le bas).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform int mode = 0;      // 0 tôle, 1 bus peint, 2 toile d'ampli, 3 vinyle, 4 fanion, 5 chrome, 6 pneu, 7 vitre, 8 toile tendue
uniform vec3 color : source_color = vec3(0.5);
uniform vec3 color2 : source_color = vec3(0.9, 0.6, 0.2);
uniform float seed = 0.0;
uniform float wind = 1.0;

varying vec3 wpos;
varying vec4 vcol;

float h1(float n) { return fract(sin(mod(n, 61.0) * 12.9898 + 0.5) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * noise2(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}
vec3 pal(float k) {
	int i = int(floor(k * 7.0));
	if (i == 0) return vec3(0.9, 0.2, 0.15);
	if (i == 1) return vec3(0.98, 0.6, 0.1);
	if (i == 2) return vec3(0.98, 0.88, 0.22);
	if (i == 3) return vec3(0.25, 0.65, 0.35);
	if (i == 4) return vec3(0.15, 0.5, 0.82);
	if (i == 5) return vec3(0.6, 0.3, 0.7);
	return vec3(0.95, 0.45, 0.65);
}

void vertex() {
	vcol = COLOR;
	if (mode == 4) {
		// les fanions bougent au vent : plus le bas est loin du fil, plus il flotte
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float s = sin(TIME * 3.1 + w.x * 0.9 + w.z * 0.7) + 0.5 * sin(TIME * 5.3 + w.x * 2.1);
		VERTEX += NORMAL * s * 0.06 * UV.y * wind;
		VERTEX.y += (sin(TIME * 2.3 + w.x) * 0.02) * UV.y * wind;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = color;
	float rough = 0.8;
	float metal = 0.0;
	float ao = 1.0;
	if (mode == 0) {
		// la tôle ondulée : les ondes le long de u ; la rouille coule depuis les bords et les vis
		float wave = sin(uv.x * 6.2832 / 0.076);
		float f = fbm(uv * 3.0 + seed);
		float rust = smoothstep(0.48, 0.72, f + 0.25 * (1.0 - smoothstep(0.0, 0.5, uv.y)) + 0.15 * noise2(vec2(uv.x * 30.0, uv.y * 2.0)));
		col = color * (0.82 + 0.12 * wave + 0.15 * f);
		col = mix(col, vec3(0.42, 0.19, 0.07) * (0.7 + 0.5 * noise2(uv * 40.0)), rust);
		metal = mix(0.65, 0.05, rust);
		rough = mix(0.45, 0.95, rust);
		ao = 0.86 + 0.14 * wave;
		NORMAL_MAP = normalize(vec3(0.5 + cos(uv.x * 6.2832 / 0.076) * 0.32, 0.5, 1.0));
	} else if (mode == 1) {
		// un bus peint : des bandes ondulées, de grandes fleurs, un soleil ; le vernis s'use en bas
		float f = fbm(uv * 2.0 + seed);
		float wv = sin(uv.x * 0.9 + seed) * 0.35 + uv.y;
		col = color;
		col = mix(col, color2, step(0.85, wv) * step(wv, 1.2));
		col = mix(col, pal(h1(seed + 4.0)), step(1.2, wv) * step(wv, 1.45));
		vec2 g = uv / vec2(1.7, 1.3);
		vec2 gi = floor(g);
		vec2 gf = fract(g) - 0.5;
		float r = length(gf);
		float ang = atan(gf.y, gf.x);
		if (h1(gi.x * 7.3 + gi.y * 1.7 + seed) > 0.45) {
			float k = h1(gi.x + gi.y * 11.0 + seed);
			float petal = 0.24 + 0.1 * cos(ang * (5.0 + floor(k * 3.0)) + k * 6.0);
			col = mix(col, pal(k), step(r, petal));
			col = mix(col, vec3(0.99, 0.92, 0.3), step(r, 0.08));
		}
		// le symbole de la paix, peint sur chaque flanc, en grand
		vec2 pc = (uv - vec2(4.0 + h1(seed) * 1.5, 1.0)) / 0.55;
		float pr = length(pc);
		float ring = step(abs(pr - 0.85), 0.12);
		float bar = step(abs(pc.x), 0.08) * step(pr, 0.85);
		float diag = step(abs(abs(pc.x) + pc.y), 0.11) * step(pc.y, 0.0) * step(pr, 0.85);
		col = mix(col, vec3(0.97, 0.95, 0.9), max(ring, max(bar, diag)));
		col *= 0.88 + 0.16 * f;
		col = mix(col, vec3(0.32, 0.26, 0.2), smoothstep(0.35, 0.0, uv.y) * 0.6);
		rough = 0.45;
	} else if (mode == 2) {
		// la toile d'ampli : un tissage serré, noir ou beige
		float w = step(0.5, fract(uv.x * 90.0)) * 0.5 + step(0.5, fract(uv.y * 90.0)) * 0.5;
		col = color * (0.75 + 0.3 * w) * (0.9 + 0.1 * noise2(uv * 8.0));
		rough = 0.95;
	} else if (mode == 3) {
		// le vinyle granuleux des amplis
		float g = noise2(uv * 220.0);
		col = color * (0.85 + 0.25 * g);
		rough = 0.55 + 0.2 * g;
	} else if (mode == 4) {
		col = vcol.rgb * (0.85 + 0.2 * fbm(uv * vec2(20.0, 6.0) + seed));
		rough = 0.95;
	} else if (mode == 5) {
		col = vec3(0.78, 0.8, 0.82);
		metal = 1.0;
		rough = 0.2 + 0.2 * noise2(uv * 30.0);
	} else if (mode == 6) {
		float tread = step(0.5, fract(uv.x * 12.0));
		col = vec3(0.05) * (0.8 + 0.3 * tread);
		rough = 0.9;
	} else if (mode == 7) {
		// une vitre : le ciel s'y reflète, un rideau de couleur derrière (selon la vitre)
		col = mix(vec3(0.1, 0.13, 0.16), vec3(0.45, 0.3, 0.5), step(0.6, h1(floor(wpos.x * 1.3) + floor(wpos.z * 1.3) * 7.0)) * 0.6);
		metal = 0.65;
		rough = 0.05;
	} else {
		// une toile tendue (les auvents, le fond de la scène) : un tissage, des plis
		float f = fbm(uv * 1.5 + seed);
		col = color * (0.86 + 0.2 * f);
		col = mix(col, color2, step(0.5, fract(uv.x / 1.2)) * 0.5);
		rough = 0.92;
	}
	ALBEDO = col;
	METALLIC = metal;
	ROUGHNESS = rough;
	AO = ao;
	AO_LIGHT_AFFECT = 0.3;
}

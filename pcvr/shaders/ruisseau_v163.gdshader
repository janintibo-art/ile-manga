// V163 : les ruisseaux du royaume des fées. Une eau claire et peu profonde qui court : on voit le lit de
// galets au fond (chacun sa couleur, déformé par les rides), plus profond et plus vert au milieu ; les
// rides qui descendent le courant (deux couches de bruit qui glissent), des filets d'écume, les bords
// qui s'effacent dans l'herbe. Le mesh : u en travers (0 à 1), v le long (0 à 1 sur toute la longueur).
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float longueur = 40.0;
uniform float largeur = 3.3;
uniform float vitesse = 0.9;
uniform vec3 eau : source_color = vec3(0.3, 0.5, 0.48);

varying vec3 wpos;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float rides(vec2 p, float t) {
	return bruit(vec2(p.x * 2.4, (p.y - t) * 1.2)) * 0.6 + bruit(vec2(p.x * 5.1 + 3.0, (p.y - t * 1.35) * 2.6)) * 0.4;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * largeur, UV.y * longueur);
	float t = TIME * vitesse;
	float e = 0.06;
	float r0 = rides(p, t);
	float rx = rides(p + vec2(e, 0.0), t);
	float ry = rides(p + vec2(0.0, e), t);
	vec2 g = vec2(rx - r0, ry - r0) / e;
	float bord = abs(UV.x - 0.5) * 2.0;
	float prof = 1.0 - bord * bord;
	// le lit de galets (dans le monde), vu à travers les rides
	vec2 q = wpos.xz * 4.0 + g * 0.02;
	vec2 qi = floor(q);
	vec2 qf = fract(q);
	float dmin = 9.0;
	float d2 = 9.0;
	vec2 cell = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 c = o + vec2(h2(qi + o), h2(qi + o + 5.3)) * 0.8 + 0.1;
			float d = length(c - qf);
			if (d < dmin) {
				d2 = dmin;
				dmin = d;
				cell = qi + o;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	float hc = h2(cell + 2.7);
	vec3 galet = mix(vec3(0.62, 0.6, 0.55), vec3(0.74, 0.66, 0.52), hc) * (0.82 + 0.3 * h2(cell + 9.1));
	galet = mix(galet, vec3(0.42, 0.46, 0.38), step(0.85, h2(cell + 4.4)) * 0.5);
	float joint = smoothstep(0.0, 0.12, d2 - dmin);
	vec3 fond = galet * mix(0.62, 1.0, joint);
	// les reflets du soleil au fond (les caustiques des rides)
	fond *= 0.9 + 0.35 * smoothstep(0.6, 0.85, r0);
	vec3 c = mix(fond * mix(1.0, 0.72, prof), eau, 0.2 + 0.3 * prof);
	// le ciel dans l'eau, de plus en plus quand on la regarde de biais
	vec3 V = normalize(CAMERA_POSITION_WORLD - wpos);
	float fres = 0.06 + 0.7 * pow(1.0 - clamp(abs(V.y), 0.0, 1.0), 4.0);
	c = mix(c, vec3(0.7, 0.8, 0.86), fres * (0.8 + 0.4 * r0));
	// l'écume : des filets qui descendent, plus près des bords
	float ecume = smoothstep(0.8, 0.95, rides(p * vec2(1.6, 0.7) + 7.0, t * 1.6)) * (0.25 + 0.6 * smoothstep(0.55, 0.95, bord));
	c = mix(c, vec3(0.9, 0.95, 0.95), ecume * 0.6);
	ALBEDO = c;
	ALPHA = smoothstep(1.0, 0.8, bord) * mix(0.8, 0.95, prof);
	NORMAL_MAP = normalize(vec3(-g.x * 0.25, -g.y * 0.25, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.05;
	SPECULAR = 0.62;
}

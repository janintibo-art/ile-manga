// V160 : les coraux qui luisent (le Dôme d'Azur, le Jardin des Coraux). Le corail est couvert de polypes :
// de petites coupes plus claires, au cœur sombre, qui s'allument (la bioluminescence) ; la couleur varie
// d'une branche à l'autre, plus profonde dans les creux ; le bord des branches, vu de biais, luit. Les
// polypes sont posés dans l'espace (pas besoin d'UV : les coraux sont regroupés en un seul maillage) ; au
// loin, ils se fondent (pas de scintillement). La lueur respire doucement.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 couleur : source_color = vec3(1.0, 0.4, 0.62);
uniform float force = 0.9;
uniform float densite = 26.0;           // des polypes par mètre

varying vec3 wp;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float bruit3(vec3 p) {
	vec3 a = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(h3(a), h3(a + vec3(1.0, 0.0, 0.0)), f.x);
	float x10 = mix(h3(a + vec3(0.0, 1.0, 0.0)), h3(a + vec3(1.0, 1.0, 0.0)), f.x);
	float x01 = mix(h3(a + vec3(0.0, 0.0, 1.0)), h3(a + vec3(1.0, 0.0, 1.0)), f.x);
	float x11 = mix(h3(a + vec3(0.0, 1.0, 1.0)), h3(a + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float facing = clamp(dot(n, normalize(VIEW)), 0.0, 1.0);
	float fres = pow(1.0 - facing, 2.2);
	// les polypes : une coupe par case, un peu décalée
	vec3 q = wp * densite;
	vec3 c = floor(q);
	vec3 f = fract(q) - 0.5;
	vec3 j = vec3(h3(c), h3(c + 1.7), h3(c + 3.3)) - 0.5;
	float d = length(f - j * 0.35);
	float rr = 0.2 + 0.12 * h3(c + 5.1);
	float aa = fwidth(d) + 0.02;
	float polype = 1.0 - smoothstep(rr - aa, rr + aa, d);
	float bouche = 1.0 - smoothstep(rr * 0.25, rr * 0.5 + aa, d);
	float loin = smoothstep(0.25, 0.7, fwidth(q.x) + fwidth(q.y));
	polype = mix(polype, 0.35, loin);
	bouche = mix(bouche, 0.08, loin);
	// la couleur : d'une branche à l'autre, plus profonde dans les creux
	float m = bruit3(wp * 1.3);
	float g = bruit3(wp * 5.0);
	vec3 base = couleur * mix(0.35, 0.75, m) * mix(0.7, 1.0, g);
	vec3 clair = mix(couleur, vec3(1.0), 0.35);
	ALBEDO = mix(base, clair * 0.8, polype * (1.0 - bouche) * 0.45) * (1.0 - 0.45 * bouche * polype);
	ROUGHNESS = 0.72;
	SPECULAR = 0.35;
	float souffle = 0.85 + 0.15 * sin(TIME * 0.5 + m * 6.0);
	EMISSION = couleur * force * souffle * (0.14 + 0.4 * polype * (1.0 - bouche) + 0.7 * fres) * mix(0.7, 1.1, m);
}

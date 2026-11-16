// V161 : les géraniums des jardinières de l'Île des Géants (à l'échelle des géants). Chaque touffe est une
// boule : le shader y pose les fleurs. « feuille » = 0 : l'ombelle, faite de petites fleurs à cinq pétales,
// leur cœur plus clair, des boutons, de l'ombre entre elles ; « feuille » = 1 : les feuilles rondes et
// festonnées, la bande sombre en fer à cheval (le « zonal » des géraniums), les nervures qui rayonnent.
// Posé dans l'espace (les touffes sont regroupées en un seul maillage) ; au loin, tout se fond.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 couleur : source_color = vec3(0.86, 0.1, 0.12);
uniform float feuille = 0.0;
uniform float densite = 6.0;

varying vec3 wp;
varying vec3 wn;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	vec3 t = normalize(cross(n, abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 b = cross(n, t);
	vec3 q = wp * densite;
	vec3 c = floor(q);
	vec3 f = fract(q) - 0.5;
	vec3 j = vec3(h3(c), h3(c + 1.7), h3(c + 3.3)) - 0.5;
	vec3 d = f - j * 0.3;
	vec2 p = vec2(dot(d, t), dot(d, b));
	float r = length(p);
	float a = atan(p.y, p.x) + h3(c + 5.5) * 6.2831;
	float hs = h3(c + 9.1);
	float loin = smoothstep(0.3, 0.8, fwidth(q.x) + fwidth(q.y));
	vec3 col;
	vec3 em = vec3(0.0);
	float rough = 0.7;
	if (feuille < 0.5) {
		// une fleur à cinq pétales, son cœur ; parfois un bouton
		float bord = 0.36 * (0.72 + 0.28 * pow(abs(cos(a * 2.5)), 0.6));
		float aa = fwidth(r) + 0.02;
		float petale = 1.0 - smoothstep(bord - aa, bord + aa, r);
		float coeur = 1.0 - smoothstep(0.05, 0.08, r);
		float bouton = step(0.8, hs) * (1.0 - smoothstep(0.12, 0.15, r));
		vec3 fond = couleur * 0.28;
		vec3 pet = couleur * (0.85 + 0.25 * (1.0 - r / 0.36)) * (0.9 + 0.2 * hs);
		col = mix(fond, pet, petale);
		col = mix(col, mix(couleur, vec3(1.0, 0.95, 0.85), 0.55), coeur * petale * 0.8);
		col = mix(col, couleur * 0.6 + vec3(0.05, 0.12, 0.02), bouton);
		col = mix(col, couleur * 0.65, loin);
		rough = 0.62;
		em = couleur * 0.04 * petale;
	} else {
		// une feuille ronde et festonnée, la bande sombre, les nervures
		float bord = 0.44 * (0.92 + 0.08 * cos(a * 9.0));
		float aa = fwidth(r) + 0.02;
		float lim = 1.0 - smoothstep(bord - aa, bord + aa, r);
		float zone = smoothstep(0.2, 0.24, r) * (1.0 - smoothstep(0.3, 0.34, r)) * step(0.35, hs);
		float nerv = 1.0 - smoothstep(0.0, 0.08, abs(fract(a * 7.0 / 6.2831) - 0.5) * 2.0 - 0.88);
		vec3 vert = mix(vec3(0.16, 0.34, 0.1), vec3(0.24, 0.44, 0.13), hs);
		col = mix(vert * 0.25, vert, lim);
		col = mix(col, vec3(0.2, 0.16, 0.07), zone * lim * 0.6);
		col = mix(col, vert * 1.3, nerv * lim * 0.35);
		col = mix(col, vec3(0.15, 0.3, 0.09), loin);
		rough = 0.55;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
	EMISSION = em;
}

// Extension « Le Château d'Ombrelac » : les métaux (v11), dans l'espace du monde. Le fer forgé (martelé,
// un peu de rouille dans les creux), l'or et le laiton (polis, un peu ternis), le bronze et le cuivre
// (le vert-de-gris dans les creux). Le métal n'est jamais d'une seule teinte : des zones plus usées,
// plus brillantes, là où on le touche ; des traces de martelage ; de petites rayures.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

uniform vec3 teinte = vec3(0.12, 0.12, 0.13);
uniform float metal = 0.85;
uniform float rugosite = 0.55;
uniform float martele = 1.0;           // les coups de marteau (le fer forgé)
uniform float rouille = 0.0;           // la rouille dans les creux
uniform vec3 couleur_rouille = vec3(0.32, 0.14, 0.06);
uniform float patine = 0.0;            // le vert-de-gris (bronze, cuivre)
uniform float terni = 0.0;             // l'or et le laiton un peu ternis

varying vec3 wp;
varying vec3 wn;

float h3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float n3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// les coups de marteau : des facettes rondes (la distance à des points au hasard)
float coups(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d = 1.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 o = vec3(float(x), float(y), float(z));
				vec3 c = o + vec3(h3(i + o), h3(i + o + 3.1), h3(i + o + 7.7));
				d = min(d, length(f - c));
			}
		}
	}
	return d;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(2.0, 14.0, dist);
	float grand = n3(wp * 2.2);
	float creux = smoothstep(0.45, 0.75, n3(wp * 7.0 + 3.0));
	vec3 col = teinte * (0.85 + 0.3 * grand);
	float r = rugosite + (grand - 0.5) * 0.18;
	// la rouille, dans les creux
	float ro = rouille * creux * smoothstep(0.3, 0.7, n3(wp * 19.0));
	col = mix(col, couleur_rouille * (0.7 + 0.5 * n3(wp * 40.0)), ro);
	float met = mix(metal, 0.0, ro);
	r = mix(r, 0.9, ro);
	// le vert-de-gris
	float pa = patine * smoothstep(0.35, 0.7, n3(wp * 5.0 + 9.0)) * (0.6 + 0.4 * creux);
	col = mix(col, vec3(0.24, 0.5, 0.42) * (0.8 + 0.3 * n3(wp * 30.0)), pa);
	met = mix(met, 0.1, pa);
	r = mix(r, 0.85, pa);
	// l'or terni : plus sombre et plus mat par endroits
	col *= 1.0 - terni * 0.35 * creux;
	r += terni * 0.25 * creux;
	// de fines rayures
	float ray = smoothstep(0.97, 0.995, n3(vec3(wp.x * 90.0, wp.y * 4.0, wp.z * 90.0))) * fin;
	r -= ray * 0.2;
	ALBEDO = col;
	METALLIC = met;
	ROUGHNESS = clamp(r, 0.05, 1.0);
	// le relief : le martelage
	if (martele > 0.0 && fin > 0.01) {
		float e = 0.004;
		float s = 38.0;
		float c0 = coups(wp * s);
		vec3 g = vec3(coups((wp + vec3(e, 0, 0)) * s) - c0, coups((wp + vec3(0, e, 0)) * s) - c0, coups((wp + vec3(0, 0, e)) * s) - c0) / e;
		g -= dot(g, n) * n;
		n = normalize(n - g * 0.0025 * martele * fin);
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
}

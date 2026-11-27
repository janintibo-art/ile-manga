// V217 : la sauce tomate sur le personnage, quand il est tombé dans la sauce de l'Île Al Dente (ou sous la
// Cascade Arrabbiata). Une couche posée par-dessus sa matière (material_overlay) : des plaques de sauce
// brillante, plus épaisses au milieu, étirées (elle coule), avec des morceaux de tomate, du basilic et des
// grains d'herbes. Le motif est collé au corps : sur le corps du héros, il est tracé dans ses coordonnées
// de texture (UV : il suit la peau quand le héros bouge) ; sur les mains de la VR (des pièces séparées), dans
// le repère de la main (« repere » : l'inverse de sa place, donné par le script). Plus il y a de sauce, plus
// les plaques sont grandes ; en séchant, elles rétrécissent et s'en vont.
// (render_priority est mis haut par le script : le corps du héros est dessiné avec les objets transparents,
// et la sauce doit passer après lui.)
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, diffuse_burley, specular_schlick_ggx;

uniform float quantite : hint_range(0.0, 1.0) = 0.0;
uniform float grain = 9.0;
uniform float epaisseur = 0.004;          // en mètres
uniform int espace = 0;                   // 0 : les UV du maillage ; 1 : le repère de la main (repere)
uniform mat4 repere = mat4(1.0);

varying vec3 lp;

float h31(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vn(vec3 p) {
	vec3 a = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(a), h31(a + vec3(1, 0, 0)), f.x), mix(h31(a + vec3(0, 1, 0)), h31(a + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h31(a + vec3(0, 0, 1)), h31(a + vec3(1, 0, 1)), f.x), mix(h31(a + vec3(0, 1, 1)), h31(a + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	float s = max(length(MODEL_MATRIX[1].xyz), 0.00001);
	if (espace == 0) {
		lp = vec3(UV, 0.37);
	} else {
		lp = (repere * (MODEL_MATRIX * vec4(VERTEX, 1.0))).xyz;
	}
	// la couche a quelques millimètres d'épaisseur : elle passe devant la peau sans se battre avec elle
	VERTEX += NORMAL * (epaisseur / s);
}

void fragment() {
	vec3 q = lp * grain;
	float n = vn(q * vec3(1.0, 0.42, 1.0)) * 0.6 + vn(q * 2.6 + 5.0) * 0.4;
	float seuil = 1.0 - 0.6 * pow(max(quantite, 0.0), 0.8);
	float m = smoothstep(seuil, seuil + 0.06, n);
	if (m <= 0.002) {
		discard;
	}
	float epais = smoothstep(seuil, seuil + 0.3, n);
	float fin = vn(q * 5.0);
	// une sauce tomate (pas autre chose) : rouge-orangé, épaisse, des morceaux de tomate plus clairs, des
	// feuilles de basilic et des grains d'herbes bien visibles
	float morceau = step(0.8, vn(q * 3.1 + 17.0)) * step(0.35, epais);
	float basilic = step(0.9, vn(q * 2.2 + 41.0)) * step(0.5, epais);
	float herbe = step(0.86, vn(q * 7.3 + 3.0));
	vec3 col = mix(vec3(0.8, 0.24, 0.06), vec3(0.6, 0.11, 0.03), epais);
	col *= mix(1.0, 0.85, fin);
	col = mix(col, vec3(0.9, 0.33, 0.12), morceau * 0.75);
	col = mix(col, vec3(0.12, 0.27, 0.06), basilic * 0.9);
	col = mix(col, vec3(0.16, 0.15, 0.04), herbe * 0.8);
	ALBEDO = col;
	ALPHA = m * mix(0.7, 0.98, epais) * clamp(quantite * 4.0, 0.0, 1.0);
	ROUGHNESS = mix(0.34, 0.13, epais);
	SPECULAR = 0.55;
}

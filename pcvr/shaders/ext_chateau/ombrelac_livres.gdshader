// Extension « Le Château d'Ombrelac » : les livres sur un rayon. Un seul quad par rayon : UV.x le
// long du rayon (en mètres), UV.y de 0 (le bas) à 1 (le rayon du dessus) ; UV2 : une graine par rayon.
// Des dos de cuir de largeurs et de hauteurs inégales (bordeaux, vert, bleu, fauve, noir), les
// nerfs et les filets dorés, une pièce de titre ; parfois un vide, un livre couché.
shader_type spatial;
render_mode cull_back, diffuse_burley;

varying vec2 graine;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	graine = UV2;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	// des largeurs inégales : une grille de 4 cm qu'on déforme doucement
	float x = u / 0.042 + sin(u * 3.1 + graine.x) * 0.8 + graine.y * 13.0;
	float id = floor(x);
	float f = fract(x);
	vec2 k = vec2(id, graine.x * 7.3 + graine.y);
	float r = h(k);
	float hb = 0.62 + 0.3 * h(k + 7.1);
	bool vide = h(k + 3.3) < 0.035;
	bool couche = h(k + 5.9) < 0.02;
	vec3 cuir;
	float p = h(k + 1.7);
	if (p < 0.22) cuir = vec3(0.34, 0.06, 0.05);
	else if (p < 0.38) cuir = vec3(0.07, 0.19, 0.11);
	else if (p < 0.52) cuir = vec3(0.06, 0.09, 0.23);
	else if (p < 0.72) cuir = vec3(0.3, 0.16, 0.07);
	else if (p < 0.82) cuir = vec3(0.55, 0.38, 0.2);
	else if (p < 0.9) cuir = vec3(0.05, 0.045, 0.045);
	else cuir = vec3(0.5, 0.3, 0.09);
	cuir *= 0.7 + 0.45 * r;
	float livre = step(v, hb) * (vide ? 0.0 : 1.0);
	if (couche) {
		livre = step(v, 0.14);
	}
	// le dos arrondi : plus sombre sur les bords
	float rond = sqrt(max(sin(f * 3.14159), 0.0));
	vec3 c = cuir * (0.45 + 0.55 * rond);
	// les nerfs, les filets dorés, la pièce de titre
	float vv = v / max(hb, 0.01);
	float orne = 0.0;
	float nerf = 0.0;
	if (h(k + 9.2) < 0.6) {
		for (int i = 0; i < 4; i++) {
			float y = 0.18 + float(i) * 0.2;
			nerf = max(nerf, 1.0 - smoothstep(0.0, 0.018, abs(vv - y)));
		}
		orne = max(orne, step(abs(vv - 0.08), 0.008) + step(abs(vv - 0.92), 0.008));
	}
	float titre = step(abs(vv - 0.72), 0.06) * step(0.5, h(k + 4.4)) * step(0.2, f) * step(f, 0.8);
	c = mix(c, c * 0.55 + vec3(0.03), titre * 0.6);
	orne = max(orne, titre * step(abs(abs(vv - 0.72) - 0.055), 0.006));
	orne = max(orne, titre * step(abs(vv - 0.72), 0.012) * step(abs(f - 0.5), 0.22));
	c = mix(c, vec3(0.85, 0.63, 0.25), clamp(orne, 0.0, 1.0));
	c *= 1.0 + nerf * 0.35;
	// au-dessus des livres : l'ombre du rayon
	vec3 fond = vec3(0.025, 0.02, 0.016) * (0.6 + 0.8 * v);
	ALBEDO = mix(fond, c, livre);
	METALLIC = orne * livre * 0.75;
	ROUGHNESS = mix(0.95, mix(0.62, 0.3, orne), livre);
	NORMAL_MAP = normalize(vec3((f - 0.5) * 1.6 * livre, nerf * 0.3 * livre, 1.0)) * 0.5 + 0.5;
	AO = mix(0.5, 1.0, livre * rond);
}

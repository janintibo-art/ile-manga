// Extension « Le Château d'Ombrelac » : les fenêtres. UV de 0 à 1 sur la baie (v vers le haut).
// Des petits carreaux en losanges sertis de plomb ; le verre ancien, un peu ondulé, reflète le ciel
// le jour ; le soir, la plupart des fenêtres s'allument (une lumière chaude de bougies qui vacille
// un peu), d'autres restent noires. « vitrail » : des verres de couleur (la Grande Salle, la rose).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float nuit = 0.0;              // 0 le jour, 1 la nuit
uniform float allumees = 0.75;         // la part des fenêtres allumées la nuit
uniform bool vitrail = false;
uniform float carreaux = 7.0;          // losanges sur la largeur
uniform float aspect = 2.5;            // hauteur / largeur de la baie
uniform vec3 lumiere : source_color = vec3(1.0, 0.68, 0.32);

varying vec3 wp;
varying vec3 wn;
varying vec3 centre;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// UV2 : le centre de la baie (pour que toute la fenêtre s'allume d'un coup)
	centre = vec3(UV2.x, 0.0, UV2.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 g = vec2(uv.x * carreaux, uv.y * carreaux * aspect);
	// les losanges : la grille tournée de 45°
	vec2 d = vec2(g.x + g.y, g.x - g.y) * 0.5;
	vec2 f = fract(d);
	vec2 cell = floor(d);
	float plomb = 1.0 - smoothstep(0.02, 0.07, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
	// le cadre et les meneaux (un montant au milieu, une traverse aux deux tiers)
	float cadre = 1.0 - smoothstep(0.0, 0.035, min(min(uv.x, 1.0 - uv.x), uv.y));
	float meneau = 1.0 - smoothstep(0.012, 0.022, abs(uv.x - 0.5));
	float trav = 1.0 - smoothstep(0.008, 0.016, abs(uv.y - 0.62)) ;
	float fer = max(max(plomb, cadre), max(meneau, trav * 0.9));
	float r = h2(cell);
	vec3 verre;
	if (vitrail) {
		// des verres de couleur profonds : surtout du bleu, un peu de rouge, d'or, de vert, de pourpre
		vec3 c1 = vec3(0.06, 0.12, 0.38);
		vec3 c2 = vec3(0.42, 0.06, 0.06);
		vec3 c3 = vec3(0.55, 0.38, 0.08);
		vec3 c4 = vec3(0.06, 0.26, 0.14);
		vec3 c5 = vec3(0.24, 0.08, 0.32);
		verre = r < 0.5 ? c1 : (r < 0.66 ? c2 : (r < 0.78 ? c3 : (r < 0.9 ? c4 : c5)));
		verre *= 0.75 + 0.5 * h2(cell * 3.1);
	} else {
		verre = mix(vec3(0.16, 0.2, 0.22), vec3(0.24, 0.28, 0.27), r);
	}
	// la nuit : la fenêtre est-elle allumée ?
	float on = step(h3(floor(centre * 0.5) + 0.37), allumees) * nuit;
	float vacille = 0.85 + 0.15 * sin(TIME * 7.0 + r * 30.0) * sin(TIME * 2.3 + centre.x);
	vec3 dedans = lumiere * (0.6 + 0.6 * r) * vacille;
	if (vitrail) {
		dedans = (verre * 2.2 + lumiere * 0.06) * vacille / 3.2;
	}
	// le jour, un vitrail laisse voir ses couleurs (un peu de lumière dedans), un verre clair reflète
	float jour = 1.0 - nuit;
	ALBEDO = mix(vitrail ? verre * 0.7 : verre, vec3(0.06, 0.06, 0.07), fer);
	METALLIC = mix(vitrail ? 0.0 : 0.6, 0.3, fer);
	ROUGHNESS = mix(0.08 + r * 0.12, 0.6, fer);
	SPECULAR = 0.7;
	EMISSION = (dedans * on * 3.2 + (vitrail ? verre * 0.12 * jour : vec3(0.0))) * (1.0 - fer);
	// vue du dedans (la face arrière) : le jour passe à travers, les vitraux flamboient ; la nuit,
	// le verre est noir (la lumière est dedans)
	if (!FRONT_FACING) {
		vec3 clair = vec3(0.62, 0.68, 0.74) * (0.8 + 0.4 * r);
		vec3 trans = vitrail ? verre * 3.2 : clair * 0.9;
		ALBEDO = mix(vec3(0.02), vec3(0.06, 0.06, 0.07), fer);
		METALLIC = 0.2;
		EMISSION = trans * jour * (1.0 - fer);
	}
	// le verre ancien : les reflets ondulent un peu d'un carreau à l'autre
	NORMAL_MAP = normalize(vec3((r - 0.5) * 0.25, (h2(cell + 5.0) - 0.5) * 0.25, 1.0)) * 0.5 + 0.5;
}

shader_type spatial;
// V219 : une poussière lumineuse (une braise, une paillette de givre, une étincelle électrique) : un point
// doux, un halo, qui scintille. Aucun trait dur. Elle fait face au regard ; « etire » > 1 : elle s'allonge un
// peu dans le sens de sa course (la particule doit alors être alignée sur sa vitesse). « etoile » : quatre
// rayons très fins, pour les paillettes de givre.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled, world_vertex_coords;

uniform float intensite = 3.0;
uniform float etire = 1.0;
uniform float scintille = 0.5;
uniform float etoile = 0.0;

varying float age;
varying float graine;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	graine = fract(float(INSTANCE_ID) * 0.618034);
	vec3 centre = MODEL_MATRIX[3].xyz;
	float taille = length(MODEL_MATRIX[0].xyz);
	vec3 oeil = normalize(CAMERA_POSITION_WORLD - centre);
	vec3 axe = normalize(INV_VIEW_MATRIX[1].xyz);
	if (etire > 1.001) {
		axe = normalize(MODEL_MATRIX[1].xyz);
	}
	vec3 cote = cross(axe, oeil);
	float l = length(cote);
	cote = l > 0.001 ? cote / l : normalize(INV_VIEW_MATRIX[0].xyz);
	vec2 coin = UV - vec2(0.5);
	VERTEX = centre + cote * coin.x * taille - axe * coin.y * taille * etire;
}

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float r = length(uv);
	float coeur = exp(-r * r * 14.0);
	float halo = pow(max(1.0 - r, 0.0), 3.0) * 0.55;
	float rayons = (exp(-abs(uv.x) * 26.0) + exp(-abs(uv.y) * 26.0)) * pow(max(1.0 - r, 0.0), 2.0) * etoile;
	float clin = 1.0 - scintille + scintille * (0.5 + 0.5 * sin(TIME * (14.0 + graine * 22.0) + graine * 50.0));
	float vie = smoothstep(0.0, 0.06, age) * (1.0 - smoothstep(0.55, 1.0, age));
	ALBEDO = COLOR.rgb * intensite * clin;
	ALPHA = clamp(coeur + halo + rayons, 0.0, 1.0) * COLOR.a * vie;
}

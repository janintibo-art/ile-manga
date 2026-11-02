// V99 : le trait de contour des objets de l'Île Crayonnée (passe suivante de leur matériau) : la
// même forme, un peu gonflée, vue de dos, à l'encre noire. L'épaisseur reste la même à l'écran
// (elle grandit avec la distance) ; elle s'efface là où l'île a retrouvé ses couleurs, et au loin.
shader_type spatial;
render_mode cull_front, unshaded, world_vertex_coords, shadows_disabled, ambient_light_disabled;

#include "res://shaders/crayon_v99.gdshaderinc"

uniform float largeur = 1.0;

void vertex() {
	float d = length(CAMERA_POSITION_WORLD - VERTEX);
	float c = cr_couleur(VERTEX);
	float w = clamp(d * 0.0022, 0.012, 0.09) * largeur * (1.0 - c) * (1.0 - smoothstep(150.0, 240.0, d));
	VERTEX += normalize(NORMAL) * w;
}

void fragment() {
	ALBEDO = vec3(0.075, 0.068, 0.062);
}

// V162 : les caustiques sous le dôme de l'Atlantide : la lumière de la surface, 30 m plus haut, passe
// par les vagues et dessine sur le sol des réseaux de lignes claires qui ondulent sans fin. Un disque
// posé juste au-dessus de la mosaïque, qui s'ajoute à la lumière (deux couches de la même texture,
// qui glissent dans deux sens) ; elles s'effacent vers le bord du dôme.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D caustic_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 couleur : source_color = vec3(0.45, 0.85, 1.0);
uniform float force = 0.22;
uniform vec3 centre = vec3(0.0);
uniform float rayon = 44.0;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	float c1 = texture(caustic_tex, p * 0.09 + vec2(TIME * 0.018, TIME * 0.011)).r;
	float c2 = texture(caustic_tex, p * 0.067 - vec2(TIME * 0.013, -TIME * 0.016)).r;
	float c = c1 * 0.6 + c2 * 0.6;
	c = c * c;
	float fade = 1.0 - smoothstep(rayon * 0.75, rayon, length(p - centre.xz));
	ALBEDO = couleur * c * force * fade;
}

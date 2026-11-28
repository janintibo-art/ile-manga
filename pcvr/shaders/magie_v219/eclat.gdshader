shader_type spatial;
// V219 : l'éclat d'une explosion, d'un éclair : un disque de lumière qui fait face au regard, très vif au
// centre, fondu au bord. « force » descend de 1 à 0 pendant sa courte vie.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec3 couleur : source_color = vec3(1.0, 0.8, 0.45);
uniform float intensite = 8.0;
uniform float force = 1.0;

void vertex() {
	mat4 monde = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * monde;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float a = pow(max(1.0 - r, 0.0), 2.2);
	float coeur = pow(max(1.0 - r * 2.2, 0.0), 1.5);
	ALBEDO = (couleur + vec3(1.0) * coeur) * intensite * force;
	ALPHA = clamp(a * force, 0.0, 1.0);
}

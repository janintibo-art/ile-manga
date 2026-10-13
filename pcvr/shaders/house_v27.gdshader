// V27 : matériau des maisons (identique au modèle d'origine : couleur, relief, rugosité, métal)
// avec une ouverture découpée à la forme exacte de la porte peinte dans la texture.
// Coordonnées de l'ouverture dans le repère du modèle : x = largeur, y = hauteur, z = profondeur du mur.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float metallic_value = 1.0;
uniform float roughness_value = 1.0;
uniform vec2 hole_x = vec2(0.0, 0.0);       // bords gauche / droit de la porte
uniform vec2 hole_z = vec2(0.0, 0.0);       // épaisseur du mur traversée
uniform float hole_bottom = 0.0;
uniform float hole_spring = 0.0;            // naissance de l'arc
uniform float hole_apex = 0.0;              // sommet de l'arc

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

bool in_hole(vec3 p) {
	if (hole_apex <= hole_bottom) {
		return false;
	}
	if (p.z < hole_z.x || p.z > hole_z.y || p.x < hole_x.x || p.x > hole_x.y || p.y < hole_bottom || p.y > hole_apex) {
		return false;
	}
	if (p.y <= hole_spring) {
		return true;
	}
	float cx = (hole_x.x + hole_x.y) * 0.5;
	float hw = (hole_x.y - hole_x.x) * 0.5;
	float u = (p.x - cx) / hw;
	float v = (p.y - hole_spring) / max(hole_apex - hole_spring, 0.0001);
	return u * u + v * v < 1.0;
}

void fragment() {
	if (in_hole(local_pos)) {
		discard;
	}
	ALBEDO = texture(albedo_tex, UV).rgb;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	vec4 orm = texture(orm_tex, UV);
	ROUGHNESS = orm.g * roughness_value;
	METALLIC = orm.b * metallic_value;
}

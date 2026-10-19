// V55 : les poissons des bancs (MultiMesh). Chaque instance : INSTANCE_CUSTOM = (phase, espèce
// 0..7 / 8, vitesse, 0). La queue ondule (plus fort vers l'arrière), la texture vient de
// l'atlas mer/poissons.png (4 x 2 espèces de profil, alpha autour de la silhouette).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float wiggle = 0.13;

varying flat float species;

void vertex() {
	float along = -VERTEX.z + 0.5;              // 0 à la queue, 1 au museau
	float w = pow(clamp(1.0 - along, 0.0, 1.0), 1.6);
	float beat = TIME * 10.0 * (0.6 + INSTANCE_CUSTOM.b) + INSTANCE_CUSTOM.r * 6.2832;
	VERTEX.x += sin(beat - along * 4.5) * wiggle * w;
	species = floor(INSTANCE_CUSTOM.g * 8.0 + 0.5);
}

void fragment() {
	vec2 cell = vec2(mod(species, 4.0), floor(species / 4.0));
	vec4 c = texture(atlas, (cell + UV) / vec2(4.0, 2.0));
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 0.35;
	METALLIC = 0.15;
	SPECULAR = 0.65;
	BACKLIGHT = c.rgb * 0.25;
}

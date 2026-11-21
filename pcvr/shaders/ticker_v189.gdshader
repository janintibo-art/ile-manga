// V189 : le bandeau des cours de la Tour Vertex : une ligne de texte lumineux qui défile autour de l'immeuble,
// faite de petits points comme un journal lumineux.
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D image : source_color, filter_linear_mipmap, repeat_enable;
uniform float vitesse = 0.012;
uniform float force = 1.5;
uniform float nuit : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = vec2(UV.x + TIME * vitesse, UV.y);
	vec3 c = texture(image, uv).rgb;
	// la trame de points
	vec2 g = fract(vec2(uv.x * 4096.0 / 6.0, UV.y * 128.0 / 6.0)) - 0.5;
	float pt = smoothstep(0.5, 0.3, length(g));
	ALBEDO = (c * (0.35 + 0.65 * pt) + vec3(0.004, 0.006, 0.01)) * force * (0.55 + 0.75 * nuit);
}

shader_type spatial;
// V219 : la glace d'un cristal : bleu profond au pied, pâle à la pointe ; ses arêtes s'allument à
// contre-jour ; des paillettes y clignotent (UV.y : la hauteur le long du cristal, de 0 à 1).
render_mode cull_disabled, shadows_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 pied : source_color = vec3(0.14, 0.4, 0.86);
uniform vec3 pointe : source_color = vec3(0.8, 0.94, 1.0);
uniform float lueur = 0.9;

void fragment() {
	vec3 n = normalize(FRONT_FACING ? NORMAL : -NORMAL);
	float bord = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 2.2);
	vec3 base = mix(pied, pointe, smoothstep(0.0, 0.9, UV.y));
	ALBEDO = base * 0.85;
	ROUGHNESS = 0.07;
	SPECULAR = 0.85;
	float p = texture(bruit, UV * vec2(3.0, 5.0) + vec2(TIME * 0.05, 0.0)).r;
	float paillette = pow(max(p * 1.25 - 0.25 + 0.2 * sin(TIME * 7.0 + UV.y * 30.0 + UV.x * 40.0), 0.0), 7.0);
	// (sa lueur tire sur le bleu du pied : de nuit, le cristal reste bleu au lieu de blanchir)
	EMISSION = mix(pied, base, 0.45) * (0.24 + bord * 1.5) * lueur + pointe * paillette * 2.0;
	NORMAL = n;
}

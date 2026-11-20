// V187 : l'étage des serveurs de la Tour Kumo, vu de la rue : des persiennes de métal sombre, et derrière,
// des rangées de petites lumières qui clignotent (bleues, vertes, quelques-unes ambre), chacune à son rythme.
// UV en mètres.
shader_type spatial;
render_mode cull_back;

uniform float nuit : hint_range(0.0, 1.0) = 0.0;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// les lames : une tous les 14 cm
	float lame = fract(UV.y / 0.14);
	float ombre = smoothstep(0.0, 0.25, lame) * (1.0 - smoothstep(0.8, 1.0, lame));
	vec3 metal = vec3(0.11, 0.12, 0.14) * (0.5 + 0.5 * ombre);
	// les lumières : dans le creux entre deux lames, une tous les 9 cm
	vec2 g = vec2(floor(UV.x / 0.09), floor(UV.y / 0.14));
	float r = h2(g);
	float presente = step(0.45, r);
	float t = TIME * (0.6 + 2.5 * h2(g + 3.0));
	float clign = step(0.35, fract(t + r * 7.0)) * (0.5 + 0.5 * step(0.5, fract(t * 3.1 + r)));
	vec3 col = r > 0.93 ? vec3(1.0, 0.6, 0.1) : (r > 0.7 ? vec3(0.2, 1.0, 0.45) : vec3(0.2, 0.6, 1.0));
	vec2 f = vec2(fract(UV.x / 0.09) - 0.5, lame - 0.12);
	float point = smoothstep(0.2, 0.05, length(f * vec2(1.0, 1.6)));
	ALBEDO = metal;
	METALLIC = 0.7;
	ROUGHNESS = 0.45;
	EMISSION = col * point * presente * clign * mix(0.9, 3.2, nuit);
}

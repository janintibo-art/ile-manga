shader_type spatial;
// V219 : le cœur de la boule de feu : une sphère de matière en fusion, parcourue de veines plus claires qui
// défilent ; le bord rougeoie.
render_mode unshaded, shadows_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform float intensite = 7.0;

void fragment() {
	float n1 = texture(bruit, UV * vec2(2.0, 1.0) + vec2(TIME * 0.9, TIME * 0.35)).r;
	float n2 = texture(bruit, UV * vec2(4.0, 2.0) - vec2(TIME * 0.5, TIME * 1.1)).r;
	float n = n1 * 0.6 + n2 * 0.4;
	float bord = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	vec3 col = mix(vec3(1.0, 0.38, 0.04), vec3(1.0, 0.8, 0.35), smoothstep(0.3, 0.6, n));
	col = mix(col, vec3(1.0, 1.0, 0.9), smoothstep(0.6, 0.85, n));
	col = mix(col, vec3(1.0, 0.25, 0.02), bord * 0.7);
	ALBEDO = col * intensite;
}

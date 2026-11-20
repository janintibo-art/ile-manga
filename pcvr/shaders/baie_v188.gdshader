// V188 : la façade d'une rangée de baies de serveurs (Tour Kumo, 5e étage) : des tiroirs noirs, et sur chacun
// des voyants verts, bleus ou ambre ; certains clignotent, chacun à son rythme. UV.x : une baie par unité.
shader_type spatial;
render_mode cull_back;

uniform float tiroirs = 14.0;
uniform float voyants = 9.0;
uniform float force = 3.0;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = vec2(UV.x, UV.y);
	float baie = floor(uv.x);
	vec2 g = vec2(fract(uv.x) * voyants, uv.y * tiroirs);
	vec2 id = floor(g) + vec2(baie * 17.0, 0.0);
	vec2 f = fract(g);
	// le montant entre deux baies, la fente entre deux tiroirs
	float montant = step(0.035, fract(uv.x)) * step(fract(uv.x), 0.965);
	float fente = step(0.08, f.y);
	vec3 fond = vec3(0.025, 0.028, 0.034) * (0.6 + 0.4 * montant * fente);
	// un voyant : un petit point, en bas à gauche du tiroir pour la plupart
	float r = h2(id);
	float r2 = h2(id + 31.7);
	float allume = step(0.45, r);
	float clignote = mix(1.0, step(0.5, fract(TIME * (0.4 + r2 * 4.0) + r * 9.0)), step(0.55, r2));
	float d = length((f - vec2(0.5, 0.45)) * vec2(1.0, 0.75));
	float point = smoothstep(0.26, 0.12, d);
	vec3 c = mix(vec3(0.15, 1.0, 0.4), vec3(0.2, 0.6, 1.0), step(0.5, r2));
	c = mix(c, vec3(1.0, 0.6, 0.1), step(0.9, r));
	ALBEDO = fond;
	ROUGHNESS = 0.5;
	METALLIC = 0.6;
	EMISSION = c * point * allume * clignote * montant * fente * force;
}

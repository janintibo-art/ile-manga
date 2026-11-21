// Extension « Le Château d'Ombrelac » : les flammes (bougies, cheminée). Des quads croisés,
// UV de 0 à 1 (v vers le haut) ; UV2 : une graine par flamme, pour qu'elles ne dansent pas ensemble.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float force = 1.0;
uniform vec3 couleur : source_color = vec3(1.0, 0.42, 0.1);
uniform vec3 coeur : source_color = vec3(1.0, 0.86, 0.55);

varying float graine;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	graine = fract(UV2.x * 0.137 + UV2.y * 0.291);
}

void fragment() {
	float t = TIME * 2.4 + graine * 40.0;
	float y = UV.y;
	float n = bruit(vec2(UV.x * 4.0 + graine * 9.0, y * 3.5 - t * 1.6));
	float n2 = bruit(vec2(UV.x * 9.0, y * 7.0 - t * 2.7));
	float x = (UV.x - 0.5) * 2.0 + (n - 0.5) * 0.7 * y + sin(t * 1.3) * 0.08 * y;
	// la silhouette : large en bas, une pointe qui monte et se déchire
	float larg = 0.9 * pow(max(1.0 - y, 0.0), 0.75) * smoothstep(0.0, 0.18, y + 0.04);
	float f = smoothstep(larg, larg * 0.35, abs(x));
	f *= 1.0 - smoothstep(0.45, 0.95, y + (n2 - 0.5) * 0.35);
	vec3 col = mix(couleur, coeur, smoothstep(0.35, 0.85, f * (1.1 - y)));
	ALBEDO = col * f * force * 2.2;
}

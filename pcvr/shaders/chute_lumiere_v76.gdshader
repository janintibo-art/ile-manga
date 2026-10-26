// V76 : une chute de lumière d'Astralys : de l'eau irisée qui file du bord de l'île et tombe dans
// le vide ; des filets qui glissent vers le bas, des reflets d'arc-en-ciel, le bas qui se perd en
// brume.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform float speed = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 15731.743);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float streaks = vnoise(vec2(uv.x * 22.0, uv.y * 3.0 - t * 6.0)) * 0.6 + vnoise(vec2(uv.x * 50.0, uv.y * 7.0 - t * 11.0)) * 0.4;
	float edge = smoothstep(0.0, 0.25, uv.x) * smoothstep(1.0, 0.75, uv.x);
	float top = smoothstep(0.0, 0.03, uv.y);
	float fade = 1.0 - smoothstep(0.25, 1.0, uv.y);
	float a = streaks * edge * top * fade;
	vec3 c = mix(vec3(0.75, 0.9, 1.0), hue(fract(uv.y * 1.5 + uv.x * 0.3 - t * 0.2)), 0.35);
	ALBEDO = c * a * 0.9;
	ALPHA = a;
}

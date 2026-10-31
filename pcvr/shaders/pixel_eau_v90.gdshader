// V90 : l'eau du Lac des Long-Cous, en pixels (16 par mètre) : des teintes de bleu par petites
// vagues qui glissent, des reflets carrés qui scintillent ; à peine transparente.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform float px_per_m = 16.0;
uniform float rayon = 34.0;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vn(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(a), h21(a + vec2(1, 0)), f.x), mix(h21(a + vec2(0, 1)), h21(a + vec2(1, 1)), f.x), f.y);
}

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	if (length(lp.xz) > rayon) { discard; }
	vec2 p = lp.xz;
	vec2 pix = floor(p * px_per_m) / px_per_m;
	float t = TIME;
	float w = vn(pix * 0.6 + vec2(t * 0.25, t * 0.11)) * 0.6 + vn(pix * 1.7 - vec2(t * 0.18, -t * 0.22)) * 0.4;
	float band = floor(w * 4.0) / 4.0;
	vec3 deep = vec3(0.10, 0.33, 0.45);
	vec3 light = vec3(0.24, 0.55, 0.66);
	vec3 c = mix(deep, light, band);
	float sp = step(0.985, h21(floor(p * px_per_m) + floor(t * 2.0)));
	vec2 fw = fwidth(p * px_per_m);
	float near = clamp(1.6 - max(fw.x, fw.y), 0.0, 1.0);
	c = mix(mix(deep, light, 0.45), c, near);
	ALBEDO = c;
	EMISSION = vec3(0.8, 0.95, 1.0) * sp * near * 0.8;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
	ALPHA = 0.84;
}

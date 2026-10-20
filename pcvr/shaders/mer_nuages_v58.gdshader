// V58 : la mer de nuages sous le royaume des fées.
// Un grand disque vu de dessus : des bancs de nuages moutonnants qui dérivent lentement,
// dorés au soleil, rosés dans les creux ; ils s'effacent doucement vers l'horizon.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix;

uniform float radius = 1400.0;
uniform vec3 light_col : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 shade_col : source_color = vec3(0.86, 0.78, 0.9);
uniform vec3 gold_col : source_color = vec3(1.0, 0.86, 0.62);

varying vec3 wpos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x), mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise2(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz * 0.006;
	vec2 drift = vec2(TIME * 0.004, TIME * 0.0016);
	float big = fbm(p + drift);
	float small = fbm(p * 3.7 - drift * 2.0);
	float n = big * 0.75 + small * 0.25;
	// des bancs de nuages, avec çà et là un trou bleuté
	float body = smoothstep(0.28, 0.62, n);
	// le dessus des moutons accroche la lumière, les creux sont lilas
	float lit = smoothstep(0.45, 0.85, n + small * 0.2);
	vec3 col = mix(shade_col, light_col, lit);
	col = mix(col, gold_col, smoothstep(0.7, 0.95, n) * 0.35);
	float d = length(wpos.xz - NODE_POSITION_WORLD.xz) / radius;
	float edge = 1.0 - smoothstep(0.55, 1.0, d);
	ALBEDO = col;
	ALPHA = clamp(body * 0.1 + 0.9, 0.0, 1.0) * edge;
}

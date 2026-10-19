// V55 : le dôme d'air de l'Atlantide — une bulle immense, presque invisible de face, qui
// s'irise sur les bords (effet de Fresnel), parcourue de reflets de caustiques et d'un
// léger maillage hexagonal lumineux qui respire avec le Grand Cristal.
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_draw_never, shadows_disabled;

uniform sampler2D caustic_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.55, 0.9, 1.0);
uniform float glow = 0.35;           // 0.35 : le cristal faiblit ; 1.0 : il brille

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hex_edge(vec2 p) {
	p *= vec2(1.0, 1.1547);
	vec2 a = mod(p, vec2(1.0, 1.732)) - vec2(0.5, 0.866);
	vec2 b = mod(p + vec2(0.5, 0.866), vec2(1.0, 1.732)) - vec2(0.5, 0.866);
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	vec2 q = abs(g);
	float d = max(q.x * 0.866 + q.y * 0.5, q.y);
	return smoothstep(0.42, 0.5, d);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float facing = abs(dot(n, VIEW));
	float fres = pow(1.0 - facing, 3.0);
	// motif hexagonal en coordonnées sphériques (angle autour, hauteur)
	vec2 sph = vec2(atan(wpos.x + 220.0, wpos.z - 260.0) * 30.0, wpos.y * 1.3);
	float hex = hex_edge(sph * 0.5);
	float c = texture(caustic_tex, wpos.xz / 9.0 + vec2(TIME * 0.02, -TIME * 0.015)).r;
	float pulse = 0.85 + 0.15 * sin(TIME * 0.8);
	vec3 col = tint * (0.4 + 0.6 * glow);
	ALBEDO = col * (0.7 + fres * 0.9 + hex * 0.35 * glow * pulse) + vec3(0.3, 0.4, 0.4) * c;
	ALPHA = clamp(0.03 + fres * 0.55 + hex * 0.035 * glow * pulse + c * c * 0.08, 0.0, 0.75);
}

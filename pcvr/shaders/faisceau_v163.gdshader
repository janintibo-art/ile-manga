// V163 : le faisceau d'une lyre de la teuf, la nuit : un cône de lumière douce (les bords s'effacent,
// la lumière faiblit en s'éloignant de la lentille), un peu de poussière qui y danse. force suit le
// projecteur (teuf_decor_v163.suivre).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 couleur = vec3(1.0);
uniform float force : hint_range(0.0, 1.0) = 0.0;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

varying vec3 wpos;
varying vec3 wnrm;
varying vec3 axe;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	axe = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	vec3 V = normalize(CAMERA_POSITION_WORLD - wpos);
	// de côté : plus dense au milieu du cône ; dans l'axe (on regarde la lyre depuis la piste) : tout
	// le cône s'éclaire
	float bord = max(pow(abs(dot(normalize(wnrm), V)), 2.2), pow(abs(dot(axe, V)), 2.0) * 0.6);
	float loin = UV.y;
	float poussiere = 0.75 + 0.5 * bruit(vec2(UV.x * 18.0, loin * 9.0 - TIME * 0.35));
	float a = force * bord * pow(1.0 - loin, 1.6) * smoothstep(0.0, 0.04, loin) * poussiere * 0.5;
	ALBEDO = couleur;
	ALPHA = clamp(a, 0.0, 1.0);
}

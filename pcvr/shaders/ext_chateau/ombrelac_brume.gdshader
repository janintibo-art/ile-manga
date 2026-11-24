// Extension « Le Château d'Ombrelac » : la brume du Lac d'Ombre (v13). Des nappes basses qui
// glissent lentement sur l'eau, en lambeaux ; plus épaisses au milieu du lac, nulles près des rives
// (le bord du disque) ; elles s'effacent là où elles touchent la roche ou le sol (pas d'arête), et
// quand on est dedans. Éclairées comme le reste : grises la nuit, dorées au couchant.
shader_type spatial;
render_mode cull_disabled, depth_draw_never, shadows_disabled, diffuse_lambert_wrap, specular_disabled;

uniform vec3 teinte = vec3(0.86, 0.9, 0.94);
uniform float epaisseur = 0.35;
uniform float graine = 0.0;
uniform sampler2D tex_prof : hint_depth_texture, filter_linear_mipmap;

varying vec3 wp;
varying vec2 loc;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	return n2(p) * 0.5 + n2(p * 2.1 + 3.1) * 0.27 + n2(p * 4.3 + 7.7) * 0.15 + n2(p * 8.7) * 0.08;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	loc = UV;
}

void fragment() {
	float t = TIME * 0.012;
	vec2 p = wp.xz * 0.018 + graine * 7.3;
	float f = fbm(p + vec2(t, t * 0.4)) * 0.65 + fbm(p * 2.6 - vec2(t * 1.7, -t)) * 0.35;
	float lambeaux = smoothstep(0.5, 0.8, f);
	// nulle vers le bord du disque (loc : -1..1)
	float bord = 1.0 - smoothstep(0.55, 1.0, length(loc));
	// le contact avec le sol : fondu sur 3 m
	float zd = texture(tex_prof, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, zd, 1.0);
	v.xyz /= v.w;
	float contact = smoothstep(0.0, 3.0, length(v.xyz) - length(VERTEX));
	// de près, elle s'efface (on la traverse)
	float pres = smoothstep(2.0, 14.0, length(VERTEX));
	ALBEDO = teinte;
	ROUGHNESS = 1.0;
	ALPHA = clamp(lambeaux * bord * contact * pres * epaisseur, 0.0, 1.0);
	BACKLIGHT = vec3(0.4);
}

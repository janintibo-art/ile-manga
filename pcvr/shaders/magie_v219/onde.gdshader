shader_type spatial;
// V219 : la vague au sol d'une explosion, d'un éclair. Pas un anneau parfait : un front irrégulier qui
// s'élargit (« t » va de 0 à 1) en ondulant, ourlé de mèches qui s'effilochent derrière lui.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 couleur : source_color = vec3(1.0, 0.55, 0.2);
uniform float intensite = 5.0;
uniform float t = 0.0;
uniform float graine = 0.0;

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float r = length(uv);
	// (l'angle fait un tour de -0,5 à 0,5 ; multiplié par un entier, le bruit se raccorde sans couture)
	float a = atan(uv.y, uv.x) / 6.2832;
	float avance = 1.0 - pow(1.0 - t, 2.5);
	// le front : son rayon ondule autour du cercle, à deux échelles, et l'ondulation tourne lentement
	float n1 = texture(bruit, vec2(a * 2.0 + graine + t * 0.25, 0.21 + graine)).r;
	float n2 = texture(bruit, vec2(a * 5.0 - graine - t * 0.4, 0.63 - graine)).r;
	float rayon = mix(0.06, 0.84, avance) * (1.0 + (n1 - 0.5) * 0.36 + (n2 - 0.5) * 0.16);
	float epais = mix(0.1, 0.04, t) * (0.55 + n2 * 0.95);
	float front = smoothstep(epais, 0.0, abs(r - rayon));
	// les mèches : derrière le front, elles s'effilochent vers le centre
	float meches = texture(bruit, vec2(a * 7.0 + graine * 2.0, r * 1.6 - t * 1.2)).r;
	float derriere = smoothstep(rayon, rayon - 0.05, r) * smoothstep(rayon - 0.45, rayon - 0.04, r);
	float langues = derriere * smoothstep(0.42, 0.8, meches) * 0.85;
	float vie = 1.0 - smoothstep(0.25, 0.95, t);
	ALBEDO = couleur * intensite * (0.55 + n1 * 0.9);
	ALPHA = clamp((front + langues) * vie, 0.0, 1.0) * smoothstep(1.0, 0.93, r);
}

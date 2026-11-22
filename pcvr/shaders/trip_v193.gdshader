shader_type canvas_item;
// V193 : le Rieur (Public averti) : le monde respire (l'image gonfle et dégonfle lentement), ondule, les
// couleurs tournent et coulent (une teinte qui change avec la distance au centre), les bords se dédoublent
// (rouge et bleu qui s'écartent), tout est plus saturé. force : 0 (rien) à 1 (le plateau).

uniform sampler2D ecran : hint_screen_texture, filter_linear_mipmap;
uniform float force = 0.0;
uniform float temps = 0.0;

vec3 teinte(vec3 c, float a) {
	// rotation autour de l'axe gris (formule de Rodrigues)
	const vec3 k = vec3(0.57735);
	float co = cos(a);
	return c * co + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - co);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r = length(c);
	float f = clamp(force, 0.0, 1.0);
	// la respiration : lente, ample
	float souffle = 1.0 - f * 0.028 * (0.5 + 0.5 * sin(temps * 1.15));
	uv = 0.5 + c * souffle;
	// les ondes : deux nappes croisées, lentes
	uv += f * 0.0055 * vec2(sin(uv.y * 17.0 + temps * 1.6) + 0.5 * sin(uv.y * 41.0 - temps * 2.3),
		cos(uv.x * 13.0 + temps * 1.25) + 0.5 * cos(uv.x * 37.0 + temps * 1.9));
	// les bords qui se dédoublent
	vec2 ca = c * f * 0.012 * (0.35 + r * 1.6);
	vec3 col;
	col.r = texture(ecran, uv + ca).r;
	col.g = texture(ecran, uv).g;
	col.b = texture(ecran, uv - ca).b;
	// les couleurs qui tournent, en anneaux qui s'éloignent du centre
	vec3 tourne = teinte(col, temps * 0.55 + r * 5.0 - temps * 0.8 * r);
	col = mix(col, tourne, f * 0.5);
	// plus saturé, un peu plus lumineux au centre
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, 1.0 + f * 0.75);
	col *= 1.0 + f * 0.12 * (1.0 - smoothstep(0.0, 0.7, r));
	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}

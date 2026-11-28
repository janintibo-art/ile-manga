shader_type spatial;
// V219 : le givre qui prend sur le sol : des cristaux en fougère qui poussent depuis le centre (« pousse » va
// de 0 à 1), scintillent, puis fondent (« fonte » va de 0 à 1).
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D cristaux : repeat_enable, filter_linear_mipmap;
uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 blanc : source_color = vec3(0.86, 0.94, 1.0);
uniform vec3 bleu : source_color = vec3(0.45, 0.68, 0.95);
uniform float pousse = 1.0;
uniform float fonte = 0.0;
uniform float graine = 0.0;

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float r = length(uv);
	// (les cristaux ne sont pas lus tout droit : un bruit tord leur dessin, ils courbent comme des fougères)
	vec2 tord = vec2(texture(bruit, UV * 1.1 + vec2(graine * 0.3, graine)).r, texture(bruit, UV * 1.1 + vec2(graine + 0.37, graine * 0.5 + 0.61)).r) - vec2(0.5);
	float c1 = texture(cristaux, UV * 2.2 + tord * 0.5 + vec2(graine, graine * 0.6)).r;
	float c2 = texture(cristaux, UV * 5.5 + tord * 0.9 - vec2(graine * 0.4, graine)).r;
	float n = texture(bruit, UV * 1.4 + vec2(graine * 0.8, -graine)).r;
	// le front de givre avance du centre vers le bord, en dents de scie le long des cristaux
	float front = pousse * 1.15 - (n - 0.5) * 0.35 - (c1 - 0.5) * 0.25;
	float dedans = smoothstep(front, front - 0.22, r);
	float bord = smoothstep(1.0, 0.72, r + (n - 0.5) * 0.3);
	// les arêtes des cristaux : claires ; entre elles : une pellicule bleutée
	float aretes = smoothstep(0.2, 0.03, c1) * 0.85 + smoothstep(0.14, 0.01, c2) * 0.45;
	float pellicule = 0.2 + 0.2 * n;
	float a = dedans * bord * clamp(pellicule + aretes, 0.0, 1.0);
	ALBEDO = mix(bleu, blanc, clamp(aretes + 0.1, 0.0, 1.0));
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
	// les paillettes : des points qui s'allument et s'éteignent
	float paillette = pow(max(c2 * 0.5 + n * 0.5 + 0.12 * sin(TIME * 6.0 + c1 * 40.0), 0.0), 9.0);
	EMISSION = (blanc * paillette * 3.0 + bleu * aretes * 0.12) * dedans;
	ALPHA = a * (1.0 - smoothstep(0.0, 1.0, fonte)) * 0.92;
}

// V94 : les grands écrans publicitaires et les enseignes au néon de Néopolis. L'image (une
// texture) est lumineuse par elle-même ; sur les écrans on voit les lignes et les points de
// l'écran de près, un léger défilement, et de temps en temps l'image change de page (« pages » :
// la texture est découpée en bandes verticales, une par réclame). Les néons grésillent un peu.
shader_type spatial;
render_mode cull_back, unshaded;

uniform sampler2D image : source_color, filter_linear_mipmap_anisotropic;
uniform float pages = 1.0;
uniform float duree_page = 7.0;
uniform float force = 2.2;
uniform float nuit : hint_range(0.0, 1.0) = 0.0;
uniform bool ecran = true;          // false : une enseigne au néon (pas de trame d'écran)
uniform float graine = 0.0;

float h1(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME + graine * 13.0;
	float p = floor(mod(t / duree_page, pages));
	// le passage d'une page à l'autre : un balayage vertical
	float ph = fract(t / duree_page);
	float bascule = smoothstep(0.96, 1.0, ph);
	vec2 uvp = vec2((uv.x + p) / pages, uv.y);
	vec3 c = texture(image, uvp).rgb;
	float a = texture(image, uvp).a;
	if (ecran) {
		// la trame : des lignes, et une barre plus claire qui descend lentement
		float ln = 0.82 + 0.18 * sin(uv.y * 900.0);
		float barre = 1.0 + 0.25 * smoothstep(0.05, 0.0, abs(fract(uv.y + t * 0.07) - 0.5));
		c *= ln * barre;
		c = mix(c, vec3(1.0), bascule * step(uv.y, (ph - 0.96) * 25.0) * 0.6);
	} else {
		// le néon : il grésille, et parfois une lettre clignote
		float gr = 0.92 + 0.08 * h1(floor(t * 24.0));
		float clign = 1.0 - 0.8 * step(0.985, h1(floor(t * 3.0) + graine)) * step(0.5, h1(floor(uv.x * 6.0) + graine));
		c *= gr * clign;
	}
	ALBEDO = c * force * (0.45 + 0.55 * nuit + 0.0);
	ALPHA = ecran ? 1.0 : a;
	ALPHA_SCISSOR_THRESHOLD = ecran ? 0.0 : 0.35;
}

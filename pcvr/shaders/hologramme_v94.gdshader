// V94 : les hologrammes de Néopolis (les carpes géantes de la Place des Hologrammes, l'anneau au
// sommet de la Tour Axiome). De la lumière sans matière : les bords brillent plus que le milieu
// (effet de Fresnel), des lignes de balayage montent, l'image tremble un peu, et parfois elle
// « saute ».
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform vec4 couleur : source_color = vec4(0.2, 0.85, 1.0, 1.0);
uniform vec4 couleur_bord : source_color = vec4(1.0, 0.35, 0.9, 1.0);
uniform float force = 1.6;
uniform float lignes = 3.0;        // lignes de balayage par mètre

varying vec3 wpos;

float h1(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// un léger tremblement horizontal, de temps en temps
	float saut = step(0.93, h1(floor(TIME * 7.0)));
	VERTEX.x += sin(VERTEX.y * 9.0 + TIME * 40.0) * 0.04 * saut;
}

void fragment() {
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float scan = 0.6 + 0.4 * sin((wpos.y * lignes - TIME * 2.2) * 6.2831);
	float fine = 0.85 + 0.15 * sin(wpos.y * 60.0 + TIME * 10.0);
	float flick = 0.88 + 0.12 * h1(floor(TIME * 18.0));
	vec3 c = mix(couleur.rgb * 0.35, couleur_bord.rgb, fres) + couleur.rgb * fres * 0.6;
	ALBEDO = c * scan * fine * flick * force;
}

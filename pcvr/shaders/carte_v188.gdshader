// V188 : le mur d'écrans de la salle de pilotage de la Tour Kumo : la carte de Néopolis (une image), et par
// dessus, les drones en vol : des points de lumière qui suivent les rues, chacun à sa vitesse. UV : 0..1.
shader_type spatial;
render_mode cull_back, unshaded;

uniform sampler2D image : source_color, filter_linear_mipmap;
uniform float force = 1.6;
// la part de l'image qu'on montre (les volets de côté) : son coin, sa taille
uniform vec4 fenetre = vec4(0.0, 0.0, 1.0, 1.0);
// la ville, dans l'image : son coin (en UV), la taille d'un îlot
uniform vec2 coin = vec2(0.2734, 0.052);
uniform vec2 ilot = vec2(0.0547, 0.1458);

float h1(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

void fragment() {
	vec2 uv = fenetre.xy + UV * fenetre.zw;
	vec3 c = texture(image, uv).rgb;
	float glow = 0.0;
	vec3 teinte = vec3(0.3, 0.9, 1.0);
	for (int i = 0; i < 26; i++) {
		float fi = float(i);
		float rue = floor(h1(fi * 3.7) * 7.0);
		float t = fract(h1(fi * 1.3) + TIME * (0.02 + 0.05 * h1(fi * 7.1)) * (h1(fi * 2.9) > 0.5 ? 1.0 : -1.0));
		vec2 p = (h1(fi * 5.3) > 0.5) ? vec2(coin.x + rue * ilot.x, coin.y + t * 6.0 * ilot.y) : vec2(coin.x + t * 6.0 * ilot.x, coin.y + rue * ilot.y);
		vec2 dd = (uv - p) * vec2(2.667, 1.0);
		float g = smoothstep(0.012, 0.0, length(dd));
		glow += g;
		if (h1(fi * 11.0) > 0.75 && g > 0.01) {
			teinte = vec3(1.0, 0.6, 0.15);
		}
	}
	float ln = 0.88 + 0.12 * sin(uv.y * 700.0);
	ALBEDO = (c * ln + teinte * glow * 1.6) * force;
}

shader_type spatial;
render_mode unshaded, cull_disabled;
// V195 : la Tour Hikari (Hikari Systèmes, la maison de la lumière) : les fibres qui courent sur la tour.
// Une lueur douce, et des impulsions de lumière qui filent le long de « axe » (vers le haut sur les
// façades, vers la porte dans le tunnel de l'entrée). La couleur glisse de couleur_a à couleur_b.
// nuit : 0 (le jour, discret) à 1 (la nuit, éclatant).

uniform vec4 couleur_a : source_color = vec4(0.1, 0.85, 1.0, 1.0);
uniform vec4 couleur_b : source_color = vec4(0.6, 0.3, 1.0, 1.0);
uniform vec3 axe = vec3(0.0, 1.0, 0.0);
uniform float periode = 22.0;      // les mètres entre deux impulsions
uniform float vitesse = 7.0;       // en mètres par seconde
uniform float largeur = 2.2;       // la longueur d'une impulsion (en mètres)
uniform float nuit = 0.0;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float s = dot(wp, normalize(axe));
	float ph = fract((s - TIME * vitesse) / periode);
	float d = abs(ph - 0.5) * periode;
	float impulsion = 1.0 - smoothstep(0.0, largeur, d);
	float glisse = 0.5 + 0.5 * sin(s * 0.11 + TIME * 0.35);
	vec3 c = mix(couleur_a.rgb, couleur_b.rgb, glisse);
	float base = mix(0.32, 0.7, nuit);
	ALBEDO = c * (base + impulsion * mix(0.9, 3.2, nuit));
}

// V161 : les feux tricolores des carrefours de Néopolis. Un cycle de 30 s : vert 12 s, orange 3 s, rouge
// 15 s ; les rues est-ouest ont un demi-cycle d'écart sur les rues nord-sud (quand l'une est au vert,
// l'autre est au rouge). Une lentille éteinte garde un reflet de sa couleur.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float phase = 0.0;      // 0 : les rues nord-sud ; 1 : les rues est-ouest
uniform int feu = 0;            // 0 : rouge ; 1 : orange ; 2 : vert ; 3 : le piéton (vert quand les voitures ont rouge)

void fragment() {
	float t = mod(TIME + phase * 15.0, 30.0);
	float on;
	if (feu == 2) {
		on = step(t, 12.0);
	} else if (feu == 1) {
		on = step(12.0, t) * step(t, 15.0);
	} else if (feu == 0) {
		on = step(15.0, t);
	} else {
		on = step(15.5, t) * step(t, 29.0) * (t > 26.0 ? step(0.5, fract(t * 1.5)) : 1.0);
	}
	vec3 c = feu == 0 ? vec3(1.0, 0.08, 0.06) : (feu == 1 ? vec3(1.0, 0.55, 0.04) : vec3(0.1, 1.0, 0.5));
	ALBEDO = c * (0.06 + 0.25 * on);
	ROUGHNESS = 0.15;
	SPECULAR = 0.7;
	EMISSION = c * on * 3.2;
}

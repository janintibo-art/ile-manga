// V161 : la pierre de la Citadelle des Nuées (l'île flottante), vieillie par le vent et la pluie. Les
// pierres de taille (la texture, posée en triplanaire dans le monde, avec son relief) ; de grandes
// nuances qui cassent la répétition ; les coulures de pluie, en traînées verticales ; la terre et
// l'humidité au pied des murs ; la mousse sur le dessus des pierres et par plaques au pied des murs ;
// de petits lichens gris-jaune. « mousse » : 0 pour une pierre sans mousse.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 teinte : source_color = vec3(0.86, 0.83, 0.78);
uniform float echelle = 0.3125;          // des motifs par mètre (1 / 3,2 m)
uniform float relief = 1.1;
uniform float sol_y = 0.0;               // le pied des murs (dans le monde)
uniform float mousse = 1.0;
uniform float rugosite = 0.9;

varying vec3 wp;
varying vec3 wn;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float bruit3(vec3 p) {
	vec3 a = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(h3(a), h3(a + vec3(1.0, 0.0, 0.0)), f.x);
	float x10 = mix(h3(a + vec3(0.0, 1.0, 0.0)), h3(a + vec3(1.0, 1.0, 0.0)), f.x);
	float x01 = mix(h3(a + vec3(0.0, 0.0, 1.0)), h3(a + vec3(1.0, 0.0, 1.0)), f.x);
	float x11 = mix(h3(a + vec3(0.0, 1.0, 1.0)), h3(a + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

float fbm(vec3 p) {
	return bruit3(p) * 0.55 + bruit3(p * 2.03 + 7.1) * 0.3 + bruit3(p * 4.1 + 3.3) * 0.15;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wn);
	vec3 w = pow(abs(n), vec3(6.0));
	w /= (w.x + w.y + w.z);
	vec2 ux = vec2(wp.z, -wp.y) * echelle;
	vec2 uy = vec2(wp.x, wp.z) * echelle;
	vec2 uz = vec2(wp.x, -wp.y) * echelle;
	vec3 col = texture(tex_albedo, ux).rgb * w.x + texture(tex_albedo, uy).rgb * w.y + texture(tex_albedo, uz).rgb * w.z;
	vec3 nx = texture(tex_normal, ux).xyz * 2.0 - 1.0;
	vec3 ny = texture(tex_normal, uy).xyz * 2.0 - 1.0;
	vec3 nz = texture(tex_normal, uz).xyz * 2.0 - 1.0;
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 pert = (vec3(0.0, 0.0, 1.0) * nx.x + up * nx.y) * w.x + (vec3(1.0, 0.0, 0.0) * ny.x + vec3(0.0, 0.0, -1.0) * ny.y) * w.y + (vec3(1.0, 0.0, 0.0) * nz.x + up * nz.y) * w.z;
	vec3 nn = normalize(n + pert * relief * 0.6);
	col *= teinte;
	// de grandes nuances (la répétition des pierres se voit moins)
	float macro = fbm(wp * 0.08);
	col *= 0.8 + 0.4 * macro;
	float rough = rugosite;
	float h = wp.y - sol_y;
	float vert = 1.0 - w.y;
	// les coulures de pluie : des traînées verticales, plus sombres
	float le_long = wp.z * abs(n.x) + wp.x * abs(n.z);
	float coul = bruit3(vec3(le_long * 2.2, wp.y * 0.09, 3.0)) * 0.7 + bruit3(vec3(le_long * 6.0, wp.y * 0.2, 9.0)) * 0.3;
	col *= 1.0 - 0.3 * smoothstep(0.48, 0.8, coul) * vert;
	// la terre et l'humidité au pied des murs
	float pied = (1.0 - smoothstep(0.0, 3.2, h)) * (0.55 + 0.45 * fbm(wp * 0.7));
	col = mix(col, col * vec3(0.5, 0.47, 0.4), pied * 0.85 * vert);
	rough = mix(rough, 0.97, pied * 0.5);
	// la mousse : sur le dessus des pierres, et par plaques au pied des murs
	float m1 = fbm(wp * 0.9 + 11.0);
	float m2 = fbm(wp * 3.1);
	float dessus = smoothstep(0.5, 0.85, n.y) * smoothstep(0.38, 0.62, m1);
	float bas = (1.0 - smoothstep(0.0, 1.4, h)) * smoothstep(0.56, 0.74, m1) * vert;
	float mo = clamp(dessus + bas * 0.8, 0.0, 1.0) * mousse;
	vec3 vert_mousse = mix(vec3(0.16, 0.24, 0.07), vec3(0.34, 0.42, 0.13), m2);
	col = mix(col, vert_mousse, mo * (0.6 + 0.4 * m2));
	rough = mix(rough, 1.0, mo);
	nn = normalize(mix(nn, n, mo * 0.6));
	// les lichens : de petites taches gris-jaune
	float li = smoothstep(0.74, 0.8, bruit3(wp * 5.5 + 2.0)) * smoothstep(0.4, 0.7, bruit3(wp * 0.5)) * mousse * vert;
	col = mix(col, mix(vec3(0.72, 0.7, 0.52), vec3(0.78, 0.66, 0.3), m2), li * 0.55);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
	NORMAL = normalize((VIEW_MATRIX * vec4(nn, 0.0)).xyz);
}

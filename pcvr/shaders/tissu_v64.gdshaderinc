// V64 : corps commun des tissus (coques et vêtements amples).
uniform vec3 couleur : source_color = vec3(0.5);
uniform vec3 couleur2 : source_color = vec3(0.9);
uniform int motif = 0;
uniform float echelle = 0.04;
uniform sampler2D trame : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float trame_rep = 60.0;
uniform float rugosite = 0.85;
uniform float lustre = 0.0;
uniform sampler2D details : hint_default_black, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D plis : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 coutures = vec3(1.0, 0.0, 0.0);
uniform float plis_force = 1.0;
uniform float metal = 0.0;

varying float hem;
varying vec3 rest;

void vertex() {
	hem = CUSTOM0.x;
	rest = CUSTOM1.xyz;
}

void fragment() {
	vec3 c = couleur;
	if (motif == 1) {
		float s = step(0.5, fract(rest.y / echelle));
		c = mix(couleur, couleur2, s);
	} else if (motif == 2) {
		float a = smoothstep(0.42, 0.5, abs(fract(rest.y / echelle) - 0.5));
		float b = smoothstep(0.42, 0.5, abs(fract((rest.x + rest.z * 0.7) / echelle) - 0.5));
		c = mix(couleur, couleur2, clamp(a * 0.6 + b * 0.6, 0.0, 1.0));
	} else if (motif == 3) {
		float s = step(0.5, fract((rest.x + rest.z * 0.6) / echelle));
		c = mix(couleur, couleur2, s);
	} else if (motif == 5) {
		// V69 : les tissages des Mayas et des Aztèques : des bandes de losanges (un losange creux,
		// un point au milieu) entre deux filets, sur le fond uni
		float band = fract(rest.y / echelle * 0.25);
		float u = (rest.x + rest.z * 0.7) / echelle;
		float bv = clamp((band - 0.55) / 0.4, 0.0, 1.0);
		float inb = step(0.55, band) * step(band, 0.95);
		float d = abs(fract(u * 0.5) - 0.5) * 2.0 + abs(bv - 0.5) * 2.0;
		float pat = inb * (step(d, 0.95) * (1.0 - step(d, 0.55)) + step(d, 0.2));
		float ln = step(abs(band - 0.5), 0.02) + step(0.975, band);
		c = mix(couleur, couleur2, clamp(pat + ln, 0.0, 1.0));
	} else if (motif == 4) {
		vec2 q = vec2(rest.x + rest.z * 0.7, rest.y) / echelle;
		float d = length(fract(q) - 0.5);
		c = mix(couleur, couleur2, smoothstep(0.24, 0.2, d));
	}
	vec4 tr = texture(trame, UV * trame_rep);
	c *= mix(0.86, 1.08, tr.b);
#ifdef SUR_CORPS
	vec4 det = texture(details, UV);
#else
	vec4 det = vec4(0.0, 0.0, 0.0, 1.0);
#endif
	float seam = det.r * coutures.x;
	float btn = det.g * coutures.y;
	float pk = det.b * coutures.z;
	c *= 1.0 - 0.35 * seam - 0.28 * pk;
	c = mix(c, c * 0.55 + vec3(0.06), btn);
	// surpiqûre à 1 cm de l'ourlet, et bord de l'ourlet un peu plus sombre (épaisseur repliée)
	float st = smoothstep(0.0016, 0.0, abs(hem - 0.011));
	c *= 1.0 - 0.22 * st;
	c *= mix(0.86, 1.0, smoothstep(0.0, 0.006, hem));
	c *= mix(0.55, 1.0, det.a);
	ALBEDO = c;
	vec2 tn = tr.rg * 2.0 - 1.0;
#ifdef SUR_CORPS
	vec2 pn = (texture(plis, UV).rg * 2.0 - 1.0) * plis_force;
#else
	vec2 pn = vec2(0.0);
#endif
	NORMAL_MAP = vec3((tn * 0.6 + pn) * 0.5 + 0.5, 1.0);
	ROUGHNESS = clamp(rugosite * mix(0.9, 1.1, tr.a) - btn * 0.4, 0.05, 1.0);
	SPECULAR = 0.3 + lustre * 0.3 + metal * 0.3;
	METALLIC = metal;
	RIM = lustre * 0.4;
	RIM_TINT = 0.6;
}

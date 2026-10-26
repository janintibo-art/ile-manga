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
	vec3 emi = vec3(0.0);       // V76 : lueur (Lumens) ; nulle pour tous les autres motifs
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
	} else if (motif == 6) {
		// V75 : le tartan (larges bandes croisées de couleur2, fins filets clairs)
		vec2 q = vec2(rest.x + rest.z * 0.7, rest.y) / echelle;
		vec2 f = fract(q);
		float bu = smoothstep(0.56, 0.6, f.x) * smoothstep(0.98, 0.94, f.x);
		float bv = smoothstep(0.56, 0.6, f.y) * smoothstep(0.98, 0.94, f.y);
		c = mix(couleur, couleur2, clamp(0.55 * (bu + bv), 0.0, 0.9));
		float lu = smoothstep(0.035, 0.02, abs(fract(q.x + 0.27) - 0.5));
		float lv = smoothstep(0.035, 0.02, abs(fract(q.y + 0.27) - 0.5));
		c = mix(c, vec3(0.9, 0.82, 0.5), clamp(0.55 * (lu + lv), 0.0, 0.8));
	} else if (motif == 11) {
		// V76 : les combinaisons des Lumens : de fins filets lumineux (couleur2), comme des circuits
		// ou des constellations, avec un petit nœud brillant aux croisements
		vec2 q = vec2(rest.x + rest.z * 0.7, rest.y) / max(echelle, 0.02);
		vec2 cell = floor(q);
		vec2 f = fract(q);
		float h1 = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float h2 = fract(sin(dot(cell, vec2(39.3468, 11.135))) * 24634.6345);
		// des filets horizontaux continus, reliés par quelques montants, et des nœuds aux croisements
		float lh = smoothstep(0.03, 0.012, abs(f.y - 0.5));
		vec2 cv = vec2(cell.x, floor(q.y - 0.5));
		float h3 = fract(sin(dot(cv, vec2(27.619, 57.583))) * 31415.9265);
		float lv = smoothstep(0.03, 0.012, abs(f.x - 0.5)) * step(h3, 0.3);
		float nd = smoothstep(0.1, 0.06, length(f - 0.5)) * step(h2, 0.45);
		float fil = clamp(lh + lv + nd, 0.0, 1.0);
		c = mix(couleur, couleur2, fil * 0.85);
		emi += couleur2 * fil * 0.9;
	} else if (motif == 13) {
		// V76 : la soie à reflets des Lumens : la teinte glisse vers couleur2 sous les angles rasants
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float ond = 0.5 + 0.5 * sin((rest.y * 9.0 + rest.x * 5.0 + rest.z * 4.0) * 3.1416);
		c = mix(couleur, mix(couleur2, vec3(1.0), 0.25), clamp(smoothstep(0.25, 0.95, fr) * 0.75 + ond * 0.12, 0.0, 0.85));
	}
	// V75 : les patchs cousus (7, 8) et les clous (8, 9) des punks de Port-Boucan
	float clou = 0.0;
	if (motif == 7 || motif == 8) {
		vec2 q = vec2(rest.x + rest.z * 0.7, rest.y) / max(echelle, 0.02);
		vec2 cell = floor(q);
		vec2 f = fract(q);
		float h1 = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float h2 = fract(sin(dot(cell, vec2(39.3468, 11.135))) * 24634.6345);
		float h3 = fract(sin(dot(cell, vec2(73.156, 52.235))) * 13581.2457);
		vec2 half_sz = vec2(0.2 + 0.18 * h2, 0.16 + 0.18 * h3);
		vec2 ctr = vec2(0.5) + (vec2(h3, h2) - 0.5) * (0.5 - half_sz) * 1.6;
		vec2 dd = abs(f - ctr) - half_sz;
		float inside = step(max(dd.x, dd.y), 0.0);
		if (h1 < 0.32 && inside > 0.5) {
			vec3 pc = couleur2;
			float k = fract(h1 * 7.31 + h2);
			if (k < 0.2) { pc = vec3(0.75, 0.08, 0.08); }
			else if (k < 0.38) { pc = vec3(0.92, 0.9, 0.84); }
			else if (k < 0.52) { pc = vec3(0.9, 0.72, 0.12); }
			else if (k < 0.66) {
				vec2 t = fract((f - ctr) * 9.0);
				pc = mix(vec3(0.62, 0.06, 0.08), vec3(0.08, 0.1, 0.12), 0.6 * (step(0.6, t.x) + step(0.6, t.y)));
			} else if (k < 0.8) { pc = vec3(0.1, 0.1, 0.1); }
			// un motif imprimé au centre : deux lignes de « texte » (le nom d'un groupe), ou un anneau
			vec2 r = (f - ctr) / max(half_sz.x, half_sz.y);
			float txt = step(abs(fract(r.y * 1.6 + 0.5) - 0.5), 0.14) * step(abs(r.x), 0.62) * step(abs(r.y), 0.55);
			float ring = smoothstep(0.08, 0.0, abs(length(r) - 0.42));
			float sym = (h2 < 0.65 || k < 0.2) ? txt : ring;
			pc = mix(pc, (dot(pc, vec3(0.33)) > 0.45) ? vec3(0.08) : vec3(0.9, 0.88, 0.82), sym * 0.85);
			// points de couture au bord du patch
			float edge = smoothstep(-0.035, -0.015, max(dd.x, dd.y));
			pc *= 1.0 - 0.45 * edge;
			c = pc;
		}
	}
	if (motif == 8 || motif == 9) {
		// clous : un semis le long des bords (ourlets, revers, poignets, col)
		vec3 qs = rest / 0.022;
		float dc = length(fract(qs) - 0.5);
		float band = smoothstep(0.012, 0.016, hem) * smoothstep(0.034, 0.03, hem);
		clou = smoothstep(0.3, 0.22, dc) * band;
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
	c = mix(c, vec3(0.78, 0.78, 0.8), clou);
	// V76 : les liserés lumineux des Lumens (10 : uni ; 11 : filets ; 13 : soie à reflets) : un ourlet
	// de lumière (couleur2) d'un centimètre
	if (motif == 10 || motif == 11 || motif == 13) {
		float lis = 1.0 - smoothstep(0.005, 0.009, hem);
		c = mix(c, mix(couleur2, vec3(1.0), 0.2), lis * 0.9);
		emi += couleur2 * lis * 1.2;
	}
	ALBEDO = c;
	vec2 tn = tr.rg * 2.0 - 1.0;
#ifdef SUR_CORPS
	vec2 pn = (texture(plis, UV).rg * 2.0 - 1.0) * plis_force;
#else
	vec2 pn = vec2(0.0);
#endif
	NORMAL_MAP = vec3((tn * 0.6 + pn) * 0.5 + 0.5, 1.0);
	ROUGHNESS = mix(clamp(rugosite * mix(0.9, 1.1, tr.a) - btn * 0.4, 0.05, 1.0), 0.25, clou);
	SPECULAR = 0.3 + lustre * 0.3 + metal * 0.3 + clou * 0.3;
	METALLIC = max(metal, clou * 0.85);
	RIM = lustre * 0.4;
	RIM_TINT = 0.6;
	// V76 : les parures de tête des Lumens (UV.y = la part de lumière, 0 à 1)
	//  12 : antennes, taches et filaments (couleur, qui s'allume en couleur2 vers les pointes) ;
	//  14 : la crête de cristal (facettes lisses, reflets, un cœur de lumière).
	if (motif == 12 || motif == 14) {
		float g = clamp(UV.y, 0.0, 1.0);
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		NORMAL_MAP = vec3(0.5, 0.5, 1.0);
		METALLIC = 0.0;
		if (motif == 12) {
			ALBEDO = mix(couleur, couleur2, g * 0.85);
			emi = couleur2 * (g * g * 1.4 + fr * 0.1);
			ROUGHNESS = mix(rugosite, 0.25, g);
			SPECULAR = 0.45;
			RIM = 0.5;
			RIM_TINT = 0.3;
		} else {
			float sp = 0.5 + 0.5 * sin(dot(rest, vec3(91.0, 57.0, 73.0)));
			ALBEDO = mix(couleur * 0.55, couleur2, clamp(fr * 0.7 + g * 0.25, 0.0, 1.0));
			emi = couleur2 * (0.18 + 0.75 * g * g + 0.25 * fr) * (0.8 + 0.4 * sp);
			ROUGHNESS = 0.06;
			SPECULAR = 0.85;
			RIM = 0.7;
			RIM_TINT = 0.6;
		}
	}
	EMISSION = emi;
}

// V97 : les matières de l'Île Al Dente.
// mode 0 : les pâtes (spaghettis cuits : jaune paille, brillants, un peu translucides ; COLOR.r dit
//          combien un brin peut se balancer : les tentacules du Grand Spaghetti Volant, les pâtes qui
//          sèchent au vent ; dry = 1 : les pâtes sèches, plus mates, plus jaunes) ;
// mode 1 : les boulettes (brunes, grumeleuses, nappées de sauce par endroits) ;
// mode 2 : les yeux (blanc, iris brun, pupille, très brillants ; l'iris regarde vers +z local) ;
// mode 3 : le bronze des statues (la fourchette et la cuillère géantes : du vert-de-gris dans les
//          creux et là où la pluie coule) ;
// mode 4 : l'or (la Fourchette Sacrée de l'autel).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform int mode = 0;
uniform float sway = 0.0;
uniform float dry = 0.0;

varying vec3 wpos;
varying vec3 lpos;
varying vec3 lnrm;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float h31(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vn3(vec3 p) {
	vec3 a = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(h31(a), h31(a + vec3(1, 0, 0)), f.x);
	float x10 = mix(h31(a + vec3(0, 1, 0)), h31(a + vec3(1, 1, 0)), f.x);
	float x01 = mix(h31(a + vec3(0, 0, 1)), h31(a + vec3(1, 0, 1)), f.x);
	float x11 = mix(h31(a + vec3(0, 1, 1)), h31(a + vec3(1, 1, 1)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

float fbm3(vec3 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += vn3(p) * a;
		p = p * 2.03 + vec3(1.3, 7.1, 4.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
	if (mode == 0 && sway > 0.0) {
		vec3 w0 = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float f = COLOR.r;
		float ph = w0.y * 0.35 + w0.x * 0.13;
		vec3 off = vec3(sin(TIME * 0.9 + ph), 0.0, cos(TIME * 0.7 + ph * 1.3)) * sway * f * f;
		off.y = sin(TIME * 1.3 + ph * 2.0) * sway * 0.2 * f;
		VERTEX += (inverse(MODEL_MATRIX) * vec4(off, 0.0)).xyz;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (mode == 0) {
		float n = vn3(wpos * 9.0) * 0.5 + vn3(wpos * 37.0) * 0.5;
		vec3 cooked = mix(vec3(0.92, 0.78, 0.46), vec3(0.98, 0.88, 0.6), n);
		vec3 dried = mix(vec3(0.93, 0.76, 0.36), vec3(0.98, 0.85, 0.48), n);
		ALBEDO = mix(cooked, dried, dry);
		ROUGHNESS = mix(0.32, 0.62, dry) + n * 0.08;
		SPECULAR = 0.5;
		SSS_STRENGTH = mix(0.45, 0.15, dry);
		BACKLIGHT = mix(vec3(0.5, 0.38, 0.16), vec3(0.2, 0.14, 0.05), dry);
	} else if (mode == 1) {
		vec3 p = lpos * 2.2;
		float g = fbm3(p);
		float crumbs = smoothstep(0.55, 0.75, vn3(lpos * 14.0));
		vec3 meat = mix(vec3(0.2, 0.11, 0.06), vec3(0.36, 0.21, 0.12), g);
		meat = mix(meat, vec3(0.55, 0.36, 0.2), crumbs * 0.4);
		// la sauce : des coulées brillantes depuis le haut
		float sauce = smoothstep(0.66, 0.8, fbm3(vec3(lpos.x * 1.2, lpos.y * 0.5, lpos.z * 1.2) + 5.0) + normalize(lnrm).y * 0.18) * 0.85;
		ALBEDO = mix(meat, vec3(0.42, 0.05, 0.02), sauce);
		ROUGHNESS = mix(0.85, 0.22, sauce);
		SPECULAR = mix(0.3, 0.55, sauce);
		float e = 0.02;
		vec3 q = lpos * 6.0;
		float h0 = fbm3(q);
		vec3 grad = vec3(fbm3(q + vec3(e, 0, 0)) - h0, fbm3(q + vec3(0, e, 0)) - h0, fbm3(q + vec3(0, 0, e)) - h0) / e;
		vec3 nl = normalize(normalize(lnrm) - grad * 0.06 * (1.0 - sauce * 0.7));
		NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nl, 0.0)).xyz);
	} else if (mode == 2) {
		vec3 d = normalize(lpos);
		float k = d.z;
		vec3 col = vec3(0.95, 0.94, 0.9);
		// de fines veines rosées au bord du blanc
		col = mix(col, vec3(0.9, 0.62, 0.6), smoothstep(0.75, 0.95, vn3(lpos * 18.0)) * smoothstep(0.3, -0.4, k) * 0.5);
		float iris = smoothstep(0.8, 0.83, k);
		float ring = vn3(vec3(atan(d.y, d.x) * 6.0, k * 20.0, 0.0));
		col = mix(col, mix(vec3(0.28, 0.16, 0.06), vec3(0.5, 0.33, 0.12), ring), iris);
		col = mix(col, vec3(0.02, 0.015, 0.01), smoothstep(0.94, 0.955, k));
		ALBEDO = col;
		ROUGHNESS = 0.05;
		SPECULAR = 0.7;
		CLEARCOAT = 1.0;
		CLEARCOAT_ROUGHNESS = 0.02;
	} else if (mode == 3) {
		float n = fbm3(wpos * 0.9);
		vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float up = smoothstep(0.2, 0.9, nw.y);
		float streaks = smoothstep(0.55, 0.8, vn3(vec3(wpos.x * 6.0, wpos.y * 0.4, wpos.z * 6.0)));
		float verdi = clamp(up * 0.7 + streaks * 0.5 + (n - 0.5) * 0.6, 0.0, 1.0);
		vec3 bronze = mix(vec3(0.42, 0.27, 0.13), vec3(0.62, 0.43, 0.22), n);
		vec3 patina = mix(vec3(0.27, 0.5, 0.42), vec3(0.4, 0.62, 0.5), n);
		ALBEDO = mix(bronze, patina, verdi * 0.85);
		METALLIC = mix(0.9, 0.15, verdi);
		ROUGHNESS = mix(0.35, 0.8, verdi);
	} else {
		float n = vn3(wpos * 14.0);
		ALBEDO = mix(vec3(0.95, 0.72, 0.3), vec3(1.0, 0.8, 0.4), n);
		METALLIC = 1.0;
		ROUGHNESS = 0.18 + n * 0.1;
	}
}

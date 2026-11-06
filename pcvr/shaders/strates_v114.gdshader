// V114 : la roche des Strates (sous Hautefond). Un grès tendre en couches : des bancs ocre, crème,
// rouille, gris et rosés, épais de quelques décimètres à deux mètres, qui ondulent un peu et que
// l'on voit courir tout autour des cavernes (d'où le nom). Roche en triplanaire (normales « whiteout »),
// sol de poussière tassée ; roche mouillée près de l'étang des Jardins et dans le Gouffre ; dans la
// Grotte aux Cristaux, des veines bleues qui luisent (les fissures d'un bruit de Voronoï, F2 - F1).
// Le maillage porte, par sommet : COLOR.r = ouverture (occlusion approchée), COLOR.g = mouillé,
// COLOR.b = sol, COLOR.a = cristal.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fissures : filter_linear_mipmap, repeat_enable;
uniform vec3 teinte_sol = vec3(0.66, 0.56, 0.44);
uniform vec3 veine : source_color = vec3(0.35, 0.7, 1.0);
uniform float veine_force = 2.6;
uniform vec3 origine = vec3(0.0);   // le repère des Strates (les coordonnées restent petites)

varying vec3 lp;
varying vec3 ln;

float hash1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 a = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(a), n100 = hash3(a + vec3(1, 0, 0)), n010 = hash3(a + vec3(0, 1, 0)), n110 = hash3(a + vec3(1, 1, 0));
	float n001 = hash3(a + vec3(0, 0, 1)), n101 = hash3(a + vec3(1, 0, 1)), n011 = hash3(a + vec3(0, 1, 1)), n111 = hash3(a + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y), mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

vec3 tri3(sampler2D t, vec3 p, vec3 w, float s) {
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}

vec3 tri_n(sampler2D t, vec3 p, vec3 n, vec3 w, float s, float k) {
	vec3 tx = texture(t, p.zy * s).xyz * 2.0 - 1.0;
	vec3 ty = texture(t, p.xz * s).xyz * 2.0 - 1.0;
	vec3 tz = texture(t, p.xy * s).xyz * 2.0 - 1.0;
	tx.xy *= k; ty.xy *= k; tz.xy *= k;
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

// la couleur d'un banc de grès (cinq teintes, tirées au sort par banc)
vec3 banc(float id) {
	float h = hash1(id);
	vec3 ocre = vec3(0.76, 0.6, 0.43);
	vec3 creme = vec3(0.8, 0.74, 0.62);
	vec3 rouille = vec3(0.66, 0.47, 0.37);
	vec3 gris = vec3(0.62, 0.6, 0.56);
	vec3 rose = vec3(0.74, 0.62, 0.55);
	vec3 c = h < 0.3 ? ocre : (h < 0.52 ? creme : (h < 0.7 ? rouille : (h < 0.86 ? gris : rose)));
	return c * (0.93 + 0.14 * hash1(id + 17.0));
}

void vertex() {
	lp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origine;
	ln = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(ln);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	float ao = COLOR.r;
	float wet = clamp(COLOR.g, 0.0, 1.0);
	float sol = smoothstep(0.75, 0.95, n.y) * (0.35 + 0.65 * COLOR.b);
	float cris = COLOR.a;
	float big = noise3(lp * 0.045);
	float huge = noise3(lp * 0.018 + 11.0);
	float mid = noise3(lp * 0.35 + 7.0);
	// les bancs : la hauteur, un peu ondulée ; des épaisseurs inégales (deux échelles qui se croisent)
	// (sur les voûtes, presque à plat, les bancs ondulent moins : sinon on verrait des tourbillons)
	float vert = 1.0 - abs(n.y);
	float yy = lp.y + ((huge - 0.5) * 7.0 + (big - 0.5) * 2.6) * mix(0.12, 1.0, vert) + (noise3(lp * 0.12 + 3.0) - 0.5) * 0.9;
	float t1 = yy / 1.35;
	float id1 = floor(t1);
	float f1 = fract(t1);
	vec3 c1 = mix(banc(id1), banc(id1 + 1.0), smoothstep(0.86, 1.0, f1));
	float t2 = yy / 0.37;
	float fine = 0.92 + 0.16 * hash1(floor(t2) + 91.0);
	// le liseré sombre entre deux bancs (un joint plus tendre, qui s'use)
	float joint = smoothstep(0.0, 0.06, f1) * (1.0 - 0.25 * smoothstep(0.93, 1.0, f1));
	vec3 strate = c1 * fine * mix(0.8, 1.0, joint);
	// les bancs se fondent par endroits (l'érosion, la poussière) : moins de contraste
	strate = mix(strate, vec3(0.72, 0.64, 0.53), 0.25 + 0.3 * smoothstep(0.3, 0.75, noise3(lp * 0.06 + 5.0)));
	vec3 tex = tri3(roche_tex, lp, w, 0.19);
	float lum = dot(tex, vec3(0.3, 0.55, 0.15));
	vec3 rock = strate * (0.42 + 1.0 * lum) * (0.84 + 0.26 * mid);
	vec3 sand = tri3(sable_tex, lp, w, 0.28) * teinte_sol * (0.85 + 0.25 * mid);
	vec3 albedo = mix(rock, sand, sol);
	albedo *= mix(1.0, 0.58, wet);
	// la voûte : plus sombre, plus unie (la poussière, la suie des lampes)
	albedo = mix(albedo, vec3(0.52, 0.46, 0.39) * (0.55 + 0.75 * lum) * (0.85 + 0.25 * mid), smoothstep(-0.25, -0.8, n.y) * 0.8);
	albedo *= mix(0.5, 1.0, ao);
	// dans la Grotte aux Cristaux : une roche plus froide, bleutée
	albedo = mix(albedo, albedo * vec3(0.72, 0.8, 0.95), cris * 0.6);
	vec3 nr = tri_n(roche_n, lp, n, w, 0.19, 1.25);
	vec3 ns = tri_n(sable_n, lp, n, w, 0.28, 0.7);
	vec3 nm = normalize(mix(nr, ns, sol));
	nm = normalize(mix(nm, n, wet * 0.45));
	NORMAL = normalize((VIEW_MATRIX * vec4(nm, 0.0)).xyz);
	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.9, 0.96, sol), 0.2, wet);
	SPECULAR = mix(0.38, 0.62, wet);
	AO = ao;
	AO_LIGHT_AFFECT = 0.45;
	// les veines de cristal (Grotte aux Cristaux) : elles respirent lentement
	float f = texture(fissures, lp.zy * 0.11).r * w.x + texture(fissures, lp.xz * 0.11).r * w.y + texture(fissures, lp.xy * 0.11).r * w.z;
	float line = 1.0 - smoothstep(0.0, 0.05, f);
	float where = smoothstep(0.45, 0.62, noise3(lp * 0.08 + 31.0)) * (1.0 - sol) * cris;
	float breathe = 0.7 + 0.3 * sin(TIME * 0.6 + big * 11.0);
	EMISSION = veine * line * where * breathe * veine_force;
}

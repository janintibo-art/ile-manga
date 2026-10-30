// V89 : la roche du souterrain du Grand Moaï (la Salle du Chant). Basalte sombre et humide en
// triplanaire (normales « whiteout »), sol de sable volcanique, roche mouillée qui brille près du
// sol et de la vasque ; dans la roche, des veines de lumière (corail et turquoise) qui respirent
// lentement : les fissures d'un bruit de Voronoï (F2 - F1), seulement par endroits.
// Le maillage porte, par sommet : COLOR.r = ouverture (occlusion approchée), COLOR.g = mouillé,
// COLOR.b = sol.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fissures : filter_linear_mipmap, repeat_enable;
uniform vec3 teinte_roche = vec3(0.58, 0.54, 0.5);
uniform vec3 teinte_sol = vec3(0.62, 0.56, 0.5);
uniform vec3 veine_a : source_color = vec3(0.25, 0.95, 0.9);
uniform vec3 veine_b : source_color = vec3(1.0, 0.45, 0.4);
uniform float veine_force = 2.4;
uniform float eveil = 0.0;          // 0 : endormie ; 1 : la salle chante (les veines s'allument plus fort)
uniform vec3 origine = vec3(0.0);   // le repère du souterrain (les coordonnées restent petites)

varying vec3 lp;
varying vec3 ln;

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

// normales triplanaires « whiteout » (chaque plan réorienté vers le monde)
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

void vertex() {
	// (en coordonnées du souterrain : la roche, et aussi les stalactites posées par MultiMesh)
	lp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origine;
	ln = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(ln);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	float ao = COLOR.r;
	float wet = clamp(COLOR.g, 0.0, 1.0);
	float sol = smoothstep(0.75, 0.95, n.y) * (0.4 + 0.6 * COLOR.b);
	float big = noise3(lp * 0.11);
	float mid = noise3(lp * 0.45 + 7.0);
	// la roche : du basalte sombre, des coulées plus rousses par endroits
	vec3 rock = tri3(roche_tex, lp, w, 0.21) * teinte_roche;
	rock *= mix(vec3(1.0), vec3(1.18, 0.98, 0.85), smoothstep(0.55, 0.8, big));
	rock *= 0.82 + 0.3 * mid;
	vec3 sand = tri3(sable_tex, lp, w, 0.33) * teinte_sol * (0.85 + 0.25 * mid);
	vec3 albedo = mix(rock, sand, sol);
	albedo *= mix(1.0, 0.6, wet);
	albedo *= mix(0.55, 1.0, ao);
	vec3 nr = tri_n(roche_n, lp, n, w, 0.21, 1.2);
	vec3 ns = tri_n(sable_n, lp, n, w, 0.33, 0.8);
	vec3 nm = normalize(mix(nr, ns, sol));
	nm = normalize(mix(nm, n, wet * 0.5));
	NORMAL = normalize((VIEW_MATRIX * vec4(nm, 0.0)).xyz);
	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.88, 0.95, sol), 0.18, wet);
	SPECULAR = mix(0.4, 0.62, wet);
	AO = ao;
	AO_LIGHT_AFFECT = 0.4;
	// les veines de lumière : des fissures, par plaques ; elles respirent
	float f = texture(fissures, lp.zy * 0.09).r * w.x + texture(fissures, lp.xz * 0.09).r * w.y + texture(fissures, lp.xy * 0.09).r * w.z;
	float line = 1.0 - smoothstep(0.0, 0.05, f);
	float where = smoothstep(0.5, 0.66, noise3(lp * 0.07 + 31.0)) * (1.0 - sol);
	float breathe = 0.65 + 0.35 * sin(TIME * 0.7 + big * 9.0);
	vec3 vc = mix(veine_a, veine_b, smoothstep(0.35, 0.65, noise3(lp * 0.05 + 3.0)));
	EMISSION = vc * line * where * breathe * veine_force * (0.55 + 0.9 * eveil);
}

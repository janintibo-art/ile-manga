// V160 : les champignons lumineux des Strates (les Jardins d'Ombre). Le chapeau : plus sombre au sommet,
// translucide et lumineux vers le bord (un liseré qui s'allume, plus fort vu de biais), semé de taches
// pâles qui brillent, de fines stries qui rayonnent ; sa lueur respire lentement, chaque champignon à
// son rythme. Le dessous (lamelles = 1) : les lamelles fines qui rayonnent du pied, allumées vers le bord.
// UV du chapeau (boucan_kit_v75._dome) : u = 0..3 autour, v = 1 au bord, 0 au sommet ; UV du dessous
// (azur_kit_v56.disc, tile = le rayon) : le disque unité.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 couleur : source_color = vec3(0.4, 1.0, 0.6);
uniform float force = 1.3;
uniform float lamelles = 0.0;

varying vec3 wp;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float facing = clamp(dot(n, normalize(VIEW)), 0.0, 1.0);
	float fres = pow(1.0 - facing, 2.0);
	float souffle = 0.85 + 0.15 * sin(TIME * 0.7 + wp.x * 0.37 + wp.z * 0.29);
	if (lamelles < 0.5) {
		float v = clamp(UV.y, 0.0, 1.0);
		float a = UV.x;
		// les taches : une par case (15 cases autour, raccordées), plutôt sur le haut
		vec2 q = vec2(a * 5.0, v * 5.0);
		vec2 cell = floor(q);
		vec2 f = fract(q);
		vec2 id = vec2(mod(cell.x, 15.0), cell.y);
		float h = h2(id);
		vec2 c = vec2(0.25 + 0.5 * h2(id + 3.1), 0.25 + 0.5 * h2(id + 7.7));
		float rr = 0.12 + 0.2 * h;
		float d = length(f - c);
		float aa = fwidth(d) + 0.01;
		float tache = (1.0 - smoothstep(rr - aa, rr + aa, d)) * step(0.35, h) * (1.0 - smoothstep(0.55, 0.85, v));
		// les stries qui rayonnent (raccordées : 30 tours de sinus pour u = 0..3)
		float st = 0.5 + 0.5 * sin(a * 6.2831853 * 10.0 + sin(v * 9.0 + a * 4.0) * 0.8);
		float bord = v * v;
		vec3 fond = mix(couleur * 0.18, couleur * 0.55, bord) * (0.9 + 0.1 * st);
		ALBEDO = mix(fond, vec3(0.92, 0.94, 0.9), tache * 0.7);
		ROUGHNESS = 0.38;
		SPECULAR = 0.6;
		EMISSION = (couleur * (0.18 + 1.1 * bord + 1.3 * fres) * (0.85 + 0.15 * st) + mix(couleur, vec3(1.0), 0.5) * tache * 0.9) * force * souffle;
	} else {
		// le dessous : les lamelles
		float rad = length(UV);
		float ang = atan(UV.y, UV.x) / 6.2831853;
		float k = fract(ang * 72.0);
		float w = fwidth(ang * 72.0) + 0.02;
		float lame = 1.0 - smoothstep(0.0, 0.18 + w, abs(k - 0.5) * 2.0 - 0.6);
		float loin = smoothstep(0.2, 0.95, rad);
		ALBEDO = couleur * mix(0.12, 0.32, lame) * (0.6 + 0.4 * loin);
		ROUGHNESS = 0.6;
		SPECULAR = 0.3;
		EMISSION = couleur * (0.08 + (0.25 + 0.9 * lame) * loin) * force * souffle;
	}
}

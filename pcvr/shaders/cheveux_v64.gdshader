shader_type spatial;
// V64 : les cheveux et les barbes — mèches alpha (atlas de brins), reflet anisotrope le long
// des mèches, racines plus sombres, lumière qui traverse les pointes.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 couleur : source_color = vec3(0.2, 0.13, 0.08);
uniform float racine = 0.7;
uniform float seuil = 0.42;
uniform float coupe = 99.0;      // sous un chapeau : pas de mèches au-dessus de cette hauteur (repos)

varying float ry;

void vertex() {
	ry = CUSTOM0.x;
}

void fragment() {
	if (ry > coupe) {
		discard;
	}
	vec4 t = texture(tex, UV);
	float v = UV.y;
	// les cheveux blancs ne sont jamais d'un blanc pur : on plafonne la teinte (sinon le ciel les bleuit)
	vec3 base = couleur;
	float m = max(base.r, max(base.g, base.b));
	if (m > 0.62) {
		base *= 0.62 / m;
	}
	// les cheveux clairs montrent davantage les brins (plus de contraste entre eux)
	float clair = smoothstep(0.25, 0.6, m);
	vec3 brin = mix(t.rgb, t.rgb * t.rgb / 0.7, clair);
	vec3 c = base * brin * COLOR.rgb * mix(racine, 1.0, smoothstep(0.0, 0.3, v));
	ALBEDO = c;
	AO = mix(0.55, 1.0, smoothstep(0.0, 0.5, v));
	AO_LIGHT_AFFECT = 0.0;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = seuil;
	ALPHA_ANTIALIASING_EDGE = 0.3;
	ROUGHNESS = 0.55;
	SPECULAR = 0.25;
	ANISOTROPY = 0.7;
	ANISOTROPY_FLOW = vec2(1.0, 0.0);
	BACKLIGHT = c * 0.5;
}

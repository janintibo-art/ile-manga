// V115 : la roche de la Fosse d'Azur, au fond de la mer (tools/generate_fosse_v115.py). Un basalte
// bleu-gris, en couches à peine marquées, projeté selon la pente (triplanaire) ; sur ce qui regarde le
// haut, le sédiment : un sable fin, gris-beige, ridé ; au creux, l'ombre (COLOR.r : l'ouverture) ;
// autour de la cheminée hydrothermale (COLOR.a), une roche noire tachée de rouille et de soufre.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D roche_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roche_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sable_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 roche_c : source_color = vec3(0.42, 0.47, 0.52);
uniform vec3 sable_c : source_color = vec3(0.62, 0.6, 0.55);

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 tri(sampler2D t, vec3 p, vec3 w, float s) {
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}

void fragment() {
	vec3 w = pow(abs(wnrm), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 r1 = tri(roche_tex, wpos, w, 0.11);
	vec3 r2 = tri(roche_tex, wpos, w, 0.023);
	float lum = dot(r1, vec3(0.33)) * 0.6 + dot(r2, vec3(0.33)) * 0.8;
	// des couches à peine marquées (le basalte s'est déposé en coulées)
	float band = 0.9 + 0.1 * sin(wpos.y * 0.55 + sin(wpos.x * 0.04) * 2.0 + sin(wpos.z * 0.05) * 1.5);
	vec3 rock = roche_c * (0.45 + lum * 0.75) * band;
	vec3 rn = texture(roche_n, wpos.xz * 0.11).rgb * w.y + texture(roche_n, wpos.zy * 0.11).rgb * w.x + texture(roche_n, wpos.xy * 0.11).rgb * w.z;
	// le sédiment (sur ce qui regarde le haut)
	vec2 suv = wpos.xz * 0.16;
	vec3 sand = texture(sable_tex, suv).rgb;
	sand *= 0.8 + 0.35 * texture(sable_tex, suv * 0.13 + vec2(0.37, 0.71)).r;
	sand = sable_c * (0.55 + dot(sand, vec3(0.33)) * 0.8);
	vec3 sn = texture(sable_n, suv).rgb;
	float sed = smoothstep(0.25, 0.75, COLOR.g + (lum - 0.5) * 0.4);
	vec3 alb = mix(rock, sand, sed);
	// la cheminée : roche noire, taches de rouille et de soufre
	float v = COLOR.a;
	if (v > 0.01) {
		float tache = smoothstep(0.55, 0.75, texture(roche_tex, wpos.xz * 0.3 + wpos.y * 0.07).r);
		vec3 noir = vec3(0.08, 0.075, 0.07) * (0.7 + lum * 0.5);
		noir = mix(noir, vec3(0.42, 0.24, 0.1), tache * 0.6);
		noir = mix(noir, vec3(0.55, 0.5, 0.22), smoothstep(0.7, 0.9, lum) * 0.5);
		alb = mix(alb, noir, smoothstep(0.0, 0.5, v));
	}
	float ao = mix(0.35, 1.0, COLOR.r);
	ALBEDO = alb * ao;
	NORMAL_MAP = mix(rn, sn, sed);
	NORMAL_MAP_DEPTH = 1.3;
	ROUGHNESS = mix(0.82, 0.95, sed);
	SPECULAR = 0.3;
}

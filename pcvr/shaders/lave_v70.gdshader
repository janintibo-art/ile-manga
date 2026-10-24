// V70 : la lave de l'Île de Braise (le Cercle de Feu autour de la Citadelle, les coulées du
// Grand Brasier, le lac du cratère). Les UV sont en mètres : x le long du courant, y en travers.
// Deux couches de lave liquide qui glissent à des vitesses différentes ; par-dessus, des plaques
// de croûte noire, plus lentes, dont les fissures rougeoient ; une légère houle.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D lave_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D croute_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D croute_e : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float speed = 0.35;            // m/s le long du courant
uniform float tile = 0.09;             // répétitions par mètre
uniform float crust_amount = 0.52;     // 0 : toute liquide, 1 : toute croûtée
uniform float glow = 3.2;
uniform float heave = 0.06;

varying vec3 wp;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x),
		mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise2(p) * 0.55 + noise2(p * 2.1 + 7.3) * 0.3 + noise2(p * 4.3 + 1.7) * 0.15;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 0.8 + wp.x * 0.31 + wp.z * 0.23) * heave + sin(TIME * 1.3 + wp.x * 0.7 - wp.z * 0.5) * heave * 0.4;
}

void fragment() {
	vec2 uv = UV * tile;
	float t = TIME * speed * tile;
	vec3 hot = texture(lave_tex, uv + vec2(-t, 0.0)).rgb;
	vec3 hot2 = texture(lave_tex, uv * 0.53 + vec2(0.37, 0.11) + vec2(-t * 0.62, 0.0)).rgb;
	hot = mix(hot, hot2, 0.45);
	vec2 cuv = uv * 0.9 + vec2(-t * 0.8, 0.0);
	float m = fbm(UV * 0.22 + vec2(-TIME * speed * 0.18, 0.0));
	float cm = smoothstep(crust_amount - 0.1, crust_amount + 0.1, m);
	vec3 crust = texture(croute_tex, cuv).rgb * 0.8;
	float ce = texture(croute_e, cuv).r;
	ALBEDO = mix(hot * 0.3, crust, cm);
	float pulse = 0.85 + 0.15 * sin(TIME * 1.7 + m * 9.0);
	EMISSION = mix(hot * glow * pulse, vec3(1.0, 0.3, 0.06) * ce * 2.0, cm);
	ROUGHNESS = mix(0.32, 0.88, cm);
	SPECULAR = 0.5;
}

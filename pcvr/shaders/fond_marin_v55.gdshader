// V55 : le fond de la mer — sable ridé, roche de récif sur les pentes (couleur du sommet,
// canal r), creux plus sombres (canal g), et les caustiques : le réseau lumineux que la
// houle projette sur le fond, qui danse et s'efface avec la profondeur.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D caustic_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float sea_y = -0.42;
uniform float caustic_strength = 1.1;
uniform vec3 caustic_color : source_color = vec3(0.75, 0.95, 1.0);

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = UV;
	// Le sable, à deux échelles pour casser la répétition
	vec3 sand = texture(sand_tex, uv).rgb;
	sand *= 0.85 + 0.3 * texture(sand_tex, uv * 0.17 + vec2(0.31, 0.77)).r;
	vec3 sn = texture(sand_n, uv).rgb;
	// La roche : projetée selon la pente (de côté sur les parois)
	vec2 ruv = abs(wnrm.x) > abs(wnrm.z) ? wpos.zy / 7.0 : wpos.xy / 7.0;
	ruv = mix(ruv, wpos.xz / 7.0, smoothstep(0.75, 0.95, wnrm.y));
	vec3 rock = texture(rock_tex, ruv).rgb;
	vec3 rn = texture(rock_n, ruv).rgb;
	float rk = clamp(sqrt(COLOR.r) + (rock.r - 0.4) * 0.5, 0.0, 1.0);
	rk = smoothstep(0.3, 0.55, rk);
	vec3 albedo = mix(sand * 0.82, rock, rk) * mix(0.55, 1.0, COLOR.g);
	ALBEDO = albedo;
	NORMAL_MAP = mix(sn, rn, rk);
	NORMAL_MAP_DEPTH = 1.2;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
	// Caustiques : deux réseaux qui glissent l'un sur l'autre (on garde leur minimum)
	float depth = sea_y - wpos.y;
	float c1 = texture(caustic_tex, wpos.xz / 6.5 + vec2(TIME * 0.035, TIME * 0.022)).r;
	float c2 = texture(caustic_tex, wpos.xz / 8.7 + vec2(-TIME * 0.027, TIME * 0.031)).r;
	float c = min(c1, c2);
	c = c * c * 1.6;
	float fade = exp(-max(depth, 0.0) * 0.06) * step(0.0, depth) * max(wnrm.y, 0.0) * COLOR.g;
	EMISSION = caustic_color * c * caustic_strength * fade * 0.42;
}

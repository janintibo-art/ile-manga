// V55 : la surface de la mer vue d'en dessous. Juste au-dessus de soi, la « fenêtre de
// Snell » : le ciel, clair et tremblant ; plus loin, au-delà de ~48°, la surface devient un
// miroir sombre (réflexion totale) qui renvoie le bleu des profondeurs. Des reflets dansent.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform sampler2D ripple_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 deep : source_color = vec3(0.04, 0.24, 0.3);
uniform vec3 sky : source_color = vec3(0.72, 0.92, 0.96);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n1 = texture(ripple_n, wpos.xz / 7.0 + vec2(TIME * 0.03, TIME * 0.02)).rgb * 2.0 - 1.0;
	vec3 n2 = texture(ripple_n, wpos.xz / 11.0 - vec2(TIME * 0.025, -TIME * 0.018)).rgb * 2.0 - 1.0;
	vec2 wob = (n1.xy + n2.xy) * 0.12;
	vec3 view_w = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float cos_up = clamp(-view_w.y + wob.x, 0.0, 1.0);        // 1 : on regarde droit vers le haut
	float window = smoothstep(0.6, 0.72, cos_up);
	float sparkle = pow(clamp(0.5 + wob.y * 3.0, 0.0, 1.0), 8.0);
	vec3 col = mix(deep * (0.8 + wob.x), sky, window) + vec3(sparkle) * window * 0.5;
	ALBEDO = col;
}

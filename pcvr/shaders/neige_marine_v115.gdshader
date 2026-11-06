// V115 : la neige marine, autour du Dôme d'Azur : de minuscules flocons blancs qui tombent très
// lentement dans l'eau (ce qui reste de la vie d'en haut). Des particules qui suivent la caméra ; on
// ne les montre que dans l'eau : celles qui tombent dans un volume d'air (un dôme, une galerie, le tube
// du Funiculaire : les mêmes volumes que le verre, shaders/verre_abysse_v115) sont jetées. Dessinées
// après le verre (déjà « noyées » : elles pâlissent avec la distance).
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D flocon : source_color, filter_linear, repeat_disable;
uniform vec3 couleur : source_color = vec3(0.72, 0.86, 0.92);
uniform float force = 0.55;
uniform float densite = 0.03;
uniform int n_ell = 0;
uniform vec4 ell_c[4];
uniform vec4 ell_r[4];
uniform int n_cap = 0;
uniform vec4 cap_a[6];
uniform vec4 cap_b[6];

varying vec3 centre;
varying float jete;

void vertex() {
	centre = MODEL_MATRIX[3].xyz;
	jete = 0.0;
	// les dômes : la coupole (un ellipsoïde) et, dessous, le tambour (un cylindre de hauteur ell_c.w)
	for (int k = 0; k < n_ell; k++) {
		vec3 dd = centre - ell_c[k].xyz;
		vec3 q = dd / ell_r[k].xyz;
		if (dot(q, q) < 1.0 || (length(dd.xz) < ell_r[k].x && dd.y < 0.0 && dd.y > -ell_c[k].w - 0.5)) {
			jete = 1.0;
		}
	}
	for (int k = 0; k < n_cap; k++) {
		vec3 ba = cap_b[k].xyz - cap_a[k].xyz;
		float t = clamp(dot(centre - cap_a[k].xyz, ba) / dot(ba, ba), 0.0, 1.0);
		if (length(centre - cap_a[k].xyz - ba * t) < cap_a[k].w + 0.2) {
			jete = 1.0;
		}
	}
	// face à la caméra (comme les particules « billboard » de Godot)
	mat4 mw = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * mw;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	if (jete > 0.5) {
		discard;
	}
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float d = length(centre - cam);
	float a = texture(flocon, UV).a * COLOR.a * force * exp(-densite * max(d - 4.0, 0.0)) * smoothstep(0.6, 2.5, d);
	if (a < 0.004) {
		discard;
	}
	ALBEDO = couleur * texture(flocon, UV).rgb;
	ALPHA = a;
}

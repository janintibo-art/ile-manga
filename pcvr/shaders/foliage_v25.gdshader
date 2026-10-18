// V25 : végétation réaliste — vent, lumière qui traverse les feuilles, découpe nette des contours.
// UV2.x = souplesse (0 au pied, 1 en bout de feuille), UV2.y = position dans le feuillage (0 au cœur, 1 dehors).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, world_vertex_coords;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_texture = true;
uniform bool use_normal = false;
uniform bool tint_petals = false;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 base_color : source_color = vec3(0.16, 0.3, 0.08);
uniform vec3 tip_color : source_color = vec3(0.55, 0.68, 0.28);
uniform float wind_strength = 0.12;
uniform float wind_speed = 1.3;
uniform float translucency = 0.4;
uniform float roughness_value = 0.78;

void vertex() {
	float flex = UV2.x;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = dot(origin.xz, vec2(0.21, 0.17));
	// Rafales lentes qui balayent l'île, plus une oscillation propre à chaque plante.
	float gust = 0.55 + 0.45 * sin(TIME * wind_speed * 0.31 + VERTEX.x * 0.045 + VERTEX.z * 0.03);
	float sway = sin(TIME * wind_speed + phase) * gust + sin(TIME * wind_speed * 2.7 + phase * 1.9 + VERTEX.y * 1.3) * 0.22;
	vec3 dir = normalize(vec3(1.0, 0.0, 0.38));
	VERTEX += dir * sway * wind_strength * flex;
	VERTEX.y -= abs(sway) * wind_strength * flex * flex * 0.25;
}

void fragment() {
	vec4 tex = use_texture ? texture(albedo_tex, UV) : vec4(1.0);
	vec3 albedo = use_texture ? tex.rgb : mix(base_color, tip_color, UV.y);
	vec3 tone = COLOR.rgb * tint;
	if (tint_petals) {
		// Seuls les pétales (pixels clairs et peu saturés) prennent la couleur de la fleur.
		float hi = max(albedo.r, max(albedo.g, albedo.b));
		float sat = hi - min(albedo.r, min(albedo.g, albedo.b));
		float petal = (1.0 - smoothstep(0.05, 0.14, sat)) * smoothstep(0.55, 0.75, hi);
		albedo = mix(albedo, albedo * tone, petal);
	} else {
		albedo *= tone;
	}
	// Ombre douce au cœur du feuillage et au pied de l'herbe.
	float inner = mix(0.58, 1.0, clamp(UV2.y, 0.0, 1.0));
	ALBEDO = albedo * inner;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = roughness_value;
	SPECULAR = 0.3;
	BACKLIGHT = albedo * translucency * inner;
}

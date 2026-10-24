// V70 : la végétation de l'Île de Braise (le même shader que foliage_v25 : le vent, la lumière
// qui traverse les feuilles, la découpe des contours) ; en plus, une lueur : les feuilles des
// arbres de braise rougeoient comme des charbons (glow_mode 1), les fissures de leur écorce
// gardent un peu de feu (glow_mode 2 : les pixels rouges et saturés). « glow » monte la nuit.
// UV2.x = souplesse (0 au pied, 1 en bout de feuille), UV2.y = position dans le feuillage.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, world_vertex_coords;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_texture = true;
uniform bool use_normal = false;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 base_color : source_color = vec3(0.16, 0.3, 0.08);
uniform vec3 tip_color : source_color = vec3(0.55, 0.68, 0.28);
uniform float wind_strength = 0.12;
uniform float wind_speed = 1.3;
uniform float translucency = 0.4;
uniform float roughness_value = 0.78;
uniform int glow_mode = 1;
uniform vec3 glow_tint : source_color = vec3(1.0, 0.45, 0.12);
uniform float glow = 1.0;

varying float v_phase;

void vertex() {
	float flex = UV2.x;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = dot(origin.xz, vec2(0.21, 0.17));
	v_phase = phase;
	float gust = 0.55 + 0.45 * sin(TIME * wind_speed * 0.31 + VERTEX.x * 0.045 + VERTEX.z * 0.03);
	float sway = sin(TIME * wind_speed + phase) * gust + sin(TIME * wind_speed * 2.7 + phase * 1.9 + VERTEX.y * 1.3) * 0.22;
	vec3 dir = normalize(vec3(1.0, 0.0, 0.38));
	VERTEX += dir * sway * wind_strength * flex;
	VERTEX.y -= abs(sway) * wind_strength * flex * flex * 0.25;
}

void fragment() {
	vec4 tex = use_texture ? texture(albedo_tex, UV) : vec4(1.0);
	vec3 albedo = use_texture ? tex.rgb : mix(base_color, tip_color, UV.y);
	albedo *= COLOR.rgb * tint;
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
	// la lueur : elle respire lentement, chaque arbre à son rythme
	float breathe = 0.78 + 0.22 * sin(TIME * 0.9 + v_phase * 3.0);
	if (glow_mode == 1) {
		float hot = smoothstep(0.25, 0.9, max(albedo.r, albedo.g * 1.4));
		EMISSION = albedo * glow_tint * hot * glow * breathe * mix(0.6, 1.0, UV2.y);
	} else if (glow_mode == 2) {
		float red = clamp((albedo.r - max(albedo.g, albedo.b)) * 3.0, 0.0, 1.0);
		EMISSION = glow_tint * red * red * glow * breathe * 1.5;
	}
}

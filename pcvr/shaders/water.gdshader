// Océan VR (opaque, léger pour le casque). V24 : vaguelettes en relief, couleur selon la distance au rivage.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D water_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ripple_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wave_strength : hint_range(0.0, 1.5) = 0.75;
uniform vec3 shallow_color : source_color = vec3(0.13, 0.55, 0.56);
uniform vec3 deep_color : source_color = vec3(0.015, 0.12, 0.22);
varying vec3 water_position;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(world.x * 0.098 + TIME * 0.8) * 0.12 + cos(world.z * 0.15 + TIME * 0.61) * 0.07;
	VERTEX.y += swell * wave_strength;
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv1 = water_position.xz * 0.045 + vec2(TIME * 0.012, TIME * 0.007);
	vec2 uv2 = water_position.xz * 0.11 + vec2(-TIME * 0.018, TIME * 0.013);
	vec3 n1 = texture(ripple_n, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(ripple_n, uv2).xyz * 2.0 - 1.0;
	NORMAL_MAP = normalize(vec3(n1.xy + n2.xy, n1.z * n2.z)) * 0.5 + 0.5;

	// Lagon clair près de l'île, bleu profond au large.
	float radius = length(water_position.xz);
	float lagoon = 1.0 - smoothstep(64.0, 105.0, radius);
	vec3 col = mix(deep_color, shallow_color, lagoon);
	col *= mix(0.92, 1.06, texture(water_tex, uv1 * 2.0).r);
	float coast = 63.5 + sin(water_position.x * 0.10) * 2.3 + cos(water_position.z * 0.13) * 1.7;
	float foam = (1.0 - smoothstep(0.4, 2.6, abs(radius - coast))) * smoothstep(0.3, 0.8, n1.x * 0.5 + 0.5) * 0.8;
	ALBEDO = mix(col, vec3(0.9, 0.95, 0.96), foam);
	ROUGHNESS = mix(0.06, 0.6, foam);
	METALLIC = 0.0;
	SPECULAR = 0.6;
}

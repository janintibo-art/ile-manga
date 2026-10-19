// Océan VR (opaque, léger pour le casque). V24 : vaguelettes en relief, couleur selon la distance au rivage.
// V48 : le lagon et l'écume suivent le vrai rivage des quatre îles (carte des fonds calculée au
// démarrage : hauteur du terrain, 3 m par pixel), et non plus un cercle autour de l'île du village.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D water_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ripple_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wave_strength : hint_range(0.0, 1.5) = 0.75;
uniform vec3 shallow_color : source_color = vec3(0.13, 0.55, 0.56);
uniform vec3 deep_color : source_color = vec3(0.015, 0.12, 0.22);
uniform sampler2D shore_map : filter_linear, repeat_disable;
uniform vec2 shore_origin = vec2(-800.0, -800.0);
uniform float shore_size = 1600.0;
uniform bool has_shore = false;
varying vec3 water_position;

// V52 : la barque (boat_v29.gd) — l'eau ne se dessine pas à l'intérieur de la coque.
uniform mat4 boat_inv = mat4(1.0);
uniform bool boat_on = false;

bool in_boat(vec3 w) {
	vec3 b = (boat_inv * vec4(w, 1.0)).xyz;
	const float L = 4.6;
	const float B = 1.6;
	const float D = 0.72;
	if (abs(b.z) > L * 0.5 || b.y > D + 0.45) {
		return false;
	}
	float s = (L * 0.5 - b.z) / L;
	float wd = s < 0.42 ? B * 0.5 * (0.64 + 0.36 * sin(1.5708 * s / 0.42)) : B * 0.5 * pow(max(cos(1.5708 * (s - 0.42) / 0.58), 0.0), 0.75);
	float keel = 0.28 * pow(max(s - 0.72, 0.0) / 0.28, 2.0) + 0.05 * pow(max(0.15 - s, 0.0) / 0.15, 2.0);
	if (b.y < keel) {
		return false;
	}
	float top = D + 0.2 * s * s * s;
	float t = clamp((b.y - keel) / max(top - keel, 0.01), 0.0, 1.0);
	float a = acos(1.0 - t) / 1.5708;
	float lat = wd * pow(sin(a * 1.5708), 0.7);
	return abs(b.x) < lat + 0.02;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(world.x * 0.098 + TIME * 0.8) * 0.12 + cos(world.z * 0.15 + TIME * 0.61) * 0.07;
	VERTEX.y += swell * wave_strength;
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (boat_on && in_boat(water_position)) {
		discard;
	}
	vec2 uv1 = water_position.xz * 0.045 + vec2(TIME * 0.012, TIME * 0.007);
	vec2 uv2 = water_position.xz * 0.11 + vec2(-TIME * 0.018, TIME * 0.013);
	vec3 n1 = texture(ripple_n, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(ripple_n, uv2).xyz * 2.0 - 1.0;
	// V53 : au loin, les petites vaguelettes s'effacent au profit d'une houle large : la
	// texture ne se répète plus en moiré jusqu'à l'horizon.
	float view_dist = length(CAMERA_POSITION_WORLD - water_position);
	float far = smoothstep(45.0, 320.0, view_dist);
	vec3 n3 = texture(ripple_n, water_position.xz * 0.0095 + vec2(TIME * 0.004, -TIME * 0.003)).xyz * 2.0 - 1.0;
	vec3 ripple = normalize(vec3(n1.xy + n2.xy, n1.z * n2.z));
	ripple = normalize(mix(ripple, vec3(n3.xy * 0.7, 1.0), far * 0.75));
	ripple.xy *= mix(1.0, 0.35, far);
	NORMAL_MAP = ripple * 0.5 + 0.5;

	// Lagon clair près de l'île, bleu profond au large.
	float lagoon;
	float foam;
	if (has_shore) {
		// Hauteur du fond sous l'eau (de -12 m à +2 m), lue dans la carte des rivages.
		vec2 suv = (water_position.xz - shore_origin) / shore_size;
		float ground = texture(shore_map, suv).r * 14.0 - 12.0;
		float wob = sin(water_position.x * 0.21 + TIME * 0.7) * 0.12 + cos(water_position.z * 0.17 - TIME * 0.5) * 0.12;
		lagoon = smoothstep(-7.5, -1.2, ground) * 0.9;
		float edge = abs(ground + 0.3 + wob);
		foam = (1.0 - smoothstep(0.1, 2.4, edge)) * mix(0.55, 1.0, smoothstep(0.3, 0.8, n1.x * 0.5 + 0.5)) * 0.9;
	} else {
		float radius = length(water_position.xz);
		lagoon = 1.0 - smoothstep(64.0, 105.0, radius);
		float coast = 63.5 + sin(water_position.x * 0.10) * 2.3 + cos(water_position.z * 0.13) * 1.7;
		foam = (1.0 - smoothstep(0.4, 2.6, abs(radius - coast))) * smoothstep(0.3, 0.8, n1.x * 0.5 + 0.5) * 0.8;
	}
	vec3 col = mix(deep_color, shallow_color, lagoon);
	col *= mix(1.0, mix(0.92, 1.06, texture(water_tex, uv1 * 2.0).r), 1.0 - far);
	ALBEDO = mix(col, vec3(0.9, 0.95, 0.96), foam);
	ROUGHNESS = mix(0.06, 0.6, foam);
	METALLIC = 0.0;
	SPECULAR = 0.6;
}

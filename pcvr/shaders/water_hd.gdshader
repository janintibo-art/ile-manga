// V24 : océan haute définition (PC) — houle, réfraction, couleur selon la profondeur, écume de rivage.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx, depth_draw_always;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D ripple_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 shallow_color : source_color = vec3(0.16, 0.62, 0.62);
uniform vec3 deep_color : source_color = vec3(0.012, 0.11, 0.21);
uniform float absorption = 0.42;
uniform float wave_strength = 1.0;

varying vec3 wpos;

vec3 gerstner(vec2 p, vec2 dir, float length_m, float amp, float speed, inout vec3 tangent, inout vec3 binormal) {
	float k = 6.28318 / length_m;
	vec2 d = normalize(dir);
	float f = k * (dot(d, p) - speed * TIME);
	float steep = 0.55 / (k * amp * 4.0 + 0.001);
	float a = amp * wave_strength;
	tangent += vec3(-d.x * d.x * steep * a * k * sin(f), d.x * a * k * cos(f), -d.x * d.y * steep * a * k * sin(f));
	binormal += vec3(-d.x * d.y * steep * a * k * sin(f), d.y * a * k * cos(f), -d.y * d.y * steep * a * k * sin(f));
	return vec3(d.x * steep * a * cos(f), a * sin(f), d.y * steep * a * cos(f));
}

float to_ndc_z(float d) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return d * 2.0 - 1.0;
#else
	return d;
#endif
}

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
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 offset = vec3(0.0);
	offset += gerstner(world.xz, vec2(1.0, 0.35), 64.0, 0.16, 5.0, tangent, binormal);
	offset += gerstner(world.xz, vec2(-0.4, 1.0), 41.0, 0.09, 4.0, tangent, binormal);
	offset += gerstner(world.xz, vec2(0.7, -0.8), 27.0, 0.05, 3.2, tangent, binormal);
	VERTEX += offset;
	NORMAL = normalize(cross(binormal, tangent));
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (boat_on && in_boat(wpos)) {
		discard;
	}
	// Vaguelettes : deux couches de relief qui défilent en sens contraires.
	vec2 uv1 = wpos.xz * 0.045 + vec2(TIME * 0.012, TIME * 0.007);
	vec2 uv2 = wpos.xz * 0.11 + vec2(-TIME * 0.018, TIME * 0.013);
	vec3 n1 = texture(ripple_n, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(ripple_n, uv2).xyz * 2.0 - 1.0;
	vec3 ripple = normalize(vec3(n1.xy + n2.xy, n1.z * n2.z));
	float view_dist = length(CAMERA_POSITION_WORLD - wpos);
	ripple.xy *= mix(1.0, 0.25, smoothstep(40.0, 400.0, view_dist));
	NORMAL_MAP = ripple * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	// Profondeur d'eau sous ce pixel (convention de profondeur selon le moteur de rendu).
	float raw_depth = to_ndc_z(texture(depth_tex, SCREEN_UV).r);
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	behind.xyz /= behind.w;
	float water_depth = max(VERTEX.z - behind.z, 0.0);

	// Réfraction : l'image du fond est légèrement déformée par les vaguelettes.
	vec2 refr_uv = SCREEN_UV + ripple.xy * 0.025 * clamp(water_depth * 0.5, 0.0, 1.0);
	float refr_depth = to_ndc_z(texture(depth_tex, refr_uv).r);
	vec4 refr_behind = INV_PROJECTION_MATRIX * vec4(refr_uv * 2.0 - 1.0, refr_depth, 1.0);
	refr_behind.xyz /= refr_behind.w;
	if (refr_behind.z > VERTEX.z) {
		refr_uv = SCREEN_UV;
	}
	vec3 under = textureLod(screen_tex, refr_uv, 0.0).rgb;

	// Absorption : turquoise sur les hauts-fonds, bleu nuit au large.
	// Le fond vu à travers l'eau passe en émission (déjà éclairé) ; la couleur de l'eau
	// elle-même est diffusée par la lumière du soleil.
	float murk = clamp(1.0 - exp(-water_depth * absorption), 0.0, 1.0);
	vec3 water_col = mix(shallow_color, deep_color, smoothstep(0.0, 1.0, murk * 1.2));
	vec3 transmitted = under * mix(vec3(0.82, 0.98, 0.95), vec3(0.45, 0.8, 0.85), murk) * (1.0 - murk);

	// Écume sur le rivage, découpée par le relief des vaguelettes.
	float foam_line = 1.0 - smoothstep(0.0, 0.55, water_depth);
	float foam_tex = smoothstep(0.35, 0.8, n1.x * 0.5 + 0.5 + sin(TIME * 1.3 + wpos.x * 0.6) * 0.15);
	float foam = clamp(foam_line * (0.45 + foam_tex * 0.7), 0.0, 1.0);
	ALBEDO = mix(water_col * murk, vec3(0.92, 0.96, 0.97), foam * 0.85);
	EMISSION = transmitted * (1.0 - foam * 0.85);
	ROUGHNESS = mix(0.03, 0.6, foam);
	METALLIC = 0.0;
	SPECULAR = 0.6;
}

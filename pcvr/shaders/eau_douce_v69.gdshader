// V69 : l'eau douce (le Lac de la Lune, le Cénote sacré, les bassins des donjons) : une eau
// calme, des rides qui glissent, la couleur qui fonce avec la profondeur (le fond se voit au
// bord), le ciel qui s'y reflète.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_always;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D ripple_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 deep : source_color = vec4(0.04, 0.18, 0.24, 1.0);
uniform vec4 shallow : source_color = vec4(0.16, 0.42, 0.42, 1.0);
uniform float clarity = 2.4;      // mètres d'eau avant qu'on ne voie plus le fond
uniform float ripple_scale = 0.11;

varying vec3 wpos;

float to_ndc_z(float d) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return d * 2.0 - 1.0;
#else
	return d;
#endif
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = wpos.xz * ripple_scale;
	vec3 n1 = texture(ripple_n, uv + vec2(TIME * 0.012, TIME * 0.007)).xyz * 2.0 - 1.0;
	vec3 n2 = texture(ripple_n, uv * 1.7 - vec2(TIME * 0.009, -TIME * 0.011)).xyz * 2.0 - 1.0;
	vec3 nm = normalize(vec3((n1.xy + n2.xy) * 0.18, 1.0));
	// la profondeur d'eau sous ce pixel
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, to_ndc_z(d), 1.0);
	world.xyz /= world.w;
	float depth = clamp(wpos.y - world.y, 0.0, 50.0);
	float k = 1.0 - exp(-depth / clarity);
	ALBEDO = mix(shallow.rgb, deep.rgb, k);
	ALPHA = clamp(0.35 + k * 0.62, 0.0, 0.97);
	NORMAL_MAP = nm * 0.5 + 0.5;
	ROUGHNESS = 0.04;
	METALLIC = 0.1;
	SPECULAR = 0.7;
}

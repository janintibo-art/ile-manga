// V55 : ce qui ondule sous l'eau — laminaires, herbiers, anémones.
// Le pied ne bouge pas ; plus on monte, plus la houle balance (deux sinus décalés, phase
// prise sur la position de chaque plante pour qu'elles ne bougent pas toutes ensemble).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D caustic_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = true;
uniform float sway = 1.0;            // amplitude en haut (m, dans l'espace de la plante)
uniform float speed = 0.7;
uniform float height_ref = 1.0;      // hauteur du maillage (le pied à 0)
uniform float sea_y = -0.42;

varying vec3 wpos;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float k = clamp(VERTEX.y / height_ref, 0.0, 1.0);
	float w = k * k * (3.0 - 2.0 * k);
	float ph = origin.x * 0.21 + origin.z * 0.17;
	float sx = sin(TIME * speed + ph) * 0.7 + sin(TIME * speed * 2.3 + ph * 1.7 + VERTEX.y * 0.8) * 0.3;
	float sz = cos(TIME * speed * 0.8 + ph * 1.3) * 0.6 + sin(TIME * speed * 1.9 + VERTEX.y * 1.1) * 0.25;
	// l'amplitude est donnée en mètres : on la ramène dans l'espace local (échelle de l'instance)
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	VERTEX.x += sx * sway * w / max(sc.x, 0.001);
	VERTEX.z += sz * sway * w / max(sc.z, 0.001);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 col = use_tex ? texture(leaf_tex, UV) : vec4(1.0);
	if (use_tex && col.a < 0.45) {
		discard;
	}
	ALBEDO = col.rgb * COLOR.rgb;
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	BACKLIGHT = vec3(0.35, 0.4, 0.2) * col.rgb;
	float c = texture(caustic_tex, wpos.xz / 6.5 + vec2(TIME * 0.035, TIME * 0.022)).r;
	float depth = sea_y - wpos.y;
	EMISSION = vec3(0.6, 0.85, 0.9) * c * c * 0.4 * exp(-max(depth, 0.0) * 0.07) * step(0.0, depth);
}

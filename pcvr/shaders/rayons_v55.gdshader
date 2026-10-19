// V55 : les rayons de soleil sous l'eau — de longues lames de lumière qui descendent de la
// surface, s'évasent et s'éteignent dans la profondeur, en ondulant doucement.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float intensity = 0.08;
uniform vec3 color : source_color = vec3(0.7, 0.92, 1.0);

varying float seed;

void vertex() {
	seed = INSTANCE_CUSTOM.r * 37.0;
}

void fragment() {
	float down = UV.y;                               // 0 en haut (surface), 1 en bas
	float edge = pow(sin(UV.x * 3.14159), 2.0);
	float fade = pow(1.0 - down, 1.6) * smoothstep(0.0, 0.05, down);
	float flick = 0.65 + 0.35 * sin(TIME * 0.7 + seed) * sin(TIME * 1.3 + seed * 1.7);
	float a = edge * fade * flick * intensity;
	// adoucir quand on est dedans (évite un voile plein écran)
	float near = smoothstep(3.0, 14.0, -VERTEX.z) * (1.0 - smoothstep(45.0, 70.0, -VERTEX.z));
	ALBEDO = color * a * near;
}

// V55 : les méduses — cloche translucide qui luit sur les bords, tentacules qui ondulent.
// La cloche « respire » (pulse = 0..1, envoyé par le script), les tentacules traînent.
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.9, 0.45, 0.85);
uniform float pulse = 0.0;
uniform float tentacle = 0.0;       // 1 : maillage de tentacules (ondulation)
uniform float seed = 0.0;
uniform float energy = 1.0;

varying float yy;

void vertex() {
	yy = VERTEX.y;
	if (tentacle > 0.5) {
		float k = clamp(-VERTEX.y / 1.6, 0.0, 1.0);
		VERTEX.x += sin(TIME * 1.7 + seed + VERTEX.y * 3.0) * 0.12 * k;
		VERTEX.z += cos(TIME * 1.3 + seed * 1.7 + VERTEX.y * 2.4) * 0.12 * k;
	} else {
		float sq = 1.0 + pulse * 0.18;
		VERTEX.xz *= sq;
		VERTEX.y *= 1.0 - pulse * 0.2;
	}
}

void fragment() {
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), VIEW)), 2.0);
	float a = tentacle > 0.5 ? 0.35 * (1.0 - clamp(-yy / 1.8, 0.0, 1.0)) : (0.12 + fres * 0.7);
	ALBEDO = tint * a * energy * exp(-length(VERTEX) * 0.035);
}

shader_type spatial;
// V219 : le sol noirci par une explosion : de la suie au bord déchiqueté, et des braises qui rougeoient dans
// ses craquelures (« braise » descend de 1 à 0 en quelques secondes ; « efface » monte de 0 à 1 à la fin).
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 suie : source_color = vec3(0.025, 0.022, 0.02);
uniform vec3 lueur : source_color = vec3(1.0, 0.36, 0.05);
uniform float braise = 1.0;
uniform float efface = 0.0;
uniform float graine = 0.0;

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float r = length(uv);
	float n1 = texture(bruit, UV * 1.3 + vec2(graine, graine * 0.7)).r;
	float n2 = texture(bruit, UV * 3.4 - vec2(graine * 0.3, graine)).r;
	// des langues de suie qui partent du centre
	float rayons = texture(bruit, vec2(atan(uv.y, uv.x) / 6.2832 * 4.0 + graine, 0.3)).r;
	float bord = 0.62 + (n1 - 0.5) * 0.5 + (rayons - 0.5) * 0.45;
	float a = smoothstep(bord, bord - 0.45, r);
	ALBEDO = suie * (0.7 + n2 * 0.6);
	ROUGHNESS = 0.95;
	// les craquelures qui rougeoient : un fil de braise là où le bruit passe par un seuil
	float fil = smoothstep(0.06, 0.0, abs(n2 - 0.5)) * smoothstep(0.75, 0.15, r);
	float coeur = smoothstep(0.5, 0.0, r) * (0.3 + 0.7 * n1);
	float pouls = 0.75 + 0.25 * sin(TIME * 5.0 + n1 * 20.0);
	EMISSION = lueur * (fil * 3.5 + coeur * 1.6) * braise * pouls;
	ALPHA = a * 0.88 * (1.0 - efface);
}

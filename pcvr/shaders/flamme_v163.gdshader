// V163 : la flamme d'un flambeau de bambou (la teuf de la plage) : une goutte de feu qui danse (le bruit
// monte avec le temps), le cœur jaune, le bord orange, la pointe qui se déchire. Allumée la nuit (glow,
// temps_v56.register_glow).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float glow = 0.0;
uniform vec3 coeur_col = vec3(1.0, 0.86, 0.5);   // V164 : la couleur du cœur et du bord de la flamme
uniform vec3 bord_col = vec3(1.0, 0.28, 0.04);

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(a), h2(a + vec2(1.0, 0.0)), f.x), mix(h2(a + vec2(0.0, 1.0)), h2(a + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	if (glow <= 0.001) {
		discard;
	}
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float graine = fract(o.x * 0.37 + o.z * 0.71);
	float y = 1.0 - UV.y;
	float x = (UV.x - 0.5) * 2.0;
	float t = TIME * 2.6 + graine * 40.0;
	float tord = (bruit(vec2(y * 2.5 - t, graine * 9.0)) - 0.5) * 0.7 * y;
	float large = 1.25 * pow(max(y, 0.0), 0.35) * (1.0 - y) + 0.02;
	float d = abs(x - tord) / large;
	float n = bruit(vec2(x * 3.5 + graine * 5.0, y * 5.0 - t * 1.6));
	float a = smoothstep(1.0, 0.35, d + (n - 0.5) * 0.5) * smoothstep(1.0, 0.6, y + n * 0.25) * smoothstep(0.0, 0.06, y);
	vec3 c = mix(bord_col, coeur_col, smoothstep(0.7, 0.05, d) * (1.0 - y * 0.8));
	ALBEDO = c * 1.1;
	ALPHA = clamp(a * glow, 0.0, 1.0);
}

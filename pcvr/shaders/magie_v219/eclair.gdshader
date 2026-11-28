shader_type spatial;
// V219 : le ruban d'un éclair. Il vit : il ondule sans cesse (chaque point glisse de côté, selon un bruit
// qui défile), des pulsations courent le long de lui ; son cœur est blanc, son halo bleu, sa frange violette.
// UV.x traverse le ruban, UV.y le suit ; NORMAL : le côté du ruban ; UV2.x : l'ampleur de l'ondulation en ce
// point (nulle là où l'éclair est tenu) ; UV2.y : une graine par ruban. « force » descend de 1 à 0 à la fin.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 halo : source_color = vec3(0.35, 0.55, 1.0);
uniform vec3 frange : source_color = vec3(0.62, 0.36, 1.0);
uniform float intensite = 5.0;
uniform float force = 1.0;
uniform float vif = 9.0;

varying float pouls;

void vertex() {
	float n1 = textureLod(bruit, vec2(UV.y * 2.3 + UV2.y, TIME * vif * 0.11 + UV2.y * 3.0), 0.0).r;
	float n2 = textureLod(bruit, vec2(UV.y * 7.0 - UV2.y, TIME * vif * 0.23), 0.0).r;
	VERTEX += NORMAL * UV2.x * ((n1 - 0.5) * 2.0 + (n2 - 0.5) * 0.8);
	pouls = textureLod(bruit, vec2(UV.y * 1.7 - TIME * 2.6 + UV2.y, 0.5), 0.0).r;
}

void fragment() {
	float d = abs(UV.x - 0.5) * 2.0;
	float coeur = smoothstep(0.2 * (0.55 + pouls), 0.0, d);
	float lueur = pow(max(1.0 - d, 0.0), 2.2);
	vec3 col = vec3(1.0) * coeur * 1.6 + mix(frange, halo, lueur) * lueur * 2.4 * (0.6 + pouls * 0.8);
	ALBEDO = col * intensite * force * COLOR.rgb;
	ALPHA = clamp((coeur + lueur) * force * COLOR.a, 0.0, 1.0);
}

// Extension « Le Château d'Ombrelac » : les rayons de soleil des grandes baies (v13). Un volume
// oblique, ajouté à l'image (blend_add) : plus fort près de la baie, il s'éteint en descendant ; ses
// bords sont doux (vu de face, il est plus clair que vu par la tranche) ; il se fond là où il touche
// le sol ou une table ; des grains de poussière y dérivent lentement. « force » : 0 la nuit.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 couleur = vec3(1.0, 0.86, 0.62);
uniform float force = 0.1;
uniform sampler2D tex_prof : hint_depth_texture, filter_linear_mipmap;

varying vec3 wp;

float h3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// le long du rayon (UV.x : 0 à la baie, 1 au bout) ; en travers (UV.y : 0..1 d'un bord à l'autre)
	float le_long = (1.0 - smoothstep(0.0, 1.0, UV.x)) * smoothstep(0.0, 0.06, UV.x);
	float travers = smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.7, UV.y);
	float face = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.5);
	// la fonte au contact (le sol, les tables)
	float zd = texture(tex_prof, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, zd, 1.0);
	v.xyz /= v.w;
	float contact = smoothstep(0.0, 1.2, length(v.xyz) - length(VERTEX));
	float proche = smoothstep(0.5, 3.0, length(VERTEX));
	// la poussière : des grains fins qui dérivent
	// (des points fins, visibles seulement de près)
	vec3 q = wp * 36.0 + vec3(TIME * 0.25, -TIME * 0.15, TIME * 0.2);
	float grain = step(0.996, h3(floor(q))) * 3.0 * (1.0 - smoothstep(3.0, 10.0, length(VERTEX)));
	float a = le_long * travers * face * contact * proche;
	ALBEDO = couleur * force * a * (1.0 + grain);
}

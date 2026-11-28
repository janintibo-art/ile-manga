shader_type spatial;
// V219 : une bouffée de flammes (une particule calculée par la carte graphique). Elle fait face au regard ;
// sa forme est rongée par un bruit qui défile, de plus en plus à mesure qu'elle vieillit ; sa couleur va du
// blanc-jaune (jeune, au cœur) à l'orange, au rouge sombre, puis s'éteint. Les bouffées s'additionnent : là où
// elles se recouvrent, le cœur de l'explosion devient blanc.
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform float intensite = 5.0;
uniform float vitesse = 0.45;
uniform float duree_chaude = 0.55;      // part de la vie pendant laquelle elle reste claire

varying float age;
varying float graine;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	graine = INSTANCE_CUSTOM.x;
	float c = cos(graine);
	float s = sin(graine);
	mat4 monde = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	monde = monde * mat4(vec4(c, -s, 0.0, 0.0), vec4(s, c, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * monde;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv) * 2.0;
	float n1 = texture(bruit, UV * 0.55 + vec2(graine * 0.37, graine * 0.73 - TIME * vitesse)).r;
	float n2 = texture(bruit, UV * 1.3 + vec2(-graine * 0.21 + TIME * vitesse * 0.4, graine - TIME * vitesse * 1.6)).r;
	float n = n1 * 0.66 + n2 * 0.34;
	// le corps de la bouffée : plein au centre, rongé au bord ; la morsure avance avec l'âge
	float corps = (1.0 - r) + (n - 0.5) * 1.05;
	float seuil = mix(0.02, 0.62, age * age * 0.6 + age * 0.4);
	// (jamais coupée au bord de son carré)
	float a = smoothstep(seuil, seuil + 0.3, corps) * smoothstep(1.0, 0.72, r);
	// la chaleur : forte au cœur et dans la jeunesse
	float chaud = clamp(corps * 1.35 + 0.3 - age / duree_chaude * 0.75, 0.0, 1.0);
	vec3 col = mix(vec3(0.35, 0.03, 0.0), vec3(0.95, 0.16, 0.02), smoothstep(0.0, 0.3, chaud));
	col = mix(col, vec3(1.0, 0.5, 0.07), smoothstep(0.25, 0.55, chaud));
	col = mix(col, vec3(1.0, 0.86, 0.42), smoothstep(0.5, 0.8, chaud));
	col = mix(col, vec3(1.0, 1.0, 0.92), smoothstep(0.82, 1.0, chaud));
	float eteint = 1.0 - smoothstep(0.45, 0.92, age);
	ALBEDO = col * COLOR.rgb * intensite * (0.25 + 0.75 * chaud) * eteint;
	ALPHA = a * COLOR.a;
}

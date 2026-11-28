shader_type spatial;
// V219 : une bouffée de fumée (ou de brume de givre) : une particule qui fait face au regard, éclairée comme
// une boule (le soleil la modèle), rongée par un bruit, avec au début la lueur du feu qu'elle enferme.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;

uniform sampler2D bruit : repeat_enable, filter_linear_mipmap;
uniform vec3 teinte : source_color = vec3(0.12, 0.11, 0.1);
uniform vec3 teinte_claire : source_color = vec3(0.4, 0.38, 0.36);
uniform vec3 lueur : source_color = vec3(1.0, 0.3, 0.04);
uniform float lueur_force = 2.0;
uniform float opacite = 0.75;
uniform float vitesse = 0.12;

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
	vec2 uv = (UV - vec2(0.5)) * 2.0;
	float r = length(uv);
	float n1 = texture(bruit, UV * 0.5 + vec2(graine * 0.31, graine * 0.57 - TIME * vitesse)).r;
	float n2 = texture(bruit, UV * 1.15 + vec2(graine - TIME * vitesse * 0.7, -graine * 0.4)).r;
	float n = n1 * 0.65 + n2 * 0.35;
	float corps = (1.0 - r) + (n - 0.5) * 0.9;
	float seuil = mix(0.03, 0.4, age);
	// (jamais coupée au bord de son carré)
	float a = smoothstep(seuil, seuil + 0.55, corps) * smoothstep(1.0, 0.7, r);
	// une boule : le soleil et les lampes la modèlent
	float z = sqrt(max(1.0 - min(r * r, 1.0), 0.0));
	NORMAL = normalize(vec3(uv.x, -uv.y, z + 0.35));
	ALBEDO = mix(teinte, teinte_claire, n * 0.7 + age * 0.3) * COLOR.rgb;
	ROUGHNESS = 1.0;
	// le feu qu'elle enferme, tant qu'elle est jeune
	float braise = pow(max(1.0 - age * 3.0, 0.0), 2.0) * smoothstep(0.62, 0.95, n2 + (1.0 - r) * 0.4);
	EMISSION = lueur * lueur_force * braise;
	// elle apparaît vite, s'efface lentement
	float vie = smoothstep(0.0, 0.08, age) * (1.0 - smoothstep(0.45, 1.0, age));
	ALPHA = a * opacite * vie * COLOR.a;
}

// V114 : les cristaux des Strates (la Grotte aux Cristaux, les lanternes) : un minéral translucide,
// dont les arêtes et les faces vues de biais s'allument (une lueur de Fresnel), le cœur plus sombre ;
// chaque face a sa nuance (on voit les facettes), et la lueur respire lentement.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

uniform vec3 couleur : source_color = vec3(0.3, 0.62, 1.0);
uniform float force = 1.0;
uniform float souffle = 0.0;

varying vec3 wp;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float facing = clamp(dot(n, normalize(VIEW)), 0.0, 1.0);
	float fres = pow(1.0 - facing, 2.2);
	// une nuance par facette (le repère monde de la normale, arrondi)
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float facet = hash3(floor(wn * 3.0) + floor(wp * 0.7));
	vec3 deep = couleur * vec3(0.18, 0.22, 0.32);
	ALBEDO = mix(deep, couleur * 0.55, 0.3 + 0.4 * facet);
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.9;
	float b = 0.75 + 0.25 * sin(TIME * 0.6 + facet * 6.0) + souffle;
	EMISSION = couleur * (0.12 + 0.3 * facet + 1.6 * fres) * force * b;
}

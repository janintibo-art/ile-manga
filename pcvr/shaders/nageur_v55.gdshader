// V55 : les grands nageurs (requins, dauphins, baleine). Le corps ondule le long de son axe
// (-Z = la tête) : de côté pour le requin (axis = 0), de haut en bas pour le dauphin et la
// baleine (axis = 1). Couleur : couleur des sommets (dos sombre, ventre clair) et un fin
// grain de peau.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform float amplitude = 0.12;     // en fraction de la longueur
uniform float freq = 1.4;           // battements par seconde
uniform float axis = 0.0;
uniform float phase = 0.0;
uniform float length_m = 1.0;       // longueur du maillage (m)
uniform float roughness_v = 0.45;

varying vec3 lpos;

void vertex() {
	float along = clamp(-VERTEX.z / length_m + 0.5, 0.0, 1.0);    // 0 queue, 1 tête
	float w = pow(1.0 - along, 2.0);
	float s = sin(TIME * freq * 6.2832 + phase - along * 3.2) * amplitude * length_m * w;
	if (axis < 0.5) {
		VERTEX.x += s;
	} else {
		VERTEX.y += s;
	}
	lpos = VERTEX;
}

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	float grain = hash(floor(lpos * 60.0)) * 0.06 - 0.03;
	ALBEDO = COLOR.rgb + vec3(grain);
	ROUGHNESS = roughness_v;
	SPECULAR = 0.55;
}

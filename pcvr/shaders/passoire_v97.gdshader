// V97 : l'acier de la passoire géante (le Temple-Passoire de l'Île Al Dente). Un inox brossé en rond
// (les traits du polissage font le tour), un peu terni en bas, avec des coulures d'eau sèches, et des
// trous ronds en rangées régulières : le soleil passe au travers et dessine des taches de lumière dans
// le temple (les trous sont de vrais trous : ils laissent aussi passer la lumière dans les ombres).
// La porte est découpée dans la paroi, en arc. holes = false : le rebord, le pied et les anses.
// Repère local : le centre du rebord à l'origine (posé au sol), le haut vers +y ; le centre de la
// sphère de la passoire est à sphere_y.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform bool holes = true;
uniform float radius = 15.0;
uniform float sphere_y = -1.0;
uniform float hole_r = 0.2;
uniform float spacing = 1.0;
uniform float phi_min = 0.2;       // pas de trous tout en haut (sous le pied) ...
uniform float phi_max = 1.36;      // ... ni tout en bas (au-dessus du rebord)
uniform vec2 door_dir = vec2(0.81, 0.586);
uniform float door_w = 2.6;        // demi-largeur de la porte (m)
uniform float door_h = 6.2;        // hauteur de la porte (m), arc compris

varying vec3 lp;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(a), h21(a + vec2(1.0, 0.0)), f.x), mix(h21(a + vec2(0.0, 1.0)), h21(a + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec3 sp = lp - vec3(0.0, sphere_y, 0.0);
	// la face intérieure de la coque : sa normale regarde vers le dedans
	vec3 n0 = FRONT_FACING ? NORMAL : -NORMAL;
	float len = max(length(sp), 0.001);
	float phi = acos(clamp(sp.y / len, -1.0, 1.0));
	float theta = atan(sp.z, sp.x);
	float hole_edge = 1.0;
	if (holes) {
		// la porte : un rectangle surmonté d'un arc, vu de face
		vec2 dd = normalize(door_dir);
		vec2 side = vec2(-dd.y, dd.x);
		float sx = dot(lp.xz, side);
		float front = dot(lp.xz, dd);
		float yb = lp.y;   // la passoire est posée : son rebord est à y = 0
		if (front > 0.0) {
			float arch_y = door_h - door_w + sqrt(max(door_w * door_w - sx * sx, 0.0));
			if (abs(sx) < door_w && yb < arch_y) {
				discard;
			}
		}
		// les trous : des rangées à phi constant ; dans chaque rangée, autant de trous que la place le permet
		float row_h = spacing / radius;
		float rowf = (phi - phi_min) / row_h;
		float row = floor(rowf + 0.5);
		float phi_row = phi_min + row * row_h;
		if (phi_row > phi_min - 0.001 && phi_row < phi_max) {
			float circ = 6.2831853 * radius * sin(phi_row);
			float n = max(floor(circ / spacing), 6.0);
			float step_a = 6.2831853 / n;
			float off = mod(row, 2.0) * 0.5;
			float k = floor(theta / step_a - off + 0.5);
			float th_c = (k + off) * step_a;
			float dth = (theta - th_c) * radius * sin(phi);
			float dph = (phi - phi_row) * radius;
			float d = length(vec2(dth, dph));
			if (d < hole_r) {
				discard;
			}
			hole_edge = smoothstep(hole_r, hole_r + 0.07, d);
		}
	}
	// l'inox : brossé en rond (des traits fins qui font le tour), quelques creux et bosses
	float brush = vnoise(vec2(phi * 900.0, theta * 4.0)) * 0.6 + vnoise(vec2(phi * 2600.0, theta * 9.0)) * 0.4;
	float tarnish = smoothstep(4.0, 0.0, lp.y) * 0.6 + vnoise(vec2(theta * 30.0, lp.y * 0.6)) * 0.25;
	// les coulures : de longues traînées verticales (l'eau de pluie qui a séché)
	float drip = smoothstep(0.62, 0.9, vnoise(vec2(theta * 70.0, lp.y * 0.08))) * smoothstep(0.0, 8.0, lp.y);
	vec3 steel = vec3(0.64, 0.65, 0.67) * (0.92 + 0.12 * brush);
	steel = mix(steel, vec3(0.42, 0.41, 0.38), tarnish * 0.45);
	steel = mix(steel, vec3(0.78, 0.76, 0.72), drip * 0.25);
	// le bord des trous : un petit chanfrein plus sombre
	steel *= mix(0.55, 1.0, hole_edge);
	float dent = vnoise(vec2(theta * 6.0, phi * 9.0)) - 0.5;
	NORMAL = normalize(n0 + (VIEW_MATRIX * vec4(normalize(sp) * dent * 0.04, 0.0)).xyz);
	ALBEDO = steel;
	METALLIC = 0.95;
	ROUGHNESS = clamp(0.2 + 0.16 * brush + tarnish * 0.18 + drip * 0.1, 0.0, 1.0);
	SPECULAR = 0.5;
	ANISOTROPY = 0.55;
	ANISOTROPY_FLOW = vec2(1.0, 0.0);
}

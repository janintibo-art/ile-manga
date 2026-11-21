// Extension « Le Château d'Ombrelac » : les tissus. Les bannières de l'Académie (un fond, une
// bordure, l'emblème : l'étoile à huit branches de l'Astrolabe dans un anneau ; le bas en queue
// d'aronde), et le tapis (« tapis » : une bordure et des losanges). UV de 0 à 1, v vers le haut.
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform vec3 fond : source_color = vec3(0.06, 0.09, 0.26);
uniform vec3 bord : source_color = vec3(0.86, 0.66, 0.26);
uniform bool tapis = false;
uniform float aspect = 4.0;            // longueur / largeur

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float motif = 0.0;
	if (!tapis) {
		// la queue d'aronde
		if (uv.y < 0.12 * (1.0 - 2.0 * abs(uv.x - 0.5))) {
			discard;
		}
		float bx = min(uv.x, 1.0 - uv.x);
		float by = (1.0 - uv.y) * aspect;
		float bb = (uv.y - 0.12 * (1.0 - 2.0 * abs(uv.x - 0.5))) * aspect;
		float d = min(min(bx, by), bb);
		motif = step(d, 0.07) * step(0.035, d) + step(d, 0.02);
		// l'emblème
		vec2 p = vec2(uv.x - 0.5, (uv.y - 0.6) * aspect);
		float r = length(p);
		float a = atan(p.y, p.x);
		float etoile = 0.27 * (0.42 + 0.58 * pow(abs(cos(a * 4.0)), 8.0));
		motif = max(motif, step(r, etoile));
		motif = max(motif, step(abs(r - 0.36), 0.022));
	} else {
		float bx = min(uv.x, 1.0 - uv.x);
		float by = min(uv.y, 1.0 - uv.y) * aspect;
		float d = min(bx, by);
		motif = step(d, 0.1) * step(0.05, d) + step(d, 0.02);
		vec2 q = vec2(uv.x * 3.0, uv.y * aspect * 3.0);
		vec2 l = abs(fract(vec2(q.x + q.y, q.x - q.y) * 0.5) - 0.5);
		float losange = step(abs(l.x + l.y - 0.5), 0.04);
		motif = max(motif, losange * step(0.16, d) * 0.8);
	}
	// le tissage, les plis
	float trame = 0.9 + 0.1 * h(floor(uv * vec2(160.0, 160.0 * aspect)));
	float pli = tapis ? 1.0 : 0.86 + 0.14 * sin(uv.x * 6.2832 * 3.0);
	vec3 c = mix(fond, bord, clamp(motif, 0.0, 1.0)) * trame * pli;
	ALBEDO = c;
	METALLIC = motif > 0.5 ? 0.55 : 0.0;
	ROUGHNESS = motif > 0.5 ? 0.45 : 0.92;
	if (!tapis) {
		NORMAL_MAP = normalize(vec3(cos(uv.x * 6.2832 * 3.0) * 0.35, 0.0, 1.0)) * 0.5 + 0.5;
	}
}

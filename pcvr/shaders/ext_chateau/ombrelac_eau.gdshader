// Extension « Le Château d'Ombrelac » : l'eau du lac et du torrent (v13). Des rides en plusieurs
// tailles qui avancent avec le vent (ou le courant), le reflet du ciel plus fort quand on la voit de
// biais, la transparence au bord (on voit le fond près de la rive), la teinte qui fonce avec la
// profondeur, l'écume le long des berges et des rochers, quelques éclats de soleil.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_always;

uniform vec3 profond = vec3(0.01, 0.045, 0.06);
uniform vec3 clair = vec3(0.07, 0.19, 0.19);
uniform float clarte = 2.5;            // en m : la profondeur où l'eau devient opaque
uniform vec2 courant = vec2(0.03, 0.015);
uniform float vif = 0.0;               // 1 : le torrent (rides serrées, écume)
uniform float ecume = 0.6;
uniform sampler2D tex_ecran : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D tex_prof : hint_depth_texture, filter_linear_mipmap;

varying vec3 wp;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

// la hauteur des rides en p, au temps t
float rides(vec2 p, float t) {
	vec2 c = courant * (1.0 + vif * 20.0);
	float s = 1.0 + vif * 1.5;
	float h = n2(p * 0.35 * s + c * t * 3.0) * 0.5;
	h += n2(p * 1.1 * s - c.yx * t * 6.0 + 7.0) * 0.28;
	h += n2(p * 3.3 * s + c * t * 12.0 + 3.0) * 0.14;
	h += n2(p * 9.0 * s - c * t * 20.0 + 11.0) * 0.08;
	return h;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME;
	vec2 p = wp.xz;
	float dist = length(CAMERA_POSITION_WORLD - wp);
	float fin = 1.0 - smoothstep(30.0, 250.0, dist);
	float e = 0.05;
	float h0 = rides(p, t);
	vec2 g = vec2(rides(p + vec2(e, 0.0), t) - h0, rides(p + vec2(0.0, e), t) - h0) / e;
	float force = (0.12 + 0.25 * vif) * (0.3 + 0.7 * fin);
	vec3 nw = normalize(vec3(-g.x * force, 1.0, -g.y * force));
	if (!FRONT_FACING) {
		nw = -nw;
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	// la profondeur de l'eau sous ce point (le fond vu à travers)
	float zd = texture(tex_prof, SCREEN_UV).r;
	vec4 fond_v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, zd, 1.0);
	fond_v.xyz /= fond_v.w;
	float epais = max(length(fond_v.xyz) - length(VERTEX), 0.0);
	float transp = exp(-epais / clarte);
	// le fond, un peu déformé par les rides
	vec2 uvr = SCREEN_UV + nw.xz * 0.02 * transp;
	vec3 fond = textureLod(tex_ecran, uvr, 0.0).rgb;
	vec3 teinte_eau = mix(profond, clair, exp(-epais / (clarte * 3.0)));
	// (le fond vu à travers est donné en émission : il est déjà éclairé)
	vec3 refr = fond * mix(vec3(1.0), clair * 3.0, 0.4) * transp * 0.85;
	vec3 col = teinte_eau * (1.0 - transp * 0.85);
	// l'écume : le long des berges (là où l'eau est mince), plus dans le torrent
	float bord = 1.0 - smoothstep(0.0, 0.35 + vif * 0.6, epais);
	float mousse = bord * smoothstep(0.35, 0.65, n2(p * 3.0 + vec2(t * 0.4, -t * 0.3)) + bord * 0.3);
	mousse += vif * smoothstep(0.72, 0.9, n2(p * 1.8 + courant * t * 40.0)) * 0.6;
	mousse = clamp(mousse * ecume, 0.0, 1.0);
	col = mix(col, vec3(0.8, 0.84, 0.82), mousse);
	ALBEDO = col;
	EMISSION = refr * (1.0 - mousse);
	ROUGHNESS = mix(0.03, 0.5, mousse);
	METALLIC = 0.0;
	SPECULAR = 0.6;
	// l'eau mince au bord se fond dans la rive
	ALPHA = smoothstep(0.0, 0.05, epais + mousse * 0.1);
}

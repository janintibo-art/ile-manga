// V115 : le verre du Dôme d'Azur (les coupoles, les vitres des tambours, les galeries, le tube du
// Funiculaire), à cent quarante mètres sous la mer. Derrière le verre, c'est de l'eau : pour chaque
// pixel, le shader cherche ce qu'il y a derrière (la profondeur de la scène) et la quantité d'eau
// traversée jusque-là, puis il y met la couleur de la mer profonde (bleu nuit ; un peu plus clair vers
// le haut, d'où vient le jour). Il connaît les volumes d'air (les dômes : des ellipsoïdes ; les
// galeries et le tube : des capsules) : l'eau s'arrête là où l'on rentre dans un autre volume d'air
// (depuis une galerie, on voit le Grand Dôme et ses lumières, au travers de vingt mètres d'eau).
// Une face « de sortie » (on regarde de l'air vers l'eau) met l'eau ; une face « d'entrée » (de l'eau
// vers l'air) n'a que le verre. Sur le verre : un reflet doux (Fresnel) et l'éclat de la Grande Perle.
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_draw_never, shadows_disabled, depth_test_default;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 eau_bas : source_color = vec3(0.012, 0.07, 0.115);
uniform vec3 eau_haut : source_color = vec3(0.06, 0.25, 0.37);
uniform sampler2D caustic_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float rayons = 1.0;
uniform float densite = 0.03;
uniform float jour = 1.0;
uniform vec3 teinte : source_color = vec3(0.62, 0.86, 0.92);
uniform float vitre = 0.05;
uniform vec3 lumiere_pos = vec3(0.0);
uniform vec3 lumiere_col : source_color = vec3(1.0, 0.93, 0.8);
uniform float lumiere_force = 0.0;
// les volumes d'air : n_ell ellipsoïdes (centre, demi-axes) et n_cap capsules (a, rayon ; b)
uniform int n_ell = 0;
uniform vec4 ell_c[4];
uniform vec4 ell_r[4];
uniform int n_cap = 0;
uniform vec4 cap_a[6];
uniform vec4 cap_b[6];

varying vec3 wpos;
varying vec3 wnrm;

float to_ndc_z(float d) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return d * 2.0 - 1.0;
#else
	return d;
#endif
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// le rayon entre-t-il dans l'ellipsoïde ? (distance d'entrée, ou -1)
float hit_ell(vec3 ro, vec3 rd, vec3 c, vec3 r) {
	vec3 oc = (ro - c) / r;
	vec3 d = rd / r;
	float a = dot(d, d);
	float b = dot(oc, d);
	float cc = dot(oc, oc) - 1.0;
	if (cc <= 0.0) {
		return -1.0;          // on est dedans (c'est le volume que l'on quitte)
	}
	float h = b * b - a * cc;
	if (h < 0.0) {
		return -1.0;
	}
	return (-b - sqrt(h)) / a;
}

// le rayon entre-t-il dans la capsule (pa, pb, rayon ra) ? (distance d'entrée, ou -1)
float hit_cap(vec3 ro, vec3 rd, vec3 pa, vec3 pb, float ra) {
	vec3 ba = pb - pa;
	vec3 oa = ro - pa;
	float baba = dot(ba, ba);
	float bard = dot(ba, rd);
	float baoa = dot(ba, oa);
	// dedans (ou sur le bord) : c'est le volume que l'on quitte
	float tt = clamp(baoa / baba, 0.0, 1.0);
	if (length(oa - ba * tt) < ra + 0.25) {
		return -1.0;
	}
	float rdoa = dot(rd, oa);
	float oaoa = dot(oa, oa);
	float a = baba - bard * bard;
	float b = baba * rdoa - baoa * bard;
	float c = baba * oaoa - baoa * baoa - ra * ra * baba;
	float h = b * b - a * c;
	if (h >= 0.0) {
		float t = (-b - sqrt(h)) / a;
		float y = baoa + t * bard;
		if (y > 0.0 && y < baba) {
			return t;
		}
		vec3 oc = (y <= 0.0) ? oa : ro - pb;
		b = dot(rd, oc);
		c = dot(oc, oc) - ra * ra;
		h = b * b - c;
		if (h > 0.0) {
			return -b - sqrt(h);
		}
	}
	return -1.0;
}

void fragment() {
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 rd = normalize(wpos - cam);
	vec3 n = normalize(wnrm);
	// ce qu'il y a derrière (la scène opaque)
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 vp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, to_ndc_z(d), 1.0);
	vp.xyz /= vp.w;
	vec3 scene = (INV_VIEW_MATRIX * vec4(vp.xyz, 1.0)).xyz;
	float s_scene = dot(scene - wpos, rd);
	if (vp.z < -3000.0 || s_scene < 0.0) {
		s_scene = 5000.0;
	}
	// une face de sortie (de l'air vers l'eau) ?
	float fog = 0.0;
	vec3 water = vec3(0.0);
	if (dot(rd, n) > 0.0) {
		float t_next = 5000.0;
		for (int k = 0; k < n_ell; k++) {
			float t = hit_ell(wpos + rd * 0.05, rd, ell_c[k].xyz, ell_r[k].xyz);
			if (t > 0.3) {
				t_next = min(t_next, t);
			}
		}
		for (int k = 0; k < n_cap; k++) {
			float t = hit_cap(wpos + rd * 0.05, rd, cap_a[k].xyz, cap_b[k].xyz, cap_a[k].w);
			if (t > 0.3) {
				t_next = min(t_next, t);
			}
		}
		float len = min(s_scene, t_next);
		fog = 1.0 - exp(-densite * len);
		float up = smoothstep(-0.35, 0.95, rd.y);
		water = mix(eau_bas, eau_haut, up) * (0.3 + 0.7 * jour);
		// un voile plus clair vers le haut, au-dessus des dômes (le jour qui descend de la surface)
		float ry = max(rd.y, 0.0);
		water += eau_haut * pow(ry, 4.0) * 0.9 * jour;
		// les rais de lumière : de longues bandes qui ondulent doucement (les vagues, tout là-haut)
		float az = atan(rd.x, rd.z);
		float band = texture(caustic_tex, vec2(az * 1.3 + TIME * 0.006, 0.37 + TIME * 0.004)).r;
		band = band * 0.65 + texture(caustic_tex, vec2(az * 2.9 - TIME * 0.004, 0.71)).r * 0.35;
		float shafts = smoothstep(0.35, 0.95, band) * smoothstep(-0.05, 0.55, rd.y) * (1.0 - smoothstep(0.75, 1.0, rd.y) * 0.6);
		water += eau_haut * shafts * 0.55 * jour * rayons;
		// au zénith, la surface qui scintille (très loin) : le motif des caustiques qui danse
		vec2 suv = rd.xz / max(rd.y + 0.25, 0.3) * 0.35;
		float sc = texture(caustic_tex, suv + vec2(TIME * 0.01, TIME * 0.007)).r * texture(caustic_tex, suv * 1.7 - vec2(TIME * 0.008, 0.0)).r;
		water += vec3(0.25, 0.55, 0.7) * sc * smoothstep(0.45, 1.0, rd.y) * 0.5 * jour * rayons;
	}
	// le verre lui-même : une teinte légère, le reflet sur les bords, l'éclat de la Perle
	float facing = abs(dot(n, -rd));
	float fres = pow(1.0 - facing, 4.0);
	vec3 nf = dot(n, rd) > 0.0 ? -n : n;
	vec3 l = normalize(lumiere_pos - wpos);
	float spec = pow(max(dot(reflect(rd, nf), l), 0.0), 90.0) * lumiere_force;
	float ga = clamp(vitre + fres * 0.35 + spec * 0.28, 0.0, 0.9);
	vec3 gc = teinte * (0.35 + fres * 0.65) + lumiere_col * spec * 0.7;
	float a_out = 1.0 - (1.0 - fog) * (1.0 - ga);
	vec3 c_out = (water * fog * (1.0 - ga) + gc * ga) / max(a_out, 0.0001);
	ALBEDO = c_out;
	ALPHA = clamp(a_out, 0.0, 1.0);
}

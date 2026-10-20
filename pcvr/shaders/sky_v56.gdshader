// V56 : le ciel qui tourne avec les heures — jour bleu, aube et crépuscule dorés, nuit
// étoilée avec la lune. Reprend le ciel V24 (dégradé, soleil, nuages) ; l'heure du jeu
// (temps_v56.gd) règle les trois poids day / dusk / night et la place du soleil et de la lune.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.13, 0.32, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.62, 0.77, 0.93);
uniform vec3 ground_color : source_color = vec3(0.24, 0.30, 0.36);
uniform float sky_energy = 1.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.52;
uniform float cloud_softness : hint_range(0.05, 0.6) = 0.26;
uniform float cloud_speed = 0.0035;
uniform int cloud_octaves = 7;

// V56 : l'heure
uniform float day = 1.0;          // 1 = plein jour
uniform float dusk = 0.0;         // lumière rasante (aube ou crépuscule)
uniform float night = 0.0;        // 1 = nuit noire
uniform vec3 sun_dir = vec3(0.0, 0.7, 0.7);
uniform vec3 moon_dir = vec3(0.0, -0.7, 0.7);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.95, 0.86);
uniform float star_rot = 0.0;     // les étoiles tournent lentement avec la nuit

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash3(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 turn = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < octaves; i++) {
		value += amplitude * noise(p);
		p = turn * p * 2.03 + vec2(1.7, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

// Un champ d'étoiles : une étoile au plus par cellule d'une grille projetée sur la sphère,
// plus ou moins brillante, qui scintille un peu.
float stars(vec3 dir, float cells, float threshold) {
	vec3 p = dir * cells;
	vec3 cell = floor(p);
	float h = hash3(cell);
	if (h < threshold) {
		return 0.0;
	}
	vec3 center = cell + 0.5 + (vec3(hash3(cell + 7.1), hash3(cell + 3.3), hash3(cell + 5.7)) - 0.5) * 0.6;
	float d = length(p - center);
	float k = (h - threshold) / (1.0 - threshold);
	float tw = 0.75 + 0.25 * sin(TIME * (1.5 + h * 4.0) + h * 40.0);
	return smoothstep(0.22, 0.0, d) * (0.25 + k * k * 2.5) * tw;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;
	vec3 sd = normalize(sun_dir);
	vec3 md = normalize(moon_dir);
	float sun_dot = dot(dir, sd);
	float moon_dot = dot(dir, md);

	// --- Dégradé d'atmosphère, mélange des trois moments
	float t = pow(1.0 - max(h, 0.0), 4.0);
	vec3 day_col = mix(zenith_color, horizon_color, t);
	day_col = mix(day_col, horizon_color * vec3(1.08, 1.0, 0.9), pow(max(sun_dot, 0.0), 3.0) * t * 0.5);

	// crépuscule : bleu violacé en haut, horizon orangé du côté du soleil, mauve de l'autre
	vec2 hz = normalize(vec2(dir.x, dir.z) + vec2(0.0001));
	vec2 hs = normalize(vec2(sd.x, sd.z) + vec2(0.0001));
	float toward = pow(dot(hz, hs) * 0.5 + 0.5, 2.0);
	vec3 dusk_h = mix(vec3(0.42, 0.36, 0.55), vec3(1.0, 0.52, 0.24), toward);
	vec3 dusk_col = mix(vec3(0.16, 0.2, 0.42), dusk_h, pow(1.0 - max(h, 0.0), 3.0));
	dusk_col += vec3(1.0, 0.62, 0.3) * pow(max(sun_dot, 0.0), 6.0) * 0.6;

	// nuit : bleu nuit, un peu plus clair à l'horizon, lueur autour de la lune
	vec3 night_col = mix(vec3(0.006, 0.011, 0.03), vec3(0.025, 0.04, 0.075), pow(1.0 - max(h, 0.0), 3.0));
	night_col += vec3(0.12, 0.15, 0.22) * pow(max(moon_dot, 0.0), 18.0) * 0.5 * smoothstep(-0.05, 0.1, md.y);

	vec3 col = day_col * day + dusk_col * dusk + night_col * night;
	float wsum = max(day + dusk + night, 0.001);
	col /= wsum;
	if (h < 0.0) {
		vec3 g = ground_color * (day + dusk * 0.6 + night * 0.06) / wsum;
		col = mix(col, g, smoothstep(0.0, 0.3, -h));
	}
	col *= sky_energy;

	// --- Étoiles et voie lactée (au-dessus de l'horizon, la nuit)
	if (h > 0.0 && night > 0.01) {
		float c = cos(star_rot);
		float s = sin(star_rot);
		vec3 sdir = vec3(dir.x * c - dir.z * s, dir.y, dir.x * s + dir.z * c);
		float st = stars(sdir, 140.0, 0.93) + stars(sdir, 320.0, 0.965) * 0.7;
		float band = exp(-pow(dot(sdir, normalize(vec3(0.35, 0.25, 0.9))) / 0.22, 2.0));
		float milky = band * (0.35 + 0.65 * fbm(sdir.xz * 6.0 + sdir.y * 3.0, 4));
		float vis = night * smoothstep(0.0, 0.18, h);
		col += (vec3(0.9, 0.93, 1.0) * st + vec3(0.07, 0.075, 0.1) * milky) * vis;
	}

	// --- Soleil : disque, halo, diffusion (rougit près de l'horizon)
	float sun_up = smoothstep(-0.08, 0.02, sd.y);
	vec3 sun_col = sun_tint * sun_up;
	col += sun_col * smoothstep(0.99965, 0.99985, sun_dot) * 30.0;
	col += sun_col * pow(max(sun_dot, 0.0), 600.0) * 1.5;
	col += sun_col * pow(max(sun_dot, 0.0), 12.0) * 0.08;

	// --- Lune : disque pâle et piqueté, halo laiteux
	float moon_up = smoothstep(-0.05, 0.05, md.y) * night;
	float disc = smoothstep(0.99955, 0.99975, moon_dot);
	vec3 mp = dir - md * moon_dot;
	float craters = 0.78 + 0.22 * noise(mp.xy * 2200.0 + mp.z * 900.0);
	col += vec3(0.85, 0.88, 0.95) * disc * craters * 2.4 * moon_up;
	col += vec3(0.4, 0.45, 0.6) * pow(max(moon_dot, 0.0), 300.0) * 0.4 * moon_up;

	// --- Nuages : éclairés par le soleil le jour, rosés au crépuscule, gris-bleu sous la lune
	if (h > 0.0) {
		vec2 uv = dir.xz / (h + 0.06) * 0.55;
		uv += TIME * cloud_speed * vec2(1.0, 0.35);
		int octaves = AT_CUBEMAP_PASS ? 4 : cloud_octaves;
		float density = fbm(uv, octaves);
		float cover = smoothstep(cloud_coverage, cloud_coverage + cloud_softness, density);
		vec3 light_dir = night > 0.5 ? md : sd;
		float toward_l = fbm(uv + light_dir.xz * 0.08, 4);
		float lit = clamp(0.55 + (density - toward_l) * 3.2, 0.0, 1.0);
		vec3 day_shadow = horizon_color * 0.72 + vec3(0.06, 0.06, 0.08);
		vec3 day_cloud = mix(day_shadow, sun_tint * 1.05, lit);
		day_cloud += sun_tint * pow(max(sun_dot, 0.0), 24.0) * (1.0 - cover) * 1.6;
		vec3 dusk_cloud = mix(vec3(0.3, 0.24, 0.36), vec3(1.0, 0.6, 0.38), lit * (0.4 + 0.6 * toward));
		vec3 night_cloud = mix(vec3(0.012, 0.016, 0.03), vec3(0.09, 0.1, 0.13), lit * moon_up);
		vec3 cloud = (day_cloud * day + dusk_cloud * dusk + night_cloud * night) / wsum;
		float fade = smoothstep(0.0, 0.16, h);
		col = mix(col, cloud * sky_energy, cover * fade * 0.94);
	}

	// La carte d'éclairage ambiant (passe « cubemap ») reste un peu plus claire la nuit :
	// le clair de lune bleuté éclaire doucement les ombres sans éclaircir le ciel visible.
	if (AT_CUBEMAP_PASS) {
		col += vec3(0.035, 0.05, 0.09) * night;
	}
	COLOR = col;
}

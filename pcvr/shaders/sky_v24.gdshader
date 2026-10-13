// V24 : ciel réaliste — dégradé atmosphérique, soleil avec halo, nuages animés éclairés par le soleil.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.13, 0.32, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.62, 0.77, 0.93);
uniform vec3 ground_color : source_color = vec3(0.24, 0.30, 0.36);
uniform float sky_energy = 1.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.52;
uniform float cloud_softness : hint_range(0.05, 0.6) = 0.26;
uniform float cloud_speed = 0.0035;
uniform int cloud_octaves = 7;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
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

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;
	vec3 sun_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0, 1.0, 0.0);
	vec3 sun_color = LIGHT0_ENABLED ? LIGHT0_COLOR * LIGHT0_ENERGY : vec3(1.0);
	float sun_dot = dot(dir, sun_dir);

	// Dégradé d'atmosphère : horizon clair et légèrement chaud du côté du soleil.
	vec3 col;
	if (h >= 0.0) {
		float t = pow(1.0 - h, 4.0);
		col = mix(zenith_color, horizon_color, t);
		col = mix(col, horizon_color * vec3(1.08, 1.0, 0.9), pow(max(sun_dot, 0.0), 3.0) * t * 0.5);
	} else {
		col = mix(horizon_color, ground_color, smoothstep(0.0, 0.3, -h));
	}
	col *= sky_energy;

	// Soleil : disque, halo proche et diffusion large (brume).
	col += sun_color * smoothstep(0.99965, 0.99985, sun_dot) * 30.0;
	col += sun_color * pow(max(sun_dot, 0.0), 600.0) * 1.5;
	col += sun_color * pow(max(sun_dot, 0.0), 12.0) * 0.08;

	// Nuages projetés sur une couche plate en altitude.
	if (h > 0.0) {
		vec2 uv = dir.xz / (h + 0.06) * 0.55;
		uv += TIME * cloud_speed * vec2(1.0, 0.35);
		int octaves = AT_CUBEMAP_PASS ? 4 : cloud_octaves;
		float density = fbm(uv, octaves);
		float cover = smoothstep(cloud_coverage, cloud_coverage + cloud_softness, density);
		// Ombrage interne : on regarde la densité un peu plus vers le soleil.
		float toward_sun = fbm(uv + sun_dir.xz * 0.08, 4);
		float lit = clamp(0.55 + (density - toward_sun) * 3.2, 0.0, 1.0);
		vec3 shadow_tint = horizon_color * 0.72 + vec3(0.06, 0.06, 0.08);
		vec3 cloud = mix(shadow_tint, sun_color * 1.05, lit);
		// Liseré argenté autour du soleil.
		cloud += sun_color * pow(max(sun_dot, 0.0), 24.0) * (1.0 - cover) * 1.6;
		float fade = smoothstep(0.0, 0.16, h);
		col = mix(col, cloud * sky_energy, cover * fade * 0.94);
	}
	COLOR = col;
}

// V175 : les écrans des bornes de l'Arcade du Dragon-Pixel (Néopolis). Chaque borne montre son jeu en
// « mode démo », dessiné ici en gros pixels (64 × 48) : Dragon-Pixel (le petit dragon vert qui saute de
// plateforme en plateforme, crache du feu, ramasse des pièces), Néo-Kart (la route qui file vers le
// soleil couchant), Carpe Cosmos (la carpe-vaisseau dans les étoiles, les méduses) et Robo-Rythme
// (les flèches qui montent vers leurs cibles). Par-dessus : les lignes de l'écran, le bord qui
// s'assombrit, le reflet de la vitre.
shader_type spatial;
render_mode cull_back, unshaded;

uniform int jeu = 0;               // 0 Dragon-Pixel, 1 Néo-Kart, 2 Carpe Cosmos, 3 Robo-Rythme
uniform float graine = 0.0;
uniform float force = 1.6;
uniform float vitesse = 1.0;

const vec2 RES = vec2(64.0, 48.0);
// le dragon (les lignes, de haut en bas ; bit i : la colonne i ; tourné vers la droite plus bas)
const int DRAGON[9] = int[9](28, 62, 127, 511, 1008, 760, 124, 102, 195);
// la carpe (12 × 7) et la méduse (5 × 4)
const int CARPE[7] = int[7](112, 508, 2046, 8191, 2046, 2556, 6256);
const int MEDUSE[4] = int[4](14, 31, 21, 17);

float h1(float n) {
	return fract(sin(n * 12.9898 + graine * 7.13) * 43758.5453);
}

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + graine * 3.7) * 43758.5453);
}

bool bit(int m, int i) {
	return i >= 0 && i < 31 && ((m >> i) & 1) == 1;
}

// ------------------------------------------------------------------ Dragon-Pixel
float sol_dragon(float x) {
	float bloc = floor(x / 8.0);
	float h = 6.0 + floor(h1(bloc) * 4.0) * 2.0;
	// des trous de temps en temps (on saute par-dessus)
	if (h1(bloc + 41.0) > 0.82) {
		h = -10.0;
	}
	return h;
}

vec3 dragon(vec2 p, float t) {
	float sc = t * 14.0;
	// le ciel violet, les étoiles qui scintillent, la lune carrée
	vec3 c = mix(vec3(0.05, 0.0, 0.12), vec3(0.32, 0.06, 0.45), p.y / RES.y);
	if (h2(floor(p + vec2(floor(sc * 0.2), 0.0))) > 0.985 && p.y < 30.0) {
		c = vec3(0.9, 0.9, 1.0) * (0.6 + 0.4 * sin(t * 3.0 + p.x));
	}
	if (p.x > 48.0 && p.x < 55.0 && p.y > 4.0 && p.y < 11.0) {
		c = vec3(1.0, 0.95, 0.7);
	}
	// les montagnes au loin (défilent lentement)
	float xm = p.x + sc * 0.3;
	float hm = 16.0 + 6.0 * sin(xm * 0.11) + 3.0 * sin(xm * 0.37);
	if (RES.y - p.y < hm) {
		c = vec3(0.16, 0.08, 0.28);
	}
	// le sol : des blocs d'herbe et de terre
	float xs = p.x + sc;
	float hs = sol_dragon(xs);
	float yb = RES.y - p.y;
	if (yb < hs) {
		c = yb > hs - 2.0 ? vec3(0.25, 0.8, 0.3) : vec3(0.45, 0.28, 0.15);
		if (mod(floor(xs), 8.0) == 0.0 || mod(floor(yb), 4.0) == 0.0) {
			c *= 0.75;
		}
	}
	// des pièces qui flottent
	float pb = floor(xs / 12.0);
	vec2 pc = vec2(pb * 12.0 + 6.0 - sc, RES.y - sol_dragon(pb * 12.0 + 6.0) - 9.0 - 2.0 * sin(t * 4.0 + pb));
	if (h1(pb + 7.0) > 0.4 && abs(p.x - pc.x) < 1.5 && abs(p.y - pc.y) < 1.5) {
		c = vec3(1.0, 0.85, 0.2);
	}
	// le dragon : il saute (un arc, toutes les 1,6 s), sa queue remue
	float ph = fract(t / 1.6);
	float saut = 14.0 * 4.0 * ph * (1.0 - ph);
	float gx = 14.0;
	float base = RES.y - max(sol_dragon(gx + sc), 6.0) - 9.0 - saut;
	vec2 q = floor(p - vec2(gx, base));
	if (q.x >= 0.0 && q.x < 10.0 && q.y >= 0.0 && q.y < 9.0) {
		int row = int(q.y);
		int col = 9 - int(q.x);
		if (bit(DRAGON[row], col)) {
			c = vec3(0.3, 1.0, 0.45);
			if (row == 2 && col == 2) {
				c = vec3(1.0);
			}
		}
	}
	// le feu qu'il crache (par moments)
	float fe = fract(t * 0.7);
	if (fe < 0.35) {
		float fx = p.x - (gx + 10.0);
		float fy = p.y - (base + 2.0);
		if (fx > 0.0 && fx < fe * 40.0 && abs(fy - sin(fx * 0.8 + t * 20.0)) < 1.6 - fx * 0.03) {
			c = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 0.25, 0.1), clamp(fx / 14.0, 0.0, 1.0));
		}
	}
	// le score, en haut (des petits blocs), les trois cœurs
	if (p.y < 4.0 && p.y >= 1.0) {
		if (p.x >= 2.0 && p.x < 22.0 && mod(p.x, 4.0) < 3.0 && h1(floor(p.x / 4.0) + floor(t)) > 0.3) {
			c = vec3(1.0, 1.0, 0.6);
		}
		if (p.x >= 48.0 && p.x < 61.0 && mod(p.x - 48.0, 5.0) < 3.0) {
			c = vec3(1.0, 0.2, 0.3);
		}
	}
	return c;
}

// ------------------------------------------------------------------ Néo-Kart
vec3 kart(vec2 p, float t) {
	float hz = 20.0;
	vec3 c;
	if (p.y < hz) {
		c = mix(vec3(0.25, 0.0, 0.35), vec3(1.0, 0.45, 0.25), p.y / hz);
		// le soleil rayé
		vec2 s = p - vec2(32.0, hz);
		if (length(s * vec2(1.0, 1.2)) < 11.0 && mod(p.y, 3.0) > 0.6 + (hz - p.y) * 0.08) {
			c = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 0.4, 0.5), (hz - p.y) / 11.0);
		}
		// les tours de la ville, en ombres
		float b = floor(p.x / 4.0);
		if (hz - p.y < 3.0 + floor(h1(b) * 7.0) && h1(b + 3.0) > 0.35) {
			c = vec3(0.12, 0.02, 0.2);
			if (h2(floor(p)) > 0.85) {
				c = vec3(1.0, 0.8, 0.3);
			}
		}
	} else {
		float dy = p.y - hz + 0.5;
		float z = 40.0 / dy;
		float x = (p.x - 32.0) * z / 40.0;
		float bande = step(0.5, fract(z * 0.25 + t * 2.4 * vitesse));
		float virage = 0.35 * sin(t * 0.5 + z * 0.05);
		float xr = x - virage;
		c = mix(vec3(0.08, 0.0, 0.18), vec3(0.15, 0.0, 0.3), bande);
		// la grille fluo
		if (fract(z * 0.25 + t * 2.4 * vitesse) < 0.08 || abs(fract(x * 2.0) - 0.5) < 0.03 * dy) {
			c = vec3(1.0, 0.2, 0.8);
		}
		if (abs(xr) < 0.9) {
			c = mix(vec3(0.22, 0.22, 0.28), vec3(0.28, 0.28, 0.34), bande);
			if (abs(xr) < 0.05 && bande > 0.5) {
				c = vec3(1.0);
			}
		}
		if (abs(abs(xr) - 0.95) < 0.07) {
			c = bande > 0.5 ? vec3(1.0, 0.2, 0.2) : vec3(1.0);
		}
		// le kart, en bas (il penche dans les virages)
		vec2 k = p - vec2(32.0 + virage * 6.0, 41.0);
		if (abs(k.x) < 6.0 && abs(k.y) < 3.0) {
			c = vec3(0.15, 0.85, 1.0);
			if (k.y > 1.0) {
				c = vec3(0.1);
			}
			if (abs(k.x) < 2.0 && k.y < -1.0) {
				c = vec3(1.0, 0.85, 0.2);
			}
		}
		if (abs(abs(k.x) - 6.5) < 1.5 && k.y > -1.0 && k.y < 3.0) {
			c = vec3(0.05);
		}
	}
	// le chrono, en haut
	if (p.y < 4.0 && p.y >= 1.0 && p.x > 26.0 && p.x < 38.0 && mod(p.x, 3.0) < 2.0) {
		c = vec3(1.0, 1.0, 0.5);
	}
	return c;
}

// ------------------------------------------------------------------ Carpe Cosmos
vec3 carpe(vec2 p, float t) {
	vec3 c = vec3(0.0, 0.01, 0.05);
	for (int k = 0; k < 3; k++) {
		float v = 6.0 + float(k) * 9.0;
		vec2 q = floor(p + vec2(t * v, 0.0));
		if (h2(q + float(k) * 31.0) > 0.992 - float(k) * 0.002) {
			c = vec3(0.4 + 0.3 * float(k));
		}
	}
	// une planète au loin
	vec2 pl = p - vec2(mod(70.0 - t * 2.0, 100.0) - 10.0, 12.0);
	if (length(pl) < 6.0) {
		c = mix(vec3(0.7, 0.35, 1.0), vec3(0.4, 0.15, 0.7), step(0.0, pl.x + pl.y));
	}
	// la carpe-vaisseau (orange), qui ondule
	float cy = 22.0 + 6.0 * sin(t * 1.3);
	vec2 q = floor(p - vec2(6.0, cy - 3.0));
	if (q.x >= 0.0 && q.x < 13.0 && q.y >= 0.0 && q.y < 7.0) {
		int col = 12 - int(q.x);
		if (bit(CARPE[int(q.y)], col)) {
			c = vec3(1.0, 0.55, 0.15);
			if (int(q.y) == 2 && col == 3) {
				c = vec3(1.0);
			}
		}
	}
	// ses tirs (des traits cyan)
	for (int k = 0; k < 3; k++) {
		float bx = mod(t * 40.0 + float(k) * 22.0, 66.0) + 18.0;
		float by = 22.0 + 6.0 * sin((t - (bx - 18.0) / 40.0) * 1.3);
		if (abs(p.x - bx) < 1.5 && abs(p.y - by) < 0.6) {
			c = vec3(0.3, 1.0, 1.0);
		}
	}
	// les méduses (roses, vertes) qui arrivent
	for (int k = 0; k < 4; k++) {
		float mx = mod(80.0 - t * 9.0 + float(k) * 20.0, 80.0);
		float my = 8.0 + float(k) * 9.0 + 3.0 * sin(t * 2.0 + float(k));
		vec2 m = floor(p - vec2(mx, my));
		if (m.x >= 0.0 && m.x < 5.0 && m.y >= 0.0 && m.y < 4.0 && bit(MEDUSE[int(m.y)], int(m.x))) {
			c = k % 2 == 0 ? vec3(1.0, 0.3, 0.8) : vec3(0.4, 1.0, 0.5);
		}
	}
	return c;
}

// ------------------------------------------------------------------ Robo-Rythme
float fleche(vec2 q, int dir) {
	// une flèche dans un carré de 7 × 7 (q de -3 à 3), qui pointe vers le haut avant d'être tournée
	vec2 r = q;
	if (dir == 1) {
		r = vec2(-q.y, q.x);
	} else if (dir == 2) {
		r = vec2(q.x, -q.y);
	} else if (dir == 3) {
		r = vec2(q.y, -q.x);
	}
	bool tete = r.y <= 0.0 && abs(r.x) <= r.y + 3.0;
	bool tige = r.y > 0.0 && r.y <= 3.0 && abs(r.x) <= 1.0;
	return (tete || tige) && abs(r.x) <= 3.0 && r.y >= -3.0 ? 1.0 : 0.0;
}

vec3 rythme(vec2 p, float t) {
	float beat = fract(t * 2.0 * vitesse);
	vec3 c = mix(vec3(0.08, 0.0, 0.18), vec3(0.2, 0.0, 0.3), p.y / RES.y);
	// des rayons qui tournent derrière
	vec2 d = p - vec2(32.0, 30.0);
	if (mod(atan(d.y, d.x) * 3.0 + t, 1.0) < 0.15) {
		c += vec3(0.08, 0.02, 0.1);
	}
	vec3 cols[4] = vec3[](vec3(1.0, 0.3, 0.8), vec3(0.3, 0.9, 1.0), vec3(0.4, 1.0, 0.5), vec3(1.0, 0.9, 0.3));
	int dirs[4] = int[](3, 2, 0, 1);
	for (int k = 0; k < 4; k++) {
		float cx = 14.0 + float(k) * 12.0;
		// la cible, en haut (elle s'allume au temps)
		vec2 qc = p - vec2(cx, 8.0);
		if (abs(qc.x) <= 3.5 && abs(qc.y) <= 3.5) {
			float f = fleche(floor(qc + 0.5), dirs[k]);
			if (f > 0.0) {
				c = mix(vec3(0.35), cols[k], 0.25 + 0.75 * step(0.8, beat) * step(0.5, h1(floor(t * 2.0) + float(k))));
			}
		}
		// les flèches qui montent
		for (int j = 0; j < 4; j++) {
			float y = 8.0 + mod(float(j) * 11.0 + float(k) * 5.0 - t * 22.0 * vitesse, 44.0);
			if (h1(float(j) + float(k) * 7.0 + floor((t * 22.0 + float(j) * 11.0) / 44.0)) < 0.35) {
				continue;
			}
			vec2 qa = p - vec2(cx, y);
			if (abs(qa.x) <= 3.5 && abs(qa.y) <= 3.5 && y > 11.0 && fleche(floor(qa + 0.5), dirs[k]) > 0.0) {
				c = cols[k];
			}
		}
	}
	// « PARFAIT ! » : une barre qui clignote en bas
	if (p.y > 42.0 && p.y < 45.0 && abs(p.x - 32.0) < 12.0 && beat < 0.3) {
		c = vec3(1.0, 1.0, 0.6);
	}
	return c;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = floor(uv * RES);
	float t = TIME * vitesse + graine * 17.0;
	vec3 c;
	if (jeu == 1) {
		c = kart(p, t);
	} else if (jeu == 2) {
		c = carpe(p, t);
	} else if (jeu == 3) {
		c = rythme(p, t);
	} else {
		c = dragon(p, t);
	}
	// l'écran : les lignes, le bord plus sombre (le tube bombé), un reflet de vitre
	float ln = 0.78 + 0.22 * sin(uv.y * RES.y * 6.2832 * 2.0);
	vec2 b = uv * 2.0 - 1.0;
	float vign = clamp(1.0 - dot(b * vec2(0.75, 0.85), b * vec2(0.75, 0.85)) * 0.55, 0.0, 1.0);
	float reflet = 0.06 * smoothstep(0.35, 0.0, abs(uv.x + uv.y * 0.6 - 0.45));
	ALBEDO = c * ln * vign * force + vec3(reflet);
}

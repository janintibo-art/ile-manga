extends "res://scripts/carene_kit_v59.gd"
## V60 : la boîte à outils de Tazira — celle de Carène et de Port-Azur, plus les matériaux du
## port berbère (pisé, chaux, zellige, claies de roseaux, tapis, barques bleues, cuivre des
## lanternes ajourées) et les formes de la ville : maison cubique à terrasse crénelée, porte
## en arc outrepassé, remparts à merlons, étal du souk, lanterne marocaine.

const TZ := "res://assets/textures/tazira/"
const CHAUX := {"blanc": Color(1, 1, 1), "bleu": Color(0.86, 0.92, 1.0), "rose": Color(1.0, 0.9, 0.86), "ocre": Color(1.0, 0.86, 0.66)}


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	if key == "pise" or key == "pise_sombre":
		m = StandardMaterial3D.new()
		m.albedo_texture = load(TZ + "pise.png")
		m.normal_enabled = true
		m.normal_texture = load(TZ + "pise_n.png")
		m.albedo_color = Color(1, 1, 1) if key == "pise" else Color(0.82, 0.78, 0.74)
		m.roughness = 0.95
	elif key.begins_with("chaux"):
		m = StandardMaterial3D.new()
		m.albedo_texture = load(TZ + "chaux.png")
		m.normal_enabled = true
		m.normal_texture = load(TZ + "chaux_n.png")
		m.albedo_color = CHAUX.get(key.substr(6), Color(1, 1, 1))
		m.roughness = 0.93
	else:
		match key:
			"zellige":
				m = StandardMaterial3D.new()
				m.albedo_texture = load(TZ + "zellige.png")
				m.roughness = 0.25
				m.metallic_specular = 0.7
			"canisse":
				m = StandardMaterial3D.new()
				m.albedo_texture = load(TZ + "canisse.png")
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.95
			"tapis_1", "tapis_2", "tapis_3":
				m = StandardMaterial3D.new()
				m.albedo_texture = load(TZ + key + ".png")
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.98
			"barque":
				m = StandardMaterial3D.new()
				m.albedo_texture = load(TZ + "barque.png")
				m.normal_enabled = true
				m.normal_texture = load(TZ + "barque_n.png")
				m.roughness = 0.6
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			"porte_arc":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.08, 0.3, 0.55)
				m.roughness = 0.55
			"porte_verte":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.08, 0.38, 0.3)
				m.roughness = 0.55
			"ombre":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.05, 0.04, 0.035)
				m.roughness = 1.0
			"lanterne_maroc":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(1.0, 0.75, 0.4)
				m.emission_enabled = true
				m.emission = Color(1.0, 0.62, 0.28)
				m.emission_energy_multiplier = 0.0
				if temps != null:
					temps.register_glow(m, 3.5, 0.25)
			"guirlande":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(1.0, 0.85, 0.55)
				m.emission_enabled = true
				m.emission = Color(1.0, 0.7, 0.35)
				m.emission_energy_multiplier = 0.0
				if temps != null:
					temps.register_glow(m, 4.0, 0.0)
			"epice_rouge", "epice_jaune", "epice_orange", "epice_vert", "epice_brun":
				var cols := {"epice_rouge": Color(0.66, 0.12, 0.06), "epice_jaune": Color(0.9, 0.68, 0.1), "epice_orange": Color(0.86, 0.4, 0.08),
					"epice_vert": Color(0.36, 0.48, 0.16), "epice_brun": Color(0.42, 0.24, 0.12)}
				m = StandardMaterial3D.new()
				m.albedo_color = cols[key]
				m.roughness = 1.0
			"terre_cuite":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.72, 0.36, 0.2)
				m.roughness = 0.85
			"cuir":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.82, 0.62, 0.28)
				m.roughness = 0.7
			"dattes":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.32, 0.14, 0.06)
				m.roughness = 0.4
			"glace":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.85, 0.92, 0.95)
				m.roughness = 0.1
				m.metallic_specular = 0.9
			"braise_feu":
				m = StandardMaterial3D.new()
				m.albedo_color = Color(0.3, 0.08, 0.02)
				m.emission_enabled = true
				m.emission = Color(1.0, 0.36, 0.06)
				m.emission_energy_multiplier = 2.5
	if m == null:
		return super.mat(key)
	mats[key] = m
	return m


## Les merlons (créneaux en gradins) sur le haut d'un mur, le long de l'axe X local.
func merlons(xf: Transform3D, length: float, top: float, thick: float, key: String, step: float = 1.25) -> void:
	var n: int = maxi(1, int(length / step))
	for i in range(n):
		var x: float = -length / 2 + (i + 0.5) * length / n
		if i % 2 == 0:
			box(xf * Transform3D(Basis(), Vector3(x, top + 0.35, 0)), Vector3(length / n * 0.9, 0.7, thick), key, 2.0)
			box(xf * Transform3D(Basis(), Vector3(x, top + 0.8, 0)), Vector3(length / n * 0.45, 0.25, thick), key, 2.0)


## Une porte en arc outrepassé (fer à cheval) posée sur le nu du mur (qui regarde -Z).
func horseshoe_door(xf: Transform3D, w: float, h: float, door_key: String, frame_key: String = "chaux_blanc") -> void:
	var r: float = w * 0.5
	var spring: float = h - r * 1.15
	# le battant (rectangle + demi-disque un peu plus large que l'ouverture)
	quad(xf * Transform3D(Basis(), Vector3(0, spring / 2, -0.03)), w, spring, door_key)
	var segs: int = 14
	for i in range(segs):
		var a0: float = lerpf(-0.25, PI + 0.25, float(i) / segs)
		var a1: float = lerpf(-0.25, PI + 0.25, float(i + 1) / segs)
		var c := Vector3(0, spring + r * 0.15, -0.03)
		var p0: Vector3 = c + Vector3(cos(a0) * r, sin(a0) * r, 0)
		var p1: Vector3 = c + Vector3(cos(a1) * r, sin(a1) * r, 0)
		tri(door_key, xf * c, xf * p0, xf * p1, (xf.basis * Vector3(0, 0, -1)).normalized(), Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0))
	# l'encadrement : un bandeau autour de l'arc
	for i in range(segs):
		var a: float = lerpf(-0.25, PI + 0.25, (float(i) + 0.5) / segs)
		var c2 := Vector3(0, spring + r * 0.15, -0.06)
		box(xf * Transform3D(Basis(Vector3(0, 0, 1), a), c2 + Vector3(cos(a) * (r + 0.12), sin(a) * (r + 0.12), 0)), Vector3(0.18, r * PI / segs * 1.4, 0.08), frame_key, 1.0)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (r + 0.12), spring / 2, -0.06)), Vector3(0.18, spring, 0.08), frame_key, 1.0)
	# clous de la porte
	for k in range(4):
		for j in range(3):
			box(xf * Transform3D(Basis(), Vector3(-r * 0.6 + k * r * 0.4, 0.4 + j * spring * 0.3, -0.05)), Vector3(0.05, 0.05, 0.03), "fer", 0.5)


## Petite fenêtre à grille de fer forgé.
func grille_window(xf: Transform3D, w: float, h: float) -> void:
	quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.02)), w, h, "ombre")
	for k in range(4):
		box(xf * Transform3D(Basis(), Vector3(-w / 2 + (k + 0.5) * w / 4, 0, -0.05)), Vector3(0.03, h, 0.03), "fer", 0.5)
	for j in range(3):
		box(xf * Transform3D(Basis(), Vector3(0, -h / 2 + (j + 0.5) * h / 3, -0.05)), Vector3(w, 0.03, 0.03), "fer", 0.5)
	box(xf * Transform3D(Basis(), Vector3(0, -h / 2 - 0.06, -0.08)), Vector3(w + 0.2, 0.08, 0.18), "chaux_blanc", 1.0)


## Une maison cubique de Tazira : murs de chaux (ou de pisé), terrasse crénelée, porte en
## arc, fenêtres à grille, parfois un étage en retrait et du linge qui sèche.
## xf : milieu du bas de la façade (qui regarde -Z). Renvoie le point devant la porte.
func riad(xf: Transform3D, w: float, d: float, h: float, wall: String, door_key: String, upper: bool, laundry: bool, door_x: float = 0.0) -> Vector3:
	box(xf * Transform3D(Basis(), Vector3(0, h / 2, d / 2)), Vector3(w, h, d), wall, 3.0, 63 - 8)
	col_box(xf * Transform3D(Basis(), Vector3(0, h / 2, d / 2)), Vector3(w, h, d))
	# soubassement teinté (bleu ou ocre, à hauteur de main)
	box(xf * Transform3D(Basis(), Vector3(0, 0.45, -0.02)), Vector3(w + 0.02, 0.9, 0.04), "chaux_bleu" if wall != "pise" else "pise_sombre", 2.0, 32)
	# acrotère et merlons
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.3, 0.12)), Vector3(w, 0.6, 0.24), wall, 2.0)
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.3, d - 0.12)), Vector3(w, 0.6, 0.24), wall, 2.0)
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * (w / 2 - 0.12), h + 0.3, d / 2)), Vector3(0.24, 0.6, d), wall, 2.0)
	merlons(xf * Transform3D(Basis(), Vector3(0, 0, 0.12)), w, h + 0.6, 0.24, wall)
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.02, d / 2)), Vector3(w - 0.4, 0.06, d - 0.4), "terre", 2.0, 4)
	horseshoe_door(xf * Transform3D(Basis(), Vector3(door_x, 0, 0)), 1.25, 2.5, door_key)
	var nwin: int = int((w - 1.6) / 2.6)
	for k in range(nwin):
		var wx: float = -w / 2 + (k + 0.5) * w / nwin
		if absf(wx - door_x) < 1.4:
			continue
		grille_window(xf * Transform3D(Basis(), Vector3(wx, 1.7, 0)), 0.6, 0.8)
	if h > 5.0:
		for k2 in range(maxi(1, int(w / 3.0))):
			var wx2: float = -w / 2 + (k2 + 0.5) * w / maxi(1, int(w / 3.0))
			grille_window(xf * Transform3D(Basis(), Vector3(wx2, h - 1.6, 0)), 0.55, 0.7)
	if upper:
		var uw: float = w * 0.45
		var ud: float = d * 0.4
		var ux: float = (w - uw) * 0.5 - 0.3
		box(xf * Transform3D(Basis(), Vector3(ux, h + 1.3, d - ud / 2 - 0.3)), Vector3(uw, 2.6, ud), wall, 3.0, 63 - 8)
		merlons(xf * Transform3D(Basis(), Vector3(ux, 0, d - ud - 0.3)), uw, h + 2.6, 0.2, wall)
		quad(xf * Transform3D(Basis(), Vector3(ux, h + 1.0, d - ud - 0.32)), 0.9, 2.0, door_key)
	if laundry:
		var y: float = h + 1.5
		var a: Vector3 = xf * Vector3(-w / 2 + 0.6, y, 0.8)
		var b: Vector3 = xf * Vector3(w / 2 - 0.6, y, d - 0.8)
		for s2 in [a, b]:
			box(Transform3D(xf.basis, s2 - xf.basis.y * 0.75), Vector3(0.06, 1.5, 0.06), "bois_sombre", 1.0)
		var cols := ["tissu_rouge", "tissu_bleu", "tissu_blanc", "tissu_jaune", "tissu_turquoise", "tissu_orange"]
		var n: int = 5
		for k3 in range(n):
			var p: Vector3 = a.lerp(b, (k3 + 0.5) / n) + Vector3.DOWN * 0.45
			var lb := Basis.looking_at((b - a).normalized().cross(Vector3.UP), Vector3.UP)
			quad(Transform3D(lb, p), rng.randf_range(0.5, 0.9), rng.randf_range(0.6, 0.9), str(cols[rng.randi() % cols.size()]), Vector2(0, 0), Vector2(1, 1), true)
	return xf * Vector3(door_x, 0, -1.0)


## Lanterne marocaine ajourée (cuivre et verre coloré) ; xf : le crochet.
func maroc_lantern(xf: Transform3D, s: float = 1.0) -> void:
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.12 * s, 0)), 0.02 * s, 0.02 * s, 0.12 * s, "cuivre", 6, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.36 * s, 0)), 0.03 * s, 0.14 * s, 0.24 * s, "cuivre", 8)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.66 * s, 0)), 0.15 * s, 0.15 * s, 0.3 * s, "lanterne_maroc", 8, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.86 * s, 0)), 0.15 * s, 0.04 * s, 0.2 * s, "cuivre", 8)
	for k in range(6):
		var a: float = TAU * k / 6.0
		box(xf * Transform3D(Basis(), Vector3(cos(a) * 0.155 * s, -0.51 * s, sin(a) * 0.155 * s)), Vector3(0.02 * s, 0.3 * s, 0.02 * s), "cuivre", 0.5)


## Un étal du souk (sur le côté de la ruelle) : comptoir bas, marchandises, auvent de toile.
## xf : milieu du devant de l'étal (le client se tient en -Z).
func souk_stall(xf: Transform3D, w: float, goods: String) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0.6)), Vector3(w, 0.8, 1.2), "bois_sombre", 1.2)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.4, 0.6)), Vector3(w, 0.8, 1.2))
	match goods:
		"epices":
			var keys := ["epice_rouge", "epice_jaune", "epice_orange", "epice_vert", "epice_brun"]
			for k in range(int(w / 0.55)):
				var x: float = -w / 2 + 0.3 + k * 0.55
				var c: Transform3D = xf * Transform3D(Basis(), Vector3(x, 0.8, 0.45))
				cyl(c, 0.2, 0.2, 0.08, "terre_cuite", 10)
				cyl(c * Transform3D(Basis(), Vector3(0, 0.08, 0)), 0.19, 0.02, 0.32, str(keys[k % keys.size()]), 10)
		"tapis":
			for k in range(3):
				var x2: float = -w / 2 + (k + 0.5) * w / 3
				quad(xf * Transform3D(Basis(), Vector3(x2, 1.9, 1.15)), w / 3 * 0.9, 2.0, "tapis_%d" % (k + 1), Vector2(0, 0), Vector2(1, 1), true)
			box(xf * Transform3D(Basis(), Vector3(0, 0.95, 0.6)), Vector3(w * 0.8, 0.3, 0.9), "tapis_1", 1.0)
		"lanternes":
			for k in range(int(w / 0.7)):
				var x3: float = -w / 2 + 0.35 + k * 0.7
				maroc_lantern(xf * Transform3D(Basis(), Vector3(x3, 2.5 - (k % 2) * 0.3, 0.5)), 0.9)
		"poteries":
			for k in range(int(w / 0.6)):
				var x4: float = -w / 2 + 0.3 + k * 0.6
				var c2: Transform3D = xf * Transform3D(Basis(), Vector3(x4, 0.8, 0.5))
				cyl(c2, 0.15, 0.24, 0.3, "terre_cuite", 10)
				cyl(c2 * Transform3D(Basis(), Vector3(0, 0.3, 0)), 0.24, 0.02, 0.32, "terre_cuite", 10)
		"babouches":
			for k in range(int(w / 0.3)):
				for j in range(3):
					box(xf * Transform3D(Basis(), Vector3(-w / 2 + 0.15 + k * 0.3, 1.2 + j * 0.35, 1.15)), Vector3(0.12, 0.28, 0.08), "cuir" if (k + j) % 3 else "tissu_jaune", 0.5)
		"dattes":
			for k in range(int(w / 0.7)):
				var c3: Transform3D = xf * Transform3D(Basis(), Vector3(-w / 2 + 0.35 + k * 0.7, 0.8, 0.5))
				cyl(c3, 0.3, 0.3, 0.12, "chaume", 12)
				cyl(c3 * Transform3D(Basis(), Vector3(0, 0.12, 0)), 0.27, 0.05, 0.16, "dattes" if k % 2 == 0 else "pomme", 10)
		"cuivre":
			for k in range(int(w / 0.6)):
				var c4: Transform3D = xf * Transform3D(Basis(), Vector3(-w / 2 + 0.3 + k * 0.6, 0.8, 0.5))
				cyl(c4, 0.18, 0.12, 0.25, "cuivre", 10)
				cyl(c4 * Transform3D(Basis(), Vector3(0, 0.25, 0)), 0.04, 0.02, 0.2, "cuivre", 6)
		_:
			for k in range(int(w / 0.8)):
				box(xf * Transform3D(Basis(), Vector3(-w / 2 + 0.4 + k * 0.8, 0.95, 0.6)), Vector3(0.7, 0.3, 0.9), str(["tissu_rouge", "tissu_bleu", "tissu_jaune", "tissu_vert"][k % 4]), 0.5)
	# auvent de toile tendu sur deux perches
	for sx in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(sx * (w / 2 - 0.05), 1.3, -0.4)), Vector3(0.06, 2.6, 0.06), "bois_sombre", 1.0)
	var p0: Vector3 = xf * Vector3(-w / 2, 2.6, -0.45)
	var p1: Vector3 = xf * Vector3(w / 2, 2.6, -0.45)
	var p2: Vector3 = xf * Vector3(w / 2, 3.0, 1.3)
	var p3: Vector3 = xf * Vector3(-w / 2, 3.0, 1.3)
	quad4("toile_rouge" if rng.randf() < 0.5 else "toile_bleue", p0, p1, p2, p3, (xf.basis * Vector3(0, 1, -0.2)).normalized(), Vector2(0, 0), Vector2(w / 1.2, 0), Vector2(w / 1.2, 1), Vector2(0, 1))

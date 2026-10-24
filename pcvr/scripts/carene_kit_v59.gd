extends "res://scripts/azur_kit_v56.gd"
## V59 : la boîte à outils de Carène — celle de Port-Azur (géométrie regroupée par matériau,
## boîtes, cylindres, lampadaires, tonneaux, caisses…) plus les matériaux du port dans
## l'épave : planches de récupération, toiles rayées taillées dans les vieilles voiles,
## goudron, braises, lanternes de bord toujours allumées, cuivre, briques du foyer.

const C := "res://assets/textures/carene/"


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D
	match key:
		"cabane", "cabane_sombre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(C + "planches_cabane.png")
			m.normal_enabled = true
			m.normal_texture = load(C + "planches_cabane_n.png")
			m.albedo_color = Color(1, 1, 1) if key == "cabane" else Color(0.62, 0.56, 0.5)
			m.roughness = 0.9
		"vaigrage":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(C + "bordage_int.png")
			m.normal_enabled = true
			m.normal_texture = load(C + "bordage_int_n.png")
			m.roughness = 0.92
		"pont":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(C + "pont.png")
			m.normal_enabled = true
			m.normal_texture = load(C + "pont_n.png")
			m.roughness = 0.85
		"toile_rouge", "toile_bleue":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(C + key + ".png")
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.95
			m.backlight_enabled = true
			m.backlight = Color(0.3, 0.25, 0.2)
		"voile":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(C + "voile.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.95
		"goudron":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.05, 0.045, 0.04)
			m.roughness = 0.3
			m.metallic_specular = 0.7
		"braise":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.25, 0.08, 0.02)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.38, 0.08)
			m.emission_energy_multiplier = 3.0
		"lanterne":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.9, 0.7, 0.9)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(1.0, 0.72, 0.38)
			m.emission_energy_multiplier = 2.6
		"cuivre":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.36, 0.2)
			m.metallic = 0.85
			m.roughness = 0.4
		"bronze":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.45, 0.36, 0.2)
			m.metallic = 0.8
			m.roughness = 0.45
		"brique":
			m = StandardMaterial3D.new()
			m.albedo_texture = _tex("moellons.png")
			m.normal_enabled = true
			m.normal_texture = _tex("moellons_n.png")
			m.albedo_color = Color(0.72, 0.4, 0.3)
			m.roughness = 0.92
		"canon":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.09, 0.09, 0.1)
			m.metallic = 0.7
			m.roughness = 0.55
		"carte":
			m = StandardMaterial3D.new()
			m.albedo_texture = load("res://assets/textures/carte/archipel.png")
			m.roughness = 0.8
			# V68 : la carte monte jusqu'à la Balafre ; les cartes murales gardent l'ancien cadrage
			if m.albedo_texture != null and m.albedo_texture.get_height() > 1100:
				m.uv1_scale = Vector3(1.0, 0.75, 1.0)
				m.uv1_offset = Vector3(0.0, 0.25, 0.0)
		"corde":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.5, 0.42, 0.3)
			m.roughness = 0.95
		"herbes":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.38, 0.45, 0.22)
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"poisson":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.68, 0.72)
			m.metallic = 0.5
			m.roughness = 0.3
		"pomme":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.72, 0.15, 0.1)
			m.roughness = 0.5
		"bouteille":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.18, 0.4, 0.2, 0.85)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.1
			m.metallic_specular = 0.9
		_:
			return super.mat(key)
	mats[key] = m
	return m


## Enseigne peinte de Carène (texture du dossier carene/).
func carene_sign(xf: Transform3D, w: float, h: float, file: String, hanging: bool = false) -> void:
	box(xf, Vector3(w + 0.1, h + 0.1, 0.07), "bois_sombre", 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(C + file + ".png")
	m.roughness = 0.65
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.name = "Enseigne_" + file
	mi.mesh = qm
	mi.material_override = m
	mi.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.04))
	root.add_child(mi)
	signs.append(mi)
	if hanging:
		var mi2 := mi.duplicate() as MeshInstance3D
		mi2.transform = xf * Transform3D(Basis(), Vector3(0, 0, 0.04))
		root.add_child(mi2)


## Lanterne de bord (cage de fer, verre allumé) ; xf : le haut (le crochet).
func ship_lantern(xf: Transform3D) -> void:
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.12, 0)), 0.03, 0.03, 0.12, "fer", 6, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.2, 0)), 0.04, 0.16, 0.1, "fer", 8)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.52, 0)), 0.13, 0.13, 0.32, "lanterne", 8, false)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI / 4.0
		box(xf * Transform3D(Basis(), Vector3(cos(a) * 0.14, -0.36, sin(a) * 0.14)), Vector3(0.025, 0.34, 0.025), "fer", 1.0)
	cyl(xf * Transform3D(Basis(), Vector3(0, -0.58, 0)), 0.15, 0.15, 0.04, "fer", 8)


## Un canon sur son affût ; xf : posé au sol, la bouche vers -Z.
func cannon(xf: Transform3D) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.28, 0.2)), Vector3(1.1, 0.4, 1.7), "bois_sombre", 1.0)
	for s in [-1.0, 1.0]:
		for zz in [-0.5, 0.8]:
			cyl(xf * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(s * 0.62, 0.22, zz)), 0.22, 0.22, 0.12, "bois_sombre", 12)
	cyl(xf * Transform3D(Basis(Vector3(1, 0, 0), -PI * 0.5 + 0.03), Vector3(0, 0.66, 1.0)), 0.3, 0.2, 2.6, "canon", 14)
	cyl(xf * Transform3D(Basis(Vector3(1, 0, 0), -PI * 0.5), Vector3(0, 0.66, 1.1)), 0.24, 0.24, 0.25, "canon", 12)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0.0)), Vector3(1.2, 0.9, 2.6))


## Une cabane de planches : murs, porte (sur la face -Z), fenêtre, toit à une pente en
## toile goudronnée ou en planches. xf : milieu du bas de la façade.
## Renvoie le point devant la porte (local du repère xf).
func shack(xf: Transform3D, w: float, d: float, h: float, roof: String = "cabane_sombre", door_x: float = 0.0, window: bool = true) -> Vector3:
	var t: float = 0.1
	var dw: float = 1.0
	var dh: float = 2.0
	# façade : de part et d'autre de la porte, et au-dessus
	var left_w: float = (w / 2.0 + door_x) - dw / 2.0
	var right_w: float = (w / 2.0 - door_x) - dw / 2.0
	if left_w > 0.05:
		var cx: float = -w / 2.0 + left_w / 2.0
		box(xf * Transform3D(Basis(), Vector3(cx, h / 2.0, 0)), Vector3(left_w, h, t), "cabane", 1.6)
		col_box(xf * Transform3D(Basis(), Vector3(cx, h / 2.0, 0)), Vector3(left_w, h, t + 0.1))
	if right_w > 0.05:
		var cx2: float = w / 2.0 - right_w / 2.0
		box(xf * Transform3D(Basis(), Vector3(cx2, h / 2.0, 0)), Vector3(right_w, h, t), "cabane", 1.6)
		col_box(xf * Transform3D(Basis(), Vector3(cx2, h / 2.0, 0)), Vector3(right_w, h, t + 0.1))
	box(xf * Transform3D(Basis(), Vector3(door_x, (h + dh) / 2.0, 0)), Vector3(dw, h - dh, t), "cabane", 1.6)
	# la porte, entrouverte
	var hinge := Vector3(door_x - dw / 2.0, 0, -0.02)
	var db := Basis(Vector3.UP, -0.5)
	box(xf * Transform3D(db, hinge + db * Vector3(dw / 2.0, dh / 2.0, 0)), Vector3(dw - 0.04, dh - 0.04, 0.05), "bois_sombre", 1.0)
	# l'intérieur sombre derrière la porte (on ne voit pas dedans)
	quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(door_x, dh / 2.0, 0.5)), dw, dh, "goudron")
	# côtés et fond
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s * w / 2.0, h / 2.0, d / 2.0)), Vector3(t, h, d), "cabane", 1.6)
		col_box(xf * Transform3D(Basis(), Vector3(s * w / 2.0, h / 2.0, d / 2.0)), Vector3(t + 0.1, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, h / 2.0, d)), Vector3(w, h, t), "cabane", 1.6)
	col_box(xf * Transform3D(Basis(), Vector3(0, h / 2.0, d)), Vector3(w, h, t + 0.1))
	# toit à une pente (plus haut sur la façade)
	var rise: float = 0.6
	var slope: float = atan2(rise, d + 0.6)
	var rb := Basis(Vector3.RIGHT, -slope)
	box(xf * Transform3D(rb, Vector3(0, h + rise / 2.0 + 0.05, d / 2.0)), Vector3(w + 0.6, 0.08, (d + 0.8) / cos(slope)), roof, 1.4)
	if window:
		var wx: float = (w / 4.0 + door_x / 2.0) if door_x <= 0.0 else (-w / 4.0 + door_x / 2.0)
		if absf(wx - door_x) > 0.9:
			quad(xf * Transform3D(Basis(), Vector3(wx, h * 0.62, -0.06)), 0.7, 0.6, "fenetre_nuit")
			box(xf * Transform3D(Basis(), Vector3(wx, h * 0.62 - 0.33, -0.1)), Vector3(0.84, 0.06, 0.14), "bois_sombre", 1.0)
	return Vector3(door_x, 0, -0.8)


## Un étal de marché : comptoir, quatre poteaux, toile tendue, marchandises.
## xf : milieu du devant du comptoir (le client se tient en -Z).
func stall(xf: Transform3D, w: float, cloth: String, goods: String) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.48, 0.45)), Vector3(w, 0.96, 0.9), "cabane", 1.4)
	box(xf * Transform3D(Basis(), Vector3(0, 0.98, 0.45)), Vector3(w + 0.1, 0.06, 1.0), "bois", 1.4)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0.45)), Vector3(w, 1.0, 0.9))
	for sx in [-1.0, 1.0]:
		for zz in [0.0, 1.9]:
			box(xf * Transform3D(Basis(), Vector3(sx * (w / 2.0 - 0.05), 1.15, zz)), Vector3(0.09, 2.3, 0.09), "bois_sombre", 1.0)
	# la toile, en pente vers le client, avec un lambrequin
	var p0: Vector3 = xf * Vector3(-w / 2.0 - 0.2, 2.15, -0.35)
	var p1: Vector3 = xf * Vector3(w / 2.0 + 0.2, 2.15, -0.35)
	var p2: Vector3 = xf * Vector3(w / 2.0 + 0.2, 2.45, 2.1)
	var p3: Vector3 = xf * Vector3(-w / 2.0 - 0.2, 2.45, 2.1)
	var nn: Vector3 = (xf.basis * Vector3(0, 1, -0.12)).normalized()
	quad4(cloth, p0, p1, p2, p3, nn, Vector2(0, 0), Vector2(w / 1.2, 0), Vector2(w / 1.2, 1), Vector2(0, 1))
	quad(xf * Transform3D(Basis(), Vector3(0, 2.0, -0.36)), w + 0.4, 0.3, cloth, Vector2(0, 0), Vector2(w / 1.2, 0.3), true)
	# marchandises
	match goods:
		"poisson":
			for k in range(3):
				var x: float = -w / 2.0 + 0.5 + k * (w - 1.0) / 2.0
				box(xf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(x, 1.12, 0.4)), Vector3(0.7, 0.14, 0.55), "bois_clair", 0.8)
				for f in range(4):
					box(xf * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.4, 0.4)), Vector3(x + rng.randf_range(-0.22, 0.22), 1.22, 0.3 + rng.randf_range(-0.12, 0.12))), Vector3(0.36, 0.06, 0.1), "poisson", 0.5)
		"cordes":
			for k in range(4):
				var x2: float = -w / 2.0 + 0.4 + k * (w - 0.8) / 3.0
				ring(xf * Transform3D(Basis(), Vector3(x2, 1.02, 0.45)), 0.1, 0.24, 0.14, "corde", 14)
			for k in range(3):
				ship_lantern(xf * Transform3D(Basis(), Vector3(-w / 2.0 + 0.6 + k * (w - 1.2) / 2.0, 2.05, 0.4)))
		"fruits":
			for k in range(3):
				var x3: float = -w / 2.0 + 0.5 + k * (w - 1.0) / 2.0
				box(xf * Transform3D(Basis(), Vector3(x3, 1.1, 0.45)), Vector3(0.6, 0.18, 0.5), "bois_clair", 0.8)
				for f in range(5):
					var bm := Transform3D(Basis(), Vector3(x3 + rng.randf_range(-0.2, 0.2), 1.24, 0.45 + rng.randf_range(-0.15, 0.15)))
					cyl(xf * bm, 0.06, 0.06, 0.1, "pomme", 8)
		"bric":
			for k in range(5):
				var x4: float = -w / 2.0 + 0.3 + k * (w - 0.6) / 4.0
				var kind: int = k % 3
				if kind == 0:
					cyl(xf * Transform3D(Basis(), Vector3(x4, 1.01, 0.4)), 0.07, 0.04, 0.32, "bouteille", 8)
				elif kind == 1:
					box(xf * Transform3D(Basis(Vector3.UP, 0.3), Vector3(x4, 1.1, 0.5)), Vector3(0.3, 0.18, 0.24), "cuivre", 0.6)
				else:
					cyl(xf * Transform3D(Basis(), Vector3(x4, 1.01, 0.5)), 0.12, 0.12, 0.06, "bronze", 12)
	# deux caisses et un tonneau derrière
	crate(xf * Vector3(-w / 2.0 + 0.5, 0.0, 1.6), rng.randf() * 0.4, 0.6)
	barrel(xf * Vector3(w / 2.0 - 0.45, 0.0, 1.55))


## Garde-corps de bois (montants et main courante) le long d'un segment (repère monde).
func railing(a: Vector3, b: Vector3, up: Vector3, h: float = 1.0) -> void:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.1:
		return
	var f: Vector3 = dir / length
	var side: Vector3 = f.cross(up).normalized()
	var bas := Basis(side, up, -f)
	var mid: Vector3 = (a + b) * 0.5
	box(Transform3D(bas, mid + up * h), Vector3(0.1, 0.1, length), "bois_sombre", 1.0)
	box(Transform3D(bas, mid + up * h * 0.5), Vector3(0.06, 0.06, length), "bois_sombre", 1.0)
	var n: int = maxi(1, int(length / 1.6))
	for i in range(n + 1):
		var p: Vector3 = a + dir * (float(i) / n)
		box(Transform3D(bas, p + up * h * 0.5), Vector3(0.1, h, 0.1), "bois_sombre", 1.0)
	col_box(Transform3D(bas, mid + up * h * 0.55), Vector3(0.14, h * 1.1, length))


## Un hamac de toile entre deux points (monde) ; il pend au milieu.
func hammock(a: Vector3, b: Vector3, sag: float, cloth: String) -> void:
	var n: int = 8
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized() * 0.45
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	for i in range(n + 1):
		var t: float = float(i) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sag * sin(t * PI)
		var w: float = sin(t * PI) * 0.9 + 0.1
		var l: Vector3 = p + side * w + Vector3.UP * 0.12 * w
		var r: Vector3 = p - side * w + Vector3.UP * 0.12 * w
		if i > 0:
			quad4(cloth, prev_l, prev_r, r, l, Vector3.UP, Vector2(0, t - 0.125), Vector2(1, t - 0.125), Vector2(1, t), Vector2(0, t))
		prev_l = l
		prev_r = r

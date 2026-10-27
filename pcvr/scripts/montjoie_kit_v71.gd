extends "res://scripts/braise_kit_v70.gd"
## V71 : la boîte à outils de Montjoie, la ville des aventuriers (et du Donjon des Mille Marches).
## Même principe que les autres kits : la géométrie regroupée par matière (un maillage par matière
## et par quartier : commit()), les pièces répétées en MultiMesh (place()), les collisions dans un
## seul corps statique. Les matières « …71 » viennent de montjoie_mats_v71.gd ; les autres, des
## kits précédents (on garde les réverbères, les tours, les remparts, les escaliers de V70).
##  - house71() : la maison de Montjoie (un rez-de-chaussée de moellons ou d'enduit, des étages à
##    pans de bois en encorbellement, enduits colorés, fenêtres à petits carreaux et volets,
##    jardinières, toit de tuiles très pentu, pignon sur rue, lucarnes, cheminée, enseigne) ;
##  - window71(), door71(), shop_sign71(), awning71(), flower_box71() ;
##  - fountain71(), well71(), stall71() (un étal de marché), quest_board71() (le tableau des
##    quêtes), windmill71() (renvoie les ailes, qui tournent), cart71(), haystack71(), fence71(),
##    tree_guard71(), bench71(), barrel71(), crate71().
## Repères : une façade « xf » regarde +Z local (comme braise_kit_v70).

const Mats71 = preload("res://scripts/montjoie_mats_v71.gd")

const ENDUIT_V := ["creme", "ocre", "rose", "bleu", "vert", "blanc", "jaune", "saumon", "creme", "blanc"]
const TOIT_V := ["rouge", "rouge", "orange", "brun", "ardoise", "rouge", "orange"]
const VOLET_V := ["rouge", "vert", "bleu", "brun", "jaune", "vert"]
const FLEUR_V := ["rouge", "rose", "jaune", "blanc", "violet"]

var sails: Array = []                    # Node3D : les ailes des moulins (elles tournent)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats71.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


## Les prototypes de Montjoie (fenêtres, portes, jardinières), les autres : ceux de V70.
func proto(key: String) -> ArrayMesh:
	if protos.has(key):
		return protos[key]
	var parts: PackedStringArray = key.split("|")
	var kind: String = parts[0]
	if not kind.ends_with("71"):
		return super.proto(key)
	var saved: Dictionary = batch
	batch = {}
	var I := Transform3D.IDENTITY
	match kind:
		"fen71":
			_win71_geo(I, 0.86, 1.3, parts[1] if parts.size() > 1 else "", parts.size() > 2 and parts[2] == "1")
		"fenp71":
			# une petite fenêtre (combles, lucarnes, rez-de-chaussée des petites maisons)
			_win71_geo(I, 0.62, 0.86, "", parts.size() > 2 and parts[2] == "1")
		"porte71":
			_door71_geo(I, parts[1] if parts.size() > 1 else "planches71_sombre")
		"fleurs71":
			_flowers71_geo(I, parts[1] if parts.size() > 1 else "rouge")
	var mesh := ArrayMesh.new()
	for k in batch:
		var st: SurfaceTool = batch[k]
		var m: Material = mat(str(k))
		if m is StandardMaterial3D and (m as StandardMaterial3D).normal_enabled:
			st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	batch = saved
	protos[key] = mesh
	return mesh


# =================================================================== fenêtres, portes

## Une fenêtre à petits carreaux (le prototype, w × h, le centre à l'origine, sur le nu du mur qui
## regarde +Z) : son cadre de chêne, son appui de pierre, ses volets ouverts.
func _win71_geo(xf: Transform3D, w: float, h: float, volet: String, lit: bool) -> void:
	quadz(xf * T(0, 0, 0.015), w, h, "vitre71_on" if lit else "vitre71_off")
	box(xf * T(0, h * 0.5 + 0.05, 0.03), Vector3(w + 0.2, 0.12, 0.1), "poutre71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 + 0.05), 0, 0.03), Vector3(0.1, h, 0.1), "poutre71", 1.0)
	box(xf * T(0, 0, 0.03), Vector3(0.05, h, 0.03), "poutre71", 1.0)
	box(xf * T(0, h * 0.18, 0.03), Vector3(w, 0.04, 0.03), "poutre71", 1.0)
	box(xf * T(0, -h * 0.5 - 0.05, 0.06), Vector3(w + 0.3, 0.1, 0.2), "dalles71_clair", 1.0)
	if volet != "":
		for s2 in [-1.0, 1.0]:
			var ang: float = deg_to_rad(165.0) * s2
			var hinge := Vector3(s2 * (w * 0.5 + 0.1), 0, 0.06)
			var b := Basis(Vector3.UP, -ang)
			var c: Vector3 = hinge + b * Vector3(-s2 * w * 0.25, 0, 0)
			box(Transform3D(b, c), Vector3(w * 0.5, h, 0.04), "volet71_" + volet, 1.0)


## Une porte de planches dans son cadre de pierre (le prototype : 1,2 × 2,4 m).
func _door71_geo(xf: Transform3D, wood: String) -> void:
	box(xf * T(0, 1.2, 0.02), Vector3(1.2, 2.4, 0.04), wood, 1.0)
	for k in range(3):
		box(xf * T(0, 0.45 + k * 0.75, 0.05), Vector3(1.16, 0.08, 0.02), "fer71", 1.0)
	box(xf * T(0.42, 1.15, 0.07), Vector3(0.08, 0.08, 0.04), "laiton71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * 0.7, 1.25, 0.04), Vector3(0.2, 2.5, 0.1), "dalles71_clair", 1.0)
	box(xf * T(0, 2.55, 0.04), Vector3(1.6, 0.22, 0.12), "dalles71_clair", 1.0)
	box(xf * T(0, 0.04, 0.25), Vector3(1.5, 0.08, 0.5), "dalles71", 1.0)


## Une jardinière de géraniums sous une fenêtre (le prototype).
func _flowers71_geo(xf: Transform3D, c: String) -> void:
	box(xf * T(0, 0, 0.12), Vector3(0.9, 0.2, 0.24), "planches71", 1.0)
	for k in range(6):
		var x: float = -0.36 + k * 0.145
		ball(xf * T(x, 0.14, 0.12 + (0.04 if k % 2 == 0 else -0.04)), 0.09, "feuille71", 6, 3)
		ball(xf * T(x + 0.03, 0.22, 0.14), 0.065, "fleur71_" + c, 6, 3)


func window71(xf: Transform3D, volet: String, lit: bool, small: bool = false) -> void:
	place(("fenp71|" if small else "fen71|") + volet + "|" + ("1" if lit else "0"), xf)


func door71(xf: Transform3D, wood: String = "planches71_sombre") -> void:
	place("porte71|" + wood, xf)


func flower_box71(xf: Transform3D) -> void:
	place("fleurs71|" + FLEUR_V[rng.randi() % FLEUR_V.size()], xf)


# =================================================================== la maison de Montjoie

## xf : le milieu de la façade au sol, la façade regarde +Z, la maison s'étend vers -Z sur d.
## opts : floors (1-4), gf, uf, base (moellons71, enduit71_…), wall (enduit71_…), roof
## (tuiles71_…, chaume71), pitch, gable (pignon sur rue), jet (encorbellement), lit (part des
## fenêtres allumées), door_x, volet, shop (enseigne : guilde, forge…), awning (couleur), flowers,
## chimney, dormers, timber (pans de bois), sides (1 : gauche, 2 : droite : fenêtres sur les côtés),
## back (fenêtres derrière). Renvoie le point devant la porte.
func house71(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Vector3:
	var floors: int = maxi(int(opts.get("floors", 2)), 1)
	var gf: float = float(opts.get("gf", 3.2))
	var uf: float = float(opts.get("uf", 2.9))
	var H: float = gf + uf * (floors - 1)
	var base: String = str(opts.get("base", "moellons71"))
	var wall: String = str(opts.get("wall", "enduit71_" + ENDUIT_V[rng.randi() % ENDUIT_V.size()]))
	var roof: String = str(opts.get("roof", "tuiles71_" + TOIT_V[rng.randi() % TOIT_V.size()]))
	var pitch: float = float(opts.get("pitch", rng.randf_range(50.0, 58.0)))
	var jet: float = float(opts.get("jet", 0.35)) if floors > 1 else 0.0
	var lit_k: float = float(opts.get("lit", 0.5))
	var dx: float = float(opts.get("door_x", 0.0))
	var volet: String = str(opts.get("volet", VOLET_V[rng.randi() % VOLET_V.size()]))
	var gable: bool = bool(opts.get("gable", true))
	var timber: bool = bool(opts.get("timber", true))
	var shop: String = str(opts.get("shop", ""))
	var sides: int = int(opts.get("sides", 0))
	# le soubassement, le rez-de-chaussée
	box(xf * T(0, -0.3, -d * 0.5), Vector3(w + 0.16, 1.0, d + 0.16), "moellons71_sombre", 1.6, 63 - 8)
	box(xf * T(0, gf * 0.5, -d * 0.5), Vector3(w, gf, d), base, 2.4, 63 - 8 - 4)
	col_box(xf * T(0, H * 0.5, -d * 0.5), Vector3(w, H, d))
	# les étages, en encorbellement sur la rue, et leurs pans de bois
	if floors > 1:
		var uh: float = H - gf
		box(xf * T(0, gf + uh * 0.5, (jet - d) * 0.5), Vector3(w, uh, d + jet), wall, 2.6, 63 - 8 - 4)
		box(xf * T(0, gf - 0.04, (jet - d) * 0.5), Vector3(w + 0.12, 0.24, d + jet + 0.12), "poutre71", 1.2)
		for k in range(floors - 1):
			var fy: float = gf + k * uf
			if timber:
				_frame71(xf * T(0, fy, jet), w, uf, k)
				if bool(opts.get("back", true)):
					_frame71(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, fy, -d)), w, uf, k + 1)
				for sd in [1, 2]:
					var sg: float = -1.0 if sd == 1 else 1.0
					_frame71(xf * Transform3D(Basis(Vector3.UP, sg * PI * 0.5), Vector3(sg * w * 0.5, fy, (jet - d) * 0.5)), d + jet, uf, k + 2, (sides & sd) != 0)
			if k > 0:
				box(xf * T(0, fy, (jet - d) * 0.5), Vector3(w + 0.08, 0.14, d + jet + 0.08), "poutre71", 1.2, 63 - 8 - 4)
	# les fenêtres : façade, et derrière
	var n: int = clampi(int((w - 0.4) / 1.55), 1, 5)
	for f in range(1, floors):
		var y: float = gf + (f - 1) * uf + uf * 0.52
		for i in range(n):
			var x: float = -w * 0.5 + (i + 0.5) * w / n
			window71(xf * T(x, y, jet), volet, rng.randf() < lit_k)
			if bool(opts.get("flowers", rng.randf() < 0.45)) and rng.randf() < 0.55:
				flower_box71(xf * T(x, y - 0.78, jet))
			if bool(opts.get("back", true)):
				window71(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-x, y, -d)), volet, rng.randf() < lit_k * 0.8)
		for sd2 in [1, 2]:
			if (sides & sd2) == 0:
				continue
			var sg2: float = -1.0 if sd2 == 1 else 1.0
			var sw: float = d + jet
			var ns: int = clampi(int((sw - 0.4) / 1.55), 1, 5)
			var face: Transform3D = xf * Transform3D(Basis(Vector3.UP, sg2 * PI * 0.5), Vector3(sg2 * w * 0.5, y, (jet - d) * 0.5))
			for i2 in range(ns):
				window71(face * T(-sw * 0.5 + (i2 + 0.5) * sw / ns, 0, 0), volet, rng.randf() < lit_k * 0.8)
	# le rez-de-chaussée : la porte, une vitrine (boutique) ou des fenêtres
	if bool(opts.get("door", true)):
		door71(xf * T(dx, 0.0, 0.0), "planches71_sombre" if rng.randf() < 0.6 else "volet71_" + volet)
	for i3 in range(n):
		var x3: float = -w * 0.5 + (i3 + 0.5) * w / n
		if absf(x3 - dx) < 1.3:
			continue
		if shop != "":
			_shop_window71(xf * T(x3, 1.35, 0.0), minf(1.6, w / n * 0.8), 1.9)
		else:
			window71(xf * T(x3, 1.55, 0.0), volet if floors == 1 else "", rng.randf() < lit_k * 0.7, floors > 1)
	if shop != "":
		shop_sign71(xf * T(w * 0.5 - 0.3, gf - 0.55, 0.0), shop)
		if str(opts.get("awning", "")) != "":
			awning71(xf * T(0, gf - 0.25, 0.0), w - 0.6, 1.4, 0.7, str(opts["awning"]))
	# le toit
	var rise: float
	var roof_key: String = roof
	if gable:
		rise = roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, H, (jet - d) * 0.5)), d + jet, w, pitch, 0.45, roof_key, wall)
		if timber and floors > 1:
			# des pans de bois dans le pignon : le poinçon et l'entrait
			var gx: Transform3D = xf * T(0, H, jet + 0.02)
			box(gx * T(0, rise * 0.45, 0), Vector3(0.16, rise * 0.9, 0.06), "poutre71", 1.0)
			box(gx * T(0, rise * 0.42, 0), Vector3(w * 0.52, 0.14, 0.06), "poutre71", 1.0)
			for s in [-1.0, 1.0]:
				var a := Vector3(s * w * 0.22, 0.05, 0)
				var b := Vector3(s * 0.05, rise * 0.78, 0)
				var mid: Vector3 = (a + b) * 0.5
				box(gx * Transform3D(Basis(Vector3.BACK, atan2(b.y - a.y, b.x - a.x)), mid), Vector3(a.distance_to(b), 0.12, 0.05), "poutre71", 1.0)
		if rise > 2.2:
			window71(xf * T(0, H + rise * 0.24 + 0.2, jet + 0.03), "", rng.randf() < lit_k, true)
	else:
		rise = roof_gable(xf * T(0, H, (jet - d) * 0.5), w, d + jet, pitch * 0.9, 0.45, roof_key, wall)
		if bool(opts.get("dormers", w > 6.0)):
			var nd: int = clampi(int(w / 3.6), 1, 3)
			for i5 in range(nd):
				var x5: float = -w * 0.5 + (i5 + 0.5) * w / nd
				_dormer71(xf * T(x5, H + 0.2, jet - 0.3 - (d + jet) * 0.14), roof_key, wall, rng.randf() < lit_k)
	# la cheminée
	if bool(opts.get("chimney", rng.randf() < 0.75)):
		var cxs: float = (w * 0.25) * (1.0 if rng.randf() < 0.5 else -1.0)
		var ch_h: float = rise + 1.4
		box(xf * T(cxs, H + ch_h * 0.5, -d * 0.62), Vector3(0.66, ch_h, 0.66), "moellons71", 1.2, 63 - 8)
		box(xf * T(cxs, H + ch_h + 0.06, -d * 0.62), Vector3(0.86, 0.12, 0.86), "dalles71_clair", 1.0)
		box(xf * T(cxs, H + ch_h + 0.24, -d * 0.62), Vector3(0.3, 0.26, 0.3), "terre71", 1.0)
		chimneys70.append(xf * Vector3(cxs, H + ch_h + 0.45, -d * 0.62))
	return xf * Vector3(dx, 0.0, 1.2)


## Les pans de bois d'un étage sur une face (xf : le milieu du bas de la face, qui regarde +Z) :
## les poteaux, la sablière, l'appui, les écharpes et les croix de Saint-André entre les fenêtres.
## win : il y a des fenêtres sur cette face (on laisse leurs travées libres).
func _frame71(xf: Transform3D, w: float, h: float, seed_k: int, win: bool = true) -> void:
	var nwin: int = clampi(int((w - 0.4) / 1.55), 1, 5)
	var z: float = 0.035
	var wy: float = h * 0.52
	# les travées des fenêtres (les fenêtres sont posées par house71 aux mêmes abscisses)
	var holes: Array = []
	if win:
		for i in range(nwin):
			var c: float = -w * 0.5 + (i + 0.5) * w / nwin
			holes.append([c - 0.55, c + 0.55])
	box(xf * T(0, h - 0.09, z), Vector3(w + 0.04, 0.17, 0.08), "poutre71", 1.0, 63 - 32)
	box(xf * T(0, 0.12, z), Vector3(w + 0.04, 0.2, 0.08), "poutre71", 1.0, 63 - 32)
	var free: Array = []
	var cur: float = -w * 0.5
	for hl in holes:
		var a: float = maxf(float(hl[0]), -w * 0.5)
		var b: float = minf(float(hl[1]), w * 0.5)
		for x in [a, b]:
			box(xf * T(x, h * 0.5, z), Vector3(0.16, h, 0.07), "poutre71", 1.0, 63 - 32)
		box(xf * T((a + b) * 0.5, wy - 0.78, z), Vector3(b - a, 0.12, 0.07), "poutre71", 1.0, 63 - 32)
		box(xf * T((a + b) * 0.5, wy + 0.76, z), Vector3(b - a, 0.12, 0.07), "poutre71", 1.0, 63 - 32)
		if a > cur + 0.05:
			free.append([cur, a])
		cur = b
	if cur < w * 0.5 - 0.05:
		free.append([cur, w * 0.5])
	var k: int = seed_k
	for fr in free:
		var x0: float = float(fr[0])
		var x1: float = float(fr[1])
		var L: float = x1 - x0
		var m: int = maxi(1, int(round(L / 1.1)))
		for j in range(m + 1):
			box(xf * T(x0 + L * j / m, h * 0.5, z), Vector3(0.16, h, 0.07), "poutre71", 1.0, 63 - 32)
		if L < 0.45:
			continue
		for j2 in range(m):
			var a2: float = x0 + L * j2 / m
			var b2: float = x0 + L * (j2 + 1) / m
			k += 1
			match k % 3:
				0:
					_strut(xf, Vector3(a2 + 0.08, 0.2, z), Vector3(b2 - 0.08, h - 0.2, z), true, 0.0)
					_strut(xf, Vector3(a2 + 0.08, 0.2, z), Vector3(a2 + 0.08, h - 0.2, z), false, b2 - 0.08)
				1:
					_strut(xf, Vector3(a2 + 0.08, 0.2, z), Vector3(b2 - 0.08, h - 0.2, z), true, 0.0)
				_:
					box(xf * T((a2 + b2) * 0.5, h * 0.5, z), Vector3(b2 - a2, 0.12, 0.07), "poutre71", 1.0, 63 - 32)
					_strut(xf, Vector3(b2 - 0.08, 0.2, z), Vector3(a2 + 0.08, h * 0.5, z), true, 0.0)


## Une pièce de bois en biais (dans le plan de la face) ; « cross » : l'autre diagonale (de bas à
## droite à haut à gauche, x_right : le bord droit).
func _strut(xf: Transform3D, a: Vector3, b: Vector3, straight: bool, x_right: float) -> void:
	var p0: Vector3 = a
	var p1: Vector3 = b
	if not straight:
		p0 = Vector3(x_right, a.y, a.z)
		p1 = Vector3(a.x, b.y, a.z)
	var mid: Vector3 = (p0 + p1) * 0.5
	var ang: float = atan2(p1.y - p0.y, p1.x - p0.x)
	box(xf * Transform3D(Basis(Vector3.BACK, ang), mid), Vector3(p0.distance_to(p1), 0.13, 0.065), "poutre71", 1.0, 63 - 32)


func _dormer71(xf: Transform3D, roof: String, wall: String, lit: bool) -> void:
	box(xf * T(0, 0.6, -0.55), Vector3(1.3, 1.2, 1.1), wall, 1.4, 63 - 8)
	window71(xf * T(0, 0.62, 0.0), "", lit, true)
	roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 1.2, -0.55)), 1.1, 1.3, 50.0, 0.12, roof, wall)


## Une vitrine de boutique : un grand châssis à petits carreaux, une tablette.
func _shop_window71(xf: Transform3D, w: float, h: float) -> void:
	quadz(xf * T(0, 0, 0.015), w, h, "vitre71_on")
	box(xf * T(0, h * 0.5 + 0.06, 0.04), Vector3(w + 0.24, 0.14, 0.1), "poutre71", 1.0)
	box(xf * T(0, -h * 0.5 - 0.06, 0.04), Vector3(w + 0.3, 0.14, 0.3), "planches71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 + 0.06), 0, 0.04), Vector3(0.12, h, 0.1), "poutre71", 1.0)
	for k in range(1, 3):
		box(xf * T(-w * 0.5 + w * k / 3.0, 0, 0.03), Vector3(0.04, h, 0.03), "poutre71", 1.0)
	box(xf * T(0, 0, 0.03), Vector3(w, 0.04, 0.03), "poutre71", 1.0)


## Une enseigne pendue à sa potence de fer (xf : le point d'accroche sur le mur, +Z : la rue).
func shop_sign71(xf: Transform3D, sign_id: String, w: float = 0.95, h: float = 0.95) -> void:
	box(xf * T(0, 0.2, 0.02), Vector3(0.12, 0.3, 0.04), "fer71", 1.0)
	box(xf * T(0, 0.25, 0.55), Vector3(0.04, 0.04, 1.1), "fer71", 1.0)
	beam(xf * Vector3(0, -0.1, 0.03), xf * Vector3(0, 0.23, 0.6), 0.03, "fer71")
	var sx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, -h * 0.5 + 0.1, 0.62))
	box(sx, Vector3(w + 0.08, h + 0.08, 0.05), "poutre71", 1.0)
	quadz(sx * T(0, 0, 0.03), w, h, "enseigne71_" + sign_id)
	quadz(sx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.03)), w, h, "enseigne71_" + sign_id)
	for s in [-1.0, 1.0]:
		beam(xf * Vector3(0, 0.23, 0.62 + s * w * 0.35), sx * Vector3(s * w * 0.35, h * 0.5 + 0.04, 0), 0.012, "fer71")


## Un store de toile (xf : le milieu du haut, sur le mur ; il avance vers +Z).
func awning71(xf: Transform3D, w: float, out: float, drop: float, color: String) -> void:
	var key: String = "tissu71_" + color
	var p0: Vector3 = xf * Vector3(-w * 0.5, 0, 0.05)
	var p1: Vector3 = xf * Vector3(w * 0.5, 0, 0.05)
	var p2: Vector3 = xf * Vector3(w * 0.5, -drop, out)
	var p3: Vector3 = xf * Vector3(-w * 0.5, -drop, out)
	var nn: Vector3 = (xf.basis * Vector3(0, out, drop).normalized()).normalized()
	quad4(key, p0, p1, p2, p3, nn, Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1))
	quad4(key, p3, p2, p1, p0, -nn, Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1))
	# le lambrequin
	var lx: Transform3D = xf * T(0, -drop - 0.16, out)
	quadz(lx, w, 0.32, key)
	quadz(lx * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), w, 0.32, key)
	for s in [-1.0, 1.0]:
		beam(xf * Vector3(s * (w * 0.5 - 0.1), -0.9, 0.04), xf * Vector3(s * (w * 0.5 - 0.1), -drop, out), 0.03, "fer71")


# =================================================================== la ville

## Une fontaine ronde (xf : le centre, au sol) : le bassin, la colonne, la vasque, l'eau, une
## statue d'aventurier (l'épée levée) ; renvoie le centre.
func fountain71(xf: Transform3D, r: float = 3.4) -> Vector3:
	ring(xf, r - 0.4, r, 0.75, "dalles71_clair", 32)
	ring(xf * T(0, 0.75, 0), r - 0.5, r + 0.08, 0.14, "dalles71", 32)
	disc(xf * T(0, 0.55, 0), r - 0.4, "eau71_claire", 32, 3.0)
	disc(xf * T(0, 0.05, 0), r - 0.4, "dalles71", 24, 2.0)
	col_cyl(xf.origin, r, 0.85)
	col_cyl(xf.origin, 1.2, 2.4)                # V77 : la colonne, la vasque et la statue sont solides
	col_cyl(xf.origin, 0.55, 5.1)
	cyl(xf * T(0, 0.0, 0), 0.5, 0.42, 2.0, "dalles71_clair", 12)
	cyl(xf * T(0, 2.0, 0), 1.2, 0.3, 0.35, "dalles71_clair", 16)
	disc(xf * T(0, 2.3, 0), 1.05, "eau71_claire", 16)
	cyl(xf * T(0, 2.3, 0), 0.28, 0.24, 0.8, "dalles71_clair", 10)
	# la statue : un aventurier de pierre, l'épée levée (le fondateur de la Guilde)
	var sx: Transform3D = xf * T(0, 3.1, 0)
	cyl(sx, 0.32, 0.28, 0.9, "dalles71_clair", 10)
	cyl(sx * T(0, 0.9, 0), 0.3, 0.26, 0.7, "dalles71_clair", 10)
	ball(sx * T(0, 1.85, 0), 0.2, "dalles71_clair", 10, 6)
	box(sx * T(0, 1.2, -0.25), Vector3(0.7, 1.1, 0.06), "dalles71_clair", 1.0)
	beam(sx * Vector3(0.3, 1.45, 0), sx * Vector3(0.45, 2.2, 0.1), 0.09, "dalles71_clair")
	beam(sx * Vector3(0.45, 2.15, 0.1), sx * Vector3(0.5, 3.3, 0.18), 0.06, "dalles71_clair")
	box(sx * T(0.47, 2.2, 0.1), Vector3(0.36, 0.06, 0.08), "dalles71_clair", 1.0)
	beam(sx * Vector3(-0.3, 1.45, 0), sx * Vector3(-0.5, 0.9, 0.2), 0.08, "dalles71_clair")
	return xf.origin


## Un puits (xf : le centre au sol) : la margelle, le toit de tuiles sur deux poteaux, le treuil.
func well71(xf: Transform3D) -> void:
	ring(xf, 0.75, 1.05, 0.85, "moellons71", 18)
	disc(xf * T(0, 0.2, 0), 0.75, "eau71", 14)
	col_cyl(xf.origin, 1.05, 0.9)
	for s in [-1.0, 1.0]:
		box(xf * T(s * 0.95, 1.3, 0), Vector3(0.14, 2.6, 0.14), "poutre71", 1.0)
	cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), xf * Vector3(0.95, 1.7, 0)), 0.1, 0.1, 1.9, "planches71", 8)
	roof_gable(xf * T(0, 2.6, 0), 2.4, 1.3, 40.0, 0.15, "tuiles71_rouge", "planches71")
	box(xf * T(0, 1.1, 0), Vector3(0.24, 0.28, 0.24), "planches71", 1.0)


## Un étal de marché (xf : le devant, +Z : les clients) : la table, quatre perches, une toile.
func stall71(xf: Transform3D, w: float = 2.6, d: float = 1.4, color: String = "rouge") -> void:
	box(xf * T(0, 0.85, -d * 0.5), Vector3(w, 0.08, d), "planches71", 1.0)
	box(xf * T(0, 0.45, -d * 0.5), Vector3(w - 0.1, 0.8, d - 0.1), "planches71_sombre", 1.0, 63 - 4 - 8)
	col_box(xf * T(0, 0.45, -d * 0.5), Vector3(w, 0.9, d))
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -d]:
			box(xf * T(sx * (w * 0.5 - 0.05), 1.15, sz), Vector3(0.07, 2.3, 0.07), "poutre71_clair", 1.0)
	var key: String = "tissu71_" + color
	var p0: Vector3 = xf * Vector3(-w * 0.5 - 0.2, 2.3, 0.35)
	var p1: Vector3 = xf * Vector3(w * 0.5 + 0.2, 2.3, 0.35)
	var p2: Vector3 = xf * Vector3(w * 0.5 + 0.2, 2.55, -d - 0.2)
	var p3: Vector3 = xf * Vector3(-w * 0.5 - 0.2, 2.55, -d - 0.2)
	var nn: Vector3 = (xf.basis * Vector3(0, 1, 0.15)).normalized()
	quad4(key, p0, p1, p2, p3, nn, Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1))
	quad4(key, p3, p2, p1, p0, -nn, Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1))
	# des marchandises : des paniers, des cagettes, des choses rondes et colorées
	for k in range(4):
		var x: float = -w * 0.5 + 0.4 + k * (w - 0.8) / 3.0
		box(xf * T(x, 0.97, -d * 0.45), Vector3(0.5, 0.16, 0.38), "planches71_clair", 1.0)
		for j in range(4):
			ball(xf * T(x - 0.15 + (j % 2) * 0.3, 1.1, -d * 0.45 - 0.08 + (j / 2) * 0.16), 0.07, ["fleur71_rouge", "fleur71_jaune", "feuille71", "fleur71_violet"][(k + j) % 4], 6, 3)


## Le tableau des quêtes de la Guilde (xf : le milieu du bas, +Z : face au lecteur) : le cadre de
## chêne, le liège, les affiches punaisées. Renvoie le point du lecteur.
func quest_board71(xf: Transform3D, w: float = 3.2, h: float = 2.0) -> Vector3:
	var bx: Transform3D = xf * T(0, 0.9 + h * 0.5, 0)
	box(bx * T(0, 0, -0.05), Vector3(w + 0.24, h + 0.24, 0.1), "poutre71", 1.0)
	quadz(bx * T(0, 0, 0.005), w, h, "liege71")
	var ids := ["quete_1", "quete_2", "recherche", "quete_3", "quete_4", "quete_5", "quete_6"]
	for k in range(ids.size()):
		var col: int = k % 4
		var row: int = k / 4
		var px: float = -w * 0.5 + 0.45 + col * (w - 0.9) / 3.0 + rng.randf_range(-0.08, 0.08)
		var py: float = h * 0.5 - 0.5 - row * 0.95 + rng.randf_range(-0.06, 0.06)
		var aw: float = 0.62 if ids[k] != "recherche" else 0.8
		quadz(bx * Transform3D(Basis(Vector3.BACK, rng.randf_range(-0.08, 0.08)), Vector3(px, py, 0.012 + k * 0.001)), aw, aw * 1.3, "affiche71_" + ids[k])
		ball(bx * T(px, py + aw * 0.6, 0.03), 0.025, "fleur71_rouge", 4, 2)
	col_box(xf * T(0, 0.9 + h * 0.5, -0.05), Vector3(w + 0.24, h + 0.24, 0.12))
	return xf * Vector3(0, 0, 1.3)


## Un moulin à vent de pierre (xf : le centre au sol, +Z : le côté des ailes) ; renvoie les ailes.
func windmill71(xf: Transform3D) -> Node3D:
	cyl(xf * T(0, -0.6, 0), 3.4, 2.9, 0.8, "moellons71_sombre", 16, false)
	cyl(xf * T(0, 0.2, 0), 2.9, 2.2, 9.0, "moellons71", 16, false, 2.4)
	col_cyl(xf.origin, 3.0, 9.4)
	cyl(xf * T(0, 9.2, 0), 2.5, 0.2, 3.4, "chaume71", 16, false, 1.8)
	door71(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0.2, -2.88)))
	for k in range(3):
		var a: float = TAU * (k + 0.5) / 3.0
		var out := Vector3(cos(a), 0, sin(a))
		window71(Transform3D(Basis.looking_at(-out, Vector3.UP), xf * Vector3(out.x * 2.45, 4.5 + k * 1.5, out.z * 2.45)), "", false, true)
	var hub := Node3D.new()
	hub.name = "Ailes_moulin"
	root.add_child(hub)
	hub.transform = xf * T(0, 8.7, 2.7)
	var mi := MeshInstance3D.new()
	var saved: Dictionary = batch
	batch = {}
	cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.9)), 0.25, 0.25, 1.2, "poutre71", 10)
	for k2 in range(4):
		var b := Basis(Vector3.BACK, TAU * k2 / 4.0)
		box(Transform3D(b, b * Vector3(0, 4.4, 0)), Vector3(0.2, 8.8, 0.2), "poutre71", 1.0)
		box(Transform3D(b, b * Vector3(0.75, 5.0, -0.05)), Vector3(1.3, 7.0, 0.04), "tissu71_blanc", 1.0)
		for j in range(8):
			box(Transform3D(b, b * Vector3(0.75, 1.8 + j * 0.9, 0)), Vector3(1.4, 0.05, 0.06), "poutre71_clair", 1.0)
	var mesh := ArrayMesh.new()
	for key in batch:
		var st: SurfaceTool = batch[key]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat(str(key)))
	batch = saved
	mi.mesh = mesh
	hub.add_child(mi)
	sails.append(hub)
	return hub


## Une charrette à foin (xf : le centre au sol, elle regarde +Z).
func cart71(xf: Transform3D, hay: bool = true) -> void:
	box(xf * T(0, 0.85, 0), Vector3(1.5, 0.1, 2.6), "planches71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * 0.74, 1.1, 0), Vector3(0.06, 0.45, 2.6), "planches71", 1.0)
		cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), xf * Vector3(s * 0.95, 0.55, -0.4)), 0.55, 0.55, 0.1, "planches71_sombre", 14)
		beam(xf * Vector3(s * 0.4, 0.8, 1.3), xf * Vector3(s * 0.3, 0.35, 2.8), 0.08, "poutre71")
	if hay:
		box(xf * T(0, 1.35, -0.1), Vector3(1.4, 0.7, 2.3), "chaume71", 1.0)
	col_box(xf * T(0, 0.8, 0), Vector3(1.8, 1.6, 2.8))


## Une meule de foin.
func haystack71(pos: Vector3, r: float = 1.6) -> void:
	cyl(Transform3D(Basis(), pos), r, r * 0.9, r * 1.2, "chaume71", 12, false, 1.4)
	cyl(Transform3D(Basis(), pos + Vector3.UP * r * 1.2), r * 0.9, 0.0, r * 0.9, "chaume71", 12, false, 1.4)
	col_cyl(pos, r, r * 2.0)


## Une clôture de bois (de a à b, au sol).
func fence71(a: Vector3, b: Vector3, h: float = 1.1) -> void:
	var len: float = a.distance_to(b)
	var n: int = maxi(int(len / 2.2), 1)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		box(Transform3D(Basis(), p + Vector3.UP * h * 0.5), Vector3(0.12, h, 0.12), "poutre71_clair", 1.0)
	for y in [h * 0.45, h * 0.85]:
		beam(a + Vector3.UP * y, b + Vector3.UP * y, 0.07, "planches71")
	var d: Vector3 = b - a
	col_box(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), (a + b) * 0.5 + Vector3.UP * h * 0.5), Vector3(0.15, h, len))


## Un banc de bois (xf : le milieu, on s'assoit face à +Z).
func bench71(xf: Transform3D) -> void:
	box(xf * T(0, 0.45, 0), Vector3(1.8, 0.07, 0.45), "planches71", 1.0)
	box(xf * T(0, 0.8, -0.22), Vector3(1.8, 0.4, 0.06), "planches71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * 0.75, 0.22, 0), Vector3(0.08, 0.45, 0.42), "fer71", 1.0)
	col_box(xf * T(0, 0.45, 0), Vector3(1.8, 0.9, 0.5))


## Un tonneau, une caisse (pour le décor).
func barrel71(pos: Vector3, yaw: float = 0.0) -> void:
	cyl(Transform3D(Basis(Vector3.UP, yaw), pos), 0.36, 0.42, 0.45, "planches71", 10)
	cyl(Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * 0.45), 0.42, 0.36, 0.45, "planches71", 10)
	for y in [0.12, 0.45, 0.78]:
		cyl(Transform3D(Basis(), pos + Vector3.UP * y), 0.425, 0.425, 0.05, "fer71", 10, false)
	col_cyl(pos, 0.42, 0.9)


func crate71(pos: Vector3, yaw: float = 0.0, s: float = 0.7) -> void:
	box(Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * s * 0.5), Vector3.ONE * s, "planches71_clair", 0.8)
	col_box(Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * s * 0.5), Vector3.ONE * s)


# =================================================================== les salles où l'on entre

## Une grande salle (la Guilde, l'auberge, le temple, la salle du trône, la chaumière…).
## xf : le milieu de la façade au sol, la façade regarde +Z, la salle s'étend vers -Z sur d.
## opts : h (hauteur des murs), t (épaisseur), wall (dehors), inner (dedans), floor_key, door_w,
## door_h, door_x, roof (tuiles71_…, chaume71 ; "" : pas de toit), pitch, gable_front (le pignon
## sur la façade), windows (des fenêtres sur les côtés), front_windows (abscisses), side_doors
## ([gauche, droite] : position z ou null), back_door, lights, energy, light_color, ceiling,
## timber (des poteaux et une lisse de bois sur les murs du dehors), base (le soubassement).
## Renvoie {door (devant la porte, dehors), inside (le milieu de la salle), top}.
func hall71(xf: Transform3D, w: float, d: float, opts: Dictionary = {}) -> Dictionary:
	var h: float = float(opts.get("h", 5.0))
	var t: float = float(opts.get("t", 0.6))
	var wall: String = str(opts.get("wall", "enduit71_creme"))
	var inner: String = str(opts.get("inner", "enduit71_blanc"))
	var floor_k: String = str(opts.get("floor_key", "planches71"))
	var dw: float = float(opts.get("door_w", 1.8))
	var dh: float = float(opts.get("door_h", 2.8))
	var dx: float = float(opts.get("door_x", 0.0))
	var base: String = str(opts.get("base", "moellons71_sombre"))
	# le sol, le soubassement, la collision du sol
	box(xf * T(0, 0.05, -d * 0.5), Vector3(w - t, 0.1, d - t), floor_k, 2.0, 4)
	box(xf * T(0, -0.45, -d * 0.5), Vector3(w + 0.2, 0.9, d + 0.2), base, 2.0, 63 - 4)
	col_box(xf * T(0, -0.2, -d * 0.5), Vector3(w, 0.5, d))
	# les murs, percés de leurs portes
	var walls := [
		[Transform3D(Basis(), Vector3(0, 0, -t * 0.5)), w, [[dx, dw, dh]]],
		[Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d + t * 0.5)), w, [[0.0, dw, dh]] if bool(opts.get("back_door", false)) else []],
	]
	var sd: Array = opts.get("side_doors", [null, null])
	for s in [-1.0, 1.0]:
		var zpos: Variant = sd[0] if s < 0 else sd[1]
		var gaps: Array = []
		if zpos != null:
			gaps.append([(float(zpos) + d * 0.5) * (-s), 1.6, 2.6])
		walls.append([Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * (w * 0.5 - t * 0.5), 0, -d * 0.5)), d - t * 2.0, gaps])
	for wd in walls:
		var wx: Transform3D = xf * (wd[0] as Transform3D)
		var len: float = float(wd[1])
		var cur: float = -len * 0.5
		var gaps2: Array = (wd[2] as Array).duplicate()
		gaps2.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
		for g in gaps2:
			var g0: float = float(g[0]) - float(g[1]) * 0.5
			var g1: float = float(g[0]) + float(g[1]) * 0.5
			_wall_piece(wx, cur, g0, 0.0, h, t, wall, inner)
			_wall_piece(wx, g0, g1, float(g[2]), h, t, wall, inner)
			# l'encadrement de la baie
			for gx in [g0, g1]:
				box(wx * T(gx, float(g[2]) * 0.5, t * 0.5 + 0.03), Vector3(0.22, float(g[2]), 0.12), "poutre71", 1.0)
			box(wx * T(float(g[0]), float(g[2]) + 0.12, t * 0.5 + 0.03), Vector3(float(g[1]) + 0.44, 0.26, 0.14), "poutre71", 1.0)
			cur = g1
		_wall_piece(wx, cur, len * 0.5, 0.0, h, t, wall, inner)
	# la porte principale : un battant ouvert, le seuil
	var fx: Transform3D = xf * T(dx, 0, 0.0)
	box(fx * Transform3D(Basis(Vector3.UP, 1.4), Vector3(-dw * 0.5 + 0.06, dh * 0.5, -t - 0.45)), Vector3(dw * 0.95, dh, 0.07), "planches71_sombre", 1.0)
	box(fx * T(0, 0.06, 0.45), Vector3(dw + 0.8, 0.12, 0.9), "dalles71", 1.0, 63 - 8)
	# les pans de bois du dehors : des poteaux d'angle, une lisse
	if bool(opts.get("timber", true)):
		for c in [[-1.0, 0.0], [1.0, 0.0], [-1.0, -d], [1.0, -d]]:
			box(xf * T(float(c[0]) * (w * 0.5 + 0.02), h * 0.5, float(c[1]) + (0.02 if float(c[1]) == 0.0 else -0.02)), Vector3(0.24, h, 0.24), "poutre71", 1.0)
		box(xf * T(0, h - 0.12, 0.05), Vector3(w + 0.1, 0.24, 0.12), "poutre71", 1.0)
		box(xf * T(0, h - 0.12, -d - 0.05), Vector3(w + 0.1, 0.24, 0.12), "poutre71", 1.0)
		for s5 in [-1.0, 1.0]:
			box(xf * T(s5 * (w * 0.5 + 0.05), h - 0.12, -d * 0.5), Vector3(0.12, 0.24, d + 0.1), "poutre71", 1.0)
	# les fenêtres : sur les côtés et en façade ; dedans, la même lumière
	var vol: String = str(opts.get("volet", ""))
	var wy: float = minf(h * 0.45, 2.2)
	if bool(opts.get("windows", true)):
		var nwin: int = maxi(1, int((d - 3.0) / 3.2))
		for s3 in [-1.0, 1.0]:
			for k in range(nwin):
				var wz: float = -d * 0.5 + (float(k) - (nwin - 1) * 0.5) * (d - 3.0) / nwin
				var zp: Variant = sd[0 if s3 < 0 else 1]
				if zp != null and absf(float(zp) - wz) < 2.2:
					continue
				window71(xf * Transform3D(Basis(Vector3.UP, s3 * PI * 0.5), Vector3(s3 * w * 0.5, wy, wz)), vol, true)
				quadz(xf * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * (w * 0.5 - t - 0.01), wy, wz)), 0.86, 1.3, "vitre71_on")
	for fwx in opts.get("front_windows", []):
		window71(xf * T(float(fwx), wy, 0.0), vol, true)
		quadz(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(float(fwx), wy, -t - 0.01)), 0.86, 1.3, "vitre71_on")
	# le plafond à poutres, le toit
	if bool(opts.get("ceiling", true)):
		box(xf * T(0, h - 0.1, -d * 0.5), Vector3(w - t, 0.2, d - t), inner, 2.4, 8)
		for k3 in range(int((d - 1.0) / 2.0)):
			box(xf * T(0, h - 0.4, -1.1 - k3 * 2.0), Vector3(w - t * 2.0, 0.36, 0.3), "poutre71", 1.5, 63 - 4)
	box(xf * T(0, h + 0.1, -d * 0.5), Vector3(w + 0.3, 0.26, d + 0.3), "poutre71", 1.6)
	var roof: String = str(opts.get("roof", "tuiles71_rouge"))
	var rise: float = 0.0
	if roof != "":
		if bool(opts.get("gable_front", true)):
			rise = roof_gable(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, h + 0.2, -d * 0.5)), d, w, float(opts.get("pitch", 48.0)), 0.5, roof, wall)
		else:
			rise = roof_gable(xf * T(0, h + 0.2, -d * 0.5), w, d, float(opts.get("pitch", 48.0)), 0.5, roof, wall)
	# les lustres
	var nl: int = int(opts.get("lights", 2))
	for k4 in range(nl):
		var lz: float = -d * (0.5 if nl == 1 else (0.22 + 0.56 * float(k4) / float(nl - 1)))
		chandelier(xf * Vector3(0, h - 1.4, lz), 1.0, opts.get("light_color", Color(1.0, 0.72, 0.42)), float(opts.get("energy", 1.6)), maxf(w, d) * 0.75)
	return {"door": xf * Vector3(dx, 0, 1.4), "inside": xf * Vector3(0, 0, -d * 0.5), "top": h, "rise": rise}


## Une table de taverne et ses deux bancs (xf : le milieu, la table le long de X) ; renvoie les
## deux places assises (devant et derrière).
func tavern_table71(xf: Transform3D, w: float = 2.2) -> Array:
	box(xf * T(0, 0.76, 0), Vector3(w, 0.08, 0.9), "planches71", 1.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.25), 0.37, 0), Vector3(0.12, 0.74, 0.7), "planches71_sombre", 1.0)
		box(xf * T(0, 0.45, s * 0.85), Vector3(w, 0.07, 0.32), "planches71", 1.0)
		for s2 in [-1.0, 1.0]:
			box(xf * T(s2 * (w * 0.5 - 0.2), 0.22, s * 0.85), Vector3(0.08, 0.44, 0.28), "planches71_sombre", 1.0)
	col_box(xf * T(0, 0.5, 0), Vector3(w, 1.0, 2.2))
	# des chopes, une miche de pain
	for k in range(3):
		cyl(xf * T(-w * 0.3 + k * w * 0.3, 0.8, (0.2 if k % 2 == 0 else -0.2)), 0.05, 0.05, 0.14, "planches71_clair", 8)
	ball(xf * T(0.1, 0.84, 0.0), 0.12, "planches71_clair", 8, 4)
	return [xf * Vector3(-w * 0.2, 0.0, 0.95), xf * Vector3(w * 0.2, 0.0, -0.95)]


## Un comptoir (xf : le devant, côté clients, +Z), long de w ; renvoie la place du tenancier.
func counter71(xf: Transform3D, w: float = 3.0, top_key: String = "planches71") -> Vector3:
	box(xf * T(0, 0.55, -0.35), Vector3(w, 1.1, 0.7), "planches71_sombre", 1.0, 63 - 8)
	box(xf * T(0, 1.13, -0.35), Vector3(w + 0.1, 0.07, 0.8), top_key, 1.0)
	col_box(xf * T(0, 0.55, -0.35), Vector3(w, 1.1, 0.7))
	return xf * Vector3(0, 0.0, -1.3)

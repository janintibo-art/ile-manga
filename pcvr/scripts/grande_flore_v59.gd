extends "res://scripts/azur_flore_v56.gd"
## V59 : la végétation de la grande île, région par région (mêmes outils que Port-Azur :
## maillages fabriqués ici, instanciés par espèce dans des MultiMesh).
##  - l'ouest (la côte des prairies) : herbe rase, fleurs, buissons, quelques pins tordus
##    par le vent, le verger de pommiers de Carène derrière la plage ;
##  - le nord (les hautes terres) : épicéas sombres en bosquets, bruyère, gros blocs gris ;
##  - l'est (la forêt des brumes) : grands feuillus serrés, fougères arborescentes, fougères,
##    roseaux autour des mares, rochers couverts de mousse ;
##  - le sud (le désert) : agaves, cactus-cierges, arbres morts blanchis, touffes sèches,
##    blocs de roche rouge.

const Rocks = preload("res://scripts/rocks_v26.gd")

var epave: Node3D
var region_counts: Dictionary = {}


## Un épicéa : un fût droit, des étages de branches tombantes, une flèche au sommet.
func fir_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5910 + variant
	var bark := _st()
	var leaves := _st()
	var h: float = rng.randf_range(11.0, 16.0)
	Flora._tube(bark, [Vector3.ZERO, Vector3.UP * h * 0.5, Vector3.UP * h] as Array[Vector3], [0.32, 0.2, 0.04] as Array[float], [0.0, 0.04, 0.12] as Array[float], 7)
	var tiers: int = 14
	for k in range(tiers):
		var t: float = float(k) / tiers
		var y: float = h * (0.16 + 0.82 * t)
		var rr: float = (1.0 - t) * h * 0.28 + 0.35
		var n: int = int(lerpf(11.0, 4.0, t))
		for c in range(n):
			var a: float = TAU * c / n + rng.randf_range(-0.3, 0.3) + k * 0.7
			var r2: float = rr * rng.randf_range(0.55, 1.0)
			var p := Vector3(cos(a) * r2, y - r2 * 0.32, sin(a) * r2)
			var b := Basis(Vector3.UP, -a + PI * 0.5)
			b = b.rotated(b.x, -0.55 - rng.randf_range(0.0, 0.35))
			Flora._card(leaves, p, rng.randf_range(1.5, 2.3) * (0.7 + 0.5 * (1.0 - t)), b, Vector3(0, y, 0), rr + 0.3, 0.2 + 0.6 * t)
	return _finish([[bark, _bark("ecorce_pin", "ecorce_pin.png", "ecorce_pin_n.png")], [leaves, _foliage("epicea", "feuille_cypres.png", 0.06, 0.3, Color(0.6, 0.78, 0.66))]])


## Un arbre mort du désert : tronc blanchi, branches nues et tordues.
func dead_tree_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5920 + variant
	var bark := _st()
	var h: float = rng.randf_range(3.5, 5.5)
	var lean := Vector3(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8))
	var trunk: Array[Vector3] = [Vector3.ZERO, Vector3.UP * h * 0.4 + lean * 0.2, Vector3.UP * h * 0.75 + lean * 0.6, Vector3.UP * h + lean]
	Flora._tube(bark, trunk, [0.24, 0.17, 0.11, 0.05] as Array[float], [0.0, 0.0, 0.0, 0.0] as Array[float], 7)
	for b in range(6):
		var a: float = rng.randf() * TAU
		var start: Vector3 = trunk[1 + b % 3]
		var dir := Vector3(cos(a), rng.randf_range(0.2, 0.9), sin(a)).normalized()
		var path: Array[Vector3] = [start]
		for s in range(1, 4):
			dir = (dir + Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.1, 0.3), rng.randf_range(-0.4, 0.4))).normalized()
			path.append(path[s - 1] + dir * rng.randf_range(0.5, 0.9))
		Flora._tube(bark, path, [0.08, 0.05, 0.03, 0.01] as Array[float], [0.0, 0.0, 0.0, 0.0] as Array[float], 5)
	return _finish([[bark, _plain("bois_mort", Color(0.62, 0.58, 0.52), Color(0.82, 0.78, 0.7), 0.0)]])


## Un cactus-cierge : une colonne côtelée et deux ou trois bras relevés.
func cactus_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5930 + variant
	var st := _st()
	var h: float = rng.randf_range(3.0, 5.2)
	var col: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	for i in range(9):
		var t: float = float(i) / 8.0
		col.append(Vector3.UP * h * t)
		radii.append(0.32 * (1.0 - pow(t, 6.0) * 0.6))
		flex.append(0.0)
	Flora._tube(st, col, radii, flex, 12)
	for a in range(2 + variant % 2):
		var ang: float = rng.randf() * TAU
		var y0: float = h * rng.randf_range(0.3, 0.55)
		var out := Vector3(cos(ang), 0, sin(ang))
		var arm: Array[Vector3] = [Vector3(0, y0, 0), Vector3(0, y0, 0) + out * 0.7 + Vector3.UP * 0.1, Vector3(0, y0, 0) + out * 0.85 + Vector3.UP * 0.6,
			Vector3(0, y0, 0) + out * 0.85 + Vector3.UP * rng.randf_range(1.4, 2.2)]
		Flora._tube(st, arm, [0.2, 0.2, 0.2, 0.12] as Array[float], [0.0, 0.0, 0.0, 0.0] as Array[float], 10)
	return _finish([[st, _plain("cactus", Color(0.2, 0.34, 0.2), Color(0.42, 0.52, 0.3), 0.0)]])


func heather_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(18, 0.38, 0.06, 59).duplicate()
	m.surface_set_material(0, _plain("bruyere", Color(0.28, 0.24, 0.16), Color(0.66, 0.36, 0.6), 0.06))
	return m


func meadow_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(13, 0.5, 0.045, 61).duplicate()
	m.surface_set_material(0, _plain("herbe_prairie", Color(0.16, 0.26, 0.08), Color(0.55, 0.62, 0.3), 0.14))
	return m


## Un point au hasard sur l'île (hors de Carène, de la porte, des mares), dans la région voulue.
func _island_point(want: String, min_h: float, max_slope: float) -> Vector3:
	for attempt in range(30):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * 330.0
		var x: float = ile.CENTER.x + cos(a) * r
		var z: float = ile.CENTER.z + sin(a) * r
		if not ile.contains(x, z):
			continue
		if want != "" and ile.region_name(x, z) != want:
			continue
		var w := Vector3(x, ile.height(x, z), z)
		if epave != null and (epave.footprint(x, z, 16.0) or _near_carene(x, z)):
			continue
		if ile.in_pond(x, z):
			continue
		if Vector2(x - ile.door_pos.x, z - ile.door_pos.z).length() < 26.0:
			continue
		if _ok_spot(w, max_slope, min_h):
			return w
	return Vector3.INF


func _near_carene(x: float, z: float) -> bool:
	var l: Vector3 = epave.Lc(Vector3(x, 0.0, z))
	return l.x > -70.0 and l.x < 80.0 and l.z > -66.0 and l.z < 30.0


func _rock_mm(label: String, tint: Color, moss: float, xfs: Array, seeds: int, size: Vector3, collide: bool) -> void:
	if xfs.is_empty():
		return
	var mat_r: Material = Rocks.material(tint, moss, 0.22)
	var per: int = int(ceil(float(xfs.size()) / seeds))
	var body := StaticBody3D.new()
	body.name = "Rochers_" + label
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for v in range(seeds):
		var part: Array = xfs.slice(v * per, mini((v + 1) * per, xfs.size()))
		if part.is_empty():
			continue
		var mesh: ArrayMesh = Rocks.shape(5940 + v * 7 + label.length(), size, 0.65, 0.18)
		mesh.surface_set_material(0, mat_r)
		_emit(label + "_%d" % v, mesh, part, 700.0)
		if collide:
			for xf in part:
				body.add_child(Rocks.collision_for(mesh, xf))


func build_island(island: Node3D, wreck: Node3D, high_quality: bool) -> void:
	ile = island
	epave = wreck
	_rng.seed = 5900
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	var lists := {
		"pin": [[], []], "maquis": [[], []], "pommier": [[], []], "prairie": [[]], "fleurs": [[]],
		"epicea": [[], [], []], "bruyere": [[]],
		"feuillu": [[], [], []], "fougere_arbre": [[], []], "fougere": [[]], "roseau": [[]],
		"agave": [[], []], "cactus": [[], []], "mort": [[], []], "seche": [[]],
	}
	var rocks := {"gris": [], "rouge": [], "mousse": [], "clair": []}
	# l'ouest : la prairie
	for i in range(int(70 * q)):
		var p: Vector3 = _island_point("ouest", 2.0, 0.5)
		if p != Vector3.INF:
			lists["pin"][i % 2].append(_xf(p, _rng.randf_range(0.7, 1.0)))
	for i in range(int(260 * q)):
		var p2: Vector3 = _island_point("ouest", 1.6, 0.6)
		if p2 != Vector3.INF:
			lists["maquis"][i % 2].append(_xf(p2, _rng.randf_range(0.7, 1.3), 0.15))
	for i in range(int(3200 * q)):
		var p3: Vector3 = _island_point("ouest", 1.4, 0.7)
		if p3 != Vector3.INF:
			lists["prairie"][0].append(_xf(p3, _rng.randf_range(0.8, 1.4), 0.02))
	for i in range(int(700 * q)):
		var p4: Vector3 = _island_point("ouest", 1.6, 0.6)
		if p4 != Vector3.INF:
			lists["fleurs"][0].append(_xf(p4, _rng.randf_range(0.8, 1.2), 0.02))
	# le verger de Carène : des pommiers en rangées, derrière la plage, au nord-est de l'épave
	if epave != null:
		for row in range(4):
			for col in range(7):
				var w: Vector3 = epave.W(Vector3(92.0 + col * 7.0 + _rng.randf_range(-1.0, 1.0), 0.0, -40.0 - row * 7.5 + _rng.randf_range(-1.0, 1.0)))
				w.y = ile.height(w.x, w.z)
				if _ok_spot(w, 0.4, 1.8):
					lists["pommier"][(row + col) % 2].append(_xf(w, _rng.randf_range(0.85, 1.1)))
	# le nord : épicéas en bosquets, bruyère, blocs
	for i in range(int(140 * q)):
		var c: Vector3 = _island_point("nord", 3.0, 0.75)
		if c == Vector3.INF:
			continue
		for k in range(_rng.randi_range(2, 5)):
			var w2 := c + Vector3(_rng.randf_range(-9.0, 9.0), 0, _rng.randf_range(-9.0, 9.0))
			w2.y = ile.height(w2.x, w2.z)
			if _ok_spot(w2, 0.8, 3.0) and w2.y < 62.0:
				lists["epicea"][(i + k) % 3].append(_xf(w2, _rng.randf_range(0.7, 1.2)))
	for i in range(int(2600 * q)):
		var p5: Vector3 = _island_point("nord", 2.0, 0.8)
		if p5 != Vector3.INF and p5.y < 58.0:
			lists["bruyere"][0].append(_xf(p5, _rng.randf_range(0.8, 1.6), 0.02))
	for i in range(int(130 * q)):
		var p6: Vector3 = _island_point("nord", 1.0, 1.5)
		if p6 != Vector3.INF:
			rocks["gris"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.4)), p6 - Vector3.UP * 0.4))
	# l'est : la forêt des brumes
	for i in range(int(520 * q)):
		var p7: Vector3 = _island_point("est", 1.8, 0.7)
		if p7 != Vector3.INF:
			lists["feuillu"][i % 3].append(_xf(p7, _rng.randf_range(0.8, 1.35)))
	for i in range(int(170 * q)):
		var p8: Vector3 = _island_point("est", 1.6, 0.6)
		if p8 != Vector3.INF:
			lists["fougere_arbre"][i % 2].append(_xf(p8, _rng.randf_range(0.8, 1.3)))
	for i in range(int(2200 * q)):
		var p9: Vector3 = _island_point("est", 1.2, 0.8)
		if p9 != Vector3.INF:
			lists["fougere"][0].append(_xf(p9, _rng.randf_range(0.8, 1.5), 0.03))
	for pd in ile.ponds_world:
		var pc: Vector3 = pd[0]
		var pr: float = float(pd[1])
		for k in range(int(26 * q)):
			var a: float = _rng.randf() * TAU
			var r: float = pr + _rng.randf_range(-0.8, 1.6)
			var w3 := Vector3(pc.x + cos(a) * r, 0, pc.z + sin(a) * r)
			w3.y = ile.height(w3.x, w3.z)
			lists["roseau"][0].append(_xf(w3, _rng.randf_range(0.8, 1.3), 0.05))
	for i in range(int(110 * q)):
		var p10: Vector3 = _island_point("est", 1.0, 1.2)
		if p10 != Vector3.INF:
			rocks["mousse"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.8)), p10 - Vector3.UP * 0.35))
	# le sud : le désert
	for i in range(int(170 * q)):
		var p11: Vector3 = _island_point("sud", 1.6, 0.6)
		if p11 != Vector3.INF:
			lists["agave"][i % 2].append(_xf(p11, _rng.randf_range(0.8, 1.5), 0.05))
	for i in range(int(95 * q)):
		var p12: Vector3 = _island_point("sud", 1.8, 0.45)
		if p12 != Vector3.INF:
			lists["cactus"][i % 2].append(_xf(p12, _rng.randf_range(0.8, 1.25), 0.05))
	for i in range(int(55 * q)):
		var p13: Vector3 = _island_point("sud", 1.8, 0.5)
		if p13 != Vector3.INF:
			lists["mort"][i % 2].append(_xf(p13, _rng.randf_range(0.8, 1.2)))
	for i in range(int(1500 * q)):
		var p14: Vector3 = _island_point("sud", 1.4, 0.7)
		if p14 != Vector3.INF:
			lists["seche"][0].append(_xf(p14, _rng.randf_range(0.7, 1.3), 0.02))
	for i in range(int(120 * q)):
		var p15: Vector3 = _island_point("sud", 1.0, 1.6)
		if p15 != Vector3.INF:
			rocks["rouge"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.2)), p15 - Vector3.UP * 0.4))
	# quelques rochers clairs sur la côte ouest et sur les pentes du massif
	for i in range(int(90 * q)):
		var p16: Vector3 = _island_point("", 1.0, 2.0)
		if p16 != Vector3.INF and (ile.region_name(p16.x, p16.z) == "ouest" or Vector2(p16.x - ile.CENTER.x, p16.z - ile.CENTER.z).length() < 160.0):
			rocks["clair"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.0)), p16 - Vector3.UP * 0.4))
	# les maillages
	for v in range(2):
		_emit("pin_tordu_%d" % v, pine_mesh(v + 4), lists["pin"][v], 700.0)
		_emit("maquis_%d" % v, shrub_mesh("maquis", v + 2), lists["maquis"][v], 220.0)
		_emit("pommier_%d" % v, Flora.tree(5950 + v, 5.5, 200), lists["pommier"][v], 420.0)
		_emit("fougere_arbre_%d" % v, _tree_fern(v), lists["fougere_arbre"][v], 260.0)
		_emit("agave_%d" % v, agave_mesh(v + 2), lists["agave"][v], 200.0)
		_emit("cactus_%d" % v, cactus_mesh(v), lists["cactus"][v], 420.0)
		_emit("arbre_mort_%d" % v, dead_tree_mesh(v), lists["mort"][v], 420.0)
	for v2 in range(3):
		_emit("epicea_%d" % v2, fir_mesh(v2), lists["epicea"][v2], 800.0)
		_emit("feuillu_%d" % v2, Flora.tree(5960 + v2, 12.0 + v2 * 2.0, 320), lists["feuillu"][v2], 700.0)
	_emit("prairie", meadow_mesh(), lists["prairie"][0], 75.0, false)
	_emit("fleurs", Flora.flower_clump(), lists["fleurs"][0], 70.0, false)
	_emit("bruyere", heather_mesh(), lists["bruyere"][0], 80.0, false)
	_emit("fougere", _ground("fougere"), lists["fougere"][0], 80.0, false)
	_emit("roseau", Flora.reed_clump(), lists["roseau"][0], 120.0, false)
	_emit("herbe_seche", grass_mesh(), lists["seche"][0], 75.0, false)
	_rock_mm("roc_gris", Color(0.58, 0.58, 0.6), 0.15, rocks["gris"], 3, Vector3(2.6, 1.8, 2.2), true)
	_rock_mm("roc_rouge", Color(0.72, 0.42, 0.3), 0.0, rocks["rouge"], 3, Vector3(2.4, 1.9, 2.1), true)
	_rock_mm("roc_mousse", Color(0.5, 0.52, 0.48), 0.85, rocks["mousse"], 2, Vector3(2.2, 1.4, 2.0), true)
	_rock_mm("roc_clair", Color(0.74, 0.72, 0.66), 0.25, rocks["clair"], 2, Vector3(2.4, 1.6, 2.0), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V59: végétation de la grande île ", placed, " en ", Time.get_ticks_msec() - t0, " ms")


func _tree_fern(v: int) -> ArrayMesh:
	if _jf == null:
		_jf = JungleFlora.new()
	return _jf.tree_fern_mesh(v)


func _ground(kind: String) -> Mesh:
	if _jf == null:
		_jf = JungleFlora.new()
	return _jf.ground_mesh(kind)

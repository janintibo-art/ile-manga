extends "res://scripts/grande_flore_v59.gd"
## V67 : la végétation d'Arcanelle (mêmes outils que les autres îles : maillages fabriqués ici,
## instanciés par espèce dans des MultiMesh).
##  - la lande : herbe rase, coussins de bruyère en fleurs, ajoncs jaunes, gros blocs de schiste ;
##  - les épicéas sombres en bosquets sur les pentes, quelques ifs noirs autour de l'Académie ;
##  - le Bois Tors, au sud-ouest : de vieux chênes tordus aux branches en spirale, des fougères,
##    de la mousse ;
##  - des roseaux autour du Lac Miroir, des simples dans les carrés du jardin.

var _ile_arc: Node3D


## Un chêne tordu : un tronc qui vrille, des branches en spirale, un feuillage sombre en touffes.
func gnarled_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6710 + variant
	var bark := _st()
	var leaves := _st()
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	var h: float = rng.randf_range(4.5, 6.5)
	var tw: float = rng.randf_range(1.5, 3.0) * (1.0 if variant % 2 == 0 else -1.0)
	for i in range(9):
		var t: float = float(i) / 8.0
		var r: float = 0.55 * sin(t * PI * 0.9) + 0.15
		trunk.append(Vector3(cos(t * tw * PI + variant) * r, t * h, sin(t * tw * PI + variant) * r))
		radii.append(lerpf(0.55, 0.2, t) * (1.25 if i == 0 else 1.0))
		flex.append(t * 0.04)
	Flora._tube(bark, trunk, radii, flex, 10)
	# des racines qui s'enfoncent
	for k in range(4):
		var a: float = TAU * k / 4.0 + rng.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		Flora._tube(bark, [Vector3.UP * 0.6 + d * 0.2, d * 0.9 + Vector3.UP * 0.15, d * 1.5 + Vector3.DOWN * 0.25] as Array[Vector3], [0.22, 0.12, 0.05] as Array[float], [0.0, 0.0, 0.0] as Array[float], 6)
	var tufts: Array = []
	for b in range(rng.randi_range(4, 6)):
		var a2: float = TAU * b / 5.0 + rng.randf_range(-0.5, 0.5)
		var start: Vector3 = trunk[4 + b % 4]
		var dir := Vector3(cos(a2), rng.randf_range(0.2, 0.7), sin(a2)).normalized()
		var path: Array[Vector3] = [start]
		for s in range(1, 6):
			var spin := Basis(Vector3.UP, 0.45 * (1.0 if b % 2 == 0 else -1.0))
			dir = (spin * dir + Vector3(0, rng.randf_range(-0.15, 0.25), 0)).normalized()
			path.append(path[s - 1] + dir * rng.randf_range(0.5, 0.85))
		Flora._tube(bark, path, [0.18, 0.13, 0.09, 0.06, 0.04, 0.02] as Array[float], [0.0, 0.1, 0.2, 0.3, 0.4, 0.5] as Array[float], 6)
		tufts.append(path[5])
		tufts.append(path[3])
	tufts.append(trunk[8] + Vector3.UP * 0.4)
	for tp in tufts:
		var c: Vector3 = tp
		var cr: float = rng.randf_range(0.9, 1.4)
		for k2 in range(16):
			var d2 := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.9), rng.randf_range(-1, 1)).normalized()
			var p: Vector3 = c + d2 * cr * rng.randf_range(0.3, 1.0)
			Flora._card(leaves, p, rng.randf_range(0.9, 1.3), Flora._random_basis(rng), c, cr, 0.35 + 0.4 * clampf((p.y - c.y + cr) / (2.0 * cr), 0.0, 1.0))
	return _finish([[bark, _bark("ecorce_tordu", "ecorce_platane.png", "ecorce_platane_n.png")], [leaves, _foliage("chene_tordu", "feuille_platane.png", 0.1, 0.35, Color(0.62, 0.78, 0.66))]])


## Un if : un cône sombre et serré (le cyprès de Port-Azur, plus bas, plus noir).
func yew_mesh(variant: int) -> ArrayMesh:
	var m: ArrayMesh = cypress_mesh(variant + 7)
	if m.get_surface_count() > 1:
		m.surface_set_material(1, _foliage("if", "feuille_cypres.png", 0.05, 0.25, Color(0.55, 0.7, 0.6)))
	return m


func gorse_mesh() -> ArrayMesh:
	var m: ArrayMesh = Flora.grass_clump(22, 0.62, 0.07, 67).duplicate()
	m.surface_set_material(0, _plain("ajonc", Color(0.18, 0.26, 0.1), Color(0.92, 0.78, 0.2), 0.05))
	return m


func herb_mesh() -> ArrayMesh:
	var m: ArrayMesh = Flora.grass_clump(16, 0.42, 0.05, 71).duplicate()
	m.surface_set_material(0, _plain("simples", Color(0.2, 0.34, 0.16), Color(0.62, 0.72, 0.5), 0.08))
	return m


func _arc_ok(w: Vector3, max_slope: float, min_h: float) -> bool:
	if _ile_arc.in_lake(w.x, w.z):
		return false
	return _ok_spot(w, max_slope, min_h)


## Un point au hasard sur Arcanelle (hors des lieux bâtis, des chemins, du lac).
func _arc_point(min_h: float, max_slope: float, center: Vector2 = Vector2.INF, radius: float = 0.0) -> Vector3:
	for attempt in range(30):
		var x: float
		var z: float
		if center != Vector2.INF:
			var a: float = _rng.randf() * TAU
			var r: float = sqrt(_rng.randf()) * radius
			x = _ile_arc.CENTER.x + center.x + cos(a) * r
			z = _ile_arc.CENTER.z + center.y + sin(a) * r
		else:
			x = _ile_arc.CENTER.x + _rng.randf_range(-118.0, 118.0)
			z = _ile_arc.CENTER.z + _rng.randf_range(-112.0, 112.0)
		var w := Vector3(x, _ile_arc.height(x, z), z)
		if _arc_ok(w, max_slope, min_h):
			return w
	return Vector3.INF


func build_arcanelle(island: Node3D, garden_beds: Array, high_quality: bool, big_trees: Array = []) -> void:
	_ile_arc = island
	ile = island
	_rng.seed = 6700
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	var lists := {"tordu": [[], [], []], "epicea": [[], []], "if": [[], []], "bruyere": [[]], "lande": [[]], "ajonc": [[]], "fougere": [[]], "roseau": [[]], "simples": [[]], "fleurs": [[]]}
	var rocks := {"schiste": [], "mousse": []}
	# le Bois Tors (et les grands chênes plantés exprès : un livre envolé y est coincé)
	for bt in big_trees:
		lists["tordu"][0].append(Transform3D(Basis(Vector3.UP, 0.7).scaled(Vector3.ONE * float(bt[1])), (bt[0] as Vector3) - Vector3.UP * 0.25))
	for i in range(int(70 * q)):
		var p: Vector3 = _arc_point(1.2, 0.7, Vector2(-62.0, 46.0), 28.0)
		if p != Vector3.INF:
			lists["tordu"][i % 3].append(_xf(p, _rng.randf_range(0.8, 1.3), 0.25))
	for i in range(int(500 * q)):
		var p2: Vector3 = _arc_point(1.0, 0.8, Vector2(-62.0, 46.0), 30.0)
		if p2 != Vector3.INF:
			lists["fougere"][0].append(_xf(p2, _rng.randf_range(0.8, 1.4), 0.03))
	for i in range(int(30 * q)):
		var p3: Vector3 = _arc_point(1.0, 1.3, Vector2(-62.0, 46.0), 28.0)
		if p3 != Vector3.INF:
			rocks["mousse"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), p3 - Vector3.UP * 0.35))
	# quelques chênes tordus ailleurs, seuls dans la lande
	for i in range(int(26 * q)):
		var p4: Vector3 = _arc_point(2.5, 0.6)
		if p4 != Vector3.INF:
			lists["tordu"][i % 3].append(_xf(p4, _rng.randf_range(0.7, 1.1), 0.25))
	# les épicéas, en bosquets sur les pentes du nord et de l'ouest
	for i in range(int(40 * q)):
		var c: Vector3 = _arc_point(5.0, 0.75)
		if c == Vector3.INF or c.z > _ile_arc.CENTER.z + 30.0:
			continue
		for k in range(_rng.randi_range(2, 4)):
			var w2 := c + Vector3(_rng.randf_range(-7.0, 7.0), 0, _rng.randf_range(-7.0, 7.0))
			w2.y = _ile_arc.height(w2.x, w2.z)
			if _arc_ok(w2, 0.8, 3.0):
				lists["epicea"][(i + k) % 2].append(_xf(w2, _rng.randf_range(0.6, 1.0)))
	# des ifs autour de l'Académie et du Cercle
	for cc in [Vector2(-10.0, -10.0), Vector2(-64.0, -4.0), Vector2(12.0, 12.0)]:
		for k2 in range(int(10 * q)):
			var a: float = _rng.randf() * TAU
			var r: float = _rng.randf_range(19.0, 26.0)
			var w3: Vector3 = Vector3(_ile_arc.CENTER.x + cc.x + cos(a) * r, 0, _ile_arc.CENTER.z + cc.y + sin(a) * r)
			w3.y = _ile_arc.height(w3.x, w3.z)
			if _arc_ok(w3, 0.7, 2.0):
				lists["if"][k2 % 2].append(_xf(w3, _rng.randf_range(0.55, 0.8)))
	# la lande : herbe rase, bruyère, ajoncs, fleurs
	for i in range(int(4200 * q)):
		var p5: Vector3 = _arc_point(1.4, 0.9)
		if p5 != Vector3.INF:
			lists["lande"][0].append(_xf(p5, _rng.randf_range(0.8, 1.4), 0.02))
	for i in range(int(3000 * q)):
		var p6: Vector3 = _arc_point(1.8, 0.9)
		if p6 != Vector3.INF:
			lists["bruyere"][0].append(_xf(p6, _rng.randf_range(0.8, 1.7), 0.02))
	for i in range(int(420 * q)):
		var p7: Vector3 = _arc_point(1.8, 0.7)
		if p7 != Vector3.INF:
			lists["ajonc"][0].append(_xf(p7, _rng.randf_range(0.8, 1.5), 0.04))
	for i in range(int(500 * q)):
		var p8: Vector3 = _arc_point(1.6, 0.6)
		if p8 != Vector3.INF:
			lists["fleurs"][0].append(_xf(p8, _rng.randf_range(0.8, 1.2), 0.02))
	# des blocs de schiste
	for i in range(int(140 * q)):
		var p9: Vector3 = _arc_point(0.6, 1.8)
		if p9 != Vector3.INF:
			rocks["schiste"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.6)), p9 - Vector3.UP * 0.4))
	# les roseaux du lac
	var lc: Vector3 = _ile_arc.W(_ile_arc.LAKE.x, _ile_arc.LAKE.y)
	for k3 in range(int(90 * q)):
		var a3: float = _rng.randf() * TAU
		var r3: float = _ile_arc.LAKE_R + _rng.randf_range(-0.6, 1.8)
		var w4 := Vector3(lc.x + cos(a3) * r3, 0, lc.z + sin(a3) * r3)
		w4.y = _ile_arc.height(w4.x, w4.z)
		if w4.distance_to(_ile_arc.W(33.0, -34.0, w4.y)) > 3.5:
			lists["roseau"][0].append(_xf(w4, _rng.randf_range(0.8, 1.3), 0.05))
	# les simples dans les carrés du jardin
	for bed in garden_beds:
		var bc: Vector3 = bed
		for k4 in range(int(14 * q) + 4):
			var w5: Vector3 = bc + Vector3(_rng.randf_range(-1.4, 1.4), 0.42, _rng.randf_range(-0.5, 0.5))
			lists["simples"][0].append(_xf(w5, _rng.randf_range(0.7, 1.2), 0.0))
	# les maillages
	for v in range(3):
		_emit("chene_tordu_%d" % v, gnarled_mesh(v), lists["tordu"][v], 620.0)
	for v2 in range(2):
		_emit("epicea_arc_%d" % v2, fir_mesh(v2 + 3), lists["epicea"][v2], 800.0)
		_emit("if_%d" % v2, yew_mesh(v2), lists["if"][v2], 600.0)
	_emit("lande", meadow_mesh(), lists["lande"][0], 75.0, false)
	_emit("bruyere_arc", heather_mesh(), lists["bruyere"][0], 85.0, false)
	_emit("ajonc", gorse_mesh(), lists["ajonc"][0], 110.0, false)
	_emit("fleurs_arc", Flora.flower_clump(), lists["fleurs"][0], 70.0, false)
	_emit("fougere_arc", _ground("fougere"), lists["fougere"][0], 80.0, false)
	_emit("roseau_arc", Flora.reed_clump(), lists["roseau"][0], 120.0, false)
	_emit("simples", herb_mesh(), lists["simples"][0], 70.0, false)
	_rock_mm("schiste_arc", Color(0.5, 0.54, 0.6), 0.2, rocks["schiste"], 3, Vector3(2.6, 1.6, 2.0), true)
	_rock_mm("roc_mousse_arc", Color(0.48, 0.5, 0.5), 0.9, rocks["mousse"], 2, Vector3(2.0, 1.3, 1.8), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V67: végétation d'Arcanelle ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

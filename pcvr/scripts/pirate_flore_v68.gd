extends "res://scripts/grande_flore_v59.gd"
## V68 : la végétation de l'Île de la Balafre (mêmes outils que les autres îles : maillages
## fabriqués ici ou empruntés à la jungle V29/V30, instanciés par espèce dans des MultiMesh).
##  - les grèves : des cocotiers penchés vers la mer, des touffes d'herbe dure ;
##  - la jungle : grands arbres de canopée (quelques géants aux contreforts), bananiers,
##    fougères arborescentes, arbustes, fougères, « oreilles d'éléphant », herbe ;
##  - le Marais des Noyés : des palétuviers sur leurs racines-échasses, des arbres morts, des
##    roseaux, de l'herbe de marais ;
##  - les pentes du Pic et les falaises : moins d'arbres, des blocs de basalte, de la mousse.

const R68 = preload("res://scripts/ile_pirate_v68.gd")

var _ile68: Node3D
var _trunk_body: StaticBody3D


## Un palétuvier : un tronc court porté par des racines-échasses arquées qui plongent dans la
## vase, une couronne dense de petites feuilles vert sombre.
func mangrove_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6880 + variant
	var bark := _st()
	var leaves := _st()
	var h: float = rng.randf_range(3.6, 5.2)
	var base := Vector3(0, 1.4, 0)
	var trunk: Array[Vector3] = [base, base + Vector3(0.1, h * 0.4, 0.05), base + Vector3(-0.15, h * 0.75, 0.1), base + Vector3(0.05, h, -0.1)]
	Flora._tube(bark, trunk, [0.2, 0.17, 0.13, 0.09] as Array[float], [0.0, 0.02, 0.05, 0.08] as Array[float], 8)
	# les racines-échasses
	var n: int = rng.randi_range(7, 10)
	for k in range(n):
		var a: float = TAU * k / n + rng.randf_range(-0.25, 0.25)
		var d := Vector3(cos(a), 0, sin(a))
		var r: float = rng.randf_range(1.2, 2.2)
		var top: Vector3 = base + Vector3.UP * rng.randf_range(0.2, 1.0)
		var mid: Vector3 = top + d * r * 0.5 + Vector3.UP * rng.randf_range(0.3, 0.6)
		var foot: Vector3 = d * r + Vector3.DOWN * 0.3
		Flora._tube(bark, [top, mid, foot] as Array[Vector3], [0.08, 0.06, 0.05] as Array[float], [0.0, 0.0, 0.0] as Array[float], 5)
	# des branches et la couronne
	var crown := base + Vector3(0, h * 0.95, 0)
	for b in range(5):
		var a2: float = TAU * b / 5.0 + rng.randf_range(-0.4, 0.4)
		var st: Vector3 = trunk[2]
		var tip: Vector3 = st + Vector3(cos(a2) * 1.6, rng.randf_range(0.6, 1.4), sin(a2) * 1.6)
		Flora._tube(bark, [st, (st + tip) * 0.5 + Vector3.UP * 0.2, tip] as Array[Vector3], [0.07, 0.05, 0.03] as Array[float], [0.05, 0.1, 0.2] as Array[float], 5)
		for k2 in range(9):
			var p: Vector3 = tip + Vector3(rng.randf_range(-1.1, 1.1), rng.randf_range(-0.5, 0.7), rng.randf_range(-1.1, 1.1))
			Flora._card(leaves, p, rng.randf_range(0.8, 1.2), Flora._random_basis(rng), crown, 2.4, 0.3 + 0.3 * clampf((p.y - crown.y + 1.5) / 3.0, 0.0, 1.0))
	return _finish([[bark, _bark("ecorce_paletuvier", "ecorce_platane.png", "ecorce_platane_n.png")], [leaves, _foliage("paletuvier", "feuille_laurier.png", 0.12, 0.35, Color(0.5, 0.66, 0.46))]])


func marsh_grass_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(18, 0.9, 0.06, 68).duplicate()
	m.surface_set_material(0, _plain("herbe_marais", Color(0.2, 0.22, 0.08), Color(0.56, 0.58, 0.26), 0.12))
	return m


func beach_grass_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(12, 0.6, 0.045, 69).duplicate()
	m.surface_set_material(0, _plain("herbe_dune", Color(0.4, 0.42, 0.2), Color(0.78, 0.74, 0.44), 0.12))
	return m


func _jungle(kind: String, v: int, detailed: bool = true) -> Mesh:
	if _jf == null:
		_jf = JungleFlora.new()
	match kind:
		"canopee":
			return _jf.canopy_tree_mesh(v, detailed)
		"geant":
			return _jf.giant_mesh(v, detailed)
		"palmier":
			return _jf.palm_mesh(v, detailed)
		"bananier", "oreille":
			return _jf.broadleaf_plant_mesh(kind, v)
	return _jf.ground_mesh(kind)


## Un point au hasard sur l'île (repère monde), hors du port, de la baie, des lieux bâtis.
func _b_point(min_h: float, max_slope: float, center: Vector2 = Vector2.INF, radius: float = 0.0, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		if center != Vector2.INF:
			var a: float = _rng.randf() * TAU
			l = center + Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * radius
		else:
			l = Vector2(_rng.randf_range(-205.0, 205.0), _rng.randf_range(-190.0, 182.0))
		if R68._rect_dist(l.x, l.y, R68.TOWN) < 4.0:
			continue
		if R68.bay_dist(l.x, l.y) < 3.0:
			continue
		if l.distance_to(R68.CIRQUE) < R68.CIRQUE_R + 1.0:
			continue
		var w: Vector3 = R68.W(l.x, l.y)
		w.y = _ile68.height(w.x, w.z)
		if _ok_spot(w, max_slope, min_h, max_h):
			return w
	return Vector3.INF


func _in_marsh(w: Vector3) -> bool:
	return R68.L(w.x, w.z).distance_to(R68.MARSH) < R68.MARSH_R + 4.0


func build_balafre(island: Node3D, high_quality: bool, town_palms: Array = []) -> void:
	_ile68 = island
	ile = island
	_rng.seed = 6800
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_balafre_v68"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var lists := {"canopee": [[], [], []], "geant": [[], []], "palmier": [[], [], []], "bananier": [[], []], "fougere_arbre": [[], []],
		"arbuste": [[]], "fougere": [[]], "oreille": [[]], "herbe": [[]], "paletuvier": [[], []], "mort": [[], []], "roseau": [[]],
		"herbe_marais": [[]], "herbe_dune": [[]]}
	var rocks := {"basalte": [], "mousse": []}
	# les cocotiers des grèves, penchés vers le large
	for i in range(int(460 * q)):
		var p: Vector3 = _b_point(0.0, 0.35, Vector2.INF, 0.0, 4.5)
		if p == Vector3.INF or _in_marsh(p):
			continue
		var l: Vector2 = R68.L(p.x, p.z)
		if island.coast_q(l.x, l.y) < 0.8:
			continue
		var out: float = atan2(l.y, l.x)
		var xf := Transform3D(Basis(Vector3.UP, -out + _rng.randf_range(-0.6, 0.6)).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.15)), p - Vector3.UP * 0.1)
		lists["palmier"][i % 3].append(xf)
		_trunk(p, 0.25, 3.0)
	for tp in town_palms:
		lists["palmier"][0].append(_xf(tp, _rng.randf_range(0.85, 1.05), 0.1))
		_trunk(tp, 0.25, 3.0)
	# la jungle : grands arbres, géants, palmiers épars
	for i in range(int(980 * q)):
		var p2: Vector3 = _b_point(2.2, 0.62, Vector2.INF, 0.0, 52.0)
		if p2 == Vector3.INF or _in_marsh(p2):
			continue
		lists["canopee"][i % 3].append(_xf(p2, _rng.randf_range(0.75, 1.2), 0.15))
		_trunk(p2, 0.45, 4.0)
	for i in range(int(46 * q)):
		var p3: Vector3 = _b_point(4.0, 0.4, Vector2.INF, 0.0, 40.0)
		if p3 == Vector3.INF or _in_marsh(p3) or R68.L(p3.x, p3.z).y > 60.0:
			continue
		lists["geant"][i % 2].append(_xf(p3, _rng.randf_range(0.8, 1.0), 0.2))
		_trunk(p3, 1.4, 6.0)
	for i in range(int(160 * q)):
		var p4: Vector3 = _b_point(2.0, 0.55, Vector2.INF, 0.0, 30.0)
		if p4 != Vector3.INF and not _in_marsh(p4):
			lists["palmier"][i % 3].append(_xf(p4, _rng.randf_range(0.7, 1.0), 0.1))
	# le sous-étage
	for i in range(int(620 * q)):
		var p5: Vector3 = _b_point(1.6, 0.7, Vector2.INF, 0.0, 45.0)
		if p5 != Vector3.INF and not _in_marsh(p5):
			lists["bananier"][i % 2].append(_xf(p5, _rng.randf_range(0.8, 1.2), 0.05))
	for i in range(int(300 * q)):
		var p6: Vector3 = _b_point(2.0, 0.8, Vector2.INF, 0.0, 60.0)
		if p6 != Vector3.INF and not _in_marsh(p6):
			lists["fougere_arbre"][i % 2].append(_xf(p6, _rng.randf_range(0.8, 1.3), 0.05))
	for i in range(int(800 * q)):
		var p7: Vector3 = _b_point(1.4, 0.8)
		if p7 != Vector3.INF and not _in_marsh(p7):
			lists["arbuste"][0].append(_xf(p7, _rng.randf_range(0.8, 1.5), 0.1))
	for i in range(int(2600 * q)):
		var p8: Vector3 = _b_point(1.2, 0.9)
		if p8 != Vector3.INF:
			lists["fougere"][0].append(_xf(p8, _rng.randf_range(0.8, 1.5), 0.03))
	for i in range(int(1500 * q)):
		var p9: Vector3 = _b_point(1.2, 0.8)
		if p9 != Vector3.INF and not _in_marsh(p9):
			lists["oreille"][0].append(_xf(p9, _rng.randf_range(0.8, 1.6), 0.03))
	for i in range(int(5200 * q)):
		var p10: Vector3 = _b_point(1.6, 0.9)
		if p10 != Vector3.INF and not _in_marsh(p10):
			lists["herbe"][0].append(_xf(p10, _rng.randf_range(0.8, 1.4), 0.02))
	for i in range(int(900 * q)):
		var p11: Vector3 = _b_point(0.1, 0.4, Vector2.INF, 0.0, 2.4)
		if p11 != Vector3.INF and not _in_marsh(p11):
			lists["herbe_dune"][0].append(_xf(p11, _rng.randf_range(0.8, 1.4), 0.02))
	# le marais : palétuviers, arbres morts, roseaux, herbe de marais
	for i in range(int(150 * q)):
		var pm: Vector3 = _b_point(-1.0, 0.6, R68.MARSH, R68.MARSH_R + 6.0)
		if pm != Vector3.INF:
			lists["paletuvier"][i % 2].append(_xf(pm, _rng.randf_range(0.8, 1.25), 0.4))
			_trunk(pm, 0.4, 3.0)
	for i in range(int(36 * q)):
		var pd: Vector3 = _b_point(-0.5, 0.6, R68.MARSH, R68.MARSH_R)
		if pd != Vector3.INF:
			lists["mort"][i % 2].append(_xf(pd, _rng.randf_range(0.7, 1.1), 0.3))
	for i in range(int(1100 * q)):
		var pr: Vector3 = _b_point(-0.3, 0.6, R68.MARSH, R68.MARSH_R + 8.0)
		if pr != Vector3.INF:
			lists["roseau" if i % 3 != 0 else "herbe_marais"][0].append(_xf(pr, _rng.randf_range(0.8, 1.5), 0.05))
	# des blocs de basalte (pentes du pic, ravin, falaises), des rochers moussus dans la jungle
	for i in range(int(200 * q)):
		var pb: Vector3 = _b_point(0.4, 2.0)
		if pb == Vector3.INF:
			continue
		var lb: Vector2 = R68.L(pb.x, pb.z)
		var steep: bool = R68.ravine(lb.x, lb.y).x < 24.0 or lb.distance_to(R68.PEAK) < 70.0 or lb.y < -130.0
		if steep or _rng.randf() < 0.25:
			rocks["basalte"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.8)), pb - Vector3.UP * 0.4))
	for i in range(int(70 * q)):
		var pmo: Vector3 = _b_point(2.0, 1.0)
		if pmo != Vector3.INF and not _in_marsh(pmo):
			rocks["mousse"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pmo - Vector3.UP * 0.35))
	# les maillages
	for v in range(3):
		_emit("canopee_bal_%d" % v, _jungle("canopee", v), lists["canopee"][v], 260.0)
		_emit("palmier_bal_%d" % v, _jungle("palmier", v), lists["palmier"][v], 320.0)
	for v2 in range(2):
		_emit("geant_bal_%d" % v2, _jungle("geant", v2), lists["geant"][v2], 520.0)
		_emit("bananier_bal_%d" % v2, _jungle("bananier", v2), lists["bananier"][v2], 110.0)
		_emit("fougere_arbre_bal_%d" % v2, _tree_fern(v2), lists["fougere_arbre"][v2], 110.0)
		_emit("paletuvier_%d" % v2, mangrove_mesh(v2), lists["paletuvier"][v2], 260.0)
		_emit("arbre_mort_bal_%d" % v2, dead_tree_mesh(v2 + 2), lists["mort"][v2], 260.0)
	_emit("arbuste_bal", _jungle("arbuste", 0), lists["arbuste"][0], 85.0)
	_emit("fougere_bal", _jungle("fougere", 0), lists["fougere"][0], 70.0, false)
	_emit("oreille_bal", _jungle("oreille", 0), lists["oreille"][0], 75.0, false)
	_emit("herbe_bal", _jungle("herbe", 0), lists["herbe"][0], 60.0, false)
	_emit("herbe_dune_bal", beach_grass_mesh(), lists["herbe_dune"][0], 70.0, false)
	_emit("roseau_bal", Flora.reed_clump(), lists["roseau"][0], 110.0, false)
	_emit("herbe_marais_bal", marsh_grass_mesh(), lists["herbe_marais"][0], 80.0, false)
	_rock_mm("basalte_bal", Color(0.3, 0.3, 0.31), 0.25, rocks["basalte"], 3, Vector3(2.4, 1.6, 2.0), true)
	_rock_mm("roc_mousse_bal", Color(0.42, 0.44, 0.4), 0.9, rocks["mousse"], 2, Vector3(2.0, 1.3, 1.8), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V68: végétation de la Balafre ", placed, " en ", Time.get_ticks_msec() - t0, " ms")


func _trunk(p: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	cs.shape = s
	cs.position = p + Vector3.UP * (h * 0.5 - 0.2)
	_trunk_body.add_child(cs)

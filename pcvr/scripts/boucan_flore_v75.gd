extends "res://scripts/montjoie_flore_v71.gd"
## V75 : la végétation de l'Île du Boucan (mêmes outils que les autres îles, instanciés par espèce
## dans des MultiMesh).
##  - le Bois des Spores (autour du Gazomètre) : des bouleaux, des saules, des aulnes, des
##    buddleias violets (l'arbre à papillons des friches), des fougères, des ronces ;
##  - la friche du sud : de l'herbe sèche en touffes, des chardons, des buddleias, quelques arbres
##    pionniers isolés, des blocs de béton cassés ;
##  - dans la ville : des herbes folles au pied des murs, l'arbre aux guirlandes de la place, les
##    arbres des Jardins Partagés.

const RB = preload("res://scripts/ile_boucan_v75.gd")

var _ileb: Node3D


func buddleia_mesh(variant: int) -> Mesh:
	var m: ArrayMesh = Flora.bush(7540 + variant).duplicate()
	return m


func thistle_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.62, 0.36, 0.78)))
	return m


func purple_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.55, 0.28, 0.72)))
	return m


func yellow_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.95, 0.82, 0.2)))
	return m


## Un point de l'île qui convient. want : "" (la friche, hors de la ville), "spores" (le bois
## autour du Gazomètre), "ville" (au pied des murs, dans la ville).
func _mpb(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"spores":
				var a: float = _rng.randf() * TAU
				l = RB.GAZO + Vector2(cos(a), sin(a)) * (RB.GAZO_R + 6.0 + sqrt(_rng.randf()) * (RB.SPORES_R - RB.GAZO_R - 6.0))
			"ville":
				l = Vector2(_rng.randf_range(RB.TOWN.position.x, RB.TOWN.end.x), _rng.randf_range(-150.0, RB.TOWN.end.y))
			_:
				l = Vector2(_rng.randf_range(-RB.HALF + 4.0, RB.HALF - 4.0), _rng.randf_range(-RB.HALF + 4.0, RB.HALF - 4.0))
		if absf(l.x) > RB.HALF - 2.0 or absf(l.y) > RB.HALF - 2.0:
			continue
		if want != "ville" and RB.in_town(l.x, l.y):
			continue
		if want != "spores" and l.distance_to(RB.GAZO) < RB.GAZO_R + 3.0:
			continue
		if _blocked.has(_cell(l)):
			continue
		var w3: Vector3 = RB.W(l.x, l.y)
		w3.y = _ileb.height(w3.x, w3.z)
		var b: Color = _ileb.biome_at(w3.x, w3.z)
		if want != "ville" and (b.r > 0.35 or b.a > 0.3 or b.g > 0.5):
			continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_b() -> void:
	for k in _ileb.paths_world:
		for p in _ileb.paths_world[k]:
			var l: Vector2 = RB.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


## Plante l'île. extra : « arbres » (Vector3 : les arbres plantés dans la ville), « herbes »
## (Vector3 : des pieds de murs où poussent des herbes folles).
func build_boucan(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ileb = island
	_ilem = island
	ile = island
	_rng.seed = 7500
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_b()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_boucan_v75"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"bouleau": [[], [], []], "saule": [[], []], "pionnier": [[], []], "buddleia": [[], []], "buisson": [[], []],
		"seche": [[]], "friche": [[]], "chardon": [[]], "violet": [[]], "jaune": [[]], "fougere": [[]], "ville": [[], []], "folle": [[]]}
	var rocks := {"beton": []}
	# ---------------------------------------------------------------- le Bois des Spores
	for i in range(int(340 * q)):
		var p: Vector3 = _mpb("spores", 0.8, 0.6, 40.0)
		if p == Vector3.INF:
			continue
		if i % 5 == 0:
			L["saule"][i % 2].append(_xfr(p, 0.8, 1.2, 0.12))
			_trunk(p, 0.45, 3.0)
		else:
			L["bouleau"][i % 3].append(_xfr(p, 0.75, 1.2, 0.1))
			_trunk(p, 0.3, 4.0)
	for i2 in range(int(220 * q)):
		var pb: Vector3 = _mpb("spores", 0.8, 0.7, 40.0)
		if pb != Vector3.INF:
			if i2 % 3 == 0:
				L["buddleia"][i2 % 2].append(_xfr(pb, 0.8, 1.3, 0.1))
			else:
				L["buisson"][i2 % 2].append(_xfr(pb, 0.8, 1.4, 0.1))
	for i3 in range(int(1500 * q)):
		var pf: Vector3 = _mpb("spores", 0.6, 0.9, 40.0)
		if pf != Vector3.INF:
			L["fougere"][0].append(_xfr(pf, 0.8, 1.5, 0.03))
	# ---------------------------------------------------------------- la friche : herbe sèche, chardons, buddleias, arbres pionniers
	for i4 in range(int(6500 * q)):
		var pg: Vector3 = _mpb("", 0.9, 0.8, 40.0)
		if pg == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.5:
			L["seche"][0].append(_xfr(pg, 0.8, 1.4, 0.02))
		elif r < 0.8:
			L["friche"][0].append(_xfr(pg, 0.8, 1.3, 0.02))
		elif r < 0.88:
			L["chardon"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
		elif r < 0.95:
			L["jaune"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
		else:
			L["violet"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
	for i5 in range(int(70 * q)):
		var pt: Vector3 = _mpb("", 1.5, 0.5, 30.0)
		if pt == Vector3.INF or RB.L(pt.x, pt.z).distance_to(RB.GAZO) < RB.SPORES_R:
			continue
		L["pionnier"][i5 % 2].append(_xfr(pt, 0.7, 1.1, 0.15))
		_trunk(pt, 0.4, 3.5)
	for i6 in range(int(240 * q)):
		var ps: Vector3 = _mpb("", 1.0, 0.6, 30.0)
		if ps != Vector3.INF:
			if i6 % 2 == 0:
				L["buddleia"][i6 % 2].append(_xfr(ps, 0.7, 1.2, 0.1))
			else:
				L["buisson"][i6 % 2].append(_xfr(ps, 0.7, 1.2, 0.1))
	for i7 in range(int(90 * q)):
		var pr: Vector3 = _mpb("", 1.0, 1.0, 30.0)
		if pr != Vector3.INF:
			rocks["beton"].append(Transform3D(Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.4, 1.1)), pr - Vector3.UP * 0.2))
	# ---------------------------------------------------------------- dans la ville
	for tp in extra.get("arbres", []):
		var w: Vector3 = tp
		L["ville"][int(absf(w.x)) % 2].append(_xf(w, _rng.randf_range(0.9, 1.1), 0.05))
		_trunk(w, 0.35, 2.6)
	for hp in extra.get("herbes", []):
		L["folle"][0].append(_xfr(hp, 0.7, 1.3, 0.02))
	for i8 in range(int(900 * q)):
		var pv: Vector3 = _mpb("ville", 2.6, 0.3, 4.2)
		if pv != Vector3.INF:
			L["folle"][0].append(_xfr(pv, 0.5, 1.1, 0.02))
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("bouleau_%d" % v, Flora.tree(7520 + v, 11.0 + v * 1.5, 300), L["bouleau"][v], 600.0)
	for v2 in range(2):
		_emit("saule_bo_%d" % v2, willow_mesh(v2 + 2), L["saule"][v2], 500.0)
		_emit("pionnier_%d" % v2, Flora.tree(7530 + v2, 8.5 + v2 * 2.0, 280), L["pionnier"][v2], 600.0)
		_emit("buddleia_%d" % v2, buddleia_mesh(v2), L["buddleia"][v2], 220.0)
		_emit("buisson_bo_%d" % v2, Flora.bush(7550 + v2), L["buisson"][v2], 220.0)
		_emit("arbre_place_%d" % v2, Flora.tree(7560 + v2, 9.0, 280), L["ville"][v2], 400.0)
	_emit("herbe_seche_bo", meadow_mesh(), L["seche"][0], 75.0, false)
	_emit("friche_bo", lush_grass_mesh(), L["friche"][0], 75.0, false)
	_emit("chardon_bo", thistle_mesh(), L["chardon"][0], 70.0, false)
	_emit("violet_bo", purple_mesh(), L["violet"][0], 70.0, false)
	_emit("jaune_bo", yellow_mesh(), L["jaune"][0], 70.0, false)
	_emit("fougere_bo", _ground("fougere"), L["fougere"][0], 80.0, false)
	_emit("herbe_folle_bo", meadow_mesh(), L["folle"][0], 70.0, false)
	_rock_mm("beton_bo", Color(0.6, 0.6, 0.58), 0.35, rocks["beton"], 3, Vector3(1.6, 0.8, 1.2), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V75: végétation de l'Île du Boucan ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

extends "res://scripts/soleils_flore_v69.gd"
## V71 : la végétation de l'Île de Montjoie (mêmes outils que les autres îles : maillages
## fabriqués ici ou empruntés aux îles précédentes, instanciés par espèce dans des MultiMesh).
##  - le Bois des Lutins : de grands chênes et des hêtres serrés, des fougères, des buissons ;
##  - les prés autour de la Butte : herbe grasse, fleurs des champs (boutons d'or, coquelicots,
##    marguerites), quelques grands arbres isolés, des haies ;
##  - le verger de la ferme : des pommiers en rangées ;
##  - le Lac des Grenouilles : des roseaux serrés sur les rives, des saules ;
##  - les Crocs : des épicéas sur les pentes, de la bruyère, des blocs gris ;
##  - dans la ville : les arbres des rues et des places.

const RM = preload("res://scripts/ile_montjoie_v71.gd")

var _ilem: Node3D


## Un saule (au bord du lac) : un tronc court, une large couronne qui retombe.
func willow_mesh(variant: int) -> ArrayMesh:
	var m: ArrayMesh = Flora.tree(7110 + variant, 7.5, 300).duplicate()
	return m


func poppy_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.92, 0.12, 0.08)))
	return m


func daisy_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.97, 0.96, 0.92)))
	return m


## Un point de l'île qui convient (hors de la ville, des chemins, des champs, de l'eau, des lieux).
## want : "" (partout), "bois", "crocs", "lac" (la rive), "verger".
func _mp(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"bois":
				var a: float = _rng.randf() * TAU
				l = RM.FOREST + Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * RM.FOREST_R
			"crocs":
				var c: Array = RM.CROCS[_rng.randi() % RM.CROCS.size()]
				var a2: float = _rng.randf() * TAU
				l = Vector2(float(c[0]), float(c[1])) + Vector2(cos(a2), sin(a2)) * sqrt(_rng.randf()) * (float(c[2]) + 14.0)
			"lac":
				var a3: float = _rng.randf() * TAU
				var k: float = _rng.randf_range(1.0, 1.22)
				l = RM.LAKE + Vector2(cos(a3) * RM.LAKE_AX.x, sin(a3) * RM.LAKE_AX.y) * k
			_:
				l = Vector2(_rng.randf_range(-RM.HALF + 4.0, RM.HALF - 4.0), _rng.randf_range(-RM.HALF + 4.0, RM.HALF - 4.0))
		if absf(l.x) > RM.HALF - 2.0 or absf(l.y) > RM.HALF - 2.0:
			continue
		if l.distance_to(RM.TOWN) < RM.WALL_R1 + 7.0:
			continue
		if _blocked.has(_cell(l)):
			continue
		if RM.FIELDS.grow(2.0).has_point(l):
			continue
		if l.distance_to(RM.HARBOR) < RM.HARBOR_R + 4.0:
			continue
		var w3: Vector3 = RM.W(l.x, l.y)
		w3.y = _ilem.height(w3.x, w3.z)
		if _ilem.in_lake_water(w3.x, w3.z):
			continue
		var b: Color = _ilem.biome_at(w3.x, w3.z)
		if b.r > 0.35 or b.a > 0.3:
			continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_m() -> void:
	for k in _ilem.paths_world:
		for p in _ilem.paths_world[k]:
			var l: Vector2 = RM.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


## Plante l'île. extra : « arbres » (Vector3 : les arbres plantés dans la ville).
func build_montjoie(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ilem = island
	ile = island
	_rng.seed = 7100
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_m()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_montjoie_v71"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"chene": [[], [], []], "isole": [[], []], "pommier": [[], []], "saule": [[], []], "epicea": [[], []], "buisson": [[], []],
		"herbe": [[]], "pre": [[]], "fleur_or": [[]], "coquelicot": [[]], "marguerite": [[]], "fougere": [[]], "roseau": [[]], "bruyere": [[]],
		"ville": [[], []]}
	var rocks := {"crocs": [], "pre": []}
	# ---------------------------------------------------------------- le Bois des Lutins
	for i in range(int(460 * q)):
		var p: Vector3 = _mp("bois", 0.8, 0.6, 60.0)
		if p == Vector3.INF:
			continue
		L["chene"][i % 3].append(_xfr(p, 0.75, 1.25, 0.15))
		_trunk(p, 0.5, 4.0)
	for i2 in range(int(160 * q)):
		var pb: Vector3 = _mp("bois", 0.8, 0.7, 60.0)
		if pb != Vector3.INF:
			L["buisson"][i2 % 2].append(_xfr(pb, 0.8, 1.4, 0.1))
	for i3 in range(int(1400 * q)):
		var pf: Vector3 = _mp("bois", 0.6, 0.9, 60.0)
		if pf != Vector3.INF:
			L["fougere"][0].append(_xfr(pf, 0.8, 1.5, 0.03))
	# ---------------------------------------------------------------- les prés : herbe, fleurs, arbres isolés, buissons
	for i4 in range(int(7000 * q)):
		var pg: Vector3 = _mp("", 0.9, 0.8, 50.0)
		if pg == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.55:
			L["herbe"][0].append(_xfr(pg, 0.8, 1.4, 0.02))
		elif r < 0.82:
			L["pre"][0].append(_xfr(pg, 0.8, 1.3, 0.02))
		elif r < 0.9:
			L["fleur_or"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
		elif r < 0.95:
			L["marguerite"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
		else:
			L["coquelicot"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
	for i5 in range(int(90 * q)):
		var pt: Vector3 = _mp("", 1.5, 0.5, 40.0)
		if pt == Vector3.INF or RM.L(pt.x, pt.z).distance_to(RM.FOREST) < RM.FOREST_R + 10.0:
			continue
		L["isole"][i5 % 2].append(_xfr(pt, 0.8, 1.2, 0.15))
		_trunk(pt, 0.5, 4.0)
	for i6 in range(int(260 * q)):
		var ps: Vector3 = _mp("", 1.0, 0.6, 40.0)
		if ps != Vector3.INF:
			L["buisson"][i6 % 2].append(_xfr(ps, 0.7, 1.3, 0.1))
	for i7 in range(int(70 * q)):
		var pr: Vector3 = _mp("", 1.0, 1.0, 40.0)
		if pr != Vector3.INF:
			rocks["pre"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.4, 1.0)), pr - Vector3.UP * 0.3))
	# ---------------------------------------------------------------- le verger de la ferme (à l'ouest des champs)
	for row in range(4):
		for col in range(6):
			var lv := Vector2(RM.FIELDS.position.x - 10.0 - row * 7.0, RM.FIELDS.position.y + 10.0 + col * 8.0) + Vector2(_rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.8, 0.8))
			var wv: Vector3 = RM.W(lv.x, lv.y)
			wv.y = _ilem.height(wv.x, wv.z)
			if _blocked.has(_cell(lv)) or not _ok_spot(wv, 0.6, 0.8, 60.0):
				continue
			L["pommier"][(row + col) % 2].append(_xf(wv, _rng.randf_range(0.85, 1.1)))
			_trunk(wv, 0.3, 3.0)
	# ---------------------------------------------------------------- le Lac des Grenouilles : roseaux, saules
	for i8 in range(int(900 * q)):
		var pl: Vector3 = _mp("lac", 2.6, 1.2, 12.0)
		if pl != Vector3.INF:
			L["roseau"][0].append(_xfr(pl, 0.8, 1.5, 0.05))
	for i9 in range(int(16 * q)):
		var pw: Vector3 = _mp("lac", 3.0, 0.6, 12.0)
		if pw != Vector3.INF:
			L["saule"][i9 % 2].append(_xfr(pw, 0.9, 1.2, 0.15))
			_trunk(pw, 0.45, 3.0)
	# ---------------------------------------------------------------- les Crocs : épicéas, bruyère, blocs
	for i10 in range(int(130 * q)):
		var pc: Vector3 = _mp("crocs", 4.0, 0.9, 30.0)
		if pc != Vector3.INF:
			L["epicea"][i10 % 2].append(_xfr(pc, 0.6, 1.0, 0.15))
			_trunk(pc, 0.3, 3.0)
	for i11 in range(int(900 * q)):
		var ph: Vector3 = _mp("crocs", 3.0, 1.3, 45.0)
		if ph != Vector3.INF:
			L["bruyere"][0].append(_xfr(ph, 0.8, 1.4, 0.02))
	for i12 in range(int(160 * q)):
		var pk: Vector3 = _mp("crocs", 3.0, 2.5)
		if pk != Vector3.INF:
			rocks["crocs"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.2)), pk - Vector3.UP * 0.4))
	# ---------------------------------------------------------------- dans la ville
	for tp in extra.get("arbres", []):
		var w: Vector3 = tp
		L["ville"][int(absf(w.x)) % 2].append(_xf(w, _rng.randf_range(0.8, 1.0), 0.05))
		_trunk(w, 0.3, 2.6)
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("chene_%d" % v, Flora.tree(7120 + v, 13.0 + v * 2.0, 340), L["chene"][v], 700.0)
	for v2 in range(2):
		_emit("arbre_pre_%d" % v2, Flora.tree(7130 + v2, 10.0 + v2 * 2.5, 320), L["isole"][v2], 700.0)
		_emit("pommier_mj_%d" % v2, Flora.tree(5950 + v2, 5.5, 200), L["pommier"][v2], 420.0)
		_emit("saule_%d" % v2, willow_mesh(v2), L["saule"][v2], 500.0)
		_emit("epicea_mj_%d" % v2, fir_mesh(v2), L["epicea"][v2], 800.0)
		_emit("buisson_mj_%d" % v2, Flora.bush(7140 + v2), L["buisson"][v2], 220.0)
		_emit("arbre_ville_%d" % v2, Flora.tree(7150 + v2, 6.5, 240), L["ville"][v2], 400.0)
	_emit("herbe_grasse_mj", lush_grass_mesh(), L["herbe"][0], 75.0, false)
	_emit("prairie_mj", meadow_mesh(), L["pre"][0], 75.0, false)
	_emit("bouton_or", flowers_mesh("pre"), L["fleur_or"][0], 70.0, false)
	_emit("marguerite", daisy_mesh(), L["marguerite"][0], 70.0, false)
	_emit("coquelicot", poppy_mesh(), L["coquelicot"][0], 70.0, false)
	_emit("fougere_mj", _ground("fougere"), L["fougere"][0], 80.0, false)
	_emit("roseau_mj", Flora.reed_clump(), L["roseau"][0], 120.0, false)
	_emit("bruyere_mj", heather_mesh(), L["bruyere"][0], 80.0, false)
	_rock_mm("crocs_mj", Color(0.52, 0.5, 0.46), 0.25, rocks["crocs"], 3, Vector3(2.4, 1.6, 2.0), true)
	_rock_mm("pre_mj", Color(0.5, 0.49, 0.46), 0.45, rocks["pre"], 2, Vector3(1.6, 1.0, 1.4), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V71: végétation de l'Île de Montjoie ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

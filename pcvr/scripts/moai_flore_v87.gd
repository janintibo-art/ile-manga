extends "res://scripts/boucan_flore_v75.gd"
## V87 : la végétation de l'Île aux Moaïs (mêmes outils que les autres îles, instanciés par
## espèce dans des MultiMesh). Une île de prairie, presque sans arbres : des herbes hautes, vertes
## et dorées, qui ondulent ; des fleurs jaunes et mauves ; des buissons dans les creux à l'abri du
## vent ; quelques petits arbres tordus ; des palmiers sur la Plage Blanche ; des blocs de basalte
## au pied des volcans et le long des falaises.

const RMO = preload("res://scripts/ile_moai_v87.gd")

var _ilemo: Node3D


func _mpm(want: String, min_h: float, max_slope: float, max_h: float = 60.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"plage":
				l = RMO.PLAGE + Vector2(_rng.randf_range(-46.0, 46.0), _rng.randf_range(-14.0, 6.0))
			_:
				l = Vector2(_rng.randf_range(-RMO.HALF + 4.0, RMO.HALF - 4.0), _rng.randf_range(-RMO.HALF + 4.0, RMO.HALF - 4.0))
		if _blocked.has(_cell(l)):
			continue
		if RMO.coast_q(l.x, l.y) > 0.99:
			continue
		var w3: Vector3 = RMO.W(l.x, l.y)
		w3.y = _ilemo.height(w3.x, w3.z)
		if _ilemo.in_lake(w3.x, w3.z):
			continue
		var b: Color = _ilemo.biome_at(w3.x, w3.z)
		match want:
			"plage":
				if b.b < 0.3:
					continue
			"roche":
				if b.g < 0.4:
					continue
			_:
				if b.r > 0.35 or b.a > 0.35 or b.b > 0.3 or b.g > 0.5:
					continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_m() -> void:
	for k in _ilemo.paths_world:
		for p in _ilemo.paths_world[k]:
			var l: Vector2 = RMO.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


func build_moai(island: Node3D, high_quality: bool) -> void:
	_ilemo = island
	_ileb = island
	_ilem = island
	ile = island
	_rng.seed = 8700
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_m()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_moai_v87"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"palmier": [[], [], []], "arbre": [[], []], "buisson": [[], []], "seche": [[]], "verte": [[]], "jaune": [[]], "violet": [[]]}
	var rocks := {"basalte": []}
	# ---------------------------------------------------------------- la prairie
	for i in range(int(8000 * q)):
		var p: Vector3 = _mpm("", 0.8, 0.85)
		if p == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.42:
			L["verte"][0].append(_xfr(p, 0.8, 1.5, 0.02))
		elif r < 0.85:
			L["seche"][0].append(_xfr(p, 0.8, 1.4, 0.02))
		elif r < 0.94:
			L["jaune"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		else:
			L["violet"][0].append(_xfr(p, 0.8, 1.2, 0.02))
	for i2 in range(int(110 * q)):
		var pb: Vector3 = _mpm("", 1.0, 0.6)
		if pb != Vector3.INF:
			L["buisson"][i2 % 2].append(_xfr(pb, 0.7, 1.3, 0.1))
	for i3 in range(int(26 * q) + 4):
		var pt: Vector3 = _mpm("", 1.5, 0.45, 20.0)
		if pt != Vector3.INF:
			L["arbre"][i3 % 2].append(_xfr(pt, 0.55, 0.85, 0.15))
			_trunk(pt, 0.3, 3.0)
	# ---------------------------------------------------------------- la Plage Blanche
	for i4 in range(40):
		if L["palmier"][0].size() + L["palmier"][1].size() + L["palmier"][2].size() >= 16:
			break
		var pp: Vector3 = _mpm("plage", 0.6, 0.6, 7.0)
		if pp != Vector3.INF:
			L["palmier"][i4 % 3].append(_xf(pp, _rng.randf_range(0.8, 1.05), 0.1))
			_trunk(pp, 0.25, 4.0)
	# ---------------------------------------------------------------- les blocs de basalte
	for i5 in range(int(160 * q)):
		var pr: Vector3 = _mpm("roche", -0.2, 1.2, 40.0)
		if pr != Vector3.INF:
			rocks["basalte"].append(Transform3D(Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pr - Vector3.UP * 0.25))
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("palmier_moai_%d" % v, _jungle("palmier", v), L["palmier"][v], 400.0)
	for v2 in range(2):
		_emit("arbre_moai_%d" % v2, Flora.tree(8720 + v2, 6.0 + v2 * 1.5, 260), L["arbre"][v2], 500.0)
		_emit("buisson_moai_%d" % v2, Flora.bush(8730 + v2), L["buisson"][v2], 220.0)
	_emit("herbe_seche_moai", meadow_mesh(), L["seche"][0], 80.0, false)
	_emit("herbe_verte_moai", lush_grass_mesh(), L["verte"][0], 80.0, false)
	_emit("jaune_moai", yellow_mesh(), L["jaune"][0], 70.0, false)
	_emit("violet_moai", purple_mesh(), L["violet"][0], 70.0, false)
	_rock_mm("basalte_moai", Color(0.32, 0.31, 0.3), 0.25, rocks["basalte"], 3, Vector3(1.6, 1.0, 1.3), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V87: végétation de l'Île aux Moaïs ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

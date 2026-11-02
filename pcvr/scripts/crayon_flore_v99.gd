extends "res://scripts/pasta_flore_v97.gd"
## V99 : la végétation de l'Île Crayonnée (mêmes outils que les autres îles, instanciés par espèce
## dans des MultiMesh ; ensuite, crayon_v99.gd passe tout au rendu coloriage) :
##  - le Bois des Hachures, à l'ouest : de grands chênes serrés, des bouleaux, des fougères ;
##  - autour de la Clairière des Géants : une couronne de vieux chênes ;
##  - les Prés Blancs, à l'est : des marguerites, des coquelicots, des bleuets, des boutons d'or,
##    et quelques arbres isolés ;
##  - le Mont Fusain : de l'herbe sèche, des rochers, quelques pins ;
##  - l'Étang Gommé et les ruisseaux : des roseaux, des nénuphars ;
##  - la Grève Blanche : des oyats, quelques pins parasols ;
##  - ailleurs, la prairie : herbe grasse, fleurs des champs.

const RCR = preload("res://scripts/ile_crayon_v99.gd")

var _ilec: Node3D
var arbres: Array = []                  # [x, z, pin (0/1)] : les arbres, pour la carte de l'archipel


func _block_paths_c() -> void:
	for k in _ilec.paths_world:
		for p in _ilec.paths_world[k]:
			var l: Vector2 = RCR.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true
	for f in _ilec.flows_world:
		for p2 in _ilec.flows_world[f]:
			var l2: Vector2 = RCR.L((p2 as Vector3).x, (p2 as Vector3).z)
			for dx2 in range(-2, 3):
				for dz2 in range(-2, 3):
					_blocked[_cell(l2 + Vector2(dx2, dz2) * 1.2)] = true


## want : "" (la prairie), "bois", "pres", "mont", "plage", "etang" (la berge), "couronne" (le tour de
## la clairière).
func _cp(want: String, min_h: float, max_slope: float, max_h: float = 60.0) -> Vector3:
	var cl: Array = RCR.PADS["clairiere"]
	var cc := Vector2(float(cl[0]), float(cl[1]))
	var et := Vector2(float(RCR.ETANG[0]), float(RCR.ETANG[1]))
	for attempt in range(30):
		var l: Vector2
		match want:
			"bois":
				l = Vector2(_rng.randf_range(-RCR.HALF + 6.0, -70.0), _rng.randf_range(-130.0, 150.0))
			"pres":
				l = Vector2(_rng.randf_range(35.0, 165.0), _rng.randf_range(20.0, 150.0))
			"mont":
				var a: float = _rng.randf() * TAU
				l = Vector2(float(RCR.MONT[0]), float(RCR.MONT[1])) + Vector2(cos(a), sin(a)) * _rng.randf_range(8.0, float(RCR.MONT[2]) * 0.95)
			"plage":
				l = RCR.PLAGE + Vector2(_rng.randf_range(-80.0, 80.0), _rng.randf_range(-18.0, 10.0))
			"etang":
				var a2: float = _rng.randf() * TAU
				l = et + Vector2(cos(a2), sin(a2)) * _rng.randf_range(float(RCR.ETANG[2]) - 0.5, float(RCR.ETANG[2]) + 2.5)
			"couronne":
				var a3: float = _rng.randf() * TAU
				l = cc + Vector2(cos(a3), sin(a3)) * _rng.randf_range(float(cl[2]) + 4.0, float(cl[2]) + 16.0)
			_:
				l = Vector2(_rng.randf_range(-RCR.HALF + 4.0, RCR.HALF - 4.0), _rng.randf_range(-RCR.HALF + 4.0, RCR.HALF - 4.0))
		if _blocked.has(_cell(l)):
			continue
		if RCR.coast_q(l.x, l.y) > 0.985:
			continue
		if want != "etang" and l.distance_to(et) < float(RCR.ETANG[2]) + 3.0:
			continue
		if want != "couronne" and l.distance_to(cc) < float(cl[2]) + 2.0:
			continue
		var w3: Vector3 = RCR.W(l.x, l.y)
		w3.y = _ilec.height(w3.x, w3.z)
		var b: Color = _ilec.biome_at(w3.x, w3.z)
		var b2: Color = _ilec.biome2_at(w3.x, w3.z)
		match want:
			"plage":
				if b.b < 0.3:
					continue
			"bois":
				if b2.r < 0.5 or b.b > 0.3 or b.g > 0.5:
					continue
			"pres":
				if b2.g < 0.4 or b.b > 0.3 or b.r > 0.35:
					continue
			"mont":
				if b.r > 0.35:
					continue
			"etang":
				pass
			_:
				if b.r > 0.35 or b.b > 0.3 or b.g > 0.5:
					continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func build_crayon(island: Node3D, high_quality: bool) -> void:
	_ilec = island
	_ilep = island
	_ilel = island
	_ilemo = island
	_ileb = island
	_ilem = island
	ile = island
	_rng.seed = 9900
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_c()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_crayonnee_v99"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"chene": [[], [], []], "bouleau": [[], []], "pin": [[], []], "fruitier": [[]], "buisson": [[], []], "fougere": [[]],
		"verte": [[]], "seche": [[]], "coquelicot": [[]], "marguerite": [[]], "bleuet": [[]], "jaune": [[]], "violet": [[]],
		"roseau": [[]], "nenuphar": [[]], "oyat": [[]], "roche": []}
	# ---------------------------------------------------------------- le Bois des Hachures
	for i in range(int(230 * q) + 50):
		var pb: Vector3 = _cp("bois", 0.8, 0.7)
		if pb == Vector3.INF:
			continue
		if _rng.randf() < 0.8:
			L["chene"][i % 3].append(_xf(pb, _rng.randf_range(0.85, 1.25)))
			_trunk(pb, 0.45, 4.0)
		else:
			L["bouleau"][i % 2].append(_xf(pb, _rng.randf_range(0.8, 1.1)))
			_trunk(pb, 0.25, 4.0)
	for i2 in range(int(900 * q)):
		var pf: Vector3 = _cp("bois", 0.7, 0.8)
		if pf != Vector3.INF:
			L["fougere"][0].append(_xfr(pf, 0.8, 1.4, 0.03))
	for i3 in range(int(70 * q) + 10):
		var pbu: Vector3 = _cp("bois", 0.7, 0.8)
		if pbu != Vector3.INF:
			L["buisson"][i3 % 2].append(_xfr(pbu, 0.8, 1.3, 0.1))
	# ---------------------------------------------------------------- la couronne de la clairière
	for i4 in range(34):
		var pc: Vector3 = _cp("couronne", 0.8, 0.6)
		if pc == Vector3.INF:
			continue
		L["chene"][i4 % 3].append(_xf(pc, _rng.randf_range(1.0, 1.35)))
		_trunk(pc, 0.5, 4.0)
	# ---------------------------------------------------------------- les Prés Blancs
	for i5 in range(int(5200 * q)):
		var pp: Vector3 = _cp("pres", 0.6, 0.8)
		if pp == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.3:
			L["marguerite"][0].append(_xfr(pp, 0.8, 1.3, 0.02))
		elif r < 0.45:
			L["coquelicot"][0].append(_xfr(pp, 0.8, 1.2, 0.02))
		elif r < 0.58:
			L["bleuet"][0].append(_xfr(pp, 0.8, 1.2, 0.02))
		elif r < 0.68:
			L["jaune"][0].append(_xfr(pp, 0.8, 1.2, 0.02))
		elif r < 0.74:
			L["violet"][0].append(_xfr(pp, 0.8, 1.2, 0.02))
		else:
			L["verte"][0].append(_xfr(pp, 0.8, 1.4, 0.02))
	for i6 in range(int(16 * q) + 6):
		var pt: Vector3 = _cp("pres", 0.8, 0.5)
		if pt == Vector3.INF:
			continue
		L["fruitier"][0].append(_xf(pt, _rng.randf_range(0.8, 1.05)))
		_trunk(pt, 0.3, 3.0)
	# ---------------------------------------------------------------- le Mont Fusain
	for i7 in range(int(1400 * q)):
		var pm: Vector3 = _cp("mont", 1.0, 0.9, 60.0)
		if pm != Vector3.INF:
			L["seche"][0].append(_xfr(pm, 0.7, 1.2, 0.02))
	for i8 in range(int(60 * q) + 20):
		var pr: Vector3 = _cp("mont", 2.0, 1.3, 60.0)
		if pr != Vector3.INF:
			L["roche"].append(Transform3D(Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.7)), pr - Vector3.UP * 0.25))
	for i9 in range(int(26 * q) + 8):
		var pn: Vector3 = _cp("mont", 3.0, 0.6, 50.0)
		if pn == Vector3.INF:
			continue
		L["pin"][i9 % 2].append(_xf(pn, _rng.randf_range(0.8, 1.05)))
		_trunk(pn, 0.3, 4.0)
	# ---------------------------------------------------------------- l'étang
	var ec: Vector3 = RCR.W(float(RCR.ETANG[0]), float(RCR.ETANG[1]))
	for i10 in range(int(140 * q) + 30):
		var pe: Vector3 = _cp("etang", -1.0, 1.2, 20.0)
		if pe == Vector3.INF:
			continue
		var de: float = Vector2(pe.x, pe.z).distance_to(Vector2(ec.x, ec.z))
		if de < float(RCR.ETANG[2]) - 0.2:
			continue
		L["roseau"][0].append(_xfr(pe, 0.8, 1.3, 0.1))
	for i11 in range(int(36 * q) + 10):
		var a: float = _rng.randf() * TAU
		var rr: float = _rng.randf_range(2.0, float(RCR.ETANG[2]) - 1.5)
		var pl: Vector3 = ec + Vector3(cos(a), 0, sin(a)) * rr
		# pas sous la cascade
		if Vector2(pl.x, pl.z).distance_to(Vector2(_ilec.pied.x, _ilec.pied.z)) < 4.0:
			continue
		pl.y = _ilec.etang_level + 0.02
		L["nenuphar"][0].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.3)), pl))
	# ---------------------------------------------------------------- la Grève Blanche
	for i12 in range(int(500 * q)):
		var ps: Vector3 = _cp("plage", 0.5, 0.6, 6.0)
		if ps != Vector3.INF:
			L["oyat"][0].append(_xfr(ps, 0.8, 1.4, 0.03))
	for i13 in range(int(10 * q) + 5):
		var pp2: Vector3 = _cp("plage", 1.3, 0.5, 8.0)
		if pp2 == Vector3.INF:
			continue
		if _ilec.biome_at(pp2.x, pp2.z).b > 0.85:
			continue
		L["pin"][i13 % 2].append(_xf(pp2, _rng.randf_range(0.75, 1.0)))
		_trunk(pp2, 0.3, 4.0)
	# ---------------------------------------------------------------- la prairie
	for i14 in range(int(7000 * q)):
		var p: Vector3 = _cp("", 0.7, 0.85)
		if p == Vector3.INF:
			continue
		var b2: Color = _ilec.biome2_at(p.x, p.z)
		if b2.r > 0.5 or b2.g > 0.4:
			continue
		var r2: float = _rng.randf()
		if r2 < 0.55:
			L["verte"][0].append(_xfr(p, 0.8, 1.5, 0.02))
		elif r2 < 0.82:
			L["seche"][0].append(_xfr(p, 0.8, 1.3, 0.02))
		elif r2 < 0.9:
			L["marguerite"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		elif r2 < 0.95:
			L["jaune"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		else:
			L["coquelicot"][0].append(_xfr(p, 0.8, 1.2, 0.02))
	for i15 in range(int(60 * q)):
		var pb2: Vector3 = _cp("", 1.0, 0.6)
		if pb2 != Vector3.INF:
			L["buisson"][i15 % 2].append(_xfr(pb2, 0.7, 1.2, 0.1))
	for sp in ["chene", "bouleau", "pin", "fruitier"]:
		for lst in L[sp]:
			for xf in lst:
				arbres.append([snappedf((xf as Transform3D).origin.x, 0.1), snappedf((xf as Transform3D).origin.z, 0.1), 1 if sp == "pin" else 0])
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("chene_crayon_%d" % v, Flora.tree(9910 + v, 9.0 + v * 1.4, 340), L["chene"][v], 650.0)
	for v2 in range(2):
		_emit("bouleau_crayon_%d" % v2, _birch(v2), L["bouleau"][v2], 520.0)
		_emit("pin_crayon_%d" % v2, pine_mesh(v2), L["pin"][v2], 650.0)
		_emit("buisson_crayon_%d" % v2, Flora.bush(9920 + v2), L["buisson"][v2], 220.0)
	_emit("fruitier_crayon", Flora.tree(9930, 5.5, 220), L["fruitier"][0], 450.0)
	_emit("fougere_crayon", Flora.fern_clump(), L["fougere"][0], 90.0, false)
	_emit("roseau_crayon", Flora.reed_clump(), L["roseau"][0], 110.0, false)
	_emit("nenuphar_crayon", lily_mesh(), L["nenuphar"][0], 90.0, false)
	_emit_tiles("coquelicot_c", poppy_mesh(), L["coquelicot"][0], 0.0, 220.0, false, 24.0)
	_emit_tiles("marguerite_c", daisy_mesh(), L["marguerite"][0], 0.0, 110.0, false, 24.0)
	_emit_tiles("bleuet_c", cornflower_mesh(), L["bleuet"][0], 0.0, 140.0, false, 24.0)
	_emit_tiles("herbe_verte_c", lush_grass_mesh(), L["verte"][0], 0.0, 85.0, false, 30.0)
	_emit_tiles("herbe_seche_c", meadow_mesh(), L["seche"][0], 0.0, 85.0, false, 30.0)
	_emit("jaune_crayon", yellow_mesh(), L["jaune"][0], 70.0, false)
	_emit("violet_crayon", purple_mesh(), L["violet"][0], 70.0, false)
	var oyat: ArrayMesh = Flora.grass_clump(14, 0.7, 0.025, 9960).duplicate()
	oyat.surface_set_material(0, _plain("oyat_crayon", Color(0.42, 0.42, 0.24), Color(0.78, 0.74, 0.5), 0.18))
	_emit("oyat_crayon", oyat, L["oyat"][0], 80.0, false)
	_rock_mm("roche_crayon", Color(0.5, 0.5, 0.5), 0.2, L["roche"], 4, Vector3(2.2, 1.4, 2.0), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V99: végétation de l'Île Crayonnée ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

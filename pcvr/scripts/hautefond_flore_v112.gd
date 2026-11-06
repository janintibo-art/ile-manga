extends "res://scripts/montjoie_flore_v71.gd"
## V112 : la végétation de l'Île de Hautefond : les prés de la campagne (herbes, fleurs des champs),
## le petit bois de la colline du Moulin (chênes, fougères, buissons), des arbres isolés, les pins
## parasols du haut des falaises, la bruyère au bord du vide, les pommiers et les cerisiers des
## Vergers en terrasses, et les arbres de la ville (les tilleuls des promenades, en bacs sur la Place).

const RH = preload("res://scripts/ile_hautefond_v112.gd")

var _ileh: Node3D


func _mph(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"bois":
				var a: float = _rng.randf() * TAU
				l = RH.WOOD + Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * RH.WOOD_R
			"falaise":
				var deg: float = _rng.randf_range(RH.CLIFF_A.x + 10.0, RH.CLIFF_A.y - 10.0)
				l = RH.polar(deg, _rng.randf_range(200.0, 240.0))
				if RH.coast_q(l.x, l.y) > 0.975 or RH.coast_q(l.x, l.y) < 0.86:
					continue
			_:
				l = Vector2(_rng.randf_range(-RH.HALF + 4.0, RH.HALF - 4.0), _rng.randf_range(-RH.HALF + 4.0, RH.HALF - 4.0))
		if absf(l.x) > RH.HALF - 2.0 or absf(l.y) > RH.HALF - 2.0:
			continue
		if l.distance_to(RH.TOWN) < RH.TOWN_R + 6.0:
			continue
		if _blocked.has(_cell(l)):
			continue
		if l.distance_to(RH.HARBOR) < RH.HARBOR_R + 8.0:
			continue
		var tp: Vector2 = RH.town_polar(l.x, l.y)
		if want != "verger" and RH.in_arc(tp.x, RH.ORCH_A.x, RH.ORCH_A.y) and tp.y > RH.ORCH_R0 - 6.0 and want != "falaise":
			continue
		var w3: Vector3 = RH.W(l.x, l.y)
		w3.y = _ileh.height(w3.x, w3.z)
		var b: Color = _ileh.biome_at(w3.x, w3.z)
		if b.r > 0.35 or b.a > 0.3:
			continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_h() -> void:
	for k in _ileh.paths_world:
		for p in _ileh.paths_world[k]:
			var l: Vector2 = RH.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


func build_hautefond(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ileh = island
	_ilem = island
	ile = island
	_rng.seed = 11200
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_h()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_hautefond_v112"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"chene": [[], []], "isole": [[], []], "pommier": [[], []], "cerisier": [[]], "pin": [[], []], "buisson": [[], []],
		"herbe": [[]], "pre": [[]], "fleur_or": [[]], "coquelicot": [[]], "marguerite": [[]], "fougere": [[]], "bruyere": [[]],
		"ville": [[], []]}
	var rocks := {"falaise": [], "pre": []}
	for i in range(int(220 * q)):
		var p: Vector3 = _mph("bois", 0.8, 0.6, 60.0)
		if p == Vector3.INF:
			continue
		L["chene"][i % 2].append(_xfr(p, 0.75, 1.2, 0.15))
		_trunk(p, 0.5, 4.0)
	for i2 in range(int(90 * q)):
		var pb: Vector3 = _mph("bois", 0.8, 0.7, 60.0)
		if pb != Vector3.INF:
			L["buisson"][i2 % 2].append(_xfr(pb, 0.8, 1.4, 0.1))
	for i3 in range(int(700 * q)):
		var pf: Vector3 = _mph("bois", 0.6, 0.9, 60.0)
		if pf != Vector3.INF:
			L["fougere"][0].append(_xfr(pf, 0.8, 1.5, 0.03))
	for i4 in range(int(6000 * q)):
		var pg: Vector3 = _mph("", 0.9, 0.8, 50.0)
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
	for i5 in range(int(70 * q)):
		var pt: Vector3 = _mph("", 1.5, 0.5, 40.0)
		if pt == Vector3.INF or RH.L(pt.x, pt.z).distance_to(RH.WOOD) < RH.WOOD_R + 10.0:
			continue
		L["isole"][i5 % 2].append(_xfr(pt, 0.8, 1.2, 0.15))
		_trunk(pt, 0.5, 4.0)
	for i6 in range(int(180 * q)):
		var ps: Vector3 = _mph("", 1.0, 0.6, 40.0)
		if ps != Vector3.INF:
			L["buisson"][i6 % 2].append(_xfr(ps, 0.7, 1.3, 0.1))
	for i7 in range(int(50 * q)):
		var pr: Vector3 = _mph("", 1.0, 1.0, 40.0)
		if pr != Vector3.INF:
			rocks["pre"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.4, 1.0)), pr - Vector3.UP * 0.3))
	# le haut des falaises : des pins parasols penchés par le vent, de la bruyère, des rochers
	for i8 in range(int(60 * q)):
		var pp: Vector3 = _mph("falaise", 4.0, 0.7, 60.0)
		if pp != Vector3.INF:
			L["pin"][i8 % 2].append(_xfr(pp, 0.7, 1.1, 0.25))
			_trunk(pp, 0.35, 3.0)
	for i9 in range(int(900 * q)):
		var ph: Vector3 = _mph("falaise", 3.0, 1.2, 60.0)
		if ph != Vector3.INF:
			L["bruyere"][0].append(_xfr(ph, 0.8, 1.4, 0.02))
	for i10 in range(int(80 * q)):
		var pk: Vector3 = _mph("falaise", 3.0, 2.5)
		if pk != Vector3.INF:
			rocks["falaise"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pk - Vector3.UP * 0.4))
	# les vergers : pommiers et cerisiers en rangées
	var k_o: int = 0
	for op in extra.get("vergers", []):
		var w: Vector3 = op
		var wl: Vector2 = RH.L(w.x, w.z)
		if _blocked.has(_cell(wl)):
			continue
		if k_o % 4 == 3:
			L["cerisier"][0].append(_xf(w, _rng.randf_range(0.85, 1.05)))
		else:
			L["pommier"][k_o % 2].append(_xf(w, _rng.randf_range(0.85, 1.1)))
		_trunk(w, 0.3, 3.0)
		k_o += 1
	for tp in extra.get("arbres", []):
		var w2: Vector3 = tp
		L["ville"][int(absf(w2.x)) % 2].append(_xf(w2, _rng.randf_range(0.8, 1.0), 0.05))
		_trunk(w2, 0.3, 2.6)
	for v in range(2):
		_emit("chene_hf_%d" % v, Flora.tree(11220 + v, 13.0 + v * 2.0, 340), L["chene"][v], 700.0)
		_emit("arbre_pre_hf_%d" % v, Flora.tree(11230 + v, 10.0 + v * 2.5, 320), L["isole"][v], 700.0)
		_emit("pommier_hf_%d" % v, Flora.tree(5950 + v, 5.5, 200), L["pommier"][v], 420.0)
		_emit("pin_hf_%d" % v, fir_mesh(v), L["pin"][v], 800.0)
		_emit("buisson_hf_%d" % v, Flora.bush(11240 + v), L["buisson"][v], 220.0)
		_emit("arbre_ville_hf_%d" % v, Flora.tree(11250 + v, 6.5, 240), L["ville"][v], 400.0)
	var cer: ArrayMesh = Flora.tree(11260, 5.0, 200).duplicate()
	for s in range(cer.get_surface_count()):
		var m: Material = cer.surface_get_material(s)
		if m is StandardMaterial3D and (m as StandardMaterial3D).albedo_color.g > (m as StandardMaterial3D).albedo_color.r:
			var mm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
			mm.albedo_color = Color(0.98, 0.7, 0.8)
			cer.surface_set_material(s, mm)
	_emit("cerisier_hf", cer, L["cerisier"][0], 420.0)
	_emit("herbe_grasse_hf", lush_grass_mesh(), L["herbe"][0], 75.0, false)
	_emit("prairie_hf", meadow_mesh(), L["pre"][0], 75.0, false)
	_emit("bouton_or_hf", flowers_mesh("pre"), L["fleur_or"][0], 70.0, false)
	_emit("marguerite_hf", daisy_mesh(), L["marguerite"][0], 70.0, false)
	_emit("coquelicot_hf", poppy_mesh(), L["coquelicot"][0], 70.0, false)
	_emit("fougere_hf", _ground("fougere"), L["fougere"][0], 80.0, false)
	_emit("bruyere_hf", heather_mesh(), L["bruyere"][0], 80.0, false)
	_rock_mm("falaise_hf", Color(0.6, 0.56, 0.48), 0.25, rocks["falaise"], 3, Vector3(2.4, 1.6, 2.0), true)
	_rock_mm("pre_hf", Color(0.55, 0.52, 0.46), 0.45, rocks["pre"], 2, Vector3(1.6, 1.0, 1.4), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V112: végétation de l'Île de Hautefond ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

extends "res://scripts/hautefond_flore_v112.gd"
## V113 : la végétation de la Cité des Nuées : les pelouses (herbe grasse, prairie fleurie), les grands
## arbres et les cerisiers du Parc des Brumes, ses buissons, les arbres des bacs de l'Esplanade et des
## jardins sur les toits et les gradins, et ce qui pousse sous les coupoles des Serres d'Altitude.

const RN = preload("res://scripts/ile_nuees_v113.gd")

var _ilen: Node3D


func _avoid_hit(w: Vector3) -> bool:
	for a in avoid:
		if Vector2(w.x, w.z).distance_to(a[0]) < float(a[1]):
			return true
	return false


## Un point de pelouse (repère monde) : sur le dessus, loin du bord, pas sur les dalles, pas dans les
## bâtiments. near : [centre local, rayon] pour chercher autour d'un lieu (vide : partout).
func _np(near: Array = [], min_bord: float = 9.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		if near.is_empty():
			var a: float = _rng.randf() * TAU
			l = Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * 104.0
		else:
			var a2: float = _rng.randf() * TAU
			l = (near[0] as Vector2) + Vector2(cos(a2), sin(a2)) * sqrt(_rng.randf()) * float(near[1])
		var rr: float = float(_ilen.coast_radius(atan2(l.y, l.x)))
		if l.length() > rr - min_bord:
			continue
		if l.distance_to(RN.POND) < RN.POND_R + 1.5:
			continue
		var w: Vector3 = RN.W(l.x, l.y)
		var b: Color = _ilen.biome_at(w.x, w.z) if _ilen.has_method("biome_at") else Color(0, 0, 0, 0)
		if b.a > 0.25:
			continue
		if _avoid_hit(w):
			continue
		w.y = _ilen.height(w.x, w.z)
		if w.y < -1e6:
			continue
		return w
	return Vector3.INF


func build_nuees(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ilen = island
	ile = island
	_rng.seed = 11330
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.5
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_nuees_v113"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"grand": [[], []], "cerisier": [[]], "ville": [[], []], "buisson": [[], []], "herbe": [[]], "pre": [[]],
		"marguerite": [[]], "fleur_or": [[]], "fougere": [[]]}
	# le Parc des Brumes : de grands arbres, des cerisiers, des buissons, des fougères sous les arbres
	for i in range(int(46 * q) + 6):
		var p: Vector3 = _np([RN.PARC, 30.0], 11.0)
		if p == Vector3.INF:
			continue
		if i % 4 == 3:
			L["cerisier"][0].append(_xfr(p, 0.85, 1.1, 0.1))
			_trunk(p, 0.3, 3.0)
		else:
			L["grand"][i % 2].append(_xfr(p, 0.7, 1.05, 0.15))
			_trunk(p, 0.45, 4.0)
	for i2 in range(int(70 * q)):
		var pb: Vector3 = _np([RN.PARC, 34.0], 10.0)
		if pb != Vector3.INF:
			L["buisson"][i2 % 2].append(_xfr(pb, 0.8, 1.4, 0.1))
	for i3 in range(int(260 * q)):
		var pf: Vector3 = _np([RN.PARC, 22.0], 10.0)
		if pf != Vector3.INF:
			L["fougere"][0].append(_xfr(pf, 0.7, 1.2, 0.03))
	# les pelouses de toute la ville
	for i4 in range(int(5200 * q)):
		var pg: Vector3 = _np([], 7.5)
		if pg == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.6:
			L["herbe"][0].append(_xfr(pg, 0.7, 1.2, 0.02))
		elif r < 0.86:
			L["pre"][0].append(_xfr(pg, 0.7, 1.1, 0.02))
		elif r < 0.94:
			L["marguerite"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
		else:
			L["fleur_or"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
	# quelques arbres isolés sur les pelouses de la ville
	for i5 in range(int(40 * q)):
		var pt: Vector3 = _np([], 14.0)
		if pt == Vector3.INF or RN.L(pt.x, pt.z).distance_to(RN.PARC) < 34.0:
			continue
		L["ville"][i5 % 2].append(_xfr(pt, 0.85, 1.15, 0.1))
		_trunk(pt, 0.3, 2.6)
	# les arbres des bacs, des toits et des gradins (fournis par la ville)
	for tp in extra.get("arbres", []):
		var w2: Vector3 = tp
		L["ville"][int(absf(w2.x)) % 2].append(_xf(w2, _rng.randf_range(0.7, 0.95), 0.05))
		_trunk(w2, 0.3, 2.6)
	# sous les coupoles des Serres : des buissons fleuris, de petits arbres, des fougères
	for sp in extra.get("serre", []):
		var w3: Vector3 = sp
		var k: float = _rng.randf()
		if k < 0.3:
			L["cerisier"][0].append(_xf(w3, _rng.randf_range(0.55, 0.7), 0.05))
		elif k < 0.75:
			L["buisson"][int(k * 10.0) % 2].append(_xf(w3, _rng.randf_range(0.9, 1.5), 0.05))
		else:
			L["fougere"][0].append(_xf(w3, _rng.randf_range(1.0, 1.6), 0.02))
	for v in range(2):
		_emit("arbre_parc_nu_%d" % v, Flora.tree(11340 + v, 11.0 + v * 2.0, 320), L["grand"][v], 900.0)
		_emit("arbre_ville_nu_%d" % v, Flora.tree(11350 + v, 6.0, 240), L["ville"][v], 700.0)
		_emit("buisson_nu_%d" % v, Flora.bush(11360 + v), L["buisson"][v], 260.0)
	var cer: ArrayMesh = Flora.tree(11370, 5.0, 200).duplicate()
	for s in range(cer.get_surface_count()):
		var m: Material = cer.surface_get_material(s)
		if m is StandardMaterial3D and (m as StandardMaterial3D).albedo_color.g > (m as StandardMaterial3D).albedo_color.r:
			var mm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
			mm.albedo_color = Color(0.99, 0.74, 0.84)
			cer.surface_set_material(s, mm)
	_emit("cerisier_nu", cer, L["cerisier"][0], 600.0)
	_emit("herbe_grasse_nu", lush_grass_mesh(), L["herbe"][0], 70.0, false)
	_emit("prairie_nu", meadow_mesh(), L["pre"][0], 70.0, false)
	_emit("marguerite_nu", daisy_mesh(), L["marguerite"][0], 65.0, false)
	_emit("bouton_or_nu", flowers_mesh("pre"), L["fleur_or"][0], 65.0, false)
	_emit("fougere_nu", _ground("fougere"), L["fougere"][0], 75.0, false)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V113: végétation de la Cité des Nuées ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

extends "res://scripts/montjoie_flore_v71.gd"
## V121 : la végétation de Sombreval, la ville morte : la nature a tout repris. Des arbres ont
## poussé au milieu des rues et dans les cours des immeubles, des buissons et des fougères dans
## les terrains vagues, l'herbe haute a percé l'asphalte, des ronces au pied des murs ; des arbres
## morts et noirs sur les pentes de la Butte du Comte et dans le vieux cimetière.
## Les points où rien ne pousse (les immeubles, le château) sont dans _blocked (cellules de 2 m,
## repère île), remplis par sombreval_v121 avant la plantation.

const RS = preload("res://scripts/ile_sombreval_v121.gd")

var _iles: Node3D


func _msv(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"butte":
				var a: float = _rng.randf() * TAU
				l = Vector2(cos(a), sin(a)) * _rng.randf_range(RS.HILL_R0 + 4.0, RS.HILL_R1 + 6.0)
			"rue":
				# au milieu d'une rue (l'asphalte a cédé)
				var k: int = _rng.randi_range(-3, 3)
				var along: float = _rng.randf_range(-RS.ANNEAU, RS.ANNEAU)
				var off: float = _rng.randf_range(-3.5, 3.5)
				l = Vector2(k * RS.PAS + off, along) if _rng.randf() < 0.5 else Vector2(along, k * RS.PAS + off)
			_:
				l = Vector2(_rng.randf_range(-RS.HALF + 4.0, RS.HALF - 4.0), _rng.randf_range(-RS.HALF + 4.0, RS.HALF - 4.0))
		if _blocked.has(_cell(l)):
			continue
		var r: float = l.length()
		if want != "butte" and r < RS.HILL_R1 - 6.0:
			continue
		if want == "butte" and RS.ramp_at(l.x, l.y).y < RS.RAMP_W + 1.5 and RS.ramp_at(l.x, l.y).x <= 1.0:
			continue
		if RS.in_jetee(l.x, l.y) or (absf(l.x) < 8.0 and l.y < -200.0):
			continue
		var w3: Vector3 = RS.W(l.x, l.y)
		w3.y = _iles.height(w3.x, w3.z)
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func build_sombreval(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_iles = island
	_ilem = island
	ile = island
	_rng.seed = 12100
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_sombreval_v121"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"grand": [[], []], "rue": [[], []], "mort": [[], []], "buisson": [[], []], "herbe": [[]], "pre": [[]], "fougere": [[]],
		"bruyere": [[]], "fleur": [[]], "ville": [[], []]}
	# de grands arbres dans les terrains vagues et les cours
	for i in range(int(260 * q)):
		var p: Vector3 = _msv("", 1.0, 0.6, 12.0)
		if p == Vector3.INF:
			continue
		L["grand"][i % 2].append(_xfr(p, 0.7, 1.25, 0.15))
		_trunk(p, 0.45, 4.0)
	# des arbres au milieu des rues
	for i2 in range(int(70 * q)):
		var pr: Vector3 = _msv("rue", 1.0, 0.5, 12.0)
		if pr == Vector3.INF:
			continue
		L["rue"][i2 % 2].append(_xfr(pr, 0.6, 1.0, 0.1))
		_trunk(pr, 0.35, 3.5)
	# des arbres morts, noirs, sur les pentes de la Butte
	for i3 in range(int(90 * q)):
		var pm: Vector3 = _msv("butte", 2.5, 1.2, 40.0)
		if pm == Vector3.INF:
			continue
		L["mort"][i3 % 2].append(_xfr(pm, 0.8, 1.3, 0.2))
		_trunk(pm, 0.3, 3.0)
	for i4 in range(int(420 * q)):
		var pb: Vector3 = _msv("", 0.8, 0.8, 30.0)
		if pb != Vector3.INF:
			L["buisson"][i4 % 2].append(_xfr(pb, 0.7, 1.4, 0.1))
	for i5 in range(int(9000 * q)):
		var pg: Vector3 = _msv("" if i5 % 5 != 0 else "rue", 0.6, 1.0, 40.0)
		if pg == Vector3.INF:
			continue
		var r: float = _rng.randf()
		if r < 0.5:
			L["herbe"][0].append(_xfr(pg, 0.8, 1.5, 0.02))
		elif r < 0.78:
			L["pre"][0].append(_xfr(pg, 0.8, 1.4, 0.02))
		elif r < 0.9:
			L["fougere"][0].append(_xfr(pg, 0.8, 1.5, 0.03))
		elif r < 0.97:
			L["bruyere"][0].append(_xfr(pg, 0.8, 1.4, 0.02))
		else:
			L["fleur"][0].append(_xfr(pg, 0.8, 1.2, 0.02))
	for tp in extra.get("arbres", []):
		var w2: Vector3 = tp
		L["ville"][int(absf(w2.x)) % 2].append(_xf(w2, _rng.randf_range(0.8, 1.1), 0.05))
		_trunk(w2, 0.35, 3.0)
	for i6 in range(int(220 * q)):
		var pt: Vector3 = _msv("butte", 2.5, 1.4, 40.0)
		if pt != Vector3.INF:
			L["bruyere"][0].append(_xfr(pt, 0.9, 1.6, 0.02))
	for v in range(2):
		_emit("grand_sv_%d" % v, _sombre(Flora.tree(12120 + v, 12.0 + v * 3.0, 320)), L["grand"][v], 700.0)
		_emit("rue_sv_%d" % v, _sombre(Flora.tree(12130 + v, 8.0 + v * 2.0, 260)), L["rue"][v], 600.0)
		_emit("mort_sv_%d" % v, _noircir(dead_tree_mesh(v + 3)), L["mort"][v], 700.0)
		_emit("buisson_sv_%d" % v, _sombre(Flora.bush(12140 + v)), L["buisson"][v], 220.0)
		_emit("cour_sv_%d" % v, _sombre(Flora.tree(12150 + v, 9.0, 260)), L["ville"][v], 500.0)
	_emit("herbe_sv", lush_grass_mesh(), L["herbe"][0], 75.0, false)
	_emit("pre_sv", meadow_mesh(), L["pre"][0], 75.0, false)
	_emit("fougere_sv", _ground("fougere"), L["fougere"][0], 80.0, false)
	_emit("bruyere_sv", heather_mesh(), L["bruyere"][0], 80.0, false)
	_emit("fleur_sv", flowers_mesh("pre"), L["fleur"][0], 70.0, false)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V121: végétation de Sombreval ", placed, " en ", Time.get_ticks_msec() - t0, " ms")


## Un feuillage plus sombre, plus terne (la lumière est blafarde à Sombreval)
func _sombre(m: Mesh) -> Mesh:
	var out: ArrayMesh = (m as ArrayMesh).duplicate()
	for s in range(out.get_surface_count()):
		var mt: Material = out.surface_get_material(s)
		if mt is StandardMaterial3D:
			var sm: StandardMaterial3D = (mt as StandardMaterial3D).duplicate()
			var c: Color = sm.albedo_color
			if c.g > c.r:
				sm.albedo_color = c.darkened(0.25).lerp(Color(0.3, 0.36, 0.25), 0.3)
			else:
				sm.albedo_color = c.darkened(0.2)
			out.surface_set_material(s, sm)
	return out


## Les arbres morts : noirs, comme brûlés
func _noircir(m: Mesh) -> Mesh:
	var out: ArrayMesh = (m as ArrayMesh).duplicate()
	for s in range(out.get_surface_count()):
		var mt: Material = out.surface_get_material(s)
		if mt is StandardMaterial3D:
			var sm: StandardMaterial3D = (mt as StandardMaterial3D).duplicate()
			sm.albedo_color = Color(0.16, 0.14, 0.13)
			out.surface_set_material(s, sm)
	return out

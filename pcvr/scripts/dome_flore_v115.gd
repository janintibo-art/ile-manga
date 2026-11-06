extends "res://scripts/nuees_flore_v113.gd"
## V115 : la végétation du Dôme d'Azur, à cent quarante mètres sous la mer : tout y pousse sous la
## Grande Perle. Les jardinets bordés de nacre du Grand Dôme et des Serres (un petit arbre ou des
## buissons, du gazon, des fleurs roses, jaunes et blanches, des fougères), les arbres des jardins des
## Gradins, et le Verger des Lampes (des mandariniers et des citronniers, chargés de fruits).

## extra : « massifs » [[centre (le dessus de la terre), rayon, "arbre" | "buisson"]],
## « arbres » [Vector3] (des arbres d'ornement), « vergers » [Vector3] (des arbres fruitiers).
func build_dome(high_quality: bool, extra: Dictionary) -> void:
	_rng.seed = 11540
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_dome_v115"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"arbre": [[], []], "fruitier": [[], []], "buisson": [[], []], "herbe": [[]], "fleur_rose": [[]], "fleur_or": [[]],
		"marguerite": [[]], "fougere": [[]]}
	for m in extra.get("massifs", []):
		var c: Vector3 = m[0]
		var r: float = m[1]
		var kind: String = m[2]
		if kind == "arbre":
			L["arbre"][_rng.randi() % 2].append(_xfr(c, 0.55, 0.72, 0.05))
			_trunk(c, 0.18, 2.4)
		else:
			var nb: int = 1 + int(r > 1.9)
			for k in range(nb):
				var a0: float = _rng.randf() * TAU
				var o := Vector3(cos(a0), 0, sin(a0)) * (r * 0.35 if nb > 1 else 0.0)
				L["buisson"][_rng.randi() % 2].append(_xfr(c + o, 0.55, 0.85, 0.05))
		# le gazon, les fleurs et les fougères, sur la terre du massif
		var n_g: int = int(r * r * 4.0 * q) + 5
		for k2 in range(n_g):
			var a: float = _rng.randf() * TAU
			var rr: float = sqrt(_rng.randf()) * (r - 0.35)
			var p: Vector3 = c + Vector3(cos(a) * rr, 0, sin(a) * rr)
			var t: float = _rng.randf()
			if t < 0.5:
				L["herbe"][0].append(_xfr(p, 0.6, 1.0, 0.02))
			elif t < 0.66:
				L["fleur_rose"][0].append(_xfr(p, 0.7, 1.0, 0.02))
			elif t < 0.78:
				L["fleur_or"][0].append(_xfr(p, 0.7, 1.0, 0.02))
			elif t < 0.9:
				L["marguerite"][0].append(_xfr(p, 0.7, 1.0, 0.02))
			else:
				L["fougere"][0].append(_xfr(p, 0.55, 0.9, 0.02))
	for tp in extra.get("arbres", []):
		var w: Vector3 = tp
		L["arbre"][int(absf(w.x)) % 2].append(_xf(w, _rng.randf_range(0.6, 0.78), 0.05))
		_trunk(w, 0.18, 2.4)
	var fruits: Array = [[], []]           # mandarines, citrons
	for vp in extra.get("vergers", []):
		var w2: Vector3 = vp
		var v: int = int(absf(w2.x * 0.37 + w2.z)) % 2
		var s: float = _rng.randf_range(0.82, 1.0)
		var xf: Transform3D = _xf(w2, s, 0.05)
		L["fruitier"][v].append(xf)
		_trunk(w2, 0.15, 2.0)
		# les fruits : sur le pourtour du houppier (H = 4,4 m : le centre à 0,68 H, le rayon 0,36 H)
		var cc: Vector3 = w2 + Vector3.UP * (4.4 * 0.68 * s - 0.05)
		for k3 in range(16):
			var a3: float = _rng.randf() * TAU
			var el: float = _rng.randf_range(-0.75, 0.35)
			var d := Vector3(cos(a3) * cos(el), sin(el), sin(a3) * cos(el))
			fruits[v].append(Transform3D(Basis().scaled(Vector3.ONE * _rng.randf_range(0.85, 1.15)), cc + d * 4.4 * 0.36 * s * 0.9))
	for v2 in range(2):
		_emit("arbre_dome_%d" % v2, Flora.tree(11550 + v2, 6.0, 240), L["arbre"][v2], 260.0)
		_emit("fruitier_dome_%d" % v2, Flora.tree(11560 + v2, 4.4, 200), L["fruitier"][v2], 220.0)
		_emit("buisson_dome_%d" % v2, Flora.bush(11570 + v2), L["buisson"][v2], 150.0)
	_emit("herbe_dome", lush_grass_mesh(), L["herbe"][0], 60.0, false)
	_emit("fleur_rose_dome", flowers_mesh("rose"), L["fleur_rose"][0], 55.0, false)
	_emit("fleur_or_dome", flowers_mesh("pre"), L["fleur_or"][0], 55.0, false)
	_emit("marguerite_dome", daisy_mesh(), L["marguerite"][0], 55.0, false)
	_emit("fougere_dome", _ground("fougere"), L["fougere"][0], 60.0, false)
	var sm := SphereMesh.new()
	sm.radius = 0.065
	sm.height = 0.13
	sm.radial_segments = 8
	sm.rings = 4
	var Mats = load("res://scripts/dome_mats_v115.gd")
	for v3 in range(2):
		if (fruits[v3] as Array).is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sm
		mm.instance_count = (fruits[v3] as Array).size()
		for i in range(mm.instance_count):
			mm.set_instance_transform(i, fruits[v3][i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Fruits_dome_%d" % v3
		mmi.multimesh = mm
		mmi.material_override = Mats.make("fruit115" if v3 == 0 else "fruit115_citron")
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 120.0
		add_child(mmi)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V115: végétation du Dôme d'Azur ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

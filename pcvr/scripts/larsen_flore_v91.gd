extends "res://scripts/moai_flore_v87.gd"
## V91 : la végétation de l'Île de Larsen (mêmes outils que les autres îles, instanciés par espèce
## dans des MultiMesh, découpés en carreaux pour que les champs lointains passent à un maillage plus
## simple) :
##  - les champs de chanvre, au nord-ouest : de hautes tiges serrées (2,5 à 3 m), leurs feuilles en
##    éventail ; on en fait des cordes et des tissus (la corderie est au bord du champ) ;
##  - les champs de coquelicots, au sud-est : un tapis rouge qui ondule, des bleuets, des marguerites ;
##  - le Bois des Riffs, au nord : des chênes, des bouleaux, des fougères ;
##  - les jardins du Camp des Fleurs : des tournesols ;
##  - la Mare aux Mantras : des roseaux, des nénuphars ;
##  - ailleurs, la prairie : herbe grasse, fleurs des champs.

const RLA = preload("res://scripts/ile_larsen_v91.gd")

var _ilel: Node3D
var jardins: Array = []                 # [Vector3 (le centre), demi-largeur, demi-profondeur, angle] (posés par l'île)


# =================================================================== les plantes

## Une touffe de chanvre : quelques hautes tiges, leurs feuilles en éventail (cinq à sept folioles),
## plus serrées en haut. detail : 1 tout près, 0 de loin (une tige, trois étages de feuilles).
func hemp_mesh(variant: int, detail: int) -> ArrayMesh:
	var key := "chanvre_%d_%d" % [variant, detail]
	if _mats.has(key):
		return _mats[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9110 + variant * 7 + detail
	var st := _st()
	var stalks: int = 4 if detail == 1 else 3
	for s in range(stalks):
		var root := Vector3(rng.randf_range(-0.36, 0.36), 0, rng.randf_range(-0.36, 0.36))
		var h: float = rng.randf_range(2.3, 3.0)
		var lean := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		# la tige (un tube à quatre côtés)
		var segs: int = 5 if detail == 1 else 2
		for k in range(segs):
			var t0: float = float(k) / segs
			var t1: float = float(k + 1) / segs
			var c0: Vector3 = root + Vector3.UP * h * t0 + lean * t0 * t0 * h
			var c1: Vector3 = root + Vector3.UP * h * t1 + lean * t1 * t1 * h
			var r0: float = lerpf(0.018, 0.006, t0)
			var r1: float = lerpf(0.018, 0.006, t1)
			for q in range(3 if detail == 1 else 2):
				var a0: float = TAU * q / 3.0
				var a1: float = TAU * (q + 1) / 3.0
				var d0 := Vector3(cos(a0), 0, sin(a0))
				var d1 := Vector3(cos(a1), 0, sin(a1))
				for v in [[c0 + d0 * r0, d0, t0], [c0 + d1 * r0, d1, t0], [c1 + d1 * r1, d1, t1], [c0 + d0 * r0, d0, t0], [c1 + d1 * r1, d1, t1], [c1 + d0 * r1, d0, t1]]:
					Flora._vertex(st, v[0], v[1], Vector2(0.5, 0.1), float(v[2]) * float(v[2]), 0.2)
		# les feuilles, par paires opposées, tournées d'un quart à chaque étage
		var nodes: int = 9 if detail == 1 else 5
		for n in range(nodes):
			var t: float = lerpf(0.22, 0.97, pow(float(n) / maxf(nodes - 1, 1), 0.8))
			var c: Vector3 = root + Vector3.UP * h * t + lean * t * t * h
			var leaf_l: float = lerpf(0.42, 0.24, t) * rng.randf_range(0.85, 1.15)
			var leaflets: int = 7 if (detail == 1 and t < 0.8) else 5
			for side in [0.0, PI]:
				var az: float = float(n) * PI * 0.5 + side + rng.randf_range(-0.3, 0.3)
				var out := Vector3(cos(az), 0, sin(az))
				var base: Vector3 = c + out * 0.1 + Vector3.UP * 0.03
				for f in range(leaflets):
					var spread: float = (float(f) / (leaflets - 1) - 0.5) * 2.2
					var ll: float = leaf_l * (1.0 - 0.55 * absf(spread) / 1.1)
					var dir: Vector3 = (out.rotated(Vector3.UP, spread * 0.55) + Vector3.UP * (0.35 - absf(spread) * 0.45)).normalized()
					var wv: Vector3 = dir.cross(Vector3.UP).normalized() * ll * 0.17
					var tip: Vector3 = base + dir * ll
					var mid: Vector3 = base + dir * ll * 0.45 - Vector3.UP * ll * 0.06
					var nrm: Vector3 = wv.cross(dir).normalized()
					if nrm.y < 0.0:
						nrm = -nrm
					var fl: float = t * t
					# une foliole : un losange allongé, dentelé par deux triangles
					Flora._vertex(st, base, nrm, Vector2(0.5, 0.0), fl, 0.6)
					Flora._vertex(st, mid + wv, nrm, Vector2(1.0, 0.45), fl + 0.1, 0.8)
					Flora._vertex(st, tip, nrm, Vector2(0.5, 1.0), fl + 0.2, 1.0)
					Flora._vertex(st, base, nrm, Vector2(0.5, 0.0), fl, 0.6)
					Flora._vertex(st, tip, nrm, Vector2(0.5, 1.0), fl + 0.2, 1.0)
					Flora._vertex(st, mid - wv, nrm, Vector2(0.0, 0.45), fl + 0.1, 0.8)
		# le sommet : un petit bouquet de jeunes feuilles
		var top: Vector3 = root + Vector3.UP * h + lean * h
		for g in range(5 if detail == 1 else 3):
			var az2: float = TAU * g / 5.0 + rng.randf() * 0.5
			var d2 := (Vector3(cos(az2), 1.6, sin(az2))).normalized()
			var w2: Vector3 = d2.cross(Vector3.UP).normalized() * 0.018
			Flora._vertex(st, top, Vector3.UP, Vector2(0.5, 0.2), 1.0, 1.0)
			Flora._vertex(st, top + d2 * 0.16 + w2, Vector3.UP, Vector2(1.0, 0.9), 1.1, 1.0)
			Flora._vertex(st, top + d2 * 0.16 - w2, Vector3.UP, Vector2(0.0, 0.9), 1.1, 1.0)
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, _plain("chanvre", Color(0.13, 0.3, 0.08), Color(0.42, 0.62, 0.2), 0.1))
	_mats[key] = mesh
	return mesh


## Un tournesol : une tige, deux grandes feuilles, le cœur brun et sa couronne de pétales jaunes.
func sunflower_mesh(variant: int) -> ArrayMesh:
	var key := "tournesol_%d" % variant
	if _mats.has(key):
		return _mats[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9130 + variant
	var stem := _st()
	var head := _st()
	var h: float = rng.randf_range(1.6, 2.1)
	var face := Vector3(rng.randf_range(-0.3, 0.3), -0.25, 1.0).normalized()
	for k in range(4):
		var t0: float = float(k) / 4.0
		var t1: float = float(k + 1) / 4.0
		for q in range(3):
			var a0: float = TAU * q / 3.0
			var a1: float = TAU * (q + 1) / 3.0
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			for v in [[d0 * 0.022 + Vector3.UP * h * t0, d0, t0], [d1 * 0.022 + Vector3.UP * h * t0, d1, t0], [d1 * 0.016 + Vector3.UP * h * t1, d1, t1],
					[d0 * 0.022 + Vector3.UP * h * t0, d0, t0], [d1 * 0.016 + Vector3.UP * h * t1, d1, t1], [d0 * 0.016 + Vector3.UP * h * t1, d0, t1]]:
				Flora._vertex(stem, v[0], v[1], Vector2(0.5, 0.2), float(v[2]) * float(v[2]) * 0.4, 0.2)
	for lf in range(3):
		var y: float = h * (0.35 + lf * 0.2)
		var az: float = lf * 2.3
		var out := Vector3(cos(az), -0.15, sin(az)).normalized()
		var w: Vector3 = out.cross(Vector3.UP).normalized() * 0.13
		var b0: Vector3 = Vector3.UP * y
		for v2 in [[b0, Vector2(0.5, 0)], [b0 + out * 0.2 + w, Vector2(1, 0.5)], [b0 + out * 0.36, Vector2(0.5, 1)], [b0, Vector2(0.5, 0)], [b0 + out * 0.36, Vector2(0.5, 1)], [b0 + out * 0.2 - w, Vector2(0, 0.5)]]:
			Flora._vertex(stem, v2[0], Vector3.UP, v2[1], 0.3, 0.8)
	# la tête : le disque, puis les pétales
	var c: Vector3 = Vector3.UP * h
	var right: Vector3 = face.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(face).normalized()
	for i in range(14):
		var a0b: float = TAU * i / 14.0
		var a1b: float = TAU * (i + 1) / 14.0
		var p0: Vector3 = c + (right * cos(a0b) + up * sin(a0b)) * 0.13 + face * 0.02
		var p1: Vector3 = c + (right * cos(a1b) + up * sin(a1b)) * 0.13 + face * 0.02
		Flora._vertex(head, c + face * 0.05, face, Vector2(0.5, 0.0), 0.5, 0.0)
		Flora._vertex(head, p0, face, Vector2(0.5, 0.0), 0.5, 0.2)
		Flora._vertex(head, p1, face, Vector2(0.5, 0.0), 0.5, 0.2)
	var petals := _st()
	for j in range(18):
		var a: float = TAU * j / 18.0
		var d: Vector3 = right * cos(a) + up * sin(a)
		var s: Vector3 = (right * cos(a + PI * 0.5) + up * sin(a + PI * 0.5)) * 0.03
		var r0: Vector3 = c + d * 0.12
		var tip: Vector3 = c + d * 0.25 - face * 0.03
		Flora._vertex(petals, r0 - s, face, Vector2(0.5, 0.0), 0.5, 0.6)
		Flora._vertex(petals, r0 + s, face, Vector2(0.5, 0.0), 0.5, 0.6)
		Flora._vertex(petals, tip, face, Vector2(0.5, 1.0), 0.55, 1.0)
	var mesh: ArrayMesh = stem.commit()
	mesh.surface_set_material(0, _plain("tournesol_tige", Color(0.14, 0.3, 0.08), Color(0.32, 0.5, 0.16), 0.06))
	head.commit(mesh)
	mesh.surface_set_material(1, _plain("tournesol_coeur", Color(0.22, 0.12, 0.04), Color(0.3, 0.18, 0.06), 0.04))
	petals.commit(mesh)
	mesh.surface_set_material(2, _plain("tournesol_petale", Color(0.95, 0.68, 0.06), Color(1.0, 0.85, 0.2), 0.05))
	_mats[key] = mesh
	return mesh


func cornflower_mesh() -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(Color(0.25, 0.42, 0.95)))
	return m


func lily_mesh() -> Mesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.32
	cm.bottom_radius = 0.32
	cm.height = 0.01
	cm.radial_segments = 10
	cm.rings = 1
	cm.material = _plain("nenuphar", Color(0.12, 0.3, 0.1), Color(0.2, 0.42, 0.14), 0.0)
	return cm


# =================================================================== où planter

## want : "" (la prairie), "bois" (le Bois des Riffs, au nord), "plage", "mare" (la rive).
func _lp(want: String, min_h: float, max_slope: float, max_h: float = 60.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"plage":
				l = RLA.PLAGE + Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(-12.0, 8.0))
			"bois":
				l = Vector2(_rng.randf_range(-110.0, 110.0), _rng.randf_range(-125.0, -60.0))
			"mare":
				var a: float = _rng.randf() * TAU
				l = Vector2(float(RLA.MARE[0]), float(RLA.MARE[1])) + Vector2(cos(a), sin(a)) * _rng.randf_range(float(RLA.MARE[2]) - 0.5, float(RLA.MARE[2]) + 3.0)
			_:
				l = Vector2(_rng.randf_range(-RLA.HALF + 4.0, RLA.HALF - 4.0), _rng.randf_range(-RLA.HALF + 4.0, RLA.HALF - 4.0))
		if _blocked.has(_cell(l)):
			continue
		if RLA.coast_q(l.x, l.y) > 0.985:
			continue
		if RLA.champ_at(l.x, l.y) != "":
			continue
		var w3: Vector3 = RLA.W(l.x, l.y)
		w3.y = _ilel.height(w3.x, w3.z)
		if want != "mare" and _ilel.in_mare(w3.x, w3.z):
			continue
		var b: Color = _ilel.biome_at(w3.x, w3.z)
		match want:
			"plage":
				if b.b < 0.3:
					continue
			"mare":
				pass
			_:
				if b.r > 0.35 or b.a > 0.3 or b.b > 0.3 or b.g > 0.5:
					continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_l() -> void:
	for k in _ilel.paths_world:
		for p in _ilel.paths_world[k]:
			var l: Vector2 = RLA.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


## Comme _emit, mais en carreaux (pour que chaque carreau passe d'un maillage à l'autre selon sa
## distance) ; vbeg : la distance où le carreau commence à se montrer.
func _emit_tiles(label: String, mesh: Mesh, xfs: Array, vbeg: float, vend: float, shadows: bool, tile: float = 18.0) -> void:
	var tiles: Dictionary = {}
	for x in xfs:
		var o: Vector3 = (x as Transform3D).origin
		var k := Vector2i(int(floor(o.x / tile)), int(floor(o.z / tile)))
		if not tiles.has(k):
			tiles[k] = []
		tiles[k].append(x)
	for k2 in tiles:
		var arr: Array = tiles[k2]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = arr.size()
		for i in range(arr.size()):
			mm.set_instance_transform(i, arr[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Flore_larsen_%s_%d_%d" % [label, k2.x, k2.y]
		mmi.multimesh = mm
		mmi.visibility_range_begin = vbeg
		mmi.visibility_range_begin_margin = 6.0 if vbeg > 0.0 else 0.0
		mmi.visibility_range_end = vend
		mmi.visibility_range_end_margin = 6.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		placed[label] = int(placed.get(label, 0)) + arr.size()


# =================================================================== plantation

func build_larsen(island: Node3D, high_quality: bool) -> void:
	_ilel = island
	_ilemo = island
	_ileb = island
	_ilem = island
	ile = island
	_rng.seed = 9100
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_l()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_larsen_v91"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"chene": [[], [], []], "bouleau": [[], []], "buisson": [[], []], "fougere": [[]], "verte": [[]], "seche": [[]], "jaune": [[]],
		"violet": [[]], "coquelicot": [[]], "bleuet": [[]], "marguerite": [[]], "chanvre": [[], []], "tournesol": [[], []], "roseau": [[]],
		"nenuphar": [[]], "palmier": [[], [], []], "oyat": [[]]}
	# ---------------------------------------------------------------- les champs
	for k in RLA.CHAMPS:
		var c: Array = RLA.CHAMPS[k]
		var cx: float = float(c[0])
		var cz: float = float(c[1])
		var hw: float = float(c[2])
		var hd: float = float(c[3])
		var ang: float = float(c[4])
		var chanvre: bool = str(k).begins_with("chanvre")
		var step: float = (0.85 if chanvre else 0.55) / sqrt(q)
		var row: float = (0.95 if chanvre else 0.55) / sqrt(q)
		var z: float = -hd + row * 0.5
		while z < hd:
			# une allée en travers, tous les 9 m (pour se promener dans le champ)
			var lane: bool = fmod(z + hd, 9.0) < (1.6 if chanvre else 1.0) and absf(z) > 2.0
			var x: float = -hw + step * 0.5
			while x < hw:
				var jit := Vector2(_rng.randf_range(-0.2, 0.2) * step, _rng.randf_range(-0.15, 0.15) * row)
				var lp: Vector2 = Vector2(x, z) + jit
				var l: Vector2 = Vector2(cx, cz) + lp.rotated(ang)
				x += step
				if lane or _blocked.has(_cell(l)):
					continue
				var w: Vector3 = RLA.W(l.x, l.y)
				w.y = _ilel.height(w.x, w.z)
				if w.y < 0.4:
					continue
				# le bord du champ s'éclaircit un peu
				var edge: float = minf(hw - absf(lp.x), hd - absf(lp.y))
				if edge < 1.2 and _rng.randf() < 0.5:
					continue
				if chanvre:
					L["chanvre"][0].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1, _rng.randf_range(0.85, 1.12), 1)), w - Vector3.UP * 0.04))
				else:
					var r: float = _rng.randf()
					if r < 0.8:
						L["coquelicot"][0].append(_xfr(w, 0.75, 1.25, 0.02))
					elif r < 0.88:
						L["bleuet"][0].append(_xfr(w, 0.7, 1.1, 0.02))
					elif r < 0.93:
						L["marguerite"][0].append(_xfr(w, 0.7, 1.1, 0.02))
					if _rng.randf() < 0.55:
						L["verte"][0].append(_xfr(w + Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3)), 0.7, 1.2, 0.02))
			z += row
	# des coquelicots sauvages qui débordent sur les pentes autour des champs
	for i0 in range(int(1800 * q)):
		var ck: Array = RLA.CHAMPS["coquelicots"] if i0 % 3 != 0 else RLA.CHAMPS["coquelicots_2"]
		var a0: float = _rng.randf() * TAU
		var rr: float = maxf(float(ck[2]), float(ck[3])) + _rng.randf_range(-2.0, 22.0) * sqrt(_rng.randf())
		var l0: Vector2 = Vector2(float(ck[0]), float(ck[1])) + Vector2(cos(a0) * rr, sin(a0) * rr * 0.75)
		if _blocked.has(_cell(l0)) or RLA.champ_at(l0.x, l0.y) != "":
			continue
		var w0: Vector3 = RLA.W(l0.x, l0.y)
		w0.y = _ilel.height(w0.x, w0.z)
		var b0: Color = _ilel.biome_at(w0.x, w0.z)
		if b0.a > 0.3 or b0.b > 0.3 or b0.r > 0.5 or not _ok_spot(w0, 0.7, 0.6, 40.0):
			continue
		L["coquelicot"][0].append(_xfr(w0, 0.7, 1.2, 0.02))
	# ---------------------------------------------------------------- la prairie
	for i in range(int(9000 * q)):
		var p: Vector3 = _lp("", 0.7, 0.85)
		if p == Vector3.INF:
			continue
		var r2: float = _rng.randf()
		if r2 < 0.55:
			L["verte"][0].append(_xfr(p, 0.8, 1.5, 0.02))
		elif r2 < 0.8:
			L["seche"][0].append(_xfr(p, 0.8, 1.3, 0.02))
		elif r2 < 0.88:
			L["jaune"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		elif r2 < 0.93:
			L["marguerite"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		elif r2 < 0.97:
			L["violet"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		else:
			L["coquelicot"][0].append(_xfr(p, 0.8, 1.2, 0.02))
	for i2 in range(int(90 * q)):
		var pb: Vector3 = _lp("", 1.0, 0.6)
		if pb != Vector3.INF:
			L["buisson"][i2 % 2].append(_xfr(pb, 0.7, 1.3, 0.1))
	for i3 in range(int(18 * q) + 6):
		var pt: Vector3 = _lp("", 1.5, 0.45, 30.0)
		if pt != Vector3.INF:
			L["chene"][i3 % 3].append(_xfr(pt, 0.6, 0.9, 0.15))
			_trunk(pt, 0.35, 3.5)
	# ---------------------------------------------------------------- le Bois des Riffs
	for i4 in range(int(240 * q) + 30):
		var pw: Vector3 = _lp("bois", 1.5, 0.75, 60.0)
		if pw == Vector3.INF:
			continue
		if _rng.randf() < 0.62:
			L["chene"][i4 % 3].append(_xfr(pw, 0.7, 1.15, 0.15))
			_trunk(pw, 0.38, 3.8)
		else:
			L["bouleau"][i4 % 2].append(_xfr(pw, 0.75, 1.1, 0.15))
			_trunk(pw, 0.22, 3.5)
	for i5 in range(int(1400 * q)):
		var pf: Vector3 = _lp("bois", 1.2, 0.9, 60.0)
		if pf == Vector3.INF:
			continue
		if _rng.randf() < 0.45:
			L["fougere"][0].append(_xfr(pf, 0.8, 1.4, 0.05))
		else:
			L["verte"][0].append(_xfr(pf, 0.8, 1.3, 0.02))
	# ---------------------------------------------------------------- les jardins du camp (tournesols)
	for jd in jardins:
		var jc: Vector3 = jd[0]
		var jw: float = float(jd[1])
		var jh: float = float(jd[2])
		var ja: float = float(jd[3])
		var zz: float = -jh + 0.4
		while zz < jh:
			var xx: float = -jw + 0.4
			while xx < jw:
				var off: Vector2 = Vector2(xx, zz).rotated(ja)
				var wj: Vector3 = jc + Vector3(off.x, 0, off.y)
				wj.y = _ilel.height(wj.x, wj.z)
				L["tournesol"][int(absf(xx * 7.0 + zz * 3.0)) % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.4, 0.4)).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.1)), wj))
				xx += 0.75
			zz += 0.8
	# ---------------------------------------------------------------- la Mare aux Mantras
	for i6 in range(int(260 * q) + 40):
		var pm: Vector3 = _lp("mare", -1.0, 1.2, 8.0)
		if pm == Vector3.INF:
			continue
		L["roseau"][0].append(_xfr(pm, 0.8, 1.4, 0.05))
	var mc: Vector3 = RLA.W(float(RLA.MARE[0]), float(RLA.MARE[1]), float(RLA.MARE[3]) + 0.015)
	for i7 in range(22):
		var a7: float = _rng.randf() * TAU
		var r7: float = sqrt(_rng.randf()) * (float(RLA.MARE[2]) - 1.5)
		L["nenuphar"][0].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1, 1, 1) * _rng.randf_range(0.6, 1.2)), mc + Vector3(cos(a7), 0, sin(a7)) * r7))
	# ---------------------------------------------------------------- la Plage du Larsen
	for i8 in range(int(500 * q)):
		var pp: Vector3 = _lp("plage", 0.5, 0.6, 6.0)
		if pp == Vector3.INF:
			continue
		if _rng.randf() < 0.03 and L["palmier"][0].size() + L["palmier"][1].size() + L["palmier"][2].size() < 12:
			L["palmier"][i8 % 3].append(_xf(pp, _rng.randf_range(0.8, 1.05), 0.1))
			_trunk(pp, 0.25, 4.0)
		else:
			L["oyat"][0].append(_xfr(pp, 0.8, 1.4, 0.03))
	# ---------------------------------------------------------------- les maillages
	_emit_tiles("chanvre", hemp_mesh(0, 1), L["chanvre"][0], 0.0, 36.0, true)
	_emit_tiles("chanvre_loin", hemp_mesh(0, 0), L["chanvre"][0], 30.0, 420.0, false, 30.0)
	_emit_tiles("coquelicot", poppy_mesh(), L["coquelicot"][0], 0.0, 320.0, false, 24.0)
	_emit_tiles("bleuet", cornflower_mesh(), L["bleuet"][0], 0.0, 160.0, false, 24.0)
	_emit_tiles("marguerite", daisy_mesh(), L["marguerite"][0], 0.0, 90.0, false, 24.0)
	_emit_tiles("herbe_verte", lush_grass_mesh(), L["verte"][0], 0.0, 85.0, false, 30.0)
	_emit_tiles("herbe_seche", meadow_mesh(), L["seche"][0], 0.0, 85.0, false, 30.0)
	_emit("jaune_larsen", yellow_mesh(), L["jaune"][0], 70.0, false)
	_emit("violet_larsen", purple_mesh(), L["violet"][0], 70.0, false)
	for v in range(3):
		_emit("chene_larsen_%d" % v, Flora.tree(9140 + v, 8.5 + v * 1.5, 320), L["chene"][v], 600.0)
		_emit("palmier_larsen_%d" % v, _jungle("palmier", v), L["palmier"][v], 400.0)
	for v2 in range(2):
		_emit("bouleau_larsen_%d" % v2, _birch(v2), L["bouleau"][v2], 500.0)
		_emit("buisson_larsen_%d" % v2, Flora.bush(9150 + v2), L["buisson"][v2], 220.0)
		_emit("tournesol_larsen_%d" % v2, sunflower_mesh(v2), L["tournesol"][v2], 120.0)
	_emit("fougere_larsen", Flora.fern_clump(), L["fougere"][0], 90.0, false)
	_emit("roseau_larsen", Flora.reed_clump(), L["roseau"][0], 110.0, false)
	_emit("nenuphar_larsen", lily_mesh(), L["nenuphar"][0], 90.0, false)
	var oyat: ArrayMesh = Flora.grass_clump(14, 0.7, 0.025, 9160).duplicate()
	oyat.surface_set_material(0, _plain("oyat", Color(0.42, 0.42, 0.24), Color(0.78, 0.74, 0.5), 0.18))
	_emit("oyat_larsen", oyat, L["oyat"][0], 80.0, false)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V91: végétation de l'Île de Larsen ", placed, " en ", Time.get_ticks_msec() - t0, " ms")


## Un bouleau : un arbre plus élancé, au feuillage plus léger.
func _birch(variant: int) -> ArrayMesh:
	return Flora.tree(9170 + variant, 9.5, 190)

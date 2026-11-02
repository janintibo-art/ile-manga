extends "res://scripts/larsen_flore_v91.gd"
## V97 : la végétation de l'Île Al Dente (mêmes outils que les autres îles, instanciés par espèce dans
## des MultiMesh, découpés en carreaux pour les champs) :
##  - les Champs de Blé Dur : des épis serrés, dorés, avec leurs longues barbes ;
##  - la Tomateraie : des plants de tomates sur leurs tuteurs, chargés de fruits rouges ;
##  - le Jardin du Basilic : de gros pieds de basilic autour du parvis du temple ;
##  - l'Oliveraie, à l'est : de vieux oliviers ; des cyprès le long du chemin du temple et autour du
##    terre-plein ; quelques pins parasols derrière la plage ;
##  - le Mont Bolognaise : de l'herbe sèche en bas, des rochers de basalte, plus rien en haut (la cendre) ;
##  - ailleurs, la prairie : herbe grasse, herbe sèche, coquelicots et marguerites.

const RPA = preload("res://scripts/ile_pasta_v97.gd")

var _ilep: Node3D


# =================================================================== les plantes

## Une touffe de blé dur : des tiges droites, leurs feuilles fines, et l'épi au sommet, avec ses
## longues barbes. detail : 1 tout près, 0 de loin.
func ble_dur_mesh(variant: int, detail: int) -> ArrayMesh:
	var key := "ble_dur_%d_%d" % [variant, detail]
	if _mats.has(key):
		return _mats[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9720 + variant * 5 + detail
	var stems := _st()
	var ears := _st()
	var awns := _st()
	var n: int = 7 if detail == 1 else 5
	for s in range(n):
		var root := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		var h: float = rng.randf_range(0.95, 1.2)
		var lean := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		var segs: int = 4 if detail == 1 else 2
		for k in range(segs):
			var t0: float = float(k) / segs
			var t1: float = float(k + 1) / segs
			var c0: Vector3 = root + Vector3.UP * h * t0 + lean * t0 * t0
			var c1: Vector3 = root + Vector3.UP * h * t1 + lean * t1 * t1
			var side: Vector3 = Vector3(0.006, 0, 0.006)
			for v in [[c0 - side, t0], [c0 + side, t0], [c1 + side, t1], [c0 - side, t0], [c1 + side, t1], [c1 - side, t1]]:
				Flora._vertex(stems, v[0], Vector3(-0.7, 0.1, 0.7).normalized(), Vector2(0.5, float(v[1])), float(v[1]) * float(v[1]), 0.3)
		# deux feuilles fines, retombantes
		for lf in range(2 if detail == 1 else 1):
			var y: float = h * rng.randf_range(0.25, 0.5)
			var az: float = rng.randf() * TAU
			var out := Vector3(cos(az), 0, sin(az))
			var wv: Vector3 = out.cross(Vector3.UP) * 0.012
			var b0: Vector3 = root + Vector3.UP * y + lean * 0.2
			var mid: Vector3 = b0 + out * 0.16 + Vector3.UP * 0.1
			var tip: Vector3 = b0 + out * 0.32 - Vector3.UP * 0.02
			for v2 in [[b0 - wv, 0.2], [b0 + wv, 0.2], [mid + wv, 0.6], [b0 - wv, 0.2], [mid + wv, 0.6], [mid - wv, 0.6], [mid - wv, 0.6], [mid + wv, 0.6], [tip, 1.0]]:
				Flora._vertex(stems, v2[0], Vector3.UP, Vector2(0.5, float(v2[1])), float(v2[1]) * 0.5, 0.7)
		# l'épi : des épillets serrés, de part et d'autre, et leurs barbes
		var top: Vector3 = root + Vector3.UP * h + lean
		var ax: Vector3 = (Vector3.UP + lean * 0.8).normalized()
		var face := Vector3(cos(s * 1.7), 0, sin(s * 1.7))
		var right: Vector3 = face.cross(ax).normalized()
		var spk: int = 7 if detail == 1 else 4
		for e in range(spk):
			var t: float = float(e) / spk
			var c: Vector3 = top + ax * (0.015 + t * 0.075)
			for sd in [-1.0, 1.0]:
				var o: Vector3 = c + right * sd * 0.008
				var tipk: Vector3 = o + (ax * 0.9 + right * sd * 0.35).normalized() * 0.022
				var wk: Vector3 = face * 0.007
				for v3 in [[o - wk, 0.0], [o + wk, 0.0], [tipk, 1.0]]:
					Flora._vertex(ears, v3[0], face, Vector2(0.5, float(v3[1])), 0.9, 0.9)
				Flora._vertex(ears, o + wk * 0.9, -face, Vector2(0.5, 0.0), 0.9, 0.9)
				Flora._vertex(ears, o - wk * 0.9, -face, Vector2(0.5, 0.0), 0.9, 0.9)
				Flora._vertex(ears, tipk, -face, Vector2(0.5, 1.0), 0.9, 0.9)
				if detail == 1:
					# la barbe : un long fil très fin
					var aw: Vector3 = (ax + right * sd * 0.25).normalized()
					var w2: Vector3 = face * 0.0015
					var a0: Vector3 = tipk
					var a1: Vector3 = tipk + aw * rng.randf_range(0.09, 0.14)
					for v4 in [[a0 - w2, 0.0], [a0 + w2, 0.0], [a1, 1.0]]:
						Flora._vertex(awns, v4[0], face, Vector2(0.5, float(v4[1])), 1.0, 1.0)
	var mesh: ArrayMesh = stems.commit()
	mesh.surface_set_material(0, _plain("ble_dur_tige", Color(0.62, 0.55, 0.26), Color(0.9, 0.8, 0.46), 0.22))
	ears.commit(mesh)
	mesh.surface_set_material(1, _plain("ble_dur_epi", Color(0.78, 0.64, 0.3), Color(0.96, 0.84, 0.5), 0.24))
	if detail == 1:
		awns.commit(mesh)
		mesh.surface_set_material(2, _plain("ble_dur_barbe", Color(0.55, 0.42, 0.2), Color(0.3, 0.22, 0.12), 0.26))
	_mats[key] = mesh
	return mesh


## Un pied de basilic : des tiges courtes, des feuilles ovales, bombées, d'un vert brillant, par
## paires opposées, plus petites vers le haut.
func basil_mesh(variant: int) -> ArrayMesh:
	var key := "basilic_%d" % variant
	if _mats.has(key):
		return _mats[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9730 + variant
	var st := _st()
	for s in range(6):
		var root := Vector3(rng.randf_range(-0.1, 0.1), 0, rng.randf_range(-0.1, 0.1))
		var lean := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		var h: float = rng.randf_range(0.38, 0.55)
		for k in range(5):
			var t: float = 0.2 + 0.8 * k / 4.0
			var c: Vector3 = root + Vector3.UP * h * t + lean * t * h
			var size: float = lerpf(0.11, 0.05, t) * rng.randf_range(0.85, 1.15)
			for side in [0.0, PI]:
				var az: float = k * PI * 0.5 + side + s
				var out := Vector3(cos(az), 0.25, sin(az)).normalized()
				var wv: Vector3 = out.cross(Vector3.UP).normalized() * size * 0.42
				var tip: Vector3 = c + out * size * 1.6 - Vector3.UP * size * 0.25
				var mid: Vector3 = c + out * size * 0.8 + Vector3.UP * size * 0.12
				var nrm: Vector3 = wv.cross(out).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				var fl: float = t * 0.6
				for v in [[c, Vector2(0.5, 0.0)], [mid + wv, Vector2(1.0, 0.5)], [tip, Vector2(0.5, 1.0)], [c, Vector2(0.5, 0.0)], [tip, Vector2(0.5, 1.0)], [mid - wv, Vector2(0.0, 0.5)]]:
					Flora._vertex(st, v[0], (nrm + (v[0] - c) * 2.0).normalized(), v[1], fl, 0.8)
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, _plain("basilic", Color(0.1, 0.32, 0.06), Color(0.3, 0.62, 0.14), 0.1))
	_mats[key] = mesh
	return mesh


## Un plant de tomates sur son tuteur : la tige qui grimpe, de grandes feuilles découpées, des grappes
## de tomates (vertes, orange, rouges).
func tomato_mesh(variant: int) -> ArrayMesh:
	var key := "tomate_%d" % variant
	if _mats.has(key):
		return _mats[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9735 + variant
	var stake := _st()
	var leaves := _st()
	var fruits := _st()
	# le tuteur
	for q in range(4):
		var a0: float = TAU * q / 4.0 + 0.4
		var a1: float = TAU * (q + 1) / 4.0 + 0.4
		var d0 := Vector3(cos(a0), 0, sin(a0)) * 0.018
		var d1 := Vector3(cos(a1), 0, sin(a1)) * 0.018
		for v in [[d0, 0.0], [d1, 0.0], [d1 + Vector3.UP * 1.7, 1.0], [d0, 0.0], [d1 + Vector3.UP * 1.7, 1.0], [d0 + Vector3.UP * 1.7, 1.0]]:
			Flora._vertex(stake, v[0], ((v[0] as Vector3) * Vector3(1, 0, 1)).normalized(), Vector2(0.5, float(v[1])), 0.0, 0.0)
	# les feuilles, en couronnes le long du tuteur
	for k in range(9):
		var y: float = 0.15 + k * 0.17
		for j in range(5):
			var az: float = rng.randf() * TAU
			var out := Vector3(cos(az), rng.randf_range(-0.1, 0.25), sin(az)).normalized()
			var base := Vector3(0, y, 0) + out * 0.04
			var ll: float = rng.randf_range(0.22, 0.34)
			var wv: Vector3 = out.cross(Vector3.UP).normalized()
			var nrm: Vector3 = wv.cross(out).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			# une feuille composée : cinq folioles le long de la nervure
			for f in range(5):
				var t: float = 0.25 + f * 0.17
				var c: Vector3 = base + out * ll * t - Vector3.UP * ll * t * t * 0.35
				var sd: float = 1.0 if f % 2 == 0 else -1.0
				var lo: Vector3 = (wv * sd * 0.8 + out * 0.6).normalized()
				var sz: float = 0.12 * (1.1 - t * 0.4)
				var tip: Vector3 = c + lo * sz * 1.6
				var w2: Vector3 = lo.cross(nrm).normalized() * sz * 0.5
				for v2 in [[c, Vector2(0.5, 0)], [c + lo * sz * 0.7 + w2, Vector2(1, 0.5)], [tip, Vector2(0.5, 1)], [c, Vector2(0.5, 0)], [tip, Vector2(0.5, 1)], [c + lo * sz * 0.7 - w2, Vector2(0, 0.5)]]:
					Flora._vertex(leaves, v2[0], nrm, v2[1], 0.3 + y * 0.2, 0.8)
		# des grappes de tomates (une sphère à huit facettes)
		if k > 1 and k % 2 == 0:
			var ga: float = rng.randf() * TAU
			for g in range(3):
				var fc := Vector3(cos(ga + g * 0.6) * 0.14, y - 0.06 - g * 0.04, sin(ga + g * 0.6) * 0.14)
				var r: float = rng.randf_range(0.035, 0.055)
				var ripe: float = clampf(0.3 + k * 0.12 + rng.randf_range(-0.2, 0.2), 0.0, 1.0)
				for i in range(8):
					for jj in range(4):
						var p0: float = PI * jj / 4.0
						var p1: float = PI * (jj + 1) / 4.0
						var t0: float = TAU * i / 8.0
						var t1: float = TAU * (i + 1) / 8.0
						var dd: Array = [Vector3(sin(p0) * cos(t0), cos(p0) * 0.85, sin(p0) * sin(t0)), Vector3(sin(p0) * cos(t1), cos(p0) * 0.85, sin(p0) * sin(t1)),
							Vector3(sin(p1) * cos(t1), cos(p1) * 0.85, sin(p1) * sin(t1)), Vector3(sin(p1) * cos(t0), cos(p1) * 0.85, sin(p1) * sin(t0))]
						for idx in [0, 1, 2, 0, 2, 3]:
							var d: Vector3 = dd[idx]
							Flora._vertex(fruits, fc + d * r, d.normalized(), Vector2(ripe, 0.5), 0.2, 0.0)
	var mesh: ArrayMesh = stake.commit()
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.55, 0.42, 0.28)
	sm.roughness = 0.9
	mesh.surface_set_material(0, sm)
	leaves.commit(mesh)
	mesh.surface_set_material(1, _plain("tomate_feuille", Color(0.08, 0.22, 0.05), Color(0.2, 0.42, 0.1), 0.08))
	fruits.commit(mesh)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.78, 0.1, 0.05)
	fm.roughness = 0.25
	fm.metallic_specular = 0.6
	mesh.surface_set_material(2, fm)
	_mats[key] = mesh
	return mesh


# =================================================================== où planter

func _block_paths_p() -> void:
	for k in _ilep.paths_world:
		for p in _ilep.paths_world[k]:
			var l: Vector2 = RPA.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true
	for f in _ilep.flows_world:
		for p2 in _ilep.flows_world[f]:
			var l2: Vector2 = RPA.L((p2 as Vector3).x, (p2 as Vector3).z)
			for dx2 in range(-3, 4):
				for dz2 in range(-3, 4):
					_blocked[_cell(l2 + Vector2(dx2, dz2) * 1.2)] = true


## want : "" (la prairie), "olive" (l'Oliveraie, à l'est), "plage", "volcan" (le bas des pentes),
## "basilic" (autour du terre-plein du temple).
func _pp(want: String, min_h: float, max_slope: float, max_h: float = 40.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"plage":
				l = RPA.PLAGE + Vector2(_rng.randf_range(-70.0, 70.0), _rng.randf_range(-16.0, 10.0))
			"olive":
				l = Vector2(_rng.randf_range(45.0, 150.0), _rng.randf_range(35.0, 135.0))
			"volcan":
				var a: float = _rng.randf() * TAU
				l = Vector2(float(RPA.VOLCAN[0]), float(RPA.VOLCAN[1])) + Vector2(cos(a), sin(a)) * _rng.randf_range(62.0, 120.0)
			"basilic":
				var a2: float = _rng.randf() * TAU
				var tp: Array = RPA.PADS["temple"]
				l = Vector2(float(tp[0]), float(tp[1])) + Vector2(cos(a2), sin(a2)) * _rng.randf_range(float(tp[2]) - 3.0, float(tp[2]) + 6.0)
			_:
				l = Vector2(_rng.randf_range(-RPA.HALF + 4.0, RPA.HALF - 4.0), _rng.randf_range(-RPA.HALF + 4.0, RPA.HALF - 4.0))
		if _blocked.has(_cell(l)):
			continue
		if RPA.coast_q(l.x, l.y) > 0.985:
			continue
		if RPA.champ_at(l.x, l.y) != "":
			continue
		var w3: Vector3 = RPA.W(l.x, l.y)
		w3.y = _ilep.height(w3.x, w3.z)
		if _ilep.sauce_stain(w3.x, w3.z) > 0.25:
			continue
		var vd: float = RPA.volcan_d(l.x, l.y)
		if want != "volcan" and vd < float(RPA.VOLCAN[3]) - 10.0:
			continue
		var b: Color = _ilep.biome_at(w3.x, w3.z)
		match want:
			"plage":
				if b.b < 0.3:
					continue
			"volcan":
				if b.g > 0.4:
					continue
			_:
				if b.r > 0.35 or b.a > 0.3 or b.b > 0.3 or b.g > 0.5:
					continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


# =================================================================== plantation

func build_pasta(island: Node3D, high_quality: bool) -> void:
	_ilep = island
	_ilel = island
	_ilemo = island
	_ileb = island
	_ilem = island
	ile = island
	_rng.seed = 9700
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_p()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_al_dente_v97"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"ble": [[]], "basilic": [[], []], "tomate": [[], []], "olivier": [[], [], []], "cypres": [[], []], "pin": [[], []],
		"verte": [[]], "seche": [[]], "coquelicot": [[]], "marguerite": [[]], "jaune": [[]], "oyat": [[]], "buisson": [[], []], "roche": []}
	# ---------------------------------------------------------------- les Champs de Blé Dur
	for k in RPA.CHAMPS:
		var c: Array = RPA.CHAMPS[k]
		var cx: float = float(c[0])
		var cz: float = float(c[1])
		var hw: float = float(c[2])
		var hd: float = float(c[3])
		var ang: float = float(c[4])
		var step: float = 0.42 / sqrt(q)
		var row: float = 0.42 / sqrt(q)
		var z: float = -hd + row * 0.5
		while z < hd:
			var lane: bool = fmod(z + hd, 10.0) < 1.1 and absf(z) > 2.0
			var x: float = -hw + step * 0.5
			while x < hw:
				var jit := Vector2(_rng.randf_range(-0.25, 0.25) * step, _rng.randf_range(-0.2, 0.2) * row)
				var lp: Vector2 = Vector2(x, z) + jit
				var l: Vector2 = Vector2(cx, cz) + lp.rotated(ang)
				x += step
				if lane or _blocked.has(_cell(l)):
					continue
				var w: Vector3 = RPA.W(l.x, l.y)
				w.y = _ilep.height(w.x, w.z)
				if w.y < 0.4:
					continue
				var edge: float = minf(hw - absf(lp.x), hd - absf(lp.y))
				if edge < 1.0 and _rng.randf() < 0.5:
					continue
				L["ble"][0].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1, _rng.randf_range(0.88, 1.1), 1)), w - Vector3.UP * 0.03))
				if _rng.randf() < 0.02:
					L["coquelicot"][0].append(_xfr(w + Vector3(0.1, 0, 0.1), 0.8, 1.2, 0.02))
			z += row
	# ---------------------------------------------------------------- la Tomateraie
	var tp: Array = RPA.PADS["tomateraie"]
	var tc := Vector2(float(tp[0]), float(tp[1]))
	var zz: float = -float(tp[2]) + 2.0
	while zz < float(tp[2]) - 2.0:
		var xx: float = -float(tp[2]) + 2.0
		while xx < float(tp[2]) - 2.0:
			if Vector2(xx, zz).length() < float(tp[2]) - 1.8 and fmod(absf(xx) + 0.5, 2.6) > 0.6:
				var wt: Vector3 = RPA.W(tc.x + xx, tc.y + zz)
				wt.y = _ilep.height(wt.x, wt.z)
				L["tomate"][int(absf(xx * 3.0 + zz)) % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.9, 1.1)), wt))
			xx += 0.9
		zz += 2.6
	# ---------------------------------------------------------------- le Jardin du Basilic
	for i in range(int(420 * q) + 60):
		var pb: Vector3 = _pp("basilic", 0.6, 0.6)
		if pb == Vector3.INF:
			continue
		L["basilic"][i % 2].append(_xfr(pb, 1.4, 2.4, 0.03))
	# ---------------------------------------------------------------- l'Oliveraie, les cyprès, les pins
	for i2 in range(int(120 * q) + 30):
		var po: Vector3 = _pp("olive", 1.0, 0.5)
		if po == Vector3.INF:
			continue
		L["olivier"][i2 % 3].append(_xf(po, _rng.randf_range(0.85, 1.15)))
		_trunk(po, 0.35, 2.6)
	# les cyprès : en double rangée le long du chemin du temple, et en couronne autour du terre-plein
	var tpath: Array = _ilep.paths_world["temple"]
	for k2 in range(0, tpath.size(), 4):
		var cp: Vector3 = tpath[k2]
		var nxt: Vector3 = tpath[mini(k2 + 1, tpath.size() - 1)]
		var dir: Vector3 = (nxt - cp).normalized()
		var side: Vector3 = Vector3(dir.x, 0, dir.z).cross(Vector3.UP).normalized()
		for sd in [-1.0, 1.0]:
			var p2: Vector3 = cp + side * sd * 3.4
			p2.y = _ilep.height(p2.x, p2.z)
			# V98 : pas de cyprès devant les maisons du Borgo (ni dans leurs murs)
			var libre: bool = true
			for a in avoid:
				if Vector2(p2.x, p2.z).distance_to(a[0]) < float(a[1]) + 1.5:
					libre = false
			if not libre:
				continue
			L["cypres"][k2 % 2].append(_xf(p2, _rng.randf_range(0.9, 1.1)))
			_trunk(p2, 0.3, 3.0)
	var tpd: Array = RPA.PADS["temple"]
	var door := Vector2(RPA.PORTE_DIR.x, RPA.PORTE_DIR.y).normalized()
	for k3 in range(22):
		var a3: float = TAU * k3 / 22.0
		var dd := Vector2(cos(a3), sin(a3))
		if dd.dot(door) > 0.82:
			continue
		var l3: Vector2 = Vector2(float(tpd[0]), float(tpd[1])) + dd * (float(tpd[2]) + 1.0)
		var w3: Vector3 = RPA.W(l3.x, l3.y)
		w3.y = _ilep.height(w3.x, w3.z)
		if _ok_spot(w3, 1.0, 0.5, 30.0):
			L["cypres"][k3 % 2].append(_xf(w3, _rng.randf_range(0.95, 1.2)))
			_trunk(w3, 0.3, 3.0)
	for i3 in range(int(14 * q) + 6):
		var pp: Vector3 = _pp("plage", 1.2, 0.5, 8.0)
		if pp == Vector3.INF:
			continue
		var bb: Color = _ilep.biome_at(pp.x, pp.z)
		if bb.b > 0.85:
			continue
		L["pin"][i3 % 2].append(_xf(pp, _rng.randf_range(0.75, 1.0)))
		_trunk(pp, 0.3, 4.0)
	# ---------------------------------------------------------------- le bas du volcan
	for i4 in range(int(1500 * q)):
		var pv: Vector3 = _pp("volcan", 1.0, 0.9, 30.0)
		if pv == Vector3.INF:
			continue
		L["seche"][0].append(_xfr(pv, 0.7, 1.2, 0.02))
	for i5 in range(int(70 * q) + 20):
		var pr: Vector3 = _pp("volcan", 2.0, 1.2, 50.0)
		if pr == Vector3.INF:
			continue
		L["roche"].append(Transform3D(Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pr - Vector3.UP * 0.25))
	# ---------------------------------------------------------------- la prairie
	for i6 in range(int(9000 * q)):
		var p: Vector3 = _pp("", 0.7, 0.85)
		if p == Vector3.INF:
			continue
		var r2: float = _rng.randf()
		if r2 < 0.5:
			L["verte"][0].append(_xfr(p, 0.8, 1.5, 0.02))
		elif r2 < 0.82:
			L["seche"][0].append(_xfr(p, 0.8, 1.3, 0.02))
		elif r2 < 0.89:
			L["jaune"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		elif r2 < 0.95:
			L["marguerite"][0].append(_xfr(p, 0.8, 1.2, 0.02))
		else:
			L["coquelicot"][0].append(_xfr(p, 0.8, 1.2, 0.02))
	for i7 in range(int(80 * q)):
		var pb2: Vector3 = _pp("", 1.0, 0.6)
		if pb2 != Vector3.INF:
			L["buisson"][i7 % 2].append(_xfr(pb2, 0.7, 1.2, 0.1))
	for i8 in range(int(500 * q)):
		var ps: Vector3 = _pp("plage", 0.5, 0.6, 6.0)
		if ps != Vector3.INF:
			L["oyat"][0].append(_xfr(ps, 0.8, 1.4, 0.03))
	# ---------------------------------------------------------------- les maillages
	_emit_tiles("ble_dur", ble_dur_mesh(0, 1), L["ble"][0], 0.0, 30.0, true)
	_emit_tiles("ble_dur_loin", ble_dur_mesh(0, 0), L["ble"][0], 25.0, 380.0, false, 30.0)
	for v in range(2):
		_emit("basilic_%d" % v, basil_mesh(v), L["basilic"][v], 120.0, false)
		_emit("tomate_%d" % v, tomato_mesh(v), L["tomate"][v], 150.0, true)
		_emit("cypres_dente_%d" % v, cypress_mesh(v), L["cypres"][v], 700.0)
		_emit("pin_dente_%d" % v, pine_mesh(v), L["pin"][v], 700.0)
		_emit("buisson_dente_%d" % v, Flora.bush(9750 + v), L["buisson"][v], 220.0)
	for v2 in range(3):
		_emit("olivier_dente_%d" % v2, olive_mesh(v2), L["olivier"][v2], 520.0)
	_emit_tiles("coquelicot_d", poppy_mesh(), L["coquelicot"][0], 0.0, 260.0, false, 24.0)
	_emit_tiles("marguerite_d", daisy_mesh(), L["marguerite"][0], 0.0, 90.0, false, 24.0)
	_emit_tiles("herbe_verte_d", lush_grass_mesh(), L["verte"][0], 0.0, 85.0, false, 30.0)
	_emit_tiles("herbe_seche_d", meadow_mesh(), L["seche"][0], 0.0, 85.0, false, 30.0)
	_emit("jaune_dente", yellow_mesh(), L["jaune"][0], 70.0, false)
	var oyat: ArrayMesh = Flora.grass_clump(14, 0.7, 0.025, 9760).duplicate()
	oyat.surface_set_material(0, _plain("oyat_dente", Color(0.42, 0.42, 0.24), Color(0.78, 0.74, 0.5), 0.18))
	_emit("oyat_dente", oyat, L["oyat"][0], 80.0, false)
	_rock_mm("basalte_dente", Color(0.2, 0.19, 0.19), 0.0, L["roche"], 4, Vector3(2.2, 1.4, 2.0), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V97: végétation de l'Île Al Dente ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

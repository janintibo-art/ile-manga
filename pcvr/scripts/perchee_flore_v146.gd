extends "res://scripts/grande_flore_v59.gd"
## V146 : la végétation de l'Île Perchée (mêmes outils que les autres îles, instanciés par espèce dans
## des MultiMesh) : une prairie d'herbe blonde qui ondule, des armoises argentées, des pins ponderosa en
## bosquets, des cotonniers le long du ruisseau et autour de l'Abreuvoir (avec des roseaux), des genévriers
## au pied des mesas, des cactus-cierges (les saguaros), des figuiers de Barbarie et des agaves sur la
## terre rouge, quelques arbres morts blanchis, des fleurs des prés (pavots orange, lupins violets,
## tournesols sauvages), des blocs de grès éboulés.

const IleP = preload("res://scripts/ile_perchee_v146.gd")
const HERBE_CELL: float = 24.0

var pc: bool = true
var interdits: Array = []                # [Rect2 (île)] : le bourg, les rues
var counts: Dictionary = {}


func plante(island: Node3D, high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	ile = island
	pc = high_quality
	_rng.seed = 14660
	var cols := StaticBody3D.new()
	cols.name = "Flore_perchee_collisions"
	cols.collision_layer = 1
	cols.collision_mask = 0
	add_child(cols)
	# le bourg : les rangées de maisons, la rue du Pique, la chapelle, le corral, le château d'eau
	interdits = [Rect2(-48.0, -34.0, 216.0, 68.0), Rect2(34.0, -114.0, 52.0, 230.0), Rect2(132.0, 30.0, 34.0, 32.0),
		Rect2(96.0, -56.0, 26.0, 22.0), Rect2(-34.0, -54.0, 20.0, 20.0), Rect2(138.0, -48.0, 28.0, 26.0)]
	var L := {"pin": [[], []], "coton": [[], []], "genevrier": [[], []], "saguaro": [[], []], "figuier": [[], []], "agave": [[], []],
		"armoise": [[], []], "mort": [[]], "roseau": [[]], "pavot": [[]], "lupin": [[]], "tournesol": [[]], "bloc": [[], []]}
	# les pins : des bosquets au nord-ouest, au nord-est, au sud
	for g in [[Vector2(-60.0, -130.0), 26.0, 12], [Vector2(130.0, -120.0), 30.0, 12], [Vector2(-120.0, 130.0), 28.0, 10],
			[Vector2(100.0, 150.0), 22.0, 7], [Vector2(-180.0, -40.0), 20.0, 6], [Vector2(170.0, -60.0), 18.0, 5]]:
		for k in range(int(g[2])):
			var q: Vector2 = (g[0] as Vector2) + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * float(g[1])
			var p: Vector3 = _point(q, 6.0)
			if p == Vector3.INF:
				continue
			L["pin"][k % 2].append(_xf(p, _rng.randf_range(0.7, 1.05), 0.15))
			_col(cols, p, 0.4, 6.0)
	# les cotonniers : le long du ruisseau et autour de l'Abreuvoir
	for i in range(18):
		var q2: Vector2
		if i < 11:
			var rd: Vector2 = IleP.RUISSEAU[i % (IleP.RUISSEAU.size() - 1)]
			q2 = rd + Vector2(_rng.randf_range(-9.0, 9.0), _rng.randf_range(-9.0, 9.0))
			if ile.ruisseau_dist(q2).x < 5.0:
				q2 += (q2 - rd).normalized() * 5.0
		else:
			var a: float = _rng.randf() * TAU
			q2 = IleP.ABREUVOIR + Vector2(cos(a), sin(a)) * _rng.randf_range(IleP.ABREUVOIR_R + 5.0, IleP.ABREUVOIR_R + 12.0)
		var p2: Vector3 = _point(q2, 5.0)
		if p2 == Vector3.INF:
			continue
		L["coton"][i % 2].append(_xf(p2, _rng.randf_range(0.8, 1.1), 0.15))
		_col(cols, p2, 0.45, 5.0)
	# les roseaux de l'Abreuvoir et du ruisseau
	for k2 in range(70 if pc else 36):
		var a2: float = _rng.randf() * TAU
		var q3: Vector2 = IleP.ABREUVOIR + Vector2(cos(a2), sin(a2)) * _rng.randf_range(IleP.ABREUVOIR_R - 3.0, IleP.ABREUVOIR_R + 1.0)
		if k2 % 3 == 0:
			var rd2: Vector2 = IleP.RUISSEAU[_rng.randi() % (IleP.RUISSEAU.size() - 2)]
			q3 = rd2 + Vector2(_rng.randf_range(-3.5, 3.5), _rng.randf_range(-3.5, 3.5))
		var w3: Vector3 = IleP.W(q3.x, q3.y)
		var h3: float = ile.height(w3.x, w3.z)
		if h3 < -1e6:
			continue
		L["roseau"][0].append(_xf(Vector3(w3.x, h3, w3.z), _rng.randf_range(1.0, 1.6), 0.05))
	# au pied des mesas : des genévriers, des blocs éboulés, des agaves
	for m in IleP.MESAS + IleP.AIGUILLES:
		var c: Vector2 = m[0]
		var r: float = float(m[1])
		for k3 in range(int(r * 0.7) + 4):
			var a3: float = _rng.randf() * TAU
			var q4: Vector2 = c + Vector2(cos(a3), sin(a3)) * (r + _rng.randf_range(4.0, 22.0))
			var p4: Vector3 = _point(q4, 1.5)
			if p4 == Vector3.INF:
				continue
			match k3 % 4:
				0, 1:
					L["genevrier"][k3 % 2].append(_xf(p4, _rng.randf_range(1.6, 2.6), 0.1))
				2:
					L["bloc"][k3 % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * _rng.randf_range(0.8, 2.4)), p4 - Vector3.UP * 0.3))
					_col(cols, p4, 0.8, 1.4)
				_:
					L["agave"][k3 % 2].append(_xf(p4, _rng.randf_range(0.8, 1.4), 0.05))
	# la terre rouge et la prairie sèche : les saguaros, les figuiers, les agaves, les armoises
	var n_sec: int = 900 if pc else 520
	for k4 in range(n_sec):
		var a4: float = _rng.randf() * TAU
		var q5: Vector2 = Vector2(cos(a4), sin(a4)) * sqrt(_rng.randf()) * (IleP.R0 - 12.0)
		var p5: Vector3 = _point(q5, 2.0)
		if p5 == Vector3.INF:
			continue
		var bio: Color = ile.biome_at(p5.x, p5.z)
		if bio.b > 0.4:
			continue
		var rouge: bool = bio.g > 0.3
		var t: float = _rng.randf()
		if rouge:
			if t < 0.14:
				L["saguaro"][k4 % 2].append(_xf(p5, _rng.randf_range(0.8, 1.3), 0.05))
				_col(cols, p5, 0.35, 4.0)
			elif t < 0.42:
				L["figuier"][k4 % 2].append(_xf(p5, _rng.randf_range(1.6, 2.8), 0.02))
			elif t < 0.62:
				L["agave"][k4 % 2].append(_xf(p5, _rng.randf_range(0.8, 1.3), 0.05))
			else:
				L["armoise"][k4 % 2].append(_xf(p5, _rng.randf_range(0.7, 1.2), 0.05))
		else:
			if t < 0.03:
				L["saguaro"][k4 % 2].append(_xf(p5, _rng.randf_range(0.8, 1.2), 0.05))
				_col(cols, p5, 0.35, 4.0)
			elif t < 0.08:
				L["figuier"][k4 % 2].append(_xf(p5, _rng.randf_range(1.4, 2.2), 0.02))
			elif t < 0.1:
				L["mort"][0].append(_xf(p5, _rng.randf_range(0.9, 1.3), 0.1))
			elif t < 0.6:
				L["armoise"][k4 % 2].append(_xf(p5, _rng.randf_range(0.7, 1.3), 0.05))
	# les fleurs : par massifs, dans la prairie et près de l'eau
	for k5 in range(46 if pc else 28):
		var a5: float = _rng.randf() * TAU
		var c5: Vector2 = Vector2(cos(a5), sin(a5)) * sqrt(_rng.randf()) * (IleP.R0 - 20.0)
		if k5 % 3 == 0:
			c5 = IleP.ABREUVOIR + Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-30.0, 30.0))
		var kind: String = ["pavot", "lupin", "tournesol", "pavot", "lupin"][k5 % 5]
		for k6 in range(_rng.randi_range(8, 18)):
			var q6: Vector2 = c5 + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-6.0, 6.0))
			var p6: Vector3 = _point(q6, 0.5)
			if p6 == Vector3.INF:
				continue
			L[kind][0].append(_xf(p6, _rng.randf_range(0.8, 1.3) * (1.6 if kind == "tournesol" else 1.0), 0.02))
	# les maillages
	_emit("perchee_pin_0", _pin(0), L["pin"][0], 700.0)
	_emit("perchee_pin_1", _pin(1), L["pin"][1], 700.0)
	_emit("perchee_coton_0", _coton(0), L["coton"][0], 600.0)
	_emit("perchee_coton_1", _coton(1), L["coton"][1], 600.0)
	for v in range(2):
		_emit("perchee_genevrier_%d" % v, _genevrier(v), L["genevrier"][v], 300.0)
		_emit("perchee_saguaro_%d" % v, cactus_mesh(v + 4), L["saguaro"][v], 400.0)
		_emit("perchee_figuier_%d" % v, figuier_mesh(v), L["figuier"][v], 160.0)
		_emit("perchee_agave_%d" % v, agave_mesh(v + 6), L["agave"][v], 160.0)
		_emit("perchee_armoise_%d" % v, _armoise(v), L["armoise"][v], 140.0, false)
		_emit("perchee_bloc_%d" % v, _bloc(v), L["bloc"][v], 500.0)
	_emit("perchee_mort", dead_tree_mesh(3), L["mort"][0], 400.0)
	_emit("perchee_roseau", Flora.reed_clump(), L["roseau"][0], 120.0, false)
	_emit("perchee_pavot", _fleur(Color(1.0, 0.55, 0.12)), L["pavot"][0], 110.0, false)
	_emit("perchee_lupin", _fleur(Color(0.62, 0.42, 0.95)), L["lupin"][0], 110.0, false)
	_emit("perchee_tournesol", _fleur(Color(1.0, 0.85, 0.15)), L["tournesol"][0], 110.0, false)
	_herbe()
	counts = placed.duplicate()
	print("ILE_MANGA_V146: la végétation de l'Île Perchée (%d ms) %s" % [Time.get_ticks_msec() - t0, str(counts)])


## Un point de l'île où planter (repère monde), ou INF : hors de l'île, dans l'eau, dans le bourg, sur
## un chemin, sur une falaise, trop près du bord.
func _point(q: Vector2, marge: float) -> Vector3:
	for r in interdits:
		if (r as Rect2).grow(marge).has_point(q):
			return Vector3.INF
	var th: float = atan2(q.y, q.x)
	if q.length() > ile.coast_radius(th) - 9.0:
		return Vector3.INF
	var w: Vector3 = IleP.W(q.x, q.y)
	var h: float = ile.height(w.x, w.z)
	if h < -1e6:
		return Vector3.INF
	if ile.in_water(w.x, w.z) or ile.ruisseau_dist(q).x < 3.0 or q.distance_to(IleP.ABREUVOIR) < IleP.ABREUVOIR_R + 1.5:
		return Vector3.INF
	var bio: Color = ile.biome_at(w.x, w.z)
	if bio.r > 0.3 or bio.a > 0.3:
		return Vector3.INF
	# la pente (pas sur les falaises des mesas)
	var hx: float = ile.height(w.x + 1.0, w.z)
	var hz: float = ile.height(w.x, w.z + 1.0)
	if hx < -1e6 or hz < -1e6 or absf(hx - h) > 0.7 or absf(hz - h) > 0.7:
		return Vector3.INF
	return Vector3(w.x, h, w.z)


func _col(cols: StaticBody3D, at: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	cs.shape = c
	cs.position = at + Vector3.UP * h * 0.5
	cols.add_child(cs)


## Un pin des montagnes de l'Ouest : l'épicéa de la grande île (un cône sombre), un peu plus clair.
func _pin(v: int) -> ArrayMesh:
	var m: ArrayMesh = fir_mesh(v + 4).duplicate()
	if m.get_surface_count() > 1 and m.surface_get_material(1) is ShaderMaterial:
		var lf: ShaderMaterial = (m.surface_get_material(1) as ShaderMaterial).duplicate()
		lf.set_shader_parameter("tint", Color(0.7, 0.86, 0.64))
		m.surface_set_material(1, lf)
	return m


## Un cotonnier (le peuplier de l'Ouest) : le platane de Port-Azur, d'un vert-jaune lumineux.
func _coton(v: int) -> ArrayMesh:
	var m: ArrayMesh = plane_mesh(v + 6).duplicate()
	var lf: ShaderMaterial = (m.surface_get_material(1) as ShaderMaterial).duplicate()
	lf.set_shader_parameter("tint", Color(1.12, 1.15, 0.72))
	m.surface_set_material(1, lf)
	return m


## Un genévrier : un buisson dense, vert-bleu sombre, plus haut que large.
func _genevrier(v: int) -> ArrayMesh:
	var m: ArrayMesh = shrub_mesh("maquis", v + 20).duplicate()
	var lf: ShaderMaterial = (m.surface_get_material(1) as ShaderMaterial).duplicate()
	lf.set_shader_parameter("tint", Color(0.42, 0.62, 0.5))
	m.surface_set_material(1, lf)
	return m


## Une armoise : une boule de feuillage gris argenté.
func _armoise(v: int) -> ArrayMesh:
	var m: ArrayMesh = shrub_mesh("maquis", v + 30).duplicate()
	var lf: ShaderMaterial = (m.surface_get_material(1) as ShaderMaterial).duplicate()
	lf.set_shader_parameter("tint", Color(0.95, 1.0, 0.88))
	m.surface_set_material(1, lf)
	return m


func _fleur(c: Color) -> ArrayMesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(c))
	return m


## Un bloc de grès rouge éboulé (un polyèdre cabossé).
func _bloc(v: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14670 + v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 7
	var half: int = 4
	var grid: Array = []
	for j in range(half + 1):
		var row: Array = []
		for i in range(seg):
			var th: float = PI * j / half
			var ph: float = TAU * i / seg
			var d := Vector3(sin(th) * cos(ph), cos(th) * 0.62, sin(th) * sin(ph))
			row.append(d * rng.randf_range(0.8, 1.15) * Vector3(1.2, 1.0, 0.9))
		grid.append(row)
	for j2 in range(half):
		for i2 in range(seg):
			var a: Vector3 = grid[j2][i2]
			var b: Vector3 = grid[j2][(i2 + 1) % seg]
			var c: Vector3 = grid[j2 + 1][i2]
			var d2: Vector3 = grid[j2 + 1][(i2 + 1) % seg]
			for tri in [[a, c, b], [b, c, d2]]:
				var n: Vector3 = ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3)).normalized()
				if n.dot(tri[0]) < 0.0:
					n = -n
				for p in tri:
					st.set_normal(n)
					st.set_uv(Vector2(p.x + p.z, p.y))
					st.add_vertex(p)
	st.generate_tangents()
	var mesh := st.commit()
	var mat: StandardMaterial3D = load("res://scripts/perchee_kit_v146.gd").mat("pierre")
	mesh.surface_set_material(0, mat)
	return mesh


## Un figuier de Barbarie (nopal) : des raquettes ovales empilées, des fruits rouges.
func figuier_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14680 + variant
	var pads := _st()
	var fruits := _st()
	var frontier: Array = [[Vector3.ZERO, rng.randf() * TAU, 0]]
	var count: int = 0
	while not frontier.is_empty() and count < 18:
		var f: Array = frontier.pop_front()
		var base: Vector3 = f[0]
		var yaw: float = float(f[1])
		var depth: int = int(f[2])
		var tilt: float = rng.randf_range(-0.5, 0.5)
		var up := Vector3(sin(tilt) * cos(yaw), cos(tilt), sin(tilt) * sin(yaw)).normalized()
		var side := Vector3(-sin(yaw + PI * 0.5), 0, cos(yaw + PI * 0.5))
		var h: float = rng.randf_range(0.32, 0.45)
		var w: float = h * 0.62
		var c: Vector3 = base + up * h * 0.5
		var nrm: Vector3 = side.cross(up).normalized()
		for k in range(10):
			var a0: float = TAU * k / 10.0
			var a1: float = TAU * (k + 1) / 10.0
			var p0: Vector3 = c + side * cos(a0) * w * 0.5 + up * sin(a0) * h * 0.5
			var p1: Vector3 = c + side * cos(a1) * w * 0.5 + up * sin(a1) * h * 0.5
			for v in [c + nrm * 0.03, p0, p1, c - nrm * 0.03, p1, p0]:
				Flora._vertex(pads, v, nrm if (v - c).dot(nrm) >= 0.0 else -nrm, Vector2(0.5, 0.5), 0.0, 0.5)
		count += 1
		if depth < 3:
			for b in range(rng.randi_range(1, 2)):
				frontier.append([c + up * h * 0.45 + side * rng.randf_range(-0.1, 0.1), yaw + rng.randf_range(-1.2, 1.2), depth + 1])
		elif rng.randf() < 0.7:
			var top: Vector3 = c + up * h * 0.5
			Flora._tube(fruits, [top, top + Vector3.UP * 0.07] as Array[Vector3], [0.035, 0.03] as Array[float], [0.0, 0.0] as Array[float], 6)
	return _finish([[pads, _plain("figuier", Color(0.26, 0.42, 0.24), Color(0.44, 0.58, 0.32), 0.0)], [fruits, _plain("figue", Color(0.72, 0.12, 0.24), Color(0.9, 0.32, 0.36), 0.0)]])


## L'herbe blonde de la prairie : des touffes par carrés de 24 m, visibles de près seulement ; plus
## verte près de l'eau.
func _herbe() -> void:
	var seche: Mesh = grass_mesh()
	var verte: ArrayMesh = Flora.grass_clump(14, 0.6, 0.045, 61).duplicate()
	verte.surface_set_material(0, _plain("herbe_verte_perchee", Color(0.2, 0.32, 0.1), Color(0.55, 0.62, 0.28), 0.14))
	var haute: ArrayMesh = Flora.grass_clump(16, 0.85, 0.04, 63).duplicate()
	haute.surface_set_material(0, _plain("herbe_blonde_perchee", Color(0.42, 0.36, 0.16), Color(0.93, 0.8, 0.46), 0.2))
	var meshes: Array = [seche, haute, verte]
	var density: float = 0.4 if pc else 0.18
	var half: float = IleP.R0 + 20.0
	var n_cells: int = int(ceil(half * 2.0 / HERBE_CELL))
	var total: int = 0
	for cz in range(n_cells):
		for cx in range(n_cells):
			var x0: float = -half + cx * HERBE_CELL
			var z0: float = -half + cz * HERBE_CELL
			var mid := Vector2(x0 + HERBE_CELL * 0.5, z0 + HERBE_CELL * 0.5)
			if mid.length() > IleP.R0 + 20.0:
				continue
			var lists: Array = [[], [], []]
			for k in range(int(HERBE_CELL * HERBE_CELL * density)):
				var q := Vector2(x0 + _rng.randf() * HERBE_CELL, z0 + _rng.randf() * HERBE_CELL)
				var p: Vector3 = _point(q, -1.0)
				if p == Vector3.INF:
					continue
				var bio: Color = ile.biome_at(p.x, p.z)
				if bio.g > 0.55 and _rng.randf() < 0.75:
					continue
				var which: int = 2 if bio.b > 0.3 else (1 if _rng.randf() < 0.35 else 0)
				lists[which].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.8, 1.2), 1.0) * _rng.randf_range(1.1, 1.7)), p - Vector3.UP * 0.03))
			for w in range(3):
				var xfs: Array = lists[w]
				if xfs.is_empty():
					continue
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = meshes[w]
				mm.instance_count = xfs.size()
				for i in range(xfs.size()):
					mm.set_instance_transform(i, xfs[i])
				var mi := MultiMeshInstance3D.new()
				mi.name = "Herbe_perchee_%d_%d_%d" % [cx, cz, w]
				mi.multimesh = mm
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.visibility_range_end = 80.0 if pc else 50.0
				mi.visibility_range_end_margin = 15.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				add_child(mi)
				total += xfs.size()
	placed["herbe"] = total

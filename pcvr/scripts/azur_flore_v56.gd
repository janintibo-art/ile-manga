extends Node3D
## V56 : la végétation méditerranéenne de Port-Azur — pins parasols, oliviers, cyprès,
## platanes de la place, palmiers du front de mer, lauriers-roses, bougainvilliers,
## agaves de la pointe et touffes d'herbe blonde. Tout est instancié (MultiMesh) par
## espèce ; les maillages sont fabriqués ici (troncs en tubes, feuillage en cartes, comme
## flora_v25.gd).

const Flora = preload("res://scripts/flora_v25.gd")
const JungleFlora = preload("res://scripts/jungle_flora_v30.gd")
const A := "res://assets/textures/azur/"

var ile: Node3D                        # ile_azur_v56.gd
var avoid: Array = []                  # [Vector2 monde, rayon] : zones sans arbres (maisons, chemins)
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}
var _jf: Node3D
var placed: Dictionary = {}            # espèce -> nombre


func _foliage(key: String, tex: String, wind: float, transl: float, tint: Color = Color(1, 1, 1)) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(Flora.FOLIAGE_SHADER)
	m.set_shader_parameter("albedo_tex", load(A + tex))
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", transl)
	if tint != Color(1, 1, 1):
		m.set_shader_parameter("tint", tint)
	_mats[key] = m
	return m


func _bark(key: String, tex: String, normal: String) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(Flora.FOLIAGE_SHADER)
	m.set_shader_parameter("albedo_tex", load(A + tex))
	if normal != "":
		m.set_shader_parameter("normal_tex", load(A + normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", 0.03)
	m.set_shader_parameter("translucency", 0.0)
	m.set_shader_parameter("roughness_value", 0.93)
	_mats[key] = m
	return m


func _plain(key: String, base: Color, tip: Color, wind: float) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(Flora.FOLIAGE_SHADER)
	m.set_shader_parameter("use_texture", false)
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("tip_color", tip)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", 0.3)
	_mats[key] = m
	return m


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _finish(parts: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var i: int = 0
	for p in parts:
		(p[0] as SurfaceTool).commit(mesh)
		mesh.surface_set_material(i, p[1])
		i += 1
	return mesh


func _basis_flat(rng: RandomNumberGenerator, tilt: float) -> Basis:
	var b := Basis(Vector3.UP, rng.randf() * TAU)
	return b.rotated(b.x, -PI / 2.0 + rng.randf_range(-tilt, tilt)).orthonormalized()


# =================================================================== essences

## Pin parasol : long fût nu un peu penché, quelques grosses branches, couronne plate.
func pine_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5610 + variant
	var bark := _st()
	var leaves := _st()
	var h: float = rng.randf_range(9.0, 12.5)
	var lean := Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.6, 1.6))
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	for i in range(8):
		var t: float = float(i) / 7.0
		trunk.append(Vector3.UP * h * 0.78 * t + lean * t * t)
		radii.append(lerpf(0.36, 0.18, t) * (1.15 if i == 0 else 1.0))
		flex.append(t * t * 0.08)
	Flora._tube(bark, trunk, radii, flex, 9)
	var top: Vector3 = trunk[7]
	var crown_c: Vector3 = top + Vector3.UP * 1.4
	var crown_r: float = rng.randf_range(4.2, 6.0)
	for b in range(5):
		var a: float = TAU * b / 5.0 + rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), rng.randf_range(0.35, 0.7), sin(a)).normalized()
		var path: Array[Vector3] = [trunk[5 + b % 3]]
		for s in range(1, 4):
			path.append(path[s - 1] + dir * crown_r * 0.24 + Vector3.UP * 0.3)
		Flora._tube(bark, path, [0.14, 0.1, 0.07, 0.04] as Array[float], [0.1, 0.2, 0.35, 0.5] as Array[float], 6)
	# la couronne : un dôme aplati (cartes presque horizontales en dessus, plus inclinées au bord)
	for c in range(150):
		var a2: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * crown_r
		var y: float = 1.1 * (1.0 - pow(r / crown_r, 2.0)) + rng.randf_range(-0.45, 0.35)
		var p := crown_c + Vector3(cos(a2) * r, y, sin(a2) * r)
		Flora._card(leaves, p, rng.randf_range(1.6, 2.4), _basis_flat(rng, 0.25 + 0.5 * r / crown_r), crown_c - Vector3.UP * 1.0, crown_r, 0.5 + 0.4 * r / crown_r)
	return _finish([[bark, _bark("ecorce_pin", "ecorce_pin.png", "ecorce_pin_n.png")], [leaves, _foliage("pin", "feuille_pin.png", 0.1, 0.4, Color(0.95, 1.05, 0.9))]])


## Cyprès : une colonne sombre et serrée.
func cypress_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5620 + variant
	var bark := _st()
	var leaves := _st()
	var h: float = rng.randf_range(9.0, 13.0)
	Flora._tube(bark, [Vector3.ZERO, Vector3.UP * h * 0.5, Vector3.UP * h * 0.9] as Array[Vector3], [0.22, 0.14, 0.05] as Array[float], [0.0, 0.05, 0.15] as Array[float], 6)
	var axis_c := Vector3.UP * h * 0.5
	for c in range(120):
		var t: float = rng.randf_range(0.04, 1.0)
		var y: float = t * h
		var rr: float = 0.95 * sin(pow(t, 0.75) * PI) * (1.0 - t * 0.25) + 0.12
		var a: float = rng.randf() * TAU
		var p := Vector3(cos(a) * rr * rng.randf_range(0.4, 1.0), y, sin(a) * rr * rng.randf_range(0.4, 1.0))
		var b := Basis(Vector3.UP, a + PI / 2.0 + rng.randf_range(-0.4, 0.4)).rotated(Vector3.UP, 0.0)
		Flora._card(leaves, p, rng.randf_range(1.1, 1.6), b, Vector3(0, y, 0), rr + 0.2, 0.2 + 0.6 * t)
	return _finish([[bark, _bark("ecorce_pin", "ecorce_pin.png", "ecorce_pin_n.png")], [leaves, _foliage("cypres", "feuille_cypres.png", 0.06, 0.3, Color(0.85, 0.95, 0.85))]])


## Olivier : tronc court et tortueux, trois ou quatre charpentières, feuillage gris-argent.
func olive_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5630 + variant
	var bark := _st()
	var leaves := _st()
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	for i in range(5):
		var t: float = float(i) / 4.0
		trunk.append(Vector3(sin(t * 3.0 + variant) * 0.25, t * 1.7, cos(t * 2.3 + variant) * 0.2))
		radii.append(lerpf(0.38, 0.24, t))
		flex.append(0.0)
	Flora._tube(bark, trunk, radii, flex, 9)
	var crown_c := Vector3(0, 3.3, 0)
	var crown_r: float = rng.randf_range(2.2, 3.0)
	var n_limbs: int = rng.randi_range(3, 4)
	for b in range(n_limbs):
		var a: float = TAU * b / n_limbs + rng.randf_range(-0.4, 0.4)
		var dir := Vector3(cos(a) * 0.7, 1.0, sin(a) * 0.7).normalized()
		var path: Array[Vector3] = [trunk[4]]
		for s in range(1, 5):
			path.append(path[s - 1] + dir * 0.55 + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)))
			dir = (dir + Vector3(cos(a), 0.0, sin(a)) * 0.25).normalized()
		Flora._tube(bark, path, [0.2, 0.15, 0.1, 0.06, 0.03] as Array[float], [0.0, 0.1, 0.25, 0.4, 0.55] as Array[float], 6)
	for c in range(110):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.8), rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = crown_c + Vector3(d.x * crown_r, d.y * crown_r * 0.62, d.z * crown_r) * rng.randf_range(0.45, 1.0)
		Flora._card(leaves, p, rng.randf_range(1.0, 1.4), Flora._random_basis(rng), crown_c, crown_r, 0.4 + 0.5 * clampf((p.y - 2.0) / 2.5, 0.0, 1.0))
	return _finish([[bark, Flora.bark_material()], [leaves, _foliage("olivier", "feuille_olivier.png", 0.12, 0.35, Color(0.95, 1.0, 0.95))]])


## Platane de la place : grand fût à l'écorce tachetée, large couronne.
func plane_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5640 + variant
	var bark := _st()
	var leaves := _st()
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	for i in range(7):
		var t: float = float(i) / 6.0
		trunk.append(Vector3(sin(t * 2.0) * 0.15, t * 5.5, 0.0))
		radii.append(lerpf(0.42, 0.26, t) * (1.15 if i == 0 else 1.0))
		flex.append(t * t * 0.05)
	Flora._tube(bark, trunk, radii, flex, 10)
	var crown_c := Vector3(0, 8.6, 0)
	var crown_r: float = rng.randf_range(5.2, 6.2)
	for b in range(7):
		var a: float = TAU * b / 7.0 + rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a), rng.randf_range(0.8, 1.3), sin(a)).normalized()
		var path: Array[Vector3] = [trunk[4 + b % 3]]
		for s in range(1, 5):
			path.append(path[s - 1] + dir * crown_r * 0.22 + Vector3.UP * 0.12 * s)
		Flora._tube(bark, path, [0.18, 0.13, 0.09, 0.05, 0.03] as Array[float], [0.05, 0.15, 0.3, 0.45, 0.6] as Array[float], 6)
	for c in range(240):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.45, 1.0), rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = crown_c + Vector3(d.x * crown_r, d.y * crown_r * 0.6, d.z * crown_r) * rng.randf_range(0.5, 1.0)
		Flora._card(leaves, p, rng.randf_range(1.4, 2.0), Flora._random_basis(rng), crown_c, crown_r, 0.5 + 0.4 * clampf((p.y - 6.0) / 5.0, 0.0, 1.0))
	return _finish([[bark, _bark("ecorce_platane", "ecorce_platane.png", "ecorce_platane_n.png")], [leaves, _foliage("platane", "feuille_platane.png", 0.12, 0.5)]])


## Buisson fleuri (laurier-rose) ou feuillage simple (lentisque du maquis).
func shrub_mesh(kind: String, variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5650 + variant + (100 if kind == "laurier" else 0)
	var stems := _st()
	var leaves := _st()
	var size: float = 1.0 if kind == "laurier" else rng.randf_range(0.7, 1.1)
	for s in range(5):
		var a: float = rng.randf() * TAU
		var tip := Vector3(cos(a) * 0.5, 1.2, sin(a) * 0.5) * size
		Flora._tube(stems, [Vector3.ZERO, tip * 0.5, tip] as Array[Vector3], [0.04, 0.03, 0.012] as Array[float], [0.0, 0.3, 0.6] as Array[float], 5)
	var center := Vector3(0, 0.85, 0) * size
	for c in range(40):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 1), rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = center + Vector3(d.x * 0.8, d.y * 0.6, d.z * 0.8) * size * rng.randf_range(0.45, 1.0)
		Flora._card(leaves, p, rng.randf_range(0.7, 1.0) * size, Flora._random_basis(rng), center, 0.9 * size, 0.4 + 0.5 * clampf(p.y, 0.0, 1.0))
	var mat: ShaderMaterial = _foliage("laurier", "feuille_laurier.png", 0.12, 0.4) if kind == "laurier" else _foliage("maquis", "feuille_olivier.png", 0.1, 0.35, Color(0.7, 0.85, 0.6))
	return _finish([[stems, Flora.bark_material()], [leaves, mat]])


## Agave : une rosette de grandes feuilles charnues, bleu-vert, bordées de jaune.
func agave_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5660 + variant
	var st := _st()
	var n: int = 18
	for i in range(n):
		var a: float = TAU * i / n + rng.randf_range(-0.12, 0.12)
		var up: float = rng.randf_range(0.5, 1.1)
		var L: float = rng.randf_range(0.8, 1.3)
		var dir := Vector3(cos(a), up, sin(a)).normalized()
		var side := Vector3(-sin(a), 0, cos(a))
		var w: float = 0.12
		var pts := [Vector3.ZERO + side * w, Vector3.ZERO - side * w, dir * L * 0.6 + side * w * 0.8 + Vector3.DOWN * 0.05, dir * L * 0.6 - side * w * 0.8 + Vector3.DOWN * 0.05, dir * L]
		var nrm: Vector3 = side.cross(dir).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		for tri in [[0, 2, 1], [1, 2, 3], [2, 4, 3]]:
			for k in tri:
				Flora._vertex(st, pts[k], nrm, Vector2(0.5, 1.0 - float(k) / 4.0), 0.05, float(k) / 4.0)
	return _finish([[st, _plain("agave", Color(0.32, 0.46, 0.42), Color(0.72, 0.7, 0.35), 0.02)]])


## Touffe d'herbe sèche.
func grass_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(14, 0.55, 0.045, 56).duplicate()
	m.surface_set_material(0, _plain("herbe_seche", Color(0.45, 0.42, 0.22), Color(0.86, 0.76, 0.48), 0.12))
	return m


func palm_mesh(variant: int) -> ArrayMesh:
	if _jf == null:
		_jf = JungleFlora.new()
	return _jf.palm_mesh(variant, true)


## Bougainvillier grimpant : une nappe de fleurs magenta plaquée contre un mur (repère : le
## mur est le plan XY, la nappe déborde vers +Z).
func bougainvillea_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5670 + variant
	var st := _st()
	var w: float = rng.randf_range(2.0, 3.2)
	var h: float = rng.randf_range(2.2, 3.4)
	var c := Vector3(0, h * 0.55, 0.3)
	for i in range(46):
		var p := Vector3(rng.randf_range(-w / 2, w / 2), rng.randf_range(0.2, h) * (1.0 - absf(rng.randf_range(-0.3, 0.3))), rng.randf_range(0.05, 0.45))
		var b := Basis(Vector3.UP, rng.randf_range(-0.6, 0.6)).rotated(Vector3.RIGHT, rng.randf_range(-0.5, 0.5))
		Flora._card(st, p, rng.randf_range(0.7, 1.1), b, c, maxf(w, h) * 0.5, 0.3)
	return _finish([[st, _foliage("bougainvillier", "feuille_bougainvillier.png", 0.05, 0.4)]])


# =================================================================== plantation

func _ok_spot(w: Vector3, max_slope: float, min_h: float, max_h: float = 200.0) -> bool:
	if w.y < min_h or w.y > max_h:
		return false
	var e: float = 1.5
	var sx: float = absf(ile.height(w.x + e, w.z) - ile.height(w.x - e, w.z)) / (2.0 * e)
	var sz: float = absf(ile.height(w.x, w.z + e) - ile.height(w.x, w.z - e)) / (2.0 * e)
	if maxf(sx, sz) > max_slope:
		return false
	for a in avoid:
		if Vector2(w.x, w.z).distance_to(a[0]) < float(a[1]):
			return false
	return true


## Un point du « maquis » : hors de la ville, de la plage, du chemin, des maisons.
func _wild_point() -> Vector3:
	for attempt in range(40):
		var x: float = _rng.randf_range(-185.0, 165.0)
		var z: float = _rng.randf_range(-10.0, 250.0)
		if z < 95.0 and x > -95.0 and x < 80.0:
			continue             # la ville
		if z < 55.0 and x < -80.0:
			continue             # la plage
		var w: Vector3 = ile.to_world(x, z)
		w.y = ile.height(w.x, w.z)
		if _ok_spot(w, 0.55, 1.6):
			return w
	return Vector3.INF


func _xf(pos: Vector3, scale_v: float, sink: float = 0.08) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_v), pos - Vector3.UP * sink)


func _emit(label: String, mesh: Mesh, xfs: Array, vis_end: float, shadows: bool = true) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Flore_azur_" + label
	mmi.multimesh = mm
	mmi.visibility_range_end = vis_end
	mmi.visibility_range_end_margin = 20.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	placed[label] = int(placed.get(label, 0)) + xfs.size()


## Plante l'île. town_spots : arbres de la ville fournis par le port ({espèce: [Transform3D]}).
func build(island: Node3D, town_spots: Dictionary, high_quality: bool) -> void:
	ile = island
	_rng.seed = 5600
	var t0: int = Time.get_ticks_msec()
	# le maquis des collines
	var lists := {"pin": [[], [], []], "olivier": [[], [], []], "cypres": [[], []], "maquis": [[], []], "laurier": [[]], "agave": [[], []], "herbe": [[]]}
	for i in range(80):
		var p: Vector3 = _wild_point()
		if p != Vector3.INF:
			lists["pin"][i % 3].append(_xf(p, _rng.randf_range(0.85, 1.15)))
			avoid.append([Vector2(p.x, p.z), 4.5])
	# l'oliveraie : sur les pentes douces à l'est, en rangées un peu irrégulières
	for row in range(9):
		for col in range(12):
			var x: float = 70.0 + col * 7.5 + _rng.randf_range(-1.2, 1.2)
			var z: float = 105.0 + row * 8.0 + _rng.randf_range(-1.2, 1.2)
			var w: Vector3 = ile.to_world(x, z)
			w.y = ile.height(w.x, w.z)
			if _ok_spot(w, 0.4, 2.0):
				lists["olivier"][(row + col) % 3].append(_xf(w, _rng.randf_range(0.85, 1.1)))
	for i in range(60):
		var p2: Vector3 = _wild_point()
		if p2 != Vector3.INF:
			lists["olivier"][i % 3].append(_xf(p2, _rng.randf_range(0.8, 1.1)))
	# cyprès le long du chemin du belvédère et autour des maisons
	for k in range(0, ile.lane_world.size(), 9):
		var lp: Vector3 = ile.lane_world[k]
		var side := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized() * 3.6
		var cp: Vector3 = lp + side
		cp.y = ile.height(cp.x, cp.z)
		if _ok_spot(cp, 0.6, 1.5):
			lists["cypres"][k % 2].append(_xf(cp, _rng.randf_range(0.8, 1.1)))
	for i in range(25):
		var p3: Vector3 = _wild_point()
		if p3 != Vector3.INF:
			lists["cypres"][i % 2].append(_xf(p3, _rng.randf_range(0.8, 1.1)))
	for i in range(420 if high_quality else 220):
		var p4: Vector3 = _wild_point()
		if p4 != Vector3.INF:
			lists["maquis"][i % 2].append(_xf(p4, _rng.randf_range(0.7, 1.4), 0.15))
	for i in range(40):
		var p5: Vector3 = _wild_point()
		if p5 != Vector3.INF:
			lists["laurier"][0].append(_xf(p5, _rng.randf_range(0.9, 1.3), 0.1))
	# agaves sur la pointe rocheuse
	for i in range(60):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(6.0, ile.HEADLAND_R + 6.0)
		var w2: Vector3 = ile.to_world(ile.HEADLAND.x + cos(a) * r, ile.HEADLAND.y + sin(a) * r)
		w2.y = ile.height(w2.x, w2.z)
		if Vector2(w2.x, w2.z).distance_to(Vector2(ile.to_world(ile.LIGHTHOUSE.x, ile.LIGHTHOUSE.y).x, ile.to_world(ile.LIGHTHOUSE.x, ile.LIGHTHOUSE.y).z)) < 7.0:
			continue
		if _ok_spot(w2, 0.8, 1.0):
			lists["agave"][i % 2].append(_xf(w2, _rng.randf_range(0.7, 1.2), 0.05))
	# herbe blonde partout dans le maquis
	for i in range(2600 if high_quality else 1200):
		var p6: Vector3 = _wild_point()
		if p6 != Vector3.INF:
			lists["herbe"][0].append(_xf(p6, _rng.randf_range(0.8, 1.5), 0.02))
	for v in range(3):
		_emit("pin_%d" % v, pine_mesh(v), lists["pin"][v], 700.0)
		_emit("olivier_%d" % v, olive_mesh(v), lists["olivier"][v], 420.0)
	for v in range(2):
		_emit("cypres_%d" % v, cypress_mesh(v), lists["cypres"][v], 600.0)
		_emit("maquis_%d" % v, shrub_mesh("maquis", v), lists["maquis"][v], 220.0)
		_emit("agave_%d" % v, agave_mesh(v), lists["agave"][v], 180.0)
	_emit("laurier", shrub_mesh("laurier", 0), lists["laurier"][0], 220.0)
	_emit("herbe", grass_mesh(), lists["herbe"][0], 70.0, false)
	# les arbres de la ville (fournis par port_azur_v56.gd)
	for sp in town_spots:
		var xfs: Array = town_spots[sp]
		match str(sp):
			"platane":
				_emit("platane", plane_mesh(0), xfs, 600.0)
			"palmier":
				_emit("palmier", palm_mesh(0), xfs.slice(0, xfs.size() / 2 + 1), 600.0)
				_emit("palmier_b", palm_mesh(1), xfs.slice(xfs.size() / 2 + 1), 600.0)
			"laurier":
				_emit("laurier_ville", shrub_mesh("laurier", 1), xfs, 220.0)
			"bougainvillier":
				_emit("bougainvillier", bougainvillea_mesh(0), xfs, 220.0)
			"cypres":
				_emit("cypres_ville", cypress_mesh(2), xfs, 600.0)
			"olivier":
				_emit("olivier_ville", olive_mesh(4), xfs, 420.0)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V56: végétation de Port-Azur ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

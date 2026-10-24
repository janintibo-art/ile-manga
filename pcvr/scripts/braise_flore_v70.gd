extends "res://scripts/soleils_flore_v69.gd"
## V70 : la végétation de l'Île de Braise (mêmes outils que les autres îles : des maillages
## fabriqués ici, instanciés par espèce dans des MultiMesh) :
##  - les arbres de braise : un tronc noir et tordu dont les crevasses rougeoient, une couronne
##    de feuilles rouges et orange qui luisent comme des charbons (la nuit, davantage) ; le Bois
##    de Cendre en est plein, il y en a dans les cours et les jardins de Pandémonia ;
##  - les arbres morts (calcinés), sur les pentes du Grand Brasier et autour des Ruines ;
##  - les champignons qui luisent (bleus, verts, orange), dans le Bois de Cendre ;
##  - les fleurs de braise, sur les pentes du volcan et dans les Jardins de Cendre ;
##  - l'herbe de cendre (grise au pied, cuivrée en haut), les touffes de bruyère sombre ;
##  - les cristaux de soufre autour des sources ; des éclats d'obsidienne ; des blocs de lave
##    et de basalte.

const RB = preload("res://scripts/ile_braise_v70.gd")
const TB := "res://assets/textures/braise/"
const SHADER70 := "res://shaders/braise_feuillage_v70.gdshader"

var glow_mats: Array = []                # [Material, énergie la nuit, le jour] (temps_v56.register_glow)
var _ileb: Node3D
var _city_c := Vector2.ZERO


# =================================================================== matières

func _braise_mat(key: String, tex: String, normal: String, wind: float, transl: float, mode: int, glow_day: float, glow_night: float) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(SHADER70)
	if ResourceLoader.exists(TB + tex):
		m.set_shader_parameter("albedo_tex", load(TB + tex))
	else:
		m.set_shader_parameter("use_texture", false)
		m.set_shader_parameter("base_color", Color(0.4, 0.08, 0.03))
		m.set_shader_parameter("tip_color", Color(0.95, 0.45, 0.1))
	if normal != "" and ResourceLoader.exists(TB + normal):
		m.set_shader_parameter("normal_tex", load(TB + normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", transl)
	m.set_shader_parameter("glow_mode", mode)
	m.set_shader_parameter("glow", glow_day)
	if mode == 2:
		m.set_shader_parameter("roughness_value", 0.93)
	_mats[key] = m
	glow_mats.append([m, glow_night, glow_day])
	return m


func _shine(key: String, c: Color, energy: float, glow_day: float = -1.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.45
	_mats[key] = m
	if glow_day >= 0.0:
		glow_mats.append([m, energy, glow_day])
	return m


func _matte(key: String, c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	_mats[key] = m
	return m


# =================================================================== maillages

## L'arbre de braise : un tronc tordu, des branches qui montent, une couronne en ombrelle.
func ember_tree_mesh(variant: int, small: bool = false) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7090 + variant * 13 + (100 if small else 0)
	var bark := _st()
	var leaves := _st()
	var h: float = rng.randf_range(4.6, 6.4) * (0.75 if small else 1.0)
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	var ph: float = rng.randf() * TAU
	for i in range(7):
		var t: float = float(i) / 6.0
		trunk.append(Vector3(sin(t * 2.6 + ph) * 0.55 * t, t * h, cos(t * 1.9 + ph) * 0.45 * t))
		radii.append(lerpf(0.42, 0.13, t) * (0.8 if small else 1.0))
		flex.append(t * 0.12)
	Flora._tube(bark, trunk, radii, flex, 9)
	# les racines qui s'agrippent au sol
	for r in range(4):
		var a: float = TAU * r / 4.0 + rng.randf_range(-0.4, 0.4)
		var path: Array[Vector3] = [Vector3(cos(a) * 0.15, 0.35, sin(a) * 0.15), Vector3(cos(a) * 0.55, 0.12, sin(a) * 0.55), Vector3(cos(a) * 0.95, -0.05, sin(a) * 0.95)]
		Flora._tube(bark, path, [0.16, 0.09, 0.04] as Array[float], [0.0, 0.0, 0.0] as Array[float], 6)
	var top: Vector3 = trunk[6]
	var crown_c: Vector3 = top + Vector3.UP * 0.6
	var crown_r: float = rng.randf_range(2.5, 3.3) * (0.75 if small else 1.0)
	var tips: Array = []
	for b in range(6):
		var a2: float = TAU * b / 6.0 + rng.randf_range(-0.35, 0.35)
		var start: Vector3 = trunk[3 + b % 3]
		var dir := Vector3(cos(a2) * 0.8, 0.75, sin(a2) * 0.8).normalized()
		var path2: Array[Vector3] = [start]
		for s in range(1, 5):
			dir = (dir + Vector3(cos(a2) * 0.25, rng.randf_range(-0.05, 0.25), sin(a2) * 0.25)).normalized()
			path2.append(path2[s - 1] + dir * rng.randf_range(0.5, 0.75) * (0.8 if small else 1.0))
		Flora._tube(bark, path2, [0.15, 0.11, 0.07, 0.04, 0.02] as Array[float], [0.1, 0.2, 0.35, 0.5, 0.65] as Array[float], 6)
		tips.append(path2[4])
	var n_cards: int = 120 if small else 170
	for c in range(n_cards):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.35, 0.7), rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = crown_c + Vector3(d.x * crown_r, d.y * crown_r * 0.5, d.z * crown_r) * rng.randf_range(0.4, 1.0)
		if c % 4 == 0:
			p = (tips[c % tips.size()] as Vector3) + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.2, 0.5), rng.randf_range(-0.6, 0.6))
		Flora._card(leaves, p, rng.randf_range(1.0, 1.45) * (0.85 if small else 1.0), Flora._random_basis(rng), crown_c, crown_r, 0.4 + 0.5 * clampf((p.y - h * 0.6) / 2.5, 0.0, 1.0))
	return _finish([[bark, _braise_mat("ecorce_braise", "ecorce_braise.png", "ecorce_braise_n.png", 0.03, 0.0, 2, 0.6, 1.4)],
		[leaves, _braise_mat("feuilles_braise", "feuilles_braise.png", "", 0.1, 0.55, 1, 0.55, 1.5)]])


## Un arbre calciné : un tronc noir, des branches nues et tordues.
func burnt_tree_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7100 + variant
	var bark := _st()
	var h: float = rng.randf_range(3.6, 5.8)
	var lean := Vector3(rng.randf_range(-0.7, 0.7), 0, rng.randf_range(-0.7, 0.7))
	var trunk: Array[Vector3] = [Vector3.ZERO, Vector3.UP * h * 0.4 + lean * 0.2, Vector3.UP * h * 0.75 + lean * 0.6, Vector3.UP * h + lean]
	Flora._tube(bark, trunk, [0.26, 0.18, 0.11, 0.04] as Array[float], [0.0, 0.0, 0.0, 0.0] as Array[float], 7)
	for b in range(7):
		var a: float = rng.randf() * TAU
		var start: Vector3 = trunk[1 + b % 3]
		var dir := Vector3(cos(a), rng.randf_range(0.2, 0.9), sin(a)).normalized()
		var path: Array[Vector3] = [start]
		for s in range(1, 4):
			dir = (dir + Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.1, 0.3), rng.randf_range(-0.4, 0.4))).normalized()
			path.append(path[s - 1] + dir * rng.randf_range(0.5, 0.9))
		Flora._tube(bark, path, [0.08, 0.05, 0.03, 0.01] as Array[float], [0.0, 0.0, 0.0, 0.0] as Array[float], 5)
	return _finish([[bark, _braise_mat("ecorce_calcinee", "ecorce_braise.png", "ecorce_braise_n.png", 0.0, 0.0, 2, 0.25, 0.7)]])


## Une touffe de champignons qui luisent (un pied pâle, un chapeau lumineux).
func mushrooms_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7110 + variant
	var stems := SurfaceTool.new()
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caps := SurfaceTool.new()
	caps.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = rng.randi_range(5, 9)
	for i in range(n):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.0, 0.45)
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var hh: float = rng.randf_range(0.12, 0.42)
		var cr: float = rng.randf_range(0.06, 0.16) * (0.7 + hh)
		var lean := Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08))
		_cyl_st(stems, base, base + Vector3.UP * hh + lean, cr * 0.28, cr * 0.22, 6)
		_dome_st(caps, base + Vector3.UP * hh + lean, cr, cr * 0.75, 10)
	var mesh := ArrayMesh.new()
	stems.generate_normals()
	stems.commit(mesh)
	mesh.surface_set_material(0, _matte("pied_champignon", Color(0.78, 0.74, 0.66), 0.7))
	caps.commit(mesh)
	var col: Color = [Color(0.3, 0.85, 1.0), Color(0.45, 1.0, 0.55), Color(1.0, 0.55, 0.18)][variant % 3]
	var cm: StandardMaterial3D = _shine("chapeau_%d" % (variant % 3), col, 1.6, 0.5)
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(1, cm)
	return mesh


func _cyl_st(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, seg: int) -> void:
	for i in range(seg):
		var t0: float = TAU * i / seg
		var t1: float = TAU * (i + 1) / seg
		var d0 := Vector3(cos(t0), 0, sin(t0))
		var d1 := Vector3(cos(t1), 0, sin(t1))
		for v in [a + d0 * r0, b + d1 * r1, b + d0 * r1, a + d0 * r0, a + d1 * r0, b + d1 * r1]:
			st.add_vertex(v)


func _dome_st(st: SurfaceTool, c: Vector3, r: float, h: float, seg: int) -> void:
	var rings := 4
	for j in range(rings):
		var v0: float = float(j) / rings * PI * 0.5
		var v1: float = float(j + 1) / rings * PI * 0.5
		for i in range(seg):
			var t0: float = TAU * i / seg
			var t1: float = TAU * (i + 1) / seg
			var p00 := c + Vector3(cos(t0) * cos(v0) * r, sin(v0) * h, sin(t0) * cos(v0) * r)
			var p10 := c + Vector3(cos(t1) * cos(v0) * r, sin(v0) * h, sin(t1) * cos(v0) * r)
			var p01 := c + Vector3(cos(t0) * cos(v1) * r, sin(v1) * h, sin(t0) * cos(v1) * r)
			var p11 := c + Vector3(cos(t1) * cos(v1) * r, sin(v1) * h, sin(t1) * cos(v1) * r)
			for p in [p00, p11, p01, p00, p10, p11]:
				st.set_normal(((p as Vector3) - c + Vector3.DOWN * h * 0.3).normalized())
				st.add_vertex(p)
	# le dessous du chapeau (les lamelles)
	for i in range(seg):
		var t0b: float = TAU * i / seg
		var t1b: float = TAU * (i + 1) / seg
		for p in [c, c + Vector3(cos(t0b) * r, 0, sin(t0b) * r), c + Vector3(cos(t1b) * r, 0, sin(t1b) * r)]:
			st.set_normal(Vector3.DOWN)
			st.add_vertex(p)


## Une touffe de fleurs de braise : des tiges, des fleurs qui regardent le ciel.
func fire_flower_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7120 + variant
	var stems := _st()
	var heads := _st()
	for i in range(rng.randi_range(3, 5)):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.0, 0.25)
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var hh: float = rng.randf_range(0.35, 0.65)
		var tip: Vector3 = base + Vector3(rng.randf_range(-0.1, 0.1), hh, rng.randf_range(-0.1, 0.1))
		Flora._tube(stems, [base, base.lerp(tip, 0.5) + Vector3(0.03, 0, 0), tip] as Array[Vector3], [0.018, 0.014, 0.01] as Array[float], [0.0, 0.4, 0.8] as Array[float], 4)
		var b := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.RIGHT, -PI * 0.5 + rng.randf_range(-0.4, 0.4))
		Flora._card(heads, tip + Vector3.UP * 0.02, rng.randf_range(0.2, 0.3), b, tip, 0.2, 0.9)
		Flora._card(heads, tip + Vector3.UP * 0.05, rng.randf_range(0.15, 0.22), b.rotated(Vector3.UP, 0.4), tip, 0.2, 0.9)
	return _finish([[stems, _plain("tige_braise", Color(0.12, 0.08, 0.05), Color(0.3, 0.12, 0.05), 0.1)],
		[heads, _braise_mat("fleur_braise", "fleur_braise.png", "", 0.08, 0.5, 1, 0.8, 1.8)]])


func ash_grass_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(14, 0.45, 0.05, 7130).duplicate()
	m.surface_set_material(0, _plain("herbe_cendre", Color(0.12, 0.11, 0.1), Color(0.55, 0.27, 0.12), 0.1))
	return m


func dark_heather_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(18, 0.34, 0.06, 7131).duplicate()
	m.surface_set_material(0, _plain("bruyere_braise", Color(0.14, 0.1, 0.08), Color(0.48, 0.14, 0.12), 0.06))
	return m


## Une gerbe de cristaux (du soufre, de l'obsidienne) : des prismes plantés en tous sens.
func crystals_mesh(variant: int, kind: String) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7140 + variant + (50 if kind == "obsidienne" else 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rng.randi_range(4, 8)):
		var dir := Vector3(rng.randf_range(-0.6, 0.6), 1.0, rng.randf_range(-0.6, 0.6)).normalized()
		var base := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
		var L: float = rng.randf_range(0.25, 0.7) * (1.6 if kind == "obsidienne" else 1.0)
		var r: float = L * rng.randf_range(0.12, 0.2)
		var side: Vector3 = dir.cross(Vector3.RIGHT).normalized()
		var side2: Vector3 = side.cross(dir).normalized()
		var top: Vector3 = base + dir * L
		var ring: Array = []
		for k in range(6):
			var a: float = TAU * k / 6.0
			ring.append(base + (side * cos(a) + side2 * sin(a)) * r)
		for k2 in range(6):
			var p0: Vector3 = ring[k2]
			var p1: Vector3 = ring[(k2 + 1) % 6]
			var q0: Vector3 = p0 + dir * L * 0.75
			var q1: Vector3 = p1 + dir * L * 0.75
			for v in [p0, q1, q0, p0, p1, q1, q0, q1, top]:
				st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	if kind == "obsidienne":
		var mo := _matte("obsidienne_eclat", Color(0.04, 0.03, 0.05), 0.08, 0.2)
		mo.metallic_specular = 0.9
		mesh.surface_set_material(0, mo)
	else:
		mesh.surface_set_material(0, _shine("soufre_cristal", Color(0.95, 0.82, 0.2), 0.35))
	return mesh


## Un bac de pierre autour d'un arbre planté dans la ville (et sa terre noire).
func planter_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 12
	var ri: float = 1.05
	var ro: float = 1.25
	var h: float = 0.45
	var up := Vector3.UP
	for i in range(seg):
		var t0: float = TAU * i / seg
		var t1: float = TAU * (i + 1) / seg
		var d0 := Vector3(cos(t0), 0, sin(t0))
		var d1 := Vector3(cos(t1), 0, sin(t1))
		var nm: Vector3 = (d0 + d1).normalized()
		_quad_n(st, d0 * ro, d1 * ro, d1 * ro + up * h, d0 * ro + up * h, nm)
		_quad_n(st, d0 * ro + up * h, d1 * ro + up * h, d1 * ri + up * h, d0 * ri + up * h, up)
		_quad_n(st, d0 * ri, d1 * ri, d1 * ri + up * h, d0 * ri + up * h, -nm)
		_tri_n(soil, up * 0.32, d0 * ri + up * 0.32, d1 * ri + up * 0.32, up)
	var mesh := st.commit()
	mesh.surface_set_material(0, _matte("bac_pierre", Color(0.26, 0.25, 0.25), 0.9))
	soil.commit(mesh)
	mesh.surface_set_material(1, _matte("terre_noire", Color(0.07, 0.05, 0.045), 0.95))
	return mesh


## Un triangle dont la face avant regarde du côté de n (la normale n à chaque sommet).
func _tri_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t: Vector3 = b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


func _quad_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	_tri_n(st, a, b, c, n)
	_tri_n(st, a, c, d, n)


# =================================================================== où planter

## Un point de l'île qui convient (hors de la ville, des chemins, des lieux, de la lave).
## want : "" (partout), "bois", "volcan", "ruines", "sources", "champ", "greve".
func _bp(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"bois":
				var a: float = _rng.randf() * TAU
				l = RB.FOREST + Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * RB.FOREST_R
			"volcan":
				var a2: float = _rng.randf() * TAU
				l = RB.VOLCANO + Vector2(cos(a2), sin(a2)) * lerpf(RB.CRATER_R + 10.0, 125.0, sqrt(_rng.randf()))
			"ruines":
				var a3: float = _rng.randf() * TAU
				l = RB.RUINS + Vector2(cos(a3), sin(a3)) * sqrt(_rng.randf()) * (RB.RUINS_R + 25.0)
			"sources":
				var sp: Vector2 = RB.SPRINGS[_rng.randi() % RB.SPRINGS.size()]
				var a4: float = _rng.randf() * TAU
				l = sp + Vector2(cos(a4), sin(a4)) * _rng.randf_range(RB.SPRING_R - 0.5, RB.SPRING_R + 5.0)
			"champ":
				var a5: float = _rng.randf() * TAU
				l = RB.LAVA_FIELD + Vector2(cos(a5), sin(a5)) * sqrt(_rng.randf()) * RB.LAVA_FIELD_R
			_:
				l = Vector2(_rng.randf_range(-RB.HALF + 4.0, RB.HALF - 4.0), _rng.randf_range(-RB.HALF + 4.0, RB.HALF - 4.0))
		if absf(l.x) > RB.HALF - 2.0 or absf(l.y) > RB.HALF - 2.0:
			continue
		if l.distance_to(_city_c) < RB.BASSE_R1 + 6.0:
			continue
		if _blocked.has(_cell(l)):
			continue
		var w3: Vector3 = RB.W(l.x, l.y)
		w3.y = _ileb.height(w3.x, w3.z)
		if _ileb.lava_at(w3.x, w3.z) > -1e9 or _ileb.in_spring(w3.x, w3.z):
			continue
		var fd: Vector2 = RB.flow_dist(l.x, l.y)
		if fd.x < fd.y + 3.0:
			continue
		if _ileb.biome_at(w3.x, w3.z).a > 0.3:
			continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _block_paths_b() -> void:
	for k in _ileb.paths_world:
		for p in _ileb.paths_world[k]:
			var l: Vector2 = RB.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


## Plante l'île. extra : « arbres » (Vector3 : les arbres de la ville), « massifs » (les
## massifs des Jardins de Cendre).
func build_braise(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ileb = island
	ile = island
	_rng.seed = 7000
	_city_c = RB.CITY
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_block_paths_b()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_braise_v70"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"braise": [[], [], []], "braise_petit": [[], []], "mort": [[], []], "champignon": [[], [], []], "fleur": [[], []],
		"herbe": [[]], "bruyere": [[]], "soufre": [[], []], "obsidienne": [[], []], "bac": [[]]}
	var rocks := {"basalte": [], "lave": []}
	# ---------------------------------------------------------------- le Bois de Cendre
	for i in range(int(260 * q)):
		var p: Vector3 = _bp("bois", 0.6, 0.6, 60.0)
		if p == Vector3.INF:
			continue
		L["braise"][i % 3].append(_xfr(p, 0.8, 1.25, 0.15))
		_trunk(p, 0.4, 3.5)
	for i2 in range(int(45 * q)):
		var pm: Vector3 = _bp("bois", 0.6, 0.6, 60.0)
		if pm != Vector3.INF:
			L["mort"][i2 % 2].append(_xfr(pm, 0.8, 1.2, 0.1))
			_trunk(pm, 0.28, 3.0)
	for i3 in range(int(420 * q)):
		var pc: Vector3 = _bp("bois", 0.5, 0.8, 60.0)
		if pc != Vector3.INF:
			L["champignon"][i3 % 3].append(_xfr(pc, 0.7, 1.6, 0.02))
	for i4 in range(int(2600 * q)):
		var ph: Vector3 = _bp("bois", 0.4, 0.9, 60.0)
		if ph != Vector3.INF:
			L["herbe"][0].append(_xfr(ph, 0.8, 1.4, 0.02))
	# ---------------------------------------------------------------- partout : l'herbe de cendre, la bruyère, quelques arbres
	for i5 in range(int(5200 * q)):
		var pg: Vector3 = _bp("", 1.2, 0.75, 70.0)
		if pg == Vector3.INF:
			continue
		var b: Color = _ileb.biome_at(pg.x, pg.z)
		if b.b > 0.4:
			continue
		if b.g > 0.25 or _rng.randf() < 0.3:
			L["herbe"][0].append(_xfr(pg, 0.8, 1.5, 0.02))
	for i6 in range(int(1500 * q)):
		var pb: Vector3 = _bp("", 1.6, 0.85, 85.0)
		if pb != Vector3.INF and _ileb.biome_at(pb.x, pb.z).b < 0.4:
			L["bruyere"][0].append(_xfr(pb, 0.8, 1.4, 0.02))
	for i7 in range(int(140 * q)):
		var pt: Vector3 = _bp("", 2.0, 0.55, 55.0)
		if pt == Vector3.INF or _ileb.biome_at(pt.x, pt.z).b > 0.3:
			continue
		if RB.L(pt.x, pt.z).distance_to(RB.VOLCANO) < 95.0:
			continue
		L["braise"][i7 % 3].append(_xfr(pt, 0.7, 1.05, 0.15))
		_trunk(pt, 0.35, 3.0)
	# ---------------------------------------------------------------- le Grand Brasier, le champ de lave, les Ruines
	for i8 in range(int(70 * q)):
		var pv: Vector3 = _bp("volcan", 6.0, 0.7, 70.0)
		if pv != Vector3.INF:
			L["mort"][i8 % 2].append(_xfr(pv, 0.7, 1.1, 0.1))
			_trunk(pv, 0.25, 3.0)
	for i9 in range(int(260 * q)):
		var pr: Vector3 = _bp("volcan", 4.0, 2.0)
		if pr != Vector3.INF:
			rocks["lave"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.4)), pr - Vector3.UP * 0.4))
	for i10 in range(int(90 * q)):
		var po: Vector3 = _bp("volcan", 10.0, 1.2)
		if po != Vector3.INF:
			L["obsidienne"][i10 % 2].append(_xfr(po, 0.8, 1.8, 0.1))
	for i11 in range(int(120 * q)):
		var pf: Vector3 = _bp("volcan", 6.0, 0.7, 75.0)
		if pf != Vector3.INF:
			L["fleur"][i11 % 2].append(_xfr(pf, 0.9, 1.3, 0.02))
	for i12 in range(int(110 * q)):
		var pl: Vector3 = _bp("champ", 0.0, 2.0)
		if pl != Vector3.INF:
			rocks["lave"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pl - Vector3.UP * 0.3))
	for i13 in range(int(40 * q)):
		var pru: Vector3 = _bp("ruines", 2.0, 0.7)
		if pru != Vector3.INF:
			L["mort"][i13 % 2].append(_xfr(pru, 0.8, 1.2, 0.1))
			_trunk(pru, 0.28, 3.0)
	# ---------------------------------------------------------------- les sources de soufre
	for i14 in range(int(70 * q)):
		var ps: Vector3 = _bp("sources", 0.0, 1.5)
		if ps != Vector3.INF:
			L["soufre"][i14 % 2].append(_xfr(ps, 0.7, 1.6, 0.05))
	# ---------------------------------------------------------------- les grèves : des blocs de basalte
	for i15 in range(int(260 * q)):
		var pz: Vector3 = _bp("", -1.5, 2.0, 2.6)
		if pz == Vector3.INF:
			continue
		var lz: Vector2 = RB.L(pz.x, pz.z)
		if RB.coast_q(lz.x, lz.y) < 0.9:
			continue
		rocks["basalte"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.2)), pz - Vector3.UP * 0.35))
	# ---------------------------------------------------------------- dans la ville
	for tp in extra.get("arbres", []):
		var w: Vector3 = tp
		L["braise_petit"][int(absf(w.x)) % 2].append(_xf(w, _rng.randf_range(0.85, 1.05), 0.05))
		L["bac"][0].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), w))
		_trunk(w, 0.3, 2.6)
	for mp in extra.get("massifs", []):
		var m: Vector3 = mp
		for k in range(4):
			var a: float = TAU * k / 4.0 + _rng.randf()
			L["fleur"][k % 2].append(_xf(m + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.3, 1.4), _rng.randf_range(0.9, 1.3), 0.0))
		L["champignon"][_rng.randi() % 3].append(_xf(m + Vector3(_rng.randf_range(-1.0, 1.0), 0, _rng.randf_range(-1.0, 1.0)), 1.0, 0.0))
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("arbre_braise_%d" % v, ember_tree_mesh(v), L["braise"][v], 420.0)
		_emit("champignon_%d" % v, mushrooms_mesh(v), L["champignon"][v], 80.0, false)
	for v2 in range(2):
		_emit("arbre_braise_ville_%d" % v2, ember_tree_mesh(v2, true), L["braise_petit"][v2], 300.0)
		_emit("arbre_calcine_%d" % v2, burnt_tree_mesh(v2), L["mort"][v2], 300.0)
		_emit("fleur_braise_%d" % v2, fire_flower_mesh(v2), L["fleur"][v2], 90.0, false)
		_emit("soufre_%d" % v2, crystals_mesh(v2, "soufre"), L["soufre"][v2], 120.0, false)
		_emit("obsidienne_%d" % v2, crystals_mesh(v2, "obsidienne"), L["obsidienne"][v2], 160.0)
	_emit("herbe_cendre", ash_grass_mesh(), L["herbe"][0], 70.0, false)
	_emit("bruyere_braise", dark_heather_mesh(), L["bruyere"][0], 70.0, false)
	_emit("bac_arbre", planter_mesh(), L["bac"][0], 250.0)
	_rock_mm("basalte_braise", Color(0.16, 0.15, 0.15), 0.0, rocks["basalte"], 3, Vector3(2.2, 1.5, 1.9), true)
	_rock_mm("lave_braise", Color(0.12, 0.1, 0.1), 0.0, rocks["lave"], 3, Vector3(2.4, 1.6, 2.0), true)
	if _jf != null:
		_jf.free()
		_jf = null
	print("ILE_MANGA_V70: végétation de l'Île de Braise ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

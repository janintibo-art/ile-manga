extends Node3D
## V30 : la forêt de l'île-jungle, en étages comme une vraie forêt tropicale.
##  - Géants (30-40 m) : troncs pâles à contreforts, grandes charpentières, canopée en
##    parasol, lianes qui pendent jusqu'au sol.
##  - Arbres de canopée (12-20 m), cocotiers sur les plages, bananiers, fougères
##    arborescentes, et au sol fougères, herbes et jeunes pousses.
##  - Brume basse sous les arbres (PC).
## Chaque essence est un maillage construit une fois, répété par MultiMesh et découpé en
## parcelles : seules les parcelles proches sont dessinées en détail ; de loin, les grands
## arbres passent sur une version allégée (on voit la forêt depuis le village).
## La gorge reste libre (rivière à venir), comme les pitons, la plage du ponton et la mer.

const LEAF_SHADER := "res://shaders/foliage_v25.gdshader"
const TEX := "res://assets/textures/jungle/"
const FLORA_TEX := "res://assets/textures/flora/"

var jungle: Node3D
var pc: bool = true
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}
var _meshes: Dictionary = {}
var _batches: Dictionary = {}          # "espèce|parcelle" -> Array[Transform3D]
var _trunks: StaticBody3D
var counts: Dictionary = {}
## V31 : clairières à laisser libres ([centre local Vector2, rayon]) — la cabane de Barnabé.
var clearings: Array = []


func build(jungle_node: Node3D, high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	jungle = jungle_node
	pc = high_quality
	_rng.seed = 3030
	_trunks = StaticBody3D.new()
	_trunks.name = "Jungle_troncs_v30"
	_trunks.collision_layer = 1
	_trunks.collision_mask = 0
	add_child(_trunks)
	_place_giants(45)
	_place_species("canopee", 950 if pc else 600, 4.0, 0.58, 4.0, 0.8, 7.0)
	_place_palms(95 if pc else 70)
	_place_bay_palms(26)
	_place_species("arbuste", 1800 if pc else 1000, 2.4, 0.7, 1.9, 0.9, 2.5)
	_place_species("bananier", 650 if pc else 380, 2.2, 0.55, 2.2, 0.88, 3.0)
	_place_species("oreille", 1300 if pc else 700, 1.6, 0.75, 1.8, 0.92, 2.0)
	_place_species("fougere_arbre", 380 if pc else 220, 2.4, 0.55, 2.2, 0.88, 3.0)
	_place_species("fougere", 7000 if pc else 3500, 1.0, 0.85, 1.8, 0.96, 1.2)
	_place_species("herbe", 12000 if pc else 6000, 0.7, 0.9, 1.7, 0.97, 0.6)
	_place_species("pousse", 2500 if pc else 1200, 1.1, 0.8, 1.8, 0.95, 1.5)
	_flush()
	if pc:
		_make_mist()
	print("ILE_MANGA_V30: jungle plantée ", counts, " en ", Time.get_ticks_msec() - t0, " ms")


# =================================================================== matériaux

func _leaf_mat(key: String, tex: String, normal: String, wind: float, transl: float, rough: float = 0.6) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(LEAF_SHADER)
	m.set_shader_parameter("albedo_tex", load(tex))
	if normal != "":
		m.set_shader_parameter("normal_tex", load(normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", transl)
	m.set_shader_parameter("roughness_value", rough)
	_mats[key] = m
	return m


func _bark_mat(key: String, tex: String, normal: String) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(LEAF_SHADER)
	m.set_shader_parameter("albedo_tex", load(tex))
	if normal != "":
		m.set_shader_parameter("normal_tex", load(normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", 0.03)
	m.set_shader_parameter("translucency", 0.0)
	m.set_shader_parameter("roughness_value", 0.93)
	_mats[key] = m
	return m


func _plain_mat(key: String, base: Color, tip: Color, wind: float) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(LEAF_SHADER)
	m.set_shader_parameter("use_texture", false)
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("tip_color", tip)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", 0.35)
	_mats[key] = m
	return m


func canopy_mat() -> ShaderMaterial:
	var m := _leaf_mat("canopee", TEX + "canopy_leaves.png", TEX + "canopy_leaves_n.png", 0.1, 0.58, 0.45)
	# Vert chaud : sous le ciel, l'ombre des feuillages tire sinon vers le bleu.
	m.set_shader_parameter("tint", Color(0.97, 1.1, 0.72))
	return m


func bark_mat() -> ShaderMaterial:
	return _bark_mat("ecorce", FLORA_TEX + "bark.png", FLORA_TEX + "bark_n.png")


# =================================================================== outils de maillage

func _v(st: SurfaceTool, pos: Vector3, n: Vector3, uv: Vector2, flex: float, outer: float, col: Color = Color.WHITE) -> void:
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(uv)
	st.set_uv2(Vector2(flex, outer))
	st.add_vertex(pos)


func _tube(st: SurfaceTool, path: Array, radii: Array, flex: Array, sides: int, col: Color, uv_scale: float = 0.35) -> void:
	var rings: Array = []
	var along: float = 0.0
	for i in range(path.size()):
		var fwd: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var side: Vector3 = fwd.cross(Vector3(0.31, 0.0, 0.95))
		if side.length() < 0.1:
			side = fwd.cross(Vector3.RIGHT)
		side = side.normalized()
		var up: Vector3 = side.cross(fwd).normalized()
		if i > 0:
			along += (path[i] as Vector3).distance_to(path[i - 1])
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / sides
			var n: Vector3 = side * cos(a) + up * sin(a)
			ring.append([(path[i] as Vector3) + n * float(radii[i]), n, Vector2(float(s) / sides * maxf(1.0, float(radii[i]) * 4.0), along * uv_scale), float(flex[i])])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a: Array = rings[i][s]
			var b: Array = rings[i][s + 1]
			var c: Array = rings[i + 1][s]
			var d: Array = rings[i + 1][s + 1]
			for q in [a, c, b, b, c, d]:
				_v(st, q[0], q[1], q[2], q[3], 0.6, col)


## Carte de feuillage presque horizontale (canopée en strates), normale « de volume ».
func _leaf_card(st: SurfaceTool, center: Vector3, size: float, crown: Vector3, crown_r: float, flex: float, tilt_max: float) -> void:
	var a: float = _rng.randf() * TAU
	var u := Vector3(cos(a), 0, sin(a))
	var perp := Vector3(-u.z, 0, u.x)
	var tilt: float = _rng.randf_range(0.0, tilt_max)
	var v: Vector3 = (perp * cos(tilt) + Vector3.UP * sin(tilt) * (1.0 if _rng.randf() < 0.5 else -1.0)).normalized()
	var hx: Vector3 = u * size * 0.5
	var hy: Vector3 = v * size * 0.5
	var out_dir: Vector3 = (center - crown + Vector3.UP * crown_r * 0.6).normalized()
	var outer: float = clampf(center.distance_to(crown) / maxf(crown_r, 0.01), 0.0, 1.0)
	var p := [center - hx - hy, center + hx - hy, center + hx + hy, center - hx + hy]
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in [0, 1, 2, 0, 2, 3]:
		var n: Vector3 = (out_dir * 0.8 + ((p[i] as Vector3) - center).normalized() * 0.2).normalized()
		_v(st, p[i], n, uv[i], flex, outer)


## Feuille longue (palme, bananier, fronde) : bande courbée, pliée en V le long de la nervure.
## base : point d'attache ; dir : direction horizontale ; rise/droop : forme de l'arc.
func _blade(st: SurfaceTool, base: Vector3, dir: Vector3, length: float, width: float, rise: float, droop: float, fold: float, segs: int, flex0: float = 0.2, col: Color = Color.WHITE) -> void:
	dir = Vector3(dir.x, 0, dir.z).normalized()
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	var rows: Array = []
	for k in range(segs + 1):
		var s: float = float(k) / segs
		var center: Vector3 = base + dir * length * s * (1.0 - 0.15 * s) + Vector3.UP * length * (rise * s - droop * s * s)
		var w: float = width * 0.5 * sin(PI * clampf(s * 1.05 + 0.04, 0.0, 1.0)) ** 0.5
		var tangent: Vector3
		if k < segs:
			var s2: float = float(k + 1) / segs
			tangent = (base + dir * length * s2 * (1.0 - 0.15 * s2) + Vector3.UP * length * (rise * s2 - droop * s2 * s2)) - center
		else:
			tangent = center - (rows[k - 1][1] as Vector3)
		tangent = tangent.normalized()
		var nrm: Vector3 = side.cross(tangent).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		var mid: Vector3 = center + nrm * fold * w
		rows.append([center - side * w, mid, center + side * w, nrm, s])
	for k in range(segs):
		var r0: Array = rows[k]
		var r1: Array = rows[k + 1]
		var v0: float = 1.0 - float(r0[4])
		var v1: float = 1.0 - float(r1[4])
		var f0: float = flex0 + (1.0 - flex0) * float(r0[4])
		var f1: float = flex0 + (1.0 - flex0) * float(r1[4])
		var n0: Vector3 = r0[3]
		var n1: Vector3 = r1[3]
		# moitié gauche puis moitié droite
		for tri in [[r0[0], Vector2(0, v0), f0, n0], [r1[0], Vector2(0, v1), f1, n1], [r0[1], Vector2(0.5, v0), f0, n0],
				[r0[1], Vector2(0.5, v0), f0, n0], [r1[0], Vector2(0, v1), f1, n1], [r1[1], Vector2(0.5, v1), f1, n1],
				[r0[1], Vector2(0.5, v0), f0, n0], [r1[1], Vector2(0.5, v1), f1, n1], [r0[2], Vector2(1, v0), f0, n0],
				[r0[2], Vector2(1, v0), f0, n0], [r1[1], Vector2(0.5, v1), f1, n1], [r1[2], Vector2(1, v1), f1, n1]]:
			_v(st, tri[0], tri[3], tri[1], tri[2], 0.5 + 0.5 * tri[2], col)


func _finish(surfaces: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var idx: int = 0
	for s in surfaces:
		var st: SurfaceTool = s[0]
		st.commit(mesh)
		mesh.surface_set_material(idx, s[1])
		idx += 1
	return mesh


func _new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# =================================================================== essences

## Géant de la canopée (fromager) : contreforts, charpentières en parasol, lianes.
func giant_mesh(variant: int, detailed: bool) -> ArrayMesh:
	var key := "geant_%d_%s" % [variant, detailed]
	if _meshes.has(key):
		return _meshes[key]
	var keep_seed: int = _rng.seed
	_rng.seed = 7700 + variant
	var bark := _new_st()
	var leaves := _new_st()
	var pale := Color(1.15, 1.08, 0.95)
	var h: float = 33.0 + variant * 2.5
	var trunk_top: float = h * 0.74
	var lean := Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6))
	var path: Array = []
	var radii: Array = []
	var flex: Array = []
	for i in range(10):
		var t: float = float(i) / 9.0
		path.append(Vector3.UP * trunk_top * t + lean * t * t)
		radii.append(lerpf(1.25, 0.6, pow(t, 0.7)))
		flex.append(t * t * 0.08)
	_tube(bark, path, radii, flex, 16 if detailed else 7, pale, 0.12)
	# Contreforts : lames de bois qui partent du tronc jusqu'à 4 m au sol.
	var fins: int = 6 if detailed else 4
	for f in range(fins):
		var a: float = TAU * f / fins + _rng.randf_range(-0.25, 0.25)
		var d := Vector3(cos(a), 0, sin(a))
		var tg := Vector3(-d.z, 0, d.x)
		var hb: float = _rng.randf_range(4.0, 6.5)
		var reach: float = _rng.randf_range(2.6, 4.2)
		var steps: int = 8
		for k in range(steps):
			var y0: float = hb * k / steps
			var y1: float = hb * (k + 1) / steps
			var e0: float = 1.1 + reach * pow(1.0 - y0 / hb, 2.2)
			var e1: float = 1.1 + reach * pow(1.0 - y1 / hb, 2.2)
			var w0: float = 0.22 * (1.0 - y0 / hb) + 0.05
			var w1: float = 0.22 * (1.0 - y1 / hb) + 0.05
			var snake0: Vector3 = tg * sin(e0 * 0.9) * 0.35
			var snake1: Vector3 = tg * sin(e1 * 0.9) * 0.35
			for sgn in [-1.0, 1.0]:
				var i0: Vector3 = d * 0.9 + tg * sgn * w0 + Vector3.UP * y0
				var o0: Vector3 = d * e0 + snake0 + tg * sgn * w0 * 0.6 + Vector3.UP * y0
				var i1: Vector3 = d * 0.9 + tg * sgn * w1 + Vector3.UP * y1
				var o1: Vector3 = d * e1 + snake1 + tg * sgn * w1 * 0.6 + Vector3.UP * y1
				var n: Vector3 = tg * sgn
				for q in [[i0, Vector2(0, y0 * 0.3)], [o0, Vector2(e0 * 0.3, y0 * 0.3)], [i1, Vector2(0, y1 * 0.3)], [i1, Vector2(0, y1 * 0.3)], [o0, Vector2(e0 * 0.3, y0 * 0.3)], [o1, Vector2(e1 * 0.3, y1 * 0.3)]]:
					_v(bark, q[0], n, q[1], 0.0, 0.6, pale)
			# arête supérieure de la lame
			var t0: Vector3 = d * e0 + snake0 + Vector3.UP * y0
			var t1: Vector3 = d * e1 + snake1 + Vector3.UP * y1
			var nu: Vector3 = (d + Vector3.UP * 0.6).normalized()
			for q in [[t0 - tg * w0 * 0.6, Vector2(0, 0)], [t0 + tg * w0 * 0.6, Vector2(0.2, 0)], [t1 - tg * w1 * 0.6, Vector2(0, 0.3)], [t1 - tg * w1 * 0.6, Vector2(0, 0.3)], [t0 + tg * w0 * 0.6, Vector2(0.2, 0)], [t1 + tg * w1 * 0.6, Vector2(0.2, 0.3)]]:
				_v(bark, q[0], nu, q[1], 0.0, 0.6, pale)
	# Charpentières et couronne en parasol.
	var top: Vector3 = path[9]
	var crown := top + Vector3.UP * h * 0.12
	var crown_r: float = h * 0.36
	var branches: int = _rng.randi_range(6, 8)
	var ends: Array = []
	for b in range(branches):
		var a: float = TAU * b / branches + _rng.randf_range(-0.3, 0.3)
		var start: Vector3 = path[_rng.randi_range(7, 9)]
		var dir := Vector3(cos(a), _rng.randf_range(0.35, 0.7), sin(a)).normalized()
		var blen: float = _rng.randf_range(8.0, 12.0)
		var bp: Array = [start]
		var br: Array = []
		var bf: Array = []
		for s in range(1, 6):
			var p: Vector3 = (bp[s - 1] as Vector3) + dir * blen / 5.0 + Vector3(_rng.randf_range(-0.4, 0.4), -0.15 * s * s * 0.1, _rng.randf_range(-0.4, 0.4))
			bp.append(p)
		for s in range(bp.size()):
			br.append(lerpf(0.5, 0.14, float(s) / 5.0))
			bf.append(0.05 + 0.25 * float(s) / 5.0)
		_tube(bark, bp, br, bf, 9 if detailed else 5, pale, 0.2)
		ends.append(bp[5])
		ends.append(bp[3])
	var cards: int = 420 if detailed else 130
	for c in range(cards):
		var e: Vector3 = ends[_rng.randi() % ends.size()]
		var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.35, 0.6), _rng.randf_range(-1, 1)) * _rng.randf_range(1.0, 4.2)
		_leaf_card(leaves, e + off, _rng.randf_range(2.8, 4.0) * (1.0 if detailed else 2.0), crown, crown_r, 0.4 + 0.3 * _rng.randf(), 0.7)
	# Lianes : elles tombent des charpentières jusqu'au sol, légèrement en arc.
	if detailed:
		var vine_col := Color(0.55, 0.5, 0.38)
		for l in range(_rng.randi_range(5, 8)):
			var from: Vector3 = (ends[_rng.randi() % ends.size()] as Vector3).lerp(top, _rng.randf_range(0.1, 0.5))
			var ground := Vector3(from.x * 0.85 + _rng.randf_range(-2, 2), 0.0, from.z * 0.85 + _rng.randf_range(-2, 2))
			var vp: Array = []
			var vr: Array = []
			var vf: Array = []
			for s in range(13):
				var t: float = float(s) / 12.0
				var p: Vector3 = from.lerp(ground, t) + Vector3(sin(t * 7.0 + l) * 0.3, -sin(t * PI) * 0.0, cos(t * 5.0 + l) * 0.3)
				p += (Vector3(from.x, 0, from.z).normalized() if from.length() > 0.1 else Vector3.RIGHT) * sin(t * PI) * 1.4
				vp.append(p)
				vr.append(lerpf(0.09, 0.05, t))
				vf.append(sin(t * PI) * 0.6)
			_tube(bark, vp, vr, vf, 5, vine_col, 0.5)
			for k in range(6):
				var q: Vector3 = vp[_rng.randi_range(2, 11)]
				_leaf_card(leaves, q + Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3)), _rng.randf_range(0.7, 1.1), q, 1.0, 0.6, 1.4)
	var mesh := _finish([[bark, bark_mat()], [leaves, canopy_mat()]])
	_rng.seed = keep_seed
	_meshes[key] = mesh
	return mesh


## Arbre de canopée : tronc droit, houppier arrondi assez haut.
func canopy_tree_mesh(variant: int, detailed: bool) -> ArrayMesh:
	var key := "canopee_%d_%s" % [variant, detailed]
	if _meshes.has(key):
		return _meshes[key]
	var keep_seed: int = _rng.seed
	_rng.seed = 8800 + variant
	var bark := _new_st()
	var leaves := _new_st()
	var h: float = 15.0 + variant * 1.5
	var trunk_top: float = h * 0.5
	var path: Array = []
	var radii: Array = []
	var flex: Array = []
	var lean := Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
	for i in range(7):
		var t: float = float(i) / 6.0
		path.append(Vector3.UP * trunk_top * t + lean * t * t)
		radii.append(lerpf(0.42, 0.22, t) * (1.25 if i == 0 else 1.0))
		flex.append(t * t * 0.12)
	_tube(bark, path, radii, flex, 9 if detailed else 5, Color(0.85, 0.82, 0.74), 0.25)
	var crown: Vector3 = path[6] + Vector3.UP * h * 0.2
	var crown_r: float = h * 0.32
	var ends: Array = []
	for b in range(5):
		var a: float = TAU * b / 5.0 + _rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), _rng.randf_range(0.6, 1.1), sin(a)).normalized()
		var bp: Array = [path[_rng.randi_range(4, 6)]]
		for s in range(1, 4):
			bp.append((bp[s - 1] as Vector3) + dir * crown_r * 0.33)
		_tube(bark, bp, [0.18, 0.12, 0.08, 0.04], [0.1, 0.25, 0.4, 0.55], 6 if detailed else 4, Color(0.85, 0.82, 0.74), 0.3)
		ends.append(bp[3])
		ends.append(bp[2])
	var cards: int = 170 if detailed else 55
	for c in range(cards):
		var d := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.5, 0.8), _rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = crown + Vector3(d.x, d.y * 0.85, d.z) * crown_r * _rng.randf_range(0.4, 1.0)
		if _rng.randf() < 0.5:
			p = (ends[_rng.randi() % ends.size()] as Vector3) + d * _rng.randf_range(0.3, 1.5)
		_leaf_card(leaves, p, _rng.randf_range(1.9, 2.8) * (1.0 if detailed else 2.1), crown, crown_r, 0.45 + 0.3 * _rng.randf(), 1.1)
	var mesh := _finish([[bark, bark_mat()], [leaves, canopy_mat()]])
	_rng.seed = keep_seed
	_meshes[key] = mesh
	return mesh


## Cocotier : stipe courbe annelé, couronne de palmes retombantes, noix de coco.
func palm_mesh(variant: int, detailed: bool) -> ArrayMesh:
	var key := "palmier_%d_%s" % [variant, detailed]
	if _meshes.has(key):
		return _meshes[key]
	var keep_seed: int = _rng.seed
	_rng.seed = 9900 + variant
	var trunk := _new_st()
	var fronds := _new_st()
	var nuts := _new_st()
	var h: float = 8.0 + variant * 1.2
	var bend: float = 1.6 + variant * 0.7
	var path: Array = []
	var radii: Array = []
	var flex: Array = []
	for i in range(12):
		var t: float = float(i) / 11.0
		path.append(Vector3(bend * pow(t, 1.7), h * t, 0.0))
		radii.append(lerpf(0.24, 0.15, t) + (0.08 if i == 0 else 0.0))
		flex.append(t * t * 0.35)
	_tube(trunk, path, radii, flex, 10 if detailed else 5, Color.WHITE, 0.5)
	var top: Vector3 = path[11]
	var n_fronds: int = 15 if detailed else 8
	for f in range(n_fronds):
		var a: float = TAU * f / n_fronds + _rng.randf_range(-0.15, 0.15)
		var young: bool = f % 5 == 0
		_blade(fronds, top, Vector3(cos(a), 0, sin(a)), _rng.randf_range(3.6, 4.6), 1.15 if detailed else 1.6, 0.9 if young else 0.45, 1.2 if young else 1.25, 0.18, 9 if detailed else 4, 0.3)
	if detailed:
		for k in range(5):
			var a2: float = TAU * k / 5.0
			var c: Vector3 = top + Vector3(cos(a2) * 0.28, -0.35 - 0.1 * (k % 2), sin(a2) * 0.28)
			var sm := SphereMesh.new()
			sm.radius = 0.15
			sm.height = 0.32
			sm.radial_segments = 8
			sm.rings = 5
			var arr: Array = sm.get_mesh_arrays()
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for i in idx:
				_v(nuts, verts[i] + c, norms[i], Vector2(0.5, 0.5), 0.35, 0.5, Color(0.42, 0.36, 0.16) if k % 2 == 0 else Color(0.36, 0.42, 0.14))
	var surfaces: Array = [[trunk, _bark_mat("stipe", TEX + "palm_trunk.png", "")], [fronds, _leaf_mat("palme", TEX + "palm_frond.png", "", 0.32, 0.5, 0.5)]]
	if detailed:
		surfaces.append([nuts, _plain_mat("coco", Color(1, 1, 1), Color(1, 1, 1), 0.2)])
	var mesh := _finish(surfaces)
	_rng.seed = keep_seed
	_meshes[key] = mesh
	return mesh


## Bananier (grand) ou « oreille d'éléphant » (bas, feuilles larges).
func broadleaf_plant_mesh(kind: String, variant: int) -> ArrayMesh:
	var key := "%s_%d" % [kind, variant]
	if _meshes.has(key):
		return _meshes[key]
	var keep_seed: int = _rng.seed
	_rng.seed = 6600 + variant + (50 if kind == "oreille" else 0)
	var stem := _new_st()
	var leaves := _new_st()
	var tall: bool = kind == "bananier"
	var h: float = (2.0 + variant * 0.4) if tall else (0.25 + variant * 0.1)
	if tall:
		_tube(stem, [Vector3.ZERO, Vector3.UP * h * 0.5, Vector3.UP * h], [0.16, 0.13, 0.1], [0.0, 0.1, 0.2], 7, Color(0.55, 0.72, 0.38), 0.5)
	var n_leaves: int = 8 if tall else 6
	for k in range(n_leaves):
		var a: float = TAU * k / n_leaves + _rng.randf_range(-0.3, 0.3)
		var base := Vector3.UP * h * _rng.randf_range(0.85, 1.0)
		var length: float = _rng.randf_range(1.8, 2.5) if tall else _rng.randf_range(0.9, 1.3)
		var width: float = 0.62 if tall else 0.75
		if not tall:
			# Pétiole dressé puis limbe large et retombant.
			var pet_end: Vector3 = base + Vector3(cos(a), 0, sin(a)) * 0.35 + Vector3.UP * _rng.randf_range(0.5, 0.9)
			_tube(stem, [base, pet_end], [0.03, 0.02], [0.0, 0.4], 4, Color(0.6, 0.75, 0.4), 0.5)
			base = pet_end
		_blade(leaves, base, Vector3(cos(a), 0, sin(a)), length, width, 0.55 if tall else 0.2, 0.95 if tall else 0.7, 0.08, 7, 0.25)
	var mesh := _finish([[stem, _plain_mat("tige_verte", Color(0.32, 0.45, 0.18), Color(0.5, 0.6, 0.3), 0.06)], [leaves, _leaf_mat("bananier", TEX + "broadleaf.png", "", 0.2, 0.55, 0.42)]])
	_rng.seed = keep_seed
	_meshes[key] = mesh
	return mesh


## Fougère arborescente : stipe fin et sombre, couronne de longues frondes.
func tree_fern_mesh(variant: int) -> ArrayMesh:
	var key := "fougere_arbre_%d" % variant
	if _meshes.has(key):
		return _meshes[key]
	var keep_seed: int = _rng.seed
	_rng.seed = 5500 + variant
	var trunk := _new_st()
	var fronds := _new_st()
	var h: float = 2.2 + variant * 0.8
	var path: Array = []
	for i in range(5):
		var t: float = float(i) / 4.0
		path.append(Vector3(sin(t * 2.0 + variant) * 0.2 * t, h * t, 0))
	_tube(trunk, path, [0.17, 0.14, 0.13, 0.12, 0.14], [0.0, 0.05, 0.1, 0.15, 0.2], 7, Color(0.45, 0.38, 0.3), 0.6)
	for f in range(12):
		var a: float = TAU * f / 12.0 + _rng.randf_range(-0.2, 0.2)
		_blade(fronds, path[4], Vector3(cos(a), 0, sin(a)), _rng.randf_range(2.0, 2.6), 0.75, 0.6, 1.05, 0.05, 7, 0.3)
	var mesh := _finish([[trunk, bark_mat()], [fronds, _leaf_mat("fronde", FLORA_TEX + "fern.png", "", 0.22, 0.5, 0.7)]])
	_rng.seed = keep_seed
	_meshes[key] = mesh
	return mesh


func ground_mesh(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var Flora = preload("res://scripts/flora_v25.gd")
	var mesh: ArrayMesh
	match kind:
		"fougere":
			mesh = Flora.fern_clump().duplicate()
			mesh.surface_set_material(0, _leaf_mat("fougere_sol", FLORA_TEX + "fern.png", "", 0.12, 0.45, 0.75))
		"herbe":
			mesh = Flora.grass_clump(12, 0.55, 0.045, 17).duplicate()
			mesh.surface_set_material(0, _plain_mat("herbe_jungle", Color(0.07, 0.17, 0.05), Color(0.3, 0.46, 0.12), 0.12))
		"arbuste":
			mesh = Flora.bush(31).duplicate()
			mesh.surface_set_material(0, bark_mat())
			mesh.surface_set_material(1, canopy_mat())
		_:
			mesh = broadleaf_plant_mesh("oreille", 0)
	_meshes[kind] = mesh
	return mesh


# =================================================================== répartition

## Point de plantation : {ok, pos (monde), slope}. local = coordonnées autour du centre de l'île.
func _spot(local: Vector2, max_slope: float, min_h: float, clear_gorge: float) -> Dictionary:
	var c: Vector3 = jungle.CENTER
	var wx: float = c.x + local.x
	var wz: float = c.z + local.y
	var h: float = jungle.height(wx, wz)
	if h < min_h:
		return {}
	var e: float = 0.8
	var gx: float = jungle.height(wx + e, wz) - jungle.height(wx - e, wz)
	var gz: float = jungle.height(wx, wz + e) - jungle.height(wx, wz - e)
	var slope: float = sqrt(gx * gx + gz * gz) / (2.0 * e)
	if slope > max_slope:
		return {}
	if jungle.gorge_distance(local.x, local.y) < clear_gorge:
		return {}
	for tw in jungle.TOWERS:
		if local.distance_to(tw[0]) < float(tw[1]) + 1.5:
			return {}
	for cl in clearings:
		if local.distance_to(cl[0]) < float(cl[1]):
			return {}
	# Plage du ponton : dégagée.
	var dock: Vector3 = jungle.dock_start - c
	if Vector2(local.x - dock.x, local.y - dock.z).length() < 14.0:
		return {}
	return {"pos": Vector3(wx, h, wz), "slope": slope, "h": h}


func _random_local(r_min: float, r_max: float) -> Vector2:
	var a: float = _rng.randf() * TAU
	var r: float = sqrt(_rng.randf_range(r_min * r_min, r_max * r_max))
	return Vector2(cos(a) * r, sin(a) * r)


## Une parcelle tous les ~41 m (8 x 8 sur l'île).
func _chunk_of(pos: Vector3) -> Vector2i:
	var c: Vector3 = jungle.CENTER
	return Vector2i(clampi(int((pos.x - c.x + 165.0) / 41.25), 0, 7), clampi(int((pos.z - c.z + 165.0) / 41.25), 0, 7))


func _add(species: String, xf: Transform3D) -> void:
	var key: String = species + "|" + str(_chunk_of(xf.origin))
	if not _batches.has(key):
		_batches[key] = []
	(_batches[key] as Array).append(xf)
	counts[species.split("#")[0]] = int(counts.get(species.split("#")[0], 0)) + 1


func _yaw_xf(pos: Vector3, scale_v: float, sink: float = 0.05) -> Transform3D:
	var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_v)
	return Transform3D(b, pos - Vector3.UP * sink)


func _cylinder(pos: Vector3, radius: float, height: float) -> void:
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	cs.shape = s
	cs.position = pos + Vector3.UP * height * 0.5
	_trunks.add_child(cs)


func _place_giants(target: int) -> void:
	var placed: Array = []
	var tries: int = 0
	while placed.size() < target and tries < 6000:
		tries += 1
		var l: Vector2 = _random_local(0.0, 100.0)
		if jungle.coast_ratio(l.x, l.y) > 0.8:
			continue
		var s: Dictionary = _spot(l, 0.45, 3.0, 12.0)
		if s.is_empty():
			continue
		var p: Vector3 = s["pos"]
		var far_enough: bool = true
		for q in placed:
			if Vector2(p.x - q.x, p.z - q.z).length() < 19.0:
				far_enough = false
				break
		if not far_enough:
			continue
		placed.append(p)
		var v: int = placed.size() % 4
		var xf := _yaw_xf(p, _rng.randf_range(0.9, 1.1), 0.3)
		_add("geant#%d" % v, xf)
		_cylinder(p, 1.45, 24.0)


func _place_palms(target: int) -> void:
	var n: int = 0
	var tries: int = 0
	while n < target and tries < 8000:
		tries += 1
		var l: Vector2 = _random_local(40.0, 130.0)
		var ratio: float = jungle.coast_ratio(l.x, l.y)
		if ratio < 0.8 or ratio > 1.0:
			continue
		var s: Dictionary = _spot(l, 0.4, 0.15, 6.0)
		if s.is_empty() or float(s["h"]) > 4.5:
			continue
		var p: Vector3 = s["pos"]
		# Les cocotiers penchent vers la mer.
		var to_sea := Vector3(l.x, 0, l.y).normalized()
		var yaw: float = atan2(-to_sea.z, to_sea.x) + _rng.randf_range(-0.5, 0.5)
		var b := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.15))
		_add("palmier#%d" % (n % 3), Transform3D(b, p - Vector3.UP * 0.1))
		_cylinder(p, 0.26, 3.5)
		n += 1


## Quelques cocotiers de part et d'autre du ponton, dans la baie où l'on accoste.
func _place_bay_palms(target: int) -> void:
	var n: int = 0
	var tries: int = 0
	var dock: Vector3 = jungle.dock_start - jungle.CENTER
	while n < target and tries < 4000:
		tries += 1
		var a: float = PI * 0.5 + _rng.randf_range(-0.75, 0.75)
		var r: float = _rng.randf_range(55.0, 95.0)
		var l := Vector2(cos(a) * r, sin(a) * r)
		var h: float = jungle.height(jungle.CENTER.x + l.x, jungle.CENTER.z + l.y)
		if h < 0.3 or h > 2.6 or Vector2(l.x - dock.x, l.y - dock.z).length() < 9.0:
			continue
		var in_clearing: bool = false
		for cl in clearings:
			if l.distance_to(cl[0]) < float(cl[1]):
				in_clearing = true
		if in_clearing:
			continue
		var s: Dictionary = _spot(l, 0.5, 0.3, 4.0)
		if s.is_empty():
			s = {"pos": Vector3(jungle.CENTER.x + l.x, h, jungle.CENTER.z + l.y)}
		var p: Vector3 = s["pos"]
		var b := Basis(Vector3.UP, atan2(-l.y, l.x) + _rng.randf_range(-0.6, 0.6)).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.2))
		_add("palmier#%d" % (n % 3), Transform3D(b, p - Vector3.UP * 0.1))
		_cylinder(p, 0.26, 3.5)
		n += 1


## Essences « ordinaires » : nombre visé, espacement mini, pente maxi, hauteur mini,
## rapport au rivage maxi (0 = centre, 1 = rivage), gorge à dégager (m).
func _place_species(species: String, target: int, spacing: float, max_slope: float, min_h: float, max_ratio: float, clear_gorge: float) -> void:
	var n: int = 0
	var tries: int = 0
	var grid: Dictionary = {}
	while n < target and tries < target * 12:
		tries += 1
		var l: Vector2 = _random_local(0.0, 125.0)
		if jungle.coast_ratio(l.x, l.y) > max_ratio:
			continue
		var cell := Vector2i(int(floor(l.x / spacing)), int(floor(l.y / spacing)))
		if grid.has(cell):
			continue
		var s: Dictionary = _spot(l, max_slope, min_h, clear_gorge)
		if s.is_empty():
			continue
		grid[cell] = true
		var p: Vector3 = s["pos"]
		match species:
			"canopee":
				_add("canopee#%d" % (n % 4), _yaw_xf(p, _rng.randf_range(0.85, 1.15), 0.15))
				_cylinder(p, 0.45, 8.0)
			"bananier":
				_add("bananier#%d" % (n % 3), _yaw_xf(p, _rng.randf_range(0.8, 1.2)))
			"oreille":
				_add("oreille#%d" % (n % 3), _yaw_xf(p, _rng.randf_range(0.7, 1.3)))
			"fougere_arbre":
				_add("fougere_arbre#%d" % (n % 3), _yaw_xf(p, _rng.randf_range(0.8, 1.2), 0.1))
				_cylinder(p, 0.18, 2.5)
			"fougere":
				_add("fougere", _yaw_xf(p, _rng.randf_range(0.9, 1.6)))
			"herbe":
				_add("herbe", _yaw_xf(p, _rng.randf_range(0.8, 1.4)))
			"pousse":
				_add("pousse", _yaw_xf(p, _rng.randf_range(0.35, 0.6)))
			"arbuste":
				_add("arbuste", _yaw_xf(p, _rng.randf_range(1.5, 2.6), 0.1))
		n += 1


## Distances d'affichage (m) : [début détaillé, fin détaillé, fin version allégée].
func _ranges(species: String) -> Array:
	match species:
		"geant":
			return [0.0, 170.0 if pc else 120.0, 1400.0]
		"canopee":
			return [0.0, 120.0 if pc else 85.0, 1400.0]
		"palmier":
			return [0.0, 140.0 if pc else 100.0, 1400.0]
		"bananier", "fougere_arbre":
			return [0.0, 95.0 if pc else 65.0, 0.0]
		"arbuste":
			return [0.0, 75.0 if pc else 55.0, 1400.0]
		"oreille", "pousse":
			return [0.0, 75.0 if pc else 55.0, 0.0]
		_:
			return [0.0, 55.0 if pc else 40.0, 0.0]


func _species_mesh(species: String, variant: int, detailed: bool) -> Mesh:
	match species:
		"geant":
			return giant_mesh(variant, detailed)
		"canopee":
			return canopy_tree_mesh(variant, detailed)
		"palmier":
			return palm_mesh(variant, detailed)
		"bananier", "oreille":
			return broadleaf_plant_mesh(species, variant)
		"fougere_arbre":
			return tree_fern_mesh(variant)
		_:
			return ground_mesh(species)


func _flush() -> void:
	for key in _batches:
		var parts: PackedStringArray = (key as String).split("|")
		var sp: PackedStringArray = parts[0].split("#")
		var species: String = sp[0]
		var variant: int = int(sp[1]) if sp.size() > 1 else 0
		var list: Array = _batches[key]
		var r: Array = _ranges(species)
		_emit(species, variant, list, true, r[0], r[1], key)
		if float(r[2]) > 0.0:
			_emit(species, variant, list, false, r[1], r[2], key)


func _emit(species: String, variant: int, list: Array, detailed: bool, begin: float, end: float, key: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _species_mesh(species, variant, detailed)
	mm.instance_count = list.size()
	for i in range(list.size()):
		mm.set_instance_transform(i, list[i])
		var tint: float = _rng.randf_range(0.88, 1.08)
		mm.set_instance_color(i, Color(tint, tint * _rng.randf_range(0.96, 1.04), tint * 0.97))
	var inst := MultiMeshInstance3D.new()
	inst.name = ("Jungle_" + key + ("" if detailed else "_loin")).replace("|", "_").replace("#", "_").replace("(", "").replace(")", "").replace(", ", "_")
	inst.multimesh = mm
	inst.visibility_range_begin = begin
	inst.visibility_range_begin_margin = 6.0 if begin > 0.0 else 0.0
	inst.visibility_range_end = end
	inst.visibility_range_end_margin = 6.0
	var big: bool = species in ["geant", "canopee", "palmier"]
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (detailed and (big or species in ["bananier", "fougere_arbre", "arbuste"])) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)


# =================================================================== brume

func _make_mist() -> void:
	var fog := FogVolume.new()
	fog.name = "Brume_jungle_v30"
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fog.size = Vector3(300.0, 26.0, 300.0)
	fog.position = jungle.CENTER + Vector3(0, 9.0, 0)
	var m := FogMaterial.new()
	m.density = 0.035
	m.albedo = Color(0.82, 0.9, 0.84)
	m.height_falloff = 0.08
	m.edge_fade = 0.4
	fog.material = m
	add_child(fog)

extends Node3D
## V58 : l'île du royaume des fées, très haut au-dessus d'une mer de nuages.
##  - Le dessus : une prairie en fleurs (herbe, fleurs de toutes les couleurs, cerisiers en
##    fleurs, champignons géants qui luisent, cristaux), le grand replat d'Yggdrasil au nord,
##    la clairière des fées au sud, le cercle de champignons (on y arrive, on en repart), un
##    étang aux nénuphars et des ruisseaux qui tombent dans les nuages.
##  - Le dessous : une montagne renversée de roche, veinée de cristaux roses et violets, des
##    racines qui pendent dans le vide, des îlots qui flottent.
##  - Tout autour, la mer de nuages, dorée au soleil.
## Le relief se calcule à la demande (height) et sert aussi de sol physique.

const Flora = preload("res://scripts/flora_v25.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const Gfx = preload("res://scripts/feerique_gfx_v45.gd")
const CENTER := Vector3(-470.0, 0.0, 520.0)
const Y0: float = 700.0
const R0: float = 86.0
const NR: int = 60
const NS: int = 240
const DEPTH: float = 96.0
const CLOUD_Y: float = Y0 - 78.0
## Repère local de l'île (+Z vers le sud)
const TREE := Vector2(0.0, -22.0)
const TREE_FLAT: float = 34.0
const PLATEAU_H: float = 2.0
const GLADE := Vector2(0.0, 54.0)
const GLADE_R: float = 15.0
const RING := Vector2(-30.0, 60.0)
const RING_R: float = 4.6
const POND := Vector2(34.0, 30.0)
const POND_R: float = 8.5
## Les sources : [source (local), angle du déversoir]
const SPRINGS := [[Vector2(41.0, 32.0), 0.35], [Vector2(-44.0, 8.0), PI - 0.15], [Vector2(36.0, -54.0), -0.95]]

var pc: bool = true
var streams: Array = []
var falls: Array = []
var lights: Array = []                  # lumières des champignons (éteintes de loin)
var _noise := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _body: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _gfx


func build(high_quality: bool) -> void:
	pc = high_quality
	_gfx = Gfx.new()
	_rng.seed = 5858
	_noise.seed = 581
	_noise.frequency = 0.022
	_noise.fractal_octaves = 4
	_coast.seed = 582
	_coast.frequency = 0.9
	_coast.fractal_octaves = 3
	_under.seed = 583
	_under.frequency = 0.06
	_under.fractal_octaves = 4
	_body = StaticBody3D.new()
	_body.name = "Fees_sol"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_plan_streams()
	_build_top()
	_build_under()
	_build_water()
	_build_pond()
	_build_cloud_sea()
	_build_flora()
	_build_mushrooms()
	_build_ring()
	_build_rocks()
	_build_underside_details()
	_build_motes()


# =================================================================== forme

func coast_radius(theta: float) -> float:
	var n: float = _coast.get_noise_2d(cos(theta) * 1.6, sin(theta) * 1.6)
	return R0 + n * 9.0 + sin(theta * 3.0 + 1.6) * 3.0


func _plan_streams() -> void:
	streams.clear()
	for sp in SPRINGS:
		var s: Vector2 = sp[0]
		var ang: float = float(sp[1])
		var dir := Vector2(cos(ang), sin(ang))
		var rim: Vector2 = dir * coast_radius(ang)
		var mid: Vector2 = s.lerp(rim, 0.5) + Vector2(-dir.y, dir.x) * 4.0
		var pts: Array = []
		for k in range(19):
			var t: float = float(k) / 18.0
			pts.append(s.lerp(mid, t).lerp(mid.lerp(rim, t), t))
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in pts:
			lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
			hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
		streams.append({"pts": pts, "rim": rim, "dir": dir, "angle": ang, "spring": s, "lo": lo - Vector2(5, 5), "hi": hi + Vector2(5, 5)})


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Array:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return [p.distance_to(a + ab * t), t]


func stream_dist(l: Vector2) -> Array:
	var best: float = INF
	var prog: float = 0.0
	for s in streams:
		var lo: Vector2 = s["lo"]
		var hi: Vector2 = s["hi"]
		if l.x < lo.x or l.y < lo.y or l.x > hi.x or l.y > hi.y:
			continue
		var pts: Array = s["pts"]
		for k in range(pts.size() - 1):
			var r: Array = _seg_dist(l, pts[k], pts[k + 1])
			if float(r[0]) < best:
				best = float(r[0])
				prog = (k + float(r[1])) / float(pts.size() - 1)
	return [best, prog]


func _on_path(l: Vector2) -> float:
	# le chemin de la clairière au pied d'Yggdrasil, en légère courbe
	if l.y < TREE.y + 20.0 or l.y > GLADE.y:
		return 0.0
	var cx: float = sin((l.y - TREE.y) * 0.06) * 3.0
	return 1.0 - smoothstep(2.4, 4.6, absf(l.x - cx))


## Hauteur du dessus, en repère local (par rapport à Y0).
func top_local(lx: float, lz: float) -> float:
	var l := Vector2(lx, lz)
	var r: float = l.length()
	var theta: float = atan2(lz, lx)
	var rr: float = coast_radius(theta)
	var hills: float = _noise.get_noise_2d(lx, lz) * 3.4 + _noise.get_noise_2d(lx * 2.3 + 40.0, lz * 2.3) * 0.8
	var h: float = 1.6 + hills * smoothstep(8.0, 30.0, r)
	# Une butte fleurie à l'ouest, un vallon à l'est
	h += 3.2 * exp(-pow(Vector2(lx + 44.0, lz - 30.0).length() / 13.0, 2.0))
	# Le replat d'Yggdrasil, la clairière, le cercle de champignons, le chemin
	h = lerpf(h, PLATEAU_H, 1.0 - smoothstep(TREE_FLAT, TREE_FLAT + 12.0, l.distance_to(TREE)))
	h = lerpf(h, PLATEAU_H, 1.0 - smoothstep(GLADE_R, GLADE_R + 9.0, l.distance_to(GLADE)))
	h = lerpf(h, PLATEAU_H, 1.0 - smoothstep(RING_R + 2.0, RING_R + 8.0, l.distance_to(RING)))
	h = lerpf(h, PLATEAU_H, _on_path(l))
	# L'étang
	var dp: float = l.distance_to(POND)
	h = lerpf(h, PLATEAU_H, 1.0 - smoothstep(POND_R + 2.0, POND_R + 9.0, dp))
	h -= 1.7 * (1.0 - smoothstep(POND_R - 3.0, POND_R + 1.0, dp))
	# Les ruisseaux creusent leur lit
	var sd: Array = stream_dist(l)
	var cut: float = 1.0 - smoothstep(1.3, 3.4, float(sd[0]))
	h -= cut * (0.9 + 0.5 * float(sd[1]))
	# Bord arrondi : la prairie bascule dans le vide
	h -= 3.0 * pow(smoothstep(rr - 7.0, rr, r), 1.6)
	return h


## Hauteur du sol (monde), ou -INF hors de l'île.
func height(wx: float, wz: float) -> float:
	var lx: float = wx - CENTER.x
	var lz: float = wz - CENTER.z
	if lx * lx + lz * lz > 110.0 * 110.0:
		return -INF
	if Vector2(lx, lz).length() > coast_radius(atan2(lz, lx)):
		return -INF
	return Y0 + top_local(lx, lz)


func walkable(wx: float, wz: float) -> bool:
	var lx: float = wx - CENTER.x
	var lz: float = wz - CENTER.z
	if lx * lx + lz * lz > 110.0 * 110.0:
		return false
	return Vector2(lx, lz).length() < coast_radius(atan2(lz, lx)) - 1.4


func near(p: Vector3, margin: float = 20.0) -> bool:
	var lx: float = p.x - CENTER.x
	var lz: float = p.z - CENTER.z
	return lx * lx + lz * lz < (R0 + 14.0 + margin) * (R0 + 14.0 + margin) and p.y > Y0 - 60.0


func world(l: Vector2, dy: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + l.x, Y0 + top_local(l.x, l.y) + dy, CENTER.z + l.y)


func pond_level() -> float:
	return Y0 + PLATEAU_H - 0.5


# =================================================================== le dessus

func _ring_point(i: int, j: int) -> Vector3:
	var theta: float = TAU * float(j) / NS
	var rr: float = coast_radius(theta)
	var r: float = rr * pow(float(i) / NR, 0.8)
	var lx: float = cos(theta) * r
	var lz: float = sin(theta) * r
	return Vector3(lx, top_local(lx, lz), lz)


func _build_top() -> void:
	var pts: Array = []
	for i in range(NR + 1):
		var row: Array = []
		for j in range(NS):
			row.append(_ring_point(i, j) if i > 0 else Vector3(0, top_local(0, 0), 0))
		pts.append(row)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var faces := PackedVector3Array()
	var nrm: Array = []
	for i in range(NR + 1):
		var nrow: Array = []
		for j in range(NS):
			if i == 0:
				nrow.append(Vector3.UP)
				continue
			var p: Vector3 = pts[i][j]
			var pin: Vector3 = pts[i - 1][j] if i > 1 else pts[0][0]
			var pout: Vector3 = pts[mini(i + 1, NR)][j]
			var pl: Vector3 = pts[i][(j + NS - 1) % NS]
			var pr: Vector3 = pts[i][(j + 1) % NS]
			var n: Vector3 = (pout - pin).cross(pr - pl).normalized()
			if n.y < 0.0:
				n = -n
			nrow.append(n)
		nrm.append(nrow)
	var flip: bool = false
	var a0: Vector3 = pts[1][0]
	var b0: Vector3 = pts[2][0]
	var c0: Vector3 = pts[1][1]
	if (b0 - a0).cross(c0 - a0).y > 0.0:
		flip = true
	for i in range(NR):
		for j in range(NS):
			var j2: int = (j + 1) % NS
			var quad: Array = [[i, j], [i + 1, j], [i, j2], [i + 1, j], [i + 1, j2], [i, j2]]
			if i == 0:
				quad = [[0, j], [1, j], [1, j2]]
			for t in range(0, quad.size(), 3):
				var tri: Array = [quad[t], quad[t + 1], quad[t + 2]]
				if i == 0:
					var pa: Vector3 = pts[0][0]
					var pb: Vector3 = pts[1][j]
					var pc2: Vector3 = pts[1][j2]
					if (pb - pa).cross(pc2 - pa).y > 0.0:
						tri = [quad[0], quad[2], quad[1]]
				elif flip:
					tri = [tri[0], tri[2], tri[1]]
				for v in tri:
					var p2: Vector3 = pts[v[0]][v[1]]
					var world_p := Vector3(CENTER.x + p2.x, Y0 + p2.y, CENTER.z + p2.z)
					verts.append(world_p)
					normals.append(nrm[v[0]][v[1]])
					faces.append(world_p)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var base := "res://assets/textures/"
	mat.set_shader_parameter("sand_tex", load(base + "terrain/sand.jpg"))
	mat.set_shader_parameter("sand_n", load(base + "terrain/sand_n.png"))
	mat.set_shader_parameter("moss_tex", load(base + "terrain/grass.jpg"))
	mat.set_shader_parameter("moss_n", load(base + "terrain/grass_n.png"))
	mat.set_shader_parameter("soil_tex", load(base + "jungle/jungle_moss.png"))
	mat.set_shader_parameter("soil_n", load(base + "jungle/jungle_moss_n.png"))
	mat.set_shader_parameter("rock_tex", load(base + "ciel/roche_ciel.png"))
	mat.set_shader_parameter("rock_n", load(base + "ciel/roche_ciel_n.png"))
	mat.set_shader_parameter("extra_detail", pc)
	var mi := MeshInstance3D.new()
	mi.name = "Fees_prairie"
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_body.add_child(cs)


# =================================================================== le dessous

func _rock_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/ciel/roche_ciel.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/ciel/roche_ciel_n.png")
	m.normal_scale = 1.2
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 3.0
	m.uv1_scale = Vector3(0.045, 0.045, 0.045)
	m.roughness = 0.92
	m.albedo_color = Color(1.18, 1.04, 1.12)
	return m


func _build_under() -> void:
	var nk: int = 34
	var tip := Vector2(-6.0, 5.0)
	var rings: Array = []
	for k in range(nk + 1):
		var t: float = float(k) / nk
		var row: Array = []
		for j in range(NS + 1):
			var theta: float = TAU * float(j % NS) / NS
			var rr: float = coast_radius(theta)
			var y: float
			var rad: float
			if k == 0:
				var edge: Vector3 = _ring_point(NR, j % NS)
				row.append(Vector3(edge.x, edge.y, edge.z))
				continue
			elif k == 1:
				rad = rr * 1.015
				y = top_local(cos(theta) * rr * 0.98, sin(theta) * rr * 0.98) - 2.5
			else:
				var tt: float = (t - 1.0 / nk) / (1.0 - 1.0 / nk)
				var prof: float = pow(1.0 - tt, 0.75) * (1.0 - 0.12 * sin(tt * PI))
				var nz: float = _under.get_noise_3d(cos(theta) * 30.0, tt * 60.0, sin(theta) * 30.0)
				var crag: float = _under.get_noise_3d(cos(theta) * 90.0, tt * 160.0, sin(theta) * 90.0)
				var ledge: float = 0.07 * smoothstep(0.1, 0.4, _under.get_noise_2d(theta * 8.0, tt * 18.0))
				rad = rr * clampf(prof * (0.92 + 0.24 * nz + 0.06 * crag) - ledge, 0.0, 1.05)
				y = -4.0 - tt * DEPTH
			var cx: float = tip.x * t * t
			var cz: float = tip.y * t * t
			row.append(Vector3(cx + cos(theta) * rad, y, cz + sin(theta) * rad))
		rings.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(nk):
		for j in range(NS):
			var a: Vector3 = rings[k][j]
			var b: Vector3 = rings[k + 1][j]
			var c: Vector3 = rings[k][j + 1]
			var d: Vector3 = rings[k + 1][j + 1]
			var out := Vector3(a.x + c.x, 0, a.z + c.z).normalized()
			var tri1: Array = [a, b, c]
			var tri2: Array = [b, d, c]
			if (b - a).cross(c - a).dot(out) > 0.0:
				tri1 = [a, c, b]
				tri2 = [b, c, d]
			for tri in [tri1, tri2]:
				for p in tri:
					st.add_vertex(Vector3(CENTER.x + p.x, Y0 + p.y, CENTER.z + p.z))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Fees_dessous"
	mi.mesh = st.commit()
	mi.material_override = _rock_material()
	add_child(mi)


func _build_underside_details() -> void:
	var rock_m: StandardMaterial3D = _rock_material()
	# Îlots flottants, chacun coiffé de prairie (et parfois d'un petit cerisier)
	for k in range(9 if pc else 5):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(100.0, 130.0)
		var s: float = _rng.randf_range(4.0, 9.0)
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.shape(5860 + k, Vector3(s * 1.3, s * 1.8, s * 1.2), 0.6, 0.3, 0.55, 22)
		mi.material_override = rock_m
		mi.position = Vector3(CENTER.x + cos(a) * r, Y0 - _rng.randf_range(-6.0, 30.0), CENTER.z + sin(a) * r)
		mi.rotation = Vector3(PI, _rng.randf() * TAU, 0)
		add_child(mi)
		var cap := MeshInstance3D.new()
		cap.mesh = Rocks.shape(5870 + k, Vector3(s * 1.25, s * 0.35, s * 1.15), 0.8, 0.2, 0.3, 18)
		cap.material_override = Rocks.material(Color(0.55, 0.68, 0.42), 0.95, 0.18)
		cap.position = mi.position + Vector3.UP * s * 0.75
		add_child(cap)
		if k % 3 == 0:
			var tr := MeshInstance3D.new()
			tr.mesh = Flora.tree(5880 + k, _rng.randf_range(5.0, 7.0), 180 if pc else 110)
			tr.set_surface_override_material(1, blossom_mat())
			tr.position = cap.position + Vector3.UP * s * 0.25
			tr.rotation.y = _rng.randf() * TAU
			add_child(tr)
	# Cristaux roses et violets qui luisent sous l'île
	var crys_a: StandardMaterial3D = _crystal_mat(Color(1.0, 0.55, 0.85))
	var crys_b: StandardMaterial3D = _crystal_mat(Color(0.7, 0.55, 1.0))
	var prism := CylinderMesh.new()
	prism.top_radius = 0.0
	prism.bottom_radius = 0.6
	prism.height = 3.2
	prism.radial_segments = 6
	prism.rings = 1
	for k in range(28 if pc else 14):
		var a2: float = _rng.randf() * TAU
		var t2: float = _rng.randf_range(0.15, 0.7)
		var rr: float = coast_radius(a2) * pow(1.0 - t2, 0.75) * 0.95
		var at := Vector3(CENTER.x + cos(a2) * rr, Y0 - 4.0 - t2 * DEPTH, CENTER.z + sin(a2) * rr)
		var cluster := Node3D.new()
		cluster.position = at
		cluster.rotation = Vector3(0, a2, 0)
		add_child(cluster)
		for c in range(_rng.randi_range(3, 6)):
			var p := MeshInstance3D.new()
			p.mesh = prism
			p.material_override = crys_a if (k + c) % 2 == 0 else crys_b
			var sc: float = _rng.randf_range(0.5, 1.6)
			p.scale = Vector3(sc, sc * _rng.randf_range(0.8, 1.6), sc)
			p.rotation = Vector3(PI + _rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.6, 0.6) + 0.7)
			p.position = Vector3(_rng.randf_range(-1.0, 1.0), -sc, _rng.randf_range(-1.0, 1.0))
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cluster.add_child(p)
	# Racines qui pendent dans le vide, depuis le bord
	var root_m := StandardMaterial3D.new()
	root_m.albedo_texture = load("res://assets/textures/flora/bark.png")
	root_m.albedo_color = Color(0.45, 0.36, 0.28)
	root_m.roughness = 0.95
	for k in range(52 if pc else 26):
		var a3: float = _rng.randf() * TAU
		var rr3: float = coast_radius(a3) * _rng.randf_range(0.9, 1.0)
		var length: float = _rng.randf_range(5.0, 22.0)
		var top := Vector3(CENTER.x + cos(a3) * rr3, Y0 - _rng.randf_range(1.5, 4.0), CENTER.z + sin(a3) * rr3)
		var cyl := CylinderMesh.new()
		cyl.top_radius = _rng.randf_range(0.12, 0.4)
		cyl.bottom_radius = 0.02
		cyl.height = length
		cyl.radial_segments = 6
		cyl.rings = 2
		var r_mi := MeshInstance3D.new()
		r_mi.mesh = cyl
		r_mi.material_override = root_m
		r_mi.position = top + Vector3.DOWN * length * 0.5
		r_mi.rotation = Vector3(_rng.randf_range(-0.15, 0.15), 0, _rng.randf_range(-0.15, 0.15))
		r_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(r_mi)


func _crystal_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c * 0.8
	m.emission_energy_multiplier = 2.2
	m.roughness = 0.1
	return m


## Feuillage des cerisiers en fleurs (les cartes de feuilles prennent la grappe de fleurs).
var _blossom: ShaderMaterial
func blossom_mat() -> ShaderMaterial:
	if _blossom != null:
		return _blossom
	_blossom = ShaderMaterial.new()
	_blossom.shader = load("res://shaders/foliage_v25.gdshader")
	_blossom.set_shader_parameter("albedo_tex", load("res://assets/textures/fees/fleurs_arbre.png"))
	_blossom.set_shader_parameter("wind_strength", 0.1)
	_blossom.set_shader_parameter("translucency", 0.55)
	_blossom.set_shader_parameter("roughness_value", 0.6)
	_blossom.set_shader_parameter("tint", Color(1.05, 1.0, 1.02))
	return _blossom


# =================================================================== l'eau

func _build_water() -> void:
	var flow := load("res://shaders/waterfall_v26.gdshader")
	for s in streams:
		var pts: Array = s["pts"]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows: Array = []
		var n: int = pts.size()
		for k in range(n):
			var p: Vector2 = pts[k]
			var tan: Vector2 = ((pts[mini(k + 1, n - 1)] as Vector2) - (pts[maxi(k - 1, 0)] as Vector2)).normalized()
			var side := Vector2(-tan.y, tan.x)
			var w: float = lerpf(1.3, 2.0, float(k) / (n - 1))
			var bed: float = top_local(p.x, p.y)
			var row: Array = []
			for a in [-1.0, 0.0, 1.0]:
				var q: Vector2 = p + side * w * a
				row.append([Vector3(CENTER.x + q.x, Y0 + bed + 0.38, CENTER.z + q.y), Vector2((a + 1.0) * 0.5, float(k) / (n - 1))])
			rows.append(row)
		for k in range(n - 1):
			for i in range(2):
				for idx in [[k, i], [k, i + 1], [k + 1, i], [k, i + 1], [k + 1, i + 1], [k + 1, i]]:
					var v: Array = rows[idx[0]][idx[1]]
					st.set_normal(Vector3.UP)
					st.set_uv(v[1])
					st.add_vertex(v[0])
		var brook := MeshInstance3D.new()
		brook.name = "Ruisseau_fees"
		brook.mesh = st.commit()
		var m := ShaderMaterial.new()
		m.shader = flow
		m.set_shader_parameter("fall_length", 40.0)
		m.set_shader_parameter("flow_speed", 1.4)
		m.set_shader_parameter("water_color", Color(0.55, 0.78, 0.82))
		brook.material_override = m
		brook.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(brook)
		var spring: Vector2 = s["spring"]
		if spring.distance_to(POND) > POND_R + 4.0:
			var pool := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 2.4
			disc.bottom_radius = 2.4
			disc.height = 0.05
			disc.radial_segments = 24
			pool.mesh = disc
			var pm := ShaderMaterial.new()
			pm.shader = flow
			pm.set_shader_parameter("fall_length", 3.0)
			pm.set_shader_parameter("flow_speed", 0.3)
			pool.material_override = pm
			pool.position = Vector3(CENTER.x + spring.x, Y0 + top_local(spring.x, spring.y) + 0.36, CENTER.z + spring.y)
			add_child(pool)
			var rm: Material = Rocks.material(Color(0.74, 0.72, 0.72), 0.75, 0.15)
			for k2 in range(7):
				var a2: float = TAU * k2 / 7.0 + 0.4
				if Vector2(cos(a2), sin(a2)).dot((s["dir"] as Vector2)) > 0.75:
					continue
				var sz: float = _rng.randf_range(0.8, 1.5)
				var rock := MeshInstance3D.new()
				rock.mesh = Rocks.shape(5890 + k2, Vector3(sz * 1.3, sz, sz * 1.2), 0.7, 0.24, 0.6, 16)
				rock.material_override = rm
				rock.position = pool.position + Vector3(cos(a2) * 2.9, sz * 0.15, sin(a2) * 2.9)
				rock.rotation.y = _rng.randf() * TAU
				add_child(rock)
		_make_fall(s)


func _make_fall(s: Dictionary) -> void:
	var rim: Vector2 = s["rim"]
	var d2: Vector2 = s["dir"]
	var dir := Vector3(d2.x, 0, d2.y)
	var side := Vector3(-d2.y, 0, d2.x)
	var top_y: float = Y0 + top_local(rim.x * 0.97, rim.y * 0.97) + 0.38
	var lip := Vector3(CENTER.x + rim.x * 0.97, top_y, CENTER.z + rim.y * 0.97)
	var drop: float = top_y - CLOUD_Y + 4.0
	var rows: int = 40 if pc else 26
	var cols: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for j in range(rows + 1):
		var t: float = float(j) / rows
		var out: float = 1.5 * sqrt(t * 3.0) + 6.0 * t
		var y: float = top_y - drop * pow(t, 1.15)
		var width: float = lerpf(3.4, 14.0, pow(t, 0.8))
		var row: Array = []
		for i in range(cols + 1):
			var a: float = float(i) / cols
			var across: float = (a - 0.5) * width
			var bulge: float = (1.0 - pow((a - 0.5) * 2.0, 2.0)) * (0.3 + 2.0 * t)
			row.append([lip + dir * (out + bulge) + side * across + Vector3(0, y - top_y, 0), Vector2(a, t)])
		grid.append(row)
	for j in range(rows):
		for i in range(cols):
			for idx in [[j, i], [j + 1, i], [j, i + 1], [j, i + 1], [j + 1, i], [j + 1, i + 1]]:
				var v: Array = grid[idx[0]][idx[1]]
				st.set_normal(dir)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	var fall := MeshInstance3D.new()
	fall.name = "Chute_fees_%d" % falls.size()
	fall.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/chute_ciel_v54.gdshader")
	m.set_shader_parameter("fall_length", drop)
	fall.material_override = m
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fall.extra_cull_margin = 20.0
	add_child(fall)
	var foot: Vector3 = lip + dir * 8.0
	foot.y = CLOUD_Y
	falls.append(foot)
	_mist("Brume_nuages_fees", foot + Vector3.UP * 4.0, Vector3(8, 3, 8), 50 if pc else 22, 7.0, 16.0, Color(0.97, 0.95, 1.0, 0.32), 2.5)
	_mist("Embruns_fees", lip + dir * 7.0 + Vector3.DOWN * drop * 0.5, Vector3(5, 16, 5), 30 if pc else 12, 6.0, 10.0, Color(0.97, 0.97, 1.0, 0.16), 1.0)


func _mist(label: String, at: Vector3, box: Vector3, amount: int, lifetime: float, size: float, color: Color, rise: float) -> void:
	var parts := GPUParticles3D.new()
	parts.name = label
	parts.amount = amount
	parts.lifetime = lifetime
	parts.position = at
	parts.preprocess = lifetime
	parts.visibility_aabb = AABB(Vector3(-30, -30, -30), Vector3(60, 60, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = rise * 0.5
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0.4, 0.15, 0)
	pm.damping_min = 0.2
	pm.damping_max = 0.5
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.25, color)
	fade.set_color(fade.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	parts.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load("res://assets/textures/ciel/nuage.png")
	mat.disable_receive_shadows = true
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(parts)


## L'étang aux nénuphars : eau calme, lotus qui luisent, galets moussus.
func _build_pond() -> void:
	var lvl: float = pond_level()
	var c := Vector3(CENTER.x + POND.x, lvl, CENTER.z + POND.y)
	var water := MeshInstance3D.new()
	water.name = "Etang_fees"
	var disc := CylinderMesh.new()
	disc.top_radius = POND_R + 0.6
	disc.bottom_radius = POND_R + 0.6
	disc.height = 0.04
	disc.radial_segments = 40
	water.mesh = disc
	# eau calme : sombre et transparente, qui reflète le ciel (petites rides)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.1, 0.24, 0.26, 0.78)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.04
	wm.metallic = 0.35
	wm.metallic_specular = 0.8
	wm.normal_enabled = true
	wm.normal_texture = load("res://assets/textures/water/water_n.png")
	wm.normal_scale = 0.35
	wm.uv1_scale = Vector3(3.0, 3.0, 3.0)
	water.material_override = wm
	water.position = c
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	var pad_m := StandardMaterial3D.new()
	pad_m.albedo_color = Color(0.24, 0.5, 0.2)
	pad_m.roughness = 0.4
	var lotus_m := StandardMaterial3D.new()
	lotus_m.albedo_color = Color(1.0, 0.75, 0.88)
	lotus_m.emission_enabled = true
	lotus_m.emission = Color(1.0, 0.55, 0.8)
	lotus_m.emission_energy_multiplier = 0.9
	lotus_m.roughness = 0.5
	for k in range(16):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * (POND_R - 1.5)
		var pad := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = _rng.randf_range(0.35, 0.7)
		cm.bottom_radius = cm.top_radius
		cm.height = 0.02
		cm.radial_segments = 14
		pad.mesh = cm
		pad.material_override = pad_m
		pad.position = c + Vector3(cos(a) * r, 0.04, sin(a) * r)
		add_child(pad)
		if k % 3 == 0:
			var lotus := MeshInstance3D.new()
			lotus.mesh = _gfx.cap_mesh(0.22, 0.9)
			lotus.material_override = lotus_m
			lotus.position = pad.position + Vector3.UP * 0.08
			lotus.rotation.x = PI
			lotus.scale = Vector3(1, 0.7, 1)
			add_child(lotus)
	var rm: Material = Rocks.material(Color(0.72, 0.72, 0.7), 0.8, 0.2)
	for k in range(16):
		var a2: float = TAU * k / 16.0 + _rng.randf_range(-0.1, 0.1)
		if absf(wrapf(a2 - float(SPRINGS[0][1]), -PI, PI)) < 0.35:
			continue
		var sz: float = _rng.randf_range(0.5, 1.2)
		var rock := MeshInstance3D.new()
		rock.mesh = Rocks.shape(5900 + k, Vector3(sz * 1.4, sz * 0.8, sz * 1.2), 0.7, 0.24, 0.6, 14)
		rock.material_override = rm
		rock.position = Vector3(CENTER.x + POND.x + cos(a2) * (POND_R + 0.8), lvl - 0.1, CENTER.z + POND.y + sin(a2) * (POND_R + 0.8))
		rock.rotation.y = _rng.randf() * TAU
		add_child(rock)


# =================================================================== la mer de nuages

func _build_cloud_sea() -> void:
	var sea := MeshInstance3D.new()
	sea.name = "Mer_de_nuages"
	var pm := PlaneMesh.new()
	pm.size = Vector2(2800, 2800)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	sea.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/mer_nuages_v58.gdshader")
	sea.material_override = m
	sea.position = Vector3(CENTER.x, CLOUD_Y, CENTER.z)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.extra_cull_margin = 400.0
	add_child(sea)
	# Des nuages plus épais qui montent de la mer, autour de l'île
	var tex: Texture2D = load("res://assets/textures/ciel/nuage.png")
	for k in range(16 if pc else 8):
		var a: float = TAU * k / (16.0 if pc else 8.0) + _rng.randf_range(-0.2, 0.2)
		var r: float = _rng.randf_range(80.0, 220.0)
		var y: float = CLOUD_Y + _rng.randf_range(4.0, 40.0)
		var s: float = _rng.randf_range(40.0, 80.0)
		var q := MeshInstance3D.new()
		q.name = "Nuage_fees"
		var qm := QuadMesh.new()
		qm.size = Vector2(s, s * 0.55)
		q.mesh = qm
		var cm := StandardMaterial3D.new()
		cm.albedo_texture = tex
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		cm.albedo_color = Color(1.0, 0.95, 0.97, 0.85)
		cm.proximity_fade_enabled = true
		cm.proximity_fade_distance = 12.0
		cm.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		cm.distance_fade_min_distance = 8.0
		cm.distance_fade_max_distance = 40.0
		q.material_override = cm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(CENTER.x + cos(a) * r, y, CENTER.z + sin(a) * r)
		add_child(q)


# =================================================================== végétation

func _free_spot(l: Vector2, margin: float) -> bool:
	if l.distance_to(TREE) < 30.0 + margin:
		return false
	if l.distance_to(GLADE) < GLADE_R + margin:
		return false
	if l.distance_to(RING) < RING_R + 3.0 + margin:
		return false
	if l.distance_to(POND) < POND_R + 1.5 + margin:
		return false
	if _on_path(l) > 0.05 and margin > 0.0:
		return false
	if float(stream_dist(l)[0]) < 3.0 + margin * 0.5:
		return false
	for s in streams:
		if l.distance_to(s["spring"]) < 4.5 + margin:
			return false
	return l.length() < coast_radius(atan2(l.y, l.x)) - 6.0 - margin


func _random_free(margin: float) -> Vector2:
	for attempt in range(40):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * R0
		var l := Vector2(cos(a) * r, sin(a) * r)
		if _free_spot(l, margin):
			return l
	return Vector2.INF


func _build_flora() -> void:
	# Cerisiers en fleurs et quelques grands feuillus
	var trees: Array = []
	for v in range(3):
		trees.append(Flora.tree(5910 + v, _rng.randf_range(7.0, 10.0), 320 if pc else 180))
	var placed: Array = []
	for k in range(30 if pc else 18):
		var l: Vector2 = _random_free(3.0)
		if l == Vector2.INF:
			continue
		var close: bool = false
		for q in placed:
			if l.distance_to(q) < 9.0:
				close = true
		if close:
			continue
		placed.append(l)
		var mi := MeshInstance3D.new()
		mi.name = "Arbre_fees"
		mi.mesh = trees[k % trees.size()]
		if k % 5 != 4:
			mi.set_surface_override_material(1, blossom_mat())
		mi.position = world(l, -0.15)
		mi.rotation.y = _rng.randf() * TAU
		mi.scale = Vector3.ONE * _rng.randf_range(0.85, 1.3)
		add_child(mi)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.35
		cyl.height = 4.0
		cs.shape = cyl
		cs.position = mi.position + Vector3.UP * 2.0
		_body.add_child(cs)
	# Herbe, fleurs de toutes les couleurs, buissons, pétales tombés
	_scatter("Herbe_fees", Flora.grass_clump(11, 0.55, 0.05, 581), Flora.grass_material(), 3800 if pc else 1600, 0.0, Vector2(0.7, 1.4))
	var colors := [Color(1.0, 0.6, 0.85), Color(0.75, 0.6, 1.0), Color(1.0, 0.92, 0.5), Color(1.0, 0.98, 0.95), Color(0.55, 0.75, 1.0), Color(1.0, 0.55, 0.5)]
	for i in range(colors.size()):
		_scatter("Fleurs_fees_%d" % i, Flora.flower_clump(), Flora.flower_material(colors[i]), 300 if pc else 130, -1.0, Vector2(0.7, 1.3))
	_scatter("Buissons_fees", Flora.bush(586), null, 50 if pc else 26, 1.5, Vector2(0.8, 1.5))
	_scatter("Fougeres_fees", Flora.fern_clump(), Flora.fern_material(), 260 if pc else 120, 0.5, Vector2(0.8, 1.4))


func _scatter(label: String, mesh: Mesh, mat: Material, count: int, margin: float, size: Vector2) -> void:
	var xfs: Array = []
	for k in range(count):
		var l: Vector2 = _random_free(maxf(margin, 0.0)) if margin >= 0.0 else _random_any()
		if l == Vector2.INF:
			continue
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(size.x, size.y))
		xfs.append(Transform3D(b, world(l, -0.03)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = label
	inst.multimesh = mm
	if mat != null:
		inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.visibility_range_end = 220.0 if pc else 140.0
	add_child(inst)


## Des fleurs aussi dans la clairière et le long du chemin (pas sur le chemin lui-même).
func _random_any() -> Vector2:
	for attempt in range(40):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * R0
		var l := Vector2(cos(a) * r, sin(a) * r)
		if l.distance_to(TREE) < 26.0 or l.distance_to(POND) < POND_R + 1.0 or _on_path(l) > 0.3:
			continue
		if l.distance_to(GLADE) < 5.0 or l.distance_to(RING) < RING_R + 1.0:
			continue
		if float(stream_dist(l)[0]) < 2.6:
			continue
		if l.length() < coast_radius(atan2(l.y, l.x)) - 4.0:
			return l
	return Vector2.INF


## Les champignons géants qui luisent : en bouquets autour de la clairière et de l'étang.
func _build_mushrooms() -> void:
	var caps := [Color(0.55, 0.45, 1.0), Color(1.0, 0.45, 0.75), Color(0.4, 0.8, 1.0), Color(1.0, 0.7, 0.35)]
	var spots: Array = [[GLADE + Vector2(-17.0, -6.0), 3], [GLADE + Vector2(17.0, -4.0), 3], [GLADE + Vector2(-12.0, 14.0), 2], [GLADE + Vector2(13.0, 13.0), 2],
		[POND + Vector2(-8.0, -9.0), 2], [RING + Vector2(-6.0, -6.0), 2], [TREE + Vector2(-30.0, 14.0), 3], [TREE + Vector2(31.0, 10.0), 3], [Vector2(-52.0, -20.0), 2], [Vector2(50.0, -8.0), 2]]
	var n_lights: int = 0
	for i in range(spots.size()):
		var base: Vector2 = spots[i][0]
		for k in range(int(spots[i][1])):
			var l: Vector2 = base + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.5, 2.5))
			var big: float = _rng.randf_range(0.9, 2.4) if k == 0 else _rng.randf_range(0.4, 1.1)
			var col: Color = caps[(i + k) % caps.size()]
			var root := Node3D.new()
			root.name = "Champignon_geant"
			root.position = world(l, -0.1)
			root.rotation = Vector3(_rng.randf_range(-0.1, 0.1), _rng.randf() * TAU, _rng.randf_range(-0.1, 0.1))
			add_child(root)
			var h: float = big * 1.8
			var stem := MeshInstance3D.new()
			stem.mesh = _gfx.stem_mesh(big * 0.22, h, k == 0)
			stem.material_override = _gfx.stem_mat()
			root.add_child(stem)
			var cap := MeshInstance3D.new()
			cap.mesh = _gfx.cap_mesh(big, 0.42)
			cap.material_override = _gfx.cap_mat(col, true, 1.6)
			cap.position = Vector3(0, h, 0)
			root.add_child(cap)
			if k == 0:
				var cs := CollisionShape3D.new()
				var cyl := CylinderShape3D.new()
				cyl.radius = big * 0.3
				cyl.height = h
				cs.shape = cyl
				cs.position = root.position + Vector3.UP * h * 0.5
				_body.add_child(cs)
				if pc and n_lights < 8:
					var ol := OmniLight3D.new()
					ol.light_color = col.lightened(0.2)
					ol.light_energy = 1.3
					ol.omni_range = 7.0 + big * 2.0
					ol.shadow_enabled = false
					ol.position = Vector3(0, h - 0.4, 0)
					root.add_child(ol)
					lights.append(ol)
					n_lights += 1


## Le cercle de champignons : douze petits champignons rouges à pois blancs, un cercle d'herbe
## plus sombre et, au centre, une colonne de lueurs (on arrive là, on repart de là).
var ring_glow: MeshInstance3D
func _build_ring() -> void:
	var c: Vector3 = world(RING, 0.0)
	var cap_m: StandardMaterial3D = _gfx.cap_mat(Color(0.85, 0.15, 0.1), true, 0.6)
	for k in range(12):
		var a: float = TAU * k / 12.0
		var l: Vector2 = RING + Vector2(cos(a), sin(a)) * RING_R
		var s: float = _rng.randf_range(0.22, 0.38)
		var root := Node3D.new()
		root.position = world(l, -0.05)
		root.rotation.y = _rng.randf() * TAU
		add_child(root)
		var stem := MeshInstance3D.new()
		stem.mesh = _gfx.stem_mesh(s * 0.25, s * 1.6, false)
		stem.material_override = _gfx.stem_mat()
		root.add_child(stem)
		var cap := MeshInstance3D.new()
		cap.mesh = _gfx.cap_mesh(s, 0.5)
		cap.material_override = cap_m
		cap.position = Vector3(0, s * 1.6, 0)
		root.add_child(cap)
	ring_glow = MeshInstance3D.new()
	ring_glow.name = "Cercle_lueur"
	var tm := TorusMesh.new()
	tm.inner_radius = RING_R - 0.12
	tm.outer_radius = RING_R + 0.12
	tm.rings = 48
	tm.ring_segments = 6
	ring_glow.mesh = tm
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.55, 1.0, 0.75, 0.22)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_glow.material_override = gm
	ring_glow.scale = Vector3(1, 0.05, 1)
	ring_glow.position = c + Vector3.UP * 0.06
	ring_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring_glow)
	_motes_at("Lueurs_cercle", c + Vector3.UP * 1.5, Vector3(RING_R * 0.6, 1.5, RING_R * 0.6), 50 if pc else 22, Color(0.6, 1.0, 0.75), 0.16)


func _build_rocks() -> void:
	var mat: Material = Rocks.material(Color(0.8, 0.78, 0.76), 0.65, 0.2)
	for k in range(22 if pc else 12):
		var l: Vector2 = _random_free(2.0)
		if l == Vector2.INF:
			continue
		var s: float = _rng.randf_range(0.7, 2.2)
		var mi := MeshInstance3D.new()
		mi.name = "Rocher_fees"
		mi.mesh = Rocks.shape(5920 + k, Vector3(s * 1.4, s, s * 1.2), 0.7, 0.22, 0.5, 18)
		mi.material_override = mat
		mi.position = world(l, s * 0.2 - 0.3)
		mi.rotation.y = _rng.randf() * TAU
		add_child(mi)
		if s > 1.2:
			_body.add_child(Rocks.collision_for(mi.mesh, mi.transform))
	# Cristaux près du cercle et de l'étang
	var cm_a: StandardMaterial3D = _crystal_mat(Color(0.75, 0.6, 1.0))
	var cm_b: StandardMaterial3D = _crystal_mat(Color(0.5, 0.95, 1.0))
	for k in range(8):
		var base: Vector2 = (RING + Vector2(-9.0, 4.0)) if k < 4 else (POND + Vector2(10.0, -7.0))
		var l2: Vector2 = base + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.5, 2.5))
		var cr := MeshInstance3D.new()
		cr.mesh = _gfx.crystal_mesh(_rng.randf_range(0.18, 0.4), _rng.randf_range(0.9, 2.2))
		cr.material_override = cm_a if k % 2 == 0 else cm_b
		cr.position = world(l2, -0.1)
		cr.rotation = Vector3(_rng.randf_range(-0.35, 0.35), _rng.randf() * TAU, _rng.randf_range(-0.35, 0.35))
		add_child(cr)


# =================================================================== lueurs dans l'air

func _build_motes() -> void:
	_motes_at("Lucioles_clairiere", world(GLADE, 2.0), Vector3(GLADE_R, 2.0, GLADE_R), 120 if pc else 50, Color(1.0, 0.9, 0.5), 0.12)
	_motes_at("Lucioles_etang", world(POND, 1.2), Vector3(POND_R + 2.0, 1.2, POND_R + 2.0), 60 if pc else 26, Color(0.6, 1.0, 0.8), 0.1)
	_motes_at("Pollen_dore", world(Vector2(0, 10), 6.0), Vector3(70, 6, 70), 260 if pc else 90, Color(1.0, 0.95, 0.75), 0.07)


func _motes_at(label: String, at: Vector3, box: Vector3, amount: int, color: Color, size: float) -> void:
	var p := GPUParticles3D.new()
	p.name = label
	p.amount = amount
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.position = at
	p.visibility_aabb = AABB(-box - Vector3(4, 4, 4), box * 2.0 + Vector3(8, 8, 8))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.03, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.2, color)
	fade.add_point(0.8, color)
	fade.set_color(fade.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	quad.material = m
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


var _dot: Texture2D
func _soft_dot() -> Texture2D:
	if _dot != null:
		return _dot
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.25, Color(1, 1, 1, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_dot = t
	return t

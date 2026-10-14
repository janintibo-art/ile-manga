extends Node3D
## V41 : la troisième île, l'île des elfes (le Bois-Doré), à l'est, entre le village et la jungle.
## Une côte douce, une baie de sable tournée vers les deux autres îles (le ponton), des
## prairies ondulées, et au centre un plateau couvert d'arbres géants. Le village elfe occupe
## une grande clairière aplanie sur le plateau.
## Même principe que l'île-jungle : le relief est calculé une fois dans une grille ; le
## maillage, la collision et height() lisent la même grille.
## L'île offre la même interface que la jungle (CENTER, height, coast_ratio, gorge_distance,
## TOWERS, dock_start) pour que la forêt (jungle_flora_v30.gd) sache y pousser.

const CENTER := Vector3(330.0, 0.0, -165.0)
const HALF: float = 140.0
const CELL: float = 1.0
const CHUNKS: int = 8
const WATER: float = -0.42
const BAY_ANGLE: float = PI                     # la baie regarde vers l'ouest (les deux îles)
const GLADE := Vector2(8.0, 0.0)                # clairière du village (local)
const GLADE_R: float = 30.0
const TOWERS: Array = []                        # (pas de pitons ici)

var count: int = 0
var heights := PackedFloat32Array()
var dock_start: Vector3
var dock_end: Vector3
var glade_y: float = 0.0
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()


func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	_setup_noise()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var z: float = -HALF + zi * CELL
		for xi in range(count):
			heights[zi * count + xi] = _shape(-HALF + xi * CELL, z)
	glade_y = height(CENTER.x + GLADE.x, CENTER.z + GLADE.y)
	_flatten(CENTER.x + GLADE.x, CENTER.z + GLADE.y, GLADE_R, GLADE_R + 16.0, glade_y)
	_find_dock()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V41: île des elfes ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms, clairière à ", glade_y)


func _setup_noise() -> void:
	_noise.seed = 4101
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.012
	_detail.seed = 4102
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 3
	_detail.frequency = 0.06
	_coast.seed = 4103
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.9


func _angle_gap(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _coast_radius(theta: float) -> float:
	var r: float = 102.0 + 10.0 * sin(3.0 * theta + 1.3) + 6.0 * sin(5.0 * theta + 0.4)
	r += _coast.get_noise_2d(cos(theta) * 2.0, sin(theta) * 2.0) * 8.0
	r -= 20.0 * exp(-pow(_angle_gap(theta, BAY_ANGLE) / 0.3, 2.0))
	return r


## Relief local : plage, prairies ondulées, plateau boisé au centre.
func _shape(x: float, z: float) -> float:
	var r: float = sqrt(x * x + z * z)
	var theta: float = atan2(z, x)
	var shore: float = _coast_radius(theta)
	var t: float = r / shore
	var bay: float = exp(-pow(_angle_gap(theta, BAY_ANGLE) / 0.42, 2.0))
	var coast: float
	if t < 1.0:
		var beach_w: float = lerpf(0.08, 0.2, bay)
		coast = WATER + 0.35 + smoothstep(1.0, 1.0 - beach_w, t) * 2.0
	else:
		coast = WATER + 0.35 - (r - shore) * lerpf(0.3, 0.12, bay)
	coast = maxf(coast, -30.0)
	var inland: float = smoothstep(lerpf(0.97, 0.93, bay), lerpf(0.72, 0.55, bay), t)
	var hills: float = (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * 9.0
	var plateau: float = 8.0 * exp(-pow(Vector2(x - GLADE.x, z - GLADE.y).length() / 62.0, 2.0))
	var land: float = hills + plateau + _detail.get_noise_2d(x, z) * 0.8
	return coast + maxf(land, 0.0) * inland


func _flatten(wx: float, wz: float, radius: float, blend: float, target: float) -> void:
	var cx: float = (wx - CENTER.x + HALF) / CELL
	var cz: float = (wz - CENTER.z + HALF) / CELL
	var reach: int = int(ceil(blend / CELL)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			if d > blend:
				continue
			var k: float = smoothstep(radius, blend, d)
			var i: int = zi * count + xi
			heights[i] = lerpf(target, heights[i], k)


# =================================================================== lecture du relief (même interface que la jungle)

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - CENTER.x + HALF) / CELL
	var fz: float = (wz - CENTER.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -40.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func gorge_distance(_lx: float, _lz: float) -> float:
	return INF


func coast_ratio(lx: float, lz: float) -> float:
	return sqrt(lx * lx + lz * lz) / _coast_radius(atan2(lz, lx))


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


func glade_world() -> Vector3:
	return Vector3(CENTER.x + GLADE.x, glade_y, CENTER.z + GLADE.y)


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var base := "res://assets/textures/"
	mat.set_shader_parameter("sand_tex", load(base + "terrain/sand.jpg"))
	mat.set_shader_parameter("sand_n", load(base + "terrain/sand_n.png"))
	# Prairie : l'herbe tient le rôle de la mousse, la terre et la roche restent celles de la jungle.
	mat.set_shader_parameter("moss_tex", load(base + "terrain/grass.jpg"))
	mat.set_shader_parameter("moss_n", load(base + "terrain/grass_n.png"))
	for key in ["soil", "rock"]:
		mat.set_shader_parameter(key + "_tex", load(base + "jungle/jungle_" + key + ".png"))
		mat.set_shader_parameter(key + "_n", load(base + "jungle/jungle_" + key + "_n.png"))
	mat.set_shader_parameter("extra_detail", high_quality)
	var per: int = (count - 1) / CHUNKS
	for cz in range(CHUNKS):
		for cx in range(CHUNKS):
			var x0: int = cx * per
			var z0: int = cz * per
			var x1: int = count - 1 if cx == CHUNKS - 1 else x0 + per
			var z1: int = count - 1 if cz == CHUNKS - 1 else z0 + per
			var mi := MeshInstance3D.new()
			mi.name = "Elfes_sol_%d_%d" % [cx, cz]
			mi.mesh = _chunk_mesh(x0, z0, x1, z1)
			mi.material_override = mat
			add_child(mi)


func _chunk_mesh(x0: int, z0: int, x1: int, z1: int) -> ArrayMesh:
	var w: int = x1 - x0 + 1
	var dpt: int = z1 - z0 + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	verts.resize(w * dpt)
	normals.resize(w * dpt)
	uvs.resize(w * dpt)
	for zi in range(z0, z1 + 1):
		for xi in range(x0, x1 + 1):
			var k: int = (zi - z0) * w + (xi - x0)
			var x: float = CENTER.x - HALF + xi * CELL
			var z: float = CENTER.z - HALF + zi * CELL
			verts[k] = Vector3(x, heights[zi * count + xi], z)
			var hl: float = heights[zi * count + maxi(xi - 1, 0)]
			var hr: float = heights[zi * count + mini(xi + 1, count - 1)]
			var hd: float = heights[maxi(zi - 1, 0) * count + xi]
			var hu: float = heights[mini(zi + 1, count - 1) * count + xi]
			normals[k] = Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
			uvs[k] = Vector2(x, z) * 0.21
	var indices := PackedInt32Array()
	indices.resize((w - 1) * (dpt - 1) * 6)
	var n: int = 0
	for zi in range(dpt - 1):
		for xi in range(w - 1):
			var a: int = zi * w + xi
			var b: int = a + 1
			var c: int = a + w
			var d: int = c + 1
			indices[n] = a; indices[n + 1] = b; indices[n + 2] = d
			indices[n + 3] = a; indices[n + 4] = d; indices[n + 5] = c
			n += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Sol_elfes_v41"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := HeightMapShape3D.new()
	shape.map_width = count
	shape.map_depth = count
	shape.map_data = heights
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	body.global_position = CENTER


## Ponton : de la plage de la baie (sol ~1 m) vers le large, 16 m.
func _find_dock() -> void:
	var dir := Vector2(cos(BAY_ANGLE), sin(BAY_ANGLE))
	var start_r: float = 40.0
	for k in range(400):
		var rr: float = 40.0 + k * 0.5
		if _shape(dir.x * rr, dir.y * rr) < 0.9:
			start_r = rr
			break
	dock_start = CENTER + Vector3(dir.x * start_r, 0.0, dir.y * start_r)
	dock_end = CENTER + Vector3(dir.x * (start_r + 16.0), 0.0, dir.y * (start_r + 16.0))

extends Node3D
## V29 : la deuxième île, une jungle géante, à 330 m au nord de l'île du village.
## Étape 1 : le relief et le sol. Une baie de sable face au village (où accoste le bateau),
## des collines couvertes de mousse, un grand massif au nord, des pitons calcaires aux
## parois verticales (qu'on peut escalader) et une gorge qui descend du massif vers la baie.
## Le relief est calculé une fois au chargement dans une grille ; le maillage, la collision
## et la fonction height() lisent tous la même grille, donc ils coïncident exactement.

const CENTER := Vector3(0.0, 0.0, -330.0)
const HALF: float = 165.0                 # la grille couvre ±165 m autour du centre
const CELL: float = 0.75                  # pas de la grille (m)
const CHUNKS: int = 8                     # découpage du maillage (pour n'afficher que l'utile)
const WATER: float = -0.42
const BAY_ANGLE: float = PI * 0.5         # la baie regarde vers +Z local, donc vers le village

## Pitons calcaires : centre local (x, z), rayon, hauteur au-dessus du sol.
const TOWERS := [
	[Vector2(-48.0, -18.0), 11.0, 34.0], [Vector2(38.0, -30.0), 13.0, 40.0],
	[Vector2(55.0, 22.0), 9.0, 26.0], [Vector2(-62.0, 30.0), 10.0, 28.0],
	[Vector2(18.0, 46.0), 7.0, 18.0], [Vector2(-24.0, -66.0), 12.0, 30.0],
	[Vector2(70.0, -12.0), 8.0, 24.0],
]

var count: int = 0
var heights := PackedFloat32Array()
var dock_start: Vector3                   # début du ponton sur la plage (monde)
var dock_end: Vector3
var _noise := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()
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
	_build_mesh(high_quality)
	_build_collision()
	_find_dock()
	print("ILE_MANGA_V29: île-jungle ", count, "x", count, " points en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 2901
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 5
	_noise.frequency = 0.011
	_ridge.seed = 2902
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 4
	_ridge.frequency = 0.018
	_detail.seed = 2903
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 3
	_detail.frequency = 0.07
	_coast.seed = 2904
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.9


func _angle_gap(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


## Rayon du rivage dans la direction theta (côte découpée + baie face au village).
func _coast_radius(theta: float) -> float:
	var r: float = 108.0 + 13.0 * sin(3.0 * theta + 0.7) + 7.0 * sin(5.0 * theta + 2.1)
	r += _coast.get_noise_2d(cos(theta) * 2.0, sin(theta) * 2.0) * 9.0
	var g: float = _angle_gap(theta, BAY_ANGLE)
	r -= 30.0 * exp(-pow(g / 0.3, 2.0))
	return r


## Relief en coordonnées locales (x vers l'est, z vers le village).
func _shape(x: float, z: float) -> float:
	var r: float = sqrt(x * x + z * z)
	var theta: float = atan2(z, x)
	var shore: float = _coast_radius(theta)
	var t: float = r / shore
	var bay: float = exp(-pow(_angle_gap(theta, BAY_ANGLE) / 0.42, 2.0))
	# Profil de côte : plage douce, puis le fond marin qui plonge vers le large.
	var coast: float
	if t < 1.0:
		var beach_w: float = lerpf(0.08, 0.2, bay)
		coast = WATER + 0.35 + smoothstep(1.0, 1.0 - beach_w, t) * 2.2
	else:
		coast = WATER + 0.35 - (r - shore) * lerpf(0.32, 0.12, bay)
	coast = maxf(coast, -32.0)
	# Intérieur : collines, grand massif au nord, pitons, gorge.
	var inland: float = smoothstep(lerpf(0.97, 0.93, bay), lerpf(0.72, 0.55, bay), t)
	var hills: float = (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * 18.0
	var massif_d: float = Vector2(x + 8.0, z + 40.0).length()
	var massif: float = 62.0 * exp(-pow(massif_d / 48.0, 2.0)) * (0.75 + 0.5 * (_ridge.get_noise_2d(x, z) * 0.5 + 0.5))
	var land: float = hills + massif + _detail.get_noise_2d(x, z) * 1.2
	# Gorge sinueuse du massif vers la baie.
	var path_x: float = 11.0 * sin(z * 0.032 + 0.6) - 4.0
	if z > -55.0 and z < shore:
		var d: float = absf(x - path_x)
		var depth: float = 9.0 * smoothstep(-55.0, -20.0, z)
		land -= depth * (1.0 - smoothstep(4.0, 14.0, d))
	var h: float = coast + maxf(land, 0.0) * inland
	# Pitons calcaires : parois quasi verticales en gradins ; tous les ~8 m une vire
	# de 2 m de large permet de reprendre son souffle pendant l'escalade.
	for tw in TOWERS:
		var c: Vector2 = tw[0]
		var rad: float = float(tw[1]) * (1.0 + 0.04 * _detail.get_noise_2d(x * 0.6, z * 0.6))
		var dt: float = Vector2(x - c.x, z - c.y).length()
		if dt < rad + 1.0:
			var tall: float = float(tw[2])
			var levels: int = int(ceil(tall / 8.0))
			var rise: float = 0.0
			for k in range(levels):
				var rk: float = rad - k * 2.2
				var wall: float = smoothstep(rk, rk - 0.45, dt)
				var top_k: float = tall * float(k + 1) / levels
				if k == levels - 1:
					top_k *= 1.0 - pow(clampf(dt / maxf(rk, 1.0), 0.0, 1.0), 4.0) * 0.12
				rise = maxf(rise, top_k * wall)
			h = maxf(h, h + rise * inland)
	return h


# =================================================================== lecture du relief

## Hauteur du sol en coordonnées monde (interpolation de la grille, comme le maillage).
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
	var a: float = heights[i]
	var b: float = heights[i + 1]
	var c: float = heights[i + count]
	var d: float = heights[i + count + 1]
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uz)


func contains(wx: float, wz: float) -> bool:
	return Vector2(wx - CENTER.x, wz - CENTER.z).length() < HALF


# =================================================================== maillage

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var base := "res://assets/textures/"
	mat.set_shader_parameter("sand_tex", load(base + "terrain/sand.jpg"))
	mat.set_shader_parameter("sand_n", load(base + "terrain/sand_n.png"))
	for key in ["soil", "moss", "rock"]:
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
			mi.name = "Jungle_sol_%d_%d" % [cx, cz]
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
			var h: float = heights[zi * count + xi]
			verts[k] = Vector3(x, h, z)
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
	body.name = "Sol_jungle_v29"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := HeightMapShape3D.new()
	shape.map_width = count
	shape.map_depth = count
	# La forme a des cases d'1 m : on l'utilise à l'échelle CELL, hauteurs divisées d'autant.
	var data := PackedFloat32Array()
	data.resize(heights.size())
	for i in range(heights.size()):
		data[i] = heights[i] / CELL
	shape.map_data = data
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.scale = Vector3.ONE * CELL
	body.add_child(cs)
	add_child(body)
	body.global_position = CENTER


## Le ponton part de la plage de la baie (sol ~1 m) et avance de 16 m dans l'eau.
func _find_dock() -> void:
	var dir := Vector2(cos(BAY_ANGLE), sin(BAY_ANGLE))
	var start_r: float = 40.0
	for k in range(400):
		var rr: float = 40.0 + k * 0.5
		if _shape(dir.x * rr, dir.y * rr) < 0.9:
			start_r = rr
			break
	var s := Vector3(dir.x * start_r, 0.0, dir.y * start_r)
	var e := Vector3(dir.x * (start_r + 16.0), 0.0, dir.y * (start_r + 16.0))
	dock_start = CENTER + s
	dock_end = CENTER + e

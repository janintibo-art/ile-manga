extends Node3D
## V46 : l'île des nains, la Montagne de Feu, à l'ouest. Une côte de sable noir, des
## pentes de cendre et d'herbe brûlée, des coulées de basalte, et au centre un volcan de
## 70 m dont le cratère abrite un lac de lave. Sur son flanc est, face à la passe des
## Récifs de Feu et au ponton, une grande terrasse aplanie : l'entrée de la cité naine.
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille.

const CENTER := Vector3(-330.0, 0.0, -160.0)
const HALF: float = 140.0
const CELL: float = 1.0
const CHUNKS: int = 8
const WATER: float = -0.42
const BAY_ANGLE: float = 0.4515                  # la baie regarde vers le village (est)
const PEAK := Vector2(-12.0, -6.0)               # sommet du volcan (local)
const PEAK_H: float = 82.0
const CRATER_R: float = 13.0
const TERRACE_R: float = 63.0                    # distance du sommet à la terrasse
const TERRACE_SIZE: float = 17.0

var count: int = 0
var heights := PackedFloat32Array()
var dock_start: Vector3
var dock_end: Vector3
var terrace: Vector3                             # centre de la terrasse (monde)
var crater_floor: float = 0.0
var trail: Array = []                            # V47 : le Sentier des Golems, de la terrasse au cratère (monde)
var trail_end: Vector3                           # V47 : le belvédère au bord du cratère
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
	var dir := Vector2(cos(BAY_ANGLE), sin(BAY_ANGLE))
	var tl: Vector2 = PEAK + dir * TERRACE_R
	var ty: float = height(CENTER.x + tl.x, CENTER.z + tl.y)
	_flatten(CENTER.x + tl.x, CENTER.z + tl.y, TERRACE_SIZE, TERRACE_SIZE + 12.0, ty)
	terrace = Vector3(CENTER.x + tl.x, ty, CENTER.z + tl.y)
	crater_floor = height(CENTER.x + PEAK.x, CENTER.z + PEAK.y)
	_find_dock()
	_carve_road()
	_carve_trail()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V46: île des nains ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms, terrasse à ", terrace)


func _setup_noise() -> void:
	_noise.seed = 4601
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.016
	_detail.seed = 4602
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail.fractal_octaves = 3
	_detail.frequency = 0.05
	_coast.seed = 4603
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.9


func _angle_gap(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _coast_radius(theta: float) -> float:
	var r: float = 108.0 + 9.0 * sin(4.0 * theta + 0.7) + 7.0 * sin(7.0 * theta + 2.1)
	r += _coast.get_noise_2d(cos(theta) * 2.0, sin(theta) * 2.0) * 10.0
	r -= 16.0 * exp(-pow(_angle_gap(theta, BAY_ANGLE) / 0.28, 2.0))
	return r


## Relief : plage noire, collines de cendre, et le cône du volcan avec son cratère.
func _shape(x: float, z: float) -> float:
	var r: float = sqrt(x * x + z * z)
	var theta: float = atan2(z, x)
	var shore: float = _coast_radius(theta)
	var t: float = r / shore
	var bay: float = exp(-pow(_angle_gap(theta, BAY_ANGLE) / 0.4, 2.0))
	var coast: float
	if t < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 1.0 - lerpf(0.07, 0.16, bay), t) * 2.2
	else:
		coast = WATER + 0.35 - (r - shore) * lerpf(0.35, 0.14, bay)
	coast = maxf(coast, -30.0)
	var inland: float = smoothstep(lerpf(0.97, 0.94, bay), lerpf(0.75, 0.6, bay), t)
	# Le volcan : un cône concave, ravines rayonnantes, cratère au sommet
	var rv: float = Vector2(x - PEAK.x, z - PEAK.y).length()
	var av: float = atan2(z - PEAK.y, x - PEAK.x)
	var cone: float = PEAK_H * pow(clampf(1.0 - rv / 95.0, 0.0, 1.0), 1.7)
	var gullies: float = (0.5 + 0.5 * sin(av * 11.0 + _noise.get_noise_2d(x * 2.0, z * 2.0) * 3.0)) * 2.4 * smoothstep(12.0, 30.0, rv) * smoothstep(90.0, 40.0, rv)
	cone -= gullies
	if rv < CRATER_R + 4.0:
		var rim: float = PEAK_H * pow(clampf(1.0 - (CRATER_R + 4.0) / 95.0, 0.0, 1.0), 1.7) + 3.5
		var k: float = smoothstep(CRATER_R + 4.0, CRATER_R, rv)
		var inside: float = rim - 11.0 + rv * 0.06
		cone = lerpf(maxf(cone, rim - (rv - CRATER_R) * 0.8), inside, k)
	var hills: float = (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * 7.0 * smoothstep(CRATER_R + 2.0, CRATER_R + 18.0, rv)
	var rough: float = _detail.get_noise_2d(x, z) * 1.6 * smoothstep(20.0, 60.0, rv)
	var land: float = maxf(hills + rough, 0.0) + cone
	return coast + land * inland


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


## Un chemin en pente douce du ponton à la terrasse : il suit le relief naturel, lissé
## (pas de tranchée), et se raccorde à la terrasse.
func _carve_road() -> void:
	var a := Vector2(dock_start.x, dock_start.z)
	var b := Vector2(terrace.x, terrace.z)
	var n: int = maxi(int(a.distance_to(b) / 2.0), 2)
	var prof: Array = []
	for k in range(n + 1):
		var p: Vector2 = a.lerp(b, float(k) / n)
		prof.append(height(p.x, p.y))
	prof[n] = terrace.y
	var h_start: float = float(prof[0])
	for pass_i in range(6):
		var nxt: Array = prof.duplicate()
		for k in range(1, n):
			var acc: float = 0.0
			var w: float = 0.0
			for o in range(-3, 4):
				var kk: int = clampi(k + o, 0, n)
				acc += float(prof[kk])
				w += 1.0
			nxt[k] = acc / w
		nxt[n] = terrace.y
		nxt[0] = h_start
		prof = nxt
	for k in range(n + 1):
		var t: float = float(k) / n
		var p2: Vector2 = a.lerp(b, t)
		var lin: float = lerpf(h_start, terrace.y, smoothstep(0.0, 1.0, t))
		_flatten(p2.x, p2.y, 2.0, 4.5, lerpf(lin, float(prof[k]), 0.45))


## V47 : le Sentier des Golems — une corniche qui monte en spirale autour du volcan, du
## bord de la terrasse jusqu'à un belvédère au bord du cratère (pente douce, ~12 %).
const TRAIL_TURNS: float = 1.25
const TRAIL_START_R: float = 60.5
const TRAIL_END_R: float = CRATER_R + 6.5


func trail_point(t: float) -> Vector3:
	var a: float = BAY_ANGLE + 0.32 + t * TAU * TRAIL_TURNS
	var r: float = lerpf(TRAIL_START_R, TRAIL_END_R, t)
	return Vector3(CENTER.x + PEAK.x + cos(a) * r, 0.0, CENTER.z + PEAK.y + sin(a) * r)


func _carve_trail() -> void:
	var end_p: Vector3 = trail_point(1.0)
	var h_end: float = height(end_p.x, end_p.z)
	var n: int = 260
	trail.clear()
	for k in range(n + 1):
		var t: float = float(k) / n
		var p: Vector3 = trail_point(t)
		var target: float = lerpf(terrace.y, h_end, t)
		_flatten(p.x, p.z, 2.6, 8.5, target)
		p.y = target
		trail.append(p)
	# Le belvédère, au bord du cratère
	_flatten(end_p.x, end_p.z, 5.0, 9.0, h_end)
	trail_end = Vector3(end_p.x, h_end, end_p.z)


## Un point du sentier (t de 0 à 1), à la hauteur du sol.
func trail_at(t: float) -> Vector3:
	var i: int = clampi(int(round(t * (trail.size() - 1))), 0, trail.size() - 1)
	return trail[i]


# =================================================================== lecture du relief

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


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


func peak_world() -> Vector3:
	return Vector3(CENTER.x + PEAK.x, crater_floor, CENTER.z + PEAK.y)


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var v := "res://assets/textures/volcan/"
	var t := "res://assets/textures/terrain/"
	mat.set_shader_parameter("sand_tex", load(v + "sable_noir.png"))
	mat.set_shader_parameter("sand_n", load(t + "sand_n.png"))
	mat.set_shader_parameter("soil_tex", load(v + "cendre.png"))
	mat.set_shader_parameter("soil_n", load(t + "sand_n.png"))
	mat.set_shader_parameter("moss_tex", load(v + "herbe_brulee.png"))
	mat.set_shader_parameter("moss_n", load(t + "grass_n.png"))
	mat.set_shader_parameter("rock_tex", load(v + "basalte.png"))
	mat.set_shader_parameter("rock_n", load(t + "rock_n.png"))
	mat.set_shader_parameter("extra_detail", high_quality)
	var per: int = (count - 1) / CHUNKS
	for cz in range(CHUNKS):
		for cx in range(CHUNKS):
			var x0: int = cx * per
			var z0: int = cz * per
			var x1: int = count - 1 if cx == CHUNKS - 1 else x0 + per
			var z1: int = count - 1 if cz == CHUNKS - 1 else z0 + per
			var mi := MeshInstance3D.new()
			mi.name = "Nains_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_nains_v46"
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


## Ponton : de la plage de la baie vers le large, 16 m.
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

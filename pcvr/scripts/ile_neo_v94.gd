extends Node3D
## V94 : le relief de Néopolis, la ville cyberpunk, au sud de l'archipel (au sud-est de l'Île du
## Boucan, au sud-ouest de Montjoie). Une île toute plate : une grande dalle de béton posée sur la
## mer, aux coins arrondis, cernée de quais. Au nord (face à l'archipel), une jetée descend vers
## le ponton où l'on accoste. Le sol de la ville (les rues, les trottoirs, la place) est dessiné par
## le shader neo_sol_v94 d'après le quadrillage ; ce script ne fait que le relief.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).

const CENTER := Vector3(300.0, 0.0, 1400.0)
const HALF: float = 270.0
const CELL: float = 2.0
const CHUNKS: int = 5
const WATER: float = -0.42
## La hauteur de la dalle de la ville
const Y0: float = 1.4
## La mer autour de l'île : un cercle qui rejoint celui de l'Île du Boucan (au nord-ouest)
const SEA_R: float = 400.0
## Le bord des quais : une « superellipse » (un carré aux coins arrondis)
const RS: float = 236.0
## Le quadrillage des rues (voir neo_sol_v94.gdshader) : une rue tous les PAS mètres, de -ANNEAU à
## +ANNEAU ; la rue du tour de ville passe à ±ANNEAU.
const PAS: float = 60.0
const ANNEAU: float = 180.0
const PLACE := Vector2(-30.0, -30.0)
## La jetée et le ponton (au nord)
const JETEE := [-5.0, 5.0, -248.0, -226.0]
const DOCK_A := Vector2(0.0, -246.0)
const DOCK_B := Vector2(0.0, -268.0)

var count: int = 0
var heights := PackedFloat32Array()
var ground_mat: ShaderMaterial


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


## 1 sur le bord des quais, moins de 1 sur la dalle
static func coast_q(x: float, z: float) -> float:
	return pow(pow(absf(x), 4.0) + pow(absf(z), 4.0), 0.25) / RS


static func in_jetee(x: float, z: float) -> bool:
	return x > float(JETEE[0]) and x < float(JETEE[1]) and z > float(JETEE[2]) and z < float(JETEE[3])


## La demi-largeur d'une chaussée et de son trottoir (le Boulevard des Néons, au milieu, est plus large)
static func largeur(k: int) -> Vector2:
	return Vector2(6.0, 9.5) if k == 0 else Vector2(4.0, 7.0)


## Sur une chaussée ? (repère île)
static func on_road(x: float, z: float) -> bool:
	if maxf(absf(x), absf(z)) > ANNEAU + 8.0:
		return false
	var kx: int = clampi(int(round(x / PAS)), -3, 3)
	var kz: int = clampi(int(round(z / PAS)), -3, 3)
	return (absf(x - kx * PAS) < largeur(kx).x and absf(z) < ANNEAU + 6.0) or (absf(z - kz * PAS) < largeur(kz).x and absf(x) < ANNEAU + 6.0)


## Le centre de l'îlot (i, j), i et j de -3 à 2 : les îlots sont entre deux rues
static func block_center(i: int, j: int) -> Vector2:
	return Vector2((i + 0.5) * PAS, (j + 0.5) * PAS)


## Le rectangle constructible d'un îlot (sans les trottoirs), en repère île : [x0, z0, x1, z1]
static func block_rect(i: int, j: int) -> Array:
	var x0: float = i * PAS + largeur(i).y
	var x1: float = (i + 1) * PAS - largeur(i + 1).y
	var z0: float = j * PAS + largeur(j).y
	var z1: float = (j + 1) * PAS - largeur(j + 1).y
	return [x0, z0, x1, z1]


# =================================================================== relief

func build(_high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var lz: float = -HALF + zi * CELL
		for xi in range(count):
			heights[zi * count + xi] = _shape(-HALF + xi * CELL, lz)
	_build_mesh()
	_build_collision()
	print("ILE_MANGA_V94: Néopolis ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _shape(x: float, z: float) -> float:
	# la jetée : elle descend doucement de la dalle jusqu'au ponton
	if in_jetee(x, z):
		return lerpf(1.02, Y0, smoothstep(float(JETEE[2]) + 1.0, float(JETEE[3]) - 2.0, z))
	var q: float = coast_q(x, z)
	if q <= 1.0:
		return Y0
	var off: float = (q - 1.0) * RS
	var h: float = lerpf(Y0, -7.5, smoothstep(0.0, 2.2, off))
	h = minf(h, -7.5 - 22.0 * smoothstep(4.0, 46.0, off))
	return maxf(h, -32.0) if off > 2.2 else h


# =================================================================== lecture

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - CENTER.x + HALF) / CELL
	var fz: float = (wz - CENTER.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -32.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== maillage, collision

func _build_mesh() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/neo_sol_v94.gdshader")
	var texs := {"asphalte_tex": "res://assets/textures/boucan/asphalte.png", "asphalte_n": "res://assets/textures/boucan/asphalte_n.png",
		"beton_tex": "res://assets/textures/boucan/beton.png", "beton_n": "res://assets/textures/boucan/beton_n.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			mat.set_shader_parameter(k, load(texs[k]))
	mat.set_shader_parameter("centre", Vector2(CENTER.x, CENTER.z))
	mat.set_shader_parameter("pas", PAS)
	mat.set_shader_parameter("anneau", ANNEAU)
	mat.set_shader_parameter("place", PLACE)
	ground_mat = mat
	var per: int = (count - 1) / CHUNKS
	for cz in range(CHUNKS):
		for cx in range(CHUNKS):
			var x0: int = cx * per
			var z0: int = cz * per
			var x1: int = count - 1 if cx == CHUNKS - 1 else x0 + per
			var z1: int = count - 1 if cz == CHUNKS - 1 else z0 + per
			var top: float = -100.0
			for zi in range(z0, z1 + 1, 2):
				for xi in range(x0, x1 + 1, 2):
					top = maxf(top, heights[zi * count + xi])
			if top < -24.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Neo_sol_%d_%d" % [cx, cz]
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
			uvs[k] = Vector2(x, z) * 0.2
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
	body.name = "Sol_neo_v94"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := HeightMapShape3D.new()
	shape.map_width = count
	shape.map_depth = count
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
	body.position = CENTER

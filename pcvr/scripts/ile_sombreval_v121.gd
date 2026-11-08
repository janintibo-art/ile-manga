extends Node3D
## V121 : le relief de Sombreval, la ville morte, tout au sud de l'archipel (au sud-ouest de
## Néopolis). Une grande ville posée sur un plateau au ras de la mer, ses rues en damier, ses
## plages grises ; au centre, la Butte du Comte : une colline de roche noire, que l'on gravit par
## une route en spirale, et, tout en haut, le château du comte Dracula.
## Le sol est peint par le shader sombreval_sol_v121 d'après les couleurs des sommets :
## r = l'asphalte des rues, g = les herbes qui ont tout envahi, b = la roche, a = les pavés.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).

const CENTER := Vector3(-60.0, 0.0, 2080.0)
const HALF: float = 300.0
const CELL: float = 2.0
const CHUNKS: int = 6
const WATER: float = -0.42
## La hauteur du plateau de la ville
const Y0: float = 2.2
## La mer autour de l'île : un cercle qui rejoint celui de Néopolis (au nord-est)
const SEA_R: float = 420.0
## Le bord de la ville (une « superellipse » bosselée)
const RS: float = 238.0
## Le quadrillage des rues : une rue tous les PAS mètres, de -ANNEAU à +ANNEAU
const PAS: float = 50.0
const ANNEAU: float = 175.0
## La Butte du Comte : le plateau du château (rayon R0, hauteur TOP), le pied de la butte (R1)
const TOP: float = 27.0
const HILL_R0: float = 46.0
const HILL_R1: float = 100.0
## La route en spirale : du pied (au nord, rayon RA) jusqu'au plateau (à l'ouest, rayon RB)
const RAMP_RA: float = 93.0
const RAMP_RB: float = 50.0
const RAMP_TH0: float = -PI * 0.5
const RAMP_SPAN: float = PI * 1.5
const RAMP_W: float = 4.2
## La jetée et le ponton (au nord, face à l'archipel)
const JETEE := [-5.0, 5.0, -264.0, -232.0]
const DOCK_A := Vector2(0.0, -258.0)
const DOCK_B := Vector2(0.0, -278.0)

var count: int = 0
var heights := PackedFloat32Array()
var ground_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func in_jetee(x: float, z: float) -> bool:
	return x > float(JETEE[0]) and x < float(JETEE[1]) and z > float(JETEE[2]) and z < float(JETEE[3])


## Le point de la route en spirale à l'avancement t (0 : le pied, 1 : le plateau), repère île
static func ramp_point(t: float) -> Vector2:
	var a: float = RAMP_TH0 + t * RAMP_SPAN
	var r: float = lerpf(RAMP_RA, RAMP_RB, t)
	return Vector2(cos(a), sin(a)) * r


static func ramp_height(t: float) -> float:
	return lerpf(Y0 + 0.15, TOP, clampf(t, 0.0, 1.0))


## [t, écart au milieu de la route] pour un point (repère île) ; t hors de [0, 1] : pas de route
static func ramp_at(x: float, z: float) -> Vector2:
	var a: float = atan2(z, x)
	var t: float = wrapf(a - RAMP_TH0, 0.0, TAU) / RAMP_SPAN
	if t > 1.0:
		# juste avant le pied (le premier mètre de la route sort un peu de la butte)
		var t2: float = (wrapf(a - RAMP_TH0, 0.0, TAU) - TAU) / RAMP_SPAN
		if t2 > -0.03:
			t = t2
	var r: float = Vector2(x, z).length()
	return Vector2(t, absf(r - lerpf(RAMP_RA, RAMP_RB, clampf(t, 0.0, 1.0))))


## La demi-largeur d'une chaussée et de son trottoir (les deux grandes avenues sont plus larges)
static func largeur(k: int) -> Vector2:
	return Vector2(6.0, 9.0) if k == 0 else Vector2(4.5, 7.0)


## Sur une chaussée ? (repère île) — hors de la Butte
static func on_road(x: float, z: float) -> bool:
	if maxf(absf(x), absf(z)) > ANNEAU + 6.0:
		return false
	var kx: int = clampi(int(round(x / PAS)), -4, 4)
	var kz: int = clampi(int(round(z / PAS)), -4, 4)
	var dx: float = absf(x - kx * PAS)
	var dz: float = absf(z - kz * PAS)
	if absf(absf(x) - ANNEAU) < 5.0 or absf(absf(z) - ANNEAU) < 5.0:
		return true
	return (absf(kx) <= 3 and dx < largeur(kx).x and absf(z) < ANNEAU + 4.0) or (absf(kz) <= 3 and dz < largeur(kz).x and absf(x) < ANNEAU + 4.0)


## Un îlot (i, j de -4 à 3) : son rectangle constructible (sans les trottoirs), repère île [x0, z0, x1, z1]
static func block_rect(i: int, j: int) -> Array:
	var e0: float = float(i) * PAS
	var e1: float = float(i + 1) * PAS
	var f0: float = float(j) * PAS
	var f1: float = float(j + 1) * PAS
	var x0: float = (e0 + largeur(i).y) if i >= -3 else -ANNEAU + 7.0
	var x1: float = (e1 - largeur(i + 1).y) if i + 1 <= 3 else ANNEAU - 7.0
	var z0: float = (f0 + largeur(j).y) if j >= -3 else -ANNEAU + 7.0
	var z1: float = (f1 - largeur(j + 1).y) if j + 1 <= 3 else ANNEAU - 7.0
	if i == -4:
		x0 = -ANNEAU + 7.0
		x1 = -3.0 * PAS - largeur(-3).y
	if i == 3:
		x0 = 3.0 * PAS + largeur(3).y
		x1 = ANNEAU - 7.0
	if j == -4:
		z0 = -ANNEAU + 7.0
		z1 = -3.0 * PAS - largeur(-3).y
	if j == 3:
		z0 = 3.0 * PAS + largeur(3).y
		z1 = ANNEAU - 7.0
	return [x0, z0, x1, z1]


# =================================================================== relief

func _init() -> void:
	_noise.seed = 12101
	_noise.frequency = 0.012
	_noise.fractal_octaves = 3
	_noise2.seed = 12102
	_noise2.frequency = 0.05
	_noise2.fractal_octaves = 2


## 1 sur le bord de la ville, moins de 1 dessus
func coast_q(x: float, z: float) -> float:
	var r: float = pow(pow(absf(x), 3.5) + pow(absf(z), 3.5), 1.0 / 3.5)
	var a: float = atan2(z, x)
	var bump: float = sin(a * 5.0 + 0.7) * 7.0 + sin(a * 11.0 + 2.1) * 4.0
	# la jetée : le bord reste droit au nord
	if z < -150.0 and absf(x) < 30.0:
		bump *= smoothstep(10.0, 30.0, absf(x))
	return r / (RS + bump)


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
	print("ILE_MANGA_V121: Sombreval ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func hill_height(x: float, z: float) -> float:
	var r: float = Vector2(x, z).length()
	if r >= HILL_R1:
		return -100.0
	if r <= HILL_R0:
		return TOP
	var k: float = smoothstep(HILL_R1, HILL_R0, r)
	var rough: float = _noise2.get_noise_2d(x, z) * 2.6 * k * (1.0 - k) * 4.0
	return Y0 + (TOP - Y0) * pow(k, 1.3) + rough


func _shape(x: float, z: float) -> float:
	if in_jetee(x, z):
		return lerpf(1.0, Y0, smoothstep(float(JETEE[2]) + 2.0, float(JETEE[3]) - 1.0, z))
	var q: float = coast_q(x, z)
	var h: float
	if q <= 1.0:
		h = Y0 + _noise.get_noise_2d(x, z) * 0.35
	else:
		var off: float = (q - 1.0) * RS
		h = lerpf(Y0, -1.4, smoothstep(0.0, 16.0, off))
		h = minf(h, -1.4 - 30.0 * smoothstep(16.0, 52.0, off))
		h = maxf(h, -32.0)
	h = maxf(h, hill_height(x, z))
	var rp: Vector2 = ramp_at(x, z)
	if rp.x >= -0.03 and rp.x <= 1.0 and rp.y < RAMP_W + 2.5:
		var w: float = 1.0 - smoothstep(RAMP_W, RAMP_W + 2.5, rp.y)
		h = lerpf(h, ramp_height(rp.x), w)
	return h


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


## Les couleurs du sol en un point (repère île) : r asphalte, g herbes, b roche, a pavés
func ground_mask(x: float, z: float, h: float, slope: float) -> Color:
	var r: float = Vector2(x, z).length()
	var rp: Vector2 = ramp_at(x, z)
	var on_ramp: bool = rp.x >= -0.03 and rp.x <= 1.0 and rp.y < RAMP_W
	var green: float = clampf(_noise.get_noise_2d(x * 1.7 + 40.0, z * 1.7) * 1.4 + 0.45, 0.0, 1.0)
	var rock: float = smoothstep(0.45, 0.9, slope)
	var asph: float = 0.0
	var pave: float = 0.0
	if on_ramp or r < HILL_R0 - 1.0:
		pave = 1.0
		green *= 0.45
		rock *= 0.2
	elif r > HILL_R1 - 4.0 and on_road(x, z) and coast_q(x, z) < 0.985:
		asph = 1.0
		# les herbes percent l'asphalte par plaques
		green *= 0.55
	elif r < HILL_R1:
		rock = maxf(rock, smoothstep(HILL_R1, HILL_R0 + 20.0, r) * 0.7)
	if h < Y0 - 0.5:
		green *= smoothstep(-0.5, Y0 - 0.5, h)
	return Color(asph, green, rock, pave)


# =================================================================== maillage, collision

func _build_mesh() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sombreval_sol_v121.gdshader")
	var texs := {"asphalte_tex": "res://assets/textures/boucan/asphalte.png", "asphalte_n": "res://assets/textures/boucan/asphalte_n.png",
		"herbe_tex": "res://assets/textures/terrain/grass.jpg", "herbe_n": "res://assets/textures/terrain/grass_n.png",
		"roche_tex": "res://assets/textures/terrain/rock.jpg", "roche_n": "res://assets/textures/terrain/rock_n.png",
		"sable_tex": "res://assets/textures/terrain/sand.jpg", "sable_n": "res://assets/textures/terrain/sand_n.png",
		"pave_tex": "res://assets/textures/chateau/dalles_chateau.png", "pave_n": "res://assets/textures/chateau/dalles_chateau_n.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			mat.set_shader_parameter(k, load(texs[k]))
	mat.set_shader_parameter("plateau_y", Y0)
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
			mi.name = "Sombreval_sol_%d_%d" % [cx, cz]
			mi.mesh = _chunk_mesh(x0, z0, x1, z1)
			mi.material_override = mat
			add_child(mi)


func _chunk_mesh(x0: int, z0: int, x1: int, z1: int) -> ArrayMesh:
	var w: int = x1 - x0 + 1
	var dpt: int = z1 - z0 + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	verts.resize(w * dpt)
	normals.resize(w * dpt)
	uvs.resize(w * dpt)
	cols.resize(w * dpt)
	for zi in range(z0, z1 + 1):
		for xi in range(x0, x1 + 1):
			var k: int = (zi - z0) * w + (xi - x0)
			var lx: float = -HALF + xi * CELL
			var lz: float = -HALF + zi * CELL
			var h: float = heights[zi * count + xi]
			verts[k] = Vector3(CENTER.x + lx, h, CENTER.z + lz)
			var hl: float = heights[zi * count + maxi(xi - 1, 0)]
			var hr: float = heights[zi * count + mini(xi + 1, count - 1)]
			var hd: float = heights[maxi(zi - 1, 0) * count + xi]
			var hu: float = heights[mini(zi + 1, count - 1) * count + xi]
			var n := Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
			normals[k] = n
			uvs[k] = Vector2(CENTER.x + lx, CENTER.z + lz) * 0.2
			cols[k] = ground_mask(lx, lz, h, sqrt(1.0 - n.y * n.y) / maxf(n.y, 0.05))
	var indices := PackedInt32Array()
	indices.resize((w - 1) * (dpt - 1) * 6)
	var n6: int = 0
	for zi in range(dpt - 1):
		for xi in range(w - 1):
			var a: int = zi * w + xi
			var b: int = a + 1
			var c: int = a + w
			var d: int = c + 1
			indices[n6] = a; indices[n6 + 1] = b; indices[n6 + 2] = d
			indices[n6 + 3] = a; indices[n6 + 4] = d; indices[n6 + 5] = c
			n6 += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Sol_sombreval_v121"
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

extends Node3D
## V87 : le relief de l'Île aux Moaïs, au nord de l'archipel (entre l'île de la jungle et la
## Balafre). Une île en triangle, comme une pointe de flèche posée sur la mer : un volcan à
## chaque coin (au sud-ouest le Cratère du Lac, au nord le Mont Venteux, à l'est la Butte de la
## Carrière, où des têtes à moitié enterrées regardent le ciel) ; entre eux, une prairie qui
## ondule, des falaises de basalte tout autour, et au sud, face à l'archipel, la Plage Blanche
## où l'on accoste. Au milieu de l'île, sur le Plateau des Anciens, se dresse le Grand Moaï.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille ; une carte des sols est cuite pour le shader.

const CENTER := Vector3(-30.0, 0.0, -790.0)
const HALF: float = 200.0
const CELL: float = 1.6
const CHUNKS: int = 5
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint la mer de l'archipel au sud.
const SEA_R: float = 240.0
const SEA_LANE := Rect2(-90.0, 150.0, 180.0, 160.0)

## La côte : un triangle aux coins arrondis (rayon moyen, force des trois coins, angle du coin nord).
const R0: float = 140.0
const LOBE: float = 0.17
## Les trois volcans : [x, z, rayon du pied, hauteur, rayon du cratère (0 : pas de cratère)]
const VOLCANS := {
	"lac": [-96.0, 52.0, 70.0, 22.0, 20.0],
	"venteux": [0.0, -118.0, 52.0, 22.0, 0.0],
	"carriere": [104.0, 52.0, 48.0, 17.0, 0.0],
}
## Le lac du cratère : son niveau.
const LAC_Y: float = 15.0
## Le Plateau des Anciens (le Grand Moaï) et la Plage Blanche.
const PLATEAU := Vector2(0.0, 0.0)
const PLATEAU_R: float = 34.0
const PLATEAU_Y: float = 9.0
const PLAGE := Vector2(0.0, 94.0)
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : le sol), longueur de la pente]
const PADS := {
	"plateau": [0.0, 0.0, PLATEAU_R, PLATEAU_Y, 30.0],
	"ahu_couchant": [-118.0, -12.0, 14.0, 0.0, 12.0],
	"ahu_levant": [86.0, -22.0, 18.0, 0.0, 14.0],
	"ahu_plage": [-34.0, 96.0, 10.0, 0.0, 10.0],
	"carriere": [86.0, 70.0, 12.0, 0.0, 10.0],
	"belvedere": [-96.0, 24.0, 6.0, 0.0, 6.0],
}
## Le ponton de la barque (au bout de la Plage Blanche).
const DOCK_A := Vector2(14.0, 101.0)
const DOCK_B := Vector2(14.0, 119.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"plage": [Vector2(12.0, 98.0), Vector2(8.0, 88.0), Vector2(4.0, 70.0), Vector2(2.0, 42.0), Vector2(0.0, 30.0)],
	"couchant": [Vector2(-30.0, 8.0), Vector2(-60.0, 2.0), Vector2(-90.0, -6.0), Vector2(-108.0, -10.0)],
	"levant": [Vector2(30.0, -6.0), Vector2(52.0, -14.0), Vector2(72.0, -20.0)],
	"carriere": [Vector2(26.0, 18.0), Vector2(48.0, 40.0), Vector2(68.0, 58.0), Vector2(80.0, 66.0)],
	"lac": [Vector2(-24.0, 22.0), Vector2(-50.0, 30.0), Vector2(-74.0, 28.0), Vector2(-92.0, 26.0)],
	"venteux": [Vector2(0.0, -30.0), Vector2(-4.0, -56.0), Vector2(-2.0, -76.0)],
	"ahu_plage": [Vector2(4.0, 84.0), Vector2(-12.0, 90.0), Vector2(-26.0, 94.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins (terre), G roche (basalte), B sable, A herbe rase du plateau
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var terrain_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


## Le rayon de la côte dans la direction theta (le triangle aux coins arrondis).
static func coast_r(theta: float) -> float:
	var r: float = R0 * (1.0 + LOBE * cos(3.0 * (theta + PI * 0.5)))
	r *= 1.0 + 0.03 * sin(theta * 7.0 + 0.6) + 0.02 * sin(theta * 13.0 + 1.7) + 0.012 * sin(theta * 23.0 + 0.3)
	# la Plage Blanche : une anse au sud
	r -= 10.0 * exp(-pow(wrapf(theta - PI * 0.5, -PI, PI) / 0.22, 2.0))
	return r


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
static func coast_q(x: float, z: float) -> float:
	return Vector2(x, z).length() / coast_r(atan2(z, x))


## La plage : au sud, dans l'anse (le reste de la côte, ce sont des falaises).
static func beach_k(x: float, z: float) -> float:
	var th: float = atan2(z, x)
	return exp(-pow(wrapf(th - PI * 0.5, -PI, PI) / 0.3, 2.0))


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# =================================================================== relief

func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	_setup_noise()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var lz: float = -HALF + zi * CELL
		for xi in range(count):
			heights[zi * count + xi] = _shape(-HALF + xi * CELL, lz)
	for k in PADS:
		var p: Array = PADS[k]
		var w: Vector3 = W(float(p[0]), float(p[1]))
		var y: float = float(p[3])
		if y <= 0.0:
			y = height(w.x, w.z)
		_flatten(w.x, w.z, float(p[2]), float(p[2]) + float(p[4]), y)
		pads_world[k] = Vector3(w.x, y, w.z)
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	_build_lake()
	print("ILE_MANGA_V87: Île aux Moaïs ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 8701
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.011
	_detail.seed = 8702
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.05
	_hills.seed = 8704
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_octaves = 3
	_hills.frequency = 0.018


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var p := Vector2(x, z)
	var bk: float = beach_k(x, z)
	var coast: float
	if q < 1.0:
		# la plage monte doucement ; ailleurs, la falaise de basalte (4 à 9 m) tombe dans la mer
		var cliff_h: float = 5.0 + 3.0 * (_hills.get_noise_2d(x * 0.7, z * 0.7) * 0.5 + 0.5)
		var cliff: float = WATER + smoothstep(1.0, 0.975, q) * cliff_h
		var beach: float = WATER + 0.35 + smoothstep(1.0, 0.86, q) * 2.2
		coast = lerpf(cliff, beach, bk)
	else:
		var off: float = (q - 1.0) * R0
		coast = WATER + 0.35 - off * lerpf(0.9, 0.22, bk) - 30.0 * smoothstep(8.0, 34.0, off)
	coast = maxf(coast, -36.0)
	var inland: float = smoothstep(1.0, 0.9, q) if bk < 0.5 else smoothstep(0.98, 0.78, q)
	# la prairie : des ondulations douces qui montent vers le centre
	var c: float = 1.0 - smoothstep(0.0, 1.0, q)
	var land: float = 3.0 + 4.0 * c + _noise.get_noise_2d(x, z) * 2.4 + (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 3.0
	var rough: float = _detail.get_noise_2d(x * 1.5, z * 1.5) * 0.35
	var hn: float = coast + maxf(land + rough, 0.0) * inland
	# les volcans (le Cratère du Lac a son lac)
	for k in VOLCANS:
		var v: Array = VOLCANS[k]
		var d: float = p.distance_to(Vector2(float(v[0]), float(v[1])))
		var foot: float = float(v[2])
		if d < foot:
			var t: float = 1.0 - d / foot
			var cone: float = float(v[3]) * pow(smoothstep(0.0, 1.0, t), 1.25)
			var cr: float = float(v[4])
			if cr > 0.0:
				# un volcan tronqué : une pente régulière jusqu'au bord du cratère, un petit bourrelet
				var tt: float = clampf((foot - d) / (foot - cr - 8.0), 0.0, 1.0)
				cone = float(v[3]) * (0.5 * tt + 0.5 * tt * tt * (3.0 - 2.0 * tt)) + 1.5 * exp(-pow((d - cr - 5.0) / 4.0, 2.0))
			hn = maxf(hn, coast + cone * smoothstep(1.0, 0.85, q) + (hn - coast) * 0.4)
			if cr > 0.0:
				# la cuvette du lac (le fond, sous l'eau)
				hn = lerpf(hn, LAC_Y - 2.5, smoothstep(cr + 5.0, cr * 0.5, d))
	return hn


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


func _anchor_y(p: Vector2) -> float:
	var w: Vector3 = W(p.x, p.y)
	return height(w.x, w.z)


## Un chemin : un ruban en pente régulière, lissé, d'un lieu à l'autre.
func _carve(name: String, lane: Array) -> void:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.6), 1)
		for k in range(n):
			pts.append(a.lerp(b, float(k) / n))
	pts.append(lane[-1])
	var y0: float = _anchor_y(pts[0])
	var y1: float = _anchor_y(pts[-1])
	var total: float = 0.0
	var acc_len: Array = [0.0]
	for k in range(1, pts.size()):
		total += (pts[k] as Vector2).distance_to(pts[k - 1])
		acc_len.append(total)
	var raw: Array = []
	for k in range(pts.size()):
		var w0: Vector3 = W((pts[k] as Vector2).x, (pts[k] as Vector2).y)
		raw.append(height(w0.x, w0.z))
	var prof: Array = []
	for k in range(pts.size()):
		var t: float = float(acc_len[k]) / maxf(total, 0.01)
		var lin: float = lerpf(y0, y1, t)
		var sm: float = 0.0
		var nsm: int = 0
		for j in range(maxi(0, k - 6), mini(pts.size(), k + 7)):
			sm += float(raw[j])
			nsm += 1
		var ground: float = sm / float(nsm)
		var w: float = 0.6 * sin(PI * t)
		prof.append(maxf(lerpf(lin, ground, w), 0.6))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.6, 5.5, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 256


## R : la terre des chemins ; G : la roche (falaises, bords des volcans) ; B : le sable blanc ;
## A : l'herbe rase du Plateau des Anciens et des ahu.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var q: float = coast_q(x, z)
			var bk: float = beach_k(x, z)
			var sand: float = bk * (1.0 - smoothstep(0.86, 0.8, q + n * 0.03))
			var rock: float = (1.0 - bk) * smoothstep(0.95, 0.99, q + n * 0.02)
			for k in VOLCANS:
				var v: Array = VOLCANS[k]
				var d: float = p.distance_to(Vector2(float(v[0]), float(v[1])))
				if float(v[4]) > 0.0:
					rock = maxf(rock, 1.0 - smoothstep(4.0, 12.0, absf(d - float(v[4]) - 4.0) + n * 6.0))
				rock = maxf(rock, (1.0 - smoothstep(0.0, float(v[2]) * 0.22, d + n * 8.0)) * 0.7)
			var lawn: float = 1.0 - smoothstep(PLATEAU_R - 4.0, PLATEAU_R + 8.0, p.distance_to(PLATEAU) + n * 6.0)
			for k2 in ["ahu_couchant", "ahu_levant", "ahu_plage"]:
				var pd: Array = PADS[k2]
				lawn = maxf(lawn, 1.0 - smoothstep(float(pd[2]) - 2.0, float(pd[2]) + 6.0, p.distance_to(Vector2(float(pd[0]), float(pd[1]))) + n * 4.0))
			biome.set_pixel(xi, zi, Color(0.0, rock, sand, lawn))
	for k3 in paths_world:
		var pts: Array = paths_world[k3]
		for qp in pts:
			var l: Vector2 = L((qp as Vector3).x, (qp as Vector3).z)
			var cx: int = int((l.x + HALF) / px)
			var cz: int = int((l.y + HALF) / px)
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var ix: int = clampi(cx + dx, 0, BIOME_RES - 1)
					var iz: int = clampi(cz + dz, 0, BIOME_RES - 1)
					var c: Color = biome.get_pixel(ix, iz)
					biome.set_pixel(ix, iz, Color(maxf(c.r, 0.9 if dx == 0 and dz == 0 else 0.6), c.g * 0.5, c.b, c.a))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


# =================================================================== lecture du relief

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - CENTER.x + HALF) / CELL
	var fz: float = (wz - CENTER.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -36.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


## Dans le lac du cratère ?
func in_lake(wx: float, wz: float) -> bool:
	var v: Array = VOLCANS["lac"]
	var l: Vector2 = L(wx, wz)
	return l.distance_to(Vector2(float(v[0]), float(v[1]))) < float(v[4]) + 2.0 and height(wx, wz) < LAC_Y - 0.1


## La mer de l'île (un cercle et un chenal vers l'archipel, au sud) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < SEA_R or SEA_LANE.has_point(l)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	var a: Vector2 = c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)
	var l: Vector2 = L(wx, wz)
	var b: Vector2 = Vector2(clampf(l.x, SEA_LANE.position.x + 0.5, SEA_LANE.end.x - 0.5), clampf(l.y, SEA_LANE.position.y + 0.5, SEA_LANE.end.y - 0.5)) + c
	return a if Vector2(wx, wz).distance_to(a) < Vector2(wx, wz).distance_to(b) else b


# =================================================================== maillage, collision, lac

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/moai_terrain_v87.gdshader")
	var texs := {"herbe": "res://assets/textures/terrain/grass.jpg", "herbe_n": "res://assets/textures/terrain/grass_n.png",
		"herbe_seche": "res://assets/textures/boucan/herbe_seche.png", "herbe_seche_n": "res://assets/textures/boucan/herbe_seche_n.png",
		"roche": "res://assets/textures/volcan/basalte.png", "roche_n": "res://assets/textures/terrain/rock_n.png",
		"sable": "res://assets/textures/terrain/sand.jpg", "sable_n": "res://assets/textures/terrain/sand_n.png",
		"terre": "res://assets/textures/boucan/terre_noire.png", "terre_n": "res://assets/textures/boucan/terre_noire_n.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			mat.set_shader_parameter(k + ("" if str(k).ends_with("_n") else "_tex"), load(texs[k]))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("extra_detail", high_quality)
	terrain_mat = mat
	var per: int = (count - 1) / CHUNKS
	for cz in range(CHUNKS):
		for cx in range(CHUNKS):
			var x0: int = cx * per
			var z0: int = cz * per
			var x1: int = count - 1 if cx == CHUNKS - 1 else x0 + per
			var z1: int = count - 1 if cz == CHUNKS - 1 else z0 + per
			var top: float = -100.0
			for zi in range(z0, z1 + 1, 4):
				for xi in range(x0, x1 + 1, 4):
					top = maxf(top, heights[zi * count + xi])
			if top < -24.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Moai_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_moai_v87"
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


## Le lac du cratère : une eau calme, couleur de ciel, au fond du Cratère du Lac.
func _build_lake() -> void:
	var v: Array = VOLCANS["lac"]
	var mi := MeshInstance3D.new()
	mi.name = "Lac_du_cratere"
	var pm := CylinderMesh.new()
	pm.top_radius = float(v[4]) + 5.0
	pm.bottom_radius = float(v[4]) + 5.0
	pm.height = 0.02
	pm.radial_segments = 48
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.36, 0.38, 0.86)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 0.9
	mi.material_override = m
	add_child(mi)
	mi.global_position = W(float(v[0]), float(v[1]), LAC_Y)

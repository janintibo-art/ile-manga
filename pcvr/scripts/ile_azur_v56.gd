extends Node3D
## V56 : l'île de Port-Azur, au sud-est du village (la grande île touristique). Sa baie
## regarde le village : un port abrité derrière une jetée, une ville basse sur un plateau
## au bord de l'eau, une longue plage de sable à l'ouest, une pointe rocheuse à l'est où
## veille le phare, et derrière la ville des collines de maquis, d'oliviers et de pins
## jusqu'au belvédère.
## Repère « ville » : origine au milieu du quai, +Z vers l'intérieur des terres, -Z vers la
## mer (et le village, 240 m plus loin), +X le long du quai vers le phare.
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille.

const CENTER := Vector3(300.0, 0.0, 200.0)
const HALF: float = 205.0
const CELL: float = 1.25
const CHUNKS: int = 8
const WATER: float = -0.42
const TOWN_YAW: float = 0.98279                       # le repère ville tourné face au village
const TOWN_ORIGIN := Vector3(201.82, 0.0, 134.55)     # milieu du quai, au niveau de la mer
const TOWN_Y: float = 1.2                             # niveau des quais et de la ville basse
const QUAY_X0: float = -80.0                          # le quai, de la plage à la pointe
const QUAY_X1: float = 66.0
const TOWN_Z1: float = 86.0                           # fond de la ville basse
const BASIN_Y: float = -4.5                           # fond du port
const HEADLAND := Vector2(96.0, -12.0)                # la pointe du phare
const HEADLAND_R: float = 40.0
const LIGHTHOUSE := Vector2(104.0, -28.0)
const SUMMIT := Vector2(-20.0, 152.0)                 # le belvédère
## Le chemin des collines : de la ville au belvédère (repère ville)
const LANE := [Vector2(-38.0, 84.0), Vector2(-34.0, 98.0), Vector2(-12.0, 108.0), Vector2(18.0, 116.0),
	Vector2(30.0, 128.0), Vector2(14.0, 140.0), Vector2(-8.0, 146.0), Vector2(-20.0, 152.0)]
## Les terrasses des maisons des collines (x, z, rayon)
const PADS := [Vector3(-52.0, 100.0, 7.0), Vector3(-24.0, 118.0, 7.0), Vector3(2.0, 98.0, 7.5), Vector3(34.0, 106.0, 7.0),
	Vector3(46.0, 128.0, 7.0), Vector3(-2.0, 128.0, 6.5), Vector3(28.0, 144.0, 6.5), Vector3(-36.0, 138.0, 6.5),
	Vector3(60.0, 96.0, 7.0), Vector3(-72.0, 96.0, 7.0)]

var count: int = 0
var heights := PackedFloat32Array()
var basis_town := Basis(Vector3.UP, TOWN_YAW)
var lane_world: Array = []                            # le chemin des collines (monde)
var pads_world: Array = []                            # terrasses (monde, hauteur comprise)
var summit_world: Vector3
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()


# =================================================================== repère ville

static func to_world(x: float, z: float, y: float = 0.0) -> Vector3:
	var c: float = cos(TOWN_YAW)
	var s: float = sin(TOWN_YAW)
	return Vector3(TOWN_ORIGIN.x + c * x + s * z, y, TOWN_ORIGIN.z - s * x + c * z)


static func to_town(wx: float, wz: float) -> Vector2:
	var c: float = cos(TOWN_YAW)
	var s: float = sin(TOWN_YAW)
	var dx: float = wx - TOWN_ORIGIN.x
	var dz: float = wz - TOWN_ORIGIN.z
	return Vector2(dx * c - dz * s, dx * s + dz * c)


# =================================================================== relief

func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	_setup_noise()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var wz: float = CENTER.z - HALF + zi * CELL
		for xi in range(count):
			var wx: float = CENTER.x - HALF + xi * CELL
			var l: Vector2 = to_town(wx, wz)
			heights[zi * count + xi] = _shape(l.x, l.y)
	_carve_lane()
	for p in PADS:
		var w: Vector3 = to_world(p.x, p.y)
		var y: float = height(w.x, w.z)
		_flatten(w.x, w.z, p.z, p.z + 6.0, y)
		pads_world.append(Vector3(w.x, y, w.z))
	var sw: Vector3 = to_world(SUMMIT.x, SUMMIT.y)
	var sy: float = height(sw.x, sw.z)
	_flatten(sw.x, sw.z, 7.0, 13.0, sy)
	summit_world = Vector3(sw.x, sy, sw.z)
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V56: île de Port-Azur ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms, belvédère à ", summit_world)


func _setup_noise() -> void:
	_noise.seed = 5601
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.012
	_detail.seed = 5602
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail.fractal_octaves = 3
	_detail.frequency = 0.045
	_coast.seed = 5603
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8


## L'île « naturelle » : un ovale aux côtes découpées, des collines au centre.
func _natural(x: float, z: float) -> float:
	var ax: float = absf((x + 5.0) / 172.0)
	var az: float = absf((z - 118.0) / 130.0)
	var theta: float = atan2(z - 118.0, x + 5.0)
	var q: float = pow(pow(ax, 2.4) + pow(az, 2.4), 1.0 / 2.4)
	q *= 1.0 + 0.07 * _coast.get_noise_2d(cos(theta) * 2.0, sin(theta) * 2.0) + 0.025 * sin(theta * 7.0 + 1.3)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.9, q) * 1.8
	else:
		coast = WATER + 0.35 - (q - 1.0) * 150.0 * 0.32
	coast = maxf(coast, -46.0)          # au large, le fond général (mer_v55) reprend la main
	var inland: float = smoothstep(0.97, 0.62, q)
	var hills: float = 42.0 * exp(-(pow(x - SUMMIT.x, 2.0) + pow(z - SUMMIT.y - 8.0, 2.0)) / (78.0 * 78.0))
	hills += 26.0 * exp(-(pow(x - 70.0, 2.0) + pow(z - 150.0, 2.0)) / (55.0 * 55.0))
	hills += 20.0 * exp(-(pow(x + 110.0, 2.0) + pow(z - 140.0, 2.0)) / (50.0 * 50.0))
	hills += (_noise.get_noise_2d(x, z) * 0.5 + 0.5) * 8.0
	hills += _detail.get_noise_2d(x, z) * 1.4 * smoothstep(20.0, 80.0, z)
	var hn: float = coast + maxf(hills, 0.0) * inland
	# au bord du carré de l'île, le relief rejoint le fond du large (pas de marche sous l'eau)
	var wp: Vector3 = to_world(x, z)
	var edge: float = minf(HALF - absf(wp.x - CENTER.x), HALF - absf(wp.z - CENTER.z))
	if hn < 0.0 and edge < 45.0:
		hn = lerpf(-46.0, hn, smoothstep(5.0, 45.0, edge))
	return hn


func _shape(x: float, z: float) -> float:
	var h: float = _natural(x, z)
	# Le port : un bassin profond devant le quai, qui rejoint le fond du large
	if x > QUAY_X0 - 6.0 and x < QUAY_X1 + 30.0 and z < 0.0:
		var out_x: float = maxf(maxf(QUAY_X0 - x, x - QUAY_X1), 0.0)
		var out_z: float = maxf(-100.0 - z, 0.0)
		var wb: float = 1.0 - smoothstep(0.0, 26.0, Vector2(out_x, out_z).length())
		h = lerpf(h, minf(h, BASIN_Y), wb)
	# La ville basse : un plateau à 1,2 m, fondu dans les collines derrière
	if z >= 0.0:
		var dx: float = maxf(maxf(QUAY_X0 - x, x - QUAY_X1), 0.0)
		var dz: float = maxf(z - TOWN_Z1, 0.0)
		var wt: float = 1.0 - smoothstep(0.0, 20.0, Vector2(dx, dz).length())
		if wt > 0.0:
			var target: float = TOWN_Y if dz <= 0.0 or h < TOWN_Y else lerpf(TOWN_Y, h, smoothstep(0.0, 20.0, dz))
			h = lerpf(h, target, wt)
	# La plage : promenade, petit mur, sable en pente douce, puis le large
	if x < QUAY_X0 + 2.0 and x > -205.0 and z > -45.0 and z < 70.0:
		var bh: float
		if z >= 18.0:
			bh = TOWN_Y
		elif z >= 13.0:
			bh = lerpf(0.72, TOWN_Y, smoothstep(13.0, 17.5, z))
		elif z >= -5.0:
			bh = lerpf(WATER - 0.12, 0.72, (z + 5.0) / 18.0)
		else:
			bh = lerpf(WATER - 0.12, -3.8, smoothstep(-5.0, -38.0, z))
		var ex: float = maxf(maxf(-172.0 - x, x - (QUAY_X0 - 2.0)), 0.0)
		var wxb: float = 1.0 - smoothstep(0.0, 28.0, ex)
		var wzb: float = (1.0 - smoothstep(26.0, 55.0, z)) * smoothstep(-45.0, -30.0, z)
		var wb2: float = wxb * wzb
		if z > 22.0:
			bh = maxf(bh, h)       # derrière la promenade, la colline reprend
		h = lerpf(h, bh, wb2)
	# La pointe rocheuse du phare
	var dh: float = Vector2(x - HEADLAND.x, z - HEADLAND.y).length()
	if dh < HEADLAND_R + 18.0:
		var rock: float = _detail.get_noise_2d(x * 1.7, z * 1.7) * 1.4
		var hh: float
		if dh < HEADLAND_R:
			hh = TOWN_Y + 11.0 * pow(1.0 - pow(dh / HEADLAND_R, 2.0), 0.8) + rock
		else:
			hh = TOWN_Y + rock * 0.5 - (dh - HEADLAND_R) * 0.55
		h = maxf(h, hh)
	return h


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


## Le chemin des collines : un ruban en pente douce, lissé, de la ville au belvédère.
func _carve_lane() -> void:
	var pts: Array = []
	for i in range(LANE.size() - 1):
		var a: Vector2 = LANE[i]
		var b: Vector2 = LANE[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.5), 1)
		for k in range(n):
			pts.append(a.lerp(b, float(k) / n))
	pts.append(LANE[-1])
	var prof: Array = []
	for p in pts:
		var w: Vector3 = to_world(p.x, p.y)
		prof.append(height(w.x, w.z))
	prof[0] = TOWN_Y
	for pass_i in range(8):
		var nxt: Array = prof.duplicate()
		for k in range(1, prof.size() - 1):
			var acc: float = 0.0
			for o in range(-4, 5):
				acc += float(prof[clampi(k + o, 0, prof.size() - 1)])
			nxt[k] = acc / 9.0
		nxt[0] = TOWN_Y
		prof = nxt
	lane_world.clear()
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = to_world(p2.x, p2.y)
		_flatten(w2.x, w2.z, 2.2, 5.0, float(prof[k]))
		lane_world.append(Vector3(w2.x, float(prof[k]), w2.z))


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


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var a := "res://assets/textures/azur/"
	mat.set_shader_parameter("sand_tex", load(a + "sable_azur.png"))
	mat.set_shader_parameter("sand_n", load(a + "sable_azur_n.png"))
	mat.set_shader_parameter("soil_tex", load(a + "terre_garrigue.png"))
	mat.set_shader_parameter("soil_n", load(a + "terre_garrigue_n.png"))
	mat.set_shader_parameter("moss_tex", load(a + "herbe_seche.png"))
	mat.set_shader_parameter("moss_n", load(a + "herbe_seche_n.png"))
	mat.set_shader_parameter("rock_tex", load(a + "calcaire.png"))
	mat.set_shader_parameter("rock_n", load(a + "calcaire_n.png"))
	mat.set_shader_parameter("extra_detail", high_quality)
	var per: int = (count - 1) / CHUNKS
	for cz in range(CHUNKS):
		for cx in range(CHUNKS):
			var x0: int = cx * per
			var z0: int = cz * per
			var x1: int = count - 1 if cx == CHUNKS - 1 else x0 + per
			var z1: int = count - 1 if cz == CHUNKS - 1 else z0 + per
			# rien que de la mer profonde : pas de maillage
			var top: float = -100.0
			for zi in range(z0, z1 + 1, 4):
				for xi in range(x0, x1 + 1, 4):
					top = maxf(top, heights[zi * count + xi])
			if top < -26.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Azur_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_azur_v56"
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

extends Node3D
## V91 : le relief de l'Île de Larsen, au nord-ouest de l'archipel (entre Astralys et l'Île aux
## Moaïs). Une île ronde et douce : des collines vertes au nord (le Bois des Riffs, la Colline du
## Feedback), une grande plage au sud (la Plage du Larsen, où l'on accoste). Trois terre-pleins :
## à l'ouest, le Camp des Fleurs (les hippies et leurs yourtes) ; à l'est, Rainville (les grunges, leurs
## yourtes sombres et leurs garages) ; au milieu, la Prairie du Festival et sa Grande Scène. Des champs
## de chanvre (pour les cordes et les tissus) au nord-ouest, de grands champs de coquelicots au sud-est.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage, collision
## et height() lisent la même grille ; une carte des sols est cuite pour le shader (celui de la V87).

const CENTER := Vector3(-430.0, 0.0, -790.0)
const HALF: float = 150.0
const CELL: float = 1.5
const CHUNKS: int = 5
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint celui de l'Île aux Moaïs, à l'est.
const SEA_R: float = 190.0
const R0: float = 116.0

## Les terre-pleins : nom -> [x, z, rayon plat, hauteur, longueur de la pente]
const PADS := {
	"festival": [0.0, 4.0, 32.0, 4.0, 22.0],
	"fleurs": [-62.0, 14.0, 30.0, 3.4, 18.0],
	"rainville": [60.0, -2.0, 30.0, 3.2, 18.0],
	"corderie": [-28.0, -40.0, 11.0, 0.0, 8.0],
	"belvedere": [8.0, -84.0, 7.0, 0.0, 8.0],
	"roadies": [12.0, -52.0, 15.0, 0.0, 12.0],
}
## Les champs : nom -> [x, z, demi-largeur, demi-profondeur, angle (radians)]
const CHAMPS := {
	"chanvre": [-56.0, -66.0, 26.0, 16.0, 0.25],
	"chanvre_2": [-86.0, -36.0, 14.0, 12.0, -0.35],
	"coquelicots": [46.0, 58.0, 30.0, 18.0, -0.2],
	"coquelicots_2": [-20.0, 62.0, 18.0, 12.0, 0.3],
}
## La Mare aux Mantras (près du Camp des Fleurs)
const MARE := [-78.0, 46.0, 9.0, 2.6]
const COLLINE := [10.0, -82.0, 30.0, 14.0]
const PLAGE := Vector2(0.0, 102.0)
const DOCK_A := Vector2(16.0, 108.0)
const DOCK_B := Vector2(16.0, 128.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"plage": [Vector2(16.0, 106.0), Vector2(10.0, 88.0), Vector2(4.0, 62.0), Vector2(2.0, 38.0)],
	"fleurs": [Vector2(-30.0, 8.0), Vector2(-40.0, 10.0)],
	"rainville": [Vector2(30.0, 2.0), Vector2(38.0, 0.0)],
	"corderie": [Vector2(-52.0, -12.0), Vector2(-44.0, -28.0), Vector2(-36.0, -38.0)],
	"colline": [Vector2(0.0, -26.0), Vector2(4.0, -50.0), Vector2(8.0, -76.0)],
	"mare": [Vector2(-68.0, 30.0), Vector2(-72.0, 36.0)],
	"coquelicots": [Vector2(12.0, 62.0), Vector2(26.0, 58.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins (terre), G roche, B sable, A herbe rase (les terre-pleins)
var pads_world: Dictionary = {}
var paths_world: Dictionary = {}
var terrain_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func coast_r(theta: float) -> float:
	var r: float = R0 * (1.0 + 0.06 * sin(theta * 2.0 + 0.4) + 0.04 * sin(theta * 5.0 + 1.3) + 0.02 * sin(theta * 11.0 + 0.2))
	# la grande plage du sud : un peu plus large
	r += 8.0 * exp(-pow(wrapf(theta - PI * 0.5, -PI, PI) / 0.6, 2.0))
	return r


static func coast_q(x: float, z: float) -> float:
	return Vector2(x, z).length() / coast_r(atan2(z, x))


## La plage : tout le sud et l'est ; au nord, de petites falaises sous le bois.
static func beach_k(x: float, z: float) -> float:
	var th: float = atan2(z, x)
	return clampf(0.5 + 0.7 * sin(th), 0.0, 1.0)


## Dans un champ ? (renvoie le nom, ou "")
static func champ_at(x: float, z: float) -> String:
	for k in CHAMPS:
		var c: Array = CHAMPS[k]
		var d := Vector2(x - float(c[0]), z - float(c[1])).rotated(-float(c[4]))
		if absf(d.x) < float(c[2]) and absf(d.y) < float(c[3]):
			return str(k)
	return ""


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
	# les champs : un sol presque plat (on laboure à plat)
	for k3 in CHAMPS:
		var c: Array = CHAMPS[k3]
		var wc: Vector3 = W(float(c[0]), float(c[1]))
		_flatten(wc.x, wc.z, maxf(float(c[2]), float(c[3])) * 0.8, maxf(float(c[2]), float(c[3])) + 10.0, height(wc.x, wc.z))
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	_dig_mare()
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	_build_mare()
	print("ILE_MANGA_V91: Île de Larsen ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 9101
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.012
	_detail.seed = 9102
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.05
	_hills.seed = 9104
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_octaves = 3
	_hills.frequency = 0.02


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var bk: float = beach_k(x, z)
	var coast: float
	if q < 1.0:
		var cliff_h: float = 3.0 + 2.5 * (_hills.get_noise_2d(x * 0.7, z * 0.7) * 0.5 + 0.5)
		var cliff: float = WATER + smoothstep(1.0, 0.975, q) * cliff_h
		var beach: float = WATER + 0.35 + smoothstep(1.0, 0.84, q) * 2.4
		coast = lerpf(cliff, beach, bk)
	else:
		var off: float = (q - 1.0) * R0
		coast = WATER + 0.35 - off * lerpf(0.9, 0.2, bk) - 30.0 * smoothstep(8.0, 36.0, off)
	coast = maxf(coast, -34.0)
	var inland: float = smoothstep(1.0, 0.9, q) if bk < 0.5 else smoothstep(0.97, 0.76, q)
	# des collines douces, plus hautes au nord (le Bois des Riffs)
	var north: float = smoothstep(10.0, -90.0, z)
	var land: float = 2.6 + 2.0 * (1.0 - q) + north * 7.0 + _noise.get_noise_2d(x, z) * 2.2 + (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 2.5 * (0.4 + north)
	var rough: float = _detail.get_noise_2d(x * 1.5, z * 1.5) * 0.3
	var hn: float = coast + maxf(land + rough, 0.0) * inland
	# la Colline du Feedback
	var dc: float = Vector2(x, z).distance_to(Vector2(float(COLLINE[0]), float(COLLINE[1])))
	if dc < float(COLLINE[2]):
		hn = maxf(hn, coast + (float(COLLINE[3]) * pow(smoothstep(0.0, 1.0, 1.0 - dc / float(COLLINE[2])), 1.2) + (hn - coast) * 0.5) * smoothstep(1.0, 0.85, q))
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


## La Mare aux Mantras : une cuvette creusée après les terre-pleins ; tout autour, une berge un
## peu plus haute que l'eau.
func _dig_mare() -> void:
	var mc: Vector3 = W(float(MARE[0]), float(MARE[1]))
	var r: float = float(MARE[2])
	var lvl: float = float(MARE[3])
	var cx: float = (mc.x - CENTER.x + HALF) / CELL
	var cz: float = (mc.z - CENTER.z + HALF) / CELL
	var reach: int = int(ceil((r + 7.0) / CELL)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			var i: int = zi * count + xi
			if d < r:
				heights[i] = lvl - 0.3 - 1.3 * sqrt(1.0 - d / r)
			elif d < r + 2.5:
				heights[i] = lerpf(lvl - 0.3, maxf(heights[i], lvl + 0.35), smoothstep(r, r + 2.5, d))
			elif d < r + 7.0:
				heights[i] = maxf(heights[i], lerpf(lvl + 0.35, heights[i], smoothstep(r + 2.5, r + 7.0, d)))


func _anchor_y(p: Vector2) -> float:
	var w: Vector3 = W(p.x, p.y)
	return height(w.x, w.z)


## Un chemin : un ruban en pente régulière, lissé, d'un lieu à l'autre.
func _carve(name: String, lane: Array) -> void:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.5), 1)
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
		raw.append(_anchor_y(pts[k]))
	var prof: Array = []
	for k in range(pts.size()):
		var t: float = float(acc_len[k]) / maxf(total, 0.01)
		var lin: float = lerpf(y0, y1, t)
		var sm: float = 0.0
		var nsm: int = 0
		for j in range(maxi(0, k - 4), mini(pts.size(), k + 5)):
			sm += float(raw[j])
			nsm += 1
		prof.append(maxf(lerpf(lin, sm / float(nsm), minf(1.0, 4.0 * sin(PI * t)) * 0.92), 0.6))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.7, 5.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 256


## R : la terre (chemins, champs labourés) ; G : la roche (les petites falaises) ; B : le sable ;
## A : l'herbe rase (les terre-pleins des quartiers, le festival).
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
			var lawn: float = 0.0
			for k2 in ["festival", "fleurs", "rainville"]:
				var pd: Array = PADS[k2]
				lawn = maxf(lawn, 1.0 - smoothstep(float(pd[2]) - 4.0, float(pd[2]) + 4.0, p.distance_to(Vector2(float(pd[0]), float(pd[1]))) + n * 5.0))
			var dirt: float = 0.0
			var chp: String = champ_at(x, z)
			if chp != "":
				dirt = 0.45 if chp.begins_with("chanvre") else 0.12
			# Rainville : la terre battue entre les yourtes (on y passe beaucoup, il y pleut souvent)
			var rv: Array = PADS["rainville"]
			dirt = maxf(dirt, 0.35 * (1.0 - smoothstep(14.0, 26.0, p.distance_to(Vector2(float(rv[0]), float(rv[1]))) + n * 6.0)))
			biome.set_pixel(xi, zi, Color(dirt, rock, sand, lawn))
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
					biome.set_pixel(ix, iz, Color(maxf(c.r, 0.9 if dx == 0 and dz == 0 else 0.6), c.g * 0.5, c.b, c.a * 0.5))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


# =================================================================== lecture

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - CENTER.x + HALF) / CELL
	var fz: float = (wz - CENTER.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -34.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


func in_mare(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.distance_to(Vector2(float(MARE[0]), float(MARE[1]))) < float(MARE[2]) + 1.0 and height(wx, wz) < float(MARE[3]) - 0.1


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== maillage, collision, mare

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/moai_terrain_v87.gdshader")
	var texs := {"herbe": "res://assets/textures/terrain/grass.jpg", "herbe_n": "res://assets/textures/terrain/grass_n.png",
		"herbe_seche": "res://assets/textures/boucan/herbe_seche.png", "herbe_seche_n": "res://assets/textures/boucan/herbe_seche_n.png",
		"roche": "res://assets/textures/terrain/rock.jpg", "roche_n": "res://assets/textures/terrain/rock_n.png",
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
			mi.name = "Larsen_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_larsen_v91"
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


## La Mare aux Mantras : une eau calme, des nénuphars (posés par la flore).
func _build_mare() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Mare_aux_Mantras"
	var pm := CylinderMesh.new()
	pm.top_radius = float(MARE[2]) + 1.4
	pm.bottom_radius = float(MARE[2]) + 1.4
	pm.height = 0.02
	pm.radial_segments = 40
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.14, 0.3, 0.3, 0.88)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 0.9
	mi.material_override = m
	add_child(mi)
	mi.global_position = W(float(MARE[0]), float(MARE[1]), float(MARE[3]))

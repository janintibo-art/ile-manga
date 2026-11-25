extends Node3D
## V209 : le relief de l'Île Foraine, à l'est de l'archipel (au large de Montjoie ; son carré ne touche
## aucune autre île). Une île ronde et plate : une grande esplanade d'herbe à 3 m au-dessus de la
## mer, une plage tout autour, la Butte aux Frissons au nord. Le Grand Frisson (le grand huit) en fait
## le tour : le sol se creuse un peu là où la voie rase la terre.

const Trace = preload("res://scripts/grand_huit_trace_v209.gd")

const CENTER := Vector3(1750.0, 0.0, 300.0)
const HALF: float = 300.0
const CELL: float = 2.0
const CHUNKS: int = 6
const WATER: float = -0.42
const SEA_R: float = 420.0
const RS: float = 188.0                    # le rayon de la côte
const SOL: float = 3.0                     # l'esplanade
const BUTTE := Vector2(18.0, -116.0)
const BUTTE_R: float = 78.0
const BUTTE_Y: float = 21.0
## Le ponton, à l'ouest (vers Montjoie)
const DOCK_A := Vector2(-196.0, 20.0)
const DOCK_B := Vector2(-224.0, 20.0)
## L'entrée (le portail, les guichets), la place, le quai du grand huit
const ENTREE := Vector2(-158.0, 20.0)
const PLACE := Vector2(-20.0, 20.0)
const PLACE_R: float = 24.0
const GARE := Vector2(-78.0, 62.0)
## Les allées : [points, demi-largeur]
const ALLEES := [
	[[[-192.0, 20.0], [-158.0, 20.0], [-20.0, 20.0], [70.0, 20.0]], 4.5],
	[[[-78.0, 20.0], [-78.0, 58.0]], 3.2],
	[[[-20.0, 20.0], [-20.0, -18.0], [10.0, -62.0], [18.0, -100.0]], 2.6],
	[[[-20.0, 20.0], [-10.0, 100.0], [20.0, 150.0]], 2.6],
	[[[38.0, 20.0], [38.0, 38.0]], 2.6],        # V210 : vers le Marteau
]
const PLATS_V210 := [[36.0, 44.0, 15.0], [20.0, 158.0, 11.0]]   # V210 : sous le Marteau, sous la Grande Balançoire
const BIOME_RES: int = 301

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image
var ground_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


## La distance (m) à l'allée la plus proche, et sa demi-largeur : Vector2(distance, demi-largeur)
static func allee_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	for c in ALLEES:
		var pts: Array = c[0]
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
			var d: float = p.distance_to(q)
			if d - float(c[1]) < best.x - best.y:
				best = Vector2(d, float(c[1]))
	return best


func _init() -> void:
	_noise.seed = 20901
	_noise.frequency = 0.008
	_noise.fractal_octaves = 3
	_noise2.seed = 20902
	_noise2.frequency = 0.04
	_noise2.fractal_octaves = 2


## 1 sur le bord de l'île, moins de 1 dessus
func coast_q(x: float, z: float) -> float:
	var r: float = Vector2(x, z).length()
	var a: float = atan2(z, x)
	var bump: float = sin(a * 3.0 + 1.1) * 7.0 + sin(a * 7.0 + 0.6) * 3.5 + sin(a * 13.0 + 2.0) * 1.5
	# la grève de l'ouest (le ponton) : un rivage régulier
	if x < -120.0 and absf(z - DOCK_A.y) < 60.0:
		bump *= smoothstep(20.0, 60.0, absf(z - DOCK_A.y))
	return r / (RS + bump)


func build(_high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var lz: float = -HALF + zi * CELL
		for xi in range(count):
			heights[zi * count + xi] = _shape(-HALF + xi * CELL, lz)
	_creuser()
	_bake_biome()
	_build_mesh()
	_build_collision()
	print("ILE_MANGA_V209: l'Île Foraine ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	if q > 1.0:
		var off: float = (q - 1.0) * RS
		if off < 18.0:
			return lerpf(0.5, -1.4, smoothstep(0.0, 18.0, off))
		return maxf(-1.4 - 30.0 * smoothstep(18.0, 56.0, off), -32.0)
	var inland: float = (1.0 - q) * RS
	var h: float = lerpf(0.5, 2.2, smoothstep(0.0, 14.0, inland))
	var doux: float = SOL + _noise.get_noise_2d(x, z) * 0.5
	h = lerpf(h, doux, smoothstep(10.0, 30.0, inland))
	# la Butte aux Frissons : un dôme d'herbe, son sommet aplati
	var db: float = Vector2(x, z).distance_to(BUTTE)
	if db < BUTTE_R:
		var k: float = smoothstep(BUTTE_R, 16.0, db)
		h = lerpf(h, BUTTE_Y + _noise2.get_noise_2d(x, z) * 0.6, k * k * (3.0 - 2.0 * k) * smoothstep(0.0, 22.0, inland))
	# les allées, la place, l'entrée, le quai : bien à plat
	var al: Vector2 = allee_at(x, z)
	var plat: float = 1.0 - smoothstep(al.y, al.y + 5.0, al.x)
	plat = maxf(plat, 1.0 - smoothstep(PLACE_R, PLACE_R + 6.0, Vector2(x, z).distance_to(PLACE)))
	plat = maxf(plat, 1.0 - smoothstep(22.0, 30.0, Vector2((x - GARE.x) * 0.5, z - GARE.y - 6.0).length()))
	for pv in PLATS_V210:
		plat = maxf(plat, 1.0 - smoothstep(float(pv[2]), float(pv[2]) + 6.0, Vector2(x - float(pv[0]), z - float(pv[1])).length()))
	if db > BUTTE_R * 0.55 and inland > 24.0:
		h = lerpf(h, SOL, plat)
	return h


## Sous la voie du grand huit, le sol reste à plus de 2 m des rails.
func _creuser() -> void:
	var d: Dictionary = Trace.tracer()
	var pts: PackedVector3Array = d["pts"]
	for p in pts:
		if p.y > 30.0:
			continue
		var cx: int = int(round((p.x + HALF) / CELL))
		var cz: int = int(round((p.z + HALF) / CELL))
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				var xi: int = cx + dx
				var zi: int = cz + dz
				if xi < 0 or zi < 0 or xi >= count or zi >= count:
					continue
				var dist: float = Vector2(-HALF + xi * CELL - p.x, -HALF + zi * CELL - p.z).length()
				var plafond: float = p.y - 2.2 + maxf(dist - 3.0, 0.0) * 0.8
				var i: int = zi * count + xi
				if heights[i] > plafond:
					heights[i] = plafond


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


func height_l(x: float, z: float) -> float:
	return height(CENTER.x + x, CENTER.z + z)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


## R : la terre battue (au pied de la butte, sous le grand huit) ; B : le sous-bois (la butte) ;
## A : les dalles (les allées, la place, l'entrée, le quai).
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / float(BIOME_RES - 1)
	for zi in range(BIOME_RES):
		var z: float = -HALF + zi * px
		for xi in range(BIOME_RES):
			var x: float = -HALF + xi * px
			var al: Vector2 = allee_at(x, z)
			var pave: float = 1.0 - smoothstep(al.y - 0.6, al.y + 0.6, al.x)
			pave = maxf(pave, 1.0 - smoothstep(PLACE_R - 1.0, PLACE_R + 1.0, Vector2(x, z).distance_to(PLACE)))
			pave = maxf(pave, 1.0 - smoothstep(13.0, 15.0, Vector2(x, z).distance_to(ENTREE)))
			var dirt: float = (1.0 - smoothstep(al.y + 0.5, al.y + 3.0, al.x)) * 0.6 * (1.0 - pave)
			var db: float = Vector2(x, z).distance_to(BUTTE)
			var forest: float = (1.0 - smoothstep(BUTTE_R * 0.5, BUTTE_R * 0.95, db)) * (0.45 + 0.3 * _noise2.get_noise_2d(x * 2.0, z * 2.0))
			biome.set_pixel(xi, zi, Color(clampf(dirt, 0.0, 1.0), 0.0, clampf(forest, 0.0, 1.0), clampf(pave, 0.0, 1.0)))


func _build_mesh() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/geants_sol_v142.gdshader")
	var S := "res://assets/textures/montjoie/"
	for k in ["prairie", "champ", "chemin", "sous_bois", "roche_crocs", "sable_lac", "paves"]:
		if ResourceLoader.exists(S + k + ".png"):
			mat.set_shader_parameter(k + "_tex", load(S + k + ".png"))
		if ResourceLoader.exists(S + k + "_n.png"):
			mat.set_shader_parameter(k + "_n", load(S + k + "_n.png"))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("lake", Vector4(CENTER.x, CENTER.z - 5000.0, 1.0, 1.0))
	mat.set_shader_parameter("lake_y", -100.0)
	mat.set_shader_parameter("town", Vector4(CENTER.x, CENTER.z, 0.0, 0.0))
	mat.set_shader_parameter("extra_detail", true)
	mat.set_shader_parameter("water_level", WATER)
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
			mi.name = "Foraine_sol_%d_%d" % [cx, cz]
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
			var lx: float = -HALF + xi * CELL
			var lz: float = -HALF + zi * CELL
			verts[k] = Vector3(CENTER.x + lx, heights[zi * count + xi], CENTER.z + lz)
			var hl: float = heights[zi * count + maxi(xi - 1, 0)]
			var hr: float = heights[zi * count + mini(xi + 1, count - 1)]
			var hd: float = heights[maxi(zi - 1, 0) * count + xi]
			var hu: float = heights[mini(zi + 1, count - 1) * count + xi]
			normals[k] = Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
			uvs[k] = Vector2(CENTER.x + lx, CENTER.z + lz) * 0.2
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
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Sol_foraine_v209"
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

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
## V213 : l'île devient volcanique. La Butte est un volcan : sa crête à 58 m, le cratère au milieu (la
## Chute se dresse sur son îlot, la croûte de lave autour), la Brèche par où l'allée y entre. Au pied
## de la grande chute du grand huit, la Faille : une arête de basalte que la voie fend, de la lave au fond.
const VOLCAN_R: float = 110.0
const CRATERE_R: float = 34.0
const CRATERE_Y: float = 58.0
const ILOT_R: float = 13.0                 # l'îlot de la Chute, au milieu du cratère
const LAVE_Y: float = BUTTE_Y - 1.5        # la croûte de lave du cratère
const FAILLE_A := Vector2(121.5, -4.0)
const FAILLE_B := Vector2(121.5, -56.0)
const FAILLE_Y: float = 15.0
## La coulée du nord : de la bouche, sur le flanc, jusqu'à la mer
const COULEE := [[19.0, -150.0], [27.0, -166.0], [24.0, -180.0], [31.0, -200.0]]

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
	var db: float = Vector2(x, z).distance_to(BUTTE)
	# les allées, la place, l'entrée, le quai : bien à plat
	var al: Vector2 = allee_at(x, z)
	var plat: float = 1.0 - smoothstep(al.y, al.y + 5.0, al.x)
	plat = maxf(plat, 1.0 - smoothstep(PLACE_R, PLACE_R + 6.0, Vector2(x, z).distance_to(PLACE)))
	plat = maxf(plat, 1.0 - smoothstep(22.0, 30.0, Vector2((x - GARE.x) * 0.5, z - GARE.y - 6.0).length()))
	for pv in PLATS_V210:
		plat = maxf(plat, 1.0 - smoothstep(float(pv[2]), float(pv[2]) + 6.0, Vector2(x - float(pv[0]), z - float(pv[1])).length()))
	if inland > 24.0:
		h = lerpf(h, SOL, plat)
	return _volcanique(x, z, h, inland)


static func _dist_ligne(p: Vector2, pts: Array) -> float:
	var best: float = 1e9
	for i in range(pts.size() - 1):
		var a := Vector2(float(pts[i][0]), float(pts[i][1]))
		var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best


## V213 : le volcan (ses flancs ravinés, la crête, le cratère et son îlot, la Brèche), la coulée du
## nord, l'arête de la Faille. « h » : le sol de l'île sans tout cela.
func _volcanique(x: float, z: float, h: float, inland: float) -> float:
	var p := Vector2(x, z)
	var db: float = p.distance_to(BUTTE)
	if db < VOLCAN_R:
		var a: float = atan2(z - BUTTE.y, x - BUTTE.x)
		var crete: float = CRATERE_Y + sin(a * 2.0 + 0.7) * 3.2 + sin(a * 5.0 + 2.1) * 1.4
		var u: float = clampf((db - CRATERE_R) / (VOLCAN_R - CRATERE_R), 0.0, 1.0)
		var vh: float = SOL + (crete - SOL) * pow(1.0 - u, 1.9)
		# les ravines du flanc
		var milieu: float = sin(u * PI)
		vh -= (0.5 + 0.5 * sin(a * 11.0 + _noise.get_noise_2d(x * 3.0, z * 3.0) * 4.0)) * 3.2 * milieu
		vh += _noise2.get_noise_2d(x * 1.5, z * 1.5) * 1.5 * milieu
		if db < CRATERE_R:
			vh = lerpf(LAVE_Y, crete, pow(smoothstep(22.0, CRATERE_R, db), 1.3))
			if db < ILOT_R + 2.5:
				vh = lerpf(BUTTE_Y, LAVE_Y, smoothstep(ILOT_R, ILOT_R + 2.5, db))
		h = lerpf(h, maxf(h, vh), smoothstep(-4.0, 8.0, inland))
		# la Brèche : l'allée monte au cratère par une gorge taillée dans le flanc
		var pts: Array = ALLEES[2][0]
		var dg: float = _dist_ligne(p, pts)
		if dg < 16.0:
			var sentier: float = lerpf(BUTTE_Y, SOL, smoothstep(ILOT_R, VOLCAN_R - 6.0, db))
			if dg < 2.8:
				h = sentier
			else:
				h = minf(h, sentier + (dg - 2.8) * 2.4)
		# la coulée : un lit creusé dans le flanc
		var dc: float = _dist_ligne(p, COULEE)
		h -= 1.3 * (1.0 - smoothstep(2.0, 5.5, dc)) * smoothstep(-6.0, 4.0, inland)
	# l'arête de la Faille
	var df: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, FAILLE_A, FAILLE_B))
	if df < 32.0:
		var arete: float = FAILLE_Y + _noise2.get_noise_2d(x * 2.0, z * 2.0) * 2.4 + _noise.get_noise_2d(x * 4.0, z * 4.0) * 1.6
		h = lerpf(h, maxf(h, arete), 1.0 - smoothstep(13.0, 30.0, df + _noise2.get_noise_2d(x * 3.0, z * 3.0 + 40.0) * 5.0))
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
		for dz in range(-4, 5):
			for dx in range(-4, 5):
				var xi: int = cx + dx
				var zi: int = cz + dz
				if xi < 0 or zi < 0 or xi >= count or zi >= count:
					continue
				var dist: float = Vector2(-HALF + xi * CELL - p.x, -HALF + zi * CELL - p.z).length()
				# V213 : des parois raides (la voie fend la roche : on la voit défiler)
				var plafond: float = p.y - 2.2 + maxf(dist - 3.2, 0.0) * 2.6
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


## R : la terre battue (le bord des allées) ; G : la lave (V213 : le cratère, la coulée, le fond de la
## Faille) ; B : la mousse rase (V213 : par plaques sur l'esplanade) ; A : les dalles.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / float(BIOME_RES - 1)
	for zi in range(BIOME_RES):
		var z: float = -HALF + zi * px
		for xi in range(BIOME_RES):
			var x: float = -HALF + xi * px
			var al: Vector2 = allee_at(x, z)
			var pave: float = 1.0 - smoothstep(al.y - 0.6, al.y + 0.6, al.x)
			# V213 : dans la Brèche, les dalles ne montent pas sur les parois
			if Vector2(x, z).distance_to(BUTTE) < VOLCAN_R:
				pave = 1.0 - smoothstep(2.0, 2.8, al.x)
			pave = maxf(pave, 1.0 - smoothstep(PLACE_R - 1.0, PLACE_R + 1.0, Vector2(x, z).distance_to(PLACE)))
			pave = maxf(pave, 1.0 - smoothstep(13.0, 15.0, Vector2(x, z).distance_to(ENTREE)))
			var dirt: float = (1.0 - smoothstep(al.y + 0.5, al.y + 3.0, al.x)) * 0.6 * (1.0 - pave)
			var db: float = Vector2(x, z).distance_to(BUTTE)
			var pp := Vector2(x, z)
			var lave: float = 0.0
			if db < CRATERE_R:
				lave = smoothstep(ILOT_R + 1.5, ILOT_R + 3.5, db) * (1.0 - smoothstep(22.5, 25.5, db)) * smoothstep(3.0, 5.0, _dist_ligne(pp, ALLEES[2][0]))
			lave = maxf(lave, 1.0 - smoothstep(1.6, 4.4, _dist_ligne(pp, COULEE)))
			if z < FAILLE_A.y + 2.0 and z > FAILLE_B.y - 4.0:
				lave = maxf(lave, 1.0 - smoothstep(1.4, 3.6, absf(x - FAILLE_A.x)))
			var mousse: float = (1.0 - lave) * smoothstep(VOLCAN_R * 0.8, VOLCAN_R * 1.1, db) * (0.55 + 0.45 * _noise.get_noise_2d(x * 2.0, z * 2.0))
			biome.set_pixel(xi, zi, Color(clampf(dirt, 0.0, 1.0), clampf(lave, 0.0, 1.0), clampf(mousse, 0.0, 1.0), clampf(pave, 0.0, 1.0)))


func _build_mesh() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/volcan_sol_v213.gdshader")
	# V213 : la cendre, la mousse rase, le basalte, le sable noir, les pavés de basalte, la croûte de lave
	var S := "res://assets/textures/montjoie/"
	var BR := "res://assets/textures/braise/"
	for paire in [["prairie", BR + "cendre"], ["chemin", S + "chemin"], ["sous_bois", BR + "mousse_braise"], ["roche_crocs", BR + "basalte"],
			["sable_lac", BR + "sable_noir"], ["paves", BR + "paves_basalte"]]:
		if ResourceLoader.exists(str(paire[1]) + ".png"):
			mat.set_shader_parameter(str(paire[0]) + "_tex", load(str(paire[1]) + ".png"))
		if ResourceLoader.exists(str(paire[1]) + "_n.png"):
			mat.set_shader_parameter(str(paire[0]) + "_n", load(str(paire[1]) + "_n.png"))
	mat.set_shader_parameter("lave_tex", load(BR + "lave_croute.png"))
	mat.set_shader_parameter("lave_e", load(BR + "lave_croute_e.png"))
	mat.set_shader_parameter("volcan", Vector3(CENTER.x + BUTTE.x, CENTER.z + BUTTE.y, VOLCAN_R))
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

extends Node3D
## V142 : le relief de l'Île des Géants, au sud-est de l'archipel (au sud de l'Île Crayonnée). Une
## campagne de conte, à l'échelle des géants : des collines vertes et rondes, la ferme des Grandpré sur
## son large plateau (la maison, la grange, la cour, le potager aux sillons larges comme des fossés),
## la butte du moulin au nord-ouest, la mare aux nénuphars au sud-ouest, le verger et le champ de blé
## au sud, une grève de sable au nord, où les géants ont bâti un ponton à la taille des visiteurs.
## Le sol est peint par le shader geants_sol_v142 d'après une carte des sols (voir _bake_biome).
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).

const CENTER := Vector3(800.0, 0.0, 2100.0)
const HALF: float = 300.0
const CELL: float = 2.0
const CHUNKS: int = 6
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint celui de l'Île Crayonnée (au nord-est)
const SEA_R: float = 420.0
## Le bord de l'île (un cercle bosselé)
const RS: float = 228.0
## L'agrandissement du monde des géants (un géant de 1,75 m « chez lui » mesure 13 m)
const G: float = 7.5
## Le plateau de la ferme : plat jusqu'à R0, rejoint les collines à R1
const PLATEAU := Vector2(30.0, 0.0)
const PLATEAU_R0: float = 112.0
const PLATEAU_R1: float = 165.0
const PLATEAU_Y: float = 9.0
## La maison des Grandpré (rectangle ; la façade et la porte au nord) : centre, demi-tailles
const MAISON := Vector2(0.0, 0.0)
const MAISON_H := Vector2(42.0, 28.0)
## La grange (à l'ouest de la maison ; ses grandes portes au nord)
const GRANGE := Vector2(-98.0, 4.0)
const GRANGE_H := Vector2(28.0, 19.0)
## La cour de terre battue, devant la maison (x0, z0, x1, z1)
const COUR := [-75.0, -78.0, 58.0, -28.0]
const PUITS := Vector2(-36.0, -56.0)
## Le potager, à l'est de la maison : la clôture (x0, z0, x1, z1) ; quatre planches et leurs allées
const POTAGER := [62.0, -52.0, 152.0, 52.0]
const PLANCHES := {
	"choux": [67.0, -47.0, 103.0, -5.0], "poireaux": [111.0, -47.0, 147.0, -5.0],
	"citrouilles": [67.0, 5.0, 103.0, 47.0], "tomates": [111.0, 5.0, 147.0, 47.0],
}
## Les sillons : une butte tous les 4 m (le long de z), 0,45 m plus haute que le fond du sillon
const SILLON: float = 4.0
## La porte du potager (à l'ouest, vers la cour)
const PORTE_POTAGER := Vector2(62.0, -40.0)
## Le verger (au sud-est) et le champ de blé (au sud)
const VERGER := Vector2(110.0, 120.0)
const VERGER_R: float = 58.0
const BLE := [-28.0, 66.0, 44.0, 136.0]
## La butte du moulin (au nord-ouest) : le sommet plat (R0), le pied (R1)
const MOULIN := Vector2(-150.0, -100.0)
const MOULIN_Y: float = 24.0
const MOULIN_R0: float = 22.0
const MOULIN_R1: float = 92.0
## La mare aux nénuphars (au sud-ouest) : centre, demi-axes, niveau de l'eau
const MARE := Vector2(-112.0, 128.0)
const MARE_AX := Vector2(36.0, 24.0)
const MARE_Y: float = 5.0
## La corde à linge (deux grands poteaux, entre la grange et la maison, au sud)
const LINGE_A := Vector2(-66.0, 40.0)
const LINGE_B := Vector2(-30.0, 52.0)
## Le château de sable de Pâquerette, sur la grève (à l'est du ponton)
const CHATEAU_SABLE := Vector2(92.0, -196.0)
## Le ponton (au nord, face à l'archipel)
const DOCK_A := Vector2(36.0, -224.0)
const DOCK_B := Vector2(36.0, -250.0)
## Les chemins de terre battue (polylignes, repère île) et leur demi-largeur
const CHEMINS := [
	[[[36.0, -220.0], [34.0, -190.0], [24.0, -152.0], [12.0, -116.0], [4.0, -86.0], [2.0, -74.0]], 5.0],     # du ponton à la cour
	[[[-46.0, -74.0], [-80.0, -86.0], [-110.0, -96.0], [-131.0, -100.0]], 4.0],                             # de la cour au moulin
	[[[50.0, -46.0], [62.0, -40.0]], 4.0],                                                                   # de la cour au potager
	[[[-75.0, -48.0], [-120.0, -30.0], [-142.0, 20.0], [-138.0, 70.0], [-124.0, 100.0]], 3.6],              # de la grange à la mare
	[[[46.0, 30.0], [58.0, 62.0], [80.0, 92.0], [96.0, 108.0]], 3.6],                                        # derrière la maison, au verger
	[[[-10.0, 30.0], [-6.0, 62.0]], 3.4],                                                                    # au champ de blé
]
## Les murets de pierres sèches (segments, repère île)
const MURETS := [
	[[-205.0, -40.0], [-168.0, 20.0], [-150.0, 82.0]],
	[[160.0, -120.0], [182.0, -60.0], [186.0, 10.0]],
]

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


# =================================================================== les lieux

static func in_rect(r: Array, x: float, z: float, m: float = 0.0) -> bool:
	return x > float(r[0]) - m and x < float(r[2]) + m and z > float(r[1]) - m and z < float(r[3]) + m


static func in_maison(x: float, z: float, m: float = 0.0) -> bool:
	return absf(x - MAISON.x) < MAISON_H.x + m and absf(z - MAISON.y) < MAISON_H.y + m


static func in_grange(x: float, z: float, m: float = 0.0) -> bool:
	return absf(x - GRANGE.x) < GRANGE_H.x + m and absf(z - GRANGE.y) < GRANGE_H.y + m


## La planche du potager sous un point (« » : aucune)
static func planche_at(x: float, z: float, m: float = 0.0) -> String:
	for k in PLANCHES:
		if in_rect(PLANCHES[k], x, z, m):
			return str(k)
	return ""


## 0 au centre de la mare, 1 sur la rive
static func mare_q(x: float, z: float) -> float:
	return Vector2((x - MARE.x) / MARE_AX.x, (z - MARE.y) / MARE_AX.y).length()


static func in_mare_water(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return mare_q(l.x, l.y) < 0.97


## La distance (m) au chemin le plus proche, et sa demi-largeur : Vector2(distance, demi-largeur)
static func chemin_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	for c in CHEMINS:
		var pts: Array = c[0]
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
			var d: float = p.distance_to(q)
			if d - float(c[1]) < best.x - best.y:
				best = Vector2(d, float(c[1]))
	return best


# =================================================================== relief

func _init() -> void:
	_noise.seed = 14201
	_noise.frequency = 0.0065
	_noise.fractal_octaves = 3
	_noise2.seed = 14202
	_noise2.frequency = 0.035
	_noise2.fractal_octaves = 2


## 1 sur le bord de l'île, moins de 1 dessus
func coast_q(x: float, z: float) -> float:
	var r: float = Vector2(x, z).length()
	var a: float = atan2(z, x)
	var bump: float = sin(a * 3.0 + 0.4) * 12.0 + sin(a * 7.0 + 1.9) * 6.0 + sin(a * 13.0 + 0.3) * 2.5
	# la grève du nord (le ponton) : un rivage plus régulier
	if z < -120.0 and absf(x - DOCK_A.x) < 70.0:
		bump *= smoothstep(25.0, 70.0, absf(x - DOCK_A.x))
	return r / (RS + bump)


func build(_high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	for zi in range(count):
		var lz: float = -HALF + zi * CELL
		for xi in range(count):
			heights[zi * count + xi] = _shape(-HALF + xi * CELL, lz)
	_bake_biome()
	_build_mesh()
	_build_collision()
	print("ILE_MANGA_V142: l'Île des Géants ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


## Les collines (sans le plateau, la butte, la mare) : des bosses douces et des creux
func _collines(x: float, z: float) -> float:
	var h: float = 4.0 + _noise.get_noise_2d(x, z) * 4.5
	for b in [[Vector2(168.0, -64.0), 76.0, 13.0], [Vector2(64.0, 178.0), 64.0, 7.0], [Vector2(-170.0, 58.0), 60.0, 6.0],
			[Vector2(-40.0, -170.0), 55.0, 3.0], [Vector2(150.0, 110.0), 50.0, 5.0]]:
		var d: float = Vector2(x, z).distance_to(b[0])
		h += float(b[2]) * exp(-pow(d / float(b[1]), 2.0) * 1.6)
	return h


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var h: float
	if q <= 1.0:
		var inland: float = (1.0 - q) * RS
		h = lerpf(0.5, 2.6, smoothstep(0.0, 18.0, inland))
		var land: float = _collines(x, z)
		h = lerpf(h, maxf(land, 2.6), smoothstep(8.0, 46.0, inland))
	else:
		var off: float = (q - 1.0) * RS
		if off < 16.0:
			h = lerpf(0.5, -1.4, smoothstep(0.0, 16.0, off))
		else:
			h = maxf(-1.4 - 30.0 * smoothstep(16.0, 52.0, off), -32.0)
		return h
	# la butte du moulin
	var dm: float = Vector2(x, z).distance_to(MOULIN)
	if dm < MOULIN_R1:
		var k: float = smoothstep(MOULIN_R1, MOULIN_R0, dm)
		var rough: float = _noise2.get_noise_2d(x, z) * 1.6 * k * (1.0 - k) * 4.0
		h = lerpf(h, MOULIN_Y, pow(k, 1.25)) + rough
	# le plateau de la ferme
	var dp: float = Vector2(x, z).distance_to(PLATEAU)
	if dp < PLATEAU_R1:
		h = lerpf(h, PLATEAU_Y, smoothstep(PLATEAU_R1, PLATEAU_R0, dp))
	# la mare : une cuvette ; des rives plus hautes que l'eau
	var mq: float = mare_q(x, z)
	if mq < 1.9:
		var rive: float = maxf(h, MARE_Y + 0.7)
		var bank: float = lerpf(rive, h, smoothstep(1.2, 1.9, mq))
		h = lerpf(MARE_Y - 2.4, bank, smoothstep(0.35, 1.08, mq))
	# le potager : les sillons (les buttes le long de z, une tous les 4 m)
	if PLATEAU.distance_to(Vector2(x, z)) < PLATEAU_R0:
		var pl: String = planche_at(x, z)
		if pl != "" and pl != "citrouilles":
			var r: Array = PLANCHES[pl]
			var edge: float = minf(minf(x - float(r[0]), float(r[2]) - x), minf(z - float(r[1]), float(r[3]) - z))
			var ridge: float = 0.5 + 0.5 * cos(TAU * (x - float(r[0]) - SILLON * 0.5) / SILLON)
			h += (0.15 + 0.5 * ridge) * smoothstep(0.0, 2.5, edge)
		elif pl == "citrouilles":
			h += 0.25
		elif in_rect(BLE, x, z):
			h += 0.15 + _noise2.get_noise_2d(x * 2.0, z * 2.0) * 0.08
	# les chemins : un peu creusés
	var ch: Vector2 = chemin_at(x, z)
	if ch.x < ch.y + 2.0:
		h -= 0.28 * (1.0 - smoothstep(ch.y - 1.0, ch.y + 2.0, ch.x))
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


## La hauteur du sol en un point du repère île
func height_l(x: float, z: float) -> float:
	return height(CENTER.x + x, CENTER.z + z)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== la carte des sols

## R : la terre battue (chemins, cour, allées du potager, autour de la grange) ; G : la terre
## labourée (les planches, le champ de blé) ; B : le sous-bois du verger ; A : les grandes dalles
## autour de la maison et du puits.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / float(BIOME_RES - 1)
	for zi in range(BIOME_RES):
		var z: float = -HALF + zi * px
		for xi in range(BIOME_RES):
			var x: float = -HALF + xi * px
			var dirt: float = 0.0
			var field: float = 0.0
			var forest: float = 0.0
			var pave: float = 0.0
			var ch: Vector2 = chemin_at(x, z)
			dirt = 1.0 - smoothstep(ch.y - 1.5, ch.y + 1.0, ch.x)
			if in_rect(COUR, x, z, 2.0):
				var e: float = minf(minf(x - float(COUR[0]), float(COUR[2]) - x), minf(z - float(COUR[1]), float(COUR[3]) - z))
				dirt = maxf(dirt, smoothstep(-2.0, 6.0, e) * (0.75 + 0.25 * _noise2.get_noise_2d(x * 3.0, z * 3.0)))
			if in_grange(x, z, 9.0):
				dirt = maxf(dirt, 0.85)
			if in_rect(POTAGER, x, z, 1.0):
				dirt = maxf(dirt, 0.8)
			var pl: String = planche_at(x, z, 0.5)
			if pl != "":
				field = 1.0
				dirt = 0.0
			if in_rect(BLE, x, z, 1.0):
				field = maxf(field, 0.85)
			var dv: float = Vector2(x, z).distance_to(VERGER)
			if dv < VERGER_R + 8.0:
				forest = (1.0 - smoothstep(VERGER_R - 12.0, VERGER_R + 8.0, dv)) * (0.55 + 0.25 * _noise2.get_noise_2d(x * 2.0, z * 2.0))
			if in_maison(x, z, 5.0) and not in_maison(x, z, -1.0):
				pave = 1.0
			if Vector2(x, z).distance_to(PUITS) < 9.0:
				pave = maxf(pave, 1.0 - smoothstep(6.0, 9.0, Vector2(x, z).distance_to(PUITS)))
			# le seuil de la porte : une grande dalle devant la maison
			if absf(x - MAISON.x) < 12.0 and z < -MAISON_H.y and z > -MAISON_H.y - 10.0:
				pave = 1.0
			biome.set_pixel(xi, zi, Color(clampf(dirt, 0.0, 1.0), field, clampf(forest, 0.0, 1.0), pave))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var px: float = HALF * 2.0 / float(BIOME_RES - 1)
	var xi: int = clampi(int(round((l.x + HALF) / px)), 0, BIOME_RES - 1)
	var zi: int = clampi(int(round((l.y + HALF) / px)), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


# =================================================================== maillage, collision

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
	var mw: Vector3 = W(MARE.x, MARE.y)
	mat.set_shader_parameter("lake", Vector4(mw.x, mw.z, MARE_AX.x, MARE_AX.y))
	mat.set_shader_parameter("lake_y", MARE_Y)
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
			mi.name = "Geants_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_geants_v142"
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

extends Node3D
## Extension « Le Château d'Ombrelac » : le relief de l'île d'Ombrelac, tout au nord de l'archipel
## (au nord de l'Île aux Moaïs). Une île de montagnes, de forêts et de falaises : au nord, la crête
## des Monts Gris ; au milieu, le Lac d'Ombre, sombre et profond ; sur la rive est du lac, le Roc
## d'Ombrelac, un grand éperon de roche aux falaises à pic, et tout en haut, l'Académie, le
## château géant ; au sud, la gorge du Torrent (le lac se vide dans la mer par elle), la Colline du
## Guet et la route qui monte depuis le débarcadère, puis le grand viaduc jusqu'à la porte.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Le sol est peint par le shader du sol des Géants (V142), dont on reprend la carte des sols.

const CENTER := Vector3(-30.0, 0.0, -1460.0)
const HALF: float = 400.0
const CELL: float = 2.0
const CHUNKS: int = 8
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint celui de l'Île aux Moaïs (au sud)
const SEA_R: float = 470.0
## Le bord de l'île (un cercle bosselé)
const RS: float = 330.0

## Le Lac d'Ombre : centre, demi-axes, niveau de l'eau, fond
const LAC := Vector2(-110.0, -40.0)
const LAC_AX := Vector2(130.0, 100.0)
const LAC_Y: float = 3.0
const LAC_FOND: float = -14.0

## Le Roc d'Ombrelac (le plateau du château) : centre, rayon du plateau, pied de la falaise, hauteur
const ROC := Vector2(80.0, 20.0)
const ROC_R0: float = 82.0
const ROC_R1: float = 104.0
const ROC_Y: float = 52.0

## L'Aiguille : le pic dans le lac, au bout du pont couvert (la Tour des Vents)
const AIGUILLE := Vector2(-48.0, -64.0)
const AIGUILLE_R: float = 17.0
const AIGUILLE_Y: float = 36.0

## La Colline du Guet, au sud de la gorge : le bout du viaduc
const GUET := Vector2(80.0, 214.0)
const GUET_R0: float = 26.0
const GUET_R1: float = 80.0
const GUET_Y: float = 42.0

## La gorge du Torrent : [x, z, hauteur du lit]
const GORGE := [[-52.0, 48.0, 2.6], [10.0, 128.0, 2.2], [80.0, 150.0, 1.6], [160.0, 148.0, 1.0], [240.0, 128.0, 0.4], [330.0, 140.0, -1.2], [380.0, 150.0, -4.0]]
const GORGE_W: float = 11.0          # demi-largeur du lit
const GORGE_E: float = 34.0          # demi-largeur au bord des falaises

## Les Monts Gris : [x, z, rayon, hauteur]
const MONTS := [[-190.0, -235.0, 110.0, 92.0], [10.0, -265.0, 120.0, 118.0], [185.0, -215.0, 100.0, 84.0],
	[-280.0, -100.0, 80.0, 52.0], [270.0, -70.0, 75.0, 46.0], [120.0, -150.0, 55.0, 30.0], [-260.0, 120.0, 70.0, 26.0]]

## Le débarcadère, au sud
const DOCK_A := Vector2(20.0, 316.0)
const DOCK_B := Vector2(20.0, 346.0)

## Le viaduc : de la Colline du Guet (sud) à la porte du château (nord)
const VIADUC_S := Vector3(80.0, GUET_Y, 192.0)
const VIADUC_N := Vector3(80.0, ROC_Y, 98.0)

## La route : [x, z, hauteur], du débarcadère au sommet du Guet
const ROUTE := [[20.0, 318.0, 1.4], [20.0, 298.0, 4.5], [-6.0, 282.0, 9.0], [-34.0, 266.0, 13.5], [-28.0, 248.0, 17.5],
	[10.0, 240.0, 23.0], [40.0, 236.0, 29.0], [62.0, 228.0, 35.0], [80.0, 212.0, GUET_Y], [80.0, 192.0, GUET_Y]]
const ROUTE_W: float = 3.6

## Les sentiers (sans hauteur imposée) : [[points], demi-largeur]
const SENTIERS := [
	[[[-34.0, 266.0], [-90.0, 230.0], [-150.0, 170.0], [-170.0, 90.0]], 1.8],      # vers la rive sud du lac
	[[[20.0, 298.0], [110.0, 300.0], [190.0, 262.0]], 1.6],                         # le long de la côte
]

const BIOME_RES: int = 401

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image
var ground_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()
var _rock := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


# =================================================================== les lieux

## 0 au centre du lac, 1 sur la rive
static func lac_q(x: float, z: float) -> float:
	return Vector2((x - LAC.x) / LAC_AX.x, (z - LAC.y) / LAC_AX.y).length()


static func in_lac_water(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return lac_q(l.x, l.y) < 0.98 and l.distance_to(ROC) > ROC_R1 - 6.0 and l.distance_to(AIGUILLE) > AIGUILLE_R + 4.0


## La distance au lit de la gorge, et la hauteur du lit à cet endroit : Vector2(distance, hauteur)
static func gorge_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	for i in range(GORGE.size() - 1):
		var a := Vector2(float(GORGE[i][0]), float(GORGE[i][1]))
		var b := Vector2(float(GORGE[i + 1][0]), float(GORGE[i + 1][1]))
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d: float = p.distance_to(a + ab * t)
		if d < best.x:
			best = Vector2(d, lerpf(float(GORGE[i][2]), float(GORGE[i + 1][2]), t))
	return best


## La distance à la route, et sa hauteur au point le plus proche : Vector2(distance, hauteur)
static func route_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	for i in range(ROUTE.size() - 1):
		var a := Vector2(float(ROUTE[i][0]), float(ROUTE[i][1]))
		var b := Vector2(float(ROUTE[i + 1][0]), float(ROUTE[i + 1][1]))
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d: float = p.distance_to(a + ab * t)
		if d < best.x:
			best = Vector2(d, lerpf(float(ROUTE[i][2]), float(ROUTE[i + 1][2]), t))
	return best


## La distance au sentier le plus proche, et sa demi-largeur : Vector2(distance, demi-largeur)
static func sentier_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	for c in SENTIERS:
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
	_noise.seed = 18801
	_noise.frequency = 0.006
	_noise.fractal_octaves = 4
	_noise2.seed = 18802
	_noise2.frequency = 0.03
	_noise2.fractal_octaves = 3
	_rock.seed = 18803
	_rock.frequency = 0.045
	_rock.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_rock.fractal_octaves = 3


## 1 sur le bord de l'île, moins de 1 dessus
func coast_q(x: float, z: float) -> float:
	var r: float = Vector2(x, z).length()
	var a: float = atan2(z, x)
	var bump: float = sin(a * 3.0 + 1.1) * 16.0 + sin(a * 7.0 + 0.4) * 8.0 + sin(a * 15.0 + 2.2) * 3.0
	# la crique du débarcadère : un rivage plus régulier
	if z > 200.0 and absf(x - DOCK_A.x) < 80.0:
		bump *= smoothstep(30.0, 80.0, absf(x - DOCK_A.x))
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
	print("OMBRELAC: le relief de l'île ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


## Les collines et les montagnes (sans le lac, le roc, la gorge)
func _terres(x: float, z: float) -> float:
	var h: float = 7.0 + _noise.get_noise_2d(x, z) * 6.0
	for m in MONTS:
		var d: float = Vector2(x, z).distance_to(Vector2(float(m[0]), float(m[1])))
		var k: float = exp(-pow(d / float(m[2]), 2.0) * 1.5)
		h += float(m[3]) * k
		# des arêtes rocheuses sur les flancs
		h += absf(_rock.get_noise_2d(x, z)) * 14.0 * k * (1.0 - k) * 2.0
	return h


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var h: float
	if q <= 1.0:
		var inland: float = (1.0 - q) * RS
		h = lerpf(0.4, 2.4, smoothstep(0.0, 16.0, inland))
		var land: float = _terres(x, z)
		h = lerpf(h, maxf(land, 2.4), smoothstep(6.0, 50.0, inland))
	else:
		var off: float = (q - 1.0) * RS
		if off < 14.0:
			h = lerpf(0.4, -1.6, smoothstep(0.0, 14.0, off))
		else:
			h = maxf(-1.6 - 30.0 * smoothstep(14.0, 60.0, off), -32.0)
		# la gorge continue un peu sous la mer
		var gm: Vector2 = gorge_at(x, z)
		if gm.x < GORGE_E:
			h = minf(h, lerpf(gm.y - 1.0, h, smoothstep(GORGE_W, GORGE_E, gm.x)))
		return h
	# la Colline du Guet
	var dg: float = Vector2(x, z).distance_to(GUET)
	if dg < GUET_R1:
		h = lerpf(h, GUET_Y, pow(smoothstep(GUET_R1, GUET_R0, dg), 1.4))
	# le Lac d'Ombre : une cuvette profonde, des rives un peu plus hautes que l'eau
	var lq: float = lac_q(x, z)
	if lq < 1.6:
		var rive: float = maxf(h, LAC_Y + 0.8)
		var bank: float = lerpf(rive, h, smoothstep(1.15, 1.6, lq))
		h = lerpf(LAC_FOND, bank, smoothstep(0.55, 1.05, lq))
	# la gorge du Torrent : un lit, des parois raides
	var g: Vector2 = gorge_at(x, z)
	if g.x < GORGE_E:
		var wall: float = smoothstep(GORGE_W, GORGE_E, g.x + _noise2.get_noise_2d(x, z) * 4.0)
		var bed: float = g.y - 1.6 * (1.0 - smoothstep(0.0, GORGE_W, g.x))
		h = lerpf(bed, h, pow(wall, 0.6))
	# le Roc d'Ombrelac : le plateau du château, des falaises à pic (dans le lac à l'ouest)
	var dr: float = Vector2(x, z).distance_to(ROC)
	# le contour du roc : des éperons, des ravines (la bande des falaises s'élargit et se resserre)
	var ang: float = atan2(z - ROC.y, x - ROC.x)
	var wob: float = sin(ang * 3.0 + 1.0) * 7.0 + sin(ang * 5.0 + 2.3) * 5.0 + sin(ang * 11.0 + 0.4) * 3.0 + _noise2.get_noise_2d(x * 0.7, z * 0.7) * 6.0
	# au sud, la gorge du Torrent passe au pied du roc : la falaise y reste droite
	var sud: float = smoothstep(0.35, 0.9, sin(ang))
	wob *= 1.0 - 0.5 * sud
	var r1: float = ROC_R1 + wob * 1.6 + 6.0 * (1.0 - sud)
	var r0: float = ROC_R0 + maxf(wob, 0.0) * 0.4
	if dr < ROC_R1 + 50.0:
		var k: float = clampf((r1 - dr) / (r1 - r0), 0.0, 1.0)
		# un à-pic : presque toute la hauteur sur la moitié extérieure de la bande ; des ressauts
		# (les strates de la roche), une corniche en haut
		var prof: float = smoothstep(0.0, 0.62, k)
		var t6: float = prof * 7.0
		var strates: float = (floor(t6) + smoothstep(0.15, 0.85, t6 - floor(t6))) / 7.0
		prof = lerpf(prof, strates, 0.55)
		var cliff: float = lerpf(h, ROC_Y, prof)
		# la roche des falaises : des fissures, des éperons
		cliff -= absf(_rock.get_noise_2d(x * 1.4, z * 1.4)) * 9.0 * prof * (1.0 - prof) * 3.0
		# un talus d'éboulis au pied
		var talus: float = 1.0 - smoothstep(r1, r1 + 24.0, dr)
		h = maxf(cliff, lerpf(h, maxf(h, LAC_Y + 2.0) + 6.0 * talus, talus * 0.7))
		if dr < r0:
			h = ROC_Y
	# l'Aiguille : un pic de roche dans le lac
	var da: float = Vector2(x, z).distance_to(AIGUILLE)
	if da < AIGUILLE_R + 14.0:
		var ka: float = smoothstep(AIGUILLE_R + 14.0, AIGUILLE_R - 4.0, da)
		var pic: float = lerpf(h, AIGUILLE_Y, pow(ka, 0.5)) - absf(_rock.get_noise_2d(x * 2.0, z * 2.0)) * 5.0 * ka * (1.0 - ka) * 3.0
		h = maxf(h, pic)
		if da < AIGUILLE_R - 4.0:
			h = AIGUILLE_Y
	# la route : la chaussée suit sa propre pente (déblai et remblai sur les côtés)
	var r: Vector2 = route_at(x, z)
	if r.x < ROUTE_W + 14.0:
		h = lerpf(r.y, h, smoothstep(ROUTE_W, ROUTE_W + 14.0, r.x))
	# les sentiers : un peu creusés
	var s: Vector2 = sentier_at(x, z)
	if s.x < s.y + 2.0:
		h -= 0.22 * (1.0 - smoothstep(s.y - 1.0, s.y + 2.0, s.x))
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

## R : la terre battue (la route, les sentiers) ; G : (rien, les champs des Géants) ; B : le
## sous-bois (les forêts des Monts Gris et de la rive nord du lac) ; A : les dalles (le plateau du
## château, le haut du Guet, l'Aiguille).
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / float(BIOME_RES - 1)
	for zi in range(BIOME_RES):
		var z: float = -HALF + zi * px
		for xi in range(BIOME_RES):
			var x: float = -HALF + xi * px
			var r: Vector2 = route_at(x, z)
			var dirt: float = 1.0 - smoothstep(ROUTE_W - 0.5, ROUTE_W + 2.0, r.x + _noise2.get_noise_2d(x * 4.0, z * 4.0) * 0.8)
			var s: Vector2 = sentier_at(x, z)
			dirt = maxf(dirt, 1.0 - smoothstep(s.y - 1.2, s.y + 0.8, s.x))
			var forest: float = clampf(_noise.get_noise_2d(x * 1.7 + 40.0, z * 1.7) * 1.6 + 0.35, 0.0, 1.0)
			forest *= smoothstep(-40.0, -140.0, z) + smoothstep(140.0, 260.0, -x) * 0.7
			forest = clampf(forest, 0.0, 1.0)
			var pave: float = 0.0
			var dr: float = Vector2(x, z).distance_to(ROC)
			if dr < ROC_R0:
				pave = 0.55 + 0.35 * _noise2.get_noise_2d(x * 2.0, z * 2.0)
				forest = 0.0
			if Vector2(x, z).distance_to(GUET) < GUET_R0 - 4.0:
				pave = maxf(pave, 0.4)
			biome.set_pixel(xi, zi, Color(clampf(dirt, 0.0, 1.0), 0.0, forest, clampf(pave, 0.0, 1.0)))


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
	var lw: Vector3 = W(LAC.x, LAC.y)
	mat.set_shader_parameter("lake", Vector4(lw.x, lw.z, LAC_AX.x, LAC_AX.y))
	mat.set_shader_parameter("lake_y", LAC_Y)
	mat.set_shader_parameter("town", Vector4(CENTER.x + ROC.x, CENTER.z + ROC.y, ROC_R0, 0.0))
	mat.set_shader_parameter("extra_detail", true)
	mat.set_shader_parameter("water_level", WATER)
	mat.set_shader_parameter("gscale", 1.0)
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
			mi.name = "Ombrelac_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_ombrelac"
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

extends Node3D
## V67 : le relief d'Arcanelle, l'île des sorciers, au nord-ouest de l'archipel.
## Une île de lande et de schiste : une colline au milieu où se dresse l'Académie, un bourg sur
## une terrasse au sud-est (le ponton regarde le village), des falaises au nord battues par un
## vent glacé, un lac perché (le Lac Miroir) et son îlot, le Cercle des Pierres-Lunes sur
## l'épaule ouest, le Bois Tors au sud-ouest, un éperon de rocher au sud où penche une vieille
## tour en ruine.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles (ile_azur_v56.gd) : relief calculé une fois dans une
## grille ; maillage, collision et height() lisent la même grille.

const CENTER := Vector3(-300.0, 0.0, -480.0)
const HALF: float = 150.0
const CELL: float = 1.0
const CHUNKS: int = 6
const WATER: float = -0.42
const TEX := "res://assets/textures/arcanelle/"

## Les terre-pleins : nom -> [x, z, rayon plat, hauteur, longueur de la pente]
const PADS := {
	"academie": [-10.0, -10.0, 17.0, 17.0, 50.0],
	"observatoire": [-34.0, -46.0, 7.5, 22.0, 24.0],
	"cercle": [-64.0, -4.0, 11.0, 13.0, 28.0],
	"bibliotheque": [12.0, 12.0, 11.0, 11.0, 18.0],
	"crypte": [-36.0, 24.0, 6.5, 10.0, 18.0],
	"jardin": [0.0, 46.0, 11.0, 6.0, 18.0],
	"aire": [58.0, 0.0, 13.0, 6.5, 20.0],
	"tour": [-20.0, 84.0, 6.0, 12.0, 11.0],
	"sauge": [14.0, 56.0, 6.0, 5.5, 10.0],
	"boree": [2.0, -34.0, 6.0, 14.0, 14.0],
	"zephyrine": [-6.0, 70.0, 5.5, 7.5, 10.0],
	"pyra": [72.0, 14.0, 5.5, 5.5, 10.0],
	"ysolde": [-54.0, 14.0, 5.5, 11.0, 12.0],
	"agathe": [-44.0, 52.0, 5.0, 7.0, 10.0],
}
## Le bourg : une terrasse en pente douce (x0, z0, x1, z1) et sa hauteur.
const TOWN := Rect2(22.0, 24.0, 50.0, 40.0)
## Le Lac Miroir : centre, rayon de l'eau, rayon du rebord, niveau de l'eau, fond ; l'îlot.
const LAKE := Vector2(26.0, -50.0)
const LAKE_R: float = 15.0
const LAKE_RIM: float = 21.0
const LAKE_Y: float = 9.3
const LAKE_FLOOR: float = 7.0
const ISLET := Vector2(31.0, -55.5)
const ISLET_R: float = 3.0
const ISLET_Y: float = 9.95
## Sous les salles où l'on entre, le sol ne dépasse pas le plancher : [x0, z0, x1, z1, y].
const CUTS := [[39.6, 24.6, 52.4, 35.4, 5.6]]
## Le ponton (de la grève vers le large, au sud-est).
const DOCK_A := Vector2(77.0, 70.0)
const DOCK_B := Vector2(91.0, 84.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"quai": [Vector2(79.0, 72.0), Vector2(70.0, 62.0)],
	"montee": [Vector2(28.0, 30.0), Vector2(22.0, 22.0), Vector2(14.0, 12.0)],
	"academie": [Vector2(14.0, 12.0), Vector2(26.0, 2.0), Vector2(14.0, -6.0), Vector2(2.0, -6.0)],
	"observatoire": [Vector2(-18.0, -24.0), Vector2(-24.0, -34.0), Vector2(-32.0, -42.0)],
	"cercle": [Vector2(-26.0, -6.0), Vector2(-40.0, -2.0), Vector2(-54.0, -4.0)],
	"jardin": [Vector2(30.0, 48.0), Vector2(18.0, 48.0), Vector2(8.0, 46.0)],
	"crypte": [Vector2(-8.0, 40.0), Vector2(-22.0, 32.0), Vector2(-31.0, 26.0)],
	"tour": [Vector2(-4.0, 55.0), Vector2(-8.0, 64.0), Vector2(-14.0, 74.0), Vector2(-18.0, 79.0)],
	"aire": [Vector2(60.0, 26.0), Vector2(60.0, 18.0), Vector2(58.0, 10.0)],
	"lac": [Vector2(48.0, -8.0), Vector2(40.0, -22.0), Vector2(33.0, -34.0)],
	"bois": [Vector2(-40.0, 30.0), Vector2(-48.0, 40.0), Vector2(-56.0, 48.0)],
	"boree": [Vector2(14.0, -6.0), Vector2(10.0, -20.0), Vector2(4.0, -30.0)],
	"ysolde": [Vector2(-48.0, -2.0), Vector2(-52.0, 8.0)],
	"zephyrine": [Vector2(-8.0, 64.0), Vector2(-6.0, 66.0)],
	"agathe": [Vector2(-48.0, 40.0), Vector2(-45.0, 48.0)],
	"sauge": [Vector2(8.0, 50.0), Vector2(12.0, 53.0)],
	"pyra": [Vector2(64.0, 8.0), Vector2(70.0, 12.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func town_y(x: float, z: float) -> float:
	var cx: float = clampf(x, TOWN.position.x, TOWN.end.x)
	var cz: float = clampf(z, TOWN.position.y, TOWN.end.y)
	return 3.4 + 0.045 * (TOWN.end.x - cx) + 0.035 * (TOWN.end.y - cz)


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


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
		_flatten(w.x, w.z, float(p[2]), float(p[2]) + 3.0, float(p[3]))
		pads_world[k] = Vector3(w.x, float(p[3]), w.z)
	_flatten_town()
	_lake()
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	# les talus des chemins ne mordent pas sur les terre-pleins
	for k3 in PADS:
		var p3: Array = PADS[k3]
		var w3: Vector3 = W(float(p3[0]), float(p3[1]))
		_flatten(w3.x, w3.z, float(p3[2]) - 0.5, float(p3[2]) + 1.0, float(p3[3]))
	for c in CUTS:
		_cut(c)
	# les dalles des chemins suivent le sol tel qu'il est au bout du compte
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V67: île d'Arcanelle ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 6701
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.014
	_detail.seed = 6702
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail.fractal_octaves = 3
	_detail.frequency = 0.05
	_coast.seed = 6703
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 112.0)
	var az: float = absf((z - 2.0) / 104.0)
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.05) + pow(az, 2.05), 1.0 / 2.05)
	# des anses et des pointes ; plus sage du côté du bourg et du ponton (sud-est)
	var calm: float = 1.0 - 0.75 * exp(-pow(wrapf(theta - 0.75, -PI, PI) / 0.5, 2.0))
	var wob: float = 0.15 * _coast.get_noise_2d(cos(theta) * 1.6, sin(theta) * 1.6) + 0.06 * _coast.get_noise_2d(cos(theta) * 5.0 + 9.0, sin(theta) * 5.0) + 0.035 * sin(theta * 5.0 + 0.7)
	# l'anse de l'ouest, sous le Cercle, et la pointe du nord-est
	wob += 0.09 * exp(-pow(wrapf(theta - 2.75, -PI, PI) / 0.22, 2.0)) - 0.07 * exp(-pow(wrapf(theta + 0.75, -PI, PI) / 0.25, 2.0))
	return q * (1.0 + wob * calm)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.9, q) * 1.6
	else:
		coast = WATER + 0.35 - (q - 1.0) * 105.0 * 0.38
	coast = maxf(coast, -46.0)
	var inland: float = smoothstep(0.98, 0.7, q)
	# la colline de l'Académie, et chaque lieu sur son terre-plein (« la terre monte vers eux »)
	var hill: float = 14.0 * exp(-(pow(x + 12.0, 2.0) + pow(z + 14.0, 2.0)) / (52.0 * 52.0))
	var flat: float = 0.0
	for k in PADS:
		var p: Array = PADS[k]
		var d: float = Vector2(x - float(p[0]), z - float(p[1])).length()
		var r0: float = float(p[2])
		var bump: float = float(p[3]) * (1.0 - smoothstep(r0, r0 + float(p[4]), d))
		hill = maxf(hill, bump)
		flat = maxf(flat, 1.0 - smoothstep(r0 + 2.0, r0 + 16.0, d))
	# le bourg : une terrasse
	var dt: float = _rect_dist(x, z, TOWN)
	if dt < 22.0:
		hill = maxf(hill * smoothstep(0.0, 22.0, dt), town_y(x, z) * (1.0 - smoothstep(4.0, 22.0, dt)))
		flat = maxf(flat, 1.0 - smoothstep(2.0, 16.0, dt))
	# les falaises du nord : la lande s'arrête net au-dessus de la mer
	var north: float = smoothstep(-55.0, -85.0, z)
	var cliff: float = north * (10.0 + _noise.get_noise_2d(x * 2.0, z) * 3.0) * smoothstep(1.0, 0.955, q)
	var rough: float = (_noise.get_noise_2d(x, z) * 3.2 + _detail.get_noise_2d(x, z) * 1.2) * (1.0 - flat)
	var hn: float = coast + maxf(maxf(hill * inland, cliff) + rough * inland + 1.2 * inland * (1.0 - flat), 0.0)
	# l'éperon de la tour : de la roche nue
	var dtw: float = Vector2(x + 20.0, z - 84.0).length()
	if dtw < 18.0:
		hn += _detail.get_noise_2d(x * 2.0, z * 2.0) * 1.5 * (1.0 - smoothstep(6.0, 18.0, dtw))
	# la grève du ponton : une plage de galets en pente douce
	var db: float = Vector2(x - 74.0, z - 68.0).length()
	if db < 26.0:
		hn = lerpf(hn, minf(hn, coast + 0.6), 1.0 - smoothstep(10.0, 26.0, db))
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 40.0:
		hn = lerpf(-46.0, hn, smoothstep(4.0, 40.0, edge))
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


## Le bourg : la terrasse exactement plane (en pente douce), fondue dans la lande autour.
func _flatten_town() -> void:
	var x0: int = int((TOWN.position.x - 16.0 + HALF) / CELL)
	var x1: int = int((TOWN.end.x + 16.0 + HALF) / CELL)
	var z0: int = int((TOWN.position.y - 16.0 + HALF) / CELL)
	var z1: int = int((TOWN.end.y + 16.0 + HALF) / CELL)
	for zi in range(maxi(z0, 0), mini(z1, count - 1) + 1):
		for xi in range(maxi(x0, 0), mini(x1, count - 1) + 1):
			var x: float = -HALF + xi * CELL
			var z: float = -HALF + zi * CELL
			var d: float = _rect_dist(x, z, TOWN)
			var k: float = smoothstep(1.0, 14.0, d)
			var i: int = zi * count + xi
			if heights[i] < -2.0:
				continue
			heights[i] = lerpf(town_y(x, z), heights[i], k)


func _cut(c: Array) -> void:
	for zi in range(int(float(c[1]) + HALF), int(float(c[3]) + HALF) + 2):
		for xi in range(int(float(c[0]) + HALF), int(float(c[2]) + HALF) + 2):
			if xi >= 0 and zi >= 0 and xi < count and zi < count:
				heights[zi * count + xi] = minf(heights[zi * count + xi], float(c[4]))


## La hauteur au bout d'un chemin : celle du lieu le plus proche (terre-plein ou bourg).
func _anchor_y(p: Vector2) -> float:
	if _rect_dist(p.x, p.y, TOWN) < 1.0:
		return town_y(p.x, p.y)
	var w: Vector3 = W(p.x, p.y)
	return height(w.x, w.z)


## Un chemin : un ruban en pente régulière, lissé, d'un lieu à l'autre.
func _carve(name: String, lane: Array) -> void:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.0), 1)
		for k in range(n):
			pts.append(a.lerp(b, float(k) / n))
	pts.append(lane[-1])
	var y0: float = _anchor_y(pts[0])
	var y1: float = _anchor_y(pts[-1])
	# une pente régulière d'un bout à l'autre (le chemin est taillé dans la pente ou remblayé)
	var total: float = 0.0
	var acc_len: Array = [0.0]
	for k in range(1, pts.size()):
		total += (pts[k] as Vector2).distance_to(pts[k - 1])
		acc_len.append(total)
	var prof: Array = []
	for k in range(pts.size()):
		var t: float = float(acc_len[k]) / maxf(total, 0.01)
		prof.append(lerpf(y0, y1, smoothstep(0.0, 1.0, t) * 0.35 + t * 0.65))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.6, 6.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


## Le Lac Miroir : un rebord, une cuvette, l'îlot au milieu.
func _lake() -> void:
	var c: Vector3 = W(LAKE.x, LAKE.y)
	var ci: Vector3 = W(ISLET.x, ISLET.y)
	var reach: int = int(ceil((LAKE_RIM + 8.0) / CELL))
	var cx: int = int((c.x - CENTER.x + HALF) / CELL)
	var cz: int = int((c.z - CENTER.z + HALF) / CELL)
	for zi in range(maxi(0, cz - reach), mini(count, cz + reach + 1)):
		for xi in range(maxi(0, cx - reach), mini(count, cx + reach + 1)):
			var wx: float = CENTER.x - HALF + xi * CELL
			var wz: float = CENTER.z - HALF + zi * CELL
			var d: float = Vector2(wx - c.x, wz - c.z).length()
			var wob: float = sin(atan2(wz - c.z, wx - c.x) * 5.0) * 0.6
			var i: int = zi * count + xi
			var h: float = heights[i]
			if d < LAKE_R + wob:
				var t: float = smoothstep(LAKE_R + wob, LAKE_R - 5.0, d)
				h = lerpf(LAKE_Y - 0.25, LAKE_FLOOR, t)
			elif d < LAKE_RIM:
				var t2: float = smoothstep(LAKE_R + wob, LAKE_R + wob + 2.5, d)
				var shore: float = lerpf(LAKE_Y - 0.25, LAKE_Y + 0.5, t2)
				h = lerpf(shore, maxf(h, LAKE_Y + 0.5), smoothstep(LAKE_R + wob + 2.5, LAKE_RIM, d))
			elif d < LAKE_RIM + 8.0:
				h = maxf(h, lerpf(LAKE_Y + 0.5, h, smoothstep(LAKE_RIM, LAKE_RIM + 8.0, d)))
			var di: float = Vector2(wx - ci.x, wz - ci.z).length()
			if di < ISLET_R + 2.5:
				h = maxf(h, lerpf(ISLET_Y, LAKE_FLOOR, smoothstep(ISLET_R, ISLET_R + 2.5, di)))
			heights[i] = h


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


## Dans l'eau du lac (et pas sur l'îlot) ?
func in_lake(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	if l.distance_to(LAKE) > LAKE_R + 0.6:
		return false
	if l.distance_to(ISLET) < ISLET_R + 0.8:
		return false
	return height(wx, wz) < LAKE_Y - 0.05


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	mat.set_shader_parameter("sand_tex", load(TEX + "galets.png"))
	mat.set_shader_parameter("sand_n", load(TEX + "galets_n.png"))
	mat.set_shader_parameter("soil_tex", load(TEX + "lande.png"))
	mat.set_shader_parameter("soil_n", load(TEX + "lande_n.png"))
	mat.set_shader_parameter("moss_tex", load(TEX + "bruyere.png"))
	mat.set_shader_parameter("moss_n", load(TEX + "bruyere_n.png"))
	mat.set_shader_parameter("rock_tex", load(TEX + "schiste.png"))
	mat.set_shader_parameter("rock_n", load(TEX + "schiste_n.png"))
	mat.set_shader_parameter("extra_detail", high_quality)
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
			if top < -26.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Arcanelle_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_arcanelle_v67"
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

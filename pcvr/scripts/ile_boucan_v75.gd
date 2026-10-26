extends Node3D
## V75 : le relief de l'Île du Boucan, au sud de l'archipel (sous l'île flottante).
##  - au nord, PORT-BOUCAN : une ancienne friche industrielle et portuaire, plate (des remblais, à
##    TOWN_Y), le long d'un quai de pierre ; le Vieux Bassin (un bassin rectangulaire creusé dans la
##    terre, ouvert sur la mer), la cale sèche devenue skatepark, la plage du nord-ouest où s'est
##    échoué le cargo ;
##  - au sud, la campagne en friche : des collines douces, le Gazomètre (la Cathédrale des Spores,
##    dans une cuvette) et son Bois des Spores, l'Usine Grise (le donjon), la Casse, la Plage aux
##    Galets à l'est, le Phare Tagué sur sa butte à la pointe sud.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille ; une carte des sols (chemins, gravier, mousse des
## spores, béton de la ville) est cuite en même temps pour le shader.

const CENTER := Vector3(-30.0, 0.0, 790.0)
const HALF: float = 260.0
const CELL: float = 1.6
const CHUNKS: int = 6
const WATER: float = -0.42
const TEX := "res://assets/textures/boucan/"
## La mer autour de l'île : un cercle, et un chenal vers le nord (vers la mer de l'archipel).
const SEA_R: float = 300.0
const SEA_LANE := Rect2(-95.0, -450.0, 190.0, 215.0)

## La ville-friche : son sol (des remblais plats), son étendue (repère île).
const TOWN_Y: float = 3.2
const TOWN := Rect2(-176.0, -214.0, 352.0, 204.0)     # x de -176 à 176, z de -214 à -10
## Le Vieux Bassin : un rectangle creusé (ouvert au nord sur la mer), son fond.
const BASIN := Rect2(-37.0, -240.0, 94.0, 81.0)       # x de -37 à 57, z de -240 à -159
const BASIN_FLOOR: float = -6.0
## La cale sèche (le skatepark) : son fond reste sec, à DRY_Y.
const DRY := Rect2(88.0, -200.0, 40.0, 38.0)          # x de 88 à 128, z de -200 à -162
const DRY_Y: float = 0.4
## La plage du cargo échoué (nord-ouest) : la ville s'arrête avant.
const CARGO := Vector2(-150.0, -176.0)
const CARGO_YAW: float = -32.0                        # le cap du cargo (degrés, 0 = vers +X)
## Le Gazomètre, la Cathédrale des Spores : une cuvette plate ; son bois autour.
const GAZO := Vector2(-64.0, 92.0)
const GAZO_R: float = 32.0
const GAZO_Y: float = 4.6
const SPORES_R: float = 96.0
## L'Usine Grise (son enceinte), la Casse, la Plage aux Galets, le Phare.
const USINE := Vector2(112.0, 104.0)
const CASSE := Vector2(150.0, 20.0)
const PLAGE := Vector2(188.0, 98.0)
const PHARE := Vector2(0.0, 200.0)
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : le sol), longueur de la pente]
const PADS := {
	"gazometre": [-64.0, 92.0, 40.0, GAZO_Y, 26.0],
	"usine": [112.0, 104.0, 30.0, 0.0, 18.0],
	"casse": [150.0, 20.0, 26.0, 0.0, 16.0],
	"plage_feu": [184.0, 92.0, 7.0, 0.0, 8.0],
	"phare": [0.0, 196.0, 8.0, 0.0, 10.0],
	"jardins": [132.0, -24.0, 22.0, TOWN_Y, 10.0],
}
## Le ponton de la barque du joueur (boat_v29._make_dock), dans le Vieux Bassin.
const DOCK_A := Vector2(-26.0, -161.8)
const DOCK_B := Vector2(-26.0, -176.0)
## Les chemins hors de la ville (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"sud": [Vector2(-14.0, -8.0), Vector2(-16.0, 18.0), Vector2(-26.0, 42.0), Vector2(-40.0, 56.0)],
	"usine": [Vector2(-16.0, 18.0), Vector2(14.0, 40.0), Vector2(44.0, 60.0), Vector2(72.0, 78.0), Vector2(90.0, 90.0)],
	"casse": [Vector2(112.0, -8.0), Vector2(122.0, 0.0), Vector2(132.0, 10.0)],
	"plage": [Vector2(150.0, 42.0), Vector2(160.0, 62.0), Vector2(172.0, 80.0), Vector2(180.0, 90.0)],
	"phare": [Vector2(-26.0, 42.0), Vector2(-22.0, 80.0), Vector2(-14.0, 130.0), Vector2(-6.0, 168.0), Vector2(-2.0, 188.0)],
	"usine_casse": [Vector2(72.0, 78.0), Vector2(110.0, 60.0), Vector2(140.0, 40.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins (terre), G gravier, B mousse des spores, A béton de la ville
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func _adiff(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)


## 1 au cœur d'un rectangle, 0 à plus de « soft » mètres de lui.
static func _rect_soft(p: Vector2, r: Rect2, soft: float) -> float:
	var dx: float = maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
	return 1.0 - smoothstep(0.0, soft, Vector2(dx, dz).length())


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
static func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 222.0)
	var az: float = absf(z / (214.0 if z < 0.0 else 206.0))
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.6) + pow(az, 2.6), 1.0 / 2.6)
	var wob: float = 0.035 * sin(theta * 3.0 + 0.7) + 0.025 * sin(theta * 5.0 + 1.9) + 0.014 * sin(theta * 11.0 + 0.4)
	# la côte du nord est un quai droit : peu de festons ; la pointe du phare au sud
	var north: float = smoothstep(-0.3, -1.2, theta) * smoothstep(-2.6, -1.9, theta)
	wob *= 1.0 - 0.8 * north
	wob += -0.07 * exp(-pow(wrapf(theta - deg_to_rad(90.0), -PI, PI) / 0.16, 2.0))
	# la baie de la plage aux galets, à l'est
	wob += 0.05 * exp(-pow(wrapf(theta - deg_to_rad(28.0), -PI, PI) / 0.22, 2.0))
	return q * (1.0 + wob)


## Dans la ville (sur les remblais) ?
static func in_town(x: float, z: float) -> bool:
	return TOWN.has_point(Vector2(x, z)) and not near_cargo_beach(x, z)


static func near_cargo_beach(x: float, z: float) -> bool:
	return x < -118.0 and z < -128.0


## La distance d'un point à un segment (repère île).
static func _seg_dist2(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func in_basin(x: float, z: float) -> bool:
	return BASIN.has_point(Vector2(x, z))


static func in_dry(x: float, z: float) -> bool:
	return DRY.has_point(Vector2(x, z))


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
	print("ILE_MANGA_V75: Île du Boucan ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 7501
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.009
	_detail.seed = 7502
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.04
	_hills.seed = 7504
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_octaves = 3
	_hills.frequency = 0.014


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var p := Vector2(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.92, q) * 1.6
	else:
		var off: float = (q - 1.0) * 214.0
		coast = WATER + 0.35 - off * 0.24 - 30.0 * smoothstep(8.0, 30.0, off)
	coast = maxf(coast, -36.0)
	var inland: float = smoothstep(0.985, 0.82, q)
	# la campagne en friche : des collines douces
	var land: float = 4.0 + _noise.get_noise_2d(x, z) * 4.0 + (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 6.0 * smoothstep(-20.0, 60.0, z)
	var rough: float = _detail.get_noise_2d(x * 1.5, z * 1.5) * 0.45
	var hn: float = coast + maxf(land * inland + rough * inland, 0.0)
	# la butte du phare, à la pointe sud
	var dp: float = p.distance_to(PHARE)
	if dp < 40.0:
		hn = maxf(hn, lerpf(hn, 9.0, 1.0 - smoothstep(6.0, 40.0, dp)))
	# la ville : des remblais plats, un quai droit au nord (le mur tombe d'un coup dans l'eau)
	var kt: float = _rect_soft(p, TOWN, 26.0)
	# la plage du cargo (nord-ouest) : les remblais s'arrêtent avant, en pente douce vers le sable
	kt *= 1.0 - smoothstep(-108.0, -126.0, x) * smoothstep(-118.0, -136.0, z)
	if kt > 0.0:
		var town_h: float = TOWN_Y + _detail.get_noise_2d(x * 0.5, z * 0.5) * 0.08
		if q > 0.965 and z < -100.0 and not near_cargo_beach(x, z):
			# le quai : la terre-plein s'arrête au bord, puis l'eau profonde
			town_h = TOWN_Y if q < 0.985 else lerpf(TOWN_Y, -6.0, smoothstep(0.985, 0.995, q))
		hn = lerpf(hn, town_h, kt) if q < 0.995 or z > -100.0 else hn
	# le Vieux Bassin : un trou rectangulaire aux parois droites
	if in_basin(x, z):
		var inside: float = minf(minf(x - BASIN.position.x, BASIN.end.x - x), z - BASIN.position.y)
		var south: float = BASIN.end.y - z
		hn = BASIN_FLOOR if minf(inside, south) > 1.6 else minf(hn, lerpf(TOWN_Y, BASIN_FLOOR, smoothstep(0.0, 1.6, minf(inside, south))))
	# la cale sèche : un fond plat et sec sous les murs, ouverte (par une porte) sur la mer au nord
	if in_dry(x, z):
		var e: float = minf(minf(x - DRY.position.x, DRY.end.x - x), DRY.end.y - z)
		hn = DRY_Y if e > 1.6 else lerpf(TOWN_Y, DRY_Y, smoothstep(0.0, 1.6, e))
	# le Gazomètre : la cuvette (le bord se relève un peu autour de l'anneau)
	var dg: float = p.distance_to(GAZO)
	if dg < GAZO_R + 70.0:
		var rim: float = GAZO_Y + 1.2 * exp(-pow((dg - GAZO_R - 6.0) / 8.0, 2.0))
		var kg: float = 1.0 - smoothstep(GAZO_R + 8.0, GAZO_R + 70.0, dg)
		hn = lerpf(hn, rim if dg > GAZO_R + 2.0 else GAZO_Y, kg)
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 30.0:
		hn = lerpf(-36.0, hn, smoothstep(3.0, 30.0, edge))
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
		if not in_town(p2.x, p2.y):
			_flatten(w2.x, w2.z, 1.8, 6.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 320


## R : la terre noire (les chemins, l'enceinte de l'usine) ; G : le gravier (la casse, les cours,
## le chemin de ronde de l'usine) ; B : la mousse bleu-vert des spores (le Gazomètre) ; A : le
## béton et l'asphalte de la ville.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var dirt: float = 0.0
			dirt = maxf(dirt, 1.0 - smoothstep(26.0, 34.0, p.distance_to(USINE) + n * 5.0))
			var gravel: float = 0.0
			gravel = maxf(gravel, 1.0 - smoothstep(20.0, 30.0, p.distance_to(CASSE) + n * 8.0))
			gravel = maxf(gravel, 1.0 - smoothstep(5.0, 9.0, p.distance_to(PLAGE + Vector2(-4.0, -6.0)) + n * 3.0))
			var moss: float = 1.0 - smoothstep(GAZO_R - 2.0, GAZO_R + 26.0, p.distance_to(GAZO) + n * 14.0)
			var town: float = 0.0
			if in_town(x, z):
				town = 1.0
				# les terrains vagues dans la ville gardent leur herbe sèche (bord est, jardins)
				if _rect_soft(p, Rect2(110.0, -46.0, 46.0, 46.0), 2.0) > 0.5:
					town = 0.0
				if n > 0.42 and z > -60.0:
					town *= 0.0
			# la bordure de la ville : le béton se défait en herbe
			town *= 1.0 - smoothstep(-26.0, -10.0, z + n * 6.0)
			biome.set_pixel(xi, zi, Color(dirt * (1.0 - town), gravel * (1.0 - town), moss, town))
	for k2 in paths_world:
		var pts: Array = paths_world[k2]
		for q in pts:
			var l: Vector2 = L((q as Vector3).x, (q as Vector3).z)
			var cx: int = int((l.x + HALF) / px)
			var cz: int = int((l.y + HALF) / px)
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var ix: int = clampi(cx + dx, 0, BIOME_RES - 1)
					var iz: int = clampi(cz + dz, 0, BIOME_RES - 1)
					var c: Color = biome.get_pixel(ix, iz)
					if c.a < 0.5:
						biome.set_pixel(ix, iz, Color(maxf(c.r, 0.9), c.g * 0.4, c.b * 0.6, c.a))


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


## La mer de l'île (un cercle et un chenal vers le nord) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < SEA_R or SEA_LANE.has_point(l)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	var a: Vector2 = c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)
	var l: Vector2 = L(wx, wz)
	var b: Vector2 = Vector2(clampf(l.x, SEA_LANE.position.x + 0.5, SEA_LANE.end.x - 0.5), clampf(l.y, SEA_LANE.position.y + 0.5, SEA_LANE.end.y - 0.5)) + c
	return a if Vector2(wx, wz).distance_to(a) < Vector2(wx, wz).distance_to(b) else b


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/boucan_terrain_v75.gdshader")
	for k in ["herbe_seche", "gravier", "beton", "asphalte", "terre_noire", "galets", "mousse_spores", "sable_gris"]:
		var t: String = TEX + k + ".png"
		if ResourceLoader.exists(t):
			mat.set_shader_parameter(k + "_tex", load(t))
		var tn: String = TEX + k + "_n.png"
		if ResourceLoader.exists(tn):
			mat.set_shader_parameter(k + "_n", load(tn))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("center", Vector2(CENTER.x, CENTER.z))
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
			mi.name = "Boucan_sol_%d_%d" % [cx, cz]
			mi.mesh = _chunk_mesh(x0, z0, x1, z1)
			mi.material_override = mat
			add_child(mi)


var terrain_mat: ShaderMaterial          # (pour la lueur des mousses la nuit)


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
	body.name = "Sol_boucan_v75"
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

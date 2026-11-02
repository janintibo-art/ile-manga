extends Node3D
## V99 : le relief de l'Île Crayonnée, au sud-est de l'archipel (à l'est de Néopolis).
## Une île ronde, toute en noir et blanc, comme une page de cahier de coloriage. Au nord, le Mont
## Fusain, une grosse colline ronde qui plonge dans la mer par des falaises ; sur son flanc sud, une
## falaise droite (la Falaise du Fusain) : le ruisseau qui naît près du sommet (la Source) y tombe
## en cascade (la Cascade d'Encre) dans l'Étang Gommé, puis il repart vers l'est, jusqu'à la mer
## (le Ruisseau Pointillé). Au milieu de l'île, un grand terre-plein rond : la Clairière des Géants
## (on y bâtira le village des arbres-maisons). À l'ouest, le Bois des Hachures ; à l'est, les Prés
## Blancs ; au sud, la Grève Blanche, où l'on accoste.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage, collision et
## height() lisent la même grille ; deux cartes des sols sont cuites pour le shader.

const CENTER := Vector3(1000.0, 0.0, 1450.0)
const HALF: float = 190.0
const CELL: float = 1.5
const CHUNKS: int = 6
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint celui de Néopolis, à l'ouest.
const SEA_R: float = 360.0
const R0: float = 150.0

## Le Mont Fusain : [x, z, rayon de la base, hauteur]
const MONT := [8.0, -80.0, 80.0, 40.0]
## La Falaise du Fusain : la ligne (z) où le mont est tranché net, entre x0 et x1.
const FALAISE := [-2.0, 64.0, -44.5]
## La Source, et le ruisseau du haut jusqu'au bord de la falaise (la lèvre de la cascade)
const RUISSEAU_HAUT := [Vector2(12.0, -84.0), Vector2(16.0, -74.0), Vector2(21.0, -64.0), Vector2(26.0, -55.0), Vector2(29.0, -48.5), Vector2(30.0, -45.6)]
## L'Étang Gommé : [x, z, rayon]
const ETANG := [32.0, -30.0, 11.0]
## Le ruisseau du bas : de l'étang jusqu'à la mer, à l'est
const RUISSEAU_BAS := [Vector2(42.0, -24.0), Vector2(56.0, -17.0), Vector2(72.0, -8.0), Vector2(90.0, 2.0), Vector2(108.0, 10.0), Vector2(126.0, 16.0), Vector2(142.0, 20.0), Vector2(156.0, 23.0)]

## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : celle du sol), longueur de la pente]
const PADS := {
	"clairiere": [-40.0, 34.0, 36.0, 0.0, 16.0],
	"carrefour": [2.0, 98.0, 7.0, 0.0, 9.0],
	"sommet": [6.0, -86.0, 6.5, 0.0, 9.0],
}
const PLAGE := Vector2(6.0, 136.0)
const DOCK_A := Vector2(10.0, 151.0)
const DOCK_B := Vector2(10.0, 173.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"plage": [Vector2(10.0, 149.0), Vector2(8.0, 128.0), Vector2(4.0, 110.0), Vector2(2.0, 100.0)],
	"clairiere": [Vector2(-4.0, 94.0), Vector2(-14.0, 81.0), Vector2(-22.0, 70.0), Vector2(-28.0, 62.0)],
	"etang": [Vector2(8.0, 93.0), Vector2(20.0, 76.0), Vector2(30.0, 54.0), Vector2(34.0, 30.0), Vector2(32.0, 6.0), Vector2(24.0, -14.0)],
	"mont": [Vector2(-52.0, -1.0), Vector2(-62.0, -24.0), Vector2(-60.0, -48.0), Vector2(-47.0, -68.0), Vector2(-28.0, -84.0), Vector2(-10.0, -92.0), Vector2(1.0, -88.0)],
	"bois": [Vector2(-76.0, 38.0), Vector2(-98.0, 46.0), Vector2(-120.0, 52.0)],
	"pres": [Vector2(8.0, 101.0), Vector2(28.0, 102.0), Vector2(52.0, 94.0), Vector2(76.0, 82.0), Vector2(96.0, 68.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins (terre), G roche, B sable, A herbe rase (la clairière)
var biome2: Image                        # R le sous-bois (le Bois des Hachures), G les fleurs (les Prés Blancs)
var pads_world: Dictionary = {}
var paths_world: Dictionary = {}
var flows_world: Dictionary = {}         # "haut" / "bas" -> Array[Vector3] (la surface de l'eau)
var etang_level: float = 2.0
var levre := Vector3.ZERO                # le bord de la falaise, où le ruisseau tombe
var pied := Vector3.ZERO                 # le pied de la cascade, dans l'étang
var terrain_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func coast_r(theta: float) -> float:
	var r: float = R0 * (1.0 + 0.045 * sin(theta * 2.0 + 2.1) + 0.035 * sin(theta * 5.0 + 0.6) + 0.02 * sin(theta * 8.0 + 2.9))
	# la Grève Blanche, au sud : un peu plus large
	r += 8.0 * exp(-pow(wrapf(theta - PI * 0.5, -PI, PI) / 0.7, 2.0))
	return r


static func coast_q(x: float, z: float) -> float:
	return Vector2(x, z).length() / coast_r(atan2(z, x))


## La plage : le sud et l'est ; au nord, les falaises du Mont Fusain.
static func beach_k(x: float, z: float) -> float:
	var th: float = atan2(z, x)
	return clampf(0.5 + 0.8 * sin(th), 0.0, 1.0)


static func mont_d(x: float, z: float) -> float:
	return Vector2(x - float(MONT[0]), z - float(MONT[1])).length()


## 1 au sud de la falaise (là où le mont est tranché), 0 au nord.
static func falaise_k(x: float, z: float) -> float:
	var zc: float = float(FALAISE[2]) + 2.6 * sin(x * 0.09) + 1.2 * sin(x * 0.31 + 1.0)
	var win: float = smoothstep(float(FALAISE[0]) - 8.0, float(FALAISE[0]) + 4.0, x) * smoothstep(float(FALAISE[1]) + 8.0, float(FALAISE[1]) - 4.0, x)
	return smoothstep(zc - 0.8, zc + 1.0, z) * win


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
	# l'Étang Gommé : son niveau, un peu sous le sol tout autour
	var ew: Vector3 = W(float(ETANG[0]), float(ETANG[1]))
	var lmin: float = 100.0
	for k4 in range(16):
		var a4: float = TAU * k4 / 16.0
		var q: Vector3 = ew + Vector3(cos(a4), 0, sin(a4)) * (float(ETANG[2]) + 3.0)
		# pas le pied de la falaise (il est bien plus haut)
		if falaise_k(L(q.x, q.z).x, L(q.x, q.z).y) < 0.5:
			continue
		lmin = minf(lmin, height(q.x, q.z))
	etang_level = lmin - 0.6
	_dig_etang()
	_dig_haut()
	_dig_bas()
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V99: Île Crayonnée ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 9901
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.012
	_detail.seed = 9902
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.05
	_hills.seed = 9904
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_octaves = 3
	_hills.frequency = 0.02


## La hauteur du Mont Fusain seul : un dôme rond, des bosses, un sommet un peu aplati.
func mont_h(x: float, z: float) -> float:
	var t: float = clampf(mont_d(x, z) / float(MONT[2]), 0.0, 1.0)
	var dome: float = float(MONT[3]) * pow(1.0 - t * t, 1.5)
	var bumps: float = _noise.get_noise_2d(x * 1.4, z * 1.4) * 2.4 * (1.0 - t) + _detail.get_noise_2d(x * 0.8, z * 0.8) * 0.8
	return maxf(dome + bumps, 0.0) * (1.0 - smoothstep(0.92, 1.0, t))


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var bk: float = beach_k(x, z)
	var coast: float
	if q < 1.0:
		var cliff_h: float = 3.0 + 3.0 * (_hills.get_noise_2d(x * 0.7, z * 0.7) * 0.5 + 0.5)
		cliff_h += 10.0 * smoothstep(110.0, 70.0, mont_d(x, z))
		var cliff: float = WATER + smoothstep(1.0, 0.975, q) * cliff_h
		var beach: float = WATER + 0.35 + smoothstep(1.0, 0.84, q) * 2.4
		coast = lerpf(cliff, beach, bk)
	else:
		var off: float = (q - 1.0) * R0
		coast = WATER + 0.35 - off * lerpf(0.9, 0.2, bk) - 30.0 * smoothstep(8.0, 36.0, off)
	coast = maxf(coast, -34.0)
	var inland: float = smoothstep(1.0, 0.9, q) if bk < 0.5 else smoothstep(0.97, 0.76, q)
	var land: float = 2.6 + 2.2 * (1.0 - q) + _noise.get_noise_2d(x, z) * 1.8 + (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 2.4
	var rough: float = _detail.get_noise_2d(x * 1.5, z * 1.5) * 0.25
	var hn: float = coast + maxf(land + rough, 0.0) * inland
	# le Mont Fusain (tranché net par la falaise, au sud) ; au nord, il plonge dans la mer
	var hm: float = mont_h(x, z) * (1.0 - falaise_k(x, z))
	if hm > 0.0:
		var keep: float = smoothstep(1.12, 0.99, q)
		hn = maxf(hn, lerpf(coast, coast + hm + 2.0, keep) if q > 0.99 else hm + maxf(land * 0.4, 0.0) * inland)
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


## Creuse (seulement : ne relève jamais le sol) autour d'un point.
func _dig(wx: float, wz: float, radius: float, blend: float, target: float) -> void:
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
			heights[i] = minf(heights[i], lerpf(target, heights[i], k))


func _anchor_y(p: Vector2) -> float:
	var w: Vector3 = W(p.x, p.y)
	return height(w.x, w.z)


func _dense(lane: Array, step: float) -> Array:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / step), 1)
		for k in range(n):
			pts.append(a.lerp(b, float(k) / n))
	pts.append(lane[-1])
	return pts


## Un chemin : un ruban en pente régulière, lissé, d'un lieu à l'autre.
func _carve(name: String, lane: Array, follow: float = 0.92) -> void:
	var pts: Array = _dense(lane, 1.5)
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
		prof.append(maxf(lerpf(lin, sm / float(nsm), minf(1.0, 4.0 * sin(PI * t)) * follow), 0.6))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.7, 4.8, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


## L'Étang Gommé : une cuvette ; la berge un peu plus haute que l'eau.
func _dig_etang() -> void:
	var mc: Vector3 = W(float(ETANG[0]), float(ETANG[1]))
	var r: float = float(ETANG[2])
	var lvl: float = etang_level
	var cx: float = (mc.x - CENTER.x + HALF) / CELL
	var cz: float = (mc.z - CENTER.z + HALF) / CELL
	var reach: int = int(ceil((r + 8.0) / CELL)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			var i: int = zi * count + xi
			if d < r:
				heights[i] = minf(heights[i], lvl - 0.5 - 1.8 * sqrt(1.0 - d / r))
			elif d < r + 2.5:
				heights[i] = minf(heights[i], lerpf(lvl - 0.5, maxf(heights[i], lvl + 0.35), smoothstep(r, r + 2.5, d)))
			elif d < r + 8.0:
				heights[i] = lerpf(maxf(heights[i], lvl + 0.35), heights[i], smoothstep(r + 2.5, r + 8.0, d))


## Le ruisseau du haut : de la Source au bord de la falaise ; il descend toujours.
func _dig_haut() -> void:
	var pts: Array = _dense(RUISSEAU_HAUT, 1.0)
	var raw: Array = []
	for p0 in pts:
		raw.append(_anchor_y(p0))
	var out: Array = []
	var prev: float = float(raw[0]) - 0.5
	for k in range(pts.size()):
		var p: Vector2 = pts[k]
		var w: Vector3 = W(p.x, p.y)
		var bed: float = minf(prev - 0.02, float(raw[k]) - 0.85)
		prev = bed
		_dig(w.x, w.z, 0.9, 3.2, bed)
		out.append(Vector3(w.x, bed + 0.32, w.z))
	flows_world["haut"] = out
	levre = out[-1]
	var dir: Vector3 = ((out[-1] as Vector3) - (out[-4] as Vector3))
	dir.y = 0.0
	dir = dir.normalized()
	pied = levre + dir * 3.2
	pied.y = etang_level


## Le ruisseau du bas : de l'étang à la mer.
func _dig_bas() -> void:
	var pts: Array = _dense(RUISSEAU_BAS, 1.2)
	var raw: Array = []
	for p0 in pts:
		raw.append(_anchor_y(p0))
	var out: Array = []
	var prev: float = etang_level - 0.25
	for k in range(pts.size()):
		var p: Vector2 = pts[k]
		var w: Vector3 = W(p.x, p.y)
		var bed: float = maxf(minf(prev - 0.03, float(raw[k]) - 1.1), WATER - 1.1)
		prev = bed
		_dig(w.x, w.z, 1.1, 3.6, bed)
		out.append(Vector3(w.x, maxf(bed + 0.38, WATER + 0.05), w.z))
	flows_world["bas"] = out


# =================================================================== les cartes des sols

const BIOME_RES: int = 320


func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	biome2 = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	var cl: Array = PADS["clairiere"]
	var cc := Vector2(float(cl[0]), float(cl[1]))
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var q: float = coast_q(x, z)
			var bk: float = beach_k(x, z)
			var sand: float = bk * (1.0 - smoothstep(0.86, 0.8, q + n * 0.03))
			# la roche : les falaises du nord, le haut du mont, la Falaise du Fusain
			var md: float = mont_d(x, z)
			var rock: float = maxf((1.0 - bk) * smoothstep(0.95, 0.99, q + n * 0.02), smoothstep(0.32, 0.12, md / float(MONT[2]) + n * 0.08) * 0.8)
			var fk: float = falaise_k(x, z)
			var zc_edge: float = fk * (1.0 - fk) * 4.0
			rock = maxf(rock, smoothstep(0.2, 0.6, zc_edge) * smoothstep(0.85, 0.4, md / float(MONT[2])))
			var lawn: float = 1.0 - smoothstep(float(cl[2]) - 4.0, float(cl[2]) + 3.0, p.distance_to(cc) + n * 5.0)
			var dirt: float = 0.0
			for k in ["carrefour", "sommet"]:
				var pd: Array = PADS[k]
				dirt = maxf(dirt, 0.55 * (1.0 - smoothstep(float(pd[2]) - 2.0, float(pd[2]) + 3.0, p.distance_to(Vector2(float(pd[0]), float(pd[1]))) + n * 4.0)))
			# le Bois des Hachures (l'ouest) et les Prés Blancs (l'est)
			var bois: float = smoothstep(-70.0, -95.0, x + n * 14.0) * (1.0 - smoothstep(0.9, 0.97, q))
			var fleurs: float = smoothstep(30.0, 50.0, x + n * 12.0) * smoothstep(20.0, 40.0, z + n * 10.0) * (1.0 - smoothstep(0.82, 0.9, q))
			biome.set_pixel(xi, zi, Color(dirt, rock, sand, lawn))
			biome2.set_pixel(xi, zi, Color(bois, fleurs, 0.0, 0.0))
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


func biome2_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome2.get_pixel(xi, zi) if biome2 != null else Color(0, 0, 0, 0)


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


## Dans l'eau douce (l'étang, un ruisseau) ? Renvoie le niveau de l'eau, ou -INF.
func water_level(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	if l.distance_to(Vector2(float(ETANG[0]), float(ETANG[1]))) < float(ETANG[2]) + 0.6:
		return etang_level
	for f in flows_world:
		var arr: Array = flows_world[f]
		for i in range(0, arr.size(), 2):
			var fp: Vector3 = arr[i]
			if Vector2(fp.x - wx, fp.z - wz).length() < 1.6:
				return fp.y
	return -INF


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== maillage, collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crayon_terrain_v99.gdshader")
	var texs := {"herbe": "res://assets/textures/terrain/grass.jpg", "herbe_n": "res://assets/textures/terrain/grass_n.png",
		"herbe_seche": "res://assets/textures/boucan/herbe_seche.png", "herbe_seche_n": "res://assets/textures/boucan/herbe_seche_n.png",
		"roche": "res://assets/textures/terrain/rock.jpg", "roche_n": "res://assets/textures/terrain/rock_n.png",
		"sable": "res://assets/textures/terrain/sand.jpg", "sable_n": "res://assets/textures/terrain/sand_n.png",
		"terre": "res://assets/textures/boucan/terre_noire.png", "terre_n": "res://assets/textures/boucan/terre_noire_n.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			mat.set_shader_parameter(k + ("" if str(k).ends_with("_n") else "_tex"), load(texs[k]))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome2", ImageTexture.create_from_image(biome2))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("extra_detail", high_quality)
	var ew: Vector3 = W(float(ETANG[0]), float(ETANG[1]))
	mat.set_shader_parameter("etang", Vector4(ew.x, ew.z, float(ETANG[2]), etang_level))
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
			mi.name = "Crayonnee_sol_%d_%d" % [cx, cz]
			mi.mesh = _chunk_mesh(x0, z0, x1, z1)
			mi.material_override = mat
			mi.set_meta("crayon_non", true)
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
	body.name = "Sol_crayonnee_v99"
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

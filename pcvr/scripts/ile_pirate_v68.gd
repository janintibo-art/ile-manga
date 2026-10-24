extends Node3D
## V68 : le relief de l'Île de la Balafre, l'île des pirates, au nord de l'archipel (entre la
## jungle et la grande île de l'est). Une grande île tropicale, sauvage et mal famée :
##  - au sud, la Baie des Pendus, profonde, où mouillent les navires ; sur sa rive nord, le port
##    de Port-Coutelas, sur une terrasse ; à l'ouest de la baie, la grève de carénage ;
##  - au centre-nord, le Pic du Borgne, un piton couvert de jungle ;
##  - à l'est, les Crêtes, fendues de part en part par la Balafre : un ravin qui court du Cirque
##    du Crâne (au pied du pic) jusqu'à la mer ;
##  - à l'ouest, le Marais des Noyés (vase, eau dormante, palétuviers) ;
##  - le Fort Maudit sur le promontoire de l'est, le Cimetière des Pirates sur sa colline à
##    l'ouest du port, la Plage des Os au nord-ouest, les falaises du nord.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille.

const CENTER := Vector3(400.0, 0.0, -700.0)
const HALF: float = 240.0
const CELL: float = 1.6
const CHUNKS: int = 6
const WATER: float = -0.42
const TEX := "res://assets/textures/pirates/"
## La mer autour de l'île (on y nage, on y navigue) : un cercle centré sur l'île.
const SEA_R: float = 232.0

## Les terre-pleins : nom -> [x, z, rayon plat, hauteur, longueur de la pente]
const PADS := {
	"fort": [150.0, 58.0, 17.0, 12.5, 26.0],
	"cimetiere": [-88.0, 22.0, 11.0, 9.0, 22.0],
	"camp": [-40.0, -62.0, 7.0, 14.0, 16.0],
	"residence": [-24.0, 28.0, 8.5, 5.8, 14.0],
}
## Port-Coutelas : la terrasse (x0, z0, largeur, profondeur) ; le quai est au bord sud (z = 92).
const TOWN := Rect2(-76.0, 40.0, 152.0, 52.5)
const QUAY_Z: float = 92.5
const QUAY_X0: float = -48.0
const QUAY_X1: float = 62.0
## La Baie des Pendus : un bassin rectangulaire contre le quai et une ellipse vers le large.
const BAY_RECT := Rect2(-48.0, 93.6, 110.0, 20.0)
const BAY_C := Vector2(8.0, 140.0)
const BAY_R := Vector2(70.0, 48.0)
const BAY_FLOOR: float = -9.5
## La grève de carénage, à l'ouest de la baie.
const CAREEN := Rect2(-84.0, 94.0, 36.0, 52.0)
## Le Pic du Borgne
const PEAK := Vector2(20.0, -95.0)
const PEAK_H: float = 58.0
## La Balafre : le ravin, du Cirque du Crâne jusqu'à la mer (à l'est).
const RAVINE := [Vector2(52.0, -66.0), Vector2(78.0, -58.0), Vector2(108.0, -48.0), Vector2(140.0, -34.0), Vector2(168.0, -22.0), Vector2(204.0, -12.0)]
const RAVINE_TOP: float = 12.0        # fond du ravin au Cirque
const CIRQUE := Vector2(52.0, -66.0)
const CIRQUE_R: float = 15.0
## Le Rocher du Crâne (au bord ouest du Cirque) : centre au sol, rayon de la coquille.
const SKULL := Vector2(39.0, -68.0)
## Le Marais des Noyés : centre, rayon, niveau de l'eau dormante.
const MARSH := Vector2(-135.0, -10.0)
const MARSH_R: float = 58.0
const MARSH_Y: float = 0.34
## La Plage des Os (nord-ouest)
const BONES := Vector2(-118.0, -138.0)
## Les pontons (repère île) : départ au quai, bout dans la baie, hauteur du platelage.
const PIER_A := [Vector2(-25.0, 92.6), Vector2(-25.0, 128.0)]
const PIER_B := [Vector2(22.0, 92.6), Vector2(22.0, 126.0)]
const PIER_Y: float = 1.25
## Le ponton de la barque du joueur (boat_v29._make_dock).
const DOCK_A := Vector2(55.0, 93.0)
const DOCK_B := Vector2(55.0, 112.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"nord": [Vector2(0.0, 40.0), Vector2(3.0, 22.0), Vector2(-3.0, 4.0), Vector2(-10.0, -16.0), Vector2(-20.0, -36.0)],
	"marais": [Vector2(-20.0, -36.0), Vector2(-48.0, -30.0), Vector2(-74.0, -24.0), Vector2(-96.0, -18.0)],
	"camp": [Vector2(-20.0, -36.0), Vector2(-28.0, -48.0), Vector2(-36.0, -57.0)],
	"os": [Vector2(-74.0, -24.0), Vector2(-88.0, -52.0), Vector2(-100.0, -84.0), Vector2(-110.0, -112.0), Vector2(-116.0, -128.0)],
	"balafre": [Vector2(-3.0, 4.0), Vector2(22.0, -4.0), Vector2(44.0, -16.0), Vector2(64.0, -30.0), Vector2(84.0, -48.0), Vector2(94.0, -52.0)],
	"fort": [Vector2(72.0, 70.0), Vector2(96.0, 68.0), Vector2(116.0, 64.0), Vector2(134.0, 60.0)],
	"cimetiere": [Vector2(-62.0, 48.0), Vector2(-72.0, 38.0), Vector2(-80.0, 29.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _marsh := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


## La terrasse du port : 2,6 m au quai, en pente douce vers le nord.
static func town_y(x: float, z: float) -> float:
	var cz: float = clampf(z, TOWN.position.y, TOWN.end.y)
	return 2.6 + 0.032 * (TOWN.end.y - cz)


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


## Distance (repère île) à l'axe de la Balafre, et position le long du ravin (0 au Cirque, 1 à la mer).
static func ravine(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best: float = INF
	var best_t: float = 0.0
	var acc: float = 0.0
	var total: float = 0.0
	for i in range(RAVINE.size() - 1):
		total += (RAVINE[i] as Vector2).distance_to(RAVINE[i + 1])
	for i in range(RAVINE.size() - 1):
		var a: Vector2 = RAVINE[i]
		var b: Vector2 = RAVINE[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d: float = p.distance_to(a + ab * t)
		if d < best:
			best = d
			best_t = (acc + ab.length() * t) / total
		acc += ab.length()
	return Vector2(best, best_t)


## Le fond du ravin à l'abscisse t (0 au Cirque, 1 à la mer).
static func ravine_floor(t: float) -> float:
	if t < 0.82:
		return lerpf(RAVINE_TOP, 1.4, pow(t / 0.82, 0.9))
	return lerpf(1.4, -3.5, smoothstep(0.82, 1.0, t))


## Distance (signée, m) au bassin de la baie (négatif dedans).
static func bay_dist(x: float, z: float) -> float:
	var dr: float = _rect_dist(x, z, BAY_RECT)
	if dr <= 0.0:
		dr = -minf(minf(x - BAY_RECT.position.x, BAY_RECT.end.x - x), minf(z - BAY_RECT.position.y, BAY_RECT.end.y - z))
	var e: Vector2 = Vector2((x - BAY_C.x) / BAY_R.x, (z - BAY_C.y) / BAY_R.y)
	var de: float = (e.length() - 1.0) * minf(BAY_R.x, BAY_R.y)
	return minf(dr, de)


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
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	# les talus des chemins ne mordent pas sur les terre-pleins, ni sur le port
	for k3 in PADS:
		var p3: Array = PADS[k3]
		var w3: Vector3 = W(float(p3[0]), float(p3[1]))
		_flatten(w3.x, w3.z, float(p3[2]) - 0.5, float(p3[2]) + 1.0, float(p3[3]))
	_flatten_town()
	_cirque()
	# les dalles des chemins suivent le sol tel qu'il est au bout du compte
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V68: île de la Balafre ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 6801
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.011
	_detail.seed = 6802
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail.fractal_octaves = 3
	_detail.frequency = 0.04
	_coast.seed = 6803
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8
	_marsh.seed = 6804
	_marsh.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_marsh.fractal_type = FastNoiseLite.FRACTAL_FBM
	_marsh.fractal_octaves = 3
	_marsh.frequency = 0.06


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 206.0)
	var az: float = absf((z + 4.0) / 186.0)
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.1) + pow(az, 2.1), 1.0 / 2.1)
	# des anses et des pointes ; plus sage autour de la baie (au sud)
	var calm: float = 1.0 - 0.8 * exp(-pow(wrapf(theta - 1.62, -PI, PI) / 0.45, 2.0))
	var wob: float = 0.13 * _coast.get_noise_2d(cos(theta) * 1.6, sin(theta) * 1.6) + 0.055 * _coast.get_noise_2d(cos(theta) * 5.0 + 9.0, sin(theta) * 5.0) + 0.03 * sin(theta * 6.0 + 0.4)
	# le promontoire du Fort Maudit (est-sud-est), l'anse de la Plage des Os (nord-ouest),
	# l'embouchure de la Balafre (est)
	wob += -0.12 * exp(-pow(wrapf(theta - 0.37, -PI, PI) / 0.16, 2.0)) + 0.07 * exp(-pow(wrapf(theta + 2.27, -PI, PI) / 0.2, 2.0))
	wob += 0.05 * exp(-pow(wrapf(theta + 0.07, -PI, PI) / 0.08, 2.0))
	return q * (1.0 + wob * calm)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.9, q) * 1.6
	else:
		# au large : une pente douce sur une dizaine de mètres, puis le tombant jusqu'au fond
		# (le relief rejoint le fond du large bien avant le bord du carré : pas de plateau carré)
		var off: float = (q - 1.0) * 200.0
		coast = WATER + 0.35 - off * 0.21 - 46.0 * smoothstep(10.0, 32.0, off)
	coast = maxf(coast, -46.0)
	var inland: float = smoothstep(0.98, 0.72, q)
	# les collines de la jungle
	var hills: float = 7.5 + _noise.get_noise_2d(x, z) * 7.0 + _detail.get_noise_2d(x, z) * 1.6
	# le Pic du Borgne
	var dp: float = Vector2(x - PEAK.x, z - PEAK.y).length()
	var peak: float = PEAK_H * exp(-pow(dp / 50.0, 1.45)) * (1.0 + _detail.get_noise_2d(x * 1.6, z * 1.6) * 0.08)
	# les Crêtes, de part et d'autre de la Balafre
	var rv: Vector2 = ravine(x, z)
	var ridge: float = 27.0 * exp(-pow(rv.x / 40.0, 2.0)) * (1.0 - smoothstep(0.7, 1.0, rv.y)) * (1.0 + _noise.get_noise_2d(x * 2.0, z * 2.0) * 0.25)
	var land: float = maxf(maxf(hills, peak), ridge)
	# chaque lieu sur son terre-plein (« la terre monte vers eux »)
	var flat: float = 0.0
	for k in PADS:
		var p: Array = PADS[k]
		var d: float = Vector2(x - float(p[0]), z - float(p[1])).length()
		var r0: float = float(p[2])
		var bump: float = float(p[3]) * (1.0 - smoothstep(r0, r0 + float(p[4]), d))
		land = maxf(land * (smoothstep(r0, r0 + float(p[4]), d) * 0.6 + 0.4), bump) if d < r0 + float(p[4]) else land
		flat = maxf(flat, 1.0 - smoothstep(r0 + 2.0, r0 + 14.0, d))
	# le port : une terrasse (les collines s'effacent devant elle)
	var dt: float = _rect_dist(x, z, TOWN)
	if dt < 30.0:
		var k_t: float = smoothstep(4.0, 30.0, dt)
		land = lerpf(town_y(x, z), land, k_t)
		flat = maxf(flat, 1.0 - smoothstep(2.0, 18.0, dt))
	# les falaises du nord : la jungle s'arrête net au-dessus de la mer
	var north: float = smoothstep(-120.0, -160.0, z)
	var cliff: float = north * (12.0 + _noise.get_noise_2d(x * 2.0, z) * 4.0) * smoothstep(1.0, 0.95, q)
	var rough: float = (_noise.get_noise_2d(x * 2.3, z * 2.3) * 1.8 + _detail.get_noise_2d(x * 1.3, z * 1.3) * 1.0) * (1.0 - flat)
	var hn: float = coast + maxf(maxf(land * inland, cliff) + rough * inland, 0.0)
	# le Marais des Noyés : des mottes de vase autour de mares d'eau dormante
	var dm: float = Vector2(x - MARSH.x, z - MARSH.y).length() * (1.0 + _coast.get_noise_2d(x * 0.02, z * 0.02) * 0.18)
	if dm < MARSH_R + 26.0 and q < 1.02:
		var mh: float = MARSH_Y + 0.05 + _marsh.get_noise_2d(x, z) * 0.9
		var mg: float = lerpf(mh, coast, smoothstep(0.93, 1.0, q))
		hn = lerpf(mg, hn, smoothstep(MARSH_R, MARSH_R + 26.0, dm))
	# la Balafre : un ravin aux parois raides, du Cirque jusqu'à la mer
	if rv.x < 20.0:
		var fl: float = ravine_floor(rv.y) + _detail.get_noise_2d(x * 3.0, z * 3.0) * 0.25
		var w0: float = 5.5 + 2.5 * rv.y
		if hn > fl:
			hn = lerpf(fl, hn, smoothstep(w0, w0 + 9.0, rv.x + _noise.get_noise_2d(x * 4.0, z * 4.0) * 1.5))
	# la Plage des Os : une grève large et douce
	var db: float = Vector2(x - BONES.x, z - BONES.y).length()
	if db < 40.0:
		hn = lerpf(hn, minf(hn, coast + 0.5), 1.0 - smoothstep(16.0, 40.0, db))
	# la baie : un bassin profond contre le quai ; la grève de carénage à l'ouest
	var bd: float = bay_dist(x, z)
	if bd < 16.0:
		var deep: float = lerpf(BAY_FLOOR, WATER - 0.8, smoothstep(-14.0, 0.0, bd))
		if bd < 0.0:
			hn = minf(hn, deep)
		else:
			hn = minf(hn, lerpf(WATER - 0.6, hn, smoothstep(0.0, 16.0, bd)))
	var dc: float = _rect_dist(x, z, CAREEN)
	if dc < 14.0:
		var beach: float = lerpf(-2.2, 2.3, smoothstep(-50.0, -80.0, x))
		hn = lerpf(beach, hn, smoothstep(0.0, 14.0, dc)) if hn > beach or dc < 0.5 else hn
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 34.0:
		hn = lerpf(-46.0, hn, smoothstep(3.0, 34.0, edge))
	return hn


## Le Cirque du Crâne : le fond plat du ravin, au pied du pic.
func _cirque() -> void:
	var c: Vector3 = W(CIRQUE.x, CIRQUE.y)
	_flatten(c.x, c.z, CIRQUE_R - 2.0, CIRQUE_R + 4.0, RAVINE_TOP)
	var s: Vector3 = W(SKULL.x, SKULL.y)
	_flatten(s.x, s.z, 6.5, 9.0, RAVINE_TOP)


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


## Le port : la terrasse exactement plane (en pente douce), fondue dans la jungle autour ;
## au sud, le quai tombe à pic dans la baie.
func _flatten_town() -> void:
	var x0: int = int((TOWN.position.x - 14.0 + HALF) / CELL)
	var x1: int = int((TOWN.end.x + 14.0 + HALF) / CELL) + 1
	var z0: int = int((TOWN.position.y - 14.0 + HALF) / CELL)
	var z1: int = int((TOWN.end.y + 2.0 + HALF) / CELL) + 1
	for zi in range(maxi(z0, 0), mini(z1, count - 1) + 1):
		for xi in range(maxi(x0, 0), mini(x1, count - 1) + 1):
			var x: float = -HALF + xi * CELL
			var z: float = -HALF + zi * CELL
			var i: int = zi * count + xi
			if z > QUAY_Z and x > QUAY_X0 - 0.5 and x < QUAY_X1 + 0.5:
				continue
			var d: float = _rect_dist(x, z, TOWN)
			if z > TOWN.end.y and (x < QUAY_X0 or x > QUAY_X1):
				continue
			var k: float = smoothstep(0.5, 12.0, d)
			if heights[i] < -2.0 and d > 1.0:
				continue
			heights[i] = lerpf(town_y(x, z), heights[i], k)


## La hauteur au bout d'un chemin : celle du lieu le plus proche (terre-plein ou port).
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
	# le profil suit le sol (lissé), sans trop s'en écarter : un sentier de jungle, pas une route
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
		var w: float = 0.55 * sin(PI * t)
		prof.append(lerpf(lin, ground, w))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.8, 6.5, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== lecture du relief

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - CENTER.x + HALF) / CELL
	var fz: float = (wz - CENTER.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -46.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


## La mer de l'île (cercle) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	return Vector2(wx - CENTER.x, wz - CENTER.z).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


## Dans le marais (là où l'eau dormante recouvre la vase) ?
func in_marsh(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.distance_to(MARSH) < MARSH_R + 12.0


func in_marsh_water(wx: float, wz: float) -> bool:
	return in_marsh(wx, wz) and height(wx, wz) < MARSH_Y - 0.02


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/pirate_terrain_v68.gdshader")
	mat.set_shader_parameter("sand_tex", load(TEX + "sable.png"))
	mat.set_shader_parameter("sand_n", load(TEX + "sable_n.png"))
	mat.set_shader_parameter("soil_tex", load(TEX + "terre.png"))
	mat.set_shader_parameter("soil_n", load(TEX + "terre_n.png"))
	mat.set_shader_parameter("moss_tex", load(TEX + "sousbois.png"))
	mat.set_shader_parameter("moss_n", load(TEX + "sousbois_n.png"))
	mat.set_shader_parameter("rock_tex", load(TEX + "basalte.png"))
	mat.set_shader_parameter("rock_n", load(TEX + "basalte_n.png"))
	mat.set_shader_parameter("mud_tex", load(TEX + "vase.png"))
	mat.set_shader_parameter("mud_n", load(TEX + "vase_n.png"))
	var mc: Vector3 = W(MARSH.x, MARSH.y)
	mat.set_shader_parameter("marsh", Vector4(mc.x, mc.z, MARSH_R - 6.0, MARSH_R + 18.0))
	var tc: Vector3 = W(TOWN.get_center().x, TOWN.get_center().y)
	mat.set_shader_parameter("town", Vector4(tc.x, tc.z, TOWN.size.x * 0.5, TOWN.size.y * 0.5))
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
			mi.name = "Balafre_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_balafre_v68"
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

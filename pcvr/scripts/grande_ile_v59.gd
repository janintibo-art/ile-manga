extends Node3D
## V59 : la grande île de l'est — à l'est de l'île des elfes, au-delà du détroit. Une île
## de plus de cinq cents mètres, si grande que chaque côte a son climat :
##  - l'ouest : la côte des prairies, rase et venteuse, des plages blondes ; dans sa baie
##    s'est échoué le Léviathan, l'épave géante où vivent les gens de Carène ;
##  - le nord : les hautes terres, landes rousses, rochers gris, neige sur les crêtes ;
##  - l'est : la forêt des brumes, mousses, terre noire, mares et vasières ;
##  - le sud : le désert, dunes ocre et buttes de roche rouge.
## Au milieu se dresse le massif : un plateau de pierre à près de 90 m, ceint de falaises.
## Sur sa face ouest, une porte géante, scellée, marquée de quatre sceaux vides.
## Même principe que les autres îles : le relief est calculé une fois dans une grille ;
## maillage, collision et height() lisent la même grille. Les poids des quatre régions
## vont dans la couleur des sommets (grande_ile_v59.gdshader).

const Fond = preload("res://scripts/fond_marin_v55.gd")
const Tazira = preload("res://scripts/tazira_relief_v60.gd")
const Cliquetis = preload("res://scripts/cliquetis_relief_v61.gd")
const Ramure = preload("res://scripts/ramure_relief_v62.gd")
const PirateIle = preload("res://scripts/ile_pirate_v68.gd")
const SoleilsIle = preload("res://scripts/ile_soleils_v69.gd")
const BraiseIle = preload("res://scripts/ile_braise_v70.gd")
const MontjoieIle = preload("res://scripts/ile_montjoie_v71.gd")
const BoucanIle = preload("res://scripts/ile_boucan_v75.gd")
const AstraleIle = preload("res://scripts/ile_astrale_v76.gd")
const MoaiIle = preload("res://scripts/ile_moai_v87.gd")
const PixelIle = preload("res://scripts/ile_pixel_v90.gd")
const LarsenIle = preload("res://scripts/ile_larsen_v91.gd")
const CENTER := Vector3(940.0, 0.0, -150.0)       # le centre de l’île (le massif)
const GRID := Vector3(900.0, 0.0, -120.0)         # le centre de la grille du relief
const HALF: float = 371.2
const CELL: float = 1.6
const CHUNKS: int = 8
const WATER: float = -0.42
const LAND_R: float = 262.0
const PLATEAU_R: float = 48.0
const PLATEAU_Y: float = 104.0
const DOOR_R: float = 63.0             # la porte scellée, au pied de la falaise ouest
const MESAS := [[1.62, 150.0, 17.0, 21.0], [2.25, 215.0, 12.0, 15.0], [0.92, 235.0, 10.0, 17.5], [2.2, 150.0, 9.0, 13.0]]
const PONDS := [[-0.45, 170.0, 13.0], [-0.12, 205.0, 10.0], [0.2, 150.0, 15.0], [0.48, 190.0, 11.0], [0.05, 120.0, 8.0], [-0.3, 228.0, 7.5], [0.62, 228.0, 8.0]]

var count: int = 0
var heights := PackedFloat32Array()
var regions := PackedColorArray()
var epave: Node3D                       # epave_v59.gd (pour ensabler la coque)
var door_pos := Vector3.ZERO            # pied de la porte (monde)
var door_yaw: float = 0.0               # la porte regarde l'ouest
var ponds_world: Array = []             # [Vector3 centre (niveau de l'eau), rayon]
var mesas_world: Array = []             # [Vector3 centre, rayon]
var _noise := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _warp := FastNoiseLite.new()


func build(high_quality: bool, wreck: Node3D) -> void:
	var t0: int = Time.get_ticks_msec()
	epave = wreck
	_setup_noise()
	count = int(round(HALF * 2.0 / CELL)) + 1
	heights.resize(count * count)
	regions.resize(count * count)
	for zi in range(count):
		var wz: float = GRID.z - HALF + zi * CELL
		for xi in range(count):
			var wx: float = GRID.x - HALF + xi * CELL
			var i: int = zi * count + xi
			regions[i] = region_at(wx, wz)
			heights[i] = _shape(wx, wz, regions[i])
	_dig_ponds()
	_door_terrace()
	_bury_wreck()
	_build_mesh(high_quality)
	_build_collision()
	_build_ponds()
	_build_door()
	_build_mist(high_quality)
	print("ILE_MANGA_V59: grande île ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms ; porte scellée à ", door_pos)


func _setup_noise() -> void:
	_noise.seed = 5901
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.009
	_ridge.seed = 5902
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 4
	_ridge.frequency = 0.0075
	_coast.seed = 5903
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.7
	_warp.seed = 5904
	_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp.fractal_octaves = 2
	_warp.frequency = 0.006


# =================================================================== la mer autour de l'île

## La mer navigable (barque) et où l'on nage s'étendent jusqu'ici : un cercle autour de l'île
## et un « couloir » qui la relie à la mer de l'archipel (au large de l'île des elfes).
const EAST_C := Vector2(905.0, -150.0)
const EAST_R: float = 360.0
const LANE_A := Vector2(470.0, -160.0)
const LANE_B := Vector2(640.0, -150.0)
const LANE_R: float = 130.0


static func _seg_closest(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + ab * t


static func east_contains(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	return p.distance_to(EAST_C) < EAST_R or p.distance_to(_seg_closest(p, LANE_A, LANE_B)) < LANE_R


## Le point le plus proche dans la mer de l'est (cercle ou couloir).
static func east_clamp(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var c1: Vector2 = EAST_C + (p - EAST_C).limit_length(EAST_R - 0.5)
	var q: Vector2 = _seg_closest(p, LANE_A, LANE_B)
	var c2: Vector2 = q + (p - q).limit_length(LANE_R - 0.5)
	return c1 if p.distance_to(c1) < p.distance_to(c2) else c2


## Le monde marin complet : le cercle de l'archipel (centre, rayon), la mer de l'est et
## (V68) la mer de l'Île de la Balafre, au nord ; (V69) celle de l'Île des Trois Soleils, à l'ouest ;
## (V70) celle de l'Île de Braise, au sud-ouest ; (V71) celle de l'Île de Montjoie, au sud de la grande île ;
## (V75) celle de l'Île du Boucan, au sud du village.
static func sea_contains(x: float, z: float, mid: Vector2, radius: float) -> bool:
	return Vector2(x, z).distance_to(mid) < radius or east_contains(x, z) or PirateIle.sea_contains(x, z) or SoleilsIle.sea_contains(x, z) or BraiseIle.sea_contains(x, z) or MontjoieIle.sea_contains(x, z) or BoucanIle.sea_contains(x, z) or AstraleIle.sea_contains(x, z) or MoaiIle.sea_contains(x, z) or PixelIle.sea_contains(x, z) or LarsenIle.sea_contains(x, z)


static func sea_clamp(x: float, z: float, mid: Vector2, radius: float) -> Vector2:
	if sea_contains(x, z, mid, radius):
		return Vector2(x, z)
	var p := Vector2(x, z)
	var c0: Vector2 = mid + (p - mid).limit_length(radius - 0.5)
	var c1: Vector2 = east_clamp(x, z)
	var c2: Vector2 = PirateIle.sea_clamp(x, z)
	var c3: Vector2 = SoleilsIle.sea_clamp(x, z)
	var c4: Vector2 = BraiseIle.sea_clamp(x, z)
	var c5: Vector2 = MontjoieIle.sea_clamp(x, z)
	var c6: Vector2 = BoucanIle.sea_clamp(x, z)
	var c7: Vector2 = AstraleIle.sea_clamp(x, z)
	var c8: Vector2 = MoaiIle.sea_clamp(x, z)
	var c9: Vector2 = PixelIle.sea_clamp(x, z)
	var c10: Vector2 = LarsenIle.sea_clamp(x, z)
	var best: Vector2 = c0 if p.distance_to(c0) < p.distance_to(c1) else c1
	best = best if p.distance_to(best) < p.distance_to(c2) else c2
	best = best if p.distance_to(best) < p.distance_to(c3) else c3
	best = best if p.distance_to(best) < p.distance_to(c4) else c4
	best = best if p.distance_to(best) < p.distance_to(c5) else c5
	best = best if p.distance_to(best) < p.distance_to(c6) else c6
	best = best if p.distance_to(best) < p.distance_to(c7) else c7
	best = best if p.distance_to(best) < p.distance_to(c8) else c8
	best = best if p.distance_to(best) < p.distance_to(c9) else c9
	return best if p.distance_to(best) < p.distance_to(c10) else c10


# =================================================================== régions

static func _adiff(a: float, b: float) -> float:
	return wrapf(a - b, -PI, PI)


## Poids des quatre régions : r = ouest, g = nord, b = est, a = sud.
func region_at(wx: float, wz: float) -> Color:
	var dx: float = wx - CENTER.x
	var dz: float = wz - CENTER.z
	var th: float = atan2(dz, dx) + _warp.get_noise_2d(wx, wz) * 0.45
	var w := Color(
		pow(maxf(0.0, cos(_adiff(th, PI))), 3.0),
		pow(maxf(0.0, cos(_adiff(th, -PI * 0.5))), 3.0),
		pow(maxf(0.0, cos(th)), 3.0),
		pow(maxf(0.0, cos(_adiff(th, PI * 0.5))), 3.0))
	var s: float = w.r + w.g + w.b + w.a
	return Color(w.r / s, w.g / s, w.b / s, w.a / s)


## La région dominante : "ouest", "nord", "est", "sud".
func region_name(wx: float, wz: float) -> String:
	var w: Color = region_at(wx, wz)
	var best: float = w.r
	var n := "ouest"
	if w.g > best:
		best = w.g
		n = "nord"
	if w.b > best:
		best = w.b
		n = "est"
	if w.a > best:
		n = "sud"
	return n


# =================================================================== relief

func coast_radius(th: float) -> float:
	var r: float = LAND_R * (1.0 + 0.08 * _coast.get_noise_2d(cos(th) * 2.0, sin(th) * 2.0) + 0.03 * sin(th * 5.0 + 1.0))
	# la baie du Léviathan, à l'ouest, entre deux pointes qui l'abritent
	# (la côte ouest s'avance en un large lobe ; la baie y est creusée par _bay)
	r += 112.0 * exp(-pow(_adiff(th, PI) / 0.4, 2.0))
	return r


func _shape(wx: float, wz: float, w: Color) -> float:
	var dx: float = wx - CENTER.x
	var dz: float = wz - CENTER.z
	var r: float = sqrt(dx * dx + dz * dz)
	var th: float = atan2(dz, dx)
	var R: float = coast_radius(th)
	var q: float = r / R
	var h: float
	if q < 1.0:
		h = WATER + 0.35 + smoothstep(1.0, 0.93, q) * 1.6
	else:
		h = WATER + 0.35 - (r - R) * 0.32
	var inland: float = smoothstep(0.97, 0.72, q)
	var n1: float = _noise.get_noise_2d(wx, wz) * 0.5 + 0.5
	var relief: float = 0.0
	if w.r > 0.01:
		relief += w.r * (2.5 + 7.0 * n1 + 1.5 * sin(wx * 0.03) * cos(wz * 0.027))
	if w.g > 0.01:
		var rg: float = _ridge.get_noise_2d(wx, wz) * 0.5 + 0.5
		relief += w.g * (14.0 + 24.0 * pow(rg, 1.8) + 9.0 * n1)
	if w.b > 0.01:
		relief += w.b * (3.5 + 7.0 * n1)
	if w.a > 0.01:
		var ax: float = wx * 0.92 + wz * 0.38
		var dune: float = pow(absf(sin(ax * 0.045 + n1 * 4.0)), 1.6)
		var sd: float = 4.0 + 6.5 * dune + 3.0 * n1
		for m in MESAS:
			var mc := Vector2(CENTER.x + cos(float(m[0])) * float(m[1]), CENTER.z + sin(float(m[0])) * float(m[1]))
			var d: float = Vector2(wx, wz).distance_to(mc) + _ridge.get_noise_2d(wx * 2.0, wz * 2.0) * 3.0
			var top: float = float(m[3]) + _noise.get_noise_2d(wx * 3.0, wz * 3.0) * 0.6
			sd = maxf(sd, lerpf(top, sd, smoothstep(float(m[2]) - 1.5, float(m[2]) + 5.0, d)))
		relief += w.a * sd
	# le massif du centre : ses pentes effacent peu à peu le relief des régions
	var ms: float = smoothstep(150.0, 70.0, r)
	h += relief * inland * (1.0 - ms)
	var rn: float = r + _noise.get_noise_2d(wx * 2.3, wz * 2.3) * 5.0
	var massif: float
	if rn < PLATEAU_R:
		massif = PLATEAU_Y + _noise.get_noise_2d(wx * 4.0, wz * 4.0) * 1.2
	elif rn < 62.0:
		massif = lerpf(PLATEAU_Y, 58.0, smoothstep(PLATEAU_R, 62.0, rn))
	else:
		massif = 58.0 * pow(smoothstep(178.0, 62.0, rn), 1.35)
	massif += (_ridge.get_noise_2d(wx * 1.6, wz * 1.6) * 0.5 + 0.5) * 7.0 * smoothstep(52.0, 75.0, rn) * smoothstep(170.0, 95.0, rn)
	h = maxf(h, WATER + 0.35 + massif) if massif > 0.5 else h
	if ms > 0.0:
		h = lerpf(h, maxf(h, WATER + 0.35 + massif), ms)
	h = _bay(wx, wz, h)
	# la plage du Léviathan : une flèche de sable au nord de l'épave
	h = _wreck_beach(wx, wz, h)
	# au large, le fond rejoint celui de la mer (pas de marche)
	h = maxf(h, -34.0)
	var edge: float = minf(HALF - absf(wx - GRID.x), HALF - absf(wz - GRID.z))
	if h < 0.0 and edge < 60.0:
		h = lerpf(Fond.height(wx, wz), h, smoothstep(4.0, 60.0, edge))
	# V60 : Tazira, le port des sables, sur la côte sud
	h = Tazira.shape(wx, wz, h)
	h = Cliquetis.shape(wx, wz, h)
	# V62 : Ramure, le village des oreilles (le Cercle de la Lune, la Clairière des Jeux)
	h = Ramure.shape(wx, wz, h)
	return h


## La baie du Léviathan : une anse ovale ouverte vers l'ouest, au fond de laquelle
## l'épave s'est échouée.
const BAY := Vector3(642.0, 0.0, -150.0)
const BAY_AX := Vector2(88.0, 62.0)


func _bay(wx: float, wz: float, h: float) -> float:
	var ex: float = (wx - BAY.x) / BAY_AX.x
	if wx < BAY.x:
		ex *= 0.55                     # vers l'ouest, l'anse s'ouvre sur la mer
	var e: float = sqrt(ex * ex + pow((wz - BAY.z) / BAY_AX.y, 2.0))
	e += _coast.get_noise_2d(wx * 0.02, wz * 0.02) * 0.08
	if e > 1.45:
		return h
	var floor_y: float = -1.6 - 9.0 * (1.0 - smoothstep(0.0, 1.0, e)) - maxf(BAY.x - wx, 0.0) * 0.05
	if e < 1.0:
		return minf(h, floor_y)
	# la grève tout autour de l'anse
	var shore: float = lerpf(-1.6, 1.4, smoothstep(1.0, 1.25, e))
	return minf(h, lerpf(shore, h, smoothstep(1.2, 1.45, e)))


## La flèche de sable : du nez de l'épave jusqu'au milieu de la coque, côté nord.
func _wreck_beach(wx: float, wz: float, h: float) -> float:
	if epave == null:
		return h
	var l: Vector3 = epave.Lc(Vector3(wx, 0.0, wz))
	if l.x < -30.0 or l.x > 140.0 or l.z > 30.0 or l.z < -110.0:
		return h
	var bh: float = 0.55 + maxf(l.x - 5.0, 0.0) * 0.018 + maxf(-l.z - 17.0, 0.0) * 0.02
	bh += _noise.get_noise_2d(wx * 3.0, wz * 3.0) * 0.25
	# vers la mer (l'arrière, à l'ouest), la plage plonge
	if l.x < 5.0:
		bh = lerpf(bh, -4.0, smoothstep(5.0, -25.0, l.x))
	var wxb: float = smoothstep(18.0, 34.0, l.x)
	var wzb: float = smoothstep(-66.0, -48.0, l.z) * (1.0 - smoothstep(-16.0, 4.0, l.z))
	# devant l'étrave, la plage fait le tour du nez
	if l.x > 60.0:
		wzb = maxf(wzb, smoothstep(60.0, 74.0, l.x) * (1.0 - smoothstep(10.0, 28.0, l.z)))
	var wb: float = wxb * wzb
	if wb <= 0.0:
		return h
	return lerpf(h, maxf(h, bh) if l.x > 5.0 else bh, wb)


## Les mares de la forêt des brumes : des cuvettes sous le niveau du sol, une eau dormante.
func _dig_ponds() -> void:
	for p in PONDS:
		var c := Vector3(CENTER.x + cos(float(p[0])) * float(p[1]), 0.0, CENTER.z + sin(float(p[0])) * float(p[1]))
		var R: float = float(p[2])
		var lvl: float = height(c.x, c.z) - 0.35
		if lvl < 1.2:
			continue
		var cx: float = (c.x - GRID.x + HALF) / CELL
		var cz: float = (c.z - GRID.z + HALF) / CELL
		var reach: int = int(ceil((R + 9.0) / CELL)) + 1
		for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
			for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
				var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
				var i: int = zi * count + xi
				if d < R:
					heights[i] = minf(heights[i], lvl - 0.25 - 1.4 * (1.0 - pow(d / R, 2.0)))
				elif d < R + 9.0:
					heights[i] = lerpf(lvl + 0.08, heights[i], smoothstep(R, R + 9.0, d)) if heights[i] > lvl else heights[i]
		ponds_world.append([Vector3(c.x, lvl, c.z), R + 0.6])


## La terrasse devant la porte scellée.
func _door_terrace() -> void:
	var th: float = PI
	var base := Vector3(CENTER.x + cos(th) * DOOR_R, 0.0, CENTER.z + sin(th) * DOOR_R)
	var front := Vector3(CENTER.x + cos(th) * (DOOR_R + 4.0), 0.0, CENTER.z + sin(th) * (DOOR_R + 4.0))
	var y: float = height(front.x, front.z)
	_flatten(front.x, front.z, 7.0, 11.0, y)
	door_pos = Vector3(base.x, y, base.z)
	door_yaw = -th + PI * 0.5


func _flatten(wx: float, wz: float, radius: float, blend: float, target: float) -> void:
	var cx: float = (wx - GRID.x + HALF) / CELL
	var cz: float = (wz - GRID.z + HALF) / CELL
	var reach: int = int(ceil(blend / CELL)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			if d > blend:
				continue
			var k: float = smoothstep(radius, blend, d)
			var i: int = zi * count + xi
			heights[i] = lerpf(target, heights[i], k)


## La coque s'enfonce dans le sable : un bourrelet le long des flancs, et sous les ponts
## le sol reste sous le plancher de la cale (dans le bassin, sous l'eau).
func _bury_wreck() -> void:
	if epave == null:
		return
	var o: Vector3 = epave.origin
	var reach: float = epave.HL + 40.0
	var x0: int = maxi(0, int((o.x - reach - GRID.x + HALF) / CELL))
	var x1: int = mini(count - 1, int((o.x + reach - GRID.x + HALF) / CELL) + 1)
	var z0: int = maxi(0, int((o.z - reach - GRID.z + HALF) / CELL))
	var z1: int = mini(count - 1, int((o.z + reach - GRID.z + HALF) / CELL) + 1)
	for zi in range(z0, z1 + 1):
		var wz: float = GRID.z - HALF + zi * CELL
		for xi in range(x0, x1 + 1):
			var wx: float = GRID.x - HALF + xi * CELL
			var i: int = zi * count + xi
			var l: Vector3 = epave.Lc(Vector3(wx, heights[i], wz))
			var cx: float = clampf(l.x, -epave.HL, epave.HL)
			var pb: float = epave.plan(cx)
			var half: float = epave.HB * pb
			var az: float = absf(l.z)
			var pe: float = 0.45 + 0.55 * pow(maxf(0.0, cx / epave.HL), 1.5)
			var hl: float = 7.0
			if az < half and half > 0.01:
				hl = 7.0 * pow(az / half, 1.0 / pe)
			hl = minf(hl, 4.0)
			var out: float = Vector2(maxf(absf(l.x) - epave.HL, 0.0), maxf(az - half, 0.0)).length()
			if out > 30.0:
				continue
			var noise: float = _noise.get_noise_2d(wx * 5.0, wz * 5.0) * 0.3
			var target: float = (epave.W(Vector3(l.x, epave.keel(cx) + hl + 0.5 - out * 0.5 + noise, l.z)) as Vector3).y
			if out <= 0.0:
				var floor_y: float = maxf(epave.HOLD_Y, epave.keel(cx) + 0.4)
				var cap: float = (epave.W(Vector3(l.x, floor_y - 0.45, l.z)) as Vector3).y
				if cap < -0.2:
					cap -= 1.6          # le bassin (la cale noyée) : de l'eau pour les barques
				heights[i] = minf(maxf(heights[i], target), cap)
			else:
				heights[i] = maxf(heights[i], target)


# =================================================================== lecture du relief

func height(wx: float, wz: float) -> float:
	var fx: float = (wx - GRID.x + HALF) / CELL
	var fz: float = (wz - GRID.z + HALF) / CELL
	if fx < 0.0 or fz < 0.0 or fx >= count - 1 or fz >= count - 1:
		return -40.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - GRID.x) < HALF and absf(wz - GRID.z) < HALF


## Sur la terre ferme de la grande île (pas dans l'eau) ?
func on_land(wx: float, wz: float) -> bool:
	return contains(wx, wz) and height(wx, wz) > WATER


func slope(wx: float, wz: float) -> float:
	var e: float = 1.5
	var sx: float = absf(height(wx + e, wz) - height(wx - e, wz)) / (2.0 * e)
	var sz: float = absf(height(wx, wz + e) - height(wx, wz - e)) / (2.0 * e)
	return maxf(sx, sz)


func in_pond(wx: float, wz: float) -> bool:
	for p in ponds_world:
		var c: Vector3 = p[0]
		if Vector2(wx - c.x, wz - c.z).length() < float(p[1]):
			return true
	return false


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/grande_ile_v59.gdshader")
	var t := "res://assets/textures/"
	mat.set_shader_parameter("sand_tex", load(t + "terrain/sand.jpg"))
	mat.set_shader_parameter("sand_n", load(t + "terrain/sand_n.png"))
	mat.set_shader_parameter("grass_tex", load(t + "terrain/grass.jpg"))
	mat.set_shader_parameter("grass_n", load(t + "terrain/grass_n.png"))
	mat.set_shader_parameter("dry_tex", load(t + "azur/herbe_seche.png"))
	mat.set_shader_parameter("dry_n", load(t + "azur/herbe_seche_n.png"))
	mat.set_shader_parameter("moss_tex", load(t + "jungle/jungle_moss.png"))
	mat.set_shader_parameter("moss_n", load(t + "jungle/jungle_moss_n.png"))
	mat.set_shader_parameter("soil_tex", load(t + "jungle/jungle_soil.png"))
	mat.set_shader_parameter("rock_tex", load(t + "terrain/rock.jpg"))
	mat.set_shader_parameter("rock_n", load(t + "terrain/rock_n.png"))
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
			if top < -30.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Grande_ile_sol_%d_%d" % [cx, cz]
			mi.mesh = _chunk_mesh(x0, z0, x1, z1)
			mi.material_override = mat
			add_child(mi)


func _chunk_mesh(x0: int, z0: int, x1: int, z1: int) -> ArrayMesh:
	var w: int = x1 - x0 + 1
	var dpt: int = z1 - z0 + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	verts.resize(w * dpt)
	normals.resize(w * dpt)
	uvs.resize(w * dpt)
	cols.resize(w * dpt)
	for zi in range(z0, z1 + 1):
		for xi in range(x0, x1 + 1):
			var k: int = (zi - z0) * w + (xi - x0)
			var x: float = GRID.x - HALF + xi * CELL
			var z: float = GRID.z - HALF + zi * CELL
			verts[k] = Vector3(x, heights[zi * count + xi], z)
			var hl: float = heights[zi * count + maxi(xi - 1, 0)]
			var hr: float = heights[zi * count + mini(xi + 1, count - 1)]
			var hd: float = heights[maxi(zi - 1, 0) * count + xi]
			var hu: float = heights[mini(zi + 1, count - 1) * count + xi]
			normals[k] = Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
			uvs[k] = Vector2(x, z) * 0.21
			cols[k] = regions[zi * count + xi]
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
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Sol_grande_ile_v59"
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
	body.position = GRID


## L'eau dormante des mares (un disque à peine ridé, sombre, qui reflète le ciel).
func _build_ponds() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.07, 0.1, 0.08, 0.86)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic = 0.2
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/terrain/sand_n.png")
	m.normal_scale = 0.08
	m.uv1_scale = Vector3(4, 4, 4)
	for p in ponds_world:
		var c: Vector3 = p[0]
		var disc := CylinderMesh.new()
		disc.top_radius = float(p[1])
		disc.bottom_radius = float(p[1])
		disc.height = 0.02
		disc.radial_segments = 40
		disc.rings = 1
		var mi := MeshInstance3D.new()
		mi.name = "Mare_v59"
		mi.mesh = disc
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = c
		add_child(mi)


# =================================================================== la brume de l'est

## Des nappes de brume qui traînent entre les arbres de la forêt des brumes (et sur les mares) :
## de grands panneaux toujours tournés vers le regard, très transparents, fondus près du sol.
func _build_mist(high_quality: bool) -> void:
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	tex.gradient = g
	tex.width = 128
	tex.height = 128
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(0.86, 0.9, 0.88, 0.2)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.proximity_fade_enabled = true
	m.proximity_fade_distance = 4.0
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 2.0
	m.distance_fade_max_distance = 14.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var qm := QuadMesh.new()
	qm.size = Vector2(16.0, 7.0)
	qm.material = m
	var xfs: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5977
	var want: int = 420 if high_quality else 220
	var tries: int = 0
	while xfs.size() < want and tries < want * 20:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * 300.0
		var x: float = CENTER.x + cos(a) * r
		var z: float = CENTER.z + sin(a) * r
		if not contains(x, z) or region_at(x, z).b < 0.5:
			continue
		# V62 : pas de nappes posées au milieu de Ramure (le village a sa brume du matin)
		if Ramure.in_village(x, z):
			continue
		var h: float = height(x, z)
		if h < 0.5 or h > 40.0:
			continue
		var s: float = rng.randf_range(0.7, 1.5)
		xfs.append(Transform3D(Basis().scaled(Vector3(s, s * rng.randf_range(0.6, 1.0), s)), Vector3(x, h + rng.randf_range(1.2, 3.2) * s, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = qm
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Brume_foret_v59"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 420.0
	add_child(mmi)
	# au PC (brouillard volumétrique), de vraies nappes de brouillard au ras du sol
	if high_quality:
		var fm := FogMaterial.new()
		fm.density = 0.035
		fm.albedo = Color(0.88, 0.92, 0.9)
		fm.height_falloff = 0.25
		fm.edge_fade = 0.35
		for k in range(7):
			var a2: float = -0.75 + k * 0.25
			var r2: float = 175.0 + (k % 3) * 25.0
			var x2: float = CENTER.x + cos(a2) * r2
			var z2: float = CENTER.z + sin(a2) * r2
			if Ramure.in_village(x2, z2):
				continue
			var fv := FogVolume.new()
			fv.name = "Brouillard_brumes_%d" % k
			fv.size = Vector3(90.0, 14.0, 90.0)
			fv.material = fm
			fv.position = Vector3(x2, height(x2, z2) + 4.0, z2)
			add_child(fv)


# =================================================================== la porte scellée

var door_glow: StandardMaterial3D
var door_gate: Node3D                   # V63 : la porte (repère : +Z vers l'ouest)
var door_mobile: Node3D                 # V63 : vantaux, cercle et creux (ils s'enfoncent)
var door_leaves: Array = []
var door_sockets: Array = []            # V63 : centre des quatre creux (repère de la porte)


func _build_door() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://assets/textures/terrain/rock.jpg")
	stone.normal_enabled = true
	stone.normal_texture = load("res://assets/textures/terrain/rock_n.png")
	stone.uv1_triplanar = true
	stone.uv1_scale = Vector3(0.09, 0.09, 0.09)
	stone.albedo_color = Color(0.86, 0.83, 0.78)
	stone.roughness = 0.9
	var dark := stone.duplicate() as StandardMaterial3D
	dark.albedo_color = Color(0.5, 0.48, 0.45)
	door_glow = StandardMaterial3D.new()
	door_glow.albedo_color = Color(0.2, 0.3, 0.32)
	door_glow.emission_enabled = true
	door_glow.emission = Color(0.45, 0.85, 0.9)
	door_glow.emission_energy_multiplier = 0.9
	var gate := Node3D.new()
	gate.name = "Porte_scellee_v59"
	gate.position = door_pos
	gate.rotation.y = door_yaw
	add_child(gate)
	# repère de la porte : +Z vers l'extérieur (l'ouest), X le long de la façade
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	gate.add_child(body)
	var parts := [
		# [taille, position, matériau]
		[Vector3(4.2, 22.0, 5.0), Vector3(-9.4, 11.0 - 1.5, 0.0), stone],     # pilier gauche
		[Vector3(4.2, 22.0, 5.0), Vector3(9.4, 11.0 - 1.5, 0.0), stone],      # pilier droit
		[Vector3(24.0, 4.0, 5.6), Vector3(0.0, 20.5, 0.0), stone],            # linteau
		[Vector3(27.0, 2.0, 6.4), Vector3(0.0, 23.2, 0.0), dark],             # corniche
		[Vector3(26.0, 1.2, 12.0), Vector3(0.0, -0.9, 4.0), stone],           # parvis
		[Vector3(22.0, 0.6, 3.0), Vector3(0.0, -0.1, 8.8), stone],            # marche
	]
	# V63 : les deux vantaux, le grand cercle et les quatre creux sont à part : quand les quatre
	# sceaux sont posés, la porte s'enfonce dans le sol (voir sceaux_v63.gd)
	door_gate = gate
	door_mobile = Node3D.new()
	door_mobile.name = "Porte_mobile_v63"
	gate.add_child(door_mobile)
	door_leaves.clear()
	for s in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.name = "Vantail_%s" % ("gauche" if s < 0.0 else "droit")
		leaf.position = Vector3(s * 3.65, 9.2 - 1.0, -0.6)
		door_mobile.add_child(leaf)
		var lmi := MeshInstance3D.new()
		var lbm := BoxMesh.new()
		lbm.size = Vector3(7.2, 18.4, 1.2)
		lmi.mesh = lbm
		lmi.material_override = dark
		leaf.add_child(lmi)
		var lb := StaticBody3D.new()
		lb.collision_layer = 1
		lb.collision_mask = 0
		var lcs := CollisionShape3D.new()
		var lbs := BoxShape3D.new()
		lbs.size = Vector3(7.2, 18.4, 1.2)
		lcs.shape = lbs
		lb.add_child(lcs)
		leaf.add_child(lb)
		door_leaves.append(leaf)
	for p in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = p[0]
		mi.mesh = bm
		mi.material_override = p[2]
		mi.position = p[1]
		gate.add_child(mi)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = p[0]
		cs.shape = bs
		cs.position = p[1]
		body.add_child(cs)
	# le grand cercle gravé sur les deux vantaux et les quatre sceaux vides
	var ring := TorusMesh.new()
	ring.inner_radius = 5.0
	ring.outer_radius = 5.35
	ring.rings = 48
	ring.ring_segments = 6
	var rmi := MeshInstance3D.new()
	rmi.mesh = ring
	rmi.material_override = door_glow
	rmi.position = Vector3(0.0, 9.2, 0.02)
	rmi.rotation.x = PI * 0.5
	door_mobile.add_child(rmi)
	var seal_names := ["ouest", "nord", "est", "sud"]
	for k in range(4):
		var a: float = PI * 0.5 + k * PI * 0.5
		var socket := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.15
		cm.height = 0.5
		cm.radial_segments = 20
		socket.mesh = cm
		socket.material_override = stone
		socket.position = Vector3(cos(a) * 5.2, 9.2 + sin(a) * 5.2, 0.1)
		socket.rotation.x = PI * 0.5
		socket.name = "Sceau_vide_" + seal_names[k]
		door_mobile.add_child(socket)
		door_sockets.append(socket.position)
		var hole := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.6
		hm.bottom_radius = 0.6
		hm.height = 0.1
		hm.radial_segments = 16
		hole.mesh = hm
		hole.material_override = door_glow
		hole.position = socket.position + Vector3(0, 0, 0.22)
		hole.rotation.x = PI * 0.5
		door_mobile.add_child(hole)
	# la fente entre les deux vantaux, qui luit faiblement
	var slit := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.12, 18.0, 0.1)
	slit.mesh = sm
	slit.material_override = door_glow
	slit.position = Vector3(0.0, 8.2, 0.02)
	door_mobile.add_child(slit)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.85, 0.9)
	light.light_energy = 0.6
	light.omni_range = 14.0
	light.position = Vector3(0.0, 9.0, 3.0)
	gate.add_child(light)
	# des blocs tombés devant la porte
	var Rocks = load("res://scripts/rocks_v26.gd")
	var rm: Material = Rocks.material(Color(0.62, 0.6, 0.56), 0.25, 0.25)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5959
	for k in range(7):
		var mi2 := MeshInstance3D.new()
		var s: float = rng.randf_range(0.8, 2.2)
		mi2.mesh = Rocks.shape(5960 + k, Vector3(s * 1.4, s, s * 1.2), 0.9, 0.08)
		mi2.material_override = rm
		var side: float = -1.0 if k % 2 == 0 else 1.0
		mi2.position = Vector3(side * rng.randf_range(11.0, 15.0), -0.3, rng.randf_range(1.0, 9.0))
		mi2.rotation.y = rng.randf() * TAU
		gate.add_child(mi2)


## Le point devant la porte (monde), où le joueur peut l'examiner.
func door_front() -> Vector3:
	var out: Vector3 = Basis(Vector3.UP, door_yaw) * Vector3(0, 0, 7.0)
	return door_pos + out + Vector3.UP * 0.2

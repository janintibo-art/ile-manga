extends Node3D
## V70 : le relief de l'Île de Braise, la grande île volcanique du sud-ouest de l'archipel.
##  - au nord-est et au centre, Pandémonia, la méga-cité des démons, bâtie en cercles autour de
##    la Citadelle : le sommet (le Palais de l'Archiduchesse), le Cercle de Feu (un fossé de
##    lave et ses quatre ponts), la Haute-Ville (une terrasse ronde, son mur de soutènement), la
##    Basse-Ville (une terrasse plus large, le rempart de la ville) ; quatre grandes avenues
##    descendent de terrasse en terrasse par des rampes ;
##  - au nord-est, la Rade de Cendre : un bassin rond, ses quais, le port ;
##  - au sud-ouest, le Grand Brasier, un volcan de 150 m, son cratère de lave, deux coulées
##    qui descendent jusqu'à la mer ; à l'est du volcan, un champ de lave refroidie ;
##  - au pied du volcan, les sources de soufre ; au sud-est, le Bois de Cendre ; au nord-ouest,
##    sur les falaises, les Ruines de l'Ancien Pandémonium ; des plages de sable noir.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille ; une carte des sols (cendre, mousse, lave
## refroidie, pavés) est cuite en même temps pour le shader.

const CENTER := Vector3(-870.0, 0.0, 600.0)
const HALF: float = 380.0
const CELL: float = 1.6
const CHUNKS: int = 8
const WATER: float = -0.42
const TEX := "res://assets/textures/braise/"
## La mer autour de l'île : un cercle, et un chenal vers le nord-est (vers le reste de l'archipel).
const SEA_R: float = 400.0
const SEA_LANE := Rect2(320.0, -380.0, 300.0, 130.0)

## Pandémonia : le centre de la cité ; les cercles (rayons, m) et leurs hauteurs.
const CITY := Vector2(60.0, -60.0)
const CIT_R: float = 40.0              # le sommet de la Citadelle (plat)
const CIT_Y: float = 32.0
const MOAT_R0: float = 50.0            # le Cercle de Feu : le fossé de lave (le creux du relief)
const MOAT_R1: float = 66.0
const LAVA_R0: float = 52.4            # la lave elle-même, entre ses deux murs de pierre
const LAVA_R1: float = 63.6
const MOAT_FLOOR: float = 18.6
const MOAT_LAVA_Y: float = 20.4
const HAUTE_R1: float = 122.0          # le bord de la Haute-Ville (le mur de soutènement)
const HAUTE_Y: float = 24.0
const BASSE_R1: float = 190.0          # le rempart de la ville
const BASSE_Y: float = 12.0
## Les quatre grandes avenues (degrés : 0 = est, 90 = sud), des portes du rempart à la Citadelle.
const AVENUES := [-45.0, 45.0, 135.0, -135.0]
const AVENUE_NAMES := ["port", "jardins", "brasier", "cendres"]
## Les escaliers de la Citadelle : du bout des ponts (r = x, à la hauteur de la Haute-Ville) au
## sommet (r = y).
const STAIR_R := Vector2(47.8, 36.0)
## La rampe de la porte du port (de r = x, à la hauteur de la Basse-Ville, à r = y, sur le quai).
const PORT_RAMP := Vector2(193.5, 216.0)
## La Rade de Cendre : le bassin du port (centre, rayon) et la hauteur des quais.
const HARBOR := Vector2(251.0, -251.0)
const HARBOR_R: float = 50.0
const QUAY_Y: float = 2.4
## Le Grand Brasier
const VOLCANO := Vector2(-170.0, 170.0)
const VOLCANO_H: float = 150.0
const CRATER_R: float = 24.0
const CRATER_LAVA_Y: float = 104.0
## Les coulées de lave : du flanc du volcan (une bouche) jusqu'à la mer ; demi-largeurs.
const FLOWS := [
	[[Vector2(-206.0, 214.0), Vector2(-222.0, 236.0), Vector2(-236.0, 256.0), Vector2(-246.0, 280.0), Vector2(-252.0, 306.0)], 3.2],
	[[Vector2(-218.0, 160.0), Vector2(-244.0, 168.0), Vector2(-268.0, 180.0), Vector2(-292.0, 186.0), Vector2(-320.0, 190.0)], 2.8],
]
## Le champ de lave refroidie (à l'est du volcan, sur le chemin du cratère).
const LAVA_FIELD := Vector2(-62.0, 214.0)
const LAVA_FIELD_R: float = 62.0
## Les sources de soufre, au pied du volcan ; le Bois de Cendre ; les Ruines.
const SPRINGS := [Vector2(-26.0, 154.0), Vector2(-6.0, 166.0), Vector2(-30.0, 176.0)]
const SPRING_R: float = 6.0
const SPRING_Y: float = 7.6
const FOREST := Vector2(176.0, 196.0)
const FOREST_R: float = 92.0
const RUINS := Vector2(-236.0, -190.0)
const RUINS_R: float = 46.0
const RUINS_Y: float = 22.0
## Les Jardins de Cendre (dans la Basse-Ville, au sud-ouest, près des Thermes) : de la mousse au lieu des pavés.
const GARDENS := Vector2(-15.0, 81.0)
const GARDENS_R: float = 21.0
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur, longueur de la pente]
const PADS := {
	"ruines": [-236.0, -190.0, 34.0, 22.0, 26.0],
	"sources": [-20.0, 164.0, 24.0, 8.0, 18.0],
	"belvedere": [-84.0, 132.0, 6.0, 0.0, 10.0],
	"phare": [292.0, -214.0, 7.0, 2.4, 8.0],
	"clairiere": [170.0, 200.0, 12.0, 0.0, 14.0],
}
## Le ponton de la barque du joueur (boat_v29._make_dock), dans la Rade.
const DOCK_A := Vector2(214.0, -214.0)
const DOCK_B := Vector2(223.0, -223.0)
## Les chemins hors de la ville (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"volcan": [Vector2(-82.0, 82.0), Vector2(-66.0, 104.0), Vector2(-72.0, 122.0), Vector2(-84.0, 132.0)],
	"sources": [Vector2(-66.0, 104.0), Vector2(-40.0, 134.0), Vector2(-20.0, 160.0)],
	"champ": [Vector2(-66.0, 104.0), Vector2(-60.0, 140.0), Vector2(-60.0, 180.0), Vector2(-62.0, 212.0)],
	"bois": [Vector2(198.0, 78.0), Vector2(194.0, 112.0), Vector2(186.0, 146.0), Vector2(176.0, 178.0), Vector2(170.0, 200.0)],
	"ruines": [Vector2(-78.0, -198.0), Vector2(-112.0, -214.0), Vector2(-150.0, -220.0), Vector2(-186.0, -212.0), Vector2(-210.0, -200.0)],
	"plage_ouest": [Vector2(-78.0, -198.0), Vector2(-132.0, -150.0), Vector2(-196.0, -96.0), Vector2(-250.0, -50.0), Vector2(-296.0, -10.0)],
	"plage_sud": [Vector2(170.0, 200.0), Vector2(120.0, 250.0), Vector2(70.0, 296.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R cendre, G mousse, B lave refroidie, A pavés
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var flows_world: Array = []              # [Array[Vector3] (monde, la surface de la lave), demi-largeur]
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


## Un point de la cité en polaire autour de son centre (angle en degrés : 0 = est, 90 = sud).
static func polar(deg: float, r: float) -> Vector2:
	return CITY + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r


## Le même, dans le monde, à la hauteur y.
static func PW(deg: float, r: float, y: float) -> Vector3:
	var p: Vector2 = polar(deg, r)
	return W(p.x, p.y, y)


## L'angle (degrés, -180..180) et la distance d'un point (repère île) au centre de la cité.
static func city_polar(x: float, z: float) -> Vector2:
	var d := Vector2(x, z) - CITY
	return Vector2(rad_to_deg(atan2(d.y, d.x)), d.length())


static func _adiff(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return Vector2(p.distance_to(a + ab * t), t)


## La distance (repère île) à une coulée de lave et sa demi-largeur, ou INF.
static func flow_dist(x: float, z: float) -> Vector2:
	var best := Vector2(INF, 0.0)
	for f in FLOWS:
		var pts: Array = f[0]
		for i in range(pts.size() - 1):
			var s: Vector2 = _seg_dist(Vector2(x, z), pts[i], pts[i + 1])
			if s.x < best.x:
				best = Vector2(s.x, float(f[1]))
	return best


## Dans la ville (à l'intérieur du rempart) ?
static func in_city(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(CITY) < BASSE_R1


## Sur le quai du port (entre le rempart et la Rade, du côté du port) ?
static func on_quay_zone(x: float, z: float) -> bool:
	var cp: Vector2 = city_polar(x, z)
	return cp.y >= BASSE_R1 - 1.0 and absf(_adiff(cp.x, -45.0)) < 40.0 and Vector2(x, z).distance_to(HARBOR) > HARBOR_R - 1.0 and coast_q(x, z) < 1.04


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
	# les escaliers de la Citadelle (du pont au sommet). De la Haute-Ville à la Basse-Ville, les
	# avenues descendent par de grands escaliers sur arches (des viaducs : pandemonia_v70) ; la
	# rue Basse passe dessous : le sol reste plat.
	for i in range(AVENUES.size()):
		var a: float = float(AVENUES[i])
		_ramp(polar(a, STAIR_R.x), polar(a, STAIR_R.y), HAUTE_Y, CIT_Y, 3.4, 1.2)
	# de la porte du port au quai
	_ramp(polar(-45.0, PORT_RAMP.x), polar(-45.0, PORT_RAMP.y), BASSE_Y, QUAY_Y, 5.0, 3.0)
	# les sorties des autres portes : on descend doucement vers les chemins
	for a2 in [45.0, 135.0, -135.0]:
		var outp: Vector2 = polar(a2, BASSE_R1 + 20.0)
		var wo: Vector3 = W(outp.x, outp.y)
		_ramp(polar(a2, BASSE_R1 + 2.5), outp, BASSE_Y, height(wo.x, wo.z), 4.5, 4.0)
	# les dalles des chemins suivent le sol tel qu'il est au bout du compte
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	for f in FLOWS:
		var ptsf: Array = []
		var fpts: Array = f[0]
		for i5 in range(fpts.size() - 1):
			var a5: Vector2 = fpts[i5]
			var b5: Vector2 = fpts[i5 + 1]
			var n5: int = maxi(int(a5.distance_to(b5) / 2.0), 1)
			for k5 in range(n5):
				var p5: Vector2 = a5.lerp(b5, float(k5) / n5)
				var w5: Vector3 = W(p5.x, p5.y)
				ptsf.append(Vector3(w5.x, maxf(height(w5.x, w5.z) + 0.55, WATER + 0.1), w5.z))
		var pe: Vector2 = fpts[-1]
		var we: Vector3 = W(pe.x, pe.y)
		ptsf.append(Vector3(we.x, maxf(height(we.x, we.z) + 0.55, WATER + 0.1), we.z))
		flows_world.append([ptsf, float(f[1])])
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V70: Île de Braise ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 7001
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.009
	_detail.seed = 7002
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.035
	_coast.seed = 7003
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8
	_hills.seed = 7004
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hills.fractal_octaves = 3
	_hills.frequency = 0.014


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
static func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 345.0)
	var az: float = absf(z / 335.0)
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.1) + pow(az, 2.1), 1.0 / 2.1)
	var wob: float = 0.07 * sin(theta * 3.0 + 0.6) + 0.045 * sin(theta * 7.0 + 2.1) + 0.025 * sin(theta * 13.0 + 0.3)
	# le cap des Ruines au nord-ouest, la pointe du volcan au sud-ouest
	wob += -0.05 * exp(-pow(wrapf(theta - deg_to_rad(-140.0), -PI, PI) / 0.25, 2.0)) - 0.04 * exp(-pow(wrapf(theta - deg_to_rad(135.0), -PI, PI) / 0.3, 2.0))
	return q * (1.0 + wob)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.92, q) * 1.4
	else:
		var off: float = (q - 1.0) * 220.0
		coast = WATER + 0.35 - off * 0.22 - 44.0 * smoothstep(8.0, 34.0, off)
	coast = maxf(coast, -46.0)
	var inland: float = smoothstep(0.98, 0.78, q)
	var p := Vector2(x, z)
	# des collines de cendre et de mousse
	var base: float = 6.0 + _noise.get_noise_2d(x, z) * 6.0 + _detail.get_noise_2d(x, z) * 1.0
	var hills: float = 9.0 + _hills.get_noise_2d(x, z) * 10.0
	var land: float = maxf(base, hills * smoothstep(0.85, 0.55, q))
	# le Grand Brasier : un cône aux flancs ravinés, le cratère
	var dv: float = p.distance_to(VOLCANO) * (1.0 + _coast.get_noise_2d(x * 0.02, z * 0.02) * 0.06)
	var volc: float = volcano_cone(dv) * (1.0 + _detail.get_noise_2d(x * 1.7, z * 1.7) * 0.04)
	if dv < CRATER_R + 8.0:
		# le cratère : une lèvre de roche, puis la cuvette et son lac de lave
		var c8: float = volcano_cone(CRATER_R + 8.0)
		var rim_y: float = c8 + 8.0
		if dv > CRATER_R + 2.0:
			volc = lerpf(rim_y, c8, smoothstep(CRATER_R + 2.0, CRATER_R + 8.0, dv))
		else:
			volc = lerpf(CRATER_LAVA_Y - 2.5, rim_y, smoothstep(CRATER_R - 8.0, CRATER_R + 2.0, dv))
	land = maxf(land, volc)
	# les Ruines : un promontoire rocheux au nord-ouest
	var dr: float = p.distance_to(RUINS)
	if dr < RUINS_R + 40.0:
		land = maxf(land, lerpf(RUINS_Y + _detail.get_noise_2d(x, z) * 1.5, land, smoothstep(RUINS_R, RUINS_R + 40.0, dr)))
	var rough: float = (_noise.get_noise_2d(x * 2.3, z * 2.3) * 1.4 + _detail.get_noise_2d(x * 1.3, z * 1.3) * 0.7)
	var hn: float = coast + maxf(land * inland + rough * inland, 0.0)
	# les coulées : un lit creusé dans le flanc
	var fd: Vector2 = flow_dist(x, z)
	if fd.x < fd.y + 5.0:
		hn -= 1.6 * (1.0 - smoothstep(fd.y * 0.6, fd.y + 5.0, fd.x))
	# la cité : des cercles de terrasses
	var cp: Vector2 = city_polar(x, z)
	if cp.y < BASSE_R1 + 46.0:
		var cy: float = _city_y(cp.y)
		var kc: float = smoothstep(BASSE_R1, BASSE_R1 + 46.0, cp.y)
		hn = lerpf(cy, hn, kc)
	# le port : le quai (sur la terre ferme), la Rade
	var dh: float = p.distance_to(HARBOR)
	var qa: float = absf(_adiff(cp.x, -45.0))
	if cp.y > BASSE_R1 - 2.0 and qa < 50.0 and dh < HARBOR_R + 60.0:
		var kq: float = (1.0 - smoothstep(34.0, 50.0, qa)) * (1.0 - smoothstep(HARBOR_R + 34.0, HARBOR_R + 60.0, dh)) * (1.0 - smoothstep(0.985, 1.03, q))
		hn = lerpf(hn, QUAY_Y, kq * smoothstep(BASSE_R1 - 2.0, BASSE_R1 + 8.0, cp.y))
	if dh < HARBOR_R + 1.5:
		hn = minf(hn, lerpf(-7.5, QUAY_Y, smoothstep(HARBOR_R - 3.0, HARBOR_R + 1.5, dh)))
	# les sources de soufre : de petites vasques
	for sp in SPRINGS:
		var ds: float = p.distance_to(sp)
		if ds < SPRING_R + 4.0:
			hn = lerpf(SPRING_Y - 1.2, hn, smoothstep(SPRING_R - 2.0, SPRING_R + 4.0, ds))
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 34.0:
		hn = lerpf(-46.0, hn, smoothstep(3.0, 34.0, edge))
	return hn


## Le profil du Grand Brasier (sans le cratère) à la distance d de son centre.
static func volcano_cone(d: float) -> float:
	return VOLCANO_H * exp(-pow(d / 75.0, 1.4))


## La hauteur de la cité à la distance r de son centre (sans les rampes).
static func _city_y(r: float) -> float:
	if r < CIT_R:
		return CIT_Y
	if r < MOAT_R0:
		return lerpf(CIT_Y, MOAT_FLOOR + 3.0, smoothstep(CIT_R, MOAT_R0, r))
	if r < MOAT_R1:
		return MOAT_FLOOR
	if r < HAUTE_R1:
		return HAUTE_Y
	if r < HAUTE_R1 + 1.6:
		return lerpf(HAUTE_Y, BASSE_Y, (r - HAUTE_R1) / 1.6)
	return BASSE_Y


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


## Une rampe droite de a (hauteur ya) à b (hauteur yb), large de 2 × half_w, fondue dans le
## pays sur blend mètres de chaque côté.
func _ramp(a: Vector2, b: Vector2, ya: float, yb: float, half_w: float, blend: float) -> void:
	var ab: Vector2 = b - a
	var length: float = ab.length()
	var dir: Vector2 = ab / length
	var nrm := Vector2(-dir.y, dir.x)
	var reach: float = half_w + blend
	var x0: int = maxi(int((minf(a.x, b.x) - reach + HALF) / CELL), 0)
	var x1: int = mini(int((maxf(a.x, b.x) + reach + HALF) / CELL) + 1, count - 1)
	var z0: int = maxi(int((minf(a.y, b.y) - reach + HALF) / CELL), 0)
	var z1: int = mini(int((maxf(a.y, b.y) + reach + HALF) / CELL) + 1, count - 1)
	for zi in range(z0, z1 + 1):
		for xi in range(x0, x1 + 1):
			var p: Vector2 = Vector2(-HALF + xi * CELL, -HALF + zi * CELL) - a
			var t: float = p.dot(dir) / length
			if t < 0.0 or t > 1.0:
				continue
			var d: float = absf(p.dot(nrm))
			if d > reach:
				continue
			var y: float = lerpf(ya, yb, t)
			var i: int = zi * count + xi
			heights[i] = lerpf(y, heights[i], smoothstep(half_w, reach, d))


## La hauteur au bout d'un chemin : celle du lieu le plus proche (une porte de la ville : la
## Basse-Ville).
func _anchor_y(p: Vector2) -> float:
	if Vector2(p.x, p.y).distance_to(CITY) < BASSE_R1 + 12.0:
		return BASSE_Y
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
		# pas dans la cité : ses terrasses sont déjà à leur hauteur
		if not in_city(p2.x, p2.y):
			_flatten(w2.x, w2.z, 1.8, 6.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 320


## R : la cendre (le volcan, les chemins, le Bois de Cendre) ; G : la mousse (les creux, les
## jardins) ; B : la lave refroidie (le champ de lave, les bords des coulées, le cratère) ;
## A : les pavés (la cité, le quai).
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var dv: float = p.distance_to(VOLCANO)
			var ash: float = 1.0 - smoothstep(70.0, 120.0, dv + n * 18.0)
			ash = maxf(ash, (1.0 - smoothstep(FOREST_R * 0.6, FOREST_R, p.distance_to(FOREST) + n * 14.0)) * 0.75)
			ash = maxf(ash, (1.0 - smoothstep(RUINS_R * 0.6, RUINS_R + 10.0, p.distance_to(RUINS) + n * 10.0)) * 0.6)
			var moss: float = smoothstep(-0.25, 0.35, _noise.get_noise_2d(x * 1.4 + 31.0, z * 1.4)) * (1.0 - ash)
			var lava: float = 1.0 - smoothstep(LAVA_FIELD_R * 0.7, LAVA_FIELD_R, p.distance_to(LAVA_FIELD) + n * 16.0)
			var fd: Vector2 = flow_dist(x, z)
			lava = maxf(lava, 1.0 - smoothstep(fd.y + 2.0, fd.y + 9.0, fd.x + n * 3.0))
			lava = maxf(lava, 1.0 - smoothstep(CRATER_R + 6.0, CRATER_R + 18.0, dv + n * 5.0))
			var pave: float = 1.0 - smoothstep(BASSE_R1 - 1.0, BASSE_R1 + 2.0, p.distance_to(CITY))
			# le Cercle de Feu et la pente de la Citadelle : de la roche, pas de pavés
			var dc: float = p.distance_to(CITY)
			if dc > CIT_R + 1.0 and dc < MOAT_R1 + 0.5:
				pave = 0.0
			if on_quay_zone(x, z):
				pave = 1.0
			# les Jardins de Cendre, dans la Basse-Ville : de la mousse et des massifs
			var dg: float = p.distance_to(GARDENS)
			if dg < GARDENS_R + 2.0:
				var kg: float = 1.0 - smoothstep(GARDENS_R - 4.0, GARDENS_R + 2.0, dg + n * 3.0)
				pave = pave * (1.0 - kg)
				moss = maxf(moss, kg)
			moss *= (1.0 - pave) * (1.0 - lava)
			ash *= (1.0 - pave)
			biome.set_pixel(xi, zi, Color(ash, moss, lava * (1.0 - pave), pave))
	# les chemins : de la cendre tassée
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
						biome.set_pixel(ix, iz, Color(maxf(c.r, 0.85), c.g * 0.3, c.b * 0.5, c.a))


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
		return -46.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


## La mer de l'île (un cercle et un chenal vers le nord-est) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < SEA_R or SEA_LANE.has_point(l)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	var a: Vector2 = c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)
	var l: Vector2 = L(wx, wz)
	var b: Vector2 = Vector2(clampf(l.x, SEA_LANE.position.x + 0.5, SEA_LANE.end.x - 0.5), clampf(l.y, SEA_LANE.position.y + 0.5, SEA_LANE.end.y - 0.5)) + c
	return a if Vector2(wx, wz).distance_to(a) < Vector2(wx, wz).distance_to(b) else b


## Sur de la lave (le Cercle de Feu, une coulée, le lac du cratère) ? La hauteur de la lave, ou -INF.
func lava_at(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	var dc: float = l.distance_to(CITY)
	if dc > LAVA_R0 + 0.2 and dc < LAVA_R1 - 0.2:
		# les ponts passent au-dessus
		var cp: Vector2 = city_polar(l.x, l.y)
		var on_bridge: bool = false
		for a in AVENUES:
			var off: float = absf(_adiff(cp.x, float(a))) * PI / 180.0 * dc
			if off < 3.2:
				on_bridge = true
		if not on_bridge:
			return MOAT_LAVA_Y
	if l.distance_to(VOLCANO) < CRATER_R - 1.0:
		return CRATER_LAVA_Y
	var fd: Vector2 = flow_dist(l.x, l.y)
	if fd.x < fd.y - 0.3:
		return height(wx, wz) + 0.5
	return -INF


## Dans une vasque de soufre (l'eau chaude des sources) ?
func in_spring(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	for sp in SPRINGS:
		if l.distance_to(sp) < SPRING_R - 1.0:
			return true
	return false


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/braise_terrain_v70.gdshader")
	for k in ["mousse_braise", "cendre", "sable_noir", "basalte", "roche_volcan", "paves_basalte", "lave_croute", "soufre"]:
		var t: String = TEX + k + ".png"
		if ResourceLoader.exists(t):
			mat.set_shader_parameter(k + "_tex", load(t))
		var tn: String = TEX + k + "_n.png"
		if ResourceLoader.exists(tn):
			mat.set_shader_parameter(k + "_n", load(tn))
	var te: String = TEX + "lave_croute_e.png"
	if ResourceLoader.exists(te):
		mat.set_shader_parameter("lave_croute_e", load(te))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("volcano", Vector4(W(VOLCANO.x, 0.0).x, W(0.0, VOLCANO.y).z, CRATER_R, 120.0))
	var springs: Array = []
	for sp in SPRINGS:
		var w: Vector3 = W(sp.x, sp.y)
		springs.append(Vector4(w.x, w.z, SPRING_R + 5.0, 0.0))
	mat.set_shader_parameter("springs", springs)
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
			mi.name = "Braise_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_braise_v70"
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

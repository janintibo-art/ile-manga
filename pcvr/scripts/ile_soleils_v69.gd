extends Node3D
## V69 : le relief de l'Île des Trois Soleils, la grande île verte de l'ouest de l'archipel.
## Trois peuples y vivent, chacun sous son soleil :
##  - à l'est, l'Iterou, un fleuve au niveau de la mer, coule de la Cataracte jusqu'à son
##    delta ; sur sa rive nord, Per-Hâpy, le village égyptien (terrasse, quai, champs) ; sur la
##    rive sud, le plateau de Rê, désert, où se dressent la Pyramide de Rê et le Sphinx ;
##  - au nord, des collines couvertes de jungle ; sur une grande esplanade, Yaxché, la cité
##    maya, le Temple de Kukulkan, le jeu de balle, et plus loin le Cénote sacré ;
##  - au sud-ouest, le Lac de la Lune, perché au-dessus de la mer ; sur son île, Aztlán, la
##    cité aztèque, reliée au rivage par deux chaussées ; les chinampas (jardins flottants)
##    au sud et à l'ouest du lac ;
##  - à l'ouest, le Mont Fumant, un volcan ; au centre, les hautes terres et l'Autel des
##    Trois Soleils.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille. Une petite carte des sols (sable, jungle,
## limon, dallage) est cuite en même temps pour le shader.

const CENTER := Vector3(-960.0, 0.0, -150.0)
const HALF: float = 330.0
const CELL: float = 1.6
const CHUNKS: int = 8
const WATER: float = -0.42
const TEX := "res://assets/textures/soleils/"
## La mer autour de l'île : un cercle, et un chenal vers l'est (vers le reste de l'archipel).
const SEA_R: float = 345.0
const SEA_LANE := Rect2(240.0, -170.0, 300.0, 330.0)

## Le fleuve Iterou (au niveau de la mer) : de la Cataracte à la mer ; demi-largeurs.
const RIVER := [Vector2(66.0, 12.0), Vector2(95.0, 17.0), Vector2(125.0, 22.0), Vector2(160.0, 25.0), Vector2(195.0, 25.0),
	Vector2(230.0, 27.0), Vector2(262.0, 34.0), Vector2(292.0, 44.0), Vector2(336.0, 56.0)]
const RIVER_W := [9.0, 11.0, 12.5, 13.0, 13.0, 13.5, 16.0, 22.0, 30.0]
const RIVER_FLOOR: float = -2.7
const CATARACT := Vector2(60.0, 11.0)
## Per-Hâpy : la terrasse du village (x0, z0, largeur, profondeur) ; le quai au bord sud.
const TOWN_E := Rect2(148.0, -48.0, 96.0, 58.0)
const TOWN_E_Y: float = 2.2
const QUAY_E_Z: float = 10.0
## Le pont de bois sur l'Iterou (à l'ouest du village) et le gué de pierre de la chaussée.
const BRIDGE := [Vector2(134.0, 6.0), Vector2(134.0, 42.0)]
const BRIDGE_Y: float = 2.4
## La plaine d'inondation (les champs) sur la rive sud.
const FIELDS := Rect2(112.0, 40.0, 150.0, 34.0)
const FLOOD_Y: float = 0.95
## Le plateau de Rê : centre, rayon plat, hauteur ; la pyramide, le Sphinx, le temple de la vallée.
const PLATEAU := Vector2(195.0, 140.0)
const PLATEAU_R: float = 64.0
const PLATEAU_Y: float = 12.0
const PYRAMID := Vector2(200.0, 152.0)
const PYRAMID_BASE: float = 64.0
const PYRAMID_H: float = 41.0
const SPHINX := Vector2(176.0, 100.0)
const VALLEY := Vector2(200.0, 64.0)
## Yaxché : la grande esplanade (x0, z0, largeur, profondeur) ; le temple, le jeu de balle.
const PLAZA_M := Rect2(-72.0, -198.0, 134.0, 108.0)
const PLAZA_Y: float = 18.0
const KUKULKAN := Vector2(-20.0, -172.0)
const KUKULKAN_BASE: float = 44.0
const BALLCOURT := Vector2(34.0, -118.0)
const OBSERVATORY := Vector2(-56.0, -104.0)
const CENOTE := Vector2(-84.0, -222.0)
const CENOTE_R: float = 13.0
const CENOTE_Y: float = 6.0
## Le Lac de la Lune : centre, demi-axes, niveau ; Aztlán sur son île ; les chaussées.
const LAKE := Vector2(-125.0, 112.0)
const LAKE_AX := Vector2(98.0, 78.0)
const LAKE_Y: float = 6.0
const AZTLAN := Vector2(-125.0, 108.0)
const AZTLAN_R: float = 40.0
const AZTLAN_Y: float = 7.2
const TEMPLO := Vector2(-125.0, 98.0)
const CAUSEWAYS := [[Vector2(-125.0, 70.0), Vector2(-125.0, 26.0)], [Vector2(-87.0, 108.0), Vector2(-20.0, 108.0)]]
const CAUSEWAY_Y: float = 6.95
## Le Mont Fumant
const VOLCANO := Vector2(-238.0, -36.0)
const VOLCANO_H: float = 105.0
## Les hautes terres, l'Autel des Trois Soleils
const HIGHLANDS := Vector2(36.0, -46.0)
const ALTAR := Vector2(42.0, -52.0)
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur, longueur de la pente]
const PADS := {
	"autel": [42.0, -52.0, 9.0, 27.0, 18.0],
	"vallee": [200.0, 64.0, 9.0, 1.7, 8.0],
	"pyramide": [200.0, 152.0, 48.0, 12.0, 14.0],
	"sphinx": [176.0, 102.0, 12.0, 8.0, 10.0],
}
## L'enclos du Sphinx s'ouvre sur la plaine : la rampe, du fond de l'enclos au bas du plateau.
const SPHINX_RAMP := [Vector2(176.0, 93.0), Vector2(176.0, 66.0)]
## Le ponton de la barque du joueur (boat_v29._make_dock), au quai de Per-Hâpy.
const DOCK_A := Vector2(224.0, 10.0)
const DOCK_B := Vector2(224.0, 22.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"nord": [Vector2(150.0, -46.0), Vector2(126.0, -66.0), Vector2(100.0, -84.0), Vector2(80.0, -98.0), Vector2(63.0, -106.0)],
	"autel": [Vector2(100.0, -84.0), Vector2(78.0, -70.0), Vector2(58.0, -60.0), Vector2(48.0, -55.0)],
	"ouest": [Vector2(-73.0, -130.0), Vector2(-100.0, -110.0), Vector2(-128.0, -84.0), Vector2(-146.0, -52.0), Vector2(-142.0, -18.0), Vector2(-130.0, 8.0), Vector2(-125.0, 24.0)],
	"chaussee": [Vector2(200.0, 70.0), Vector2(200.0, 94.0), Vector2(200.0, 117.0)],
	"sud": [Vector2(-19.0, 108.0), Vector2(14.0, 100.0), Vector2(50.0, 84.0), Vector2(84.0, 66.0), Vector2(108.0, 52.0), Vector2(126.0, 44.0)],
	"rive_sud": [Vector2(142.0, 44.0), Vector2(162.0, 54.0), Vector2(184.0, 60.0), Vector2(194.0, 63.0)],
	"village_pont": [Vector2(147.0, -6.0), Vector2(138.0, 2.0), Vector2(134.0, 5.0)],
	"cenote": [Vector2(-66.0, -199.0), Vector2(-72.0, -206.0), Vector2(-76.0, -211.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R sable, G jungle, B limon, A dallage
var pads_world: Dictionary = {}          # nom -> Vector3 (monde, hauteur comprise)
var paths_world: Dictionary = {}         # nom -> Array[Vector3] (monde)
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _hills := FastNoiseLite.new()


# =================================================================== repère île

static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func _rect_dist(x: float, z: float, r: Rect2) -> float:
	var dx: float = maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return Vector2(p.distance_to(a + ab * t), t)


## Distance (repère île) à l'axe du fleuve, et demi-largeur du fleuve à cet endroit.
static func river(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best: float = INF
	var w: float = 10.0
	for i in range(RIVER.size() - 1):
		var r: Vector2 = _seg_dist(p, RIVER[i], RIVER[i + 1])
		if r.x < best:
			best = r.x
			w = lerpf(float(RIVER_W[i]), float(RIVER_W[i + 1]), r.y)
	# la source : au pied de la Cataracte, le fleuve s'arrête net
	if x < (RIVER[0] as Vector2).x:
		best = maxf(best, Vector2(x, z).distance_to(RIVER[0]))
	return Vector2(best, w)


## La position dans l'ellipse du lac (1 = le rivage).
static func lake_q(x: float, z: float) -> float:
	return Vector2((x - LAKE.x) / LAKE_AX.x, (z - LAKE.y) / LAKE_AX.y).length()


## Les chinampas : dans le secteur sud-ouest du lac, des planches de terre en longues bandes
## séparées par des canaux ; renvoie 1 sur une planche, 0 dans un canal, -1 hors du secteur.
static func chinampa(x: float, z: float) -> float:
	var q: float = lake_q(x, z)
	if q < 0.6 or q > 1.0:
		return -1.0
	var a: float = rad_to_deg(atan2((z - LAKE.y) / LAKE_AX.y, (x - LAKE.x) / LAKE_AX.x))
	if a < 0.0:
		a += 360.0
	if a < 62.0 or a > 222.0:
		return -1.0
	# des bandes nord-sud de 5 m, des canaux de 2,2 m ; des allées est-ouest tous les 26 m
	var u: float = fposmod(x + 300.0, 7.2)
	var v: float = fposmod(z + 300.0, 26.0)
	if u > 5.0 or v > 24.4:
		return 0.0
	return 1.0


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
	_flat_rect(TOWN_E, TOWN_E_Y, 12.0, true)
	_flat_rect(PLAZA_M, PLAZA_Y, 14.0, false)
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	# les talus des chemins ne mordent ni sur les terre-pleins, ni sur le village, ni sur la place
	for k3 in PADS:
		var p3: Array = PADS[k3]
		var w3: Vector3 = W(float(p3[0]), float(p3[1]))
		_flatten(w3.x, w3.z, float(p3[2]) - 0.5, float(p3[2]) + 1.0, float(p3[3]))
	_flat_rect(TOWN_E, TOWN_E_Y, 4.0, true)
	_flat_rect(PLAZA_M, PLAZA_Y, 4.0, false)
	# l'enclos du Sphinx s'ouvre au nord : une rampe taillée dans le rebord du plateau
	_ramp(SPHINX_RAMP[0], SPHINX_RAMP[1], float((PADS["sphinx"] as Array)[3]), 7.5, 6.0)
	_cenote()
	# les dalles des chemins suivent le sol tel qu'il est au bout du compte
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V69: île des Trois Soleils ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 6901
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.009
	_detail.seed = 6902
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_detail.fractal_octaves = 3
	_detail.frequency = 0.035
	_coast.seed = 6903
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8
	_hills.seed = 6904
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hills.fractal_octaves = 3
	_hills.frequency = 0.016


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 300.0)
	var az: float = absf((z - 4.0) / 284.0)
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.1) + pow(az, 2.1), 1.0 / 2.1)
	var wob: float = 0.11 * _coast.get_noise_2d(cos(theta) * 1.7, sin(theta) * 1.7) + 0.05 * _coast.get_noise_2d(cos(theta) * 5.0 + 9.0, sin(theta) * 5.0) + 0.025 * sin(theta * 7.0 + 1.1)
	# le cap du volcan à l'ouest, la pointe du delta à l'est
	wob += -0.06 * exp(-pow(wrapf(theta - PI, -PI, PI) / 0.22, 2.0)) - 0.05 * exp(-pow(wrapf(theta - 0.12, -PI, PI) / 0.18, 2.0))
	return q * (1.0 + wob)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.9, q) * 1.6
	else:
		var off: float = (q - 1.0) * 220.0
		coast = WATER + 0.35 - off * 0.2 - 46.0 * smoothstep(10.0, 34.0, off)
	coast = maxf(coast, -46.0)
	var inland: float = smoothstep(0.98, 0.74, q)
	var p := Vector2(x, z)
	# des prairies vallonnées
	var base: float = 4.5 + _noise.get_noise_2d(x, z) * 4.5 + _detail.get_noise_2d(x, z) * 0.9
	# au nord, les collines de la jungle
	var north: float = smoothstep(-40.0, -130.0, z)
	var hills: float = north * (13.0 + _hills.get_noise_2d(x, z) * 9.0 + _detail.get_noise_2d(x * 1.3, z * 1.3) * 1.4)
	# les hautes terres du centre
	var dh: float = p.distance_to(HIGHLANDS)
	var high: float = 25.0 * exp(-pow(dh / 105.0, 2.0)) * (1.0 + _noise.get_noise_2d(x * 1.7, z * 1.7) * 0.18)
	# le Mont Fumant : un cône aux flancs creusés, un cratère
	var dv: float = p.distance_to(VOLCANO) * (1.0 + _coast.get_noise_2d(x * 0.02, z * 0.02) * 0.08)
	var volc: float = VOLCANO_H * exp(-pow(dv / 66.0, 1.3))
	if dv < 18.0:
		volc -= 15.0 * pow(1.0 - dv / 18.0, 0.8)
	volc *= 1.0 + _detail.get_noise_2d(x * 1.8, z * 1.8) * 0.05
	var land: float = maxf(maxf(maxf(base, hills), high), volc)
	# le plateau de Rê : une table de calcaire, des falaises vers la mer
	var dp: float = p.distance_to(PLATEAU) * (1.0 + _coast.get_noise_2d(x * 0.03 + 4.0, z * 0.03) * 0.12)
	var flat: float = 0.0
	if dp < PLATEAU_R + 30.0:
		var kp: float = smoothstep(PLATEAU_R, PLATEAU_R + 30.0, dp)
		land = lerpf(PLATEAU_Y + _detail.get_noise_2d(x * 0.6, z * 0.6) * 0.25, land, kp)
		flat = maxf(flat, 1.0 - smoothstep(PLATEAU_R - 8.0, PLATEAU_R + 4.0, dp))
	# la plaine d'inondation : de part et d'autre du fleuve, à peine au-dessus de l'eau
	var rv: Vector2 = river(x, z)
	var flood: float = 1.0 - smoothstep(rv.y + 14.0, rv.y + 46.0, rv.x)
	var df: float = _rect_dist(x, z, FIELDS)
	flood = maxf(flood, 1.0 - smoothstep(0.0, 22.0, df))
	if x < 80.0:
		flood *= smoothstep(54.0, 80.0, x)
	land = lerpf(land, FLOOD_Y + _noise.get_noise_2d(x * 3.0, z * 3.0) * 0.25, flood * (1.0 - flat))
	flat = maxf(flat, flood * 0.8)
	# la Cataracte : les hautes terres finissent en falaise sur la source du fleuve
	var dc: float = p.distance_to(CATARACT)
	if dc < 30.0 and x < CATARACT.x + 4.0:
		land = maxf(land, lerpf(21.0, land, smoothstep(14.0, 30.0, dc)))
	var rough: float = (_noise.get_noise_2d(x * 2.3, z * 2.3) * 1.5 + _detail.get_noise_2d(x * 1.3, z * 1.3) * 0.8) * (1.0 - flat)
	var hn: float = coast + maxf(land * inland + rough * inland, 0.0)
	# le fleuve : un lit au niveau de la mer, des berges basses
	if rv.x < rv.y + 12.0:
		var bed: float = lerpf(RIVER_FLOOR, WATER + 0.25, smoothstep(rv.y * 0.55, rv.y, rv.x))
		var bank: float = lerpf(WATER + 0.25, hn, smoothstep(rv.y, rv.y + 12.0, rv.x))
		hn = minf(hn, bed if rv.x < rv.y else bank)
	# le Lac de la Lune, Aztlán, les chaussées, les chinampas
	hn = _lake(x, z, hn)
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 34.0:
		hn = lerpf(-46.0, hn, smoothstep(3.0, 34.0, edge))
	return hn


func _lake(x: float, z: float, hn: float) -> float:
	var lq: float = lake_q(x, z) * (1.0 + _coast.get_noise_2d(x * 0.05, z * 0.05) * 0.04)
	if lq > 1.45:
		return hn
	# le bassin : le pays monte autour du lac (il est perché au-dessus de la mer)
	var rim: float = maxf(hn, LAKE_Y + 1.1 + _noise.get_noise_2d(x * 2.0, z * 2.0) * 0.6)
	var h: float = lerpf(rim, hn, smoothstep(1.08, 1.45, lq))
	if lq < 1.0:
		var floor_y: float = lerpf(LAKE_Y - 2.4, LAKE_Y - 0.35, smoothstep(0.8, 0.98, lq))
		h = lerpf(floor_y, h, smoothstep(0.98, 1.06, lq))
		# les chinampas
		var c: float = chinampa(x, z)
		if c >= 0.0:
			var fade: float = smoothstep(0.6, 0.64, lq)
			var top: float = LAKE_Y + 0.42 if c > 0.5 else LAKE_Y - 0.14
			h = lerpf(h, top, fade)
	elif lq < 1.08:
		h = lerpf(LAKE_Y + 0.25, h, smoothstep(1.0, 1.08, lq))
	# l'île d'Aztlán
	var da: float = Vector2(x, z).distance_to(AZTLAN)
	if da < AZTLAN_R + 4.0:
		h = maxf(h, lerpf(AZTLAN_Y, LAKE_Y - 2.0, smoothstep(AZTLAN_R - 1.0, AZTLAN_R + 4.0, da)))
	# les chaussées
	for cw in CAUSEWAYS:
		var s: Vector2 = _seg_dist(Vector2(x, z), cw[0], cw[1])
		if s.x < 6.5:
			h = maxf(h, lerpf(CAUSEWAY_Y, LAKE_Y - 1.5, smoothstep(3.0, 6.5, s.x)))
	return h


## Le Cénote sacré : un puits rond aux parois à pic, l'eau verte au fond.
func _cenote() -> void:
	var c: Vector3 = W(CENOTE.x, CENOTE.y)
	var cx: float = (c.x - CENTER.x + HALF) / CELL
	var cz: float = (c.z - CENTER.z + HALF) / CELL
	var reach: int = int(ceil((CENOTE_R + 10.0) / CELL)) + 1
	var rim_y: float = height(c.x + CENOTE_R + 8.0, c.z)
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			var i: int = zi * count + xi
			if d < CENOTE_R:
				heights[i] = lerpf(CENOTE_Y - 3.0, CENOTE_Y - 0.4, smoothstep(CENOTE_R - 4.0, CENOTE_R - 0.3, d))
			elif d < CENOTE_R + 1.2:
				heights[i] = lerpf(CENOTE_Y + 0.5, rim_y, smoothstep(CENOTE_R, CENOTE_R + 1.2, d))
			elif d < CENOTE_R + 9.0:
				heights[i] = lerpf(rim_y, heights[i], smoothstep(CENOTE_R + 3.0, CENOTE_R + 9.0, d))


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


## Une rampe droite de a (à la hauteur ya) à b (à la hauteur du sol en b), large de 2 × half_w,
## fondue dans le pays sur blend mètres de chaque côté.
func _ramp(a: Vector2, b: Vector2, ya: float, half_w: float, blend: float) -> void:
	var wb: Vector3 = W(b.x, b.y)
	var yb: float = height(wb.x, wb.z)
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
			var y: float = lerpf(ya, yb, smoothstep(0.0, 1.0, t))
			var i: int = zi * count + xi
			heights[i] = lerpf(y, heights[i], smoothstep(half_w, reach, d))


## Un rectangle exactement plat (le village, l'esplanade), fondu dans le pays autour ; le
## village s'arrête net au sud, sur le quai du fleuve.
func _flat_rect(r: Rect2, y: float, blend: float, quay_south: bool) -> void:
	var x0: int = int((r.position.x - blend + HALF) / CELL)
	var x1: int = int((r.end.x + blend + HALF) / CELL) + 1
	var z0: int = int((r.position.y - blend + HALF) / CELL)
	var z1: int = int((r.end.y + blend + HALF) / CELL) + 1
	for zi in range(maxi(z0, 0), mini(z1, count - 1) + 1):
		for xi in range(maxi(x0, 0), mini(x1, count - 1) + 1):
			var x: float = -HALF + xi * CELL
			var z: float = -HALF + zi * CELL
			if quay_south and z > r.end.y:
				continue
			var d: float = _rect_dist(x, z, r)
			var k: float = smoothstep(0.5, blend, d)
			var i: int = zi * count + xi
			heights[i] = lerpf(y, heights[i], k)


## La hauteur au bout d'un chemin : celle du lieu le plus proche.
func _anchor_y(p: Vector2) -> float:
	if _rect_dist(p.x, p.y, TOWN_E) < 1.0:
		return TOWN_E_Y
	if _rect_dist(p.x, p.y, PLAZA_M) < 1.5:
		return PLAZA_Y
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
		var w: float = 0.55 * sin(PI * t)
		# jamais dans l'eau : au-dessus du fleuve et du lac, le chemin reste sur la berge
		prof.append(maxf(lerpf(lin, ground, w), 0.6))
	var out: Array = []
	for k in range(pts.size()):
		var p2: Vector2 = pts[k]
		var w2: Vector3 = W(p2.x, p2.y)
		_flatten(w2.x, w2.z, 1.8, 6.5, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 256


## R : le sable (le plateau de Rê, les dunes) ; G : la jungle (le nord) ; B : le limon (les
## berges du fleuve, les champs, le rivage du lac, les chinampas) ; A : le dallage (l'esplanade
## de Yaxché, Aztlán, la terrasse de Per-Hâpy).
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var dp: float = Vector2(x, z).distance_to(PLATEAU) + n * 10.0
			var sand: float = 1.0 - smoothstep(PLATEAU_R + 8.0, PLATEAU_R + 26.0, dp)
			var jungle: float = smoothstep(-50.0, -95.0, z + n * 18.0)
			jungle *= smoothstep(30.0, 70.0, Vector2(x, z).distance_to(VOLCANO) - 40.0)
			var rv: Vector2 = river(x, z)
			var silt: float = 1.0 - smoothstep(rv.y + 6.0, rv.y + 20.0, rv.x + n * 5.0)
			silt = maxf(silt, (1.0 - smoothstep(0.0, 6.0, _rect_dist(x, z, FIELDS))) * 0.9)
			var lq: float = lake_q(x, z)
			silt = maxf(silt, 1.0 - smoothstep(1.02, 1.12, lq + n * 0.03))
			var pave: float = 0.0
			pave = maxf(pave, 1.0 - smoothstep(-2.0, 3.0, _rect_dist(x, z, PLAZA_M) + n * 2.0))
			pave = maxf(pave, 1.0 - smoothstep(AZTLAN_R - 4.0, AZTLAN_R - 1.0, Vector2(x, z).distance_to(AZTLAN)))
			for cw in CAUSEWAYS:
				pave = maxf(pave, 1.0 - smoothstep(2.6, 3.4, _seg_dist(Vector2(x, z), cw[0], cw[1]).x))
			var town: float = 1.0 - smoothstep(-1.0, 4.0, _rect_dist(x, z, TOWN_E) + n * 3.0)
			sand = maxf(sand, town * 0.55)
			silt = maxf(silt * (1.0 - pave), town * 0.5)
			jungle *= (1.0 - pave) * (1.0 - sand)
			biome.set_pixel(xi, zi, Color(sand, jungle, silt, pave))


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


## La mer de l'île (un cercle et un chenal vers l'est) : on y nage, on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < SEA_R or SEA_LANE.has_point(l)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	var a: Vector2 = c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)
	var l: Vector2 = L(wx, wz)
	var b: Vector2 = Vector2(clampf(l.x, SEA_LANE.position.x + 0.5, SEA_LANE.end.x - 0.5), clampf(l.y, SEA_LANE.position.y + 0.5, SEA_LANE.end.y - 0.5)) + c
	return a if Vector2(wx, wz).distance_to(a) < Vector2(wx, wz).distance_to(b) else b


## Dans l'eau du lac (assez profonde pour qu'on n'y marche pas) ?
func in_lake_water(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	if lake_q(l.x, l.y) > 1.02:
		return false
	return height(wx, wz) < LAKE_Y - 0.22


## Dans l'eau du Cénote ?
func in_cenote(wx: float, wz: float) -> bool:
	return L(wx, wz).distance_to(CENOTE) < CENOTE_R - 0.3


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/soleils_terrain_v69.gdshader")
	for k in ["herbe", "jungle", "sable", "limon", "roche", "dalles_soleil"]:
		mat.set_shader_parameter(k + "_tex", load(TEX + k + ".png"))
		mat.set_shader_parameter(k + "_n", load(TEX + k + "_n.png"))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("plaza_m", Vector4(W(PLAZA_M.get_center().x, 0.0).x, W(0.0, PLAZA_M.get_center().y).z, PLAZA_M.size.x * 0.5, PLAZA_M.size.y * 0.5))
	mat.set_shader_parameter("volcano", Vector4(W(VOLCANO.x, 0.0).x, W(0.0, VOLCANO.y).z, 45.0, 140.0))
	mat.set_shader_parameter("lake_y", LAKE_Y)
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
			mi.name = "Soleils_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_soleils_v69"
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

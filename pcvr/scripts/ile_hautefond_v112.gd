extends Node3D
## V112 : le relief de l'Île de Hautefond, la cité-colonne, au sud-ouest de l'archipel (au sud de
## l'Île de Braise, à l'ouest de l'Île Al Dente). Une île ronde :
##  - au milieu, la Butte de Hautefond : la ville en terrasses rondes autour de la Grande Colonne
##    (la Place de la Colonne en haut, la Haute-Ville, la Ville-Moyenne, la Basse-Ville) ; les rues
##    montent en LACETS le long des murs de soutènement (RAMPS) ; pas de rempart : la Basse-Ville
##    s'ouvre sur la campagne par une pente douce ;
##  - au nord-est, le Port des Cordages : un bassin rond creusé dans la côte, son quai ; sur la
##    pointe, au nord, le Phare ;
##  - à l'est, la Plage des Galets Blonds ; à l'ouest, la colline du Moulin des Quatre Vents et son
##    petit bois ;
##  - au sud, les Vergers en terrasses (des marches de 2,5 m) ; au sud et à l'ouest, de hautes
##    FALAISES qui tombent droit dans la mer (les Arches et la Cascade : hautefond_dehors_v112).
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud) ; angles en
## degrés autour de la ville (0 = est, 90 = sud, -90 = nord).
## Même principe que l'Île de Montjoie : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille ; une carte des sols cuite pour le shader.

const CENTER := Vector3(-980.0, 0.0, 1420.0)
const HALF: float = 280.0
const CELL: float = 1.6
const CHUNKS: int = 7
const WATER: float = -0.42
const TEX := "res://assets/textures/montjoie/"
## La mer autour de l'île (un cercle) : on y nage, on y navigue.
const SEA_R: float = 360.0

## La Butte de Hautefond : les terrasses (rayons, m) et leurs hauteurs.
const TOWN := Vector2(0.0, 0.0)
const CORE_R: float = 36.0             # la Place de la Colonne (le sommet plat)
const CORE_Y: float = 36.0
const HAUTE_R: float = 80.0            # le bord de la Haute-Ville (son mur de soutènement)
const HAUTE_Y: float = 27.0
const MOY_R: float = 126.0             # le bord de la Ville-Moyenne
const MOY_Y: float = 17.0
const TOWN_R: float = 172.0            # le bord de la Basse-Ville
const BASSE_Y: float = 7.0
const GLACIS_R: float = 196.0          # au-delà, la campagne
const STEP: float = 1.6
## Les rampes en lacets : [rayon du mur, largeur, angle du bas, angle du haut, y bas, y haut].
const RAMPS := {
	"r1": [126.0, 7.0, 104.0, 74.0, 7.0, 17.0],
	"r1b": [126.0, 7.0, -150.0, -120.0, 7.0, 17.0],
	"r2": [80.0, 6.5, 22.0, -18.0, 17.0, 27.0],
	"r2b": [80.0, 6.5, 160.0, 200.0, 17.0, 27.0],
	"r3": [36.0, 6.5, -160.0, -250.0, 27.0, 36.0],
	"r3b": [36.0, 6.5, -20.0, 70.0, 27.0, 36.0],
}
## Les sorties de la ville (angles) : là où les rues descendent vers la campagne.
const GATES := {"port": -45.0, "est": 10.0, "verger": 95.0, "moulin": 180.0}
## Le Port des Cordages : le bassin (centre, rayon) et la hauteur du quai.
const HARBOR := Vector2(151.0, -151.0)
const HARBOR_R: float = 36.0
const QUAY_Y: float = 2.4
## La colline du Moulin des Quatre Vents (et son petit bois)
const MILL := Vector2(-202.0, -14.0)
const HILL_R: float = 46.0
const HILL_H: float = 9.0
const WOOD := Vector2(-176.0, 58.0)
const WOOD_R: float = 40.0
## Les Vergers en terrasses : entre ces angles, de ce rayon à la falaise
const ORCH_A := Vector2(52.0, 128.0)
const ORCH_R0: float = 190.0
## Les falaises : entre ces angles (degrés), la côte est haute et tombe droit dans la mer
const CLIFF_A := Vector2(40.0, 232.0)
## Le Phare de la Pointe (au nord, sur un cap)
const PHARE := Vector2(40.0, -250.0)
## La Cascade des Falaises : là où le ruisseau tombe de la falaise (repère île)
const CASCADE_DEG: float = 152.0
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : le sol), longueur de la pente]
const PADS := {
	"moulin": [-202.0, -14.0, 9.0, 0.0, 12.0],
	"phare": [40.0, -250.0, 8.0, 0.0, 9.0],
	"capitainerie": [196.0, -102.0, 10.0, QUAY_Y, 8.0],
	"belvedere_falaise": [-120.0, 196.0, 7.0, 0.0, 8.0],
}
## Le ponton de la barque du joueur (boat_v29._make_dock), dans le bassin du port.
const DOCK_A := Vector2(126.0, -126.0)
const DOCK_B := Vector2(135.0, -135.0)
## Les chemins hors de la ville (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"port": [Vector2(112.0, -112.0), Vector2(126.0, -108.0), Vector2(150.0, -100.0), Vector2(172.0, -98.0), Vector2(190.0, -104.0)],
	"phare": [Vector2(104.0, -142.0), Vector2(86.0, -180.0), Vector2(64.0, -218.0), Vector2(46.0, -242.0)],
	"plage": [Vector2(194.0, 34.0), Vector2(214.0, 40.0), Vector2(228.0, 48.0)],
	"moulin": [Vector2(-194.0, 0.0), Vector2(-198.0, -6.0)],
	"verger": [Vector2(-16.0, 196.0), Vector2(-20.0, 214.0), Vector2(-26.0, 228.0)],
	"falaise": [Vector2(-60.0, 186.0), Vector2(-90.0, 194.0), Vector2(-112.0, 196.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins, G terre des vergers, B sous-bois, A pavés
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


## Un point de la ville en polaire autour de son centre (angle en degrés : 0 = est, 90 = sud).
static func polar(deg: float, r: float) -> Vector2:
	return TOWN + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r


static func PW(deg: float, r: float, y: float) -> Vector3:
	var p: Vector2 = polar(deg, r)
	return W(p.x, p.y, y)


static func town_polar(x: float, z: float) -> Vector2:
	var d := Vector2(x, z) - TOWN
	return Vector2(rad_to_deg(atan2(d.y, d.x)), d.length())


static func _adiff(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)


static func in_arc(a: float, a0: float, a1: float) -> bool:
	return wrapf(a - a0, 0.0, 360.0) <= wrapf(a1 - a0, 0.0, 360.0)


## Dans la ville (la Basse-Ville comprise) ?
static func in_town(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(TOWN) < TOWN_R


static func ramp_t(key: String, deg: float) -> float:
	var r: Array = RAMPS[key]
	var span: float = _adiff(float(r[3]), float(r[2]))
	if absf(span) < 1.0:
		span = float(r[3]) - float(r[2])
	var t: float = _adiff(deg, float(r[2])) / span
	return t if t >= 0.0 and t <= 1.0 else -1.0


## L'écart (en degrés, signé) du haut au bas d'une rampe : une rampe peut tourner de plus de 90°.
static func ramp_span(key: String) -> float:
	var r: Array = RAMPS[key]
	return float(r[3]) - float(r[2])


## t de 0 à 1 le long d'une rampe (angles pris sans repli : une rampe peut faire plus de 180°).
static func ramp_t2(key: String, deg: float) -> float:
	var r: Array = RAMPS[key]
	var span: float = ramp_span(key)
	var d: float = wrapf(deg - float(r[2]), -180.0, 180.0) if absf(span) <= 180.0 else wrapf(deg - float(r[2]), -360.0 if span < 0.0 else 0.0, 0.0 if span < 0.0 else 360.0)
	var t: float = d / span
	return t if t >= 0.0 and t <= 1.0 else -1.0


static func ramp_at(x: float, z: float) -> String:
	var tp: Vector2 = town_polar(x, z)
	for k in RAMPS:
		var r: Array = RAMPS[k]
		if tp.y >= float(r[0]) - 0.2 and tp.y <= float(r[0]) + float(r[1]) and ramp_t2(str(k), tp.x) >= 0.0:
			return str(k)
	return ""


## La hauteur des terrasses à la distance r (sans les rampes) : la marche est sous le mur.
static func terrace_y(r: float) -> float:
	for e in [[CORE_R, CORE_Y, HAUTE_Y], [HAUTE_R, HAUTE_Y, MOY_Y], [MOY_R, MOY_Y, BASSE_Y]]:
		var r0: float = float(e[0]) - 2.0 * STEP
		if r < r0:
			return float(e[1])
		if r < r0 + STEP:
			return lerpf(float(e[1]), float(e[2]), (r - r0) / STEP)
	return BASSE_Y


## La hauteur de la ville (terrasses et rampes) en un point (repère île).
static func town_y(x: float, z: float) -> float:
	var tp: Vector2 = town_polar(x, z)
	var y: float = terrace_y(tp.y)
	for k in RAMPS:
		var r: Array = RAMPS[k]
		var r0: float = float(r[0])
		var w: float = float(r[1])
		if tp.y < r0 - STEP or tp.y > r0 + w + STEP:
			continue
		var t: float = ramp_t2(str(k), tp.x)
		if t < 0.0:
			continue
		var ry: float = lerpf(float(r[4]), float(r[5]), t)
		if tp.y <= r0 + w:
			y = maxf(y, ry)
		else:
			y = maxf(y, lerpf(ry, float(r[4]), (tp.y - r0 - w) / STEP))
	return y


static func on_quay_zone(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	var dh: float = p.distance_to(HARBOR)
	var a: float = _adiff(rad_to_deg((p - HARBOR).angle()), 135.0)
	return dh > HARBOR_R - 1.0 and dh < HARBOR_R + 24.0 and a > -95.0 and a < 95.0


## La falaise à cet angle (0 : côte basse, 1 : haute falaise).
static func cliff_k(deg: float) -> float:
	var a: float = wrapf(deg - CLIFF_A.x, 0.0, 360.0)
	var span: float = CLIFF_A.y - CLIFF_A.x
	if a > span + 30.0:
		return 0.0
	var k: float = smoothstep(0.0, 26.0, a) * (1.0 - smoothstep(span - 22.0, span + 6.0, a))
	return k


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
	print("ILE_MANGA_V112: Île de Hautefond ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 11201
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.009
	_detail.seed = 11202
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.04
	_hills.seed = 11204
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_hills.fractal_octaves = 3
	_hills.frequency = 0.05


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
static func coast_q(x: float, z: float) -> float:
	var theta: float = atan2(z, x)
	var r: float = Vector2(x / 246.0, z / 238.0).length()
	var wob: float = 0.035 * sin(theta * 3.0 + 0.7) + 0.025 * sin(theta * 5.0 + 2.1) + 0.012 * sin(theta * 11.0 + 0.4)
	# le cap du phare (au nord), la baie de la plage (à l'est)
	wob += -0.07 * exp(-pow(wrapf(theta - atan2(PHARE.y, PHARE.x), -PI, PI) / 0.16, 2.0))
	wob += 0.04 * exp(-pow(wrapf(theta - deg_to_rad(28.0), -PI, PI) / 0.22, 2.0))
	return r * (1.0 + wob)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var p := Vector2(x, z)
	var deg: float = rad_to_deg(atan2(z, x))
	var ck: float = cliff_k(deg)
	# le fond de la mer, et la côte : basse (plage, port) ou haute (falaise)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.93, q) * 1.6
	else:
		var off: float = (q - 1.0) * 240.0
		coast = WATER + 0.35 - off * 0.25 - 36.0 * smoothstep(6.0, 40.0, off)
		# au pied des falaises, l'eau est profonde tout de suite
		coast = minf(coast, lerpf(coast, -8.0 - off * 0.4, ck))
	coast = maxf(coast, -44.0)
	var inland: float = smoothstep(0.985, 0.82, q)
	# la campagne : de douces ondulations ; plus haute vers les falaises
	var land: float = 4.0 + _noise.get_noise_2d(x, z) * 3.4 + _detail.get_noise_2d(x, z) * 0.5
	land += ck * (10.0 + _noise.get_noise_2d(x * 0.7 + 40.0, z * 0.7) * 4.0)
	# la colline du moulin
	var dm: float = p.distance_to(MILL)
	land += HILL_H * exp(-pow(dm / HILL_R, 2.0))
	var hn: float = coast + maxf(land * inland, 0.0)
	# la falaise : à l'approche du rivage, la terre reste haute puis tombe d'un coup
	if ck > 0.02 and q > 0.9:
		var lip: float = smoothstep(0.955, 0.985, q)
		var face: float = 1.0 - smoothstep(0.985, 1.005, q)
		var cliff_top: float = maxf(land, 8.0) * (1.0 - lip * 0.08) + _hills.get_noise_2d(x, z) * 0.8
		var cliff_h: float = lerpf(coast, cliff_top, face)
		if q < 0.985:
			cliff_h = lerpf(hn, cliff_top, smoothstep(0.9, 0.96, q))
		hn = lerpf(hn, cliff_h, ck)
	# les vergers : des terrasses de 2,5 m qui descendent vers la falaise
	var tp: Vector2 = town_polar(x, z)
	var ok_a: float = smoothstep(ORCH_A.x, ORCH_A.x + 8.0, tp.x) * (1.0 - smoothstep(ORCH_A.y - 8.0, ORCH_A.y, tp.x))
	if ok_a > 0.0 and tp.y > ORCH_R0 - 10.0 and q < 0.95:
		var ring: float = (tp.y - ORCH_R0) / 9.0
		var step_i: float = floor(ring)
		var fr: float = ring - step_i
		var base_y: float = hn
		var stepped: float = 15.0 - step_i * 1.2
		stepped -= smoothstep(0.86, 1.0, fr) * 1.2
		var k_o: float = ok_a * smoothstep(ORCH_R0 - 10.0, ORCH_R0, tp.y) * (1.0 - smoothstep(0.91, 0.95, q))
		hn = lerpf(base_y, maxf(stepped, base_y * 0.6), k_o)
	# la Butte : les terrasses de la ville, et la pente douce (le glacis) vers la campagne
	if tp.y < GLACIS_R:
		var ty: float = town_y(x, z)
		if tp.y > TOWN_R:
			var kg: float = smoothstep(TOWN_R, GLACIS_R, tp.y)
			ty = lerpf(BASSE_Y, maxf(hn, 2.0), kg)
			hn = ty if kg < 0.98 else hn
		else:
			hn = ty
	# le port : le quai, le bassin
	var dh: float = p.distance_to(HARBOR)
	if dh < HARBOR_R + 46.0:
		# le quai : seulement du côté de la terre (le bassin s'ouvre sur la mer, vers le nord-est)
		var kq: float = 1.0 - smoothstep(HARBOR_R + 16.0, HARBOR_R + 46.0, dh)
		var side: float = _adiff(rad_to_deg((p - HARBOR).angle()), 135.0)
		var land_side: float = 1.0 - smoothstep(80.0, 110.0, absf(side))
		if (tp.y > TOWN_R + 2.0 or dh < HARBOR_R + 20.0) and q < 1.02:
			hn = lerpf(hn, QUAY_Y, kq * land_side)
		if dh < HARBOR_R + 1.5 and absf(side) <= 100.0:
			hn = minf(hn, lerpf(-7.0, QUAY_Y, smoothstep(HARBOR_R - 3.0, HARBOR_R + 1.5, dh)))
		elif dh < HARBOR_R + 1.5:
			hn = minf(hn, -7.0)
		elif absf(side) > 100.0 and dh < HARBOR_R + 30.0:
			# l'entrée du port : un chenal vers le large
			hn = minf(hn, lerpf(-7.0, hn, smoothstep(HARBOR_R + 6.0, HARBOR_R + 30.0, dh)))
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 34.0:
		hn = lerpf(-44.0, hn, smoothstep(3.0, 34.0, edge))
	return hn


static func _rect_soft(p: Vector2, r: Rect2, soft: float) -> float:
	var dx: float = maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
	var dz: float = maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
	return 1.0 - smoothstep(0.0, soft, Vector2(dx, dz).length())


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
		if Vector2(p2.x, p2.y).distance_to(TOWN) > TOWN_R + 4.0:
			_flatten(w2.x, w2.z, 1.8, 6.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 320


func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var tp: Vector2 = town_polar(x, z)
			var dirt: float = 1.0 - smoothstep(12.0, 18.0, p.distance_to(MILL) + n * 5.0)
			# les vergers : des bandes de terre au pied des rangées d'arbres
			var field: float = 0.0
			if in_arc(tp.x, ORCH_A.x + 6.0, ORCH_A.y - 6.0) and tp.y > ORCH_R0 + 2.0 and coast_q(x, z) < 0.92:
				var fr: float = fposmod(tp.y - ORCH_R0, 9.0)
				field = 1.0 if fr > 2.0 and fr < 6.4 else 0.0
			var forest: float = 1.0 - smoothstep(WOOD_R * 0.5, WOOD_R, p.distance_to(WOOD) + n * 14.0)
			var pave: float = 1.0 - smoothstep(TOWN_R + 2.0, TOWN_R + 5.0, tp.y)
			if on_quay_zone(x, z):
				pave = 1.0
			# les jardins de la Haute-Ville gardent un peu d'herbe (la promenade)
			if tp.y > 62.0 and tp.y < HAUTE_R - 5.0 and int(floor(tp.x / 22.5)) % 2 == 0:
				pave = 0.0
			forest *= (1.0 - pave)
			dirt *= (1.0 - pave)
			biome.set_pixel(xi, zi, Color(dirt, field * (1.0 - pave), forest, pave))
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
						biome.set_pixel(ix, iz, Color(maxf(c.r, 0.9), c.g * 0.2, c.b * 0.5, c.a))


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
		return -44.0
	var xi: int = int(fx)
	var zi: int = int(fz)
	var ux: float = fx - xi
	var uz: float = fz - zi
	var i: int = zi * count + xi
	return lerpf(lerpf(heights[i], heights[i + 1], ux), lerpf(heights[i + count], heights[i + count + 1], ux), uz)


func contains(wx: float, wz: float) -> bool:
	return absf(wx - CENTER.x) < HALF and absf(wz - CENTER.z) < HALF


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/montjoie_terrain_v71.gdshader")
	var texs := {"prairie": TEX + "prairie", "champ": TEX + "champ", "chemin": TEX + "chemin", "sous_bois": TEX + "sous_bois",
		"roche_crocs": TEX + "roche_crocs", "sable_lac": "res://assets/textures/terrain/sand", "paves": TEX + "paves"}
	for k in texs:
		for suf in [["_tex", ".png"], ["_n", "_n.png"]]:
			var t: String = str(texs[k]) + str(suf[1])
			if ResourceLoader.exists(t):
				mat.set_shader_parameter(str(k) + str(suf[0]), load(t))
			elif str(k) == "sable_lac" and ResourceLoader.exists(TEX + "sable_lac" + str(suf[1])):
				mat.set_shader_parameter(str(k) + str(suf[0]), load(TEX + "sable_lac" + str(suf[1])))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("lake", Vector4(CENTER.x + 5000.0, CENTER.z, 1.0, 1.0))
	mat.set_shader_parameter("lake_y", -100.0)
	mat.set_shader_parameter("town", Vector4(W(TOWN.x, TOWN.y).x, W(TOWN.x, TOWN.y).z, TOWN_R, 0.0))
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
			mi.name = "Hautefond_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_hautefond_v112"
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

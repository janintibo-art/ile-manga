extends Node3D
## V71 : le relief de l'Île de Montjoie, l'île des aventuriers, au sud-est de l'archipel.
##  - au centre, la Butte de Montjoie : une ville fortifiée sur une colline, en terrasses rondes
##    autour du Château (le sommet), la Haute-Ville, la Ville-Moyenne (la Grand-Place, la Guilde
##    des Aventuriers), la Basse-Ville et son rempart ; les rues montent en LACETS : des rampes qui
##    longent les murs de soutènement (rampes : RAMPS) ;
##  - au nord-ouest, le Port des Mouettes : un bassin rond, son quai ;
##  - au sud, les Champs du Sud (la ferme, le moulin) ; à l'est, le Lac des Grenouilles ; au
##    nord-est, le Bois des Lutins (le camp des gobelins) ; au sud-ouest, les Crocs (trois collines
##    rocheuses, les cristaux d'orage) et, à leur pied, l'entrée du Donjon des Mille Marches.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage,
## collision et height() lisent la même grille ; une carte des sols (chemins, champs, sous-bois,
## pavés) est cuite en même temps pour le shader.

const CENTER := Vector3(790.0, 0.0, 620.0)
const HALF: float = 360.0
const CELL: float = 1.6
const CHUNKS: int = 8
const WATER: float = -0.42
const TEX := "res://assets/textures/montjoie/"
## La mer autour de l'île : un cercle, et un chenal vers le nord (vers la mer de la grande île).
const SEA_R: float = 400.0
const SEA_LANE := Rect2(-60.0, -430.0, 200.0, 190.0)

## La Butte de Montjoie : le centre de la ville ; les terrasses (rayons, m) et leurs hauteurs.
const TOWN := Vector2(0.0, -30.0)
const CAST_R: float = 38.0             # le Château (le sommet plat)
const CAST_Y: float = 44.0
const HAUTE_R: float = 75.0            # le bord de la Haute-Ville (son mur de soutènement)
const HAUTE_Y: float = 32.0
const MOY_R: float = 118.0             # le bord de la Ville-Moyenne
const MOY_Y: float = 20.0
const BASSE_R: float = 158.0           # le rempart (de BASSE_R à WALL_R1)
const BASSE_Y: float = 9.0
const WALL_R1: float = 162.0
const GLACIS_R: float = 206.0          # au-delà, le pays
const STEP: float = 1.6                # la largeur de la marche d'une terrasse à l'autre
## Les rampes en lacets : [rayon du mur, largeur, angle du bas, angle du haut, y bas, y haut]
## (angles en degrés autour de TOWN : 0 = est, 90 = sud, -90 = nord).
const RAMPS := {
	"r1": [118.0, 7.0, 90.0, 60.0, 9.0, 20.0],
	"r1b": [118.0, 7.0, -130.0, -160.0, 9.0, 20.0],
	"r2": [75.0, 6.5, -10.0, -55.0, 20.0, 32.0],
	"r3": [38.0, 6.5, -100.0, -190.0, 32.0, 44.0],
}
## Les portes du rempart (angles) et la Grand-Place (de, à : angles ; Ville-Moyenne).
const GATES := {"nord": -130.0, "sud": 90.0, "est": 10.0}
const PLACE_A := Vector2(22.0, 58.0)
## Le Port des Mouettes : le bassin (centre, rayon) et la hauteur du quai.
const HARBOR := Vector2(-222.0, -212.0)
const HARBOR_R: float = 38.0
const QUAY_Y: float = 2.4
## Le Lac des Grenouilles (une ellipse perchée un peu au-dessus de la mer).
const LAKE := Vector2(238.0, 78.0)
const LAKE_AX := Vector2(58.0, 44.0)
const LAKE_Y: float = 3.2
## Le Bois des Lutins et le camp des gobelins
const FOREST := Vector2(178.0, -196.0)
const FOREST_R: float = 92.0
const CAMP := Vector2(206.0, -236.0)
## Les Champs du Sud
const FIELDS := Rect2(-96.0, 168.0, 160.0, 112.0)
const FARM := Vector2(-14.0, 214.0)
const MILL := Vector2(48.0, 236.0)
## Les Crocs : trois collines rocheuses [x, z, hauteur, rayon] ; les cristaux d'orage au sommet
const CROCS := [[-214.0, 152.0, 44.0, 50.0], [-170.0, 198.0, 32.0, 38.0], [-246.0, 98.0, 32.0, 38.0]]
## L'entrée du Donjon des Mille Marches (la tour en ruine) et la cabane d'Odon
const DUNGEON := Vector2(-168.0, 116.0)
## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : le sol), longueur de la pente]
const PADS := {
	"donjon": [-168.0, 116.0, 15.0, 0.0, 16.0],
	"ferme": [-14.0, 214.0, 26.0, 0.0, 18.0],
	"moulin": [48.0, 236.0, 8.0, 0.0, 12.0],
	"camp": [206.0, -236.0, 17.0, 0.0, 14.0],
	"croc_1": [-214.0, 152.0, 4.0, 0.0, 6.0],
	"croc_2": [-170.0, 198.0, 3.5, 0.0, 6.0],
	"croc_3": [-246.0, 98.0, 3.5, 0.0, 6.0],
	"phare": [-250.0, -238.0, 7.0, 2.4, 8.0],
}
## Le ponton de la barque du joueur (boat_v29._make_dock), dans le bassin du port.
const DOCK_A := Vector2(-206.0, -196.0)
const DOCK_B := Vector2(-214.0, -204.0)
## Les chemins hors de la ville (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"port": [Vector2(-114.0, -166.0), Vector2(-146.0, -184.0), Vector2(-176.0, -192.0), Vector2(-194.0, -190.0)],
	"champs": [Vector2(0.0, 150.0), Vector2(-4.0, 172.0), Vector2(-10.0, 192.0)],
	"moulin": [Vector2(10.0, 210.0), Vector2(30.0, 224.0), Vector2(42.0, 232.0)],
	"donjon": [Vector2(-8.0, 176.0), Vector2(-56.0, 166.0), Vector2(-104.0, 150.0), Vector2(-140.0, 130.0), Vector2(-156.0, 120.0)],
	"lac": [Vector2(176.0, 2.0), Vector2(184.0, 24.0), Vector2(186.0, 44.0)],
	"foret": [Vector2(176.0, 2.0), Vector2(188.0, -40.0), Vector2(194.0, -100.0), Vector2(198.0, -160.0), Vector2(204.0, -220.0)],
	"crocs": [Vector2(-104.0, 150.0), Vector2(-132.0, 168.0), Vector2(-160.0, 172.0), Vector2(-188.0, 164.0), Vector2(-210.0, 154.0)],
	"croc_sud": [Vector2(-210.0, 154.0), Vector2(-192.0, 178.0), Vector2(-174.0, 196.0)],
	"croc_ouest": [Vector2(-210.0, 154.0), Vector2(-230.0, 126.0), Vector2(-243.0, 102.0)],
	"plage": [Vector2(186.0, 44.0), Vector2(220.0, 140.0), Vector2(236.0, 200.0), Vector2(230.0, 250.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins, G champs labourés, B sous-bois, A pavés
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


## Un point de la ville en polaire autour de son centre (angle en degrés : 0 = est, 90 = sud).
static func polar(deg: float, r: float) -> Vector2:
	return TOWN + Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r


## Le même, dans le monde, à la hauteur y.
static func PW(deg: float, r: float, y: float) -> Vector3:
	var p: Vector2 = polar(deg, r)
	return W(p.x, p.y, y)


## L'angle (degrés, -180..180) et la distance d'un point (repère île) au centre de la ville.
static func town_polar(x: float, z: float) -> Vector2:
	var d := Vector2(x, z) - TOWN
	return Vector2(rad_to_deg(atan2(d.y, d.x)), d.length())


static func _adiff(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return Vector2(p.distance_to(a + ab * t), t)


## Dans la ville (à l'intérieur du rempart) ?
static func in_town(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(TOWN) < WALL_R1


## La position le long d'une rampe : t (0 en bas, 1 en haut) si l'angle est dans la rampe, sinon -1.
static func ramp_t(key: String, deg: float) -> float:
	var r: Array = RAMPS[key]
	var span: float = _adiff(float(r[3]), float(r[2]))
	var t: float = _adiff(deg, float(r[2])) / span
	return t if t >= 0.0 and t <= 1.0 else -1.0


## Dans la bande d'une rampe ? La clé, ou "".
static func ramp_at(x: float, z: float) -> String:
	var tp: Vector2 = town_polar(x, z)
	for k in RAMPS:
		var r: Array = RAMPS[k]
		if tp.y >= float(r[0]) - 0.2 and tp.y <= float(r[0]) + float(r[1]) and ramp_t(str(k), tp.x) >= 0.0:
			return str(k)
	return ""


## La hauteur des terrasses à la distance r (sans les rampes) : la marche (STEP mètres) est
## 1,6 m en deçà de chaque bord, sous le mur de soutènement (de bord - 3,4 à bord + 0,1), qui la
## couvre tout entière, avec les triangles du relief (cellules de 1,6 m) qui la débordent.
static func terrace_y(r: float) -> float:
	for e in [[CAST_R, CAST_Y, HAUTE_Y], [HAUTE_R, HAUTE_Y, MOY_Y], [MOY_R, MOY_Y, BASSE_Y]]:
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
		var t: float = ramp_t(str(k), tp.x)
		if t < 0.0:
			continue
		var ry: float = lerpf(float(r[4]), float(r[5]), t)
		if tp.y <= r0 + w:
			y = maxf(y, ry)
		else:
			# le bord extérieur de la rampe : la marche vers la terrasse du bas
			y = maxf(y, lerpf(ry, float(r[4]), (tp.y - r0 - w) / STEP))
	return y


## Sur le quai du port ?
static func on_quay_zone(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	var dh: float = p.distance_to(HARBOR)
	return dh > HARBOR_R - 1.0 and dh < HARBOR_R + 22.0 and _adiff(rad_to_deg((p - HARBOR).angle()), 40.0) > -80.0 and _adiff(rad_to_deg((p - HARBOR).angle()), 40.0) < 80.0


## La position dans l'ellipse du lac (1 = le rivage).
static func lake_q(x: float, z: float) -> float:
	return Vector2((x - LAKE.x) / LAKE_AX.x, (z - LAKE.y) / LAKE_AX.y).length()


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
	# les dalles des chemins suivent le sol tel qu'il est au bout du compte
	for k4 in paths_world:
		var pts4: Array = paths_world[k4]
		for i4 in range(pts4.size()):
			var q4: Vector3 = pts4[i4]
			pts4[i4] = Vector3(q4.x, height(q4.x, q4.z), q4.z)
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V71: Île de Montjoie ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 7101
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.008
	_detail.seed = 7102
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.035
	_coast.seed = 7103
	_coast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_coast.fractal_octaves = 3
	_coast.frequency = 0.8
	_hills.seed = 7104
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_hills.fractal_octaves = 3
	_hills.frequency = 0.03


## Rayon relatif de la côte (1 = le rivage) en (x, z) du repère île.
static func coast_q(x: float, z: float) -> float:
	var ax: float = absf(x / 318.0)
	var az: float = absf(z / 312.0)
	var theta: float = atan2(z, x)
	var q: float = pow(pow(ax, 2.2) + pow(az, 2.2), 1.0 / 2.2)
	var wob: float = 0.06 * sin(theta * 3.0 + 1.3) + 0.04 * sin(theta * 5.0 + 0.4) + 0.022 * sin(theta * 11.0 + 2.2)
	# la pointe du phare au nord-ouest, la baie du lac à l'est, le cap des Crocs au sud-ouest
	wob += -0.05 * exp(-pow(wrapf(theta - deg_to_rad(-135.0), -PI, PI) / 0.22, 2.0))
	wob += 0.05 * exp(-pow(wrapf(theta - deg_to_rad(22.0), -PI, PI) / 0.3, 2.0))
	wob += 0.05 * exp(-pow(wrapf(theta - deg_to_rad(145.0), -PI, PI) / 0.3, 2.0))
	return q * (1.0 + wob)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var coast: float
	if q < 1.0:
		coast = WATER + 0.35 + smoothstep(1.0, 0.92, q) * 1.6
	else:
		var off: float = (q - 1.0) * 220.0
		coast = WATER + 0.35 - off * 0.22 - 40.0 * smoothstep(8.0, 34.0, off)
	coast = maxf(coast, -44.0)
	var inland: float = smoothstep(0.98, 0.8, q)
	var p := Vector2(x, z)
	# de douces collines de prairie
	var land: float = 4.5 + _noise.get_noise_2d(x, z) * 4.5 + _detail.get_noise_2d(x, z) * 0.6
	# les Crocs : trois collines rocheuses, des arêtes
	for c in CROCS:
		var d: float = p.distance_to(Vector2(float(c[0]), float(c[1])))
		var hh: float = float(c[2]) * exp(-pow(d / float(c[3]), 2.0))
		if hh > 0.5:
			var ridge: float = (_hills.get_noise_2d(x, z) * 0.5 + 0.5)
			hh *= 0.82 + ridge * 0.32
			land = maxf(land, land * 0.3 + hh)
	var rough: float = _noise.get_noise_2d(x * 2.3, z * 2.3) * 0.9 + _detail.get_noise_2d(x * 1.3, z * 1.3) * 0.5
	var hn: float = coast + maxf(land * inland + rough * inland, 0.0)
	# les Champs du Sud : un plateau doux, presque plat
	var fk: float = _rect_soft(p, FIELDS, 30.0)
	if fk > 0.0:
		hn = lerpf(hn, 5.2 + _noise.get_noise_2d(x * 0.5, z * 0.5) * 1.2, fk * 0.85)
	# le lac : le pays monte un peu autour, le fond descend
	var lq: float = lake_q(x, z)
	if lq < 1.6:
		var rim: float = maxf(hn, LAKE_Y + 0.9 + _noise.get_noise_2d(x * 2.0, z * 2.0) * 0.5)
		var h: float = lerpf(rim, hn, smoothstep(1.15, 1.6, lq))
		if lq < 1.08:
			var floor_y: float = lerpf(LAKE_Y - 3.0, LAKE_Y - 0.4, smoothstep(0.75, 0.98, lq))
			h = lerpf(floor_y, LAKE_Y + 0.35, smoothstep(0.98, 1.08, lq))
		hn = h
	# la Butte : les terrasses de la ville, le rempart, le glacis
	var tp: Vector2 = town_polar(x, z)
	if tp.y < GLACIS_R:
		var ty: float = town_y(x, z)
		if tp.y > WALL_R1:
			# le glacis : de la Basse-Ville au pays, une pente régulière (et le ravin des portes)
			var kg: float = smoothstep(WALL_R1, GLACIS_R, tp.y)
			ty = lerpf(BASSE_Y, maxf(hn, 2.0), kg)
			hn = maxf(ty, hn) if kg < 0.98 else hn
		else:
			hn = ty
	# le port : le quai, le bassin
	var dh: float = p.distance_to(HARBOR)
	if dh < HARBOR_R + 40.0:
		var kq: float = 1.0 - smoothstep(HARBOR_R + 14.0, HARBOR_R + 40.0, dh)
		if q < 1.04:
			hn = lerpf(hn, QUAY_Y, kq)
		if dh < HARBOR_R + 1.5:
			hn = minf(hn, lerpf(-7.0, QUAY_Y, smoothstep(HARBOR_R - 3.0, HARBOR_R + 1.5, dh)))
	# au bord du carré, le relief rejoint le fond du large
	var edge: float = minf(HALF - absf(x), HALF - absf(z))
	if hn < 0.0 and edge < 34.0:
		hn = lerpf(-44.0, hn, smoothstep(3.0, 34.0, edge))
	return hn


## 1 au cœur d'un rectangle, 0 à plus de « soft » mètres de lui.
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


## La hauteur au bout d'un chemin : celle du lieu le plus proche (près de la ville : le glacis
## devant la porte).
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
		if Vector2(p2.x, p2.y).distance_to(TOWN) > WALL_R1 + 6.0 and lake_q(p2.x, p2.y) > 1.1:
			_flatten(w2.x, w2.z, 1.8, 6.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


# =================================================================== la carte des sols

const BIOME_RES: int = 360


## R : la terre battue (les chemins, la cour de la ferme, le camp) ; G : les champs labourés ;
## B : le sous-bois (le Bois des Lutins) ; A : les pavés (la ville, le quai).
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
			dirt = maxf(dirt, 1.0 - smoothstep(14.0, 22.0, p.distance_to(FARM) + n * 6.0))
			dirt = maxf(dirt, 1.0 - smoothstep(10.0, 18.0, p.distance_to(CAMP) + n * 5.0))
			dirt = maxf(dirt, 1.0 - smoothstep(9.0, 16.0, p.distance_to(DUNGEON) + n * 5.0))
			var field: float = 0.0
			if _rect_soft(p, FIELDS, 1.0) > 0.99:
				# des parcelles : des bandes, avec des haies d'herbe entre elles
				var cellx: float = fposmod(x - FIELDS.position.x, 40.0)
				var cellz: float = fposmod(z - FIELDS.position.y, 28.0)
				field = 1.0 if cellx > 2.5 and cellz > 2.0 else 0.0
				if p.distance_to(FARM) < 30.0 or p.distance_to(MILL) < 12.0:
					field = 0.0
			var forest: float = 1.0 - smoothstep(FOREST_R * 0.55, FOREST_R, p.distance_to(FOREST) + n * 16.0)
			var tp: Vector2 = town_polar(x, z)
			var pave: float = 1.0 - smoothstep(WALL_R1 - 1.0, WALL_R1 + 1.0, tp.y)
			if on_quay_zone(x, z):
				pave = 1.0
			# les jardins du château et de la Haute-Ville gardent un peu d'herbe
			if tp.y < CAST_R - 3.0 and _adiff(tp.x, 60.0) > -40.0 and _adiff(tp.x, 60.0) < 40.0 and tp.y > 14.0:
				pave = 0.0
			forest *= (1.0 - pave)
			dirt *= (1.0 - pave)
			biome.set_pixel(xi, zi, Color(dirt, field * (1.0 - pave), forest, pave))
	# les chemins : de la terre battue
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


## Dans l'eau du lac (assez profonde pour qu'on n'y marche pas) ?
func in_lake_water(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	if lake_q(l.x, l.y) > 1.1:
		return false
	return height(wx, wz) < LAKE_Y - 0.22


# =================================================================== maillage et collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/montjoie_terrain_v71.gdshader")
	for k in ["prairie", "champ", "chemin", "sous_bois", "roche_crocs", "sable_lac", "paves"]:
		var t: String = TEX + k + ".png"
		if ResourceLoader.exists(t):
			mat.set_shader_parameter(k + "_tex", load(t))
		var tn: String = TEX + k + "_n.png"
		if ResourceLoader.exists(tn):
			mat.set_shader_parameter(k + "_n", load(tn))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
	mat.set_shader_parameter("lake", Vector4(W(LAKE.x, LAKE.y).x, W(LAKE.x, LAKE.y).z, LAKE_AX.x, LAKE_AX.y))
	mat.set_shader_parameter("lake_y", LAKE_Y)
	mat.set_shader_parameter("town", Vector4(W(TOWN.x, TOWN.y).x, W(TOWN.x, TOWN.y).z, WALL_R1, 0.0))
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
			mi.name = "Montjoie_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_montjoie_v71"
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

extends Node3D
## V97 : le relief de l'Île Al Dente, au sud-ouest de l'archipel (entre l'Île du Boucan et Néopolis).
## Une île ronde dominée, au nord, par le Mont Bolognaise : un volcan dont le cratère (la Marmite) est
## plein de sauce tomate qui mijote. Par deux becs verseurs taillés dans le bord du cratère, la sauce
## coule en deux rivières : à l'est, jusqu'au Lac Napolitain (puis à la mer) ; au nord-ouest, jusqu'à la
## falaise, d'où elle tombe dans la mer (la Cascade Arrabbiata). Un chemin fait le tour du volcan en
## montant jusqu'au cratère.
## Au sud-ouest, sur un grand terre-plein : le Temple-Passoire (une passoire géante retournée, et, au-
## dessus, le Grand Spaghetti Volant) et son parvis. Au sud : la Plage du Parmesan (où l'on accoste),
## les Champs de Blé Dur, le Séchoir à pâtes, la Tomateraie ; à l'est, l'Oliveraie.
## Repère « île » : origine au CENTRE, axes du monde (x vers l'est, z vers le sud).
## Même principe que les autres îles : relief calculé une fois dans une grille ; maillage, collision et
## height() lisent la même grille ; deux cartes des sols sont cuites pour le shader.

const CENTER := Vector3(-420.0, 0.0, 1400.0)
const HALF: float = 190.0
const CELL: float = 1.5
const CHUNKS: int = 6
const WATER: float = -0.42
## La mer autour de l'île : un cercle qui rejoint celui de Néopolis, à l'est.
const SEA_R: float = 360.0
const R0: float = 150.0

## Le Mont Bolognaise : [x, z, rayon du bord du cratère, rayon de la base, hauteur du bord,
## fond du cratère, niveau de la sauce]
const VOLCAN := [5.0, -58.0, 24.0, 106.0, 56.0, 49.0, 53.2]
## Les deux becs verseurs (angles en degrés, 0 = est, 90 = sud) et les rivières de sauce (repère île),
## du bec à la mer.
const BECS := {"est": 0.0, "nord": 250.0}
const FLOWS := {
	"est": [Vector2(28.0, -58.0), Vector2(42.0, -52.0), Vector2(56.0, -43.0), Vector2(70.0, -31.0), Vector2(83.0, -17.0), Vector2(93.0, -1.0)],
	"nord": [Vector2(-3.2, -80.6), Vector2(-7.0, -91.0), Vector2(-12.0, -105.0), Vector2(-17.0, -119.0), Vector2(-21.0, -131.0), Vector2(-24.5, -140.5)],
}
## Le ruisseau qui sort du lac et rejoint la mer, à l'est
const DEVERSOIR := [Vector2(116.0, 16.0), Vector2(128.0, 19.0), Vector2(140.0, 22.0), Vector2(152.0, 25.0), Vector2(162.0, 27.0)]
## Le Lac Napolitain : [x, z, rayon] (son niveau : un peu sous le sol tout autour, voir lac_level)
const LAC := [102.0, 12.0, 15.0]
## Le chemin en spirale autour du volcan : [angle de départ, angle d'arrivée (degrés), rayon de départ, rayon d'arrivée]
const SPIRALE := [50.0, 215.0, 97.0, 25.5]

## Les terre-pleins : nom -> [x, z, rayon plat, hauteur (0 : celle du sol), longueur de la pente]
const PADS := {
	"temple": [-66.0, 34.0, 33.0, 6.5, 20.0],
	"carrefour": [0.0, 80.0, 7.0, 0.0, 9.0],
	"sechoir": [-34.0, 104.0, 9.0, 0.0, 8.0],
	"tomateraie": [38.0, 96.0, 11.0, 0.0, 8.0],
}
## Le Temple-Passoire : le centre de la passoire, son rayon, et vers où s'ouvre la porte
const PASSOIRE := Vector2(-74.0, 28.0)
const PASSOIRE_R: float = 15.0
const PORTE_DIR := Vector2(0.81, 0.586)
## Les champs : nom -> [x, z, demi-largeur, demi-profondeur, angle (radians)]
const CHAMPS := {
	"ble": [-74.0, 102.0, 24.0, 13.0, 0.22],
	"ble_2": [-118.0, 62.0, 15.0, 20.0, -0.3],
}
const PLAGE := Vector2(10.0, 136.0)
const DOCK_A := Vector2(22.0, 151.0)
const DOCK_B := Vector2(22.0, 173.0)
## Les chemins (repère île) ; le premier et le dernier point prennent la hauteur du lieu.
const PATHS := {
	"plage": [Vector2(22.0, 149.0), Vector2(18.0, 126.0), Vector2(10.0, 104.0), Vector2(3.0, 88.0)],
	"temple": [Vector2(-6.0, 76.0), Vector2(-20.0, 67.0), Vector2(-36.0, 57.0)],
	"volcan": [Vector2(6.0, 74.0), Vector2(24.0, 62.0), Vector2(44.0, 46.0), Vector2(58.0, 30.0), Vector2(66.0, 19.0)],
	"lac": [Vector2(44.0, 46.0), Vector2(62.0, 40.0), Vector2(78.0, 31.0), Vector2(87.0, 25.0)],
	"sechoir": [Vector2(4.0, 86.0), Vector2(-12.0, 96.0), Vector2(-25.0, 102.0)],
	"tomateraie": [Vector2(8.0, 84.0), Vector2(22.0, 90.0), Vector2(28.0, 93.0)],
}

var count: int = 0
var heights := PackedFloat32Array()
var biome: Image                         # R chemins (terre), G roche, B sable, A herbe rase (le parvis)
var biome2: Image                        # R la sauce séchée, G la cendre du volcan
var pads_world: Dictionary = {}
var paths_world: Dictionary = {}
var flows_world: Dictionary = {}         # nom -> Array[Vector3] (le fond du lit de la rivière)
var spiral_end := Vector3.ZERO           # le bout du chemin, au bord du cratère
var lac_level: float = 2.0               # le niveau de la sauce du Lac Napolitain
var terrain_mat: ShaderMaterial
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _hills := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func coast_r(theta: float) -> float:
	var r: float = R0 * (1.0 + 0.05 * sin(theta * 2.0 + 0.7) + 0.035 * sin(theta * 5.0 + 1.9) + 0.02 * sin(theta * 9.0 + 0.4))
	# la Plage du Parmesan, au sud : un peu plus large
	r += 9.0 * exp(-pow(wrapf(theta - PI * 0.5, -PI, PI) / 0.7, 2.0))
	return r


static func coast_q(x: float, z: float) -> float:
	return Vector2(x, z).length() / coast_r(atan2(z, x))


## La plage : le sud et l'est ; au nord et au nord-ouest, les falaises du volcan.
static func beach_k(x: float, z: float) -> float:
	var th: float = atan2(z, x)
	return clampf(0.55 + 0.75 * sin(th), 0.0, 1.0)


static func champ_at(x: float, z: float) -> String:
	for k in CHAMPS:
		var c: Array = CHAMPS[k]
		var d := Vector2(x - float(c[0]), z - float(c[1])).rotated(-float(c[4]))
		if absf(d.x) < float(c[2]) and absf(d.y) < float(c[3]):
			return str(k)
	return ""


static func volcan_d(x: float, z: float) -> float:
	return Vector2(x - float(VOLCAN[0]), z - float(VOLCAN[1])).length()


static func spiral_point(t: float) -> Vector2:
	var a: float = deg_to_rad(lerpf(float(SPIRALE[0]), float(SPIRALE[1]), t))
	# le rayon diminue vite en bas (là où la pente est douce), lentement en haut (là où elle est raide)
	var r: float = lerpf(float(SPIRALE[2]), float(SPIRALE[3]), pow(t, 0.62))
	return Vector2(float(VOLCAN[0]), float(VOLCAN[1])) + Vector2(cos(a), sin(a)) * r


static func spiral_lane() -> Array:
	var lane: Array = []
	for i in range(41):
		lane.append(spiral_point(float(i) / 40.0))
	return lane


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
	for k3 in CHAMPS:
		var c: Array = CHAMPS[k3]
		var wc: Vector3 = W(float(c[0]), float(c[1]))
		_flatten(wc.x, wc.z, maxf(float(c[2]), float(c[3])) * 0.8, maxf(float(c[2]), float(c[3])) + 10.0, height(wc.x, wc.z))
	# le belvédère au bord du cratère, au bout du chemin en spirale
	var se: Vector2 = spiral_point(1.0)
	var sw: Vector3 = W(se.x, se.y)
	_flatten(sw.x, sw.z, 4.0, 8.0, float(VOLCAN[4]) + 0.2)
	pads_world["belvedere"] = Vector3(sw.x, float(VOLCAN[4]) + 0.2, sw.z)
	for k2 in PATHS:
		_carve(str(k2), PATHS[k2])
	_carve("spirale", spiral_lane(), 0.45)
	var se2: Vector3 = (paths_world["spirale"] as Array)[-1]
	spiral_end = se2
	var lw: Vector3 = W(float(LAC[0]), float(LAC[1]))
	var lmin: float = 100.0
	for k4 in range(12):
		var a4: float = TAU * k4 / 12.0
		lmin = minf(lmin, height(lw.x + cos(a4) * (float(LAC[2]) + 3.0), lw.z + sin(a4) * (float(LAC[2]) + 3.0)))
	lac_level = lmin - 0.7
	for f in FLOWS:
		_dig_flow(str(f), FLOWS[f], true)
	_dig_flow("deversoir", DEVERSOIR, false)
	_dig_lac()
	_bake_biome()
	_build_mesh(high_quality)
	_build_collision()
	print("ILE_MANGA_V97: Île Al Dente ", count, "x", count, " en ", Time.get_ticks_msec() - t0, " ms")


func _setup_noise() -> void:
	_noise.seed = 9701
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = 0.012
	_detail.seed = 9702
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_octaves = 2
	_detail.frequency = 0.05
	_hills.seed = 9704
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_octaves = 3
	_hills.frequency = 0.02
	_ridge.seed = 9706
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 3
	_ridge.frequency = 0.035


## La hauteur du volcan seul (sans la côte).
func volcan_h(x: float, z: float) -> float:
	var d: float = volcan_d(x, z)
	var rim_r: float = float(VOLCAN[2])
	var base_r: float = float(VOLCAN[3])
	var rim_h: float = float(VOLCAN[4])
	var floor_h: float = float(VOLCAN[5])
	var th: float = atan2(z - float(VOLCAN[1]), x - float(VOLCAN[0]))
	if d < rim_r:
		# la Marmite : une cuvette ronde, un bord qui retombe un peu à l'intérieur
		var k: float = smoothstep(rim_r * 0.3, rim_r, d)
		return floor_h + (rim_h - floor_h) * pow(k, 1.6) + 0.6 * sin(PI * k) * k
	var t: float = clampf((d - rim_r) / (base_r - rim_r), 0.0, 1.0)
	var cone: float = rim_h * pow(1.0 - t, 1.4)
	# des ravines qui descendent du bord (plus marquées en haut)
	var gully: float = (_ridge.get_noise_2d(th * 26.0, d * 0.08) * 0.5 + 0.5) * 3.2 * (1.0 - t) * t * 4.0
	var bumps: float = _noise.get_noise_2d(x * 1.3, z * 1.3) * 1.6 * (1.0 - t)
	return maxf(cone - gully + bumps, 0.0)


func _shape(x: float, z: float) -> float:
	var q: float = coast_q(x, z)
	var bk: float = beach_k(x, z)
	var coast: float
	if q < 1.0:
		var cliff_h: float = 3.5 + 3.5 * (_hills.get_noise_2d(x * 0.7, z * 0.7) * 0.5 + 0.5)
		# au pied du volcan, les falaises de basalte sont bien plus hautes
		cliff_h += 9.0 * smoothstep(150.0, 95.0, volcan_d(x, z))
		var cliff: float = WATER + smoothstep(1.0, 0.975, q) * cliff_h
		var beach: float = WATER + 0.35 + smoothstep(1.0, 0.84, q) * 2.6
		coast = lerpf(cliff, beach, bk)
	else:
		var off: float = (q - 1.0) * R0
		coast = WATER + 0.35 - off * lerpf(0.9, 0.2, bk) - 30.0 * smoothstep(8.0, 36.0, off)
	coast = maxf(coast, -34.0)
	var inland: float = smoothstep(1.0, 0.9, q) if bk < 0.5 else smoothstep(0.97, 0.76, q)
	var land: float = 2.8 + 2.4 * (1.0 - q) + _noise.get_noise_2d(x, z) * 2.0 + (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * 2.6
	var rough: float = _detail.get_noise_2d(x * 1.5, z * 1.5) * 0.3
	var hn: float = coast + maxf(land + rough, 0.0) * inland
	# le Mont Bolognaise : il plonge dans la mer au nord (des falaises noires)
	var hv: float = volcan_h(x, z)
	if hv > 0.0:
		var keep: float = smoothstep(1.14, 0.99, q)
		var lift: float = maxf(land * 0.5, 0.0) * inland * smoothstep(float(VOLCAN[2]), float(VOLCAN[2]) + 20.0, volcan_d(x, z))
		hn = maxf(hn, lerpf(coast, coast + hv + 2.0, keep) if q > 0.99 else hv + lift)
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


## Un chemin : un ruban en pente régulière, lissé, d'un lieu à l'autre.
func _carve(name: String, lane: Array, follow: float = 0.92) -> void:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.5), 1)
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
		_flatten(w2.x, w2.z, 1.8, 5.0, float(prof[k]))
		out.append(Vector3(w2.x, float(prof[k]), w2.z))
	paths_world[name] = out


## Une rivière de sauce : un lit creusé, qui descend toujours. from_rim : elle part d'un bec
## verseur, taillé dans le bord du cratère jusque sous le niveau de la sauce.
func _dig_flow(name: String, lane: Array, from_rim: bool) -> void:
	var pts: Array = []
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var n: int = maxi(int(a.distance_to(b) / 1.2), 1)
		for k in range(n):
			pts.append(a.lerp(b, float(k) / n))
	pts.append(lane[-1])
	if from_rim:
		# le bec : de l'intérieur du cratère jusqu'au premier point
		var c := Vector2(float(VOLCAN[0]), float(VOLCAN[1]))
		var dir: Vector2 = ((pts[0] as Vector2) - c).normalized()
		var spout: Array = []
		for s in range(6):
			spout.append(c + dir * lerpf(float(VOLCAN[2]) * 0.55, float(VOLCAN[2]) - 0.6, float(s) / 5.0))
		pts = spout + pts
	# le sol d'avant (chaque point creusé abaisse aussi les voisins : on lit tout avant de creuser)
	var raw: Array = []
	for k0 in range(pts.size()):
		raw.append(_anchor_y(pts[k0]))
	var out: Array = []
	var prev: float = float(VOLCAN[6]) - 0.35 if from_rim else lac_level - 0.3
	for k in range(pts.size()):
		var p: Vector2 = pts[k]
		var w: Vector3 = W(p.x, p.y)
		var target: float = minf(prev - 0.04, float(raw[k]) - 1.5)
		if from_rim and k < 6:
			target = float(VOLCAN[6]) - 0.35 - 0.06 * k
		if name == "est":
			target = maxf(target, lac_level - 0.25)
		target = maxf(target, WATER - 1.2)
		prev = target
		var wid: float = 1.9 if from_rim else 1.3
		_dig(w.x, w.z, wid, wid + 3.4, target)
		out.append(Vector3(w.x, target, w.z))
	flows_world[name] = out


## Le Lac Napolitain : une cuvette ; la berge un peu plus haute que la sauce.
func _dig_lac() -> void:
	var mc: Vector3 = W(float(LAC[0]), float(LAC[1]))
	var r: float = float(LAC[2])
	var lvl: float = lac_level
	var cx: float = (mc.x - CENTER.x + HALF) / CELL
	var cz: float = (mc.z - CENTER.z + HALF) / CELL
	var reach: int = int(ceil((r + 8.0) / CELL)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(count, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(count, int(cx) + reach + 1)):
			var d: float = Vector2((xi - cx) * CELL, (zi - cz) * CELL).length()
			var i: int = zi * count + xi
			if d < r:
				heights[i] = minf(heights[i], lvl - 0.4 - 1.6 * sqrt(1.0 - d / r))
			elif d < r + 2.5:
				heights[i] = lerpf(lvl - 0.4, maxf(heights[i], lvl + 0.4), smoothstep(r, r + 2.5, d))
			elif d < r + 8.0:
				heights[i] = lerpf(maxf(heights[i], lvl + 0.4), heights[i], smoothstep(r + 2.5, r + 8.0, d))


# =================================================================== les cartes des sols

const BIOME_RES: int = 320


func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	biome2 = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = HALF * 2.0 / BIOME_RES
	var tp: Array = PADS["temple"]
	var tc := Vector2(float(tp[0]), float(tp[1]))
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var x: float = -HALF + (xi + 0.5) * px
			var z: float = -HALF + (zi + 0.5) * px
			var n: float = _noise.get_noise_2d(x * 3.0, z * 3.0)
			var p := Vector2(x, z)
			var q: float = coast_q(x, z)
			var bk: float = beach_k(x, z)
			var vd: float = volcan_d(x, z)
			var vt: float = clampf((vd - float(VOLCAN[2])) / (float(VOLCAN[3]) - float(VOLCAN[2])), 0.0, 1.0)
			var sand: float = bk * (1.0 - smoothstep(0.86, 0.8, q + n * 0.03))
			# la roche : le haut du volcan, les falaises
			var rock: float = maxf((1.0 - bk) * smoothstep(0.95, 0.99, q + n * 0.02), smoothstep(0.62, 0.38, vt + n * 0.12))
			var lawn: float = 1.0 - smoothstep(float(tp[2]) - 5.0, float(tp[2]) + 3.0, p.distance_to(tc) + n * 5.0)
			var dirt: float = 0.0
			var chp: String = champ_at(x, z)
			if chp != "":
				dirt = 0.4
			for k in ["sechoir", "tomateraie", "carrefour"]:
				var pd: Array = PADS[k]
				dirt = maxf(dirt, 0.55 * (1.0 - smoothstep(float(pd[2]) - 2.0, float(pd[2]) + 3.0, p.distance_to(Vector2(float(pd[0]), float(pd[1]))) + n * 4.0)))
			# la cendre : le volcan, de plus en plus gris vers le haut
			var ash: float = smoothstep(0.85, 0.3, vt + n * 0.15) * (1.0 if vd > float(VOLCAN[2]) - 1.0 else 0.6)
			biome.set_pixel(xi, zi, Color(dirt, rock, sand, lawn))
			biome2.set_pixel(xi, zi, Color(0.0, ash, 0.0, 0.0))
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
	# la sauce séchée : le long des rivières, autour du lac, dans la Marmite
	var stains: Array = []
	for f in flows_world:
		for fp in flows_world[f]:
			stains.append([L((fp as Vector3).x, (fp as Vector3).z), 4.8 if str(f) != "deversoir" else 3.6])
	stains.append([Vector2(float(LAC[0]), float(LAC[1])), float(LAC[2]) + 4.0])
	stains.append([Vector2(float(VOLCAN[0]), float(VOLCAN[1])), float(VOLCAN[2]) + 3.0])
	for s in stains:
		var c2: Vector2 = s[0]
		var r2: float = float(s[1])
		var ix0: int = int((c2.x - r2 + HALF) / px)
		var iz0: int = int((c2.y - r2 + HALF) / px)
		var ix1: int = int((c2.x + r2 + HALF) / px) + 1
		var iz1: int = int((c2.y + r2 + HALF) / px) + 1
		for iz2 in range(maxi(iz0, 0), mini(iz1, BIOME_RES)):
			for ix2 in range(maxi(ix0, 0), mini(ix1, BIOME_RES)):
				var pp := Vector2(-HALF + (ix2 + 0.5) * px, -HALF + (iz2 + 0.5) * px)
				var nn: float = _detail.get_noise_2d(pp.x * 4.0, pp.y * 4.0)
				var k2: float = 1.0 - smoothstep(r2 * 0.45, r2, pp.distance_to(c2) + nn * 1.6)
				var cc: Color = biome2.get_pixel(ix2, iz2)
				if k2 > cc.r:
					biome2.set_pixel(ix2, iz2, Color(k2, cc.g, cc.b, cc.a))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


func sauce_stain(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + HALF) / (HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome2.get_pixel(xi, zi).r if biome2 != null else 0.0


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


## Dans la sauce (le lac, la Marmite, le lit d'une rivière) ? Renvoie le niveau de la sauce, ou -INF.
func sauce_level(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	if l.distance_to(Vector2(float(LAC[0]), float(LAC[1]))) < float(LAC[2]) + 0.6:
		return lac_level
	if volcan_d(l.x, l.y) < float(VOLCAN[2]) - 0.5:
		var g: float = height(wx, wz)
		if g < float(VOLCAN[6]) + 0.05:
			return float(VOLCAN[6])
	for f in flows_world:
		var arr: Array = flows_world[f]
		var wid: float = 2.3 if str(f) != "deversoir" else 1.6
		for i in range(0, arr.size(), 2):
			var fp: Vector3 = arr[i]
			if Vector2(fp.x - wx, fp.z - wz).length() < wid:
				return fp.y + 0.45
	return -INF


static func sea_contains(wx: float, wz: float) -> bool:
	return L(wx, wz).length() < SEA_R


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var c := Vector2(CENTER.x, CENTER.z)
	return c + (Vector2(wx, wz) - c).limit_length(SEA_R - 0.5)


# =================================================================== maillage, collision

func _build_mesh(high_quality: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/pasta_terrain_v97.gdshader")
	var texs := {"herbe": "res://assets/textures/terrain/grass.jpg", "herbe_n": "res://assets/textures/terrain/grass_n.png",
		"herbe_seche": "res://assets/textures/boucan/herbe_seche.png", "herbe_seche_n": "res://assets/textures/boucan/herbe_seche_n.png",
		"roche": "res://assets/textures/braise/basalte.png", "roche_n": "res://assets/textures/braise/basalte_n.png",
		"cendre": "res://assets/textures/braise/cendre.png", "cendre_n": "res://assets/textures/braise/cendre_n.png",
		"sable": "res://assets/textures/terrain/sand.jpg", "sable_n": "res://assets/textures/terrain/sand_n.png",
		"terre": "res://assets/textures/boucan/terre_noire.png", "terre_n": "res://assets/textures/boucan/terre_noire_n.png"}
	for k in texs:
		if ResourceLoader.exists(texs[k]):
			mat.set_shader_parameter(k + ("" if str(k).ends_with("_n") else "_tex"), load(texs[k]))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome2", ImageTexture.create_from_image(biome2))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - HALF, CENTER.z - HALF, HALF * 2.0, HALF * 2.0))
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
			mi.name = "Al_dente_sol_%d_%d" % [cx, cz]
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
	body.name = "Sol_al_dente_v97"
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

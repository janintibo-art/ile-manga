extends Node3D
## V217 : l'Île Foraine devient un parc à thème : « le Parc du Volcan », au temps des dinosaures.
##
## - des massifs de plantes d'avant l'histoire (fougères arborescentes, cycas, grandes feuilles, bananiers,
##   fougères au sol, palmiers sur la côte), le long des allées, autour de la Place, au pied du volcan et
##   autour de chaque animal ; des blocs de basalte dans les massifs ;
## - des animaux de décoration, grandeur nature, comme dans un vrai parc : le Long-Cou (on passe sous son
##   ventre), Grosse-Dent qui rugit au bord du chemin du volcan, Corne-Sur-Nez et son petit, le
##   Dos-à-Plaques, trois raptors dans les fougères, deux Grand-Becs perchés sur des rochers, un nid et ses
##   œufs, un grand squelette à demi enterré. Chacun a son écriteau.
##
## Les animaux sont des sculptures : un seul maillage chacun (des fuseaux lisses, les couleurs peintes dans
## les sommets, une peau à écailles). Les plantes sont celles de la jungle (les mêmes maillages), en
## MultiMesh par carré de 180 m. Rien n'est posé sur une allée, sur un manège, ni à moins de 4,3 m de la
## voie du Grand Frisson.

const IleScript = preload("res://scripts/ile_foraine_v209.gd")
const Kit = preload("res://scripts/foraine_kit_v209.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const Animaux = preload("res://scripts/animaux_v75.gd")
const Trace = preload("res://scripts/grand_huit_trace_v209.gd")
const Flore = preload("res://scripts/jungle_flora_v30.gd")

const LIBRE: float = 4.3                  # rien à moins de 4,3 m de l'axe de la voie
const CARRE: float = 180.0                # les plantes sont rangées par carré (peu de carrés : peu d'appels de dessin)
const TEX := "res://assets/textures/jungle/"
## Les baraques, la gare, les manèges : [x, z, rayon] (on n'y plante rien)
const ZONES := [[-128.0, 9.0, 5.5], [-112.0, 9.0, 5.5], [-128.0, 31.0, 5.5], [-112.0, 31.0, 5.5], [-56.0, 9.0, 5.5], [-40.0, 9.0, 5.5],
	[-78.0, 66.0, 17.0], [36.0, 44.0, 20.0], [20.0, 158.0, 17.0], [-158.0, 20.0, 16.0], [-200.0, 20.0, 14.0]]
## Les animaux : [clé, nom, sous-titre, x, z (l'endroit souhaité), tourné (rad, par rapport à l'allée),
## l'arrière, l'avant (m, le long du corps), la hauteur, le rayon où rien ne pousse]
const ANIMAUX := [
	["long_cou", "LE LONG-COU", "brachiosaure", -84.0, 0.0, 1.25, 9.5, 7.8, 13.0, 2.6],
	["grosse_dent", "GROSSE-DENT", "tyrannosaure", -31.0, -10.0, 0.25, 6.8, 5.0, 5.4, 1.6],
	["corne", "CORNE-SUR-NEZ", "tricératops", -100.0, 46.0, 1.1, 4.4, 4.2, 3.5, 1.7],
	["plaques", "LE DOS-À-PLAQUES", "stégosaure", 60.0, 2.0, 1.25, 4.6, 3.9, 3.6, 1.5],
	["raptors", "LES RAPTORS", "ils chassent en bande", -5.0, 70.0, 0.3, 2.0, 1.6, 1.6, 0.7],
	["grand_bec", "LE GRAND-BEC", "ptéranodon", -46.0, 46.0, 0.0, 1.5, 1.5, 6.5, 2.0],
	["grand_bec2", "", "", 44.0, 98.0, 0.6, 1.5, 1.5, 6.5, 2.0],
	["squelette", "LES OS DU GÉANT", "trouvés en creusant le parc", -30.0, 62.0, 1.3, 5.5, 5.5, 2.4, 2.4],
]

var main: Node
var ile: Node3D
var pc: bool = true
var statues: Array = []                   # {cle, nom, pos (monde), cap, noeud, rayon}
var plantes: Dictionary = {}              # espèce -> combien
var massifs: int = 0
var blocs: int = 0
var triangles: int = 0                    # ceux des animaux
var au_plus_pres: float = 99.0            # l'animal le plus proche de l'axe de la voie (m)
var _rng := RandomNumberGenerator.new()
var _jf: Node3D
var _voie: Dictionary = {}                # carré de 4 m -> les points de la voie qui y passent
var _lots: Dictionary = {}                # "espèce#variante|cx|cz" -> [Transform3D]
var _peau_mat: StandardMaterial3D
var _os_mat: StandardMaterial3D
var _interdits: Array = []                # [x, z, rayon] : le corps des animaux
var _cols: GK.Cols
var _formes: Dictionary = {}              # "espèce#variante" -> son maillage (construit une fois)
var _taches_sol: Array = []               # [centre (repère île), rayon, force] : la terre et la mousse des massifs
var obstacles: Array = []                 # [centre (monde), rayon, hauteur] : ce qui arrête le promeneur (pour les essais)
var refusees_voie: int = 0                # plantes pas posées : trop près de la voie (leur couronne compte)
var refusees_vue: int = 0                 # plantes hautes pas posées : elles auraient caché un animal


func setup(main_node: Node, ile_node: Node3D, cols: GK.Cols) -> void:
	var t0: int = Time.get_ticks_msec()
	main = main_node
	ile = ile_node
	_cols = cols
	name = "Prehistoire_v217"
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 21701
	for p in Trace.tracer()["pts"]:
		var k := Vector2i(int(floor(p.x / 4.0)), int(floor(p.z / 4.0)))
		if not _voie.has(k):
			_voie[k] = []
		(_voie[k] as Array).append(p)
	_jf = Flore.new()
	_jf.name = "Outil_flore_v217"
	_jf.pc = pc
	add_child(_jf)
	_animaux()
	_massifs()
	_planter()
	_peindre_sol()
	var n: int = 0
	for e in plantes:
		n += int(plantes[e])
	print("ILE_MANGA_V217: le Parc du Volcan : %d animaux (%d triangles, au plus près à %.1f m de la voie), %d plantes en %d massifs, %d blocs de basalte, en %d ms" % [statues.size(), triangles, au_plus_pres, n, massifs, blocs, Time.get_ticks_msec() - t0])


# =================================================================== où poser

func _h(x: float, z: float) -> float:
	return float(ile.height_l(x, z))


## La distance (à plat) à la voie, pour les bouts de voie plus bas que « plafond »
func voie_a(x: float, z: float, plafond: float = 1e9, portee: float = 12.0) -> float:
	var best: float = 1e9
	var n: int = int(ceil(portee / 4.0))
	var cx: int = int(floor(x / 4.0))
	var cz: int = int(floor(z / 4.0))
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var k := Vector2i(cx + dx, cz + dz)
			if not _voie.has(k):
				continue
			for q in _voie[k]:
				if q.y > plafond:
					continue
				best = minf(best, Vector2(q.x - x, q.z - z).length())
	return best


## Le point de l'allée le plus proche
func allee_pres(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(x + 1.0, z)
	var bd: float = 1e9
	for c in IleScript.ALLEES:
		var pts: Array = c[0]
		for i in range(pts.size() - 1):
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(float(pts[i][0]), float(pts[i][1])), Vector2(float(pts[i + 1][0]), float(pts[i + 1][1])))
			if p.distance_to(q) < bd:
				bd = p.distance_to(q)
				best = q
	return best


func _lave(x: float, z: float) -> float:
	var px: float = float(IleScript.BIOME_RES - 1) / (IleScript.HALF * 2.0)
	var xi: int = clampi(int(round((x + IleScript.HALF) * px)), 0, IleScript.BIOME_RES - 1)
	var zi: int = clampi(int(round((z + IleScript.HALF) * px)), 0, IleScript.BIOME_RES - 1)
	return ile.biome.get_pixel(xi, zi).g


## Peut-on poser quelque chose de rayon r ici ? (ni allée, ni place, ni manège, ni lave, ni pente, ni voie)
func libre(x: float, z: float, r: float, pente_max: float = 0.45, plafond: float = 1e9, animaux_aussi: bool = true) -> bool:
	var p := Vector2(x, z)
	if p.length() > 176.0:
		return false
	var h: float = _h(x, z)
	if h < 1.5 or h > 26.0:
		return false
	var al: Vector2 = IleScript.allee_at(x, z)
	if al.x < al.y + 0.9 + r:
		return false
	if p.distance_to(IleScript.PLACE) < IleScript.PLACE_R + 1.2 + r:
		return false
	for zo in ZONES:
		if p.distance_to(Vector2(float(zo[0]), float(zo[1]))) < float(zo[2]) + r:
			return false
	if animaux_aussi:
		for it in _interdits:
			if p.distance_to(Vector2(float(it[0]), float(it[1]))) < float(it[2]) + r:
				return false
	if _lave(x, z) > 0.08:
		return false
	var e: float = maxf(r, 1.0)
	if absf(_h(x + e, z) - _h(x - e, z)) > pente_max * 2.0 * e or absf(_h(x, z + e) - _h(x, z - e)) > pente_max * 2.0 * e:
		return false
	if voie_a(x, z, plafond) < (LIBRE if plafond < 1e8 else 3.4) + r:
		return false
	return true


# =================================================================== les plantes

## Un obstacle (un cylindre : on ne traverse ni un tronc, ni une patte, ni un rocher)
func _col(at: Vector3, r: float, h: float) -> void:
	_cols.cyl(at, r, h)
	obstacles.append([at, r, h])


## La forme d'une plante (construite une fois) : « fougere_arbre#1 », « fougere »…
func _forme(espece: String) -> Mesh:
	if not _formes.has(espece):
		var sp: PackedStringArray = espece.split("#")
		_formes[espece] = _maillage(sp[0], int(sp[1]) if sp.size() > 1 else 0)
	return _formes[espece]


## Une plante, si elle a sa place : sa couronne reste à 4,3 m de l'axe de la voie (sauf là où la voie
## passe bien au-dessus d'elle), et une plante haute ne se met pas entre une allée et un animal.
func _ajoute(espece: String, x: float, z: float, echelle: float, enfonce: float = 0.05) -> bool:
	var bo: AABB = _forme(espece).get_aabb()
	var haut: float = maxf(bo.end.y, 0.3) * echelle
	var couronne: float = maxf(maxf(absf(bo.position.x), absf(bo.end.x)), maxf(absf(bo.position.z), absf(bo.end.z))) * echelle
	var sol: float = _h(x, z)
	if voie_a(x, z, sol + haut + LIBRE, LIBRE + couronne + 4.0) < LIBRE + couronne:
		refusees_voie += 1
		return false
	if _cache_la_vue(x, z, haut):
		refusees_vue += 1
		return false
	var w: Vector3 = IleScript.W(x, z, sol - enfonce)
	var key: String = "%s|%d|%d" % [espece, int(floor(x / CARRE)), int(floor(z / CARRE))]
	if not _lots.has(key):
		_lots[key] = []
	(_lots[key] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * echelle), w))
	var nom: String = espece.split("#")[0]
	plantes[nom] = int(plantes.get(nom, 0)) + 1
	return true


## Entre une allée et un animal (le couloir qui va du bord de l'allée le plus proche jusqu'à son corps,
## de plus en plus large), une plante plus haute que la moitié de l'animal le cacherait.
func _cache_la_vue(x: float, z: float, hauteur: float) -> bool:
	var p := Vector2(x, z)
	for st in statues:
		if not st.has("allee"):
			continue
		if hauteur < maxf(0.45 * float(st["haut"]), 0.9):
			continue
		var a: Vector2 = st["allee"]
		var b: Vector2 = st["ici"]
		var ab: Vector2 = b - a
		var l: float = ab.length()
		if l < 0.5:
			continue
		var t: float = (p - a).dot(ab) / (l * l)
		if t < -0.15 or t > 1.0:
			continue
		var w: float = lerpf(2.5, float(st["demi"]), clampf(t, 0.0, 1.0))
		if absf((p - a).cross(ab)) / l < w:
			return true
	return false


## Un massif : au milieu les grandes (fougères arborescentes, cycas), autour les feuilles, au bord les
## fougères basses ; un ou deux blocs de basalte.
func _massif(c: Vector2, rayon: float, lot: Kit.Lot, grand: bool = true) -> void:
	var k: float = 1.0 if pc else 0.6
	var faits: int = 0
	var n_grand: int = (_rng.randi_range(1, 3) if grand else 0)
	for i in range(n_grand):
		var p: Vector2 = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * rayon * 0.45
		if not libre(p.x, p.y, 0.5):
			continue
		if _rng.randf() < 0.55:
			if _ajoute("fougere_arbre#%d" % _rng.randi_range(0, 2), p.x, p.y, _rng.randf_range(0.95, 1.5), 0.1):
				_col(IleScript.W(p.x, p.y, _h(p.x, p.y)), 0.2, 2.6)
				faits += 1
		elif _ajoute("cycas#%d" % _rng.randi_range(0, 1), p.x, p.y, _rng.randf_range(0.9, 1.4), 0.1):
			_col(IleScript.W(p.x, p.y, _h(p.x, p.y)), 0.32, 1.4)
			faits += 1
	for i2 in range(int(round(_rng.randi_range(2, 4) * k))):
		var p2: Vector2 = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.2, 0.75) * rayon
		if not libre(p2.x, p2.y, 0.4):
			continue
		if _rng.randf() < 0.3:
			if _ajoute("bananier#%d" % _rng.randi_range(0, 2), p2.x, p2.y, _rng.randf_range(0.8, 1.15)):
				faits += 1
		elif _ajoute("cycas#%d" % _rng.randi_range(0, 1), p2.x, p2.y, _rng.randf_range(0.55, 0.85), 0.25):
			faits += 1
	for i3 in range(int(round(_rng.randi_range(5, 9) * k))):
		var p3: Vector2 = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.15, 0.95) * rayon
		if libre(p3.x, p3.y, 0.3) and _ajoute("oreille#%d" % _rng.randi_range(0, 2), p3.x, p3.y, _rng.randf_range(0.9, 1.6)):
			faits += 1
	for i4 in range(int(round(_rng.randi_range(12, 22) * k))):
		var p4: Vector2 = c + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * rayon * 1.15
		if libre(p4.x, p4.y, 0.1, 0.7) and _ajoute("fougere", p4.x, p4.y, _rng.randf_range(1.0, 1.9)):
			faits += 1
	if faits == 0:
		return
	massifs += 1
	# sous le massif, la terre et la mousse (plutôt que la cendre de l'esplanade)
	_taches_sol.append([c, rayon * 1.1, 1.0])
	for i5 in range(_rng.randi_range(0, 2)):
		var p5: Vector2 = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.6, 1.0) * rayon
		var rr: float = _rng.randf_range(0.35, 0.95)
		if not libre(p5.x, p5.y, rr):
			continue
		var w: Vector3 = IleScript.W(p5.x, p5.y, _h(p5.x, p5.y) + rr * 0.25)
		lot.blob("basalte", w, Vector3(rr, rr * _rng.randf_range(0.55, 0.85), rr * _rng.randf_range(0.75, 1.1)), 7, Basis(Vector3.UP, _rng.randf() * TAU))
		if rr > 0.6:
			_col(IleScript.W(p5.x, p5.y, _h(p5.x, p5.y)), rr * 0.8, rr * 1.0)
		blocs += 1


func _massifs() -> void:
	var lot := Kit.Lot.new()
	# autour de chaque animal : son décor
	# (derrière lui, vu de l'allée : un fond de verdure ; devant, rien de haut)
	for s in statues:
		if not s.has("allee"):
			continue
		var l: Vector2 = s["ici"]
		var loin: Vector2 = (l - (s["allee"] as Vector2)).normalized()
		var nb: int = 5 if str(s["cle"]) in ["long_cou", "grosse_dent"] else 4
		for i in range(nb):
			var a: float = atan2(loin.x, loin.y) + (float(i) - (nb - 1) * 0.5) * (TAU * 0.7 / nb) + _rng.randf_range(-0.15, 0.15)
			var d: float = float(s["demi"]) * 0.7 + _rng.randf_range(2.5, 5.0)
			_massif(l + Vector2(sin(a), cos(a)) * d, _rng.randf_range(3.5, 5.5), lot)
		_taches_sol.append([l, float(s["demi"]) + 2.0, 0.8])
	# le long des allées, des deux côtés
	for c in IleScript.ALLEES:
		var pts: Array = c[0]
		var demi: float = float(c[1])
		for i2 in range(pts.size() - 1):
			var a2 := Vector2(float(pts[i2][0]), float(pts[i2][1]))
			var b2 := Vector2(float(pts[i2 + 1][0]), float(pts[i2 + 1][1]))
			var dir: Vector2 = (b2 - a2).normalized()
			var lat := Vector2(-dir.y, dir.x)
			var s2: float = _rng.randf_range(3.0, 9.0)
			while s2 < a2.distance_to(b2):
				for cote in [-1.0, 1.0]:
					if _rng.randf() < 0.85:
						var r: float = _rng.randf_range(3.0, 5.0)
						_massif(a2 + dir * s2 + lat * cote * (demi + r + _rng.randf_range(1.0, 5.0)), r, lot)
				s2 += _rng.randf_range(8.0, 13.0)
	# autour de la Place
	for i3 in range(12):
		var a3: float = TAU * i3 / 12.0 + _rng.randf_range(-0.1, 0.1)
		_massif(IleScript.PLACE + Vector2(cos(a3), sin(a3)) * (IleScript.PLACE_R + _rng.randf_range(5.5, 8.0)), _rng.randf_range(3.5, 5.0), lot)
	# au pied du volcan
	for i4 in range(22):
		var a4: float = TAU * i4 / 22.0 + _rng.randf_range(-0.1, 0.1)
		_massif(IleScript.BUTTE + Vector2(cos(a4), sin(a4)) * (IleScript.VOLCAN_R + _rng.randf_range(-10.0, 9.0)), _rng.randf_range(4.0, 6.5), lot)
	# çà et là sur l'esplanade
	for i5 in range(42 if pc else 28):
		var p5: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * 160.0
		_massif(p5, _rng.randf_range(3.5, 6.0), lot)
	# des palmiers sur la côte
	var np: int = 0
	var garde: int = 0
	while np < (26 if pc else 18) and garde < 600:
		garde += 1
		var a6: float = _rng.randf() * TAU
		var p6: Vector2 = Vector2(cos(a6), sin(a6)) * _rng.randf_range(150.0, 174.0)
		if _h(p6.x, p6.y) < 1.8 or _h(p6.x, p6.y) > 4.5 or not libre(p6.x, p6.y, 0.8):
			continue
		if _ajoute("palmier#%d" % _rng.randi_range(0, 2), p6.x, p6.y, _rng.randf_range(0.85, 1.15), 0.15):
			_col(IleScript.W(p6.x, p6.y, _h(p6.x, p6.y)), 0.28, 4.0)
			np += 1
	lot.commit(self, "Blocs_v217", true, 320.0)


func _cycas(variante: int) -> ArrayMesh:
	var tronc: SurfaceTool = _jf._new_st()
	var palmes: SurfaceTool = _jf._new_st()
	var r := RandomNumberGenerator.new()
	r.seed = 21750 + variante
	var h: float = 0.9 + variante * 0.5
	_jf._tube(tronc, [Vector3(0, -0.3, 0), Vector3(0, h * 0.5, 0), Vector3(0, h, 0)], [0.3, 0.27, 0.22], [0.0, 0.02, 0.05], 9, Color(0.8, 0.72, 0.62), 0.9)
	for k in range(16):
		var a: float = TAU * k / 16.0 + r.randf_range(-0.12, 0.12)
		_jf._blade(palmes, Vector3(0, h, 0), Vector3(cos(a), 0, sin(a)), r.randf_range(1.6, 2.1), 0.46, 0.5, 0.7, 0.12, 7, 0.35)
	for k2 in range(9):
		var a2: float = TAU * k2 / 9.0 + 0.2 + r.randf_range(-0.15, 0.15)
		_jf._blade(palmes, Vector3(0, h, 0), Vector3(cos(a2), 0, sin(a2)), r.randf_range(1.2, 1.5), 0.36, 1.15, 0.55, 0.12, 6, 0.35)
	var feuille: ShaderMaterial = _jf._leaf_mat("cycas217", TEX + "palm_frond.png", "", 0.1, 0.4, 0.55)
	feuille.set_shader_parameter("tint", Color(0.72, 0.95, 0.66))
	return _jf._finish([[tronc, _jf._bark_mat("stipe", TEX + "palm_trunk.png", "")], [palmes, feuille]])


func _maillage(espece: String, variante: int) -> Mesh:
	match espece:
		"fougere_arbre":
			return _jf.tree_fern_mesh(variante)
		"cycas":
			return _cycas(variante)
		"bananier":
			return _jf.broadleaf_plant_mesh("bananier", variante)
		"oreille":
			return _jf.broadleaf_plant_mesh("oreille", variante)
		"palmier":
			return _jf.palm_mesh(variante, pc)
	return _jf.ground_mesh("fougere")


func _planter() -> void:
	var portee := {"fougere": 95.0, "oreille": 150.0, "bananier": 230.0, "cycas": 260.0, "fougere_arbre": 320.0, "palmier": 520.0}
	var faits: Dictionary = {}
	for key in _lots:
		var parts: PackedStringArray = str(key).split("|")
		var sp: PackedStringArray = parts[0].split("#")
		var espece: String = sp[0]
		if not faits.has(parts[0]):
			faits[parts[0]] = _forme(parts[0])
		var liste: Array = _lots[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = faits[parts[0]]
		mm.instance_count = liste.size()
		for i in range(liste.size()):
			mm.set_instance_transform(i, liste[i])
			var t: float = _rng.randf_range(0.86, 1.06)
			mm.set_instance_color(i, Color(t, t * _rng.randf_range(0.97, 1.05), t * 0.95))
		var inst := MultiMeshInstance3D.new()
		inst.name = ("Plantes_" + str(key)).replace("|", "_").replace("#", "_").replace("-", "m")
		inst.multimesh = mm
		inst.visibility_range_end = float(portee.get(espece, 200.0)) * (1.0 if pc else 0.8)
		inst.visibility_range_end_margin = 8.0
		inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		var ombre: bool = pc and espece in ["fougere_arbre", "cycas", "bananier", "palmier"]
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if ombre else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)
	_lots.clear()


## La terre et la mousse sous les massifs et autour des animaux : on peint la carte des sols de l'île
## (le bleu : la mousse, le rouge : la terre), puis le sol la reprend. Ni sur les allées, ni sur la lave.
func _peindre_sol() -> void:
	if ile == null or ile.get("biome") == null:
		return
	var img: Image = ile.biome
	var res: int = IleScript.BIOME_RES
	var px: float = IleScript.HALF * 2.0 / float(res - 1)
	var bruit := FastNoiseLite.new()
	bruit.seed = 2172
	bruit.frequency = 0.15
	for t in _taches_sol:
		var c: Vector2 = t[0]
		var r: float = float(t[1])
		var f: float = float(t[2])
		var x0: int = clampi(int(floor((c.x - r - 2.0 + IleScript.HALF) / px)), 0, res - 1)
		var x1: int = clampi(int(ceil((c.x + r + 2.0 + IleScript.HALF) / px)), 0, res - 1)
		var z0: int = clampi(int(floor((c.y - r - 2.0 + IleScript.HALF) / px)), 0, res - 1)
		var z1: int = clampi(int(ceil((c.y + r + 2.0 + IleScript.HALF) / px)), 0, res - 1)
		for zi in range(z0, z1 + 1):
			for xi in range(x0, x1 + 1):
				var x: float = -IleScript.HALF + xi * px
				var z: float = -IleScript.HALF + zi * px
				var d: float = Vector2(x, z).distance_to(c) + bruit.get_noise_2d(x, z) * 1.6
				var k: float = (1.0 - smoothstep(r * 0.5, r * 1.05, d)) * f
				if k <= 0.01:
					continue
				var al: Vector2 = IleScript.allee_at(x, z)
				k *= smoothstep(al.y + 0.4, al.y + 1.6, al.x)
				var col: Color = img.get_pixel(xi, zi)
				if col.a > 0.25 or col.g > 0.06 or k <= 0.01:
					continue
				col.b = maxf(col.b, k * 0.95)
				col.r = maxf(col.r, k * 0.3)
				img.set_pixel(xi, zi, col)
	var mat: Variant = ile.get("ground_mat")
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("biome", ImageTexture.create_from_image(img))


# =================================================================== les outils de sculpture

func _peau() -> StandardMaterial3D:
	if _peau_mat != null:
		return _peau_mat
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Animaux._noise_tex("dino217", 2171, 0.035, Vector2.ONE, false, 0.78, 1.0)
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/pirates/croco_n.png")
	m.normal_scale = 0.85
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.75, 0.75, 0.75)
	m.roughness = 0.74
	m.metallic_specular = 0.32
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_peau_mat = m
	return m


func _os() -> StandardMaterial3D:
	if _os_mat != null:
		return _os_mat
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = load("res://assets/textures/pirates/os.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/pirates/os_n.png")
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	m.roughness = 0.8
	_os_mat = m
	return m


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _fus(st: SurfaceTool, pts: Array, rx: Array, ry: Array, seg: int, colf: Callable, up: Vector3 = Vector3.UP, sub: int = 3) -> void:
	st.append_from(Animaux.loft(pts, rx, ry, seg, colf, 0.0, up, 0, sub), 0, Transform3D())


## Un fuseau le long de l'axe du corps : zs, ys (le milieu), rx (demi-largeur), ry (demi-hauteur)
func _corps(st: SurfaceTool, zs: Array, ys: Array, rx: Array, ry: Array, seg: int, colf: Callable, x: float = 0.0) -> void:
	var pts: Array = []
	for i in range(zs.size()):
		pts.append(Vector3(x, float(ys[i]), float(zs[i])))
	_fus(st, pts, rx, ry, seg, colf)


## Une patte : un chemin de haut en bas ([x, y, z, rayon]…), des deux côtés (x et -x)
func _pattes(st: SurfaceTool, chemin: Array, colf: Callable, plat: float = 0.85, seg: int = 12) -> void:
	for cote in [1.0, -1.0]:
		var pts: Array = []
		var rx: Array = []
		var ry: Array = []
		for c in chemin:
			pts.append(Vector3(float(c[0]) * cote, float(c[1]), float(c[2])))
			rx.append(float(c[3]) * plat)
			ry.append(float(c[3]))
		_fus(st, pts, rx, ry, seg, colf, Vector3.FORWARD)


func _boule(st: SurfaceTool, c: Vector3, r: float, col: Color, ry: float = -1.0) -> void:
	var f := func(_p: Vector3, _u: float, _a: float) -> Color: return col
	_fus(st, [c - Vector3(0, 0, r), c, c + Vector3(0, 0, r)], [0.0, r, 0.0], [0.0, r if ry < 0.0 else ry, 0.0], 8, f)


## Une corne, une dent, une griffe : pointue au bout (des deux côtés si miroir)
func _corne(st: SurfaceTool, pts: Array, r0: float, r1: float, col: Color, miroir: bool = false, seg: int = 7) -> void:
	var f := func(_p: Vector3, _u: float, _a: float) -> Color: return col
	st.append_from(Animaux.tube(pts, r0, r1, 8, seg, f, Vector3.UP, 1.0), 0, Transform3D())
	if miroir:
		var m: Array = []
		for p in pts:
			m.append(Vector3(-(p as Vector3).x, (p as Vector3).y, (p as Vector3).z))
		st.append_from(Animaux.tube(m, r0, r1, 8, seg, f, Vector3.UP, 1.0), 0, Transform3D())


## La robe d'un corps : le dos plus sombre, le ventre clair, des raies en travers du dos (f : leur pas)
func _robe(base: Color, dos: Color, ventre: Color, raie: Color, f: float, graine: int) -> Callable:
	return func(p: Vector3, _u: float, a: float) -> Color:
		var h: float = sin(a)
		var c: Color = base.lerp(dos, smoothstep(0.1, 0.9, h)).lerp(ventre, smoothstep(-0.3, -0.9, h))
		var n: float = Animaux._n3(p * 0.7, graine)
		if f > 0.0:
			c = c.lerp(raie, 0.7 * smoothstep(0.3, 0.8, sin(p.z * f + n * 2.2)) * smoothstep(-0.2, 0.55, h))
		return c.darkened(maxf(0.0, -n) * 0.2).lightened(maxf(0.0, n) * 0.08)


## La robe d'une patte : la couleur du corps en haut, plus sombre vers le pied
func _robe_patte(base: Color, pied: Color, haut: float, graine: int) -> Callable:
	return func(p: Vector3, _u: float, _a: float) -> Color:
		var n: float = Animaux._n3(p * 0.7, graine)
		return base.lerp(pied, 1.0 - smoothstep(0.0, haut, p.y)).darkened(maxf(0.0, -n) * 0.2)


func _uni(c: Color, graine: int = 0) -> Callable:
	return func(p: Vector3, _u: float, _a: float) -> Color:
		return c.darkened(maxf(0.0, -Animaux._n3(p * 0.9, graine)) * 0.16)


func _interp(zs: Array, vs: Array, z: float) -> float:
	for i in range(zs.size() - 1):
		if z >= float(zs[i]) and z <= float(zs[i + 1]):
			return lerpf(float(vs[i]), float(vs[i + 1]), (z - float(zs[i])) / maxf(float(zs[i + 1]) - float(zs[i]), 0.001))
	return float(vs[0]) if z < float(zs[0]) else float(vs[vs.size() - 1])


# =================================================================== les animaux

## Le Long-Cou (un brachiosaure, 17 m du bout de la queue au museau, la tête à 12 m)
func _mesh_long_cou() -> ArrayMesh:
	var st := _st()
	var base := Color(0.44, 0.47, 0.36)
	var robe: Callable = _robe(base, Color(0.3, 0.34, 0.26), Color(0.74, 0.7, 0.56), Color(0.22, 0.25, 0.2), 0.0, 3)
	var zs: Array = [-9.6, -8.4, -6.8, -5.2, -3.6, -2.2, -0.6, 0.9, 2.0, 2.9, 3.7, 4.5, 5.2, 5.8, 6.2]
	var ys: Array = [1.3, 1.5, 2.0, 2.8, 3.7, 4.3, 4.7, 5.1, 5.7, 6.6, 7.8, 9.2, 10.5, 11.4, 11.85]
	var rx: Array = [0.0, 0.13, 0.28, 0.52, 0.95, 1.4, 1.55, 1.42, 1.05, 0.7, 0.52, 0.43, 0.37, 0.33, 0.3]
	var ry: Array = [0.0, 0.15, 0.32, 0.6, 1.1, 1.6, 1.8, 1.65, 1.2, 0.78, 0.56, 0.45, 0.39, 0.35, 0.32]
	_corps(st, zs, ys, rx, ry, 22, robe)
	# la tête : un museau large, la bosse du front
	_corps(st, [6.0, 6.2, 6.6, 7.0, 7.4, 7.7, 7.85], [11.9, 11.95, 11.98, 11.9, 11.8, 11.72, 11.7], [0.0, 0.34, 0.4, 0.36, 0.32, 0.26, 0.0], [0.0, 0.34, 0.36, 0.3, 0.25, 0.2, 0.0], 16, robe)
	_corps(st, [6.25, 6.45, 6.75, 7.0, 7.15], [12.2, 12.36, 12.42, 12.28, 12.1], [0.0, 0.17, 0.2, 0.16, 0.0], [0.0, 0.2, 0.24, 0.18, 0.0], 10, robe)
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.34 * cote, 12.02, 6.95), 0.085, Color(0.05, 0.04, 0.03))
		_boule(st, Vector3(0.12 * cote, 12.4, 6.95), 0.05, Color(0.12, 0.1, 0.08))
	var patte: Callable = _robe_patte(base, Color(0.27, 0.28, 0.23), 1.6, 5)
	_pattes(st, [[0.95, 5.3, 1.3, 0.0], [0.98, 4.8, 1.3, 0.66], [1.0, 3.2, 1.36, 0.52], [1.0, 1.7, 1.3, 0.43], [1.0, 0.55, 1.3, 0.45], [1.0, 0.1, 1.34, 0.55], [1.0, -0.15, 1.34, 0.0]], patte)
	_pattes(st, [[1.0, 4.5, -2.4, 0.0], [1.02, 4.0, -2.4, 0.8], [1.05, 2.5, -2.2, 0.62], [1.05, 1.4, -2.45, 0.46], [1.05, 0.5, -2.4, 0.5], [1.05, 0.1, -2.36, 0.6], [1.05, -0.15, -2.36, 0.0]], patte)
	# les ongles
	for cote2 in [-1.0, 1.0]:
		for zz in [1.34, -2.36]:
			for k in range(3):
				_boule(st, Vector3(cote2 * (1.02 + (k - 1) * 0.3), 0.14, zz + 0.5 - absf(k - 1.0) * 0.12), 0.11, Color(0.2, 0.19, 0.17), 0.09)
	return st.commit()


## Un théropode : Grosse-Dent (le tyrannosaure, gueule ouverte) ou, en fin et les bras longs, un raptor
func _mesh_theropode(raptor: bool) -> ArrayMesh:
	var st := _st()
	var base: Color = Color(0.5, 0.4, 0.26) if not raptor else Color(0.56, 0.42, 0.24)
	var dos: Color = Color(0.3, 0.22, 0.14) if not raptor else Color(0.36, 0.2, 0.1)
	var robe: Callable = _robe(base, dos, Color(0.82, 0.76, 0.6), Color(0.16, 0.12, 0.08), 2.2 if not raptor else 2.6, 11 if not raptor else 12)
	var fin: float = 0.8 if raptor else 1.0
	var zs: Array = [-6.6, -5.5, -4.2, -2.8, -1.4, -0.2, 1.0, 1.9, 2.6, 3.0, 3.3]
	var ys: Array = [2.75, 2.7, 2.72, 2.82, 2.95, 3.05, 3.25, 3.6, 4.05, 4.4, 4.6]
	var rx: Array = [0.0, 0.1, 0.22, 0.42, 0.7, 0.88, 0.84, 0.62, 0.46, 0.4, 0.0]
	var ry: Array = [0.0, 0.12, 0.27, 0.5, 0.86, 1.12, 1.08, 0.8, 0.56, 0.46, 0.0]
	for i in range(rx.size()):
		rx[i] = float(rx[i]) * fin
		ry[i] = float(ry[i]) * fin
	_corps(st, zs, ys, rx, ry, 20, robe)
	# le crâne et la mâchoire (ouverte chez Grosse-Dent)
	var ht: float = 0.0 if not raptor else -0.05
	var long: float = 1.0 if not raptor else 0.9
	var cz: Array = [2.75, 2.95, 3.35, 3.8, 4.25, 4.65, 4.9]
	var cy: Array = [4.6, 4.68, 4.78, 4.82, 4.8, 4.76, 4.72]
	var crx: Array = [0.0, 0.44, 0.52, 0.47, 0.37, 0.3, 0.0]
	var cry: Array = [0.0, 0.36, 0.42, 0.36, 0.27, 0.22, 0.0]
	for i2 in range(cz.size()):
		cz[i2] = 2.75 + (float(cz[i2]) - 2.75) * long
		cy[i2] = float(cy[i2]) + ht
		crx[i2] = float(crx[i2]) * (0.82 if raptor else 1.0)
	_corps(st, cz, cy, crx, cry, 16, robe)
	var bas: float = 0.0 if not raptor else 0.32            # la mâchoire fermée remonte
	var gueule: Callable = _robe(base.lightened(0.1), base, Color(0.84, 0.78, 0.62), dos, 0.0, 13)
	_corps(st, [2.9, 3.1, 3.55, 4.05, 4.45, 4.62], [4.34 + bas * 0.2, 4.28 + bas * 0.3, 4.12 + bas * 0.75, 3.97 + bas * 1.15, 3.86 + bas * 1.45, 3.83 + bas * 1.5],
		[0.0, 0.37 * (0.82 if raptor else 1.0), 0.39 * (0.82 if raptor else 1.0), 0.31 * (0.82 if raptor else 1.0), 0.24 * (0.82 if raptor else 1.0), 0.0], [0.0, 0.15, 0.16, 0.13, 0.1, 0.0], 14, gueule)
	if not raptor:
		# le fond de la gueule, la langue
		_corps(st, [2.95, 3.2, 3.7, 4.1], [4.32, 4.36, 4.3, 4.22], [0.0, 0.3, 0.26, 0.0], [0.0, 0.2, 0.14, 0.0], 10, _uni(Color(0.4, 0.1, 0.1)))
		_corps(st, [3.2, 3.5, 3.95, 4.3], [4.2, 4.2, 4.1, 4.02], [0.0, 0.17, 0.15, 0.0], [0.0, 0.06, 0.05, 0.0], 8, _uni(Color(0.7, 0.3, 0.32)))
	# les dents
	var ivoire := Color(0.93, 0.89, 0.76)
	for k in range(9):
		var z: float = 3.45 + k * 0.155
		var x: float = _interp(cz, crx, z) * 0.86
		var y: float = _interp(cz, cy, z) - _interp(cz, cry, z) * 0.72
		var lg: float = (0.2 - absf(k - 4.0) * 0.012) * (0.55 if raptor else 1.0)
		_corne(st, [Vector3(x, y, z), Vector3(x, y - lg, z + 0.02)], 0.045, 0.006, ivoire, true, 5)
		if not raptor:
			var zb: float = 3.4 + k * 0.13
			var xb: float = _interp([2.9, 3.1, 3.55, 4.05, 4.45, 4.62], [0.0, 0.37, 0.39, 0.31, 0.24, 0.0], zb) * 0.84
			var yb: float = _interp([2.9, 3.1, 3.55, 4.05, 4.45, 4.62], [4.34, 4.28, 4.12, 3.97, 3.86, 3.83], zb) + 0.1
			_corne(st, [Vector3(xb, yb, zb), Vector3(xb, yb + 0.15, zb)], 0.038, 0.006, ivoire, true, 5)
	# les yeux, l'arcade
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.4 * cote * (0.82 if raptor else 1.0), 4.93 + ht, 3.42), 0.075, Color(0.75, 0.55, 0.1))
		_boule(st, Vector3(0.435 * cote * (0.82 if raptor else 1.0), 4.93 + ht, 3.45), 0.045, Color(0.03, 0.03, 0.03))
		_corps(st, [3.15, 3.3, 3.5, 3.68], [5.0 + ht, 5.07 + ht, 5.07 + ht, 5.0 + ht], [0.0, 0.1, 0.1, 0.0], [0.0, 0.08, 0.08, 0.0], 8, _uni(dos, 14), 0.34 * cote * (0.82 if raptor else 1.0))
	# les pattes arrière : la cuisse, le jarret, le pied
	var patte: Callable = _robe_patte(base, Color(0.2, 0.16, 0.12), 1.2, 15)
	var g: float = 0.8 if raptor else 1.0
	_pattes(st, [[0.6, 3.3, -0.15, 0.0], [0.64, 3.0, -0.05, 0.56 * g], [0.72, 2.3, 0.32, 0.48 * g], [0.76, 1.68, 0.62, 0.3 * g], [0.76, 1.1, 0.15, 0.2 * g], [0.76, 0.62, -0.3, 0.15 * g], [0.76, 0.28, -0.06, 0.17 * g], [0.76, 0.1, 0.2, 0.19 * g], [0.76, -0.1, 0.3, 0.0]], patte, 0.8)
	for cote2 in [-1.0, 1.0]:
		for k2 in range(3):
			var ex: float = (k2 - 1) * 0.3
			_corne(st, [Vector3(cote2 * 0.76, 0.16, 0.2), Vector3(cote2 * 0.76 + ex * 0.6, 0.13, 0.6), Vector3(cote2 * 0.76 + ex, 0.05, 0.95 - absf(ex) * 0.4)], 0.13 * g, 0.03, Color(0.22, 0.18, 0.14), false, 6)
			_corne(st, [Vector3(cote2 * 0.76 + ex, 0.08, 0.93 - absf(ex) * 0.4), Vector3(cote2 * 0.76 + ex * 1.1, 0.02, 1.12 - absf(ex) * 0.4)], 0.05, 0.008, Color(0.1, 0.09, 0.08), false, 5)
		if raptor:
			# la griffe en faucille, relevée
			_corne(st, [Vector3(cote2 * 0.6, 0.3, 0.3), Vector3(cote2 * 0.56, 0.55, 0.55), Vector3(cote2 * 0.55, 0.42, 0.78)], 0.07, 0.008, Color(0.08, 0.07, 0.06), false, 6)
	# les bras : tout petits chez Grosse-Dent, longs chez le raptor
	var bras: Callable = _uni(base, 16)
	if raptor:
		_pattes(st, [[0.48, 3.5, 1.75, 0.0], [0.52, 3.35, 1.8, 0.15], [0.6, 2.85, 1.55, 0.11], [0.62, 2.5, 2.05, 0.09], [0.6, 2.25, 2.45, 0.07], [0.6, 2.15, 2.6, 0.0]], bras, 0.9, 8)
		for cote3 in [-1.0, 1.0]:
			for k3 in range(3):
				_corne(st, [Vector3(cote3 * 0.6, 2.25, 2.45), Vector3(cote3 * (0.6 + (k3 - 1) * 0.07), 2.08, 2.7 + (k3 - 1) * 0.02)], 0.035, 0.005, Color(0.08, 0.07, 0.06), false, 5)
	else:
		_pattes(st, [[0.5, 3.5, 1.9, 0.0], [0.56, 3.35, 1.95, 0.15], [0.62, 2.95, 1.85, 0.1], [0.6, 2.75, 2.2, 0.075], [0.58, 2.66, 2.4, 0.0]], bras, 0.9, 8)
		for cote4 in [-1.0, 1.0]:
			for k4 in range(2):
				_corne(st, [Vector3(cote4 * 0.58, 2.7, 2.34), Vector3(cote4 * (0.56 + k4 * 0.08), 2.56, 2.52)], 0.03, 0.005, Color(0.08, 0.07, 0.06), false, 5)
	return st.commit()


## Corne-Sur-Nez (un tricératops, 8 m)
func _mesh_corne() -> ArrayMesh:
	var st := _st()
	var base := Color(0.5, 0.42, 0.3)
	var dos := Color(0.36, 0.28, 0.2)
	var robe: Callable = _robe(base, dos, Color(0.78, 0.72, 0.58), dos, 0.0, 21)
	_corps(st, [-4.3, -3.5, -2.6, -1.6, -0.5, 0.6, 1.5, 2.1, 2.5], [1.0, 1.25, 1.75, 2.1, 2.25, 2.2, 2.05, 1.95, 1.9],
		[0.0, 0.14, 0.42, 0.9, 1.12, 1.08, 0.86, 0.62, 0.5], [0.0, 0.17, 0.52, 1.0, 1.22, 1.16, 0.92, 0.66, 0.52], 22, robe)
	# la tête, le bec
	var tete := func(p: Vector3, u: float, a: float) -> Color:
		var c: Color = robe.call(p, u, a)
		return c.lerp(Color(0.26, 0.22, 0.17), smoothstep(3.75, 4.05, p.z) * 0.85)
	_corps(st, [2.2, 2.4, 2.8, 3.2, 3.6, 3.9, 4.08], [1.95, 1.92, 1.82, 1.66, 1.5, 1.36, 1.26], [0.0, 0.52, 0.54, 0.44, 0.32, 0.18, 0.0], [0.0, 0.52, 0.52, 0.44, 0.33, 0.2, 0.0], 18, tete)
	# la collerette : un grand bouclier relevé derrière la tête, bordé de pointes
	var col := func(p: Vector3, _u: float, _a: float) -> Color:
		var d: float = Vector2(p.x, p.y - 2.2).length()
		var c2: Color = base.lerp(Color(0.62, 0.3, 0.2), smoothstep(0.5, 1.2, d) * 0.7)
		return c2.darkened(maxf(0.0, -Animaux._n3(p * 0.9, 22)) * 0.2)
	_fus(st, [Vector3(0, 1.85, 2.6), Vector3(0, 2.3, 2.3), Vector3(0, 2.85, 1.95), Vector3(0, 3.3, 1.68), Vector3(0, 3.5, 1.56)], [0.45, 1.0, 1.32, 1.05, 0.0], [0.3, 0.17, 0.12, 0.1, 0.0], 20, col)
	var ivoire := Color(0.9, 0.86, 0.72)
	for k in range(7):
		var a2: float = lerpf(-1.15, 1.15, k / 6.0)
		var bx: float = sin(a2) * 1.3
		var by: float = 2.35 + cos(a2) * 1.12
		_corne(st, [Vector3(bx, by, 1.95 - cos(a2) * 0.3), Vector3(bx * 1.12, by + cos(a2) * 0.16 + 0.03, 1.9 - cos(a2) * 0.34)], 0.07, 0.012, ivoire, false, 6)
	# les trois cornes
	_corne(st, [Vector3(0.3, 2.1, 2.85), Vector3(0.36, 2.5, 3.2), Vector3(0.4, 2.8, 3.7), Vector3(0.4, 2.95, 4.15)], 0.15, 0.015, ivoire, true, 9)
	_corne(st, [Vector3(0, 1.72, 3.5), Vector3(0, 1.98, 3.62), Vector3(0, 2.16, 3.76)], 0.11, 0.02, ivoire, false, 8)
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.47 * cote, 1.98, 3.02), 0.06, Color(0.04, 0.03, 0.03))
		_corne(st, [Vector3(0.48 * cote, 1.55, 2.75), Vector3(0.62 * cote, 1.45, 2.7)], 0.07, 0.015, ivoire, false, 6)
	var patte: Callable = _robe_patte(base, Color(0.25, 0.21, 0.16), 0.9, 23)
	_pattes(st, [[0.72, 2.0, 1.4, 0.0], [0.75, 1.65, 1.4, 0.45], [0.78, 0.95, 1.52, 0.32], [0.78, 0.4, 1.46, 0.3], [0.78, 0.08, 1.5, 0.38], [0.78, -0.12, 1.5, 0.0]], patte)
	_pattes(st, [[0.78, 2.2, -1.3, 0.0], [0.82, 1.85, -1.3, 0.58], [0.85, 1.05, -1.08, 0.4], [0.85, 0.42, -1.3, 0.33], [0.85, 0.08, -1.26, 0.4], [0.85, -0.12, -1.26, 0.0]], patte)
	return st.commit()


## Le Dos-à-Plaques (un stégosaure, 7,5 m)
func _mesh_plaques() -> ArrayMesh:
	var st := _st()
	var base := Color(0.4, 0.46, 0.3)
	var dos := Color(0.26, 0.32, 0.2)
	var robe: Callable = _robe(base, dos, Color(0.76, 0.72, 0.54), Color(0.2, 0.24, 0.14), 1.6, 31)
	var zs: Array = [-4.5, -3.7, -2.7, -1.7, -0.7, 0.3, 1.2, 1.9, 2.5, 2.95]
	var ys: Array = [1.35, 1.35, 1.6, 2.0, 2.3, 2.22, 1.92, 1.58, 1.28, 1.12]
	var rx: Array = [0.0, 0.1, 0.28, 0.6, 0.86, 0.84, 0.64, 0.38, 0.21, 0.16]
	var ry: Array = [0.0, 0.12, 0.33, 0.76, 1.06, 1.02, 0.76, 0.44, 0.23, 0.18]
	_corps(st, zs, ys, rx, ry, 20, robe)
	_corps(st, [2.85, 3.0, 3.25, 3.55, 3.72], [1.12, 1.1, 1.04, 0.97, 0.94], [0.0, 0.18, 0.18, 0.12, 0.0], [0.0, 0.17, 0.16, 0.11, 0.0], 12, robe)
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.17 * cote, 1.1, 3.2), 0.035, Color(0.04, 0.03, 0.03))
	# les plaques : deux rangs décalés le long du dos, les plus grandes sur la croupe
	var plaque := func(p: Vector3, u: float, _a: float) -> Color:
		return Color(0.42, 0.4, 0.26).lerp(Color(0.8, 0.36, 0.14), smoothstep(0.15, 0.85, u)).darkened(maxf(0.0, -Animaux._n3(p * 1.4, 32)) * 0.2)
	for k in range(11):
		var z: float = lerpf(-3.0, 2.2, k / 10.0)
		var grand: float = 0.35 + 0.75 * exp(-pow((z + 0.8) / 1.7, 2.0))
		var x: float = 0.14 if k % 2 == 0 else -0.14
		var y0: float = _interp(zs, ys, z) + _interp(zs, ry, z) - 0.12
		# (une plaque plate en losange, la pointe en haut : des segments droits, pas de dôme au bout)
		_fus(st, [Vector3(x, y0, z), Vector3(x * 1.25, y0 + grand * 0.25, z - grand * 0.04), Vector3(x * 1.5, y0 + grand * 0.55, z - grand * 0.08),
				Vector3(x * 1.7, y0 + grand * 0.8, z - grand * 0.1), Vector3(x * 1.8, y0 + grand * 1.05, z - grand * 0.08)],
			[0.075, 0.065, 0.05, 0.03, 0.0], [grand * 0.2, grand * 0.42, grand * 0.45, grand * 0.27, 0.0], 8, plaque, Vector3.FORWARD, 1)
	# les quatre piquants du bout de la queue
	var ivoire := Color(0.88, 0.84, 0.7)
	_corne(st, [Vector3(0.08, 1.42, -3.75), Vector3(0.45, 1.75, -3.95), Vector3(0.8, 2.0, -4.2)], 0.08, 0.01, ivoire, true, 7)
	_corne(st, [Vector3(0.06, 1.42, -4.1), Vector3(0.4, 1.68, -4.35), Vector3(0.7, 1.85, -4.65)], 0.07, 0.01, ivoire, true, 7)
	var patte: Callable = _robe_patte(base, Color(0.2, 0.22, 0.15), 0.9, 33)
	_pattes(st, [[0.52, 1.7, 1.5, 0.0], [0.55, 1.4, 1.5, 0.36], [0.58, 0.75, 1.6, 0.25], [0.58, 0.32, 1.55, 0.24], [0.58, 0.08, 1.6, 0.31], [0.58, -0.1, 1.6, 0.0]], patte)
	_pattes(st, [[0.68, 2.35, -0.9, 0.0], [0.72, 1.95, -0.9, 0.55], [0.75, 1.05, -0.68, 0.38], [0.75, 0.4, -0.9, 0.31], [0.75, 0.08, -0.86, 0.38], [0.75, -0.1, -0.86, 0.0]], patte)
	return st.commit()


## Le Grand-Bec (un ptéranodon), perché, les ailes à demi ouvertes comme un cormoran qui sèche (6 m
## d'envergure) : le bras, le long doigt qui porte l'aile, et la toile de peau tendue du bout du doigt
## jusqu'à la cheville ; le long bec, la crête qui part en arrière.
func _mesh_grand_bec() -> ArrayMesh:
	var st := _st()
	var base := Color(0.6, 0.48, 0.34)
	var robe: Callable = _robe(base, Color(0.38, 0.28, 0.19), Color(0.86, 0.8, 0.66), Color(0.3, 0.2, 0.14), 0.0, 41)
	# le corps, penché en avant, et le cou
	_fus(st, [Vector3(0, 0.42, -0.34), Vector3(0, 0.55, -0.27), Vector3(0, 0.85, -0.12), Vector3(0, 1.12, 0.02), Vector3(0, 1.3, 0.1), Vector3(0, 1.58, 0.2), Vector3(0, 1.84, 0.27), Vector3(0, 1.98, 0.3)],
		[0.0, 0.16, 0.25, 0.25, 0.17, 0.09, 0.08, 0.0], [0.0, 0.15, 0.23, 0.22, 0.15, 0.09, 0.08, 0.0], 14, robe, Vector3.FORWARD)
	# la tête : le long bec, la crête rouge en arrière
	var bec := func(p: Vector3, _u: float, _a: float) -> Color:
		return base.lerp(Color(0.86, 0.72, 0.32), smoothstep(0.5, 1.1, p.z))
	_corps(st, [0.08, 0.24, 0.5, 0.9, 1.35, 1.7], [2.0, 2.03, 2.02, 1.96, 1.88, 1.83], [0.0, 0.12, 0.1, 0.065, 0.032, 0.0], [0.0, 0.13, 0.12, 0.08, 0.04, 0.0], 10, bec)
	var crete := func(p: Vector3, _u: float, _a: float) -> Color:
		return base.lerp(Color(0.8, 0.2, 0.12), smoothstep(0.2, -0.4, p.z))
	_corps(st, [0.28, 0.08, -0.3, -0.68, -0.98], [2.08, 2.16, 2.3, 2.4, 2.44], [0.05, 0.045, 0.035, 0.025, 0.0], [0.1, 0.15, 0.14, 0.08, 0.0], 8, crete)
	var os_aile: Callable = _uni(Color(0.5, 0.38, 0.26), 44)
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.1 * cote, 2.07, 0.4), 0.03, Color(0.03, 0.03, 0.03))
		# le bras (épaule, coude, poignet) puis le long doigt jusqu'au bout de l'aile
		var avant: Array = [Vector3(0.16 * cote, 1.18, 0.02), Vector3(0.6 * cote, 1.36, 0.18), Vector3(1.22 * cote, 1.6, 0.1),
			Vector3(1.9 * cote, 1.66, -0.06), Vector3(2.55 * cote, 1.5, -0.26), Vector3(3.05 * cote, 1.2, -0.46)]
		_fus(st, avant, [0.075, 0.07, 0.055, 0.04, 0.03, 0.0], [0.075, 0.07, 0.055, 0.04, 0.03, 0.0], 8, os_aile, Vector3.UP, 2)
		# les trois petits doigts griffus, au poignet
		for k in range(3):
			_corne(st, [Vector3(1.22 * cote, 1.6, 0.12), Vector3((1.26 + k * 0.04) * cote, 1.62 - k * 0.03, 0.3), Vector3((1.28 + k * 0.05) * cote, 1.55 - k * 0.03, 0.38)], 0.022, 0.004, Color(0.12, 0.09, 0.07), false, 5)
		# la toile : du bout du doigt, en arrière, jusqu'à la cheville
		var arriere: Array = [Vector3(0.15 * cote, 0.4, -0.3), Vector3(0.45 * cote, 0.5, -0.38), Vector3(1.05 * cote, 0.64, -0.46),
			Vector3(1.7 * cote, 0.8, -0.52), Vector3(2.4 * cote, 0.98, -0.54), Vector3(3.05 * cote, 1.2, -0.46)]
		var toile := func(p: Vector3, u: float, v: float) -> Color:
			var c: Color = Color(0.7, 0.54, 0.38).lerp(Color(0.42, 0.29, 0.2), smoothstep(0.35, 1.0, v)).lerp(Color(0.33, 0.22, 0.15), smoothstep(0.75, 1.0, u) * 0.6)
			# les fibres qui raidissent la toile, en éventail
			var fibre: float = smoothstep(0.55, 0.95, sin((u * 9.0 + v * 2.0) * PI) * 0.5 + 0.5)
			return c.darkened(fibre * 0.08 + maxf(0.0, -Animaux._n3(p * 1.5, 45)) * 0.14)
		_toile(st, avant, arriere, 14, 7, toile, Vector3(0, -0.05, -0.16))
	# les pattes, repliées, les doigts sur le rocher
	_pattes(st, [[0.14, 0.6, -0.12, 0.0], [0.16, 0.5, -0.08, 0.09], [0.2, 0.25, 0.1, 0.06], [0.2, 0.05, 0.04, 0.045], [0.2, -0.05, 0.12, 0.0]], _uni(Color(0.4, 0.3, 0.2), 43), 0.9, 8)
	return st.commit()


## Une ligne brisée, rééchantillonnée en n points également espacés
func _reech(pts: Array, n: int) -> Array:
	var long: Array = [0.0]
	for i in range(1, pts.size()):
		long.append(float(long[i - 1]) + (pts[i] as Vector3).distance_to(pts[i - 1]))
	var total: float = float(long[long.size() - 1])
	var out: Array = []
	for k in range(n):
		var d: float = total * float(k) / float(n - 1)
		var i: int = 1
		while i < pts.size() - 1 and float(long[i]) < d:
			i += 1
		var t: float = clampf((d - float(long[i - 1])) / maxf(float(long[i]) - float(long[i - 1]), 0.00001), 0.0, 1.0)
		out.append((pts[i - 1] as Vector3).lerp(pts[i], t))
	return out


## Une toile tendue entre deux bords (du corps vers le bout de l'aile, l'un et l'autre), un peu gonflée,
## des deux faces. colf(point, u le long de l'aile, v du bord avant au bord arrière) -> couleur.
func _toile(st: SurfaceTool, bord_avant: Array, bord_arriere: Array, n: int, m: int, colf: Callable, gonfle: Vector3) -> void:
	var a: Array = _reech(bord_avant, n)
	var b: Array = _reech(bord_arriere, n)
	var grille: Array = []
	for i in range(n):
		var ligne: Array = []
		for j in range(m + 1):
			var v: float = float(j) / float(m)
			ligne.append((a[i] as Vector3).lerp(b[i], v) + gonfle * sin(PI * v) * (1.0 - float(i) / float(n - 1) * 0.6))
		grille.append(ligne)
	# les normales, lisses : en travers de la grille
	var normales: Array = []
	for i in range(n):
		var ln: Array = []
		for j in range(m + 1):
			var du: Vector3 = (grille[mini(i + 1, n - 1)][j] as Vector3) - (grille[maxi(i - 1, 0)][j] as Vector3)
			var dv: Vector3 = (grille[i][mini(j + 1, m)] as Vector3) - (grille[i][maxi(j - 1, 0)] as Vector3)
			var nn: Vector3 = du.cross(dv)
			ln.append(nn.normalized() if nn.length() > 1e-9 else Vector3.UP)
		normales.append(ln)
	var t2 := SurfaceTool.new()
	t2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [1.0, -1.0]:
		for i in range(n - 1):
			for j in range(m):
				var q: Array = [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
				for tri in [[0, 1, 2], [0, 2, 3]]:
					var pa: Vector3 = grille[q[tri[0]][0]][q[tri[0]][1]]
					var pb: Vector3 = grille[q[tri[1]][0]][q[tri[1]][1]]
					var pc: Vector3 = grille[q[tri[2]][0]][q[tri[2]][1]]
					var g: Vector3 = (pb - pa).cross(pc - pa)
					if g.length() < 1e-10:
						continue
					# (une face de chaque côté : la normale est celle de la face qu'on regarde)
					var nrm: Vector3 = ((normales[q[tri[0]][0]][q[tri[0]][1]] as Vector3) + (normales[q[tri[1]][0]][q[tri[1]][1]] as Vector3) + (normales[q[tri[2]][0]][q[tri[2]][1]] as Vector3)) * face
					var ordre: Array = [tri[0], tri[1], tri[2]] if g.dot(nrm) < 0.0 else [tri[0], tri[2], tri[1]]
					for o in ordre:
						var ij: Array = q[o]
						var pp: Vector3 = grille[ij[0]][ij[1]]
						t2.set_normal((normales[ij[0]][ij[1]] as Vector3) * face)
						t2.set_uv(Vector2(float(ij[0]) / float(n - 1), float(ij[1]) / float(m)))
						t2.set_color(colf.call(pp, float(ij[0]) / float(n - 1), float(ij[1]) / float(m)))
						t2.add_vertex(pp)
	st.append_from(t2.commit(), 0, Transform3D())


## Un œuf (posé sur la pointe, un peu penché), tacheté
func _mesh_oeuf() -> ArrayMesh:
	var st := _st()
	var f := func(p: Vector3, _u: float, _a: float) -> Color:
		return Color(0.9, 0.86, 0.74).lerp(Color(0.55, 0.46, 0.34), smoothstep(0.25, 0.6, Animaux._n3(p * 9.0, 51)))
	_fus(st, [Vector3(0, 0.0, 0), Vector3(0, 0.05, 0), Vector3(0, 0.2, 0), Vector3(0, 0.36, 0), Vector3(0, 0.46, 0), Vector3(0, 0.5, 0)], [0.0, 0.11, 0.17, 0.14, 0.08, 0.0], [0.0, 0.11, 0.17, 0.14, 0.08, 0.0], 12, f, Vector3.FORWARD)
	return st.commit()


## Le grand squelette à demi enterré : l'échine, les côtes qui sortent de terre, le crâne
func _mesh_squelette() -> ArrayMesh:
	var st := _st()
	var os := Color(0.92, 0.88, 0.78)
	var f: Callable = _uni(os, 61)
	# l'échine : une file de vertèbres qui ondule, à moitié dans le sol
	for k in range(19):
		var z: float = -5.0 + k * 0.5
		var y: float = 0.25 + sin(k * 0.45) * 0.18
		_boule(st, Vector3(sin(k * 0.3) * 0.25, y, z), 0.2, os, 0.17)
		if k % 2 == 0:
			_corne(st, [Vector3(sin(k * 0.3) * 0.25, y + 0.1, z), Vector3(sin(k * 0.3) * 0.25, y + 0.5, z - 0.12)], 0.06, 0.02, os, false, 5)
	# les côtes : sept arcs de chaque côté, les plus hauts au milieu
	for k2 in range(7):
		var z2: float = -1.6 + k2 * 0.62
		var h: float = 1.5 + 0.7 * sin(PI * (k2 + 0.5) / 7.0)
		var x0: float = sin((k2 * 1.24 + 6.8) * 0.3) * 0.25
		_corne(st, [Vector3(x0 + 0.15, 0.35, z2), Vector3(x0 + 0.95, h * 0.6, z2 - 0.05), Vector3(x0 + 1.25, h, z2 - 0.1), Vector3(x0 + 0.95, h + 0.42, z2 - 0.15), Vector3(x0 + 0.5, h + 0.5, z2 - 0.2)], 0.1, 0.035, os, true, 7)
	# le crâne, posé de côté devant l'échine (les orbites, les dents)
	_corps(st, [4.6, 4.8, 5.2, 5.7, 6.2, 6.6, 6.8], [0.5, 0.56, 0.62, 0.58, 0.5, 0.44, 0.42], [0.0, 0.42, 0.5, 0.45, 0.36, 0.28, 0.0], [0.0, 0.36, 0.42, 0.36, 0.27, 0.2, 0.0], 14, f)
	for cote in [-1.0, 1.0]:
		_boule(st, Vector3(0.4 * cote, 0.78, 5.25), 0.13, Color(0.12, 0.1, 0.08))
		_boule(st, Vector3(0.3 * cote, 0.66, 6.45), 0.06, Color(0.12, 0.1, 0.08))
	for k3 in range(8):
		var z3: float = 5.5 + k3 * 0.15
		var x3: float = _interp([4.6, 4.8, 5.2, 5.7, 6.2, 6.6, 6.8], [0.0, 0.42, 0.5, 0.45, 0.36, 0.28, 0.0], z3) * 0.85
		_corne(st, [Vector3(x3, 0.33, z3), Vector3(x3, 0.12, z3 + 0.02)], 0.045, 0.006, os, true, 5)
	return st.commit()


func _statue(mesh: ArrayMesh, mat: Material, at: Vector3, cap: float, echelle: float, nom: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nom
	mi.mesh = mesh
	mi.material_override = mat
	mi.visibility_range_end = 520.0 if pc else 380.0
	mi.visibility_range_end_margin = 20.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, cap).scaled(Vector3.ONE * echelle), at)
	for s in range(mesh.get_surface_count()):
		triangles += mesh.surface_get_array_len(s) / 3
	return mi


## Le sol le plus bas sous l'animal (il ne flotte pas sur une pente)
func _sol(x: float, z: float, cap: float, arriere: float, avant: float, large: float) -> float:
	var bas: float = 1e9
	var f := Vector2(sin(cap), cos(cap))
	var l := Vector2(f.y, -f.x)
	for t in [-arriere * 0.35, 0.0, avant * 0.35]:
		for s in [-large, large]:
			var p: Vector2 = Vector2(x, z) + f * t + l * s
			bas = minf(bas, _h(p.x, p.y))
	return bas


## Un rocher de basalte (des colonnes à six pans serrées) : le perchoir du Grand-Bec
func _perchoir(lot: Kit.Lot, x: float, z: float, haut: float) -> void:
	var sol: float = _h(x, z)
	for k in range(7):
		var a: float = TAU * k / 6.0
		var d: float = 0.0 if k == 6 else 0.78
		var hh: float = haut if k == 6 else haut - _rng.randf_range(0.5, 1.8)
		var p: Vector3 = IleScript.W(x + cos(a) * d, z + sin(a) * d, sol - 0.6)
		lot.cyl("basalte", Transform3D(Basis(Vector3.UP, 0.5236), p), 0.47, 0.45, hh + 0.6, 6)
	_col(IleScript.W(x, z, sol), 1.2, haut)


## L'écriteau : un poteau, une planche, le nom ; au bord de l'allée, tourné vers elle
func _ecriteau(lot: Kit.Lot, x: float, z: float, vers: Vector2, nom: String, sous: String) -> void:
	var sol: float = _h(x, z)
	var cap: float = atan2(vers.x, vers.y)
	var bs := Basis(Vector3.UP, cap)
	var w: Vector3 = IleScript.W(x, z, sol)
	lot.box("planches", Transform3D(bs, w + Vector3.UP * 0.55), Vector3(0.12, 1.1, 0.12))
	lot.box("planches", Transform3D(bs * Basis(Vector3.RIGHT, -0.35), w + Vector3.UP * 1.12), Vector3(1.7, 0.62, 0.06))
	var face: Vector3 = bs * Basis(Vector3.RIGHT, -0.35) * Vector3.BACK
	for ligne in [[nom, 0.17, 0.12, Color(1.0, 0.86, 0.4)], [sous, 0.1, -0.13, Color(0.96, 0.92, 0.84)]]:
		var l := Label3D.new()
		l.text = str(ligne[0])
		l.font_size = 96
		l.pixel_size = float(ligne[1]) / 96.0
		l.outline_size = 12
		l.modulate = ligne[3]
		l.outline_modulate = Color(0.12, 0.05, 0.03)
		l.double_sided = false
		l.visibility_range_end = 60.0
		add_child(l)
		l.global_transform = Transform3D(bs * Basis(Vector3.RIGHT, -0.35), w + Vector3.UP * 1.12 + face * 0.04 + (bs * Basis(Vector3.RIGHT, -0.35) * Vector3.UP) * float(ligne[2]))
	_col(w, 0.2, 1.2)


func _animaux() -> void:
	var lot := Kit.Lot.new()
	var raptor: ArrayMesh = null
	for a in ANIMAUX:
		var cle: String = str(a[0])
		var arriere: float = float(a[6])
		var avant: float = float(a[7])
		var haut: float = float(a[8])
		var rayon: float = float(a[9])
		# l'endroit : celui qu'on souhaite, sinon le plus proche qui soit libre (en spirale)
		var ici := Vector2(float(a[3]), float(a[4]))
		var trouve: bool = false
		var cap: float = 0.0
		for essai in range(140):
			var p: Vector2 = ici
			if essai > 0:
				p += Vector2.from_angle(essai * 2.4) * (1.5 + essai * 0.22)
			var q: Vector2 = allee_pres(p.x, p.y)
			var vers: Vector2 = (q - p).normalized()
			cap = atan2(vers.x, vers.y) + float(a[5])
			var f := Vector2(sin(cap), cos(cap))
			var ok: bool = true
			var t: float = -arriere
			while t <= avant + 0.01 and ok:
				var s: Vector2 = p + f * t
				# le corps ne touche ni une allée ni la voie ; le cou et la queue peuvent passer au-dessus
				var corps: bool = absf(t) < rayon + 1.0
				if corps:
					ok = libre(s.x, s.y, rayon, 0.3, _h(p.x, p.y) + haut + 3.0, false)
				else:
					ok = voie_a(s.x, s.y, _h(p.x, p.y) + haut + 3.0) > LIBRE + 1.0
					# la queue (et le cou, tant qu'il est bas) ne passe pas au-dessus d'une allée : on s'y
					# cognerait ; seul le cou du Long-Cou, déjà haut, peut la survoler
					if ok and not (cle == "long_cou" and t > 3.0):
						var al: Vector2 = IleScript.allee_at(s.x, s.y)
						ok = al.x > al.y + 1.0
				t += 1.5
			if ok:
				ici = p
				trouve = true
				break
		if not trouve:
			push_warning("V217 : pas de place pour " + cle)
			continue
		var fwd := Vector2(sin(cap), cos(cap))
		var sol: float = _sol(ici.x, ici.y, cap, arriere, avant, rayon * 0.5)
		var at: Vector3 = IleScript.W(ici.x, ici.y, sol)
		var noeud: Node3D = null
		match cle:
			"long_cou":
				noeud = _statue(_mesh_long_cou(), _peau(), at, cap, 1.0, "Long_cou_v217")
				for pp in [[1.0, 1.32], [-1.0, 1.32], [1.05, -2.38], [-1.05, -2.38]]:
					var lp: Vector2 = ici + fwd * float(pp[1]) + Vector2(fwd.y, -fwd.x) * float(pp[0])
					_col(IleScript.W(lp.x, lp.y, sol), 0.6, 3.6)
					_interdits.append([lp.x, lp.y, 0.9])
			"grosse_dent":
				noeud = _statue(_mesh_theropode(false), _peau(), at, cap, 1.0, "Grosse_dent_v217")
				_col(at, 1.3, 3.0)
				_interdits.append([ici.x, ici.y, rayon])
			"corne":
				var m: ArrayMesh = _mesh_corne()
				noeud = _statue(m, _peau(), at, cap, 1.0, "Corne_sur_nez_v217")
				_col(at, 1.5, 2.4)
				_interdits.append([ici.x, ici.y, rayon])
				# son petit, à côté, et le nid
				var pp2: Vector2 = ici + fwd * 2.6 + Vector2(fwd.y, -fwd.x) * 2.6
				_statue(m, _peau(), IleScript.W(pp2.x, pp2.y, _h(pp2.x, pp2.y) - 0.03), cap - 0.7, 0.36, "Petit_corne_v217")
				_col(IleScript.W(pp2.x, pp2.y, _h(pp2.x, pp2.y)), 0.6, 0.9)
				_interdits.append([pp2.x, pp2.y, 1.3])
				var pn: Vector2 = ici + fwd * 4.6 + Vector2(fwd.y, -fwd.x) * 0.4
				_nid(lot, pn.x, pn.y)
			"plaques":
				noeud = _statue(_mesh_plaques(), _peau(), at, cap, 1.0, "Dos_a_plaques_v217")
				_col(at, 1.3, 2.4)
				_interdits.append([ici.x, ici.y, rayon])
			"raptors":
				raptor = _mesh_theropode(true)
				noeud = _statue(raptor, _peau(), at, cap, 0.3, "Raptor_0_v217")
				_col(at, 0.5, 1.4)
				_interdits.append([ici.x, ici.y, 1.0])
				# les deux autres, autour : à la première place libre parmi quelques-unes
				var poses: int = 0
				for r2 in [[3.4, 2.6, 0.5], [-1.5, 5.2, -0.4], [3.0, -2.8, -0.5], [-2.2, -4.6, 0.35], [5.5, 0.8, 0.2], [-4.0, 2.4, -0.2], [1.5, 6.2, 0.6], [2.0, -5.6, -0.6], [-5.5, -1.0, 0.3]]:
					if poses >= 2:
						break
					var pr: Vector2 = ici + fwd * float(r2[0]) + Vector2(fwd.y, -fwd.x) * float(r2[1])
					if not libre(pr.x, pr.y, 0.8, 0.5, _h(pr.x, pr.y) + 4.0):
						continue
					poses += 1
					_statue(raptor, _peau(), IleScript.W(pr.x, pr.y, _h(pr.x, pr.y) - 0.03), cap + float(r2[2]), 0.3 - absf(float(r2[2])) * 0.05, "Raptor_%d_v217" % poses)
					_col(IleScript.W(pr.x, pr.y, _h(pr.x, pr.y)), 0.5, 1.4)
					_interdits.append([pr.x, pr.y, 1.0])
			"grand_bec", "grand_bec2":
				var hp: float = 3.6 if cle == "grand_bec" else 2.8
				_perchoir(lot, ici.x, ici.y, hp)
				noeud = _statue(_mesh_grand_bec(), _peau(), IleScript.W(ici.x, ici.y, _h(ici.x, ici.y) + hp), cap, 1.0, "Grand_bec_v217" if cle == "grand_bec" else "Grand_bec_2_v217")
				_interdits.append([ici.x, ici.y, 1.6])
			"squelette":
				noeud = _statue(_mesh_squelette(), _os(), IleScript.W(ici.x, ici.y, _h(ici.x, ici.y) - 0.12), cap, 1.0, "Squelette_v217")
				_col(at, 1.3, 1.6)
				_interdits.append([ici.x, ici.y, rayon])
		var q2: Vector2 = allee_pres(ici.x, ici.y)
		statues.append({"cle": cle, "nom": str(a[1]), "pos": at, "cap": cap, "noeud": noeud, "rayon": rayon,
			"ici": ici, "allee": q2, "demi": maxf(arriere, avant) * 0.75 + rayon * 0.5, "haut": haut})
		# l'écriteau : au bord de l'allée si elle est proche, sinon devant l'animal
		if str(a[1]) != "":
			var d: float = ici.distance_to(q2)
			var al: Vector2 = IleScript.allee_at(ici.x, ici.y)
			var vers2: Vector2 = (q2 - ici).normalized()
			var pe: Vector2 = ici + vers2 * (d - al.y - 1.0) if d < 26.0 else ici + vers2 * (rayon + 3.0)
			# un peu de côté : il ne cache pas l'animal
			pe += Vector2(vers2.y, -vers2.x) * 2.2
			_ecriteau(lot, pe.x, pe.y, vers2, str(a[1]), str(a[2]))
			_interdits.append([pe.x, pe.y, 0.9])
	lot.commit(self, "Decor_animaux_v217", true, 320.0)
	# (pour le journal : l'animal le plus proche de l'axe de la voie, mesuré sur ses sommets)
	for n in get_children():
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and not str(n.name).begins_with("Decor_"):
			var mi: MeshInstance3D = n
			var sommets: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var pas: int = maxi(1, sommets.size() / 400)
			for k in range(0, sommets.size(), pas):
				var w: Vector3 = mi.global_transform * sommets[k]
				var l: Vector2 = IleScript.L(w.x, w.z)
				var cx: int = int(floor(l.x / 4.0))
				var cz: int = int(floor(l.y / 4.0))
				for dz in range(-2, 3):
					for dx in range(-2, 3):
						var kk := Vector2i(cx + dx, cz + dz)
						if not _voie.has(kk):
							continue
						for q in _voie[kk]:
							au_plus_pres = minf(au_plus_pres, Vector3(l.x, w.y, l.y).distance_to(q))


## Le nid : un bourrelet de terre et de brindilles, cinq œufs
func _nid(lot: Kit.Lot, x: float, z: float) -> void:
	if not libre(x, z, 1.2, 0.4, 1e9, false):
		return
	var sol: float = _h(x, z)
	for k in range(14):
		var a: float = TAU * k / 14.0
		var p: Vector3 = IleScript.W(x + cos(a) * 1.05, z + sin(a) * 1.05, sol + 0.08)
		lot.blob("planches", p, Vector3(0.42, 0.2, 0.26), 6, Basis(Vector3.UP, -a + PI * 0.5))
	var oeuf: ArrayMesh = _mesh_oeuf()
	for k2 in range(5):
		var a2: float = TAU * k2 / 5.0 + 0.4
		var d: float = 0.0 if k2 == 0 else 0.48
		var mi: MeshInstance3D = _statue(oeuf, _peau(), IleScript.W(x + cos(a2) * d, z + sin(a2) * d, sol + 0.02), a2, 1.0 + (k2 % 2) * 0.12, "Oeuf_%d_v217" % k2)
		mi.rotate_object_local(Vector3.RIGHT, 0.25 if k2 > 0 else 0.0)
		mi.visibility_range_end = 90.0
	_col(IleScript.W(x, z, sol), 1.2, 0.5)
	_interdits.append([x, z, 1.5])

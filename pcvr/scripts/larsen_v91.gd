extends Node3D
## V91 : l'Île de Larsen — le chef d'orchestre. Une grande ville de yourtes, en deux quartiers :
##  - à l'ouest, le Camp des Fleurs (les hippies) : des yourtes claires en deux ronds autour du
##    cercle des tambours et de son feu, des bus peints de fleurs, des fanions de prières, l'arbre à
##    rubans, des jardins de tournesols, la Mare aux Mantras ;
##  - à l'est, Rainville (les grunges) : des yourtes sombres rapiécées de flanelle le long d'une rue,
##    des garages en tôle, des amplis, des canapés défoncés, une rampe de skate, des flaques… et un
##    petit nuage qui ne quitte jamais le quartier (il y pleut toujours un peu) ;
##  - au milieu, la Prairie du Festival et sa Grande Scène (les concerts viendront en V93).
## Autour : les champs de chanvre (pour les cordes et les tissus ; la Corderie au bord du champ), les
## champs de coquelicots, le Bois des Riffs, la Colline du Feedback et son carillon, la Plage du
## Larsen et son ponton.
## (V92 : les habitants et l'intérieur des yourtes ; V93 : le festival et les concerts.)

const IleScript = preload("res://scripts/ile_larsen_v91.gd")
const Kit = preload("res://scripts/larsen_kit_v91.gd")
const Decor = preload("res://scripts/decor_v53.gd")
const FLORE := "res://scripts/larsen_flore_v91.gd"

const PLACES := {"plage": "la Plage du Larsen", "festival": "la Prairie du Festival", "fleurs": "le Camp des Fleurs",
	"rainville": "Rainville", "chanvre": "les champs de chanvre", "coquelicots": "les champs de coquelicots",
	"bois": "le Bois des Riffs", "colline": "la Colline du Feedback", "corderie": "la Corderie", "mare": "la Mare aux Mantras",
	"roadies": "le Hameau des Roadies", "prairie": "la prairie"}

## Les feutres des yourtes
const FEUTRES_FLEURS := [Color(0.9, 0.86, 0.76), Color(0.86, 0.76, 0.58), Color(0.62, 0.74, 0.82), Color(0.68, 0.76, 0.6),
	Color(0.88, 0.7, 0.66), Color(0.9, 0.72, 0.42), Color(0.93, 0.9, 0.84)]
const FEUTRES_RAINVILLE := [Color(0.2, 0.2, 0.21), Color(0.3, 0.32, 0.22), Color(0.36, 0.17, 0.14), Color(0.28, 0.32, 0.36),
	Color(0.34, 0.27, 0.2), Color(0.18, 0.22, 0.3)]

## Le Camp des Fleurs : les yourtes en deux ronds autour du feu [angle (degrés ; 0 = est, 90 = sud), rayon, échelle]
const CAMP_YOURTES := [[40.0, 13.0, 0.9], [85.0, 13.5, 0.95], [150.0, 13.0, 0.9], [195.0, 13.5, 1.0], [240.0, 13.0, 0.92], [325.0, 13.0, 0.9],
	[28.0, 24.5, 1.05], [60.0, 25.0, 1.0], [92.0, 24.0, 1.1], [148.0, 25.0, 1.0], [178.0, 24.5, 1.08], [208.0, 25.0, 1.0], [238.0, 24.0, 1.12], [330.0, 24.5, 1.0]]
## Le Hameau du Gué, entre le camp et la plage (des yourtes du camp, un peu à l'écart)
const HAMEAU := [[-24.0, 42.0, 0.95, Vector2(0.4, -1.0)], [-38.0, 34.0, 1.0, Vector2(0.8, -0.6)], [-44.0, 52.0, 0.9, Vector2(1.0, -0.6)]]
## Rainville : les yourtes le long de la rue [x, z (repère île), échelle, porte vers (x, z)]
const RAIN_YOURTES := [[50.0, -24.0, 1.0, Vector2(1, 0)], [50.0, -13.0, 0.95, Vector2(1, 0)], [50.0, -2.0, 1.05, Vector2(1, 0)], [50.0, 9.0, 0.95, Vector2(1, 0)], [50.0, 20.0, 1.0, Vector2(1, 0)],
	[70.0, -24.0, 1.0, Vector2(-1, 0)], [70.0, -13.0, 1.0, Vector2(-1, 0)], [70.0, 9.0, 0.95, Vector2(-1, 0)], [70.0, 20.0, 1.05, Vector2(-1, 0)],
	[38.0, -18.0, 0.9, Vector2(1, 0.2)], [38.0, -6.0, 0.95, Vector2(1, 0)], [38.0, 6.0, 0.9, Vector2(1, 0)], [38.0, 17.0, 0.95, Vector2(1, -0.2)]]
const CAFE := [60.0, -33.0, 1.55, Vector2(0, 1)]        # le Café Feedback, au bout de la rue
const DISQUAIRE := [70.0, -2.0, 1.15, Vector2(-1, 0)]   # le Disquaire, au milieu de la rue
const GARAGES := [[85.0, -18.0], [85.0, -4.0], [85.0, 10.0]]
## Le Hameau des Roadies, derrière la scène (ceux qui montent la scène, des deux quartiers) :
## [x, z, échelle, porte vers (x, z), style]
const ROADIES := [[16.0, -42.0, 0.95, Vector2(-1, 0.3), 0], [26.0, -46.0, 0.9, Vector2(-1, 0), 1], [20.0, -56.0, 1.0, Vector2(-1, 0.2), 1],
	[30.0, -58.0, 0.9, Vector2(-1, 0.4), 0], [17.0, -66.0, 0.95, Vector2(-1, 0.6), 0], [-8.0, -44.0, 0.95, Vector2(1, 0), 1],
	[-10.0, -56.0, 1.0, Vector2(1, 0), 0], [-4.0, -66.0, 0.9, Vector2(1, 0.4), 1]]
const SCENE := Vector2(0.0, -22.0)
const ARCHE := Vector2(2.0, 36.0)

## Ce que disent les panneaux : [id, x, z, vers où il regarde, texte]
const PANNEAUX := [
	["accueil", 22.0, 100.0, Vector2(0, 1), "Bienvenue sur l'Île de Larsen !\nÀ l'ouest : le Camp des Fleurs.\nÀ l'est : Rainville (prends un parapluie).\nAu milieu : la Grande Scène."],
	["fleurs", -34.0, 4.0, Vector2(1, 0), "Camp des Fleurs\nPaix, amour et tournesols.\n(Merci de ne pas marcher dans les jardins.)"],
	["rainville", 33.0, -6.0, Vector2(-1, 0), "RAINVILLE\nIci, il pleut. Tout le temps.\nOn s'y est fait."],
	["corderie", -38.0, -34.0, Vector2(-0.6, 0.8), "La Corderie\nIci, le chanvre devient corde, toile et ficelle.\n(Rien d'autre. On ne fume rien : on tresse.)"],
	["colline", 2.0, -74.0, Vector2(0, 1), "Colline du Feedback\nQuand le vent souffle fort, la colline siffle,\ncomme une guitare trop près de son ampli."],
	["scene", 16.0, 24.0, Vector2(0, 1), "Festival du Larsen\nLa Grande Scène se prépare…\nRevenez bientôt : ça va faire du bruit !"],
]

## Quand on frappe chez quelqu'un (V91 : il n'y a encore personne)
const TOC_FLEURS := [
	"Toc, toc… Personne. Sur la porte, un petit mot : « Partie cueillir des coquelicots. Reviens quand tu veux, la porte du cœur est toujours ouverte (celle-ci, non). »",
	"Personne. On entend juste un carillon qui tinte, dedans, tout seul.",
	"Toc, toc. Rien… Un écriteau peint : « En méditation. Revenir dans une heure, ou dans une vie. »",
	"Personne ne répond. Ça sent l'encens à la lavande et la tarte aux pommes.",
]
const TOC_RAIN := [
	"Toc, toc… Rien. Puis, de très loin dans la yourte, une voix endormie : « … C'est pas encore l'heure de la répète… »",
	"Personne. Sur la porte, au feutre : « Partis au garage. Ou au café. Ou ailleurs. Bref, pas là. »",
	"Toc, toc. Le seul qui répond, c'est la pluie, sur le toit : tic, tic, tic…",
	"Personne. Une guitare débranchée est posée contre la porte, avec un parapluie troué.",
]

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}               # lieux pour le carnet (nom -> Vector3 monde)
var yourtes: Array = []                   # {"at", "face", "s", "style", "door", "nom"}
var panneaux: Array = []                  # {"id", "at", "texte"}
var jardins: Array = []
var _avoid: Array = []
var _fire_light: OmniLight3D
var _night_lights: Array = []             # les lumières qui ne s'allument que le soir
var _rain: CPUParticles3D
var _cloud: Node3D
var _djembes: Array = []
var _carillon_at := Vector3.ZERO
var _arbre_at := Vector3.ZERO
var _ampli_at := Vector3.ZERO
var _corde_at := Vector3.ZERO
var _clock: float = 0.0
var _zone_t: float = 0.0
var _registered: bool = false
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 9190
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "toc": 0, "djembe": 0, "carillon": 0, "ampli": false, "corde": false,
		"arbre": false, "panneaux": {}}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_larsen_v91"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Après le relief et l'heure du jour : les deux quartiers, la scène, la corderie, la végétation.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	_camp_fleurs()
	_rainville()
	_festival()
	_roadies()
	_corderie()
	_colline()
	_plage()
	_panneaux()
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_larsen_v91"
		add_child(flore)
		for a in _avoid:
			flore.avoid.append(a)
		for j in jardins:
			flore.jardins.append(j)
		flore.build_larsen(ile, pc)
	objets["plage"] = _ground(14.0, 96.0)
	objets["scene"] = _ground(SCENE.x, SCENE.y + 12.0)
	objets["fleurs"] = _ground(-62.0 + 6.0, 14.0)
	objets["rainville"] = _ground(60.0, -2.0)
	objets["corderie"] = _ground(-28.0, -36.0)
	objets["colline"] = _ground(8.0, -80.0)
	objets["mare"] = _ground(-66.0, 40.0)
	print("ILE_MANGA_V91: l'Île de Larsen est prête (%d yourtes, %d ms)" % [yourtes.size(), Time.get_ticks_msec() - t0])


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


## La hauteur où poser une yourte : le plus haut du sol sous son plancher (le plancher descend dans
## la pente).
func _yurt_ground(x: float, z: float, s: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	var y: float = ile.height(w.x, w.z)
	for k in range(8):
		var a: float = TAU * k / 8.0
		y = maxf(y, ile.height(w.x + cos(a) * Kit.R * s, w.z + sin(a) * Kit.R * s))
	w.y = y - 0.02
	return w


func _add_yurt(list: Array, x: float, z: float, face2: Vector2, s: float, style: int, col: Color, nom: String) -> void:
	var at: Vector3 = _yurt_ground(x, z, s)
	var face := Vector3(face2.x, 0, face2.y).normalized()
	list.append({"at": at, "face": face, "s": s, "col": col, "seed": _rng.randf()})
	var door: Vector3 = Kit.yurt_door(at, face, s)
	door.y = ile.height(door.x, door.z) + 0.05
	yourtes.append({"at": at, "face": face, "s": s, "style": style, "door": door, "nom": nom})
	_avoid.append([Vector2(at.x, at.z), (Kit.R + 1.2) * s])


func _light(at: Vector3, col: Color, energy: float, rng: float, night_only: bool) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	add_child(l)
	l.global_position = at
	if night_only:
		_night_lights.append([l, energy])
	return l


# ------------------------------------------------------------------- le Camp des Fleurs

func _camp_fleurs() -> void:
	var c := Vector2(float(IleScript.PADS["fleurs"][0]), float(IleScript.PADS["fleurs"][1]))
	var list: Array = []
	for i in range(CAMP_YOURTES.size()):
		var e: Array = CAMP_YOURTES[i]
		var a: float = deg_to_rad(float(e[0]))
		var l: Vector2 = c + Vector2(cos(a), sin(a)) * float(e[1])
		_add_yurt(list, l.x, l.y, -Vector2(cos(a), sin(a)), float(e[2]), 0, FEUTRES_FLEURS[i % FEUTRES_FLEURS.size()], "fleurs_%d" % i)
	for j in range(HAMEAU.size()):
		var h: Array = HAMEAU[j]
		_add_yurt(list, float(h[0]), float(h[1]), h[3], float(h[2]), 0, FEUTRES_FLEURS[(j + 3) % FEUTRES_FLEURS.size()], "hameau_%d" % j)
	Kit.yurts(self, "Camp_des_Fleurs", 0, list)
	var b := Kit.Batch.new()
	# --- le cercle des tambours : le foyer, six bancs de rondins, des djembés
	var fc: Vector3 = _ground(c.x, c.y)
	Kit.fire_ring(b, fc)
	_avoid.append([Vector2(fc.x, fc.z), 6.5])
	for k in range(6):
		var a2: float = TAU * k / 6.0 + 0.25
		var bp: Vector3 = _ground(c.x + cos(a2) * 4.4, c.y + sin(a2) * 4.4)
		Kit.log_bench(b, bp, -a2 + PI * 0.5)
		if k % 2 == 0:
			var dp: Vector3 = _ground(c.x + cos(a2 + 0.45) * 3.4, c.y + sin(a2 + 0.45) * 3.4)
			Kit.djembe(b, dp)
			_djembes.append(dp)
	var fire: CPUParticles3D = _fire(fc + Vector3.UP * 0.2)
	fire.name = "Feu_des_tambours"
	_fire_light = _light(fc + Vector3.UP * 1.0, Color(1.0, 0.62, 0.3), 2.2, 16.0, false)
	_fire_light.shadow_enabled = true
	Decor.smoke(self, fc + Vector3.UP * 1.2, 22, 1.4, 0.8)
	# --- les fanions de prières : un hexagone de poteaux autour du feu, des fils vers les yourtes
	var poles_in: Array = []
	var gaps: Array = [2.0, 62.0, 117.0, 172.0, 217.0, 282.0]
	for k2 in range(6):
		var a3: float = deg_to_rad(float(gaps[k2]))
		poles_in.append(Kit.pole(b, _ground(c.x + cos(a3) * 8.0, c.y + sin(a3) * 8.0), 3.4))
	for k3 in range(6):
		Kit.flags(b, poles_in[k3], poles_in[(k3 + 1) % 6], 0.55, 11)
		var a4: float = deg_to_rad(float(gaps[k3]))
		var outer: Vector3 = Kit.pole(b, _ground(c.x + cos(a4) * 19.0, c.y + sin(a4) * 19.0), 3.0)
		Kit.flags(b, poles_in[k3], outer, 0.7, 13)
	# des guirlandes d'ampoules entre les yourtes du grand rond
	var ring: Array = []
	for k4 in range(12):
		var a5: float = TAU * (k4 + 0.5) / 12.0
		ring.append(Kit.pole(b, _ground(c.x + cos(a5) * 30.0, c.y + sin(a5) * 30.0), 2.8, 0.05))
	for k5 in range(12):
		if k5 == 11 or k5 == 0:
			continue          # (l'entrée, vers le festival : pas de fil en travers du chemin)
		Kit.bulbs(b, ring[k5], ring[(k5 + 1) % 12], 0.6, 9)
	# --- l'arbre à rubans, à l'entrée du camp
	_arbre_at = _ground(c.x + 15.0, c.y + 1.0)
	Kit.maypole(b, _arbre_at)
	_avoid.append([Vector2(_arbre_at.x, _arbre_at.z), 6.5])
	# --- les bus peints
	var buses: Array = [[80.0, 33.0, "bus_0", true], [200.0, 33.5, "bus_1", true], [250.0, 34.0, "bus_2", false]]
	for bu in buses:
		var a6: float = deg_to_rad(float(bu[0]))
		var bl: Vector2 = c + Vector2(cos(a6), sin(a6)) * float(bu[1])
		var bw: Vector3 = _ground(bl.x, bl.y)
		var yaw: float = -a6 + PI * 0.5
		Kit.bus(b, Transform3D(Basis(Vector3.UP, yaw), bw), str(bu[2]), bool(bu[3]))
		if bool(bu[3]):
			# un tapis sous l'auvent, deux poufs
			var side: Vector3 = Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
			var rug: Vector3 = bw + side * 3.0 + Basis(Vector3.UP, yaw) * Vector3(-1.0, 0, 0)
			rug.y = ile.height(rug.x, rug.z)
			b.box("toile_rayee", Transform3D(Basis(Vector3.UP, yaw), rug + Vector3.UP * 0.02), Vector3(3.0, 0.03, 2.0))
			for sx in [-0.8, 0.8]:
				var pf: Vector3 = rug + Basis(Vector3.UP, yaw) * Vector3(sx, 0, 0.3)
				b.cyl("toile_bleue", Transform3D(Basis(), pf), 0.32, 0.3, 0.38, 10, true)
		_avoid.append([Vector2(bw.x, bw.z), 5.5])
	# --- les jardins de tournesols (plantés par la végétation), leurs bordures de planches
	for g in [[155.0, 33.0, 4.5, 2.2], [270.0, 33.0, 5.0, 2.0]]:
		var a7: float = deg_to_rad(float(g[0]))
		var gl: Vector2 = c + Vector2(cos(a7), sin(a7)) * float(g[1])
		var gw: Vector3 = _ground(gl.x, gl.y)
		var ang: float = a7 + PI * 0.5
		jardins.append([gw, float(g[2]), float(g[3]), ang])
		var gb := Basis(Vector3.UP, -ang)
		for sz in [-1.0, 1.0]:
			b.box("planches", Transform3D(gb, gw + gb * Vector3(0, 0.12, sz * (float(g[3]) + 0.1))), Vector3(float(g[2]) * 2.0 + 0.3, 0.25, 0.08))
			b.box("planches", Transform3D(gb, gw + gb * Vector3(sz * (float(g[2]) + 0.1), 0.12, 0)), Vector3(0.08, 0.25, float(g[3]) * 2.0 + 0.3))
		_avoid.append([Vector2(gw.x, gw.z), maxf(float(g[2]), float(g[3])) + 1.0])
	b.commit(self, "Camp_des_Fleurs_decor")


# ------------------------------------------------------------------- Rainville

func _rainville() -> void:
	var list: Array = []
	for i in range(RAIN_YOURTES.size()):
		var e: Array = RAIN_YOURTES[i]
		_add_yurt(list, float(e[0]), float(e[1]), e[3], float(e[2]), 1, FEUTRES_RAINVILLE[i % FEUTRES_RAINVILLE.size()], "rain_%d" % i)
	_add_yurt(list, float(CAFE[0]), float(CAFE[1]), CAFE[3], float(CAFE[2]), 1, Color(0.24, 0.22, 0.2), "cafe")
	_add_yurt(list, float(DISQUAIRE[0]), float(DISQUAIRE[1]), DISQUAIRE[3], float(DISQUAIRE[2]), 1, Color(0.2, 0.2, 0.26), "disquaire")
	Kit.yurts(self, "Rainville", 1, list)
	var b := Kit.Batch.new()
	# --- les garages, leurs amplis et leurs canapés
	var toles: Array = ["tole_rouge", "tole_vert", "tole_bleu"]
	for g in range(GARAGES.size()):
		var gp: Vector3 = _ground(float(GARAGES[g][0]), float(GARAGES[g][1]))
		var xf := Transform3D(Basis(Vector3.UP, -PI * 0.5), gp)
		Kit.garage(b, xf, toles[g])
		_avoid.append([Vector2(gp.x, gp.z), 5.5])
		var front: Vector3 = gp + Vector3(-5.0, 0, 0)
		front.y = ile.height(front.x, front.z)
		Kit.amp(b, Transform3D(Basis(Vector3.UP, -PI * 0.5 + 0.3), front + Vector3(0, 0, -2.0)), 2 if g != 1 else 1, g == 2)
		Kit.couch(b, Transform3D(Basis(Vector3.UP, -PI * 0.5 - 0.15), front + Vector3(-1.0, 0, 1.5)), "toile_canape" if g % 2 == 0 else "toile_canape_2")
		if g == 1:
			_ampli_at = front + Vector3(0, 0, -2.0)
		# une enseigne au néon au-dessus du volet
		b.box("neon", Transform3D(Basis(Vector3.UP, -PI * 0.5), gp + Vector3(-3.62, 3.25, 0)), Vector3(2.4, 0.12, 0.05))
	# --- la rampe de skate, au coin sud-ouest
	var rp: Vector3 = _ground(42.0, 27.0)
	Kit.ramp(b, Transform3D(Basis(Vector3.UP, PI * 0.25), rp))
	_avoid.append([Vector2(rp.x, rp.z), 5.0])
	# --- les réverbères de la rue (des lanternes au bout de grands poteaux) et les guirlandes
	var lamps: Array = []
	for z in [-28.0, -16.0, -4.0, 8.0, 20.0]:
		for sx in [-1.0, 1.0]:
			var lp: Vector3 = _ground(60.0 + sx * 4.2, z + (3.0 if sx > 0 else 0.0))
			var top: Vector3 = Kit.pole(b, lp, 3.6, 0.07)
			b.box("fer", Transform3D(Basis(), top + Vector3(-sx * 0.35, -0.05, 0)), Vector3(0.75, 0.05, 0.05))
			var lan: Node3D = Decor.lantern(self, top + Vector3(-sx * 0.65, -0.05, 0) - global_position, 1.2)
			lan.name = "Reverbere_rainville"
			lamps.append(top)
	for k in range(0, lamps.size() - 2, 2):
		Kit.bulbs(b, lamps[k], lamps[k + 3], 0.8, 12)
	for zl in [-16.0, 8.0]:
		_light(_ground(60.0, zl) + Vector3.UP * 3.4, Color(1.0, 0.75, 0.45), 1.6, 14.0, true)
	_light(_ground(78.0, -4.0) + Vector3.UP * 3.2, Color(1.0, 0.3, 0.6), 0.8, 9.0, true)
	# --- des flaques partout (il pleut)
	for f in range(26):
		var fl := Vector2(_rng.randf_range(34.0, 88.0), _rng.randf_range(-34.0, 30.0))
		var fw: Vector3 = _ground(fl.x, fl.y)
		for k5 in range(3):
			var off := Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.5, 0.5))
			var pw: Vector3 = fw + off
			pw.y = ile.height(pw.x, pw.z) + 0.012 + 0.001 * k5
			b.cyl("flaque", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(_rng.randf_range(0.5, 0.9), 1, _rng.randf_range(0.35, 0.6))), pw), 1.0, 1.0, 0.004, 12, true)
	# --- des poubelles en tonneaux, des caisses de disques devant le Disquaire
	for t in [[56.0, -30.0], [64.0, 25.0], [44.0, 14.0], [76.0, -20.0]]:
		Decor.barrel(self, _ground(float(t[0]), float(t[1])) - global_position, 0.38, 0.95, _rng.randf() * TAU)
	var dq: Vector3 = Kit.yurt_door(_ground(float(DISQUAIRE[0]), float(DISQUAIRE[1])), Vector3(-1, 0, 0), float(DISQUAIRE[2]))
	for k2 in range(3):
		var cp: Vector3 = dq + Vector3(0, 0, -2.2 + k2 * 0.6) + Vector3(0.4, 0, 0)
		cp.y = ile.height(cp.x, cp.z)
		b.box("planches_gris", Transform3D(Basis(Vector3.UP, 0.1 * k2), cp + Vector3.UP * 0.25), Vector3(0.45, 0.5, 0.45))
	# --- le nuage de Rainville, et la pluie qui suit le promeneur dans le quartier
	_cloud = Node3D.new()
	_cloud.name = "Nuage_de_Rainville"
	add_child(_cloud)
	_cloud.global_position = _ground(60.0, -2.0) + Vector3.UP * 42.0
	# des bouffées douces (des cartes tournées vers la caméra, un dégradé rond), plus sombres dessous
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gr.add_point(0.55, Color(1, 1, 1, 0.75))
	tex.gradient = gr
	for k3 in range(34):
		var puff := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var sz: float = _rng.randf_range(14.0, 26.0)
		qm.size = Vector2(sz, sz * 0.75)
		puff.mesh = qm
		var cm := StandardMaterial3D.new()
		var lo: float = _rng.randf()
		var g: float = lerpf(0.42, 0.66, lo)
		cm.albedo_color = Color(g, g * 1.02, g * 1.07, 0.8)
		cm.albedo_texture = tex
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		cm.disable_receive_shadows = true
		cm.render_priority = -1
		puff.material_override = cm
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.position = Vector3(_rng.randf_range(-26.0, 26.0), lerpf(-4.0, 5.0, lo), _rng.randf_range(-28.0, 28.0))
		_cloud.add_child(puff)
	# (une ombre douce sur le quartier : un disque invisible qui ne fait que de l'ombre)
	var shade := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 34.0
	sc.bottom_radius = 34.0
	sc.height = 2.0
	shade.mesh = sc
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_cloud.add_child(shade)
	_rain = CPUParticles3D.new()
	_rain.name = "Pluie_de_Rainville"
	_rain.amount = 1100 if pc else 520
	_rain.lifetime = 1.15
	_rain.preprocess = 1.0
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(26.0, 0.5, 26.0)
	_rain.direction = Vector3(0.08, -1, 0.04)
	_rain.spread = 2.0
	_rain.initial_velocity_min = 13.0
	_rain.initial_velocity_max = 15.0
	_rain.gravity = Vector3(0, -2.0, 0)
	_rain.local_coords = false
	var rq := QuadMesh.new()
	rq.size = Vector2(0.018, 0.55)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.78, 0.83, 0.9, 0.45)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.disable_receive_shadows = true
	rq.material = rm
	_rain.mesh = rq
	_rain.emitting = false
	add_child(_rain)
	b.commit(self, "Rainville_decor")


# ------------------------------------------------------------------- la Prairie du Festival

func _festival() -> void:
	var b := Kit.Batch.new()
	var sc: Vector3 = _ground(SCENE.x, SCENE.y)
	var sy: float = sc.y
	var W: float = 22.0
	var D: float = 12.0
	var H: float = 1.6
	var o := Vector3(sc.x, sy, sc.z)
	# --- le plancher de la scène, sa jupe noire, les escaliers de côté
	b.box("planches", Transform3D(Basis(), o + Vector3(0, H - 0.06, 0)), Vector3(W, 0.12, D))
	b.box("toile_noire", Transform3D(Basis(), o + Vector3(0, (H - 0.12) * 0.5 - 0.3, D * 0.5 - 0.02)), Vector3(W, H - 0.12 + 0.6, 0.04))
	for sx in [-1.0, 1.0]:
		b.box("toile_noire", Transform3D(Basis(), o + Vector3(sx * W * 0.5, (H - 0.12) * 0.5 - 0.3, 0)), Vector3(0.04, H - 0.12 + 0.6, D))
		for st in range(5):
			var sh: float = H * float(st + 1) / 6.0
			b.box("planches_gris", Transform3D(Basis(), o + Vector3(sx * (W * 0.5 + 0.5 + (4 - st) * 0.35), sh * 0.5 - 0.2, D * 0.25)), Vector3(0.36, sh + 0.4, 1.8))
	b.box("toile_noire", Transform3D(Basis(), o + Vector3(0, (H - 0.12) * 0.5 - 0.3, -D * 0.5)), Vector3(W, H - 0.12 + 0.6, 0.04))
	# --- les quatre tours en treillis, le cadre du toit, le toit noir
	var TH: float = 9.5
	for cx in [-W * 0.5 + 0.3, W * 0.5 - 0.3]:
		for cz in [-D * 0.5 + 0.3, D * 0.5 - 0.3]:
			var base: Vector3 = o + Vector3(cx, -0.3, cz)
			_truss_v(b, base, TH + 0.3)
	for cz2 in [-D * 0.5 + 0.3, D * 0.5 - 0.3]:
		_truss_h(b, o + Vector3(-W * 0.5 + 0.3, TH, cz2), o + Vector3(W * 0.5 - 0.3, TH, cz2))
	for cx2 in [-W * 0.5 + 0.3, W * 0.5 - 0.3]:
		_truss_h(b, o + Vector3(cx2, TH, -D * 0.5 + 0.3), o + Vector3(cx2, TH, D * 0.5 - 0.3))
	b.box("toile_noire", Transform3D(Basis(Vector3.RIGHT, -0.06), o + Vector3(0, TH + 0.7, 0)), Vector3(W + 1.6, 0.06, D + 1.6))
	# --- la toile du fond (peinte), les projecteurs sous le treillis de devant
	b.box("toile_bleue", Transform3D(Basis(), o + Vector3(0, H + (TH - H) * 0.5, -D * 0.5 + 0.7)), Vector3(W - 1.6, TH - H - 0.3, 0.05))
	for k in range(10):
		var px: float = -W * 0.5 + 2.2 + k * (W - 4.4) / 9.0
		var pp: Vector3 = o + Vector3(px, TH - 0.55, D * 0.5 - 0.3)
		b.cyl("fer", Transform3D(Basis(Vector3.RIGHT, 0.6), pp), 0.14, 0.12, 0.38, 10, true)
		b.tube("fer", pp + Vector3.UP * 0.2, pp + Vector3.UP * 0.5, 0.015, 4)
	# --- les murs d'enceintes, de chaque côté, et les retours au bord de la scène
	for sx2 in [-1.0, 1.0]:
		for k2 in range(2):
			Kit.amp(b, Transform3D(Basis(Vector3.UP, 0.0), o + Vector3(sx2 * (W * 0.5 + 1.6), -0.1, D * 0.5 - 1.0 - k2 * 0.85)), 4)
			Kit.amp(b, Transform3D(Basis(Vector3.UP, 0.0), o + Vector3(sx2 * (W * 0.5 + 2.45), -0.1, D * 0.5 - 1.0 - k2 * 0.85)), 4)
	for k3 in range(4):
		var wx: float = -6.0 + k3 * 4.0
		b.box("vinyle", Transform3D(Basis(Vector3.RIGHT, -0.5), o + Vector3(wx, H + 0.22, D * 0.5 - 0.7)), Vector3(0.8, 0.4, 0.45))
		b.box("grille", Transform3D(Basis(Vector3.RIGHT, -0.5), o + Vector3(wx, H + 0.3, D * 0.5 - 0.5)), Vector3(0.7, 0.3, 0.02))
	_avoid.append([Vector2(sc.x, sc.z), 17.0])
	# le grand panneau peint au fond de la scène
	var lbl: Label3D = Kit.label(self, "FESTIVAL DU LARSEN", o + Vector3(0, H + (TH - H) * 0.62, -D * 0.5 + 0.75), Vector3(0, 0, 1), 0.035, Color(0.98, 0.85, 0.3))
	lbl.outline_size = 12
	lbl.outline_modulate = Color(0.55, 0.15, 0.4)
	var lbl2: Label3D = Kit.label(self, "~ la Grande Scène ~", o + Vector3(0, H + (TH - H) * 0.42, -D * 0.5 + 0.75), Vector3(0, 0, 1), 0.02, Color(0.95, 0.95, 0.9))
	lbl2.outline_size = 8
	lbl2.outline_modulate = Color(0.1, 0.2, 0.4)
	# --- la régie, au milieu de la prairie (une tente rayée, une table, la console)
	var reg: Vector3 = _ground(0.0, 14.0)
	for rx in [-1.8, 1.8]:
		for rz in [-1.5, 1.5]:
			b.tube("chrome", reg + Vector3(rx, 0, rz), reg + Vector3(rx, 2.4, rz), 0.035, 6)
	b.box("toile_rayee", Transform3D(Basis(), reg + Vector3(0, 2.45, 0)), Vector3(4.0, 0.05, 3.4))
	b.box("planches_gris", Transform3D(Basis(), reg + Vector3(0, 0.45, 0)), Vector3(2.6, 0.9, 1.0))
	b.box("vinyle", Transform3D(Basis(Vector3.RIGHT, 0.25), reg + Vector3(0, 0.98, 0)), Vector3(1.8, 0.1, 0.8))
	_avoid.append([Vector2(reg.x, reg.z), 3.5])
	# --- l'arche d'entrée, sur le chemin de la plage
	var ar: Vector3 = _ground(ARCHE.x, ARCHE.y)
	for ax in [-3.2, 3.2]:
		var ap: Vector3 = _ground(ARCHE.x + ax, ARCHE.y)
		b.cyl("bois_peint", Transform3D(Basis(), ap - Vector3.UP * 0.5), 0.18, 0.15, 6.4, 10, true)
	b.box("bois_peint", Transform3D(Basis(), ar + Vector3(0, 5.6, 0)), Vector3(7.4, 0.3, 0.3))
	b.box("toile_rayee", Transform3D(Basis(), ar + Vector3(0, 4.85, 0.18)), Vector3(6.0, 1.1, 0.04))
	var la: Label3D = Kit.label(self, "Festival du Larsen", ar + Vector3(0, 4.85, 0.22), Vector3(0, 0, 1), 0.016, Color(0.3, 0.1, 0.35))
	la.outline_size = 6
	la.outline_modulate = Color(1, 1, 1)
	var la2: Label3D = Kit.label(self, "Festival du Larsen", ar + Vector3(0, 4.85, 0.14), Vector3(0, 0, -1), 0.016, Color(0.3, 0.1, 0.35))
	la2.outline_size = 6
	la2.outline_modulate = Color(1, 1, 1)
	Kit.flags(b, ar + Vector3(-3.4, 5.9, 0), ar + Vector3(3.4, 5.9, 0), 0.25, 9)
	# --- les guirlandes autour de la prairie (pas devant la scène)
	var fc := Vector2(float(IleScript.PADS["festival"][0]), float(IleScript.PADS["festival"][1]))
	var poles: Array = []
	for k4 in range(14):
		var a: float = TAU * k4 / 14.0
		if sin(a) < -0.45:
			poles.append(Vector3.INF)
			continue
		poles.append(Kit.pole(b, _ground(fc.x + cos(a) * 29.0, fc.y + sin(a) * 29.0), 3.6, 0.06))
	for k5 in range(14):
		var p0: Vector3 = poles[k5]
		var p1: Vector3 = poles[(k5 + 1) % 14]
		if p0 == Vector3.INF or p1 == Vector3.INF:
			continue
		if absf(rad_to_deg(TAU * (k5 + 0.5) / 14.0) - 90.0) < 14.0:
			continue          # (l'arche)
		if k5 % 2 == 0:
			Kit.bulbs(b, p0, p1, 0.7, 10)
		else:
			Kit.flags(b, p0, p1, 0.7, 12)
	b.commit(self, "Festival_decor")


## Une tour de treillis (quatre tubes et leurs barreaux en zigzag).
func _truss_v(b: Kit.Batch, base: Vector3, h: float) -> void:
	var s: float = 0.2
	var corners: Array = [Vector3(-s, 0, -s), Vector3(s, 0, -s), Vector3(s, 0, s), Vector3(-s, 0, s)]
	for c in corners:
		b.tube("chrome", base + c, base + c + Vector3.UP * h, 0.025, 6)
	var n: int = int(h / 0.5)
	for k in range(n):
		var y0: float = k * 0.5
		for i in range(4):
			var a: Vector3 = corners[i]
			var c2: Vector3 = corners[(i + 1) % 4]
			b.tube("chrome", base + a + Vector3.UP * y0, base + c2 + Vector3.UP * (y0 + 0.5), 0.012, 4)


func _truss_h(b: Kit.Batch, a: Vector3, c: Vector3) -> void:
	var d: Vector3 = c - a
	var l: float = d.length()
	var f: Vector3 = d / l
	var side: Vector3 = f.cross(Vector3.UP).normalized() * 0.2
	var up := Vector3.UP * 0.2
	var corners: Array = [side + up, -side + up, -side - up, side - up]
	for cc in corners:
		b.tube("chrome", a + cc, c + cc, 0.025, 6)
	var n: int = int(l / 0.5)
	for k in range(n):
		for i in range(4):
			b.tube("chrome", a + f * (k * 0.5) + corners[i], a + f * ((k + 1) * 0.5) + corners[(i + 1) % 4], 0.012, 4)


# ------------------------------------------------------------------- le Hameau des Roadies

func _roadies() -> void:
	var l0: Array = []
	var l1: Array = []
	for i in range(ROADIES.size()):
		var e: Array = ROADIES[i]
		var st: int = int(e[4])
		_add_yurt(l0 if st == 0 else l1, float(e[0]), float(e[1]), e[3], float(e[2]), st,
			FEUTRES_FLEURS[i % FEUTRES_FLEURS.size()] if st == 0 else FEUTRES_RAINVILLE[i % FEUTRES_RAINVILLE.size()], "roadies_%d" % i)
	Kit.yurts(self, "Roadies_fleurs", 0, l0)
	Kit.yurts(self, "Roadies_rainville", 1, l1)
	var b := Kit.Batch.new()
	# des caisses de matériel, des rouleaux de câbles, une remorque
	for k in range(6):
		var cp: Vector3 = _ground(13.0 + (k % 3) * 1.4, -33.0 - float(int(k / 3.0)) * 1.3)
		b.box("vinyle", Transform3D(Basis(Vector3.UP, 0.05 * k), cp + Vector3.UP * 0.45), Vector3(1.2, 0.9, 0.8))
		b.box("chrome", Transform3D(Basis(Vector3.UP, 0.05 * k), cp + Vector3.UP * 0.9), Vector3(1.22, 0.04, 0.82))
	for k2 in range(3):
		var rp: Vector3 = _ground(18.0 + k2 * 1.0, -31.0)
		b.cyl("pneu", Transform3D(Basis(), rp), 0.35, 0.35, 0.18, 14, true)
	_avoid.append([Vector2(IleScript.W(15.0, -34.0).x, IleScript.W(15.0, -34.0).z), 4.0])
	b.commit(self, "Roadies_decor")


# ------------------------------------------------------------------- la Corderie

func _corderie() -> void:
	var b := Kit.Batch.new()
	var c: Vector3 = _ground(-28.0, -40.0)
	var L: float = 18.0
	var yaw: float = 0.0
	var bs := Basis(Vector3.UP, yaw)
	# l'abri : des poteaux, un toit de planches, la longue allée où l'on tord les cordes
	for k in range(7):
		var x: float = -L * 0.5 + k * L / 6.0
		for sz in [-1.6, 1.6]:
			var pp: Vector3 = c + bs * Vector3(x, 0, sz)
			pp.y = ile.height(pp.x, pp.z)
			b.cyl("bois", Transform3D(Basis(), pp - Vector3.UP * 0.3), 0.1, 0.09, 3.1, 8, true)
	b.box("planches", Transform3D(bs * Basis(Vector3.RIGHT, 0.12), c + Vector3(0, 2.9, 0)), Vector3(L + 0.8, 0.08, 4.2))
	# aux deux bouts, les rouets (des cadres avec des crochets), et les cordes tendues entre eux
	for ex in [-L * 0.5 + 0.5, L * 0.5 - 0.5]:
		var ep: Vector3 = c + bs * Vector3(ex, 0, 0)
		ep.y = ile.height(ep.x, ep.z)
		b.box("bois", Transform3D(bs, ep + Vector3.UP * 0.7), Vector3(0.25, 1.4, 1.6))
		b.cyl("bois", Transform3D(bs * Basis(Vector3.FORWARD, PI * 0.5), ep + Vector3.UP * 1.05 + bs * Vector3(-0.15 * signf(ex), 0, 0)), 0.32, 0.32, 0.08, 14, true)
	for r in range(3):
		var zz: float = -0.45 + r * 0.45
		var a: Vector3 = c + bs * Vector3(-L * 0.5 + 0.7, 0, zz)
		var e: Vector3 = c + bs * Vector3(L * 0.5 - 0.7, 0, zz)
		a.y = ile.height(a.x, a.z) + 1.0
		e.y = ile.height(e.x, e.z) + 1.0
		for k2 in range(6):
			var t0: float = float(k2) / 6.0
			var t1: float = float(k2 + 1) / 6.0
			b.tube("corde", a.lerp(e, t0) - Vector3.UP * 0.12 * sin(PI * t0), a.lerp(e, t1) - Vector3.UP * 0.12 * sin(PI * t1), 0.022, 6)
	# les bottes de chanvre qui sèchent, en meules, et des rouleaux de cordes
	for k3 in range(8):
		var mp: Vector3 = c + bs * Vector3(-8.0 + k3 * 2.3, 0, 4.4 + (k3 % 2) * 0.8)
		mp.y = ile.height(mp.x, mp.z)
		Kit.stook(b, mp, _rng.randf() * TAU)
	for k4 in range(4):
		var rp: Vector3 = c + bs * Vector3(-6.0 + k4 * 1.1, 0, -2.6)
		rp.y = ile.height(rp.x, rp.z)
		b.cyl("corde", Transform3D(Basis(), rp), 0.38, 0.38, 0.28, 14, true)
		b.cyl("corde", Transform3D(Basis(), rp + Vector3.UP * 0.28), 0.3, 0.3, 0.25, 14, true)
	_corde_at = c + bs * Vector3(0, 0, 0.9)
	_corde_at.y = ile.height(_corde_at.x, _corde_at.z)
	_avoid.append([Vector2(c.x, c.z), 11.5])
	b.commit(self, "Corderie_decor")


# ------------------------------------------------------------------- la Colline du Feedback

func _colline() -> void:
	var b := Kit.Batch.new()
	var c: Vector3 = _ground(8.0, -84.0)
	# le banc qui regarde la mer du sud, et le grand carillon (des tubes qui sonnent au vent)
	b.box("planches", Transform3D(Basis(), c + Vector3(0, 0.45, 2.0)), Vector3(2.2, 0.08, 0.5))
	for sx in [-0.9, 0.9]:
		b.box("bois", Transform3D(Basis(), c + Vector3(sx, 0.2, 2.0)), Vector3(0.1, 0.45, 0.45))
	var cp: Vector3 = c + Vector3(-3.5, 0, -1.0)
	cp.y = ile.height(cp.x, cp.z)
	for sx2 in [-1.2, 1.2]:
		b.cyl("bois", Transform3D(Basis(), cp + Vector3(sx2, -0.4, 0)), 0.09, 0.08, 3.4, 8, true)
	b.box("bois", Transform3D(Basis(), cp + Vector3(0, 2.95, 0)), Vector3(2.8, 0.14, 0.16))
	for k in range(7):
		var x: float = -0.9 + k * 0.3
		var l: float = 0.6 + 0.12 * k
		b.tube("corde", cp + Vector3(x, 2.9, 0), cp + Vector3(x, 2.65, 0), 0.006, 4)
		b.cyl("chrome", Transform3D(Basis(), cp + Vector3(x, 2.65 - l, 0)), 0.035, 0.035, l, 10, true)
	_carillon_at = cp + Vector3(0, 0, 1.0)
	_avoid.append([Vector2(c.x, c.z), 5.0])
	b.commit(self, "Colline_decor")
	# le grand chêne du belvédère (planté ici à la main, pas par la végétation)
	var tr := MeshInstance3D.new()
	tr.name = "Chene_du_belvedere"
	tr.mesh = preload("res://scripts/flora_v25.gd").tree(9199, 12.0, 420)
	add_child(tr)
	tr.global_position = c + Vector3(4.0, -0.2, -3.0)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.5
	sh.height = 4.0
	cs.shape = sh
	body.add_child(cs)
	add_child(body)
	body.global_position = c + Vector3(4.0, 1.8, -3.0)


# ------------------------------------------------------------------- la Plage du Larsen

func _plage() -> void:
	var b := Kit.Batch.new()
	# du bois flotté, une planche de surf plantée dans le sable, un parasol rayé
	for k in range(6):
		var dp: Vector3 = _ground(_rng.randf_range(-50.0, 50.0), _rng.randf_range(96.0, 106.0))
		if dp.y < -0.1 or absf(dp.x - IleScript.W(IleScript.DOCK_A.x, 0).x) < 5.0:
			continue
		var yaw: float = _rng.randf() * TAU
		b.cyl("bois_flotte", Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, PI * 0.5), dp + Vector3.UP * 0.12), 0.16, 0.1, _rng.randf_range(1.6, 3.2), 8, true)
	# le quatrième bus peint, garé au bord de la plage
	var bp: Vector3 = _ground(-38.0, 88.0)
	Kit.bus(b, Transform3D(Basis(Vector3.UP, 0.35), bp), "bus_3", true)
	_avoid.append([Vector2(bp.x, bp.z), 6.0])
	var sp: Vector3 = _ground(-8.0, 98.0)
	b.box("bus_1", Transform3D(Basis(Vector3.RIGHT, 0.1), sp + Vector3.UP * 0.8), Vector3(0.5, 2.0, 0.07))
	var pa: Vector3 = _ground(-16.0, 96.0)
	b.tube("bois", pa, pa + Vector3.UP * 2.3, 0.03, 6)
	b.cyl("toile_rayee", Transform3D(Basis(), pa + Vector3.UP * 2.0), 1.4, 0.05, 0.45, 12, false)
	b.box("toile_rayee", Transform3D(Basis(Vector3.UP, 0.4), pa + Vector3(0.8, 0.02, 0.6)), Vector3(1.8, 0.02, 0.9))
	b.commit(self, "Plage_decor")


# ------------------------------------------------------------------- les panneaux

func _panneaux() -> void:
	var b := Kit.Batch.new()
	for e in PANNEAUX:
		var at: Vector3 = _ground(float(e[1]), float(e[2]))
		var f2: Vector2 = (e[3] as Vector2).normalized()
		var face := Vector3(f2.x, 0, f2.y)
		var xf := Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
		Kit.sign_board(b, xf, 2.3, 1.3)
		var lb: Label3D = Kit.label(self, str(e[4]), at + Vector3.UP * 2.05 + face * 0.1, face, 0.003)
		lb.font_size = 40
		lb.width = 620.0
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panneaux.append({"id": str(e[0]), "at": at + face * 1.0, "texte": str(e[4]).replace("\n", " ")})
	b.commit(self, "Panneaux_larsen")


func _fire(at: Vector3) -> CPUParticles3D:
	var d: Node = main.get("donjon_v35") if main != null else null
	if d != null and d.has_method("_fire"):
		return d._fire(self, at - global_position, 0.3, 40)
	var p := CPUParticles3D.new()
	add_child(p)
	p.global_position = at
	return p


# =================================================================== les interactions

func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for i in range(yourtes.size()):
		var y: Dictionary = yourtes[i]
		var nm: String = str(y["nom"])
		var txt: String = "E : frapper à la porte"
		if nm == "cafe":
			txt = "E : entrer au Café Feedback"
		elif nm == "disquaire":
			txt = "E : entrer chez le Disquaire"
		d._interactions.append({"id": "larsen_porte_%d" % i, "pos": y["door"], "radius": 1.6,
			"text": txt, "vr": txt.replace("E :", "Gâchette :"), "call": _knock.bind(i)})
	for j in range(panneaux.size()):
		var pn: Dictionary = panneaux[j]
		d._interactions.append({"id": "larsen_panneau_%s" % str(pn["id"]), "pos": pn["at"], "radius": 2.2,
			"text": "E : lire le panneau", "vr": "Gâchette : lire le panneau", "call": _lire.bind(j)})
	for k in range(_djembes.size()):
		d._interactions.append({"id": "larsen_djembe_%d" % k, "pos": _djembes[k], "radius": 1.4,
			"text": "E : jouer du djembé", "vr": "Gâchette : jouer du djembé", "call": _djembe.bind(k)})
	if _carillon_at != Vector3.ZERO:
		d._interactions.append({"id": "larsen_carillon", "pos": _carillon_at, "radius": 2.2,
			"text": "E : faire sonner le carillon", "vr": "Gâchette : faire sonner le carillon", "call": _carillon})
	if _arbre_at != Vector3.ZERO:
		d._interactions.append({"id": "larsen_arbre", "pos": _arbre_at, "radius": 6.5,
			"text": "E : danser autour de l'arbre à rubans", "vr": "Gâchette : danser autour de l'arbre à rubans", "call": _arbre})
	if _ampli_at != Vector3.ZERO:
		d._interactions.append({"id": "larsen_ampli", "pos": _ampli_at, "radius": 1.8,
			"text": "E : brancher la guitare sur l'ampli", "vr": "Gâchette : brancher la guitare", "call": _ampli})
	if _corde_at != Vector3.ZERO:
		d._interactions.append({"id": "larsen_corde", "pos": _corde_at, "radius": 2.2,
			"text": "E : tordre une corde de chanvre", "vr": "Gâchette : tordre une corde", "call": _corde})


func _knock(i: int) -> void:
	var y: Dictionary = yourtes[i]
	var n: int = int(state.get("toc", 0))
	state["toc"] = n + 1
	sfx("touche_bois", y["door"])
	match str(y["nom"]):
		"cafe":
			say("Le Café Feedback est fermé. Sur la porte : « On ouvre quand on se réveille. » Par la fenêtre, des tasses, un vieux juke-box… et un chat qui dort sur l'ampli.", 7.0)
		"disquaire":
			say("Le Disquaire est fermé. Une affiche, collée de travers : « De retour après la répète. Ne pas toucher aux vinyles. Ni au chat. »", 7.0)
		_:
			var lines: Array = TOC_FLEURS if int(y["style"]) == 0 else TOC_RAIN
			say(str(lines[(n + i) % lines.size()]), 6.5)
	if n + 1 == 6:
		await get_tree().create_timer(7.0).timeout
		say("Toutes les yourtes sont vides… Où sont donc passés les habitants de l'Île de Larsen ? On dirait qu'ils préparent quelque chose.", 7.0)


func _lire(j: int) -> void:
	var pn: Dictionary = panneaux[j]
	(state["panneaux"] as Dictionary)[str(pn["id"])] = true
	say("« " + str(pn["texte"]) + " »", 7.0)


func _djembe(k: int) -> void:
	sfx("djembe", _djembes[k])
	state["djembe"] = int(state.get("djembe", 0)) + 1
	var n: int = int(state["djembe"])
	if n == 1:
		say("Boum, ba-da boum ! Le djembé résonne autour du feu… et, quelque part dans le camp, un autre tambour te répond.", 6.0)
	elif n == 8:
		say("Ba-da-boum, ba-da-boum ! Tu as trouvé le rythme du Camp des Fleurs.", 6.0)
		if main.has_method("jingle"):
			main.jingle("decouverte")


func _carillon() -> void:
	sfx("carillon", _carillon_at)
	state["carillon"] = int(state.get("carillon", 0)) + 1
	if int(state["carillon"]) == 1:
		say("Ding, dong, dilin… Les tubes du carillon chantent, et le vent les accompagne. Tout en bas, on voit les yourtes, les champs rouges, la scène, et la mer.", 7.0)


func _arbre() -> void:
	var first: bool = not bool(state.get("arbre", false))
	state["arbre"] = true
	sfx("clochette", _arbre_at)
	say("Tu prends un ruban et tu fais le tour de l'arbre en sautillant. Les rubans se tressent autour du mât, jaune, rouge, vert, bleu… c'est très joli, et un peu étourdissant." if first
		else "Encore un tour ! Les rubans s'emmêlent un peu, mais personne ne t'en voudra.", 6.5)


func _ampli() -> void:
	var first: bool = not bool(state.get("ampli", false))
	state["ampli"] = true
	sfx("larsen", _ampli_at)
	say("Tu branches la vieille guitare et tu t'approches de l'ampli… RRRIIIIIIIIIIIIII ! Un sifflement terrible : c'est l'effet Larsen ! (Voilà d'où vient le nom de l'île.)" if first
		else "Rrriiiii ! Le larsen siffle encore. Les corneilles de Rainville s'envolent, vexées.", 7.0)


func _corde() -> void:
	var first: bool = not bool(state.get("corde", false))
	state["corde"] = true
	sfx("ramasse_bois", _corde_at)
	say("Tu tournes la manivelle du rouet : les fils de chanvre se tordent ensemble, serrés, serrés… et voilà une corde solide ! Le chanvre, ici, ça sert à ça : des cordes, des toiles, de la ficelle." if first
		else "Une corde de plus pour la Corderie. Il en faudra beaucoup pour tendre la toile du festival.", 7.0)


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== services du jeu

func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["larsen_" + str(k)] = objets[k]
	journal.lieux["larsen"] = respawn_point()[0]
	_register_interactions()


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À pied : sur la terre ferme (la mare n'est pas profonde : on peut y patauger).
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	for k in ["festival", "fleurs", "rainville"]:
		var pd: Array = IleScript.PADS[k]
		if l.distance_to(Vector2(float(pd[0]), float(pd[1]))) < float(pd[2]) + 4.0:
			return k
	var ch: String = IleScript.champ_at(l.x, l.y)
	if ch != "":
		return "chanvre" if ch.begins_with("chanvre") else "coquelicots"
	if l.distance_to(Vector2(-28.0, -40.0)) < 13.0:
		return "corderie"
	if l.distance_to(Vector2(12.0, -52.0)) < 20.0:
		return "roadies"
	if l.distance_to(Vector2(float(IleScript.MARE[0]), float(IleScript.MARE[1]))) < float(IleScript.MARE[2]) + 6.0:
		return "mare"
	if l.distance_to(Vector2(float(IleScript.COLLINE[0]), float(IleScript.COLLINE[1]))) < 18.0:
		return "colline"
	if l.y < -58.0:
		return "bois"
	if IleScript.beach_k(l.x, l.y) > 0.4 and IleScript.coast_q(l.x, l.y) > 0.8:
		return "plage"
	return "prairie"


func place_name(p: Vector3) -> String:
	return "L'Île de Larsen, " + str(PLACES.get(zone_at(p), "l'île"))


## Pour la téléportation : on arrive sur la Plage du Larsen, au bout du ponton, face à l'île.
func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(14.0, 96.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, -1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func in_rain(p: Vector3) -> bool:
	if ile == null:
		return false
	var l: Vector2 = IleScript.L(p.x, p.z)
	return l.distance_to(Vector2(60.0, -2.0)) < 40.0


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var inside: bool = ile.contains(p.x, p.z)
	# la pluie de Rainville suit le promeneur ; le nuage dérive à peine
	if _rain != null:
		var wet: bool = inside and in_rain(p)
		if wet != _rain.emitting:
			_rain.emitting = wet
		if wet:
			_rain.global_position = Vector3(p.x, p.y + 15.0, p.z)
	if _cloud != null:
		_cloud.rotation.y = _clock * 0.004
	if _fire_light != null:
		_fire_light.light_energy = 2.0 + 0.35 * sin(_clock * 9.0) + 0.2 * sin(_clock * 23.0)
	if not inside:
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.2 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de Larsen — une grande ville de yourtes : les hippies du Camp des Fleurs, les grunges de Rainville… et, entre les deux, la Grande Scène")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	# le soir, les lumières s'allument ; les ampoules brillent plus fort
	var h: float = hour()
	var night: bool = h < 6.5 or h > 19.5
	for e in _night_lights:
		(e[0] as OmniLight3D).visible = night
	var lampe: StandardMaterial3D = Kit.mat("lampe")
	lampe.emission_energy_multiplier = 2.4 if night else 0.35
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z in ["fleurs", "rainville", "festival", "chanvre", "coquelicots", "colline", "corderie", "mare", "bois"] and not bool(vis.get(z, false)):
		vis[z] = true
		match z:
			"fleurs":
				main._show_message_v28("Le Camp des Fleurs — des yourtes en rond autour du feu, des fanions, des bus peints, et des tambours qui ne dorment jamais")
			"rainville":
				main._show_message_v28("Rainville — des yourtes sombres, des garages, des amplis… et un petit nuage qui ne s'en va jamais")
			"festival":
				main._show_message_v28("La Prairie du Festival — la Grande Scène attend son festival")
			"chanvre":
				main._show_message_v28("Les champs de chanvre — de hautes tiges vertes : on en fait des cordes et des toiles")
			"coquelicots":
				main._show_message_v28("Les champs de coquelicots — un grand tapis rouge qui ondule au vent")
			"colline":
				main._show_message_v28("La Colline du Feedback — d'ici, on voit toute l'île… et on entend le vent siffler")
			"corderie":
				main._show_message_v28("La Corderie — ici, le chanvre devient corde")
			"mare":
				main._show_message_v28("La Mare aux Mantras — une eau calme, des nénuphars, des grenouilles qui méditent")
			"bois":
				main._show_message_v28("Le Bois des Riffs — des chênes et des bouleaux ; le vent y joue de la guitare dans les feuilles")
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"larsen": 1 if bool(state.get("visite", false)) else 0,
		"larsen_fleurs": 1 if bool(vis.get("fleurs", false)) else 0, "larsen_rainville": 1 if bool(vis.get("rainville", false)) else 0,
		"larsen_scene": 1 if bool(vis.get("festival", false)) else 0, "larsen_chanvre": 1 if bool(vis.get("chanvre", false)) else 0,
		"larsen_coquelicots": 1 if bool(vis.get("coquelicots", false)) else 0, "larsen_colline": 1 if bool(vis.get("colline", false)) else 0,
		"larsen_djembe": 1 if int(state.get("djembe", 0)) >= 8 else 0, "larsen_ampli": 1 if bool(state.get("ampli", false)) else 0,
		"larsen_corde": 1 if bool(state.get("corde", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)

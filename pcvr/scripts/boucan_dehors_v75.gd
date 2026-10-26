extends Node3D
## V75 : le dehors de l'Île du Boucan (hors de la ville-friche) :
##  - le GAZOMÈTRE, la CATHÉDRALE DES SPORES : la carcasse d'acier, la forêt de champignons géants
##    lumineux qui y a poussé, la roulotte de Mère Morille ; autour, le Bois des Spores et ses
##    champignons ; des spores qui flottent ;
##  - l'USINE GRISE de Lisse & Fils (le béton, le grillage, le portail, la loge, le logement de
##    fonction de la famille Lisse) et l'entrée du donjon (le grand rideau de fer du quai de
##    chargement) ;
##  - la CASSE : les épaves, les montagnes de ferraille, l'atelier de Ferraille et son dragon ;
##  - la PLAGE AUX GALETS (le feu de camp, la cabane de Gravier) ; le PHARE TAGUÉ ;
##  - les poteaux indicateurs, et le réseau des chemins pour les habitants.

const R = preload("res://scripts/ile_boucan_v75.gd")

var main: Node
var manager: Node                        # boucan_v75
var ile: Node3D
var city: Node3D
var kit
var objets: Dictionary = {}
var fire_spots: Array = []
var flora_avoid: Array = []
var mushrooms: Array = []                # [Vector3 (le chapeau), rayon, couleur] : les champignons géants
var spore_emitters: Array = []           # CPUParticles3D : les spores qui flottent
var spore_lights: Array = []             # OmniLight3D : la lueur de la cathédrale
var dungeon_door := Vector3.ZERO         # devant le rideau de fer du quai de chargement
var dungeon_face := Vector3(0, 0, 1)     # vers où l'on regarde en sortant
var phare_light: SpotLight3D             # le faisceau du phare (il tourne la nuit)
var phare_top := Vector3.ZERO
var gazo_center := Vector3.ZERO
var animals: Array = []                  # [espèce, Vector3, rayon]
var _rng := RandomNumberGenerator.new()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Un point au sol (repère île).
func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func GX(x: float, z: float, dx: float, dz: float) -> Transform3D:
	var p: Vector3 = G(x, z)
	var d := Vector3(dx, 0, dz).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


func build(owner: Node) -> void:
	manager = owner
	main = owner.main
	ile = owner.ile
	city = owner.city
	kit = load("res://scripts/boucan_kit_v75.gd").new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = owner.pc
	kit.rng.seed = 7581
	kit.light_every = 1
	_rng.seed = 7582
	_gazometre()
	_bois()
	_usine()
	_casse()
	_plage()
	_phare()
	_panneaux()
	kit.commit()
	for f in kit.fires70:
		fire_spots.append(f)
	_graph()


# =================================================================== le Gazomètre

func _gazometre() -> void:
	var c: Vector3 = G(R.GAZO.x, R.GAZO.y)
	gazo_center = c
	kit.gazometre75(c, R.GAZO_R, 40.0, 18)
	# les grands champignons, dedans : des chapeaux de toutes tailles qui se chevauchent
	var big := [[0.0, -6.0, 15.0, 7.0, "bleu"], [-14.0, 6.0, 12.0, 5.6, "violet"], [12.0, 10.0, 10.5, 5.0, "orange"], [16.0, -12.0, 13.0, 6.0, "bleu"],
		[-12.0, -16.0, 9.0, 4.4, "orange"], [-22.0, -4.0, 7.5, 3.6, "bleu"], [4.0, 20.0, 8.5, 4.2, "violet"], [22.0, 4.0, 6.5, 3.2, "violet"],
		[-4.0, 12.0, 5.0, 2.6, "bleu"], [-20.0, 14.0, 5.5, 2.8, "orange"], [6.0, -22.0, 6.0, 3.0, "violet"], [-6.0, -24.0, 4.5, 2.4, "bleu"]]
	for b in big:
		var p: Vector3 = G(R.GAZO.x + float(b[0]), R.GAZO.y + float(b[1]))
		var top: Vector3 = kit.champi75(p, float(b[2]), float(b[3]), str(b[4]), _rng.randf_range(-6.0, 6.0), _rng.randf() * TAU)
		mushrooms.append([top, float(b[3]), str(b[4])])
	# des petits, partout sur la mousse
	for i in range(46):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * (R.GAZO_R - 3.0)
		var p2: Vector3 = G(R.GAZO.x + cos(a) * r, R.GAZO.y + sin(a) * r)
		var h: float = _rng.randf_range(0.5, 2.6)
		kit.champi75(p2, h, h * _rng.randf_range(0.45, 0.8), ["bleu", "violet", "orange"][_rng.randi() % 3], _rng.randf_range(-12.0, 12.0), _rng.randf() * TAU)
	# la roulotte de Mère Morille (au milieu, sous le grand bleu)
	var rx: Transform3D = GX(R.GAZO.x + 6.0, R.GAZO.y + 2.0, -1.0, 0.4)
	_roulotte(rx)
	city.doors["porte_morille"] = city._pt("porte_morille", rx * Vector3(0, 0.05, 2.6))
	city._pt("ga_roulotte", rx * Vector3(1.6, 0.05, 3.6))
	city._spot("gazometre_roulotte", rx * Vector3(-1.0, 0.05, 2.8), rx.basis * Vector3(0, 0, 1), "assis", "ga_roulotte")
	city._pt("ga_centre", G(R.GAZO.x - 4.0, R.GAZO.y + 2.0, 0.05))
	city._spot("gazometre_centre", G(R.GAZO.x - 5.0, R.GAZO.y + 3.0, 0.05), Vector3(1, 0, 0), "observer", "ga_centre")
	city._pt("ga_porte", G(R.GAZO.x, R.GAZO.y - R.GAZO_R + 2.0, 0.05))
	city._pt("ga_dehors", G(R.GAZO.x + 6.0, R.GAZO.y - R.GAZO_R - 8.0, 0.05))
	city._chain(["ga_dehors", "ga_porte", "ga_centre", "ga_roulotte", "porte_morille"])
	# un cercle de pierres, un tronc moussu, des lanternes
	for k in range(9):
		var a2: float = TAU * k / 9.0
		kit.ball(Transform3D(Basis.from_scale(Vector3(1.0, 0.6, 1.0)), G(R.GAZO.x - 4.0 + cos(a2) * 3.2, R.GAZO.y + 3.0 + sin(a2) * 3.2, 0.1)), 0.42, "beton75_mousse", 7, 4)
	kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, 0.4), G(R.GAZO.x - 10.0, R.GAZO.y - 8.0, 0.4)), 0.45, 0.4, 6.0, "bardage75_mousse", 10, true, 2.0)
	# les champignons de la quête de Mère Morille (bo_champignons) : un de chaque sorte
	var champs := [[-14.0, 9.0], [13.0, 13.0], [-9.0, -18.0], [18.0, -8.0], [2.0, 24.0]]
	for i2 in range(champs.size()):
		objets["champi_%d" % (i2 + 1)] = G(R.GAZO.x + float(champs[i2][0]), R.GAZO.y + float(champs[i2][1]), 0.15)
	# la lueur (quatre lumières douces, colorées) et les spores
	for k2 in range(4):
		var a3: float = TAU * k2 / 4.0 + 0.4
		var l := OmniLight3D.new()
		l.light_color = [Color(0.4, 0.75, 1.0), Color(0.7, 0.45, 1.0), Color(1.0, 0.6, 0.3), Color(0.4, 0.9, 0.9)][k2]
		l.light_energy = 0.6
		l.omni_range = 26.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		l.distance_fade_enabled = true
		l.distance_fade_begin = 90.0
		l.distance_fade_length = 20.0
		add_child(l)
		l.position = G(R.GAZO.x + cos(a3) * 14.0, R.GAZO.y + sin(a3) * 14.0, 6.0)
		spore_lights.append(l)
	for k3 in range(3):
		spore_emitters.append(_spores(G(R.GAZO.x + (k3 - 1) * 12.0, R.GAZO.y + (k3 - 1) * -6.0, 1.0), ["bleu", "violet", "orange"][k3], 22.0))
	flora_avoid.append([Vector2(c.x, c.z), R.GAZO_R + 4.0])
	animals.append(["chat", G(R.GAZO.x + 7.0, R.GAZO.y + 4.0, 2.4), 1.0])


## La roulotte : une caisse de bois peinte sur quatre roues, un toit arrondi, un escalier, un tuyau
## de poêle (xf : le devant, la porte regarde +Z).
func _roulotte(xf: Transform3D) -> void:
	kit.box(xf * T(0, 1.9, -1.4), Vector3(4.6, 2.2, 2.4), "peint75_vert", 1.2)
	# le toit arrondi (un demi-tonneau : un cylindre couché, aplati, dont le bas est dans la caisse)
	kit.cyl(xf * Transform3D(Basis(Vector3.BACK, -PI * 0.5) * Basis.from_scale(Vector3(0.62, 1.0, 1.0)), Vector3(-2.45, 3.0, -1.4)), 1.32, 1.32, 4.9, "peint75_rouge", 16, true, 1.2)
	for sx in [-1.6, 1.6]:
		for sz in [-2.5, -0.3]:
			kit.ring(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(sx + (0.15 if sx > 0 else -0.15), 0.6, sz)), 0.45, 0.6, 0.12, "peint75_jaune", 12)
	kit.box(xf * T(0, 1.4, -0.18), Vector3(0.9, 1.8, 0.06), "peint75_bleu", 1.0)
	kit.stair(xf * Vector3(0, 0.0, 1.4), xf * Vector3(0, 0.8, -0.1), 0.9, "palette75")
	kit.cyl(xf * T(1.4, 3.3, -2.2), 0.08, 0.08, 1.2, "metal75_noir", 6, false)
	kit.col_box(xf * T(0, 1.9, -1.4), Vector3(4.6, 2.6, 2.4))
	for s in [-1.0, 1.0]:
		kit.box(xf * T(s * 1.6, 2.1, -0.18), Vector3(0.7, 0.6, 0.04), "vitre75_on", 1.0)
	kit.guirlande75(xf * Vector3(-2.3, 3.0, 0.0), xf * Vector3(2.3, 3.0, 0.0), 0.3, 0.45)
	kit.box(xf * T(-2.8, 0.4, 0.8), Vector3(0.9, 0.8, 0.6), "palette75", 1.0)
	fire_spots.append([xf * Vector3(2.8, 0.15, 1.2), 0.35])
	for k2 in range(6):
		var a: float = TAU * k2 / 6.0
		kit.ball(Transform3D(Basis.from_scale(Vector3(1, 0.5, 1)), xf * Vector3(2.8 + cos(a) * 0.55, 0.1, 1.2 + sin(a) * 0.55)), 0.18, "beton75", 6, 3)


## Des spores qui flottent (un nuage de petits points lumineux qui montent lentement).
func _spores(at: Vector3, couleur: String, radius: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 60.0
	p.gravity = Vector3(0, 0.06, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var qm := QuadMesh.new()
	qm.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = {"bleu": Color(0.5, 0.85, 1.0, 0.8), "violet": Color(0.8, 0.55, 1.0, 0.8), "orange": Color(1.0, 0.7, 0.35, 0.8)}[couleur]
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-radius - 4.0, -4.0, -radius - 4.0), Vector3(radius * 2.0 + 8.0, 30.0, radius * 2.0 + 8.0))
	add_child(p)
	p.position = at
	return p


# =================================================================== le Bois des Spores

func _bois() -> void:
	# des champignons moyens et petits entre les arbres (les arbres : la flore)
	for i in range(70):
		var a: float = _rng.randf() * TAU
		var r: float = R.GAZO_R + 8.0 + sqrt(_rng.randf()) * (R.SPORES_R - R.GAZO_R - 10.0)
		var x: float = R.GAZO.x + cos(a) * r
		var z: float = R.GAZO.y + sin(a) * r
		if R.coast_q(x, z) > 0.86 or _near_path(x, z, 4.0):
			continue
		var h: float = _rng.randf_range(0.6, 4.5) if _rng.randf() < 0.85 else _rng.randf_range(5.0, 8.0)
		kit.champi75(G(x, z), h, h * _rng.randf_range(0.45, 0.75), ["bleu", "violet", "orange"][_rng.randi() % 3], _rng.randf_range(-14.0, 14.0), _rng.randf() * TAU)
	spore_emitters.append(_spores(G(R.GAZO.x - 50.0, R.GAZO.y + 30.0, 1.0), "violet", 18.0))
	spore_emitters.append(_spores(G(R.GAZO.x + 46.0, R.GAZO.y - 20.0, 1.0), "bleu", 18.0))
	city._pt("sp_1", G(R.GAZO.x - 46.0, R.GAZO.y + 24.0, 0.05))
	city._pt("sp_2", G(R.GAZO.x + 44.0, R.GAZO.y - 30.0, 0.05))
	city._spot("spores_1", G(R.GAZO.x - 47.0, R.GAZO.y + 25.0, 0.05), Vector3(1, 0, 0), "observer", "sp_1")
	city._spot("spores_2", G(R.GAZO.x + 45.0, R.GAZO.y - 31.0, 0.05), Vector3(-1, 0, 0), "jardiner", "sp_2")
	animals.append(["rat", G(R.GAZO.x + 40.0, R.GAZO.y - 26.0, 0.0), 4.0])


func _near_path(x: float, z: float, d: float) -> bool:
	var w: Vector3 = R.W(x, z)
	for k in ile.paths_world:
		for q in ile.paths_world[k]:
			if Vector2((q as Vector3).x - w.x, (q as Vector3).z - w.z).length() < d:
				return true
	return false


# =================================================================== l'Usine Grise

func _usine() -> void:
	var c: Vector3 = G(R.USINE.x, R.USINE.y)
	var y: float = c.y
	# l'enceinte grillagée (70 × 60), le portail (côté ouest, vers le chemin)
	var hw := Vector2(35.0, 30.0)
	var corners := [Vector2(-hw.x, -hw.y), Vector2(hw.x, -hw.y), Vector2(hw.x, hw.y), Vector2(-hw.x, hw.y)]
	for i in range(4):
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		if i == 3:
			# le côté ouest : le portail au milieu
			kit.grillage75(R.W(R.USINE.x + a.x, R.USINE.y + a.y, y), R.W(R.USINE.x + a.x, R.USINE.y - 5.0, y))
			kit.grillage75(R.W(R.USINE.x + a.x, R.USINE.y + 5.0, y), R.W(R.USINE.x + b.x, R.USINE.y + b.y, y))
		else:
			kit.grillage75(R.W(R.USINE.x + a.x, R.USINE.y + a.y, y), R.W(R.USINE.x + b.x, R.USINE.y + b.y, y))
	var gate: Vector3 = R.W(R.USINE.x - hw.x, R.USINE.y, y)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(Basis(), gate + Vector3(0, 1.5, s * 5.2)), Vector3(0.4, 3.0, 0.4), "beton75", 1.0)
		kit.col_box(Transform3D(Basis(), gate + Vector3(0, 1.5, s * 5.2)), Vector3(0.4, 3.0, 0.4))
	# le portail est ouvert (poussé de côté) : une grille sur roulettes
	kit.quad(Transform3D(Basis(Vector3.UP, PI * 0.5), gate + Vector3(0.4, 1.2, -9.0)), 8.0, 2.4, "grillage75", Vector2(0, 0), Vector2(16, 4.8), true)
	kit.quadz(Transform3D(Basis(Vector3.UP, -PI * 0.5), gate + Vector3(-0.3, 3.2, 0)), 6.0, 1.2, "enseigne75_lisse")
	kit.box(Transform3D(Basis(), gate + Vector3(0.0, 3.2, 0)), Vector3(0.2, 0.2, 10.8), "metal75_gris", 1.0)
	# la loge du gardien (un petit cube de béton, une barrière)
	var lx: Transform3D = Transform3D(Basis(Vector3.UP, -PI * 0.5), gate + Vector3(4.0, 0, 8.0))
	kit.box(lx * T(0, 1.3, -1.2), Vector3(3.0, 2.6, 2.4), "beton75_clair", 1.4)
	kit.box(lx * T(0, 1.6, 0.01), Vector3(2.4, 0.8, 0.02), "vitre75_on", 1.0)
	kit.col_box(lx * T(0, 1.3, -1.2), Vector3(3.0, 2.6, 2.4))
	# l'usine : un grand bloc de béton gris, propre, des fenêtres en bandeau, deux cheminées d'inox
	var fx: Transform3D = GX(R.USINE.x + 8.0, R.USINE.y + 12.0, -1.0, 0.0)
	var fw: float = 40.0
	var fd: float = 26.0
	kit.usine75(fx, fw, fd, {"h": 12.0, "wall": "beton75_clair", "roof": "plat", "rows": 2, "lit": 0.25, "bay": 5.0, "pilasters": false, "cornice": true,
		"cornice_key": "tolep75_gris", "sign": "lisse", "sign_w": 16.0, "sign_h": 2.4, "sign_y": 9.6})
	for k in range(2):
		var sp: Vector3 = fx * Vector3(-8.0 + k * 10.0, 12.0, -18.0)
		kit.cyl(Transform3D(Basis(), sp), 0.9, 0.8, 10.0, "chrome75", 14, false)
		kit.ring(Transform3D(Basis(), sp + Vector3.UP * 9.6), 0.78, 1.0, 0.4, "tolep75_jaune", 14)
	# le quai de chargement et son grand rideau de fer : l'entrée du donjon
	var dock: Transform3D = fx * T(6.0, 0, 0)
	kit.box(dock * T(0, 0.6, 2.0), Vector3(10.0, 1.2, 4.0), "beton75", 2.0)
	kit.col_box(dock * T(0, 0.6, 2.0), Vector3(10.0, 1.2, 4.0))
	kit.stair(dock * Vector3(-6.4, 0.0, 2.0), dock * Vector3(-5.0, 1.2, 2.0), 3.0, "beton75")
	kit.box(dock * T(0, 3.6, 0.06), Vector3(6.4, 4.8, 0.1), "tolep75_jaune", 1.2)
	for k2 in range(12):
		kit.box(dock * T(0, 1.4 + k2 * 0.4, 0.13), Vector3(6.4, 0.04, 0.04), "acier75", 1.0)
	kit.quadz(dock * T(0, 6.5, 0.2), 6.0, 1.0, "enseigne75_lisse")
	for s2 in [-1.0, 1.0]:
		kit.box(dock * T(s2 * 3.6, 3.5, 0.3), Vector3(0.12, 0.6, 0.12), "neon75_rouge", 1.0)
	dungeon_door = dock * Vector3(0, 1.25, 2.6)
	dungeon_face = (fx.basis * Vector3(0, 0, 1)).normalized()
	objets["usine_porte"] = dungeon_door
	# le logement de fonction de la famille Lisse (un cube blanc, une haie taillée au carré)
	var hx: Transform3D = GX(R.USINE.x + 16.0, R.USINE.y - 20.0, -1.0, 0.0)
	kit.box(hx * T(0, 3.2, -4.0), Vector3(9.0, 6.4, 8.0), "tolep75_blanc", 2.0)
	kit.box(hx * T(0, 6.5, -4.0), Vector3(9.4, 0.2, 8.4), "tolep75_gris", 2.0)
	kit.col_box(hx * T(0, 3.2, -4.0), Vector3(9.0, 6.4, 8.0))
	for k3 in range(3):
		kit.box(hx * T(-3.0 + k3 * 3.0, 4.6, 0.01), Vector3(1.8, 1.4, 0.02), "vitre75_on", 1.0)
	kit.box(hx * T(-3.0, 1.6, 0.01), Vector3(1.8, 1.4, 0.02), "vitre75_off", 1.0)
	kit.place("porte75|gris", hx * T(2.2, 0.0, 0.0))
	for s3 in [-1.0, 1.0]:
		kit.box(hx * T(s3 * 6.0, 0.6, 1.0), Vector3(2.0, 1.2, 0.8), "feuille75", 1.0)
	var hd: Vector3 = hx * Vector3(2.2, 0.05, 1.2)
	for who in ["lisse", "gedeon", "prune"]:
		city.doors["porte_" + who] = city._pt("porte_" + who, hd)
	# des caisses, des robots en pièces détachées (décor), le repaire des robots près du portail
	for k4 in range(6):
		kit.crate(G(R.USINE.x - 22.0 + (k4 % 3) * 1.6, R.USINE.y - 18.0 + int(k4 / 3) * 1.6), _rng.randf() * TAU, 0.8, true)
	objets["guitare_rouille"] = G(R.USINE.x - 22.0, R.USINE.y - 15.0, 0.15)
	objets["usine_cour"] = G(R.USINE.x - 18.0, R.USINE.y - 8.0)
	# le réseau : le portail, la loge, le quai, le logement
	city._pt("us_dehors", gate + Vector3(-5.0, 0.05, 0.0))
	city._pt("us_portail", gate + Vector3(3.0, 0.05, 0.0))
	city._pt("us_quai", dock * Vector3(-7.4, 0.05, 2.0))
	city._pt("us_logement", hd + (hx.basis * Vector3(0, 0, 2.0)))
	city._chain(["us_dehors", "us_portail", "us_quai"])
	city._chain(["us_portail", "us_logement"])
	for who2 in ["lisse", "gedeon", "prune"]:
		city._link("porte_" + who2, "us_logement")
	city._spot("usine_portail", gate + Vector3(2.0, 0.05, 3.4), Vector3(-1, 0, 0), "bras_croises", "us_portail")
	flora_avoid.append([Vector2(c.x, c.z), 40.0])


# =================================================================== la Casse

func _casse() -> void:
	var c: Vector3 = G(R.CASSE.x, R.CASSE.y)
	# des épaves en tas, des pneus, des barils, des montagnes de ferraille
	var colors := ["rouge", "bleu", "vert", "jaune", "blanc", "orange"]
	for i in range(16):
		var a: float = _rng.randf() * TAU
		var r: float = 6.0 + _rng.randf() * 16.0
		var p: Vector3 = G(R.CASSE.x + cos(a) * r, R.CASSE.y + sin(a) * r)
		var yaw: float = _rng.randf() * TAU
		kit.voiture75(Transform3D(Basis(Vector3.UP, yaw), p), colors[_rng.randi() % colors.size()], _rng.randf() < 0.6)
		if i % 4 == 0:
			kit.voiture75(Transform3D(Basis(Vector3.UP, yaw + 0.3) * Basis(Vector3.BACK, 0.12), p + Vector3.UP * 1.55), colors[_rng.randi() % colors.size()], true)
	for i2 in range(5):
		var a2: float = TAU * i2 / 5.0 + 0.3
		var hp: Vector3 = G(R.CASSE.x + cos(a2) * 19.0, R.CASSE.y + sin(a2) * 19.0)
		for k in range(14):
			var q: Vector3 = hp + Vector3(_rng.randf_range(-2.4, 2.4), _rng.randf_range(0.0, 2.6), _rng.randf_range(-2.4, 2.4))
			kit.box(Transform3D(Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU), q), Vector3(_rng.randf_range(0.4, 2.0), _rng.randf_range(0.1, 0.8), _rng.randf_range(0.4, 1.8)), ["acier75", "tole75", "tolep75_bleu", "rivete75"][_rng.randi() % 4], 1.0)
		kit.col_cyl(hp, 2.8, 3.0)
		kit.pneus75(hp + Vector3(3.4, 0, 1.0), 2 + i2 % 3)
	for i3 in range(6):
		kit.baril75(G(R.CASSE.x - 4.0 + i3 * 1.0, R.CASSE.y + 10.0))
	# l'atelier de Ferraille (un hangar de tôle, un établi de soudeur, un poste à souder qui crépite)
	var ax: Transform3D = GX(R.CASSE.x - 10.0, R.CASSE.y - 14.0, 0.3, 1.0)
	kit.box(ax * T(0, 2.0, -3.0), Vector3(7.0, 4.0, 6.0), "tole75", 1.4, 63 - 16)
	kit.box(ax * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 4.2, -3.0)), Vector3(7.6, 0.08, 6.8), "tole75", 1.4)
	kit.col_box(ax * T(0, 2.0, -5.9), Vector3(7.0, 4.0, 0.2))
	for s in [-1.0, 1.0]:
		kit.col_box(ax * T(s * 3.4, 2.0, -3.0), Vector3(0.2, 4.0, 6.0))
	kit.box(ax * T(0, 0.85, -4.6), Vector3(3.6, 0.1, 1.2), "acier75", 1.0)
	kit.col_box(ax * T(0, 0.45, -4.6), Vector3(3.6, 0.9, 1.2))
	city.doors["porte_ferraille"] = city._pt("porte_ferraille", ax * Vector3(2.4, 0.05, -5.0))
	city._pt("ca_atelier", ax * Vector3(0, 0.05, -1.6))
	city._spot("casse_atelier", ax * Vector3(0, 0.05, -3.6), ax.basis * Vector3(0, 0, -1), "bricoler", "ca_atelier")
	city._link("porte_ferraille", "ca_atelier")
	# le dragon de ferraille (12 m : une échine de poutres, des côtes, une tête, des ailes de tôle)
	var dx: Transform3D = GX(R.CASSE.x + 10.0, R.CASSE.y + 4.0, -1.0, 0.4)
	_dragon(dx)
	city._pt("ca_dragon", dx * Vector3(0, 0.05, 6.0))
	city._spot("casse_dragon", dx * Vector3(1.0, 0.05, 5.0), dx.basis * Vector3(0, 0, -1), "observer", "ca_dragon")
	# des robots-fleurs (des sculptures : une tige de tuyau, une tête de phare, des pétales de tôle)
	for k2 in range(5):
		var fp: Vector3 = G(R.CASSE.x - 18.0 + k2 * 4.0, R.CASSE.y + 18.0)
		kit.cyl(Transform3D(Basis(), fp), 0.08, 0.06, 2.6 + k2 * 0.3, "acier75", 6, false)
		var head: Vector3 = fp + Vector3.UP * (2.6 + k2 * 0.3)
		kit.ball(Transform3D(Basis(), head), 0.25, "chrome75", 8, 4)
		for k3 in range(6):
			var a3: float = TAU * k3 / 6.0
			kit.box(Transform3D(Basis(Vector3.UP, a3) * Basis(Vector3.RIGHT, 0.5), head + Vector3(cos(a3), 0, -sin(a3)) * 0.45), Vector3(0.3, 0.04, 0.6), "tolep75_" + ["rouge", "jaune", "rose", "orange", "violet"][k2], 1.0)
	# les objets des quêtes : l'ampli du groupe, les pièces de vélo, l'endroit où se cache Sardine
	objets["ampli"] = G(R.CASSE.x + 14.0, R.CASSE.y - 10.0, 0.15)
	objets["velo_1"] = G(R.CASSE.x - 16.0, R.CASSE.y - 6.0, 0.15)
	objets["velo_2"] = G(R.CASSE.x + 4.0, R.CASSE.y + 16.0, 0.15)
	objets["velo_3"] = G(R.CASSE.x + 18.0, R.CASSE.y + 10.0, 0.15)
	objets["sardine"] = G(R.CASSE.x + 6.0, R.CASSE.y - 16.0, 0.0)
	objets["casse"] = c
	city._pt("ca_entree", G(R.CASSE.x - 18.0, R.CASSE.y - 22.0, 0.05))
	city._pt("ca_milieu", G(R.CASSE.x, R.CASSE.y, 0.05))
	city._chain(["ca_entree", "ca_atelier", "ca_milieu", "ca_dragon"])
	flora_avoid.append([Vector2(c.x, c.z), 28.0])
	animals.append(["chat", G(R.CASSE.x - 6.0, R.CASSE.y + 4.0, 1.6), 1.0])
	animals.append(["rat", G(R.CASSE.x + 2.0, R.CASSE.y - 4.0, 0.0), 4.0])


func _dragon(xf: Transform3D) -> void:
	var spine: Array = []
	for i in range(12):
		var t: float = float(i) / 11.0
		spine.append(xf * Vector3(sin(t * PI * 1.4) * 2.0, 1.6 + sin(t * PI) * 4.0 + (2.6 if i == 11 else 0.0), -6.0 + t * 12.0))
	for i2 in range(spine.size() - 1):
		kit.beam(spine[i2], spine[i2 + 1], 0.35, "acier75")
		if i2 > 1 and i2 < 9:
			for s in [-1.0, 1.0]:
				var rib: Vector3 = (spine[i2] as Vector3) + xf.basis * Vector3(s * 1.4, -1.4, 0)
				kit.beam(spine[i2], rib, 0.14, "rivete75")
				kit.beam(rib, Vector3(rib.x, ile.height(rib.x, rib.z), rib.z), 0.2, "acier75")
	# la tête : une calandre de camion, deux phares pour les yeux, une mâchoire
	var hd: Vector3 = spine[-1]
	kit.box(Transform3D(xf.basis, hd), Vector3(1.6, 1.2, 2.2), "tolep75_rouge", 1.0)
	kit.box(Transform3D(xf.basis * Basis(Vector3.RIGHT, 0.3), hd + xf.basis * Vector3(0, -0.8, 0.6)), Vector3(1.4, 0.2, 1.8), "acier75", 1.0)
	for s2 in [-0.5, 0.5]:
		kit.ball(Transform3D(Basis(), hd + xf.basis * Vector3(s2, 0.3, 1.1)), 0.2, "lampe75", 8, 4)
		kit.beam(hd + xf.basis * Vector3(s2, 0.6, -0.6), hd + xf.basis * Vector3(s2 * 1.6, 2.0, -1.6), 0.08, "chrome75")
	# les ailes : deux grandes tôles, levées
	for s3 in [-1.0, 1.0]:
		var w0: Vector3 = spine[5]
		kit.quad(Transform3D(xf.basis * Basis(Vector3.BACK, s3 * 0.6) * Basis(Vector3.UP, s3 * 0.2), w0 + xf.basis * Vector3(s3 * 3.6, 2.0, 0)), 5.6, 3.2, "tole75", Vector2(0, 0), Vector2(2, 1), true)
	# la queue (vers -Z) : une chaîne de pots d'échappement
	var tail: Vector3 = spine[0]
	kit.beam(tail, tail + xf.basis * Vector3(1.0, -1.2, -3.0), 0.16, "chrome75")
	kit.col_box(Transform3D(xf.basis, xf * Vector3(0, 2.0, 0)), Vector3(3.0, 4.0, 12.0))


# =================================================================== la Plage aux Galets, le Phare

func _plage() -> void:
	var fc: Vector3 = G(184.0, 92.0)
	# le cercle du feu de camp : des pierres, des troncs pour s'asseoir, le feu
	for k in range(10):
		var a: float = TAU * k / 10.0
		kit.ball(Transform3D(Basis.from_scale(Vector3(1, 0.55, 1)), fc + Vector3(cos(a) * 1.0, 0.1, sin(a) * 1.0)), 0.22, "beton75", 6, 3)
	fire_spots.append([fc + Vector3.UP * 0.2, 0.7])
	for k2 in range(3):
		var a2: float = TAU * k2 / 3.0 + 0.5
		var lp: Vector3 = fc + Vector3(cos(a2) * 3.2, 0.25, sin(a2) * 3.2)
		kit.cyl(Transform3D(Basis(Vector3.UP, -a2) * Basis(Vector3.BACK, PI * 0.5), lp + Vector3(-sin(a2), 0, cos(a2)) * 1.4), 0.25, 0.25, 2.8, "bardage75_sombre", 10, true, 1.0)
		kit.col_box(Transform3D(Basis(Vector3.UP, -a2), lp), Vector3(0.5, 0.5, 2.8))
	city._pt("pl_feu", fc + Vector3(-4.5, 0.05, 0.0))
	city._spot("plage_feu", fc + Vector3(cos(0.5) * 3.2, 0.5, sin(0.5) * 3.2), -Vector3(cos(0.5), 0, sin(0.5)), "assis", "pl_feu")
	objets["plage_feu"] = fc
	# la cabane de Gravier, sur pilotis, ses filets, une barque retournée
	var cx: Transform3D = GX(196.0, 70.0, -1.0, 0.6)
	for sx in [-1.6, 1.6]:
		for sz in [-0.4, -3.6]:
			kit.cyl(cx * T(sx, -1.0, sz), 0.12, 0.12, 2.2, "bardage75_sombre", 6, false)
	kit.box(cx * T(0, 1.2, -2.0), Vector3(3.8, 0.2, 4.2), "bardage75", 1.0)
	kit.box(cx * T(0, 2.4, -2.4), Vector3(3.6, 2.4, 3.2), "bardage75", 1.2)
	kit.box(cx * Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3(0, 3.8, -2.4)), Vector3(4.2, 0.08, 4.0), "tole75", 1.4)
	kit.col_box(cx * T(0, 1.6, -2.2), Vector3(3.8, 3.2, 4.2))
	kit.place("porte75|bleu", cx * T(-0.6, 1.3, -0.79))
	kit.stair(cx * Vector3(1.2, 0.0, 1.4), cx * Vector3(1.2, 1.3, -0.3), 0.9, "bardage75")
	city.doors["porte_gravier"] = city._pt("porte_gravier", cx * Vector3(1.2, 0.05, 2.0))
	city._pt("pl_cabane", cx * Vector3(2.6, 0.05, 2.4))
	city._spot("plage_cabane", cx * Vector3(3.0, 0.05, 1.0), cx.basis * Vector3(0.4, 0, 1).normalized(), "pecher", "pl_cabane")
	city._link("porte_gravier", "pl_cabane")
	city._link("pl_cabane", "pl_feu")
	var bx: Transform3D = GX(176.0, 104.0, 1.0, 0.2)
	kit.box(bx * Transform3D(Basis(Vector3.BACK, PI), Vector3(0, 0.45, 0)), Vector3(1.6, 0.6, 4.2), "peint75_bleu", 1.0)
	kit.col_box(bx * T(0, 0.35, 0), Vector3(1.6, 0.7, 4.2))
	animals.append(["mouette", G(190.0, 104.0, 0.0), 10.0])


func _phare() -> void:
	var p: Vector3 = G(R.PHARE.x, R.PHARE.y - 4.0)
	phare_top = kit.phare75(p)
	var l := SpotLight3D.new()
	l.light_color = Color(1.0, 0.92, 0.75)
	l.light_energy = 8.0
	l.spot_range = 220.0
	l.spot_angle = 6.0
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 3.0
	add_child(l)
	l.position = phare_top
	phare_light = l
	city._pt("ph_pied", p + Vector3(-4.4, 0.05, -3.0))
	city._spot("phare", p + Vector3(-4.0, 0.05, -4.0), Vector3(-0.4, 0, -1).normalized(), "observer", "ph_pied")
	objets["phare"] = p


## Des poteaux indicateurs aux carrefours (la ville, le Gazomètre, l'Usine, la Casse, le phare).
func _panneaux() -> void:
	for spec in [[-12.0, 16.0], [44.0, 60.0], [-24.0, 46.0], [130.0, 6.0]]:
		var p: Vector3 = G(float(spec[0]) + 2.5, float(spec[1]) + 2.5)
		kit.box(Transform3D(Basis(), p + Vector3.UP * 1.2), Vector3(0.12, 2.4, 0.12), "acier75", 1.0)
		for k in range(3):
			var a: float = k * 2.1 + float(spec[0]) * 0.01
			kit.box(Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * (2.1 - k * 0.32)), Vector3(1.1, 0.22, 0.05), "tolep75_" + ["jaune", "bleu", "rouge"][k], 1.0)
		kit.col_box(Transform3D(Basis(), p + Vector3.UP * 1.2), Vector3(0.3, 2.4, 0.3))


# =================================================================== le réseau

## Les chemins : une suite de points (tous les ~11 m) reliés aux rues de la ville et aux lieux.
func _graph() -> void:
	var ends := {"sud": "ga_dehors", "usine": "us_dehors", "casse": "ca_entree", "plage": "pl_feu", "phare": "ph_pied"}
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		if pts.size() < 2:
			continue
		var prev: String = ""
		var acc: float = 0.0
		for i in range(pts.size()):
			if i > 0:
				acc += (pts[i] as Vector3).distance_to(pts[i - 1])
			if i == 0 or i == pts.size() - 1 or acc > 11.0:
				acc = 0.0
				var nm: String = city._pt("ch_%s_%d" % [str(k), i], (pts[i] as Vector3) + Vector3.UP * 0.05)
				if prev != "":
					city._link(prev, nm)
				else:
					city._link(city._nearest_point(pts[i] as Vector3, "ch_" + str(k)), nm)
				prev = nm
		if ends.has(k) and city.points.has(str(ends[k])):
			city._link(prev, str(ends[k]))
	# les lieux sans chemin : au point de chemin le plus proche
	for extra in ["sp_1", "sp_2", "ca_entree", "pl_feu", "ph_pied"]:
		if city.points.has(extra) and (not city.graph.has(extra) or (city.graph[extra] as Array).size() < 2):
			city._link(extra, city._nearest_point(city.points[extra], extra.substr(0, 3)))

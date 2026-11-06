extends Node3D
## V114 : LA FRONDE, le quartier libre des Strates, dans sa caverne à l'est (strates_roche_v114). Du
## punk à vapeur, sous terre : on y arrive par le tunnel et le PONT DES FRONDEURS (un pont de fer en
## treillis au-dessus du GOUFFRE, où gronde très loin une rivière qui luit) ; puis :
##  - l'entrée : une arche de ferraille soudée (« LA FRONDE »), les bannières au A cerclé en engrenage ;
##  - la PLACE LIBRE (au milieu) et les guirlandes qui traversent toute la caverne ;
##  - la SCÈNE DES SOUPAPES (à l'est) : la scène de palettes, l'orgue à vapeur fait de tuyaux recyclés,
##    les amplis, les projecteurs ; la fosse ;
##  - la CANTINE LIBRE (au nord-ouest), sous un parachute tendu ; l'ATELIER LIBRE (au nord), deux
##    conteneurs et la ferraille ; le TROC (au sud-ouest) ; l'ASSEMBLÉE (au sud) : un cercle de vieux
##    canapés autour d'un brasero ; le SKATEPARK (au sud-est) ; le MUR DES FRESQUES (au nord-est) ;
##  - les maisons : des conteneurs et de vieilles chaudières empilés contre les parois, des escaliers de
##    fer, des fenêtres allumées ;
##  - la voie du Pont (Rivet et Bielle la réparent le jour) et sa draisine.

const R = preload("res://scripts/strates_roche_v114.gd")
const FY: float = -98.0

var main: Node
var ville: Node3D                       # strates_ville_v114 (le kit, les lumières, les objets)
var hf: Node3D
var kit
var pc: bool = true
var objets: Dictionary = {}
var organ_steam: Array = []
var _rng := RandomNumberGenerator.new()


func P(lx: float, lz: float, y: float = FY) -> Vector3:
	return R.W(lx, lz, y)


func XL(p: Vector3, q: Vector3) -> Transform3D:
	var d := Vector3(q.x - p.x, 0, q.z - p.z)
	return Transform3D(Basis.looking_at(-d.normalized(), Vector3.UP), p)


func _pt(name: String, p: Vector3) -> String:
	return hf._pt(name, p)


func _link(a: String, b: String) -> void:
	hf._link(a, b)


func _near_pt(p: Vector3) -> String:
	return ville._near_pt(p, "fr_p_")


func _sp(name: String, pos: Vector3, face_to: Vector3, pose: String) -> void:
	var f := Vector3(face_to.x - pos.x, 0, face_to.z - pos.z)
	hf._spot(name, pos + Vector3.UP * 0.05, f.normalized() if f.length() > 0.01 else Vector3.FORWARD, pose, _near_pt(pos))


func _door(name: String, p: Vector3) -> void:
	var near: String = _near_pt(p)
	_pt(name, p + Vector3.UP * 0.05)
	if near != "":
		_link(name, near)
	ville.doors[name] = p


func build(main_node: Node, v: Node3D, hf_city: Node3D, high_quality: bool) -> void:
	main = main_node
	ville = v
	hf = hf_city
	kit = v.kit
	pc = high_quality
	_rng.seed = 11420
	_network()
	_pont()
	_entree()
	_scene()
	_cantine()
	_atelier()
	_troc()
	_assemblee()
	_skatepark()
	_fresques()
	_maisons()
	_guirlandes()
	_lustre()
	_bricoles()


# =================================================================== le réseau

const C := Vector2(150.0, 26.0)


func _network() -> void:
	# le pont et le tunnel (côté Strates : st_p_fr_1 ; côté Fronde : fr_p_0)
	_pt("fr_p_pont_o", P(89.5, 14.5, -96.8))
	_pt("fr_p_pont_e", P(103.5, 20.0, -97.6))
	_pt("fr_p_0", P(112.0, 23.0))
	_link("st_p_fr_1", "fr_p_pont_o")
	_link("fr_p_pont_o", "fr_p_pont_e")
	_link("fr_p_pont_e", "fr_p_0")
	# la Place Libre : un anneau de huit points
	for k in range(8):
		var a: float = TAU * k / 8.0
		_pt("fr_p_pl_%d" % k, P(C.x + cos(a) * 13.0, C.y + sin(a) * 11.0))
	for k in range(8):
		_link("fr_p_pl_%d" % k, "fr_p_pl_%d" % ((k + 1) % 8))
	_link("fr_p_0", "fr_p_pl_4")
	# les branches : vers chaque lieu
	var br := [["scene", 172.0, 26.0, 0], ["cantine", 128.0, 10.0, 5], ["atelier", 150.0, 2.0, 6], ["troc", 129.0, 38.0, 3],
		["assemblee", 150.0, 49.0, 2], ["skate", 174.0, 46.0, 1], ["fresques", 172.0, 6.0, 7]]
	for b in br:
		_link(_pt("fr_p_" + str(b[0]), P(float(b[1]), float(b[2]))), "fr_p_pl_%d" % int(b[3]))
	# le tour des maisons, le long des parois
	for k2 in range(12):
		var a2: float = TAU * k2 / 12.0
		_pt("fr_p_tour_%d" % k2, P(R.FR_C.x + cos(a2) * (R.FR_R.x - 9.0), R.FR_C.z + sin(a2) * (R.FR_R.z - 8.0)))
	for k2 in range(12):
		_link("fr_p_tour_%d" % k2, "fr_p_tour_%d" % ((k2 + 1) % 12))
	_link("fr_p_tour_6", "fr_p_0")
	_link("fr_p_tour_0", "fr_p_scene")
	_link("fr_p_tour_3", "fr_p_assemblee")
	_link("fr_p_tour_9", "fr_p_atelier")


# =================================================================== le Pont des Frondeurs

func _pont() -> void:
	var a: Vector3 = P(90.6, 14.9, -96.85)
	var b: Vector3 = P(102.2, 19.6, -97.5)
	kit.bridge114(a, b, 3.0)
	# la voie du Pont : elle traverse le tunnel et le pont jusqu'à la Fronde
	var p0: Vector3 = P(84.0, 11.6, R.floor_y(84.0, 11.6))
	var pts := [p0, a + Vector3.UP * 0.02, b + Vector3.UP * 0.02, P(110.0, 22.6, -98.0), P(118.0, 24.5, -98.0)]
	kit.track114(pts, false)
	# la draisine (la petite voiture à bras des cheminots), au bout de la voie
	var dx: Transform3D = XL(P(115.5, 24.0), P(118.0, 24.5))
	kit.box(dx * kit.T(0, 0.55, 0), Vector3(1.3, 0.12, 2.0), "traverse114", 1.0)
	kit.box(dx * kit.T(0, 1.0, 0), Vector3(0.12, 0.9, 0.12), "fer114", 1.0)
	kit.box(dx * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(0, 1.45, 0)), Vector3(1.2, 0.06, 0.06), "fer114", 1.0)
	for s in [-0.55, 0.55]:
		for z in [-0.7, 0.7]:
			kit.cyl(Transform3D(dx.basis * Basis(Vector3.BACK, PI * 0.5), dx * Vector3(s, 0.3, z)), 0.28, 0.28, 0.08, "fer114", 10)
	kit.col_box(dx * kit.T(0, 0.6, 0), Vector3(1.4, 1.2, 2.1))
	# des outils posés, une caisse
	kit.crate71(P(113.0, 26.0), 0.3, 0.7)
	hf._spot("fr_rail_1", P(86.0, 13.6, R.floor_y(86.0, 13.6)) + Vector3.UP * 0.05, Vector3(1, 0, 0.4).normalized(), "bricoler", "st_p_fr_1")
	_sp("fr_rail_2", P(114.5, 22.2), P(115.5, 24.0), "bricoler")
	_sp("fr_pont", (a + b) * 0.5 + Vector3(0.0, 0, 0.6), (a + b) * 0.5 + Vector3(0, -10, 8), "observer")
	# la rivière, tout au fond du Gouffre : une lueur bleue, une lumière
	var rv := MeshInstance3D.new()
	rv.name = "Riviere_gouffre"
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.0, 100.0)
	rv.mesh = pm
	rv.material_override = kit.mat("riviere114")
	add_child(rv)
	rv.global_position = P(96.2, 15.0, R.RIVIERE_Y)
	ville._light(P(96.2, 15.0, R.RIVIERE_Y + 6.0), Color(0.3, 0.7, 0.9), 1.6, 1.6, 40.0)
	objets["pont"] = (a + b) * 0.5
	objets["gouffre"] = P(96.2, 15.0, R.RIVIERE_Y)


# =================================================================== l'entrée

func _entree() -> void:
	var e: Vector3 = P(110.5, 22.5)
	var bs := Basis.looking_at(Vector3(-1, 0, -0.35).normalized(), Vector3.UP)
	# l'arche de ferraille : deux piles de bidons, une poutre, les lettres soudées
	for s in [-1.0, 1.0]:
		var pp: Vector3 = e + bs.x * s * 4.6
		for k in range(4):
			kit.cyl(Transform3D(Basis(Vector3.UP, k * 0.7), pp + Vector3.UP * (k * 1.0)), 0.42, 0.42, 0.95, "tole114_" + ["rouge", "jaune", "bleu", "vert"][k], 14)
		kit.col_cyl(pp, 0.5, 4.0)
	kit.box(Transform3D(bs, e + Vector3.UP * 4.3), Vector3(10.2, 0.5, 0.5), "fer114_rouille", 1.0)
	kit.sign114(Transform3D(bs, e + Vector3.UP * 5.3 + bs.z * 0.3), "fronde", 5.0, 1.3)
	for s2 in [-1.0, 1.0]:
		kit.banner70(Transform3D(bs, e + bs.x * s2 * 3.2 + Vector3.UP * 4.0 + bs.z * 0.3), 1.0, 2.6, "banniere114")
	objets["entree"] = e


# =================================================================== la Scène des Soupapes

func _scene() -> void:
	var xf: Transform3D = XL(P(184.0, 26.0), P(150.0, 26.0))
	var d: Dictionary = kit.scene75(xf, 12.0, 7.0, 1.1)
	_sp("fr_scene_chant", d["chant"], xf * Vector3(0, 0, 10), "chanter")
	_sp("fr_scene_guitare", d["guitare"], xf * Vector3(0, 0, 10), "guitare")
	_sp("fr_scene_basse", d["basse"], xf * Vector3(0, 0, 10), "basse")
	_sp("fr_scene_batterie", d["batterie"], xf * Vector3(0, 0, 10), "batterie")
	# l'orgue à vapeur : des tuyaux de cuivre et de laiton, de toutes les hauteurs, derrière la scène
	for k in range(13):
		var x: float = -5.4 + k * 0.9
		var h: float = 3.0 + 4.0 * sin(PI * float(k) / 12.0) + (0.6 if k % 2 == 0 else 0.0)
		var base: Vector3 = xf * Vector3(x, 1.1, -7.6)
		kit.cyl(Transform3D(Basis(), base), 0.22, 0.22, h, "cuivre112" if k % 3 != 0 else "laiton112", 12, false)
		kit.cyl(Transform3D(Basis(), base + Vector3.UP * h), 0.3, 0.22, 0.25, "laiton112", 12)
		if k % 3 == 1:
			organ_steam.append(base + Vector3.UP * (h + 0.3))
	kit.box(xf * kit.T(0, 1.6, -7.8), Vector3(12.0, 1.0, 1.0), "tole114_noir", 1.0)
	kit.chaudiere114(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-7.6, 0, -6.0)), 1.1, 3.6, "noir", false)
	kit.banner70(xf * kit.T(-5.0, 6.0, -7.9), 1.2, 3.0, "banniere114")
	kit.banner70(xf * kit.T(5.0, 6.0, -7.9), 1.2, 3.0, "banniere114")
	kit.sign114(xf * kit.T(0, 7.1, -0.5), "soupapes", 4.6, 1.2)
	# les projecteurs (de couleur) sur le portique
	var cols := [Color(1.0, 0.3, 0.3), Color(0.3, 0.5, 1.0), Color(1.0, 0.75, 0.3)]
	for k2 in range(3):
		var at: Vector3 = xf * Vector3(-4.0 + k2 * 4.0, 6.2, -0.4)
		kit.projecteur75(at, xf * Vector3(-2.0 + k2 * 2.0, 1.2, -2.5), cols[k2], 2.2, k2 != 1 or pc)
	# la fosse
	for k3 in range(8):
		var fx: float = -4.5 + (k3 % 4) * 3.0 + _rng.randf_range(-0.6, 0.6)
		var fz: float = 4.0 + (k3 / 4) * 2.6 + _rng.randf_range(-0.5, 0.5)
		_sp("fr_fosse_%d" % (k3 + 1), xf * Vector3(fx, 0, fz), xf * Vector3(0, 1.5, -2), "pogo")
	ville._light(xf * Vector3(0, 4.0, 3.0), Color(1.0, 0.55, 0.45), 1.2, 1.8, 18.0)
	objets["scene"] = xf * Vector3(0, 0, 5.0)


# =================================================================== la Cantine Libre

func _cantine() -> void:
	var c: Vector3 = P(130.0, 9.0)
	# le parachute tendu (une grande toile bombée sur quatre mâts)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var mp: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 7.0
		kit.cyl(Transform3D(Basis(), mp), 0.08, 0.08, 4.2, "fer114_rouille", 6, false)
		kit.col_cyl(mp, 0.12, 4.2)
	# (un vieux parachute : une toile en cône, des fuseaux de couleur)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 3.9), 7.8, 0.3, 2.2, "toile114_parachute", 16, false, 1.0)
	for k2 in range(8):
		var a3: float = TAU * k2 / 8.0
		kit.beam(c + Vector3.UP * 6.1, c + Vector3(cos(a3), 0, sin(a3)) * 7.8 + Vector3.UP * 3.9, 0.06, "toile114_" + ["rouge", "jaune", "bleu", "vert"][k2 % 4])
	kit.cyl(Transform3D(Basis(), c), 0.1, 0.1, 6.2, "fer114_rouille", 6, false)
	# les tables (longues, en planches sur tréteaux), les bancs
	for i in range(4):
		var tx: Transform3D = XL(c + Vector3(-3.5 + (i % 2) * 7.0, 0, -2.4 + (i / 2) * 4.8), c + Vector3(0, 0, 10))
		var seats: Array = kit.tavern_table71(tx, 2.6)
		var sp: Vector3 = (seats[0] as Vector3) if seats.size() > 0 else tx * Vector3(0, 0, 0.8)
		_sp("fr_cantine_table_%d" % (i + 1), sp, tx.origin, "assis")
	# la cuisine : une chaudière devenue fourneau, le comptoir de palettes, la grande louche
	var kx: Transform3D = XL(c + Vector3(-1.0, 0, -6.8), c)
	kit.chaudiere114(kx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-2.8, 0, -1.4)), 0.9, 2.6, "orange", true)
	kit.box(kx * kit.T(1.4, 0.55, 0), Vector3(3.2, 1.1, 0.8), "palette75", 1.0)
	kit.box(kx * kit.T(1.4, 1.12, 0), Vector3(3.3, 0.06, 0.9), "bois112", 1.0)
	kit.col_box(kx * kit.T(1.4, 0.55, 0), Vector3(3.2, 1.1, 0.8))
	_sp("fr_cantine_comptoir", kx * Vector3(1.4, 0, -0.9), kx * Vector3(1.4, 0, 3.0), "comptoir")
	_sp("fr_cantine_cuisine", kx * Vector3(-1.4, 0, 0.6), kx * Vector3(-2.8, 1, -1.4), "cuisiner")
	kit.sign114(kx * kit.T(1.4, 2.6, -0.3), "cantine", 2.8, 0.9)
	ville._light(c + Vector3.UP * 3.2, Color(1.0, 0.74, 0.45), 1.3, 1.9, 13.0)
	objets["cantine"] = kx * Vector3(1.4, 0, 1.8)


# =================================================================== l'Atelier Libre

func _atelier() -> void:
	var c: Vector3 = P(150.0, -1.0)
	var x1: Transform3D = XL(c + Vector3(-3.0, 0, -4.0), c + Vector3(-3.0, 0, 6.0))
	kit.conteneur75(x1, "bleu", {"len": 6.1, "home": false})
	var x2: Transform3D = XL(c + Vector3(4.5, 0, -2.0), c + Vector3(-5.0, 0, 0.0))
	kit.conteneur75(x2 * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO), "jaune", {"len": 6.1, "home": false})
	kit.sign114(x1 * kit.T(0, 3.2, 1.3), "atelier", 2.8, 0.9)
	# l'établi, l'étau, la ferraille, les vélos à moitié faits
	var ex: Transform3D = XL(c + Vector3(-2.0, 0, 0.5), c + Vector3(-2.0, 0, 6.0))
	kit.box(ex * kit.T(0, 0.9, 0), Vector3(3.0, 0.1, 1.0), "bois112", 1.0)
	for s in [-1.4, 1.4]:
		kit.box(ex * kit.T(s, 0.45, 0), Vector3(0.1, 0.9, 0.9), "fer114", 1.0)
	kit.col_box(ex * kit.T(0, 0.5, 0), Vector3(3.0, 1.0, 1.0))
	for k in range(4):
		kit.gear112(ex * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-1.0 + k * 0.6, 0.97, 0.1)), 0.18 + k * 0.03, 8, 0.04, "laiton112_vieux")
	_sp("fr_atelier_etabli", ex * Vector3(0, 0, 0.9), ex * Vector3(0, 1, 0), "bricoler")
	var e2: Transform3D = XL(c + Vector3(3.5, 0, 2.5), c + Vector3(-3.0, 0, 2.5))
	kit.box(e2 * kit.T(0, 0.8, 0), Vector3(2.0, 0.1, 0.9), "tole114_noir", 1.0)
	kit.box(e2 * kit.T(0, 0.4, 0), Vector3(1.8, 0.8, 0.8), "fer114_rouille", 1.0)
	kit.col_box(e2 * kit.T(0, 0.45, 0), Vector3(2.0, 0.9, 0.9))
	_sp("fr_atelier_2", e2 * Vector3(0, 0, 0.9), e2 * Vector3(0, 0.9, 0), "bricoler")
	for k2 in range(5):
		kit.baril75(c + Vector3(6.5 + (k2 % 2) * 0.8, 0, -4.0 + k2 * 0.9), ["rouge", "bleu", "jaune", "", "vert"][k2])
	kit.pneus75(c + Vector3(-7.0, 0, 1.5), 4)
	steam.append(c + Vector3(-1.0, 3.0, -4.0))
	ville._light(c + Vector3(0, 3.0, 2.0), Color(0.85, 0.9, 1.0), 1.0, 1.5, 11.0)
	objets["atelier"] = ex * Vector3(0, 0, 2.0)


var steam: Array = []


# =================================================================== le Troc

func _troc() -> void:
	var c: Vector3 = P(124.5, 44.0)
	var x1: Transform3D = XL(c + Vector3(0, 0, 2.0), c + Vector3(6.0, 0, -4.0))
	kit.conteneur75(x1, "rouge", {"len": 6.1, "home": false})
	kit.sign114(x1 * kit.T(0, 3.2, 1.3), "troc", 2.6, 0.9)
	kit.awning71(x1 * kit.T(0, 2.4, 1.25), 5.8, 2.0, 0.6, "jaune")
	var cx: Transform3D = x1 * kit.T(-1.0, 0, 2.6)
	kit.counter71(cx, 2.6, "planches71")
	_sp("fr_troc_comptoir", cx * Vector3(0, 0, -0.9), cx * Vector3(0, 0, 3.0), "comptoir")
	# les étagères de récup (des caisses empilées), l'établi des bijoux
	for k in range(4):
		kit.crate71(x1 * Vector3(2.0, 0.0 + (k % 2) * 0.7, 2.2 + (k / 2) * 0.6), 0.2 * k, 0.65)
	var ex: Transform3D = x1 * kit.T(2.4, 0, 3.6)
	kit.box(ex * kit.T(0, 0.85, 0), Vector3(1.6, 0.08, 0.8), "bois112", 1.0)
	kit.box(ex * kit.T(0, 0.42, 0), Vector3(1.4, 0.84, 0.7), "palette75", 1.0)
	for k2 in range(5):
		kit.ball(ex * Transform3D(Basis(), Vector3(-0.6 + k2 * 0.3, 0.93, 0.0)), 0.04, "cristal114" if k2 % 2 == 0 else "laiton112", 6, 3)
	kit.col_box(ex * kit.T(0, 0.45, 0), Vector3(1.6, 0.9, 0.8))
	_sp("fr_troc_etabli", ex * Vector3(0, 0, -0.8), ex * Vector3(0, 0.9, 0), "bricoler")
	ville._light(x1 * Vector3(0, 2.6, 3.2), Color(1.0, 0.8, 0.5), 0.9, 1.4, 10.0)
	objets["troc"] = cx * Vector3(0, 0, 1.8)


# =================================================================== l'Assemblée

func _assemblee() -> void:
	var c: Vector3 = P(150.0, 50.0)
	# le brasero (un bidon percé), sa braise, sa lueur
	kit.cyl(Transform3D(Basis(), c), 0.45, 0.45, 0.95, "fer114_rouille", 14, false)
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.8), 0.42, "braise114", 12)
	kit.col_cyl(c, 0.5, 1.0)
	ville._light(c + Vector3.UP * 1.6, Color(1.0, 0.5, 0.2), 1.6, 2.4, 10.0)
	objets["brasero"] = c
	# six vieux canapés en cercle
	var cols := ["rouge", "vert", "bleu", "jaune", "rouge", "violet"]
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.3
		var sp: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 4.6
		var seat: Vector3 = kit.canape75(XL(sp, c), cols[k])
		_sp("fr_assemblee_%d" % (k + 1), seat - Vector3.UP * 0.45, c, "assis")
	kit.sign114(XL(c + Vector3(0, 0, 7.5), c) * kit.T(0, 2.2, 0), "assemblee", 2.8, 0.9)
	objets["assemblee"] = c + Vector3(0, 0, -6.0)


# =================================================================== le Skatepark

func _skatepark() -> void:
	var c: Vector3 = P(176.0, 47.0)
	kit.funbox75(XL(c, c + Vector3(-10, 0, 0)), 5.0, 3.0, 0.7)
	kit.quarter75(XL(c + Vector3(7.5, 0, 0), c), 6.0, 2.2)
	kit.quarter75(XL(c + Vector3(-8.0, 0, 3.0), c + Vector3(8, 0, 0)), 4.0, 1.6)
	_sp("fr_skate_1", c + Vector3(-3.5, 0, -3.0), c + Vector3(3, 0, -3), "skate")
	_sp("fr_skate_2", c + Vector3(3.0, 0, 3.6), c + Vector3(-3, 0, 3.6), "skate")
	objets["skate"] = c + Vector3(0, 0, -5.0)


# =================================================================== le Mur des Fresques

func _fresques() -> void:
	var specs := [["1", P(166.0, -2.5), 8.0, 4.0], ["2", P(176.0, 1.0), 8.0, 4.0], ["3", P(184.5, 8.0), 6.0, 3.0]]
	for s in specs:
		var p: Vector3 = s[0 + 1]
		var xf: Transform3D = XL(p, P(160.0, 20.0))
		kit.fresque114(xf, str(s[0]), float(s[2]), float(s[3]))
	_sp("fr_fresque_1", P(166.0, 1.0), P(166.0, -2.5), "peindre")
	_sp("fr_fresque_2", P(175.0, 4.6), P(176.0, 1.0), "peindre")
	# des pots de peinture, une échelle
	for k in range(4):
		kit.cyl(Transform3D(Basis(), P(169.0 + k * 0.4, 0.5)), 0.12, 0.12, 0.25, "tole114_" + ["rouge", "jaune", "bleu", "vert"][k], 8)
	ville._light(P(172.0, 8.0, FY + 3.5), Color(1.0, 0.85, 0.65), 0.9, 1.3, 14.0)
	objets["fresques"] = P(171.0, 6.0)


# =================================================================== les maisons

const DOORS := ["porte_rivet", "porte_bielle", "porte_echo", "porte_gamelle", "porte_fusain", "porte_bricole", "porte_lumi", "porte_ressort", "porte_brasero"]


func _maisons() -> void:
	# des conteneurs (et quelques chaudières) le long des parois, l'entrée tournée vers le milieu ; un
	# second rang posé dessus (des fenêtres allumées, des escaliers de fer)
	var cols := ["rouge", "bleu", "vert", "jaune", "orange", "violet", "turquoise", "creme"]
	var left: Array = DOORS.duplicate()
	var angs := [-150.0, -128.0, -108.0, -88.0, -66.0, -40.0, 62.0, 84.0, 104.0, 124.0, 146.0, 166.0]
	for i in range(angs.size()):
		var a: float = deg_to_rad(float(angs[i]))
		var p: Vector3 = P(R.FR_C.x + cos(a) * (R.FR_R.x - 4.5), R.FR_C.z + sin(a) * (R.FR_R.z - 4.0))
		var xf: Transform3D = XL(p, P(C.x, C.y))
		var door: Vector3
		if i % 4 == 3:
			door = kit.chaudiere114(xf, 1.4, 5.0, cols[i % cols.size()], true)
		else:
			# la façade longue tournée vers le milieu : le conteneur est couché de travers
			var cx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 0, -1.3))
			kit.conteneur75(cx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO), cols[i % cols.size()], {"len": 6.1, "home": true, "lit": true, "door_color": cols[(i + 3) % cols.size()]})
			door = xf * Vector3(6.1 * 0.38, 0, 1.0)
			# le second rang : un conteneur posé dessus, décalé ; un escalier de fer
			if i % 2 == 0:
				var top: Transform3D = xf * kit.T(1.0, 2.62, -1.4)
				kit.conteneur75(top, cols[(i + 2) % cols.size()], {"len": 6.1, "home": true, "lit": true, "solid": true})
				kit.stair(xf * Vector3(-4.2, 0, 0.6), xf * Vector3(-2.0, 2.62, 0.6), 0.9, "fer114_rouille")
		if not left.is_empty():
			_door(str(left.pop_front()), door)
	for nm in left:
		_door(str(nm), P(C.x + _rng.randf_range(-8, 8), C.y + _rng.randf_range(-6, 6)))
	# les bannières sur les piles de conteneurs, les places
	var spots := [[136.0, 18.0], [160.0, 30.0], [146.0, 36.0], [162.0, 18.0]]
	for i2 in range(spots.size()):
		_sp("fr_place_%d" % (i2 + 1), P(float(spots[i2][0]), float(spots[i2][1])), P(C.x, C.y), ["debout", "bras_croises", "observer", "debout"][i2])
	# des places pour les passants (des Frondeurs de passage)
	var cs := [[140.0, 26.0], [158.0, 24.0], [150.0, 15.0], [150.0, 37.0], [168.0, 38.0], [134.0, 34.0]]
	for i3 in range(cs.size()):
		var cp: Vector3 = P(float(cs[i3][0]), float(cs[i3][1]))
		_sp("fr_crowd_%d" % (i3 + 1), cp, P(C.x, C.y) if i3 != 4 else P(176.0, 47.0), ["debout", "bras_croises", "observer"][i3 % 3])
		ville.crowd_spots.append("fr_crowd_%d" % (i3 + 1))


# =================================================================== les guirlandes

func _guirlandes() -> void:
	var ends := [[P(112.0, 18.0, -92.0), P(150.0, 8.0, -86.0)], [P(150.0, 8.0, -86.0), P(184.0, 20.0, -90.0)], [P(112.0, 30.0, -92.0), P(150.0, 44.0, -86.0)],
		[P(150.0, 44.0, -86.0), P(184.0, 34.0, -90.0)], [P(130.0, 26.0, -88.0), P(170.0, 26.0, -86.0)], [P(150.0, 8.0, -86.0), P(150.0, 44.0, -86.0)],
		[P(124.0, 6.0, -91.0), P(176.0, 46.0, -90.0)], [P(124.0, 46.0, -91.0), P(176.0, 6.0, -90.0)]]
	var cols := ["rouge", "jaune", "bleu", "vert", "violet"]
	for i in range(ends.size()):
		var a: Vector3 = ends[i][0]
		var b: Vector3 = ends[i][1]
		var n: int = int(a.distance_to(b) / 1.1)
		var prev: Vector3 = a
		for k in range(1, n + 1):
			var t: float = float(k) / n
			var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * 2.2 * 4.0 * t * (1.0 - t)
			kit.beam(prev, p, 0.012, "fer114")
			if k < n:
				kit.ball(Transform3D(Basis(), p + Vector3.DOWN * 0.1), 0.08, "guirlande114_" + cols[(k + i) % cols.size()], 6, 3)
			prev = p
	# quelques vraies lumières colorées sous les guirlandes
	var lc := [Color(1.0, 0.45, 0.4), Color(0.45, 0.6, 1.0), Color(1.0, 0.8, 0.4), Color(0.6, 1.0, 0.55)]
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + 0.4
		ville._light(P(C.x + cos(a2) * 16.0, C.y + sin(a2) * 13.0, -91.0), lc[k2], 1.1, 1.5, 18.0)


# =================================================================== le Lustre de Ferraille

## Au milieu de la voûte de la Fronde, le LUSTRE DE FERRAILLE : une grande roue de vélo de fer et des
## dizaines d'ampoules, de lanternes, de bocaux allumés, pendus à des chaînes ; il éclaire tout le
## quartier (la Fronde n'a pas de Soleil de Laiton : « on a mieux, on a le nôtre »).
func _lustre() -> void:
	var c: Vector3 = P(C.x, C.y, -74.0)
	var top: Vector3 = P(C.x, C.y, -68.5)
	kit.beam(top, c, 0.08, "fer114")
	kit.ring(Transform3D(Basis(), c), 5.6, 6.0, 0.2, "fer114_rouille", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.DOWN * 1.2), 3.2, 3.5, 0.15, "laiton112_vieux", 24)
	for k in range(12):
		var a: float = TAU * k / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.beam(c, c + d * 5.8, 0.04, "fer114")
		var hang: float = 1.0 + float(k % 3) * 0.7
		var lp: Vector3 = c + d * 5.8 + Vector3.DOWN * hang
		kit.beam(c + d * 5.8, lp, 0.01, "fer114")
		kit.ball(Transform3D(Basis(), lp), 0.28, ["guirlande114_jaune", "guirlande114_rouge", "lampe114", "guirlande114_bleu"][k % 4], 8, 5)
		var lp2: Vector3 = c + d * 3.35 + Vector3.DOWN * (1.9 + float(k % 2) * 0.5)
		kit.beam(c + d * 3.35 + Vector3.DOWN * 1.2, lp2, 0.01, "fer114")
		kit.ball(Transform3D(Basis(), lp2), 0.2, "lampe114", 6, 4)
	var big: OmniLight3D = ville._light(c + Vector3.DOWN * 2.0, Color(1.0, 0.8, 0.64), 5.0, 6.0, 80.0)
	big.omni_attenuation = 0.7
	ville._light(P(C.x - 22.0, C.y, -88.0), Color(1.0, 0.7, 0.55), 1.2, 1.6, 30.0)
	ville._light(P(C.x + 22.0, C.y, -88.0), Color(0.8, 0.7, 1.0), 1.2, 1.6, 30.0)
	objets["lustre"] = c


## Ce qui traîne dans la Fronde (et qui sert à tout) : des palettes, des bidons, des pneus, une vieille
## voiture devenue jardinière, des tapis, des lanternes.
func _bricoles() -> void:
	for spec in [[132.0, 30.0, 3], [166.0, 14.0, 2], [140.0, 44.0, 4], [170.0, 40.0, 2]]:
		kit.pile_palettes75(P(float(spec[0]), float(spec[1])), int(spec[2]), _rng.randf() * TAU)
	for k in range(6):
		kit.baril75(P(120.0 + k * 1.1, 14.0 + (k % 2) * 0.9), ["rouge", "bleu", "jaune", "vert", "", "orange"][k])
	kit.pneus75(P(162.0, 44.0), 3)
	kit.voiture75(XL(P(138.0, 18.0), P(150.0, 26.0)), "turquoise", true)
	# la Place Libre : un grand rond peint à même le sol (des cercles de couleur)
	for k2 in range(4):
		kit.ring(Transform3D(Basis(), P(C.x, C.y, FY + 0.012 + k2 * 0.002)), 9.0 - k2 * 2.0, 9.6 - k2 * 2.0, 0.01, "tole114_" + ["rouge", "jaune", "turquoise", "violet"][k2], 48)
	kit.box(Transform3D(Basis(), P(C.x, C.y, FY + 0.011)), Vector3(1.4, 0.01, 1.4), "tole114_creme", 1.0, 4)
	# des lanternes sur poteaux (des bocaux allumés) le long des chemins
	for q in [[124.0, 20.0], [136.0, 24.0], [162.0, 26.0], [146.0, 12.0], [146.0, 40.0], [160.0, 42.0], [158.0, 10.0]]:
		var lp: Vector3 = P(float(q[0]), float(q[1]))
		kit.cyl(Transform3D(Basis(), lp), 0.06, 0.06, 2.6, "fer114_rouille", 6, false)
		kit.cyl(Transform3D(Basis(), lp + Vector3.UP * 2.6), 0.16, 0.16, 0.3, "vitre114", 8)
		kit.ball(Transform3D(Basis(), lp + Vector3.UP * 2.75), 0.12, ["guirlande114_jaune", "guirlande114_violet", "guirlande114_vert"][int(q[0]) % 3], 6, 4)
		kit.col_cyl(lp, 0.1, 2.6)


# =================================================================== les zones

func zone_at(p: Vector3) -> String:
	var l: Vector3 = R.L(p)
	if l.x < 104.0:
		return ""
	var best: String = "fr_place"
	var bd: float = INF
	for k in [["scene", "fr_scene", 14.0], ["cantine", "fr_cantine", 10.0], ["atelier", "fr_atelier", 9.0], ["troc", "fr_troc", 8.0],
		["assemblee", "fr_assemblee", 9.0], ["skate", "fr_skate", 10.0], ["fresques", "fr_fresques", 10.0], ["entree", "fr_entree", 6.0]]:
		var o: Vector3 = objets.get(str(k[0]), Vector3.INF)
		if o == Vector3.INF:
			continue
		var d: float = Vector2(p.x - o.x, p.z - o.z).length()
		if d < float(k[2]) and d < bd:
			bd = d
			best = str(k[1])
	return best

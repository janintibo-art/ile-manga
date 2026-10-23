extends Node3D
## V56 : la ville de Port-Azur — le quai et ses bittes d'amarrage, la gare maritime et
## son môle, les façades colorées du front de mer, la place de la Mairie (fontaine,
## platanes, horloge, terrasses de café), le Grand Hôtel des Embruns face à la plage,
## la promenade et ses palmiers, la plage (paillote, parasols, poste de secours), la
## pointe du phare et la jetée, les maisons des collines.
## Fournit aussi aux habitants (azur_v56.gd) : le réseau des rues (points + graphe), les
## lieux d'activité (comptoirs, chaises, serviettes de plage…) et les portes des maisons.
## Repère « ville » : voir ile_azur_v56.gd (origine au milieu du quai, -Z vers la mer).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")

var main: Node
var ile: Node3D
var kit
var Y: float = 1.2
var points: Dictionary = {}          # nom -> Vector3 monde (nœuds du graphe des rues et des lieux)
var graph: Dictionary = {}           # nom -> [voisins]
var spots: Dictionary = {}           # nom -> {pos, face, pose, node}
var doors: Dictionary = {}           # bâtiment -> Vector3 monde devant la porte
var interiors: Array = []            # [nom, centre monde, demi-taille (x, z) dans le repère ville, rot]
var flora_spots: Dictionary = {"platane": [], "palmier": [], "laurier": [], "bougainvillier": [], "cypres": [], "olivier": []}
var objets: Dictionary = {}          # objets de quête : nom -> Vector3 monde
var clock_hands: Array = []          # [[Node3D aiguille des heures, Node3D minutes], ...]
var lighthouse_head: Node3D          # le feu tournant du phare
var lighthouse_light: OmniLight3D
var fountain: Vector3
var bell_pos: Vector3
var ferry_berth: Transform3D         # où s'amarre L'Hirondelle (avant vers la mer)
var ferry_gangway: Vector3           # où l'on monte à bord
var boat_dock: Array = []            # [début, fin] du ponton de la barque du joueur
var boats: Array = []                # [Node3D, phase] petits bateaux qui se balancent
var _clock: float = 0.0


# =================================================================== repère

func T(x: float, z: float, y: float = 0.0) -> Vector3:
	return ile.to_world(x, z, Y + y)


func TG(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = ile.to_world(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


## Repère local d'un objet dans la ville : rot en degrés (0 : regarde la mer, 90 : la plage
## (-X ville), -90 : le phare (+X ville), 180 : les collines).
func TF(x: float, z: float, rot: float = 0.0, y: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, ile.TOWN_YAW + deg_to_rad(rot)), T(x, z, y))


func TFW(w: Vector3, rot: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, ile.TOWN_YAW + deg_to_rad(rot)), w)


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	Y = ile.TOWN_Y
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56"))
	_ground()
	_quay()
	_waterfront()
	_square()
	_hotel()
	_blocks()
	_back_row()
	_hills()
	_beach()
	_headland()
	_breakwater()
	_piers()
	_props()
	_graph()
	kit.commit()
	_boats()
	print("ILE_MANGA_V56: Port-Azur construit en ", Time.get_ticks_msec() - t0, " ms (", kit.lamp_count, " lampes, ", points.size(), " points, ", spots.size(), " lieux)")


# =================================================================== sols

func _flat(x0: float, x1: float, z0: float, z1: float, y: float, key: String, tile: float, faces: int = 4) -> void:
	kit.box(TF((x0 + x1) * 0.5, (z0 + z1) * 0.5, 0.0, y - 0.05), Vector3(x1 - x0, 0.1, z1 - z0), key, tile, faces)


func _ground() -> void:
	# toute la ville basse en calade, puis les dalles du quai et de la place par-dessus
	_flat(-80.0, 66.0, 9.5, 86.0, 0.03, "paves", 2.6)
	_flat(-80.0, 66.0, 0.4, 10.0, 0.05, "dalles", 4.0)
	_flat(-20.0, 20.0, 28.0, 60.0, 0.06, "dalles", 4.0)
	# terre battue du jeu de boules
	_flat(-19.0, -7.0, 47.0, 58.5, 0.075, "sable", 3.0)
	for p in [[-19.0, -7.0, 47.0, 47.15], [-19.0, -7.0, 58.35, 58.5], [-19.15, -19.0, 47.0, 58.5], [-7.0, -6.85, 47.0, 58.5]]:
		kit.box(TF((p[0] + p[1]) * 0.5, (p[2] + p[3]) * 0.5, 0.0, 0.1), Vector3(p[1] - p[0], 0.08, p[3] - p[2]), "bois_sombre", 1.0)


# =================================================================== le quai

func _quay() -> void:
	# mur de quai en moellons, couronnement de pierre, échelles de fer
	kit.box(TF(-7.0, -0.4, 0.0, -2.9), Vector3(146.0, 8.4, 0.8), "moellons", 3.0, 32 | 4)
	kit.box(TF(-7.0, 0.25, 0.0, 0.08), Vector3(146.0, 0.18, 0.7), "pierre", 1.6)
	for x in [-58.0, -30.0, 2.0, 32.0, 56.0]:
		for k in range(6):
			kit.box(TF(x, -0.86, 0.0, -0.3 - k * 0.42), Vector3(0.5, 0.05, 0.05), "fer", 1.0)
		for s in [-0.25, 0.25]:
			kit.box(TF(x + s, -0.86, 0.0, -1.1), Vector3(0.05, 2.6, 0.05), "fer", 1.0)
	# bittes d'amarrage
	var x2: float = -76.0
	while x2 < 63.0:
		if absf(x2 + 70.0) > 4.5 and absf(x2 - 22.0) > 2.5 and absf(x2 + 25.0) > 2.5 and absf(x2 - 45.0) > 2.5:
			kit.bollard(T(x2, 0.75))
		x2 += 8.0
	# lampadaires et bancs du quai
	for x3 in [-72.0, -56.0, -40.0, -24.0, -8.0, 8.0, 24.0, 40.0, 56.0]:
		kit.lamppost(T(x3, 8.6), ile.TOWN_YAW)
	for x4 in [-48.0, -32.0, 32.0, 48.0]:
		kit.bench(TF(x4, 7.6, 180.0))
	flora_spots["palmier"].append(Transform3D(Basis(Vector3.UP, 1.3), T(-60.5, 8.0)))
	flora_spots["palmier"].append(Transform3D(Basis(Vector3.UP, 2.4), T(61.0, 8.0)))


# =================================================================== le front de mer

const WATERFRONT := [
	{"id": "gare", "x": -70.0, "w": 16.0, "floors": [6.4], "color": "creme", "volets": "blanc", "roof": "hip", "rdc": "bar", "enseigne": "gare"},
	{"id": "capitainerie", "x": -55.0, "w": 9.0, "floors": [3.6, 3.0, 3.0], "color": "bleu", "volets": "blanc", "rdc": "boutique", "enseigne": "capitainerie", "balcons": [1], "porte": "bleu"},
	{"id": "location", "x": -27.0, "w": 10.0, "floors": [3.6, 3.0, 3.0], "color": "jaune", "volets": "vert", "rdc": "boutique", "enseigne": "location", "auvent": "turquoise"},
	{"id": "taverne", "x": -13.0, "w": 18.0, "floors": [3.8, 3.0], "color": "ocre", "volets": "bleu", "rdc": "aveugle", "enseigne": "taverne", "auvent": "bleu",
		"interieur": {"door_x": 0.0, "door_w": 1.8, "lumieres": 3, "sol": "planches", "couleur": "creme"}, "balcons": [1], "balcon_long": true},
	{"id": "paulo", "x": 10.0, "w": 12.0, "floors": [3.6, 3.0, 3.0], "color": "rose", "volets": "bordeaux", "rdc": "bar", "enseigne": "paulo", "auvent": "rouge", "balcons": [1]},
	{"id": "bijouterie", "x": 20.0, "w": 8.0, "floors": [3.6, 3.0, 3.0], "color": "creme", "volets": "lavande", "rdc": "boutique", "enseigne": "bijouterie", "auvent": "bordeaux"},
	{"id": "souvenirs", "x": 29.0, "w": 10.0, "floors": [3.6, 3.0], "color": "corail", "volets": "turquoise", "rdc": "boutique", "enseigne": "souvenirs", "auvent": "turquoise"},
	{"id": "maison_quai_1", "x": 45.0, "w": 10.0, "floors": [3.4, 3.0, 3.0], "color": "ocre", "volets": "vert", "rdc": "porte", "door_x": -1.5},
	{"id": "maison_quai_2", "x": 57.0, "w": 14.0, "floors": [3.4, 3.0], "color": "blanc", "volets": "bleu", "rdc": "porte", "balcons": [1], "balcon_long": true, "door_x": 2.0},
]


func _waterfront() -> void:
	for b in WATERFRONT:
		var spec: Dictionary = b.duplicate()
		spec["d"] = 12.0
		var r: Dictionary = kit.building(TF(float(b["x"]), 10.0, 0.0), spec)
		doors[str(b["id"])] = r.get("door", T(float(b["x"]), 9.0))
		if b.has("interieur"):
			interiors.append([str(b["id"]), T(float(b["x"]), 16.0), Vector2(float(b["w"]) * 0.5 - 0.3, 5.7), 0.0])
	# bougainvilliers sur quelques façades
	for p in [[-27.0, 10.0], [45.0, 10.0], [57.0, 10.0]]:
		flora_spots["bougainvillier"].append(TF(p[0] + 3.2, p[1] - 0.05, 180.0))
	_fish_market(-43.0)
	_tavern_inside()


## Le marché aux poissons : une halle ouverte (piliers, toit de tuiles), trois étals.
func _fish_market(x: float) -> void:
	var xf: Transform3D = TF(x, 10.0)
	for px in [-4.4, 0.0, 4.4]:
		for pz in [0.4, 11.6]:
			kit.box(xf * Transform3D(Basis(), Vector3(px, 2.2, pz)), Vector3(0.5, 4.4, 0.5), "pierre", 1.2)
			kit.col_box(xf * Transform3D(Basis(), Vector3(px, 2.2, pz)), Vector3(0.5, 4.4, 0.5))
	kit.box(xf * Transform3D(Basis(), Vector3(0, 4.55, 0.4)), Vector3(9.6, 0.3, 0.5), "bois_sombre", 1.5)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 4.55, 11.6)), Vector3(9.6, 0.3, 0.5), "bois_sombre", 1.5)
	kit.roof_gable(xf * Transform3D(Basis(), Vector3(0, 4.7, 6.0)), 9.8, 11.6, 20.0, 0.6, "tuiles", "enduit_creme")
	kit.sign_board(xf * Transform3D(Basis(), Vector3(0, 4.05, 0.12)), 4.2, 0.85, "poissonnerie", true)
	for k in range(3):
		var sx: float = -3.0 + k * 3.0
		var sxf: Transform3D = xf * Transform3D(Basis(), Vector3(sx, 0, 3.0))
		kit.box(sxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.2, 0.9, 1.0), "bois", 1.0)
		kit.box(sxf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 0.98, 0)), Vector3(2.1, 0.06, 0.95), "peinture_blanc", 1.0)
		for f in range(7):
			var fx: float = -0.85 + f * 0.28
			var fc: String = ["peinture_gris", "peinture_creme", "peinture_orange"][f % 3]
			kit.box(sxf * Transform3D(Basis(Vector3.UP, 0.3 * (f % 2)).rotated(Vector3.RIGHT, -0.25), Vector3(fx, 1.05, -0.05 + (f % 2) * 0.2)), Vector3(0.1, 0.05, 0.38), fc, 1.0)
		kit.col_box(sxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(2.2, 1.0, 1.0))
	_spot("poissonnerie", -43.0, 14.2, -43.0, 6.0, "comptoir")


## L'intérieur de la taverne du Perroquet Bleu : comptoir, étagères de bouteilles,
## tonneaux, tables, petite estrade du guitariste.
func _tavern_inside() -> void:
	var xf: Transform3D = TF(-13.0, 10.0)
	# comptoir le long du mur du fond
	kit.box(xf * Transform3D(Basis(), Vector3(-1.5, 0.55, 9.2)), Vector3(10.0, 1.1, 0.7), "bois_sombre", 1.2)
	kit.box(xf * Transform3D(Basis(), Vector3(-1.5, 1.13, 9.15)), Vector3(10.3, 0.06, 0.85), "bois", 1.2)
	kit.col_box(xf * Transform3D(Basis(), Vector3(-1.5, 0.55, 9.2)), Vector3(10.0, 1.1, 0.7))
	# étagères et bouteilles
	for row in range(3):
		kit.box(xf * Transform3D(Basis(), Vector3(-1.5, 1.5 + row * 0.5, 11.45)), Vector3(9.0, 0.05, 0.35), "bois_sombre", 1.0)
		for k in range(22):
			var bx: float = -5.6 + k * 0.38 + kit.rng.randf_range(-0.05, 0.05)
			var bc: String = ["peinture_vert", "peinture_bois", "peinture_creme", "peinture_rouge", "peinture_turquoise"][(k + row) % 5]
			kit.cyl(xf * Transform3D(Basis(), Vector3(bx, 1.53 + row * 0.5, 11.45)), 0.05, 0.04, 0.3, bc, 6)
	for k2 in range(3):
		kit.barrel(xf * Vector3(-8.0 + k2 * 0.75, 0, 10.6))
	# tables et chaises (bois)
	for tp in [Vector3(-5.5, 0, 3.8), Vector3(4.5, 0, 3.8), Vector3(4.5, 0, 6.4)]:
		var tw: Vector3 = xf * tp
		kit.cafe_table(tw, ile.TOWN_YAW, 2)
	# estrade du musicien
	kit.box(xf * Transform3D(Basis(), Vector3(7.2, 0.12, 8.2)), Vector3(2.6, 0.24, 2.6), "planches", 2.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(7.2, 0.12, 8.2)), Vector3(2.6, 0.24, 2.6))
	# terrasse sur le quai
	for k3 in range(3):
		kit.cafe_table(T(-19.0 + k3 * 6.0, 5.3), ile.TOWN_YAW + k3, 3, "bleu")
	_spot("tav_comptoir", -14.5, 20.4, -14.5, 12.0, "comptoir")
	_spot("tav_bar_1", -17.5, 18.2, -17.5, 22.0, "boire")
	_spot("tav_bar_2", -15.3, 18.2, -15.3, 22.0, "boire")
	_spot("tav_bar_3", -11.4, 18.2, -11.4, 22.0, "boire")
	_spot("tav_bar_4", -9.2, 18.2, -9.2, 22.0, "boire")
	_spot("tav_table_1", -19.1, 13.8, -18.5, 13.8, "assis")
	_spot("tav_table_2", -7.9, 13.8, -8.5, 13.8, "assis")
	_spot("tav_table_3", -9.1, 16.4, -8.5, 16.4, "assis")
	_spot("tav_scene", -5.8, 18.2, -12.0, 15.0, "guitare", 0.24)
	_spot("tav_service", -13.0, 15.0, -13.0, 20.0, "debout")
	for k4 in range(3):
		var tx: float = -19.0 + k4 * 6.0
		_spot("tav_terrasse_%d" % (k4 + 1), tx + 0.55, 5.6, tx, 5.3, "assis")
		_spot("tav_terrasse_%db" % (k4 + 1), tx - 0.5, 4.9, tx, 5.3, "assis")
	_spot("tav_serveuse", -13.0, 7.6, -13.0, 4.0, "debout")


# =================================================================== la place

const SQUARE_NORTH := [
	{"id": "boulangerie", "x": -19.0, "w": 14.0, "floors": [3.6, 3.0], "color": "jaune", "volets": "bleu", "rdc": "boutique", "enseigne": "boulangerie", "auvent": "jaune"},
	{"id": "mairie", "x": 0.0, "w": 18.0, "floors": [4.2, 3.6], "color": "creme", "volets": "gris", "rdc": "porte", "roof": "hip", "balcons": [1], "porte": "brun"},
	{"id": "epicerie", "x": 19.0, "w": 14.0, "floors": [3.6, 3.0], "color": "vert", "volets": "bordeaux", "rdc": "boutique", "enseigne": "epicerie", "auvent": "vert"},
]
const SQUARE_WEST := [
	{"id": "cafe", "z": 35.0, "w": 14.0, "floors": [3.8, 3.0, 3.0], "color": "saumon", "volets": "vert", "rdc": "bar", "enseigne": "cafe", "auvent": "bordeaux"},
	{"id": "poste", "z": 51.0, "w": 14.0, "floors": [3.6, 3.0], "color": "jaune", "volets": "bleu", "rdc": "boutique", "enseigne": "poste", "auvent": "bleu"},
]
const SQUARE_EAST := [
	{"id": "libraire", "z": 34.0, "w": 12.0, "floors": [3.6, 3.0, 3.0], "color": "rose", "volets": "vert", "rdc": "boutique", "enseigne": "libraire", "auvent": "vert"},
	{"id": "herboriste", "z": 50.0, "w": 16.0, "floors": [3.6, 3.0], "color": "blanc", "volets": "vert", "rdc": "boutique", "enseigne": "herboriste", "auvent": "vert"},
]


func _square() -> void:
	for b in SQUARE_NORTH:
		var spec: Dictionary = b.duplicate()
		spec["d"] = 12.0
		var r: Dictionary = kit.building(TF(float(b["x"]), 60.0, 0.0), spec)
		doors[str(b["id"])] = r.get("door", T(float(b["x"]), 59.0))
	for b2 in SQUARE_WEST:
		var spec2: Dictionary = b2.duplicate()
		spec2["d"] = 12.0
		var r2: Dictionary = kit.building(TF(-20.0, float(b2["z"]), -90.0), spec2)
		doors[str(b2["id"])] = r2.get("door", T(-19.0, float(b2["z"])))
	for b3 in SQUARE_EAST:
		var spec3: Dictionary = b3.duplicate()
		spec3["d"] = 14.0
		var r3: Dictionary = kit.building(TF(20.0, float(b3["z"]), 90.0), spec3)
		doors[str(b3["id"])] = r3.get("door", T(19.0, float(b3["z"])))
	_clock_tower()
	_fountain()
	# platanes et leurs grilles
	for p in [[-13.0, 33.0], [13.0, 33.0], [-13.0, 55.0], [13.0, 55.0]]:
		flora_spots["platane"].append(Transform3D(Basis(Vector3.UP, kit.rng.randf() * TAU), T(p[0], p[1], 0.02)))
		kit.box(TF(p[0], p[1], 0.0, 0.08), Vector3(1.6, 0.04, 1.6), "fer", 0.5)
		kit.col_cyl(T(p[0], p[1]), 0.45, 4.0)
	# bancs autour de la fontaine
	for b4 in [[0.0, 50.0, 0.0], [0.0, 38.0, 180.0], [6.2, 44.0, 90.0], [-6.2, 44.0, -90.0]]:
		kit.bench(TF(b4[0], b4[1], b4[2]))
	_spot("banc_n", 0.0, 50.15, 0.0, 44.0, "assis", 0.0)
	_spot("banc_s", 0.0, 37.85, 0.0, 44.0, "assis", 0.0)
	_spot("banc_e", 6.35, 44.0, 0.0, 44.0, "assis", 0.0)
	_spot("banc_o", -6.35, 44.0, 0.0, 44.0, "assis", 0.0)
	# terrasse du café de la place
	for k in range(3):
		var tz: float = 31.0 + k * 4.4
		kit.cafe_table(T(-16.6, tz), ile.TOWN_YAW + k, 2, "bordeaux")
		_spot("cafe_table_%d" % (k + 1), -16.0, tz + 0.15, -16.6, tz, "assis")
		_spot("cafe_table_%db" % (k + 1), -17.2, tz - 0.15, -16.6, tz, "assis")
	# étal de la fleuriste
	_flower_stall(15.5, 29.6)
	# lampadaires de la place et de la rue Haute
	for p2 in [[-18.5, 29.5], [18.5, 58.5], [-18.5, 58.5], [18.5, 41.0], [-28.0, 25.0], [28.0, 25.0], [52.0, 25.0], [-50.0, 25.0], [-35.0, 70.0], [37.0, 70.0]]:
		kit.lamppost(T(p2[0], p2[1]), ile.TOWN_YAW)
	# pots de lauriers
	for p3 in [[-9.0, 59.0], [9.0, 59.0], [-3.0, 28.6], [3.0, 28.6]]:
		kit.planter(T(p3[0], p3[1]), 0.45)
		flora_spots["laurier"].append(Transform3D(Basis(Vector3.UP, kit.rng.randf() * TAU).scaled(Vector3.ONE * 0.75), T(p3[0], p3[1], 0.5)))
	# les commerçants devant leur boutique
	_spot("boulangerie", -21.0, 58.6, -21.0, 50.0, "comptoir")
	_spot("mairie", 0.0, 58.6, 0.0, 48.0, "debout")
	_spot("mairie_horloge", 4.0, 58.6, 4.0, 48.0, "debout")
	_spot("epicerie", 17.0, 58.6, 17.0, 50.0, "comptoir")
	_spot("cafe_service", -17.8, 37.2, -10.0, 37.2, "debout")
	_spot("poste", -18.6, 49.0, -10.0, 49.0, "comptoir")
	_spot("libraire", 18.6, 32.0, 10.0, 32.0, "comptoir")
	_spot("herboriste", 18.6, 48.0, 10.0, 48.0, "comptoir")
	_spot("fleurs", 15.5, 31.0, 10.0, 36.0, "comptoir")
	_spot("petanque_1", -16.5, 49.0, -12.0, 56.0, "petanque")
	_spot("petanque_2", -9.5, 50.0, -12.0, 56.0, "petanque")
	_spot("petanque_3", -13.0, 48.2, -12.0, 56.0, "debout")
	_spot("fontaine_jeu", -2.5, 40.0, 0.0, 44.0, "jouer")
	_spot("fontaine_jeu_b", 3.0, 47.5, 0.0, 44.0, "jouer")
	_spot("place_flane", 10.0, 40.0, 0.0, 44.0, "debout")
	objets["cochonnet"] = T(6.6, 44.6, 0.12)        # sous le banc est de la fontaine


func _fountain() -> void:
	fountain = T(0.0, 44.0)
	var xf: Transform3D = TF(0.0, 44.0, 0.0, 0.06)
	kit.ring(xf, 2.9, 3.35, 0.62, "pierre", 40)
	kit.disc(xf * Transform3D(Basis(), Vector3(0, 0.08, 0)), 2.95, "pierre_sombre", 32, 3.0)
	kit.disc(xf * Transform3D(Basis(), Vector3(0, 0.46, 0)), 2.92, "eau", 32, 3.0)
	kit.cyl(xf, 0.55, 0.42, 1.25, "pierre", 14)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.25, 0)), 0.5, 1.25, 0.3, "pierre", 18)
	kit.disc(xf * Transform3D(Basis(), Vector3(0, 1.5, 0)), 1.18, "eau", 24, 2.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.5, 0)), 0.18, 0.12, 0.9, "pierre", 10)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 2.4, 0)), 0.35, 0.05, 0.4, "pierre", 10)
	for k in range(4):
		var a: float = TAU * k / 4.0
		var from: Vector3 = Vector3(cos(a) * 1.15, 1.48, sin(a) * 1.15)
		var to: Vector3 = Vector3(cos(a) * 1.7, 0.47, sin(a) * 1.7)
		var dir: Vector3 = to - from
		kit.box(xf * Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), (from + to) * 0.5), Vector3(0.05, 0.05, dir.length()), "eau", 1.0)
	kit.col_cyl(fountain, 3.35, 0.7)


## La tour de l'horloge, sur la Mairie : quatre cadrans, un clocheton et sa cloche.
func _clock_tower() -> void:
	var base: Transform3D = TF(0.0, 66.0)
	var tw: float = 4.4
	kit.box(base * Transform3D(Basis(), Vector3(0, 8.5, 0)), Vector3(tw, 17.0, tw), "enduit_creme", 3.0, 63 - 8)
	kit.col_box(base * Transform3D(Basis(), Vector3(0, 8.5, 0)), Vector3(tw, 17.0, tw))
	for y in [7.8, 12.6, 17.0]:
		kit.box(base * Transform3D(Basis(), Vector3(0, y, 0)), Vector3(tw + 0.2, 0.22, tw + 0.2), "pierre", 1.5)
	# clocheton ouvert : quatre piliers et une toiture
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(base * Transform3D(Basis(), Vector3(sx * 1.9, 18.4, sz * 1.9)), Vector3(0.5, 2.8, 0.5), "pierre", 1.5)
	kit.box(base * Transform3D(Basis(), Vector3(0, 19.9, 0)), Vector3(tw + 0.4, 0.25, tw + 0.4), "pierre", 1.5)
	kit.roof_hip(base * Transform3D(Basis(), Vector3(0, 20.0, 0)), tw, tw, 34.0, 0.35, "tuiles")
	kit.cyl(base * Transform3D(Basis(), Vector3(0, 23.6, 0)), 0.04, 0.02, 1.4, "fer", 6)
	bell_pos = (base * Transform3D(Basis(), Vector3(0, 18.6, 0))).origin
	kit.cyl(base * Transform3D(Basis(), Vector3(0, 17.9, 0)), 0.75, 0.4, 1.0, "laiton", 16)
	kit.cyl(base * Transform3D(Basis(), Vector3(0, 18.9, 0)), 0.4, 0.15, 0.25, "laiton", 16)
	# cadrans (texture) et aiguilles (nœuds qui tournent avec l'heure du jeu)
	var face_tex: Texture2D = load("res://assets/textures/azur/horloge.png")
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = face_tex
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	fm.alpha_scissor_threshold = 0.4
	fm.emission_enabled = true
	fm.emission_texture = face_tex
	fm.emission = Color(1.0, 0.9, 0.7)
	fm.emission_energy_multiplier = 0.0
	if main.get("temps_v56") != null:
		main.temps_v56.register_glow(fm, 0.8, 0.0)
	for k in range(4):
		var rot: float = k * 90.0
		var face_xf: Transform3D = base * Transform3D(Basis(Vector3.UP, deg_to_rad(rot)), Vector3(0, 14.6, 0)) * Transform3D(Basis(), Vector3(0, 0, -tw / 2 - 0.03))
		var qm := QuadMesh.new()
		qm.size = Vector2(3.0, 3.0)
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		mi.material_override = fm
		mi.transform = face_xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
		add_child(mi)
		var hands: Array = []
		for hand in [[0.85, 0.09], [1.25, 0.06]]:
			var pivot := Node3D.new()
			pivot.transform = face_xf * Transform3D(Basis(), Vector3(0, 0, -0.04 - hands.size() * 0.02))
			add_child(pivot)
			var hm := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(float(hand[1]), float(hand[0]), 0.02)
			hm.mesh = bm
			hm.material_override = kit.mat("fer")
			hm.position = Vector3(0, float(hand[0]) * 0.42, 0)
			pivot.add_child(hm)
			hands.append(pivot)
		clock_hands.append(hands)


func _flower_stall(x: float, z: float) -> void:
	var xf: Transform3D = TF(x, z, 0.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.9, 1.0), "bois", 1.0)
	for k in range(3):
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.95 + k * 0.22, -0.1 + k * 0.25)), Vector3(2.3, 0.06, 0.3), "bois_sombre", 1.0)
		for f in range(9):
			var c: String = ["tissu_rouge", "tissu_jaune", "tissu_rose", "tissu_blanc", "tissu_orange"][(f + k) % 5]
			kit.cyl(xf * Transform3D(Basis(), Vector3(-1.0 + f * 0.25, 1.0 + k * 0.22, -0.1 + k * 0.25)), 0.09, 0.12, 0.22, c, 6)
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(s * 1.15, 1.25, 0.45)), Vector3(0.06, 2.5, 0.06), "bois_sombre", 1.0)
	kit.awning(xf * Transform3D(Basis(), Vector3(0, 2.5, 0.45)), 2.6, 1.2, 0.4, "rouge")
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(2.4, 1.0, 1.0))


# =================================================================== l'hôtel

func _hotel() -> void:
	# façade sur la plage (regarde -X ville), 22 m de large, 34 m de profondeur
	var spec := {"w": 22.0, "d": 34.0, "floors": [4.4, 3.4, 3.4, 3.4], "color": "blanc", "volets": "bleu", "rdc": "aveugle", "roof": "hip",
		"enseigne": "hotel", "auvent": "bleu", "balcons": [1, 2, 3], "balcon_long": true, "lit": 0.55, "shutters_closed": 0.1,
		"interieur": {"door_x": 0.0, "door_w": 2.4, "lumieres": 4, "energie": 2.2, "portee": 0.5, "sol": "dalles", "couleur": "creme"}}
	var r: Dictionary = kit.building(TF(-74.0, 41.0, 90.0), spec)
	doors["hotel"] = r.get("door", T(-75.0, 41.0))
	interiors.append(["hotel", T(-57.0, 41.0), Vector2(16.7, 10.7), 0.0])
	# perron, marquise de fer et de verre
	kit.box(TF(-75.0, 41.0, 90.0, 0.12), Vector3(5.0, 0.24, 2.0), "pierre", 1.5)
	kit.col_box(TF(-75.0, 41.0, 90.0, 0.12), Vector3(5.0, 0.24, 2.0))
	# réception, salon, escalier
	var lob: Transform3D = TF(-74.0, 41.0, 90.0)
	kit.box(lob * Transform3D(Basis(), Vector3(0, 0.55, 12.0)), Vector3(5.0, 1.1, 0.8), "bois_sombre", 1.2)
	kit.box(lob * Transform3D(Basis(), Vector3(0, 1.13, 12.0)), Vector3(5.3, 0.06, 1.0), "pierre", 1.2)
	kit.col_box(lob * Transform3D(Basis(), Vector3(0, 0.55, 12.0)), Vector3(5.0, 1.1, 0.8))
	kit.box(lob * Transform3D(Basis(), Vector3(0, 2.0, 15.6)), Vector3(4.0, 1.6, 0.25), "bois_sombre", 1.0)
	for k in range(12):
		kit.box(lob * Transform3D(Basis(), Vector3(-7.5, 0.1 + k * 0.18, 20.0 + k * 0.3)), Vector3(2.0, 0.18, 0.32), "pierre", 1.0)
	kit.col_box(lob * Transform3D(Basis(Vector3.RIGHT, 0.54), Vector3(-7.5, 1.1, 21.7)), Vector3(2.0, 0.2, 4.2))
	for p in [[-6.0, 5.0], [6.0, 5.0], [-6.0, 7.5], [6.0, 7.5]]:
		var cxf: Transform3D = lob * Transform3D(Basis(), Vector3(p[0], 0, p[1]))
		kit.box(cxf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.9, 0.5, 0.9), "tissu_bleu", 1.0)
		kit.box(cxf * Transform3D(Basis(), Vector3(0, 0.75, 0.38 if p[1] > 6.0 else -0.38)), Vector3(0.9, 0.6, 0.18), "tissu_bleu", 1.0)
	kit.box(lob * Transform3D(Basis(), Vector3(-6.0, 0.25, 6.25)), Vector3(1.0, 0.5, 0.6), "bois", 1.0)
	kit.box(lob * Transform3D(Basis(), Vector3(6.0, 0.25, 6.25)), Vector3(1.0, 0.5, 0.6), "bois", 1.0)
	# le hall : tapis, lambris, tableaux, tableau des clés, laiton du comptoir
	kit.box(lob * Transform3D(Basis(), Vector3(0, 0.065, 7.0)), Vector3(7.4, 0.02, 6.4), "tissu_or", 1.0)
	kit.box(lob * Transform3D(Basis(), Vector3(0, 0.075, 7.0)), Vector3(7.0, 0.02, 6.0), "tissu_bordeaux", 1.0)
	kit.box(lob * Transform3D(Basis(), Vector3(0, 1.16, 11.58)), Vector3(5.3, 0.05, 0.05), "laiton", 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(lob * Transform3D(Basis(), Vector3(sx * 10.64, 0.6, 17.0)), Vector3(0.05, 1.2, 33.0), "bois_sombre", 1.0)
		kit.box(lob * Transform3D(Basis(), Vector3(sx * 10.62, 1.22, 17.0)), Vector3(0.08, 0.06, 33.0), "bois", 1.0)
		for k3 in range(3):
			var pz: float = 6.0 + k3 * 9.0
			var rot: float = -PI * 0.5 if sx < 0.0 else PI * 0.5
			var pxf: Transform3D = lob * Transform3D(Basis(Vector3.UP, rot), Vector3(sx * 10.6, 2.3, pz))
			kit.box(pxf * Transform3D(Basis(), Vector3(0, 0, 0.03)), Vector3(1.9, 1.45, 0.06), "laiton", 1.0)
			kit.quad(pxf * Transform3D(Basis(), Vector3(0, 0, -0.005)), 1.7, 1.25, "image_tableau_%d" % ((k3 + (0 if sx < 0.0 else 1)) % 3 + 1))
	kit.box(lob * Transform3D(Basis(), Vector3(0, 0.6, 33.64)), Vector3(21.3, 1.2, 0.05), "bois_sombre", 1.0)
	for row in range(4):
		for col in range(8):
			var kx: float = -1.6 + col * 0.46
			var ky: float = 1.5 + row * 0.34
			kit.box(lob * Transform3D(Basis(), Vector3(kx, ky, 15.46)), Vector3(0.05, 0.14, 0.02), "laiton", 1.0)
	kit.box(lob * Transform3D(Basis(), Vector3(0, 3.15, 15.6)), Vector3(3.2, 0.85, 0.2), "bois_sombre", 1.0)
	kit.quad(lob * Transform3D(Basis(), Vector3(0, 3.15, 15.49)), 3.0, 0.75, "image_enseigne_hotel")
	for k2 in range(2):
		kit.planter(lob * Vector3(-3.0 + k2 * 6.0, 0, 1.2), 0.45)
		flora_spots["laurier"].append(Transform3D(Basis(Vector3.UP, kit.rng.randf() * TAU).scaled(Vector3.ONE * 0.7), lob * Vector3(-3.0 + k2 * 6.0, 0.5, 1.2)))
	# le jardin devant l'hôtel : palmiers, tables
	for p2 in [[-77.5, 32.0], [-77.5, 50.0]]:
		flora_spots["palmier"].append(Transform3D(Basis(Vector3.UP, kit.rng.randf() * TAU), T(p2[0], p2[1])))
	kit.cafe_table(T(-77.6, 45.5), ile.TOWN_YAW, 2, "blanc")
	kit.cafe_table(T(-77.6, 36.5), ile.TOWN_YAW + 1.0, 2, "blanc")
	kit.lamppost(T(-77.0, 41.0 - 3.2), ile.TOWN_YAW)
	_spot("hotel_reception", -61.0, 41.0, -70.0, 41.0, "comptoir")
	_spot("hotel_salon_1", -68.0, 35.0, -68.0, 41.0, "assis")
	_spot("hotel_salon_2", -68.0, 47.0, -68.0, 41.0, "assis")
	_spot("hotel_couloir", -64.0, 46.0, -60.0, 46.0, "debout")
	_spot("hotel_jardin_1", -77.0, 45.0, -77.6, 45.5, "assis")
	_spot("hotel_jardin_2", -77.0, 36.0, -77.6, 36.5, "assis")
	_spot("hotel_perron", -76.4, 39.0, -85.0, 39.0, "debout")


# =================================================================== les îlots de la ville

const BLOCKS := [
	# armurerie et maisons à l'est de la place (façades sur la rue du Phare, regardent -X)
	{"id": "armurerie", "x": 40.0, "z": 36.0, "rot": 90.0, "w": 12.0, "d": 12.0, "floors": [3.6, 3.0], "color": "terre", "volets": "brun", "rdc": "boutique", "enseigne": "armurerie", "auvent": "bordeaux"},
	{"id": "maison_phare_1", "x": 40.0, "z": 51.0, "rot": 90.0, "w": 14.0, "d": 12.0, "floors": [3.4, 3.0], "color": "ocre", "volets": "vert", "rdc": "porte"},
	{"id": "maison_phare_2", "x": 58.0, "z": 28.0, "rot": 0.0, "w": 12.0, "d": 14.0, "floors": [3.4, 3.0, 3.0], "color": "rose", "volets": "lavande", "rdc": "porte", "balcons": [1]},
	{"id": "maison_phare_3", "x": 58.0, "z": 44.0, "rot": 0.0, "w": 12.0, "d": 14.0, "floors": [3.4, 3.0], "color": "jaune", "volets": "vert", "rdc": "porte"},
	# à l'ouest de la place, entre la rue de la Gare et l'hôtel
	{"id": "maison_gare_1", "x": -38.0, "z": 62.0, "rot": 0.0, "w": 10.0, "d": 10.0, "floors": [3.4, 3.0], "color": "saumon", "volets": "vert", "rdc": "porte"},
	{"id": "maison_gare_2", "x": -60.0, "z": 60.0, "rot": 0.0, "w": 14.0, "d": 12.0, "floors": [3.4, 3.0, 3.0], "color": "bleu", "volets": "blanc", "rdc": "porte", "balcons": [1, 2]},
]


func _blocks() -> void:
	for b in BLOCKS:
		var spec: Dictionary = b.duplicate()
		var r: Dictionary = kit.building(TF(float(b["x"]), float(b["z"]), float(b["rot"])), spec)
		doors[str(b["id"])] = r.get("door", T(float(b["x"]), float(b["z"])))
	_spot("armurerie", 38.6, 34.0, 30.0, 34.0, "comptoir")


# =================================================================== la rue de derrière

const BACK_ROW := [
	{"id": "maison_haute_1", "x": -64.0, "w": 12.0, "color": "rose", "volets": "vert"},
	{"id": "maison_haute_2", "x": -50.0, "w": 10.0, "color": "blanc", "volets": "bleu"},
	{"id": "maison_haute_3", "x": -24.0, "w": 12.0, "color": "ocre", "volets": "brun"},
	{"id": "maison_haute_4", "x": -9.0, "w": 12.0, "color": "jaune", "volets": "vert"},
	{"id": "maison_haute_5", "x": 6.0, "w": 10.0, "color": "creme", "volets": "lavande"},
	{"id": "maison_haute_6", "x": 20.0, "w": 12.0, "color": "saumon", "volets": "turquoise"},
	{"id": "maison_haute_7", "x": 46.0, "w": 12.0, "color": "vert", "volets": "bordeaux"},
	{"id": "maison_haute_8", "x": 59.0, "w": 10.0, "color": "terre", "volets": "vert"},
]


func _back_row() -> void:
	for b in BACK_ROW:
		var spec: Dictionary = b.duplicate()
		spec["d"] = 8.0
		spec["floors"] = [3.4, 3.0] if int(b["x"]) % 2 == 0 else [3.4, 3.0, 3.0]
		spec["rdc"] = "porte"
		var r: Dictionary = kit.building(TF(float(b["x"]), 79.0, 0.0), spec)
		doors[str(b["id"])] = r.get("door", T(float(b["x"]), 78.0))


# =================================================================== les collines

func _hills() -> void:
	var cols := ["blanc", "creme", "ocre", "rose", "jaune", "saumon", "terre", "blanc", "bleu", "rose"]
	var vols := ["bleu", "vert", "lavande", "vert", "bleu", "turquoise", "brun", "vert", "blanc", "bordeaux"]
	for i in range(ile.pads_world.size()):
		var p: Vector3 = ile.pads_world[i]
		var spec := {"w": 9.0, "d": 8.0, "floors": [3.2, 3.0], "color": cols[i % cols.size()], "volets": vols[i % vols.size()], "rdc": "porte", "roof": "hip" if i % 2 == 0 else "gable", "balcons": [1] if i % 3 == 0 else []}
		var xf: Transform3D = TFW(p + Vector3.UP * -0.05, 0.0) * Transform3D(Basis(), Vector3(0, 0, -4.0))
		var r: Dictionary = kit.building(xf, spec)
		doors["villa_%d" % i] = r.get("door", p)
		# muret du jardin et un cyprès
		var g: Vector3 = (xf * Vector3(5.2, 0, 2.0))
		flora_spots["cypres"].append(Transform3D(Basis(), Vector3(g.x, ile.height(g.x, g.z), g.z)))
		var o: Vector3 = (xf * Vector3(-5.5, 0, -2.5))
		flora_spots["olivier"].append(Transform3D(Basis(Vector3.UP, i), Vector3(o.x, ile.height(o.x, o.z), o.z)))
	# le belvédère : dallage, garde-corps, longue-vue, banc
	var s: Vector3 = ile.summit_world
	kit.cyl(Transform3D(Basis(), s + Vector3.DOWN * 0.3), 6.0, 6.0, 0.36, "dalles", 32)
	for k in range(18):
		var a: float = PI * 0.35 + k / 17.0 * PI * 1.3 + ile.TOWN_YAW
		var q: Vector3 = s + Vector3(-sin(a) * 5.8, 0.0, -cos(a) * 5.8)
		kit.cyl(Transform3D(Basis(), q), 0.05, 0.05, 1.0, "fer", 6)
	kit.ring(Transform3D(Basis(), s + Vector3.UP * 0.95), 5.75, 5.85, 0.06, "fer", 48)
	kit.bench(TFW(s + _town_dir(-3.0, 1.5), 180.0))
	var tel: Vector3 = s + _town_dir(1.8, -4.4)
	kit.cyl(Transform3D(Basis(), tel), 0.06, 0.05, 1.2, "laiton", 8)
	kit.cyl(Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.RIGHT, PI / 2.0 - 0.2), tel + Vector3(0, 1.25, 0.3)), 0.07, 0.05, 0.7, "laiton", 10)
	# chevalet de la peintre
	var ez: Vector3 = s + _town_dir(3.0, -2.5)
	var ex: Transform3D = TFW(ez, 180.0)
	for lx in [-0.3, 0.3]:
		kit.box(ex * Transform3D(Basis(Vector3.BACK, lx * 0.4), Vector3(lx, 0.8, 0)), Vector3(0.04, 1.65, 0.04), "bois", 1.0)
	kit.box(ex * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.75, 0.35)), Vector3(0.04, 1.5, 0.04), "bois", 1.0)
	kit.box(ex * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 1.25, -0.05)), Vector3(0.9, 0.65, 0.03), "peinture_creme", 1.0)
	_spot_w("belvedere_peintre", s + _town_dir(3.0, -1.6), s + _town_dir(3.0, -3.5), "peindre")
	_spot_w("belvedere_banc", s + _town_dir(-3.0, 1.35), s + _town_dir(-3.0, -6.0), "assis")
	_spot_w("belvedere_vue", s + _town_dir(1.8, -3.6), s + _town_dir(1.8, -12.0), "debout")
	objets["appareil_photo"] = s + _town_dir(-4.6, 2.6) + Vector3.UP * 0.1
	objets["cerf_volant"] = TG(-58.0, 118.0, 0.15)


## Un décalage exprimé dans les axes de la ville (x le long du quai, z vers les collines).
func _town_dir(x: float, z: float) -> Vector3:
	return Basis(Vector3.UP, ile.TOWN_YAW) * Vector3(x, 0, z)


# =================================================================== la plage

func _beach() -> void:
	# la promenade : dalles, muret de moellons côté mer, escaliers vers le sable
	_flat(-172.0, -80.0, 17.4, 24.0, 0.05, "dalles", 4.0)
	kit.box(TF(-126.0, 17.0, 0.0, -0.35), Vector3(92.0, 1.6, 0.8), "moellons", 3.0, 63 - 8)
	kit.box(TF(-126.0, 17.0, 0.0, 0.48), Vector3(92.2, 0.1, 0.95), "pierre", 1.5)
	kit.col_box(TF(-126.0, 17.0, 0.0, 0.0), Vector3(92.0, 1.0, 0.8))
	for sx in [-100.0, -130.0, -158.0]:
		kit.box(TF(sx, 17.0, 0.0, 0.0), Vector3(2.6, 1.2, 0.9), "dalles", 2.0, 0)
		for k in range(5):
			var z: float = 16.4 - k * 0.5
			var y: float = 0.0 - k * 0.12
			kit.box(TF(sx, z, 0.0, y - 0.1), Vector3(2.4, 0.2, 0.5), "pierre", 1.0)
			kit.col_box(TF(sx, z, 0.0, y - 0.1), Vector3(2.4, 0.2, 0.5))
	# couper le muret au droit des escaliers : on le refait en morceaux par-dessus (plus simple : passages)
	for p in [[-100.0, 15.0], [-130.0, 15.0], [-158.0, 15.0]]:
		points["marche_%d" % int(-p[0])] = TG(p[0], p[1], 0.05)
	# palmiers, lampadaires, bancs de la promenade
	for x in range(-168, -84, 12):
		flora_spots["palmier"].append(Transform3D(Basis(Vector3.UP, x * 0.37), T(float(x), 22.6)))
	for x2 in [-90.0, -112.0, -134.0, -156.0]:
		kit.lamppost(T(x2, 23.3), ile.TOWN_YAW)
	for x3 in [-96.0, -118.0, -142.0, -164.0]:
		kit.bench(TF(x3, 18.6, 0.0))
	# le kiosque du glacier
	_kiosk(-92.0, 22.6)
	# la tente de Madame Rita
	_tent(-146.0, 22.0)
	# la paillote du Coco Loco, sur le sable
	_paillote(-125.0, 6.0)
	# le poste de secours
	_lifeguard(-108.0, -1.0)
	# parasols, serviettes, transats
	var towels := [[-150.0, 4.0, "rouge", "auvent_rouge"], [-141.0, 6.0, "bleu", "auvent_bleu"], [-132.0, 3.2, "jaune", "chaume"],
		[-112.0, 6.4, "turquoise", "auvent_turquoise"], [-103.0, 4.0, "rose", "auvent_orange"], [-160.0, 7.0, "vert", "auvent_vert"], [-118.0, 9.5, "orange", "chaume"]]
	for i in range(towels.size()):
		var t: Array = towels[i]
		var g: Vector3 = TG(float(t[0]), float(t[1]), 0.02)
		var txf: Transform3D = TFW(g, 0.0 + i * 7.0)
		kit.box(txf, Vector3(0.9, 0.02, 1.9), "tissu_" + str(t[2]), 1.0)
		var pole: Vector3 = g + _town_dir(0.9, 0.4)
		kit.cyl(Transform3D(Basis(), pole + Vector3.DOWN * 0.3), 0.03, 0.03, 2.6, "bois_clair", 6)
		if str(t[3]) == "chaume":
			kit.cyl(Transform3D(Basis(), pole + Vector3.UP * 1.9), 1.5, 0.05, 0.55, "chaume", 10)
		else:
			kit.umbrella(Transform3D(Basis(), pole + Vector3.UP * 2.3), 1.4, 0.5, str(t[3]).substr(7))
		_spot_w("plage_%d" % (i + 1), g + Vector3.UP * 0.02, g + _town_dir(0.0, -3.0), "allonge")
		if i % 2 == 0:
			_transat(TFW(g + _town_dir(-1.4, 0.2), 10.0 * i))
	_spot_w("chateau_sable", TG(-136.0, 0.8, 0.02), TG(-136.0, -2.0), "jouer")
	_spot_w("plage_balade_1", TG(-150.0, -2.0, 0.02), TG(-150.0, -10.0), "debout")
	_spot_w("plage_balade_2", TG(-95.0, -1.0, 0.02), TG(-95.0, -10.0), "debout")
	for k2 in range(3):
		_spot("promenade_%d" % (k2 + 1), -97.0 - k2 * 28.0, 19.0, -97.0 - k2 * 28.0, 10.0, "debout")
	objets["alliance"] = TG(-127.0, 1.2, 0.02)
	objets["etoile_1"] = TG(-118.0, -26.0, 0.1)
	objets["etoile_2"] = TG(-140.0, -30.0, 0.1)
	objets["etoile_3"] = TG(-100.0, -32.0, 0.1)
	objets["corail_rouge"] = TG(-162.0, -36.0, 0.1)


func _kiosk(x: float, z: float) -> void:
	var xf: Transform3D = TF(x, z, 0.0)
	kit.cyl(xf, 1.5, 1.5, 0.15, "pierre", 8)
	for k in range(6):
		var a: float = TAU * k / 6.0
		kit.cyl(xf * Transform3D(Basis(), Vector3(cos(a) * 1.35, 0.15, sin(a) * 1.35)), 0.05, 0.05, 2.3, "peinture_blanc", 6)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.15, 0.35)), 1.1, 1.1, 1.0, "peinture_creme", 8)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 2.45, 0)), 1.85, 0.08, 0.9, "auvent_rouge", 8)
	kit.sign_board(xf * Transform3D(Basis(), Vector3(0, 2.75, -1.45)) * Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3.ZERO), 1.8, 0.45, "glacier", true)
	kit.col_cyl(T(x, z), 1.5, 2.4)
	_spot("glacier", x, z - 1.75, x, z - 6.0, "comptoir")


func _tent(x: float, z: float) -> void:
	var xf: Transform3D = TF(x, z, 0.0)
	kit.cyl(xf, 1.9, 1.9, 1.7, "auvent_bordeaux", 8, false)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.7, 0)), 2.05, 0.06, 1.3, "auvent_bordeaux", 8)
	kit.sign_board(xf * Transform3D(Basis(), Vector3(0, 2.0, -1.95)), 1.6, 0.4, "rita", true)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.38, -0.5)), Vector3(0.9, 0.76, 0.9), "tissu_noir", 1.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.76, -0.5)), 0.13, 0.13, 0.26, "verre", 12)
	kit.col_cyl(T(x, z, 0.0) + _town_dir(0, 0.6), 1.4, 2.5)
	_spot("rita", x, z + 0.2, x, z - 3.0, "assis")


func _paillote(x: float, z: float) -> void:
	var g: Vector3 = TG(x, z, 0.0)
	var xf: Transform3D = TFW(g, 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.cyl(xf * Transform3D(Basis(), Vector3(sx * 2.0, -0.3, sz * 1.6)), 0.09, 0.08, 3.1, "bois", 8)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 2.75, 0)), 3.4, 0.1, 1.6, "chaume", 8)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.55, -1.1)), Vector3(3.6, 1.1, 0.5), "bois_clair", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.13, -1.15)), Vector3(3.8, 0.06, 0.7), "bois", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.55, -1.1)), Vector3(3.6, 1.1, 0.5))
	for k in range(9):
		kit.cyl(xf * Transform3D(Basis(), Vector3(-1.6 + k * 0.4, 1.16, -1.1)), 0.04, 0.035, 0.25, ["peinture_vert", "peinture_orange", "peinture_bois"][k % 3], 6)
	kit.sign_board(xf * Transform3D(Basis(), Vector3(0, 2.2, -1.65)), 2.2, 0.55, "paillote", true)
	for s2 in [-1.2, 0.0, 1.2]:
		kit.cyl(xf * Transform3D(Basis(), Vector3(s2, 0.0, -1.95)), 0.2, 0.2, 0.75, "bois_sombre", 8)
	_spot_w("paillote", g + _town_dir(0.0, -0.2), g + _town_dir(0.0, -5.0), "comptoir")
	_spot_w("paillote_1", g + _town_dir(-1.2, -2.25), g + _town_dir(-1.2, 0.0), "boire")
	_spot_w("paillote_2", g + _town_dir(1.2, -2.25), g + _town_dir(1.2, 0.0), "boire")


func _lifeguard(x: float, z: float) -> void:
	var g: Vector3 = TG(x, z, 0.0)
	var xf: Transform3D = TFW(g, 0.0)
	for sx in [-0.8, 0.8]:
		for sz in [-0.8, 0.8]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx, 1.0, sz)), Vector3(0.14, 2.4, 0.14), "peinture_blanc", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 2.2, 0)), Vector3(2.0, 0.12, 2.0), "planches", 2.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 3.0, 0.3)), Vector3(1.6, 1.5, 1.2), "peinture_rouge", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 3.85, 0.3)), Vector3(1.9, 0.12, 1.5), "peinture_blanc", 1.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0.9, 2.2, -0.9)), 0.03, 0.03, 2.8, "fer", 6)
	kit.quad(xf * Transform3D(Basis(), Vector3(1.25, 4.6, -0.9)), 0.7, 0.45, "tissu_jaune", Vector2.ZERO, Vector2.ONE, true)
	for k in range(7):
		kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 0.25 + k * 0.3, -1.3 - k * 0.1)), Vector3(0.7, 0.04, 0.14), "bois", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(1.8, 2.4, 1.8))
	_spot_w("secours", g + _town_dir(0.0, -2.0), g + _town_dir(0.0, -12.0), "debout")


func _transat(xf: Transform3D) -> void:
	kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.1), Vector3(0, 0.25, 0.3)), Vector3(0.6, 0.04, 1.2), "tissu_blanc", 1.0)
	kit.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.9), Vector3(0, 0.6, -0.45)), Vector3(0.6, 0.04, 0.8), "tissu_blanc", 1.0)
	for s in [-0.3, 0.3]:
		kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(s, 0.2, 0.2)), Vector3(0.03, 0.03, 1.0), "bois", 1.0)


# =================================================================== la pointe et le phare

func _headland() -> void:
	var lp: Vector3 = TG(ile.LIGHTHOUSE.x, ile.LIGHTHOUSE.y, -0.2)
	var xf: Transform3D = Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), lp)
	# soubassement de moellons
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, -1.0, 0)), 3.2, 3.0, 2.2, "moellons", 20)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), 3.1, 3.1, 0.2, "pierre", 20)
	# la tour blanche, une bande rouge, la galerie, la lanterne, le dôme
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 1.4, 0)), 2.1, 1.55, 15.0, "peinture_blanc", 20)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 11.0, 0)), 1.72, 1.68, 1.6, "peinture_rouge", 20, false)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 16.4, 0)), 2.25, 2.25, 0.22, "pierre", 24)
	kit.ring(xf * Transform3D(Basis(), Vector3(0, 17.4, 0)), 2.15, 2.22, 0.06, "fer", 40)
	for k in range(16):
		var a: float = TAU * k / 16.0
		kit.cyl(xf * Transform3D(Basis(), Vector3(cos(a) * 2.18, 16.6, sin(a) * 2.18)), 0.025, 0.025, 0.85, "fer", 4, false)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 16.6, 0)), 1.3, 1.3, 0.5, "peinture_rouge", 16)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 17.1, 0)), 1.25, 1.25, 1.7, "verre", 16, false)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 18.8, 0)), 1.45, 0.25, 0.9, "peinture_rouge", 16)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, 19.7, 0)), 0.08, 0.02, 0.8, "laiton", 6)
	# porte et petites fenêtres
	kit.quad(xf * Transform3D(Basis(Vector3.UP, PI * 0.75), Vector3(0, 2.6, 0)) * Transform3D(Basis(), Vector3(0, 0, -2.06)), 1.0, 2.2, "porte_vert")
	for y in [6.0, 9.0, 13.5]:
		kit.quad(xf * Transform3D(Basis(Vector3.UP, PI * 0.75 + y), Vector3(0, y, 0)) * Transform3D(Basis(), Vector3(0, 0, -1.92 + (y - 6.0) * 0.035)), 0.45, 0.8, "fenetre_nuit")
	kit.col_cyl(lp + Vector3.DOWN * 1.0, 3.2, 20.0)
	# le feu tournant : deux faisceaux et une lumière
	lighthouse_head = Node3D.new()
	lighthouse_head.name = "Feu_du_phare"
	lighthouse_head.position = lp + Vector3(0, 17.9, 0)
	add_child(lighthouse_head)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_color = Color(1.0, 0.92, 0.7, 0.0)
	beam_mat.disable_receive_shadows = true
	beam_mat.no_depth_test = false
	if main.get("temps_v56") != null:
		main.temps_v56.register_glow(beam_mat, 0.0, 0.0)
	lighthouse_head.set_meta("beam_mat", beam_mat)
	for s in [0.0, PI]:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.25
		cm.bottom_radius = 7.0
		cm.height = 90.0
		cm.radial_segments = 16
		cm.cap_top = false
		cm.cap_bottom = false
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = beam_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.transform = Transform3D(Basis(Vector3.UP, s) * Basis(Vector3.RIGHT, PI / 2.0 + 0.04), Basis(Vector3.UP, s) * Vector3(0, 0, 45.0))
		lighthouse_head.add_child(mi)
	var lens := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	lens.mesh = sm
	lens.material_override = kit.mat("lampe")
	lighthouse_head.add_child(lens)
	lighthouse_light = OmniLight3D.new()
	lighthouse_light.light_color = Color(1.0, 0.9, 0.7)
	lighthouse_light.omni_range = 28.0
	lighthouse_light.shadow_enabled = false
	lighthouse_head.add_child(lighthouse_light)
	if main.get("temps_v56") != null:
		main.temps_v56.register_lamp(lighthouse_light, 3.0)
	# la maison du gardien
	var cg: Vector3 = TG(88.0, -14.0, -0.1)
	var r: Dictionary = kit.building(TFW(cg, 90.0), {"w": 7.0, "d": 6.0, "floors": [3.2], "color": "blanc", "volets": "vert", "rdc": "porte", "roof": "gable"})
	doors["gardien"] = r.get("door", cg)
	_spot_w("phare_porte", lp + _town_dir(-2.4, 2.6) + Vector3.UP * 1.4, lp + _town_dir(-10.0, 10.0), "debout")
	objets["lentille_phare"] = TG(120.0, -50.0, 0.1)


# =================================================================== la jetée

func _breakwater() -> void:
	var a := Vector2(72.0, -26.0)
	var b := Vector2(6.0, -84.0)
	var dir: Vector2 = (b - a).normalized()
	var length: float = a.distance_to(b)
	var rot: float = rad_to_deg(atan2(dir.x, -dir.y))
	var mid: Vector2 = (a + b) * 0.5
	# la levée de béton et le chemin de ronde
	var xf: Transform3D = Transform3D(Basis(Vector3.UP, ile.TOWN_YAW) * Basis(Vector3.UP, -atan2(dir.x, -dir.y)), T(mid.x, mid.y))
	kit.box(xf * Transform3D(Basis(), Vector3(0, -2.6, 0)), Vector3(5.0, 6.4, length), "moellons_sombre", 3.0, 63 - 8)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(4.6, 0.1, length), "dalles", 3.0, 4)
	kit.box(xf * Transform3D(Basis(), Vector3(-2.6, 1.1, 0)), Vector3(0.6, 1.1, length), "moellons", 2.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -2.6, 0)), Vector3(5.0, 6.4, length))
	kit.col_box(xf * Transform3D(Basis(), Vector3(-2.6, 1.1, 0)), Vector3(0.6, 1.1, length))
	# le petit feu vert du bout de la jetée
	var end_xf: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0.65, length * 0.5 - 1.8))
	kit.cyl(end_xf, 0.9, 0.7, 3.4, "peinture_vert", 12)
	kit.cyl(end_xf * Transform3D(Basis(), Vector3(0, 3.4, 0)), 0.45, 0.45, 0.6, "verre", 10)
	kit.cyl(end_xf * Transform3D(Basis(), Vector3(0, 4.0, 0)), 0.6, 0.05, 0.5, "peinture_vert", 10)
	kit.col_cyl(end_xf.origin, 0.9, 4.0)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.3, 1.0, 0.45)
	gl.omni_range = 8.0
	gl.position = end_xf.origin + Vector3.UP * 3.7
	add_child(gl)
	if main.get("temps_v56") != null:
		main.temps_v56.register_lamp(gl, 2.0)
	# les gros blocs de l'enrochement, côté large
	var rocks := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Rocks.shape(5611, Vector3(2.4, 1.6, 2.0), 0.85, 0.18)
	var xfs: Array = []
	var n: int = int(length / 2.2)
	for i in range(n):
		var t: float = (i + 0.5) / n
		var p: Vector2 = a.lerp(b, t)
		for row in range(2):
			var off: Vector2 = Vector2(dir.y, -dir.x) * (3.6 + row * 1.9)
			var q: Vector2 = p + off * (1.0 if row == 0 else 1.0)
			var w: Vector3 = T(q.x, q.y, -1.0 - row * 1.8)
			xfs.append(Transform3D(Basis(Vector3.UP, kit.rng.randf() * TAU).rotated(Vector3.RIGHT, kit.rng.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * kit.rng.randf_range(0.8, 1.25)), w))
	mm.instance_count = xfs.size()
	for i2 in range(xfs.size()):
		mm.set_instance_transform(i2, xfs[i2])
	rocks.multimesh = mm
	rocks.material_override = Rocks.material(Color(0.78, 0.76, 0.7), 0.15)
	rocks.name = "Enrochement_jetee"
	add_child(rocks)
	_spot_w("jetee_bout", T(b.x + dir.x * -5.0, b.y + dir.y * -5.0, 0.62), T(b.x - 10.0, b.y - 20.0), "debout")
	points["jetee_0"] = T(a.x - dir.x * 1.0, a.y - dir.y * 1.0, 0.62)
	points["jetee_1"] = T(mid.x, mid.y, 0.62)
	points["jetee_2"] = T(b.x - dir.x * 5.0, b.y - dir.y * 5.0, 0.62)


# =================================================================== môle, pontons

func _piers() -> void:
	# le môle de la gare maritime (pierre), 7 m de large, 38 m vers le large
	var xf: Transform3D = TF(-70.0, -19.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, -2.7, 0)), Vector3(7.0, 8.0, 38.0), "moellons", 3.0, 63 - 8 - 16)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.25, 0)), Vector3(7.0, 0.1, 38.0), "dalles", 3.5, 4)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -2.7, 0)), Vector3(7.0, 8.0, 38.0))
	for z in [-34.0, -26.0, -18.0, -10.0, -3.0]:
		kit.bollard(T(-66.9, z))
	kit.lamppost(T(-72.8, -34.0), ile.TOWN_YAW)
	kit.lamppost(T(-72.8, -14.0), ile.TOWN_YAW)
	kit.bench(TF(-72.6, -22.0, -90.0))
	# l'Hirondelle s'amarre côté est du môle, l'avant vers le large
	ferry_berth = Transform3D(Basis(Vector3.UP, ile.TOWN_YAW), T(-62.6, -25.0, -1.62))
	ferry_gangway = T(-67.6, -24.0)
	_spot("gare_capitaine", -67.8, -21.0, -62.0, -21.0, "debout")
	_spot("gare_attente", -71.5, -26.0, -62.0, -26.0, "debout")
	_spot("capitainerie", -55.0, 8.4, -55.0, 0.0, "comptoir")
	_spot("location", -27.0, 8.6, -27.0, 0.0, "comptoir")
	_spot("paulo", 10.0, 8.6, 10.0, 0.0, "comptoir")
	_spot("bijouterie", 20.0, 8.7, 20.0, 0.0, "comptoir")
	_spot("souvenirs", 29.0, 8.7, 29.0, 0.0, "comptoir")
	for k in range(2):
		var tx: float = 6.0 + k * 6.5
		kit.cafe_table(T(tx, 5.2), ile.TOWN_YAW + k, 2, "rouge")
		_spot("paulo_table_%d" % (k + 1), tx + 0.5, 5.5, tx, 5.2, "assis")
		_spot("paulo_table_%db" % (k + 1), tx - 0.5, 4.9, tx, 5.2, "assis")
	# le ponton de la barque du joueur (construit par boat_v29) et ceux des voiliers
	boat_dock = [T(24.0, 0.2, -0.2), T(24.0, -15.0, -0.2)]
	for px in [-25.0, 45.0]:
		var len2: float = 24.0
		var pxf: Transform3D = TF(px, -len2 * 0.5 - 2.0, 0.0, -1.0)
		kit.box(pxf, Vector3(2.2, 0.16, len2), "planches", 2.2)
		kit.col_box(pxf, Vector3(2.2, 0.16, len2))
		# passerelle inclinée depuis le quai
		var rxf: Transform3D = TF(px, -1.0, 0.0, -0.5) * Transform3D(Basis(Vector3.RIGHT, -0.48), Vector3.ZERO)
		kit.box(rxf, Vector3(1.4, 0.1, 2.3), "planches", 2.0)
		kit.col_box(rxf, Vector3(1.4, 0.1, 2.3))
		for k2 in range(5):
			kit.cyl(Transform3D(Basis(), T(px + 1.25, -4.0 - k2 * 5.0, -3.0)), 0.13, 0.13, 3.4, "bois_sombre", 8)
	objets["croissants"] = T(53.2, 4.6, 0.02)
	objets["partition_1"] = T(61.0, 2.6, 0.06)
	objets["partition_2"] = T(-16.5, 46.0, 0.1)
	objets["partition_3"] = TG(-110.0, 8.5, 0.05)


# =================================================================== le décor du port

func _props() -> void:
	# caisses, tonneaux, filets et casiers sur le quai
	for c in [[-46.5, 4.0, 0.2], [-45.6, 4.2, 0.0], [-46.1, 3.4, 0.4], [50.5, 3.6, 0.1], [51.4, 3.5, 0.3], [52.2, 3.8, 0.0], [51.0, 4.5, 0.2]]:
		kit.crate(T(c[0], c[1]), ile.TOWN_YAW + c[2], 0.75)
	kit.crate(T(51.0, 3.6, 0.75), ile.TOWN_YAW + 0.5, 0.6)
	for b in [[-48.5, 3.8], [-48.9, 4.6], [48.6, 3.2]]:
		kit.barrel(T(b[0], b[1]))
	# filet de pêche drapé sur les caisses de Gaston
	kit.quad(TF(46.0, 3.9, 0.0, 0.6) * Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3.ZERO), 2.6, 1.6, "filet", Vector2.ZERO, Vector2(2.0, 1.2), true)
	kit.crate(T(46.0, 3.4), ile.TOWN_YAW, 0.55, true)
	_spot("quai_gaston", 46.0, 3.0, 46.0, -6.0, "assis", 0.55)
	_spot("quai_lucas_a", -44.0, 5.6, -46.0, 4.0, "debout")
	_spot("quai_lucas_b", 49.6, 5.4, 51.0, 3.8, "debout")
	_spot("quai_flane_1", -8.0, 2.0, -8.0, -10.0, "debout")
	_spot("quai_flane_2", 34.0, 2.0, 34.0, -10.0, "debout")
	_spot("ponton_yannick", 24.0, 1.4, 24.0, -6.0, "debout")
	# casiers à homards
	for k in range(4):
		var xf: Transform3D = TF(53.5 + k * 0.7, 5.2, k * 20.0)
		kit.cyl(xf, 0.3, 0.3, 0.5, "filet", 8)
	# une ancre ancienne et un canon décoratif devant la capitainerie
	var an: Transform3D = TF(-51.5, 8.0, 0.0)
	kit.box(an * Transform3D(Basis(), Vector3(0, 0.9, 0)), Vector3(0.14, 1.8, 0.14), "fer", 1.0)
	kit.box(an * Transform3D(Basis(), Vector3(0, 1.7, 0)), Vector3(0.7, 0.1, 0.1), "fer", 1.0)
	kit.ring(an * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.35, 0.05)), 0.5, 0.6, 0.1, "fer", 16)
	kit.col_cyl(T(-51.5, 8.0), 0.4, 1.8)


# =================================================================== les bateaux du port

func _hull_mesh(length: float, beam: float, depth: float, paint: String, stripe: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 14
	var segs := 10
	var sections: Array = []
	for i in range(rings + 1):
		var t: float = float(i) / rings
		var z: float = (t - 0.5) * length
		var wf: float = sin(pow(t, 0.8) * PI) if t < 0.5 else pow(sin(t * PI), 0.6) * 0.92 + 0.08 * (1.0 - t)
		wf = clampf(wf, 0.02, 1.0)
		var sheer: float = depth + 0.18 * pow(absf(t - 0.45) * 2.0, 2.0)
		var ring: Array = []
		for s in range(segs + 1):
			var a: float = PI * float(s) / segs
			var x: float = -cos(a) * beam * 0.5 * wf
			var y: float = sheer - sin(a) * depth * (0.55 + 0.45 * wf)
			ring.append(Vector3(x, y, z))
		sections.append(ring)
	for i in range(rings):
		for s in range(segs):
			var a0: Vector3 = sections[i][s]
			var a1: Vector3 = sections[i][s + 1]
			var b0: Vector3 = sections[i + 1][s]
			var b1: Vector3 = sections[i + 1][s + 1]
			var n: Vector3 = (a1 - a0).cross(b0 - a0).normalized()
			var c: Vector3 = (a0 + a1 + b0 + b1) * 0.25
			if n.dot(Vector3(c.x, c.y - depth * 0.4, 0.0)) < 0.0:
				n = -n
			var low: bool = (a0.y + b0.y) * 0.5 < depth * 0.25
			var col: Color = Color(0.55, 0.12, 0.1) if low else (Color(1, 1, 1))
			for v in [[a0, b0, a1], [a1, b0, b1]]:
				var tn: Vector3 = (v[1] - v[0]).cross(v[2] - v[0])
				var order: Array = v if tn.dot(n) < 0.0 else [v[0], v[2], v[1]]
				for p in order:
					st.set_color(col)
					st.set_normal(n)
					st.set_uv(Vector2(p.z / length, p.y))
					st.add_vertex(p)
	var mesh := st.commit()
	return mesh


func _boats() -> void:
	var colors := ["blanc", "bleu", "blanc", "vert", "blanc", "rouge", "blanc", "turquoise", "jaune", "blanc"]
	var slots: Array = []
	for px in [-25.0, 45.0]:
		for k in range(4):
			for s in [-1.0, 1.0]:
				if (k + int(s)) % 3 == 0 and px > 0.0:
					continue
				slots.append(Vector2(px + s * 3.6, -6.0 - k * 5.5))
	for i in range(slots.size()):
		var p: Vector2 = slots[i]
		var sail: bool = i % 3 != 2
		var length: float = 7.5 if sail else 5.0
		var node := Node3D.new()
		node.name = "Voilier_%d" % i
		node.transform = Transform3D(Basis(Vector3.UP, ile.TOWN_YAW + (PI if i % 2 == 0 else 0.0) + kit.rng.randf_range(-0.05, 0.05)), Vector3(T(p.x, p.y).x, -0.42, T(p.x, p.y).z))
		add_child(node)
		var hull := MeshInstance3D.new()
		hull.mesh = _hull_mesh(length, 2.4 if sail else 1.9, 0.9 if sail else 0.7, colors[i % colors.size()], "")
		var hm := StandardMaterial3D.new()
		hm.vertex_color_use_as_albedo = true
		hm.albedo_color = kit.mat("peinture_" + colors[i % colors.size()]).albedo_color if colors[i % colors.size()] != "blanc" else Color(0.95, 0.95, 0.93)
		hm.roughness = 0.4
		hm.cull_mode = BaseMaterial3D.CULL_DISABLED
		hull.material_override = hm
		hull.position = Vector3(0, -0.45, 0)
		node.add_child(hull)
		var deck := MeshInstance3D.new()
		var dm := BoxMesh.new()
		dm.size = Vector3((2.4 if sail else 1.9) * 0.82, 0.06, length * 0.82)
		deck.mesh = dm
		deck.material_override = kit.mat("planches")
		deck.position = Vector3(0, 0.42, 0)
		node.add_child(deck)
		if sail:
			var cab := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(1.4, 0.5, 2.0)
			cab.mesh = cb
			cab.material_override = kit.mat("peinture_creme")
			cab.position = Vector3(0, 0.7, 0.4)
			node.add_child(cab)
			var mast := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.05
			cm.bottom_radius = 0.07
			cm.height = 9.0
			mast.mesh = cm
			mast.material_override = kit.mat("chrome")
			mast.position = Vector3(0, 4.9, -0.6)
			node.add_child(mast)
			var boom := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.16
			bm.bottom_radius = 0.16
			bm.height = 3.0
			boom.mesh = bm
			boom.material_override = kit.mat("tissu_" + ["bleu", "creme", "rouge", "vert"][i % 4])
			boom.rotation = Vector3(PI / 2.0, 0, 0)
			boom.position = Vector3(0, 1.6, 0.9)
			node.add_child(boom)
		else:
			# barque de pêcheur (pointu) : un petit taud et un mât court
			var tent := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(1.2, 0.6, 1.2)
			tent.mesh = tb
			tent.material_override = kit.mat("peinture_bois")
			tent.position = Vector3(0, 0.75, -0.6)
			node.add_child(tent)
		boats.append([node, kit.rng.randf() * TAU, node.position.y])


# =================================================================== lieux et rues

func _spot(name: String, x: float, z: float, fx: float, fz: float, pose: String, dy: float = 0.0) -> void:
	var inside_y: float = 0.06 if name.begins_with("tav_") and not name.begins_with("tav_terrasse") and name != "tav_serveuse" else 0.0
	if name.begins_with("hotel_") and not name.begins_with("hotel_jardin") and name != "hotel_perron":
		inside_y = 0.06
	spots[name] = {"pos": T(x, z, inside_y + dy), "face": T(fx, fz), "pose": pose}


func _spot_w(name: String, pos: Vector3, face: Vector3, pose: String) -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose}


func _p(name: String, x: float, z: float, ground: bool = false) -> void:
	points[name] = TG(x, z, 0.0) if ground else T(x, z)


func _link(a: String, b: String) -> void:
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


func _chain(names: Array) -> void:
	for i in range(names.size() - 1):
		_link(names[i], names[i + 1])


## Le réseau des rues : nœuds nommés, reliés à vue (aucun mur entre deux nœuds voisins).
func _graph() -> void:
	# la promenade et le quai
	_p("pr1", -166.0, 21.0); _p("pr2", -146.0, 20.2); _p("pr3", -130.0, 20.2); _p("pr4", -112.0, 20.2); _p("pr5", -96.0, 20.2); _p("pr6", -84.0, 21.0)
	_p("q0", -79.0, 5.0); _p("q1", -70.0, 5.0); _p("q2", -55.0, 5.2); _p("q3", -43.0, 5.4); _p("q4", -35.0, 5.4); _p("q5", -27.0, 5.4)
	_p("q6", -13.0, 3.0); _p("q7", 0.0, 5.0); _p("q8", 10.0, 3.0); _p("q9", 20.0, 5.4); _p("q10", 29.0, 5.4); _p("q11", 37.0, 5.4)
	_p("q12", 46.0, 5.6); _p("q13", 56.0, 5.4); _p("q14", 64.0, 5.0)
	_chain(["pr1", "pr2", "pr3", "pr4", "pr5", "pr6", "q0", "q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11", "q12", "q13", "q14"])
	# le môle et l'Hirondelle
	_p("m1", -70.0, -2.0); _p("m2", -69.5, -13.0); _p("m3", -69.5, -24.0)
	_chain(["q1", "m1", "m2", "m3"])
	# les pontons
	_p("pt_b", 24.0, 0.8)
	_link("q9", "pt_b")
	points["pt_b2"] = T(24.0, -6.0, -0.2)
	_link("pt_b", "pt_b2")
	# rue de la Gare, ruelle centrale, rue du Phare
	_p("g1", -35.0, 12.0); _p("g2", -35.0, 25.0); _p("g3", -35.0, 40.0); _p("g4", -35.0, 56.0); _p("g5", -35.0, 70.0); _p("g6", -37.0, 76.5)
	_chain(["q4", "g1", "g2", "g3", "g4", "g5", "g6"])
	_p("a1", 0.0, 12.0); _p("a2", 0.0, 25.0)
	_chain(["q7", "a1", "a2"])
	_p("e1", 37.0, 12.0); _p("e2", 37.0, 25.0); _p("e3", 37.0, 44.0); _p("e4", 37.0, 62.0); _p("e5", 37.0, 76.5)
	_chain(["q11", "e1", "e2", "e3", "e4", "e5"])
	# rue Haute
	_p("h0", -44.0, 25.0); _p("h1", -20.0, 25.5); _p("h2", 20.0, 25.5); _p("h3", 52.0, 25.0); _p("h4", 64.0, 25.0)
	_chain(["h0", "g2", "h1", "a2", "h2", "e2", "h3", "h4"])
	# la place (un anneau autour de la fontaine et ses entrées)
	_p("s1", -14.0, 30.0); _p("s2", 14.0, 30.0); _p("s3", -14.0, 58.0); _p("s4", 14.0, 58.0)
	_p("s5", 0.0, 37.0); _p("s6", 0.0, 51.0); _p("s7", -7.0, 44.0); _p("s8", 7.0, 44.0)
	_p("s9", -17.5, 44.0); _p("s10", 17.5, 44.0); _p("s11", 0.0, 58.5)
	_chain(["s1", "s5", "s2"])
	_chain(["s3", "s6", "s4"])
	_chain(["s1", "s9", "s3"])
	_chain(["s2", "s10", "s4"])
	_chain(["s5", "s7", "s6", "s8", "s5"])
	_link("s6", "s11")
	_link("a2", "s5")
	_link("h1", "s1")
	_link("h2", "s2")
	_link("s9", "s7")
	_link("s10", "s8")
	_link("s3", "s11")
	_link("s4", "s11")
	# rue de derrière (entre la place et les maisons hautes)
	_p("b1", -64.0, 76.5); _p("b2", -50.0, 76.5); _p("b3", -24.0, 76.5); _p("b4", -9.0, 76.5); _p("b5", 6.0, 76.5); _p("b6", 20.0, 76.5); _p("b7", 46.0, 76.5); _p("b8", 59.0, 76.5)
	_chain(["b1", "b2", "g6", "b3", "b4", "b5", "b6", "e5", "b7", "b8"])
	_p("bx1", -16.0, 75.5)
	_link("s3", "bx1")
	_link("bx1", "b3")
	_link("bx1", "b4")
	# devant l'hôtel
	_p("ho1", -77.5, 28.0); _p("ho2", -77.5, 41.0); _p("ho3", -71.0, 41.0); _p("ho4", -61.0, 41.0); _p("ho5", -66.0, 46.0)
	_chain(["pr6", "ho1", "ho2", "ho3", "ho4", "ho5"])
	_link("h0", "ho1")
	# la taverne (porte au milieu de la façade)
	_p("tv0", -13.0, 8.0); _p("tv1", -13.0, 11.6); _p("tv2", -13.0, 15.5)
	_chain(["q6", "tv0", "tv1", "tv2"])
	points["tv1"].y += 0.06
	points["tv2"].y += 0.06
	# le chemin de la pointe et du phare
	_p("ph1", 70.0, 4.0, true); _p("ph2", 80.0, -3.0, true); _p("ph3", 90.0, -12.0, true); _p("ph4", 97.0, -20.5, true)
	_chain(["q14", "ph1", "ph2", "ph3", "ph4"])
	_link("ph2", "jetee_0")
	_chain(["jetee_0", "jetee_1", "jetee_2"])
	# la plage (sable), reliée aux escaliers
	_p("sb1", -158.0, 9.0, true); _p("sb2", -144.0, 9.5, true); _p("sb3", -130.0, 10.0, true); _p("sb4", -116.0, 10.5, true); _p("sb5", -100.0, 9.0, true)
	_chain(["sb1", "sb2", "sb3", "sb4", "sb5"])
	_p("sm1", -158.0, 13.2, true); _p("sm2", -130.0, 13.2, true); _p("sm3", -100.0, 13.2, true)
	_link("sm1", "sb1"); _link("sm2", "sb3"); _link("sm3", "sb5")
	_link("sm1", "pr2"); _link("sm2", "pr3"); _link("sm3", "pr5")
	_p("sw1", -150.0, 2.0, true); _p("sw2", -125.0, 1.0, true); _p("sw3", -104.0, 1.5, true)
	_link("sb2", "sw1"); _link("sb3", "sw2"); _link("sb5", "sw3")
	# le chemin des collines, jusqu'au belvédère
	var lane: Array = ile.lane_world
	var prev: String = "g6"
	var idx: int = 0
	for k in range(0, lane.size(), 8):
		var nm: String = "l%d" % idx
		points[nm] = (lane[k] as Vector3) + Vector3.UP * 0.05
		_link(prev, nm)
		prev = nm
		idx += 1
	points["l_fin"] = ile.summit_world + Vector3.UP * 0.05
	_link(prev, "l_fin")
	# les villas : chacune reliée au point du chemin le plus proche
	for i in range(ile.pads_world.size()):
		var door: Vector3 = doors.get("villa_%d" % i, Vector3.INF)
		if door == Vector3.INF:
			continue
		var nm2: String = "villa_%d" % i
		points[nm2] = Vector3(door.x, ile.height(door.x, door.z) + 0.05, door.z)
		_link(nm2, _nearest_point(points[nm2], ["l", "b", "g6"]))
	# portes des maisons de la ville : reliées au nœud de rue le plus proche
	for d in doors:
		if str(d).begins_with("villa_"):
			continue
		var nm3: String = "porte_" + str(d)
		var dp: Vector3 = doors[d]
		dp.y = maxf(ile.height(dp.x, dp.z), Y) + 0.0
		points[nm3] = dp
		if not graph.has(nm3):
			_link(nm3, _nearest_point(dp, []))
	# chaque lieu d'activité est relié au point le plus proche
	for s in spots:
		var nm4: String = "@" + str(s)
		points[nm4] = spots[s]["pos"]
		var near: String = _nearest_point(spots[s]["pos"], [], true)
		_link(nm4, near)
		spots[s]["node"] = nm4
	_fix_links()


func _nearest_point(p: Vector3, prefixes: Array, skip_spots: bool = true) -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		var ks: String = str(k)
		if skip_spots and ks.begins_with("@"):
			continue
		if ks.begins_with("porte_") or ks.begins_with("villa_"):
			continue
		if not prefixes.is_empty():
			var ok: bool = false
			for pf in prefixes:
				if ks.begins_with(str(pf)):
					ok = true
			if not ok:
				continue
		var d: float = (points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = ks
	return best


## Quelques liaisons à la main là où le « plus proche » passerait à travers un mur.
func _fix_links() -> void:
	var fixes := {
		"@tav_comptoir": "tv2", "@tav_bar_1": "tv2", "@tav_bar_2": "tv2", "@tav_bar_3": "tv2", "@tav_bar_4": "tv2",
		"@tav_table_1": "tv2", "@tav_table_2": "tv2", "@tav_table_3": "tv2", "@tav_scene": "tv2", "@tav_service": "tv2",
		"@hotel_reception": "ho4", "@hotel_salon_1": "ho3", "@hotel_salon_2": "ho3", "@hotel_couloir": "ho5",
		"@poissonnerie": "q3", "porte_taverne": "tv0", "porte_hotel": "ho2",
	}
	for a in fixes:
		if not graph.has(a):
			continue
		for nb in (graph[a] as Array).duplicate():
			(graph[nb] as Array).erase(a)
		graph[a] = []
		_link(a, str(fixes[a]))


# =================================================================== vie : horloge, phare, bateaux

func _process(delta: float) -> void:
	_clock += delta
	var t: Node = main.get("temps_v56") if main != null else null
	if t != null:
		var h: float = float(t.hour)
		# l'horloge est arrêtée sur 10 h 14 tant qu'Hortense n'a pas son rouage
		var j: Node = main.get("journal_v56")
		if j != null and not bool(j.flags.get("horloge", false)):
			h = 10.0 + 14.0 / 60.0
		for hands in clock_hands:
			(hands[0] as Node3D).rotation.z = -fmod(h, 12.0) / 12.0 * TAU
			(hands[1] as Node3D).rotation.z = -fmod(h, 1.0) * TAU
		if lighthouse_head != null:
			lighthouse_head.rotation.y += delta * 0.6
			var bm: StandardMaterial3D = lighthouse_head.get_meta("beam_mat")
			bm.albedo_color.a = 0.07 if bool(t.lamps_on) else 0.0
	for b in boats:
		var n: Node3D = b[0]
		var ph: float = float(b[1])
		n.position.y = float(b[2]) + sin(_clock * 0.9 + ph) * 0.05
		n.rotation.z = sin(_clock * 0.7 + ph) * 0.025
		n.rotation.x = sin(_clock * 0.55 + ph * 1.3) * 0.015

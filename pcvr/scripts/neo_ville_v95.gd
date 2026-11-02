extends Node3D
## V95 : la vie de Néopolis. Les rues (un graphe de points le long des trottoirs de tout le quadrillage,
## les passages piétons aux croisements), les portes des habitants (au pied des immeubles), les lieux
## où l'on s'installe (les bancs de la Place des Hologrammes, les tables et les étals du Marché de Nuit,
## l'atelier de Kenji dans les Ruelles, l'étal de Monsieur Fil, l'accueil de la Tour Axiome, les bornes
## de l'Arcade, la piste de danse de Kira au milieu du Boulevard, le Jardin Zen, les bancs du quai, les
## stations du monorail…), les habitants (pnj/neo_habitants_v95.gd, pnj/pnj_neo_v95.gd), qui vivent selon
## l'heure, et les passants (des humains, des « modifiés », des androïdes : pnj/maisons_habitants_v81.gd,
## pnj/figurant_v81.gd), le jour sur les bancs et aux stations, le soir au marché et autour de Kira.
## Le gestionnaire des lieux (hour, spot, spot_free, claim_spot, release_spot) : comme les autres villes.

const IleScript = preload("res://scripts/ile_neo_v94.gd")
const Kit = preload("res://scripts/neo_kit_v94.gd")
const HABITANTS := "res://scripts/pnj/neo_habitants_v95.gd"
const PNJ := "res://scripts/pnj/pnj_neo_v95.gd"
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")

## Les portes des habitants (au pied d'un immeuble, repère île)
const PORTES := {
	"porte_mamie_kiku": Vector2(-66.6, 30.0), "porte_hiro": Vector2(-66.6, 42.0), "porte_kenji": Vector2(-66.6, 104.0),
	"porte_fil": Vector2(-126.6, 20.0), "porte_zero": Vector2(-66.6, -30.0), "porte_yuna": Vector2(66.6, -90.0),
	"porte_kira": Vector2(66.6, 80.0), "porte_turbo": Vector2(9.1, 150.0), "porte_glitch": Vector2(-126.6, 90.0),
	"porte_ishi": Vector2(113.4, 150.0), "porte_aiko": Vector2(150.0, 113.4), "porte_cargo": Vector2(-20.0, -231.0),
}
## Le tour de ville : le trottoir extérieur est un peu plus loin (les piliers des stations, les réverbères)
const ANNEAU_EXT: float = 186.5

var main: Node
var N: Node3D                              # neo_v94 (l'île, la ville)
var points: Dictionary = {}                # nom -> Vector3 (monde)
var graph: Dictionary = {}                 # nom -> [voisins]
var spots: Dictionary = {}                 # nom -> {pos, face, pose, node}
var habitants: Array = []
var by_id: Dictionary = {}
var crowd: Array = []                      # [figurant, heure de début, heure de fin, position]
var _claims: Dictionary = {}
var _streets: Array = []
var _crowd_t: float = 0.0
var _crowd_spawned: bool = false


func setup(main_node: Node, neo: Node3D) -> void:
	main = main_node
	N = neo
	name = "Neo_ville_v95"


func G(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = N.ile.height(w.x, w.z)
	return w


# =================================================================== construction

func build() -> void:
	var t0: int = Time.get_ticks_msec()
	_rues()
	_portes()
	_lieux()
	_decor()
	print("ILE_MANGA_V95: Néopolis : %d points, %d lieux, %d portes (%d ms)" % [points.size(), spots.size(), PORTES.size(), Time.get_ticks_msec() - t0])


func _key(x: float, z: float) -> String:
	return "st_%d_%d" % [int(round(x * 10.0)), int(round(z * 10.0))]


func _pt(nm: String, p: Vector3) -> String:
	points[nm] = p
	if nm.begins_with("st_"):
		_streets.append(nm)
	return nm


func _link(a: String, b: String) -> void:
	if a == b or not points.has(a) or not points.has(b):
		return
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


## Les lignes des trottoirs : de chaque côté de chaque rue (au bord de la chaussée), et le tour de ville
static func lignes() -> Array:
	var out: Array = []
	for k in range(-3, 4):
		var o: float = IleScript.largeur(k).x + 0.75
		for s in [-1.0, 1.0]:
			var c: float = k * IleScript.PAS + s * o
			if absf(k) == 3 and s * k > 0:
				c = signf(k) * ANNEAU_EXT
			out.append(c)
	out.sort()
	return out


## Un graphe en grille : un point à chaque croisement de deux lignes, d'autres tous les 12 m au plus
## entre deux croisements ; les passages piétons sont les morceaux de ligne qui traversent une rue.
func _rues() -> void:
	var C: Array = lignes()
	for vertical in [true, false]:
		for c in C:
			var prev: String = ""
			for i in range(C.size()):
				var a: float = float(C[i])
				var stops: Array = [a]
				if i < C.size() - 1:
					var b: float = float(C[i + 1])
					var n: int = maxi(int(ceil((b - a) / 12.0)), 1)
					for k in range(1, n):
						stops.append(lerpf(a, b, float(k) / n))
				for u in stops:
					var x: float = float(c) if vertical else float(u)
					var z: float = float(u) if vertical else float(c)
					var nm: String = _key(x, z)
					if not points.has(nm):
						_pt(nm, G(x, z))
					if prev != "":
						_link(prev, nm)
					prev = nm


func nearest_street(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for s in _streets:
		var d: float = (points[s] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(s)
	return best


func _portes() -> void:
	for nm in PORTES:
		var q: Vector2 = PORTES[nm]
		_pt(nm, G(q.x, q.y))
		_link(nm, nearest_street(points[nm]))
	# l'accueil de la Tour Axiome (Sept ne rentre jamais chez lui : sa « porte » est son comptoir)
	_pt("porte_sept", N.lobby + Vector3(1.2, 0, 3.65))
	_link("porte_sept", nearest_street(points["porte_sept"]))


## Un lieu (repère île) : vers où l'on regarde, la pose ; dy : hauteur au-dessus du sol ; via : le
## point par lequel on y arrive (sinon le trottoir le plus proche, en ligne droite).
func _spot(nm: String, x: float, z: float, face: Vector3, pose: String, via: String = "") -> void:
	var p: Vector3 = G(x, z)
	var f: Vector3 = Vector3(face.x, 0, face.z).normalized() if face.length() > 0.01 else Vector3(0, 0, 1)
	var node: String = via if via != "" else nearest_street(p)
	if (points[node] as Vector3).distance_to(p) > 2.5:
		var np: String = _pt("lieu_" + nm, p)
		_link(np, node)
		node = np
	spots[nm] = {"pos": p, "face": f, "pose": pose, "node": node}


func _lieux() -> void:
	# --- la Place des Hologrammes : l'émetteur au milieu, huit bancs (tournés vers l'extérieur),
	# quatre cerisiers dans leurs bacs (que Zéro arrose)
	var pc: Vector2 = IleScript.PLACE
	for k in range(4):
		var a: float = TAU * k / 4.0
		var d := Vector2(cos(a), sin(a))
		var p: Vector2 = pc + d * 6.0
		_spot("place_%d" % (k + 1), p.x, p.y, Vector3(-d.x, 0, -d.y), "observer")
	for k2 in range(8):
		var a2: float = TAU * (k2 + 0.5) / 8.0
		var d2 := Vector2(cos(a2), sin(a2))
		var p2: Vector2 = pc + d2 * 12.06
		_spot("place_banc_%d" % (k2 + 1), p2.x, p2.y, Vector3(d2.x, 0, d2.y), "assis")
	for k3 in range(4):
		var a3: float = TAU * k3 / 4.0 + PI * 0.25
		var d3 := Vector2(cos(a3), sin(a3))
		var p3: Vector2 = pc + d3 * 16.6
		_spot("place_arrosage_%d" % (k3 + 1), p3.x, p3.y, Vector3(d3.x, 0, d3.y), "peindre")
	# --- la Tour Axiome : l'accueil (Sept derrière son comptoir), le parvis
	var lob: Vector2 = IleScript.L(N.lobby.x, N.lobby.z)
	_spot("accueil", lob.x + 1.22, lob.y + 3.65, Vector3(-1, 0, 0), "comptoir")
	_spot("parvis_1", lob.x - 0.2, lob.y - 4.8, Vector3(-1, 0, 0.3), "bras_croises")
	_spot("parvis_2", lob.x - 0.2, lob.y + 7.0, Vector3(-1, 0, -0.2), "observer")
	# --- le Marché de Nuit : l'allée des étals, les tables (les tabourets, autour)
	var r: Array = IleScript.block_rect(-1, 0)
	var ax: float = (float(r[0]) + float(r[2])) * 0.5
	var entree: String = _pt("marche_entree", G(ax, float(r[1]) + 1.0))
	_link(entree, nearest_street(points[entree]))
	var allee: String = _pt("marche_allee", G(ax, float(r[1]) + 22.0))
	_link(entree, allee)
	var fond: String = _pt("marche_fond", G(ax, float(r[1]) + 40.0))
	_link(allee, fond)
	_spot("cuisine_hiro", ax - 4.85, float(r[1]) + 4.0 + 3.0 * 4.4 + 1.2, Vector3(-1, 0, 0), "cuisiner", allee)
	for k4 in range(4):
		var cz: float = float(r[1]) + 4.0 + float([1, 2, 6, 7][k4]) * 4.4
		_spot("marche_client_%d" % (k4 + 1), ax + 4.85, cz, Vector3(1, 0, 0), "comptoir", allee if k4 < 2 else fond)
	# les tables : [côté, rang, tabouret] ; la table du thé de Mamie Kiku : à l'ouest, au troisième rang
	var tables: Array = [[-1, 2, 0], [-1, 0, 0], [-1, 1, 2], [1, 0, 0], [1, 1, 0], [1, 2, 2], [1, 3, 0], [-1, 3, 2], [1, 4, 0], [-1, 4, 0],
		[1, 1, 2], [1, 2, 0], [-1, 1, 0]]
	var noms: Array = ["the_kiku", "marche_table_1", "marche_table_2", "marche_table_3", "marche_table_4", "marche_table_5", "marche_table_6",
		"marche_table_7", "marche_table_8", "marche_table_9", "marche_table_10", "marche_table_11", "marche_table_12"]
	for t in range(tables.size()):
		var e: Array = tables[t]
		var tx: float = ax + float(e[0]) * 16.0
		var tz: float = float(r[1]) + 6.0 + float(e[1]) * 8.5
		var sa: float = TAU * float(e[2]) / 4.0 + 0.4
		var sp := Vector2(tx, tz) + Vector2(cos(sa), sin(sa)) * 0.75
		_spot(str(noms[t]), sp.x, sp.y, Vector3(-cos(sa), 0, -sin(sa)), "assis", allee if float(e[1]) < 2.5 else fond)
	# --- l'Arcade du Dragon-Pixel : les deux bornes, côté boulevard
	var ra: Array = IleScript.block_rect(-1, 1)
	var x1: float = float(ra[2])
	var zm: float = (float(ra[1]) + 6.0 + float(ra[3]) - 6.0) * 0.5
	_spot("borne_1", x1 + 2.05, zm - 3.6, Vector3(-1, 0, 0), "comptoir")
	_spot("borne_2", x1 + 2.05, zm + 3.6, Vector3(-1, 0, 0), "comptoir")
	_spot("arcade_public", x1 + 2.6, zm - 6.2, Vector3(-0.6, 0, 0.8), "observer")
	_spot("arcade_public_2", x1 + 2.7, zm + 6.0, Vector3(-0.6, 0, -0.8), "observer")
	# --- la piste de Kira : au milieu du Boulevard (il n'y passe que des voitures qui volent), et son public
	_spot("danse_kira", 0.0, 82.0, Vector3(-1, 0, 0), "danse")
	_spot("danse_public_1", -3.2, 79.4, Vector3(0.75, 0, 0.6), "acclamer")
	_spot("danse_public_2", 3.0, 79.0, Vector3(-0.7, 0, 0.7), "observer")
	_spot("danse_public_3", -2.6, 85.6, Vector3(0.6, 0, -0.8), "acclamer")
	# --- les Ruelles : l'atelier de Kenji (son établi contre le mur), la caisse où Mio s'assoit, Zéro qu'on répare ;
	# l'étal de Monsieur Fil (une table pliante devant un immeuble, face à la grande rue) ; Glitch qui le surveille
	_spot("atelier_kenji", -65.9, 88.0, Vector3(-1, 0, 0), "peindre")
	_spot("atelier_banc", -66.25, 85.35, Vector3(0.35, 0, 1), "assis")
	_spot("atelier_kenji_client", -65.5, 90.6, Vector3(-0.6, 0, -0.8), "debout")
	_spot("bazar_fil", -90.0, 9.05, Vector3(0, 0, -1), "comptoir")
	_spot("ruelle_1", -98.25, 10.6, Vector3(0.9, 0, -0.3), "holo")
	# --- le Jardin Zen : on entre par le nord ; le râteau de Maître Ishi, le chevalet d'Aïko, la fontaine
	var jc := Vector2(150.0, 150.0)
	var jn: String = _pt("jardin_nord", G(jc.x, 128.6))
	_link(jn, nearest_street(points[jn]))
	var jm: String = _pt("jardin_milieu", G(jc.x + 2.0, 140.0))
	_link(jn, jm)
	_spot("jardin_rateau", 160.0, 158.0, Vector3(-1, 0, 0.2), "peindre", jm)
	_spot("jardin_peinture", 140.0, 140.0, Vector3(0, 0, 1), "peindre", jm)
	_spot("jardin_mediter_1", 151.5, 137.6, Vector3(1, 0, 0.3), "mediter", jm)
	_spot("jardin_mediter_2", 146.5, 141.0, Vector3(0.4, 0, 1), "mediter", jm)
	_spot("fontaine", 156.8, 141.5, Vector3(1, 0, 0), "observer", jm)
	# --- le Quai des Drones : les bancs face à la mer, les conteneurs de Cargo, le bord du quai
	var q: int = 1
	for k5 in range(-3, 4):
		if k5 == 0:
			continue
		var bx: float = k5 * 22.0 + 11.0
		_spot("quai_banc_%d" % q, bx, -222.05, Vector3(0, 0, -1), "assis")
		q += 1
	_spot("quai_cargo_1", 45.7, -205.0, Vector3(1, 0, 0), "peindre")
	_spot("quai_cargo_2", -61.6, -207.0, Vector3(-1, 0, 0), "bras_croises")
	_spot("quai_bord", -20.0, -232.6, Vector3(0, 0, -1), "observer")
	_spot("quai_bord_2", -18.6, -232.6, Vector3(-0.2, 0, -1), "debout")
	# --- les stations du monorail : on attend à côté de la borne
	for k6 in range(mini(N._kiosques.size(), 4)):
		var kio: Vector3 = N._kiosques[k6][0]
		var inw: Vector3 = N._kiosques[k6][1]
		var along := Vector3(-inw.z, 0, inw.x)
		var sp2: Vector3 = kio + along * 1.8 + inw * 0.4
		var l2: Vector2 = IleScript.L(sp2.x, sp2.z)
		_spot("station_%d" % k6, l2.x, l2.y, -inw, "holo" if k6 == 2 else "debout")
	# la puce vocale de la quête « La voix de Zéro » : contre le conteneur orange (côté ouest du quai)
	N.objets["puce"] = G(-46.2, -201.4) + Vector3.UP * 0.05


func _decor() -> void:
	var b := Kit.Batch.new()
	# le comptoir de Sept (un pupitre noir, un plateau de verre, un petit écran)
	var ac: Dictionary = spots["accueil"]
	var dp: Vector3 = (ac["pos"] as Vector3) + Vector3(-0.62, 0, 0)
	b.box("metal_noir", Transform3D(Basis(), dp + Vector3.UP * 0.52), Vector3(0.5, 1.04, 1.6))
	b.box("verre_fume", Transform3D(Basis(), dp + Vector3.UP * 1.06), Vector3(0.6, 0.03, 1.7))
	b.box("ecran_bleu", Transform3D(Basis(Vector3.UP, PI * 0.5).rotated(Vector3(0, 0, 1), 0.3), dp + Vector3(0.05, 1.25, 0.4)), Vector3(0.4, 0.26, 0.02))
	b.box("neon_cyan", Transform3D(Basis(), dp + Vector3(-0.26, 0.9, 0)), Vector3(0.02, 0.05, 1.6))
	N._col(Transform3D(Basis(), dp + Vector3.UP * 0.52), Vector3(0.5, 1.04, 1.6))
	# l'atelier de Kenji : l'établi, les outils, des pièces, une tête d'androïde ouverte, la caisse de Mio
	var wb: Vector3 = G(-66.75, 88.0)
	b.box("bois", Transform3D(Basis(), wb + Vector3.UP * 0.45), Vector3(0.5, 0.9, 2.0))
	b.box("metal", Transform3D(Basis(), wb + Vector3.UP * 0.92), Vector3(0.56, 0.04, 2.06))
	b.box("metal_noir", Transform3D(Basis(), wb + Vector3(-0.12, 1.5, 0)), Vector3(0.06, 1.1, 2.0))
	for k in range(5):
		b.box("metal", Transform3D(Basis(), wb + Vector3(-0.06, 1.2 + (k % 3) * 0.3, -0.8 + k * 0.4)), Vector3(0.04, 0.18, 0.03))
	b.blob("peinture_blanche", wb + Vector3(0.05, 1.04, 0.45), Vector3(0.11, 0.13, 0.12), 10)
	b.blob("ecran_bleu", wb + Vector3(0.14, 1.06, 0.45), Vector3(0.03, 0.02, 0.07), 6)
	b.cyl_at("metal", wb + Vector3(0.05, 0.94, -0.5), 0.06, 0.06, 0.08, 10)
	b.box("plastique_rouge", Transform3D(Basis(Vector3.UP, 0.4), wb + Vector3(0.08, 0.98, -0.1)), Vector3(0.18, 0.1, 0.3))
	N._col(Transform3D(Basis(), wb + Vector3.UP * 0.45), Vector3(0.5, 0.9, 2.0))
	var cr: Vector3 = G(-66.45, 85.25)
	b.box("bois", Transform3D(Basis(Vector3.UP, 0.15), cr + Vector3.UP * 0.22), Vector3(0.5, 0.44, 0.5))
	N._light(wb + Vector3(0.6, 2.4, 0), Color(1.0, 0.75, 0.45), 2.2, 7.0)
	# l'étal de Monsieur Fil : une table pliante, des boîtes de programmes, un écran qui clignote
	var ft: Vector3 = G(-90.0, 8.15)
	b.box("plastique_noir", Transform3D(Basis(), ft + Vector3.UP * 0.86), Vector3(1.5, 0.04, 0.55))
	for sx in [-0.65, 0.65]:
		b.tube("metal", ft + Vector3(sx, 0, 0), ft + Vector3(sx, 0.86, 0), 0.015, 4)
	var boites: Array = ["plastique_rouge", "plastique_bleu", "neon_rose", "peinture_jaune", "plastique_bleu", "neon_violet"]
	for k2 in range(6):
		b.box(str(boites[k2]), Transform3D(Basis(Vector3.UP, 0.1 * (k2 - 3)), ft + Vector3(-0.6 + k2 * 0.24, 0.94, 0.05 * (k2 % 2))), Vector3(0.16, 0.12, 0.2))
	b.box("ecran_bleu", Transform3D(Basis(Vector3.UP, PI).rotated(Vector3.RIGHT, -0.2), ft + Vector3(0.45, 1.18, 0.18)), Vector3(0.42, 0.28, 0.02))
	N._col(Transform3D(Basis(), ft + Vector3.UP * 0.45), Vector3(1.5, 0.9, 0.55))
	var lb := Label3D.new()
	lb.text = "PROGRAMMES\npas chers !"
	lb.font_size = 48
	lb.pixel_size = 0.008
	lb.modulate = Color(0.85, 0.45, 1.0)
	lb.outline_size = 8
	lb.outline_modulate = Color(0.15, 0.0, 0.25)
	add_child(lb)
	lb.global_position = ft + Vector3(0, 1.75, 0.45)
	lb.global_rotation = Vector3(0, PI, 0)
	N._light(ft + Vector3(0, 2.2, -0.4), Color(0.8, 0.35, 1.0), 1.6, 6.0)
	# la table du thé de Mamie Kiku : une théière, des tasses, une lanterne
	var tk: Dictionary = spots["the_kiku"]
	var tc: Vector3 = (tk["pos"] as Vector3) + (tk["face"] as Vector3) * 0.75
	b.blob("peinture_blanche", tc + Vector3(0, 0.86, 0), Vector3(0.1, 0.08, 0.1), 10)
	b.tube("peinture_blanche", tc + Vector3(0.07, 0.86, 0), tc + Vector3(0.16, 0.92, 0), 0.012, 6)
	b.tube("metal_noir", tc + Vector3(-0.06, 0.94, 0), tc + Vector3(0.06, 0.94, 0), 0.008, 4)
	for k3 in range(3):
		var ca: float = TAU * k3 / 3.0 + 0.6
		b.cyl_at("peinture_blanche", tc + Vector3(cos(ca) * 0.26, 0.78, sin(ca) * 0.26), 0.035, 0.028, 0.05, 10)
	b.cyl_at("lampe_chaude", tc + Vector3(-0.2, 0.78, 0.18), 0.06, 0.06, 0.16, 10)
	var lt := Label3D.new()
	lt.text = "THÉ"
	lt.font_size = 64
	lt.pixel_size = 0.01
	lt.modulate = Color(1.0, 0.55, 0.75)
	lt.outline_size = 8
	lt.outline_modulate = Color(0.3, 0.0, 0.1)
	lt.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(lt)
	lt.global_position = tc + Vector3(0, 2.4, 0)
	# le chevalet d'Aïko (une toile : des cerisiers roses sur un ciel bleu nuit)
	var ch: Dictionary = spots["jardin_peinture"]
	var cp: Vector3 = (ch["pos"] as Vector3) + (ch["face"] as Vector3) * 0.75
	for e in [[-0.3, -0.12], [0.3, -0.12], [0.0, 0.25]]:
		b.tube("bois_clair", cp + Vector3(float(e[0]), 0, float(e[1])), cp + Vector3(0, 1.55, 0.02), 0.015, 4)
	b.box("peinture_blanche", Transform3D(Basis(Vector3.RIGHT, -0.12), cp + Vector3(0, 1.2, -0.05)), Vector3(0.62, 0.46, 0.02))
	b.box("neon_violet", Transform3D(Basis(Vector3.RIGHT, -0.12), cp + Vector3(0, 1.26, -0.062)), Vector3(0.56, 0.24, 0.005))
	b.blob("neon_rose", cp + Vector3(-0.12, 1.12, -0.064), Vector3(0.1, 0.06, 0.004), 6)
	b.blob("neon_rose", cp + Vector3(0.1, 1.15, -0.064), Vector3(0.08, 0.05, 0.004), 6)
	# la petite boîte où Cargo a rangé la puce vocale
	b.box("plastique_noir", Transform3D(Basis(Vector3.UP, 0.2), G(-46.25, -200.9) + Vector3.UP * 0.12), Vector3(0.3, 0.24, 0.24))
	b.commit(self, "Neo_vie_decor")


# =================================================================== les habitants

func spawn_npcs() -> void:
	if not habitants.is_empty() or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if points.has(home) else str(_streets[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V95: %d habitants à Néopolis" % habitants.size())


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func spot(nm: String) -> Dictionary:
	return spots.get(nm, {})


func spot_free(nm: String, who: Node) -> bool:
	var c: Variant = _claims.get(nm, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(nm: String, who: Node) -> void:
	_claims[nm] = who


func release_spot(nm: String, who: Node) -> void:
	if _claims.get(nm, null) == who:
		_claims.erase(nm)


# =================================================================== les passants

## [style, rôle, lieu, pose, début, fin, phrases]
const PASSANTS := [
	["neo", "femme", "place_banc_2", "assis", 8.0, 19.0, ["Les carpes changent de couleur toutes les dix minutes. J'ai chronométré.", "J'adore cette place. Il y a de l'ombre, des fleurs, et du réseau."]],
	["neo_android", "homme", "place_banc_6", "assis", 8.0, 21.0, ["Je fais une pause. Les androïdes ont droit aux pauses, depuis la loi de la mairesse.", "Bonjour. Belle journée, statistiquement."]],
	["neo", "vieux", "place_banc_4", "assis", 7.0, 18.0, ["De mon temps, les voitures roulaient par terre. Si, si.", "Hm ? Ah, c'est toi qu'on appelle le voyageur ?"]],
	["neo", "homme", "marche_table_10", "manger", 11.0, 14.0, ["Les nouilles de Hiro… ou de Gaston. Peu importe : elles sont parfaites.", "Chaud, chaud, chaud !"]],
	["neo", "femme", "marche_table_11", "manger", 18.0, 2.0, ["Le Marché de Nuit, c'est mon rituel. Un bol, un thé, et au lit.", "Tu as goûté le thé de Mamie Kiku ? Il réchauffe jusqu'aux orteils."]],
	["neo_android", "femme", "marche_table_12", "assis", 18.0, 2.0, ["Je ne mange pas. Je viens pour l'odeur du gingembre. Elle est très bien notée.", "Bonsoir. Mon voisin humain trouve que je suis de bonne compagnie."]],
	["neo", "garcon", "marche_client_3", "comptoir", 17.0, 22.0, ["Un bol de nouilles, s'il vous plaît ! Avec un smiley !", "Gaston m'a fait un smiley qui tire la langue !"]],
	["neo", "femme", "marche_client_4", "comptoir", 18.0, 1.0, ["Deux brochettes, et une pour le chemin.", "Ça sent trop bon, ici."]],
	["neo", "fille", "danse_public_2", "applaudir", 20.0, 1.0, ["Kira ! Kira ! Encore le tour qui brille !", "Quand je serai grande, j'aurai des circuits roses, comme elle."]],
	["neo_android", "garcon", "danse_public_3", "danse", 20.0, 1.0, ["J'apprends à danser en observant Kira. Progression : quatre pour cent.", "Mes moteurs ne sont pas faits pour ça. Je continue quand même."]],
	["neo", "homme", "station_3", "mains_dos", 7.0, 22.0, ["Le prochain monorail arrive dans… maintenant. Non. Maintenant.", "Je vais travailler dans les Hauts. Quatre-vingt-dixième étage. J'ai le vertige."]],
	["neo_android", "vieux", "station_1", "mains_dos", 6.0, 24.0, ["Je suis un vieux modèle. On m'a oublié à cette station il y a six ans. J'attends qu'on vienne me chercher. Je ne suis pas pressé.", "Bip. Pardon. Vieille habitude."]],
	["neo", "homme", "arcade_public_2", "mains_dos", 10.0, 21.0, ["Turbo joue. Personne ne parle. C'est la règle.", "Il va battre son record… Non… Si… NON !"]],
	["neo", "vieille", "quai_banc_1", "assis", 9.0, 18.0, ["Je viens regarder les bateaux. Et Cargo. Il est si doux, ce grand garçon.", "Les mouettes volent les frites, ici. Garde ton goûter."]],
	["neo", "homme", "bazar_fil_client", "comptoir", 15.0, 1.0, ["Un programme pour que mon frigo me dise bonjour… Pas cher… Hm.", "Glitch dit que c'est une mauvaise idée. Mais c'est presque gratuit…"]],
]


func _spawn_crowd() -> void:
	_crowd_spawned = true
	if not spots.has("bazar_fil_client"):
		_spot("bazar_fil_client", -89.3, 7.15, Vector3(0, 0, 1), "comptoir")
	var rng := RandomNumberGenerator.new()
	rng.seed = 95000
	var n: int = PASSANTS.size() if bool(N.get("pc")) else 9
	for i in range(n):
		var e: Array = PASSANTS[i]
		var sp: Dictionary = spots.get(str(e[2]), {})
		if sp.is_empty():
			continue
		var prof: Dictionary = Gens.pick(str(e[0]), str(e[1]), rng)
		if prof.is_empty():
			continue
		prof["nom"] = Gens.prenom(str(e[0]), str(e[1]), rng)
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(e[3]))
		if f == null:
			continue
		f.set("lines", e[6])
		claim_spot(str(e[2]), f)
		crowd.append([f, float(e[4]), float(e[5]), sp["pos"]])
	_crowd_vis(true)


static func _in_hours(h: float, a: float, b: float) -> bool:
	return (a <= b and h >= a and h < b) or (a > b and (h >= a or h < b))


func _crowd_vis(force: bool = false) -> void:
	var p: Vector3 = main._player_pos_v27()
	var h: float = hour()
	for c in crowd:
		var f: Node = c[0]
		if not is_instance_valid(f):
			continue
		var npc: Node3D = f.get("npc")
		if npc == null:
			continue
		var want: bool = _in_hours(h, float(c[1]), float(c[2])) and (c[3] as Vector3).distance_to(p) < 240.0
		if want != npc.visible or force:
			npc.visible = want
			f.process_mode = Node.PROCESS_MODE_INHERIT if want else Node.PROCESS_MODE_DISABLED
			for k in npc.get_children():
				if k is PhysicsBody3D:
					for cs in k.get_children():
						if cs is CollisionShape3D:
							(cs as CollisionShape3D).disabled = not want


func crowd_visible() -> int:
	var n: int = 0
	for c in crowd:
		if is_instance_valid(c[0]) and (c[0] as Node).get("npc") != null and ((c[0] as Node).get("npc") as Node3D).visible:
			n += 1
	return n


func _process(delta: float) -> void:
	if main == null or N == null:
		return
	_crowd_t -= delta
	if _crowd_t > 0.0:
		return
	_crowd_t = 1.5
	var p: Vector3 = main._player_pos_v27()
	if not _crowd_spawned:
		if Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length() < 420.0 and bool(main.get("game_started")):
			_spawn_crowd()
		return
	_crowd_vis()

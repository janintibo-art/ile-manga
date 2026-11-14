extends RefCounted
## V146 : le bourg de Pile-ou-Face, au milieu de l'Île Perchée. La grand-rue (la rue de la Mise, d'ouest en
## est), coupée par la rue du Pique (du nord au sud) sur la place de la Roue ; les saloons, les tripots,
## les boutiques, la banque, le bureau du shérif et son vieux donjon, l'hôtel, la poste, la forge, la
## chapelle, le château d'eau, l'éolienne, les maisons. Repère : celui de l'île (+X à l'est, +Z au sud).
##
## build(M) : M est le module (perchee_v146) ; il garde ce qui bouge (M.tournants), les lampes
## (M.lampes), les portes (M.portes : les maisons où l'on entre, les lieux du jeu), les étals.

const Kit = preload("res://scripts/perchee_kit_v146.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const Ile = preload("res://scripts/ile_perchee_v146.gd")
const AzurKit = preload("res://scripts/azur_kit_v56.gd")

const FACADE: float = 10.6               # la façade est à 10,6 m de l'axe de la grand-rue
const FACADE_PIQUE: float = 9.1          # et à 9,1 m de l'axe de la rue du Pique

## Les bâtiments : [id, côté (« n », « s » de la grand-rue ; « po », « pe » : rue du Pique, côté ouest
## ou est), position le long de la rue, spec]. « lieu » : un lieu du jeu (les tables de jeu y viendront) ;
## « maison » : une maison où l'on entre (maisons_v81).
const BATIMENTS := [
	["barbier", "n", -30.0, {"w": 11.0, "d": 13.0, "mur": "bardage_bleu", "fronton": "droit", "enseigne": "BARBIER\nLE COUPE-CHOU", "porte": "simple", "vitrine": true, "vapeur": ["tuyaux"], "lieu": "barbier"}],
	["bazar", "n", -15.0, {"w": 14.0, "d": 14.0, "etages": 2, "mur": "clins_jaune", "haut": "clins_jaune", "fronton": "gradins", "enseigne": "BAZAR DE LA VEUVE CLOU", "vitrine": true, "vapeur": ["cheminee"], "lieu": "bazar"}],
	["banque", "n", 3.0, {"w": 13.0, "d": 15.0, "etages": 2, "vieux": true, "mur": "moellons", "haut": "pierre", "fronton": "droit", "toit": "tuiles", "enseigne": "BANQUE DE L'ÉCU PERCHÉ", "porte": "arche", "porche": false, "vapeur": ["horloge", "rivets"], "enseigne_fond": "enseigne_verte", "lieu": "banque"}],
	["saloon", "n", 26.0, {"w": 20.0, "d": 18.0, "etages": 2, "mur": "bardage_rouge", "haut": "clins_creme", "fronton": "arrondi", "balcon": true, "enseigne": "SALOON DU CHIEN QUI MISE", "porte": "battantes", "vapeur": ["rouage", "cheminee", "tuyaux"], "enseigne_fond": "enseigne_creme", "lieu": "saloon"}],
	["forge", "s", -30.0, {"w": 12.0, "d": 14.0, "mur": "brique", "fronton": "droit", "enseigne": "FORGE DU MARTEAU-PILON", "porte": "double", "vapeur": ["cheminee", "tuyaux", "rouage", "rivets"], "lieu": "forge"}],
	["poste", "s", -15.0, {"w": 10.0, "d": 12.0, "mur": "clins_vert", "fronton": "gradins", "enseigne": "POSTE\n& TÉLÉGRAPHE", "porte": "double", "lieu": "poste"}],
	["hotel", "s", 4.0, {"w": 18.0, "d": 16.0, "etages": 3, "mur": "clins_creme", "haut": "clins_bleu", "fronton": "droit", "balcon": true, "enseigne": "HÔTEL DES NUAGES", "porte": "double", "vapeur": ["horloge", "cheminee"], "lieu": "hotel"}],
	["fosse", "s", 27.0, {"w": 16.0, "d": 16.0, "mur": "bardage_brun", "fronton": "gradins", "enseigne": "LA FOSSE AUX DÉS", "porte": "battantes", "vapeur": ["rivets", "tuyaux"], "enseigne_fond": "enseigne_rouge", "lieu": "fosse"}],
	["tripot", "n", 95.0, {"w": 18.0, "d": 17.0, "etages": 2, "mur": "bardage_vert", "haut": "clins_creme", "fronton": "arrondi", "balcon": true, "enseigne": "TRIPOT DE LA DAME DE PIQUE", "porte": "battantes", "vapeur": ["rouage", "horloge"], "enseigne_fond": "enseigne_fond", "lieu": "tripot"}],
	["epicerie", "n", 114.0, {"w": 12.0, "d": 13.0, "mur": "clins_rose", "fronton": "droit", "enseigne": "CLOUS & CONFITURES", "vitrine": true, "porche": false, "auvent": "toile_rouge", "enseigne_fond": "enseigne_creme", "lieu": "epicerie"}],
	["apothicaire", "n", 130.0, {"w": 11.0, "d": 12.0, "mur": "bardage_turquoise", "fronton": "gradins", "enseigne": "APOTHICAIRE\nDOC CORNEMUSE", "vitrine": true, "vapeur": ["tuyaux"], "lieu": "apothicaire"}],
	["sherif", "n", 147.0, {"w": 14.0, "d": 14.0, "vieux": true, "mur": "moellons", "fronton": "droit", "toit": "tuiles", "enseigne": "BUREAU DU SHÉRIF", "porte": "arche", "porche": true, "vapeur": ["rivets"], "lieu": "sherif"}],
	["prospecteurs", "s", 94.0, {"w": 14.0, "d": 14.0, "mur": "adobe", "fronton": "gradins", "enseigne": "COMPTOIR DES PROSPECTEURS", "porte": "double", "vapeur": ["tuyaux", "rouage"], "enseigne_fond": "enseigne_rouge", "lieu": "prospecteurs"}],
	["chapelier", "s", 111.0, {"w": 12.0, "d": 12.0, "mur": "clins_creme", "fronton": "arrondi", "enseigne": "AU CHAPEAU POINTU", "vitrine": true, "porche": false, "auvent": "toile_verte", "lieu": "chapelier"}],
	["sellerie", "s", 127.0, {"w": 12.0, "d": 13.0, "mur": "bardage_brut", "fronton": "droit", "enseigne": "SELLERIE DES ÉPERONS", "porte": "double", "vapeur": ["cheminee"], "lieu": "sellerie"}],
	["ecurie", "s", 147.0, {"w": 18.0, "d": 16.0, "mur": "bardage_rouge", "fronton": "aucun", "toit": "bardeaux", "enseigne": "ÉCURIE DU GRAND GALOP", "porte": "double", "porche": false, "lieu": "ecurie"}],
	["pension", "po", -36.0, {"w": 12.0, "d": 12.0, "etages": 2, "mur": "clins_rose", "fronton": "droit", "enseigne": "PENSION ROSALIE", "porte": "double", "maison": true}],
	["m_po_1", "po", -54.0, {"w": 11.0, "d": 11.0, "mur": "clins_bleu", "fronton": "aucun", "toit": "bardeaux", "porte": "simple", "porche": true, "maison": true}],
	["m_po_2", "po", -71.0, {"w": 10.0, "d": 10.0, "etages": 2, "mur": "clins_brut", "fronton": "aucun", "porte": "simple", "porche": false, "maison": true}],
	["horloger", "pe", -36.0, {"w": 13.0, "d": 12.0, "etages": 2, "mur": "brique", "haut": "rivets", "fronton": "gradins", "enseigne": "HORLOGERIE\nTIC & TAC", "porte": "double", "vitrine": true, "vapeur": ["rouage", "horloge", "tuyaux", "cheminee"], "lieu": "horloger"}],
	["m_pe_1", "pe", -54.0, {"w": 11.0, "d": 11.0, "mur": "clins_vert", "fronton": "aucun", "toit": "tole", "porte": "simple", "porche": true, "maison": true}],
	["m_pe_2", "pe", -71.0, {"w": 10.0, "d": 10.0, "mur": "adobe", "fronton": "droit", "porte": "simple", "porche": false, "maison": true}],
	["m_ps_1", "po", 34.0, {"w": 11.0, "d": 11.0, "mur": "clins_jaune", "fronton": "aucun", "toit": "bardeaux", "porte": "simple", "porche": true, "maison": true}],
	["m_ps_2", "po", 52.0, {"w": 11.0, "d": 10.0, "etages": 2, "mur": "clins_gris", "fronton": "aucun", "porte": "simple", "porche": false, "maison": true, "vapeur": ["cheminee"]}],
	["m_ps_3", "po", 69.0, {"w": 10.0, "d": 10.0, "mur": "bardage_brun", "fronton": "droit", "porte": "simple", "porche": true, "maison": true}],
	["theatre", "pe", 36.0, {"w": 15.0, "d": 16.0, "etages": 2, "mur": "stuc_rouge", "haut": "stuc_rouge", "fronton": "arrondi", "enseigne": "THÉÂTRE DES MIRAGES", "porte": "double", "vapeur": ["rouage", "horloge"], "enseigne_fond": "enseigne_creme", "lieu": "theatre"}],
	["m_pse_1", "pe", 55.0, {"w": 11.0, "d": 11.0, "mur": "clins_turquoise", "fronton": "aucun", "toit": "tole", "porte": "simple", "porche": true, "maison": true}],
	["m_pse_2", "pe", 71.0, {"w": 10.0, "d": 10.0, "mur": "adobe", "fronton": "droit", "porte": "simple", "porche": false, "maison": true, "vapeur": ["tuyaux"]}],
]


## Le repère d'un bâtiment (au pied de sa façade, Z vers la rue), en monde.
static func repere(ile, cote: String, pos: float) -> Transform3D:
	var l: Vector2
	var yaw: float = 0.0
	match cote:
		"n":
			l = Vector2(pos, -FACADE)
			yaw = 0.0
		"s":
			l = Vector2(pos, FACADE)
			yaw = PI
		"po":
			l = Vector2(Ile.PIQUE_X - FACADE_PIQUE, pos)
			yaw = PI * 0.5
		_:
			l = Vector2(Ile.PIQUE_X + FACADE_PIQUE, pos)
			yaw = -PI * 0.5
	var w: Vector3 = Ile.W(l.x, l.y)
	w.y = ile.height(w.x, w.z)
	return Transform3D(Basis(Vector3.UP, yaw), w)


static func build(M) -> void:
	var ile = M.ile
	var rng := RandomNumberGenerator.new()
	rng.seed = 14646
	var root: Node3D = M.bourg_root
	var cols := GK.Cols.new(root, "Perchee_bourg_collisions")
	var nuit: bool = true
	var quartier: int = 0
	for e in BATIMENTS:
		var b := Kit.Lot.new()
		var id: String = str(e[0])
		var s: Dictionary = e[3]
		var xf: Transform3D = repere(ile, str(e[1]), float(e[2]))
		var r: Dictionary = Kit.batiment(b, cols, root, xf, s, rng, nuit)
		var w: float = float(s.get("w", 10.0))
		Kit.trottoir(b, cols, xf.translated_local(Vector3(0, 0, 0)), w + 0.6, 3.1, [float(s.get("porte_x", 0.0))])
		# un peu de vie sur le trottoir
		for k in range(rng.randi_range(1, 3)):
			var px: float = rng.randf_range(-w * 0.45, w * 0.45)
			if absf(px) < 1.8:
				continue
			var at: Vector3 = xf * Vector3(px, 0.35, rng.randf_range(0.5, 1.2))
			match rng.randi() % 4:
				0:
					Kit.tonneau(b, cols, at)
				1:
					Kit.caisse(b, cols, at, rng.randf_range(0.6, 0.9), rng.randf() * TAU)
				2:
					Kit.pot_cactus(b, at, rng)
				_:
					Kit.tonneau(b, cols, at + (xf.basis * Vector3(0.0, 0, 0.6)), true, xf.basis.get_euler().y + PI * 0.5)
		b.commit(root, "Perchee_bat_" + id, true, 260.0)
		for g in r["rouages"]:
			M.tournants.append([g, Vector3(0, 0, 1), float(g.get_meta("vitesse"))])
		for c in r["cheminees"]:
			M.cheminees.append(c)
		for lp in r["lampes"]:
			M.lampes.append(lp)
		M.portes.append({"id": id, "porte": r["porte"], "out": r["out"], "seuil": r["seuil"], "lieu": str(s.get("lieu", "")), "maison": bool(s.get("maison", false)),
			"w": w, "d": float(s.get("d", 12.0)), "etages": int(s.get("etages", 1)), "nom": str(s.get("enseigne", "")).replace("\n", " ")})
		# les maisons où l'on entre (maisons_v81 : une histoire par maison)
		if bool(s.get("maison", false)):
			AzurKit.PORTES_V81.append({"door": r["porte"], "out": r["out"], "w": minf(w - 2.5, 8.0), "d": minf(float(s.get("d", 12.0)) - 3.0, 7.0),
				"style": "perchee", "floors": int(s.get("etages", 1)), "owner": ""})
		quartier += 1
	_rue(M, cols, rng)
	_place(M, cols, rng)
	_chapelle(M, cols)
	_donjon(M, cols)
	_chateau_eau(M, cols)
	_eolienne(M, cols)
	_corral(M, cols, rng)


## La rue : les réverbères, les barres d'attache, les abreuvoirs, les chariots, les poteaux du
## télégraphe jusqu'au Quai des Nuées, les panneaux indicateurs.
static func _rue(M, cols: GK.Cols, rng: RandomNumberGenerator) -> void:
	var ile = M.ile
	var b := Kit.Lot.new()
	var root: Node3D = M.bourg_root
	var sol := func(x: float, z: float) -> Vector3:
		var w: Vector3 = Ile.W(x, z)
		w.y = ile.height(w.x, w.z)
		return w
	# les réverbères, en quinconce
	var xs: Array = [-34.0, -10.0, 14.0, 36.0, 86.0, 108.0, 132.0, 156.0]
	for i in range(xs.size()):
		var z: float = 6.4 if i % 2 == 0 else -6.4
		M.lampes.append(Kit.reverbere(b, cols, sol.call(xs[i], z)))
		M.lampes_rue.append(M.lampes[M.lampes.size() - 1])
	for j in range(4):
		var zz: float = -30.0 - j * 20.0 if j < 2 else 30.0 + (j - 2) * 20.0
		M.lampes.append(Kit.reverbere(b, cols, sol.call(Ile.PIQUE_X + (5.0 if j % 2 == 0 else -5.0), zz)))
	# les barres d'attache devant les saloons et les tripots
	for e in [[22.0, -6.3], [32.0, -6.3], [24.0, 6.3], [91.0, -6.3], [100.0, -6.3], [147.0, 6.3]]:
		Kit.barre_attache(b, cols, Transform3D(Basis(), sol.call(e[0], e[1])), 3.4)
	Kit.abreuvoir(b, cols, sol.call(13.0, -6.0), 0.0)
	Kit.abreuvoir(b, cols, sol.call(122.0, 6.0), PI)
	Kit.chariot(b, cols, sol.call(-2.0, 5.6), PI * 0.5 + 0.05)
	Kit.chariot(b, cols, sol.call(138.0, -5.4), -PI * 0.5 + 0.1, false)
	Kit.chariot(b, cols, sol.call(170.0, 18.0), 1.2)
	# des tonneaux et des caisses dans les ruelles
	for k in range(14):
		var x: float = rng.randf_range(-36.0, 150.0)
		if absf(x - 60.0) < 24.0:
			continue
		var z2: float = (8.2 + rng.randf() * 0.4) * (1.0 if rng.randf() < 0.5 else -1.0)
		if rng.randf() < 0.5:
			Kit.tonneau(b, cols, sol.call(x, z2 * 0.86))
	# le télégraphe : de la poste au Quai des Nuées
	var prev: Vector3 = Vector3.ZERO
	var x0: float = 162.0
	while x0 < 222.0:
		var top: Vector3 = Kit.poteau(b, sol.call(x0, 9.5), 0.0)
		if prev != Vector3.ZERO:
			for s in [-0.65, 0.65]:
				Kit.fil(b, prev + Vector3(s, 0, 0), top + Vector3(s, 0, 0), 0.5)
		prev = top
		x0 += 24.0
	# les panneaux indicateurs à la sortie du bourg
	var ech := func(at: Vector3, yaw: float, txts: Array) -> void:
		var xf := Transform3D(Basis(Vector3.UP, yaw), at)
		b.cyl("poutre", xf, 0.12, 0.1, 3.4, 8)
		for i2 in range(txts.size()):
			var t: Array = txts[i2]
			var dir: float = float(t[1])
			var pxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, dir), Vector3(0, 2.8 - i2 * 0.55, 0)) * Transform3D(Basis(), Vector3(0.95, 0, 0.12))
			Kit.panneau(b, root, pxf, 1.9, 0.42, str(t[0]), "enseigne_creme")
	ech.call(sol.call(164.0, -9.0), 0.0, [["QUAI DES NUÉES", 0.0], ["LA GRANDE CHAÎNE", -0.9]])
	ech.call(sol.call(-44.0, 9.0), PI, [["LE VIEUX-PIC", 0.2], ["L'ABREUVOIR", -0.6]])
	ech.call(sol.call(66.0, 96.0), PI * 0.5, [["LA GRANDE CHAÎNE", -0.5], ["PILE-OU-FACE", PI * 0.5]])
	b.commit(root, "Perchee_rue", true, 220.0)


## La place de la Roue : la Roue de la Fortune (une grande roue de laiton sur un socle de pierre, qui
## tourne doucement), les bancs, le tableau des annonces, les réverbères.
static func _place(M, cols: GK.Cols, rng: RandomNumberGenerator) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var c: Vector3 = Ile.W(Ile.PLACE.x, Ile.PLACE.y)
	c.y = ile.height(c.x, c.z)
	# le socle : trois marches octogonales
	for k in range(3):
		b.cyl("pierre_taille", Transform3D(Basis(Vector3.UP, PI / 8.0), c + Vector3.UP * (k * 0.35 - 0.6)), 5.2 - k * 0.9, 5.2 - k * 0.9, 0.95, 8)
	cols.cyl(c + Vector3.DOWN * 0.6, 5.0, 1.65)
	var axe: Vector3 = c + Vector3.UP * 6.2
	# les deux montants de fonte, le moyeu
	for s in [-1.0, 1.0]:
		b.tube("fer", c + Vector3(s * 3.2, 1.0, 0.0), axe + Vector3(s * 0.5, 0, 0), 0.22, 8)
		b.tube("fer", c + Vector3(s * 3.2, 1.0, 1.4), axe + Vector3(s * 0.5, 0, 0), 0.16, 8)
		b.tube("fer", c + Vector3(s * 3.2, 1.0, -1.4), axe + Vector3(s * 0.5, 0, 0), 0.16, 8)
		b.blob("laiton", axe + Vector3(s * 0.55, 0, 0), Vector3(0.3, 0.3, 0.3), 8)
	# la flèche (le cliquet) en haut
	b.box("vanne", Transform3D(Basis(), axe + Vector3(0, 4.55, 0.0)), Vector3(0.12, 0.7, 0.3))
	b.prism("vanne", axe + Vector3(-0.06, 4.2, -0.18), axe + Vector3(-0.06, 4.2, 0.18), axe + Vector3(-0.06, 3.85, 0.0), Vector3(0.12, 0, 0))
	b.tube("fer", axe + Vector3(-0.5, 4.9, 0), axe + Vector3(0.5, 4.9, 0), 0.08, 6)
	for s2 in [-1.0, 1.0]:
		b.tube("fer", axe + Vector3(s2 * 0.5, 4.9, 0), axe + Vector3(s2 * 0.5, 0.3, 0), 0.07, 6)
	b.commit(root, "Perchee_place", true, 300.0)
	# la roue (elle tourne autour de X)
	var roue := Node3D.new()
	roue.name = "Roue_de_la_fortune"
	root.add_child(roue)
	roue.global_position = axe
	var rb := Kit.Lot.new()
	var R: float = 3.9
	var n: int = 24
	var couleurs: Array = ["enseigne_rouge", "enseigne_creme", "enseigne_fond", "enseigne_creme", "enseigne_verte", "enseigne_creme"]
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var key: String = couleurs[i % couleurs.size()] if i != 0 else "or"
		for sx in [-0.1, 0.1]:
			var p0 := Vector3(sx, cos(a0) * R, sin(a0) * R)
			var p1 := Vector3(sx, cos(a1) * R, sin(a1) * R)
			var p2 := Vector3(sx, cos(a1) * 0.7, sin(a1) * 0.7)
			var p3 := Vector3(sx, cos(a0) * 0.7, sin(a0) * 0.7)
			rb.quad(key, [p0, p1, p2, p3], Vector3(signf(sx), 0, 0), [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		rb.tube("laiton", Vector3(0, cos(a0) * 0.7, sin(a0) * 0.7), Vector3(0, cos(a0) * R, sin(a0) * R), 0.05, 4)
		# les clous du pourtour (le cliquet y claque)
		rb.tube("laiton", Vector3(0, cos(a0) * (R + 0.05), sin(a0) * (R + 0.05)), Vector3(0, cos(a0) * (R + 0.35), sin(a0) * (R + 0.35)), 0.04, 4)
		rb.tube("laiton", Vector3(0, cos(a0) * R, sin(a0) * R), Vector3(0, cos(a1) * R, sin(a1) * R), 0.12, 6)
	rb.cyl("laiton", Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.4, 0, 0)), 0.75, 0.75, 0.8, 16)
	rb.commit(roue, "Roue_maillage", true, 300.0)
	# les chiffres (des Label3D sur les deux faces)
	for i3 in range(n):
		var a: float = TAU * (i3 + 0.5) / n
		var num: String = ["×2", "1", "5", "2", "10", "3", "★", "4", "1", "8", "2", "6", "×2", "1", "5", "2", "20", "3", "★", "4", "1", "8", "2", "6"][i3]
		for sx2 in [-1.0, 1.0]:
			var l := Label3D.new()
			l.text = num
			l.font = Kit.police()
			l.font_size = 96
			l.pixel_size = 0.006
			l.modulate = Color(0.98, 0.9, 0.6)
			l.outline_size = 8
			l.outline_modulate = Color(0.1, 0.06, 0.03)
			l.double_sided = false
			l.visibility_range_end = 90.0
			roue.add_child(l)
			l.transform = Transform3D(Basis(Vector3.RIGHT, a) * Basis(Vector3.UP, sx2 * PI * 0.5), Vector3(sx2 * 0.13, cos(a) * R * 0.8, sin(a) * R * 0.8))
	M.tournants.append([roue, Vector3(1, 0, 0), 0.12])
	M.roue = roue
	# les bancs et le tableau des annonces, les réverbères autour
	var b2 := Kit.Lot.new()
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + PI / 4.0
		var at: Vector3 = c + Vector3(cos(a2) * 13.5, 0, sin(a2) * 13.5)
		at.y = ile.height(at.x, at.z)
		M.lampes.append(Kit.reverbere(b2, cols, at + Vector3(cos(a2) * 2.2, 0, sin(a2) * 2.2)))
		var bxf := Transform3D(Basis(Vector3.UP, -a2 - PI * 0.5), at)
		for s3 in [-1.0, 1.0]:
			b2.box("fer", bxf * Transform3D(Basis(), Vector3(s3 * 0.8, 0.22, 0)), Vector3(0.06, 0.44, 0.5))
		b2.box("planches", bxf * Transform3D(Basis(), Vector3(0, 0.47, 0)), Vector3(1.8, 0.06, 0.48))
		b2.box("planches", bxf * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.8, -0.24)), Vector3(1.8, 0.4, 0.05))
		cols.box(bxf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.8, 0.6, 0.5))
	var tab: Vector3 = c + Vector3(-8.0, 0, 15.0)
	tab.y = ile.height(tab.x, tab.z)
	var txf := Transform3D(Basis(Vector3.UP, PI + 0.4), tab)
	for s4 in [-1.0, 1.0]:
		b2.box("poutre", txf * Transform3D(Basis(), Vector3(s4 * 1.3, 1.3, 0)), Vector3(0.16, 2.6, 0.16))
	b2.box("planches", txf * Transform3D(Basis(), Vector3(0, 1.75, 0)), Vector3(2.8, 1.6, 0.08))
	b2.prism("tole", txf * Vector3(-1.6, 2.65, -0.4), txf * Vector3(1.6, 2.65, -0.4), txf * Vector3(0, 3.0, -0.4), txf.basis * Vector3(0, 0, 0.8))
	cols.box(txf * Transform3D(Basis(), Vector3(0, 1.4, 0)), Vector3(2.8, 2.8, 0.3))
	Kit.panneau(b2, root, txf * Transform3D(Basis(), Vector3(-0.68, 1.95, 0.06)), 1.2, 0.9, "GRAND\nTOURNOI\nDE DÉS", "enseigne_creme")
	Kit.panneau(b2, root, txf * Transform3D(Basis(), Vector3(0.68, 1.95, 0.06)), 1.2, 0.9, "ON CHERCHE\nUN\nCROUPIER", "enseigne_creme")
	Kit.panneau(b2, root, txf * Transform3D(Basis(), Vector3(0, 1.22, 0.06)), 2.5, 0.42, "PILE-OU-FACE, LA VILLE QUI MISE", "enseigne_fond")
	M.tableau = tab
	b2.commit(root, "Perchee_place_mobilier", true, 200.0)


## La chapelle Notre-Dame-des-Nuées, au bout de la rue du Pique : de la pierre (les fondations
## médiévales), un clocher de bois, une cloche, un vitrail.
static func _chapelle(M, cols: GK.Cols) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var at: Vector3 = Ile.W(Ile.PIQUE_X, -100.0)
	at.y = ile.height(at.x, at.z)
	var xf := Transform3D(Basis(), at)
	var w: float = 11.0
	var d: float = 18.0
	b.box("moellons", xf * Transform3D(Basis(), Vector3(0, 2.6, -d * 0.5)), Vector3(w, 7.0, d))
	b.box("moellons", xf * Transform3D(Basis(), Vector3(0, -0.8, -d * 0.5)), Vector3(w + 0.4, 1.8, d + 0.4))
	cols.box(xf * Transform3D(Basis(), Vector3(0, 3.0, -d * 0.5)), Vector3(w, 7.0, d))
	# le toit à deux pentes (de l'avant vers l'arrière)
	for sx in [-1.0, 1.0]:
		var n: Vector3 = Vector3(sx * 5.0, 6.0, 0).normalized()
		b.quad("bardeaux", [xf * Vector3(sx * (w * 0.5 + 0.5), 6.0, 0.6), xf * Vector3(0, 11.0, 0.6), xf * Vector3(0, 11.0, -d - 0.6), xf * Vector3(sx * (w * 0.5 + 0.5), 6.0, -d - 0.6)], n,
			[Vector2(0, 0), Vector2(0, 7), Vector2(19, 7), Vector2(19, 0)])
	for zz in [0.0, -d]:
		b.prism("moellons", xf * Vector3(-w * 0.5, 6.0, zz), xf * Vector3(w * 0.5, 6.0, zz), xf * Vector3(0, 10.8, zz), Vector3(0, 0, -0.3 if zz == 0.0 else 0.3))
	# la porte en arc, la rosace
	Kit.porte(b, xf * Transform3D(Basis(), Vector3(0, -0.1, 0.02)), "arche", 2.4, 3.4)
	var rxf := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at + Vector3(0, 7.6, 0.18))
	b.cyl("pierre_taille", rxf, 1.4, 1.4, 0.2, 20)
	b.cyl("cristal", rxf.translated_local(Vector3(0, 0.21, 0)), 1.15, 1.15, 0.01, 20)
	for k in range(8):
		var a: float = TAU * k / 8.0
		b.box("fer", Transform3D(Basis(Vector3.BACK, a), at + Vector3(cos(a) * 0.58, 7.6 + sin(a) * 0.58, 0.42)), Vector3(1.15, 0.06, 0.03))
	# le clocher : une tour carrée de bois sur la façade
	var cxf: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0, -3.2))
	b.box("clins_creme", cxf * Transform3D(Basis(), Vector3(0, 12.6, 0)), Vector3(3.4, 3.2, 3.4))
	for s in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		b.box("sombre", cxf * Transform3D(Basis(), Vector3(s[0] * 1.71, 12.8, s[1] * 1.71)), Vector3(1.1 if s[0] == 0 else 0.04, 1.8, 1.1 if s[1] == 0 else 0.04))
	b.cyl("laiton", cxf * Transform3D(Basis(), Vector3(0, 12.3, 0)), 0.65, 0.35, 0.9, 12)
	var coins: Array = [Vector3(2.0, 14.2, 2.0), Vector3(-2.0, 14.2, 2.0), Vector3(-2.0, 14.2, -2.0), Vector3(2.0, 14.2, -2.0)]
	for k3 in range(4):
		var q0: Vector3 = coins[k3]
		var q1: Vector3 = coins[(k3 + 1) % 4]
		var nn: Vector3 = (cxf.basis * ((q0 + q1) * 0.5 * Vector3(1, 0, 1) + Vector3(0, 1.0, 0))).normalized()
		b.tri("bardeaux", [cxf * q0, cxf * q1, cxf * Vector3(0, 18.5, 0)], [nn, nn, nn], [Vector2(0, 0), Vector2(4, 0), Vector2(2, 4)])
	b.cyl("laiton", cxf * Transform3D(Basis(), Vector3(0, 18.4, 0)), 0.06, 0.04, 1.6, 6)
	b.box("laiton", cxf * Transform3D(Basis(), Vector3(0, 19.5, 0)), Vector3(0.8, 0.08, 0.08))
	b.box("laiton", cxf * Transform3D(Basis(Vector3.UP, 0.0), Vector3(0.3, 19.6, 0)), Vector3(0.5, 0.25, 0.04))
	Kit.panneau(b, root, xf * Transform3D(Basis(), Vector3(0, 4.5, 0.18)), 5.6, 0.6, "NOTRE-DAME-DES-NUÉES", "enseigne_creme")
	b.commit(root, "Perchee_chapelle", true, 400.0)
	M.reperes["chapelle"] = at + Vector3(0, 0, 2.5)


## Le vieux donjon, derrière le bureau du shérif : une tour ronde médiévale, des créneaux, une
## guérite de bois et une sirène à vapeur ajoutées par-dessus.
static func _donjon(M, cols: GK.Cols) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var at: Vector3 = Ile.W(152.0, -36.0)
	at.y = ile.height(at.x, at.z)
	b.cyl("moellons", Transform3D(Basis(), at + Vector3.DOWN * 1.5), 5.6, 5.0, 19.0, 20)
	cols.cyl(at + Vector3.DOWN * 1.5, 5.4, 19.0)
	b.cyl("pierre_taille", Transform3D(Basis(), at + Vector3.UP * 17.0), 5.4, 5.4, 0.6, 20)
	for k in range(14):
		var a: float = TAU * k / 14.0
		b.box("moellons", Transform3D(Basis(Vector3.UP, -a), at + Vector3(cos(a) * 5.1, 18.1, sin(a) * 5.1)), Vector3(0.8, 1.4, 1.4))
	for k2 in range(5):
		var a2: float = TAU * k2 / 5.0 + 0.3
		var y: float = 4.0 + k2 * 2.5
		b.box("sombre", Transform3D(Basis(Vector3.UP, -a2), at + Vector3(cos(a2) * 5.05, y, sin(a2) * 5.05)), Vector3(0.3, 1.2, 0.4))
	# la guérite et la sirène
	b.box("bardage_brut", Transform3D(Basis(), at + Vector3(0, 19.4, 0)), Vector3(3.2, 2.6, 3.2))
	b.prism("tole", at + Vector3(-2.0, 20.7, -2.0), at + Vector3(2.0, 20.7, -2.0), at + Vector3(0, 22.0, -2.0), Vector3(0, 0, 4.0))
	b.tube("cuivre", at + Vector3(1.0, 20.7, 1.0), at + Vector3(1.0, 23.6, 1.0), 0.14, 8)
	b.cyl("laiton", Transform3D(Basis(Vector3.BACK, PI * 0.5), at + Vector3(1.0, 23.8, 1.0)), 0.3, 0.6, 1.2, 12)
	b.commit(root, "Perchee_donjon", true, 500.0)
	M.cheminees.append(at + Vector3(1.0, 23.8, 1.0))


## Le château d'eau sur ses quatre pieds (une cuve de douves cerclées, un toit pointu, une échelle).
static func _chateau_eau(M, cols: GK.Cols) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var at: Vector3 = Ile.W(108.0, -46.0)
	at.y = ile.height(at.x, at.z)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.tube("poutre", at + Vector3(sx * 3.2, -0.5, sz * 3.2), at + Vector3(sx * 2.2, 9.0, sz * 2.2), 0.22, 6)
			cols.cyl(at + Vector3(sx * 2.8, 0, sz * 2.8), 0.3, 6.0)
	for y in [3.0, 6.0]:
		var r: float = 3.2 - y / 9.5
		for k in range(4):
			var a0: float = TAU * k / 4.0 + PI / 4.0
			var a1: float = a0 + PI * 0.5
			var p0: Vector3 = at + Vector3(cos(a0) * r * 1.414, y, sin(a0) * r * 1.414)
			var p1: Vector3 = at + Vector3(cos(a1) * r * 1.414, y, sin(a1) * r * 1.414)
			b.tube("poutre", p0, p1, 0.1, 4)
	b.box("planches", Transform3D(Basis(), at + Vector3(0, 9.1, 0)), Vector3(5.6, 0.2, 5.6))
	b.cyl("tonneau", Transform3D(Basis(), at + Vector3.UP * 9.2), 3.0, 3.0, 4.8, 20)
	for y2 in [9.6, 11.2, 12.8, 13.7]:
		b.cyl("fer", Transform3D(Basis(), at + Vector3.UP * y2), 3.05, 3.05, 0.12, 20, false)
	b.cyl("tole", Transform3D(Basis(), at + Vector3.UP * 14.0), 3.4, 0.1, 2.0, 20)
	b.tube("fer", at + Vector3(3.1, 0.0, 0.0), at + Vector3(3.1, 14.0, 0.0), 0.04, 4)
	b.tube("fer", at + Vector3(3.1, 0.0, 0.6), at + Vector3(3.1, 14.0, 0.6), 0.04, 4)
	for k2 in range(30):
		b.tube("fer", at + Vector3(3.1, 0.4 + k2 * 0.45, 0), at + Vector3(3.1, 0.4 + k2 * 0.45, 0.6), 0.025, 4)
	b.tube("cuivre", at + Vector3(0, 9.2, 0), at + Vector3(0, -0.4, 0), 0.25, 8)
	Kit.panneau(b, root, Transform3D(Basis(Vector3.UP, PI * 0.15), at + Vector3(0.9, 11.6, 3.05)), 3.4, 0.8, "PILE-OU-FACE", "enseigne_fond")
	b.commit(root, "Perchee_chateau_eau", true, 600.0)


## L'éolienne de pompage (la roue à pales tourne au vent, la queue la tient face au vent).
static func _eolienne(M, cols: GK.Cols) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var at: Vector3 = Ile.W(-24.0, -44.0)
	at.y = ile.height(at.x, at.z)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.tube("fer", at + Vector3(sx * 1.6, -0.3, sz * 1.6), at + Vector3(sx * 0.3, 11.0, sz * 0.3), 0.07, 5)
	for y in [2.5, 5.5, 8.5]:
		var r: float = 1.6 - y / 11.0 * 1.3
		for k in range(4):
			var a0: float = TAU * k / 4.0 + PI / 4.0
			b.tube("fer", at + Vector3(cos(a0) * r * 1.414, y, sin(a0) * r * 1.414), at + Vector3(cos(a0 + PI * 0.5) * r * 1.414, y, sin(a0 + PI * 0.5) * r * 1.414), 0.03, 4)
	cols.box(Transform3D(Basis(), at + Vector3(0, 2.0, 0)), Vector3(3.4, 4.0, 3.4))
	b.box("planches", Transform3D(Basis(), at + Vector3(0, 11.0, 0)), Vector3(0.9, 0.12, 0.9))
	b.tube("fer", at + Vector3(0, 11.2, 0.3), at + Vector3(0, 11.2, -3.2), 0.06, 6)
	b.box("tole_peinte", Transform3D(Basis(), at + Vector3(0, 11.6, -3.0)), Vector3(0.04, 1.4, 1.8))
	b.box("planches", Transform3D(Basis(), at + Vector3(2.0, 0.6, 0)), Vector3(1.4, 1.2, 1.4))
	b.commit(root, "Perchee_eolienne", true, 500.0)
	var rotor := Node3D.new()
	rotor.name = "Eolienne_roue"
	root.add_child(rotor)
	rotor.global_position = at + Vector3(0, 11.2, 0.5)
	var rb := Kit.Lot.new()
	for k2 in range(18):
		var a: float = TAU * k2 / 18.0
		var d := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0)
		rb.quad("tole_peinte", [d * 0.5 - side * 0.1, d * 2.6 - side * 0.24, d * 2.6 + side * 0.24 + Vector3(0, 0, 0.15), d * 0.5 + side * 0.1 + Vector3(0, 0, 0.05)], Vector3(0, 0, 1),
			[Vector2(0, 0), Vector2(2, 0), Vector2(2, 0.5), Vector2(0, 0.5)])
	rb.tube("fer", Vector3(0, 0, -0.2), Vector3(0, 0, 0.3), 0.25, 8)
	rb.cyl("fer", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 2.6, 2.6, 0.06, 24, false)
	rb.cyl("fer", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 1.4, 1.4, 0.05, 18, false)
	var mi: MeshInstance3D = rb.commit(rotor, "Eolienne_pales", true, 400.0)
	if mi != null:
		var m2: Material = Kit.mat("tole_peinte")
		if m2 is StandardMaterial3D:
			(m2 as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	M.tournants.append([rotor, Vector3(0, 0, 1), 0.9])


## Le corral derrière l'écurie : une barrière de rondins, un abreuvoir, des balles de foin.
static func _corral(M, cols: GK.Cols, rng: RandomNumberGenerator) -> void:
	var ile = M.ile
	var root: Node3D = M.bourg_root
	var b := Kit.Lot.new()
	var c := Vector2(150.0, 46.0)
	var pts: Array = []
	for k in range(14):
		var a: float = TAU * k / 14.0
		pts.append(c + Vector2(cos(a) * 14.0, sin(a) * 10.0))
	for i in range(pts.size()):
		if i == 10:
			continue                       # le portail (vers la rue)
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[(i + 1) % pts.size()]
		var a0: Vector3 = Ile.W(p0.x, p0.y)
		a0.y = ile.height(a0.x, a0.z)
		var a1: Vector3 = Ile.W(p1.x, p1.y)
		a1.y = ile.height(a1.x, a1.z)
		b.cyl("poutre", Transform3D(Basis(), a0 + Vector3.DOWN * 0.3), 0.14, 0.12, 1.8, 6)
		for y in [0.55, 1.2]:
			b.tube("poutre", a0 + Vector3.UP * y, a1 + Vector3.UP * y, 0.08, 5)
		var mid: Vector3 = (a0 + a1) * 0.5
		var dir: Vector3 = a1 - a0
		cols.box(Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), mid + Vector3.UP * 0.7), Vector3(0.2, 1.4, dir.length()))
	for k2 in range(4):
		var q: Vector2 = c + Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-5.0, 5.0))
		var at: Vector3 = Ile.W(q.x, q.y)
		at.y = ile.height(at.x, at.z)
		b.cyl("foin", Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.BACK, PI * 0.5), at + Vector3(0, 0.6, 0)), 0.6, 0.6, 1.2, 12)
		cols.cyl(at, 0.7, 1.2)
	var t: Vector3 = Ile.W(c.x + 6.0, c.y - 4.0)
	t.y = ile.height(t.x, t.z)
	Kit.abreuvoir(b, cols, t, 0.4)
	b.commit(root, "Perchee_corral", true, 260.0)

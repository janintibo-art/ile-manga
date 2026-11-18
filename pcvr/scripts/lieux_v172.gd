extends RefCounted
## V172 : on entre au Fondouk de Tazira, dans la tour de guet de la Skala et dans les deux petits
## phares de la jetée ; à Ramure, dans l'échoppe des Simples, la Poste des chouettes, la boulangerie
## des lapins et la pêcherie des chats ; à Port-Boucan, dans le bureau de vente de Lisse & Fils, la
## roulotte de Mère Morille et le phare tagué.
## Comme lieux_v171 (et les boutiques de boutiques_v170, qui délègue ici les métiers qu'il ne connaît
## pas) : chaque ville pose ses portes (porte_ville) ; derrière la porte, la pièce de l'endroit
## (« b172 »), et celui qui le tient : la vraie personne de la ville quand elle existe.
## M : maisons_v81 ; R : la pièce ; B : les boutiques ; L1 : les aides de lieux_v171.

const B = preload("res://scripts/boutiques_v170.gd")
const L1 = preload("res://scripts/lieux_v171.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")
const BM = preload("res://scripts/boucan_mats_v75.gd")

const HISTOIRE := "b172"

const METIERS := {
	"fondouk": [Vector2(12.0, 10.0), 5.0], "tour_skala": [Vector2(6.0, 6.0), 4.0], "phare_jetee": [Vector2(4.6, 4.6), 4.2],
	"simples": [Vector2(6.6, 6.6), 3.3], "poste_chouettes": [Vector2(6.2, 6.2), 3.4], "boulangerie_lapins": [Vector2(7.0, 7.0), 3.4],
	"pecherie_chats": [Vector2(6.2, 6.2), 3.1], "bureau_lisse": [Vector2(9.5, 4.6), 2.7], "roulotte_morille": [Vector2(3.4, 5.2), 2.7],
	"phare_tague": [Vector2(6.6, 6.6), 5.0],
}

## Les pièces rondes (les cabanes rondes de Ramure, les phares).
const RONDS := ["phare_jetee", "simples", "poste_chouettes", "boulangerie_lapins", "pecherie_chats", "phare_tague"]

## id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"tazira": {
		"fondouk": ["fondouk", "zineb", "au Fondouk, chez Zineb", "Fondouk"],
		"skala": ["tour_skala", "hamza", "dans la tour de guet de la Skala", "Tour de la Skala"],
		"phare_vert": ["phare_jetee", "", "dans le petit phare vert", "Phare vert"],
		"phare_rouge": ["phare_jetee", "", "dans le petit phare rouge", "Phare rouge"],
	},
	"ramure": {
		"simples": ["simples", "pivoine", "à l'échoppe des Simples", "Les Simples"],
		"poste": ["poste_chouettes", "plumette", "à la Poste des chouettes", "Poste des chouettes"],
		"boulangerie": ["boulangerie_lapins", "trefle", "à la boulangerie des lapins", "Boulangerie"],
		"pecherie": ["pecherie_chats", "caramel", "à la pêcherie des chats", "Pêcherie"],
	},
	"boucan": {
		"bureau": ["bureau_lisse", "lisse", "au bureau de vente de Lisse & Fils", "Lisse & Fils"],
		"morille": ["roulotte_morille", "morille", "dans la roulotte de Mère Morille", "Roulotte de Mère Morille"],
		"phare": ["phare_tague", "pigment", "dans le phare tagué", "Phare tagué"],
	},
}


static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return B.porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]), HISTOIRE)


static func has_metier(met: String) -> bool:
	return METIERS.has(met)


# =================================================================== la coque

static func _pal(st: String, met: String) -> Dictionary:
	var p := {}
	match st:
		"tazira":
			p = {"sol": ["tazira/zellige.png", Color(1, 1, 1), 1.2], "mur": ["tazira/chaux.png", Color(1, 0.98, 0.94), 2.5],
				"bas": ["tazira/zellige.png", Color(0.9, 0.95, 1.0), 0.9], "plafond": ["tazira/canisse.png", Color(0.85, 0.75, 0.6), 1.5]}
			match met:
				"fondouk":
					p["mur"] = ["tazira/chaux.png", Color(1.02, 0.94, 0.82), 2.5]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.58, 0.36, 0.26), 1.6]
				"tour_skala":
					p["sol"] = ["azur/dalles.png", Color(0.82, 0.74, 0.64), 1.4]
					p["mur"] = ["tazira/chaux.png", Color(1.0, 0.86, 0.66), 2.5]
					p["bas"] = ["tazira/chaux.png", Color(0.82, 0.68, 0.52), 1.6]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.4, 0.3, 0.24), 1.8]
					p["fenetre"] = "aucune"
				"phare_jetee":
					p["sol"] = ["azur/dalles.png", Color(0.8, 0.76, 0.7), 1.2]
					p["mur"] = ["tazira/chaux.png", Color(1.02, 1.02, 1.0), 2.0]
					p["bas"] = ["tazira/chaux.png", Color(0.85, 0.85, 0.85), 1.4]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
		"ramure":
			p = {"sol": ["ramure/planches.png", Color(0.95, 0.88, 0.75), 1.8], "mur": ["ramure/rondins.png", Color(1, 0.95, 0.88), 2.0],
				"bas": ["ramure/rondins.png", Color(0.82, 0.76, 0.68), 2.0], "plafond": ["ramure/chaume.png", Color(0.85, 0.78, 0.6), 2.0],
				"fenetre": "aucune", "sans_poutres": true}
			if met == "poste_chouettes":
				p["mur"] = ["ramure/ecorce.png", Color(0.95, 0.9, 0.85), 2.0]
		"boucan":
			p = {"sol": ["boucan/carrelage_bureau.png", Color(0.95, 0.95, 0.95), 1.6], "mur": ["boucan/brique_peinte.png", Color(1, 1, 1), 2.5],
				"bas": ["boucan/beton.png", Color(0.85, 0.85, 0.85), 2.0], "plafond": ["boucan/beton.png", Color(0.8, 0.8, 0.8), 3.0]}
			match met:
				"bureau_lisse":
					p["sol"] = ["boucan/moquette_bureau.png", Color(0.9, 0.9, 0.95), 1.6]
					p["mur"] = ["maisons/lambris_blanc.png", Color(0.93, 0.94, 0.96), 1.6]
					p["bas"] = ["boucan/tole_peinte.png", Color(0.85, 0.85, 0.85), 1.5]
					p["plafond"] = ["boucan/faux_plafond.png", Color(0.95, 0.95, 0.95), 1.2]
					p["sans_poutres"] = true
				"roulotte_morille":
					p["sol"] = ["montjoie/bois_planches.png", Color(0.7, 0.55, 0.42), 1.6]
					p["mur"] = ["montjoie/bois_planches.png", Color(0.45, 0.62, 0.42), 1.4]
					p["bas"] = ["montjoie/bois_planches.png", Color(0.55, 0.4, 0.3), 1.2]
					p["plafond"] = ["montjoie/bois_planches.png", Color(0.75, 0.3, 0.25), 1.4]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
				"phare_tague":
					p["sol"] = ["boucan/beton.png", Color(0.8, 0.8, 0.82), 2.0]
					p["mur"] = ["boucan/brique_peinte.png", Color(1.0, 1.0, 1.0), 2.0]
					p["bas"] = ["boucan/beton.png", Color(0.6, 0.6, 0.62), 1.6]
					p["plafond"] = ["boucan/beton.png", Color(0.55, 0.55, 0.58), 2.0]
					p["fenetre"] = "aucune"
					p["sans_poutres"] = true
	return p


static func build(M) -> void:
	match str(M.cur.get("metier", "")):
		"fondouk":
			_fondouk(M)
		"tour_skala":
			_tour_skala(M)
		"phare_jetee":
			_phare_jetee(M)
		"simples":
			_simples(M)
		"poste_chouettes":
			_poste_chouettes(M)
		"boulangerie_lapins":
			_boulangerie_lapins(M)
		"pecherie_chats":
			_pecherie_chats(M)
		"bureau_lisse":
			_bureau_lisse(M)
		"roulotte_morille":
			_roulotte_morille(M)
		"phare_tague":
			_phare_tague(M)


# =================================================================== les aides

## Une matière de Port-Boucan (boucan_mats_v75 : « graffiti75_3 », « chapeau75_bleu »…).
static func _mb(R, key: String) -> String:
	if R.mat(key) == null:
		var m: Material = BM.make(key)
		if m == null:
			return "pierre"
		R._put(key, m)
	return key


## Une image posée contre le mur rond (angle a, à la hauteur y), qui regarde le milieu.
static func _image_rond(M, key: String, a: float, r: float, y: float, w: float, h: float) -> void:
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.03, y)
	M.R.kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 0.01)), w, h, key)


## Le toit d'une cabane ronde, vu de dedans : les chevrons qui montent du mur vers le milieu.
static func _chevrons(M, r: float, n: int = 10) -> void:
	var R = M.R
	var k = R.kit
	for i in range(n):
		var a: float = TAU * (i + 0.5) / n
		var p0 := Vector3(sin(a) * (r - 0.1), R.H - 0.75, cos(a) * (r - 0.1))
		var p1 := Vector3(sin(a) * 0.2, R.H - 0.02, cos(a) * 0.2)
		var mid: Vector3 = (p0 + p1) * 0.5
		var d: Vector3 = p1 - p0
		var xf := Transform3D(Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT), R.P(mid.x, mid.y, mid.z))
		k.box(xf, Vector3(0.1, 0.12, d.length()), "poutre", 1.0)
	k.cyl(R.L(0, R.H - 0.4, 0), 0.2, 0.2, 0.4, "poutre", 10)


## Une lanterne marocaine de cuivre ajouré (les verres de couleur), pendue au plafond.
static func _lanterne_maroc(M, x: float, z: float, y: float, c: Color) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, y + 0.42, z), 0.006, 0.006, R.H - y - 0.42, "fer", 4, false)
	k.cyl(R.L(x, y - 0.05, z), 0.04, 0.12, 0.08, "cuivre", 6)
	k.cyl(R.L(x, y + 0.03, z), 0.13, 0.13, 0.26, B._verre(R, "verre_maroc_%s" % c.to_html(false), c, 0.6, 1.6), 6)
	for i in range(6):
		var a: float = TAU * i / 6.0
		k.box(R.L(x + cos(a) * 0.13, y + 0.16, z + sin(a) * 0.13), Vector3(0.02, 0.28, 0.02), "cuivre", 1.0)
	k.cyl(R.L(x, y + 0.29, z), 0.15, 0.03, 0.14, "cuivre", 6)
	k.cyl(R.L(x, y + 0.29, z), 0.15, 0.15, 0.02, "cuivre", 6)
	B._lampe(M, x, y + 0.15, z, c.lerp(Color(1.0, 0.85, 0.6), 0.5), 0.55, 3.5)


## Un arc outrepassé (en fer à cheval), entre deux piliers le long de z (à x), sa base à y.
static func _arc_fer(M, x: float, z0: float, z1: float, y: float, key: String) -> void:
	var R = M.R
	var k = R.kit
	var r: float = (z1 - z0) * 0.5 * 1.08
	var cz: float = (z0 + z1) * 0.5
	var cy: float = y + r * 0.35
	var n: int = 14
	var a0: float = -0.38
	var a1: float = PI + 0.38
	for i in range(n):
		var t0: float = lerpf(a0, a1, float(i) / n)
		var t1: float = lerpf(a0, a1, float(i + 1) / n)
		var p0 := Vector3(x, cy + sin(t0) * r, cz + cos(t0) * r)
		var p1 := Vector3(x, cy + sin(t1) * r, cz + cos(t1) * r)
		var mid: Vector3 = (p0 + p1) * 0.5
		var d: Vector3 = p1 - p0
		k.box(R.L(mid.x, mid.y, mid.z) * Transform3D(Basis(Vector3.RIGHT, -atan2(d.y, d.z)), Vector3.ZERO), Vector3(0.3, 0.16, d.length() + 0.02), key, 1.0)


## Un jet d'eau (de petites gouttes qui montent et retombent dans la vasque).
static func _jet(M, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 1.6
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, -6.5, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := SphereMesh.new()
	q.radius = 0.018
	q.height = 0.036
	q.radial_segments = 6
	q.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.88, 1.0, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	q.material = m
	p.mesh = q
	M.room.add_child(p)
	p.global_position = at


## Un oranger dans sa grande jarre (le tronc, le feuillage rond, les oranges).
static func _oranger(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.32, 0.4, 0.55, "terre_cuite", 14)
	k.cyl(R.L(x, 0.55, z), 0.38, 0.38, 0.02, "terreau", 14)
	k.cyl(R.L(x, 0.55, z), 0.06, 0.05, 1.0, "bois_sombre", 8)
	var feu: Material = R.mat("feuillage")
	Sud._boule(M.room, feu, R.P(x, 1.75, z), 0.55, Vector3(1.0, 0.85, 1.0))
	Sud._boule(M.room, feu, R.P(x + 0.25, 1.95, z - 0.1), 0.35)
	var orm: Material = R.mat(B._c(R, "orange171", Color(1.0, 0.55, 0.08), 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 10.0 + z * 100.0)
	for i in range(9):
		var a: float = rng.randf() * TAU
		var e: float = rng.randf_range(-0.3, 0.6)
		Sud._boule(M.room, orm, R.P(x + cos(a) * 0.5 * cos(e), 1.75 + sin(e) * 0.45, z + sin(a) * 0.5 * cos(e)), 0.05)
	k.col_box(R.L(x, 0.5, z), Vector3(0.8, 1.0, 0.8))
	R.reserve(x, z, 1.0, 1.0)


## Un plateau à thé de cuivre sur sa table basse (la théière, les verres colorés).
static func _the(M, x: float, z: float, h: float = 0.42) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(x, 0, z), 0.12, 0.16, h - 0.03, "bois_sombre", 10)
	k.cyl(R.L(x, h - 0.03, z), 0.5, 0.5, 0.03, "cuivre", 20)
	k.ring(R.L(x, h, z), 0.46, 0.5, 0.03, "cuivre", 20)
	k.cyl(R.L(x, h, z), 0.09, 0.11, 0.14, "argent", 12)
	k.cyl(R.L(x, h + 0.14, z), 0.09, 0.03, 0.08, "argent", 12)
	k.cyl(R.L(x + 0.1, h + 0.06, z) * Transform3D(Basis(Vector3.BACK, -0.9), Vector3.ZERO), 0.015, 0.01, 0.16, "argent", 6)
	for g in range(4):
		var a: float = TAU * g / 4.0 + 0.5
		k.cyl(R.L(x + cos(a) * 0.28, h, z + sin(a) * 0.28), 0.03, 0.035, 0.08, B._verre(R, "verre_the_%d" % (g % 2), [Color(0.2, 0.55, 0.3), Color(0.75, 0.25, 0.3)][g % 2], 0.6), 8)
	k.col_box(R.L(x, h * 0.5, z), Vector3(1.0, h, 1.0))
	R.reserve(x, z, 1.1, 1.1)


## Un pouf de cuir (on s'y assied).
static func _pouf(M, x: float, z: float, c: String = "cuir") -> void:
	var R = M.R
	R.kit.cyl(R.L(x, 0, z), 0.26, 0.28, 0.4, c, 12)
	R.kit.cyl(R.L(x, 0.4, z), 0.27, 0.2, 0.04, c, 12)


# =================================================================== Tazira : le Fondouk

static func _fondouk(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var zel: String = B._tex(R, "zellige172", "tazira/zellige.png", Color(1, 1, 1), 0.5)
	# la vasque du milieu, carrelée de zellige, et son jet d'eau
	var fz: float = -0.3
	k.cyl(R.L(0, 0, fz), 1.15, 1.2, 0.5, zel, 8)
	k.ring(R.L(0, 0.5, fz), 1.0, 1.2, 0.06, "pierre_lisse", 8)
	k.disc(R.L(0, 0.42, fz), 1.02, L1._m(R, "eau69"), 8)
	k.cyl(R.L(0, 0.4, fz), 0.12, 0.08, 0.5, "pierre_lisse", 10)
	k.cyl(R.L(0, 0.9, fz), 0.08, 0.3, 0.1, "pierre_lisse", 14)
	_jet(M, R.P(0, 1.0, fz))
	k.col_box(R.L(0, 0.3, fz), Vector3(2.3, 0.6, 2.3))
	R.reserve(0, fz, 2.6, 2.6)
	# le ciel du patio (une verrière), et la lumière qui tombe sur la vasque
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.box(R.L(0, R.H - 0.01, fz), Vector3(3.0, 0.02, 3.0), B._c(R, "ciel_patio_n" if nuit else "ciel_patio_j", Color(0.08, 0.1, 0.25) if nuit else Color(0.62, 0.8, 1.0), 0.5, 0.0, 0.5 if nuit else 1.5), 1.0)
	k.ring(R.L(0, R.H - 0.2, fz), 1.5, 1.75, 0.2, "bois_sombre", 4)
	if not nuit:
		L1._rayon(M, 0.0, fz + 0.3, 1.4, 0.15)
	# les arcades des deux côtés : les piliers, les arcs en fer à cheval, la galerie au-dessus
	var chaux: String = "mur"
	for sx in [-1.0, 1.0]:
		var ax: float = sx * (hw - 1.6)
		for pz in [-3.9, -1.3, 1.3]:
			k.box(R.L(ax, 1.3, pz), Vector3(0.36, 2.6, 0.36), chaux, 1.0)
			k.box(R.L(ax, 0.45, pz), Vector3(0.4, 0.9, 0.4), zel, 0.5)
			k.col_box(R.L(ax, 1.3, pz), Vector3(0.36, 2.6, 0.36))
		for a2 in [[-3.9, -1.3], [-1.3, 1.3]]:
			_arc_fer(M, ax, float(a2[0]) + 0.18, float(a2[1]) - 0.18, 2.05, chaux)
		k.box(R.L(ax, 3.2, -1.3), Vector3(0.4, 0.5, 5.6), chaux, 1.0)
		k.box(R.L(ax, 3.48, -1.3), Vector3(0.5, 0.08, 5.7), "bois_sombre", 1.0)
		# la galerie du premier : sa balustrade de bois tourné (moucharabieh)
		k.box(R.L(ax, 3.95, -1.3), Vector3(0.06, 0.8, 5.6), B._tex(R, "canisse172", "tazira/canisse.png", Color(0.6, 0.4, 0.25), 0.8), 0.6)
		k.box(R.L(ax, 4.37, -1.3), Vector3(0.12, 0.06, 5.6), "bois_sombre", 1.0)
	# à gauche, sous les arcades : le salon (la banquette, les coussins, le thé)
	var bx: float = -hw + 0.45
	k.box(R.L(bx, 0.21, -1.3), Vector3(0.75, 0.42, 5.2), "bois_sombre", 1.0)
	k.box(R.L(bx, 0.47, -1.3), Vector3(0.7, 0.1, 5.1), "tissu_rouge", 1.0)
	k.box(R.L(-hw + 0.12, 0.8, -1.3), Vector3(0.18, 0.5, 5.1), "tissu_rouge", 1.0)
	for c in range(5):
		k.box(R.L(-hw + 0.2, 0.75, -3.3 + c * 1.0) * Transform3D(Basis(Vector3.BACK, 0.25), Vector3.ZERO), Vector3(0.14, 0.42, 0.42), "tissu_" + ["jaune", "bleu", "vert", "orange", "violet"][c], 1.0)
	k.col_box(R.L(bx, 0.25, -1.3), Vector3(0.75, 0.5, 5.2))
	R.reserve(bx, -1.3, 1.0, 5.4)
	_the(M, -hw + 1.55, -1.9)
	_the(M, -hw + 1.55, 0.6)
	R.tapis(-hw + 1.4, -0.7, 90.0, 4.4, 2.0)
	# au fond : la grande tenture, l'enseigne ; à droite : la réception de Zineb, le tableau des clés
	L1._fresque(M, "tazira/tapis_2.png", -2.4, 2.4, -hd + 0.02, 0.0, 1.6, 2.4, "bois_sombre")
	L1._fresque(M, "tazira/enseigne_fondouk.png", 0.0, 3.6, -hd + 0.02, 0.0, 2.6, 1.3, "", 1)
	var zc: float = -hd + 1.25
	var cx: Transform3D = B._comptoir(M, 2.5, zc, 2.0, 0.0, false, 1.0, "bois_sombre", "cuivre")
	B._balance(R, cx * B.T3(-0.6, 1.06, 0.05))
	R.bougie(2.9, 1.06, zc + 0.1)
	k.box(R.L(2.5, 1.8, -hd + 0.03), Vector3(1.3, 0.8, 0.04), "bois", 1.0)
	R.mark_wall(2.5, 1.8, -hd, 0.7)
	for c2 in range(8):
		var kx: float = 2.0 + (c2 % 4) * 0.3
		var ky: float = 2.0 - (c2 / 4) * 0.35
		k.cyl(R.L(kx, ky, -hd + 0.06) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.008, 0.008, 0.05, "or", 4)
		k.box(R.L(kx, ky - 0.08, -hd + 0.07), Vector3(0.03, 0.1, 0.006), "or", 1.0)
	# les orangers, les lanternes, les tapis
	for e in [[-1.9, -2.6], [1.9, -2.6], [-1.9, 2.0], [1.9, 2.0]]:
		_oranger(M, float(e[0]), float(e[1]))
	_lanterne_maroc(M, -hw + 1.6, -0.0, 2.35, Color(0.95, 0.4, 0.2))
	_lanterne_maroc(M, hw - 1.6, -0.0, 2.35, Color(0.3, 0.6, 0.9))
	_lanterne_maroc(M, -2.6, 2.0, 3.6, Color(0.95, 0.75, 0.25))
	_lanterne_maroc(M, 2.6, 2.0, 3.6, Color(0.4, 0.8, 0.45))
	R.tapis(hw - 1.4, -0.7, 90.0, 4.0, 1.8)
	for e2 in [[hw - 1.0, -2.2], [hw - 1.0, 0.5]]:
		_pouf(M, float(e2[0]), float(e2[1]), "tissu_bleu")
		_pouf(M, float(e2[0]) - 0.7, float(e2[1]) + 0.6, "cuir")
	var the := func() -> void:
		M.main.sfx("clochette")
		M.say("Zineb verse le thé de très haut, d'un grand geste : la mousse monte dans le verre. « Le premier est doux comme la vie, le deuxième fort comme l'amour, le troisième amer comme la mort. On ne boit que le premier, ici. »", 7.0)
	M.act(R.P(-hw + 1.55, 0, -0.65), "E : boire un thé à la menthe", the, 1.0)
	B._marchand(M, 2.5, zc - 0.55, 0.0, "comptoir", "femme", "Zineb", ["Le Fondouk a vu passer plus de caravanes que de mouettes.", "Une chambre sur la terrasse ? On s'endort avec la fête, on se réveille avec les mouettes.", "Le jet d'eau chante tout seul. Moi, je chante seulement quand personne n'écoute."],
		{"bonjour": "Bienvenue au Fondouk, voyageur. Du thé ? Une chambre ?", "vend": {"the_menthe": 2, "dattes": 2}})
	B._habitue(M, "mbarek", bx, -1.9, 90.0, "assis", ["Trois mois de désert pour vendre mes dattes. Trois minutes pour tout vendre à Lalla Aïcha.", "Le chameau ? Il dort dans la cour de derrière. Il ronfle comme un moteur de barque."])
	B._habitue(M, "selma", -1.4, 2.9, 160.0, "peindre", ["Je peins la vasque depuis trois jours. L'eau ne tient jamais la pose.", "La lumière de Tazira est la plus belle du monde. Ne le dis pas à Port-Azur."])
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au Fondouk ! Assieds-toi, le thé arrive.", "Entre, entre. Ici, on prend le temps."]
	M.ctx["entree"] = "Le Fondouk : le patio et sa vasque de zellige qui chante, les arcades en fer à cheval, les orangers en pot, le salon et ses coussins, et l'odeur du thé à la menthe."


# =================================================================== Tazira : la tour de guet de la Skala

static func _tour_skala(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# les meurtrières (la mer derrière), la longue-vue sur son trépied
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	var ciel: String = B._c(R, "fente_mer_n" if nuit else "fente_mer_j", Color(0.08, 0.1, 0.22) if nuit else Color(0.6, 0.78, 0.95), 0.5, 0.0, 0.5 if nuit else 1.4)
	for e in [[0.0, -hd + 0.01, 0.0], [-hw + 0.01, 0.0, 90.0], [hw - 0.01, -0.6, -90.0]]:
		k.quad(R.L(float(e[0]), 1.7, float(e[1]), float(e[2])) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.16, 0.9, ciel)
		R.mark_wall(float(e[0]), 1.7, float(e[1]), 0.2)
	var lx: float = 0.6
	var lz: float = -hd + 0.9
	for i in range(3):
		var a: float = TAU * i / 3.0
		k.box(R.L(lx + cos(a) * 0.18, 0.6, lz + sin(a) * 0.18) * Transform3D(Basis(Vector3(-sin(a), 0, cos(a)), 0.22), Vector3.ZERO), Vector3(0.03, 1.25, 0.03), "bois_sombre", 1.0)
	k.cyl(R.L(lx, 1.25, lz) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.1), Vector3(0, 0, 0.3)), 0.05, 0.035, 0.85, "cuivre", 12)
	# le râtelier des lances, les boucliers ronds, la pyramide de boulets
	var rx: float = -hw + 0.12
	k.box(R.L(rx, 1.0, -1.0), Vector3(0.1, 0.06, 1.6), "bois_sombre", 1.0)
	k.box(R.L(rx, 0.15, -1.0), Vector3(0.14, 0.06, 1.6), "bois_sombre", 1.0)
	for s in range(5):
		var sz: float = -1.6 + s * 0.3
		k.cyl(R.L(rx + 0.08, 0.15, sz), 0.018, 0.018, 1.9, "bois", 6)
		k.cyl(R.L(rx + 0.08, 2.05, sz), 0.03, 0.0, 0.18, "fer", 6)
	for sb in [[-hw + 0.04, 2.3, 0.6], [-hw + 0.04, 2.3, 1.6]]:
		var bxf: Transform3D = R.L(float(sb[0]), float(sb[1]), float(sb[2]), 90.0)
		k.cyl(bxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.02)), 0.36, 0.36, 0.04, "cuir", 18)
		k.cyl(bxf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.06)), 0.08, 0.05, 0.05, "cuivre", 12)
		R.mark_wall(float(sb[0]), float(sb[1]), float(sb[2]), 0.4)
	var bf: Material = R.mat("fer")
	for lv in range(3):
		for ix in range(3 - lv):
			for iz in range(3 - lv):
				Sud._boule(M.room, bf, R.P(hw - 0.7 + ix * 0.2 + lv * 0.1, 0.1 + lv * 0.16, hd - 1.2 + iz * 0.2 + lv * 0.1), 0.1)
	R.reserve(hw - 0.5, hd - 1.0, 0.8, 0.8)
	# le grand tambour d'alarme, l'échelle vers la terrasse, le coffre, le brasero
	k.cyl(R.L(hw - 0.6, 0, -hd + 0.7), 0.32, 0.32, 0.6, "bois", 14)
	k.cyl(R.L(hw - 0.6, 0.6, -hd + 0.7), 0.33, 0.33, 0.02, "cuir", 14)
	k.col_box(R.L(hw - 0.6, 0.3, -hd + 0.7), Vector3(0.7, 0.6, 0.7))
	R.reserve(hw - 0.6, -hd + 0.7, 0.8, 0.8)
	for s2 in [-1.0, 1.0]:
		k.box(R.L(-hw + 0.9 + s2 * 0.22, R.H * 0.5, -hd + 0.25) * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3.ZERO), Vector3(0.06, R.H + 0.1, 0.06), "bois", 1.0)
	for g in range(int(R.H / 0.32)):
		k.box(R.L(-hw + 0.9, 0.25 + g * 0.32, -hd + 0.25 + (0.25 + g * 0.32 - R.H * 0.5) * 0.12), Vector3(0.46, 0.04, 0.05), "bois", 1.0)
	k.box(R.L(-hw + 0.9, R.H - 0.02, -hd + 0.6), Vector3(0.9, 0.04, 0.9), "bois_sombre", 1.0)
	R.reserve(-hw + 0.9, -hd + 0.4, 0.8, 0.8)
	R.coffre_deco(hw - 0.5, 0.6, -90.0)
	_the(M, -0.6, 0.6, 0.38)
	_pouf(M, -1.35, 0.9)
	_pouf(M, 0.1, 1.2)
	B._cadre(R, B._img(R, "carte_campagne172", "beau170/carte_campagne.png"), hw - 0.02, 2.0, -0.6, -90.0, 1.2, 0.85, "bois_sombre")
	var drap: Transform3D = R.L(0.0, 2.6, -hd + 0.03)
	k.quad(drap * Transform3D(Basis(Vector3.UP, PI), Vector3(1.3, 0, 0)), 0.9, 0.6, "tissu_rouge")
	var voir := func() -> void:
		M.main.sfx("cloche_bateau")
		M.say(str(B._pick(M, ["Dans la longue-vue : les barques qui rentrent, les mouettes qui les suivent, et au loin, une voile noire… La Murène Noire, à quai. « Elle ne bouge pas, dit Hamza. Je la surveille quand même. »", "La mer est calme. Un dauphin saute, deux fois. Hamza note quelque chose dans son carnet : « Dauphin. Deux sauts. Rien à signaler. »"])), 7.0)
	M.act(R.P(lx, 0, lz + 0.7), "E : regarder dans la longue-vue", voir, 0.9)
	B._marchand(M, -0.2, -0.9, 20.0, "bras_croises", "homme", "Caïd Hamza", ["La Skala veille sur Tazira depuis trois cents ans. Moi, depuis vingt. Je fais de mon mieux.", "Un guetteur qui dort, c'est une ville qui tremble.", "Les canons ? Ils n'ont pas tiré depuis cent ans. On les cire quand même."],
		{"bonjour": "Halte ! … Ah, un visiteur. Bienvenue à la Skala.", "infos": ["Le tambour, c'est pour l'alarme. On ne l'a battu qu'une fois : pour l'anniversaire de Lalla Fatima."]})
	var g2: Node = M.person("homme", 0.1, 1.2, 200.0, "assis", "Driss")
	g2.lines = ["Je suis de garde. Avec un thé. Une garde sans thé, ce n'est pas une garde."]
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue à la Skala.", "Entre. Le thé est chaud, la mer est calme."]
	M.ctx["entree"] = "La tour de guet de la Skala : les meurtrières sur la mer, la longue-vue, le râtelier des lances, la pyramide de boulets, le grand tambour d'alarme, et le thé des gardes."


# =================================================================== Tazira : les petits phares de la jetée

static func _phare_jetee(M) -> void:
	var R = M.R
	var k = R.kit
	var vert: bool = str(M.cur.get("nom170", "")).contains("vert")
	var r: float = L1._rond(M, 28.0, 22)
	var coul: String = B._c(R, "phare_vert" if vert else "phare_rouge", Color(0.2, 0.55, 0.3) if vert else Color(0.75, 0.15, 0.12), 0.6)
	k.ring(R.L(0, 1.0, 0), r - 0.05, r - 0.01, 0.2, coul, 22)
	# l'échelle de fer en colimaçon, au milieu, vers la lanterne
	k.cyl(R.L(0, 0, 0), 0.06, 0.06, R.H, "fer", 8)
	for i in range(13):
		var a: float = deg_to_rad(180.0 + i * 30.0)
		k.box(R.L(sin(a) * 0.4, 0.3 * (i + 1) - 0.03, cos(a) * 0.4, rad_to_deg(a)), Vector3(0.28, 0.04, 0.68), "fer", 1.0)
	k.box(R.L(0, R.H - 0.02, 0), Vector3(0.8, 0.04, 0.8), "fer", 1.0)
	k.col_cyl(R.P(0, 0, 0), 0.72, R.H)
	R.reserve(0, 0, 1.6, 1.6)
	for l in R.lights:
		(l as Node3D).global_position = R.P(0, R.H - 1.0, 1.2)
	# les jarres d'huile, le banc, le registre, le rouleau de corde
	for j in range(3):
		var a2: float = deg_to_rad(200.0 + j * 22.0)
		L1._jarre(R, sin(a2) * (r - 0.4), cos(a2) * (r - 0.4), 0.8, "argile69")
	var bxf: Transform3D = L1._sur_rond(M, 125.0, r - 0.3, 0.0)
	k.box(bxf * B.T3(0, 0.42, 0), Vector3(1.0, 0.06, 0.36), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(bxf * B.T3(sx * 0.4, 0.2, 0), Vector3(0.06, 0.4, 0.3), "bois_sombre", 1.0)
	k.box(bxf * B.T3(0.2, 0.47, 0.05), Vector3(0.24, 0.04, 0.3), B._c(R, "registre", Color(0.35, 0.15, 0.1), 0.8), 1.0)
	var rxf: Transform3D = L1._sur_rond(M, 290.0, r - 0.35, 0.0)
	k.ring(rxf * B.T3(0, 0.02, 0), 0.1, 0.28, 0.14, B._tex(R, "corde170", "beau161/corde.png", Color(0.9, 0.8, 0.62)), 16)
	var fen: Transform3D = L1._sur_rond(M, 160.0, r - 0.01, 2.0)
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.cyl(fen * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.22, 0.22, 0.02, B._c(R, "hublot_mer_n" if nuit else "hublot_mer_j", Color(0.1, 0.12, 0.3) if nuit else Color(0.6, 0.8, 1.0), 0.3, 0.0, 0.5 if nuit else 1.4), 16)
	k.ring(fen * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.22, 0.28, 0.05, "cuivre", 16)
	var monter := func() -> void:
		M.say("Tu montes l'échelle de fer jusqu'à la trappe : là-haut, la lanterne %s, ses verres épais, la mèche qu'on allume au coucher du soleil. Le vent siffle dans les vitres." % ("verte" if vert else "rouge"), 6.0)
	M.act(R.P(0.0, 0, 1.0), "E : monter voir la lanterne", monter, 0.9)
	var nom: String = "Si Abdeslam" if vert else "Si Hmed"
	B._marchand(M, 1.0, -0.9, -130.0, "mains_dos", "vieux", nom, ["Vert à tribord, rouge à bâbord : les barques rentrent entre les deux, comme on enfile une aiguille.", "Ma lanterne ne s'est jamais éteinte. Une fois, elle a toussé. C'est tout."],
		{"bonjour": "Bienvenue dans mon phare. Il est petit, mais il voit loin.", "infos": ["L'huile, la mèche, le verre : chaque soir, le même travail. Et chaque matin, les barques rentrent. C'est ça, ma paye."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bienvenue au phare !", "Attention à l'échelle, elle glisse un peu."]
	M.ctx["entree"] = "Le petit phare %s : l'échelle de fer en colimaçon vers la lanterne, les jarres d'huile, le registre des barques, le hublot sur la mer." % ("vert" if vert else "rouge")


# =================================================================== Ramure : les cabanes rondes

## La cabane ronde, vue de dedans : le mur rond, les chevrons du toit ; renvoie le rayon.
static func _hutte(M) -> float:
	var r: float = L1._rond(M, 26.0, 26)
	_chevrons(M, r, 10)
	return r


## Une étagère contre le mur rond (angle a), pleine (sorte : « bocaux », « pains »…).
static func _rayon_rond(M, a: float, r: float, w: float, h: float, rows: int, sorte: String, seed_c: int = 0) -> void:
	var ar: float = deg_to_rad(a)
	B._rayons(M, sin(ar) * (r - 0.24), cos(ar) * (r - 0.24), a + 180.0, w, h, rows, sorte, seed_c)


## Un panier rond posé au sol (des champignons, des baies, des carottes).
static func _panier(M, x: float, z: float, sorte: String) -> void:
	var R = M.R
	var k = R.kit
	var t: String = B._toile(R)
	k.cyl(R.L(x, 0, z), 0.2, 0.26, 0.24, t, 12)
	k.ring(R.L(x, 0.24, z), 0.22, 0.27, 0.03, t, 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 100.0 + z * 7.0)
	for i in range(9):
		var a: float = rng.randf() * TAU
		var d: float = rng.randf() * 0.16
		var p: Vector3 = R.P(x + cos(a) * d, 0.24, z + sin(a) * d)
		match sorte:
			"champignons":
				k.cyl(Transform3D(Basis(), p), 0.015, 0.012, 0.05, "ceramique", 6)
				k.cyl(Transform3D(Basis(), p + Vector3.UP * 0.05), 0.05, 0.0, 0.035, B._c(R, "chapeau_brun", Color(0.55, 0.35, 0.2), 0.7), 8)
			"carottes":
				k.cyl(Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 1.2), p), 0.025, 0.0, 0.18, B._c(R, "carotte172", Color(0.95, 0.45, 0.1), 0.6), 6)
			_:
				Sud._boule(M.room, R.mat(B._c(R, "baie172", Color(0.55, 0.05, 0.25), 0.3)), p + Vector3.UP * 0.02, 0.03)
	k.col_box(R.L(x, 0.13, z), Vector3(0.5, 0.26, 0.5))
	R.reserve(x, z, 0.6, 0.6)


## Le foyer creusé dans le plancher (l'irori) : le cadre, la cendre, les braises, la bouilloire pendue.
static func _irori(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	k.box(R.L(x, 0.04, z), Vector3(0.95, 0.08, 0.95), "bois_sombre", 1.0)
	k.box(R.L(x, 0.06, z), Vector3(0.75, 0.04, 0.75), B._c(R, "cendre172", Color(0.55, 0.52, 0.5), 0.95), 1.0)
	k.box(R.L(x, 0.09, z), Vector3(0.3, 0.04, 0.24), B._c(R, "braises171", Color(1.0, 0.42, 0.12), 0.6, 0.0, 2.2), 1.0)
	R.fire(R.P(x, 0.1, z), 0.25)
	k.cyl(R.L(x, 0.75, z), 0.012, 0.012, R.H - 0.75, "bois_sombre", 6, false)
	k.cyl(R.L(x, 0.48, z), 0.13, 0.11, 0.22, "fer", 12)
	k.cyl(R.L(x, 0.7, z), 0.06, 0.03, 0.05, "fer", 8)
	k.cyl(R.L(x + 0.12, 0.62, z) * Transform3D(Basis(Vector3.BACK, -1.0), Vector3.ZERO), 0.015, 0.01, 0.14, "fer", 6)
	k.col_box(R.L(x, 0.3, z), Vector3(0.95, 0.6, 0.95))
	R.reserve(x, z, 1.1, 1.1)


static func _simples(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _hutte(M)
	for e in [[75.0, 1], [105.0, 3], [255.0, 5], [285.0, 7]]:
		_rayon_rond(M, float(e[0]), r, 1.1, 2.0, 4, "bocaux", int(e[1]))
	_rayon_rond(M, 180.0, r, 1.6, 2.1, 5, "mixte", 2)
	B._herbes(M, -1.7, 1.7, -0.5)
	var zc: float = -1.5
	var cx: Transform3D = B._comptoir(M, 0.0, zc, 2.0, 0.0, false, 0.95, "bois", "bois_clair")
	k.cyl(cx * B.T3(-0.6, 1.01, 0.1), 0.1, 0.08, 0.1, "pierre_lisse", 14)
	k.cyl(cx * Transform3D(Basis(Vector3.BACK, 0.4), Vector3(-0.58, 1.13, 0.1)), 0.018, 0.025, 0.2, "pierre_lisse", 8)
	B._balance(R, cx * B.T3(0.55, 1.01, 0.05))
	B._bocaux(R, cx * B.T3(-0.2, 1.01, 0.18), 3, 0.17, 0.06, 0.2, 4)
	_irori(M, 1.3, 0.9)
	_panier(M, -1.5, 1.2, "champignons")
	_panier(M, -2.0, 0.4, "baies")
	var sentir := func() -> void:
		M.say("Tu respires les bouquets qui sèchent : la menthe, la camomille, le thym… et quelque chose qui sent la pluie. Pivoine sourit : « Ça, c'est l'herbe à rêver. Pour les dormeurs difficiles. »", 6.0)
	M.act(R.P(0.0, 0, 0.3), "E : sentir les herbes qui sèchent", sentir, 1.0)
	B._marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "femme", "Pivoine", ["Une tisane pour chaque peine, une pommade pour chaque bosse.", "Les renards connaissent toutes les herbes du bois. Même celles qui se cachent.", "Ne touche pas au bocal du haut : c'est du poil à gratter."],
		{"bonjour": "Bienvenue aux Simples ! Un remède ? Une tisane ?", "vend": {"tisane_lune": 5, "potion_seve": 14}, "achete": {"champignon": 2, "baies": 1, "fleur_lune": 12}})
	M.ctx["bonjour170"] = ["Bienvenue aux Simples !", "Entre, entre. Ça sent bon, hein ?"]
	M.ctx["entree"] = "L'échoppe des Simples : les bocaux tout autour, les bouquets d'herbes qui sèchent sous le toit, le mortier sur le comptoir, la bouilloire qui chante sur le foyer."


static func _poste_chouettes(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _hutte(M)
	# le mur des casiers (les lettres en attente), au fond
	var cz: float = -(r - 0.4)
	var cw: float = 2.2
	var ch: float = 2.0
	k.box(R.L(0, ch * 0.5, cz - 0.15), Vector3(cw, ch, 0.05), "bois_sombre", 1.0)
	for i in range(7):
		k.box(R.L(-cw * 0.5 + i * cw / 6.0, ch * 0.5, cz), Vector3(0.03, ch, 0.3), "bois", 1.0)
	for j in range(7):
		k.box(R.L(0, 0.02 + j * ch / 6.0, cz), Vector3(cw, 0.03, 0.3), "bois", 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 172
	for i2 in range(6):
		for j2 in range(6):
			if rng.randf() < 0.65:
				var lx: float = -cw * 0.5 + (i2 + 0.5) * cw / 6.0
				var ly: float = 0.04 + j2 * ch / 6.0
				for l in range(1 + rng.randi() % 3):
					k.box(R.L(lx + 0.03 * l - 0.03, ly + 0.11, cz + 0.02) * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3.ZERO), Vector3(0.2, 0.2, 0.01), "papier" if l % 2 == 0 else B._c(R, "enveloppe", Color(0.88, 0.8, 0.62), 0.9), 1.0)
	k.col_box(R.L(0, ch * 0.5, cz), Vector3(cw, ch, 0.35))
	R.reserve(0, cz, cw + 0.2, 0.6)
	# le guichet : la balance, les tampons, les enveloppes
	var zc: float = -1.3
	var cx: Transform3D = B._comptoir(M, 0.0, zc, 1.8, 0.0, false, 1.0, "bois", "bois_clair")
	B._balance(R, cx * B.T3(-0.5, 1.06, 0.05))
	for t in range(3):
		k.cyl(cx * B.T3(0.3 + t * 0.12, 1.06, 0.1), 0.025, 0.025, 0.07, "bois_sombre", 8)
		k.box(cx * B.T3(0.3 + t * 0.12, 1.06, 0.1), Vector3(0.06, 0.02, 0.06), B._c(R, "tampon_%d" % t, [Color(0.7, 0.1, 0.1), Color(0.1, 0.3, 0.7), Color(0.1, 0.5, 0.2)][t], 0.6), 1.0)
	k.box(cx * B.T3(0.0, 1.07, 0.12), Vector3(0.24, 0.02, 0.16), "papier", 1.0)
	# les chouettes sur leurs perchoirs, les colis, la lunette de Hulotte près du hublot
	L1._chouette(M, -1.9, 0.5, 70.0)
	L1._chouette(M, 1.95, 0.2, -70.0)
	for c in range(4):
		k.box(R.L(1.5 + 0.05 * float(c % 2), 0.15 + c * 0.24, -0.9) * Transform3D(Basis(Vector3.UP, 0.3 * c), Vector3.ZERO), Vector3(0.4 - c * 0.05, 0.22, 0.3 - c * 0.03), "carton", 1.0)
	R.reserve(1.5, -0.9, 0.6, 0.6)
	var fen: Transform3D = L1._sur_rond(M, 250.0, r - 0.01, 1.9)
	var h: float = float(M.ctx.get("hour", 12.0))
	var nuit: bool = h >= 20.0 or h < 6.0
	k.cyl(fen * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.3, 0.3, 0.02, B._c(R, "hublot_ciel_n" if nuit else "hublot_ciel_j", Color(0.1, 0.12, 0.3) if nuit else Color(0.6, 0.8, 1.0), 0.3, 0.0, 0.6 if nuit else 1.4), 18)
	k.ring(fen * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.3, 0.36, 0.06, "bois_sombre", 18)
	var tl: Transform3D = L1._sur_rond(M, 250.0, r - 0.75, 0.0)
	for i3 in range(3):
		var a: float = TAU * i3 / 3.0
		k.box(tl * Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 0.22), Vector3(cos(a + PI * 0.5) * 0.12, 0.6, sin(a + PI * 0.5) * 0.12)), Vector3(0.03, 1.25, 0.03), "bois_sombre", 1.0)
	k.cyl(tl * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.35), Vector3(0, 1.25, 0.25)), 0.05, 0.035, 0.7, "cuivre", 12)
	_image_rond(M, B._img(R, "banniere_lune172", "ramure/banniere_lune.png"), 110.0, r, 1.9, 0.7, 1.2)
	var lettre := func() -> void:
		M.main.sfx("clochette")
		M.say("Plumette tamponne ta lettre — clac ! — et la tend à une chouette, qui l'emporte dans son bec par la fenêtre du haut. « Elle arrivera demain. Ou après-demain, si elle croise une souris. »", 7.0)
		M.close_talk()
	B._marchand(M, 0.0, zc - 0.55, 0.0, "comptoir", "femme", "Plumette", ["Une lettre, un colis, une chouette, et hop : ça vole !", "Les chouettes travaillent la nuit. Moi, le jour. On se croise au petit matin.", "Hulotte regarde les étoiles. Moi, je regarde les adresses."],
		{"bonjour": "Bienvenue à la Poste des chouettes ! Une lettre à envoyer ?", "services": [{"label": "Envoyer une lettre", "cb": lettre}]})
	B._habitue(M, "hulotte", sin(deg_to_rad(250.0)) * (r - 1.25), cos(deg_to_rad(250.0)) * (r - 1.25), 250.0, "observer", ["La lune est toujours pleine à Ramure. C'est pratique pour lire les cartes du ciel.", "Cette nuit, j'ai vu une comète. Ou une luciole très pressée."])
	M.act(R.P(0.0, 0, zc + 0.9), "E : regarder les lettres en attente", func(): M.say("Des dizaines de lettres attendent dans les casiers : « Pour Bedaine, au Grand Troc », « Pour Mère-Lune, très urgent (c'est une recette) », « Pour toi, qui lis par-dessus mon épaule »… Tiens, tiens.", 7.0), 1.0)
	M.ctx["bonjour170"] = ["Bienvenue à la Poste !", "Hou-hou ! … Pardon, l'habitude."]
	M.ctx["entree"] = "La Poste des chouettes : le grand mur des casiers et ses lettres, le guichet et ses tampons, les chouettes sur leurs perchoirs, la lunette de Hulotte près du hublot."


static func _boulangerie_lapins(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _hutte(M)
	L1._four(M, -1.4, -2.1)
	for e in [[100.0, 0], [128.0, 2]]:
		_rayon_rond(M, float(e[0]), r, 1.2, 1.8, 4, "pains", int(e[1]))
	# le comptoir : les gâteaux de lune, les gâteaux aux carottes, les petits pains
	var zc: float = -0.9
	var cx: Transform3D = B._comptoir(M, 0.7, zc, 2.0, 0.0, false, 0.95, "bois", "bois_clair")
	var dore: String = B._c(R, "gateau_lune172", Color(0.88, 0.62, 0.28), 0.7)
	for g in range(4):
		k.cyl(cx * B.T3(-0.75 + g * 0.17, 1.01, 0.05), 0.07, 0.07, 0.04, dore, 14)
		k.ring(cx * B.T3(-0.75 + g * 0.17, 1.05, 0.05), 0.03, 0.05, 0.004, B._c(R, "lapin_dore", Color(0.7, 0.45, 0.2), 0.7), 12)
	for c in range(3):
		k.cyl(cx * B.T3(0.05 + c * 0.22, 1.01, 0.08), 0.09, 0.09, 0.09, B._c(R, "gateau_carotte", Color(0.92, 0.5, 0.18), 0.7), 14)
		k.cyl(cx * B.T3(0.05 + c * 0.22, 1.1, 0.08), 0.09, 0.08, 0.02, B._c(R, "glacage", Color(0.98, 0.96, 0.9), 0.4), 14)
		k.cyl(cx * B.T3(0.05 + c * 0.22, 1.12, 0.08), 0.008, 0.0, 0.05, B._c(R, "carotte172", Color(0.95, 0.45, 0.1), 0.6), 5)
	k.cyl(cx * B.T3(0.75, 1.01, 0.05), 0.16, 0.2, 0.08, B._toile(R), 14)
	B._sac(R, -2.3, 0.4, Color(0.95, 0.93, 0.88), 0.9)
	B._sac(R, -2.4, 1.1, Color(0.95, 0.93, 0.88), 0.8)
	_panier(M, 2.3, 0.9, "carottes")
	R.table(1.6, 1.5, 90.0, 1.1, 0.6, 0.85)
	for d in range(4):
		Sud._boule(M.room, R.mat(B._c(R, "pate172", Color(0.96, 0.9, 0.78), 0.8)), R.P(1.5 + 0.1 * float(d % 2), 0.92, 1.2 + d * 0.18), 0.07, Vector3(1.0, 0.7, 1.0))
	k.cyl(R.L(1.75, 0.89, 1.5) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.25)), 0.035, 0.035, 0.5, "bois_clair", 10)
	# Mochi goûte un gâteau, à sa petite table
	R.table_ronde(-0.85, 0.85, 0.4, 0.72)
	k.cyl(R.L(-0.85, 0.72, 0.85), 0.07, 0.07, 0.04, dore, 14)
	R.chaise(-1.15, 1.4, 150.0, "rose")
	B._habitue(M, "mochi", -1.15, 1.4, 150.0, "manger", ["Maman fait les meilleurs gâteaux de lune du monde. J'en ai mangé trois. Chut.", "Quand je serai grande, je ferai des gâteaux aux carottes ET au chocolat. Les deux en même temps."])
	var gouter := func() -> void:
		M.main.sfx("clochette")
		M.say("Trèfle te tend un petit gâteau de lune encore tiède. Dessus, un lapin dessiné dans la pâte. C'est doux, ça sent le miel et la châtaigne.", 6.0)
	M.act(R.P(0.7, 0, zc + 0.9), "E : goûter un gâteau de lune", gouter, 1.0)
	B._marchand(M, 0.7, zc - 0.55, 0.0, "comptoir", "femme", "Trèfle", ["Le four est chaud depuis l'aube. Les lapins se lèvent tôt.", "Les carottes du potager, la farine du moulin, et un peu de lune. Voilà le secret.", "Mochi ! Laisse-en un peu pour les clients !"],
		{"bonjour": "Bienvenue à la boulangerie ! Tout est encore chaud.", "vend": {"gateau_lune": 6, "pain_carotte": 3}})
	M.ctx["bonjour170"] = ["Bienvenue ! Ça sort du four !", "Entre, entre. Mochi, dis bonjour !"]
	M.ctx["entree"] = "La boulangerie des lapins : le four en coupole, les étagères de pains, les gâteaux de lune et les gâteaux aux carottes, la table où l'on pétrit… et Mochi qui goûte."


## Un filet de pêche tendu contre le mur rond (les mailles, les flotteurs de liège).
static func _filet(M, a: float, r: float, y: float, w: float, h: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = L1._sur_rond(M, a, r - 0.05, y)
	var corde: String = B._c(R, "maille", Color(0.55, 0.48, 0.38), 0.95)
	var n: int = int(w / 0.12)
	for i in range(n + 1):
		k.box(xf * B.T3(-w * 0.5 + i * w / n, 0, 0.01), Vector3(0.008, h, 0.008), corde, 1.0)
	var m: int = int(h / 0.12)
	for j in range(m + 1):
		k.box(xf * B.T3(0, -h * 0.5 + j * h / m, 0.01), Vector3(w, 0.008, 0.008), corde, 1.0)
	for f in range(5):
		Sud._boule(M.room, R.mat(B._c(R, "liege", Color(0.8, 0.6, 0.35), 0.9)), xf * Vector3(-w * 0.4 + f * w * 0.2, h * 0.5, 0.04), 0.04)


static func _pecherie_chats(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = _hutte(M)
	_filet(M, 95.0, r, 1.6, 1.4, 1.2)
	_filet(M, 265.0, r, 1.7, 1.2, 1.1)
	# les poissons qui sèchent, pendus à une perche
	k.cyl(R.L(0, 2.3, -0.7) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(1.7, 0, 0)), 0.025, 0.025, 3.4, "bois_sombre", 6)
	var cols: Array = [Color(0.6, 0.65, 0.72), Color(0.75, 0.6, 0.4), Color(0.45, 0.55, 0.6), Color(0.8, 0.7, 0.5)]
	for p in range(8):
		var px: float = -1.4 + p * 0.4
		k.cyl(R.L(px, 2.1, -0.7), 0.004, 0.004, 0.2, "fer", 3, false)
		B._poisson(R, R.L(px, 2.08, -0.7) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), cols[p % cols.size()], 0.3)
	# les cannes à pêche contre le mur, les seaux, le tonneau, le petit poêle et la soupe de poisson
	for c in range(3):
		var cx: Transform3D = L1._sur_rond(M, 200.0 + c * 7.0, r - 0.2, 0.0)
		k.cyl(cx * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3.ZERO), 0.015, 0.008, 2.6, "bois", 6)
	R.tonneau(sin(deg_to_rad(140.0)) * (r - 0.5), cos(deg_to_rad(140.0)) * (r - 0.5))
	for s in range(2):
		var sx: float = -0.6 + s * 0.45
		k.cyl(R.L(sx, 0, -2.2), 0.16, 0.2, 0.32, "metal", 12, false)
		k.disc(R.L(sx, 0.26, -2.2), 0.17, L1._m(R, "eau69"), 12)
	var px2: float = 1.6
	var pz2: float = -1.6
	k.cyl(R.L(px2, 0, pz2), 0.25, 0.28, 0.6, "fer", 12)
	k.cyl(R.L(px2, 0.6, pz2), 0.16, 0.14, 0.18, "cuivre", 12)
	k.cyl(R.L(px2, 0.6, pz2), 0.05, 0.05, R.H - 0.6, "fer", 6, false)
	k.col_box(R.L(px2, 0.35, pz2), Vector3(0.6, 0.7, 0.6))
	R.reserve(px2, pz2, 0.7, 0.7)
	B._lampe(M, px2, 0.5, pz2, Color(1.0, 0.55, 0.25), 0.5, 2.5)
	# le panier du chaton
	var bx: float = -1.2
	var bz: float = 1.3
	k.cyl(R.L(bx, 0, bz), 0.3, 0.34, 0.16, B._toile(R), 14)
	k.ring(R.L(bx, 0.16, bz), 0.27, 0.34, 0.04, B._toile(R), 14)
	k.cyl(R.L(bx, 0.03, bz), 0.27, 0.27, 0.08, "tissu_rouge", 14)
	R.chat(bx, bz, 40.0, Color(0.95, 0.65, 0.3), true, 0.11)
	R.reserve(bx, bz, 0.8, 0.8)
	# Caramel ravaude ses filets ; Moustache répare une canne ; Myrtille joue près du panier
	k.box(R.L(0.9, 0.21, -1.1), Vector3(0.4, 0.42, 0.38), "bois", 1.0)
	k.box(R.L(0.9, 0.05, -0.6), Vector3(0.6, 0.06, 0.5), B._c(R, "maille", Color(0.55, 0.48, 0.38), 0.95), 1.0)
	var caresser := func() -> void:
		M.main.sfx("clochette")
		M.say("Tu caresses le chaton roux. Il ronronne sans ouvrir les yeux, et étire une patte. Caramel chuchote : « Il s'appelle Sardine. Il ne pêche pas. Il mange. »", 6.0)
	M.act(R.P(bx + 0.7, 0, bz), "E : caresser le chaton", caresser, 1.0)
	B._marchand(M, 0.9, -1.1, 20.0, "tricot", "femme", "Caramel", ["Un filet, c'est des trous attachés ensemble. Moi, je répare les trous.", "Le poisson du jour ? Il était encore dans la mare ce matin.", "Moustache dit qu'il a pris un brochet géant. Le brochet, lui, ne dit rien."],
		{"bonjour": "Bienvenue à la pêcherie ! Ça sent le poisson, hein ? C'est normal.", "vend": {"sardine": 1, "maquereau": 3, "brochette_poisson": 4}})
	R.table(-1.6, -1.2, 40.0, 1.0, 0.5, 0.85)
	k.cyl(R.L(-1.6, 0.86, -1.2) * Transform3D(Basis(Vector3.UP, deg_to_rad(40.0)) * Basis(Vector3.BACK, PI * 0.5), Vector3(0.4, 0, 0)), 0.012, 0.008, 0.8, "bois", 6)
	B._habitue(M, "moustache", -1.6 + sin(deg_to_rad(220.0)) * -0.62, -1.2 + cos(deg_to_rad(220.0)) * -0.62, 220.0, "bricoler", ["J'ai pris un brochet grand comme ça ! … Bon, comme ça. Bon, d'accord : comme ça.", "Une canne, c'est comme une moustache : il faut la soigner."])
	B._habitue(M, "myrtille", -0.55, 1.6, 230.0, "rire", ["Sardine dort tout le temps ! Moi je veux jouer !", "Un jour, je pêcherai la plus grosse sardine de la mare. Et je la mangerai. Non, je la relâcherai. Non, je la mangerai."])
	M.ctx["bonjour170"] = ["Bienvenue à la pêcherie !", "Entre ! Attention aux filets par terre."]
	M.ctx["entree"] = "La pêcherie des chats : les filets tendus aux murs, les poissons qui sèchent sous le toit, les cannes à pêche, la soupe qui mijote… et Sardine, le chaton, qui dort dans son panier."


# =================================================================== Port-Boucan : le bureau de vente de Lisse & Fils

static func _bureau_lisse(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	# le bureau du directeur : la table, le fauteuil, la tablette, le stylo doré, la plaque
	var dx: float = 2.9
	var dz: float = -1.4
	R.table(dx, dz, 0.0, 1.7, 0.75, 0.76)
	R.chaise(dx, dz - 0.55, 0.0, "noir")
	k.box(R.L(dx - 0.3, 0.775, dz - 0.05), Vector3(0.36, 0.015, 0.26), "noir", 1.0)
	k.box(R.L(dx - 0.3, 0.784, dz - 0.05), Vector3(0.32, 0.003, 0.22), B._c(R, "ecran172", Color(0.35, 0.55, 0.85), 0.3, 0.0, 1.2), 1.0)
	k.cyl(R.L(dx + 0.35, 0.77, dz + 0.1) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.006, 0.006, 0.14, "or", 6)
	k.box(R.L(dx + 0.45, 0.8, dz + 0.3), Vector3(0.42, 0.06, 0.06), "or", 1.0)
	B._ecrit(M, dx + 0.45, 0.8, dz + 0.335, 0.0, "A. LISSE — DIRECTEUR", 22, Color(0.15, 0.12, 0.08), 0.0017, 0.0)
	for p in range(4):
		k.box(R.L(dx + 0.1 + 0.02 * p, 0.77 + p * 0.004, dz - 0.15, -6.0 + p * 4.0), Vector3(0.22, 0.004, 0.3), "papier", 1.0)
	# la maquette du Lisse-Center, sous sa cloche de verre
	var mx: float = -1.3
	var mz: float = -0.5
	R.table(mx, mz, 0.0, 2.2, 1.2, 0.85)
	var gris: String = B._c(R, "maquette_gris", Color(0.82, 0.82, 0.84), 0.5)
	var blanc: String = B._c(R, "maquette_blanc", Color(0.96, 0.96, 0.96), 0.4)
	var y0: float = 0.87
	k.box(R.L(mx, y0, mz), Vector3(2.0, 0.03, 1.0), gris, 1.0)
	k.box(R.L(mx + 0.55, y0 + 0.017, mz + 0.15), Vector3(0.8, 0.005, 0.6), B._c(R, "asphalte172", Color(0.2, 0.2, 0.22), 0.8), 1.0)
	for l in range(6):
		k.box(R.L(mx + 0.2 + l * 0.13, y0 + 0.021, mz + 0.15), Vector3(0.01, 0.002, 0.5), blanc, 1.0)
	for b in [[-0.6, -0.2, 0.5, 0.3, 0.35], [-0.2, -0.25, 0.3, 0.55, 0.25], [-0.65, 0.2, 0.35, 0.18, 0.4], [0.3, -0.3, 0.4, 0.22, 0.3], [-0.25, 0.25, 0.25, 0.35, 0.22]]:
		var bh: float = float(b[3])
		k.box(R.L(mx + float(b[0]), y0 + 0.015 + bh * 0.5, mz + float(b[1])), Vector3(float(b[2]), bh, float(b[4])), blanc if bh > 0.3 else gris, 1.0)
		k.box(R.L(mx + float(b[0]), y0 + 0.015 + bh * 0.6, mz + float(b[1]) + float(b[4]) * 0.5 + 0.002), Vector3(float(b[2]) * 0.9, bh * 0.08, 0.003), B._c(R, "vitres_maquette", Color(0.4, 0.6, 0.8), 0.2, 0.3), 1.0)
	k.disc(R.L(mx - 0.1, y0 + 0.02, mz + 0.4), 0.08, B._c(R, "fontaine_maquette", Color(0.3, 0.6, 0.9), 0.2), 12)
	for t in range(6):
		Sud._boule(M.room, R.mat(B._c(R, "arbre_maquette", Color(0.35, 0.6, 0.3), 0.8)), R.P(mx - 0.9 + t * 0.12, y0 + 0.05, mz + 0.42), 0.035)
	k.box(R.L(mx, y0 + 0.35, mz), Vector3(2.04, 0.66, 1.04), B._verre(R, "cloche_maquette", Color(0.85, 0.92, 0.95), 0.15), 1.0)
	B._ecrit(M, mx, 0.7, mz + 0.61, 0.0, "LISSE-CENTER\nquatre cents boutiques — deux mille places", 26, Color(0.9, 0.75, 0.3), 0.0022, 0.0)
	# les affiches, l'enseigne ; la fontaine à eau, la machine à café, la plante en plastique, les brochures
	var pan: String = _mb(R, "panneau75_lisse")
	k.quad(R.L(-1.3, 1.75, -hd + 0.02) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.2, 1.1, pan)
	R.mark_wall(-1.3, 1.75, -hd, 1.1)
	var ens: String = _mb(R, "enseigne75_lisse")
	k.quad(R.L(-hw + 0.02, 1.9, 0.0, 90.0) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 2.2, 0.32, ens)
	R.mark_wall(-hw, 1.9, 0.0, 1.1)
	var wx: float = -hw + 0.4
	var wz: float = -1.6
	k.box(R.L(wx, 0.5, wz), Vector3(0.36, 1.0, 0.36), blanc, 1.0)
	k.cyl(R.L(wx, 1.0, wz), 0.15, 0.15, 0.38, B._verre(R, "bonbonne", Color(0.4, 0.65, 0.95), 0.45), 14)
	k.cyl(R.L(wx, 1.38, wz), 0.15, 0.05, 0.08, B._verre(R, "bonbonne", Color(0.4, 0.65, 0.95), 0.45), 14)
	k.col_box(R.L(wx, 0.7, wz), Vector3(0.4, 1.4, 0.4))
	R.reserve(wx, wz, 0.6, 0.6)
	k.box(R.L(-hw + 0.35, 0.45, 0.9), Vector3(0.5, 0.9, 0.6), "bois_sombre", 1.0)
	k.box(R.L(-hw + 0.35, 1.08, 0.9), Vector3(0.28, 0.36, 0.3), "noir", 1.0)
	k.cyl(R.L(-hw + 0.4, 0.9, 1.0), 0.04, 0.035, 0.09, "ceramique", 10)
	k.col_box(R.L(-hw + 0.35, 0.6, 0.9), Vector3(0.5, 1.2, 0.6))
	R.reserve(-hw + 0.35, 0.9, 0.7, 0.8)
	R.plante(hw - 0.45, -hd + 0.45, 0.0, 1.3)
	R.plante(-hw + 0.45, 1.8, 0.0, 1.1)
	var bx: float = hw - 0.3
	k.box(R.L(bx, 0.7, 0.6, -90.0), Vector3(0.7, 1.4, 0.06), "metal", 1.0)
	for s in range(3):
		for c in range(3):
			k.box(R.L(bx - 0.06, 0.4 + s * 0.4, 0.4 + c * 0.2, -90.0) * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3.ZERO), Vector3(0.16, 0.24, 0.015), B._c(R, "brochure_%d" % ((s + c) % 3), [Color(0.95, 0.95, 0.95), Color(0.85, 0.75, 0.3), Color(0.6, 0.6, 0.65)][(s + c) % 3], 0.4), 1.0)
	R.mark_wall(hw, 0.9, 0.6, 0.4)
	var maquette := func() -> void:
		M.say("Sous la cloche de verre, le Lisse-Center : des tours blanches, un parking grand comme une mer, une fontaine qui joue un hymne. Là où sont la Halle, la Conserverie et les Jardins… il n'y a plus que des places de parking. Gédéon détourne les yeux.", 7.0)
	M.act(R.P(mx, 0, mz + 1.0), "E : regarder la maquette du Lisse-Center", maquette, 1.0)
	B._marchand(M, dx, dz - 0.55, 0.0, "assis", "homme", "Monsieur Lisse", ["Le progrès n'attend pas. Moi non plus. Asseyez-vous. Ou plutôt, non : je suis pressé.", "Quatre cents boutiques ! Et pas une seule gratuiterie. Enfin un endroit sérieux.", "Signez ici, ici et ici. Non, ne lisez pas, c'est inutile."],
		{"bonjour": "Lisse & Fils, bonjour. Vous venez pour un appartement témoin ?", "infos": ["Le Lisse-Center, c'est l'avenir : propre, lisse, sans graffitis. Sans musique non plus. C'est plus calme."]})
	B._habitue(M, "gedeon", -3.4, 1.2, 140.0, "holo", ["Papa dit que je reprendrai l'entreprise. Moi, je voudrais faire de la musique. Chut.", "J'ai mis mes écouteurs. Je n'écoute pas Papa. J'écoute les Rats de Cale."])
	var pr: Node = M.person("femme", 1.5, -0.5, 210.0, "bras_croises", "Mademoiselle Prune")
	pr.lines = ["Monsieur Lisse a rendez-vous à quatorze heures, à quatorze heures quinze, et à quatorze heures quinze et demie.", "Une brochure ? Elle est très brillante. On voit son reflet dedans."]
	M.ctx["cloche170"] = true
	M.ctx["bonjour170"] = ["Lisse & Fils, bonjour.", "Entrez, entrez. Ne touchez pas à la maquette."]
	M.ctx["entree"] = "Le bureau de vente de Lisse & Fils : la moquette grise, les affiches « BIENTÔT ICI », la maquette du Lisse-Center sous sa cloche de verre, et Monsieur Lisse derrière son grand bureau."


# =================================================================== Port-Boucan : la roulotte de Mère Morille

## Les arceaux de la voûte d'une roulotte (le long de z), d'une couleur.
static func _arceaux(M, key: String, n: int = 5) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	for i in range(n):
		var z: float = -hd + 0.45 + i * (R.D - 0.9) / maxf(1.0, n - 1)
		for j in range(6):
			var a0: float = PI * j / 6.0
			var a1: float = PI * (j + 1) / 6.0
			var p0 := Vector3(cos(a0) * hw, R.H - 0.55 + sin(a0) * 0.5, z)
			var p1 := Vector3(cos(a1) * hw, R.H - 0.55 + sin(a1) * 0.5, z)
			var mid: Vector3 = (p0 + p1) * 0.5
			var d: Vector3 = p1 - p0
			k.box(R.L(mid.x, mid.y, mid.z) * Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)), Vector3.ZERO), Vector3(d.length() + 0.02, 0.07, 0.07), key, 1.0)


static func _roulotte_morille(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_arceaux(M, B._c(R, "arceau_jaune", Color(0.9, 0.72, 0.2), 0.6))
	# l'alcôve du lit et son édredon en patchwork, l'oreiller champignon
	var bz: float = -hd + 0.45
	k.box(R.L(0, 0.25, bz), Vector3(R.W, 0.5, 0.9), "bois", 1.0)
	for p in range(6):
		k.box(R.L(-hw + 0.3 + p * (R.W - 0.6) / 5.0, 0.56, bz + 0.05), Vector3((R.W - 0.1) / 6.0, 0.1, 0.8), "tissu_" + ["rouge", "jaune", "violet", "vert", "orange", "bleu"][p], 1.0)
	var chap: String = _mb(R, "chapeau75_violet")
	k.cyl(R.L(-1.0, 0.62, bz - 0.15), 0.18, 0.04, 0.12, chap, 14)
	k.cyl(R.L(-1.0, 0.6, bz - 0.15), 0.18, 0.18, 0.02, _mb(R, "lamelles75_violet"), 14)
	k.col_box(R.L(0, 0.3, bz), Vector3(R.W, 0.6, 0.9))
	R.reserve(0, bz, R.W, 1.0)
	# l'étagère des bocaux de champignons qui luisent, les guirlandes de champignons séchés
	for row in range(3):
		var sy: float = 0.9 + row * 0.42
		k.box(R.L(hw - 0.17, sy, 0.4), Vector3(0.3, 0.03, 1.6), "bois", 1.0)
		for j2 in range(4):
			var jz: float = -0.25 + j2 * 0.42
			k.cyl(R.L(hw - 0.17, sy + 0.015, jz), 0.07, 0.07, 0.2, B._verre(R, "bocal_morille", Color(0.85, 0.95, 0.95), 0.3), 10)
			var cc: String = _mb(R, "chapeau75_" + ["bleu", "violet", "orange"][(j2 + row) % 3])
			k.cyl(R.L(hw - 0.17, sy + 0.05, jz), 0.012, 0.01, 0.06, _mb(R, "pied75"), 6)
			k.cyl(R.L(hw - 0.17, sy + 0.11, jz), 0.05, 0.0, 0.04, cc, 8)
	k.col_box(R.L(hw - 0.17, 1.3, 0.4), Vector3(0.3, 1.0, 1.6))
	B._lampe(M, hw - 0.5, 1.4, 0.4, Color(0.55, 0.65, 1.0), 0.5, 2.5)
	for gz in [-0.6, 0.8]:
		k.cyl(R.L(0, R.H - 0.62, gz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(hw - 0.2, 0, 0)), 0.006, 0.006, R.W - 0.4, "fer", 4, false)
		for g in range(7):
			var gx: float = -hw + 0.45 + g * 0.4
			k.cyl(R.L(gx, R.H - 0.78, gz), 0.004, 0.004, 0.16, "fer", 3, false)
			k.cyl(R.L(gx, R.H - 0.84, gz), 0.06, 0.0, 0.05, B._c(R, "champi_seche", Color(0.62, 0.45, 0.3), 0.8), 8)
	# la petite table, la théière de tisane, le tabouret champignon du visiteur
	var tz: float = -0.75
	R.table_ronde(0, tz, 0.4, 0.7)
	k.cyl(R.L(0.12, 0.7, tz), 0.08, 0.1, 0.12, "ceramique", 12)
	k.cyl(R.L(0.12, 0.82, tz), 0.06, 0.02, 0.05, "ceramique", 10)
	k.cyl(R.L(-0.15, 0.7, tz + 0.1), 0.04, 0.035, 0.07, "ceramique", 8)
	k.cyl(R.L(0, 0, 0.0), 0.12, 0.1, 0.36, _mb(R, "pied75"), 10)
	k.cyl(R.L(0, 0.36, 0.0), 0.26, 0.22, 0.12, _mb(R, "chapeau75_orange"), 14)
	k.cyl(R.L(0, 0, -1.4), 0.16, 0.16, 0.42, "bois", 10)
	k.cyl(R.L(0, 0.42, -1.4), 0.19, 0.19, 0.04, "tissu_violet", 12)
	# le terrarium et son escargot, le petit poêle
	var tx: float = -hw + 0.3
	k.box(R.L(tx, 0.85, 0.9), Vector3(0.36, 0.04, 0.6), "bois", 1.0)
	k.box(R.L(tx, 1.03, 0.9), Vector3(0.32, 0.32, 0.5), B._verre(R, "terrarium", Color(0.85, 0.95, 0.9), 0.2), 1.0)
	k.box(R.L(tx, 0.9, 0.9), Vector3(0.3, 0.06, 0.48), B._c(R, "mousse172", Color(0.25, 0.45, 0.2), 0.95), 1.0)
	k.ring(R.L(tx, 0.96, 0.95) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.015, 0.045, 0.03, B._c(R, "coquille", Color(0.6, 0.42, 0.25), 0.5), 12)
	k.box(R.L(tx, 0.94, 0.88), Vector3(0.03, 0.02, 0.1), B._c(R, "escargot", Color(0.7, 0.62, 0.5), 0.4), 1.0)
	k.cyl(R.L(-hw + 0.4, 0, hd - 1.0), 0.18, 0.2, 0.5, "fer", 12)
	k.cyl(R.L(-hw + 0.4, 0.5, hd - 1.0), 0.1, 0.09, 0.1, "cuivre", 10)
	k.col_box(R.L(-hw + 0.4, 0.25, hd - 1.0), Vector3(0.4, 0.5, 0.4))
	R.reserve(-hw + 0.4, hd - 1.0, 0.5, 0.5)
	var ecouter := func() -> void:
		M.say("Mère Morille baisse la voix : « Sous nos pieds, les champignons se parlent. Des fils fins comme des cheveux, d'un arbre à l'autre, sous toute la ville. Quand un arbre a soif, les autres lui passent de l'eau. On ferait bien de faire pareil. »", 8.0)
		M.close_talk()
	B._marchand(M, 0, -1.4, 0.0, "assis", "vieille", "Mère Morille", ["Les champignons ne sont pas des plantes, mon petit. Ni des bêtes. Ce sont des champignons.", "Ne mange jamais un champignon que tu ne connais pas. Même s'il est poli.", "La tisane ? Du thym, de la mélisse, et un peu de patience."],
		{"bonjour": "Entre, mon petit, entre. Assieds-toi sur le tabouret, il ne mord pas.", "services": [{"label": "Écouter Mère Morille parler des champignons", "cb": ecouter}], "vend": {"tisane_lune": 5}})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Ah, de la visite ! Les spores me l'avaient dit.", "Entre, mon petit. La tisane est chaude."]
	M.ctx["entree"] = "La roulotte de Mère Morille : les bocaux de champignons qui luisent, les guirlandes de champignons séchés, l'édredon en patchwork, le tabouret champignon, et l'escargot dans son terrarium."


# =================================================================== Port-Boucan : le phare tagué

static func _phare_tague(M) -> void:
	var R = M.R
	var k = R.kit
	var r: float = L1._rond(M, 26.0, 26)
	# les graffitis sur le mur rond
	var tags: Array = [[60.0, 1.6, 1, 1.6], [95.0, 3.2, 4, 1.8], [130.0, 1.4, 7, 1.4], [165.0, 2.9, 2, 2.0], [205.0, 1.5, 9, 1.6], [290.0, 3.0, 11, 1.7], [320.0, 1.5, 5, 1.4]]
	for t in tags:
		_image_rond(M, _mb(R, "graffiti75_%d" % int(t[2])), float(t[0]), r, float(t[1]), float(t[3]), float(t[3]) * 0.55)
	# l'escalier de fer en colimaçon vers la lanterne
	k.cyl(R.L(0, 0, 0), 0.08, 0.08, R.H, "fer", 8)
	for i in range(16):
		var a: float = deg_to_rad(200.0 + i * 26.0)
		k.box(R.L(sin(a) * 0.55, 0.3 * (i + 1) - 0.03, cos(a) * 0.55, rad_to_deg(a)), Vector3(0.34, 0.05, 0.95), "fer", 1.0)
	k.box(R.L(0, R.H - 0.02, 0), Vector3(1.1, 0.04, 1.1), "fer", 1.0)
	k.col_cyl(R.P(0, 0, 0), 1.0, R.H)
	R.reserve(0, 0, 2.2, 2.2)
	for l in R.lights:
		(l as Node3D).global_position = R.P(0, R.H - 1.2, 1.8)
	# la fresque en cours de Pigment (et son escabeau), les bombes de peinture sur la palette
	var fa: float = 250.0
	_image_rond(M, _mb(R, "graffiti75_12"), fa, r, 2.0, 2.4, 1.6)
	var esc: Transform3D = L1._sur_rond(M, fa + 22.0, r - 0.6, 0.0)
	for s in [-1.0, 1.0]:
		k.box(esc * Transform3D(Basis(Vector3.RIGHT, s * 0.22), Vector3(0, 0.7, s * 0.15)) * B.T3(-0.2, 0, 0), Vector3(0.04, 1.45, 0.04), "metal", 1.0)
		k.box(esc * Transform3D(Basis(Vector3.RIGHT, s * 0.22), Vector3(0, 0.7, s * 0.15)) * B.T3(0.2, 0, 0), Vector3(0.04, 1.45, 0.04), "metal", 1.0)
	for g in range(4):
		k.box(esc * B.T3(0, 0.3 + g * 0.35, 0.15 - g * 0.05), Vector3(0.44, 0.03, 0.1), "metal", 1.0)
	var pal: Transform3D = L1._sur_rond(M, 215.0, r - 0.9, 0.0)
	k.box(pal * B.T3(0, 0.07, 0), Vector3(1.0, 0.14, 0.7), B._tex(R, "palette172", "boucan/lamelles.png", Color(0.8, 0.65, 0.45), 0.9), 0.6)
	for b in range(9):
		var cc: Color = B.TEINTES[b % B.TEINTES.size()]
		var bpx: float = -0.35 + (b % 5) * 0.17
		var bpz: float = -0.15 + (b / 5) * 0.25
		k.cyl(pal * B.T3(bpx, 0.14, bpz), 0.035, 0.035, 0.17, B._c(R, "bombe_%d" % (b % B.TEINTES.size()), cc, 0.35, 0.5), 10)
		k.cyl(pal * B.T3(bpx, 0.31, bpz), 0.02, 0.02, 0.03, "noir", 6)
	k.col_box(pal * B.T3(0, 0.1, 0), Vector3(1.0, 0.2, 0.7))
	# le canapé de palettes, ses coussins ; le poste à musique ; la guirlande de lumières
	var cap: Transform3D = L1._sur_rond(M, 120.0, r - 0.55, 0.0)
	k.box(cap * B.T3(0, 0.15, 0), Vector3(1.6, 0.3, 0.75), B._tex(R, "palette172", "boucan/lamelles.png", Color(0.8, 0.65, 0.45), 0.9), 0.6)
	k.box(cap * B.T3(0, 0.36, 0.02), Vector3(1.5, 0.12, 0.65), "tissu_orange", 1.0)
	k.box(cap * B.T3(0, 0.62, -0.32), Vector3(1.5, 0.45, 0.12), "tissu_bleu", 1.0)
	k.col_box(cap * B.T3(0, 0.3, 0), Vector3(1.6, 0.6, 0.75))
	var bb: Transform3D = L1._sur_rond(M, 150.0, r - 0.4, 0.0)
	k.box(bb * B.T3(0, 0.2, 0), Vector3(0.45, 0.4, 0.4), "carton", 1.0)
	k.box(bb * B.T3(0, 0.52, 0), Vector3(0.5, 0.24, 0.16), "noir", 1.0)
	for sp in [-1.0, 1.0]:
		k.cyl(bb * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sp * 0.14, 0.52, 0.08)), 0.07, 0.07, 0.01, "metal", 12)
	var n: int = 22
	for i2 in range(n):
		var a2: float = TAU * i2 / n
		var c2: Color = [Color(1.0, 0.3, 0.3), Color(1.0, 0.85, 0.2), Color(0.3, 0.9, 0.4), Color(0.3, 0.6, 1.0), Color(0.9, 0.4, 1.0)][i2 % 5]
		Sud._boule(M.room, R.mat(B._c(R, "ampoule_%d" % (i2 % 5), c2, 0.3, 0.0, 2.0)), R.P(sin(a2) * (r - 0.3), R.H - 0.7 - 0.15 * absf(sin(a2 * 3.0)), cos(a2) * (r - 0.3)), 0.035)
	B._lampe(M, 0.0, R.H - 0.8, -1.5, Color(1.0, 0.75, 0.6), 0.6, 6.0)
	var regarder := func() -> void:
		M.say("La fresque de Pigment : une baleine qui avale le Lisse-Center tout entier, et qui recrache des fleurs, des vélos et des guitares. La peinture est encore fraîche. Pigment te tend une bombe jaune : « Une étoile, là, dans le coin. Allez. »", 8.0)
	M.act(R.P(sin(deg_to_rad(fa)) * (r - 1.5), 0, cos(deg_to_rad(fa)) * (r - 1.5)), "E : regarder la fresque de Pigment", regarder, 1.1)
	B._marchand(M, sin(deg_to_rad(fa)) * (r - 0.9), cos(deg_to_rad(fa)) * (r - 0.9), fa, "peindre", "femme", "Pigment", ["Un mur gris, c'est une page blanche qui s'ennuie.", "Le phare, c'est ma galerie. Le seul musée de Port-Boucan où l'on entre sans payer.", "Attention, c'est frais ! … Trop tard. Bon, ta manche est jolie, maintenant."],
		{"bonjour": "Salut ! Bienvenue dans ma galerie. Ne touche pas, ça colle.", "infos": ["Au-dessus, la lanterne tourne encore, la nuit. Personne ne sait qui l'allume. Moi je dis que c'est le phare tout seul."]})
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Salut ! Fais pas attention à l'odeur de peinture.", "Entre ! Tu tombes bien, j'ai besoin d'un avis."]
	M.ctx["entree"] = "Le phare tagué : des graffitis du sol au plafond, l'escalier de fer en colimaçon, le canapé de palettes, les bombes de peinture, la guirlande de lumières… et Pigment, perchée devant sa fresque."

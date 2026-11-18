extends RefCounted
## V175 : les derniers bâtiments où l'on n'entrait pas.
##  - À Néopolis, l'Arcade du Dragon-Pixel : la moquette « cosmique » qui luit sous la lumière noire, les
##    néons du plafond, les rangées de bornes (Dragon-Pixel, Carpe Cosmos, et leurs écrans qui jouent tout
##    seuls), la grande borne du Dragon-Pixel au fond et le tableau des records (Turbo, toujours) ; les
##    deux Néo-Kart où l'on s'assoit, la machine à danser Robo-Rythme et sa boule à facettes, le palet sur
##    coussin d'air, les deux pinces à peluches, le photomaton ; le comptoir « Jetons & Lots » d'Octet,
##    l'androïde qui tient la salle, le frigo à sodas, le changeur de jetons.
##  - Sur l'Île de Larsen, les quatre bus peints, des maisons qui roulent (ou qui rouleraient) : le Bus
##    du Soleil de Papy Rayon (les tisanes, la tenture du soleil et de la lune), le Bus-Atelier de Pastel
##    (là qu'on mélange les couleurs des bus), le Bus-Bibliothèque de Marque-Page (le hamac, les livres
##    partout), le Bus de la Plage d'Écume (les planches de surf au plafond, les coquillages). Par les
##    fenêtres, la prairie et les yourtes (ou la plage), le jour et la nuit ; les guirlandes ; les rideaux.
## Comme lieux_v171 à lieux_v174 (boutiques_v170 délègue ici les métiers qu'il ne connaît pas) ; les bus
## font leur coque eux-mêmes (coque : le plancher, les parois et leurs fenêtres, la voûte de lattes).
## M : maisons_v81 ; R : la pièce ; B : les boutiques ; L4 : les aides de lieux_v174.

const B = preload("res://scripts/boutiques_v170.gd")
const L4 = preload("res://scripts/lieux_v174.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")

const HISTOIRE := "b175"
const T := "beau175/"

const METIERS := {
	"arcade_dragon": [Vector2(16.0, 18.0), 5.2],
	"bus_soleil": [Vector2(7.3, 2.35), 2.1],
	"bus_atelier": [Vector2(7.3, 2.35), 2.1],
	"bus_livres": [Vector2(7.3, 2.35), 2.1],
	"bus_plage": [Vector2(7.3, 2.35), 2.1],
}

const RONDS: Array = []
const SEULS: Array = []

## id (celui de la ville) → [métier, la vraie personne, « E : entrer … », enseigne].
const VILLES := {
	"neo": {
		"arcade": ["arcade_dragon", "", "à l'Arcade du Dragon-Pixel", "Arcade du Dragon-Pixel"],
	},
	"larsen": {
		"bus_0": ["bus_soleil", "", "dans le Bus du Soleil", "Bus du Soleil"],
		"bus_1": ["bus_atelier", "", "dans le Bus-Atelier", "Bus-Atelier"],
		"bus_2": ["bus_livres", "", "dans le Bus-Bibliothèque", "Bus-Bibliothèque"],
		"bus_3": ["bus_plage", "", "dans le Bus de la Plage", "Bus de la Plage"],
	},
}

## Des vues pour l'outil d'images (rendu_maisons.sh … boutiques neo, larsen) : [nom, d'où, vers où], en
## repère de la pièce.
const VUES := {
	"arcade_dragon": [
		["salle", Vector3(-1.5, 1.7, 7.6), Vector3(0.8, 1.5, -6.0)],
		["fond", Vector3(1.6, 1.65, -4.4), Vector3(0.0, 2.4, -9.0)],
		["bornes", Vector3(-3.6, 1.6, -1.8), Vector3(-7.5, 1.3, -6.5)],
		["karts", Vector3(3.2, 1.65, -3.0), Vector3(7.5, 1.2, -6.5)],
		["danse", Vector3(3.0, 1.7, 0.6), Vector3(7.2, 1.5, -1.6)],
		["pinces", Vector3(2.4, 1.65, 4.6), Vector3(7.5, 1.4, 2.6)],
		["lots", Vector3(-1.6, 1.65, 3.2), Vector3(-7.5, 1.4, 4.6)],
	],
	"bus_soleil": [
		["avant", Vector3(-1.4, 1.55, 0.1), Vector3(3.6, 1.2, -0.2)],
		["arriere", Vector3(2.6, 1.6, 0.3), Vector3(-3.6, 0.9, 0.0)],
	],
	"bus_atelier": [
		["avant", Vector3(-1.6, 1.55, 0.2), Vector3(3.6, 1.2, -0.2)],
		["arriere", Vector3(2.6, 1.6, 0.3), Vector3(-3.6, 0.9, 0.0)],
	],
	"bus_livres": [
		["avant", Vector3(-1.9, 1.55, 0.2), Vector3(3.6, 1.2, -0.2)],
		["arriere", Vector3(2.6, 1.6, 0.3), Vector3(-3.6, 1.1, 0.0)],
	],
	"bus_plage": [
		["avant", Vector3(-1.4, 1.55, 0.1), Vector3(3.6, 1.2, -0.2)],
		["arriere", Vector3(2.6, 1.6, 0.3), Vector3(-3.6, 0.9, 0.0)],
	],
}

## Les bus : la couleur de la carrosserie (dehors), la seconde couleur (les fleurs), le pastel des
## parois, ce qu'on voit par les fenêtres.
const BUS := {
	"bus_soleil": {"c": Color(0.95, 0.62, 0.15), "c2": Color(0.2, 0.55, 0.8), "pastel": Color(0.99, 0.88, 0.66), "vue": "prairie"},
	"bus_atelier": {"c": Color(0.3, 0.62, 0.72), "c2": Color(0.97, 0.88, 0.3), "pastel": Color(0.8, 0.93, 0.92), "vue": "prairie"},
	"bus_livres": {"c": Color(0.62, 0.32, 0.68), "c2": Color(0.95, 0.5, 0.25), "pastel": Color(0.92, 0.83, 0.96), "vue": "prairie"},
	"bus_plage": {"c": Color(0.92, 0.9, 0.82), "c2": Color(0.9, 0.25, 0.2), "pastel": Color(0.96, 0.95, 0.9), "vue": "plage"},
}


static func porte_ville(style: String, id: String, door: Vector3, out: Vector3) -> bool:
	var v: Dictionary = VILLES.get(style, {})
	if not v.has(id):
		return false
	var e: Array = v[id]
	return B.porte(door, out, style, str(e[0]), str(e[1]), str(e[2]), str(e[3]), HISTOIRE)


static func has_metier(met: String) -> bool:
	return METIERS.has(met)


static func _pal(_st: String, met: String) -> Dictionary:
	if met == "arcade_dragon":
		return {"sol": [T + "moquette_cosmos.png", Color(1, 1, 1), 2.6], "mur": ["neo156/beton_cire.png", Color(0.22, 0.16, 0.32), 2.5],
			"bas": ["neo156/panneaux_metal.png", Color(0.1, 0.1, 0.13), 1.6], "plafond": ["neo156/beton_cire.png", Color(0.07, 0.065, 0.09), 4.0],
			"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}
	var b: Dictionary = BUS.get(met, BUS["bus_soleil"])
	var pa: Color = b["pastel"]
	return {"sol": ["montjoie/bois_planches.png", Color(0.86, 0.7, 0.55), 1.2], "mur": ["beau161/bois_peint.png", pa, 1.2],
		"bas": ["maisons/lambris_blanc.png", pa.darkened(0.08), 0.9], "plafond": ["neo156/lattes_bois.png", Color(0.95, 0.86, 0.72), 1.0],
		"fenetre": "aucune", "sans_poutres": true, "sans_lampe": true}


static func build(M) -> void:
	match str(M.cur.get("metier", "")):
		"arcade_dragon":
			_arcade(M)
		"bus_soleil":
			_bus_soleil(M)
		"bus_atelier":
			_bus_atelier(M)
		"bus_livres":
			_bus_livres(M)
		"bus_plage":
			_bus_plage(M)


## La coque d'un lieu de la V175 (à la place de R.shell) : vrai si ce module l'a faite.
static func coque(M) -> bool:
	var met: String = str(M.cur.get("metier", ""))
	if met == "arcade_dragon":
		_coque_arcade(M)
		return true
	if BUS.has(met):
		_coque_bus(M, met)
		return true
	return false


# =================================================================== les petites aides

static func T3(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(x, y, z))


## Un point d'un meuble (lx, lz : dans son repère) en repère de la pièce : son repère est en (x, z),
## tourné de yaw (degrés).
static func _rp(x: float, z: float, yaw: float, lx: float, lz: float) -> Vector2:
	var a: float = deg_to_rad(yaw)
	return Vector2(x + lx * cos(a) + lz * sin(a), z - lx * sin(a) + lz * cos(a))


## Une matière d'image (éclairée).
static func _tx(R, key: String, path: String, tint: Color = Color(1, 1, 1), rough: float = 0.85) -> String:
	return B._tex(R, key, path, tint, rough)


## Une couleur qui brille (un néon, une diode).
static func _lum(R, key: String, c: Color, e: float) -> String:
	return B._c(R, key, c, 0.4, 0.0, e)


## Une image qui brille d'elle-même (un écran, un fronton rétroéclairé, ce qu'on voit par une vitre).
static func _image(R, key: String, path: String, e: float = 1.0) -> String:
	if R.mat(key) == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var t: Texture2D = R._tex(path)
		if t != null:
			m.albedo_texture = t
		m.albedo_color = Color(e, e, e)
		R._put(key, m)
	return key


## Un néon de la salle (l'image d'un tube sur fond transparent) : il grésille un peu (ecran_v94).
static func _neon(R, key: String, path: String, graine: float, force: float = 2.2) -> String:
	if R.mat(key) == null:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/ecran_v94.gdshader")
		var t: Texture2D = R._tex(path)
		if t != null:
			m.set_shader_parameter("image", t)
		m.set_shader_parameter("ecran", false)
		m.set_shader_parameter("force", force)
		m.set_shader_parameter("nuit", 1.0)
		m.set_shader_parameter("graine", graine)
		R._put(key, m)
	return key


## L'écran d'une borne (son jeu, en « mode démo » : arcade_ecran_v175).
static func _ecran(R, key: String, jeu: int, graine: float, force: float = 1.5) -> String:
	if R.mat(key) == null:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/arcade_ecran_v175.gdshader")
		m.set_shader_parameter("jeu", jeu)
		m.set_shader_parameter("graine", graine)
		m.set_shader_parameter("force", force)
		R._put(key, m)
	return key


## Une image posée à plat contre un mur, tournée vers la pièce (xf : son centre, +Z vers la pièce).
static func _plaque(R, xf: Transform3D, w: float, h: float, key: String, uv0: Vector2 = Vector2.ZERO, uv1: Vector2 = Vector2.ONE) -> void:
	R.kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), w, h, key, uv0, uv1)


## Une image posée à plat sur le dessus d'un meuble (xf : son centre ; elle regarde +Y ; son haut vers +Z).
static func _dessus(R, xf: Transform3D, w: float, h: float, key: String) -> void:
	R.kit.quad(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), w, h, key)


## Un tube (un cylindre de a à b, repère de la pièce).
static func _tube(R, a: Vector3, b: Vector3, r: float, key: String, seg: int = 8) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var y: Vector3 = d / l
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	R.kit.cyl(Transform3D(Basis(x, y, z), R.P(a.x, a.y, a.z)), r, r, l, key, seg, false)


## Une boîte allongée de a à b (repère de la pièce) : un barreau, un tube de néon, une baguette.
static func _barre(R, a: Vector3, b: Vector3, ep: Vector2, key: String) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var z: Vector3 = d / l
	var x: Vector3 = Vector3.UP.cross(z)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var y: Vector3 = z.cross(x).normalized()
	var m: Vector3 = (a + b) * 0.5
	R.kit.box(Transform3D(Basis(x, y, z), R.P(m.x, m.y, m.z)), Vector3(ep.x, ep.y, l), key, 1.0)


static func _boule(M, key: String, p: Vector3, r: float, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	return L4._boule(M, key, p, r, scl)


# =================================================================== l'Arcade du Dragon-Pixel : la salle

static func _mats_arcade(R) -> void:
	if R.mat("moquette175") == null:
		var m: StandardMaterial3D = R._texmat(T + "moquette_cosmos.png", Color(1, 1, 1), 1.0)
		var lt: Texture2D = R._tex(T + "moquette_cosmos_lum.png")
		if lt != null:
			# (l'émission « ajoute » sa couleur à l'image : la couleur reste noire, seule l'image luit)
			m.emission_enabled = true
			m.emission = Color(0, 0, 0)
			m.emission_texture = lt
			m.emission_energy_multiplier = 0.9
		R._put("moquette175", m)
	_tx(R, "mur175", "neo156/beton_cire.png", Color(0.22, 0.16, 0.32), 0.85)
	_tx(R, "bas175", "neo156/panneaux_metal.png", Color(0.1, 0.1, 0.13), 0.45)
	_tx(R, "plafond175", "neo156/beton_cire.png", Color(0.07, 0.065, 0.09), 0.9)
	_tx(R, "fer175", "neo156/inox_brosse.png", Color(0.2, 0.2, 0.24), 0.45)
	_tx(R, "inox175", "neo156/inox_brosse.png", Color(0.85, 0.86, 0.9), 0.3)
	B._c(R, "noir175", Color(0.03, 0.03, 0.04), 0.35)
	B._c(R, "panneau175", Color(0.06, 0.06, 0.08), 0.5)
	B._c(R, "chrome175", Color(0.85, 0.86, 0.9), 0.15, 0.9)
	B._c(R, "skai175", Color(0.35, 0.08, 0.45), 0.45)
	B._c(R, "siege175", Color(0.75, 0.08, 0.1), 0.4)
	B._c(R, "blanc175", Color(0.92, 0.93, 0.95), 0.35)
	B._c(R, "rouge175", Color(0.85, 0.06, 0.08), 0.3)
	B._c(R, "borne_vert175", Color(0.03, 0.16, 0.07), 0.45)
	B._c(R, "borne_bleu175", Color(0.03, 0.06, 0.2), 0.45)
	B._c(R, "borne_rouge175", Color(0.25, 0.02, 0.04), 0.45)
	B._c(R, "borne_violet175", Color(0.14, 0.03, 0.22), 0.45)
	for e in [["neon_rose175", Color(1.0, 0.25, 0.75)], ["neon_cyan175", Color(0.2, 0.9, 1.0)], ["neon_violet175", Color(0.62, 0.32, 1.0)],
			["neon_vert175", Color(0.3, 1.0, 0.45)], ["neon_jaune175", Color(1.0, 0.85, 0.2)], ["neon_orange175", Color(1.0, 0.5, 0.15)]]:
		_lum(R, str(e[0]), e[1], 1.7)
	_lum(R, "diode_rouge175", Color(1.0, 0.15, 0.1), 1.6)
	B._verre(R, "vitre175", Color(0.8, 0.85, 0.95), 0.14)
	B._verre(R, "verre_porte175", Color(0.35, 0.3, 0.65), 0.6, 0.6)
	_tx(R, "flanc_eclairs175", T + "flanc_eclairs.png", Color(1, 1, 1), 0.5)
	_tx(R, "flanc_planetes175", T + "flanc_planetes.png", Color(1, 1, 1), 0.5)
	for n in ["dragon", "kart", "carpe", "rythme"]:
		_image(R, "fronton_%s175" % n, T + "fronton_%s.png" % n, 1.15)
		_tx(R, "affiche_%s175" % n, T + "affiche_%s.png" % n, Color(1, 1, 1), 0.6)


## La coque de l'arcade : la moquette qui luit, les murs violet de nuit (le bas en panneaux noirs), le
## plafond noir ; les bandes de néon le long des murs ; la porte vitrée (vue de dedans).
static func _coque_arcade(M) -> void:
	var R = M.R
	var k = R.kit
	_mats_arcade(R)
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var H: float = R.H
	k.box(R.L(0, -0.1, 0), Vector3(R.W, 0.2, R.D), "moquette175", 2.6, 4)
	k.col_box(R.L(0, -0.5, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))
	k.box(R.L(0, H + 0.1, 0), Vector3(R.W, 0.2, R.D), "plafond175", 4.0, 8)
	k.col_box(R.L(0, H + 1.0, 0), Vector3(R.W + 4.0, 1.0, R.D + 4.0))
	var bas: float = 1.1
	var porte_w: float = 2.6
	var porte_h: float = 2.75
	# les murs : [repère du pied du mur (+Z vers la pièce), longueur, trou de la porte]
	var murs: Array = [[R.L(0, 0, -hd, 0), R.W, false], [R.L(-hw, 0, 0, 90), R.D, false], [R.L(hw, 0, 0, -90), R.D, false], [R.L(0, 0, hd, 180), R.W, true]]
	for mu in murs:
		var xf: Transform3D = mu[0]
		var l: float = mu[1]
		var ouv: Array = [[0.0, porte_w, 0.0, porte_h]] if bool(mu[2]) else []
		var hl: float = l * 0.5
		var xs: Array = [-hl, hl]
		for o in ouv:
			xs.append(float(o[0]) - float(o[1]) * 0.5)
			xs.append(float(o[0]) + float(o[1]) * 0.5)
		xs.sort()
		for i in range(xs.size() - 1):
			var a: float = xs[i]
			var b: float = xs[i + 1]
			var parts: Array = [[0.0, H]]
			for o2 in ouv:
				if absf((a + b) * 0.5 - float(o2[0])) < float(o2[1]) * 0.5:
					parts = L4._sans(parts, float(o2[2]), float(o2[2]) + float(o2[3]))
			for p in parts:
				var y0: float = p[0]
				var y1: float = p[1]
				if y0 < bas:
					L4._pan(R, "bas175", xf, a, b, y0, minf(bas, y1), 1.6)
				if y1 > bas:
					L4._pan(R, "mur175", xf, a, b, maxf(bas, y0), y1, 2.5)
		k.col_box(xf * T3(0, H * 0.5, -0.5), Vector3(l + 2.0, H + 2.0, 1.0))
		# les bandes de néon : au-dessus des panneaux noirs (rose), sous le plafond (violet) ; une
		# baguette chromée entre les deux
		var segs: Array = [[-hl, hl]]
		if bool(mu[2]):
			segs = [[-hl, -porte_w * 0.5 - 0.15], [porte_w * 0.5 + 0.15, hl]]
		for s in segs:
			var c: float = (float(s[0]) + float(s[1])) * 0.5
			var ls: float = float(s[1]) - float(s[0])
			k.box(xf * T3(c, bas + 0.02, 0.03), Vector3(ls, 0.05, 0.05), "neon_rose175", 1.0)
			k.box(xf * T3(c, bas - 0.05, 0.02), Vector3(ls, 0.06, 0.04), "chrome175", 1.0)
			k.box(xf * T3(c, 0.06, 0.03), Vector3(ls, 0.12, 0.06), "noir175", 1.0)
		k.box(xf * T3(0, H - 0.3, 0.03), Vector3(l, 0.05, 0.05), "neon_violet175", 1.0)
	_porte_arcade(M)


## La porte vitrée de l'arcade (vue de dedans) : le cadre d'inox, les deux vantaux de verre dépoli où
## passe la lumière de la rue, le paillasson du dragon, « SORTIE » au-dessus.
static func _porte_arcade(M) -> void:
	var R = M.R
	var k = R.kit
	var z: float = R.D * 0.5
	var w: float = 2.6
	var h: float = 2.75
	var xf: Transform3D = R.L(0, 0, z, 180)
	for s in [-1.0, 1.0]:
		k.box(xf * T3(s * (w * 0.5 + 0.04), h * 0.5, 0.0), Vector3(0.08, h, 0.16), "inox175", 1.0)
		k.box(xf * T3(s * w * 0.25, h * 0.5, -0.04), Vector3(w * 0.5 - 0.06, h - 0.06, 0.03), "verre_porte175", 1.0)
		k.box(xf * T3(s * 0.05, h * 0.5, -0.02), Vector3(0.04, h - 0.06, 0.05), "inox175", 1.0)
		k.box(xf * T3(s * 0.16, 1.05, 0.03), Vector3(0.03, 0.9, 0.03), "chrome175", 1.0)
	k.box(xf * T3(0, h + 0.04, 0.0), Vector3(w + 0.16, 0.08, 0.16), "inox175", 1.0)
	k.box(xf * T3(0, 0.02, 0.0), Vector3(w, 0.04, 0.16), "inox175", 1.0)
	# l'arche de néon autour de la porte
	k.box(xf * T3(0, h + 0.22, 0.05), Vector3(w + 0.6, 0.05, 0.05), "neon_cyan175", 1.0)
	for s2 in [-1.0, 1.0]:
		k.box(xf * T3(s2 * (w * 0.5 + 0.3), (h + 0.22) * 0.5, 0.05), Vector3(0.05, h + 0.22, 0.05), "neon_cyan175", 1.0)
	var lb: Label3D = B._ecrit(M, 0.0, h + 0.55, z, 180.0, "SORTIE", 64, Color(0.4, 1.0, 0.5), 0.004, 0.06)
	lb.outline_modulate = Color(0.0, 0.2, 0.05, 0.9)
	# le paillasson
	B._c(R, "paillasson175", Color(0.05, 0.05, 0.07), 0.95)
	k.box(R.L(0, 0.005, z - 0.8), Vector3(2.0, 0.012, 1.1), "paillasson175", 1.0)
	k.box(R.L(0, 0.012, z - 0.8), Vector3(1.8, 0.006, 0.04), "neon_vert175", 1.0)


## Le plafond : deux poutres en treillis (des projecteurs y sont accrochés), des zigzags de néon d'un
## mur à l'autre.
static func _plafond_arcade(M) -> void:
	var R = M.R
	var k = R.kit
	var H: float = R.H
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	for sx in [-3.5, 3.5]:
		_treillis(R, Vector3(sx, H - 0.55, -hd + 0.2), Vector3(sx, H - 0.55, hd - 0.2), 0.32)
		for i in range(6):
			var z: float = -hd + 1.6 + i * 3.0
			k.cyl(R.L(sx, H - 0.73, z) * Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), 0.11, 0.09, 0.26, "noir175", 10)
			k.disc(R.L(sx, H - 0.995, z) * Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), 0.08, "neon_jaune175" if i % 2 == 0 else "neon_cyan175", 10)
		# les tiges qui tiennent la poutre
		for z2 in [-hd + 2.0, 0.0, hd - 2.0]:
			_tube(R, Vector3(sx, H - 0.39, z2), Vector3(sx, H, z2), 0.015, "fer175", 6)
	var cols: Array = ["neon_rose175", "neon_cyan175", "neon_violet175", "neon_jaune175"]
	var ci: int = 0
	for z3 in [-6.0, -2.0, 2.0, 6.0]:
		var n: int = 7
		var prev: Vector3 = Vector3(-hw + 0.6, H - 0.12, z3)
		for i2 in range(1, n + 1):
			var x: float = -hw + 0.6 + (R.W - 1.2) * float(i2) / n
			var p: Vector3 = Vector3(x, H - 0.12, z3 + (0.7 if i2 % 2 == 1 else -0.7))
			_barre(R, prev, p, Vector2(0.05, 0.05), cols[ci % cols.size()])
			prev = p
		ci += 1


## Une poutre en treillis carré (les quatre membrures, les diagonales sur chaque face), de a à b.
static func _treillis(R, a: Vector3, b: Vector3, s: float) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	var dir: Vector3 = d / l
	var side: Vector3 = Vector3.UP.cross(dir).normalized()
	var up: Vector3 = dir.cross(side).normalized()
	var h: float = s * 0.5
	var coins: Array = [side * h + up * h, -side * h + up * h, -side * h - up * h, side * h - up * h]
	for c in coins:
		_tube(R, a + (c as Vector3), b + (c as Vector3), 0.022, "fer175", 6)
	var n: int = int(l / 0.6)
	for i in range(n):
		var t0: float = float(i) / n
		var t1: float = float(i + 1) / n
		for f in range(4):
			var c0: Vector3 = coins[f]
			var c1: Vector3 = coins[(f + 1) % 4]
			var p0: Vector3 = a + d * t0 + (c0 if i % 2 == 0 else c1)
			var p1: Vector3 = a + d * t1 + (c1 if i % 2 == 0 else c0)
			_tube(R, p0, p1, 0.011, "fer175", 4)


# =================================================================== l'Arcade : les bornes

## Une borne d'arcade (x, z, yaw : le joueur est devant, côté +Z) : le meuble peint, les flancs décorés
## et leur liseré de néon, le pupitre (le manche, les boutons), l'écran qui joue tout seul, le fronton
## rétroéclairé, la porte à pièces. s : l'échelle (la grande borne du fond). Renvoie le repère.
static func _borne(M, x: float, z: float, yaw: float, jeu: int, graine: int, s: float = 1.0) -> Transform3D:
	var R = M.R
	var k = R.kit
	var base: Transform3D = R.L(x, 0, z, yaw)
	var xf: Transform3D = base * Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO)
	var corps: String = ["borne_vert175", "borne_rouge175", "borne_bleu175", "borne_violet175"][jeu]
	var nom: String = ["dragon", "kart", "carpe", "rythme"][jeu]
	var flanc: String = "flanc_eclairs175" if graine % 2 == 0 else "flanc_planetes175"
	var liseret: String = ["neon_vert175", "neon_cyan175", "neon_orange175", "neon_rose175"][jeu]
	# le meuble
	k.box(xf * T3(0, 0.5, -0.04), Vector3(0.72, 1.0, 0.7), corps, 1.0)
	k.box(xf * T3(0, 0.05, 0.3), Vector3(0.72, 0.1, 0.06), "noir175", 1.0)
	k.box(xf * T3(0, 1.5, -0.2), Vector3(0.72, 1.0, 0.42), corps, 1.0)
	# les flancs (le dessin dehors), leur liseré de néon devant
	for sx in [-1.0, 1.0]:
		k.box(xf * T3(sx * 0.375, 1.0, 0.0), Vector3(0.03, 2.0, 0.84), "noir175", 1.0)
		_plaque(R, xf * Transform3D(Basis(Vector3.UP, sx * PI * 0.5), Vector3(sx * 0.392, 1.0, 0.0)), 0.82, 1.96, flanc)
		k.box(xf * T3(sx * 0.375, 1.0, 0.425), Vector3(0.035, 2.0, 0.015), liseret, 1.0)
	# le pupitre penché vers le joueur, le manche (sa boule rouge), les boutons
	var pxf: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(0, 1.0, 0.24))
	k.box(pxf, Vector3(0.72, 0.07, 0.34), "panneau175", 1.0)
	k.cyl(pxf * T3(-0.2, 0.035, 0.02), 0.012, 0.012, 0.085, "chrome175", 8)
	k.cyl(pxf * T3(-0.2, 0.11, 0.02), 0.028, 0.028, 0.045, "rouge175", 10)
	var bts: Array = ["neon_jaune175", "neon_rose175", "neon_cyan175", "neon_vert175"]
	for i in range(4):
		k.cyl(pxf * T3(0.0 + i * 0.075, 0.035, 0.03 - (i % 2) * 0.05), 0.022, 0.022, 0.016, bts[i], 10)
	# l'écran (un peu en retrait), sa visière
	k.box(xf * T3(0, 1.52, 0.012), Vector3(0.66, 0.56, 0.02), "noir175", 1.0)
	var cle: String = _ecran(R, "ecran175_%d" % graine, jeu, float(graine) * 1.37, 1.55)
	_plaque(R, xf * T3(0, 1.52, 0.024), 0.56, 0.42, cle)
	k.box(xf * T3(0, 1.84, 0.08), Vector3(0.72, 0.05, 0.16), "noir175", 1.0)
	# le fronton (le nom du jeu), allumé
	k.box(xf * T3(0, 2.04, -0.06), Vector3(0.72, 0.28, 0.28), "noir175", 1.0)
	_plaque(R, xf * T3(0, 2.04, 0.082), 0.7, 0.175, "fronton_%s175" % nom)
	# la porte à pièces : deux fentes rouges
	k.box(xf * T3(0, 0.55, 0.31), Vector3(0.32, 0.36, 0.02), "chrome175", 1.0)
	for sx2 in [-0.07, 0.07]:
		k.box(xf * T3(sx2, 0.62, 0.322), Vector3(0.05, 0.08, 0.008), "diode_rouge175", 1.0)
	k.col_box(base * T3(0, 1.08 * s, 0.0), Vector3(0.8, 2.16, 0.86) * s)
	return xf


## Les bornes : la rangée du mur de gauche (Carpe Cosmos et Dragon-Pixel, côte à côte), l'îlot du milieu
## (dos à dos), la grande borne du Dragon-Pixel au fond.
static func _bornes(M) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var g: int = 0
	for i in range(7):
		_borne(M, -hw + 0.46, -8.4 + i * 0.92, 90.0, [2, 0][i % 2], g)
		g += 1
	for i2 in range(4):
		var zz: float = -5.2 + i2 * 0.92
		_borne(M, -0.46, zz, -90.0, [0, 3, 2, 0][i2], g)
		g += 1
		_borne(M, 0.46, zz, 90.0, [2, 0, 1, 2][i2], g)
		g += 1
	# l'îlot : son socle noir et son liseré, une enseigne au-dessus
	var k = R.kit
	k.box(R.L(0, 2.35, -3.82), Vector3(0.2, 0.06, 3.8), "neon_jaune175", 1.0)
	# la grande borne du Dragon-Pixel (sur une estrade qui luit), au fond
	k.box(R.L(0, 0.06, -R.D * 0.5 + 1.0), Vector3(2.6, 0.12, 1.9), "noir175", 1.0)
	k.box(R.L(0, 0.125, -R.D * 0.5 + 1.95), Vector3(2.6, 0.02, 0.04), "neon_vert175", 1.0)
	_borne(M, 0.0, -R.D * 0.5 + 0.75, 0.0, 0, 99, 1.32)


## Le mur du fond : le grand dragon de néon, le tableau des records, les affiches.
static func _mur_du_fond(M) -> void:
	var R = M.R
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	_plaque(R, R.L(0.0, 3.9, -hd + 0.05), 4.0, 2.0, _neon(R, "neon_dragon175", T + "neon_dragon.png", 1.0, 1.5))
	# le tableau des records (des lettres de lumière), son cadre
	var k = R.kit
	k.box(R.L(4.1, 2.45, -hd + 0.04), Vector3(1.75, 2.15, 0.06), "noir175", 1.0)
	_plaque(R, R.L(4.1, 2.45, -hd + 0.08), 1.6, 2.0, _image(R, "records175", T + "records.png", 1.1))
	k.box(R.L(4.1, 3.6, -hd + 0.06), Vector3(1.8, 0.05, 0.06), "neon_rose175", 1.0)
	# les affiches (dans leurs cadres noirs)
	var aff: Array = [["affiche_carpe175", -hw + 0.03, 3.3, -7.2, 90.0], ["affiche_dragon175", -hw + 0.03, 3.3, -4.6, 90.0],
		["affiche_kart175", hw - 0.03, 3.4, -6.3, -90.0], ["affiche_rythme175", hw - 0.03, 3.6, 0.4, -90.0],
		["affiche_dragon175", -5.6, 2.0, hd - 0.03, 180.0], ["affiche_carpe175", 5.6, 2.0, hd - 0.03, 180.0],
		["affiche_rythme175", -4.4, 2.4, -hd + 0.03, 0.0]]
	for a in aff:
		B._cadre(R, str(a[0]), float(a[1]), float(a[2]), float(a[3]), float(a[4]), 1.0, 1.5, "noir175")


# =================================================================== l'Arcade : les machines

## Les deux Néo-Kart (on s'y assoit) : le socle, les sièges baquets, les volants, les pédales, deux
## écrans, le fronton.
static func _kart(M, x: float, z: float, yaw: float, graine: int) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * T3(0, 0.06, 0.1), Vector3(1.8, 0.12, 2.0), "noir175", 1.0)
	k.box(xf * T3(0, 0.125, 1.08), Vector3(1.8, 0.02, 0.04), "neon_cyan175", 1.0)
	# la caisse des écrans, le tableau de bord
	k.box(xf * T3(0, 1.3, -0.68), Vector3(1.8, 1.9, 0.6), "borne_rouge175", 1.0)
	k.box(xf * T3(0, 0.55, -0.25), Vector3(1.8, 0.86, 0.36), "borne_rouge175", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * T3(sx * 0.92, 1.25, -0.5), Vector3(0.04, 2.5, 1.0), "noir175", 1.0)
		_plaque(R, xf * Transform3D(Basis(Vector3.UP, sx * PI * 0.5), Vector3(sx * 0.942, 1.25, -0.5)), 0.98, 2.4, "flanc_eclairs175" if sx < 0 else "flanc_planetes175")
		k.box(xf * T3(sx * 0.92, 1.25, 0.005), Vector3(0.045, 2.5, 0.02), "neon_cyan175", 1.0)
		var e: String = _ecran(R, "ecran175_kart%d_%d" % [graine, int(sx)], 1, float(graine) * 2.1 + sx * 3.3, 1.5)
		k.box(xf * T3(sx * 0.43, 1.48, -0.375), Vector3(0.8, 0.62, 0.02), "noir175", 1.0)
		_plaque(R, xf * T3(sx * 0.43, 1.48, -0.362), 0.72, 0.54, e)
		# le volant (tourné vers le pilote), sa colonne
		var vxf: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(62.0)), Vector3(sx * 0.43, 0.98, -0.02))
		k.ring(vxf, 0.15, 0.185, 0.035, "noir175", 20)
		k.cyl(vxf * T3(0, -0.01, 0), 0.05, 0.05, 0.05, "neon_jaune175", 10)
		k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(62.0)), Vector3(sx * 0.43, 0.85, -0.09)), 0.025, 0.025, 0.15, "chrome175", 8)
		# les pédales
		for p in [-0.08, 0.08]:
			k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(sx * 0.43 + p, 0.2, 0.0)), Vector3(0.08, 0.02, 0.14), "chrome175", 1.0)
		# le siège baquet
		k.box(xf * T3(sx * 0.43, 0.22, 0.62), Vector3(0.44, 0.2, 0.44), "noir175", 1.0)
		k.box(xf * T3(sx * 0.43, 0.39, 0.6), Vector3(0.5, 0.1, 0.5), "siege175", 1.0)
		k.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.18), Vector3(sx * 0.43, 0.78, 0.88)), Vector3(0.5, 0.74, 0.12), "siege175", 1.0)
		for sb in [-1.0, 1.0]:
			k.box(xf * T3(sx * 0.43 + sb * 0.23, 0.5, 0.62), Vector3(0.06, 0.16, 0.46), "siege175", 1.0)
		k.col_box(xf * T3(sx * 0.43, 0.45, 0.65), Vector3(0.5, 0.9, 0.55))
	# le fronton
	k.box(xf * T3(0, 2.42, -0.6), Vector3(1.8, 0.4, 0.52), "noir175", 1.0)
	_plaque(R, xf * T3(0, 2.42, -0.335), 1.6, 0.4, "fronton_kart175")
	k.col_box(xf * T3(0, 1.25, -0.55), Vector3(1.9, 2.5, 0.95))


## La machine à danser Robo-Rythme : la plate-forme, le tapis aux quatre flèches (qui s'allume au
## temps), la barre derrière le danseur, la tour (l'écran, les haut-parleurs, le fronton). Renvoie le
## centre du tapis (repère de la pièce).
static func _danse(M, x: float, z: float, yaw: float) -> Vector2:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	k.box(xf * T3(0, 0.08, 0.35), Vector3(1.7, 0.16, 1.55), "noir175", 1.0)
	for sx in [-1.0, 1.0]:
		k.box(xf * T3(sx * 0.85, 0.17, 0.35), Vector3(0.03, 0.02, 1.55), "neon_rose175", 1.0)
	# le tapis : sa matière brille au temps de la musique (tick)
	var tap := StandardMaterial3D.new()
	var tt: Texture2D = R._tex(T + "tapis_danse.png")
	tap.albedo_texture = tt
	tap.roughness = 0.35
	tap.emission_enabled = true
	tap.emission_texture = tt
	tap.emission = Color(0, 0, 0)
	tap.emission_energy_multiplier = 0.8
	R._put("tapis175", tap)
	M.ctx["tapis175"] = tap
	_dessus(R, xf * T3(0, 0.165, 0.35, 180.0), 1.15, 1.15, "tapis175")
	# la barre, derrière le danseur
	for sx2 in [-0.72, 0.72]:
		var a: Vector2 = _rp(x, z, yaw, sx2, 1.05)
		_tube(R, Vector3(a.x, 0.16, a.y), Vector3(a.x, 1.1, a.y), 0.025, "chrome175", 10)
	var a1: Vector2 = _rp(x, z, yaw, -0.72, 1.05)
	var a2: Vector2 = _rp(x, z, yaw, 0.72, 1.05)
	_tube(R, Vector3(a1.x, 1.1, a1.y), Vector3(a2.x, 1.1, a2.y), 0.025, "chrome175", 10)
	# la tour : l'écran, les haut-parleurs (leurs cônes), le fronton
	k.box(xf * T3(0, 1.3, -0.68), Vector3(1.7, 2.6, 0.55), "borne_violet175", 1.0)
	k.box(xf * T3(0, 1.62, -0.395), Vector3(1.0, 0.78, 0.02), "noir175", 1.0)
	_plaque(R, xf * T3(0, 1.62, -0.383), 0.92, 0.69, _ecran(R, "ecran175_danse", 3, 7.0, 1.6))
	for sx3 in [-0.62, 0.62]:
		for yy in [0.75, 2.25]:
			k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx3, yy, -0.4)), 0.17, 0.12, 0.04, "noir175", 16)
			k.cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(sx3, yy, -0.37)), 0.05, 0.05, 0.03, "chrome175", 10)
		k.box(xf * T3(sx3 + (0.24 if sx3 > 0 else -0.24), 1.3, -0.4), Vector3(0.03, 2.6, 0.02), "neon_rose175", 1.0)
	k.box(xf * T3(0, 2.82, -0.6), Vector3(1.7, 0.42, 0.5), "noir175", 1.0)
	_plaque(R, xf * T3(0, 2.82, -0.345), 1.62, 0.405, "fronton_rythme175")
	k.col_box(xf * T3(0, 1.4, -0.68), Vector3(1.7, 2.8, 0.55))
	var c: Vector2 = _rp(x, z, yaw, 0.0, 0.35)
	return c


## Le palet sur coussin d'air (le long de x) : les pieds, la caisse, le plateau bleu aux mille trous, les
## bandes, les buts ; le palet qui file (tick), les deux poussoirs.
static func _palet(M, x: float, z: float) -> void:
	var R = M.R
	var k = R.kit
	B._c(R, "palet_caisse175", Color(0.9, 0.9, 0.92), 0.3)
	for sx in [-0.95, 0.95]:
		for sz in [-0.45, 0.45]:
			k.box(R.L(x + sx, 0.31, z + sz), Vector3(0.12, 0.62, 0.12), "noir175", 1.0)
	k.box(R.L(x, 0.73, z), Vector3(2.2, 0.22, 1.2), "palet_caisse175", 1.0)
	k.box(R.L(x, 0.66, z), Vector3(2.22, 0.06, 1.22), "neon_cyan175", 1.0)
	var pl := StandardMaterial3D.new()
	var tt: Texture2D = R._tex(T + "table_palet.png")
	pl.albedo_texture = tt
	pl.roughness = 0.15
	pl.emission_enabled = true
	pl.emission_texture = tt
	pl.emission = Color(0, 0, 0)
	pl.emission_energy_multiplier = 0.35
	R._put("palet175", pl)
	_dessus(R, R.L(x, 0.845, z, 90.0), 1.0, 2.0, "palet175")
	for sz2 in [-0.55, 0.55]:
		k.box(R.L(x, 0.88, z + sz2), Vector3(2.2, 0.08, 0.1), "rouge175", 1.0)
	for sx2 in [-1.05, 1.05]:
		for sz3 in [-0.36, 0.36]:
			k.box(R.L(x + sx2, 0.88, z + sz3), Vector3(0.1, 0.08, 0.3), "rouge175", 1.0)
		k.box(R.L(x + sx2 * 1.02, 0.8, z), Vector3(0.06, 0.06, 0.42), "noir175", 1.0)
	k.col_box(R.L(x, 0.46, z), Vector3(2.2, 0.92, 1.2))
	# le palet (il file d'un but à l'autre), les poussoirs
	var palet := L4._noeud(M, "Palet175", Transform3D(Basis(), R.P(x, 0.855, z)))
	L4._bout(palet, B._cylm(0.042, 0.042, 0.012, 16), R.mat("rouge175"), Vector3.ZERO)
	M.ctx["palet175"] = [palet, R.P(x, 0.855, z)]
	for sx3 in [-0.82, 0.82]:
		k.cyl(R.L(x + sx3, 0.85, z + 0.1 * sx3), 0.05, 0.05, 0.03, "rouge175" if sx3 < 0 else "neon_vert175", 14)
		k.cyl(R.L(x + sx3, 0.88, z + 0.1 * sx3), 0.022, 0.018, 0.06, "noir175", 10)


## Une pince à peluches : le meuble, la cage de verre, le tas de peluches (des dragons verts, des
## carpes orange, des ours roses…), la pince qui se promène (tick), le bac à lots, le fronton.
static func _pince(M, x: float, z: float, yaw: float, graine: int) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	var coul: String = "borne_violet175" if graine % 2 == 0 else "borne_bleu175"
	k.box(xf * T3(0, 0.48, 0), Vector3(1.0, 0.96, 0.95), coul, 1.0)
	k.box(xf * T3(0, 0.97, 0), Vector3(1.02, 0.03, 0.97), "chrome175", 1.0)
	for sx in [-0.49, 0.49]:
		for sz in [-0.455, 0.455]:
			k.box(xf * T3(sx, 1.5, sz), Vector3(0.04, 1.05, 0.04), "chrome175", 1.0)
	for f in [[T3(0, 1.5, 0.465), Vector3(0.96, 1.03, 0.012)], [T3(0, 1.5, -0.465), Vector3(0.96, 1.03, 0.012)],
			[T3(0.495, 1.5, 0), Vector3(0.012, 1.03, 0.9)], [T3(-0.495, 1.5, 0), Vector3(0.012, 1.03, 0.9)]]:
		k.box(xf * (f[0] as Transform3D), f[1], "vitre175", 1.0)
	k.box(xf * T3(0, 2.15, 0), Vector3(1.04, 0.26, 0.98), coul, 1.0)
	_plaque(R, xf * T3(0, 2.15, 0.495), 0.98, 0.245, _neon(R, "neon_pince175", T + "neon_pince.png", float(graine), 1.5))
	k.box(xf * T3(0, 2.02, 0.0), Vector3(0.96, 0.01, 0.9), "neon_jaune175", 1.0)
	# le bac à lots (devant, à gauche), sa trappe
	k.box(xf * T3(-0.28, 0.52, 0.48), Vector3(0.32, 0.26, 0.02), "noir175", 1.0)
	k.box(xf * T3(-0.28, 1.2, 0.2), Vector3(0.3, 0.45, 0.012), "vitre175", 1.0)
	# le pupitre : le manche, le bouton
	k.box(xf * T3(0.18, 0.92, 0.5), Vector3(0.5, 0.1, 0.12), "panneau175", 1.0)
	k.cyl(xf * T3(0.08, 0.97, 0.5), 0.012, 0.012, 0.09, "chrome175", 8)
	k.cyl(xf * T3(0.08, 1.05, 0.5), 0.03, 0.03, 0.04, "rouge175", 10)
	k.cyl(xf * T3(0.3, 0.97, 0.5), 0.035, 0.035, 0.02, "neon_rose175", 12)
	# le tas de peluches
	var rng := RandomNumberGenerator.new()
	rng.seed = 17501 + graine
	var cols: Array = [Color(0.3, 0.8, 0.35), Color(1.0, 0.55, 0.15), Color(1.0, 0.6, 0.75), Color(0.55, 0.75, 1.0), Color(1.0, 0.9, 0.4), Color(0.75, 0.55, 1.0)]
	for i in range(14):
		var c: Color = cols[i % cols.size()]
		var key: String = B._c(R, "peluche175_%d" % (i % cols.size()), c, 0.95)
		var lx: float = rng.randf_range(-0.36, 0.36)
		var lz: float = rng.randf_range(-0.34, 0.3)
		if lx < -0.1 and lz > 0.1:
			lx += 0.3
		var p: Vector2 = _rp(x, z, yaw, lx, lz)
		var y: float = 1.05 + rng.randf_range(0.0, 0.1) + (0.08 if i > 8 else 0.0)
		var r: float = rng.randf_range(0.075, 0.1)
		_boule(M, key, Vector3(p.x, y, p.y), r, Vector3(1.0, 0.85, 1.0))
		# les oreilles (ou les cornes) : deux petites boules
		if i % 3 == 0:
			for se in [-1.0, 1.0]:
				var q: Vector2 = _rp(x, z, yaw, lx + se * r * 0.6, lz)
				_boule(M, key, Vector3(q.x, y + r * 0.75, q.y), r * 0.32)
	# la pince : un chariot sur ses rails, le câble, les trois griffes (elle se promène : tick)
	k.box(xf * T3(0, 1.98, -0.38), Vector3(0.94, 0.03, 0.04), "chrome175", 1.0)
	k.box(xf * T3(0, 1.98, 0.38), Vector3(0.94, 0.03, 0.04), "chrome175", 1.0)
	var pin := L4._noeud(M, "Pince175_%d" % graine, xf * T3(0, 1.95, 0))
	L4._bout(pin, B._boitem(0.12, 0.05, 0.12), R.mat("chrome175"), Vector3.ZERO)
	L4._bout(pin, B._cylm(0.004, 0.004, 0.35, 4), R.mat("noir175"), Vector3(0, -0.2, 0))
	L4._bout(pin, B._cylm(0.03, 0.04, 0.06, 10), R.mat("chrome175"), Vector3(0, -0.4, 0))
	for g in range(3):
		var a: float = TAU * g / 3.0
		var bs := Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), -0.35)
		L4._bout(pin, B._boitem(0.012, 0.13, 0.012), R.mat("chrome175"), Vector3(cos(a) * 0.045, -0.48, sin(a) * 0.045), bs)
	if not M.ctx.has("pinces175"):
		M.ctx["pinces175"] = []
	(M.ctx["pinces175"] as Array).append([pin, xf * Vector3(0, 1.95, 0), xf.basis, float(graine)])
	k.col_box(xf * T3(0, 1.15, 0), Vector3(1.04, 2.3, 0.98))


## Le photomaton Pixel-Photo : la cabine, le rideau rouge (ses plis), le tabouret qu'on voit dessous,
## les bandes de photos d'exemple, le néon.
static func _photomaton(M, x: float, z: float, yaw: float) -> void:
	var R = M.R
	var k = R.kit
	var xf: Transform3D = R.L(x, 0, z, yaw)
	B._c(R, "cabine175", Color(0.9, 0.9, 0.95), 0.35)
	B._c(R, "rideau175", Color(0.65, 0.04, 0.1), 0.95)
	k.box(xf * T3(0, 1.15, -0.6), Vector3(1.55, 2.3, 0.04), "cabine175", 1.0)
	for sx in [-0.76, 0.76]:
		k.box(xf * T3(sx, 1.15, 0.0), Vector3(0.04, 2.3, 1.24), "cabine175", 1.0)
	k.box(xf * T3(0, 2.32, 0.0), Vector3(1.6, 0.05, 1.26), "cabine175", 1.0)
	k.box(xf * T3(0.42, 1.15, 0.6), Vector3(0.7, 2.3, 0.04), "cabine175", 1.0)
	# le rideau (des plis), le tabouret qu'on voit en dessous
	for i in range(7):
		var lx: float = -0.73 + i * 0.065
		k.box(xf * T3(lx, 1.25, 0.6 + (0.035 if i % 2 == 0 else 0.0)), Vector3(0.07, 1.8, 0.02), "rideau175", 1.0)
	k.cyl(xf * T3(-0.33, 0.0, 0.0), 0.16, 0.16, 0.45, "chrome175", 14)
	k.cyl(xf * T3(-0.33, 0.45, 0.0), 0.2, 0.2, 0.05, "noir175", 14)
	# la vitre de l'écran (on s'y voit : un écran qui joue), la fente des photos, les exemples
	_plaque(R, xf * T3(0.42, 1.55, 0.625), 0.5, 0.38, _ecran(R, "ecran175_photo", 2, 3.0, 1.2))
	k.box(xf * T3(0.42, 0.8, 0.63), Vector3(0.3, 0.03, 0.02), "noir175", 1.0)
	var bp: String = _tx(R, "bande_photo175", T + "bande_photo.png", Color(1, 1, 1), 0.6)
	for i2 in range(3):
		_plaque(R, xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-0.785, 1.25 + (i2 % 2) * 0.1, -0.35 + i2 * 0.3)), 0.24, 0.72, bp)
	k.box(xf * T3(0, 2.55, 0.0), Vector3(1.6, 0.4, 0.3), "noir175", 1.0)
	_plaque(R, xf * T3(0, 2.55, 0.16), 1.55, 0.39, _neon(R, "neon_photo175", T + "neon_photo.png", 4.0, 1.5))
	k.col_box(xf * T3(0, 1.15, 0.0), Vector3(1.6, 2.3, 1.26))


## Le comptoir « Jetons & Lots » : la vitrine des petits lots, les étagères du mur pleines de peluches et
## de boîtes, le néon, la caisse à tickets.
static func _comptoir_lots(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var x: float = -5.4
	var z0: float = 2.6
	var z1: float = 6.6
	var zc: float = (z0 + z1) * 0.5
	var l: float = z1 - z0
	k.box(R.L(x, 0.48, zc), Vector3(0.7, 0.96, l), "noir175", 1.0)
	k.box(R.L(x + 0.355, 0.1, zc), Vector3(0.02, 0.05, l), "neon_jaune175", 1.0)
	k.box(R.L(x + 0.355, 0.93, zc), Vector3(0.02, 0.04, l), "neon_jaune175", 1.0)
	k.box(R.L(x, 0.975, zc), Vector3(0.76, 0.03, l + 0.06), "chrome175", 1.0)
	# la vitrine (le haut du comptoir) et ses petits lots
	k.box(R.L(x + 0.05, 1.18, zc), Vector3(0.6, 0.38, l - 0.1), "vitre175", 1.0)
	k.box(R.L(x + 0.05, 1.375, zc), Vector3(0.62, 0.02, l - 0.08), "chrome175", 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17511
	var cols: Array = [Color(0.3, 0.8, 0.35), Color(1.0, 0.55, 0.15), Color(1.0, 0.6, 0.75), Color(0.55, 0.75, 1.0), Color(1.0, 0.9, 0.4), Color(0.75, 0.55, 1.0)]
	for i in range(int(l / 0.18)):
		var c: Color = cols[i % cols.size()]
		var key: String = B._c(R, "lot175_%d" % (i % cols.size()), c, 0.5)
		k.box(R.L(x + rng.randf_range(-0.12, 0.2), 1.04, z0 + 0.15 + i * 0.18) * Transform3D(Basis(Vector3.UP, rng.randf() * 0.6), Vector3.ZERO), Vector3(0.07, 0.06, 0.04), key, 1.0)
	k.col_box(R.L(x, 0.7, zc), Vector3(0.7, 1.4, l))
	# la machine à tickets, sur le comptoir
	k.box(R.L(x - 0.05, 1.55, z1 - 0.35), Vector3(0.3, 0.3, 0.3), "rouge175", 1.0)
	k.box(R.L(x + 0.11, 1.6, z1 - 0.35), Vector3(0.02, 0.12, 0.2), "neon_jaune175", 1.0)
	# les étagères du mur, et ce qu'il y a dessus
	B._c(R, "etagere175", Color(0.95, 0.95, 0.97), 0.4)
	k.box(R.L(-hw + 0.03, 1.6, zc), Vector3(0.04, 2.2, l), "noir175", 1.0)
	for yy in [0.95, 1.5, 2.05, 2.6]:
		k.box(R.L(-hw + 0.22, yy, zc), Vector3(0.38, 0.03, l), "etagere175", 1.0)
		k.box(R.L(-hw + 0.41, yy - 0.025, zc), Vector3(0.01, 0.02, l), "neon_cyan175", 1.0)
	var n: int = 0
	for yy2 in [0.95, 1.5, 2.05]:
		var zz: float = z0 + 0.2
		while zz < z1 - 0.15:
			var c2: Color = cols[n % cols.size()]
			var key2: String = B._c(R, "lot175_%d" % (n % cols.size()), c2, 0.5)
			if n % 3 == 0 and yy2 < 2.0:
				var pk: String = B._c(R, "peluche175_%d" % (n % cols.size()), c2, 0.95)
				_boule(M, pk, Vector3(-hw + 0.2, yy2 + 0.13, zz), 0.12, Vector3(1.0, 0.9, 1.0))
				zz += 0.32
			else:
				var hb: float = rng.randf_range(0.14, 0.3)
				k.box(R.L(-hw + 0.2, yy2 + 0.015 + hb * 0.5, zz), Vector3(0.22, hb, 0.18), key2, 1.0)
				zz += 0.24
			n += 1
	# les grosses peluches, tout en haut (les lots qu'on n'a jamais)
	var gros: Array = [[Color(0.3, 0.8, 0.35), 3.4], [Color(1.0, 0.6, 0.75), 4.6], [Color(1.0, 0.9, 0.4), 5.8]]
	for g in gros:
		var gk: String = B._c(R, "grosse175_%d" % int(float(g[1]) * 10.0), g[0], 0.95)
		_boule(M, gk, Vector3(-hw + 0.25, 2.88, float(g[1])), 0.24, Vector3(1.0, 1.0, 1.0))
		_boule(M, gk, Vector3(-hw + 0.25, 3.22, float(g[1])), 0.15)
	_plaque(R, R.L(-hw + 0.05, 3.88, zc, 90.0), 3.4, 0.85, _neon(R, "neon_jetons175", T + "neon_jetons.png", 2.0, 1.5))


## L'entrée : le changeur de jetons, le frigo à sodas, la banquette des parents qui attendent, une
## table haute et ses tabourets.
static func _entree_arcade(M) -> void:
	var R = M.R
	var k = R.kit
	var hd: float = R.D * 0.5
	var hw: float = R.W * 0.5
	# le changeur (face à la salle)
	var cx: Transform3D = R.L(2.75, 0, hd - 0.3, 180.0)
	k.box(cx * T3(0, 0.8, 0), Vector3(0.75, 1.6, 0.45), "borne_bleu175", 1.0)
	k.box(cx * T3(0, 1.2, 0.23), Vector3(0.6, 0.45, 0.01), _lum(R, "jetons_ecran175", Color(1.0, 0.8, 0.2), 2.2), 1.0)
	k.box(cx * T3(0, 0.5, 0.24), Vector3(0.4, 0.12, 0.08), "chrome175", 1.0)
	k.box(cx * T3(0.22, 0.9, 0.23), Vector3(0.04, 0.12, 0.01), "diode_rouge175", 1.0)
	var lb: Label3D = B._ecrit(M, 2.75, 1.68, hd - 0.3, 180.0, "JETONS", 56, Color(1.0, 0.85, 0.3), 0.0035, 0.26)
	lb.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
	k.col_box(cx * T3(0, 0.8, 0), Vector3(0.75, 1.6, 0.45))
	# le frigo à sodas (sa porte vitrée, les canettes alignées, la lumière dedans)
	var fx: Transform3D = R.L(-hw + 0.4, 0, hd - 1.0, 90.0)
	k.box(fx * T3(0, 0.98, 0), Vector3(0.9, 1.96, 0.7), "blanc175", 1.0)
	k.box(fx * T3(0, 1.05, 0.33), Vector3(0.78, 1.6, 0.02), _lum(R, "frigo175", Color(0.75, 0.9, 1.0), 0.8), 1.0)
	var canettes: Array = [Color(0.95, 0.2, 0.6), Color(0.2, 0.85, 1.0), Color(0.45, 1.0, 0.4), Color(1.0, 0.8, 0.2)]
	for r in range(4):
		for c in range(6):
			var ck: String = B._c(R, "canette175_%d" % ((r + c) % 4), canettes[(r + c) % 4], 0.25, 0.6)
			k.cyl(fx * T3(-0.3 + c * 0.12, 0.38 + r * 0.38, 0.34), 0.033, 0.033, 0.12, ck, 10)
	k.box(fx * T3(0, 1.05, 0.35), Vector3(0.8, 1.62, 0.01), "vitre175", 1.0)
	k.box(fx * T3(0, 1.88, 0.355), Vector3(0.7, 0.12, 0.01), _lum(R, "frigo_haut175", Color(1.0, 0.3, 0.7), 2.0), 1.0)
	k.col_box(fx * T3(0, 0.98, 0), Vector3(0.9, 1.96, 0.7))
	# la banquette, contre le mur de devant
	var bx: Transform3D = R.L(-4.6, 0, hd - 0.32, 180.0)
	k.box(bx * T3(0, 0.22, 0), Vector3(3.0, 0.44, 0.55), "noir175", 1.0)
	k.box(bx * T3(0, 0.49, 0.02), Vector3(3.0, 0.1, 0.52), "skai175", 1.0)
	k.box(bx * T3(0, 0.8, -0.24), Vector3(3.0, 0.55, 0.12), "skai175", 1.0)
	k.box(bx * T3(0, 0.05, 0.27), Vector3(3.0, 0.02, 0.02), "neon_violet175", 1.0)
	k.col_box(bx * T3(0, 0.5, 0), Vector3(3.0, 1.0, 0.55))
	# une table haute, deux tabourets
	k.cyl(R.L(-3.3, 0, 6.6), 0.25, 0.25, 0.04, "chrome175", 16)
	k.cyl(R.L(-3.3, 0.04, 6.6), 0.04, 0.04, 1.02, "chrome175", 10)
	k.cyl(R.L(-3.3, 1.06, 6.6), 0.38, 0.38, 0.04, "noir175", 20)
	k.ring(R.L(-3.3, 1.06, 6.6), 0.37, 0.39, 0.04, "neon_rose175", 24)
	k.col_cyl(R.P(-3.3, 0, 6.6), 0.4, 1.1)
	for t in [[-2.7, 6.9], [-3.85, 6.2]]:
		k.cyl(R.L(float(t[0]), 0, float(t[1])), 0.03, 0.03, 0.72, "chrome175", 8)
		k.cyl(R.L(float(t[0]), 0.72, float(t[1])), 0.18, 0.17, 0.08, "skai175", 14)
		k.ring(R.L(float(t[0]), 0.3, float(t[1])), 0.14, 0.16, 0.02, "chrome175", 14)
	# deux sodas oubliés sur la table
	k.cyl(R.L(-3.2, 1.1, 6.5), 0.033, 0.033, 0.12, "canette175_0", 10)
	k.cyl(R.L(-3.42, 1.1, 6.7), 0.033, 0.033, 0.12, "canette175_1", 10)


## La boule à facettes, au-dessus de la machine à danser (elle tourne), sa tige.
static func _boule_facettes(M, p: Vector3) -> void:
	var R = M.R
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.87, 0.92)
	m.metallic = 1.0
	m.roughness = 0.08
	var mi: MeshInstance3D = Sud._boule(M.room, m, R.P(p.x, p.y, p.z), 0.32)
	mi.name = "Boule_facettes175"
	var sm: SphereMesh = mi.mesh
	sm.radial_segments = 16
	sm.rings = 10
	(M.ctx["anims170"] as Array).append([mi, "tourne", Vector3.UP, 0.6])
	_tube(R, p + Vector3.UP * 0.32, Vector3(p.x, R.H, p.z), 0.008, "chrome175", 4)


# =================================================================== l'Arcade : la vie

static func _arcade(M) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_plafond_arcade(M)
	_mur_du_fond(M)
	_bornes(M)
	_kart(M, hw - 1.05, -7.4, -90.0, 1)
	_kart(M, hw - 1.05, -5.2, -90.0, 2)
	var tapis: Vector2 = _danse(M, hw - 0.95, -1.6, -90.0)
	_boule_facettes(M, Vector3(tapis.x - 0.6, R.H - 1.1, tapis.y))
	_palet(M, 2.8, 1.6)
	_pince(M, hw - 0.55, 2.0, -90.0, 0)
	_pince(M, hw - 0.55, 3.15, -90.0, 1)
	_plaque(R, R.L(hw - 0.05, 3.3, 2.6, -90.0), 2.4, 0.6, _neon(R, "neon_pince175", T + "neon_pince.png", 0.0, 1.5))
	_photomaton(M, hw - 0.7, 6.2, -90.0)
	_comptoir_lots(M)
	_entree_arcade(M)
	# les lumières : des taches de couleur (rose, cyan, violet), du blanc chaud sur le comptoir ; celle de
	# la machine à danser change de couleur (tick)
	L4._omni(M, Vector3(-4.0, 3.9, -5.0), Color(1.0, 0.35, 0.8), 1.4, 8.5)
	L4._omni(M, Vector3(4.0, 3.9, -5.0), Color(0.3, 0.85, 1.0), 1.4, 8.5)
	L4._omni(M, Vector3(0.0, 3.9, 1.5), Color(0.62, 0.42, 1.0), 1.3, 9.0)
	L4._omni(M, Vector3(-5.6, 2.8, 4.6), Color(1.0, 0.86, 0.7), 1.0, 5.5)
	L4._omni(M, Vector3(5.4, 2.8, 4.0), Color(1.0, 0.55, 0.85), 0.9, 6.0)
	L4._omni(M, Vector3(0.0, 2.8, 7.2), Color(0.85, 0.85, 1.0), 0.7, 6.0)
	var disco: OmniLight3D = L4._omni(M, Vector3(tapis.x - 0.8, 3.4, tapis.y), Color(1, 0.3, 0.8), 1.6, 6.0)
	M.ctx["disco175"] = disco
	# les gens
	_gens_arcade(M, tapis)
	# ce qu'on y fait
	var neo: Node = M.main.get("neo_v94")
	var jouer := func() -> void:
		M.main.sfx("arcade")
		if neo != null and neo.has_method("_arcade_jeu"):
			neo._arcade_jeu()
		else:
			M.say("Le petit dragon de pixels saute, crache du feu, ramasse trois pièces… et tombe dans un trou. Le public fait « ooooh ». Encore une !", 6.0)
	M.act(R.P(0.15, 0.0, -hd + 2.05), "E : jouer à Dragon-Pixel", jouer, 1.0)
	var records := func() -> void:
		M.say("MEILLEURS SCORES. 1. TURBO, 98 700. 2. TURBO, 91 200. 3. MIO, 88 800. 4. GLITCH… et tout en bas, « ??? », 100 points. Quelqu'un a appuyé sur le mauvais bouton.", 7.0)
	M.act(R.P(4.1, 0.0, -hd + 1.0), "E : lire les meilleurs scores", records, 1.2)
	var carpe := func() -> void:
		M.main.sfx("arcade")
		M.say(str(B._pick(M, ["Ta carpe-vaisseau nage entre les étoiles, crache des bulles de lumière… Trois méduses touchées ! Puis une quatrième te touche. « L'ESPACE EST UNE MARE », dit l'écran.",
			"Carpe Cosmos : tu esquives une planète, tu attrapes une étoile dorée, ta carpe brille… et te voilà au niveau 2 ! Derrière toi, un enfant applaudit."])), 6.0)
	M.act(R.P(-hw + 1.4, 0.0, -8.4), "E : jouer à Carpe Cosmos", carpe, 1.0)
	var course := func() -> void:
		M.main.sfx("arcade")
		var place: int = 1 + B._r(M).randi() % 5
		M.say("Néo-Kart : feu rouge, feu rouge, VERT ! Ton kart file vers le soleil couchant, dérape dans le virage des néons… Tu finis %s." % ["premier ! Ton voisin te tape dans la main", "deuxième, d'un pare-chocs", "troisième (une banane de pixels, pas de chance)", "quatrième, mais avec style", "dernier… mais tu as fait le plus beau dérapage de la soirée"][place - 1], 7.0)
	var kp: Vector2 = _rp(hw - 1.05, -5.2, -90.0, 0.43, 1.2)
	M.act(R.P(kp.x, 0.0, kp.y), "E : faire une course de Néo-Kart", course, 1.1)
	var danser := func() -> void:
		M.main.sfx("arcade")
		M.ctx["fete175"] = 6.0
		M.say(str(B._pick(M, ["Tu montes sur le tapis. Haut, droite, bas, bas, gauche… L'écran clignote : « PARFAIT ! » « PARFAIT ! » « … OUPS ». La boule à facettes tourne plus vite.",
			"Robo-Rythme : le petit robot de l'écran danse avec toi. Tu rates une flèche sur deux, mais tu ris si fort que tout le monde danse aussi."])), 6.5)
	M.act(R.P(tapis.x - 1.15, 0.0, tapis.y), "E : danser sur Robo-Rythme", danser, 1.0)
	var palet := func() -> void:
		M.main.sfx("arcade")
		M.ctx["palet_vite175"] = 5.0
		M.say(str(B._pick(M, ["Tac ! Tac ! Le palet file sur son coussin d'air, rebondit sur la bande… BUT ! 7 à 6. Tu lèves les bras.",
			"Le palet glisse si vite qu'on ne le voit plus. Tac, tac, tac… il saute par-dessus la bande et roule sous la machine à danser. Tout le monde le cherche."])), 6.0)
	M.act(R.P(2.8 - 1.45, 0.0, 1.6), "E : jouer au palet", palet, 1.0)
	var pince := func() -> void:
		var st: Dictionary = M.state()
		var n: int = int(st.get("pince175", 0)) + 1
		st["pince175"] = n
		M.ctx["pince_vite175"] = 3.0
		if n % 5 == 0:
			M.say("La pince descend… attrape un petit dragon vert par l'oreille… remonte… et le lâche JUSTE au-dessus du trou ! Il tombe dans le bac. La petite fille qui regardait pousse un cri de joie : tu le lui donnes. Elle le serre si fort que ses yeux de feutre louchent.", 9.0)
		else:
			M.say(str(B._pick(M, ["La pince descend, attrape une carpe orange… et la lâche. Comme toujours. « Elle est réglée sur “presque” », dit Octet.",
				"La pince descend, serre… rien. Elle remonte en tremblant, toute fière d'elle.", "Elle attrape deux peluches à la fois ! … Et les lâche toutes les deux. Presque !"])), 6.0)
	var pp: Vector2 = _rp(hw - 0.55, 2.0, -90.0, 0.0, 1.0)
	M.act(R.P(pp.x, 0.0, pp.y), "E : essayer la pince", pince, 1.0)
	var photo := func() -> void:
		M.ctx["flash175"] = 1.0
		M.say("Tu tires le rideau. « 3… 2… 1… » FLASH ! Quatre photos : une normale, une qui louche, une qui tire la langue, une floue. La bande tombe dans la fente, encore tiède. Le photomaton y a ajouté des étoiles et un petit dragon.", 8.0)
	var ph: Vector2 = _rp(hw - 0.7, 6.2, -90.0, 0.0, 1.15)
	M.act(R.P(ph.x, 0.0, ph.y), "E : faire une photo", photo, 1.1)
	var jetons := func() -> void:
		M.say("Tu glisses une pièce dans le changeur. Il réfléchit, clignote, et crache cinq jetons dorés, frappés d'un petit dragon. Clink-clink-clink !", 6.0)
	M.act(R.P(2.75, 0.0, hd - 1.0), "E : changer une pièce en jetons", jetons, 1.0)
	M.ctx["tick170"] = func(delta: float) -> void:
		_tick_arcade(M, delta)
	M.ctx["cloche170"] = false
	M.ctx["entree"] = "L'Arcade du Dragon-Pixel : la moquette qui luit comme un ciel d'étoiles, des bips partout, les écrans qui jouent tout seuls, la machine à danser et sa boule à facettes, les pinces à peluches… et au fond, la grande borne du Dragon-Pixel, où Turbo défend son record."


## Les gens de l'arcade : Octet (l'androïde du comptoir), Turbo devant la grande borne (le jour), Kira sur
## la machine à danser ; des joueurs aux bornes, deux pilotes de Néo-Kart, une fille devant la pince.
static func _gens_arcade(M, tapis: Vector2) -> void:
	var R = M.R
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var hr: float = float(M.ctx.get("hour", 14.0))
	var donner := func() -> void:
		M.say("Octet te tend une poignée de tickets roses : « Dix tickets. Encore neuf cent quatre-vingt-dix, et le grand dragon en peluche est à toi. » Ses yeux clignotent : c'est sa façon de sourire.", 7.0)
	var st0: String = str(M.ctx.get("style", "neo"))
	M.ctx["style"] = "neo_android"
	B._marchand(M, -6.5, 4.6, 90.0, "comptoir", "homme", "Octet",
		["Bienvenue à l'Arcade du Dragon-Pixel. Ouverte à toute heure : la ville ne dort pas, et les dragons non plus.",
			"Je compte les tickets, je rends la monnaie, je souffle sur les écrans quand ils toussent. Et je ne joue jamais. … Bon. Parfois. La nuit.",
			"Turbo a battu son propre record trois fois cette semaine. Je lui ai dit de rentrer dormir. Il m'a dit « encore une ».",
			"La pince est réglée sur « presque ». C'est le réglage le plus juste : presque tout le monde gagne presque toujours."],
		{"bonjour": "Bip ! Bienvenue à l'Arcade. Jetons, sodas, tickets, lots : je m'occupe de tout. Sauf des records : ça, c'est Turbo.",
			"vend": {"soda_neon": 8, "jus_pomme": 6},
			"services": [{"label": "Échanger mes tickets contre un lot", "cb": donner}],
			"infos": ["L'arcade a ouvert le jour où la Tour Axiome a été finie. Les ouvriers venaient y jouer après le travail. Le premier record de Dragon-Pixel, c'était Zéro, le balayeur : 1 200 points. Il en est encore fier.",
				"Le grand dragon de néon, au fond, c'est Kenji qui l'a réparé, avec son bras bionique. Avant, il ne disait que « DRAGON PIX ». Les gens l'appelaient « le dragon qui a faim ».",
				"Les bornes jouent toutes seules, la nuit, quand il n'y a personne. Je laisse faire : elles s'entraînent.",
				"La machine à danser, c'est Kira qui la préfère. Elle danse si bien que le robot de l'écran s'arrête pour la regarder."]})
	M.ctx["style"] = st0
	M.ctx["cloche170"] = false
	M.ctx["bonjour170"] = ["Bip ! Un nouveau joueur ! Les jetons, c'est par ici.", "Bienvenue au pays des bips. Tu veux un soda ?"]
	M.ctx["bonjour_nuit170"] = ["Bip… Il est tard, mais l'arcade ne ferme jamais. Les bornes non plus.", "La nuit, c'est l'heure des records. Et des sodas."]
	# Turbo (le jour), devant la grande borne
	if hr >= 9.0 and hr < 21.0:
		var lt: Array = ["À toi. Montre-moi ce que tu sais faire.", "Saute AVANT le trou. Pas dans le trou. Avant.", "Pas mal… pour un débutant."]
		var t: Node = B._habitue(M, "turbo", -1.05, -hd + 2.05, 160.0, "bras_croises", lt)
		if t == null:
			var t2: Node = M.person("garcon", -1.05, -hd + 2.05, 160.0, "bras_croises", "Turbo")
			t2.lines = lt
		var k2: Node = B._habitue(M, "kira", tapis.x, tapis.y, 90.0, "danse", ["Haut, droite, bas… Tu viens ? Le tapis, c'est mieux à deux !"])
		if k2 == null:
			var k3: Node = M.person("femme", tapis.x, tapis.y, 90.0, "danse")
			k3.lines = ["Haut, droite, bas… Tu viens ? Le tapis, c'est mieux à deux !"]
		B._clients(M, [["garcon", -hw + 1.25, -7.48, -90.0, "debout", ["Chut, je vais battre mon record.", "Méduse à gauche ! À GAUCHE !"]],
			["fille", -hw + 1.25, -5.64, -90.0, "debout", ["Le dragon vert, c'est moi qui le fais sauter.", "Tu as un jeton ? Juste un ?"]],
			["homme", -1.3, -4.28, 90.0, "debout", ["Quand j'étais petit, il n'y avait que trois bornes. Et pas de soda.", "Encore une partie, et je rentre. Promis."]],
			["garcon", 4.25, 1.6, -90.0, "colere", ["Il est trop rapide, ce palet !", "Revanche !"]],
			["fille", hw - 1.75, 3.15, 90.0, "debout", ["Le dragon vert… je le veux… presque…", "La pince, elle fait exprès."]],
			["homme", 1.5, -hd + 2.6, -150.0, "applaudir", ["Bravo, Turbo ! … Ah, ce n'était pas Turbo ?"]]])
		var ka: Vector2 = _rp(hw - 1.05, -7.4, -90.0, -0.43, 0.6)
		var kb: Vector2 = _rp(hw - 1.05, -7.4, -90.0, 0.43, 0.6)
		var pa: Node = M.person("garcon", ka.x, ka.y, 90.0, "assis")
		pa.lines = ["Vroum ! Pousse-toi, j'arrive !", "Le virage des néons, je le prends sans freiner."]
		var pb: Node = M.person("femme", kb.x, kb.y, 90.0, "assis")
		pb.lines = ["Mon fils me bat à chaque fois. Chaque. Fois.", "Je freine trop. Il paraît."]
	else:
		B._clients(M, [["homme", -hw + 1.25, -6.56, -90.0, "debout", ["La nuit, l'arcade est à moi. Enfin, à moi et aux bornes.", "Chut… niveau douze."]],
			["femme", -1.3, -5.2, 90.0, "debout", ["Je sors du travail. Une partie, et au lit. … Bon, deux.", "Carpe Cosmos, c'est ma méditation."]]])


## Ce qui bouge : le palet qui file, les pinces qui se promènent, le tapis et la lumière de la danse qui
## battent la mesure, le flash du photomaton.
static func _tick_arcade(M, delta: float) -> void:
	var t: float = float(M.ctx.get("t170", 0.0))
	var pv: float = maxf(0.0, float(M.ctx.get("palet_vite175", 0.0)) - delta)
	M.ctx["palet_vite175"] = pv
	var pl: Variant = M.ctx.get("palet175", null)
	if pl is Array and is_instance_valid(pl[0]):
		var v: float = 0.7 + (1.6 if pv > 0.0 else 0.0)
		var ux: float = 2.0 * absf(fposmod(t * v * 0.37, 2.0) - 1.0) - 1.0
		var uz: float = 2.0 * absf(fposmod(t * v * 0.61 + 0.3, 2.0) - 1.0) - 1.0
		(pl[0] as Node3D).global_position = (pl[1] as Vector3) + Vector3(ux * 0.98, 0.0, uz * 0.47)
	var pin_v: float = maxf(0.0, float(M.ctx.get("pince_vite175", 0.0)) - delta)
	M.ctx["pince_vite175"] = pin_v
	for p in M.ctx.get("pinces175", []):
		if not is_instance_valid(p[0]):
			continue
		var g: float = float(p[3])
		var bs: Basis = p[2]
		var desc: float = 0.25 * maxf(0.0, sin(t * 0.5 + g)) if pin_v <= 0.0 else 0.4 * sin(clampf(3.0 - pin_v, 0.0, 3.0) / 3.0 * PI)
		var off := Vector3(0.3 * sin(t * 0.31 + g * 2.0), -desc, 0.25 * sin(t * 0.23 + g))
		(p[0] as Node3D).global_position = (p[1] as Vector3) + bs * off
	var fete: float = maxf(0.0, float(M.ctx.get("fete175", 0.0)) - delta)
	M.ctx["fete175"] = fete
	var bpm: float = 2.2 if fete <= 0.0 else 3.2
	var beat: float = fposmod(t * bpm, 1.0)
	var tap: Variant = M.ctx.get("tapis175", null)
	if tap is StandardMaterial3D:
		(tap as StandardMaterial3D).emission_energy_multiplier = 0.6 + 2.2 * pow(1.0 - beat, 3.0)
	var dl: Variant = M.ctx.get("disco175", null)
	if dl is OmniLight3D and is_instance_valid(dl):
		(dl as OmniLight3D).light_color = Color.from_hsv(fposmod(t * (0.08 if fete <= 0.0 else 0.3), 1.0), 0.75, 1.0)
		(dl as OmniLight3D).light_energy = 1.2 + 0.8 * pow(1.0 - beat, 2.0)
	var fl: float = maxf(0.0, float(M.ctx.get("flash175", 0.0)) - delta)
	M.ctx["flash175"] = fl
	if fl > 0.0 and not M.ctx.has("flash_l175"):
		var R = M.R
		M.ctx["flash_l175"] = L4._omni(M, Vector3(R.W * 0.5 - 1.6, 2.0, 6.2), Color(1, 1, 1), 0.0, 6.0)
	var fll: Variant = M.ctx.get("flash_l175", null)
	if fll is OmniLight3D and is_instance_valid(fll):
		(fll as OmniLight3D).light_energy = 6.0 * maxf(0.0, fl - 0.6) / 0.4 if fl > 0.6 else 0.0
	L4._tick(M, delta)


# =================================================================== les bus peints : la coque

## La hauteur des parois (là où commence la voûte) ; les fenêtres : leur bas, leur hauteur ; les fenêtres
## des côtés (x, repère de la pièce : sept de chaque côté, comme dehors ; la septième, côté droit, est la
## porte) ; la porte.
const BUS_HS: float = 1.84
const BUS_FY: float = 1.0
const BUS_FH: float = 0.62
const BUS_FX: Array = [-3.0, -2.05, -1.1, -0.15, 0.8, 1.75, 2.7]
const BUS_PORTE: float = 3.15


static func _mats_bus(R, met: String) -> void:
	var b: Dictionary = BUS[met]
	var pa: Color = b["pastel"]
	_tx(R, "plancher175", "montjoie/bois_planches.png", Color(0.86, 0.7, 0.55), 0.8)
	_tx(R, "lambris175", "maisons/lambris_blanc.png", pa.darkened(0.06), 0.85)
	_tx(R, "paroi175", "beau161/bois_peint.png", pa, 0.85)
	_tx(R, "lattes175", "neo156/lattes_bois.png", Color(0.97, 0.88, 0.74), 0.8)
	_tx(R, "rideau_bus175", T + "indienne.png", Color(1, 1, 1), 0.95)
	_tx(R, "patchwork175", T + "patchwork.png", Color(1, 1, 1), 0.95)
	_tx(R, "kilim175", T + "kilim.png", Color(1, 1, 1), 0.95)
	_tx(R, "tweed175", "beau161/tweed.png", (b["c2"] as Color).lerp(Color(0.9, 0.85, 0.75), 0.35), 0.95)
	B._c(R, "peint175", b["c"], 0.5)
	B._c(R, "peint2_175", b["c2"], 0.5)
	B._c(R, "joint175", Color(0.07, 0.07, 0.07), 0.85)
	B._c(R, "chrome175", Color(0.85, 0.86, 0.9), 0.15, 0.9)
	B._c(R, "tableau175", Color(0.13, 0.13, 0.14), 0.6)
	B._c(R, "siege_bus175", Color(0.55, 0.35, 0.22), 0.55)
	B._c(R, "matelas175", Color(0.94, 0.92, 0.86), 0.95)
	B._c(R, "inox175", Color(0.75, 0.76, 0.78), 0.25, 0.8)
	B._verre(R, "vitre_bus175", Color(0.85, 0.9, 0.95), 0.1)
	_lum(R, "cadran175", Color(0.95, 0.9, 0.7), 1.2)
	var vue: String = "vue_%s_%s.png" % [str(b["vue"]), "jour" if R.day else "nuit"]
	_image(R, "vue175", T + vue, 1.0 if R.day else 0.85)


## La coque d'un bus : le plancher, les parois (le lambris en bas, le bois peint en haut ; les fenêtres
## et leurs rideaux ; la porte), le pare-brise, la voûte de lattes et ses arceaux peints.
static func _coque_bus(M, met: String) -> void:
	var R = M.R
	var k = R.kit
	_mats_bus(R, met)
	R.door_x = BUS_PORTE
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	k.box(R.L(0, -0.05, 0), Vector3(R.W, 0.1, R.D), "plancher175", 1.2, 4)
	k.col_box(R.L(0, -0.5, 0), Vector3(R.W + 2.0, 1.0, R.D + 2.0))
	k.col_box(R.L(0, R.H + 0.45, 0), Vector3(R.W + 2.0, 0.9, R.D + 2.0))
	# les côtés (u : la part de la vue derrière chaque fenêtre) : à gauche (-z), à droite (+z, la porte)
	var ouv_g: Array = []
	for x in BUS_FX:
		ouv_g.append([float(x), 0.75, BUS_FY, BUS_FH])
	_paroi(M, R.L(0, 0, -hd, 0), R.W, ouv_g, 0.0, 0.5)
	var ouv_d: Array = []
	for i in range(6):
		ouv_d.append([-float(BUS_FX[i]), 0.75, BUS_FY, BUS_FH])
	ouv_d.append([-BUS_PORTE, 0.8, 0.0, 1.95])
	_paroi(M, R.L(0, 0, hd, 180), R.W, ouv_d, 0.5, 1.0)
	# le pare-brise (devant, deux vitres), les deux vitres de l'arrière
	_paroi(M, R.L(hw, 0, 0, -90), R.D, [[-0.5, 0.9, 0.98, 0.76], [0.5, 0.9, 0.98, 0.76]], 0.3, 0.7)
	_paroi(M, R.L(-hw, 0, 0, 90), R.D, [[-0.55, 0.6, 1.05, 0.5], [0.55, 0.6, 1.05, 0.5]], 0.3, 0.7)
	_porte_bus(M, R.L(0, 0, hd, 180))
	_voute(M)


## Une paroi du bus (xf : son pied, au milieu ; +Z vers la pièce) et ses ouvertures [x, largeur, bas,
## hauteur] (une porte si le bas est au sol) ; u0, u1 : la part de la vue qu'on voit de ce côté.
static func _paroi(M, xf: Transform3D, longueur: float, ouv: Array, u0: float, u1: float) -> void:
	var R = M.R
	var k = R.kit
	var hl: float = longueur * 0.5
	var xs: Array = [-hl, hl]
	for o in ouv:
		xs.append(float(o[0]) - float(o[1]) * 0.5)
		xs.append(float(o[0]) + float(o[1]) * 0.5)
	xs.sort()
	for i in range(xs.size() - 1):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b - a < 0.005:
			continue
		var parts: Array = [[0.0, BUS_HS]]
		for o2 in ouv:
			if absf((a + b) * 0.5 - float(o2[0])) < float(o2[1]) * 0.5:
				parts = L4._sans(parts, float(o2[2]), float(o2[2]) + float(o2[3]))
		for p in parts:
			var y0: float = p[0]
			var y1: float = p[1]
			if y0 < 0.95:
				L4._pan(R, "lambris175", xf, a, b, y0, minf(0.95, y1), 0.9)
			if y1 > 0.95:
				L4._pan(R, "paroi175", xf, a, b, maxf(0.95, y0), y1, 1.2)
	# la baguette peinte, en haut du lambris (pas devant la porte)
	var bords: Array = [[-hl, hl]]
	for o3 in ouv:
		if float(o3[2]) < 0.5:
			var nb: Array = []
			for bd in bords:
				for q in L4._sans([bd], float(o3[0]) - float(o3[1]) * 0.5, float(o3[0]) + float(o3[1]) * 0.5):
					nb.append(q)
			bords = nb
	for bd2 in bords:
		var l: float = float(bd2[1]) - float(bd2[0])
		if l > 0.05:
			k.box(xf * T3((float(bd2[0]) + float(bd2[1])) * 0.5, 0.95, 0.015), Vector3(l, 0.045, 0.03), "peint175", 1.0)
			k.box(xf * T3((float(bd2[0]) + float(bd2[1])) * 0.5, 0.04, 0.012), Vector3(l, 0.08, 0.024), "peint175", 1.0)
	for o4 in ouv:
		if float(o4[2]) > 0.5:
			var uc: float = u0 + (u1 - u0) * (float(o4[0]) + hl) / longueur
			var du: float = (u1 - u0) * float(o4[1]) / longueur
			_fenetre_bus(M, xf, float(o4[0]), float(o4[2]), float(o4[1]), float(o4[3]), uc - du * 0.5, uc + du * 0.5)
	k.col_box(xf * T3(0, BUS_HS * 0.5, -0.5), Vector3(longueur + 1.0, BUS_HS + 0.8, 1.0))


## Une fenêtre du bus (repère de la paroi) : ce qu'on voit dehors (la vue, sa part [ua, ub]), la vitre, le
## joint de caoutchouc, l'ébrasement, la tablette ; les rideaux à fleurs, noués de chaque côté.
static func _fenetre_bus(M, xf: Transform3D, cx: float, y0: float, w: float, h: float, ua: float, ub: float) -> void:
	var R = M.R
	var k = R.kit
	var yc: float = y0 + h * 0.5
	# la vue : la bande de l'horizon (le haut de l'image : le ciel)
	var va: float = 0.5 - h * 0.42
	var vb: float = 0.5 + h * 0.42
	_plaque(R, xf * T3(cx, yc, -0.08), w + 0.04, h + 0.04, "vue175", Vector2(ua, va), Vector2(ub, vb))
	k.box(xf * T3(cx, yc, -0.03), Vector3(w, h, 0.006), "vitre_bus175", 1.0)
	for s in [-1.0, 1.0]:
		k.box(xf * T3(cx + s * (w * 0.5 + 0.005), yc, -0.035), Vector3(0.01, h + 0.02, 0.07), "paroi175", 1.0)
		k.box(xf * T3(cx, yc + s * (h * 0.5 + 0.005), -0.035), Vector3(w + 0.02, 0.01, 0.07), "paroi175", 1.0)
		k.box(xf * T3(cx + s * (w * 0.5 - 0.012), yc, 0.005), Vector3(0.026, h, 0.012), "joint175", 1.0)
		k.box(xf * T3(cx, yc + s * (h * 0.5 - 0.012), 0.005), Vector3(w, 0.026, 0.012), "joint175", 1.0)
	k.box(xf * T3(cx, y0 - 0.015, 0.055), Vector3(w + 0.12, 0.03, 0.11), "bois", 1.0)
	# les rideaux : la tringle, deux pans plissés noués sur les côtés
	if h < 0.7:
		k.box(xf * T3(cx, y0 + h + 0.07, 0.04), Vector3(w + 0.32, 0.012, 0.012), "chrome175", 1.0)
		var hh: float = h + 0.16
		for s2 in [-1.0, 1.0]:
			for j in range(3):
				var px: float = cx + s2 * (w * 0.5 + 0.03 + j * 0.055)
				var pz: float = 0.04 + (0.022 if j % 2 == 1 else 0.0)
				_plaque(R, xf * T3(px, y0 + h + 0.06 - hh * 0.5, pz), 0.065, hh, "rideau_bus175", Vector2(j * 0.25, 0.0), Vector2(j * 0.25 + 0.26, hh / 0.25))
			k.box(xf * T3(cx + s2 * (w * 0.5 + 0.09), y0 + h * 0.32, 0.075), Vector3(0.13, 0.022, 0.035), "peint2_175", 1.0)


## La porte du bus, vue de dedans (repère de la paroi droite) : le bas peint, le haut vitré (la prairie
## derrière), la poignée ; la marche et sa bande jaune.
static func _porte_bus(M, xf: Transform3D) -> void:
	var R = M.R
	var k = R.kit
	var cx: float = -BUS_PORTE
	k.box(xf * T3(cx, 0.5, -0.02), Vector3(0.8, 1.0, 0.04), "peint175", 1.0)
	_plaque(R, xf * T3(cx, 1.42, -0.09), 0.7, 0.8, "vue175", Vector2(0.92, 0.25), Vector2(0.98, 0.75))
	k.box(xf * T3(cx, 1.42, -0.03), Vector3(0.66, 0.8, 0.006), "vitre_bus175", 1.0)
	for s in [-1.0, 1.0]:
		k.box(xf * T3(cx + s * 0.37, 1.45, -0.02), Vector3(0.06, 0.95, 0.04), "peint175", 1.0)
	k.box(xf * T3(cx, 1.88, -0.02), Vector3(0.8, 0.08, 0.04), "peint175", 1.0)
	k.box(xf * T3(cx, 1.0, -0.01), Vector3(0.8, 0.06, 0.04), "joint175", 1.0)
	k.box(xf * T3(cx + 0.3, 1.0, 0.03), Vector3(0.03, 0.03, 0.12), "chrome175", 1.0)
	B._c(R, "bande_jaune175", Color(0.95, 0.78, 0.15), 0.6)
	k.box(xf * T3(cx, 0.008, 0.25), Vector3(0.8, 0.016, 0.06), "bande_jaune175", 1.0)


## La voûte du bus : des lattes de bois en arc d'une paroi à l'autre, quatre arceaux peints, les deux
## pignons (devant, derrière).
static func _voute(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var H: float = R.H
	var n: int = 12
	var pts: Array = []
	for i in range(n + 1):
		var zz: float = -hd + R.D * float(i) / n
		var t: float = zz / hd
		pts.append(Vector2(zz, BUS_HS + (H - BUS_HS) * sqrt(maxf(0.0, 1.0 - t * t))))
	var o: Transform3D = R.L(0, 0, 0)
	for i2 in range(n):
		var a: Vector2 = pts[i2]
		var b: Vector2 = pts[i2 + 1]
		var nrm: Vector3 = Vector3(0, -(b.x - a.x), b.y - a.y).normalized()
		L4._q4(R, "lattes175", o, Vector3(-hw, a.y, a.x), Vector3(hw, a.y, a.x), Vector3(hw, b.y, b.x), Vector3(-hw, b.y, b.x), nrm, Vector3.RIGHT, Vector3(0, 0, 1), 0.9)
		for xr in [-2.65, -0.95, 0.75, 2.4]:
			_barre(R, Vector3(xr, a.y - 0.018, a.x), Vector3(xr, b.y - 0.018, b.x), Vector2(0.07, 0.035), "peint175")
	# les pignons : un éventail de triangles entre le haut des parois et la voûte
	for e in [[hw, -1.0], [-hw, 1.0]]:
		var x: float = float(e[0]) + float(e[1]) * 0.002
		var nn := Vector3(float(e[1]), 0, 0)
		var c: Vector3 = R.P(x, BUS_HS, 0.0)
		for i3 in range(n):
			var a2: Vector2 = pts[i3]
			var b2: Vector2 = pts[i3 + 1]
			k.tri("paroi175", c, R.P(x, a2.y, a2.x), R.P(x, b2.y, b2.x), nn, Vector2(0.0, -BUS_HS) / 1.2, Vector2(a2.x, -a2.y) / 1.2, Vector2(b2.x, -b2.y) / 1.2)
	# la frise peinte sous la voûte (le haut des parois)
	for sz in [-1.0, 1.0]:
		k.box(R.L(0, BUS_HS - 0.02, sz * (hd - 0.012)), Vector3(R.W, 0.04, 0.024), "peint2_175", 1.0)


# =================================================================== les bus : les meubles

## La cabine : le tableau de bord (ses cadrans), le volant, le siège du conducteur, le levier de vitesse,
## le rétroviseur.
static func _cabine_bus(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	k.box(R.L(hw - 0.2, 0.47, -0.31), Vector3(0.4, 0.94, R.D - 0.62), "tableau175", 1.0)
	k.box(R.L(hw - 0.24, 0.96, -0.31), Vector3(0.48, 0.04, R.D - 0.6), "joint175", 1.0)
	k.col_box(R.L(hw - 0.2, 0.5, -0.31), Vector3(0.4, 1.0, R.D - 0.62))
	for dz in [-0.68, -0.44]:
		k.cyl(R.L(hw - 0.405, 0.82, dz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.055, 0.055, 0.015, "cadran175", 16)
		k.ring(R.L(hw - 0.41, 0.82, dz) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.055, 0.065, 0.02, "chrome175", 16)
	# le volant
	var vxf: Transform3D = R.L(hw - 0.62, 1.04, -0.55) * Transform3D(Basis(Vector3.BACK, deg_to_rad(62.0)), Vector3.ZERO)
	k.ring(vxf, 0.17, 0.2, 0.03, "joint175", 22)
	k.cyl(vxf * T3(0, -0.005, 0), 0.04, 0.04, 0.04, "chrome175", 10)
	for a in [0.0, 2.1, 4.2]:
		k.box(vxf * Transform3D(Basis(Vector3.UP, a), Vector3(0.09, 0.015, 0)), Vector3(0.17, 0.012, 0.02), "joint175", 1.0)
	_tube(R, Vector3(hw - 0.42, 0.78, -0.55), Vector3(hw - 0.6, 1.02, -0.55), 0.025, "joint175", 8)
	# le siège du conducteur
	var sx: float = hw - 0.95
	k.box(R.L(sx, 0.2, -0.55), Vector3(0.46, 0.4, 0.46), "joint175", 1.0)
	k.box(R.L(sx, 0.45, -0.55), Vector3(0.52, 0.1, 0.52), "siege_bus175", 1.0)
	k.box(R.L(sx - 0.28, 0.86, -0.55) * Transform3D(Basis(Vector3.BACK, 0.12), Vector3.ZERO), Vector3(0.1, 0.72, 0.52), "siege_bus175", 1.0)
	k.col_box(R.L(sx - 0.05, 0.6, -0.55), Vector3(0.6, 1.2, 0.55))
	# le levier, le rétroviseur
	_tube(R, Vector3(hw - 0.62, 0.0, -0.12), Vector3(hw - 0.7, 0.72, -0.12), 0.012, "chrome175", 6)
	_boule(M, "joint175", Vector3(hw - 0.7, 0.74, -0.12), 0.035)
	k.box(R.L(hw - 0.12, 1.78, 0.0), Vector3(0.04, 0.09, 0.26), "joint175", 1.0)
	k.box(R.L(hw - 0.145, 1.78, 0.0), Vector3(0.006, 0.07, 0.24), "chrome175", 1.0)


## Le lit, au fond (toute la largeur) : le coffre et ses tiroirs, le matelas, le dessus-de-lit en
## patchwork, les oreillers.
static func _lit_bus(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var x: float = -hw + 0.9
	k.box(R.L(x, 0.2, 0), Vector3(1.8, 0.4, R.D), "bois", 1.0)
	for dz in [-0.55, 0.55]:
		k.box(R.L(x + 0.905, 0.2, dz), Vector3(0.02, 0.26, 0.85), "peint175", 1.0)
		k.box(R.L(x + 0.92, 0.22, dz), Vector3(0.03, 0.04, 0.16), "chrome175", 1.0)
	k.box(R.L(x, 0.49, 0), Vector3(1.76, 0.18, R.D - 0.06), "matelas175", 1.0)
	k.box(R.L(x + 0.1, 0.59, 0), Vector3(1.5, 0.025, R.D - 0.08), "patchwork175", 0.9)
	k.box(R.L(x + 0.86, 0.5, 0), Vector3(0.025, 0.2, R.D - 0.08), "patchwork175", 0.9)
	for dz2 in [-0.5, 0.5]:
		_boule(M, "drap", Vector3(-hw + 0.3, 0.66, dz2), 0.3, Vector3(0.55, 0.28, 1.25))
	_boule(M, "tissu_jaune", Vector3(-hw + 0.48, 0.68, 0.0), 0.16, Vector3(0.7, 0.9, 1.0))
	k.col_box(R.L(x, 0.3, 0), Vector3(1.8, 0.6, R.D))


## La banquette (le long de la paroi gauche) : le coffre, l'assise, les coussins du dossier, des coussins.
static func _banquette_bus(M, x0: float, x1: float, tissu: String = "tweed175") -> void:
	var R = M.R
	var k = R.kit
	var hd: float = R.D * 0.5
	var l: float = x1 - x0
	var xc: float = (x0 + x1) * 0.5
	k.box(R.L(xc, 0.2, -hd + 0.28), Vector3(l, 0.4, 0.55), "bois", 1.0)
	k.box(R.L(xc, 0.45, -hd + 0.29), Vector3(l, 0.1, 0.53), tissu, 0.6)
	var n: int = maxi(2, int(l / 0.8))
	for i in range(n):
		var bx: float = x0 + (i + 0.5) * l / n
		k.box(R.L(bx, 0.72, -hd + 0.1) * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO), Vector3(l / n - 0.04, 0.44, 0.13), tissu, 0.6)
	var cols: Array = ["tissu_rouge", "tissu_jaune", "tissu_turquoise", "tissu_rose"]
	for j in range(2):
		_boule(M, cols[(j + int(x0 * 3.0)) % cols.size()], Vector3(x0 + 0.35 + j * (l - 0.7), 0.62, -hd + 0.3), 0.17, Vector3(1.0, 0.85, 0.45))
	k.col_box(R.L(xc, 0.3, -hd + 0.28), Vector3(l, 0.6, 0.55))


## La petite cuisine (le long de la paroi droite) : les placards peints, le plan de travail, l'évier et son
## robinet, le réchaud à deux feux ; l'étagère au-dessus des fenêtres. Renvoie le centre du réchaud.
static func _cuisine_bus(M, x0: float, x1: float) -> Vector3:
	var R = M.R
	var k = R.kit
	var hd: float = R.D * 0.5
	var l: float = x1 - x0
	var xc: float = (x0 + x1) * 0.5
	var z: float = hd - 0.26
	k.box(R.L(xc, 0.43, z), Vector3(l, 0.86, 0.5), "peint2_175", 1.0)
	var n: int = maxi(2, int(l / 0.45))
	for i in range(n):
		var px: float = x0 + (i + 0.5) * l / n
		k.box(R.L(px, 0.45, z - 0.252), Vector3(l / n - 0.04, 0.72, 0.008), "paroi175", 1.0)
		k.box(R.L(px + (l / n) * 0.3, 0.7, z - 0.262), Vector3(0.02, 0.06, 0.02), "chrome175", 1.0)
	k.box(R.L(xc, 0.88, z - 0.01), Vector3(l + 0.02, 0.04, 0.54), "bois_clair", 1.0)
	k.col_box(R.L(xc, 0.45, z), Vector3(l, 0.9, 0.5))
	# l'évier, le robinet
	var ex: float = x0 + l * 0.3
	k.box(R.L(ex, 0.895, z), Vector3(0.42, 0.012, 0.34), "inox175", 1.0)
	k.box(R.L(ex, 0.885, z), Vector3(0.36, 0.01, 0.28), "joint175", 1.0)
	_tube(R, Vector3(ex, 0.9, z + 0.2), Vector3(ex, 1.12, z + 0.2), 0.012, "chrome175", 6)
	_tube(R, Vector3(ex, 1.12, z + 0.2), Vector3(ex, 1.1, z + 0.05), 0.012, "chrome175", 6)
	# le réchaud
	var rx: float = x0 + l * 0.72
	k.box(R.L(rx, 0.91, z), Vector3(0.5, 0.03, 0.36), "joint175", 1.0)
	for dx in [-0.12, 0.12]:
		k.ring(R.L(rx + dx, 0.925, z), 0.05, 0.075, 0.012, "inox175", 14)
	# l'étagère au-dessus des fenêtres
	k.box(R.L(xc, 1.7, hd - 0.1), Vector3(l, 0.03, 0.18), "bois", 1.0)
	k.box(R.L(xc, 1.75, hd - 0.012), Vector3(l, 0.07, 0.01), "peint175", 1.0)
	return Vector3(rx - 0.12, 0.94, z)


## Une bouilloire (une théière) sur le feu : x, y, z en repère de la pièce.
static func _theiere(M, p: Vector3, key: String) -> void:
	var R = M.R
	var k = R.kit
	k.cyl(R.L(p.x, p.y, p.z), 0.08, 0.06, 0.14, key, 14)
	k.cyl(R.L(p.x, p.y + 0.14, p.z), 0.04, 0.02, 0.03, key, 10)
	_boule(M, key, Vector3(p.x, p.y + 0.18, p.z), 0.018)
	_tube(R, Vector3(p.x + 0.06, p.y + 0.04, p.z), Vector3(p.x + 0.15, p.y + 0.13, p.z), 0.012, key, 6)
	k.ring(R.L(p.x - 0.09, p.y + 0.08, p.z) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.035, 0.045, 0.012, "joint175", 10)


## Le tapis de l'allée.
static func _tapis_bus(M, x: float) -> void:
	_dessus(M.R, M.R.L(x, 0.006, 0.0), 2.6, 0.96, "kilim175")


## Les guirlandes : deux fils sous la voûte, une ampoule tous les 30 cm (blanc chaud, rose, bleu, vert).
static func _guirlandes_bus(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	var e: float = 1.6 if R.day else 3.6
	var cols: Array = [Color(1.0, 0.82, 0.5), Color(1.0, 0.45, 0.65), Color(0.45, 0.75, 1.0), Color(0.55, 1.0, 0.55)]
	for i in range(cols.size()):
		_lum(R, "ampoule175_%d" % i, cols[i], e)
	B._c(R, "fil175", Color(0.12, 0.1, 0.08), 0.8)
	for z in [-0.55, 0.55]:
		var t: float = z / hd
		var y: float = BUS_HS + (R.H - BUS_HS) * sqrt(maxf(0.0, 1.0 - t * t)) - 0.05
		var prev: Vector3 = Vector3(-hw + 0.3, y, z)
		var n: int = int((R.W - 0.9) / 0.3)
		for j in range(n + 1):
			var x: float = -hw + 0.3 + j * 0.3
			var sag: float = 0.05 * sin(PI * fposmod(j, 4) / 4.0)
			var p: Vector3 = Vector3(x, y - sag, z)
			if j > 0:
				_barre(R, prev, p, Vector2(0.006, 0.006), "fil175")
			k.cyl(R.L(x, p.y - 0.05, z), 0.017, 0.021, 0.045, "ampoule175_%d" % ((j + (1 if z > 0 else 0)) % cols.size()), 8)
			prev = p


## Les lumières du bus : la journée, le jour entre par les fenêtres (une lumière douce, un peu bleue,
## devant) ; le soir, une lumière chaude.
static func _lumieres_bus(M) -> void:
	var R = M.R
	if R.day:
		L4._omni(M, Vector3(0.4, 1.85, 0.0), Color(1.0, 0.94, 0.85), 0.55, 5.5)
		L4._omni(M, Vector3(2.9, 1.6, 0.0), Color(0.85, 0.92, 1.0), 0.45, 3.5)
		L4._omni(M, Vector3(-2.6, 1.6, 0.0), Color(1.0, 0.92, 0.82), 0.35, 3.5)
	else:
		L4._omni(M, Vector3(0.4, 1.8, 0.0), Color(1.0, 0.72, 0.45), 0.75, 5.0)
		L4._omni(M, Vector3(-2.6, 1.5, 0.0), Color(1.0, 0.65, 0.4), 0.5, 3.5)


## Le commun des bus : la coque est faite ; la cabine, les guirlandes, les lumières, le tic-tac.
static func _bus_commun(M) -> void:
	_cabine_bus(M)
	_guirlandes_bus(M)
	_lumieres_bus(M)
	M.ctx["cloche170"] = false
	M.ctx["tick170"] = func(delta: float) -> void:
		L4._tick(M, delta)


## Une peluche-chat (Animaux) qui dort, sur le lit ou dans le hamac.
static func _chat(M, p: Vector3, yaw: float, v: Dictionary) -> void:
	var d: Dictionary = {"taille": 0.9, "seed": 1751}
	for kk in v:
		d[kk] = v[kk]
	L4._bete(M, "chat", d, p, yaw, "dort")


# =================================================================== le Bus du Soleil (Papy Rayon)

static func _bus_soleil(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_bus_commun(M)
	_lit_bus(M)
	_banquette_bus(M, -1.75, 0.95)
	var feu: Vector3 = _cuisine_bus(M, -1.75, 1.3)
	_tapis_bus(M, 0.35)
	# la théière qui chauffe (sa vapeur), les herbes qui sèchent, les bocaux de tisanes
	B._c(R, "email_bleu175", Color(0.2, 0.45, 0.75), 0.35)
	_theiere(M, feu, "email_bleu175")
	L4._vapeur(M, feu + Vector3(0.15, 0.16, 0.0), 0.03, 0.4, Color(1, 1, 1, 0.35), 8)
	B._herbes(M, -1.5, 1.1, hd - 0.2)
	B._bocaux(R, R.L(-1.55, 1.715, hd - 0.1), 9, 0.17, 0.05, 0.15, 2)
	# la tenture du soleil et de la lune, sur la fenêtre au-dessus du lit
	var ten: String = _tx(R, "tenture175", T + "tenture_soleil.png", Color(1, 1, 1), 0.95)
	_plaque(R, R.L(-2.05, 1.33, -hd + 0.035), 0.9, 0.9, ten)
	# l'attrape-rêves, à la fenêtre du fond (il tourne doucement)
	_attrape_reves(M, Vector3(-hw + 0.12, 1.42, 0.55))
	# des tournesols dans un bocal, sur le tableau de bord ; un cristal à la fenêtre
	_tournesols(M, Vector3(hw - 0.25, 0.98, -0.95))
	_chat(M, Vector3(-hw + 1.1, 0.61, 0.35), 200.0, {"base": Color(0.9, 0.55, 0.2), "tigre": 0.85, "ventre": Color(0.97, 0.9, 0.8)})
	# Papy Rayon, sur la banquette
	var tisane := func() -> void:
		M.say("Papy Rayon verse une tisane dorée dans une tasse dépareillée : « Camomille, tilleul, une pincée de soleil. Bois doucement : elle est chaude comme un après-midi d'août. » Ça sent le miel et le foin coupé.", 8.0)
	var pose: String = "assis" if R.day else "dormir_assis"
	B._marchand(M, -0.45, -hd + 0.35, 0.0, pose, "vieux", "Papy Rayon",
		["Ce bus a fait trois fois le tour de l'île. Lentement. Très lentement. Bigoudi dit que c'est un record.",
			"Le soleil, je le mets en bocal. Tu ne me crois pas ? Goûte ma tisane.",
			"La tenture ? C'est Lune qui l'a tissée. Le soleil qui dort dans la lune. Ou la lune qui rêve du soleil.",
			"Le chat s'appelle Mandarine. Elle ne fait rien, toute la journée. C'est une sage."],
		{"bonjour": "Bienvenue dans le Bus du Soleil ! Enlève tes chaussures si tu veux, et assieds-toi : la théière chante.",
			"vend": {"tisane_lune": 6},
			"services": [{"label": "Boire une tisane du soleil", "cb": tisane}],
			"infos": ["J'ai acheté ce bus pour un pot de miel et une chanson, il y a quarante ans. Il ne roulait déjà plus. Il ne roule toujours pas. Mais il voyage, dans sa tête.",
				"Bigoudi, la mécanicienne, dit qu'il suffirait d'un moteur, de quatre pneus et d'un miracle. On attend le miracle. On a déjà la patience.",
				"Le matin, le soleil entre par le pare-brise et fait le tour du bus, fenêtre après fenêtre. Le soir, il sort par la vitre du fond. C'est ma montre.",
				"Les herbes qui sèchent : camomille, verveine, menthe, tilleul. Lavande me les apporte de son jardin. En échange, je lui chante de vieilles chansons. Elle dit qu'elle préfère les herbes."]})
	M.ctx["bonjour170"] = ["Entre, entre ! La théière chante.", "Oh, de la visite ! Mandarine, pousse-toi."]
	M.ctx["bonjour_nuit170"] = ["Zzz… Hein ? Oh, une visite ! Une tisane du soir ?", "Chut, Mandarine dort. Moi aussi, presque."]
	M.act(R.P(feu.x, 0.0, feu.z - 0.7), "E : prendre une tisane", tisane, 0.9)
	M.ctx["entree"] = ("Le Bus du Soleil : des herbes qui sèchent sous la voûte, la théière qui chante, la tenture du soleil et de la lune, un chat roux sur le lit… et partout, les guirlandes." if R.day
		else "Le Bus du Soleil, le soir : les guirlandes, la théière qui fume encore, Papy Rayon qui s'est endormi sur la banquette, et Mandarine en boule sur le lit.")


## Un attrape-rêves (le cercle, la toile, les plumes qui pendent) : p en repère de la pièce.
static func _attrape_reves(M, p: Vector3) -> void:
	var R = M.R
	B._c(R, "plume175", Color(0.95, 0.92, 0.85), 0.9)
	B._c(R, "osier175", Color(0.6, 0.45, 0.28), 0.8)
	var n := L4._noeud(M, "Attrape_reves175", Transform3D(Basis(Vector3.UP, PI * 0.5), R.P(p.x, p.y, p.z)))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.115
	ring.rings = 20
	ring.ring_segments = 6
	L4._bout(n, ring, R.mat("osier175"), Vector3.ZERO, Basis(Vector3.RIGHT, PI * 0.5))
	for i in range(4):
		var a: float = PI * i / 4.0
		L4._bout(n, B._boitem(0.2, 0.003, 0.003), R.mat("plume175"), Vector3.ZERO, Basis(Vector3.BACK, a))
	for j in range(3):
		var x: float = -0.06 + j * 0.06
		L4._bout(n, B._boitem(0.003, 0.12, 0.003), R.mat("osier175"), Vector3(x, -0.17, 0))
		L4._bout(n, B._boitem(0.025, 0.09, 0.006), R.mat("plume175"), Vector3(x, -0.27, 0))
	(M.ctx["anims170"] as Array).append([n, "tourne", Vector3.UP, 0.25])


## Des tournesols dans un bocal (sur le tableau de bord).
static func _tournesols(M, p: Vector3) -> void:
	var R = M.R
	var k = R.kit
	B._c(R, "tige175", Color(0.3, 0.5, 0.2), 0.8)
	B._c(R, "petale175", Color(1.0, 0.8, 0.15), 0.7)
	B._c(R, "coeur_tournesol175", Color(0.35, 0.22, 0.1), 0.9)
	k.cyl(R.L(p.x, p.y, p.z), 0.05, 0.05, 0.14, "vitre_bus175", 12)
	for i in range(3):
		var a: float = TAU * i / 3.0 + 0.4
		var top: Vector3 = p + Vector3(cos(a) * 0.06, 0.32 + i * 0.04, sin(a) * 0.06)
		_tube(R, p + Vector3(0, 0.02, 0), top, 0.006, "tige175", 5)
		var fxf: Transform3D = R.L(top.x, top.y, top.z) * Transform3D(Basis(Vector3.BACK, PI * 0.5 - 0.3), Vector3.ZERO)
		k.cyl(fxf, 0.07, 0.07, 0.01, "petale175", 12)
		k.cyl(fxf * T3(0, 0.008, 0), 0.035, 0.035, 0.012, "coeur_tournesol175", 10)


# =================================================================== le Bus-Atelier (Pastel)

static func _bus_atelier(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_bus_commun(M)
	_lit_bus(M)
	var feu: Vector3 = _cuisine_bus(M, -1.75, 1.3)
	_tapis_bus(M, 0.5)
	# le chevalet et sa toile (des fleurs, presque finies)
	var fl: String = _tx(R, "toile_fleurs175", T + "toile_fleurs.png", Color(1, 1, 1), 0.8)
	var so: String = _tx(R, "toile_soleil175", T + "toile_soleil.png", Color(1, 1, 1), 0.8)
	var va: String = _tx(R, "toile_vagues175", T + "toile_vagues.png", Color(1, 1, 1), 0.8)
	var ex: float = -1.25
	var ez: float = -0.62
	for e in [[-0.3, -0.2], [-0.3, 0.2], [0.25, 0.0]]:
		_tube(R, Vector3(ex + float(e[0]) * 0.4, 0.0, ez + float(e[1])), Vector3(ex, 1.55, ez), 0.014, "bois", 6)
	k.box(R.L(ex + 0.02, 0.92, ez), Vector3(0.06, 0.03, 0.62), "bois", 1.0)
	_plaque(R, R.L(ex + 0.05, 1.25, ez, 90.0) * Transform3D(Basis(Vector3.RIGHT, -0.08), Vector3.ZERO), 0.6, 0.6, fl)
	k.box(R.L(ex + 0.035, 1.25, ez), Vector3(0.025, 0.62, 0.62), "bois_clair", 1.0)
	# les toiles qui attendent, contre la paroi
	_plaque(R, R.L(0.15, 0.48, -hd + 0.09) * Transform3D(Basis(Vector3.RIGHT, -0.14), Vector3.ZERO), 0.55, 0.55, so)
	_plaque(R, R.L(0.75, 0.46, -hd + 0.06) * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3.ZERO), 0.5, 0.5, va)
	k.col_box(R.L(0.45, 0.4, -hd + 0.12), Vector3(1.2, 0.8, 0.2))
	# les pots de peinture (ouverts : leur couleur), les pinceaux dans leurs bocaux
	var cols: Array = [Color(0.95, 0.62, 0.15), Color(0.2, 0.55, 0.8), Color(0.3, 0.62, 0.72), Color(0.97, 0.88, 0.3), Color(0.62, 0.32, 0.68),
		Color(0.95, 0.5, 0.25), Color(0.9, 0.25, 0.2), Color(0.92, 0.9, 0.82), Color(0.35, 0.7, 0.3), Color(0.95, 0.5, 0.7)]
	for i in range(10):
		var px: float = -1.6 + i * 0.13
		if absf(px - (feu.x + 0.12)) < 0.32:
			continue
		var c: Color = cols[i]
		var key: String = B._c(R, "peinture175_%d" % i, c, 0.3)
		k.cyl(R.L(px, 0.9, hd - 0.42 + (i % 2) * 0.12), 0.05, 0.05, 0.09, "inox175", 12, false)
		k.disc(R.L(px, 0.985, hd - 0.42 + (i % 2) * 0.12), 0.048, key, 12)
		k.box(R.L(px, 0.94, hd - 0.42 + (i % 2) * 0.12 - 0.051), Vector3(0.03, 0.06, 0.004), key, 1.0)
	for j in range(2):
		var bx: float = 0.85 + j * 0.2
		k.cyl(R.L(bx, 0.9, hd - 0.2), 0.045, 0.045, 0.12, "vitre_bus175", 12)
		for b2 in range(5):
			var a: float = TAU * b2 / 5.0
			var tip: Vector3 = Vector3(bx + cos(a) * 0.035, 1.2, hd - 0.2 + sin(a) * 0.035)
			_tube(R, Vector3(bx, 0.92, hd - 0.2), tip, 0.005, "bois_clair", 4)
			_boule(M, "peinture175_%d" % ((b2 + j * 3) % 10), tip + Vector3(0, 0.015, 0), 0.01)
	# les taches de peinture sur le plancher (autour du chevalet)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17521
	for t in range(14):
		var tx: float = ex + rng.randf_range(0.0, 1.4)
		var tz: float = ez + rng.randf_range(-0.2, 0.75)
		k.disc(R.L(tx, 0.012 + t * 0.0004, tz), rng.randf_range(0.02, 0.06), "peinture175_%d" % (t % 10), 10)
	# des croquis épinglés au-dessus du lit, une palette sur le tableau de bord
	_plaque(R, R.L(-2.05, 1.32, -hd + 0.035), 0.42, 0.42, so)
	_plaque(R, R.L(-3.0, 1.32, -hd + 0.035), 0.42, 0.42, va)
	B._c(R, "palette175", Color(0.8, 0.65, 0.45), 0.7)
	k.cyl(R.L(hw - 0.3, 0.985, -0.95), 0.12, 0.12, 0.01, "palette175", 16)
	for p in range(5):
		_boule(M, "peinture175_%d" % (p * 2), Vector3(hw - 0.3 + cos(p * 1.2) * 0.07, 1.0, -0.95 + sin(p * 1.2) * 0.07), 0.018, Vector3(1.0, 0.4, 1.0))
	# Pastel, au chevalet ; Bigoudi (aux heures des bus), au volant
	var peindre := func() -> void:
		M.ctx["n_fleurs175"] = int(M.ctx.get("n_fleurs175", 0)) + 1
		M.say(str(B._pick(M, ["Pastel te tend un pinceau : « Une fleur. N'importe laquelle. » Tu peins une marguerite un peu penchée. Pastel recule, plisse les yeux : « Elle a l'air contente. C'est l'essentiel. »",
			"Tu ajoutes un coquelicot dans un coin de la toile. Pastel rit : « Un coquelicot qui fait coucou ! Il ira sur le bus de Papy Rayon. »",
			"Tu peins une fleur bleue, très bleue. Pastel la regarde longtemps : « Celle-là, je la garde pour le capot. »"])), 8.0)
	var couleur := func() -> void:
		var c2: String = str(B._pick(M, ["vert pomme", "rose bonbon", "bleu lavande", "jaune poussin", "orange coucher-de-soleil", "violet aubergine"]))
		M.say("Pastel note dans son carnet : « Le prochain bus sera… %s. Avec des fleurs blanches. Bigoudi va râler : elle dit que ça se voit de trop loin. C'est le but ! »" % c2, 8.0)
	B._marchand(M, -0.5, -0.42, -90.0, "peindre", "femme", "Pastel",
		["Les fleurs des bus, c'est moi. Chaque été, j'en ajoute une sur chaque bus. Le bus de Papy Rayon en a 1 412. Je compte.",
			"Une couleur, ça se mélange avec le cœur. Et un peu d'huile de lin.",
			"Bigoudi répare les moteurs, moi je répare les couleurs. Les moteurs ne marchent toujours pas, mais les couleurs, si.",
			"Attention où tu marches : le plancher, c'est aussi une œuvre d'art. Involontaire."],
		{"bonjour": "Entre ! Tu as de la chance, la peinture est sèche. Presque.",
			"services": [{"label": "Peindre une fleur sur la toile", "cb": peindre}, {"label": "Choisir la couleur du prochain bus", "cb": couleur}],
			"infos": ["C'est ici qu'on mélange les couleurs des bus. Le orange du Bus du Soleil, c'est trois carottes et un coucher de soleil. Enfin, c'est ce que je raconte.",
				"Les toiles, je les vends au Festival. Ou je les échange : une toile contre une chanson, une toile contre une tarte. Une fois, contre un parapluie de Mère Averse.",
				"Le bus de la plage, celui d'Écume, je l'ai peint en crème et rouge : comme une glace à la fraise. Elle a dit que ça lui donnait faim. Mission accomplie.",
				"Mon rêve ? Peindre la Grande Scène. Jack dit qu'il faudrait une échelle de dix mètres. Je lui ai dit : « Trouve l'échelle, je trouve les couleurs. »"]})
	M.ctx["bonjour170"] = ["Bienvenue à l'atelier ! Ne touche pas, c'est frais.", "Oh, un visiteur ! Tu as une couleur préférée ?"]
	M.ctx["bonjour_nuit170"] = ["La nuit, je peins les étoiles. Il en faut beaucoup.", "Chut… je mélange un bleu de minuit."]
	var hr: float = float(M.ctx.get("hour", 14.0))
	if (hr >= 9.0 and hr < 12.0) or (hr >= 14.0 and hr < 18.0):
		var bg: Node = B._habitue(M, "bigoudi", hw - 0.95, -0.55, 90.0, "assis", ["Ce moteur… il a fait vroum. Une fois. En 1987.", "Passe-moi la clé de 12. Non, l'autre. Non, l'autre autre."])
		if bg == null:
			var bg2: Node = M.person("femme", hw - 0.95, -0.55, 90.0, "assis", "Bigoudi")
			bg2.lines = ["Ce moteur… il a fait vroum. Une fois.", "Passe-moi la clé de 12."]
	M.act(R.P(ex + 0.75, 0.0, ez + 0.75), "E : peindre une fleur", peindre, 0.8)
	M.ctx["entree"] = "Le Bus-Atelier : ça sent la peinture et l'huile de lin, des pots ouverts de toutes les couleurs, une toile de fleurs sur le chevalet, des taches partout sur le plancher. C'est ici qu'on mélange les couleurs des bus."


# =================================================================== le Bus-Bibliothèque (Marque-Page)

static func _bus_livres(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_bus_commun(M)
	_cuisine_bus(M, 0.05, 1.3)
	_tapis_bus(M, 0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17531
	var cols: Array = [Color(0.6, 0.15, 0.12), Color(0.15, 0.3, 0.55), Color(0.2, 0.42, 0.25), Color(0.75, 0.55, 0.15), Color(0.45, 0.2, 0.45),
		Color(0.85, 0.82, 0.72), Color(0.1, 0.1, 0.12), Color(0.55, 0.35, 0.2)]
	for i in range(cols.size()):
		_tx(R, "livre175_%d" % i, "beau161/toile_lin.png", cols[i], 0.85)
	# les étagères basses sous les fenêtres (à gauche, tout du long) et leurs livres
	var x0: float = -hw + 0.15
	var x1: float = 1.75
	k.box(R.L((x0 + x1) * 0.5, 0.45, -hd + 0.17), Vector3(x1 - x0, 0.9, 0.34), "bois", 1.0, 1 + 2 + 4 + 32)
	k.col_box(R.L((x0 + x1) * 0.5, 0.45, -hd + 0.17), Vector3(x1 - x0, 0.9, 0.34))
	for yy in [0.04, 0.47]:
		k.box(R.L((x0 + x1) * 0.5, yy, -hd + 0.17), Vector3(x1 - x0, 0.03, 0.33), "bois_sombre", 1.0)
		var x: float = x0 + 0.03
		while x < x1 - 0.05:
			var w: float = rng.randf_range(0.025, 0.06)
			var h: float = rng.randf_range(0.26, 0.38)
			var c: int = rng.randi() % cols.size()
			var tilt: float = rng.randf_range(-0.12, 0.12) if rng.randf() < 0.15 else 0.0
			k.box(R.L(x + w * 0.5, yy + 0.015 + h * 0.5, -hd + 0.2) * Transform3D(Basis(Vector3.BACK, tilt), Vector3.ZERO), Vector3(w, h, 0.22), "livre175_%d" % c, 1.0)
			x += w + 0.004
			if rng.randf() < 0.05:
				x += 0.08
	# des piles de livres sur les étagères, par terre, sur le tableau de bord
	for p in [[-1.2, 0.9, -hd + 0.2, 7], [0.4, 0.9, -hd + 0.2, 5], [1.4, 0.9, -hd + 0.2, 4], [hw - 0.25, 0.98, -0.85, 6], [-1.95, 0.0, 0.75, 9]]:
		var hy: float = float(p[1])
		for j in range(int(p[3])):
			var th: float = rng.randf_range(0.03, 0.06)
			k.box(R.L(float(p[0]) + rng.randf_range(-0.02, 0.02), hy + th * 0.5, float(p[2])) * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)), Vector3.ZERO),
				Vector3(rng.randf_range(0.18, 0.26), th, rng.randf_range(0.13, 0.18)), "livre175_%d" % (rng.randi() % cols.size()), 1.0)
			hy += th
	k.col_box(R.L(-1.95, 0.25, 0.75), Vector3(0.3, 0.5, 0.25))
	# des livres sur l'étagère du haut (côté droit)
	var x2: float = 0.08
	while x2 < 1.25:
		var w2: float = rng.randf_range(0.025, 0.05)
		var h2: float = rng.randf_range(0.18, 0.24)
		k.box(R.L(x2 + w2 * 0.5, 1.715 + h2 * 0.5, hd - 0.1), Vector3(w2, h2, 0.15), "livre175_%d" % (rng.randi() % cols.size()), 1.0)
		x2 += w2 + 0.004
	# le fauteuil de lecture et sa lampe
	R.fauteuil(-1.25, 0.6, 180.0, "vert")
	_tube(R, Vector3(-1.85, 0.0, 0.95), Vector3(-1.85, 1.45, 0.95), 0.015, "chrome175", 6)
	B._c(R, "abat_jour175", Color(1.0, 0.85, 0.55), 0.8)
	_lum(R, "ampoule_lecture175", Color(1.0, 0.85, 0.55), 2.5)
	k.cyl(R.L(-1.85, 1.38, 0.95), 0.16, 0.09, 0.18, "abat_jour175", 14, false)
	k.cyl(R.L(-1.85, 1.4, 0.95), 0.03, 0.03, 0.05, "ampoule_lecture175", 8)
	L4._omni(M, Vector3(-1.75, 1.3, 0.8), Color(1.0, 0.78, 0.5), 0.6, 2.5)
	# le hamac, au fond (d'une paroi à l'autre) ; un coussin, un livre ouvert, le chat
	_hamac(M, -hw + 0.85)
	# la carte de la route, épinglée sur une fenêtre ; le panneau « prends un livre »
	var ca: String = _tx(R, "carte175", T + "carte_route.png", Color(1, 1, 1), 0.85)
	_plaque(R, R.L(-0.15, 1.31, -hd + 0.035), 0.78, 0.52, ca)
	var lb: Label3D = B._ecrit(M, hw - 0.01, 1.93, 0.0, -90.0, "PRENDS UN LIVRE · LAISSE UN LIVRE", 40, Color(0.98, 0.92, 0.7), 0.0032, 0.0)
	lb.outline_modulate = Color(0.25, 0.1, 0.3, 0.9)
	# Marque-Page, dans son fauteuil
	var lire := func() -> void:
		M.say("Tu ouvres un livre au hasard. « %s »" % str(B._pick(M, [
			"Il était une fois une île si petite qu'on ne pouvait y poser qu'un seul pied. Le héros resta donc sur un pied. Toute sa vie. Il devint très bon en équilibre.",
			"Le dragon s'assit et dit : « Je ne crache pas de feu. Je crache des bulles. » Personne ne le crut, jusqu'au jour du grand incendie de savon.",
			"La pluie de Rainville avait un secret : elle ne tombait pas. Elle descendait, lentement, pour regarder les gens.",
			"Chapitre 12 : où l'on apprend que le trésor était, depuis le début, dans la poche gauche du capitaine. Chapitre 13 : où le capitaine change de pantalon.",
			"Recette de la soupe de pierre : prenez une pierre. Ajoutez tout le reste. Retirez la pierre. Servez chaud."])), 9.0)
	var mot := func() -> void:
		M.say("Marque-Page te tend le livre d'or, un gros cahier plein de dessins et d'écritures de toutes les couleurs. Tu écris : « Merci pour les histoires. » Il souffle sur l'encre pour la sécher, très sérieusement.", 7.0)
	B._marchand(M, -1.25, 0.55, 180.0, "lire", "homme", "Marque-Page",
		["Prends un livre, laisse un livre. Ou laisse une histoire : ça compte aussi.",
			"Le hamac, c'est pour lire. Le fauteuil, c'est pour lire. Le lit ? Il n'y a pas de lit. Il y a des livres.",
			"J'ai lu tous les livres de ce bus. Deux fois. Sauf un : je le garde pour la fin.",
			"Le chat s'appelle Virgule. Il s'arrête partout."],
		{"bonjour": "Chut… Bienvenue au Bus-Bibliothèque. Ici, on parle tout bas et on lit tout haut.",
			"services": [{"label": "Lire une page au hasard", "cb": lire}, {"label": "Écrire un mot dans le livre d'or", "cb": mot}],
			"infos": ["Le bus est arrivé avec trois cents livres. Il en a mille deux cents maintenant. Les gens en laissent toujours plus qu'ils n'en prennent. C'est mathématique et magique.",
				"La carte, sur la fenêtre ? C'est le voyage que fera le bus, un jour : Larsen, Néopolis, Montjoie, Al Dente. Bigoudi dit « un jour ». Je dis « un jour » aussi. On a le même calendrier.",
				"Le livre que je garde pour la fin s'appelle « Le dernier chapitre ». Je l'ouvrirai quand j'aurai tout lu. Donc jamais : on m'apporte toujours de nouveaux livres. C'est le plan.",
				"Clapotis, le petit skateur, vient lire des bandes dessinées le mercredi. Il fait semblant de ne pas lire. Je fais semblant de ne pas le voir lire. Tout le monde est content."]})
	M.ctx["bonjour170"] = ["Chut… Bienvenue. Prends un livre.", "Ah, un lecteur ! Ou une lectrice. Ou un écouteur d'histoires."]
	M.ctx["bonjour_nuit170"] = ["Une histoire pour la nuit ? J'en ai mille deux cents.", "Chut… Virgule dort. Les livres aussi."]
	M.act(R.P(0.4, 0.0, -0.45), "E : lire une page au hasard", lire, 0.9)
	M.ctx["entree"] = "Le Bus-Bibliothèque : des livres partout, sous les fenêtres, sur le tableau de bord, en piles par terre ; un hamac au fond, une lampe de lecture, et un chat qui dort entre deux chapitres."


## Le hamac (à travers le bus, au fond) : la toile qui pend (de part et d'autre de la largeur), les
## cordes, un coussin, un livre ouvert, Virgule le chat.
static func _hamac(M, x: float) -> void:
	var R = M.R
	var k = R.kit
	var hd: float = R.D * 0.5
	var n: int = 10
	var prev: Array = []
	var zs: float = hd - 0.3
	for i in range(n + 1):
		var z: float = -zs + 2.0 * zs * float(i) / n
		var t: float = z / zs
		var y: float = 1.3 - 0.58 * (1.0 - t * t)
		var a: Vector3 = R.P(x - 0.42, y, z)
		var b: Vector3 = R.P(x + 0.42, y, z)
		if not prev.is_empty():
			var nrm := Vector3(0, 1, 0)
			k.quad4("patchwork175", prev[0], prev[1], b, a, nrm, Vector2(0, 0), Vector2(0.9, 0), Vector2(0.9, 0.2), Vector2(0, 0.2))
			k.quad4("patchwork175", prev[0], prev[1], b, a, -nrm, Vector2(0, 0), Vector2(0.9, 0), Vector2(0.9, 0.2), Vector2(0, 0.2))
		prev = [a, b]
	for s in [-1.0, 1.0]:
		var bout: Vector3 = Vector3(x, 1.3, s * zs)
		var crochet: Vector3 = Vector3(x, 1.6, s * (hd - 0.02))
		for dx in [-0.42, 0.0, 0.42]:
			_tube(R, Vector3(x + dx, 1.3, s * zs), crochet, 0.006, "fil175", 4)
		_boule(M, "chrome175", crochet, 0.025)
	_boule(M, "tissu_rose", Vector3(x, 0.8, -0.35), 0.16, Vector3(1.2, 0.5, 0.9))
	k.box(R.L(x + 0.05, 0.75, 0.2) * Transform3D(Basis(Vector3.UP, 0.4), Vector3.ZERO), Vector3(0.22, 0.03, 0.16), "livre175_1", 1.0)
	_chat(M, Vector3(x - 0.05, 0.74, 0.0), 80.0, {"base": Color(0.18, 0.18, 0.2), "ventre": Color(0.95, 0.95, 0.93), "chaussettes": true})
	k.col_box(R.L(x, 0.5, 0), Vector3(0.9, 1.0, R.D - 0.2))


# =================================================================== le Bus de la Plage (Écume)

static func _bus_plage(M) -> void:
	var R = M.R
	var k = R.kit
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	_bus_commun(M)
	_lit_bus(M)
	_banquette_bus(M, -1.75, 0.95, "tissu_turquoise")
	_cuisine_bus(M, -1.75, 1.3)
	_tapis_bus(M, 0.35)
	# la serviette de plage rayée, sur la banquette
	for i in range(7):
		var key: String = "tissu_blanc" if i % 2 == 0 else "tissu_rouge"
		k.box(R.L(-0.65 + i * 0.12, 0.505, -hd + 0.32), Vector3(0.12, 0.012, 0.5), key, 1.0)
	# les planches de surf, sous la voûte, et leurs sangles
	B._c(R, "planche_a175", Color(0.92, 0.3, 0.25), 0.25)
	B._c(R, "planche_b175", Color(0.2, 0.75, 0.75), 0.25)
	for e in [[-0.33, "planche_a175"], [0.33, "planche_b175"]]:
		var z: float = float(e[0])
		_boule(M, str(e[1]), Vector3(0.1, 1.9, z), 1.0, Vector3(1.05, 0.03, 0.26))
		_boule(M, "tissu_blanc", Vector3(0.1, 1.885, z), 1.0, Vector3(1.0, 0.012, 0.03))
		for sx in [-0.6, 0.8]:
			_tube(R, Vector3(0.1 + sx, 1.87, z - 0.2), Vector3(0.1 + sx, 2.05, z - 0.2), 0.008, "joint175", 4)
			_tube(R, Vector3(0.1 + sx, 1.87, z + 0.2), Vector3(0.1 + sx, 2.05, z + 0.2), 0.008, "joint175", 4)
			_barre(R, Vector3(0.1 + sx, 1.87, z - 0.2), Vector3(0.1 + sx, 1.87, z + 0.2), Vector2(0.03, 0.006), "joint175")
	# la combinaison qui sèche (au dos du siège), les tongs près de la porte
	B._c(R, "neoprene175", Color(0.05, 0.05, 0.06), 0.6)
	var cx: float = hw - 1.27
	k.box(R.L(cx, 1.12, -0.55), Vector3(0.05, 0.6, 0.38), "neoprene175", 1.0)
	for s in [-1.0, 1.0]:
		k.box(R.L(cx, 0.98, -0.55 + s * 0.24) * Transform3D(Basis(Vector3.RIGHT, s * 0.25), Vector3.ZERO), Vector3(0.04, 0.5, 0.09), "neoprene175", 1.0)
		k.box(R.L(cx, 0.62, -0.55 + s * 0.09), Vector3(0.04, 0.45, 0.11), "neoprene175", 1.0)
	for t in [[2.3, 0.75, "tissu_jaune"], [2.55, 0.85, "tissu_rose"]]:
		for f in [-0.06, 0.06]:
			k.box(R.L(float(t[0]), 0.012, float(t[1]) + f) * Transform3D(Basis(Vector3.UP, 0.3), Vector3.ZERO), Vector3(0.26, 0.018, 0.09), str(t[2]), 1.0)
	# le ukulélé sur le lit
	B._c(R, "ukulele175", Color(0.75, 0.48, 0.25), 0.4)
	_boule(M, "ukulele175", Vector3(-2.5, 0.64, 0.45), 0.13, Vector3(1.0, 0.3, 0.85))
	_boule(M, "ukulele175", Vector3(-2.33, 0.64, 0.45), 0.1, Vector3(1.0, 0.3, 0.85))
	k.box(R.L(-2.08, 0.645, 0.45), Vector3(0.3, 0.025, 0.05), "bois_sombre", 1.0)
	k.box(R.L(-1.9, 0.645, 0.45), Vector3(0.07, 0.03, 0.07), "bois_sombre", 1.0)
	# les coquillages (les tablettes des fenêtres, le tableau de bord) ; la conque
	var rng := RandomNumberGenerator.new()
	rng.seed = 17541
	B._c(R, "nacre175", Color(0.98, 0.9, 0.88), 0.25)
	B._c(R, "coquille175", Color(0.95, 0.65, 0.6), 0.5)
	for x in BUS_FX:
		for z2 in [-hd + 0.06, hd - 0.06]:
			if z2 > 0.0 and float(x) > 1.6:
				continue
			for j in range(2):
				if rng.randf() < 0.4:
					continue
				_boule(M, "coquille175" if j == 0 else "nacre175", Vector3(float(x) + rng.randf_range(-0.25, 0.25), BUS_FY + 0.015, z2), rng.randf_range(0.025, 0.04), Vector3(1.0, 0.55, 0.8))
	var conque: Vector3 = Vector3(hw - 0.28, 1.0, -0.25)
	_boule(M, "coquille175", conque + Vector3(0, 0.05, 0), 0.08, Vector3(1.6, 0.85, 1.0))
	k.cyl(R.L(conque.x - 0.12, conque.y + 0.05, conque.z) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), 0.06, 0.005, 0.14, "nacre175", 10)
	# le mobile de verre de mer, à la fenêtre du fond
	_mobile_verre(M, Vector3(-hw + 0.14, 1.6, -0.55))
	# Écume, sur la banquette, avec sa guitare
	var ecouter := func() -> void:
		M.say("Tu poses la conque contre ton oreille. Chhhh… la mer. Puis, très loin, une mouette. Puis… quelqu'un qui chante faux sous la douche ? Écume éclate de rire : « Ça, c'est Grésil. Il chante même sous l'eau. »", 8.0)
	B._marchand(M, -0.45, -hd + 0.35, 0.0, "guitare", "femme", "Écume",
		["La mer, c'est mon réveil. Elle frappe à la carrosserie tous les matins.",
			"Les planches, au plafond ? Elles dorment. Comme moi, quand il n'y a pas de vagues.",
			"Un coquillage par jour. Pas plus. Il faut en laisser pour les bernard-l'ermite.",
			"Mon bus est garé au bord de la plage depuis six ans. Bigoudi dit qu'il s'est enraciné."],
		{"bonjour": "Hé ! Bienvenue dans le Bus de la Plage. Attention au sable : il en reste partout, c'est la déco.",
			"vend": {"jus_soleil": 5},
			"achete": {"coquillage": 4},
			"services": [{"label": "Écouter la conque", "cb": ecouter}],
			"infos": ["Ce bus, je l'ai trouvé à moitié dans le sable, avec un crabe au volant. Le crabe est parti. Le bus est resté. Moi aussi.",
				"Le mobile, à la fenêtre du fond, c'est du verre de mer : des morceaux de bouteilles que la mer a polis pendant des années. Le vert, c'est le plus courant. Le bleu, c'est un trésor.",
				"Le soir, on fait un feu sur la plage, avec ceux du camp. Arc-en-Ciel joue du djembé, je joue du ukulélé, et la mer fait la basse.",
				"Si tu trouves des coquillages, je te les achète. Je les colle sur la carrosserie. Pastel dit que ça abîme sa peinture. Moi je dis que ça la complète."]})
	M.ctx["bonjour170"] = ["Salut, toi ! Tu sens la mer ? Moi aussi.", "Bienvenue à bord ! Enfin, à sable."]
	M.ctx["bonjour_nuit170"] = ["La nuit, j'écoute la marée. Tu entends ? Elle monte.", "Chut… la lune est sur la mer. On ne la dérange pas."]
	M.act(R.P(conque.x - 0.45, 0.0, conque.z + 0.25), "E : écouter le coquillage", ecouter, 0.8)
	M.ctx["entree"] = ("Le Bus de la Plage : des planches de surf sous la voûte, des coquillages sur chaque fenêtre, une combinaison qui sèche, et dehors, par toutes les vitres, la mer." if R.day
		else "Le Bus de la Plage, la nuit : les guirlandes, le ukulélé sur le lit, et par les fenêtres, la lune qui trace son chemin sur la mer.")


## Un mobile de verre de mer (un bout de bois flotté, des fils, des éclats de verre de couleur) : il se
## balance (anims170).
static func _mobile_verre(M, p: Vector3) -> void:
	var R = M.R
	var n := L4._noeud(M, "Mobile175", Transform3D(Basis(), R.P(p.x, p.y, p.z)))
	B._c(R, "flotte175", Color(0.75, 0.68, 0.58), 0.95)
	L4._bout(n, B._cylm(0.012, 0.012, 0.5, 6), R.mat("flotte175"), Vector3.ZERO, Basis(Vector3.RIGHT, PI * 0.5))
	var cols: Array = [Color(0.4, 0.8, 0.6), Color(0.3, 0.55, 0.95), Color(0.85, 0.95, 0.9), Color(0.5, 0.75, 0.45), Color(0.6, 0.85, 0.95), Color(0.95, 0.85, 0.6)]
	for i in range(6):
		var z: float = -0.22 + i * 0.088
		var l: float = 0.12 + 0.06 * float(i % 3)
		L4._bout(n, B._cylm(0.002, 0.002, l, 3), R.mat("fil175"), Vector3(0, -l * 0.5, z))
		var key: String = B._verre(R, "verre_mer175_%d" % i, cols[i], 0.65, 0.3)
		L4._bout(n, B._boitem(0.035, 0.045, 0.012), R.mat(key), Vector3(0, -l - 0.02, z), Basis(Vector3.UP, i * 0.7))
	(M.ctx["anims170"] as Array).append([n, "balance", 0.06, 1.3])

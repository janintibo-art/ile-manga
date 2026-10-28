extends RefCounted
## V75 : les grands lieux de Port-Boucan (le reste : boucan_ville_v75.gd). Chacun bâti par le kit
## de la ville (boucan_kit_v75), avec ses lieux pour les habitants (spots), ses points et ses liens
## dans le réseau des rues, ses objets (les comptoirs, les invites, les lieux des quêtes) :
##  - la HALLE HURLANTE (la salle de concert : la scène, la fosse, le bar à limonades, la régie,
##    la mezzanine) ;
##  - la CONSERVERIE (le grand squat : la Cantine à prix libre, la Gratuiterie, le salon commun ; sur
##    le toit, le jardin et la salle des assemblées, par l'escalier de secours) ;
##  - la FILATURE (les ateliers : vélo, imprimerie, couture, menuiserie) et la Grande Cheminée ;
##  - la PLACE DES PALETTES ; le PORT (les grues, les conteneurs, le ponton, les quais) ;
##  - le CARGO « La Baleine Rouillée » (le studio de Radio Boucan) ; le SKATEPARK de la cale sèche ;
##  - le MUR D'EXPRESSION ; le CHÂTEAU D'EAU ; les BOÎTES (les conteneurs-maisons) ; les JARDINS
##    PARTAGÉS ; le BUREAU DE VENTE de Lisse & Fils ; les rails et le vieux wagon.

const R = preload("res://scripts/ile_boucan_v75.gd")
const Y: float = R.TOWN_Y

var c                                    # boucan_ville_v75
var kit
## La Halle Hurlante
var halle_xf := Transform3D.IDENTITY
var halle_inside := Vector3.ZERO
var halle_fosse := Vector3.ZERO          # le milieu de la fosse (on y danse le pogo)
var halle_scene := Vector3.ZERO          # le devant de la scène (on y monte jouer)
var halle_musiciens: Dictionary = {}     # chant, guitare, basse, batterie -> Vector3
var stage_lights: Array = []             # les projecteurs (le gestionnaire les anime pendant les concerts)
var halle_lights: Array = []             # les lampes de la salle
## La Conserverie
var cantine_comptoir := Vector3.ZERO     # devant le comptoir de Lentille (le client : prix libre)
var gratuiterie := Vector3.ZERO          # devant la table de la Gratuiterie
var conserverie_inside := Vector3.ZERO
var toit := Vector3.ZERO                 # le toit-jardin
## Le cargo, le château d'eau, le bureau de vente
var studio := Vector3.ZERO               # dans la timonerie (Radio Boucan)
var antenne := Vector3.ZERO              # le haut du château d'eau (l'antenne tombée)
var bureau_vente := Vector3.ZERO         # devant le comptoir de Monsieur Lisse
var cargo_info: Dictionary = {}
var mur_points: Array = []               # [Transform3D, w, h] : les panneaux du Mur d'Expression (graffitis)
var _zones: Array = []                   # [nom, Transform3D inverse, demi-taille]
var _links: Array = []                   # [point, Vector3] : à relier à la rue la plus proche


func setup(city) -> void:
	c = city
	kit = city.kit


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func _zone(name: String, xf: Transform3D, center: Vector3, half: Vector3) -> void:
	_zones.append([name, (xf * Transform3D(Basis(), center)).affine_inverse(), half])


func zone_at(p: Vector3) -> String:
	for i in range(_zones.size() - 1, -1, -1):
		var z: Array = _zones[i]
		var l: Vector3 = (z[1] as Transform3D) * p
		var h: Vector3 = z[2]
		if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
			return str(z[0])
	return ""


func _street_link(pt: String) -> void:
	_links.append(pt)


func link_graph() -> void:
	for l in _links:
		var near: String = c.nearest_street(c.points[str(l)])
		if near != "":
			c._link(str(l), near)


## Un point en repère local d'un bâtiment, au ras du sol (+5 cm).
func P(xf: Transform3D, x: float, z: float, y: float = 0.05) -> Vector3:
	return xf * Vector3(x, y, z)


# =================================================================== la Halle Hurlante

func halle() -> void:
	var xf: Transform3D = c.XF(52.0, -99.0, 0.0, 1.0)
	halle_xf = xf
	var w: float = 40.0
	var d: float = 26.0
	kit.usine75(xf, w, d, {"h": 10.0, "hollow": true, "roof": "arc", "roof_key": "tolep75_noir", "wall": "brique75", "inner": "brique75_suie",
		"floor_key": "betonsol75", "door_w": 4.4, "door_h": 4.2, "side_doors": [null, -21.0], "rows": 1, "lit": 0.5, "lights": 0,
		"sign": "halle", "sign_w": 12.0, "sign_h": 2.6, "sign_y": 7.0, "bay": 5.0,
		"fresques": [{"side": "l", "id": 2, "w": 18.0, "h": 7.0, "x": 0.0, "y": 1.2}, {"side": "r", "id": 8, "w": 14.0, "h": 6.0, "x": -2.0, "y": 1.4}]})
	halle_inside = P(xf, 0, -d * 0.5)
	_zone("bo_halle", xf, Vector3(0, 6.0, -d * 0.5), Vector3(w * 0.5 - 0.4, 6.2, d * 0.5 - 0.3))
	# la marquise au-dessus de la porte, des affiches
	kit.box(xf * T(0, 4.6, 1.2), Vector3(8.0, 0.2, 2.4), "tolep75_noir", 1.0)
	for k in range(4):
		kit.quadz(xf * T(-9.0 - k * 1.4 + (0.0 if k < 2 else -2.0), 1.8, 0.28), 1.0, 1.4, "affiche75_" + str(k + 1))
		kit.quadz(xf * T(6.5 + k * 1.4, 1.8, 0.28), 1.0, 1.4, "affiche75_" + str(4 - k))
	# la scène, au fond (vers -Z), ses projecteurs
	var sx: Transform3D = xf * T(0, 0, -17.0)
	var m: Dictionary = kit.scene75(sx, 16.0, 8.4, 1.2)
	halle_musiciens = m
	halle_scene = P(xf, 0, -15.5)
	var colors := [Color(1.0, 0.2, 0.4), Color(0.2, 0.5, 1.0), Color(1.0, 0.7, 0.2), Color(0.5, 1.0, 0.4)]
	for k2 in range(4):
		var at: Vector3 = xf * Vector3(-6.0 + k2 * 4.0, 7.2, -16.6)
		var aim: Vector3 = xf * Vector3(-4.5 + k2 * 3.0, 1.2, -21.0)
		var l: Light3D = kit.projecteur75(at, aim, colors[k2], 7.0, true)
		if l != null:
			stage_lights.append(l)
	for k3 in range(2):
		var at2: Vector3 = xf * Vector3(-8.0 + k3 * 16.0, 7.0, -6.0)
		var l2: Light3D = kit.projecteur75(at2, xf * Vector3(0.0, 2.2, -19.5), Color(1.0, 0.95, 0.85), 9.0, true)
		if l2 != null:
			stage_lights.append(l2)
	# les lampes de la salle (chaudes, douces)
	for k4 in range(2):
		var lp: Vector3 = xf * Vector3(0, 8.6, -4.0 - k4 * 7.0)
		halle_lights.append(kit._hall_light(lp, Color(1.0, 0.72, 0.45), 1.4, 16.0))
	# le bar à limonades (le long du mur ouest, il regarde l'est)
	var bx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-w * 0.5 + 3.4, 0, -8.0))
	var keeper: Vector3 = kit.counter71(bx, 7.0, "chrome75")
	for k5 in range(3):
		kit.box(bx * T(0, 1.4 + k5 * 0.55, -2.55), Vector3(6.6, 0.05, 0.3), "palette75", 1.0)
		for k6 in range(9):
			kit.cyl(bx * T(-3.0 + k6 * 0.75, 1.43 + k5 * 0.55, -2.55), 0.05, 0.05, 0.24, "neon75_" + ["vert", "jaune", "rose"][(k5 + k6) % 3] if (k5 + k6) % 4 == 0 else "vitre75_off", 8)
	kit.box(bx * T(0, 3.2, -2.75), Vector3(4.0, 0.12, 0.08), "neon75_rose", 1.0)
	halle_lights.append(kit._hall_light(bx * Vector3(0, 3.0, -1.6), Color(1.0, 0.4, 0.7), 0.8, 7.0))
	c._pt("ha_bar", bx * Vector3(0, 0.05, 1.6))
	c._pt("ha_bar_derriere", bx * Vector3(3.6, 0.05, -1.4))
	c._spot("halle_bar", keeper + Vector3.UP * 0.05, bx.basis * Vector3(0, 0, 1), "comptoir", "ha_bar_derriere")
	c._spot("halle_comptoir", bx * Vector3(-1.2, 0.05, 0.75), bx.basis * Vector3(0, 0, -1), "boire", "ha_bar")
	c.objets["halle_bar"] = bx * Vector3(0, 0.05, 1.1)
	# des tabourets de palettes près du bar
	for k7 in range(4):
		kit.place("chaise75|" + ["rouge", "bleu", "jaune", "vert"][k7], bx * T(-2.4 + k7 * 1.6, 0, 1.6))
	# la régie (au fond de la fosse, face à la scène)
	var rx: Transform3D = xf * T(7.5, 0, -3.5)
	kit.box(rx * T(0, 0.45, 0), Vector3(2.6, 0.9, 1.2), "caoutchouc75", 1.0)
	kit.box(rx * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 0.98, 0)), Vector3(2.4, 0.08, 1.0), "metal75_gris", 1.0)
	kit.col_box(rx * T(0, 0.5, 0), Vector3(2.6, 1.0, 1.2))
	c._pt("ha_regie", rx * Vector3(0, 0.05, 1.6))
	c._spot("halle_regie", rx * Vector3(0, 0.05, 1.0), xf.basis * Vector3(0, 0, -1), "bricoler", "ha_regie")
	# la mezzanine (le long du mur est), son escalier, sa rambarde
	var my: float = 3.4
	var mx: Transform3D = xf * T(w * 0.5 - 3.2, 0, -10.0)
	kit.box(mx * T(0, my, 0), Vector3(5.6, 0.25, 16.0), "acier75", 2.0)
	kit.col_box(mx * T(0, my, 0), Vector3(5.6, 0.25, 16.0))
	kit.walk_boxes.append([(mx * T(0, my + 0.12, 0)).affine_inverse(), Vector3(2.8, 3.0, 8.0)])
	for k8 in range(4):
		kit.box(mx * T(-2.6, my * 0.5, -7.0 + k8 * 4.6), Vector3(0.24, my, 0.24), "metal75_noir", 1.0)
	kit.railing70(mx * Vector3(-2.75, my + 0.12, -8.0), mx * Vector3(-2.75, my + 0.12, 4.0))
	kit.stair(mx * Vector3(-0.8, 0.0, 8.0 + 6.4), mx * Vector3(-0.8, my, 8.0), 1.4, "acier75", "metal75_noir", 0.9, 0.06)
	c._pt("ha_mezz_bas", mx * Vector3(-0.8, 0.05, 15.6))
	c._pt("ha_mezz", mx * Vector3(0.2, my + 0.17, 6.0))
	c._pt("ha_mezz_bout", mx * Vector3(0.2, my + 0.17, -4.0))
	c._spot("halle_mezzanine", mx * Vector3(-1.6, my + 0.17, -2.0), xf.basis * Vector3(-0.5, 0, -1).normalized(), "acclamer", "ha_mezz_bout")
	# la fosse : douze places de pogo (face à la scène)
	halle_fosse = P(xf, 0, -10.0)
	c.objets["halle_fosse"] = halle_fosse
	c.objets["halle_scene"] = halle_scene
	var k9: int = 0
	for zz in [-13.6, -10.6, -7.6]:
		for xx in [-7.5, -2.5, 2.5, 7.5]:
			k9 += 1
			var fp: String = c._pt("ha_fosse_%d" % k9, P(xf, xx, zz + 1.0))
			c._spot("halle_fosse_%d" % k9, P(xf, xx + (0.6 if k9 % 2 == 0 else -0.5), zz), xf.basis * Vector3(0, 0, -1), "pogo", fp)
	# les musiciens, sur la scène
	c._pt("ha_scene_cote", sx * Vector3(8.0 + 1.8, 0.05, -5.9))
	c._pt("ha_scene", sx * Vector3(5.0, 1.25, -5.9))
	for role in ["chant", "guitare", "basse", "batterie"]:
		var mp: Vector3 = m[role]
		c._spot("halle_scene_" + role, mp + Vector3.UP * 0.05, xf.basis * Vector3(0, 0, 1), {"chant": "chanter", "guitare": "guitare", "basse": "basse", "batterie": "batterie"}[role], "ha_scene")
	# le réseau
	c._pt("ha_dehors", P(xf, 0, 3.0))
	c._pt("ha_entree", P(xf, 0, -1.6))
	c._pt("ha_salle", P(xf, 0, -5.0))
	c._pt("ha_coulisse", P(xf, w * 0.5 - 1.4, -21.0))
	c._spot("halle_entree", P(xf, 1.6, -1.8), xf.basis * Vector3(0, 0, -1), "bras_croises", "ha_entree")
	c._chain(["ha_dehors", "ha_entree", "ha_salle", "ha_bar"])
	c._chain(["ha_bar", "ha_bar_derriere"])
	c._chain(["ha_salle", "ha_regie"])
	c._chain(["ha_salle", "ha_mezz_bas", "ha_mezz", "ha_mezz_bout"])
	for k10 in range(12):
		c._link("ha_fosse_%d" % (k10 + 1), "ha_salle" if k10 >= 8 else ("ha_fosse_%d" % (k10 + 5)))
	c._chain(["ha_salle", "ha_fosse_10"])
	c._chain(["ha_fosse_4", "ha_scene_cote", "ha_scene"])
	c._chain(["ha_scene_cote", "ha_coulisse"])
	_street_link("ha_dehors")
	c._avoid(P(xf, 0, -d * 0.5), 26.0)


# =================================================================== la Conserverie

func conserverie() -> void:
	var xf: Transform3D = c.XF(-62.0, -104.0, 0.0, 1.0)
	var w: float = 34.0
	var d: float = 16.0
	var h: float = 11.4
	kit.usine75(xf, w, d, {"h": h, "hollow": true, "roof": "plat", "roof_walk": true, "ceiling": false, "wall": "brique75", "inner": "briquep75_creme",
		"floor_key": "carrelage75", "door_w": 3.0, "door_h": 3.2, "door_x": -6.0, "rows": 3, "lit": 0.55, "lights": 0,
		"sign": "conserverie", "sign_w": 14.0, "sign_h": 2.0, "sign_y": 9.8, "bay": 4.2,
		"fresques": [{"side": "f", "id": 1, "w": 12.0, "h": 5.4, "x": 9.0, "y": 3.6}, {"side": "l", "id": 5, "w": 12.0, "h": 6.0, "x": 0.0, "y": 4.6}]})
	conserverie_inside = P(xf, 0, -d * 0.5)
	# le plafond du rez-de-chaussée (les étages au-dessus ne se visitent pas)
	kit.box(xf * T(0, 4.3, -d * 0.5), Vector3(w - 0.5, 0.3, d - 0.5), "briquep75_creme", 3.0, 8 | 4)
	_zone("bo_conserverie", xf, Vector3(0, 2.2, -d * 0.5), Vector3(w * 0.5 - 0.3, 2.2, d * 0.5 - 0.3))
	for k in range(3):
		kit._hall_light(xf * Vector3(-10.0 + k * 10.0, 3.6, -8.0), Color(1.0, 0.78, 0.55), 1.3, 12.0)
		kit.cyl(Transform3D(Basis(), xf * Vector3(-10.0 + k * 10.0, 3.6, -8.0)), 0.35, 0.06, 0.25, "tolep75_" + ["rouge", "jaune", "bleu"][k], 10, false)
	# les enseignes des portes : la Cantine (à gauche), la Gratuiterie (à droite)
	kit.quadz(xf * T(-6.0, 4.0, 0.3), 4.6, 1.0, "enseigne75_cantine")
	kit.quadz(xf * T(8.0, 4.0, 0.3), 4.2, 1.0, "enseigne75_gratuiterie")
	kit.box(xf * T(8.0, 1.6, 0.06), Vector3(2.4, 3.0, 0.1), "vitre75_on", 1.0)
	# la cuisine de Lentille (au fond, à gauche), le comptoir où l'on paie ce qu'on veut
	var kx: Transform3D = xf * T(-11.0, 0, -14.6)
	kit.box(kx * T(0, 0.45, 0), Vector3(6.0, 0.9, 1.0), "chrome75", 1.0)
	kit.col_box(kx * T(0, 0.45, 0), Vector3(6.0, 0.9, 1.0))
	for k2 in range(3):
		kit.cyl(kx * T(-2.0 + k2 * 2.0, 0.9, 0), 0.38, 0.36, 0.6, "chrome75", 14)
	kit.fires70.append([kx * Vector3(0.0, 0.92, 0.0), 0.22])
	c._pt("co_cuisine", kx * Vector3(0, 0.05, 1.5))
	c._spot("cantine_cuisine", kx * Vector3(0, 0.05, 0.95), xf.basis * Vector3(0, 0, -1), "cuisiner", "co_cuisine")
	var cx: Transform3D = xf * T(-6.0, 0, -9.0)
	var lent: Vector3 = kit.counter71(cx, 5.0, "chrome75")
	cantine_comptoir = cx * Vector3(0, 0.05, 1.1)
	c.objets["cantine_comptoir"] = cantine_comptoir
	kit.cyl(cx * T(-1.6, 1.17, -0.3), 0.32, 0.3, 0.5, "chrome75", 14)
	kit.box(cx * T(1.5, 1.3, -0.3), Vector3(0.6, 0.3, 0.4), "peint75_jaune", 1.0)
	c._pt("co_comptoir", cx * Vector3(0, 0.05, 2.0))
	c._pt("co_comptoir_derriere", cx * Vector3(3.2, 0.05, -1.2))
	c._spot("cantine_comptoir", lent + Vector3.UP * 0.05, xf.basis * Vector3(0, 0, 1), "comptoir", "co_comptoir_derriere")
	# les tables de la cantine (bancs de palettes)
	var tables := [Vector3(-13.0, 0, -3.6), Vector3(-6.6, 0, -3.6), Vector3(-0.4, 0, -3.6), Vector3(-13.0, 0, -7.4), Vector3(-0.4, 0, -7.6), Vector3(-13.0, 0, -11.0)]
	for i in range(tables.size()):
		var txf: Transform3D = xf * Transform3D(Basis(), tables[i])
		var seats: Array = kit.tavern_table71(txf, 2.2)
		var tp: String = c._pt("co_table_%d" % (i + 1), txf * Vector3(1.6, 0.05, 1.5))
		c._spot("cantine_table_%d" % (i + 1), (seats[0] as Vector3) + Vector3.UP * 0.45, xf.basis * Vector3(0, 0, -1), "boire" if i % 3 == 1 else "assis", tp)
	# la Gratuiterie (à droite) : des étagères pleines, la grande boîte à dons, la table de Trocante
	var gx: Transform3D = xf * T(9.0, 0, -6.0)
	kit.box(gx * T(0, 0.4, 0), Vector3(3.0, 0.8, 1.2), "palette75", 1.0)
	kit.col_box(gx * T(0, 0.4, 0), Vector3(3.0, 0.8, 1.2))
	for k3 in range(6):
		var ob: Vector3 = gx * Vector3(-1.2 + k3 * 0.5, 0.86, (0.2 if k3 % 2 == 0 else -0.2))
		kit.box(Transform3D(Basis(Vector3.UP, k3 * 0.7), ob), Vector3(0.3, 0.14 + (k3 % 3) * 0.08, 0.24), "peint75_" + ["rouge", "bleu", "jaune", "vert", "violet", "orange"][k3], 1.0)
	for k4 in range(3):
		var sh: Transform3D = xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(w * 0.5 - 0.7, 0, -3.0 - k4 * 3.6))
		for lv in range(4):
			kit.box(sh * T(0, 0.4 + lv * 0.5, 0), Vector3(3.2, 0.05, 0.6), "palette75", 1.0)
			for k5 in range(5):
				kit.box(sh * T(-1.3 + k5 * 0.62, 0.55 + lv * 0.5, 0), Vector3(0.4, 0.24, 0.4), "peint75_" + ["rouge", "bleu", "jaune", "vert", "blanc"][(k5 + lv + k4) % 5], 1.0)
		kit.col_box(sh * T(0, 1.0, 0), Vector3(3.2, 2.0, 0.6))
	var bt: Vector3 = gx * Vector3(-3.0, 0, 1.5)
	kit.box(Transform3D(xf.basis, bt + Vector3.UP * 0.45), Vector3(1.4, 0.9, 1.0), "palette75", 1.0)
	kit.box(Transform3D(xf.basis, bt + Vector3.UP * 0.95), Vector3(1.2, 0.1, 0.8), "tissu75_jaune", 1.0)
	kit.col_box(Transform3D(xf.basis, bt + Vector3.UP * 0.45), Vector3(1.4, 0.9, 1.0))
	gratuiterie = gx * Vector3(0, 0.05, 1.4)
	c.objets["gratuiterie"] = gratuiterie
	c.objets["boite_dons"] = bt
	c._pt("co_gratuiterie", gx * Vector3(0, 0.05, 2.2))
	c._spot("gratuiterie", gx * Vector3(0.3, 0.05, -1.2), xf.basis * Vector3(0, 0, 1), "comptoir", "co_gratuiterie")
	# le salon commun (au fond, à droite) : des canapés, une table basse, une bibliothèque
	var sx: Transform3D = xf * T(9.0, 0, -13.5)
	var seats2: Array = []
	seats2.append(kit.canape75(sx * T(-3.0, 0, 0), "rouge"))
	seats2.append(kit.canape75(sx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(4.0, 0, 1.6)), "vert"))
	kit.table_bobine75(sx * Vector3(0.0, 0, 2.0))
	for k6 in range(4):
		var cp: String = c._pt("co_chambre_%d" % (k6 + 1), sx * Vector3(-4.0 + k6 * 2.6, 0.05, 3.4))
		var pos: Vector3 = (seats2[0] if k6 < 2 else seats2[1]) as Vector3
		pos += (xf.basis * Vector3(-0.6 + (k6 % 2) * 1.2, 0, 0)) if k6 < 2 else (xf.basis * Vector3(0, 0, -0.6 + (k6 % 2) * 1.2))
		c._spot("conserverie_chambre_%d" % (k6 + 1), pos, xf.basis * Vector3(0, 0, 1) if k6 < 2 else xf.basis * Vector3(-1, 0, 0), ["assis", "lire", "allonge", "assis"][k6], cp)
	# les portes des habitants (leurs chambres, aux étages : une porte au fond, l'escalier intérieur)
	var residents := ["barricade", "rouille", "clou", "mouette", "lentille", "trocante", "pastille", "tapage", "velours", "bardane"]
	for i2 in range(residents.size()):
		var dp: Vector3 = xf * Vector3(-16.0 + i2 * 1.4 if i2 < 5 else 1.0 + (i2 - 5) * 1.3, 0.05, -15.2)
		c.doors["porte_" + residents[i2]] = c._pt("porte_" + residents[i2], dp)
	kit.box(xf * T(-9.5, 1.6, -15.65), Vector3(8.0, 3.2, 0.1), "peint75_rouge", 1.0)
	kit.box(xf * T(4.0, 1.6, -15.65), Vector3(7.0, 3.2, 0.1), "peint75_bleu", 1.0)
	# le toit : le jardin, la salle des assemblées, l'escalier de secours (dehors, côté ouest)
	var ry: float = h + 0.45
	toit = xf * Vector3(0, ry, -d * 0.5)
	kit.walk_boxes.append([(xf * T(0, ry, -d * 0.5)).affine_inverse(), Vector3(w * 0.5, 3.0, d * 0.5)])
	_zone("bo_toit", xf, Vector3(0, ry + 2.0, -d * 0.5), Vector3(w * 0.5, 2.6, d * 0.5))
	for s in [-1.0, 1.0]:
		kit.box(xf * T(0, ry + 0.45, (0.0 if s > 0 else -d) - s * 0.1), Vector3(w, 0.9, 0.2), "brique75", 1.6)
		kit.col_box(xf * T(0, ry + 0.45, (0.0 if s > 0 else -d) - s * 0.1), Vector3(w, 0.9, 0.2))
		kit.box(xf * T(s * (w * 0.5 - 0.1), ry + 0.45, -d * 0.5), Vector3(0.2, 0.9, d), "brique75", 1.6)
	for k7 in range(4):
		kit.bac75(xf * T(-12.0 + k7 * 4.0, ry, -4.0), 3.2, 1.2)
		kit.bac75(xf * T(-12.0 + k7 * 4.0, ry, -8.0), 3.2, 1.2)
	c._pt("co_toit", xf * Vector3(-6.0, ry + 0.05, -6.0))
	c._spot("conserverie_toit_jardin", xf * Vector3(-8.0, ry + 0.05, -6.0), xf.basis * Vector3(0, 0, 1), "jardiner", "co_toit")
	# la salle des assemblées : un cercle de chaises sous une pergola de récup
	var ax: Vector3 = xf * Vector3(9.0, ry, -8.0)
	for k8 in range(8):
		var a: float = TAU * k8 / 8.0
		kit.place("chaise75|" + ["rouge", "bleu", "jaune", "vert"][k8 % 4], Transform3D(Basis(Vector3.UP, -a + PI * 0.5), ax + Vector3(cos(a), 0, sin(a)) * 2.6))
	for s2 in [[-4.0, -3.5], [4.0, -3.5], [-4.0, 3.5], [4.0, 3.5]]:
		kit.box(Transform3D(xf.basis, ax + xf.basis * Vector3(float(s2[0]), 1.4, float(s2[1]))), Vector3(0.15, 2.8, 0.15), "acier75", 1.0)
	kit.box(Transform3D(xf.basis, ax + Vector3.UP * 2.85), Vector3(8.4, 0.1, 7.4), "tissu75_rouge", 1.0)
	kit.guirlande75(ax + xf.basis * Vector3(-4.0, 2.7, -3.5), ax + xf.basis * Vector3(4.0, 2.7, 3.5), 0.4)
	c._pt("co_assemblee", ax + Vector3.UP * 0.05 + xf.basis * Vector3(0, 0, 3.6))
	c._spot("conserverie_assemblee", ax + Vector3(cos(0.8), 0, sin(0.8)) * 2.6 + Vector3.UP * 0.5, -Vector3(cos(0.8), 0, sin(0.8)), "assis", "co_assemblee")
	# l'escalier de secours (deux volées le long du mur ouest)
	var ex: Vector3 = xf * Vector3(-w * 0.5 - 1.2, 0, 0)
	var mid_y: float = ry * 0.5
	var e0: Vector3 = xf * Vector3(-w * 0.5 - 1.0, 0.0, -0.5)
	var e1: Vector3 = xf * Vector3(-w * 0.5 - 1.0, mid_y, -d + 1.2)
	var e2: Vector3 = xf * Vector3(-w * 0.5 - 2.6, mid_y, -d + 1.2)
	var e3: Vector3 = xf * Vector3(-w * 0.5 - 2.6, ry, -0.8)
	kit.stair(e0, e1, 1.3, "acier75", "metal75_noir", 0.9, 0.06)
	kit.box(Transform3D(xf.basis, (e1 + e2) * 0.5 + Vector3.DOWN * 0.1 + xf.basis * Vector3(0, 0, -0.6)), Vector3(3.0, 0.2, 2.4), "acier75", 1.0)
	kit.col_box(Transform3D(xf.basis, (e1 + e2) * 0.5 + Vector3.DOWN * 0.1 + xf.basis * Vector3(0, 0, -0.6)), Vector3(3.0, 0.2, 2.4))
	kit.stair(e2, e3, 1.3, "acier75", "metal75_noir", 0.9, 0.06)
	var top_land: Vector3 = xf * Vector3(-w * 0.5 - 1.6, ry - 0.1, -0.6)
	kit.box(Transform3D(xf.basis, top_land), Vector3(3.4, 0.2, 1.8), "acier75", 1.0)
	kit.col_box(Transform3D(xf.basis, top_land), Vector3(3.4, 0.2, 1.8))
	kit.walk_boxes.append([(Transform3D(xf.basis, top_land + Vector3.UP * 0.1)).affine_inverse(), Vector3(1.7, 3.0, 0.9)])
	kit.walk_boxes.append([(Transform3D(xf.basis, (e1 + e2) * 0.5 + xf.basis * Vector3(0, 0, -0.6))).affine_inverse(), Vector3(1.5, 3.0, 1.2)])
	c._pt("co_secours_bas", xf * Vector3(-w * 0.5 - 1.0, 0.05, 1.6))
	c._pt("co_secours_palier", (e1 + e2) * 0.5 + Vector3.UP * 0.05)
	c._pt("co_secours_haut", top_land + Vector3.UP * 0.15)
	c._pt("co_toit_entree", xf * Vector3(-w * 0.5 + 1.6, ry + 0.05, -0.8))
	c._chain(["co_secours_bas", "co_secours_palier", "co_secours_haut", "co_toit_entree", "co_toit", "co_assemblee"])
	_street_link("co_secours_bas")
	# le réseau du rez-de-chaussée
	c._pt("co_dehors", P(xf, -6.0, 3.0))
	c._pt("co_entree", P(xf, -6.0, -1.6))
	c._pt("co_salle", P(xf, -6.0, -6.0))
	c._pt("co_fond", P(xf, 4.0, -11.6))
	c._spot("conserverie_entree", P(xf, -4.4, -1.8), xf.basis * Vector3(0, 0, -1), "debout", "co_entree")
	c._chain(["co_dehors", "co_entree", "co_salle", "co_comptoir", "co_comptoir_derriere", "co_cuisine"])
	c._chain(["co_salle", "co_gratuiterie", "co_fond"])
	c._chain(["co_salle", "co_fond"])
	for i3 in range(6):
		c._link("co_table_%d" % (i3 + 1), "co_salle")
	for k9 in range(4):
		c._link("co_chambre_%d" % (k9 + 1), "co_fond")
	for r2 in residents:
		c._link("porte_" + r2, "co_fond")
	_street_link("co_dehors")
	c._avoid(P(xf, 0, -d * 0.5), 20.0)


# =================================================================== la Filature

func filature() -> void:
	var xf: Transform3D = c.XF(-24.0, -64.0, 0.0, -1.0)
	var w: float = 52.0
	var d: float = 22.0
	kit.usine75(xf, w, d, {"h": 7.0, "hollow": true, "roof": "shed", "roof_key": "tole75", "wall": "brique75", "inner": "briquep75_blanc",
		"floor_key": "betonsol75", "door_w": 4.0, "door_h": 3.6, "back_door": true, "rows": 1, "lit": 0.6, "lights": 4, "bay": 4.3,
		"sign": "imprimerie", "sign_w": 7.0, "sign_h": 1.4, "sign_y": 4.8, "sign_x": -14.0,
		"fresques": [{"side": "r", "id": 4, "w": 14.0, "h": 4.6, "x": 0.0, "y": 1.0}, {"side": "b", "id": 6, "w": 16.0, "h": 4.4, "x": 8.0, "y": 1.2}]})
	kit.quadz(xf * T(14.0, 4.8, 0.32), 6.0, 1.4, "enseigne75_velo")
	_zone("bo_filature", xf, Vector3(0, 3.6, -d * 0.5), Vector3(w * 0.5 - 0.3, 3.8, d * 0.5 - 0.3))
	# les quatre ateliers (le long du mur du fond, vers -Z), séparés par des cloisons de palettes
	var ateliers := [["atelier_velo", -18.0, "bricoler"], ["imprimerie", -6.0, "scribe"], ["atelier_couture", 6.0, "bricoler"], ["menuiserie", 18.0, "bricoler"]]
	for i in range(ateliers.size()):
		var ax: float = float(ateliers[i][1])
		var bx: Transform3D = xf * T(ax, 0, -d + 3.2)
		# l'établi
		kit.box(bx * T(0, 0.85, 0), Vector3(4.0, 0.1, 1.2), "palette75", 1.0)
		for s in [-1.8, 1.8]:
			kit.box(bx * T(s, 0.42, 0), Vector3(0.12, 0.84, 1.0), "acier75", 1.0)
		kit.col_box(bx * T(0, 0.45, 0), Vector3(4.0, 0.9, 1.2))
		var pt: String = c._pt("fi_" + str(ateliers[i][0]), bx * Vector3(0, 0.05, 2.4))
		c._spot(str(ateliers[i][0]), bx * Vector3(0, 0.05, 1.05), xf.basis * Vector3(0, 0, -1), str(ateliers[i][2]), pt)
		# la cloison (entre deux ateliers)
		if i > 0:
			kit.box(xf * T(ax - 6.0, 1.1, -d + 3.0), Vector3(0.15, 2.2, 5.0), "palette75", 1.0)
			kit.col_box(xf * T(ax - 6.0, 1.1, -d + 3.0), Vector3(0.15, 2.2, 5.0))
		match str(ateliers[i][0]):
			"atelier_velo":
				for k in range(3):
					_velo(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(ax - 2.0 + k * 1.6, 0, -d + 6.4)))
				kit.box(bx * T(0, 2.3, -0.5), Vector3(3.6, 1.2, 0.05), "rivete75_gris", 1.0)
			"imprimerie":
				kit.box(bx * T(0, 0.96, 0), Vector3(1.4, 0.12, 1.0), "metal75_gris", 1.0)
				for k2 in range(5):
					kit.quadz(xf * T(ax - 2.0 + k2 * 1.0, 2.2, -d + 5.4), 0.7, 0.95, "affiche75_" + str(1 + k2 % 4))
				kit.beam(xf * Vector3(ax - 2.6, 2.75, -d + 5.4), xf * Vector3(ax + 2.6, 2.75, -d + 5.4), 0.01, "metal75_noir")
				kit.quadz(bx * T(1.4, 0.92, 0.3) * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), 0.5, 0.7, "fanzine75")
			"atelier_couture":
				for k3 in range(4):
					kit.cyl(bx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-1.6 + k3 * 1.0, 1.2, -0.3)), 0.12, 0.12, 0.9, "tissu75_" + ["rouge", "bleu", "violet", "jaune"][k3], 10)
			"menuiserie":
				kit.pile_palettes75(bx * Vector3(-1.0, 0, 2.6), 6, 0.2)
				kit.pile_palettes75(bx * Vector3(1.4, 0, 2.8), 4, -0.3)
		c.objets[str(ateliers[i][0])] = bx * Vector3(0, 0.05, 1.8)
	# les habitants de la Filature : des lofts au fond (des portes dans le mur du fond)
	var residents := ["rustine", "copeau", "tornade", "cerise", "agrafe", "pigment", "fusible"]
	for i2 in range(residents.size()):
		var dp: Vector3 = xf * Vector3(-22.0 + i2 * 6.6, 0.05, -d + 0.9)
		c.doors["porte_" + residents[i2]] = c._pt("porte_" + residents[i2], dp)
		kit.place("porte75|" + ["rouge", "bleu", "jaune", "vert", "violet", "orange", "noir"][i2], xf * Transform3D(Basis(), Vector3(-22.0 + i2 * 6.6, 0.05, -d + 0.27)))
	# le réseau
	c._pt("fi_dehors", P(xf, 0, 3.0))
	c._pt("fi_entree", P(xf, 0, -1.6))
	c._pt("fi_allee", P(xf, 0, -9.0))
	c._pt("fi_allee_o", P(xf, -16.0, -9.0))
	c._pt("fi_allee_e", P(xf, 16.0, -9.0))
	c._pt("fi_derriere", P(xf, 0, -d - 3.0))
	c._pt("fi_porte_arriere", P(xf, 0, -d + 1.6))
	c._spot("filature_entree", P(xf, 2.0, -2.0), xf.basis * Vector3(0, 0, -1), "debout", "fi_entree")
	c._chain(["fi_dehors", "fi_entree", "fi_allee", "fi_porte_arriere", "fi_derriere"])
	c._chain(["fi_allee_o", "fi_allee", "fi_allee_e"])
	c._link("fi_atelier_velo", "fi_allee_o")
	c._link("fi_imprimerie", "fi_allee")
	c._link("fi_atelier_couture", "fi_allee")
	c._link("fi_menuiserie", "fi_allee_e")
	for i3 in range(residents.size()):
		c._link("porte_" + residents[i3], "fi_allee_o" if i3 < 3 else ("fi_allee" if i3 < 5 else "fi_allee_e"))
	_street_link("fi_dehors")
	_street_link("fi_derriere")
	c._avoid(P(xf, 0, -d * 0.5), 30.0)


## Un vélo posé sur sa béquille (xf : au sol, le vélo le long de X).
func _velo(xf: Transform3D) -> void:
	for s in [-0.55, 0.55]:
		kit.ring(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(s, 0.34, 0)), 0.3, 0.34, 0.04, "caoutchouc75", 16)
	var col: String = "tolep75_" + ["rouge", "bleu", "jaune", "vert"][kit.rng.randi() % 4]
	kit.beam(xf * Vector3(-0.55, 0.34, 0), xf * Vector3(0.0, 0.34, 0), 0.03, col)
	kit.beam(xf * Vector3(0.0, 0.34, 0), xf * Vector3(-0.15, 0.85, 0), 0.03, col)
	kit.beam(xf * Vector3(-0.15, 0.85, 0), xf * Vector3(0.45, 0.82, 0), 0.03, col)
	kit.beam(xf * Vector3(0.45, 0.82, 0), xf * Vector3(0.55, 0.34, 0), 0.03, col)
	kit.beam(xf * Vector3(0.0, 0.34, 0), xf * Vector3(0.45, 0.82, 0), 0.03, col)
	kit.box(xf * T(-0.18, 0.92, 0), Vector3(0.24, 0.04, 0.1), "caoutchouc75", 1.0)
	kit.box(xf * T(0.48, 1.0, 0), Vector3(0.04, 0.04, 0.5), "chrome75", 1.0)


## La Grande Cheminée (à l'est de la Filature).
func cheminee() -> void:
	var p: Vector3 = c.G(14.0, -50.0, 0.0)
	kit.cheminee75(p, 42.0, 2.0, 1.3)
	kit.quadz(Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), p + Vector3(0, 7.0, 1.95)), 3.0, 1.8, "graffiti75_5")
	c._avoid(p, 6.0)


# =================================================================== la Place des Palettes

func place() -> void:
	var cxf: Transform3D = c.XF(-6.0, -82.0, 0.0, 1.0)
	_zone("bo_place", cxf, Vector3(0, 3.0, 0), Vector3(26.0, 4.0, 14.0))
	# la fontaine-baignoire
	var spout: Vector3 = kit.baignoire75(cxf * T(0, 0, 0))
	c._pt("pl_fontaine", P(cxf, 0, 2.4))
	c._spot("place_fontaine", P(cxf, 1.2, 1.6), cxf.basis * Vector3(-0.4, 0, -1).normalized(), "debout", "pl_fontaine")
	# l'arbre aux guirlandes (planté par la flore), des guirlandes vers des mâts
	var tree: Vector3 = P(cxf, 12.0, 6.0, 0.0)
	c.tree_spots.append(tree)
	c._pt("pl_arbre", P(cxf, 10.0, 3.6))
	c._spot("place_arbre", P(cxf, 10.6, 4.6), cxf.basis * Vector3(0, 0, -1), "observer", "pl_arbre")
	var masts: Array = []
	for m in [Vector3(-14.0, 0, -8.0), Vector3(14.0, 0, -8.0), Vector3(-14.0, 0, 8.0)]:
		var mp: Vector3 = cxf * m
		kit.cyl(Transform3D(Basis(), mp), 0.1, 0.08, 6.0, "acier75", 8, false)
		kit.col_cyl(mp, 0.12, 6.0)
		masts.append(mp + Vector3.UP * 5.8)
	for mm in masts:
		kit.guirlande75(mm, tree + Vector3.UP * 5.5, 0.8)
	kit.guirlande75(masts[0], masts[1], 1.2)
	# les canapés de palettes, les tables-bobines
	var b1: Vector3 = kit.canape75(cxf * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-12.0, 0, -6.0)), "rouge")
	var b2: Vector3 = kit.canape75(cxf * Transform3D(Basis(Vector3.UP, -0.3), Vector3(6.0, 0, -8.0)), "bleu")
	c._pt("pl_banc_1", P(cxf, -11.0, -3.6))
	c._pt("pl_banc_2", P(cxf, 6.4, -5.6))
	c._spot("place_banc_1", b1, cxf.basis * Vector3(0.3, 0, 1).normalized(), "assis", "pl_banc_1")
	c._spot("place_banc_2", b2, cxf.basis * Vector3(-0.2, 0, 1).normalized(), "assis", "pl_banc_2")
	kit.table_bobine75(cxf * Vector3(-11.0, 0, -2.6))
	kit.table_bobine75(cxf * Vector3(6.0, 0, -4.4))
	# le camion-cuisine (une vieille camionnette peinte, un auvent)
	var tx: Transform3D = cxf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-17.0, 0, 6.0))
	kit.box(tx * T(0, 1.55, 0), Vector3(2.2, 2.4, 5.4), "tolep75_turquoise", 1.4)
	kit.box(tx * T(0, 1.2, 2.9), Vector3(2.2, 1.6, 0.6), "tolep75_turquoise", 1.0)
	for s in [-1.0, 1.0]:
		for z in [-1.8, 2.2]:
			kit.place("pneu75", tx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * 1.0, 0.36, z)))
	kit.box(tx * T(1.12, 1.7, 0), Vector3(0.04, 1.0, 3.0), "vitre75_on", 1.0)
	kit.awning71(tx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.1, 2.6, 0)), 3.6, 1.6, 0.4, "rouge")
	kit.col_box(tx * T(0, 1.4, 0.3), Vector3(2.3, 2.8, 6.0))
	c._pt("pl_camion", tx * Vector3(2.8, 0.05, 0))
	c._spot("place_camion", tx * Vector3(2.1, 0.05, 0.5), tx.basis * Vector3(-1, 0, 0), "boire", "pl_camion")
	# la table de ping-pong
	var pp: Transform3D = cxf * T(6.0, 0, 8.0)
	kit.box(pp * T(0, 0.74, 0), Vector3(1.5, 0.05, 2.7), "peint75_vert", 1.0)
	kit.box(pp * T(0, 0.86, 0), Vector3(1.6, 0.15, 0.02), "peint75_blanc", 1.0)
	for sx in [-0.6, 0.6]:
		for sz in [-1.1, 1.1]:
			kit.box(pp * T(sx, 0.37, sz), Vector3(0.06, 0.74, 0.06), "metal75_gris", 1.0)
	kit.col_box(pp * T(0, 0.4, 0), Vector3(1.5, 0.8, 2.7))
	c._pt("pl_jeu", pp * Vector3(1.6, 0.05, 0))
	c._spot("place_jeu_1", pp * Vector3(0, 0.05, -1.9), pp.basis * Vector3(0, 0, 1), "jouer", "pl_jeu")
	c._spot("place_jeu_2", pp * Vector3(0, 0.05, 1.9), pp.basis * Vector3(0, 0, -1), "jouer", "pl_jeu")
	c._chain(["pl_fontaine", "pl_banc_1"])
	c._chain(["pl_fontaine", "pl_banc_2"])
	c._chain(["pl_fontaine", "pl_arbre", "pl_jeu"])
	c._chain(["pl_fontaine", "pl_camion"])
	for p in ["pl_fontaine", "pl_camion", "pl_jeu"]:
		_street_link(p)
	c._avoid(P(cxf, 0, 0), 14.0)
	c.animals.append(["pigeon", P(cxf, -2.0, -4.0, 0.0), 8.0])
	c.animals.append(["pigeon", P(cxf, 4.0, 4.0, 0.0), 6.0])
	c.animals.append(["chien", P(cxf, -8.0, 2.0, 0.0), 10.0])


# =================================================================== le port

func port() -> void:
	# les deux grues sur le quai sud du Vieux Bassin, leurs flèches au-dessus de l'eau
	for gx in [-10.0, 36.0]:
		var gxf: Transform3D = c.XF(gx, -163.0, 0.0, 1.0)
		kit.grue75(gxf, 18.0, "jaune" if gx < 0.0 else "orange")
	c._pt("po_grue", c.G(-10.0, -154.0))
	c._spot("grue", c.G(-6.0, -160.0), Vector3(0, 0, -1), "observer", "po_grue")
	# les quais : des bittes, des lampadaires, des piles de conteneurs
	for x in range(-34, 56, 6):
		kit.place("bitte75", Transform3D(Basis(), c.G(float(x), -159.8, -0.05)))
	for side in [-1.0, 1.0]:
		var qx: float = -38.5 if side < 0.0 else 58.5
		for z in range(-200, -164, 7):
			kit.place("bitte75", Transform3D(Basis(), c.G(qx + side * 0.6, float(z), -0.05)))
	var stacks := [[-62.0, -176.0, 0.0], [-62.0, -168.0, 0.0], [-58.0, -186.0, 0.3], [76.0, -170.0, PI * 0.5], [70.0, -186.0, PI * 0.5]]
	var k: int = 0
	for st in stacks:
		var levels: int = 1 + (k % 3)
		for lv in range(levels):
			var cxf: Transform3D = Transform3D(Basis(Vector3.UP, float(st[2]) + (kit.rng.randf() - 0.5) * 0.05), c.G(float(st[0]), float(st[1]), lv * 2.6 - 0.05))
			kit.conteneur75(cxf, kit.CONT_V[(k + lv) % kit.CONT_V.size()], {"len": 12.0})
		k += 1
	# des palettes, des barils, des filets
	for i in range(6):
		kit.pile_palettes75(c.G(-50.0 + i * 3.0, -154.0, -0.05), 2 + i % 3, i * 0.4)
	for i2 in range(5):
		kit.baril75(c.G(64.0 + i2 * 1.1, -156.0 + (i2 % 2) * 1.0, -0.05))
	# l'escalier du ponton (du ponton de la barque jusqu'au quai, contre le mur du bassin)
	var s0: Vector3 = R.W(-27.6, -160.7, 1.0)
	var s1: Vector3 = R.W(-35.6, -160.7, Y_QUAI)
	kit.stair(s0, s1, 1.5, "beton75", "acier75", 0.9, 0.06)
	for k2 in range(4):
		kit.cyl(Transform3D(Basis(), R.W(-28.0 - k2 * 2.6, -161.6, -6.0)), 0.18, 0.18, 6.6 + k2 * 0.6, "acier75", 8, false)
	kit.box(Transform3D(Basis(), R.W(-37.0, -160.0, Y_QUAI - 0.1)), Vector3(2.4, 0.2, 2.6), "beton75", 1.0)
	kit.col_box(Transform3D(Basis(), R.W(-37.0, -160.0, Y_QUAI - 0.1)), Vector3(2.4, 0.2, 2.6))
	c._pt("po_ponton", R.W(-26.0, -164.0, 1.05))
	c._pt("po_escalier", R.W(-37.0, -157.6, Y_QUAI + 0.05))
	c._chain(["po_ponton", "po_escalier"])
	_street_link("po_escalier")
	c.objets["ponton"] = R.W(-26.0, -164.0, 1.05)
	# les lieux des quais (on y pêche, on y regarde la mer)
	var qs := [["quai_1", 4.0, "pecher"], ["quai_2", 22.0, "assis"], ["quai_3", 48.0, "observer"]]
	for q in qs:
		var qp: String = c._pt("po_" + str(q[0]), c.G(float(q[1]), -157.6))
		c._spot(str(q[0]), c.G(float(q[1]), -159.0), Vector3(0, 0, -1), str(q[2]), qp)
		_street_link(qp)
	c.animals.append(["mouette", c.G(20.0, -158.0, 0.0), 14.0])
	c.animals.append(["mouette", c.G(-50.0, -160.0, 0.0), 10.0])
	c.animals.append(["chat", c.G(-58.0, -176.0, 7.8), 2.0])


const Y_QUAI: float = R.TOWN_Y


# =================================================================== le cargo échoué

func cargo() -> void:
	var cp: Vector3 = R.W(R.CARGO.x, R.CARGO.y)
	cp.y = 0.2
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(-R.CARGO_YAW)), cp)
	var info: Dictionary = kit.cargo75(xf, 62.0, 11.0, 6.0)
	cargo_info = info
	_zone("bo_cargo", xf, Vector3(0, 9.0, 0), Vector3(32.0, 8.0, 6.5))
	studio = info["studio"]
	c.objets["radio_studio"] = studio
	# la grande passerelle (de la plage au pont)
	var g: Array = info["gang"]
	var gb: Vector3 = g[0]
	gb.y = c.ile.height(gb.x, gb.z)
	kit.stair(gb, g[1], 1.6, "acier75", "metal75_noir", 0.9, 0.06)
	c._pt("ca_passerelle_bas", gb + (gb - (g[1] as Vector3)).normalized() * 1.4 * Vector3(1, 0, 1) + Vector3.UP * 0.05)
	c._pt("ca_passerelle_haut", (g[1] as Vector3) + Vector3.UP * 0.05)
	c._pt("ca_pont", (info["pont"] as Vector3) + Vector3.UP * 0.05)
	c._pt("ca_escalier_bas", (info["bridge_bot"] as Vector3) + Vector3.UP * 0.05)
	c._pt("ca_escalier_haut", (info["bridge_top"] as Vector3) + Vector3.UP * 0.05)
	c._pt("ca_studio_porte", (info["studio_door"] as Vector3))
	c._pt("ca_studio", studio)
	c._chain(["ca_passerelle_bas", "ca_passerelle_haut", "ca_pont", "ca_escalier_bas", "ca_escalier_haut", "ca_studio_porte", "ca_studio"])
	c._spot("cargo_passerelle", (g[1] as Vector3) + Vector3.UP * 0.05 + (xf.basis * Vector3(1.2, 0, 0)), xf.basis * Vector3(0, 0, 1), "observer", "ca_passerelle_haut")
	c._spot("cargo_pont", (info["pont"] as Vector3) + Vector3.UP * 0.05 + xf.basis * Vector3(2.0, 0, 3.6), xf.basis * Vector3(1, 0, 0), "assis", "ca_pont")
	c._spot("radio_studio", studio + xf.basis * Vector3(1.6, 0, 0), xf.basis * Vector3(1, 0, 0), "comptoir", "ca_studio")
	c._spot("cargo_cabine", (info["pont"] as Vector3) + Vector3.UP * 0.05 + xf.basis * Vector3(-4.0, 0, 0), xf.basis * Vector3(0, 0, 1), "lire", "ca_pont")
	c.doors["porte_sergent"] = c._pt("porte_sergent", studio + xf.basis * Vector3(-1.2, 0, 1.6))
	c._link("porte_sergent", "ca_studio")
	# le studio : un pupitre, des platines, des piles de disques, un micro
	var sx: Transform3D = Transform3D(xf.basis, studio)
	kit.box(sx * T(2.2, 0.45, 0), Vector3(0.9, 0.9, 3.4), "palette75", 1.0)
	kit.box(sx * T(2.2, 0.95, 0), Vector3(0.8, 0.1, 3.2), "metal75_gris", 1.0)
	kit.col_box(sx * T(2.2, 0.45, 0), Vector3(0.9, 0.9, 3.4))
	kit.cyl(sx * T(2.2, 1.0, -0.8), 0.18, 0.18, 0.03, "caoutchouc75", 14)
	kit.cyl(sx * T(2.2, 1.0, 0.8), 0.18, 0.18, 0.03, "caoutchouc75", 14)
	kit.box(sx * T(2.0, 1.4, 0.0), Vector3(0.05, 0.6, 0.05), "metal75_noir", 1.0)
	kit.box(sx * T(-1.6, 0.6, -2.4), Vector3(1.6, 1.2, 0.5), "tissu75_noir", 1.0)
	kit.box(sx * T(0, 2.4, 0), Vector3(0.6, 0.06, 0.3), "neon75_rouge", 1.0)
	kit._hall_light(sx * Vector3(0, 2.2, 0), Color(1.0, 0.5, 0.4), 0.9, 6.0)
	kit.quadz(sx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-2.9, 1.5, 0)), 2.0, 0.6, "enseigne75_radio")
	kit.quadz(Transform3D(Basis.looking_at(-(xf.basis * Vector3(0, 0, 1)), Vector3.UP), (info["pont"] as Vector3) + xf.basis * Vector3(-24.0, 3.0, 5.9)), 4.0, 1.2, "enseigne75_radio")
	kit.fresque75(Transform3D(xf.basis, cp + xf.basis * Vector3(0, 0, 5.3)), 0.0, 0.0, {"side": "f", "id": 3, "w": 16.0, "h": 4.0, "x": 6.0, "y": 1.2})
	c._avoid(cp, 34.0)
	c.animals.append(["mouette", cp + xf.basis * Vector3(10.0, 6.4, 0), 6.0])
	c.animals.append(["rat", cp + xf.basis * Vector3(-4.0, 6.2, 2.0), 3.0])


# =================================================================== le skatepark de la cale sèche

func bassin_sec() -> void:
	var r: Rect2 = R.DRY
	var fy: float = R.DRY_Y
	var cx: float = r.get_center().x
	_zone("bo_skate", Transform3D(Basis(), R.W(cx, r.get_center().y, fy + 2.0)), Vector3.ZERO, Vector3(r.size.x * 0.5, 4.0, r.size.y * 0.5))
	# la porte de la cale (au nord, côté mer) : un caisson d'acier
	kit.box(Transform3D(Basis(), R.W(cx, r.position.y + 0.6, (fy + Y) * 0.5 - 0.5)), Vector3(r.size.x + 2.0, Y - fy + 4.0, 1.2), "acier75", 2.0)
	kit.col_box(Transform3D(Basis(), R.W(cx, r.position.y + 0.6, (fy + Y) * 0.5 - 0.5)), Vector3(r.size.x + 2.0, Y - fy + 4.0, 1.2))
	kit.quadz(Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), R.W(cx, r.position.y + 1.25, fy + 1.8)), 8.0, 3.0, "graffiti75_2")
	# la rampe d'accès (au sud : du quai au fond de la cale)
	var a0: Vector3 = R.W(r.end.x - 4.0, r.end.y + 4.0, Y)
	var a1: Vector3 = R.W(r.end.x - 4.0, r.end.y - 6.0, fy)
	kit.stair(a1, a0, 3.0, "beton75", "", 0.6, 0.5)
	# les modules : deux quarts de lune, une boîte à sauts, un rail
	kit.quarter75(Transform3D(Basis(Vector3.UP, PI), R.W(cx - 6.0, r.position.y + 6.0, fy)), 10.0, 2.2)
	kit.quarter75(Transform3D(Basis(), R.W(cx + 2.0, r.end.y - 9.0, fy)), 10.0, 1.6)
	kit.funbox75(Transform3D(Basis(Vector3.UP, PI * 0.5), R.W(cx - 4.0, r.get_center().y, fy)), 4.0, 3.0, 0.7)
	kit.box(Transform3D(Basis(), R.W(cx + 8.0, r.get_center().y, fy + 0.45)), Vector3(0.06, 0.06, 8.0), "acier75", 1.0)
	for z in [-3.6, 3.6]:
		kit.box(Transform3D(Basis(), R.W(cx + 8.0, r.get_center().y + z, fy + 0.22)), Vector3(0.06, 0.44, 0.06), "acier75", 1.0)
	# des graffitis sur les murs de la cale
	for k in range(4):
		var gz: float = r.position.y + 6.0 + k * 8.0
		kit.quadz(Transform3D(Basis(Vector3.UP, PI * 0.5), R.W(r.position.x + 0.15, gz, fy + 1.6)), 5.0, 2.4, "graffiti75_" + str(3 + k * 2))
		c.walls_paint.append([Transform3D(Basis(Vector3.UP, -PI * 0.5), R.W(r.end.x - 0.15, gz, fy + 1.6)), 4.0, 2.0])
	c._pt("sk_haut", R.W(r.end.x - 4.0, r.end.y + 6.0, Y + 0.05))
	c._pt("sk_bas", R.W(r.end.x - 4.0, r.end.y - 8.0, fy + 0.05))
	c._pt("sk_milieu", R.W(cx, r.get_center().y, fy + 0.05))
	c._chain(["sk_haut", "sk_bas", "sk_milieu"])
	c._spot("bassin_sec_1", R.W(cx - 2.0, r.get_center().y + 4.0, fy + 0.05), Vector3(0, 0, -1), "skate", "sk_milieu")
	c._spot("bassin_sec_2", R.W(cx + 4.0, r.get_center().y - 4.0, fy + 0.05), Vector3(-1, 0, 0), "observer", "sk_milieu")
	_street_link("sk_haut")
	# les baguettes de batterie du groupe (bo_concert) : oubliées au fond de la cale
	c.objets["baguettes"] = R.W(cx - 9.0, r.position.y + 9.0, fy + 0.15)


# =================================================================== le Mur d'Expression

func mur() -> void:
	var x: float = -118.0
	var z0: float = -88.0
	var z1: float = -48.0
	var len: float = z1 - z0
	var mid: Vector3 = c.G(x, (z0 + z1) * 0.5, 0.0)
	kit.box(Transform3D(Basis(), mid + Vector3.UP * 2.0), Vector3(0.5, 4.0, len), "beton75", 2.0)
	kit.col_box(Transform3D(Basis(), mid + Vector3.UP * 2.0), Vector3(0.5, 4.0, len))
	_zone("bo_mur", Transform3D(Basis(), mid + Vector3(10.0, 2.0, 0.0)), Vector3.ZERO, Vector3(12.0, 4.0, len * 0.5 + 2.0))
	# des graffitis déjà là (et des places libres : le joueur peindra par-dessus le béton nu)
	var n: int = 8
	for k in range(n):
		var gz: float = z0 + len * (k + 0.5) / n
		var fx := Transform3D(Basis(Vector3.UP, -PI * 0.5), c.G(x + 0.27, gz, 1.9))
		if k % 2 == 0:
			kit.quadz(fx, 4.4, 2.6, "graffiti75_" + str([6, 8, 11, 12][k / 2]))
		else:
			mur_points.append([fx, 4.4, 2.6])
	# l'autre face : une grande fresque
	kit.quadz(Transform3D(Basis(Vector3.UP, PI * 0.5), c.G(x - 0.27, (z0 + z1) * 0.5, 2.0)), 20.0, 3.8, "fresque75_6")
	for k2 in range(6):
		kit.baril75(c.G(x + 3.0, z0 + 2.0 + k2 * 0.8, 0.0))
	c._pt("mu_milieu", c.G(x + 6.0, (z0 + z1) * 0.5))
	c._pt("mu_nord", c.G(x + 4.0, z0 + 6.0))
	c._pt("mu_sud", c.G(x + 4.0, z1 - 6.0))
	c._chain(["mu_nord", "mu_milieu", "mu_sud"])
	c._spot("mur_expression_1", c.G(x + 2.0, z0 + 10.0), Vector3(-1, 0, 0), "peindre", "mu_nord")
	c._spot("mur_expression_2", c.G(x + 2.0, z1 - 12.0), Vector3(-1, 0, 0), "peindre", "mu_sud")
	_street_link("mu_milieu")
	c.objets["mur_expression"] = c.G(x + 2.0, (z0 + z1) * 0.5)
	c.animals.append(["chat", c.G(x, z0 + 4.0, 4.1), 1.0])


# =================================================================== le château d'eau, les Boîtes, les Jardins

func chateau_eau() -> void:
	var p: Vector3 = c.G(118.0, -62.0, 0.0)
	antenne = kit.chateau_eau75(p, 7)
	c.objets["antenne_radio"] = antenne + Vector3(4.0, 0.15, 3.0)
	c._pt("ce_pied", p + Vector3(8.0, 0.05, 0.0))
	c._spot("chateau_eau", p + Vector3(7.6, 0.05, 2.0), Vector3(-1, 0, 0), "observer", "ce_pied")
	_street_link("ce_pied")
	c._avoid(p, 10.0)


func boites() -> void:
	# le village des conteneurs : trois rangées, empilées sur deux niveaux par endroits, peintes,
	# avec des escaliers et une coursive
	var homes := ["patchouli", "chaussette", "cradoc", "larsen", "sirene"]
	var k: int = 0
	var spots_done: int = 0
	for row in range(3):
		var z: float = -30.0 + row * 9.0
		for i in range(3):
			var x: float = 66.0 + i * 13.5
			var col: String = kit.CONT_V[(row * 3 + i + 2) % kit.CONT_V.size()]
			var cxf: Transform3D = c.XF(x, z, 0.0, 1.0)
			var door: Vector3 = kit.conteneur75(cxf, col, {"len": 12.0, "home": true, "door_color": ["jaune", "rouge", "bleu"][i], "v81": true})
			if k < homes.size():
				c.doors["porte_" + homes[k]] = c._pt("porte_" + homes[k], door + Vector3.UP * 0.05)
				_street_link("porte_" + homes[k])
			k += 1
			if (row + i) % 2 == 0:
				kit.conteneur75(cxf * Transform3D(Basis(), Vector3(0, 2.6, 0)), kit.CONT_V[(row + i * 2) % kit.CONT_V.size()], {"len": 12.0, "home": true})
			if spots_done < 3 and (row + i) % 3 == 1:
				spots_done += 1
				var sp: String = c._pt("bx_%d" % spots_done, c.G(x, z + 3.6))
				c._spot("boites_%d" % spots_done, c.G(x + 1.0, z + 2.6), Vector3(0, 0, 1), ["assis", "jardiner", "lire"][spots_done - 1], sp)
				_street_link(sp)
				kit.canape75(c.XF(x + 1.0, z + 2.0, 0.0, 1.0), ["violet", "jaune", "vert"][spots_done - 1])
	for i2 in range(3):
		kit.place("plante75|" + ["rouge", "jaune", "bleu"][i2], Transform3D(Basis(), c.G(70.0 + i2 * 13.0, -26.0, 0.0)))
	kit.guirlande75(c.G(64.0, -24.0, 4.0), c.G(96.0, -24.0, 4.0), 0.6)
	c.animals.append(["chien", c.G(80.0, -20.0, 0.0), 8.0])
	c.animals.append(["chat", c.G(66.0, -12.0, 5.3), 2.0])


func jardins() -> void:
	var o := Vector2(114.0, -30.0)
	for row in range(3):
		for i in range(5):
			kit.bac75(c.XF(o.x + 3.0 + i * 6.0, o.y + 4.0 + row * 6.0, 0.0, 1.0), 4.0, 1.4)
	var gx: Vector3 = kit.serre75(c.XF(150.0, -10.0, -1.0, 0.0), 5.0, 8.0)
	for k in range(4):
		kit.ruche75(c.G(152.0, -28.0 + k * 1.4, 0.0), 0.2 * k)
	# la cabane de Radis (des planches, un toit de tôle)
	var hx: Transform3D = c.XF(118.0, -6.0, 0.0, -1.0)
	kit.box(hx * T(0, 1.3, -1.6), Vector3(3.6, 2.6, 3.2), "bardage75", 1.4)
	kit.box(hx * Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 2.8, -1.6)), Vector3(4.2, 0.06, 4.0), "tole75", 1.4)
	kit.col_box(hx * T(0, 1.3, -1.6), Vector3(3.6, 2.6, 3.2))
	kit.place("porte75|vert", hx * T(0.6, 0, 0.0))
	c.doors["porte_radis"] = c._pt("porte_radis", hx * Vector3(0.6, 0.05, 1.0))
	# les paniers de légumes de la quête de Lentille (bo_cantine)
	for k2 in range(3):
		c.objets["panier_%d" % (k2 + 1)] = c.G(o.x + 6.0 + k2 * 12.0, o.y + 7.2 + k2 * 4.0, 0.15)
	c._pt("ja_entree", c.G(o.x + 2.0, o.y + 2.0))
	c._pt("ja_milieu", c.G(o.x + 18.0, o.y + 10.0))
	c._pt("ja_serre", c.G(150.0, -8.0))
	c._chain(["ja_entree", "ja_milieu", "ja_serre", "porte_radis"])
	c._link("porte_radis", "ja_milieu")
	c._spot("jardins_1", c.G(o.x + 9.0, o.y + 8.6), Vector3(0, 0, -1), "jardiner", "ja_milieu")
	c._spot("jardins_2", c.G(o.x + 21.0, o.y + 14.6), Vector3(0, 0, -1), "jardiner", "ja_milieu")
	c._spot("jardins_serre", gx, Vector3(0, 0, -1).rotated(Vector3.UP, PI * 0.5), "jardiner", "ja_serre")
	_street_link("ja_entree")
	c._avoid(c.G(134.0, -18.0, 0.0), 22.0)
	c.animals.append(["pigeon", c.G(130.0, -20.0, 0.0), 6.0])


# =================================================================== le bureau de vente, les rails

func bureau() -> void:
	var xf: Transform3D = c.XF(-58.0, -26.0, 0.0, -1.0)
	var door: Vector3 = kit.algeco75(xf, 10.0, 4.0)
	# les panneaux « BIENTÔT ICI : LE LISSE-CENTER », l'enseigne, un petit gazon en plastique
	for s in [-1.0, 1.0]:
		var pxf: Transform3D = xf * T(s * 9.0, 0, 1.0)
		for s2 in [-2.6, 2.6]:
			kit.box(pxf * T(s2, 1.6, 0), Vector3(0.15, 3.2, 0.15), "metal75_gris", 1.0)
		kit.quadz(pxf * T(0, 3.2, 0.05), 6.0, 3.0, "panneau75_lisse")
		kit.col_box(pxf * T(0, 2.4, 0), Vector3(6.0, 4.8, 0.3))
	kit.quadz(xf * T(0, 3.3, 0.04), 7.0, 1.0, "enseigne75_lisse")
	kit.box(xf * T(0, 0.02, 2.4), Vector3(10.0, 0.04, 3.6), "peint75_vert", 1.0)
	for k in range(4):
		kit.place("plante75|blanc", xf * T(-4.0 + k * 2.6, 0.04, 3.8))
	# le stand de vente, devant : une table nappée de gris, des brochures, un parasol « LISSE »
	var st: Transform3D = xf * T(3.0, 0, 2.6)
	kit.box(st * T(0, 0.45, 0), Vector3(1.8, 0.9, 0.8), "tolep75_gris", 1.0)
	kit.col_box(st * T(0, 0.45, 0), Vector3(1.8, 0.9, 0.8))
	for k2 in range(5):
		kit.box(st * T(-0.7 + k2 * 0.35, 0.92, 0.1), Vector3(0.25, 0.02, 0.32), "peint75_blanc", 1.0)
	kit.umbrella(st * T(0.9, 2.4, -0.6), 1.6, 0.3, "blanc")
	kit.cyl(st * T(0.9, 0, -0.6), 0.03, 0.03, 2.4, "chrome75", 6, false)
	bureau_vente = st * Vector3(0, 0.05, 1.2)
	c.objets["bureau_vente"] = bureau_vente
	c._pt("bv_devant", st * Vector3(0, 0.05, 2.2))
	c._pt("bv_derriere", st * Vector3(1.6, 0.05, -1.2))
	c._chain(["bv_devant", "bv_derriere"])
	c._spot("bureau_vente", st * Vector3(0, 0.05, -0.9), xf.basis * Vector3(0, 0, 1), "comptoir", "bv_derriere")
	# Mademoiselle Prune (à côté du stand, son bloc-notes) ; Gédéon (sur le gazon en plastique, il tapote)
	c._spot("bureau_vente_2", st * Vector3(-1.6, 0.05, -0.5), xf.basis * Vector3(0.3, 0, 1).normalized(), "bras_croises", "bv_derriere")
	c._spot("bureau_vente_3", xf * Vector3(-3.0, 0.08, 2.2), xf.basis * Vector3(0, 0, 1), "debout", "bv_devant")
	_street_link("bv_devant")


func rails() -> void:
	var a: Vector3 = c.G(24.0, -156.0, 0.0)
	var b: Vector3 = c.G(24.0, -98.0, 0.0)
	kit.rails75(a, b)
	kit.wagon75(Transform3D(Basis(), c.G(24.0, -122.0, 0.0)), "rouge")
	kit.quadz(Transform3D(Basis(Vector3.UP, PI * 0.5), c.G(25.55, -122.0, 2.3)), 8.0, 2.4, "graffiti75_9")
	c._pt("ra_wagon", c.G(28.4, -118.0))
	c._spot("rails_wagon", c.G(27.2, -116.0), Vector3(-1, 0, 0), "assis", "ra_wagon")
	_street_link("ra_wagon")
	c.animals.append(["rat", c.G(24.0, -126.0, 0.0), 3.0])

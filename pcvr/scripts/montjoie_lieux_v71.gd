extends RefCounted
## V71 : les grands lieux de Montjoie (le reste : montjoie_ville_v71.gd). Chacun bâti par le kit
## de la ville (montjoie_kit_v71), avec ses lieux pour les habitants (spots), ses points et ses
## liens dans le réseau des rues, ses objets (les comptoirs, les invites) :
##  - le Château du Baron (l'enceinte, ses tours, la porte où arrive la rampe, le donjon carré et sa
##    salle du trône, la collection de chapeaux, le jardin) ;
##  - le Temple de l'Aube (la nef, l'autel, la rose, le clocher) ; la Chaumière des Glycines (la
##    maison à vendre : son jardin, sa glycine, son lit, son étagère à trophées) ; le belvédère ;
##  - la Grand-Place du Marché (la fontaine du Fondateur, les étals, l'estrade de la crieuse) et la
##    GUILDE DES AVENTURIERS (le comptoir d'Églantine, le tableau des quêtes, la taverne de Mamie
##    Rissole, la scène du barde, le bureau de Maître Hugues) ;
##  - l'auberge « La Grenouille Repue », la forge de Brunehaut ;
##  - dans la Basse-Ville : le lavoir, la caserne, l'écurie, le puits.

const R = preload("res://scripts/ile_montjoie_v71.gd")

var c                                    # montjoie_ville_v71
var kit
var trone := Vector3.ZERO
var guild_board := Vector3.ZERO          # devant le tableau des quêtes (le lecteur)
var guild_counter := Vector3.ZERO        # devant le comptoir d'Églantine (le client)
var guild_crystal := Vector3.ZERO        # la boule de cristal (l'inscription)
var guild_inside := Vector3.ZERO
var guild_xf := Transform3D.IDENTITY
var chaumiere_door := Vector3.ZERO       # devant la porte de la Chaumière (dehors)
var chaumiere_inside := Vector3.ZERO
var chaumiere_bed := Vector3.ZERO
var chaumiere_shelf: Transform3D         # l'étagère à trophées (+Z : face à la pièce)
var chaumiere_gate: Node3D               # la porte (fermée tant qu'on ne l'a pas achetée)
var crier_bell := Vector3.ZERO           # l'estrade de Mélusine (les alertes)
var castle_gate := ""                    # le point de la porte du château
var _zones: Array = []                   # [nom, Transform3D inverse, demi-taille] : les intérieurs, les places
var _links: Array = []                   # [point, anneau, angle] à relier au réseau des rues


func setup(city) -> void:
	c = city
	kit = city.kit


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func _zone(name: String, xf: Transform3D, center: Vector3, half: Vector3) -> void:
	_zones.append([name, (xf * Transform3D(Basis(), center)).affine_inverse(), half])


func zone_at(p: Vector3) -> String:
	# les intérieurs (posés après les places) d'abord
	for i in range(_zones.size() - 1, -1, -1):
		var z: Array = _zones[i]
		var l: Vector3 = (z[1] as Transform3D) * p
		var h: Vector3 = z[2]
		if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
			return str(z[0])
	return ""


## Un point à relier, plus tard, à la rue en anneau la plus proche.
func _ring_link(pt: String, ring: String, deg: float) -> void:
	_links.append([pt, ring, deg])


func link_graph() -> void:
	for l in _links:
		var near: String = c.nearest_ring(str(l[1]), float(l[2]))
		if near != "":
			c._link(str(l[0]), near)


func castle_link(ramp_top: String) -> void:
	if castle_gate != "":
		c._link(ramp_top, castle_gate)


# =================================================================== le Château

func chateau() -> void:
	var y: float = R.CAST_Y
	var gate_a: float = 170.0
	# l'enceinte : un mur crénelé à r = 35, quatre tours d'angle, la porte (où arrive la rampe)
	var n: int = 40
	for k in range(n):
		var a0: float = 360.0 * k / n
		var a1: float = 360.0 * (k + 1) / n
		if absf(R._adiff((a0 + a1) * 0.5, gate_a)) < 9.0:
			continue
		kit.wall_line(c.PW(a0, 35.2, y - 0.6), c.PW(a1, 35.2, y - 0.6), 7.6, 2.0, "rempart71", true, 1.0, "dalles71")
	for a in [-135.0, -45.0, 45.0, 135.0]:
		kit.tower70(c.PW(a, 35.6, y - 0.6), 3.6, 12.0, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 8.0, "windows": [4.5, 8.5], "nwin": 3, "lit": 0.6, "wall": "rempart71", "trim": "rempart71_sombre"})
	var gx: Transform3D = c.PX(gate_a, 35.2, y, "out")
	kit.arch_gate(gx, 4.6, 5.4, 3.0, 8.4, "rempart71")
	for s in [-1.0, 1.0]:
		kit.tower70(gx * Vector3(s * 5.4, -0.6, 0.0), 2.6, 11.0, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 6.0, "windows": [5.0], "nwin": 2, "lit": 0.6, "wall": "rempart71", "trim": "rempart71_sombre"})
		kit.lamp70(gx * Vector3(s * 3.2, 0, 2.4), 3.6, true, false)
	kit.flag69(gx * T(0, 8.2, 1.6), "banniere71", Vector2(2.4, 1.2))
	castle_gate = c._pt("chateau_porte_pt", gx * Vector3(0, 0.05, -1.0))
	c._pt("chateau_dehors", gx * Vector3(0, 0.05, 3.0))
	c._link(castle_gate, "chateau_dehors")
	c._spot("chateau_porte", gx * Vector3(2.4, 0.05, -2.2), gx.basis * Vector3(-0.3, 0, 1), "bras_croises", castle_gate)
	# le donjon carré : la salle du trône (sa façade regarde la porte)
	var dir: Vector3 = c.radial(gate_a)
	var hx: Transform3D = c.XD(c.PW(gate_a, 9.5, y), dir)
	var hall: Dictionary = kit.hall71(hx, 17.0, 19.0, {"h": 9.0, "wall": "rempart71", "inner": "enduit71_creme", "floor_key": "dalles71",
		"door_w": 2.6, "door_h": 3.6, "roof": "tuiles71_ardoise", "pitch": 55.0, "lights": 3, "energy": 2.0, "front_windows": [-5.0, 5.0],
		"timber": false, "base": "rempart71_sombre"})
	kit.rose_window(hx * T(0, 7.3, 0.03), 1.3, "vitrail71", "dalles71_clair")
	_zone("mj_trone", hx, Vector3(0, 4.5, -9.5), Vector3(8.0, 4.6, 9.0))
	# les tourelles d'angle du donjon, la grande tour (le beffroi) derrière
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -19.0]:
			var tp: Vector3 = hx * Vector3(sx * 8.5, 0, sz)
			kit.tower70(tp, 1.8, 13.5, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 5.5, "windows": [6.0, 10.0], "nwin": 2, "lit": 0.6, "wall": "rempart71", "trim": "rempart71_sombre", "crown": false})
	var keep: Vector3 = kit.tower70(hx * Vector3(5.5, 0, -24.0), 3.4, 24.0, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 11.0, "windows": [8.0, 13.0, 18.0], "nwin": 3, "lit": 0.7, "wall": "rempart71", "trim": "rempart71_sombre"})
	kit.flag69(Transform3D(Basis(), keep + Vector3(0, 11.0, 0)), "banniere71", Vector2(2.2, 1.1))
	# dedans : le tapis, les piliers, l'estrade, le trône, les bannières, les chapeaux du Baron
	kit.box(hx * T(0, 0.12, -8.5), Vector3(2.2, 0.04, 15.0), "tissu71_rouge", 1.0, 4 | 1 | 2 | 16 | 32)
	for s2 in [-1.0, 1.0]:
		for z in [-4.5, -9.5, -14.5]:
			kit.column(hx * T(s2 * 5.4, 0.1, z), 0.4, 8.6, "dalles71_clair", "dalles71")
	kit.box(hx * T(0, 0.3, -16.8), Vector3(7.0, 0.5, 3.6), "dalles71_clair", 1.4)
	kit.col_box(hx * T(0, 0.3, -16.8), Vector3(7.0, 0.5, 3.6))
	var tx: Transform3D = hx * T(0, 0.55, -17.3)
	kit.box(tx * T(0, 0.25, 0), Vector3(1.4, 0.5, 1.0), "or71", 1.0)
	kit.box(tx * T(0, 0.55, 0.05), Vector3(1.2, 0.12, 0.9), "tissu71_bleu", 1.0)
	kit.box(tx * T(0, 1.6, -0.42), Vector3(1.5, 2.6, 0.2), "or71", 1.0)
	kit.box(tx * T(0, 1.5, -0.3), Vector3(1.1, 1.9, 0.04), "tissu71_bleu", 1.0)
	kit.col_box(tx * T(0, 0.8, -0.2), Vector3(1.6, 1.6, 1.3))
	trone = tx * Vector3(0, 0.6, 0.15)
	c._spot("chateau_trone", trone, hx.basis * Vector3(0, 0, 1), "assis", "ch_trone")
	c._pt("ch_trone", hx * Vector3(1.8, 0.05, -14.0))
	c._pt("ch_salle", hx * Vector3(0, 0.05, -6.0))
	c._pt("ch_entree", hx * Vector3(0, 0.05, -1.2))
	c._pt("ch_perron", hx * Vector3(0, 0.05, 2.4))
	c._chain(["ch_trone", "ch_salle", "ch_entree", "ch_perron"])
	for s3 in [-1.0, 1.0]:
		kit.flag69(Transform3D(hx.basis * Basis(Vector3.UP, -s3 * PI * 0.5), hx * Vector3(s3 * 7.9, 6.2, -9.0)), "banniere71", Vector2(1.4, 2.6))
	# la collection de chapeaux du Baron : une étagère et ses têtes de bois, contre le mur de gauche
	var sh: Transform3D = hx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-7.85, 0, -10.0))
	for lv in range(3):
		kit.box(sh * T(0, 1.0 + lv * 0.8, 0.2), Vector3(4.0, 0.06, 0.4), "planches71", 1.0)
		for k2 in range(5):
			var hp: Vector3 = sh * Vector3(-1.6 + k2 * 0.8, 1.15 + lv * 0.8, 0.22)
			kit.ball(Transform3D(Basis(), hp + Vector3.UP * 0.1), 0.12, "planches71_clair", 8, 4)
			var col: String = ["tissu71_rouge", "tissu71_vert", "tissu71_violet", "tissu71_bleu", "tissu71_jaune", "tissu71_brun"][(k2 + lv * 2) % 6]
			match (k2 + lv) % 3:
				0:
					kit.cyl(Transform3D(Basis(), hp + Vector3.UP * 0.18), 0.2, 0.2, 0.03, col, 12)
					kit.cyl(Transform3D(Basis(), hp + Vector3.UP * 0.2), 0.12, 0.11, 0.2, col, 12)
				1:
					kit.cyl(Transform3D(Basis(), hp + Vector3.UP * 0.16), 0.17, 0.0, 0.42, col, 12)
				_:
					kit.cyl(Transform3D(Basis(), hp + Vector3.UP * 0.16), 0.15, 0.13, 0.12, col, 12)
					kit.beam(hp + Vector3(0.05, 0.25, 0), hp + Vector3(0.25, 0.55, -0.05), 0.03, "tissu71_blanc")
	# le bureau de l'intendante (près de la porte, à droite)
	var dx: Transform3D = hx * T(5.0, 0, -4.0)
	kit.box(dx * T(0, 0.75, 0), Vector3(1.8, 0.08, 0.9), "planches71_sombre", 1.0)
	kit.box(dx * T(0, 0.37, 0), Vector3(1.6, 0.74, 0.7), "planches71_sombre", 1.0, 63 - 4)
	kit.col_box(dx * T(0, 0.4, 0), Vector3(1.8, 0.8, 0.9))
	for k3 in range(4):
		kit.box(dx * T(-0.6 + k3 * 0.35, 0.82, 0.1), Vector3(0.3, 0.06, 0.22), "tissu71_blanc", 1.0)
	c._spot("chateau_salon", dx * Vector3(0, 0.05, -0.95), hx.basis * Vector3(0, 0, 1), "scribe", "ch_salle")
	c.doors["porte_barthelemy"] = c._pt("porte_barthelemy", hx * Vector3(-6.2, 0.05, -18.0))
	c.doors["porte_aurore"] = c._pt("porte_aurore", hx * Vector3(6.2, 0.05, -18.0))
	c._link("porte_barthelemy", "ch_trone")
	c._link("porte_aurore", "ch_trone")
	# la cour : un banc, des arbres, le jardin du Baron (sa statue… coiffée d'un chapeau)
	var cour: Vector3 = c.PW(gate_a, 21.0, y)
	c._pt("ch_cour", cour + Vector3.UP * 0.05)
	c._chain(["chateau_dehors", "ch_cour", "ch_perron"])
	c._link(castle_gate, "ch_cour")
	var bxf: Transform3D = c.PX(gate_a + 28.0, 24.0, y, "in")
	kit.bench71(bxf)
	c._spot("chateau_cour", bxf * Vector3(0, 0.45, 0.15), bxf.basis * Vector3(0, 0, 1), "assis", "ch_cour")
	var jx: Transform3D = c.PX(gate_a - 70.0, 25.0, y, "in")
	kit.ring(jx, 3.0, 3.5, 0.5, "dalles71_clair", 24)
	kit.disc(jx * T(0, 0.3, 0), 3.0, "terre71", 20)
	kit.col_cyl(jx.origin, 3.5, 0.55)
	kit.cyl(jx * T(0, 0.3, 0), 0.35, 0.3, 1.6, "dalles71_clair", 10)
	kit.ball(jx * T(0, 2.15, 0), 0.32, "dalles71_clair", 10, 6)
	kit.cyl(jx * T(0, 2.4, 0), 0.5, 0.5, 0.04, "tissu71_violet", 14)
	kit.cyl(jx * T(0, 2.42, 0), 0.3, 0.27, 0.36, "tissu71_violet", 14)
	for k4 in range(5):
		var a4: float = TAU * k4 / 5.0
		c.tree_spots.append(jx * Vector3(cos(a4) * 7.0, 0, sin(a4) * 5.0))
	c._pt("ch_jardin", jx * Vector3(0, 0.05, 4.4))
	c._spot("chateau_jardin", jx * Vector3(1.2, 0.05, 4.0), jx.basis * Vector3(0, 0, -1), "jardiner", "ch_jardin")
	c._link("ch_jardin", "ch_cour")
	c._pt("ch_mur", c.PW(gate_a + 80.0, 31.5, y + 0.05))
	c._spot("chateau_rempart", c.PW(gate_a + 80.0, 32.6, y + 0.05), c.radial(gate_a + 80.0), "observer", "ch_mur")
	c._link("ch_mur", "ch_cour")
	c._avoid(c.PW(0, 0, 0), 30.0)


# =================================================================== le Temple de l'Aube

func temple() -> void:
	var y: float = R.HAUTE_Y
	var a: float = 71.0
	var fx: Transform3D = c.PX(a, 50.6, y, "in")
	var hall: Dictionary = kit.hall71(fx, 13.0, 19.0, {"h": 9.5, "wall": "dalles71_clair", "inner": "enduit71_blanc", "floor_key": "dalles71",
		"door_w": 2.4, "door_h": 3.6, "roof": "tuiles71_ardoise", "pitch": 56.0, "lights": 2, "energy": 1.8, "timber": false,
		"windows": false, "base": "rempart71", "light_color": Color(1.0, 0.86, 0.62)})
	kit.rose_window(fx * T(0, 7.0, 0.03), 1.6, "vitrail71", "dalles71")
	kit.rose_window(Transform3D(fx.basis * Basis(Vector3.UP, PI), fx * Vector3(0, 7.0, -19.0 - 0.03)), 1.6, "vitrail71", "dalles71")
	for s in [-1.0, 1.0]:
		for k in range(3):
			var wz: float = -4.5 - k * 5.0
			var ox: Transform3D = fx * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 6.5, 3.4, wz))
			kit.ogive_face(ox * T(0, 0, 0.03), 1.1, 3.2, "vitrail71", 4)
			kit.ogive_frame(ox, 1.1, 3.2, 0.2, 0.2, "dalles71", 4)
			var ix: Transform3D = fx * Transform3D(Basis(Vector3.UP, -s * PI * 0.5), Vector3(s * (6.5 - 0.61), 3.4, wz))
			kit.ogive_face(ix, 1.1, 3.2, "vitrailin71", 4)
			kit.buttress(fx * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 6.5, 0, wz - 2.5)), 8.0, 1.2, 0.8, "dalles71_clair", false)
	_zone("mj_temple", fx, Vector3(0, 4.5, -9.5), Vector3(5.9, 4.8, 9.0))
	# le clocher, à droite de la façade
	var bt: Vector3 = kit.tower70(fx * Vector3(8.6, 0, -3.0), 2.6, 17.0, {"roof": "spire", "roof_key": "tuiles71_ardoise", "roof_h": 10.0, "windows": [6.0, 11.5], "nwin": 3, "lit": 0.5, "wall": "dalles71_clair", "trim": "dalles71"})
	# dedans : l'autel du soleil levant, les bancs
	var ax: Transform3D = fx * T(0, 0, -17.0)
	kit.box(ax * T(0, 0.25, 0), Vector3(5.0, 0.5, 2.6), "dalles71_clair", 1.0)
	kit.col_box(ax * T(0, 0.25, 0), Vector3(5.0, 0.5, 2.6))
	kit.box(ax * T(0, 1.0, -0.2), Vector3(2.2, 1.0, 0.9), "dalles71_clair", 1.0)
	kit.col_box(ax * T(0, 1.0, -0.2), Vector3(2.2, 1.0, 0.9))
	kit.box(ax * T(0, 1.52, -0.2), Vector3(2.4, 0.06, 1.0), "tissu71_blanc", 1.0)
	kit.ring(Transform3D(fx.basis * Basis(Vector3.RIGHT, PI * 0.5), fx * Vector3(0, 4.5, -18.3)), 1.2, 1.5, 0.12, "or71", 24)
	kit.disc(Transform3D(fx.basis * Basis(Vector3.RIGHT, PI * 0.5), fx * Vector3(0, 4.5, -18.36)), 1.2, "or71", 24)
	for s2 in [-1.0, 1.0]:
		var cp: Vector3 = ax * Vector3(s2 * 1.7, 1.55, -0.2)
		kit.cyl(Transform3D(Basis(), cp), 0.05, 0.05, 0.3, "fleur71_blanc", 8)
		kit.cyl(Transform3D(Basis(), cp + Vector3.UP * 0.3), 0.02, 0.0, 0.08, "orage71", 4)
	var seats: Array = []
	for row in range(5):
		for s3 in [-1.0, 1.0]:
			var bxf: Transform3D = fx * T(s3 * 2.7, 0, -4.0 - row * 2.2)
			kit.box(bxf * T(0, 0.45, 0), Vector3(3.2, 0.07, 0.42), "planches71", 1.0)
			kit.box(bxf * T(0, 0.85, 0.24), Vector3(3.2, 0.5, 0.06), "planches71", 1.0)
			kit.col_box(bxf * T(0, 0.45, 0), Vector3(3.2, 0.9, 0.5))
			seats.append(bxf * Vector3(s3 * -0.6, 0.45, -0.05))
	c._pt("tp_entree", fx * Vector3(0, 0.05, -1.5))
	c._pt("tp_nef", fx * Vector3(0, 0.05, -10.0))
	c._pt("tp_choeur", fx * Vector3(0, 0.05, -14.5))
	c._pt("tp_parvis", fx * Vector3(0, 0.05, 3.0))
	c._chain(["tp_parvis", "tp_entree", "tp_nef", "tp_choeur"])
	_ring_link("tp_parvis", "hi", a)
	c._spot("temple_autel", ax * Vector3(0, 0.55, 0.9), fx.basis * Vector3(0, 0, 1), "prier", "tp_choeur")
	c._spot("temple_banc_1", seats[2], fx.basis * Vector3(0, 0, -1), "assis", "tp_nef")
	c._spot("temple_banc_2", seats[5], fx.basis * Vector3(0, 0, -1), "prier", "tp_nef")
	c._spot("temple_parvis", fx * Vector3(-2.6, 0.05, 2.6), fx.basis * Vector3(0.3, 0, 1), "debout", "tp_parvis")
	c.doors["porte_clotaire"] = c._pt("porte_clotaire", fx * Vector3(4.6, 0.05, -18.0))
	c._link("porte_clotaire", "tp_choeur")
	c._avoid(fx * Vector3(0, 0, -9.0), 13.0)


# =================================================================== la Chaumière des Glycines

func chaumiere() -> void:
	var y: float = R.HAUTE_Y
	var a: float = 149.0
	var fx: Transform3D = c.PX(a, 58.0, y, "in")
	var hall: Dictionary = kit.hall71(fx, 9.0, 7.6, {"h": 3.3, "wall": "enduit71_blanc", "inner": "enduit71_creme", "floor_key": "planches71",
		"door_w": 1.3, "door_h": 2.4, "door_x": -1.6, "roof": "chaume71", "pitch": 50.0, "gable_front": false, "lights": 1, "energy": 1.4,
		"front_windows": [1.8], "volet": "bleu", "base": "moellons71"})
	chaumiere_door = fx * Vector3(-1.6, 0.05, 1.4)
	chaumiere_inside = fx * Vector3(0.6, 0.05, -3.8)
	_zone("mj_chaumiere", fx, Vector3(0, 1.8, -3.8), Vector3(4.1, 2.0, 3.4))
	# la porte (fermée à clé tant que la maison n'est pas à nous) : un vantail et sa collision
	chaumiere_gate = Node3D.new()
	chaumiere_gate.name = "Porte_chaumiere"
	kit.root.add_child(chaumiere_gate)
	chaumiere_gate.transform = fx * T(-1.6, 1.2, -0.3)
	var dm := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.3, 2.4, 0.08)
	dm.mesh = bm
	dm.material_override = kit.mat("volet71_bleu")
	chaumiere_gate.add_child(dm)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.3, 2.4, 0.3)
	cs.shape = bs
	sb.add_child(cs)
	chaumiere_gate.add_child(sb)
	# dedans : le lit, la table, la cheminée, l'étagère à trophées
	var bx: Transform3D = fx * T(-3.0, 0, -5.6)
	kit.box(bx * T(0, 0.3, 0), Vector3(1.6, 0.4, 2.2), "planches71_sombre", 1.0)
	kit.box(bx * T(0, 0.55, 0.1), Vector3(1.5, 0.14, 1.9), "tissu71_bleu", 1.0)
	kit.box(bx * T(0, 0.6, -0.85), Vector3(1.3, 0.16, 0.4), "tissu71_blanc", 1.0)
	kit.box(bx * T(0, 0.75, -1.08), Vector3(1.6, 1.1, 0.08), "planches71_sombre", 1.0)
	kit.col_box(bx * T(0, 0.35, 0), Vector3(1.6, 0.7, 2.2))
	chaumiere_bed = bx * Vector3(0, 0.7, 0.0)
	kit.tavern_table71(fx * T(1.6, 0, -2.6), 1.5)
	var hearth: Transform3D = fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(4.15, 0, -4.8))
	kit.box(hearth * T(0, 0.8, -0.2), Vector3(1.6, 1.6, 0.5), "moellons71", 1.0)
	kit.box(hearth * T(0, 0.5, 0.05), Vector3(1.0, 0.8, 0.1), "terre71", 1.0)
	kit.fires70.append([hearth * Vector3(0, 0.3, 0.1), 0.35])
	chaumiere_shelf = fx * Transform3D(Basis(Vector3.UP, PI), Vector3(1.4, 0, -7.0))
	for lv in range(2):
		kit.box(chaumiere_shelf * T(0, 1.1 + lv * 0.7, 0.18), Vector3(2.6, 0.06, 0.34), "planches71", 1.0)
	# le jardin : la clôture, la glycine sur sa pergola, des massifs, la pancarte « À vendre »
	for s in [-1.0, 1.0]:
		kit.fence71(fx * Vector3(s * 6.4, 0, 2.4), fx * Vector3(s * 6.4, 0, -8.6))
	kit.fence71(fx * Vector3(-6.4, 0, -8.6), fx * Vector3(6.4, 0, -8.6))
	kit.fence71(fx * Vector3(1.2, 0, 2.4), fx * Vector3(6.4, 0, 2.4))
	var pg: Transform3D = fx * T(-1.6, 0, 1.6)
	for sx in [-1.0, 1.0]:
		for sz in [0.6, -0.6]:
			kit.box(pg * T(sx * 1.0, 1.25, sz), Vector3(0.12, 2.5, 0.12), "poutre71_clair", 1.0)
	for k in range(5):
		kit.box(pg * T(0, 2.5, -0.8 + k * 0.4), Vector3(2.4, 0.08, 0.08), "poutre71_clair", 1.0)
		for j in range(4):
			var fp: Vector3 = pg * Vector3(-0.9 + j * 0.6, 2.3 - (j % 2) * 0.12, -0.8 + k * 0.4)
			kit.cyl(Transform3D(Basis(), fp + Vector3.DOWN * 0.45), 0.07, 0.11, 0.45, "fleur71_violet", 6)
	var sign_xf: Transform3D = fx * T(4.0, 0, 3.0)
	kit.box(sign_xf * T(0, 0.6, 0), Vector3(0.1, 1.2, 0.1), "poutre71", 1.0)
	kit.box(sign_xf * T(0, 1.3, 0.04), Vector3(1.2, 0.7, 0.05), "planches71_clair", 1.0)
	kit.quadz(sign_xf * T(0, 1.3, 0.07), 1.0, 0.56, "enseigne71_agence")
	c.objets["chaumiere_pancarte"] = sign_xf * Vector3(0, 0.05, 1.0)
	for k2 in range(6):
		c.tree_spots.append(fx * Vector3(-5.0 + k2 * 2.0, 0, 5.2) if k2 % 2 == 0 else fx * Vector3(-5.5 + k2 * 2.0, 0, -9.6))
	c._pt("chaum_jardin", fx * Vector3(-1.6, 0.05, 3.6))
	_ring_link("chaum_jardin", "hi", a)
	c._spot("chaumiere_jardin", fx * Vector3(2.6, 0.05, 1.8), fx.basis * Vector3(-0.6, 0, 1), "debout", "chaum_jardin")
	c._avoid(fx * Vector3(0, 0, -3.0), 9.0)


func belvedere() -> void:
	var y: float = R.HAUTE_Y
	var a: float = 111.0
	var bx: Transform3D = c.PX(a, 70.5, y, "out")
	kit.box(bx * T(0, 0.08, -2.0), Vector3(12.0, 0.16, 7.0), "dalles71_clair", 2.0, 4)
	for k in range(9):
		kit.cyl(bx * T(-5.6 + k * 1.4, 0.16, 2.6), 0.12, 0.09, 0.85, "dalles71_clair", 8)
	kit.box(bx * T(0, 1.05, 2.6), Vector3(12.0, 0.14, 0.4), "dalles71_clair", 1.0)
	var lunette: Transform3D = bx * T(3.0, 0, 1.4)
	kit.cyl(lunette, 0.08, 0.08, 1.2, "laiton71", 8)
	kit.cyl(Transform3D(lunette.basis * Basis(Vector3.RIGHT, -1.2), lunette * Vector3(0, 1.25, -0.2)), 0.07, 0.11, 0.9, "laiton71", 10)
	kit.bench71(bx * Transform3D(Basis(Vector3.UP, PI), Vector3(-2.5, 0, -1.2)) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO))
	c._pt("belv_pt", bx * Vector3(0, 0.05, -2.0))
	_ring_link("belv_pt", "ho", a)
	c._spot("haute_belvedere", bx * Vector3(3.0, 0.05, 0.8), bx.basis * Vector3(0, 0, 1), "observer", "belv_pt")
	c._spot("haute_banc", bx * Vector3(-2.5, 0.45, -1.0), bx.basis * Vector3(0, 0, 1), "assis", "belv_pt")


# =================================================================== la Grand-Place, la Guilde

func grand_place() -> void:
	var y: float = R.MOY_Y
	var fa: float = 45.0
	var fr: float = 97.0
	var fc: Vector3 = c.PW(fa, fr, y)
	kit.fountain71(Transform3D(Basis(), fc), 3.8)
	c._avoid(fc, 6.0)
	c._pt("pl_fontaine", fc + c.radial(fa) * 6.0 + Vector3.UP * 0.05)
	c._pt("pl_nord", c.PW(fa, fr - 10.0, y + 0.05))
	c._pt("pl_sud", c.PW(fa, fr + 11.0, y + 0.05))
	c._pt("pl_est", c.PW(fa + 8.0, fr, y + 0.05))
	c._pt("pl_ouest", c.PW(fa - 7.0, fr, y + 0.05))
	c._chain(["pl_ouest", "pl_nord", "pl_est", "pl_sud", "pl_ouest"])
	c._link("pl_fontaine", "pl_sud")
	c._link("pl_fontaine", "pl_est")
	_ring_link("pl_nord", "mi", fa)
	_ring_link("pl_sud", "mo", fa)
	_ring_link("pl_est", "mi", fa + 15.0)
	_ring_link("pl_est", "mo", fa + 15.0)
	c._spot("place_fontaine", fc + c.radial(fa) * 4.3 + c.tangent(fa) * 1.2 + Vector3.UP * 0.05, -c.radial(fa), "debout", "pl_fontaine")
	# les bancs autour de la fontaine
	var b1: Transform3D = c.XD(fc + c.tangent(fa) * 6.5, -c.tangent(fa))
	kit.bench71(b1)
	c._spot("place_banc_1", b1 * Vector3(0, 0.45, 0.15), b1.basis * Vector3(0, 0, 1), "assis", "pl_est")
	var b2: Transform3D = c.XD(fc - c.radial(fa) * 6.5, c.radial(fa))
	kit.bench71(b2)
	c._spot("place_banc_2", b2 * Vector3(0, 0.45, 0.15), b2.basis * Vector3(0, 0, 1), "assis", "pl_nord")
	# l'estrade de la crieuse : quelques marches, sa grosse cloche sur un portique
	var ex: Transform3D = c.XD(c.PW(fa + 10.0, fr - 8.0, y), -c.tangent(fa))
	kit.box(ex * T(0, 0.3, 0), Vector3(2.6, 0.6, 2.0), "planches71", 1.0)
	kit.col_box(ex * T(0, 0.3, 0), Vector3(2.6, 0.6, 2.0))
	kit.box(ex * T(0, 0.15, 1.25), Vector3(1.2, 0.3, 0.5), "planches71", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(ex * T(s * 1.1, 1.8, -0.8), Vector3(0.12, 2.4, 0.12), "poutre71", 1.0)
	kit.box(ex * T(0, 3.0, -0.8), Vector3(2.4, 0.14, 0.14), "poutre71", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI), ex * Vector3(0, 2.92, -0.8)), 0.18, 0.34, 0.5, "laiton71", 14)
	crier_bell = ex * Vector3(0, 2.6, -0.8)
	c._spot("place_crieur", ex * Vector3(0, 0.65, 0.2), ex.basis * Vector3(0, 0, 1), "acclamer", "pl_est")
	# les étals du marché (fruits et légumes de Babette, et d'autres)
	var colors := ["vert", "rouge", "jaune", "bleu", "orange"]
	var stalls := [[fa - 9.0, fr + 9.0], [fa - 4.0, fr + 12.0], [fa + 2.0, fr + 13.0], [fa + 8.0, fr + 11.0], [fa + 12.0, fr + 4.0]]
	for i in range(stalls.size()):
		var sa: float = float(stalls[i][0])
		var sr: float = float(stalls[i][1])
		var sx: Transform3D = c.XD(c.PW(sa, sr, y), (fc - c.PW(sa, sr, y)))
		kit.stall71(sx, 2.6, 1.3, colors[i])
		c._avoid(sx.origin, 3.0)
		if i == 0:
			c._pt("pl_etal", sx * Vector3(1.8, 0.05, -0.6))
			c._link("pl_etal", "pl_ouest")
			c._spot("marche_fruits", sx * Vector3(0, 0.05, -1.95), sx.basis * Vector3(0, 0, 1), "comptoir", "pl_etal")
			c.objets["etal_babette"] = sx * Vector3(0, 0.05, 1.2)
	c._spot("marche_flane_1", c.PW(fa - 2.0, fr + 8.0, y + 0.05), c.radial(fa), "observer", "pl_sud")
	c._spot("marche_flane_2", c.PW(fa + 6.0, fr + 7.0, y + 0.05), c.radial(fa), "observer", "pl_sud")
	c._spot("place_jeu_1", c.PW(fa + 6.0, fr - 3.0, y + 0.05), c.tangent(fa), "jouer", "pl_est")
	c._spot("place_jeu_2", c.PW(fa + 7.5, fr - 1.5, y + 0.05), -c.tangent(fa), "jouer", "pl_est")
	c._spot("place_musique", c.PW(fa - 5.0, fr - 9.0, y + 0.05), c.radial(fa), "violon", "pl_nord")
	# des arbres en bacs, des réverbères
	for k in range(6):
		var ta: float = fa - 14.0 + k * 5.5
		c.tree_spots.append(c.PW(ta, 79.5, y))
	for k2 in range(5):
		kit.lamp70(c.PW(fa - 12.0 + k2 * 6.0, 115.4, y), 3.9, true, false)
	_zone_place(fa, fr)


func _zone_place(fa: float, fr: float) -> void:
	var zx: Transform3D = c.XD(c.PW(fa, fr, R.MOY_Y), c.radial(fa))
	_zone("mj_place", zx, Vector3(0, 4.0, 0), Vector3(30.0, 6.0, 20.0))


func guilde() -> void:
	var y: float = R.MOY_Y
	var a: float = 34.0
	var r: float = 97.5
	var fx: Transform3D = c.PX(a, r, y, "cw")
	guild_xf = fx
	var w: float = 24.0
	var d: float = 21.0
	var hall: Dictionary = kit.hall71(fx, w, d, {"h": 8.0, "wall": "enduit71_creme", "inner": "enduit71_ocre", "floor_key": "planches71",
		"door_w": 2.8, "door_h": 3.4, "roof": "tuiles71_rouge", "pitch": 46.0, "gable_front": false, "lights": 4, "energy": 3.2,
		"front_windows": [-8.0, -4.6, 4.6, 8.0], "volet": "vert", "base": "moellons71", "light_color": Color(1.0, 0.7, 0.4)})
	guild_inside = fx * Vector3(0, 0.05, -d * 0.5)
	_zone("mj_guilde", fx, Vector3(0, 4.0, -d * 0.5), Vector3(w * 0.5 - 0.6, 4.2, d * 0.5 - 0.5))
	# la façade : l'étage (de grandes fenêtres), l'enseigne, le blason, les bannières, l'auvent
	for k in range(6):
		kit.window71(fx * T(-10.0 + k * 4.0, 5.8, 0.0), "vert", true)
	kit.box(fx * T(0, 4.15, 0.25), Vector3(w + 0.2, 0.3, 0.5), "poutre71", 1.0)
	kit.box(fx * T(0, 4.3, 0.06), Vector3(6.2, 1.9, 0.1), "poutre71", 1.0)
	kit.quadz(fx * T(0, 4.3, 0.12), 6.0, 1.7, "enseigne71_guilde")
	kit.quadz(fx * T(0, 6.7, 0.06), 2.0, 2.0, "blason71")
	for s in [-1.0, 1.0]:
		kit.flag69(fx * T(s * 5.5, 7.4, 0.3) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), "banniere71", Vector2(2.6, 1.0))
		kit.lamp70(fx * Vector3(s * 3.0, 0, 2.6), 3.8, true, false)
		kit.barrel71(fx * Vector3(s * 6.0, 0, 0.8))
	# dedans : le comptoir d'Églantine (et la boule de cristal), le tableau des quêtes
	var cx: Transform3D = fx * T(-6.5, 0, -14.0)
	var keeper: Vector3 = kit.counter71(cx, 4.2, "planches71_clair")
	guild_counter = cx * Vector3(0, 0.05, 1.1)
	guild_crystal = cx * Vector3(1.4, 1.35, -0.35)
	kit.cyl(Transform3D(Basis(), cx * Vector3(1.4, 1.16, -0.35)), 0.16, 0.12, 0.08, "laiton71", 10)
	kit.ball(Transform3D(Basis(), guild_crystal), 0.2, "cristal71", 14, 8)
	kit.box(cx * T(-1.2, 1.2, -0.4), Vector3(0.6, 0.12, 0.4), "tissu71_blanc", 1.0)
	kit.box(cx * T(-0.5, 1.2, -0.3), Vector3(0.12, 0.1, 0.12), "laiton71", 1.0)
	c._pt("gu_comptoir", cx * Vector3(0, 0.05, 2.2))
	c._spot("guilde_comptoir", keeper + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "gu_comptoir_derriere")
	c._pt("gu_comptoir_derriere", cx * Vector3(2.8, 0.05, -1.2))
	var qb: Transform3D = fx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-w * 0.5 + 0.7, 0, -7.0))
	guild_board = kit.quest_board71(qb, 3.4, 2.0)
	c._pt("gu_tableau", guild_board + Vector3.UP * 0.05)
	c._spot("guilde_tableau", guild_board + qb.basis * Vector3(0.9, 0.05, 0.1), qb.basis * Vector3(0, 0, -1), "lire", "gu_tableau")
	c.objets["guilde_tableau"] = guild_board
	c.objets["guilde_comptoir"] = guild_counter
	# la taverne de Mamie Rissole : son bar, ses tonneaux, ses étagères
	var bx: Transform3D = fx * T(6.5, 0, -16.5)
	var cook: Vector3 = kit.counter71(bx, 5.0, "planches71")
	for k2 in range(4):
		kit.barrel71(bx * Vector3(-2.0 + k2 * 1.3, 0, -3.4))
	for lv in range(3):
		kit.box(bx * T(0, 1.6 + lv * 0.6, -3.95), Vector3(5.0, 0.06, 0.3), "planches71", 1.0)
		for k3 in range(8):
			kit.cyl(bx * T(-2.2 + k3 * 0.6, 1.63 + lv * 0.6, -3.95), 0.06, 0.06, 0.2, "planches71_clair" if k3 % 2 == 0 else "laiton71", 8)
	c._pt("gu_bar", bx * Vector3(0, 0.05, 1.8))
	c._pt("gu_bar_derriere", bx * Vector3(3.2, 0.05, -1.4))
	c._spot("guilde_bar", cook + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "gu_bar_derriere")
	c.objets["guilde_bar"] = bx * Vector3(0, 0.05, 1.1)
	# la scène du barde (à droite), le bureau de Maître Hugues (au fond, sous le blason)
	var sx: Transform3D = fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(w * 0.5 - 2.2, 0, -7.0))
	kit.box(sx * T(0, 0.2, 0), Vector3(4.0, 0.4, 3.0), "planches71_sombre", 1.0)
	kit.col_box(sx * T(0, 0.2, 0), Vector3(4.0, 0.4, 3.0))
	c._pt("gu_scene", sx * Vector3(1.8, 0.05, 2.0))
	c._spot("guilde_scene", sx * Vector3(0, 0.45, 0.2), sx.basis * Vector3(0, 0, 1), "violon", "gu_scene")
	var dx: Transform3D = fx * T(0.5, 0, -19.0)
	kit.box(dx * T(0, 0.8, 0), Vector3(2.6, 0.08, 1.2), "planches71_sombre", 1.0)
	kit.box(dx * T(0, 0.4, 0), Vector3(2.4, 0.8, 1.0), "planches71_sombre", 1.0, 63 - 4)
	kit.col_box(dx * T(0, 0.42, 0), Vector3(2.6, 0.84, 1.2))
	kit.box(dx * T(0, 0.5, -1.0), Vector3(0.9, 0.08, 0.8), "cuir71", 1.0)
	kit.box(dx * T(0, 1.2, -1.35), Vector3(0.9, 1.4, 0.12), "cuir71", 1.0)
	kit.quadz(fx * T(0.5, 4.6, -d + 0.66), 2.4, 2.4, "blason71")
	# une hache géante au mur (« celle du dragon », dit Hugues)
	kit.beam(fx * Vector3(-2.5, 2.4, -d + 0.7), fx * Vector3(-1.0, 4.4, -d + 0.7), 0.08, "poutre71")
	kit.box(fx * T(-1.0, 4.2, -d + 0.68), Vector3(0.9, 0.7, 0.05), "fer71", 1.0)
	c._pt("gu_maitre", dx * Vector3(1.8, 0.05, 0.4))
	c._spot("guilde_maitre", dx * Vector3(0, 0.5, -0.95), fx.basis * Vector3(0, 0, 1), "assis", "gu_maitre")
	# la cheminée (contre le mur de gauche, au fond)
	var hx: Transform3D = fx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-w * 0.5 + 0.65, 0, -17.5))
	kit.box(hx * T(0, 1.4, -0.3), Vector3(2.4, 2.8, 0.8), "moellons71", 1.0)
	kit.box(hx * T(0, 0.6, 0.12), Vector3(1.4, 1.0, 0.1), "terre71", 1.0)
	kit.col_box(hx * T(0, 1.4, -0.3), Vector3(2.4, 2.8, 0.8))
	kit.fires70.append([hx * Vector3(0, 0.35, 0.25), 0.45])
	# les tables (deux places chacune)
	var tables := [Vector3(-6.0, 0, -4.5), Vector3(-0.5, 0, -4.5), Vector3(4.8, 0, -4.5), Vector3(-3.5, 0, -9.8), Vector3(2.0, 0, -9.8), Vector3(-0.8, 0, -14.6)]
	for i in range(tables.size()):
		var txf: Transform3D = fx * Transform3D(Basis(), tables[i])
		var seats: Array = kit.tavern_table71(txf, 2.2)
		var tp: String = c._pt("gu_table_%d" % (i + 1), txf * Vector3(1.6, 0.05, 1.5))
		c._spot("guilde_table_%d" % (i + 1), (seats[0] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, -1), "boire" if i % 2 == 0 else "assis", tp)
	# le réseau : l'entrée, la salle, le comptoir, le bar, la scène, le bureau, les tables
	c._pt("gu_entree", fx * Vector3(0, 0.05, -1.5))
	c._pt("gu_salle", fx * Vector3(0, 0.05, -7.2))
	c._pt("gu_fond", fx * Vector3(1.5, 0.05, -12.5))
	c._pt("gu_dehors", fx * Vector3(0, 0.05, 3.2))
	c._chain(["gu_dehors", "gu_entree", "gu_salle", "gu_fond", "gu_maitre"])
	c._chain(["gu_salle", "gu_tableau"])
	c._chain(["gu_fond", "gu_comptoir", "gu_comptoir_derriere"])
	c._chain(["gu_fond", "gu_bar", "gu_bar_derriere"])
	c._chain(["gu_salle", "gu_scene"])
	for i2 in range(tables.size()):
		c._link("gu_table_%d" % (i2 + 1), "gu_salle" if i2 < 3 else "gu_fond")
	c._link("gu_dehors", "pl_ouest")
	_ring_link("gu_dehors", "mi", a + 4.0)
	c.doors["porte_hugues"] = c._pt("porte_hugues", fx * Vector3(-3.0, 0.05, -d + 1.2))
	c.doors["porte_rissole"] = c._pt("porte_rissole", fx * Vector3(9.5, 0.05, -d + 1.2))
	c._link("porte_hugues", "gu_maitre")
	c._link("porte_rissole", "gu_bar_derriere")
	c._avoid(fx * Vector3(0, 0, -d * 0.5), 15.0)


# =================================================================== l'auberge, la forge

func auberge() -> void:
	var y: float = R.MOY_Y
	var a: float = 94.0
	var fx: Transform3D = c.PX(a, 110.5, y, "out")
	var w: float = 15.0
	var d: float = 17.0
	kit.hall71(fx, w, d, {"h": 6.4, "wall": "enduit71_ocre", "inner": "enduit71_creme", "floor_key": "planches71", "door_w": 2.0, "door_h": 2.8,
		"roof": "tuiles71_brun", "pitch": 50.0, "lights": 2, "energy": 1.8, "front_windows": [-4.5, 4.5], "volet": "rouge", "base": "moellons71"})
	_zone("mj_auberge", fx, Vector3(0, 3.2, -d * 0.5), Vector3(w * 0.5 - 0.6, 3.4, d * 0.5 - 0.5))
	kit.shop_sign71(fx * T(-2.0, 3.6, 0.0), "auberge", 1.2, 1.2)
	for k in range(4):
		kit.window71(fx * T(-5.4 + k * 3.6, 4.7, 0.0), "rouge", true, true)
	var cx: Transform3D = fx * T(-3.5, 0, -12.5)
	var keeper: Vector3 = kit.counter71(cx, 4.0)
	for k2 in range(3):
		kit.barrel71(cx * Vector3(-1.4 + k2 * 1.4, 0, -2.8))
	c._pt("au_comptoir", cx * Vector3(0, 0.05, 1.8))
	c._pt("au_derriere", cx * Vector3(2.6, 0.05, -1.3))
	c._spot("auberge_comptoir", keeper + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "au_derriere")
	c.objets["auberge_comptoir"] = cx * Vector3(0, 0.05, 1.1)
	var t1: Array = kit.tavern_table71(fx * T(2.5, 0, -5.0), 2.2)
	var t2: Array = kit.tavern_table71(fx * T(-3.0, 0, -5.5), 2.2)
	kit.tavern_table71(fx * T(3.5, 0, -11.0), 2.2)
	c._pt("au_salle", fx * Vector3(0, 0.05, -8.0))
	c._pt("au_entree", fx * Vector3(0, 0.05, -1.4))
	c._pt("au_dehors", fx * Vector3(0, 0.05, 3.0))
	c._chain(["au_dehors", "au_entree", "au_salle", "au_comptoir", "au_derriere"])
	c._spot("auberge_table_1", (t1[0] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, -1), "boire", "au_salle")
	c._spot("auberge_table_2", (t2[0] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, -1), "assis", "au_salle")
	var hx: Transform3D = fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(w * 0.5 - 0.65, 0, -8.5))
	kit.box(hx * T(0, 1.2, -0.3), Vector3(2.2, 2.4, 0.8), "moellons71", 1.0)
	kit.col_box(hx * T(0, 1.2, -0.3), Vector3(2.2, 2.4, 0.8))
	kit.fires70.append([hx * Vector3(0, 0.35, 0.2), 0.45])
	_ring_link("au_dehors", "mo", a)
	c.doors["porte_ulric"] = c._pt("porte_ulric", fx * Vector3(-5.5, 0.05, -15.5))
	c._link("porte_ulric", "au_derriere")
	c._avoid(fx * Vector3(0, 0, -d * 0.5), 11.0)


func forge() -> void:
	var y: float = R.MOY_Y
	var a: float = -25.5
	var fx: Transform3D = c.PX(a, 112.0, y, "out")
	# l'appentis : un toit sur des poteaux, ouvert sur la rue
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -7.0]:
			kit.box(fx * T(sx * 4.8, 1.9, sz - 0.5), Vector3(0.3, 3.8, 0.3), "poutre71", 1.0)
	kit.roof_gable(fx * T(0, 3.8, -4.0), 10.6, 8.6, 30.0, 0.3, "tuiles71_brun", "planches71")
	kit.box(fx * T(0, 1.9, -7.8), Vector3(9.6, 3.8, 0.4), "moellons71", 1.6)
	kit.col_box(fx * T(0, 1.9, -7.8), Vector3(9.6, 3.8, 0.4))
	# le foyer, son soufflet, l'enclume, la cuve, le râtelier d'armes
	var fo: Transform3D = fx * T(-2.8, 0, -6.4)
	kit.box(fo * T(0, 0.5, 0), Vector3(2.0, 1.0, 1.6), "moellons71", 1.0)
	kit.col_box(fo * T(0, 0.5, 0), Vector3(2.0, 1.0, 1.6))
	kit.box(fo * T(0, 1.02, 0.1), Vector3(1.2, 0.06, 0.9), "terre71", 1.0)
	kit.cyl(fo * T(0, 1.05, -0.5), 0.7, 0.4, 2.6, "moellons71_sombre", 4)
	kit.fires70.append([fo * Vector3(0, 1.15, 0.1), 0.45])
	var an: Transform3D = fx * T(0.4, 0, -3.6)
	kit.cyl(an, 0.3, 0.26, 0.6, "poutre71", 8)
	kit.box(an * T(0, 0.75, 0), Vector3(0.9, 0.3, 0.3), "fer71", 1.0)
	kit.col_box(an * T(0, 0.45, 0), Vector3(0.9, 0.9, 0.4))
	kit.box(fx * T(3.4, 0.45, -5.6), Vector3(1.4, 0.9, 0.8), "planches71_sombre", 1.0)
	kit.disc(fx * T(3.4, 0.86, -5.6), 0.5, "eau71", 10)
	var rack: Transform3D = fx * T(3.4, 0, -7.4)
	kit.box(rack * T(0, 1.3, 0), Vector3(2.4, 0.1, 0.2), "poutre71", 1.0)
	for k in range(5):
		kit.beam(rack * Vector3(-1.0 + k * 0.5, 0.2, 0.1), rack * Vector3(-1.0 + k * 0.5, 1.6, 0.1), 0.04, "fer71")
	kit.counter71(fx * T(-3.0, 0, -0.4), 2.2, "planches71")
	kit.shop_sign71(fx * T(4.8, 3.0, 0.0), "forge", 1.0, 1.0)
	c._pt("fo_rue", fx * Vector3(0, 0.05, 2.2))
	c._pt("fo_dedans", fx * Vector3(1.5, 0.05, -2.0))
	c._chain(["fo_rue", "fo_dedans"])
	_ring_link("fo_rue", "mo", a)
	c._spot("forge_enclume", an * Vector3(0, 0.05, 1.0), fx.basis * Vector3(0, 0, -1), "forger", "fo_dedans")
	c._spot("forge_comptoir", fx * Vector3(-3.0, 0.05, -1.7), fx.basis * Vector3(0, 0, 1), "comptoir", "fo_dedans")
	c.objets["forge_comptoir"] = fx * Vector3(-3.0, 0.05, 1.0)
	c.smoke_spots.append(fo * Vector3(0, 3.8, -0.5))
	c._avoid(fx * Vector3(0, 0, -4.0), 7.0)


# =================================================================== la Basse-Ville

func lavoir() -> void:
	var y: float = R.BASSE_Y
	var a: float = 148.0
	var lx: Transform3D = c.PX(a, 140.0, y, "cw")
	kit.box(lx * T(0, 0.35, 0), Vector3(8.0, 0.7, 4.0), "moellons71", 1.6, 63 - 4)
	kit.box(lx * T(0, 0.45, 0), Vector3(7.0, 0.1, 3.0), "eau71", 1.0, 4)
	kit.col_box(lx * T(0, 0.35, 0), Vector3(8.0, 0.7, 4.0))
	for s in [-1.0, 1.0]:
		kit.box(lx * T(0, 0.75, s * 1.85), Vector3(8.0, 0.1, 0.4), "dalles71", 1.0)
		for k in range(4):
			kit.box(lx * T(-3.8 + k * 2.53, 1.7, s * 2.6), Vector3(0.22, 3.4, 0.22), "poutre71", 1.0)
	kit.roof_gable(lx * T(0, 3.4, 0), 9.2, 6.0, 32.0, 0.3, "tuiles71_rouge", "planches71")
	c._pt("lav_pt", lx * Vector3(0, 0.05, 4.2))
	_ring_link("lav_pt", "bi", a)
	_ring_link("lav_pt", "bo", a)
	c._spot("lavoir_1", lx * Vector3(-1.8, 0.05, 2.5), lx.basis * Vector3(0, 0, -1), "jardiner", "lav_pt")
	c._spot("lavoir_2", lx * Vector3(1.6, 0.05, 2.5), lx.basis * Vector3(0, 0, -1), "jardiner", "lav_pt")
	c._avoid(lx.origin, 7.0)


func caserne() -> void:
	var y: float = R.BASSE_Y
	var a: float = 109.0
	var fx: Transform3D = c.PX(a, 133.0, y, "in")
	var door: Vector3 = kit.house71(fx, 12.0, 10.0, {"floors": 2, "base": "rempart71", "wall": "enduit71_gris", "roof": "tuiles71_ardoise", "gable": false, "lit": 0.6, "volet": "rouge"})
	kit.flag69(fx * T(-5.0, 6.0, 0.4) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), "banniere71", Vector2(2.0, 0.9))
	# la cour d'entraînement : deux mannequins de paille, un râtelier
	for k in range(2):
		var mp: Vector3 = fx * Vector3(-3.0 + k * 6.0, 0, -15.0)
		kit.box(Transform3D(Basis(), mp + Vector3.UP * 0.8), Vector3(0.12, 1.6, 0.12), "poutre71", 1.0)
		kit.cyl(Transform3D(Basis(), mp + Vector3.UP * 1.0), 0.26, 0.24, 0.8, "chaume71", 8)
		kit.ball(Transform3D(Basis(), mp + Vector3.UP * 2.0), 0.2, "tissu71_brun", 8, 5)
		kit.box(Transform3D(Basis(), mp + Vector3.UP * 1.5), Vector3(0.9, 0.12, 0.12), "poutre71", 1.0)
	c.doors["porte_ferdinand"] = c._pt("porte_ferdinand", door)
	c._pt("cas_pt", fx * Vector3(3.0, 0.05, 2.4))
	_ring_link("cas_pt", "bi", a)
	c._link("porte_ferdinand", "cas_pt")
	c._spot("caserne", fx * Vector3(3.2, 0.05, 1.5), fx.basis * Vector3(0, 0, 1), "bras_croises", "cas_pt")


func ecurie() -> void:
	var y: float = R.BASSE_Y
	var a: float = -113.0
	var fx: Transform3D = c.PX(a, 132.5, y, "in")
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -8.0]:
			kit.box(fx * T(sx * 6.5, 2.0, sz - 0.3), Vector3(0.3, 4.0, 0.3), "poutre71", 1.0)
	kit.box(fx * T(0, 2.0, -8.6), Vector3(13.4, 4.0, 0.4), "planches71_sombre", 1.6)
	kit.col_box(fx * T(0, 2.0, -8.6), Vector3(13.4, 4.0, 0.4))
	for s2 in [-1.0, 1.0]:
		kit.box(fx * T(s2 * 6.7, 2.0, -4.3), Vector3(0.3, 4.0, 8.6), "planches71_sombre", 1.6)
		kit.col_box(fx * T(s2 * 6.7, 2.0, -4.3), Vector3(0.3, 4.0, 8.6))
	kit.roof_gable(fx * T(0, 4.0, -4.3), 14.0, 9.4, 35.0, 0.4, "tuiles71_brun", "planches71")
	for k in range(4):
		kit.box(fx * T(-4.8 + k * 3.2, 0.7, -5.0), Vector3(0.12, 1.4, 6.0), "planches71", 1.0)
	kit.haystack71(fx * Vector3(-5.4, 0, -6.4), 0.9)
	kit.haystack71(fx * Vector3(5.2, 0, -6.6), 0.8)
	kit.cart71(fx * Transform3D(Basis(Vector3.UP, 0.4), Vector3(9.5, 0, 1.0)), true)
	c._pt("ecu_pt", fx * Vector3(0, 0.05, 2.0))
	_ring_link("ecu_pt", "bi", a)
	c._spot("ecurie", fx * Vector3(1.6, 0.05, -2.0), fx.basis * Vector3(0, 0, -1), "bricoler", "ecu_pt")
	c._avoid(fx * Vector3(0, 0, -4.0), 9.0)


func puits() -> void:
	var y: float = R.BASSE_Y
	var a: float = -60.0
	var wx: Transform3D = c.PX(a, 136.0, y, "in")
	kit.well71(wx)
	c._pt("puits_pt", wx * Vector3(0, 0.05, 2.6))
	_ring_link("puits_pt", "bi", a)
	c._spot("puits", wx * Vector3(1.4, 0.05, 1.3), wx.basis * Vector3(-0.6, 0, -1), "debout", "puits_pt")
	c.objets["puits"] = wx.origin

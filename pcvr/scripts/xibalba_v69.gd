extends "res://scripts/enigmes_v69.gd"
## V69 : Xibalba, sous le Temple de Kukulkan (les Mayas de Yaxché) — le Popol Vuh, l'histoire
## des Jumeaux, Hunahpu et Xbalanque, qui descendirent chez les Seigneurs de la mort.
## Dehors, au sommet du temple : le calendrier sacré (deux roues : treize nombres en points et en
## barres, vingt jours) ; à la date de la création du monde, 4 Ahau, la porte du temple s'ouvre.
## Dedans :
##  1. l'escalier (Kukulkan qui descend, peint au mur) ;
##  2. le carrefour des quatre chemins (rouge, noir, blanc, jaune) : le chemin noir mène chez
##     les Seigneurs ; les autres tournent en rond. Xan, le moustique, connaît le bon ;
##  3. la cour des Seigneurs de Xibalba : douze trônes, deux mannequins de bois parmi eux ;
##     saluer les deux grands Seigneurs, Hun-Camé (« Un-Mort ») et Vucub-Camé (« Sept-Morts ») ;
##  4. la Maison Obscure (rendre la torche « entière » : des plumes d'ara rouges au lieu du feu) ;
##     la Maison des Lames (leur offrir la viande d'un cerf, ou passer entre elles) ; la Maison
##     des Jaguars (leur jeter des os, ou les combattre) ;
##  5. le jeu de balle contre les Seigneurs : trois fois la balle dans l'anneau de pierre ;
##  6. la Maison des Chauves-souris : Camazotz. Récompense : le Masque de Jade.

const T := 1.0
const DAYS := ["imix", "ik", "akbal", "kan", "chicchan", "cimi", "manik", "lamat", "muluc", "oc", "chuen", "eb", "ben", "ix", "men", "cib", "caban", "etznab", "cauac", "ahau"]
const DAY_NAMES := ["Imix", "Ik'", "Ak'bal", "K'an", "Chikchan", "Kimi", "Manik'", "Lamat", "Muluk", "Ok", "Chuwen", "Eb'", "B'en", "Ix", "Men", "K'ib'", "Kab'an", "Etz'nab'", "Kawak", "Ajaw (Ahau)"]
const ROADS := [["rouge", -10.5], ["noir", -3.5], ["blanc", 3.5], ["jaune", 10.5]]
## les douze trônes : [nom, signe (le nombre), vrai Seigneur ?]
const LORDS := [["Xiquiripat", "", true], ["Cuchumaquic", "", true], ["Ahalpuh", "", true], ["", "1", false], ["Ahalganá", "", true],
	["Vucub-Camé", "7", true], ["Hun-Camé", "1", true], ["Chamiabac", "", true], ["", "7", false], ["Chamiaholom", "", true], ["Quicxic", "", true], ["Patán", "", true]]
const BLADE_Z := [116.5, 120.5, 124.5, 128.5]

var _wheels: Array = []                         # [disque, fenêtre (MeshInstance3D)]
var _lord_labels: Array = []
var _lord_eyes: Array = []
var _greeted: Dictionary = {}
var _feathers: Array = []                       # [lumière, quad] des trois torches de la Maison Obscure
var _blades: Array = []
var _blade_hit_cd: float = 0.0
var _ball: Node3D
var _ball_busy: bool = false
var _ball_home := Vector3(0, 0.36, 177.0)
var _rings: Array = []                          # centres des anneaux (local)
var _mask: Node3D
var _mosquito: Node3D
var _loop_cd: float = 0.0
var _slab: MeshInstance3D


func _init() -> void:
	key = "maya"
	titre = "Xibalba"
	O = Vector3(-980.0, -130.0, -330.0)
	bbox = AABB(Vector3(-40.0, -12.0, -4.0), Vector3(80.0, 40.0, 240.0))
	room_spawns = {
		"carrefour": [["chauve_souris", -6.0, 0.0, 34.0], ["chauve_souris", 6.0, 0.0, 30.0]],
		"jaguars": [["jaguar", -6.0, 0.0, 150.0], ["jaguar", 6.0, 0.0, 148.0], ["jaguar", 0.0, 0.0, 153.0]],
		"balle": [["chauve_souris", -3.0, 0.0, 188.0], ["chauve_souris", 3.0, 0.0, 166.0]],
	}


func _defaults() -> Dictionary:
	return {"nombre": 11, "jour": 15, "calendrier": false, "cour": false, "plumes": [false, false, false], "obscure": false,
		"lames": false, "jaguars_calmes": false, "jaguars": false, "buts": 0, "balle": false}


func entry() -> Array:
	return [W(Vector3(0, 0, 3.5)), Vector3(0, 0, 1)]


func exit_point() -> Array:
	return [sol.maya.temple_door + Vector3(0, 0.1, 0.8), Vector3(0, 0, 1)]


# =================================================================== construction

func _build() -> void:
	add_room("escalier", Vector3(-6, 0, 0), Vector3(6, 8, 14), Vector3(0, 0, 3.5), Vector3(0, 0, 1), ["carrefour"])
	add_room("carrefour", Vector3(-14, 0, 16), Vector3(14, 9, 44), Vector3(0, 0, 17.8), Vector3(0, 0, 1), ["escalier", "routes"])
	add_room("routes", Vector3(-14, 0, 46), Vector3(14, 7, 60), Vector3(0, 0, 42.0), Vector3(0, 0, 1), ["carrefour", "cour"])
	add_room("cour", Vector3(-16, 0, 62), Vector3(16, 10, 90), Vector3(-3.5, 0, 63.8), Vector3(0, 0, 1), ["routes", "obscure"])
	add_room("obscure", Vector3(-10, 0, 92), Vector3(10, 7, 110), Vector3(0, 0, 93.8), Vector3(0, 0, 1), ["cour", "lames"])
	add_room("lames", Vector3(-10, 0, 112), Vector3(10, 7, 134), Vector3(0, 0, 113.6), Vector3(0, 0, 1), ["obscure", "jaguars"])
	add_room("jaguars", Vector3(-12, 0, 136), Vector3(12, 8, 156), Vector3(0, 0, 137.8), Vector3(0, 0, 1), ["lames", "balle"])
	add_room("balle", Vector3(-12, 0, 158), Vector3(12, 11, 196), Vector3(0, 0, 159.8), Vector3(0, 0, 1), ["jaguars", "chauves"])
	add_room("chauves", Vector3(-16, 0, 198), Vector3(16, 14, 230), Vector3(0, 0, 199.8), Vector3(0, 0, 1), ["balle"])
	_build_escalier()
	_build_carrefour()
	_build_routes()
	_build_cour()
	_build_obscure()
	_build_lames()
	_build_jaguars()
	_build_balle()
	_build_chauves()
	kit.commit()


func _xf() -> Transform3D:
	return Transform3D(Basis(), O)


func _torch(n: String, l: Vector3, facing: Vector3, energy: float = 1.5) -> void:
	kit.torch(rooms[n]["root"], W(l), facing, energy)


func _build_escalier() -> void:
	_in_room("escalier")
	kit.room(_xf(), -6, 6, 0, 14, 0, 8, "pmaya69", "pmaya69_sombre", [["s", 0, 3.2, 4.2]], "pmaya69_sombre", T)
	kit.ramp(_xf(), Vector3(0, 0, 2.6), Vector3(0, 3.0, -0.2), 3.0, "pmaya69", "pmaya69_sombre")
	kit.solid(X(Vector3(0, 1.5, -0.6)), Vector3(3.6, 3.0, 0.8), "pmaya69")
	kit.quadz(X(Vector3(0, 4.2, 0.02)), 3.0, 2.2, "noir69")
	kit.panel(X(Vector3(-5.95, 3.6, 7.0), PI * 0.5), 6.0, 3.0, "fresque69_kukulkan", "pmaya69")
	kit.panel(X(Vector3(5.95, 3.6, 7.0), -PI * 0.5), 6.0, 3.0, "fresque69_jumeaux", "pmaya69")
	for s in [-1.0, 1.0]:
		kit.serpent_head(X(Vector3(s * 2.6, 0, 12.2)), 0.9)
	_torch("escalier", Vector3(-5.85, 2.4, 3.0), Vector3(1, 0, 0))
	_torch("escalier", Vector3(5.85, 2.4, 3.0), Vector3(-1, 0, 0))
	_torch("escalier", Vector3(-5.85, 2.4, 11.0), Vector3(1, 0, 0))
	_torch("escalier", Vector3(5.85, 2.4, 11.0), Vector3(-1, 0, 0))


func _build_carrefour() -> void:
	_in_room("carrefour")
	var ops: Array = [["n", 0, 3.2, 4.2]]
	for r in ROADS:
		ops.append(["s", float(r[1]), 3.0, 4.0])
	kit.room(_xf(), -14, 14, 16, 44, 0, 9, "pmaya69", "pmaya69_sombre", ops, "pmaya69_sombre", T)
	# au centre, une croix de quatre couleurs incrustée dans le sol, un autel rond
	var cols := {"rouge": "stucr69", "noir": "obsid69", "blanc": "enduit69_blanc", "jaune": "enduit69_jaune"}
	for r2 in ROADS:
		var x: float = float(r2[1])
		kit.box(X(Vector3(x * 0.5, 0.01, 37.0)), Vector3(2.4, 0.02, 12.0), str(cols[str(r2[0])]), 2.0, 4)
		# le linteau peint de chaque chemin
		kit.box(X(Vector3(x, 4.35, 43.8)), Vector3(3.6, 0.7, 0.5), str(cols[str(r2[0])]), 1.0)
	kit.cyl(X(Vector3(0, 0, 30.0)), 1.4, 1.3, 0.8, "pmaya69", 18)
	kit.col_cyl(W(Vector3(0, 0, 30.0)), 1.4, 0.8)
	kit.stela(X(Vector3(-9.0, 0, 22.0), PI * 0.25), 1.6, 3.4, "glyphm69", false)
	kit.stela(X(Vector3(9.0, 0, 22.0), -PI * 0.25), 1.6, 3.4, "glyphm69", false)
	for z in [20.0, 32.0]:
		_torch("carrefour", Vector3(-13.85, 2.6, z), Vector3(1, 0, 0))
		_torch("carrefour", Vector3(13.85, 2.6, z), Vector3(-1, 0, 0))
	kit.brazier63(rooms["carrefour"]["root"], W(Vector3(-3.0, 0, 26.0)), true, "bronze69", 2.0, "pmaya69")
	kit.brazier63(rooms["carrefour"]["root"], W(Vector3(3.0, 0, 26.0)), true, "bronze69", 2.0, "pmaya69")


func _build_routes() -> void:
	_in_room("routes")
	kit.room(_xf(), -14, 14, 46, 60, 0, 7, "pmaya69_sombre", "pmaya69_sombre", [["n", -10.5, 3.0, 4.0], ["n", -3.5, 3.0, 4.0], ["n", 3.5, 3.0, 4.0], ["n", 10.5, 3.0, 4.0], ["s", -3.5, 3.0, 4.0]], "pmaya69_sombre", T)
	# les murs entre les quatre chemins
	for wx in [[-13.0, 2.0], [-7.0, 4.0], [0.0, 4.0], [7.0, 4.0], [13.0, 2.0]]:
		kit.solid(X(Vector3(float(wx[0]), 3.5, 53.0)), Vector3(float(wx[1]), 7.0, 14.0), "pmaya69_sombre", 2.5)
	var cols := {"rouge": "stucr69", "noir": "obsid69", "blanc": "enduit69_blanc", "jaune": "enduit69_jaune"}
	for r in ROADS:
		var x: float = float(r[1])
		kit.box(X(Vector3(x, 0.01, 53.0)), Vector3(2.4, 0.02, 14.0), str(cols[str(r[0])]), 2.0, 4)
		if str(r[0]) != "noir":
			# un chemin qui s'enfonce dans le noir… un faux fond peint
			kit.quadz(X(Vector3(x, 2.0, 59.95), PI), 3.0, 4.0, "noir69")
		_torch("routes", Vector3(x - 1.38, 2.2, 49.0), Vector3(1, 0, 0), 0.9)
	var me = self
	chest("noir", "routes", Vector3(-3.5, 0, 57.2), PI, [["plume_ara", 3], ["os_jaguar", 2]],
		"Au bout du chemin noir, un coffre de bois peint : des plumes rouges et des os. Drôle de bagage pour descendre chez les morts…")


func _build_cour() -> void:
	_in_room("cour")
	kit.room(_xf(), -16, 16, 62, 90, 0, 10, "pmaya69_sombre", "pmaya69_sombre", [["n", -3.5, 3.0, 4.0], ["s", 0, 3.2, 4.2]], "pmaya69_sombre", T)
	gate("cour", "cour", Vector3(0, 0, 91.0), 3.4, 4.3, 0.6, 0.0, "pmaya69", "sym69_jour_cimi")
	# le banc des Seigneurs, le long du mur sud
	kit.solid(X(Vector3(-9.0, 0.3, 87.6)), Vector3(13.0, 0.6, 3.6), "pmaya69")
	kit.solid(X(Vector3(9.0, 0.3, 87.6)), Vector3(13.0, 0.6, 3.6), "pmaya69")
	_lord_labels.clear()
	_lord_eyes.clear()
	for i in range(12):
		var x: float = _seat_x(i)
		_lord(i, X(Vector3(x, 0.6, 88.4), PI), not bool(LORDS[i][2]))
	kit.panel(X(Vector3(-15.95, 5.0, 76.0), PI * 0.5), 9.0, 4.5, "fresque69_xibalba", "pmaya69")
	kit.panel(X(Vector3(15.95, 5.0, 76.0), -PI * 0.5), 9.0, 4.5, "fresque69_jumeaux", "pmaya69")
	for z in [66.0, 78.0]:
		_torch("cour", Vector3(-15.85, 2.6, z), Vector3(1, 0, 0), 2.0)
		_torch("cour", Vector3(15.85, 2.6, z), Vector3(-1, 0, 0), 2.0)
	kit.brazier63(rooms["cour"]["root"], W(Vector3(-6.0, 0, 82.0)), true, "bronze69", 2.0, "pmaya69")
	kit.brazier63(rooms["cour"]["root"], W(Vector3(6.0, 0, 82.0)), true, "bronze69", 2.0, "pmaya69")
	# des feux au pied du banc des Seigneurs (leurs crânes dans la lueur)
	for bx in [-12.0, 0.0, 12.0]:
		kit.brazier63(rooms["cour"]["root"], W(Vector3(bx, 0, 84.4)), true, "bronze69", 1.8, "pmaya69")
	var me = self
	chest("cour", "cour", Vector3(13.6, 0, 66.0), -PI * 0.5, [["viande_cerf", 1], ["piece", 12]],
		"Un coffre laissé par les Seigneurs « pour leurs invités » : un cuissot de cerf, et quelques pièces.",
		func(): return bool(me.state["cour"]))


func _seat_x(i: int) -> float:
	return -14.4 + 2.15 * i if i < 6 else 3.65 + 2.15 * (i - 6)


## Un Seigneur de Xibalba sur son trône (crâne blanc, yeux de braise, collier de jade), ou un
## mannequin de bois au visage lisse. xf : au sol du banc, le personnage regarde +Z.
func _lord(i: int, xf: Transform3D, wood: bool) -> void:
	var body_k: String = "bois69" if wood else "psombre69"
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.45, 0.1)), Vector3(1.1, 0.9, 1.0), "pmaya69", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.2, -0.42)), Vector3(1.1, 1.6, 0.25), "pmaya69", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.25, -0.05)), Vector3(0.55, 0.75, 0.38), body_k, 1.0)
	for sx in [-0.16, 0.16]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx, 0.96, 0.3)), Vector3(0.18, 0.16, 0.6), body_k, 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(sx, 0.5, 0.58)), Vector3(0.16, 0.9, 0.18), body_k, 1.0)
		kit.box(xf * Transform3D(Basis(Vector3.RIGHT, -0.9), Vector3(sx * 2.1, 1.2, 0.12)), Vector3(0.13, 0.5, 0.13), body_k, 1.0)
	if wood:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.85, -0.04)), Vector3(0.34, 0.42, 0.34), "bois69_clair", 1.0)
	else:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.85, -0.04)), Vector3(0.34, 0.4, 0.36), "calc69_blanc", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.7, 0.1)), Vector3(0.28, 0.12, 0.12), "calc69_blanc", 1.0)
		kit.box(xf * Transform3D(Basis(), Vector3(0, 1.48, 0.1)), Vector3(0.6, 0.1, 0.12), "jade69", 1.0)
		for sx2 in [-0.08, 0.08]:
			var eye := MeshInstance3D.new()
			var em := SphereMesh.new()
			em.radius = 0.035
			em.height = 0.07
			eye.mesh = em
			eye.material_override = kit.mat("lueur69_rouge")
			(rooms["cour"]["root"] as Node3D).add_child(eye)
			eye.global_position = xf * Vector3(sx2, 1.9, 0.14)
			_lord_eyes.append(eye)
	# une coiffe de plumes (sauf aux mannequins, coiffés d'un simple bandeau de bois)
	if not wood:
		for k in range(5):
			kit.box(xf * Transform3D(Basis(Vector3.BACK, (k - 2) * 0.3), Vector3((k - 2) * 0.09, 2.2, -0.12)), Vector3(0.08, 0.5, 0.04), "plume69" if k % 2 else "plume69_rouge", 1.0)
	else:
		kit.box(xf * Transform3D(Basis(), Vector3(0, 2.1, -0.04)), Vector3(0.38, 0.08, 0.38), "bois69", 1.0)
	# le signe au-dessus du trône : le nombre (s'il y en a un) sur le signe de la mort
	var sign_n: String = str(LORDS[i][1])
	kit.quadz(xf * Transform3D(Basis(), Vector3(0, 2.25, -0.28)), 0.6, 0.6, "sym69_jour_cimi")
	if sign_n != "":
		kit.quadz(xf * Transform3D(Basis(), Vector3(0, 1.6, -0.28)), 0.5, 0.5, "sym69_num_" + sign_n)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(1.1, 2.0, 1.1))
	var lab := Label3D.new()
	lab.text = str(LORDS[i][0]) if not wood else "…"
	lab.font_size = 40
	lab.pixel_size = 0.004
	lab.outline_size = 8
	lab.modulate = Color(1.0, 0.85, 0.6)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	(rooms["cour"]["root"] as Node3D).add_child(lab)
	lab.global_position = xf * Vector3(0, 2.75, 0.2)
	lab.visible = false
	_lord_labels.append(lab)


func _build_obscure() -> void:
	_in_room("obscure")
	kit.room(_xf(), -10, 10, 92, 110, 0, 7, "psombre69", "psombre69", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "psombre69", T)
	gate("obscure", "obscure", Vector3(0, 0, 111.0), 3.4, 4.3, 0.6, 0.0, "psombre69", "sym69_jour_akbal")
	# trois porte-torches éteints (pas de feu : la Maison Obscure)
	_feathers.clear()
	for p in [Vector3(-9.85, 2.4, 97.0), Vector3(9.85, 2.4, 101.0), Vector3(-9.85, 2.4, 105.0)]:
		var face := Vector3(1, 0, 0) if p.x < 0.0 else Vector3(-1, 0, 0)
		var holder := Node3D.new()
		(rooms["obscure"]["root"] as Node3D).add_child(holder)
		holder.global_position = W(p)
		holder.rotation.y = atan2(face.x, face.z)
		var bracket := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.08
		bm.bottom_radius = 0.04
		bm.height = 0.4
		bracket.mesh = bm
		bracket.material_override = kit.mat("bronze69")
		bracket.position = Vector3(0, 0, 0.25)
		holder.add_child(bracket)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.18, 0.55)
		q.mesh = qm
		q.material_override = kit.mat("plume69_rouge")
		q.position = Vector3(0, 0.45, 0.25)
		holder.add_child(q)
		var q2 := q.duplicate()
		q2.rotation.y = PI * 0.5
		holder.add_child(q2)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.3, 0.15)
		l.light_energy = 1.4
		l.omni_range = 7.0
		l.position = Vector3(0, 0.5, 0.4)
		holder.add_child(l)
		_feathers.append([l, q, q2])
	# la seule lueur : les braises d'un foyer tout au fond (et les yeux des chauves-souris)
	kit.glow_light(rooms["obscure"]["root"], W(Vector3(0, 0.4, 108.5)), Color(0.9, 0.3, 0.1), 0.35, 5.0)
	kit.cyl(X(Vector3(0, 0, 108.5)), 0.9, 0.8, 0.3, "psombre69", 12)


func _build_lames() -> void:
	_in_room("lames")
	kit.room(_xf(), -10, 10, 112, 134, 0, 7, "pmaya69_sombre", "pmaya69_sombre", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "pmaya69_sombre", T)
	# l'autel des offrandes, à l'entrée
	kit.solid(X(Vector3(-6.5, 0.5, 114.2)), Vector3(1.6, 1.0, 1.2), "pmaya69")
	# les quatre grandes lames d'obsidienne qui balaient la salle, chacune dans sa rainure
	_blades.clear()
	for i in range(BLADE_Z.size()):
		var z: float = BLADE_Z[i]
		kit.box(X(Vector3(0, 0.01, z)), Vector3(20.0, 0.02, 0.5), "noir69", 2.0, 4)
		var b := Node3D.new()
		b.name = "Lame_%d" % i
		(rooms["lames"]["root"] as Node3D).add_child(b)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 2.6, 0.12)
		mi.mesh = bm
		mi.material_override = kit.mat("obsid69")
		mi.position = Vector3(0, 1.4, 0)
		b.add_child(mi)
		var edge := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(1.7, 0.08, 0.14)
		edge.mesh = em
		edge.material_override = kit.mat("lueur69_rouge")
		edge.position = Vector3(0, 2.72, 0)
		b.add_child(edge)
		b.global_position = W(Vector3(0, 0, z))
		_blades.append(b)
	for z2 in [118.0, 126.0]:
		_torch("lames", Vector3(-9.85, 3.0, z2 + 0.5), Vector3(1, 0, 0), 2.0)
		_torch("lames", Vector3(9.85, 3.0, z2 + 0.5), Vector3(-1, 0, 0), 2.0)


func _build_jaguars() -> void:
	_in_room("jaguars")
	kit.room(_xf(), -12, 12, 136, 156, 0, 8, "pmaya69", "pmaya69_sombre", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "pmaya69_sombre", T)
	gate("jaguars", "jaguars", Vector3(0, 0, 157.0), 3.4, 4.3, 0.6, 0.0, "pmaya69", "sym69_soleil_jaguar")
	for p in [Vector3(-8.0, 0, 142.0), Vector3(8.0, 0, 142.0), Vector3(-8.0, 0, 151.0), Vector3(8.0, 0, 151.0)]:
		kit.column(X(p), 0.6, 8.0, "glyphm69", "pmaya69")
	kit.rocks(rooms["jaguars"]["root"], [W(Vector3(-10.5, 0, 139.0)), W(Vector3(10.6, 0, 154.0)), W(Vector3(-10.4, 0, 153.0))], 69, "roche69", 0.5, 1.0)
	_torch("jaguars", Vector3(-11.85, 2.6, 146.0), Vector3(1, 0, 0), 1.5)
	_torch("jaguars", Vector3(11.85, 2.6, 146.0), Vector3(-1, 0, 0), 1.5)
	kit.brazier63(rooms["jaguars"]["root"], W(Vector3(-4.0, 0, 139.0)), true, "bronze69", 1.8, "pmaya69")
	kit.brazier63(rooms["jaguars"]["root"], W(Vector3(4.0, 0, 139.0)), true, "bronze69", 1.8, "pmaya69")


func _build_balle() -> void:
	_in_room("balle")
	kit.room(_xf(), -12, 12, 158, 196, 0, 11, "pmaya69", "pmaya69_sombre", [["n", 0, 3.2, 4.2], ["s", 0, 3.2, 4.2]], "pmaya69_sombre", T)
	gate("balle", "balle", Vector3(0, 0, 197.0), 3.4, 4.3, 0.6, 0.0, "pmaya69", "sym69_jour_ahau")
	var rc: Array = kit.ball_court(X(Vector3(0, 0, 177.0)), 30.0, 8.0, 6.0)
	_rings.clear()
	for r in rc:
		_rings.append(L(r))
	# des marqueurs (une pierre ronde à chaque bout de l'allée), les Seigneurs en gradins (des crânes)
	for zz in [164.0, 190.0]:
		kit.disc(X(Vector3(0, 0.02, zz)), 0.9, "glyphm69", 18)
	_ball = Node3D.new()
	_ball.name = "Balle"
	(rooms["balle"]["root"] as Node3D).add_child(_ball)
	var bm := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.36
	sm.height = 0.72
	bm.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.09, 0.07)
	mat.roughness = 0.45
	mat.metallic_specular = 0.6
	bm.material_override = mat
	_ball.add_child(bm)
	_ball.global_position = W(_ball_home)
	# les torches sur la face intérieure des murs du terrain (les murs de la salle sont derrière)
	for z2 in [164.0, 171.0, 183.0, 190.0]:
		_torch("balle", Vector3(-5.15, 4.2, z2), Vector3(1, 0, 0), 2.0)
		_torch("balle", Vector3(5.15, 4.2, z2), Vector3(-1, 0, 0), 2.0)
	for z3 in [160.0, 194.0]:
		_torch("balle", Vector3(-11.85, 3.0, z3), Vector3(1, 0, 0), 1.5)
		_torch("balle", Vector3(11.85, 3.0, z3), Vector3(-1, 0, 0), 1.5)
	kit.glow_light(rooms["balle"]["root"], W(Vector3(0, 5.5, 177.0)), Color(1.0, 0.7, 0.4), 0.6, 22.0)


func _build_chauves() -> void:
	_in_room("chauves")
	kit.room(_xf(), -16, 16, 198, 230, 0, 14, "psombre69", "psombre69", [["n", 0, 3.2, 4.2]], "psombre69", T)
	# des stalactites, des perchoirs, l'autel du fond
	for k in range(14):
		var x: float = -14.0 + fmod(k * 9.7, 28.0)
		var z: float = 201.0 + fmod(k * 13.3, 27.0)
		kit.cyl(X(Vector3(x, 14.0 - 2.2 - fmod(k * 0.7, 1.5), z)), 0.05, 0.45, 2.2 + fmod(k * 0.7, 1.5), "roche69", 8)
	kit.solid(X(Vector3(0, 0.5, 226.5)), Vector3(4.0, 1.0, 3.0), "pmaya69")
	kit.stela(X(Vector3(0, 1.0, 228.6), 0.0), 2.0, 4.0, "glyphm69", false)
	for z2 in [204.0, 216.0]:
		_torch("chauves", Vector3(-15.85, 3.0, z2), Vector3(1, 0, 0), 1.3)
		_torch("chauves", Vector3(15.85, 3.0, z2), Vector3(-1, 0, 0), 1.3)
	kit.brazier63(rooms["chauves"]["root"], W(Vector3(-3.0, 1.0, 226.0)), true, "bronze69", 2.0, "pmaya69")
	kit.brazier63(rooms["chauves"]["root"], W(Vector3(3.0, 1.0, 226.0)), true, "bronze69", 2.0, "pmaya69")
	_mask = Node3D.new()
	_mask.name = "Masque_de_Jade"
	(rooms["chauves"]["root"] as Node3D).add_child(_mask)
	var mm := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 0.3
	ms.height = 0.6
	mm.mesh = ms
	mm.scale = Vector3(1.0, 1.25, 0.45)
	mm.material_override = kit.mat("jade69")
	_mask.add_child(mm)
	for sx in [-0.1, 0.1]:
		var e := MeshInstance3D.new()
		var eb := BoxMesh.new()
		eb.size = Vector3(0.1, 0.035, 0.03)
		e.mesh = eb
		e.material_override = kit.mat("calc69_blanc")
		e.position = Vector3(sx, 0.07, 0.14)
		_mask.add_child(e)
	var ml := OmniLight3D.new()
	ml.light_color = Color(0.4, 1.0, 0.6)
	ml.light_energy = 1.4
	ml.omni_range = 5.0
	_mask.add_child(ml)
	_mask.global_position = W(Vector3(0, 2.0, 226.2))
	_mask.visible = false


# =================================================================== le calendrier du sommet

func register(journal: Node) -> void:
	journal.lieux["xibalba"] = W(Vector3(0, 0, 3.5))
	var d: Node = main.get("donjon_v35")
	if d == null or sol.maya == null:
		return
	var txf: Transform3D = sol.maya.temple_xf
	var me = self
	_wheels.clear()
	for i in range(2):
		var p: Vector3 = txf * Vector3(-2.4 + i * 4.8, 0.4, 6.2)
		var w := _make_wheel(p, txf.basis, i)
		_wheels.append(w)
		var ii: int = i
		d._interactions.append({"id": "ma_roue_%d" % i, "pos": txf * Vector3(-2.4 + i * 4.8, 0.45, 7.4), "radius": 1.3,
			"text": "E : tourner la roue des nombres" if i == 0 else "E : tourner la roue des jours", "vr": "Gâchette : la roue",
			"call": func(): me._turn_wheel(ii), "when": func(): return not bool(me.state["calendrier"])})
	d._interactions.append({"id": "ma_temple_porte", "pos": sol.maya.temple_door, "radius": 1.6, "text": "E : examiner la porte du temple", "vr": "Gâchette : la porte",
		"call": func(): me._say("La porte du milieu est murée par une dalle de pierre. De part et d'autre, deux roues de pierre gravées : des nombres en points et en barres, et les vingt jours du calendrier sacré. « Quand la date de la création du monde reviendra, Kukulkan ouvrira sa porte. »", 8.0),
		"when": func(): return not bool(me.state["calendrier"])})
	d._interactions.append({"id": "ma_temple_entrer", "pos": sol.maya.temple_door, "radius": 1.6, "text": "E : descendre dans le temple (vers Xibalba)", "vr": "Gâchette : descendre",
		"call": func(): me.enter(), "when": func(): return bool(me.state["calendrier"])})
	# la dalle qui mure la porte du milieu (elle s'enfonce quand la date est juste)
	_slab = MeshInstance3D.new()
	_slab.name = "Dalle_porte_Kukulkan"
	var sb := BoxMesh.new()
	sb.size = Vector3(1.5, 2.45, 0.16)
	_slab.mesh = sb
	_slab.material_override = preload("res://scripts/soleils_mats_v69.gd").make("pmaya69")
	add_child(_slab)
	_slab.global_transform = Transform3D(txf.basis, txf * Vector3(0, 0.4 + 1.22, 4.58))
	_slab.visible = not bool(state["calendrier"])
	_show_wheels(false)


func _make_wheel(p: Vector3, basis: Basis, i: int) -> Array:
	var root := Node3D.new()
	root.name = "Roue_calendrier_%d" % i
	add_child(root)
	root.global_transform = Transform3D(basis, p)
	var Mats = preload("res://scripts/soleils_mats_v69.gd")
	var foot := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(1.9, 0.6, 0.7)
	foot.mesh = fb
	foot.material_override = Mats.make("pmaya69")
	foot.position = Vector3(0, 0.3, 0)
	root.add_child(foot)
	var disc := Node3D.new()
	disc.position = Vector3(0, 1.55, 0)
	root.add_child(disc)
	var dm := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.95
	cm.bottom_radius = 0.95
	cm.height = 0.3
	cm.radial_segments = 26 if i == 0 else 40
	dm.mesh = cm
	dm.material_override = Mats.make("glyphm69")
	dm.rotation.x = PI * 0.5
	disc.add_child(dm)
	# les crans (13 ou 20)
	var n: int = 13 if i == 0 else 20
	for k in range(n):
		var a: float = TAU * k / n
		var t := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.12, 0.2, 0.34)
		t.mesh = tb
		t.material_override = Mats.make("pmaya69")
		t.position = Vector3(cos(a) * 1.0, sin(a) * 1.0, 0)
		t.rotation.z = a
		disc.add_child(t)
	# la fenêtre où paraît le signe
	var frame := MeshInstance3D.new()
	var fr := BoxMesh.new()
	fr.size = Vector3(0.95, 0.95, 0.1)
	frame.mesh = fr
	frame.material_override = Mats.make("stucr69")
	frame.position = Vector3(0, 1.55, 0.18)
	root.add_child(frame)
	var win := MeshInstance3D.new()
	var wq := QuadMesh.new()
	wq.size = Vector2(0.8, 0.8)
	win.mesh = wq
	win.position = Vector3(0, 1.55, 0.235)
	root.add_child(win)
	var col := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.9, 2.6, 0.7)
	cs.shape = sh
	cs.position = Vector3(0, 1.3, 0)
	col.add_child(cs)
	root.add_child(col)
	return [disc, win]


func _show_wheels(animate: bool) -> void:
	if _wheels.is_empty():
		return
	var Mats = preload("res://scripts/soleils_mats_v69.gd")
	var nb: int = int(state["nombre"])
	var jr: int = int(state["jour"])
	(_wheels[0][1] as MeshInstance3D).material_override = Mats.make("sym69_num_%d" % nb)
	(_wheels[1][1] as MeshInstance3D).material_override = Mats.make("sym69_jour_" + DAYS[jr])
	var a0: float = -TAU * (nb - 1) / 13.0
	var a1: float = -TAU * jr / 20.0
	if animate:
		create_tween().tween_property(_wheels[0][0], "rotation:z", a0, 0.5).set_trans(Tween.TRANS_BACK)
		create_tween().tween_property(_wheels[1][0], "rotation:z", a1, 0.5).set_trans(Tween.TRANS_BACK)
	else:
		(_wheels[0][0] as Node3D).rotation.z = a0
		(_wheels[1][0] as Node3D).rotation.z = a1


func _turn_wheel(i: int) -> void:
	if i == 0:
		state["nombre"] = int(state["nombre"]) % 13 + 1
	else:
		state["jour"] = (int(state["jour"]) + 1) % 20
	# les roues tournent dans le même sens : on garde un angle qui ne revient pas en arrière
	_show_wheels(true)
	_sfx("mecanisme", (_wheels[i][0] as Node3D).global_position)
	var nb: int = int(state["nombre"])
	var jr: int = int(state["jour"])
	main._show_message_v28("La date : %d %s" % [nb, DAY_NAMES[jr]])
	if nb == 4 and jr == 19:
		state["calendrier"] = true
		_sfx("flute_maya", sol.maya.temple_door + Vector3.UP)
		_sfx("pierre_glisse", sol.maya.temple_door + Vector3.UP)
		if main.has_method("jingle"):
			main.jingle("decouverte")
		if _slab != null:
			var down: Vector3 = _slab.global_position + Vector3.DOWN * 2.5
			var tw := create_tween()
			tw.tween_property(_slab, "global_position", down, 2.5).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(func(): _slab.visible = false)
		_say("4 Ahau ! Le jour où les dieux ont créé le monde. Un grondement dans le temple : la dalle qui murait la porte du milieu s'enfonce dans le sol. Un escalier descend dans le noir… vers Xibalba.", 9.0)


# =================================================================== invites du donjon

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 2.0), 1.6, "E : remonter au sommet du temple", "Gâchette : remonter", func(): me.leave("De retour au sommet du Temple de Kukulkan. Le soleil, enfin."))
	ia("moustique_carrefour", Vector3(0, 0, 33.2), 2.6, "E : lâcher Xan le moustique", "Gâchette : lâcher Xan",
		func(): me._mosquito_roads(), func(): return me._inv().count("moustique") > 0)
	ia("chemins", Vector3(0, 0, 33.2), 2.6, "E : examiner les quatre chemins", "Gâchette : les chemins",
		func(): me._say("Quatre chemins partent du carrefour : un rouge, un noir, un blanc, un jaune. Sur la stèle, ces mots : « Ici, les Jumeaux hésitèrent. Mais Xan, le moustique, partit devant eux. »", 7.0),
		func(): return me._inv().count("moustique") <= 0)
	ia("moustique_cour", Vector3(0, 0, 80.0), 3.0, "E : lâcher Xan le moustique sur les Seigneurs", "Gâchette : lâcher Xan",
		func(): me._mosquito_lords(), func(): return me._inv().count("moustique") > 0 and not bool(me.state["cour"]))
	for i in range(12):
		var ii: int = i
		ia("seigneur_%d" % i, Vector3(_seat_x(i), 0, 85.0), 1.0, "E : saluer ce Seigneur", "Gâchette : saluer", func(): me._greet(ii), func(): return not bool(me.state["cour"]))
	for i2 in range(3):
		var jj: int = i2
		var p: Vector3 = [Vector3(-9.0, 0, 97.0), Vector3(9.0, 0, 101.0), Vector3(-9.0, 0, 105.0)][i2]
		ia("torche_%d" % i2, p, 1.5, "E : t'occuper de la torche", "Gâchette : la torche", func(): me._torch_holder(jj),
			func(): return not bool((me.state["plumes"] as Array)[jj]))
	ia("offrande_lames", Vector3(-6.5, 0, 115.4), 1.6, "E : offrir le cuissot de cerf aux lames", "Gâchette : l'offrande",
		func(): me._offer_meat(), func(): return not bool(me.state["lames"]) and me._inv().count("viande_cerf") > 0)
	ia("autel_lames", Vector3(-6.5, 0, 115.4), 1.6, "E : examiner l'autel", "Gâchette : l'autel",
		func(): me._say("Un autel de pierre, vide, taché de vieux sang. Gravé dessus : « Les lames ont faim. Les Jumeaux leur promirent la chair de toutes les bêtes… et les lames se couchèrent. »", 7.0),
		func(): return not bool(me.state["lames"]) and me._inv().count("viande_cerf") <= 0)
	ia("os_jaguars", Vector3(0, 0, 139.5), 2.6, "E : jeter des os aux jaguars", "Gâchette : jeter des os",
		func(): me._throw_bones(), func(): return not bool(me.state["jaguars"]) and me._inv().count("os_jaguar") > 0 and me.room_alive("jaguars") > 0)
	var it: Dictionary = ia("balle", Vector3.ZERO, 1.8, "E : frapper la balle (de la hanche)", "Gâchette : frapper la balle",
		func(): me._hit_ball(), func(): return not bool(me.state["balle"]) and not me._ball_busy)
	it["suit_balle"] = true
	ia("masque", Vector3(0, 1.0, 224.6), 2.2, "E : prendre le Masque de Jade", "Gâchette : le masque", func(): me._take_mask(),
		func(): return bool(me.state["boss"]) and not bool(me.state["fini"]))
	ia("sortie_fin", Vector3(0, 1.0, 224.6), 2.2, "E : monter l'escalier secret (vers le sommet du temple)", "Gâchette : remonter",
		func(): me.leave("Un long escalier en colimaçon… et te voilà au sommet du Temple de Kukulkan, ébloui par le soleil."), func(): return bool(me.state["fini"]))


func _apply_outdoor() -> void:
	_show_wheels(false)
	if _slab != null and sol.maya != null:
		_slab.visible = not bool(state["calendrier"])
		_slab.global_transform = Transform3D(sol.maya.temple_xf.basis, sol.maya.temple_xf * Vector3(0, 0.4 + 1.22, 4.58))


func _apply_state() -> void:
	super._apply_state()
	_apply_outdoor()
	if _feathers.is_empty():
		return
	var pl: Array = state["plumes"]
	for i in range(3):
		var on: bool = bool(pl[i])
		(_feathers[i][0] as OmniLight3D).visible = on
		(_feathers[i][1] as Node3D).visible = on
		(_feathers[i][2] as Node3D).visible = on
	for i2 in range(_blades.size()):
		(_blades[i2] as Node3D).position.x = O.x + (9.4 if i2 % 2 == 0 else -9.4) if bool(state["lames"]) else O.x
	if _ball != null:
		_ball.global_position = W(_ball_home)
	_mask.visible = bool(state["boss"]) and not bool(state["fini"])
	for lab in _lord_labels:
		(lab as Label3D).visible = bool(state["cour"])


# =================================================================== Xan le moustique

func _mosquito_fly(path: Array, back: bool) -> void:
	if _mosquito != null and is_instance_valid(_mosquito):
		_mosquito.queue_free()
	_mosquito = Node3D.new()
	add_child(_mosquito)
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	m.mesh = sm
	m.material_override = kit.mat("lueur69_vert")
	_mosquito.add_child(m)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 1.0, 0.6)
	l.light_energy = 1.0
	l.omni_range = 3.0
	_mosquito.add_child(l)
	_mosquito.global_position = _feet() + Vector3.UP * 1.5
	var tw := create_tween()
	for p in path:
		tw.tween_property(_mosquito, "global_position", W(p), 0.9).set_trans(Tween.TRANS_SINE)
	if back:
		tw.tween_property(_mosquito, "global_position", _feet() + Vector3.UP * 1.5, 1.2)
	tw.tween_callback(func(): if is_instance_valid(_mosquito): _mosquito.queue_free())


func _mosquito_roads() -> void:
	_sfx("chauve_souris_cri", _feet() + Vector3.UP)
	_mosquito_fly([Vector3(-3.5, 1.6, 40.0), Vector3(-3.5, 1.6, 50.0), Vector3(-3.5, 1.6, 58.5), Vector3(-3.5, 1.6, 50.0), Vector3(-3.5, 1.6, 40.0)], true)
	_say("Tu ouvres la calebasse. Xan file droit… sur le chemin NOIR ! Il y disparaît, puis revient en zigzaguant, tout content, et rentre dans sa calebasse.", 7.0)


func _mosquito_lords() -> void:
	var path: Array = []
	for i in range(12):
		path.append(Vector3(_seat_x(i), 2.0, 88.6))
	_mosquito_fly(path, true)
	_say("Xan file vers les trônes et pique chaque Seigneur, l'un après l'autre…", 4.0)
	for i2 in range(12):
		get_tree().create_timer(0.9 * (i2 + 1)).timeout.connect(func(): _sting(i2))


func _sting(i: int) -> void:
	if not built:
		return
	var lab: Label3D = _lord_labels[i]
	if bool(LORDS[i][2]):
		lab.visible = true
		if main.combat_v28 != null:
			main.combat_v28.float_text(lab.global_position, "« Aïe ! » — « Qu'as-tu, %s ? »" % str(LORDS[i][0]), Color(1.0, 0.6, 0.4))
	else:
		lab.visible = true
		lab.text = "(rien… du bois)"
	if i == 11:
		_say("Les vrais Seigneurs ont crié, et les autres les ont appelés par leur nom ! Deux d'entre eux n'ont pas bronché : des mannequins de bois.", 7.0)


# =================================================================== la cour des Seigneurs

func _greet(i: int) -> void:
	var e: Array = LORDS[i]
	if not bool(e[2]):
		_greeted.clear()
		_say("« Salut à toi, grand Seigneur ! »… Tu as salué un MANNEQUIN DE BOIS. Un rire terrible roule sous la voûte : tous les Seigneurs se moquent de toi. Et du plafond, des chauves-souris se détachent !", 7.0)
		_sfx("camazotz_cri", W(Vector3(0, 6, 80)))
		for k in range(2):
			spawn_in("cour", "chauve_souris", Vector3(-4.0 + k * 8.0, 0, 80.0), true)
		return
	var nm: String = str(e[0])
	if nm != "Hun-Camé" and nm != "Vucub-Camé":
		_say("« Salut à toi, %s. » Le Seigneur te regarde de ses yeux de braise : « Je ne suis pas le plus grand ici. Ce n'est pas moi que tu dois saluer d'abord. »" % nm, 6.0)
		return
	_greeted[nm] = true
	if _greeted.size() < 2:
		_say("« Salut à toi, %s ! » Le Seigneur incline lentement son crâne. Il en reste un…" % nm, 5.0)
		_sfx("flute_maya", W(Vector3(_seat_x(i), 2, 88)))
		return
	state["cour"] = true
	for lab in _lord_labels:
		(lab as Label3D).visible = true
	_sfx("flute_maya", W(Vector3(0, 2, 88)))
	_say("« Salut à toi, Hun-Camé, salut à toi, Vucub-Camé ! » Les deux grands Seigneurs se lèvent à demi : « Tu nous connais donc… Entre dans nos Maisons, voyageur. Si tu en ressors, nous jouerons à la balle. » Derrière eux, la porte s'enfonce dans le sol.", 9.0)
	await get_tree().create_timer(2.5).timeout
	open_gate("cour")


# =================================================================== les Maisons

func _torch_holder(i: int) -> void:
	if _inv().count("plume_ara") > 0:
		_inv().remove("plume_ara", 1)
		state["plumes"][i] = true
		(_feathers[i][0] as OmniLight3D).visible = true
		(_feathers[i][1] as Node3D).visible = true
		(_feathers[i][2] as Node3D).visible = true
		_sfx("lueur", W(Vector3(0, 2, 100)))
		var n: int = 0
		for f in state["plumes"]:
			if bool(f):
				n += 1
		if n < 3:
			_say("Tu piques une plume d'ara rouge dans le porte-torche : elle brille comme une flamme… qui ne brûle pas. (%d sur 3)" % n, 5.0)
			return
		state["obscure"] = true
		_say("Trois flammes rouges qui ne brûlent pas ! Une voix sèche, dans le noir : « Nos torches sont… entières ? » Les Seigneurs sont furieux, mais la porte s'ouvre.", 8.0)
		await get_tree().create_timer(2.0).timeout
		open_gate("obscure")
		return
	_say("Tu allumes la torche… elle flambe, se consume, et tombe en cendres. Un rire dans le noir : « Rends-nous notre torche ENTIÈRE, demain matin ! » (Il faudrait qu'elle brille sans brûler. Les Jumeaux, eux, y avaient mis des plumes rouges.)", 9.0)
	_sfx("flamme_impact", W(Vector3(0, 2, 100)))


func _offer_meat() -> void:
	_inv().remove("viande_cerf", 1)
	state["lames"] = true
	_sfx("mecanisme", W(Vector3(0, 1, 122)))
	_say("Tu poses le cuissot de cerf sur l'autel : « Lames, voici la chair des bêtes. Elle sera à vous, toutes les bêtes de la forêt. » Un grincement… et les quatre lames glissent dans les murs et se couchent.", 8.0)
	for i in range(_blades.size()):
		var b: Node3D = _blades[i]
		create_tween().tween_property(b, "position:x", O.x + (9.4 if i % 2 == 0 else -9.4), 1.6).set_trans(Tween.TRANS_SINE)


func _blade_x(i: int) -> float:
	var speed: float = [0.9, 1.15, 0.8, 1.3][i]
	return 8.0 * sin(_clock * speed + i * 1.7)


func _throw_bones() -> void:
	_inv().remove("os_jaguar", 1)
	state["jaguars_calmes"] = true
	_say("Tu jettes les os au milieu de la salle. Les jaguars se jettent dessus en grondant… et se couchent pour les ronger. Ils ne s'intéressent plus du tout à toi.", 7.0)
	for m in _room_monsters.get("jaguars", []):
		if is_instance_valid(m) and str(m.state) != "mort":
			var sp: Dictionary = (m.spec as Dictionary).duplicate()
			sp["vue"] = 0.0
			m.spec = sp
			m.state = "veille"
			m.home = m.global_position
	_check_jaguars()


func _check_jaguars() -> void:
	if bool(state["jaguars"]) or not room_spawned("jaguars"):
		return
	var hostile: int = 0
	for m in _room_monsters.get("jaguars", []):
		if is_instance_valid(m) and str(m.state) != "mort" and float(m.spec["vue"]) > 0.0:
			hostile += 1
	if hostile == 0:
		state["jaguars"] = true
		open_gate("jaguars", "La Maison des Jaguars est calme. La porte du fond s'enfonce dans le sol : derrière, un terrain de jeu de balle.")


# =================================================================== le jeu de balle

func _hit_ball() -> void:
	if _ball_busy:
		return
	var b: Vector3 = L(_ball.global_position)
	var p: Vector3 = L(_feet())
	var dir := Vector3(b.x - p.x, 0, b.z - p.z)
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	_sfx("balle", _ball.global_position)
	# vers un anneau ?
	for rc in _rings:
		var to_r := Vector3(rc.x - b.x, 0, rc.z - b.z)
		var dist: float = to_r.length()
		if dist < 14.0 and dir.angle_to(to_r.normalized()) < deg_to_rad(14.0):
			_goal(rc)
			return
	# sinon la balle roule, rebondit sur les talus, s'arrête
	var end: Vector3 = b + dir * 6.0
	end.x = clampf(end.x, -3.4, 3.4)
	end.z = clampf(end.z, 163.5, 190.5)
	end.y = _ball_home.y
	_ball_busy = true
	var tw := create_tween()
	tw.tween_property(_ball, "global_position", W(end), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): me_ball_free())
	if randf() < 0.5:
		_say("La balle roule, rebondit sur le talus… et retombe dans l'allée. Les Seigneurs ricanent. Vise l'anneau de pierre, sur le mur.", 4.0)


func me_ball_free() -> void:
	_ball_busy = false


func _goal(rc: Vector3) -> void:
	_ball_busy = true
	var b: Vector3 = _ball.global_position
	var through: Vector3 = W(rc) + (W(rc) - b).normalized() * 0.6
	var mid: Vector3 = (b + W(rc)) * 0.5 + Vector3.UP * 1.6
	var tw := create_tween()
	tw.tween_property(_ball, "global_position", mid, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_ball, "global_position", through, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _scored())


func _scored() -> void:
	state["buts"] = int(state["buts"]) + 1
	_sfx("balle", _ball.global_position)
	var n: int = int(state["buts"])
	if n < 3:
		_say("DANS L'ANNEAU ! La balle traverse la pierre. Les Seigneurs se taisent d'un coup. (%d sur 3)" % n, 5.0)
	else:
		state["balle"] = true
		_say("TROISIÈME FOIS DANS L'ANNEAU ! Les Seigneurs de Xibalba sont vaincus au jeu de balle, comme autrefois par les Jumeaux. « Va donc… dans la Maison des Chauves-souris. » La porte du fond s'ouvre.", 9.0)
		if main.has_method("jingle"):
			main.jingle("victoire")
		open_gate("balle")
	await get_tree().create_timer(1.6).timeout
	if _ball != null:
		_ball.global_position = W(_ball_home)
	_ball_busy = false


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	var l: Vector3 = L(p)
	_loop_cd = maxf(_loop_cd - delta, 0.0)
	match r:
		"routes":
			# un mauvais chemin : il tourne en rond, et te ramène au carrefour
			if l.z > 52.5 and _loop_cd <= 0.0 and absf(l.x + 3.5) > 1.8:
				_loop_cd = 3.0
				_loop_back()
		"lames":
			_tick_blades(delta, l)
		"jaguars":
			if room_spawned("jaguars"):
				_check_jaguars()
		"chauves":
			if not bool(state["boss"]) and not fight and l.z > 206.0:
				_say("Un battement d'ailes énorme fait vaciller les flammes. Une silhouette se décroche de la voûte : un corps d'homme, une tête de chauve-souris, des ailes immenses… CAMAZOTZ !", 7.0)
				_start_boss("camazotz", Vector3(0, 0, 216.0), "Camazotz, la chauve-souris de la mort", Callable(self, "_camazotz_dead"))
	if r != "lames" and not bool(state["lames"]):
		_blade_hit_cd = maxf(_blade_hit_cd - delta, 0.0)
	# les lames bougent dès qu'on est dans la salle ou dans les salles voisines
	if not bool(state["lames"]) and (r == "lames" or r == "obscure" or r == "jaguars"):
		for i in range(_blades.size()):
			(_blades[i] as Node3D).position.x = O.x + _blade_x(i)
	if _mask != null and _mask.visible:
		_mask.rotate_y(delta * 0.7)


func _loop_back() -> void:
	_say("Le chemin tourne, tourne… et te ramène au carrefour. Quelque part, des rires secs résonnent. Ce n'était pas le bon chemin.", 6.0)
	await main.donjon_v35._travel(W(Vector3(0, 0, 36.0)), Vector3(0, 0, 1))


func _tick_blades(delta: float, l: Vector3) -> void:
	_blade_hit_cd = maxf(_blade_hit_cd - delta, 0.0)
	if bool(state["lames"]):
		return
	for i in range(_blades.size()):
		var bx: float = _blade_x(i)
		(_blades[i] as Node3D).position.x = O.x + bx
		if _blade_hit_cd <= 0.0 and absf(l.z - float(BLADE_Z[i])) < 0.55 and absf(l.x - bx) < 1.15 and l.y < 2.5:
			_blade_hit_cd = 1.6
			_sfx("lame", W(Vector3(bx, 1.4, float(BLADE_Z[i]))))
			_fall_back("Une lame d'obsidienne te frôle… et t'entaille ! Tu recules jusqu'à l'entrée de la salle.", 2)


func _camazotz_dead() -> void:
	state["boss"] = true
	_say("Camazotz s'écrase sur les dalles et se dissout en une nuée de chauves-souris qui fuient par les fissures de la voûte. Le silence… Sur l'autel du fond, quelque chose de vert s'allume.", 8.0)
	await get_tree().create_timer(2.0).timeout
	_mask.visible = true
	_mask.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_mask, "scale", Vector3.ONE, 1.5)


func _take_mask() -> void:
	state["fini"] = true
	_mask.visible = false
	_reward("masque_jade", "Vainqueur de Xibalba", 150, W(Vector3(0, 1.2, 224.0)))
	main._show_message_v28("Le Masque de Jade ! Le visage des rois de Yaxché, des centaines de petits carrés verts. 150 pièces, un cœur de plus, et un titre : « Vainqueur de Xibalba ». Un escalier secret, derrière l'autel, remonte au sommet du temple.")


func _on_enter(first: bool) -> void:
	if first:
		_say("Tu descends, longtemps, dans le ventre du Temple de Kukulkan. L'air devient humide et froid. Sur les murs, le Serpent à plumes descend avec toi… et deux jeunes gens, une sarbacane à la main : les Jumeaux.", 9.0)
	else:
		_say("Xibalba, le royaume des Seigneurs de la mort.", 3.0)


func _enter_room(_old: String, r: String) -> void:
	match r:
		"carrefour":
			_once("carrefour", "Le carrefour. Quatre chemins partent vers le sud : un rouge, un noir, un blanc, un jaune. Lequel mène chez les Seigneurs ?", 6.0)
		"cour":
			if not bool(state["cour"]):
				_once("cour", "La cour des Seigneurs de Xibalba. Douze trônes, douze silhouettes immobiles. Une voix sèche : « Salue donc les Seigneurs, voyageur… les plus grands d'abord. »", 8.0)
		"obscure":
			if not bool(state["obscure"]):
				_once("obscure", "La Maison Obscure. Le noir complet. Une voix : « Voici nos torches. Garde-les allumées toute la nuit, et rends-les-nous ENTIÈRES demain. » Trois porte-torches vides, aux murs.", 8.0)
		"lames":
			if not bool(state["lames"]):
				_once("lames", "La Maison des Lames. Quatre lames d'obsidienne, hautes comme un homme, balaient la salle d'un mur à l'autre. Près de l'entrée, un autel vide.", 7.0)
		"jaguars":
			if not bool(state["jaguars"]):
				_once("jaguars", "La Maison des Jaguars. Des yeux jaunes dans l'ombre, des grondements, des os rongés partout sur le sol…", 6.0)
		"balle":
			if not bool(state["balle"]):
				_once("balle", "Le jeu de balle des Seigneurs. Une allée, deux talus, deux anneaux de pierre tout en haut des murs. La balle de caoutchouc, au milieu. « Joue contre nous, voyageur. Trois fois dans l'anneau, et tu passes. »", 9.0)
		"chauves":
			if not bool(state["boss"]):
				_once("chauves", "La Maison des Chauves-souris. Des milliers de petits cris, là-haut, dans le noir. Et un silence, plus bas, beaucoup plus lourd.", 6.0)


func _faint_text() -> String:
	return "Des rires secs, dans le noir…"


func _on_reset() -> void:
	_greeted.clear()
	_ball_busy = false
	if built and _ball != null:
		_ball.global_position = W(_ball_home)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not built or _ball == null:
		return
	for it in _ia:
		if it.has("suit_balle"):
			it["pos"] = _ball.global_position - Vector3(0, _ball_home.y, 0)

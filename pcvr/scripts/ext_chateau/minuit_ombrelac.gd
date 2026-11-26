extends Node3D
## Extension « Le Château d'Ombrelac » (v16) : les caves de la Maison de Minuit, sous la fontaine du cloître.
## La quatrième maison de l'Académie (l'Aube, le Zénith, le Crépuscule, la Minuit) s'est endormie sous le
## cloître il y a deux cents ans. On y descend par l'escalier qui s'ouvre au fond de la fontaine quand
## Hortense, la grenouille, a entendu les cinq indices (quetes_ombrelac.gd).
##  - la Salle de l'Escalier : la Porte du Treizième Coup (une cloche : sonner treize coups, pas un de plus) ;
##  - la Salle des Veilleurs : quatre statues (le Soleil, le Coq, la Chouette, le Papillon) : toucher celle
##    qui veille la nuit ;
##  - la Galerie des Trois Angles : trois roues de bronze à tourner d'un quart de tour (un angle droit)
##    jusqu'à ce que la lune noire de la Minuit soit en haut des trois ;
##  - la Salle du Trésor : la bannière de la Minuit, le coffre, la lettre des fondateurs.
## Le tout dans le repère du château (nœud enfant du château), à 100 m sous le cloître, dans le roc. On y
## descend et on en remonte comme dans les souterrains du jeu (un fondu au noir). L'état : ombrelac.state["minuit"].

const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")
const Horloge = preload("res://scripts/ext_chateau/horloge_ombrelac.gd")

## Le sol des caves (repère château) : cent mètres sous le cloître, sous la cote -40 du monde, comme les
## souterrains du jeu (main._in_dungeon_v35 : pas de « remontée à la surface », l'ambiance de sous terre)
const FY := -100.0
const H := 5.0                      # la hauteur sous plafond
const EP := 1.0                     # l'épaisseur des murs
const PORTE_L := 2.4
const PORTE_H := 3.2
const FONTAINE := Vector3(10.0, 0.0, -23.0)   # le centre de la fontaine du cloître (repère château)
## Les salles : [x0, x1, z0, z1]
const SALLES := {"escalier": [5.0, 15.0, -28.0, -18.0], "veilleurs": [4.0, 16.0, -40.0, -28.0],
	"angles": [16.0, 30.0, -40.0, -30.0], "tresor": [19.0, 31.0, -30.0, -18.0]}
## Les murs : [axe ("x" : le long de x, à z fixe ; "z" : le long de z, à x fixe), fixe, de, à, porte (au milieu de l'ouverture) ou NAN]
const MURS := [["x", -18.0, 5.0, 15.0, NAN], ["z", 5.0, -28.0, -18.0, NAN], ["z", 15.0, -28.0, -18.0, NAN],
	["x", -28.0, 4.0, 16.0, 10.0], ["z", 4.0, -40.0, -28.0, NAN], ["x", -40.0, 4.0, 30.0, NAN],
	["z", 16.0, -40.0, -28.0, -34.5], ["z", 30.0, -40.0, -30.0, NAN], ["x", -30.0, 16.0, 31.0, 25.0],
	["z", 31.0, -30.0, -18.0, NAN], ["x", -18.0, 19.0, 31.0, NAN], ["z", 19.0, -30.0, -18.0, NAN]]
## Les trois portes : la position (le milieu, au sol), le sens du mur
const PORTES := {"treize": [Vector3(10.0, FY, -28.0), "x"], "veilleurs": [Vector3(16.0, FY, -34.5), "z"], "angles": [Vector3(25.0, FY, -30.0), "x"]}
const STATUES := ["soleil", "coq", "chouette", "papillon"]
const NOMS_STATUES := {"soleil": "le Soleil", "coq": "le Coq", "chouette": "la Chouette", "papillon": "le Papillon"}
const GLYPHES := ["soleil", "etoile", "chouette", "lune"]    # sur les roues, de quart en quart
const ROUES_DEPART := [0, 1, 2]
const LUNE := 3
const TRESOR := [["piece_or", 8], ["elixir_etoile", 2], ["carte_tresor", 1], ["eclat_lune", 1]]

var main: Node
var ombrelac: Node
var chateau: Node3D
var portes: Dictionary = {}         # nom -> StaticBody3D
var roues: Array = []               # Node3D (tournent autour de z)
var yeux: Array = []                # les yeux de la chouette (s'allument)
var couvercle: Node3D
var cloche: Node3D
var son: AudioStreamPlayer3D
var coups: int = 0                  # les coups de la Porte du Treizième Coup
var _t_coup: float = 0.0
var _busy: bool = false


# =================================================================== construire

func build(the_main: Node, the_ombrelac: Node, the_chateau: Node3D) -> void:
	main = the_main
	ombrelac = the_ombrelac
	chateau = the_chateau
	name = "Ombrelac_minuit"
	var k := Kit.new()
	# les sols, les plafonds (le puits de l'escalier : un trou dans le plafond de la première salle)
	for nom in SALLES:
		var s: Array = SALLES[nom]
		var c := Vector3((s[0] + s[1]) * 0.5, FY, (s[2] + s[3]) * 0.5)
		var w: float = s[1] - s[0] + EP
		var d: float = s[3] - s[2] + EP
		k.box("dalles_int", _at(c.x, FY - 0.5, c.z), Vector3(w, 0.5, d), true)
		if nom == "escalier":
			k.box("moellons", _at(c.x - 1.5, FY + H, c.z), Vector3(w - 3.0, 0.6, d), true)
			k.box("moellons", _at(s[1] - 1.0, FY + H, c.z - 1.6), Vector3(3.0, 0.6, d - 3.2), true)
		else:
			k.box("moellons", _at(c.x, FY + H, c.z), Vector3(w, 0.6, d), true)
	# les murs (une ouverture pour chaque porte, un linteau de pierre claire au-dessus)
	for m in MURS:
		_mur(k, str(m[0]), float(m[1]), float(m[2]), float(m[3]), float(m[4]))
	_escalier(k)
	_cloche_porte(k)
	_veilleurs(k)
	_angles(k)
	_tresor(k)
	add_child(k.commit("Ombrelac_minuit_caves"))
	add_child(k.body("Ombrelac_minuit_caves_col"))
	for nom in PORTES:
		_porte(nom)
	# la lumière : des lanternes aux murs, une lumière douce par salle
	for nom in SALLES:
		var s: Array = SALLES[nom]
		var l := OmniLight3D.new()
		l.position = Vector3((s[0] + s[1]) * 0.5, FY + H - 1.2, (s[2] + s[3]) * 0.5)
		l.light_color = Color(1.0, 0.74, 0.46)
		l.light_energy = 1.7
		l.omni_range = 11.0
		l.omni_attenuation = 1.2
		add_child(l)
	son = AudioStreamPlayer3D.new()
	son.max_distance = 40.0
	son.unit_size = 6.0
	add_child(son)
	appliquer()


static func _at(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))


func _mur(k: RefCounted, axe: String, fixe: float, a: float, b: float, porte: float) -> void:
	var morceaux: Array = [[a - EP * 0.5, b + EP * 0.5]]
	if not is_nan(porte):
		morceaux = [[a - EP * 0.5, porte - PORTE_L * 0.5], [porte + PORTE_L * 0.5, b + EP * 0.5]]
	for mo in morceaux:
		var l: float = float(mo[1]) - float(mo[0])
		var m: float = (float(mo[0]) + float(mo[1])) * 0.5
		var c: Vector3 = Vector3(m, FY, fixe) if axe == "x" else Vector3(fixe, FY, m)
		var sz: Vector3 = Vector3(l, H, EP) if axe == "x" else Vector3(EP, H, l)
		k.box("moellons", _at(c.x, c.y, c.z), sz, true)
	if not is_nan(porte):
		var c2: Vector3 = Vector3(porte, FY, fixe) if axe == "x" else Vector3(fixe, FY, porte)
		var sz2: Vector3 = Vector3(PORTE_L, H - PORTE_H, EP) if axe == "x" else Vector3(EP, H - PORTE_H, PORTE_L)
		k.box("moellons", _at(c2.x, FY + PORTE_H, c2.z), sz2, true)
		# l'encadrement : deux jambages, le linteau
		var t: Vector3 = Vector3(1, 0, 0) if axe == "x" else Vector3(0, 0, 1)
		for sg in [-1.0, 1.0]:
			var j: Vector3 = c2 + t * sg * (PORTE_L * 0.5 + 0.15)
			k.box("pierre_claire", _at(j.x, FY, j.z), Vector3(0.36, PORTE_H, EP + 0.2) if axe == "x" else Vector3(EP + 0.2, PORTE_H, 0.36))
		k.box("pierre_claire", _at(c2.x, FY + PORTE_H, c2.z), Vector3(PORTE_L + 0.7, 0.4, EP + 0.2) if axe == "x" else Vector3(EP + 0.2, 0.4, PORTE_L + 0.7))


## L'escalier qui remonte vers la fontaine : une volée contre le mur sud de la première salle, qui
## s'enfonce dans le puits (le trou du plafond), et le puits lui-même, noir, jusque sous le cloître
func _escalier(k: RefCounted) -> void:
	var n: int = 14
	for i in range(n):
		var x: float = 7.0 + i * 0.55
		k.box("pierre_claire", _at(x, FY, -19.3), Vector3(0.55, 0.36 * (i + 1), 2.4), true)
	# le puits : quatre murs au-dessus du trou, un fond noir
	var cx: float = 13.5
	var cz: float = -19.6
	k.box("moellons", _at(cx, FY + H, cz - 1.75), Vector3(3.4, 9.0, 0.5), true)
	k.box("moellons", _at(cx - 1.75, FY + H, cz), Vector3(0.5, 9.0, 3.4), true)
	k.box("moellons", _at(cx + 1.75, FY + H, cz), Vector3(0.5, 9.0, 3.4), true)
	k.box("moellons", _at(cx, FY + H, cz + 1.75), Vector3(3.4, 9.0, 0.5), true)
	k.box("suie", _at(cx, FY + H + 6.0, cz), Vector3(3.4, 0.3, 3.4), true)
	# la rampe de fer
	for i in range(8):
		k.box("fer", _at(7.2 + i * 0.9, FY + 0.36 * (i * 1.64 + 1.0), -20.45), Vector3(0.06, 0.95, 0.06))
	k.box("fer", Transform3D(Basis(Vector3.BACK, atan2(0.36, 0.55)), Vector3(10.4, FY + 0.36 * 7.5 + 0.95, -20.45)), Vector3(8.4, 0.07, 0.07))


## La Porte du Treizième Coup : une cloche sur un portique, l'inscription
func _cloche_porte(k: RefCounted) -> void:
	var p := Vector3(12.9, FY, -26.4)
	for sx in [-0.9, 0.9]:
		k.box("chene", _at(p.x + sx, FY, p.z), Vector3(0.22, 2.7, 0.22))
	k.box("chene", _at(p.x, FY + 2.6, p.z), Vector3(2.1, 0.24, 0.26))
	cloche = Node3D.new()
	cloche.name = "Cloche_minuit"
	cloche.position = Vector3(p.x, FY + 2.6, p.z)
	add_child(cloche)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.5
	cm.height = 0.75
	cm.radial_segments = 20
	mi.mesh = cm
	mi.material_override = Kit.mat("bronze")
	mi.position = Vector3(0, -0.45, 0)
	cloche.add_child(mi)
	_plaque(k, Vector3(7.0, FY + 2.2, -27.45), Vector3(0, 0, 1))


## La Salle des Veilleurs : quatre statues sur leur socle, contre le mur nord
func _veilleurs(k: RefCounted) -> void:
	for i in range(STATUES.size()):
		var p := Vector3(6.5 + i * 2.5, FY, -38.6)
		k.box("pierre_claire", _at(p.x, FY, p.z), Vector3(1.0, 1.1, 1.0), true)
		k.box("pierre", _at(p.x, FY + 1.1, p.z), Vector3(1.1, 0.12, 1.1))
		_statue(str(STATUES[i]), p + Vector3(0, 1.22, 0))
	_plaque(k, Vector3(4.55, FY + 2.2, -33.5), Vector3(1, 0, 0))


func _boule(parent: Node3D, r: float, p: Vector3, m: Material, sy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	mi.scale = Vector3(1, sy, 1)
	parent.add_child(mi)
	return mi


func _bloc(parent: Node3D, sz: Vector3, p: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _statue(sorte: String, p: Vector3) -> void:
	var s := Node3D.new()
	s.name = "Statue_" + sorte
	s.position = p
	add_child(s)
	var br: Material = Kit.mat("bronze")
	match sorte:
		"soleil":
			_bloc(s, Vector3(0.1, 0.8, 0.1), Vector3(0, 0.4, 0), br)
			var d := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.34
			cm.bottom_radius = 0.34
			cm.height = 0.08
			d.mesh = cm
			d.material_override = Kit.mat("or")
			d.rotation.x = PI * 0.5
			d.position = Vector3(0, 1.1, 0)
			s.add_child(d)
			for i in range(12):
				var a: float = TAU * i / 12.0
				_bloc(s, Vector3(0.05, 0.3, 0.04), Vector3(cos(a) * 0.48, 1.1 + sin(a) * 0.48, 0), Kit.mat("or"), Vector3(0, 0, a - PI * 0.5))
		"coq":
			_boule(s, 0.34, Vector3(0, 0.42, 0), br, 0.9)
			_boule(s, 0.17, Vector3(0, 0.86, 0.18), br)
			_bloc(s, Vector3(0.05, 0.16, 0.22), Vector3(0, 1.04, 0.16), Kit.mat("potion_rouge"))
			_bloc(s, Vector3(0.06, 0.06, 0.14), Vector3(0, 0.86, 0.38), Kit.mat("or"))
			_bloc(s, Vector3(0.08, 0.5, 0.3), Vector3(0, 0.66, -0.36), br, Vector3(-0.6, 0, 0))
		"chouette":
			_boule(s, 0.36, Vector3(0, 0.5, 0), br, 1.25)
			_boule(s, 0.27, Vector3(0, 1.0, 0.02), br)
			for sx in [-0.11, 0.11]:
				yeux.append(_boule(s, 0.075, Vector3(sx, 1.03, 0.22), Kit.mat("or")))
				_bloc(s, Vector3(0.07, 0.14, 0.05), Vector3(sx * 1.5, 1.27, 0.0), br)
			_bloc(s, Vector3(0.05, 0.07, 0.07), Vector3(0, 0.94, 0.26), Kit.mat("or"))
		"papillon":
			_bloc(s, Vector3(0.08, 0.6, 0.08), Vector3(0, 0.45, 0), br)
			for sx in [-1.0, 1.0]:
				_bloc(s, Vector3(0.5, 0.45, 0.03), Vector3(sx * 0.27, 0.78, 0), br, Vector3(0, sx * 0.35, sx * 0.25))
				_bloc(s, Vector3(0.36, 0.3, 0.03), Vector3(sx * 0.22, 0.42, 0), br, Vector3(0, sx * 0.35, -sx * 0.4))


## La Galerie des Trois Angles : trois roues de bronze au mur nord, une flèche d'or au-dessus de chacune
func _angles(k: RefCounted) -> void:
	for i in range(3):
		var p := Vector3(20.5 + i * 2.5, FY + 1.7, -39.42)
		k.box("pierre_claire", _at(p.x, FY + 0.6, p.z + 0.05), Vector3(1.9, 2.3, 0.25))
		k.box("or", _at(p.x, p.y + 0.86, p.z + 0.2), Vector3(0.1, 0.22, 0.1))
		var r := Node3D.new()
		r.name = "Roue_%d" % i
		r.position = p + Vector3(0, 0, 0.3)
		add_child(r)
		var d := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.72
		cm.bottom_radius = 0.72
		cm.height = 0.14
		cm.radial_segments = 28
		d.mesh = cm
		d.material_override = Kit.mat("bronze")
		d.rotation.x = PI * 0.5
		r.add_child(d)
		for g in range(4):
			var a: float = PI * 0.5 * g
			_glyphe(r, str(GLYPHES[g]), Vector3(-sin(a), cos(a), 0) * 0.46 + Vector3(0, 0, 0.09))
		roues.append(r)
	_plaque(k, Vector3(29.45, FY + 2.2, -35.0), Vector3(-1, 0, 0))


func _glyphe(r: Node3D, g: String, p: Vector3) -> void:
	match g:
		"soleil":
			var b := _boule(r, 0.13, p, Kit.mat("or"))
			b.scale = Vector3(1, 1, 0.35)
		"etoile":
			_bloc(r, Vector3(0.24, 0.07, 0.04), p, Kit.mat("cristal"))
			_bloc(r, Vector3(0.07, 0.24, 0.04), p, Kit.mat("cristal"))
			_bloc(r, Vector3(0.18, 0.05, 0.04), p, Kit.mat("cristal"), Vector3(0, 0, PI * 0.25))
			_bloc(r, Vector3(0.18, 0.05, 0.04), p, Kit.mat("cristal"), Vector3(0, 0, -PI * 0.25))
		"chouette":
			var o := _boule(r, 0.12, p, Kit.mat("chene"), 1.25)
			o.scale = Vector3(1, 1.25, 0.4)
			for sx in [-0.045, 0.045]:
				_boule(r, 0.03, p + Vector3(sx, 0.05, 0.05), Kit.mat("or"))
		"lune":
			var l := _boule(r, 0.15, p, Kit.mat("suie"))
			l.scale = Vector3(1, 1, 0.3)
			var c := _boule(r, 0.16, p + Vector3(0, 0, -0.01), Kit.mat("cristal"))
			c.scale = Vector3(1, 1, 0.2)


## Une plaque gravée (son texte est dans quetes_ombrelac.gd) : face, vers où elle regarde
func _plaque(k: RefCounted, p: Vector3, face: Vector3) -> void:
	var yaw: float = atan2(face.x, face.z)
	k.box("bronze", Transform3D(Basis(Vector3.UP, yaw), p - Vector3(0, 0.45, 0)), Vector3(1.4, 0.9, 0.06))
	k.box("pierre_claire", Transform3D(Basis(Vector3.UP, yaw), p - Vector3(0, 0.55, 0) - face * 0.03), Vector3(1.6, 1.1, 0.05))


## La Salle du Trésor : la bannière de la Minuit, le coffre, la table de pierre et la lettre, des pièces d'or
func _tresor(k: RefCounted) -> void:
	# la bannière (nuit et argent), au mur est
	var bn := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.8, 3.4)
	bn.mesh = qm
	var sti := ShaderMaterial.new()
	sti.shader = load(Kit.TISSU)
	sti.set_shader_parameter("fond", Color(0.03, 0.03, 0.08))
	sti.set_shader_parameter("bord", Color(0.78, 0.8, 0.86))
	bn.material_override = sti
	bn.position = Vector3(30.42, FY + 2.6, -24.0)
	bn.rotation.y = -PI * 0.5
	add_child(bn)
	var lune := _boule(self, 0.42, Vector3(30.38, FY + 2.9, -24.0), Kit.mat("cristal"))
	lune.scale = Vector3(0.12, 1, 1)
	var ombre := _boule(self, 0.36, Vector3(30.33, FY + 2.95, -23.88), Kit.mat("suie"))
	ombre.scale = Vector3(0.12, 1, 1)
	k.box("fer", _at(30.4, FY + 4.35, -24.0), Vector3(0.1, 0.1, 2.2))
	# le coffre (le couvercle s'ouvre)
	var c := Vector3(25.0, FY, -19.4)
	k.box("chene", _at(c.x, FY, c.z), Vector3(1.6, 0.7, 0.9), true)
	for sx in [-0.6, 0.0, 0.6]:
		k.box("fer", _at(c.x + sx, FY - 0.01, c.z), Vector3(0.1, 0.72, 0.94))
	couvercle = Node3D.new()
	couvercle.name = "Couvercle_minuit"
	couvercle.position = Vector3(c.x, FY + 0.7, c.z + 0.45)
	add_child(couvercle)
	_bloc(couvercle, Vector3(1.64, 0.28, 0.94), Vector3(0, 0.14, -0.45), Kit.mat("chene"))
	_bloc(couvercle, Vector3(0.18, 0.2, 0.06), Vector3(0, 0.0, -0.94), Kit.mat("or"))
	# l'or, autour (de petits tas de pièces)
	for i in range(9):
		var a: float = i * 2.4
		var r: float = 1.2 + 0.25 * (i % 3)
		var q: Vector3 = c + Vector3(cos(a) * r, 0, -absf(sin(a)) * r * 0.8 - 0.2)
		var t := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.05
		tm.bottom_radius = 0.22 + 0.06 * (i % 2)
		tm.height = 0.12 + 0.05 * (i % 3)
		tm.radial_segments = 12
		t.mesh = tm
		t.material_override = Kit.mat("or")
		t.position = q + Vector3(0, tm.height * 0.5, 0)
		add_child(t)
	# la table de pierre, la lettre, deux chandeliers
	k.box("pierre_claire", _at(21.0, FY, -24.0), Vector3(0.7, 0.9, 1.6), true)
	k.box("pierre", _at(21.0, FY + 0.9, -24.0), Vector3(0.9, 0.1, 1.8))
	k.box("cire", _at(21.0, FY + 1.0, -24.0, 0.2), Vector3(0.32, 0.01, 0.24))
	for sz in [-0.7, 0.7]:
		k.cyl("or", _at(21.0, FY + 1.0, -24.0 + sz), 0.08, 0.04, 0.3, 8)
		k.cyl("cire", _at(21.0, FY + 1.3, -24.0 + sz), 0.03, 0.03, 0.16, 8)
	# des lanternes aux murs des quatre salles
	for p in [Vector3(5.55, 0, -24.0), Vector3(14.45, 0, -26.0), Vector3(4.55, 0, -31.0), Vector3(15.45, 0, -38.0),
			Vector3(17.0, 0, -30.55), Vector3(29.45, 0, -38.5), Vector3(19.55, 0, -21.0), Vector3(30.45, 0, -20.0)]:
		k.box("fer", _at(p.x, FY + 2.7, p.z), Vector3(0.16, 0.5, 0.16))
		k.box("lanterne", _at(p.x, FY + 3.2, p.z), Vector3(0.28, 0.4, 0.28))


## Une porte : une grille de fer qui s'enfonce dans le sol quand on l'ouvre
func _porte(nom: String) -> void:
	var pd: Array = PORTES[nom]
	var p: Vector3 = pd[0]
	var axe: String = pd[1]
	var b := StaticBody3D.new()
	b.name = "Porte_" + nom
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = p
	if axe == "z":
		b.rotation.y = PI * 0.5
	add_child(b)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(PORTE_L, PORTE_H, 0.3)
	cs.shape = bs
	cs.position = Vector3(0, PORTE_H * 0.5, 0)
	b.add_child(cs)
	var k := Kit.new()
	for i in range(9):
		var x: float = -PORTE_L * 0.5 + 0.15 + i * (PORTE_L - 0.3) / 8.0
		k.cyl("fer", _at(x, 0.0, 0.0), 0.04, 0.04, PORTE_H - 0.05, 8)
	for y in [0.4, 1.6, 2.8]:
		k.box("fer", _at(0.0, y, 0.0), Vector3(PORTE_L - 0.1, 0.1, 0.1))
	# le blason de la Minuit au milieu : une lune noire cerclée d'argent
	k.cyl("cristal", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.9, 0.06)), 0.3, 0.3, 0.04, 20)
	k.cyl("suie", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.06, 1.94, 0.1)), 0.25, 0.25, 0.04, 20)
	b.add_child(k.commit("Grille"))
	portes[nom] = b


# =================================================================== l'état

func st() -> Dictionary:
	if ombrelac == null:
		return {}
	var s: Dictionary = ombrelac.state
	if not s.has("minuit") or not (s["minuit"] is Dictionary):
		s["minuit"] = {}
	var m: Dictionary = s["minuit"]
	for kk in ["treize", "veilleurs", "angles", "coffre"]:
		if not m.has(kk):
			m[kk] = false
	if not m.has("roues") or not (m["roues"] is Array) or (m["roues"] as Array).size() != 3:
		m["roues"] = ROUES_DEPART.duplicate()
	return m


## Remettre les portes, les roues, le coffre comme la partie les a laissés
func appliquer() -> void:
	var m: Dictionary = st()
	for nom in portes:
		var b: StaticBody3D = portes[nom]
		b.position.y = FY - PORTE_H - 0.1 if bool(m.get(nom, false)) else FY
	for i in range(roues.size()):
		(roues[i] as Node3D).rotation.z = -PI * 0.5 * int(m["roues"][i])
	_yeux(bool(m.get("veilleurs", false)))
	if couvercle != null:
		couvercle.rotation.x = 1.9 if bool(m.get("coffre", false)) else 0.0


func _yeux(on: bool) -> void:
	for y in yeux:
		var mi: MeshInstance3D = y
		if on:
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(1.0, 0.85, 0.4)
			em.emission_enabled = true
			em.emission = Color(1.0, 0.8, 0.3)
			em.emission_energy_multiplier = 3.0
			mi.material_override = em
		else:
			mi.material_override = Kit.mat("or")


func ouverte(nom: String) -> bool:
	return bool(st().get(nom, false))


func roue_haut(i: int) -> int:
	return int(st()["roues"][i]) % 4


## Le monde (pour les objets) depuis le repère château
func monde(p: Vector3) -> Vector3:
	var xf: Transform3D = chateau.global_transform if chateau.is_inside_tree() else chateau.transform
	return xf * p


func contient_local(p: Vector3) -> bool:
	return p.y < FY + H + 1.0 and p.y > FY - 2.0 and p.x > 3.0 and p.x < 32.0 and p.z > -41.0 and p.z < -17.0


# =================================================================== les énigmes

func _ouvrir(nom: String) -> void:
	var m: Dictionary = st()
	if bool(m.get(nom, false)):
		return
	m[nom] = true
	var b: StaticBody3D = portes.get(nom)
	if b == null:
		return
	if main != null and main.has_method("sfx"):
		main.sfx("pierre_glisse", monde(b.position))
		main.sfx("porte", monde(b.position))
	if b.is_inside_tree():
		var tw := create_tween()
		tw.tween_property(b, "position:y", FY - PORTE_H - 0.1, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	else:
		b.position.y = FY - PORTE_H - 0.1


## La cloche : un coup ; le treizième ouvre la porte (si on s'arrête là)
func frapper() -> String:
	if ouverte("treize"):
		_son_cloche()
		return "DONG… La cloche résonne longtemps sous la voûte. La porte, elle, est déjà ouverte."
	coups += 1
	_t_coup = 0.0
	_son_cloche()
	if cloche != null and cloche.is_inside_tree():
		var tw := create_tween()
		tw.tween_property(cloche, "rotation:z", 0.25, 0.12)
		tw.tween_property(cloche, "rotation:z", -0.15, 0.2)
		tw.tween_property(cloche, "rotation:z", 0.0, 0.25)
	if coups > 13:
		coups = 0
		return "Quatorze ! Un coup de trop : la porte gronde, et le silence efface le compte. Tout est à recommencer."
	if coups == 13:
		return "Treize. Tu retiens ton souffle… (Laisse la cloche se taire.)"
	return "DONG ! (%d)" % coups


## Le temps qui passe entre deux coups : le treizième, suivi du silence, ouvre la porte ; trop de silence
## avant le treizième, et le compte s'efface
func _process(delta: float) -> void:
	if coups <= 0:
		return
	_t_coup += delta
	if coups == 13 and _t_coup > 2.5:
		coups = 0
		_ouvrir("treize")
		_dire("Le treizième coup s'éteint… et la grille de fer s'enfonce lentement dans le sol. La Minuit a entendu son heure.", 7.0)
	elif coups < 13 and _t_coup > 8.0:
		coups = 0
		_dire("Le silence est retombé : la cloche a oublié tes coups. Il faut les sonner d'une traite.", 5.0)


func _son_cloche() -> void:
	if son != null and son.is_inside_tree():
		son.position = cloche.position if cloche != null else Vector3(12.9, FY + 2.0, -26.4)
		son.stream = Horloge.son_cloche()
		son.pitch_scale = 1.35
		son.play()


## Une statue : la bonne (celle qui veille la nuit) ouvre la porte
func toucher(statue: String) -> String:
	if ouverte("veilleurs"):
		return "Les yeux de la Chouette brillent toujours. Elle veille sur la porte ouverte."
	match statue:
		"chouette":
			_ouvrir("veilleurs")
			_yeux(true)
			if main != null and main.has_method("sfx"):
				main.sfx("cristal_chante", monde(Vector3(11.5, FY + 2.0, -38.6)))
			return "Tu poses la main sur la Chouette de bronze. Ses yeux s'allument d'une lueur d'or, un hululement lointain roule sous la voûte… et la grille de l'est s'enfonce dans le sol."
		"soleil":
			return "Le Soleil est froid sous ta main. Il ne veille que le jour : il ne se passe rien."
		"coq":
			return "Le Coq a l'air très fier de lui. Mais un coq, la nuit, ça dort. Rien ne bouge."
		"papillon":
			return "Le Papillon frémit à peine. Un papillon de jour : il dort la nuit. Rien ne se passe."
	return ""


## Une roue : un quart de tour (un angle droit) ; les trois lunes noires en haut ouvrent la porte
func tourner(i: int) -> String:
	if ouverte("angles"):
		return "La roue tourne à vide, avec un cliquetis content. La porte est ouverte."
	var m: Dictionary = st()
	m["roues"][i] = (int(m["roues"][i]) + 1) % 4
	var r: Node3D = roues[i]
	var cible: float = -PI * 0.5 * int(m["roues"][i])
	if r.is_inside_tree():
		while cible > r.rotation.z + 0.01:
			cible -= TAU
		var tw := create_tween()
		tw.tween_property(r, "rotation:z", cible, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): r.rotation.z = wrapf(r.rotation.z, -TAU, 0.0))
	else:
		r.rotation.z = cible
	if main != null and main.has_method("sfx"):
		main.sfx("cliquet_roue", monde(r.position))
	var haut: Array = []
	for j in range(3):
		haut.append(roue_haut(j))
	var nom: String = {"soleil": "le soleil", "etoile": "l'étoile", "chouette": "la chouette", "lune": "la lune noire"}[GLYPHES[roue_haut(i)]]
	if haut == [LUNE, LUNE, LUNE]:
		_ouvrir("angles")
		return "Clac ! En haut de la roue : %s. Les trois lunes noires te regardent… et la dernière grille s'enfonce dans le sol." % nom
	return "Un quart de tour, un angle droit. Clac ! En haut de la roue : %s." % nom


## Le coffre de la Minuit
func ouvrir_coffre() -> String:
	var m: Dictionary = st()
	if bool(m.get("coffre", false)):
		return "Le coffre est vide, à part une odeur de vieux velours et un grain de poussière d'étoile."
	var inv: Node = main.get("inventory_v28") if main != null else null
	if inv != null and inv.has_method("can_accept") and not inv.can_accept(TRESOR, []):
		return "Ton sac est trop plein pour le trésor de la Minuit. Fais de la place, puis reviens."
	m["coffre"] = true
	if inv != null:
		for t in TRESOR:
			inv.add(str(t[0]), int(t[1]))
	if couvercle != null and couvercle.is_inside_tree():
		var tw := create_tween()
		tw.tween_property(couvercle, "rotation:x", 1.9, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if main != null:
		if main.has_method("sfx"):
			main.sfx("coffre", monde(Vector3(25.0, FY + 0.8, -19.4)))
			main.sfx("coffre_pieces", monde(Vector3(25.0, FY + 0.8, -19.4)))
		var pr: Variant = main.get("progression_v63")
		if pr != null and pr.has_method("on_chest"):
			pr.on_chest(monde(Vector3(25.0, FY + 0.8, -19.4)))
		if main.has_method("jingle"):
			main.jingle("victoire")
	return "Le couvercle grince… Le trésor de la Maison de Minuit ! Huit pièces d'or, deux élixirs d'étoile, une vieille carte au trésor et un éclat de lune, posés sur du velours noir."


func _dire(txt: String, s: float) -> void:
	var o: Variant = ombrelac.get("objets") if ombrelac != null else null
	if o != null and o.has_method("say"):
		o.say(txt, s)


# =================================================================== descendre, remonter

## L'arrivée en bas de l'escalier (monde), et le regard
func arrivee() -> Array:
	var xf: Transform3D = chateau.global_transform if chateau.is_inside_tree() else chateau.transform
	return [xf * Vector3(7.6, FY + 0.1, -22.4), (xf.basis * Vector3(0.3, 0, -1)).normalized()]


## La sortie, au bord de la fontaine (monde)
func sortie() -> Array:
	var xf: Transform3D = chateau.global_transform if chateau.is_inside_tree() else chateau.transform
	var p: Vector3 = xf * (FONTAINE + Vector3(5.6, 0.0, 0.0))
	var ile: Variant = ombrelac.get("ile") if ombrelac != null else null
	if ile != null and ile.has_method("height"):
		p.y = maxf(float(ile.height(p.x, p.z)), p.y) + 0.15
	return [p, (xf.basis * Vector3(-1, 0, 0)).normalized()]


func descendre() -> void:
	var a: Array = arrivee()
	await _voyage(a[0], a[1])


func remonter() -> void:
	var a: Array = sortie()
	await _voyage(a[0], a[1])


func _voyage(cible: Vector3, regard: Vector3) -> void:
	if _busy or main == null:
		return
	_busy = true
	var d: Variant = main.get("donjon_v35")
	if main.get("fishing_v32") != null and main.fishing_v32 != null and main.fishing_v32.has_method("cancel"):
		main.fishing_v32.cancel("")
	if d != null and d.has_method("_fade_to") and is_inside_tree():
		await d._fade_to(1.0, 0.45)
	if main.has_method("place_player_v35"):
		main.place_player_v35(cible, regard)
	# (sous terre : l'ambiance des souterrains du jeu ; dehors : le ciel revient)
	if d != null and d.has_method("update_inside"):
		d.update_inside(true)
	if d != null and d.has_method("_fade_to") and is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		await d._fade_to(0.0, 0.6)
	_busy = false

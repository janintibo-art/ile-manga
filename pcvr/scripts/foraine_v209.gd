extends Node3D
## V209 : l'Île Foraine, à l'est de l'archipel (au large de Montjoie). L'île des sensations fortes :
## on paie son billet au guichet (en pièces, il vaut pour la journée), on passe le tourniquet sous le
## grand portail, et tout au bout de l'allée, le Grand Frisson — un grand huit de 1,7 km qui fait
## le tour de l'île (grand_huit_v209). V210 : le Marteau (au bord de l'allée), la Chute (au sommet
## de la Butte) et la Grande Balançoire (au bord de la mer, au sud) ; le billet vaut pour tout.
## Tout public : rien ne change ici entre les deux modes du jeu.

const IleScript = preload("res://scripts/ile_foraine_v209.gd")
const Kit = preload("res://scripts/foraine_kit_v209.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const Huit = preload("res://scripts/grand_huit_v209.gd")
const Trace = preload("res://scripts/grand_huit_trace_v209.gd")
const Marteau = preload("res://scripts/marteau_v210.gd")
const Chute = preload("res://scripts/chute_v210.gd")
const Balancoire = preload("res://scripts/balancoire_v210.gd")

# V210 : où sont les manèges (sur l'île)
const MARTEAU_AT := Vector2(36.0, 44.0)
const CHUTE_AT := Vector2(18.0, -116.0)
const BALANCOIRE_AT := Vector2(20.0, 160.0)

const PRIX: int = 25                      # le billet d'entrée (en pièces), pour la journée
const QUAI_Y: float = 5.32                # le plancher du quai du grand huit
const PLACES := {"fo_ponton": "le ponton", "fo_entree": "le Grand Portail", "fo_quai": "le quai du Grand Frisson",
	"fo_butte": "la Butte aux Frissons", "fo_place": "la Place du Mât", "fo_plage": "la plage", "fo_esplanade": "l'esplanade",
	"fo_marteau": "le Marteau", "fo_chute": "la Chute", "fo_balancoire": "la Grande Balançoire"}

var main: Node
var ile: Node3D
var huit: Node3D
var maneges: Array = []                   # V210 : le Marteau, la Chute, la Grande Balançoire
var prehistoire: Node3D                   # V217 : le Parc du Volcan (les animaux de décoration, les massifs)
var volcan: Node3D                        # V213 : la roche (les orgues, les arches), le panache
var pc: bool = true
var state: Dictionary = {}
var guichet_pos := Vector3.ZERO
var portail_pos := Vector3.ZERO
var reglage_pos := Vector3.ZERO
var _cols: GK.Cols
var _barriere: CollisionShape3D
var _bras: Node3D
var _interactions: Array = []
var bornes: Array = []                  # V214 : les bornes « monter ici » (une par attraction)
var _borne_t := 0.0
var lampions := {"portiques": 0, "lampions": 0}   # V214
var _registered: bool = false
var _built: bool = false
var _bras_t: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "billet_jour": -1, "billets": 0, "tours": 0, "doux": false, "marteau": 0, "chute": 0, "balancoire": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_foraine_v209"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Un point de l'île dans le monde, posé sur le sol (dy au-dessus)
func _w(x: float, z: float, dy: float = 0.0) -> Vector3:
	var p: Vector3 = IleScript.W(x, z)
	p.y = (ile.height(p.x, p.z) if ile != null else 0.0) + dy
	return p


## Un point de l'île dans le monde, à une hauteur donnée
func _a(x: float, y: float, z: float) -> Vector3:
	return Vector3(IleScript.CENTER.x + x, y, IleScript.CENTER.z + z)


func build_town() -> void:
	if _built or ile == null:
		return
	_built = true
	_cols = GK.Cols.new(self, "Foraine_cols_v209")
	_portail()
	_clotures()
	_gare()
	_place()
	_baraques()
	huit = Huit.new()
	huit.name = "Grand_huit_v209"
	add_child(huit)
	huit.setup(main, ile)
	# V210 : les manèges à sensations
	for spec in [[Marteau, MARTEAU_AT, PI * 0.5], [Chute, CHUTE_AT, 0.0], [Balancoire, BALANCOIRE_AT, 0.0]]:
		var m: Node3D = spec[0].new()
		m.name = "%s_v210" % str(m.cle).capitalize()
		add_child(m)
		m.setup(main, ile, self, spec[1], float(spec[2]))
		m.tours = int(state.get(str(m.cle), 0))
		maneges.append(m)
	# V213 : la roche du volcan (les orgues de basalte, les arches), tout près de la voie
	volcan = load("res://scripts/volcan_v213.gd").new()
	add_child(volcan)
	volcan.setup(main, ile, _cols)
	# V217 : le Parc du Volcan, au temps des dinosaures (des animaux de décoration, des massifs de plantes)
	prehistoire = load("res://scripts/prehistoire_v217.gd").new()
	prehistoire.name = "Prehistoire_v217"
	add_child(prehistoire)
	prehistoire.setup(main, ile, _cols)
	# ils ne partent pas tous en même temps
	for k in range(maneges.size()):
		maneges[k].attente = 9.0 + k * 7.0
	_guirlandes()
	_embarquements()
	_actions()


func _etiquette(texte: String, at: Vector3, face: Vector3, taille: float, couleur: Color) -> Label3D:
	var l := Label3D.new()
	l.text = texte
	l.font_size = 96
	l.pixel_size = taille / 96.0
	l.outline_size = 14
	l.modulate = couleur
	l.outline_modulate = Color(0.12, 0.05, 0.03)
	l.double_sided = false
	l.visibility_range_end = 220.0
	add_child(l)
	l.global_position = at
	l.rotation.y = atan2(face.x, face.z)
	return l


## Le Grand Portail : deux tours rayées, la grande enseigne, les ampoules ; le guichet ; le tourniquet.
func _portail() -> void:
	var b := Kit.Lot.new()
	var e: Vector2 = IleScript.ENTREE
	var y0: float = ile.height_l(e.x, e.y)
	portail_pos = _a(e.x, y0, e.y)
	for sg in [-1.0, 1.0]:
		var z: float = e.y + sg * 6.2
		for k in range(7):
			b.box("basalte", Transform3D(Basis(), _a(e.x, y0 + 0.5 + k, z)), Vector3(2.2 - (k % 2) * 0.12, 1.0, 2.2 - (k % 2) * 0.12))
		_cols.box_at(_a(e.x, y0, z), Vector3(2.2, 7.0, 2.2))
		# le toit pointu de la tour, sa boule
		b.cyl("chaume", Transform3D(Basis(), _a(e.x, y0 + 6.9, z)), 2.1, 0.05, 2.8, 9)
		b.blob("ampoule", _a(e.x, y0 + 9.75, z), Vector3(0.22, 0.22, 0.22), 6)
	# l'enseigne, d'une tour à l'autre
	b.box("planches", Transform3D(Basis(), _a(e.x, y0 + 6.2, e.y)), Vector3(0.5, 2.0, 10.4))
	b.box("basalte", Transform3D(Basis(), _a(e.x, y0 + 7.28, e.y)), Vector3(0.6, 0.16, 10.6))
	b.box("basalte", Transform3D(Basis(), _a(e.x, y0 + 5.12, e.y)), Vector3(0.6, 0.16, 10.6))
	for k in range(17):
		for yy in [5.0, 7.42]:
			b.blob("ampoule", _a(e.x - 0.34, y0 + yy, e.y - 4.8 + k * 0.6), Vector3(0.09, 0.09, 0.09), 6)
	_etiquette("ÎLE FORAINE", _a(e.x - 0.27, y0 + 6.2, e.y), Vector3(-1, 0, 0), 1.25, Color(1.0, 0.86, 0.3))
	_etiquette("À bientôt !", _a(e.x + 0.27, y0 + 6.2, e.y), Vector3(1, 0, 0), 1.0, Color(1.0, 0.86, 0.3))
	# le guichet (au nord du passage, côté ponton)
	var g := Vector2(e.x - 7.0, e.y - 9.5)
	var gy: float = ile.height_l(g.x, g.y)
	b.box("planches", Transform3D(Basis(), _a(g.x, gy + 0.55, g.y)), Vector3(2.6, 1.1, 2.6))
	for cx in [-1.2, 1.2]:
		for cz in [-1.2, 1.2]:
			b.box("planches", Transform3D(Basis(), _a(g.x + cx, gy + 1.3, g.y + cz)), Vector3(0.16, 2.6, 0.16))
	b.box("planches", Transform3D(Basis(), _a(g.x, gy + 1.12, g.y + 1.45)), Vector3(2.7, 0.08, 0.5))
	b.box("vitre", Transform3D(Basis(), _a(g.x, gy + 1.85, g.y - 1.25)), Vector3(2.3, 1.4, 0.04))
	b.cyl("chaume", Transform3D(Basis(), _a(g.x, gy + 2.55, g.y)), 2.4, 0.05, 1.45, 9)
	b.blob("ampoule", _a(g.x, gy + 3.98, g.y), Vector3(0.16, 0.16, 0.16), 6)
	_cols.box_at(_a(g.x, gy, g.y), Vector3(2.6, 2.6, 2.6))
	_etiquette("BILLETS", _a(g.x, gy + 2.95, g.y + 1.5), Vector3(0, 0, 1), 0.42, Color(1.0, 0.95, 0.8))
	_etiquette("L'entrée : %d pièces\nle billet vaut pour la journée" % PRIX, _a(g.x, gy + 0.62, g.y + 1.32), Vector3(0, 0, 1), 0.16, Color(1.0, 0.95, 0.8))
	guichet_pos = _a(g.x, gy, g.y + 2.4)
	# le tourniquet : deux bornes, les trois bras qui tournent
	for sg2 in [-1.0, 1.0]:
		b.box("acier", Transform3D(Basis(), _a(e.x, y0 + 0.55, e.y + sg2 * 0.75)), Vector3(1.1, 1.1, 0.3))
		_cols.box_at(_a(e.x, y0, e.y + sg2 * 0.75), Vector3(1.1, 1.1, 0.3))
		# les barrières basses, des bornes aux tours
		b.box("fer", Transform3D(Basis(), _a(e.x, y0 + 0.95, e.y + sg2 * 3.0)), Vector3(0.08, 0.08, 4.2))
		b.box("fer", Transform3D(Basis(), _a(e.x, y0 + 0.5, e.y + sg2 * 3.0)), Vector3(0.08, 0.08, 4.2))
		_cols.box_at(_a(e.x, y0, e.y + sg2 * 3.0), Vector3(0.3, 1.4, 4.2))
	b.commit(self, "Portail_v209", true)
	_bras = Node3D.new()
	_bras.name = "Tourniquet_v209"
	add_child(_bras)
	_bras.global_position = _a(e.x, y0 + 0.95, e.y - 0.55)
	var bb := Kit.Lot.new()
	for k in range(3):
		var dir: Vector3 = Vector3(0, 0, 1).rotated(Vector3(0.0, 0.7, 0.7).normalized(), TAU * k / 3.0)
		bb.tube("acier", Vector3.ZERO, dir * 1.0, 0.035, 6)
	bb.commit(_bras, "Bras", false, 80.0)
	# la barrière (fermée tant qu'on n'a pas de billet)
	var body := StaticBody3D.new()
	body.name = "Barriere_billet_v209"
	body.collision_layer = 1
	body.collision_mask = 0
	_barriere = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.4, 2.6, 1.3)
	_barriere.shape = bs
	body.add_child(_barriere)
	add_child(body)
	body.global_position = _a(e.x, y0 + 1.3, e.y)


## La palissade, du portail jusqu'à la mer, des deux côtés : on entre par le tourniquet.
func _clotures() -> void:
	var b := Kit.Lot.new()
	var e: Vector2 = IleScript.ENTREE
	for sg in [-1.0, 1.0]:
		var prec := Vector2(e.x, e.y + sg * 7.3)
		var k: int = 0
		while k < 60:
			k += 1
			# un arc qui s'écarte vers la côte
			var suiv := Vector2(e.x + 2.0 - k * k * 0.035, e.y + sg * (7.3 + k * 2.5))
			var h0: float = ile.height_l(prec.x, prec.y)
			var h1: float = ile.height_l(suiv.x, suiv.y)
			if h1 < -0.6:
				break
			var a: Vector3 = _a(prec.x, h0, prec.y)
			var c: Vector3 = _a(suiv.x, h1, suiv.y)
			b.cyl("planches", Transform3D(Basis(), a - Vector3.UP * 0.1), 0.09, 0.07, 2.2, 6)
			for yy in [0.5, 1.2, 1.8]:
				b.tube("planches", a + Vector3.UP * yy, c + Vector3.UP * yy, 0.045, 5)
			var mil: Vector3 = (a + c) * 0.5
			var dir: Vector3 = c - a
			_cols.box(Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), mil + Vector3.UP * 1.0), Vector3(0.2, 2.4, dir.length() + 0.1))
			prec = suiv
	b.commit(self, "Clotures_v209", true, 300.0)


## Le quai du Grand Frisson : la rampe, le plancher, le toit de toile rayée, la cabine.
func _gare() -> void:
	var b := Kit.Lot.new()
	var zq: float = Trace.QUAI_Z
	var sol: float = IleScript.SOL
	# le plancher du quai (côté nord : on y monte ; côté sud : une étroite passerelle)
	b.box("planches", Transform3D(Basis(), _a(-77.0, QUAI_Y - 0.12, 65.55)), Vector3(50.0, 0.24, 7.2))
	_cols.box(Transform3D(Basis(), _a(-77.0, QUAI_Y - 0.12, 65.55)), Vector3(50.0, 0.24, 7.2))
	b.box("planches", Transform3D(Basis(), _a(-77.0, QUAI_Y - 0.12, zq + 2.05)), Vector3(50.0, 0.24, 2.3))
	b.box("jaune", Transform3D(Basis(), _a(-77.0, QUAI_Y + 0.005, 68.95)), Vector3(50.0, 0.012, 0.3))
	# les pilotis
	for x in range(-100, -52, 8):
		for z in [62.4, 68.6, zq + 1.4, zq + 2.9]:
			b.box("planches", Transform3D(Basis(), _a(x, (sol + QUAI_Y) * 0.5 - 0.2, z)), Vector3(0.22, QUAI_Y - sol, 0.22))
	# la rampe (depuis l'allée)
	var r0 := Vector3(-78.0, sol - 0.05, 48.0)
	var r1 := Vector3(-78.0, QUAI_Y, 62.0)
	var pente: float = atan2(r1.y - r0.y, r1.z - r0.z)
	var long: float = Vector2(r1.z - r0.z, r1.y - r0.y).length()
	var xr := Transform3D(Basis(Vector3.RIGHT, -pente), _a(-78.0, (r0.y + r1.y) * 0.5 - 0.12, (r0.z + r1.z) * 0.5))
	b.box("planches", xr, Vector3(3.6, 0.24, long))
	_cols.box(xr, Vector3(3.6, 0.24, long))
	for sg in [-1.0, 1.0]:
		b.tube("planches", _a(-78.0 + sg * 1.8, r0.y + 1.0, r0.z), _a(-78.0 + sg * 1.8, r1.y + 1.0, r1.z), 0.05, 6)
		for k in range(6):
			var f: float = k / 5.0
			b.box("planches", Transform3D(Basis(), _a(-78.0 + sg * 1.8, lerpf(r0.y, r1.y, f) + 0.5, lerpf(r0.z, r1.z, f))), Vector3(0.1, 1.0, 0.1))
	# la rambarde du quai (ouverte devant la rampe)
	for seg in [[-102.0, -79.8], [-76.2, -52.0]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		for yy in [0.55, 1.05]:
			b.tube("planches", _a(x0, QUAI_Y + yy, 62.05), _a(x1, QUAI_Y + yy, 62.05), 0.045, 6)
		var nb: int = int((x1 - x0) / 2.4)
		for k in range(nb + 1):
			b.box("planches", Transform3D(Basis(), _a(lerpf(x0, x1, float(k) / nb), QUAI_Y + 0.55, 62.05)), Vector3(0.1, 1.1, 0.1))
		_cols.box(Transform3D(Basis(), _a((x0 + x1) * 0.5, QUAI_Y + 0.7, 62.05)), Vector3(x1 - x0, 1.4, 0.2))
	for xx in [-102.0, -52.0]:
		b.tube("planches", _a(xx, QUAI_Y + 1.05, 62.05), _a(xx, QUAI_Y + 1.05, 68.6), 0.045, 6)
		_cols.box(Transform3D(Basis(), _a(xx, QUAI_Y + 0.7, 65.3)), Vector3(0.2, 1.4, 6.6))
	# le toit : des poteaux, deux pans de toile rayée
	var faite: float = QUAI_Y + 5.6
	var bord: float = QUAI_Y + 3.9
	for x in [-100.0, -84.0, -68.0, -54.0]:
		for z in [61.6, zq + 3.6]:
			b.box("planches", Transform3D(Basis(), _a(x, (sol + bord) * 0.5, z)), Vector3(0.26, bord - sol, 0.26))
		b.tube("planches", _a(x, bord, 61.6), _a(x, faite, 67.6), 0.09, 6)
		b.tube("planches", _a(x, bord, zq + 3.6), _a(x, faite, 67.6), 0.09, 6)
	b.tube("planches", _a(-101.0, faite, 67.6), _a(-53.0, faite, 67.6), 0.1, 6)
	var bande: int = 0
	var x: float = -101.0
	while x < -53.0:
		var key: String = "chaume"
		for pan in [[61.0, 67.6], [zq + 4.2, 67.6]]:
			var za: float = pan[0]
			var zb: float = pan[1]
			var p0: Vector3 = _a(x, bord - 0.1, za)
			var p1: Vector3 = _a(x + 3.0, bord - 0.1, za)
			var p2: Vector3 = _a(x + 3.0, faite + 0.08, zb)
			var p3: Vector3 = _a(x, faite + 0.08, zb)
			var nrm: Vector3 = (p1 - p0).cross(p3 - p0).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			b.quad(key, [p0, p1, p2, p3], nrm, [Vector2(0, 0), Vector2(3, 0), Vector2(3, 7), Vector2(0, 7)])
		x += 3.0
		bande += 1
	# la cabine du machiniste, au bout du quai
	b.box("planches", Transform3D(Basis(), _a(-54.5, QUAI_Y + 0.6, 64.0)), Vector3(2.6, 1.2, 2.6))
	b.box("vitre", Transform3D(Basis(), _a(-54.5, QUAI_Y + 1.8, 64.0)), Vector3(2.5, 1.2, 2.5))
	b.box("planches", Transform3D(Basis(), _a(-54.5, QUAI_Y + 2.5, 64.0)), Vector3(2.9, 0.14, 2.9))
	_cols.box_at(_a(-54.5, QUAI_Y, 64.0), Vector3(2.6, 2.5, 2.6))
	# le panneau des sensations, en haut de la rampe
	b.box("planches", Transform3D(Basis(), _a(-75.0, QUAI_Y + 0.8, 62.6)), Vector3(0.12, 1.6, 0.12))
	b.box("planches", Transform3D(Basis(), _a(-75.0, QUAI_Y + 1.45, 62.6)), Vector3(1.3, 0.7, 0.08))
	reglage_pos = _a(-75.0, QUAI_Y, 63.6)
	b.commit(self, "Gare_v209", true)
	# l'enseigne, au-dessus de la rampe
	var e2 := Kit.Lot.new()
	e2.box("planches", Transform3D(Basis(), _a(-78.0, bord + 0.5, 60.9)), Vector3(11.0, 1.7, 0.2))
	for k in range(19):
		for yy in [-0.75, 0.75]:
			e2.blob("ampoule", _a(-83.4 + k * 0.6, bord + 0.5 + yy, 60.76), Vector3(0.08, 0.08, 0.08), 6)
	e2.commit(self, "Gare_enseigne_v209", false, 300.0)
	_etiquette("LE GRAND FRISSON", _a(-78.0, bord + 0.62, 60.78), Vector3(0, 0, -1), 0.86, Color(1.0, 0.88, 0.35))
	_etiquette("114 km/h · 56 m · une boucle · une vrille", _a(-78.0, bord - 0.02, 60.78), Vector3(0, 0, -1), 0.26, Color(1.0, 0.96, 0.85))


## La Place du Mât : le grand mât, ses guirlandes de fanions, les bancs. (V217 : au Parc du Volcan, des
## poteaux de bois et des fanions couleur de terre, d'ocre, de feuille et d'os.)
func _place() -> void:
	var b := Kit.Lot.new()
	var c: Vector2 = IleScript.PLACE
	var y0: float = ile.height_l(c.x, c.y)
	var pied: Vector3 = _a(c.x, y0, c.y)
	b.cyl("dalles", Transform3D(Basis(), pied), 2.2, 1.9, 0.5, 16)
	b.cyl("planches", Transform3D(Basis(), pied + Vector3.UP * 0.5), 0.24, 0.13, 15.5, 9)
	b.blob("ampoule", pied + Vector3.UP * 16.3, Vector3(0.4, 0.4, 0.4), 8)
	_cols.cyl(pied, 2.0, 1.2)
	var couleurs: Array = ["toile_ocre", "toile_terre", "toile_feuille", "toile_os"]
	for k in range(8):
		var ang: float = TAU * k / 8.0 + 0.2
		var loin := Vector2(c.x + cos(ang) * 21.0, c.y + sin(ang) * 21.0)
		var yl: float = ile.height_l(loin.x, loin.y)
		var poteau: Vector3 = _a(loin.x, yl, loin.y)
		b.cyl("planches", Transform3D(Basis(), poteau), 0.11, 0.08, 4.6, 7)
		b.blob("ampoule", poteau + Vector3.UP * 4.75, Vector3(0.16, 0.16, 0.16), 6)
		_cols.cyl(poteau, 0.15, 2.0)
		_fanions(b, pied + Vector3.UP * 15.6, poteau + Vector3.UP * 4.5, 26, couleurs, 2.2)
		# un banc entre deux poteaux
		if k % 2 == 1:
			var bp := Vector2(c.x + cos(ang) * 15.0, c.y + sin(ang) * 15.0)
			var by: float = ile.height_l(bp.x, bp.y)
			var xf := Transform3D(Basis(Vector3.UP, -ang + PI * 0.5), _a(bp.x, by, bp.y))
			b.box("planches", xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.8, 0.07, 0.45))
			b.box("planches", xf * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.8, 0.26)), Vector3(1.8, 0.4, 0.06))
			for sx in [-0.8, 0.8]:
				b.box("fer", xf * Transform3D(Basis(), Vector3(sx, 0.22, 0.0)), Vector3(0.07, 0.45, 0.45))
			_cols.box(xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.8, 0.6, 0.5))
	b.commit(self, "Place_v209", true, 420.0)


## Une guirlande de fanions, tendue de a à c (elle pend au milieu)
func _fanions(b: Kit.Lot, a: Vector3, c: Vector3, nb: int, couleurs: Array, fleche: float) -> void:
	var prec: Vector3 = a
	var dir: Vector3 = (c - a)
	var cote: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	for k in range(1, nb + 1):
		var f: float = float(k) / nb
		var p: Vector3 = a.lerp(c, f) - Vector3.UP * fleche * 4.0 * f * (1.0 - f)
		b.tube("fer", prec, p, 0.012, 3)
		var m: Vector3 = (prec + p) * 0.5
		var demi: Vector3 = (p - prec) * 0.36
		var nrm: Vector3 = cote.cross(Vector3.UP).normalized()
		b.tri(str(couleurs[k % couleurs.size()]), [m - demi, m + demi, m - Vector3.UP * 0.55], [nrm, nrm, nrm], [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)])
		prec = p


## Les baraques de l'allée (fermées pour l'instant : les stands ouvriront plus tard). V217 : le Parc du
## Volcan est au temps des dinosaures : des huttes, des peaux tendues, des poteaux de bois, un toit de chaume
## (avant : des toiles rayées de cirque, rouge, bleu, jaune et blanc).
func _baraques() -> void:
	var b := Kit.Lot.new()
	var toiles: Array = [["peau_claire", "peau_sombre"], ["peau_sombre", "peau_claire"]]
	var k: int = 0
	for spot in [[-128.0, 9.0], [-112.0, 9.0], [-128.0, 31.0], [-112.0, 31.0], [-56.0, 9.0], [-40.0, 9.0]]:
		var x: float = spot[0]
		var z: float = spot[1]
		var y0: float = ile.height_l(x, z)
		var vers: float = 1.0 if z < 20.0 else -1.0          # la façade regarde l'allée
		var t: Array = toiles[k % toiles.size()]
		# le comptoir, les montants
		b.box("planches", Transform3D(Basis(), _a(x, y0 + 0.5, z + vers * 2.0)), Vector3(5.6, 1.0, 0.3))
		for cx in [-2.8, 2.8]:
			for cz in [-2.0, 2.0]:
				b.cyl("planches", Transform3D(Basis(), _a(x + cx, y0 - 0.1, z + cz)), 0.12, 0.1, 3.05, 7)
		# le fond et les côtés de toile, le rideau baissé sur la façade
		b.box(str(t[1]), Transform3D(Basis(), _a(x, y0 + 1.4, z - vers * 2.0)), Vector3(5.6, 2.8, 0.04))
		for cx2 in [-2.8, 2.8]:
			b.box(str(t[1]), Transform3D(Basis(), _a(x + cx2, y0 + 1.4, z)), Vector3(0.04, 2.8, 4.0))
		for bande in range(8):
			b.box(str(t[bande % 2]), Transform3D(Basis(), _a(x - 2.45 + bande * 0.7, y0 + 1.9, z + vers * 1.96)), Vector3(0.7, 1.8, 0.03))
		# le toit pointu, rayé
		for bande2 in range(8):
			var a0: float = TAU * bande2 / 8.0 + PI / 8.0
			var a1: float = TAU * (bande2 + 1) / 8.0 + PI / 8.0
			var p0: Vector3 = _a(x + cos(a0) * 4.2, y0 + 2.75, z + sin(a0) * 3.3)
			var p1: Vector3 = _a(x + cos(a1) * 4.2, y0 + 2.75, z + sin(a1) * 3.3)
			var top: Vector3 = _a(x, y0 + 4.9, z)
			var nrm: Vector3 = (p1 - p0).cross(top - p0).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			b.tri("chaume", [p0, p1, top], [nrm, nrm, nrm], [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)])
		b.blob("ampoule", _a(x, y0 + 5.0, z), Vector3(0.14, 0.14, 0.14), 6)
		_cols.box_at(_a(x, y0, z), Vector3(5.6, 2.8, 4.0))
		k += 1
	b.commit(self, "Baraques_v209", true, 380.0)


# =================================================================== le billet, le quai

func jour() -> int:
	return int(main.temps_v56.day_count) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 1


func billet_valide() -> bool:
	return int(state.get("billet_jour", -1)) == jour()


func offrir_billet() -> void:
	state["billet_jour"] = jour()


func acheter_billet() -> bool:
	if billet_valide():
		main._show_message_v28("Vous avez déjà votre billet pour aujourd'hui. Bonne fête !")
		return false
	var inv: Node = main.get("inventory_v28")
	var bourse: int = int(inv.count("piece")) if inv != null else 0
	if bourse < PRIX:
		main._show_message_v28("L'entrée coûte %d pièces — il vous en manque %d." % [PRIX, PRIX - bourse])
		if main.has_method("sfx"):
			main.sfx("ui_erreur")
		return false
	inv.remove("piece", PRIX)
	state["billet_jour"] = jour()
	state["billets"] = int(state.get("billets", 0)) + 1
	if main.has_method("sfx"):
		main.sfx("ramasse_pieces")
	main._show_message_v28("Un billet pour l'Île Foraine (%d pièces) : il vaut pour toute la journée. Passez le tourniquet !" % PRIX)
	return true


func monter() -> bool:
	if huit == null or riding():
		return false
	if not billet_valide():
		main._show_message_v28("Il faut un billet pour monter : le guichet est à l'entrée, près du Grand Portail.")
		return false
	if not huit.a_quai():
		main._show_message_v28("Le train est en route… il revient à quai dans un instant.")
		return false
	if not huit.monter(bool(state.get("doux", false))):
		return false
	main._show_message_v28("Au premier rang du Grand Frisson ! La barre se baisse… %s" % ("(en douceur : l'horizon reste droit)" if bool(state.get("doux", false)) else "(toutes les sensations)"))
	return true


## V210 : monter dans un des manèges à sensations
func monter_manege(m: Node3D) -> bool:
	if m == null or riding():
		return false
	if not billet_valide():
		main._show_message_v28("Il faut un billet pour monter : le guichet est à l'entrée, près du Grand Portail.")
		return false
	if not m.a_quai():
		main._show_message_v28("%s est en marche… il s'arrête dans un instant." % str(m.titre))
		return false
	if not m.monter(bool(state.get("doux", false))):
		return false
	main._show_message_v28("%s ! Le harnais se referme… %s" % [str(m.titre), "(en douceur : l'horizon reste droit)" if bool(state.get("doux", false)) else "(toutes les sensations)"])
	return true


func manege(cle: String) -> Node3D:
	for m in maneges:
		if str(m.cle) == cle:
			return m
	return null


func _a_bord() -> Node3D:
	if huit != null and bool(huit.a_bord):
		return huit
	for m in maneges:
		if bool(m.a_bord):
			return m
	return null


func changer_sensations() -> void:
	state["doux"] = not bool(state.get("doux", false))
	if main.has_method("sfx"):
		main.sfx("ui_choix")
	main._show_message_v28("Sensations : %s" % ("en douceur — la vue reste droite, sans se pencher ni se retourner." if bool(state["doux"]) else "toutes — la vue penche et se retourne avec le wagon, comme en vrai."))


## V214 : la fête manquait de couleur. Le long de toutes les allées, des portiques de mâts rayés,
## une guirlande de lampions de cinq couleurs en travers et des fanions d'un portique au suivant.
## Rien dans la Place (elle a ses guirlandes), rien contre la voie du grand huit ni sur les parois.
func _guirlandes() -> void:
	var b := Kit.Lot.new()
	var teintes: Array = ["lampion_rouge", "lampion_jaune", "lampion_bleu", "lampion_vert", "lampion_orange"]
	var toiles: Array = ["toile_ocre", "toile_terre", "toile_feuille", "toile_os"]
	var n: int = 0
	for c in IleScript.ALLEES:
		var pts: Array = c[0]
		var demi: float = float(c[1]) + 1.1
		var reste: float = 6.0
		var prec: Array = []
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var z := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var l: float = a.distance_to(z)
			var d: Vector2 = (z - a) / maxf(l, 0.01)
			var cote := Vector2(-d.y, d.x)
			var s: float = reste
			while s < l:
				var m: Vector2 = a + d * s
				s += 15.0
				var g: Vector2 = m - cote * demi
				var dr: Vector2 = m + cote * demi
				var y0: float = ile.height_l(m.x, m.y)
				var yg: float = ile.height_l(g.x, g.y)
				var yd: float = ile.height_l(dr.x, dr.y)
				var libre: bool = m.distance_to(IleScript.PLACE) > IleScript.PLACE_R + 3.0 and y0 > 1.0
				libre = libre and absf(yg - y0) < 1.2 and absf(yd - y0) < 1.2
				# pas de mât planté au milieu d'une autre allée (aux croisements)
				for c2 in IleScript.ALLEES:
					if c2 != c and (IleScript._dist_ligne(g, c2[0]) < float(c2[1]) + 0.7 or IleScript._dist_ligne(dr, c2[0]) < float(c2[1]) + 0.7):
						libre = false
				var hg: Vector3 = _a(g.x, yg + 5.2, g.y)
				var hd: Vector3 = _a(dr.x, yd + 5.2, dr.y)
				if libre and volcan != null and volcan.has_method("_a_la_voie"):
					libre = float(volcan._a_la_voie(Vector3(m.x, y0, m.y), y0 + 9.0)) > 7.0   # (repère de l'île, comme la voie)
				if not libre:
					prec = []
					continue
				for cote_k in range(2):
					var pied: Vector3 = _a(g.x, yg, g.y) if cote_k == 0 else _a(dr.x, yd, dr.y)
					for an in range(5):
						b.cyl("planches", Transform3D(Basis(), pied + Vector3.UP * (0.52 + an * 1.04)), 0.1 - an * 0.004, 0.1 - (an + 1) * 0.004, 1.04, 7, false)
					b.blob("basalte", pied + Vector3.UP * 5.32, Vector3(0.19, 0.17, 0.19), 6)
					_cols.cyl(pied, 0.14, 2.2)
				# la guirlande de lampions en travers de l'allée
				var av: Vector3 = hg
				for k in range(1, 10):
					var f: float = k / 9.0
					var q: Vector3 = hg.lerp(hd, f) - Vector3.UP * 0.9 * 4.0 * f * (1.0 - f)
					b.tube("fer", av, q, 0.012, 3)
					if k < 9:
						b.blob(str(teintes[(k + n) % teintes.size()]), q - Vector3.UP * 0.2, Vector3(0.16, 0.2, 0.16), 6)
						lampions["lampions"] = int(lampions["lampions"]) + 1
					av = q
				# les fanions depuis le portique d'avant
				if prec.size() == 2:
					_fanions(b, prec[0], hg, 14, toiles, 0.7)
					_fanions(b, prec[1], hd, 14, toiles, 0.7)
				prec = [hg, hd]
				n += 1
			reste = s - l
	lampions["portiques"] = n
	b.commit(self, "Guirlandes_v214", false, 320.0)
	print("ILE_MANGA_V214: la fête en couleur : %d portiques, %d lampions le long des allées" % [n, int(lampions["lampions"])])


## V214 : on ne savait pas où monter. Chaque attraction a sa borne à l'endroit exact : un disque
## lumineux au sol, une flèche qui danse au-dessus et un panneau lisible de loin, verts quand on peut
## monter, jaunes s'il manque le billet, orange pendant que le manège tourne.
func _embarquements() -> void:
	var liste: Array = [huit] + maneges
	for r in liste:
		var at: Vector3 = r.quai_pos
		var sous_toit: bool = r == huit          # la gare a un toit : la borne y est plus basse et plus petite
		var bas: float = 1.5 if sous_toit else 0.0
		var ech: float = 0.6 if sous_toit else 1.0
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.3, 1.0, 0.45, 0.55)
		var disque := MeshInstance3D.new()
		disque.name = "Borne_disque_v214"
		var dm := CylinderMesh.new()
		dm.top_radius = 1.6
		dm.bottom_radius = 1.6
		dm.height = 0.03
		dm.radial_segments = 28
		disque.mesh = dm
		disque.material_override = mat
		disque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(disque)
		disque.global_position = at + Vector3(0, 0.05, 0)
		var fleche := MeshInstance3D.new()
		fleche.name = "Borne_fleche_v214"
		var fm := CylinderMesh.new()
		fm.top_radius = 0.8 * ech
		fm.bottom_radius = 0.0
		fm.height = 1.4 * ech
		fm.radial_segments = 4
		fleche.mesh = fm
		fleche.material_override = mat
		fleche.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fleche)
		fleche.global_position = at + Vector3(0, 3.3 - bas * 0.6, 0)
		var l := Label3D.new()
		l.name = "Borne_panneau_v214"
		l.text = "MONTER ICI"
		l.font_size = 96
		l.pixel_size = 0.95 * ech / 96.0
		l.outline_size = 22
		l.outline_modulate = Color(0.05, 0.05, 0.06)
		l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		l.visibility_range_end = 160.0
		add_child(l)
		l.global_position = at + Vector3(0, 5.4 - bas, 0)
		bornes.append({"manege": r, "mat": mat, "fleche": fleche, "panneau": l, "disque": disque, "y": at.y + 3.3 - bas * 0.6, "etat": ""})
	_bornes(0.0, true)


## l'état d'une borne : "pret", "billet", "marche"
func etat_borne(k: int) -> String:
	var r: Node3D = bornes[k]["manege"]
	if not r.a_quai():
		return "marche"
	return "pret" if billet_valide() else "billet"


func _bornes(delta: float, forcer: bool = false) -> void:
	_borne_t += delta
	var a_bord: bool = riding()
	for k in range(bornes.size()):
		var b: Dictionary = bornes[k]
		var fl: MeshInstance3D = b["fleche"]
		fl.global_position.y = float(b["y"]) + sin(_borne_t * 2.6 + k) * 0.18
		fl.rotation.y = _borne_t * 1.4
		var e: String = "bord" if a_bord else etat_borne(k)
		if e == str(b["etat"]) and not forcer:
			continue
		b["etat"] = e
		var voir: bool = e != "bord"
		fl.visible = voir
		(b["disque"] as MeshInstance3D).visible = voir
		var l: Label3D = b["panneau"]
		l.visible = voir
		var c := Color(0.3, 1.0, 0.45)
		var t: String = "MONTER ICI"
		if e == "billet":
			c = Color(1.0, 0.86, 0.2)
			t = "BILLET AU GUICHET\n(au Grand Portail)"
		elif e == "marche":
			c = Color(1.0, 0.55, 0.15)
			t = "EN MARCHE\nrevient ici"
		l.text = t
		l.modulate = c
		(b["mat"] as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 0.55)


func _actions() -> void:
	var me = self
	_interactions.append({"id": "fo_guichet", "pos": guichet_pos, "radius": 2.6, "text": "E : acheter un billet (%d pièces)" % PRIX,
		"vr": "Gâchette : acheter un billet (%d pièces)" % PRIX, "call": func(): me.acheter_billet(),
		"when": func(): return not me.billet_valide()})
	_interactions.append({"id": "fo_monter", "pos": huit.quai_pos, "radius": 4.2, "text": "E : monter dans le Grand Frisson",
		"vr": "Gâchette : monter dans le Grand Frisson", "call": func(): me.monter(),
		"when": func(): return me.huit != null and not me.riding() and me.huit.a_quai()})
	_interactions.append({"id": "fo_attendre", "pos": huit.quai_pos, "radius": 4.2, "text": "Le Grand Frisson est en route… il revient à quai",
		"vr": "Le Grand Frisson est en route… il revient à quai", "call": func(): me.monter(),
		"when": func(): return me.huit != null and not me.riding() and not me.huit.a_quai()})
	_interactions.append({"id": "fo_sensations", "pos": reglage_pos, "radius": 1.8, "text": "E : régler les sensations",
		"vr": "Gâchette : régler les sensations", "call": func(): me.changer_sensations(),
		"when": func(): return me.huit != null and not me.riding()})
	for m in maneges:
		var mm: Node3D = m
		_interactions.append({"id": "fo_monter_%s" % str(mm.cle), "pos": mm.quai_pos, "radius": 3.4, "text": "E : monter — %s" % str(mm.titre),
			"vr": "Gâchette : monter — %s" % str(mm.titre), "call": func(): me.monter_manege(mm),
			"when": func(): return not me.riding() and mm.a_quai()})
		_interactions.append({"id": "fo_attendre_%s" % str(mm.cle), "pos": mm.quai_pos, "radius": 3.4, "text": "%s tourne… il s'arrête dans un instant" % str(mm.titre),
			"vr": "%s tourne… il s'arrête dans un instant" % str(mm.titre), "call": func(): me.monter_manege(mm),
			"when": func(): return not me.riding() and not mm.a_quai()})


# =================================================================== les manèges qui nous portent

func riding() -> bool:
	return _a_bord() != null


func ride_interact() -> void:
	var m: Node3D = _a_bord()
	if m != null:
		m.descendre_avant_depart()


func ride_prompt() -> String:
	var m: Node3D = _a_bord()
	return str(m.texte()) if m != null else ""


func ride_safe_pos() -> Vector3:
	var m: Node3D = _a_bord()
	return m.lieu_sur() if m != null else respawn_point()[0]


# =================================================================== les repères des autres

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	return ile.height(p.x, p.z) > -1.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func hostile_zone(_p: Vector3) -> bool:
	return false


func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	if l.distance_to(IleScript.DOCK_A.lerp(IleScript.DOCK_B, 0.5)) < 24.0:
		return "fo_ponton"
	if ile.height(p.x, p.z) < -0.42 and p.y < 2.0:
		return "" if ile.coast_q(l.x, l.y) > 1.12 else "fo_plage"
	if l.distance_to(IleScript.ENTREE) < 20.0:
		return "fo_entree"
	if Vector2((l.x - IleScript.GARE.x) * 0.5, l.y - IleScript.GARE.y - 4.0).length() < 14.0:
		return "fo_quai"
	if l.distance_to(CHUTE_AT) < 14.0:
		return "fo_chute"
	if l.distance_to(MARTEAU_AT) < 16.0:
		return "fo_marteau"
	if l.distance_to(BALANCOIRE_AT) < 18.0:
		return "fo_balancoire"
	if l.distance_to(IleScript.BUTTE) < IleScript.BUTTE_R * 0.75:
		return "fo_butte"
	if l.distance_to(IleScript.PLACE) < IleScript.PLACE_R + 6.0:
		return "fo_place"
	if ile.coast_q(l.x, l.y) > 0.9:
		return "fo_plage"
	return "fo_esplanade"


func place_name(p: Vector3) -> String:
	return "Île Foraine, " + str(PLACES.get(zone_at(p), "l'île"))


func village_point(id: String) -> Array:
	if ile == null:
		return []
	if id == "foraine_quai":
		return [_a(-78.0, QUAI_Y + 0.3, 64.5), Vector3(0, 0, 1)]
	# V210 : devant chaque manège (à quelques pas de l'embarquement)
	for pair in [["foraine_marteau", "marteau"], ["foraine_chute", "chute"], ["foraine_balancoire", "balancoire"]]:
		if id == str(pair[0]):
			var m: Node3D = manege(str(pair[1]))
			return [m.quai_pos, m.quai_face] if m != null else []
	return respawn_point()


## Devant le Grand Portail, côté ponton
func respawn_point() -> Array:
	var q: Vector3 = _w(IleScript.ENTREE.x - 12.0, IleScript.ENTREE.y, 0.3)
	return [q, Vector3(1, 0, 0)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… On vous a porté à l'ombre du Grand Portail, avec un verre de limonade. On se sent tout de suite mieux.")


func register_services(journal: Node) -> void:
	journal.lieux["foraine"] = respawn_point()[0]
	if _registered:
		return
	var dj: Node = main.get("donjon_v35")
	if dj == null:
		return
	_registered = true
	for e in _interactions:
		dj._interactions.append(e)


func _process(delta: float) -> void:
	if main == null or ile == null or not _built:
		return
	if main.get("game_started") != null and not bool(main.game_started):
		return
	if not main.has_method("_player_pos_v27"):
		return
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.3 and p.y < 40.0:
		state["visite"] = true
		main._show_message_v28("L'Île Foraine — l'île des sensations fortes. Le guichet est près du Grand Portail ; pour monter dans une attraction, allez sur son disque vert, sous la flèche.")
	_bornes(delta)
	if huit != null:
		state["tours"] = maxi(int(state.get("tours", 0)), int(huit.tours))
	for m in maneges:
		state[str(m.cle)] = maxi(int(state.get(str(m.cle), 0)), int(m.tours))
	# la barrière du tourniquet : ouverte avec un billet (ou quand on est déjà dans la fête)
	var dedans: bool = p.x > portail_pos.x + 0.4
	if _barriere != null:
		_barriere.disabled = billet_valide() or dedans
	# les bras tournent quand on passe
	if _bras != null:
		if absf(p.x - portail_pos.x) < 1.0 and absf(p.z - portail_pos.z) < 1.0:
			if _bras_t <= 0.0 and main.has_method("sfx"):
				main.sfx("tourniquet", portail_pos + Vector3.UP)
			_bras_t = 0.8
		if _bras_t > 0.0:
			_bras_t -= delta
			_bras.rotate(Vector3(0.0, 0.7, 0.7).normalized(), delta * TAU / 3.0 / 0.8)


func trouvailles() -> Dictionary:
	return {"foraine": 1 if bool(state["visite"]) else 0,
		"fo_billet": 1 if int(state.get("billets", 0)) > 0 or int(state.get("billet_jour", -1)) >= 0 else 0,
		"fo_tour": 1 if int(state.get("tours", 0)) > 0 else 0,
		"fo_marteau": 1 if int(state.get("marteau", 0)) > 0 else 0,
		"fo_chute": 1 if int(state.get("chute", 0)) > 0 else 0,
		"fo_balancoire": 1 if int(state.get("balancoire", 0)) > 0 else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(dd: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if dd.has(k):
			state[k] = dd[k]
	if huit != null:
		huit.lacher()
		huit.tours = int(state.get("tours", 0))
	for m in maneges:
		m.lacher()
		m.tours = int(state.get(str(m.cle), 0))

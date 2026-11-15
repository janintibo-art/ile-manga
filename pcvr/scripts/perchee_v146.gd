extends Node3D
## V146 : l'Île Perchée et son bourg, Pile-ou-Face (le module) : une grande île flottante du Far West à
## 270 m au-dessus de la mer, au sud de Hautefond. On y monte de deux façons :
##  - la Navette des Nuées (un dirigeable rayé comme un chapiteau) : du Mât des Nuées de Hautefond (au
##    bout d'un ponton suspendu au-dessus de la falaise du sud) au Quai des Nuées (à l'est de l'île) ;
##  - la Grande Chaîne : du Ponton de la Chaîne (sur la mer, où la barque peut s'amarrer) à la Potence
##    (au bord sud-est), dans une cage de fer qui monte le long d'une chaîne géante.
## Là-haut : le bourg (ses saloons, ses tripots, ses boutiques ; les tables de jeu viendront ensuite), la
## prairie, les mesas, le ruisseau et sa chute, l'Abreuvoir, et les habitants (des gens… particuliers).
## Comme l'Île des Géants : setup, build_island (le relief), build_town (le reste, après l'heure du
## jour), spawn_npcs, contains / walkable / zone_at / place_name, serialize / load_data.

const IleScript = preload("res://scripts/ile_perchee_v146.gd")
const Bourg = preload("res://scripts/perchee_bourg_v146.gd")
const Kit = preload("res://scripts/perchee_kit_v146.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const Chaine = preload("res://scripts/chaine_v146.gd")
const Navette = preload("res://scripts/navette_v146.gd")
const Lieux147 = preload("res://scripts/lieux_perchee_v147.gd")
const HautefondIle = preload("res://scripts/ile_hautefond_v112.gd")
const FLORE := "res://scripts/perchee_flore_v146.gd"
const HABITANTS := "res://scripts/pnj/perchee_habitants_v146.gd"
const PNJ := "res://scripts/pnj/pnj_montjoie_v71.gd"

const PLACES := {"pp_quai": "le Quai des Nuées", "pp_bourg": "Pile-ou-Face", "pp_place": "la place de la Roue", "pp_potence": "la Potence de la Grande Chaîne",
	"pp_ponton": "le Ponton de la Chaîne", "pp_vieux_pic": "le Vieux-Pic", "pp_corbeaux": "la Mesa des Corbeaux", "pp_ruisseau": "le ruisseau de l'Orpailleur",
	"pp_chute": "la Chute de l'Orpailleur", "pp_abreuvoir": "l'Abreuvoir", "pp_prairie": "la prairie", "pp_bord": "le bord de l'île", "pp_dessous": "sous l'île",
	"pp_chapelle": "la chapelle Notre-Dame-des-Nuées", "pp_corral": "le corral", "pp_mat": "le Mât des Nuées de Hautefond"}
## Le Mât des Nuées de Hautefond : sur la falaise du sud de Hautefond (repère de Hautefond, en degrés et
## en mètres depuis son centre), le ponton suspendu avance au-dessus de la mer.
const MAT_DEG: float = 80.0
const MAT_R: float = 232.0
const MAT_AVANCE: float = 14.0

var main: Node
var ile: Node3D
var flore: Node3D
var bourg_root: Node3D
var chaine: Node3D
var navette: Node3D
var pc: bool = true
var state: Dictionary = {}
var habitants: Array = []
var by_id: Dictionary = {}
var tournants: Array = []                 # [nœud, axe local, vitesse (rad/s)]
var cheminees: Array = []                 # Vector3 : le haut des cheminées
var lampes: Array = []                    # Vector3 : les lanternes, les réverbères
var lampes_rue: Array = []
var portes: Array = []                    # {id, porte, out, seuil, lieu, maison, w, d, etages, nom}
var reperes: Dictionary = {}
var roue: Node3D
var tableau := Vector3.ZERO
var points: Dictionary = {}               # les nœuds où marchent les habitants
var graph: Dictionary = {}
var spots: Dictionary = {}                # les lieux des habitants {pos, face, pose, node}
var lieux: Dictionary = {}
var quai := Vector3.ZERO                  # le plancher du Quai des Nuées (le milieu de l'aire)
var mat_hf := Vector3.ZERO                # le plancher du Mât des Nuées de Hautefond
var potence := Vector3.ZERO               # le quai de la Potence (en haut de la Grande Chaîne)
var ponton := Vector3.ZERO                # le Ponton de la Chaîne (sur la mer)
var _claims: Dictionary = {}
var _clock: float = 0.0
var _built: bool = false
var _near: bool = false
var _interactions: Array = []
var _fumees: Array = []
var _rng := RandomNumberGenerator.new()
var _pepites_ok: bool = false
var _cran: int = -1                       # le cran de la Roue sous le cliquet (le « clac »)
var pepites: Array = []                   # Vector3 : les pépites d'or du ruisseau (on les ramasse une fois)


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 14646
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "navette": 0, "chaine": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_perchee_v146"
	add_child(ile)
	ile.build(pc)


## La jetée du Ponton de la Chaîne (où la barque s'amarre) : [a, b], du ponton vers le large.
func dock() -> Array:
	var d: Vector3 = _dehors_chaine()
	var side: Vector3 = d.cross(Vector3.UP).normalized()
	var c: Vector3 = _chaine_axe() * Vector3(1, 0, 1) - d * 6.0
	return [c + side * 8.8 + Vector3.UP * 1.0, c + side * 22.0 + Vector3.UP * 1.0]


func build_all() -> void:
	build_island()
	build_town()


## Après le relief et l'heure du jour : le bourg, la végétation, la Grande Chaîne, la Navette.
func build_town() -> void:
	if _built:
		return
	_built = true
	var t0: int = Time.get_ticks_msec()
	bourg_root = Node3D.new()
	bourg_root.name = "Pile_ou_Face"
	add_child(bourg_root)
	Bourg.build(self)
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_perchee_v146"
		add_child(flore)
		flore.plante(ile, pc)
	_acces()
	_fumees_cheminees()
	_lumieres()
	_reseau()
	print("ILE_MANGA_V146: Pile-ou-Face est prêt (%d ms) : %d bâtiments, %d lampes" % [Time.get_ticks_msec() - t0, portes.size(), lampes.size()])


# =================================================================== l'accès : la Grande Chaîne, la Navette

func _dehors_chaine() -> Vector3:
	return Vector3(cos(IleScript.CHAINE_ANGLE), 0, sin(IleScript.CHAINE_ANGLE))


## L'axe de la Grande Chaîne (monde, à la hauteur du bord) : au bout de la Potence.
func _chaine_axe() -> Vector3:
	var a: float = IleScript.CHAINE_ANGLE
	var r: float = ile.coast_radius(a) + 9.0
	return IleScript.W(cos(a) * r, sin(a) * r)


func _acces() -> void:
	var b := Kit.Lot.new()
	var cols := GK.Cols.new(self, "Perchee_acces_collisions")
	# --- la Potence : une plate-forme de planches qui dépasse du bord, une poutre de fer, le treuil
	var d: Vector3 = _dehors_chaine()
	var side: Vector3 = d.cross(Vector3.UP).normalized()
	var a: float = IleScript.CHAINE_ANGLE
	var rr: float = ile.coast_radius(a)
	var bord: Vector3 = IleScript.W(cos(a) * (rr - 14.0), sin(a) * (rr - 14.0))
	var y_top: float = ile.height(bord.x, bord.z) + 0.35
	var axe: Vector3 = _chaine_axe()
	axe.y = y_top
	potence = axe - d * 3.4
	var yaw: float = atan2(d.x, d.z)
	var pxf := Transform3D(Basis(Vector3.UP, yaw), (bord + axe) * 0.5 * Vector3(1, 0, 1) + Vector3.UP * y_top)
	var plen: float = Vector2(axe.x - bord.x, axe.z - bord.z).length() + 4.0
	b.box("planches", pxf * Transform3D(Basis(), Vector3(0, -0.12, 0)), Vector3(12.0, 0.24, plen))
	b.box("fer", pxf * Transform3D(Basis(), Vector3(0, -0.7, 0)), Vector3(10.0, 0.9, plen))
	cols.box(pxf * Transform3D(Basis(), Vector3(0, -0.5, 0)), Vector3(12.0, 1.0, plen))
	# le garde-corps (sauf devant les cages)
	for s in [-1.0, 1.0]:
		b.box("fer", pxf * Transform3D(Basis(), Vector3(s * 5.9, 0.55, 0)), Vector3(0.08, 0.08, plen))
		b.box("fer", pxf * Transform3D(Basis(), Vector3(s * 5.9, 1.05, 0)), Vector3(0.1, 0.1, plen))
		cols.box(pxf * Transform3D(Basis(), Vector3(s * 5.9, 0.6, 0)), Vector3(0.2, 1.2, plen))
		for k in range(int(plen / 1.5)):
			b.box("fer", pxf * Transform3D(Basis(), Vector3(s * 5.9, 0.5, -plen * 0.5 + k * 1.5)), Vector3(0.06, 1.0, 0.06))
	b.box("fer", pxf * Transform3D(Basis(), Vector3(0, 1.05, plen * 0.5 - 0.1)), Vector3(1.2, 0.1, 0.1))
	# les jambes de force sous la plate-forme, jusqu'à la roche
	for s2 in [-1.0, 1.0]:
		b.tube("fer", axe + side * s2 * 5.0 + Vector3.DOWN * 1.0, bord + side * s2 * 5.0 + Vector3.DOWN * 9.0 + Vector3.UP * (y_top - bord.y), 0.3, 6)
	# le portique du treuil : quatre montants, deux poutres, un toit de tôle
	for s3 in [-1.0, 1.0]:
		for s4 in [-1.0, 1.0]:
			b.tube("fer", axe + side * s3 * 5.2 + d * s4 * 1.6 + Vector3.DOWN * 0.1, axe + side * s3 * 4.4 + d * s4 * 1.2 + Vector3.UP * 7.5, 0.18, 6)
			cols.cyl(axe + side * s3 * 5.0 + d * s4 * 1.5, 0.25, 7.0)
	b.box("fer", Transform3D(Basis(Vector3.UP, yaw), axe + Vector3.UP * 7.6), Vector3(10.4, 0.6, 3.2))
	b.box("tole", Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.12), axe + Vector3.UP * 8.6), Vector3(11.4, 0.1, 5.0))
	Kit.panneau(b, self, Transform3D(Basis(Vector3.UP, yaw + PI), axe + Vector3.UP * 6.6 - d * 1.75), 6.0, 0.8, "LA GRANDE CHAÎNE", "enseigne_fond")
	# --- le Ponton de la Chaîne, sur la mer : un plancher sur des flotteurs, des bites d'amarrage
	ponton = Vector3(axe.x, 1.0, axe.z) - d * 3.4
	var tx := Transform3D(Basis(Vector3.UP, yaw), Vector3(axe.x, 0.55, axe.z) - d * 6.0)
	b.box("planches", tx * Transform3D(Basis(), Vector3(0, 0.33, 0)), Vector3(18.0, 0.24, 14.0))
	b.box("planches_sombres", tx * Transform3D(Basis(), Vector3(0, -0.1, 0)), Vector3(17.0, 0.7, 13.0))
	cols.box(tx * Transform3D(Basis(), Vector3(0, -0.4, 0)), Vector3(18.0, 1.6, 14.0))
	for k2 in range(6):
		var bx: float = -7.5 + k2 * 3.0
		b.cyl("fer", tx * Transform3D(Basis(), Vector3(bx, 0.45, -6.6)), 0.18, 0.15, 0.6, 8)
		b.cyl("tonneau", tx * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(bx, -0.2, 0)), 0.6, 0.6, 13.0, 10)
	# le contrepoids (la poulie du bas) et un petit abri
	for k3 in range(2):
		b.cyl("fer", Transform3D(Basis(), Vector3(axe.x, 1.0, axe.z) + side * (2.7 if k3 == 0 else -2.7) + dehors_bas(d)), 1.1, 1.1, 0.5, 14)
	b.box("bardage_bleu", tx * Transform3D(Basis(), Vector3(6.0, 1.75, -4.0)), Vector3(4.0, 2.8, 3.0))
	b.prism("tole", tx * Vector3(3.8, 3.15, -5.6), tx * Vector3(8.2, 3.15, -5.6), tx * Vector3(6.0, 4.0, -5.6), tx.basis * Vector3(0, 0, 3.2))
	cols.box(tx * Transform3D(Basis(), Vector3(6.0, 1.75, -4.0)), Vector3(4.0, 2.8, 3.0))
	Kit.panneau(b, self, tx * Transform3D(Basis(), Vector3(6.0, 2.4, -2.45)), 3.6, 0.7, "PONTON DE LA CHAÎNE", "enseigne_creme")
	b.commit(self, "Perchee_chaine", true, 1500.0)
	chaine = Chaine.new()
	chaine.name = "Grande_chaine_v146"
	add_child(chaine)
	chaine.setup(main, Vector3(axe.x, 1.0, axe.z), axe, d)
	# --- le Quai des Nuées : une aire de planches au-delà du bord est, un kiosque, un mât d'amarrage
	var qa: float = IleScript.QUAI_ANGLE
	var qr: float = ile.coast_radius(qa)
	var qd := Vector3(cos(qa), 0, sin(qa))
	var qside: Vector3 = qd.cross(Vector3.UP).normalized()
	var qbord: Vector3 = IleScript.W(cos(qa) * (qr - 12.0), sin(qa) * (qr - 12.0))
	var qy: float = ile.height(qbord.x, qbord.z) + 0.35
	quai = IleScript.W(cos(qa) * (qr + 16.0), sin(qa) * (qr + 16.0))
	quai.y = qy
	var qyaw: float = atan2(qd.x, qd.z)
	var qxf := Transform3D(Basis(Vector3.UP, qyaw), (qbord + quai) * 0.5 * Vector3(1, 0, 1) + Vector3.UP * qy)
	var qlen: float = Vector2(quai.x - qbord.x, quai.z - qbord.z).length() + 14.0
	_aire(b, cols, qxf, 26.0, qlen)
	var mxf := Transform3D(Basis(Vector3.UP, qyaw), quai + qd * 14.0 + qside * 10.0)
	_mat_amarrage(b, cols, mxf)
	var kxf := Transform3D(Basis(Vector3.UP, qyaw + PI * 0.5), qbord + qside * 8.0 + Vector3.UP * (qy - qbord.y))
	_kiosque(b, cols, kxf, "QUAI DES NUÉES\nNAVETTE POUR HAUTEFOND")
	b.commit(self, "Perchee_quai", true, 1500.0)
	# --- le Mât des Nuées de Hautefond : le ponton suspendu au-dessus de la falaise du sud
	var hd := Vector2(cos(deg_to_rad(MAT_DEG)), sin(deg_to_rad(MAT_DEG)))
	var hbord: Vector3 = HautefondIle.W(hd.x * (MAT_R - 6.0), hd.y * (MAT_R - 6.0))
	var hh: float = _hautefond_h(hbord)
	mat_hf = HautefondIle.W(hd.x * (MAT_R + MAT_AVANCE), hd.y * (MAT_R + MAT_AVANCE))
	mat_hf.y = hh + 0.35
	var hdir := Vector3(hd.x, 0, hd.y)
	var hside: Vector3 = hdir.cross(Vector3.UP).normalized()
	var hyaw: float = atan2(hdir.x, hdir.z)
	var hxf := Transform3D(Basis(Vector3.UP, hyaw), (hbord + mat_hf) * 0.5 * Vector3(1, 0, 1) + Vector3.UP * (hh + 0.35))
	var hlen: float = Vector2(mat_hf.x - hbord.x, mat_hf.z - hbord.z).length() + 14.0
	_aire(b, cols, hxf, 26.0, hlen)
	# les jambes de force jusqu'au pied de la falaise
	for s5 in [-1.0, 1.0]:
		for f in [0.2, 0.75]:
			var top: Vector3 = hbord.lerp(mat_hf, f) * Vector3(1, 0, 1) + hside * s5 * 11.0 + Vector3.UP * (hh - 0.5)
			b.tube("fer", top, top * Vector3(1, 0, 1) - hdir * 18.0 * (1.0 - f) + Vector3.UP * -6.0, 0.35, 6)
	_mat_amarrage(b, cols, Transform3D(Basis(Vector3.UP, hyaw), mat_hf + hdir * 14.0 - hside * 10.0))
	_kiosque(b, cols, Transform3D(Basis(Vector3.UP, hyaw + PI * 0.5), hbord + hside * 8.0 + Vector3.UP * (hh + 0.35 - hbord.y)), "MÂT DES NUÉES\nNAVETTE POUR L'ÎLE PERCHÉE")
	b.commit(self, "Perchee_mat_hautefond", true, 1500.0)
	navette = Navette.new()
	navette.name = "Navette_des_nuees_v146"
	add_child(navette)
	navette.height_fn = func(x: float, z: float) -> float:
		var h1: float = ile.height(x, z)
		return maxf(h1 if h1 > -1e6 else 0.0, _hautefond_h(Vector3(x, 0, z)))
	navette.setup(main, [mat_hf, quai])


## (la poulie du bas est juste sous la cage : rien à décaler)
func dehors_bas(_d: Vector3) -> Vector3:
	return Vector3.DOWN * 0.6


func _hautefond_h(p: Vector3) -> float:
	var hf: Node = main.get("hautefond_v112") if main != null else null
	if hf != null and hf.get("ile") != null and hf.ile != null:
		return float(hf.ile.height(p.x, p.z))
	return 12.0


## Une aire d'amarrage : un grand plancher, ses solives, ses garde-corps (ouverts du côté de la terre).
func _aire(b: Kit.Lot, cols: GK.Cols, xf: Transform3D, w: float, l: float) -> void:
	b.box("planches", xf * Transform3D(Basis(), Vector3(0, -0.12, 0)), Vector3(w, 0.24, l))
	for k in range(int(l / 3.0) + 1):
		b.box("poutre", xf * Transform3D(Basis(), Vector3(0, -0.55, -l * 0.5 + k * 3.0)), Vector3(w, 0.6, 0.3))
	b.box("fer", xf * Transform3D(Basis(), Vector3(0, -1.2, 0)), Vector3(w * 0.5, 0.8, l))
	cols.box(xf * Transform3D(Basis(), Vector3(0, -0.5, 0)), Vector3(w, 1.0, l))
	for s in [-1.0, 1.0]:
		b.box("fer", xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.1), 1.05, 0)), Vector3(0.1, 0.1, l))
		cols.box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.1), 0.6, 0)), Vector3(0.2, 1.2, l))
		for k2 in range(int(l / 1.6)):
			b.box("fer", xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.1), 0.52, -l * 0.5 + k2 * 1.6)), Vector3(0.06, 1.04, 0.06))
	b.box("fer", xf * Transform3D(Basis(), Vector3(0, 1.05, l * 0.5 - 0.1)), Vector3(w, 0.1, 0.1))
	cols.box(xf * Transform3D(Basis(), Vector3(0, 0.6, l * 0.5 - 0.1)), Vector3(w, 1.2, 0.2))
	# des lanternes aux coins
	for s2 in [-1.0, 1.0]:
		var at: Vector3 = xf * Vector3(s2 * (w * 0.5 - 0.6), 0, l * 0.5 - 0.6)
		lampes.append(Kit.reverbere(b, cols, at))


## Le mât d'amarrage : une tour de fer en treillis, une plate-forme, un cône de laiton, une manche à air.
func _mat_amarrage(b: Kit.Lot, cols: GK.Cols, xf: Transform3D) -> void:
	var h: float = 16.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.tube("fer", xf * Vector3(sx * 2.0, -0.2, sz * 2.0), xf * Vector3(sx * 0.6, h, sz * 0.6), 0.12, 5)
	for k in range(6):
		var y: float = 1.5 + k * 2.5
		var r: float = 2.0 - y / h * 1.4
		for e in [[Vector3(-r, y, -r), Vector3(r, y + 2.5, -r)], [Vector3(r, y, -r), Vector3(r, y + 2.5, r)], [Vector3(r, y, r), Vector3(-r, y + 2.5, r)], [Vector3(-r, y, r), Vector3(-r, y + 2.5, -r)]]:
			b.tube("fer", xf * e[0], xf * e[1], 0.05, 4)
	cols.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(3.6, h, 3.6))
	b.cyl("planches", xf * Transform3D(Basis(), Vector3(0, h, 0)), 1.6, 1.6, 0.2, 12)
	b.cyl("laiton", xf * Transform3D(Basis(), Vector3(0, h + 0.2, 0)), 0.9, 0.2, 1.6, 12)
	b.tube("fer", xf * Vector3(0, h + 1.8, 0), xf * Vector3(0, h + 4.0, 0), 0.05, 4)
	b.cyl("toile_rouge", xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.1, h + 3.7, 0)), 0.3, 0.12, 1.8, 10)
	b.cyl("lampe", xf * Transform3D(Basis(), Vector3(0, h + 1.85, 0)), 0.14, 0.14, 0.2, 8)


## Le kiosque à billets (on n'y paie rien : la navette est gratuite, le panneau dit les horaires).
func _kiosque(b: Kit.Lot, cols: GK.Cols, xf: Transform3D, txt: String) -> void:
	b.box("bardage_rouge", xf * Transform3D(Basis(), Vector3(0, 1.4, 0)), Vector3(3.2, 2.8, 2.4))
	b.box("planches_sombres", xf * Transform3D(Basis(), Vector3(0, 1.1, 1.25)), Vector3(2.4, 0.1, 0.4))
	b.box("vitre_on", xf * Transform3D(Basis(), Vector3(0, 1.9, 1.21)), Vector3(2.2, 1.1, 0.04))
	b.prism("tole", xf * Vector3(-2.0, 2.8, -1.6), xf * Vector3(2.0, 2.8, -1.6), xf * Vector3(0, 3.6, -1.6), xf.basis * Vector3(0, 0, 3.4))
	cols.box(xf * Transform3D(Basis(), Vector3(0, 1.4, 0)), Vector3(3.2, 2.8, 2.4))
	Kit.panneau(b, self, xf * Transform3D(Basis(), Vector3(0, 3.0, 1.3)), 3.6, 0.9, txt, "enseigne_fond")


# =================================================================== la vie du bourg

func _fumees_cheminees() -> void:
	var n: int = 0
	for c in cheminees:
		if n >= (8 if pc else 4):
			break
		var s := CPUParticles3D.new()
		s.amount = 10
		s.lifetime = 6.0
		s.direction = Vector3(0.2, 1, 0.1)
		s.spread = 12.0
		s.initial_velocity_min = 1.4
		s.initial_velocity_max = 2.4
		s.gravity = Vector3(0.6, 0.15, 0.2)
		s.scale_amount_min = 1.2
		s.scale_amount_max = 2.4
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 0.4))
		curve.add_point(Vector2(1.0, 1.8))
		s.scale_amount_curve = curve
		var qm := QuadMesh.new()
		qm.size = Vector2(1.4, 1.4)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.8, 0.8, 0.8, 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		if ResourceLoader.exists("res://assets/textures/ciel/nuage.png"):
			m.albedo_texture = load("res://assets/textures/ciel/nuage.png")
		qm.material = m
		s.mesh = qm
		s.visibility_aabb = AABB(Vector3(-20, -5, -20), Vector3(40, 50, 40))
		add_child(s)
		s.global_position = c
		_fumees.append(s)
		n += 1


## La nuit : les fenêtres, les lanternes ; quelques vraies lumières dans la grand-rue.
func _lumieres() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		return
	t.register_glow(Kit.mat("vitre_on"), 2.2, 0.05)
	t.register_glow(Kit.mat("lampe"), 3.0, 0.3)
	var n: int = 0
	for p in lampes_rue:
		if n >= (8 if pc else 3):
			break
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.76, 0.46)
		l.omni_range = 13.0
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		add_child(l)
		l.global_position = p
		t.register_lamp(l, 1.8)
		n += 1


# =================================================================== les chemins des habitants

func _pt(nom: String, p: Vector3) -> String:
	points[nom] = p
	return nom


func _link(a: String, b: String) -> void:
	if a == b or not points.has(a) or not points.has(b):
		return
	for pair in [[a, b], [b, a]]:
		if not graph.has(pair[0]):
			graph[pair[0]] = []
		if not (graph[pair[0]] as Array).has(pair[1]):
			(graph[pair[0]] as Array).append(pair[1])


func _sol(x: float, z: float, dy: float = 0.05) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	var h: float = ile.height(w.x, w.z)
	w.y = (h if h > -1e6 else IleScript.Y0) + dy
	return w


func _spot(nom: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	spots[nom] = {"pos": pos, "face": face.normalized(), "pose": pose, "node": node}


## Le réseau : la grand-rue (tous les 10 m), la rue du Pique, le chemin du Quai et celui de la Potence ;
## chaque porte est reliée à la rue ; les lieux des habitants (comptoirs, trottoirs, place).
func _reseau() -> void:
	var prev: String = ""
	var x: float = -44.0
	while x <= 214.0:
		var nm: String = _pt("rue_%d" % int(x), _sol(x, 0.0))
		if prev != "":
			_link(prev, nm)
		prev = nm
		x += 10.0
	var prev2: String = ""
	var z: float = -90.0
	while z <= 90.0:
		var nm2: String = _pt("pique_%d" % int(z), _sol(IleScript.PIQUE_X, z))
		if prev2 != "":
			_link(prev2, nm2)
		if absf(z) < 1.0:
			_link(nm2, "rue_56")
			_link(nm2, "rue_66")
		prev2 = nm2
		z += 10.0
	# le Quai des Nuées, la Potence, le chemin de la Potence
	_pt("quai", quai + Vector3.UP * 0.05)
	_link("quai", prev)
	var pts: Array = []
	var p0: Vector3 = points["pique_90"]
	for k in range(1, 6):
		var q: Vector3 = p0.lerp(potence, float(k) / 6.0)
		var lq: Vector2 = IleScript.L(q.x, q.z)
		pts.append(_pt("vers_potence_%d" % k, _sol(lq.x, lq.y)))
	pts.append(_pt("potence", potence + Vector3.UP * 0.05))
	for k2 in range(pts.size()):
		_link(pts[k2], "pique_90" if k2 == 0 else pts[k2 - 1])
	# les portes
	for e in portes:
		var pn: String = _pt("porte_" + str(e["id"]), (e["porte"] as Vector3) + Vector3.UP * 0.05)
		var best: String = ""
		var bd: float = INF
		for k3 in points:
			if str(k3).begins_with("rue_") or str(k3).begins_with("pique_"):
				var dd: float = (points[k3] as Vector3).distance_to(points[pn])
				if dd < bd:
					bd = dd
					best = str(k3)
		_link(pn, best)
		# le lieu de l'habitant de la boutique : sur le trottoir, devant sa porte
		var seuil: Vector3 = e["seuil"]
		var out: Vector3 = e["out"]
		var side: Vector3 = out.cross(Vector3.UP).normalized()
		_spot("devant_" + str(e["id"]), seuil + out * 0.9 + side * 1.6, out, "debout", pn)
		_spot("comptoir_" + str(e["id"]), seuil + out * 1.1 - side * 1.4, out, "bras_croises", pn)
	# la place de la Roue, le tableau, la chapelle, l'Abreuvoir
	var c: Vector3 = _sol(IleScript.PLACE.x, IleScript.PLACE.y)
	for k4 in range(4):
		var a: float = TAU * k4 / 4.0 + PI / 4.0
		_spot("banc_%d" % k4, c + Vector3(cos(a) * 13.5, 0.0, sin(a) * 13.5), Vector3(cos(a), 0, sin(a)), "assis", "rue_56" if cos(a) < 0.0 else "rue_66")
	_spot("place_roue", c + Vector3(0, 0, 7.0), Vector3(0, 0, -1), "observer", "rue_56")
	_spot("tableau", tableau + Vector3(0.6, 0.05, 1.4), Vector3(-0.3, 0, -1), "lire", "rue_56")
	_spot("potence_quai", potence + _dehors_chaine() * -2.0 + Vector3.UP * 0.05, _dehors_chaine(), "bras_croises", "potence")
	_spot("quai_kiosque", quai - Vector3(cos(IleScript.QUAI_ANGLE), 0, sin(IleScript.QUAI_ANGLE)) * 18.0 + Vector3(0, 0.05, 6.0), Vector3(1, 0, 0), "debout", "quai")
	if reperes.has("chapelle"):
		var ch: Vector3 = reperes["chapelle"]
		_pt("chapelle", ch)
		_link("chapelle", "pique_-90")
		_spot("chapelle", ch + Vector3(1.5, 0.05, 1.0), Vector3(0, 0, -1), "debout", "chapelle")
	var ab: Vector3 = _sol(IleScript.ABREUVOIR.x + 18.0, IleScript.ABREUVOIR.y - 6.0)
	_pt("abreuvoir", ab)
	_link("abreuvoir", "rue_-44")
	_spot("abreuvoir", ab + Vector3(-3.0, 0, 1.0), Vector3(-1, 0, 0.3), "observer", "abreuvoir")


# =================================================================== pour les habitants (le gestionnaire)

func spot(nom: String) -> Dictionary:
	return spots.get(nom, {})


func spot_free(nom: String, who: Node) -> bool:
	var c: Variant = _claims.get(nom, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(nom: String, who: Node) -> void:
	_claims[nom] = who


func release_spot(nom: String, who: Node) -> void:
	if _claims.get(nom, null) == who:
		_claims.erase(nom)


func hostile_zone(_p: Vector3) -> bool:
	return false


func concert_on() -> bool:
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func spawn_npcs() -> void:
	if not habitants.is_empty() or not _built or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if points.has(home) else "rue_56"
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {}) if main.get("pending_pnj_v31") != null else {}
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V146: %d habitants à Pile-ou-Face" % habitants.size())


# =================================================================== les repères des autres

func contains(p: Vector3) -> bool:
	if ile == null:
		return false
	if p.y > IleScript.Y0 - IleScript.DEPTH - 30.0 and ile.near_xz(p.x, p.z, 40.0):
		return true
	return false


## Là-haut : la terre ferme, les plates-formes (la Potence, le Quai) ; pas le vide.
func walkable(p: Vector3) -> bool:
	if riding():
		return true
	var h: float = ile.height(p.x, p.z)
	if h > -1e6 and p.y > h - 3.0:
		return true
	if _sur_plateforme(p):
		return true
	return false


func _sur_plateforme(p: Vector3) -> bool:
	for c in [[quai, 30.0], [potence, 16.0]]:
		var q: Vector3 = c[0]
		if q != Vector3.ZERO and Vector2(p.x - q.x, p.z - q.z).length() < float(c[1]) and absf(p.y - q.y) < 6.0:
			return true
	return false


## Sur une plate-forme hors de l'île, au-dessus de la mer : le Mât des Nuées (à Hautefond, au-delà de la
## falaise) et le Ponton de la Chaîne (sur l'eau) ; la limite des îles ne s'y applique pas.
func on_platform(p: Vector3) -> bool:
	if mat_hf != Vector3.ZERO:
		var hd := Vector3(cos(deg_to_rad(MAT_DEG)), 0, sin(deg_to_rad(MAT_DEG)))
		var rel: Vector3 = p - mat_hf
		var along: float = rel.dot(hd)
		var across: float = absf(rel.dot(hd.cross(Vector3.UP)))
		if along > -22.0 and along < 8.0 and across < 13.0 and absf(rel.y) < 4.0:
			return true
	if ponton != Vector3.ZERO:
		var d: Vector3 = _dehors_chaine()
		var c: Vector3 = Vector3(ponton.x, 1.0, ponton.z) - d * 2.6
		var rel2: Vector3 = p - c
		if absf(rel2.dot(d)) < 7.2 and absf(rel2.dot(d.cross(Vector3.UP))) < 9.2 and rel2.y > -1.5 and rel2.y < 4.0:
			return true
	return false


func owns_point(p: Vector3) -> bool:
	return ile != null and (contains(p) and p.y > IleScript.Y0 - 40.0 or _pres_ponton(p))


func _pres_ponton(p: Vector3) -> bool:
	return ponton != Vector3.ZERO and Vector2(p.x - ponton.x, p.z - ponton.z).length() < 26.0 and p.y < 12.0


func zone_at(p: Vector3) -> String:
	if ile == null:
		return ""
	if _pres_ponton(p):
		return "pp_ponton"
	if mat_hf != Vector3.ZERO and Vector2(p.x - mat_hf.x, p.z - mat_hf.z).length() < 26.0 and absf(p.y - mat_hf.y) < 20.0:
		return "pp_mat"
	if not contains(p) or p.y < IleScript.Y0 - 40.0:
		return ""
	if quai != Vector3.ZERO and Vector2(p.x - quai.x, p.z - quai.z).length() < 30.0:
		return "pp_quai"
	if potence != Vector3.ZERO and Vector2(p.x - potence.x, p.z - potence.z).length() < 16.0:
		return "pp_potence"
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -1e6 or p.y < h - 6.0:
		return "pp_dessous"
	if l.distance_to(IleScript.PLACE) < IleScript.PLACE_R + 4.0:
		return "pp_place"
	if l.distance_to(Vector2(IleScript.PIQUE_X, -100.0)) < 16.0:
		return "pp_chapelle"
	if l.distance_to(Vector2(150.0, 46.0)) < 16.0:
		return "pp_corral"
	if (l.x > -48.0 and l.x < 168.0 and absf(l.y) < 34.0) or (absf(l.x - IleScript.PIQUE_X) < 28.0 and l.y > -114.0 and l.y < 96.0):
		return "pp_bourg"
	var m0: Array = IleScript.MESAS[0]
	if l.distance_to(m0[0]) < float(m0[1]) + 14.0:
		return "pp_vieux_pic"
	var m1: Array = IleScript.MESAS[1]
	if l.distance_to(m1[0]) < float(m1[1]) + 12.0:
		return "pp_corbeaux"
	if l.distance_to(IleScript.ABREUVOIR) < IleScript.ABREUVOIR_R + 12.0:
		return "pp_abreuvoir"
	var rd: Vector2 = ile.ruisseau_dist(l)
	if rd.x < 9.0:
		return "pp_chute" if rd.y > 0.88 else "pp_ruisseau"
	if l.length() > ile.coast_radius(atan2(l.y, l.x)) - 14.0:
		return "pp_bord"
	return "pp_prairie"


func place_name(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "pp_mat":
		return "Hautefond, " + str(PLACES[z])
	return "Île Perchée, " + str(PLACES.get(z, "l'île"))


func village_point(id: String) -> Array:
	match id:
		"perchee":
			var q: Vector3 = _sol(IleScript.PLACE.x - 26.0, 3.0, 0.3)
			return [q, Vector3(1, 0, 0)]
		"perchee_ponton":
			return [ponton + Vector3(0, 0.3, 0) - _dehors_chaine() * 2.0, -_dehors_chaine()]
		"perchee_mat":
			return [mat_hf + Vector3.UP * 0.3 - Vector3(cos(deg_to_rad(MAT_DEG)), 0, sin(deg_to_rad(MAT_DEG))) * 12.0, Vector3(cos(deg_to_rad(MAT_DEG)), 0, sin(deg_to_rad(MAT_DEG)))]
	return []


func respawn_point() -> Array:
	return [_sol(IleScript.PLACE.x - 14.0, 16.0, 0.3), Vector3(1, 0, -1).normalized()]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… On vous a porté sur un banc de la place de la Roue, à l'ombre, avec une salsepareille bien fraîche. Doc Cornemuse a joué un air de cornemuse « pour réveiller les esprits ». Ça marche, hélas.")


# =================================================================== monter, descendre

func riding() -> bool:
	return (navette != null and navette.riding) or (chaine != null and chaine.riding >= 0)


func ride_prompt() -> String:
	if navette != null and navette.riding:
		return "E : descendre de la Navette" if navette.docked else ""
	return ""


func ride_interact() -> void:
	if navette != null and navette.riding and navette.docked:
		navette.leave()


func ride_safe_pos() -> Vector3:
	if navette != null and navette.riding:
		return navette.safe_pos()
	if chaine != null and chaine.riding >= 0:
		return chaine.safe_pos()
	return respawn_point()[0]


func register_services(journal: Node) -> void:
	journal.lieux["perchee"] = respawn_point()[0]
	journal.lieux["pp_ponton"] = ponton
	journal.lieux["pp_quai"] = quai
	lieux = {"pp_quai": quai, "pp_ponton": ponton}
	register_interactions()


func register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null or not _interactions.is_empty():
		return
	var I: Array = d._interactions
	var ni := {"id": "navette_monter", "pos": Vector3.INF, "radius": 3.2, "text": "E : monter à bord de la Navette des Nuées", "vr": "Gâchette : monter à bord de la Navette",
		"call": _board_navette, "when": func(): return navette != null and navette.docked and not navette.riding}
	I.append(ni)
	_interactions.append(ni)
	for k in range(2):
		var ci := {"id": "chaine_%d" % k, "pos": Vector3.INF, "radius": 2.8, "text": "E : monter dans la cage de la Grande Chaîne", "vr": "Gâchette : monter dans la cage",
			"call": func(): _board_chaine(k), "when": func(): return chaine != null and chaine.riding < 0 and chaine.at_station(k) != ""}
		I.append(ci)
		_interactions.append(ci)
	for e in portes:
		if str(e["lieu"]) == "" or Lieux147.has("pp_" + str(e["lieu"])):
			continue
		var de: Dictionary = e
		I.append({"id": "pp_porte_" + str(e["id"]), "pos": (e["porte"] as Vector3) + Vector3.UP * 0.4, "radius": 1.6, "text": "E : pousser la porte", "vr": "Gâchette : pousser la porte",
			"call": func(): _porte_lieu(de)})


## Les portes des lieux (les tables de jeu y viendront ; en attendant, la porte dit ce qui se prépare).
const PORTES_FERMEES := {
}


func _porte_lieu(e: Dictionary) -> void:
	var lieu: String = str(e["lieu"])
	if PORTES_FERMEES.has(lieu):
		main._show_message_v28(str(PORTES_FERMEES[lieu]))
	else:
		main._show_message_v28("%s : la porte est fermée pour l'instant." % str(e["nom"]))


func _board_navette() -> void:
	navette.board()
	state["navette"] = int(state["navette"]) + 1


func _board_chaine(k: int) -> void:
	chaine.board(k)
	state["chaine"] = int(state["chaine"]) + 1


func _physics_process(_delta: float) -> void:
	if _interactions.size() >= 3:
		(_interactions[0] as Dictionary)["pos"] = navette.door_pos()
		for k in range(2):
			(_interactions[k + 1] as Dictionary)["pos"] = chaine.cage_floor(k) + Vector3.UP * 0.4


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var pres: bool = ile.near_xz(p.x, p.z, 260.0) and p.y > IleScript.Y0 - 260.0
	if pres:
		for t in tournants:
			var n: Node3D = t[0]
			if is_instance_valid(n):
				n.rotate_object_local(t[1], float(t[2]) * delta)
	for f in _fumees:
		(f as CPUParticles3D).emitting = pres
	# le cliquet de la Roue claque à chaque cran, quand on est sur la place
	if roue != null and is_instance_valid(roue):
		var cran: int = int(floor(fposmod(roue.rotation.x, TAU) / (TAU / 24.0)))
		if cran != _cran:
			if _cran >= 0 and p.distance_to(roue.global_position) < 34.0 and main.has_method("sfx"):
				main.sfx("cliquet_roue", roue.global_position + Vector3.UP * 4.2)
			_cran = cran
	# le filet de sécurité : tombé du bord, on se réveille sur la place (pas dans la mer, 270 m plus bas)
	if contains(p) and not riding() and not _en_vol() and p.y < IleScript.Y0 - 25.0 and p.y > IleScript.Y0 - IleScript.DEPTH and not _pres_ponton(p):
		var h: float = ile.height(p.x, p.z)
		if h < -1e6 and not _sur_plateforme(p):
			_rattrape()
			return
	if not contains(p) or p.y < IleScript.Y0 - 40.0:
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -1e6 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île Perchée — Pile-ou-Face, la ville qui mise. Ici, on joue tout : son chapeau, son dîner, sa réputation… et parfois sa moustache.")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if _built and not _pepites_ok:
		_pepites_ok = true
		_pepites()
	var z: String = zone_at(p)
	if z != "" and not bool((state["visites"] as Dictionary).get(z, false)):
		state["visites"][z] = true
		match z:
			"pp_place":
				main._show_message_v28("La place de la Roue : la Roue de la Fortune tourne toute seule, jour et nuit. On dit qu'elle s'arrête quand quelqu'un a de la chance.")
			"pp_chute":
				main._show_message_v28("La Chute de l'Orpailleur : le ruisseau tombe de l'île jusqu'à la mer. On dit qu'il roule des paillettes d'or.")
			"pp_vieux_pic":
				main._show_message_v28("Le Vieux-Pic : une mesa de grès rouge, rayée comme un gâteau. Les corbeaux y tiennent conseil.")
			"pp_dessous":
				main._show_message_v28("Sous l'île : les Pierres-de-Ciel, d'énormes cristaux pris dans des cages de fer. Ce sont elles qui portent tout ça.")


## Les pépites d'or du ruisseau de l'Orpailleur : sur ses berges, de la source jusqu'à la Chute.
func _pepites() -> void:
	var inv: Node = main.get("inventory_v28")
	pepites.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 14699
	var n: int = IleScript.RUISSEAU.size()
	for i in range(8):
		var t: float = (float(i) + 0.5) / 8.0 * float(n - 2)
		var k: int = int(t)
		var a: Vector2 = IleScript.RUISSEAU[k]
		var c: Vector2 = IleScript.RUISSEAU[k + 1]
		var q: Vector2 = a.lerp(c, t - k)
		var side := Vector2(-(c - a).y, (c - a).x).normalized() * (2.3 if i % 2 == 0 else -2.3)
		var w: Vector3 = _sol(q.x + side.x, q.y + side.y, 0.06)
		pepites.append(w)
		if inv == null or not inv.ITEMS.has("pepite_or"):
			continue
		var uid: String = "pp_pepite_%d" % i
		if inv.taken.has(uid):
			continue
		inv.spawn_pickup(uid, "pepite_or", 1, w)


## En vol (Ventaile, l'aéronef, les ailes de l'atelier) : le filet ne s'en mêle pas.
func _en_vol() -> bool:
	for k in ["ciel_v54", "aeronef_v76"]:
		var n: Variant = main.get(k)
		if n != null and n is Object and is_instance_valid(n):
			var r: Variant = (n as Object).get("riding")
			if r is bool and r:
				return true
	return false


func _rattrape() -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Ouf ! Le grand filet de Pile-ou-Face, tendu sous le bord, vous a rattrapé ; on vous a remonté au treuil jusqu'à la place. Ici, on perd parfois sa mise, jamais ses visiteurs.")


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	return {"perchee": 1 if bool(state["visite"]) else 0,
		"pp_navette": 1 if int(state["navette"]) > 0 else 0,
		"pp_chaine": 1 if int(state["chaine"]) > 0 else 0}


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if navette != null:
		d["navette_escale"] = navette.serialize()
	return d


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	if navette != null and d.get("navette_escale") is Dictionary:
		navette.load_data(d["navette_escale"])
	_pepites_ok = false

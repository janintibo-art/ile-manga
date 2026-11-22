extends Node
## V193 : Port-Boucan, la nuit, en « Public averti » (public_v111.gd). En « Tout public », rien de tout ceci
## ne se voit ni ne s'entend : le nœud est caché, les gens qu'il pose sont éteints, les invites se taisent.
##  - ROCK'N'ROLL, à la Halle Hurlante : le bar de Sirène sert la Hurlante (une blonde maison : la tireuse à
##    trois becs, les fûts, l'ardoise des prix ; la pinte : objets_v66.COMPTOIRS_AVERTI) ; pendant les
##    concerts, les paroles des Rats de Cale défilent (trois chansons, une par soir) ; Rouille arrose la fosse
##    de bière ; et l'on peut se jeter de la scène dans la foule (le SLAM : la foule porte le héros à bout de
##    bras jusqu'à la régie) ;
##  - DROGUES : sur le toit de la Conserverie, la nuit, quatre habitués fument en cercle (la fumée, le joint
##    qui passe, une bouffée de temps en temps, des phrases qui flottent) ; le RIEUR, le champignon de Mère
##    Morille (champignons_v75 : il ne pousse qu'en Public averti), fait « tripper » : le monde respire, les
##    couleurs coulent, les sons s'étirent (trip()) ;
##  - SEXE (suggéré, jamais montré) : des couples d'adultes qui s'embrassent dans les coins (sous la mezzanine,
##    près de l'entrée de la Halle, sur le toit de la Conserverie), des répliques qui en disent long, l'affiche
##    « Ici, on se respecte » dans la Halle, et une porte de chambre de la Conserverie avec son écriteau.
## Les gens de la nuit (des figurants, pnj/figurant_v81) sont posés la première fois qu'on vient la nuit en
## Public averti ; jamais d'enfants parmi eux. Ils sont là de 20 h à 4 h.
## Les poses (s'enlacer, porter le joint à la bouche) : Pose193, un SkeletonModifier3D qui agit après
## l'animation (une petite IK à deux os pour les bras, la tête qui se tourne et s'incline).

const Public = preload("res://scripts/public_v111.gd")
const Mats = preload("res://scripts/boucan_mats_v75.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const NUIT_DEBUT: float = 20.0
const NUIT_FIN: float = 4.0
const SLAM_DUREE: float = 8.0
const TRIP_MONTEE: float = 8.0
const TRIP_DESCENTE: float = 12.0

## Les chansons des Rats de Cale (une par soir, en boucle pendant le concert)
const CHANSONS := [
	["« LISSE-CENTER, MON CUL ! »",
		"Ils veulent un parking à la place de nos cœurs — Lisse-Center, mon cul !",
		"Quatre cents boutiques et pas un seul sourire — Lisse-Center, mon cul !",
		"On a des palettes, des guitares et des chiens — et vous, vous n'avez rien !",
		"Range ta cravate, fais-en une corde à sauter !",
		"Ici on vit, on crie, on s'aime et on partage — Lisse-Center, mon cul !"],
	["« BIÈRE TIÈDE ET CŒUR BRÛLANT »",
		"Une bière tiède, un cœur brûlant, la fosse qui sent le chien mouillé…",
		"Je t'ai embrassé derrière l'ampli, tu avais le goût du gingembre !",
		"Tes lèvres, ma crête, nos sueurs mélangées — personne ne dort ce soir !",
		"Demain on aura mal partout — ce soir on est immortels !",
		"Une bière tiède, un cœur brûlant — et l'aube qui peut bien attendre !"],
	["« PERSONNE NE DORT À PORT-BOUCAN »",
		"Personne ne dort à Port-Boucan — les rats chantent plus fort que nous !",
		"Pas de patrons, pas de badges, juste des potes et du bruit !",
		"Si tu tombes on te relève — si tu pleures on monte le son !",
		"Ta mère a appelé, elle veut qu'on baisse — ON MONTE !",
		"Personne ne dort à Port-Boucan — et surtout pas avec toi !"],
]

const LIGNES_COUPLE := [
	"Chez toi ou chez moi ? … Ah oui. On habite la même Conserverie.",
	"Tu as le goût de la Hurlante.",
	"Et toi de la limonade à la violette. Viens là.",
	"Ne regarde pas, on est occupés à s'aimer.",
	"Encore un. Juste un. … Bon. Encore deux.",
	"Ton piercing s'est accroché à mon bonnet. On ne bouge plus. On reste comme ça. Pour toujours.",
	"On rentre ? J'ai une collection de vinyles. Enfin. On ne va pas vraiment les écouter.",
	"Hé, le curieux ! Va danser dans la fosse : toi aussi, tu trouveras quelqu'un.",
	"Tes mains sont gelées. Mets-les là. … Non, pas là. … Bon, d'accord, là.",
	"Je t'aime. … C'est la bière qui parle. … Non. C'est moi.",
]
const LIGNES_FUMEURS := [
	"Tu savais que les étoiles, c'est juste des trous dans le noir ? … Wouah.",
	"Passe-le à gauche, c'est la tradition. … Ta gauche ou ma gauche ?",
	"J'ai faim. J'ai TELLEMENT faim. Lentille a laissé de la soupe ?",
	"Le toit, il bouge, ou c'est moi ? … C'est toi. Le toit, il est en brique.",
	"Mamie Barricade dit qu'avant, c'était plus fort. Elle dit ça de tout.",
	"Écoute… On entend la mer. … Non. C'est le frigo de la Cantine.",
	"Si les mouettes avaient des guitares, elles feraient du punk. Obligé.",
	"Tu veux t'asseoir ? Il y a de la place dans le cercle. Il y a toujours de la place dans le cercle.",
	"Doucement, toi. Tu vas encore tousser jusqu'à demain.",
	"J'ai eu une idée géniale. … Je l'ai perdue. Elle était géniale, je te jure.",
]
const LIGNES_TRIP := [
	"Le sol respire. Doucement. Comme un gros chat endormi. Tu n'oses plus marcher trop fort.",
	"Tes mains sont devenues très intéressantes. Tu les regardes depuis… combien de temps, déjà ?",
	"Les couleurs ont un goût. Le violet, c'est la réglisse. Évidemment.",
	"Tu ris. Tu ne sais pas pourquoi. C'est encore plus drôle de ne pas savoir pourquoi.",
	"Le ciel a une texture de velours. Tu voudrais le caresser.",
	"Une mouette te regarde. Elle sait. Elle sait TOUT.",
	"La musique est devenue un escalier. Tu montes dedans.",
	"Tout va bien. Tout est doux. Respire. Il suffit de respirer.",
]

var main: Node
var bo: Node                              # boucan_v75
var root: Node3D                          # tout ce qui est posé (caché en Tout public)
var averti: bool = false
var nuit: bool = false
var halle_xf := Transform3D.IDENTITY
var conserverie_xf := Transform3D.IDENTITY
var toit_y: float = 0.0
var couples: Array = []                   # [figurant A, figurant B]
var fumeurs: Array = []                   # {fig, pose (Pose193), joint (Node3D), t, w}
var gens_poses: bool = false
var slam_ia: Dictionary = {}
var trip_on: bool = false
var trip_t: float = -1.0
var slams: int = 0
var douches: int = 0
var _t: float = 0.0
var _tick: float = 0.0
var _parole_t: float = 4.0
var _parole_i: int = 0
var _douche_t: float = 30.0
var _brume: CPUParticles3D
var _slam_t: float = -1.0
var _slam_a := Vector3.ZERO
var _slam_b := Vector3.ZERO
var _trip_layer: CanvasLayer
var _trip_mat: ShaderMaterial
var _trip_line_t: float = 6.0
var _trip_fx: Array = []                  # les effets ajoutés au bus Master (on les retire à la fin)
var _trip_sat: float = -1.0
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	bo = manager
	_rng.seed = 19301
	root = Node3D.new()
	root.name = "Averti_v193"
	bo.add_child(root)
	if bo.city == null or bo.city.get("lieux") == null:
		return
	halle_xf = bo.city.lieux.halle_xf
	conserverie_xf = bo.city.XF(-62.0, -104.0, 0.0, 1.0)
	toit_y = 11.4 + 0.45
	_bar()
	_affiche()
	_ecriteau()
	root.visible = false


# =================================================================== les petits outils

func H(x: float, y: float, z: float) -> Vector3:
	return halle_xf * Vector3(x, y, z)


func _mi(mesh: Mesh, mat: Material, xf: Transform3D, parent: Node3D = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	(parent if parent != null else root).add_child(m)
	if m.is_inside_tree():
		m.global_transform = xf
	else:
		m.transform = xf
	return m


func _cyl(r1: float, r2: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r2
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


func _boite(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


func _mat(c: Color, rough: float = 0.6, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _texte(txt: String, xf: Transform3D, taille: int, col: Color, larg: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font_size = taille
	l.pixel_size = 0.0022
	l.modulate = col
	l.outline_size = 0
	l.double_sided = false
	l.shaded = true
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	if larg > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = larg
	root.add_child(l)
	l.global_transform = xf
	return l


# =================================================================== le bar de Sirène : la Hurlante

## La tireuse à trois becs sur le comptoir, les fûts sous la fenêtre de service, l'ardoise des prix,
## quelques pintes servies.
func _bar() -> void:
	var w: float = 40.0
	var bx: Transform3D = halle_xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-w * 0.5 + 3.4, 0, -8.0))
	var chrome: Material = Mats.make("chrome75")
	var noir: Material = Mats.make("metal75_noir")
	var bois := _mat(Color(0.3, 0.17, 0.08), 0.55)
	var or_m := _mat(Color(0.95, 0.72, 0.3), 0.25, 1.0)
	var top: float = 1.165
	# la tireuse : un pied, une barre en T, trois becs, trois manettes (bois, rouge, noire)
	var tz: float = -0.42
	_mi(_cyl(0.05, 0.06, 0.38), chrome, bx * Transform3D(Basis(), Vector3(0.0, top + 0.19, tz)))
	_mi(_cyl(0.045, 0.045, 0.62), chrome, bx * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.0, top + 0.4, tz)))
	var poignees := [bois, _mat(Color(0.75, 0.08, 0.06), 0.4), _mat(Color(0.05, 0.05, 0.05), 0.35)]
	for k in range(3):
		var x: float = -0.22 + k * 0.22
		_mi(_cyl(0.018, 0.018, 0.1), chrome, bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, top + 0.4, tz + 0.07)))
		_mi(_cyl(0.012, 0.016, 0.07), chrome, bx * Transform3D(Basis(), Vector3(x, top + 0.33, tz + 0.11)))
		_mi(_cyl(0.017, 0.026, 0.2, 10), poignees[k], bx * Transform3D(Basis(), Vector3(x, top + 0.55, tz + 0.02)))
		_mi(_cyl(0.028, 0.028, 0.025, 12), or_m, bx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, top + 0.56, tz + 0.04)))
	# l'égouttoir sous les becs
	_mi(_boite(Vector3(0.66, 0.02, 0.16)), noir, bx * Transform3D(Basis(), Vector3(0.0, top + 0.01, tz + 0.12)))
	# quelques pintes servies sur le comptoir
	var verre := _mat(Color(0.85, 0.9, 0.92, 0.3), 0.05)
	verre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var blonde := _mat(Color(0.86, 0.52, 0.12), 0.15, 0.0, 0.25)
	var mousse := _mat(Color(0.98, 0.95, 0.86), 0.85)
	for p in [Vector2(1.4, -0.2), Vector2(1.62, -0.28), Vector2(-1.7, -0.25), Vector2(2.6, -0.3)]:
		var at := Vector3(p.x, top, p.y)
		_mi(_cyl(0.04, 0.034, 0.15, 16), verre, bx * Transform3D(Basis(), at + Vector3.UP * 0.075))
		_mi(_cyl(0.037, 0.031, 0.12, 16), blonde, bx * Transform3D(Basis(), at + Vector3.UP * 0.064))
		_mi(_cyl(0.039, 0.037, 0.026, 16), mousse, bx * Transform3D(Basis(), at + Vector3.UP * 0.136))
	# les fûts, debout et couchés, derrière le comptoir (côté sud : loin du passage de Sirène)
	var inox: Material = chrome
	for f in [Vector3(-3.0, 0, -1.75), Vector3(-2.35, 0, -1.95), Vector3(-3.0, 0.62, -1.85)]:
		var couche: bool = f.y > 0.1
		var fb: Basis = Basis(Vector3(0, 0, 1), PI * 0.5) if couche else Basis()
		var c: Vector3 = f + (Vector3.UP * 0.31 if not couche else Vector3.UP * 0.27)
		_mi(_cyl(0.24, 0.24, 0.6, 18), inox, bx * Transform3D(fb, c))
		for r in [-0.22, 0.22]:
			_mi(_cyl(0.25, 0.25, 0.04, 18), noir, bx * Transform3D(fb, c + fb * Vector3(0, r, 0)))
	# l'ardoise des prix, sur le mur des étagères (à droite du néon)
	var ard: Transform3D = bx * Transform3D(Basis(), Vector3(2.65, 3.2, -2.68))
	_mi(_boite(Vector3(1.1, 0.78, 0.03)), bois, ard)
	_mi(_boite(Vector3(1.0, 0.68, 0.01)), _mat(Color(0.06, 0.07, 0.06), 0.9), ard * Transform3D(Basis(), Vector3(0, 0, 0.018)))
	var craie := _texte("LA HURLANTE ........ 3 P\nLIMONADE ............ 2 P\nSIROP ................... 2 P\n\nPas de thunes ? Demande.", ard * Transform3D(Basis(), Vector3(0, 0, 0.026)), 28, Color(0.82, 0.82, 0.78), 420.0)
	craie.shaded = false
	var la := OmniLight3D.new()
	la.light_color = Color(1.0, 0.8, 0.55)
	la.light_energy = 0.7
	la.omni_range = 2.2
	la.shadow_enabled = false
	root.add_child(la)
	la.global_position = ard * Vector3(0, 0.75, 0.6)


# =================================================================== l'affiche, l'écriteau

## « Ici, on se respecte » : une grande affiche collée sur le mur ouest de la Halle, entre le bar et la scène.
func _affiche() -> void:
	var xf: Transform3D = halle_xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-19.44, 1.75, -13.6))
	_mi(_boite(Vector3(1.25, 1.7, 0.012)), _mat(Color(0.95, 0.92, 0.84), 0.95), xf)
	_mi(_boite(Vector3(1.25, 0.24, 0.014)), _mat(Color(0.95, 0.2, 0.45), 0.6, 0.0, 0.4), xf * Transform3D(Basis(), Vector3(0, 0.62, 0.002)))
	var titre := _texte("ICI, ON SE RESPECTE.", xf * Transform3D(Basis(), Vector3(0, 0.62, 0.012)), 34, Color(1, 1, 1))
	titre.shaded = false
	var lampe := OmniLight3D.new()
	lampe.light_color = Color(1.0, 0.85, 0.7)
	lampe.light_energy = 1.1
	lampe.omni_range = 2.6
	lampe.shadow_enabled = false
	root.add_child(lampe)
	lampe.global_position = xf * Vector3(0, 1.15, 0.55)
	_mi(_cyl(0.07, 0.12, 0.1, 12), Mats.make("metal75_noir"), xf * Transform3D(Basis(Vector3.RIGHT, -0.6), Vector3(0, 1.05, 0.12)))
	_texte("Un non, c'est non.\nUn peut-être, c'est non.\nTrop bourré pour dire oui ? C'est non.\n\nUn oui, ça se demande.\nEt ça se reprend quand on veut.\n\nUn souci ? Va voir Sirène au bar,\nou n'importe qui avec un bandana rose.\n\n— les Rats de Cale ♥",
		xf * Transform3D(Basis(), Vector3(0, -0.12, 0.008)), 22, Color(0.08, 0.06, 0.07), 470.0)


## Sur la porte d'une chambre de la Conserverie (au fond du rez-de-chaussée), un écriteau pendu à un clou.
func _ecriteau() -> void:
	var xf: Transform3D = conserverie_xf * Transform3D(Basis(), Vector3(-16.0, 1.75, -15.43))
	var carton := _mat(Color(0.82, 0.68, 0.46), 0.95)
	_mi(_boite(Vector3(0.5, 0.34, 0.01)), carton, xf)
	_mi(_cyl(0.003, 0.003, 0.3, 4), _mat(Color(0.2, 0.15, 0.1), 0.9), xf * Transform3D(Basis(Vector3(0, 0, 1), 0.98), Vector3(-0.1, 0.24, 0.0)))
	_mi(_cyl(0.003, 0.003, 0.3, 4), _mat(Color(0.2, 0.15, 0.1), 0.9), xf * Transform3D(Basis(Vector3(0, 0, 1), -0.98), Vector3(0.1, 0.24, 0.0)))
	_texte("OCCUPÉ·ES ♥\nrevenez plus tard\n(beaucoup plus tard)", xf * Transform3D(Basis(), Vector3(0, 0, 0.007)), 24, Color(0.45, 0.04, 0.1), 210.0)


# =================================================================== les gens de la nuit

func _profil(role: String) -> Dictionary:
	var p: Dictionary = Gens.pick("boucan", role, _rng)
	p["nom"] = Gens.prenom("boucan", role, _rng)
	return p


func _figurant(role: String, at: Vector3, face: Vector3, pose: String) -> Node:
	var f: Node = Figurant.spawn(root, main, _profil(role), at, face, pose)
	f.follow = false
	f.line_every = Vector2(9.0, 16.0)
	return f


## Les couples (s'enlacer) et les fumeurs du toit : posés une seule fois.
func poser_gens() -> void:
	if gens_poses or bo.city == null:
		return
	gens_poses = true
	Gens.debut_lieu()
	# [où (repère de la Halle ou de la Conserverie), direction de A vers B, rôles A, B]
	var places := [
		[H(18.3, 0.0, -15.0), halle_xf.basis * Vector3(0, 0, 1), "femme", "homme"],
		[H(-18.4, 0.0, -2.3), halle_xf.basis * Vector3(1, 0, 0), "femme", "femme"],
		[conserverie_xf * Vector3(-15.0, toit_y, -1.4), conserverie_xf.basis * Vector3(1, 0, 0), "homme", "homme"],
	]
	for e in places:
		var at: Vector3 = (e[0] as Vector3) + Vector3.UP * 0.05
		var d: Vector3 = (e[1] as Vector3).normalized()
		var a: Node = _figurant(str(e[2]), at - d * 0.17, d, "debout")
		var b: Node = _figurant(str(e[3]), at + d * 0.17, -d, "debout")
		a.lines = LIGNES_COUPLE
		b.lines = LIGNES_COUPLE
		b._line_t = 8.0
		_enlacer(a, b, "cou", 1.0)
		_enlacer(b, a, "taille", -1.0)
		couples.append([a, b])
	# les fumeurs : quatre places du cercle des assemblées, sur le toit (la place 1 est celle d'un habitant)
	var ax: Vector3 = conserverie_xf * Vector3(9.0, toit_y, -8.0)
	for k in [3, 4, 5, 6]:
		var a2: float = TAU * k / 8.0
		var p: Vector3 = ax + Vector3(cos(a2), 0, sin(a2)) * 2.6 + Vector3.UP * 0.05
		var role: String = ["homme", "femme", "vieux", "femme"][k - 3]
		var f: Node = _figurant(role, p, -Vector3(cos(a2), 0, sin(a2)), "assis")
		f.lines = LIGNES_FUMEURS
		f._line_t = 4.0 + 5.0 * (k - 3)
		var e2: Dictionary = {"fig": f, "pose": null, "joint": null, "t": _rng.randf_range(3.0, 10.0), "w": 0.0}
		if k == 3 or k == 5:
			e2["joint"] = _joint(f)
			e2["pose"] = _poser_mod(f, "taf", null, 1.0)
		fumeurs.append(e2)
	Gens.fin_lieu()
	_brume = _fumee_brume(ax + Vector3.UP * 1.1)


func _enlacer(f: Node, partenaire: Node, role: String, incline: float) -> void:
	_poser_mod(f, role, partenaire, incline)


func _poser_mod(f: Node, role: String, partenaire: Node, incline: float) -> Pose193:
	var sk: Skeleton3D = f.npc.get("skel")
	if sk == null:
		return null
	var m := Pose193.new()
	m.name = "Pose193"
	m.role = role
	m.incline = incline
	m.moi = f.npc
	m.autre = partenaire.npc if partenaire != null else null
	sk.add_child(m)
	m.preparer(sk)
	return m


## Un joint dans la main droite : le papier, le bout rougeoyant, un filet de fumée.
func _joint(f: Node) -> Node3D:
	var j := Node3D.new()
	j.name = "Joint193"
	var papier := _mi(_cyl(0.0042, 0.0034, 0.075, 8), _mat(Color(0.95, 0.93, 0.88), 0.9), Transform3D.IDENTITY, j)
	papier.position = Vector3(0, 0.0375, 0)
	var braise := _mi(_cyl(0.0045, 0.0045, 0.006, 8), _mat(Color(1.0, 0.35, 0.08), 0.5, 0.0, 4.0), Transform3D.IDENTITY, j)
	braise.position = Vector3(0, 0.077, 0)
	var fil := _filet()
	j.add_child(fil)
	fil.position = Vector3(0, 0.08, 0)
	if f.npc.has_method("_attach"):
		# (repère du personnage au repos : la main droite tendue vers -X ; le joint entre l'index et le majeur)
		f.npc._attach("RightHand", Vector3(-8.0, -0.5, -1.5), j, Vector3(-90, 0, 0))
	else:
		root.add_child(j)
	return j


func _tache() -> Texture2D:
	if main != null and main.has_method("_soft_dot_v24"):
		return main._soft_dot_v24()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.gradient = gr
	return g


func _mat_fumee(alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _tache()
	m.albedo_color = Color(1, 1, 1, alpha)
	m.disable_receive_shadows = true
	return m


## Le filet de fumée qui monte du bout du joint.
func _filet() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Fumee193"
	p.amount = 14
	p.lifetime = 2.6
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.12
	p.gravity = Vector3(0.03, 0.16, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var c := Curve.new()
	c.add_point(Vector2(0, 0.2))
	c.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = c
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.85, 0.86, 0.9, 0.0), Color(0.85, 0.86, 0.9, 0.35), Color(0.8, 0.82, 0.86, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = _mat_fumee(0.6)
	p.mesh = q
	return p


## La bouffée qu'on recrache : un petit nuage qui part devant la bouche.
func _bouffee(at: Vector3, dir: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 2.2
	p.one_shot = true
	p.explosiveness = 0.75
	p.local_coords = false
	p.direction = (dir + Vector3.UP * 0.25).normalized()
	p.spread = 22.0
	p.initial_velocity_min = 0.25
	p.initial_velocity_max = 0.5
	p.damping_min = 0.3
	p.damping_max = 0.5
	p.gravity = Vector3(0, 0.12, 0)
	var c := Curve.new()
	c.add_point(Vector2(0, 0.3))
	c.add_point(Vector2(1, 2.4))
	p.scale_amount_curve = c
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.88, 0.88, 0.92, 0.45), Color(0.85, 0.86, 0.9, 0.0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.14)
	q.material = _mat_fumee(0.7)
	p.mesh = q
	root.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)


## Une brume légère au-dessus du cercle (l'odeur, on l'imagine).
func _fumee_brume(at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Brume193"
	p.amount = 16
	p.lifetime = 9.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.2
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.08
	p.gravity = Vector3(0.02, 0.03, 0)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.8, 0.82, 0.88, 0.0), Color(0.8, 0.82, 0.88, 0.06), Color(0.8, 0.82, 0.88, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(1.3, 1.3)
	q.material = _mat_fumee(0.5)
	p.mesh = q
	root.add_child(p)
	p.global_position = at
	return p


func _gens_actifs(on: bool) -> void:
	for c in couples:
		for f in c:
			_actif(f, on)
	for e in fumeurs:
		_actif(e["fig"], on)
	if _brume != null:
		_brume.emitting = on
		_brume.visible = on


func _actif(f: Node, on: bool) -> void:
	if f == null or not is_instance_valid(f) or f.npc == null:
		return
	f.npc.visible = on
	f.npc.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	f.set_process(on)


## Les fumeurs : de temps en temps, le joint monte à la bouche (une seconde et demie), puis la bouffée.
func _fumeurs_tick(delta: float) -> void:
	for e in fumeurs:
		var m: Pose193 = e["pose"]
		if m == null:
			continue
		e["t"] = float(e["t"]) - delta
		var t: float = float(e["t"])
		var w: float = 0.0
		if t < 0.0:
			var u: float = -t
			if u < 0.6:
				w = smoothstep(0.0, 1.0, u / 0.6)
			elif u < 2.0:
				w = 1.0
			elif u < 2.7:
				w = 1.0 - smoothstep(0.0, 1.0, (u - 2.0) / 0.7)
			else:
				e["t"] = _rng.randf_range(8.0, 15.0)
				var sk: Skeleton3D = m.get_skeleton()
				var f: Node = e["fig"]
				if sk != null and sk.find_bone("Head") >= 0:
					var tete: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
					var av: Vector3 = (f.npc as Node3D).global_basis.z
					_bouffee(tete + av * 0.12 + Vector3.UP * 0.02, av)
		m.poids = w


# =================================================================== la Halle : paroles, bière, slam

func _concert_tick(delta: float) -> void:
	var ev: Node = bo.events
	if ev == null or not ev.concert_on():
		_parole_i = 0
		return
	var p: Vector3 = main._player_pos_v27()
	if not ev.in_halle(p):
		return
	_parole_t -= delta
	if _parole_t <= 0.0:
		_parole_t = 9.0
		var ch: Array = CHANSONS[posmod(ev._day(), CHANSONS.size())]
		var ligne: String = str(ch[_parole_i % ch.size()])
		main._show_message_v28("♪ " + ligne + " ♪")
		if main.get("message_clock_v28") != null:
			main.message_clock_v28 = 8.0
		_parole_i += 1
	_douche_t -= delta
	if _douche_t <= 0.0:
		_douche_t = _rng.randf_range(55.0, 90.0)
		douche()


## Rouille secoue une canette et arrose la fosse.
func douche() -> void:
	var l = bo.city.lieux
	var from: Vector3 = l.halle_scene + Vector3.UP * 2.6
	var p := CPUParticles3D.new()
	p.name = "Douche193"
	p.amount = 320
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.55
	p.local_coords = false
	p.direction = (halle_xf.basis * Vector3(0, 0.55, 1)).normalized()
	p.spread = 32.0
	p.initial_velocity_min = 4.5
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var s := SphereMesh.new()
	s.radius = 0.032
	s.height = 0.05
	s.radial_segments = 6
	s.rings = 3
	var m := _mat(Color(1.0, 0.68, 0.2, 0.9), 0.05, 0.0, 1.4)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s.material = m
	p.mesh = s
	root.add_child(p)
	p.global_position = from
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)
	douches += 1
	if main.has_method("sfx"):
		main.sfx("foule_acclame", l.halle_fosse)
	var me: Vector3 = main._player_pos_v27()
	if me.distance_to(l.halle_fosse) < 9.0:
		bo.say("Rouille secoue une canette de Hurlante et arrose toute la fosse ! La bière te dégouline dans le cou. Ça colle. C'est merveilleux.", 6.0)


func can_slam() -> bool:
	return averti and _slam_t < 0.0 and bo.events != null and bo.events.concert_on()


## Se jeter dans la foule depuis le bord de la scène : la foule porte le héros jusqu'à la régie.
func slam() -> void:
	if not can_slam():
		return
	_slam_a = H(0.0, 0.0, -14.6)
	_slam_b = H(5.5, 0.0, -4.6)
	_slam_t = 0.0
	slams += 1
	main.sfx("foule_acclame", bo.city.lieux.halle_fosse)
	bo.say(["Tu prends ton élan au bord de la scène… et tu te jettes dans la foule ! Cent mains te rattrapent.",
		"Rouille hurle « VAS-Y ! » : tu plonges ! La fosse t'attrape au vol et te fait voguer au-dessus des crêtes.",
		"Tu sautes de la scène, bras en croix. Un instant de vide… puis des mains partout. Tu flottes sur une mer de gens."][slams % 3], 6.0)


func _slam_tick(delta: float) -> void:
	if _slam_t < 0.0:
		return
	_slam_t += delta
	var u: float = clampf(_slam_t / SLAM_DUREE, 0.0, 1.0)
	var dir: Vector3 = (_slam_b - _slam_a)
	dir.y = 0.0
	dir = dir.normalized()
	var cote: Vector3 = dir.cross(Vector3.UP)
	var pos: Vector3 = _slam_a.lerp(_slam_b, smoothstep(0.0, 1.0, u)) + cote * sin(_slam_t * 1.7) * 0.35
	pos.y = _slam_a.y + 1.85 + sin(_slam_t * 5.3) * 0.1 + sin(_slam_t * 2.1) * 0.06
	if u >= 1.0:
		_slam_t = -1.0
		var h0: Node = main.get("hero_v28")
		main.place_player_v35(_slam_b + Vector3.UP * 0.1, dir)
		if h0 != null and not main.xr_active:
			h0.leave_ride()
		bo.say("La foule te dépose en douceur près de la régie. Larsen lève le pouce sans quitter ses potards des yeux.", 5.0)
		return
	if main.xr_active:
		var cam_local: Vector3 = main.xr_camera.position
		var off: Vector3 = Basis(Vector3.UP, main.xr_origin.rotation.y) * Vector3(cam_local.x, 0.0, cam_local.z)
		main.xr_origin.position = Vector3(pos.x - off.x, pos.y + 0.25 - cam_local.y, pos.z - off.z)
		main.vr_body.global_position = pos + Vector3.UP * 0.3
		main.vr_body.velocity = Vector3.ZERO
		return
	main.pc_root.position = pos
	main.pc_body.global_position = pos + Vector3.UP * 0.5
	main.pc_body.velocity = Vector3.ZERO
	var h: Node = main.get("hero_v28")
	if h == null:
		return
	h.state = "bateau"
	h.facing = -dir
	h.fall_top = pos.y
	if h.hero != null:
		# couché sur le dos, la tête vers où l'on va, les bras qui battent
		var yaw: float = atan2(-dir.x, -dir.z)
		var b: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5 + sin(_slam_t * 3.0) * 0.08) * Basis(Vector3(0, 0, 1), sin(_slam_t * 2.3) * 0.12)
		var sc: float = (h.hero as Node3D).scale.x
		var pivot := Vector3(0, 0.95, 0)
		var origin: Vector3 = h.root.position + Vector3.UP * float(main.get("hero_mesh_floor_offset_v11"))
		(h.hero as Node3D).transform = Transform3D(b.scaled(Vector3.ONE * sc), origin + pivot - b * pivot)
		h._play("v28/fall", 0.3)


func slamming() -> bool:
	return _slam_t >= 0.0


# =================================================================== le Rieur : le trip

## Le Rieur commence (on) ou s'arrête (off) : champignons_v75._begin / _end.
func trip(on: bool) -> void:
	if on:
		trip_on = true
		trip_t = 0.0
		_trip_line_t = 7.0
		_trip_ecran(true)
		_trip_son(true)
		if main.has_method("sfx"):
			main.sfx("gloussement", main._player_pos_v27() + Vector3.UP * 1.5)
	else:
		trip_on = false
		trip_t = -1.0
		_trip_ecran(false)
		_trip_son(false)
		_trip_env(0.0)


func _trip_ecran(on: bool) -> void:
	if not on:
		if _trip_layer != null:
			_trip_layer.queue_free()
		_trip_layer = null
		_trip_mat = null
		return
	if _trip_layer != null or main.get("xr_active") == true:
		return
	_trip_layer = CanvasLayer.new()
	_trip_layer.name = "Trip193"
	_trip_layer.layer = 40
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trip_mat = ShaderMaterial.new()
	_trip_mat.shader = load("res://shaders/trip_v193.gdshader")
	r.material = _trip_mat
	_trip_layer.add_child(r)
	add_child(_trip_layer)


func _trip_son(on: bool) -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if on and _trip_fx.is_empty():
		var ph := AudioEffectPhaser.new()
		ph.rate_hz = 0.25
		ph.depth = 0.9
		ph.feedback = 0.55
		var ch := AudioEffectChorus.new()
		ch.wet = 0.45
		for fx in [ph, ch]:
			AudioServer.add_bus_effect(bus, fx)
			_trip_fx.append(fx)
	elif not on:
		for fx in _trip_fx:
			for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
				if AudioServer.get_bus_effect(bus, i) == fx:
					AudioServer.remove_bus_effect(bus, i)
		_trip_fx.clear()


## La force du trip, de 0 à 1 (montée, plateau, descente) ; la durée : champignons_v75.KINDS.
func force() -> float:
	if not trip_on or trip_t < 0.0:
		return 0.0
	var reste: float = 90.0 - trip_t
	var ch: Node = bo.get("champis")
	if ch != null and (ch.active as Dictionary).has("champi_rieur"):
		reste = float(ch.active["champi_rieur"])
	return clampf(minf(trip_t / TRIP_MONTEE, reste / TRIP_DESCENTE), 0.0, 1.0)


func _trip_env(f: float) -> void:
	var t: Node = main.get("temps_v56")
	var e: Environment = t.env if t != null and t.get("env") != null else null
	if e == null:
		return
	if f <= 0.0:
		if _trip_sat >= 0.0:
			e.adjustment_saturation = _trip_sat
		_trip_sat = -1.0
		return
	if _trip_sat < 0.0:
		_trip_sat = e.adjustment_saturation
	e.adjustment_saturation = _trip_sat * (1.0 + f * (0.9 + 0.45 * sin(_t * 1.9)))


func _trip_tick(delta: float) -> void:
	if not trip_on:
		return
	trip_t += delta
	var f: float = force()
	if _trip_mat != null:
		_trip_mat.set_shader_parameter("force", f)
		_trip_mat.set_shader_parameter("temps", _t)
	if main.get("xr_active") == true:
		_trip_env(f)
	_trip_line_t -= delta
	if _trip_line_t <= 0.0 and f > 0.5:
		_trip_line_t = _rng.randf_range(12.0, 18.0)
		main._show_message_v28(str(LIGNES_TRIP[_rng.randi() % LIGNES_TRIP.size()]))
		if _rng.randf() < 0.6 and main.has_method("sfx"):
			main.sfx("gloussement", main._player_pos_v27() + Vector3.UP * 1.5)


# =================================================================== les invites

func register_interactions(d: Node) -> void:
	var me = self
	slam_ia = {"id": "bo_slam", "pos": H(0.0, 0.0, -14.6), "radius": 2.6, "text": "E : se jeter dans la foule (slam) !", "vr": "Gâchette : slam dans la foule",
		"call": func(): me.slam(), "when": func(): return me.can_slam()}
	bo._ia(d, slam_ia)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or bo == null or root == null:
		return
	_t += delta
	_trip_tick(delta)
	_slam_tick(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		var a: bool = Public.averti()
		var h: float = bo.hour()
		var n: bool = h >= NUIT_DEBUT or h < NUIT_FIN
		var p: Vector3 = main._player_pos_v27()
		if a and n and not gens_poses and p.distance_to(halle_xf.origin) < 320.0:
			poser_gens()
		if a != averti or n != nuit:
			averti = a
			nuit = n
			root.visible = averti
			_gens_actifs(averti and nuit)
		if not averti and trip_on:
			# on est repassé en Tout public : le trip s'arrête net
			var ch: Node = bo.get("champis")
			if ch != null and (ch.active as Dictionary).has("champi_rieur"):
				ch.active.erase("champi_rieur")
			trip(false)
	if not averti:
		return
	_concert_tick(delta)
	if nuit and gens_poses:
		_fumeurs_tick(delta)


func serialize() -> Dictionary:
	return {"slams": slams, "douches": douches}


func load_data(d: Dictionary) -> void:
	slams = int(d.get("slams", 0))
	douches = int(d.get("douches", 0))
	if trip_on:
		trip(false)


# =================================================================== Pose193 : s'enlacer, fumer

## Agit après l'animation : les bras (IK à deux os) vers la nuque ou la taille de l'autre, ou la main droite
## vers la bouche (« taf », avec un poids) ; la tête se tourne vers le visage de l'autre et s'incline.
class Pose193 extends SkeletonModifier3D:
	var role: String = "cou"              # cou | taille | taf
	var incline: float = 1.0              # le sens où la tête penche
	var moi: Node3D
	var autre: Node3D
	var poids: float = 1.0
	var _os: Dictionary = {}

	func preparer(sk: Skeleton3D) -> void:
		for n in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]:
			_os[n] = sk.find_bone(n)

	func _b(n: String) -> int:
		return int(_os.get(n, -1))

	func _monde(sk: Skeleton3D, b: int) -> Vector3:
		return sk.global_transform * sk.get_bone_global_pose(b).origin

	## Tourne l'os b (dans sa pose) pour que sa direction locale `axe` regarde `vers` (repère du squelette).
	func _viser(sk: Skeleton3D, b: int, axe: Vector3, vers: Vector3, w: float, roulis: float = 0.0) -> void:
		if b < 0 or vers.length() < 0.0001 or w <= 0.001:
			return
		var par: int = sk.get_bone_parent(b)
		var gp: Quaternion = sk.get_bone_global_pose(par).basis.get_rotation_quaternion() if par >= 0 else Quaternion.IDENTITY
		var lr: Quaternion = sk.get_bone_pose_rotation(b)
		var gb: Quaternion = gp * lr
		var cur: Vector3 = (gb * axe).normalized()
		var want: Vector3 = vers.normalized()
		if cur.dot(want) > 0.99999:
			return
		var q := Quaternion(cur, want)
		if absf(roulis) > 0.0001:
			q = Quaternion(want, roulis) * q
		var cible: Quaternion = (gp.inverse() * (q * gb)).normalized()
		sk.set_bone_pose_rotation(b, lr.slerp(cible, clampf(w, 0.0, 1.0)))

	## Le bras (épaule, avant-bras) jusqu'à `cible`, le coude vers `pole` (repère du squelette).
	func _bras(sk: Skeleton3D, cote: String, cible: Vector3, pole: Vector3, w: float) -> void:
		var arm: int = _b(cote + "Arm")
		var fore: int = _b(cote + "ForeArm")
		var hand: int = _b(cote + "Hand")
		if arm < 0 or fore < 0 or hand < 0:
			return
		var s: Vector3 = sk.get_bone_global_pose(arm).origin
		var l1: float = sk.get_bone_pose_position(fore).length()
		var l2: float = sk.get_bone_pose_position(hand).length()
		var dv: Vector3 = cible - s
		var d: float = clampf(dv.length(), 0.1 * (l1 + l2), 0.995 * (l1 + l2))
		var dir: Vector3 = dv.normalized()
		var a: float = (l1 * l1 + d * d - l2 * l2) / (2.0 * d)
		var hh: float = sqrt(maxf(l1 * l1 - a * a, 0.0))
		var pv: Vector3 = pole - s
		pv -= dir * pv.dot(dir)
		if pv.length() < 0.0001:
			pv = dir.cross(Vector3.UP)
		pv = pv.normalized()
		var coude: Vector3 = s + dir * a + pv * hh
		var main_p: Vector3 = s + dir * d
		_viser(sk, arm, sk.get_bone_pose_position(fore).normalized(), coude - s, w)
		_viser(sk, fore, sk.get_bone_pose_position(hand).normalized(), main_p - sk.get_bone_global_pose(fore).origin, w)

	func _avant_local(sk: Skeleton3D, b: int) -> Vector3:
		return sk.get_bone_global_rest(b).basis.get_rotation_quaternion().inverse() * Vector3(0, 0, 1)

	func _process_modification_with_delta(_delta: float) -> void:
		var sk: Skeleton3D = get_skeleton()
		if sk == null or moi == null or not sk.is_visible_in_tree():
			return
		var inv: Transform3D = sk.global_transform.affine_inverse()
		var av: Vector3 = moi.global_basis.z.normalized()
		var gauche: Vector3 = moi.global_basis.x.normalized()
		if role == "taf":
			if poids <= 0.001 or _b("Head") < 0:
				return
			var tete: Vector3 = _monde(sk, _b("Head"))
			# le poignet en avant et en dessous de la bouche (le joint, entre les doigts, arrive aux lèvres)
			var bouche: Vector3 = tete + av * 0.17 - Vector3.UP * 0.11 - gauche * 0.07
			var epaule: Vector3 = _monde(sk, _b("RightArm"))
			_bras(sk, "Right", inv * bouche, inv * (epaule - Vector3.UP * 0.4 - gauche * 0.45 + av * 0.15), poids)
			_viser(sk, _b("Head"), _avant_local(sk, _b("Head")), inv.basis * (av - Vector3.UP * 0.12), poids * 0.4)
			return
		if autre == null or not is_instance_valid(autre):
			return
		var ask: Skeleton3D = autre.get("skel")
		if ask == null:
			return
		var aav: Vector3 = autre.global_basis.z.normalized()
		# le buste se penche un peu vers l'autre ; la tête cherche son visage et s'incline
		var atete: Vector3 = ask.global_transform * ask.get_bone_global_pose(ask.find_bone("Head")).origin if ask.find_bone("Head") >= 0 else autre.global_position + Vector3.UP * 1.6
		var visage: Vector3 = atete + aav * 0.06
		if _b("Spine2") >= 0:
			_viser(sk, _b("Spine2"), _avant_local(sk, _b("Spine2")), inv.basis * (av - Vector3.UP * 0.05), 0.5)
		if _b("Neck") >= 0 and _b("Head") >= 0:
			var ma_tete: Vector3 = _monde(sk, _b("Head"))
			var vers: Vector3 = visage - ma_tete
			_viser(sk, _b("Neck"), _avant_local(sk, _b("Neck")), inv.basis * vers, 0.45)
			_viser(sk, _b("Head"), _avant_local(sk, _b("Head")), inv.basis * (visage - _monde(sk, _b("Head"))), 0.85, deg_to_rad(16.0) * incline)
		# les bras
		var haut: bool = role == "cou"
		var aos: int = ask.find_bone("Neck" if haut else "Spine1")
		if aos < 0:
			aos = ask.find_bone("Spine")
		if aos < 0:
			return
		var ancre: Vector3 = ask.global_transform * ask.get_bone_global_pose(aos).origin
		for cote in ["Left", "Right"]:
			var sg: float = 1.0 if cote == "Left" else -1.0
			var ep: Vector3 = _monde(sk, _b(cote + "Arm"))
			var cible: Vector3
			var pole: Vector3
			if haut:
				cible = ancre + gauche * sg * 0.05 - aav * 0.05 + Vector3.UP * 0.03
				pole = ep - Vector3.UP * 0.5 + gauche * sg * 0.35 - av * 0.1
			else:
				cible = ancre + gauche * sg * 0.07 - aav * 0.07 - Vector3.UP * 0.02
				pole = ep - Vector3.UP * 0.6 + gauche * sg * 0.45 - av * 0.25
			_bras(sk, cote, inv * cible, inv * pole, poids)

extends "res://scripts/chateau_comte_v124.gd"
## V128 : la fin du château du comte, à Sombreval.
##  1. la porte de fer, tout en haut de la Tour du Comte, s'ouvre sur la Chambre du Comte : une grande
##     salle rouge et noire, un cercueil sur une estrade, trois immenses fenêtres cachées par de lourds
##     rideaux de velours… et le comte Dracula, debout devant elles ;
##  2. le combat : le comte glisse, frappe, disparaît dans sa brume et revient dans ton dos. Blessé,
##     il se change en brume rouge et plus aucune lame ne le touche : il faut arracher les trois
##     rideaux (E) pour laisser entrer l'aube. Dans la lumière, il redevient vulnérable ; à la fin, il
##     appelle ses loups ;
##  3. vaincu (en poussière et en lumière, ou en cendres en « Public averti ») : la clé des souterrains
##     tombe sur les dalles, et dehors, dans toute la ville, les morts-vivants s'endorment pour toujours
##     (sombreval_v121.liberer) ;
##  4. les souterrains, derrière la grille du fond de la salle d'armes : un long couloir voûté, dix
##     cellules, huit prisonniers de Sombreval (le docteur Vasseur, la boulangère, l'horloger…). On
##     ouvre chaque cellule avec la clé ; libérés, ils rentrent en ville et t'attendent sur la Place du
##     Marché.
## Repère : celui du château (chateau_comte_v124). La Chambre est à l'ouest de la tour (x < -3,6), au
## niveau du palier de la porte de fer (y = 11,45) ; les souterrains au nord de la salle d'armes
## (z < -60), au même niveau (y = -8).

const Monster124 = preload("res://scripts/monstre_v124.gd")
const Public = preload("res://scripts/public_v111.gd")

const CH_Y: float = 11.45                        # le sol de la Chambre du Comte
const DRAC_HOME := Vector3(-22.5, 11.5, -25.0)   # le comte, devant son estrade
const FENETRES := [-21.0, -14.0, -7.0]           # x des trois grandes fenêtres (mur nord, z = -34)
const CELL_Z0: float = -60.0                     # le début du couloir des cachots
const CELL_L: float = 7.4                        # la longueur d'une cellule

## Les prisonniers : [id, nom, corps, cellule (0-4 à l'ouest, 5-9 à l'est), invite, merci, histoire, en ville]
const CAPTIFS := [
	["clotilde", "Madame Clotilde, la boulangère", "f81_braise_3", 0, "E : ouvrir la cellule de Madame Clotilde",
		"« Oh, mon petit ! » La vieille boulangère te serre dans ses bras, très fort. « Trois ans sans pétrir… J'en ai les mains qui tremblent. Je vais rallumer mon four, et tu auras le premier pain de Sombreval. Promis. »",
		"« Avant le comte, on faisait la fête des brioches, chaque printemps, sur la place. Toute la ville sentait le beurre et la fleur d'oranger… On la refera. Cette année. »",
		"« Le four chauffe ! » Clotilde a déjà de la farine jusqu'aux coudes. « Reviens tout à l'heure : la première fournée est pour toi. »"],
	["gaspard", "Gaspard, l'horloger", "f81_yourte_fleurs_2", 1, "E : ouvrir la cellule de Gaspard",
		"« Minuit… Il est toujours minuit, n'est-ce pas ? » Le vieil horloger cligne des yeux. « Non ? Le comte est tombé ? Alors les horloges vont repartir. Toutes. Je vais m'en occuper moi-même, une par une. »",
		"« C'est le comte qui a arrêté toutes les horloges de la ville, le premier soir. Il voulait que la nuit ne finisse jamais. Mais le temps, mon petit, on peut l'arrêter un moment… jamais pour toujours. »",
		"« Tu entends ? Tic-tac. » Gaspard sourit de toutes ses rides. « Le beffroi d'abord. Ensuite la gare, la mairie… Il y a trois cent quarante horloges à Sombreval. Je les ai comptées. »"],
	["lina", "Lina, l'institutrice", "f81_yourte_fleurs_9", 3, "E : ouvrir la cellule de Lina",
		"« Enfin ! » Lina passe la porte en courant. « Je chantais à voix basse pour les autres, tous les soirs, pour qu'on garde courage. Maintenant, on va pouvoir chanter fort ! »",
		"« Mes élèves étaient partis en voyage sur le continent, juste avant que tout commence. Ils vont bien, je le sais. Je vais leur écrire que Sombreval est libre… et rouvrir l'école. »",
		"« L'école rouvrira à la rentrée ! » Lina tient une craie entre ses doigts, comme un trésor. « J'ai déjà écrit ton nom au tableau, en haut, en grand. »"],
	["vasseur", "le docteur Vasseur", "f81_yourte_rainville_2", 4, "E : ouvrir la cellule du docteur Vasseur",
		"« Vous… vous avez trouvé mon journal ? » Le vieux docteur se relève en s'appuyant sur les barreaux. « Alors ces cinq pages n'auront pas été écrites pour rien. Le comte m'a pris le soir où j'ai voulu les cacher en ville. Merci, mon enfant. Merci. »",
		"« Trois hivers dans le noir… J'ai compté les jours en grattant le mur, voyez. » Il montre des centaines de petits traits. « Je vais rouvrir mon cabinet, sur la Place du Marché. Il y aura du monde à soigner : des rhumes, surtout. Il fait si humide, ici. »",
		"« Mon cabinet ouvre demain ! » Le docteur Vasseur rajuste ses lunettes. « Mon journal ? Je l'ai recopié en entier, avec une nouvelle fin : la tienne. »"],
	["matthieu", "Matthieu, le forgeron", "f81_braise_8", 5, "E : ouvrir la cellule de Matthieu",
		"Le forgeron tâte la serrure ouverte d'un air connaisseur. « Belle clé. Belle serrure. Mauvaise idée de m'enfermer derrière. » Il s'étire, ses épaules craquent. « Merci, l'ami. Je te dois une épée. Ou deux. »",
		"« C'est moi qui ai forgé les grilles de ces cachots, il y a trois ans. Le comte me les avait commandées… Je ne savais pas pour qui c'était. » Il serre les poings. « Je vais les fondre. Toutes. Et en faire des grilles de jardin. »",
		"« Les grilles des cachots ? Elles font de très belles grilles de jardin. » Matthieu frappe sur son enclume, tout content. « Reviens quand tu veux : pour toi, c'est gratuit. »"],
	["rose", "Rose, la fleuriste", "f81_yourte_rainville_7", 6, "E : ouvrir la cellule de Rose",
		"« Il y a… il y a encore des fleurs, dehors ? » Rose a les yeux pleins de larmes. « Je les entendais pousser, je te jure, à travers les murs. Merci… Merci ! »",
		"« Le lierre a tout recouvert, là-haut ? Tant mieux. On va garder le lierre, et planter des roses dessous. Une ville morte, ça peut refleurir. Il suffit d'un peu de soleil. »",
		"« Regarde ! » Rose montre une petite pousse verte entre deux pavés. « La première rose de Sombreval. Je l'appellerai comme toi. »"],
	["joachim", "le père Joachim, le sonneur", "f81_pasta_2", 8, "E : ouvrir la cellule du père Joachim",
		"« Ah ! Mes vieux genoux… » Le sonneur sort en boitant, mais il rit. « Le comte m'a enfermé le soir où j'ai voulu sonner l'alarme. Il ne supportait pas les cloches. Eh bien, il va falloir qu'il s'habitue… Ah non, c'est vrai. Il n'est plus là. »",
		"« Douze coups pour minuit. Six coups pour l'aube. Et un grand carillon pour les jours de fête. Tu l'entendras, ce carillon-là. Tout l'archipel l'entendra. »",
		"« Tu as entendu le carillon ? » Le père Joachim frotte ses mains rouges. « C'était pour toi. Je te sonnerai le grand carillon chaque fois que tu reviendras. »"],
	["solene", "Solène, la postière", "f81_pasta_9", 9, "E : ouvrir la cellule de Solène",
		"« Trois ans de courrier en retard ! » Solène se relève d'un bond. « Les lettres de toute la ville dorment au bureau de poste… Il va falloir tout distribuer. Merci, mille fois merci ! »",
		"« Le dernier jour, quelqu'un a posté une lettre pour le comte. Une lettre sans timbre, avec juste écrit dessus : Va-t'en. » Elle rit. « Je crois que c'était le docteur. »",
		"« Une lettre pour toi ! » Solène te tend une enveloppe : « Merci », signé par toute la ville. « Je l'ai fait signer porte à porte. Ça m'a pris toute la matinée. »"],
]
const PARLER := {"clotilde": "E : parler à Madame Clotilde", "gaspard": "E : parler à Gaspard", "lina": "E : parler à Lina",
	"vasseur": "E : parler au docteur Vasseur", "matthieu": "E : parler à Matthieu", "rose": "E : parler à Rose",
	"joachim": "E : parler au père Joachim", "solene": "E : parler à Solène"}
## Ce qu'on entend derrière les barreaux, en passant
const CRIS := ["« Ici ! Par ici ! »", "« Tu as la clé ? Oh, je t'en prie… »", "« Ce n'est pas un vampire… c'est quelqu'un ! »", "« Ouvrez-nous ! »"]

var _dracula: Node3D
var _phase: int = 0                              # 0 : il parle ; 1, 2, 3 : le combat
var _porte_fer_n: Node3D                         # la porte de fer (sa charnière)
var _rideaux: Array = []                         # [Node3D (la tringle), arraché ?]
var _aubes: Array = []                           # [MeshInstance3D (le vitrail dans l'aube), SpotLight3D]
var _grille_n: Node3D
var _cell_doors: Dictionary = {}                 # cellule -> Node3D (la charnière)
var _captifs: Dictionary = {}                    # id -> monstre (« captif »)
var _brume_t: float = 0.0
var _fume_t: float = 0.0
var _spawns124: Dictionary = {}
var _dial_t: float = 0.0


func _init() -> void:
	super._init()
	bbox = AABB(Vector3(-86.0, -12.0, -100.0), Vector3(140.0, 36.0, 118.0))
	_spawns124 = room_spawns.duplicate(true)


func _defaults() -> Dictionary:
	var d: Dictionary = super._defaults()
	d.merge({"chambre": false, "comte": false, "comte_vu": false, "cle": false, "grille": false, "cellules": {}, "libres": false}, true)
	return d


# =================================================================== construction

func _build() -> void:
	super._build()
	add_room("comte", Vector3(-30, CH_Y, -34), Vector3(-3.6, 22, -16), Vector3(-5.6, CH_Y + 0.05, -20.5), Vector3(-1, 0, 0), ["tour"])
	add_room("cachots", Vector3(-6, -8, -97), Vector3(22, -3, -60), Vector3(8.0, -7.95, -61.5), Vector3(0, 0, -1), ["armes"])
	(rooms["tour"]["voisins"] as Array).append("comte")
	(rooms["armes"]["voisins"] as Array).append("cachots")
	_build_chambre()
	_build_cachots()
	_fill_lights128()


## La tour : comme en V124, mais le mur ouest est percé (la porte de fer donne sur la Chambre)
func _build_tour() -> void:
	_b = SK.Batch.new()
	floor_ceil(-3, 3, -22, -15, 6, 10, "dalles_int", "pierre_int")
	walls(-3, 3, -22, -15, 6, 10, "pierre_int", "pierre_int", [["s", 0, 8.0, 10.0], ["w", -20.5, 1.6, 10.0]])
	_wall_seg(false, -3.3, -21.3, -19.7, 6.0, CH_Y - 6.0, 0.6, "pierre_int", "pierre_int")
	_wall_seg(false, -3.3, -21.3, -19.7, CH_Y + 2.7, 16.0 - CH_Y - 2.7, 0.6, "pierre_int", "pierre_int")
	var c := Vector3(0, 6, -19.5)
	cy("pierre_chateau_claire", c, 0.35, 0.35, 8.0, 12)
	kit.col_cyl(W(c), 0.4, 8.0)
	var n: int = 22
	for i in range(n):
		var a: float = PI * 0.5 + i * (TAU * 0.9 / n)
		var y: float = 6.0 + (i + 1) * (5.4 / n)
		var p: Vector3 = c + Vector3(cos(a) * 1.3, 0, sin(a) * 1.3)
		bx("pierre_chateau_claire", Vector3(p.x, y - 0.1, p.z), Vector3(1.9, 0.2, 0.75), -a, true)
	bx("pierre_chateau_claire", Vector3(-1.6, 11.35, -20.5), Vector3(2.6, 0.2, 2.6), 0.0, true)
	# l'encadrement de la porte de fer (côté tour)
	for s in [-1.0, 1.0]:
		bx("pierre_chateau_claire", Vector3(-2.92, CH_Y + 1.35, -20.5 + s * 0.92), Vector3(0.18, 2.7, 0.24))
	bx("pierre_chateau_claire", Vector3(-2.92, CH_Y + 2.8, -20.5), Vector3(0.18, 0.24, 2.1))
	_commit("tour", "Tour_v124")
	applique("tour", Vector3(2.95, 8.0, -18.5), Vector3(-1, 0, 0))
	light("tour", Vector3(-2.0, 12.8, -20.5), 0.6, 4.0, Color(1.0, 0.2, 0.1))
	_build_porte_fer()


## La porte de fer : une charnière au sud de l'ouverture ; elle s'ouvre vers la Chambre
func _build_porte_fer() -> void:
	_porte_fer_n = Node3D.new()
	_porte_fer_n.name = "Porte_fer_v128"
	(rooms["tour"]["root"] as Node3D).add_child(_porte_fer_n)
	_porte_fer_n.global_transform = X(Vector3(-3.3, CH_Y, -19.75))
	var b := SK.Batch.new()
	var xf := Transform3D(Basis(), Vector3(0, 1.32, -0.75))
	b.box("fer_noir", xf, Vector3(0.1, 2.64, 1.5))
	for yy in [0.35, 1.32, 2.29]:
		b.box("rouille", Transform3D(Basis(), Vector3(0, yy, -0.75)), Vector3(0.16, 0.09, 1.52))
	for k in range(6):
		for yy2 in [0.35, 1.32, 2.29]:
			b.blob("fer_noir", Vector3(0.09, yy2, -0.12 - k * 0.25), Vector3(0.025, 0.025, 0.025), 6)
			b.blob("fer_noir", Vector3(-0.09, yy2, -0.12 - k * 0.25), Vector3(0.025, 0.025, 0.025), 6)
	# l'anneau (des deux côtés)
	for s in [-1.0, 1.0]:
		var rc: Vector3 = Vector3(s * 0.1, 1.2, -1.25)
		for k2 in range(10):
			var a0: float = TAU * k2 / 10.0
			var a1: float = TAU * (k2 + 1) / 10.0
			b.tube("rouille", rc + Vector3(0, cos(a0) * 0.1, sin(a0) * 0.1), rc + Vector3(0, cos(a1) * 0.1, sin(a1) * 0.1), 0.014, 5)
	b.commit(_porte_fer_n, "Battant_fer")
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.14, 2.64, 1.5)
	cs.shape = sh
	cs.position = Vector3(0, 1.32, -0.75)
	sb.add_child(cs)
	_porte_fer_n.add_child(sb)


func _show_porte_fer(open: bool, animate: bool) -> void:
	if _porte_fer_n == null:
		return
	var target: float = PI * 0.52 if open else 0.0
	if animate:
		create_tween().tween_property(_porte_fer_n, "rotation:y", target, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		_porte_fer_n.rotation.y = target


## La salle d'armes : comme en V124, mais au fond (nord), une arche et la grille des souterrains
func _build_armes() -> void:
	_b = SK.Batch.new()
	floor_ceil(-6, 22, -59, -31, -8, 10, "dalles_int", "pierre_int")
	walls(-6, 22, -59, -31, -8, 10, "pierre_int", "pierre_int", [["s", 8, 3.6, 4.0], ["n", 8.0, 3.0, 3.8]])
	for z in [-38.0, -45.0, -52.0]:
		for x in [1.0, 15.0]:
			bx("pierre_chateau_claire", Vector3(x, -3.0, z), Vector3(0.9, 10.0, 0.9), 0.0, true)
		bx("pierre_chateau_claire", Vector3(8.0, 1.4, z), Vector3(28.0, 1.2, 0.6))
	cy("sac_sable", Vector3(8.0, -7.99, -46.0), 6.5, 6.5, 0.02, 32)
	for x2 in [-5.3, 21.3]:
		for z2 in [-36.0, -42.0, -50.0]:
			bx("bois_sombre", Vector3(x2, -6.9, z2), Vector3(0.3, 2.2, 2.4), 0.0, true)
			for k in range(5):
				_b.tube("acier", O + Vector3(x2 + (0.12 if x2 < 0 else -0.12), -7.9, z2 - 1.0 + k * 0.5), O + Vector3(x2 + (0.18 if x2 < 0 else -0.18), -5.6, z2 - 1.0 + k * 0.5), 0.02, 5)
	for x3 in [2.0, 14.0]:
		armure_statue(Vector3(x3, -8.0, -58.0), 0.0)
	# V128 : l'arche de la grille des souterrains (avant : une tapisserie rouge)
	doorway(Vector3(8.0, -8.0, -59.0), 0.0, 3.0, 3.8)
	bx("tissu_rouge_sombre", Vector3(8.0 - 3.6, -3.2, -58.65), Vector3(1.2, 6.0, 0.04))
	bx("tissu_rouge_sombre", Vector3(8.0 + 3.6, -3.2, -58.65), Vector3(1.2, 6.0, 0.04))
	for x4 in [-5.6, 21.6]:
		bx("tissu_rouge_sombre", Vector3(x4, -3.5, -46.0), Vector3(0.04, 5.0, 1.8))
	toile("armes", Vector3(-5.5, 1.5, -58.5), -PI * 0.25 + PI, 1.6)
	toile("armes", Vector3(21.5, 1.5, -31.5), PI * 0.25, 1.4)
	_commit("armes", "Salle_armes_v124")
	applique("armes", Vector3(8.0 - 2.6, -5.0, -31.6), Vector3(0, 0, -1))
	applique("armes", Vector3(8.0 + 2.6, -5.0, -31.6), Vector3(0, 0, -1))
	kit.mats["fer124"] = SK.mat("fer_noir")
	kit.mats["pierre124"] = SK.mat("pierre_chateau_claire")
	for p in BRASEROS:
		var br: Dictionary = kit.brazier63(rooms["armes"]["root"], W(p), false, "fer124", 3.0, "pierre124")
		_braseros.append(br)
	_build_grille()


## La grille des souterrains : une herse de fer qui remonte dans le mur
func _build_grille() -> void:
	_grille_n = Node3D.new()
	_grille_n.name = "Grille_souterrains_v128"
	(rooms["armes"]["root"] as Node3D).add_child(_grille_n)
	_grille_n.global_transform = X(Vector3(8.0, -8.0, -59.3))
	var b := SK.Batch.new()
	var k: int = 0
	var x: float = -1.4
	while x <= 1.41:
		b.tube("fer_noir", Vector3(x, 0.0, 0), Vector3(x, 3.85, 0), 0.03, 6)
		b.cyl("fer_noir", Transform3D(Basis(Vector3.RIGHT, PI), Vector3(x, 0.02, 0)), 0.03, 0.0, 0.12, 6)
		x += 0.2
		k += 1
	for yy in [0.6, 1.9, 3.2]:
		b.box("fer_noir", Transform3D(Basis(), Vector3(0, yy, 0)), Vector3(2.95, 0.08, 0.07))
	# la serrure (une grosse boîte de fer rouillé, au milieu)
	b.box("rouille", Transform3D(Basis(), Vector3(0.0, 1.15, 0.06)), Vector3(0.3, 0.38, 0.12))
	b.blob("fer_noir", Vector3(0.0, 1.18, 0.13), Vector3(0.035, 0.05, 0.02), 6)
	b.commit(_grille_n, "Grille")
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.0, 3.8, 0.2)
	cs.shape = sh
	cs.position = Vector3(0, 1.9, 0)
	sb.add_child(cs)
	_grille_n.add_child(sb)


func _show_grille(open: bool, animate: bool) -> void:
	if _grille_n == null:
		return
	var sb: StaticBody3D = _grille_n.get_node("Corps")
	var y0: float = W(Vector3(8.0, -8.0, -59.3)).y
	var target: float = y0 + (3.75 if open else 0.0)
	if animate:
		var tw := create_tween()
		tw.tween_property(_grille_n, "global_position:y", target, 4.0).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): sb.collision_layer = 0 if open else 1)
	else:
		_grille_n.global_position.y = target
		sb.collision_layer = 0 if open else 1


# ------------------------------------------------------------------- la Chambre du Comte

func _build_chambre() -> void:
	_b = SK.Batch.new()
	var y0: float = CH_Y
	floor_ceil(-30, -3.6, -34, -16, y0, 10.5, "parquet", "pierre_int")
	# le mur est est celui de la tour (là où ils se touchent) : on laisse la place
	walls(-30, -3.6, -34, -16, y0, 10.5, "lambris", "damas", [["e", -19.0, 6.0, 16.0 - y0]])
	# côté Chambre, le mur de la tour est tendu de damas (sauf la porte)
	bx("lambris", Vector3(-3.64, y0 + 0.62, -21.65), Vector3(0.04, 1.24, 0.7))
	bx("lambris", Vector3(-3.64, y0 + 0.62, -17.85), Vector3(0.04, 1.24, 3.7))
	bx("damas", Vector3(-3.64, y0 + 1.24 + (16.0 - y0 - 1.24) * 0.5, -21.65), Vector3(0.04, 16.0 - y0 - 1.24, 0.7))
	bx("damas", Vector3(-3.64, y0 + 1.24 + (16.0 - y0 - 1.24) * 0.5, -17.85), Vector3(0.04, 16.0 - y0 - 1.24, 3.7))
	bx("damas", Vector3(-3.64, y0 + 2.7 + (16.0 - y0 - 2.7) * 0.5, -20.5), Vector3(0.04, 16.0 - y0 - 2.7, 1.6))
	doorway(Vector3(-3.75, y0, -20.5), PI * 0.5, 1.6, 2.7)
	# les pilastres entre les fenêtres, la corniche
	for px in [-24.5, -17.5, -10.5, -4.3]:
		bx("pierre_chateau_claire", Vector3(px, y0 + 5.25, -33.72), Vector3(0.6, 10.5, 0.55))
	for pz in [-29.0, -21.0]:
		bx("pierre_chateau_claire", Vector3(-29.72, y0 + 5.25, pz), Vector3(0.55, 10.5, 0.6))
	bx("dorure_terne", Vector3(-16.8, y0 + 10.2, -33.8), Vector3(26.4, 0.18, 0.3))
	bx("dorure_terne", Vector3(-16.8, y0 + 10.2, -16.2), Vector3(26.4, 0.18, 0.3))
	# l'estrade, le cercueil
	bx("marbre_damier", Vector3(-27.4, y0 + 0.2, -25.0), Vector3(5.2, 0.4, 8.0), 0.0, true)
	bx("pierre_chateau_claire", Vector3(-24.5, y0 + 0.1, -25.0), Vector3(0.7, 0.2, 6.0), 0.0, true)
	bx("tapis_rouge", Vector3(-27.4, y0 + 0.41, -25.0), Vector3(4.4, 0.02, 6.6))
	var cof := Vector3(-27.6, y0 + 0.4, -25.0)
	bx("bois_cire", cof + Vector3(0, 0.32, 0), Vector3(2.3, 0.62, 0.86), 0.0, true)
	bx("dorure_terne", cof + Vector3(0, 0.05, 0), Vector3(2.4, 0.1, 0.94))
	bx("velours", cof + Vector3(0, 0.6, 0), Vector3(2.12, 0.04, 0.7))
	# le couvercle, entrouvert, posé de travers
	bx("bois_cire", cof + Vector3(0.25, 0.72, 0.42), Vector3(2.32, 0.1, 0.9), 0.22)
	bx("dorure", cof + Vector3(0.25, 0.79, 0.42), Vector3(0.7, 0.02, 0.06), 0.22)
	bx("dorure", cof + Vector3(0.25, 0.79, 0.42), Vector3(0.06, 0.02, 0.45), 0.22)
	# le grand portrait du comte, au-dessus de l'estrade
	tableau("comte", Vector3(-29.95, y0 + 5.6, -25.0), Vector3(1, 0, 0), 3.2, 4.2, _tex("res://assets/textures/chateau/portrait_comte.png"))
	# les tapis
	bx("tapis_rouge", Vector3(-14.5, y0 + 0.01, -25.0), Vector3(12.0, 0.02, 7.5))
	bx("tapis_rouge", Vector3(-6.4, y0 + 0.01, -20.5), Vector3(5.4, 0.02, 1.7))
	# la cheminée (allumée), le fauteuil du comte, un guéridon
	cheminee("comte", Vector3(-14.0, y0, -16.6), Vector3(0, 0, -1), true)
	tableau("comte", Vector3(-14.0, y0 + 4.4, -16.03), Vector3(0, 0, -1), 2.2, 1.5)
	fauteuil(Vector3(-11.2, y0, -18.6), PI * 0.85)
	cy("bois_cire", Vector3(-9.9, y0, -18.4), 0.3, 0.22, 0.04, 14)
	cy("bois_cire", Vector3(-9.9, y0, -18.4), 0.05, 0.05, 0.72, 8)
	cy("bois_cire", Vector3(-9.9, y0 + 0.72, -18.4), 0.32, 0.32, 0.04, 14)
	cy("dorure", Vector3(-9.85, y0 + 0.76, -18.35), 0.04, 0.035, 0.1, 10)
	cy("dorure", Vector3(-9.85, y0 + 0.86, -18.35), 0.008, 0.008, 0.06, 6)
	cy("dorure", Vector3(-9.85, y0 + 0.92, -18.35), 0.035, 0.045, 0.08, 10)
	candle(Vector3(-10.05, y0 + 0.76, -18.55), 0.15)
	# les livres du comte (le long du mur sud, à l'ouest)
	etageres(Vector3(-29.4, y0, -16.45), Vector3(-19.5, y0, -16.45), Vector3(0, 0, -1), 3.0)
	# les armures de chaque côté de la porte
	armure_statue(Vector3(-5.0, y0, -23.0), -PI * 0.5)
	armure_statue(Vector3(-5.0, y0, -17.6), -PI * 0.5)
	# une longue table, oubliée, sous la poussière
	table(Vector3(-15.5, y0, -31.6), 6.0, 1.3, 0.0, "bois_cire", true)
	bx("drap_poussiere", Vector3(-15.5, y0 + 0.8, -31.6), Vector3(6.1, 0.03, 1.4))
	for k in range(3):
		candle(Vector3(-17.5 + k * 2.0, y0 + 0.8, -31.6), 0.18)
	_commit("comte", "Chambre_comte_v128")
	# les grandes fenêtres, leurs vitraux, les rideaux
	for i in range(FENETRES.size()):
		var fx: float = FENETRES[i]
		vitrail("comte", Vector3(fx, y0 + 4.9, -33.98), Vector3(0, 0, 1), 3.0, 6.4)
		_build_aube(i, fx)
		_build_rideau(i, fx)
	# les lumières : le lustre, les candélabres, les appliques (une pénombre rouge)
	_b = SK.Batch.new()
	lustre("comte", Vector3(-15.0, y0 + 7.3, -25.0), 1.5, y0 + 10.5)
	for cz in [-28.6, -21.4]:
		candelabre("comte", Vector3(-25.2, y0 + 0.4, cz))
	for e in [[Vector3(-29.95, y0 + 2.6, -18.5), Vector3(1, 0, 0)], [Vector3(-29.95, y0 + 2.6, -31.5), Vector3(1, 0, 0)],
			[Vector3(-3.66, y0 + 2.6, -27.5), Vector3(-1, 0, 0)], [Vector3(-3.66, y0 + 2.6, -32.0), Vector3(-1, 0, 0)]]:
		applique("comte", e[0], e[1])
	toile("comte", Vector3(-29.5, y0 + 10.0, -33.5), PI * 0.25, 1.6)
	toile("comte", Vector3(-4.1, y0 + 10.0, -16.5), -PI * 0.75, 1.3)
	_commit("comte", "Chambre_comte_lumieres_v128")
	light("comte", Vector3(-26.0, y0 + 3.0, -25.0), 0.9, 7.0, Color(1.0, 0.18, 0.1))


## Derrière chaque rideau : le vitrail dans la lumière de l'aube, et le grand rayon qui entre
func _build_aube(i: int, fx: float) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.0, 6.4)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	var base: Material = SK.mat("vitrail_comte")
	if base is StandardMaterial3D and (base as StandardMaterial3D).albedo_texture != null:
		m.albedo_texture = (base as StandardMaterial3D).albedo_texture
		m.emission_texture = (base as StandardMaterial3D).albedo_texture
	m.albedo_color = Color(1.0, 0.86, 0.72)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.78, 0.58)
	m.emission_energy_multiplier = 2.6
	m.roughness = 0.2
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(rooms["comte"]["root"] as Node3D).add_child(mi)
	mi.global_transform = X(Vector3(fx, CH_Y + 4.9, -33.94))
	mi.visible = false
	var sp := SpotLight3D.new()
	sp.light_color = Color(1.0, 0.74, 0.52)
	sp.light_energy = 0.0
	sp.spot_range = 22.0
	sp.spot_angle = 30.0
	sp.spot_attenuation = 0.7
	sp.shadow_enabled = pc
	sp.light_volumetric_fog_energy = 2.0
	(rooms["comte"]["root"] as Node3D).add_child(sp)
	sp.global_position = W(Vector3(fx, CH_Y + 7.4, -33.6))
	sp.look_at(W(Vector3(fx - 1.5, CH_Y, -23.0)), Vector3.UP)
	sp.visible = false
	_aubes.append([mi, sp])


## Un grand rideau de velours rouge, pendu à sa tringle dorée (le nœud est la tringle)
func _build_rideau(_i: int, fx: float) -> void:
	var rod := Node3D.new()
	rod.name = "Rideau_v128"
	(rooms["comte"]["root"] as Node3D).add_child(rod)
	rod.global_transform = X(Vector3(fx, CH_Y + 8.5, -33.62))
	var b := SK.Batch.new()
	b.tube("dorure", Vector3(-2.1, 0.12, 0), Vector3(2.1, 0.12, 0), 0.04, 8)
	for s in [-1.0, 1.0]:
		b.blob("dorure", Vector3(s * 2.15, 0.12, 0), Vector3(0.08, 0.08, 0.08), 8)
	b.commit(rod, "Tringle")
	var drap := Node3D.new()
	drap.name = "Drap"
	rod.add_child(drap)
	var b2 := SK.Batch.new()
	# des plis : de longues bandes, un peu en zigzag
	var nf: int = 14
	for k in range(nf):
		var x0: float = -1.9 + k * (3.8 / nf)
		var zz: float = 0.07 if k % 2 == 0 else -0.03
		b2.box("velours", Transform3D(Basis(Vector3.UP, 0.32 if k % 2 == 0 else -0.32), Vector3(x0 + 3.8 / nf * 0.5, -4.0, zz)), Vector3(3.8 / nf + 0.06, 8.0, 0.05))
	b2.box("dorure_terne", Transform3D(Basis(), Vector3(0, -7.95, 0.04)), Vector3(3.9, 0.1, 0.12))
	b2.commit(drap, "Velours")
	_rideaux.append([rod, false])


func _show_rideau(i: int, torn: bool, animate: bool) -> void:
	if i >= _rideaux.size():
		return
	var drap: Node3D = (_rideaux[i][0] as Node3D).get_node("Drap")
	_rideaux[i][1] = torn
	var a: Array = _aubes[i]
	if not torn:
		drap.position = Vector3.ZERO
		drap.scale = Vector3.ONE
		drap.rotation = Vector3.ZERO
		drap.visible = true
		(a[0] as MeshInstance3D).visible = false
		(a[1] as SpotLight3D).visible = false
		(a[1] as SpotLight3D).light_energy = 0.0
		return
	(a[0] as MeshInstance3D).visible = true
	(a[1] as SpotLight3D).visible = true
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(drap, "position", Vector3(0, -8.3, 0.9), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(drap, "scale", Vector3(1.15, 0.05, 6.0), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(a[1], "light_energy", 7.0, 2.5).set_trans(Tween.TRANS_SINE)
	else:
		drap.position = Vector3(0, -8.3, 0.9)
		drap.scale = Vector3(1.15, 0.05, 6.0)
		(a[1] as SpotLight3D).light_energy = 7.0


func torn_count() -> int:
	var n: int = 0
	for r in _rideaux:
		if bool(r[1]):
			n += 1
	return n


# ------------------------------------------------------------------- les souterrains

func _cell_zc(c: int) -> float:
	return CELL_Z0 - CELL_L * (float(c % 5) + 0.5)


func _cell_x(c: int) -> float:
	return -0.6 if c < 5 else 16.6


## Où l'on se tient, dans le couloir, pour ouvrir une cellule
func _cell_front(c: int) -> Vector3:
	return Vector3(6.1 if c < 5 else 9.9, -8.0, _cell_zc(c))


## Où il se tient, une fois sorti (dans le couloir, à côté de sa porte)
func _cell_out(c: int) -> Vector3:
	return Vector3((4.7 + 0.8) if c < 5 else (11.3 - 0.8), -7.95, _cell_zc(c) - 1.3)


func _build_cachots() -> void:
	_b = SK.Batch.new()
	floor_ceil(-6, 22, -97, -60, -8, 5, "dalles_int", "pierre_int")
	walls(-6, 22, -97, -60, -8, 5, "pierre_int", "pierre_int", [["s", 8.0, 3.0, 3.8]])
	# les arcs de la voûte, au-dessus du couloir
	for k in range(6):
		var z: float = CELL_Z0 - k * CELL_L
		bx("pierre_chateau_claire", Vector3(8.0, -3.35, z - (0.25 if k == 0 else 0.0) + (0.25 if k == 5 else 0.0)), Vector3(6.6, 0.7, 0.5))
	# les murs entre les cellules, les piliers, les linteaux au-dessus des barreaux
	for k2 in range(6):
		var zb: float = CELL_Z0 - k2 * CELL_L
		if k2 > 0 and k2 < 5:
			bx("pierre_int", Vector3(-0.65, -5.5, zb), Vector3(10.7, 5.0, 0.5), 0.0, true)
			bx("pierre_int", Vector3(16.65, -5.5, zb), Vector3(10.7, 5.0, 0.5), 0.0, true)
		for sx in [4.7, 11.3]:
			bx("pierre_chateau_claire", Vector3(sx, -5.5, zb + (-0.3 if k2 == 0 else (0.3 if k2 == 5 else 0.0))), Vector3(0.55, 5.0, 0.6), 0.0, true)
	for c in range(10):
		var zc: float = _cell_zc(c)
		var bxp: float = 4.7 if c < 5 else 11.3
		bx("pierre_int", Vector3(bxp, -3.8, zc), Vector3(0.5, 1.6, CELL_L - 0.6), 0.0, true)
		# les barreaux fixes (de part et d'autre de la porte)
		for seg in [[zc + 0.7, zc + CELL_L * 0.5 - 0.3], [zc - CELL_L * 0.5 + 0.3, zc - 0.7]]:
			var za: float = seg[0]
			var zz: float = seg[1]
			var z1: float = za
			while z1 <= zz + 0.001:
				_b.tube("fer_noir", O + Vector3(bxp, -8.0, z1), O + Vector3(bxp, -4.6, z1), 0.026, 6)
				z1 += 0.15
			for yy in [-7.7, -6.0, -4.65]:
				bx("fer_noir", Vector3(bxp, yy, (za + zz) * 0.5), Vector3(0.07, 0.07, zz - za + 0.05))
			kit.col_box(X(Vector3(bxp, -6.3, (za + zz) * 0.5)), Vector3(0.14, 3.4, zz - za + 0.06))
		# dans la cellule : la paille, un banc, un seau, des chaînes au mur
		var cx: float = _cell_x(c)
		var back: float = -5.6 if c < 5 else 21.6
		bx("sac_sable", Vector3((back + cx) * 0.5, -7.97, zc + 1.6), Vector3(2.4, 0.06, 1.6), 0.15)
		bx("bois_pourri", Vector3(back + (0.5 if c < 5 else -0.5), -7.55, zc - 1.2), Vector3(0.6, 0.08, 2.4), 0.0, true)
		for sz in [-2.2, -0.2]:
			bx("bois_pourri", Vector3(back + (0.5 if c < 5 else -0.5), -7.8, zc + sz), Vector3(0.5, 0.42, 0.08))
		cy("bois_pourri", Vector3(cx + (1.6 if c < 5 else -1.6), -8.0, zc - 2.8), 0.2, 0.17, 0.4, 10)
		for s in [-1.0, 1.0]:
			var wa: Vector3 = Vector3(back + (0.08 if c < 5 else -0.08), -5.6, zc + s * 1.0)
			_b.blob("rouille", O + wa, Vector3(0.06, 0.06, 0.06), 6)
			for k3 in range(6):
				_b.tube("rouille", O + wa + Vector3(0, -k3 * 0.22, 0), O + wa + Vector3(0, -(k3 + 1) * 0.22, 0.02 * s), 0.02, 4)
	# au fond du couloir : une lucarne murée, de la mousse, une toile d'araignée
	bx("pierre_chateau_claire", Vector3(8.0, -5.2, -96.7), Vector3(1.4, 0.9, 0.2))
	toile("cachots", Vector3(5.5, -3.6, -96.5), PI * 0.25, 1.4)
	toile("cachots", Vector3(10.5, -3.6, -60.6), -PI * 0.75, 1.2)
	_commit("cachots", "Souterrains_v128")
	# les torches (sur les piliers, côté couloir)
	_b = SK.Batch.new()
	for k4 in [1, 3]:
		var zb2: float = CELL_Z0 - k4 * CELL_L
		applique("cachots", Vector3(5.02, -5.4, zb2), Vector3(1, 0, 0))
		applique("cachots", Vector3(10.98, -5.4, zb2), Vector3(-1, 0, 0))
	applique("cachots", Vector3(8.0, -5.2, -96.6), Vector3(0, 0, 1))
	_commit("cachots", "Souterrains_torches_v128")
	# les portes des cellules
	for c2 in range(10):
		_build_cell_door(c2)


## La porte d'une cellule : des barreaux sur une charnière (au sud) ; elle s'ouvre vers le couloir
func _build_cell_door(c: int) -> void:
	var zc: float = _cell_zc(c)
	var bxp: float = 4.7 if c < 5 else 11.3
	var h := Node3D.new()
	h.name = "Cellule_%d" % c
	(rooms["cachots"]["root"] as Node3D).add_child(h)
	h.global_transform = X(Vector3(bxp, -8.0, zc + 0.7))
	var b := SK.Batch.new()
	var z: float = -0.08
	while z >= -1.33:
		b.tube("fer_noir", Vector3(0, 0.02, z), Vector3(0, 3.38, z), 0.026, 6)
		z -= 0.15
	for yy in [0.3, 1.7, 3.35]:
		b.box("fer_noir", Transform3D(Basis(), Vector3(0, yy, -0.7)), Vector3(0.07, 0.07, 1.4))
	b.box("rouille", Transform3D(Basis(), Vector3(0, 1.15, -1.25)), Vector3(0.12, 0.26, 0.16))
	b.commit(h, "Barreaux")
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.14, 3.4, 1.4)
	cs.shape = sh
	cs.position = Vector3(0, 1.7, -0.7)
	sb.add_child(cs)
	h.add_child(sb)
	_cell_doors[c] = h


func _show_cell(c: int, open: bool, animate: bool) -> void:
	var h: Node3D = _cell_doors.get(c, null)
	if h == null:
		return
	var target: float = ((-1.0 if c < 5 else 1.0) * PI * 0.55) if open else 0.0
	if animate:
		create_tween().tween_property(h, "rotation:y", target, 1.4).set_trans(Tween.TRANS_SINE)
	else:
		h.rotation.y = target


## V126 (comme les autres grandes salles) : une lumière douce cachée sous les plafonds
func _fill_lights128() -> void:
	for e in [["comte", 2, 2, 0.32, Color(1.0, 0.62, 0.5)], ["cachots", 1, 4, 0.4, Color(1.0, 0.72, 0.5)]]:
		var rn: String = e[0]
		var a: Vector3 = rooms[rn]["a"]
		var b: Vector3 = rooms[rn]["b"]
		var nx: int = e[1]
		var nz: int = e[2]
		var y: float = minf(a.y + 4.2, b.y - 1.0)
		for i in range(nx):
			for k in range(nz):
				var lt := OmniLight3D.new()
				lt.name = "Appoint_v128"
				lt.light_color = e[4]
				lt.light_energy = float(e[3])
				lt.omni_range = 14.0
				lt.omni_attenuation = 0.8
				lt.shadow_enabled = false
				lt.light_specular = 0.2
				(rooms[rn]["root"] as Node3D).add_child(lt)
				lt.global_position = W(Vector3(lerpf(a.x, b.x, (i + 0.5) / nx), y, lerpf(a.z, b.z, (k + 0.5) / nz)))


# =================================================================== les invites

func _register() -> void:
	super._register()
	var me = self
	# la porte de fer ne sert plus une fois ouverte
	for it in _ia:
		if str(it.get("id", "")) == key + "_porte_fer":
			it["when"] = func(): return me.built and me.room != "" and int(me.state["poses"]) >= 3 and not bool(me.state["chambre"])
	for i in range(FENETRES.size()):
		var k: int = i
		ia("rideau_%d" % i, Vector3(float(FENETRES[i]), CH_Y, -32.2), 2.6, "E : arracher le rideau", "Gâchette : arracher le rideau",
			func(): me._arracher(k), func(): return me.fight and me._dracula != null and k < me._rideaux.size() and not bool(me._rideaux[k][1]))
	ia("cercueil", Vector3(-25.6, CH_Y, -25.0), 1.8, "E : regarder le cercueil", "Gâchette : le cercueil",
		func(): me._cercueil(), func(): return not me.fight)
	ia("grille", Vector3(8.0, -8.0, -57.6), 2.4, "E : examiner la grille", "Gâchette : la grille",
		func(): me._grille(), func(): return not bool(me.state["grille"]))
	for e in CAPTIFS:
		var id: String = str(e[0])
		var c: int = int(e[3])
		ia("cellule_" + id, _cell_front(c), 1.7, str(e[4]), "Gâchette : ouvrir la cellule",
			func(): me._ouvrir(id), func(): return not me._cell_open(id))
		ia("captif_" + id, _cell_front(c), 2.4, str(PARLER.get(id, "E : parler")), "Gâchette : parler",
			func(): me._captif_talk(id), func(): return me._cell_open(id) and me._captifs.has(id) and is_instance_valid(me._captifs[id]))




func _apply_state() -> void:
	super._apply_state()
	_show_porte_fer(bool(state["chambre"]), false)
	_show_grille(bool(state["grille"]), false)
	for e in CAPTIFS:
		_show_cell(int(e[3]), _cell_open(str(e[0])), false)
	for i in range(_rideaux.size()):
		_show_rideau(i, bool(state["comte"]), false)
	room_spawns = {} if bool(state["comte"]) else _spawns124.duplicate(true)


# =================================================================== entrer, les salles

func _enter_room(old: String, r: String) -> void:
	super._enter_room(old, r)
	match r:
		"comte":
			if bool(state["comte"]):
				_once("comte_fin", "La Chambre du Comte. L'aube entre à flots par les trois grandes fenêtres. Il ne reste du comte qu'un peu de poussière sur les dalles… et le silence.", 6.0)
		"cachots":
			if bool(state["libres"]):
				_once("cachots_vides", "Les souterrains. Les cellules sont ouvertes, et vides. Il ne reste que la paille… et des centaines de petits traits gravés dans les murs.", 6.0)
			else:
				_once("cachots", "Les souterrains du château. Une odeur de paille humide, des chaînes aux murs… et des visages derrière les barreaux. « Quelqu'un ! Il y a quelqu'un ! »", 7.0)


func _spawn_people(r: String) -> void:
	super._spawn_people(r)
	var mo: Node = main.get("monstres_v36")
	if mo == null or not bool(mo.get("_was_inside")):
		return
	if r == "comte" and not bool(state["comte"]) and (_dracula == null or not is_instance_valid(_dracula)):
		_phase = 0
		_dracula = _npc("dracula", DRAC_HOME, Vector3(1, 0, 0))
		_dial_t = 1.4
	if r == "cachots" and _captifs.is_empty() and not bool(state["libres"]):
		for e in CAPTIFS:
			var c: int = int(e[3])
			var open: bool = _cell_open(str(e[0]))
			Monster124.next_corps = str(e[2])
			var at: Vector3 = Vector3(_cell_x(c) + (1.6 if c < 5 else -1.6), -7.95, _cell_zc(c) + 0.4)
			if open:
				at = _cell_out(c)
			var m: Node3D = _npc("captif", at, Vector3(1 if c < 5 else -1, 0, 0))
			_captifs[str(e[0])] = m


func _free_people() -> void:
	super._free_people()
	var mo: Node = main.get("monstres_v36")
	var all: Array = _captifs.values()
	all.append(_dracula)
	for m in all:
		if m != null and is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			(m as Node).queue_free()
	_captifs.clear()
	_dracula = null
	_phase = 0


func _on_reset() -> void:
	super._on_reset()
	# le combat reprendra à zéro : les rideaux sont de nouveau tirés (sauf si le comte est vaincu)
	if not bool(state["comte"]):
		for i in range(_rideaux.size()):
			_show_rideau(i, false, false)
	_brume_t = 0.0


func _faint_text() -> String:
	if room == "comte" and not bool(state["comte"]):
		return "Mortimer t'a redescendu jusqu'à la porte. « Monsieur le Comte n'aime pas qu'on abîme ses tapis », a-t-il murmuré."
	return super._faint_text()


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	super._tick(delta, p, r)
	if r == "comte":
		_comte_tick(delta)
	if r == "cachots":
		_cachots_tick(L(p))


func _comte_tick(delta: float) -> void:
	if _dial_t > 0.0:
		_dial_t -= delta
		if _dial_t <= 0.0 and _dracula != null and is_instance_valid(_dracula) and str(_dracula.state) == "parle":
			_dracula_talk()
	if not fight or _dracula == null or not is_instance_valid(_dracula):
		return
	# en brume rouge : il disparaît plus souvent, une fumée rouge le suit
	if bool(_dracula.invuln):
		_brume_t -= delta
		if _brume_t <= 0.0:
			_brume_t = 0.5
			_dracula._mist124(_dracula.global_position + Vector3.UP * 1.1)
	elif torn_count() > 0:
		# dans la lumière de l'aube, il fume
		_fume_t -= delta
		if _fume_t <= 0.0 and main.get("combat_v28") != null and main.combat_v28 != null:
			_fume_t = 0.6
			main.combat_v28.puff(_dracula.global_position + Vector3.UP * randf_range(0.8, 1.7), Color(0.62, 0.58, 0.55))


## Les phases du comte (les enfants : comme en V124)
func _boss_phases() -> void:
	if not fight or _boss == null or not is_instance_valid(_boss) or str(_boss.kind) != "dracula":
		super._boss_phases()
		return
	var ratio: float = float(_boss.hp) / float(_boss.spec["pv"])
	if _phase == 1 and ratio < 0.7:
		_phase = 2
		_sfx("vampire_rire", _boss.global_position + Vector3.UP * 1.8)
		_sfx("nuee_chauves_souris", _boss.global_position + Vector3.UP * 2.0)
		_boss.bats_burst(_boss.global_position + Vector3.UP * 1.3, 8)
		if torn_count() < _rideaux.size():
			_boss.invuln = true
			_boss.spec["brume"] = 3.0
			_say("Le comte éclate de rire et se change en brume rouge : tes coups le traversent ! « Tant que ces rideaux resteront tirés, je suis éternel ! » Derrière les rideaux… le jour se lève. Arrache-les (E) !", 8.0)
		else:
			_say("Le comte essaie de se changer en brume… mais l'aube le brûle, et la brume se déchire !", 5.0)
		for s in [-1.0, 1.0]:
			var at: Vector3 = L(_boss.global_position) + Vector3(s * 2.5, 0.05, 2.0)
			at.y = CH_Y + 0.05
			var m: Node3D = spawn_in(room, "vampire", at, true)
			if m != null:
				m.bats_burst(m.global_position + Vector3.UP * 1.3, 4)
	elif _phase == 2 and ratio < 0.36:
		_phase = 3
		_say("« Mes enfants de la nuit… À moi ! » Des loups noirs surgissent de l'ombre, derrière la cheminée !", 5.0)
		_sfx("loup_menace", W(Vector3(-14.0, CH_Y + 1.0, -17.5)))
		for k in range(3):
			var at2: Vector3 = Vector3(-17.0 + k * 3.0, CH_Y + 0.05, -18.2)
			var w: Node3D = spawn_in(room, "loup", at2, true)
			if w != null and main.get("combat_v28") != null and main.combat_v28 != null:
				main.combat_v28.puff(w.global_position + Vector3.UP * 0.6, Color(0.12, 0.1, 0.12))


func _cachots_tick(l: Vector3) -> void:
	if bool(state["libres"]):
		return
	for e in CAPTIFS:
		var id: String = str(e[0])
		if _cell_open(id) or _said.has("cri_" + id):
			continue
		var f: Vector3 = _cell_front(int(e[3]))
		if Vector2(f.x - l.x, f.z - l.z).length() < 3.2:
			_said["cri_" + id] = true
			_say(str(CRIS[_said.size() % CRIS.size()]), 3.0)
			if _captifs.has(id) and is_instance_valid(_captifs[id]):
				_captifs[id].set_speaking(true)
				var m: Node3D = _captifs[id]
				get_tree().create_timer(2.5).timeout.connect(func(): if is_instance_valid(m): m.set_speaking(false))
			return


# =================================================================== le comte

func _porte_fer() -> void:
	if bool(state["chambre"]):
		return
	state["chambre"] = true
	state["tour"] = true
	_sfx("serrure", W(Vector3(-3.3, CH_Y + 1.2, -20.5)))
	get_tree().create_timer(0.8).timeout.connect(func(): _sfx("porte_grince", W(Vector3(-3.3, CH_Y + 1.4, -20.5))))
	_show_porte_fer(true, true)
	_say("Tu poses la main sur la porte de fer… et elle s'ouvre toute seule, très lentement. Derrière : une grande chambre rouge et noire, trois rideaux immenses, un cercueil sur une estrade. Et quelqu'un, debout dans la pénombre, qui t'attendait.", 8.0)
	if main.has_method("jingle"):
		main.jingle("decouverte")
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()


func _dracula_talk() -> void:
	if _dracula == null or not is_instance_valid(_dracula) or fight:
		return
	var at: Vector3 = _dracula.global_position + Vector3.UP * 1.85
	_dracula.set_speaking(true)
	var t: String
	if not bool(state["comte_vu"]):
		state["comte_vu"] = true
		t = "« Bienvenue chez moi, petit voyageur. » Le comte s'avance sans un bruit. Grand, très pâle, une cape noire doublée de rouge ; ses yeux brillent comme deux braises. « Tu as vaincu mes enfants. Tu as lu les gribouillages de ce pauvre docteur. Et te voilà, dans ma chambre, à l'heure où la nuit s'achève… Que veux-tu ? »"
	else:
		t = "« Encore toi ? » Le comte sourit, et ses dents brillent. « Tu es tenace, petit voyageur. J'aime ça. Mais l'aube ne viendra pas. Pas tant que je serai là. »"
	_ask(at, "Le comte Dracula", "moqueur", t,
		[{"id": "liberer", "label": "Libérez les gens de Sombreval !"}, {"id": "pourquoi", "label": "Pourquoi faites-vous tout ça ?"},
		{"id": "combat", "label": "Je suis venu vous vaincre."}],
		Callable(self, "_dracula_answer"))


func _dracula_answer(id: String) -> void:
	if _dracula == null or not is_instance_valid(_dracula):
		_close_dialog()
		return
	var at: Vector3 = _dracula.global_position + Vector3.UP * 1.85
	match id:
		"liberer":
			_ask(at, "Le comte Dracula", "moqueur",
				"« Les libérer ? » Il rit, tout doucement. « Ceux qui dorment dans mes souterrains m'appartiennent, comme ceux qui marchent dans mes rues. Et la clé ne quitte jamais mon cou. » Il effleure une grosse clé de fer, pendue à une chaîne. « Viens la prendre… si tu l'oses. »",
				[{"id": "pourquoi", "label": "Pourquoi faites-vous tout ça ?"}, {"id": "combat", "label": "Je suis venu vous vaincre."}], Callable(self, "_dracula_answer"))
		"pourquoi":
			_ask(at, "Le comte Dracula", "triste",
				"« Pourquoi ? » Il regarde les grands rideaux rouges. « Il y a trois cents ans, une ville toute pareille m'a chassé avec des torches. J'ai juré qu'aucune ville ne dormirait plus jamais sans moi. Ici, toutes les horloges se sont arrêtées à minuit : la nuit ne finit jamais. » Un silence. « Enfin… presque jamais. » Derrière les rideaux, une lueur pâle.",
				[{"id": "liberer", "label": "Libérez les gens de Sombreval !"}, {"id": "combat", "label": "Je suis venu vous vaincre."}], Callable(self, "_dracula_answer"))
		_:
			_close_dialog()
			_dracula.set_speaking(false)
			_comte_combat()


func _comte_combat() -> void:
	if _dracula == null or not is_instance_valid(_dracula):
		return
	_say("« Bien ! » Le comte ouvre les bras ; sa cape se déploie comme deux grandes ailes. « Alors dansons, petit voyageur. Une dernière valse avant l'aube ! »", 5.0)
	_sfx("vampire_rire", _dracula.global_position + Vector3.UP * 1.8)
	_phase = 1
	_dracula.invuln = false
	_dracula.on_invuln_hit = Callable(self, "_comte_brume")
	_dracula.home = W(Vector3(-15.0, CH_Y + 0.05, -25.0))
	_fight_with(_dracula, "Le comte Dracula", Callable(self, "_comte_dead"))


var _brume_dit: bool = false


func _comte_brume() -> void:
	if _brume_dit:
		return
	_brume_dit = true
	_say("Ta lame traverse le comte comme une fumée rouge… Les rideaux ! Arrache les trois grands rideaux des fenêtres (E) pour laisser entrer l'aube.", 7.0)


func _arracher(k: int) -> void:
	if k >= _rideaux.size() or bool(_rideaux[k][1]):
		return
	_show_rideau(k, true, true)
	var at: Vector3 = W(Vector3(float(FENETRES[k]), CH_Y + 4.0, -33.4))
	_sfx("fendre_lourd", at)
	get_tree().create_timer(0.7).timeout.connect(func(): _sfx("sable_effondre", W(Vector3(float(FENETRES[k]), CH_Y + 0.3, -32.8))))
	if main.get("combat_v28") != null and main.combat_v28 != null:
		get_tree().create_timer(0.7).timeout.connect(func(): main.combat_v28.puff(W(Vector3(float(FENETRES[k]), CH_Y + 0.4, -32.6)), Color(0.55, 0.45, 0.4)))
	var n: int = torn_count()
	if _dracula != null and is_instance_valid(_dracula):
		_sfx("vampire_siffle", _dracula.global_position + Vector3.UP * 1.6)
	if n < _rideaux.size():
		_say("Le rideau tombe dans un nuage de poussière ! Une lumière rose et dorée entre dans la chambre. Le comte recule en sifflant. (%d sur %d)" % [n, _rideaux.size()], 4.5)
		return
	_say("Le dernier rideau tombe. L'aube inonde la chambre ! Le comte pousse un cri terrible ; sa brume se déchire en lambeaux : il est à ta merci !", 6.0)
	if _dracula != null and is_instance_valid(_dracula):
		_dracula.invuln = false
		_dracula.spec["brume"] = 7.0
		_dracula.spec["vitesse"] = float(_dracula.spec["vitesse"]) * 0.85
		_sfx("boss_cri", _dracula.global_position + Vector3.UP * 1.8)


func _cercueil() -> void:
	if bool(state["comte"]):
		_say("Le cercueil est vide. Au fond, sur le velours rouge, un peu de terre noire… la terre de son pays, qu'il avait apportée de très loin.", 6.0)
	else:
		_say("Un cercueil de bois noir, verni comme un miroir. Le couvercle est entrouvert. À l'intérieur, sur le velours rouge… un peu de terre. Et l'empreinte d'un très grand corps.", 6.0)
	_sfx("couvercle", W(Vector3(-27.6, CH_Y + 1.0, -25.0)))


func _comte_dead() -> void:
	state["comte"] = true
	_dracula = null
	_phase = 0
	room_spawns = {}
	var dust: String = "en cendres et en braises" if Public.averti() else "en poussière, dans un grand éclat de lumière"
	_say("« Non… Pas la lumière… Pas maintenant… » Le comte Dracula chancelle dans le soleil levant, tend la main vers toi… et s'effondre %s." % dust, 8.0)
	for i in range(_rideaux.size()):
		if not bool(_rideaux[i][1]):
			_show_rideau(i, true, true)
	get_tree().create_timer(5.5).timeout.connect(_cle_tombe)
	get_tree().create_timer(13.0).timeout.connect(func():
		if sv != null and sv.has_method("liberer"):
			sv.liberer(true))
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()


func _cle_tombe() -> void:
	state["cle"] = true
	var at: Vector3 = _feet() + Vector3.UP * 0.5
	_sfx("ramasse", at)
	var inv: Node = _inv()
	if inv != null and inv.add("cle_souterrains", 1) <= 0:
		inv.spawn_pickup(key + "_cle", "cle_souterrains", 1, at)
	_say("Une grosse clé de fer tombe sur les dalles avec un bruit clair. Tu la ramasses : la clé des souterrains ! (La grille est au fond de la salle d'armes.)", 7.0)
	if main.has_method("jingle"):
		main.jingle("decouverte")


# =================================================================== les souterrains

func _grille() -> void:
	if not bool(state["cle"]):
		_say("Une lourde grille de fer, fermée par une serrure énorme. De l'autre côté, un long couloir noir… et, tout au fond, quelqu'un qui pleure. Il faudrait la clé du comte.", 6.0)
		_sfx("grille", W(Vector3(8.0, -6.8, -59.3)))
		return
	state["grille"] = true
	_sfx("serrure", W(Vector3(8.0, -6.8, -59.2)))
	get_tree().create_timer(0.9).timeout.connect(func(): _sfx("herse_monte", W(Vector3(8.0, -5.0, -59.3))))
	_show_grille(true, true)
	_say("La clé du comte tourne dans la serrure avec un grincement terrible. La grille remonte lentement dans le mur… Un courant d'air froid. Des voix, tout au fond : « Quelqu'un vient ! »", 7.0)
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()


func _cell_open(id: String) -> bool:
	return bool((state["cellules"] as Dictionary).get(id, false)) or bool(state["libres"])


func _captif(id: String) -> Array:
	for e in CAPTIFS:
		if str(e[0]) == id:
			return e
	return []


func _ouvrir(id: String) -> void:
	var e: Array = _captif(id)
	if e.is_empty() or _cell_open(id):
		return
	var c: int = int(e[3])
	state["cellules"][id] = true
	_sfx("serrure", W(_cell_front(c) + Vector3(-1.4 if c < 5 else 1.4, 1.2, 0)))
	_show_cell(c, true, true)
	get_tree().create_timer(0.5).timeout.connect(func(): _sfx("porte_grince", W(_cell_front(c) + Vector3(0, 1.5, 0))))
	var m: Node3D = _captifs.get(id, null)
	if m != null and is_instance_valid(m):
		# il passe la porte et s'arrête dans le couloir
		var bxp: float = 4.7 if c < 5 else 11.3
		var door: Vector3 = W(Vector3(bxp + (-0.6 if c < 5 else 0.6), -7.95, _cell_zc(c)))
		var to: Vector3 = W(_cell_out(c))
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(m, "global_position", door, 1.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(m, "global_position", to, 0.9).set_trans(Tween.TRANS_SINE)
		m.set_speaking(true)
		get_tree().create_timer(3.2).timeout.connect(func():
			if is_instance_valid(m):
				m.set_speaking(false)
				m.home = to)
	var n: int = 0
	for e2 in CAPTIFS:
		if _cell_open(str(e2[0])):
			n += 1
	var me = self
	get_tree().create_timer(1.6).timeout.connect(func():
		var who: Node3D = me._captifs.get(id, null)
		var at: Vector3 = (who.global_position if who != null and is_instance_valid(who) else me.W(me._cell_front(c))) + Vector3.UP * 1.75
		me._ask(at, me._titre(str(e[1])), "ravi", str(e[5]) + "  (%d sur %d)" % [n, CAPTIFS.size()],
			[{"id": "ok", "label": "Rentrez vite chez vous !"}], Callable(me, "_captif_fin")))


func _captif_fin(_id: String) -> void:
	_close_dialog()
	for e in CAPTIFS:
		if not _cell_open(str(e[0])):
			return
	if bool(state["libres"]):
		return
	state["libres"] = true
	get_tree().create_timer(0.8).timeout.connect(func():
		_say("Les huit prisonniers sont libres ! Ils se serrent dans les bras, ils pleurent, ils rient… « On rentre à la maison ! » Ils t'attendront sur la Place du Marché, à Sombreval.", 8.0)
		_sfx("foule_acclame", _feet() + Vector3.UP * 1.5)
		_reward("piece_or", "Libérateur de Sombreval", 150, _feet() + Vector3.UP * 0.5)
		var j: Node = main.get("journal_v56")
		if j != null and j.has_method("refresh"):
			j.refresh())


func _captif_talk(id: String) -> void:
	var e: Array = _captif(id)
	var m: Node3D = _captifs.get(id, null)
	if e.is_empty() or m == null or not is_instance_valid(m):
		return
	_ask(m.global_position + Vector3.UP * 1.75, _titre(str(e[1])), "ému", str(e[6]),
		[{"id": "ok", "label": "Courage, c'est fini."}], Callable(self, "_captif_fin"))


static func _titre(nom: String) -> String:
	return nom.substr(0, 1).to_upper() + nom.substr(1)


# =================================================================== Mortimer (V128)

func _mortimer_talk() -> void:
	if _mortimer == null or not is_instance_valid(_mortimer):
		return
	if not bool(state["mortimer"]):
		super._mortimer_talk()
		return
	var at: Vector3 = _mortimer.global_position + Vector3.UP * 1.7
	var t: String
	if bool(state["libres"]):
		t = "« Ils sont tous rentrés chez eux ? » Mortimer sourit, pour la première fois. « Je leur ai porté du thé, avant qu'ils partent. Ils ne l'ont pas bu. Ils avaient un peu peur de moi… Je ne leur en veux pas. »"
	elif bool(state["comte"]):
		t = "« Monsieur le Comte… n'est plus. » Mortimer soupire, très longtemps. « Trois cent douze ans de service. Je crois que je vais enfin prendre des vacances. » Puis, plus bas : « Les souterrains sont derrière la grille, au fond de la salle d'armes. Elle s'ouvre avec la clé que vous portez. Libérez-les. Je vous en prie. »"
	elif int(state["poses"]) >= 3:
		t = "« La tour est ouverte… » Mortimer regarde ses chaussures. « Monsieur le Comte vous attend dans sa chambre, tout en haut. Il a horreur du petit jour, vous savez. Depuis trois cents ans, il fait tirer les grands rideaux bien avant l'aube… Je dis ça, je ne dis rien. »"
	else:
		super._mortimer_talk()
		return
	_ask(at, "Mortimer", "courtois", t, _mortimer_choices(), Callable(self, "_mortimer_answer"))


func _mortimer_choices() -> Array:
	var ch: Array = [{"id": "qui", "label": "Qui êtes-vous, au juste ?"}, {"id": "comte", "label": "Où est le comte ?"},
		{"id": "villageois", "label": "Et les gens de la ville ?"}]
	if not bool(state["comte"]):
		ch.append({"id": "vaincre", "label": "Comment vaincre le comte ?"})
	ch.append({"id": "fermer", "label": "Merci, Mortimer."})
	return ch


func _mortimer_answer(id: String) -> void:
	if _mortimer == null or not is_instance_valid(_mortimer):
		_close_dialog()
		return
	if int(state["poses"]) < 3 and not bool(state["comte"]) and id != "vaincre":
		super._mortimer_answer(id)
		return
	var t: String = {
		"qui": "« Un vampire, si le mot ne vous effraie pas. Un vieux. Je n'ai plus de dents pour mordre, voyez-vous : je sers le thé. Monsieur le Comte m'a gardé pour mes bonnes manières. »",
		"comte": "« Monsieur le Comte… n'est plus. Il ne reste de lui qu'un peu de poussière, là-haut, dans la lumière. Je balaierai. Plus tard. »" if bool(state["comte"]) else "« Tout en haut de la Tour, derrière la porte de fer. Il vous attend dans sa chambre. Il attend toujours. »",
		"villageois": ("« Ils sont libres, grâce à vous. Dehors, les autres, ceux qui marchaient… se sont endormis pour de bon. La ville va pouvoir respirer. »" if bool(state["libres"]) else "« Les prisonniers sont dans les souterrains, derrière la grille de la salle d'armes. La clé, c'est vous qui l'avez, maintenant. »") if bool(state["comte"]) else "« Ceux qui ont résisté sont enfermés sous le château, dans les vieux souterrains. Monsieur le Comte garde la clé sur lui, nuit et jour. Je les entends pleurer, la nuit. Je n'aime pas ça. »",
		"vaincre": "« Moi ? Je ne sais rien. » Il lisse sa veste. « Sinon que Monsieur le Comte n'a jamais supporté le petit jour. Et que les rideaux de sa chambre sont très, très lourds… mais pas cloués. »",
	}.get(id, "")
	if t == "":
		_close_dialog()
		return
	_ask(_mortimer.global_position + Vector3.UP * 1.7, "Mortimer", "courtois", t, _mortimer_choices(), Callable(self, "_mortimer_answer"))


# =================================================================== pour Sombreval

func trouvailles() -> Dictionary:
	var d: Dictionary = super.trouvailles()
	d.merge({"sv_chambre": 1 if bool(state["chambre"]) else 0, "sv_comte": 1 if bool(state["comte"]) else 0,
		"sv_grille": 1 if bool(state["grille"]) else 0, "sv_libres": 1 if bool(state["libres"]) else 0,
		"sv_place": 1 if sv != null and bool(sv.state.get("place", false)) else 0}, true)
	return d

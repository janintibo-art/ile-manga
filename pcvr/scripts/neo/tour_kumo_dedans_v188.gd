extends RefCounted
## V188 : l'intérieur de la Tour Kumo (Kumo Logistique). Avant : les étages de n'importe quelle tour (les mêmes
## bureaux, le même hangar), et des murs dont les fenêtres ne tombaient pas en face de celles du dehors.
##   - les murs de chaque étage reprennent la façade du dehors (quatre travées, trois vitres par travée) ; au
##     rez-de-chaussée, les portes du dépôt, le rideau baissé, la vitrine du boulevard, le guichet ; au 7e, les
##     loggias : on sort sur la terrasse, au-dessus du quai ;
##   - le rez-de-chaussée : le dépôt 01 (la baie des drones, le tapis roulant et sa trieuse, les rayonnages, le
##     quai de chargement, le guichet de Kumo Express) ;
##   - le 3e : la salle de pilotage (le mur d'écrans et la carte des vols, les pupitres des pilotes, l'hologramme
##     du briefing, les simulateurs) ;
##   - le 7e : le jardin d'hiver (les bambous, le bassin et son pont, le comptoir à thé, les loggias) ;
##   - le 12e : la présidence (l'antichambre et la maquette de la tour, le bureau de Madame Kumo, la galerie
##     des premiers colis).
## Les autres étages gardent pour l'instant leur contenu d'avant (dans les nouveaux murs).
## Repère d'un étage : lx vers l'est (le boulevard), lz vers le sud ; le quai est au nord (lz = 0).

const Kit = preload("res://scripts/neo_kit_v94.gd")
const Q = preload("res://scripts/tours_quartiers_v155.gd")
const Anime = preload("res://scripts/neo/anime_v188.gd")
const Flora = preload("res://scripts/flora_v25.gd")
const TEX := "res://assets/textures/neo187/"
const FAITS := {0: "depot", 1: "agence", 2: "cantine", 3: "pilotage", 4: "clinique", 5: "memoire", 6: "standard", 7: "jardin", 8: "nuage", 9: "etudes", 10: "trouves", 11: "meteo", 12: "presidence"}
## Les noms des étages (le panneau à côté de l'ascenseur, la liste de l'ascenseur).
const NOMS := {0: "le Dépôt 01", 1: "l'agence Kumo Express", 2: "la cantine « Au Bol volant »", 3: "le contrôle des vols", 4: "la clinique des drones",
	5: "la mémoire (les serveurs)", 6: "le standard", 7: "le jardin d'hiver", 8: "le Nuage (la salle de repos)",
	9: "le bureau d'études", 10: "les objets trouvés", 11: "la météo du ciel", 12: "la présidence"}
const L_ETUDES := ["Le K-Titan porte un piano. Il ne sait pas encore le poser.", "Portance égale vent fois audace. C'est écrit au tableau.", "Dans la soufflerie, on fabrique du vent de nord-ouest. Le vrai coûte trop cher.",
	"Le K-Mouche tient dans la main. On en a perdu onze dans ce bureau.", "J'imprime une hélice. Revenez dans quatre heures."]
const L_ROBOT_ETUDES := ["ASSISTANT D'ÉTUDES. JE TIENS LES PLANS. JE NE LES COMPRENDS PAS.", "CALCUL EN COURS. RÉSULTAT : ÇA VOLE. PROBABLEMENT."]
const L_TROUVES := ["Bureau des colis en promenade. Vous avez perdu quoi ? … Un piano ? Deuxième allée.", "Tout ce qui tombe d'un drone finit ici. Sauf les pigeons : ils repartent.",
	"Ce nain de jardin attend depuis trois ans. Je lui ai donné un nom.", "Signez le registre. Non, pas là : là, c'est la page des parapluies."]
const L_CHERCHEUR := ["Je cherche un parapluie noir. Il y en a quatre cents.", "Mon colis faisait « tic-tac ». C'était une horloge. J'espère."]
const L_METEO := ["Vent de nord-ouest, quatorze kilomètres-heure. Comme tous les jours. Comme toujours.", "Chaque île a son nuage. Celui de Néopolis, c'est nous.", "Le ballon-sonde monte à midi. À midi cinq, un pigeon se pose dessus.",
	"Demain : beau. Après-demain : beau, mais avec du vent. Compris, bien sûr.", "Je présente le bulletin devant un mur vert. Chez moi, on me croit en vacances."]
const L_MEMOIRE := ["Chut. Ils réfléchissent.", "Chaque voyant, c'est un colis qui sait où il va.", "Le Serveur n°1 tourne depuis 2087. On n'ose plus l'éteindre.", "Il fait frais, ici. Les drones adorent. Moi, j'ai un pull."]
const L_STANDARD := ["Kumo, bonjour ! Votre colis n'est pas perdu : il se promène.", "Oui madame. Non madame. Le drone ne peut pas « sonner plus doucement », madame.", "Trois appels en attente. Dont un pigeon, je crois.",
	"Il a commandé un piano. Il a reçu un piano. Il appelle pour dire merci. Ça arrive !", "Le client dit que le drone lui a souri. Je note."]
const L_CHEFFE_STANDARD := ["Ici, on décroche avant la deuxième sonnerie. La première, c'est pour le suspense.", "Regardez le mur des mercis. Les jours de pluie, je le relis."]
const L_NUAGE := ["Vingt minutes de sieste : c'est dans le contrat.", "Au baby-foot, les rouges, c'est le service des vols. Ils trichent.", "Je lis toujours le même livre. Je m'endors à la page douze.",
	"Le nuage, au plafond ? Il pleut de la lumière. C'est Madame Kumo qui a voulu.", "Un jus de mangue ? La machine a un caractère, parlez-lui gentiment."]
const L_AGENCE := ["Kumo Express, bonjour ! Un colis à envoyer, ou un colis à retrouver ?", "Guichet 2. Non, l'autre 2.", "Votre colis est parti il y a quatre minutes. Il vous attend déjà chez vous.",
	"Fragile ? Tout est fragile, monsieur. Même les drones ont leurs jours."]
const L_CLIENT := ["J'ai le numéro 42. Ils appellent le 17.", "J'envoie des nouilles à ma sœur, à Port-Azur. Elles arriveront chaudes.", "Mon casier, c'est le 208. Ou le 802. Enfin, il y a un 8.",
	"Je viens tous les jours. Je n'envoie rien. J'aime regarder les drones tourner."]
const L_EMBALLAGE := ["Du papier, du ruban, et un peu d'amour : voilà un colis.", "On pèse, on timbre, et hop : par la fenêtre. Enfin, par le toit."]
const L_CHEF_BOL := ["Un bol du premier jour ? C'est la recette de Madame Kumo. Elle ne la reconnaît plus.", "Asseyez-vous, ça arrive. Ici aussi, on livre en vingt minutes.", "Le bouillon mijote depuis ce matin. Hier matin."]
const L_CUISTOT := ["UNITÉ DE CUISSON 2. CUISSON : PARFAITE. COMME TOUJOURS.", "JE NE GOÛTE PAS. JE SAIS.", "ERREUR 404 : PIMENT INTROUVABLE. NON. LE VOICI."]
const L_CANTINE := ["Les nouilles sautées « vent de nord-ouest » : ça décoiffe.", "Je pilote douze drones le matin. Le midi, je pilote des baguettes.", "On mange face à la mer. Ça vaut toutes les primes.",
	"Le bol qui passe sur le rail ? Non, celui-là est à moi.", "Tu as vu ? Le drone apporte le thé. Il ne renverse jamais. Presque."]
const L_CLINIQUE := ["La clinique des drones. Ici, on répare tout. Même l'orgueil.", "K-0733 a rencontré un pigeon. Le pigeon va bien.", "Une hélice, deux vis, un peu de repos : il revolera demain.",
	"Ne dites pas « cassé » devant eux. On dit « fatigué »."]
const L_MECANO := ["Passe-moi la clé de huit. Non, l'autre huit.", "Celui-là a livré un piano. Seul. On ne lui avait rien demandé.", "Je soude, je visse, je souffle dessus : c'est de la mécanique de précision.",
	"Dans la cage, on leur réapprend à voler. Certains boudent."]

const L_DEPOT := ["Dépôt 01 : trois mille drones, et c'est moi qui range.", "Ne restez pas sous les socles, ça décolle sans prévenir.", "Un colis pour les Ruelles ? Vingt minutes, vent compris.",
	"Le tapis ne s'arrête jamais. Moi non plus, d'ailleurs.", "On a retrouvé un colis de 2091 derrière la trieuse. Il était encore tiède.", "Le K-0412 boude depuis ce matin. Problème d'hélice, ou de cœur."]
const L_GUICHET := ["Kumo Express, bonjour ! Votre numéro de casier ?", "Un colis égaré ? Chez Kumo, on dit « en promenade ».", "Signez ici. Et ici. Et là, mais avec le sourire."]
const L_PILOTE := ["Secteur 4, un pigeon. Encore lui.", "Je pilote douze drones à la fois. Ma mère dit que je joue.", "Vent de nord-ouest : on passe par les Hauts.", "K-0733, rentre à la maison, ta batterie pleure.",
	"Chut. Livraison délicate : un gâteau d'anniversaire.", "Le record ? Quarante et un mille colis en un jour. On était fatigués, les drones non."]
const L_CHEF := ["Bienvenue au contrôle des vols. Ne touchez à aucun bouton. Surtout le rouge.", "Deux mille huit cents drones en l'air, zéro au tapis. Bonne journée.", "Un visiteur ? Regardez la carte : chaque point est un cadeau qui arrive."]
const L_JARDIN := ["Ici, on n'entend plus les hélices. Presque.", "Le bambou a pris dix centimètres depuis lundi. Mon salaire, non.", "Un thé au jasmin ? C'est la maison qui offre.", "Je viens voir la mer entre deux livraisons.",
	"Les carpes ont des noms de drones. Celle-là, c'est K-0001."]
const L_PRESIDENTE := ["Madame Kumo. Asseyez-vous : chez nous, même les visiteurs arrivent à l'heure.", "J'ai livré mon premier colis à vélo. Il pleuvait. C'était des nouilles.", "Le nuage, sur le toit ? C'est moi qui l'ai dessiné, sur une serviette en papier.",
	"Un jour, mes drones livreront jusqu'aux autres îles. Dites-le à vos amis."]
const L_ACCUEIL := ["Vous avez rendez-vous ? … Non. Madame vous recevra quand même, elle aime les surprises.", "Regardez la maquette, mais ne soufflez pas dessus : les drones tiennent avec de la colle.", "Le douzième étage : la plus belle vue du quai."]

var T: Node
var b: Kit.Batch
var X0: float
var Z0: float
var W: float
var D: float
var y: float
var hc: float
var rng: RandomNumberGenerator
var anime: Node3D


static func fait(k: int) -> bool:
	return FAITS.has(k)


static func nom(k: int) -> String:
	return str(NOMS.get(k, ""))


func _debut(tours: Node, lot: Kit.Batch, r: RandomNumberGenerator, t: Dictionary) -> void:
	T = tours
	b = lot
	rng = r
	var rect: Rect2 = T.info["rect"]
	X0 = rect.position.x
	Z0 = rect.position.y
	W = rect.size.x
	D = rect.size.y
	y = T.info["y"]
	hc = float(t["e"]) - 0.35


func _p(lx: float, h: float, lz: float) -> Vector3:
	return Vector3(X0 + lx, y + h, Z0 + lz)


## Une boîte : de lx0 à lx1, de h0 à h1 (au-dessus du sol), de lz0 à lz1 ; col : on s'y cogne.
func _bx(key: String, lx0: float, lx1: float, h0: float, h1: float, lz0: float, lz1: float, col: bool = false) -> void:
	T._boite(b, key, _p((lx0 + lx1) * 0.5, (h0 + h1) * 0.5, (lz0 + lz1) * 0.5), Vector3(absf(lx1 - lx0), absf(h1 - h0), absf(lz1 - lz0)), col)


func _anime() -> Node3D:
	if anime == null or not is_instance_valid(anime):
		anime = Anime.new()
		anime.name = "Anime_v188"
		(T.get("_node") as Node3D).add_child(anime)
	return anime


func _image(nom: String, at: Vector3, face: Vector3, size: Vector2, force: float = 2.0) -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ecran_v94.gdshader")
	if ResourceLoader.exists(TEX + nom):
		m.set_shader_parameter("image", load(TEX + nom))
	m.set_shader_parameter("ecran", false)
	m.set_shader_parameter("force", force)
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	(T.get("_node") as Node3D).add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)


func _colis(lx: float, h: float, lz: float, s: float = 0.4) -> void:
	var hh: float = s * rng.randf_range(0.6, 1.0)
	_carton(b, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)), _p(lx, h + hh * 0.5, lz)), Vector3(s, hh, s * 0.9))


## Un carton de Kumo : chaque côté montre l'image entière, à l'endroit (l'étiquette se lit, la flèche monte) ;
## le dessus et le dessous ne montrent que la bande de ruban.
func _carton(lot: Kit.Batch, xf: Transform3D, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var k: float = 1.0 / 1.6                      # (la matière répète l'image 1,6 fois par unité)
	for n in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var dr: Vector3 = Vector3.UP.cross(n)
		var hw: float = absf(h.dot(dr))
		var c: Vector3 = n * absf(h.dot(n))
		lot.quad("k187_carton", [xf * (c - dr * hw + Vector3.UP * h.y), xf * (c + dr * hw + Vector3.UP * h.y), xf * (c + dr * hw - Vector3.UP * h.y), xf * (c - dr * hw - Vector3.UP * h.y)],
			(xf.basis * n).normalized(), [Vector2(0, 0), Vector2(k, 0), Vector2(k, k), Vector2(0, k)])
	for sg in [1.0, -1.0]:
		var c2 := Vector3(0, sg * h.y, 0)
		lot.quad("k187_carton", [xf * (c2 + Vector3(-h.x, 0, -h.z)), xf * (c2 + Vector3(h.x, 0, -h.z)), xf * (c2 + Vector3(h.x, 0, h.z)), xf * (c2 + Vector3(-h.x, 0, h.z))],
			(xf.basis * Vector3(0, sg, 0)).normalized(), [Vector2(0, 0.38 * k), Vector2(k, 0.38 * k), Vector2(k, 0.62 * k), Vector2(0, 0.62 * k)])


## Une pièce d'un meuble : « bs » l'oriente (son +z : là où il regarde), « off » la place, « incl » la penche.
func _pc(key: String, o: Vector3, bs: Basis, off: Vector3, size: Vector3, incl: Basis = Basis()) -> void:
	b.box(key, Transform3D(bs * incl, o + bs * off), size)


## Une plante vraie (les feuillages du reste du jeu : des feuilles, pas des boules), posée dans l'étage.
func _vegetal(mesh: Mesh, at: Vector3, sc: Vector3, yaw: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	_anime().add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, yaw).scaled(sc), at)
	return mi


func _fleurs(at: Vector3, couleur: Color, s: float) -> void:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	m.surface_set_material(0, Flora.flower_material(couleur))
	_vegetal(m, at, Vector3(s, s, s), rng.randf() * TAU)


## Une plante en pot : le pot de grès, la terre, un buisson ou une fougère.
func _plante_pot(lx: float, lz: float, s: float = 1.0, fougere: bool = false) -> void:
	b.cyl_at("in_pot", _p(lx, 0.0, lz), 0.2 * s, 0.26 * s, 0.48 * s, 14)
	b.cyl_at("in_noir", _p(lx, 0.48 * s, lz), 0.27 * s, 0.27 * s, 0.03, 14)
	b.cyl_at("terre_bac", _p(lx, 0.49 * s, lz), 0.23 * s, 0.23 * s, 0.03, 12)
	if fougere:
		_vegetal(Flora.fern_clump(), _p(lx, 0.5 * s, lz), Vector3(1.1, 1.2, 1.1) * s, rng.randf() * TAU)
	else:
		_vegetal(Flora.bush(1881 + int(lx * 7.0) % 5), _p(lx, 0.46 * s, lz), Vector3(0.62, 0.95, 0.62) * s, rng.randf() * TAU)
	T._col(_p(lx, 0.5 * s, lz), Vector3(0.5, 1.0, 0.5) * s)


## Un canapé (ou un fauteuil, s'il est étroit) : les pieds, le socle, les coussins, le dossier penché, les accoudoirs.
func _canape(lx: float, lz: float, face: Vector3, larg: float, key: String = "in_cuir") -> void:
	var o: Vector3 = _p(lx, 0.0, lz)
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.cyl_at("in_inox", o + bs * Vector3(sx * (larg * 0.5 - 0.08), 0.0, sz * 0.34), 0.02, 0.025, 0.1, 6)
	_pc(key, o, bs, Vector3(0, 0.2, 0), Vector3(larg, 0.2, 0.86))
	var n: int = maxi(1, int(round((larg - 0.36) / 0.75)))
	var w: float = (larg - 0.36) / n
	var dos := Basis(Vector3(1, 0, 0), -0.2)
	_pc(key, o, bs, Vector3(0, 0.6, -0.37), Vector3(larg - 0.36, 0.56, 0.14), dos)
	for i in range(n):
		var x: float = (i - (n - 1) * 0.5) * w
		_pc(key, o, bs, Vector3(x, 0.37, 0.07), Vector3(w - 0.03, 0.14, 0.68))
		_pc(key, o, bs, Vector3(x, 0.66, -0.24), Vector3(w - 0.06, 0.4, 0.13), dos)
	for sx2 in [-1.0, 1.0]:
		_pc(key, o, bs, Vector3(sx2 * (larg * 0.5 - 0.09), 0.42, 0.0), Vector3(0.18, 0.46, 0.86))
	T._col(o + Vector3.UP * 0.45, Vector3(larg, 0.9, 0.9), atan2(face.x, face.z))


## Une lanterne de jardin : le pied, la lampe de papier entre ses deux coiffes noires.
func _lanterne(lx: float, lz: float, ht: float = 0.9) -> void:
	b.cyl_at("in_noir", _p(lx, 0.0, lz), 0.06, 0.03, 0.04, 8)
	b.cyl_at("in_noir", _p(lx, 0.0, lz), 0.018, 0.018, ht, 6)
	b.cyl_at("in_noir", _p(lx, ht, lz), 0.11, 0.11, 0.02, 10)
	b.cyl_at("lampe_chaude", _p(lx, ht + 0.02, lz), 0.085, 0.1, 0.24, 10)
	b.cyl_at("in_noir", _p(lx, ht + 0.26, lz), 0.13, 0.05, 0.05, 10)


## Un tableau accroché (une image éclairée par la pièce, dans son cadre).
func _tableau(nom: String, at: Vector3, face: Vector3, size: Vector2) -> void:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(TEX + nom):
		m.albedo_texture = load(TEX + nom)
	m.roughness = 0.9
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	(T.get("_node") as Node3D).add_child(mi)
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	mi.global_transform = Transform3D(bs, at + face * 0.03)
	for e in [[0.0, size.y * 0.5 + 0.03, size.x + 0.12, 0.06], [0.0, -size.y * 0.5 - 0.03, size.x + 0.12, 0.06], [size.x * 0.5 + 0.03, 0.0, 0.06, size.y], [-size.x * 0.5 - 0.03, 0.0, 0.06, size.y]]:
		b.box("in_bois", Transform3D(bs, at + bs * Vector3(e[0], e[1], 0.02)), Vector3(e[2], e[3], 0.05))


## Le chariot élévateur du dépôt : le châssis, le contrepoids, le siège, le toit de protection, le mât, la
## fourche levée et sa palette de colis.
func _elevateur(lx: float, lz: float, yaw: float) -> void:
	var o: Vector3 = _p(lx, 0.0, lz)
	var bs := Basis(Vector3.UP, yaw)
	_pc("peinture_jaune", o, bs, Vector3(0, 0.5, -0.35), Vector3(1.0, 0.5, 1.5))
	_pc("metal_noir", o, bs, Vector3(0, 0.55, -1.16), Vector3(0.96, 0.62, 0.22))
	_pc("peinture_jaune", o, bs, Vector3(0, 0.84, -0.72), Vector3(0.9, 0.2, 0.72))
	_pc("k187_danger", o, bs, Vector3(0, 0.3, -1.275), Vector3(0.96, 0.12, 0.012))
	_pc("plastique_noir", o, bs, Vector3(0, 0.99, -0.62), Vector3(0.46, 0.1, 0.46))
	_pc("plastique_noir", o, bs, Vector3(0, 1.27, -0.85), Vector3(0.46, 0.5, 0.08), Basis(Vector3(1, 0, 0), -0.12))
	b.tube("metal_noir", o + bs * Vector3(0, 0.75, 0.0), o + bs * Vector3(0, 1.17, -0.2), 0.025, 6)
	b.cyl("plastique_noir", Transform3D(bs * Basis(Vector3(1, 0, 0), 0.9), o + bs * Vector3(0, 1.18, -0.21)), 0.17, 0.17, 0.03, 14)
	for sx in [-1.0, 1.0]:
		for q in [[0.3, 0.3], [-0.9, 0.24]]:
			var couche := bs * Basis(Vector3(0, 0, 1), PI * 0.5)
			b.cyl("plastique_noir", Transform3D(couche, o + bs * Vector3(sx * 0.52, q[1], q[0])), q[1], q[1], 0.2, 16)
			b.cyl("peinture_jaune", Transform3D(couche, o + bs * Vector3(sx * 0.53, q[1], q[0])), q[1] * 0.45, q[1] * 0.45, 0.21, 10)
		# le toit de protection : deux montants de chaque côté, un longeron
		b.tube("metal_noir", o + bs * Vector3(sx * 0.44, 0.75, 0.32), o + bs * Vector3(sx * 0.44, 2.05, 0.1), 0.03, 6)
		b.tube("metal_noir", o + bs * Vector3(sx * 0.44, 0.94, -1.02), o + bs * Vector3(sx * 0.44, 2.05, -0.9), 0.03, 6)
		b.tube("metal_noir", o + bs * Vector3(sx * 0.44, 2.05, 0.1), o + bs * Vector3(sx * 0.44, 2.05, -0.9), 0.03, 6)
		# le mât, la fourche
		_pc("metal_noir", o, bs, Vector3(sx * 0.3, 1.3, 0.5), Vector3(0.08, 2.3, 0.1))
		_pc("in_inox", o, bs, Vector3(sx * 0.25, 0.62, 1.12), Vector3(0.1, 0.04, 1.05))
		_pc("in_inox", o, bs, Vector3(sx * 0.25, 0.85, 0.6), Vector3(0.1, 0.5, 0.04))
		_pc("lampe_blanche", o, bs, Vector3(sx * 0.36, 0.62, 0.405), Vector3(0.14, 0.08, 0.01))
	for i in range(5):
		_pc("metal_noir", o, bs, Vector3(0, 2.05, 0.05 - i * 0.235), Vector3(0.88, 0.035, 0.04))
	for hh in [0.35, 1.3, 2.4]:
		_pc("metal_noir", o, bs, Vector3(0, hh, 0.5), Vector3(0.68, 0.08, 0.06))
	b.cyl_at("chrome", o + bs * Vector3(0, 0.3, 0.5), 0.035, 0.035, 1.5, 8)
	_pc("metal_noir", o, bs, Vector3(0, 0.85, 0.58), Vector3(0.8, 0.5, 0.03))
	b.cyl_at("in_led_ambre", o + bs * Vector3(0, 2.07, -0.4), 0.05, 0.04, 0.09, 8)
	# la palette levée, ses colis
	_pc("bois_clair", o, bs, Vector3(0, 0.71, 1.15), Vector3(1.0, 0.12, 0.9))
	for q2 in [[-0.25, -0.2, 0.42], [0.25, -0.2, 0.36], [-0.22, 0.22, 0.3], [0.24, 0.24, 0.4]]:
		_carton(b, Transform3D(bs, o + bs * Vector3(q2[0], 0.77 + q2[2] * 0.5, 1.15 + q2[1])), Vector3(0.44, q2[2], 0.4))
	_carton(b, Transform3D(bs.rotated(Vector3.UP, 0.3), o + bs * Vector3(0.0, 1.32, 1.1)), Vector3(0.4, 0.26, 0.36))
	T._col(o + bs * Vector3(0, 1.05, 0.1) , Vector3(1.2, 2.1, 2.9), yaw)


# =================================================================== les murs (ils reprennent la façade du dehors)

## Un mur de façade, de a à c (au sol), qui regarde « dedans ». Renvoie vrai : c'est fait.
func facade(tours: Node, lot: Kit.Batch, a: Vector3, c: Vector3, dedans: Vector3, h: float, k: int, sorte: String) -> void:
	T = tours
	b = lot
	var L: float = a.distance_to(c)
	var u: Vector3 = (c - a).normalized()
	var long_x: bool = absf(u.x) > 0.5
	var nord: bool = dedans.z > 0.5
	var est: bool = dedans.x < -0.5
	var mb := func(key: String, s0: float, s1: float, h0: float, h1: float, t0: float, t1: float, col: bool) -> void:
		var at: Vector3 = a + u * ((s0 + s1) * 0.5) + dedans * ((t0 + t1) * 0.5) + Vector3.UP * ((h0 + h1) * 0.5)
		var sz := Vector3(absf(s1 - s0), absf(h1 - h0), absf(t1 - t0)) if long_x else Vector3(absf(t1 - t0), absf(h1 - h0), absf(s1 - s0))
		T._boite(b, key, at, sz, col)
	# ---- le jardin du 7e, côté quai et côté boulevard : la loggia (on sort sur la terrasse)
	if sorte == "jardin" and k == 7 and (nord or est):
		mb.call("in_noir", 0.0, L, 0.0, 1.15, -0.1, 0.0, true)                 # (le garde-corps est dehors : ici, ce qui retient)
		mb.call("bois", 0.0, L, -0.02, 0.012, 0.0, 2.6, false)
		for i in range(4):
			var s0: float = L * i / 4.0
			var s1: float = L * (i + 1) / 4.0
			mb.call("in_menuiserie", s0 - 0.06, s0 + 0.06, 0.0, h, 2.56, 2.68, true)
			if i == 1 or i == 2:
				continue                      # les deux travées du milieu : ouvertes
			mb.call("in_vitre", s0 + 0.06, s1 - 0.06, 0.0, h, 2.6, 2.64, true)
		mb.call("in_menuiserie", L - 0.06, L + 0.06, 0.0, h, 2.56, 2.68, true)
		mb.call("in_menuiserie", 0.0, L, h - 0.12, h, 2.56, 2.68, false)
		return
	# ---- le rez-de-chaussée
	if k == 0:
		_facade_rdc(mb, L, h, dedans, a, u)
		return
	# ---- l'étage des serveurs : un mur plein, des chemins de câbles
	if sorte == "serveurs":
		mb.call("in_mur_gris", 0.0, L, 0.0, h, 0.0, 0.2, true)
		for hh in [0.5, 2.6]:
			mb.call("in_inox", 0.3, L - 0.3, hh, hh + 0.08, 0.2, 0.34, false)
		return
	# ---- un étage courant : les poteaux, l'allège, trois vitres par travée
	var Lo: float = L + 0.6
	mb.call("in_mur", 0.0, L, 0.0, 0.95, 0.0, 0.2, false)
	mb.call("in_menuiserie", 0.0, L, 0.95, 1.0, 0.0, 0.26, false)
	for i2 in range(5):
		var sc: float = Lo * i2 / 4.0 - 0.3
		mb.call("in_mur_gris", clampf(sc - 0.26, 0.0, L), clampf(sc + 0.26, 0.0, L), 0.0, h, 0.0, 0.3, false)
	for i3 in range(4):
		var s2: float = Lo * i3 / 4.0 - 0.3 + 0.26
		var s3: float = Lo * (i3 + 1) / 4.0 - 0.3 - 0.26
		var w: float = (s3 - s2) / 3.0
		mb.call("in_vitre", s2, s3, 1.0, h, 0.08, 0.11, false)
		for j in [1, 2]:
			mb.call("in_menuiserie", s2 + w * j - 0.035, s2 + w * j + 0.035, 1.0, h, 0.04, 0.16, false)
	T._col(a + u * (L * 0.5) + dedans * 0.1 + Vector3.UP * (h * 0.5), Vector3(L, h, 0.3) if long_x else Vector3(0.3, h, L))


func _facade_rdc(mb: Callable, L: float, h: float, dedans: Vector3, a: Vector3, u: Vector3) -> void:
	var long_x: bool = absf(u.x) > 0.5
	var mur: String = "in_mur_gris"
	if dedans.z > 0.5:
		# le quai (de l'ouest vers l'est) : le rideau baissé, l'entrée, la grande porte du dépôt
		mb.call(mur, 0.0, L, 2.75, h, 0.0, 0.2, false)
		for pr in [[0.0, 0.3], [6.7, L * 0.5 - 1.35], [L * 0.5 + 1.35, 12.7], [19.1, L]]:
			mb.call(mur, pr[0], pr[1], 0.0, 2.75, 0.0, 0.2, false)
		mb.call("metal", 0.3, 6.7, 0.75, 2.75, 0.02, 0.08, false)
		mb.call("metal_noir", 0.3, 6.7, 0.7, 0.78, 0.0, 0.12, false)
		for g in [0.3, 6.7, 12.7, 19.1]:
			mb.call("peinture_jaune", g - 0.06, g + 0.06, 0.0, 2.75, 0.2, 0.26, false)
		mb.call("k187_danger", 12.7, 19.1, 0.004, 0.012, 0.0, 0.7, false)
		mb.call("k187_danger", 0.3, 6.7, 0.004, 0.012, 0.0, 0.5, false)
		# la barrière de la grande porte (ouverte sur le quai)
		for sp in [12.9, 18.9]:
			mb.call("peinture_jaune", sp - 0.06, sp + 0.06, 0.0, 1.05, 0.34, 0.46, false)
		mb.call("k187_danger", 12.9, 18.9, 0.92, 1.02, 0.37, 0.43, false)
		# l'entrée : les portes de verre, et la sortie
		var mil: Vector3 = a + u * (L * 0.5)
		for sj in [-0.66, 0.66]:
			mb.call("in_vitre", L * 0.5 + sj - 0.63, L * 0.5 + sj + 0.63, 0.0, 2.7, 0.08, 0.12, false)
		for sj2 in [-1.32, 0.0, 1.32]:
			mb.call("in_menuiserie", L * 0.5 + sj2 - 0.03, L * 0.5 + sj2 + 0.03, 0.0, 2.7, 0.06, 0.14, false)
		mb.call("in_menuiserie", L * 0.5 - 1.35, L * 0.5 + 1.35, 2.68, 2.76, 0.06, 0.14, false)
		T._its_add({"id": "sortie153", "pos": mil + dedans * 1.2, "radius": 1.6, "text": "E : sortir sur le quai", "vr": "Gâchette : sortir", "call": T.leave})
	elif dedans.x < -0.5:
		# le boulevard (du nord vers le sud) : le dos des casiers, la vitrine, le guichet
		mb.call(mur, 0.0, L, 2.75, h, 0.0, 0.2, false)
		mb.call(mur, 0.0, 8.5, 0.0, 2.75, 0.0, 0.2, false)
		for s in range(8):
			for hh in range(4):
				mb.call("in_inox", 0.45 + s * 1.0, 1.35 + s * 1.0, 0.3 + hh * 0.6, 0.84 + hh * 0.6, 0.2, 0.23, false)
		mb.call(mur, 8.5, 8.96, 0.0, 2.75, 0.0, 0.2, false)
		mb.call(mur, 8.96, 14.96, 0.0, 0.5, 0.0, 0.2, false)
		mb.call("in_vitre", 8.96, 14.96, 0.5, 2.75, 0.08, 0.11, false)
		for sm in [10.96, 12.96]:
			mb.call("in_menuiserie", sm - 0.03, sm + 0.03, 0.5, 2.75, 0.04, 0.16, false)
		mb.call(mur, 14.96, 16.2, 0.0, 2.75, 0.0, 0.2, false)
		mb.call(mur, 16.2, 19.0, 0.0, 1.0, 0.0, 0.2, false)
		mb.call(mur, 16.2, 19.0, 2.2, 2.75, 0.0, 0.2, false)
		mb.call(mur, 19.0, L, 0.0, 2.75, 0.0, 0.2, false)
		mb.call("bois", 16.1, 19.1, 0.96, 1.02, -0.1, 0.55, false)
	elif dedans.x > 0.5:
		# le service (du nord vers le sud) : les deux portes du quai de chargement
		mb.call(mur, 0.0, L, 0.0, h, 0.0, 0.2, false)
		for d0 in [4.3, 11.9]:
			mb.call("metal", d0, d0 + 3.2, 0.0, 3.0, 0.2, 0.26, false)
			mb.call("peinture_jaune", d0 - 0.1, d0, 0.0, 3.05, 0.2, 0.3, false)
			mb.call("peinture_jaune", d0 + 3.2, d0 + 3.3, 0.0, 3.05, 0.2, 0.3, false)
			mb.call("in_led_verte" if d0 < 5.0 else "in_led_ambre", d0 + 1.4, d0 + 1.8, 3.02, 3.1, 0.2, 0.24, false)
	else:
		# la ruelle : un mur plein, la porte de service
		mb.call(mur, 0.0, L, 0.0, h, 0.0, 0.2, false)
		mb.call("in_porte", 14.6, 15.6, 0.0, 2.1, 0.2, 0.25, false)
		mb.call("in_led_verte", 14.85, 15.35, 2.2, 2.36, 0.2, 0.23, false)
	T._col(a + u * (L * 0.5) + dedans * 0.1 + Vector3.UP * (h * 0.5), Vector3(L, h, 0.3) if long_x else Vector3(0.3, h, L))


# =================================================================== les étages

func etage(tours: Node, lot: Kit.Batch, r: RandomNumberGenerator, t: Dictionary, k: int) -> String:
	_debut(tours, lot, r, t)
	match str(FAITS.get(k, "")):
		"depot":
			return _depot()
		"pilotage":
			return _pilotage()
		"jardin":
			return _jardin()
		"presidence":
			return _presidence()
		"agence":
			return _agence()
		"cantine":
			return _cantine()
		"clinique":
			return _clinique()
		"memoire":
			return _memoire()
		"standard":
			return _standard()
		"nuage":
			return _nuage()
		"etudes":
			return _etudes()
		"trouves":
			return _trouves()
		"meteo":
			return _meteo()
	return ""


func _gens(role: String, lx: float, lz: float, face: Vector3, pose: String, lignes: Array, android: bool = false, force: bool = false) -> void:
	T._gens_ajoute(role, _p(lx, 0.0, lz), face, pose, rng, lignes, android, force)


# ------------------------------------------------------------------ le rez-de-chaussée : le dépôt 01
func _depot() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	# les lignes jaunes autour du cœur, l'allée de l'entrée
	for e in [[cx0 - 1.6, cx1 + 1.6, cz0 - 1.6, cz0 - 1.5], [cx0 - 1.6, cx1 + 1.6, cz1 + 1.5, cz1 + 1.6], [cx0 - 1.6, cx0 - 1.5, cz0 - 1.6, cz1 + 1.6], [cx1 + 1.5, cx1 + 1.6, cz0 - 1.6, cz1 + 1.6]]:
		_bx("peinture_jaune", e[0], e[1], 0.004, 0.01, e[2], e[3])
	for sx in [W * 0.5 - 1.7, W * 0.5 + 1.7]:
		_bx("peinture_jaune", sx - 0.05, sx + 0.05, 0.004, 0.01, 0.3, cz0 - 1.6)
	# le tableau des tournées (sur le cœur, côté ouest), le nuage de Kumo (côté est)
	_bx("in_noir", cx0 - 0.08, cx0, 0.9, 2.5, cz0 + 0.5, cz1 - 0.5)
	_bx("in_ecran_ui_graphes", cx0 - 0.1, cx0 - 0.08, 1.0, 2.4, cz0 + 0.6, cz1 - 0.6)
	_image("kumo_enseigne.png", _p(cx1 + 0.06, 1.9, (cz0 + cz1) * 0.5), Vector3(1, 0, 0), Vector2(4.0, 1.0), 1.8)
	# ---- la baie des drones (au nord-est, derrière la grande porte) : trois socles, l'établi, les chargeurs
	for i in range(3):
		var px: float = 14.0 + i * 2.0
		b.cyl_at("metal_noir", _p(px, 0.0, 2.3), 0.8, 0.8, 0.1, 20)
		b.cyl_at("neon_cyan", _p(px, 0.1, 2.3), 0.72, 0.72, 0.015, 20)
		b.tube("plastique_noir", _p(px, 0.05, 2.9), _p(px, 0.05, 5.2), 0.03, 5)
		_bx("in_inox", px - 0.2, px + 0.2, 0.0, 1.1, 5.2, 5.5, true)
		_bx("in_led_verte" if i != 1 else "in_led_ambre", px - 0.1, px + 0.1, 0.8, 0.95, 5.18, 5.2)
		if i != 1:
			_drone(b, _p(px, 0.34, 2.3), rng.randf() * TAU, false, 1.5)
	# le drone qui s'essaie au vol, au-dessus du socle du milieu
	var lotd := Kit.Batch.new()
	_drone(lotd, Vector3.ZERO, 0.4, true, 1.5)
	var vol := MeshInstance3D.new()
	vol.mesh = _maillage(lotd)
	_anime().add_child(vol)
	vol.global_position = _p(16.0, 1.5, 2.3)
	_anime().flotte.append([vol, _p(16.0, 1.5, 2.3), 0.18, 1.7, 0.0])
	_anime().tourne.append([vol, 0.5])
	# l'établi, la servante à outils, un drone ouvert
	_bx("in_inox", 12.9, 13.0, 0.0, 0.88, 0.9, 1.7)
	_bx("in_inox", 15.0, 15.1, 0.0, 0.88, 0.9, 1.7)
	_bx("in_bois", 12.8, 15.2, 0.88, 0.94, 0.8, 1.8, true)
	_drone(b, _p(14.0, 1.06, 1.3), 1.9, false, 1.2)
	_bx("plastique_rouge", 17.4, 18.2, 0.0, 1.0, 0.8, 1.35, true)
	for hh in [0.3, 0.55, 0.8]:
		_bx("in_inox", 17.45, 18.15, hh, hh + 0.02, 1.35, 1.37)
	# ---- le tri (au nord-ouest, derrière le rideau) : les palettes, les piles, le chariot-robot
	for q in [[1.4, 1.6], [3.4, 1.4], [5.4, 1.7], [1.5, 4.4]]:
		Q._pile(T, b, _p(q[0], 0.0, q[1]), rng, 2.4)
	_elevateur(6.0, 5.0, PI * 0.5 + 0.25)
	# ---- le long du mur du service : les rayonnages, entre les deux portes du quai
	for lz in [1.6, 8.6, 9.9, 16.4, 18.0]:
		Q._rayonnage(T, b, _p(0.75, 0.0, lz), Vector3(1, 0, 0), 2.7, rng)
	for q2 in [[2.6, 6.0], [2.8, 13.6], [4.6, 13.2]]:
		_bx("bois", q2[0] - 0.55, q2[0] + 0.55, 0.0, 0.12, q2[1] - 0.45, q2[1] + 0.45, true)
		for i2 in range(2):
			for j2 in range(2):
				_colis(q2[0] - 0.27 + i2 * 0.54, 0.12, q2[1] - 0.22 + j2 * 0.44, 0.5)
		_colis(q2[0], 0.55, q2[1], 0.55)
	# ---- le tapis roulant : il longe la vitrine du boulevard, tourne, et entre dans la trieuse
	var tx: float = W - 1.25                      # (derrière la vitrine : on voit les colis passer de la rue)
	_bx("metal", tx - 0.35, tx + 0.35, 0.0, 1.0, 8.9, 15.2, true)
	_bx("plastique_noir", tx - 0.38, tx + 0.38, 1.0, 1.08, 8.9, 15.2)
	for sg in [-0.42, 0.42]:
		_bx("k187_orange", tx + sg - 0.03, tx + sg + 0.03, 1.0, 1.14, 8.9, 15.2)
	_bx("metal", 13.9, tx + 0.35, 0.0, 1.0, 14.5, 15.2, true)
	_bx("plastique_noir", 13.9, tx + 0.38, 1.0, 1.08, 14.47, 15.23)
	# la trieuse : un portique, ses lumières, quatre goulottes et leurs bacs de couleur
	_bx("k187_allege", 13.9, 15.5, 0.0, 2.3, 13.6, 16.1, true)
	_bx("k187_orange", 13.88, 15.52, 2.3, 2.36, 13.58, 16.12)
	_bx("k187_danger", 13.88, 15.52, 0.0, 0.12, 13.585, 13.6)
	_bx("in_noir", 14.0, 15.4, 1.05, 1.75, 13.58, 13.6)
	_bx("in_ecran_ui_code", 14.2, 15.2, 1.85, 2.2, 13.57, 13.6)
	_bx("neon_rouge", 15.5, 15.53, 1.2, 1.6, 14.6, 15.1)
	var bacs: Array = ["plastique_bleu", "plastique_rouge", "tissu_vert", "tissu_jaune"]
	for i3 in range(4):
		var bz: float = 13.9 + i3 * 0.6
		b.box("in_inox", Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(28.0)), _p(13.5, 0.95, bz)), Vector3(0.9, 0.04, 0.5))
		_bx(bacs[i3], 12.7, 13.3, 0.0, 0.6, bz - 0.27, bz + 0.27, true)
		_colis(13.0, 0.45, bz, 0.34)
	# les colis du tapis (ils avancent : de la vitrine vers la trieuse)
	var boite := Kit.Batch.new()
	_carton(boite, Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3.ONE)
	var mesh: ArrayMesh = _maillage(boite)
	for i4 in range(8):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.scale = Vector3(rng.randf_range(0.28, 0.5), rng.randf_range(0.18, 0.4), rng.randf_range(0.28, 0.45))
		_anime().add_child(mi)
		_anime().tapis.append([mi, _p(tx, 1.08, 9.0), Vector3(0, 0, 1), 5.6, float(i4) / 8.0, 0.32])
	# ---- le guichet de Kumo Express (au sud-est) : le comptoir, les étagères de colis à remettre
	_bx("bois_clair", W - 2.6, W - 0.9, 0.0, 1.0, 16.0, 16.12, true)
	for niv in range(4):
		_bx("in_inox", W - 4.62 + niv * 0.47, W - 4.58 + niv * 0.47, 0.0, 2.2, 17.06, 17.1)
		_bx("in_bois_clair", W - 4.6, W - 3.2, 0.35 + niv * 0.5, 0.38 + niv * 0.5, 16.6, 17.1)
		for q3 in range(3):
			if rng.randf() < 0.8:
				_colis(W - 4.4 + q3 * 0.45, 0.38 + niv * 0.5, 16.85, 0.32)
	_gens("femme", W - 1.2, 17.4, Vector3(1, 0, 0), "comptoir", L_GUICHET, false, true)
	# ---- le coin des équipes (au sud) : les vestiaires, le distributeur, le banc
	for i5 in range(5):
		_bx("plastique_bleu" if i5 % 2 == 0 else "k187_orange", 3.0 + i5 * 0.62, 3.58 + i5 * 0.62, 0.0, 1.9, D - 0.8, D - 0.25, i5 == 0)
		_bx("in_inox", 3.5 + i5 * 0.62, 3.54 + i5 * 0.62, 0.9, 1.05, D - 0.83, D - 0.8)
	_distributeur(7.0, D - 0.72, Vector3(0, 0, -1), "plastique_rouge")
	_bx("bois", 3.2, 6.0, 0.42, 0.48, D - 2.3, D - 1.9, true)
	for sb in [3.3, 5.9]:
		_bx("in_inox", sb - 0.03, sb + 0.03, 0.0, 0.42, D - 2.25, D - 1.95)
	# ---- sous le plafond : deux gaines de ventilation et leurs colliers, le chemin de câbles ; aux murs, les enseignes
	for gx in [cx0 - 2.3, cx1 + 2.3]:
		_bx("in_inox", gx - 0.3, gx + 0.3, hc - 0.52, hc - 0.14, 0.5, D - 0.5)
		var gz: float = 1.2
		while gz < D - 0.8:
			_bx("metal_noir", gx - 0.33, gx + 0.33, hc - 0.55, hc - 0.11, gz - 0.04, gz + 0.04)
			_bx("metal_noir", gx - 0.01, gx + 0.01, hc - 0.14, hc, gz - 0.01, gz + 0.01)
			gz += 2.4
		for bz2 in [4.0, D - 4.0]:
			_bx("metal_noir", gx - 0.2, gx + 0.2, hc - 0.6, hc - 0.52, bz2 - 0.3, bz2 + 0.3)
	_bx("metal_noir", 0.6, W - 0.6, hc - 0.34, hc - 0.31, 7.0, 7.3)
	for i6 in range(4):
		b.tube(["plastique_rouge", "plastique_bleu", "plastique_noir", "peinture_jaune"][i6], _p(0.6, hc - 0.29, 7.05 + i6 * 0.06), _p(W - 0.6, hc - 0.29, 7.05 + i6 * 0.06), 0.018, 5)
	_image("kumo_depot.png", _p(4.55, 2.5, D - 0.24), Vector3(0, 0, -1), Vector2(3.2, 0.4), 1.3)
	_image("kumo_express.png", _p(W - 1.75, 2.45, 16.0), Vector3(0, 0, -1), Vector2(2.0, 0.25), 1.5)
	# l'extincteur, la trousse de secours (près de la porte de service)
	b.cyl_at("plastique_rouge", _p(13.4, 0.5, D - 0.32), 0.07, 0.07, 0.42, 10)
	b.cyl_at("metal_noir", _p(13.4, 0.92, D - 0.32), 0.025, 0.035, 0.07, 6)
	_bx("peinture_blanche", 12.6, 13.0, 1.2, 1.5, D - 0.26, D - 0.2)
	_bx("tissu_vert", 12.72, 12.88, 1.32, 1.38, D - 0.27, D - 0.26)
	_bx("tissu_vert", 12.77, 12.83, 1.27, 1.43, D - 0.27, D - 0.26)
	# ---- les gens du dépôt
	_gens("homme", 13.3, 3.6, Vector3(1, 0, -0.3).normalized(), "debout", L_DEPOT, false, true)
	_gens("femme", 15.9, 12.6, Vector3(0, 0, 1), "bras_croises", L_DEPOT)
	_gens("homme", 3.6, 3.0, Vector3(-1, 0, 0), "debout", L_DEPOT, true)
	_gens("homme", 4.4, D - 2.1, Vector3(0, 0, -1), "assis", L_DEPOT)
	_gens("femme", 3.6, 11.0, Vector3(-1, 0, 0), "debout", L_DEPOT)
	return "drone_vol"


# ------------------------------------------------------------------ le 3e : la salle de pilotage
func _pilotage() -> String:
	var core: Rect2 = T.info["core"]
	var cz0: float = core.position.y - Z0
	var cx1: float = core.end.x - X0
	var cx0: float = core.position.x - X0
	# la pénombre : les lumières de l'étage baissées, bleutées
	for ch in (T.get("_node") as Node3D).get_children():
		if ch is OmniLight3D:
			(ch as OmniLight3D).light_energy *= 0.4
			(ch as OmniLight3D).light_color = Color(0.55, 0.75, 1.0)
	# ---- le mur d'écrans, devant les fenêtres du quai : la carte des vols, deux volets de côté
	var mx: float = W * 0.5
	_bx("in_noir", mx - 3.5, mx + 3.5, 0.35, 3.05, 1.0, 1.2, true)
	var carte := ShaderMaterial.new()
	carte.shader = load("res://shaders/carte_v188.gdshader")
	if ResourceLoader.exists(TEX + "carte_vols.png"):
		carte.set_shader_parameter("image", load(TEX + "carte_vols.png"))
	var qm := QuadMesh.new()
	qm.size = Vector2(6.67, 2.5)
	var ec := MeshInstance3D.new()
	ec.mesh = qm
	ec.material_override = carte
	(T.get("_node") as Node3D).add_child(ec)
	ec.global_transform = Transform3D(Basis(Vector3.UP, 0.0), _p(mx, 1.7, 1.21))
	for sg in [-1.0, 1.0]:
		var xf := Transform3D(Basis(Vector3.UP, -sg * deg_to_rad(28.0)), _p(mx + sg * 5.15, 1.7, 1.75))
		b.box("in_noir", xf, Vector3(3.5, 2.7, 0.16))
		# (les volets : la moitié gauche et la moitié droite de la carte, en plus grand)
		var cv := carte.duplicate() as ShaderMaterial
		cv.set_shader_parameter("fenetre", Vector4(0.0 if sg < 0.0 else 0.5, 0.0, 0.5, 1.0))
		var qv := QuadMesh.new()
		qv.size = Vector2(3.2, 2.4)
		var ev := MeshInstance3D.new()
		ev.mesh = qv
		ev.material_override = cv
		(T.get("_node") as Node3D).add_child(ev)
		ev.global_transform = xf * Transform3D(Basis(), Vector3(0, 0, 0.09))
		T._col(_p(mx + sg * 5.15, 1.5, 1.75), Vector3(3.2, 3.0, 1.2))
	# la pénombre : un faux plafond sombre sous les dalles de lumière, des liserés de lumière bleue
	_bx("in_noir", 0.3, W - 0.3, hc - 0.09, hc - 0.07, 0.3, D - 0.3)
	for lzz in [3.0, 6.6, D - 6.6, D - 3.0]:
		_bx("neon_cyan", 1.0, W - 1.0, hc - 0.1, hc - 0.09, lzz - 0.02, lzz + 0.02)
	_bx("neon_cyan", mx - 3.5, mx + 3.5, 0.3, 0.34, 1.2, 1.24)
	var o := OmniLight3D.new()
	o.light_color = Color(0.4, 0.8, 1.0)
	o.light_energy = 1.6
	o.omni_range = 9.0
	(T.get("_node") as Node3D).add_child(o)
	o.global_position = _p(mx, 1.8, 2.6)
	# ---- les pupitres des pilotes : deux rangs, de part et d'autre de l'allée
	var n_p: int = 0
	for rg in range(2):
		for lx in [2.2, 6.0, W - 6.0, W - 2.6]:
			var pz: float = 3.9 + rg * 2.2
			var px: float = lx + (0.35 if rg == 1 else 0.0) * (1.0 if lx < mx else -1.0)
			if not T._libre(_p(px, 0.0, pz), 0.5):
				continue
			_pupitre(px, pz)
			if (rg * 4 + n_p) % 4 != 3:
				_gens("femme" if (n_p + rg) % 2 == 0 else "homme", px, pz + 0.62, Vector3(0, 0, -1), "assis", L_PILOTE, n_p == 2)
			n_p += 1
	# la cheffe des vols, debout derrière ses pilotes
	_gens("femme", cx1 + 1.6, cz0 - 0.9, Vector3(-0.4, 0, -1).normalized(), "bras_croises", L_CHEF, false, true)
	# ---- le briefing (à l'est) : la table ronde, l'hologramme d'un drone qui tourne
	var bz: float = (core.position.y + core.end.y) * 0.5 - Z0
	var bxc: float = (cx1 + 1.5 + W) * 0.5
	b.cyl_at("in_noir", _p(bxc, 0.0, bz), 0.18, 0.14, 0.72, 10)
	b.cyl_at("in_bureau", _p(bxc, 0.72, bz), 1.1, 1.1, 0.05, 24)
	b.cyl_at("neon_cyan", _p(bxc, 0.775, bz), 0.5, 0.5, 0.01, 20)
	T._col(_p(bxc, 0.4, bz), Vector3(1.8, 0.8, 1.8))
	var loth := Kit.Batch.new()
	_drone(loth, Vector3.ZERO, 0.0, true, 2.2)
	var holo := MeshInstance3D.new()
	holo.mesh = _maillage(loth)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.3, 0.9, 1.0, 0.45)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.emission_enabled = true
	hm.emission = Color(0.3, 0.9, 1.0)
	hm.emission_energy_multiplier = 1.6
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo.material_override = hm
	_anime().add_child(holo)
	holo.global_position = _p(bxc, 1.5, bz)
	_anime().tourne.append([holo, 0.7])
	_anime().flotte.append([holo, _p(bxc, 1.5, bz), 0.06, 1.2, 0.0])
	for a in range(4):
		var ang: float = a * PI * 0.5 + 0.6
		T._chaise(b, _p(bxc + cos(ang) * 1.65, 0.0, bz + sin(ang) * 1.65), Vector3(-cos(ang), 0, -sin(ang)))
	_gens("homme", bxc + cos(0.6) * 1.65, bz + sin(0.6) * 1.65, Vector3(-cos(0.6), 0, -sin(0.6)), "assis", L_PILOTE)
	# ---- les simulateurs (au sud) : deux cabines, leur siège, leurs trois écrans
	for sx in [4.0, W - 4.0]:
		var sz: float = D - 2.6
		_bx("in_noir", sx - 1.1, sx + 1.1, 0.0, 0.25, sz - 1.2, sz + 1.2, true)
		_bx("in_noir", sx - 1.1, sx + 1.1, 0.25, 2.2, sz + 1.1, sz + 1.2)
		for sg2 in [-1.0, 1.0]:
			_bx("in_noir", sx + sg2 * 1.05 - 0.05, sx + sg2 * 1.05 + 0.05, 0.25, 2.2, sz - 0.2, sz + 1.2)
			_bx("in_ecran_ui_graphes", sx + sg2 * 1.0 - 0.01, sx + sg2 * 1.0 + 0.01, 1.0, 1.9, sz + 0.1, sz + 1.0)
		var cs := carte.duplicate() as ShaderMaterial
		cs.set_shader_parameter("fenetre", Vector4(0.33, 0.1, 0.34, 0.8))
		var qs := QuadMesh.new()
		qs.size = Vector2(1.8, 1.0)
		var es := MeshInstance3D.new()
		es.mesh = qs
		es.material_override = cs
		(T.get("_node") as Node3D).add_child(es)
		es.global_transform = Transform3D(Basis(Vector3.UP, PI), _p(sx, 1.5, sz + 1.09))
		_bx("neon_cyan", sx - 1.1, sx + 1.1, 0.25, 0.27, sz - 1.21, sz - 1.2)
		_bx("k187_orange", sx - 1.1, sx + 1.1, 2.2, 2.26, sz - 0.2, sz + 1.2)
		T._chaise(b, _p(sx, 0.25, sz - 0.1), Vector3(0, 0, 1))
		b.cyl_at("in_noir", _p(sx + 0.3, 0.25, sz + 0.4), 0.03, 0.03, 0.75, 6)
	_gens("femme", 4.0, D - 2.7 + 0.5, Vector3(0, 0, 1), "debout", L_PILOTE)
	# ---- le coin du café (à l'ouest) : le comptoir, la machine, le canapé, le tableau des records
	var wz: float = bz
	_bx("in_bois", 0.5, 1.2, 0.0, 0.95, wz - 1.8, wz + 0.2, true)
	_bx("in_inox", 0.6, 1.05, 0.95, 1.4, wz - 1.6, wz - 1.1)
	_bx("in_led_ambre", 1.05, 1.07, 1.15, 1.25, wz - 1.5, wz - 1.2)
	_canape(0.95, wz + 1.8, Vector3(1, 0, 0), 2.0)
	_plante_pot(0.8, wz + 3.5, 1.2)
	_bx("in_noir", cx0 - 0.07, cx0, 1.0, 2.4, bz - 1.3, bz + 1.3)
	_bx("in_ecran_ui_messages", cx0 - 0.09, cx0 - 0.07, 1.1, 2.3, bz - 1.2, bz + 1.2)
	return "bip"


## Un pupitre de pilote (tourné vers le mur d'écrans, au nord) : le plateau, trois écrans, le manche, la chaise.
func _pupitre(lx: float, lz: float) -> void:
	_bx("in_bureau", lx - 0.95, lx + 0.95, 0.7, 0.75, lz - 0.45, lz + 0.3, true)
	_bx("in_noir", lx - 0.95, lx + 0.95, 0.0, 0.7, lz - 0.45, lz - 0.38)
	for sg in [-0.92, 0.92]:
		_bx("in_noir", lx + sg - 0.03, lx + sg + 0.03, 0.0, 0.7, lz - 0.45, lz + 0.3)
	_bx("neon_cyan", lx - 0.95, lx + 0.95, 0.68, 0.7, lz + 0.3, lz + 0.31)
	var ecrans: Array = ["in_ecran_ui_graphes", "in_ecran", "in_ecran_ui_code"]
	for i in range(3):
		var xf := Transform3D(Basis(Vector3.UP, (1 - i) * deg_to_rad(24.0)), _p(lx + (i - 1) * 0.62, 1.08, lz - 0.3 + absf(i - 1.0) * 0.1))
		b.box("in_noir", xf, Vector3(0.6, 0.42, 0.03))
		b.box(str(ecrans[i]), xf * Transform3D(Basis(), Vector3(0, 0, 0.018)), Vector3(0.55, 0.37, 0.005))
		b.box("in_noir", Transform3D(Basis(), _p(lx + (i - 1) * 0.62, 0.82, lz - 0.32)), Vector3(0.06, 0.14, 0.06))
	b.cyl_at("in_noir", _p(lx + 0.45, 0.75, lz + 0.05), 0.05, 0.04, 0.03, 8)
	b.cyl_at("in_noir", _p(lx + 0.45, 0.78, lz + 0.05), 0.018, 0.022, 0.14, 6)
	b.blob("neon_rouge", _p(lx + 0.45, 0.93, lz + 0.05), Vector3(0.025, 0.025, 0.025), 5)
	_bx("in_noir", lx - 0.5, lx - 0.05, 0.75, 0.765, lz - 0.05, lz + 0.12)
	T._chaise(b, _p(lx, 0.0, lz + 0.62), Vector3(0, 0, -1))


# ------------------------------------------------------------------ le 7e : le jardin d'hiver
func _jardin() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var mx: float = W * 0.5
	# les allées de bois : de l'ascenseur à la loggia du quai, le tour du cœur, vers la loggia du boulevard
	_bx("bois", mx - 1.1, mx + 1.1, 0.0, 0.03, 2.6, cz0)
	_bx("bois", cx0 - 1.6, cx1 + 1.6, 0.0, 0.03, cz1, cz1 + 1.4)
	_bx("bois", cx0 - 1.6, cx0, 0.0, 0.03, cz0 - 1.4, cz1)
	_bx("bois", cx1, W - 2.6, 0.0, 0.03, cz0 - 1.4, cz0)
	_bx("bois", cx1, cx1 + 1.6, 0.0, 0.03, cz0, cz1)
	# ---- les bambous (au nord-ouest) : un bac, une trentaine de cannes, leurs feuilles
	_bac(0.6, 6.4, 3.2, 6.4)
	for i in range(30):
		var bx2: float = rng.randf_range(0.9, 6.1)
		var bz2: float = rng.randf_range(3.5, 6.1)
		var hh: float = rng.randf_range(2.0, hc - 0.25)
		b.cyl_at("k187_feuillage_clair", _p(bx2, 0.36, bz2), 0.032, 0.022, hh - 0.36, 7)
		var nd: float = 0.7
		while nd < hh - 0.1:                       # (les nœuds de la canne)
			b.cyl_at("k187_feuillage", _p(bx2, nd, bz2), 0.036, 0.036, 0.018, 7)
			nd += 0.34
		for f in range(3):
			var sf: float = rng.randf_range(0.2, 0.3)
			_vegetal(Flora.bush(1890 + (i + f) % 4), _p(bx2 + rng.randf_range(-0.1, 0.1), hh - 0.3 - f * rng.randf_range(0.35, 0.55), bz2 + rng.randf_range(-0.1, 0.1)), Vector3(sf * 1.3, sf * 0.9, sf * 1.3), rng.randf() * TAU)
	for i5 in range(9):
		_vegetal(Flora.grass_clump(11, 0.5, 0.05, 3 + i5 % 3), _p(rng.randf_range(0.9, 6.1), 0.36, rng.randf_range(3.5, 6.1)), Vector3(0.8, 0.7, 0.8), rng.randf() * TAU)
	# ---- les fougères et les fleurs (au sud-ouest), les arbres (au sud)
	_bac(0.6, 6.0, cz1 + 2.2, D - 0.7)
	var teintes: Array = [Color(1.0, 0.55, 0.7), Color(1.0, 0.85, 0.3), Color(0.95, 0.95, 1.0), Color(0.75, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
	for i2 in range(22):
		var fx: float = rng.randf_range(1.0, 5.6)
		var fz: float = rng.randf_range(cz1 + 2.6, D - 1.1)
		var sorte: float = rng.randf()
		if sorte < 0.4:
			var sf2: float = rng.randf_range(0.8, 1.25)
			_vegetal(Flora.fern_clump(), _p(fx, 0.36, fz), Vector3(sf2, sf2, sf2), rng.randf() * TAU)
		elif sorte < 0.6:
			var sb2: float = rng.randf_range(0.5, 0.8)
			_vegetal(Flora.bush(1885 + i2 % 4), _p(fx, 0.34, fz), Vector3(sb2, sb2, sb2), rng.randf() * TAU)
		else:
			_fleurs(_p(fx, 0.36, fz), teintes[rng.randi() % teintes.size()], rng.randf_range(0.7, 1.0))
	for i6 in range(3):
		b.blob("pierre", _p(rng.randf_range(1.2, 5.4), 0.38, rng.randf_range(cz1 + 2.7, D - 1.2)), Vector3(0.22, 0.13, 0.18), 6)
	_bac(W - 9.0, W - 0.7, D - 3.4, D - 0.7)
	for ax in [W - 8.0, W - 5.0, W - 2.0]:
		_arbre(ax, D - 2.0)
	for i7 in range(7):
		_vegetal(Flora.fern_clump() if i7 % 2 == 0 else Flora.grass_clump(11, 0.5, 0.05, 3 + i7 % 3), _p(rng.randf_range(W - 8.7, W - 1.0), 0.36, rng.randf_range(D - 3.1, D - 1.0)), Vector3(0.8, 0.8, 0.8), rng.randf() * TAU)
	# ---- le jardin sec (au sud, entre les fougères et les arbres) : le gravier ratissé, trois pierres, la lanterne de pierre
	var s0: float = 6.6
	var s1: float = W - 9.6
	if s1 - s0 > 1.6:
		for e2 in [[s0, s1, cz1 + 2.7, cz1 + 2.82], [s0, s1, D - 0.82, D - 0.7], [s0, s0 + 0.12, cz1 + 2.7, D - 0.7], [s1 - 0.12, s1, cz1 + 2.7, D - 0.7]]:
			_bx("pierre", e2[0], e2[1], 0.0, 0.14, e2[2], e2[3])
		_bx("gravier_zen", s0 + 0.1, s1 - 0.1, 0.0, 0.1, cz1 + 2.8, D - 0.8)
		var gm: float = (s0 + s1) * 0.5
		for q5 in [[gm - 0.7, cz1 + 3.6, 0.34, 0.3], [gm + 0.5, cz1 + 3.3, 0.2, 0.16], [gm + 0.2, D - 1.5, 0.26, 0.2]]:
			b.blob("pierre", _p(q5[0], 0.1 + q5[3] * 0.6, q5[1]), Vector3(q5[2], q5[3], q5[2] * 0.8), 7)
		# la lanterne de pierre
		var lxp: float = s1 - 0.7
		var lzp: float = D - 1.5
		b.cyl_at("pierre", _p(lxp, 0.1, lzp), 0.16, 0.12, 0.1, 6)
		b.cyl_at("pierre", _p(lxp, 0.2, lzp), 0.06, 0.06, 0.4, 6)
		b.cyl_at("pierre", _p(lxp, 0.6, lzp), 0.15, 0.1, 0.06, 6)
		b.cyl_at("lampe_chaude", _p(lxp, 0.66, lzp), 0.09, 0.09, 0.16, 6)
		b.cyl_at("pierre", _p(lxp, 0.82, lzp), 0.03, 0.22, 0.12, 6)
		_vegetal(Flora.bush(1894), _p(gm - 0.75, 0.36, cz1 + 3.55), Vector3(0.4, 0.45, 0.4), 0.7)
		T._col(_p(gm, 0.3, (cz1 + 2.7 + D - 0.7) * 0.5), Vector3(s1 - s0, 0.6, D - 0.7 - cz1 - 2.7))
	# ---- le bassin (à l'est) : la margelle de pierre, l'eau, le petit pont, la fontaine de bambou
	var b0: float = cx1 + 2.4
	var b1: float = W - 3.4
	_bx("pierre", b0 - 0.25, b1 + 0.25, 0.0, 0.3, cz0 + 0.6, cz1 + 0.4, true)
	_bx("eau", b0, b1, 0.3, 0.31, cz0 + 0.85, cz1 + 0.15)
	for i3 in range(7):
		var a: float = float(i3) / 6.0
		var hx: float = sin(a * PI) * 0.35
		b.box("bois", Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(lerpf(22.0, -22.0, a))), _p((b0 + b1) * 0.5, 0.36 + hx, lerpf(cz0 + 0.5, cz1 + 0.5, a))), Vector3(1.0, 0.05, (cz1 - cz0) / 6.4))
	for sg in [-0.5, 0.5]:
		b.tube("bois", _p((b0 + b1) * 0.5 + sg, 0.9, cz0 + 0.5), _p((b0 + b1) * 0.5 + sg, 1.25, (cz0 + cz1) * 0.5 + 0.5), 0.03, 6)
		b.tube("bois", _p((b0 + b1) * 0.5 + sg, 1.25, (cz0 + cz1) * 0.5 + 0.5), _p((b0 + b1) * 0.5 + sg, 0.9, cz1 + 0.5), 0.03, 6)
	b.tube("k187_feuillage_clair", _p(b1 - 0.2, 0.3, cz0 + 1.2), _p(b1 - 0.2, 1.2, cz0 + 1.2), 0.05, 6)
	b.tube("k187_feuillage_clair", _p(b1 - 0.2, 1.1, cz0 + 1.2), _p(b1 - 0.8, 0.85, cz0 + 1.5), 0.04, 6)
	for q in [[b0 + 0.5, cz0 + 1.3, 0.3], [b0 + 0.9, cz1 - 0.3, 0.22], [b1 - 0.6, cz1 - 0.2, 0.28]]:
		b.blob("pierre", _p(q[0], 0.36, q[1]), Vector3(q[2], q[2] * 0.6, q[2]), 6)
	b.tube("eau", _p(b1 - 0.8, 0.85, cz0 + 1.5), _p(b1 - 0.82, 0.31, cz0 + 1.52), 0.012, 5)
	for i8 in range(7):
		var nx: float = rng.randf_range(b0 + 0.3, b1 - 0.3)
		var nz: float = rng.randf_range(cz0 + 1.1, cz1 - 0.1)
		if absf(nx - (b0 + b1) * 0.5) < 0.7:
			nx += 0.9 if nx > (b0 + b1) * 0.5 else -0.9
		b.cyl_at("k187_feuillage" if i8 % 2 == 0 else "k187_feuillage_clair", _p(nx, 0.312, nz), 0.17, 0.17, 0.008, 9)
		if i8 % 3 == 0:
			b.blob("sakura", _p(nx + 0.04, 0.35, nz), Vector3(0.07, 0.045, 0.07), 6)
			b.blob("tissu_jaune", _p(nx + 0.04, 0.385, nz), Vector3(0.025, 0.02, 0.025), 5)
	for i9 in range(4):
		_vegetal(Flora.reed_clump(), _p(b0 + 0.25 + i9 * 0.2, 0.3, cz1 - 0.05 - (i9 % 2) * 0.25), Vector3(0.45, 0.5, 0.45), i9 * 1.3)
	# les carpes : trois taches de couleur qui tournent sous l'eau
	for i4 in range(3):
		var cm := MeshInstance3D.new()
		var lotc := Kit.Batch.new()
		lotc.blob(["k187_orange", "peinture_blanche", "k187_fleurs"][i4], Vector3(0.45 + i4 * 0.12, 0, 0), Vector3(0.16, 0.03, 0.06), 6)
		cm.mesh = _maillage(lotc)
		_anime().add_child(cm)
		cm.global_position = _p((b0 + b1) * 0.5 + (i4 - 1) * 0.5, 0.27, (cz0 + cz1) * 0.5 + 0.5 + (i4 - 1) * 0.9)
		_anime().tourne.append([cm, 0.5 + i4 * 0.2])
	# ---- le comptoir à thé (contre le cœur, à l'ouest), ses tabourets, sa théière
	_bx("bois", cx0 - 0.7, cx0 - 0.15, 0.0, 1.0, cz0 + 0.4, cz1 - 0.4, true)
	_bx("bois_clair", cx0 - 0.85, cx0 - 0.1, 1.0, 1.05, cz0 + 0.3, cz1 - 0.3)
	# la théière de fonte, ses tasses, le plateau ; derrière, l'étagère des boîtes à thé
	b.blob("metal_noir", _p(cx0 - 0.45, 1.16, cz0 + 1.1), Vector3(0.13, 0.1, 0.13), 8)
	b.cyl_at("metal_noir", _p(cx0 - 0.45, 1.25, cz0 + 1.1), 0.05, 0.03, 0.03, 8)
	b.tube("metal_noir", _p(cx0 - 0.45, 1.17, cz0 + 1.22), _p(cx0 - 0.45, 1.24, cz0 + 1.34), 0.018, 5)
	_bx("rouge_laque", cx0 - 0.75, cx0 - 0.25, 1.05, 1.065, cz0 + 1.5, cz0 + 2.2)
	for i10 in range(3):
		b.cyl_at("peinture_blanche", _p(cx0 - 0.6 + (i10 % 2) * 0.2, 1.065, cz0 + 1.65 + i10 * 0.2), 0.035, 0.045, 0.06, 8)
	for niv2 in range(2):
		_bx("bois", cx0 - 0.14, cx0, 1.55 + niv2 * 0.5, 1.59 + niv2 * 0.5, cz0 + 0.5, cz1 - 0.5)
		var jz: float = cz0 + 0.65
		while jz < cz1 - 0.6:
			var jr: float = rng.randf_range(0.05, 0.075)
			b.cyl_at(["rouge_laque", "in_pot", "metal_noir", "tissu_vert", "peinture_blanche"][rng.randi() % 5], _p(cx0 - 0.08, 1.59 + niv2 * 0.5, jz), jr, jr, rng.randf_range(0.14, 0.24), 8)
			jz += rng.randf_range(0.18, 0.34)
	for tz in [cz0 + 1.0, (cz0 + cz1) * 0.5, cz1 - 1.0]:
		b.cyl_at("in_inox", _p(cx0 - 1.35, 0.0, tz), 0.03, 0.03, 0.65, 6)
		b.cyl_at("bois_clair", _p(cx0 - 1.35, 0.65, tz), 0.18, 0.18, 0.05, 12)
	_gens("femme", cx0 - 0.45, cz0 - 0.15, Vector3(0, 0, 1), "comptoir", L_JARDIN, true, true)
	T.info["sans_promeneurs"] = true            # (on ne fait pas le tour du cœur : le comptoir à thé y est adossé)
	# ---- les bancs des loggias, face à la mer et face au boulevard ; les lanternes
	for bxx in [4.0, mx + 3.6, W - 6.0]:
		_bx("bois", bxx - 0.9, bxx + 0.9, 0.42, 0.48, 1.3, 1.75, true)
		for sb in [-0.8, 0.8]:
			_bx("in_noir", bxx + sb - 0.03, bxx + sb + 0.03, 0.0, 0.42, 1.35, 1.7)
	for lzz in [6.0, 14.0]:
		_bx("bois", W - 1.75, W - 1.3, 0.42, 0.48, lzz - 0.9, lzz + 0.9, true)
	for q2 in [[2.2, 2.2], [mx - 2.0, 2.2], [W - 2.2, 2.2], [W - 2.2, 10.0], [W - 2.2, 17.0], [2.0, cz1 + 1.6], [mx, cz1 + 2.2]]:
		_lanterne(q2[0], q2[1])
	# ---- sous le plafond : un claire-voie de bois, qui tamise la lumière
	var lv: float = 3.0
	while lv < D - 2.9:
		if lv > cz0 - 0.1 and lv < cz1 + 0.1:
			_bx("bois", 2.9, cx0 - 0.05, hc - 0.16, hc - 0.04, lv - 0.05, lv + 0.05)
			_bx("bois", cx1 + 0.05, W - 2.9, hc - 0.16, hc - 0.04, lv - 0.05, lv + 0.05)
		else:
			_bx("bois", 0.3, W - 2.9, hc - 0.16, hc - 0.04, lv - 0.05, lv + 0.05)
		lv += 0.5
	for lw in [3.2, W * 0.5, W - 3.2]:
		_bx("bois", lw - 0.07, lw + 0.07, hc - 0.24, hc - 0.16, 2.9, D - 0.4)
	# ---- ceux qui prennent l'air
	_gens("homme", 4.0, 1.52, Vector3(0, 0, -1), "assis", L_JARDIN)
	_gens("femme", mx + 3.6, 1.52, Vector3(0, 0, -1), "assis", L_JARDIN, false, true)
	_gens("femme", W - 1.52, 14.0, Vector3(1, 0, 0), "assis", L_JARDIN)
	_gens("homme", 7.0, cz1 + 1.9, Vector3(-1, 0, 0.2).normalized(), "debout", L_JARDIN)
	return "fontaine_holo"


func _bac(lx0: float, lx1: float, lz0: float, lz1: float) -> void:
	for e in [[lx0, lx1, lz0, lz0 + 0.12], [lx0, lx1, lz1 - 0.12, lz1], [lx0, lx0 + 0.12, lz0, lz1], [lx1 - 0.12, lx1, lz0, lz1]]:
		_bx("bois_clair", e[0], e[1], 0.0, 0.42, e[2], e[3])
	_bx("terre_bac", lx0 + 0.1, lx1 - 0.1, 0.0, 0.36, lz0 + 0.1, lz1 - 0.1)
	T._col(_p((lx0 + lx1) * 0.5, 0.5, (lz0 + lz1) * 0.5), Vector3(lx1 - lx0, 1.0, lz1 - lz0))


## Un arbre d'intérieur : un vrai arbre du jeu (son tronc, ses branches, ses feuilles), à la taille de l'étage.
func _arbre(lx: float, lz: float) -> void:
	var k: float = (hc - 0.5) / 7.0
	_vegetal(Flora.tree(1880 + int(lx * 3.0) % 4, 7.0, 240), _p(lx, 0.34, lz), Vector3(k * 1.15, k, k * 1.15), rng.randf() * TAU)


# ------------------------------------------------------------------ le 12e : la présidence
func _presidence() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var mx: float = W * 0.5
	# ---- l'antichambre (au nord, face à la mer) : le tapis, l'accueil, le canapé
	_bx("in_tissu_rouge", mx - 1.3, mx + 1.3, 0.0, 0.012, 0.6, cz0)
	_bx("in_bois", W - 3.6, W - 1.2, 0.0, 1.0, 2.2, 2.9, true)
	_bx("in_marbre_noir", W - 3.7, W - 1.1, 1.0, 1.05, 2.1, 3.0)
	_bx("in_ecran_ui_messages", W - 2.9, W - 2.3, 1.08, 1.45, 2.25, 2.28)
	_gens("homme", W - 2.4, 1.6, Vector3(0, 0, 1), "comptoir", L_ACCUEIL, false, true)
	_canape(1.9, 2.3, Vector3(0, 0, 1), 2.6)
	_bx("in_marbre_noir", 1.2, 2.6, 0.36, 0.4, 3.4, 4.0, true)
	for q0 in [[1.28, 3.48], [2.52, 3.48], [1.28, 3.92], [2.52, 3.92]]:
		b.cyl_at("in_inox", _p(q0[0], 0.0, q0[1]), 0.015, 0.015, 0.36, 6)
	_bx("peinture_blanche", 1.5, 1.8, 0.4, 0.41, 3.55, 3.77)
	_bx("in_tissu_rouge", 1.52, 1.8, 0.41, 0.425, 3.57, 3.78)
	b.cyl_at("peinture_blanche", _p(2.3, 0.4, 3.7), 0.04, 0.05, 0.07, 8)
	_plante_pot(0.8, 0.9, 1.5)
	_plante_pot(W - 0.8, 0.9, 1.5, true)
	# la longue-vue, tournée vers la mer : son trépied, son tube de laiton
	var lvx: float = mx - 1.2
	for a3 in range(3):
		var an: float = a3 * TAU / 3.0 + 0.5
		b.tube("in_bois", _p(lvx, 1.25, 1.0), _p(lvx + cos(an) * 0.42, 0.0, 1.0 + sin(an) * 0.42), 0.016, 5)
	b.tube("chrome", _p(lvx, 1.24, 1.22), _p(lvx, 1.44, 0.5), 0.045, 10)
	b.tube("metal_noir", _p(lvx, 1.235, 1.3), _p(lvx, 1.24, 1.22), 0.03, 8)
	T._col(_p(lvx, 0.7, 1.0), Vector3(0.7, 1.4, 0.8))
	# la maquette de la tour, sous verre : le socle, la tour, ses petits drones
	var px: float = mx - 3.2
	_bx("in_marbre_noir", px - 0.5, px + 0.5, 0.0, 0.9, 0.9, 1.9, true)
	_bx("k187_bardage", px - 0.2, px + 0.2, 0.9, 1.3, 1.2, 1.6)
	_bx("k187_bardage", px - 0.15, px + 0.15, 1.3, 1.55, 1.25, 1.55)
	_bx("neon_cyan", px - 0.16, px + 0.16, 1.55, 1.56, 1.24, 1.56)
	_bx("in_vitre", px - 0.45, px + 0.45, 0.9, 1.8, 0.95, 1.85)
	# le drone doré (le premier modèle), qui tourne sur son socle
	var gx: float = mx + 3.2
	_bx("in_marbre_noir", gx - 0.4, gx + 0.4, 0.0, 0.9, 1.0, 1.8, true)
	var lotg := Kit.Batch.new()
	_drone(lotg, Vector3.ZERO, 0.0, false, 0.9)
	var or_m := StandardMaterial3D.new()
	or_m.albedo_color = Color(0.95, 0.75, 0.3)
	or_m.metallic = 1.0
	or_m.roughness = 0.25
	var dg := MeshInstance3D.new()
	dg.mesh = _maillage(lotg)
	dg.material_override = or_m
	_anime().add_child(dg)
	dg.global_position = _p(gx, 1.15, 1.4)
	_anime().tourne.append([dg, 0.45])
	# ---- le bureau de Madame Kumo (au sud) : la grande table de marbre, le fauteuil, la bibliothèque
	var bz: float = D - 2.2
	var bxm: float = mx + 0.5
	_bx("in_tissu_rouge", bxm - 3.0, bxm + 3.0, 0.0, 0.012, cz1 + 1.8, D - 0.5)
	_bx("in_marbre_noir", bxm - 1.6, bxm + 1.6, 0.72, 0.8, bz - 0.6, bz + 0.6, true)
	for sg in [bxm - 1.45, bxm + 1.45]:
		_bx("in_bois", sg - 0.08, sg + 0.08, 0.0, 0.72, bz - 0.5, bz + 0.5)
	_bx("in_ecran_ui_graphes", bxm - 0.4, bxm + 0.4, 0.85, 1.3, bz + 0.2, bz + 0.22)
	_bx("in_noir", bxm - 0.05, bxm + 0.05, 0.8, 0.86, bz + 0.18, bz + 0.26)
	_carton(b, Transform3D(Basis(Vector3.UP, 0.25), _p(bxm + 0.98, 0.91, bz - 0.15)), Vector3(0.35, 0.22, 0.3))
	# la lampe de bureau, la plaque, le pot à crayons, les dossiers, le téléphone, la tasse
	b.cyl_at("in_inox", _p(bxm - 1.2, 0.8, bz + 0.2), 0.07, 0.07, 0.015, 10)
	b.cyl_at("in_inox", _p(bxm - 1.2, 0.8, bz + 0.2), 0.012, 0.012, 0.3, 6)
	b.cyl_at("lampe_chaude", _p(bxm - 1.2, 1.08, bz + 0.2), 0.13, 0.08, 0.14, 12)
	_bx("in_inox", bxm - 0.3, bxm + 0.3, 0.8, 0.87, bz - 0.5, bz - 0.47)
	b.cyl_at("in_noir", _p(bxm + 1.3, 0.8, bz + 0.25), 0.04, 0.04, 0.1, 8)
	for i11 in range(3):
		b.tube(["plastique_bleu", "plastique_rouge", "peinture_jaune"][i11], _p(bxm + 1.3 + (i11 - 1) * 0.015, 0.85, bz + 0.25), _p(bxm + 1.3 + (i11 - 1) * 0.04, 0.98, bz + 0.26), 0.005, 4)
	for i12 in range(3):
		_bx(["peinture_blanche", "in_tissu_rouge", "peinture_blanche"][i12], bxm - 1.0 + i12 * 0.02, bxm - 0.7 + i12 * 0.02, 0.8 + i12 * 0.012, 0.812 + i12 * 0.012, bz - 0.2, bz + 0.2)
	_bx("in_noir", bxm + 0.35, bxm + 0.55, 0.8, 0.83, bz + 0.25, bz + 0.45)
	b.cyl_at("peinture_blanche", _p(bxm - 0.55, 0.8, bz + 0.3), 0.035, 0.04, 0.08, 8)
	# le fauteuil de la présidente (haut dossier), la fresque derrière les visiteurs, le plafond à caisson
	_bx("in_cuir", bxm - 0.36, bxm + 0.36, 0.34, 0.48, bz + 0.85, bz + 1.5, true)
	b.box("in_cuir", Transform3D(Basis(Vector3(1, 0, 0), 0.14), _p(bxm, 0.95, bz + 1.5)), Vector3(0.7, 1.0, 0.12))
	for sg3 in [-0.4, 0.4]:
		_bx("in_cuir", bxm + sg3 - 0.05, bxm + sg3 + 0.05, 0.48, 0.72, bz + 0.9, bz + 1.45)
	b.cyl_at("in_inox", _p(bxm, 0.05, bz + 1.17), 0.04, 0.04, 0.3, 8)
	for a4 in range(5):
		b.tube("in_inox", _p(bxm, 0.06, bz + 1.17), _p(bxm + cos(a4 * TAU / 5.0) * 0.34, 0.03, bz + 1.17 + sin(a4 * TAU / 5.0) * 0.34), 0.02, 5)
	_tableau("fresque_kumo.png", _p(cx0 - 0.02, 1.75, (cz0 + cz1) * 0.5), Vector3(-1, 0, 0), Vector2(1.9, 1.9))
	for e3 in [[bxm - 3.0, bxm + 3.0, cz1 + 1.7, cz1 + 1.9], [bxm - 3.0, bxm + 3.0, D - 0.6, D - 0.4], [bxm - 3.0, bxm - 2.8, cz1 + 1.7, D - 0.4], [bxm + 2.8, bxm + 3.0, cz1 + 1.7, D - 0.4]]:
		_bx("in_bois", e3[0], e3[1], hc - 0.22, hc - 0.02, e3[2], e3[3])
	for e4 in [[bxm - 2.8, bxm + 2.8, cz1 + 1.9, cz1 + 1.94], [bxm - 2.8, bxm + 2.8, D - 0.64, D - 0.6]]:
		_bx("lampe_chaude", e4[0], e4[1], hc - 0.2, hc - 0.17, e4[2], e4[3])
	_gens("femme", bxm, bz + 1.15, Vector3(0, 0, -1), "assis", L_PRESIDENTE, false, true)
	for vx in [bxm - 0.8, bxm + 0.8]:
		T._chaise(b, _p(vx, 0.0, bz - 1.3), Vector3(0, 0, 1))
	# la bibliothèque (contre le mur de l'ouest) : des dossiers, des trophées, des petits drones
	for niv in range(5):
		_bx("in_bois", 0.25, 0.75, 0.2 + niv * 0.52, 0.24 + niv * 0.52, cz1 + 2.2, D - 0.6)
		var lz: float = cz1 + 2.3
		while lz < D - 0.8:
			var w: float = rng.randf_range(0.06, 0.3)
			var sorte: float = rng.randf()
			if sorte < 0.7:
				_bx(["in_tissu_rouge", "in_cuir", "in_bois_clair", "plastique_bleu", "in_tissu_gris"][rng.randi() % 5], 0.32, 0.6, 0.24 + niv * 0.52, 0.24 + niv * 0.52 + rng.randf_range(0.28, 0.42), lz, lz + w)
			elif sorte < 0.82:
				b.cyl_at("in_inox", _p(0.5, 0.24 + niv * 0.52, lz + 0.1), 0.05, 0.08, 0.22, 8)
			lz += w + rng.randf_range(0.01, 0.12)
	_bx("in_bois", 0.2, 0.3, 0.0, 2.85, cz1 + 2.1, D - 0.5, true)
	# ---- la table du conseil (à l'ouest, le long du cœur) : six fauteuils
	var tz: float = (cz0 + cz1) * 0.5
	_bx("in_bois", 1.2, 2.3, 0.72, 0.78, tz - 1.6, tz + 1.6, true)
	_bx("in_noir", 1.55, 1.95, 0.0, 0.72, tz - 0.3, tz + 0.3)
	for i13 in range(3):                         # (les trois suspensions de la table du conseil)
		b.cyl_at("in_noir", _p(1.75, 1.75, tz - 1.1 + i13 * 1.1), 0.004, 0.004, hc - 1.75, 4)
		b.cyl_at("in_noir", _p(1.75, 1.62, tz - 1.1 + i13 * 1.1), 0.16, 0.05, 0.13, 12)
		b.cyl_at("lampe_chaude", _p(1.75, 1.6, tz - 1.1 + i13 * 1.1), 0.14, 0.14, 0.02, 12)
	for i in range(3):
		T._chaise(b, _p(0.75, 0.0, tz - 1.1 + i * 1.1), Vector3(1, 0, 0))
		T._chaise(b, _p(2.75, 0.0, tz - 1.1 + i * 1.1), Vector3(-1, 0, 0))
	_gens("homme", 0.75, tz, Vector3(1, 0, 0), "assis", ["Le conseil commence dans dix minutes. Depuis une heure.", "Vous avez vu le drone doré ? Il n'a jamais volé. Il est trop beau pour ça."])
	# ---- la galerie des premiers colis (à l'est) : trois vitrines, leurs étiquettes
	var gz: float = (cz0 + cz1) * 0.5
	for i2 in range(3):
		var vz: float = gz - 1.6 + i2 * 1.6
		_bx("in_marbre_blanc", W - 1.3, W - 0.6, 0.0, 0.95, vz - 0.35, vz + 0.35, true)
		_bx("in_vitre", W - 1.25, W - 0.65, 0.95, 1.55, vz - 0.3, vz + 0.3)
		if i2 == 0:
			_colis(W - 0.95, 0.95, vz, 0.36)
		elif i2 == 1:
			b.cyl_at("peinture_blanche", _p(W - 0.95, 0.95, vz), 0.12, 0.16, 0.14, 10)
			b.cyl_at("k187_orange", _p(W - 0.95, 1.09, vz), 0.16, 0.16, 0.02, 10)
		else:
			_drone(b, _p(W - 0.95, 1.1, vz), 0.7, false, 0.55)
		var lab: Label3D = T._label(["Le premier colis (2087)", "Les nouilles du premier jour", "K-0001, le doyen"][i2], 22, Color(0.95, 0.85, 0.6))
		lab.global_position = _p(W - 1.32, 0.6, vz)
		lab.look_at(lab.global_position + Vector3(1, 0, 0), Vector3.UP)
	# ---- le salon (au sud-est) : deux fauteuils, la table basse, le bonsaï
	var sx0: float = W - 2.4
	for sg2 in [-1.0, 1.0]:
		_canape(sx0 + sg2 * 1.05, D - 1.15, Vector3(-sg2 * 0.35, 0, -1).normalized(), 1.0)
	# le lampadaire, le meuble aux carafes
	b.cyl_at("in_noir", _p(W - 0.7, 0.0, D - 0.7), 0.14, 0.14, 0.02, 12)
	b.cyl_at("in_noir", _p(W - 0.7, 0.0, D - 0.7), 0.012, 0.012, 1.6, 6)
	b.cyl_at("lampe_chaude", _p(W - 0.7, 1.55, D - 0.7), 0.17, 0.12, 0.26, 12)
	_bx("in_bois", W - 1.0, W - 0.45, 0.0, 0.85, D - 4.6, D - 3.4, true)
	_bx("in_marbre_noir", W - 1.03, W - 0.42, 0.85, 0.88, D - 4.63, D - 3.37)
	for i14 in range(4):
		b.cyl_at(["verre_fume", "rouge_laque", "verre", "verre_fume"][i14], _p(W - 0.7, 0.88, D - 4.4 + i14 * 0.22), 0.04, 0.045, 0.2 + (i14 % 2) * 0.06, 8)
		b.cyl_at("in_inox", _p(W - 0.7, 1.08 + (i14 % 2) * 0.06, D - 4.4 + i14 * 0.22), 0.015, 0.015, 0.05, 6)
	for i15 in range(3):
		b.cyl_at("verre", _p(W - 0.88, 0.88, D - 3.85 + i15 * 0.12), 0.03, 0.025, 0.07, 8)
	b.cyl_at("in_marbre_noir", _p(sx0, 0.0, D - 2.2), 0.35, 0.35, 0.4, 14)
	_bx("in_pot", sx0 - 0.16, sx0 + 0.16, 0.4, 0.47, D - 2.31, D - 2.09)
	b.tube("ecorce", _p(sx0, 0.46, D - 2.2), _p(sx0 + 0.07, 0.6, D - 2.17), 0.022, 6)
	b.tube("ecorce", _p(sx0 + 0.07, 0.6, D - 2.17), _p(sx0 - 0.04, 0.72, D - 2.2), 0.016, 6)
	_vegetal(Flora.bush(1897), _p(sx0 - 0.03, 0.62, D - 2.2), Vector3(0.24, 0.2, 0.24), 0.3)
	return ""


# =================================================================== ce qui sert à plusieurs étages

## Une image de la matière « key » sur un panneau (à l'endroit) : « rep » la répète.
func _quad(key: String, at: Vector3, face: Vector3, w: float, h: float, rep: Vector2 = Vector2.ONE) -> void:
	var dr: Vector3 = Vector3.UP.cross(face)
	b.quad(key, [at - dr * w * 0.5 + Vector3.UP * h * 0.5, at + dr * w * 0.5 + Vector3.UP * h * 0.5, at + dr * w * 0.5 - Vector3.UP * h * 0.5, at - dr * w * 0.5 - Vector3.UP * h * 0.5],
		face, [Vector2(0, 0), Vector2(rep.x, 0), Vector2(rep.x, rep.y), Vector2(0, rep.y)])


func _texte(txt: String, taille: int, couleur: Color, at: Vector3, face: Vector3) -> Label3D:
	var lab: Label3D = T._label(txt, taille, couleur)
	lab.global_position = at
	lab.look_at(at - face, Vector3.UP)
	return lab


## Un distributeur de boissons : la caisse, la vitrine et ses rangées de canettes, le clavier, la trappe.
func _distributeur(lx: float, lz: float, face: Vector3, couleur: String) -> void:
	var o: Vector3 = _p(lx, 0.0, lz)
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	_pc(couleur, o, bs, Vector3(0, 0.95, -0.05), Vector3(1.05, 1.9, 0.7))
	_pc("peinture_blanche", o, bs, Vector3(-0.14, 1.2, 0.31), Vector3(0.7, 1.2, 0.02))
	_pc("lampe_blanche", o, bs, Vector3(-0.14, 1.77, 0.37), Vector3(0.66, 0.03, 0.08))
	var teintes: Array = ["plastique_rouge", "plastique_bleu", "tissu_vert", "tissu_jaune", "k187_orange", "peinture_blanche"]
	for r in range(4):
		_pc("in_inox", o, bs, Vector3(-0.14, 0.68 + r * 0.28, 0.37), Vector3(0.68, 0.015, 0.1))
		for c in range(6):
			b.cyl_at(teintes[(r * 2 + c) % teintes.size()], o + bs * Vector3(-0.14 + (c - 2.5) * 0.105, 0.69 + r * 0.28, 0.37), 0.035, 0.035, 0.13, 8)
	for cd in [[-0.5, 1.2, 0.03, 1.24], [0.22, 1.2, 0.03, 1.24], [-0.14, 1.81, 0.75, 0.03], [-0.14, 0.59, 0.75, 0.03]]:
		_pc("in_noir", o, bs, Vector3(cd[0], cd[1], 0.37), Vector3(cd[2], cd[3], 0.12))
	_pc("in_noir", o, bs, Vector3(0.36, 1.25, 0.305), Vector3(0.18, 0.5, 0.02))
	_pc("in_ecran_vert", o, bs, Vector3(0.36, 1.4, 0.317), Vector3(0.13, 0.07, 0.005))
	for r2 in range(4):
		for c2 in range(3):
			_pc("in_inox", o, bs, Vector3(0.32 + c2 * 0.04, 1.28 - r2 * 0.045, 0.317), Vector3(0.028, 0.03, 0.008))
	_pc("in_noir", o, bs, Vector3(-0.14, 0.33, 0.305), Vector3(0.6, 0.2, 0.03))
	T._col(o + Vector3.UP * 1.0, Vector3(1.05, 2.0, 0.8), atan2(face.x, face.z))


## Un bol de nouilles (le bol, le bouillon, deux baguettes posées dessus).
func _bol(lot: Kit.Batch, at: Vector3) -> void:
	lot.cyl("peinture_blanche", Transform3D(Basis(), at + Vector3.UP * 0.045), 0.07, 0.11, 0.09, 10)
	lot.cyl("k187_orange", Transform3D(Basis(), at + Vector3.UP * 0.088), 0.1, 0.1, 0.012, 10)
	lot.tube("in_bois", at + Vector3(-0.1, 0.1, -0.05), at + Vector3(0.12, 0.1, 0.03), 0.005, 4)
	lot.tube("in_bois", at + Vector3(-0.1, 0.1, -0.02), at + Vector3(0.12, 0.1, 0.055), 0.005, 4)


## Une table ronde et ses chaises.
func _table_ronde(lx: float, lz: float, n: int, bols: int = 0) -> void:
	b.cyl_at("in_noir", _p(lx, 0.0, lz), 0.28, 0.28, 0.025, 14)
	b.cyl_at("in_noir", _p(lx, 0.0, lz), 0.035, 0.035, 0.72, 8)
	b.cyl_at("in_bois_clair", _p(lx, 0.72, lz), 0.55, 0.55, 0.04, 20)
	T._col(_p(lx, 0.4, lz), Vector3(1.0, 0.8, 1.0))
	var a0: float = rng.randf() * TAU
	for i in range(n):
		var a: float = a0 + i * TAU / n
		T._chaise(b, _p(lx + cos(a) * 0.95, 0.0, lz + sin(a) * 0.95), Vector3(-cos(a), 0, -sin(a)))
		if i < bols:
			_bol(b, _p(lx + cos(a) * 0.33, 0.76, lz + sin(a) * 0.33))


## Les gaines de ventilation, sous le plafond (deux, de part et d'autre du cœur).
func _gaines(cx0: float, cx1: float) -> void:
	for gx in [cx0 - 2.3, cx1 + 2.3]:
		_bx("in_inox", gx - 0.3, gx + 0.3, hc - 0.52, hc - 0.14, 0.5, D - 0.5)
		var gz: float = 1.2
		while gz < D - 0.8:
			_bx("metal_noir", gx - 0.33, gx + 0.33, hc - 0.55, hc - 0.11, gz - 0.04, gz + 0.04)
			_bx("metal_noir", gx - 0.01, gx + 0.01, hc - 0.14, hc, gz - 0.01, gz + 0.01)
			gz += 2.4
		for bz2 in [4.0, D - 4.0]:
			_bx("metal_noir", gx - 0.2, gx + 0.2, hc - 0.6, hc - 0.52, bz2 - 0.3, bz2 + 0.3)


## Un drone de plus, qui a sa vie à lui (il tourne, il flotte) : son nœud.
func _drone_vivant(at: Vector3, s: float, colis: bool) -> MeshInstance3D:
	var lot := Kit.Batch.new()
	_drone(lot, Vector3.ZERO, 0.0, colis, s)
	var mi := MeshInstance3D.new()
	mi.mesh = _maillage(lot)
	_anime().add_child(mi)
	mi.global_position = at
	return mi


# ------------------------------------------------------------------ le 1er : l'agence Kumo Express
func _agence() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var mx: float = W * 0.5
	# le chemin orange : de l'ascenseur aux guichets
	_bx("k187_orange", mx - 0.8, mx + 0.8, 0.0, 0.006, 3.4, cz0)
	_bx("k187_orange", mx - 0.8, W - 6.8, 0.0, 0.006, 3.4, 5.0)
	# ---- les guichets (à l'est) : le long comptoir, ses trois postes, leurs numéros, les colis en attente
	var gx: float = W - 3.3
	_bx("in_bois_clair", gx, gx + 0.8, 0.0, 1.05, 1.5, 7.0, true)
	_bx("in_marbre_blanc", gx - 0.08, gx + 0.88, 1.05, 1.09, 1.42, 7.08)
	_bx("k187_orange", gx - 0.012, gx, 0.42, 0.52, 1.5, 7.0)
	_image("kumo_express.png", _p(gx - 0.02, 0.78, 4.25), Vector3(-1, 0, 0), Vector2(2.4, 0.3), 1.3)
	for i in range(3):
		var pz: float = 2.4 + i * 1.85
		b.box("in_noir", Transform3D(Basis(Vector3.UP, 0.0), _p(gx + 0.62, 1.3, pz)), Vector3(0.03, 0.34, 0.5))
		_bx("in_ecran_ui_messages", gx + 0.636, gx + 0.64, 1.15, 1.45, pz - 0.23, pz + 0.23)
		_bx("in_noir", gx + 0.58, gx + 0.66, 1.09, 1.14, pz - 0.05, pz + 0.05)
		_bx("in_inox", gx + 0.05, gx + 0.35, 1.09, 1.12, pz - 0.5, pz - 0.2)                # (la balance)
		_bx("in_ecran_vert", gx + 0.36, gx + 0.38, 1.1, 1.18, pz - 0.45, pz - 0.25)
		if i < 2:
			_bx("in_vitre", gx + 0.1, gx + 0.7, 1.09, 1.75, pz + 0.915, pz + 0.935)
		# le numéro du guichet, suspendu
		_bx("in_noir", gx - 0.02, gx + 0.04, 2.0, 2.3, pz - 0.28, pz + 0.28)
		for cb in [-0.2, 0.2]:
			_bx("in_noir", gx, gx + 0.012, 2.3, hc, pz + cb - 0.006, pz + cb + 0.006)
		_texte(str(i + 1), 56, Color(1.0, 0.6, 0.15), _p(gx - 0.03, 2.15, pz), Vector3(-1, 0, 0))
		_gens("femme" if i != 1 else "homme", gx + 1.45, pz, Vector3(-1, 0, 0), "comptoir", L_AGENCE, i == 2, i == 0)
		if i != 1:
			_colis(gx + 0.3, 1.09, pz + 0.25, 0.3)
	# les colis en attente, sous les fenêtres
	_bx("in_bois_clair", W - 0.95, W - 0.4, 0.0, 0.9, 1.4, 7.1, true)
	for i2 in range(8):
		_colis(W - 0.68, 0.9, 1.75 + i2 * 0.68, rng.randf_range(0.3, 0.46))
	# la file : les potelets, leurs rubans
	for fx in [gx - 1.5, gx - 2.9]:
		var z0: float = 2.0
		while z0 < 6.6:
			b.cyl_at("in_inox", _p(fx, 0.0, z0), 0.14, 0.14, 0.02, 12)
			b.cyl_at("in_inox", _p(fx, 0.0, z0), 0.02, 0.02, 0.95, 8)
			b.blob("in_inox", _p(fx, 0.97, z0), Vector3(0.035, 0.035, 0.035), 6)
			if z0 + 1.5 < 6.6:
				b.tube("in_tissu_rouge", _p(fx, 0.9, z0), _p(fx, 0.9, z0 + 1.5), 0.02, 4)
			z0 += 1.5
	_gens("homme", gx - 0.75, 2.4, Vector3(1, 0, 0), "debout", L_CLIENT, false, true)
	_gens("femme", gx - 2.2, 4.3, Vector3(0, 0, -1), "debout", L_CLIENT)
	_gens("homme", gx - 2.2, 5.6, Vector3(0, 0, -1), "bras_croises", L_CLIENT)
	# ---- les casiers à colis (au nord-ouest) : un îlot à deux faces, un mur ; la borne
	_bx("in_noir", 1.2, 6.2, 0.0, 2.1, 1.9, 2.7, true)
	_quad("k187_casiers", _p(3.7, 1.05, 1.89), Vector3(0, 0, -1), 5.0, 2.1, Vector2(2.5, 1))
	_quad("k187_casiers", _p(3.7, 1.05, 2.71), Vector3(0, 0, 1), 5.0, 2.1, Vector2(2.5, 1))
	_bx("k187_orange", 1.15, 6.25, 2.1, 2.16, 1.85, 2.75)
	_bx("in_noir", 0.3, 0.75, 0.0, 2.1, 4.6, 7.2, true)
	_quad("k187_casiers", _p(0.76, 1.05, 5.9), Vector3(1, 0, 0), 2.6, 2.1, Vector2(1.3, 1))
	_bx("k187_orange", 0.3, 0.8, 2.1, 2.16, 4.55, 7.25)
	_bx("in_noir", 6.7, 7.0, 0.0, 1.15, 4.1, 4.6, true)
	b.box("in_noir", Transform3D(Basis(Vector3(0, 0, 1), 0.5), _p(6.82, 1.25, 4.35)), Vector3(0.05, 0.36, 0.46))
	b.box("in_ecran_ui_messages", Transform3D(Basis(Vector3(0, 0, 1), 0.5), _p(6.795, 1.262, 4.35)), Vector3(0.005, 0.3, 0.4))
	_bx("neon_cyan", 6.69, 6.7, 0.2, 0.9, 4.3, 4.4)
	_gens("femme", 2.6, 3.55, Vector3(0, 0, -1), "debout", L_CLIENT)
	_colis(3.3, 0.0, 3.2, 0.45)
	# ---- le drone d'exposition (à l'ouest) : son socle, son anneau, le panneau du slogan
	b.cyl_at("in_marbre_noir", _p(3.2, 0.0, 10.1), 0.75, 0.75, 0.45, 24)
	b.cyl_at("neon_cyan", _p(3.2, 0.45, 10.1), 0.6, 0.6, 0.012, 24)
	T._col(_p(3.2, 0.5, 10.1), Vector3(1.5, 1.0, 1.5))
	var expo: MeshInstance3D = _drone_vivant(_p(3.2, 1.35, 10.1), 1.9, true)
	_anime().tourne.append([expo, 0.4])
	_anime().flotte.append([expo, _p(3.2, 1.35, 10.1), 0.07, 1.1, 0.0])
	_bx("in_noir", 0.5, 0.62, 0.0, 2.6, 8.7, 11.5, true)
	_image("kumo_enseigne.png", _p(0.64, 2.05, 10.1), Vector3(1, 0, 0), Vector2(2.4, 0.6), 1.6)
	_texte("Vingt minutes, vent compris.", 44, Color(0.85, 0.95, 1.0), _p(0.64, 1.4, 10.1), Vector3(1, 0, 0))
	_texte("K-9, le nouveau : il porte un piano. On a essayé.", 22, Color(1.0, 0.7, 0.3), _p(0.64, 1.0, 10.1), Vector3(1, 0, 0))
	# ---- « suivez votre colis » : la carte des vols, sur le cœur (à l'est)
	var cm: float = (cz0 + cz1) * 0.5
	_bx("in_noir", cx1, cx1 + 0.06, 1.05, 2.55, cm - 2.1, cm + 2.1)
	var carte := ShaderMaterial.new()
	carte.shader = load("res://shaders/carte_v188.gdshader")
	if ResourceLoader.exists(TEX + "carte_vols.png"):
		carte.set_shader_parameter("image", load(TEX + "carte_vols.png"))
	var qc := QuadMesh.new()
	qc.size = Vector2(4.0, 1.5)
	var ec := MeshInstance3D.new()
	ec.mesh = qc
	ec.material_override = carte
	(T.get("_node") as Node3D).add_child(ec)
	ec.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), _p(cx1 + 0.07, 1.8, cm))
	_texte("Suivez votre colis", 36, Color(1.0, 0.6, 0.15), _p(cx1 + 0.07, 2.72, cm), Vector3(1, 0, 0))
	# ---- le salon d'attente (au sud-est)
	_bx("in_tissu_gris", W - 6.2, W - 0.7, 0.0, 0.012, D - 5.6, D - 0.6)
	_canape(W - 3.4, D - 1.05, Vector3(0, 0, -1), 2.6, "in_tissu_rouge")
	_canape(W - 1.1, D - 3.6, Vector3(-1, 0, 0), 2.0, "in_tissu_rouge")
	_canape(W - 5.6, D - 3.6, Vector3(1, 0, 0), 1.0, "in_tissu_rouge")
	_bx("in_bois_clair", W - 4.1, W - 2.7, 0.34, 0.38, D - 3.9, D - 3.2, true)
	for q in [[W - 4.0, D - 3.8], [W - 2.8, D - 3.8], [W - 4.0, D - 3.3], [W - 2.8, D - 3.3]]:
		b.cyl_at("in_noir", _p(q[0], 0.0, q[1]), 0.015, 0.015, 0.34, 6)
	for i3 in range(3):
		_bx(["peinture_blanche", "k187_orange", "plastique_bleu"][i3], W - 3.9 + i3 * 0.3, W - 3.68 + i3 * 0.3, 0.38 + i3 * 0.001, 0.39 + i3 * 0.004, D - 3.75, D - 3.45)
	_plante_pot(W - 0.9, D - 0.9, 1.3)
	_plante_pot(W - 6.0, D - 0.9, 1.2, true)
	_distributeur(W - 7.4, D - 0.72, Vector3(0, 0, -1), "plastique_bleu")
	_gens("femme", W - 4.0, D - 0.98, Vector3(0, 0, -1), "assis", L_CLIENT)
	_gens("homme", W - 1.03, D - 3.3, Vector3(-1, 0, 0), "assis", L_CLIENT)
	# ---- l'emballage (au sud-ouest) : la table, le papier, le ruban, la balance ; les cartons à plat
	_bx("in_bois_clair", 2.2, 4.8, 0.86, 0.9, D - 4.6, D - 3.7, true)
	for q2 in [[2.3, D - 4.5], [4.7, D - 4.5], [2.3, D - 3.8], [4.7, D - 3.8]]:
		b.cyl_at("in_inox", _p(q2[0], 0.0, q2[1]), 0.025, 0.025, 0.86, 6)
	b.cyl("in_bois_clair", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(2.9, 1.0, D - 3.95)), 0.1, 0.1, 0.9, 12)
	b.cyl("in_noir", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(2.9, 1.0, D - 3.95)), 0.02, 0.02, 1.1, 6)
	for sx in [2.38, 3.42]:
		_bx("in_inox", sx - 0.015, sx + 0.015, 0.9, 1.02, D - 3.99, D - 3.91)
	_bx("in_bois_clair", 2.5, 3.3, 0.9, 0.903, D - 4.5, D - 3.95)
	for i4 in range(3):
		b.cyl("k187_orange" if i4 != 1 else "peinture_blanche", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(3.8 + i4 * 0.16, 0.96, D - 3.85)), 0.06, 0.06, 0.04, 12)
	_bx("in_inox", 4.2, 4.6, 0.9, 0.94, D - 4.45, D - 4.05)
	_bx("in_ecran_vert", 4.3, 4.5, 0.94, 1.0, D - 4.07, D - 4.05)
	_colis(4.4, 0.94, D - 4.25, 0.3)
	for niv in range(4):
		_bx("in_bois_clair", 1.0, 5.8, 0.3 + niv * 0.5, 0.33 + niv * 0.5, D - 0.95, D - 0.4)
		for qx in range(5):
			if niv == 0 or rng.randf() < 0.75:
				if (qx + niv) % 3 == 0:                      # (des cartons à plat, en pile)
					_bx("k187_carton", 1.15 + qx * 0.95, 1.85 + qx * 0.95, 0.33 + niv * 0.5, 0.33 + niv * 0.5 + rng.randf_range(0.06, 0.2), D - 0.9, D - 0.45)
				else:
					_colis(1.5 + qx * 0.95, 0.33 + niv * 0.5, D - 0.68, rng.randf_range(0.28, 0.4))
	for px in [1.0, 2.6, 4.2, 5.8]:
		_bx("in_inox", px - 0.02, px + 0.02, 0.0, 2.1, D - 0.97, D - 0.93)
	T._col(_p(3.4, 1.0, D - 0.68), Vector3(4.9, 2.1, 0.6))
	_gens("homme", 3.5, D - 5.0, Vector3(0, 0, 1), "debout", L_EMBALLAGE, false, true)
	# ---- sous le plafond : quatre petits drones font le tour de l'agence, un colis sous le ventre
	var ronde := Node3D.new()
	_anime().add_child(ronde)
	ronde.global_position = _p(mx, 2.6, D * 0.5)
	for i5 in range(4):
		var a: float = i5 * TAU / 4.0 + 0.4
		var lotd := Kit.Batch.new()
		_drone(lotd, Vector3.ZERO, 0.0, true, 0.9)
		var dm := MeshInstance3D.new()
		dm.mesh = _maillage(lotd)
		ronde.add_child(dm)
		dm.transform = Transform3D(Basis(Vector3.UP, PI * 0.5 - a), Vector3(cos(a) * 5.4, 0.08 * (i5 % 2), sin(a) * 5.4))
	_anime().tourne.append([ronde, 0.22])
	return "bip"


# ------------------------------------------------------------------ le 2e : la cantine « Au Bol volant »
func _cantine() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var mx: float = W * 0.5
	# ---- la cuisine ouverte (à l'ouest) : le plan de cuisson, ses marmites, la hotte, l'étagère des bols
	_bx("k187_clair", 0.4, 1.1, 0.0, 0.88, 3.0, 17.0, true)
	_bx("in_inox", 0.38, 1.14, 0.88, 0.92, 2.96, 17.04)
	_bx("k187_clair", 0.4, 1.4, 2.25, 2.7, 4.6, 15.4)
	_bx("in_inox", 0.4, 1.42, 2.2, 2.25, 4.58, 15.42)
	_bx("lampe_chaude", 0.6, 1.2, 2.19, 2.2, 5.0, 15.0)
	for i in range(4):
		var mz: float = 5.6 + i * 2.9
		_bx("in_noir", 0.5, 1.0, 0.92, 0.94, mz - 0.3, mz + 0.3)
		b.cyl_at("in_inox", _p(0.75, 0.94, mz), 0.2, 0.22, 0.3, 14)
		b.cyl_at("k187_orange" if i % 2 == 0 else "lampe_chaude", _p(0.75, 1.2, mz), 0.2, 0.2, 0.02, 14)
		b.tube("in_inox", _p(0.75, 1.24, mz), _p(0.95, 1.5, mz + 0.2), 0.012, 5)                # (la louche)
	_bx("in_bois", 0.42, 0.72, 1.5, 1.53, 3.2, 4.4)
	for i3 in range(6):
		b.cyl_at("peinture_blanche", _p(0.57, 1.53, 3.35 + i3 * 0.18), 0.05, 0.08, 0.06 + (i3 % 2) * 0.06, 8)
	for i4 in range(5):
		b.cyl_at(["rouge_laque", "in_inox", "tissu_vert", "verre_fume", "peinture_jaune"][i4], _p(0.6, 0.92, 15.6 + i4 * 0.25), 0.05, 0.05, 0.18 + (i4 % 2) * 0.06, 8)
	# ---- le comptoir (les tabourets, le rail où passent les bols), ses lanternes rouges
	_bx("in_bois", 2.3, 2.9, 0.0, 0.86, 3.0, 17.0, true)
	_bx("in_bois_clair", 2.2, 3.15, 0.86, 0.9, 2.9, 17.1)
	_bx("plastique_noir", 2.24, 2.52, 0.9, 0.915, 3.0, 17.0)
	for sg in [2.23, 2.53]:
		_bx("k187_orange", sg - 0.01, sg + 0.01, 0.9, 0.93, 3.0, 17.0)
	var lotb := Kit.Batch.new()
	_bol(lotb, Vector3.ZERO)
	var mb: ArrayMesh = _maillage(lotb)
	for i5 in range(9):
		var mi := MeshInstance3D.new()
		mi.mesh = mb
		_anime().add_child(mi)
		_anime().tapis.append([mi, _p(2.38, 0.915, 3.2), Vector3(0, 0, 1), 13.6, float(i5) / 9.0 + rng.randf_range(-0.02, 0.02), 0.28])
	var n_a: int = 0
	for i6 in range(8):
		var tz: float = 4.9 + i6 * 1.6
		b.cyl_at("in_inox", _p(3.55, 0.0, tz), 0.16, 0.16, 0.015, 12)
		b.cyl_at("in_inox", _p(3.55, 0.0, tz), 0.025, 0.025, 0.46, 6)
		b.cyl_at("rouge_laque", _p(3.55, 0.46, tz), 0.17, 0.17, 0.05, 14)
		b.cyl_at("in_noir", _p(2.6, 2.3, tz), 0.004, 0.004, hc - 2.3, 4)
		b.cyl_at("in_noir", _p(2.6, 2.27, tz), 0.06, 0.06, 0.03, 8)
		b.cyl_at("rouge_laque", _p(2.6, 1.97, tz), 0.13, 0.15, 0.3, 12)
		b.cyl_at("lampe_chaude", _p(2.6, 1.95, tz), 0.11, 0.11, 0.02, 12)
		if i6 in [0, 2, 3, 5, 6]:
			_bol(b, _p(2.88, 0.9, tz))
			_gens("homme" if n_a % 2 == 0 else "femme", 3.55, tz, Vector3(-1, 0, 0), "assis", L_CANTINE, false, n_a == 0)
			n_a += 1
	_gens("homme", 1.7, 7.4, Vector3(1, 0, 0), "comptoir", L_CHEF_BOL, false, true)
	_gens("homme", 1.7, 12.8, Vector3(1, 0, 0), "comptoir", L_CUISTOT, true, true)
	# ---- la carte, sur le cœur (face au comptoir)
	var cm: float = (cz0 + cz1) * 0.5
	_bx("in_noir", cx0 - 0.06, cx0, 0.9, 2.75, cz0 + 0.3, cz1 - 0.3)
	_bx("rouge_laque", cx0 - 0.08, cx0 - 0.06, 2.68, 2.75, cz0 + 0.3, cz1 - 0.3)
	_texte("AU BOL VOLANT", 60, Color(1.0, 0.55, 0.15), _p(cx0 - 0.08, 2.42, cm), Vector3(-1, 0, 0))
	var plats: Array = ["Le bol du premier jour", "Ramen des Hauts, œuf mollet", "Nouilles sautées « vent de nord-ouest »", "Bouillon du pigeon (sans pigeon)", "Raviolis vapeur du Dépôt 01", "Thé au jasmin — la maison offre"]
	for i7 in range(plats.size()):
		_texte(str(plats[i7]), 26, Color(0.95, 0.92, 0.85), _p(cx0 - 0.08, 2.05 - i7 * 0.19, cm), Vector3(-1, 0, 0))
	# ---- les alcôves (à l'est, contre les fenêtres) : deux banquettes rouges, une table, un bol ou deux
	var n_b: int = 0
	for zc in [3.2, 6.6, 10.1, 13.6, 17.0]:
		_bx("in_bois_clair", W - 2.15, W - 0.75, 0.7, 0.74, zc - 0.36, zc + 0.36, true)
		_bx("in_noir", W - 1.5, W - 1.4, 0.0, 0.7, zc - 0.05, zc + 0.05)
		_canape(W - 1.45, zc - 0.98, Vector3(0, 0, 1), 1.5, "in_tissu_rouge")
		_canape(W - 1.45, zc + 0.98, Vector3(0, 0, -1), 1.5, "in_tissu_rouge")
		_bx("in_bois", W - 2.3, W - 2.2, 0.0, 1.25, zc - 1.45, zc - 1.38)
		b.cyl_at("lampe_chaude", _p(W - 0.9, 0.74, zc), 0.05, 0.035, 0.12, 8)
		if n_b != 2:
			_bol(b, _p(W - 1.6, 0.74, zc - 0.18))
			_gens("femme" if n_b % 2 == 0 else "homme", W - 1.6, zc - 0.9, Vector3(0, 0, 1), "assis", L_CANTINE)
			if n_b == 1:
				_bol(b, _p(W - 1.5, 0.74, zc + 0.18))
				_gens("femme", W - 1.5, zc + 0.9, Vector3(0, 0, -1), "assis", L_CANTINE)
		n_b += 1
	# ---- les tables rondes (au nord et au sud), la tablette face à la mer
	_table_ronde(6.0, 2.9, 3, 2)
	_table_ronde(14.2, 2.7, 4, 1)
	_table_ronde(6.2, D - 3.0, 4, 2)
	_table_ronde(12.6, D - 2.6, 3, 0)
	_gens("femme", 5.0, 2.0, Vector3(0, 0, -1), "debout", L_CANTINE)
	# le drone qui apporte le thé : il attend au-dessus de la table, la théière sous le ventre
	var the: MeshInstance3D = _drone_vivant(_p(14.2, 1.75, 2.7), 1.0, false)
	_anime().flotte.append([the, _p(14.2, 1.75, 2.7), 0.1, 1.3, 0.0])
	_anime().tourne.append([the, 0.3])
	# ---- le coin des plateaux (au sud-ouest) : le distributeur, la desserte, les plantes
	_distributeur(1.0, D - 0.72, Vector3(0, 0, -1), "plastique_bleu")
	_bx("in_inox", 2.2, 3.4, 0.0, 1.5, D - 0.9, D - 0.4, true)
	for i8 in range(4):
		_bx("in_bois_clair", 2.25, 3.35, 0.3 + i8 * 0.32, 0.32 + i8 * 0.32, D - 0.92, D - 0.42)
	_plante_pot(0.9, 1.0, 1.4)
	_plante_pot(W - 0.9, D - 0.75, 1.2, true)
	_plante_pot(mx + 2.0, D - 0.8, 1.3)
	return ""


# ------------------------------------------------------------------ le 4e : la clinique des drones
func _clinique() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	_bx("in_sol_technique", 0.0, W, 0.0, 0.012, 0.0, cz0)
	_bx("in_sol_technique", 0.0, W, 0.0, 0.012, cz1, D)
	_bx("in_sol_technique", 0.0, cx0, 0.0, 0.012, cz0, cz1)
	_bx("in_sol_technique", cx1, W, 0.0, 0.012, cz0, cz1)
	_gaines(cx0, cx1)
	# l'enseigne de la clinique, sur le cœur (côté ouest)
	_bx("in_noir", cx0 - 0.05, cx0, 1.7, 2.7, cz0 + 0.3, cz1 - 0.3)
	_texte("LA CLINIQUE DES DRONES", 46, Color(0.4, 0.95, 1.0), _p(cx0 - 0.07, 2.35, cm), Vector3(-1, 0, 0))
	_texte("Ici, on répare tout. Même l'orgueil.", 24, Color(1.0, 0.7, 0.3), _p(cx0 - 0.07, 2.0, cm), Vector3(-1, 0, 0))
	# ---- les établis (au nord, sous les fenêtres) : quatre postes, leurs mécanos
	var n_e: int = 0
	for ex in [2.3, 5.4, W - 5.4, W - 2.3]:
		_etabli(ex, 1.25, n_e)
		if n_e != 2:
			_gens("homme" if n_e % 2 == 0 else "femme", ex, 2.25, Vector3(0, 0, -1), "comptoir", L_MECANO, false, n_e == 0)
		n_e += 1
	# ---- les lits de convalescence (à l'ouest) : trois drones au repos, leur moniteur, leur perfusion
	var maux: Array = ["K-0733 — a rencontré un pigeon", "K-1204 — a livré un piano", "K-0058 — a pris la pluie"]
	for i in range(3):
		var lz: float = cz0 + 0.6 + i * 2.0
		for q in [[0.8, lz - 0.28], [2.0, lz - 0.28], [0.8, lz + 0.28], [2.0, lz + 0.28]]:
			b.cyl_at("in_inox", _p(q[0], 0.06, q[1]), 0.015, 0.015, 0.7, 6)
			b.cyl("plastique_noir", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(q[0], 0.04, q[1])), 0.04, 0.04, 0.03, 8)
		_bx("in_inox", 0.75, 2.05, 0.74, 0.78, lz - 0.33, lz + 0.33, true)
		_bx("peinture_blanche", 0.78, 2.02, 0.78, 0.88, lz - 0.3, lz + 0.3)
		_bx("peinture_blanche", 0.8, 1.1, 0.88, 0.94, lz - 0.2, lz + 0.2)                 # (l'oreiller)
		_drone(b, _p(1.35, 1.02, lz), 0.0, false, 1.0)
		_bx("plastique_bleu", 1.45, 2.03, 0.88, 0.9, lz - 0.31, lz + 0.31)                # (la couverture)
		_bx("plastique_bleu", 1.45, 2.03, 0.9, 1.0, lz - 0.2, lz + 0.2)
		if i == 0:
			_bx("peinture_blanche", 0.95, 1.05, 0.98, 1.1, lz + 0.24, lz + 0.42)          # (le pansement, sur un bras)
		# la perfusion (de l'huile), le moniteur
		b.cyl_at("in_inox", _p(0.6, 0.0, lz + 0.55), 0.012, 0.012, 1.75, 6)
		b.cyl_at("in_inox", _p(0.6, 0.0, lz + 0.55), 0.14, 0.14, 0.015, 10)
		b.cyl_at("lampe_chaude", _p(0.6, 1.45, lz + 0.47), 0.05, 0.04, 0.2, 8)
		b.tube("verre", _p(0.6, 1.45, lz + 0.47), _p(1.0, 1.0, lz + 0.15), 0.006, 4)
		_bx("in_noir", 0.32, 0.38, 1.25, 1.6, lz - 0.25, lz + 0.25)
		_bx("in_ecran_vert", 0.38, 0.385, 1.28, 1.57, lz - 0.22, lz + 0.22)
		var lab: Label3D = _texte(str(maux[i]), 20, Color(0.95, 0.95, 1.0), _p(2.07, 0.6, lz), Vector3(1, 0, 0))
		lab.width = 280.0
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gens("femme", 3.0, cz0 + 1.6, Vector3(-1, 0, 0), "debout", L_CLINIQUE, false, true)
	# ---- la cage d'essai (à l'est) : les montants, le verre, le socle, le cerceau ; un drone y réapprend à voler
	var c0: float = cx1 + 1.5
	var c1: float = W - 0.9
	var k0: float = cz0 - 0.4
	var k1: float = cz1 + 0.4
	for q2 in [[c0, k0], [c1, k0], [c0, k1], [c1, k1]]:
		_bx("metal_noir", q2[0] - 0.05, q2[0] + 0.05, 0.0, hc - 0.2, q2[1] - 0.05, q2[1] + 0.05)
	for hh in [0.06, hc - 0.25]:
		_bx("metal_noir", c0, c1, hh - 0.05, hh + 0.05, k0 - 0.04, k0 + 0.04)
		_bx("metal_noir", c0, c1, hh - 0.05, hh + 0.05, k1 - 0.04, k1 + 0.04)
		_bx("metal_noir", c0 - 0.04, c0 + 0.04, hh - 0.05, hh + 0.05, k0, k1)
		_bx("metal_noir", c1 - 0.04, c1 + 0.04, hh - 0.05, hh + 0.05, k0, k1)
	_bx("in_cloison_verre", c0, c1, 0.1, hc - 0.3, k0 - 0.01, k0 + 0.01, true)
	_bx("in_cloison_verre", c0, c1, 0.1, hc - 0.3, k1 - 0.01, k1 + 0.01, true)
	_bx("in_cloison_verre", c1 - 0.01, c1 + 0.01, 0.1, hc - 0.3, k0, k1, true)
	_bx("in_cloison_verre", c0 - 0.01, c0 + 0.01, 0.1, hc - 0.3, k0, cm - 0.6, true)
	_bx("in_cloison_verre", c0 - 0.01, c0 + 0.01, 0.1, hc - 0.3, cm + 0.6, k1, true)
	_bx("k187_danger", c0 + 0.1, c1 - 0.1, 0.012, 0.018, k0 + 0.1, k0 + 0.3)
	_bx("k187_danger", c0 + 0.1, c1 - 0.1, 0.012, 0.018, k1 - 0.3, k1 - 0.1)
	var pcx: float = (c0 + c1) * 0.5
	b.cyl_at("metal_noir", _p(pcx, 0.012, cm), 0.8, 0.8, 0.08, 20)
	b.cyl_at("neon_cyan", _p(pcx, 0.092, cm), 0.7, 0.7, 0.012, 20)
	for a8 in range(10):                          # (le cerceau à traverser)
		var a0: float = a8 * TAU / 10.0
		var a1: float = (a8 + 1) * TAU / 10.0
		b.tube("k187_orange", _p(pcx + cos(a0) * 0.7, 1.7 + sin(a0) * 0.7, k0 + 1.3), _p(pcx + cos(a1) * 0.7, 1.7 + sin(a1) * 0.7, k0 + 1.3), 0.03, 6)
	b.cyl_at("metal_noir", _p(pcx, 0.0, k0 + 1.3), 0.03, 0.03, 1.0, 6)
	var eleve: MeshInstance3D = _drone_vivant(_p(pcx, 1.5, cm + 0.6), 1.4, false)
	_anime().flotte.append([eleve, _p(pcx, 1.5, cm + 0.6), 0.45, 0.9, 0.0])
	_anime().tourne.append([eleve, 0.8])
	# le pupitre de l'essai, devant la porte de la cage
	_bx("in_noir", c0 + 0.5, c0 + 1.4, 0.0, 1.0, k0 - 0.9, k0 - 0.4, true)
	b.box("in_ecran_ui_graphes", Transform3D(Basis(Vector3(1, 0, 0), -0.45), _p(c0 + 0.95, 1.08, k0 - 0.68)), Vector3(0.7, 0.01, 0.4))
	_gens("homme", c0 + 0.95, k0 - 1.5, Vector3(0, 0, 1), "bras_croises", L_MECANO, false, true)
	# ---- les socles de charge (au sud-est) : trois rangs de drones qui se refont une santé
	for niv in range(3):
		_bx("metal_noir", 11.4, W - 0.6, 0.45 + niv * 0.75, 0.49 + niv * 0.75, D - 1.0, D - 0.4)
		for i2 in range(6):
			var dx: float = 12.0 + i2 * (W - 13.2) / 5.0
			b.cyl_at("neon_cyan", _p(dx, 0.49 + niv * 0.75, D - 0.7), 0.2, 0.2, 0.01, 10)
			if (i2 + niv * 2) % 5 != 0:
				_drone(b, _p(dx, 0.67 + niv * 0.75, D - 0.7), 1.57, false, 0.72)
				_bx("in_led_verte" if (i2 + niv) % 3 != 0 else "in_led_ambre", dx - 0.05, dx + 0.05, 0.4 + niv * 0.75, 0.44 + niv * 0.75, D - 1.01, D - 1.0)
	for px in [11.4, 14.0, 16.6, W - 0.6]:
		_bx("metal_noir", px - 0.03, px + 0.03, 0.0, 2.2, D - 1.02, D - 0.96)
	T._col(_p((11.4 + W - 0.6) * 0.5, 1.1, D - 0.7), Vector3(W - 12.0, 2.2, 0.7))
	# ---- le magasin des pièces (au sud-ouest) : les rayonnages, les bacs d'hélices et de batteries
	for rz in [D - 5.2, D - 3.4, D - 1.6]:
		Q._rayonnage(T, b, _p(0.8, 0.0, rz), Vector3(1, 0, 0), 2.6, rng)
	var bacs: Array = ["plastique_bleu", "plastique_rouge", "tissu_jaune", "tissu_vert"]
	for i3 in range(4):
		var bx0: float = 3.4 + (i3 % 2) * 0.9
		var bz0: float = D - 3.6 + (i3 >> 1) * 0.9
		_bx(bacs[i3], bx0 - 0.38, bx0 + 0.38, 0.0, 0.55, bz0 - 0.38, bz0 + 0.38, true)
		_bx("in_noir", bx0 - 0.34, bx0 + 0.34, 0.5, 0.52, bz0 - 0.34, bz0 + 0.34)
		for j in range(5):
			if i3 < 2:
				b.cyl("verre_fume", Transform3D(Basis(Vector3(1, 0, 0), rng.randf_range(-0.5, 0.5)), _p(bx0 + rng.randf_range(-0.15, 0.15), 0.55 + j * 0.02, bz0 + rng.randf_range(-0.15, 0.15))), 0.2, 0.2, 0.01, 10)
			else:
				_bx("k187_orange" if j % 2 == 0 else "in_noir", bx0 - 0.3 + j * 0.12, bx0 - 0.2 + j * 0.12, 0.52, 0.66, bz0 - 0.12, bz0 + 0.12)
	_gens("femme", 5.4, D - 3.1, Vector3(-1, 0, 0), "debout", L_MECANO)
	# ---- le robot monteur (au sud) : son bras, sa table, un drone neuf
	Q._robot(T, b, _p(9.2, 0.0, D - 1.3), Vector3(0, 0, -1))
	_bx("in_inox", 8.4, 10.0, 0.8, 0.84, D - 3.0, D - 2.2, true)
	for q3 in [[8.45, D - 2.95], [9.95, D - 2.95], [8.45, D - 2.25], [9.95, D - 2.25]]:
		b.cyl_at("in_inox", _p(q3[0], 0.0, q3[1]), 0.02, 0.02, 0.8, 6)
	_drone(b, _p(9.2, 1.06, D - 2.6), 0.6, false, 1.2)
	for e in [[7.9, 10.5, D - 3.5, D - 3.4], [7.9, 8.0, D - 3.5, D - 0.5], [10.4, 10.5, D - 3.5, D - 0.5]]:
		_bx("k187_danger", e[0], e[1], 0.012, 0.018, e[2], e[3])
	_distributeur(W - 0.75, 3.6, Vector3(-1, 0, 0), "k187_orange")
	return "bip"


# ------------------------------------------------------------------ le 5e : la mémoire (les serveurs)
func _memoire() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	if not Kit._mcache.has("k188_baie"):
		var bm := ShaderMaterial.new()
		bm.shader = load("res://shaders/baie_v188.gdshader")
		Kit._mcache["k188_baie"] = bm
	# la pénombre bleue
	for ch in (T.get("_node") as Node3D).get_children():
		if ch is OmniLight3D:
			(ch as OmniLight3D).light_energy *= 0.35
			(ch as OmniLight3D).light_color = Color(0.45, 0.65, 1.0)
	_bx("in_noir", 0.3, W - 0.3, hc - 0.09, hc - 0.07, 0.3, D - 0.3)
	# ---- les rangées de baies (au nord et au sud) : entre deux rangées, l'allée froide et son trait de lumière
	for rz in [1.9, 5.0, D - 5.0, D - 1.9]:
		for seg in [[1.4, mx - 1.7], [mx + 1.7, W - 1.4]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			var n: float = floor((x1 - x0) / 0.62)
			x1 = x0 + n * 0.62
			_bx("in_rack", x0, x1, 0.0, 2.1, rz - 0.5, rz + 0.5, true)
			_quad("k188_baie", _p((x0 + x1) * 0.5, 1.05, rz - 0.505), Vector3(0, 0, -1), x1 - x0, 2.0, Vector2(n, 1))
			_quad("k188_baie", _p((x0 + x1) * 0.5, 1.05, rz + 0.505), Vector3(0, 0, 1), x1 - x0, 2.0, Vector2(n, 1))
			_bx("metal_noir", x0, x1, 2.1, 2.14, rz - 0.52, rz + 0.52)
			_bx("metal_noir", x0, x1, hc - 0.5, hc - 0.46, rz - 0.2, rz + 0.2)                  # (le chemin de câbles)
			for i in range(3):
				b.tube(["plastique_bleu", "k187_orange", "peinture_jaune"][i], _p(x0, hc - 0.44, rz - 0.1 + i * 0.1), _p(x1, hc - 0.44, rz - 0.1 + i * 0.1), 0.02, 5)
			var hx: float = x0 + 0.3
			while hx < x1:
				_bx("metal_noir", hx - 0.01, hx + 0.01, hc - 0.46, hc - 0.09, rz - 0.01, rz + 0.01)
				b.tube("plastique_bleu", _p(hx + 0.3, hc - 0.46, rz), _p(hx + 0.3, 2.14, rz + 0.3), 0.012, 4)
				hx += 1.86
	for az in [3.45, D - 3.45]:
		_bx("neon_cyan", 1.4, mx - 1.7, 0.0, 0.008, az - 0.03, az + 0.03)
		_bx("neon_cyan", mx + 1.7, W - 1.4, 0.0, 0.008, az - 0.03, az + 0.03)
		for lxx in [mx - 5.0, mx + 5.0]:
			var o := OmniLight3D.new()
			o.light_color = Color(0.3, 0.7, 1.0)
			o.light_energy = 0.9
			o.omni_range = 6.0
			(T.get("_node") as Node3D).add_child(o)
			o.global_position = _p(lxx, 1.2, az)
	# ---- la salle de contrôle (à l'ouest) : derrière sa vitre, deux veilleurs et la carte
	_bx("in_cloison_verre", 5.6, 5.64, 0.0, hc - 0.1, cz0 - 0.6, cm - 0.6, true)
	_bx("in_cloison_verre", 5.6, 5.64, 0.0, hc - 0.1, cm + 0.6, cz1 + 0.6, true)
	_bx("in_menuiserie", 5.56, 5.68, 0.0, hc - 0.1, cm - 0.66, cm - 0.6)
	_bx("in_menuiserie", 5.56, 5.68, 0.0, hc - 0.1, cm + 0.6, cm + 0.66)
	_bx("in_cloison_verre", 0.5, 5.6, 0.0, hc - 0.1, cz0 - 0.62, cz0 - 0.58, true)
	_bx("in_cloison_verre", 0.5, 5.6, 0.0, hc - 0.1, cz1 + 0.58, cz1 + 0.62, true)
	_bx("in_moquette_bleue", 0.5, 5.6, 0.0, 0.012, cz0 - 0.58, cz1 + 0.58)
	for i2 in range(2):
		var pz: float = cm - 1.4 + i2 * 2.8
		_bx("in_bureau", 1.0, 1.9, 0.72, 0.76, pz - 0.9, pz + 0.9, true)
		_bx("in_noir", 1.0, 1.06, 0.0, 0.72, pz - 0.9, pz + 0.9)
		for j in range(3):
			var xf := Transform3D(Basis(Vector3.UP, PI * 0.5 + (1 - j) * 0.35), _p(1.25 + absf(j - 1.0) * 0.1, 1.1, pz + (j - 1) * 0.6))
			b.box("in_noir", xf, Vector3(0.58, 0.4, 0.03))
			b.box(["in_ecran_ui_code", "in_ecran_ui_graphes", "in_ecran_vert"][j], xf * Transform3D(Basis(), Vector3(0, 0, 0.018)), Vector3(0.53, 0.35, 0.005))
		T._chaise(b, _p(2.5, 0.0, pz), Vector3(-1, 0, 0))
		_gens("femme" if i2 == 0 else "homme", 2.5, pz, Vector3(-1, 0, 0), "assis", L_MEMOIRE, false, i2 == 0)
	_plante_pot(5.0, cz1 + 0.1, 1.1, true)
	# ---- le Serveur n°1 (à l'est) : sur son socle, derrière son cordon, sous sa lumière
	var sx: float = (cx1 + W) * 0.5 + 0.4
	b.cyl_at("in_marbre_noir", _p(sx, 0.0, cm), 0.9, 0.9, 0.5, 24)
	b.cyl_at("lampe_chaude", _p(sx, 0.5, cm), 0.82, 0.82, 0.01, 24)
	_bx("peinture_blanche", sx - 0.55, sx - 0.2, 0.51, 0.98, cm - 0.25, cm + 0.2)            # (la tour beige)
	_bx("in_noir", sx - 0.56, sx - 0.555, 0.8, 0.9, cm - 0.2, cm + 0.15)
	_bx("in_led_verte", sx - 0.562, sx - 0.556, 0.62, 0.64, cm - 0.2, cm - 0.17)
	_bx("peinture_blanche", sx - 0.1, sx + 0.4, 0.51, 0.56, cm - 0.25, cm + 0.25)
	_bx("peinture_blanche", sx - 0.1, sx + 0.4, 0.56, 1.0, cm - 0.27, cm + 0.27)             # (l'écran à tube)
	_bx("in_ecran_vert", sx - 0.105, sx - 0.1, 0.62, 0.95, cm - 0.2, cm + 0.2)
	_bx("peinture_blanche", sx - 0.45, sx - 0.3, 0.51, 0.54, cm + 0.3, cm + 0.75)             # (le clavier)
	T._col(_p(sx, 0.6, cm), Vector3(1.8, 1.2, 1.8))
	var spot := OmniLight3D.new()
	spot.light_color = Color(1.0, 0.8, 0.5)
	spot.light_energy = 1.4
	spot.omni_range = 4.0
	(T.get("_node") as Node3D).add_child(spot)
	spot.global_position = _p(sx - 0.6, 2.3, cm)
	for a in range(6):
		var an: float = a * TAU / 6.0
		var an2: float = (a + 1) * TAU / 6.0
		b.cyl_at("in_inox", _p(sx + cos(an) * 1.6, 0.0, cm + sin(an) * 1.6), 0.12, 0.12, 0.02, 10)
		b.cyl_at("in_inox", _p(sx + cos(an) * 1.6, 0.0, cm + sin(an) * 1.6), 0.02, 0.02, 0.95, 8)
		if a != 2:
			b.tube("in_tissu_rouge", _p(sx + cos(an) * 1.6, 0.9, cm + sin(an) * 1.6), _p(sx + cos(an2) * 1.6, 0.9, cm + sin(an2) * 1.6), 0.02, 4)
	_texte("Serveur n°1 (2087)", 30, Color(1.0, 0.85, 0.55), _p(sx - 0.92, 0.3, cm), Vector3(-1, 0, 0))
	_texte("Ne pas débrancher. Sérieusement.", 18, Color(0.9, 0.9, 0.95), _p(sx - 0.92, 0.16, cm), Vector3(-1, 0, 0))
	# le froid : trois grosses conduites contre le mur de l'est, leurs vannes
	for i3 in range(3):
		var tz: float = cz0 + 0.4 + i3 * 0.7
		b.cyl_at("in_inox", _p(W - 0.7, 0.0, tz), 0.2, 0.2, hc - 0.1, 12)
		b.cyl_at("plastique_bleu", _p(W - 0.7, 1.2, tz), 0.22, 0.22, 0.12, 12)
		b.cyl("plastique_rouge", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(W - 0.98, 1.26, tz)), 0.12, 0.12, 0.03, 10)
		_bx("in_led_bleue", W - 0.91, W - 0.9, 1.6, 1.64, tz - 0.05, tz + 0.05)
	T._col(_p(W - 0.7, 1.5, cz0 + 1.1), Vector3(0.6, 3.0, 2.0))
	# ---- le technicien et son chariot de disques
	_bx("in_inox", mx + 3.0, mx + 3.8, 0.3, 0.33, 5.5, 6.0)
	_bx("in_inox", mx + 3.0, mx + 3.8, 0.85, 0.88, 5.5, 6.0, true)
	for q in [[mx + 3.03, 5.53], [mx + 3.77, 5.53], [mx + 3.03, 5.97], [mx + 3.77, 5.97]]:
		b.cyl_at("in_inox", _p(q[0], 0.05, q[1]), 0.012, 0.012, 0.83, 5)
		b.cyl("plastique_noir", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(q[0], 0.04, q[1])), 0.04, 0.04, 0.03, 8)
	for i4 in range(5):
		_bx("in_noir", mx + 3.08 + i4 * 0.14, mx + 3.18 + i4 * 0.14, 0.88, 0.91, 5.6, 5.9)
		_bx("in_led_verte", mx + 3.1 + i4 * 0.14, mx + 3.12 + i4 * 0.14, 0.895, 0.905, 5.595, 5.6)
	_gens("homme", mx + 3.4, 6.5, Vector3(0, 0, -1), "debout", L_MEMOIRE, false, true)
	_gens("femme", mx - 4.0, D - 3.4, Vector3(0, 0, -1), "bras_croises", L_MEMOIRE)
	return "bip"


# ------------------------------------------------------------------ le 6e : le standard
func _standard() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	# ---- les alvéoles (au nord, de part et d'autre de l'allée de l'ascenseur) : chacune sa couleur
	var teintes: Array = ["in_tissu_rouge", "plastique_bleu", "tissu_vert", "tissu_jaune", "k187_orange", "in_tissu_gris"]
	var n_a: int = 0
	for rg in range(2):
		for ax in [1.6, 3.6, 5.6, W - 5.6, W - 3.6, W - 1.6]:
			var az: float = 1.5 + rg * 3.4
			_alveole(ax, az, str(teintes[(n_a + rg) % teintes.size()]), n_a)
			if n_a % 4 != 3:
				_gens("femme" if n_a % 2 == 0 else "homme", ax, az + 0.75, Vector3(0, 0, -1), "assis", L_STANDARD, n_a == 5, n_a == 1)
			n_a += 1
	# ---- le grand tableau (sur le cœur, à l'ouest) : les compteurs du jour, la cloche
	_bx("in_noir", cx0 - 0.06, cx0, 0.9, 2.75, cz0 + 0.3, cz1 - 0.3)
	_bx("k187_orange", cx0 - 0.08, cx0 - 0.06, 2.68, 2.75, cz0 + 0.3, cz1 - 0.3)
	_texte("LE STANDARD", 52, Color(1.0, 0.6, 0.15), _p(cx0 - 0.08, 2.42, cm), Vector3(-1, 0, 0))
	var lignes: Array = [["Appels en attente", "3", Color(1.0, 0.75, 0.3)], ["Colis en promenade", "1", Color(1.0, 0.45, 0.4)], ["Colis retrouvés ce mois", "212", Color(0.5, 1.0, 0.6)],
		["Clients ravis aujourd'hui", "41 208", Color(0.5, 1.0, 0.6)], ["Pigeons signalés", "7", Color(0.6, 0.85, 1.0)]]
	for i in range(lignes.size()):
		_texte("%s : %s" % [str(lignes[i][0]), str(lignes[i][1])], 30, lignes[i][2], _p(cx0 - 0.08, 2.0 - i * 0.22, cm), Vector3(-1, 0, 0))
	b.tube("in_bois", _p(cx0, 1.5, cz1 - 0.12), _p(cx0 - 0.3, 1.5, cz1 - 0.12), 0.02, 6)
	b.cyl_at("in_noir", _p(cx0 - 0.27, 1.38, cz1 - 0.12), 0.005, 0.005, 0.12, 4)
	b.cyl_at("lampe_chaude", _p(cx0 - 0.27, 1.22, cz1 - 0.12), 0.1, 0.045, 0.16, 12)
	_texte("On sonne à chaque colis retrouvé.", 18, Color(0.95, 0.9, 0.8), _p(cx0 - 0.08, 1.0, cz1 - 1.3), Vector3(-1, 0, 0))
	_gens("femme", cx0 - 1.7, cm, Vector3(-1, 0, -0.4).normalized(), "bras_croises", L_CHEFFE_STANDARD, false, true)
	# ---- le mur des mercis (sur le cœur, à l'est) : des dizaines de petits papiers de couleur
	_bx("in_bois_clair", cx1, cx1 + 0.04, 0.8, 2.6, cz0 + 0.3, cz1 - 0.3)
	_texte("Le mur des mercis", 40, Color(1.0, 0.6, 0.15), _p(cx1 + 0.06, 2.78, cm), Vector3(1, 0, 0))
	var papiers: Array = ["tissu_jaune", "sakura", "peinture_blanche", "k187_orange", "tissu_vert", "plastique_bleu"]
	for i2 in range(70):
		var pz: float = rng.randf_range(cz0 + 0.45, cz1 - 0.45)
		var ph: float = rng.randf_range(0.9, 2.5)
		b.box(str(papiers[rng.randi() % papiers.size()]), Transform3D(Basis(Vector3(1, 0, 0), rng.randf_range(-0.2, 0.2)), _p(cx1 + 0.045 + (i2 % 3) * 0.002, ph, pz)), Vector3(0.004, 0.12, 0.12))
	var mercis: Array = ["Merci pour le piano !", "Les nouilles étaient chaudes.", "Le drone a attendu que je me réveille.", "Reçu en 19 minutes. Vent compris ?"]
	for i3 in range(mercis.size()):
		_texte(str(mercis[i3]), 14, Color(0.15, 0.15, 0.2), _p(cx1 + 0.06, 1.2 + i3 * 0.36, cz0 + 1.0 + (i3 % 2) * 2.2), Vector3(1, 0, 0))
	_canape(cx1 + 2.6, cm, Vector3(-1, 0, 0), 2.2, "in_tissu_gris")
	_gens("homme", cx1 + 2.5, cm - 0.4, Vector3(-1, 0, 0), "assis", L_STANDARD)
	# ---- la salle de réunion vitrée (au sud-ouest) : la table, six chaises, le tableau blanc
	var r0: float = D - 5.4
	_bx("in_cloison_verre", 0.5, 6.4, 0.0, hc - 0.1, r0 - 0.02, r0 + 0.02, true)
	_bx("in_cloison_verre", 6.4, 6.44, 0.0, hc - 0.1, r0, D - 2.9, true)
	_bx("in_cloison_verre", 6.4, 6.44, 0.0, hc - 0.1, D - 1.9, D - 0.4, true)
	_bx("in_menuiserie", 6.36, 6.48, 0.0, hc - 0.1, D - 2.96, D - 2.9)
	_bx("in_menuiserie", 6.36, 6.48, 0.0, hc - 0.1, D - 1.9, D - 1.84)
	_bx("in_bois", 2.0, 5.0, 0.72, 0.77, D - 3.4, D - 2.3, true)
	for sxx in [2.3, 4.7]:
		_bx("in_noir", sxx - 0.05, sxx + 0.05, 0.0, 0.72, D - 3.2, D - 2.5)
	for i4 in range(3):
		T._chaise(b, _p(2.5 + i4 * 1.0, 0.0, D - 4.0), Vector3(0, 0, 1))
		T._chaise(b, _p(2.5 + i4 * 1.0, 0.0, D - 1.7), Vector3(0, 0, -1))
	_bx("peinture_blanche", 0.52, 0.56, 1.0, 2.2, D - 4.6, D - 1.2)
	_bx("in_inox", 0.5, 0.58, 0.96, 1.0, D - 4.65, D - 1.15)
	_texte("Idée n° 1 : répondre au pigeon.", 20, Color(0.1, 0.2, 0.7), _p(0.58, 1.9, D - 2.9), Vector3(1, 0, 0))
	_texte("Idée n° 2 : ne PAS répondre au pigeon.", 20, Color(0.8, 0.15, 0.1), _p(0.58, 1.6, D - 2.9), Vector3(1, 0, 0))
	_gens("femme", 3.5, D - 4.0, Vector3(0, 0, 1), "assis", L_STANDARD)
	# ---- la pause (au sud-est) : le comptoir du café, les tabourets, le distributeur, les plantes
	_bx("in_bois", W - 4.6, W - 1.4, 0.0, 1.0, D - 0.95, D - 0.4, true)
	_bx("in_marbre_blanc", W - 4.65, W - 1.35, 1.0, 1.04, D - 1.0, D - 0.38)
	_bx("in_inox", W - 2.4, W - 1.8, 1.04, 1.5, D - 0.85, D - 0.45)
	_bx("in_led_ambre", W - 2.3, W - 2.2, 1.3, 1.34, D - 0.86, D - 0.85)
	for i5 in range(5):
		b.cyl_at("peinture_blanche", _p(W - 4.3 + i5 * 0.2, 1.04, D - 0.7), 0.035, 0.04, 0.08, 8)
	for i6 in range(3):
		b.cyl_at("in_inox", _p(W - 4.0 + i6 * 1.0, 0.0, D - 1.7), 0.025, 0.025, 0.62, 6)
		b.cyl_at("in_cuir", _p(W - 4.0 + i6 * 1.0, 0.62, D - 1.7), 0.17, 0.17, 0.05, 12)
	_distributeur(W - 5.6, D - 0.72, Vector3(0, 0, -1), "plastique_rouge")
	_plante_pot(W - 0.8, D - 0.8, 1.4)
	_plante_pot(W - 0.8, cz1 + 1.0, 1.2, true)
	_plante_pot(mx + 2.2, D - 0.8, 1.2)
	_gens("homme", W - 3.0, D - 2.3, Vector3(0, 0, 1), "debout", L_STANDARD)
	return ""


## Une alvéole du standard (on y regarde le nord) : le bureau, les cloisons de tissu, l'écran, le casque, la chaise.
func _alveole(lx: float, lz: float, teinte: String, n: int) -> void:
	_bx("in_bureau", lx - 0.75, lx + 0.75, 0.72, 0.76, lz - 0.35, lz + 0.3, true)
	_bx(teinte, lx - 0.8, lx + 0.8, 0.0, 1.45, lz - 0.42, lz - 0.36)
	for sg in [-0.8, 0.8]:
		_bx(teinte, lx + sg - 0.03, lx + sg + 0.03, 0.0, 1.3, lz - 0.42, lz + 0.5)
		_bx("in_inox", lx + sg - 0.035, lx + sg + 0.035, 1.3, 1.32, lz - 0.42, lz + 0.5)
	_bx("in_inox", lx - 0.8, lx + 0.8, 1.45, 1.47, lz - 0.425, lz - 0.355)
	_bx("in_noir", lx - 0.3, lx + 0.3, 0.84, 1.22, lz - 0.3, lz - 0.27)
	_bx(["in_ecran_ui_messages", "in_ecran_ui_graphes", "in_ecran_ui_code"][n % 3], lx - 0.27, lx + 0.27, 0.87, 1.19, lz - 0.27, lz - 0.265)
	_bx("in_noir", lx - 0.04, lx + 0.04, 0.76, 0.84, lz - 0.31, lz - 0.25)
	_bx("in_noir", lx - 0.25, lx + 0.2, 0.76, 0.775, lz - 0.1, lz + 0.05)
	# le casque, posé ou accroché ; le petit mot, la tasse, la plante
	b.tube("in_noir", _p(lx + 0.5, 0.78, lz - 0.05), _p(lx + 0.5, 0.92, lz + 0.02), 0.012, 5)
	b.tube("in_noir", _p(lx + 0.5, 0.92, lz + 0.02), _p(lx + 0.5, 0.78, lz + 0.12), 0.012, 5)
	b.blob("in_noir", _p(lx + 0.5, 0.79, lz - 0.05), Vector3(0.04, 0.045, 0.03), 6)
	b.blob("in_noir", _p(lx + 0.5, 0.79, lz + 0.12), Vector3(0.04, 0.045, 0.03), 6)
	_bx(["tissu_jaune", "sakura", "peinture_blanche"][n % 3], lx - 0.6, lx - 0.48, 1.0, 1.12, lz - 0.36, lz - 0.355)
	b.cyl_at(["rouge_laque", "peinture_blanche", "plastique_bleu", "tissu_vert"][n % 4], _p(lx - 0.55, 0.76, lz + 0.1), 0.035, 0.04, 0.08, 8)
	if n % 3 == 0:
		b.cyl_at("in_pot", _p(lx + 0.6, 0.76, lz - 0.22), 0.05, 0.06, 0.08, 8)
		_vegetal(Flora.fern_clump(), _p(lx + 0.6, 0.83, lz - 0.22), Vector3(0.22, 0.25, 0.22), n * 1.1)
	T._chaise(b, _p(lx, 0.0, lz + 0.75), Vector3(0, 0, -1))


# ------------------------------------------------------------------ le 8e : le Nuage (la salle de repos)
func _nuage() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	# ---- le nuage (au nord-ouest), sous le plafond : il pleut de la lumière sur la fosse aux coussins
	var nx: float = 7.0
	var nz: float = 3.2
	for i in range(34):
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf())
		var r: float = rng.randf_range(0.35, 0.7) * (1.0 - d * 0.35)
		b.blob("peinture_blanche", _p(nx + cos(a) * d * 2.6, hc - 0.45 - rng.randf_range(0.0, 0.25) + (1.0 - d) * 0.1, nz + sin(a) * d * 1.5), Vector3(r, r * 0.62, r * 0.9), 8)
	for i2 in range(46):
		var gx: float = nx + rng.randf_range(-2.3, 2.3)
		var gz: float = nz + rng.randf_range(-1.3, 1.3)
		var gl: float = rng.randf_range(0.3, 1.1)
		b.cyl_at("in_inox", _p(gx, hc - 0.6 - gl, gz), 0.002, 0.002, gl, 3)
		b.blob("lampe_chaude" if i2 % 3 != 0 else "neon_cyan", _p(gx, hc - 0.62 - gl, gz), Vector3(0.022, 0.035, 0.022), 5)
	var on := OmniLight3D.new()
	on.light_color = Color(1.0, 0.85, 0.65)
	on.light_energy = 1.2
	on.omni_range = 6.0
	(T.get("_node") as Node3D).add_child(on)
	on.global_position = _p(nx, 1.9, nz)
	# la fosse : un tapis rond, des coussins et des poufs de toutes les couleurs
	b.cyl_at("in_tissu_gris", _p(nx, 0.0, nz), 2.5, 2.5, 0.015, 32)
	var coul: Array = ["in_tissu_rouge", "plastique_bleu", "tissu_jaune", "tissu_vert", "k187_orange", "sakura", "peinture_blanche"]
	for i3 in range(12):
		var a2: float = i3 * TAU / 12.0 + rng.randf_range(-0.15, 0.15)
		var d2: float = rng.randf_range(0.9, 2.1)
		var pr: float = rng.randf_range(0.28, 0.45)
		if i3 == 3 or i3 == 8:
			continue                                 # (deux places pour ceux qui s'y assoient)
		b.blob(str(coul[i3 % coul.size()]), _p(nx + cos(a2) * d2, 0.015 + pr * 0.5, nz + sin(a2) * d2), Vector3(pr, pr * 0.5, pr), 8)
	T._col(_p(nx - 2.0, 0.3, nz - 1.2), Vector3(0.8, 0.6, 0.8))
	_gens("femme", nx + cos(3.0 * TAU / 12.0) * 1.5, nz + sin(3.0 * TAU / 12.0) * 1.5, Vector3(0, 0, -1), "debout", L_NUAGE, false, true)
	# ---- les hamacs (au nord-est) : trois toiles tendues entre des poteaux de bois
	for i4 in range(3):
		var hx: float = mx + 3.4 + i4 * 2.0
		for hz in [1.2, 5.0]:
			b.cyl_at("in_bois", _p(hx, 0.0, hz), 0.05, 0.05, 1.5, 8)
			b.cyl_at("in_bois", _p(hx, 0.0, hz), 0.22, 0.22, 0.03, 12)
		for j in range(8):
			var u0: float = float(j) / 8.0
			var u1: float = float(j + 1) / 8.0
			var y0: float = 1.35 - sin(u0 * PI) * 0.75
			var y1: float = 1.35 - sin(u1 * PI) * 0.75
			var z0: float = lerpf(1.3, 4.9, u0)
			var z1: float = lerpf(1.3, 4.9, u1)
			var ang: float = atan2(y1 - y0, z1 - z0)
			b.box(str(coul[(i4 * 2) % coul.size()]) if j % 2 == 0 else "peinture_blanche", Transform3D(Basis(Vector3(1, 0, 0), -ang), _p(hx, (y0 + y1) * 0.5, (z0 + z1) * 0.5)),
				Vector3(0.75 * (0.55 + 0.45 * sin((u0 + u1) * 0.5 * PI)), 0.02, Vector2(z1 - z0, y1 - y0).length() + 0.01))
		T._col(_p(hx, 0.5, 3.1), Vector3(0.8, 1.0, 3.8))
	# ---- les jeux (à l'ouest et au sud-ouest) : le baby-foot, la table de ping-pong, les bornes
	var fz: float = cm
	_bx("in_bois", 2.0, 3.3, 0.55, 0.9, fz - 0.4, fz + 0.4, true)
	_bx("tissu_vert", 2.05, 3.25, 0.9, 0.905, fz - 0.35, fz + 0.35)
	for q in [[2.05, fz - 0.35], [3.25, fz - 0.35], [2.05, fz + 0.35], [3.25, fz + 0.35]]:
		_bx("in_bois", q[0] - 0.04, q[0] + 0.04, 0.0, 0.55, q[1] - 0.04, q[1] + 0.04)
	for i5 in range(6):
		var rx: float = 2.15 + i5 * 0.2
		b.tube("in_inox", _p(rx, 1.0, fz - 0.65), _p(rx, 1.0, fz + 0.65), 0.008, 5)
		b.cyl("in_noir", Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), _p(rx, 1.0, fz + (0.7 if i5 % 2 == 0 else -0.7))), 0.02, 0.02, 0.1, 6)
		for j2 in range(2 + (i5 % 2)):
			_bx("plastique_rouge" if i5 % 2 == 0 else "plastique_bleu", rx - 0.015, rx + 0.015, 0.91, 1.02, fz - 0.2 + j2 * 0.2 - 0.02, fz - 0.2 + j2 * 0.2 + 0.02)
	_gens("homme", 2.65, fz + 1.0, Vector3(0, 0, -1), "comptoir", L_NUAGE)
	var tz: float = D - 3.2
	_bx("plastique_bleu", 1.6, 4.3, 0.74, 0.77, tz - 0.76, tz + 0.76, true)
	_bx("peinture_blanche", 1.6, 4.3, 0.771, 0.773, tz - 0.01, tz + 0.01)
	_bx("peinture_blanche", 2.94, 2.96, 0.77, 0.92, tz - 0.82, tz + 0.82)
	for q2 in [[1.8, tz - 0.6], [4.1, tz - 0.6], [1.8, tz + 0.6], [4.1, tz + 0.6]]:
		b.cyl_at("in_noir", _p(q2[0], 0.0, q2[1]), 0.025, 0.025, 0.74, 6)
	b.cyl("plastique_rouge", Transform3D(Basis(), _p(2.2, 0.78, tz + 0.3)), 0.08, 0.08, 0.012, 10)
	b.blob("peinture_blanche", _p(3.6, 0.79, tz - 0.2), Vector3(0.02, 0.02, 0.02), 6)
	for i6 in range(3):
		Q._borne(T, b, _p(0.75, 0.0, D - 6.4 - i6 * 1.0), Vector3(1, 0, 0), rng, ["neon_cyan", "neon_rouge", "neon_cyan"][i6], true)
	# ---- la sieste (à l'est) : trois cocons blancs, leur veilleuse
	for i7 in range(3):
		var kz: float = cz0 + 0.3 + i7 * 2.3
		# le lit (la tête contre le mur de l'est), sa capote de toile sur ses arceaux, la veilleuse
		_bx("in_bois_clair", W - 2.7, W - 0.6, 0.0, 0.3, kz - 0.5, kz + 0.5, true)
		_bx("peinture_blanche", W - 2.65, W - 0.65, 0.3, 0.44, kz - 0.46, kz + 0.46)
		_bx(str(coul[i7 * 2]), W - 2.0, W - 0.9, 0.44, 0.5, kz - 0.47, kz + 0.47)
		b.blob("peinture_blanche", _p(W - 0.95, 0.5, kz), Vector3(0.2, 0.08, 0.3), 8)
		for a7 in range(8):
			var t0: float = PI * float(a7) / 8.0
			var t1: float = PI * float(a7 + 1) / 8.0
			var p0 := Vector2(cos(t0) * 0.56, sin(t0) * 0.75)
			var p1 := Vector2(cos(t1) * 0.56, sin(t1) * 0.75)
			var mid: Vector2 = (p0 + p1) * 0.5
			b.box("peinture_blanche" if a7 % 2 == 0 else "in_tissu_gris", Transform3D(Basis(Vector3(1, 0, 0), -atan2(p1.y - p0.y, p1.x - p0.x)), _p(W - 1.25, 0.34 + mid.y, kz + mid.x)), Vector3(1.3, 0.025, p0.distance_to(p1) + 0.01))
		for ax7 in [W - 1.9, W - 0.6]:
			for a8 in range(8):
				var u0: float = PI * float(a8) / 8.0
				var u1: float = PI * float(a8 + 1) / 8.0
				b.tube("in_inox", _p(ax7, 0.34 + sin(u0) * 0.77, kz + cos(u0) * 0.58), _p(ax7, 0.34 + sin(u1) * 0.77, kz + cos(u1) * 0.58), 0.015, 5)
		b.blob("lampe_chaude", _p(W - 0.75, 0.85, kz), Vector3(0.03, 0.03, 0.03), 5)
		T._col(_p(W - 1.25, 0.7, kz), Vector3(1.4, 1.4, 1.2))
	_texte("Sieste : vingt minutes. Vent compris.", 22, Color(0.9, 0.95, 1.0), _p(cx1 + 0.05, 1.9, cm), Vector3(1, 0, 0))
	# ---- la bibliothèque (au sud-est) : les rayons, le tapis, deux fauteuils, la lampe
	for niv in range(5):
		_bx("in_bois", W - 6.4, W - 0.6, 0.2 + niv * 0.5, 0.24 + niv * 0.5, D - 0.8, D - 0.4)
		var lxb: float = W - 6.3
		while lxb < W - 0.8:
			var wb: float = rng.randf_range(0.04, 0.09)
			if rng.randf() < 0.86:
				_bx(str(coul[rng.randi() % coul.size()]), lxb, lxb + wb, 0.24 + niv * 0.5, 0.24 + niv * 0.5 + rng.randf_range(0.26, 0.4), D - 0.75, D - 0.5)
			lxb += wb + 0.006
	for pxx in [W - 6.4, W - 3.5, W - 0.6]:
		_bx("in_bois", pxx - 0.03, pxx + 0.03, 0.0, 2.75, D - 0.82, D - 0.4)
	T._col(_p(W - 3.5, 1.3, D - 0.6), Vector3(5.9, 2.7, 0.5))
	_bx("in_tissu_rouge", W - 5.6, W - 1.4, 0.0, 0.012, D - 4.2, D - 1.3)
	_canape(W - 4.6, D - 2.4, Vector3(0.5, 0, 0.87).normalized(), 1.0, "in_cuir")
	_canape(W - 2.4, D - 2.4, Vector3(-0.5, 0, 0.87).normalized(), 1.0, "in_cuir")
	b.cyl_at("in_bois", _p(W - 3.5, 0.0, D - 2.0), 0.3, 0.3, 0.42, 14)
	for i8 in range(3):
		_bx(str(coul[i8]), W - 3.65, W - 3.4, 0.42 + i8 * 0.035, 0.45 + i8 * 0.035, D - 2.15, D - 1.82)
	b.cyl_at("in_noir", _p(W - 1.2, 0.0, D - 1.5), 0.012, 0.012, 1.6, 6)
	b.cyl_at("in_noir", _p(W - 1.2, 0.0, D - 1.5), 0.14, 0.14, 0.02, 12)
	b.cyl_at("lampe_chaude", _p(W - 1.2, 1.55, D - 1.5), 0.17, 0.12, 0.26, 12)
	_gens("femme", W - 4.55, D - 2.3, Vector3(0.5, 0, 0.87).normalized(), "assis", L_NUAGE)
	# ---- le bar à jus (au sud, près de l'escalier) : le comptoir, les fruits, la machine qui a du caractère
	_bx("in_bois_clair", mx - 2.4, mx + 0.4, 0.0, 1.0, D - 0.95, D - 0.4, true)
	_bx("in_marbre_blanc", mx - 2.45, mx + 0.45, 1.0, 1.04, D - 1.0, D - 0.38)
	_bx("in_inox", mx - 0.4, mx + 0.2, 1.04, 1.55, D - 0.85, D - 0.45)
	_bx("in_ecran_vert", mx - 0.3, mx + 0.1, 1.3, 1.45, D - 0.86, D - 0.85)
	b.cyl_at("in_bois", _p(mx - 1.6, 1.04, D - 0.7), 0.22, 0.16, 0.08, 12)
	for i9 in range(7):
		b.blob(["k187_orange", "tissu_jaune", "tissu_vert", "plastique_rouge"][i9 % 4], _p(mx - 1.6 + cos(i9 * 0.9) * 0.11, 1.14 + (i9 % 2) * 0.05, D - 0.7 + sin(i9 * 0.9) * 0.11), Vector3(0.05, 0.05, 0.05), 6)
	for i10 in range(3):
		b.cyl_at("verre", _p(mx - 1.0 + i10 * 0.16, 1.04, D - 0.65), 0.035, 0.03, 0.12, 8)
	_gens("homme", mx - 1.0, D - 1.7, Vector3(0, 0, 1), "comptoir", L_NUAGE)
	_plante_pot(0.9, 0.9, 1.5)
	_plante_pot(2.2, 0.9, 1.1, true)
	_plante_pot(mx + 2.2, 0.8, 1.2, true)
	_plante_pot(W - 0.9, D - 1.6, 1.0, true)
	return ""


# ------------------------------------------------------------------ le 9e : le bureau d'études
func _etudes() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	# ---- les planches à dessin (au nord, face à la mer) : le plan bleu, les traits, la lampe, le tabouret
	var n_p: int = 0
	for px in [1.6, mx + 3.0, W - 1.6]:
		var o: Vector3 = _p(px, 0.0, 1.5)
		var incl := Basis(Vector3(1, 0, 0), -0.9)
		for sg in [-0.5, 0.5]:
			b.tube("in_noir", o + Vector3(sg, 0.0, 0.25), o + Vector3(sg, 1.0, -0.1), 0.02, 6)
			b.tube("in_noir", o + Vector3(sg, 0.0, -0.4), o + Vector3(sg, 1.0, -0.1), 0.02, 6)
		b.box("peinture_blanche", Transform3D(incl, o + Vector3(0, 1.1, -0.05)), Vector3(1.3, 0.03, 0.95))
		b.box("plastique_bleu", Transform3D(incl, o + Vector3(0, 1.115, -0.038)), Vector3(1.1, 0.004, 0.8))
		for i in range(5):                            # (le dessin : un drone vu de dessus, en traits blancs)
			var ang: float = i * TAU / 5.0 + n_p
			b.box("peinture_blanche", Transform3D(incl * Basis(Vector3.UP, ang), o + Vector3(0, 1.118, -0.036) + incl * (Basis(Vector3.UP, ang) * Vector3(0.18, 0, 0))), Vector3(0.36, 0.002, 0.012))
			b.cyl("peinture_blanche", Transform3D(incl, o + Vector3(0, 1.118, -0.036) + incl * (Basis(Vector3.UP, ang) * Vector3(0.36, 0, 0))), 0.09, 0.09, 0.002, 12)
		b.tube("in_noir", o + Vector3(0.6, 1.3, -0.4), o + Vector3(0.3, 1.75, -0.3), 0.01, 5)
		b.cyl_at("lampe_blanche", o + Vector3(0.3, 1.68, -0.3), 0.07, 0.07, 0.012, 10)
		b.cyl_at("in_inox", _p(px, 0.0, 2.3), 0.02, 0.02, 0.6, 6)
		b.cyl_at("in_noir", _p(px, 0.6, 2.3), 0.16, 0.16, 0.05, 12)
		T._col(o + Vector3(0, 0.7, -0.05), Vector3(1.3, 1.4, 0.9))
		if n_p != 1:
			_gens("femme" if n_p == 0 else "homme", px, 2.35, Vector3(0, 0, -1), "comptoir", L_ETUDES, false, n_p == 0)
		n_p += 1
	# ---- les prototypes (à l'ouest) : trois socles, leurs étiquettes
	var noms: Array = ["K-Titan : il porte un piano", "K-Mouche : onze perdus à ce jour", "K-Plume : il livre sans bruit. On ne le retrouve jamais."]
	for i2 in range(3):
		var pz: float = cz0 + 0.3 + i2 * 1.75
		_bx("in_marbre_blanc", 0.6, 1.6, 0.0, 0.8, pz - 0.5, pz + 0.5, true)
		_bx("neon_cyan", 0.62, 1.58, 0.8, 0.805, pz - 0.48, pz + 0.48)
		var lab: Label3D = _texte(str(noms[i2]), 18, Color(0.15, 0.2, 0.3), _p(1.62, 0.5, pz), Vector3(1, 0, 0))
		lab.width = 230.0
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if i2 == 0:
			var titan: MeshInstance3D = _drone_vivant(_p(1.1, 1.5, pz), 1.7, false)
			_anime().flotte.append([titan, _p(1.1, 1.5, pz), 0.05, 1.0, 0.0])
			_piano(_p(1.1, 0.95, pz), 0.0, 0.32)
			for sg2 in [-0.25, 0.25]:
				b.tube("in_noir", _p(1.1 + sg2, 1.2, pz), _p(1.1 + sg2 * 0.6, 1.45, pz), 0.004, 4)
		elif i2 == 1:
			for j in range(5):
				var mo: MeshInstance3D = _drone_vivant(_p(1.1 + cos(j * 1.3) * 0.25, 1.05 + j * 0.07, pz + sin(j * 1.3) * 0.25), 0.22, false)
				_anime().flotte.append([mo, mo.global_position, 0.05, 1.5 + j * 0.3, j * 1.1])
				_anime().tourne.append([mo, 1.0 + j * 0.2])
			b.blob("verre", _p(1.1, 0.8, pz), Vector3(0.48, 0.75, 0.48), 12)
		else:
			_drone(b, _p(1.1, 1.0, pz), 0.8, false, 1.0)
			b.blob("peinture_blanche", _p(1.1, 0.87, pz), Vector3(0.3, 0.06, 0.2), 8)
	# le tableau (sur le cœur, face aux prototypes) : les équations de la maison
	_bx("peinture_blanche", cx0 - 0.04, cx0, 0.95, 2.4, cz0 + 0.3, cz1 - 0.3)
	_bx("in_inox", cx0 - 0.08, cx0, 0.9, 0.95, cz0 + 0.25, cz1 - 0.25)
	var eq: Array = [["portance = vent × audace", Color(0.1, 0.2, 0.7)], ["poids du piano : trop", Color(0.8, 0.15, 0.1)], ["vingt minutes = dix-neuf + une de politesse", Color(0.1, 0.45, 0.2)],
		["NE PAS EFFACER (c'est joli)", Color(0.1, 0.1, 0.15)]]
	for i3 in range(eq.size()):
		_texte(str(eq[i3][0]), 22, eq[i3][1], _p(cx0 - 0.05, 2.15 - i3 * 0.3, cm), Vector3(-1, 0, 0))
	# ---- la soufflerie (à l'est) : le tube de verre, l'hélice qui tourne, le drone à l'épreuve, les filets de fumée
	var tx: float = W - 2.1
	var couche := Basis(Vector3(1, 0, 0), PI * 0.5)
	b.cyl("verre", Transform3D(couche, _p(tx, 1.25, cm)), 0.85, 0.85, 3.6, 20)
	for kz in [cm - 1.8, cm, cm + 1.8]:
		b.cyl("in_inox", Transform3D(couche, _p(tx, 1.25, kz)), 0.9, 0.9, 0.08, 20, false)
		_bx("metal_noir", tx - 0.7, tx + 0.7, 0.0, 0.42, kz - 0.06, kz + 0.06)
	_bx("metal_noir", tx - 0.95, tx + 0.95, 0.3, 2.2, cm - 2.5, cm - 1.84, true)
	_bx("k187_danger", tx - 0.95, tx + 0.95, 0.3, 0.42, cm - 1.84, cm - 1.83)
	var lotf := Kit.Batch.new()
	for a in range(5):
		lotf.box("in_inox", Transform3D(Basis(Vector3(0, 0, 1), a * TAU / 5.0) * Basis(Vector3(1, 0, 0), 0.5), Basis(Vector3(0, 0, 1), a * TAU / 5.0) * Vector3(0.38, 0, 0)), Vector3(0.7, 0.22, 0.02))
	lotf.cyl("metal_noir", Transform3D(couche, Vector3.ZERO), 0.12, 0.12, 0.12, 10)
	var helice := MeshInstance3D.new()
	helice.mesh = _maillage(lotf)
	_anime().add_child(helice)
	helice.global_position = _p(tx, 1.25, cm - 1.7)
	_anime().vrille.append([helice, 9.0])
	var essai: MeshInstance3D = _drone_vivant(_p(tx, 1.25, cm + 0.3), 1.1, false)
	essai.rotate_y(PI * 0.5)
	_anime().flotte.append([essai, _p(tx, 1.25, cm + 0.3), 0.06, 3.0, 0.0])
	for i4 in range(6):
		var fa: float = i4 * TAU / 6.0
		b.tube("neon_cyan", _p(tx + cos(fa) * 0.5, 1.25 + sin(fa) * 0.5, cm - 1.5), _p(tx + cos(fa) * 0.55, 1.25 + sin(fa) * 0.55, cm + 1.7), 0.006, 4)
	T._col(_p(tx, 1.2, cm), Vector3(1.9, 2.4, 3.8))
	_bx("in_noir", tx - 2.0, tx - 1.5, 0.0, 1.0, cm + 0.6, cm + 1.6, true)
	b.box("in_ecran_ui_graphes", Transform3D(Basis(Vector3(0, 0, 1), 0.45), _p(tx - 1.78, 1.08, cm + 1.1)), Vector3(0.4, 0.01, 0.8))
	_gens("homme", tx - 2.1, cm - 0.4, Vector3(1, 0, 0), "bras_croises", L_ETUDES, false, true)
	# ---- les imprimantes (au sud-ouest) : deux caissons vitrés, une hélice qui pousse couche à couche
	for i5 in range(2):
		var ix: float = 1.0 + i5 * 1.5
		_bx("in_noir", ix - 0.55, ix + 0.55, 0.0, 0.8, D - 1.3, D - 0.4, true)
		for q in [[ix - 0.52, D - 1.27], [ix + 0.52, D - 1.27], [ix - 0.52, D - 0.43], [ix + 0.52, D - 0.43]]:
			_bx("in_noir", q[0] - 0.03, q[0] + 0.03, 0.8, 1.7, q[1] - 0.03, q[1] + 0.03)
		_bx("in_noir", ix - 0.55, ix + 0.55, 1.7, 1.78, D - 1.3, D - 0.4)
		_bx("in_vitre", ix - 0.5, ix + 0.5, 0.8, 1.7, D - 1.28, D - 1.26)
		_bx("lampe_blanche", ix - 0.45, ix + 0.45, 1.68, 1.7, D - 1.2, D - 0.5)
		_bx("in_inox", ix - 0.4, ix + 0.4, 0.8, 0.83, D - 1.2, D - 0.5)
		_bx("in_inox", ix - 0.5, ix + 0.5, 1.3, 1.33, D - 0.9, D - 0.86)
		_bx("in_noir", ix - 0.1 + i5 * 0.2, ix + 0.02 + i5 * 0.2, 1.2, 1.33, D - 0.95, D - 0.8)
		if i5 == 0:
			b.cyl_at("k187_orange", _p(ix, 0.83, D - 0.85), 0.03, 0.03, 0.05, 8)
			b.cyl_at("k187_orange", _p(ix, 0.88, D - 0.85), 0.25, 0.25, 0.012, 14)
		else:
			_bx("k187_orange", ix - 0.2, ix + 0.2, 0.83, 0.93, D - 0.98, D - 0.72)
		_bx("in_led_verte" if i5 == 0 else "in_led_ambre", ix + 0.35, ix + 0.45, 0.6, 0.64, D - 1.31, D - 1.3)
	_gens("femme", 1.75, D - 2.0, Vector3(0, 0, 1), "debout", L_ETUDES)
	# ---- la table des maquettes (au sud-est) : des morceaux de drones, des plans roulés ; l'assistant
	_bx("in_bois_clair", W - 4.8, W - 2.0, 0.9, 0.95, D - 2.6, D - 1.4, true)
	for q2 in [[W - 4.7, D - 2.5], [W - 2.1, D - 2.5], [W - 4.7, D - 1.5], [W - 2.1, D - 1.5]]:
		b.cyl_at("in_inox", _p(q2[0], 0.0, q2[1]), 0.025, 0.025, 0.9, 6)
	_drone(b, _p(W - 4.0, 1.15, D - 2.0), 0.4, false, 1.0)
	for i6 in range(4):
		b.cyl("peinture_blanche" if i6 % 2 == 0 else "plastique_bleu", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5) * Basis(Vector3(1, 0, 0), 0.2 * i6), _p(W - 2.9, 0.98 + (i6 >> 1) * 0.05, D - 2.3 + (i6 % 2) * 0.12)), 0.03, 0.03, 0.8, 8)
	b.cyl_at("verre_fume", _p(W - 3.3, 0.95, D - 1.7), 0.2, 0.2, 0.01, 12)
	b.cyl_at("verre_fume", _p(W - 3.1, 0.96, D - 1.6), 0.2, 0.2, 0.01, 12)
	_gens("homme", W - 3.4, D - 3.2, Vector3(0, 0, 1), "comptoir", L_ROBOT_ETUDES, true, true)
	_plante_pot(W - 0.8, D - 0.8, 1.3)
	_plante_pot(mx - 2.6, 0.8, 1.1, true)
	return "bip"


## Un piano droit (« s » : sa taille — 1 : un vrai ; 0,3 : une maquette).
func _piano(at: Vector3, yaw: float, s: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box("in_noir", Transform3D(bs, at + bs * Vector3(0, 0.62, -0.15) * s), Vector3(1.5, 1.24, 0.35) * s)
	b.box("in_noir", Transform3D(bs, at + bs * Vector3(0, 0.66, 0.16) * s), Vector3(1.5, 0.1, 0.3) * s)
	b.box("peinture_blanche", Transform3D(bs, at + bs * Vector3(0, 0.72, 0.2) * s), Vector3(1.3, 0.02, 0.18) * s)
	for i in range(18):
		if i % 7 != 2 and i % 7 != 6:
			b.box("in_noir", Transform3D(bs, at + bs * Vector3(-0.61 + i * 0.072, 0.735, 0.16) * s), Vector3(0.035, 0.02, 0.1) * s)
	for sg in [-0.7, 0.7]:
		b.box("in_noir", Transform3D(bs, at + bs * Vector3(sg, 0.33, 0.2) * s), Vector3(0.08, 0.66, 0.1) * s)
	b.box("in_bois", Transform3D(bs, at + bs * Vector3(0, 1.0, 0.03) * s), Vector3(0.6, 0.3, 0.02) * s)
	b.box("lampe_chaude", Transform3D(bs, at + bs * Vector3(0, 0.12, 0.05) * s), Vector3(0.3, 0.03, 0.04) * s)


# ------------------------------------------------------------------ le 10e : les objets trouvés
func _trouves() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	# ---- le guichet (au nord-est, en sortant de l'ascenseur) : le registre, la sonnette, le casier à étiquettes
	_bx("in_bois", mx + 2.0, mx + 5.2, 0.0, 1.05, 2.6, 3.2, true)
	_bx("in_bois_clair", mx + 1.95, mx + 5.25, 1.05, 1.09, 2.55, 3.3)
	_bx("in_cuir", mx + 2.9, mx + 3.5, 1.09, 1.13, 2.75, 3.15)
	_bx("peinture_blanche", mx + 2.93, mx + 3.47, 1.13, 1.14, 2.78, 3.12)
	b.cyl_at("lampe_chaude", _p(mx + 4.2, 1.09, 3.05), 0.06, 0.02, 0.05, 10)
	b.cyl_at("in_inox", _p(mx + 4.2, 1.14, 3.05), 0.01, 0.01, 0.02, 5)
	_texte("COLIS EN PROMENADE", 44, Color(1.0, 0.6, 0.15), _p(mx + 3.6, 2.5, 2.58), Vector3(0, 0, 1))
	_texte("« Rien ne se perd. Tout se promène. »", 22, Color(0.9, 0.95, 1.0), _p(mx + 3.6, 2.2, 2.58), Vector3(0, 0, 1))
	_bx("in_noir", mx + 2.0, mx + 5.2, 2.0, 2.75, 2.5, 2.56)
	for cb in [mx + 2.2, mx + 5.0]:
		_bx("in_noir", cb - 0.01, cb + 0.01, 2.75, hc, 2.52, 2.54)
	_gens("femme", mx + 3.4, 1.9, Vector3(0, 0, 1), "comptoir", L_TROUVES, false, true)
	_gens("homme", mx + 3.2, 4.0, Vector3(0, 0, -1), "debout", L_CHERCHEUR)
	# ---- les allées (à l'ouest et au sud) : des rayons pleins de tout ce qui est tombé du ciel
	var n_o: int = 0
	for ray in [[0.5, cz0 - 0.2, 0.5, cz1 + 0.6, 1.0], [2.5, cz0 + 0.3, 2.5, cz1 + 0.3, -1.0], [2.9, cz0 + 0.3, 2.9, cz1 + 0.3, 1.0]]:
		# (un rayon le long de z : x, z0, z1, et le côté d'où on le regarde)
		var rx: float = ray[0]
		var cote: float = ray[4]
		for niv in range(4):
			_bx("in_bois", rx - 0.03 if cote > 0.0 else rx - 0.5, rx + 0.5 if cote > 0.0 else rx + 0.03, 0.25 + niv * 0.6, 0.29 + niv * 0.6, ray[1], ray[3])
			var oz: float = float(ray[1]) + 0.35
			while oz < float(ray[3]) - 0.2:
				_objet(n_o, _p(rx + cote * 0.24, 0.29 + niv * 0.6, oz), niv)
				n_o += 1
				oz += rng.randf_range(0.5, 0.75)
		for pz in [float(ray[1]), (float(ray[1]) + float(ray[3])) * 0.5, float(ray[3])]:
			_bx("in_inox", rx + cote * 0.47 - 0.02, rx + cote * 0.47 + 0.02, 0.0, 2.3, pz - 0.02, pz + 0.02)
	_bx("in_bois", 2.47, 2.53, 0.0, 2.3, cz0 + 0.3, cz1 + 0.3)
	T._col(_p(0.75, 1.2, cm + 0.2), Vector3(0.6, 2.4, cz1 - cz0 + 0.8))
	T._col(_p(2.7, 1.2, cm + 0.3), Vector3(1.0, 2.4, cz1 - cz0))
	for niv2 in range(4):
		_bx("in_bois", 4.9, W - 0.6, 0.25 + niv2 * 0.6, 0.29 + niv2 * 0.6, D - 0.9, D - 0.4)
		var ox: float = 5.2
		while ox < W - 0.9:
			_objet(n_o, _p(ox, 0.29 + niv2 * 0.6, D - 0.65), niv2)
			n_o += 1
			ox += rng.randf_range(0.5, 0.75)
	for px in [4.9, 8.0, 11.0, W - 0.6]:
		_bx("in_inox", px - 0.02, px + 0.02, 0.0, 2.3, D - 0.93, D - 0.89)
	T._col(_p((4.9 + W - 0.6) * 0.5, 1.2, D - 0.65), Vector3(W - 5.5, 2.4, 0.6))
	# l'échelle, contre le rayon du sud ; celui qui cherche tout en haut
	for sg in [-0.22, 0.22]:
		b.tube("in_bois_clair", _p(10.0 + sg, 0.0, D - 1.9), _p(10.0 + sg, 2.4, D - 1.0), 0.025, 6)
	for i in range(7):
		var u: float = (i + 0.5) / 7.5
		b.tube("in_bois_clair", _p(9.78, 2.4 * u, D - 1.9 + 0.9 * u), _p(10.22, 2.4 * u, D - 1.9 + 0.9 * u), 0.018, 5)
	_gens("homme", 8.8, D - 2.0, Vector3(0, 0, 1), "debout", L_TROUVES)
	# ---- les grands objets (à l'est) : le piano arrivé seul, le canoë pendu au plafond, le vélo, l'aquarium
	_bx("in_tissu_rouge", W - 4.2, W - 0.9, 0.0, 0.012, cz0 - 0.2, cz1 + 0.6)
	_piano(_p(W - 1.2, 0.0, cm - 0.5), -PI * 0.5, 1.0)
	T._col(_p(W - 1.2, 0.65, cm - 0.5), Vector3(0.8, 1.3, 1.6))
	_bx("in_cuir", W - 2.3, W - 1.9, 0.42, 0.5, cm - 0.9, cm - 0.1, true)
	for q in [[W - 2.25, cm - 0.85], [W - 1.95, cm - 0.85], [W - 2.25, cm - 0.15], [W - 1.95, cm - 0.15]]:
		b.cyl_at("in_noir", _p(q[0], 0.0, q[1]), 0.02, 0.02, 0.42, 6)
	var lp: Label3D = _texte("Piano. Arrivé seul, un mardi. Personne ne l'a réclamé.", 20, Color(0.95, 0.9, 0.75), _p(W - 3.0, 0.5, cm + 1.0), Vector3(-1, 0, 0))
	lp.width = 300.0
	lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.cyl_at("in_inox", _p(W - 3.0, 0.0, cm + 1.0), 0.015, 0.015, 0.9, 6)
	# le canoë
	b.blob("in_bois", _p(W - 2.4, hc - 0.55, cm + 0.2), Vector3(0.4, 0.22, 2.2), 12)
	b.blob("in_noir", _p(W - 2.4, hc - 0.5, cm + 0.2), Vector3(0.3, 0.2, 1.9), 10)
	for kz in [cm - 1.0, cm + 1.4]:
		b.cyl_at("in_noir", _p(W - 2.4, hc - 0.4, kz), 0.006, 0.006, 0.4, 4)
	# le vélo : deux roues, le cadre, le guidon, la selle
	var vz: float = cz1 + 1.6
	var vx: float = W - 2.6
	for wx in [vx - 0.5, vx + 0.5]:
		for a in range(12):
			var a0: float = a * TAU / 12.0
			var a1: float = (a + 1) * TAU / 12.0
			b.tube("in_noir", _p(wx + cos(a0) * 0.33, 0.33 + sin(a0) * 0.33, vz), _p(wx + cos(a1) * 0.33, 0.33 + sin(a1) * 0.33, vz), 0.018, 5)
			if a % 3 == 0:
				b.tube("in_inox", _p(wx, 0.33, vz), _p(wx + cos(a0) * 0.33, 0.33 + sin(a0) * 0.33, vz), 0.004, 3)
	for seg in [[-0.5, 0.33, 0.0, 0.33], [0.0, 0.33, -0.15, 0.82], [-0.15, 0.82, 0.38, 0.8], [0.0, 0.33, 0.38, 0.8], [0.38, 0.8, 0.5, 0.33], [-0.5, 0.33, -0.15, 0.82], [0.38, 0.8, 0.36, 0.98]]:
		b.tube("plastique_rouge", _p(vx + seg[0], seg[1], vz), _p(vx + seg[2], seg[3], vz), 0.016, 5)
	b.tube("in_noir", _p(vx + 0.36, 0.98, vz - 0.22), _p(vx + 0.36, 0.98, vz + 0.22), 0.012, 5)
	b.blob("in_cuir", _p(vx - 0.17, 0.87, vz), Vector3(0.13, 0.03, 0.07), 6)
	_bx("in_inox", vx - 0.02, vx + 0.02, 0.0, 0.3, vz + 0.1, vz + 0.14)
	T._col(_p(vx, 0.5, vz), Vector3(1.7, 1.0, 0.5))
	# l'aquarium (le poisson rouge attend son maître)
	_bx("in_bois", W - 1.1, W - 0.5, 0.0, 0.8, cz0 - 0.2, cz0 + 0.6, true)
	_bx("eau", W - 1.05, W - 0.55, 0.82, 1.18, cz0 - 0.15, cz0 + 0.55)
	_bx("in_vitre", W - 1.07, W - 0.53, 0.8, 1.25, cz0 - 0.17, cz0 + 0.57)
	_bx("gravier_zen", W - 1.05, W - 0.55, 0.8, 0.84, cz0 - 0.15, cz0 + 0.55)
	var lotp := Kit.Batch.new()
	lotp.blob("k187_orange", Vector3(0.14, 0, 0), Vector3(0.06, 0.035, 0.02), 6)
	lotp.blob("k187_orange", Vector3(0.14, 0, 0.06), Vector3(0.02, 0.03, 0.035), 5)
	var poisson := MeshInstance3D.new()
	poisson.mesh = _maillage(lotp)
	_anime().add_child(poisson)
	poisson.global_position = _p(W - 0.8, 1.0, cz0 + 0.2)
	_anime().tourne.append([poisson, 1.1])
	# ---- le coin des parapluies (au nord-ouest) : quatre cents, dit-on ; les valises en pile
	_bx("in_inox", 0.6, 3.2, 0.0, 0.5, 0.6, 1.6, true)
	for i2 in range(26):
		var ux: float = 0.75 + (i2 % 9) * 0.28 + rng.randf_range(-0.05, 0.05)
		var uz: float = 0.75 + floorf(i2 / 9.0) * 0.35 + rng.randf_range(-0.05, 0.05)
		var cl: String = "in_noir" if i2 % 3 != 0 else str(["plastique_rouge", "plastique_bleu", "tissu_jaune", "tissu_vert"][i2 % 4])
		b.cyl_at(cl, _p(ux, 0.1, uz), 0.035, 0.02, 0.85, 6)
		b.tube("in_bois", _p(ux, 0.95, uz), _p(ux + 0.05, 1.03, uz), 0.012, 4)
	for i3 in range(6):
		_bx(["in_cuir", "plastique_bleu", "in_tissu_rouge", "in_bois", "tissu_vert", "in_cuir"][i3], W - 4.6 + (i3 % 2) * 0.1, W - 3.7 + (i3 % 2) * 0.05, i3 * 0.27, i3 * 0.27 + 0.25, 0.6, 1.25)
		_bx("in_inox", W - 4.25, W - 4.05, i3 * 0.27 + 0.1, i3 * 0.27 + 0.16, 1.25, 1.27)
	T._col(_p(W - 4.15, 0.8, 0.95), Vector3(1.0, 1.7, 0.8))
	_plante_pot(W - 0.8, 0.8, 1.2)
	return ""


## Un objet trouvé, posé sur un rayon (douze sortes : n choisit).
func _objet(n: int, at: Vector3, niv: int) -> void:
	var c: Array = ["plastique_rouge", "plastique_bleu", "tissu_jaune", "tissu_vert", "k187_orange", "sakura", "peinture_blanche"]
	var k1: String = str(c[(n * 3 + niv) % c.size()])
	var k2: String = str(c[(n * 5 + 2) % c.size()])
	match (n * 7 + niv * 3) % 12:
		0:                                            # un ours en peluche
			b.blob("in_bois_clair", at + Vector3(0, 0.12, 0), Vector3(0.11, 0.13, 0.1), 8)
			b.blob("in_bois_clair", at + Vector3(0, 0.3, 0), Vector3(0.085, 0.085, 0.08), 8)
			for sg in [-0.07, 0.07]:
				b.blob("in_bois_clair", at + Vector3(0, 0.38, sg), Vector3(0.03, 0.03, 0.03), 5)
				b.blob("in_bois_clair", at + Vector3(0.06, 0.08, sg * 1.3), Vector3(0.05, 0.04, 0.04), 5)
			b.blob(k1, at + Vector3(0.02, 0.22, 0), Vector3(0.09, 0.02, 0.09), 6)
		1:                                            # un nain de jardin
			b.blob(k2, at + Vector3(0, 0.1, 0), Vector3(0.08, 0.1, 0.08), 8)
			b.blob("sakura", at + Vector3(0, 0.23, 0), Vector3(0.06, 0.06, 0.06), 8)
			b.blob("peinture_blanche", at + Vector3(0.03, 0.19, 0), Vector3(0.05, 0.05, 0.05), 6)
			b.cyl_at("plastique_rouge", at + Vector3(0, 0.27, 0), 0.06, 0.005, 0.16, 8)
		2:                                            # une valise
			b.box(k1, Transform3D(Basis(), at + Vector3(0, 0.17, 0)), Vector3(0.18, 0.34, 0.46))
			b.box("in_inox", Transform3D(Basis(), at + Vector3(0, 0.36, 0)), Vector3(0.03, 0.04, 0.14))
		3:                                            # un cactus en pot
			b.cyl_at("in_pot", at, 0.07, 0.09, 0.1, 8)
			b.blob("tissu_vert", at + Vector3(0, 0.24, 0), Vector3(0.06, 0.15, 0.06), 8)
			b.blob("tissu_vert", at + Vector3(0, 0.26, 0.08), Vector3(0.03, 0.06, 0.03), 6)
			b.blob("sakura", at + Vector3(0, 0.4, 0), Vector3(0.025, 0.02, 0.025), 5)
		4:                                            # un globe
			b.cyl_at("in_bois", at, 0.08, 0.06, 0.03, 8)
			b.cyl_at("in_inox", at, 0.008, 0.008, 0.12, 4)
			b.blob("plastique_bleu", at + Vector3(0, 0.22, 0), Vector3(0.12, 0.12, 0.12), 10)
			b.blob("tissu_vert", at + Vector3(0.05, 0.25, 0.04), Vector3(0.075, 0.06, 0.07), 6)
		5:                                            # une théière
			b.blob(k2, at + Vector3(0, 0.09, 0), Vector3(0.1, 0.09, 0.1), 8)
			b.tube(k2, at + Vector3(0, 0.1, 0.09), at + Vector3(0, 0.17, 0.17), 0.015, 5)
			b.cyl_at(k2, at + Vector3(0, 0.17, 0), 0.03, 0.015, 0.03, 6)
		6:                                            # un chapeau
			b.cyl_at("in_noir" if n % 2 == 0 else "in_bois_clair", at, 0.17, 0.17, 0.012, 14)
			b.cyl_at("in_noir" if n % 2 == 0 else "in_bois_clair", at, 0.1, 0.09, 0.13, 12)
			b.cyl_at(k1, at + Vector3(0, 0.012, 0), 0.102, 0.102, 0.03, 12)
		7:                                            # une cage à oiseau (et son pigeon, bien sûr)
			b.cyl_at("in_inox", at, 0.13, 0.13, 0.015, 10)
			for a in range(8):
				b.tube("in_inox", at + Vector3(cos(a * TAU / 8.0) * 0.12, 0.0, sin(a * TAU / 8.0) * 0.12), at + Vector3(0, 0.38, 0), 0.004, 3)
			b.blob("in_tissu_gris", at + Vector3(0, 0.08, 0), Vector3(0.05, 0.045, 0.07), 6)
			b.blob("in_tissu_gris", at + Vector3(0, 0.14, 0.05), Vector3(0.025, 0.025, 0.025), 5)
		8:                                            # un ballon
			b.blob(k1, at + Vector3(0, 0.12, 0), Vector3(0.12, 0.12, 0.12), 10)
			b.blob("peinture_blanche", at + Vector3(0.02, 0.14, 0.02), Vector3(0.105, 0.105, 0.105), 6)
		9:                                            # une horloge (elle fait tic-tac)
			b.box("in_bois", Transform3D(Basis(), at + Vector3(0, 0.15, 0)), Vector3(0.1, 0.3, 0.2))
			b.cyl("peinture_blanche", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), at + Vector3(0.055, 0.2, 0)), 0.07, 0.07, 0.01, 12)
			b.box("in_noir", Transform3D(Basis(), at + Vector3(0.062, 0.22, 0.0)), Vector3(0.004, 0.05, 0.008))
		10:                                           # une pile de livres
			for i in range(4):
				b.box(str(c[(n + i) % c.size()]), Transform3D(Basis(Vector3.UP, i * 0.3), at + Vector3(0, 0.02 + i * 0.04, 0)), Vector3(0.16, 0.035, 0.22))
		_:                                            # un colis, tout simplement
			_carton(b, Transform3D(Basis(Vector3.UP, n * 0.4), at + Vector3(0, 0.13, 0)), Vector3(0.28, 0.26, 0.3))


# ------------------------------------------------------------------ le 11e : la météo du ciel
func _meteo() -> String:
	var core: Rect2 = T.info["core"]
	var cx0: float = core.position.x - X0
	var cx1: float = core.end.x - X0
	var cz0: float = core.position.y - Z0
	var cz1: float = core.end.y - Z0
	var cm: float = (cz0 + cz1) * 0.5
	var mx: float = W * 0.5
	# ---- la table de l'archipel (à l'ouest) : les îles en petit, qui flottent ; leurs nuages qui tournent
	var ax: float = 2.4
	var az: float = cm
	b.cyl_at("in_noir", _p(ax, 0.0, az), 1.5, 1.6, 0.7, 28)
	b.cyl_at("eau", _p(ax, 0.7, az), 1.45, 1.45, 0.02, 28)
	b.cyl_at("neon_cyan", _p(ax, 0.68, az), 1.52, 1.52, 0.015, 28)
	T._col(_p(ax, 0.5, az), Vector3(3.0, 1.0, 3.0))
	var iles: Array = [[0.0, 0.0, 0.34, "herbe", "L'île du Départ"], [0.75, -0.5, 0.26, "k187_allege", "Néopolis"], [-0.7, 0.55, 0.24, "tissu_jaune", "Tazira"], [0.5, 0.8, 0.2, "tissu_vert", "Ramure"],
		[-0.85, -0.5, 0.22, "pierre", "Montjoie"], [0.1, -0.95, 0.18, "sakura", "Les Fées"]]
	for i in range(iles.size()):
		var q: Array = iles[i]
		var lot := Kit.Batch.new()
		lot.blob("pierre", Vector3(0, -0.06, 0), Vector3(float(q[2]) * 0.8, 0.14, float(q[2]) * 0.8), 8)
		lot.cyl(str(q[3]), Transform3D(Basis(), Vector3(0, 0.01, 0)), float(q[2]), float(q[2]) * 0.85, 0.05, 12)
		if i == 1:
			for j in range(6):
				lot.box("k187_bardage", Transform3D(Basis(), Vector3(cos(j * 1.1) * 0.12, 0.08 + (j % 3) * 0.03, sin(j * 1.1) * 0.12)), Vector3(0.05, 0.12 + (j % 3) * 0.06, 0.05))
			lot.box("neon_cyan", Transform3D(Basis(), Vector3(0, 0.29, 0)), Vector3(0.03, 0.01, 0.03))
		else:
			lot.blob("tissu_vert" if i != 2 else "k187_orange", Vector3(0.05, 0.08, 0.02), Vector3(float(q[2]) * 0.4, 0.06, float(q[2]) * 0.35), 6)
		var mi := MeshInstance3D.new()
		mi.mesh = _maillage(lot)
		_anime().add_child(mi)
		var pos: Vector3 = _p(ax + float(q[0]), 1.15 + (i % 3) * 0.12, az + float(q[1]))
		mi.global_position = pos
		_anime().flotte.append([mi, pos, 0.04, 0.8 + i * 0.13, i * 1.7])
		b.cyl_at("neon_cyan", _p(ax + float(q[0]), 0.72, az + float(q[1])), 0.004, 0.004, 0.36 + (i % 3) * 0.12, 3)
		var li: Label3D = _texte(str(q[4]), 14, Color(0.7, 0.95, 1.0), pos + Vector3(0, 0.3, 0), Vector3(1, 0, 0))
		li.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var ciel := Node3D.new()
	_anime().add_child(ciel)
	ciel.global_position = _p(ax, 1.75, az)
	for i2 in range(5):
		var lotn := Kit.Batch.new()
		for j2 in range(4):
			lotn.blob("peinture_blanche", Vector3(j2 * 0.1 - 0.15, (j2 % 2) * 0.04, (j2 % 3) * 0.05), Vector3(0.11, 0.07, 0.09), 6)
		var nu := MeshInstance3D.new()
		nu.mesh = _maillage(lotn)
		ciel.add_child(nu)
		nu.position = Vector3(cos(i2 * TAU / 5.0) * (0.6 + (i2 % 2) * 0.5), (i2 % 3) * 0.1, sin(i2 * TAU / 5.0) * (0.6 + (i2 % 2) * 0.5))
	_anime().tourne.append([ciel, 0.18])
	_gens("femme", ax + 2.0, az + 0.9, Vector3(-1, 0, -0.3).normalized(), "bras_croises", L_METEO, false, true)
	# ---- les instruments (au nord, face au large) : l'anémomètre, la girouette, la longue-vue, le ballon-sonde
	var ix: float = 1.6
	b.cyl_at("in_inox", _p(ix, 0.0, 1.3), 0.2, 0.2, 0.03, 12)
	b.cyl_at("in_inox", _p(ix, 0.0, 1.3), 0.025, 0.025, 1.7, 8)
	var lota := Kit.Batch.new()
	for a in range(3):
		var d := Vector3(cos(a * TAU / 3.0), 0, sin(a * TAU / 3.0))
		lota.tube("in_inox", Vector3.ZERO, d * 0.3, 0.008, 4)
		lota.blob("plastique_rouge" if a == 0 else "in_noir", d * 0.33, Vector3(0.06, 0.06, 0.06), 8)
	var ane := MeshInstance3D.new()
	ane.mesh = _maillage(lota)
	_anime().add_child(ane)
	ane.global_position = _p(ix, 1.72, 1.3)
	_anime().tourne.append([ane, 3.5])
	b.cyl_at("in_inox", _p(ix + 1.3, 0.0, 1.0), 0.16, 0.16, 0.03, 12)
	b.cyl_at("in_inox", _p(ix + 1.3, 0.0, 1.0), 0.02, 0.02, 1.9, 8)
	b.tube("in_noir", _p(ix + 1.0, 1.9, 1.15), _p(ix + 1.6, 1.9, 0.85), 0.012, 5)
	b.box("k187_orange", Transform3D(Basis(Vector3.UP, 0.46), _p(ix + 1.08, 1.9, 1.11)), Vector3(0.22, 0.14, 0.01))
	b.cyl_at("in_noir", _p(ix + 1.63, 1.86, 0.83), 0.0, 0.035, 0.08, 6)
	for a3 in range(3):
		var an: float = a3 * TAU / 3.0 + 0.5
		b.tube("in_bois", _p(mx + 3.0, 1.25, 1.1), _p(mx + 3.0 + cos(an) * 0.42, 0.0, 1.1 + sin(an) * 0.42), 0.016, 5)
	b.tube("chrome", _p(mx + 3.0, 1.22, 1.35), _p(mx + 3.0, 1.46, 0.55), 0.045, 10)
	T._col(_p(mx + 3.0, 0.7, 1.1), Vector3(0.7, 1.4, 0.8))
	# le ballon-sonde, retenu par sa ficelle, sa petite nacelle d'instruments
	var bx: float = W - 1.8
	var ballon := MeshInstance3D.new()
	var lotb := Kit.Batch.new()
	lotb.blob("peinture_blanche", Vector3(0, 0.55, 0), Vector3(0.55, 0.62, 0.55), 14)
	lotb.cyl("peinture_blanche", Transform3D(Basis(), Vector3(0, -0.08, 0)), 0.04, 0.12, 0.12, 8)
	lotb.cyl("in_noir", Transform3D(Basis(), Vector3(0, -0.5, 0)), 0.003, 0.003, 0.9, 3)
	lotb.box("k187_orange", Transform3D(Basis(), Vector3(0, -1.0, 0)), Vector3(0.16, 0.12, 0.16))
	lotb.box("neon_rouge", Transform3D(Basis(), Vector3(0, -1.07, 0)), Vector3(0.03, 0.02, 0.03))
	ballon.mesh = _maillage(lotb)
	_anime().add_child(ballon)
	ballon.global_position = _p(bx, 2.0, 1.6)
	_anime().flotte.append([ballon, _p(bx, 2.0, 1.6), 0.08, 0.7, 0.0])
	b.cyl_at("in_noir", _p(bx, 0.0, 1.6), 0.003, 0.003, 0.95, 3)
	_bx("in_inox", bx - 0.2, bx + 0.2, 0.0, 0.06, 1.4, 1.8)
	_texte("Départ à midi. Pigeon à midi cinq.", 16, Color(0.9, 0.95, 1.0), _p(bx - 0.6, 0.35, 1.9), Vector3(-0.7, 0, 0.7).normalized())
	_gens("homme", mx + 3.0, 2.0, Vector3(0, 0, -1), "debout", L_METEO)
	# ---- le mur des cadrans (sur le cœur, à l'ouest) : le vent, la pression, l'humeur du ciel
	_bx("in_bois", cx0 - 0.05, cx0, 0.9, 2.6, cz0 + 0.25, cz1 - 0.25)
	var cad: Array = ["Vent", "Pression", "Pluie", "Pigeons", "Humeur du ciel", "Nuages"]
	for i3 in range(6):
		var dz: float = cz0 + 0.85 + (i3 % 3) * 1.1
		var dh: float = 2.1 - (0.75 if i3 >= 3 else 0.0)
		b.cyl("in_inox", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(cx0 - 0.07, dh, dz)), 0.27, 0.27, 0.04, 20)
		b.cyl("peinture_blanche", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(cx0 - 0.095, dh, dz)), 0.24, 0.24, 0.01, 20)
		var na: float = rng.randf_range(-1.2, 1.2)
		b.tube("plastique_rouge", _p(cx0 - 0.105, dh, dz), _p(cx0 - 0.105, dh + cos(na) * 0.2, dz + sin(na) * 0.2), 0.008, 4)
		b.blob("in_noir", _p(cx0 - 0.105, dh, dz), Vector3(0.02, 0.02, 0.02), 5)
		for t in range(9):
			var ta: float = -1.4 + t * 0.35
			b.box("in_noir", Transform3D(Basis(Vector3(1, 0, 0), -ta), _p(cx0 - 0.102, dh + cos(ta) * 0.2, dz + sin(ta) * 0.2)), Vector3(0.002, 0.03, 0.006))
		_texte(str(cad[i3]), 14, Color(0.95, 0.9, 0.8), _p(cx0 - 0.06, dh - 0.33, dz), Vector3(-1, 0, 0))
	# ---- le studio du bulletin (à l'est) : le mur vert, la caméra, la carte, la présentatrice
	_bx("tissu_vert", W - 0.5, W - 0.44, 0.0, 2.7, cz0 - 0.6, cz1 + 0.6)
	_bx("tissu_vert", W - 2.6, W - 0.44, 0.0, 0.012, cz0 - 0.6, cz1 + 0.6)
	_gens("femme", W - 1.4, cm, Vector3(-1, 0, 0), "debout", L_METEO, false, true)
	for a4 in range(3):
		var an2: float = a4 * TAU / 3.0 + 0.2
		b.tube("in_noir", _p(W - 4.0, 1.3, cm), _p(W - 4.0 + cos(an2) * 0.45, 0.0, cm + sin(an2) * 0.45), 0.018, 5)
	_bx("in_noir", W - 4.2, W - 3.75, 1.3, 1.6, cm - 0.14, cm + 0.14)
	b.cyl("in_noir", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(W - 3.65, 1.45, cm)), 0.09, 0.07, 0.2, 10)
	b.cyl("verre_fume", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), _p(W - 3.54, 1.45, cm)), 0.075, 0.075, 0.01, 10)
	_bx("neon_rouge", W - 4.0, W - 3.96, 1.6, 1.64, cm - 0.02, cm + 0.02)
	T._col(_p(W - 4.0, 0.8, cm), Vector3(0.8, 1.6, 0.8))
	for sp in [cm - 1.7, cm + 1.7]:                   # (les deux projecteurs)
		b.cyl_at("in_noir", _p(W - 3.4, 0.0, sp), 0.015, 0.015, 2.1, 6)
		b.cyl_at("in_noir", _p(W - 3.4, 0.0, sp), 0.2, 0.2, 0.02, 10)
		b.box("in_noir", Transform3D(Basis(Vector3.UP, 0.5 if sp < cm else -0.5), _p(W - 3.4, 2.15, sp)), Vector3(0.12, 0.3, 0.4))
		b.box("lampe_blanche", Transform3D(Basis(Vector3.UP, 0.5 if sp < cm else -0.5), _p(W - 3.33, 2.15, sp)), Vector3(0.02, 0.26, 0.36))
	_bx("in_noir", cx1, cx1 + 0.05, 1.0, 2.5, cz0 + 0.3, cz1 - 0.3)
	var carte := ShaderMaterial.new()
	carte.shader = load("res://shaders/carte_v188.gdshader")
	if ResourceLoader.exists(TEX + "carte_vols.png"):
		carte.set_shader_parameter("image", load(TEX + "carte_vols.png"))
	carte.set_shader_parameter("fenetre", Vector4(0.27, 0.0, 0.32, 1.0))
	var qc := QuadMesh.new()
	qc.size = Vector2(1.9, 1.4)
	var ec := MeshInstance3D.new()
	ec.mesh = qc
	ec.material_override = carte
	(T.get("_node") as Node3D).add_child(ec)
	ec.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), _p(cx1 + 0.06, 1.75, cm))
	# ---- le bulletin du jour (au sud) : le grand panneau, les bureaux des prévisionnistes
	_bx("in_noir", mx + 1.2, mx + 5.4, 0.9, 2.5, D - 0.5, D - 0.44)
	_texte("LE BULLETIN DU CIEL", 40, Color(0.4, 0.95, 1.0), _p(mx + 3.3, 2.25, D - 0.52), Vector3(0, 0, -1))
	var bul: Array = ["Aujourd'hui : beau. Vent de nord-ouest.", "Demain : beau. Vent de nord-ouest.", "Après-demain : surprise (vent de nord-ouest).", "Risque de pigeon : élevé."]
	for i4 in range(bul.size()):
		_texte(str(bul[i4]), 22, Color(0.95, 0.95, 1.0) if i4 < 3 else Color(1.0, 0.6, 0.3), _p(mx + 3.3, 1.9 - i4 * 0.25, D - 0.52), Vector3(0, 0, -1))
	for i5 in range(2):
		var dx: float = 1.6 if i5 == 0 else mx - 1.6
		T._poste(b, _p(dx, 0.0, D - 1.3), Vector3(0, 0, 1), rng)
		T._col(_p(dx, 0.4, D - 1.3), Vector3(1.5, 0.8, 0.75))
		if i5 == 0:
			_gens("homme", dx, D - 2.0, Vector3(0, 0, 1), "assis", L_METEO)
	_plante_pot(W - 0.8, D - 0.8, 1.3)
	_plante_pot(0.8, 0.8, 1.2, true)
	return ""


## Un établi de la clinique (le mécano est au sud, il regarde le nord) : le plateau, le panneau d'outils, la
## lampe, un drone ouvert, le tabouret.
func _etabli(lx: float, lz: float, n: int) -> void:
	_bx("in_bois", lx - 0.95, lx + 0.95, 0.86, 0.92, lz - 0.42, lz + 0.42, true)
	for q in [[lx - 0.9, lz - 0.37], [lx + 0.9, lz - 0.37], [lx - 0.9, lz + 0.37], [lx + 0.9, lz + 0.37]]:
		_bx("in_inox", q[0] - 0.025, q[0] + 0.025, 0.0, 0.86, q[1] - 0.025, q[1] + 0.025)
	_bx("in_inox", lx - 0.9, lx + 0.9, 0.25, 0.28, lz - 0.37, lz + 0.37)
	_bx("plastique_rouge", lx - 0.8, lx - 0.3, 0.28, 0.5, lz - 0.25, lz + 0.2)                # (la caisse à outils)
	_bx("in_mur_gris", lx - 0.95, lx + 0.95, 0.92, 1.7, lz - 0.42, lz - 0.38)
	var cles: Array = ["in_inox", "plastique_rouge", "k187_orange", "plastique_bleu", "in_noir", "peinture_jaune"]
	for i in range(9):
		var tx: float = lx - 0.8 + i * 0.2
		var tl: float = 0.16 + ((i * 7 + n) % 4) * 0.06
		_bx(cles[(i + n) % cles.size()], tx - 0.02, tx + 0.02, 1.58 - tl, 1.58, lz - 0.38, lz - 0.36)
		_bx("in_inox", tx - 0.03, tx + 0.03, 1.58, 1.61, lz - 0.38, lz - 0.355)
	_bx("in_inox", lx - 0.9, lx + 0.9, 1.06, 1.08, lz - 0.38, lz - 0.26)                       # (la tablette des petites pièces)
	for i2 in range(5):
		_bx(["plastique_bleu", "tissu_jaune", "plastique_rouge", "tissu_vert", "k187_orange"][(i2 + n) % 5], lx - 0.8 + i2 * 0.34, lx - 0.56 + i2 * 0.34, 1.08, 1.16, lz - 0.37, lz - 0.27)
	# la lampe d'atelier, sur son bras
	b.tube("in_noir", _p(lx + 0.8, 0.92, lz - 0.2), _p(lx + 0.7, 1.4, lz - 0.15), 0.012, 5)
	b.tube("in_noir", _p(lx + 0.7, 1.4, lz - 0.15), _p(lx + 0.35, 1.5, lz + 0.05), 0.012, 5)
	b.cyl_at("in_noir", _p(lx + 0.35, 1.42, lz + 0.05), 0.09, 0.05, 0.09, 10)
	b.cyl_at("lampe_blanche", _p(lx + 0.35, 1.41, lz + 0.05), 0.075, 0.075, 0.012, 10)
	# le drone sur l'établi : entier, ou ouvert (les hélices à côté, le capot ôté)
	if n % 2 == 0:
		_drone(b, _p(lx - 0.1, 1.14, lz + 0.05), 0.5 + n, false, 1.15)
	else:
		_bx("peinture_blanche", lx - 0.4, lx + 0.15, 0.92, 1.02, lz - 0.12, lz + 0.22)
		_bx("in_noir", lx - 0.35, lx + 0.1, 1.02, 1.03, lz - 0.08, lz + 0.18)
		for j in range(3):
			b.tube(["plastique_rouge", "peinture_jaune", "plastique_bleu"][j], _p(lx - 0.25 + j * 0.12, 1.035, lz - 0.05), _p(lx - 0.2 + j * 0.1, 1.035, lz + 0.15), 0.008, 4)
		_bx("k187_orange", lx + 0.3, lx + 0.6, 0.92, 0.95, lz - 0.05, lz + 0.15)
		for j2 in range(3):
			b.cyl_at("verre_fume", _p(lx + 0.55 + (j2 % 2) * 0.12, 0.92 + j2 * 0.012, lz + 0.25 - j2 * 0.03), 0.2, 0.2, 0.01, 12)
	b.cyl_at("in_inox", _p(lx - 0.6, 0.92, lz + 0.2), 0.04, 0.04, 0.1, 8)                     # (la tasse)
	# le tabouret
	b.cyl_at("in_inox", _p(lx + 1.3, 0.0, lz + 0.9), 0.02, 0.02, 0.55, 6)
	b.cyl_at("in_noir", _p(lx + 1.3, 0.55, lz + 0.9), 0.16, 0.16, 0.05, 12)


# =================================================================== les drones (comme dehors)

func _drone(lot: Kit.Batch, at: Vector3, yaw: float, colis: bool, s: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), at)
	lot.box("peinture_blanche", xf, Vector3(0.5, 0.13, 0.32))
	lot.box("k187_orange", xf * Transform3D(Basis(), Vector3(0.0, 0.075, 0.0)), Vector3(0.3, 0.03, 0.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var e := Vector3(sx * 0.42, 0.04, sz * 0.34)
			lot.tube("metal_noir", xf * Vector3(sx * 0.2, 0.0, sz * 0.12), xf * e, 0.022 * s, 5)
			lot.cyl("metal_noir", xf * Transform3D(Basis(), e), 0.04, 0.04, 0.06, 6)
			lot.cyl("verre_fume", xf * Transform3D(Basis(), e + Vector3(0, 0.065, 0)), 0.21, 0.21, 0.01, 12)
		lot.tube("metal_noir", xf * Vector3(sx * 0.16, -0.06, -0.1), xf * Vector3(sx * 0.2, -0.2, -0.1), 0.012 * s, 4)
		lot.tube("metal_noir", xf * Vector3(sx * 0.16, -0.06, 0.1), xf * Vector3(sx * 0.2, -0.2, 0.1), 0.012 * s, 4)
	lot.blob("neon_cyan", xf * Vector3(0.26, 0.0, 0.0), Vector3(0.035, 0.035, 0.05) * s, 5)
	lot.blob("neon_rouge", xf * Vector3(-0.26, 0.0, 0.0), Vector3(0.03, 0.03, 0.04) * s, 5)
	if colis:
		_carton(lot, xf * Transform3D(Basis(), Vector3(0.0, -0.2, 0.0)), Vector3(0.28, 0.22, 0.24))


func _maillage(lot: Kit.Batch) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for k in lot.sts:
		var st: SurfaceTool = lot.sts[k]
		st.index()
		st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, Kit.mat(str(k)))
	lot.sts.clear()
	return mesh

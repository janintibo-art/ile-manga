extends Node3D
## Extension « Le Château d'Ombrelac » (v16) : les quêtes des habitants de l'Académie, et le secret de la
## fontaine du cloître.
##  - six quêtes, chacune partie d'une rumeur qu'on entend déjà au château : la chaussette de Tobie (sur la
##    girouette de l'horloge), le pari du miel (Maître Rouage et Maître Fauconnier), l'élixir de rire
##    (Sidonie et Maître Équerre), la grande fougère (Firmin Buis), le livre bien élevé (Dame Reliure) et la
##    Maison de Minuit (Anatole) ;
##  - les cinq premières donnent chacune un indice de la Minuit ; avec les cinq, la nuit, Hortense (la
##    grenouille de la fontaine) vide le bassin : un escalier descend aux caves de la Minuit
##    (minuit_ombrelac.gd : trois portes à énigmes, le trésor).
## Rien dans les fichiers du jeu : les quêtes passent par ce que le carnet sait déjà lire.
##  - dans le carnet (onglet Quêtes, « Habitants ») : la « quete » du profil de l'habitant (le titre, ce
##    qu'il reste à faire) et sa mémoire (« quete » : "" / "demandee" / "finie"), tenues à jour ici ;
##  - le point d'exclamation au-dessus de sa tête (indicateurs_v130), la question « ★ » dans la
##    conversation : les services du carnet (journal_v56.add_service) ;
##  - ce qu'on fait dans le château (la lunette, la cloche, la paillasse, les livres, la fontaine) : les
##    objets (objets_ombrelac.gd), qui demandent d'abord ici (intercepte) ; les objets propres aux quêtes
##    (Hortense, la chaussette tombée, les racines, l'escalier, les énigmes des caves) : objets.ajouter().
## L'état : ombrelac.state["quetes"] (enregistré avec la partie).

const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")
const Societe = preload("res://scripts/pnj/societe_v65.gd")

const ORDRE := ["chaussette", "miel", "elixir", "fougere", "livre", "minuit"]
const INDICES := ["chaussette", "miel", "elixir", "fougere", "livre"]

## Les quêtes : qui la donne, le titre, ce qu'il reste à faire à chaque étape (dans le carnet), ce que
## dit l'habitant quand on lui demande où on en est, la proposition, la récompense, l'indice
const Q := {
	"chaussette": {"qui": "tobie_om", "titre": "La chaussette de Tobie",
		"etapes": ["la chaussette perdue (la repérer à la Grande Lunette de l'Observatoire)",
			"la chaussette perdue (la faire tomber de la girouette : la cloche de l'horloge ?)",
			"la chaussette perdue (la ramasser au pied de la Tour de l'Horloge)",
			"la chaussette retrouvée (la rendre à Tobie)"],
		"rappels": ["Tu as regardé à la Grande Lunette ? Elle est tout en haut de la Tour de l'Astrolabe, sur la terrasse de l'Observatoire.",
			"Il faudrait secouer la girouette… La cloche ! Quand elle sonne, toute la tour tremble. La corde pend dans la Chambre des Rouages.",
			"Elle est tombée ? Elle doit être au pied de la Tour de l'Horloge. Vite, avant que Maître Rouage la trouve !",
			"Tu l'as ? Tu l'as ?!"],
		"offre_label": "★ Ta chaussette est encore sur la girouette ?",
		"offre": "Chut ! Pas si fort… Oui. Encore. La gauche, celle à rayures bleues et or. Je ne sais pas comment elle monte là-haut, je te jure ! Si Maître Rouage la trouve, il va encore l'écrire dans son registre. Tu m'aides à la récupérer ? De la Grande Lunette, à l'Observatoire, on voit la girouette comme si on y était.",
		"accepte": "Merci ! Je te dois un croissant. Deux, même. Va voir à la Grande Lunette, tout en haut de la Tour de l'Astrolabe.",
		"refuse": "Bon… Si tu changes d'avis, je serai en train de faire semblant de ne pas avoir froid au pied.",
		"rendre_label": "★ Voici ta chaussette !",
		"fin": "MA CHAUSSETTE ! Merci, merci ! … Attends. Elle est brodée, à l'intérieur. Ce n'est pas moi qui ai fait ça. Un fil d'argent… une lune noire. Anatole dit que c'est le blason des vieilles portes, sous le château. Tiens, prends ça, c'est tout ce que j'ai. Et ne dis rien à Maître Rouage !",
		"recompense": [["piece", 6], ["croissant", 2]],
		"indice": "Une lune noire brodée d'argent : le blason de la Maison de Minuit."},
	"miel": {"qui": "rouage_om", "titre": "Le pari du miel",
		"etapes": ["l'heure des étoiles (la relever à la Grande Lunette, la nuit)",
			"l'heure des étoiles (la porter à Maître Fauconnier)",
			"un pot de miel pour sceller le pari (Mère Fournil en garde un)",
			"un pot de miel (le porter à Maître Rouage)"],
		"rappels": ["La Grande Lunette, la nuit. Le jour, on n'y voit que des pigeons.",
			"Porte l'heure des étoiles à Maître Fauconnier. Il est souvent à l'Observatoire, ou dans la Salle des Astres.",
			"Il faut un pot de miel pour sceller la fin du pari. Mère Fournil en garde toujours un, près de la cheminée de la Grande Salle.",
			"Alors, ce miel ? Je l'entends presque cristalliser."],
		"offre_label": "★ Et ce fameux pari du miel ?",
		"offre": "Le pari ! Onze ans que ça dure. Fauconnier dit que ses étoiles donnent l'heure exacte. Moi, je dis que c'est mon horloge. Et chaque jeudi, mon horloge avance d'une minute, et il me nargue. Tu veux trancher ? Relève l'heure des étoiles à la Grande Lunette, une nuit, et porte-la à Fauconnier : il fera ses calculs. Puis on scellera la fin du pari avec un pot de miel, comme il se doit.",
		"accepte": "Parfait. La Grande Lunette, de nuit. Et ne laisse pas Fauconnier tricher : il compte sur ses doigts quand il croit qu'on ne le voit pas.",
		"refuse": "Hm. Le pari attendra. Il a l'habitude.",
		"rendre_label": "★ Le pari est tranché : voici le miel.",
		"fin": "Une minute pour la Minuit… et un treizième coup à minuit ! Je savais bien qu'il y avait un rouage de trop dans mon horloge. Je n'ai jamais osé l'enlever. Égalité, donc. Le miel, on le mangera à deux, comme d'habitude. Merci ! Tiens : un rouage de bronze, et une pièce d'or pour l'arbitre.",
		"recompense": [["rouage", 1], ["piece_or", 1]],
		"indice": "Le treizième coup de minuit est l'heure de la Minuit : l'heure que l'horloge oublie."},
	"elixir": {"qui": "sidonie_om", "titre": "L'élixir de rire",
		"etapes": ["les ingrédients de l'élixir de rire (une fleur de lune, une plume de chouette, une fiole de cristal)",
			"l'élixir de rire (le préparer à une paillasse de la Salle des Élixirs)",
			"l'élixir de rire (le faire goûter à Maître Équerre)",
			"des nouvelles de Maître Équerre (les raconter à Sidonie)"],
		"rappels": ["Il te faut une fleur de lune (demande à Firmin), une plume de chouette (Maître Fauconnier) et une fiole de cristal (Maîtresse Alambic).",
			"Maintenant, prépare-le à une paillasse de la Salle des Élixirs. Trois tours de cuillère, pas un de plus.",
			"Fais-le goûter à Maître Équerre. Une seule goutte !",
			"Alors ? Il a ri ? Combien de temps ?"],
		"offre_label": "★ Ton élixir de rire, tu sais encore le faire ?",
		"offre": "Chut ! Depuis que Maître Équerre en a goûté, il me demande la recette « pour la ranger ». Je crois qu'il veut rire encore. Mais il me faut une fleur de lune, une plume de chouette et une fiole de cristal. Tu me les trouves ? Firmin a des fleurs de lune, Maître Fauconnier garde les plumes de la chouette de l'Observatoire, et Maîtresse Alambic a des fioles. Ensuite, il faudra le préparer à une paillasse de la Salle des Élixirs.",
		"accepte": "Super ! Et surtout, ne secoue jamais la fiole. J'ai appris ça le jour où Malo a ri pendant deux jours.",
		"refuse": "D'accord… Je garde le secret de la recette, alors.",
		"rendre_label": "★ Maître Équerre a ri… et il a dit quelque chose d'étrange.",
		"fin": "Il a ri ? Combien de temps ? … Une devise de la Minuit ? « Trois fois à angle droit »… Anatole va devenir fou. Merci ! Tiens, deux potions de magie : ce sont mes ratés, mais ils marchent très bien.",
		"recompense": [["potion_mana", 2]],
		"indice": "« Trois fois à angle droit, jusqu'à ce que la Minuit te regarde. »"},
	"fougere": {"qui": "buis_om", "titre": "La fougère géante",
		"etapes": ["les racines de la grande fougère (les examiner à la serre du fond, la nuit)",
			"le bruit de l'eau (écouter la fontaine du cloître)",
			"ce que tu as entendu (le raconter à Firmin)"],
		"rappels": ["Les racines de la grande fougère, côté ouest de la serre du fond. La nuit : le jour, elle fait semblant de dormir.",
			"Les racines filent vers le nord, vers le cloître ? Alors écoute la fontaine. Penche-toi au-dessus du bassin.",
			"Alors ? Qu'est-ce que tu as entendu ?"],
		"offre_label": "★ La grande fougère a encore grandi ?",
		"offre": "D'un mètre en une nuit, et elle continue. Ce n'est pas naturel. Une fougère, ça pousse doucement, ça a le temps. Celle-là a l'air pressée. J'ai vu ses racines sortir de la serre… Tu voudrais bien les examiner, la nuit ? Le jour, elle fait semblant de dormir.",
		"accepte": "Merci. La serre du fond, celle qui est le plus au nord. Les racines sortent du côté ouest. Et marche doucement : les fleurs ont peur.",
		"refuse": "Bon. Je la mesurerai encore demain. Et Maître Équerre aussi. Trois fois.",
		"rendre_label": "★ J'ai entendu de l'eau, sous la fontaine.",
		"fin": "Sous la fontaine… Alors c'est là qu'elle boit, ma fougère : dans une eau qui remonte d'en dessous. Une eau qui a connu la Minuit, si les vieilles histoires disent vrai. Ma grand-mère disait : « Rends l'eau à sa source, et le chemin s'ouvrira. » Merci. Tiens : deux fleurs de lune, et la sève de ma meilleure plante.",
		"recompense": [["fleur_lune", 2], ["potion_seve", 1]],
		"indice": "Rends l'eau de la fontaine à sa source, et le chemin s'ouvrira."},
	"livre": {"qui": "reliure_om", "titre": "Le livre bien élevé",
		"etapes": ["le livre bien élevé (le chercher dans les rayonnages de la Bibliothèque)",
			"le Journal de la Maison de Minuit (le rapporter à Dame Reliure)"],
		"rappels": ["Il est dans un rayonnage de la Bibliothèque. Prenez des livres, changez de rayon : il finira par se montrer.",
			"Vous l'avez ? Ne le lâchez pas : il retournerait à sa place."],
		"offre_label": "★ Ce livre qui se range tout seul, c'est lequel ?",
		"offre": "Vous aussi ? Bien. Je ne le dirai pas. Mais si vous le trouviez vous-même… ce serait différent. Il se cache dans les rayonnages de la Bibliothèque. Il est bien élevé : quand on le pose ailleurs, il retourne à sa place. Rapportez-le-moi, et je vous dirai pourquoi.",
		"accepte": "Cherchez bien. Et parlez bas : il est timide.",
		"refuse": "Comme vous voudrez. Il ne bougera pas. Enfin, si : mais toujours pour revenir.",
		"rendre_label": "★ Le voici : le Journal de la Maison de Minuit.",
		"fin": "Vous l'avez trouvé. Le journal de la Minuit, la maison qui veillait la nuit. Sa dernière préfète l'a confié à la Bibliothèque il y a deux cents ans, avant que la Minuit ne s'endorme sous le cloître. Écoutez la dernière page : « Nous qui veillons quand tout dort, nous avons pris la chouette pour amie. Qui la reconnaîtra nous trouvera. » … Voilà : il a filé à sa place. Prenez ce grimoire d'apprenti : vous l'avez mérité.",
		"recompense": [["grimoire", 1]],
		"indice": "« Nous qui veillons quand tout dort, nous avons pris la chouette pour amie. »"},
	"minuit": {"qui": "anatole_om", "titre": "La Maison de Minuit",
		"etapes": ["les cinq indices de la Minuit (%d / 5)",
			"le passage secret (parler à Hortense, la grenouille de la fontaine du cloître, la nuit)",
			"le passage secret (descendre l'escalier, sous la fontaine)",
			"le trésor de la Minuit (ouvrir les trois portes des caves)",
			"le trésor de la Minuit (tout raconter à Anatole)"],
		"rappels": ["Il te faut les cinq indices. Écoute les gens : Tobie, Maître Rouage, Sidonie, Firmin, Dame Reliure. Chacun sait un bout de l'histoire sans le savoir.",
			"Les cinq indices ! Va voir Hortense, à la fontaine. La nuit : une gardienne de la Minuit, ça veille la nuit.",
			"Le passage est ouvert ?! Descends ! Qu'est-ce que tu attends ?",
			"Alors, en bas ? Il y a des portes ? Des énigmes ? Un trésor ?",
			"Raconte ! Raconte tout !"],
		"offre_label": "★ Ce passage secret, sous la fontaine…",
		"offre": "Tu me crois, toi ? Il y a un passage sous la fontaine, j'en suis sûr ! La Maison de Minuit dort quelque part en dessous. Mais il faut des indices. Tobie, Sidonie, Firmin, Dame Reliure, Maître Rouage… tout le monde sait un petit bout de l'histoire sans le savoir. Rassemble les cinq indices de la Minuit, puis parle à Hortense, la grenouille. Je suis sûr que c'est elle, la gardienne.",
		"accepte": "Enfin quelqu'un de sérieux ! Si tu trouves la Minuit, je veux tout savoir. TOUT.",
		"refuse": "Tu verras. Un jour, tout le monde me croira.",
		"rendre_label": "★ J'ai trouvé la Maison de Minuit !",
		"fin": "JE LE SAVAIS ! Je le savais, je le savais ! Une cloche, des statues, des roues, un trésor… Tout le monde va me croire, maintenant ! Enfin… tu leur diras, toi. Moi, ils ne me croiront pas. Tiens : c'est ma réserve secrète de pièces. Tu l'as bien mérité.",
		"recompense": [["piece", 10]]},
}

## Les services des autres habitants (des étapes, des ingrédients)
const SERVICES := ["tobie_om", "rouage_om", "fauconnier_om", "fournil_om", "sidonie_om", "alambic_om", "buis_om",
	"equerre_om", "reliure_om", "anatole_om", "vesperine_om", "sortelame_om", "herse_om"]

const HORTENSE_A := 0.35                       # l'angle d'Hortense sur la margelle (repère château)
const DALLE := Vector3(12.7, 0.165, -23.0)     # la dalle qui cache l'escalier, au fond du bassin (sur l'allée, haute de 0.16)
const CHAUSSETTE_HAUT := Vector3(36.35, 57.0, 34.0)
const CHAUSSETTE_SOL := Vector3(37.6, 0.0, 42.8)
const FOUGERE := Vector3(47.3, 0.8, 43.0)      # dans la serre du fond, côté ouest (sur le socle)
const RACINES := Vector3(44.7, 0.0, 43.0)      # là où l'on se tient pour les examiner

var main: Node
var ombrelac: Node
var chateau: Node3D
var vie: Node
var objets: Node
var minuit: Node3D
var cours: Node                         # (v17) les cours de l'Académie (cours_ombrelac.gd) : leurs sujets passent par ici
var creatures: Node                     # (v18) les créatures (creatures_ombrelac.gd) : le fantôme, chez Gaspard Herse
var hortense: Node3D
var chaussette_haut: Node3D
var chaussette_sol: Node3D
var dalle: Node3D
var trou: Node3D
var eau_surfaces: Array = []
var eau_mesh: MeshInstance3D
var eau_mat: StandardMaterial3D
var ouverte: bool = false               # l'escalier de la fontaine est ouvert (le bassin vide)
var _services_ok: bool = false
var _t: float = 0.0
var _t_fermer: float = -1.0
var _rng := RandomNumberGenerator.new()


# =================================================================== construire

func build(the_main: Node, the_ombrelac: Node, the_chateau: Node3D, the_vie: Node, the_objets: Node) -> void:
	main = the_main
	ombrelac = the_ombrelac
	chateau = the_chateau
	vie = the_vie
	objets = the_objets
	top_level = true
	_rng.randomize()
	minuit = preload("res://scripts/ext_chateau/minuit_ombrelac.gd").new()
	chateau.add_child(minuit)
	minuit.build(main, ombrelac, chateau)
	_hortense()
	_chaussettes()
	_fougere()
	_fontaine()
	_objets()
	if objets != null:
		objets.quetes = self
	_decor()


func _xf() -> Transform3D:
	return chateau.global_transform if chateau.is_inside_tree() else chateau.transform


func monde(p: Vector3) -> Vector3:
	return _xf() * p


func _sol(p: Vector3) -> float:
	var ile: Variant = ombrelac.get("ile") if ombrelac != null else null
	var w: Vector3 = monde(p)
	if ile != null and ile.has_method("height"):
		return maxf(float(ile.height(w.x, w.z)), w.y)
	return w.y


func _mat(c: Color, rough: float = 0.6, em: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if em > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = em
	return m


func _boule(parent: Node3D, r: float, p: Vector3, m: Material, s: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	mi.scale = s
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


## Hortense : une grenouille verte, assise sur la margelle, qui regarde dehors
func _hortense() -> void:
	hortense = Node3D.new()
	hortense.name = "Hortense"
	add_child(hortense)
	var d := Vector3(cos(HORTENSE_A), 0, sin(HORTENSE_A))
	var p: Vector3 = Vector3(10.0, 0.0, -23.0) + d * 4.05
	hortense.position = monde(p + Vector3(0, 0.88, 0))
	hortense.basis = _xf().basis.orthonormalized() * Basis(Vector3.UP, atan2(d.x, d.z))
	var vert := _mat(Color(0.28, 0.5, 0.18), 0.35)
	var ventre := _mat(Color(0.78, 0.8, 0.5), 0.5)
	_boule(hortense, 0.13, Vector3(0, 0.08, 0), vert, Vector3(1.0, 0.7, 1.15))
	_boule(hortense, 0.09, Vector3(0, 0.07, 0.06), ventre, Vector3(1.1, 0.7, 1.0))
	for sx in [-1.0, 1.0]:
		_boule(hortense, 0.042, Vector3(sx * 0.06, 0.17, 0.07), vert)
		_boule(hortense, 0.03, Vector3(sx * 0.065, 0.185, 0.095), _mat(Color(0.95, 0.8, 0.25), 0.2))
		_boule(hortense, 0.014, Vector3(sx * 0.068, 0.188, 0.12), _mat(Color(0.02, 0.02, 0.02), 0.1))
		_boule(hortense, 0.05, Vector3(sx * 0.1, 0.02, -0.06), vert, Vector3(0.8, 0.5, 1.6))
		_boule(hortense, 0.03, Vector3(sx * 0.08, 0.01, 0.1), vert, Vector3(1.0, 0.4, 1.4))
	# (une couronne minuscule ? non : un petit nœud d'argent, le blason de la Minuit)
	_boule(hortense, 0.02, Vector3(0, 0.15, -0.09), _mat(Color(0.75, 0.78, 0.85), 0.2))


## La chaussette : là-haut sur la girouette, puis au pied de la tour
func _chaussette(parent: Node3D) -> void:
	var bleu := _mat(Color(0.12, 0.2, 0.6), 0.9)
	var orc := _mat(Color(0.9, 0.7, 0.25), 0.9)
	for i in range(4):
		_bloc(parent, Vector3(0.12, 0.08, 0.09), Vector3(0, 0.04 + i * 0.08, 0), bleu if i % 2 == 0 else orc)
	_bloc(parent, Vector3(0.12, 0.09, 0.2), Vector3(0, -0.02, 0.06), bleu)
	_bloc(parent, Vector3(0.12, 0.08, 0.08), Vector3(0, -0.02, 0.17), orc)


func _chaussettes() -> void:
	chaussette_haut = Node3D.new()
	chaussette_haut.name = "Chaussette_girouette"
	add_child(chaussette_haut)
	chaussette_haut.position = monde(CHAUSSETTE_HAUT)
	chaussette_haut.scale = Vector3.ONE * 2.2
	chaussette_haut.rotation = Vector3(0.0, 0.4, 1.3)
	_chaussette(chaussette_haut)
	chaussette_sol = Node3D.new()
	chaussette_sol.name = "Chaussette_tombee"
	add_child(chaussette_sol)
	var ps: Vector3 = monde(CHAUSSETTE_SOL)
	chaussette_sol.position = Vector3(ps.x, _sol(CHAUSSETTE_SOL) + 0.06, ps.z)
	chaussette_sol.rotation = Vector3(PI * 0.5, 0.7, 0.0)
	_chaussette(chaussette_sol)


## La grande fougère de la serre du fond (trois mètres de frondes), et ses racines qui sortent de la serre
func _fougere() -> void:
	var f := Node3D.new()
	f.name = "Grande_fougere"
	add_child(f)
	f.position = monde(FOUGERE)
	var vert := _mat(Color(0.16, 0.42, 0.14), 0.75)
	vert.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 15
	for i in range(n):
		var a: float = TAU * i / n + _rng.randf_range(-0.15, 0.15)
		var L: float = _rng.randf_range(2.4, 3.3)
		var lev: float = _rng.randf_range(0.9, 1.3)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var seg: int = 12
		for j in range(seg):
			var t0: float = float(j) / seg
			var t1: float = float(j + 1) / seg
			var p0: Vector3 = d * L * t0 * 0.8 + Vector3(0, lev * 2.0 * t0 * (1.0 - t0 * 0.85), 0)
			var p1: Vector3 = d * L * t1 * 0.8 + Vector3(0, lev * 2.0 * t1 * (1.0 - t1 * 0.85), 0)
			var w: float = 0.32 * sin(PI * (t0 * 0.85 + 0.12))
			# une paire de folioles à chaque segment
			for sg in [-1.0, 1.0]:
				var q: Vector3 = p0 + side * sg * w + (p1 - p0) * 0.8 + Vector3(0, -0.06, 0)
				st.set_normal(Vector3.UP)
				st.add_vertex(p0)
				st.add_vertex(p1 if sg > 0 else q)
				st.add_vertex(q if sg > 0 else p1)
			# la tige
			st.set_normal(Vector3.UP)
			st.add_vertex(p0 - side * 0.015)
			st.add_vertex(p1 + side * 0.015)
			st.add_vertex(p0 + side * 0.015)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = vert
	f.add_child(mi)
	# le cœur (des crosses enroulées)
	_boule(f, 0.25, Vector3(0, 0.1, 0), _mat(Color(0.25, 0.3, 0.12), 0.8), Vector3(1, 0.6, 1))
	# les racines : elles sortent de la serre côté ouest, rampent sur le socle et plongent entre les dalles
	var brun := _mat(Color(0.32, 0.22, 0.13), 0.9)
	for i in range(5):
		var z0: float = FOUGERE.z - 0.8 + i * 0.4
		var a0: Vector3 = monde(Vector3(FOUGERE.x - 0.3, FOUGERE.y + 0.05, z0))
		var a1: Vector3 = monde(Vector3(45.05, FOUGERE.y + 0.03, z0 + 0.15 * (i - 2)))
		var g1: Vector3 = monde(Vector3(44.3 - 0.2 * (i % 2), 0.0, z0 + 0.3 * (i - 2)))
		a1.y = maxf(a1.y, 0.0)
		g1.y = _sol(Vector3(44.3, 0.0, z0)) + 0.03
		for seg in [[a0, a1], [a1, g1]]:
			var s0: Vector3 = seg[0]
			var s1: Vector3 = seg[1]
			var r := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.045
			cm.bottom_radius = 0.06
			cm.height = s0.distance_to(s1)
			cm.radial_segments = 6
			r.mesh = cm
			r.material_override = brun
			add_child(r)
			r.position = (s0 + s1) * 0.5
			var up: Vector3 = (s1 - s0).normalized()
			var ref: Vector3 = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
			var bx: Vector3 = up.cross(ref).normalized()
			r.basis = Basis(bx, up, bx.cross(up).normalized())


## La fontaine : la surface de l'eau (dans le maillage du cloître), la dalle qui cache l'escalier
func _fontaine() -> void:
	eau_mesh = chateau.get_node_or_null("Ombrelac_cloitre") as MeshInstance3D
	if eau_mesh != null and eau_mesh.mesh != null:
		var em: Material = Kit.mat("eau_fontaine")
		for i in range(eau_mesh.mesh.get_surface_count()):
			if eau_mesh.mesh.surface_get_material(i) == em:
				eau_surfaces.append(i)
	eau_mat = StandardMaterial3D.new()
	eau_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eau_mat.albedo_color = Color(0.1, 0.24, 0.24, 0.85)
	eau_mat.roughness = 0.05
	eau_mat.metallic_specular = 0.9
	trou = Node3D.new()
	trou.name = "Escalier_fontaine"
	add_child(trou)
	trou.position = monde(DALLE)
	trou.basis = _xf().basis
	_bloc(trou, Vector3(1.2, 0.02, 1.2), Vector3(0, 0.005, 0), Kit.mat("suie"))
	for i in range(3):
		_bloc(trou, Vector3(1.1, 0.02, 0.3), Vector3(0, -0.25 - i * 0.28, -0.42 + i * 0.3), Kit.mat("pierre_claire"))
	trou.visible = false
	dalle = Node3D.new()
	dalle.name = "Dalle_fontaine"
	add_child(dalle)
	dalle.position = monde(DALLE)
	dalle.basis = _xf().basis
	_bloc(dalle, Vector3(1.3, 0.1, 1.3), Vector3(0, 0.05, 0), Kit.mat("pierre_claire"))
	var l := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.3
	cm.height = 0.02
	l.mesh = cm
	l.material_override = Kit.mat("suie")
	l.position = Vector3(0, 0.11, 0)
	dalle.add_child(l)
	var c := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.36
	cm2.bottom_radius = 0.36
	cm2.height = 0.015
	c.mesh = cm2
	c.material_override = Kit.mat("cristal")
	c.position = Vector3(0.05, 0.105, 0.03)
	dalle.add_child(c)


## Ce qu'on voit selon l'état (la chaussette en haut ou en bas…)
func _decor() -> void:
	var e: int = etape("chaussette")
	if chaussette_haut != null:
		chaussette_haut.visible = e < 2 and not finie("chaussette")
	if chaussette_sol != null:
		chaussette_sol.visible = e == 2


# =================================================================== l'état

## Une partie chargée (ou une nouvelle partie) : le décor suit l'état ; la fontaine est pleine
func apres_chargement() -> void:
	if minuit != null:
		minuit.coups = 0
		minuit.appliquer()
	_decor()
	if ouverte:
		ouverte = false
		_t_fermer = -1.0
		if dalle != null:
			dalle.position = monde(DALLE)
		me_trou(false)
		if eau_mesh != null:
			for i in eau_surfaces:
				eau_mesh.set_surface_override_material(i, null)
	_sync()

func st() -> Dictionary:
	if ombrelac == null:
		return {}
	var s: Dictionary = ombrelac.state
	if not s.has("quetes") or not (s["quetes"] is Dictionary):
		s["quetes"] = {}
	var q: Dictionary = s["quetes"]
	if not q.has("etapes") or not (q["etapes"] is Dictionary):
		q["etapes"] = {}
	if not q.has("indices") or not (q["indices"] is Array):
		q["indices"] = []
	return q


## -1 : pas commencée ; 0… : l'étape en cours ; le nombre d'étapes : accomplie
func etape(qid: String) -> int:
	return int((st()["etapes"] as Dictionary).get(qid, -1))


func finie(qid: String) -> bool:
	return etape(qid) >= (Q[qid]["etapes"] as Array).size()


func en_cours(qid: String, e: int = -99) -> bool:
	var x: int = etape(qid)
	if e != -99:
		return x == e
	return x >= 0 and not finie(qid)


func indices() -> int:
	return (st()["indices"] as Array).size()


func _fixer(qid: String, e: int) -> void:
	st()["etapes"][qid] = e
	_decor()
	_sync()


func _avancer(qid: String, e: int, txt: String = "", s: float = 9.0) -> void:
	_fixer(qid, e)
	if main != null and main.has_method("sfx"):
		main.sfx("ui_quete")
	if txt != "":
		_dire(txt + "  (Carnet : %s.)" % _objectif(qid), s)


func _objectif(qid: String) -> String:
	var e: int = etape(qid)
	var et: Array = Q[qid]["etapes"]
	if e < 0 or e >= et.size():
		return str(Q[qid]["titre"])
	var t: String = str(et[e])
	return t % indices() if t.contains("%d") else t


func _dire(txt: String, s: float = 8.0) -> void:
	if objets != null and objets.has_method("say"):
		objets.say(txt, s)
	elif main != null and main.has_method("_show_message_v28"):
		main._show_message_v28(txt)


func _nuit() -> bool:
	return objets.call("_nuit") if objets != null and objets.has_method("_nuit") else false


func _inv() -> Node:
	return main.get("inventory_v28") if main != null else null


func _a(id: String, n: int = 1) -> bool:
	var inv: Node = _inv()
	return inv != null and int(inv.count(id)) >= n


func _npc(id: String) -> Node:
	if vie == null or vie.get("by_id") == null:
		return null
	var n: Variant = (vie.by_id as Dictionary).get(id)
	return n if n != null and is_instance_valid(n) else null


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	if not _services_ok and main.get("journal_v56") != null and main.journal_v56 != null:
		for id in SERVICES:
			main.journal_v56.add_service(id, _sujets, _choisir)
		_services_ok = true
	# Hortense respire (et cligne, de temps en temps : elle sait des choses)
	if hortense != null:
		var tt: float = Time.get_ticks_msec() * 0.001
		hortense.scale = Vector3(1.0, 1.0 + 0.05 * sin(tt * 2.1), 1.0)
	if _t_fermer > 0.0:
		_t_fermer -= delta
		if _t_fermer <= 0.0:
			fermer()
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	_sync()
	_auto()


## Les étapes qui avancent d'elles-mêmes (on a déjà ce qu'il faut)
func _auto() -> void:
	if en_cours("elixir", 0) and _a("fleur_lune") and _a("chouette_plume") and _a("fiole_vide"):
		_avancer("elixir", 1, "Tu as la fleur de lune, la plume de chouette et la fiole de cristal : direction une paillasse de la Salle des Élixirs !")
	if en_cours("miel", 2) and _a("miel"):
		_avancer("miel", 3, "Un pot de miel dans ton sac : de quoi sceller le pari. Maître Rouage t'attend.")
	if en_cours("minuit", 0) and indices() >= INDICES.size():
		_avancer("minuit", 1, "Tu as les cinq indices de la Minuit ! Anatole avait raison : il faut parler à Hortense, la grenouille de la fontaine. La nuit.")
	# (une partie rechargée dans les caves : on a forcément descendu l'escalier)
	if en_cours("minuit", 2) and minuit != null and minuit.contient_local(_xf().affine_inverse() * _joueur()):
		_avancer("minuit", 3)


func _joueur() -> Vector3:
	return main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else Vector3.ZERO


## Le carnet : chaque donneur de quête porte sa quête (le titre, ce qu'il reste à faire), sa mémoire dit
## où on en est ; ce qu'il répond quand on lui en parle, c'est le rappel de l'étape
func _sync() -> void:
	for qid in ORDRE:
		var q: Dictionary = Q[qid]
		var n: Node = _npc(str(q["qui"]))
		if n == null or not (n.get("profile") is Dictionary) or n.get("brain") == null:
			continue
		var e: int = etape(qid)
		var pr: Dictionary = n.profile
		pr["quete"] = {"sujet": str(q["titre"]), "objets": {_objectif(qid): 1}, "note": "m'a confié : " + str(q["titre"]).to_lower(),
			"souvenir": "Et grâce à toi, « %s », c'est réglé." % str(q["titre"]), "affinite": 0.0}
		var rep: Dictionary = pr.get("repliques", {})
		var rp: Array = q["rappels"]
		var txt: String = str(rp[clampi(e, 0, rp.size() - 1)])
		if qid == "minuit" and e == 0:
			txt += " (Tu en as %d sur 5.)" % indices()
		rep["quete_manque"] = [{"t": txt, "si": {}}]
		rep["quete_fin"] = [{"t": "Merci encore !", "si": {}}]
		pr["repliques"] = rep
		var mem: Dictionary = n.brain.memoire
		mem["quete"] = "" if e < 0 else ("finie" if finie(qid) else "demandee")


# =================================================================== les services (la conversation)

func _id(qid: String, action: String) -> String:
	return "q56:service:om_%s_%s" % [qid, action]


func _sujets(npc: Node) -> Array:
	var id: String = str(npc.profile.get("id", ""))
	var out: Array = []
	for qid in ORDRE:
		var q: Dictionary = Q[qid]
		if str(q["qui"]) == id:
			if etape(qid) < 0:
				out.append({"id": _id(qid, "offre"), "label": str(q["offre_label"])})
			elif _peut_rendre(qid):
				out.append({"id": _id(qid, "rendre"), "label": str(q["rendre_label"])})
	match id:
		"fauconnier_om":
			if en_cours("miel", 1):
				out.append({"id": _id("miel", "etoiles"), "label": "★ J'ai relevé l'heure des étoiles."})
			if en_cours("elixir", 0) and not _a("chouette_plume"):
				out.append({"id": _id("elixir", "plume"), "label": "★ Auriez-vous une plume de chouette ?"})
		"fournil_om":
			if en_cours("miel", 2) and not _a("miel"):
				out.append({"id": _id("miel", "pot"), "label": "★ Il me faudrait un pot de miel, pour le pari."})
		"alambic_om":
			if en_cours("elixir", 0) and not _a("fiole_vide"):
				out.append({"id": _id("elixir", "fiole"), "label": "★ Auriez-vous une fiole de cristal ?"})
		"buis_om":
			if en_cours("elixir", 0) and not _a("fleur_lune"):
				out.append({"id": _id("elixir", "fleur"), "label": "★ Une fleur de lune, pour Sidonie ?"})
		"equerre_om":
			if en_cours("elixir", 2):
				out.append({"id": _id("elixir", "gouter"), "label": "★ Maître, goûtez donc cet élixir."})
		"vesperine_om":
			if finie("minuit") and not bool(st().get("rectrice", false)):
				out.append({"id": _id("minuit", "rectrice"), "label": "★ Madame la Rectrice… j'ai trouvé la Maison de Minuit."})
	if cours != null and cours.has_method("sujets"):
		out.append_array(cours.sujets(npc))
	if creatures != null and creatures.has_method("sujets"):
		out.append_array(creatures.sujets(npc))
	return out


func _peut_rendre(qid: String) -> bool:
	var e: int = etape(qid)
	var last: int = (Q[qid]["etapes"] as Array).size() - 1
	if e != last:
		return false
	if qid == "miel":
		return _a("miel")
	return true


func _choisir(npc: Node, choice: String) -> Dictionary:
	var parts: PackedStringArray = choice.split(":")
	if parts.size() >= 3 and parts[2].begins_with("omc_") and cours != null:
		return cours.choisir(npc, parts[2].substr(4))
	if parts.size() >= 3 and parts[2].begins_with("omk_") and creatures != null:
		return creatures.choisir(npc, parts[2].substr(4))
	if parts.size() < 3 or not parts[2].begins_with("om_"):
		return {}
	var rest: String = parts[2].substr(3)
	var cut: int = rest.rfind("_")
	var qid: String = rest.substr(0, cut)
	var action: String = rest.substr(cut + 1)
	if not Q.has(qid):
		return {}
	var q: Dictionary = Q[qid]
	match action:
		"offre":
			return {"texte": str(q["offre"]), "geste": "parle",
				"choix": [{"id": _id(qid, "accepte"), "label": "D'accord, je m'en occupe."}, {"id": _id(qid, "refuse"), "label": "Pas maintenant."}]}
		"refuse":
			return {"texte": str(q["refuse"]), "geste": "parle"}
		"accepte":
			if etape(qid) >= 0:
				return {"texte": str(q["rappels"][clampi(etape(qid), 0, (q["rappels"] as Array).size() - 1)]), "geste": "parle"}
			_fixer(qid, 0)
			if npc.get("brain") != null and npc.brain.has_method("_bond"):
				npc.brain._bond(3.0)
			if main != null and main.has_method("_show_message_v28"):
				main._show_message_v28("Nouvelle quête : " + str(q["titre"]))
			if main != null and main.has_method("sfx"):
				main.sfx("ui_quete")
			_auto()
			return {"texte": str(q["accepte"]), "geste": "salut"}
		"rendre":
			if not _peut_rendre(qid):
				return {}
			return _finir(npc, qid)
		"etoiles":
			if not en_cours("miel", 1):
				return {}
			_avancer("miel", 2)
			return {"texte": "Voyons… L'étoile du Berger à trois doigts du clocher, Saturnelle sous la Couronne… minuit moins onze. Exactement l'heure de l'horloge. Sauf le jeudi. Hm ! Je crois comprendre. Le jeudi soir, la vieille Maison de Minuit veillait. Aubin le Polisseur a ajouté une minute à l'horloge pour eux, et un treizième coup à minuit. Nous avions raison tous les deux, Rouage et moi ! Va le lui dire. Avec du miel : il ne croit rien sans miel.", "geste": "rire"}
		"pot":
			if not en_cours("miel", 2) or _a("miel"):
				return {}
			return {"texte": "Le pari du miel ! Ils vont enfin le finir ? Tiens, voilà le pot. Le même qu'il y a onze ans, ou presque : je le remplis en cachette. Ne leur dis pas.", "geste": "rire", "donner": [["miel", 1]]}
		"plume":
			if not en_cours("elixir", 0) or _a("chouette_plume"):
				return {}
			return {"texte": "Une plume de Minerve ? La chouette de l'Observatoire en perd une par nuit : je les garde dans une boîte. Pour un élixir de rire, je parie. Tiens. Et dis à Sidonie : une goutte. Pas deux.", "geste": "parle", "donner": [["chouette_plume", 1]]}
		"fiole":
			if not en_cours("elixir", 0) or _a("fiole_vide"):
				return {}
			return {"texte": "Une fiole ? Pour Sidonie, je parie. L'élixir de rire… Tiens. Et rappelle-lui la règle numéro un : on ne secoue pas. La règle numéro deux : on ne secoue vraiment pas.", "geste": "parle", "donner": [["fiole_vide", 1]]}
		"fleur":
			if not en_cours("elixir", 0) or _a("fleur_lune"):
				return {}
			return {"texte": "Pour un élixir de rire ? Ha ! Firmin Buis n'a rien entendu. Tiens, cueillie à la nuit tombée. Prends-en soin : elle est timide.", "geste": "parle", "donner": [["fleur_lune", 1]]}
		"gouter":
			if not en_cours("elixir", 2):
				return {}
			_avancer("elixir", 3)
			return {"texte": "Un élixir ? Je me méfie des liquides : ils ne gardent jamais leur forme… Hm. Une goutte, alors. … Ha. HA. HAHAHA ! C'est… c'est mathématiquement inacceptable ! HAHA ! Attendez… cela me rappelle… une devise, dans la marge de mon vieux traité de géométrie, signée « la Minuit » : « Trois fois à angle droit, jusqu'à ce que la Minuit te regarde. » Je ne l'ai jamais comprise. HAHAHA ! Je ne la comprends toujours pas !", "geste": "rire"}
		"rectrice":
			if not finie("minuit") or bool(st().get("rectrice", false)):
				return {}
			var r := {"texte": "Je sais. Hortense me l'a dit. … Ne faites pas cette tête : je suis Rectrice. La Minuit nous a laissé un message, il y a deux cents ans : certains apprennent mieux la nuit. Nous l'avions oublié. Dès ce soir, l'Observatoire restera ouvert aux élèves qui veillent. Merci. Et gardez ceci : la Minuit aurait voulu qu'il soit à vous.", "geste": "salut", "donner": [["elixir_etoile", 1]]}
			if not _peut_donner(r["donner"]):
				return _sac_plein(r["donner"])
			st()["rectrice"] = true
			return r
	return {}


func _peut_donner(gives: Array, takes: Array = []) -> bool:
	var inv: Node = _inv()
	return inv == null or not inv.has_method("can_accept") or bool(inv.can_accept(gives, takes))


func _sac_plein(gives: Array) -> Dictionary:
	var noms: Array = []
	var inv: Node = _inv()
	for g in gives:
		noms.append(str(inv.ITEMS.get(str(g[0]), {"name": str(g[0])})["name"]).to_lower() if inv != null else str(g[0]))
	return {"texte": "« Attends… ton sac est plein. Fais un peu de place pour %s, puis reviens me voir. »" % " et ".join(noms), "geste": "parle"}


## Une quête accomplie : la récompense, l'indice de la Minuit, l'expérience, la nouvelle qui circule
func _finir(npc: Node, qid: String) -> Dictionary:
	var q: Dictionary = Q[qid]
	var gives: Array = q.get("recompense", [])
	var takes: Array = [["miel", 1]] if qid == "miel" else []
	if not _peut_donner(gives, takes):
		return _sac_plein(gives)
	var texte: String = str(q["fin"])
	if q.has("indice"):
		var li: Array = st()["indices"]
		if not li.has(qid):
			li.append(qid)
		texte += "\n\n✦ Indice de la Minuit (%d / 5) : %s" % [li.size(), str(q["indice"])]
		if li.size() == INDICES.size():
			texte += "\nTu as les cinq indices ! Hortense, la grenouille de la fontaine, attend sûrement ta visite. La nuit."
	_fixer(qid, (q["etapes"] as Array).size())
	var msgs: Array = []
	var pr: Variant = main.get("progression_v63") if main != null else null
	if pr != null and pr.has_method("quest_xp"):
		msgs.append("+%d XP" % int(pr.quest_xp("om_" + qid, (q["etapes"] as Array).size())))
	if main != null and main.has_method("_show_message_v28"):
		main._show_message_v28("Quête accomplie : %s%s" % [str(q["titre"]), ("  (" + ", ".join(msgs) + ")") if not msgs.is_empty() else ""])
	if pr != null and pr.has_method("on_quest"):
		pr.on_quest("om_" + qid, (q["etapes"] as Array).size())
	if main != null and main.has_method("jingle"):
		main.jingle("victoire")
	if npc != null and npc.get("brain") != null and npc.brain.has_method("_bond"):
		npc.brain._bond(12.0)
	var j: Variant = main.get("journal_v56") if main != null else null
	var now: float = float(j._now()) if j != null and j.has_method("_now") else 0.0
	Societe.noter("quete", str(q["qui"]), now, {"titre": str(q["titre"])})
	_auto()
	var r := {"texte": texte, "geste": "rire", "donner": gives}
	if not takes.is_empty():
		r["prendre"] = takes
	return r


# =================================================================== les objets du château

## Les objets des quêtes (Hortense, la chaussette tombée, les racines, l'escalier, les énigmes des caves)
func _objets() -> void:
	if objets == null or not objets.has_method("ajouter"):
		return
	var me = self
	var d := Vector3(cos(HORTENSE_A), 0, sin(HORTENSE_A))
	var ph: Vector3 = Vector3(10.0, 0.0, -23.0) + d * 4.05
	objets.ajouter({"id": "hortense", "a": monde(ph), "portee": 1.3, "prio": 3.0, "verbe": "parler à Hortense, la grenouille",
		"call": func(): me.parler_hortense()})
	objets.ajouter({"id": "escalier_fontaine", "a": monde(Vector3(10.0, 0.0, -23.0)), "portee": 5.6, "prio": 2.0,
		"verbe": "descendre l'escalier de la Minuit", "si": func(): return me.ouverte, "call": func(): me.descendre()})
	objets.ajouter({"id": "chaussette", "a": monde(CHAUSSETTE_SOL), "portee": 1.5, "prio": 1.0, "verbe": "ramasser la chaussette",
		"si": func(): return me.en_cours("chaussette", 2), "call": func(): me.ramasser_chaussette()})
	objets.ajouter({"id": "racines", "a": monde(RACINES), "portee": 2.2, "prio": 0.5,
		"verbe": func(): return "examiner les racines de la grande fougère" if me.en_cours("fougere", 0) else "regarder la grande fougère",
		"call": func(): me.racines()})
	# les caves de la Minuit (repère château, au sol des caves)
	var FY: float = minuit.FY
	objets.ajouter({"id": "remonter", "a": monde(Vector3(6.4, FY, -20.0)), "portee": 1.7, "prio": 1.0, "verbe": "remonter vers le cloître",
		"call": func(): me.remonter()})
	objets.ajouter({"id": "cloche_minuit", "a": monde(Vector3(12.9, FY, -26.4)), "portee": 1.6, "verbe": "frapper la cloche",
		"call": func(): me._dire(me.minuit.frapper(), 3.0)})
	objets.ajouter({"id": "plaque_treize", "a": monde(Vector3(7.0, FY, -27.3)), "portee": 1.3, "face": _xf().basis * Vector3(0, 0, 1), "verbe": "lire l'inscription",
		"call": func(): me._dire("Gravé dans le bronze : « JE SONNE L'HEURE QUE L'HORLOGE OUBLIE. FRAPPE-MOI AUTANT DE FOIS, PAS UNE DE PLUS, ET LA MINUIT T'OUVRIRA. »", 9.0)})
	objets.ajouter({"id": "plaque_veilleurs", "a": monde(Vector3(4.7, FY, -33.5)), "portee": 1.3, "face": _xf().basis * Vector3(1, 0, 0), "verbe": "lire l'inscription",
		"call": func(): me._dire("Gravé dans le bronze : « QUATRE VEILLENT ICI. UN SEUL VEILLE QUAND TOUT DORT. POSE LA MAIN SUR LUI. »", 9.0)})
	objets.ajouter({"id": "plaque_angles", "a": monde(Vector3(29.3, FY, -35.0)), "portee": 1.3, "face": _xf().basis * Vector3(-1, 0, 0), "verbe": "lire l'inscription",
		"call": func(): me._dire("Gravé dans le bronze : « TROIS ROUES, TROIS FOIS À ANGLE DROIT, JUSQU'À CE QUE LA MINUIT TE REGARDE. »", 9.0)})
	for i in range(minuit.STATUES.size()):
		var sn: String = str(minuit.STATUES[i])
		objets.ajouter({"id": "statue_" + sn, "a": monde(Vector3(6.5 + i * 2.5, FY, -37.7)), "portee": 1.25, "face": _xf().basis * Vector3(0, 0, 1),
			"verbe": "toucher la statue : " + str(minuit.NOMS_STATUES[sn]), "call": func(): me._dire(me.minuit.toucher(sn), 7.0)})
	for i in range(3):
		var ri: int = i
		objets.ajouter({"id": "roue_%d" % i, "a": monde(Vector3(20.5 + i * 2.5, FY, -38.7)), "portee": 1.25, "face": _xf().basis * Vector3(0, 0, 1),
			"verbe": "tourner la roue d'un quart de tour", "call": func(): me._dire(me.minuit.tourner(ri), 4.0)})
	objets.ajouter({"id": "coffre_minuit", "a": monde(Vector3(25.0, FY, -20.3)), "portee": 1.5, "verbe": "ouvrir le coffre de la Minuit",
		"call": func(): me.coffre()})
	objets.ajouter({"id": "lettre_minuit", "a": monde(Vector3(21.8, FY, -24.0)), "portee": 1.3, "verbe": "lire la lettre posée sur la table",
		"call": func(): me._dire(LETTRE, 16.0)})
	objets.ajouter({"id": "banniere_minuit", "a": monde(Vector3(29.6, FY, -24.0)), "portee": 1.8, "verbe": "regarder la bannière",
		"call": func(): me._dire("La bannière de la Maison de Minuit : une lune noire cerclée d'argent, sur un drap couleur de nuit. Dessous, brodé en tout petit : « Nous veillons pour que d'autres dorment. »", 8.0)})


const LETTRE := "« À toi qui as trouvé le chemin. Nous étions la Maison de Minuit : ceux qui apprennent quand tout dort. Nous étions peu, nous dormions le jour, nous manquions les repas (Mère Fournil de notre temps ne nous l'a jamais pardonné). Alors nous sommes descendus ici, et nous avons laissé cinq indices à ceux d'en haut, pour qu'un jour quelqu'un se souvienne que certains voient mieux la nuit. Prends le trésor. Garde le secret, ou ne le garde pas : la chouette jugera. — Séraphine Nuitdargent, dernière préfète de la Minuit. P.-S. : Aubin, rends-nous la minute du jeudi. »"


## Avant ce que l'objet fait d'habitude : une quête en a besoin ? (true : c'est fait)
func intercepte(o: Dictionary) -> bool:
	match str(o.get("sorte", "")):
		"lunette":
			return _lunette(o)
		"cloche":
			if en_cours("chaussette", 1):
				objets._cloche()
				_tomber_chaussette()
				return true
		"paillasse":
			if en_cours("elixir", 1):
				_preparer_elixir()
				return true
		"fontaine":
			if en_cours("fougere", 1):
				if main != null and main.has_method("sfx"):
					main.sfx("bulles", monde(Vector3(10.0, 0.6, -23.0)))
				_avancer("fougere", 2, "Tu te penches au-dessus du bassin et tu tends l'oreille. Sous le clapotis, il y a un autre bruit : de l'eau qui coule vers le bas, très loin, marche après marche, comme dans un escalier. Cette fontaine ne vient pas d'en haut : elle remonte d'en dessous. Hortense, la grenouille, te regarde faire d'un air entendu.", 11.0)
				return true
		"livres":
			if en_cours("livre", 0) and str(o.get("noeud", "")) == "Ombrelac_bibliotheque":
				_chercher_livre(o)
				return true
	return false


func _lunette(o: Dictionary) -> bool:
	if not bool(o.get("grande", false)):
		return false
	var parts: Array = []
	if en_cours("chaussette", 0):
		_fixer("chaussette", 1)
		parts.append("Tu tournes la Grande Lunette vers la Tour de l'Horloge… là ! Tout en haut, accrochée à la girouette, une chaussette à rayures bleues et or flotte au vent. Il faudrait secouer la tour : la cloche, peut-être ?")
	if en_cours("miel", 0):
		if _nuit():
			_fixer("miel", 1)
			parts.append("Tu relèves l'heure des étoiles : l'étoile du Berger à trois doigts du clocher, Saturnelle juste sous la Couronne. Maître Fauconnier saura la lire.")
		elif not parts.is_empty():
			parts.append("(Pour le pari du miel, il faudra revenir la nuit.)")
	if parts.is_empty():
		return false
	if main != null and main.has_method("sfx"):
		main.sfx("cliquet_roue", o["a"])
		main.sfx("ui_quete")
	_dire(" ".join(parts), 11.0)
	return true


func _tomber_chaussette() -> void:
	_fixer("chaussette", 2)
	if chaussette_haut != null and chaussette_sol != null and chaussette_haut.is_inside_tree():
		chaussette_haut.visible = true
		chaussette_sol.visible = false
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(chaussette_haut, "position", chaussette_sol.position + Vector3(0, 0.05, 0), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(chaussette_haut, "rotation", Vector3(PI * 3.0, 2.0, PI * 2.5), 2.2)
		tw.tween_callback(_chaussette_posee)
	_dire("DONG ! La cloche roule dans la tour, la girouette tremble… et quelque chose de bleu et or tombe en tournoyant jusqu'au pied de la Tour de l'Horloge. La chaussette !  (Carnet : %s.)" % _objectif("chaussette"), 9.0)


func _chaussette_posee() -> void:
	chaussette_haut.visible = false
	chaussette_haut.position = monde(CHAUSSETTE_HAUT)
	chaussette_haut.rotation = Vector3(0.0, 0.4, 1.3)
	_decor()


func ramasser_chaussette() -> void:
	if not en_cours("chaussette", 2):
		return
	if main != null and main.has_method("sfx"):
		main.sfx("ui_quete")
	_avancer("chaussette", 3, "Tu ramasses la chaussette : à rayures bleues et or, un peu humide de brume, et brodée à l'intérieur d'un petit fil d'argent. Tobie va être content.")


func _preparer_elixir() -> void:
	var manque: Array = []
	for it in [["fleur_lune", "une fleur de lune"], ["chouette_plume", "une plume de chouette"], ["fiole_vide", "une fiole de cristal"]]:
		if not _a(str(it[0])):
			manque.append(str(it[1]))
	if not manque.is_empty():
		_fixer("elixir", 0)
		_dire("Il te manque : %s. Sans ça, l'élixir ne rira pas." % ", ".join(manque), 6.0)
		return
	var inv: Node = _inv()
	for id in ["fleur_lune", "chouette_plume", "fiole_vide"]:
		inv.remove(id, 1)
	if main != null and main.has_method("sfx"):
		main.sfx("vapeur", objets._joueur())
		main.sfx("verser", objets._joueur())
	_avancer("elixir", 2, "Tu effeuilles la fleur de lune, tu glisses la plume de chouette dans le ballon, trois tours de cuillère… La vapeur glousse. Elle GLOUSSE. Le liquide devient rose, plein de petites bulles qui rient tout bas : l'élixir de rire est prêt. Tu le bouches avec soin. Ne pas secouer.", 11.0)


func racines() -> void:
	if en_cours("fougere", 0):
		if not _nuit():
			_dire("La grande fougère fait semblant de dormir : ses frondes pendent, ses racines ne bougent pas. Firmin avait raison : il faudra revenir la nuit.", 7.0)
			return
		_avancer("fougere", 1, "La nuit, la grande fougère frémit. Ses racines passent sous la vitre, rampent sur le socle et plongent entre les dalles, toutes dans la même direction : le nord, vers le cloître. En collant l'oreille au sol, tu entends de l'eau couler, très loin dessous.", 11.0)
		return
	_dire("La grande fougère de Firmin : trois mètres de frondes, et ça continue. Elle a l'air très contente d'elle." if not finie("fougere")
		else "La grande fougère boit l'eau de la Minuit. Elle a encore pris dix centimètres. Firmin a renoncé à la mesurer.", 6.0)


func _chercher_livre(o: Dictionary) -> void:
	var s: Dictionary = st()
	var essais: int = int(s.get("livre_essais", 0))
	var rayon: int = int(o.get("n", -1))
	if essais == 0 or rayon == int(s.get("livre_rayon", -2)):
		s["livre_essais"] = 1
		s["livre_rayon"] = rayon
		if main != null and main.has_method("sfx"):
			main.sfx("carte", o["a"])
		_dire("Tu passes la main le long des dos de cuir… rien ne bouge. Ici, les livres sont rangés par taille : Maître Équerre est passé. Essaie un autre rayon.", 7.0)
		return
	s["livre_essais"] = 2
	if main != null and main.has_method("sfx"):
		main.sfx("carte", o["a"])
	_avancer("livre", 1, "Tu tires un vieux livre noir… il se tortille, essaie de retourner sur l'étagère ! Tu le tiens bien. Sur la couverture, en lettres d'argent : « Journal de la Maison de Minuit ». Il se calme, un peu vexé.", 10.0)


func coffre() -> void:
	var avant: bool = minuit.ouverte("coffre")
	_dire(minuit.ouvrir_coffre(), 9.0)
	if not avant and minuit.ouverte("coffre") and etape("minuit") < 4:
		if etape("minuit") < 0:
			_fixer("minuit", 0)
		_fixer("minuit", 4)


# =================================================================== Hortense, la fontaine, l'escalier

func parler_hortense() -> void:
	if main != null and main.has_method("sfx"):
		main.sfx("grenouille_coasse", hortense.position if hortense != null else null)
	var n: int = indices()
	if ouverte:
		_dire("Hortense garde l'escalier. « Coâ. » Ce qui veut sûrement dire : « Essuie-toi les pieds en remontant. »", 6.0)
		return
	if n < INDICES.size():
		var lignes: Array = ["Hortense te regarde d'un air entendu. « Coâ. » On dirait qu'elle attend que tu en saches davantage.",
			"Hortense cligne lentement des yeux. Tu as la nette impression d'être jugée.",
			"« Coâ. » Hortense se gratte l'oreille avec la patte arrière. Enfin, l'endroit où serait son oreille.",
			"Hortense fixe le fond du bassin, puis toi, puis le fond du bassin. Elle a l'air de trouver que tu es lent."]
		_dire("%s  (Indices de la Minuit : %d / 5.)" % [str(lignes[_rng.randi() % lignes.size()]), n], 7.0)
		return
	if bool(st().get("fontaine", false)):
		# (elle a déjà ouvert le passage une fois : elle le rouvre quand on veut)
		_dire("Hortense te reconnaît. Elle coasse treize fois sous l'eau… le bassin tourbillonne et se vide : l'escalier de la Minuit s'ouvre.", 7.0)
		ouvrir()
		return
	if not _nuit():
		_dire("Hortense dort, un œil à moitié ouvert. Une gardienne de la Minuit, ça veille la nuit : reviens quand tout le château dormira.", 7.0)
		return
	st()["fontaine"] = true
	if etape("minuit") < 0:
		_fixer("minuit", 0)
	if etape("minuit") < 2:
		_fixer("minuit", 2)
	if main != null and main.has_method("jingle"):
		main.jingle("decouverte")
	_dire("Tu te penches vers Hortense et tu murmures les cinq indices : la lune noire, le treizième coup, les trois angles droits, la chouette… et l'eau qu'on rend à sa source. Hortense te regarde longtemps. Puis elle plonge et coasse treize fois sous l'eau. L'eau de la fontaine se met à tourner… et s'en va par le fond ! Une dalle glisse : un escalier s'enfonce dans le noir.", 14.0)
	ouvrir()


## Le bassin se vide, la dalle glisse : l'escalier de la Minuit
func ouvrir() -> void:
	if ouverte:
		return
	ouverte = true
	_t_fermer = -1.0
	if main != null and main.has_method("sfx"):
		main.sfx("eau_vanne", monde(Vector3(10.0, 0.5, -23.0)))
		main.sfx("pierre_glisse", monde(DALLE))
	_eau(0.0, 3.5)
	if trou != null:
		trou.visible = true
	if dalle != null:
		var cible: Vector3 = monde(DALLE + Vector3(0, 0, 1.35))
		if dalle.is_inside_tree():
			var tw := create_tween()
			tw.tween_interval(2.5)
			tw.tween_property(dalle, "position", cible, 1.6).set_trans(Tween.TRANS_QUAD)
		else:
			dalle.position = cible


## Le passage se referme (un moment après qu'on est remonté) : l'eau revient
func fermer() -> void:
	if not ouverte:
		return
	ouverte = false
	if dalle != null:
		if dalle.is_inside_tree():
			var tw := create_tween()
			tw.tween_property(dalle, "position", monde(DALLE), 1.6).set_trans(Tween.TRANS_QUAD)
			tw.tween_callback(func(): me_trou(false))
		else:
			dalle.position = monde(DALLE)
			me_trou(false)
	_eau(0.85, 4.0)
	if main != null and main.has_method("sfx"):
		main.sfx("bulles", monde(Vector3(10.0, 0.5, -23.0)))


func me_trou(v: bool) -> void:
	if trou != null:
		trou.visible = v


## L'eau de la fontaine : de « a » à « b » d'opacité (0 : vide) ; à 0.85, l'eau du cloître revient telle quelle
func _eau(alpha: float, secs: float) -> void:
	if eau_mesh == null or eau_surfaces.is_empty():
		return
	var from: float = eau_mat.albedo_color.a if eau_mesh.get_surface_override_material(eau_surfaces[0]) == eau_mat else 0.85
	for i in eau_surfaces:
		eau_mesh.set_surface_override_material(i, eau_mat)
	if not is_inside_tree():
		eau_mat.albedo_color.a = alpha
		if alpha >= 0.85:
			_eau_normale()
		return
	eau_mat.albedo_color.a = from
	var tw := create_tween()
	tw.tween_property(eau_mat, "albedo_color:a", alpha, secs)
	if alpha >= 0.85:
		tw.tween_callback(_eau_normale)


func _eau_normale() -> void:
	if ouverte or eau_mesh == null:
		return
	for i in eau_surfaces:
		eau_mesh.set_surface_override_material(i, null)


func eau_visible() -> bool:
	if eau_mesh == null or eau_surfaces.is_empty():
		return true
	var m: Material = eau_mesh.get_surface_override_material(eau_surfaces[0])
	return m == null or (m == eau_mat and eau_mat.albedo_color.a > 0.05)


func descendre() -> void:
	if not ouverte:
		return
	if en_cours("minuit", 2):
		_fixer("minuit", 3)
	_dire("Tu descends l'escalier de la Minuit… les marches tournent, tournent, l'air devient frais et sent la pierre mouillée.", 4.0)
	await minuit.descendre()
	if etape("minuit") == 3 and not bool(st().get("arrive", false)):
		st()["arrive"] = true
		_dire("Les caves de la Maison de Minuit. Deux cents ans de silence… et, quelque part, une cloche qui attend son heure.", 8.0)


func remonter() -> void:
	ouvrir()
	await minuit.remonter()
	_dire("De retour au cloître. Hortense te regarde remonter d'un air satisfait. Derrière toi, l'eau revient doucement dans le bassin.", 6.0)
	_t_fermer = 6.0

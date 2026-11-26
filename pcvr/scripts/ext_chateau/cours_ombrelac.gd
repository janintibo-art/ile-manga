extends Node3D
## Extension « Le Château d'Ombrelac » (v17) : les cours de l'Académie.
## Cinq matières, trois leçons chacune, avec le maître de la matière, à l'heure de son cours :
##  - les astres (Maître Fauconnier, Salle des Astres ; la troisième leçon la nuit, à l'Observatoire) ;
##  - les élixirs (Maîtresse Alambic, Salle des Élixirs) ;
##  - la géométrie (Maître Équerre, Amphithéâtre) ;
##  - les sortilèges (Dame Sortelame, Salle des Cercles de la Tour des Sortilèges) ;
##  - la calligraphie (Dame Reliure, comptoir de la Bibliothèque).
## Une leçon : on parle au maître pendant son cours (« ★ Suivre la leçon »), il explique, il interroge
## (des questions à choix dans la conversation), puis il donne un exercice dans la salle :
##  - « cartes » : chercher la bonne carte du ciel (E sur les cartes de la Salle des Astres) ;
##  - « jauge » : appuyer sur E au bon moment, trois ou quatre fois (la fiole qui passe au vert sur la
##    paillasse, la règle de craie qui fait un angle droit au tableau, la planète au centre de la lunette) ;
##  - « runes » : des runes s'allument dans le Cercle ; on marche dessus, dans le même ordre ;
##  - « mannequins » : la passe d'armes : E sur le mannequin qui s'allume, avant qu'il ne s'éteigne.
## On revient voir le maître pour la note (Excellent, Très bien, Bien ; « À revoir » : on recommence).
## Les notes vont au bulletin (le chevalet du cloître, et le carnet : « Le diplôme de l'Académie », chez
## la Rectrice). Une matière réussie (ses trois leçons) : un cadeau du maître ; les cinq : la Rectrice
## remet le diplôme. Tout est dans ombrelac.state["cours"] (enregistré avec la partie).
## Les sujets passent par les services des habitants que tiennent les quêtes (quetes_ombrelac.gd) ;
## les objets (la paillasse, le tableau, les lunettes, les cartes, les mannequins) par objets_ombrelac.gd.

const Societe = preload("res://scripts/pnj/societe_v65.gd")
const ORDRE := ["astres", "elixirs", "geometrie", "sortileges", "calligraphie"]
## Le chevalet du bulletin (repère château) : dans le cloître, au bord de l'allée est, face au sud
const CHEVALET := Vector3(16.0, 0.16, -21.95)
const FENETRE_ANGLE := 9.0          # degrés de tolérance autour de l'angle droit
const RUNES_N := 5
const RUNES_R := 1.6

## Une question : [la question, [les réponses], l'indice de la bonne, ce que dit le maître si on se trompe]
const C := {
	"astres": {"maitre": "fauconnier_om", "nom": "Astres", "salle": "la Salle des Astres",
		"horaire": "Mon cours a lieu de 8 h à 10 h et de 13 h à 15 h, dans la Salle des Astres.",
		"recompense": [["goutte_rosee", 1], ["piece_or", 2]],
		"fin": "Trois leçons, trois réussites ! Vous savez lire le ciel, maintenant. Tenez : une goutte de rosée de lune, récoltée sur la terrasse de l'Astrolabe. Elle brille quand on pense aux étoiles.",
		"lecons": [
			{"titre": "L'étoile du Nord", "poste": "astres_maitre",
				"expl": "Asseyez-vous, asseyez-vous ! Aujourd'hui : l'étoile du Nord. Toutes les étoiles tournent autour d'elle pendant la nuit, comme des enfants autour d'un mât de cocagne. Elle, elle ne bouge presque pas. Pour la trouver, prenez la Grande Casserole, suivez le bord de la casserole et prolongez-le cinq fois. Voilà ! C'est le bout de la queue de la Petite Ourse.",
				"questions": [
					["Quelle étoile ne bouge presque pas dans le ciel ?", ["L'étoile du Berger", "L'étoile du Nord", "Gertrude"], 1, "Non : c'est l'étoile du Nord. Gertrude bouge beaucoup. Elle est très agitée, Gertrude."],
					["Comment la trouve-t-on ?", ["En prolongeant cinq fois le bord de la Grande Casserole", "En suivant la lune", "En regardant vers le sud"], 0, "Non : on prolonge cinq fois le bord de la Grande Casserole."],
				],
				"pratique": {"type": "cartes"},
				"consigne": "L'exercice : sur les cartes du ciel accrochées aux murs de la salle, trouvez celle où l'on voit la Petite Ourse et l'étoile du Nord. Approchez-vous des cartes et regardez-les (E)."},
			{"titre": "Les planètes", "poste": "astres_maitre",
				"expl": "Les planètes ne sont pas des étoiles. Elles ne brillent pas d'elles-mêmes : elles renvoient la lumière du soleil, comme un miroir. Et elles se promènent ! « Planète », en grec ancien, veut dire « vagabonde ». Saturne a des anneaux, Mars est rouge, Vénus est la plus brillante : c'est elle qu'on appelle l'étoile du Berger. Une étoile qui n'en est pas une. Le ciel adore les farces.",
				"questions": [
					["Les planètes brillent-elles d'elles-mêmes ?", ["Oui, comme les étoiles", "Non : elles renvoient la lumière du soleil", "Seulement le jeudi"], 1, "Non : elles renvoient la lumière du soleil, comme un miroir."],
					["Quelle planète a de grands anneaux ?", ["Saturne", "Mars", "Vénus"], 0, "Non : c'est Saturne. Mars est rouge, et Vénus n'a pas d'anneaux. Pas même une bague."],
				],
				"pratique": {"type": "jauge", "sorte": "lunette", "grande": false, "mode": "balancier", "vitesse": 1.0, "besoin": 3},
				"consigne": "L'exercice : à la lunette de la salle, suivez Vénus. Elle traverse le champ : appuyez sur E quand elle passe au centre du cercle. Trois fois."},
			{"titre": "Les étoiles filantes", "poste": "observatoire", "nuit": true,
				"expl": "Bonsoir ! La nuit est claire, la Grande Lunette est à nous. Ce soir : les étoiles filantes. Ce ne sont pas des étoiles qui tombent : ce sont des grains de poussière, gros comme un pois, qui entrent dans l'air à toute vitesse et qui brûlent. Et le ciel compte quatre-vingt-huit constellations. Ni plus, ni moins. J'ai vérifié. Deux fois.",
				"questions": [
					["Une étoile filante, c'est…", ["Une étoile qui tombe", "Un grain de poussière qui brûle dans l'air", "Une luciole perdue"], 1, "Non : un grain de poussière qui brûle en entrant dans l'air. Les lucioles, elles, restent dans le jardin de Firmin."],
					["Combien de constellations le ciel compte-t-il ?", ["Douze", "Mille", "Quatre-vingt-huit"], 2, "Non : quatre-vingt-huit. Douze, ce sont celles du zodiaque."],
				],
				"pratique": {"type": "jauge", "sorte": "lunette", "grande": true, "mode": "balancier", "vitesse": 1.6, "besoin": 3},
				"consigne": "L'exercice : à la Grande Lunette, attrapez trois étoiles filantes. Appuyez sur E quand l'étoile passe au centre du cercle. Elles vont vite !"},
		]},
	"elixirs": {"maitre": "alambic_om", "nom": "Élixirs", "salle": "la Salle des Élixirs",
		"horaire": "Mon cours a lieu de 8 h à midi et de 13 h à 17 h, dans la Salle des Élixirs. Avec des gants !",
		"recompense": [["tisane_lune", 2], ["piece_or", 2]],
		"fin": "Trois élixirs réussis, et pas une seule explosion. Enfin, presque pas. Vous avez la main ! Tenez : deux tisanes de lune, de ma réserve personnelle. Pour les nuits où l'on ne dort pas.",
		"lecons": [
			{"titre": "La tisane de sommeil", "poste": "elixirs_maitre",
				"expl": "Première leçon, la plus importante : on lit TOUTE la recette avant de commencer. Toute ! Ensuite on verse, un ingrédient après l'autre, au bon moment : quand la fiole passe au vert. Aujourd'hui, la tisane de sommeil : de la mélisse, de la camomille, et une goutte de racine de nénuphar. Une seule ! Deux gouttes, et on dort jusqu'au mardi suivant.",
				"questions": [
					["Que fait-on toujours en premier ?", ["On allume l'athanor", "On lit la recette jusqu'au bout", "On goûte"], 1, "Non ! On lit la recette jusqu'au bout. Toujours. Même quand on la connaît par cœur."],
					["Combien de gouttes de nénuphar ?", ["Une", "Deux", "Tout le flacon"], 0, "Une seule ! Avec deux, on dort jusqu'au mardi suivant. Avec tout le flacon, on dort jusqu'à l'année prochaine."],
				],
				"pratique": {"type": "jauge", "sorte": "paillasse", "mode": "couleur", "vitesse": 1.0, "besoin": 3},
				"consigne": "L'exercice : à une paillasse, versez les trois ingrédients. Appuyez sur E quand la fiole devient verte, pas avant, pas après."},
			{"titre": "L'élixir de lumière", "poste": "elixirs_maitre",
				"expl": "L'élixir de lumière : il éclaire une pièce pendant une heure, sans flamme. Il faut des pétales de fleur de lune, qui ne s'ouvrent que la nuit, de l'eau de source et une pincée de poussière de fée. Et la règle numéro un : on ne secoue pas. La règle numéro deux : on ne secoue vraiment pas. Ça va plus vite, aujourd'hui : soyez attentif.",
				"questions": [
					["La fleur de lune s'ouvre…", ["À midi", "La nuit", "Jamais"], 1, "Non : la nuit. Le jour, elle dort, comme Maître Fauconnier."],
					["La règle numéro un ?", ["On ne secoue pas", "On secoue fort", "On chante doucement"], 0, "Non : on ne secoue pas ! Chanter, en revanche, ça ne fait pas de mal. Sauf à Maître Équerre."],
				],
				"pratique": {"type": "jauge", "sorte": "paillasse", "mode": "couleur", "vitesse": 1.4, "besoin": 3},
				"consigne": "L'exercice : à une paillasse, trois ingrédients, quand la fiole devient verte. Elle change plus vite que tout à l'heure !"},
			{"titre": "L'élixir des étoiles", "poste": "elixirs_maitre",
				"expl": "Dernière leçon : l'élixir des étoiles. Le plus difficile. Quatre ingrédients, et la flamme bien réglée : c'est le cœur bleu de la flamme qui est le plus chaud, pas la pointe jaune. Et si ça siffle et que la fumée devient violette… on recule et on ouvre la hotte. Tout de suite. Sans discuter.",
				"questions": [
					["Quelle partie de la flamme est la plus chaude ?", ["La pointe jaune", "La fumée", "Le cœur bleu"], 2, "Non : le cœur bleu. La pointe jaune, c'est pour faire joli."],
					["Ça siffle, la fumée devient violette. Que fait-on ?", ["On recule et on ouvre la hotte", "On goûte vite", "On bouche la fiole"], 0, "Surtout pas ! On recule et on ouvre la hotte. Anatole a bouché la fiole, une fois. Le plafond s'en souvient."],
				],
				"pratique": {"type": "jauge", "sorte": "paillasse", "mode": "couleur", "vitesse": 1.8, "besoin": 4},
				"consigne": "L'exercice : à une paillasse, quatre ingrédients, quand la fiole devient verte. C'est rapide : concentration !"},
		]},
	"geometrie": {"maitre": "equerre_om", "nom": "Géométrie", "salle": "l'Amphithéâtre",
		"horaire": "Mon cours a lieu de 10 h 30 à midi et de 16 h à 19 h, à l'Amphithéâtre. À l'heure. Pas une minute de retard : une minute, c'est un angle de six degrés sur l'horloge.",
		"recompense": [["eclat_cristal", 1], ["piece_or", 2]],
		"fin": "Trois leçons. Trois. Aucune erreur de raisonnement. Je… je suis satisfait. Ne le répétez pas. Tenez : un éclat de cristal. Ses faces sont parfaitement planes. C'est ce que la nature a fait de plus géométrique.",
		"lecons": [
			{"titre": "L'angle droit", "poste": "amphi_maitre",
				"expl": "Asseyez-vous. L'angle droit : quatre-vingt-dix degrés. Le coin d'une page, le coin d'une porte, le pied d'un mur. Un carré en a quatre. Sans angle droit, les maisons penchent, les livres ne tiennent pas sur les étagères, et la Rectrice se fâche. L'angle droit est la politesse de la géométrie.",
				"questions": [
					["Un angle droit mesure…", ["45 degrés", "90 degrés", "180 degrés"], 1, "Non : quatre-vingt-dix degrés. Quarante-cinq, c'est la moitié. Cent quatre-vingts, c'est un demi-tour."],
					["Combien d'angles droits dans un carré ?", ["Deux", "Huit", "Quatre"], 2, "Non : quatre. Un à chaque coin. Comptez-les, la prochaine fois."],
				],
				"pratique": {"type": "jauge", "sorte": "tableau", "m": "tableau_amphi", "mode": "angle", "vitesse": 1.0, "besoin": 3},
				"consigne": "L'exercice : au grand tableau, la règle de craie tourne. Appuyez sur E quand elle croise la ligne à angle droit. Trois fois."},
			{"titre": "Les triangles", "poste": "amphi_maitre",
				"expl": "Le triangle. Trois côtés, trois angles, et un secret : la somme de ses angles fait toujours cent quatre-vingts degrés. Toujours. Grand ou petit, pointu ou aplati. Le triangle aux trois côtés égaux s'appelle équilatéral ; celui qui a un angle droit s'appelle rectangle.",
				"questions": [
					["La somme des angles d'un triangle ?", ["180 degrés", "360 degrés", "Ça dépend du triangle"], 0, "Non : cent quatre-vingts degrés, toujours. Ça ne dépend de rien. C'est ce qui est beau."],
					["Un triangle aux trois côtés égaux est…", ["Isocèle", "Équilatéral", "Rectangle"], 1, "Non : équilatéral. Isocèle, c'est deux côtés égaux seulement."],
				],
				"pratique": {"type": "jauge", "sorte": "tableau", "m": "tableau_amphi", "mode": "angle", "vitesse": 1.4, "besoin": 3},
				"consigne": "L'exercice : au grand tableau, tracez les angles droits des triangles rectangles. E quand la règle fait un angle droit. Elle tourne plus vite."},
			{"titre": "Le cercle", "poste": "amphi_maitre",
				"expl": "Le cercle : tous ses points sont à la même distance du centre. Cette distance, c'est le rayon ; deux rayons font le diamètre. Et le tour du cercle fait un peu plus de trois fois son diamètre : trois virgule un, quatre, un, cinq, neuf… on l'appelle pi, et il ne s'arrête jamais. Comme Maîtresse Alambic quand elle parle.",
				"questions": [
					["Le tour d'un cercle fait combien de fois son diamètre ?", ["Un peu plus de trois fois", "Deux fois exactement", "Quatre fois le dimanche"], 0, "Non : un peu plus de trois fois. C'est le nombre pi."],
					["Le rayon, c'est…", ["Le diamètre entier", "La moitié du diamètre", "Le tour du cercle"], 1, "Non : la moitié du diamètre. Du centre jusqu'au bord."],
				],
				"pratique": {"type": "jauge", "sorte": "tableau", "m": "tableau_amphi", "mode": "angle", "vitesse": 1.9, "besoin": 3},
				"consigne": "L'exercice : au grand tableau, tracez les diamètres perpendiculaires du cercle. E quand la règle croise la ligne à angle droit. Vite et juste !"},
		]},
	"sortileges": {"maitre": "sortelame_om", "nom": "Sortilèges", "salle": "la Salle des Cercles",
		"horaire": "Mon cours a lieu de 13 h à 19 h, dans la Salle des Cercles, au pied de la Tour des Sortilèges.",
		"recompense": [["poussiere_fee", 2], ["piece_or", 2]],
		"fin": "Trois leçons. Pas une étincelle de travers. Je ne suis jamais polie, vous le savez : c'est donc un compliment. Tenez, de la poussière de fée. Ne l'éternuez pas.",
		"lecons": [
			{"titre": "La première étincelle", "poste": "sort_maitre",
				"expl": "Première règle des sortilèges : savoir ne pas s'en servir. Deuxième : la baguette se tient comme une plume, pas comme un marteau. Troisième : on regarde, on retient, on refait. Les runes du Cercle vont s'allumer, l'une après l'autre. Vous marcherez dessus, dans le même ordre. Pas de baguette aujourd'hui : vos pieds suffiront.",
				"questions": [
					["La première règle des sortilèges ?", ["Savoir ne pas s'en servir", "Viser la tête", "Crier très fort"], 0, "Non. Savoir ne pas s'en servir. Encore une fois."],
					["La baguette se tient…", ["Comme un marteau", "Comme une plume", "Avec les dents"], 1, "Non. Comme une plume. Barnabé la tenait avec les dents, l'an dernier. Il n'a plus de sourcils."],
				],
				"pratique": {"type": "runes", "n": 3},
				"consigne": "L'exercice : entrez dans le Cercle. Trois runes vont s'allumer : marchez dessus dans le même ordre."},
			{"titre": "Les cinq runes", "poste": "sort_maitre",
				"expl": "Le Cercle a cinq runes : le feu, l'eau, le vent, la pierre et la lune. Chacune répond quand on la touche dans l'ordre. Dans le désordre, elles se taisent, et il faut recommencer, calmement. La colère ne lance pas de sorts. Elle lance des assiettes.",
				"questions": [
					["Combien de runes dans le Cercle ?", ["Trois", "Douze", "Cinq"], 2, "Non. Cinq : le feu, l'eau, le vent, la pierre, la lune."],
					["On s'est trompé de rune. Que fait-on ?", ["On recommence calmement", "On court partout", "On accuse Barnabé"], 0, "Non. On recommence, calmement. Barnabé n'y est pour rien. Cette fois."],
				],
				"pratique": {"type": "runes", "n": 5},
				"consigne": "L'exercice : entrez dans le Cercle. Cinq runes, cette fois : regardez bien, puis marchez dessus dans le même ordre."},
			{"titre": "La passe d'armes", "poste": "sort_maitre",
				"expl": "La passe d'armes. Avant tout, on salue l'adversaire. Ensuite, on garde les yeux ouverts : le mannequin qui s'allume, c'est celui qu'il faut toucher. Vite, avant qu'il ne s'éteigne. La première qualité, c'est la persévérance ; la deuxième, c'est savoir esquiver. Aujourd'hui, vous n'esquiverez rien : ce sont des mannequins. Mais ils comptent les points.",
				"questions": [
					["En duel, avant tout…", ["On salue", "On attaque dans le dos", "On discute du prix"], 0, "Non. On salue. Toujours."],
					["La deuxième qualité, après la persévérance ?", ["La vitesse", "Savoir esquiver", "La grosse voix"], 1, "Non. Savoir esquiver. Je vous l'avais dit dès le premier jour."],
				],
				"pratique": {"type": "mannequins", "n": 5},
				"consigne": "L'exercice : allez aux mannequins d'entraînement et appuyez sur E devant l'un d'eux pour commencer. Ensuite, touchez (E) celui qui s'allume, avant qu'il ne s'éteigne. Cinq touches."},
		]},
	"calligraphie": {"maitre": "reliure_om", "nom": "Calligraphie", "salle": "la Bibliothèque",
		"horaire": "Je vous attends au comptoir de la Bibliothèque, de 8 h à midi et de 13 h à 21 h. En silence, s'il vous plaît.",
		"recompense": [["plume_corbeau", 1], ["piece_or", 2]],
		"fin": "Trois leçons. Vous lisez les vieux livres comme on lit une lettre d'un ami. Tenez : une plume de corbeau, taillée par mes soins. La meilleure plume pour écrire. Et la seule qui ne fait jamais de pâté. Presque jamais.",
		"lecons": [
			{"titre": "Les lettres anciennes", "poste": "biblio_comptoir",
				"expl": "Chut… Approchez. Dans les vieux livres, les lettres ne ressemblent pas tout à fait aux nôtres. Le « s » long, par exemple, ressemble à un « f » sans barre : on le lit « s ». Au début des chapitres, la grande lettre décorée d'or et de couleurs, c'est la lettrine. Et on tourne les pages avec des gants, par le coin. Jamais avec un doigt mouillé. Jamais.",
				"questions": [
					["Dans les vieux livres, le « s » long (ſ) se lit…", ["« f »", "« s »", "« l »"], 1, "Non : « s ». Il ressemble à un « f », c'est tout le piège."],
					["Une lettrine, c'est…", ["Une toute petite lettre", "La grande lettre décorée au début d'un chapitre", "Une lettre d'amour"], 1, "Non : la grande lettre décorée qui ouvre un chapitre."],
					["On tourne les pages d'un vieux livre…", ["Avec un doigt mouillé", "En soufflant dessus", "Avec des gants, par le coin"], 2, "Malheureux ! Avec des gants, par le coin. Jamais avec un doigt mouillé."],
				],
				"pratique": {}},
			{"titre": "Les mots d'autrefois", "poste": "biblio_comptoir",
				"expl": "Les mots aussi vieillissent. « Icelle » veut dire « celle-ci ». « Moult » veut dire « beaucoup ». « Occire » veut dire « tuer », mais dans les livres de chevalerie seulement, rassurez-vous. Et « oncques » veut dire « jamais ». Je ne l'ai oncques entendu dans la Salle Commune.",
				"questions": [
					["« Moult » veut dire…", ["Mou", "Beaucoup", "Mouton"], 1, "Non : « beaucoup ». « Moult merci », disaient les chevaliers polis."],
					["« Icelle » veut dire…", ["Celle-ci", "Une petite île", "Un glaçon"], 0, "Non : « celle-ci »."],
					["« Oncques » veut dire…", ["Toujours", "Un oncle", "Jamais"], 2, "Non : « jamais ». Et votre oncle n'y est pour rien."],
				],
				"pratique": {}},
			{"titre": "Les copistes", "poste": "biblio_comptoir",
				"expl": "Avant l'imprimerie, les livres étaient recopiés à la main, lettre après lettre, par les copistes. Leur encre était faite de noix de galle, une petite boule qui pousse sur les chênes. Les plus beaux livres étaient enluminés : décorés d'or et de couleurs. Et le copiste qui faisait une faute grattait le parchemin avec un canif, et recommençait. Sans soupirer.",
				"questions": [
					["L'encre des copistes était faite de…", ["Noix de galle", "Jus de myrtille", "Suie de cheminée"], 0, "Non : de noix de galle, une petite boule qui pousse sur les chênes."],
					["Un livre enluminé est…", ["Lu à la bougie", "Décoré d'or et de couleurs", "Écrit dans le noir"], 1, "Non : décoré d'or et de couleurs."],
					["Le copiste qui fait une faute…", ["Déchire la page", "Appelle ça « le style »", "Gratte le parchemin et recommence"], 2, "Non : il gratte le parchemin avec un canif, et il recommence."],
				],
				"pratique": {}},
		]},
}

const COULEURS := [Color(0.9, 0.2, 0.15), Color(1.0, 0.65, 0.1), Color(0.2, 1.0, 0.35), Color(0.25, 0.45, 1.0)]

var main: Node
var ombrelac: Node
var chateau: Node3D
var vie: Node
var objets: Node
var quetes: Node
var jeu: Dictionary = {}                  # l'exercice qui se joue (jauge, runes, mannequins) : pas enregistré
var runes: Array = []                     # les cinq runes du Cercle (MeshInstance3D)
var runes_mat: Array = []
var chevalet: Node3D
var sceau: Node3D                         # (le sceau d'or du diplôme, sur le chevalet)
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


# =================================================================== construire

func build(the_main: Node, the_ombrelac: Node, the_chateau: Node3D, the_vie: Node, the_objets: Node, the_quetes: Node) -> void:
	main = the_main
	ombrelac = the_ombrelac
	chateau = the_chateau
	vie = the_vie
	objets = the_objets
	quetes = the_quetes
	top_level = true
	_rng.randomize()
	_runes()
	_chevalet()
	if objets != null:
		objets.set("cours", self)
	if quetes != null:
		quetes.set("cours", self)
	_decor()


func _xf() -> Transform3D:
	return chateau.global_transform if chateau.is_inside_tree() else chateau.transform


func monde(p: Vector3) -> Vector3:
	return _xf() * p


func _mat(c: Color, e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _mesh(parent: Node3D, mesh: Mesh, p: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = p
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _boite(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b


func _boule(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


## Les cinq runes du Cercle des sortilèges (éteintes : on ne les voit que pendant l'exercice)
func _runes() -> void:
	var lieux: Variant = chateau.get("lieux")
	var sc: Vector3 = Vector3(-52, 0, 34)
	if lieux is Dictionary and (lieux as Dictionary).has("sortileges_centre"):
		sc = (lieux as Dictionary)["sortileges_centre"]
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.02
	cyl.radial_segments = 20
	for i in range(RUNES_N):
		var a: float = deg_to_rad(54.0 + 72.0 * i)
		var p: Vector3 = monde(sc + Vector3(cos(a), 0.0, sin(a)) * RUNES_R + Vector3(0, 0.035, 0))
		var m := _mat(Color(0.45, 0.3, 0.75), 0.6)
		var r := _mesh(self, cyl, p, m)
		r.name = "Rune_%d" % i
		r.visible = false
		runes.append(r)
		runes_mat.append(m)


func rune_pos(i: int) -> Vector3:
	return (runes[i] as Node3D).position


func rune_allumer(i: int, v: bool) -> void:
	var m: StandardMaterial3D = runes_mat[i]
	m.albedo_color = Color(1.0, 0.85, 0.35) if v else Color(0.45, 0.3, 0.75)
	m.emission = m.albedo_color
	m.emission_energy_multiplier = 3.0 if v else 0.6


## Le chevalet du bulletin : deux pieds, la planche, le parchemin des notes, et le sceau (après le diplôme)
func _chevalet() -> void:
	chevalet = Node3D.new()
	chevalet.name = "Chevalet_bulletin"
	add_child(chevalet)
	chevalet.position = monde(CHEVALET)
	chevalet.basis = _xf().basis.orthonormalized()
	var bois := _mat(Color(0.36, 0.22, 0.12))
	for sx in [-0.36, 0.36]:
		var pied := _mesh(chevalet, _boite(Vector3(0.06, 1.75, 0.06)), Vector3(sx, 0.85, 0.0), bois)
		pied.rotation.x = 0.12
	var arr := _mesh(chevalet, _boite(Vector3(0.05, 1.6, 0.05)), Vector3(0, 0.78, 0.22), bois)
	arr.rotation.x = -0.28
	var planche := _mesh(chevalet, _boite(Vector3(0.86, 0.9, 0.04)), Vector3(0, 1.25, -0.06), bois)
	planche.rotation.x = 0.12
	var parch := _mesh(chevalet, _boite(Vector3(0.72, 0.78, 0.01)), Vector3(0, 1.25, -0.088), _mat(Color(0.93, 0.87, 0.7)))
	parch.rotation.x = 0.12
	# des lignes d'écriture
	var encre := _mat(Color(0.15, 0.12, 0.1))
	for i in range(7):
		var l := _mesh(parch, _boite(Vector3(0.5 - 0.06 * (i % 3), 0.018, 0.004)), Vector3(-0.03, 0.27 - i * 0.075, -0.006), encre)
		l.name = "ligne_%d" % i
	var titre := _mesh(parch, _boite(Vector3(0.36, 0.035, 0.004)), Vector3(0, 0.34, -0.006), _mat(Color(0.35, 0.18, 0.5)))
	titre.name = "titre"
	var tablette := _mesh(chevalet, _boite(Vector3(0.9, 0.04, 0.12)), Vector3(0, 0.78, -0.03), bois)
	tablette.name = "tablette"
	sceau = Node3D.new()
	sceau.name = "Sceau"
	parch.add_child(sceau)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.07
	cyl.height = 0.012
	var s := _mesh(sceau, cyl, Vector3(0.22, -0.28, -0.01), _mat(Color(0.95, 0.75, 0.25), 0.8))
	s.rotation.x = PI * 0.5
	var ruban := _mesh(sceau, _boite(Vector3(0.05, 0.14, 0.004)), Vector3(0.22, -0.36, -0.008), _mat(Color(0.55, 0.12, 0.2)))
	ruban.name = "ruban"
	sceau.visible = false
	# on le lit (E), debout devant, au sud
	if objets != null and objets.has_method("ajouter"):
		var me = self
		objets.ajouter({"id": "bulletin", "a": monde(CHEVALET + Vector3(0, 0, -0.75)), "portee": 1.3, "prio": 0.5,
			"verbe": "lire le bulletin de l'Académie", "call": func(): me._dire(me.bulletin(), 14.0)})


func _decor() -> void:
	if sceau != null:
		sceau.visible = bool(st().get("diplome", false))


# =================================================================== l'état (enregistré avec la partie)

func st() -> Dictionary:
	if ombrelac == null:
		return {}
	var s: Dictionary = ombrelac.state
	if not s.has("cours") or not (s["cours"] is Dictionary):
		s["cours"] = {}
	var c: Dictionary = s["cours"]
	if not c.has("notes") or not (c["notes"] is Dictionary):
		c["notes"] = {}
	if not c.has("recues") or not (c["recues"] is Array):
		c["recues"] = []
	if not c.has("actuelle") or not (c["actuelle"] is Dictionary):
		c["actuelle"] = {}
	return c


## Les notes d'une matière : un tableau de [points, sur] (une par leçon réussie, dans l'ordre)
func notes(m: String) -> Array:
	var n: Dictionary = st()["notes"]
	if not n.has(m) or not (n[m] is Array):
		n[m] = []
	return n[m]


func reussies(m: String) -> int:
	return notes(m).size()


func matiere_finie(m: String) -> bool:
	return reussies(m) >= (C[m]["lecons"] as Array).size()


func tout_fini() -> bool:
	for m in ORDRE:
		if not matiere_finie(m):
			return false
	return true


func diplome() -> bool:
	return bool(st().get("diplome", false))


func actuelle() -> Dictionary:
	return st()["actuelle"]


func lecon(m: String, l: int) -> Dictionary:
	return (C[m]["lecons"] as Array)[l]


static func mention(pts: int, sur: int) -> String:
	var r: float = float(pts) / float(maxi(sur, 1))
	if r >= 0.999:
		return "Excellent"
	if r >= 0.75:
		return "Très bien"
	if r >= 0.5:
		return "Bien"
	return "À revoir"


func _sur(m: String, l: int) -> int:
	var le: Dictionary = lecon(m, l)
	return (le["questions"] as Array).size() + (2 if not (le["pratique"] as Dictionary).is_empty() else 0)


# =================================================================== le jeu autour

func _dire(txt: String, s: float = 8.0) -> void:
	if objets != null and objets.has_method("say"):
		objets.say(txt, s)
	elif main != null and main.has_method("_show_message_v28"):
		main._show_message_v28(txt)


func _sfx(nom: String, at: Variant = null) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(nom, at)


func _nuit() -> bool:
	return objets.call("_nuit") if objets != null and objets.has_method("_nuit") else false


func _joueur() -> Vector3:
	return main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else Vector3(0, -9999, 0)


func _npc(id: String) -> Node:
	if vie == null or vie.get("by_id") == null:
		return null
	var n: Variant = (vie.by_id as Dictionary).get(id)
	return n if n != null and is_instance_valid(n) else null


func _maitre_de(id: String) -> String:
	for m in ORDRE:
		if str(C[m]["maitre"]) == id:
			return m
	return ""


## Le maître est à son poste de cours (à moins de 5 m)
func en_classe(npc: Node, poste: String) -> bool:
	if npc == null or vie == null or vie.get("spots") == null:
		return false
	var sp: Dictionary = (vie.spots as Dictionary).get(poste, {})
	return not sp.is_empty() and (npc as Node3D).global_position.distance_to(sp["pos"]) < 5.0


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	if not jeu.is_empty():
		_jeu_tick(delta)
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	_sync()


## Le carnet : la Rectrice porte « Le diplôme de l'Académie » (où en sont les cinq matières)
func _sync() -> void:
	var n: Node = _npc("vesperine_om")
	if n == null or not (n.get("profile") is Dictionary) or n.get("brain") == null:
		return
	var pr: Dictionary = n.profile
	var parts: Array = []
	for m in ORDRE:
		parts.append("%s %d/3" % [str(C[m]["nom"]).to_lower(), reussies(m)])
	var obj: String = ("Recevoir le diplôme des mains de la Rectrice" if tout_fini() else "Réussir les cours (" + ", ".join(parts) + ")")
	pr["quete"] = {"sujet": "Le diplôme de l'Académie", "objets": {obj: 1}, "note": "m'a parlé du diplôme de l'Académie",
		"souvenir": "Et vous voilà diplômé de l'Académie d'Ombrelac.", "affinite": 0.0}
	var rep: Dictionary = pr.get("repliques", {})
	rep["quete_manque"] = [{"t": _rappel(), "si": {}}]
	rep["quete_fin"] = [{"t": "Votre diplôme est au registre de l'Académie. Pour toujours.", "si": {}}]
	pr["repliques"] = rep
	var a: Dictionary = actuelle()
	var commence: bool = not a.is_empty()
	for m in ORDRE:
		commence = commence or reussies(m) > 0
	n.brain.memoire["quete"] = "finie" if diplome() else ("demandee" if commence else "")


func _rappel() -> String:
	if tout_fini():
		return "Vous avez réussi vos cinq matières. Venez me voir : il est temps de vous remettre votre diplôme."
	var a: Dictionary = actuelle()
	if not a.is_empty():
		var m: String = str(a["m"])
		return "Vous êtes en pleine leçon de %s, « %s ». %s" % [str(C[m]["nom"]).to_lower(), str(lecon(m, int(a["l"]))["titre"]), _consigne_courte()]
	return "Cinq matières : les astres, les élixirs, la géométrie, les sortilèges et la calligraphie. Allez voir chaque maître à l'heure de son cours, et revenez me voir quand les cinq seront réussies. Le bulletin est affiché au cloître, sur le chevalet, près de la fontaine."


func _consigne_courte() -> String:
	var a: Dictionary = actuelle()
	if a.is_empty():
		return ""
	var nom: String = str(_npc(str(C[str(a["m"])]["maitre"])).display_name) if _npc(str(C[str(a["m"])]["maitre"])) != null else "le maître"
	match str(a.get("etape", "")):
		"quiz":
			return "Il reste des questions : retournez voir %s." % nom
		"pratique":
			return str(lecon(str(a["m"]), int(a["l"]))["consigne"]).replace("L'exercice : ", "Exercice : ")
		"note":
			return "L'exercice est fait : %s vous attend pour la note." % nom
	return ""


# =================================================================== les sujets (la conversation)

func _id(m: String, action: String) -> String:
	return "q56:service:omc_%s_%s" % [m, action]


func sujets(npc: Node) -> Array:
	var id: String = str(npc.profile.get("id", ""))
	var out: Array = []
	if id == "vesperine_om":
		if tout_fini() and not diplome():
			out.append({"id": _id("rectrice", "diplome"), "label": "★ J'ai réussi mes cinq matières."})
		elif not diplome():
			out.append({"id": _id("rectrice", "cours"), "label": "★ Comment suivre les cours de l'Académie ?"})
		return out
	var m: String = _maitre_de(id)
	if m == "":
		return out
	var a: Dictionary = actuelle()
	if a.is_empty():
		if not matiere_finie(m):
			var l: int = reussies(m)
			out.append({"id": _id(m, "lecon"), "label": "★ Suivre la leçon : « %s » (%d/3)" % [str(lecon(m, l)["titre"]), l + 1]})
	elif str(a["m"]) == m:
		match str(a.get("etape", "")):
			"quiz":
				out.append({"id": _id(m, "reprendre"), "label": "★ Je suis prêt pour les questions."})
			"pratique":
				out.append({"id": _id(m, "consigne"), "label": "★ Rappelez-moi l'exercice."})
			"note":
				out.append({"id": _id(m, "note"), "label": "★ J'ai fini l'exercice : ma note ?"})
	return out


func choisir(npc: Node, quoi: String) -> Dictionary:
	# quoi : « <matière>_<action> » (l'action peut contenir des chiffres : r0x2 = question 0, réponse 2)
	var cut: int = quoi.find("_")
	if cut < 0:
		return {}
	var m: String = quoi.substr(0, cut)
	var action: String = quoi.substr(cut + 1)
	if m == "rectrice":
		return _rectrice(npc, action)
	if not C.has(m):
		return {}
	var a: Dictionary = actuelle()
	if action == "lecon":
		if not a.is_empty() or matiere_finie(m):
			return {}
		var l: int = reussies(m)
		var le: Dictionary = lecon(m, l)
		if bool(le.get("nuit", false)):
			if not _nuit() or not en_classe(npc, str(le["poste"])):
				return {"texte": "Cette leçon-là se donne la nuit, à l'Observatoire, en haut de la Tour de l'Astrolabe, devant la Grande Lunette. Venez m'y retrouver après 20 h : j'y suis jusqu'à 2 h du matin.", "geste": "parle"}
		elif not en_classe(npc, str(le["poste"])):
			return {"texte": str(C[m]["horaire"]), "geste": "parle"}
		st()["actuelle"] = {"m": m, "l": l, "q": 0, "pts": 0, "etape": "quiz"}
		_sfx("ui_quete")
		_sync()
		return {"texte": str(le["expl"]), "geste": "parle", "choix": [{"id": _id(m, "reprendre"), "label": "Je suis prêt pour les questions."}]}
	if a.is_empty() or str(a["m"]) != m:
		return {}
	var le2: Dictionary = lecon(m, int(a["l"]))
	match action:
		"reprendre":
			if str(a.get("etape", "")) != "quiz":
				return {}
			return _question(m, "")
		"consigne":
			return {"texte": str(le2["consigne"]), "geste": "parle"}
		"note":
			if str(a.get("etape", "")) != "note":
				return {}
			return _noter(npc, m)
	if action.begins_with("r") and action.contains("x") and str(a.get("etape", "")) == "quiz":
		var qi: int = int(action.substr(1, action.find("x") - 1))
		var k: int = int(action.substr(action.find("x") + 1))
		var qs: Array = le2["questions"]
		if qi != int(a["q"]) or qi >= qs.size():
			return {}
		var q: Array = qs[qi]
		var juste: bool = k == int(q[2])
		var retour: String
		if juste:
			a["pts"] = int(a["pts"]) + 1
			retour = ["Exact !", "Parfait.", "Très juste !", "Bonne réponse."][qi % 4]
			_sfx("ui_quete")
		else:
			retour = str(q[3])
		a["q"] = qi + 1
		if int(a["q"]) < qs.size():
			return _question(m, retour + "\n\n")
		# les questions sont finies : l'exercice (ou la note, s'il n'y en a pas)
		if (le2["pratique"] as Dictionary).is_empty():
			a["etape"] = "note"
			_sync()
			var r: Dictionary = _noter(npc, m)
			r["texte"] = retour + "\n\n" + str(r["texte"])
			return r
		a["etape"] = "pratique"
		_sync()
		return {"texte": retour + "\n\n" + str(le2["consigne"]), "geste": "parle"}
	return {}


func _question(m: String, avant: String) -> Dictionary:
	var a: Dictionary = actuelle()
	var qi: int = int(a["q"])
	var qs: Array = lecon(m, int(a["l"]))["questions"]
	var q: Array = qs[qi]
	var ch: Array = []
	for k in range((q[1] as Array).size()):
		ch.append({"id": _id(m, "r%dx%d" % [qi, k]), "label": str(q[1][k])})
	return {"texte": avant + "Question %d sur %d : %s" % [qi + 1, qs.size(), str(q[0])], "geste": "parle", "choix": ch}


## La note de la leçon (on revient voir le maître) : réussie, elle va au bulletin ; « À revoir », on recommence
func _noter(npc: Node, m: String) -> Dictionary:
	var a: Dictionary = actuelle()
	var l: int = int(a["l"])
	var pts: int = int(a["pts"])
	var sur: int = _sur(m, l)
	var men: String = mention(pts, sur)
	var titre: String = str(lecon(m, l)["titre"])
	if men == "À revoir":
		st()["actuelle"] = {}
		_sync()
		return {"texte": "%d sur %d : à revoir. Ce n'est pas grave : on apprend plus de ses erreurs que de ses réussites. Revenez quand vous voulez, nous reprendrons « %s » depuis le début." % [pts, sur, titre], "geste": "parle"}
	var gives: Array = []
	var derniere: bool = l + 1 >= (C[m]["lecons"] as Array).size()
	if derniere and not (st()["recues"] as Array).has(m):
		gives = C[m]["recompense"]
		if quetes != null and quetes.has_method("_peut_donner") and not quetes._peut_donner(gives):
			return quetes._sac_plein(gives)
	notes(m).append([pts, sur])
	st()["actuelle"] = {}
	var texte: String = "« %s » : %d sur %d. Mention : %s !" % [titre, pts, sur, men]
	var msgs: Array = []
	var pr: Variant = main.get("progression_v63") if main != null else null
	if pr != null and pr.has_method("quest_xp"):
		msgs.append("+%d XP" % int(pr.quest_xp("om_cours_%s_%d" % [m, l], 1)))
	if main != null and main.has_method("_show_message_v28"):
		main._show_message_v28("Leçon réussie : %s, « %s » (%s)%s" % [str(C[m]["nom"]), titre, men, ("  (" + ", ".join(msgs) + ")") if not msgs.is_empty() else ""])
	if npc != null and npc.get("brain") != null and npc.brain.has_method("_bond"):
		npc.brain._bond(4.0)
	if derniere:
		(st()["recues"] as Array).append(m)
		texte += "\n\n" + str(C[m]["fin"])
		if pr != null and pr.has_method("on_quest"):
			pr.on_quest("om_cours_" + m, 3)
		if main != null and main.has_method("jingle"):
			main.jingle("victoire")
		if tout_fini():
			texte += "\n\n(Les cinq matières sont réussies ! La Rectrice Vespérine vous attend pour le diplôme.)"
	else:
		_sfx("ui_quete")
		texte += " Leçon suivante : « %s »." % str(lecon(m, l + 1)["titre"])
	var j: Variant = main.get("journal_v56") if main != null else null
	var now: float = float(j._now()) if j != null and j.has_method("_now") else 0.0
	Societe.noter("quete", str(C[m]["maitre"]), now, {"titre": titre})
	_sync()
	var r := {"texte": texte, "geste": "rire" if men == "Excellent" else "salut"}
	if not gives.is_empty():
		r["donner"] = gives
	return r


func _rectrice(npc: Node, action: String) -> Dictionary:
	match action:
		"cours":
			if diplome():
				return {}
			return {"texte": "Nos cours sont ouverts aux visiteurs qui ont envie d'apprendre. " + _rappel() + " Chaque maître donne trois leçons : on écoute, on répond à ses questions, on fait l'exercice, et on revient le voir pour la note.", "geste": "parle"}
		"diplome":
			if not tout_fini() or diplome():
				return {}
			var gives: Array = [["piece_or", 10]]
			if quetes != null and quetes.has_method("_peut_donner") and not quetes._peut_donner(gives):
				return quetes._sac_plein(gives)
			st()["diplome"] = true
			_decor()
			var pr: Variant = main.get("progression_v63") if main != null else null
			var xp: String = ""
			if pr != null and pr.has_method("quest_xp"):
				xp = "  (+%d XP)" % int(pr.quest_xp("om_diplome", 5))
			if pr != null and pr.has_method("on_quest"):
				pr.on_quest("om_diplome", 5)
			if main != null and main.has_method("_show_message_v28"):
				main._show_message_v28("Diplômé de l'Académie d'Ombrelac !" + xp)
			if main != null and main.has_method("jingle"):
				main.jingle("victoire")
			if npc != null and npc.get("brain") != null and npc.brain.has_method("_bond"):
				npc.brain._bond(12.0)
			var j: Variant = main.get("journal_v56") if main != null else null
			var now: float = float(j._now()) if j != null and j.has_method("_now") else 0.0
			Societe.noter("quete", "vesperine_om", now, {"titre": "Le diplôme de l'Académie"})
			_sync()
			return {"texte": "Approchez. … Par les pouvoirs qui me sont confiés par les fondateurs, et par Hortense, qui me l'a très fortement conseillé, je vous déclare diplômé de l'Académie d'Ombrelac. Astres, élixirs, géométrie, sortilèges, calligraphie : vos maîtres sont fiers de vous. Moi aussi. Votre nom est inscrit au registre, et le sceau d'or est posé sur votre bulletin, au cloître. Et ceci, pour fêter ça : dix pièces d'or. Ne les dépensez pas toutes en chocolat chaud. Ou si. C'est votre fête.", "geste": "salut", "donner": gives}
	return {}


## Le bulletin (le chevalet du cloître)
func bulletin() -> String:
	var lignes: Array = []
	for m in ORDRE:
		var ns: Array = notes(m)
		var t: Array = []
		for i in range(ns.size()):
			t.append(mention(int(ns[i][0]), int(ns[i][1])))
		lignes.append("%s : %s" % [str(C[m]["nom"]), (", ".join(t) + (" (réussi !)" if matiere_finie(m) else "")) if not t.is_empty() else "pas encore de note"])
	var tete: String = "BULLETIN DE L'ACADÉMIE D'OMBRELAC. "
	if diplome():
		tete += "Sceau d'or : DIPLÔMÉ. "
	return tete + " ; ".join(lignes) + "."


# =================================================================== les exercices

## (appelé par objets_ombrelac.gd, avant tout le reste) : E sur un objet. true : c'est pour un exercice
func intercepte(o: Dictionary) -> bool:
	var a: Dictionary = actuelle()
	if a.is_empty() or str(a.get("etape", "")) != "pratique":
		return false
	var p: Dictionary = lecon(str(a["m"]), int(a["l"]))["pratique"]
	match str(p.get("type", "")):
		"cartes":
			if est_carte_astres(o):
				_carte(o)
				return true
		"jauge":
			if not jeu.is_empty() and str(jeu.get("type", "")) == "jauge":
				if int(jeu["o"].get("n", -1)) == int(o.get("n", -2)) and str(jeu["o"].get("sorte", "")) == str(o.get("sorte", "")):
					appuyer()
					return true
			if _bon_objet(o, p):
				_jauge_debut(o, p)
				return true
		"mannequins":
			if str(o.get("sorte", "")) == "mannequin":
				if jeu.is_empty():
					_mannequins_debut(p)
				else:
					toucher(o)
				return true
	return false


func _bon_objet(o: Dictionary, p: Dictionary) -> bool:
	if str(o.get("sorte", "")) != str(p.get("sorte", "")):
		return false
	if p.has("grande") and bool(o.get("grande", false)) != bool(p["grande"]):
		return false
	if p.has("m") and str(o.get("m", "")) != str(p["m"]):
		return false
	return true


func _finir_pratique(pts: int, txt: String) -> void:
	var a: Dictionary = actuelle()
	_jeu_vider()
	if a.is_empty():
		return
	a["pts"] = int(a["pts"]) + pts
	a["etape"] = "note"
	var nom: String = str(_npc(str(C[str(a["m"])]["maitre"])).display_name) if _npc(str(C[str(a["m"])]["maitre"])) != null else "le maître"
	_sync()
	_dire(txt + "  (Exercice terminé : %s vous attend pour la note.)" % nom, 9.0)


func _jeu_vider() -> void:
	if jeu.has("noeud") and is_instance_valid(jeu["noeud"]):
		(jeu["noeud"] as Node).queue_free()
	if str(jeu.get("type", "")) == "runes":
		for i in range(runes.size()):
			rune_allumer(i, false)
			(runes[i] as Node3D).visible = false
	if str(jeu.get("type", "")) == "mannequins" and jeu.has("marques"):
		for mk in jeu["marques"]:
			if is_instance_valid(mk):
				(mk as Node).queue_free()
	jeu = {}


## Les cartes du ciel de la Salle des Astres (à moins de 13 m du poste de Maître Fauconnier)
func est_carte_astres(o: Dictionary) -> bool:
	if str(o.get("sorte", "")) != "carte_ciel" or vie == null or vie.get("spots") == null:
		return false
	var sp: Dictionary = (vie.spots as Dictionary).get("astres_maitre", {})
	if sp.is_empty():
		return false
	var c: Vector3 = sp["pos"]
	var m: Vector3 = (o["a"] as Vector3).lerp(o["b"], 0.5)
	return Vector2(m.x - c.x, m.z - c.z).length() < 13.0 and absf(m.y - c.y) < 3.0


func cartes_astres() -> Array:
	return objets.objets.filter(func(x): return est_carte_astres(x))


# --- les cartes du ciel : trouver la bonne (on la tire au sort au premier regard)
func _carte(o: Dictionary) -> void:
	var cartes: Array = cartes_astres()
	var a: Dictionary = actuelle()
	if not a.has("carte"):
		a["carte"] = int(cartes[_rng.randi() % cartes.size()]["n"]) if cartes.size() > 1 else int(o["n"])
		a["essais"] = 0
	a["essais"] = int(a["essais"]) + 1
	_sfx("carte", o["a"])
	if int(o["n"]) == int(a["carte"]):
		var e: int = int(a["essais"])
		var pts: int = 2 if e <= 2 else 1
		a.erase("carte")
		a.erase("essais")
		_finir_pratique(pts, "La voilà ! La Grande Casserole, son bord prolongé cinq fois… et la petite étoile tranquille au bout de la Petite Ourse : l'étoile du Nord. Trouvée en %d regard%s." % [e, "" if e == 1 else "s"])
	else:
		_dire(["Sur cette carte : le Cygne, la Lyre, l'Aigle. Pas de Petite Ourse.", "Sur cette carte : Orion et ses trois étoiles en ligne. Pas d'étoile du Nord ici.", "Sur cette carte : le Scorpion, le Sagittaire. Ce sont des étoiles du sud. Cherchez ailleurs.", "Sur cette carte : Cassiopée, en W. Tout près… mais pas la Petite Ourse."][int(a["essais"]) % 4], 5.0)


# --- la jauge : appuyer sur E au bon moment
func _jauge_debut(o: Dictionary, p: Dictionary) -> void:
	_jeu_vider()
	var n := Node3D.new()
	n.name = "Exercice_jauge"
	add_child(n)
	var mid: Vector3 = (o["a"] as Vector3).lerp(o["b"], 0.5)
	var f: Vector3 = o["face"]
	var mode: String = str(p["mode"])
	jeu = {"type": "jauge", "o": o, "mode": mode, "vitesse": float(p.get("vitesse", 1.0)), "besoin": int(p.get("besoin", 3)),
		"touches": 0, "rates": 0, "t": 0.0, "noeud": n, "eclat": 0.0}
	match mode:
		"couleur":
			# la fiole qui change de couleur, au-dessus de la paillasse
			n.position = mid - f * 0.55 + Vector3(0, 1.22, 0)
			var m := _mat(COULEURS[0], 2.0)
			var b := _mesh(n, _boule(0.12), Vector3.ZERO, m)
			b.name = "fiole"
			var col := _mesh(n, _boite(Vector3(0.06, 0.14, 0.06)), Vector3(0, 0.16, 0), _mat(Color(0.8, 0.9, 0.95)))
			col.name = "col"
			jeu["mat"] = m
		"angle":
			# la règle de craie qui tourne au tableau, la ligne de référence (verticale)
			n.position = mid - f * 0.62 + Vector3(0, 1.75, 0)
			n.basis = Basis.looking_at(-f, Vector3.UP) if f.length() > 0.1 else Basis.IDENTITY
			var craie := _mat(Color(0.95, 0.95, 0.9), 0.5)
			var ref := _mesh(n, _boite(Vector3(0.03, 1.1, 0.01)), Vector3(0, 0, 0.02), craie)
			ref.name = "reference"
			var pivot := Node3D.new()
			pivot.name = "regle"
			n.add_child(pivot)
			pivot.position = Vector3(0, 0, 0.03)
			_mesh(pivot, _boite(Vector3(1.3, 0.035, 0.01)), Vector3.ZERO, _mat(Color(1.0, 0.95, 0.6), 0.8))
			var marque := _mesh(n, _boule(0.04), Vector3(0, 0, 0.035), _mat(Color(1.0, 0.4, 0.3), 1.0))
			marque.name = "centre"
			jeu["regle"] = pivot
		"balancier":
			# la planète (ou l'étoile filante) qui traverse le cercle de la lunette
			var j: Vector3 = _joueur()
			var vers: Vector3 = Vector3(mid.x - j.x, 0, mid.z - j.z)
			if vers.length() < 0.1:
				vers = Vector3(0, 0, -1)
			vers = vers.normalized()
			n.position = mid + Vector3(0, 2.2 if bool(o.get("grande", false)) else 1.75, 0) - vers * 0.2
			n.basis = Basis.looking_at(vers, Vector3.UP)
			var anneau := TorusMesh.new()
			anneau.inner_radius = 0.1
			anneau.outer_radius = 0.125
			var ra := _mesh(n, anneau, Vector3.ZERO, _mat(Color(0.7, 0.85, 1.0), 1.2))
			ra.rotation.x = PI * 0.5
			ra.name = "cercle"
			var pl := _mesh(n, _boule(0.05), Vector3.ZERO, _mat(Color(1.0, 0.95, 0.7) if bool(o.get("grande", false)) else Color(1.0, 0.85, 0.5), 2.5))
			pl.name = "astre"
			jeu["astre"] = pl
	_sfx("sort_lumiere", n.position)
	_dire(_consigne_jeu() + "  (0 / %d)" % int(jeu["besoin"]), 6.0)


func _consigne_jeu() -> String:
	match str(jeu.get("mode", "")):
		"couleur":
			return "La fiole change de couleur : appuie sur E quand elle est verte."
		"angle":
			return "La règle de craie tourne : appuie sur E quand elle fait un angle droit avec la ligne."
		"balancier":
			return "L'astre traverse la lunette : appuie sur E quand il passe au centre du cercle."
	return ""


## La phase de la jauge, de 0 à 1 (elle tourne en boucle)
func _phase() -> float:
	var per: float = 2.4
	return fposmod(float(jeu["t"]) * float(jeu["vitesse"]) / per, 1.0)


## Au bon moment ?
func dans_la_fenetre() -> bool:
	var ph: float = _phase()
	match str(jeu.get("mode", "")):
		"couleur":
			return ph >= 0.5 and ph < 0.72
		"angle":
			var ang: float = fposmod(ph * 360.0, 180.0)
			return absf(ang - 90.0) <= FENETRE_ANGLE
		"balancier":
			return absf(sin(ph * TAU)) < 0.16
	return false


## Mettre la jauge au bon moment (pour les tests et les photos)
func caler(bon: bool) -> void:
	if jeu.is_empty() or str(jeu.get("type", "")) != "jauge":
		return
	var cible: float
	match str(jeu["mode"]):
		"couleur":
			cible = 0.61 if bon else 0.1
		"angle":
			cible = 0.25 if bon else 0.05
		_:
			cible = 0.0 if bon else 0.25
	var per: float = 2.4
	var k: float = floor(float(jeu["t"]) * float(jeu["vitesse"]) / per)
	jeu["t"] = (k + cible) * per / float(jeu["vitesse"])
	_jauge_montrer()


func appuyer() -> void:
	if jeu.is_empty() or str(jeu.get("type", "")) != "jauge":
		return
	var pos: Vector3 = (jeu["noeud"] as Node3D).position
	if dans_la_fenetre():
		jeu["touches"] = int(jeu["touches"]) + 1
		jeu["eclat"] = 0.5
		match str(jeu["mode"]):
			"couleur":
				_sfx("bulles", pos)
			"angle":
				_sfx("gribouillis_griffe", pos)
			_:
				_sfx("sort_lumiere", pos)
		if int(jeu["touches"]) >= int(jeu["besoin"]):
			var r: int = int(jeu["rates"])
			var fin: String
			match str(jeu["mode"]):
				"couleur":
					fin = "La fiole prend une belle couleur claire, et une odeur de miel monte de la paillasse. Réussi !"
				"angle":
					fin = "Au tableau, les angles droits sont parfaits. Même Maître Équerre n'y trouverait rien à redire."
				_:
					fin = "Dans l'oculaire, l'astre est bien au centre du cercle. Joli coup d'œil !"
			_finir_pratique(2 if r == 0 else 1, fin + (" Sans une erreur." if r == 0 else " (%d erreur%s.)" % [r, "" if r == 1 else "s"]))
			return
		_dire("Juste !  (%d / %d)" % [int(jeu["touches"]), int(jeu["besoin"])], 2.5)
		return
	jeu["rates"] = int(jeu["rates"]) + 1
	match str(jeu["mode"]):
		"couleur":
			_sfx("explosion_feu", pos)
			_bouffee(pos)
		"angle":
			_sfx("touche_pierre", pos)
		_:
			_sfx("cliquet_roue", pos)
	if int(jeu["rates"]) >= 3:
		var fin2: String = "Pfff… un nuage de fumée violette : la fiole est ratée." if str(jeu["mode"]) == "couleur" else "Trois erreurs : l'exercice est manqué."
		_finir_pratique(0, fin2 + " Le maître notera quand même tes réponses.")
		return
	_dire(("Trop tôt, ou trop tard ! Pouf : une petite bouffée de fumée.  (%d / %d)" if str(jeu["mode"]) == "couleur" else "Raté ! Pas au bon moment.  (%d / %d)") % [int(jeu["touches"]), int(jeu["besoin"])], 2.5)


func _bouffee(p: Vector3) -> void:
	var b := _mesh(self, _boule(0.15), p + Vector3(0, 0.15, 0), _mat(Color(0.55, 0.5, 0.65, 0.7)))
	(b.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if b.is_inside_tree():
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(b, "scale", Vector3.ONE * 4.0, 1.2)
		tw.tween_property(b, "position", b.position + Vector3(0, 0.8, 0), 1.2)
		tw.tween_property(b.material_override, "albedo_color:a", 0.0, 1.2)
		tw.chain().tween_callback(b.queue_free)
	else:
		b.queue_free()


func _jauge_montrer() -> void:
	var ph: float = _phase()
	match str(jeu["mode"]):
		"couleur":
			var m: StandardMaterial3D = jeu["mat"]
			var i: int = 2 if (ph >= 0.5 and ph < 0.72) else (0 if ph < 0.25 else (1 if ph < 0.5 else 3))
			m.albedo_color = COULEURS[i]
			m.emission = COULEURS[i]
			m.emission_energy_multiplier = 2.0 + 3.0 * float(jeu["eclat"])
		"angle":
			(jeu["regle"] as Node3D).rotation.z = ph * TAU
		"balancier":
			(jeu["astre"] as Node3D).position = Vector3(sin(ph * TAU) * 0.55, 0, 0)


# --- les runes du Cercle : regarder, retenir, marcher dessus dans le même ordre
func _runes_debut(p: Dictionary) -> void:
	_jeu_vider()
	var seq: Array = []
	var prec: int = -1
	for i in range(int(p.get("n", 3))):
		var r: int = _rng.randi() % RUNES_N
		while r == prec:
			r = _rng.randi() % RUNES_N
		seq.append(r)
		prec = r
	jeu = {"type": "runes", "seq": seq, "k": 0, "rates": 0, "t": 0.0, "phase": "montre", "sous": -1}
	for i in range(runes.size()):
		(runes[i] as Node3D).visible = true
		rune_allumer(i, false)
	_dire("Les runes s'éveillent. Regarde bien l'ordre…", 4.0)


func _centre_cercle() -> Vector3:
	var s: Vector3 = Vector3.ZERO
	for r in runes:
		s += (r as Node3D).position
	return s / float(maxi(runes.size(), 1))


## La rune sous les pieds du joueur (-1 : aucune)
func rune_sous(p: Vector3) -> int:
	for i in range(runes.size()):
		var q: Vector3 = rune_pos(i)
		if Vector2(p.x - q.x, p.z - q.z).length() < 0.42 and absf(p.y - q.y) < 1.2:
			return i
	return -1


func marcher_sur(i: int) -> void:
	if jeu.is_empty() or str(jeu.get("type", "")) != "runes" or str(jeu["phase"]) != "joue":
		return
	var seq: Array = jeu["seq"]
	var k: int = int(jeu["k"])
	if i == int(seq[k]):
		rune_allumer(i, true)
		_sfx("sort_lumiere", rune_pos(i))
		jeu["k"] = k + 1
		jeu["eteindre"] = [i, 0.5]
		if int(jeu["k"]) >= seq.size():
			var r: int = int(jeu["rates"])
			_finir_pratique(2 if r == 0 else 1, "Les %d runes répondent l'une après l'autre, et le Cercle s'illumine tout entier ! Réussi%s." % [seq.size(), " du premier coup" if r == 0 else ""])
		return
	jeu["rates"] = int(jeu["rates"]) + 1
	_sfx("impact_arcane", rune_pos(i))
	if int(jeu["rates"]) >= 3:
		_finir_pratique(0, "Les runes se taisent. Trois fois dans le désordre : l'exercice est manqué. Dame Sortelame notera quand même tes réponses.")
		return
	for j in range(runes.size()):
		rune_allumer(j, false)
	jeu["k"] = 0
	jeu["phase"] = "montre"
	jeu["t"] = -1.0
	_dire("Ce n'est pas la bonne rune : elles se taisent. Calmement… on recommence. Regarde bien.  (erreur %d sur 3)" % int(jeu["rates"]), 4.0)


func _runes_tick(delta: float) -> void:
	jeu["t"] = float(jeu["t"]) + delta
	var seq: Array = jeu["seq"]
	if str(jeu["phase"]) == "montre":
		var t: float = float(jeu["t"])
		if t < 0.0:
			return
		var pas: float = 0.95
		var i: int = int(t / pas)
		for j in range(runes.size()):
			rune_allumer(j, false)
		if i < seq.size():
			if fposmod(t, pas) < 0.7:
				rune_allumer(int(seq[i]), true)
				if not jeu.has("dit_%d" % i) or int(jeu["dit_%d" % i]) != int(jeu["rates"]):
					jeu["dit_%d" % i] = int(jeu["rates"])
					_sfx("sort_lumiere", rune_pos(int(seq[i])))
		else:
			jeu["phase"] = "joue"
			jeu["sous"] = rune_sous(_joueur())
			_dire("À toi : marche sur les runes, dans le même ordre.", 4.0)
		return
	if jeu.has("eteindre"):
		var e: Array = jeu["eteindre"]
		e[1] = float(e[1]) - delta
		if float(e[1]) <= 0.0:
			rune_allumer(int(e[0]), false)
			jeu.erase("eteindre")
	var s: int = rune_sous(_joueur())
	if s != int(jeu["sous"]):
		jeu["sous"] = s
		if s >= 0:
			marcher_sur(s)


# --- la passe d'armes : le mannequin qui s'allume
func _mannequins_debut(p: Dictionary) -> void:
	_jeu_vider()
	var ms: Array = objets.objets.filter(func(x): return str(x["sorte"]) == "mannequin")
	if ms.is_empty():
		return
	var marques: Array = []
	for o in ms:
		var mk := _mesh(self, _boule(0.13), (o["a"] as Vector3) + Vector3(0, 2.05, 0), _mat(Color(1.0, 0.8, 0.3), 3.0))
		mk.visible = false
		marques.append(mk)
	jeu = {"type": "mannequins", "ms": ms, "marques": marques, "besoin": int(p.get("n", 5)), "touches": 0, "rates": 0,
		"allume": -1, "t": 0.0, "pause": 1.2}
	_sfx("tambour")
	_dire("En garde ! Touche (E) le mannequin qui s'allume, avant qu'il ne s'éteigne.  (0 / %d)" % int(jeu["besoin"]), 5.0)


func toucher(o: Dictionary) -> void:
	if jeu.is_empty() or str(jeu.get("type", "")) != "mannequins":
		return
	var ms: Array = jeu["ms"]
	var i: int = -1
	for k in range(ms.size()):
		if int(ms[k]["n"]) == int(o.get("n", -1)):
			i = k
	if i >= 0 and i == int(jeu["allume"]):
		jeu["touches"] = int(jeu["touches"]) + 1
		_sfx("coup_poing", o["a"])
		_eteindre_mannequin()
		if int(jeu["touches"]) >= int(jeu["besoin"]):
			var r: int = int(jeu["rates"])
			_finir_pratique(2 if r == 0 else 1, "Cinq touches ! Les mannequins s'inclinent (enfin, ils penchent un peu). Belle passe d'armes%s." % (", sans une faute" if r == 0 else ""))
			return
		_dire("Touché !  (%d / %d)" % [int(jeu["touches"]), int(jeu["besoin"])], 2.0)
		return
	_rate_mannequin("Pas celui-là !")


func _rate_mannequin(pourquoi: String) -> void:
	jeu["rates"] = int(jeu["rates"]) + 1
	_sfx("esquive")
	_eteindre_mannequin()
	if int(jeu["rates"]) >= 3:
		_finir_pratique(0, "Trois fautes : la passe d'armes est perdue. Dame Sortelame notera quand même tes réponses.")
		return
	_dire("%s  (faute %d sur 3)" % [pourquoi, int(jeu["rates"])], 2.5)


func _eteindre_mannequin() -> void:
	var a: int = int(jeu["allume"])
	if a >= 0:
		(jeu["marques"][a] as Node3D).visible = false
	jeu["allume"] = -1
	jeu["t"] = 0.0
	jeu["pause"] = 0.7


## Allumer un mannequin (pour les tests et les photos : lequel)
func allumer_mannequin(i: int) -> void:
	var a: int = int(jeu["allume"])
	if a >= 0:
		(jeu["marques"][a] as Node3D).visible = false
	jeu["allume"] = i
	jeu["t"] = 0.0
	(jeu["marques"][i] as Node3D).visible = true


func _mannequins_tick(delta: float) -> void:
	jeu["t"] = float(jeu["t"]) + delta
	if int(jeu["allume"]) < 0:
		if float(jeu["t"]) >= float(jeu["pause"]):
			var n: int = (jeu["ms"] as Array).size()
			var i: int = _rng.randi() % n
			if n > 1 and i == int(jeu.get("dernier", -1)):
				i = (i + 1) % n
			jeu["dernier"] = i
			allumer_mannequin(i)
		return
	if float(jeu["t"]) > 2.0:
		_rate_mannequin("Trop lent : il s'est éteint !")


func _jeu_tick(delta: float) -> void:
	var a: Dictionary = actuelle()
	if a.is_empty() or str(a.get("etape", "")) != "pratique":
		_jeu_vider()
		return
	var j: Vector3 = _joueur()
	match str(jeu.get("type", "")):
		"jauge":
			jeu["t"] = float(jeu["t"]) + delta
			jeu["eclat"] = maxf(float(jeu["eclat"]) - delta, 0.0)
			_jauge_montrer()
			var c: Vector3 = (jeu["o"]["a"] as Vector3).lerp(jeu["o"]["b"], 0.5)
			if Vector2(j.x - c.x, j.z - c.z).length() > 4.5 or absf(j.y - c.y) > 3.0:
				_jeu_vider()
				_dire("Tu t'éloignes : l'exercice reprendra quand tu reviendras (E).", 4.0)
		"runes":
			if _centre_cercle().distance_to(j) > 6.0:
				_jeu_vider()
				_dire("Tu sors du Cercle : les runes s'endorment. Reviens au centre pour recommencer.", 4.0)
				return
			_runes_tick(delta)
		"mannequins":
			var near: bool = false
			for o in jeu["ms"]:
				if (o["a"] as Vector3).distance_to(j) < 6.0:
					near = true
			if not near:
				_jeu_vider()
				_dire("Tu t'éloignes des mannequins : la passe d'armes reprendra quand tu reviendras (E).", 4.0)
				return
			_mannequins_tick(delta)


## Les runes : elles s'éveillent quand on entre dans le Cercle (pendant l'exercice)
func _physics_process(_delta: float) -> void:
	if main == null or not jeu.is_empty():
		return
	var a: Dictionary = actuelle()
	if a.is_empty() or str(a.get("etape", "")) != "pratique" or runes.is_empty():
		return
	var p: Dictionary = lecon(str(a["m"]), int(a["l"]))["pratique"]
	if str(p.get("type", "")) != "runes":
		return
	var j: Vector3 = _joueur()
	var c: Vector3 = _centre_cercle()
	if Vector2(j.x - c.x, j.z - c.z).length() < 2.4 and absf(j.y - c.y) < 2.0:
		_runes_debut(p)


## Une partie chargée : l'exercice en cours reprend du début (il n'est pas enregistré)
func apres_chargement() -> void:
	_jeu_vider()
	var a: Dictionary = actuelle()
	if not a.is_empty():
		a.erase("carte")
		a.erase("essais")
	_decor()
	_sync()

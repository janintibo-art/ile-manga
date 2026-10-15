extends RefCounted
## V44 : le peuple du Village des Fées, sous l'Arbre-Mère. Quatre fées et un lutin bougon,
## chacun avec son caractère, sa maison-champignon et (souvent) une petite quête.
## Même cerveau que les autres habitants ; les répliques communes viennent de
## elfes_habitants_v42.gd (complete()).

const Habitants = preload("res://scripts/pnj/elfes_habitants_v42.gd")

## [fiche, maison (repère du Royaume des Racines)]
const FEES := [
	{
		"maison": Vector3(19.0, 0.0, -71.0),
		"data": {
			"id": "melisse", "nom": "Mélisse", "titre": "fée des nectars, marchande",
			"fee": {"robe": [0.95, 0.75, 0.3], "cheveux": [1.0, 0.85, 0.45], "ailes": [1.0, 0.85, 0.5], "yeux": [0.6, 0.4, 0.15], "fleur": [1.0, 0.5, 0.3]},
			"humeur_base": 0.4, "energie_base": 0.9, "affinite_depart": 10.0,
			"traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.3, "radin": 0.6},
			"aime": {"miel": 3.0, "fleur_lune": 3.0, "goutte_rosee": 1.5, "pain_miel": 2.0, "baies": 1.0},
			"deteste": {"vieille_botte": -1.5, "caillou": -0.5},
			"refuse": ["hache", "epee", "pelle"],
			"boutique": {"vend": {"nectar_fee": 18, "tisane_lune": 6}, "achete": {"eclat_cristal": 6, "miel": 9, "champignon": 3, "baies": 2, "fleur_lune": 30}},
			"repliques": {
				"accueil": [
					{"t": "Un client ! Un GRAND client ! Bienvenue chez Mélisse, nectars et douceurs. Ne marche pas sur mes fleurs, s'il te plaît.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Te revoilà, {surnom} ! J'ai du nectar tout frais, cueilli à l'aube. Enfin, à l'aube des fées : quand la cascade s'allume.", "si": {"visites_min": 2}},
					{"t": "Oh, tu es blessé ! Un nectar, vite. Quatre cœurs d'un coup, c'est mon record.", "si": {"vie_basse": true}},
				],
				"humeur": [
					{"t": "Pétillante ! Les fleurs géantes ont donné double ration de nectar.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Pas terrible. Grommelot m'a encore traitée de « moucheron à paillettes ».", "si": {"humeur_max": 0.2}},
				],
				"lui": [
					{"t": "Je cueille le nectar au cœur des fleurs géantes et je le mets en flacons. Les fées en raffolent. Les humains aussi, il paraît.", "si": {}},
					{"t": "Mes éclats de cristal ? Je les fais fondre au clair de cascade pour faire des flacons. Je t'en rachète, si tu en trouves.", "si": {}},
				],
				"ile": [
					{"t": "Le village est bâti dans les maisons-champignons : on creuse le pied, on ouvre une fenêtre, et voilà. Il pousse avec nous.", "si": {}},
					{"t": "La cascade de lumière descend des racines de l'Arbre-Mère. C'est sa sève. Ne la bois pas : tu brillerais pendant une semaine.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "Brindille cherche encore ses gouttes de rosée. Elle en perd partout, puis elle pleure, et ses larmes font de nouvelles gouttes. C'est sans fin.", "si": {}, "geste": "rire"},
					{"t": "Pimprenelle a perdu sa baguette dans la Grotte des Champignons Sauteurs. Ne lui dis pas que je te l'ai dit.", "si": {"pas_trouve": "baguette"}},
					{"t": "La Reine des Ronces… on n'en parle pas trop fort ici. Ses ronces ont mangé la moitié de notre royaume.", "si": {}},
				],
				"boutique": [{"t": "Nectar de fée, quatre cœurs ! Et je rachète les éclats de cristal. Tu as {pieces} pièces.", "si": {}}],
				"achat_nectar_fee": [{"t": "Un nectar ! Bois-le d'un trait, c'est meilleur. Et ça soigne mieux.", "si": {}, "geste": "rire"}],
				"interpelle": [
					{"t": "Nectar ! Nectar tout frais !", "si": {}},
					{"t": "{surnom} ! Viens par ici !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"maison": Vector3(43.0, 0.0, -71.0),
		"data": {
			"id": "brindille", "nom": "Brindille", "titre": "fée de la rosée",
			"fee": {"robe": [0.55, 0.85, 0.95], "cheveux": [0.75, 0.9, 1.0], "ailes": [0.6, 0.95, 1.0], "yeux": [0.2, 0.55, 0.85], "fleur": [0.8, 0.95, 1.0]},
			"humeur_base": 0.1, "energie_base": 0.6, "affinite_depart": 12.0,
			"traits": {"bavard": 0.6, "humour": 0.3, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.1},
			"aime": {"goutte_rosee": 3.0, "perle": 2.0, "coquillage": 1.5, "fleur_lune": 2.0},
			"deteste": {"buche": -1.0},
			"refuse": ["hache", "epee"],
			"quete": {"objet": "goutte_rosee", "nombre": 5, "recompense": [["poussiere_fee", 2], ["piece", 20]], "affinite": 20.0,
				"sujet": "Tes gouttes de rosée…", "note": "m'a demandé des gouttes de rosée", "souvenir": "Tu m'as rapporté mes cinq gouttes de rosée. Je ne les perdrai plus. Promis. Presque."},
			"repliques": {
				"accueil": [
					{"t": "Oh… bonjour. Je suis Brindille. Je garde la rosée de lune. Enfin… je la gardais. Je l'ai perdue.", "si": {"visites_max": 1}},
					{"t": "{surnom} ! Tu reviens… tu as vu mes gouttes, peut-être ?", "si": {"visites_min": 2, "quete": "demandee"}},
					{"t": "{surnom} ! Regarde comme elles brillent, mes gouttes ! Grâce à toi !", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Un peu triste. Sans ma rosée, les fleurs du village ont soif.", "si": {"pas_trouve": "rosee_rendue"}},
					{"t": "Toute légère ! Les fleurs boivent, les fées chantent.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"lui": [
					{"t": "Chaque matin, je cueille la rosée de lune sur les racines, et j'en arrose les fleurs du village. C'est un petit métier, mais il est important.", "si": {}},
					{"t": "Hier, une araignée de cristal m'a fait peur. J'ai tout lâché ! Mes gouttes ont roulé partout : dans la Salle des Prismes, le jardin, la grotte… Tu m'en rapporterais {manque} ? Elles brillent, tu les verras.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Il m'en manque {manque}. Elles brillent comme de toutes petites lunes, posées par terre.", "si": {"quete": "demandee"}},
					{"t": "Mes fleurs n'ont jamais été aussi belles. Tu es un humain très gentil.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "Le Royaume des Racines était grand, avant. Il y avait des jardins jusqu'à la mer. Maintenant, il y a les ronces.", "si": {}},
				],
				"rumeur": [
					{"t": "Cardamome pose des énigmes à tout le monde. Moi, je ne trouve jamais. Elle dit que ce n'est pas grave. C'est un peu grave.", "si": {}},
					{"t": "Grommelot fait semblant d'être méchant. Il m'a donné une couverture, l'hiver dernier. En grognant.", "si": {}},
				],
				"quete_manque": [{"t": "Encore {manque}… Elles sont peut-être dans des coins où on ne va jamais. Ou tout en haut.", "si": {}}],
				"quete_fin": [{"t": "Mes gouttes ! Toutes ! Tiens, de la poussière de fée, deux pincées. Et vingt pièces. Et… merci. Vraiment.", "si": {}, "geste": "rire", "humeur": 0.4}],
				"interpelle": [
					{"t": "Oh… un humain…", "si": {"visites_max": 0}},
					{"t": "{surnom} !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"maison": Vector3(45.0, 0.0, -86.0),
		"data": {
			"id": "cardamome", "nom": "Cardamome", "titre": "fée des énigmes",
			"fee": {"robe": [0.5, 0.35, 0.75], "cheveux": [0.3, 0.2, 0.45], "ailes": [0.8, 0.6, 1.0], "yeux": [0.7, 0.5, 0.95], "fleur": [0.95, 0.7, 1.0]},
			"humeur_base": 0.3, "energie_base": 0.7, "affinite_depart": 6.0,
			"traits": {"bavard": 0.7, "humour": 0.8, "curiosite": 0.9, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"perle": 2.0, "fleur_lune": 2.0, "eclat_cristal": 1.5, "bague": 2.0},
			"deteste": {"vieille_botte": -1.0},
			"refuse": ["hache", "epee"],
			"sujets_speciaux": [
				{"id": "prix_enigmes", "label": "J'ai répondu à tes trois énigmes !", "si": {"fait": "enigme3", "pas_fait": "prix_enigmes"}},
			],
			"questions": [
				{"id": "enigme1", "si": {"visites_min": 1}, "texte": "Une énigme, humain ! « Plus j'ai de gardiens, moins je suis gardé. » Qui suis-je ?",
					"reponses": [
						{"label": "Un secret.", "valeur": "bon", "affinite": 6.0, "humeur": 0.2, "t": "Un secret ! Bravo. Plus on est nombreux à le garder, plus il s'envole."},
						{"label": "Un trésor.", "valeur": "faux", "affinite": 1.0, "humeur": 0.0, "t": "Raté ! C'était un secret. Mais tu as essayé, c'est bien."},
						{"label": "Une porte.", "valeur": "faux", "affinite": 1.0, "humeur": 0.0, "t": "Une porte ?! Non, non : un secret. Les portes, elles, aiment les gardiens."},
					]},
				{"id": "enigme2", "si": {"fait": "enigme1"}, "texte": "Deuxième énigme ! « Je cours sans jambes, je chante sans bouche, et je dors dans un lit sans jamais m'y coucher. »",
					"reponses": [
						{"label": "Le vent.", "valeur": "faux", "affinite": 1.0, "humeur": 0.0, "t": "Presque ! C'était la rivière. Elle a un lit, tu vois ?"},
						{"label": "La rivière.", "valeur": "bon", "affinite": 6.0, "humeur": 0.2, "t": "La rivière ! Tu es plus malin que tu en as l'air. Ce n'est pas difficile, remarque."},
						{"label": "Grommelot.", "valeur": "faux", "affinite": 2.0, "humeur": 0.3, "t": "Ha ha ha ! Grommelot ne chante JAMAIS. Mais j'aime l'idée. C'était la rivière."},
					]},
				{"id": "enigme3", "si": {"fait": "enigme2"}, "texte": "Dernière énigme ! « Plus on m'enlève, plus je deviens grand. »",
					"reponses": [
						{"label": "Un trou.", "valeur": "bon", "affinite": 8.0, "humeur": 0.3, "t": "UN TROU ! Trois sur trois… ou presque. Demande-moi ton prix, tu l'as mérité."},
						{"label": "Une ombre.", "valeur": "faux", "affinite": 2.0, "humeur": 0.0, "t": "Non ! C'était un trou. Mais je te donnerai quand même un petit quelque chose. Demande."},
						{"label": "Une barbe de lutin.", "valeur": "faux", "affinite": 2.0, "humeur": 0.3, "t": "Ha ! Non, elle repousse. C'était un trou. Demande-moi ton prix, tu m'as fait rire."},
					]},
			],
			"repliques": {
				"prix_enigmes": [
					{"t": "Un humain qui répond aux énigmes d'une fée ! Voilà ton prix : une pincée de poussière de fée. Ne l'éternue pas.", "si": {}, "action": "donne", "donne": [["poussiere_fee", 1]], "pose": "prix_enigmes", "geste": "rire", "humeur": 0.2},
				],
				"accueil": [
					{"t": "Tiens, tiens… Un humain. Je suis Cardamome. J'aime les énigmes, les secrets et les gens qui réfléchissent. Tu réfléchis ?", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom} ! Prêt pour une énigme ?", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Curieuse. Toujours curieuse. C'est mon humeur préférée.", "si": {}},
					{"t": "Pensive. J'ai trouvé une énigme sans réponse. Ou alors la réponse est « Grommelot ».", "si": {}, "geste": "rire"},
				],
				"lui": [
					{"t": "Je garde la mémoire du royaume : les histoires, les chansons, les énigmes. Une énigme, c'est une histoire qui se cache.", "si": {}},
					{"t": "Les clochettes de cristal, c'est moi qui les ai accordées. Il faut écouter avant de jouer. Toujours écouter.", "si": {}},
				],
				"ile": [
					{"t": "Le royaume a trois parties : les racines, le village… et le domaine de la Reine des Ronces, au nord. Personne n'y est allé depuis cent ans.", "si": {}},
					{"t": "Énigme gratuite : « Au fond du royaume, sous les ronces, dort ce qu'on a oublié. » Tu trouveras peut-être, un jour.", "si": {}},
				],
				"rumeur": [
					{"t": "Mélisse vend son nectar trop cher. Mais il est délicieux. Les deux sont vrais : c'est une énigme.", "si": {}, "geste": "rire"},
					{"t": "Lumi t'a guidé jusqu'ici ? C'est la plus jeune d'entre nous. Et la plus brave.", "si": {}},
				],
				"interpelle": [
					{"t": "Humain ! Une énigme ?", "si": {}},
				],
			},
		},
	},
	{
		"maison": Vector3(18.0, 0.0, -89.0),
		"data": {
			"id": "pimprenelle", "nom": "Pimprenelle", "titre": "fée-magicienne (sans baguette)",
			"fee": {"robe": [0.95, 0.5, 0.65], "cheveux": [0.95, 0.55, 0.3], "ailes": [1.0, 0.7, 0.85], "yeux": [0.3, 0.7, 0.4], "fleur": [1.0, 0.95, 0.5]},
			"humeur_base": 0.0, "energie_base": 0.95, "affinite_depart": 10.0,
			"traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"baguette_fee": 4.0, "fleur_lune": 2.0, "perle": 1.5, "nectar_fee": 2.0},
			"deteste": {"champignon": -0.5},
			"refuse": ["hache", "epee"],
			"quete": {"objet": "baguette_fee", "nombre": 1, "recompense": [["poussiere_fee", 2]], "affinite": 25.0,
				"sujet": "Ta baguette…", "note": "m'a demandé de retrouver sa baguette", "souvenir": "Tu m'as rendu ma baguette ! Depuis, je ne la lâche plus. Même pour dormir."},
			"repliques": {
				"accueil": [
					{"t": "Bonjour ! Je suis Pimprenelle, la plus grande magicienne du village ! Enfin… quand j'ai ma baguette.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom} ! Tu as du nouveau ? Ma baguette me manque terriblement.", "si": {"visites_min": 2, "quete": "demandee"}},
					{"t": "Regarde ! Pif ! Paf ! Des étincelles ! Ma baguette marche à merveille !", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Sans ma baguette, je me sens toute… normale. C'est horrible.", "si": {"quete": "demandee"}},
					{"t": "Magique ! Littéralement.", "si": {"quete": "finie"}, "geste": "rire"},
					{"t": "Agitée. Je n'arrive pas à rester sur place. Tu vois ? Là, je bouge.", "si": {}},
				],
				"lui": [
					{"t": "Je fais pousser les fleurs d'un coup de baguette, j'allume les maisons, je change Grommelot en grenouille quand il est trop grognon. Enfin, je le faisais.", "si": {}, "geste": "rire"},
					{"t": "Ma baguette ! Je l'ai perdue dans la Grotte des Champignons Sauteurs, à l'ouest du jardin. Elle est restée TOUT EN HAUT, sur la corniche. Saute sur les champignons, ils te propulseront. Tu me la rapportes ?", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Tout en haut de la grotte ! Les gros champignons rebondissent : monte dessus, et hop !", "si": {"quete": "demandee"}},
					{"t": "Grâce à toi, j'ai changé Grommelot en grenouille ce matin. Cinq minutes. Il a adoré. Il dit que non.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Tu connais les champignons sauteurs ? On les a fait pousser pour jouer. Puis les araignées de cristal sont arrivées, et on ne joue plus.", "si": {}},
				],
				"rumeur": [
					{"t": "Grommelot collectionne les éclats de cristal. Il dit que c'est pour sa cheminée. Je crois qu'il les trouve jolis.", "si": {}},
					{"t": "Mélisse met trop de sucre dans son nectar. Ne lui répète pas, elle me jetterait des pétales.", "si": {}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Pas encore ma baguette ? Tout en haut de la grotte, sur la corniche, à l'ouest !", "si": {}}],
				"quete_fin": [{"t": "MA BAGUETTE ! Pif ! Paf ! Ça marche ! Tiens, deux pincées de poussière de fée. Tu es le meilleur humain du monde. Le seul que je connaisse, mais le meilleur !", "si": {}, "geste": "rire", "humeur": 0.6}],
				"interpelle": [
					{"t": "Hé ! Hé, toi ! Tu n'aurais pas vu une baguette ?", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Pif !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"maison": Vector3(40.5, 0.0, -93.5),
		"data": {
			"id": "grommelot", "nom": "Grommelot", "titre": "lutin bougon, gardien des racines", "lutin": true,
			"fee": {"robe": [0.35, 0.45, 0.25], "cheveux": [0.7, 0.2, 0.18]},
			"humeur_base": -0.2, "energie_base": 0.5, "affinite_depart": 0.0,
			"traits": {"bavard": 0.3, "humour": 0.4, "curiosite": 0.2, "susceptible": 0.8, "rancunier": 0.7},
			"aime": {"eclat_cristal": 2.5, "buche": 1.5, "champignon": 1.0, "piece_or": 1.5},
			"deteste": {"fleur_lune": -0.5, "nectar_fee": -0.5},
			"refuse": [],
			"quete": {"objet": "eclat_cristal", "nombre": 4, "recompense": [["poussiere_fee", 1], ["piece", 30]], "affinite": 20.0,
				"sujet": "Tes éclats de cristal…", "note": "m'a demandé des éclats de cristal", "souvenir": "Tu m'as rapporté des éclats de cristal. Ma cheminée n'a jamais été aussi jolie. … Je veux dire : aussi chaude."},
			"repliques": {
				"accueil": [
					{"t": "Hmpf. Un humain. Trop grand, trop bruyant, trop… humain. Grommelot, gardien des racines. Qu'est-ce que tu veux ?", "si": {"visites_max": 1}},
					{"t": "Encore toi. Hmpf.", "si": {"visites_min": 2, "affinite_max": 30}},
					{"t": "Ah. C'est toi. … Bonjour. Ne t'y habitue pas.", "si": {"visites_min": 2, "affinite_min": 30}},
				],
				"humeur": [
					{"t": "Mauvaise. Comme d'habitude. Merci de demander. Hmpf.", "si": {}},
					{"t": "Pimprenelle m'a encore changé en grenouille. J'ai mal aux pattes. Aux jambes. Hmpf.", "si": {"a_trouve": "baguette_rendue"}},
				],
				"lui": [
					{"t": "Je garde les racines depuis quatre cents ans. Avant les fées, avant les elfes. Personne ne dit merci aux racines. Personne.", "si": {}},
					{"t": "Les araignées de cristal ont envahi la grotte de l'ouest. Elles laissent des éclats quand on les casse. Rapporte-m'en {manque}. Pour ma cheminée. Pas parce qu'ils sont jolis. Hmpf.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} éclats. J'attends. J'ai l'habitude d'attendre.", "si": {"quete": "demandee"}},
					{"t": "Ma cheminée brille comme une étoile. Hmpf. … Merci.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "Au nord, les ronces. Elles avancent d'un pas chaque année. Un jour, elles mangeront le village. Personne ne m'écoute.", "si": {}},
					{"t": "Les feux follets ? Des farceurs. Ils te foncent dessus pour rire. Leur rire fait mal.", "si": {}},
				],
				"rumeur": [
					{"t": "Les fées ? Des moucherons à paillettes. Toutes. … Brindille est gentille. Ne le répète pas.", "si": {}},
					{"t": "Tu as vaincu un grand serpent, là-haut ? Hmpf. Les serpents, c'est facile. Essaie donc les ronces.", "si": {"a_trouve": "naga"}},
				],
				"quete_manque": [{"t": "Il en manque {manque}. Les araignées de la grotte de l'ouest. Va.", "si": {}}],
				"quete_fin": [{"t": "Des éclats… de beaux éclats. Hmpf. Tiens : trente pièces et une pincée de poussière. Et ne souris pas comme ça.", "si": {}, "geste": "salut", "humeur": 0.5}],
				"frappe": [{"t": "AÏE ! Espèce de grand échalas ! Hmpf !", "si": {}, "geste": "colere", "humeur": -0.5}],
				"interpelle": [
					{"t": "Hmpf.", "si": {}},
					{"t": "Ne marche pas sur mes racines.", "si": {}},
				],
			},
		},
	},
]


static func fiche(i: int) -> Dictionary:
	var d: Dictionary = Habitants.complete(FEES[i]["data"])
	d["surnoms"] = [[0, "humain"], [25, "grand ami"], [50, "ami des fées"], [75, "chevalier des racines"], [95, "fée d'honneur"]]
	d["tics"] = ["Par les racines !", "Pétales et rosée…", "Que la sève te garde.", "Tiens, une étincelle."]
	if bool(d.get("lutin", false)):
		d["tics"] = ["Hmpf.", "Hmpf hmpf.", "Bah."]
	return d

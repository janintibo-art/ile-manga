extends RefCounted
## V31 : fiche de personnalité de Barnabé Coquillard, ermite de la plage de la jungle.
## Ancien cartographe naufragé, il collectionne les coquillages et parle à Gaston, son perroquet.
## Ce fichier ne contient que des données : le « cerveau » commun à tous les personnages
## (pnj_brain_v31.gd) choisit les répliques selon l'humeur, l'amitié et la mémoire.
##
## Conditions possibles dans "si" :
##   humeur_min / humeur_max (-1..1), energie_min / energie_max (0..1),
##   affinite_min / affinite_max (0..100), visites_min / visites_max,
##   absent_min / absent_max (secondes de jeu depuis la dernière visite),
##   fait / pas_fait ("clé" ou "clé=valeur"), objet (le joueur le porte), arme (true/false),
##   vie_basse (true/false), quete ("", "demandee", "finie"), sujet_min ([sujet, nombre]).
## Variables dans les textes : {surnom} {visites} {absence} {arme} {objet_joueur}
##   {dernier_cadeau} {nb_cadeaux} {coquillages} {manque} {humeur_mot} {sujet_prefere}

const DATA := {
	"id": "barnabe",
	"nom": "Barnabé Coquillard",
	"titre": "ermite de la plage",
	"humeur_base": 0.35,
	"energie_base": 0.65,
	"affinite_depart": 15.0,
	# Traits : 0..1 ; ils règlent la fréquence des tics, des blagues, des digressions.
	"traits": {"bavard": 0.85, "humour": 0.75, "curiosite": 0.8, "susceptible": 0.45, "rancunier": 0.35},
	"surnoms": [[0, "étranger"], [25, "moussaillon"], [50, "matelot"], [75, "vieux frère"], [95, "capitaine"]],
	"aime": {"coquillage": 3.0, "baies": 1.5, "pomme": 1.0, "champignon": 0.5, "piece": 0.8},
	"deteste": {"caillou": -1.0, "baton": -0.4},
	"refuse": ["epee_bois"],
	"quete": {"objet": "coquillage", "nombre": 5, "recompense": [["boussole", 1], ["piece", 15]], "affinite": 20.0},
	"compagnon": "Gaston",

	# Petits mots ajoutés devant ou derrière une réplique, selon l'humeur.
	"prefixes": {
		"joie": ["Ha ha !", "Oh, magnifique !", "Sapristi, quelle journée !", "Hé hé hé…"],
		"neutre": ["Hmm.", "Voyons voir…", "Ah.", "Bon, bon."],
		"triste": ["Pfff…", "Hmmmf.", "Ah, c'est toi…", "Mouais."],
		"colere": ["Grrr.", "Quoi encore ?", "Mille sabords…", "Tss."],
	},
	"tics": ["Par la barbe de Neptune !", "Gaston, note ça !", "Comme disait ma grand-mère : jamais de chaussettes sur le sable.",
		"Je l'ai écrit quelque part… sur un coquillage, je crois.", "Sapristi !", "Où en étais-je ? Ah oui.",
		"Le vent tourne, moussaillon. Le vent tourne toujours."],
	"compagnon_lignes": ["Gaston : « RRAAAH ! Naufrage ! Naufrage ! »", "Gaston : « Coco veut une pièce ! »",
		"Gaston : « Barnabé est un génie ! Un génie ! »", "Gaston : « Coquillaaaage ! »",
		"Gaston : « Bonjourrr ! Bonjourrr ! »", "Gaston (en se lissant les plumes) : « Pfff. »"],
	"humeur_mots": [[0.6, "rayonnant"], [0.25, "de bonne humeur"], [-0.25, "pensif"], [-0.6, "bougon"], [-2.0, "furieux"]],

	"repliques": {
		# ------------------------------------------------------------ accueil
		"accueil": [
			{"t": "Oh ! Un visiteur ! Un vrai, avec des jambes et tout ! Bienvenue dans mon humble cabane, {surnom}. Je suis Barnabé Coquillard, cartographe, naufragé et collectionneur.", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.2},
			{"t": "Tiens, te revoilà, {surnom} ! Ça fait {absence}. Gaston croyait que les crabes t'avaient mangé.", "si": {"visites_min": 2, "absent_min": 900}, "geste": "salut"},
			{"t": "Déjà de retour ? Tu ne peux plus te passer de ma conversation, avoue.", "si": {"visites_min": 2, "absent_max": 180}, "geste": "rire"},
			{"t": "Ahoy, {surnom} ! La marée est bonne aujourd'hui, et toi aussi on dirait.", "si": {"visites_min": 2, "humeur_min": 0.2}},
			{"t": "Ah. C'est toi. Je comptais mes coquillages. J'en étais à… zut, j'ai perdu le fil.", "si": {"visites_min": 2, "humeur_max": 0.1}},
			{"t": "Mon vieil ami ! Assieds-toi, enfin… il n'y a pas de chaise. Assieds-toi debout.", "si": {"visites_min": 3, "affinite_min": 55}, "geste": "rire"},
			{"t": "Tu reviens après ce que tu m'as fait ? Je n'ai pas oublié, moi. Ni Gaston.", "si": {"fait": "frappe", "humeur_max": 0.0}, "geste": "colere"},
			{"t": "Ohé ! Tu as une épée maintenant ? Fais attention où tu la pointes, j'ai des voiles à repriser.", "si": {"arme": true, "visites_min": 2}},
			{"t": "Tu as une mine affreuse, {surnom}. Tu t'es battu avec un piton ? Mange quelque chose, voyons.", "si": {"vie_basse": true}},
			{"t": "Bonjour bonjour ! Gaston et moi discutions justement de toi. Enfin, surtout Gaston.", "si": {"visites_min": 2}},
			{"t": "Ah, l'aventurier en personne ! Alors, le vaste monde ?", "si": {"fait": "origine=aventurier", "visites_min": 2}},
			{"t": "Le voisin du village ! Dis-moi, ils mangent toujours leurs soupes froides là-bas ?", "si": {"fait": "origine=village", "visites_min": 2}},
		],
		# ------------------------------------------------------------ comment ça va
		"humeur": [
			{"t": "Moi ? Comme un coquillage à marée haute : plein d'eau et ravi de l'être !", "si": {"humeur_min": 0.4}, "geste": "rire"},
			{"t": "Très bien ! J'ai trouvé ce matin un caillou qui ressemble exactement à ma tante Ursule. Sauf le chapeau.", "si": {"humeur_min": 0.2}},
			{"t": "Pas mal, pas mal. Un peu de vague à l'âme. Mais l'âme, c'est fait pour les vagues, non ?", "si": {"humeur_min": -0.2, "humeur_max": 0.4}},
			{"t": "Bof. Gaston boude, la mer est grise dans ma tête, et j'ai perdu ma cuillère préférée.", "si": {"humeur_max": 0.0}},
			{"t": "Mal. Très mal. Mais tu n'y es pour rien… enfin, presque rien.", "si": {"humeur_max": -0.4}, "geste": "colere"},
			{"t": "Je suis fatigué. J'ai cartographié trois fois la même dune cette nuit. Elle bougeait.", "si": {"energie_max": 0.35}},
			{"t": "Survolté ! J'ai bu le jus de quatre noix de coco. Je vois les sons. Ils sont verts.", "si": {"energie_min": 0.85}, "geste": "rire"},
			{"t": "Depuis que tu passes me voir, ça va nettement mieux. Ne le répète pas à Gaston, il est jaloux.", "si": {"affinite_min": 50}},
		],
		# ------------------------------------------------------------ qui es-tu
		"lui": [
			{"t": "Je suis arrivé ici il y a vingt-deux ans, sur un radeau fait de cartes marines roulées. Excellente flottaison, très mauvaise lecture.", "si": {"sujet_min": ["lui", 0]}},
			{"t": "Avant, j'étais cartographe du roi. J'ai dessiné la carte de ce royaume tellement précise qu'elle était aussi grande que le royaume. On ne l'a jamais dépliée.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Gaston m'a trouvé, pas l'inverse. Il est descendu d'un arbre et m'a dit « Naufrage ». C'est le premier qui m'ait parlé ici.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Je collectionne les coquillages. Chacun a une histoire. Celui-ci, par exemple, a vu une baleine éternuer.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Ma collection a un trou, {surnom}. Un trou béant ! Il me manque {manque} coquillages nacrés. Il y en a sur la plage de ton village. Tu m'en rapporterais ?", "si": {"quete": "", "sujet_min": ["lui", 2]}, "action": "quete_demande", "geste": "parle"},
			{"t": "Mes coquillages nacrés, tu y penses ? Il m'en faut {manque}. Ma collection en tremble d'impatience.", "si": {"quete": "demandee"}},
			{"t": "Tu veux vraiment savoir ? J'avais une fiancée, Mireille. Elle est partie avec un phare. Je ne veux pas en parler.", "si": {"affinite_min": 45, "sujet_min": ["lui", 3]}, "humeur": -0.1},
			{"t": "Grâce à toi, ma collection est complète. Enfin, jusqu'à ce que j'en trouve une plus grande à compléter.", "si": {"quete": "finie"}, "geste": "rire"},
		],
		# ------------------------------------------------------------ l'île
		"ile": [
			{"t": "Cette île ? Une jungle, {surnom}. De la vraie. Les grands arbres pâles, là, ce sont des fromagers. Ils sont plus vieux que mes chaussettes.", "si": {}},
			{"t": "Tu vois les pitons de pierre ? Ce sont les doigts d'un géant endormi. Ne le chatouille pas.", "si": {}},
			{"t": "Si tu grimpes les pitons, repose-toi sur les corniches. Même les chèvres font des pauses, et elles n'ont pas de bras.", "si": {}},
			{"t": "La gorge, au milieu, va jusqu'au grand massif du nord. Un jour, une rivière y coulera, j'en suis sûr. Je l'entends rêver.", "si": {}},
			{"t": "Les lianes, ne t'y pends pas trop. Celle de droite m'a fait tomber trois fois. On ne se parle plus.", "si": {}},
			{"t": "Les bananiers sont mes amis. Ils ne disent rien, mais ils écoutent très bien.", "si": {"affinite_min": 20}},
			{"t": "Au sommet du massif, il y a un endroit d'où l'on voit tes deux îles en même temps. Je l'ai cartographié. Sur un coquillage, évidemment.", "si": {"affinite_min": 35}},
		],
		# ------------------------------------------------------------ rumeurs et secrets
		"rumeur": [
			{"t": "Des rumeurs ? Je ne parle pas aux inconnus de choses importantes. Reviens quand on sera amis.", "si": {"affinite_max": 29}},
			{"t": "On dit que l'île flottante au-dessus de ton village a été posée là par un enfant géant qui jouait aux dés.", "si": {"affinite_min": 30}},
			{"t": "Il paraît qu'il y a des ruines sous les racines des grands fromagers. Des escaliers qui ne mènent nulle part. Ou alors très loin.", "si": {"affinite_min": 30}},
			{"t": "Entre nous… j'ai vu des lumières au sommet du plus grand piton, une nuit. Gaston dit que c'était la lune. Gaston dit beaucoup de choses.", "si": {"affinite_min": 40}},
			{"t": "Un secret de cartographe : les jarres de ton village se reforment toutes seules. Personne ne sait pourquoi. Moi non plus. Mais je fais semblant.", "si": {"affinite_min": 50}},
			{"t": "La boussole que je t'ai donnée ne montre pas le nord. Elle montre ce que tu cherches vraiment. En général, c'est le nord.", "si": {"quete": "finie"}},
		],
		# ------------------------------------------------------------ blagues
		"blague": [
			{"t": "Pourquoi les poissons détestent l'ordinateur ? Parce qu'ils ont peur du net ! Ha ! Gaston ne rit jamais à celle-là.", "si": {}, "geste": "rire"},
			{"t": "Qu'est-ce qu'un crabe qui fait du vélo ? Un crabe qui va de travers, mais plus vite.", "si": {}, "geste": "rire"},
			{"t": "J'ai voulu écrire un livre sur les coquillages. Mais je n'arrivais pas à sortir de ma coquille.", "si": {}, "geste": "rire"},
			{"t": "Un naufragé ne se perd jamais : il est déjà perdu. C'est très reposant.", "si": {}},
			{"t": "Je ne suis pas d'humeur à plaisanter. Mais je vais en faire une quand même : toi. Hmpf.", "si": {"humeur_max": -0.3}, "geste": "colere"},
		],
		# ------------------------------------------------------------ cadeaux
		"cadeau_aime": [
			{"t": "Oh ! {dernier_cadeau}, pour moi ? Tu es un trésor, {surnom}. Gaston, regarde !", "geste": "rire"},
			{"t": "Oh… oh oh oh. C'est exactement ce qu'il me fallait. Comment savais-tu ?", "geste": "rire"},
			{"t": "Encore {dernier_cadeau} ? Tu me gâtes ! Ça fait {nb_cadeaux} cadeaux, je les compte, tu sais.", "si": {"visites_min": 2}},
		],
		"cadeau_neutre": [
			{"t": "Tiens, {dernier_cadeau}. Hmm. Merci, je suppose. Je trouverai bien à quoi ça sert.", "si": {}},
			{"t": "C'est… gentil. Je vais le poser là, à côté de l'autre truc que je ne sais pas utiliser.", "si": {}},
		],
		"cadeau_deteste": [
			{"t": "Sérieusement ? {dernier_cadeau} ? Tu te moques de moi, {surnom} ?", "geste": "colere"},
			{"t": "Gaston, on m'offre {dernier_cadeau}. Oui. Ne ris pas.", "si": {}},
		],
		"cadeau_refus": [
			{"t": "Garde ça, {surnom}. Tu en auras plus besoin que moi. Moi, je me bats avec des métaphores.", "si": {}},
		],
		"quete_fin": [
			{"t": "Cinq coquillages nacrés ! Ma collection est complète ! Tiens, prends ma vieille boussole, et quelques pièces. Tu les as bien méritées, {surnom} !", "geste": "rire", "humeur": 0.5},
		],
		"quete_manque": [
			{"t": "Tu n'en as que {coquillages}. Il m'en faut {manque} en tout. Cherche sur la plage de ton village, ils brillent au soleil.", "si": {}},
		],
		# ------------------------------------------------------------ souvenirs (complétés par le cerveau)
		"souvenir": [
			{"t": "Si je me souviens de toi ? Mais bien sûr ! Ma mémoire est un coquillage : tout résonne dedans.", "si": {}},
			{"t": "Évidemment. Je n'ai pas tant de visiteurs. En fait, je n'en ai qu'un. Toi.", "si": {}},
		],
		# ------------------------------------------------------------ au revoir
		"au_revoir": [
			{"t": "Bon vent, {surnom} ! Et méfie-toi des lianes de droite.", "si": {"humeur_min": 0.0}, "geste": "salut"},
			{"t": "Déjà ? Bon. Gaston va encore bouder. Reviens vite.", "si": {"affinite_min": 40}},
			{"t": "C'est ça, file. Les coquillages, eux, ne partent jamais.", "si": {"humeur_max": 0.0}},
			{"t": "À la prochaine marée ! Ou celle d'après. Je ne suis pas pressé, j'ai vingt-deux ans d'avance.", "si": {}},
		],
		# ------------------------------------------------------------ interpellations à distance
		"interpelle": [
			{"t": "Ohé, là-bas ! Un visiteur !", "si": {"visites_max": 0}},
			{"t": "Hé ! {surnom} ! Viens par ici !", "si": {"visites_min": 1, "humeur_min": 0.0}},
			{"t": "Tiens, revoilà {surnom}…", "si": {"visites_min": 1, "humeur_max": 0.0}},
			{"t": "Gaston, cache les coquillages, il revient !", "si": {"visites_min": 2}},
			{"t": "Ahoy !", "si": {}},
		],
		"frappe": [
			{"t": "AÏE ! Mais ça va pas ?!", "geste": "colere"},
			{"t": "Gaston, tu as vu ? Il m'a frappé ! Note-le !", "geste": "colere"},
			{"t": "Encore ?! Je m'en souviendrai, crois-moi.", "si": {"fait": "frappe"}, "geste": "colere"},
		],
	},

	# Questions qu'il pose une fois chacune ; la réponse est retenue et colore la suite.
	"questions": [
		{"id": "origine", "si": {"visites_max": 1}, "texte": "Dis-moi, d'où viens-tu, comme ça ?",
			"reponses": [
				{"label": "Du village, sur l'île d'en face.", "valeur": "village", "affinite": 3.0, "humeur": 0.05, "t": "Le village ! Je vois parfois vos lanternes la nuit. Ça me fait de la compagnie."},
				{"label": "Je suis un aventurier, je viens de partout.", "valeur": "aventurier", "affinite": 5.0, "humeur": 0.15, "t": "Un aventurier ! Comme moi à ton âge. Sauf que moi, je suis resté coincé ici. Ne fais pas pareil."},
				{"label": "Ça ne te regarde pas.", "valeur": "secret", "affinite": -4.0, "humeur": -0.15, "t": "Oh. Pardon, monsieur le mystérieux. Gaston, on a un mystérieux."},
			]},
		{"id": "coquillage_prefere", "si": {"visites_min": 2, "affinite_min": 20}, "texte": "Question importante : tu préfères les coquillages ronds ou pointus ?",
			"reponses": [
				{"label": "Ronds, évidemment.", "valeur": "ronds", "affinite": 4.0, "humeur": 0.2, "t": "Évidemment ! Enfin quelqu'un de sensé sur cette île."},
				{"label": "Pointus.", "valeur": "pointus", "affinite": 1.0, "humeur": -0.05, "t": "Pointus… Bon. Chacun ses défauts. Je ne te juge pas. Un peu quand même."},
				{"label": "Je m'en fiche complètement.", "valeur": "aucun", "affinite": -3.0, "humeur": -0.2, "t": "Tu… tu t'en fiches ? Gaston, bouche-toi les oreilles."},
			]},
		{"id": "gaston", "si": {"visites_min": 3, "affinite_min": 30}, "texte": "Gaston veut savoir : tu le trouves beau ?",
			"reponses": [
				{"label": "Magnifique, le plus beau perroquet du monde.", "valeur": "beau", "affinite": 5.0, "humeur": 0.25, "t": "Gaston : « Rrrah ! Il a bon goût ! » Il t'adore maintenant. C'est rare."},
				{"label": "Il a l'air un peu déplumé.", "valeur": "deplume", "affinite": -2.0, "humeur": -0.1, "t": "Gaston : « RRRAAAH ! » Il ne te parlera plus pendant une semaine. Moi non plus, peut-être."},
			]},
	],
}

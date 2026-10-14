extends RefCounted
## V41 : fiche de personnalité de Lyra Sylvanel, elfe du Bois-Doré.
## Lyra a quitté l'île des elfes, cachée dans la brume à l'est, pour veiller sur l'Arbre
## sacré qui pousse au cœur de l'île du village : un rejeton de l'Arbre-Mère des elfes. Il
## se meurt. Pour le soigner, il lui faut trois choses : une fleur de lune (au sommet d'un
## piton de la jungle), de l'eau de la source (le bassin de la grande chute, sur l'île du
## village) et une graine d'or (que Barnabé a ramassée sur une plage, il y a longtemps).
## En échange, elle confie sa boussole elfique : la seule qui traverse la brume du Bois-Doré.
## Douce, curieuse des humains, un peu poétique, très patiente, rit facilement.
## Même cerveau que Barnabé et Octave (pnj_brain_v31.gd) ; quête à plusieurs objets.

const DATA := {
	"id": "lyra",
	"nom": "Lyra Sylvanel",
	"titre": "elfe du Bois-Doré",
	"elfe": {"texture": "res://assets/textures/elfes/elfe_lyra.png", "cheveux": [0.96, 0.9, 0.72], "robe": [0.16, 0.42, 0.32], "cape": [0.86, 0.9, 0.82], "bijou": [0.85, 0.88, 0.9]},
	"teinte": [1.0, 0.92, 0.86],
	"humeur_base": 0.3,
	"energie_base": 0.7,
	"affinite_depart": 10.0,
	"traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2},
	"surnoms": [[0, "voyageur"], [25, "ami des arbres"], [50, "ami de Lyra"], [75, "frère du Bois"], [95, "gardien du Bois-Doré"]],
	"aime": {"fleur_lune": 3.0, "miel": 2.0, "baies": 2.0, "pomme": 1.5, "perle": 1.5, "coquillage": 1.0, "champignon": 1.0, "ecaille_naga": 2.5},
	"deteste": {"buche": -1.5, "hache": -2.0, "vieille_botte": -0.5},
	"refuse": ["hache", "epee", "pelle"],
	"quete": {"objets": {"fleur_lune": 1, "eau_source": 1, "graine_or": 1}, "recompense": [["boussole_elfique", 1]], "affinite": 25.0,
		"sujet": "À propos de l'Arbre sacré…", "note": "m'a demandé de soigner l'Arbre sacré", "note_fin": "a soigné l'Arbre sacré",
		"souvenir": "Et tu as rendu la vie à l'Arbre sacré. Le Bois-Doré ne l'oubliera jamais."},
	"compagnon": "",

	"sujets_speciaux": [
		{"id": "remede", "label": "Que faut-il pour soigner l'arbre ?", "si": {"quete": "demandee"}},
		{"id": "chez_elle", "label": "Comment rejoindre ton île ?", "si": {"quete": "finie"}},
	],

	"prefixes": {
		"joie": ["Oh !", "Quelle joie…", "Ha ha !", "Merveilleux."],
		"neutre": ["Hmm…", "Écoute…", "Vois-tu,", "Oui…"],
		"triste": ["Hélas…", "Ah…", "Pardonne-moi…", "Mmh."],
		"colere": ["Tss.", "Assez.", "Recule.", "Non."],
	},
	"tics": ["Les arbres entendent tout, tu sais.", "Par la lumière de l'Arbre-Mère…", "Écoute le vent : il chante.",
		"Les humains marchent si vite…", "Chez nous, on dirait : « que tes racines soient profondes ».", "Pardon, je rêvais."],
	"compagnon_lignes": [],
	"humeur_mots": [[0.6, "radieuse"], [0.25, "sereine"], [-0.25, "inquiète"], [-0.6, "attristée"], [-2.0, "glaciale"]],

	"repliques": {
		# ------------------------------------------------------------ accueil
		"accueil": [
			{"t": "Oh… Un humain, ici, au cœur des arbres. N'aie pas peur : je m'appelle Lyra Sylvanel, et je viens du Bois-Doré, l'île des elfes, de l'autre côté de la brume.", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.15},
			{"t": "Te revoilà, {surnom}. Les feuilles t'ont annoncé avant tes pas.", "si": {"visites_min": 2}},
			{"t": "Tu reviens après une longue absence… {absence}, je crois. Pour une elfe, c'est un battement de paupières.", "si": {"visites_min": 2, "absent_min": 900}},
			{"t": "Tu portes une hache. S'il te plaît… pas ici. Pas près de l'Arbre.", "si": {"tient": "hache"}, "geste": "colere", "humeur": -0.1},
			{"t": "L'Arbre sacré respire à nouveau. Chaque fois que je le regarde, je pense à toi.", "si": {"quete": "finie"}, "humeur": 0.1},
			{"t": "Tu as l'air épuisé, {surnom}. Assieds-toi sous les feuilles. Ici, rien ne peut t'atteindre.", "si": {"vie_basse": true}},
			{"t": "Tu viens de chez Barnabé ? Il me fait rire. Il m'a demandé si les elfes mangeaient des coquillages.", "si": {"a_rencontre": "barnabe", "visites_min": 2}, "geste": "rire"},
		],
		# ------------------------------------------------------------ comment ça va
		"humeur": [
			{"t": "Je vais bien… mais l'Arbre, lui, va mal. Ses feuilles ont la couleur de l'automne alors qu'il n'y a pas d'automne ici.", "si": {"quete": ""}},
			{"t": "Inquiète. Chaque jour, une branche de plus devient grise. Mais tu m'aides : je reprends espoir.", "si": {"quete": "demandee"}},
			{"t": "Légère comme une graine au vent ! L'Arbre chante de nouveau. Tu l'entends ?", "si": {"quete": "finie"}, "geste": "rire"},
			{"t": "Bien. J'ai dormi dans les branches, et un oiseau m'a réveillée en chantant faux. C'était charmant.", "si": {"humeur_min": 0.2}, "geste": "rire"},
			{"t": "Fatiguée. Garder un arbre, c'est garder un rêve : il ne faut jamais fermer tout à fait les yeux.", "si": {"energie_max": 0.4}},
		],
		# ------------------------------------------------------------ qui es-tu
		"lui": [
			{"t": "Je suis une gardienne. Cet arbre, là, est un rejeton de l'Arbre-Mère du Bois-Doré : une graine portée par le vent il y a mille ans. Il se meurt, {surnom}. Veux-tu m'aider à le soigner ? Il me faut trois choses : une fleur de lune, de l'eau de la source et une graine d'or. Tiens, prends cette fiole de cristal : pour l'eau.", "si": {"quete": ""}, "action": "quete_demande", "donne": [["fiole_vide", 1]], "geste": "parle"},
			{"t": "Moi ? J'ai trois cent douze ans. C'est jeune, chez nous. Ma mère dit que je suis « encore toute verte ».", "si": {"quete": "demandee", "sujet_min": ["lui", 1]}, "geste": "rire"},
			{"t": "Les elfes ne quittent presque jamais le Bois-Doré. La brume nous protège… et nous enferme un peu, aussi. Je suis la première depuis longtemps à parler à un humain.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Au Bois-Doré, nos maisons sont posées dans les branches d'arbres si grands que leurs cimes touchent les nuages. Tu verras. Je te le promets.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Merci encore, {surnom}. Grâce à toi, je peux rentrer chez moi. Et toi, tu peux venir : la boussole connaît le chemin.", "si": {"quete": "finie"}, "humeur": 0.05},
		],
		# ------------------------------------------------------------ remède (pendant la quête)
		"remede": [
			{"t": "Il me manque encore {manque_liste}. La fleur de lune ne pousse qu'au sommet du petit piton de la jungle, celui qui regarde la baie. L'eau, puise-la avec la fiole dans le bassin de la grande chute, au nord-est de cette île. Et la graine d'or… les vagues l'ont emportée il y a longtemps. Un collectionneur l'a peut-être ramassée ?", "si": {}},
			{"t": "Il me faut encore {manque_liste}. Courage : l'Arbre t'attend. Il ne se plaint jamais, mais moi je l'entends soupirer.", "si": {}},
		],
		# ------------------------------------------------------------ comment rejoindre son île
		"chez_elle": [
			{"t": "Prends ton bateau et suis la boussole : son aiguille de cristal pointe toujours vers l'Arbre-Mère, à l'est, entre ton village et la jungle. La brume s'ouvrira devant toi. Je t'attendrai sur la place du village, au pied des grands arbres.", "si": {}},
		],
		# ------------------------------------------------------------ l'île
		"ile": [
			{"t": "Ton île est jolie. Bruyante, mais jolie. Les arbres d'ici sont jeunes : ils ne parlent pas encore beaucoup.", "si": {}},
			{"t": "Il y a deux chutes d'eau ici. L'eau de la plus grande, au nord-est, vient de très loin sous la terre. Elle a le goût des étoiles.", "si": {}},
			{"t": "Ces pierres levées, au nord du village… Ce ne sont pas les elfes qui les ont posées. Quelqu'un de plus ancien encore.", "si": {}},
			{"t": "Si tu coupes un arbre, plantes-en un autre. C'est tout ce que nous demandons, nous autres.", "si": {"arbres_min": 3}},
		],
		# ------------------------------------------------------------ rumeurs
		"rumeur": [
			{"t": "On raconte au Bois-Doré qu'un grand serpent dormait sous vos îles. Je n'y croyais pas.", "si": {"pas_trouve": "naga"}},
			{"t": "Tu as vaincu le Serpent des Abysses ?! Les anciens de mon peuple en parleront pendant cent ans. Enfin… cent ans, ce n'est pas si long.", "si": {"a_trouve": "naga"}, "geste": "rire", "humeur": 0.1},
			{"t": "Octave, le forgeron dans l'arbre… Il gronde comme un orage, mais il caresse l'écorce de son fromager quand il croit que personne ne le voit.", "si": {"a_rencontre": "octave"}},
			{"t": "Barnabé dit que sa carte des Anciens montre « un œil doré à l'est ». C'est l'Arbre-Mère. Il a de bons yeux, pour un humain.", "si": {"a_rencontre": "barnabe"}},
		],
		"blague": [
			{"t": "Pourquoi les elfes ne jouent-ils jamais à cache-cache avec les arbres ? … Parce que les arbres trichent : ils ne bougent jamais.", "si": {}, "geste": "rire"},
			{"t": "Un humain m'a demandé mon âge. J'ai répondu « trois cent douze ». Il a dit « bien conservée ». Je ne sais toujours pas si c'était gentil.", "si": {}, "geste": "rire"},
		],
		# ------------------------------------------------------------ cadeaux
		"cadeau_aime": [
			{"t": "Pour moi ? Oh… {dernier_cadeau}. C'est délicat. Merci, {surnom}.", "si": {}, "geste": "rire"},
			{"t": "Tu as un cœur d'elfe, {surnom}. Je garderai {dernier_cadeau} près de moi.", "si": {}},
		],
		"cadeau_neutre": [
			{"t": "Merci. Je vais lui trouver une place dans mes affaires.", "si": {}},
			{"t": "Un cadeau des humains… Je le montrerai aux miens. Ils seront curieux.", "si": {}},
		],
		"cadeau_deteste": [
			{"t": "Du bois coupé… Tu sais, chez nous, c'est un peu comme offrir… un bras. Non. Merci.", "si": {}, "geste": "colere"},
			{"t": "Je… préfère que tu le gardes.", "si": {}},
		],
		"cadeau_refus": [
			{"t": "Une arme ? Non. Je n'en ai pas besoin, et l'Arbre n'aime pas le fer.", "si": {}},
		],
		# ------------------------------------------------------------ quête
		"quete_manque": [
			{"t": "Il manque encore {manque_liste}. Ne te presse pas : l'Arbre est patient, même malade.", "si": {}},
		],
		"quete_fin": [
			{"t": "La fleur de lune… l'eau de la source… la graine d'or ! Viens, {surnom}, regarde. Je pose la graine au pied de l'Arbre, la fleur dans ses racines, et l'eau… voilà.\n\nTu sens ? La sève remonte. Il respire. IL RESPIRE !\n\nTiens : ma boussole elfique. Son aiguille de cristal traverse la brume du Bois-Doré. Prends ton bateau vers l'est… et viens me voir chez moi.", "si": {}, "geste": "rire", "humeur": 0.4},
		],
		"quete_inconnue": [
			{"t": "L'Arbre ? Laisse-moi d'abord te parler de lui. Demande-moi qui je suis.", "si": {}},
		],
		"souvenir": [
			{"t": "Bien sûr que je me souviens. Les elfes n'oublient rien : c'est parfois un problème.", "si": {}},
		],
		"au_revoir": [
			{"t": "Que tes racines soient profondes, {surnom}.", "si": {}, "geste": "salut"},
			{"t": "À bientôt. Marche doucement : il y a des fleurs partout.", "si": {}},
			{"t": "Va. Le vent te ramènera.", "si": {}},
		],
		"interpelle": [
			{"t": "Psst… Par ici, humain. Approche, n'aie pas peur.", "si": {"visites_max": 0}},
			{"t": "{surnom} ! Les feuilles chantent ton nom.", "si": {"visites_min": 1}},
		],
		"frappe": [
			{"t": "Ah ! … Pourquoi ? Je ne t'ai rien fait.", "si": {}, "geste": "colere", "humeur": -0.4},
			{"t": "Arrête ! La violence n'a pas sa place sous ces branches.", "si": {}, "geste": "colere", "humeur": -0.4},
		],
	},

	"questions": [
		{"id": "foret", "si": {"visites_min": 2}, "texte": "Dis-moi, toi qui vis ici… Tu aimes la forêt ?",
			"reponses": [
				{"label": "Oui, j'adore marcher sous les arbres.", "valeur": "oui", "affinite": 5.0, "humeur": 0.15, "t": "Alors tu aimeras le Bois-Doré. Là-bas, on marche AU-DESSUS des arbres, aussi."},
				{"label": "Je préfère la plage.", "valeur": "plage", "affinite": 1.0, "humeur": 0.0, "t": "La plage… Le sable chaud, le bruit des vagues. Oui, je comprends. Un peu."},
				{"label": "Le bois, c'est surtout utile pour se chauffer.", "valeur": "bois", "affinite": -3.0, "humeur": -0.2, "t": "… Je vais faire semblant de ne pas avoir entendu."},
			]},
	],
}

extends RefCounted
## V42 : les habitants du Bois-Doré. Sept elfes avec leur histoire, leur métier, leur petite
## quête et leurs liens (ils parlent les uns des autres), et des elfes de passage plus
## discrets. Même cerveau que Barnabé (pnj_brain_v31.gd). Les répliques communes (cadeaux,
## au revoir, coups…) sont ajoutées par complete() quand une fiche ne les donne pas.
## Apparence ("elfe") : texture, cheveux (couleur), coiffure (long, tresse, chignon, queue,
## court), silhouette (robe ou tunique), robe/cape/bijou (couleurs), yeux, taille.

const TEX := "res://assets/textures/elfes/"

const COMMON := {
	"cadeau_aime": [
		{"t": "Pour moi ? {dernier_cadeau}… Merci, {surnom}. Les humains ont parfois des gestes d'elfe.", "si": {}, "geste": "rire"},
		{"t": "Oh ! {dernier_cadeau}. Je le garderai précieusement.", "si": {}},
	],
	"cadeau_neutre": [
		{"t": "Merci. C'est… curieux. Je lui trouverai une place.", "si": {}},
		{"t": "Un cadeau des humains ! Je le montrerai aux autres.", "si": {}},
	],
	"cadeau_deteste": [
		{"t": "Je… préfère que tu le gardes.", "si": {}},
	],
	"cadeau_refus": [
		{"t": "Une arme ? Non merci. Ici, les arbres nous gardent.", "si": {}},
	],
	"souvenir": [
		{"t": "Bien sûr que je me souviens de toi. Les elfes n'oublient rien.", "si": {}},
	],
	"au_revoir": [
		{"t": "Que tes racines soient profondes, {surnom}.", "si": {}, "geste": "salut"},
		{"t": "À bientôt. Le Bois-Doré t'attend.", "si": {}},
		{"t": "Va en paix, et reviens nous voir.", "si": {}},
	],
	"frappe": [
		{"t": "Ah ! Mais… pourquoi ?!", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Arrête ! On ne frappe personne sous l'Arbre-Mère !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"quete_inconnue": [
		{"t": "Je ne t'ai rien demandé… pas encore.", "si": {}},
	],
	"blague": [
		{"t": "Que dit un arbre à un autre arbre ? « Tu as l'air enraciné, aujourd'hui. » … Les blagues d'arbres sont lentes.", "si": {}, "geste": "rire"},
		{"t": "Un humain a demandé à Faelar son âge. Faelar a commencé à compter. Il compte encore.", "si": {}, "geste": "rire"},
	],
	# Boutique (réponses par défaut)
	"boutique": [{"t": "Regarde ce que j'ai. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Pas avec toi.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "{objet}, pour {prix} pièces. Prends-en soin.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "{prix} pièces, et tu n'en as que {pieces}. Reviens plus tard.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein, {surnom}.", "si": {}}],
	"vente": [{"t": "{objet} ? Je te le prends pour {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout ? D'accord : {prix} pièces le lot.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… pour toi, un petit rabais. Les arbres n'ont rien vu.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Mes prix sont justes. Les elfes ne mentent pas sur les prix.", "si": {}}],
	"marchande_deja": [{"t": "On en a déjà parlé aujourd'hui.", "si": {}}],
}


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			rep[k] = COMMON[k]
	out["repliques"] = rep
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = BASE[k]
	if not out.has("compagnon_lignes"):
		out["compagnon_lignes"] = []
	return out


const BASE := {
	"prefixes": {
		"joie": ["Oh !", "Ha ha !", "Quelle belle journée !", "Mmh !"],
		"neutre": ["Hmm…", "Voyons…", "Oui ?", "Écoute…"],
		"triste": ["Hélas…", "Ah…", "Mmh.", "Pardon…"],
		"colere": ["Tss.", "Assez.", "Recule.", "Non."],
	},
	"tics": ["Par les racines de l'Arbre-Mère…", "Les feuilles l'ont dit.", "Écoute le vent.", "Que la lumière te garde."],
	"humeur_mots": [[0.6, "radieux"], [0.25, "serein"], [-0.25, "pensif"], [-0.6, "contrarié"], [-2.0, "glacial"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "ami du Bois"], [75, "frère du Bois"], [95, "elfe d'honneur"]],
}


## Les sept habitants nommés : fiche + lieu de vie (« coin ») dans le village.
const NAMED := [
	{
		"coin": "herboristerie",
		"data": {
			"id": "aelwen", "nom": "Aëlwen Feuillargent", "titre": "herboriste du Bois-Doré",
			"elfe": {"texture": TEX + "elfe_pourpre.png", "cheveux": [0.72, 0.32, 0.16], "coiffure": "tresse", "silhouette": "robe",
				"robe": [0.45, 0.16, 0.24], "cape": [0.9, 0.82, 0.62], "bijou": [0.86, 0.7, 0.35], "yeux": [0.55, 0.38, 0.15]},
			"teinte": [1.0, 0.9, 0.82],
			"humeur_base": 0.25, "energie_base": 0.8, "affinite_depart": 8.0,
			"traits": {"bavard": 0.7, "humour": 0.4, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3, "radin": 0.4},
			"aime": {"champignon": 2.0, "fleur_lune": 3.0, "miel": 1.5, "baies": 1.2, "pomme": 1.0},
			"deteste": {"buche": -1.5, "vieille_botte": -1.0},
			"refuse": ["hache", "epee", "pelle"],
			"quete": {"objet": "champignon", "nombre": 5, "recompense": [["potion_seve", 2]], "affinite": 15.0,
				"sujet": "Tes champignons…", "note": "m'a demandé des champignons", "souvenir": "Tes champignons ont soigné la toux de tout le village."},
			"boutique": {"vend": {"potion_seve": 15, "tisane_lune": 6}, "achete": {"champignon": 3, "baies": 2, "pomme": 2, "miel": 6, "fleur_lune": 25}},
			"repliques": {
				"accueil": [
					{"t": "Un humain dans mon herboristerie ! Approche, approche. Aëlwen Feuillargent, herboriste. Ici, tout ce qui pousse soigne… ou presque.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom}. Tu as une petite mine. Une tisane ?", "si": {"visites_min": 2}},
					{"t": "Tu es blessé ! Assieds-toi. Non, ne discute pas. Une potion de sève, et tu seras comme neuf.", "si": {"vie_basse": true}},
					{"t": "Tu reviens de la forêt ? Tu sens la mousse et le champignon. C'est un compliment.", "si": {"visites_min": 2, "humeur_min": 0.2}},
				],
				"humeur": [
					{"t": "Très bien ! Les champignons de lune ont poussé cette nuit. Je les ai entendus.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Débordée. Nimiel s'est encore écorché les genoux en grimpant aux passerelles.", "si": {}},
					{"t": "Fatiguée. J'ai veillé toute la nuit sur une décoction. Elle a tourné. Comme mon humeur.", "si": {"energie_max": 0.4}},
				],
				"lui": [
					{"t": "Je soigne. Les écorchures, les rhumes, les cœurs brisés… surtout ceux de Caelan, ces temps-ci.", "si": {}},
					{"t": "Ma potion de sève ? La recette de ma grand-mère. Elle rend trois cœurs d'un coup. Ne me demande pas ce qu'il y a dedans.", "si": {}},
					{"t": "Tu veux m'aider ? Rapporte-moi {manque} champignons de ta forêt. Ici, ils ne poussent qu'à la pleine lune. Je te paierai en potions.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Toujours {manque} champignons à trouver, {surnom}. Les sous-bois humides, au pied des grands arbres.", "si": {"quete": "demandee"}},
					{"t": "Grâce à tes champignons, j'ai soigné la toux de la moitié du village. Faelar compris. Il dit que c'est la première fois en trois siècles.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "La forêt du Bois-Doré est une pharmacie : écorce pour la fièvre, mousse pour les plaies, rosée pour les yeux fatigués.", "si": {}},
					{"t": "Ne mange jamais les baies bleues du sous-bois. Sauf si tu veux voir des lucioles qui parlent. Pendant deux jours.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "Sylwen a raté son pain ce matin. Elle dit que c'est le four. C'est toujours le four.", "si": {}, "geste": "rire"},
					{"t": "Caelan joue la même chanson d'amour depuis cent ans. Ilyria fait semblant de ne pas comprendre. Ils m'épuisent.", "si": {}},
					{"t": "Lyra est revenue grâce à toi. Elle n'arrête pas de parler de « l'humain gentil ». Ça te va bien.", "si": {"a_trouve": "arbre_sacre"}},
				],
				"quete_manque": [{"t": "Il me manque encore {manque} champignons. Patience : la forêt en est pleine.", "si": {}}],
				"quete_fin": [{"t": "Cinq beaux champignons ! Ils sentent la pluie. Tiens, deux potions de sève, avec mes remerciements. Ne les bois pas d'un coup.", "si": {}, "geste": "rire", "humeur": 0.3}],
				"boutique": [
					{"t": "Potions de sève (trois cœurs !) et tisanes de lune. Et je rachète tout ce qui pousse. Tu as {pieces} pièces.", "si": {}},
					{"t": "Ah, mon étal ! Regarde, sens, goûte… enfin, paie d'abord.", "si": {}, "geste": "rire"},
				],
				"achat_potion_seve": [{"t": "Une potion de sève. Bois-la quand tu en as besoin, pas avant. La sève n'aime pas attendre.", "si": {}, "geste": "salut"}],
				"vente_fleur_lune": [{"t": "Une fleur de lune ?! Tu sais où elles poussent ? … Ne me le dis pas, je saurai le trouver. {prix} pièces !", "si": {}, "geste": "rire"}],
				"interpelle": [
					{"t": "Toi, l'humain ! Tu as l'air fatigué. Viens voir mes potions !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Une tisane ?", "si": {"visites_min": 1}},
				],
			},
			"questions": [
				{"id": "soins", "si": {"visites_min": 2}, "texte": "Dis-moi, comment soignent-ils les blessures, chez toi ?",
					"reponses": [
						{"label": "Avec des herbes, comme toi.", "valeur": "herbes", "affinite": 4.0, "humeur": 0.15, "t": "Vraiment ? Alors nous sommes cousins d'herbes. Tu m'apporteras les tiennes."},
						{"label": "En mangeant des noix de coco.", "valeur": "coco", "affinite": 2.0, "humeur": 0.1, "t": "Des noix de coco… Il faudra que j'essaie. Pour la science."},
						{"label": "On ne se soigne pas, on serre les dents.", "valeur": "dents", "affinite": -2.0, "humeur": -0.1, "t": "… Je comprends mieux pourquoi tu as cette tête-là."},
					]},
			],
		},
	},
	{
		"coin": "boulangerie",
		"data": {
			"id": "sylwen", "nom": "Sylwen Rayonmiel", "titre": "boulangère de miel",
			"elfe": {"texture": TEX + "elfe_ivoire.png", "cheveux": [0.95, 0.8, 0.45], "coiffure": "chignon", "silhouette": "robe",
				"robe": [0.92, 0.84, 0.66], "cape": [0.78, 0.5, 0.25], "bijou": [0.9, 0.75, 0.35], "yeux": [0.35, 0.5, 0.75]},
			"teinte": [1.0, 0.9, 0.82],
			"humeur_base": 0.45, "energie_base": 0.85, "affinite_depart": 12.0,
			"traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.2, "radin": 0.2},
			"aime": {"miel": 3.0, "baies": 2.0, "pomme": 1.5, "noix_coco": 2.0, "pain_miel": 1.0},
			"deteste": {"caillou": -0.5},
			"refuse": ["hache", "epee"],
			"quete": {"objet": "miel", "nombre": 2, "recompense": [["pain_miel", 3]], "affinite": 15.0,
				"sujet": "Ton miel sauvage…", "note": "m'a demandé du miel", "souvenir": "Tes rayons de miel ont fait le meilleur pain de l'année."},
			"boutique": {"vend": {"pain_miel": 8, "tisane_lune": 5}, "achete": {"miel": 8, "baies": 2, "pomme": 2, "noix_coco": 3}},
			"repliques": {
				"accueil": [
					{"t": "Oh ! Un visiteur ! Tu as faim ? Tout le monde a faim. Sylwen Rayonmiel, boulangère. Goûte-moi ça.", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.1},
					{"t": "{surnom} ! Le pain sort du four. Enfin, il en sortira. Bientôt. Si le four veut bien.", "si": {"visites_min": 2}, "geste": "rire"},
					{"t": "Tu as une tête à manger du pain de miel. C'est ma façon de dire bonjour.", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Merveilleusement bien ! Le pain a levé, les abeilles chantent, et personne n'a renversé ma farine aujourd'hui.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Mon four boude. Je lui parle gentiment, mais il boude.", "si": {"humeur_max": 0.2}},
				],
				"lui": [
					{"t": "Je fais le pain du village depuis deux cents ans. Personne n'a jamais eu faim au Bois-Doré. Sauf Thalion, qui oublie de manger.", "si": {}},
					{"t": "Mon secret ? Le miel sauvage. Les abeilles du Bois-Doré butinent l'Arbre-Mère : leur miel est doré comme ses feuilles.", "si": {}},
					{"t": "Il me manque du miel sauvage, {surnom}. Tu en trouverais {manque} rayons ? Dans les arbres creux de ton île, en coupant le bois. Je te ferai du pain en échange !", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} rayons de miel, tu y penses ? Mon four m'en parle tous les jours.", "si": {"quete": "demandee"}},
					{"t": "Ton miel ! Le pain de cette semaine a le goût du soleil. Tout le village me demande la recette.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Tu as vu les passerelles ? Moi, je n'y monte jamais avec un plateau de pains. Une fois, une seule fois…", "si": {}, "geste": "rire"},
					{"t": "Les abeilles vivent tout en haut de l'Arbre-Mère. Thalion va chercher le miel. Il dit que c'est de l'entraînement.", "si": {}},
				],
				"rumeur": [
					{"t": "Caelan a encore composé une chanson pour Ilyria. Quarante couplets. Ilyria s'est endormie au douzième.", "si": {}, "geste": "rire"},
					{"t": "Nimiel a caché une grenouille dans mon pétrin. Je ne dirai rien à sa mère. Cette fois.", "si": {}},
					{"t": "Faelar raconte qu'un humain a vaincu le grand serpent sous la mer. C'est toi ?! Prends un pain. Prends-en deux !", "si": {"a_trouve": "naga"}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Il me manque encore {manque} rayons de miel. Courage, mon four t'attend !", "si": {}}],
				"quete_fin": [{"t": "Du miel sauvage ! Il sent la fleur et la sève. Tiens : trois pains de miel tout chauds. Enfin, tièdes. Le four, tu sais.", "si": {}, "geste": "rire", "humeur": 0.3}],
				"boutique": [
					{"t": "Pains de miel (deux cœurs chacun !) et tisanes. Et je rachète le miel, les fruits, les noix de coco. Tu as {pieces} pièces.", "si": {}},
				],
				"interpelle": [
					{"t": "Hé ! Toi ! Ça sent bon, hein ? Viens goûter !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Pain chaud !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "garde",
		"data": {
			"id": "thalion", "nom": "Thalion Ventvif", "titre": "archer, garde du Bois-Doré",
			"elfe": {"texture": TEX + "elfe_azur.png", "cheveux": [0.12, 0.1, 0.1], "coiffure": "queue", "silhouette": "tunique",
				"robe": [0.16, 0.3, 0.48], "cape": [0.24, 0.32, 0.22], "bijou": [0.75, 0.78, 0.82], "yeux": [0.4, 0.55, 0.8], "arc": true},
			"teinte": [0.98, 0.88, 0.8],
			"humeur_base": 0.0, "energie_base": 0.9, "affinite_depart": 0.0,
			"traits": {"bavard": 0.3, "humour": 0.25, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.6},
			"aime": {"baton": 1.5, "pomme": 1.0, "piece_or": 1.0, "ecaille_naga": 4.0},
			"deteste": {"coquillage": -0.3},
			"refuse": ["epee", "hache"],
			"quete": {"objet": "baton", "nombre": 4, "recompense": [["piece", 20]], "affinite": 18.0,
				"sujet": "Tes bâtons pour les flèches…", "note": "m'a demandé des bâtons pour ses flèches", "souvenir": "Mes flèches de ton bois volent droit. Je n'oublie pas."},
			"repliques": {
				"accueil": [
					{"t": "Halte. Un humain… avec la boussole de Lyra. Bon. Thalion Ventvif, garde du Bois-Doré. Je t'ai à l'œil.", "si": {"visites_max": 1}},
					{"t": "Encore toi. Tu ne tiens pas en place, hein ?", "si": {"visites_min": 2, "affinite_max": 30}},
					{"t": "{surnom}. Content de te voir. … Ne le répète pas.", "si": {"visites_min": 2, "affinite_min": 30}},
					{"t": "Range cette épée dans le village. Ici, c'est moi qui veille.", "si": {"tient": "epee"}},
				],
				"humeur": [
					{"t": "Calme. Trop calme. Je n'aime pas quand c'est trop calme.", "si": {}},
					{"t": "Bien. J'ai touché une pomme à cent pas ce matin. Ilyria a dit que c'était de la chance. Ce n'était pas de la chance.", "si": {"humeur_min": 0.1}},
				],
				"lui": [
					{"t": "Je garde l'entrée du village. Depuis que la brume s'est ouverte pour toi, je garde surtout un œil sur toi.", "si": {}},
					{"t": "Mon arc est taillé dans une branche tombée de l'Arbre-Mère. On ne coupe jamais l'Arbre. Jamais.", "si": {}},
					{"t": "Il me faut du bois droit pour mes flèches. Rapporte-moi {manque} bâtons bien droits, et je te paierai. Honnêtement.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} bâtons ? Une flèche tordue, c'est une flèche perdue.", "si": {"quete": "demandee"}},
					{"t": "Tes bâtons ont fait de belles flèches. Tu as l'œil pour le bois. Pour un humain.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "La forêt est grande. Ne t'éloigne pas du sentier la nuit : les racines bougent. Enfin… on le dit.", "si": {}},
					{"t": "Du haut des plates-formes, on voit ton île et la jungle. Et parfois, Barnabé qui fait de grands signes. On ne répond pas.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "Le grand serpent des abysses… Faelar dit que tu l'as vaincu. Si c'est vrai, je retire ce que j'ai dit sur toi. Une partie.", "si": {"a_trouve": "naga"}},
					{"t": "Caelan joue de la harpe sous les fenêtres d'Ilyria. Toutes les nuits. Je suis garde : je dois tout entendre. TOUT.", "si": {}, "geste": "colere"},
					{"t": "Nimiel veut devenir archère. Elle a tiré sur la porte de Sylwen. La porte n'a pas survécu.", "si": {}, "geste": "rire"},
					{"t": "Des lumières dansent dans la forêt. Des esprits, dit Faelar. Je ne tire pas sur les esprits.", "si": {"pas_trouve": "porte_racines"}},
					{"t": "La porte de l'Arbre-Mère est ouverte… Trois siècles que je la garde fermée, et un humain l'ouvre en une semaine. Bon. Bravo.", "si": {"a_trouve": "porte_racines"}},
				],
				"quete_manque": [{"t": "Encore {manque} bâtons. Droits, hein.", "si": {}}],
				"quete_fin": [{"t": "Bon bois. Droit, sec, solide. Voilà vingt pièces. Et… merci, {surnom}.", "si": {}, "geste": "salut", "humeur": 0.2}],
				"interpelle": [
					{"t": "Toi ! Pas si vite.", "si": {"visites_max": 0}},
					{"t": "{surnom}. Tout va bien ?", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "ancien",
		"data": {
			"id": "faelar", "nom": "Faelar l'Ancien", "titre": "conteur du Bois-Doré",
			"elfe": {"texture": TEX + "elfe_crepuscule.png", "cheveux": [0.95, 0.95, 0.97], "coiffure": "long", "silhouette": "robe",
				"robe": [0.3, 0.28, 0.45], "cape": [0.55, 0.5, 0.7], "bijou": [0.85, 0.85, 0.9], "yeux": [0.6, 0.6, 0.75], "baton": true},
			"teinte": [0.97, 0.9, 0.85],
			"humeur_base": 0.3, "energie_base": 0.4, "affinite_depart": 15.0,
			"traits": {"bavard": 0.95, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"perle": 2.0, "coquillage": 1.0, "miel": 1.0, "ecaille_naga": 3.0, "fragment_amulette": 2.0},
			"deteste": {},
			"refuse": ["epee", "hache"],
			# V43 : la légende de la porte de l'Arbre-Mère
			"sujets_speciaux": [
				{"id": "porte", "label": "Que cache l'Arbre-Mère ?", "si": {"pas_fait": "lanterne_fee"}},
				{"id": "esprits", "label": "Les esprits-lucioles…", "si": {"fait": "lanterne_fee", "pas_trouve": "porte_racines"}},
				{"id": "royaume", "label": "J'ai ouvert la porte de l'Arbre-Mère !", "si": {"a_trouve": "porte_racines"}},
			],
			"repliques": {
				"porte": [
					{"t": "Ah… Tu as vu la porte sculptée dans son tronc. Sous l'Arbre-Mère dort le Royaume des Racines, le pays des fées. Jadis, cinq esprits-lucioles gardaient sa porte ; un soir d'orage, ils se sont envolés dans la forêt, et la porte s'est refermée. Prends cette lanterne de fée. Les esprits dansent au-dessus des cercles de champignons blancs, tout autour du village. Ramène-les chez eux, et la porte s'ouvrira.", "si": {}, "action": "donne", "donne": [["lanterne_fee", 1]], "pose": "lanterne_fee", "geste": "salut", "humeur": 0.1},
				],
				"esprits": [
					{"t": "Cinq esprits, cinq cercles de champignons blancs, dans la forêt autour du village. Ils ne se laissent attraper que par la lanterne. Et par la patience.", "si": {}},
					{"t": "Cherche les petites lumières qui dansent sous les grands arbres, loin de la place. Le jour, elles brillent aussi, si l'on sait regarder.", "si": {}},
					{"t": "Quand ta lanterne en abritera cinq, va devant la porte de l'Arbre-Mère, côté couchant. Ils sauront quoi faire.", "si": {}},
				],
				"royaume": [
					{"t": "Le Royaume des Racines… Cela faisait trois cents ans que personne n'y était descendu. Les fées sont joueuses : méfie-toi de leurs énigmes, et ne perds pas le soleil de vue.", "si": {"pas_trouve": "prismes"}},
					{"t": "La Fleur-Porte s'est ouverte pour toi ! Plus loin, dit-on, vit la Reine des Ronces. Elle n'aime ni les humains, ni les elfes, ni personne. Sois prudent.", "si": {"a_trouve": "prismes"}},
				],
				"accueil": [
					{"t": "Approche, jeune humain. Assieds-toi. Je suis Faelar. J'ai vu pousser cet arbre-là, et celui-là, et… ah, non, celui-là était déjà grand.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom}. Tu veux une histoire ? J'en ai trois mille. Celle-ci est courte. Enfin, pour un elfe.", "si": {"visites_min": 2}},
					{"t": "Le vainqueur de Nâga ! Approche, que je te regarde. Tu es plus petit que dans la chanson de Barnabé.", "si": {"a_trouve": "naga", "visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Mes os craquent comme du bois sec, mais mon cœur est vert. Ça va.", "si": {}},
					{"t": "J'ai dormi trois jours. Ce n'est rien : la dernière fois, c'était trois ans.", "si": {}, "geste": "rire"},
				],
				"lui": [
					{"t": "Je suis le plus vieux du Bois-Doré. Neuf cent quatre-vingt-sept ans. Je compte les printemps, pas les hivers : c'est plus gai.", "si": {}},
					{"t": "Il y a longtemps, les Anciens vivaient sous vos îles. Un peuple de pierre et de serpents. Ils ont enchaîné Nâga, puis ils ont disparu. Nous, nous sommes restés dans les arbres.", "si": {}},
					{"t": "L'Arbre-Mère a semé des graines sur toutes les îles. Celle que Lyra gardait était la dernière à mourir. Tu l'as sauvée. Le Bois s'en souviendra.", "si": {"a_trouve": "arbre_sacre"}},
					{"t": "La brume ? C'est le souffle de l'Arbre-Mère. Elle s'ouvre devant ceux qu'il aime. Il t'aime bien, apparemment. Il a des goûts étranges.", "si": {"sujet_min": ["lui", 2]}, "geste": "rire"},
				],
				"ile": [
					{"t": "Chaque arbre-maison a un nom. Celui d'Ilyria s'appelle « Fil-d'Aube ». Le mien s'appelle « Encore-Debout ». C'est un vieux mot elfe.", "si": {}, "geste": "rire"},
					{"t": "Sous la place, les racines de l'Arbre-Mère descendent jusqu'à la mer. Parfois, la nuit, l'eau de la fontaine chante.", "si": {}},
				],
				"rumeur": [
					{"t": "Barnabé Coquillard… Un humain qui dessine des cartes de choses qu'il n'a pas vues. Nous l'aimons beaucoup. De loin.", "si": {}, "geste": "rire"},
					{"t": "Octave, le forgeron dans l'arbre, a un cœur d'elfe sous sa barbe. Ne le lui dis pas : il te frapperait avec son marteau.", "si": {}},
					{"t": "On dit que Caelan et Ilyria se marieront avant le prochain millénaire. Je parie sur après.", "si": {}, "geste": "rire"},
				],
				"interpelle": [
					{"t": "Jeune humain… viens écouter une histoire.", "si": {"visites_max": 0}},
					{"t": "{surnom} ! J'en ai une nouvelle. Enfin, une vieille.", "si": {"visites_min": 1}},
				],
			},
			"questions": [
				{"id": "histoire", "si": {"visites_min": 2}, "texte": "Veux-tu entendre l'histoire de la première graine ?",
					"reponses": [
						{"label": "Oui, raconte !", "valeur": "oui", "affinite": 5.0, "humeur": 0.2, "t": "Au commencement, il n'y avait que la mer. Une étoile est tombée, si fatiguée qu'elle s'est endormie dans l'eau. En rêvant, elle a fait pousser une graine… L'Arbre-Mère. Et nous sommes ses feuilles."},
						{"label": "Une autre fois, peut-être.", "valeur": "plus_tard", "affinite": 0.5, "humeur": 0.0, "t": "Bien sûr. J'ai le temps. Beaucoup de temps."},
					]},
			],
		},
	},
	{
		"coin": "fontaine",
		"data": {
			"id": "nimiel", "nom": "Nimiel", "titre": "petite elfe très curieuse",
			"elfe": {"texture": TEX + "elfe_azur.png", "cheveux": [0.42, 0.26, 0.14], "coiffure": "chignon", "silhouette": "robe",
				"robe": [0.35, 0.6, 0.85], "cape": [0.95, 0.85, 0.5], "bijou": [0.9, 0.85, 0.6], "yeux": [0.3, 0.65, 0.45], "taille": 0.72},
			"teinte": [1.0, 0.9, 0.84],
			"humeur_base": 0.6, "energie_base": 1.0, "affinite_depart": 20.0,
			"traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"coquillage": 3.0, "perle": 2.5, "baies": 2.0, "pomme": 1.5, "miel": 2.0, "boussole": 1.0},
			"deteste": {"champignon": -0.8},
			"refuse": ["epee", "hache", "pelle"],
			"quete": {"objet": "coquillage", "nombre": 3, "recompense": [["perle", 1]], "affinite": 20.0,
				"sujet": "Tes coquillages de la mer…", "note": "m'a demandé des coquillages de la mer", "souvenir": "Tu m'as apporté des coquillages de la vraie mer ! Je les ai tous gardés."},
			"repliques": {
				"accueil": [
					{"t": "Un HUMAIN ?! Un vrai ?! Tu as des oreilles toutes rondes ! Je m'appelle Nimiel ! J'ai quarante-deux ans, je suis encore petite. Et toi ?", "si": {"visites_max": 1}, "geste": "rire", "humeur": 0.2},
					{"t": "{surnom} ! Tu es revenu ! Tu veux voir ma grenouille ?", "si": {"visites_min": 2}, "geste": "rire"},
					{"t": "Tu as une épée ! Je peux la toucher ? Non ? Juste un peu ? Bon.", "si": {"tient": "epee"}},
				],
				"humeur": [
					{"t": "Super bien ! J'ai grimpé jusqu'à la troisième passerelle sans les mains ! … Ne le dis pas à Aëlwen.", "si": {}, "geste": "rire"},
					{"t": "Je m'ennuie. Thalion ne veut pas m'apprendre l'arc. Il dit que la porte de Sylwen ne s'en est pas remise.", "si": {}},
				],
				"lui": [
					{"t": "Moi, plus tard, je serai archère ! Ou herboriste. Ou exploratrice ! Comme toi !", "si": {}},
					{"t": "Tu viens de la mer ? Il paraît qu'il y a des coquillages qui chantent quand on les met contre l'oreille. Tu m'en rapportes {manque} ? S'il te plaît, s'il te plaît, s'il te plaît !", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Tu n'as pas oublié mes {manque} coquillages ? Je leur ai déjà fait une place sur l'étagère !", "si": {"quete": "demandee"}},
					{"t": "Mes coquillages chantent ! Enfin, ils font « fouuuh ». C'est la mer qui chante, Faelar dit.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Je connais toutes les cachettes du village ! Il y en a une sous la fontaine. Mais c'est un secret. Oups.", "si": {}, "geste": "rire"},
					{"t": "La nuit, l'Arbre-Mère brille. Maman dit qu'il veille sur nous. Moi je crois qu'il fait semblant de dormir.", "si": {}},
				],
				"rumeur": [
					{"t": "Caelan est amoureux d'Ilyria ! Tout le monde le sait ! Sauf Ilyria. Enfin, elle fait semblant.", "si": {}, "geste": "rire"},
					{"t": "Faelar s'est endormi au milieu d'une histoire. Encore. On lui a mis une fleur sur le nez.", "si": {}, "geste": "rire"},
					{"t": "Thalion a peur des grenouilles. C'est vrai ! Je l'ai vu !", "si": {}, "geste": "rire"},
					{"t": "J'ai vu une petite lumière danser au-dessus d'un cercle de champignons blancs, dans la forêt ! Faelar dit que c'est un esprit-luciole. Je n'ai pas eu le droit de la suivre.", "si": {"pas_trouve": "porte_racines"}},
					{"t": "Tu es descendu dans l'Arbre-Mère ?! Il y a des fées ? Des VRAIES ? Emmène-moi la prochaine fois ! S'il te plaît !", "si": {"a_trouve": "royaume"}, "geste": "rire"},
				],
				"blague": [
					{"t": "Pourquoi les grenouilles sont toujours contentes ? Parce qu'elles mangent ce qui les embête ! Hi hi hi !", "si": {}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Encore {manque} coquillages ! Sur la plage de ton île, il y en a plein, Lyra a dit !", "si": {}}],
				"quete_fin": [{"t": "Des coquillages de la VRAIE mer ! Ils sont trop beaux ! Tiens, c'est pour toi : une perle que j'ai trouvée dans la fontaine. Chut !", "si": {}, "geste": "rire", "humeur": 0.4}],
				"interpelle": [
					{"t": "HÉÉÉ ! L'humain ! Viens voir !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! {surnom} ! Joue avec moi !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "musicien",
		"data": {
			"id": "caelan", "nom": "Caelan Harpelune", "titre": "musicien, joueur de harpe",
			"elfe": {"texture": TEX + "elfe_crepuscule.png", "cheveux": [0.86, 0.86, 0.8], "coiffure": "long", "silhouette": "tunique",
				"robe": [0.36, 0.3, 0.52], "cape": [0.75, 0.68, 0.9], "bijou": [0.82, 0.84, 0.9], "yeux": [0.5, 0.45, 0.8]},
			"teinte": [0.98, 0.9, 0.84],
			"humeur_base": 0.15, "energie_base": 0.6, "affinite_depart": 10.0,
			"traits": {"bavard": 0.8, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.7, "rancunier": 0.3},
			"aime": {"bague": 3.0, "perle": 2.0, "fleur_lune": 2.5, "miel": 1.0},
			"deteste": {"vieille_botte": -1.0},
			"refuse": ["epee", "hache"],
			"quete": {"objet": "bague", "nombre": 1, "recompense": [["piece", 25]], "affinite": 25.0,
				"sujet": "La bague pour Ilyria…", "note": "m'a demandé une bague pour Ilyria", "souvenir": "Tu m'as trouvé la bague. Je… je ne l'ai pas encore offerte. Mais bientôt !"},
			"repliques": {
				"accueil": [
					{"t": "Oh ! Un auditeur ! Assieds-toi, je joue la « Ballade de l'Aube ». Elle dure trois heures. Caelan Harpelune, pour te servir.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom} ! Tu tombes bien : j'ai écrit un nouveau couplet. Le quarante-et-unième.", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Le cœur lourd et les cordes légères. Ilyria m'a souri ce matin. Ou alors elle souriait à la lumière.", "si": {}},
					{"t": "Inspiré ! J'ai trouvé une rime à « Ilyria » : « harmonie-a ». Ce n'est pas encore tout à fait ça.", "si": {"humeur_min": 0.2}, "geste": "rire"},
				],
				"lui": [
					{"t": "Je joue pour l'Arbre-Mère, pour le vent… et surtout pour une fenêtre, là-haut. Celle d'Ilyria.", "si": {}},
					{"t": "Tu sais garder un secret ? Je voudrais offrir une bague à Ilyria. Une bague d'humain, avec une pierre bleue, comme ses yeux. Tu en trouverais une ? Les plages de vos îles en cachent, il paraît.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "La bague… Tu en as trouvé une ? Avec une pierre bleue, hein. Pas rouge. Le rouge, c'est pour les déclarations de guerre.", "si": {"quete": "demandee"}},
					{"t": "La bague est dans ma poche depuis des jours. J'attends le bon moment. Le bon siècle, peut-être.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "Écoute : chaque arbre a sa note. L'Arbre-Mère fait un « do » si grave qu'on ne l'entend qu'avec les pieds.", "si": {}},
				],
				"rumeur": [
					{"t": "Thalion dit que ma harpe l'empêche de monter la garde. Il dit ça parce qu'il chante faux.", "si": {}, "geste": "colere"},
					{"t": "Sylwen a goûté ma chanson sur le pain. Elle a dit « joli ». Venant d'elle, c'est un triomphe.", "si": {}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Pas encore de bague ? Patience. L'amour attend bien depuis cent ans.", "si": {}}],
				"quete_fin": [{"t": "Une bague d'argent… avec une pierre bleue ! Elle est parfaite ! Tiens, vingt-cinq pièces. Et une chanson. Non, ne pars pas, elle est courte !", "si": {}, "geste": "rire", "humeur": 0.4}],
				"interpelle": [
					{"t": "(il chante) « Un humain passe sous les feuilles d'or… »", "si": {"visites_max": 0}},
					{"t": "(il chante) « {surnom}, {surnom}, viens écouter… »", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "tisserande",
		"data": {
			"id": "ilyria", "nom": "Ilyria Fildaube", "titre": "tisserande des passerelles",
			"elfe": {"texture": TEX + "elfe_ivoire.png", "cheveux": [0.2, 0.18, 0.3], "coiffure": "long", "silhouette": "robe",
				"robe": [0.62, 0.78, 0.92], "cape": [0.95, 0.92, 0.98], "bijou": [0.82, 0.86, 0.95], "yeux": [0.3, 0.5, 0.9]},
			"teinte": [1.0, 0.91, 0.86],
			"humeur_base": 0.3, "energie_base": 0.7, "affinite_depart": 8.0,
			"traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"perle": 3.0, "coquillage": 1.5, "fleur_lune": 2.0, "bague": 2.0},
			"deteste": {"vieille_botte": -1.0, "buche": -0.5},
			"refuse": ["epee", "hache"],
			"quete": {"objet": "perle", "nombre": 3, "recompense": [["piece", 35]], "affinite": 18.0,
				"sujet": "Les perles pour ta robe de fête…", "note": "m'a demandé des perles", "souvenir": "Tes perles brillent sur ma robe de fête. Tout le monde me demande d'où elles viennent."},
			"repliques": {
				"accueil": [
					{"t": "Tu es monté jusqu'ici ? Bienvenue sur ma plate-forme. Ilyria Fildaube. Attention aux fils : ils sont partout, et ils sont à moi.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom}. Tu viens voir mes tissages, ou tu viens de la part de Caelan ?", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Bien. Le métier à tisser chante, le fil est doux. Et la harpe s'est tue cette nuit. Enfin un peu de silence.", "si": {}},
					{"t": "Un peu triste. La harpe s'est tue cette nuit. … Je ne dirai pas que ça me manque.", "si": {"humeur_max": 0.2}},
				],
				"lui": [
					{"t": "Je tisse les capes, les voiles des passerelles, les rubans des fêtes. Le fil, je le file avec la soie des araignées dorées. Elles sont gentilles.", "si": {}},
					{"t": "Je prépare ma robe pour la fête de l'Aube. Il me faudrait {manque} perles, pour la broder comme la rosée. Tu en trouves dans la mer, non ?", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} perles… La fête approche. Enfin, dans dix ans. Mais quand même.", "si": {"quete": "demandee"}},
					{"t": "Ma robe brille comme un matin de rosée, grâce à toi. Caelan l'a vue. Il a laissé tomber sa harpe.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "D'ici, on voit toute la place. Et tout le monde. Je sais tout ce qui se passe au village. Tout.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "Caelan croit que je ne sais pas. Je sais. Je sais depuis cent ans. J'attends qu'il ose.", "si": {}, "geste": "rire"},
					{"t": "Aëlwen soigne tout le monde, mais personne ne la soigne, elle. Apporte-lui des fleurs, un jour.", "si": {}},
					{"t": "Caelan a une bague dans sa poche. Il la tripote toute la journée. Il croit que personne ne voit.", "si": {"a_trouve": "bague_caelan"}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Encore {manque} perles. Rondes et blanches, comme la rosée.", "si": {}}],
				"quete_fin": [{"t": "Trois perles parfaites ! Tu as l'œil, {surnom}. Voilà trente-cinq pièces. Et si tu veux une cape un jour, je t'en tisse une.", "si": {}, "geste": "rire", "humeur": 0.3}],
				"interpelle": [
					{"t": "Attention aux fils, humain !", "si": {"visites_max": 0}},
					{"t": "{surnom}, tu viens voir mes tissages ?", "si": {"visites_min": 1}},
				],
			},
		},
	},
]


## Elfes de passage : noms, apparences et répliques courtes (tirées au sort, toujours les mêmes).
const PASSANTS := [
	["Elandor", "tunique", "court", [0.85, 0.75, 0.5], "elfe_azur.png", "promeneur"],
	["Miriel", "robe", "tresse", [0.9, 0.9, 0.85], "elfe_pourpre.png", "cueilleuse de fleurs"],
	["Taeron", "tunique", "queue", [0.55, 0.3, 0.15], "elfe_lyra.png", "charpentier des passerelles"],
	["Lirael", "robe", "long", [0.95, 0.8, 0.5], "elfe_crepuscule.png", "veilleuse des lanternes"],
	["Orophin", "tunique", "long", [0.2, 0.18, 0.16], "elfe_ivoire.png", "éclaireur"],
	["Celebrë", "robe", "chignon", [0.75, 0.75, 0.82], "elfe_azur.png", "chanteuse"],
	["Haldir", "tunique", "court", [0.9, 0.88, 0.8], "elfe_pourpre.png", "messager"],
	["Nessa", "robe", "long", [0.6, 0.2, 0.12], "elfe_lyra.png", "danseuse"],
	["Gilwen", "robe", "tresse", [0.35, 0.22, 0.12], "elfe_ivoire.png", "apicultrice"],
	["Rúmil", "tunique", "queue", [0.88, 0.86, 0.8], "elfe_crepuscule.png", "pêcheur de lumière"],
]

const PASSANT_LINES := {
	"accueil": [
		{"t": "Bonjour, humain. Bienvenue au Bois-Doré.", "si": {"visites_max": 1}, "geste": "salut"},
		{"t": "Te revoilà ! Le village parle de toi, tu sais.", "si": {"visites_min": 2}},
		{"t": "Oh, l'ami de Lyra ! Bonjour, bonjour.", "si": {"visites_max": 1, "a_trouve": "arbre_sacre"}, "geste": "salut"},
	],
	"humeur": [
		{"t": "Bien, merci. La lumière est douce aujourd'hui.", "si": {}},
		{"t": "Un peu fatigué. J'ai dansé toute la nuit sous l'Arbre-Mère.", "si": {}, "geste": "rire"},
		{"t": "Très bien ! Le vent sent le miel.", "si": {}},
	],
	"lui": [
		{"t": "Moi ? Rien de bien extraordinaire. Je vis ici depuis toujours. Enfin, depuis trois siècles.", "si": {}},
		{"t": "Je suis {titre}. Un métier tranquille. Les arbres ne sont jamais pressés.", "si": {}},
	],
	"ile": [
		{"t": "Tu as vu la Fontaine de lune ? La nuit, son cristal s'allume tout seul.", "si": {}},
		{"t": "Monte sur les passerelles, la vue est magnifique. Mais ne regarde pas en bas.", "si": {}, "geste": "rire"},
		{"t": "Aëlwen vend des potions, Sylwen du pain de miel. Et Faelar vend des histoires. Gratuitement. Beaucoup.", "si": {}, "geste": "rire"},
	],
	"rumeur": [
		{"t": "Caelan et Ilyria… tout le monde attend. Tout le monde.", "si": {}, "geste": "rire"},
		{"t": "Thalion t'a à l'œil. Ne lui en veux pas : il a tout le monde à l'œil.", "si": {}},
		{"t": "Il paraît que tu as soigné l'Arbre sacré, sur ton île. Merci, humain.", "si": {"a_trouve": "arbre_sacre"}},
		{"t": "Nimiel a encore fait une bêtise. Je ne sais pas laquelle, mais c'est sûr.", "si": {}, "geste": "rire"},
		{"t": "La porte de l'Arbre-Mère s'est ouverte ! Tout le village ne parle que de ça.", "si": {"a_trouve": "porte_racines"}},
	],
	"interpelle": [
		{"t": "Bonjour !", "si": {}},
		{"t": "Un humain… bienvenue !", "si": {"visites_max": 0}},
		{"t": "Belle journée, n'est-ce pas ?", "si": {}},
	],
}


## Fiche d'un elfe de passage (n = rang dans PASSANTS).
static func passant(n: int) -> Dictionary:
	var p: Array = PASSANTS[n % PASSANTS.size()]
	var robe_cols := [[0.2, 0.45, 0.35], [0.3, 0.38, 0.6], [0.55, 0.25, 0.3], [0.88, 0.82, 0.62], [0.4, 0.32, 0.55]]
	var lines: Dictionary = PASSANT_LINES.duplicate(true)
	for e in lines["lui"]:
		e["t"] = str(e["t"]).replace("{titre}", str(p[5]))
	var d := {
		"id": "elfe_%d" % n, "nom": str(p[0]), "titre": str(p[5]),
		"elfe": {"texture": TEX + str(p[4]), "cheveux": p[3], "coiffure": str(p[2]), "silhouette": str(p[1]),
			"robe": robe_cols[n % robe_cols.size()], "cape": [0.9, 0.88, 0.8], "bijou": [0.85, 0.85, 0.9], "yeux": [0.3 + 0.1 * (n % 3), 0.5, 0.6 - 0.1 * (n % 2)]},
		"teinte": [1.0, 0.9, 0.84],
		"humeur_base": 0.3, "energie_base": 0.7, "affinite_depart": 10.0,
		"traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
		"aime": {"miel": 1.0, "baies": 1.0, "perle": 1.5, "fleur_lune": 2.0},
		"deteste": {"buche": -1.0},
		"refuse": ["epee", "hache"],
		"repliques": lines,
	}
	return complete(d)

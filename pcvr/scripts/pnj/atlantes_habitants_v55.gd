extends RefCounted
## V55 : les Atlantes, le peuple de la cité engloutie. Six habitants nommés (la reine,
## l'artisan du corail, la petite curieuse, l'archiviste, le garde de la Porte des Marées,
## la marchande d'algues) et des Atlantes de passage. Même cerveau que les autres habitants
## (pnj_brain_v31.gd). Apparence : la fiche « elfe » (silhouette élancée, longs cheveux) aux
## couleurs de la mer, et la fiche « atlante » (couronne de nacre, trident, collier de
## coquillages, nageoires aux oreilles) — voir pnj_v31.gd.

const TEX := "res://assets/textures/pnj/"

const COMMON := {
	"cadeau_aime": [
		{"t": "Pour moi ? {dernier_cadeau}… Un trésor du monde d'en haut ! Merci, {surnom}.", "si": {}, "geste": "rire"},
		{"t": "Oh ! {dernier_cadeau} ! Je le poserai près de ma fenêtre, là où la lumière ondule.", "si": {}},
	],
	"cadeau_neutre": [
		{"t": "Merci… Je ne sais pas à quoi ça sert, mais c'est joli quand ça flotte.", "si": {}},
		{"t": "Un cadeau de la surface ! Les enfants vont vouloir le voir.", "si": {}},
	],
	"cadeau_deteste": [
		{"t": "Garde-le. Ça sent… la terre sèche.", "si": {}},
	],
	"cadeau_refus": [
		{"t": "Une arme ? Ici, sous le dôme, personne ne se bat.", "si": {}},
	],
	"souvenir": [
		{"t": "Je me souviens de toi. Tu es le premier visiteur depuis mille ans.", "si": {}},
	],
	"au_revoir": [
		{"t": "Que les courants te portent, {surnom}.", "si": {}, "geste": "salut"},
		{"t": "Reviens vite. Et garde ton masque bien serré.", "si": {}},
		{"t": "Va en paix, enfant de la surface.", "si": {}},
	],
	"frappe": [
		{"t": "Aïe ! Mais… on ne frappe pas sous le dôme !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Arrête ! Tu vas fâcher la Reine !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"quete_inconnue": [
		{"t": "Je ne t'ai rien demandé… pas encore.", "si": {}},
	],
	"blague": [
		{"t": "Pourquoi les poissons ne jouent-ils jamais aux cartes ? Parce qu'ils ont peur des requins ! Hi hi.", "si": {}, "geste": "rire"},
		{"t": "Que dit une huître à une autre huître ? Rien. Elles ont la bouche fermée. … C'est une blague très ancienne.", "si": {}, "geste": "rire"},
		{"t": "Un poulpe entre dans une taverne. Il commande huit boissons. Une par bras !", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, voyageur. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Pas avec toi.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "{objet}, pour {prix} pièces. Que la mer te soit douce.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "{prix} pièces, et tu n'en as que {pieces}. Reviens plus tard.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein, {surnom}.", "si": {}}],
	"vente": [{"t": "{objet} ? Je te le prends pour {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout ? D'accord : {prix} pièces le lot.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… pour le premier visiteur depuis mille ans, un petit rabais.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Mes prix sont aussi stables que le dôme.", "si": {}}],
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
		"joie": ["Oh !", "Ha ha !", "Quelle belle marée !", "Mmh !"],
		"neutre": ["Hmm…", "Voyons…", "Oui ?", "Écoute…"],
		"triste": ["Hélas…", "Ah…", "Mmh.", "Pardon…"],
		"colere": ["Tss.", "Assez.", "Recule.", "Non."],
	},
	"tics": ["Par les marées…", "Le cristal l'a dit.", "Écoute la mer.", "Que la lumière te garde."],
	"humeur_mots": [[0.6, "radieux"], [0.25, "serein"], [-0.25, "pensif"], [-0.6, "contrarié"], [-2.0, "glacial"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "ami des marées"], [75, "frère des profondeurs"], [95, "Atlante d'honneur"]],
}


## Les six habitants nommés : fiche + lieu de vie (« coin ») dans la cité.
const NAMED := [
	{
		"coin": "palais",
		"data": {
			"id": "nerea", "nom": "Néréa", "titre": "reine de l'Atlantide",
			"elfe": {"texture": TEX + "atlante_nacre.png", "cheveux": [0.86, 0.93, 0.97], "coiffure": "long", "silhouette": "robe",
				"robe": [0.16, 0.55, 0.6], "cape": [0.92, 0.96, 0.98], "bijou": [0.95, 0.8, 0.4], "yeux": [0.25, 0.75, 0.82]},
			"atlante": {"couronne": true, "collier": true, "nageoires": true},
			"teinte": [0.86, 0.95, 1.0],
			"humeur_base": 0.0, "energie_base": 0.5, "affinite_depart": 10.0,
			"traits": {"bavard": 0.5, "humour": 0.3, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"perle": 3.0, "coquillage": 1.5, "couronne_nuees": 3.0, "fleur_lune": 2.0, "poisson_lune": 2.5},
			"deteste": {"vieille_botte": -1.0},
			"refuse": ["hache"],
			"quete": {"objet": "perle_lumiere", "nombre": 3, "recompense": [["trident_marees", 1], ["piece_or", 3]], "affinite": 25.0,
				"sujet": "Les Perles de Lumière…", "note": "m'a demandé les trois Perles de Lumière",
				"souvenir": "Grâce à toi, le Grand Cristal brille de nouveau sur l'Atlantide."},
			"sujets_speciaux": [
				{"id": "cristal", "label": "Le Grand Cristal ?", "si": {"sujet_min": ["lui", 1]}},
				{"id": "perles", "label": "Où trouver les Perles ?", "si": {"quete": "demandee"}},
				{"id": "surface", "label": "Pourquoi vous cacher sous la mer ?", "si": {"visites_min": 2}},
			],
			"repliques": {
				"accueil": [
					{"t": "Un enfant de la surface… sous mon dôme. Le premier depuis mille ans. Approche. Je suis Néréa, reine de l'Atlantide. Tu as le masque des Rois-Ciel ; ils étaient nos amis, autrefois.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Te revoilà, {surnom}. Le dôme frissonne quand tu passes la Porte des Marées. Il t'aime bien.", "si": {"visites_min": 2, "pas_trouve": "cristal"}},
					{"t": "{surnom} ! Regarde la cité : le Grand Cristal chante de nouveau. C'est ton œuvre.", "si": {"a_trouve": "cristal"}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Inquiète. Chaque nuit, le Grand Cristal pâlit un peu plus, et le dôme avec lui.", "si": {"pas_trouve": "cristal"}},
					{"t": "Heureuse. La lumière est revenue, les enfants jouent sur les ponts du canal. Une reine n'en demande pas plus.", "si": {"a_trouve": "cristal"}, "geste": "rire"},
				],
				"lui": [
					{"t": "Mon peuple vivait sur une île, autrefois, comme le tien. Une nuit, la mer s'est levée et l'a avalée. Le Grand Cristal nous a enveloppés d'une bulle d'air, et nous sommes restés. Mille ans, sous la mer.", "si": {}},
					{"t": "Le Grand Cristal faiblit. Il se nourrit de trois Perles de Lumière, une pour chaque âge de la mer… Elles ont été dispersées quand les requins sont arrivés. Rapporte-moi les {manque}, et le dôme vivra encore mille ans. Je te donnerai le trident de nos rois.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Les Perles, {surnom}. Il en manque encore {manque}. Le jardin de corail, l'épave, la fosse aux méduses… Abyssos t'en dira plus.", "si": {"quete": "demandee"}},
					{"t": "Le trident te va bien. Mon arrière-grand-père s'en servait pour parler aux baleines. Moi, je n'ai jamais réussi.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"cristal": [
					{"t": "Tu le vois, au sommet de la tour, au centre de la cité ? C'est lui qui fait l'air, la lumière et le dôme. Quand il brille, la mer chante. Quand il pâlit… elle se tait.", "si": {"pas_trouve": "cristal"}},
					{"t": "Écoute-le : il chante. Les anciens disent qu'on l'entend jusqu'à la surface, les nuits calmes. Les baleines lui répondent.", "si": {"a_trouve": "cristal"}},
				],
				"perles": [
					{"t": "La Perle du Jardin dort dans le grand bénitier, au cœur du récif de corail, au nord-est de la cité. Les requins tournent autour. Sois prompt.", "si": {}},
					{"t": "La Perle de l'Épave est dans le coffre de « La Sirène Noire », le navire coulé à l'ouest de la Porte. Les marins de la surface l'avaient volée…", "si": {}},
					{"t": "La Perle de la Fosse repose sur l'autel, au fond de la Fosse aux Méduses, au nord, derrière la forêt de laminaires. Les méduses piquent : ne les frôle pas.", "si": {}},
				],
				"surface": [
					{"t": "Nous cacher ? Non. Nous attendons. La mer a ses raisons ; un jour, elle nous rendra notre île. En attendant, le dôme est notre ciel.", "si": {}},
				],
				"ile": [
					{"t": "Notre cité a sept quartiers et un canal circulaire. Les enfants disent que le canal fait le tour du monde. C'est presque vrai.", "si": {}},
				],
				"rumeur": [
					{"t": "Coralin se plaint des requins. Il a raison : ils lui volent ses dents de requin. … Enfin, l'inverse.", "si": {}, "geste": "rire"},
					{"t": "Ondine pose mille questions sur la surface. Réponds-lui gentiment, veux-tu ? Elle n'a jamais vu le soleil.", "si": {}},
				],
				"quete_manque": [{"t": "Il manque encore {manque} Perles de Lumière. Le cristal patiente. Moi aussi.", "si": {}}],
				"quete_fin": [{"t": "Les trois Perles… Les trois âges de la mer, réunis ! Regarde le Grand Cristal, {surnom}, regarde ! … Prends ce trident : celui des rois de l'Atlantide. Et ces trois pièces d'or, frappées avant le déluge.", "si": {}, "geste": "salut", "humeur": 0.5}],
				"interpelle": [
					{"t": "Enfant de la surface… approche.", "si": {"visites_max": 0}},
					{"t": "{surnom} ! La reine voudrait te parler.", "si": {"visites_min": 1, "pas_trouve": "cristal"}},
				],
			},
			"questions": [
				{"id": "soleil", "si": {"visites_min": 2}, "texte": "Dis-moi… le soleil, là-haut, est-il toujours aussi chaud ?",
					"reponses": [
						{"label": "Oui, et il fait briller la mer.", "valeur": "chaud", "affinite": 4.0, "humeur": 0.15, "t": "Briller la mer… Je l'avais oublié. Merci, {surnom}."},
						{"label": "Il brûle le nez, surtout.", "valeur": "nez", "affinite": 3.0, "humeur": 0.2, "t": "Ha ! Alors je préfère notre cristal. Il ne brûle personne."},
					]},
			],
		},
	},
	{
		"coin": "atelier",
		"data": {
			"id": "coralin", "nom": "Coralin", "titre": "artisan du corail",
			"elfe": {"texture": TEX + "atlante_corail.png", "cheveux": [0.9, 0.48, 0.3], "coiffure": "court", "silhouette": "tunique",
				"robe": [0.72, 0.3, 0.24], "cape": [0.3, 0.55, 0.58], "bijou": [0.86, 0.7, 0.42], "yeux": [0.3, 0.6, 0.55]},
			"atlante": {"collier": true, "nageoires": true},
			"teinte": [0.9, 0.93, 0.98],
			"humeur_base": 0.25, "energie_base": 0.9, "affinite_depart": 8.0,
			"traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.4, "radin": 0.5},
			"aime": {"dent_requin": 2.5, "coquillage": 1.5, "minerai_fer": 2.0, "obsidienne": 2.0, "epee_naine": 1.0},
			"deteste": {"buche": -1.0},
			"refuse": [],
			"quete": {"objet": "dent_requin", "nombre": 3, "recompense": [["palmes_atlante", 1]], "affinite": 15.0,
				"sujet": "Tes dents de requin…", "note": "m'a demandé trois dents de requin",
				"souvenir": "Avec tes dents de requin, j'ai taillé les plus belles palmes de la cité."},
			"repliques": {
				"accueil": [
					{"t": "Ho ! Un visiteur dans mon atelier ! Coralin, artisan du corail. Je taille, je polis, je sculpte. Ne touche pas au corail rouge : il mord.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom} ! Viens voir ma dernière sculpture. C'est un poisson. Ou un oursin. Je n'ai pas encore décidé.", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Excellent ! Le corail se laisse tailler comme du beurre, aujourd'hui.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Grognon. Un requin m'a volé mon outil préféré. Il me nargue depuis le récif.", "si": {"humeur_max": 0.2}},
				],
				"lui": [
					{"t": "Je fabrique tout ce qui sert sous la mer : lampes de nacre, peignes, palmes… Les palmes ! Avec, tu nages comme un dauphin.", "si": {}},
					{"t": "Pour tailler des palmes, il me faut {manque} dents de requin. Les requins rôdent autour du Jardin de corail. Frappe-les quand ils foncent sur toi, et ramasse les dents. Je te ferai une paire de palmes atlantes !", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Toujours {manque} dents de requin à trouver, {surnom}. Les requins tournent autour du récif. Attends qu'ils foncent, et frappe !", "si": {"quete": "demandee"}},
					{"t": "Mes palmes te vont ? Tu nages comme un vrai Atlante, maintenant. Presque.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Le corail rouge pousse lentement : un doigt par siècle. Mes sculptures ont toutes plus de mille ans. Moi aussi, presque.", "si": {}},
				],
				"rumeur": [
					{"t": "Marée vend des galettes d'algues. Elles sont… nourrissantes. C'est le mot gentil.", "si": {}, "geste": "rire"},
					{"t": "Triton monte la garde à la Porte depuis trois cents ans. Il n'a jamais vu personne entrer. Tu l'as rendu très heureux.", "si": {}},
				],
				"quete_manque": [{"t": "Il me faut encore {manque} dents de requin. Courage !", "si": {}}],
				"quete_fin": [{"t": "Trois dents de requin ! Bien pointues… Attends. … Voilà ! Des palmes atlantes, nervurées de nacre. Mets-les, et file comme un dauphin !", "si": {}, "geste": "rire", "humeur": 0.3}],
				"interpelle": [
					{"t": "Hé ! Toi ! Viens voir mon atelier !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! J'ai du nouveau !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "canal",
		"data": {
			"id": "ondine", "nom": "Ondine", "titre": "petite Atlante très curieuse",
			"elfe": {"texture": TEX + "atlante_turquoise.png", "cheveux": [0.35, 0.65, 0.75], "coiffure": "queue", "silhouette": "robe",
				"robe": [0.25, 0.7, 0.7], "cape": [0.9, 0.95, 0.95], "bijou": [0.95, 0.85, 0.6], "yeux": [0.3, 0.7, 0.85], "taille": 0.72},
			"atlante": {"collier": true},
			"teinte": [0.9, 0.96, 1.0],
			"humeur_base": 0.6, "energie_base": 1.0, "affinite_depart": 15.0,
			"traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"pomme": 3.0, "fleur_lune": 2.5, "plume_corbeau": 2.0, "miel": 2.5, "baies": 2.0, "coquillage": 1.0},
			"deteste": {"dent_requin": -1.0},
			"refuse": ["epee", "hache", "trident_marees"],
			"repliques": {
				"accueil": [
					{"t": "Oh ! Oh oh oh ! Tu viens d'en haut ?! Pour de vrai ?! Je m'appelle Ondine ! Est-ce que les nuages sont mouillés ? Est-ce que les arbres parlent ? Est-ce que…", "si": {"visites_max": 1}, "geste": "rire"},
					{"t": "{surnom} ! Raconte-moi encore la surface ! S'il te plaît !", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Super bien ! J'ai vu une tortue par la fenêtre du dôme !", "si": {}, "geste": "rire"},
					{"t": "Un peu triste. Le cristal pâlit, et ma maman dit que c'est grave.", "si": {"pas_trouve": "cristal"}},
				],
				"lui": [
					{"t": "Je suis née sous le dôme, comme tout le monde. Mais moi, un jour, je monterai voir le soleil. Promis.", "si": {}},
					{"t": "Tu sais quoi ? Une baleine passe au-dessus de la cité, parfois. Elle chante. Abyssos dit qu'elle parle au Grand Cristal.", "si": {}},
				],
				"ile": [
					{"t": "Tu as vu l'obélisque devant la Porte ? Il monte jusqu'à la surface ! On dit que sa pointe touche le ciel. C'est vrai ?", "si": {}},
				],
				"rumeur": [
					{"t": "Coralin parle à ses sculptures. Je l'ai entendu. Il leur dit « bonne nuit ».", "si": {}, "geste": "rire"},
					{"t": "La reine a les cheveux tout blancs parce qu'elle a mille ans. Enfin, c'est ce que dit Triton. Ne lui répète pas !", "si": {}},
				],
				"interpelle": [
					{"t": "Hé ! Hé ! Toi, d'en haut !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Viens jouer !", "si": {"visites_min": 1}},
				],
			},
			"questions": [
				{"id": "pomme", "si": {"visites_min": 1}, "texte": "C'est quoi, une pomme ? Coralin dit que c'est un oursin rouge qui pousse dans les arbres.",
					"reponses": [
						{"label": "Un fruit sucré et croquant.", "valeur": "fruit", "affinite": 4.0, "humeur": 0.2, "t": "Croquant ! Comme un coquillage ? Il faut que j'en goûte une. Tu m'en apporteras ?"},
						{"label": "Coralin a raison.", "valeur": "oursin", "affinite": 2.0, "humeur": 0.25, "t": "Je le savais ! … Attends. Tu te moques de moi ?"},
					]},
			],
		},
	},
	{
		"coin": "archives",
		"data": {
			"id": "abyssos", "nom": "Abyssos", "titre": "archiviste de la cité",
			"elfe": {"texture": TEX + "atlante_abysse.png", "cheveux": [0.92, 0.94, 0.96], "coiffure": "long", "silhouette": "robe",
				"robe": [0.22, 0.24, 0.45], "cape": [0.45, 0.55, 0.7], "bijou": [0.85, 0.85, 0.9], "yeux": [0.55, 0.65, 0.8], "baton": true},
			"atlante": {"nageoires": true},
			"teinte": [0.84, 0.92, 0.98],
			"humeur_base": 0.2, "energie_base": 0.4, "affinite_depart": 12.0,
			"traits": {"bavard": 0.95, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"perle": 2.0, "ecaille_naga": 3.0, "fragment_amulette": 2.5, "couronne_nuees": 2.0, "plume_ventaile": 2.0},
			"deteste": {},
			"refuse": ["epee", "hache"],
			"sujets_speciaux": [
				{"id": "perles", "label": "Les trois Perles de Lumière ?", "si": {}},
				{"id": "rois_ciel", "label": "Les Rois-Ciel ?", "si": {"a_trouve": "orage"}},
			],
			"repliques": {
				"accueil": [
					{"t": "Hmm ? Un visiteur… de la surface ? Attends, que je trouve une plume. Il faut que je note ça. « Jour 365 214 : un humain. »", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom}. J'ai écrit trois rouleaux sur toi. Tu veux les lire ? Non ? Personne ne veut jamais.", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "L'encre de seiche sèche mal, sous le dôme. Mais je ne me plains pas. Enfin, si. Un peu.", "si": {}},
				],
				"lui": [
					{"t": "J'archive tout : les marées, les naissances, les chansons des baleines… Et les erreurs de Coralin. Ce sont les rouleaux les plus épais.", "si": {}, "geste": "rire"},
					{"t": "Sur cette fresque, regarde : la cité sous son dôme, la baleine, et les trois perles. L'histoire tient en une image. Moi, il m'a fallu dix mille rouleaux.", "si": {"sujet_min": ["lui", 1]}},
				],
				"perles": [
					{"t": "La première, la Perle du Jardin, est l'âge de la vie : elle dort dans le grand bénitier du récif de corail, au nord-est. Approche-toi et ouvre-le doucement ; les requins le gardent.", "si": {}},
					{"t": "La deuxième, la Perle de l'Épave, est l'âge des hommes : des marins l'ont volée, et leur navire, « La Sirène Noire », a coulé à l'ouest. Elle est restée dans le coffre du capitaine.", "si": {}},
					{"t": "La troisième, la Perle de la Fosse, est l'âge des profondeurs : sur un autel, au fond de la Fosse aux Méduses, au nord de la cité. Les méduses brûlent la peau : passe entre elles, lentement.", "si": {}},
				],
				"rois_ciel": [
					{"t": "Les Rois-Ciel ! Ils descendaient nous voir avec des masques comme le tien, avant le déluge. Leur château volait au-dessus de nous ; leurs cascades nous apportaient l'eau douce. Tu as vaincu Sire Orage ? Alors le ciel et la mer sont de nouveau amis.", "si": {}},
				],
				"ile": [
					{"t": "Le dôme fait quatre-vingt-douze pas de large. Je les ai comptés. Deux fois. La deuxième fois, j'en ai trouvé quatre-vingt-treize.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "La reine ne dort plus. Elle regarde le cristal toute la nuit. Les perles, {surnom}… les perles.", "si": {"pas_trouve": "cristal"}},
					{"t": "Ondine a dessiné un « arbre » d'après ta description. On dirait un poulpe en colère.", "si": {}, "geste": "rire"},
				],
				"interpelle": [
					{"t": "Toi… viens que je t'archive.", "si": {"visites_max": 0}},
					{"t": "{surnom} ! J'ai une question pour mes rouleaux !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "porte",
		"data": {
			"id": "triton", "nom": "Triton", "titre": "garde de la Porte des Marées",
			"elfe": {"texture": TEX + "atlante_turquoise.png", "cheveux": [0.15, 0.25, 0.3], "coiffure": "court", "silhouette": "tunique",
				"robe": [0.14, 0.38, 0.45], "cape": [0.6, 0.7, 0.75], "bijou": [0.8, 0.75, 0.55], "yeux": [0.3, 0.6, 0.7]},
			"atlante": {"trident": true, "nageoires": true},
			"teinte": [0.86, 0.94, 1.0],
			"humeur_base": 0.3, "energie_base": 0.8, "affinite_depart": 10.0,
			"traits": {"bavard": 0.5, "humour": 0.4, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"dent_requin": 2.0, "ragout_nain": 2.5, "biere_naine": 2.0, "maquereau": 1.5},
			"deteste": {},
			"refuse": [],
			"repliques": {
				"accueil": [
					{"t": "HALTE ! Qui va l… Un humain ?! Un vrai ?! Trois cents ans que je garde cette porte, et personne n'est jamais venu ! Bienvenue en Atlantide ! Euh… Je veux dire : bienvenue. Gardez votre calme.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom}. La Porte des Marées t'est ouverte. Comme d'habitude. Ça me fait toujours plaisir.", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Vigilant. Toujours vigilant. Même quand il ne se passe rien. Surtout quand il ne se passe rien.", "si": {}},
				],
				"lui": [
					{"t": "Je garde la porte. Contre les requins, surtout. Ils n'entrent pas sous le dôme — il n'y a pas d'eau — mais ils essaient. Bêtes, les requins.", "si": {}},
					{"t": "Un conseil, voyageur : quand un requin fonce sur toi, frappe-le au dernier moment. Et les méduses : on ne les frôle pas. Jamais.", "si": {"sujet_min": ["lui", 1]}},
				],
				"ile": [
					{"t": "Dans le dôme, on respire. Dehors, il faut un masque, ou retenir son souffle. Toi, tu as le masque des Rois-Ciel. Tu as de la chance.", "si": {}},
					{"t": "L'obélisque, derrière moi, monte jusqu'à la surface. Sa pointe s'allume la nuit : c'est notre phare.", "si": {}},
				],
				"rumeur": [
					{"t": "On raconte qu'une baleine tourne autour de la cité. Je ne l'ai jamais vue. Je suis de garde.", "si": {}},
				],
				"interpelle": [
					{"t": "Halte ! … Ah, c'est toi. Passe.", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "marche",
		"data": {
			"id": "maree", "nom": "Marée", "titre": "marchande d'algues",
			"elfe": {"texture": TEX + "atlante_corail.png", "cheveux": [0.45, 0.2, 0.18], "coiffure": "tresse", "silhouette": "robe",
				"robe": [0.55, 0.28, 0.22], "cape": [0.75, 0.85, 0.7], "bijou": [0.9, 0.8, 0.5], "yeux": [0.4, 0.55, 0.45]},
			"atlante": {"collier": true},
			"teinte": [0.9, 0.95, 1.0],
			"humeur_base": 0.4, "energie_base": 0.8, "affinite_depart": 10.0,
			"traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2, "radin": 0.6},
			"aime": {"sardine": 1.5, "maquereau": 1.5, "dorade": 2.0, "bar": 2.0, "merou": 3.0, "pomme": 2.0},
			"deteste": {"galette_algue": -0.5},
			"refuse": [],
			"boutique": {"vend": {"galette_algue": 6}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 6, "bar": 6, "merou": 15, "coquillage": 3, "dent_requin": 12, "perle": 20}},
			"repliques": {
				"accueil": [
					{"t": "Approchez, approchez ! Galettes d'algues ! Toutes fraîches ! Enfin, fraîches… mouillées. Je suis Marée. Et vous, vous êtes… sec ! Comme c'est exotique !", "si": {"visites_max": 1}, "geste": "rire"},
					{"t": "{surnom} ! Une galette ? Deux ? Elles rendent deux cœurs, et le sourire. Enfin, deux cœurs.", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Les affaires marchent ! Un client de la surface, c'est le meilleur des signes.", "si": {}, "geste": "rire"},
				],
				"lui": [
					{"t": "Je cultive les algues dans les jardins du dôme, je les sèche sous le cristal, et je les presse en galettes. Recette de ma grand-mère. Elle avait neuf cents ans.", "si": {}},
					{"t": "Je rachète le poisson de la surface ! Ici, on ne pêche pas : on parle aux poissons. Mais un maquereau grillé… mmh.", "si": {"sujet_min": ["lui", 1]}},
				],
				"ile": [
					{"t": "Les jardins d'algues sont derrière les maisons, au bord du dôme. Ils boivent la lumière du cristal.", "si": {}},
				],
				"rumeur": [
					{"t": "Abyssos m'a demandé d'archiver mes recettes. J'ai refusé. Les secrets, ça ne s'écrit pas.", "si": {}},
				],
				"boutique": [
					{"t": "Galettes d'algues (deux cœurs !). Et je rachète poissons, coquillages, perles, dents de requin. Vous avez {pieces} pièces.", "si": {}},
				],
				"interpelle": [
					{"t": "Galettes ! Galettes d'algues !", "si": {}},
				],
			},
		},
	},
]


const PASSANTS := [
	["Thalassa", "robe", "long", [0.75, 0.88, 0.92], "atlante_nacre.png", "tisseuse d'algues"],
	["Pélagos", "tunique", "court", [0.2, 0.3, 0.35], "atlante_turquoise.png", "gardien des jardins"],
	["Nausicaa", "robe", "tresse", [0.95, 0.75, 0.55], "atlante_corail.png", "chanteuse des marées"],
	["Glaucos", "tunique", "queue", [0.6, 0.75, 0.8], "atlante_abysse.png", "souffleur de nacre"],
	["Ianthé", "robe", "chignon", [0.4, 0.7, 0.75], "atlante_turquoise.png", "danseuse du canal"],
	["Protée", "tunique", "court", [0.88, 0.88, 0.85], "atlante_nacre.png", "conteur des courants"],
]

const PASSANT_LINES := {
	"accueil": [
		{"t": "Un humain ! Bienvenue sous le dôme, voyageur.", "si": {"visites_max": 1}, "geste": "salut"},
		{"t": "Te revoilà ! Toute la cité parle de toi.", "si": {"visites_min": 2}},
	],
	"humeur": [
		{"t": "Bien, merci. La lumière ondule joliment, aujourd'hui.", "si": {}},
		{"t": "Un peu inquiet. Le cristal pâlit…", "si": {"pas_trouve": "cristal"}},
		{"t": "Merveilleusement ! Le cristal chante de nouveau !", "si": {"a_trouve": "cristal"}, "geste": "rire"},
	],
	"lui": [
		{"t": "Moi ? Je suis {titre}. Un métier tranquille, sous la mer. Tout est tranquille, sous la mer.", "si": {}},
	],
	"ile": [
		{"t": "Tu as vu le canal ? Les enfants y font flotter des bateaux de nacre.", "si": {}},
		{"t": "Ne sors pas sans ton masque, hein. Dehors, c'est la mer. Partout.", "si": {}},
	],
	"rumeur": [
		{"t": "On dit qu'un humain a rapporté une Perle de Lumière. C'est toi ?", "si": {"a_trouve": "perles_1"}},
		{"t": "La reine attend les trois Perles. Le cristal faiblit chaque nuit.", "si": {"pas_trouve": "cristal"}},
	],
}


## Fiche d'un Atlante de passage (n = rang dans PASSANTS).
static func passant(n: int) -> Dictionary:
	var p: Array = PASSANTS[n % PASSANTS.size()]
	var robe_cols := [[0.18, 0.55, 0.6], [0.8, 0.85, 0.88], [0.6, 0.3, 0.3], [0.25, 0.3, 0.55], [0.3, 0.6, 0.5]]
	var lines: Dictionary = PASSANT_LINES.duplicate(true)
	for e in lines["lui"]:
		e["t"] = str(e["t"]).replace("{titre}", str(p[5]))
	var d := {
		"id": "atlante_%d" % n, "nom": str(p[0]), "titre": str(p[5]),
		"elfe": {"texture": TEX + str(p[4]), "cheveux": p[3], "coiffure": str(p[2]), "silhouette": str(p[1]),
			"robe": robe_cols[n % robe_cols.size()], "cape": [0.9, 0.95, 0.96], "bijou": [0.9, 0.8, 0.55], "yeux": [0.3, 0.65 + 0.05 * (n % 3), 0.75]},
		"atlante": {"collier": n % 2 == 0, "nageoires": n % 3 != 0},
		"teinte": [0.88, 0.95, 1.0],
		"humeur_base": 0.3, "energie_base": 0.7, "affinite_depart": 10.0,
		"traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
		"aime": {"pomme": 1.5, "perle": 1.5, "coquillage": 1.0, "fleur_lune": 2.0},
		"deteste": {},
		"refuse": ["epee", "hache"],
		"repliques": lines,
	}
	return complete(d)

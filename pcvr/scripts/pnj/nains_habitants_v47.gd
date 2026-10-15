extends RefCounted
## V47 : les nains de la Montagne de Feu. Cinq habitants sur la terrasse de Forgefer (le garde,
## le forgeron, la cuisinière, le mineur, la chevrière), quatre dans la cité sous la montagne
## (le roi, la tavernière, le vieux runiste, le joaillier) et des nains de passage.
## Même cerveau que les autres habitants (pnj_brain_v31.gd) ; chacun a sa petite quête.
## Apparence ("nain") : texture, barbe (couleur), style_barbe (large, tresse, fourche), coiffe
## (casque, capuche, bonnet, couronne, chauve), tunique/cape/metal (couleurs), tablier, outil, taille.

const TEX := "res://assets/textures/nains/"

const COMMON := {
	"cadeau_aime": [
		{"t": "Pour moi ? {dernier_cadeau}… Hmpf. C'est… c'est très bien. Merci, {surnom}.", "si": {}, "geste": "rire"},
		{"t": "Ho ho ! {dernier_cadeau} ! Tu as l'œil, pour un grand.", "si": {}},
	],
	"cadeau_neutre": [
		{"t": "Hmm. Ça ne se forge pas, ça ne se boit pas… mais merci.", "si": {}},
		{"t": "Un cadeau d'un grand ! Je le mettrai sur l'étagère.", "si": {}},
	],
	"cadeau_deteste": [
		{"t": "Garde ça. Vraiment. Garde-le.", "si": {}, "geste": "colere"},
	],
	"cadeau_refus": [
		{"t": "Une arme qui n'est pas forgée ici ? Non merci.", "si": {}},
	],
	"souvenir": [
		{"t": "Un nain n'oublie jamais un visage. Ni une dette. Ni une insulte.", "si": {}},
	],
	"au_revoir": [
		{"t": "Que ta forge ne s'éteigne jamais, {surnom}.", "si": {}, "geste": "salut"},
		{"t": "Va. Et garde ta barbe au sec. … Ah, tu n'en as pas. Dommage.", "si": {}, "geste": "rire"},
		{"t": "Pierre et feu te gardent.", "si": {}},
	],
	"frappe": [
		{"t": "Tu frappes un nain ? Sur SA montagne ?!", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Recommence, et c'est mon marteau qui te répond.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"quete_inconnue": [
		{"t": "Je ne t'ai rien demandé. Un nain demande rarement.", "si": {}},
	],
	"blague": [
		{"t": "Pourquoi les nains n'ont pas peur du noir ? Parce que le noir a peur des nains. Ho ho ho !", "si": {}, "geste": "rire"},
		{"t": "Un elfe entre dans une mine. … C'est tout. Il est toujours en train de se cogner la tête. HO HO !", "si": {}, "geste": "rire"},
		{"t": "Combien de nains faut-il pour changer une torche ? Aucun : on creuse jusqu'à la lave, c'est plus clair.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, mais ne touche pas avec les doigts gras. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Fermé. Pour toi, c'est fermé.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "{objet}, pour {prix} pièces. Du travail nain, ça dure mille ans.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "{prix} pièces. Tu en as {pieces}. Un nain ne fait pas crédit.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un. Un seul suffit, s'il est nain.", "si": {}}],
	"achat_plein": [{"t": "Ton sac déborde, {surnom}. Range-le comme une mine : bien étayé.", "si": {}}],
	"vente": [{"t": "{objet} ? Je t'en donne {prix} pièces. Pas une de plus.", "si": {}}],
	"vente_lot": [{"t": "Tout ? {prix} pièces le lot. Et je suis généreux.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Grmbl… Bon. Pour toi. Mais tu ne le dis à personne.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander avec un nain ? Ho ho ! Non.", "si": {}, "geste": "rire"}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui. Ma barbe s'en souvient.", "si": {}}],
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
		"joie": ["Ho ho !", "Par ma barbe !", "Ha !", "Bien, bien !"],
		"neutre": ["Hmm.", "Bon.", "Écoute, le grand…", "Grmbl."],
		"triste": ["Hélas…", "Pff…", "Mouais.", "Ah…"],
		"colere": ["Grrr.", "Ça suffit.", "Dehors.", "Hmpf !"],
	},
	"tics": ["Par le marteau d'Ancêtre-Pierre !", "Pierre et feu.", "Ça, c'est du solide.", "Par ma barbe."],
	"humeur_mots": [[0.6, "jovial"], [0.25, "bourru mais content"], [-0.25, "grognon"], [-0.6, "furieux"], [-2.0, "de pierre"]],
	"surnoms": [[0, "le grand"], [25, "l'ami"], [50, "ami des nains"], [75, "frère de forge"], [95, "nain d'honneur"]],
}


## Les cinq habitants de la terrasse. "coin" = leur poste (voir nains_v46.gd).
const DEHORS := [
	{
		"coin": "porte",
		"data": {
			"id": "bramm", "nom": "Bramm Poing-de-Roc", "titre": "garde de la Grande Porte",
			"nain": {"texture": TEX + "nain_suie.png", "barbe": [0.18, 0.14, 0.12], "style_barbe": "fourche", "coiffe": "casque",
				"tunique": [0.22, 0.24, 0.3], "metal": [0.62, 0.64, 0.7], "outil": "lance", "cape": [0.45, 0.12, 0.1], "taille": 0.8},
			"teinte": [0.95, 0.72, 0.6],
			"humeur_base": -0.05, "energie_base": 0.9, "affinite_depart": 0.0,
			"traits": {"bavard": 0.3, "humour": 0.2, "curiosite": 0.3, "susceptible": 0.7, "rancunier": 0.8, "radin": 0.5},
			"aime": {"biere_naine": 3.0, "ragout_nain": 2.0, "rune_golem": 1.0, "piece_or": 1.5, "rubis": 2.0},
			"deteste": {"fleur_lune": -1.5, "coquillage": -0.5},
			"refuse": [],
			"quete": {"objet": "rune_golem", "nombre": 2, "recompense": [["piece", 30]], "affinite": 25.0,
				"sujet": "Les runes des golems…", "note": "m'a demandé deux runes de golem", "souvenir": "Tu as rapporté deux runes de golem. La porte de Forgefer s'est ouverte pour toi."},
			"repliques": {
				"accueil": [
					{"t": "Halte ! Un grand. Sur NOTRE plage. Bramm Poing-de-Roc, garde de la Grande Porte. Personne n'entre à Forgefer sans y être invité.", "si": {"visites_max": 1}, "geste": "colere"},
					{"t": "Encore toi. Hmpf. Tu tiens debout, c'est déjà ça.", "si": {"visites_min": 2, "quete": "demandee"}},
					{"t": "{surnom}. La porte t'est ouverte. Ne la salis pas.", "si": {"visites_min": 2, "quete": "finie"}, "geste": "salut"},
					{"t": "Toi. Qu'est-ce que tu veux ?", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Je garde une porte. Elle ne bouge pas. Moi non plus. Tout va bien.", "si": {}},
					{"t": "Mal. Les golems des hauteurs se sont réveillés. Ils descendent la nuit. Les pierres grondent.", "si": {"quete": ""}},
				],
				"lui": [
					{"t": "Cent quatre-vingts ans de garde. Pas une fois la porte n'a été forcée. Pas une.", "si": {}},
					{"t": "Tu veux entrer ? Prouve ta valeur. Les golems des hauteurs, là-haut près du cratère, se sont réveillés. Rapporte-moi {manque} de leurs runes, et la Grande Porte s'ouvrira pour toi.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Toujours {manque} runes de golem. Monte vers le cratère : ils gardent les pentes noires. Frappe quand ils lèvent leurs gros bras… après, pas avant.", "si": {"quete": "demandee"}},
					{"t": "Tu as abattu des golems. Pour un grand, c'est… correct. Très correct. Hmpf.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "La Montagne de Feu. Mille ans que nous creusons dessous. Elle gronde, elle fume, elle nous chauffe. C'est notre mère.", "si": {}},
					{"t": "Les récifs et la cendre nous cachent. Ceux qui n'ont pas la carte tournent en rond et repartent. C'est bien comme ça.", "si": {}},
					{"t": "Là-haut, près du cratère, la lave crache des élémentaires de magma. Ne t'en approche pas sans arme.", "si": {}},
				],
				"rumeur": [
					{"t": "Borin dit qu'il est le meilleur forgeron de la montagne. Borin dit beaucoup de choses.", "si": {}},
					{"t": "Grimli a encore perdu une galerie. Perdu. Une galerie. Il faut le faire.", "si": {}, "geste": "rire"},
					{"t": "Une reine des fées t'a donné la carte ? Les fées… Hmpf. Au moins elles savent choisir.", "si": {"a_trouve": "reine"}},
				],
				"quete_manque": [{"t": "Il me faut {manque} runes. Pas une de moins. Une porte, ça ne s'ouvre pas à moitié.", "si": {}}],
				"quete_fin": [{"t": "Deux runes de golem. Bien. TRÈS bien. … OUVREZ LA GRANDE PORTE ! Le grand est des nôtres ! Tiens, trente pièces. Et ne dis pas que je suis gentil.", "si": {}, "geste": "salut", "humeur": 0.3}],
				"interpelle": [
					{"t": "Halte-là, le grand !", "si": {"visites_max": 0}},
					{"t": "Hmpf. {surnom}.", "si": {"visites_min": 1}},
				],
			},
			"questions": [
				{"id": "valeur", "si": {"visites_min": 2}, "texte": "Dis-moi, le grand… qu'est-ce qui fait un bon guerrier ?",
					"reponses": [
						{"label": "Ne jamais reculer.", "valeur": "reculer", "affinite": 4.0, "humeur": 0.15, "t": "Ha ! Ça, c'est une réponse de nain."},
						{"label": "Savoir quand fuir.", "valeur": "fuir", "affinite": 1.0, "humeur": 0.0, "t": "… Hmpf. C'est vrai, mais ne le répète pas."},
						{"label": "Une bonne bière avant le combat.", "valeur": "biere", "affinite": 3.0, "humeur": 0.2, "t": "HO HO ! Toi, tu iras loin."},
					]},
			],
		},
	},
	{
		"coin": "forge",
		"data": {
			"id": "borin", "nom": "Borin Barbe-de-Fer", "titre": "maître forgeron",
			"nain": {"texture": TEX + "nain_braise.png", "barbe": [0.62, 0.3, 0.12], "style_barbe": "tresse", "coiffe": "chauve",
				"tunique": [0.42, 0.2, 0.12], "metal": [0.55, 0.55, 0.58], "tablier": true, "outil": "marteau", "taille": 0.82},
			"teinte": [1.0, 0.7, 0.55],
			"humeur_base": 0.25, "energie_base": 0.9, "affinite_depart": 8.0,
			"traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.3, "radin": 0.6},
			"aime": {"minerai_fer": 2.0, "obsidienne": 1.5, "coeur_magma": 2.5, "biere_naine": 2.0, "rubis": 1.5},
			"deteste": {"epee_bois": -1.0, "fleur_lune": -0.5},
			"refuse": [],
			"quete": {"objet": "minerai_fer", "nombre": 5, "recompense": [["epee_naine", 1]], "affinite": 20.0,
				"sujet": "Ton minerai de fer…", "note": "m'a demandé du minerai de fer", "souvenir": "Avec ton minerai, je t'ai forgé une épée naine. Ma meilleure de l'année."},
			"boutique": {"vend": {"epee": 120}, "achete": {"minerai_fer": 5, "obsidienne": 7, "coeur_magma": 12, "caillou": 1, "buche": 2}},
			"repliques": {
				"accueil": [
					{"t": "Un grand ! Approche, approche, mais pas trop près de l'enclume. Borin Barbe-de-Fer, maître forgeron. Le meilleur de la montagne. Demande à n'importe qui. Enfin, demande-moi.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom} ! Tu entends ? DING ! DING ! C'est la musique de Forgefer.", "si": {"visites_min": 2}, "geste": "rire"},
					{"t": "Tu portes mon épée ! Elle te va bien. Enfin, toi, tu lui vas bien.", "si": {"tient": "epee_naine"}, "geste": "rire"},
					{"t": "Une épée d'acier d'Octave ? Pas mal… pour un grand. Je ferais mieux. Beaucoup mieux.", "si": {"tient": "epee", "visites_min": 2}},
				],
				"humeur": [
					{"t": "Très bien ! Le feu tire bien, l'acier chante. Que demander de plus ? Une bière. Voilà.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Mon soufflet a un trou. Mon apprenti a un trou dans la tête. Tout fuit, aujourd'hui.", "si": {"humeur_max": 0.2}},
				],
				"lui": [
					{"t": "Trois cents ans à frapper le fer. J'ai forgé la hache du roi, les portes de la cité, et la cuillère de Dagna. Elle dit que c'est mon chef-d'œuvre. Hmpf.", "si": {}},
					{"t": "Le minerai de la montagne est le meilleur du monde. Rouge comme la rouille, lourd comme un serment.", "si": {}},
					{"t": "Tu veux une vraie arme, {surnom} ? Rapporte-moi {manque} minerais de fer. On en trouve sur les pentes du volcan, là où la roche est rouge. Je t'en forgerai une épée naine. Une VRAIE.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} minerais, {surnom} ? Les pierres veinées de rouille, sur les flancs de la montagne.", "si": {"quete": "demandee"}},
					{"t": "Ton épée naine ! Prends-en soin : graisse la lame, et ne la prête jamais à un elfe.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Le volcan nous donne tout : le fer, le feu, et la chaleur pour l'hiver. Il nous prend parfois un toit ou deux. C'est le prix.", "si": {}},
					{"t": "Les deux forges de la terrasse, c'est pour le gros travail. La Forge Royale, sous la montagne, c'est pour les chefs-d'œuvre.", "si": {}},
				],
				"rumeur": [
					{"t": "Dagna met trop de champignons dans son ragoût. Je le dis, et j'en reprends trois fois.", "si": {}, "geste": "rire"},
					{"t": "Bramm n'a pas souri depuis cent ans. La dernière fois, c'était pour un tonneau de bière tombé sur un elfe.", "si": {}, "geste": "rire"},
					{"t": "On dit qu'au cœur de la montagne dort une pierre qui bat comme un cœur. Nori sait. Nori sait toujours tout. C'est agaçant.", "si": {}},
				],
				"quete_manque": [{"t": "Il me manque encore {manque} minerais. Pas de fer, pas d'épée. C'est la loi de l'enclume.", "si": {}}],
				"quete_fin": [{"t": "Du beau minerai rouge ! Attends… (DING ! DING ! DING ! PSHHHH !) Voilà. Une épée naine. Lame large, garde d'or, un rubis au pommeau. Elle coupe le fer comme du beurre. Ne la casse pas.", "si": {}, "geste": "rire", "humeur": 0.4}],
				"boutique": [
					{"t": "J'achète le minerai, l'obsidienne et les cœurs de magma. Et je vends de l'acier. Tu as {pieces} pièces.", "si": {}},
				],
				"interpelle": [
					{"t": "Hé, le grand ! Tu as besoin d'une lame ?", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Viens voir l'acier !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "cuisine",
		"data": {
			"id": "dagna", "nom": "Dagna Soufflebraise", "titre": "cuisinière de la terrasse",
			"nain": {"texture": TEX + "nain_mousse.png", "barbe": [0.85, 0.55, 0.25], "style_barbe": "tresse", "coiffe": "bonnet",
				"tunique": [0.3, 0.38, 0.2], "metal": [0.8, 0.62, 0.3], "tablier": true, "outil": "louche", "taille": 0.76},
			"teinte": [1.0, 0.76, 0.62],
			"humeur_base": 0.45, "energie_base": 0.85, "affinite_depart": 12.0,
			"traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.2, "radin": 0.2},
			"aime": {"champignon_braise": 2.5, "fromage_chevre": 2.0, "miel": 2.0, "sardine": 1.0, "pomme": 1.0},
			"deteste": {"caillou": -0.5},
			"refuse": [],
			"quete": {"objet": "champignon_braise", "nombre": 4, "recompense": [["ragout_nain", 3]], "affinite": 15.0,
				"sujet": "Tes champignons de braise…", "note": "m'a demandé des champignons de braise", "souvenir": "Tes champignons de braise ont fait le ragoût du siècle."},
			"boutique": {"vend": {"ragout_nain": 12, "biere_naine": 6}, "achete": {"champignon_braise": 4, "fromage_chevre": 5, "miel": 7, "pomme": 2, "champignon": 2}},
			"repliques": {
				"accueil": [
					{"t": "Oh ! Un grand ! Tu as faim. Tout le monde a faim. Dagna Soufflebraise, la cuisinière. Assieds-toi, mange, et ne dis pas que c'est trop chaud.", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.1},
					{"t": "{surnom} ! Le ragoût mijote depuis trois jours. Il est parfait. Ou presque.", "si": {"visites_min": 2}, "geste": "rire"},
					{"t": "Tu es tout pâle ! Mange. Non, pas de discussion : MANGE.", "si": {"vie_basse": true}},
				],
				"humeur": [
					{"t": "À merveille ! Le chaudron chante, les nains mangent, personne ne s'est brûlé. Enfin, presque personne.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Borin a encore volé une louche de ragoût avant midi. Je l'ai vu. Je vois tout.", "si": {}},
				],
				"lui": [
					{"t": "Je nourris toute la terrasse. Cent nains, cent estomacs, cent avis sur le sel.", "si": {}},
					{"t": "Mon secret ? Le champignon de braise. Il pousse dans la cendre chaude, près des fumerolles. Ça pique, ça réchauffe, ça soigne.", "si": {}},
					{"t": "Tu veux m'aider, {surnom} ? Il me faut {manque} champignons de braise. Ils poussent dans la cendre, près des fumerolles qui fument sur les pentes. Je te ferai du ragoût !", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} champignons de braise, {surnom} ! Cherche les petites lueurs rouges dans la cendre, près des fumerolles.", "si": {"quete": "demandee"}},
					{"t": "Grâce à tes champignons, même Bramm a souri. Une demi-seconde. J'ai compté.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Les chèvres de Hilda broutent la cendre. Je ne sais pas comment. Leur fromage est le meilleur du monde.", "si": {}},
					{"t": "Ne mange jamais un champignon blanc de la montagne. Les rouges, oui. Les blancs, tu vois des dragons pendant une semaine.", "si": {}, "geste": "rire"},
				],
				"rumeur": [
					{"t": "Hilda parle à ses corbeaux. Et ses corbeaux lui répondent. Je l'ai entendu !", "si": {}},
					{"t": "Le roi a encore commandé un tonneau de bière à Ulfa. Pour « goûter ». Trois fois cette semaine.", "si": {}, "geste": "rire"},
					{"t": "Grimli dort dans sa mine. Il dit que c'est plus calme. C'est surtout que sa femme ronfle.", "si": {}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Il m'en faut encore {manque}, {surnom}. Mon chaudron attend.", "si": {}}],
				"quete_fin": [{"t": "Des champignons de braise ! Ils brillent encore ! Tiens : trois bols de ragoût, tout chauds. Quatre cœurs chacun. Souffle dessus.", "si": {}, "geste": "rire", "humeur": 0.3}],
				"boutique": [
					{"t": "Ragoût aux champignons de braise et bière de Forgefer ! Et je rachète tout ce qui se mange. Tu as {pieces} pièces.", "si": {}},
				],
				"interpelle": [
					{"t": "Hé ! Tu as faim, le grand ?", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Un bol de ragoût ?", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "mine",
		"data": {
			"id": "grimli", "nom": "Grimli Pic-Rouillé", "titre": "mineur",
			"nain": {"texture": TEX + "nain_suie.png", "barbe": [0.4, 0.38, 0.36], "style_barbe": "large", "coiffe": "casque",
				"tunique": [0.35, 0.3, 0.24], "metal": [0.5, 0.46, 0.4], "outil": "pioche", "taille": 0.78},
			"teinte": [0.9, 0.68, 0.56],
			"humeur_base": 0.1, "energie_base": 0.6, "affinite_depart": 6.0,
			"traits": {"bavard": 0.5, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3, "radin": 0.5},
			"aime": {"coeur_magma": 2.5, "biere_naine": 2.0, "minerai_fer": 1.0, "rubis": 2.0},
			"deteste": {"fleur_lune": -0.5},
			"refuse": [],
			"quete": {"objet": "coeur_magma", "nombre": 3, "recompense": [["piece", 60], ["rubis", 1]], "affinite": 18.0,
				"sujet": "Les cœurs de magma…", "note": "m'a demandé des cœurs de magma", "souvenir": "Tes cœurs de magma éclairent ma galerie. Elle ne se perd plus."},
			"repliques": {
				"accueil": [
					{"t": "Hein ? Quoi ? Un grand ! Pardon, je croyais que c'était un éboulement. Grimli Pic-Rouillé, mineur. Le plus vieux mineur de la plus vieille mine.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom} ! Tu viens creuser ? Non ? Dommage.", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Fatigué. Quarante pieds de galerie hier. Et elle s'est effondrée. Bon, trente-neuf.", "si": {"energie_max": 0.5}},
					{"t": "Bien ! J'ai trouvé une veine d'argent. Je l'ai reperdue. Mais je l'ai trouvée !", "si": {}, "geste": "rire"},
				],
				"lui": [
					{"t": "J'ai creusé sous toute la montagne. Il y a des galeries que même le roi ne connaît pas. Moi non plus, d'ailleurs. Je les ai oubliées.", "si": {}},
					{"t": "Mes lanternes s'éteignent tout le temps, là-dessous. Il me faudrait {manque} cœurs de magma : ça brille cent ans. Les élémentaires de magma, près du cratère, en ont un dans le ventre… Tu vois ce que je veux dire.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Toujours {manque} cœurs de magma à trouver, {surnom}. Les élémentaires rôdent au bord du cratère. Ils brûlent : frappe vite, recule vite.", "si": {"quete": "demandee"}},
					{"t": "Grâce à tes cœurs de magma, ma galerie est éclairée comme une salle de fête. J'ai retrouvé ma veine d'argent. Et deux pioches. Et un nain.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Sous nos pieds, la montagne est creuse comme un fromage. Des galeries, des puits, des salles. Et tout au fond, la lave.", "si": {}},
					{"t": "Tu vois les rochers rouges, sur les pentes ? C'est du minerai de fer. Borin en veut toujours.", "si": {}},
				],
				"rumeur": [
					{"t": "Les golems des hauteurs… ce sont les anciens gardiens de la montagne. Ils se sont réveillés quand le volcan a grondé. Nori dit que quelqu'un les a réveillés.", "si": {}},
					{"t": "J'ai entendu un cœur battre, au fond d'une galerie. Boum… boum… Ne le dis pas au roi.", "si": {}},
				],
				"quete_manque": [{"t": "Encore {manque} cœurs de magma, {surnom}. Mes lanternes clignotent.", "si": {}}],
				"quete_fin": [{"t": "Des cœurs de magma ! Ils sont encore chauds ! Tiens : soixante pièces, et un rubis que j'ai trouvé… je ne sais plus où. Merci, {surnom} !", "si": {}, "geste": "rire", "humeur": 0.3}],
				"interpelle": [
					{"t": "Attention à la tête, le grand ! … Ah non, c'est toi qui es grand.", "si": {"visites_max": 0}, "geste": "rire"},
					{"t": "{surnom} ! Tu creuses avec moi ?", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "chevres",
		"data": {
			"id": "hilda", "nom": "Hilda Plume-de-Suie", "titre": "chevrière et dresseuse de corbeaux",
			"nain": {"texture": TEX + "nain_mousse.png", "barbe": [0.15, 0.12, 0.12], "style_barbe": "tresse", "coiffe": "capuche",
				"tunique": [0.2, 0.22, 0.26], "metal": [0.6, 0.6, 0.62], "outil": "baton", "taille": 0.77},
			"teinte": [0.98, 0.76, 0.64],
			"humeur_base": 0.2, "energie_base": 0.75, "affinite_depart": 8.0,
			"traits": {"bavard": 0.5, "humour": 0.55, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.3, "radin": 0.3},
			"aime": {"plume_corbeau": 2.0, "pomme": 2.0, "baies": 1.5, "sardine": 1.5, "fromage_chevre": 0.5},
			"deteste": {"epee": -0.5},
			"refuse": [],
			"quete": {"objet": "plume_corbeau", "nombre": 4, "recompense": [["fromage_chevre", 3], ["piece", 20]], "affinite": 15.0,
				"sujet": "Les plumes de corbeau…", "note": "m'a demandé des plumes de corbeau", "souvenir": "Avec tes plumes, j'ai fait un manteau pour Croâ, mon plus vieux corbeau."},
			"boutique": {"vend": {"fromage_chevre": 7}, "achete": {"plume_corbeau": 3, "pomme": 2, "baies": 2, "sardine": 3}},
			"repliques": {
				"accueil": [
					{"t": "Chut ! Tu vas faire peur aux chèvres. … Bon, elles n'ont peur de rien. Hilda Plume-de-Suie. Je garde les chèvres des cendres et je parle aux corbeaux.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom}. Croâ t'a vu arriver. Il m'a prévenue.", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Bien. Les chèvres ont mangé un tonneau. Vide, heureusement.", "si": {}, "geste": "rire"},
					{"t": "Inquiète. Une chèvre est montée trop haut, vers les golems. Elle est redescendue. En courant.", "si": {}},
				],
				"lui": [
					{"t": "Mes chèvres grimpent partout : sur les rochers, sur les toits, sur Bramm. Leur lait fait le meilleur fromage de la montagne.", "si": {}},
					{"t": "Les corbeaux des cendres portent nos messages au roi, sous la montagne. Ils perdent des plumes partout.", "si": {}},
					{"t": "Tu veux m'aider ? Ramasse {manque} plumes de corbeau. Les corbeaux tournent autour du sommet et se posent sur les rochers ; ils en perdent tout le temps. Je te paierai en fromage.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} plumes, {surnom} ? Regarde sous les rochers où se posent les corbeaux.", "si": {"quete": "demandee"}},
					{"t": "Croâ porte son nouveau manteau de plumes. Il est insupportable de fierté.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "Les salamandres de feu dorment sur les pierres chaudes. Ne les touche pas : elles ne mordent pas, mais elles brûlent.", "si": {}},
					{"t": "Sur la plage noire, il y a des crabes de lave. Ils sont gentils. Juste un peu chauds.", "si": {}},
				],
				"rumeur": [
					{"t": "Croâ dit qu'il a vu une porte de pierre, tout en haut, au bord du cratère. Croâ dit aussi qu'il est un aigle. Alors…", "si": {}, "geste": "rire"},
					{"t": "Borin et Grimli se disputent depuis cent ans pour savoir qui a la plus belle barbe. C'est moi.", "si": {}, "geste": "rire"},
				],
				"quete_manque": [{"t": "Encore {manque} plumes, {surnom}.", "si": {}}],
				"quete_fin": [{"t": "De belles plumes noires ! Croâ va être jaloux. Tiens : trois fromages et vingt pièces. Le fromage, ça se mange vite. Il est… vivant.", "si": {}, "geste": "rire", "humeur": 0.3}],
				"boutique": [{"t": "Fromage de chèvre des cendres, le meilleur du monde. Tu as {pieces} pièces.", "si": {}}],
				"interpelle": [
					{"t": "Doucement, le grand ! Les chèvres !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Croâ te salue.", "si": {"visites_min": 1}},
				],
			},
		},
	},
]


## Les quatre habitants de la cité, sous la montagne (forgefer_v47.gd).
const DEDANS := [
	{
		"coin": "trone",
		"data": {
			"id": "thorgal", "nom": "Thorgal Marteau-d'Or", "titre": "roi de Forgefer",
			"nain": {"texture": TEX + "nain_royal.png", "barbe": [0.92, 0.9, 0.86], "style_barbe": "tresse", "coiffe": "couronne",
				"tunique": [0.45, 0.1, 0.12], "metal": [0.95, 0.78, 0.35], "cape": [0.55, 0.08, 0.1], "outil": "hache", "taille": 0.84},
			"teinte": [0.98, 0.74, 0.6],
			"humeur_base": 0.2, "energie_base": 0.6, "affinite_depart": 5.0,
			"traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.4, "radin": 0.7},
			"aime": {"rubis": 3.0, "piece_or": 2.0, "biere_naine": 2.0, "ecaille_naga": 3.0, "coeur_magma": 1.5},
			"deteste": {"epee_bois": -1.0},
			"refuse": [],
			"sujets_speciaux": [
				{"id": "merci_roi", "label": "Vos sujets ont eu besoin d'aide…", "si": {"a_trouve": "nains_aides_3", "pas_fait": "cadeau_roi"}},
				{"id": "coeur", "label": "Le cœur de la montagne ?", "si": {"sujet_min": ["lui", 1]}},
			],
			"repliques": {
				"accueil": [
					{"t": "Approche, le grand. Approche. Thorgal Marteau-d'Or, roi de Forgefer, seigneur de la Montagne de Feu. Tu peux t'incliner. … Plus bas.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "Ah, {surnom}. Mon royaume parle de toi. Assieds-toi. Pas sur le trône.", "si": {"visites_min": 2}},
					{"t": "Le vainqueur du Serpent des Abysses ! Les corbeaux m'ont tout raconté. Approche !", "si": {"a_trouve": "naga", "visites_max": 1}, "geste": "salut"},
				],
				"humeur": [
					{"t": "Royalement bien. La bière est fraîche, les forges brûlent, les golems… hmm. Presque bien.", "si": {}},
					{"t": "La couronne pèse. Surtout le matin.", "si": {"energie_max": 0.5}},
				],
				"lui": [
					{"t": "Je suis le quarante-deuxième roi de Forgefer. Mon arrière-arrière-grand-père a creusé cette salle à la main. Avec une cuillère, dit-on. Je n'y crois pas.", "si": {}},
					{"t": "Mon peuple forge depuis mille ans. Nos lames ont vaincu des dragons. Enfin, un dragon. Un petit. Il avait le rhume.", "si": {}, "geste": "rire"},
					{"t": "Tu as aidé mes sujets dehors. Bramm, Borin, Dagna… Un roi n'oublie pas.", "si": {"a_trouve": "nains_aides_3"}},
				],
				"ile": [
					{"t": "La montagne est notre mère, notre forge et notre forteresse. Les récifs et la cendre nous cachent des grands. Toi, tu es venu avec la carte d'Églantine. Elle a toujours eu bon goût.", "si": {}},
					{"t": "Sous cette salle, il y a la Forge Royale, alimentée par la lave du volcan. Plus bas encore… personne n'y descend.", "si": {}},
				],
				"rumeur": [
					{"t": "Ulfa croit que je ne vois pas qu'elle met de l'eau dans ma bière. Je vois. Je fais semblant. C'est ça, être roi.", "si": {}, "geste": "rire"},
					{"t": "Nori lit les runes. Il dit que la montagne a peur. Une montagne qui a peur… Hmm.", "si": {}},
				],
				"merci_roi": [
					{"t": "Mes sujets m'ont tout dit : tu as aidé ma garde, ma forge, mes cuisines, mes mines. Un roi récompense. Tiens : trois pièces d'or de la Forge Royale. Et le titre d'ami de Forgefer. Le titre est gratuit. L'or, non.", "si": {}, "action": "donne", "donne": [["piece_or", 3]], "pose": "cadeau_roi", "geste": "salut", "humeur": 0.2},
				],
				"coeur": [
					{"t": "Le Cœur de la Montagne… Une pierre de feu, grosse comme un tonneau, qui bat au fond du volcan. Elle tient la lave endormie. Depuis que les golems se sont réveillés, son battement est faible. Nori t'en dira plus. Un jour, peut-être, nous aurons besoin de toi, le grand.", "si": {}},
				],
				"interpelle": [
					{"t": "Approche, le grand !", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Viens saluer ton roi.", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "taverne",
		"data": {
			"id": "ulfa", "nom": "Ulfa Chope-Pleine", "titre": "tavernière de la Chope Ardente",
			"nain": {"texture": TEX + "nain_braise.png", "barbe": [0.75, 0.32, 0.12], "style_barbe": "fourche", "coiffe": "bonnet",
				"tunique": [0.5, 0.3, 0.15], "metal": [0.8, 0.62, 0.3], "tablier": true, "taille": 0.78},
			"teinte": [1.0, 0.75, 0.62],
			"humeur_base": 0.5, "energie_base": 0.9, "affinite_depart": 12.0,
			"traits": {"bavard": 0.95, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.2, "radin": 0.3},
			"aime": {"miel": 2.5, "biere_naine": 1.0, "pomme": 1.5, "baies": 1.5, "fromage_chevre": 1.5},
			"deteste": {"caillou": -0.5},
			"refuse": [],
			"quete": {"objet": "miel", "nombre": 3, "recompense": [["biere_naine", 3], ["piece", 25]], "affinite": 15.0,
				"sujet": "Ton miel sauvage…", "note": "m'a demandé du miel", "souvenir": "Avec ton miel, j'ai brassé l'hydromel de Forgefer. Le roi en a bu un tonneau."},
			"boutique": {"vend": {"biere_naine": 5, "ragout_nain": 12, "fromage_chevre": 8}, "achete": {"miel": 9, "pomme": 2, "baies": 2, "noix_coco": 4, "bar": 6}},
			"repliques": {
				"accueil": [
					{"t": "Bienvenue à la Chope Ardente ! La seule taverne sous un volcan. Ulfa Chope-Pleine. Une bière ? Deux bières ? Le tonneau ?", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.1},
					{"t": "{surnom} ! Ta chope t'attend. Enfin, n'importe quelle chope.", "si": {"visites_min": 2}, "geste": "rire"},
				],
				"humeur": [
					{"t": "Formidable ! La taverne est pleine, les chansons sont fausses, tout va bien.", "si": {"humeur_min": 0.2}, "geste": "rire"},
					{"t": "Fatiguée. Le roi a chanté jusqu'à l'aube. Tu as déjà entendu un roi nain chanter ? Ne le fais pas.", "si": {}},
				],
				"lui": [
					{"t": "Je brasse la bière de Forgefer depuis deux cents ans. Brune, mousseuse, et elle donne chaud aux oreilles.", "si": {}},
					{"t": "Je rêve de brasser un hydromel. Mais ici, pas d'abeilles : trop chaud. Si tu me rapportais {manque} rayons de miel de ton île… Je t'en offrirais la première chope !", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Mes {manque} rayons de miel, {surnom} ? Sur ton île, dans les arbres creux.", "si": {"quete": "demandee"}},
					{"t": "Mon hydromel est un triomphe ! Le roi en a bu un tonneau. Il a dansé sur la table. La table s'en souvient.", "si": {"quete": "finie"}, "geste": "rire"},
				],
				"ile": [
					{"t": "La Chope Ardente, c'est le cœur de Forgefer. Le roi a son trône, moi j'ai mon comptoir. On sait qui on vient voir.", "si": {}, "geste": "rire"},
					{"t": "La cité s'étend sous toute la montagne : la grande halle, la Forge Royale, les mines, les dortoirs… et ma cave. La plus grande salle de toutes.", "si": {}},
				],
				"rumeur": [
					{"t": "Orsik compte ses rubis tous les soirs. Il en manque toujours un. C'est moi qui le cache. Chut.", "si": {}, "geste": "rire"},
					{"t": "Nori boit de l'eau. De l'EAU. Dans une taverne. Je ne dis rien. Je n'en pense pas moins.", "si": {}},
					{"t": "Bramm vient boire ici après sa garde. Il sourit, parfois. Ne le répète à personne.", "si": {}},
				],
				"quete_manque": [{"t": "Encore {manque} rayons de miel, {surnom}. Mon tonneau attend.", "si": {}}],
				"quete_fin": [{"t": "Du miel ! Du VRAI miel ! Tiens : trois bières, vingt-cinq pièces, et quand l'hydromel sera prêt, ta première chope est offerte.", "si": {}, "geste": "rire", "humeur": 0.4}],
				"boutique": [{"t": "Bière de Forgefer, ragoût de Dagna, fromage de Hilda ! Et je rachète le miel et les fruits. Tu as {pieces} pièces.", "si": {}}],
				"interpelle": [
					{"t": "Hé, le grand ! Une bière ?", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Ta chope !", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "runes",
		"data": {
			"id": "nori", "nom": "Nori le Runiste", "titre": "gardien des runes",
			"nain": {"texture": TEX + "nain_royal.png", "barbe": [0.95, 0.95, 0.95], "style_barbe": "large", "coiffe": "capuche",
				"tunique": [0.18, 0.2, 0.35], "metal": [0.7, 0.72, 0.8], "outil": "baton", "taille": 0.74},
			"teinte": [0.96, 0.78, 0.68],
			"humeur_base": 0.15, "energie_base": 0.35, "affinite_depart": 6.0,
			"traits": {"bavard": 0.85, "humour": 0.4, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2, "radin": 0.4},
			"aime": {"obsidienne": 2.5, "rune_golem": 3.0, "fleur_lune": 2.0, "eclat_cristal": 2.0},
			"deteste": {"biere_naine": -0.5},
			"refuse": [],
			"quete": {"objet": "obsidienne", "nombre": 4, "recompense": [["piece_or", 2]], "affinite": 18.0,
				"sujet": "L'obsidienne…", "note": "m'a demandé de l'obsidienne", "souvenir": "Sur ton obsidienne, j'ai gravé les runes de garde de la cité."},
			"repliques": {
				"accueil": [
					{"t": "Ah… Un grand. Les runes me l'avaient dit. Nori, gardien des runes. Assieds-toi, et parle doucement : les pierres écoutent.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom}. Les runes ont changé depuis ta dernière visite. Elles changent toujours.", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Inquiet. La montagne gronde, la nuit. Ce n'est pas un grondement normal.", "si": {}},
					{"t": "Bien, bien. Une rune m'a souri ce matin. Ça n'arrive pas souvent.", "si": {}},
				],
				"lui": [
					{"t": "J'ai quatre cent douze ans. Je lis les runes que nos ancêtres ont gravées dans la montagne. Elles racontent l'avenir. Mal, souvent. Mais elles le racontent.", "si": {}},
					{"t": "Les runes de garde de la cité s'effacent. Il me faut de l'obsidienne pour en graver de nouvelles : {manque} éclats. On la trouve près du cratère, là où la lave a refroidi en verre noir. Attention aux élémentaires.", "si": {"quete": "", "sujet_min": ["lui", 1]}, "action": "quete_demande"},
					{"t": "Toujours {manque} éclats d'obsidienne, {surnom}. Le verre noir, au bord du cratère.", "si": {"quete": "demandee"}},
					{"t": "Les nouvelles runes de garde brillent sur les portes. Grâce à toi, la cité dort mieux.", "si": {"quete": "finie"}},
				],
				"ile": [
					{"t": "Les golems des hauteurs ont été taillés par nos ancêtres pour garder le Cœur de la Montagne. Quelqu'un — ou quelque chose — les a réveillés. Ils ne reconnaissent plus personne.", "si": {}},
					{"t": "Le Cœur de la Montagne bat sous nos pieds. Il faiblit. Quand il s'arrêtera, la lave se réveillera. Pas aujourd'hui. Pas demain. Mais un jour.", "si": {}},
				],
				"rumeur": [
					{"t": "Les runes parlent d'un grand venu de la mer, qui vaincra le feu par le feu. Je ne dis pas que c'est toi. Je ne dis pas que ce n'est pas toi.", "si": {}},
					{"t": "Ulfa croit que je bois de l'eau. C'est de l'eau de lune. Elle ne saurait pas la différence.", "si": {}},
				],
				"quete_manque": [{"t": "Il me manque {manque} éclats d'obsidienne. Les runes attendent.", "si": {}}],
				"quete_fin": [{"t": "De l'obsidienne pure ! Regarde comme elle boit la lumière. Tiens, deux pièces d'or de mon coffre. Et une rune gravée dans ta mémoire : « Le feu garde le feu. » Tu comprendras un jour.", "si": {}, "geste": "salut", "humeur": 0.3}],
				"interpelle": [
					{"t": "Les runes t'attendaient, le grand…", "si": {"visites_max": 0}},
					{"t": "{surnom}… approche.", "si": {"visites_min": 1}},
				],
			},
		},
	},
	{
		"coin": "joaillier",
		"data": {
			"id": "orsik", "nom": "Orsik Sertissor", "titre": "joaillier de la cité",
			"nain": {"texture": TEX + "nain_royal.png", "barbe": [0.3, 0.2, 0.12], "style_barbe": "fourche", "coiffe": "chauve",
				"tunique": [0.25, 0.15, 0.35], "metal": [0.95, 0.8, 0.4], "tablier": true, "taille": 0.76},
			"teinte": [0.98, 0.74, 0.62],
			"humeur_base": 0.2, "energie_base": 0.7, "affinite_depart": 4.0,
			"traits": {"bavard": 0.6, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.5, "radin": 0.9},
			"aime": {"rubis": 3.0, "perle": 2.5, "eclat_cristal": 2.0, "piece_or": 2.0, "ecaille_naga": 2.5},
			"deteste": {"caillou": -1.0, "baton": -0.5},
			"refuse": [],
			"boutique": {"vend": {"rubis": 45, "piece_or": 22}, "achete": {"rubis": 25, "perle": 15, "eclat_cristal": 6, "coquillage": 2, "ecaille_naga": 60, "coeur_magma": 14, "obsidienne": 6, "piece_or": 18}},
			"repliques": {
				"accueil": [
					{"t": "Un client ! Enfin… un grand. Orsik Sertissor, joaillier. Je n'achète que ce qui brille. Tu brilles ? Non. Tes poches, peut-être.", "si": {"visites_max": 1}, "geste": "salut"},
					{"t": "{surnom}. Tu as quelque chose qui brille pour moi ?", "si": {"visites_min": 2}},
				],
				"humeur": [
					{"t": "Bien. J'ai compté mes rubis : il en manque un. Comme d'habitude.", "si": {}},
					{"t": "Excellent ! Un rubis gros comme un œuf de corbeau est arrivé ce matin.", "si": {"humeur_min": 0.2}, "geste": "rire"},
				],
				"lui": [
					{"t": "Je sertis les couronnes, les pommeaux, les boucles de ceinture. La couronne du roi, c'est moi. Les huit rubis. Enfin, sept : un est faux. Chut.", "si": {}},
					{"t": "J'achète les perles, les rubis, les éclats de cristal, les écailles… tout ce qui brille. Les nains paient mieux que les grands. Enfin, moi.", "si": {}},
				],
				"ile": [
					{"t": "Le volcan donne des rubis, quand il est de bonne humeur. Les mineurs les trouvent dans la roche rouge.", "si": {}},
				],
				"rumeur": [
					{"t": "Ulfa me vole un rubis par soir. Je le sais. Je fais semblant. Elle me les rend à la fête de la Forge.", "si": {}},
					{"t": "Une écaille du Serpent des Abysses ? Si tu en as une… je paie une fortune. Une vraie fortune.", "si": {"a_trouve": "naga"}},
				],
				"boutique": [{"t": "Rubis, pièces d'or… et j'achète tout ce qui brille. Tu as {pieces} pièces.", "si": {}}],
				"interpelle": [
					{"t": "Psst, le grand ! Tu as des perles ?", "si": {"visites_max": 0}},
					{"t": "{surnom} ! Qu'as-tu qui brille ?", "si": {}},
				],
			},
		},
	},
]


## Nains de passage : nom, coiffe, barbe, couleur de barbe, texture, métier, outil.
const PASSANTS := [
	["Dwalin", "casque", "large", [0.45, 0.25, 0.1], "nain_suie.png", "porteur de charbon", "pioche"],
	["Brunna", "bonnet", "tresse", [0.8, 0.45, 0.2], "nain_mousse.png", "souffleuse de forge", "marteau"],
	["Fundin", "capuche", "fourche", [0.3, 0.3, 0.32], "nain_braise.png", "apprenti forgeron", "marteau"],
	["Kalda", "casque", "tresse", [0.2, 0.14, 0.1], "nain_suie.png", "éclaireuse des pentes", "lance"],
	["Ori", "chauve", "large", [0.85, 0.82, 0.78], "nain_royal.png", "scribe de la cité", ""],
	["Gunnar", "casque", "fourche", [0.55, 0.2, 0.08], "nain_braise.png", "garde de la halle", "bouclier"],
	["Sigrun", "bonnet", "tresse", [0.95, 0.75, 0.4], "nain_mousse.png", "brasseuse", ""],
]

const PASSANT_LINES := {
	"accueil": [
		{"t": "Un grand ! Sur la terrasse ! Bonjour, bonjour.", "si": {"visites_max": 1}, "geste": "salut"},
		{"t": "Te revoilà. Tu ne grandis pas, au moins ?", "si": {"visites_min": 2}, "geste": "rire"},
		{"t": "C'est toi qui as abattu les golems ? Bienvenue à Forgefer, l'ami !", "si": {"a_trouve": "porte_forgefer"}, "geste": "salut"},
	],
	"humeur": [
		{"t": "Bien. Il fait chaud. Il fait toujours chaud. C'est bien.", "si": {}},
		{"t": "J'ai mal au dos. Le charbon, ça pèse.", "si": {}},
		{"t": "Très bien ! Ulfa a mis un nouveau tonneau en perce.", "si": {}, "geste": "rire"},
	],
	"lui": [
		{"t": "Moi ? Je suis {titre}. Un métier honnête. Comme tous les métiers nains.", "si": {}},
		{"t": "Je suis né sous la montagne, comme mon père, et son père, et son père… tu vois l'idée.", "si": {}},
	],
	"ile": [
		{"t": "Ne monte pas vers le cratère sans arme. Les golems et les élémentaires n'aiment pas les visiteurs.", "si": {}},
		{"t": "La Grande Porte mène à la cité. Bramm ne laisse entrer personne. Personne.", "si": {"pas_trouve": "porte_forgefer"}},
		{"t": "Dans la cité, va à la Chope Ardente. Dis à Ulfa que tu viens de ma part. Elle ne me connaît pas, mais dis-le quand même.", "si": {"a_trouve": "porte_forgefer"}, "geste": "rire"},
	],
	"rumeur": [
		{"t": "Le roi a encore perdu sa couronne. Elle était sur sa tête.", "si": {}, "geste": "rire"},
		{"t": "Les golems descendent plus bas chaque nuit. Ça ne me plaît pas.", "si": {}},
		{"t": "On dit qu'une reine des fées t'a donné la carte. Une fée. Qui aide un grand. À trouver des nains. Le monde change.", "si": {"a_trouve": "reine"}},
	],
	"interpelle": [
		{"t": "Salut, le grand !", "si": {}},
		{"t": "Attention, ça chauffe !", "si": {}},
		{"t": "Pierre et feu !", "si": {}},
	],
}


## Fiche d'un nain de passage (n = rang dans PASSANTS).
static func passant(n: int) -> Dictionary:
	var p: Array = PASSANTS[n % PASSANTS.size()]
	var tun := [[0.4, 0.22, 0.12], [0.24, 0.3, 0.2], [0.3, 0.28, 0.35], [0.45, 0.15, 0.12], [0.25, 0.25, 0.3]]
	var lines: Dictionary = PASSANT_LINES.duplicate(true)
	for e in lines["lui"]:
		e["t"] = str(e["t"]).replace("{titre}", str(p[5]))
	var d := {
		"id": "nain_%d" % n, "nom": str(p[0]), "titre": str(p[5]),
		"nain": {"texture": TEX + str(p[4]), "barbe": p[3], "style_barbe": str(p[2]), "coiffe": str(p[1]),
			"tunique": tun[n % tun.size()], "metal": [0.6, 0.6, 0.64], "outil": str(p[6]), "tablier": n % 3 == 1,
			"taille": 0.74 + 0.03 * (n % 3)},
		"teinte": [0.98, 0.72 + 0.02 * (n % 3), 0.6],
		"humeur_base": 0.2, "energie_base": 0.8, "affinite_depart": 6.0,
		"traits": {"bavard": 0.4, "humour": 0.55, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.4},
		"aime": {"biere_naine": 2.0, "ragout_nain": 1.5, "rubis": 1.5},
		"deteste": {"fleur_lune": -0.5},
		"refuse": [],
		"repliques": lines,
	}
	return complete(d)

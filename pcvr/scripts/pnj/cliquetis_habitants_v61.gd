extends RefCounted
## V61 : les gens de Cliquetis, la cité des ingénieurs fous, sur les hautes terres du nord de
## la grande île. Des inventeurs, des horlogers, des mécaniciens, des savants un peu fêlés et
## leurs familles, qui vivent au milieu des robots, de la vapeur et des explosions.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd ; postures et tenues en plus : pnj_tazira_v60.gd, pnj_cliquetis_v61.gd).
## Lieux : cliquetis_v61.gd (spots). Ils parlent de la Foire des Inventions, du Zéphyr, des
## bergers des hautes terres, de Tazira et de Carène, et du sceau du nord.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Au revoir, {surnom} ! Graissez bien vos rouages.", "si": {}, "geste": "salut"},
		{"t": "À la prochaine invention !", "si": {}, "geste": "salut"},
		{"t": "Filez, filez, j'ai une idée qui va s'envoler.", "si": {}},
		{"t": "Bonne nuit. Si vous entendez une explosion, c'est le professeur Boum. Rendormez-vous.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Je vais vous faire breveter, vous, comme danger public !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Le Colosse va entendre parler de vous !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Merci ! Je vais le démonter pour voir comment ça marche.", "si": {}},
		{"t": "Un cadeau ? Formidable. Je vais lui ajouter un moteur.", "si": {}, "geste": "rire"},
	],
	"cadeau_refus": [{"t": "Une arme ? Non, merci. Ici, on invente des choses qui ne font de mal à personne. Sauf le professeur Boum, mais c'est involontaire.", "si": {}}],
	"blague": [
		{"t": "Combien faut-il d'ingénieurs de Cliquetis pour changer une ampoule ? Un seul. Mais l'ampoule tourne maintenant à la vapeur, parle trois langues et sert le thé.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi l'horloge de l'Académie ne ment jamais ? Parce qu'elle a trop de ressort ! … Elle est de Tic Tacquet. Il la raconte toutes les heures.", "si": {}, "geste": "rire"},
		{"t": "Un robot entre dans un café. Le majordome lui dit : « On ne sert pas les robots. » Le robot répond : « Ça tombe bien, je suis un grille-pain. »", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Voyons, voyons… Tout est garanti, sauf ce qui ne l'est pas. Vous avez {pieces} pièces.", "si": {}}],
	"achat": [{"t": "{objet}, {prix} pièces. Mode d'emploi non fourni. C'est plus amusant.", "si": {}, "geste": "salut"}],
	"marchande_non": [{"t": "Marchander ? J'ai calculé le prix au centime près avec ma machine à calculer. Elle ne se trompe jamais. Enfin, presque.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Eurêka !", "Sapristi !", "Formidable !", "Par mes engrenages !"],
		"neutre": ["Hmm.", "Voyons…", "Bon.", "Intéressant…"],
		"triste": ["Ah…", "Zut et flûte.", "Encore une soupape de grillée…", "Pff."],
		"colere": ["Tss.", "Saperlipopette !", "Ça suffit.", "Écoutez-moi bien."],
	},
	"tics": ["Mécaniquement parlant.", "Théoriquement.", "Par mes engrenages !", "Comme disait mon vieux maître."],
	"humeur_mots": [[0.6, "inspiré"], [0.25, "de bonne humeur"], [-0.25, "songeur"], [-0.6, "contrarié"], [-2.0, "en surchauffe"]],
	"surnoms": [[0, "visiteur"], [25, "apprenti"], [50, "collègue"], [75, "ingénieur"], [95, "génie de Cliquetis"]],
}

const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [1.0, 0.9, 0.8]]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


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
	out = Azur.complete(out)
	out["groupe"] = "cliquetis"
	return out


static func _all() -> Array:
	return [
		# ================================================================ l'Académie
		{"id": "heloise", "nom": "Héloïse Manivelle", "titre": "ingénieure-en-chef de Cliquetis", "maison": "porte_academie",
			"agenda": [[8, 11, "academie_porte"], [11, 14, ["machine_1", "stand_client_5"]], [14, 18, "academie_porte"], [18, 21, ["cafe_table_1", "promenade_banc_3"]], [21, 8, "maison"]],
			"azur": {"cheveux": [0.45, 0.28, 0.16], "coiffure": "chignon", "haut": [0.2, 0.25, 0.4], "robe": [0.18, 0.22, 0.36], "robe_longue": true, "yeux": [0.3, 0.45, 0.5], "lunettes": false},
			"cq": {"monocle": true, "noeud_papillon": [0.7, 0.1, 0.12]},
			"teinte": PEAU[0], "humeur_base": 0.2, "traits": {"bavard": 0.7, "humour": 0.4, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"montre_envers": 2.0, "engrenage_or": 2.0, "boussole": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Bienvenue à Cliquetis, la cité des ingénieurs ! Héloïse Manivelle, ingénieure-en-chef. Ici, on invente le matin, on teste l'après-midi, et on répare le soir. Parfois dans l'autre ordre.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom} ! Vous tombez bien, j'ai besoin d'un œil neuf. Les miens ont trop vu d'engrenages.", {"visites_min": 2}),
				],
				"humeur": [L("Débordée ! La Foire des Inventions bat son plein, et chaque inventeur pense que la sienne est la meilleure. Ils ont tous raison. C'est ça le problème.", {}), L("Le soir, je regarde la cité s'allumer depuis la promenade. Toutes ces fenêtres, ce sont des gens qui inventent encore.", {"soir": true})],
				"lui": [
					L("J'ai inventé le téléphérique, le monorail et la moitié des robots balayeurs. L'autre moitié, c'est Maître Rivet. On ne se parle plus depuis l'affaire du balayeur qui chantait.", {}),
					L("Mon rêve ? Une machine qui pense. Le professeur Boum dit qu'il en a une. Elle a explosé la semaine dernière.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Cliquetis est le nord de l'île : les hautes terres, la bruyère, la neige sur les crêtes. Les bergers nous vendent la laine et le minerai ; nous leur vendons… des machines à tondre. Ils ne s'en servent pas.", {}),
					L("Le Zéphyr relie Cliquetis à Tazira et à Carène. Avant, il fallait trois jours de marche. Maintenant, il faut trois minutes et un estomac solide.", {"sujet_min": ["ile", 1]}),
					L("Le sceau du nord ? On raconte que les bergers le gardent dans une grotte, sous la plus haute crête. Ils ne veulent pas en parler. Je les comprends : si je l'avais, je le démonterais.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Firmin Cogne a perdu l'engrenage d'or de son moteur perpétuel. Il dit qu'il a roulé jusqu'au port. Un engrenage qui roule jusqu'en bas de la falaise… c'est presque une invention.", {}), L("Le professeur Boum a encore perdu son toit. C'est le troisième ce mois-ci.", {})],
				"interpelle": [L("Visiteur ! Bienvenue à la Foire !", {"visites_max": 0}), L("{surnom} ! Par ici !", {"visites_min": 1})],
			}},
		{"id": "tacquet", "nom": "Tic Tacquet", "titre": "horloger de la grande horloge", "maison": "porte_maison_5",
			"agenda": [[7, 12, "horloge"], [12, 13, "cafe_bar_1"], [13, 19, "horloge"], [19, 22, ["promenade_banc_1", "cafe_table_2"]], [22, 7, "maison"]],
			"azur": {"cheveux": [0.85, 0.85, 0.82], "coiffure": "court", "barbe": "moustache", "lunettes": true, "haut": [0.35, 0.28, 0.22], "tablier": [0.3, 0.22, 0.14], "vieux": true, "yeux": [0.3, 0.3, 0.35], "taille": 0.92},
			"cq": {"noeud_papillon": [0.15, 0.3, 0.55]},
			"teinte": PEAU[1], "humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"montre_envers": 2.5, "laiton": 1.0}, "deteste": {"sifflet_muet": -0.5},
			"repliques": {
				"accueil": [L("Tic… tac… Bonjour ! Tacquet. Horloger. Cette grande horloge, là-haut, c'est moi qui la remonte chaque matin. Elle n'a jamais eu une seconde de retard. Une seconde d'avance, une fois. Je l'ai grondée.", {"visites_max": 1}, "salut"), L("Ah ! Vous êtes à l'heure. J'aime les gens à l'heure.", {"visites_min": 2})],
				"humeur": [L("Ponctuelle. Comme toujours.", {}, "rire")],
				"lui": [L("Quarante-deux ans d'horlogerie. Je dors avec trois réveils. Ils sonnent tous à la même seconde. C'est le plus beau son du monde.", {}), L("La montre qui tourne à l'envers, au Bazar ? C'est moi qui l'ai faite. Un jour de distraction. Elle est parfaitement juste, mais dans l'autre sens.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("De là-haut, sur la tour, on voit toute l'île. Le Cœur-de-Pierre au sud, avec son plateau tout rond. On dirait le cadran d'une horloge géante. Sans aiguilles.", {})],
				"rumeur": [L("Achille Plumevent vole au-dessus de la ville depuis huit jours. Il n'arrive pas à atterrir. Sa sœur lui lance des sandwiches.", {}, "rire")],
				"interpelle": [L("Tic tac !", {"visites_max": 0}), L("{surnom}, à l'heure !", {"visites_min": 1})],
			}},
		# ================================================================ les inventeurs de la Foire
		{"id": "cogne", "nom": "Firmin Cogne", "titre": "inventeur du moteur perpétuel", "maison": "porte_maison_2",
			"agenda": [[8, 19, "stand_6"], [19, 22, ["cafe_table_3", "cafe_bar_2"]], [22, 8, "maison"]],
			"azur": {"cheveux": [0.25, 0.18, 0.12], "coiffure": "boucles", "barbe": "courte", "haut": [0.55, 0.42, 0.25], "yeux": [0.3, 0.35, 0.2], "carrure": 1.1},
			"cq": {"lunettes_aviateur": true, "sac_vapeur": true},
			"teinte": PEAU[2], "humeur_base": 0.0, "traits": {"bavard": 0.8, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"engrenage_or": 3.0, "minerai_fer": 1.0}, "deteste": {"vieille_botte": -0.5},
			"repliques": {
				"accueil": [L("Approchez ! Admirez ! Le Moteur Perpétuel de Firmin Cogne : il tourne depuis onze ans sans jamais s'arrêter ! … Bon, il s'est arrêté hier. Mais c'est la faute de l'engrenage.", {"visites_max": 1}, "salut"), L("Ah, vous ! Vous avez vu mon moteur ? Il tourne. Enfin, il tourne mieux qu'hier.", {"visites_min": 2})],
				"humeur": [L("Inquiet. Sans mon engrenage d'or, le jury ne va jamais me croire.", {}), L("Fatigué. Mon moteur perpétuel, lui, ne se fatigue jamais. C'est le principe.", {"soir": true}, "rire")],
				"lui": [L("Le mouvement perpétuel, tout le monde dit que c'est impossible. Moi je dis : c'est juste très, très difficile. Et j'ai beaucoup de temps.", {}), L("L'engrenage d'or, c'est mon grand-père qui l'a coulé. Quatorze dents, de l'or massif, et mon nom gravé dessus. Il a roulé jusqu'en bas de la falaise pendant la démonstration. Une démonstration de trop.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les bergers des hautes terres ont un moulin à vent qui tourne depuis cent ans. Cent ans ! Je voudrais voir comment il est fait. Ils ne me laissent pas approcher.", {})],
				"rumeur": [L("Capucine dit que son canon à confettis gagnera la Foire. Ses confettis sont dans tous mes engrenages.", {}), L("Le port est plein de choses tombées de la falaise. Gonzague, le grutier, en a une collection.", {})],
				"interpelle": [L("Admirez le Moteur Perpétuel !", {"visites_max": 0}), L("{surnom} ! Mon engrenage ?", {"visites_min": 1})],
			}},
		{"id": "prudence", "nom": "Prudence Touche", "titre": "inventrice du piano mécanique", "maison": "porte_maison_3",
			"agenda": [[9, 19, "stand_1"], [19, 22, ["cafe_table_4", "promenade_vue_1"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.15, 0.1, 0.08], "coiffure": "carre", "haut": [0.85, 0.82, 0.75], "robe": [0.45, 0.12, 0.2], "yeux": [0.25, 0.35, 0.5]},
			"cq": {"noeud_papillon": [0.1, 0.1, 0.12]},
			"teinte": PEAU[5], "humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"canard_mecanique": 2.0, "miel": 1.5}, "deteste": {"sifflet_muet": -1.0},
			"repliques": {
				"accueil": [L("Bonjour ! Prudence Touche. Voici mon piano mécanique : il joue tout seul, il tourne les pages tout seul, et il salue à la fin. Le public applaudit tout seul aussi, parfois.", {"visites_max": 1}, "salut"), L("Re-bonjour ! Le piano a appris un nouveau morceau. Enfin, il croit.", {"visites_min": 2})],
				"humeur": [L("En harmonie !", {}, "rire")],
				"lui": [L("Le cylindre, là, avec ses picots : chaque picot est une note. J'en ai planté douze mille à la main. Je ne sens plus mes pouces.", {}), L("Un jour, mon piano a joué une musique que je ne lui avais pas apprise. Je n'ai jamais su d'où elle venait. Elle venait peut-être du Cœur-de-Pierre.", {"sujet_min": ["lui", 1]})],
				"ile": [L("À Tazira, ils ont des musiciens qui jouent toute la nuit sur la place. Je les ai écoutés depuis le Zéphyr. J'ai noté leurs rythmes. Mon piano va danser.", {})],
				"rumeur": [L("Ambroise dit que son automate joueur d'échecs n'a jamais perdu. C'est parce qu'il triche. Enfin, l'automate. Ambroise, je ne sais pas.", {}, "rire")],
				"interpelle": [L("Une petite musique ?", {"visites_max": 0}), L("{surnom} ! Écoutez !", {"visites_min": 1})],
				"jury": [L("Mon avis sur le piano ? Il est parfait. Mais dites au jury qu'il joue mieux le matin. Il est un peu enrhumé le soir.", {})],
			}},
		{"id": "basile", "nom": "Basile Bulle", "titre": "inventeur de la machine à bulles", "maison": "porte_maison_4",
			"agenda": [[9, 19, "stand_2"], [19, 22, ["promenade_banc_2", "cafe_bar_1"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.9, 0.7, 0.35], "coiffure": "boucles", "haut": [0.3, 0.55, 0.8], "yeux": [0.3, 0.5, 0.7], "taille": 0.95},
			"cq": {"lunettes_aviateur": true},
			"teinte": PEAU[0], "humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.9, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"tasse_tourneuse": 2.0, "glace": 1.5}, "deteste": {"boite_a_rien": -0.5},
			"repliques": {
				"accueil": [L("Une bulle ? Deux bulles ? Trois mille bulles par minute ! Basile Bulle, inventeur. Ma machine fait les plus belles bulles de l'archipel. Elles ne servent à rien, et c'est ça qui est beau.", {"visites_max": 1}, "rire"), L("Ah ! Mon visiteur préféré ! Regardez celle-là, elle est carrée !", {"visites_min": 2}, "rire")],
				"humeur": [L("Léger comme une bulle !", {}, "rire")],
				"lui": [L("Petit, je soufflais des bulles avec une paille. Maintenant, c'est une chaudière de cuivre, un soufflet à vapeur et deux litres de savon à la minute. On ne change pas, on grandit.", {}), L("Mon but : une bulle assez grande pour y faire entrer quelqu'un. J'y suis presque. Le professeur Boum veut essayer. Je ne suis pas sûr que ce soit une bonne idée.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Quand le vent souffle du sud, mes bulles volent jusqu'à la mer. Les marins du port disent qu'il pleut des bulles. Ils adorent.", {})],
				"rumeur": [L("Capucine a mis des confettis dans ma machine à bulles. Maintenant, les bulles sont pleines de confettis. C'est encore plus joli. Ne lui dites pas.", {}, "rire")],
				"interpelle": [L("Des bulles !", {"visites_max": 0}), L("{surnom} ! Des bulles !", {"visites_min": 1})],
				"jury": [L("Pour le jury ? Dites-leur que mes bulles rendent les gens heureux. C'est mesuré : on sourit 34 % plus près de ma machine.", {}, "rire")],
			}},
		{"id": "capucine", "nom": "Capucine Pétard", "titre": "inventrice du canon à confettis", "maison": "porte_maison_8",
			"agenda": [[9, 19, "stand_3"], [19, 22, ["machine_2", "cafe_table_1"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.85, 0.3, 0.15], "coiffure": "queue", "haut": [0.95, 0.75, 0.2], "robe": [0.2, 0.2, 0.5], "yeux": [0.3, 0.55, 0.35], "taille": 0.97},
			"cq": {"casque_aviateur": [0.35, 0.22, 0.12], "lunettes_aviateur": true},
			"teinte": PEAU[5], "humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"chapeau_ventilateur": 2.0, "biscuit_engrenage": 1.5}, "deteste": {"montre_envers": -0.3},
			"repliques": {
				"accueil": [L("BOUM ! … Pardon. Capucine Pétard. Mon canon à confettis tire toutes les vingt secondes, sur la foule. Les gens adorent. Les balayeurs, beaucoup moins.", {"visites_max": 1}, "rire"), L("Vous revenez vous faire confettiser ? Bravo !", {"visites_min": 2}, "rire")],
				"humeur": [L("Explosive ! Mais dans le bon sens.", {}, "rire")],
				"lui": [L("Je suis l'élève du professeur Boum. J'ai gardé l'idée d'exploser, mais j'ai enlevé le danger. Il reste les couleurs. C'est le meilleur.", {}), L("Mon prochain canon tirera des pétales de fleurs. Les bergers du nord m'ont promis de la bruyère.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Au nouvel an, je tire mes confettis du haut de la tour de l'horloge. Le vent les emporte jusqu'aux hautes terres. Les moutons sont tout colorés pendant une semaine.", {}, "rire")],
				"rumeur": [L("Les balayeurs ont fait une réclamation officielle contre moi. Signée « BIP ».", {}, "rire")],
				"interpelle": [L("Attention, ça va tirer !", {"visites_max": 0}), L("{surnom} ! Attention !", {"visites_min": 1})],
			}},
		{"id": "wilfried", "nom": "Wilfried Ressort", "titre": "inventeur de Boulon, le chien-robot", "maison": "porte_maison_9",
			"agenda": [[9, 19, "stand_4"], [19, 22, ["place_banc_2", "promenade_banc_4"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.1, 0.08, 0.06], "coiffure": "court", "barbe": "courte", "haut": [0.25, 0.4, 0.3], "yeux": [0.25, 0.2, 0.15]},
			"cq": {"bras_mecanique": true, "haut_de_forme": [0.12, 0.12, 0.14]},
			"teinte": PEAU[3], "humeur_base": 0.3, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"canard_mecanique": 2.0, "os": 1.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Bonjour. Wilfried Ressort. Et voici Boulon, le meilleur ami de l'homme… mécanique. Il rapporte, il donne la patte, il fait le beau. Il ne fait pas pipi partout : c'est son grand avantage.", {"visites_max": 1}, "salut"), L("Boulon vous a reconnu. Regardez sa queue !", {"visites_min": 2}, "rire")],
				"humeur": [L("Content. Boulon aussi, je crois. Il remue la queue, et sa queue est un ressort.", {})],
				"lui": [L("J'ai perdu mon bras droit dans une machine à coudre géante. Je me suis fait celui-ci, en laiton. Il est plus fort, mais il me gratte quand il pleut.", {}), L("Boulon a un cœur. Un vrai petit moteur qui bat plus vite quand on le caresse. Je l'ai fait exprès.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Boulon est déjà allé à Tazira en dirigeable. Il a couru après les chats du port. Il n'en a attrapé aucun. Eux, si.", {}, "rire")],
				"rumeur": [L("Le Colosse fait peur aux enfants. Il ne ferait pas de mal à une mouche. Il a d'ailleurs peur des mouches.", {})],
				"interpelle": [L("Boulon, assis !", {"visites_max": 0}), L("{surnom} ! Boulon vous dit bonjour.", {"visites_min": 1})],
			}},
		{"id": "ambroise", "nom": "Ambroise Échec", "titre": "inventeur de l'automate joueur d'échecs", "maison": "porte_maison_10",
			"agenda": [[9, 19, "stand_5"], [19, 22, "cafe_table_2"], [22, 9, "maison"]],
			"azur": {"cheveux": [0.6, 0.6, 0.58], "coiffure": "long", "barbe": "longue", "haut": [0.1, 0.1, 0.12], "yeux": [0.4, 0.4, 0.45], "vieux": true, "taille": 1.04},
			"cq": {"monocle": true, "haut_de_forme": [0.08, 0.08, 0.09], "engrenage_chapeau": true},
			"teinte": PEAU[1], "humeur_base": 0.0, "traits": {"bavard": 0.4, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.7, "rancunier": 0.5},
			"aime": {"montre_envers": 1.5, "boussole_sud": 1.5}, "deteste": {"chaussettes_vapeur": -0.5},
			"repliques": {
				"accueil": [L("Bonjour. Ambroise Échec. Mon automate n'a jamais perdu une partie. Voulez-vous essayer ? Non ? Vous êtes sage.", {"visites_max": 1}), L("Revanche ? Ah non, vous n'avez jamais joué. Pas encore.", {"visites_min": 2})],
				"humeur": [L("Concentré. Mon automate a trois coups d'avance sur moi.", {})],
				"lui": [L("Mon automate réfléchit grâce à quatre cents engrenages et un système de cartes perforées. Certains disent qu'un nain est caché dedans. C'est faux. Il n'y a pas la place.", {}), L("Une fois, l'automate a fait match nul contre lui-même. Il s'est vexé et n'a plus parlé pendant une semaine.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les gens des brumes, à l'est, jouent à un jeu avec des pierres blanches et noires. Mon automate a voulu apprendre. Il a perdu. Je n'en parle jamais.", {})],
				"rumeur": [L("Prudence dit que mon automate triche. C'est faux. Il bluffe.", {})],
				"interpelle": [L("Une partie ?", {"visites_max": 0}), L("{surnom}. Échec.", {"visites_min": 1})],
				"jury": [L("Mon avis sur mon automate ? Il est imbattable. Notez-le. Notez-le bien.", {})],
			}},
		# ================================================================ les savants et les ateliers
		{"id": "boum", "nom": "Professeur Augustin Boum", "titre": "savant (explosif)", "maison": "porte_boum",
			"agenda": [[8, 12, "boum_atelier"], [12, 13, "cafe_bar_2"], [13, 19, ["boum_atelier", "boum_debris"]], [19, 22, "cafe_table_3"], [22, 8, "maison"]],
			"azur": {"cheveux": [0.95, 0.95, 0.93], "coiffure": "boucles", "barbe": "moustache", "haut": [0.95, 0.95, 0.92], "vieux": true, "yeux": [0.3, 0.3, 0.3], "carrure": 1.05},
			"cq": {"lunettes_aviateur": true, "blouse": [0.92, 0.92, 0.88]},
			"teinte": PEAU[1], "humeur_base": 0.4, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"minerai_fer": 2.0, "obsidienne": 2.0, "coeur_magma": 2.5}, "deteste": {"glace": -1.0},
			"repliques": {
				"accueil": [L("Bonjour bonjour ! Professeur Augustin Boum ! Ne restez pas là, je suis en pleine expérience. Mettez-vous là. Non, là. Plus loin. Encore. Parfait.", {"visites_max": 1}, "rire"), L("Ah, mon visiteur ! Vous avez encore vos sourcils ? Bravo !", {"visites_min": 2}, "rire")],
				"humeur": [L("Excellente ! Rien n'a explosé depuis… au moins une heure.", {}, "rire"), L("Le soir, je fais mes expériences les plus silencieuses. Les voisins ont signé une pétition.", {"soir": true})],
				"lui": [L("Je cherche une énergie nouvelle, propre, puissante. Je l'ai trouvée onze fois. Elle a explosé onze fois.", {}), L("Mon atelier a eu quatorze toits. Le quinzième est en commande. J'ai besoin de fer pour le refaire, et les bergers du nord vendent le minerai trop cher.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Sous les hautes terres, il y a des cristaux qui brillent dans le noir. Les bergers les appellent « les étoiles d'en bas ». Si je pouvais en étudier un… BOUM ! Euh, pardon, je m'emballe.", {})],
				"rumeur": [L("Ma fumée verte de mardi a teint les moutons des bergers en vert. Ils sont venus se plaindre. Moi je trouve que ça leur va bien.", {}, "rire")],
				"interpelle": [L("Reculez ! Non, avancez ! Non, reculez !", {"visites_max": 0}), L("{surnom} ! Pas trop près !", {"visites_min": 1})],
			}},
		{"id": "electre", "nom": "Docteure Électre Volta", "titre": "électricienne du laboratoire Volta", "maison": "porte_volta",
			"agenda": [[8, 13, "volta_1"], [13, 14, "cafe_bar_1"], [14, 19, "volta_2"], [19, 22, ["promenade_vue_3", "volta_1"]], [22, 8, "maison"]],
			"azur": {"cheveux": [0.12, 0.1, 0.1], "coiffure": "boucles", "haut": [0.2, 0.2, 0.25], "yeux": [0.25, 0.55, 0.65]},
			"cq": {"blouse": [0.88, 0.9, 0.92], "lunettes_aviateur": true},
			"teinte": PEAU[3], "humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"eclat_cristal": 2.5, "boussole": 1.5}, "deteste": {"chaussettes_vapeur": -0.5},
			"repliques": {
				"accueil": [L("Attention aux éclairs ! Électre Volta. Ces deux bobines produisent un million de volts. À quoi ça sert ? Pour l'instant, à faire de très belles étincelles. Et à faire dresser les cheveux de mes visiteurs.", {"visites_max": 1}, "salut"), L("Vos cheveux tiennent encore ? Formidable.", {"visites_min": 2}, "rire")],
				"humeur": [L("Électrique !", {}, "rire")],
				"lui": [L("L'électricité, c'est l'avenir. La vapeur, c'est le passé. Le professeur Boum, c'est… autre chose.", {}), L("Un jour, j'éclairerai toute la cité sans une goutte d'huile. Pour l'instant, j'éclaire très bien mon laboratoire. Quand il ne prend pas feu.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Pendant les orages, je monte sur la tour avec un cerf-volant et une clé. Héloïse dit que c'est dangereux. Héloïse a raison. Mais c'est magnifique.", {})],
				"rumeur": [L("Céleste dit avoir vu une lumière bleue sur le Cœur-de-Pierre. Une lumière qui clignote. Je voudrais bien savoir ce qui l'alimente.", {})],
				"interpelle": [L("Attention, ça crépite !", {"visites_max": 0}), L("{surnom} ! Gardez vos distances, ça crépite.", {"visites_min": 1})],
			}},
		{"id": "celeste", "nom": "Céleste Lunette", "titre": "astronome de l'observatoire", "maison": "porte_observatoire",
			"agenda": [[10, 14, "promenade_lunette"], [14, 17, "cafe_table_4"], [17, 4, "observatoire"], [4, 10, "maison"]],
			"azur": {"cheveux": [0.5, 0.35, 0.6], "coiffure": "long", "haut": [0.12, 0.14, 0.3], "robe": [0.1, 0.12, 0.26], "robe_longue": true, "yeux": [0.4, 0.4, 0.6], "lunettes": true},
			"cq": {},
			"teinte": PEAU[0], "humeur_base": 0.2, "traits": {"bavard": 0.4, "humour": 0.3, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"boussole_sud": 1.5, "fleur_lune": 2.0, "perle": 1.5}, "deteste": {"lunettes_kaleido": -0.5},
			"repliques": {
				"accueil": [L("Chut… Je comptais les étoiles. Il y en a… j'ai perdu le compte. Bonsoir. Céleste Lunette, astronome. Je vis la nuit, je dors le jour, et je bois du café entre les deux.", {"visites_max": 1}), L("Vous revenez voir le ciel ? Il est magnifique, ce soir. Il l'est toujours.", {"visites_min": 2})],
				"humeur": [L("Rêveuse. Le jour, je suis rêveuse. La nuit, je suis éveillée.", {})],
				"lui": [L("J'ai découvert une étoile qui n'était sur aucune carte. Je l'ai appelée « Cliquetis ». Elle clignote. Comme tout ici.", {}), L("Depuis la lunette, j'ai vu une île flottante au-dessus des nuages, à l'ouest. Personne ne me croit. Vous, vous me croyez ?", {"sujet_min": ["lui", 1]})],
				"ile": [L("La nuit, sur le Cœur-de-Pierre, il y a une lueur bleue qui pulse, très lentement. Une fois par minute. Comme un cœur. Je l'ai notée deux cents nuits de suite.", {})],
				"rumeur": [L("Achille Plumevent vole si haut, parfois, que je le prends pour une comète. Une comète qui tousse.", {}, "rire")],
				"interpelle": [L("Regardez le ciel…", {"visites_max": 0}), L("{surnom}. Bonsoir.", {"visites_min": 1})],
			}},
		{"id": "rivet", "nom": "Maître Rivet", "titre": "constructeur de robots", "maison": "porte_fabrique",
			"agenda": [[7, 12, "fabrique_1"], [12, 13, "cafe_bar_2"], [13, 19, ["fabrique_1", "fabrique_2"]], [19, 22, "promenade_banc_3"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.3, 0.3, 0.32], "coiffure": "chauve", "barbe": "longue", "haut": [0.35, 0.3, 0.25], "tablier": [0.25, 0.18, 0.12], "yeux": [0.3, 0.3, 0.3], "carrure": 1.3, "vieux": true},
			"cq": {"lunettes_aviateur": true, "bras_mecanique": true},
			"teinte": PEAU[2], "humeur_base": 0.0, "traits": {"bavard": 0.3, "humour": 0.4, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.5},
			"aime": {"minerai_fer": 2.0, "canard_mecanique": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Hm. Maître Rivet. Les balayeurs, les porteurs, le majordome du café, le Colosse : c'est moi. Tous. Enfin, presque tous.", {"visites_max": 1}), L("Hm. Vous. Vous n'auriez pas vu un balayeur qui chante ?", {"visites_min": 2})],
				"humeur": [L("Hm. Comme un robot : constant.", {})],
				"lui": [L("Mes robots sont simples, solides, et ils ne discutent pas. Contrairement aux ingénieurs.", {}), L("Le Colosse, c'est mon chef-d'œuvre. Il devait garder la cité contre les tempêtes. Il a peur du tonnerre. Je n'ai pas encore trouvé pourquoi.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Il me faut du fer. Toujours du fer. Les bergers du nord en ont plein leurs collines et le vendent au compte-gouttes.", {})],
				"rumeur": [L("Héloïse dit que ses balayeurs sont meilleurs que les miens. Les siens chantent. C'est un défaut de fabrication.", {})],
				"interpelle": [L("Hm.", {"visites_max": 0}), L("{surnom}. Hm.", {"visites_min": 1})],
			}},
		# ================================================================ le café, le bazar
		{"id": "gaston", "nom": "Gaston Bielle", "titre": "patron du Café de la Bielle", "maison": "porte_cafe",
			"agenda": [[7, 23, "cafe_comptoir"], [23, 7, "maison"]],
			"azur": {"cheveux": [0.2, 0.15, 0.1], "coiffure": "court", "barbe": "moustache", "haut": [0.95, 0.94, 0.9], "tablier": [0.2, 0.3, 0.25], "yeux": [0.3, 0.25, 0.2], "carrure": 1.2},
			"cq": {"noeud_papillon": [0.1, 0.1, 0.1]},
			"teinte": PEAU[1], "humeur_base": 0.4, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"tasse_tourneuse": 2.5, "miel": 1.5}, "deteste": {"the_menthe": -0.3},
			"boutique": {"vend": {"cafe_vapeur": 3, "biscuit_engrenage": 4, "galette_sarrasin": 6}, "achete": {"miel": 4, "pomme": 2, "dattes": 3}},
			"repliques": {
				"accueil": [L("Bienvenue au Café de la Bielle ! Gaston. Café à vapeur, biscuits-engrenages, et des chambres à ressorts à l'étage. Le service, c'est le majordome. Il est lent, mais il ne fait jamais grève.", {"visites_max": 1}, "salut"), L("Un café, {surnom} ? Il sort de la chaudière.", {"visites_min": 2})],
				"humeur": [L("Sous pression ! Comme mon café.", {}, "rire")],
				"lui": [L("La machine à café, c'est un ancien moteur de locomotive. Elle fait quarante tasses à la minute, et elle siffle quand c'est prêt. Les clients sursautent. Ils reviennent quand même.", {}), L("Les chambres du dessus ont des lits à ressorts. Une invention d'Héloïse. On y dort très bien, quand on arrive à rester dedans.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("J'achète mon café aux caravaniers de Tazira, qui l'achètent à d'autres caravaniers. Il voyage plus que moi.", {})],
				"rumeur": [L("Le professeur Boum boit son café avec trois cuillères de poudre de fer. « Pour la réflexion », dit-il.", {}, "rire")],
				"interpelle": [L("Un café ?", {"visites_max": 0}), L("{surnom} ! Un café ?", {"visites_min": 1})],
			}},
		{"id": "bricolette", "nom": "Madame Bricolette", "titre": "marchande du Bazar des Inutilités", "maison": "porte_bazar",
			"agenda": [[9, 20, "bazar_comptoir"], [20, 23, "cafe_table_1"], [23, 9, "maison"]],
			"azur": {"cheveux": [0.55, 0.25, 0.6], "coiffure": "chignon", "haut": [0.45, 0.2, 0.5], "robe": [0.25, 0.12, 0.3], "robe_longue": true, "yeux": [0.4, 0.3, 0.5], "lunettes": true, "vieux": true},
			"cq": {"haut_de_forme": [0.3, 0.12, 0.35], "engrenage_chapeau": true},
			"teinte": PEAU[0], "humeur_base": 0.5, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"perle": 2.0, "piece_or": 2.0, "vieille_botte": 1.0}, "deteste": {},
			"boutique": {"vend": {"parapluie_helice": 18, "chapeau_ventilateur": 22, "montre_envers": 30, "boite_a_rien": 8, "canard_mecanique": 15, "tasse_tourneuse": 14, "lunettes_kaleido": 20, "chaussettes_vapeur": 12, "sifflet_muet": 6, "boussole_sud": 16},
				"achete": {"vieille_botte": 3, "coquillage": 2, "plume_corbeau": 4, "perle": 25, "piece_or": 45}},
			"repliques": {
				"accueil": [
					L("Entrez, entrez ! Bienvenue au Bazar des Inutilités ! Madame Bricolette. Ici, tout est inutile, et tout est merveilleux. Un parapluie à hélice ? Une boîte à rien ? Une boussole qui indique le sud ? Rien ne sert à rien, mais tout fait joli dans un sac !", {"visites_max": 1}, "rire"),
					L("Mon client préféré ! J'ai reçu un sifflet muet tout neuf. Écoutez… Vous entendez ? Non ? Parfait, il marche.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Merveilleuse ! J'ai vendu trois boîtes à rien ce matin. Les gens adorent ne rien avoir.", {}, "rire")],
				"lui": [L("Chaque inventeur de Cliquetis rate une invention sur deux. Les ratées, je les rachète. Ce sont les plus belles : elles ont essayé.", {}), L("Mon objet préféré ? La montre qui tourne à l'envers. Avec elle, on n'est jamais en retard : on est en avance dans l'autre sens.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Je vends aussi aux autres villes. Les pirates de Tazira m'ont acheté tous mes chapeaux-ventilateurs. Il fait chaud, au sud.", {})],
				"rumeur": [L("Les vieilles bottes, je les rachète. Pourquoi ? Pour rien. C'est le principe de la maison.", {}, "rire")],
				"interpelle": [L("Des merveilles inutiles !", {"visites_max": 0}), L("{surnom} ! Une curiosité ?", {"visites_min": 1})],
			}},
		# ================================================================ les transports
		{"id": "zelie", "nom": "Commandante Zélie Hélice", "titre": "commandante de l'aérodrome", "maison": "porte_maison_1",
			"agenda": [[7, 12, "aerodrome_1"], [12, 13, "cafe_bar_1"], [13, 20, "aerodrome_1"], [20, 23, ["promenade_vue_2", "cafe_table_2"]], [23, 7, "maison"]],
			"azur": {"cheveux": [0.35, 0.2, 0.12], "coiffure": "queue", "haut": [0.45, 0.3, 0.18], "yeux": [0.3, 0.45, 0.35]},
			"cq": {"casque_aviateur": [0.4, 0.26, 0.14], "lunettes_aviateur": true},
			"teinte": PEAU[2], "humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"boussole": 2.0, "parapluie_helice": 1.5}, "deteste": {"boussole_sud": -0.5},
			"repliques": {
				"accueil": [L("Commandante Zélie Hélice, aérodrome de Cliquetis ! Le Zéphyr fait le tour de l'île sans arrêt : Cliquetis, Tazira, Carène, et retour. Montez à bord quand il est posé, c'est gratuit. Les ingénieurs paient pour tout le monde.", {"visites_max": 1}, "salut"), L("Le Zéphyr arrive bientôt ! Ou il vient de partir. Il est toujours quelque part.", {"visites_min": 2}, "rire")],
				"humeur": [L("Dans les nuages, comme toujours.", {}, "rire")],
				"lui": [L("J'ai piloté le Zéphyr pendant dix ans. Maintenant, c'est mon frère qui pilote, et moi je reste au sol à m'inquiéter. C'est pire.", {}), L("Le Zéphyr flotte grâce à un gaz plus léger que l'air, qu'Héloïse fabrique dans une cuve. Elle refuse de me dire avec quoi. Ça sent un peu le chou.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Vu d'en haut, l'île ressemble à une feuille posée sur la mer, avec une pierre au milieu. Le Cœur-de-Pierre. On le survole à cent soixante mètres. En dessous, c'est plat comme une table, et rond comme une assiette.", {})],
				"rumeur": [L("Achille Plumevent a demandé à atterrir sur le Zéphyr. Refusé. Il vole tellement mal qu'il aurait crevé l'enveloppe.", {}, "rire")],
				"interpelle": [L("Le Zéphyr, par ici !", {"visites_max": 0}), L("{surnom} ! Un petit vol ?", {"visites_min": 1})],
			}},
		{"id": "adele", "nom": "Adèle Plumevent", "titre": "sœur de l'homme volant", "maison": "porte_maison_7",
			"agenda": [[9, 13, "aerodrome_banc"], [13, 15, "cafe_table_3"], [15, 19, ["aerodrome_banc", "promenade_lunette"]], [19, 22, "place_banc_1"], [22, 9, "maison"]],
			"azur": {"cheveux": [0.9, 0.78, 0.4], "coiffure": "long", "haut": [0.8, 0.6, 0.65], "robe": [0.5, 0.35, 0.45], "yeux": [0.3, 0.5, 0.6], "chapeau": "capeline", "chapeau_c": [0.9, 0.85, 0.75]},
			"cq": {},
			"teinte": PEAU[5], "humeur_base": 0.0, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"parapluie_helice": 2.0, "biscuit_engrenage": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Vous voyez ce petit point, là-haut, qui fait des huit ? C'est mon frère, Achille. Il a inventé des ailes à vapeur. Il vole depuis huit jours. Il ne sait pas comment atterrir. Je suis Adèle. Je l'attends.", {"visites_max": 1}), L("Toujours en l'air ! Je lui ai lancé un sandwich ce matin. Il l'a attrapé. Je suis fière.", {"visites_min": 2}, "rire")],
				"humeur": [L("Inquiète. Fière aussi. Surtout inquiète.", {})],
				"lui": [L("Achille a toujours voulu voler. Petit, il sautait du toit avec des parapluies. Maintenant, il a des ailes et une chaudière. Le progrès, c'est terrifiant.", {}), L("Le soir, il descend un peu, pour que je lui parle. Il dit que la vue est merveilleuse et qu'il a envie de faire pipi.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Achille dit que d'en haut, on voit tout : les moutons des bergers, les barques de Tazira, l'épave de Carène. Il dit même qu'il voit quelque chose qui brille au milieu du Cœur-de-Pierre.", {})],
				"rumeur": [L("Basile propose d'envoyer une bulle géante chercher Achille. Je ne suis pas sûre que ce soit une bonne idée.", {}, "rire")],
				"interpelle": [L("Vous voyez mon frère ?", {"visites_max": 0}), L("{surnom} ! Il est toujours là-haut.", {"visites_min": 1})],
			}},
		{"id": "ernest", "nom": "Ernest Câble", "titre": "gardien du téléphérique", "maison": "porte_maison_6",
			"agenda": [[6, 13, "telepherique_haut"], [13, 20, "telepherique_bas"], [20, 22, "cafe_bar_2"], [22, 6, "maison"]],
			"azur": {"cheveux": [0.4, 0.4, 0.42], "coiffure": "court", "barbe": "courte", "chapeau": "kepi", "chapeau_c": [0.15, 0.2, 0.3], "haut": [0.15, 0.2, 0.32], "yeux": [0.3, 0.3, 0.3], "vieux": true},
			"cq": {},
			"teinte": PEAU[2], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.3, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"montre_envers": 1.0, "cafe_vapeur": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Bonjour, bonjour ! Ernest, gardien du téléphérique. Deux cabines, un câble, quarante secondes du port à la cité. Montez quand la cabine est en gare, et ne vous penchez pas. Surtout, ne vous penchez pas.", {"visites_max": 1}, "salut"), L("Encore un tour ? La cabine rouge est plus rapide. Non, c'est faux, elles vont à la même vitesse. Mais la rouge est plus jolie.", {"visites_min": 2}, "rire")],
				"humeur": [L("Comme un câble : bien tendu.", {}, "rire")],
				"lui": [L("Avant le téléphérique, il y avait l'escalier. Quatre cent douze marches. Je les ai montées tous les jours pendant vingt ans. Maintenant, je regarde les gens monter en cabine, et je souris.", {}), L("Une fois, la cabine s'est arrêtée au milieu. Avec le maire de Port-Azur dedans. Il y est resté une heure. Il a écrit un poème. Il était très mauvais.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Il y a aussi la route, à l'est, qui descend en lacet jusqu'au port. Les porteurs-robots la prennent. Ils ont le vertige en cabine.", {})],
				"rumeur": [L("Gonzague, le grutier, garde tout ce qui tombe de la falaise. Il a même un piano. Personne ne sait comment il est arrivé là.", {})],
				"interpelle": [L("En voiture !", {"visites_max": 0}), L("{surnom} ! Une cabine ?", {"visites_min": 1})],
			}},
		# ================================================================ le port
		{"id": "gonzague", "nom": "Gonzague", "titre": "grutier du port", "maison": "porte_capitainerie_port",
			"agenda": [[7, 12, "port_grue"], [12, 14, "port_quai_2"], [14, 19, "port_grue"], [19, 22, "port_peche_1"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.2, 0.15, 0.12], "coiffure": "court", "barbe": "longue", "chapeau": "casquette", "chapeau_c": [0.3, 0.25, 0.2], "haut": [0.2, 0.3, 0.45], "yeux": [0.25, 0.3, 0.35], "carrure": 1.3},
			"cq": {},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"vieille_botte": 1.5, "sardine": 1.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Ho ! Gonzague, grutier. Je décharge les bateaux, et je ramasse tout ce qui tombe de la falaise. Et il en tombe, des choses, avec tous ces inventeurs là-haut.", {"visites_max": 1}, "salut"), L("Ho ! Encore vous. Rien de tombé aujourd'hui. Enfin, presque rien.", {"visites_min": 2})],
				"humeur": [L("Solide, comme ma grue.", {})],
				"lui": [L("Ma collection : une roue de locomotive, deux chapeaux-ventilateurs, un piano, et un robot balayeur qui chante encore. Il chante faux.", {}, "rire"), L("Il y a quelques jours, j'ai vu quelque chose de doré rouler du haut de la falaise et rebondir sur le quai, près de la grue. Ça brillait. Je n'ai pas eu le temps de le ramasser.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les barques des bergers viennent parfois ici, avec la laine. Les bateaux de Carène aussi, avec le cidre. Et le Petit Piston, mon remorqueur, n'a pas bougé depuis trois ans. Il est très bien comme ça.", {})],
				"rumeur": [L("Mademoiselle Écrou veut remettre le Petit Piston en marche. Je l'aime bien, mais je crois qu'il préfère dormir.", {})],
				"interpelle": [L("Ho !", {"visites_max": 0}), L("{surnom} ! Ho !", {"visites_min": 1})],
			}},
		{"id": "ecrou", "nom": "Mademoiselle Écrou", "titre": "mécanicienne du port", "maison": "porte_entrepot",
			"agenda": [[7, 12, "port_quai_3"], [12, 13, "port_quai_2"], [13, 19, ["port_quai_3", "port_quai_1"]], [19, 22, "port_peche_2"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.1, 0.08, 0.06], "coiffure": "queue", "haut": [0.25, 0.35, 0.5], "tablier": [0.3, 0.25, 0.2], "yeux": [0.3, 0.5, 0.35], "taille": 0.95},
			"cq": {"lunettes_aviateur": true},
			"teinte": PEAU[4], "humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"minerai_fer": 1.5, "chaussettes_vapeur": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Salut ! Mademoiselle Écrou. Mécanicienne. Je répare tout ce qui flotte, tout ce qui roule et tout ce qui siffle. En ce moment, j'essaie de réveiller le Petit Piston, le remorqueur.", {"visites_max": 1}, "salut"), L("Salut ! Le Petit Piston a toussé, ce matin. C'est bon signe. Ou très mauvais.", {"visites_min": 2}, "rire")],
				"humeur": [L("Graissée ! Euh, je veux dire : de bonne humeur.", {}, "rire")],
				"lui": [L("J'ai grandi dans une famille de bergers, sur les hautes terres. À huit ans, j'ai démonté le moulin du village. À neuf ans, ils m'ont envoyée à Cliquetis. Tout le monde était content.", {}, "rire"), L("Les bergers gardent un secret, dans une grotte sous la grande crête. Une pierre ronde, gravée. Mon grand-père disait que c'est une clé. Une clé pour une porte qu'on ne peut pas ouvrir.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les hautes terres, c'est chez moi : la bruyère, le vent, les moutons, la neige l'hiver. C'est rude, mais c'est beau. Et personne n'explose jamais rien.", {})],
				"rumeur": [L("Maître Rivet voudrait que je lui construise un bateau-robot. Un bateau qui se pilote tout seul. Je lui ai répondu : et moi, je fais quoi ?", {}, "rire")],
				"interpelle": [L("Salut !", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		# ================================================================ les promeneurs, les enfants
		{"id": "philibert", "nom": "Philibert Vis", "titre": "inventeur sans invention", "maison": "porte_maison_0",
			"agenda": [[9, 12, ["stand_client_1", "stand_client_2", "stand_client_3"]], [12, 14, "cafe_table_4"], [14, 18, ["machine_3", "stand_client_6", "stand_client_4"]], [18, 22, ["promenade_vue_1", "promenade_banc_2"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.55, 0.4, 0.25], "coiffure": "court", "haut": [0.55, 0.5, 0.42], "yeux": [0.3, 0.4, 0.3], "lunettes": true},
			"cq": {"haut_de_forme": [0.35, 0.25, 0.15]},
			"teinte": PEAU[0], "humeur_base": -0.1, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"boite_a_rien": 2.0, "sifflet_muet": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Bonjour… Philibert Vis. Inventeur. Enfin, presque. Toutes les idées que j'ai, quelqu'un les a déjà eues. Hier, j'ai inventé la roue. Elle existait déjà.", {"visites_max": 1}), L("Ah, vous ! J'ai eu une idée ! … Non. Elle existe déjà.", {"visites_min": 2}, "rire")],
				"humeur": [L("Plein d'espoir. Aujourd'hui, j'invente quelque chose de nouveau. Je le sens.", {})],
				"lui": [L("Ma meilleure invention, c'est la boîte à rien, au Bazar. Madame Bricolette dit qu'elle est parfaite, parce qu'elle ne peut pas tomber en panne.", {}, "rire")],
				"ile": [L("J'ai demandé au Zéphyr de m'emmener quelque part où personne n'a jamais rien inventé. Il m'a déposé à Carène. Ils ont inventé le cidre. Raté.", {}, "rire")],
				"rumeur": [L("Le jury de la Foire cherche des avis. Héloïse demande à tout le monde ce qu'ils pensent des inventions. Moi, j'ai toujours le même avis : je n'y avais pas pensé.", {})],
				"interpelle": [L("Une idée ?", {"visites_max": 0}), L("{surnom}…", {"visites_min": 1})],
			}},
		{"id": "rosette", "nom": "Rosette Engrenage", "titre": "chroniqueuse de la Gazette des Rouages", "maison": "porte_maison_11",
			"agenda": [[9, 12, ["machine_2", "stand_client_2", "stand_client_5"]], [12, 14, "cafe_table_1"], [14, 18, ["aerodrome_1", "volta_1", "stand_client_3"]], [18, 22, ["promenade_vue_2", "cafe_table_2"]], [22, 9, "maison"]],
			"azur": {"cheveux": [0.75, 0.3, 0.2], "coiffure": "carre", "haut": [0.9, 0.85, 0.7], "robe": [0.3, 0.45, 0.35], "yeux": [0.3, 0.5, 0.4], "chapeau": "beret", "chapeau_c": [0.3, 0.15, 0.2]},
			"cq": {},
			"teinte": PEAU[5], "humeur_base": 0.5, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"lunettes_kaleido": 2.0, "plume_corbeau": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Une nouvelle tête ! Rosette Engrenage, de la Gazette des Rouages. Je peux vous interviewer ? Qu'est-ce que vous pensez de Cliquetis ? Non, attendez, je note. Voilà. Allez-y.", {"visites_max": 1}, "rire"), L("Vous ! Vous êtes dans la Gazette de ce matin. Page quatre. « Un visiteur mystérieux ».", {"visites_min": 2}, "rire")],
				"humeur": [L("Curieuse ! Toujours curieuse.", {})],
				"lui": [L("La Gazette sort tous les matins, imprimée par une presse à vapeur qui rate une lettre sur cent. Les lecteurs jouent à les retrouver.", {}, "rire")],
				"ile": [L("Ma rubrique préférée : « Nouvelles des autres villes ». Hier : « À Tazira, un chat vole une carte au trésor. » Les gens n'y croient pas. C'est pourtant vrai.", {})],
				"rumeur": [L("Exclusivité : le professeur Boum prépare une explosion plus grande que toutes les autres. Il dit que ce sera « la bonne ». Rédaction en alerte.", {}), L("Titre de demain : « Achille Plumevent toujours en vol ». Comme hier. Comme avant-hier.", {}, "rire")],
				"interpelle": [L("Une interview ?", {"visites_max": 0}), L("{surnom} ! Une déclaration ?", {"visites_min": 1})],
			}},
		{"id": "leonce", "nom": "Léonce", "titre": "apprenti inventeur", "maison": "porte_maison_9",
			"agenda": [[8, 11, "place_enfants_1", ["place_enfants_2", "stand_client_4"]], [11, 13, "stand_client_3", ["stand_client_1"]], [13, 18, "place_enfants_2", ["place_enfants_1", "machine_3"]], [18, 21, "aerodrome_banc"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.85, 0.6, 0.3], "coiffure": "boucles", "haut": [0.85, 0.35, 0.2], "yeux": [0.3, 0.45, 0.6], "taille": 0.7},
			"cq": {"lunettes_aviateur": true},
			"teinte": PEAU[5], "humeur_base": 0.7, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"canard_mecanique": 2.5, "glace": 2.0, "biscuit_engrenage": 2.0}, "deteste": {"cafe_vapeur": -0.5},
			"repliques": {
				"accueil": [L("T'es un inventeur ? Moi oui ! Léonce, apprenti ! J'ai inventé une fusée. Elle n'a pas décollé. Mais elle a fait beaucoup de fumée !", {"visites_max": 1}, "rire"), L("Hé ! Tu veux voir ma nouvelle fusée ? Elle fait encore plus de fumée !", {"visites_min": 2}, "rire")],
				"humeur": [L("Super ! J'ai caressé Boulon !", {})],
				"lui": [L("Plus tard, je serai comme le professeur Boum. Ma mère dit que non. Elle dit « comme Héloïse ». C'est moins drôle.", {}), L("Avec Margot, on construit un robot dans la cave. Il s'appelle Bidule. Il ne marche pas encore. Il ne marchera peut-être jamais. Mais il a un nom.", {"sujet_min": ["lui", 1]})],
				"ile": [L("J'ai fait un tour en Zéphyr ! On voit tout d'en haut ! J'ai craché par la fenêtre. C'est interdit. Ne le dis pas.", {}, "rire")],
				"rumeur": [L("Le Colosse m'a fait coucou. Je te jure. Avec sa grosse main de fer.", {})],
				"interpelle": [L("T'es un inventeur ?", {"visites_max": 0}), L("{surnom} ! Viens voir !", {"visites_min": 1})],
			}},
		{"id": "margot", "nom": "Margot", "titre": "apprentie inventrice", "maison": "porte_maison_4",
			"agenda": [[8, 11, "place_enfants_2", ["place_enfants_1", "stand_client_2"]], [11, 13, "stand_client_2", ["stand_client_6"]], [13, 18, "place_enfants_1", ["place_enfants_2", "machine_1"]], [18, 21, "promenade_lunette"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.12, 0.08, 0.06], "coiffure": "queue", "haut": [0.3, 0.55, 0.85], "robe": [0.9, 0.75, 0.3], "yeux": [0.25, 0.35, 0.3], "taille": 0.68, "lunettes": true},
			"cq": {},
			"teinte": PEAU[3], "humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"lunettes_kaleido": 2.5, "glace": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Bonjour. Margot. J'ai huit ans et demi et je suis ingénieure. Enfin, apprentie. Léonce fait les fusées, moi je fais les calculs. Sans moi, ses fusées feraient encore plus de fumée.", {"visites_max": 1}), L("Bonjour. Tu as réfléchi au problème du moteur perpétuel ? Moi oui. C'est impossible. Ne le dis pas à monsieur Cogne.", {"visites_min": 2}, "rire")],
				"humeur": [L("Logique.", {}, "rire")],
				"lui": [L("Je veux être astronome, comme Céleste. Ou ingénieure-en-chef, comme Héloïse. Ou les deux. Je calcule le temps qu'il faut.", {})],
				"ile": [L("J'ai calculé que le Zéphyr met trois minutes et douze secondes pour aller de Cliquetis à Tazira. Avec le vent dans le dos, trois minutes. Avec Achille devant, quatre.", {}, "rire")],
				"rumeur": [L("Monsieur Cogne cherche un engrenage. Gonzague, au port, a vu quelque chose de doré près de la grue. J'ai additionné les deux.", {})],
				"interpelle": [L("Bonjour.", {"visites_max": 0}), L("{surnom}. Bonjour.", {"visites_min": 1})],
			}},
	]


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out

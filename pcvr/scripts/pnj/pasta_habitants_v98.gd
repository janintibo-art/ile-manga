extends RefCounted
## V98 : les adeptes de l'Église du Grand Spaghetti Volant, sur l'Île Al Dente. En entrant dans
## l'Église, chacun a choisi un nom de pâte (« c'est plus facile à retenir, et ça donne faim »).
## Ils terminent leurs prières par « Ramen ! », portent une passoire sur la tête les jours de fête
## (et les autres jours aussi), et vénèrent les pirates (« les premiers pastafariens »).
##  - le Temple-Passoire : le Révérend Père Farfalle (le grand prêtre, très solennel, très distrait),
##    Sœur Penne (la cheffe de chœur, qui chante faux mais très fort) et Frère Linguini (le novice,
##    maladroit, la passoire trop grande lui tombe sur les yeux) ;
##  - le Couvercle Sacré : Macaroni (le gardien du gong, qui compte les coups : « jamais trois ! ») ;
##  - le Borgo des Coquillettes (le hameau, la Grande Tablée, le four) : Mamma Lasagna (les pâtes
##    fraîches, le four à pain), Nonno Tortellini (le paysan du blé dur, qui jure que le Spaghetti lui
##    a fait un clin d'œil en 1987) et leur petit-fils Gnocchi (8 ans) ;
##  - la Tomateraie : Signorina Ravioli (elle chante pour ses tomates) ;
##  - le parvis : Tagliatelle (la peintre des bannières, violoniste de la tarentelle du soir) et la
##    Professeure Fusilli (la théologienne-savante, qui mesure le Spaghetti avec un double mètre) ;
##  - la Marmite, en haut du Mont Bolognaise : Bucatini (le gardien de la sauce, qui la goûte tous
##    les jours : « il manque un peu de sel ») ;
##  - la Plage du Parmesan : le Capitaine Rigatoni (un vieux pirate à la retraite, sa barque
##    retournée, son perroquet Pesto, son trésor enterré).
## La quête « Le Grand Spaghetti boude » (journal_v56) : le Plat de la Grande Réconciliation.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure (les lieux :
## pasta_ville_v98.gd) ; la passoire, le cache-œil, le perroquet, les objets : pnj_pasta_v98.gd.
## Fiche « pasta » : tenue, c, c2 (les couleurs de la tenue), chapeau, passoire (la passoire sur la
## tête : "" / "simple" / "doree" / "grande"), props (cache_oeil, perroquet), objet.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Que Ses Nouilles te protègent, {surnom}. Ramen !", "si": {}, "geste": "salut"},
		{"t": "Va en paix, et ne casse jamais tes spaghettis en deux.", "si": {}, "geste": "salut"},
		{"t": "À plus tard, {surnom} ! Reviens pour la Grande Tablée : il y en aura pour tout le monde.", "si": {}},
		{"t": "Arrivederci ! Et garde un œil sur le volcan : il a mauvais caractère, ces temps-ci.", "si": {}, "geste": "salut"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! La Sixième Recommandation dit : on ne tape pas les gens. Même pas avec une baguette de pain.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu es trop cuit, toi. Va te refroidir à l'eau froide.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Ça ne se fait pas ! Le Grand Spaghetti Volant voit tout, tu sais. Il a deux yeux, et ils sont très grands.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Oh, merci, {surnom}. Ce n'est pas des pâtes, mais c'est gentil quand même.", "si": {}},
		{"t": "Un cadeau ! Que Ses Nouilles te le rendent au centuple. Ramen.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Oh, {surnom}, c'est un signe ! Un signe des Nouilles ! Ramen !", "si": {}, "geste": "rire"},
		{"t": "{dernier_cadeau} ! Merci, merci ! Je savais que tu avais bon goût. Tu as la sauce dans le cœur.", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Hum… merci. Je vais le… mettre de côté. Très loin de la marmite.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Ici ? Non, non. Ici, on se bat seulement pour la dernière boulette. Et encore, on partage.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Le Grand Spaghetti n'oublie personne, et nous non plus.", "si": {}}],
	"quete_inconnue": [{"t": "Moi ? Je ne t'ai rien demandé… Mais le Révérend Père Farfalle, au Temple-Passoire, a l'air bien soucieux, ces jours-ci.", "si": {}}],
	"blague": [
		{"t": "Pourquoi les spaghettis ne se perdent jamais ? Parce qu'ils suivent toujours le fil !", "si": {}, "geste": "rire"},
		{"t": "Que dit une nouille qui arrive en retard ? « Désolée, j'ai été retenue… à la passoire. »", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qui est jaune, qui flotte dans le ciel et qui fait « miam » ? Le Grand Spaghetti Volant après la Grande Tablée !", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on une pâte qui fait du sport ? Une pâte… brisée ! Non, attends, ça, c'est une tarte.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi le volcan est-il toujours de bonne humeur ? Parce qu'il a la sauce qui monte !", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Choisis, choisis ! Tout est fait à la main et béni par les Nouilles. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Reviens quand on sera de nouveau amis.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Buon appetito !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu en as {pieces}. Repasse plus tard, je te le garde au chaud.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un !", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein comme une marmite, {surnom}.", "si": {}}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et une bénédiction en plus.", "si": {}}],
	"marchande_oui": [{"t": "Bon, d'accord. Le Grand Spaghetti aime les gens généreux. Et les gens qui marchandent. Un peu.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Non, non. Mes prix sont al dente : ni trop, ni trop peu.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui. Demain, peut-être, si le volcan est de bonne humeur.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Ramen !", "Mamma mia !", "Ha ha !", "Que c'est bon !"],
		"neutre": ["Bon.", "Hm.", "Allora…", "Voyons…"],
		"triste": ["Bof…", "Pfff…", "Ma che…", "Aïe aïe aïe…"],
		"colere": ["Basta !", "Grrr.", "Ça suffit !", "Ma insomma !"],
	},
	"tics": ["Ramen.", "Par Ses Nouilles !", "Al dente, toujours.", "Que la sauce soit avec toi."],
	"humeur_mots": [[0.6, "al dente"], [0.25, "de bonne humeur"], [-0.25, "un peu trop cuit"], [-0.6, "en bouillie"], [-2.0, "complètement brûlé"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "frère de sauce"], [75, "ami des Nouilles"], [95, "pastafarien d'honneur"]],
}

## Peaux, cheveux, yeux
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24]]
const NOIR := [0.06, 0.05, 0.05]
const BRUN := [0.25, 0.16, 0.1]
const CHATAIN := [0.38, 0.24, 0.14]
const ROUX := [0.62, 0.28, 0.12]
const BLOND := [0.86, 0.72, 0.42]
const BLANC := [0.93, 0.92, 0.9]
const GRIS := [0.62, 0.61, 0.6]
const Y_BRUN := [0.3, 0.18, 0.1]
const Y_NOIR := [0.14, 0.1, 0.08]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BLEU := [0.3, 0.45, 0.62]
const Y_NOISETTE := [0.42, 0.3, 0.14]
## Les couleurs de l'île : la pâte, la tomate, le basilic, la crème, le parmesan
const PATE := [0.95, 0.82, 0.45]
const TOMATE := [0.78, 0.12, 0.08]
const BASILIC := [0.2, 0.45, 0.18]
const CREME := [0.94, 0.9, 0.8]
const PARMESAN := [0.96, 0.9, 0.66]
const OR := [0.9, 0.7, 0.25]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			rep[k] = (COMMON[k] as Array).duplicate(true)
	out["repliques"] = rep
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = BASE[k]
	out = Azur.complete(out)
	out["groupe"] = "pasta"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Temple-Passoire
		{"id": "farfalle", "nom": "Révérend Père Farfalle", "titre": "grand prêtre de l'Église du Grand Spaghetti Volant", "maison": "porte_presbytere", "village": "pasta",
			"agenda": [[6, 9, "autel"], [9, 12, "statue"], [12, 14, "tablee_1"], [14, 17, "pupitre"], [17, 19, "autel"], [19, 21, "tablee_1"], [21, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BLEU, "haut": CREME, "vieux": true, "carrure": 1.1},
			"teinte": PEAU[1],
			"pasta": {"tenue": "pretre", "c": CREME, "c2": TOMATE, "passoire": "doree", "objet": "louche"},
			"humeur_base": 0.45, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"spaghettis_bolo": 2.5, "spaghettis_secs": 2.0, "sauce_volcan": 2.0, "focaccia": 1.5, "tomate_coeur": 1.0}, "deteste": {"nouilles_neo": -0.5},
			"tics": ["Ramen.", "Par Ses Nouilles…", "Hum, hum. Où en étais-je ?", "C'est écrit dans les Recommandations."],
			"surnoms": [[0, "mon enfant"], [25, "mon cher enfant"], [50, "frère de sauce"], [75, "fidèle parmi les fidèles"], [95, "Touché par l'Appendice Nouilleux"]],
			"repliques": {
				"accueil": [
					L("Bienvenue, mon enfant, bienvenue sur l'Île Al Dente ! Je suis le Révérend Père Farfalle, grand prêtre de l'Église du Grand Spaghetti Volant. (Il ajuste la passoire dorée qu'il porte sur la tête.) Ceci ? C'est ma mitre. Elle égoutte aussi très bien les idées. Ramen.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Quelle joie. Le Grand Spaghetti t'attendait. Enfin, je crois. Il ne parle pas beaucoup, mais il cligne des yeux, et c'est déjà beaucoup.", {"visites_min": 2}, "rire"),
					L("{surnom}… Ah, {surnom}. Tu as vu, là-haut ? Ses nouilles pendent. Ses yeux sont mi-clos. Il boude. Le Grand Spaghetti boude, et je ne sais plus quoi faire.", {"visites_min": 2, "q56": "pa_plat_sacre="}),
					L("{surnom} ! Il danse ! Il danse encore ! Depuis la Grande Réconciliation, il n'arrête plus de frétiller. Hier, il m'a fait coucou avec une nouille. J'ai pleuré dans ma passoire.", {"visites_min": 2, "q56": "pa_plat_sacre=finie"}, "rire"),
				],
				"humeur": [
					L("Soucieux, mon enfant. Très soucieux. Le Grand Spaghetti boude, le volcan gronde plus que d'habitude, et Frère Linguini a encore cassé une assiette. La troisième de la semaine. On est mardi.", {"q56": "pa_plat_sacre="}),
					L("Comme une farfalle : un peu froissé au milieu, mais avec deux belles ailes de chaque côté.", {}, "rire"),
					L("Le soir, quand le soleil se couche derrière le Mont Bolognaise, la sauce brille comme de l'or rouge. C'est l'heure où je prie le mieux. Et où j'ai le plus faim.", {"soir": true}),
					L("Radieux ! Le Grand Spaghetti a retrouvé sa bonne humeur. Il frétille, il cligne, il fait des petits nœuds avec ses nouilles. Ramen, ramen, et encore ramen !", {"q56": "pa_plat_sacre=finie"}, "rire"),
				],
				"lui": [
					L("Avant, j'étais cuisinier sur un grand bateau. Un soir de tempête, j'ai fait tomber une énorme marmite de spaghettis. Elle s'est renversée sur le pont, et les spaghettis ont dessiné… un visage. Avec deux boulettes pour les yeux. Il me regardait. Il m'a souri. J'ai su que ma vie venait de changer.", {}),
					L("Pourquoi Farfalle ? Parce que les farfalle ressemblent à des papillons. Et qu'un papillon, ça va où le vent le pousse, comme un prêtre va où les Nouilles le poussent. Et aussi parce que « Révérend Père Spaghetti », c'était déjà pris. Par le Spaghetti.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma passoire dorée, c'est celle du premier repas du temple. Elle a égoutté les spaghettis de la toute première Grande Tablée. Je ne l'ai jamais lavée. Enfin, si. Mais avec respect.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Huit Recommandations sont écrites au pupitre, dans le temple. Ce ne sont pas des ordres, mon enfant, ce sont des « je préférerais vraiment que tu ne… ». Le Grand Spaghetti est très poli.", {}),
					L("Le Temple-Passoire est la plus grande passoire du monde. Quand il pleut, il pleut dedans. C'est voulu. La pluie, c'est l'eau des pâtes du ciel.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Couvercle Sacré, sur le parvis : on le frappe pour appeler les fidèles. Une fois, c'est la prière. Deux fois, c'est le repas. Trois fois… Trois fois, on ne le frappe pas. Demande à Macaroni pourquoi. Non, ne lui demande pas, il va te faire un discours d'une heure.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Grand Spaghetti boude depuis une semaine. Ses nouilles pendent, ses yeux sont mi-clos… Il y a une recette, dans les vieux livres, pour le réconcilier avec nous. Mais il me faudrait de l'aide. Beaucoup d'aide.", {"q56": "pa_plat_sacre="}),
					L("On dit que le Capitaine Rigatoni a enterré un trésor sur la plage il y a trente ans. Il dit que non. Puis il fait un clin d'œil. Avec l'œil qui n'a pas de cache-œil, heureusement.", {}),
					L("La Professeure Fusilli dit que le Grand Spaghetti mesure exactement cent douze nouilles de long. Je ne sais pas comment on mesure en nouilles. Mais j'ai la foi.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Mon enfant ! Viens, viens, approche. Les Nouilles t'appellent.", {"visites_max": 0}, "salut"), L("{surnom} ! Ramen !", {"visites_min": 1}, "salut")],
			}},
		{"id": "penne", "nom": "Sœur Penne", "titre": "cheffe du chœur du Temple-Passoire", "maison": "porte_soeurs", "village": "pasta",
			"agenda": [[7, 9, "choeur_1"], [9, 12, ["banc_1", "banc_2"]], [12, 14, "tablee_2"], [14, 17, "choeur_1"], [17, 19, "fontaine_1"], [19, 21, "tablee_2"], [21, 7, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "chignon", "yeux": Y_NOISETTE, "haut": TOMATE, "carrure": 1.05},
			"teinte": PEAU[2],
			"pasta": {"tenue": "soeur", "c": TOMATE, "c2": CREME, "passoire": "simple"},
			"femme": true,
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"partition": 2.5, "tomate_coeur": 1.5, "focaccia": 1.5, "miel": 1.5, "the_menthe": 1.0}, "deteste": {"sifflet_muet": -1.0},
			"tics": ["Do-ré-mi-ramen !", "On reprend au refrain !", "Plus fort !", "Ah, la belle note."],
			"surnoms": [[0, "petit soliste"], [25, "voix d'or"], [50, "mon ténor"], [75, "ma plus belle voix"], [95, "soliste du Grand Spaghetti"]],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Sœur Penne, cheffe du chœur ! Tu chantes ? Tout le monde chante ! Même ceux qui ne savent pas. SURTOUT ceux qui ne savent pas : le Grand Spaghetti aime le bruit. (Elle chante une gamme, très fort et un peu faux.) Do-ré-mi-fa-sol-la-si-RAMEN !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien, il me manque une voix grave pour le Cantique de la Boulette. Non ? Une voix aiguë, alors ? N'importe quelle voix ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("En pleine forme ! J'ai chanté le Grand Cantique des Nouilles ce matin, les sept couplets. Trois oiseaux se sont envolés. Ça veut dire que c'était puissant.", {}, "rire"),
					L("Un peu enrouée. Le Grand Spaghetti boude, alors je chante plus fort pour le consoler. Ça ne marche pas. Il ferme encore plus les yeux. Peut-être que ce n'est pas la bonne chanson.", {"q56": "pa_plat_sacre="}),
					L("Le soir, quand Tagliatelle sort son violon et Macaroni son tambourin, tout le Borgo danse la tarentelle. Même Nonno Tortellini. Surtout Nonno Tortellini.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Avant, je chantais à l'opéra. Dans le chœur, au dernier rang. Personne ne m'entendait. Ici, tout le monde m'entend. Même les gens de Néopolis, quand le vent souffle vers l'est.", {}, "rire"),
					L("Pourquoi Penne ? Parce que les penne sont des petits tuyaux. Et moi, j'ai du coffre, des poumons, des tuyaux ! Do-o-o-o !", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je partage ma maison avec Tagliatelle. Elle peint, je chante. Elle dit que je chante faux. Je dis qu'elle peint de travers. On a toutes les deux raison, et on s'adore.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Dans le temple, la voix résonne sous la passoire, et elle ressort par les mille trous. C'est le seul endroit du monde où on peut chanter en mille morceaux à la fois.", {}),
					L("La Grande Tablée, au Borgo, c'est deux fois par jour : à midi et le soir. Tout le monde mange ensemble, à la même table. Avant de manger, on chante. C'est moi qui donne le la. Et c'est souvent un si.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Frère Linguini a encore fait sonner le Couvercle trois fois de suite. Le volcan a craché de la sauce sur le linge de Mamma Lasagna. Elle l'a poursuivi avec son rouleau à pâtisserie autour du Borgo. Deux fois.", {}, "rire"),
					L("Il paraît que la Professeure Fusilli a calculé la note préférée du Grand Spaghetti. Un « fa ». Depuis, je ne chante plus que des fa. Les autres sont un peu fatigués.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Toi ! Tu veux chanter avec nous ? Do-ré-mi-RAMEN !", {}, "salut")],
			}},
		{"id": "linguini", "nom": "Frère Linguini", "titre": "novice du Temple-Passoire", "maison": "porte_ravioli", "village": "pasta",
			"agenda": [[7, 11, "parvis_balai"], [11, 12, "sechoir_2"], [12, 14, "tablee_3"], [14, 17, ["parvis_balai", "fontaine_2"]], [17, 19, "banc_3"], [19, 21, "tablee_3"], [21, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "yeux": Y_VERT, "haut": [0.82, 0.72, 0.52], "taille": 1.04},
			"teinte": PEAU[0],
			"pasta": {"tenue": "novice", "c": [0.82, 0.72, 0.52], "c2": [0.55, 0.38, 0.2], "passoire": "grande", "objet": "balai"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.8, "curiosite": 0.9, "susceptible": 0.6, "rancunier": 0.0},
			"aime": {"focaccia": 2.0, "glace": 2.5, "spaghettis_bolo": 2.0, "pomme": 1.0}, "deteste": {"caillou": -0.5},
			"tics": ["Oups.", "C'est pas moi !", "Je range tout de suite !", "Hein ? Quoi ? J'étais réveillé !"],
			"surnoms": [[0, "toi"], [25, "mon copain"], [50, "mon grand copain"], [75, "mon meilleur copain"], [95, "mon héros"]],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour ! Frère Linguini, novice du temple, pour vous servir ! (Il s'incline. Sa passoire, beaucoup trop grande, lui glisse sur le nez.) … Pardon. Elle est à ma taille, c'est moi qui ne suis pas encore à la sienne. Le Révérend dit que je vais grandir dedans.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu ne dis à personne que tu m'as vu dormir sur le banc, hein ? Je méditais. Les yeux fermés. Très fort.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bien ! Je n'ai cassé que deux assiettes aujourd'hui. C'est un record. Un record vers le bas, mais un record.", {}, "rire"),
					L("Un peu inquiet. Le Grand Spaghetti boude, et j'ai peur que ce soit à cause de moi. La semaine dernière, j'ai éternué pendant la prière. Sur l'assiette éternelle.", {"q56": "pa_plat_sacre="}),
					L("Content ! Le Grand Spaghetti a recommencé à danser, et le Révérend m'a dit que ce n'était pas du tout de ma faute. Enfin, il a dit « presque pas ». Mais c'est pareil.", {"q56": "pa_plat_sacre=finie"}, "rire"),
				],
				"lui": [
					L("Je suis arrivé ici il y a un an, sur un bateau de pêche. Je cherchais ma vocation. J'avais essayé boulanger, facteur, gardien de phare. Ici, au premier repas, on m'a donné une assiette de spaghettis et une passoire. J'ai su que j'étais chez moi.", {}),
					L("Ma sœur, c'est Signorina Ravioli, à la Tomateraie. Elle parle aux tomates. Moi, je parle aux balais. Chacun sa famille.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon balai est en spaghettis secs. C'est moi qui l'ai fabriqué. Il balaie très mal. Mais il sent bon le blé, et quand il est trop usé, on le fait cuire.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le parvis, je le balaie tous les matins. Tous les matins, le vent ramène le sable de la plage. C'est un travail sans fin. Le Révérend dit que c'est le but. Je ne suis pas sûr d'avoir compris.", {}),
					L("Le Couvercle Sacré, il ne faut JAMAIS le frapper trois fois. Je le sais. Je le sais très bien. Je l'ai appris… de la manière difficile. Trois fois.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Psst. Le Capitaine Rigatoni a une vieille carte au trésor dans sa barque. Je l'ai vue ! Elle est toute tachée de sauce. Enfin, j'espère que c'est de la sauce.", {}),
					L("Gnocchi veut devenir novice comme moi. Je lui ai dit qu'il fallait d'abord grandir. Il a mis une passoire encore plus grande que la mienne. On ne le voit plus du tout.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Attention, ça glisse ! Enfin, ça va glisser. Dès que j'aurai renversé le seau.", {}, "rire")],
			}},
		{"id": "macaroni", "nom": "Macaroni", "titre": "gardien du Couvercle Sacré", "maison": "porte_gardiens", "village": "pasta",
			"agenda": [[7, 12, "gong"], [12, 14, "tablee_4"], [14, 20, "gong"], [20, 22, "piazza_tambour"], [22, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.3, 0.32, 0.22], "carrure": 1.2},
			"teinte": PEAU[3],
			"pasta": {"tenue": "gardien_gong", "c": [0.3, 0.32, 0.22], "c2": OR, "chapeau": "kepi", "tambourin": true},
			"humeur_base": 0.35, "traits": {"bavard": 0.6, "humour": 0.3, "curiosite": 0.3, "susceptible": 0.7, "rancunier": 0.4},
			"aime": {"spaghettis_bolo": 2.0, "cloche": 2.0, "piece_or": 1.5, "focaccia": 1.5}, "deteste": {"sifflet_muet": -0.5},
			"tics": ["Une fois, c'est la prière.", "Deux fois, c'est le repas.", "Jamais trois.", "Je compte."],
			"repliques": {
				"accueil": [
					L("Halte ! Macaroni, gardien du Couvercle Sacré. Une fois : la prière. Deux fois : le repas. Trois fois : JAMAIS. Tu as compris ? Répète. … Bien. Tu peux passer.", {"visites_max": 1}),
					L("{surnom}. Je t'ai à l'œil. Et l'autre œil, je l'ai sur le Couvercle.", {"visites_min": 2}),
					L("{surnom} ! Tu as frappé trois fois. TROIS FOIS. J'ai compté. Le volcan a compté aussi. Va falloir t'excuser auprès de Mamma Lasagna, son linge est tout rouge.", {"visites_min": 2, "a_trouve": "pasta_eruption"}, "colere"),
				],
				"humeur": [
					L("Vigilant. Toujours vigilant. Le Couvercle ne se garde pas tout seul.", {}),
					L("Fatigué. Frère Linguini est passé quatre fois devant le Couvercle avec son balai. Quatre fois, j'ai cru qu'il allait taper dedans. Quatre fois, j'ai eu peur.", {}),
					L("Le soir, je pose le Couvercle et je prends mon tambourin. On ne garde pas un gong pendant la tarentelle. Le gong, il danse aussi, dans sa tête.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Avant, j'étais garde-barrière. Une barrière, un train, deux fois par jour. Je ne me suis jamais trompé. Ici, c'est pareil : un Couvercle, deux coups par jour. Le métier, c'est de compter.", {}),
					L("Mon cousin Bucatini garde la Marmite, en haut. Moi, je garde le Couvercle, en bas. Il dit que le plus important, c'est la Marmite. Je dis que sans Couvercle, la Marmite déborde. On en discute tous les dimanches. Depuis onze ans.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Pourquoi pas trois fois ? Parce que trois coups, le Mont Bolognaise les entend. Et il croit qu'on l'appelle pour le dîner. Alors il se réveille, et il envoie la sauce. Partout.", {}),
					L("Le Couvercle Sacré est le couvercle de la toute première marmite de l'île. Il est en cuivre. Il fait BOOONG. Les autres couvercles font « tic ». C'est toute la différence.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Gnocchi tourne autour du Couvercle avec une cuillère en bois. Je le surveille. Une cuillère en bois, ça commence par un « tic », et ça finit par un BOOONG.", {}),
				],
				"interpelle": [L("Toi. Pas plus de deux coups. Je compte.", {})],
			}},
		# ================================================================ le Borgo des Coquillettes
		{"id": "lasagna", "nom": "Mamma Lasagna", "titre": "faiseuse de pâtes fraîches du Borgo", "maison": "porte_famille", "village": "pasta",
			"agenda": [[6, 8, "four"], [8, 12, "sechoir_1"], [12, 14, "four"], [14, 18, "sechoir_1"], [18, 20, "four"], [20, 21, "tablee_5"], [21, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.3, 0.22, 0.32], "vieux": true, "carrure": 1.25, "taille": 0.95},
			"teinte": PEAU[2],
			"pasta": {"tenue": "mamma", "c": [0.3, 0.22, 0.32], "c2": TOMATE, "chapeau": "foulard"},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"tomate_coeur": 2.0, "spaghettis_secs": 1.5, "miel": 2.0, "fromage_chevre": 2.0, "sauce_volcan": 1.5}, "deteste": {"nouilles_neo": -1.0, "soda_neon": -0.5},
			"tics": ["Mangia, mangia !", "Tu es tout maigre.", "Ma che…", "Une petite assiette ?"],
			"surnoms": [[0, "mon petit"], [25, "mon chou"], [50, "mon petit raviolo"], [75, "mon trésor"], [95, "mon petit-enfant de cœur"]],
			"boutique": {"vend": {"focaccia": 4, "spaghettis_bolo": 9}, "achete": {"tomate_coeur": 3, "spaghettis_secs": 4, "sauce_volcan": 3, "miel": 4, "fromage_chevre": 5}},
			"repliques": {
				"accueil": [
					L("Oh ! Un nouveau ! Viens là, viens là, que je te regarde. Tu es tout maigre ! Moi, c'est Mamma Lasagna. Je fais les pâtes de toute l'île, à la main, depuis quarante ans. Mangia, mangia ! Assieds-toi, je t'apporte une assiette. Non, deux.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as mangé ? Tu n'as pas mangé. Je le vois. Ça se voit tout de suite, quand quelqu'un n'a pas mangé.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien, bien. La pâte a bien levé, le soleil sèche bien les tagliatelles, et personne n'a cassé de spaghettis en deux aujourd'hui. Personne que je connaisse.", {}),
					L("Fâchée ! Le volcan a craché sur mon linge. Encore ! Mes draps sont tout rouges. Bon, ils sentent bon. Mais quand même !", {"a_trouve": "pasta_eruption"}, "colere"),
					L("Le soir, c'est moi qui fais le four. Les focaccias sortent toutes dorées, et l'odeur fait le tour de l'île. Même le Grand Spaghetti ouvre un œil.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Ma nonna m'a appris la pâte quand j'avais cinq ans. Farine, œufs, et les mains. Pas de machine ! La machine, elle ne sait pas si la pâte est triste. Moi, je le sens.", {}),
					L("Mon mari, c'est Nonno Tortellini. Il fait pousser le blé, je fais les pâtes. Lui, il dit que sans son blé, pas de pâtes. Moi, je dis que sans mes pâtes, son blé, c'est de l'herbe. On ne s'est jamais disputés. Enfin, jamais longtemps.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon petit-fils, Gnocchi, il est tout rond et tout doux, comme un vrai gnocchi. Il veut être pirate, novice, chanteur et volcan. Je lui ai dit : d'abord, finis ton assiette.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Séchoir, là-bas, c'est mon trésor. Les spaghettis sèchent au vent de la mer, ils prennent le sel et le soleil. Les pâtes de Néopolis, elles sèchent dans une machine. On sent la différence. Moi, je la sens.", {}),
					L("La Grande Tablée, c'est sacré. Midi et soir, tout le monde à table. Celui qui mange seul, il mange deux fois moins bien. C'est la Recommandation numéro neuf. Il n'y en a que huit, mais celle-là, c'est la mienne.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Le Révérend tourne en rond dans son temple. Il dit que le Grand Spaghetti boude. Moi, je dis : un spaghetti qui boude, c'est un spaghetti qui a faim. Mais personne ne m'écoute.", {"q56": "pa_plat_sacre="}),
					L("La Professeure Fusilli a voulu peser mes pâtes au milligramme. Je l'ai laissée faire. Puis je lui ai servi une assiette. Elle a arrêté de peser.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Toi ! Tu as faim ? Bien sûr que tu as faim !", {"visites_max": 0}, "salut"), L("{surnom} ! Mangia !", {"visites_min": 1})],
			}},
		{"id": "tortellini", "nom": "Nonno Tortellini", "titre": "paysan du blé dur", "maison": "porte_famille", "village": "pasta",
			"agenda": [[6, 11, "champ_1"], [11, 12, "piazza_banc_1"], [12, 14, "tablee_6"], [14, 17, ["champ_2", "oliviers"]], [17, 20, "piazza_banc_1"], [20, 21, "tablee_6"], [21, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.92, 0.88, 0.78], "vieux": true, "taille": 0.93},
			"teinte": PEAU[3],
			"pasta": {"tenue": "paysan", "c": [0.92, 0.88, 0.78], "c2": [0.4, 0.3, 0.2], "chapeau": "paille", "objet": "fourche"},
			"humeur_base": 0.5, "traits": {"bavard": 0.7, "humour": 0.8, "curiosite": 0.3, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"graines": 2.5, "focaccia": 2.0, "pomme": 1.5, "miel": 1.5}, "deteste": {"soda_neon": -1.0},
			"tics": ["En 1987…", "Le blé, ça ne ment pas.", "Hé hé hé.", "Moi, je l'ai vu."],
			"surnoms": [[0, "petit"], [25, "fiston"], [50, "mon gars"], [75, "mon brave"], [95, "mon petit-fils de cœur"]],
			"repliques": {
				"accueil": [
					L("Ah, un jeunot ! Nonno Tortellini, paysan. Tout le blé de l'île, c'est moi. Du blé dur, le meilleur. Tu sais pourquoi on l'appelle « dur » ? Parce qu'il faut être dur pour le faire pousser. Hé hé hé.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens t'asseoir. Je vais te raconter 1987. Tu connais déjà ? Je te la raconte quand même.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Le blé est beau, le soleil est chaud, et Lasagna m'a gardé la dernière focaccia. La vie est bonne.", {}),
					L("Mon dos craque comme un spaghetti sec. Mais le blé, lui, il pousse droit. On ne peut pas tout avoir.", {}, "rire"),
				],
				"lui": [
					L("En 1987, j'étais dans mon champ. Il faisait chaud. J'ai levé les yeux. Et là, le Grand Spaghetti m'a fait un clin d'œil. Avec l'œil gauche. Personne ne me croit. Mais moi, je l'ai vu.", {}),
					L("Lasagna et moi, on s'est rencontrés à un concours de pâtes. Elle a gagné. J'ai fini dernier. Je lui ai demandé sa recette. Elle m'a dit : « Épouse-moi, et tu la mangeras tous les jours. » C'était il y a cinquante ans. Je mange toujours.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Gnocchi, mon petit-fils, il veut tout faire. Pirate, novice, chanteur. Je lui ai dit : sois paysan. Les paysans, ils se lèvent tôt, mais ils voient le soleil se lever sur le blé. Il m'a dit que c'était trop tôt.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le blé dur aime le soleil, le vent de la mer et un peu de cendre du volcan. Le Mont Bolognaise, c'est notre engrais. Il crache, ça retombe, ça pousse.", {}),
					L("Les oliviers, à l'est, ils ont trois cents ans. Ils étaient là avant le temple, avant le Borgo, avant moi. Je leur dis bonjour tous les après-midi. Ils ne répondent pas. Ils sont polis à leur façon.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le Capitaine Rigatoni, il raconte qu'il a vu le Grand Spaghetti en pleine mer, avant tout le monde. Moi, je dis que c'était une méduse. Il m'en veut encore.", {}, "rire"),
					L("Il paraît que la sauce du volcan est trop salée cette année. Bucatini dit que non. Bucatini dit toujours que non. Il goûte tous les jours, il ne sait plus ce qui est salé.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Hé, jeunot ! Le blé est beau, hein ?", {}, "salut")],
			}},
		{"id": "gnocchi", "nom": "Gnocchi", "titre": "petit-fils de Mamma Lasagna (8 ans)", "maison": "porte_famille", "village": "pasta",
			"agenda": [[8, 10, "plage_chateau"], [10, 12, ["fontaine_2", "barque_2"]], [12, 14, "tablee_7"], [14, 17, ["plage_chateau", "plage_bord"]], [17, 19, "piazza_banc_2"], [19, 20, "tablee_7"], [20, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "boucles", "yeux": Y_BRUN, "haut": [0.95, 0.94, 0.9], "taille": 0.72},
			"teinte": PEAU[1],
			"pasta": {"tenue": "enfant", "c": [0.95, 0.94, 0.9], "c2": TOMATE, "passoire": "grande"},
			"humeur_base": 0.7, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"glace": 2.5, "coquillage": 2.0, "spaghettis_bolo": 2.0, "carte_tresor": 2.5, "cerf_volant": 2.0}, "deteste": {"champignon": -0.5},
			"tics": ["À l'abordage !", "C'est trop bien !", "Pourquoi ?", "Moi aussi je veux !"],
			"surnoms": [[0, "toi"], [25, "moussaillon"], [50, "matelot"], [75, "mon capitaine"], [95, "mon meilleur ami pirate"]],
			"repliques": {
				"accueil": [
					L("Halte-là, moussaillon ! Je suis Gnocchi, le pirate le plus terrible de l'Île Al Dente ! (Sa passoire lui tombe sur les yeux. Il la remonte.) Je suis aussi novice. Et chanteur. Et plus tard, je serai volcan.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens jouer aux pirates ? Toi, tu fais le requin. Moi, je fais le capitaine. Et la passoire, c'est mon casque.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Trop content ! Le Capitaine Rigatoni m'a montré comment faire un nœud de marin. J'ai attaché mes deux chaussures ensemble. Je suis tombé. C'était un super nœud.", {}, "rire"),
					L("Un peu triste. Le Grand Spaghetti ne me fait plus coucou. Avant, quand je lui faisais coucou, il remuait une nouille. Maintenant, il ne bouge plus.", {"q56": "pa_plat_sacre="}),
					L("TROP CONTENT ! Le Grand Spaghetti m'a refait coucou ! Avec DEUX nouilles !", {"q56": "pa_plat_sacre=finie"}, "rire"),
				],
				"lui": [
					L("J'ai huit ans. Et demi. Presque neuf. Bientôt dix. Nonna dit que je suis tout rond comme un gnocchi. Moi, je dis que je suis tout fort comme un pirate.", {}, "rire"),
					L("Mon trésor à moi, je l'ai enterré sous le château de sable. C'est un coquillage, une bille et une nouille sèche. Ne le dis à personne. Surtout pas aux mouettes.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Capitaine Rigatoni habite dans une barque à l'envers, sur la plage ! C'est la maison la plus géniale du monde. Quand il pleut, ça fait « tac-tac-tac » sur le toit. Le toit, c'est le fond du bateau.", {}),
					L("Tu sais pourquoi la cascade est rouge ? Parce que le volcan saigne de la sauce ! Non, je rigole. C'est de la vraie sauce. Mais il ne faut pas la boire, elle est trop chaude. J'ai essayé. Un tout petit peu.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Le Capitaine a un trésor ! Un vrai ! Il dit qu'il ne se souvient plus où il l'a enterré. Moi, je crois qu'il s'en souvient. Il regarde toujours au même endroit quand il en parle.", {}),
					L("Frère Linguini a peur du noir. Il dort avec sa passoire sur la tête, comme ça la lune passe par les trous. C'est malin.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("À l'abordage !", {}, "rire"), L("Hé ! Tu veux voir mon château de sable ?", {}, "salut")],
			}},
		{"id": "ravioli", "nom": "Signorina Ravioli", "titre": "jardinière de la Tomateraie", "maison": "porte_ravioli", "village": "pasta",
			"agenda": [[7, 12, "tomates_1"], [12, 14, "tablee_8"], [14, 18, ["tomates_2", "tomates_1"]], [18, 20, "piazza_banc_3"], [20, 21, "tablee_8"], [21, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "tresse", "yeux": Y_VERT, "haut": [0.95, 0.9, 0.82]},
			"teinte": PEAU[0],
			"pasta": {"tenue": "jardiniere", "c": [0.95, 0.9, 0.82], "c2": TOMATE, "chapeau": "capeline", "objet": "arrosoir"},
			"femme": true,
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"graines": 2.5, "tomate_coeur": 1.0, "fleur_lune": 2.0, "bouquet_tournesols": 2.5, "miel": 1.5}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Chut, elles dorment.", "Elles m'écoutent, tu sais.", "Oh, regarde celle-là !", "Tout doux, tout doux."],
			"surnoms": [[0, "petit bourgeon"], [25, "petite pousse"], [50, "mon beau plant"], [75, "ma plus belle tomate"], [95, "jardinier de cœur"]],
			"repliques": {
				"accueil": [
					L("Chut ! Doucement… Elles écoutent. (Elle caresse un plant de tomates.) Bonjour ! Signorina Ravioli. Je m'occupe de la Tomateraie. Je chante pour mes tomates tous les matins. Elles rougissent. De plaisir, je crois.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens voir, viens voir : celle-là a encore grossi depuis hier. Je l'ai appelée Bolognaise. C'est ma préférée. Ne le dis pas aux autres.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Heureuse. Mes tomates sont rouges, mes basilics sont verts, et le volcan a envoyé un peu de cendre cette nuit. Elles adorent la cendre. C'est comme du chocolat pour elles.", {}),
					L("Un peu nerveuse. Quelqu'un a cueilli trois tomates sans me demander. Elles étaient très bien, ces tomates. Elles avaient des noms.", {"a_trouve": "pasta_tomates"}),
				],
				"lui": [
					L("Avant, je vivais à Port-Azur. Je vendais des fleurs. Un jour, une graine de tomate est tombée dans mon pot de roses. Elle a poussé plus haut que les roses. J'ai compris que c'était un message.", {}),
					L("Mon petit frère, c'est Frère Linguini. Il casse tout ce qu'il touche. Sauf les plantes. Les plantes, il les fait pousser rien qu'en les regardant. C'est notre secret de famille.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Tomateraie donne les tomates de la sauce sacrée. Bucatini en jette un panier dans la Marmite tous les dimanches. Le volcan fait le reste.", {}),
					L("Les tomates cœur-de-bœuf, il faut leur parler doucement, et leur chanter quelque chose de lent. Les cerises, elles, préfèrent la tarentelle. Elles sont plus jeunes.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Le Révérend Père cherche des tomates pour un plat très spécial. Il ne m'a pas dit lequel. Je lui ai préparé les trois plus belles. Elles l'attendent.", {"q56": "pa_plat_sacre=en_cours"}),
					L("Tagliatelle a peint mes tomates sur la grande bannière. Elle les a faites violettes. « C'est artistique », elle dit. Mes tomates sont vexées.", {}, "rire"),
				],
				"interpelle": [L("Psst… Viens voir mes tomates. Doucement.", {}, "salut")],
			}},
		{"id": "fusilli", "nom": "Professeure Fusilli", "titre": "théologienne et savante de l'Église", "maison": "porte_fusilli", "village": "pasta",
			"agenda": [[8, 10, "effigie_mesure"], [10, 12, "lac_rive"], [12, 14, "tablee_9"], [14, 17, ["effigie_mesure", "statue_2"]], [17, 20, "lac_rive"], [20, 21, "tablee_9"], [21, 24, "effigie_mesure"], [0, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "boucles", "yeux": Y_NOIR, "haut": [0.94, 0.94, 0.92], "lunettes": true},
			"teinte": PEAU[4],
			"pasta": {"tenue": "savante", "c": [0.18, 0.28, 0.4], "c2": PATE, "objet": "telescope_portable"},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 1.0, "humour": 0.5, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"boussole": 2.5, "partition": 1.5, "eclat_cristal": 2.0, "spaghettis_secs": 1.5, "grimoire": 2.0}, "deteste": {},
			"tics": ["Intéressant.", "Selon mes calculs…", "Plus ou moins une nouille.", "C'est statistiquement prouvé."],
			"surnoms": [[0, "cher visiteur"], [25, "cher collègue"], [50, "mon assistant"], [75, "mon brillant assistant"], [95, "docteur honoris nouillis"]],
			"repliques": {
				"accueil": [
					L("Ah ! Un témoin ! Parfait. Professeure Fusilli, théologienne de l'Église et savante. Je mesure le Grand Spaghetti Volant. Cent douze nouilles de long, deux boulettes, deux yeux. Plus ou moins une nouille. La science est formelle.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous tombez bien. J'ai besoin de quelqu'un pour tenir l'autre bout du double mètre. Il est un peu court. Il me faudrait un triple mètre.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Passionnée. J'ai découvert que le Grand Spaghetti cligne des yeux toutes les quarante-trois secondes. Sauf quand on le regarde. Là, c'est toutes les quarante-deux. Il est un peu timide.", {}),
					L("Perplexe. Depuis une semaine, l'amplitude du frétillement des nouilles a baissé de quatre-vingt-dix pour cent. En langage courant : il boude.", {"q56": "pa_plat_sacre="}),
					L("La nuit, je reste au parvis pour vérifier s'il dort. Mes observations sont formelles : il ne dort pas. Il fait semblant. Il ronfle très légèrement. En sauce.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai écrit trois livres : « Les Nouilles et l'Univers », « Pourquoi la passoire ? » et « Pirates et Climat : une corrélation ». Ce dernier montre que moins il y a de pirates sur les mers, plus il fait chaud. Je n'ai pas encore compris pourquoi. Mais les courbes sont très jolies.", {}, "rire"),
					L("Pourquoi Fusilli ? À cause de mes cheveux. Et parce que la spirale est la forme parfaite. Les coquillages, les galaxies, les fusilli. Tout se tient.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Mont Bolognaise est un volcan tout à fait unique. Sa lave est une sauce tomate à quatre-vingt-quatorze degrés, légèrement salée, avec du basilic. Mes collègues des autres îles ne me croient pas. Je leur envoie des pots. Ils me croient un peu plus.", {}),
					L("Le Lac Napolitain est le seul lac de sauce connu. Il ne gèle jamais, il ne s'évapore pas, et il sent très bon. Je viens y prendre la température deux fois par jour. Elle est toujours parfaite.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Selon mes calculs, le Grand Spaghetti boude depuis exactement sept jours, trois heures et quelques nouilles. Le Révérend pense qu'il faut lui préparer un plat spécial. Scientifiquement, c'est une hypothèse comme une autre. Et elle sent meilleur que les autres.", {"q56": "pa_plat_sacre="}),
					L("Le Capitaine Rigatoni prétend qu'un pirate doit enterrer son trésor « là où l'ombre du mât touche la mer à midi ». J'ai fait le calcul. C'est juste à côté de sa barque. Il le sait. Il fait semblant de ne pas savoir.", {"sujet_min": ["rumeur", 1]}),
				],
				"interpelle": [L("Vous ! Combien de nouilles voyez-vous, là-haut ? Comptez bien !", {}, "salut")],
			}},
		{"id": "tagliatelle", "nom": "Tagliatelle", "titre": "peintre des bannières et violoniste du Borgo", "maison": "porte_soeurs", "village": "pasta",
			"agenda": [[8, 12, "banniere"], [12, 14, "tablee_10"], [14, 18, ["banniere", "sechoir_2"]], [18, 21, "piazza_violon"], [21, 8, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "long", "yeux": Y_BLEU, "haut": [0.95, 0.88, 0.7]},
			"teinte": PEAU[0],
			"pasta": {"tenue": "peintre", "c": [0.95, 0.88, 0.7], "c2": BASILIC, "chapeau": "beret", "violon": true},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"bombe_peinture": 2.5, "fleur_lune": 2.0, "plume_ara": 2.0, "bouquet_tournesols": 2.0}, "deteste": {},
			"tics": ["C'est artistique.", "Regarde la lumière !", "Un peu plus de rouge…", "Tralala."],
			"surnoms": [[0, "toi"], [25, "mon modèle"], [50, "ma muse"], [75, "mon chef-d'œuvre"], [95, "ma plus belle toile"]],
			"repliques": {
				"accueil": [
					L("Ne bouge pas ! … Voilà. Je t'ai peint dans un coin de la bannière. Tout petit. En jaune. Tu fais un très joli spaghetti. Moi, c'est Tagliatelle. Je peins les bannières du temple, et le soir, je joue du violon pour la tarentelle.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Regarde : j'ai peint le volcan en bleu. Pourquoi ? Parce qu'il est déjà rouge. Ce serait trop facile.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Inspirée ! La lumière du matin sur la passoire, c'est de l'or qui coule par mille petits trous. Je n'arrive jamais à la peindre. C'est pour ça que j'essaie tous les jours.", {}),
					L("Le soir, le violon. La tarentelle commence doucement, puis on accélère, on accélère, et à la fin, plus personne ne sait où sont ses pieds. C'est le meilleur moment.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai appris le violon toute seule, sur un violon trouvé dans un grenier. Il lui manquait une corde. J'ai joué trois ans sur trois cordes. Quand on m'en a offert une quatrième, je ne savais plus quoi en faire.", {}, "rire"),
					L("Sœur Penne et moi, on partage la maison bleue du Borgo. Elle chante le matin, je joue le soir. Les voisins disent que notre maison ne dort jamais. Ils ont raison.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les bannières du parvis : vert, blanc, rouge, comme le basilic, la pâte et la tomate. Et au milieu, la fourchette dorée. Je les repeins chaque printemps. Cette année, j'ai ajouté des petits pirates dans les coins. Personne ne les a encore vus.", {}),
					L("Le Grand Spaghetti, je l'ai peint cent fois. Il ne ressemble jamais à mes tableaux. Je crois qu'il bouge exprès quand je le regarde.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Macaroni a un tambourin caché sous son Couvercle. Le soir, il le sort. C'est le gardien le plus sérieux de l'île, et le meilleur percussionniste. Ne lui dis pas que je te l'ai dit.", {}, "rire"),
				],
				"interpelle": [L("Bouge pas ! Je te peins !", {}, "rire")],
			}},
		# ================================================================ la Marmite
		{"id": "bucatini", "nom": "Bucatini", "titre": "gardien de la Marmite (le cratère du Mont Bolognaise)", "maison": "porte_gardiens", "village": "pasta",
			"agenda": [[6, 12, "belvedere"], [12, 14, "louche_geante"], [14, 19, "belvedere"], [19, 6, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.42, 0.4, 0.36], "carrure": 1.3},
			"teinte": PEAU[3],
			"pasta": {"tenue": "gardien_marmite", "c": [0.42, 0.4, 0.36], "c2": [0.35, 0.22, 0.12], "chapeau": "bandana", "objet": "louche"},
			"humeur_base": 0.45, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.3, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"tomate_coeur": 2.0, "fromage_chevre": 2.5, "focaccia": 2.0, "the_menthe": 1.0}, "deteste": {},
			"tics": ["Il manque un peu de sel.", "Elle mijote.", "Pas trop près.", "Hm. Bonne sauce."],
			"repliques": {
				"accueil": [
					L("Pas trop près du bord. Bucatini, gardien de la Marmite. Je surveille la sauce, je la goûte, je la remue quand elle colle. Tous les jours. (Il goûte.) … Il manque un peu de sel.", {"visites_max": 1}),
					L("{surnom}. Tu es monté jusqu'ici ? Bravo. Les jambes, c'est comme la sauce : il faut que ça travaille.", {"visites_min": 2}),
				],
				"humeur": [
					L("Bien. La sauce mijote tranquillement. Elle fait des petites bulles, « blop, blop ». Quand elle fait « BLOP », je recule.", {}),
					L("Agacé. En bas, quelqu'un a encore frappé le Couvercle trois fois. Ici, en haut, c'est moi qui reçois toute la sauce en premier.", {"a_trouve": "pasta_eruption"}, "colere"),
				],
				"lui": [
					L("Je suis monté ici il y a vingt ans pour goûter la sauce. Je ne suis jamais vraiment redescendu. Le soir, si. Pour dormir. Mais le matin, je remonte. Elle m'attend.", {}),
					L("Mon cousin Macaroni garde le Couvercle, en bas. Il dit que son travail est plus important. Je lui dis : viens remuer quarante tonnes de sauce avec une louche, et on en reparle. Il ne vient jamais.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La sauce coule par deux becs : un vers le lac, un vers la mer. Le jour où elle en trouve un troisième, on a un problème. Je surveille.", {}),
					L("La grande louche, là, c'est la Louche Sacrée. On peut en prendre une louchée, pour goûter. Une seule à la fois. Et on souffle avant. Toujours. On souffle.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le Révérend m'a demandé si la sauce était « digne d'un plat sacré ». J'ai goûté. Elle est digne. Il manque juste un peu de sel. Mais elle est digne.", {"q56": "pa_plat_sacre=en_cours"}),
					L("Quand le volcan crache, il ne faut pas courir. Il faut regarder en l'air et faire un pas de côté. La sauce tombe toujours là où on court.", {}),
				],
				"interpelle": [L("Pas trop près du bord !", {})],
			}},
		# ================================================================ la Plage du Parmesan
		{"id": "rigatoni", "nom": "Capitaine Rigatoni", "titre": "vieux pirate à la retraite, sur la Plage du Parmesan", "maison": "porte_barque", "village": "pasta",
			"agenda": [[7, 10, "ponton_peche"], [10, 12, "barque"], [12, 14, "tablee_11"], [14, 16, "plage_sieste"], [16, 19, "ponton_peche"], [19, 22, "barque"], [22, 7, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "queue", "barbe": "longue", "yeux": Y_BLEU, "haut": [0.18, 0.2, 0.32], "vieux": true, "carrure": 1.15},
			"teinte": PEAU[2],
			"pasta": {"tenue": "pirate", "c": [0.18, 0.2, 0.32], "c2": TOMATE, "chapeau": "tricorne", "props": ["cache_oeil", "perroquet"], "objet": "canne_peche"},
			"humeur_base": 0.5, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"carte_tresor": 2.5, "plume_perroquet": 2.0, "sardine": 1.5, "coquillage": 1.5, "boussole": 2.0}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Arrr !", "Mille sabords… de sauce !", "Par ma barbe !", "De mon temps, sur les mers…"],
			"surnoms": [[0, "moussaillon"], [25, "matelot"], [50, "second"], [75, "mon brave pirate"], [95, "capitaine d'honneur"]],
			"boutique": {"vend": {"pelle": 6, "canne_peche": 8, "sardine": 3}, "achete": {"coquillage": 2, "sardine": 2, "maquereau": 4, "perle": 18, "etoile_mer": 3}},
			"repliques": {
				"accueil": [
					L("Arrr ! Un nouveau sur ma plage ! Capitaine Rigatoni, terreur des sept mers, à la retraite. Et voici Pesto, mon perroquet. (Le perroquet vert crie : « RAMEN ! RAMEN ! ») Il ne sait dire que ça. C'est un perroquet très croyant.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens t'asseoir sur la barque. Je vais te raconter la fois où j'ai vu le Grand Spaghetti en pleine mer. Pesto, tais-toi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien, bien. Le poisson ne mord pas, mais le soleil est bon, et Pesto ne m'a pas encore pincé l'oreille. C'est une bonne journée de pirate à la retraite.", {}),
					L("Arrr, le soir, je bois mon jus de tomate au coucher du soleil, sur ma barque. Un vrai pirate ne boit que du jus de tomate. C'est le secret des pirates. Ne le répète pas.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Les pirates sont les premiers pastafariens, tu le savais ? Le Grand Spaghetti aime les pirates. Il les a créés avec une nouille spéciale. Moi, j'ai navigué quarante ans. Je n'ai jamais pillé personne. J'ai surtout échangé des recettes.", {}),
					L("Mon cache-œil ? Je n'ai rien à l'œil. Mais un pirate sans cache-œil, ce n'est pas sérieux. Je le change d'œil le mardi. Pour que les deux se reposent.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Pesto, je l'ai trouvé sur une île à basilic, tout petit, tout vert. Il sentait le basilic. Il sent toujours le basilic. Le premier mot qu'il a appris, c'est « Ramen ». Le deuxième, ça aussi.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ma maison, c'est ma vieille barque, retournée sur le sable. Le toit ne fuit pas, la vue est magnifique, et quand j'ai la nostalgie, je regarde la quille. Elle me raconte des histoires de mer.", {}),
					L("J'ai vu le Grand Spaghetti en pleine mer, il y a cinquante ans. Il flottait au-dessus des vagues, au coucher du soleil, et il m'a montré cette île avec une nouille. Tortellini dit que c'était une méduse. Une méduse ne montre rien avec ses nouilles. Arrr.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Un trésor ? Quel trésor ? Je n'ai jamais enterré de trésor près de ma barque. Jamais. (Il jette un coup d'œil vers le sable, à côté de la barque, puis siffle.)", {}),
					L("La Râpe d'Or ? Qui t'a parlé de la Râpe d'Or ? … Le Révérend ? Bon. Bon, bon, bon. Viens me voir quand il t'enverra. Je verrai ce que je peux… me rappeler.", {"q56": "pa_plat_sacre=en_cours"}),
				],
				"interpelle": [L("Arrr ! Moussaillon ! Approche !", {}, "salut")],
			}},
	]

extends RefCounted
## Extension « Le Château d'Ombrelac » (v14) : les gens de l'Académie d'Ombrelac.
##  - les élèves : quatre du Dortoir de l'Aube (bleu et or : Lison, Barnabé, Nour, Tobie) et quatre du
##    Dortoir du Crépuscule (pourpre et vieil or : Ombeline, Anatole, Sidonie, Malo) ;
##  - les maîtres : la Rectrice Aldegonde Vespérine, Maître Fauconnier (les astres), Maîtresse Alambic
##    (les élixirs), Maître Équerre (la géométrie, à l'Amphithéâtre), Dame Sortelame (les sortilèges),
##    Dame Reliure (la bibliothécaire), Maître Rouage (le gardien de l'horloge) ;
##  - les gens du château : Gaspard Herse (le portier), Mère Fournil (l'intendante), Firmin Buis (le
##    jardinier).
## Même cerveau et même vie réglée par l'heure que les autres habitants de l'archipel (pnj_brain_v31,
## pnj_azur_v56, pnj_montjoie_v71). Les lieux viennent de vie_ombrelac.gd : un lieu qui commence par « @ »
## est un groupe (les bancs d'une table, les pupitres d'une salle…) : l'habitant y prend une place libre.
## L'emploi du temps : le petit déjeuner à 7 h, les cours (8 h 30, 11 h, 13 h 30), la récréation à
## la fontaine à 10 h, le déjeuner à midi, le temps libre l'après-midi, le dîner à 19 h, la Salle
## Commune le soir, au lit à 22 h.
## Identifiants suffixés « _om » (Ombrelac) pour ne rien croiser ailleurs dans l'archipel.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bonne route, {surnom} ! Et ne te perds pas dans les couloirs : ils changent de place quand on ne les regarde pas. Enfin, c'est ce qu'on raconte aux nouveaux.", "si": {}, "geste": "salut"},
		{"t": "À bientôt ! Que la brume du lac te soit légère.", "si": {}},
		{"t": "Bonne nuit, {surnom}. Écoute l'horloge : à minuit, elle sonne treize coups. Personne ne sait pourquoi.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Aïe ! À l'Académie, on ne se bat qu'en duel de sortilèges, avec Dame Sortelame pour arbitre. Et elle arbitre très sévèrement.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Je vais le dire à la Rectrice. Et la Rectrice, elle ne crie jamais. C'est bien pire.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Merci, {surnom}. Je le rangerai dans ma malle, sous mes chaussettes : c'est là qu'on cache les trésors, ici.", "si": {}},
		{"t": "Oh, c'est gentil. Je vais demander à Dame Reliure s'il y a un livre là-dessus. Il y a un livre sur tout.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Comment as-tu deviné ? Tu lis dans les pensées ? On n'apprend ça qu'en dernière année !", "si": {}, "geste": "rire"},
		{"t": "Par les étoiles d'Ombrelac ! Merci, {surnom}, c'est exactement ce qu'il me fallait.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Ah… merci. Je… je vais le donner à Maîtresse Alambic. Elle en fera sûrement un élixir. Un élixir qui sent mauvais.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Range ça. Dans l'enceinte de l'Académie, la seule lame permise, c'est le coupe-papier de la Rectrice.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr. À Ombrelac, on n'oublie rien : même les murs ont de la mémoire. Surtout ceux de la Bibliothèque.", "si": {}}],
	"blague": [
		{"t": "Pourquoi l'astrolabe ne ment jamais ? Parce qu'il a trop d'anneaux pour se cacher derrière !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un élixir qui ne marche pas ? Une soupe. Maîtresse Alambic en fait beaucoup, mais elle dit que ce sont des essais.", "si": {}, "geste": "rire"},
		{"t": "Un élève demande à Maître Équerre : « Maître, à quoi sert la géométrie ? » Il répond : « À tourner en rond, mais proprement. »", "si": {}, "geste": "rire"},
	],
}

const BASE := {
	"prefixes": {
		"joie": ["Par les étoiles !", "Formidable !", "Ah, merveilleux !", "Quelle chance !"],
		"neutre": ["Hmm.", "Voyons…", "Bien.", "Eh bien…"],
		"triste": ["Ah…", "Hélas.", "Pff…", "Que la brume m'emporte…"],
		"colere": ["Par la Couronne !", "Ça suffit.", "Sapristi !", "Écoute-moi bien."],
	},
	"tics": ["Par les étoiles.", "Comme dit la Rectrice.", "Si l'horloge le permet.", "Hm hm."],
	"humeur_mots": [[0.6, "radieux"], [0.25, "de bonne humeur"], [-0.25, "rêveur"], [-0.6, "grognon"], [-2.0, "orageux"]],
	"surnoms": [[0, "visiteur"], [25, "voyageur"], [50, "ami de l'Académie"], [75, "presque élève"], [95, "membre d'honneur"]],
}

const AUBE := "dortoir_aube"
const CREPUSCULE := "dortoir_crepuscule"


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
	out["groupe"] = "ombrelac"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


## La journée d'un élève : la maison (le dortoir), les trois cours, le temps libre (deux lieux au choix).
static func _journee(maison: String, cours: Array, libre1: Variant, libre2: Variant) -> Array:
	var gs: String = "@gs_aube" if maison == AUBE else "@gs_crepuscule"
	# (une heure de jeu dure une minute : les repas et les cours sont longs, la récréation se passe à la
	# fontaine du cloître, juste devant les salles de cours)
	return [[7, 8.5, gs], [8.5, 10, cours[0]], [10, 11, "@fontaine"], [11, 12, cours[1]], [12, 13.5, gs], [13.5, 15.5, cours[2]],
		[15.5, 17.5, libre1], [17.5, 19, libre2], [19, 20.5, gs], [20.5, 22, "@commune"], [22, 7, "maison"]]


static func _all() -> Array:
	var cours_aube: Array = ["@astres", "@elixirs", "@cercle"]
	var cours_crep: Array = ["@elixirs", "@amphi", "@astres"]
	return [
		# ================================================================ les élèves de l'Aube
		{"id": "lison_om", "nom": "Lison", "titre": "élève de l'Aube", "maison": AUBE, "village": "ombrelac",
			"agenda": _journee(AUBE, cours_aube, "@fontaine", "@biblio"),
			"azur": {"taille": 0.85}, "teinte": [0.98, 0.86, 0.76], "mj": {"objet": "livre"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"plume_lune": 2.0, "eclat_lune": 2.0, "the_menthe": 1.0, "pain_miel": 1.5}, "deteste": {"gelee_slime": -1.5},
			"tics": ["Et pourquoi ?", "Attends, attends…", "C'est écrit quelque part !"],
			"repliques": {
				"accueil": [
					L("Bonjour ! Tu n'es pas d'ici, toi. Tu viens d'où ? Comment tu es arrivé ? Par le viaduc ? Tu as vu les gargouilles ? Pardon. Je m'appelle Lison, je suis de l'Aube, et je pose trop de questions. C'est Maître Fauconnier qui le dit.", {"visites_max": 1}, "salut"),
					L("{surnom} ! J'ai trouvé un nouveau passage derrière la Bibliothèque. Enfin, je crois. C'était peut-être un placard.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bien ! Ce matin, en élixirs, ma potion a changé de couleur trois fois. Maîtresse Alambic a dit « intéressant ». Chez elle, « intéressant » veut dire « ne recommence jamais ».", {}, "rire"),
					L("Le soir, j'aime regarder la brume monter du lac, depuis la fenêtre du dortoir. On dirait que l'eau respire.", {"soir": true}),
				],
				"lui": [
					L("Je veux devenir cartographe des étoiles. Il y a des constellations que personne n'a encore nommées. J'ai déjà une liste de noms. Elle fait quatre pages.", {}),
					L("Mon père est pêcheur, ma mère réparait des filets. Personne dans ma famille n'avait jamais vu un sortilège. Alors quand la lettre de l'Académie est arrivée, ma grand-mère l'a fait encadrer.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("L'Académie a quatre cents ans ! Les fondateurs ont posé la Couronne dans la Grosse Tour, et depuis, chaque Recteur l'a gardée. On n'a pas le droit de monter la voir. Enfin, pas encore.", {}),
					L("Tu as vu les nénuphars, sur le lac ? Quand ils fleurissent tous ensemble, c'est que l'été est vraiment là. Barnabé dit que c'est de la botanique. Moi, je dis que c'est de la magie.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il paraît que l'horloge avance d'une minute chaque fois que quelqu'un ment dans la cour. Maître Rouage la remet à l'heure tous les matins. Ça veut dire qu'on ment beaucoup.", {}, "rire"),
					L("Anatole, du Crépuscule, dit qu'il a vu la Rectrice sourire. Une fois. Personne ne le croit.", {}),
				],
				"interpelle": [L("Hé ! Toi ! Tu cherches quelque chose ? Je connais tous les couloirs. Presque.", {"visites_max": 0}), L("{surnom} ! Viens voir, vite !", {"visites_min": 1}, "salut")],
			}},
		{"id": "barnabe_om", "nom": "Barnabé", "titre": "élève de l'Aube", "maison": AUBE, "village": "ombrelac",
			"agenda": _journee(AUBE, cours_aube, "@biblio", "@biblio"),
			"azur": {"taille": 0.9}, "teinte": [0.9, 0.72, 0.58], "mj": {"objet": "livre"},
			"humeur_base": 0.3, "traits": {"bavard": 0.5, "humour": 0.4, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"grimoire": 2.5, "the_menthe": 1.5, "champignon": 1.0, "plume_corbeau": 1.5}, "deteste": {"cerf_volant": -0.5},
			"tics": ["Techniquement…", "J'ai lu que…", "Hum."],
			"repliques": {
				"accueil": [
					L("Oh. Bonjour. Pardon, j'étais au chapitre douze. Barnabé, de l'Aube. Tu cherches la Bibliothèque ? Tout le monde devrait chercher la Bibliothèque.", {"visites_max": 1}),
					L("{surnom}. J'ai fini le chapitre douze. Il y a un chapitre treize. Personne ne m'avait prévenu.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Correcte. Dame Reliure m'a prêté un livre de la réserve. Avec des gants. Le livre portait des gants, je veux dire. Moi aussi, d'ailleurs.", {}),
					L("Le soir, à la Salle Commune, tout le monde joue aux échecs. Moi, je lis les règles. C'est plus reposant que de perdre.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai lu tous les livres de la deuxième rangée de la galerie. Il en reste onze rangées. À ce rythme, j'aurai fini dans… trente-deux ans. Je suis assez content de ce chiffre.", {}),
					L("Les sortilèges, ce n'est pas mon fort : la dernière fois, ma baguette a lancé une étincelle, puis une plume, puis plus rien. Dame Sortelame a dit que c'était « un début ». Elle avait l'air sincère.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Bibliothèque a été bâtie dans l'Aile des Études, sous un lambris peint d'étoiles. Les rayons de la galerie montent jusqu'à cinq mètres soixante. J'ai mesuré.", {}),
					L("Le Lac d'Ombre est très profond au milieu. Seize mètres, d'après le vieux registre des fondateurs. Et personne n'a jamais trouvé le fond de la légende qui va avec.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il y a un livre, dans la galerie, qui se range tout seul quand on le pose ailleurs. Dame Reliure dit que c'est un livre « bien élevé ». Je pense qu'elle en sait plus.", {}),
					L("Tobie a perdu sa chaussette gauche il y a deux mois. On l'a retrouvée sur la girouette de la Tour de l'Horloge. Personne n'a d'explication.", {}, "rire"),
				],
				"interpelle": [L("Psst. Tu sais où est rangé l'atlas des courants ? Non ? Moi non plus.", {"visites_max": 0}), L("{surnom}, tu as un instant ? J'ai une théorie.", {"visites_min": 1})],
			}},
		{"id": "nour_om", "nom": "Nour", "titre": "élève de l'Aube", "maison": AUBE, "village": "ombrelac",
			"agenda": _journee(AUBE, cours_aube, "@cour_jeu", "@fontaine"),
			"azur": {"taille": 0.86}, "teinte": [0.7, 0.5, 0.38], "mj": {},
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"eclat_lune": 2.5, "boussole": 2.0, "plume_vent": 1.5, "chocolat_chaud": 1.5}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Regarde le ciel.", "Exactement.", "Bon."],
			"repliques": {
				"accueil": [
					L("Salut. Nour, de l'Aube. Tu sais repérer l'étoile du Nord ? Non ? Ce soir, à l'Observatoire, demande à Maître Fauconnier. Il adore quand on demande.", {"visites_max": 1}, "salut"),
					L("Tiens, {surnom}. Hier soir, j'ai vu une étoile filante au-dessus de la Tour de l'Astrolabe. J'ai fait un vœu. Je ne te dis pas lequel.", {"visites_min": 2}),
				],
				"humeur": [
					L("Parfaite. J'ai eu la meilleure note en astres. Encore. Lison dit que c'est injuste. Je lui ai dit que les étoiles, ce n'est pas une question de justice, c'est une question de calcul.", {}, "rire"),
					L("La nuit est claire. Ça, c'est une bonne nuit.", {"soir": true}),
				],
				"lui": [
					L("Je viens du désert, de très loin au sud. Là-bas, le ciel est si noir qu'on voit la poussière d'étoiles. Ici, il y a la brume. Mais quand elle se lève, le ciel d'Ombrelac est le plus beau de l'archipel.", {}),
					L("Un jour, je calculerai l'orbite de la septième planète. Le planétaire de la Salle des Astres n'en a que six. Il en manque une, j'en suis sûre.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Grande Lunette de l'Observatoire est tout en haut de la Tour de l'Astrolabe, à cinquante-quatre mètres. On y monte par la Nacelle. Malo a peur de la Nacelle. Ne lui dis pas que je te l'ai dit.", {}),
					L("Les trois anneaux du Grand Astrolabe, au pied de la tour, tournent tout seuls. Ils suivent le ciel, même le jour, même dans la brume.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("On dit que la Rectrice ne dort jamais : on voit de la lumière dans la Grosse Tour à toute heure. Moi, je pense qu'elle oublie d'éteindre sa lampe.", {}),
					L("Maître Fauconnier parle à la lune. Je l'ai entendu. Il lui demande des nouvelles.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu veux voir quelque chose de beau ? Lève la tête.", {"visites_max": 0}), L("{surnom} ! Les étoiles sont bien placées, aujourd'hui.", {"visites_min": 1}, "salut")],
			}},
		{"id": "tobie_om", "nom": "Tobie", "titre": "élève de l'Aube", "maison": AUBE, "village": "ombrelac",
			"agenda": _journee(AUBE, cours_aube, "@cour_jeu", "@cour_jeu"),
			"azur": {"taille": 0.84}, "teinte": [0.98, 0.86, 0.76], "mj": {},
			"humeur_base": 0.8, "traits": {"bavard": 0.9, "humour": 1.0, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"chocolat_chaud": 2.5, "croissant": 2.0, "cerf_volant": 2.0, "pain_miel": 1.5}, "deteste": {"champignon": -1.0},
			"tics": ["Ha !", "Trop bien !", "Je te jure !"],
			"repliques": {
				"accueil": [
					L("Salut ! Tobie, de l'Aube ! Tu veux jouer au chat-perché-sortilège ? C'est comme le chat perché, mais on a le droit de flotter. Enfin, on aurait le droit, si on savait flotter.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes bien, il nous manque un joueur. Et un ballon. Surtout un ballon.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super ! Au déjeuner, il y avait de la tarte. Mère Fournil m'en a gardé une part. Elle dit que je suis trop maigre. Moi, je dis que je cours trop vite.", {}, "rire"),
					L("Le soir, on fait des parties d'échecs à la Salle Commune. Je perds toujours contre Ombeline. Elle dit que je joue « avec enthousiasme ». C'est gentil, non ?", {"soir": true}),
				],
				"lui": [
					L("Plus tard, je veux être gardien du viaduc, comme Gaspard. Il a une moustache magnifique et il connaît tout le monde. Il me manque juste la moustache.", {}, "rire"),
					L("J'ai perdu une chaussette. Elle est réapparue sur la girouette de l'horloge. Je n'ai rien fait. Je le jure sur la Couronne. Enfin, presque rien.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le meilleur endroit pour jouer, c'est la Cour d'Honneur : il y a de la place, des réverbères pour se cacher derrière, et le portier ne dit rien tant qu'on ne monte pas sur les bancs.", {}),
					L("Le jardin du cloître, on n'a pas le droit de courir dedans. Firmin dit que les fleurs ont peur. Je ne savais pas que les fleurs avaient peur.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Anatole dit qu'il y a un passage secret sous la fontaine du cloître. On a cherché. On a trouvé une grenouille. Elle avait l'air de savoir quelque chose.", {}, "rire"),
					L("Il paraît que Maître Équerre dort au garde-à-vous. Comme un compas. Les deux pieds bien serrés.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu cours vite ? On fait la course jusqu'à la fontaine !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens jouer !", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ les élèves du Crépuscule
		{"id": "ombeline_om", "nom": "Ombeline", "titre": "préfète du Crépuscule", "maison": CREPUSCULE, "village": "ombrelac", "vouvoie": true,
			"agenda": _journee(CREPUSCULE, cours_crep, "@biblio", "@fontaine"),
			"azur": {"taille": 0.9}, "teinte": [0.96, 0.84, 0.76], "mj": {"objet": "livre"},
			"humeur_base": 0.3, "traits": {"bavard": 0.5, "humour": 0.4, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"perle": 2.0, "the_menthe": 2.0, "plume_corbeau": 1.5, "tisane_lune": 2.0}, "deteste": {"gelee_slime": -2.0},
			"tics": ["Le règlement est clair.", "Hm.", "Silence, s'il vous plaît."],
			"repliques": {
				"accueil": [
					L("Bonjour. Ombeline, préfète du Crépuscule. Vous êtes un visiteur ? Bien. Les visiteurs ne courent pas dans les couloirs, ne parlent pas fort à la Bibliothèque et ne nourrissent pas les gargouilles.", {"visites_max": 1}),
					L("Ah, {surnom}. Vous avez respecté le règlement depuis la dernière fois ? Je vous fais confiance. Presque.", {"visites_min": 2}),
				],
				"humeur": [
					L("Bonne. Le Crépuscule a gagné trois points au tournoi d'échecs, et Anatole n'a rien fait exploser depuis mardi. C'est un record.", {}),
					L("Le soir, je fais la ronde du dortoir. Puis je lis. Puis je refais la ronde, parce qu'Anatole ne dort jamais quand il le faut.", {"soir": true}),
				],
				"lui": [
					L("Je serai Rectrice un jour. Pas ici, peut-être, mais quelque part. Il faut bien que quelqu'un tienne les registres et sache où sont rangés les grimoires.", {}),
					L("Mes parents tiennent une librairie sur une île de l'est. J'ai appris à lire avant de savoir marcher. Enfin, c'est ce que dit ma mère. Elle exagère toujours un peu.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Dortoir du Crépuscule a des rideaux pourpres et la meilleure vue sur le lac. Celui de l'Aube a des rideaux bleus et la vue sur le cloître. Nous ne nous disputons pas à ce sujet. Officiellement.", {}),
					L("La Salle Commune est entre les deux dortoirs, à l'étage. C'est le seul endroit où l'Aube et le Crépuscule partagent le même feu. Et le même échiquier. Ce qui est plus dangereux.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Je ne fais pas circuler de rumeurs. Mais il est exact que Maître Rouage a fait sonner la cloche à quatre heures trente, la semaine dernière. Par erreur. Toute l'Académie s'est levée.", {}),
					L("Une préfète ne commère pas. Je dirai seulement que Sidonie a réussi un élixir de rire, et que Maître Équerre en a goûté. Par mégarde.", {}, "rire"),
				],
				"interpelle": [L("Vous, là. Vous n'êtes pas perdu, j'espère ?", {"visites_max": 0}), L("{surnom}. Bonjour.", {"visites_min": 1}, "salut")],
			}},
		{"id": "anatole_om", "nom": "Anatole", "titre": "élève du Crépuscule", "maison": CREPUSCULE, "village": "ombrelac",
			"agenda": _journee(CREPUSCULE, cours_crep, "@cour_jeu", "@fontaine"),
			"azur": {"taille": 0.86}, "teinte": [0.98, 0.84, 0.74], "mj": {},
			"humeur_base": 0.7, "traits": {"bavard": 0.9, "humour": 1.0, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"poussiere_fee": 2.5, "cerf_volant": 2.0, "chocolat_chaud": 1.5, "montre_envers": 2.0}, "deteste": {"the_menthe": -0.5},
			"tics": ["C'était pas moi.", "Ha ha !", "Tu veux un secret ?"],
			"repliques": {
				"accueil": [
					L("Salut ! Anatole, du Crépuscule. Si tu entends une explosion, ce n'était pas moi. Si tu sens une odeur de chou brûlé, ce n'était pas moi non plus. Bon. Peut-être un peu.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu veux voir mon nouveau sortilège ? Il fait pousser des moustaches aux statues. Pour l'instant, il marche sur moi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Génial ! Ce matin, mon élixir a fait des bulles violettes qui chantaient. Maîtresse Alambic a pris des notes. Ombeline a pris un air sévère.", {}, "rire"),
					L("La nuit, c'est l'heure des farces. Mais chut. Je n'ai rien dit.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mes grands frères sont tous passés par l'Académie. Ils ont laissé un souvenir. Un mauvais souvenir, d'après Maître Équerre. Alors moi, je fais de mon mieux pour être à la hauteur.", {}, "rire"),
					L("Je veux inventer des sortilèges utiles. Comme celui qui range une chambre en claquant des doigts. Je l'ai presque. Pour l'instant, il range la chambre du voisin.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le meilleur coin du château, c'est le haut de la Tour des Sortilèges : les marches flottent dans le vide, il n'y a pas de rampe, juste de la lumière. La première fois, on a les genoux qui tremblent. La deuxième aussi.", {}),
					L("Tu as vu le Pont Couvert ? Il passe au-dessus du lac jusqu'à la Tour des Vents. Quand le vent souffle fort, il chante. Enfin, il siffle. Comme Gaspard quand il est content.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il y a un passage secret sous la fontaine du cloître. J'en suis sûr. Tobie a trouvé une grenouille. C'est forcément la gardienne du passage.", {}, "rire"),
					L("La Rectrice a souri une fois. Je l'ai vu. Personne ne me croit. C'était quand Maître Équerre a goûté l'élixir de rire de Sidonie.", {}, "rire"),
				],
				"interpelle": [L("Psst ! Tu veux voir un truc ? Ne le dis à personne.", {"visites_max": 0}), L("{surnom} ! J'ai une idée géniale. Enfin, une idée.", {"visites_min": 1}, "rire")],
			}},
		{"id": "sidonie_om", "nom": "Sidonie", "titre": "élève du Crépuscule", "maison": CREPUSCULE, "village": "ombrelac",
			"agenda": _journee(CREPUSCULE, cours_crep, "@biblio", "@biblio"),
			"azur": {"taille": 0.85}, "teinte": [0.92, 0.76, 0.62], "mj": {"objet": "livre"},
			"humeur_base": 0.4, "traits": {"bavard": 0.3, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.6, "rancunier": 0.1},
			"aime": {"champignon": 2.0, "miel": 2.0, "bouquet_tournesols": 2.0, "nectar_fee": 2.0}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Euh…", "Je crois.", "Peut-être."],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour… Sidonie. Du Crépuscule. Pardon, je ne parle pas beaucoup. Sauf aux plantes. Les plantes, elles, ne se moquent pas.", {"visites_max": 1}),
					L("Bonjour, {surnom}. Je… je suis contente de te revoir. Vraiment.", {"visites_min": 2}),
				],
				"humeur": [
					L("Bien, je crois. Maîtresse Alambic m'a laissée préparer l'élixir de rire toute seule. Il a marché. Un peu trop, d'ailleurs.", {}, "rire"),
					L("Le soir, je vais voir les serres avec Firmin. Les fleurs de lune s'ouvrent à la nuit tombée. Elles sentent le miel et la pluie.", {"soir": true}),
				],
				"lui": [
					L("Je veux être herboriste. Il y a des plantes, dans les serres, qui guérissent la tristesse. Pas complètement. Mais assez pour finir sa journée.", {}),
					L("Je suis la première de ma famille à savoir faire un sortilège. Le premier qui a marché, c'était pour réchauffer une tasse de thé. Ma mère a pleuré. De joie, je crois.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les serres de l'Académie sont près de la Tour de l'Horloge. Firmin y fait pousser des choses qui n'existent nulle part ailleurs. Il leur parle. Moi aussi, maintenant.", {}),
					L("Au bord du lac, entre les roseaux, il y a des nénuphars blancs et roses. Maîtresse Alambic dit que leurs racines servent à l'élixir de sommeil.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Je… je ne sais pas si je devrais le dire. Mais Maître Équerre a ri pendant une heure, après avoir goûté mon élixir. Il a dit que c'était « mathématiquement inacceptable ». Et il riait encore.", {}, "rire"),
					L("Firmin dit que la grande fougère de la serre a grandi d'un mètre en une nuit. Il ne sait pas pourquoi. Il a l'air un peu inquiet.", {}),
				],
				"interpelle": [L("Euh… bonjour ?", {"visites_max": 0}), L("{surnom} ! Oh. Bonjour.", {"visites_min": 1}, "salut")],
			}},
		{"id": "malo_om", "nom": "Malo", "titre": "élève du Crépuscule", "maison": CREPUSCULE, "village": "ombrelac",
			"agenda": _journee(CREPUSCULE, cours_crep, "@cour_jeu", "@cour_jeu"),
			"azur": {"taille": 0.92}, "teinte": [0.6, 0.42, 0.3], "mj": {},
			"humeur_base": 0.6, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"pain_miel": 2.0, "croissant": 2.0, "tarte_potiron": 2.0, "pomme": 1.5}, "deteste": {"gelee_slime": -1.0},
			"tics": ["Allez !", "Facile.", "On y va ?"],
			"repliques": {
				"accueil": [
					L("Salut ! Malo, du Crépuscule. Tu fais du sport ? Ici, on court autour de la cour avant le petit déjeuner. Enfin, moi je cours. Les autres dorment.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Le tour de la cour en moins d'une minute, tu crois que c'est possible ? Moi oui.", {"visites_min": 2}),
				],
				"humeur": [
					L("En forme ! J'ai fait douze fois le tour de la cour ce matin. Gaspard compte avec moi. Il dit que je vais finir par user les pavés.", {}, "rire"),
					L("Le soir, je suis fatigué. Mais un bon fatigué. Celui où on dort comme une pierre.", {"soir": true}),
				],
				"lui": [
					L("Je viens d'un village de montagne. Là-bas, on monte et on descend toute la journée. Ici, tout est plat. Sauf les escaliers des tours. Les escaliers des tours, je les adore.", {}),
					L("La Nacelle de la Tour de l'Astrolabe… je préfère l'escalier. Il n'y a pas d'escalier ? Bon. Je préfère ne pas monter, alors.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("L'escalier de la Tour de l'Horloge a huit volées. Je les monte en moins de deux minutes. Maître Rouage dit que je fais trembler les rouages. Je ne crois pas. Un peu, peut-être.", {}, "rire"),
					L("Le viaduc a sept arches. Je les ai comptées en courant. Puis en marchant, pour être sûr. Puis Gaspard m'a dit de rentrer.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Il paraît que Dame Sortelame a été championne de duel dans sa jeunesse. Personne ne l'a jamais battue. Moi, je voudrais essayer. Un jour. Quand je serai très, très fort.", {}),
					L("Nour dit que j'ai peur de la Nacelle. C'est faux. J'ai… du respect pour la Nacelle.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu fais la course ?", {"visites_max": 0}, "salut"), L("{surnom} ! On fait un tour de cour ?", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ les maîtres
		{"id": "vesperine_om", "nom": "la Rectrice Vespérine", "titre": "Rectrice de l'Académie d'Ombrelac", "maison": "bureau_recteur", "village": "ombrelac", "vouvoie": true,
			"agenda": [[7, 8, "estrade_s4"], [8, 12, "bureau_recteur"], [12, 13, "estrade_s4"], [13, 15, "@fontaine"], [15, 16, "@conseil"], [16, 19, "bureau_recteur"], [19, 20, "estrade_s4"], [20, 23, "bureau_recteur"], [23, 7, "maison"]],
			"azur": {"taille": 0.95}, "teinte": [0.96, 0.84, 0.76], "mj": {"objet": "baton", "tenue": "mage"},
			"humeur_base": 0.4, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"the_menthe": 2.5, "grimoire": 2.0, "perle": 1.5, "plume_lune": 2.0}, "deteste": {"gelee_slime": -2.0},
			"tics": ["Hm.", "Voyons cela.", "Bien."],
			"surnoms": [[0, "visiteur"], [25, "cher visiteur"], [50, "ami de l'Académie"], [75, "hôte d'honneur"], [95, "ami très cher"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à l'Académie d'Ombrelac. Je suis Aldegonde Vespérine, sa Rectrice. Vous êtes ici chez vous, tant que vous respectez trois choses : le silence de la Bibliothèque, le sommeil des élèves et le jardin de Firmin.", {"visites_max": 1}, "salut"),
					L("{surnom}. L'Académie vous a manqué ? Elle aussi, je crois. Les murs d'ici ont de l'affection pour ceux qui reviennent.", {"visites_min": 2}),
				],
				"humeur": [
					L("Sereine. Les élèves travaillent, l'horloge est à l'heure, et personne n'a encore changé une statue en grenouille aujourd'hui. Il n'est que midi, cependant.", {}),
					L("Le soir, j'aime la Grosse Tour. On entend tout le château s'endormir, salle après salle. Puis la cloche. Puis rien.", {"soir": true}),
				],
				"lui": [
					L("J'ai été élève ici, il y a… longtemps. Au Dortoir de l'Aube. J'étais la pire en géométrie et la meilleure pour me perdre dans les couloirs. Les deux m'ont beaucoup appris.", {}),
					L("Garder une école, c'est garder une flamme : il faut la protéger du vent, mais jamais l'enfermer. Les fondateurs l'ont écrit au-dessus de la cheminée de mon bureau. Je le relis tous les matins.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les fondateurs ont choisi ce roc pour sa solitude : le lac, la brume, les falaises. Ici, disaient-ils, on entend mieux ses propres pensées. Ils avaient raison, sauf à l'heure du déjeuner.", {}),
					L("La Couronne des Fondateurs repose dans la Salle des Reliques, en haut de la Grosse Tour. Elle tourne depuis quatre siècles. Le jour où elle s'arrêtera… eh bien, nous verrons.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("On dit que je ne dors jamais. C'est faux. Je dors très bien. Simplement, je laisse ma lampe allumée : les élèves travaillent mieux quand ils croient qu'on les surveille.", {}, "rire"),
					L("Il paraît qu'un passage secret part de la fontaine du cloître. Je laisse les élèves chercher. Chercher, c'est déjà apprendre.", {}),
				],
				"interpelle": [L("Vous cherchez quelqu'un ?", {"visites_max": 0}), L("{surnom}. Approchez.", {"visites_min": 1}, "salut")],
			}},
		{"id": "fauconnier_om", "nom": "Maître Fauconnier", "titre": "maître des astres", "maison": "observatoire", "village": "ombrelac",
			"agenda": [[7, 8, "estrade_s3"], [8, 10, "astres_maitre"], [10, 12, "@biblio"], [12, 13, "estrade_s3"], [13, 15, "astres_maitre"], [15, 19, "terrasse"], [19, 20, "estrade_s3"], [20, 2, "observatoire"], [2, 7, "maison"]],
			"azur": {"taille": 1.0}, "teinte": [0.95, 0.8, 0.7], "mj": {"objet": "baton", "tenue": "mage"},
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"eclat_lune": 2.5, "plume_lune": 2.0, "boussole": 1.5, "the_menthe": 1.0}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Ah, le ciel…", "Fascinant.", "Comme je le disais à la lune…"],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Orbel Fauconnier, maître des astres. Vous aimez les étoiles ? Tout le monde aime les étoiles. Le difficile, c'est de les aimer en plein jour, quand on ne les voit pas.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom} ! Ce soir, Vénus se lève au-dessus de la Tour de l'Horloge. Montez à l'Observatoire, je vous la présenterai.", {"visites_min": 2}),
				],
				"humeur": [
					L("Excellente ! J'ai enfin compris pourquoi la quatrième planète du planétaire grince. Ce n'était pas une planète, c'était une souris. Elle dormait sur le bras de laiton.", {}, "rire"),
					L("La nuit est mon heure. Le jour, je ne fais qu'attendre la nuit en enseignant.", {"soir": true}),
				],
				"lui": [
					L("J'ai passé quarante ans à regarder le ciel. Je connais chaque étoile par son nom, et certaines par leur surnom. Il y en a une, au nord, que j'appelle Gertrude. Ne me demandez pas pourquoi.", {}, "rire"),
					L("Nour, de l'Aube, est la meilleure élève que j'aie eue depuis vingt ans. Elle cherche la septième planète. Je ne lui dis pas encore que je la cherche aussi.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Grande Lunette de l'Observatoire a été polie par les fondateurs eux-mêmes, avec du sable du lac. On y voit les anneaux des planètes et, par temps clair, le phare de l'île la plus lointaine.", {}),
					L("Le Grand Astrolabe, au pied de ma tour, suit le ciel à la seconde près. Il ne s'est jamais trompé. Moi si, parfois. Mais lui ne le dit à personne.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("On raconte que je parle à la lune. C'est parfaitement vrai. Elle ne répond pas, mais elle écoute très bien.", {}, "rire"),
					L("Maître Rouage prétend que son horloge est plus précise que mes étoiles. Nous avons un pari en cours depuis onze ans. L'enjeu : un pot de miel.", {}),
				],
				"interpelle": [L("Vous, là ! Vous savez où se trouve l'étoile du Nord ? Non ? Il faut que nous parlions.", {"visites_max": 0}), L("{surnom} ! Le ciel est clair, ce soir !", {"visites_min": 1}, "salut")],
			}},
		{"id": "alambic_om", "nom": "Maîtresse Alambic", "titre": "maîtresse des élixirs", "maison": "elixirs_maitre", "village": "ombrelac",
			"agenda": [[7, 8, "estrade_s5"], [8, 12, "elixirs_maitre"], [12, 13, "estrade_s5"], [13, 17, "elixirs_maitre"], [17, 19, "serres"], [19, 20, "estrade_s5"], [20, 22, "@biblio"], [22, 7, "maison"]],
			"azur": {"taille": 0.95}, "teinte": [0.96, 0.8, 0.7], "mj": {"objet": "louche"},
			"humeur_base": 0.8, "traits": {"bavard": 0.9, "humour": 0.9, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"champignon": 2.5, "miel": 2.0, "nectar_fee": 2.0, "poussiere_fee": 1.5}, "deteste": {"cerf_volant": -0.5},
			"tics": ["Intéressant !", "Une pincée, pas plus !", "Ça bouillonne !"],
			"repliques": {
				"accueil": [
					L("Entrez, entrez ! Ysaure Alambic, maîtresse des élixirs. Ne touchez à rien qui fume, qui brille ou qui chante. Le reste, vous pouvez. Mais avec des gants.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Vous tombez bien : j'ai besoin de quelqu'un pour goûter. Non ? Personne ne veut jamais goûter.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bouillonnante ! L'athanor chauffe, les cornues chantent, et Anatole n'a encore rien transformé en chou. La journée est jeune.", {}, "rire"),
					L("Le soir, je vais aux serres cueillir les fleurs de lune. Elles n'ouvrent qu'à la nuit, et leur parfum dure jusqu'au matin.", {"soir": true}),
				],
				"lui": [
					L("Un élixir, c'est de la cuisine qui a fait des études. Il faut de la patience, du flair, et une bonne hotte. Surtout une bonne hotte.", {}, "rire"),
					L("Sidonie, du Crépuscule, a un don. Elle a réussi l'élixir de rire du premier coup. Moi, il m'a fallu sept essais. Et j'ai ri pendant trois jours au sixième.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Les racines de nénuphar du lac font un élixir de sommeil merveilleux. Une goutte, et on dort comme un bienheureux. Deux gouttes, et on dort jusqu'au mardi suivant.", {}),
					L("Firmin, le jardinier, me prépare des simples dans les serres : la sauge, la mélisse, la fleur de lune. Sans lui, je ne ferais que de l'eau colorée.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Maître Équerre a goûté l'élixir de rire de Sidonie. Il a ri une heure. Puis il a demandé la recette. Pour la ranger, a-t-il dit. Moi, je crois qu'il veut recommencer.", {}, "rire"),
					L("Il paraît que la Rectrice boit son thé à la menthe avec une goutte d'élixir de patience. Je ne confirme rien. Mais je lui en prépare un flacon tous les mois.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Oui, vous ! Sentez-moi ça. Alors ? Ça sent la pomme ou le soufre ?", {"visites_max": 0}, "rire"), L("{surnom} ! Venez voir ce qui bouillonne !", {"visites_min": 1}, "salut")],
			}},
		{"id": "equerre_om", "nom": "Maître Équerre", "titre": "maître de géométrie", "maison": "amphi_maitre", "village": "ombrelac", "vouvoie": true,
			"agenda": [[7, 8, "estrade_s2"], [8, 10.5, "@biblio"], [10.5, 12, "amphi_maitre"], [12, 13, "estrade_s2"], [13, 15, "@cour"], [15, 16, "@conseil"], [16, 19, "amphi_maitre"], [19, 20, "estrade_s2"], [20, 22, "@biblio"], [22, 7, "maison"]],
			"azur": {"taille": 1.05}, "teinte": [0.94, 0.8, 0.7], "mj": {"objet": "livre"},
			"humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.3, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.5},
			"aime": {"boussole": 2.5, "engrenage": 1.5, "the_menthe": 1.5, "montre_envers": 1.0}, "deteste": {"poussiere_fee": -1.0, "gelee_slime": -2.0},
			"tics": ["Rigoureusement.", "Exactement à angle droit.", "Ce n'est pas carré."],
			"repliques": {
				"accueil": [
					L("Bonjour. Théodore Équerre, maître de géométrie. Vous êtes entré par le viaduc ? Sept arches, rigoureusement égales. Une merveille de proportions. Le reste du château, je préfère ne pas en parler.", {"visites_max": 1}),
					L("{surnom}. Vous vous tenez plus droit que la dernière fois. C'est un progrès.", {"visites_min": 2}),
				],
				"humeur": [
					L("Mesurée. Ni bonne ni mauvaise : parfaitement au milieu, comme il se doit.", {}),
					L("Le soir, je lis à la Bibliothèque. Les livres sont rangés par taille, sur la troisième rangée. C'est la seule rangée bien rangée. Je m'en suis chargé.", {"soir": true}),
				],
				"lui": [
					L("La géométrie, c'est la vérité qu'on peut tracer à la règle. Les sortilèges, l'élixir, les étoiles : tout repose sur elle. Mes collègues l'oublient. Je le leur rappelle. Souvent.", {}),
					L("J'ai goûté, par mégarde, un élixir de rire. J'ai ri une heure. C'était mathématiquement inacceptable. … Mais assez agréable, je dois l'avouer.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Les gradins de l'Amphithéâtre font trente-huit centimètres chacun. Exactement. J'ai fait refaire le quatrième, qui en faisait trente-neuf.", {}),
					L("Le cloître est un carré parfait, à trois centimètres près. Je ne dors plus très bien depuis que je les ai mesurés, ces trois centimètres.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Je ne prête pas l'oreille aux rumeurs : elles ne sont jamais à angle droit. Mais j'ai remarqué que l'horloge avance d'une minute le jeudi. Rouage dit que c'est la faute des élèves.", {}),
					L("Il paraît que je dors au garde-à-vous. C'est faux. Je dors à quatre-vingt-dix degrés. Ce n'est pas la même chose.", {}, "rire"),
				],
				"interpelle": [L("Vous. Tenez-vous droit.", {"visites_max": 0}), L("{surnom}. Bonjour, rigoureusement.", {"visites_min": 1}, "salut")],
			}},
		{"id": "sortelame_om", "nom": "Dame Sortelame", "titre": "maîtresse des sortilèges", "maison": "sort_cabinet", "village": "ombrelac", "vouvoie": true,
			"agenda": [[6, 7, "@cour"], [7, 8, "estrade_s6"], [8, 12, "sort_cabinet"], [12, 13, "estrade_s6"], [13, 15, "sort_maitre"], [15, 19, "sort_maitre"], [19, 20, "estrade_s6"], [20, 23, "sort_cabinet"], [23, 6, "maison"]],
			"azur": {"taille": 1.0}, "teinte": [0.82, 0.6, 0.45], "mj": {"objet": "baton", "tenue": "mage"},
			"humeur_base": 0.3, "traits": {"bavard": 0.3, "humour": 0.5, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"rubis": 2.0, "plume_vent": 2.0, "pain_miel": 1.0, "chocolat_chaud": 1.5}, "deteste": {"gelee_slime": -1.5},
			"tics": ["En garde.", "Concentration.", "Encore une fois."],
			"repliques": {
				"accueil": [
					L("Brunehaut Sortelame. J'enseigne les sortilèges, dans la tour du même nom. Vous n'avez pas de baguette ? Bien. Ici, on apprend d'abord à ne pas s'en servir.", {"visites_max": 1}),
					L("{surnom}. Vous revenez. La persévérance est la première des qualités. La deuxième, c'est de savoir esquiver.", {"visites_min": 2}),
				],
				"humeur": [
					L("Stable. Barnabé a fait jaillir une étincelle ce matin. Une vraie. Je lui ai dit que c'était un début. Il a cru que j'étais polie. Je ne suis jamais polie : c'était un début.", {}),
					L("Le soir, je m'entraîne seule, dans le Cabinet en haut de la tour. Les marches flottantes s'allument une à une quand on monte. C'est très beau. Et très haut.", {"soir": true}),
				],
				"lui": [
					L("Dans ma jeunesse, j'ai disputé des duels dans tout l'archipel. Je n'en ai perdu aucun. Pas parce que j'étais la plus forte, mais parce que je savais quand il ne fallait pas se battre.", {}),
					L("Un sortilège, c'est une phrase qu'on dit au monde. Il faut la dire clairement, poliment, et ne pas se tromper de mot. Sinon le monde répond n'importe quoi.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Salle des Cercles, au pied de ma tour, a un grand cercle de runes gravé dans le sol. C'est là que les élèves s'exercent. Le cercle absorbe les sortilèges ratés. Il en a absorbé beaucoup.", {}),
					L("Les marches flottantes de la tour ne tombent jamais. Les élèves, si. Mais la rambarde de lumière les rattrape. En général.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Malo voudrait me défier en duel. Il a du cran. Je l'attends. Dans dix ans.", {}),
					L("On dit que j'ai fait fuir un dragon, autrefois, d'un seul regard. C'était un très petit dragon. Et un très long regard.", {}, "rire"),
				],
				"interpelle": [L("Vous. Votre posture est mauvaise. Pieds écartés, épaules basses.", {"visites_max": 0}), L("{surnom}. En garde.", {"visites_min": 1}, "salut")],
			}},
		{"id": "reliure_om", "nom": "Dame Reliure", "titre": "bibliothécaire de l'Académie", "maison": "biblio_comptoir", "village": "ombrelac", "vouvoie": true,
			"agenda": [[7, 8, "estrade_s7"], [8, 12, "biblio_comptoir"], [12, 13, "estrade_s7"], [13, 21, "biblio_comptoir"], [21, 7, "maison"]],
			"azur": {"taille": 0.92}, "teinte": [0.95, 0.82, 0.72], "mj": {"objet": "livre"},
			"humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"grimoire": 2.5, "the_menthe": 2.0, "plume_corbeau": 1.5, "carte_postale": 1.5}, "deteste": {"gelee_slime": -2.5, "vieille_botte": -1.0},
			"tics": ["Chut.", "Page quarante-deux.", "Avec des gants, s'il vous plaît."],
			"repliques": {
				"accueil": [
					L("Chut… Bonjour. Clémence Reliure, bibliothécaire. Ici, on parle bas, on tourne les pages avec soin, et on ne corne jamais, jamais un coin de page. Les livres s'en souviennent.", {"visites_max": 1}),
					L("{surnom}. Vous avez rendu le livre que je vous ai prêté ? Je plaisante. Je ne prête pas de livres aux visiteurs. Pas encore.", {"visites_min": 2}),
				],
				"humeur": [
					L("Paisible. Barnabé lit, Sidonie lit, Maître Équerre range la troisième rangée par taille. Encore. Tout est en ordre. Presque.", {}),
					L("Le soir, quand les lampes vertes sont allumées et que tout le monde est parti, la Bibliothèque chuchote. Ce sont les pages qui se reposent.", {"soir": true}),
				],
				"lui": [
					L("Je connais l'emplacement de chaque livre de la Bibliothèque. Il y en a vingt-trois mille quatre cent douze. Treize, depuis que Barnabé a recopié ses notes.", {}),
					L("Un livre, c'est une porte. Certaines s'ouvrent sur des pays, d'autres sur des gens, d'autres encore sur des placards. Ceux-là sont les plus drôles.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La galerie de la Bibliothèque fait tout le tour de la salle, à cinq mètres soixante. On y monte par le grand escalier, au sud. Pas par les rayonnages. Je dis cela pour Anatole.", {}),
					L("Les fondateurs ont laissé un registre : tout ce qu'ils savaient du lac, des falaises et des étoiles. Il est dans la réserve. Il est écrit à l'encre de brume. On ne peut le lire que les jours de brouillard.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il y a un livre qui se range tout seul. C'est exact. Il est très bien élevé. Je ne dirai pas lequel : les élèves passeraient leurs journées à le déranger.", {}),
					L("Maître Équerre range la troisième rangée par taille, et je la range par sujet, chaque nuit. Nous ne nous sommes jamais parlé de la chose. Cela dure depuis neuf ans.", {}, "rire"),
				],
				"interpelle": [L("Chut !", {"visites_max": 0}), L("{surnom}… bonjour. À voix basse, s'il vous plaît.", {"visites_min": 1}, "salut")],
			}},
		{"id": "rouage_om", "nom": "Maître Rouage", "titre": "gardien de l'horloge", "maison": "horloge_salle", "village": "ombrelac",
			"agenda": [[6, 12, "horloge_salle"], [12, 13, "estrade_s1"], [13, 19, "rouages"], [19, 20, "estrade_s1"], [20, 23, "horloge_salle"], [23, 6, "maison"]],
			"azur": {"taille": 0.88}, "teinte": [0.92, 0.78, 0.66], "mj": {"objet": "marteau"},
			"humeur_base": 0.4, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"engrenage": 2.5, "ressort": 2.0, "montre_envers": 2.5, "miel": 1.5}, "deteste": {"gelee_slime": -1.5},
			"tics": ["Tic, tac.", "À la seconde près.", "Huilé et remonté."],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Anselme Rouage, gardien de l'horloge. Tic, tac. Vous entendez ? Le cœur du château. Je le remonte tous les matins à six heures, et il ne m'a jamais déçu. Presque jamais.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous arrivez à onze heures, quatorze minutes et… sept secondes. Très bien. J'aime les gens ponctuels.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien remontée ! L'horloge est à l'heure, la cloche a sonné juste, et le balancier bat comme un cœur de vingt ans. Le mien bat comme un cœur de quatre-vingts, mais il bat.", {}, "rire"),
					L("Le soir, j'écoute la cloche sonner les heures, de la Salle des Poids. Chaque coup descend jusqu'au fond de la tour. Je les compte. Je ne me suis jamais trompé.", {"soir": true}),
				],
				"lui": [
					L("Mon père était horloger, et son père avant lui. Moi, j'ai la plus grande horloge de l'archipel. Le balancier fait plus de vingt mètres. Mon père en serait jaloux. Il serait fier, aussi.", {}),
					L("J'ai fait sonner la cloche à quatre heures et demie, la semaine dernière. Une erreur de ressort. Toute l'Académie s'est levée. La Rectrice m'a regardé. Simplement regardé. J'ai réparé le ressort dans l'heure.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Chambre des Rouages est à vingt-huit mètres. On y voit le dos des quatre cadrans, et l'ombre des aiguilles. C'est le plus bel endroit du château. Je suis peut-être un peu partial.", {}),
					L("Les cadrans de l'horloge sont en verre opalin. La nuit, ils s'allument. Les pêcheurs du lac se guident dessus pour rentrer.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Fauconnier prétend que ses étoiles sont plus précises que mon horloge. Nous avons parié un pot de miel il y a onze ans. Le pari n'est pas tranché. Le miel non plus : nous le mangeons ensemble.", {}, "rire"),
					L("L'horloge avance d'une minute le jeudi. Je ne sais pas pourquoi. Les élèves disent que c'est parce qu'on ment davantage le jeudi. C'est le jour des contrôles.", {}, "rire"),
				],
				"interpelle": [L("Vous avez l'heure ? Non ? Moi si.", {"visites_max": 0}, "rire"), L("{surnom} ! Tic, tac !", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ les gens du château
		{"id": "herse_om", "nom": "Gaspard Herse", "titre": "portier de l'Académie", "maison": "portier", "village": "ombrelac",
			"agenda": [[6, 12, "portier"], [12, 13, "@cour"], [13, 22, "portier"], [22, 6, "maison"]],
			"azur": {"taille": 1.1, "carrure": 1.2}, "teinte": [0.84, 0.64, 0.5], "mj": {"objet": "lanterne"},
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"pain_miel": 2.0, "chocolat_chaud": 2.0, "tarte_potiron": 2.0, "carte_postale": 1.5}, "deteste": {"gelee_slime": -1.0},
			"tics": ["Halte-là !", "Bon.", "Ma moustache me dit que…"],
			"repliques": {
				"accueil": [
					L("Halte-là ! … Ah, un visiteur. Bienvenue à l'Académie d'Ombrelac ! Gaspard Herse, portier. Si vous êtes venu à pied par le viaduc, vous avez des mollets solides. Ma moustache vous salue.", {"visites_max": 1}, "salut"),
					L("Tiens, {surnom} ! Ma moustache vous avait reconnu de l'autre bout du viaduc. Elle frémit pour les gens qu'elle aime bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Pas un intrus, pas une gargouille en fuite, et Malo n'a fait que douze tours de cour. Une journée calme.", {}, "rire"),
					L("Le soir, j'allume les lanternes du viaduc, une à une. Sept arches, quatorze lanternes. Après, je ferme la herse et je fais ma ronde.", {"soir": true}),
				],
				"lui": [
					L("Je garde la porte depuis vingt-deux ans. J'ai vu passer trois Recteurs, deux cents élèves, un ours (perdu), et une fois un bateau. Sur le viaduc. Ne me demandez pas.", {}, "rire"),
					L("Tobie veut devenir portier, comme moi. Je lui ai dit qu'il fallait d'abord une moustache. Il en a dessiné une au charbon. Elle était très réussie.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le viaduc enjambe la gorge du Torrent depuis la Colline du Guet. Sept arches, et la herse au bout. Personne n'entre à l'Académie sans passer devant moi. Sauf les oiseaux. Les oiseaux, je les laisse.", {}),
					L("Le débarcadère est en bas, au sud. Le bateau y accoste, puis on monte la route en lacets jusqu'au Guet. C'est long. Mais la vue sur le château, en arrivant, vaut toutes les ampoules.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il paraît qu'Anatole a essayé de faire pousser une moustache à la statue de la cour. Il a réussi sur lui-même. Il l'a eue trois jours. Elle lui allait bien.", {}, "rire"),
					L("On dit que la brume du lac garde les secrets des fondateurs. Moi, je dis qu'elle garde surtout mes lanternes humides.", {}),
				],
				"interpelle": [L("Halte-là ! … Non, je plaisante. Entrez donc !", {"visites_max": 0}, "rire"), L("{surnom} ! Ma moustache vous salue !", {"visites_min": 1}, "salut")],
			}},
		{"id": "fournil_om", "nom": "Mère Fournil", "titre": "intendante de l'Académie", "maison": "cheminee_feu", "village": "ombrelac",
			"agenda": [[6, 7, "cheminee_feu"], [7, 8, "@service"], [8, 11.5, "cheminee_feu"], [11.5, 13, "@service"], [13, 18, "serres"], [18, 20, "@service"], [20, 22, "cheminee_feu"], [22, 6, "maison"]],
			"azur": {"taille": 0.95, "carrure": 1.15}, "teinte": [0.96, 0.8, 0.68], "mj": {"objet": "plateau"},
			"humeur_base": 0.7, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"miel": 2.0, "tarte_potiron": 2.5, "pomme": 1.5, "baies": 1.5, "the_menthe": 1.0}, "deteste": {"gelee_slime": -2.0},
			"tics": ["Mange donc !", "Mon petit…", "Doux Jésus des fourneaux !"],
			"repliques": {
				"accueil": [
					L("Oh, un visiteur ! Roseline Fournil, l'intendante. Vous avez faim ? Vous avez l'air d'avoir faim. Tout le monde a l'air d'avoir faim quand on vient de monter le viaduc.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous revoilà ! Asseyez-vous, je vous garde une part de tarte. Ne dites rien à Tobie.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Débordée, mais heureuse ! Deux cents couverts à midi, la tarte au potiron a fait l'unanimité, et Maître Équerre a même repris du pain. Coupé en carrés, mais repris.", {}, "rire"),
					L("Le soir, je m'assieds devant la grande cheminée de la Grande Salle, quand tout le monde est parti. Le feu crépite, et je compte les miettes. Il y en a toujours sous la table de l'Aube.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je nourris l'Académie depuis trente ans. J'ai vu grandir des élèves qui sont devenus maîtres. Ils me demandent encore de la tarte. On ne cesse jamais d'avoir dix ans devant une tarte.", {}),
					L("Mon secret, c'est le miel du Guet et les pommes du verger. Et une pincée de cannelle. Et beaucoup d'amour. Surtout ne le répétez pas, ça ferait de la concurrence.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Grande Salle a trois longues tables, la table d'honneur sur l'estrade, et la plus grande cheminée de l'archipel. On pourrait y rôtir un bœuf. On y rôtit surtout des châtaignes.", {}),
					L("Firmin me fait pousser les herbes et les légumes dans les serres. Sa sauge est la meilleure du monde. Je le lui dis tous les jours, pour qu'il continue.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("La Rectrice prend son thé à la menthe sans sucre. Mais avec trois biscuits. Je les compte. Je ne dis rien.", {}, "rire"),
					L("Tobie m'a demandé si les fantômes mangeaient. Je lui ai dit que oui, et qu'ils adoraient les restes. Depuis, il finit toujours son assiette.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Vous avez mangé ?", {"visites_max": 0}), L("{surnom} ! Venez, il reste de la tarte !", {"visites_min": 1}, "salut")],
			}},
		{"id": "buis_om", "nom": "Firmin Buis", "titre": "jardinier de l'Académie", "maison": "serres", "village": "ombrelac",
			"agenda": [[6, 11, "@jardin"], [11, 13, "serres"], [13, 15, "@jardin"], [15, 20, "serres"], [20, 6, "maison"]],
			"azur": {"taille": 1.05}, "teinte": [0.82, 0.6, 0.44], "mj": {"objet": "panier"},
			"humeur_base": 0.5, "traits": {"bavard": 0.3, "humour": 0.5, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"bouquet_tournesols": 2.5, "champignon": 1.5, "miel": 1.5, "baies": 1.5}, "deteste": {"cerf_volant": -1.0},
			"tics": ["Hm.", "Ça pousse.", "Doucement…"],
			"repliques": {
				"accueil": [
					L("Bonjour. Firmin. Le jardinier. Marchez dans les allées, s'il vous plaît : les fleurs ont des racines, et les racines ont des sentiments.", {"visites_max": 1}),
					L("{surnom}. Les rosiers vous ont reconnu. Ils se sont redressés. Si, si.", {"visites_min": 2}),
				],
				"humeur": [
					L("Ça pousse. Quand ça pousse, je suis content.", {}),
					L("La nuit, je vais voir les fleurs de lune s'ouvrir dans les serres. Sidonie vient avec moi. Elle leur parle mieux que moi.", {"soir": true}),
				],
				"lui": [
					L("Je taille les buis du cloître au cordeau. Maître Équerre vérifie à l'équerre. Nous ne sommes jamais d'accord. Les buis, eux, sont contents.", {}, "rire"),
					L("J'ai grandi dans les forêts des Monts Gris, au nord de l'île. Mon grand-père disait : « Un arbre, c'est un homme qui a pris son temps. » Je prends le mien.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le jardin du cloître a quatre carrés, un arbre au milieu de chacun, et un cyprès à chaque coin. La fontaine au centre. Les fondateurs l'ont dessiné. Je ne fais que l'entretenir.", {}),
					L("Les serres sont près de la Tour de l'Horloge. Il y pousse la sauge de Mère Fournil, les simples de Maîtresse Alambic, et une grande fougère qui grandit un peu trop vite. Je la surveille.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Il n'y a pas de passage secret sous la fontaine. Il y a une grenouille. Elle s'appelle Hortense. Elle est très discrète.", {}),
					L("La grande fougère a pris un mètre en une nuit. Je l'ai mesurée deux fois. Maître Équerre l'a mesurée trois fois. Nous sommes d'accord, pour une fois. C'est inquiétant.", {}),
				],
				"interpelle": [L("Attention à la plate-bande.", {"visites_max": 0}), L("{surnom}. Bonjour.", {"visites_min": 1}, "salut")],
			}},
	]

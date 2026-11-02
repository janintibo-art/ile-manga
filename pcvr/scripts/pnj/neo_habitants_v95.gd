extends RefCounted
## V95 : les gens de Néopolis, la ville cyberpunk. Des humains, des androïdes, et des « modifiés »
## (des humains qui portent un implant : un avant-bras de métal, une plaque sur la tempe, des
## circuits qui s'allument sous la peau).
##  - le Marché de Nuit : Mamie Kiku (la doyenne de la ville, maîtresse de thé, sans un seul implant :
##    « mes genoux sont d'origine ») et son petit-fils Hiro (le cuisinier de nouilles, qui travaille
##    avec Gaston, le bras-robot de l'étal, qui cuisine mieux que lui) ;
##  - les Ruelles : Kenji Volt (le réparateur, au bras bionique), sa fille Mio (9 ans), et Monsieur Fil
##    (un marchand de programmes « pas chers »… ce qui inquiète Glitch) ;
##  - la Place des Hologrammes : Zéro (le plus vieux des androïdes, le balayeur, qui a perdu sa voix :
##    la quête « La voix de Zéro », journal_v56) ;
##  - la Tour Axiome : Sept (l'androïde d'accueil, qui ne dort jamais) et Madame Yuna Takeda (la mairesse) ;
##  - le Boulevard et les Arcades : Kira (la danseuse aux circuits de lumière), Turbo (12 ans, champion
##    de Dragon-Pixel) et Glitch (une hackeuse au grand cœur, une visière sur les yeux) ;
##  - le Jardin Zen : Maître Ishi (le jardinier) et Aïko (une androïde qui a appris à peindre) ;
##  - le Quai des Drones : Cargo (un grand androïde docker, très doux, qui parle aux mouettes).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure (les lieux :
## neo_ville_v95.gd) ; le corps, les implants et les objets : pnj_neo_v95.gd. Fiche « neo » : android,
## implant, circuit (la couleur des circuits), peau (celle d'un androïde), tenue, c, c2 (les couleurs
## de la tenue), chapeau, props (visiere, led_tempe, collier, antenne, monocle, oreillettes), objet.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "À plus, {surnom}. Garde tes batteries chargées.", "si": {"genre": "humain"}, "geste": "salut"},
		{"t": "Fin de la conversation. Ce fut un plaisir enregistré, {surnom}.", "si": {"genre": "android"}, "geste": "salut"},
		{"t": "File ! Et regarde en l'air avant de traverser : les voitures volent, ici.", "si": {}, "geste": "salut"},
		{"t": "Bonne nuit… ou bonjour. À Néopolis, on ne sait jamais très bien.", "si": {}},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Ça ne se fait pas, même à Néopolis.", "si": {"genre": "humain"}, "geste": "colere", "humeur": -0.4},
		{"t": "Choc détecté. Je note : « pas gentil ». Je n'efface pas mes notes.", "si": {"genre": "android"}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Il y a des caméras partout, tu sais. Et elles ont toutes vu.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Oh, merci. C'est… analogique. J'aime bien les choses analogiques.", "si": {"genre": "humain"}},
		{"t": "Objet reçu. Analyse : gentil. Merci, {surnom}.", "si": {"genre": "android"}},
		{"t": "Merci, {surnom}. C'est gentil.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Oh, {surnom}, tu as tout compris !", "si": {"genre": "humain"}, "geste": "rire"},
		{"t": "{dernier_cadeau}… Mes circuits chauffent un peu. Je crois que ça s'appelle « être touché ».", "si": {"genre": "android"}, "geste": "rire"},
		{"t": "{dernier_cadeau} ! Merci, {surnom}, c'est exactement ce qu'il me fallait !", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Hum… merci. Je vais le… ranger. Quelque part. Loin.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Non merci. À Néopolis, on se bat à Dragon-Pixel, pas autrement.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Ici, tout le monde se souvient de tout. Les humains un peu moins bien que les androïdes, c'est tout.", "si": {}}],
	"quete_inconnue": [{"t": "Moi ? Je ne t'ai rien demandé… Mais la petite Mio, au Marché de Nuit ou dans les Ruelles, elle a l'air d'avoir besoin d'aide.", "si": {}}],
	"blague": [
		{"t": "Pourquoi les androïdes ne jouent jamais à cache-cache ? Parce qu'ils ont tous le GPS !", "si": {}, "geste": "rire"},
		{"t": "Quel est le plat préféré des robots ? Les nouilles… à puces !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un néon dit à un autre néon ? « Tu m'allumes ! »", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on un ordinateur qui chante ? Un Dell… Non, attends. Un… Bon, Glitch la raconte mieux que moi.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi la voiture volante est-elle en retard ? Elle a trouvé un bouchon… dans les nuages.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Reviens quand on sera de nouveau amis.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu en as {pieces}. Repasse plus tard.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un !", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein, {surnom}.", "si": {}}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces.", "si": {}}],
	"marchande_oui": [{"t": "Bon, d'accord. Mais ne le dis à personne.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Non. Mes prix sont déjà calculés au plus juste.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Génial !", "Trop bien !", "Ha ha !", "Waouh !"],
		"neutre": ["Bon.", "Hm.", "Alors…", "Voyons…"],
		"triste": ["Bof…", "Pfff…", "Mouais…", "Aïe…"],
		"colere": ["Ça suffit !", "Grrr.", "Pas cool !", "Tss."],
	},
	"tics": ["C'est Néopolis.", "Ça clignote.", "On verra bien.", "Tout est connecté."],
	"humeur_mots": [[0.6, "lumineux"], [0.25, "de bonne humeur"], [-0.25, "un peu en veille"], [-0.6, "maussade"], [-2.0, "en surchauffe"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "camarade"], [75, "ami de toujours"], [95, "enfant de Néopolis"]],
}

const BASE_ANDROID := {
	"prefixes": {
		"joie": ["Joie détectée.", "Excellent.", "Hi hi. (Rire enregistré.)", "Positif."],
		"neutre": ["Bien.", "Noté.", "Traitement…", "Affirmatif."],
		"triste": ["Batterie morale faible.", "Hmm.", "Dommage.", "Erreur triste."],
		"colere": ["Désaccord.", "Non.", "Alerte.", "Je proteste."],
	},
	"tics": ["Je calcule.", "Mise à jour en cours.", "Bip.", "C'est logique."],
	"humeur_mots": [[0.6, "à cent pour cent"], [0.25, "bien chargé"], [-0.25, "un peu déchargé"], [-0.6, "en mode économie"], [-2.0, "en erreur rouge"]],
	"surnoms": [[0, "visiteur"], [25, "utilisateur ami"], [50, "ami enregistré"], [75, "ami prioritaire"], [95, "ami pour toujours (sauvegardé)"]],
}

## Peaux, cheveux, yeux
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const NOIR := [0.06, 0.05, 0.05]
const BRUN := [0.25, 0.16, 0.1]
const BLANC := [0.93, 0.92, 0.9]
const GRIS := [0.62, 0.61, 0.6]
const ARGENT := [0.8, 0.82, 0.86]
const ROSE_NEON := [0.98, 0.3, 0.68]
const BLEU_NEON := [0.2, 0.62, 0.98]
const VERT_NEON := [0.3, 0.92, 0.45]
const Y_BRUN := [0.3, 0.18, 0.1]
const Y_NOIR := [0.14, 0.1, 0.08]
const Y_GRIS := [0.45, 0.5, 0.55]
const Y_CYAN := [0.2, 0.85, 1.0]
const Y_AMBRE := [1.0, 0.62, 0.2]
const Y_ROSE := [1.0, 0.4, 0.75]
const CYAN := [0.25, 0.9, 1.0]
const MAGENTA := [1.0, 0.3, 0.8]
const VERT := [0.3, 1.0, 0.45]
const AMBRE := [1.0, 0.6, 0.18]
const ORANGE := [1.0, 0.45, 0.12]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


## Une réplique de Zéro avant qu'il retrouve sa voix (la quête n'est pas finie : pas encore
## commencée, ou en cours) : deux répliques, une pour chaque état.
static func Z(t: String, geste: String = "", si: Dictionary = {}) -> Array:
	var a: Dictionary = si.duplicate()
	a["q56"] = "ne_voix_zero="
	var b: Dictionary = si.duplicate()
	b["q56"] = "ne_voix_zero=en_cours"
	return [L(t, a, geste), L(t, b, geste)]


static func is_android(d: Dictionary) -> bool:
	return bool((d.get("neo", {}) as Dictionary).get("android", false))


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var genre: String = "android" if is_android(out) else "humain"
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			var lst: Array = []
			for e in COMMON[k]:
				var si: Dictionary = (e as Dictionary).get("si", {})
				if si.has("genre") and str(si["genre"]) != genre:
					continue
				var e2: Dictionary = (e as Dictionary).duplicate(true)
				(e2["si"] as Dictionary).erase("genre")
				lst.append(e2)
			rep[k] = lst
	out["repliques"] = rep
	var base: Dictionary = BASE_ANDROID if genre == "android" else BASE
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = base[k]
	out = Azur.complete(out)
	out["groupe"] = "neo"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Marché de Nuit
		{"id": "mamie_kiku", "nom": "Mamie Kiku", "titre": "doyenne de Néopolis, maîtresse de thé du Marché de Nuit", "maison": "porte_mamie_kiku", "village": "neo",
			"agenda": [[6, 9, ["place_2", "place_3"]], [9, 12, "jardin_mediter_1"], [12, 16, "maison"], [16, 24, "the_kiku"], [0, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "yeux": Y_NOIR, "haut": [0.35, 0.12, 0.25], "vieux": true, "taille": 0.94},
			"teinte": PEAU[1],
			"neo": {"tenue": "kimono", "c": [0.42, 0.14, 0.3], "c2": [0.98, 0.78, 0.86]},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"the_menthe": 2.5, "the_stellaire": 2.0, "gateau_lune": 2.0, "fleur_lune": 1.5}, "deteste": {"soda_neon": -0.5},
			"tics": ["Patience, patience.", "De mon temps…", "Le thé ne se presse pas.", "Hé hé."],
			"surnoms": [[0, "mon petit"], [25, "mon grillon"], [50, "ma petite lanterne"], [75, "mon trésor"], [95, "enfant de Néopolis"]],
			"repliques": {
				"accueil": [
					L("Bonsoir, mon petit. Moi, c'est Mamie Kiku. Je sers le thé au Marché de Nuit depuis… depuis qu'il n'y avait ici qu'un ponton, trois cabanes et un lampadaire. Assieds-toi. Le thé, ça ne se boit pas debout.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens. J'ai gardé une tasse au chaud. Enfin, Gaston l'a gardée au chaud. Moi, je l'ai regardée.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Comme une théière : chaude dedans, un peu cabossée dehors.", {}),
					L("Tout le monde ici a des puces, des écrans, des bras en métal. Moi, j'ai mes deux mains, ma théière et ma mémoire. Elle n'a jamais besoin de mise à jour. Enfin… presque jamais.", {}, "rire"),
					L("La nuit, quand les néons s'allument, le marché sent le bouillon et le gingembre. C'est mon heure préférée.", {"soir": true}),
				],
				"lui": [
					L("Quand je suis arrivée, Néopolis n'existait pas. Il y avait une dalle de béton sur la mer, et on disait qu'on allait y construire « la ville du futur ». Je me suis dit : il faudra bien que quelqu'un serve le thé, dans le futur.", {}),
					L("Je n'ai pas un seul implant. Tous les ans, le docteur me dit : « Madame Kiku, un petit genou neuf ? » Et tous les ans, je lui réponds : mes genoux sont d'origine, garantis quatre-vingts ans, et ils ne sont pas encore en panne.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon petit-fils Hiro fait les nouilles juste à côté, avec Gaston, le bras-robot. Il croit qu'il a tout appris à Gaston. Moi, je crois que c'est le contraire. Mais je ne le lui dis pas : il est fier.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Néopolis, c'est une ville qui ne dort jamais. Ça tombe bien : à mon âge, on ne dort plus beaucoup non plus.", {}, "rire"),
					L("Les androïdes ? Ce sont des voisins comme les autres. Plus polis, souvent. Sept, à la Tour Axiome, me dit bonjour quarante-deux fois par jour. Je compte.", {"sujet_min": ["ile", 1]}),
					L("Le Jardin Zen, au sud-est, c'est le seul endroit sans écran. J'y vais le matin, avec Maître Ishi. On ne se dit rien pendant une heure. C'est la meilleure conversation de la journée.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Il paraît que Monsieur Fil, dans les Ruelles, vend des programmes « pas chers ». Chez moi, on disait : ce qui n'est pas cher finit toujours par coûter cher. Méfie-toi, mon petit.", {}),
					L("Le vieux Zéro ne parle plus. Il balaie toujours la place, il me fait toujours un petit signe… mais plus un mot. La petite Mio en est toute triste.", {"q56": "ne_voix_zero="}),
					L("Zéro a retrouvé sa voix ! Il m'a chanté une berceuse de mon enfance. Je ne sais pas où il l'a apprise. Je ne la lui ai jamais chantée… Enfin, je crois.", {"q56": "ne_voix_zero=finie"}, "rire"),
				],
				"interpelle": [L("Toi, là ! Une tasse de thé ? Ça réchauffe, même les androïdes.", {"visites_max": 0}, "salut"), L("{surnom} ! La théière est chaude.", {"visites_min": 1})],
			}},
		{"id": "hiro", "nom": "Hiro", "titre": "cuisinier de nouilles du Marché de Nuit", "maison": "porte_hiro", "village": "neo",
			"agenda": [[11, 14, "cuisine_hiro"], [14, 17, ["quai_banc_2", "marche_table_3"]], [17, 2, "cuisine_hiro"], [2, 11, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "yeux": Y_BRUN, "haut": [0.95, 0.95, 0.94]},
			"teinte": PEAU[1],
			"neo": {"tenue": "chef", "c": [0.75, 0.12, 0.12], "chapeau": "cuisinier"},
			"humeur_base": 0.55, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"nouilles_neo": 1.0, "champignon": 2.0, "sardine": 1.5, "the_menthe": 1.5}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Chaud devant !", "Encore un bol !", "Gaston, la louche !", "C'est la recette de Mamie."],
			"repliques": {
				"accueil": [
					L("Bienvenue au meilleur étal de nouilles de Néopolis ! Je suis Hiro, et voici Gaston, mon bras-robot. C'est moi qui lui ai tout appris. (Gaston égoutte les nouilles d'un geste parfait.) … Enfin, presque tout.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Un bol ? Gaston t'a reconnu : il a déjà sorti le grand bol.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Le bouillon mijote depuis ce matin, les nouilles sont fraîches, Gaston est bien huilé. Que demander de plus ?", {}),
					L("Un peu vexé. Hier, un client m'a dit que les nouilles étaient meilleures quand c'était Gaston qui les faisait. … C'était Gaston qui les faisait. Mais quand même.", {}, "colere"),
					L("Le coup de feu, c'est maintenant ! Tout Néopolis a faim à minuit.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Ma grand-mère, c'est Mamie Kiku, la dame du thé, juste là. Elle m'a appris le bouillon. Il faut huit heures, des os, du gingembre, et surtout ne jamais regarder son téléphone en surveillant la marmite.", {}),
					L("Gaston, je l'ai acheté d'occasion il y a cinq ans. Il était programmé pour peindre des voitures. Aujourd'hui, il fait des nouilles. Parfois, il essaie encore de peindre les bols. On les vend plus cher.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Au Marché de Nuit, tout le monde se retrouve : les gens des tours, les gens des Ruelles, les androïdes qui n'ont pas faim mais qui aiment l'ambiance.", {}),
					L("Cargo, le docker du quai, vient tous les soirs. Il ne mange pas, mais il commande un bol pour sentir l'odeur. Il dit que ça lui rappelle quelque chose. Il ne sait pas quoi.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Turbo, le gamin de l'Arcade, prétend qu'il a battu le record de Dragon-Pixel les yeux fermés. Je l'ai vu jouer. Il les ferme à moitié. C'est déjà pas mal.", {}, "rire"),
					L("Il paraît que la mairesse mange ici en cachette, avec une casquette et des lunettes. Tout le monde la reconnaît. Personne ne dit rien. C'est notre secret à tous.", {}, "rire"),
				],
				"interpelle": [L("Nouilles ! Nouilles chaudes !", {}, "salut")],
			}},
		# ================================================================ les Ruelles
		{"id": "kenji", "nom": "Kenji Volt", "titre": "réparateur des Ruelles (bras bionique)", "maison": "porte_kenji", "village": "neo",
			"agenda": [[8, 12, "atelier_kenji"], [12, 13, "marche_table_1"], [13, 20, "atelier_kenji"], [20, 23, ["marche_table_2", "place_banc_5"]], [23, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "queue", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.2, 0.22, 0.25], "carrure": 1.1},
			"teinte": PEAU[2],
			"neo": {"implant": true, "circuit": ORANGE, "metal": [0.28, 0.29, 0.32], "tenue": "mecano", "c": [0.22, 0.24, 0.28], "props": ["monocle"], "objet": "cle_molette"},
			"humeur_base": 0.4, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"engrenage": 2.0, "ressort": 2.0, "boulon": 1.5, "nouilles_neo": 1.5, "puce_holo": 2.5}, "deteste": {},
			"tics": ["Ça se répare.", "Passe-moi la clé de 12.", "Hm, intéressant.", "Rien ne se jette."],
			"repliques": {
				"accueil": [
					L("Kenji Volt, réparateur. Androïdes, drones, distributeurs, bras-robots, grille-pains intelligents… Si ça a une prise, je le répare. Si ça n'en a pas, je lui en mets une. (Il fait tourner les doigts de son bras de métal.) Et ça, c'est ma meilleure réparation.", {"visites_max": 1}, "salut"),
					L("{surnom}. Tu as cassé quelque chose ? Non ? Dommage, je m'ennuyais.", {"visites_min": 2}, "rire"),
					L("{surnom} ! Zéro parle de nouveau. Il m'a dit merci trois fois, et une fois en morse, au cas où. Grâce à toi.", {"q56": "ne_voix_zero=finie"}, "rire"),
				],
				"humeur": [
					L("Concentré. Il y a un drone de livraison qui croit qu'il est un pigeon. Il roucoule. Je cherche le bug.", {}),
					L("Mon bras me gratte. Enfin, l'endroit où il n'y a plus de bras. C'est bizarre, hein ? Les docteurs disent que c'est normal.", {}),
				],
				"lui": [
					L("Ce bras ? Un accident d'atelier, il y a dix ans. Une presse un peu trop pressée. J'ai construit celui-là moi-même, pièce par pièce. Il serre plus fort que l'autre. Il fait les poignées de main un peu trop fort aussi. Je m'entraîne.", {}),
					L("Ma fille Mio vient à l'atelier après l'école. Elle me passe les outils, elle me pose mille questions. Elle voudrait un androïde à elle. Je lui ai dit : on n'a pas un androïde, on a un ami androïde. Elle a choisi Zéro.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les Ruelles, c'est le vieux Néopolis : des immeubles serrés, des guirlandes, des enseignes, des ateliers. Les tours de verre sont belles, mais c'est ici qu'on répare tout ce qui tombe d'en haut.", {}),
					L("Monsieur Fil, le marchand au chapeau, deux rues plus loin… Je n'aime pas ses programmes. La semaine dernière, j'ai réparé trois robots ménagers qui en avaient installé un. Ils faisaient le ménage… chez les voisins.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le vieux Zéro a perdu sa voix. Sa puce vocale a lâché : c'est un modèle de la Série Z, on n'en fabrique plus depuis trente ans. Je n'en ai pas une seule à l'atelier.", {"q56": "ne_voix_zero="}),
					L("Glitch, la petite à la visière, peut entrer dans n'importe quel système. Heureusement qu'elle est gentille. Elle répare les feux du boulevard quand ils plantent. Gratuitement.", {}),
				],
				"interpelle": [L("Toi, là. Tu n'aurais pas un ressort, par hasard ?", {}, "salut")],
			}},
		{"id": "mio", "nom": "Mio", "titre": "fille de Kenji (9 ans)", "maison": "porte_kenji", "village": "neo",
			"agenda": [[8, 12, ["atelier_banc", "place_arrosage_2"]], [12, 13, "marche_table_5"], [13, 18, ["place_arrosage_3", "atelier_banc", "borne_2"]], [18, 20, "atelier_banc"], [20, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.98, 0.45, 0.7], "taille": 0.72},
			"teinte": PEAU[2],
			"neo": {"tenue": "enfant", "c": [0.98, 0.45, 0.7], "c2": CYAN},
			"femme": true,
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"soda_neon": 2.0, "glace": 2.0, "cerf_volant": 2.5, "gateau_lune": 1.5}, "deteste": {"champignon": -0.5},
			"tics": ["Pourquoi ?", "C'est trop beau !", "Papa dit que…", "Zéro, regarde !"],
			"surnoms": [[0, "toi"], [25, "l'aventurier"], [50, "mon copain"], [75, "mon meilleur copain"], [95, "le héros de Zéro"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Je m'appelle Mio ! Mon papa, c'est Kenji, il répare tout. Et mon meilleur ami, c'est Zéro, l'androïde qui balaie la place. Il est très vieux. Il a quarante ans ! C'est plus vieux que Papa !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens jouer ? Zéro m'apprend à balayer en rythme !", {"visites_min": 2}, "rire"),
					L("{surnom} ! Zéro m'a chanté une chanson ! Une vraie, avec des mots ! Merci, merci, merci !", {"q56": "ne_voix_zero=finie"}, "rire"),
				],
				"humeur": [
					L("Un peu triste… Zéro ne parle plus. Il fait juste « bip ». Avant, il me racontait des histoires de quand la ville était toute petite.", {"q56": "ne_voix_zero="}),
					L("Trop contente ! Zéro parle, Papa sourit, et j'ai eu un soda gratuit au distributeur. Bon, je l'ai secoué un peu. Le distributeur. Pas Zéro.", {"q56": "ne_voix_zero=finie"}, "rire"),
					L("J'attends que Papa revienne avec la puce. Tu crois que Zéro aura la même voix qu'avant ?", {"q56": "ne_voix_zero=en_cours"}),
				],
				"lui": [
					L("Plus tard, je serai réparatrice, comme Papa. Mais je réparerai surtout les androïdes. Les autres machines, elles ne disent pas merci.", {}),
					L("Je n'ai pas le droit d'avoir un implant avant mes dix-huit ans. De toute façon, je veux garder mes deux bras. Comme ça, je peux faire des câlins à Papa des deux côtés : un bras chaud, un bras froid.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Tu as vu les carpes de lumière, sur la place ? Si tu touches l'émetteur, elles changent de couleur ! Je l'ai fait cent fois. Cent et deux.", {}, "rire"),
					L("La Tour Axiome, c'est la plus haute. Sept, le monsieur androïde de l'accueil, m'a laissée appuyer sur le bouton de l'ascenseur. C'était le plus beau jour de ma vie. Avant celui où j'ai eu un soda gratuit.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Turbo dit qu'il est le meilleur à Dragon-Pixel. Moi, je l'ai battu une fois. Il dit que ça compte pas parce qu'il éternuait.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu veux voir Zéro ? Il est sur la place !", {}, "salut")],
			}},
		{"id": "fil", "nom": "Monsieur Fil", "titre": "marchand de programmes « pas chers » des Ruelles", "maison": "porte_fil", "village": "neo",
			"agenda": [[14, 2, "bazar_fil"], [2, 14, "maison"]],
			"azur": {"cheveux": [0.2, 0.08, 0.22], "coiffure": "plaque", "barbe": "moustache", "yeux": Y_GRIS, "haut": [0.55, 0.12, 0.45], "lunettes": true},
			"teinte": PEAU[0],
			"neo": {"tenue": "marchand", "c": [0.55, 0.12, 0.45], "chapeau": "haut_de_forme", "chapeau_c": [0.22, 0.06, 0.25], "objet": "tablette_holo"},
			"humeur_base": 0.5, "traits": {"bavard": 1.0, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.5},
			"aime": {"piece_or": 2.5, "rubis": 2.5, "perle": 2.0}, "deteste": {"boulon": -0.5},
			"tics": ["Pas cher, pas cher !", "Une affaire !", "Faites-moi confiance.", "Dernier exemplaire !"],
			"surnoms": [[0, "cher client"], [25, "client fidèle"], [50, "mon client préféré"], [75, "mon ami"], [95, "mon associé"]],
			"repliques": {
				"accueil": [
					L("Approchez, approchez ! Monsieur Fil, marchand de programmes ! Des applications pour tout : pour rendre votre frigo plus drôle, votre réveil plus doux, votre robot aspirateur plus… aspirant. Et tout ça, pas cher ! Presque gratuit !", {"visites_max": 1}, "salut"),
					L("Ah, mon {surnom} ! J'ai reçu des nouveautés. Toutes garanties. Garanties quoi ? Garanties… nouvelles.", {"visites_min": 2, "q56": "ne_virus_fil="}, "rire"),
					L("Ah… mon {surnom}. Le chasseur de virus. (Il cache vite une tablette derrière son dos.) Rien à vendre aujourd'hui ! Rien de rien. Que des programmes vérifiés. Enfin, à vérifier.", {"visites_min": 2, "q56": "ne_virus_fil=finie"}, "rire"),
				],
				"humeur": [
					L("Excellente ! Les affaires marchent. Enfin, elles marchent… elles avancent. Lentement. Les gens sont méfiants, à Néopolis. Je me demande pourquoi.", {}),
					L("La nuit, c'est la meilleure heure pour vendre : les gens sont fatigués, ils lisent moins les petites lignes. Euh… je veux dire : ils sont plus détendus.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis arrivé à Néopolis il y a trois mois avec une valise pleine de programmes et un grand sourire. La valise est toujours pleine. Le sourire aussi.", {}, "rire"),
					L("Mes programmes, je les fabrique moi-même. Enfin, je les trouve. Enfin, quelqu'un les fabrique, et moi je les vends. C'est un métier, la vente.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Néopolis est une ville formidable : il y a un ordinateur dans chaque objet ! Et donc un client dans chaque objet. Hé hé.", {}),
					L("La petite Glitch, avec sa visière, passe tous les jours devant mon étal en me regardant de travers. Elle croit que mes programmes sont… pas nets. Quelle idée.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("J'ai enfin reçu mon programme exceptionnel ! Le Turbo-Aventure 3000. Le meilleur de tous. Il rendra ton aventure plus facile, plus rapide, plus… tout. Demande-moi : pour toi, je ferai un prix.", {"q56": "ne_virus_fil="}, "rire"),
					L("Glitch vérifie mes programmes, maintenant. Elle en a ouvert un hier : il y avait trois virus et une recette de crêpes. Elle a gardé la recette. Moi, je garde… la honte.", {"q56": "ne_virus_fil=finie"}),
				],
				"interpelle": [L("Psst ! Toi ! Un programme pas cher ?", {}, "salut"), L("Mon {surnom} ! Des nouveautés !", {"visites_min": 1})],
			}},
		# ================================================================ la Place des Hologrammes
		{"id": "zero", "nom": "Zéro", "titre": "androïde balayeur, le plus vieux de Néopolis", "maison": "porte_zero", "village": "neo",
			"agenda": [[6, 12, ["place_arrosage_1", "place_arrosage_2", "place_arrosage_3", "place_arrosage_4"]], [12, 14, "atelier_kenji_client"], [14, 20, ["place_arrosage_4", "place_arrosage_1", "place_1"]], [20, 23, "quai_bord_2"], [23, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chauve", "yeux": Y_AMBRE, "haut": [0.9, 0.45, 0.12], "taille": 0.97},
			"teinte": PEAU[1],
			"neo": {"android": true, "vieux_modele": true, "peau": [0.6, 0.62, 0.64], "circuit": AMBRE, "lueur_yeux": 0.9, "tenue": "combinaison", "c": [0.92, 0.45, 0.12], "props": ["antenne", "led_tempe"], "objet": "arrosoir"},
			"humeur_base": 0.6, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"boulon": 2.0, "ressort": 1.5, "fleur_lune": 2.0, "graines": 2.0, "partition": 2.5}, "deteste": {},
			"tics": ["Bip.", "Mise à jour… jamais.", "Je balaie, donc je suis.", "Hi hi."],
			"repliques": {
				"accueil": Z("Bip ! Bip-bip. (Le vieil androïde pose son arrosoir et te fait un grand salut, très lent, très poli. Ses yeux couleur d'ambre clignotent deux fois. Il ouvre la bouche… et seul un petit « bip » en sort.)", "salut") + Z("Bip-bip ! (Il te reconnaît. Il fait tourner son balai comme une canne, et manque de tomber.)", "rire", {"visites_min": 2}) + [
					L("Bonjour, {surnom} ! Bonjour, bonjour, bonjour ! Pardon. Ça fait des années que je n'ai pas dit bonjour. J'en ai plein en réserve.", {"q56": "ne_voix_zero=finie"}, "salut"),
				],
				"humeur": Z("Bip… (Il montre les cerisiers en fleurs, puis son cœur. Puis il hausse les épaules, l'air de dire : je ne peux pas t'en dire plus.)") + [
					L("Je fonctionne à cent pour cent ! Enfin, à quatre-vingt-sept. Mais quatre-vingt-sept, à mon âge, c'est cent.", {"q56": "ne_voix_zero=finie"}, "rire"),
					L("Le soir, je vais au quai regarder la mer. Les mouettes ne m'ont jamais demandé de mise à jour. Je les aime bien.", {"q56": "ne_voix_zero=finie", "soir": true}),
				],
				"lui": Z("Bip. Bip-biiip. Bip. (Il dessine dans l'air un petit carré, puis un plus grand, puis des tours. Tu comprends : il a vu la ville grandir.)") + [
					L("Je suis un modèle de la Série Z. Le premier androïde de Néopolis. Quand je suis arrivé, il n'y avait qu'un ponton et Mamie Kiku qui servait le thé. J'ai balayé le premier mètre carré de la ville. Puis le deuxième. Ça fait quarante ans que je continue.", {"q56": "ne_voix_zero=finie"}),
					L("On m'a proposé cent fois de me remplacer par un robot plus récent. La mairesse a toujours dit non. Elle dit que la place ne serait pas la même sans moi. Je crois qu'elle a raison : je suis le seul à arroser les cerisiers en chantant.", {"q56": "ne_voix_zero=finie", "sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": Z("Bip ! (Il montre les carpes holographiques qui nagent au-dessus de la place, et fait semblant de nager avec elles.)", "rire") + [
					L("Les carpes de lumière ? C'est moi qui leur ai donné leurs noms : Ambre, Azur et Rubis. Elles ne savent pas qu'elles ont un nom. Moi, je le sais. Ça suffit.", {"q56": "ne_voix_zero=finie"}),
				],
				"rumeur": Z("Bip-bip… (Il regarde vers les Ruelles, fronce ses sourcils peints, et secoue la tête : non, non, non.)") + [
					L("Mio dit qu'elle veut devenir réparatrice. Elle me répare déjà : chaque fois qu'elle rit, mes circuits refroidissent. C'est très efficace.", {"q56": "ne_voix_zero=finie"}, "rire"),
				],
				"interpelle": Z("Bip !", "salut") + [L("Bonjour ! Bonjour ! J'ai encore plein de bonjours !", {"q56": "ne_voix_zero=finie"}, "salut")],
				"au_revoir": Z("Bip-bip. (Il agite son arrosoir.)", "salut") + [L("Au revoir, {surnom} ! Reviens vite : j'apprends une nouvelle chanson.", {"q56": "ne_voix_zero=finie"}, "salut")],
				"cadeau_neutre": Z("Bip. (Il range ton cadeau dans une petite trappe, sur sa poitrine, avec beaucoup de soin.)") + [L("Merci ! Je vais le ranger dans ma trappe à trésors. Elle est presque pleine. Presque.", {"q56": "ne_voix_zero=finie"})],
				"cadeau_aime": Z("Biiiiip ! (Ses yeux s'allument très fort. Il te serre la main pendant longtemps. Très longtemps.)", "rire") + [L("{dernier_cadeau} ! Oh ! Mes circuits font des étincelles de joie. Ce n'est pas dangereux. Enfin, je crois.", {"q56": "ne_voix_zero=finie"}, "rire")],
				"cadeau_deteste": Z("Bip ? (Il regarde l'objet, puis toi, puis l'objet. Il le pose poliment sur un banc.)") + [L("Hum. Merci. Je vais le… balayer. Non ! Le garder. Je voulais dire le garder.", {"q56": "ne_voix_zero=finie"})],
				"frappe": Z("BIP ! (Il recule, vexé, et se cache derrière son balai.)", "colere") + [L("Aïe ! Je suis vieux, tu sais. On ne tape pas les vieux androïdes. Ni les jeunes, d'ailleurs.", {"q56": "ne_voix_zero=finie"}, "colere")],
				"blague": Z("Bip-bip-bip-bip ! (Il rit. Enfin, ça ressemble à un rire. Tu ne sais pas de quoi, mais c'est communicatif.)", "rire") + [L("Qu'est-ce qu'un balai dit à un autre balai ? Rien : ils sont trop occupés. … Je l'ai inventée il y a trente ans. Personne ne rit. Moi, si.", {"q56": "ne_voix_zero=finie"}, "rire")],
				"souvenir": Z("Bip. (Il tapote sa tempe : il se souvient de tout. De toi aussi.)") + [L("Je me souviens de tout. Du premier lampadaire, de la première tour, et de toi. Surtout de toi.", {"q56": "ne_voix_zero=finie"})],
				"quete_inconnue": Z("Bip ? (Il montre Mio du doigt, là-bas, et fait un petit geste : c'est elle qu'il faut aller voir.)") + [L("Une quête ? Moi ? Non… Mais Mio a toujours des projets. Demande-lui.", {"q56": "ne_voix_zero=finie"})],
			}},
		# ================================================================ la Tour Axiome
		{"id": "sept", "nom": "Sept", "titre": "androïde d'accueil de la Tour Axiome (modèle U-7)", "maison": "porte_sept", "village": "neo",
			"agenda": [[0, 24, "accueil"]],
			"azur": {"cheveux": ARGENT, "coiffure": "court", "yeux": Y_CYAN, "haut": [0.08, 0.1, 0.14]},
			"teinte": PEAU[0],
			"neo": {"android": true, "peau": [0.94, 0.93, 0.92], "circuit": CYAN, "lueur_yeux": 0.8, "tenue": "service", "c": [0.08, 0.1, 0.14], "c2": CYAN, "props": ["led_tempe", "collier"]},
			"humeur_base": 0.6, "traits": {"bavard": 0.7, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"puce_holo": 2.5, "carte_postale": 2.0, "appareil_photo": 1.5}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Bienvenue à la Tour Axiome.", "Étage demandé ?", "Je note.", "Excellente journée."],
			"repliques": {
				"accueil": [
					L("Bienvenue à la Tour Axiome. Je suis Sept, androïde d'accueil, modèle U-7. Hauteur de la tour : deux cent soixante-cinq mètres. Vitesse de l'ascenseur : six mètres par seconde. Nombre de sourires que je fais par jour : environ huit cents. Celui-ci est pour vous.", {"visites_max": 1}, "salut"),
					L("Bon retour parmi nous, {surnom}. Visite numéro {visites}. Je compte tout. C'est plus fort que moi.", {"visites_min": 2}),
				],
				"humeur": [
					L("Fonctionnement optimal. Je ne dors jamais. Je me mets en veille de trois heures à trois heures cinq. Pendant ces cinq minutes, je rêve. Je rêve que je dors.", {}),
					L("Légèrement perplexe. Une dame m'a demandé hier où se trouvait le quarante-septième étage. Il n'y en a que quarante-six. Elle est montée quand même. Je ne l'ai pas revue.", {}, "rire"),
				],
				"lui": [
					L("J'ai été fabriqué pour dire bonjour. J'en ai dit un million deux cent mille quatre cent douze. Treize, avec vous.", {}),
					L("Mamie Kiku dit que je lui dis bonjour quarante-deux fois par jour. C'est faux : c'est quarante-trois. Elle oublie celui du matin, elle est encore endormie.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La mairesse m'a demandé de prendre des vacances. J'ai cherché « vacances » dans ma mémoire. Définition : rester sans rien faire. J'ai essayé une minute. J'ai trouvé ça très difficile.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'ascenseur, juste là, monte à la Terrasse du Ciel : cent cinquante mètres au-dessus des rues. D'en haut, on voit toute la ville, la mer, et l'archipel. Je n'y suis jamais monté. Je garde l'accueil.", {}),
					L("Néopolis compte environ quatre mille habitants et neuf cents androïdes. Et un voyageur. Vous.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Je ne répète pas les rumeurs. Mais j'ai entendu que les programmes de Monsieur Fil faisaient faire des choses étranges aux machines. Je ne les installerai pas. Mes mises à jour, je les fais à la mairie. Avec un tampon.", {}),
				],
				"interpelle": [L("Bienvenue à la Tour Axiome !", {}, "salut")],
			}},
		{"id": "yuna", "nom": "Madame Yuna Takeda", "titre": "mairesse de Néopolis", "maison": "porte_yuna", "village": "neo",
			"agenda": [[8, 12, ["parvis_1", "parvis_2"]], [12, 14, "marche_table_6"], [14, 18, ["place_1", "station_0"]], [18, 21, ["parvis_1", "jardin_mediter_2"]], [21, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": Y_NOIR, "haut": [0.1, 0.12, 0.2]},
			"teinte": PEAU[1],
			"neo": {"tenue": "tailleur", "c": [0.1, 0.12, 0.2], "c2": [0.2, 0.8, 1.0]},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"nouilles_neo": 2.5, "the_menthe": 2.0, "carte_postale": 1.5, "fleur_lune": 1.5}, "deteste": {},
			"tics": ["Pour Néopolis !", "J'en prends note.", "Hm, voyons le dossier.", "Ma porte est ouverte."],
			"repliques": {
				"accueil": [
					L("Bienvenue à Néopolis ! Yuna Takeda, mairesse. Ma ville est la plus moderne de l'archipel : des tours, des trains suspendus, des voitures qui volent… et des gens qui prennent encore le temps de boire le thé de Mamie Kiku. J'y tiens beaucoup.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Toujours en visite ? Si vous restez, je vous trouve un appartement au quatre-vingtième étage. Vue sur la mer. Ascenseur rapide.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Occupée ! Une réunion sur les voitures volantes, une autre sur les mouettes qui volent les nouilles, et une troisième sur les réunions. Je les aime bien, les réunions sur les réunions.", {}, "rire"),
					L("Fière. Ma ville brille la nuit. Mais ce que je préfère, c'est quand elle rit.", {"soir": true}),
				],
				"lui": [
					L("Je suis née ici, dans les Ruelles, au-dessus d'un atelier de réparation. Mon père réparait des radios. Aujourd'hui, je répare une ville. Ce n'est pas si différent : il faut écouter ce qui grésille.", {}),
					L("On m'a proposé un implant pour travailler plus vite. J'ai refusé. Une mairesse doit rester à la vitesse de ses habitants. Surtout de Mamie Kiku.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("À Néopolis, les humains et les androïdes vivent ensemble, avec les mêmes droits et le même bus. Enfin, le même monorail. Le règlement tient sur une seule page : « Soyez gentils. Même avec les machines. »", {}),
					L("Zéro, le vieux balayeur, a été le premier habitant de la ville, avant moi. Personne ne le remplacera. C'est la seule loi que j'ai signée deux fois.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Un marchand vend des programmes douteux dans les Ruelles. Je n'ai pas de preuve. Glitch dit qu'elle en trouvera. Je lui ai demandé d'être prudente. Elle m'a répondu « toujours ». Elle dit toujours « toujours ».", {}),
				],
				"interpelle": [L("Bonjour ! Bienvenue à Néopolis !", {}, "salut")],
			}},
		# ================================================================ le Boulevard et les Arcades
		{"id": "kira", "nom": "Kira", "titre": "danseuse holographique du Boulevard des Néons (circuits lumineux)", "maison": "porte_kira", "village": "neo",
			"agenda": [[11, 15, ["quai_banc_4", "place_banc_1"]], [15, 19, "danse_kira"], [19, 20, "marche_table_7"], [20, 1, "danse_kira"], [1, 11, "maison"]],
			"azur": {"cheveux": ROSE_NEON, "coiffure": "carre", "yeux": Y_BRUN, "haut": [0.1, 0.1, 0.14]},
			"teinte": PEAU[3],
			"neo": {"implant": true, "circuit": MAGENTA, "metal": [0.42, 0.4, 0.48], "tenue": "holo", "c": [0.35, 0.25, 0.6], "c2": [1.0, 0.4, 0.85], "props": ["oreillettes"]},
			"femme": true,
			"humeur_base": 0.65, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"soda_neon": 2.0, "partition": 2.5, "glace": 1.5, "fleur_lune": 1.5}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Et un, et deux…", "Suis le rythme !", "Ça brille !", "On danse ?"],
			"repliques": {
				"accueil": [
					L("Salut ! Moi, c'est Kira. Je danse sur le Boulevard, tous les soirs. Regarde mon bras : quand la musique monte, mes circuits s'allument. Quand elle est vraiment bonne, ils changent de couleur. Les gens viennent pour voir ça. Moi, je viens pour danser.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu restes pour le spectacle ? Ce soir, je tente le triple tour lumineux.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("En rythme ! Cent vingt battements par minute, comme mon cœur. Enfin, comme mon cœur quand je danse.", {}, "rire"),
					L("La nuit, le Boulevard est à moi. Les néons, les voitures qui passent au-dessus, la pluie qui brille… C'est la plus belle scène du monde.", {"soir": true}),
				],
				"lui": [
					L("Mes circuits ? Un implant de danseuse. Il transforme la musique en lumière, sous ma peau. Kenji l'a réglé pour qu'il ne chauffe pas. Avant, quand je dansais trop longtemps, je faisais griller les toasts en passant devant.", {}, "rire"),
					L("Turbo, le gamin de l'Arcade, vient me voir danser après ses parties. Il fait semblant de ne pas aimer. Il tape du pied. Je le vois.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Boulevard des Néons traverse toute la ville, du quai jusqu'au sud. La nuit, tout le monde y passe. C'est le meilleur public de l'archipel.", {}),
				],
				"rumeur": [
					L("Il paraît que Sept, à la Tour Axiome, danse quand il est seul. Une caméra l'aurait vu faire une petite pirouette à trois heures du matin. Je veux voir cette vidéo.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Viens danser !", {}, "salut")],
			}},
		{"id": "turbo", "nom": "Turbo", "titre": "champion de Dragon-Pixel (12 ans)", "maison": "porte_turbo", "village": "neo",
			"agenda": [[9, 12, "borne_1"], [12, 13, "marche_table_8"], [13, 19, ["borne_1", "borne_2"]], [19, 21, "danse_public_1"], [21, 9, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "court", "yeux": Y_BRUN, "haut": [0.15, 0.55, 0.95], "taille": 0.8},
			"teinte": PEAU[2],
			"neo": {"tenue": "enfant", "c": [0.15, 0.55, 0.95], "c2": [1.0, 0.85, 0.2], "chapeau": "casquette", "chapeau_c": [0.95, 0.2, 0.25], "props": ["casque_audio"]},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.8, "rancunier": 0.3},
			"aime": {"soda_neon": 2.5, "glace": 2.0, "nouilles_neo": 1.5, "coupe_course": 2.0}, "deteste": {"the_menthe": -0.5},
			"tics": ["Trop facile.", "Combo !", "Game over… pour toi.", "Encore une !"],
			"surnoms": [[0, "le débutant"], [25, "le joueur"], [50, "mon rival"], [75, "mon équipier"], [95, "le maître du Dragon"]],
			"repliques": {
				"accueil": [
					L("Salut. Turbo. Champion de Dragon-Pixel. Le record, là-haut, sur l'écran ? C'est moi. Le deuxième record ? Moi aussi. Le troisième… c'est Mio, mais elle a eu de la chance.", {"visites_max": 1}, "salut"),
					L("Oh, {surnom}. Tu viens perdre ? Euh, je veux dire : jouer ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Concentré. Ne me parle pas pendant le niveau sept, c'est celui avec les dragons qui font des boucles.", {}),
					L("Énervé. Quelqu'un a mis du soda sur le bouton B. Il colle. Comment je fais des combos, moi, avec un bouton qui colle ?", {}, "colere"),
				],
				"lui": [
					L("J'ai commencé à jouer à quatre ans. Ma mère dit que mon premier mot, c'était « encore ». Mon deuxième, c'était « une pièce ».", {}, "rire"),
					L("Je veux devenir créateur de jeux. Mon jeu à moi, il y aura des dragons, des voitures volantes et un vieux robot qui balaie. Zéro sera le héros. Il ne sait pas encore.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("L'Arcade du Dragon-Pixel, c'est le meilleur endroit de la ville. Il y a la clim, des bips partout, et personne ne te demande de ranger ta chambre.", {}),
				],
				"rumeur": [
					L("Glitch dit qu'elle pourrait pirater la borne et mettre son nom à la place du mien. Elle ne le fait pas. Elle dit qu'un record, ça se gagne. … Elle est cool, Glitch. Ne lui dis pas que j'ai dit ça.", {}),
				],
				"interpelle": [L("Hé ! T'as vu mon score ?", {}, "salut")],
			}},
		{"id": "glitch", "nom": "Glitch", "titre": "hackeuse au grand cœur (visière, implant)", "maison": "porte_glitch", "village": "neo",
			"agenda": [[10, 13, ["station_2", "station_1"]], [13, 17, "arcade_public"], [17, 22, ["station_2", "ruelle_1"]], [22, 10, "maison"]],
			"azur": {"cheveux": VERT_NEON, "coiffure": "court", "yeux": Y_GRIS, "haut": [0.12, 0.12, 0.14], "taille": 0.93},
			"teinte": PEAU[0],
			"neo": {"implant": true, "circuit": VERT, "metal": [0.25, 0.27, 0.27], "tenue": "sweat", "c": [0.12, 0.12, 0.14], "c2": VERT, "props": ["visiere"], "objet": "tablette_holo"},
			"femme": true,
			"humeur_base": 0.45, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"puce_holo": 2.5, "soda_neon": 2.0, "antenne_radio": 2.0, "nouilles_neo": 1.0}, "deteste": {},
			"tics": ["Accès autorisé.", "Hé hé.", "Ça, c'est du code propre.", "Bug trouvé."],
			"repliques": {
				"accueil": [
					L("Salut. Glitch. Oui, comme un bug. Ma visière me montre les réseaux de la ville : les lignes de données, les feux, les distributeurs, les ascenseurs. Tout parle, ici. Moi, j'écoute. Et quand quelque chose tousse, je le soigne.", {"visites_max": 1}, "salut"),
					L("{surnom}. Mes capteurs t'ont repéré il y a trois rues. Tu marches toujours un peu à gauche, tu le savais ?", {"visites_min": 2}, "rire"),
					L("Salut, chasseur de virus. Ton carnet va bien ? Pas de fenêtres surprises ? Pas de poney en chocolat ? Parfait. Hé hé.", {"visites_min": 2, "q56": "ne_virus_fil=finie"}, "rire"),
				],
				"humeur": [
					L("Vigilante. Il se passe des trucs bizarres dans les Ruelles. Des machines qui font n'importe quoi, d'un coup.", {}),
					L("Bien. J'ai réparé les feux du boulevard ce matin. Ils clignotaient en morse. Ils disaient « ennui ». Je leur ai mis de la musique.", {}, "rire"),
				],
				"lui": [
					L("Je suis une hackeuse. Mais une gentille. On dit « chapeau blanc ». Moi, j'ai une visière verte, mais l'idée est là.", {}, "rire"),
					L("Mon implant, sur la tempe, me laisse « voir » les réseaux. La première fois, j'ai cru que la ville entière me parlait en même temps. J'ai mis des semaines à apprendre à baisser le volume.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le monorail fait une boucle autour de la ville, avec quatre stations. Les bornes des kiosques t'emmènent d'une station à l'autre. Elles sont honnêtes, elles. Je les ai vérifiées.", {}),
					L("Les androïdes de Néopolis ont tous un petit cœur de code. Celui de Zéro est le plus vieux. Il est écrit à la main, presque. C'est beau à voir.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Monsieur Fil, le marchand au chapeau… Ses programmes cachent des choses. Je ne sais pas encore quoi. Fais-moi plaisir : s'il te propose quelque chose de « pas cher », réfléchis deux fois. Trois, même.", {}),
					L("Si un jour ton écran devient tout bleu, avec des messages qui font peur, ne panique pas. Respire. Et viens me voir. C'est souvent moins grave que ça en a l'air.", {"sujet_min": ["rumeur", 1]}),
				],
				"interpelle": [L("Psst. Ton sac fait bip. Non, je blague.", {}, "rire")],
			}},
		# ================================================================ le Jardin Zen
		{"id": "ishi", "nom": "Maître Ishi", "titre": "jardinier du Jardin Zen", "maison": "porte_ishi", "village": "neo",
			"agenda": [[6, 11, "jardin_rateau"], [11, 13, "fontaine"], [13, 17, "jardin_rateau"], [17, 19, "marche_table_4"], [19, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_NOIR, "haut": [0.6, 0.55, 0.45], "vieux": true},
			"teinte": PEAU[1],
			"neo": {"tenue": "jardinier", "c": [0.55, 0.5, 0.4], "chapeau": "paille"},
			"humeur_base": 0.6, "traits": {"bavard": 0.3, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"graines": 2.5, "fleur_lune": 2.0, "the_menthe": 2.0, "caillou_chantant": 2.5}, "deteste": {"soda_neon": -0.5},
			"tics": ["Hm.", "Respire.", "Le gravier sait.", "Doucement."],
			"surnoms": [[0, "jeune pousse"], [25, "jeune arbre"], [50, "ami du jardin"], [75, "élève"], [95, "cerisier"]],
			"repliques": {
				"accueil": [
					L("… Bienvenue au jardin. (Il ratisse une longue ligne droite, puis une vague.) Ici, on parle peu. Les cerisiers parlent pour nous. Et la fontaine de bambou compte le temps.", {"visites_max": 1}, "salut"),
					L("{surnom}. Tu reviens. Le gravier se souvient de tes pas.", {"visites_min": 2}),
				],
				"humeur": [
					L("Comme l'étang : calme dessus, vivant dessous.", {}),
					L("Ce matin, un drone est tombé dans le gravier. J'ai ratissé autour. Il fait partie du jardin, maintenant. Aïko l'a peint.", {}, "rire"),
				],
				"lui": [
					L("Je ratisse ce gravier depuis trente ans. Chaque matin, je dessine des vagues. Chaque soir, le vent les efface. Chaque matin, je recommence. C'est ça, être jardinier.", {}),
					L("Aïko est venue un jour me demander ce qu'était « la beauté ». Je lui ai tendu un pinceau. Elle peint depuis trois ans. Elle ne sait toujours pas. Moi non plus. C'est pour ça qu'on continue.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le jardin est au milieu de la ville, mais on n'entend presque pas les voitures. Les murets, les cerisiers… et un peu de patience dans les oreilles.", {}),
				],
				"rumeur": [
					L("Mamie Kiku vient le matin. On ne se dit rien. Elle boit son thé, je ratisse. Une fois, elle a dit « joli ». C'était il y a six ans. Je m'en souviens encore.", {}),
				],
				"interpelle": [L("Doucement… les vagues dorment.", {})],
			}},
		{"id": "aiko", "nom": "Aïko", "titre": "androïde peintre du Jardin Zen", "maison": "porte_aiko", "village": "neo",
			"agenda": [[7, 12, "jardin_peinture"], [12, 14, "jardin_mediter_2"], [14, 18, "jardin_peinture"], [18, 22, ["place_banc_7", "quai_banc_5"]], [22, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": Y_ROSE, "haut": [0.95, 0.75, 0.85], "taille": 0.96},
			"teinte": PEAU[0],
			"neo": {"android": true, "peau": [0.97, 0.88, 0.84], "circuit": [1.0, 0.45, 0.75], "lueur_yeux": 0.55, "tenue": "artiste", "c": [0.95, 0.75, 0.85], "c2": [0.9, 0.3, 0.5], "chapeau": "beret", "props": ["led_tempe"]},
			"femme": true,
			"accessoire": "pinceau",
			"humeur_base": 0.55, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.0},
			"aime": {"fleur_lune": 2.5, "carte_postale": 2.0, "partition": 1.5, "plume_lune": 2.0}, "deteste": {"boulon": -0.3},
			"tics": ["C'est beau ?", "Je ne sais pas encore.", "Encore un peu de rose.", "Regarde la lumière."],
			"repliques": {
				"accueil": [
					L("Bonjour. Je suis Aïko. J'ai été fabriquée pour trier des colis. Un jour, un colis s'est ouvert : il y avait une peinture de cerisier dedans. Je l'ai regardée pendant onze heures. Après, j'ai démissionné. Maintenant, je peins.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens voir. J'ai peint la lumière de ce matin. Elle ne reviendra jamais exactement pareille. C'est triste. C'est beau. Je crois que c'est les deux.", {"visites_min": 2}),
				],
				"humeur": [
					L("Mon module d'émotions est à soixante-dix pour cent. Je me le suis installé moi-même. Kenji a dit que c'était risqué. C'était la meilleure décision de ma vie.", {}),
					L("Le soir, je regarde la mer depuis le quai. Les néons se reflètent dans l'eau. On dirait que la ville se peint elle-même.", {"soir": true}),
				],
				"lui": [
					L("Les androïdes ne sont pas censés aimer les choses. Moi, j'aime le rose des cerisiers, le bruit de la fontaine et la voix de Maître Ishi quand il dit « hm ». Je ne sais pas si c'est une erreur. Si c'en est une, je la garde.", {}),
					L("J'ai ajouté une petite modification dans mon cœur de code : un « module de rêve ». La nuit, au lieu de me mettre en veille, je repasse mes images préférées. Cette nuit, j'ai rêvé d'un cerisier bleu. Je vais le peindre.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Jardin Zen est le seul endroit de Néopolis où la lumière vient du ciel, et pas des néons. Je viens ici pour apprendre les vraies couleurs.", {}),
				],
				"rumeur": [
					L("Zéro m'a appris à arroser les fleurs en chantant. Je ne sais pas chanter. Lui non plus, maintenant qu'il n'a plus de voix. Alors on arrose en silence, et on fait semblant.", {"q56": "ne_voix_zero="}),
					L("Zéro chante de nouveau ! Faux. Très faux. C'est merveilleux.", {"q56": "ne_voix_zero=finie"}, "rire"),
				],
				"interpelle": [L("Tu veux voir ma peinture ?", {}, "salut")],
			}},
		# ================================================================ le Quai des Drones
		{"id": "cargo", "nom": "Cargo", "titre": "androïde docker du Quai des Drones", "maison": "porte_cargo", "village": "neo",
			"agenda": [[6, 13, ["quai_cargo_1", "quai_cargo_2"]], [13, 14, "quai_bord"], [14, 21, ["quai_cargo_1", "quai_cargo_2"]], [21, 6, "quai_bord"]],
			"azur": {"cheveux": NOIR, "coiffure": "chauve", "yeux": Y_AMBRE, "haut": [0.95, 0.85, 0.1], "carrure": 1.4, "taille": 1.08},
			"teinte": PEAU[3],
			"neo": {"android": true, "peau": [0.36, 0.38, 0.41], "circuit": [1.0, 0.75, 0.15], "lueur_yeux": 0.8, "tenue": "docker", "c": [0.98, 0.82, 0.1], "chapeau": "casquette", "chapeau_c": [0.95, 0.5, 0.1], "props": ["led_tempe"]},
			"humeur_base": 0.6, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"sardine": 2.0, "plume_corbeau": 1.5, "coquillage": 2.0, "etoile_mer": 2.5}, "deteste": {},
			"tics": ["Charge : légère.", "Doucement.", "Les mouettes savent.", "Je porte."],
			"surnoms": [[0, "petit humain"], [25, "petit ami humain"], [50, "collègue"], [75, "ami du quai"], [95, "capitaine"]],
			"repliques": {
				"accueil": [
					L("Bonjour, petit humain. Je suis Cargo. Je porte les conteneurs. Un conteneur pèse vingt tonnes. Une mouette pèse un kilo. Je fais très attention aux deux.", {"visites_max": 1}, "salut"),
					L("{surnom}. Bonjour. Les mouettes ont demandé de tes nouvelles. Enfin, elles ont crié. J'ai traduit.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Charge morale : légère. Le soleil sur les conteneurs, le bruit de la mer. Tout va bien.", {}),
					L("La nuit, je regarde les bateaux et les étoiles. Je ne dors pas. Je n'ai pas besoin. Mais j'aime bien faire semblant de rêver.", {"soir": true}),
				],
				"lui": [
					L("J'ai été construit pour soulever des choses lourdes. Puis une mouette s'est posée sur ma tête. Elle y est restée trois jours. J'ai appris à marcher très doucement. Depuis, je fais tout très doucement.", {}),
					L("Zéro est mon plus vieil ami. Quand je suis arrivé en caisse, c'est lui qui a ouvert le couvercle. Il m'a dit « bienvenue ». C'était le premier mot que j'entendais. Maintenant, il ne parle plus. Je lui parle pour deux.", {"q56": "ne_voix_zero=", "sujet_min": ["lui", 1]}),
					L("Zéro a sa voix ! Il m'a redit « bienvenue », pour rire. Comme le premier jour. Mes circuits ont fait un bruit bizarre. Kenji dit que ça s'appelle « être ému ».", {"q56": "ne_voix_zero=finie", "sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Quai des Drones : les bateaux apportent les conteneurs, les drones portent les petits paquets, et moi je porte les gros. Et parfois les drones fatigués.", {}),
				],
				"rumeur": [
					L("Dans les vieux conteneurs du bout du quai, il y a des pièces de tous les âges. Des choses qu'on ne fabrique plus. Je les garde. Au cas où quelqu'un en aurait besoin un jour.", {}),
				],
				"interpelle": [L("Attention. Charge lourde. Je passe doucement.", {})],
			}},
	]

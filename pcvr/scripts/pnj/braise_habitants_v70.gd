extends RefCounted
## V70 : les gens de Pandémonia, la méga-cité des démons de l'Île de Braise. Des cornes, des
## queues, parfois des ailes, des yeux qui luisent… et des cœurs plus chauds que la lave.
##  - le Palais : Ignatia l'Archiduchesse, Asmodin son majordome, Pyrus le capitaine de la Garde ;
##  - la Cathédrale-Forge : Frère Cendrin, gardien du Cœur-Brasier, et Ferronde, maîtresse de la
##    Grande Forge ;
##  - l'Académie Infernale : le Professeur Malachar, Mademoiselle Sulfura, et deux diablotins,
##    Pépin (le fils de Zébuline) et Ortie (la fille de Ferronde et de Pyrus) ;
##  - l'Arène des Cornes : Madame Hurla, la crieuse, et Gorgoth le Cornu, son champion ;
##  - la Grand-Place des Lanternes : Lumina la lanternière, son grand-père Ébène le conteur,
##    Calcine la violoniste, et Nox, l'allumeur de réverbères qui vit la nuit ;
##  - la Bibliothèque des Âmes : Ombreline ;
##  - le Grand Marché : Zébuline (épices), Kraxx (armes), Vespérine (potions), Bobor (le pain du
##    Four Éternel) ;
##  - le Port de Cendre : le Capitaine Charbonnel, Moloka la poissonnière, Grumbald le tavernier du
##    Diable Repu (le mari de Moloka), Brindille la factrice ailée ;
##  - les Thermes et les Jardins de Cendre : Mère Brasille et ses jumeaux, Bulle et Vespérine ;
##  - les Artisans : Tiburce le polisseur de cornes, Zigomar l'inventeur-artificier, Grisette la
##    couturière, Flammèche et ses chiots d'enfer (la sœur de Pyrus).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd). Fiche « village » : pandemonia (les lieux : voir la note V70).
## Fiche « demon » : cornes {forme : belier | droites | courbes | petites | couronne, c, taille},
## queue {c, pointe : fleche | touffe, long} (facultatif), ailes {c, envergure} (facultatif),
## lueur [r,g,b] (les yeux qui luisent), tenue (noble | marchand | artisan | savant | garde |
## enfant | marin | pretre | gladiateur | cuisinier), objet (lanterne | livre | marteau | violon |
## baton, facultatif).
## Identifiants : « pepin_braise » et « brindille_braise », car « pepin » (Ramure) et « brindille »
## (la fée de la rosée) existent déjà ; leurs portes restent « porte_pepin » et « porte_brindille ».

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Que ta flamme ne vacille jamais, {surnom}.", "si": {}, "geste": "salut"},
		{"t": "Va, et garde les cornes au chaud ! Enfin… ce que tu as à la place des cornes.", "si": {}, "geste": "rire"},
		{"t": "À bientôt ! Si tu as froid, reviens : ici, il y a toujours une braise pour toi.", "si": {}},
		{"t": "Bonne nuit. Dors au chaud : les lanternes veillent sur la cité.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! On ne frappe pas un démon chez lui ! Ça ne se fait pas, même en enfer !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Mes cornes en tremblent ! Si tu veux te battre, va donc à l'Arène des Cornes, c'est fait pour ça !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Comme c'est aimable. Je le poserai près de la cheminée.", "si": {}},
		{"t": "Merci, {surnom}. Chez nous, un cadeau réchauffe deux fois : quand on le reçoit, et quand on y repense.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par mes cornes… tu as lu dans mon cœur, {surnom} !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau qui fait du bien ! Merci, {surnom}. Je sens ma flamme grandir.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… original. Je vais le ranger. Très loin. Du côté du Cocyte.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Dans les Neuf Cercles, tu en auras plus besoin que moi.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Un démon n'oublie jamais un visage. Ni une odeur de fumée.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Tu confonds avec un autre démon : avec nos cornes, on se ressemble tous un peu.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les démons ne gagnent jamais à cache-cache ? Parce qu'on voit toujours dépasser leurs cornes ! … Et leur queue. Et la fumée.", "si": {}, "geste": "rire"},
		{"t": "Un diablotin demande à sa mère : « Maman, je peux aller jouer dans la lave ? » Elle répond : « Oui, mais mets ton manteau, elle est à peine tiède aujourd'hui ! »", "si": {}, "geste": "rire"},
		{"t": "Pourquoi les démons ne partent jamais en vacances au Cocyte ? Parce qu'il y fait un froid d'enfer ! … Chez nous, c'est la pire des insultes.", "si": {}, "geste": "rire"},
		{"t": "Tu sais ce que dit une corne à l'autre corne ? « Toi et moi, on a toujours été sur la même tête ! »", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, et ne te brûle pas les doigts. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand j'aurai refroidi.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Que ça te tienne chaud !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même en enfer, on ne fait pas crédit. Reviens plus tard.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Il ne faut pas être gourmand. Enfin, si, un peu, mais pas trop.", "si": {}}],
	"achat_plein": [{"t": "Ton sac déborde, {surnom}. Même un démon ne pourrait rien y faire entrer.", "si": {}}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et une poignée de main brûlante en prime !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu as une bonne tête. Un petit geste. Mais ne le dis à personne, j'ai une réputation.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont déjà plus doux que la lave du matin. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. Ma queue s'en souvient.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par mes cornes !", "Ha ! Quelle chaleur !", "Flammes et merveilles !", "Ça me réchauffe le cœur !"],
		"neutre": ["Hm.", "Voyons…", "Bon.", "Écoute…"],
		"triste": ["Hélas…", "Brr…", "Ma flamme vacille…", "Pff."],
		"colere": ["Par le Grand Brasier !", "Ça suffit !", "Ma queue se hérisse…", "Grrr."],
	},
	"tics": ["Par mes cornes.", "Foi de démon.", "Comme on dit au Cercle de Feu.", "Et que ça chauffe !"],
	"humeur_mots": [[0.6, "brûlant de joie"], [0.25, "de bonne humeur"], [-0.25, "un peu éteint"], [-0.6, "fumant"], [-2.0, "en éruption"]],
	"surnoms": [[0, "petite flamme"], [25, "étincelle"], [50, "ami des braises"], [75, "cœur ardent"], [95, "âme de braise"]],
}

## Peaux de démon : rouges, carmin, bordeaux, violets, prune, bleu-gris, ardoise, cendre pâle.
const PEAU := {
	"rouge": [0.84, 0.3, 0.25], "carmin": [0.7, 0.15, 0.2], "bordeaux": [0.46, 0.12, 0.15], "violet": [0.5, 0.3, 0.6],
	"prune": [0.56, 0.27, 0.45], "bleu_gris": [0.47, 0.53, 0.62], "ardoise": [0.33, 0.35, 0.42], "cendre": [0.76, 0.73, 0.72],
}
const NOIR := [0.07, 0.05, 0.06]
const IVOIRE := [0.92, 0.87, 0.76]
const OR := [0.86, 0.66, 0.3]
const LUEUR_OR := [1.0, 0.76, 0.25]
const LUEUR_ROUGE := [1.0, 0.28, 0.12]
const LUEUR_ORANGE := [1.0, 0.52, 0.16]
const LUEUR_VIOLET := [0.72, 0.42, 1.0]
const LUEUR_VERT := [0.45, 1.0, 0.42]
const LUEUR_BLEU := [0.45, 0.72, 1.0]


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
	out["groupe"] = "braise"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Palais
		{"id": "ignatia", "nom": "Ignatia", "titre": "Archiduchesse de Pandémonia", "maison": "porte_ignatia", "village": "pandemonia",
			"agenda": [[8, 12, "palais_trone"], [12, 14, "palais_jardin"], [14, 17, ["palais_trone", "palais_balcon", "arene_gradin_6"]], [17, 19, "forge_parvis"], [19, 22, "palais_balcon"], [22, 8, "maison"]],
			"azur": {"cheveux": [0.08, 0.05, 0.07], "coiffure": "long", "yeux": LUEUR_OR, "haut": [0.1, 0.05, 0.12], "taille": 1.04},
			"teinte": PEAU["carmin"],
			"demon": {"cornes": {"forme": "couronne", "c": OR, "taille": 1.2}, "queue": {"c": [0.5, 0.08, 0.12], "pointe": "fleche", "long": 1.2},
				"ailes": {"c": [0.3, 0.05, 0.08], "envergure": 1.5}, "lueur": LUEUR_OR, "tenue": "noble"},
			"humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"rubis": 2.5, "coeur_magma": 2.5, "couronne_nuees": 2.0, "piment_infernal": 1.5, "brioche_braise": 1.5}, "deteste": {"flocon_givre": -1.5, "vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Un voyageur ! Bienvenue à Pandémonia, la plus chaude des cités ! Je suis Ignatia, Archiduchesse de l'Île de Braise. Non, ne t'incline pas : Asmodin le fera pour nous deux. Il adore ça.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Te revoilà dans ma cité. Viens, raconte-moi ce que tu as vu. Ici, les nouvelles fraîches, c'est ce qu'il y a de plus rare.", {"visites_min": 2}),
					L("Tu me cherchais jusqu'à la Cathédrale-Forge ? À cette heure-ci, je viens écouter le Cœur-Brasier. Il me dit comment va la cité. Mieux qu'Asmodin, et en moins de mots.", {"visites_min": 2, "heure_min": 17, "heure_max": 19}, "rire"),
				],
				"humeur": [L("Le Cœur-Brasier brûle haut et clair, grâce à toi. Toute la cité a chaud. Même Asmodin a souri. Deux fois. Je les ai comptées.", {"a_trouve": "coeur_vif"}, "rire"), L("Bien, merci. Enfin… aussi bien qu'une Archiduchesse qui a trois cents dossiers sur son trône et un majordome qui les classe par ordre de chaleur.", {}, "rire"), L("Le soir, depuis le balcon, je regarde les lanternes s'allumer une à une. C'est mon moment préféré : ma cité qui respire.", {"soir": true})],
				"lui": [
					L("Ma grand-mère était Archiduchesse, ma mère aussi. On dit que la couronne est sur nos cornes depuis neuf générations. En vérité, ce sont nos cornes qui poussent en couronne. C'est pratique : on ne la perd jamais.", {}, "rire"),
					L("Petite, je me cachais dans le grand lustre de la salle du trône. Asmodin me retrouvait toujours à l'odeur de dentelle roussie. Je ne lui ai jamais avoué que j'aimais surtout qu'il me cherche.", {"sujet_min": ["lui", 1]}),
					L("Mon rêve, c'est que tout l'archipel vienne un jour danser sur notre Grand-Place. On a mauvaise réputation, nous, les démons. À cause des cornes, sans doute. Ou de la fumée.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Pandémonia, c'est ma fierté : la Citadelle au centre, le Cercle de Feu tout autour, la Haute-Ville avec l'Académie, la Cathédrale-Forge et la Grand-Place des Lanternes, et en bas le Marché, l'Arène, les Thermes et le port. Promène-toi : tout le monde te dira bonjour.", {}),
					L("Sous la Cathédrale-Forge brûle le Cœur-Brasier, le grand feu qui chauffe toute la cité. Et sous le Cœur s'ouvrent les Neuf Cercles. Quand le Cœur pâlit, c'est qu'un froid remonte d'en bas. Frère Cendrin garde la Clé du Brasier : c'est à lui qu'il faut parler.", {"sujet_min": ["ile", 1]}),
					L("Tout au fond des Neuf Cercles, il y a le Cocyte, un lac gelé. On raconte qu'un Titan de Givre y dort, et que la Flamme Éternelle, qui nourrit notre Cœur-Brasier, brûle tout près de lui. Si tu descends, couvre-toi. Vraiment.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Asmodin et Madame Hurla ne se supportent pas. Il dit qu'elle crie. Elle dit qu'il chuchote. Ils ont raison tous les deux.", {}, "rire"), L("Pyrus me suit partout, avec son armure : clang, clang, clang. Je l'entends venir depuis le Cercle de Feu. Un jour, je lui offrirai des chaussons.", {}, "rire")],
				"interpelle": [L("Bonjour, voyageur ! Bienvenue chez nous !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens donc me saluer !", {"visites_min": 1})],
			}},
		{"id": "asmodin", "nom": "Asmodin", "titre": "majordome du palais", "maison": "porte_asmodin", "village": "pandemonia", "vouvoie": true,
			"agenda": [[6, 12, "palais_majordome"], [12, 13, "marche_flane_1"], [13, 18, "palais_majordome"], [18, 20, "palais_jardin"], [20, 23, "palais_majordome"], [23, 6, "maison"]],
			"azur": {"cheveux": [0.82, 0.82, 0.84], "coiffure": "court", "barbe": "moustache", "yeux": LUEUR_VIOLET, "haut": [0.08, 0.08, 0.1], "vieux": true, "taille": 1.06, "carrure": 0.85},
			"teinte": PEAU["ardoise"],
			"demon": {"cornes": {"forme": "droites", "c": NOIR, "taille": 1.1}, "queue": {"c": [0.25, 0.27, 0.33], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_VIOLET, "tenue": "noble"},
			"humeur_base": 0.1, "traits": {"bavard": 0.7, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.7, "rancunier": 0.5},
			"aime": {"huile_cornes": 2.0, "tasse_tourneuse": 2.0, "cafe_brasier": 1.5, "brioche_braise": 1.5, "perle": 1.5}, "deteste": {"vieille_botte": -2.0, "glace": -1.0, "sifflet_muet": -0.5},
			"tics": ["Si je puis me permettre.", "Naturellement.", "Comme il se doit.", "Cela va de soi."],
			"surnoms": [[0, "cher visiteur"], [25, "honorable invité"], [50, "ami de la maison"], [75, "très cher ami"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Asmodin, majordome du Palais de Pandémonia, au service de Son Altesse l'Archiduchesse Ignatia, comme de sa mère, et de la mère de sa mère. Trois cent douze ans de service. Puis-je prendre votre manteau ? Ah. Vous n'en avez pas. Fâcheux.", {"visites_max": 1}, "salut"),
					L("{surnom}. Vous revoilà. J'ai fait épousseter le hall. Je le fais épousseter tous les jours, certes. Mais aujourd'hui, c'était en prévision.", {"visites_min": 2}),
				],
				"humeur": [L("Excellente, merci. Les couverts d'argent sont alignés, les tapis brossés, et personne n'a encore crié dans le hall. Ce qui ne saurait durer, puisque Madame Hurla existe.", {}), L("Le soir, je fais le tour du palais et j'éteins les bougies inutiles. Son Altesse dit qu'elles ne coûtent rien. Le principe, {surnom}. Le principe.", {"soir": true})],
				"lui": [
					L("Je suis entré au palais comme porteur de plateaux. À l'époque, je renversais tout. Un jour, j'ai renversé un pot de crème sur l'Archiduc lui-même. Il a ri. Ce jour-là, j'ai décidé de ne plus jamais rien renverser. J'ai tenu parole.", {}),
					L("Mes cornes sont polies chaque lundi par Monsieur Tiburce. Le lustre d'une corne, voyez-vous, c'est la réputation d'une maison. Une corne terne, et c'est tout le palais qui a l'air de sortir du lit.", {"sujet_min": ["lui", 1]}),
					L("Son Altesse me prie de l'appeler Ignatia. Je ne peux pas. Trois cent douze ans d'habitude. Mais quand elle ne m'entend pas, je dis « la petite ». Ne le répétez pas.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Palais de l'Archiduchesse se dresse au sommet de la Citadelle, au-dessus du Cercle de Feu. Quatre ponts y mènent. Je vous prie de ne pas y courir : la lave n'a jamais apprécié les gens pressés.", {}),
					L("Si vous descendez dans les Neuf Cercles, vous croiserez Minos, le juge. Il pose trois questions sur le chemin parcouru. Répondez poliment, exactement, et sans bâiller. Mademoiselle Ombreline, à la Bibliothèque des Âmes, connaît les bonnes réponses. Elle connaît tout.", {"sujet_min": ["ile", 1]}),
					L("La porte des Neuf Cercles porte une inscription : « Vous qui entrez ici, gardez l'espoir (et prenez un manteau) ». La parenthèse fut ajoutée par l'arrière-grand-mère de Son Altesse. Elle était frileuse. Je l'approuvais.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Monsieur Zigomar a lancé une fusée pendant le dîner des ambassadeurs. Elle est entrée par la fenêtre et a terminé dans la soupe. J'ai servi la soupe quand même. Flambée. On m'a félicité.", {}), L("Madame Hurla crie les nouvelles à neuf heures sous les fenêtres du palais. Je lui ai écrit dix-sept lettres de protestation. Elle les a lues. À voix haute. Sur la place.", {})],
				"interpelle": [L("Vous. Oui, vous. Essuyez vos pieds, je vous prie.", {"visites_max": 0}), L("{surnom}. Bienvenue.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Je vous souhaite une excellente journée, {surnom}.", {}, "salut"), L("Au plaisir. La sortie est à votre gauche. Comme toujours.", {}), L("Bonne soirée. Et couvrez-vous : il fait frais, à peine cinquante degrés.", {"soir": true})],
				"cadeau_aime": [L("Oh. Pour moi ? C'est… d'un goût parfait. Je ne sais que dire. Si : merci, {surnom}.", {}, "salut")],
				"cadeau_neutre": [L("C'est fort aimable. Je le rangerai à l'office, à sa place. Tout a une place.", {})],
				"cadeau_deteste": [L("Je vais faire comme si je n'avais rien vu. J'y excelle : trois cent douze ans d'entraînement.", {})],
				"cadeau_refus": [L("Une arme, dans le palais ? Rangez cela immédiatement, je vous prie.", {})],
				"frappe": [{"t": "Aïe ! Vous… vous avez frappé le majordome ?! De mémoire de palais, on n'avait jamais vu cela. Je vous prie de sortir.", "si": {}, "geste": "colere", "humeur": -0.5}],
				"souvenir": [L("Naturellement, je me souviens de vous. Je me souviens de tout le monde. C'est mon métier.", {})],
			}},
		{"id": "pyrus", "nom": "Pyrus", "titre": "capitaine de la Garde", "maison": "porte_pyrus", "village": "pandemonia",
			"agenda": [[6, 9, "palais_porte"], [9, 12, "rue_1", ["rue_2", "rue_3"]], [12, 13, "palais_porte"], [13, 17, "rue_4", ["rue_5", "rue_6"]], [17, 19, ["arene_gradin_6", "rue_3"]], [19, 21, "place_banc_1"], [21, 6, "maison"]],
			"azur": {"cheveux": [0.12, 0.06, 0.05], "coiffure": "court", "barbe": "courte", "yeux": LUEUR_ROUGE, "haut": [0.35, 0.35, 0.4], "taille": 1.1, "carrure": 1.2},
			"teinte": [0.66, 0.14, 0.16],
			"demon": {"cornes": {"forme": "droites", "c": [0.25, 0.25, 0.28], "taille": 1.2}, "queue": {"c": [0.5, 0.1, 0.12], "pointe": "fleche", "long": 1.1}, "lueur": LUEUR_ROUGE, "tenue": "garde", "objet": "baton"},
			"humeur_base": 0.2, "traits": {"bavard": 0.4, "humour": 0.45, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"cafe_brasier": 2.0, "croc_cerbere": 1.5, "epee_naine": 1.5, "obsidienne": 1.0, "brioche_braise": 1.0}, "deteste": {"des_pipes": -1.5, "flocon_givre": -1.0},
			"tics": ["Rien à signaler.", "Garde à vous.", "Clang.", "Foi de capitaine."],
			"repliques": {
				"accueil": [
					L("Halte ! … Pardon. L'habitude. Capitaine Pyrus, de la Garde de Pandémonia. Bienvenue dans la cité. Ici, la première règle, c'est d'être gentil. La deuxième, c'est de ne pas nager dans le Cercle de Feu.", {"visites_max": 1}, "salut"),
					L("{surnom}. Rien à signaler ? Moi non plus. C'est ça, une bonne journée de garde.", {"visites_min": 2}),
				],
				"humeur": [L("Les chiens du champ de lave ne s'approchent plus de nos murs. Ma sœur dit qu'ils ont compris. Moi, je dis que tu as été convaincant. Rien à signaler. Merci.", {"a_trouve": "chiens_champ"}), L("En service. Toujours. Ma femme dit que même la nuit je fais des rondes. Dans mon lit. Au pas.", {}, "rire"), L("Fin de service. Ce soir, j'enlève l'armure, et Ortie me fait réciter ses leçons. Enfin, c'est moi qui récite. Elle corrige.", {"soir": true}, "rire")],
				"lui": [
					L("Mon armure, c'est Ferronde qui l'a forgée. Ma femme. Elle a cousu des patins de feutre aux genoux pour les rondes de nuit. Avant, on m'entendait arriver depuis le port. Maintenant, seulement depuis le marché.", {}, "rire"),
					L("J'ai une fille, Ortie, et une petite sœur, Flammèche, qui élève des chiots d'enfer. Entre les deux, je ne sais pas qui fait le plus de bêtises. Les chiots, au moins, s'assoient quand on dit « assis ».", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Garde veille sur les quatre ponts du Cercle de Feu, sur le port et sur les remparts. Mais le danger n'est pas dans la cité, il est dehors : les chiens d'enfer sauvages du champ de lave, à l'est du volcan. Ils rôdent de plus en plus près.", {}),
					L("Ma sœur dit que ces chiens sauvages sont juste mal élevés. Moi, je dis qu'un chien qui crache du feu sur mes gardes, mal élevé ou pas, il faut le repousser loin de nos murs. Elle dit qu'un os suffirait. Les chiens, eux, n'ont rien dit.", {"sujet_min": ["ile", 1]}),
					L("Dans les Neuf Cercles, la porte de Dité est gardée par trois Furies qui volent. Trois gardiennes contre un seul voyageur : c'est déloyal. Garde la tête froide, enfin… tiède, et occupe-toi de celle qui plonge. Conseil de capitaine.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Kraxx m'a vendu un bouclier si lourd qu'il fallait deux gardes pour le porter. Ensemble. Il protégeait surtout le sol.", {}, "rire"), L("Mon Archiduchesse s'échappe du palais par le jardin pour aller au marché. Elle croit que je ne le sais pas. Je la suis de loin. Elle croit que je ne la suis pas. Tout le monde est content.", {})],
				"interpelle": [L("Bonjour, citoyen ! Tout va bien ?", {"visites_max": 0}, "salut"), L("{surnom} ! Rien à signaler ?", {"visites_min": 1})],
			}},
		# ================================================================ la Cathédrale-Forge
		{"id": "cendrin", "nom": "Frère Cendrin", "titre": "gardien du Cœur-Brasier", "maison": "porte_cendrin", "village": "pandemonia",
			"agenda": [[5, 12, "forge_coeur"], [12, 13, "forge_parvis"], [13, 19, "forge_coeur"], [19, 21, "forge_parvis"], [21, 5, "maison"]],
			"azur": {"cheveux": [0.86, 0.84, 0.8], "coiffure": "chauve", "barbe": "longue", "yeux": LUEUR_ORANGE, "haut": [0.32, 0.18, 0.12], "vieux": true},
			"teinte": PEAU["cendre"],
			"demon": {"cornes": {"forme": "courbes", "c": [0.6, 0.58, 0.55], "taille": 0.9}, "queue": {"c": [0.6, 0.56, 0.54], "pointe": "touffe", "long": 0.9}, "lueur": LUEUR_ORANGE, "tenue": "pretre", "objet": "baton"},
			"humeur_base": 0.15, "traits": {"bavard": 0.5, "humour": 0.45, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"coeur_magma": 3.0, "buche": 1.5, "miel": 1.5, "tisane_lune": 1.5, "grog_soufre": 1.5}, "deteste": {"flocon_givre": -2.0, "eclat_givre": -1.5},
			"tics": ["Doucement.", "Le feu le sait.", "Patience, patience.", "Ainsi va la flamme."],
			"repliques": {
				"accueil": [
					L("Approche, mon enfant. N'aie pas peur : le feu ne mord que ceux qui le négligent. Je suis Frère Cendrin, gardien du Cœur-Brasier. Depuis quatre cents ans, je veille sur la flamme qui chauffe toute la cité.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Assieds-toi un instant près du feu. Écoute-le. Il crépite ton nom… enfin, presque.", {"visites_min": 2}),
				],
				"humeur": [L("Le Cœur ronronne de nouveau comme au premier jour, mon enfant. Je n'ai plus froid en dedans. Je crois que je vais faire une petite sieste près de lui. Pour fêter ça.", {"a_trouve": "coeur_vif"}), L("Paisible, comme une braise sous la cendre. C'est ma façon à moi d'être heureux.", {}), L("Le soir, le Cœur-Brasier ronronne. Je l'écoute, je lui parle, et parfois il me répond. Les vieux gardiens deviennent un peu bizarres. C'est normal.", {"soir": true}, "rire")],
				"lui": [
					L("Je suis entré à la Cathédrale-Forge à douze ans, pour balayer les cendres. Le vieux gardien d'alors m'a dit : « Le feu, ça ne se commande pas, ça s'écoute. » J'ai mis cent ans à comprendre. Je balaie encore les cendres. C'est un bon métier, pour réfléchir.", {}),
					L("Ferronde vient me prendre des braises du Cœur pour sa forge. Je grogne, elle rit. Le feu sacré n'est pas un fourneau, je lui dis. Elle répond qu'un feu qui ne sert à rien s'ennuie. Elle n'a pas tout à fait tort. Ne le lui répète pas.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Cœur-Brasier, c'est le grand feu sous la Cathédrale-Forge. Tant qu'il brûle haut, Pandémonia a chaud, les lanternes brillent, le pain lève. Quand il pâlit, toute la cité frissonne. Et un démon qui frissonne, c'est triste à voir.", {}),
					L("La Clé du Brasier ouvre la porte des Neuf Cercles, sous le Cœur. C'est moi qui la garde. Je ne la confie qu'à celui qui descendra pour le bien de la cité, avec la bénédiction de l'Archiduchesse. Va voir Ignatia, si ce n'est déjà fait.", {"sujet_min": ["ile", 1]}),
					L("La Flamme Éternelle brûle tout au fond, près du Cocyte, le lac gelé : c'est elle qui nourrit notre Cœur, de loin, comme une racine nourrit l'arbre. Mais au fond, il y a aussi le froid, et ce qui dort dans le froid. Le Titan de Givre. Garde ton feu à l'intérieur, mon enfant.", {"sujet_min": ["ile", 2]}),
					L("Dans le cercle des Tombeaux de feu, la chaleur monte des pierres comme d'un four ouvert. Même un démon y transpire. Ne t'y attarde pas : le feu aime qu'on passe, pas qu'on s'installe.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [L("Grand-père Ébène et moi, nous jouons aux dames de basalte depuis trois cents ans. Il triche : il raconte des histoires pendant que je réfléchis. Le jour de son anniversaire, je le laisse gagner. Il croit que c'est grâce aux histoires.", {}, "rire"), L("Malachar dit que c'est moi qui ai mis le feu à la tour de l'Académie, quand nous étions élèves. C'était lui. Enfin… c'était nous. Mais l'idée était à lui.", {})],
				"interpelle": [L("Approche, mon enfant, viens te réchauffer.", {"visites_max": 0}), L("{surnom}. Le feu t'attendait.", {"visites_min": 1})],
			}},
		{"id": "ferronde", "nom": "Ferronde", "titre": "maîtresse de la Grande Forge", "maison": "porte_ferronde", "village": "pandemonia",
			"agenda": [[6, 12, "forge_enclume"], [12, 13, "marche_flane_2"], [13, 18, ["forge_enclume", "forge_soufflet"]], [18, 20, "place_danse_4"], [20, 6, "maison"]],
			"azur": {"cheveux": [0.15, 0.06, 0.04], "coiffure": "queue", "yeux": LUEUR_ORANGE, "haut": [0.3, 0.2, 0.15], "carrure": 1.25, "taille": 1.04},
			"teinte": [0.68, 0.24, 0.16],
			"demon": {"cornes": {"forme": "belier", "c": [0.35, 0.25, 0.18], "taille": 1.1}, "queue": {"c": [0.5, 0.16, 0.1], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_ORANGE, "tenue": "artisan", "objet": "marteau"},
			"humeur_base": 0.35, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"coeur_magma": 3.0, "minerai_fer": 2.5, "obsidienne": 2.0, "grog_soufre": 1.5, "biere_naine": 1.5}, "deteste": {"epee_bois": -1.0, "flocon_givre": -1.0},
			"tics": ["Ha !", "Ça, c'est du solide.", "Tape, tape, tape.", "Foi de forgeronne."],
			"repliques": {
				"accueil": [
					L("Ha ! Un visiteur ! Approche, mais pas trop : les étincelles ne font pas la différence entre un client et une enclume. Ferronde, maîtresse de la Grande Forge. Tout ce qui est en fer, à Pandémonia, est passé sous mon marteau. Même mon mari. Enfin, son armure.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes bien, je viens de tremper une lame. Écoute-la chanter dans l'eau… Psssshhh ! C'est beau, hein ?", {"visites_min": 2}),
				],
				"humeur": [L("En pleine forme ! Le feu est bon, le fer est docile, et personne n'a encore laissé tomber de marteau sur mon pied aujourd'hui.", {}, "rire"), L("Le soir, je danse avec mon Pyrus sur la Grand-Place. Il danse comme un pont-levis. Je l'adore.", {"soir": true}, "rire")],
				"lui": [
					L("Ma mère forgeait, ma grand-mère forgeait, et l'arrière-grand-mère de ma grand-mère a forgé la grande grille du Cœur-Brasier. Chez nous, on naît avec un marteau dans la main. Enfin, pas vraiment. Ça ferait mal à tout le monde.", {}, "rire"),
					L("Ma fille, Ortie, ne veut pas forger. Elle veut inventer, comme Zigomar. Elle a transformé mon soufflet en machine à bulles de feu. J'étais furieuse. Et fière. Surtout fière. Ne lui dis pas.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Cathédrale-Forge, c'est une seule maison pour deux feux : le Cœur-Brasier de Frère Cendrin, et ma forge. Il dit que je lui vole ses braises. Je les emprunte ! Je les lui rends en grilles, en clous et en cloches.", {}, "rire"),
					L("Le fer de Pandémonia vient du volcan, le Grand Brasier, au sud-ouest. Ses coulées descendent jusqu'à la mer. Ne va pas te promener sur la lave fraîche : elle a l'air solide, mais elle a mauvais caractère.", {"sujet_min": ["ile", 1]}),
					L("Au fond des Neuf Cercles coule le Phlégéthon, une rivière de lave. On la traverse sur des radeaux. Saute quand le radeau est bien en face, pas avant, pas après. Le fer, ça coule. Toi aussi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Kraxx vend mes épées au marché. Il leur invente des histoires : « Celle-ci a tranché la queue d'un dragon ! » Un client est revenu demander quel dragon. Kraxx a répondu : « Un petit. »", {}, "rire"), L("Gorgoth et moi, on fait un bras de fer au Diable Repu chaque année. Je l'ai battu une fois. Il dit qu'il m'a laissée gagner. Il a pleuré, alors je ne sais pas.", {}, "rire")],
				"interpelle": [L("Hé ! Attention aux étincelles !", {"visites_max": 0}), L("{surnom} ! Viens voir ça !", {"visites_min": 1})],
			}},
		# ================================================================ l'Académie Infernale et la Bibliothèque
		{"id": "malachar", "nom": "Professeur Malachar", "titre": "directeur de l'Académie Infernale", "maison": "porte_malachar", "village": "pandemonia",
			"agenda": [[7, 8, "aca_tour"], [8, 12, "aca_chaire"], [12, 14, "aca_biblio"], [14, 17, "aca_chaire"], [17, 19, ["aca_cour_2", "aca_biblio"]], [19, 23, "aca_tour"], [23, 7, "maison"]],
			"azur": {"cheveux": [0.75, 0.74, 0.78], "coiffure": "long", "barbe": "courte", "yeux": LUEUR_VIOLET, "haut": [0.18, 0.1, 0.24], "vieux": true, "taille": 1.08},
			"teinte": [0.38, 0.22, 0.45],
			"demon": {"cornes": {"forme": "belier", "c": IVOIRE, "taille": 1.4}, "queue": {"c": [0.3, 0.16, 0.36], "pointe": "touffe", "long": 1.2},
				"ailes": {"c": [0.22, 0.12, 0.28], "envergure": 1.4}, "lueur": LUEUR_VIOLET, "tenue": "savant", "objet": "livre"},
			"humeur_base": 0.2, "traits": {"bavard": 0.9, "humour": 0.55, "curiosite": 0.95, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"grimoire": 3.0, "livre_envole": 2.0, "eclat_lune": 2.0, "cafe_brasier": 1.5, "lunettes_kaleido": 1.0}, "deteste": {"vieille_botte": -1.0, "sifflet_muet": -1.0},
			"tics": ["Hm, hm.", "Notez bien.", "Comme je l'enseigne depuis trois siècles.", "Question d'examen !"],
			"repliques": {
				"accueil": [
					L("Ah ! Un nouvel élève ? Non ? Un visiteur. C'est presque pareil : un visiteur, c'est un élève qui s'ignore. Professeur Malachar, directeur de l'Académie Infernale. Trois siècles d'enseignement, quarante mille copies corrigées, et pas une seule plume perdue. De mes ailes, s'entend.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien : j'allais justement faire une digression. Assieds-toi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Studieuse, comme toujours. J'ai découvert ce matin une erreur dans un livre que j'ai écrit il y a cent ans. Quelle joie ! On progresse.", {}, "rire"), L("Le soir, je monte en haut de la tour, j'ouvre les ailes et je regarde la cité. D'en haut, Pandémonia ressemble à un gâteau d'anniversaire. Avec beaucoup de bougies.", {"soir": true})],
				"lui": [
					L("Je suis entré à l'Académie à sept ans, comme élève. J'y suis encore. Certains disent que je n'ai jamais réussi à en sortir. C'est faux : je suis sorti une fois, il y a deux cents ans. Il pleuvait des cendres. Je suis rentré.", {}, "rire"),
					L("Frère Cendrin et moi étions dans la même classe. Il était dernier en flammes et premier en patience. Moi, l'inverse. Ensemble, nous avons mis le feu à la tour. C'était une expérience. Elle a parfaitement réussi : la tour a brûlé.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mademoiselle Sulfura a été mon élève. À sa première leçon, elle a enflammé ma barbe. Aujourd'hui, c'est la meilleure professeure de flammes de l'Académie. Je garde la barbe courte. Par prudence.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Académie Infernale forme les jeunes démons depuis mille ans : les flammes, l'histoire, les contrats, la politesse infernale et le calcul des étincelles. Elle est au nord-ouest de la Haute-Ville. Tu ne peux pas la rater : c'est le bâtiment qui fume le plus.", {}),
					L("Tu voudrais passer nos examens ? Trois épreuves : les flammes, le contrat, les étincelles. Les flammes demandent de la maîtrise, le contrat de l'attention, et les étincelles de bons réflexes. Le diplôme fait de toi un Bachelier des Flammes. C'est très bien porté.", {"sujet_min": ["ile", 1]}),
					L("Dans les Neuf Cercles, il y a les Limbes : des salles où la lumière des sages dort dans le noir. Des miroirs la renvoient de l'un à l'autre. Oriente-les comme on tourne une phrase, jusqu'à ce que la lumière arrive où elle doit aller. Question d'examen !", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Mademoiselle Ombreline m'envoie un rappel pour un livre emprunté il y a soixante-trois ans. Très poliment. Chaque année. Je vais le lui rendre. Dès que je l'aurai fini.", {}, "rire"), L("Le petit Pépin s'échappe de mes cours pour aller compter les champignons du Bois de Cendre. Il connaît leurs noms savants mieux que moi. Ça me désespère. Et ça m'enchante.", {})],
				"interpelle": [L("Toi, là ! Une question, une seule !", {"visites_max": 0}), L("{surnom} ! Question d'examen : comment vas-tu ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "sulfura", "nom": "Mademoiselle Sulfura", "titre": "professeure de flammes", "maison": "porte_sulfura", "village": "pandemonia",
			"agenda": [[7, 12, ["aca_cour_1", "aca_cour_2"]], [12, 13, "place_banc_1"], [13, 16, ["aca_cour_1", "aca_cour_2"]], [16, 18, ["arene_gradin_4", "arene_gradin_5", "aca_cour_1"]], [18, 19, "aca_cour_1"], [19, 21, "place_danse_2"], [21, 7, "maison"]],
			"azur": {"cheveux": [0.95, 0.45, 0.1], "coiffure": "chignon", "yeux": LUEUR_ORANGE, "haut": [0.12, 0.1, 0.12]},
			"teinte": [0.85, 0.28, 0.22],
			"demon": {"cornes": {"forme": "courbes", "c": NOIR, "taille": 1.0}, "queue": {"c": [0.6, 0.18, 0.14], "pointe": "fleche", "long": 1.1}, "lueur": LUEUR_ORANGE, "tenue": "savant", "objet": "baton"},
			"humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"coeur_magma": 2.0, "piment_infernal": 2.0, "cafe_brasier": 1.5, "elixir_etoile": 1.5, "chaussettes_vapeur": 1.0}, "deteste": {"flocon_givre": -1.5, "eclat_givre": -1.0},
			"tics": ["Attention, ça chauffe !", "Concentration !", "On recommence.", "Pfiou."],
			"repliques": {
				"accueil": [
					L("Bonjour ! Reculez d'un pas. Encore un. Voilà. Mademoiselle Sulfura, professeure de flammes à l'Académie Infernale. Je ne mords pas, mais mes élèves crachent, parfois. Des étincelles. Par accident.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Pile à l'heure pour la leçon. Non, je plaisante. Quoique… tu veux essayer ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Électrique ! J'ai trente diablotins qui savent enfin allumer une bougie sans allumer la bougie d'à côté. C'est un progrès énorme.", {}, "rire"), L("Le soir, je danse sur la Grand-Place. Et je n'enflamme personne. Enfin, presque personne. Zigomar ne compte pas.", {"soir": true}, "rire")],
				"lui": [
					L("À ma première leçon de flammes, j'ai mis le feu à la barbe du Professeur Malachar. Il a dit : « Excellent ! Maintenant, éteignez-la. » J'ai mis trois minutes. Il m'a donné la meilleure note de la classe. Pour l'enthousiasme.", {}, "rire"),
					L("Une flamme, ce n'est pas de la force, c'est de la politesse. On l'invite, on la guide, on la remercie. Les élèves qui crient sur leur flamme finissent toujours avec les sourcils roussis. J'en ai vu beaucoup. Des sourcils.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("L'Académie, c'est la cour où j'enseigne, la chaire du Professeur, la bibliothèque et la tour. N'entre jamais dans la tour sans frapper : le Professeur y fait des expériences. Ou la sieste. Les deux sont dangereuses.", {}, "rire"),
					L("Pour l'épreuve des flammes, garde le poignet souple et le cœur calme. Une flamme qui sent qu'on a peur fait n'importe quoi. Comme un chiot. Demande à Flammèche.", {"sujet_min": ["ile", 1]}),
					L("Au fond des Neuf Cercles coule le Phlégéthon, la rivière de lave. Elle est belle, je te jure. Mais ne la regarde pas trop longtemps : le radeau, lui, n'attend pas que tu aies fini d'admirer.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Zigomar m'envoie des fusées en forme de cœur. La dernière a explosé en forme de… rognon. Il dit que c'était voulu. C'était très mignon. Ne lui dis pas.", {}, "rire"), L("Ortie, la fille de Ferronde, est ma meilleure élève. Elle allume une bougie à dix pas. Malheureusement, elle allume aussi celles qu'on ne lui demande pas.", {})],
				"interpelle": [L("Attention, ça chauffe par ici !", {"visites_max": 0}), L("{surnom} ! Viens voir, ça brûle bien aujourd'hui !", {"visites_min": 1})],
			}},
		{"id": "pepin_braise", "nom": "Pépin", "titre": "élève diablotin, le fils de Zébuline", "maison": "porte_pepin", "village": "pandemonia",
			"agenda": [[8, 12, ["aca_eleve_1", "aca_eleve_2"]], [12, 13, "place_jeu_1", ["place_jeu_2", "place_fontaine"]], [13, 16, ["aca_eleve_1", "aca_eleve_2"]], [16, 18, ["arene_gradin_1", "arene_gradin_2", "place_jeu_1"]], [18, 19, "place_jeu_1", ["place_jeu_2", "place_fontaine"]], [19, 8, "maison"]],
			"azur": {"cheveux": [0.12, 0.05, 0.04], "coiffure": "boucles", "yeux": LUEUR_OR, "haut": [0.85, 0.6, 0.15], "enfant": true, "taille": 0.72},
			"teinte": [0.86, 0.3, 0.26],
			"demon": {"cornes": {"forme": "petites", "c": IVOIRE, "taille": 0.6}, "queue": {"c": [0.6, 0.18, 0.14], "pointe": "fleche", "long": 0.8}, "lueur": LUEUR_OR, "tenue": "enfant"},
			"humeur_base": 0.5, "traits": {"bavard": 0.95, "humour": 0.75, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"champignon_braise": 2.5, "gateau_miel": 2.5, "lave_glacee": 2.5, "canard_mecanique": 2.0, "champignon": 1.5, "brioche_braise": 1.5}, "deteste": {"vieille_botte": -0.5, "flocon_givre": -0.5},
			"tics": ["Trop bien !", "C'est vrai de vrai !", "Hé hé !", "Promis juré !"],
			"surnoms": [[0, "étranger"], [25, "copain"], [50, "grand copain"], [75, "meilleur copain"], [95, "frère de cornes"]],
			"repliques": {
				"accueil": [
					L("Chut ! … Ah, c'est toi ! Je ne suis pas perdu, hein ! Je… je compte les champignons. Mais il fait tout noir, et tous les arbres se ressemblent. Appelle-moi bien fort, d'accord ?", {"q56": "br_pepin=en_cours", "pas_trouve": "pepin_trouve"}),
					L("Salut ! Je m'appelle Pépin ! J'ai quatre-vingt-dix ans ! … En années de démon. En années normales, j'en ai neuf. T'as des cornes, toi ? Non ? T'inquiète, elles vont pousser !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu veux voir mon champignon qui brille ? Il est dans ma poche. Il brille plus, il dort.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Je me suis un peu perdu dans le Bois de Cendre, l'autre jour. Pas beaucoup ! Juste un peu. Maintenant, Maman me tient la main au marché. C'est la honte. Mais c'est un peu bien, aussi.", {"a_trouve": "pepin_trouve"}), L("Super bien ! Mademoiselle Sulfura a dit que mes étincelles étaient « originales ». Ça veut dire bien, hein ?", {}), L("Je dois rentrer, sinon Maman va faire de la fumée par les oreilles. Elle fait vraiment ça, quand elle est fâchée.", {"soir": true})],
				"lui": [
					L("Ma maman, c'est Zébuline, elle vend des épices au marché. Ça pique le nez ! Mon grand-père, c'est le Capitaine Charbonnel. Il connaît tous les nœuds du monde. Moi, je connais le nœud de lacet. C'est un début.", {}),
					L("Quand je serai grand, je serai explorateur. J'irai partout dans le Bois de Cendre et je donnerai un nom à tous les champignons qui brillent. J'en ai déjà nommé quarante. Celui-là, c'est Gérard.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Bois de Cendre, c'est le plus bel endroit du monde ! Les arbres sont noirs, les feuilles sont des braises, et les champignons brillent comme des lanternes ! Maman dit que je ne dois jamais y aller tout seul. Jamais jamais.", {}),
					L("Si un jour tu te perds dans le Bois de Cendre, suis les champignons qui brillent : ils poussent en ligne, comme un chemin. C'est moi qui l'ai découvert. Enfin, je crois. Personne ne me croit.", {"sujet_min": ["ile", 1]}),
					L("Grand-père Ébène dit que Cerbère, le chien à trois têtes des Neuf Cercles, adore les gâteaux au miel ! Mais il en faut un pour chaque tête, sinon elles se disputent. Moi aussi je veux un chien à trois têtes. Il mangerait trois gâteaux, et moi les miettes.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Ortie dit qu'elle crache des étincelles plus loin que moi. C'est faux. Enfin, c'est vrai. Mais c'est parce qu'elle s'entraîne en cachette !", {}), L("Bobor casse une brioche tous les jours à quatre heures, et il la laisse au bord du comptoir. Il dit que c'est un accident. Il a des accidents tous les jours !", {}, "rire")],
				"interpelle": [L("Hé ! Hé ! T'as vu mes cornes ? Elles ont poussé !", {"visites_max": 0}), L("{surnom} ! Viens jouer !", {"visites_min": 1})],
			}},
		{"id": "ortie", "nom": "Ortie", "titre": "élève diablotine, la fille de Ferronde", "maison": "porte_ortie", "village": "pandemonia",
			"agenda": [[8, 12, ["aca_eleve_2", "aca_eleve_1"]], [12, 13, "place_jeu_2", ["place_jeu_1", "place_fontaine"]], [13, 16, ["aca_eleve_2", "aca_eleve_1"]], [16, 18, ["arene_gradin_3", "arene_gradin_4", "place_jeu_2"]], [18, 19, "place_jeu_2", ["place_jeu_1", "place_fontaine"]], [19, 8, "maison"]],
			"azur": {"cheveux": [0.2, 0.08, 0.2], "coiffure": "tresse", "yeux": LUEUR_VERT, "haut": [0.2, 0.45, 0.35], "enfant": true, "taille": 0.75},
			"teinte": [0.6, 0.28, 0.48],
			"demon": {"cornes": {"forme": "petites", "c": [0.2, 0.12, 0.12], "taille": 0.65}, "queue": {"c": [0.42, 0.18, 0.34], "pointe": "touffe", "long": 0.7}, "lueur": LUEUR_VERT, "tenue": "enfant"},
			"humeur_base": 0.4, "traits": {"bavard": 0.85, "humour": 0.6, "curiosite": 0.95, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"canard_mecanique": 2.5, "montre_envers": 2.5, "lunettes_kaleido": 2.0, "lave_glacee": 2.0, "gateau_miel": 1.5, "minerai_fer": 1.0}, "deteste": {"epee_bois": -0.5, "vieille_botte": -0.5},
			"tics": ["Évidemment.", "Moi, je sais.", "Note bien.", "C'est scientifique."],
			"surnoms": [[0, "étranger"], [25, "copain"], [50, "assistant"], [75, "associé"], [95, "frère de cornes"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Je m'appelle Ortie, j'ai neuf ans, et je serai la plus grande inventrice de Pandémonia. Après Zigomar. Non : avant Zigomar. Tu peux noter.", {"visites_max": 1}),
					L("{surnom} ! Tu tombes bien, j'ai besoin d'un cobaye. Non, je plaisante. Un peu.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Très bien. J'ai inventé une machine à ramasser les boulons. Elle a mangé le balai de Zigomar. Mais elle marche.", {}, "rire"), L("Je dois rentrer. Papa va encore faire clang clang dans l'escalier, et Maman va rire. Tous les soirs pareil.", {"soir": true})],
				"lui": [
					L("Ma maman, c'est Ferronde, de la Grande Forge. Mon papa, c'est le capitaine Pyrus. Ma tante, c'est Flammèche, celle des chiots. Ça fait beaucoup de gens qui me surveillent. Heureusement, ils sont tous très occupés.", {}),
					L("Maman voudrait que je devienne forgeronne. Mais forger, c'est taper sur une chose jusqu'à ce qu'elle ait la bonne forme. Inventer, c'est taper sur des choses jusqu'à ce qu'elles fassent quelque chose de nouveau. C'est pas pareil.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le meilleur endroit de la cité, c'est l'atelier de Zigomar, chez les Artisans. Ça sent la poudre et le soufre, et il y a des choses qui font boum toute la journée. Maman dit que ce n'est pas un endroit pour une enfant. C'est pour ça que c'est le meilleur.", {}, "rire"),
					L("Zigomar prépare les fusées de la Nuit des Lanternes. Pour ses fusées, il lui faut des cristaux de soufre, des sources de soufre, hors de la ville. Moi, je n'ai pas le droit d'y aller. Toi, tu as le droit, non ?", {"sujet_min": ["ile", 1]}),
					L("Pépin aime trop le Bois de Cendre. Il dit qu'il connaît le chemin par cœur. Moi, je dis qu'un chemin qu'on connaît par cœur, on finit toujours par s'y perdre en pensant à autre chose. C'est scientifique.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Pépin n'est pas venu à l'école ! Je parie qu'il est au Bois de Cendre. Je l'avais dit : un chemin qu'on connaît par cœur, on s'y perd en pensant à autre chose. … J'espère qu'il va bien.", {"q56": "br_pepin=en_cours", "pas_trouve": "pepin_trouve"}), L("Pépin dit qu'il crache des étincelles plus loin que moi. J'ai mesuré : lui, quatre pas. Moi, cinq pas et demi. Les chiffres ne mentent pas, Pépin.", {}), L("Papa a porté son casque toute une journée avec un sourire que j'avais peint dessus. Tous les gardes le saluaient en souriant. Il ne comprenait pas pourquoi.", {}, "rire")],
				"interpelle": [L("Hé, toi ! Tu as des boulons ?", {"visites_max": 0}), L("{surnom} ! Viens voir mon invention !", {"visites_min": 1})],
			}},
		{"id": "ombreline", "nom": "Ombreline", "titre": "bibliothécaire des Âmes", "maison": "porte_ombreline", "village": "pandemonia",
			"agenda": [[8, 12, "biblio_pupitre", ["biblio_rayons"]], [12, 13, "biblio_rayons"], [13, 19, "biblio_pupitre", ["biblio_rayons"]], [19, 22, "biblio_pupitre"], [22, 8, "maison"]],
			"azur": {"cheveux": [0.1, 0.1, 0.16], "coiffure": "carre", "yeux": LUEUR_BLEU, "haut": [0.16, 0.18, 0.26]},
			"teinte": PEAU["bleu_gris"],
			"demon": {"cornes": {"forme": "droites", "c": [0.3, 0.32, 0.38], "taille": 0.8}, "queue": {"c": [0.36, 0.4, 0.48], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_BLEU, "tenue": "savant", "objet": "livre"},
			"humeur_base": 0.15, "traits": {"bavard": 0.3, "humour": 0.4, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"grimoire": 2.5, "livre_envole": 2.5, "tisane_lune": 2.0, "chouette_plume": 2.0, "sifflet_muet": 1.5, "plume_corbeau": 1.5}, "deteste": {"vieille_botte": -1.0, "canard_mecanique": -0.5},
			"tics": ["Chut.", "Page suivante.", "C'est noté.", "Doucement."],
			"repliques": {
				"accueil": [
					L("Chut. Bonjour. Ombreline, bibliothécaire des Âmes. Ici dort le livre de chaque démon de Pandémonia, celui de sa vie, qu'il écrit lui-même. On parle bas, on tourne les pages doucement, et on ne vole pas dans les rayons. Même avec des ailes.", {"visites_max": 1}),
					L("{surnom}. Bonjour. Tu reviens pour lire, ou pour parler ? … Les deux. Bien. Doucement, alors.", {"visites_min": 2}),
				],
				"humeur": [L("Calme. Un livre m'a souri, ce matin. Enfin, une enluminure. C'est presque pareil.", {}), L("Le soir, j'allume une seule bougie et je lis jusqu'à ce qu'elle s'éteigne. Elle s'éteint toujours au meilleur moment. C'est de la méchanceté de bougie.", {"soir": true})],
				"lui": [
					L("J'ai appris à lire avant de parler. Ma mère dit que mon premier mot fut « chut ». Je ne la crois pas. Je crois que c'était « page ».", {}),
					L("Chaque nuit, quelqu'un emprunte un recueil de poèmes par la fenêtre et le rapporte avant l'aube. Il signe le cahier d'un seul mot : « Merci ». Je sais que c'est Nox. Je laisse la fenêtre ouverte, et une bougie allumée.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Bibliothèque des Âmes est à l'ouest de la Haute-Ville. Pas d'âmes en peine, rassure-toi : seulement des livres. Chaque démon y dépose celui de sa vie. Les plus vieux sont si épais qu'il faut deux bibliothécaires pour les ouvrir.", {}),
					L("Dans les Neuf Cercles, Minos, le juge, pose trois questions sur le voyage. Il ne cherche pas à piéger : il veut savoir si tu as bien regardé. Retiens tout, en descendant : la phrase gravée sur la porte, le nom du passeur et ce qu'il demande, ce qui éclaire les Limbes.", {"sujet_min": ["ile", 1]}),
					L("Les réponses, alors. La porte dit : « Vous qui entrez ici, gardez l'espoir (et prenez un manteau) ». Le passeur de l'Achéron s'appelle Charon, et il demande une obole. Les Limbes s'éclairent de la lumière des sages, que les miroirs se renvoient. Et les cercles sont neuf. C'est noté ?", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Le Professeur Malachar me doit un livre depuis soixante-trois ans. Je lui écris chaque année. Il me répond chaque année qu'il en est au chapitre trois. Ça avance.", {}), L("Gorgoth emprunte des recueils de poèmes. Il les tient avec deux doigts, comme des papillons. Il me les rend sans un pli, avec une fleur de braise séchée dedans. C'est mon lecteur préféré. Chut.", {})],
				"interpelle": [L("Chut… Bonjour.", {"visites_max": 0}), L("{surnom}. Bonjour. Doucement.", {"visites_min": 1})],
			}},
		# ================================================================ l'Arène des Cornes
		{"id": "gorgoth", "nom": "Gorgoth le Cornu", "titre": "champion de l'Arène des Cornes", "maison": "porte_gorgoth", "village": "pandemonia",
			"agenda": [[6, 8, "chenil"], [8, 12, "arene_sable"], [12, 14, "taverne_table_1"], [14, 18, "arene_sable"], [18, 20, "thermes_bain_1"], [20, 22, "place_banc_2"], [22, 6, "maison"]],
			"azur": {"cheveux": [0.1, 0.05, 0.05], "coiffure": "chauve", "barbe": "courte", "yeux": LUEUR_ROUGE, "haut": [0.3, 0.18, 0.12], "taille": 1.2, "carrure": 1.45},
			"teinte": PEAU["bordeaux"],
			"demon": {"cornes": {"forme": "belier", "c": [0.78, 0.72, 0.6], "taille": 1.6}, "queue": {"c": [0.36, 0.08, 0.1], "pointe": "touffe", "long": 1.4}, "lueur": LUEUR_ROUGE, "tenue": "gladiateur"},
			"humeur_base": 0.35, "traits": {"bavard": 0.35, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.6, "rancunier": 0.05},
			"aime": {"gateau_miel": 2.5, "brioche_braise": 2.0, "miel": 2.0, "chouette_plume": 2.0, "plume_corbeau": 1.5, "tisane_lune": 1.5}, "deteste": {"croc_cerbere": -1.0, "flocon_givre": -0.5},
			"refuse": ["epee", "hache", "sabre_corsaire"],
			"tics": ["Pardon.", "C'est joli, ça.", "Hmm… doucement.", "Comme dit le poème."],
			"surnoms": [[0, "petit voyageur"], [25, "petite étincelle"], [50, "mon brave"], [75, "mon cher ami"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Oh. Bonjour. Pardon, je t'ai fait peur ? Je fais peur à tout le monde, à cause de la taille. Et des cornes. Et de la voix. Je m'appelle Gorgoth. On dit « Gorgoth le Cornu ». Je suis le champion de l'Arène. Mais je préfère les poèmes.", {"visites_max": 1}),
					L("{surnom}. Bonjour. J'ai écrit un poème, ce matin. Il est court. Il parle d'un chiot. Tu veux l'entendre ? … Une autre fois, d'accord.", {"visites_min": 2}),
				],
				"humeur": [L("Tu m'as battu, à l'Arène. Doucement, même. Je t'ai écrit un poème. Il rime avec « champion ». Deux fois. Je te le lirai un soir, sous la lanterne.", {"a_trouve": "tournoi"}), L("Bien. J'ai gardé les chiots de Flammèche ce matin. Ils m'ont escaladé comme une montagne. J'étais une montagne heureuse.", {}), L("Le soir, je lis sur mon banc, sous la lanterne. Nox passe et me dit bonsoir. Parfois, il me donne un poème. C'est le meilleur moment.", {"soir": true})],
				"lui": [
					L("Avant, j'étais porteur au port. Je portais quatre caisses à la fois, et je leur demandais pardon quand je les posais trop fort. Madame Hurla m'a vu. Elle a crié : « TOI ! TU VAS ÊTRE CHAMPION ! » J'ai dit oui. J'avais peur de dire non.", {}),
					L("Dans l'arène, je ne frappe jamais fort. Je pousse, je soulève, je pose doucement. Les gens croient que c'est de la stratégie. C'est de la gentillesse. Ne le dis pas à Madame Hurla, elle crierait.", {"sujet_min": ["lui", 1]}),
					L("J'écris des poèmes. Ils ne sont pas très bons. Le dernier faisait rimer « chiot » avec « chiot ». Nox dit que c'est une rime riche. Je crois qu'il est gentil.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("L'Arène des Cornes est dans la Basse-Ville, au sud-est. L'après-midi, les gradins se remplissent et tout le monde crie. Surtout Madame Hurla. Moi, je dis bonjour à la foule. Personne ne m'entend.", {}),
					L("Le Tournoi des Cornes a quatre manches. À la dernière, c'est moi qu'il faut battre. Je ne suis pas méchant, mais je suis lourd. Ne reste pas devant moi quand je charge : je ne sais pas très bien tourner.", {"sujet_min": ["ile", 1]}),
					L("Grand-père Ébène dit qu'au fond des Neuf Cercles il y a le Puits des Géants. Des géants ! Plus grands que moi ! Je voudrais les voir. Je leur lirais un poème. Peut-être qu'ils sont timides, eux aussi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Madame Hurla crie si fort que les chiots de Flammèche viennent se cacher sous moi. Douze chiots sous un seul Gorgoth. On ne se voit plus, mais on est bien.", {}), L("Bulle a fait construire aux Thermes une baignoire rien que pour moi. Elle s'appelle « le Bain Gorgoth ». Avant, quand j'entrais dans l'eau, tout le monde ressortait. Par la vague.", {}, "rire")],
				"interpelle": [L("Oh… bonjour.", {"visites_max": 0}), L("{surnom} ! … Pardon. Bonjour.", {"visites_min": 1})],
			}},
		{"id": "hurla", "nom": "Madame Hurla", "titre": "crieuse publique et maîtresse de l'arène", "maison": "porte_hurla", "village": "pandemonia",
			"agenda": [[9, 12, "place_fontaine", ["marche_flane_1", "marche_flane_2"]], [12, 13, "taverne_table_2"], [13, 14, "arene_guichet"], [14, 18, "arene_entree"], [18, 21, "place_fontaine"], [21, 9, "maison"]],
			"azur": {"cheveux": [0.85, 0.2, 0.1], "coiffure": "boucles", "yeux": LUEUR_OR, "haut": [0.75, 0.15, 0.12], "taille": 0.92},
			"teinte": [0.8, 0.3, 0.38],
			"demon": {"cornes": {"forme": "droites", "c": [0.25, 0.08, 0.08], "taille": 1.2}, "queue": {"c": [0.6, 0.2, 0.26], "pointe": "fleche", "long": 1.2}, "lueur": LUEUR_OR, "tenue": "gladiateur"},
			"humeur_base": 0.45, "traits": {"bavard": 1.0, "humour": 0.75, "curiosite": 0.7, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"cafe_brasier": 2.0, "tisane_lune": 1.5, "grog_soufre": 1.5, "piment_infernal": 1.5, "miel": 1.5}, "deteste": {"sifflet_muet": -2.0, "flocon_givre": -1.0},
			"tics": ["OYEZ !", "QUELLE AMBIANCE !", "Ha !", "ET VOILÀ !"],
			"surnoms": [[0, "VOYAGEUR"], [25, "petite étincelle"], [50, "MON GRAND"], [75, "MON CHAMPION"], [95, "ÂME DE BRAISE"]],
			"repliques": {
				"accueil": [
					L("OYEZ, OYEZ ! UN NOUVEAU VISAGE À PANDÉMONIA ! … Pardon. Bonjour. Madame Hurla, crieuse publique et maîtresse de l'Arène des Cornes. Je crie les nouvelles le matin, et les combats l'après-midi. Le soir, je crie pour le plaisir.", {"visites_max": 1}, "salut"),
					L("{surnom} ! TE REVOILÀ ! … Je baisse le ton, je baisse le ton. Qu'est-ce que tu veux savoir ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("LE NOUVEAU CHAMPION DES CORNES ! … C'est toi, je sais. Je le crie partout depuis ta victoire. Asmodin a fermé ses volets. Pour trois jours.", {"a_trouve": "tournoi"}, "rire"), L("EXCELLENTE ! J'ai crié les nouvelles du matin si fort qu'on m'a entendue au port. Le port a répondu. C'était Moloka.", {}, "rire"), L("Le soir, je laisse reposer ma voix. Enfin, j'essaie. Elle ne veut pas.", {"soir": true}, "rire")],
				"lui": [
					L("Je suis née en criant, et je n'ai jamais arrêté. À l'école, on me mettait au fond de la classe. On m'entendait quand même. Au premier rang. Et dans la classe d'à côté.", {}, "rire"),
					L("Gorgoth, c'est moi qui l'ai découvert ! Il portait quatre caisses à la fois sur le port, en leur demandant pardon. J'ai su tout de suite : CE GARÇON EST UN CHAMPION. Et un cœur d'or. Ça, il ne faut pas le crier. Pour une fois.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("OYEZ ! L'Arène des Cornes, dans la Basse-Ville, au sud-est ! Des combats tous les après-midi ! Les gradins sont pleins, la foule hurle, et c'est moi qui hurle le plus fort ! Entrée libre, sortie aussi !", {}),
					L("LE TOURNOI DES CORNES ! Quatre manches ! Trois diablotins, puis deux chiens d'enfer, puis des automates de bronze avec deux diablotins, et pour finir… GORGOTH LE CORNU ! Si tu veux t'inscrire, viens me voir à l'Arène. Je crierai ton nom !", {"sujet_min": ["ile", 1]}),
					L("Un conseil, tout bas : dans l'Arène, ne reste jamais immobile. Les diablotins sont rapides, les chiens bondissent, les automates frappent fort mais tournent lentement. Et Gorgoth… Gorgoth ne tourne pas du tout. Profites-en.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("BRINDILLE ! Ah, Brindille… Elle croit que les nouvelles voyagent mieux dans ses lettres. Le temps qu'elle vole jusqu'à la boîte, je les ai déjà criées trois fois !", {}, "rire"), L("Asmodin m'a écrit dix-sept lettres pour se plaindre de ma voix. Je les ai toutes lues sur la place. À voix haute. Tout le monde a applaudi. Lui, non.", {}, "rire")],
				"interpelle": [L("OYEZ, OYEZ ! UN VISITEUR !", {"visites_max": 0}), L("{surnom} ! PAR ICI !", {"visites_min": 1})],
			}},
		# ================================================================ la Grand-Place des Lanternes
		{"id": "lumina", "nom": "Lumina", "titre": "la lanternière", "maison": "porte_lumina", "village": "pandemonia",
			"agenda": [[8, 13, "place_lanterne"], [13, 14, "marche_flane_2"], [14, 18, "place_lanterne", ["reverbere_1", "reverbere_2"]], [18, 21, "place_lanterne"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.98, 0.8, 0.45], "coiffure": "queue", "yeux": LUEUR_OR, "haut": [0.95, 0.55, 0.15]},
			"teinte": [0.86, 0.78, 0.74],
			"demon": {"cornes": {"forme": "courbes", "c": [0.9, 0.6, 0.25], "taille": 0.85}, "queue": {"c": [0.7, 0.62, 0.6], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_OR, "tenue": "artisan", "objet": "lanterne"},
			"humeur_base": 0.5, "traits": {"bavard": 0.75, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"eclat_cristal": 2.0, "coeur_magma": 2.0, "fleur_lune": 2.0, "gateau_miel": 1.5, "cafe_brasier": 1.0}, "deteste": {"flocon_givre": -1.0, "vieille_botte": -1.0},
			"tics": ["Lumière !", "Ça brille !", "Une de plus !", "Et hop, allumée !"],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Lumina, la lanternière ! Toutes les lanternes de Pandémonia, c'est moi qui les fabrique : les petites, les grosses, les rondes, les pointues, et les sept Grandes Lanternes de la cité. Regarde : celle-ci a la forme d'une corne !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes à pic, je viens de finir une lanterne. Regarde comme elle brille… Bon, de jour, ça se voit moins.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("La Nuit des Lanternes… Tu as vu ? Les sept Grandes Lanternes, les fusées de Zigomar, toute la cité qui dansait sur la place. Je n'ai jamais vu Pandémonia aussi belle.", {"a_trouve": "fete_lanternes"}), L("Lumineuse ! Évidemment. J'ai rempli trois cents lanternes d'huile de braise ce matin. Je sens le feu de camp.", {}, "rire"), L("Le soir, c'est mon heure ! Les lanternes s'allument, Nox fait le tour des réverbères, et toute la cité devient une grande boîte à bijoux.", {"soir": true})],
				"lui": [
					L("Mon grand-père, c'est Grand-père Ébène, le conteur. Petite, il me racontait des histoires devant le feu, et je regardais les ombres danser. J'ai voulu apprendre à fabriquer la lumière, pour que les histoires aient toujours un endroit où danser.", {}),
					L("Chaque soir, je vais chercher la première flamme au Cœur-Brasier, à la Cathédrale-Forge. Frère Cendrin me la donne au bout d'une mèche. Il dit qu'une flamme se porte comme un secret : doucement, et sans courir.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Grand-Place des Lanternes, à l'est de la Haute-Ville, c'est le cœur de la fête. Il y a la fontaine, le coin du conteur, le coin de la musique, et ma grande lanterne. Le soir, tout le monde vient y danser.", {}),
					L("La Nuit des Lanternes ! Il faut allumer les sept Grandes Lanternes de la cité : celle du port, du marché, de l'arène, des thermes, de l'académie, de la forge et de la place. Quand elles brillent toutes et que les fusées de Zigomar sont prêtes, la nuit venue, toute la cité vient danser !", {"sujet_min": ["ile", 1]}),
					L("Dans les Limbes, sous la cité, la lumière des sages se promène de miroir en miroir. Grand-père dit qu'on ne la commande pas : on lui ouvre le chemin. C'est comme pour mes lanternes. La lumière va toujours là où on la laisse aller.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Quelqu'un laisse des poèmes dans mes boîtes à lanternes. Des poèmes sur la nuit, sur les flammes. Jamais signés. Je crois que c'est Nox. Il rougit dès qu'on dit le mot « poème ». Et pourtant, il est déjà tout bleu.", {}, "rire"), L("Zigomar a transformé une de mes lanternes en fusée, une fois. Elle s'est envolée au-dessus de la place, et tout le monde a applaudi. Depuis, à chaque fête, on fait s'envoler des lanternes. C'est devenu la tradition !", {})],
				"interpelle": [L("Bonjour ! Regarde mes lanternes !", {"visites_max": 0}), L("{surnom} ! Ça brille, aujourd'hui !", {"visites_min": 1})],
			}},
		{"id": "ebene", "nom": "Grand-père Ébène", "titre": "le conteur", "maison": "porte_ebene", "village": "pandemonia",
			"agenda": [[9, 11, "jardin_banc"], [11, 13, "place_conteur"], [13, 15, "maison"], [15, 20, "place_conteur"], [20, 9, "maison"]],
			"azur": {"cheveux": [0.92, 0.92, 0.9], "coiffure": "long", "barbe": "longue", "yeux": LUEUR_OR, "haut": [0.3, 0.22, 0.14], "vieux": true, "taille": 0.94},
			"teinte": [0.3, 0.3, 0.36],
			"demon": {"cornes": {"forme": "belier", "c": NOIR, "taille": 1.3}, "queue": {"c": [0.24, 0.24, 0.3], "pointe": "touffe", "long": 1.3}, "lueur": LUEUR_OR, "tenue": "savant", "objet": "baton"},
			"humeur_base": 0.35, "traits": {"bavard": 0.85, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"miel": 2.0, "brioche_braise": 2.0, "tisane_lune": 2.0, "gateau_miel": 1.5, "grimoire": 1.5, "chouette_plume": 1.5}, "deteste": {"flocon_givre": -1.0, "sifflet_muet": -0.5},
			"tics": ["Il était une fois…", "Écoute bien, petit.", "Mais c'est une autre histoire.", "Hé hé."],
			"surnoms": [[0, "petit"], [25, "mon petit"], [50, "mon enfant"], [75, "mon petit cœur"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Approche, petit, approche. Les vieilles cornes ne mordent pas. On m'appelle Grand-père Ébène. Je raconte des histoires sur la Grand-Place depuis… oh… six cents ans ? Sept ? Après cinq cents, on ne compte plus les bougies. On compte les histoires.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Assieds-toi. J'ai une histoire qui t'attendait. Elle a un peu vieilli, comme moi, mais elle a gardé toutes ses dents.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Bien, bien. Mes genoux craquent, mes cornes pèsent, mais ma mémoire est encore là. Presque toute. Il en manque un petit bout, vers l'an mille. Rien d'important.", {}, "rire"), L("Le soir, les histoires ont meilleur goût. C'est l'ombre qui leur donne du sel.", {"soir": true})],
				"lui": [
					L("Ma petite-fille, Lumina, fabrique les lanternes de la cité. Petite, elle s'endormait toujours avant la fin de mes histoires. Alors je lui racontais la fin le lendemain, au petit déjeuner. Elle a grandi en croyant que toutes les histoires finissent par des tartines.", {}, "rire"),
					L("J'ai raconté des histoires à trois Archiduchesses, quand elles étaient petites. La dernière, Ignatia, vient encore m'écouter, une capuche sur la tête. Ses cornes en couronne dépassent de la capuche. Tout le monde fait semblant de ne pas la reconnaître.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Il était une fois, sous la cité, neuf cercles creusés par les anciens pour enfermer le froid de la terre. Tout en haut, la porte et son inscription. Puis l'Achéron, une rivière sombre, et Charon le passeur, avec sa barque et sa lanterne. Il ne prend qu'une obole. Pas deux. Il est très à cheval sur les comptes.", {}),
					L("Ensuite viennent les Limbes, où dort la lumière des sages, puis Minos le juge, qui enroule sa queue autour de lui pour réfléchir, et la Tourmente, où le vent souffle sans repos. Puis Cerbère, le chien à trois têtes. Chaque tête se croit la plus importante : donne un gâteau de miel à chacune, sinon les deux autres boudent. Et une tête qui boude, ça mord.", {"sujet_min": ["ile", 1]}),
					L("Plus bas, la salle des Avares, pleine de lourds poids de bronze qu'il faut pousser à leur place ; le Styx, où seules tiennent les dalles qui ne bouillonnent pas ; la cité de Dité et ses trois Furies. Puis Géryon, qui a le visage d'un honnête homme et la queue d'un scorpion : il porte les voyageurs jusqu'en bas, en planant comme une feuille.", {"sujet_min": ["ile", 2]}),
					L("Et tout au fond, petit : Malebolge et ses ponts qui tournent, le Puits des Géants, et le Cocyte, le lac gelé, si froid que même nos cornes y claquent des dents. C'est là que brûle la Flamme Éternelle. Et c'est là que dort le Titan de Givre. Mais c'est une autre histoire… que tu écriras peut-être toi-même.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [L("Bobor me donne la première brioche de chaque fournée, en échange d'une histoire. Ça dure depuis quarante ans. Je lui dois donc… voyons… quatorze mille six cents histoires. J'en ai inventé la moitié en route. Il n'a rien remarqué.", {}, "rire"), L("Le petit Malachar, le directeur de l'Académie, dit que mes histoires ne sont pas de l'Histoire. Il a raison. Ce sont des histoires. C'est beaucoup mieux.", {}, "rire")],
				"interpelle": [L("Psst… Petit… tu veux une histoire ?", {"visites_max": 0}), L("Ah, {surnom}. Viens, viens.", {"visites_min": 1})],
			}},
		{"id": "calcine", "nom": "Calcine", "titre": "violoniste de la Grand-Place", "maison": "porte_calcine", "village": "pandemonia",
			"agenda": [[10, 12, "place_musique"], [12, 14, ["jardin_banc", "place_banc_2"]], [14, 22, "place_musique"], [22, 10, "maison"]],
			"azur": {"cheveux": [0.08, 0.06, 0.1], "coiffure": "long", "yeux": LUEUR_VIOLET, "haut": [0.5, 0.08, 0.2]},
			"teinte": PEAU["violet"],
			"demon": {"cornes": {"forme": "courbes", "c": IVOIRE, "taille": 0.9}, "queue": {"c": [0.4, 0.22, 0.48], "pointe": "fleche", "long": 1.2}, "lueur": LUEUR_VIOLET, "tenue": "noble", "objet": "violon"},
			"humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"lave_glacee": 2.0, "perle": 1.5, "eclat_cristal": 1.5, "hydromel": 1.5, "gateau_lune": 1.5, "plume_furie": 1.0}, "deteste": {"sifflet_muet": -1.0, "canard_mecanique": -0.5},
			"tics": ["Tra-la-la.", "En mesure !", "Une note de plus.", "Fortissimo."],
			"repliques": {
				"accueil": [
					L("Bonsoir… ah non, bonjour. Pour une musicienne, il est toujours un peu le soir. Calcine, violoniste de la Grand-Place. Je joue pour les danseurs, pour le conteur, pour les passants. Et pour les lanternes, quand il n'y a personne. Elles adorent les valses.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu veux une chanson ? Je t'en joue une en sol. Le sol, c'est la note des voyageurs.", {"visites_min": 2}),
				],
				"humeur": [L("Accordée ! Enfin, mon violon. Moi, je suis toujours un peu désaccordée. C'est ce qui fait mon charme.", {}, "rire"), L("Le soir, la place danse. Je joue jusqu'à ce que mes doigts fument. Littéralement : ils fument. On est des démons.", {"soir": true}, "rire")],
				"lui": [
					L("Mon violon est en bois de cendre, avec des cordes en crin de chien d'enfer. Flammèche me les garde quand elle brosse ses chiots. Il sonne chaud, un peu rauque, comme un chat qui ronronne près du feu.", {}),
					L("Grand-père Ébène raconte, et moi, je joue derrière lui. Quand l'histoire fait peur, je joue des notes graves. Quand il oublie la fin, je tiens une longue note, très longue, le temps qu'il s'en souvienne. Parfois, la note dure dix minutes.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Grand-Place des Lanternes, c'est ma scène. La fontaine pour le rythme, le conteur pour les paroles, les danseurs pour les pieds. Le soir, tout Pandémonia y passe. Même Asmodin. Il ne danse pas, mais son pied bat la mesure. Je l'ai vu.", {}, "rire"),
					L("Pour la Nuit des Lanternes, je prépare une valse nouvelle. Quand les sept Grandes Lanternes brilleront et que les fusées de Zigomar partiront, je la jouerai. Elle s'appelle… non. C'est une surprise.", {"sujet_min": ["ile", 1]}),
					L("On dit que dans la Tourmente, sous la cité, le vent souffle par rafales, comme une musique sans mesure. Écoute-le : il y a toujours un silence entre deux rafales. C'est là qu'on avance. En musique, on appelle ça un soupir.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Tiburce vient m'écouter tous les soirs. Il se met au premier rang, il ferme les yeux et il soupire. Fort. À contretemps. Je crois qu'il est amoureux. De ma musique, j'espère. Enfin… on verra.", {}, "rire"), L("Madame Hurla crie par-dessus mon violon. Alors je joue plus fort. Une fois, ça a fait un tel duel que la foule nous a jeté des pièces. On a partagé. Elle a crié merci.", {}, "rire")],
				"interpelle": [L("Une chanson, voyageur ?", {"visites_max": 0}), L("{surnom} ! Écoute ça !", {"visites_min": 1})],
			}},
		{"id": "nox", "nom": "Nox", "titre": "allumeur de réverbères", "maison": "porte_nox", "village": "pandemonia",
			"agenda": [[18, 20, "reverbere_1", ["reverbere_2"]], [20, 23, "reverbere_3", ["reverbere_4", "rue_1"]], [23, 2, ["port_phare", "place_lanterne"]], [2, 5, "reverbere_2", ["reverbere_1", "reverbere_3", "reverbere_4"]], [5, 7, "rue_3", ["rue_5"]], [7, 18, "maison"]],
			"azur": {"cheveux": [0.05, 0.05, 0.1], "coiffure": "court", "yeux": LUEUR_BLEU, "haut": [0.12, 0.14, 0.24], "carrure": 0.85},
			"teinte": [0.28, 0.3, 0.42],
			"demon": {"cornes": {"forme": "droites", "c": NOIR, "taille": 0.9}, "queue": {"c": [0.2, 0.22, 0.32], "pointe": "fleche", "long": 1.3},
				"ailes": {"c": [0.12, 0.13, 0.2], "envergure": 0.7}, "lueur": LUEUR_BLEU, "tenue": "artisan", "objet": "lanterne"},
			"humeur_base": 0.2, "traits": {"bavard": 0.2, "humour": 0.35, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.1},
			"aime": {"eclat_lune": 2.0, "plume_corbeau": 2.0, "tisane_lune": 2.0, "fleur_lune": 2.0, "chouette_plume": 2.0, "grimoire": 1.5}, "deteste": {"piment_infernal": -0.5, "vieille_botte": -1.0},
			"tics": ["…", "La nuit est belle.", "Chut, les étoiles dorment.", "Pardon."],
			"surnoms": [[0, "passant"], [25, "promeneur du soir"], [50, "ami de la nuit"], [75, "petite étoile"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Oh… bonsoir. Je… je m'appelle Nox. J'allume les réverbères. Le jour, je dors. La nuit, j'allume. Entre les deux, j'écris un peu. Pardon, je parle trop. D'habitude, je ne parle pas du tout.", {"visites_max": 1}),
					L("{surnom}… Bonsoir. Tu es venu voir les lumières ?", {"visites_min": 2}),
				],
				"humeur": [L("Ça va. La lumière du jour me fait cligner des yeux. Je suis un démon de nuit. Avec de petites ailes. Elles ne volent pas. Elles décorent.", {}), L("Bien. Très bien, même. La nuit est douce. Chaque réverbère que j'allume, c'est comme une étoile que je pose par terre.", {"soir": true})],
				"lui": [
					L("Mes ailes sont trop petites pour voler. Enfant, je sautais du toit en battant des ailes de toutes mes forces. J'atterrissais toujours dans les choux de Mère Brasille. Elle me donnait une tisane et me renvoyait chez moi.", {}),
					L("J'écris des poèmes. Sur la nuit, les flammes, les gens qui dorment. Je les laisse dans les boîtes à lanternes de Lumina. Elle ne sait pas que c'est moi. … Elle sait ? Oh non.", {"sujet_min": ["lui", 1]}),
					L("Gorgoth m'a demandé de lui apprendre la poésie. Il fait rimer « chiot » avec « chiot ». Je lui ai dit que c'était une rime riche. C'est un mensonge. Mais un mensonge gentil, et ses poèmes sont pleins de cœur.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La nuit, la cité est différente. Les rues sont vides, les lanternes ronronnent, et on entend la lave du Cercle de Feu qui chuchote. Je connais chaque réverbère par son nom. Celui du marché s'appelle Gustave. Il clignote quand il est content.", {}),
					L("La Nuit des Lanternes… Il faut allumer les sept Grandes Lanternes : le port, le marché, l'arène, les thermes, l'académie, la forge et la place. Lumina en a fait les mèches. Si tu les allumes, je regarderai. De loin. C'est ma façon d'applaudir.", {"sujet_min": ["ile", 1]}),
					L("Le Cocyte, au fond des Neuf Cercles, c'est le contraire de nos nuits : une nuit sans aucune lumière, froide comme un silence. Si tu y descends, emporte une flamme. Une petite suffit. Une petite flamme dans le grand froid, c'est déjà un poème.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Mademoiselle Ombreline laisse la fenêtre de la bibliothèque ouverte, la nuit, avec une bougie. Je ne sais pas pourquoi. … Si. Je sais. Merci, Ombreline.", {}), L("Calcine joue une valse pour moi, chaque soir, quand j'allume le premier réverbère. Elle croit que je ne l'ai pas remarqué. J'allume les réverbères en rythme. Une flamme par note.", {})],
				"interpelle": [L("… bonsoir.", {"visites_max": 0}), L("{surnom}… bonsoir.", {"visites_min": 1})],
			}},
		# ================================================================ le Grand Marché
		{"id": "zebuline", "nom": "Zébuline", "titre": "marchande d'épices, la mère de Pépin", "maison": "porte_zebuline", "village": "pandemonia",
			"agenda": [[7, 19, "marche_epices"], [19, 20, "port_quai_2"], [20, 7, "maison"]],
			"azur": {"cheveux": [0.15, 0.06, 0.04], "coiffure": "chignon", "yeux": LUEUR_OR, "haut": [0.85, 0.45, 0.12]},
			"teinte": [0.78, 0.26, 0.24],
			"demon": {"cornes": {"forme": "courbes", "c": [0.75, 0.55, 0.3], "taille": 0.9}, "queue": {"c": [0.55, 0.16, 0.14], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_OR, "tenue": "marchand"},
			"humeur_base": 0.25, "traits": {"bavard": 0.9, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"dattes": 2.0, "cacao": 2.0, "the_menthe": 1.5, "champignon_braise": 1.5, "perle": 1.5}, "deteste": {"flocon_givre": -1.0, "vieille_botte": -1.0},
			"boutique": {"vend": {"piment_infernal": 5}, "achete": {"dattes": 3, "cacao": 3, "the_menthe": 2}},
			"tics": ["Ça pique !", "Goûte-moi ça !", "Par la cannelle de feu !", "Ah, les enfants…"],
			"repliques": {
				"accueil": [
					L("{surnom} ! Tu n'as pas vu Pépin ? Il n'est pas rentré du Bois de Cendre ! Il a dû suivre ses champignons qui brillent, et là-bas, sous les arbres, il fait si noir…", {"q56": "br_pepin=en_cours", "pas_trouve": "pepin_trouve"}),
					L("Approche, approche ! Épices de Pandémonia ! Cannelle de feu, poivre de cendre, sel de soufre, et le célèbre piment infernal ! Zébuline, pour te servir. Ne renifle pas trop fort : la dernière cliente a éternué jusqu'au port.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Un petit piment ? Pour te réchauffer le cœur. Et la langue. Surtout la langue.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Depuis qu'il s'est perdu dans le Bois de Cendre, Pépin me tient la main au marché. Une heure par jour, au moins. Il dit que c'est pour me rassurer, moi. Il a raison.", {"a_trouve": "pepin_trouve"}), L("Bien, bien ! Les affaires sont bonnes, et mon voisin Kraxx éternue toute la journée. Ce n'est pas ma faute : c'est le vent.", {}, "rire"), L("Fatiguée. Après le marché, je passe voir mon père au port, puis je rentre border Pépin. Il ne s'endort jamais avant de m'avoir raconté sa journée. Trois fois.", {"soir": true})],
				"lui": [
					L("Mon père, c'est le Capitaine Charbonnel, le maître du port. Il voulait que je navigue. J'ai le mal de mer. Alors j'ai fait le contraire : je reste à quai, et ce sont les navires qui m'apportent mes épices du bout de l'archipel.", {}),
					L("Mon fils, Pépin, a neuf ans et la tête dans les champignons. Il connaît chaque arbre du Bois de Cendre. C'est bien ça qui m'inquiète. Une maman, ça s'inquiète. Même une maman démon. Surtout une maman démon.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Grand Marché est au nord-est de la Basse-Ville : mes épices, les armes de Kraxx, les potions de Vespérine et le pain de Bobor. Ça sent le feu, le sucre, le fer et le soufre. C'est l'odeur de chez nous.", {}),
					L("Le Bois de Cendre, au sud-est, est plein de merveilles et de chemins qui se ressemblent tous. Pépin y file dès que j'ai le dos tourné. Si un jour tu vois là-bas un petit diablotin aux cornes ivoire qui parle aux champignons… dis-lui que sa mère l'attend.", {"sujet_min": ["ile", 1]}),
					L("Tu descends dans les Neuf Cercles ? Ébène dit que la salle des Avares est pleine de poids à pousser. Moi, je pèse des épices toute la journée : un poids, ça se pousse avec les jambes, pas avec les bras. Et réfléchis avant de pousser : un poids, ça ne se tire pas.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Kraxx, mon voisin d'étal, tape sur ses épées toute la journée. Clang ! Clang ! Ça fait fuir mes clients. Alors j'ai mis le poivre de cendre du côté de son étal. Depuis, il éternue. On est quittes.", {}, "rire"), L("Vespérine m'achète du piment infernal pour ses « potions de courage ». Je lui ai demandé sa recette. Elle m'a répondu : « Du piment infernal. » Elle n'a même pas souri.", {}, "rire")],
				"interpelle": [L("Épices ! Épices de feu !", {"visites_max": 0}), L("{surnom} ! Goûte-moi ça !", {"visites_min": 1})],
			}},
		{"id": "kraxx", "nom": "Kraxx", "titre": "armurier du Grand Marché", "maison": "porte_kraxx", "village": "pandemonia",
			"agenda": [[8, 16, "marche_armes"], [16, 18, ["arene_gradin_2", "marche_armes"]], [18, 21, "taverne_table_3"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.1, 0.1, 0.1], "coiffure": "court", "barbe": "courte", "yeux": LUEUR_ROUGE, "haut": [0.25, 0.22, 0.2], "carrure": 1.2},
			"teinte": [0.42, 0.14, 0.16],
			"demon": {"cornes": {"forme": "droites", "c": [0.4, 0.38, 0.36], "taille": 1.2}, "queue": {"c": [0.32, 0.1, 0.12], "pointe": "fleche", "long": 0.7}, "lueur": LUEUR_ROUGE, "tenue": "artisan"},
			"humeur_base": 0.05, "traits": {"bavard": 0.3, "humour": 0.55, "curiosite": 0.3, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"obsidienne": 2.0, "croc_cerbere": 2.0, "minerai_fer": 1.5, "dent_requin": 1.5, "grog_soufre": 1.5, "rubis": 1.5}, "deteste": {"piment_infernal": -1.5, "epee_bois": -0.5},
			"boutique": {"vend": {"epee": 60, "hache": 34, "sabre_corsaire": 140}, "achete": {"epee_bois": 2, "hache": 14, "epee": 26, "sabre_corsaire": 60, "obsidienne": 8, "minerai_fer": 5}},
			"tics": ["Hm.", "Qualité.", "Atchoum.", "Bon."],
			"repliques": {
				"accueil": [
					L("Hm. Kraxx. Armurier. Épées, haches, sabres. Du solide, forgé par Ferronde, vendu par moi. Tu touches, tu achètes. Tu casses, tu paies. Atch… Atchoum ! Pardon. C'est le poivre de la voisine.", {"visites_max": 1}),
					L("{surnom}. Une lame ? … Atchoum.", {"visites_min": 2}),
				],
				"humeur": [L("Ça irait mieux si l'étal d'à côté vendait des fleurs. Atchoum.", {}), L("Le soir, je bois un grog de soufre au Diable Repu. Sans épices. J'ai demandé.", {"soir": true})],
				"lui": [
					L("J'ai été garde, avant. Trente ans sur les remparts. Un jour, mon épée s'est cassée sur une gargouille. Je me suis dit : il faut de meilleures lames. Alors je me suis mis à les vendre. Les gargouilles sont toujours là. Mais mes lames ne cassent plus.", {}),
					L("Ferronde et moi, on se dispute les prix chaque semaine. Elle dit que sa lame vaut soixante, je dis qu'elle en vaut quarante. On finit toujours à cinquante, et on est tous les deux persuadés d'avoir perdu.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le marché, c'est au nord-est de la Basse-Ville. Mon étal est le seul sans fumée d'épices. Enfin, il devrait l'être.", {}),
					L("Si tu fais le Tournoi des Cornes, prends une lame que tu connais. Les diablotins sont rapides : il faut frapper vite. Les automates de bronze sont durs : il faut frapper fort. Gorgoth… Gorgoth, une lame ne suffit pas. Il faut de la patience.", {"sujet_min": ["ile", 1]}),
					L("Ébène dit qu'au fond des Neuf Cercles, à Malebolge, les ponts tournent. Conseil d'ancien garde : ne cours pas sur un pont qui bouge. Attends qu'il s'arrête en face de toi. Un pont qui tourne, c'est comme un client qui hésite : il finit toujours par se décider.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Pyrus marchande comme un poissonnier. « Prix de la Garde », qu'il dit. La Garde, c'est lui. Le prix aussi, apparemment.", {}), L("Le Capitaine Charbonnel m'a rapporté un harpon tordu. Une gargouille l'avait plié avec ses dents. Il m'a dit : « Ton harpon fait des nœuds. » J'ai répondu : « Ta gargouille mange du fer. » Match nul.", {}, "rire")],
				"interpelle": [L("Hm. Une lame ?", {"visites_max": 0}), L("{surnom}. … Atchoum.", {"visites_min": 1})],
			}},
		{"id": "vesperine", "nom": "Vespérine", "titre": "apothicaire du Grand Marché", "maison": "porte_vesperine", "village": "pandemonia",
			"agenda": [[8, 12, "marche_potions"], [12, 14, ["jardin_massif_2", "jardin_massif_1"]], [14, 19, "marche_potions"], [19, 21, "jardin_banc"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.18, 0.08, 0.2], "coiffure": "carre", "yeux": LUEUR_VERT, "haut": [0.18, 0.3, 0.22]},
			"teinte": [0.5, 0.26, 0.42],
			"demon": {"cornes": {"forme": "courbes", "c": [0.18, 0.1, 0.16], "taille": 0.9}, "queue": {"c": [0.36, 0.18, 0.3], "pointe": "fleche", "long": 1.0}, "lueur": LUEUR_VERT, "tenue": "savant"},
			"humeur_base": 0.05, "traits": {"bavard": 0.5, "humour": 0.65, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"champignon_braise": 2.0, "fleur_lune": 2.0, "eclat_cristal": 1.5, "tisane_brume": 1.5, "the_menthe": 1.0, "montre_envers": 1.0}, "deteste": {"huile_cornes": -1.5, "vieille_botte": -1.0},
			"boutique": {"vend": {"potion_seve": 14, "potion_mana": 9, "elixir_etoile": 16}, "achete": {"fleur_lune": 12, "eclat_cristal": 8, "champignon_braise": 4, "champignon": 2}},
			"tics": ["Techniquement…", "Fascinant.", "Évidemment.", "Prends des notes."],
			"repliques": {
				"accueil": [
					L("Bonjour. Vespérine, apothicaire. Potions de sève, potions de magie, élixirs d'étoile. Tout est étiqueté, daté et testé. Sur moi. Ne t'inquiète pas pour le vert de mes yeux : c'est naturel. Enfin, je crois.", {"visites_max": 1}),
					L("{surnom}. Tu as la tête de quelqu'un qui a besoin d'une potion. Ou d'une sieste. Je ne vends que les potions.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Correcte. J'ai réussi une potion qui rend la voix plus douce. Je la garde pour Madame Hurla. Pour son anniversaire. Ou pour le mien.", {}, "rire"), L("Le soir, je vais m'asseoir aux Jardins de Cendre, près des herbes de ma mère. C'est le seul endroit de la cité où personne ne me demande une potion contre le hoquet.", {"soir": true})],
				"lui": [
					L("J'ai un frère jumeau, Bulle, le maître des Thermes. Je suis née trois minutes avant lui. Il rit tout le temps, moi pas. Notre mère dit qu'à la naissance, on s'est partagé le caractère : il a pris tout le rire, j'ai pris tout le reste.", {}),
					L("Ma mère, Mère Brasille, cultive les Jardins de Cendre. Toutes mes herbes viennent de chez elle. À cinq ans, j'étiquetais déjà ses pots de confiture. Avec la date, le poids et le nom savant. Elle m'a regardée bizarrement. Elle me regarde encore comme ça.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Les Thermes de Soufre et les Jardins de Cendre sont au sud de la Basse-Ville. Le soufre des sources est excellent pour la peau, les cornes et le moral. Techniquement. Le moral, je ne l'ai jamais mesuré.", {}),
					L("Les fleurs de braise poussent sur les pentes du volcan. Ma mère en cherche toujours pour ses massifs. Elles brûlent sans se consumer : un mystère botanique. Si tu en cueilles, prends-les par la tige, et parle-leur poliment.", {"sujet_min": ["ile", 1]}),
					L("Si tu descends dans les Neuf Cercles, prends des potions. Plusieurs. Le froid du Cocyte n'a rien de magique : il est simplement très, très froid, et un corps n'aime pas ça. Une potion de sève, c'est un manteau qu'on boit.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Tiburce vend une « huile à cornes » qui guérirait tout. Je l'ai analysée : neuf dixièmes de parfum, un dixième de vanité. Ça ne guérit rien, mais ça sent très bon. C'est déjà ça.", {}), L("Mon frère Bulle a voulu faire des bulles avec une de mes potions. La potion a fait des bulles. Bulle aussi. Pendant deux jours. Il a trouvé ça formidable.", {}, "rire")],
				"interpelle": [L("Une potion ? Tu as l'air d'en avoir besoin.", {"visites_max": 0}), L("{surnom}. Tu es pâle. Enfin, pour quelqu'un sans cornes.", {"visites_min": 1})],
			}},
		{"id": "bobor", "nom": "Bobor", "titre": "boulanger du Four Éternel", "maison": "porte_bobor", "village": "pandemonia",
			"agenda": [[4, 14, "marche_pain"], [14, 16, ["arene_gradin_3", "arene_gradin_4"]], [16, 19, "marche_pain"], [19, 21, "thermes_bain_2"], [21, 4, "maison"]],
			"azur": {"cheveux": [0.95, 0.92, 0.88], "coiffure": "court", "barbe": "moustache", "yeux": LUEUR_ORANGE, "haut": [0.95, 0.93, 0.88], "carrure": 1.4, "taille": 0.96},
			"teinte": [0.84, 0.4, 0.38],
			"demon": {"cornes": {"forme": "petites", "c": [0.95, 0.9, 0.8], "taille": 0.7}, "queue": {"c": [0.66, 0.3, 0.28], "pointe": "touffe", "long": 0.7}, "lueur": LUEUR_ORANGE, "tenue": "cuisinier"},
			"humeur_base": 0.55, "traits": {"bavard": 0.75, "humour": 0.75, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"miel": 2.5, "pain_miel": 2.0, "croissant": 2.0, "gateau_lune": 2.0, "baguette": 1.5, "tarte_potiron": 1.5}, "deteste": {"vieille_botte": -1.5, "galette_algue": -0.5},
			"boutique": {"vend": {"brioche_braise": 4, "gateau_miel": 9}, "achete": {"miel": 5, "baies": 1, "pomme": 1}},
			"tics": ["Hmm, ça sent bon !", "À la bonne pâte !", "Ho ho !", "Tout chaud, tout chaud !"],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Bobor, boulanger du Four Éternel ! Mon four ne s'est jamais éteint depuis quatre cents ans : mon arrière-arrière-grand-père l'a allumé avec une braise du Cœur-Brasier. Une brioche de braise ? Elle sort du four. Elle est chaude. Toujours.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Ta brioche t'attend ! Enfin, une brioche. Toutes les brioches attendent quelqu'un.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Comme une pâte qui lève : de mieux en mieux ! Je me suis levé à trois heures, j'ai pétri, j'ai chanté, j'ai goûté. Beaucoup goûté.", {}, "rire"), L("Le soir, je vais flotter aux Thermes. Je flotte très bien. Bulle dit que je suis le seul client qui ne coule jamais. C'est grâce aux brioches.", {"soir": true}, "rire")],
				"lui": [
					L("Le Four Éternel, c'est mon trésor. Quatre cents ans sans s'éteindre. La nuit, je lui chante des berceuses pour qu'il ne s'ennuie pas. Les voisins disent que c'est le four qui chante. Je ne les contredis pas.", {}),
					L("Chaque matin, je donne la première brioche à Grand-père Ébène, contre une histoire. Ça dure depuis quarante ans. Je ne lui ai jamais dit que je connaissais déjà la moitié de ses histoires. Il les raconte si bien, la deuxième fois.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Mon étal est au Grand Marché, au nord-est de la Basse-Ville. Suis l'odeur de brioche. Si tu sens le piment, c'est Zébuline : trop à gauche. Si tu entends éternuer, c'est Kraxx : trop à droite.", {}, "rire"),
					L("Grand-père Ébène dit que Cerbère, le gardien à trois têtes des Neuf Cercles, se laisse amadouer par des gâteaux de miel. Un par tête ! Mes gâteaux de miel sont les meilleurs de l'île. Il me faut du bon miel, c'est tout. Le miel, c'est l'âme du gâteau.", {"sujet_min": ["ile", 1]}),
					L("Trois gâteaux pour trois têtes, retiens bien. Si tu n'en donnes que deux, la troisième tête boude, et une tête qui boude, chez un chien de cette taille… Ébène dit que ça finit mal. Moi, je dis que ça finit en bagarre. C'est pareil, avec moins de gâteaux.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Grumbald dit que sa lave glacée est le meilleur dessert de Pandémonia. Un sorbet ! Un dessert froid ! Chez des démons ! Bon… je l'adore. Mais je ne le dirai jamais devant lui.", {}, "rire"), L("Le petit Pépin passe tous les jours à quatre heures, juste quand une brioche se casse, par accident, au bord du comptoir. C'est fou, les accidents qui arrivent à l'heure.", {}, "rire")],
				"interpelle": [L("Brioches chaudes ! Toujours chaudes !", {"visites_max": 0}), L("{surnom} ! Une brioche ?", {"visites_min": 1})],
			}},
		# ================================================================ le Port de Cendre
		{"id": "charbonnel", "nom": "Capitaine Charbonnel", "titre": "maître du Port de Cendre", "maison": "porte_charbonnel", "village": "pandemonia",
			"agenda": [[6, 12, "port_capitainerie"], [12, 13, "taverne_table_3"], [13, 15, ["port_capitainerie", "port_phare"]], [15, 17, ["arene_gradin_5", "port_capitainerie"]], [17, 18, "port_quai_1"], [18, 22, "taverne_table_1"], [22, 6, "maison"]],
			"azur": {"cheveux": [0.7, 0.7, 0.72], "coiffure": "court", "barbe": "longue", "yeux": LUEUR_ORANGE, "haut": [0.1, 0.12, 0.2], "vieux": true, "carrure": 1.15},
			"teinte": PEAU["ardoise"],
			"demon": {"cornes": {"forme": "belier", "c": [0.55, 0.55, 0.52], "taille": 1.2}, "queue": {"c": [0.26, 0.28, 0.34], "pointe": "touffe", "long": 1.0}, "lueur": LUEUR_ORANGE, "tenue": "marin"},
			"humeur_base": 0.2, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"grog_soufre": 2.5, "boussole": 2.0, "sardines_grillees": 1.5, "dent_requin": 1.5, "corail_rouge": 1.5, "etoile_mer": 1.5}, "deteste": {"flocon_givre": -1.0, "vieille_botte": -0.5},
			"tics": ["Par les cendres de la Rade !", "Mille tisons !", "Foi de marin.", "Bon vent."],
			"surnoms": [[0, "moussaillon"], [25, "matelot"], [50, "ami des braises"], [75, "loup de mer"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Ohé ! Capitaine Charbonnel, maître du Port de Cendre ! Soixante ans de mer, trois naufrages, deux cornes et un genou qui grince quand le vent tourne. Bienvenue dans la Rade, moussaillon. Ici, les voiles sont noires et les cœurs sont rouges.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Le vent est bon, la mer est tiède. Tu viens prendre des nouvelles du large ?", {"visites_min": 2}),
				],
				"humeur": [L("Plus une gargouille sur les falaises ! Mes navires sortent de la Rade sans trembler. Même le vieux Tison, au fond du port, a l'air content. Si, si. Je le connais.", {"a_trouve": "gargouilles_ruines"}, "rire"), L("Correcte, mais j'ai l'œil sur les falaises du nord-ouest. Ces satanées gargouilles ne me laissent pas dormir. Ni moi, ni mes navires.", {}), L("Le soir, je prends ma table au Diable Repu et je raconte la tempête de cendre. Grumbald la connaît par cœur. Il remue les lèvres en même temps que moi.", {"soir": true}, "rire")],
				"lui": [
					L("J'ai pris la mer à dix ans, sur un brick aux voiles noires. J'ai vu les îles de l'est, les glaces du nord, et une baleine qui chantait faux. Puis l'Archiduchesse m'a confié le port. J'ai rangé ma longue-vue. Enfin, presque : je la sors tous les matins.", {}),
					L("Ma fille, Zébuline, vend des épices au marché : le mal de mer, elle l'a eu dès le berceau. Mon petit-fils, Pépin, lui, a le pied marin. Je lui apprends les nœuds. Il connaît le nœud de lacet. On progresse.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Port de Cendre, c'est la Rade, au nord-est de l'île : les quais de basalte, mes navires aux voiles noires, la poissonnerie de Moloka, la poste de Brindille, le Diable Repu et le phare au feu rouge. Tout ce qui arrive à Pandémonia passe par ici. Toi aussi, d'ailleurs.", {}),
					L("Les gargouilles, voilà mon souci. Elles nichent dans les Ruines de l'Ancien Pandémonium, sur les falaises du nord-ouest, et elles plongent sur mes navires : voiles arrachées, poisson volé. Peau de pierre, ailes de chauve-souris. Mes harpons rebondissent dessus.", {"sujet_min": ["ile", 1]}),
					L("Un vieux marin te le dira : au fond des Neuf Cercles, sur l'Achéron, il y a un passeur. Charon. Il ne fait pas crédit. Une obole, une seule, et il te fait traverser. N'oublie jamais de payer le passeur, moussaillon. C'est la première loi de toutes les mers.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Mon petit-fils n'est pas rentré du Bois de Cendre. Zébuline est blanche comme la cendre. Si tu vas au sud-est, appelle-le fort : Pépin répond toujours quand on crie son nom.", {"q56": "br_pepin=en_cours", "pas_trouve": "pepin_trouve"}), L("Moloka a lancé une sardine à la tête de Grumbald, il y a vingt-cinq ans, parce qu'il avait dit que son poisson n'était pas frais. Ils se sont mariés l'année suivante. La sardine était de la noce.", {}, "rire"), L("Brindille vient m'emprunter ma longue-vue pour guetter les navires. Elle dit que c'est pour le courrier. Je crois qu'elle aime surtout voir la mer de haut. Elle a des ailes, elle, la chanceuse.", {})],
				"interpelle": [L("Ohé, moussaillon !", {"visites_max": 0}, "salut"), L("{surnom} ! Ohé !", {"visites_min": 1})],
			}},
		{"id": "moloka", "nom": "Moloka", "titre": "poissonnière du port", "maison": "porte_moloka", "village": "pandemonia",
			"agenda": [[5, 8, "port_quai_1"], [8, 13, "port_poisson"], [13, 15, ["arene_gradin_5", "arene_gradin_6"]], [15, 18, "port_poisson"], [18, 21, "taverne_table_2"], [21, 5, "maison"]],
			"azur": {"cheveux": [0.2, 0.25, 0.35], "coiffure": "tresse", "yeux": LUEUR_BLEU, "haut": [0.2, 0.35, 0.45], "carrure": 1.15},
			"teinte": [0.46, 0.52, 0.6],
			"demon": {"cornes": {"forme": "courbes", "c": [0.85, 0.85, 0.88], "taille": 0.9}, "queue": {"c": [0.34, 0.4, 0.48], "pointe": "fleche", "long": 0.9}, "lueur": LUEUR_BLEU, "tenue": "marin"},
			"humeur_base": 0.35, "traits": {"bavard": 0.85, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"poisson_lune": 2.5, "perle": 2.0, "corail_rouge": 1.5, "etoile_mer": 1.5, "coquillage": 1.5, "lave_glacee": 1.5}, "deteste": {"vieille_botte": -2.0, "galette_algue": -0.5},
			"boutique": {"vend": {"maquereau": 6}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 6, "bar": 7, "poisson_perroquet": 11, "merou": 16, "poisson_lune": 28}},
			"tics": ["Frais du matin !", "Ça frétille !", "Foi de poissonnière.", "Et que ça saute !"],
			"repliques": {
				"accueil": [
					L("MAQUEREAU ! … Pardon, l'habitude. Bonjour ! Moloka, poissonnière du port. Je pêche à l'aube, je vends le matin, et je crie toute la journée. Tu as du poisson à vendre ? Je t'achète tout ce qui frétille. Sauf les bottes.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Il est frais, mon poisson ! Il est presque encore dans l'eau !", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Bonne ! Les maquereaux mordent, et aucune gargouille n'a pillé mon étal ce matin. Je touche du basalte.", {}), L("Le soir, je m'assois au Diable Repu, chez mon mari. Il me sert une lave glacée, et je lui raconte la pêche. Il fait semblant d'écouter. Je fais semblant de ne pas le voir.", {"soir": true}, "rire")],
				"lui": [
					L("J'ai rencontré Grumbald en lui lançant une sardine à la tête. Il avait dit que mon poisson n'était pas frais. La sardine, elle, était fraîche : il l'a senti passer. On s'est mariés l'année d'après. Vingt-cinq ans. Il ne critique plus jamais mon poisson.", {}, "rire"),
					L("Ma peau est bleue comme la mer du matin. Ma mère disait qu'une poissonnière, il faut que ça se voie de loin. Moi, je dis qu'il suffit de crier. Hurla et moi, on fait un concours chaque année. J'ai gagné une fois, avec « MAQUEREAU ».", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La poissonnerie est sur le quai, à côté de la capitainerie du vieux Charbonnel. Dans la Rade, l'eau est tiède, à cause du volcan. Les poissons y sont gras et paresseux. Les meilleurs.", {}),
					L("Les gargouilles des ruines, au nord-ouest, viennent voler mon poisson sur le quai. Elles tombent du ciel comme des pierres, attrapent une dorade et repartent. Une m'a pris un mérou entier. Le mérou était plus gros qu'elle.", {"sujet_min": ["ile", 1]}),
					L("On dit que dans les Neuf Cercles, sur le Styx, il y a des dalles posées sur l'eau, et que certaines s'enfoncent. Moi, je connais l'eau : quand ça bouillonne en dessous, c'est que ça ne tient pas. Ne marche que sur les dalles bien calmes.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Ma copine Hurla m'a appris à crier. Moi, je lui ai appris à vider un poisson. Elle crie toujours mieux que moi. Et elle vide toujours très mal les poissons.", {}, "rire"), L("Chaque matin, je donne mes restes de poisson à Flammèche pour ses chiots. Un des chiots m'a volé un mérou entier, une fois. Il l'a traîné jusqu'au chenil. Il était si fier que je n'ai pas osé le gronder.", {}, "rire")],
				"interpelle": [L("POISSON FRAIS ! POISSON FRAIS !", {"visites_max": 0}), L("{surnom} ! Viens voir ma pêche !", {"visites_min": 1})],
			}},
		{"id": "grumbald", "nom": "Grumbald", "titre": "tavernier du Diable Repu", "maison": "porte_grumbald", "village": "pandemonia",
			"agenda": [[10, 14, "taverne_comptoir"], [14, 16, ["arene_gradin_1", "arene_gradin_2"]], [16, 1, "taverne_comptoir"], [1, 10, "maison"]],
			"azur": {"cheveux": [0.2, 0.1, 0.06], "coiffure": "chauve", "barbe": "longue", "yeux": LUEUR_ORANGE, "haut": [0.55, 0.3, 0.15], "carrure": 1.4},
			"teinte": [0.62, 0.2, 0.2],
			"demon": {"cornes": {"forme": "belier", "c": [0.4, 0.28, 0.2], "taille": 1.1}, "queue": {"c": [0.45, 0.14, 0.14], "pointe": "touffe", "long": 1.0}, "lueur": LUEUR_ORANGE, "tenue": "cuisinier"},
			"humeur_base": 0.45, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"champignon_braise": 2.0, "cafe_vapeur": 2.0, "piment_infernal": 1.5, "the_menthe": 1.5, "cacao": 1.5, "biscuit_engrenage": 1.0}, "deteste": {"vieille_botte": -1.0, "flocon_givre": -0.5},
			"boutique": {"vend": {"grog_soufre": 5, "cafe_brasier": 4, "lave_glacee": 6}, "achete": {"champignon_braise": 4, "miel": 4, "sardine": 2}},
			"tics": ["Mon brave !", "À la tienne !", "Ho ho ho !", "Qui a soif ?"],
			"repliques": {
				"accueil": [
					L("Entre, entre ! Bienvenue au Diable Repu, la meilleure taverne de l'Île de Braise ! Grumbald, patron, cuisinier et confident. Grog de soufre, café du Brasier, lave glacée : on sert tout ce qui réchauffe, et un seul truc qui rafraîchit. Assieds-toi où tu veux, sauf à la table du Capitaine.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Ta place t'attend ! Un grog de soufre ? Sans une goutte d'alcool : du soufre, du miel et de la cannelle de feu. Ça réchauffe sans faire tourner la tête.", {"visites_min": 2}),
				],
				"humeur": [L("Repu ! Comme ma taverne. J'ai goûté ma nouvelle sauce toute la matinée. Elle est prête. Moi aussi, je suis prêt. Pour une sieste.", {}, "rire"), L("Le soir, le Repu est plein : le Capitaine raconte sa tempête, Kraxx éternue, ma Moloka rit. C'est le plus beau bruit du monde.", {"soir": true})],
				"lui": [
					L("Mon grand-père a ouvert le Diable Repu il y a trois cents ans. Il disait : « Un démon qui a bien mangé ne fait de mal à personne. » C'est la devise de la maison. Elle est gravée au-dessus du comptoir, avec une faute d'orthographe. On la garde : c'est la tradition.", {}),
					L("Ma femme, Moloka, m'a lancé une sardine à la figure le jour où on s'est rencontrés. J'avais dit que son poisson n'était pas frais. J'avais tort. Depuis vingt-cinq ans, c'est elle qui m'apporte le poisson, et moi, je dis seulement « merci ».", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Diable Repu est au Port de Cendre, sur le quai. Les marins y viennent pour le grog, les marchands pour les nouvelles, et les nouvelles pour les marchands. Tout ce qui se dit à Pandémonia se dit d'abord ici.", {}),
					L("La lave glacée, c'est mon invention : un sorbet de fruits de feu, servi dans une coupe d'obsidienne. Froid dehors, chaud dedans. Les démons font semblant d'être choqués. Puis ils en reprennent.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Un conseil de tavernier pour les Neuf Cercles : là-dessous, plus on descend, plus il fait froid. Bois chaud avant de partir, et emporte de quoi te remonter. Un grog de soufre, ça te réchauffe jusqu'au bout des cornes. Même si tu n'en as pas.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Bobor dit que ses gâteaux sont meilleurs que ma lave glacée. Il en mange trois coupes chaque fois qu'il vient. De ma lave glacée. Pour vérifier, qu'il dit.", {}, "rire"), L("Le Capitaine Charbonnel raconte la même tempête de cendre tous les soirs depuis trente ans. Chaque fois, les vagues sont plus hautes. Elles font maintenant la taille du volcan.", {}, "rire")],
				"interpelle": [L("Hé, voyageur ! Un grog pour la route ?", {"visites_max": 0}), L("{surnom} ! Qui a soif ?", {"visites_min": 1})],
			}},
		{"id": "brindille_braise", "nom": "Brindille", "titre": "factrice ailée", "maison": "porte_brindille", "village": "pandemonia",
			"agenda": [[7, 9, "poste"], [9, 12, "rue_5", ["rue_6", "rue_4", "palais_porte"]], [12, 13, "poste"], [13, 17, "rue_2", ["rue_3", "aca_cour_2", "marche_flane_2"]], [17, 19, "poste"], [19, 21, ["place_danse_3", "place_jeu_1"]], [21, 7, "maison"]],
			"azur": {"cheveux": [0.95, 0.85, 0.95], "coiffure": "queue", "yeux": LUEUR_VIOLET, "haut": [0.25, 0.3, 0.55], "taille": 0.9, "carrure": 0.85},
			"teinte": [0.7, 0.5, 0.75],
			"demon": {"cornes": {"forme": "petites", "c": [0.9, 0.85, 0.95], "taille": 0.6}, "queue": {"c": [0.55, 0.38, 0.6], "pointe": "fleche", "long": 0.8},
				"ailes": {"c": [0.45, 0.3, 0.55], "envergure": 1.2}, "lueur": LUEUR_VIOLET, "tenue": "marchand"},
			"humeur_base": 0.45, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"lettre_azur": 2.5, "boussole": 2.0, "cafe_brasier": 2.0, "chouette_plume": 1.5, "brioche_braise": 1.5}, "deteste": {"flocon_givre": -1.0, "vieille_botte": -1.0},
			"tics": ["Pas le temps !", "Vite, vite !", "Courrier !", "Et hop, envolée !"],
			"repliques": {
				"accueil": [
					L("Bonjour-bonjour ! Brindille, factrice ! Je vole, je livre, je repars ! Lettres, colis, cartes, mots doux, factures, et une fois un fromage, mais je n'en parle plus. Tu as du courrier ? Non ? Dommage. Bon, à plus ! … Non, attends, je reste un peu. Tu as l'air gentil.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Pas de lettre pour toi aujourd'hui. Mais un bonjour, oui ! Gratuit. Sans timbre.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Pressée ! Toujours ! J'ai quarante lettres dans mon sac, et il est à peine onze heures. Ou midi. Je n'ai pas le temps de regarder.", {}, "rire"), L("Le soir, je pose mon sac et je danse sur la Grand-Place. C'est le seul moment où je ne vole pas. Enfin, je sautille. C'est presque voler.", {"soir": true})],
				"lui": [
					L("Je suis née avec des ailes trop grandes pour moi. Petite, je me prenais dans les rideaux, les portes, les cheminées. Le Capitaine Charbonnel m'a appris à voler contre le vent, sur la jetée. Maintenant, je livre toute la cité en une matinée.", {}),
					L("Mon cousin Zigomar m'a fabriqué un « sac postal à réaction ». Il a pris feu au-dessus du port. J'ai traversé la Rade à reculons, en fumant comme une cheminée. Toutes les lettres sont arrivées. Un peu grillées.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La poste est au Port de Cendre, à côté de la capitainerie. Tout le courrier de l'île passe par mes mains. Et par mes ailes. Je connais toutes les adresses, toutes les portes, et tous les chiens. Surtout les chiens.", {}),
					L("J'ai toujours trop de lettres et pas assez d'ailes ! Si un jour tu veux m'aider à en porter, je ne dirai pas non. Grumbald au Diable Repu, Ombreline à la Bibliothèque, Gorgoth à l'Arène : c'est ma tournée la plus longue, du port à la Haute-Ville, et retour.", {"sujet_min": ["ile", 1]}),
					L("Ébène dit qu'il y a une Tourmente dans les Neuf Cercles, avec des rafales terribles. Conseil de factrice : on n'avance jamais contre une rafale, on attend qu'elle passe et on file entre deux. Et les gargouilles des ruines ? Je les évite. Elles adorent les sacs de courrier.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Madame Hurla crie les nouvelles sur la place avant que j'aie livré les lettres qui les annoncent. Une fois, elle a annoncé son propre anniversaire avant que j'apporte les invitations. Tout le monde est venu. Sans invitation.", {}), L("Mademoiselle Ombreline a mis une pancarte à la bibliothèque : « Ici, on chuchote. Et on ne vole pas. » Je suis sûre que c'est pour moi. Maintenant, j'entre à pied. Mais mes ailes font du bruit.", {}, "rire")],
				"interpelle": [L("Courrier ! … Ah non, pas pour toi. Bonjour quand même !", {"visites_max": 0}, "rire"), L("{surnom} ! Coucou d'en haut !", {"visites_min": 1})],
			}},
		# ================================================================ les Thermes de Soufre et les Jardins de Cendre
		{"id": "brasille", "nom": "Mère Brasille", "titre": "jardinière des Jardins de Cendre", "maison": "porte_brasille", "village": "pandemonia",
			"agenda": [[5, 7, "jardin_massif_1"], [7, 10, ["bois_cueillette", "jardin_massif_2"]], [10, 12, ["jardin_massif_1", "jardin_massif_2"]], [12, 14, "maison"], [14, 18, ["jardin_massif_2", "jardin_massif_1"]], [18, 20, "jardin_massif_1"], [20, 5, "maison"]],
			"azur": {"cheveux": [0.85, 0.85, 0.82], "coiffure": "chignon", "yeux": LUEUR_VERT, "haut": [0.3, 0.35, 0.2], "vieux": true, "taille": 0.9},
			"teinte": [0.74, 0.7, 0.68],
			"demon": {"cornes": {"forme": "courbes", "c": [0.65, 0.6, 0.55], "taille": 0.8}, "queue": {"c": [0.58, 0.54, 0.52], "pointe": "touffe", "long": 0.9}, "lueur": LUEUR_VERT, "tenue": "artisan", "objet": "baton"},
			"humeur_base": 0.25, "traits": {"bavard": 0.7, "humour": 0.55, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"fleur_lune": 2.0, "miel": 1.5, "tisane_brume": 1.5, "champignon_braise": 1.5, "graines": 1.0, "pomme": 1.0}, "deteste": {"flocon_givre": -1.5, "vieille_botte": -1.0},
			"tics": ["Ça pousse, ça pousse.", "La terre sait.", "Tss, ces chiots…", "Patience et eau chaude."],
			"surnoms": [[0, "mon petit"], [25, "mon petit chou"], [50, "ma petite braise"], [75, "mon trésor"], [95, "âme de braise"]],
			"repliques": {
				"accueil": [
					L("Bonjour, mon petit. Fais attention où tu mets les pieds : là, ce sont mes poivriers de cendre, et là, mes roses de soufre. Mère Brasille, jardinière. Ces jardins, je les cultive depuis trois cents ans. Ce sont les seuls jardins du monde qu'on arrose à l'eau chaude.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Tu reviens voir mes fleurs ? Elles t'ont reconnu. Regarde, elles se tournent vers toi. Ou vers le soleil. Les deux, peut-être.", {"visites_min": 2}),
				],
				"humeur": [L("Bonne, tant que les chiots de Flammèche ne viennent pas creuser mes massifs. Ils enterrent des os sous mes bégonias de lave. J'ai déterré onze os ce mois-ci. Et une chaussure.", {}), L("Le soir, je donne à boire aux plantes et je leur dis bonne nuit. Les roses de soufre se ferment toutes seules. Les poivriers, il faut leur chanter quelque chose.", {"soir": true})],
				"lui": [
					L("J'ai deux enfants, des jumeaux : Bulle, aux Thermes, et Vespérine, au marché. L'un rit tout le temps, l'autre presque jamais. Je les ai élevés pareil, pourtant. Enfin, je crois. Peut-être que j'ai un peu plus chatouillé Bulle.", {}, "rire"),
					L("Le matin, quand je vais au jardin, je croise Nox qui rentre se coucher. Il me dit bonne nuit, je lui dis bonjour, et je lui donne un brin de menthe de cendre pour qu'il dorme bien. Ça fait des années. C'est notre petite cérémonie.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les Jardins de Cendre sont au sud de la Basse-Ville, à côté des Thermes de mon fils. La cendre du volcan, c'est la meilleure terre du monde. Tout y pousse : il suffit d'un peu d'eau chaude et de beaucoup de patience.", {}),
					L("Il me manque des fleurs de braise pour mes massifs. Elles ne poussent que sur les pentes du volcan, là où la terre fume. Il en faudrait cinq pour faire un beau massif. Mes vieilles jambes ne grimpent plus là-haut. Les tiennes, peut-être ?", {"sujet_min": ["ile", 1]}),
					L("Certains matins, je vais au Bois de Cendre, au sud-est, cueillir des champignons qui luisent. Le bois est doux, mais il se ressemble partout : les arbres noirs, les feuilles de braise… Le petit Pépin dit que les champignons qui brillent font des chemins. Pour une fois, je crois qu'il a raison.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Cette écervelée de Flammèche laisse ses chiots courir partout. L'un d'eux dort dans mon arrosoir. Je ne l'ai pas chassé. Il ronfle. C'est mignon. Mais ne le dis pas à Flammèche.", {}), L("Mon fils Bulle a ouvert ses Thermes pour que les vieilles cornes comme les miennes se réchauffent. Il me fait payer quand même. Moitié prix. C'est un bon fils. Un peu radin, mais un bon fils.", {}, "rire")],
				"interpelle": [L("Attention à mes fleurs, mon petit !", {"visites_max": 0}), L("{surnom} ! Viens sentir mes roses !", {"visites_min": 1})],
			}},
		{"id": "bulle", "nom": "Bulle", "titre": "maître des Thermes de Soufre", "maison": "porte_bulle", "village": "pandemonia",
			"agenda": [[7, 12, "thermes_comptoir"], [12, 13, "thermes_bain_2"], [13, 21, "thermes_comptoir"], [21, 23, "thermes_bain_1"], [23, 7, "maison"]],
			"azur": {"cheveux": [0.95, 0.6, 0.4], "coiffure": "boucles", "yeux": LUEUR_OR, "haut": [0.95, 0.9, 0.85], "carrure": 1.25},
			"teinte": [0.86, 0.46, 0.44],
			"demon": {"cornes": {"forme": "petites", "c": [0.95, 0.85, 0.8], "taille": 0.7}, "queue": {"c": [0.66, 0.34, 0.32], "pointe": "touffe", "long": 0.8}, "lueur": LUEUR_OR, "tenue": "marchand"},
			"boutique": {"vend": {"cristal_soufre": 8, "cafe_brasier": 4}, "achete": {"coquillage": 1, "etoile_mer": 3}},
			"humeur_base": 0.6, "traits": {"bavard": 0.85, "humour": 0.9, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"chaussettes_vapeur": 2.5, "lave_glacee": 2.0, "canard_mecanique": 2.0, "brioche_braise": 1.5, "etoile_mer": 1.0, "coquillage": 1.0}, "deteste": {"eclat_givre": -2.0, "flocon_givre": -1.5},
			"tics": ["Ho ho ho !", "Plouf !", "Ça mijote !", "Détends-toi !"],
			"repliques": {
				"accueil": [
					L("Ho ho ! Bienvenue aux Thermes de Soufre ! Bulle, maître des bains ! Eau chaude, eau très chaude, et eau « attention-tes-cornes-vont-fondre » ! Tout est naturel : c'est le volcan qui chauffe, moi je fais juste les bulles.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Un petit bain ? Tu as l'air tout raide. Ici, on ressort tout mou. Mou comme une brioche.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Ho ho ! Merveilleuse ! J'ai trouvé une nouvelle source, encore plus chaude. Je l'ai goûtée du bout du doigt. Je ne sens plus le doigt. Mais quelle source !", {}, "rire"), L("Le soir, quand les clients sont partis, je prends mon bain à moi. Rien que moi, les bulles et les étoiles. Et parfois Bobor, qui flotte comme un bouchon.", {"soir": true}, "rire")],
				"lui": [
					L("J'ai une sœur jumelle, Vespérine, l'apothicaire. Elle est née trois minutes avant moi, et elle ne me laisse jamais l'oublier. Elle dit qu'en trois minutes, elle a eu le temps de prendre tout le sérieux de la famille. Moi, j'ai pris le reste. Le meilleur !", {}, "rire"),
					L("Ma mère, Mère Brasille, cultive les Jardins juste à côté. Petit, je faisais des bulles dans son arrosoir. Elle m'appelait « mon petit savon ». Le surnom est resté : Bulle. C'est quand même moins gênant.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Les Thermes de Soufre, au sud de la Basse-Ville : trois bassins, de la vapeur, et la meilleure vue sur le volcan. Le soufre est bon pour la peau, les cornes et le moral. Ma sœur dit que pour le moral, ce n'est pas prouvé. Moi, je l'ai prouvé : regarde-moi !", {}, "rire"),
					L("L'eau des Thermes vient des sources de soufre, hors des murs. Là-bas poussent des cristaux de soufre, jaunes comme des citrons. Zigomar en cherche pour ses fusées. Si tu y vas, ne mets pas le pied dans les bassins qui fument : même moi, je ne m'y baigne pas.", {"sujet_min": ["ile", 1]}),
					L("Tu vas au Styx ? Écoute un spécialiste des bulles : une dalle qui fait des bulles, c'est une dalle qui coule. Les bulles, c'est l'air qui s'échappe par en dessous. Marche sur les dalles tranquilles. Et le Cocyte… brr. Je ne veux même pas en parler. Ça me donne froid aux cornes.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Gorgoth vient se baigner après ses combats. La première fois, il est entré dans le grand bassin, et tous les autres clients sont sortis. Par la vague. Alors je lui ai fait construire son propre bain. Le Bain Gorgoth. Maintenant, tout le monde veut l'essayer.", {}, "rire"), L("Tiburce vient « faire respirer ses cornes » dans ma vapeur, tous les jeudis. Je lui ai dit que les cornes ne respirent pas. Il m'a répondu que les siennes, si. Je ne discute pas avec un client qui paie.", {}, "rire")],
				"interpelle": [L("Ho ho ! Un bain chaud ?", {"visites_max": 0}), L("{surnom} ! Ça mijote, viens !", {"visites_min": 1})],
			}},
		# ================================================================ le quartier des Artisans
		{"id": "tiburce", "nom": "Tiburce", "titre": "polisseur de cornes", "maison": "porte_tiburce", "village": "pandemonia",
			"agenda": [[9, 12, "barbier"], [12, 14, "place_fontaine"], [14, 18, "barbier"], [18, 22, "place_danse_1"], [22, 9, "maison"]],
			"azur": {"cheveux": [0.08, 0.06, 0.1], "coiffure": "queue", "barbe": "moustache", "yeux": LUEUR_VIOLET, "haut": [0.45, 0.1, 0.35], "carrure": 0.9, "taille": 1.04},
			"teinte": [0.48, 0.3, 0.58],
			"demon": {"cornes": {"forme": "droites", "c": OR, "taille": 1.3}, "queue": {"c": [0.36, 0.2, 0.44], "pointe": "fleche", "long": 1.4}, "lueur": LUEUR_VIOLET, "tenue": "noble"},
			"humeur_base": 0.35, "traits": {"bavard": 0.85, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.3},
			"aime": {"perle": 2.5, "rubis": 2.0, "bague": 2.0, "eclat_cristal": 1.5, "plume_furie": 1.5, "lave_glacee": 1.0}, "deteste": {"vieille_botte": -2.0, "fromage_chevre": -1.0},
			"boutique": {"vend": {"huile_cornes": 8}, "achete": {"perle": 11, "corail_rouge": 9}},
			"tics": ["Très cher…", "Divin.", "Quel lustre !", "La beauté, toujours."],
			"repliques": {
				"accueil": [
					L("Oh ! Entre, entre, très cher ! Tiburce, polisseur de cornes. Huile, lustre, limage, et pour les grandes occasions, la feuille d'or. Une corne, c'est une couronne qu'on ne retire jamais : il faut en prendre soin. Tu n'as pas de cornes ? Quel dommage. Quel gâchis.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Toujours pas de cornes ? Je reste optimiste. J'ai une huile qui fait des miracles. Enfin, qui sent très bon.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Divine ! J'ai poli les cornes d'Asmodin ce matin. On pourrait s'y coiffer. Lui a refusé de sourire, mais ses cornes, elles, souriaient.", {}, "rire"), L("Le soir, je vais écouter Calcine jouer sur la Grand-Place. Au premier rang. Les yeux fermés. Je soupire aux bons moments. Enfin, je crois que ce sont les bons moments.", {"soir": true})],
				"lui": [
					L("Petit, j'étais apprenti chez le vieux polisseur de la Haute-Ville. Mon premier client fut Asmodin. Il m'a regardé travailler une heure sans un mot, puis il a dit : « Acceptable. » J'en ai pleuré de joie. Il vient toujours, chaque lundi. Il dit toujours « acceptable ».", {}),
					L("L'huile à cornes, c'est ma recette : de l'huile de braise, un soupçon de cannelle de feu, et un secret. Vespérine dit que le secret, c'est du parfum. C'est faux. C'est beaucoup de parfum.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Mon salon est dans le quartier des Artisans, à l'ouest de la Basse-Ville, entre l'atelier de Grisette et celui de Zigomar. D'un côté, on critique mes cols ; de l'autre, on fait exploser des choses. C'est un quartier très stimulant.", {}, "rire"),
					L("Avant le Tournoi des Cornes, tout le monde vient faire polir ses cornes. C'est mon meilleur mois ! Gorgoth, lui, ne vient jamais. Il dit que ses cornes n'aiment pas l'huile. Des cornes qui n'aiment pas l'huile ! Quelle tristesse.", {"sujet_min": ["ile", 1]}),
					L("On dit qu'au fond des Neuf Cercles, au Cocyte, le froid fait craquer les cornes. Craquer ! Si tu y descends, couvre-toi la tête. Et à ton retour, passe me voir : je n'ai jamais poli de cornes gelées. Ce serait une première.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Grisette dit que mes cols ont trois siècles de retard. Moi, je dis que ses capes cachent les cornes de ses clients, ce qui est un crime. L'an dernier, nous avons fait une tenue ensemble pour la fête. Elle a gagné le prix. Depuis, nous nous parlons. Pour nous critiquer.", {}, "rire"), L("Calcine… Ah, Calcine. Elle joue comme un feu qui danse. Elle m'a dit que mes cornes brillaient plus que ma conversation. J'ai décidé que c'était un compliment.", {})],
				"interpelle": [L("Oh ! Très cher ! Un petit lustre ?", {"visites_max": 0}), L("{surnom} ! Quel plaisir !", {"visites_min": 1}, "salut")],
			}},
		{"id": "zigomar", "nom": "Zigomar", "titre": "inventeur et artificier", "maison": "porte_zigomar", "village": "pandemonia",
			"agenda": [[9, 13, "atelier_inventeur"], [13, 14, "marche_flane_1"], [14, 19, "atelier_inventeur"], [19, 22, "port_phare"], [22, 1, "atelier_inventeur"], [1, 9, "maison"]],
			"azur": {"cheveux": [0.95, 0.95, 0.9], "coiffure": "boucles", "yeux": LUEUR_ORANGE, "haut": [0.45, 0.32, 0.18], "lunettes": true},
			"teinte": [0.82, 0.36, 0.22],
			"demon": {"cornes": {"forme": "courbes", "c": [0.3, 0.22, 0.18], "taille": 0.9}, "queue": {"c": [0.58, 0.24, 0.16], "pointe": "touffe", "long": 0.9}, "lueur": LUEUR_ORANGE, "tenue": "savant"},
			"humeur_base": 0.5, "traits": {"bavard": 0.95, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"montre_envers": 2.5, "lunettes_kaleido": 2.5, "chapeau_ventilateur": 2.0, "coeur_magma": 2.0, "cafe_brasier": 1.5, "minerai_fer": 1.0}, "deteste": {"flocon_givre": -1.0, "vieille_botte": -0.5},
			"boutique": {"vend": {}, "achete": {"cristal_soufre": 10, "coeur_magma": 16, "minerai_fer": 5}},
			"tics": ["Eurêka !", "Boum !", "Fascinant, fascinant !", "Ça devrait marcher !"],
			"repliques": {
				"accueil": [
					L("Attention ! Baisse-toi ! … Non, rien. Fausse alerte. Bonjour ! Zigomar, inventeur, artificier, et ancien propriétaire de deux sourcils. Ici, on invente l'avenir de Pandémonia ! Enfin, l'avenir, et quelques trous dans le plafond.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes à pic ! Tiens ce bidule. Non, pas par là. Par là. Voilà. Ne bouge plus. … Boum. Ha ! Ça marche !", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Les fusées sont prêtes, grâce à tes cristaux de soufre ! Elles n'attendent plus que la Nuit des Lanternes. Et un peu de chance. Beaucoup de chance.", {"a_trouve": "fusees_pretes"}, "rire"), L("Explosive ! Dans le bon sens ! Ma dernière fusée a atteint le haut du phare. Enfin, le haut du phare a atteint ma fusée. On ne sait pas trop.", {}, "rire"), L("Le soir, je teste mes fusées sur la jetée, près du phare. Le Capitaine Charbonnel dit que je fais peur aux poissons. Les poissons ne m'ont jamais rien dit.", {"soir": true}, "rire")],
				"lui": [
					L("Petit, j'ai démonté le réveil de mon père pour voir où était caché le temps. Je ne l'ai pas trouvé. J'ai remonté le réveil : il sonnait toutes les sept minutes. Mon père dit que c'est ma meilleure invention. Il n'a plus jamais été en retard.", {}, "rire"),
					L("Ma cousine Brindille distribue le courrier. Je lui ai inventé un sac postal à réaction. Il a fonctionné ! Trop bien. Elle a traversé le port à reculons. Elle dit qu'elle me pardonne. Elle ne veut plus que je lui invente quoi que ce soit.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mademoiselle Sulfura… Ah. Je lui envoie des fusées en forme de cœur. La dernière a explosé en forme de rognon. Elle a ri. Elle a ri ! C'est un début, non ?", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon atelier est chez les Artisans, à l'ouest de la Basse-Ville. Tu le trouveras facilement : c'est celui qui n'a plus de toit. Enfin, il en a un. Il est juste un peu plus loin que prévu.", {}, "rire"),
					L("Pour la Nuit des Lanternes, je prépare le plus grand feu d'artifice de l'histoire de l'île ! Il me manque trois cristaux de soufre, des sources de soufre, hors des murs. Jaunes, brillants, ça sent l'œuf pourri : tu ne peux pas te tromper. Je te les achète, et je te garde une place au premier rang !", {"sujet_min": ["ile", 1]}),
					L("Dans les Neuf Cercles, à Malebolge, il paraît que des ponts tournent sur eux-mêmes. Des ponts tournants ! Quel mécanisme magnifique ! Observe le rythme, compte les tours, et passe quand ils s'alignent. Tout mécanisme a un rythme. Même moi. Surtout moi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Asmodin ne m'a jamais pardonné la fusée du dîner des ambassadeurs. Pourtant, elle a parfaitement fonctionné ! Elle est juste entrée par la mauvaise fenêtre. Et dans la mauvaise soupe.", {}, "rire"), L("La petite Ortie veut être mon apprentie. Elle a inventé une machine qui ramasse les boulons. La machine a mangé mon balai. J'ai été très impressionné. Et un peu inquiet pour mes chaussures.", {}, "rire")],
				"interpelle": [L("Attention ! … Non, ça va. Bonjour !", {"visites_max": 0}, "rire"), L("{surnom} ! Eurêka ! Viens voir !", {"visites_min": 1})],
			}},
		{"id": "grisette", "nom": "Grisette", "titre": "couturière", "maison": "porte_grisette", "village": "pandemonia",
			"agenda": [[8, 12, "atelier_couture"], [12, 13, "thermes_bain_1"], [13, 18, "atelier_couture"], [18, 20, "place_banc_2"], [20, 8, "maison"]],
			"azur": {"cheveux": [0.82, 0.82, 0.86], "coiffure": "chignon", "yeux": LUEUR_VIOLET, "haut": [0.2, 0.2, 0.22]},
			"teinte": [0.72, 0.72, 0.74],
			"demon": {"cornes": {"forme": "courbes", "c": [0.78, 0.78, 0.8], "taille": 0.8}, "queue": {"c": [0.55, 0.55, 0.58], "pointe": "fleche", "long": 1.1}, "lueur": LUEUR_VIOLET, "tenue": "artisan"},
			"humeur_base": 0.2, "traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.6, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"plume_furie": 2.5, "perle": 2.0, "plume_ara": 2.0, "plume_corbeau": 1.5, "eclat_cristal": 1.5, "chouette_plume": 1.0}, "deteste": {"vieille_botte": -1.5, "huile_cornes": -0.5},
			"tics": ["Un point, deux points…", "Quelle étoffe !", "Tiens-toi droit.", "Cousu main."],
			"repliques": {
				"accueil": [
					L("Ne bouge pas. … Voilà. Tu as des épaules de voyageur, et tu te tiens mal. Bonjour. Grisette, couturière. J'habille l'Archiduchesse, le champion de l'Arène, la violoniste de la place, et quiconque veut cesser de ressembler à un sac de charbon.", {"visites_max": 1}),
					L("{surnom}. Toujours cette tenue ? Je ne dis rien. Je regarde. Ça suffit.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Appliquée. J'ai trois robes de bal, une cape de champion et quarante mouchoirs brodés à finir avant la fête. Et Tiburce qui passe toutes les heures critiquer mes ourlets.", {}), L("Le soir, je m'assois sur un banc de la place et je regarde passer les gens. Pas pour les gens : pour ce qu'ils portent. On apprend beaucoup en regardant les manches.", {"soir": true})],
				"lui": [
					L("Je suis née grise. Peau couleur de cendre, cheveux couleur de cendre, cornes couleur d'argent. Ma mère disait : « Une couleur pareille, c'est une toile blanche. Habille-la. » Alors j'ai appris à habiller tout le monde. Sauf moi : je porte toujours du gris. Ça me repose.", {}),
					L("Pour mesurer Gorgoth, j'ai besoin d'une échelle. Il se tient immobile, il retient sa respiration, et il chuchote « pardon » chaque fois qu'il respire. C'est le client le plus poli que j'aie jamais eu. Et le plus long à coudre : six mètres de cape.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Mon atelier est chez les Artisans, à l'ouest de la Basse-Ville, entre Tiburce, qui sent le parfum, et Zigomar, qui sent la poudre. Mes tissus sentent les deux. Les clients pensent que c'est voulu.", {}, "rire"),
					L("Pour la Nuit des Lanternes, toute la cité s'habille. Je couds des robes à paillettes de braise, qui brillent quand on danse. Si tu viens danser sur la Grand-Place, passe me voir avant. Je ne te laisserai pas y aller dans cette tenue.", {"sujet_min": ["ile", 1]}),
					L("La porte des Neuf Cercles dit « prenez un manteau ». Je prends cette phrase très au sérieux. Au fond, au Cocyte, le froid est si vif qu'il gèle les ourlets. Mets plusieurs couches. Une couche, c'est de l'élégance. Trois couches, c'est de la sagesse.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Ce paon de Tiburce passe devant mon atelier dix fois par jour pour me montrer son nouveau col. Il a le même col depuis trois siècles. Il le repasse différemment, c'est tout.", {}), L("L'Archiduchesse veut des robes simples, avec des poches. Des poches ! Pour y mettre des marrons grillés ! Je lui fais des robes magnifiques. Avec des poches cachées. Personne ne doit le savoir.", {}, "rire")],
				"interpelle": [L("Toi. Tiens-toi droit.", {"visites_max": 0}), L("{surnom}. Viens, que je regarde cette manche.", {"visites_min": 1})],
			}},
		{"id": "flammeche", "nom": "Flammèche", "titre": "gardienne du chenil des chiots d'enfer", "maison": "porte_flammeche", "village": "pandemonia",
			"agenda": [[6, 8, "port_quai_2"], [8, 18, "chenil"], [18, 20, "rue_6", ["rue_5", "jardin_massif_2"]], [20, 6, "maison"]],
			"azur": {"cheveux": [0.95, 0.5, 0.15], "coiffure": "queue", "yeux": LUEUR_ROUGE, "haut": [0.35, 0.25, 0.15]},
			"teinte": [0.82, 0.24, 0.2],
			"demon": {"cornes": {"forme": "petites", "c": [0.5, 0.2, 0.12], "taille": 0.8}, "queue": {"c": [0.6, 0.18, 0.14], "pointe": "touffe", "long": 1.0}, "lueur": LUEUR_ROUGE, "tenue": "artisan"},
			"humeur_base": 0.45, "traits": {"bavard": 0.85, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"os_jaguar": 2.5, "merou": 2.0, "sardine": 1.5, "brochette_poisson": 1.5, "canard_mecanique": 1.0}, "deteste": {"croc_cerbere": -2.0, "flocon_givre": -0.5},
			"tics": ["Assis ! … Pas toi.", "Bon chien !", "Ouaf.", "Qui c'est le plus beau ?"],
			"repliques": {
				"accueil": [
					L("Attention, ils mordillent ! Mais gentiment ! Flammèche, gardienne du chenil. J'élève douze chiots d'enfer : Braise, Tison, Suie, Fumerolle, Pétard, Charbon, Escarbille, Flambard, Mèche, Cendre, Biscotte et Grignotte. Oui, ils crachent un peu de feu. Comme tous les bébés.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Biscotte t'a reconnu ! Regarde, il remue la queue. Et il a roussi ta chaussure. C'est sa façon de dire bonjour.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Les chiens sauvages ont reculé dans le champ de lave. Je leur porterai des os quand même. Un chien qui recule, c'est un chien qui réfléchit. C'est déjà un début.", {"a_trouve": "chiens_champ"}), L("Débordée ! Pétard a avalé une chaussette, Suie a peur de son ombre, et Grignotte a mangé la porte. La porte !", {}, "rire"), L("Le soir, je promène les chiots dans les rues. Ils aboient aux réverbères. Nox leur dit bonsoir. Ils l'adorent : il sent la mèche.", {"soir": true})],
				"lui": [
					L("Mon grand frère, c'est le capitaine Pyrus. Il voulait que je sois garde, comme lui. Moi, j'ai toujours ramené à la maison tout ce qui avait quatre pattes et un museau. Un jour, j'ai ramené un chiot d'enfer abandonné. Puis deux. Puis douze. Pyrus a cédé.", {}),
					L("Chaque matin, Gorgoth garde les chiots pendant que je vais chercher les restes de poisson chez Moloka. Ils grimpent sur lui comme sur une montagne. Il ne bouge pas d'un poil, pour ne pas les faire tomber. Le plus grand champion de l'île. La plus gentille des montagnes.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le chenil est chez les Artisans, à l'ouest de la Basse-Ville. Avant, j'étais à côté des Jardins de Cendre, mais mes chiots creusaient les massifs de Mère Brasille. Elle m'a… gentiment… demandé de déménager. Avec un balai.", {}, "rire"),
					L("Les chiens d'enfer sauvages du champ de lave, à l'est du volcan, ne sont pas méchants : ils sont mal élevés, c'est tout ! Ils bondissent, ils soufflent du feu, et ils ont faim. Mon frère dit qu'il faut les repousser. Moi, je dis qu'il faut les comprendre. Méfie-toi quand même : ils mordent fort.", {"sujet_min": ["ile", 1]}),
					L("Cerbère, le grand chien à trois têtes des Neuf Cercles… le pauvre. Trois têtes, trois appétits, trois humeurs. Chacune veut son gâteau, pas celui de la voisine ! Donne un gâteau de miel à chaque tête, et elles seront sages. Après tout, c'est un chien.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Mère Brasille dit qu'elle déteste mes chiots. Pourtant, Suie dort dans son arrosoir tous les après-midi, et elle ne le chasse jamais. Je l'ai vue lui chanter une berceuse. Elle a nié. Elle a rougi. Sur une peau de cendre, ça se voit beaucoup.", {}, "rire"), L("Le petit Pépin veut un chiot. Je lui ai dit : quand tu connaîtras leurs douze noms. Il les a appris en une journée. Alors je lui ai dit : et leurs douze anniversaires. Il y travaille.", {}, "rire")],
				"interpelle": [L("Attention, chiots en liberté !", {"visites_max": 0}), L("{surnom} ! Viens leur dire bonjour !", {"visites_min": 1})],
			}},
	]

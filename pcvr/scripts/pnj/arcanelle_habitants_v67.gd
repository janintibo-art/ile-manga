extends RefCounted
## V67 : les gens d'Arcanelle, l'île des sorciers. Une petite communauté autour de l'Académie :
## l'archimage, les maîtres qui enseignent chacun un sort (la lumière, le feu, le gel, la
## lévitation, la télékinésie, le soin), les apprentis, l'alchimiste, l'aubergiste du Chaudron
## Fumant, la gardienne du Cercle des Pierres-Lunes, le passeur, la voyante du Bois Tors.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd ; postures et tenues de sorcier en plus : pnj_arcanelle_v67.gd).
## Lieux : arcanelle_bourg_v67.gd (spots). Fiche « arc » : chapeau pointu, cape, robe, bâton.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Que les étoiles éclairent ta route, {surnom} !", "si": {}, "geste": "salut"},
		{"t": "À bientôt. Et ne touche à rien qui fume.", "si": {}},
		{"t": "Va. Et si tu vois un balai voler tout seul, ne le suis pas.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit. Le Grand Cristal veille sur nous.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! On ne frappe pas un sorcier, {surnom}. Il a de la mémoire. Et des crapauds.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Recommence, et je te change en navet. Un petit navet.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Un cadeau ? Merci ! Je vais voir s'il est magique. … Non. Mais il est gentil.", "si": {}},
		{"t": "Oh, merci. Je le poserai sur ma table de chevet, à côté de mon crâne de corbeau.", "si": {}, "geste": "rire"},
	],
	"cadeau_refus": [{"t": "Une arme ? Range ça. Ici, on se bat avec des mots. Et parfois avec des boules de feu, mais seulement le mardi.", "si": {}}],
	"blague": [
		{"t": "Pourquoi les sorciers portent-ils des chapeaux pointus ? Pour que les idées sortent par le haut !", "si": {}, "geste": "rire"},
		{"t": "Un apprenti demande à l'archimage : « Maître, comment devient-on sage ? » « En faisant des bêtises. » « Et comment fait-on des bêtises ? » « Demande à Oscar. »", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un sorcier qui a raté son sort de lévitation ? Un sorcier par terre.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Approche, approche… Tout est garanti magique, sauf ce qui ne l'est pas. Tu as {pieces} pièces.", "si": {}}],
	"achat": [{"t": "{objet}, {prix} pièces. À boire avec modération, et jamais avant de voler.", "si": {}, "geste": "salut"}],
	"marchande_non": [{"t": "Marchander ? Mon prix a été calculé à la lumière de la lune. On ne discute pas avec la lune.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par les étoiles !", "Fiat lux !", "Merveilleux !", "Ah, magnifique !"],
		"neutre": ["Hmm.", "Voyons…", "Bien.", "Eh bien…"],
		"triste": ["Ah…", "Hélas.", "Que la lune me pardonne…", "Pff."],
		"colere": ["Sapristi !", "Par ma barbe… ou celle d'un autre !", "Ça suffit.", "Écoute-moi bien."],
	},
	"tics": ["Par les étoiles.", "Comme dit l'archimage.", "Magiquement parlant.", "Fiat lux."],
	"humeur_mots": [[0.6, "inspiré"], [0.25, "de bonne humeur"], [-0.25, "songeur"], [-0.6, "contrarié"], [-2.0, "orageux"]],
	"surnoms": [[0, "voyageur"], [25, "apprenti"], [50, "jeune mage"], [75, "mage"], [95, "enchanteur"]],
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
	out["groupe"] = "arcanelle"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ l'Académie
		{"id": "archimage", "nom": "Séraphine Astrelune", "titre": "archimage d'Arcanelle", "maison": "porte_tour",
			"agenda": [[7, 8, "cour_cristal"], [8, 12, "cour_pupitre"], [12, 13, "chaudron_table_1"], [13, 17, ["cour_pupitre", "salle_pupitre"]], [17, 19, "cour_cristal"], [19, 22, "cercle_autel"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.86, 0.86, 0.9], "coiffure": "long", "yeux": [0.35, 0.5, 0.7], "vieux": true, "haut": [0.2, 0.18, 0.4]},
			"arc": {"robe": [0.16, 0.14, 0.36], "cape": [0.42, 0.36, 0.72], "chapeau": [0.2, 0.18, 0.42], "baton": true, "etoiles": true},
			"teinte": PEAU[5], "humeur_base": 0.35, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"eclat_lune": 2.5, "grimoire": 2.0, "the_menthe": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Bienvenue à Arcanelle, voyageur. Je suis Séraphine Astrelune, l'archimage. Le Grand Cristal m'avait dit qu'un visiteur viendrait par la mer. Il ne m'avait pas dit que tu aurais l'air si… curieux. C'est bon signe.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Le Cristal a frémi quand tu as passé la porte. Il t'aime bien, je crois.", {"visites_min": 2}),
				],
				"humeur": [L("Sereine. Les étoiles sont à leur place, les apprentis presque.", {}), L("Le soir, je monte au Cercle écouter les Pierres-Lunes. Elles parlent lentement. Il faut être patient.", {"soir": true})],
				"lui": [
					L("J'enseigne ici depuis quarante ans. J'ai vu passer des centaines d'apprentis. Certains sont devenus des mages, d'autres des pâtissiers. Les deux font des merveilles.", {}),
					L("La magie, ce n'est pas un pouvoir, c'est une écoute. Le feu, la glace, le vent, la lumière : tout parle. Un sorcier, c'est quelqu'un qui a appris à répondre poliment.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Arcanelle n'est sur aucune carte des marchands. Les brumes la cachent aux curieux. Si tu es là, c'est qu'elle a voulu que tu viennes.", {}),
					L("Chaque maître enseigne un sort : Aurélien la lumière, Pyra le feu, Borée le gel, Zéphyrine la lévitation, Théophraste la télékinésie, Mère Sauge le soin. Apprends les six, et je te remettrai ton bâton au Cercle.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [L("Oscar a encore transformé son chapeau en pigeon. Le pigeon a refusé de redevenir chapeau. On l'a appelé Gérard.", {}, "rire"), L("Borée et Pyra ne se parlent plus depuis l'hiver où elle a fait fondre son lac pour prendre un bain. Ils finiront par se réconcilier. Dans cent ans.", {})],
				"interpelle": [L("Voyageur ! Approche, n'aie pas peur des chapeaux.", {"visites_max": 0}), L("{surnom} ! Le Cristal t'attendait.", {"visites_min": 1})],
			}},
		{"id": "lumen", "nom": "Aurélien Lumen", "titre": "maître de la lumière, astronome", "maison": "porte_observatoire",
			"agenda": [[10, 12, "obs_carte"], [12, 13, "chaudron_bar_1"], [13, 17, ["bib_table_1", "crypte_porte"]], [17, 19, "obs_carte"], [19, 2, "obs_lunette"], [2, 10, "maison"]],
			"azur": {"cheveux": [0.82, 0.62, 0.3], "coiffure": "boucles", "barbe": "courte", "lunettes": true, "yeux": [0.4, 0.5, 0.3], "haut": [0.85, 0.72, 0.35]},
			"arc": {"robe": [0.75, 0.6, 0.25], "cape": [0.2, 0.22, 0.42], "chapeau": [0.22, 0.24, 0.46], "etoiles": true},
			"teinte": PEAU[0], "humeur_base": 0.3, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"eclat_lune": 3.0, "lentille_phare": 2.0, "boussole": 1.5}, "deteste": {"sifflet_muet": -0.5},
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Aurélien Lumen, maître de la lumière, astronome, et accessoirement le seul ici qui dort le jour. Vous avez vu le ciel, cette nuit ? Non ? Quel dommage. Il était magnifique.", {"visites_max": 1}, "salut"),
					L("Ah, vous ! Vous tombez à pic : j'ai trouvé une nouvelle étoile. Enfin, c'était une luciole. Mais elle brillait bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Ébloui ! Comme toujours.", {}, "rire"), L("La nuit tombe, mes étoiles se lèvent. Je suis l'homme le plus heureux d'Arcanelle.", {"soir": true})],
				"lui": [
					L("La lumière, c'est le premier sort qu'on apprend et le dernier qu'on maîtrise. Une petite flamme dans la main, et soudain le noir n'est plus le même noir.", {}),
					L("Mon observatoire, c'est mon grand-père qui l'a bâti. Il disait que les étoiles sont des sorciers qui ont réussi leur sort de lumière. Je n'ai jamais osé le contredire.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [L("Sous la colline, il y a la Crypte aux Runes. Il y fait noir comme dans un encrier. Les runes du fond ne se montrent qu'à une lumière née de la main d'un sorcier.", {}), L("Les éclats de lune ? Des morceaux de lumière qui tombent sur l'île les nuits claires. Ils restent là où ils tombent, et brillent doucement.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Théophraste dit qu'un de ses livres s'est envolé jusque sur le toit de la bibliothèque. Les livres de Théophraste ont de l'imagination.", {}, "rire"), L("Agathe, la voyante, m'a prédit une grande découverte. Le lendemain, j'ai trouvé mes lunettes. Elles étaient sur mon nez.", {})],
				"interpelle": [L("Vous avez vu la lune ?", {"visites_max": 0}), L("{surnom} ! Regardez là-haut !", {"visites_min": 1})],
			}},
		{"id": "pyra", "nom": "Pyra Flammèche", "titre": "maîtresse du feu", "maison": "porte_pyra",
			"agenda": [[7, 12, "aire_centre"], [12, 13, "chaudron_table_2"], [13, 18, ["aire_centre", "aire_braseros"]], [18, 22, ["chaudron_bar_2", "place_fontaine_1"]], [22, 7, "maison"]],
			"azur": {"cheveux": [0.75, 0.2, 0.08], "coiffure": "queue", "yeux": [0.45, 0.3, 0.12], "haut": [0.6, 0.12, 0.08], "carrure": 1.05},
			"arc": {"robe": [0.55, 0.1, 0.06], "cape": [0.85, 0.42, 0.08], "chapeau": [0.45, 0.08, 0.05]},
			"teinte": PEAU[1], "humeur_base": 0.2, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.4},
			"aime": {"rhum_murene": 2.0, "coeur_magma": 3.0, "obsidienne": 2.0}, "deteste": {"flocon_givre": -1.5},
			"repliques": {
				"accueil": [
					L("Hé, toi ! Pyra Flammèche, maîtresse du feu. Tu veux apprendre à lancer des boules de feu ? Tout le monde veut. Personne ne veut apprendre à les éteindre.", {"visites_max": 1}, "salut"),
					L("Te revoilà ! Approche, je ne mords pas. Je brûle un peu, c'est tout.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("En feu ! Comme d'habitude.", {}, "rire"), L("Fatiguée. Trois apprentis ont roussi leurs sourcils aujourd'hui. Un record.", {"soir": true})],
				"lui": [L("Je suis née pendant un orage. La foudre est tombée sur la cheminée de ma mère. Le feu ne s'est jamais éteint, et moi non plus.", {}), L("Le feu, il faut le respecter. Il est généreux, il réchauffe, il cuit la soupe. Mais si tu lui tournes le dos, il dévore tout. Un peu comme Berthe quand on critique sa tarte.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("L'Aire des Duels, c'est mon royaume. Cinq braseros tout autour : un apprenti qui les allume tous les cinq d'affilée a compris le feu.", {}), L("Les bûches du Bois Tors brûlent longtemps et sans fumée. Le bois tordu a de la patience, il la rend en chaleur.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Borée prétend que la glace est plus élégante que le feu. La glace, ça fond. Je dis ça, je ne dis rien.", {}), L("Mathurin le passeur a vu un serpent de mer près de la côte. Après trois verres d'hydromel. Il en voit tous les soirs, des serpents.", {}, "rire")],
				"interpelle": [L("Toi ! Tu veux voir du feu ?", {"visites_max": 0}), L("{surnom} ! Viens chauffer tes mains !", {"visites_min": 1})],
			}},
		{"id": "boree", "nom": "Borée Givrelin", "titre": "maître du gel", "maison": "porte_boree",
			"agenda": [[6, 12, "lac_rive"], [12, 14, "maison_boree_banc"], [14, 19, "lac_rive"], [19, 21, "chaudron_table_3"], [21, 6, "maison"]],
			"azur": {"cheveux": [0.94, 0.95, 0.97], "coiffure": "long", "barbe": "longue", "yeux": [0.6, 0.75, 0.85], "vieux": true, "haut": [0.7, 0.8, 0.9], "taille": 1.05},
			"arc": {"robe": [0.62, 0.72, 0.86], "cape": [0.9, 0.93, 0.98], "chapeau": [0.55, 0.66, 0.82], "baton": true},
			"teinte": PEAU[5], "humeur_base": -0.05, "traits": {"bavard": 0.3, "humour": 0.3, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.6},
			"aime": {"flocon_givre": 3.0, "the_menthe": 1.5, "perle": 1.5}, "deteste": {"rhum_murene": -1.0},
			"repliques": {
				"accueil": [
					L("Hm. Borée Givrelin. Maître du gel. Parlez doucement : le lac écoute, et il n'aime pas qu'on crie.", {"visites_max": 1}),
					L("Encore vous. Bien. Le froid aime les gens qui reviennent. Il les attend.", {"visites_min": 2}),
				],
				"humeur": [L("Calme. Comme un lac en janvier.", {}), L("Le soir, le lac devient un miroir. Je regarde la lune s'y poser. Je ne m'en lasse pas depuis soixante ans.", {"soir": true})],
				"lui": [L("Je viens des glaciers du grand nord, au-delà des cartes. Là-bas, on apprend le gel avant de marcher. Ici, j'enseigne aux jeunes à ne pas avoir peur du froid.", {}), L("Le gel, ce n'est pas la colère. C'est la patience. L'eau ne se fige pas parce qu'on le lui ordonne : elle se fige parce qu'on lui a laissé le temps d'y penser.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Sur l'îlot du Lac Miroir dort le Cristal de Givre. Personne n'y va à la nage : l'eau est trop froide, et le lac ne veut pas. Il faut lui demander de durcir sous ses pas.", {}), L("Les flocons de givre éternel tombent sur les falaises du nord, là où le vent ne s'arrête jamais. Ils ne fondent pas. Même dans la main de Pyra. Surtout dans la main de Pyra.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Pyra a fait fondre mon lac, un hiver, pour prendre un bain chaud. Je ne lui ai pas pardonné. Le lac non plus.", {}), L("Zéphyrine dit que le vent du nord lui a parlé. Le vent du nord ne parle pas. Il siffle. C'est différent.", {})],
				"interpelle": [L("Doucement, près du lac.", {"visites_max": 0}), L("{surnom}. Le lac vous salue.", {"visites_min": 1})],
			}},
		{"id": "zephyrine", "nom": "Zéphyrine Plume", "titre": "maîtresse de l'air et de la lévitation", "maison": "porte_zephyrine",
			"agenda": [[8, 12, "tour_pied"], [12, 13, "jardin_banc"], [13, 18, ["tour_pied", "falaise_vent"]], [18, 21, "place_fontaine_2"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.95, 0.88, 0.62], "coiffure": "tresse", "yeux": [0.4, 0.6, 0.75], "haut": [0.85, 0.92, 0.95], "taille": 0.96},
			"arc": {"robe": [0.7, 0.85, 0.92], "cape": [0.95, 0.95, 0.98], "chapeau": [0.45, 0.65, 0.8]},
			"teinte": PEAU[0], "humeur_base": 0.5, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"plume_vent": 3.0, "cerf_volant": 2.5, "plume_lune": 2.0}, "deteste": {"caillou": -0.5},
			"repliques": {
				"accueil": [
					L("Oh ! Un visiteur ! Bonjour, bonjour ! Zéphyrine Plume, maîtresse de l'air. Tu sens ce petit vent ? C'est moi qui l'ai invité. Il reste pour le goûter.", {"visites_max": 1}, "salut"),
					L("Te revoilà, {surnom} ! Le vent m'avait prévenue. Il est bavard, le vent.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Légère ! Comme une plume.", {}, "rire"), L("Le soir, le vent se couche. Moi aussi. On se dit bonne nuit.", {"soir": true})],
				"lui": [L("Petite, je sautais du grenier avec un parapluie. Ma mère criait. Le parapluie aussi. Un jour, je suis restée en l'air. Ma mère a arrêté de crier.", {}, "rire"), L("Léviter, ce n'est pas lutter contre la terre. C'est lui demander poliment de te lâcher un moment. Elle dit presque toujours oui.", {"sujet_min": ["lui", 1]})],
				"ile": [L("La Tour Penchée, là-bas, c'était la tour des vents. Elle penche depuis la grande tempête. Sa cloche est toujours là-haut, mais l'escalier s'est effondré. Il n'y a plus qu'une façon d'y monter…", {}), L("Les plumes du vent ? Le vent en perd quand il tourne trop vite. Elles se posent là où il souffle le plus fort : sur les hauteurs, au bord des falaises.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Borée et moi, on n'est pas d'accord sur le vent du nord. Il dit qu'il siffle. Moi je dis qu'il chante. Faux, mais il chante.", {}, "rire"), L("Pip essaie de léviter en sautant du dortoir avec un drap. Il faudra que je lui parle avant qu'il ne parle au sol.", {})],
				"interpelle": [L("Coucou ! Tu sens le vent ?", {"visites_max": 0}), L("{surnom} ! Hop, hop, viens !", {"visites_min": 1})],
			}},
		{"id": "theophraste", "nom": "Théophraste Filandre", "titre": "bibliothécaire, maître de la télékinésie", "maison": "porte_bibliotheque",
			"agenda": [[8, 19, "bib_bureau"], [19, 21, "chaudron_table_4"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.7, 0.68, 0.64], "coiffure": "chauve", "barbe": "moustache", "lunettes": true, "yeux": [0.3, 0.3, 0.25], "vieux": true, "haut": [0.36, 0.26, 0.2], "taille": 0.94},
			"arc": {"robe": [0.34, 0.24, 0.18], "cape": [0.24, 0.2, 0.3], "chapeau": [0.3, 0.24, 0.2]},
			"teinte": PEAU[1], "humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"grimoire": 3.0, "livre_envole": 2.0, "carte_postale": 1.0}, "deteste": {"jarre_eau": -1.0},
			"repliques": {
				"accueil": [
					L("Chut. … Ah, un nouveau. Bienvenue à la bibliothèque. Théophraste Filandre. Ici, on parle bas, on marche doucement, et on ne corne pas les pages. Les livres se souviennent de qui les corne.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Vous avez lu quelque chose, depuis la dernière fois ? Non ? Il n'est jamais trop tard.", {"visites_min": 2}),
				],
				"humeur": [L("Tranquille. Les livres sont bien rangés. Presque tous.", {}), L("Fatigué. J'ai passé la journée à rattraper des livres qui voulaient sortir.", {"soir": true})],
				"lui": [L("J'ai appris la télékinésie pour attraper les livres en haut des étagères sans échelle. J'avais peur des échelles. Je n'ai plus peur des échelles. Je n'en ai plus besoin.", {}), L("Un livre, c'est un sorcier qui a gardé sa voix pour plus tard. Quand vous l'ouvrez, il recommence à parler. C'est la plus vieille magie du monde.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Arcanelle a la plus vieille bibliothèque de l'archipel. Trois mille volumes. Deux mille neuf cent quatre-vingt-seize, depuis le grand coup de vent.", {}), L("Quatre de mes livres se sont envolés pendant la tempête. Je les vois encore, coincés là où personne ne peut monter. Ils font semblant de ne pas m'entendre.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Lin lit plus vite que moi. Je l'ai chronométrée. Je n'en ai parlé à personne. Sauf à vous. Ne le répétez pas.", {}), L("Gustave m'a emprunté le traité des mélanges explosifs il y a six ans. Il dit qu'il l'a « presque fini ».", {}),
					L("Un de mes plus vieux livres parle d'une île, loin à l'ouest, au-delà de l'île des nains : l'Île des Trois Soleils. Trois peuples y vivent, chacun sous son soleil, avec des pyramides, des sphinx, des serpents à plumes. Je donnerais ma barbe pour la voir. Enfin, une partie de ma barbe.", {"pas_trouve": "soleils"})],
				"interpelle": [L("Chut…", {"visites_max": 0}), L("{surnom}. Doucement.", {"visites_min": 1})],
			}},
		{"id": "sauge", "nom": "Mère Sauge", "titre": "herboriste, maîtresse du soin", "maison": "porte_sauge",
			"agenda": [[6, 12, "jardin_serre"], [12, 14, "maison_sauge_banc"], [14, 18, ["jardin_carres", "jardin_ruches"]], [18, 21, "maison_sauge_banc"], [21, 6, "maison"]],
			"azur": {"cheveux": [0.78, 0.76, 0.72], "coiffure": "chignon", "yeux": [0.35, 0.45, 0.3], "vieux": true, "haut": [0.45, 0.55, 0.38], "tablier": [0.55, 0.45, 0.3], "taille": 0.92, "carrure": 1.08},
			"arc": {"robe": [0.32, 0.42, 0.26], "cape": [0.52, 0.42, 0.28], "chapeau": [0.3, 0.38, 0.24]},
			"teinte": PEAU[0], "humeur_base": 0.45, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"miel": 3.0, "champignon": 2.0, "baies": 1.5}, "deteste": {"poisson_lune": -0.5},
			"repliques": {
				"accueil": [
					L("Bonjour, mon petit. Mère Sauge. Tu as une petite mine, toi. Tu manges assez ? Tiens, mâche cette feuille de menthe. C'est bon pour tout, sauf pour le hoquet.", {"visites_max": 1}, "salut"),
					L("Te revoilà, mon petit ! Montre-moi tes mains… Encore des égratignures. Les jeunes, ça court partout.", {"visites_min": 2}),
				],
				"humeur": [L("Contente. Mes abeilles chantent, mes simples poussent.", {}), L("Le soir, je fais sécher mes herbes au-dessus du feu. Toute la maison sent la lavande et le thym.", {"soir": true})],
				"lui": [L("Soigner, c'est la magie la plus simple et la plus difficile. Il faut écouter le corps comme on écoute une vieille amie qui se plaint : sans l'interrompre.", {}), L("J'ai soigné tout le monde, ici. Les brûlures de Pyra, les engelures de Borée, les bosses d'Oscar. Surtout les bosses d'Oscar.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Dans le Bois Tors poussent les meilleurs champignons de l'île. Il faut savoir lesquels : certains soignent, d'autres font chanter faux pendant trois jours.", {}), L("Une chouette s'est blessée l'aile dans le Bois Tors. Elle ne se laisse approcher par personne. Il faudrait des mains douces, et un sort plus doux encore.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Berthe met trop de sel dans sa soupe. Je le lui dis depuis vingt ans. Elle me répond que j'ai trop de miel dans ma tisane. Elle n'a pas tort.", {}, "rire"), L("Agathe m'a lu l'avenir dans le thé. Elle a vu « une longue vie et beaucoup de tisane ». Ça, je le savais.", {})],
				"interpelle": [L("Mon petit ! Viens par ici.", {"visites_max": 0}), L("{surnom} ! Tu as bien mangé ?", {"visites_min": 1})],
			}},
		# ================================================================ le bourg
		{"id": "gustave", "nom": "Gustave Fiole", "titre": "alchimiste de L'Alambic", "maison": "porte_alambic",
			"agenda": [[8, 19, "alambic_comptoir"], [19, 22, "chaudron_bar_3"], [22, 8, "maison"]],
			"azur": {"cheveux": [0.32, 0.22, 0.14], "coiffure": "boucles", "barbe": "moustache", "lunettes": true, "yeux": [0.3, 0.35, 0.2], "haut": [0.55, 0.3, 0.45], "tablier": [0.35, 0.25, 0.18], "carrure": 1.15},
			"arc": {"robe": [0.42, 0.18, 0.36], "chapeau": [0.3, 0.12, 0.26]},
			"teinte": PEAU[2], "humeur_base": 0.3, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"champignon_lune": 2.5, "poussiere_fee": 2.5, "goutte_rosee": 2.0}, "deteste": {"vieille_botte": -0.5},
			"boutique": {"vend": {"potion_mana": 8, "elixir_etoile": 15, "potion_seve": 9}, "achete": {"champignon": 2, "baies": 1, "miel": 4, "eclat_cristal": 8, "poussiere_fee": 6}},
			"repliques": {
				"accueil": [
					L("Bienvenue à L'Alambic ! Gustave Fiole, alchimiste diplômé, presque jamais explosé. Potions de magie, élixirs d'étoile, sirops contre la timidité… Le sirop contre la timidité est en rupture. Personne n'ose en demander.", {"visites_max": 1}, "salut"),
					L("Ah, un habitué ! J'ai une nouvelle potion. Elle est bleue. Je ne sais pas encore ce qu'elle fait. Vous voulez essayer ? Non ? Sage.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Pétillant ! Comme mes élixirs.", {}, "rire"), L("Le soir, je goûte les potions du jour. Pour vérifier. C'est pour ça que je chante en rentrant.", {"soir": true}, "rire")],
				"lui": [L("La potion de magie, c'est ma fierté : de la rosée de lune, trois gouttes de miel, et une pensée gentille au moment de remuer. Sans la pensée gentille, ça goûte le chou.", {}), L("Je suis alchimiste depuis que j'ai fait sauter la cuisine de ma mère. Elle m'a dit : « Si tu dois faire des explosions, fais-les payer. » Alors j'ai ouvert une boutique.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("La magie, ça fatigue. Un sorcier qui lance trop de sorts a les mains qui tremblent et la tête qui tourne. Une potion de magie, et hop ! On repart.", {}), L("Je rachète les champignons, les baies, le miel. Tout ce qui pousse finit dans une fiole, un jour ou l'autre.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Théophraste réclame son traité des mélanges explosifs. Je le lis, je le lis ! C'est un livre qu'il faut lire lentement. Pour éviter les accidents.", {}), L("Mirabelle vend des potions sur la place. Des potions ratées. Elle dit que c'est de l'art. Je ne dis pas non.", {}, "rire")],
				"interpelle": [L("Potions ! Élixirs !", {"visites_max": 0}), L("{surnom} ! Une petite fiole ?", {"visites_min": 1})],
			}},
		{"id": "berthe", "nom": "Berthe Chaudron", "titre": "aubergiste du Chaudron Fumant", "maison": "porte_chaudron",
			"agenda": [[7, 23, "chaudron_comptoir"], [23, 7, "maison"]],
			"azur": {"cheveux": [0.55, 0.2, 0.12], "coiffure": "chignon", "yeux": [0.3, 0.4, 0.25], "haut": [0.72, 0.4, 0.22], "tablier": [0.92, 0.88, 0.8], "carrure": 1.2},
			"arc": {"robe": [0.5, 0.28, 0.16]},
			"teinte": PEAU[1], "humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"miel": 2.0, "croissant": 1.5, "biere_naine": 1.5}, "deteste": {"sardine": -0.5},
			"boutique": {"vend": {"hydromel": 4, "tarte_potiron": 6}, "achete": {"poisson_lune": 6, "miel": 4, "champignon": 2}},
			"repliques": {
				"accueil": [
					L("Entre, entre, ferme la porte, tu fais entrer les courants d'air ! Berthe Chaudron, du Chaudron Fumant. Ici, la soupe est chaude, l'hydromel est doux, et personne ne fait de magie à table. C'est la règle.", {"visites_max": 1}, "salut"),
					L("Ah, mon chou ! Assieds-toi. Je te sers ? Tu as l'air d'un voyageur qui a besoin d'une tarte.", {"visites_min": 2}),
				],
				"humeur": [L("Débordée ! Mais contente.", {}, "rire"), L("Le soir, mon auberge est pleine de sorciers fatigués. Ils racontent tous leurs exploits. La moitié est vraie.", {"soir": true}, "rire")],
				"lui": [L("Je ne suis pas sorcière, moi. Le seul sort que je connais, c'est la tarte au potiron. Mais crois-moi, il ensorcelle tout le monde.", {}, "rire"), L("Mon chaudron, là, au fond, ne s'est jamais éteint depuis que ma grand-mère l'a allumé. Les sorciers disent qu'il est magique. Moi je dis qu'il est bien entretenu.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Tout Arcanelle passe par mon auberge. Les maîtres, les apprentis, le passeur, la voyante. Si tu veux savoir quelque chose sur quelqu'un, demande à Berthe. Mais pas trop fort.", {}), L("Une chambre ? Il y en a une sous les toits, avec une lucarne. On y voit les étoiles. Aurélien dit que c'est la meilleure chambre de l'île pour rêver.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Mère Sauge dit que je sale trop ma soupe. Elle en reprend toujours deux fois. Je n'ai rien dit. Je souris.", {}, "rire"), L("Pyra et Borée, chaque soir, s'assoient chacun à un bout de la salle. Je leur sers la même soupe. Ils ne le savent pas.", {}, "rire")],
				"interpelle": [L("Entre, il fait bon !", {"visites_max": 0}), L("{surnom} ! Une part de tarte ?", {"visites_min": 1})],
			}},
		# ================================================================ les apprentis
		{"id": "pip", "nom": "Pip Grelot", "titre": "jeune apprenti", "maison": "porte_dortoir",
			"agenda": [[8, 12, "cour_banc_1"], [12, 13, "chaudron_table_5"], [13, 17, ["aire_banc", "cour_banc_1"]], [17, 20, "place_jeu_1"], [20, 8, "maison"]],
			"azur": {"cheveux": [0.65, 0.42, 0.2], "coiffure": "court", "yeux": [0.35, 0.5, 0.3], "haut": [0.3, 0.45, 0.7], "taille": 0.76},
			"arc": {"robe": [0.3, 0.42, 0.68], "chapeau": [0.28, 0.38, 0.62]},
			"teinte": PEAU[0], "humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"cerf_volant": 3.0, "glace": 2.5, "plume_vent": 2.0}, "deteste": {"tisane_lune": -0.5},
			"repliques": {
				"accueil": [
					L("Salut ! T'es nouveau ? Moi c'est Pip, apprenti, première année ! Je sais faire une étincelle. Regarde ! … Bon, elle est partie. Mais je sais la faire, promis !", {"visites_max": 1}, "salut"),
					L("Hé, c'est toi ! Tu as appris un sort ? Montre ! Montre !", {"visites_min": 2}),
				],
				"humeur": [L("Super content ! Aujourd'hui j'ai presque lévité ! Enfin, j'ai sauté très haut.", {}, "rire"), L("J'ai pas sommeil. Les apprentis n'ont jamais sommeil. C'est la règle.", {"soir": true})],
				"lui": [L("Je suis arrivé ici l'an dernier. Mes parents sont pêcheurs à Port-Azur. Un jour, j'ai fait voler un hareng. Ils m'ont envoyé ici. Le hareng aussi, il est resté à Port-Azur.", {}, "rire"), L("Plus tard, je serai maître de la lévitation, comme Zéphyrine. Ou maître du feu. Ou cuisinier. Je ne sais pas encore. Peut-être les trois.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Le dortoir est au fond de la cour de l'Académie. Oscar ronfle. Lin lit sous sa couverture. Mirabelle fait des potions sous son lit. Moi je dors. Presque.", {}, "rire"), L("Il paraît qu'il y a un fantôme dans la Crypte aux Runes ! C'est Oscar qui l'a dit. Mais Oscar dit beaucoup de choses.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Oscar a changé son chapeau en pigeon. Le pigeon s'appelle Gérard. Il vit sur le toit du dortoir. Il nous regarde.", {}, "rire"), L("Mirabelle dit que ses potions ratées sont des potions d'art. Une fois, j'en ai bu une. J'ai eu les oreilles vertes pendant une journée.", {}, "rire")],
				"interpelle": [L("Hé ! Hé ! Toi !", {"visites_max": 0}), L("{surnom} ! Regarde ce que je sais faire !", {"visites_min": 1})],
			}},
		{"id": "mirabelle", "nom": "Mirabelle Pétard", "titre": "apprentie alchimiste", "maison": "porte_dortoir",
			"agenda": [[8, 12, "cour_banc_2"], [12, 13, "chaudron_table_6"], [13, 18, "etal_mirabelle"], [18, 20, "place_jeu_2"], [20, 8, "maison"]],
			"azur": {"cheveux": [0.92, 0.75, 0.4], "coiffure": "tresse", "yeux": [0.3, 0.55, 0.35], "haut": [0.85, 0.45, 0.62], "taille": 0.8},
			"arc": {"robe": [0.72, 0.32, 0.55], "chapeau": [0.62, 0.22, 0.45]},
			"teinte": PEAU[5], "humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"poussiere_fee": 3.0, "nectar_fee": 2.0, "miel": 1.5}, "deteste": {"sardine": -0.5},
			"repliques": {
				"accueil": [
					L("Bonjour ! Mirabelle, apprentie alchimiste. Tu veux une potion ? Elles sont toutes ratées. C'est ça qui les rend uniques. Celle-ci fait éternuer des bulles. Celle-là change ta voix en canard pendant une heure.", {"visites_max": 1}, "salut"),
					L("Re-bonjour ! J'ai raté une nouvelle potion. Elle est encore plus ratée que les autres. Je suis très fière.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Bouillonnante !", {}, "rire"), L("Le soir, je range mes fioles par couleur. Puis par odeur. Puis je les mélange.", {"soir": true})],
				"lui": [L("Gustave dit que j'ai du talent. Il dit aussi que je dois arrêter d'utiliser sa cave comme laboratoire. Les deux sont vrais.", {}, "rire"), L("Ma potion la plus réussie, c'est celle qui ne marche pas du tout. Tout le monde l'aime. C'est du jus de mûre.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Sur la place, il y a la statue du Fondateur. Il paraît que son orbe s'allume quand quelqu'un devient sorcier. Je l'ai jamais vue s'allumer. Pas encore.", {}), L("Les potions de magie de Gustave, elles sont vraiment bonnes. Quand tu as plus de forces pour tes sorts, une gorgée, et ça repart.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Pip a bu une de mes potions. Il a eu les oreilles vertes. Il dit que c'est ma faute. C'est un peu la sienne : c'était écrit « pas pour Pip » sur l'étiquette.", {}, "rire"), L("Lin lit tellement qu'un jour, elle va rentrer dans un livre et on ne la reverra plus. Je lui ai dit. Elle a souri.", {})],
				"interpelle": [L("Potions ratées ! Pas chères !", {"visites_max": 0}), L("{surnom} ! Goûte celle-ci !", {"visites_min": 1})],
			}},
		{"id": "oscar", "nom": "Oscar Bévue", "titre": "apprenti maladroit", "maison": "porte_dortoir",
			"agenda": [[8, 12, "cour_banc_3"], [12, 13, "chaudron_table_7"], [13, 18, ["bib_table_2", "aire_banc"]], [18, 20, "place_fontaine_3"], [20, 8, "maison"]],
			"azur": {"cheveux": [0.12, 0.1, 0.08], "coiffure": "boucles", "yeux": [0.25, 0.18, 0.1], "haut": [0.42, 0.5, 0.3], "taille": 0.9, "lunettes": true},
			"arc": {"robe": [0.38, 0.46, 0.26], "chapeau": [0.3, 0.38, 0.2]},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.6, "rancunier": 0.1},
			"aime": {"croissant": 2.0, "tarte_potiron": 2.5, "montre_envers": 1.5}, "deteste": {"flocon_givre": -0.5},
			"repliques": {
				"accueil": [
					L("Oh ! Pardon ! Je t'ai pas marché sur le pied ? Non ? Ouf. Oscar. Apprenti. Troisième année. Enfin… troisième première année.", {"visites_max": 1}, "salut"),
					L("Salut ! Attention, je viens de lancer un sort. Je ne sais pas encore lequel. On va voir.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Ça va ! Rien n'a explosé aujourd'hui. Enfin, presque rien.", {}, "rire"), L("Fatigué. J'ai couru après Gérard toute la journée. Gérard, c'est mon chapeau. Enfin, c'était.", {"soir": true})],
				"lui": [L("Je rate tous mes sorts. Mais je les rate de façon originale ! L'archimage dit que c'est déjà une forme de talent. Je crois qu'elle est gentille.", {}), L("Un jour, je réussirai un sort parfait, devant tout le monde. Et Pyra applaudira. Pyra n'applaudit jamais. Ce sera le plus beau jour de ma vie.", {"sujet_min": ["lui", 1]})],
				"ile": [L("La Crypte aux Runes, j'y suis entré une fois, sans lumière. J'ai entendu quelque chose bouger. C'était moi. Mais j'ai eu très peur quand même.", {}), L("Les mannequins de paille de l'Aire des Duels, je les ai tous brûlés au moins une fois. Pas exprès. Pyra dit que c'est un record.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("Gérard, mon pigeon, vit sur le toit du dortoir. Il refuse de redevenir chapeau. Je le comprends, il a une meilleure vue.", {}, "rire"), L("Pip veut léviter en sautant avec un drap. Je l'ai fait l'an dernier. Mère Sauge m'a soigné une semaine.", {})],
				"interpelle": [L("Attention ! … Ah, non, c'est rien.", {"visites_max": 0}), L("{surnom} ! Tu veux voir un sort ? Recule un peu.", {"visites_min": 1})],
			}},
		{"id": "lin", "nom": "Lin Feuillette", "titre": "apprentie studieuse", "maison": "porte_dortoir",
			"agenda": [[8, 12, "cour_banc_4"], [12, 13, "chaudron_table_8"], [13, 19, ["bib_table_3", "cercle_pierre"]], [19, 21, "bib_table_4"], [21, 8, "maison"]],
			"azur": {"cheveux": [0.08, 0.06, 0.06], "coiffure": "carre", "yeux": [0.2, 0.15, 0.1], "haut": [0.45, 0.4, 0.62], "taille": 0.9, "lunettes": true},
			"arc": {"robe": [0.36, 0.32, 0.55], "chapeau": [0.28, 0.24, 0.45]},
			"teinte": PEAU[2], "humeur_base": 0.25, "traits": {"bavard": 0.2, "humour": 0.4, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"grimoire": 3.0, "carte_postale": 1.5, "the_menthe": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("… Oh. Bonjour. Lin. Apprentie. Excuse-moi, j'étais au chapitre douze. Le sort de lumière y est décrit en quatre cents pages. C'est passionnant.", {"visites_max": 1}),
					L("Bonjour, {surnom}. J'ai fini le chapitre douze. Il y a un chapitre treize. Je suis très contente.", {"visites_min": 2}),
				],
				"humeur": [L("Bien. J'ai trouvé un livre que je n'avais pas lu. C'est rare.", {}), L("Je lis encore un peu. Juste un chapitre. Ou deux.", {"soir": true})],
				"lui": [L("Je viens de Cliquetis. Mes parents fabriquent des automates. Moi je préférais les livres de sorciers aux livres de mécanique. Ils ont dit : « Va voir l'archimage. » Je suis venue. Je ne suis jamais repartie.", {}), L("Je ne rate jamais un sort. Mais je les lance lentement. Pyra dit que je lance des boules de feu comme on écrit une lettre. Je crois que c'est un compliment.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Au Cercle des Pierres-Lunes, il y a neuf pierres. Chacune a un nom. Ysolde les connaît tous. Elle m'en a appris trois. Je les écris dans mon carnet.", {}), L("Les quatre livres envolés de Théophraste, je sais où ils sont. Mais je ne sais pas les faire descendre. Il faut la télékinésie. Je n'en suis pas encore là.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Mirabelle dit que je vais entrer dans un livre et disparaître. Ce serait bien, si c'est un bon livre.", {}), L("Théophraste me chronomètre quand je lis. Il croit que je ne le vois pas. Je fais semblant de lire plus lentement pour lui faire plaisir.", {})],
				"interpelle": [L("…", {"visites_max": 0}), L("Oh, {surnom}. Bonjour.", {"visites_min": 1})],
			}},
		# ================================================================ les gardiens et les gens du bord
		{"id": "ysolde", "nom": "Ysolde Lunevoile", "titre": "gardienne du Cercle des Pierres-Lunes", "maison": "porte_ysolde",
			"agenda": [[6, 11, "cercle_autel"], [11, 14, "maison_ysolde_banc"], [14, 22, "cercle_garde"], [22, 2, "cercle_autel"], [2, 6, "maison"]],
			"azur": {"cheveux": [0.12, 0.1, 0.16], "coiffure": "long", "yeux": [0.5, 0.55, 0.65], "haut": [0.2, 0.2, 0.32], "taille": 1.03},
			"arc": {"robe": [0.14, 0.14, 0.24], "cape": [0.62, 0.66, 0.78], "baton": true},
			"teinte": PEAU[4], "humeur_base": 0.1, "traits": {"bavard": 0.3, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"eclat_lune": 3.0, "plume_lune": 2.5, "perle": 1.5}, "deteste": {"pelle": -1.0},
			"repliques": {
				"accueil": [
					L("Le Cercle t'a vu arriver avant moi. Je suis Ysolde Lunevoile. Je garde les Pierres-Lunes. Personne ne les touche sans que je le sache. Personne.", {"visites_max": 1}),
					L("Tu reviens au Cercle. Les pierres s'en souviennent. Elles se souviennent de tout.", {"visites_min": 2}),
				],
				"humeur": [L("Attentive.", {}), L("La nuit, les pierres brillent un peu. Je reste près d'elles. Elles n'aiment pas être seules dans le noir.", {"soir": true})],
				"lui": [L("Ma mère gardait le Cercle, et sa mère avant elle. Je connais le nom des neuf pierres, et la chanson qui les réveille. Je ne la chante qu'une fois par génération.", {}), L("Quand un apprenti a appris les six sorts, l'archimage le conduit au Cercle. On pose la main sur l'autel. Les pierres décident. Elles n'ont jamais dit non. Mais elles pourraient.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les éclats de lune tombent souvent près du Cercle. Les pierres les attirent. Ou les éclats aiment les pierres. On ne sait pas qui a commencé.", {}), L("Le Bois Tors, au sud du Cercle, n'est pas méchant. Il est vieux. Les vieux arbres se tordent pour regarder qui passe.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Lin vient lire au pied des pierres. Elle leur lit des histoires à voix basse. Je crois que les pierres aiment ça.", {}), L("Agathe dit qu'elle voit l'avenir dans sa boule. Les pierres voient le passé. Ensemble, on pourrait tout savoir. Ce serait ennuyeux.", {})],
				"interpelle": [L("Ne touche pas aux pierres.", {"visites_max": 0}), L("{surnom}. Les pierres te saluent.", {"visites_min": 1})],
			}},
		{"id": "mathurin", "nom": "Mathurin Rame", "titre": "passeur et pêcheur", "maison": "porte_mathurin",
			"agenda": [[6, 12, "quai_peche"], [12, 13, "chaudron_bar_4"], [13, 19, ["quai_peche", "quai_bout"]], [19, 22, "chaudron_table_5"], [22, 6, "maison"]],
			"azur": {"cheveux": [0.6, 0.58, 0.55], "coiffure": "court", "barbe": "courte", "yeux": [0.3, 0.4, 0.45], "vieux": true, "haut": [0.2, 0.3, 0.45], "carrure": 1.1, "chapeau": "marin", "chapeau_c": [0.12, 0.16, 0.3]},
			"arc": {},
			"teinte": PEAU[2], "humeur_base": 0.2, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"rhum_murene": 2.5, "dorade": 2.0, "cidre_carene": 1.5}, "deteste": {"flocon_givre": -0.5},
			"boutique": {"vend": {"sardine": 3, "maquereau": 6}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 6, "bar": 7, "merou": 16}},
			"repliques": {
				"accueil": [
					L("Ho, matelot ! T'as trouvé Arcanelle tout seul ? Dans la brume ? Chapeau. Mathurin Rame, passeur. Je ne suis pas sorcier, moi : je rame. C'est de la magie aussi, demande à mes bras.", {"visites_max": 1}, "salut"),
					L("Te revoilà ! La brume t'a laissé passer. Elle t'aime bien.", {"visites_min": 2}),
				],
				"humeur": [L("Calme plat.", {}), L("Le soir, je regarde la mer. Des fois, je vois un serpent de mer. Des fois, c'est un tronc. Des fois, c'est l'hydromel.", {"soir": true}, "rire")],
				"lui": [L("Je suis né au village, de l'autre côté de l'eau. Je suis venu ici livrer des barriques, il y a trente ans. Je ne suis jamais reparti. Berthe m'avait servi sa tarte.", {}, "rire"), L("Je connais tous les courants autour de l'île. La brume, les écueils, les tourbillons. Les sorciers savent voler. Moi, je sais rentrer au port.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Arcanelle, de la mer, on ne la voit qu'au dernier moment. La brume la cache, et puis d'un coup : la tour de l'Académie, toute droite, et le cristal qui brille. Ça me fait encore quelque chose, après trente ans.", {}), L("Au nord, les falaises. Le vent y est glacé, même en été. Borée y monte chercher ses flocons. Moi je n'y monte pas. Les falaises, ça ne flotte pas.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Pyra dit que je vois des serpents de mer parce que je bois. Je bois parce que je vois des serpents de mer. C'est elle qui confond.", {}, "rire"), L("Agathe m'a prédit une grosse prise. J'ai attrapé une botte. Elle dit que c'était une grosse botte.", {}, "rire")],
				"interpelle": [L("Ho, matelot !", {"visites_max": 0}), L("{surnom} ! Ça mord, aujourd'hui !", {"visites_min": 1})],
			}},
		{"id": "agathe", "nom": "Agathe Brumaire", "titre": "voyante du Bois Tors", "maison": "porte_roulotte",
			"agenda": [[10, 19, "roulotte_table"], [19, 23, ["chaudron_table_8", "roulotte_table"]], [23, 10, "maison"]],
			"azur": {"cheveux": [0.3, 0.14, 0.2], "coiffure": "boucles", "yeux": [0.45, 0.3, 0.15], "haut": [0.55, 0.15, 0.25], "foulard": [0.75, 0.55, 0.2]},
			"arc": {"robe": [0.48, 0.12, 0.22], "cape": [0.2, 0.12, 0.28]},
			"teinte": PEAU[3], "humeur_base": 0.3, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"perle": 2.5, "carte_postale": 2.0, "coquillage": 1.5}, "deteste": {"boussole_sud": -1.0},
			"repliques": {
				"accueil": [
					L("Ah… Je t'attendais. Ne fais pas cette tête : je dis ça à tout le monde, et ça marche à chaque fois. Agathe Brumaire, voyante. Assieds-toi, la boule est chaude.", {"visites_max": 1}, "salut"),
					L("Tu reviens… La boule me l'avait dit. Elle me dit tout, cette pipelette.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Mystérieuse. C'est mon métier.", {}, "rire"), L("Le soir, la brume monte du Bois Tors. La boule y voit plus clair. Moi moins.", {"soir": true})],
				"lui": [L("Ma roulotte a fait le tour de l'archipel trois fois. Je me suis arrêtée ici parce que les arbres m'écoutaient. Les arbres tordus sont d'excellents confidents.", {}), L("Voir l'avenir, c'est facile. Le dire gentiment, c'est tout un art. Tu ne veux pas savoir ce qu'on a vu dans le thé de Pyra. Elle non plus, d'ailleurs.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Le Bois Tors est le plus vieil endroit de l'île. Les arbres s'y tordent depuis mille ans pour regarder les étoiles à travers les feuilles. Les champignons y brillent la nuit. C'est joli, et un peu inquiétant.", {}), L("Une chouette blessée vit près de ma roulotte. Elle ne laisse personne approcher. Elle attend quelqu'un. La boule dit : quelqu'un qui saura soigner.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Mathurin dit que je lui ai prédit une grosse prise et qu'il a attrapé une botte. C'était une très grosse botte. J'avais raison.", {}, "rire"), L("Lumen vient me demander si les étoiles bougeront demain. Je lui dis oui. Il est toujours rassuré.", {})],
				"interpelle": [L("Je t'attendais…", {"visites_max": 0}), L("{surnom} ! La boule a parlé de toi !", {"visites_min": 1})],
			}},
	]

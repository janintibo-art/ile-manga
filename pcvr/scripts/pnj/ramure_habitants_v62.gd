extends RefCounted
## V62 : les gens de Ramure, le village des oreilles, dans la forêt des brumes (l'est de la
## grande île). Ils ont des oreilles et une queue d'animal, et chaque espèce a son métier :
## les renards cueillent et soignent, les lapins cuisent le pain et courent, les chats pêchent,
## les ours forgent et portent, les loups veillent, les tanukis troquent, les chouettes portent
## le courrier, les écureuils construisent, les biches dansent.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd) ; oreilles, queue, postures : pnj_ramure_v62.gd. Lieux : ramure_v62.gd.
## Ils parlent de la fête de la lune (chaque nuit), de la Grande Course, du Grand Troc, des
## mares, du Zéphyr, des autres villes de l'île et du sceau des brumes.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "À bientôt, {surnom} ! Que tes oreilles restent au chaud.", "si": {}, "geste": "salut"},
		{"t": "Bonne route ! Et si tu te perds dans la brume, suis les lanternes.", "si": {}, "geste": "salut"},
		{"t": "File, file ! La forêt t'attend.", "si": {}},
		{"t": "Bonne nuit. Écoute bien : ce sont les tambours de la lune. Ils te bercent jusqu'au matin.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Mes oreilles se sont toutes hérissées ! On ne tape pas, à Ramure !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Grrr… Les loups du Guet vont entendre parler de toi.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Oh… ma queue s'agite toute seule. Merci !", "si": {}},
		{"t": "Un cadeau ! Je pourrai le troquer… non, je le garde. Merci !", "si": {}, "geste": "rire"},
	],
	"cadeau_refus": [{"t": "Une arme ? Non merci. Ici, on a des crocs et des griffes, et on ne s'en sert que pour les noisettes.", "si": {}}],
	"blague": [
		{"t": "Pourquoi les lapins ne jouent jamais aux cartes avec les renards ? Parce que les renards ont toujours un as dans la queue !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un ours qui n'a pas de dents ? Un nounours ! … Ne le dis pas à Ursule.", "si": {}, "geste": "rire"},
		{"t": "Un tanuki entre au Marché aux trocs avec une feuille sur la tête. Bedaine lui dit : « Je te l'échange contre deux feuilles ! » Le tanuki accepte. C'était Bedaine.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, renifle, choisis ! Tu as {pieces} pièces. Ici on prend aussi les pièces, même si on préfère troquer.", "si": {}}],
	"achat": [{"t": "{objet}, {prix} pièces. Marché conclu, tope là — de la patte !", "si": {}, "geste": "salut"}],
	"marchande_non": [{"t": "Marchander ? Va voir Bedaine, au Grand Troc. Moi, mes prix sont ronds comme la lune.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Oh, oh !", "Pattes et moustaches !", "Que la lune est belle !", "Hop hop !"],
		"neutre": ["Hmm.", "Voyons…", "Bon.", "Tiens, tiens…"],
		"triste": ["Ah…", "Mes oreilles tombent…", "Pff.", "Quelle brume dans ma tête…"],
		"colere": ["Grrr.", "Tss !", "Ça suffit.", "Mes poils se hérissent !"],
	},
	"tics": ["Par la lune !", "Comme disent les anciens de Ramure.", "Je le sens dans mes moustaches.", "Oreilles dressées !"],
	"humeur_mots": [[0.6, "à en remuer la queue"], [0.25, "de bonne humeur"], [-0.25, "les oreilles basses"], [-0.6, "le poil hérissé"], [-2.0, "à mordre"]],
	"surnoms": [[0, "voyageur"], [25, "petite patte"], [50, "ami des brumes"], [75, "frère de la lune"], [95, "cœur de Ramure"]],
}

const PEAU := [[1.0, 0.88, 0.78], [0.98, 0.82, 0.7], [0.94, 0.76, 0.62], [0.84, 0.64, 0.5], [0.7, 0.52, 0.4], [1.0, 0.92, 0.84]]

## Les pelages (poil, pointe, intérieur des oreilles).
const ROUX := [0.86, 0.42, 0.14]
const GRIS_LOUP := [0.56, 0.56, 0.6]
const BRUN_OURS := [0.42, 0.28, 0.17]
const TANUKI := [0.56, 0.46, 0.36]
const BLANC := [0.96, 0.95, 0.93]
const ROSE := [0.98, 0.78, 0.76]


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
	out["groupe"] = "ramure"
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Chêne-Mère
		{"id": "merelune", "nom": "Mère-Lune", "titre": "doyenne de Ramure", "maison": "porte_mere_lune",
			"agenda": [[7, 10, "mere_lune_porte"], [10, 12, ["marche_client_1", "marche_client_2"]], [12, 15, "mere_lune_porte"], [15, 19, ["cercle_banc_1", "jeux_banc_1"]], [19, 20, "mere_lune_porte"], [20, 1, "cercle_mere"], [1, 7, "maison"]],
			"azur": {"cheveux": [0.86, 0.86, 0.88], "coiffure": "long", "haut": [0.32, 0.36, 0.58], "robe": [0.22, 0.26, 0.45], "robe_longue": true, "yeux": [0.75, 0.62, 0.25], "vieux": true, "foulard": [0.85, 0.8, 0.55]},
			"kemo": {"espece": "loup", "poil": [0.86, 0.86, 0.88], "interieur": [0.9, 0.84, 0.82], "pointe": BLANC, "queue": 1.1},
			"teinte": PEAU[0], "humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.4, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"champignon_lune": 3.0, "tisane_brume": 2.0, "gateau_lune": 2.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Approche, petit. N'aie pas peur de mes oreilles : elles sont vieilles, mais elles entendent encore battre les cœurs. Je suis Mère-Lune. Bienvenue à Ramure, le village des oreilles.", {"visites_max": 1}, "salut"),
					L("Te revoilà, {surnom}. La brume m'avait dit que tu reviendrais.", {"visites_min": 2}),
				],
				"humeur": [L("Paisible. Les arbres ont bien dormi, les enfants aussi. Un peu moins les enfants.", {}), L("Le soir, je m'assois sur ma mousse, près du feu, et je regarde danser les jeunes. Mes pattes dansent encore, dans ma tête.", {"soir": true})],
				"lui": [
					L("J'étais pisteuse, autrefois, comme Brume. J'ai suivi la trace de la lune jusqu'au bord du monde. Elle m'a dit : rentre chez toi, Ramure a besoin de toi. Je suis rentrée.", {}),
					L("Les lanternes de lune, sur les ponts, ce sont des champignons des mares qui luisent la nuit. Chaque printemps, j'en remets de nouveaux. Cette année, mes vieilles pattes ne vont plus jusqu'au bord de l'eau.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Ramure est née dans les arbres parce que la forêt était pleine de brume, et la brume pleine de loups. Les vrais loups, pas Croc-Gris. On a monté nos maisons là-haut. Puis les loups sont partis, et on est restés : c'était trop joli.", {}),
					L("Quatre peuples sur cette île, quatre sceaux dans la grande porte. Le nôtre, le sceau des brumes… Il dort au fond de la plus grande mare. Seule la lune sait où, et la lune ne parle qu'aux anciens. Pas encore à toi.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [L("Pépin dit que personne n'a jamais battu Bondi à la Grande Course. Bondi dit que c'est parce que personne n'a encore essayé pour de vrai.", {}, "rire"), L("Bedaine a encore troqué un caillou contre une plume, une plume contre une fiole… Un jour, il troquera le Chêne-Mère contre une noisette.", {}, "rire")],
				"interpelle": [L("Approche, petit.", {"visites_max": 0}), L("{surnom}…", {"visites_min": 1})],
			}},
		{"id": "pivoine", "nom": "Pivoine", "titre": "herboriste des Simples", "maison": "porte_simples",
			"agenda": [[7, 12, "simples_porte"], [12, 13, ["marche_client_3", "boul_client"]], [13, 19, "simples_porte"], [19, 20, "marche_client_2"], [20, 23, ["cercle_banc_2", "cercle_banc_6"]], [23, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "queue", "haut": [0.85, 0.82, 0.7], "robe": [0.35, 0.5, 0.3], "tablier": [0.55, 0.42, 0.28], "yeux": [0.4, 0.62, 0.3]},
			"kemo": {"espece": "renard", "poil": ROUX, "interieur": ROSE, "queue": 1.2},
			"teinte": PEAU[1], "humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"plume_lune": 2.0, "champignon": 1.5, "baies": 1.0}, "deteste": {"sardine": -0.5},
			"boutique": {"vend": {"tisane_brume": 6, "tisane_lune": 10}, "achete": {"champignon": 3, "baies": 1, "goutte_rosee": 6}},
			"repliques": {
				"accueil": [L("Bonjour ! Pivoine, herboriste. Tu as l'air fatigué… Non ? Alors tu le seras bientôt, et tu reviendras me voir. Tisane de brume pour dormir, tisane de lune pour rêver.", {"visites_max": 1}, "salut"), L("Ah, {surnom} ! Ton nez a l'air en forme. Le mien aussi : je sens que tu vas m'acheter quelque chose.", {"visites_min": 2}, "rire")],
				"humeur": [L("Parfumée. J'ai fait sécher la sauge ce matin.", {}), L("La nuit, mes herbes sentent plus fort. Les renards aussi, dit Roux. Il dit des bêtises.", {"soir": true}, "rire")],
				"lui": [L("Les renards ont le meilleur nez de Ramure. Le mien distingue trois cents herbes. Et toutes les tartes de Trèfle, à cent pas.", {}, "rire"), L("Ma fiole de brume, c'est de la brume du matin, cueillie sur la grande mare avant le lever du soleil. On la met en bouteille avec une plume de lune pour qu'elle ne s'envole pas. Ça guérit les cœurs gros.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les fées de l'ouest ont des fleurs de lune. Ici, nous avons les champignons de lune. Les fées disent que leurs fleurs brillent plus fort. Les fées disent beaucoup de choses.", {})],
				"rumeur": [L("Roux est encore rentré avec des feuilles dans la queue. Il dit qu'il cueillait. Je dis qu'il dormait sous un arbre.", {}, "rire")],
				"interpelle": [L("Une tisane ?", {"visites_max": 0}), L("{surnom} ! Une tisane ?", {"visites_min": 1})],
			}},
		{"id": "roux", "nom": "Roux", "titre": "cueilleur et joueur de flûte", "maison": "porte_ouest_1",
			"agenda": [[7, 12, "marche_plumes"], [12, 15, ["jardin_2", "ponton_1", "aire_zephyr"]], [15, 19, "marche_plumes"], [19, 20, "boul_client"], [20, 1, "cercle_flute"], [1, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "haut": [0.3, 0.4, 0.25], "yeux": [0.55, 0.4, 0.15], "foulard": [0.8, 0.75, 0.6]},
			"kemo": {"espece": "renard", "poil": ROUX, "interieur": ROSE, "queue": 1.3},
			"teinte": PEAU[2], "humeur_base": 0.5, "traits": {"bavard": 0.7, "humour": 0.9, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"miel": 2.0, "baies": 1.5, "pomme": 1.0}, "deteste": {"pelle": -0.5},
			"repliques": {
				"accueil": [L("Salut, l'étranger ! Roux. Je cueille, je trouve, je vends : plumes, cordes, babioles de la forêt. Et le soir, je joue de la flûte pour la lune. Elle aime bien.", {"visites_max": 1}, "salut"), L("Hé, {surnom} ! J'ai trouvé un truc ce matin. Je ne sais pas ce que c'est. Tu veux l'acheter ?", {"visites_min": 2}, "rire")],
				"humeur": [L("Léger comme une plume. Comme toutes mes plumes, d'ailleurs.", {}, "rire"), L("Ce soir, je joue la chanson de la lune. Viens au Cercle, écoute, et ne dis pas à Pivoine que je l'ai écrite pour elle.", {"soir": true})],
				"lui": [L("Ma flûte est taillée dans un bambou du Cercle. Elle a sept trous. Le huitième, c'est un écureuil qui l'a fait. Depuis, elle joue une note de plus.", {}, "rire"), L("Pivoine dit que je dors sous les arbres au lieu de cueillir. C'est faux. Je cueille en dormant. C'est une technique de renard.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("J'ai marché jusqu'à Tazira, une fois, en suivant la côte. Trois jours. Là-bas, ils jouent du tambour toute la nuit, sur une place pleine de sable. J'ai appris leurs rythmes à Pépin.", {})],
				"rumeur": [L("Il paraît que Hulotte a vu une étoile tomber dans la grande mare. Moi, je crois que c'était une luciole qui avait trop bu de tisane de lune.", {}, "rire")],
				"interpelle": [L("Hé, l'étranger !", {"visites_max": 0}), L("{surnom} ! Psst !", {"visites_min": 1})],
			}},
		# ================================================================ le Marché aux trocs
		{"id": "bedaine", "nom": "Bedaine", "titre": "maître du Grand Troc", "maison": "porte_mares_1",
			"agenda": [[8, 13, "marche_troc"], [13, 14, "boul_client"], [14, 20, "marche_troc"], [20, 1, ["cercle_banc_3", "cercle_banc_7"]], [1, 8, "maison"]],
			"azur": {"cheveux": TANUKI, "coiffure": "boucles", "haut": [0.55, 0.3, 0.15], "yeux": [0.35, 0.25, 0.12], "carrure": 1.3, "tablier": [0.25, 0.32, 0.22]},
			"kemo": {"espece": "tanuki", "poil": TANUKI, "interieur": [0.25, 0.2, 0.16], "queue": 1.3},
			"teinte": PEAU[3], "humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"grelot_tanuki": 3.0, "caillou_chantant": 2.0, "miel": 1.5, "pain_carotte": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Hé hé hé ! Un nouveau visage ! Bedaine, maître du Grand Troc. Ici, pas de pièces, mon ami : on échange ! Une chose contre une autre, et tout le monde repart plus riche. C'est magique. Enfin, c'est du commerce.", {"visites_max": 1}, "rire"), L("Ah, mon client préféré ! Qu'est-ce que tu m'apportes ? Qu'est-ce que tu remportes ?", {"visites_min": 2}, "rire")],
				"humeur": [L("Rond et content ! Comme mon ventre.", {}, "rire"), L("Le soir, je compte mes trocs de la journée. Je n'ai jamais rien gagné, jamais rien perdu… et pourtant je suis plus riche chaque jour. C'est ça, le troc.", {"soir": true})],
				"lui": [L("Les tanukis troquent depuis toujours. Mon grand-père a troqué une feuille contre une maison. Il a fait croire que la feuille était magique. Elle ne l'était pas. La maison, si : elle est encore debout.", {}, "rire"), L("Le Grand Troc, le vrai, c'est une chaîne : tu donnes un caillou, on te donne un gland, puis une plume, puis une fiole… Au bout, il y a toujours quelque chose de beau. Je te montrerai, si tu veux.", {"sujet_min": ["lui", 1]})],
				"ile": [L("À Cliquetis, ils m'ont troqué une boussole qui indique le sud. Je l'ai troquée à Carène contre une longue-vue qui voit le passé. Je l'ai troquée à Tazira contre un tapis qui ne vole pas. Je l'ai encore. Personne n'en veut.", {}, "rire")],
				"rumeur": [L("Grelot vend ses pommes contre des pièces. Des pièces ! Une tanuki ! Ma nièce me fait honte. Mais ses pommes sont bonnes.", {}, "rire")],
				"interpelle": [L("Troc, troc, troc !", {"visites_max": 0}), L("{surnom} ! On troque ?", {"visites_min": 1})],
			}},
		{"id": "grelot", "nom": "Grelot", "titre": "marchande de fruits", "maison": "porte_mares_2",
			"agenda": [[8, 19, "marche_fruits"], [19, 20, "peche_client"], [20, 1, "cercle_danse_2"], [1, 8, "maison"]],
			"azur": {"cheveux": TANUKI, "coiffure": "carre", "haut": [0.9, 0.6, 0.25], "robe": [0.4, 0.25, 0.2], "yeux": [0.3, 0.22, 0.12], "foulard": [0.75, 0.2, 0.18]},
			"kemo": {"espece": "tanuki", "poil": TANUKI, "interieur": [0.25, 0.2, 0.16], "queue": 1.1},
			"teinte": PEAU[2], "humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"grelot_tanuki": 2.0, "gateau_lune": 2.0}, "deteste": {"vieille_botte": -0.5},
			"boutique": {"vend": {"pomme": 2, "baies": 2, "miel": 8}, "achete": {"champignon": 2, "noix_coco": 2, "pomme": 1}},
			"repliques": {
				"accueil": [L("Des pommes, des baies, du miel de la forêt ! Grelot. Oui, comme le grelot. Il y en a un au bout de ma queue, écoute… Non, c'était ma tante. Elle est partie avec.", {"visites_max": 1}, "rire"), L("Re-bonjour ! Tes pommes d'hier étaient bonnes ? Elles sont meilleures aujourd'hui.", {"visites_min": 2})],
				"humeur": [L("Sucrée.", {}, "rire")],
				"lui": [L("Mon oncle Bedaine troque. Moi, je vends. Il dit que c'est une honte pour une tanuki. Je dis que les pièces, ça tient dans une poche, et une chèvre, non.", {}, "rire")],
				"ile": [L("Le miel vient des abeilles des grands arbres. Pomme-de-Pin grimpe le chercher, tout en haut. Elle redescend toujours avec trois piqûres et un sourire.", {})],
				"rumeur": [L("Bondi mange trois carottes avant chaque course. Il dit que ça fait courir plus vite. Moi, je crois que ça fait juste… des carottes de moins.", {}, "rire")],
				"interpelle": [L("Des pommes !", {"visites_max": 0}), L("{surnom} ! Des pommes ?", {"visites_min": 1})],
			}},
		# ================================================================ les lapins : le pain et la course
		{"id": "trefle", "nom": "Trèfle", "titre": "boulangère", "maison": "porte_boulangerie",
			"agenda": [[5, 8, "boul_four"], [8, 13, "boul_comptoir"], [13, 14, "jardin_1"], [14, 19, "boul_comptoir"], [19, 20, "boul_four"], [20, 23, ["cercle_banc_4", "cercle_banc_8"]], [23, 5, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "haut": [0.95, 0.9, 0.85], "robe": [0.7, 0.45, 0.35], "tablier": [0.96, 0.95, 0.92], "yeux": [0.55, 0.25, 0.3]},
			"kemo": {"espece": "lapin", "poil": BLANC, "interieur": ROSE, "oreille_tombante": true},
			"teinte": PEAU[0], "humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"miel": 2.0, "pomme": 1.0, "baies": 1.0}, "deteste": {"champignon": -0.5},
			"boutique": {"vend": {"pain_carotte": 4, "gateau_lune": 7}, "achete": {"pomme": 1, "miel": 4, "baies": 1}},
			"repliques": {
				"accueil": [L("Bonjour bonjour ! Trèfle, boulangère. Pain de carotte, gâteau de lune… Tout sort du four, tout est chaud. Mochi ! Pose ce gâteau ! … Pardon. C'est ma fille.", {"visites_max": 1}, "salut"), L("Ah, {surnom} ! Le pain est tout chaud, comme toujours.", {"visites_min": 2})],
				"humeur": [L("Farineuse ! Je suis farineuse jusqu'au bout des oreilles.", {}, "rire"), L("Le soir, je m'assois au Cercle, je regarde le feu, et je pense déjà au pain de demain.", {"soir": true})],
				"lui": [L("Les lapins de Ramure se lèvent avant le soleil. On allume le four, on pétrit, on goûte. On goûte beaucoup.", {}, "rire"), L("Le gâteau de lune, c'est la recette de ma grand-mère : farine de châtaigne, miel, et un rond de pâte de haricot dessiné comme la lune. On le mange le soir de la fête. Donc tous les soirs.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Il paraît qu'à Port-Azur, ils font des croissants. Des pains en forme de lune croissante ! Comme nous ! Mais à moitié.", {})],
				"rumeur": [L("Pépin s'entraîne au tambour derrière ma boulangerie. Mon pain lève en rythme, maintenant.", {}, "rire")],
				"interpelle": [L("Du pain chaud !", {"visites_max": 0}), L("{surnom} ! Du pain chaud !", {"visites_min": 1})],
			}},
		{"id": "pepin", "nom": "Pépin", "titre": "organisateur de la Grande Course", "maison": "porte_sud_1",
			"agenda": [[8, 12, "jeux_depart"], [12, 13, "boul_client"], [13, 19, "jeux_depart"], [19, 20, "jeux_records"], [20, 1, "cercle_tambour_1"], [1, 8, "maison"]],
			"azur": {"cheveux": [0.62, 0.48, 0.36], "coiffure": "court", "haut": [0.85, 0.2, 0.15], "yeux": [0.3, 0.22, 0.12], "foulard": [0.95, 0.85, 0.3]},
			"kemo": {"espece": "lapin", "poil": [0.62, 0.48, 0.36], "interieur": ROSE, "pointe": BLANC},
			"teinte": PEAU[2], "humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"pain_carotte": 2.0, "coupe_course": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Hé ! Toi ! Tu as des jambes ? Deux ? Parfait ! Pépin, organisateur de la Grande Course de Ramure : dix arches de lanternes, une boucle autour du village, et Bondi à battre. Personne ne bat Bondi. Tu veux essayer ?", {"visites_max": 1}, "salut"), L("{surnom} ! Prêt pour une course ? L'arche du départ est juste là !", {"visites_min": 2})],
				"humeur": [L("En pleine forme ! Je cours tous les matins. Jusqu'à la boulangerie.", {}, "rire"), L("Ce soir, je tiens le tambour. Boum, boum-boum. Le cœur de la fête, c'est moi.", {"soir": true})],
				"lui": [L("J'ai couru la Grande Course pendant dix ans. Je n'ai jamais gagné. Alors je l'organise. C'est presque pareil, et je gagne à chaque fois.", {}, "rire"), L("Le tableau des records, là, c'est moi qui le peins. Bondi est tout en haut depuis trois ans. Il commence à s'ennuyer, tout seul là-haut.", {"sujet_min": ["lui", 1]})],
				"ile": [L("La course passe sous les dix arches : la Clairière des Jeux, le nord, les mares de l'ouest, le Cercle, le sud, la forge, le Guet… et retour. Ne coupe pas par les arbres : les arches comptent.", {})],
				"rumeur": [L("Grisou dit qu'il va battre Bondi cette fois. Il le dit à chaque fois. Éclair ne dit rien. C'est elle qu'il faut surveiller.", {})],
				"interpelle": [L("Une course ?", {"visites_max": 0}), L("{surnom} ! Une course ?", {"visites_min": 1})],
			}},
		{"id": "bondi", "nom": "Bondi", "titre": "champion de la Grande Course", "maison": "porte_sud_2",
			"agenda": [[7, 9, "jardin_2"], [9, 12, "jeux_echauffement_1"], [12, 13, "boul_client"], [13, 19, "jeux_echauffement_2"], [19, 20, "jeux_banc_2"], [20, 1, "cercle_danse_3"], [1, 7, "maison"]],
			"azur": {"cheveux": [0.95, 0.92, 0.88], "coiffure": "court", "haut": [0.2, 0.45, 0.85], "yeux": [0.6, 0.2, 0.25]},
			"kemo": {"espece": "lapin", "poil": [0.95, 0.92, 0.88], "interieur": ROSE},
			"teinte": PEAU[0], "humeur_base": 0.7, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"pain_carotte": 3.0, "coupe_course": 1.0}, "deteste": {"sardine": -0.5},
			"repliques": {
				"accueil": [L("Hop ! Bondi. Champion de la Grande Course, trois ans de suite. Tu veux un conseil ? Ne me suis pas : tu vas voir que mes talons.", {"visites_max": 1}, "rire"), L("Hop hop ! Encore toi ? Tu t'entraînes ? Moi aussi. Tout le temps.", {"visites_min": 2})],
				"humeur": [L("Rapide !", {}, "rire")],
				"lui": [L("Trois carottes avant la course, pas une de plus. La quatrième, ça alourdit.", {}), L("Le secret, c'est le départ. Je pars comme une flèche, et après, les autres courent derrière une flèche. C'est décourageant.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Un jour, je ferai le tour de toute l'île en courant. Cliquetis, Tazira, Carène, et retour. Plus vite que le Zéphyr ! … Bon, peut-être pas plus vite que le Zéphyr.", {})],
				"rumeur": [L("Éclair s'entraîne en cachette, la nuit. Je l'ai vue. Elle ne m'a pas vu. Je suis trop rapide.", {})],
				"interpelle": [L("Hop !", {"visites_max": 0}), L("Hop, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "mochi", "nom": "Mochi", "titre": "fille de la boulangère", "maison": "porte_boulangerie",
			"agenda": [[8, 12, "cercle_enfants_1", ["cercle_enfants_2"]], [12, 13, "boul_client"], [13, 18, "jeux_enfants_1", ["jeux_enfants_2"]], [18, 21, ["cercle_banc_5", "jeux_banc_2"]], [21, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "court", "haut": [0.95, 0.6, 0.7], "robe": [0.9, 0.85, 0.5], "yeux": [0.55, 0.25, 0.3], "taille": 0.68},
			"kemo": {"espece": "lapin", "poil": BLANC, "interieur": ROSE, "oreille_tombante": true},
			"teinte": PEAU[0], "humeur_base": 0.8, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"gateau_lune": 3.0, "pain_carotte": 2.0, "glace": 2.0}, "deteste": {"sardine": -0.5},
			"repliques": {
				"accueil": [L("T'as pas d'oreilles ! Enfin si, mais elles sont toutes petites, sur le côté ! C'est rigolo ! Moi c'est Mochi. Ma maman fait le pain.", {"visites_max": 1}, "rire"), L("C'est toi ! L'oreilles-toutes-petites ! Tu joues ?", {"visites_min": 2}, "rire")],
				"humeur": [L("Super ! J'ai mangé un gâteau de lune. Chut.", {}, "rire")],
				"lui": [L("Plus tard je serai coureuse, comme Bondi. Ou boulangère. Ou les deux : je livrerai le pain en courant !", {})],
				"ile": [L("Gland dit qu'il y a un dragon sous la grande mare. Myrtille dit que c'est un gros poisson. Moi je dis que c'est un dragon-poisson.", {})],
				"rumeur": [L("Hulotte voit dans le noir ! Il m'a dit que j'avais du gâteau sur le museau. Dans le noir !", {}, "rire")],
				"interpelle": [L("Hé ! Les petites oreilles !", {"visites_max": 0}), L("{surnom} ! Tu joues ?", {"visites_min": 1})],
			}},
		# ================================================================ les ours : la forge et la nacelle
		{"id": "ursule", "nom": "Ursule", "titre": "forgeronne", "maison": "porte_nord_1",
			"agenda": [[7, 12, "forge_enclume"], [12, 13, "marche_client_4"], [13, 18, "forge_enclume"], [18, 20, "forge_client"], [20, 23, ["cercle_banc_5", "cercle_banc_1"]], [23, 7, "maison"]],
			"azur": {"cheveux": BRUN_OURS, "coiffure": "queue", "haut": [0.45, 0.35, 0.28], "tablier": [0.22, 0.16, 0.12], "yeux": [0.3, 0.2, 0.1], "carrure": 1.35, "taille": 1.08},
			"kemo": {"espece": "ours", "poil": BRUN_OURS, "interieur": [0.62, 0.48, 0.38]},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.3, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"miel": 3.0, "minerai_fer": 1.5, "fiole_brume": 1.0}, "deteste": {"sifflet_muet": -0.5},
			"boutique": {"vend": {"hache": 30, "pelle": 18}, "achete": {"minerai_fer": 6, "buche": 2}},
			"repliques": {
				"accueil": [L("… Ursule. Forgeronne. Haches, pelles, clous pour les ponts, cloches pour les lanternes. Tu veux quelque chose, demande. Tu veux parler, parle à Tilleul.", {"visites_max": 1}), L("Hm. Toi. Bonjour.", {"visites_min": 2})],
				"humeur": [L("Chaude. Comme la forge.", {}), L("Fatiguée. Le marteau pèse plus lourd le soir. Le miel, moins.", {"soir": true})],
				"lui": [L("Les ours de Ramure sont forts et lents. On forge, on porte, on ne court pas. Laisse la course aux lapins.", {}), L("Je fais les clochettes d'argent pour les grandes fêtes. Une clochette pour chaque oreille qui naît à Ramure. Il y en a beaucoup, sur le Chêne-Mère.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les nains de la Montagne de Feu ont de grandes forges. J'y suis allée, jeune. Ils m'ont trouvée trop poilue. Je les ai trouvés trop bavards.", {})],
				"rumeur": [L("Bourru a encore oublié de remonter la nacelle. Trois lapins ont attendu en bas toute la matinée. Ils ont fini par prendre l'escalier. Ça leur a fait du bien.", {})],
				"interpelle": [L("Hm.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "bourru", "nom": "Bourru", "titre": "gardien de la nacelle", "maison": "porte_nord_2",
			"agenda": [[7, 20, "ascenseur"], [20, 1, "cercle_tambour_2"], [1, 7, "maison"]],
			"azur": {"cheveux": [0.32, 0.22, 0.14], "coiffure": "court", "barbe": "courte", "haut": [0.6, 0.3, 0.18], "yeux": [0.25, 0.18, 0.1], "carrure": 1.4, "taille": 1.1},
			"kemo": {"espece": "ours", "poil": [0.32, 0.22, 0.14], "interieur": [0.55, 0.42, 0.34]},
			"teinte": PEAU[3], "humeur_base": 0.3, "traits": {"bavard": 0.4, "humour": 0.7, "curiosite": 0.3, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"miel": 3.0, "gateau_lune": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Hrmm. Bourru. Je garde la nacelle d'osier : elle monte à la cime du Chêne-Mère, et elle redescend. Monte dedans, attends un peu, et hop. C'est moi qui tire la corde. Enfin, c'est la poulie. Mais je la surveille.", {"visites_max": 1}, "salut"), L("Hrmm ! La nacelle t'attend. Monte, monte.", {"visites_min": 2})],
				"humeur": [L("Hrmm. Bien.", {}), L("Ce soir, je tape sur le grand tambour. Boum. Ça, j'aime.", {"soir": true}, "rire")],
				"lui": [L("La nacelle, c'est mon grand-père qui l'a tressée. L'osier a été changé quatre fois. La corde, six fois. Mais c'est toujours la nacelle de mon grand-père.", {}), L("D'en haut, à la cime, on voit la mer à l'est et la montagne à l'ouest. Monte au coucher du soleil. Ne le dis à personne : il y a trop de monde, après.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Il y a un dirigeable qui vient se poser au nord du village, le Zéphyr. Les ingénieurs de Cliquetis. Ils ont voulu me vendre une nacelle à vapeur. Hrmm. Non.", {})],
				"rumeur": [L("Hulotte monte à la cime toutes les nuits pour regarder les étoiles. Il ne prend jamais la nacelle. Il vole. Enfin, il dit qu'il vole.", {})],
				"interpelle": [L("Hrmm !", {"visites_max": 0}), L("Hrmm, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "tilleul", "nom": "Grand-Père Tilleul", "titre": "conteur", "maison": "porte_nord_2",
			"agenda": [[8, 12, "cercle_banc_2"], [12, 14, "boul_client"], [14, 19, ["jeux_banc_1", "cercle_banc_4"]], [19, 23, ["cercle_banc_5", "cercle_banc_6"]], [23, 8, "maison"]],
			"azur": {"cheveux": [0.7, 0.66, 0.6], "coiffure": "court", "barbe": "longue", "haut": [0.35, 0.42, 0.3], "yeux": [0.3, 0.25, 0.15], "vieux": true, "carrure": 1.3},
			"kemo": {"espece": "ours", "poil": [0.62, 0.55, 0.48], "interieur": [0.72, 0.62, 0.55]},
			"teinte": PEAU[2], "humeur_base": 0.5, "traits": {"bavard": 1.0, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"miel": 3.0, "tisane_brume": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Assieds-toi, assieds-toi. Je suis Tilleul, le conteur. Tu veux une histoire ? Il était une fois… non, attends. Il était deux fois. C'est une histoire qui s'est passée deux fois.", {"visites_max": 1}, "rire"), L("Ah, {surnom}. Tu reviens pour la suite de l'histoire ? Je ne me souviens plus où on en était. Je vais en commencer une autre.", {"visites_min": 2}, "rire")],
				"humeur": [L("Ensommeillé, mais heureux. Les vieux ours, ça somnole.", {}), L("La nuit, je raconte aux petits l'histoire de la lune qui ne voulait plus se coucher. Ils s'endorment toujours avant la fin. La lune aussi.", {"soir": true})],
				"lui": [L("Quand j'étais petit, il n'y avait qu'un arbre habité : le Chêne-Mère. Puis les familles ont grandi, et les ponts ont poussé d'un arbre à l'autre. Comme des branches. Ramure, ça veut dire ça : toutes les branches d'un arbre.", {}), L("L'histoire de la lune toujours pleine ? Il y a très longtemps, une louve a sauvé la lune tombée dans la grande mare. Pour la remercier, la lune a promis de briller toute ronde au-dessus de Ramure, chaque nuit. Et elle tient parole. Regarde.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Autrefois, les quatre peuples de l'île se retrouvaient au centre, devant la grande porte, une fois par an. On chantait, on troquait, on dansait. Puis la porte s'est fermée, avec ses quatre sceaux. On ne sait plus bien pourquoi. Les histoires ont oublié.", {})],
				"rumeur": [L("Mère-Lune sait des choses que les autres ne savent pas. Sur le sceau. Sur la grande mare. Elle ne les dira qu'à quelqu'un qui aime Ramure. Fais-toi aimer de Ramure.", {})],
				"interpelle": [L("Une histoire ?", {"visites_max": 0}), L("{surnom}… une histoire ?", {"visites_min": 1})],
			}},
		# ================================================================ les chats : la pêche
		{"id": "caramel", "nom": "Caramel", "titre": "poissonnière", "maison": "porte_pecherie",
			"agenda": [[7, 12, "marche_poisson"], [12, 13, "peche_client"], [13, 19, "peche_etal"], [19, 20, "boul_client"], [20, 23, ["cercle_banc_6", "cercle_banc_2"]], [23, 7, "maison"]],
			"azur": {"cheveux": [0.9, 0.6, 0.3], "coiffure": "carre", "haut": [0.25, 0.4, 0.6], "tablier": [0.85, 0.85, 0.82], "yeux": [0.55, 0.62, 0.2]},
			"kemo": {"espece": "chat", "poil": [0.9, 0.6, 0.3], "interieur": ROSE, "pointe": [0.98, 0.9, 0.78]},
			"teinte": PEAU[1], "humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"sardine": 2.0, "dorade": 2.5, "brochette_poisson": 1.5}, "deteste": {"pain_carotte": -0.3},
			"boutique": {"vend": {"brochette_poisson": 5, "sardine": 4}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 7, "bar": 8}},
			"repliques": {
				"accueil": [L("Mrrr… Bonjour. Caramel, poissonnière. Poissons des mares le matin, brochettes grillées l'après-midi. Et non, je ne goûte pas la marchandise. Pas beaucoup.", {"visites_max": 1}, "salut"), L("Mrrr ! Toi. Tu sens le poisson. C'est un compliment.", {"visites_min": 2}, "rire")],
				"humeur": [L("Mrrr. Satisfaite.", {}), L("Le soir, je m'étire au coin du feu. Sept fois. C'est le nombre parfait d'étirements.", {"soir": true})],
				"lui": [L("Les chats de Ramure pêchent dans les mares depuis toujours. Pas avec les pattes : avec des cannes. Les pattes, c'était il y a longtemps. On a progressé.", {}, "rire")],
				"ile": [L("À Tazira, ils pêchent en mer, sur de grands bateaux. La mer, c'est trop d'eau. Une mare, c'est la bonne taille.", {})],
				"rumeur": [L("Moustache dit qu'il a vu un poisson d'or dans la grande mare. Gros comme un lapin. Il l'appelle « le Roi des mares ». Il ne l'a jamais attrapé. Il ne l'a peut-être jamais vu.", {})],
				"interpelle": [L("Poisson frais !", {"visites_max": 0}), L("Mrrr, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "moustache", "nom": "Moustache", "titre": "pêcheur des mares", "maison": "porte_pecherie",
			"agenda": [[5, 11, "peche_1"], [11, 13, "peche_client"], [13, 19, "peche_2"], [19, 22, ["cercle_banc_7", "cercle_banc_3"]], [22, 5, "maison"]],
			"azur": {"cheveux": [0.12, 0.12, 0.13], "coiffure": "court", "barbe": "moustache", "haut": [0.5, 0.45, 0.35], "yeux": [0.7, 0.62, 0.15], "vieux": true},
			"kemo": {"espece": "chat", "poil": [0.12, 0.12, 0.13], "interieur": [0.55, 0.45, 0.45], "pointe": BLANC},
			"teinte": PEAU[2], "humeur_base": 0.2, "traits": {"bavard": 0.3, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"sardine": 2.0, "canne_peche": 2.0}, "deteste": {"vieille_botte": -0.5},
			"repliques": {
				"accueil": [L("Chut. Tu vas faire fuir le Roi des mares. … Moustache. Pêcheur. Assieds-toi, ne bouge pas, et regarde le bouchon. C'est tout ce qu'il y a à faire, et c'est déjà beaucoup.", {"visites_max": 1}), L("Chut. Il est là. Je le sens dans mes moustaches.", {"visites_min": 2})],
				"humeur": [L("Patient.", {})],
				"lui": [L("Quarante ans que je pêche sur ce ponton. J'ai attrapé des sardines, des perches, une vieille botte et un rhume. Le Roi des mares, jamais. Un jour.", {}), L("Le Roi des mares est doré, gros comme un lapin, et il me regarde. Je le jure. Il me regarde et il rit. Les poissons, ça rit sous l'eau, on ne l'entend pas.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les mares de la forêt sont reliées sous la terre, dit Mère-Lune. Un poisson qui plonge ici remonte là-bas. C'est pour ça que le Roi des mares est partout et nulle part.", {})],
				"rumeur": [L("Les enfants disent qu'il y a un dragon sous la grande mare. C'est le Roi des mares. Il grandit un peu chaque fois qu'on en parle.", {}, "rire")],
				"interpelle": [L("Chut.", {"visites_max": 0}), L("Chut, {surnom}.", {"visites_min": 1})],
			}},
		{"id": "eclair", "nom": "Éclair", "titre": "coureuse", "maison": "porte_guet_1",
			"agenda": [[8, 12, "jeux_echauffement_3"], [12, 14, ["marche_client_2", "simples_client"]], [14, 19, "jeux_echauffement_1"], [19, 20, ["marche_client_1", "jeux_banc_1"]], [20, 1, "cercle_danse_4"], [1, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "queue", "haut": [0.15, 0.15, 0.2], "yeux": [0.3, 0.55, 0.85]},
			"kemo": {"espece": "chat", "poil": BLANC, "interieur": ROSE, "pointe": [0.25, 0.25, 0.28]},
			"teinte": PEAU[5], "humeur_base": 0.3, "traits": {"bavard": 0.2, "humour": 0.4, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"brochette_poisson": 2.0, "coupe_course": 2.0}, "deteste": {"pain_carotte": -0.5},
			"repliques": {
				"accueil": [L("… Éclair. Je cours. Je ne parle pas beaucoup. Je cours.", {"visites_max": 1}), L("Toi. Tu cours, aujourd'hui ?", {"visites_min": 2})],
				"humeur": [L("Concentrée.", {})],
				"lui": [L("Les chats ne courent pas longtemps. Mais vite. Très vite. Le dernier virage, avant le Guet : c'est là que je passe Bondi. Un jour.", {}), L("Je m'entraîne la nuit, quand tout le monde danse. Bondi croit que personne ne le sait. Tout le monde le sait.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Il y a des chats à Tazira aussi. Des chats tout entiers, sans gens autour. Ils volent des cartes aux pirates. Je les aime bien.", {})],
				"rumeur": [L("Grisou parle beaucoup. Il court moins.", {})],
				"interpelle": [L("…", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "myrtille", "nom": "Myrtille", "titre": "petite chatte de la pêcherie", "maison": "porte_pecherie",
			"agenda": [[8, 12, "cercle_enfants_2", ["cercle_enfants_1"]], [12, 13, "peche_client"], [13, 18, "jeux_enfants_2", ["jeux_enfants_1"]], [18, 21, ["cercle_banc_8", "jeux_banc_2"]], [21, 8, "maison"]],
			"azur": {"cheveux": [0.45, 0.45, 0.5], "coiffure": "carre", "haut": [0.5, 0.3, 0.6], "robe": [0.3, 0.25, 0.5], "yeux": [0.4, 0.7, 0.3], "taille": 0.66},
			"kemo": {"espece": "chat", "poil": [0.45, 0.45, 0.5], "interieur": ROSE, "pointe": BLANC},
			"teinte": PEAU[1], "humeur_base": 0.7, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"brochette_poisson": 2.5, "gateau_lune": 2.0, "glace": 2.0}, "deteste": {"pelle": -0.3},
			"repliques": {
				"accueil": [L("Mrrrou ! Tu sens bizarre. Pas mauvais. Bizarre. Moi c'est Myrtille. Mon papy, c'est Moustache. Il cherche le Roi des mares. Moi aussi, mais je cherche mieux.", {"visites_max": 1}, "rire"), L("Mrrrou ! T'as vu le Roi des mares ? Non ? Moi presque.", {"visites_min": 2})],
				"humeur": [L("Joueuse !", {}, "rire")],
				"lui": [L("Je sais grimper jusqu'au premier plancher sans l'escalier. Maman ne veut pas. Alors je prends l'escalier. En courant.", {}, "rire")],
				"ile": [L("Mochi dit que c'est un dragon-poisson, sous la mare. Gland dit que c'est un dragon. Moi je dis que c'est le Roi des mares, et qu'il a une couronne.", {})],
				"rumeur": [L("La nuit, les oreilles de tout le monde brillent un peu. Même les miennes ! Regarde quand il fera noir.", {})],
				"interpelle": [L("Mrrrou !", {"visites_max": 0}), L("Mrrrou, {surnom} !", {"visites_min": 1})],
			}},
		# ================================================================ les loups : le Guet
		{"id": "crocgris", "nom": "Croc-Gris", "titre": "garde du Guet", "maison": "porte_vigie",
			"agenda": [[6, 13, "guet_vigie"], [13, 14, "boul_client"], [14, 20, "guet_vigie"], [20, 1, ["cercle_banc_8", "cercle_banc_4"]], [1, 6, "maison"]],
			"azur": {"cheveux": [0.36, 0.36, 0.4], "coiffure": "court", "haut": [0.3, 0.28, 0.22], "yeux": [0.75, 0.6, 0.15], "carrure": 1.15, "foulard": [0.55, 0.12, 0.1]},
			"kemo": {"espece": "loup", "poil": [0.36, 0.36, 0.4], "interieur": [0.7, 0.62, 0.6], "queue": 1.1},
			"teinte": PEAU[3], "humeur_base": 0.0, "traits": {"bavard": 0.3, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"brochette_poisson": 2.0, "miel": 1.0}, "deteste": {"sifflet_muet": -1.0},
			"repliques": {
				"accueil": [L("Halte. … Bon, tu as l'air inoffensif. Croc-Gris, garde du Guet. D'en haut, je vois toute la forêt, et toute la forêt sait que je la vois. Bienvenue à Ramure. Ne fais pas de bêtises.", {"visites_max": 1}), L("{surnom}. Rien à signaler. Comme d'habitude.", {"visites_min": 2})],
				"humeur": [L("Vigilant.", {}), L("Le soir, je descends au Cercle. Même un garde a le droit d'écouter les tambours. Grisou me remplace. Enfin, il essaie.", {"soir": true})],
				"lui": [L("Les loups veillent sur Ramure depuis que Mère-Lune est arrivée. Elle était louve, elle aussi, et pisteuse. Les loups l'ont suivie. On la suit encore.", {}), L("La tyrolienne, là-haut ? C'est pour descendre vite, en cas d'alerte. En vrai, ce sont surtout les enfants qui s'en servent. Et Grisou.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Du Guet, par temps clair, on voit le dirigeable de Cliquetis arriver du nord. Il fait un bruit de bourdon. Les lapins se cachent à chaque fois.", {})],
				"rumeur": [L("Brume a trouvé des traces étranges près de la grande mare. Pas des pattes. Pas des pieds. Des traces rondes. Elle cherche encore.", {})],
				"interpelle": [L("Halte.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "grisou", "nom": "Grisou", "titre": "coureur", "maison": "porte_guet_2",
			"agenda": [[7, 12, "jeux_echauffement_2"], [12, 16, "guet_2"], [16, 19, "jeux_echauffement_3"], [19, 20, ["forge_client", "marche_client_3"]], [20, 1, "cercle_danse_5"], [1, 7, "maison"]],
			"azur": {"cheveux": GRIS_LOUP, "coiffure": "boucles", "haut": [0.85, 0.5, 0.15], "yeux": [0.55, 0.45, 0.2]},
			"kemo": {"espece": "loup", "poil": GRIS_LOUP, "interieur": [0.8, 0.72, 0.7], "queue": 1.2},
			"teinte": PEAU[2], "humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"brochette_poisson": 2.0, "coupe_course": 3.0}, "deteste": {"pain_carotte": -0.5},
			"repliques": {
				"accueil": [L("Salut ! Grisou ! Le prochain champion de la Grande Course ! Cette fois, je bats Bondi. Je le sens. Je le sens dans mes pattes. Mes pattes le sentent aussi.", {"visites_max": 1}, "rire"), L("Hé ! Tu as vu ma dernière course ? Deuxième ! Presque premier ! Enfin… deuxième.", {"visites_min": 2}, "rire")],
				"humeur": [L("Gonflé à bloc !", {}, "rire")],
				"lui": [L("Les loups, c'est l'endurance. On court longtemps. La Grande Course est trop courte pour un loup, voilà le problème. Il faudrait qu'elle fasse le tour de l'île.", {}), L("Je remplace Croc-Gris au Guet l'après-midi. Je surveille la forêt. Bon, je surveille surtout la Clairière des Jeux. Pour voir comment Bondi s'entraîne.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Il paraît qu'à Cliquetis, ils ont des chaussures à ressorts. Si j'en avais… Non. Pépin dirait que c'est de la triche. Pépin a raison. Mais quand même.", {})],
				"rumeur": [L("Éclair ne dit jamais rien, mais elle me regarde comme si j'étais une brochette. Je n'aime pas ça.", {})],
				"interpelle": [L("Salut !", {"visites_max": 0}), L("{surnom} ! On fait la course ?", {"visites_min": 1})],
			}},
		{"id": "brume", "nom": "Brume", "titre": "pisteuse", "maison": "porte_guet_1",
			"agenda": [[6, 10, "aire_zephyr"], [10, 12, "guet_2"], [12, 16, "ponton_1"], [16, 19, "aire_zephyr"], [19, 20, "marche_client_4"], [20, 1, "cercle_danse_6"], [1, 6, "maison"]],
			"azur": {"cheveux": [0.82, 0.84, 0.88], "coiffure": "long", "haut": [0.25, 0.32, 0.3], "yeux": [0.4, 0.6, 0.75]},
			"kemo": {"espece": "loup", "poil": [0.82, 0.84, 0.88], "interieur": [0.85, 0.8, 0.8], "pointe": [0.45, 0.48, 0.55], "queue": 1.2},
			"teinte": PEAU[5], "humeur_base": 0.2, "traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"plume_corbeau": 2.0, "boussole": 2.0, "fiole_brume": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Tu arrives de l'ouest. Tes bottes sentent la lande et le sel. Brume, pisteuse de Ramure. Je lis les traces comme d'autres lisent des livres.", {"visites_max": 1}), L("Tu es passé par les mares du nord. Il y a de la vase sur ta botte gauche. Bonjour, {surnom}.", {"visites_min": 2})],
				"humeur": [L("Attentive.", {}), L("La nuit, la brume monte des mares. C'est mon heure. C'est pour ça que je m'appelle Brume.", {"soir": true})],
				"lui": [L("Mère-Lune m'a appris à pister. Elle disait : une trace, c'est une phrase. Plusieurs traces, c'est une histoire. Beaucoup de traces, c'est Bedaine qui fait ses courses.", {}, "rire"), L("Près de la grande mare, j'ai trouvé des traces rondes, comme des pas de pierre. Elles vont jusqu'à l'eau, et elles s'arrêtent. Rien ne sort de l'eau. Je surveille.", {"sujet_min": ["lui", 1]})],
				"ile": [L("J'ai pisté jusqu'au pied du Cœur-de-Pierre, au centre de l'île. Les traces des quatre peuples y vont toutes. Puis plus rien, depuis longtemps. Comme si on avait oublié le chemin.", {})],
				"rumeur": [L("Le dirigeable de Cliquetis se pose maintenant au nord du village, sur l'aire. Les ingénieurs descendent, regardent nos ponts, prennent des notes. Ils trouvent que nos ponts bougent trop. C'est fait pour.", {})],
				"interpelle": [L("…", {"visites_max": 0}), L("{surnom}. Je t'ai senti venir.", {"visites_min": 1})],
			}},
		# ================================================================ les chouettes : la Poste et les étoiles
		{"id": "plumette", "nom": "Plumette", "titre": "postière", "maison": "porte_poste",
			"agenda": [[9, 21, "poste_guichet"], [21, 1, ["cercle_banc_1", "cercle_banc_5"]], [1, 9, "maison"]],
			"azur": {"cheveux": [0.62, 0.5, 0.38], "coiffure": "chignon", "haut": [0.3, 0.38, 0.55], "robe": [0.28, 0.3, 0.42], "yeux": [0.95, 0.72, 0.15], "lunettes": true},
			"kemo": {"espece": "chouette", "poil": [0.62, 0.5, 0.38], "pointe": [0.92, 0.88, 0.8], "interieur": [0.85, 0.78, 0.68]},
			"teinte": PEAU[0], "humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"gland_dore": 2.0, "carte_postale": 2.0, "tisane_brume": 1.5}, "deteste": {"sifflet_muet": -0.5},
			"repliques": {
				"accueil": [L("Hou ! Bonjour ! Plumette, postière de Ramure. Courrier pour les arbres, courrier pour les mares, courrier pour les autres villes. Tout part de la cime du Chêne-Mère. Tu as une lettre ? Non ? Écris-en une, voyons !", {"visites_max": 1}, "salut"), L("Hou ! Rien pour toi aujourd'hui. Mais demain, peut-être.", {"visites_min": 2})],
				"humeur": [L("Un peu ensommeillée… Les chouettes, le jour, c'est comme les lapins la nuit.", {}), L("Hou ! Enfin la nuit ! Je me sens toute neuve.", {"soir": true}, "rire")],
				"lui": [L("Je porte les lettres d'arbre en arbre, de cabane en cabane. Je connais toutes les portes de Ramure. Et tous les secrets. Mais une postière ne dit rien. Hou.", {}), L("Les glands d'or ? Pomme-de-Pin en trouve, parfois, au sommet des plus vieux chênes. Les chouettes les adorent. Pour un gland d'or, je donnerais… une plume de lune, tiens.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Je reçois des lettres de Port-Azur, apportées par les bateaux. Des cartes postales avec la mer bleue. Ici, la mer est grise de brume, mais elle est à nous.", {})],
				"rumeur": [L("Une lettre est arrivée de Cliquetis pour Pépin. Elle fait « tic-tac ». Je ne l'ai pas ouverte. Je l'ai juste écoutée.", {}, "rire")],
				"interpelle": [L("Hou !", {"visites_max": 0}), L("Hou, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "hulotte", "nom": "Hulotte", "titre": "astronome", "maison": "porte_poste",
			"agenda": [[6, 14, "maison"], [14, 18, ["cercle_banc_2", "jeux_banc_1"]], [18, 6, "poste_vue"]],
			"azur": {"cheveux": [0.42, 0.34, 0.26], "coiffure": "court", "haut": [0.2, 0.18, 0.3], "yeux": [0.98, 0.6, 0.1], "lunettes": true, "vieux": true},
			"kemo": {"espece": "chouette", "poil": [0.42, 0.34, 0.26], "pointe": [0.85, 0.78, 0.65], "interieur": [0.75, 0.66, 0.55]},
			"teinte": PEAU[1], "humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.4, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"boussole": 2.0, "montre_envers": 2.0, "tisane_lune": 1.5}, "deteste": {},
			"repliques": {
				"accueil": [L("Hm ? Oh, un visiteur. Hulotte, astronome. Chaque nuit, je monte à la cime et je compte les étoiles. J'en suis à quatre mille deux cent douze. Ou treize. Tu m'as fait perdre le compte.", {"visites_max": 1}), L("Hou… Tu viens regarder le ciel ? Il est très beau, ce soir. Il est très beau tous les soirs.", {"visites_min": 2})],
				"humeur": [L("Le jour, je dors debout. Excuse-moi.", {}), L("Éveillé ! Les étoiles se lèvent, moi aussi.", {"soir": true})],
				"lui": [L("La lune au-dessus de Ramure est toujours pleine. J'ai vérifié trois mille nuits. Ailleurs, elle maigrit, elle grossit. Ici, non. Je n'ai aucune explication. C'est la plus belle chose que je connaisse.", {}), L("J'ai vu une étoile tomber dans la grande mare, il y a quarante nuits. Elle n'est jamais ressortie. Brume a vu des traces rondes, depuis. Je fais des calculs.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les ingénieurs de Cliquetis ont une grande lunette, paraît-il. Une astronome là-bas, Céleste, m'écrit. Elle dit que notre lune est une illusion. Je lui ai répondu de venir voir.", {})],
				"rumeur": [L("Les enfants croient que je vole. Je les laisse croire. En vrai, je prends l'escalier. Très lentement.", {}, "rire")],
				"interpelle": [L("Hou…", {"visites_max": 0}), L("{surnom}, regarde le ciel.", {"visites_min": 1})],
			}},
		# ================================================================ les écureuils : les ponts
		{"id": "pommedepin", "nom": "Pomme-de-Pin", "titre": "charpentière des ponts", "maison": "porte_ouest_2",
			"agenda": [[7, 12, "charpente_1"], [12, 13, "marche_client_1"], [13, 19, "charpente_2"], [19, 20, "boul_client"], [20, 23, ["cercle_banc_3", "cercle_banc_7"]], [23, 7, "maison"]],
			"azur": {"cheveux": [0.72, 0.36, 0.14], "coiffure": "queue", "haut": [0.5, 0.55, 0.3], "tablier": [0.4, 0.3, 0.2], "yeux": [0.35, 0.22, 0.1]},
			"kemo": {"espece": "ecureuil", "poil": [0.72, 0.36, 0.14], "pointe": [0.8, 0.45, 0.2], "interieur": [0.92, 0.78, 0.62], "queue": 1.2},
			"teinte": PEAU[2], "humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"caillou_chantant": 2.5, "noisette": 3.0, "pomme": 1.0}, "deteste": {"hache": -0.5},
			"repliques": {
				"accueil": [L("Coucou, coucou ! Pomme-de-Pin ! Charpentière ! Tous les ponts de Ramure, c'est moi ! Enfin, moi et ma famille. Et ma grand-mère. Surtout ma grand-mère. Ils bougent un peu ? C'est normal ! C'est fait pour !", {"visites_max": 1}, "rire"), L("Coucou ! Tu as traversé le pont de l'ouest ? Il chante quand le vent souffle. Je l'ai fait exprès.", {"visites_min": 2}, "rire")],
				"humeur": [L("Pleine d'énergie ! Comme toujours !", {}, "rire")],
				"lui": [L("Un pont de corde, il faut qu'il danse avec le vent. Un pont raide, ça casse. Un pont qui danse, ça dure cent ans. Comme les vieux écureuils.", {}), L("Les cailloux-qui-chantent, tu connais ? Quand le vent passe dedans, ils sifflent. J'en accroche sous les ponts pour savoir quand le vent forcit. Pour un caillou-qui-chante, je donnerais mon plus beau gland d'or !", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les ingénieurs de Cliquetis ont regardé mes ponts. Ils voulaient les remplacer par des ponts de métal. Je leur ai demandé si le métal savait danser. Ils sont repartis.", {}, "rire")],
				"rumeur": [L("Gland, mon petit frère, a caché trois cents noisettes quelque part dans le Chêne-Mère. Il ne sait plus où. Moi non plus. L'arbre, peut-être.", {}, "rire")],
				"interpelle": [L("Coucou !", {"visites_max": 0}), L("Coucou, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "gland", "nom": "Gland", "titre": "petit frère de Pomme-de-Pin", "maison": "porte_ouest_2",
			"agenda": [[8, 12, "jeux_enfants_1", ["jeux_enfants_2"]], [12, 13, ["marche_client_2", "marche_client_3"]], [13, 18, "cercle_enfants_2", ["cercle_enfants_1"]], [18, 21, ["jeux_banc_1", "cercle_banc_6"]], [21, 8, "maison"]],
			"azur": {"cheveux": [0.75, 0.38, 0.15], "coiffure": "boucles", "haut": [0.3, 0.6, 0.35], "yeux": [0.35, 0.22, 0.1], "taille": 0.66},
			"kemo": {"espece": "ecureuil", "poil": [0.75, 0.38, 0.15], "pointe": [0.82, 0.47, 0.2], "interieur": [0.92, 0.78, 0.62], "queue": 1.3},
			"teinte": PEAU[2], "humeur_base": 0.8, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"noisette": 3.0, "gateau_lune": 2.0, "glace": 2.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Coucou ! T'as des noisettes ? Non ? Dommage. Moi c'est Gland. J'en ai caché trois cents. Je sais plus où. Tu m'aides à chercher ?", {"visites_max": 1}, "rire"), L("Coucou ! J'ai retrouvé une noisette ! Il en reste deux cent quatre-vingt-dix-neuf !", {"visites_min": 2}, "rire")],
				"humeur": [L("Tout fou !", {}, "rire")],
				"lui": [L("Plus tard je ferai des ponts, comme Pomme-de-Pin. Des ponts jusqu'à la lune. Elle est pleine tout le temps, alors elle a le temps d'attendre.", {})],
				"ile": [L("Sous la grande mare, il y a un dragon ! Un vrai ! Mochi dit que c'est un dragon-poisson, mais c'est n'importe quoi.", {})],
				"rumeur": [L("La tyrolienne du Guet, c'est trop bien ! Croc-Gris dit que c'est pour les alertes. Moi je fais une alerte tous les jours.", {}, "rire")],
				"interpelle": [L("Coucou !", {"visites_max": 0}), L("Coucou, {surnom} !", {"visites_min": 1})],
			}},
		# ================================================================ les biches : la danse
		{"id": "lilas", "nom": "Lilas", "titre": "danseuse de la lune", "maison": "porte_mares_2",
			"agenda": [[8, 12, "jeux_banc_2"], [12, 16, ["marche_client_3", "simples_client"]], [16, 20, "cercle_danse_1"], [20, 1, "cercle_danse_1"], [1, 8, "maison"]],
			"azur": {"cheveux": [0.68, 0.48, 0.3], "coiffure": "long", "haut": [0.92, 0.88, 0.78], "robe": [0.55, 0.7, 0.45], "robe_longue": true, "yeux": [0.3, 0.2, 0.1]},
			"kemo": {"espece": "biche", "poil": [0.7, 0.5, 0.32], "pointe": BLANC, "interieur": [0.95, 0.85, 0.78]},
			"teinte": PEAU[1], "humeur_base": 0.6, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"clochette_argent": 2.5, "fleur_lune": 2.0, "gateau_lune": 1.5}, "deteste": {"vieille_botte": -0.5},
			"repliques": {
				"accueil": [L("Oh… bonjour. Je suis Lilas. Je danse au Cercle, chaque nuit, pour la lune. Viens ce soir, après vingt heures. Tu verras le feu, tu entendras les tambours, et tu auras envie de danser. Tout le monde a envie.", {"visites_max": 1}, "salut"), L("Bonjour, {surnom}. Tu viendras danser, ce soir ?", {"visites_min": 2})],
				"humeur": [L("Légère.", {}), L("C'est l'heure ! Mes sabots ne tiennent plus en place.", {"soir": true}, "rire")],
				"lui": [L("Les biches ne savent ni forger, ni pêcher, ni troquer. Mais quand on danse, le village entier oublie sa fatigue. C'est un métier aussi, je crois.", {}), L("La danse de la lune raconte l'histoire de la louve qui a sauvé la lune tombée dans la mare. Le moment où elle la ressort de l'eau… c'est le moment où tout le monde lève les bras. Tu verras.", {"sujet_min": ["lui", 1]})],
				"ile": [L("À Tazira, ils dansent aussi, sur la place, chaque soir. Roux m'a montré leurs pas. On dirait une danse de chèvre. Je l'ai apprise quand même.", {}, "rire")],
				"rumeur": [L("Pépin tape trop fort sur son tambour. Bourru tape trop lentement. Ensemble, ça fait exactement le bon rythme. C'est un mystère.", {}, "rire")],
				"interpelle": [L("Bonsoir…", {"visites_max": 0}), L("{surnom}…", {"visites_min": 1})],
			}},
	]


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out

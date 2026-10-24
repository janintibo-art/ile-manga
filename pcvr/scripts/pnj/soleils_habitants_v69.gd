extends RefCounted
## V69 : les gens de l'Île des Trois Soleils. Trois peuples, trois villages :
##  - Per-Hâpy (les Égyptiens, sur l'Iterou) : Néferet la prêtresse de Rê, Amenemhat le maître
##    scribe, Khéty le pêcheur, Mérit la boulangère-brasseuse, Ptahmosé le potier, Hapou le
##    paysan, Tiyi la tisserande et sa fille Nebet ;
##  - Yaxché (les Mayas, dans la jungle) : Ix Kanul la grande prêtresse de Kukulkan, Ah Kin Pech
##    l'astronome, Balam le chasseur, Ix Sak la tisserande, Chak le joueur de balle, Yum Kab
##    l'apiculteur, Ix Chab la marchande de cacao, et Kinich, le garçon au moustique ;
##  - Aztlán (les Aztèques, sur le lac) : Cuauhtli le grand prêtre, Citlali la maîtresse du
##    calmecac, Mixtli le guerrier-jaguar, Xóchitl la jardinière des chinampas, Tochtli le
##    marchand, Coyotl le potier, Nenetl la musicienne, et Pilli, le garçon au chien xolo.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd ; postures et parures en plus : pnj_soleils_v69.gd).
## Fiche « village » : egypte | maya | azteque (les lieux : per_hapy_v69, yaxche_v69, aztlan_v69).
## Fiche « sol » : les parures (usekh, plumes [r,g,b], jade, baton, eventail, bouclier,
## jaguar, chat, chien, tenue : pretre | scribe | peuple | guerrier | enfant).

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Que le soleil te garde, {surnom}.", "si": {}, "geste": "salut"},
		{"t": "Va en paix. Et bois de l'eau : le soleil d'ici ne pardonne pas.", "si": {}},
		{"t": "À bientôt. Les dieux regardent, alors marche droit.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit. Le soleil voyage sous le monde, mais il reviendra.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Tu frappes un habitant sous les yeux des dieux ? Ils ne l'oublieront pas. Moi non plus.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Ça ne se fait pas ! Va donc te battre contre les bêtes de la jungle !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Merci. Je le poserai près de l'autel de la maison.", "si": {}},
		{"t": "C'est gentil. Chez nous, un cadeau appelle un cadeau. Je m'en souviendrai.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Oh… Les dieux t'ont soufflé ce qui me ferait plaisir !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un vrai cadeau ! Merci, {surnom}. Mon cœur est léger comme une plume de Maât.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Hum… Tu sais, ce n'est pas vraiment… Enfin, merci quand même.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la : dans la jungle et sous les temples, tu en auras besoin.", "si": {}}],
	"blague": [
		{"t": "Pourquoi le scribe ne se perd jamais ? Parce qu'il a toujours le bon signe sous la main !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'une pyramide avec un rhume ? Une pyra-mouche ! … Les enfants l'adorent, celle-là.", "si": {}, "geste": "rire"},
		{"t": "Un jaguar entre au marché. Le marchand demande : « Je peux vous aider ? » Le jaguar répond : « Non merci, je regarde. » Et il regarde le marchand.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis. Tout est fait ici, sous le soleil. Tu as {pieces} pièces.", "si": {}}],
	"achat": [{"t": "{objet}, {prix} pièces. Que les dieux te le rendent en santé.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "{prix} pièces, et tu n'en as que {pieces}. Reviens quand ta bourse aura grossi.", "si": {}}],
	"vente": [{"t": "{objet} ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout ? D'accord : {prix} pièces pour le lot.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Le prix est juste, comme la plume de Maât. On ne discute pas avec Maât.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Ah, quelle joie !", "Par le soleil !", "Merveilleux !", "Les dieux sont bons !"],
		"neutre": ["Hm.", "Voyons…", "Bien.", "Écoute…"],
		"triste": ["Hélas…", "Ah…", "Que les dieux nous gardent…", "Pff."],
		"colere": ["Par la barbe d'Osiris !", "Ça suffit !", "Écoute-moi bien.", "Grr."],
	},
	"tics": ["Par le soleil.", "Comme disaient les anciens.", "Les dieux le savent.", "Ainsi soit-il."],
	"humeur_mots": [[0.6, "rayonnant"], [0.25, "de bonne humeur"], [-0.25, "soucieux"], [-0.6, "contrarié"], [-2.0, "en colère"]],
	"surnoms": [[0, "étranger"], [25, "voyageur"], [50, "ami"], [75, "frère du soleil"], [95, "enfant des Trois Soleils"]],
}

const PEAU := [[0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.74, 0.53, 0.38], [0.66, 0.46, 0.34], [0.56, 0.38, 0.27], [0.46, 0.31, 0.22]]
const NOIR := [0.06, 0.05, 0.045]
const BRUN := [0.14, 0.09, 0.06]


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
	out["groupe"] = "soleils"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ Per-Hâpy (les Égyptiens)
		{"id": "neferet", "nom": "Néferet", "titre": "prêtresse de Rê", "maison": "porte_neferet", "village": "egypte",
			"agenda": [[6, 8, "temple_autel"], [8, 11, ["temple_cour_1", "temple_porte"]], [11, 13, "jardin_pretresse"], [13, 17, ["temple_autel", "vallee_priere"]], [17, 20, "temple_autel"], [20, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": [0.25, 0.18, 0.1], "haut": [0.95, 0.93, 0.86]},
			"tz": {"foulard_tete": [0.94, 0.9, 0.8]},
			"sol": {"tenue": "pretre", "usekh": [0.85, 0.65, 0.2], "baton": "ankh"},
			"teinte": PEAU[2], "humeur_base": 0.25, "traits": {"bavard": 0.55, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"scarabee": 2.0, "dattes": 1.5, "perle": 2.0, "oeil_horus": 3.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Sois le bienvenu à Per-Hâpy, étranger. Je suis Néferet, prêtresse de Rê. Chaque matin, je salue le soleil quand il renaît à l'est. Chaque soir, je le pleure quand il meurt à l'ouest. Entre les deux, je réponds aux questions des voyageurs.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Le soleil est haut ; Rê a gagné sa bataille de la nuit. Que veux-tu savoir ?", {"visites_min": 2}),
				],
				"humeur": [L("Sereine. Le fleuve est calme, la crue sera bonne.", {}), L("La nuit vient. Rê entre dans la Douat, le monde d'en dessous. Douze heures de voyage, douze portes, et Apophis qui guette.", {"soir": true})],
				"lui": [
					L("Je suis entrée au temple à sept ans. J'y ai appris les hymnes, les heures, et la patience. Surtout la patience : les dieux ne sont jamais pressés.", {}),
					L("Ma mère était prêtresse avant moi. Elle disait : « Le soleil meurt chaque soir et renaît chaque matin. Toi aussi, tu peux recommencer chaque matin. »", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Sur le plateau, au sud du fleuve, se dresse la Pyramide de Rê. On dit qu'on y refait, sous la pierre, le voyage du soleil dans la nuit. Mais le Sphinx garde la porte, et il ne laisse passer que ceux qui savent répondre.", {}),
					L("Le soleil, chez nous, a trois visages : Khépri le scarabée qui le pousse au matin, Rê qui brille à midi, Atoum le vieillard qui se couche le soir. Retiens-le : le Sphinx aime ce genre de choses.", {"sujet_min": ["ile", 1]}),
					L("Dans la pyramide, il faudra affronter la pesée du cœur. Devant Anubis, on ne se vante pas : on dit le mal qu'on n'a PAS fait. « Je n'ai pas volé. Je n'ai pas menti. » Un cœur plus lourd que la plume de Maât… Ammit le dévore.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Amenemhat prétend avoir lu tous les papyrus de la Maison de Vie. Tous. Même ceux qu'il a écrits lui-même. Surtout ceux-là.", {}, "rire"), L("Les Mayas de Yaxché et les Aztèques d'Aztlán ont eux aussi leur soleil. Trois peuples, trois soleils. Les anciens disaient qu'un jour quelqu'un les réunirait sur l'autel des hautes terres.", {})],
				"interpelle": [L("Étranger ! Le soleil t'a mené jusqu'ici.", {"visites_max": 0}), L("{surnom} ! Viens, approche.", {"visites_min": 1})],
			}},
		{"id": "amenemhat", "nom": "Amenemhat", "titre": "maître scribe de la Maison de Vie", "maison": "porte_ecole", "village": "egypte",
			"agenda": [[7, 12, "ecole_maitre"], [12, 14, ["place_3", "biere_2"]], [14, 18, "ecole_maitre"], [18, 21, ["biere_1", "temple_cour_2"]], [21, 7, "maison"]],
			"azur": {"cheveux": [0.55, 0.53, 0.5], "coiffure": "chauve", "vieux": true, "yeux": [0.25, 0.2, 0.15], "haut": [0.94, 0.92, 0.85]},
			"sol": {"tenue": "scribe", "usekh": [0.2, 0.35, 0.6], "palette": true},
			"teinte": PEAU[2], "humeur_base": 0.3, "traits": {"bavard": 0.9, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"papyrus_thot": 2.0, "grimoire": 2.5, "livre_envole": 2.0, "biere_heqet": 1.5}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"papyrus_thot": 12}, "achete": {"grimoire": 20, "livre_envole": 15, "carte_tresor": 10}},
			"repliques": {
				"accueil": [
					L("Ah ! Un visiteur ! Amenemhat, maître scribe de la Maison de Vie. Je sais lire sept cents signes, en écrire six cent quatre-vingt-dix-huit, et j'invente les deux qui manquent. Tu sais lire ? Non ? Ce n'est pas grave. Moi, je parle.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Assieds-toi, j'ai une histoire. J'ai toujours une histoire.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Excellent ! J'ai trouvé une faute dans un papyrus. Une faute à moi. C'est comme ça qu'on progresse.", {}, "rire"), L("Le jour baisse. On ne lit pas à la lampe : l'huile coûte cher, et les signes se mettent à danser.", {"soir": true})],
				"lui": [
					L("Thot, le dieu à tête d'ibis, a inventé l'écriture. C'est lui qui note la pesée du cœur, au jour du jugement. Un scribe, c'est un petit Thot avec des mains tachées d'encre.", {}),
					L("J'ai appris mes signes en recopiant le même conte trois cents fois. Je le sais encore par cœur. Tu veux l'entendre ? … Une autre fois, alors.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le Sphinx du plateau pose trois devinettes. La première est vieille comme le monde : qui marche à quatre pattes le matin, sur deux à midi, sur trois le soir ? Pense à toute une vie, pas à une journée.", {}),
					L("Dans un cartouche royal, on lit de haut en bas : d'abord le dieu qui écrit, puis celui qui veille, enfin celui qui brille. L'ibis de Thot, l'œil d'Horus, le disque de Rê. N'importe quel apprenti le sait. Enfin… le devrait.", {"sujet_min": ["ile", 1]}),
					L("Osiris fut tué par son frère Seth, jaloux, et son corps coupé en morceaux, dispersés dans tout le pays. Isis, son épouse, les a cherchés un à un, et les a réunis. C'est ainsi qu'Osiris est devenu le roi des morts.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Khéty jure qu'il a vu un crocodile long comme une barque près de l'embouchure. Khéty jure beaucoup. Mais là, il avait l'air sincère.", {}), L("Mérit fait la meilleure bière du fleuve. Ne lui dis pas que je l'ai dit : elle augmenterait ses prix.", {}, "rire")],
				"interpelle": [L("Toi ! Tu as une tête à aimer les histoires.", {"visites_max": 0}), L("{surnom} ! J'ai lu quelque chose sur toi. Non, je plaisante.", {"visites_min": 1}, "rire")],
			}},
		{"id": "kheti", "nom": "Khéty", "titre": "pêcheur du fleuve", "maison": "porte_kheti", "village": "egypte",
			"agenda": [[5, 11, ["quai_peche_1", "quai_peche_2"]], [11, 13, "etal_poisson"], [13, 17, ["quai_peche_1", "quai_flane"]], [17, 20, ["biere_1", "etal_poisson"]], [20, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "", "yeux": [0.22, 0.16, 0.1], "haut": [0.9, 0.86, 0.76]},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[3], "humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.2, "rancunier": 0.2},
			"aime": {"sardine": 1.0, "bar": 1.5, "dorade": 1.5, "biere_heqet": 2.0}, "deteste": {"poisson_lune": -0.5},
			"boutique": {"vend": {"sardine": 3}, "achete": {"sardine": 2, "maquereau": 3, "dorade": 4, "bar": 4, "merou": 6}},
			"repliques": {
				"accueil": [L("Salut, l'étranger ! Khéty, pêcheur. Le fleuve me donne mes poissons, je lui donne mes chansons. Il préfère les poissons, je crois.", {"visites_max": 1}, "rire"), L("{surnom} ! Ça mord, aujourd'hui. Enfin, ça grignote.", {"visites_min": 2}, "rire")],
				"humeur": [L("Content. J'ai pris une perche grosse comme mon bras. Bon, mon bras n'est pas gros.", {}, "rire"), L("Le soir, les crocodiles sortent. Je rentre ma barque, et mes orteils.", {"soir": true})],
				"lui": [L("Mon père pêchait, mon grand-père pêchait, et le père de mon grand-père… il nageait, surtout. Il est tombé de la barque.", {}, "rire"), L("Ma barque est en papyrus. Légère comme une feuille, solide comme une promesse. Et quand elle est vieille, on la brûle et on en fait une autre.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Près de l'embouchure, il y a des crocodiles. Un, surtout, énorme, qui vole nos filets. Hapou dit qu'il a mangé une chèvre. Moi je dis qu'il a mangé deux chèvres et la moitié d'une barque.", {}), L("Le fleuve monte chaque année. Les anciens disent que ce sont les larmes d'Isis qui pleure Osiris. Moi je dis que c'est la pluie dans les montagnes. Mais je ne le dis pas trop fort devant Néferet.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("La petite Nebet a perdu son chat. Elle pleure toute la journée. Le chat, lui, doit se promener tranquillement chez les morts, sur le plateau. Les chats aiment les tombeaux : il y fait frais.", {}), L("Mérit et Ptahmosé se disputent pour savoir qui a le plus beau four. Ce sont des fours. Ils se ressemblent.", {}, "rire")],
				"interpelle": [L("Hé ! Tu veux du poisson frais ?", {"visites_max": 0}), L("{surnom} ! Viens voir ma prise !", {"visites_min": 1})],
			}},
		{"id": "merit", "nom": "Mérit", "titre": "boulangère et brasseuse", "maison": "porte_merit", "village": "egypte",
			"agenda": [[5, 8, "four"], [8, 13, "etal_pain"], [13, 15, "four"], [15, 19, "etal_pain"], [19, 22, ["biere_2", "biere_1"]], [22, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": [0.3, 0.2, 0.12], "haut": [0.92, 0.88, 0.78], "taille": 0.98},
			"sol": {"tenue": "peuple", "usekh": [0.3, 0.6, 0.55]},
			"teinte": PEAU[3], "humeur_base": 0.4, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"miel": 2.0, "dattes": 1.5, "fleur_lune": 1.5}, "deteste": {"poisson_lune": -0.5},
			"boutique": {"vend": {"pain_egypte": 3, "biere_heqet": 4, "dattes": 3}, "achete": {"miel": 4, "pomme": 1}},
			"repliques": {
				"accueil": [L("Bienvenue, bienvenue ! Mérit. Le pain, c'est moi ; la bière, c'est moi ; les ragots aussi. Du pain chaud ? Il sort du four.", {"visites_max": 1}, "rire"), L("{surnom} ! Ta galette t'attend.", {"visites_min": 2})],
				"humeur": [L("Bonne ! Le four chauffe bien, la pâte lève. Que demander de plus ?", {}), L("Fatiguée. Je me lève avant Rê, moi. Le soleil, au moins, il a des dieux pour tirer sa barque.", {"soir": true}, "rire")],
				"lui": [L("Le pain et la bière, c'est la même chose chez nous : de l'orge, de l'eau, de la patience. L'un se mange, l'autre se boit. Les deux rendent heureux.", {}), L("Les ouvriers de la pyramide, autrefois, étaient payés en pain et en bière. Ma famille les nourrissait. Sans nous, pas de pyramide !", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Les Mayas de Yaxché font une boisson de cacao, mousseuse et amère. J'en ai goûté une fois. J'ai rajouté du miel, ils ont crié au sacrilège.", {}, "rire"), L("Les gens d'Aztlán vivent sur un lac, dans des maisons blanches, et cultivent des jardins qui flottent. Des jardins qui flottent ! Chez nous, c'est le jardin qui se noie, à la crue.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Tiyi, la tisserande, a refusé trois prétendants cette année. Trois ! Elle dit qu'elle préfère son métier à tisser. Je la comprends : lui, au moins, il ne ronfle pas.", {}, "rire"), L("Amenemhat boit sa bière en lisant. Il renverse toujours un peu sur le papyrus. Ses papyrus sentent l'orge.", {}, "rire")],
				"interpelle": [L("Pain chaud ! Bière fraîche !", {"visites_max": 0}), L("{surnom} ! Une galette ?", {"visites_min": 1})],
			}},
		{"id": "ptahmose", "nom": "Ptahmosé", "titre": "potier", "maison": "porte_ptahmose", "village": "egypte",
			"agenda": [[7, 12, "potier"], [12, 14, ["etal_pots", "place_2"]], [14, 18, "potier"], [18, 21, ["biere_1", "place_2"]], [21, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "courte", "yeux": [0.25, 0.18, 0.12], "haut": [0.85, 0.8, 0.7], "taille": 1.04},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[4], "humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"obsidienne": 2.0, "minerai_fer": 1.0, "caillou_chantant": 2.0}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"scarabee": 18}, "achete": {"obsidienne": 6, "caillou": 1}},
			"repliques": {
				"accueil": [L("Hm. Ptahmosé, potier. Khnoum, le dieu bélier, a façonné les hommes sur son tour de potier, comme moi mes jarres. En plus petit. Tu veux une amulette ? Un scarabée de faïence, ça porte chance.", {"visites_max": 1}), L("{surnom}. Tu reviens voir mes pots, ou mes scarabées ?", {"visites_min": 2})],
				"humeur": [L("Correcte. La terre est bonne, le four aussi. Quoi qu'en dise Mérit.", {}), L("Le four refroidit. Moi aussi. Bonne nuit.", {"soir": true})],
				"lui": [L("Le scarabée pousse sa boule de fumier comme Khépri pousse le soleil au matin. Petit, sale, têtu… et il fait se lever le jour. J'aime les scarabées.", {}), L("J'ai fait les jarres de la Maison de Vie, celles du temple, et la grande jarre où Mérit brasse sa bière. Mes jarres ne fuient pas. Ce n'est pas le cas de tous les potiers.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Le potier d'Aztlán, Coyotl, fait des jarres bleues pour Tlaloc, leur dieu de la pluie. Avec des yeux ronds et des crocs. Drôle de goût. Belles jarres, cela dit.", {}), L("Sous la pyramide, il y a des salles à miroirs. Des miroirs de bronze poli, pour mener la lumière dans le noir. C'est un truc d'artisan, ça : la lumière, ça se conduit comme l'eau.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Mérit dit que son four est le meilleur du village. Mon four, je l'ai fait de mes mains. Le sien aussi, d'ailleurs. C'est moi qui l'ai fait.", {}), L("Hapou parle aux crocodiles. Il dit que ça les calme. Moi je dis que ça les fait rire.", {})],
				"interpelle": [L("Hm. Tu regardes mes jarres ?", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "hapou", "nom": "Hapou", "titre": "paysan", "maison": "porte_hapou", "village": "egypte",
			"agenda": [[5, 9, ["chadouf_1", "chadouf_2"]], [9, 13, ["champ_1", "champ_2"]], [13, 15, "place_1"], [15, 19, ["champ_3", "chadouf_1"]], [19, 21, "biere_2"], [21, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "", "yeux": [0.22, 0.16, 0.1], "haut": [0.86, 0.8, 0.68], "taille": 1.02},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[4], "humeur_base": 0.0, "traits": {"bavard": 0.5, "humour": 0.3, "curiosite": 0.3, "susceptible": 0.5, "rancunier": 0.5},
			"aime": {"graines": 2.0, "pain_egypte": 1.0, "biere_heqet": 1.5}, "deteste": {"dent_croco": -0.5},
			"repliques": {
				"accueil": [L("Bonjour. Hapou. Je cultive l'orge, le blé et le lin, sur la rive sud. Et je chasse les crocodiles de mes champs. Surtout ça, ces temps-ci.", {"visites_max": 1}), L("{surnom}. Les crocodiles, toujours là.", {"visites_min": 2})],
				"humeur": [L("Inquiet. Un crocodile a encore piétiné mon blé. Et mangé mon chien. Non, je plaisante, il a mangé la niche. Le chien a eu chaud.", {}), L("La journée est finie. Les crocodiles, eux, commencent la leur.", {"soir": true})],
				"lui": [L("Hapy, c'est le dieu de la crue. Moi c'est Hapou. Mon père trouvait ça drôle. Moi, je dois expliquer tous les jours que je ne fais pas monter le fleuve.", {}), L("Le chadouf, tu vois ? Un poteau, une perche, un seau, un contrepoids de terre. On remonte l'eau du fleuve sans se casser le dos. Enfin, moins.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les crocodiles viennent de l'embouchure, à l'est. Ils sont trois, peut-être quatre. Le plus gros, on l'appelle Sobek, comme le dieu-crocodile. Il ne mérite pas ce nom.", {}), L("La rive sud est fertile, mais le plateau, derrière, c'est le désert. Le domaine des morts. On n'y cultive rien, à part le silence.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Khéty dit qu'il n'a pas peur des crocodiles. Il dit ça depuis sa barque, au milieu du fleuve. Facile.", {}), L("Les Aztèques font pousser du maïs sur le lac. Sur le lac ! Moi j'ai déjà du mal sur la terre ferme.", {})],
				"interpelle": [L("Tu sais te battre ? J'ai des crocodiles à te présenter.", {"visites_max": 0}), L("{surnom} ! Ils sont revenus.", {"visites_min": 1})],
			}},
		{"id": "tiyi", "nom": "Tiyi", "titre": "tisserande", "maison": "porte_tiyi", "village": "egypte",
			"agenda": [[7, 12, "metier"], [12, 14, "etal_lin"], [14, 18, "metier"], [18, 20, ["place_1", "temple_cour_2"]], [20, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": [0.28, 0.2, 0.1], "haut": [0.96, 0.94, 0.88]},
			"sol": {"tenue": "peuple", "usekh": [0.7, 0.3, 0.25]},
			"teinte": PEAU[2], "humeur_base": 0.2, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"perle": 2.0, "fleur_lune": 2.0, "bague": 1.5, "plume_ara": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Bonjour. Tiyi. Je tisse le lin, le plus fin du fleuve : si fin qu'on voit la lumière au travers. Ma fille, Nebet, court quelque part. Elle court toujours quelque part.", {"visites_max": 1}, "salut"), L("{surnom}. Nebet parle de toi.", {"visites_min": 2})],
				"humeur": [L("Tranquille. Le fil ne casse pas, la navette chante.", {}), L("Nebet est triste, depuis que son chat a disparu. Moi aussi, un peu. C'était un bon chasseur de souris.", {"q56": "eg_chat=en_cours"})],
				"lui": [L("Le lin, on l'arrache, on le rouit dans l'eau, on le bat, on le peigne, on le file, on le tisse. Neuf mois de travail pour une robe. Comme pour un enfant, dit-on. Sauf qu'une robe, ça ne réclame pas de dattes.", {}, "rire"), L("Les momies sont enveloppées dans du lin. Des centaines de mètres. Parfois, je me dis que je tisse pour des gens qui ne sont pas encore morts. Ça me donne des frissons.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Dans les tombeaux du plateau, les momies dorment dans leurs bandelettes. Et dans la pyramide… on dit qu'elles ne dorment pas toutes.", {}), L("Les Mayas tissent aussi, avec un métier qu'ils attachent à leur taille, à un arbre. Ix Sak, leur tisserande, fait des merveilles de couleurs. Moi je ne fais que du blanc. Mais quel blanc !", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Mérit dit que j'ai refusé trois prétendants. C'est faux. J'en ai refusé quatre.", {}, "rire")],
				"interpelle": [L("Bonjour, étranger.", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "nebet", "nom": "Nebet", "titre": "la fille de Tiyi", "maison": "porte_tiyi", "village": "egypte",
			"agenda": [[8, 12, ["jeu_1", "jeu_2", "jeu_3"]], [12, 13, "etal_lin"], [13, 18, ["jeu_1", "jeu_3", "quai_flane"]], [18, 19, "place_3"], [19, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "tresse", "yeux": [0.3, 0.2, 0.12], "haut": [0.95, 0.92, 0.84], "enfant": true, "taille": 0.72},
			"sol": {"tenue": "enfant"},
			"teinte": PEAU[2], "humeur_base": 0.3, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"dattes": 2.5, "miel": 2.0, "coquillage": 1.5, "plume_ara": 2.0}, "deteste": {"dent_croco": -1.0},
			"repliques": {
				"accueil": [L("Bonjour ! Je m'appelle Nebet ! J'ai huit ans et demi ! Tu viens d'où ? Tu as vu un chat ? Un chat roux, avec une oreille tordue ? Il s'appelle Miou !", {"visites_max": 1}), L("{surnom} ! Tu as vu Miou ?", {"visites_min": 2, "pas_trouve": "chat_trouve"}), L("{surnom} ! Miou dort sur mon lit ! Il a encore une oreille tordue !", {"visites_min": 2, "a_trouve": "chat_trouve"}, "rire")],
				"humeur": [L("Triste. Miou est parti depuis trois jours. Maman dit qu'il reviendra. Les chats reviennent toujours, elle dit.", {"pas_trouve": "chat_trouve"}), L("Super contente ! Miou est revenu ! Et il a ramené une souris ! Maman n'était pas contente.", {"a_trouve": "chat_trouve"}, "rire")],
				"lui": [L("Quand je serai grande, je serai prêtresse comme Néferet. Ou pêcheuse comme Khéty. Ou chat. Les chats, ici, on les aime beaucoup. Il y a même une déesse-chat, Bastet !", {}), L("Je sais écrire mon nom en hiéroglyphes ! Un pot, une jambe, un pain. Ça fait Nebet. Amenemhat dit que c'est presque juste.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Le Sphinx, il pose des devinettes ! Moi je connais celle de l'homme : à quatre pattes le matin, c'est le bébé ! Sur deux à midi, c'est le grand ! Sur trois le soir, c'est le vieux avec sa canne ! Facile !", {}), L("Miou aime bien aller sur le plateau, chez les morts, près des tombes carrées. Il dit que c'est calme. Enfin, il ne dit rien, c'est un chat.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Amenemhat ronfle à la Maison de Vie. Les élèves l'appellent l'hippopotame. Ne lui dis pas.", {}, "rire")],
				"interpelle": [L("Hé ! Hé ! Tu as vu un chat ?", {"visites_max": 0, "pas_trouve": "chat_trouve"}), L("{surnom} ! Viens jouer !", {"visites_min": 1})],
			}},
		# ================================================================ Yaxché (les Mayas)
		{"id": "ixkanul", "nom": "Ix Kanul", "titre": "grande prêtresse de Kukulkan", "maison": "porte_ixkanul", "village": "maya",
			"agenda": [[5, 7, "cenote_offrande"], [7, 11, "kuku_priere"], [11, 13, "place_m1"], [13, 17, ["kuku_priere", "stele"]], [17, 19, "cenote_offrande"], [19, 21, "venus_1"], [21, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "chignon", "yeux": [0.2, 0.14, 0.08], "haut": [0.95, 0.93, 0.88]},
			"tz": {"turban": [0.9, 0.85, 0.75]},
			"sol": {"tenue": "pretre", "plumes": [0.1, 0.55, 0.32], "jade": true, "baton": "serpent"},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"masque_jade": 3.0, "plume_ara": 2.0, "cacao": 1.5, "perle": 2.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Tu es loin de chez toi, voyageur. Je suis Ix Kanul, grande prêtresse de Kukulkan, le Serpent à Plumes. Aux équinoxes, son ombre descend l'escalier du temple. Aujourd'hui, c'est toi qui montes. Que cherches-tu ?", {"visites_max": 1}, "salut"),
					L("{surnom}. Le Serpent à Plumes t'a vu revenir.", {"visites_min": 2}),
				],
				"humeur": [L("Attentive. Les signes sont bons, le ciel est clair.", {}), L("La nuit appartient à Xibalba, le monde d'en dessous. Les Seigneurs de la Mort ne dorment jamais.", {"soir": true})],
				"lui": [
					L("Le Popol Vuh, notre livre du conseil, raconte comment les dieux ont fait les hommes : de boue d'abord, qui fondait ; de bois ensuite, qui n'avaient pas de cœur ; et enfin de maïs. Nous sommes des hommes de maïs.", {}),
					L("Je garde le temple depuis la mort de ma mère. Chaque matin, je verse du cacao et du copal dans le Cénote. Les dieux de la pluie y habitent.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Sous le Temple de Kukulkan s'ouvre le chemin de Xibalba. Les héros Hunahpu et Xbalanque y sont descendus pour venger leur père. Ils ont trompé les Seigneurs de la Mort, et ils sont devenus le Soleil et la Lune.", {}),
					L("Au carrefour de Xibalba, il y a quatre chemins : rouge, noir, blanc et jaune. Le chemin noir a parlé : « C'est moi, le chemin du roi. » Et c'était vrai : il descend chez les Seigneurs ; les trois autres tournent en rond. Les Jumeaux ont envoyé un moustique devant eux. Kinich, le petit, en a attrapé un : il le garde dans une calebasse.", {"sujet_min": ["ile", 1]}),
					L("Dans les Maisons de Xibalba, les Jumeaux ont rusé à chaque épreuve : des plumes d'ara rouges au bout des torches, dans la Maison Obscure ; de la viande pour les lames ; des os pour les jaguars. Prépare-toi comme eux.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Ah Kin Pech passe ses nuits à l'observatoire. Il dit qu'il compte les étoiles. Je crois qu'il dort, souvent, la tête sur ses calculs.", {}), L("Les Aztèques d'Aztlán sont venus du nord, d'un lieu nommé Aztlán, eux aussi. Leur dieu leur a dit de s'arrêter là où un aigle mangerait un serpent sur un cactus. Chez nous, le serpent a des plumes, et personne ne le mange.", {})],
				"interpelle": [L("Voyageur. Approche.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "ahkin", "nom": "Ah Kin Pech", "titre": "astronome", "maison": "porte_ahkin", "village": "maya",
			"agenda": [[10, 13, "stele"], [13, 15, ["marche_cacao", "place_m2"]], [15, 18, "observatoire"], [18, 3, "observatoire"], [3, 10, "maison"]],
			"azur": {"cheveux": [0.5, 0.48, 0.45], "coiffure": "queue", "vieux": true, "yeux": [0.2, 0.15, 0.1], "haut": [0.92, 0.9, 0.84]},
			"sol": {"tenue": "pretre", "plumes": [0.15, 0.3, 0.7], "jade": true},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.8, "humour": 0.4, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"boussole": 2.0, "lentille_phare": 2.5, "eclat_lune": 2.0, "cacao": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Ah, un visiteur ! Pardon, je ne t'avais pas vu : je regardais Vénus. Elle est là, juste là… Non ? Bon. Ah Kin Pech, astronome. Je compte les jours, les lunes, les années, et parfois mes cheveux.", {"visites_max": 1}, "rire"), L("{surnom} ! Tu tombes bien : il est exactement le jour qu'il est.", {"visites_min": 2}, "rire")],
				"humeur": [L("Excellente ! Mes calculs tombent juste. À une lune près. Deux, peut-être.", {}, "rire"), L("La nuit ! Enfin ! Mes étoiles se lèvent.", {"soir": true})],
				"lui": [L("Notre calendrier sacré, le Tzolk'in, compte deux cent soixante jours : treize nombres et vingt noms de jours qui tournent ensemble, comme deux roues. Un jour revient tous les deux cent soixante jours. Comme une vieille connaissance.", {}), L("Nous écrivons les nombres avec des points et des barres : un point vaut un, une barre vaut cinq. Treize, c'est deux barres et trois points. Simple, non ?", {"sujet_min": ["lui", 1]})],
				"ile": [L("La porte du temple, en haut de Kukulkan, ne s'ouvre qu'au jour de la création. Les deux roues de pierre doivent montrer la date où le monde présent est né.", {}), L("Le monde présent est né un jour 4 Ahau : quatre points, et le visage du Seigneur. C'est écrit sur la grande stèle, devant le temple. Les jeunes ne la lisent plus. Ils ont tort.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Chak, le joueur de balle, dit qu'il pourrait battre les Seigneurs de Xibalba. Chak dit beaucoup de choses. Il a pris un ballon sur la tête, petit.", {}, "rire")],
				"interpelle": [L("Toi ! Tu sais quel jour on est ?", {"visites_max": 0}), L("{surnom} ! Regarde le ciel !", {"visites_min": 1})],
			}},
		{"id": "balam", "nom": "Balam", "titre": "chasseur", "maison": "porte_balam", "village": "maya",
			"agenda": [[5, 9, "chasseur"], [9, 13, ["place_m3", "marche_mais"]], [13, 18, "chasseur"], [18, 21, ["venus_2", "place_m1"]], [21, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": [0.2, 0.15, 0.1], "haut": [0.5, 0.35, 0.2], "taille": 1.06},
			"sol": {"tenue": "chasseur", "plumes": [0.75, 0.15, 0.08]},
			"teinte": PEAU[4], "humeur_base": 0.0, "traits": {"bavard": 0.3, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.4},
			"aime": {"os_jaguar": 1.5, "obsidienne": 2.0, "dent_croco": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Balam. Ça veut dire jaguar. Je chasse le cerf, le pécari, le dindon. Le jaguar, je le laisse tranquille : c'est mon nom, pas mon gibier.", {"visites_max": 1}), L("{surnom}.", {"visites_min": 2})],
				"humeur": [L("Tranquille. La forêt est calme.", {}), L("La nuit, la jungle appartient aux jaguars. Je rentre.", {"soir": true})],
				"lui": [L("Mon père m'a appris à marcher sans bruit, à lire les traces, à remercier la bête qu'on tue. On ne prend que ce qu'il faut.", {}), L("La sarbacane, c'est l'arme des Jumeaux. Hunahpu et Xbalanque chassaient les oiseaux avec. Moi aussi. Mais je rate plus souvent qu'eux.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Au nord, dans la jungle, il y a des serpents. À l'ouest, sur les pentes du volcan, des jaguars. Les vrais. Fais attention.", {}), L("Dans la Maison des Lames, à Xibalba, les couteaux tranchent tout ce qui passe. Les Jumeaux leur ont promis la chair de toutes les bêtes. Si tu y vas, emporte de la viande de cerf. Je t'en donnerai.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Yum Kab parle à ses abeilles. Elles lui répondent, il dit. En bourdonnant.", {})],
				"interpelle": [L("Hm.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "ixsak", "nom": "Ix Sak", "titre": "tisserande", "maison": "porte_ixsak", "village": "maya",
			"agenda": [[7, 12, "metier_maya"], [12, 14, "marche_plumes"], [14, 18, "metier_maya"], [18, 20, ["venus_1", "place_m2"]], [20, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "tresse", "yeux": [0.22, 0.15, 0.1], "haut": [0.92, 0.9, 0.86]},
			"sol": {"tenue": "peuple", "jade": true},
			"teinte": PEAU[3], "humeur_base": 0.35, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"plume_ara": 2.0, "fleur_lune": 2.0, "perle": 2.0, "cacao": 1.0}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"plume_ara": 6}, "achete": {"plume_perroquet": 7, "plume_corbeau": 3}},
			"repliques": {
				"accueil": [L("Bonjour ! Ix Sak. Je tisse, je teins, je brode les huipils de tout le village. Ces couleurs ? Rouge de cochenille, bleu de l'indigo, jaune des fleurs. Et les plumes d'ara, pour les fêtes.", {"visites_max": 1}, "salut"), L("{surnom} ! Tu veux des plumes ?", {"visites_min": 2})],
				"humeur": [L("Joyeuse ! Mon métier chante, mes couleurs sont vives.", {}), L("Le soir, je danse sur la plateforme de Vénus. Avec Balam, quand il ne fait pas le jaguar.", {"soir": true}, "rire")],
				"lui": [L("Ix Chel, la déesse de la lune, a appris aux femmes à tisser. Mon métier s'attache à ma taille et à cet arbre. Quand je me penche en arrière, les fils se tendent. Je tisse avec tout mon corps.", {}), L("Chaque motif raconte quelque chose : le serpent, le maïs, le losange du monde avec ses quatre coins. Un huipil, c'est un livre qu'on porte.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les plumes d'ara rouges, dans la nuit, on dirait des braises. Les Jumeaux s'en sont servis pour tromper les Seigneurs de Xibalba, dans la Maison Obscure : il fallait garder les torches allumées toute la nuit sans les brûler. Ils ont mis des plumes à la place du feu !", {}), L("J'en vends, des plumes d'ara. Quatre suffiraient pour une Maison Obscure, je dirais. Pour une fête, il en faut beaucoup plus.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("Chak s'entraîne au jeu de balle même la nuit. Il a cassé deux pots de Ix Chab. Elle l'a poursuivi jusqu'au Cénote.", {}, "rire")],
				"interpelle": [L("Bonjour !", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "chak", "nom": "Chak", "titre": "joueur de balle", "maison": "porte_chak", "village": "maya",
			"agenda": [[7, 12, ["balle_1", "balle_2", "balle_3"]], [12, 14, "marche_cacao"], [14, 18, ["balle_2", "balle_3"]], [18, 21, ["venus_1", "place_m3"]], [21, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "queue", "yeux": [0.2, 0.14, 0.08], "haut": [0.7, 0.2, 0.12], "taille": 1.05},
			"sol": {"tenue": "joueur", "plumes": [0.95, 0.75, 0.15]},
			"teinte": PEAU[4], "humeur_base": 0.4, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"cacao": 2.0, "coupe_course": 2.5, "ceinture_champion": 2.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Hé ! Chak ! Meilleur joueur de balle de Yaxché ! Et de toute l'île ! Et de… bon, de Yaxché, c'est déjà bien. Tu joues ?", {"visites_max": 1}, "rire"), L("{surnom} ! Une partie ?", {"visites_min": 2})],
				"humeur": [L("En forme ! J'ai marqué trois fois ce matin. Bon, il n'y avait personne en face.", {}, "rire"), L("Fatigué. J'ai joué toute la journée. Mes hanches sont bleues.", {"soir": true})],
				"lui": [L("Le jeu de balle, c'est simple : la balle de caoutchouc, on ne la touche ni avec les mains ni avec les pieds. Avec les hanches, les cuisses, les coudes. Et il faut la faire passer dans l'anneau de pierre, là-haut. Personne n'y arrive. Moi, deux fois. Peut-être.", {}), L("Les Jumeaux ont joué contre les Seigneurs de Xibalba. Ils ont gagné. Moi, je rêve de jouer contre les Seigneurs. Mais de préférence en restant vivant.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Si tu descends à Xibalba, tu devras jouer contre les Seigneurs. Un conseil : ne cours pas après la balle, va où elle va aller. Et pousse-la vers l'anneau avec tout ton corps.", {}), L("La balle est lourde, en caoutchouc plein. Une balle sur la tête et tu vois les étoiles. Demande à Ah Kin Pech : c'est comme ça qu'il est devenu astronome.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("Ix Chab me poursuit encore pour ses pots. Ce n'était pas moi. C'était la balle.", {}, "rire")],
				"interpelle": [L("Hé ! Attrape ! … Non, pas avec les mains !", {"visites_max": 0}, "rire"), L("{surnom} ! On joue ?", {"visites_min": 1})],
			}},
		{"id": "yumkab", "nom": "Yum Kab", "titre": "apiculteur", "maison": "porte_yumkab", "village": "maya",
			"agenda": [[6, 11, "ruches"], [11, 13, "marche_mais"], [13, 18, "ruches"], [18, 20, ["place_m2", "stele"]], [20, 6, "maison"]],
			"azur": {"cheveux": [0.45, 0.42, 0.38], "coiffure": "court", "vieux": true, "yeux": [0.2, 0.15, 0.1], "haut": [0.8, 0.7, 0.4]},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[4], "humeur_base": 0.45, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.1, "rancunier": 0.1},
			"aime": {"fleur_lune": 2.0, "miel": 1.0, "cacao": 1.5}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"miel": 4}, "achete": {"fleur_lune": 4}},
			"repliques": {
				"accueil": [L("Bonjour, bonjour… Yum Kab, gardien des abeilles. Mes abeilles n'ont pas de dard. Elles sont douces comme moi. Tu veux goûter le miel ? Il a le goût des fleurs de la jungle.", {"visites_max": 1}, "rire"), L("{surnom} ! Les abeilles t'ont reconnu. Elles bourdonnent plus fort.", {"visites_min": 2}, "rire")],
				"humeur": [L("Doux comme le miel. Toujours.", {}, "rire"), L("La ruche s'endort. Moi aussi.", {"soir": true})],
				"lui": [L("Mes ruches sont des troncs creux, couchés sous un toit de palmes. On les ouvre par le bout, on prend un peu de miel, jamais tout. Les abeilles nous font confiance.", {}), L("Mon nom vient du dieu des abeilles. Ma mère disait que je bourdonnais déjà dans mon berceau.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Le Cénote sacré, au nord-ouest, c'est une porte vers le monde d'en bas. Le soir, des chauves-souris en sortent par centaines. Camazotz, la chauve-souris de la mort, les commande, dit-on.", {}), L("Kinich, le petit, a un chien qui enterre des os partout. Si tu as besoin d'os, demande-lui. Les jaguars en raffolent.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("Ah Kin Pech et moi, on joue aux osselets le soir. Il compte les points, alors il gagne toujours.", {}, "rire")],
				"interpelle": [L("Bzzz… Bonjour !", {"visites_max": 0}, "rire"), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "ixchab", "nom": "Ix Chab", "titre": "marchande de cacao et de tortillas", "maison": "porte_ixchab", "village": "maya",
			"agenda": [[5, 8, "metate"], [8, 13, "marche_cacao"], [13, 15, "metate"], [15, 19, "marche_cacao"], [19, 21, "place_m1"], [21, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "chignon", "yeux": [0.22, 0.15, 0.1], "haut": [0.85, 0.3, 0.25], "taille": 0.96},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[4], "humeur_base": 0.25, "traits": {"bavard": 0.8, "humour": 0.5, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"miel": 2.0, "dattes": 2.0, "coquillage": 1.0}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"cacao": 4, "galette_mais": 3}, "achete": {"miel": 3, "dattes": 3}},
			"repliques": {
				"accueil": [L("Cacao ! Tortillas ! Approche ! Ix Chab. Mon cacao est battu jusqu'à la mousse, avec du piment et de la vanille. Les dieux en boivent. Les marchands aussi, mais ils paient.", {"visites_max": 1}, "rire"), L("{surnom} ! Un cacao ? Bien mousseux ?", {"visites_min": 2})],
				"humeur": [L("Bonne, tant que Chak garde sa balle loin de mes pots.", {}), L("Mes bras sont fatigués : j'ai moulu du maïs toute la journée.", {"soir": true})],
				"lui": [L("Le maïs, on le cuit avec de la chaux, on le moud sur la pierre, le metate, et on fait les galettes. Tous les jours. Avant le soleil. C'est le maïs qui nous a faits, dit le Popol Vuh. Alors on lui doit bien ça.", {}), L("Les fèves de cacao, chez nous, servent aussi de monnaie. Un lapin vaut dix fèves. Un dindon, cent. Moi, je préfère les boire.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les Aztèques adorent le cacao aussi. Ils l'appellent xocolatl. Leurs nobles en boivent cinquante tasses par jour, il paraît. Moi, à cinquante, je ne dormirais plus jamais.", {}, "rire")],
				"rumeur": [L("Yum Kab vend son miel moins cher que moi le mien. Moi je n'ai pas de miel. Mais c'est une question de principe.", {}, "rire")],
				"interpelle": [L("Cacao chaud !", {"visites_max": 0}), L("{surnom} ! Ton cacao !", {"visites_min": 1})],
			}},
		{"id": "kinich", "nom": "Kinich", "titre": "le garçon au moustique", "maison": "porte_kinich", "village": "maya",
			"agenda": [[8, 12, ["balle_1", "balle_3", "place_m3"]], [12, 13, "marche_cacao"], [13, 18, ["balle_2", "place_m3"]], [18, 19, "venus_1"], [19, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "yeux": [0.2, 0.14, 0.08], "haut": [0.9, 0.86, 0.75], "enfant": true, "taille": 0.7},
			"sol": {"tenue": "enfant", "chien": true},
			"teinte": PEAU[4], "humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"miel": 2.5, "cacao": 2.0, "plume_ara": 1.5, "coquillage": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Salut ! Je suis Kinich ! J'ai attrapé un moustique ! Il est dans ma calebasse ! Il s'appelle Xan, comme le moustique des Jumeaux ! Tu veux le voir ? Non, tu ne peux pas, il s'envolerait.", {"visites_max": 1}, "rire"), L("{surnom} ! Xan va bien !", {"visites_min": 2})],
				"humeur": [L("Super ! Mon chien a trouvé un os énorme. Il l'a enterré. Puis il l'a déterré. Puis il l'a enterré.", {}, "rire")],
				"lui": [L("Mon chien s'appelle Peek'. Il enterre des os partout dans le village. Si tu en as besoin, je sais où ils sont !", {}), L("Quand je serai grand, je serai joueur de balle comme Chak. Ou héros comme Hunahpu. Ou chien.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Dans Xibalba, les Jumeaux ont envoyé un moustique piquer les Seigneurs ! Il y avait des faux seigneurs en bois, et les vrais ont crié « aïe ! » et ils ont dit leurs noms ! Hun-Camé et Vucub-Camé ! C'est la meilleure histoire du monde !", {}), L("Les jaguars, il faut leur jeter des os, comme les Jumeaux. Alors ils rongent et ils oublient de te manger !", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Ah Kin Pech dort à l'observatoire. Je l'ai vu ! Il ronfle vers les étoiles !", {}, "rire")],
				"interpelle": [L("Hé ! Tu veux voir mon moustique ?", {"visites_max": 0}), L("{surnom} ! {surnom} !", {"visites_min": 1})],
			}},
		# ================================================================ Aztlán (les Aztèques)
		{"id": "cuauhtli", "nom": "Cuauhtli", "titre": "grand prêtre du Grand Temple", "maison": "porte_cuauhtli", "village": "azteque",
			"agenda": [[5, 8, "priere_huitzi"], [8, 11, "calmecac_cours"], [11, 13, "place_a1"], [13, 16, ["priere_tlaloc", "priere_huitzi"]], [16, 19, "calmecac_cours"], [19, 21, "priere_huitzi"], [21, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "vieux": true, "yeux": [0.2, 0.14, 0.08], "haut": [0.12, 0.12, 0.14]},
			"sol": {"tenue": "pretre", "plumes": [0.1, 0.5, 0.3], "jade": true, "baton": "serpent"},
			"teinte": PEAU[3], "humeur_base": 0.1, "traits": {"bavard": 0.6, "humour": 0.2, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"plume_quetzal": 3.0, "obsidienne": 2.0, "copal": 1.5, "cacao": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Halte, étranger. Tu es à Aztlán, au cœur du Lac de la Lune. Je suis Cuauhtli, l'Aigle, grand prêtre du Grand Temple. Là-haut veillent Tlaloc, qui donne la pluie, et Huitzilopochtli, qui mène le soleil au combat.", {"visites_max": 1}, "salut"),
					L("{surnom}. Le soleil se lève encore. C'est bon signe.", {"visites_min": 2}),
				],
				"humeur": [L("Grave. Le soleil a besoin de nous pour se lever chaque matin. On ne plaisante pas avec ça.", {}), L("La nuit, les étoiles se battent contre le soleil. Nous prions pour qu'il gagne.", {"soir": true})],
				"lui": [
					L("Nous vivons sous le Cinquième Soleil. Quatre mondes l'ont précédé, et tous ont été détruits. Celui-ci finira aussi, un jour, par des tremblements de terre. Mais pas aujourd'hui.", {}),
					L("Pour faire naître le Cinquième Soleil, les dieux se sont réunis à Teotihuacan autour d'un grand feu. Le fier Tecciztécatl, couvert de plumes et d'or, a eu peur de sauter. Le petit Nanahuatzin, humble et couvert de boutons, a sauté le premier. Il est devenu le Soleil.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Grand Temple a deux sanctuaires. Celui de Tlaloc, bleu, veut de l'eau : une jarre de pluie. Celui de Huitzilopochtli, rouge, veut du feu : du copal qui brûle. Apporte les deux, et la porte du Cinquième Soleil s'ouvrira entre eux.", {}),
					L("Sous le temple, chaque soleil a sa salle. Les glyphes que tu y trouveras, il faudra les poser sur la Pierre du Soleil dans l'ordre des mondes. Citlali, au calmecac, garde le codex qui les raconte.", {"sujet_min": ["ile", 1]}),
					L("Au plus profond, dort Cipactli, le monstre de la Terre : un crocodile aux mille bouches. Les dieux ont fait le monde de son corps. Tezcatlipoca y a laissé son pied. Toi, garde les tiens.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [L("Mixtli, notre guerrier-jaguar, dit qu'il a vu de vrais jaguars sur les pentes du Mont Fumant. Il veut aller les affronter. Un guerrier-jaguar contre des jaguars… Les dieux aiment les plaisanteries.", {}), L("Tochtli vend son copal plus cher les jours de fête. Les dieux le voient. Tochtli aussi, d'ailleurs, voit les dieux : il leur vend du copal.", {})],
				"interpelle": [L("Étranger. Approche.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "citlali", "nom": "Citlali", "titre": "maîtresse du calmecac", "maison": "porte_citlali", "village": "azteque",
			"agenda": [[7, 12, "calmecac_codex"], [12, 14, ["tianguis_cacao", "place_a2"]], [14, 18, "calmecac_codex"], [18, 20, ["musique", "place_a2"]], [20, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "tresse", "yeux": [0.22, 0.15, 0.1], "haut": [0.95, 0.92, 0.86]},
			"sol": {"tenue": "peuple", "jade": true},
			"teinte": PEAU[2], "humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"grimoire": 2.5, "papyrus_thot": 2.0, "plume_quetzal": 2.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Bonjour, voyageur. Citlali, l'Étoile. J'enseigne au calmecac, l'école où l'on apprend les chants, les calendriers, l'écriture en images. Nos livres se déplient comme un paravent. On les appelle des codex.", {"visites_max": 1}, "salut"), L("{surnom}. Tu viens apprendre ?", {"visites_min": 2})],
				"humeur": [L("Studieuse. Mes élèves aussi. Enfin, certains.", {}, "rire")],
				"lui": [L("Un codex se lit en images : un pied qui marche, c'est un voyage ; une langue devant une bouche, c'est une parole ; un petit point, c'est un nombre. Le monde est un livre d'images, si on sait regarder.", {}), L("Je suis entrée au calmecac à cinq ans. Les prêtres nous réveillaient à minuit pour chanter aux étoiles. J'ai gardé l'habitude. Les étoiles, aussi.", {"sujet_min": ["lui", 1]})],
				"ile": [L("La Légende des Soleils, je la sais par cœur : le premier soleil fut celui des Jaguars, qui dévorèrent les géants ; le deuxième, celui du Vent, qui emporta tout ; le troisième, celui de la Pluie de Feu ; le quatrième, celui de l'Eau, le grand déluge. Nous vivons sous le cinquième, le Soleil du Mouvement.", {}), L("Jaguar, Vent, Pluie de Feu, Eau, puis Mouvement. Le codex de la Légende des Soleils est là, sur le pupitre : regarde, les points disent l'ordre.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Pilli dort en classe. Avec son chien. Le chien, lui, apprend mieux.", {}, "rire")],
				"interpelle": [L("Bonjour.", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "mixtli", "nom": "Mixtli", "titre": "guerrier-jaguar", "maison": "porte_mixtli", "village": "azteque",
			"agenda": [[6, 10, "guerrier"], [10, 13, ["place_a1", "tianguis_copal"]], [13, 18, "guerrier"], [18, 21, ["danse_a", "musique"]], [21, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "yeux": [0.18, 0.12, 0.08], "haut": [0.9, 0.7, 0.2], "taille": 1.08},
			"sol": {"tenue": "guerrier", "jaguar": true, "bouclier": true, "plumes": [0.9, 0.7, 0.15]},
			"teinte": PEAU[4], "humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.3, "curiosite": 0.3, "susceptible": 0.7, "rancunier": 0.5},
			"aime": {"obsidienne": 2.5, "croc_geant": 2.5, "dent_croco": 1.5, "os_jaguar": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Mixtli. Guerrier-jaguar d'Aztlán. Je porte la peau du jaguar parce que je me bats comme lui : vite, et dans l'ombre. Tu as l'air de savoir te battre. On verra.", {"visites_max": 1}), L("{surnom}. Toujours debout ?", {"visites_min": 2})],
				"humeur": [L("Prêt. Toujours prêt.", {}), L("La nuit, c'est l'heure du jaguar. Mon heure.", {"soir": true})],
				"lui": [L("On devient guerrier-jaguar après avoir capturé quatre ennemis. J'en ai capturé cinq. Le cinquième, c'était mon cousin, à l'entraînement. Il ne m'a pas encore pardonné.", {}), L("Mon arme, c'est la macuahuitl : un bâton de bois garni d'éclats d'obsidienne. Plus tranchant qu'un couteau de fer. Mais si on frappe une pierre, l'obsidienne casse. Alors on ne frappe pas les pierres.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Sur les pentes du Mont Fumant, à l'ouest, de vrais jaguars rôdent. Deux, au moins. Ils ont tué un dindon de Xóchitl. Je vais les chasser. Tu viens ?", {}), L("Sous le Grand Temple, dans la salle du premier soleil, celui des Jaguars, on dit que des jaguars de pierre se réveillent. Ceux-là, même moi je les respecte.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Tochtli a voulu me vendre une plume de quetzal. C'était une plume de perroquet peinte en vert. Je lui ai rendu sa plume. Sur la tête.", {})],
				"interpelle": [L("Toi.", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "xochitl", "nom": "Xóchitl", "titre": "jardinière des chinampas", "maison": "porte_xochitl", "village": "azteque",
			"agenda": [[5, 11, "chinampa_1"], [11, 13, "tianguis_mais"], [13, 18, ["chinampa_2", "chinampa_1"]], [18, 20, "place_a2"], [20, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "tresse", "yeux": [0.22, 0.15, 0.1], "haut": [0.95, 0.75, 0.3]},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[3], "humeur_base": 0.45, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"graines": 2.5, "fleur_lune": 2.0, "cempasuchil": 1.5, "miel": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Bonjour ! Xóchitl, la Fleur ! Je cultive les chinampas, les jardins flottants. On entasse de la boue du lac sur des nattes de roseaux, on plante des saules aux coins pour tenir le tout, et ça pousse ! Maïs, haricots, courges, piments, fleurs !", {"visites_max": 1}, "rire"), L("{surnom} ! Tu viens m'aider au jardin ?", {"visites_min": 2})],
				"humeur": [L("Fleurie ! Comme toujours.", {}, "rire"), L("Le soir, les hérons viennent voler mes poissons. Je leur jette des mottes de boue. Ils trouvent ça drôle.", {"soir": true})],
				"lui": [L("Les fleurs de cempasúchil, orange comme le soleil, on les met sur les autels pour guider les âmes des morts. Leur odeur leur montre le chemin.", {}), L("Mon fils Pilli court partout avec son chien. Un xoloitzcuintle, sans poils. Il dit que le chien le guidera chez les morts, plus tard. Moi je dis qu'il ferait mieux de le guider jusqu'à la maison, déjà.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("La fête des morts approche. Il me faudrait cinq bouquets de cempasúchil pour les autels du temple. Elles poussent sur les chinampas du sud, au bord des canaux. Tu m'aiderais à les cueillir ?", {}), L("Sur le lac, ne t'aventure pas hors des chinampas et des chaussées : l'eau est profonde, et froide.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Coyotl, le potier, a fait une jarre si belle pour Tlaloc que Tlaloc a fait pleuvoir trois jours. Coyotl dit que c'est un compliment.", {}, "rire")],
				"interpelle": [L("Coucou !", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "tochtli", "nom": "Tochtli", "titre": "marchand du tianguis", "maison": "porte_tochtli", "village": "azteque",
			"agenda": [[7, 13, "tianguis_copal"], [13, 15, ["place_a1", "tianguis_cacao"]], [15, 19, "tianguis_copal"], [19, 21, "musique"], [21, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": [0.22, 0.15, 0.1], "haut": [0.3, 0.55, 0.6], "taille": 0.98},
			"sol": {"tenue": "peuple", "eventail": true},
			"teinte": PEAU[3], "humeur_base": 0.35, "traits": {"bavard": 0.9, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"piece_or": 2.5, "perle": 2.0, "rubis": 2.0}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"copal": 6, "cacao": 4, "obsidienne": 14}, "achete": {"plume_ara": 5, "perle": 12, "dent_croco": 5, "obsidienne": 7}},
			"repliques": {
				"accueil": [L("Approche, approche ! Tochtli, le Lapin ! Le meilleur marchand du tianguis ! Copal pour les dieux, cacao pour les hommes, obsidienne pour les guerriers ! Tout ce qu'il faut, et même ce qu'il ne faut pas !", {"visites_max": 1}, "rire"), L("{surnom} ! Mon client préféré ! Enfin, mon client.", {"visites_min": 2}, "rire")],
				"humeur": [L("Excellente ! Les affaires marchent. Elles courent, même.", {}, "rire")],
				"lui": [L("Mon père était pochtecatl, marchand voyageur. Il partait des mois, chargé de plumes, de jade, de cacao. Il revenait avec des histoires. Moi, je reste au tianguis. Les histoires viennent à moi.", {}), L("Le copal, c'est la résine d'un arbre. On la brûle pour les dieux : la fumée monte jusqu'à eux. Huitzilopochtli l'adore. Moi aussi : je la vends.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Pour le sanctuaire rouge de Huitzilopochtli, il te faut du copal. J'en ai, du meilleur. Six pièces, et la fumée est parfumée.", {}), L("Les Mayas de Yaxché vendent des plumes d'ara. Moi aussi, j'en achète. Je les revends plus cher. C'est ça, le commerce.", {"sujet_min": ["ile", 1]}, "rire")],
				"rumeur": [L("Mixtli dit que je lui ai vendu une fausse plume de quetzal. C'était un essai. Il fallait vérifier qu'il savait reconnaître une vraie.", {}, "rire")],
				"interpelle": [L("Copal ! Cacao ! Obsidienne !", {"visites_max": 0}), L("{surnom} ! Viens voir !", {"visites_min": 1})],
			}},
		{"id": "coyotl", "nom": "Coyotl", "titre": "potier", "maison": "porte_coyotl", "village": "azteque",
			"agenda": [[7, 12, "potier_az"], [12, 14, "tianguis_pots"], [14, 18, "potier_az"], [18, 20, ["place_a1", "danse_a"]], [20, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "", "yeux": [0.2, 0.14, 0.08], "haut": [0.85, 0.82, 0.75]},
			"sol": {"tenue": "peuple"},
			"teinte": PEAU[4], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"obsidienne": 1.5, "scarabee": 2.0, "eau_source": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Salut ! Coyotl, potier. Je fais les jarres de Tlaloc : bleues, avec ses grands yeux ronds et ses crocs. On les remplit d'eau du lac et on les offre au dieu de la pluie. Il aime qu'on pense à lui.", {"visites_max": 1}, "salut"), L("{surnom} ! Tu viens chercher une jarre ?", {"visites_min": 2})],
				"humeur": [L("Mouillée. Comme toujours. C'est le métier.", {}, "rire")],
				"lui": [L("Mon grand-père disait que Tlaloc habite au sommet des montagnes, avec ses petits aides, les Tlaloque. Ils ont des jarres pleines de pluie, et quand ils les cassent avec leurs bâtons, il pleut. Le tonnerre, c'est le bruit des jarres.", {}), L("J'ai envoyé des jarres jusqu'à Per-Hâpy, chez les Égyptiens. Leur potier, Ptahmosé, m'a renvoyé un scarabée. Je crois que c'était un compliment.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Pour le sanctuaire de Tlaloc, il faut une jarre de pluie bien pleine. Je t'en ferai une, si le grand prêtre t'envoie.", {}), L("Sous le temple, dans la salle du Soleil de l'Eau, on dit que l'eau monte et descend selon des vannes. Les anciens maîtrisaient l'eau mieux que nous.", {"sujet_min": ["ile", 1]})],
				"rumeur": [L("Nenetl joue du tambour si fort que mes pots tremblent sur leurs étagères. Un jour, ils sauteront tout seuls dans le lac.", {}, "rire")],
				"interpelle": [L("Hé !", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "nenetl", "nom": "Nenetl", "titre": "musicienne", "maison": "porte_nenetl", "village": "azteque",
			"agenda": [[9, 12, "place_a2"], [12, 14, "tianguis_cacao"], [14, 17, ["musique", "place_a2"]], [17, 22, "musique"], [22, 9, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": [0.22, 0.15, 0.1], "haut": [0.85, 0.25, 0.4]},
			"sol": {"tenue": "peuple", "plumes": [0.85, 0.2, 0.45]},
			"teinte": PEAU[2], "humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"partition": 2.5, "caillou_chantant": 2.5, "conque": 2.0}, "deteste": {"sifflet_muet": -1.0},
			"repliques": {
				"accueil": [L("Bonjour ! Nenetl ! Je joue du huehuetl, le grand tambour, du teponaztli, le tambour fendu, et de la flûte de terre. Et du coquillage, quand Ehécatl me le demande !", {"visites_max": 1}, "rire"), L("{surnom} ! Tu danses ?", {"visites_min": 2})],
				"humeur": [L("En musique ! Toujours !", {}, "rire"), L("Le soir, c'est la fête. Les tambours, les danseurs, les étoiles. Viens !", {"soir": true})],
				"lui": [L("Ma flûte est en terre cuite, en forme d'oiseau. Quand je souffle, elle chante comme un colibri. Huitzilopochtli était un colibri, tu sais. Le colibri du sud.", {}), L("Ehécatl, le dieu du vent, souffle dans une conque. C'est lui qui a mis le Cinquième Soleil en mouvement : le soleil s'était levé, mais il restait immobile. Ehécatl a soufflé, et le soleil s'est mis en route.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Sous le Grand Temple, on dit que la conque d'Ehécatl attend dans la salle du Vent. Celui qui souffle dedans fait tourner le soleil. J'aimerais bien l'entendre, ce coquillage.", {})],
				"rumeur": [L("Coyotl dit que je fais trembler ses pots. C'est faux : ce sont ses pots qui dansent. Ils ont du goût.", {}, "rire")],
				"interpelle": [L("Tam tam tam !", {"visites_max": 0}, "rire"), L("{surnom} !", {"visites_min": 1})],
			}},
		{"id": "pilli", "nom": "Pilli", "titre": "le fils de Xóchitl", "maison": "porte_xochitl", "village": "azteque",
			"agenda": [[8, 11, ["chinampa_2", "place_a2"]], [11, 13, "tianguis_mais"], [13, 18, ["place_a1", "danse_a"]], [18, 19, "musique"], [19, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": [0.2, 0.14, 0.08], "haut": [0.9, 0.86, 0.76], "enfant": true, "taille": 0.7},
			"sol": {"tenue": "enfant", "chien": true},
			"teinte": PEAU[3], "humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"cacao": 2.5, "miel": 2.0, "plume_quetzal": 2.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Salut ! Je suis Pilli ! Et lui c'est Tlaco, mon chien ! Il n'a pas de poils ! C'est normal ! C'est un xolo ! Il est tout chaud, touche ! … Bon, ne touche pas, il mord un peu.", {"visites_max": 1}, "rire"), L("{surnom} ! Tlaco t'a reconnu !", {"visites_min": 2})],
				"humeur": [L("Content ! Maman m'a donné un cacao.", {})],
				"lui": [L("Les xolos guident les morts dans le Mictlan, le monde d'en bas. Tlaco me guidera, plus tard. Mais pas maintenant : il ne sait même pas trouver la maison.", {}, "rire")],
				"ile": [L("Au Grand Temple, il y a des serpents de pierre en bas de l'escalier ! Et en haut, deux maisons, une bleue et une rouge ! Je n'ai pas le droit d'y monter. Toi non plus, je parie.", {})],
				"rumeur": [L("Citlali dit que Tlaco apprend mieux que moi. C'est vrai. Il sait déjà s'asseoir.", {}, "rire")],
				"interpelle": [L("Hé ! Tu veux voir mon chien ?", {"visites_max": 0}), L("{surnom} !", {"visites_min": 1})],
			}},
	]

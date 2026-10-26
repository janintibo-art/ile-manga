extends RefCounted
## V75 : les gens de Port-Boucan, la ville libre de l'Île du Boucan. Une vieille friche industrielle
## et portuaire, abandonnée puis réoccupée par des punks au grand cœur, des artistes, des bricoleurs et
## des familles : des squats, une salle de concert, une cantine à prix libre, une gratuiterie, un atelier
## vélo, une imprimerie de fanzines, une radio pirate, des jardins partagés, un skatepark… et des
## assemblées où tout le monde a la parole. Crêtes colorées, perfectos cloutés, chiens à bandanas,
## musique très fort, et beaucoup de tendresse sous les airs de durs.
##  - la Conserverie (le grand squat) et les Rats de Cale : Rouille (chant), Clou (guitare, et sa guitare
##    Germaine-la-Terrible), Mouette (basse), Mamie Barricade (la fondatrice), Lentille (la Cantine à prix
##    libre), Trocante (la Gratuiterie), Pastille (le Point Soins), Tapage (le vieux punk légendaire),
##    Velours (la couturière de récup) ;
##  - la Filature (les ateliers) : Rustine (atelier vélo), Agrafe (l'imprimerie du Boucanier), Pigment
##    (la graffeuse), Copeau (la menuiserie de récup), Fusible (l'électricien) ;
##  - la Halle Hurlante : Sirène (le bar à limonades), Larsen (la régie son) ;
##  - le port et la ville : Boulon (le grutier), Sergent Fréquence (Radio Boucan, dans le Cargo), Radis
##    (les Jardins Partagés), Chaussette (et ses six chiens), Cradoc (jongleur), Bardane (grimpeuse
##    d'arbres), Patchouli (le tarot des pigeons), et les enfants Tornade (10 ans, skate) et Cerise
##    (9 ans, fanzines), les enfants de Rustine et de Copeau ;
##  - le sud : Mère Morille (la sage des champignons féeriques, dans le Gazomètre), Ferraille (la Casse),
##    Gravier (le pêcheur de la Plage aux Galets) ;
##  - Lisse & Fils : Monsieur Aldric Lisse (le promoteur, méchant de comédie), son fils Gédéon (batteur
##    génial en secret) et Mademoiselle Prune (sa secrétaire, fan des Rats de Cale en cachette).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd). Fiche « village » : boucan (les lieux : voir la note V75).
## Les concerts : chaque soir de 21 h à 23 h 30, Rouille, Clou et Mouette sont sur scène
## (halle_scene_chant, halle_scene_guitare, halle_scene_basse) ; la batterie (halle_scene_batterie) est
## dans l'agenda de Tapage, le remplaçant « par défaut » : le jeu fait tourner le batteur de remplacement
## du soir parmi les volontaires (puis Gédéon, après sa quête). La fosse : halle_fosse_1 … 12.
## Fiche « punk » : tenue (perfecto | veste_jean | sweat | salopette | bleu_travail | tablier | costume |
## tailleur | robe_recup | chale | marin | enfant | sportif), clous (perfecto clouté), patchs, objet
## (guitare | basse | baguettes | micro | louche | cle_molette | bombe_peinture | casque_audio | arrosoir |
## tablette | skate | laisse | aiguilles | balles_jonglage | canne_peche | panier | livre | carnet,
## facultatif), chapeau (bonnet | bandana | casquette | casque_skate, facultatif), lunettes (facultatif),
## chien (se promène avec un chien, facultatif).
## Coiffures : celles des autres îles, plus « crete » (la crête) et « crete_courte ».

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Salut, {surnom} ! Et si tu croises un robot de Lisse, dis-lui qu'on n'est pas à vendre.", "si": {}, "geste": "salut"},
		{"t": "À plus ! Passe à la Halle ce soir : c'est gratuit, c'est fort, et c'est plein d'amour. Surtout fort.", "si": {}, "geste": "rire"},
		{"t": "Bonne route ! Ici, la porte est toujours ouverte. Enfin, elle est tombée en 1998. Mais c'est pareil.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit ! Dors bien, si tu y arrives : les Rats de Cale jouent jusqu'à minuit moins le quart.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Ici, on ne tape que sur les batteries et sur les robots ! Et encore, gentiment !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Ça va pas, non ? Tu veux qu'on en parle à l'assemblée ? Mamie Barricade va te faire un sermon de trois heures !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? C'est sympa. Si je n'en ai pas besoin, je le poserai à la Gratuiterie : il fera un autre heureux.", "si": {}},
		{"t": "Merci, {surnom}. Ici, on dit qu'un cadeau, c'est un objet qui a trouvé un nouveau copain.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Tu as tapé en plein dans le mille, {surnom} ! Comme une baguette sur une caisse claire !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau de punk au grand cœur ! Merci, {surnom}. Je vais le raconter à toute la Place des Palettes.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… Je vais le déposer à la Gratuiterie. Trocante trouve preneur pour tout. Même pour ça.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, on se défend avec des chaînes humaines et des chansons. Et contre les robots, elle te servira plus qu'à moi.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Évidemment ! À Port-Boucan, tout le monde se souvient de tout le monde. Et Sergent Fréquence le répète à la radio.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Tu confonds peut-être avec une assemblée : là-bas, tout le monde demande tout en même temps.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les robots de Lisse ne viennent jamais aux concerts ? Parce qu'ils ont peur de rouiller dans le pogo !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un punk dit à un autre punk qui a perdu son épingle à nourrice ? « Ne t'en fais pas, ça va s'arranger, on va tout raccommoder. »", "si": {}, "geste": "rire"},
		{"t": "Combien de punks faut-il pour changer une ampoule ? Un pour la changer, et trente pour en discuter en assemblée. Et Fusible pour la brancher sur la grue.", "si": {}, "geste": "rire"},
		{"t": "Comment on appelle un rat qui joue de la batterie ? Un rat-ta-ta-tam ! … Bon. Celle-là, c'est Tapage qui me l'a apprise. Il la raconte depuis 1977.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Ici, les prix sont tout petits et les sourires sont gratuits. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Pas pour toi, pas aujourd'hui. Reviens quand on se sera réconciliés. Avec un sourire, ça ira plus vite.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Fais-en bon usage !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Va manger à la Cantine de Lentille : là-bas, tu paies ce que tu peux.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Ici, on évite d'avoir deux fois la même chose : il y a toujours quelqu'un qui en a zéro.", "si": {}}],
	"achat_plein": [{"t": "Ton sac déborde, {surnom}. Dépose un truc à la Gratuiterie, Trocante sera ravie.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et un patch des Rats de Cale en pensée !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… Ici, on ne laisse personne sur le carreau. Un petit geste. Ne le dis pas à Lisse : il appellerait ça « une perte non optimisée ».", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont déjà plus petits qu'une épingle à nourrice. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. J'ai une mémoire d'éléphant. D'éléphant à crête.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Ouais !", "Trop bien !", "Ha ha !", "Quel boucan !"],
		"neutre": ["Bon.", "Ouais…", "Hm.", "Alors…"],
		"triste": ["Bof…", "La loose…", "Pff…", "Aïe aïe aïe…"],
		"colere": ["Par les clous de mon perfecto !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["C'est fait maison.", "Comme on dit à l'assemblée.", "Ça, c'est punk !", "Do it yourself."],
	"humeur_mots": [[0.6, "à fond"], [0.25, "de bonne humeur"], [-0.25, "un peu ronchon"], [-0.6, "grognon"], [-2.0, "en colère comme un larsen"]],
	"surnoms": [[0, "le nouveau"], [25, "camarade"], [50, "mon pote"], [75, "frère de pogo"], [95, "légende du Boucan"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
## Les cheveux teints du Boucan, et quelques couleurs naturelles.
const ROUGE_VIF := [0.92, 0.08, 0.1]
const VERT_FLUO := [0.25, 0.88, 0.3]
const BLEU_ELEC := [0.12, 0.42, 0.95]
const ROSE_VIF := [1.0, 0.38, 0.66]
const VIOLET_VIF := [0.55, 0.16, 0.85]
const PLATINE := [0.97, 0.96, 0.92]
const ORANGE_VIF := [1.0, 0.5, 0.08]
const TURQUOISE := [0.15, 0.78, 0.72]
const PRUNE_C := [0.45, 0.1, 0.32]
const LAVANDE := [0.72, 0.58, 0.88]
const JAUNE_PAILLE := [0.96, 0.88, 0.42]
const ROUX := [0.82, 0.3, 0.1]
const GRIS := [0.6, 0.6, 0.58]
const BLANC := [0.93, 0.92, 0.9]
const BRUN := [0.3, 0.19, 0.11]
const CHATAIN := [0.45, 0.3, 0.17]
const NOIR := [0.08, 0.06, 0.05]
const Y_BLEU := [0.25, 0.45, 0.7]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BRUN := [0.32, 0.2, 0.12]
const Y_GRIS := [0.45, 0.5, 0.55]
const Y_VIOLET := [0.5, 0.32, 0.7]
const Y_AMBRE := [0.7, 0.48, 0.15]


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
	out["groupe"] = "boucan"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Conserverie et les Rats de Cale
		{"id": "rouille", "nom": "Rouille", "titre": "chanteuse des Rats de Cale", "maison": "porte_rouille", "village": "boucan",
			"agenda": [[10, 12, "conserverie_assemblee"], [12, 14, ["cantine_table_1", "cantine_table_2"]], [14, 17, ["place_arbre", "quai_1", "rue_1"]], [17, 19, "halle_scene_chant"], [19, 21, ["cantine_table_3", "halle_comptoir"]], [21, 23.5, "halle_scene_chant"], [23.5, 10, "maison"]],
			"azur": {"cheveux": ROUGE_VIF, "coiffure": "crete", "yeux": Y_VERT, "haut": [0.08, 0.08, 0.09], "taille": 0.98},
			"teinte": PEAU[1],
			"punk": {"tenue": "perfecto", "clous": true, "patchs": true, "objet": "micro"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.75, "curiosite": 0.7, "susceptible": 0.35, "rancunier": 0.1},
			"aime": {"limonade_boucan": 2.0, "patch_rat": 2.5, "affiche_concert": 2.0, "soupe_prix_libre": 1.5, "sirop_menthe": 1.5}, "deteste": {"plans_lisse": -2.0, "badge_usine": -1.0},
			"tics": ["OUAIS !", "On lâche rien !", "Un, deux, trois, BOUCAN !", "Ça, c'est du rock."],
			"surnoms": [[0, "le nouveau"], [25, "camarade"], [50, "mon pote de fosse"], [75, "membre d'honneur"], [95, "cinquième Rat de Cale"]],
			"repliques": {
				"accueil": [
					L("HÉ ! Un nouveau visage ! Bienvenue à Port-Boucan, la ville où personne n'est de trop ! Moi, c'est Rouille. Je chante dans les Rats de Cale, j'organise un peu tout, et je crie beaucoup. Pas parce que je suis fâchée : c'est ma voix normale. Tu veux que je te présente du monde ?", {"visites_max": 1, "q56": "bo_bienvenue="}, "salut"),
					L("{surnom} ! Te revoilà ! Tu as faim ? Tu as soif ? Tu as envie de crier ? Les trois se soignent ici. Dans cet ordre-là.", {"visites_min": 2}, "rire"),
					L("Le héros du Grand Boucan ! Viens là que je te serre dans mes bras cloutés. Ça pique un peu. C'est de l'affection.", {"q56": "bo_concert=finie"}, "rire"),
				],
				"humeur": [
					L("À FOND ! J'ai chanté hier soir jusqu'à ne plus avoir de voix. Ce matin, elle est revenue. Elle revient toujours. Elle est fidèle, ma voix.", {}, "rire"),
					L("Un peu inquiète. Les robots de Lisse ont volé notre matériel : la guitare de Clou, l'ampli, les baguettes. Sans eux, le Grand Boucan va faire… un petit boucan. Je déteste les petits boucans.", {"q56": "bo_concert=en_cours"}),
					L("Gédéon ! À la batterie ! Tu l'as entendu ? Il joue comme un orage qui aurait pris des cours ! Tapage a pleuré. Il dit que c'est la poussière. Il n'y a pas de poussière sur scène, on a balayé.", {"a_trouve": "gedeon_batteur"}, "rire"),
					L("Le soir, avant de monter sur scène, j'ai les mains qui tremblent. Toujours. Et puis Mouette fait la mouette, Clou hoche la tête, et je n'ai plus peur.", {"soir": true}),
				],
				"lui": [
					L("Je suis arrivée au Boucan à douze ans, avec un sac à dos et une très grande bouche. Mamie Barricade m'a donné une chambre au troisième étage de la Conserverie et une écharpe cloutée. Elle m'a dit : « Ici, tu peux crier. » Alors j'ai crié. Je n'ai jamais arrêté.", {}),
					L("Les Rats de Cale, on les a fondés à dix-sept ans, avec Clou et Mouette, dans la cale de la Baleine Rouillée. D'où le nom. Il y avait vraiment des rats. Ils sont restés pour la musique. Ce sont nos premiers fans.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma crête, je la teins en rouge tous les dimanches, avec une teinture que Pigment fabrique avec des betteraves. Quand il pleut, je laisse des petites traces roses partout. Lentille dit que je suis la seule chanteuse qu'on peut suivre à la trace.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Port-Boucan, c'était une friche : un port fermé, des usines vides, du gris partout. On est venus, on a ouvert les portes, on a repeint les murs, on a planté des tomates sur les toits. Maintenant, c'est la ville la plus bruyante et la plus gentille de l'archipel.", {}),
					L("La Halle Hurlante, c'est notre salle de concert, l'ancienne halle des forges, au milieu de la ville. Tous les soirs à vingt et une heures, on joue. C'est gratuit. Viens pogoter dans la fosse : on saute, on se cogne gentiment, on se relève les uns les autres. C'est ça, le pogo.", {"sujet_min": ["ile", 1]}),
					L("Monsieur Lisse veut tout raser pour construire son « Lisse-Center ». Une galerie marchande éternelle. Éternelle ! Rien que d'y penser, j'ai mal aux oreilles. Et pourtant, mes oreilles en ont vu.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Tapage raconte qu'il a joué devant cent mille personnes sur le dos d'une baleine. Hier, c'était devant dix mille. La baleine rapetisse chaque fois que Mamie Barricade est dans la pièce.", {}, "rire"),
					L("Prune, la secrétaire de Lisse, vient aux concerts avec une moustache en carton. Elle croit que personne ne la reconnaît. Tout le monde la reconnaît. Personne ne dit rien. On l'aime bien, la moustache.", {}, "rire"),
					L("Il y a un garçon en costume trop grand qui reste à l'entrée de la Halle tous les soirs. Il tapote le mur en rythme. En rythme parfait. Je ne sais pas qui c'est, mais il a des mains en or.", {"pas_trouve": "gedeon_batteur"}),
				],
				"interpelle": [L("HÉ ! Toi ! Oui, toi ! Viens dire bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Concert ce soir ! Tu viens ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "clou", "nom": "Clou", "titre": "guitariste des Rats de Cale", "maison": "porte_clou", "village": "boucan",
			"agenda": [[11, 13, "cargo_pont"], [13, 14, "cantine_table_2"], [14, 17, ["quai_2", "grue", "conserverie_toit_jardin"]], [17, 19, "halle_scene_guitare"], [19, 21, "conserverie_toit_jardin"], [21, 23.5, "halle_scene_guitare"], [23.5, 11, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "crete", "yeux": Y_GRIS, "haut": [0.1, 0.1, 0.12], "taille": 1.16, "carrure": 0.78},
			"teinte": PEAU[4],
			"punk": {"tenue": "perfecto", "clous": true, "patchs": true, "objet": "guitare"},
			"humeur_base": 0.4, "traits": {"bavard": 0.1, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"guitare_rouille": 3.0, "gateau_miel": 2.0, "pain_miel": 1.5, "the_menthe": 1.5, "partition": 2.0}, "deteste": {"plans_lisse": -1.5, "vieille_botte": -0.5},
			"tics": ["Mh.", "Ouais.", "… (Il hoche la tête.)", "Germaine est d'accord."],
			"surnoms": [[0, "toi"], [25, "toi, là"], [50, "pote"], [75, "frérot"], [95, "frérot pour toujours"]],
			"repliques": {
				"accueil": [
					L("… Salut. (Il hoche la tête.) Clou. Guitare. (Il montre la guitare.) Elle, c'est Germaine. Germaine-la-Terrible. Elle dit bonjour aussi.", {"visites_max": 1, "pas_trouve": "grand_boucan"}, "salut"),
					L("… (Il lève deux doigts.) {surnom}. Ça va. Germaine aussi.", {"visites_min": 2}),
					L("Tu as ramené Germaine. (Il la serre contre lui très longtemps.) … Merci. Vraiment. C'était le plus long discours de ma vie.", {"q56": "bo_concert=finie", "visites_max": 4}),
				],
				"humeur": [
					L("Bien. (Un temps.) Très bien, même. Mouette a ri toute la matinée. Ça fait du bien, une matinée qui rit.", {}),
					L("Sans Germaine… (Il regarde ses mains vides.) Je joue sur une raquette de tennis. Ça ne sonne pas. Ça fait « poc ».", {"q56": "bo_concert=en_cours"}),
					L("Le soir, sur le toit, je joue tout doucement pour les tomates de Radis. Il dit qu'elles poussent mieux. Je le crois.", {"soir": true}),
				],
				"lui": [
					L("J'ai fabriqué Germaine moi-même. Le manche vient d'une rampe d'escalier de la Filature. Le corps, d'une porte de la Baleine Rouillée. Les cordes, je les ai achetées. Il y a des limites au fait-maison.", {}),
					L("Je ne parle pas beaucoup. Germaine parle pour moi. Fort. Très fort. Mamie Barricade dit que j'ai tout mis dans la guitare et rien gardé pour la bouche. Elle a raison. Comme toujours.", {"sujet_min": ["lui", 1]}),
					L("Mamie Barricade m'a appris à tricoter. Je tricote les housses de guitare de tout le monde. Avec des clous dessus. Douces dedans, piquantes dehors. Comme nous.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Cargo, la Baleine Rouillée, au nord-ouest. On a commencé dans sa cale. Le matin, j'y vais sur le pont. Je regarde la mer. Elle fait « chhh ». C'est un bon public.", {}),
					L("La Halle Hurlante. Ma place est à gauche de la scène. Rouille au milieu. Mouette à droite. Et derrière… un batteur différent chaque soir. (Il soupire très longtemps.)", {"sujet_min": ["ile", 1]}),
					L("Ferraille, à la Casse, m'a soudé des clous sur la tête de Germaine. Pour le style. Elle est contente. Moi aussi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le garçon en costume, à l'entrée de la Halle. Je l'ai entendu taper sur une poubelle. … Une poubelle. Et c'était beau. (Il hoche la tête, très sérieux.)", {"pas_trouve": "gedeon_batteur"}),
					L("Hier, le remplaçant à la batterie, c'était Boulon. Il a cassé la grosse caisse. Avec douceur. Il s'est excusé auprès d'elle.", {}, "rire"),
					L("Gédéon. (Long silence. Il sourit.) Enfin.", {"a_trouve": "gedeon_batteur"}),
				],
				"interpelle": [L("… Hé.", {"visites_max": 0}), L("{surnom}. (Un petit signe de tête.)", {"visites_min": 1}, "salut")],
			}},
		{"id": "mouette", "nom": "Mouette", "titre": "bassiste des Rats de Cale", "maison": "porte_mouette", "village": "boucan",
			"agenda": [[9, 12, ["quai_3", "quai_1"]], [12, 14, "cantine_table_3"], [14, 17, ["bassin_sec_1", "place_jeu_1", "quai_3"]], [17, 19, "halle_scene_basse"], [19, 21, "halle_comptoir"], [21, 23.5, "halle_scene_basse"], [23.5, 9, "maison"]],
			"azur": {"cheveux": BLEU_ELEC, "coiffure": "boucles", "yeux": Y_BRUN, "haut": [0.3, 0.42, 0.62], "taille": 0.94},
			"teinte": PEAU[3],
			"punk": {"tenue": "veste_jean", "clous": false, "patchs": true, "objet": "basse"},
			"humeur_base": 0.75, "traits": {"bavard": 0.8, "humour": 1.0, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"sardine": 2.5, "sardines_grillees": 2.5, "glace": 2.0, "limonade_boucan": 1.5, "coquillage": 1.5}, "deteste": {"plans_lisse": -1.5, "galette_algue": -1.0},
			"tics": ["KIAAA !", "Ha ha ha !", "Kia-kia !", "Je rigole, je rigole."],
			"surnoms": [[0, "petit poisson"], [25, "mon goéland"], [50, "ma frite préférée"], [75, "mon albatros"], [95, "ma mouette de cœur"]],
			"repliques": {
				"accueil": [
					L("KIAAA ! KIA-KIA ! … Ha ha ha ! Pardon, c'est comme ça que je dis bonjour. Je m'appelle Mouette, je joue de la basse dans les Rats de Cale, et je fais très bien la mouette. Trop bien. Les vraies viennent me demander des frites.", {"visites_max": 1}, "rire"),
					L("{surnom} ! KIAAA ! Tu tombes bien, je m'ennuyais depuis au moins quatre secondes !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Ce matin, une mouette m'a répondu. Elle a dit « kia ». Je crois que c'était une insulte. J'ai ri quand même.", {}, "rire"),
					L("Ma basse est restée, mais sans l'ampli, elle fait « blom-blom » tout bas. On dirait une baleine qui chuchote. C'est mignon, mais pour un concert, c'est léger.", {"q56": "bo_concert=en_cours"}),
					L("Le soir, avant le concert, je bois une limonade au bar de Sirène. Elle me la sert avec une paille en forme de mouette. Elle l'a fabriquée pour moi. Je l'adore, Sirène.", {"soir": true}),
				],
				"lui": [
					L("J'ai appris la basse sur un manche à balai avec trois élastiques. Ça faisait « bzoing ». Rouille m'a entendue et elle a dit : « Toi, tu as le rythme. » J'avais quatorze ans. J'ai encore le balai. Il est retraité.", {}),
					L("Pourquoi je ris tout le temps ? Parce que c'est plus facile que de pleurer, et que ça fait moins de vaisselle. Et parce qu'ici, il se passe toujours quelque chose de drôle. Hier, Cradoc est tombé de son monocycle dans la fontaine. Avec élégance.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mes cheveux sont bleus parce qu'un jour j'ai voulu ressembler à la mer. Mouette a dit Rouille, et le surnom est resté. Mon vrai prénom ? Je ne le dis qu'à la mer. Et elle ne le répète pas.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Vieux Bassin, au nord, c'est le port. Il y a les deux vieilles grues, les conteneurs, et des milliers de mouettes. Ce sont mes cousines. Elles ne le savent pas encore.", {}, "rire"),
					L("Le Bassin à sec, à l'est du port, c'est le skatepark. Tornade y fait des figures incroyables. Moi j'y fais une seule figure : je tombe. Mais je tombe avec style.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Plage aux Galets, tout au sud-est : Gravier y pêche. Il ne parle presque pas. Moi je parle tout le temps. Ensemble, ça fait une conversation normale.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Larsen dit que je joue trop fort. Larsen dit tout trop fort. On s'entend très bien, mais de loin.", {}, "rire"),
					L("Cradoc m'a appris à cracher des bulles. J'en ai fait une si grosse qu'une mouette est restée coincée dedans. Elle est repartie toute brillante. Elle m'en veut encore.", {}, "rire"),
					L("Patchouli a lu dans les pigeons que je serais célèbre. Ou que je mangerais une frite. Les pigeons n'étaient pas d'accord entre eux.", {}, "rire"),
				],
				"interpelle": [L("KIAAA ! Hé, toi !", {"visites_max": 0}, "rire"), L("Kia-kia, {surnom} !", {"visites_min": 1}, "salut")],
			}},
		{"id": "barricade", "nom": "Mamie Barricade", "titre": "fondatrice du squat de la Conserverie", "maison": "porte_barricade", "village": "boucan",
			"agenda": [[7, 9, "conserverie_toit_jardin"], [9, 12, "conserverie_assemblee"], [12, 14, "cantine_table_4"], [14, 18, ["conserverie_entree", "place_banc_1"]], [18, 21, "conserverie_assemblee"], [21, 23.5, "halle_mezzanine"], [23.5, 7, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "crete_courte", "yeux": Y_BLEU, "haut": [0.18, 0.28, 0.48], "vieux": true, "lunettes": true, "taille": 0.9, "carrure": 1.2},
			"teinte": PEAU[2],
			"punk": {"tenue": "bleu_travail", "clous": true, "patchs": true, "objet": "aiguilles", "lunettes": true},
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.2},
			"aime": {"the_menthe": 2.0, "bail_collectif": 3.0, "pain_miel": 1.5, "tarte_potiron": 2.0, "plans_lisse": 2.5}, "deteste": {"badge_usine": -1.0, "vieille_botte": -0.5},
			"tics": ["Mon grand.", "On vote ?", "Un rang à l'endroit, un rang à l'envers.", "J'en ai vu d'autres."],
			"surnoms": [[0, "mon grand"], [25, "mon petit clou"], [50, "mon trésor clouté"], [75, "mon héritier"], [95, "la relève du Boucan"]],
			"repliques": {
				"accueil": [
					L("Approche, mon grand, je ne mords pas. Je tricote. Mamie Barricade, docker pendant quarante ans, fondatrice de ce squat, et présidente des assemblées. Tu veux une écharpe ? Elle a des clous. Elle tient chaud et elle impressionne les robots.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Assieds-toi deux minutes. Tu cours trop. À ton âge, je courais aussi. Avec une caisse de sardines sur chaque épaule.", {"visites_min": 2}),
					L("Le Bail collectif. Signé. (Elle le caresse comme un chat.) Quarante ans que je l'attendais. Viens que je t'embrasse, mon héritier.", {"q56": "bo_lisse=finie"}),
				],
				"humeur": [
					L("Bonne ! L'assemblée de ce matin a duré quatre heures. On a voté la couleur du nouveau portail. Rose, à vingt-trois voix contre une. La voix contre, c'était Tapage. Il voulait « noir, comme en 1977 ».", {}, "rire"),
					L("Inquiète, mon grand. Les robots de Lisse sont revenus ce matin. Ils ont demandé poliment de libérer les lieux. Je leur ai demandé poliment de libérer le trottoir.", {"q56": "bo_robots="}),
					L("Le soir, je monte à la mezzanine de la Halle, et je regarde tout ce petit monde sauter. Ça me rappelle les quais à la fin du travail. On sautait aussi. De joie, et parce que le béton était froid.", {"soir": true}),
				],
				"lui": [
					L("J'ai porté des caisses sur ce port pendant quarante ans. Des sardines, des oranges, des machines, une girafe une fois. Elle était très polie. Et puis le port a fermé. Les gens sont partis. Moi, je suis restée. On ne quitte pas un port qu'on a porté sur son dos.", {}),
					L("Le jour où Lisse & Fils a voulu raser la Conserverie, je me suis assise devant la porte avec mes aiguilles et une pelote. Trois semaines. J'ai tricoté une écharpe de douze mètres. Les bulldozers sont repartis. Ils ne savaient pas comment passer l'écharpe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma crête, je l'ai depuis que j'ai soixante ans. Avant, je n'osais pas. Rouille m'a dit : « Mamie, c'est maintenant ou jamais. » J'ai dit maintenant. Je n'ai jamais regretté. Sauf les jours de grand vent.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Conserverie, l'ancienne usine de sardines, c'est notre grande maison. En bas, la Cantine de Lentille et la Gratuiterie de Trocante. Aux étages, les chambres. Et sur le toit, le jardin et la salle des assemblées. Tout le monde y parle. Même les timides. Surtout les timides.", {}),
					L("À l'assemblée, la règle est simple : on lève la main, on parle, on écoute. Et personne ne coupe la parole. Sauf Tapage. Mais lui, on a voté une exception : il a droit à une interruption par jour. Il les garde pour le dimanche.", {"sujet_min": ["ile", 1]}, "rire"),
					L("L'Usine Grise de Lisse & Fils, au sud-est, au milieu du bois. Tout ce qui sort de là est gris, propre et poli. Les robots, les drones, les panneaux. Un jour, il faudra aller voir ce qu'il y a dedans. Pas moi : mes genoux. Mais quelqu'un de vaillant.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Tapage dit que le grand concert de la Halle, c'était en 1977. C'était en 1978. J'y étais. J'avais une écharpe jaune. Lui, il avait encore des cheveux noirs. Et il jouait faux.", {}, "rire"),
					L("Le petit Aldric Lisse, je l'ai connu tout gamin, sur les quais, quand son père venait compter les caisses. Il m'aidait à porter les oranges. Il riait fort. Je me demande où il est passé, ce petit garçon. Quelque part sous le costume gris.", {}),
					L("Lentille met une louche de plus dans l'assiette de ceux qui ne paient rien. Il croit que je ne le vois pas. Je le vois. Je fais pareil avec les écharpes.", {}),
				],
				"interpelle": [L("Toi, là ! Viens donc voir une vieille dame.", {"visites_max": 0}), L("{surnom} ! Viens t'asseoir, j'ai gardé une écharpe pour toi.", {"visites_min": 1}, "salut")],
			}},
		{"id": "lentille", "nom": "Lentille", "titre": "cuisinier de la Cantine à prix libre", "maison": "porte_lentille", "village": "boucan",
			"agenda": [[6, 8, ["jardins_1", "jardins_2"]], [8, 15, "cantine_cuisine"], [15, 16, "place_camion"], [16, 22, "cantine_cuisine"], [22, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.85, 0.42, 0.15], "tablier": [0.95, 0.92, 0.85], "carrure": 1.4},
			"teinte": PEAU[3],
			"punk": {"tenue": "tablier", "patchs": true, "objet": "louche", "chapeau": "bandana"},
			"humeur_base": 0.65, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"panier_legumes": 2.5, "champignon": 1.5, "miel": 1.5, "pomme": 1.0, "graines": 1.0}, "deteste": {"plans_lisse": -1.5, "galette_algue": -0.5},
			"boutique": {"vend": {"soupe_prix_libre": 1, "pain_miel": 2, "galette_sarrasin": 2, "pomme": 1}, "achete": {"panier_legumes": 2, "champignon": 1, "pomme": 1, "baies": 1, "graines": 1, "miel": 3}},
			"tics": ["Goûte-moi ça !", "Ça mijote.", "Une louche de plus ?", "Paie ce que tu peux."],
			"surnoms": [[0, "mon petit pois"], [25, "ma carotte"], [50, "mon poireau"], [75, "ma grande marmite"], [95, "mon potage d'or"]],
			"repliques": {
				"accueil": [
					L("Ah ! Un estomac nouveau ! Entre, entre ! Lentille, cuisinier de la Cantine à prix libre. Ici, tu paies ce que tu peux : zéro, une pièce, dix pièces. Celui qui a beaucoup paie pour celui qui n'a rien, et tout le monde mange. Et tout le monde ressert.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu arrives pile : la soupe vient de faire « blop ». Le blop, c'est le signal.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! J'ai fait une soupe de courges, de pommes et de châtaignes. Quarante bols. Quarante bols vides. Un bol vide, c'est un compliment qui ne parle pas.", {}, "rire"),
					L("Mes paniers de légumes ne sont pas arrivés des Jardins Partagés. Sans légumes, ma soupe, c'est de l'eau chaude avec de l'espoir dedans.", {"q56": "bo_cantine=en_cours"}),
					L("Le soir, je fais la vaisselle en chantant les chansons des Rats de Cale. Les assiettes adorent. Les verres un peu moins : ils vibrent.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Avant, j'étais cuisinier dans un grand restaurant chic. On servait des petits pois un par un, sur des assiettes immenses, avec une pince. Un jour, un enfant a demandé s'il pouvait avoir « un vrai repas ». J'ai démissionné le soir même. Je suis venu ici avec ma louche.", {}),
					L("Ma louche s'appelle Pépite. Elle est énorme : une louche, c'est un bol entier. Rouille dit que c'est une louche de punk. Moi je dis que c'est une louche de partage. Elle est d'accord avec nous deux.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le prix libre, ça marche. Je n'y croyais pas au début. Et puis un jour, Boulon a payé trente pièces pour un bol, et il a dit : « C'est pour les trois prochains qui n'auront rien. » Ce jour-là, j'ai pleuré dans la soupe. Elle était un peu trop salée.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Cantine est au rez-de-chaussée de la Conserverie, à côté de la Gratuiterie de Trocante. Six grandes tables, des bancs en palettes faits par Copeau, et une marmite grande comme une baignoire.", {}),
					L("Mes légumes viennent des Jardins Partagés de Radis, à l'est de la ville. Il les fait pousser, je les fais mijoter. Lui leur parle avant, moi je leur parle après. Ils ne s'ennuient jamais.", {"sujet_min": ["ile", 1]}),
					L("L'après-midi, je fais une pause au camion-cuisine de la Place des Palettes. J'y teste des recettes. Hier : la crêpe à la soupe. Ce n'était pas une bonne idée. Mais c'était une idée.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Mamie Barricade vient tous les midis à la même table, et elle laisse toujours trois pièces sous son bol. Toujours trois. Elle dit que c'est pour « la soupe d'un inconnu ». Je l'adore.", {}),
					L("Tapage mange quatre bols et paie avec une histoire. Une histoire de concert. Elles sont fausses, mais elles sont tellement bonnes qu'elles valent bien quatre bols.", {}, "rire"),
					L("Monsieur Lisse est venu manger une fois, déguisé. Il a demandé « le menu optimisé ». Je lui ai servi une soupe et un sourire. Il a fini la soupe. Il a laissé dix pièces. Il ne l'a dit à personne.", {}),
				],
				"interpelle": [L("Hé ! Tu as faim ? Tu as une tête à avoir faim !", {"visites_max": 0}), L("{surnom} ! Une louche ?", {"visites_min": 1}, "salut")],
				"boutique": [L("Soupe, pain au miel, galettes ! Tout est fait maison, tout est petit prix. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "trocante", "nom": "Trocante", "titre": "gardienne de la Gratuiterie", "maison": "porte_trocante", "village": "boucan",
			"agenda": [[9, 12, "gratuiterie"], [12, 13, "cantine_table_5"], [13, 19, "gratuiterie"], [19, 21, ["place_banc_2", "rails_wagon"]], [21, 23.5, "halle_fosse_12"], [23.5, 9, "maison"]],
			"azur": {"cheveux": VIOLET_VIF, "coiffure": "chignon", "yeux": Y_VIOLET, "haut": [0.62, 0.35, 0.2], "robe": [0.55, 0.32, 0.45], "lunettes": true, "carrure": 1.1},
			"teinte": PEAU[0],
			"punk": {"tenue": "robe_recup", "patchs": true, "objet": "panier", "lunettes": true},
			"humeur_base": 0.55, "traits": {"bavard": 0.9, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"boite_a_rien": 2.5, "canard_mecanique": 2.0, "carte_postale": 2.0, "cerf_volant": 1.5, "vieille_botte": 1.0}, "deteste": {"plans_lisse": -1.5},
			"boutique": {"vend": {"boite_a_rien": 0, "carte_postale": 0, "cerf_volant": 1, "chaussettes_vapeur": 1, "lunettes_kaleido": 1, "canard_mecanique": 1}, "achete": {}},
			"tics": ["Rien ne se jette !", "Tout se donne !", "Il a une histoire, celui-là.", "Prends, prends."],
			"surnoms": [[0, "mon trésor trouvé"], [25, "mon bibelot"], [50, "ma perle de récup"], [75, "mon objet préféré"], [95, "le trésor de ma Gratuiterie"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à la Gratuiterie ! Ici, rien ne se vend, rien ne se jette : tout se donne ! Tu as un objet qui s'ennuie chez toi ? Pose-le. Tu as besoin de quelque chose ? Prends-le. Un par jour, pour que tout le monde en profite. Je suis Trocante, et je connais l'histoire de chaque chose.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Il est arrivé un objet ce matin qui te ressemble. Une boussole qui indique toujours la cantine. Ça ne te dit rien ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Formidable ! Quelqu'un a déposé un parapluie qui s'ouvre tout seul quand il entend le mot « pluie ». Je l'ai appelé Gaston. Il est très nerveux.", {}, "rire"),
					L("Un peu triste. La théière à fleurs est repartie ce matin. Elle a fait le tour de l'île quatorze fois, et elle revient toujours. Elle me manque déjà. Elle reviendra.", {}),
					L("Le soir, je vais danser dans la fosse de la Halle. Au fond, à droite. On m'a déjà prise pour un tas de vêtements oubliés. C'est ma robe : elle est faite de vingt-deux robes.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Avant, j'avais tout. Une grande maison pleine de beaux objets, et personne dedans. Un jour, j'ai tout posé sur le trottoir, avec un panneau : « Servez-vous. » Les gens sont venus, ils ont pris, ils ont parlé, ils sont revenus. Je n'ai plus rien et j'ai plein d'amis. Le compte est bon.", {}),
					L("Chaque objet a une histoire. Ce bouton ? Il a tenu le manteau d'un capitaine. Cette cuillère ? Elle a mangé la soupe de Lentille trois cents fois. Ce caillou ? Bon, c'est un caillou. Mais il a voyagé.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma robe, je l'ai cousue avec Velours, avec un morceau de chaque vêtement qu'on m'a donné la première année. Vingt-deux robes en une. Quand je la porte, j'ai l'impression d'être serrée dans les bras de tout le Boucan.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Gratuiterie est au rez-de-chaussée de la Conserverie, à côté de la Cantine. Avant, c'était la salle où on rangeait les boîtes de sardines vides. Aujourd'hui, on y range les objets pleins d'histoires.", {}),
					L("Le vieux wagon sur les rails rouillés, c'est mon coin de lecture du soir. Il ne va nulle part. C'est ce que j'aime chez lui.", {"sujet_min": ["ile", 1]}),
					L("Ferraille, à la Casse, récupère ce qui est cassé. Moi, ce qui marche encore. Rustine, ce qui roule. À nous trois, on ne laisse rien partir à la poubelle. Même pas la poubelle : Copeau en a fait un fauteuil.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Tapage a déposé sa vieille paire de rangers il y a deux ans. Il est venu la reprendre le lendemain. Il la redépose chaque lundi et la reprend chaque mardi. Je crois qu'il vient surtout pour discuter.", {}, "rire"),
					L("Patchouli m'a prédit que je recevrais « un objet mystérieux venu du ciel ». Le lendemain, une mouette a laissé tomber une chaussette dans ma Gratuiterie. Je l'ai rangée au rayon « mystères ».", {}, "rire"),
					L("Mademoiselle Prune passe parfois, en lunettes noires, et prend un vieux disque des Rats de Cale. Elle le cache dans son dossier « Expulsions ». Personne ne cherche jamais dans ce dossier.", {}),
				],
				"interpelle": [L("Hé ! Tu veux un objet ? Ou en donner un ?", {"visites_max": 0}), L("{surnom} ! J'ai un nouvel objet avec une histoire !", {"visites_min": 1}, "salut")],
				"boutique": [L("Tout est gratuit, ou presque : une pièce, c'est juste pour le geste. Prends ce qui te rend heureux. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "pastille", "nom": "Pastille", "titre": "infirmière bénévole du Point Soins", "maison": "porte_pastille", "village": "boucan",
			"agenda": [[8, 12, "conserverie_entree"], [12, 13, "cantine_table_5"], [13, 18, ["conserverie_entree", "bassin_sec_2"]], [18, 21, ["place_banc_1", "place_fontaine"]], [21, 23.5, "halle_comptoir"], [23.5, 8, "maison"]],
			"azur": {"cheveux": ROSE_VIF, "coiffure": "queue", "yeux": Y_BLEU, "haut": [0.92, 0.94, 0.95], "taille": 0.97},
			"teinte": PEAU[5],
			"punk": {"tenue": "sweat", "patchs": true, "chapeau": "bandana"},
			"humeur_base": 0.45, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"the_menthe": 2.0, "miel": 1.5, "sirop_menthe": 1.5, "gateau_miel": 1.5, "patch_rat": 1.5}, "deteste": {"vieille_botte": -0.5, "plans_lisse": -1.0},
			"tics": ["Respire.", "Ça va aller.", "Montre-moi ça.", "Un pansement ?"],
			"surnoms": [[0, "mon petit patient"], [25, "mon genou écorché"], [50, "mon patient préféré"], [75, "mon courageux"], [95, "mon héros pansé"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Respire. Voilà. Je suis Pastille, infirmière bénévole au Point Soins, à l'entrée de la Conserverie. Bosses, bobos, chutes de skate, coups de soleil, chagrins : tout se soigne. Pour les chagrins, j'ai des pansements à motif de chaton.", {"visites_max": 1}, "salut"),
					L("{surnom}. Montre-moi tes genoux. … Bon, ça va. Pour une fois.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Calme. Ce matin, seulement trois genoux de Tornade, un coude de Cradoc et une écharde de Copeau. Une matinée tranquille.", {}),
					L("Fatiguée, mais contente. Après une Descente des Déménageurs, tout le monde a des bleus aux bras à force de se tenir par les coudes. Des bleus d'amitié. Je les soigne avec du respect.", {"a_trouve": "descente_repoussee"}),
					L("Le soir, je tiens le comptoir des bouchons d'oreilles à la Halle. Larsen dit que c'est le stand le plus important de la ville. Il le crie, évidemment.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'étais infirmière dans un grand hôpital, avec des couloirs blancs et des néons qui grésillaient. Un soir, on m'a amené Rouille, une cheville tordue après un saut de scène. Elle chantait sur le brancard. Je l'ai raccompagnée au Boucan. Je ne suis jamais repartie.", {}),
					L("Mes pansements, je les dessine moi-même avec Cerise : des crânes souriants, des crêtes, des chatons à épingles à nourrice. Les enfants tombent exprès pour en avoir. Ça me fait beaucoup de travail. Et beaucoup de joie.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un truc : je n'aime pas la musique forte. Du tout. Mais je viens à tous les concerts, avec deux paires de bouchons. Parce que j'aime voir les gens heureux. Et ça, ça s'entend même avec des bouchons.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Point Soins, c'est une petite pièce à l'entrée de la Conserverie, avec une croix rouge peinte par Pigment. Elle a ajouté une crête à la croix. Je n'ai pas eu le cœur de dire non.", {}, "rire"),
					L("L'après-midi, je m'installe près du Bassin à sec, le skatepark. C'est plus pratique : les genoux écorchés arrivent directement.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Mère Morille, dans la Cathédrale des Spores, connaît toutes les plantes qui soignent. Elle m'a appris le pansement à la feuille de plantain. Mais elle répète toujours : « Ne mange jamais un champignon que tu ne connais pas. » Elle a raison. J'ai soigné assez de ventres pour le savoir.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Cradoc tombe de son monocycle quatre fois par jour. J'ai fini par lui coudre des coussins dans le pantalon. Il dit que ça améliore son équilibre. Ça améliore surtout ses atterrissages.", {}, "rire"),
					L("Chaussette m'amène ses chiens quand ils ont une épine dans la patte. Les six. Même si un seul a une épine. Par solidarité.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Tu n'es pas blessé, au moins ?", {"visites_max": 0}), L("{surnom}. Tout va bien ? Respire.", {"visites_min": 1}, "salut")],
			}},
		{"id": "tapage", "nom": "Tapage", "titre": "vieux punk légendaire", "maison": "porte_tapage", "village": "boucan",
			"agenda": [[10, 12, "place_banc_2"], [12, 14, "cantine_table_6"], [14, 18, ["rails_wagon", "place_banc_2", "quai_2", "gratuiterie"]], [18, 21, ["halle_comptoir", "place_banc_2"]], [21, 23.5, "halle_scene_batterie"], [23.5, 10, "maison"]],
			"azur": {"cheveux": PLATINE, "coiffure": "crete", "barbe": "moustache", "yeux": Y_GRIS, "haut": [0.12, 0.12, 0.12], "vieux": true, "carrure": 0.92},
			"teinte": PEAU[1],
			"punk": {"tenue": "perfecto", "clous": true, "patchs": true, "objet": "baguettes", "lunettes": true},
			"humeur_base": 0.55, "traits": {"bavard": 1.0, "humour": 0.85, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"baguettes": 2.5, "patch_rat": 2.0, "fanzine": 2.0, "soupe_prix_libre": 1.5, "partition": 1.5}, "deteste": {"plans_lisse": -1.5, "tisane_lune": -1.0},
			"tics": ["De mon temps…", "En 1977 !", "Plus fort !", "C'était énorme. ÉNORME."],
			"surnoms": [[0, "petit jeune"], [25, "jeune pousse"], [50, "mon roadie"], [75, "mon disciple"], [95, "ma relève"]],
			"repliques": {
				"accueil": [
					L("Assieds-toi, petit jeune. Tu as devant toi Tapage. LE Tapage. Celui qui a joué devant cent mille personnes en 1977, sur le dos d'une baleine, pendant une tempête. Tu ne me crois pas ? Demande à la baleine. Elle s'en souvient.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Je t'ai raconté le concert sur le toit d'un phare ? Non ? Il y avait cinquante mille personnes. Sur le phare. C'était serré.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("En pleine forme ! Hier soir, j'ai remplacé le batteur. J'ai fait un solo de onze minutes au milieu d'une chanson douce. Rouille m'a regardé. Clou m'a regardé. Mouette a ri. C'était ÉNORME.", {}, "rire"),
					L("Le petit Gédéon à la batterie… (Il renifle.) C'est la poussière. Il y a de la poussière partout, ici. (Il n'y a pas de poussière.) Il joue comme moi en 1977. En mieux. Ne le répète pas.", {"a_trouve": "gedeon_batteur"}),
					L("Le soir, je bois une limonade au bar de Sirène avant de monter sur scène. Un vrai punk, ça boit de la limonade : ça pique, et ça fait des bulles. Comme nous.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon premier groupe s'appelait Les Boulons Hurleurs. On était quatre, et on avait trois instruments. Le quatrième hurlait. C'était moi. Puis on m'a donné une batterie pour que j'arrête. Je n'ai pas arrêté. J'ai juste hurlé en tapant.", {}, "rire"),
					L("J'ai inventé le pogo. Si, si. En 1977, je suis tombé de scène, j'ai rebondi sur la foule, la foule a rebondi sur moi, et tout le monde a trouvé ça génial. Mamie Barricade dit que c'était en 1978 et que j'avais juste trébuché sur un câble. Elle ne comprend rien à l'Histoire.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma crête est blanche depuis vingt ans. Avant, elle était noire. Avant encore, verte. Avant encore, je n'avais pas de crête, j'avais une coupe au bol. On n'en parle pas. Il n'existe aucune photo. Agrafe en a une. Je le surveille.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Halle Hurlante, c'était l'ancienne halle des forges. J'y ai joué le tout premier concert, quand il y avait encore des enclumes. On s'en servait de batterie. Ça sonnait. Les voisins aussi : ils ont sonné à la porte.", {}, "rire"),
					L("Quand il n'y a pas de batteur, c'est moi qui joue. Chaque soir quelqu'un d'autre se porte volontaire, et chaque soir c'est une catastrophe. Une fois, c'était Boulon. Une autre fois, un des chiens de Chaussette. Le chien était le meilleur.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le vieux wagon sur les rails, c'est là que je raconte mes histoires l'après-midi. Les enfants viennent m'écouter. Ils ne me croient pas. Ils ont raison. Mais ils reviennent.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Larsen règle le son trop fort. Ou pas assez fort. Je ne sais plus, je n'entends plus grand-chose depuis 1977. Ou 1978.", {}, "rire"),
					L("La petite Cerise m'interviewe pour son fanzine. Je lui ai raconté le concert sur la lune. Elle a écrit « invention » au crayon dans la marge. Elle ira loin, cette gamine.", {}, "rire"),
					L("Gravier, sur sa plage, il dit un mot par jour. Moi j'en dis dix mille. On se complète. Il dit que c'est lui qui a le meilleur rapport qualité-mots.", {}, "rire"),
				],
				"interpelle": [L("Hé, petit jeune ! Tu veux une histoire vraie ? Enfin, une histoire ?", {"visites_max": 0}, "rire"), L("{surnom} ! J'en ai une nouvelle ! Elle est ÉNORME !", {"visites_min": 1}, "salut")],
			}},
		{"id": "velours", "nom": "Velours", "titre": "couturière de récup", "maison": "porte_velours", "village": "boucan",
			"agenda": [[9, 12, "atelier_couture"], [12, 13, "cantine_table_4"], [13, 19, "atelier_couture"], [19, 21, ["place_arbre", "place_banc_1"]], [21, 23.5, "halle_fosse_9"], [23.5, 9, "maison"]],
			"azur": {"cheveux": PRUNE_C, "coiffure": "carre", "yeux": Y_AMBRE, "haut": [0.5, 0.12, 0.28], "robe": [0.3, 0.1, 0.2], "carrure": 1.05},
			"teinte": PEAU[2],
			"punk": {"tenue": "robe_recup", "clous": true, "patchs": true, "objet": "aiguilles"},
			"humeur_base": 0.5, "traits": {"bavard": 0.7, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.45, "rancunier": 0.15},
			"aime": {"patch_rat": 2.0, "chaussettes_vapeur": 2.0, "plume_perroquet": 1.5, "the_menthe": 1.5, "fanzine": 1.0}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -1.0},
			"boutique": {"vend": {"patch_rat": 5}, "achete": {"plume_perroquet": 2, "plume_corbeau": 1, "chaussettes_vapeur": 2}},
			"tics": ["Un point, deux points.", "Ça manque d'un patch.", "Ne bouge pas !", "C'est cousu main."],
			"surnoms": [[0, "mon petit bouton"], [25, "ma bobine"], [50, "mon patch préféré"], [75, "mon chef-d'œuvre"], [95, "ma plus belle pièce"]],
			"repliques": {
				"accueil": [
					L("Ne bouge pas ! … Voilà. Je t'ai cousu un petit patch sur la manche pendant que tu disais bonjour. Tu n'as rien senti ? Je suis Velours, couturière de récup. Je coude des patchs sur tout. Sur les vestes, sur les sacs, sur les chiens. Les chiens adorent.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu as encore un coin de veste sans patch. Ça me fait mal aux yeux.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bonne ! J'ai cousu un patch des Rats de Cale sur le bandana de chacun des chiens de Chaussette. Les six. Ils se sont regardés et ils ont aboyé ensemble. Je crois qu'ils ont formé un groupe.", {}, "rire"),
					L("Le soir, je danse dans la fosse. Je rentre toujours avec un bouton en moins et une idée en plus.", {"soir": true}),
				],
				"lui": [
					L("J'ai été costumière dans un théâtre, pendant vingt ans. Des robes de reine, des manteaux de pirate, des ailes de fée. Un jour, le théâtre a fermé. J'ai emporté les chutes de tissu dans trois valises. Elles ont toutes fini en patchs.", {}),
					L("Mon patch des Rats de Cale, c'est moi qui l'ai dessiné : un rat avec une crête rouge et une guitare. Rouille a pleuré quand je le lui ai montré. Clou a hoché la tête deux fois. Chez lui, c'est une ovation.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je coude aussi des choses qu'on ne voit pas. Des petits trésors dans les doublures. Des messages. Des secrets. Une couturière, c'est comme un coffre-fort avec des aiguilles.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon atelier est à la Filature, l'ancienne usine de fils, entre l'imprimerie d'Agrafe et la menuiserie de Copeau. Les vieilles machines à filer sont encore là. Je leur ai fait des housses. Elles avaient froid.", {}),
					L("La Gratuiterie de Trocante me donne tous les vieux vêtements. Je les découpe, je les recouds, et ils repartent en vestes. Rien ne se perd. Tout se coud.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Mademoiselle Prune m'a apporté sa veste de bureau à recoudre. Je lui ai cousu une doublure secrète avec des poches pour ses badges. Je n'ai rien dit. Et toi, tu n'as rien entendu.", {}),
					L("Tapage m'a demandé de recoudre sa veste de 1977. Elle date de 2004. Il y avait l'étiquette. Je n'ai rien dit non plus. Je suis une tombe. Une tombe avec des patchs.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Ta veste ! Viens ici, elle a besoin de moi !", {"visites_max": 0}), L("{surnom} ! J'ai un patch pour toi !", {"visites_min": 1}, "salut")],
				"boutique": [L("Des patchs des Rats de Cale, cousus main, un par un. Tu as {pieces} pièces.", {})],
			}},
		# ================================================================ la Filature
		{"id": "rustine", "nom": "Rustine", "titre": "mécanicienne de l'atelier vélo", "maison": "porte_rustine", "village": "boucan",
			"agenda": [[8, 12, "atelier_velo"], [12, 13, "cantine_table_1"], [13, 19, "atelier_velo"], [19, 21, ["place_jeu_1", "place_banc_2"]], [21, 23.5, "halle_fosse_6"], [23.5, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "queue", "yeux": Y_VERT, "haut": [0.2, 0.35, 0.3], "tablier": [0.25, 0.22, 0.2], "carrure": 1.05},
			"teinte": PEAU[1],
			"punk": {"tenue": "salopette", "patchs": true, "objet": "cle_molette", "chapeau": "bandana"},
			"humeur_base": 0.55, "traits": {"bavard": 0.5, "humour": 0.7, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.15},
			"aime": {"pieces_velo": 2.5, "ressort": 2.0, "rouage": 2.0, "engrenage_or": 2.5, "boulon": 1.5}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -1.0},
			"boutique": {"vend": {"pieces_velo": 4}, "achete": {"boulon": 2, "ressort": 2, "rouage": 3}},
			"tics": ["(Elle siffle.)", "Ça roule !", "Passe-moi la clé de 12.", "Un coup de graisse et ça repart."],
			"surnoms": [[0, "petit pédaleur"], [25, "mon rayon de soleil"], [50, "ma roue de secours"], [75, "mon grand braquet"], [95, "ma bicyclette en or"]],
			"repliques": {
				"accueil": [
					L("(Elle siffle un petit air, puis s'essuie les mains sur sa salopette. Ça ne change rien.) Salut ! Rustine, atelier vélo. Ici, on ne répare pas ton vélo : on t'apprend à le réparer. Et si tu n'as pas de vélo, on t'en construit un avec trois vieux vélos. Ça s'appelle le recyclage. Ou la magie.", {"visites_max": 1}, "salut"),
					L("{surnom} ! (Elle siffle deux notes : c'est un bonjour.) Ta chaîne grince, je l'entends d'ici.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Au top ! J'ai réparé neuf vélos, un monocycle, un fauteuil roulant et la poussette de la poupée de Cerise. La poussette avait un pneu crevé. La poupée était très inquiète.", {}, "rire"),
					L("Il me manque des pièces. Les robots de Lisse ont tout ramassé dans la Casse pour fabriquer leurs bras. Sans pièces, mes vélos sont des sculptures. Ferraille est jaloux.", {"q56": "bo_velo=en_cours"}),
					L("Le soir, je joue au ballon avec mes deux zèbres sur la place. Tornade triche, Cerise arbitre, et Copeau perd exprès. Moi je siffle. Je siffle tout le temps.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon père était chef de gare. Pas d'une vraie gare : d'une gare de marchandises, ici, sur les rails rouillés. Quand elle a fermé, il m'a laissé une boîte à outils et une phrase : « Tout ce qui roule peut repartir. » Les gens aussi, je crois.", {}),
					L("J'ai rencontré Copeau quand il m'a demandé de réparer une brouette. Je l'ai réparée. Il m'a fabriqué un établi. Je lui ai réparé un vélo. Il m'a fabriqué une maison. À un moment, on s'est dit qu'il fallait arrêter de s'échanger des choses et se marier.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je siffle au lieu de parler quand je suis concentrée. Tornade et Cerise comprennent tous mes sifflements : deux notes, c'est bonjour ; trois, c'est « à table » ; un long, c'est « QUI a pris ma clé de 12 ? ». Elles savent toujours qui.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("L'atelier vélo est à la Filature, l'ancienne usine de fils, avec les toits en dents de scie. On partage le bâtiment : Agrafe imprime, Velours coud, Copeau scie, Fusible branche. Moi, je graisse. Ça sent l'huile, l'encre et la sciure. C'est le parfum du Boucan.", {}),
					L("Ferraille, à la Casse, au sud-est, me donne des pièces. Moi je lui donne des roues pour son dragon de ferraille. Son dragon a maintenant onze roues. Il ne roule pas. Mais il pourrait.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Mes enfants passent leur vie au Bassin à sec, le skatepark. Tornade sur sa planche, Cerise sur le bord avec son carnet. J'y vais le soir regarder Tornade tomber. Il tombe très bien. Il tient ça de moi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Copeau a construit une balançoire en palettes si haute que Cerise a vu la mer par-dessus la Conserverie. Je l'ai fait baisser. Un peu. Cerise boude encore.", {}, "rire"),
					L("Gédéon, le fils de Lisse, est venu faire réparer un vélo de bureau gris. Pendant que je travaillais, il a tapoté un rythme sur ma boîte à outils. J'en ai lâché ma clé. Ce garçon a quelque chose dans les doigts.", {}),
				],
				"interpelle": [L("(Elle siffle.) Hé, toi ! Tu roules ?", {"visites_max": 0}), L("(Deux notes sifflées.) {surnom} !", {"visites_min": 1}, "salut")],
				"boutique": [L("Pièces de vélo, triées, graissées, garanties. Enfin, presque garanties. Tu as {pieces} pièces.", {})],
			}},
		{"id": "agrafe", "nom": "Agrafe", "titre": "imprimeur de fanzines", "maison": "porte_agrafe", "village": "boucan",
			"agenda": [[9, 12, "imprimerie"], [12, 13, "cantine_table_2"], [13, 18, "imprimerie"], [18, 21, ["mur_expression_1", "place_arbre", "rue_2"]], [21, 23.5, "halle_fosse_2"], [23.5, 9, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.32, 0.32, 0.36], "tablier": [0.15, 0.15, 0.2], "lunettes": true},
			"teinte": PEAU[4],
			"punk": {"tenue": "tablier", "patchs": true, "objet": "livre", "lunettes": true},
			"humeur_base": 0.55, "traits": {"bavard": 0.85, "humour": 1.0, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"fanzine": 2.0, "carte_postale": 1.5, "the_menthe": 1.5, "plume_corbeau": 2.0, "affiche_concert": 2.0}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -1.0},
			"boutique": {"vend": {"fanzine": 2, "affiche_concert": 1}, "achete": {"plume_corbeau": 1, "baies": 1}},
			"tics": ["Ça, c'est de l'encre-oyable !", "Je note, je note.", "Stop les presses !", "Ha ! Jeu de mots."],
			"surnoms": [[0, "cher lecteur"], [25, "mon abonné"], [50, "mon rédacteur adjoint"], [75, "ma une"], [95, "mon édition spéciale"]],
			"repliques": {
				"accueil": [
					L("Stop les presses ! Un nouveau lecteur ! Agrafe, imprimeur du « Boucanier », le fanzine de Port-Boucan : les nouvelles, les concerts, les recettes de Lentille et l'horoscope des pigeons de Patchouli. Je fais tout à la main. D'où l'encre. Partout. Même derrière les oreilles.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes à pic : je cherche un titre pour la une. « Le Boucan ne se rend pas » ou « La soupe du siècle » ? … Les deux. En gros.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Encre-oyablement bien ! J'ai imprimé trois cents exemplaires ce matin. Il y en a deux cent quatre-vingt-dix-neuf de lisibles. Le trois centième a un pouce au milieu. Le mien. C'est une édition collector.", {}, "rire"),
					L("Le Grand Boucan approche ! Les affiches sont prêtes. Pigment a peint le rat, j'ai imprimé les lettres. Il faut qu'elles voyagent sur les autres îles. Les affiches, pas les lettres. Quoique.", {"q56": "bo_affiches=en_cours"}),
					L("Le soir, je colle des affiches avec Pigment. Elle peint, je colle, et on se dispute sur la police d'écriture. C'est notre façon de nous dire bonsoir.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon premier fanzine, je l'ai fait à douze ans, à la photocopieuse de l'école. C'était une lettre pour une fille de ma classe. J'ai appuyé sur « 300 » au lieu de « 1 ». Toute l'école l'a lue. Elle aussi. Elle a corrigé mes fautes au stylo rouge et me l'a rendue. On est toujours amis.", {}, "rire"),
					L("Le Boucanier, c'est une feuille pliée en quatre, agrafée au milieu. D'où mon surnom. Avant, on m'appelait Trombone. J'ai changé : l'agrafe tient mieux. Elle s'engage, l'agrafe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("J'ai une vieille presse de sérigraphie que j'ai trouvée dans la Filature, sous trois mètres de bobines. Je l'ai appelée Gutenberg-la-Petite. Elle grince à chaque page. Je l'ai huilée. Elle grince en mieux.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'imprimerie est à la Filature, au milieu, là où sont les grandes fenêtres. Il faut de la lumière pour imprimer. Et pour lire les fautes avant qu'il ne soit trop tard. En général, il est trop tard.", {}),
					L("Le Mur d'Expression, à l'ouest de la ville, c'est la une géante du Boucan. Tout le monde peut y peindre. Pigment y passe ses journées. Moi j'y colle les affiches des concerts. On ne se marche jamais dessus. Presque jamais.", {"sujet_min": ["ile", 1]}),
					L("Sergent Fréquence lit le Boucanier à la radio chaque matin. Il ajoute des bruitages. Quand j'écris « une mouette a volé un sandwich », on entend la mouette, le sandwich et le cri du propriétaire. C'est du grand journalisme.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Patchouli m'écrit l'horoscope des pigeons. Cette semaine : « Bélier : un pigeon vous regardera de travers. » Sur le Boucan, ça arrive à tout le monde. Elle a donc raison à cent pour cent.", {}, "rire"),
					L("La petite Cerise fait son propre fanzine : « La Cerise sur le Zine ». Il se vend mieux que le mien. Il a des dessins de chevaux à crête. Je ne peux pas lutter contre des chevaux à crête.", {}, "rire"),
					L("Tapage me surveille parce que j'ai une photo de lui avec une coupe au bol. Je ne la publierai jamais. Mais j'aime bien qu'il me surveille. Ça lui fait faire de l'exercice.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Un lecteur ! Tu veux un fanzine ?", {"visites_max": 0}), L("{surnom} ! Dernière édition, encore chaude !", {"visites_min": 1}, "salut")],
				"boutique": [L("Le Boucanier, tout frais, et les affiches du Grand Boucan. L'encre est offerte. Sur les doigts. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "pigment", "nom": "Pigment", "titre": "graffeuse", "maison": "porte_pigment", "village": "boucan",
			"agenda": [[10, 13, ["mur_expression_1", "mur_expression_2"]], [13, 14, "cantine_table_3"], [14, 17, ["chateau_eau", "bassin_sec_2", "rue_3"]], [17, 21, ["imprimerie", "mur_expression_2"]], [21, 23.5, "halle_fosse_1"], [23.5, 10, "maison"]],
			"azur": {"cheveux": VERT_FLUO, "coiffure": "crete", "yeux": Y_BRUN, "haut": [0.25, 0.25, 0.3], "taille": 0.95, "carrure": 0.9},
			"teinte": PEAU[2],
			"punk": {"tenue": "sweat", "patchs": true, "objet": "bombe_peinture", "chapeau": "casquette"},
			"humeur_base": 0.6, "traits": {"bavard": 0.7, "humour": 0.75, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"bombe_peinture": 2.5, "fleur_lune": 2.0, "baies": 1.0, "affiche_concert": 1.5, "glace": 1.5}, "deteste": {"plans_lisse": -2.0, "badge_usine": -1.0},
			"boutique": {"vend": {"bombe_peinture": 3}, "achete": {"baies": 1, "fleur_lune": 4}},
			"tics": ["Pschhht !", "Ça manque de couleur.", "Trop gris !", "Le mur parle."],
			"surnoms": [[0, "toile blanche"], [25, "petit pochoir"], [50, "ma couleur primaire"], [75, "mon chef-d'œuvre"], [95, "ma fresque vivante"]],
			"repliques": {
				"accueil": [
					L("Pschhht ! … Oh, pardon, je ne t'avais pas vu derrière ma fumée de couleurs. Pigment, graffeuse. Tous les murs de Port-Boucan, c'est moi. Enfin, presque tous : il y en a un gris, au Bureau de Lisse. Pour l'instant.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu as des taches de peinture sur le nez. C'est moi ? C'est moi. Ça te va bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! J'ai peint un rat géant qui joue de la guitare sur le château d'eau. Il fait vingt mètres. Il a l'air un peu étonné. Moi aussi, je ne pensais pas qu'il serait si grand.", {}, "rire"),
					L("Monsieur Lisse a fait repeindre en gris le mur derrière son bureau. Gris ! Le mur me suppliait. Je l'ai entendu. Cette nuit, il aura des fleurs.", {}),
					L("Le soir, à l'imprimerie, je fais les affiches avec Agrafe. On se dispute sur les couleurs. Il veut du noir. Je veux tout le reste.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai commencé à dessiner sur le mur de ma chambre, à six ans. Un dragon. Mes parents l'ont recouvert de papier peint. Je l'ai redessiné sur le papier peint. Ils ont abandonné. Le dragon est toujours là.", {}, "rire"),
					L("Mes bombes de peinture, je les remplis moi-même, avec des pigments que je fais avec Radis : betterave pour le rouge, épinard pour le vert, myrtille pour le bleu. Mes murs sentent la soupe. Lentille vient les renifler.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon plus beau graffiti, c'est sur le Mur d'Expression, à l'ouest : deux mains qui s'entraident. Tout le Boucan a posé son empreinte autour. Même les chiens de Chaussette. Il y a une empreinte de pied de Boulon. Il a glissé.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Mur d'Expression, à l'ouest de la ville, c'est le mur où tout le monde a le droit de peindre. Toi aussi ! Prends une bombe et laisse ta marque. Le mur ne juge pas. Moi, un peu. Mais gentiment.", {}),
					L("Le château d'eau, à l'est, je l'ai peint tout entier, à la corde, avec Bardane qui me tenait. Trois semaines. Le rat guitariste en haut, les mouettes au milieu, et en bas, les noms de tous les habitants. Il y a la place pour le tien.", {"sujet_min": ["ile", 1]}),
					L("Le Bureau de vente de Lisse, au sud-ouest de la place : tout gris, tout propre, avec des panneaux « Bientôt ici : le Lisse-Center ». Chaque matin, ses robots repeignent en gris. Chaque nuit, je repeins en couleurs. C'est notre petite danse.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Agrafe fait des jeux de mots dans tous ses titres. Je lui ai peint un panneau : « Interdit de faire des jeux de mots ». Il a écrit dessous : « Ça me laisse sans voix… de sortie. » Il est irrécupérable.", {}, "rire"),
					L("Tornade veut que je peigne une flamme sur son casque de skate. Rustine a dit oui, à condition que la flamme soit « raisonnable ». Je ne sais pas faire de flammes raisonnables.", {}, "rire"),
				],
				"interpelle": [L("Pschhht ! Hé, toi !", {"visites_max": 0}, "rire"), L("{surnom} ! Viens voir mon nouveau mur !", {"visites_min": 1}, "salut")],
				"boutique": [L("Des bombes de peinture faites maison. Fais-moi un beau mur. Tu as {pieces} pièces.", {})],
			}},
		{"id": "copeau", "nom": "Copeau", "titre": "menuisier de récup", "maison": "porte_copeau", "village": "boucan",
			"agenda": [[8, 12, "menuiserie"], [12, 13, "cantine_table_1"], [13, 17, ["menuiserie", "place_jeu_2"]], [17, 21, ["place_jeu_1", "boites_2"]], [21, 23.5, "halle_fosse_7"], [23.5, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "barbe": "longue", "yeux": Y_BRUN, "haut": [0.55, 0.35, 0.2], "taille": 1.06, "carrure": 1.25},
			"teinte": PEAU[2],
			"punk": {"tenue": "bleu_travail", "patchs": true, "objet": "carnet", "chapeau": "bonnet"},
			"humeur_base": 0.55, "traits": {"bavard": 0.45, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.25, "rancunier": 0.05},
			"aime": {"buche": 2.0, "baton": 1.0, "miel": 1.5, "pain_miel": 1.5, "rouage": 1.0}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -0.5},
			"tics": ["Avec des palettes.", "Ça se construit.", "Mesure deux fois, scie une fois.", "Hop, une cheville."],
			"surnoms": [[0, "petite planche"], [25, "mon tasseau"], [50, "ma palette"], [75, "ma poutre maîtresse"], [95, "mon chef-d'œuvre en chêne"]],
			"repliques": {
				"accueil": [
					L("Salut. Copeau, menuisier. Tu vois ce banc ? Palettes. Cette table ? Palettes. Cette scène, ce toboggan, ce kiosque ? Palettes. Ma maison ? Palettes et amour. Surtout palettes.", {"visites_max": 1}, "salut"),
					L("{surnom}. Assieds-toi sur ce tabouret. Je viens de le finir. Il est solide. Je crois.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. J'ai construit une cabane dans l'arbre de la place pour Cerise. Elle y a déjà installé une rédaction. Elle m'a demandé une « salle des archives ». Elle a neuf ans.", {}, "rire"),
					L("Le soir, je joue au ballon avec les enfants et Rustine. Je perds exprès. Tornade le sait. Il me laisse perdre exprès. C'est un gentil garçon.", {"soir": true}),
				],
				"lui": [
					L("Mon grand-père était charpentier de marine. Il construisait des barques pour les pêcheurs du Vieux Bassin. Il m'a appris une seule chose : « Le bois se souvient de l'arbre. » Alors je lui parle gentiment. Même aux palettes. Surtout aux palettes : elles ont eu une vie dure.", {}),
					L("J'ai construit le berceau de Tornade avec une palette et une roue de vélo de Rustine. Il se balançait tout seul. Puis celui de Cerise. Tornade est sorti du sien à six mois, en le faisant rouler. Il était déjà pressé.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je ne parle pas beaucoup. Je mesure. Rustine parle avec des sifflements, moi avec des coups de marteau. À la maison, ça fait un orchestre. Les enfants font les paroles.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La menuiserie de récup est au fond de la Filature. Tout ce que tu vois de bois au Boucan vient de là. Sauf les arbres. Eux, ils sont venus tout seuls.", {}, "rire"),
					L("La scène de la Halle Hurlante, c'est moi qui l'ai construite, avec Fusible pour les lumières. Elle tient trois punks, un batteur et une foule qui saute dessus. Je l'ai testée en sautant moi-même. Pendant une heure.", {"sujet_min": ["ile", 1]}),
					L("Les Boîtes, à l'est, le village de conteneurs : j'y ai fait les escaliers, les balcons et les passerelles. Patchouli a demandé une passerelle pour ses pigeons. Je l'ai faite. Ils ne s'en servent pas. Ils volent.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Fusible a branché une guirlande sur ma scie. Maintenant, quand je scie, ça clignote. C'est joli. C'est un peu inquiétant aussi.", {}, "rire"),
					L("Mamie Barricade m'a demandé une chaise à bascule « avec des clous ». J'ai mis des clous. Elle a dit : « Plus. » J'en ai mis plus. Elle se balance comme une reine.", {}, "rire"),
				],
				"interpelle": [L("Hé. Tu as besoin d'un banc ?", {"visites_max": 0}), L("{surnom}. Viens voir ce que j'ai construit.", {"visites_min": 1}, "salut")],
			}},
		{"id": "fusible", "nom": "Fusible", "titre": "électricien du Boucan", "maison": "porte_fusible", "village": "boucan",
			"agenda": [[9, 12, "filature_entree"], [12, 13, "cantine_table_6"], [13, 17, ["halle_regie", "chateau_eau", "rue_2", "grue"]], [17, 21, ["halle_entree", "place_camion"]], [21, 23.5, "halle_fosse_8"], [23.5, 9, "maison"]],
			"azur": {"cheveux": JAUNE_PAILLE, "coiffure": "boucles", "yeux": Y_BLEU, "haut": [0.3, 0.38, 0.55], "lunettes": true, "carrure": 0.95},
			"teinte": PEAU[0],
			"punk": {"tenue": "bleu_travail", "patchs": true, "objet": "cle_molette", "lunettes": true},
			"humeur_base": 0.55, "traits": {"bavard": 0.75, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"rouage": 2.0, "ressort": 1.5, "boulon": 1.5, "engrenage_or": 2.5, "lanterne_fee": 2.0}, "deteste": {"plans_lisse": -1.0, "eau_source": -0.5},
			"tics": ["Bzzt !", "Je branche ça sur ça…", "Ça va marcher. Peut-être.", "Pas de panique, c'est du courant."],
			"surnoms": [[0, "petite ampoule"], [25, "mon interrupteur"], [50, "ma prise multiple"], [75, "mon court-circuit préféré"], [95, "ma centrale électrique"]],
			"repliques": {
				"accueil": [
					L("Bzzt ! Salut ! Fusible, électricien. Les guirlandes, les lampes, les projecteurs de la Halle, la radio, la fontaine qui clignote : tout passe par moi. Ne touche pas ce fil. Ni celui-là. Ni moi, d'ailleurs, je suis peut-être encore chargé.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes bien, j'ai besoin de quelqu'un pour tenir cette ampoule. Non, pas comme ça. Voilà. Ne bouge plus. Pendant deux heures.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Électrique ! J'ai branché la fontaine-baignoire de la place sur la grue de Boulon. Quand il lève un conteneur, la fontaine s'allume. C'est complètement inutile. C'est magnifique.", {}, "rire"),
					L("L'antenne de la radio est tombée au sommet du château d'eau. Je pourrais monter la chercher, mais j'ai le vertige au-dessus du deuxième barreau. Les fils, oui. Les échelles, non.", {"q56": "bo_radio=en_cours"}),
					L("Le soir, j'allume toutes les guirlandes de la ville d'un seul coup. Clac ! Tout le Boucan fait « ooooh ». Tous les soirs. Ils ne s'en lassent pas. Moi non plus.", {"soir": true}),
				],
				"lui": [
					L("À huit ans, j'ai démonté le grille-pain de ma grand-mère pour voir où allait le pain. J'ai trouvé des fils. Depuis, je suis les fils. Mes cheveux sont restés un peu dressés. Pas à cause du grille-pain. Enfin, peut-être un peu.", {}, "rire"),
					L("J'ai eu peur du noir pendant toute mon enfance. Alors j'ai appris à faire de la lumière. Aujourd'hui, toute une ville s'allume grâce à moi. La peur, c'est parfois un très bon métier.", {"sujet_min": ["lui", 1]}),
					L("Mon électricité vient du vent et du soleil : des éoliennes faites avec de vieux ventilateurs sur le toit de la Filature, et des panneaux récupérés à la Casse. Et quand il n'y a ni vent ni soleil, Tapage pédale sur un vélo-dynamo. Il dit que c'est son sport.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Halle Hurlante a quarante projecteurs, trois boules à facettes et une enseigne qui clignote. La moitié vient de la Casse. L'autre moitié, je ne sais plus d'où. Elle marche, c'est l'essentiel.", {}),
					L("La grande cheminée de briques, à côté de la Filature : j'ai mis une lumière tout en haut. Les bateaux la voient de loin. Gravier dit qu'elle l'a ramené au port un soir de brouillard. Il me l'a dit en quatre mots. C'est beaucoup, pour lui.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Larsen et moi, on fait la régie ensemble. Lui le son, moi la lumière. Quand il crie « PLUS FORT ! », je mets plus de lumière. Ce n'est pas ce qu'il veut dire. Mais c'est joli.", {}, "rire"),
					L("Copeau dit que j'ai branché une guirlande sur sa scie. C'est vrai. Il dit que c'est inquiétant. C'est faux : c'est festif.", {}, "rire"),
				],
				"interpelle": [L("Bzzt ! Hé, toi !", {"visites_max": 0}, "rire"), L("{surnom} ! Ne touche à rien, mais viens voir !", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ la Halle Hurlante
		{"id": "sirene", "nom": "Sirène", "titre": "patronne du bar à limonades de la Halle", "maison": "porte_sirene", "village": "boucan",
			"agenda": [[8, 11, ["jardins_serre", "jardins_2"]], [11, 14, "halle_bar"], [14, 16, "place_camion"], [16, 23.5, "halle_bar"], [23.5, 8, "maison"]],
			"azur": {"cheveux": TURQUOISE, "coiffure": "long", "yeux": Y_VERT, "haut": [0.15, 0.4, 0.45], "tablier": [0.9, 0.88, 0.82]},
			"teinte": PEAU[4],
			"punk": {"tenue": "tablier", "patchs": true, "objet": "carnet", "chapeau": "bandana"},
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"miel": 2.0, "pomme": 1.5, "baies": 1.5, "the_menthe": 2.0, "sirop_menthe": 1.0}, "deteste": {"plans_lisse": -1.5, "galette_algue": -1.0},
			"boutique": {"vend": {"limonade_boucan": 2, "sirop_menthe": 2, "jus_pomme": 2}, "achete": {"pomme": 1, "baies": 1, "miel": 3}},
			"tics": ["Au suivant !", "Glaçons ?", "Une paille ou deux ?", "J'ai tout noté."],
			"surnoms": [[0, "petite bulle"], [25, "ma citronnade"], [50, "mon sirop préféré"], [75, "ma limonade d'or"], [95, "ma recette secrète"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au bar de la Halle Hurlante. Sirène. Limonades, sirops maison, jus de pomme. Pas de bouteilles bizarres, pas de cocktails qui fument : ici, on danse à la limonade et on chante au sirop. Tu veux goûter ma limonade ? Elle pique le nez.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Comme d'habitude ? … Tu n'as pas encore d'habitude. On va t'en faire une.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Organisée. J'ai étiqueté tous mes sirops : menthe, fraise, sureau, violette, et « mystère », qui est un mélange des fonds de bouteilles. C'est le plus demandé.", {}, "rire"),
					L("Le soir, le bar est plein, tout le monde crie sa commande en même temps, et je n'en rate aucune. J'ai un carnet. Et une très bonne mémoire. Et Larsen qui répète les commandes dans le micro, ce qui n'aide pas.", {"soir": true}, "rire"),
				],
				"lui": [
					L("On m'appelle Sirène parce que j'ai été maître-nageuse sur une plage de Port-Azur. Sauf que je ne sais pas nager. Je surveillais très, très attentivement. Personne ne s'est jamais noyé. Je pense que c'était le regard.", {}, "rire"),
					L("Mes sirops, je les fais avec les plantes de la serre des Jardins Partagés. Radis me laisse cueillir la menthe à condition que je lui raconte comment elle a fini. Il veut savoir si elle a été heureuse.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le bar, je l'ai monté avec des caisses de sardines et un vieux comptoir de la Conserverie. Mon carnet, lui, je l'ai depuis quinze ans. Toutes les commandes de tous les concerts. Un jour, ce sera un livre d'histoire. Avec beaucoup de menthe dedans.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le bar est à droite en entrant dans la Halle, sous la mezzanine. Le comptoir est en bois de bateau. Si tu poses ton oreille dessus, on entend la mer. Ou les basses de Mouette. C'est difficile à distinguer.", {}, "rire"),
					L("Les Jardins Partagés, à l'est, ont une serre faite de vieilles fenêtres. Il y pousse la menthe la plus fraîche de l'archipel. Radis lui joue de l'harmonica. Elle aime ça.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Larsen commande toujours en criant. Un jour, il a crié « UNE LIMONADE ! » si fort que toutes les bouteilles ont fait des bulles en même temps. Je l'ai servi. Il fallait bien.", {}, "rire"),
					L("Je ne dis rien sur personne. Une patronne de bar, ça écoute et ça se tait. … Mais si quelqu'un porte une moustache en carton au fond de la fosse, ce n'est pas mon affaire. Et je lui garde une limonade à la violette.", {}),
				],
				"interpelle": [L("Une limonade ? Ça te ferait du bien.", {"visites_max": 0}), L("{surnom} ! Ta limonade t'attend !", {"visites_min": 1}, "salut")],
				"boutique": [L("Limonade, sirop de menthe, jus de pomme : tout est fait maison, rien ne tourne la tête, tout fait danser. Tu as {pieces} pièces.", {})],
			}},
		{"id": "larsen", "nom": "Larsen", "titre": "ingénieur du son de la Halle", "maison": "porte_larsen", "village": "boucan",
			"agenda": [[11, 13, "halle_regie"], [13, 14, "cantine_table_5"], [14, 17, ["halle_regie", "rue_4"]], [17, 23.5, "halle_regie"], [23.5, 11, "maison"]],
			"azur": {"cheveux": ORANGE_VIF, "coiffure": "crete_courte", "yeux": Y_GRIS, "haut": [0.18, 0.18, 0.2], "carrure": 1.1},
			"teinte": PEAU[3],
			"punk": {"tenue": "sweat", "patchs": true, "objet": "casque_audio", "chapeau": "casquette"},
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"ampli": 3.0, "caillou_chantant": 2.0, "sifflet_muet": 2.0, "limonade_boucan": 1.5, "rouage": 1.0}, "deteste": {"plans_lisse": -1.0, "vieille_botte": -0.5},
			"tics": ["QUOI ?", "UN, DEUX ! UN, DEUX !", "C'EST TROP FORT ! … PAS ASSEZ !", "TEST !"],
			"surnoms": [[0, "PETIT NOUVEAU"], [25, "MON PETIT VOLUME"], [50, "MA BASSE FRÉQUENCE"], [75, "MON MICRO PRÉFÉRÉ"], [95, "MA TABLE DE MIXAGE"]],
			"repliques": {
				"accueil": [
					L("SALUT ! … PARDON. Salut. JE M'APPELLE LARSEN ! … Pardon. Larsen. Ingénieur du son. Je parle un peu fort. C'est le métier. Et le casque. Et peut-être un peu moi.", {"visites_max": 1}, "salut"),
					L("{surnom} ! TU VAS BIEN ? … Je t'entends, hein. Je réponds juste fort.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("TRÈS BIEN ! Hier soir, le son était PARFAIT ! Enfin, sauf quand le remplaçant a fait tomber la cymbale sur la tête de Clou. Clou n'a rien dit. Il ne dit jamais rien. Mais la cymbale a fait « BWOÏNG ».", {}, "rire"),
					L("ON N'A PLUS D'AMPLI ! Les robots l'ont emporté à la Casse ! Sans ampli, Germaine joue en chuchotant ! Un concert en chuchotant ! C'EST UNE CATASTROPHE ! … pardon.", {"q56": "bo_concert=en_cours"}),
					L("LE SOIR, C'EST CONCERT ! Je suis à la régie, au fond de la Halle, avec mes boutons. J'ai cent douze boutons. J'en utilise trois. Les autres sont là pour faire sérieux.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai grandi à côté d'une corne de brume. Elle sonnait toutes les deux minutes, toute la nuit. Pour se parler à la maison, il fallait crier entre deux « BWOOO ». Je n'ai jamais perdu l'habitude. Ma mère non plus.", {}, "rire"),
					L("Je vais te dire un secret. Tout bas. … Tu entends ? Non ? JE DISAIS : je n'aime pas le bruit. J'aime le SON. Le beau son. Le bruit, c'est un son qui n'a pas été écouté. Mon métier, c'est d'écouter.", {"sujet_min": ["lui", 1]}),
					L("Chez moi, le soir, j'écoute des enregistrements de baleines. Tout doucement. Très doucement. Si quelqu'un le dit à Tapage, je nie tout. FORT.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("LA RÉGIE est au fond de la Halle Hurlante, sur une estrade. De là, je vois tout : la scène, la fosse, le bar de Sirène, et Mamie Barricade sur la mezzanine qui me fait signe de baisser. Je baisse. Un peu.", {}),
					L("Pour le Grand Boucan, on aura des gens de toutes les îles ! Des pirates, des aventuriers, des touristes de Port-Azur ! IL FAUDRA QUE LE SON SOIT PARFAIT ! … pour une fois.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("TAPAGE dit que le son est trop fort ! Ou pas assez ! Il change d'avis selon que Mamie Barricade est là ou pas ! Je règle le son pour Mamie Barricade. C'est plus sûr.", {}, "rire"),
					L("Mouette joue tellement fort que mon casque vibre. J'adore. Ne lui dis pas. ELLE JOUERAIT ENCORE PLUS FORT.", {}, "rire"),
				],
				"interpelle": [L("HÉ ! TOI ! … pardon. Hé, toi.", {"visites_max": 0}, "rire"), L("{surnom} ! TEST ! UN, DEUX !", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ le port et la ville
		{"id": "boulon", "nom": "Boulon", "titre": "grutier du Vieux Bassin", "maison": "porte_boulon", "village": "boucan",
			"agenda": [[6, 12, "grue"], [12, 13, ["cantine_table_6", "place_camion"]], [13, 18, "grue"], [18, 21, ["quai_2", "plage_cabane"]], [21, 23.5, "halle_fosse_10"], [23.5, 6, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BRUN, "haut": [0.85, 0.5, 0.15], "taille": 1.2, "carrure": 1.6},
			"teinte": PEAU[5],
			"punk": {"tenue": "bleu_travail", "patchs": true, "chapeau": "bonnet"},
			"humeur_base": 0.6, "traits": {"bavard": 0.4, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"sardines_grillees": 2.5, "pain_miel": 2.0, "gateau_miel": 2.0, "ressort": 1.0, "os_sardine": 1.5}, "deteste": {"plans_lisse": -1.0, "vieille_botte": -0.5},
			"tics": ["Doucement.", "Hop là.", "On soulève.", "Pardon, pardon."],
			"surnoms": [[0, "petit gars"], [25, "mon petit conteneur"], [50, "mon copain"], [75, "mon grand ami"], [95, "le plus beau chargement du port"]],
			"repliques": {
				"accueil": [
					L("(Une ombre immense te recouvre. C'est Boulon. Il sourit.) Bonjour. N'aie pas peur. Je suis grand, mais je suis doux. Boulon. Je fais tourner la vieille grue du Vieux Bassin. Je soulève des conteneurs pour les Boîtes. Et parfois des chats coincés dans les arbres.", {"visites_max": 1}, "salut"),
					L("{surnom} ! (Il te tapote l'épaule. Tu t'enfonces un peu dans le sol.) Pardon. Pardon.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Content. J'ai posé un nouveau conteneur aux Boîtes. Une famille va y habiter. Ils ont peint des fleurs dessus avant même que je le pose. Il est arrivé fleuri.", {}),
					L("Hier, j'ai remplacé le batteur. J'ai tapé doucement. La grosse caisse s'est cassée quand même. Je me suis excusé auprès d'elle. Copeau l'a réparée. Elle m'a pardonné, je crois.", {}, "rire"),
					L("Le soir, je vais dans la fosse de la Halle. Je saute tout doucement, pour ne pas faire trembler la scène. Les petits s'accrochent à mes bras. Je suis un manège.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai travaillé sur ce port avec Mamie Barricade, quand j'avais vingt ans et qu'elle en avait quarante-huit. Elle portait deux caisses. Moi quatre. Elle disait : « Ce n'est pas la force qui compte, petit, c'est la douceur dans la force. » Je l'ai gardé.", {}),
					L("La grue s'appelle Mademoiselle. Elle a soixante-dix ans. Je lui parle le matin, je la graisse, je lui dis qu'elle est belle. Fusible a mis des guirlandes sur son bras. Elle est encore plus belle. Elle grince de fierté.", {"sujet_min": ["lui", 1]}, "rire"),
					L("J'ai le vertige. Si. Mais dans la cabine de Mademoiselle, je ne regarde jamais en bas. Je regarde l'horizon. Gravier m'a appris ça. Il a dit : « Regarde loin. » Trois mots. Ça m'a changé la vie.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Vieux Bassin, c'est le port, au nord de la ville : un grand bassin rectangulaire, des quais de pierre, deux vieilles grues. La mienne, c'est celle de l'ouest. L'autre est à la retraite. Elle regarde la mienne travailler.", {}),
					L("Les Boîtes, à l'est, c'est le village de conteneurs. Chaque conteneur, je l'ai posé moi-même. Je connais chaque famille. Quand ils déménagent, je déménage la maison entière. Avec eux dedans, s'ils veulent. Les enfants adorent.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Les robots de Lisse ont essayé de démonter Mademoiselle. Je suis descendu de la cabine. Je me suis mis devant. Ils m'ont regardé longtemps. Ils sont repartis. Je n'ai rien dit. J'étais juste grand.", {}),
					L("Les chiens de Chaussette m'adorent. Les six. Ils me grimpent dessus comme sur une colline. Chaussette dit que je suis leur montagne préférée.", {}, "rire"),
				],
				"interpelle": [L("Bonjour, petit gars. N'aie pas peur.", {"visites_max": 0}, "salut"), L("{surnom} ! Hop là !", {"visites_min": 1}, "rire")],
			}},
		{"id": "sergent", "nom": "Sergent Fréquence", "titre": "animateur de Radio Boucan", "maison": "porte_sergent", "village": "boucan",
			"agenda": [[7, 12, "radio_studio"], [12, 13, "cargo_pont"], [13, 17, ["radio_studio", "cargo_cabine"]], [17, 19, ["place_camion", "rue_5", "cargo_passerelle"]], [19, 23.5, "radio_studio"], [23.5, 7, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "moustache", "yeux": Y_AMBRE, "haut": [0.25, 0.35, 0.5], "lunettes": true, "carrure": 1.1},
			"teinte": PEAU[2],
			"punk": {"tenue": "veste_jean", "patchs": true, "objet": "micro", "lunettes": true},
			"humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.85, "curiosite": 0.9, "susceptible": 0.35, "rancunier": 0.1},
			"aime": {"antenne_radio": 3.0, "fanzine": 2.0, "the_menthe": 1.5, "cafe_vapeur": 2.0, "caillou_chantant": 1.5}, "deteste": {"plans_lisse": -1.5, "sifflet_muet": -1.0},
			"tics": ["Ici Radio Boucan !", "Fin de transmission.", "Restez à l'écoute !", "Pschhh… à vous !"],
			"surnoms": [[0, "cher auditeur"], [25, "fidèle auditeur"], [50, "mon correspondant spécial"], [75, "mon envoyé spécial"], [95, "la voix du Boucan"]],
			"repliques": {
				"accueil": [
					L("ICI RADIO BOUCAN, 98.7 ! La radio qui ne s'éteint jamais… sauf quand l'antenne tombe ! Et vous êtes en direct avec Sergent Fréquence ! … Enfin, là, on n'est pas en direct, on se parle. Mais j'ai gardé la voix. Bienvenue au Boucan, cher auditeur !", {"visites_max": 1}, "salut"),
					L("Ah ! {surnom} ! Je l'annonçais justement à l'antenne : « Notre ami se promène sur les quais. » C'était vrai ! Le direct, c'est magique.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("En pleine forme, sur toutes les fréquences ! Ce matin, j'ai annoncé la météo : « gris, comme Monsieur Lisse ». Il a appelé la radio pour se plaindre. Je l'ai passé à l'antenne. Grand moment de radio.", {}, "rire"),
					L("Silence radio… L'antenne est tombée au sommet du château d'eau pendant la tempête. Je parle dans mon micro, et personne ne m'entend. C'est comme parler à Clou, mais en plus triste.", {"q56": "bo_radio=en_cours"}),
					L("De retour sur les ondes ! Grâce à toi ! J'ai fait une émission spéciale de quatre heures pour te remercier. Tu ne l'as pas entendue ? Je la refais demain.", {"q56": "bo_radio=finie"}, "rire"),
					L("Le soir, je retransmets le concert en direct depuis la timonerie du Cargo. Je commente le pogo comme un match : « Et Boulon saute… il saute… IL A SAUTÉ ! »", {"soir": true}, "rire"),
				],
				"lui": [
					L("On m'appelle Sergent, mais je n'ai jamais été sergent. Quand j'étais petit, je criais les annonces dans la cour de l'école avec un entonnoir. « Garde à vous, c'est la récré ! » Le surnom est resté. Fréquence, je l'ai ajouté plus tard. Pour le sérieux.", {}, "rire"),
					L("La Baleine Rouillée, je l'ai trouvée échouée sur la plage, vide, avec une vieille radio de bord dans la timonerie. J'ai tourné le bouton. Il y avait du bruit, rien que du bruit. Je me suis dit : « Ce bruit attend une voix. » J'ai emménagé le soir même.", {"sujet_min": ["lui", 1]}),
					L("Devant un micro, je suis courageux. En vrai, en face des gens, je suis un peu timide. C'est pour ça que je parle fort et vite : pour ne pas avoir le temps d'avoir peur. Pschhh… fin de la confidence.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Cargo, la Baleine Rouillée, est échoué sur la plage du nord-ouest. Le studio de Radio Boucan est dans la timonerie, tout en haut, et l'antenne au sommet du mât. Quand il y a du vent, tout le bateau chante. Je le passe à l'antenne. Ça s'appelle « la Minute du Cargo ».", {}),
					L("Mes émissions : « Le Réveil du Rat » le matin, « Les Petites Annonces de Trocante » à midi, « L'Horoscope des Pigeons » avec Patchouli, et le soir, le concert en direct. Et entre les deux, les alertes. Quand les robots débarquent, je crie. Fort.", {"sujet_min": ["ile", 1]}),
					L("Quand les robots de Lisse débarquent, je sonne la sirène et je crie dans le micro : « ALERTE ! Les robots sont sur les quais ! » Tout le Boucan sort. On fait la chaîne. Les robots détestent la chaîne. Elle n'est pas dans leur programme.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Exclusivité Radio Boucan : Tapage aurait joué en 1977. Ou en 1978. Mamie Barricade et lui se disputent en direct tous les jeudis. C'est mon émission la plus écoutée.", {}, "rire"),
					L("Information non vérifiée : Mademoiselle Prune, la secrétaire de Lisse, téléphonerait à la radio tous les soirs pour demander une chanson des Rats de Cale, en déguisant sa voix. Elle déguise très mal sa voix. Je passe la chanson quand même.", {}, "rire"),
					L("Monsieur Lisse m'a proposé d'acheter la radio. Il voulait l'appeler « Lisse FM, la radio optimisée ». J'ai dit non en direct. Mille auditeurs ont applaudi. Et trois mouettes.", {}, "rire"),
				],
				"interpelle": [L("Ici Radio Boucan ! Hé, vous ! Oui, vous !", {"visites_max": 0}, "salut"), L("{surnom} ! Une petite interview ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "radis", "nom": "Radis", "titre": "jardinier des Jardins Partagés", "maison": "porte_radis", "village": "boucan",
			"agenda": [[6, 12, ["jardins_1", "jardins_2", "jardins_serre"]], [12, 13, "cantine_table_4"], [13, 19, ["jardins_serre", "jardins_1"]], [19, 21, "place_banc_1"], [21, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chauve", "barbe": "courte", "yeux": Y_VERT, "haut": [0.35, 0.5, 0.3], "vieux": true, "lunettes": true, "carrure": 0.95},
			"teinte": PEAU[3],
			"punk": {"tenue": "salopette", "patchs": true, "objet": "arrosoir", "chapeau": "casquette", "lunettes": true},
			"humeur_base": 0.5, "traits": {"bavard": 0.75, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.55, "rancunier": 0.25},
			"aime": {"graines": 2.5, "graine_or": 3.0, "miel": 1.5, "tarte_potiron": 2.0, "panier_legumes": 1.5}, "deteste": {"plans_lisse": -1.5, "champignon_braise": -1.0},
			"tics": ["Très bien, assieds-toi.", "Dix sur dix.", "Les tomates écoutent.", "Révise ta botanique."],
			"surnoms": [[0, "mon élève"], [25, "ma petite pousse"], [50, "mon bon élève"], [75, "mon premier de la classe"], [95, "mon prix d'excellence"]],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Très bien, assieds-toi. Radis, ancien professeur de sciences naturelles, aujourd'hui jardinier des Jardins Partagés. Tu vois ces tomates ? Elles ont dix sur dix en rougeur. Ces courgettes, sept sur dix. Elles peuvent mieux faire.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes pendant l'interrogation des carottes. Chut. Elles sont concentrées.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Satisfait. Mes tomates ont bien poussé cette semaine. Je leur ai lu un chapitre de botanique tous les soirs. Elles adorent la photosynthèse. C'est leur sujet préféré.", {}, "rire"),
					L("Contrarié. Mère Morille raconte que sa courge géante pèse cent kilos. Cent kilos ! La mienne en pèse quatre-vingt-dix-huit. Elle a sûrement compté la roulotte.", {}),
					L("Le soir, je m'assois sur un banc de la place et je relis mes notes de la journée. « Haricot numéro douze : progrès remarquables. » Un vieux professeur ne s'arrête jamais de corriger.", {"soir": true}),
				],
				"lui": [
					L("J'ai été professeur pendant trente-cinq ans. J'ai appris la botanique à des centaines d'élèves. Certains s'en souviennent. Rustine, par exemple, a eu quatre en herbier. Elle avait collé une clé de 12 à la place d'une fougère. C'était audacieux.", {}, "rire"),
					L("À la retraite, j'ai pris un carré de terre ici, sur une friche pleine de cailloux et de bouts de ferraille. J'ai mis trois ans à la rendre douce. Aujourd'hui, elle nourrit la Cantine de Lentille. Mes meilleurs élèves, ce sont des poireaux.", {"sujet_min": ["lui", 1]}),
					L("Je parle à mes tomates. Je leur raconte ma journée, je leur pose des questions. Elles ne répondent pas, mais elles rougissent. C'est déjà une forme de conversation.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Les Jardins Partagés sont à l'est de la ville, près des Boîtes : des carrés de légumes, une serre faite de vieilles fenêtres, des ruches et un compost. Chacun peut cultiver un carré. Même toi. Je te mettrai une note.", {}),
					L("Le compost, c'est la plus belle chose du monde. On y met les épluchures, et un an plus tard, c'est de la terre. Rien ne se perd. C'est la même chose que la Gratuiterie de Trocante, mais en plus lent.", {"sujet_min": ["ile", 1]}),
					L("Au sud, dans la Cathédrale des Spores, Mère Morille connaît tous les champignons. Elle est très savante. Pour une rivale. Mais attention : il ne faut jamais, JAMAIS cueillir un champignon sans quelqu'un qui le connaît. Zéro sur dix à ceux qui le font.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Bardane a passé la nuit dans mon pommier pour vérifier qu'il allait bien. Il allait bien. Elle aussi. Mais elle a fait peur au hibou.", {}, "rire"),
					L("Patchouli prétend que les pigeons prévoient la météo. J'ai vérifié pendant un mois. Ils se trompent une fois sur deux. Comme la météo, finalement.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Tu connais la différence entre un radis et une rave ?", {"visites_max": 0}), L("{surnom} ! Viens voir mes progrès !", {"visites_min": 1}, "salut")],
			}},
		{"id": "chaussette", "nom": "Chaussette", "titre": "promeneuse de chiens", "maison": "porte_chaussette", "village": "boucan",
			"agenda": [[8, 11, ["rue_1", "rue_2", "rue_3", "quai_1"]], [11, 13, ["place_fontaine", "place_arbre"]], [13, 14, "cantine_table_6"], [14, 18, ["rue_4", "rue_5", "rue_6", "jardins_2", "plage_feu"]], [18, 21, ["place_banc_2", "quai_3"]], [21, 23.5, "halle_fosse_5"], [23.5, 8, "maison"]],
			"azur": {"cheveux": JAUNE_PAILLE, "coiffure": "tresse", "yeux": Y_BRUN, "haut": [0.35, 0.45, 0.65], "taille": 0.96},
			"teinte": PEAU[0],
			"punk": {"tenue": "veste_jean", "patchs": true, "objet": "laisse", "chapeau": "bandana", "chien": true},
			"humeur_base": 0.6, "traits": {"bavard": 0.5, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.05},
			"aime": {"os_sardine": 3.0, "sardine": 1.5, "sardines_grillees": 1.5, "glace": 1.5, "patch_rat": 1.5}, "deteste": {"plans_lisse": -1.5, "sifflet_muet": -1.0},
			"tics": ["Assis ! … Pas toi.", "Bigoudi, lâche ça !", "Ils disent bonjour.", "Wouf. Pardon."],
			"surnoms": [[0, "petit chiot"], [25, "mon toutou"], [50, "mon septième chien"], [75, "mon chien de cœur"], [95, "le chef de la meute"]],
			"repliques": {
				"accueil": [
					L("Assis ! … Pas toi. Eux. Bonjour ! Chaussette, promeneuse de chiens. Je te présente Bigoudi, Pneu, Gaufre, Amiral, Madame Croquette et Tic-Tac. Ils disent bonjour. Tic-Tac dit bonjour deux fois, il a deux bouts de queue qui remuent. Enfin, une queue très rapide.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Les chiens t'ont reconnu ! Regarde, Pneu se roule par terre. C'est son plus grand compliment.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super ! Amiral a appris à rapporter. Il rapporte tout : des bâtons, des chaussures, et une fois, un panneau « Bientôt ici : le Lisse-Center ». Je l'ai félicité.", {}, "rire"),
					L("Sardine, le chien de Tornade, a disparu ! Mes six chiens ont cherché partout. Bigoudi a reniflé une piste vers le sud-est, vers la Casse. Puis il a reniflé un sandwich. Il a perdu la piste.", {"q56": "bo_sardine=en_cours"}),
					L("Le soir, je laisse les chiens chez Boulon et je vais danser dans la fosse. Ils m'attendent sur son ventre. Il ne bouge pas pendant deux heures. C'est un saint.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Petite, j'étais très timide. Je ne parlais à personne. Mais aux chiens, si. Les chiens ne te coupent jamais la parole, et ils trouvent toutes tes histoires géniales. Aujourd'hui, j'en promène six. Et je parle un peu aux humains aussi. Un peu.", {}),
					L("Les chiens, ce ne sont pas les miens. Ce sont les chiens du Boucan : celui de la Conserverie, celui des Boîtes, celui de la Filature… Chaque matin, je passe les prendre, et chaque soir je les ramène. Sauf Madame Croquette. Elle a décidé qu'elle habitait chez moi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Velours a cousu un patch des Rats de Cale sur chacun de leurs bandanas. Depuis, quand ils entendent la guitare de Clou, ils hurlent tous ensemble. Rouille dit qu'ils sont les meilleurs choristes de l'île.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Ma promenade du matin fait le tour du Vieux Bassin. Les mouettes taquinent les chiens, les chiens courent après les mouettes, et personne n'attrape jamais personne. C'est le jeu préféré de tout le monde.", {}),
					L("L'après-midi, on va jusqu'à la Plage aux Galets, au sud-est. Gravier nous donne des têtes de poisson. Les chiens l'adorent. Gravier fait semblant de ne pas les aimer. Il ment très mal.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Les chiens aboient sur les robots de Lisse. Tous les six. Ensemble. Les robots s'arrêtent et disent : « Veuillez cesser d'aboyer. Merci de votre compréhension. » Les chiens n'ont aucune compréhension. C'est leur force.", {}, "rire"),
					L("Pastille soigne les pattes de mes chiens. Quand l'un d'eux a une épine, les six viennent. Par solidarité. Elle leur fait à tous un pansement à motif de chaton. Ils sont très fiers.", {}, "rire"),
				],
				"interpelle": [L("Assis ! … Oh, bonjour, toi.", {"visites_max": 0}, "rire"), L("{surnom} ! Les chiens veulent te dire bonjour !", {"visites_min": 1}, "salut")],
			}},
		{"id": "cradoc", "nom": "Cradoc", "titre": "jongleur et cracheur de bulles", "maison": "porte_cradoc", "village": "boucan",
			"agenda": [[10, 13, ["place_fontaine", "place_jeu_2"]], [13, 14, "cantine_table_2"], [14, 18, ["place_fontaine", "bassin_sec_1", "rue_6"]], [18, 21, ["place_arbre", "halle_entree"]], [21, 23.5, "halle_fosse_3"], [23.5, 10, "maison"]],
			"azur": {"cheveux": VIOLET_VIF, "coiffure": "crete", "yeux": Y_VIOLET, "haut": [0.85, 0.75, 0.2], "carrure": 0.88},
			"teinte": PEAU[1],
			"punk": {"tenue": "salopette", "patchs": true, "objet": "balles_jonglage"},
			"humeur_base": 0.7, "traits": {"bavard": 0.85, "humour": 1.0, "curiosite": 0.7, "susceptible": 0.25, "rancunier": 0.0},
			"aime": {"glace": 2.0, "ressort": 2.0, "cochonnet": 2.0, "lunettes_kaleido": 2.5, "limonade_boucan": 1.5}, "deteste": {"plans_lisse": -1.0, "vieille_botte": -0.5},
			"tics": ["Tadaaa !", "Hop, hop, hop !", "Oups. C'était prévu.", "Une bulle ?"],
			"surnoms": [[0, "spectateur"], [25, "mon public"], [50, "mon assistant"], [75, "mon partenaire de piste"], [95, "la star du spectacle"]],
			"repliques": {
				"accueil": [
					L("Mesdames et messieurs, approchez ! Cradoc, jongleur, monocycliste et cracheur de bulles ! Regardez : trois balles… quatre balles… cinq… (Tout tombe.) TADAAA ! C'était prévu. C'est un numéro de chute. Très difficile.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Mon public préféré ! Recule un peu. Encore. Voilà : là, tu ne prendras pas de balle.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Formidable ! J'ai fait une bulle si grande que Cerise est entrée dedans. Elle a flotté trois secondes. Puis elle a éclaté. La bulle. Pas Cerise. Cerise va très bien.", {}, "rire"),
					L("Je suis tombé de mon monocycle quatre fois ce matin. Pastille m'a cousu des coussins dans le pantalon. Maintenant je tombe en rebondissant. C'est un nouveau numéro.", {}, "rire"),
					L("Le soir, je jongle à l'entrée de la Halle pendant que les gens arrivent. Avec des balles lumineuses que Fusible m'a fabriquées. Elles clignotent. Moi aussi, un peu, quand j'en prends une sur la tête.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'étais employé de bureau. Je classais des dossiers dans des boîtes grises. Un jour, j'ai jonglé avec trois dossiers pendant la pause. Mon chef m'a vu. J'ai cru qu'il allait me renvoyer. Il a dit : « Fais-en quatre. » J'ai démissionné le lendemain pour en faire cinq.", {}, "rire"),
					L("Mes bulles, je les fais avec le liquide de vaisselle de la Cantine. Lentille me le donne à condition que je fasse rire les enfants qui font la vaisselle. Les enfants font la vaisselle en riant. Lentille dit que c'est un miracle.", {"sujet_min": ["lui", 1]}),
					L("Ma crête violette, c'est pour qu'on me voie de loin quand je tombe. Comme ça, on vient m'aider plus vite. C'est une crête de sécurité.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Place des Palettes, au cœur de la ville, c'est ma scène. La fontaine est une baignoire, les bancs sont des palettes, et l'arbre a des guirlandes. Le public, ce sont des enfants, des chiens et des pigeons. Les pigeons sont les plus durs.", {}),
					L("Au Bassin à sec, le skatepark, j'essaie de faire du monocycle sur les rampes. Tornade dit que c'est impossible. Je lui prouve tous les jours que c'est impossible.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Mouette fait des bulles maintenant ! Elle en a fait une qui a emporté une mouette. La mouette est revenue toute brillante. Elle ne nous parle plus.", {}, "rire"),
					L("Chaussette m'a demandé de jongler pour ses chiens. Pneu a attrapé une balle. Puis deux. Puis il est parti avec. Ce chien a un avenir dans le cirque.", {}, "rire"),
				],
				"interpelle": [L("Approchez, approchez ! Le spectacle commence !", {"visites_max": 0}, "rire"), L("{surnom} ! Regarde ce nouveau tour !", {"visites_min": 1}, "salut")],
			}},
		{"id": "bardane", "nom": "Bardane", "titre": "grimpeuse d'arbres et militante écolo", "maison": "porte_bardane", "village": "boucan",
			"agenda": [[7, 12, ["spores_1", "spores_2"]], [12, 13, "jardins_2"], [13, 18, ["place_arbre", "rue_4", "chateau_eau"]], [18, 21, ["conserverie_toit_jardin", "jardins_1"]], [21, 23.5, "halle_fosse_4"], [23.5, 7, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "tresse", "yeux": Y_VERT, "haut": [0.3, 0.42, 0.22], "carrure": 0.95},
			"teinte": PEAU[4],
			"punk": {"tenue": "sportif", "patchs": true, "chapeau": "bandana"},
			"humeur_base": 0.55, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.85, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"graines": 2.0, "gland_dore": 2.5, "noix_coco": 1.5, "baies": 1.5, "plume_corbeau": 1.0}, "deteste": {"plans_lisse": -2.5, "buche": -1.5, "hache": -2.0},
			"tics": ["Les arbres d'abord.", "Je monte voir.", "Ça pousse !", "Respire la feuille."],
			"surnoms": [[0, "petit gland"], [25, "jeune pousse"], [50, "ma branche"], [75, "mon chêne"], [95, "mon arbre-monde"]],
			"repliques": {
				"accueil": [
					L("Salut d'en haut ! … Je descends. (Elle descend d'un arbre en rappel.) Bardane. Je grimpe aux arbres, je les protège, je les compte, je leur fais des câlins. Monsieur Lisse voulait couper le grand saule de la place. Je me suis installée dedans. Ça fait trois cents jours.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as respiré une feuille aujourd'hui ? Non ? Viens, je t'en présente une.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Il y a un nouveau bouleau qui a poussé dans une fissure du béton, derrière la Halle. Tout seul ! Sans demander la permission ! Je l'ai appelé Rebelle.", {}, "rire"),
					L("Furieuse. Les robots de Lisse ont mesuré le Bois des Spores avec des lasers. Pour « optimiser la surface ». On n'optimise pas un bois. On s'y promène.", {"q56": "bo_lisse="}),
					L("Le soir, je monte sur le toit de la Conserverie et j'écoute les arbres de la ville. Il y en a quarante-trois. Je les connais tous par leur prénom.", {"soir": true}),
				],
				"lui": [
					L("Petite, je grimpais partout : aux arbres, aux armoires, aux réverbères. Mes parents m'ont offert un harnais pour mes dix ans. Je ne l'ai jamais retiré. Enfin si, pour dormir. Je dors dans un hamac. Accroché à un arbre.", {}, "rire"),
					L("J'ai vécu trois cents jours dans le grand saule de la place, pour empêcher Lisse de le couper. Lentille me montait la soupe avec une poulie. Cerise me faisait passer son fanzine. Tapage me racontait des histoires d'en bas. Le saule est toujours là.", {"sujet_min": ["lui", 1]}),
					L("Je vais te dire un secret : j'ai le vertige dans les escaliers. Les escaliers, ça n'a pas de feuilles, rien pour s'accrocher. Dans un arbre, je n'ai jamais peur. L'arbre me tient.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Bois des Spores, au sud, autour du vieux gazomètre : des bouleaux, des saules, des buddleias violets que les papillons adorent, et des champignons partout. C'est le plus beau bois de l'archipel. Et Lisse veut en faire un parking.", {}),
					L("Dans le Bois des Spores vivent les champignards : des petites créatures champignons farceuses. Elles soufflent des nuages de spores colorées qui font éternuer. Elles ne sont pas méchantes. Juste très, très agaçantes. Comme les cousins.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le château d'eau, Pigment l'a peint pendant que je la tenais avec une corde. Trois semaines là-haut. On a mangé les soupes de Lentille à vingt-huit mètres. On a vu la mer de tous les côtés.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Mère Morille dit que les champignons géants de la Cathédrale se parlent par leurs racines. Radis dit que c'est scientifiquement possible. C'est la seule fois où ils ont été d'accord.", {}, "rire"),
					L("J'ai attaché une banderole « Les arbres ne sont pas à vendre » au panneau de Lisse. Le lendemain, ses robots l'avaient pliée en quatre, repassée, et posée sur mon arbre. Avec un mot : « Merci de votre compréhension. »", {}, "rire"),
				],
				"interpelle": [L("Hé, d'en bas ! Tu aimes les arbres ?", {"visites_max": 0}), L("{surnom} ! Viens voir Rebelle, il a grandi !", {"visites_min": 1}, "salut")],
			}},
		{"id": "patchouli", "nom": "Patchouli", "titre": "voisine des Boîtes, liseuse de pigeons", "maison": "porte_patchouli", "village": "boucan",
			"agenda": [[8, 12, ["boites_1", "boites_3"]], [12, 13, "cantine_table_5"], [13, 18, ["place_banc_1", "boites_1", "place_fontaine"]], [18, 22, "boites_1"], [22, 8, "maison"]],
			"azur": {"cheveux": LAVANDE, "coiffure": "long", "yeux": Y_VIOLET, "haut": [0.55, 0.35, 0.6], "robe": [0.45, 0.25, 0.5], "robe_longue": true, "vieux": true, "foulard": [0.85, 0.55, 0.2]},
			"teinte": PEAU[1],
			"punk": {"tenue": "chale", "patchs": true, "objet": "carnet"},
			"humeur_base": 0.6, "traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 0.9, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"graines": 2.0, "plume_lune": 2.5, "the_menthe": 2.0, "eclat_lune": 2.0, "pain_miel": 1.5}, "deteste": {"plans_lisse": -1.0, "plume_corbeau": -0.5},
			"tics": ["Les pigeons l'ont dit.", "Je le savais !", "Roucou…", "C'était écrit dans les plumes."],
			"surnoms": [[0, "petite âme"], [25, "mon étoile"], [50, "ma prédiction préférée"], [75, "mon destin"], [95, "mon pigeon voyageur"]],
			"repliques": {
				"accueil": [
					L("Je le savais ! Les pigeons m'ont annoncé ce matin qu'un visiteur viendrait. Ou qu'il pleuvrait. Ou les deux. Je suis Patchouli, voisine des Boîtes, et je lis l'avenir dans les pigeons. Pas dans leurs entrailles, rassure-toi : dans leur façon de picorer.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Le gros pigeon gris a picoré trois fois à gauche. Ça veut dire que tu vas passer une bonne journée. Ou que tu vas manger une soupe. Souvent, c'est pareil.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Radieuse ! Les pigeons ont annoncé un grand événement. Ils ont tous roucoulé en même temps. Il y a aussi un monsieur qui jetait du pain. Mais je préfère l'explication mystique.", {}, "rire"),
					L("Le soir, je reste devant mon conteneur et je regarde les pigeons rentrer. Ils rentrent en formation. Ce soir, ils dessinaient un cœur. Ou un haricot. L'avenir est flou, mais il est mignon.", {"soir": true}),
				],
				"lui": [
					L("J'ai été voyante dans une fête foraine, avec une boule de cristal en plastique. Un jour, la boule s'est cassée. Un pigeon s'est posé sur ma table et a picoré les miettes de mon sandwich en forme de point d'interrogation. J'ai compris que c'était un signe. Ou qu'il avait faim.", {}, "rire"),
					L("Mes pigeons ont tous un nom : Nostradamus, Madame Irma, Petit-Gris, Voyant, et Bernard. Bernard ne prédit rien. Il mange. On a besoin d'un Bernard dans toute équipe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Une fois, une seule fois, une prédiction s'est réalisée exactement. J'avais dit « Boulon va soulever une maison ». Le lendemain, il a posé le premier conteneur des Boîtes. J'ai eu tellement peur que je n'ai rien prédit pendant un mois.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Boîtes, à l'est, c'est le village des conteneurs. Le mien est violet, avec des étoiles. Boulon l'a posé à côté de celui de la famille Pimpin, qui a un poulailler sur le toit. Les poules et les pigeons ne s'entendent pas. Ce sont des querelles de voisinage.", {}),
					L("Je fais l'horoscope des pigeons pour le fanzine d'Agrafe et pour la radio du Sergent. Les gens me disent que c'est toujours vrai. C'est parce que j'écris des choses comme « Vous allez respirer ». Ça marche à tous les coups.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Les pigeons m'ont dit que Monsieur Lisse aimait la musique en secret. Il paraît qu'il tapote du pied quand il passe devant la Halle. Les pigeons voient tout. Surtout les pieds.", {}),
					L("Radis dit que mes pigeons se trompent une fois sur deux. Une fois sur deux ! C'est la moitié de raison ! Il est vexé parce qu'ils ont prédit qu'une limace mangerait ses salades. Elle les a mangées.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Les pigeons parlent de toi !", {"visites_max": 0}), L("{surnom} ! J'ai une prédiction pour toi !", {"visites_min": 1}, "salut")],
			}},
		{"id": "tornade", "nom": "Tornade", "titre": "skateur du Bassin à sec, le fils de Rustine et de Copeau", "maison": "porte_tornade", "village": "boucan",
			"agenda": [[8, 12, ["bassin_sec_1", "bassin_sec_2"]], [12, 13, "cantine_table_1"], [13, 18, ["bassin_sec_1", "bassin_sec_2", "place_jeu_1"]], [18, 20, "place_jeu_1", ["place_jeu_2", "place_fontaine"]], [20, 8, "maison"]],
			"azur": {"cheveux": TURQUOISE, "coiffure": "court", "yeux": Y_VERT, "haut": [0.85, 0.2, 0.15], "enfant": true, "taille": 0.76},
			"teinte": PEAU[1],
			"punk": {"tenue": "enfant", "patchs": true, "objet": "skate", "chapeau": "casque_skate"},
			"humeur_base": 0.7, "traits": {"bavard": 0.95, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.45, "rancunier": 0.05},
			"aime": {"os_sardine": 3.0, "glace": 2.5, "cerf_volant": 2.0, "boulon": 1.5, "patch_rat": 2.0}, "deteste": {"plans_lisse": -1.5, "tisane_lune": -1.0},
			"tics": ["Trop stylé !", "Carrément !", "T'as vu ? T'AS VU ?", "Même pas mal !"],
			"surnoms": [[0, "le nouveau"], [25, "mon pote"], [50, "mon équipier"], [75, "mon meilleur pote"], [95, "le roi du skatepark"]],
			"repliques": {
				"accueil": [
					L("Salut ! T'as vu ? T'AS VU ? Je viens de faire un saut de la rampe jusqu'au bord ! … Bon, je suis tombé à la fin. Mais t'as vu le début ? Moi c'est Tornade. Je suis le meilleur skateur du Bassin à sec. Le seul de moins de onze ans. Donc le meilleur.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Regarde mon casque ! Il a une nouvelle bosse ! Elle est trop belle !", {"visites_min": 2}, "rire"),
					L("SARDINE ! Tu l'as retrouvé ! (Il serre le chien très fort.) … Il te regarde tout le temps, hein. Il t'a choisi. C'est d'accord. Mais tu me le ramènes au skatepark de temps en temps.", {"q56": "bo_sardine=finie", "visites_max": 6}),
				],
				"humeur": [
					L("Trop bien ! J'ai appris un nouveau tour : le « Tornade-Retournée ». Tu sautes, tu tournes, et tu atterris sur le dos. Le dernier bout, c'est pas exprès. Mais j'y travaille.", {}, "rire"),
					L("Sardine a disparu… Il a suivi un robot de Lisse. Il court toujours après les robots. Il croit que c'est des grosses boîtes de croquettes. Je l'ai cherché partout dans la ville. Il est peut-être à la Casse… c'est loin, la Casse.", {"q56": "bo_sardine=en_cours"}),
					L("Le soir, Maman me dit de rentrer. Je fais encore un tour. Puis encore un. Puis elle siffle trois fois, et là, faut vraiment rentrer.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon casque, c'est Papa qui me l'a peint, et Pigment a ajouté une flamme. Maman a dit « une flamme raisonnable ». Pigment a dit qu'elle ne savait pas faire. Alors la flamme est énorme. Trop stylé.", {}, "rire"),
					L("Sardine, je l'ai trouvé dans une caisse de sardines vide, au port, quand il était tout petit. D'où son nom. Il sentait le poisson pendant trois mois. Maintenant il sent le chien. C'est mieux. Un peu.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je dors avec mon casque. Pas parce que j'ai peur de tomber du lit. Enfin… un peu. Je suis déjà tombé du lit quatre fois. Une fois, j'ai fait un salto. Personne ne m'a vu. C'était mon plus beau tour.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Bassin à sec, c'est une ancienne cale sèche pour réparer les bateaux, à l'est du port. On l'a vidée et maintenant c'est un skatepark ! Les courbes sont parfaites. Les bateaux, ils avaient de la chance.", {}),
					L("Ma sœur Cerise fait un fanzine. Elle a écrit un article sur moi : « Tornade tombe encore ». C'est pas un article, c'est de la jalousie.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Mère Morille, dans le gazomètre, elle a des champignons qui font sauter super haut ! Le Bolet-Ressort ! Mais Maman dit que je n'ai pas le droit de manger un champignon sans que Mère Morille me dise oui. Et dans la vraie vie, jamais. JAMAIS. Elle l'a dit trois fois.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le monsieur gris, Gédéon, il tapote sur tout. Une fois, il a tapoté sur ma planche. C'était le meilleur rythme du monde. Je lui ai dit qu'il devrait faire batteur. Il est devenu tout rouge.", {"pas_trouve": "gedeon_batteur"}),
					L("Cradoc dit qu'il peut faire du monocycle sur les rampes. Il tombe à chaque fois. Mais il tombe mieux que moi. Je prends des notes.", {}, "rire"),
				],
				"interpelle": [L("Hé ! T'as vu mon saut ?", {"visites_max": 0}, "rire"), L("{surnom} ! Regarde ! REGARDE !", {"visites_min": 1}, "salut")],
			}},
		{"id": "cerise", "nom": "Cerise", "titre": "dessinatrice de fanzines, la fille de Rustine et de Copeau", "maison": "porte_cerise", "village": "boucan",
			"agenda": [[8, 12, ["bassin_sec_2", "place_arbre"]], [12, 13, "cantine_table_1"], [13, 17, ["imprimerie", "place_arbre", "rails_wagon"]], [17, 20, "place_jeu_2", ["place_jeu_1", "place_fontaine"]], [20, 8, "maison"]],
			"azur": {"cheveux": ROSE_VIF, "coiffure": "crete", "yeux": Y_BRUN, "haut": [0.95, 0.85, 0.3], "enfant": true, "taille": 0.72},
			"teinte": PEAU[1],
			"punk": {"tenue": "enfant", "patchs": true, "objet": "carnet"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.75, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.15},
			"aime": {"fanzine": 2.5, "glace": 2.5, "carte_postale": 2.0, "plume_perroquet": 2.0, "gateau_miel": 2.0}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -1.0},
			"tics": ["Je peux t'interviewer ?", "C'est noté.", "Exclusif !", "C'est pour mon zine."],
			"surnoms": [[0, "mon lecteur"], [25, "mon témoin"], [50, "mon reporter"], [75, "mon rédacteur en chef"], [95, "ma une préférée"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Je peux t'interviewer ? C'est pour mon fanzine, « La Cerise sur le Zine ». Première question : est-ce que tu as une crête ? … Non ? Pourquoi ? Je note : « n'a pas encore de crête ». C'est pas grave, ça viendra.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Exclusif ! J'ai une nouvelle pour toi ! … Je l'ai oubliée. Mais elle était exclusive.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bonne ! Mon dernier numéro s'est mieux vendu que celui d'Agrafe ! Bon, il a dit que c'est grâce aux chevaux à crête. Mais c'est surtout grâce au talent.", {}, "rire"),
					L("Le soir, je dessine sur la place pendant que Tornade joue au ballon. Je dessine Tornade qui rate. Ça fait beaucoup de dessins.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Ma crête, je la fais toute seule avec du gel et un peigne. Elle tient trois heures. Après, elle penche. Maman dit qu'elle penche « avec caractère ». Papa dit qu'elle penche « vers la gauche ». Moi je dis qu'elle penche vers l'avenir.", {}, "rire"),
					L("Mon fanzine, je le dessine à la main et Agrafe me l'imprime à la Filature. Il y a des interviews, des dessins, et la rubrique « Les bêtises de Tornade ». C'est la rubrique la plus longue. Elle a des suites.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret, mais tu ne le mets dans aucun fanzine. Promis ? … J'adore les poneys roses. Avec des paillettes. Je fais une crête parce que je veux être une grande punk. Mais je peux être une grande punk qui aime les poneys, non ?", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("J'ai interviewé tout le monde à Port-Boucan. Sauf Clou : il a répondu « Mh » à toutes les questions. J'ai publié l'interview quand même. Elle fait une page de « Mh ». C'est très artistique.", {}, "rire"),
					L("Papa m'a construit une cabane dans l'arbre de la Place des Palettes. C'est ma rédaction. Il y a un bureau, un tampon, et une boîte « courrier des lecteurs ». J'ai reçu trois lettres. Deux de Tapage.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Tapage m'a raconté qu'il avait joué un concert sur la lune. J'ai écrit « invention » au crayon dans la marge. Mais j'ai quand même dessiné la lune. Avec une crête.", {}, "rire"),
					L("Exclusif : Mademoiselle Prune a un badge des Rats de Cale caché sous sa veste. Je l'ai vu briller. Je ne l'ai pas publié. Une bonne journaliste protège ses sources. Et ses badges.", {}),
				],
				"interpelle": [L("Bonjour ! Je peux t'interviewer ?", {"visites_max": 0}, "salut"), L("{surnom} ! Une question pour mon zine !", {"visites_min": 1}, "rire")],
			}},
		# ================================================================ le sud
		{"id": "morille", "nom": "Mère Morille", "titre": "sage des champignons de la Cathédrale des Spores", "maison": "porte_morille", "village": "boucan",
			"agenda": [[6, 10, ["spores_1", "spores_2"]], [10, 18, "gazometre_roulotte"], [18, 21, "gazometre_centre"], [21, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "long", "yeux": Y_VIOLET, "haut": [0.35, 0.28, 0.45], "robe": [0.3, 0.22, 0.38], "robe_longue": true, "vieux": true, "foulard": [0.55, 0.35, 0.75], "taille": 0.9},
			"teinte": PEAU[2],
			"punk": {"tenue": "chale", "patchs": true, "objet": "panier"},
			"humeur_base": 0.55, "traits": {"bavard": 0.55, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.15},
			"aime": {"champignon": 2.0, "fleur_lune": 2.0, "tarte_potiron": 2.0, "the_menthe": 1.5, "champi_lune": 2.5}, "deteste": {"plans_lisse": -2.0, "hache": -1.5},
			"boutique": {"vend": {"champi_ressort": 25}, "achete": {"champignon": 2, "baies": 1, "fleur_lune": 4}},
			"tics": ["Dans un conte, oui. Dans la vraie forêt : jamais !", "Écoute les spores.", "Doucement, mon petit champignon.", "Hm hm."],
			"surnoms": [[0, "mon petit champignon"], [25, "ma petite girolle"], [50, "mon bolet"], [75, "ma morille d'or"], [95, "mon petit prince des spores"]],
			"repliques": {
				"accueil": [
					L("Entre, entre, mon petit champignon. N'aie pas peur de la lumière bleue : ce sont les chapeaux qui brillent. Je suis Mère Morille. Je vis ici, dans la Cathédrale des Spores, avec les champignons féeriques. Ils sont magiques, oui. Et je te le dis tout de suite : dans un conte, on peut les goûter. Dans la vraie forêt : jamais ! Jamais un champignon qu'on ne connaît pas.", {"visites_max": 1}, "salut"),
					L("{surnom}. Les spores m'ont dit que tu arrivais. Elles bavardent, les spores. Assieds-toi sur la mousse.", {"visites_min": 2}),
				],
				"humeur": [
					L("Paisible. Ce matin, un champignon géant a ouvert un nouveau chapeau. Orange, grand comme une table. Il a fait « pouf » et toute la cathédrale a scintillé. C'est sa façon de dire bonjour.", {}),
					L("Taquine. Radis prétend que sa courge pèse quatre-vingt-dix-huit kilos. La mienne en pèse cent. Il dit que j'ai compté la roulotte. Je n'ai pas compté la roulotte. Juste un peu la mousse.", {}, "rire"),
					L("Le soir, je m'assois au milieu de la cathédrale, et je regarde les chapeaux s'allumer un par un. Bleu, violet, orange. C'est le plus beau concert de l'île. Ne le dis pas à Rouille.", {"soir": true}),
				],
				"lui": [
					L("Quand je suis arrivée, il y a quarante ans, ce gazomètre était une carcasse d'acier, grise et vide. Ma grand-mère m'avait laissé un vieux livre de contes, avec une spore séchée entre deux pages. Je l'ai posée sur la rouille. Elle a poussé. Puis une autre. Et voilà la cathédrale.", {}),
					L("Les champignons féeriques, je les connais tous : le Bolet-Ressort qui fait sauter, la Lunaire qui fait voir l'invisible, le Babillard qui fait comprendre les animaux, l'Arc-en-ciel et le Petit-Géant. Ce sont des champignons de conte. Les vrais champignons, eux, ne donnent aucun pouvoir. Certains rendent très malade. Retiens bien ça.", {"sujet_min": ["lui", 1]}),
					L("Ma roulotte, c'est Copeau qui l'a remise sur ses roues. Elle ne bouge plus depuis longtemps : les champignons ont poussé autour des roues. Ils la tiennent comme une main. Je crois qu'ils ne veulent pas que je parte. Je ne veux pas partir.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Cathédrale des Spores, c'est l'ancien gazomètre, au sud de la ville : un grand anneau de piliers d'acier, sans toit, et dedans, une forêt de champignons géants qui brillent la nuit. Il y a de la mousse partout. Marche doucement : elle est sensible.", {}),
					L("Autour, le Bois des Spores : bouleaux, saules, buddleias. Les champignards y vivent. Ce sont des petits farceurs à chapeau qui soufflent des spores colorées. Ils font éternuer, rien de plus. Si tu les chasses, ils boudent. Leur roi, lui, est plus gros. Et il boude plus fort.", {"sujet_min": ["ile", 1]}, "rire"),
					L("L'Usine Grise de Lisse & Fils est juste à l'est du bois. Sa fumée est grise et propre. Mes champignons n'aiment pas ça : ceux qui poussent du côté de l'usine ont des chapeaux tout ternes. Il faudra qu'un jour quelqu'un aille dire deux mots à cette usine.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Bardane vient me voir le matin et elle me demande des nouvelles de chaque champignon. Par son prénom. Je lui ai dit qu'ils n'avaient pas de prénom. Elle leur en a donné. Le grand bleu s'appelle Gustave, maintenant.", {}, "rire"),
					L("Tornade voulait manger un Bolet-Ressort pour sauter jusqu'au toit de la Halle. Rustine a dit non. J'ai dit non. Tornade a dit : « Et dans un conte ? » J'ai dit : « Dans un conte, demande à ta mère. » Il demande encore.", {}, "rire"),
				],
				"interpelle": [L("Approche, mon petit champignon. N'aie pas peur.", {"visites_max": 0}), L("{surnom}. Les spores t'attendaient.", {"visites_min": 1}, "salut")],
				"boutique": [L("Je ne vends qu'une seule chose : le Bolet-Ressort. Les autres, il faut les trouver soi-même, dans la cathédrale. Et souviens-toi : dans un conte, oui. Dans la vraie forêt : jamais ! Tu as {pieces} pièces.", {})],
			}},
		{"id": "ferraille", "nom": "Ferraille", "titre": "sculpteur de la Casse", "maison": "porte_ferraille", "village": "boucan",
			"agenda": [[8, 12, "casse_atelier"], [12, 13, "casse_dragon"], [13, 19, ["casse_atelier", "casse_dragon"]], [19, 21, ["plage_feu", "casse_dragon"]], [21, 8, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chauve", "barbe": "longue", "yeux": Y_GRIS, "haut": [0.3, 0.3, 0.32], "tablier": [0.35, 0.25, 0.18], "carrure": 1.35, "lunettes": true},
			"teinte": PEAU[3],
			"punk": {"tenue": "bleu_travail", "clous": true, "patchs": true, "objet": "cle_molette", "lunettes": true},
			"humeur_base": 0.45, "traits": {"bavard": 0.6, "humour": 0.65, "curiosite": 0.8, "susceptible": 0.45, "rancunier": 0.2},
			"aime": {"boulon": 2.0, "ressort": 2.0, "engrenage_or": 3.0, "rouage": 2.0, "canard_mecanique": 1.5}, "deteste": {"plans_lisse": -1.5, "gelee_slime": -0.5},
			"boutique": {"vend": {"canard_mecanique": 8}, "achete": {"boulon": 2, "ressort": 2, "rouage": 3, "engrenage_or": 12}},
			"tics": ["Ça se soude.", "Ça, c'est de la belle ferraille.", "Tchhhh ! (le bruit de la soudure)", "Rien n'est jamais cassé. Juste en attente."],
			"surnoms": [[0, "petit boulon"], [25, "mon écrou"], [50, "ma pièce rare"], [75, "mon alliage préféré"], [95, "mon chef-d'œuvre d'acier"]],
			"repliques": {
				"accueil": [
					L("(Il relève ses lunettes de soudeur.) Tiens, un visiteur. Ferraille, sculpteur. Bienvenue à la Casse. Tu vois ces tas de vieilles voitures, de machines, de casseroles ? Toi, tu vois des déchets. Moi, je vois un dragon. Regarde : il est là-bas. Douze mètres. Il n'est pas fini. Il ne sera jamais fini. C'est ça, l'art.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu m'apportes des boulons ? Non ? Tu en trouveras sur les robots de Lisse. Ils en perdent partout. Ils sont mal serrés.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bonne. J'ai ajouté une écaille au dragon : une portière de voiture rouge. Il est content. Il ne le dit pas, mais je le sais : il a grincé.", {}, "rire"),
					L("Agacé. Les robots de Lisse viennent fouiller ma Casse pour se fabriquer des bras. Ils prennent mes plus belles pièces. Ils ont pris l'aile gauche de mon dragon. Il vole de travers, maintenant. En théorie.", {}),
					L("Le soir, je m'assois devant le dragon et je le regarde rouiller. Doucement. La rouille, c'est la couleur du temps qui passe. Elle est belle.", {"soir": true}),
				],
				"lui": [
					L("J'étais soudeur dans un chantier naval. Je soudais des coques de bateaux, toutes pareilles, grises. Un jour, avec les chutes, j'ai soudé un petit oiseau. Mon chef l'a jeté. Je suis allé le rechercher dans la benne. Je suis parti avec. Il est sur ma cheminée.", {}),
					L("Mon dragon s'appelle Brindezingue. Il a onze roues offertes par Rustine, une queue en tuyaux d'orgue et des yeux en phares de camion. Fusible veut les allumer. Je dis non. Un dragon, il faut que ça dorme. Il a l'air si paisible.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Les robots-fleurs du parc de sculptures, je les ai faits avec des pièces de robots de Lisse. Des bras qui poussaient, je les ai transformés en tiges. Des têtes qui menaçaient, en pétales. C'est ma réponse à Lisse. Il est passé les voir. Il est resté longtemps. Il n'a rien dit.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Casse, c'est au sud-est, entre le Bois des Spores et la mer. Un cimetière de voitures et de machines, et mon parc de sculptures. C'est le seul cimetière où les choses reviennent à la vie.", {}),
					L("Les robots de Lisse ont un repaire tout près de l'Usine Grise. Ils y entassent ce qu'ils volent en ville. Si un jour tu cherches quelque chose qui a disparu, commence par là. Et par chez moi. Ils oublient toujours des trucs en passant.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Clou est venu me demander de souder des clous sur sa guitare. Sur Germaine. Je lui ai dit que c'était un instrument délicat. Il m'a regardé. Je les ai soudés. Il a hoché la tête. Une fois. Pour Clou, c'est une embrassade.", {}, "rire"),
					L("Boulon passe me voir le dimanche. Il soulève les voitures pour que je puisse chercher les pièces dessous. Il les repose doucement. Toujours. Même les épaves. Surtout les épaves.", {}),
				],
				"interpelle": [L("Hé, toi ! Tu as de la ferraille sur toi ?", {"visites_max": 0}), L("{surnom} ! Viens voir Brindezingue !", {"visites_min": 1}, "salut")],
				"boutique": [L("J'achète la ferraille : boulons, ressorts, rouages. Et je vends mes canards soudés. Ils ne nagent pas, mais ils ont du caractère. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "gravier", "nom": "Gravier", "titre": "pêcheur de la Plage aux Galets", "maison": "porte_gravier", "village": "boucan",
			"agenda": [[5, 11, "plage_cabane"], [11, 13, ["quai_2", "quai_3"]], [13, 18, ["plage_cabane", "phare"]], [18, 22, "plage_feu"], [22, 5, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "courte", "yeux": Y_BLEU, "haut": [0.2, 0.25, 0.35], "vieux": true, "carrure": 1.1},
			"teinte": PEAU[3],
			"punk": {"tenue": "marin", "patchs": true, "objet": "canne_peche", "chapeau": "bonnet"},
			"humeur_base": 0.4, "traits": {"bavard": 0.05, "humour": 0.5, "curiosite": 0.3, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"maquereau": 2.0, "dorade": 2.0, "sardine": 1.5, "coquillage": 1.0, "the_menthe": 1.0}, "deteste": {"plans_lisse": -1.0, "vieille_botte": -1.0},
			"tics": ["Hm.", "La mer sait.", "Patience.", "…"],
			"surnoms": [[0, "petit"], [25, "petit"], [50, "l'ami"], [75, "mon ami"], [95, "mon ami de mer"]],
			"repliques": {
				"accueil": [
					L("… (Il te regarde longtemps.) Gravier. (Il regarde la mer.) Pêcheur. (Il regarde à nouveau la mer.) Assieds-toi. Ou pas. La mer s'en fiche.", {"visites_max": 1}),
					L("{surnom}. (Il hoche la tête.) Ça mord.", {"visites_min": 2}),
				],
				"humeur": [
					L("Calme. Comme la mer. Aujourd'hui.", {}),
					L("Trois maquereaux. Une botte. La botte, je l'ai relâchée.", {}, "rire"),
					L("Le soir, le feu. Boulon vient. On ne dit rien. C'est bien.", {"soir": true}),
				],
				"lui": [
					L("J'ai pêché toute ma vie. Mon père aussi. Il disait : « Celui qui parle fait fuir les poissons. » J'ai beaucoup pêché.", {}),
					L("Une fois, j'ai parlé pendant une heure. À ma femme. Le jour où je lui ai demandé de m'épouser. Elle a dit : « Tu as fini ? » J'ai dit oui. Elle a dit oui. Depuis, elle parle pour deux. Elle est partie avant moi. Maintenant, c'est la mer qui parle.", {"sujet_min": ["lui", 1]}),
					L("Les gens croient que je suis triste. Non. Je suis attentif. Ce n'est pas pareil.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Plage aux Galets. Sud-est. Les galets roulent. Ça fait de la musique. Mieux que la Halle. Moins fort.", {}),
					L("Le phare tagué, au sud. Pigment l'a peint. Il éclaire quand même. C'est l'essentiel.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Tapage parle beaucoup. Moi peu. Ensemble, on fait la moyenne.", {}, "rire"),
					L("Patchouli m'a prédit un gros poisson. J'ai pêché une baleine en caoutchouc. Elle avait raison, en un sens.", {}, "rire"),
				],
				"interpelle": [L("… Hm.", {"visites_max": 0}), L("{surnom}. (Un signe de tête.)", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ Lisse & Fils
		{"id": "lisse", "nom": "Monsieur Lisse", "titre": "promoteur, patron de Lisse & Fils", "maison": "porte_lisse", "village": "boucan", "vouvoie": true,
			"agenda": [[8, 12, "bureau_vente"], [12, 13, ["place_camion", "rue_5"]], [13, 18, "bureau_vente"], [18, 20, ["usine_portail", "rue_6"]], [20, 8, "maison"]],
			"azur": {"cheveux": [0.18, 0.17, 0.17], "coiffure": "court", "yeux": Y_GRIS, "haut": [0.45, 0.46, 0.48], "carrure": 1.05},
			"teinte": PEAU[6],
			"punk": {"tenue": "costume", "clous": false, "patchs": false, "objet": "tablette"},
			"humeur_base": 0.3, "traits": {"bavard": 0.85, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.7, "rancunier": 0.4},
			"aime": {"plans_lisse": 3.0, "badge_usine": 1.5, "cafe_vapeur": 1.5, "croissant": 1.0, "partition": 1.0}, "deteste": {"bombe_peinture": -2.0, "affiche_concert": -1.5, "fanzine": -1.0, "patch_rat": -1.0},
			"tics": ["Optimisons.", "C'est une question de rentabilité.", "Merci de votre compréhension.", "Signez ici."],
			"surnoms": [[0, "cher prospect"], [25, "cher client"], [50, "client privilégié"], [75, "partenaire stratégique"], [95, "cher ami… euh, partenaire"]],
			"repliques": {
				"accueil": [
					L("Bienvenue, bienvenue, cher prospect ! Aldric Lisse, de Lisse & Fils. On rase, on bâtit, on encaisse. Vous admirez la maquette ? Le Lisse-Center ! Une galerie marchande éternelle, climatisée, optimisée, avec des escalators qui montent ET qui descendent. Le progrès. Ici, aujourd'hui, ce n'est qu'une friche. Bruyante. Colorée. Inefficace.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Vous revenez signer ? Non ? Vous revenez regarder la maquette. Tout le monde revient regarder la maquette. Elle est très optimisée.", {"visites_min": 2, "q56": "bo_lisse="}),
					L("Vous. (Il réajuste sa cravate.) Bon. J'ai perdu. Ma Pelleteuse est en morceaux, mes plans sont chez Mamie Barricade, et mon fils joue de la batterie. Fort. Très fort. … Il est bon, n'est-ce pas ? Ne répondez pas. Je sais qu'il est bon.", {"q56": "bo_lisse=finie"}),
				],
				"humeur": [
					L("Optimiste, comme toujours. Mes robots ont repeint trois murs en gris cette nuit. Ce matin, ils avaient tous des fleurs. Je ne sais pas comment elle fait. C'est très inefficace. Et très rapide.", {"q56": "bo_lisse="}, "rire"),
					L("Préoccupé. Mes robots déménageurs reviennent tous de Port-Boucan avec des écharpes cloutées tricotées autour du cou. Ils refusent de les enlever. Ils disent qu'elles « tiennent chaud au circuit ».", {"q56": "bo_lisse="}, "rire"),
					L("Étrangement… calme. J'ai signé le Bail collectif. Je pensais que ça me ferait mal. Ça m'a fait… du bien ? C'est une sensation non optimisée. Je vais l'étudier.", {"q56": "bo_lisse=finie"}),
				],
				"lui": [
					L("Lisse & Fils, c'était l'entreprise de mon père, Ambroise Lisse. Il disait : « Un terrain vide est une perte. Un terrain plein de gens est une perte plus grande. » J'ai repris l'entreprise à trente ans. J'ai repris la cravate aussi. Elle me serre un peu.", {}),
					L("Mon fils Gédéon devait reprendre l'entreprise. Il s'appellerait « le Fils » de Lisse & Fils. Mais il tapote. Sur les bureaux, sur les dossiers, sur les maquettes. Il a tapoté sur la maquette du Lisse-Center jusqu'à ce que l'escalator tombe. En rythme.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Quand j'étais petit, mon père m'emmenait sur les quais du Vieux Bassin pour compter les caisses. Une dame docker m'aidait à porter les oranges. Elle m'avait donné un caramel. Je… je ne sais pas pourquoi je vous raconte ça. Ce n'est pas rentable.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon Bureau de vente est au sud-ouest de la place, entre la Filature et le Mur d'Expression. Bungalow gris, impeccable, climatisé. Le seul bâtiment propre de l'île. Enfin, il l'était avant cette nuit. Il y a un rat qui joue de la guitare sur la porte.", {}),
					L("Mon usine, l'Usine Grise, est au sud-est, derrière le Bois des Spores. Cinq étages sous terre : des bureaux, une chaîne de montage, une chaufferie, un entrepôt, et tout au fond… Non. C'est confidentiel. Ne descendez pas. Surtout ne descendez pas.", {"sujet_min": ["ile", 1]}),
					L("Le Lisse-Center aurait eu quatre cents boutiques, deux mille places de parking et une fontaine qui joue l'hymne de Lisse & Fils toutes les heures. J'ai écrit l'hymne moi-même. Il manquait… un batteur.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Ma secrétaire, Mademoiselle Prune, est d'une efficacité remarquable. Elle part toujours à vingt heures cinquante-cinq précises. Je ne sais pas où elle va. Je suppose qu'elle va optimiser quelque chose.", {}),
					L("Mamie Barricade me regarde toujours comme si j'avais encore huit ans. C'est très désagréable. Elle me demande si je mange bien. Je mange très bien. Optimisé.", {}),
				],
				"interpelle": [L("Vous ! Oui, vous ! Une maison au Lisse-Center ? Prix de lancement !", {"visites_max": 0, "q56": "bo_lisse="}), L("{surnom}. Bonjour. (Il hésite.) Bonne journée… optimisée.", {"visites_min": 1}, "salut")],
			}},
		{"id": "gedeon", "nom": "Gédéon", "titre": "fils de Monsieur Lisse", "maison": "porte_gedeon", "village": "boucan", "vouvoie": true,
			"agenda": [[8, 12, ["bureau_vente_3", "rue_3"]], [12, 14, ["rails_wagon", "bassin_sec_2"]], [14, 18, ["bureau_vente_3", "rue_3"]], [18, 21, ["place_banc_2", "quai_1"]], [21, 23.5, "halle_entree"], [23.5, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "boucles", "yeux": Y_BRUN, "haut": [0.45, 0.46, 0.48], "taille": 1.04, "carrure": 0.82},
			"teinte": PEAU[6],
			"punk": {"tenue": "costume", "clous": false, "patchs": false},
			"humeur_base": 0.35, "traits": {"bavard": 0.25, "humour": 0.55, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.0},
			"aime": {"baguettes": 3.0, "partition": 2.0, "patch_rat": 2.5, "affiche_concert": 2.0, "glace": 1.5}, "deteste": {"plans_lisse": -1.0, "badge_usine": -0.5},
			"tics": ["(Tap-tap-tap.)", "Pardon.", "Ce n'est rien.", "Boum-tchak."],
			"surnoms": [[0, "monsieur"], [25, "mon ami"], [50, "mon ami"], [75, "mon meilleur ami"], [95, "mon premier fan"]],
			"repliques": {
				"accueil": [
					L("Oh ! Pardon. Je ne vous avais pas vu. (Il arrête de tapoter sur un poteau.) Gédéon. Gédéon Lisse. Le fils. De Lisse & Fils. Le « Fils », c'est moi. (Il tapote nerveusement sa cravate : boum-tchak, boum-boum-tchak.) Pardon. C'est nerveux.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Bonjour. (Tap-tap.) Vous allez bien ? Moi, ça va. Mes doigts aussi. Ils vont même un peu trop bien.", {"visites_min": 2, "pas_trouve": "gedeon_batteur"}),
					L("{surnom} ! Vous étiez là, hier soir ? Vous avez entendu ? J'ai joué ! Sur une vraie batterie ! Devant des gens ! J'ai fermé les yeux tout le concert. Quand je les ai ouverts, tout le monde sautait. Même Papa. Un peu. Du pied.", {"a_trouve": "gedeon_batteur"}, "rire"),
				],
				"humeur": [
					L("Bien. Je crois. Papa m'a demandé de compter les places de parking du futur Lisse-Center. J'ai compté en rythme. Un-deux-trois-quatre, un-deux-trois-quatre. J'en ai trouvé deux mille et un. Et un solo.", {"pas_trouve": "gedeon_batteur"}, "rire"),
					L("Heureux. Vraiment heureux. C'est la première fois que je dis ça sans tapoter nerveusement. (Tap-tap.) Bon. Presque.", {"a_trouve": "gedeon_batteur"}),
					L("Le soir, je vais jusqu'à l'entrée de la Halle Hurlante. Je n'entre pas. J'écoute à travers la porte, et je tape le rythme sur le mur. Le batteur de remplacement se trompe toujours. Moi pas. Mais personne ne m'entend. C'est mieux comme ça. Je crois.", {"soir": true, "pas_trouve": "gedeon_batteur"}),
				],
				"lui": [
					L("Depuis que je suis tout petit, je tape sur tout. Les tables, les casseroles, les dossiers de Papa. Ma première batterie, c'était trois boîtes de classement et une corbeille à papier. Papa a dit que c'était « une utilisation non conforme du mobilier ».", {}, "rire"),
					L("Papa veut que je reprenne Lisse & Fils. J'ai essayé. J'ai fait un stage. J'ai tamponné des avis d'expulsion. Je les ai tamponnés en rythme. Ça faisait une très bonne chanson. Mais c'était une très mauvaise idée.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous dire un secret. Tous les soirs, j'écoute les Rats de Cale derrière la porte de la Halle. Je connais toutes les chansons par cœur. Toutes les parties de batterie. J'en ai même inventé de meilleures. Mais je n'ai pas de baguettes. Et je n'ai pas le courage. Surtout pas le courage.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Bureau de vente de Papa, c'est le bungalow gris au sud-ouest de la place. J'y classe des dossiers. Enfin, je les empile. En forme de batterie. Mademoiselle Prune me laisse faire. Elle m'a donné une agrafeuse qui fait « tchak ».", {}, "rire"),
					L("Le vieux wagon sur les rails, c'est mon endroit secret à midi. Les rails font « tac-tac » quand on tape dessus avec un caillou. Je m'entraîne là. Personne ne vient. Enfin, sauf Tornade. Il dit que je devrais faire batteur. Il a dix ans. Il dit ça comme si c'était facile.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Mademoiselle Prune a un badge des Rats de Cale sous sa veste. Je l'ai vu briller. Je ne l'ai pas dit à Papa. On a chacun nos secrets, au Bureau de vente.", {}),
					L("Papa tapote du pied quand il passe devant la Halle. Je l'ai vu. Il ne le sait pas. Je crois que je tiens ça de quelqu'un.", {}),
				],
				"interpelle": [L("Oh… bonjour. (Tap-tap.)", {"visites_max": 0}), L("{surnom} ! (Boum-tchak.) Pardon. Bonjour.", {"visites_min": 1}, "salut")],
			}},
		{"id": "prune", "nom": "Mademoiselle Prune", "titre": "secrétaire de Monsieur Lisse", "maison": "porte_prune", "village": "boucan", "vouvoie": true,
			"agenda": [[8, 12, "bureau_vente_2"], [12, 13, "cantine_table_6"], [13, 18, "bureau_vente_2"], [18, 21, ["phare", "place_banc_1"]], [21, 23.5, "halle_fosse_11"], [23.5, 8, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.5, 0.48, 0.5], "robe": [0.35, 0.34, 0.38], "lunettes": true},
			"teinte": PEAU[5],
			"punk": {"tenue": "tailleur", "clous": false, "patchs": false, "objet": "carnet", "lunettes": true},
			"humeur_base": 0.5, "traits": {"bavard": 0.45, "humour": 0.65, "curiosite": 0.6, "susceptible": 0.45, "rancunier": 0.1},
			"aime": {"patch_rat": 3.0, "affiche_concert": 2.5, "fanzine": 2.0, "sirop_menthe": 1.5, "limonade_boucan": 1.5}, "deteste": {"plans_lisse": -0.5, "vieille_botte": -0.5},
			"tics": ["C'est noté.", "Dans le dossier.", "Tout à fait.", "(Elle vérifie que sa veste est bien fermée.)"],
			"surnoms": [[0, "Monsieur ou Madame"], [25, "cher visiteur"], [50, "cher ami"], [75, "mon complice"], [95, "mon complice de fosse"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Mademoiselle Prune, secrétaire de Monsieur Lisse. Vous avez rendez-vous ? Non ? Je vous inscris. Voilà : vous avez rendez-vous. Monsieur Lisse vous recevra dans… (Elle consulte son carnet.) …jamais. Mais vous pouvez attendre. Les chaises sont grises. Toutes.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. (Elle vérifie que sa veste est bien fermée.) Je vous ai noté dans le dossier « Visiteurs sympathiques ». Il est très mince. Vous êtes en tête.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Efficace. J'ai classé quatre cents formulaires, tapé douze lettres d'expulsion et je les ai toutes envoyées… à la mauvaise adresse. Quelle maladresse. Ça arrive. Tous les jours.", {}, "rire"),
					L("Ravie. Je ne devrais pas le dire. Le Bail est signé, Gédéon joue, et Monsieur Lisse a souri ce matin. Il l'a noté dans son agenda : « 9 h 12, sourire ». C'était un beau sourire.", {"q56": "bo_lisse=finie"}),
					L("Le soir, je… je fais une promenade. Seule. Très calme. Rien à voir avec un concert. Je déteste le bruit. (Elle range rapidement une fausse moustache dans son sac.)", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je travaille pour Monsieur Lisse depuis huit ans. Je suis très efficace. Je connais tous ses rendez-vous, tous ses dossiers, et toutes ses manies. Il dit « optimiser » quatorze fois par heure. Je compte. Ça m'occupe.", {}, "rire"),
					L("La première fois que je suis venue à Port-Boucan, c'était pour coller des avis d'expulsion. Il pleuvait. Une dame âgée avec une crête m'a donné une écharpe et un thé. J'ai collé les avis à l'envers. Personne n'a pu les lire. Je ne me suis jamais expliqué pourquoi.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous confier quelque chose. (Elle ouvre sa veste d'un centimètre : dedans, une doublure couverte de badges des Rats de Cale.) Velours me les a cousus. Sirène me garde une limonade à la violette. Et je viens à tous les concerts. Avec une moustache. Ne dites rien. Surtout à Monsieur Lisse. Il serait… inoptimisé.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Bureau de vente est au sud-ouest de la place. J'y travaille de huit heures à dix-huit heures, avec une pause d'une heure. Pendant la pause, je vais à la Cantine de Lentille. Je paie toujours un peu plus. Pour les dossiers que je n'ai pas envoyés.", {}),
					L("Le phare tagué, au sud, c'est mon endroit. Le soir, j'y retrouve… quelqu'un. Pour échanger des recettes de sirop. Rien de plus. Ce n'est pas un complot. C'est de la menthe.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le jeune Gédéon empile ses dossiers en forme de batterie. Je l'ai vu jouer dessus avec deux crayons. Je lui ai donné une agrafeuse qui fait « tchak ». C'est tout ce que je pouvais faire. Pour l'instant.", {}),
					L("Monsieur Lisse a gardé dans son tiroir une photo d'une cabane en palettes, faite par un petit garçon. Lui. Je l'ai vue en classant. Je n'ai rien classé. Certaines choses ne se classent pas.", {}),
				],
				"interpelle": [L("Vous avez rendez-vous ?", {"visites_max": 0}), L("{surnom}. (Petit sourire, veste bien fermée.)", {"visites_min": 1}, "salut")],
			}},
	]

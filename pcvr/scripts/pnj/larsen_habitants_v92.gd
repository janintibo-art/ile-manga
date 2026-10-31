extends RefCounted
## V92 : les gens de l'Île de Larsen, la grande ville de yourtes.
##  - le Camp des Fleurs (les hippies) : Mamie Tournesol (la doyenne, qui a fondé le camp), Arc-en-Ciel
##    (le djembé, jour et nuit), Lune (la tisserande : le chanvre devient toile), Galet (le cordier),
##    Lavande (les jardins et les tisanes), Mantra (qui médite au bord de la mare, et qui rit tout le
##    temps), Bigoudi (la mécanicienne des bus peints) et la petite Bouton-d'Or (8 ans, l'arbre à rubans) ;
##  - Rainville (les grunges) : les Gouttières, le groupe du garage : Flanelle (chant), Grésil (guitare,
##    il parle très lentement), Bruine (basse, très timide) et Bourrasque (batterie, très pas timide) ;
##    Spleen (le Café Feedback), Vinyle (le Disquaire), Mère Averse (la doyenne, qui fabrique des
##    parapluies) et le petit Clapotis (10 ans, skate, ciré jaune) ;
##  - le Hameau des Roadies, derrière la scène : Jack (le chef roadie, qui monte la Grande Scène) et
##    Mégaphone (la régie, qui teste les micros : « Un, deux, un, deux… »).
## Les deux doyennes ne se parlent plus depuis très longtemps (le Soleil contre la Pluie) : la quête
## « Le Soleil et la Pluie » (journal_v56) les réconcilie… et le festival pourra avoir lieu (V93).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure ; les poses et
## les objets : pnj_larsen_v92.gd. Fiche « larsen » : style (hippie | grunge), tenue, chapeau,
## couronne (une couronne de fleurs, posée par le jeu) ; fiche « punk » : l'objet tenu (guitare, basse,
## baguettes, micro, skate, arrosoir, aiguilles, livre…), comme à Port-Boucan.
## « yourte » : le nom de la yourte où l'habitant vit (larsen_v91) ; sa porte devient « porte_<id> ».

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Paix et amour, {surnom} ! Et des tournesols plein les poches.", "si": {"camp": "fleurs"}, "geste": "salut"},
		{"t": "Va, {surnom}. Le soleil te suit, même quand il pleut.", "si": {"camp": "fleurs"}},
		{"t": "Salut. Prends un parapluie. Ou pas. De toute façon, on finit toujours mouillé.", "si": {"camp": "rain"}, "geste": "salut"},
		{"t": "À plus. Si tu entends un larsen, ce n'est pas nous. Enfin, si. Mais c'est exprès.", "si": {"camp": "rain"}, "geste": "rire"},
		{"t": "Bonne route ! Et si tu vois Jack, dis-lui qu'il a oublié ses câbles. Il oublie toujours ses câbles.", "si": {}},
	],
	"frappe": [
		{"t": "Aïe ! Pourquoi ? Ici, on règle tout avec un câlin et une chanson. Tu veux la chanson ?", "si": {"camp": "fleurs"}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouch. Ok. Ça, c'est pas cool, même pour Rainville.", "si": {"camp": "rain"}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! On ne tape pas les gens, sur l'île de Larsen. On tape sur les tambours.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Oh, merci… Tout ce qu'on donne finit par revenir, tu sais. Comme les saisons.", "si": {"camp": "fleurs"}},
		{"t": "Merci. Je vais le mettre au sec. Si j'arrive à trouver un endroit sec.", "si": {"camp": "rain"}},
		{"t": "Merci, {surnom}. C'est gentil.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Oh, {surnom}, ça me fait le cœur tout ensoleillé !", "si": {"camp": "fleurs"}, "geste": "rire"},
		{"t": "{dernier_cadeau}… Pour moi ? … Wow. Personne ne m'avait jamais… Bon, je ne pleure pas, c'est la pluie.", "si": {"camp": "rain"}},
		{"t": "{dernier_cadeau} ! Merci, {surnom}, c'est exactement ce qu'il me fallait !", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Hum… merci. C'est l'intention qui compte. Je vais… le donner à quelqu'un qui en a besoin.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Non merci. Ici, la seule chose qu'on fait exploser, c'est le son des amplis.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Sur une île aussi petite, on se souvient de tout le monde. Même de la mouette qui vole les tartines.", "si": {}}],
	"quete_inconnue": [{"t": "Moi ? Je ne t'ai rien demandé… Mais si tu veux aider, va voir Mamie Tournesol. Ou Mère Averse. Enfin, l'une ou l'autre : elles ne se parlent plus.", "si": {}}],
	"blague": [
		{"t": "Qu'est-ce qu'un tournesol dit quand il fait gris ? « Rien. J'attends. »", "si": {}, "geste": "rire"},
		{"t": "Pourquoi les grunges de Rainville ne prennent jamais de douche ? Parce qu'ils sortent dehors, c'est pareil !", "si": {}, "geste": "rire"},
		{"t": "Combien de hippies faut-il pour changer une ampoule ? Aucun : ils attendent qu'elle se réalise d'elle-même.", "si": {}, "geste": "rire"},
		{"t": "Comment on appelle un parapluie qui joue de la guitare ? Un para-pluie-rock ! … Bon. Celle-là, c'est Bourrasque. Elle la raconte à chaque répétition.", "si": {}, "geste": "rire"},
		{"t": "Que dit un coquelicot à un autre coquelicot ? « Tu es tout rouge ! » « Toi aussi ! »", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis : ici, les prix sont tout doux. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Reviens quand on sera de nouveau amis.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Prends-en soin !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu en as {pieces}. Repasse plus tard, ce n'est pas grave.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un ! Garde de la place pour autre chose.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}. Allège-le un peu.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces.", "si": {}}],
	"marchande_oui": [{"t": "Bon, d'accord. Le partage, c'est ce qui fait tourner le monde.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Non. Mes prix sont déjà tout petits.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui. Demain, peut-être.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Oh, c'est beau !", "Trop bien !", "Ha ha !", "Paix !"],
		"neutre": ["Bon.", "Hm.", "Alors…", "Ouais…"],
		"triste": ["Bof…", "Pfff…", "Il pleut dans mon cœur…", "Aïe…"],
		"colere": ["Ça suffit !", "Grrr.", "Pas cool !", "Tss."],
	},
	"tics": ["C'est comme ça.", "Tout est lié.", "On verra bien.", "Il faut que ça sonne."],
	"humeur_mots": [[0.6, "rayonnant"], [0.25, "de bonne humeur"], [-0.25, "un peu nuageux"], [-0.6, "maussade"], [-2.0, "en colère comme un larsen"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "frangin"], [75, "âme sœur"], [95, "enfant de Larsen"]],
}

## Peaux, cheveux, yeux
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.72, 0.42]
const BLOND_BLANC := [0.94, 0.9, 0.78]
const ROUX := [0.78, 0.32, 0.12]
const CHATAIN := [0.45, 0.3, 0.17]
const BRUN := [0.3, 0.19, 0.11]
const NOIR := [0.08, 0.06, 0.05]
const GRIS := [0.66, 0.65, 0.63]
const BLANC := [0.93, 0.92, 0.9]
const DELAVE := [0.7, 0.58, 0.42]
const Y_BLEU := [0.25, 0.45, 0.7]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BRUN := [0.32, 0.2, 0.12]
const Y_GRIS := [0.45, 0.5, 0.55]
const Y_NOISETTE := [0.5, 0.36, 0.18]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var camp: String = "fleurs" if str((out.get("larsen", {}) as Dictionary).get("style", "")) == "hippie" else "rain"
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			var lst: Array = []
			for e in COMMON[k]:
				var si: Dictionary = (e as Dictionary).get("si", {})
				if si.has("camp") and str(si["camp"]) != camp:
					continue
				var e2: Dictionary = (e as Dictionary).duplicate(true)
				(e2["si"] as Dictionary).erase("camp")
				lst.append(e2)
			rep[k] = lst
	out["repliques"] = rep
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = BASE[k]
	out = Azur.complete(out)
	out["groupe"] = "larsen"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Camp des Fleurs
		{"id": "mamie_tournesol", "nom": "Mamie Tournesol", "titre": "doyenne du Camp des Fleurs", "yourte": "fleurs_0", "maison": "porte_mamie_tournesol", "village": "larsen",
			"agenda": [[8, 11, ["jardin_1", "jardin_2"]], [11, 13, "feu_1"], [13, 16, ["camp_1", "arbre_rubans"]], [16, 19, ["jardin_2", "feu_1"]], [19, 22, "feu_1"], [22, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "tresse", "yeux": Y_BLEU, "haut": [0.95, 0.75, 0.2], "vieux": true, "robe": [0.9, 0.55, 0.15], "robe_longue": true, "lunettes": true},
			"teinte": PEAU[1],
			"larsen": {"style": "hippie", "tenue": "robe_fleurs", "couronne": "tournesol"},
			"punk": {"objet": "arrosoir"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.5},
			"aime": {"bouquet_tournesols": 2.5, "pain_miel": 2.0, "tisane_lune": 2.0, "miel": 1.5, "baies": 1.0}, "deteste": {"parapluie_rainville": -0.5, "vieille_botte": -1.0},
			"tics": ["Le soleil revient toujours.", "Mes petits…", "Paix sur toi.", "Comme disait ma mère, qui était une fleur."],
			"surnoms": [[0, "mon petit"], [25, "mon rayon"], [50, "mon tournesol"], [75, "mon soleil"], [95, "enfant du Camp"]],
			"repliques": {
				"accueil": [
					L("Bonjour, mon petit ! Bienvenue au Camp des Fleurs. Moi, c'est Mamie Tournesol. J'ai planté la première graine de ce camp il y a… oh, longtemps. Avant que tu sois né. Avant que ta maman soit née, peut-être. Viens t'asseoir au soleil.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Te revoilà. Tu as bonne mine. Le soleil te va bien.", {"visites_min": 2}),
					L("Mon messager du Soleil et de la Pluie ! Viens que je t'embrasse. Grâce à toi, j'ai retrouvé une vieille amie.", {"q56": "la_soleil_pluie=finie"}, "rire"),
				],
				"humeur": [
					L("Comme un tournesol à midi : la tête bien haute et le cœur chaud.", {}),
					L("Un peu triste, à vrai dire… Là-bas, à Rainville, il y a une vieille dame qui fabrique des parapluies. Autrefois, c'était ma meilleure amie. Et puis on s'est fâchées. Pour une bêtise.", {"q56": "la_soleil_pluie="}),
					L("Le soir, autour du feu, quand Arc-en-Ciel joue du djembé, je me sens jeune comme un bourgeon.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Quand je suis arrivée sur cette île, il n'y avait que des coquelicots, du vent et une yourte toute trouée. J'ai planté des tournesols. Les gens sont venus pour les tournesols, et ils sont restés pour la musique.", {}),
					L("Mère Averse et moi, on est arrivées ensemble, sur le même bateau, il y a cinquante ans. Elle aimait la pluie, j'aimais le soleil. On disait que c'était parfait : à nous deux, on faisait un arc-en-ciel.", {"sujet_min": ["lui", 1]}),
					L("Pourquoi on s'est fâchées ? Pour le festival. Elle voulait qu'il ait lieu sous la pluie, j'en voulais un au soleil. Cinquante ans sans se parler, pour une météo. Les vieilles dames sont parfois très bêtes.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Île de Larsen, c'est deux villages qui n'en font qu'un, même s'ils ne le savent pas encore : nous, au soleil, et ceux de Rainville, sous leur petit nuage.", {}),
					L("Le chanvre, ici, sert à faire des cordes, des toiles et des sacs. Galet en fait des cordes à la Corderie, Lune en tisse les toiles des yourtes. Rien ne se perd.", {"sujet_min": ["ile", 1]}),
					L("Autrefois, il y avait un grand festival sur la prairie, chaque été. Les deux villages jouaient ensemble. Depuis notre dispute, la Grande Scène attend. Elle s'ennuie, la pauvre.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("On raconte que Mantra a médité trois jours sans bouger, au bord de la mare. Une grenouille a fini par s'installer sur sa tête. Il ne s'en est pas aperçu.", {}, "rire"),
					L("Arc-en-Ciel joue du djembé même en dormant. Je le sais, j'habite à côté.", {}, "rire"),
				],
				"interpelle": [L("Toi, là ! Viens donc boire une tisane avec une vieille dame !", {"visites_max": 0}, "salut"), L("{surnom} ! Le soleil est beau aujourd'hui, non ?", {"visites_min": 1})],
			}},
		{"id": "arc_en_ciel", "nom": "Arc-en-Ciel", "titre": "joueur de djembé", "yourte": "fleurs_1", "maison": "porte_arc_en_ciel", "village": "larsen",
			"agenda": [[9, 12, ["djembe_1", "djembe_2"]], [12, 14, "feu_2"], [14, 18, ["arbre_rubans", "djembe_1", "pelouse_1"]], [18, 24, ["djembe_1", "djembe_2"]], [0, 9, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "dreads", "yeux": Y_BRUN, "haut": [0.9, 0.3, 0.6], "barbe": "courte", "taille": 1.02},
			"teinte": PEAU[4],
			"larsen": {"style": "hippie", "tenue": "tie_dye", "chapeau": "bandeau"},
			"punk": {"objet": ""},
			"humeur_base": 0.7, "traits": {"bavard": 0.6, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"baies": 2.0, "jus_pomme": 1.5, "gateau_miel": 2.0, "partition": 1.5}, "deteste": {},
			"tics": ["Boum, ba-da boum.", "Tout est rythme.", "Ressens le groove.", "Ba-da-boum !"],
			"repliques": {
				"accueil": [
					L("Hé ! Boum, ba-da boum ! Salut, toi ! Je suis Arc-en-Ciel. Je joue du djembé. Tout le temps. Même là, maintenant, je joue dans ma tête. Tu l'entends ?", {"visites_max": 1}, "salut"),
					L("{surnom} ! Ba-da-boum ! Tu viens taper avec moi ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Groovy ! Mon cœur bat à 120 battements par minute, comme un bon rythme de danse.", {}, "rire"),
					L("Le soir, c'est le meilleur moment : le feu, les étoiles, et les djembés qui se répondent. On joue jusqu'à ce que Mamie Tournesol dise « Au lit ! ».", {"soir": true}),
				],
				"lui": [
					L("Mon djembé s'appelle Tonnerre. C'est mon grand-père qui l'a fabriqué, avec un tronc d'arbre tombé pendant un orage. D'où le nom.", {}),
					L("Mes cheveux, ce sont des dreadlocks. Chaque mèche a une histoire. Celle-là, c'est l'été où j'ai appris à jouer. Celle-là, c'est la fois où une mouette a essayé d'y faire son nid.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [L("Le cercle des tambours, au milieu du camp, c'est le cœur du village. Si tu tapes sur un djembé, quelqu'un te répondra. Toujours. C'est la règle.", {})],
				"rumeur": [L("Bourrasque, la batteuse de Rainville, vient parfois écouter nos djembés, cachée derrière un bus. Je fais semblant de ne pas la voir. Je crois qu'elle voudrait jouer avec nous.", {})],
				"interpelle": [L("Psst ! Boum, ba-da boum ! Tu as le rythme, toi ?", {})],
			}},
		{"id": "lune", "nom": "Lune", "titre": "tisserande du Camp des Fleurs", "yourte": "fleurs_2", "maison": "porte_lune", "village": "larsen",
			"agenda": [[9, 12, "tissage"], [12, 14, "feu_3"], [14, 17, ["corderie_2", "tissage"]], [17, 20, ["mare_2", "camp_2"]], [20, 23, "feu_3"], [23, 9, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "boucles", "yeux": Y_VERT, "haut": [0.85, 0.82, 0.72], "robe": [0.55, 0.4, 0.65], "robe_longue": true},
			"teinte": PEAU[0],
			"larsen": {"style": "hippie", "tenue": "robe_longue", "couronne": "marguerites"},
			"punk": {"objet": "aiguilles"},
			"humeur_base": 0.45, "traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"corde_chanvre": 2.0, "tisane_lune": 2.0, "plume_ara": 1.5, "pain_miel": 1.0}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Un fil après l'autre.", "Tout se tisse.", "Mmh…", "Doucement."],
			"repliques": {
				"accueil": [
					L("Oh, bonjour… Je suis Lune. Je tisse les toiles du camp : les murs des yourtes, les tapis, les sacs. Avec le chanvre de Galet. Tu veux voir mon métier à tisser ? Il chante un peu quand il travaille.", {"visites_max": 1}, "salut"),
					L("Bonjour, {surnom}. Tu reviens voir la toile ? Elle a poussé de trois rangs depuis ta dernière visite.", {"visites_min": 2}),
				],
				"humeur": [L("Paisible. Le métier fait tic-tac, la navette passe, et les heures filent avec le fil.", {}), L("J'ai un nœud dans ma toile. Et un petit nœud dans le cœur aussi. Ça passera.", {})],
				"lui": [
					L("Le chanvre, c'est une plante magnifique : on en fait des cordes très solides, des toiles qui durent cent ans, du papier… Ses graines, les oiseaux les adorent. Rien ne se perd.", {}),
					L("La couronne de marguerites, c'est Bouton-d'Or qui me la tresse chaque matin. Elle dit que les fleurs fanent moins vite sur la tête des gens gentils.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [L("Toutes les toiles des yourtes, ici, je les ai tissées, ou ma mère, ou la mère de ma mère. Même à Rainville : leurs toiles sombres, c'est nous qui les avons faites. Ils ne le disent pas, mais ils le savent.", {})],
				"rumeur": [L("Spleen, au Café Feedback, m'a commandé une écharpe « couleur pluie ». J'ai mis trois semaines à trouver la couleur de la pluie. C'est gris, mais un gris qui sourit.", {})],
				"interpelle": [L("Doucement… tu marches sur mon fil.", {})],
			}},
		{"id": "galet", "nom": "Galet", "titre": "cordier de la Corderie", "yourte": "fleurs_9", "maison": "porte_galet", "village": "larsen",
			"agenda": [[7, 12, ["corderie_1", "corderie_2"]], [12, 13, "feu_4"], [13, 18, ["corderie_1", "corderie_2"]], [18, 21, "feu_4"], [21, 7, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "queue", "barbe": "longue", "yeux": Y_GRIS, "haut": [0.75, 0.65, 0.45], "carrure": 1.2},
			"teinte": PEAU[2],
			"larsen": {"style": "hippie", "tenue": "poncho", "chapeau": "paille"},
			"punk": {"objet": ""},
			"humeur_base": 0.3, "traits": {"bavard": 0.2, "humour": 0.5, "curiosite": 0.3, "susceptible": 0.2, "rancunier": 0.2},
			"aime": {"pain_miel": 2.0, "the_menthe": 1.5, "jus_pomme": 1.5}, "deteste": {},
			"tics": ["Hm.", "Ça tient.", "Bien serré.", "Nœud de chaise."],
			"repliques": {
				"accueil": [
					L("… Galet. Je fais des cordes. (Il tire sur une corde.) Ça, c'est une bonne corde. Elle tiendrait un bateau. Ou une baleine. Ou une baleine dans un bateau.", {"visites_max": 1}, "salut"),
					L("Hm. {surnom}. Tu viens tordre une corde ?", {"visites_min": 2}),
				],
				"humeur": [L("Comme une corde bien tendue : solide.", {}), L("Le soir, je fais des nœuds pour les enfants. Des nœuds de marin. Ils me les défont. C'est un jeu.", {"soir": true})],
				"lui": [L("J'étais marin. J'ai fait le tour du monde trois fois. Puis j'ai trouvé une île où les gens chantaient le soir. Je suis descendu du bateau. Le bateau est reparti sans moi. Je ne l'ai pas regretté.", {})],
				"ile": [L("La Corderie, c'est au nord, au bord du champ de chanvre. Les tiges sèchent en meules, on les bat, on file, on tord. Des cordes pour tendre les yourtes, et pour la grande toile de la scène.", {})],
				"rumeur": [L("Jack, le chef roadie, m'a commandé cinq cents mètres de corde pour la scène. Cinq cents. Je lui ai demandé s'il voulait attacher l'île au continent.", {}, "rire")],
				"interpelle": [L("Hm. Attention aux cordes.", {})],
			}},
		{"id": "lavande", "nom": "Lavande", "titre": "jardinière et herboriste", "yourte": "fleurs_3", "maison": "porte_lavande", "village": "larsen",
			"agenda": [[8, 12, ["jardin_1", "jardin_2"]], [12, 14, "feu_5"], [14, 17, ["coquelicots_1", "jardin_1"]], [17, 20, ["camp_3", "mare_1"]], [20, 22, "feu_5"], [22, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "long", "yeux": Y_VERT, "haut": [0.6, 0.45, 0.75], "robe": [0.4, 0.55, 0.35]},
			"teinte": PEAU[6],
			"larsen": {"style": "hippie", "tenue": "salopette_fleurs", "chapeau": "capeline"},
			"punk": {"objet": "arrosoir"},
			"humeur_base": 0.6, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"miel": 2.0, "baies": 1.5, "tisane_lune": 2.0, "bouquet_tournesols": 2.0}, "deteste": {},
			"tics": ["Ça sent bon !", "Les plantes écoutent.", "Arrose, arrose…", "Fleurir, c'est tout un art."],
			"repliques": {
				"accueil": [
					L("Bonjour ! Fais attention où tu marches, il y a des radis qui dorment. Je suis Lavande, je m'occupe des jardins du camp : tournesols, tomates, menthe, camomille… et des tisanes pour tout le monde.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu sens comme la menthe, aujourd'hui. Tu es passé par le jardin ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Épanouie ! Mes tournesols ont encore grandi. Ils me dépassent. Ils me regardent de haut, mais gentiment.", {}, "rire")],
				"lui": [L("Je parle à mes plantes. Elles ne répondent pas avec des mots, mais avec des fleurs. C'est une conversation très lente et très jolie.", {})],
				"ile": [L("Les champs de coquelicots, au sud-est, personne ne les a plantés. Ils sont venus tout seuls, avec le vent. Les abeilles adorent ça, et le miel du camp a un goût de coquelicot.", {})],
				"rumeur": [L("Mère Averse cultive des escargots, dans son jardin de Rainville. Enfin, elle ne les cultive pas : ils viennent tout seuls, avec la pluie. Elle leur a donné des noms.", {}, "rire")],
				"interpelle": [L("Hé ! Tu veux sentir la menthe ?", {})],
			}},
		{"id": "mantra", "nom": "Mantra", "titre": "le sage de la mare", "yourte": "hameau_1", "maison": "porte_mantra", "village": "larsen",
			"agenda": [[6, 11, ["mare_1", "mare_2"]], [11, 13, "feu_6"], [13, 18, ["mare_1", "colline_banc"]], [18, 21, ["mare_2", "feu_6"]], [21, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BRUN, "haut": [0.95, 0.6, 0.15], "lunettes": true, "carrure": 0.9},
			"teinte": PEAU[3],
			"larsen": {"style": "hippie", "tenue": "tunique"},
			"punk": {"objet": ""},
			"humeur_base": 0.8, "traits": {"bavard": 0.3, "humour": 0.95, "curiosite": 0.4, "susceptible": 0.0, "rancunier": 0.0},
			"aime": {"tisane_lune": 2.0, "the_menthe": 2.0, "baies": 1.0}, "deteste": {},
			"tics": ["Ommm…", "Hi hi hi.", "Respire.", "La grenouille sait."],
			"repliques": {
				"accueil": [
					L("Ommm… (Il ouvre un œil.) Oh ! Un visiteur. Bienvenue. Je suis Mantra. Je médite. Enfin, j'essaie. Il y a une grenouille qui me regarde, et ça me fait rire. Hi hi hi. Ommm…", {"visites_max": 1}, "rire"),
					L("{surnom}. Respire. Voilà. Tu es arrivé. Hi hi.", {"visites_min": 2}),
				],
				"humeur": [L("Calme comme l'eau de la mare. Sauf quand la grenouille saute. Alors je ris. Hi hi hi.", {}, "rire")],
				"lui": [L("J'ai passé dix ans à chercher la sagesse dans les montagnes. Je l'ai trouvée ici, au bord d'une mare, en regardant une grenouille attraper une mouche. Elle ne se presse jamais. Elle attend. Et hop.", {})],
				"ile": [L("La Mare aux Mantras porte mon nom, mais c'est la mare qui m'a donné le mien. Avant, je m'appelais Bernard.", {}, "rire")],
				"rumeur": [L("Grésil, le guitariste de Rainville, vient parfois méditer avec moi. Il est très doué : il ne bouge pas, il ne parle pas. En fait, je crois qu'il dort.", {}, "rire")],
				"interpelle": [L("Psst… Respire. Hi hi.", {})],
			}},
		{"id": "bigoudi", "nom": "Bigoudi", "titre": "mécanicienne des bus peints", "yourte": "fleurs_8", "maison": "porte_bigoudi", "village": "larsen",
			"agenda": [[9, 12, ["bus_1", "bus_2"]], [12, 14, "djembe_3"], [14, 18, ["bus_2", "bus_3"]], [18, 21, ["camp_1", "feu_2"]], [21, 9, "maison"]],
			"azur": {"cheveux": [0.92, 0.45, 0.6], "coiffure": "chignon", "yeux": Y_NOISETTE, "haut": [0.85, 0.82, 0.75], "carrure": 1.05},
			"teinte": PEAU[2],
			"larsen": {"style": "hippie", "tenue": "salopette_fleurs", "chapeau": "bandeau"},
			"punk": {"objet": "cle_molette"},
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"limonade_boucan": 2.0, "jus_pomme": 1.5, "gateau_miel": 1.5}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Vroum !", "Ça roule !", "Une petite vis, et hop.", "Bichonné !"],
			"repliques": {
				"accueil": [
					L("Salut ! Attention, peinture fraîche ! Moi, c'est Bigoudi. Je répare les bus du camp et je les peins. Des fleurs, des soleils, des vagues… Le bleu, là, il est à peine sec.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens m'aider à peindre une marguerite ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Graissée et heureuse ! J'ai réparé le klaxon du bus orange. Il fait « Pouêt-pouêt » maintenant. Avant, il faisait « Prrrt ». C'était gênant.", {}, "rire")],
				"lui": [L("Ces bus, c'étaient de vieux bus d'école tout jaunes, abandonnés. Je les ai réparés un par un. Maintenant, on dort dedans quand il y a trop de monde pour le festival. Enfin… quand il y avait le festival.", {})],
				"ile": [L("Les bus ne roulent plus beaucoup : l'île est trop petite. Mais une fois par an, on fait le tour de l'île en klaxonnant. Ça prend dix minutes. Avec les pauses pique-nique, une journée.", {}, "rire")],
				"rumeur": [L("Clapotis, le petit de Rainville, vient faire du skate sur la rampe à côté de mes bus. Il est très fort. Il tombe très fort aussi.", {})],
				"interpelle": [L("Hé ! Tu n'aurais pas une clé de douze ?", {})],
			}},
		{"id": "bouton_dor", "nom": "Bouton-d'Or", "titre": "enfant du Camp des Fleurs (8 ans)", "yourte": "fleurs_4", "maison": "porte_bouton_dor", "village": "larsen",
			"agenda": [[9, 12, ["arbre_rubans", "jardin_1"], ["camp_2", "arbre_rubans"]], [12, 14, "djembe_2"], [14, 18, ["arbre_rubans", "coquelicots_1", "plage_1"], ["arbre_rubans", "camp_1"]], [18, 20, ["feu_5", "feu_3", "djembe_3"]], [20, 9, "maison"]],
			"azur": {"cheveux": BLOND_BLANC, "coiffure": "tresse", "yeux": Y_BLEU, "haut": [0.98, 0.85, 0.3], "taille": 0.74, "robe": [0.95, 0.6, 0.7]},
			"teinte": PEAU[0],
			"larsen": {"style": "hippie", "tenue": "enfant", "couronne": "coquelicots"},
			"punk": {"objet": ""},
			"humeur_base": 0.8, "traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.5, "rancunier": 0.0},
			"aime": {"gateau_miel": 2.5, "baies": 2.0, "pomme": 1.5, "coquillage": 2.0}, "deteste": {"champignon": -1.0},
			"tics": ["Hihi !", "Tu savais que… ?", "C'est MOI qui l'ai fait !", "Encore !"],
			"surnoms": [[0, "toi"], [25, "mon copain"], [50, "mon meilleur copain"], [75, "mon super copain"], [95, "mon héros"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Je m'appelle Bouton-d'Or, j'ai huit ans et demi, et c'est moi qui fais les couronnes de fleurs de tout le camp ! Tu veux danser autour de l'arbre à rubans ? On tourne, on tourne, et après on tombe ! Hihi !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu reviens ! Tu as vu ? J'ai une nouvelle couronne ! En coquelicots !", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Super contente ! J'ai trouvé une coccinelle à sept points. Je l'ai appelée Septembre.", {}, "rire")],
				"lui": [L("Quand je serai grande, je serai musicienne, et jardinière, et capitaine de bus, et aussi grenouille. Mantra dit que c'est possible si je respire bien.", {}, "rire")],
				"ile": [L("Il y a un garçon à Rainville qui s'appelle Clapotis. Il fait du skate et il a un ciré jaune. Je crois qu'il est gentil, mais on n'a pas le droit de jouer ensemble à cause de la dispute des mamies. C'est nul, les disputes de mamies.", {})],
				"rumeur": [L("Chut, c'est un secret : Mamie Tournesol garde une photo de Mère Averse dans sa boîte à bijoux. Je l'ai vue. Elles se tiennent par la main et elles rigolent.", {})],
				"interpelle": [L("Hé ! Tu veux voir ma couronne ?", {}, "salut")],
			}},
		# ================================================================ Rainville
		{"id": "mere_averse", "nom": "Mère Averse", "titre": "doyenne de Rainville, fabricante de parapluies", "yourte": "rain_0", "maison": "porte_mere_averse", "village": "larsen",
			"agenda": [[8, 12, ["rue_1", "cafe_terrasse_1"]], [12, 14, "cafe_terrasse_1"], [14, 18, ["rue_2", "canape_1"]], [18, 21, "cafe_terrasse_2"], [21, 8, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chignon", "yeux": Y_GRIS, "haut": [0.2, 0.28, 0.35], "vieux": true, "carrure": 0.9, "lunettes": true},
			"teinte": PEAU[1],
			"larsen": {"style": "grunge", "tenue": "impermeable", "chapeau": "bonnet"},
			"punk": {"objet": "aiguilles"},
			"humeur_base": 0.0, "traits": {"bavard": 0.5, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.7},
			"aime": {"parapluie_rainville": 1.5, "cafe_vapeur": 2.0, "the_menthe": 1.5, "bouquet_tournesols": 2.5}, "deteste": {},
			"tics": ["Il va pleuvoir.", "Tss.", "De mon temps…", "La pluie, c'est la vie."],
			"surnoms": [[0, "le mouillé"], [25, "mon petit"], [50, "ma goutte"], [75, "mon averse"], [95, "enfant de Rainville"]],
			"repliques": {
				"accueil": [
					L("Hm. Un étranger. Tu es tout sec, ça se voit. Ici, à Rainville, il pleut tous les jours, et c'est très bien comme ça. Je suis Mère Averse. Je fabrique les parapluies du quartier. Tous troués, exprès : un parapluie sans trou, ce n'est pas honnête avec la pluie.", {"visites_max": 1}),
					L("Tiens, {surnom}. Tu as pris un peu de pluie. Ça te va bien.", {"visites_min": 2}),
					L("Mon messager ! Entre, entre. Tu sais quoi ? Hier, j'ai pris un thé au soleil. Au SOLEIL. Avec Tournesol. Je ne l'avais pas fait depuis cinquante ans.", {"q56": "la_soleil_pluie=finie"}, "rire"),
				],
				"humeur": [
					L("Grise et contente, comme le ciel de Rainville.", {}),
					L("Tu veux savoir ? Là-bas, au Camp des Fleurs, il y a une vieille bique qui plante des tournesols. Avant, c'était ma meilleure amie. Ne me parle pas d'elle. … Comment va-t-elle ?", {"q56": "la_soleil_pluie="}),
				],
				"lui": [
					L("Le petit nuage au-dessus de Rainville ? C'est le mien. Il m'a suivie depuis le continent, quand j'étais toute jeune. Je l'ai gardé. On ne laisse pas un nuage tout seul.", {}),
					L("Les jeunes de Rainville, ils font de la musique très fort, avec des guitares qui grincent. Ils croient que je n'aime pas ça. J'adore ça. Je tricote en rythme.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [L("Rainville, c'est le quartier des gens qui aiment la pluie, les grosses chemises à carreaux et le café chaud. On a l'air tristes, mais c'est juste qu'on réfléchit beaucoup.", {})],
				"rumeur": [L("On dit que Spleen, au café, n'a jamais souri. C'est faux. Il a souri une fois, en 1994. Il y avait une flaque en forme de cœur.", {}, "rire")],
				"interpelle": [L("Toi, le tout sec ! Viens donc là.", {})],
			}},
		{"id": "flanelle", "nom": "Flanelle", "titre": "chanteuse des Gouttières", "yourte": "rain_1", "maison": "porte_flanelle", "village": "larsen",
			"agenda": [[11, 14, ["rue_3", "canape_2"]], [14, 17, ["rue_3", "canape_2"]], [17, 22, "garage_chant"], [22, 24, "cafe_terrasse_3"], [0, 11, "maison"]],
			"azur": {"cheveux": DELAVE, "coiffure": "long", "yeux": Y_BLEU, "haut": [0.6, 0.12, 0.1]},
			"teinte": PEAU[1],
			"larsen": {"style": "grunge", "tenue": "flanelle", "chapeau": "bonnet"},
			"punk": {"objet": "micro"},
			"humeur_base": 0.2, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"cafe_vapeur": 2.0, "affiche_concert": 2.0, "partition": 2.0, "sirop_menthe": 1.0}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Ouais.", "C'est intense.", "Mmh, carrément.", "Ça me parle."],
			"repliques": {
				"accueil": [
					L("Salut. Je suis Flanelle. Je chante dans les Gouttières, le groupe du garage. On joue fort et on chante des chansons tristes qui rendent heureux. C'est compliqué à expliquer. Viens écouter, tu comprendras.", {"visites_max": 1}, "salut"),
					L("Hé, {surnom}. Tu viens à la répète ce soir ? On a une nouvelle chanson. Elle parle d'une flaque.", {"visites_min": 2}),
				],
				"humeur": [L("Mélancolique et bien. C'est mon état préféré.", {}), L("La répète, c'est ma séance de cri de la journée. Après, je suis calme comme un parapluie fermé.", {"soir": true})],
				"lui": [L("Ma chemise à carreaux, c'était celle de mon père. Elle est trop grande, elle a des trous aux coudes, et je ne la quitterai jamais.", {})],
				"ile": [L("Les Gouttières, c'est Grésil à la guitare, Bruine à la basse, Bourrasque à la batterie, et moi. On répète dans le garage rouge. Les murs sont en tôle, ça résonne : on a l'impression d'être quatre cents.", {})],
				"rumeur": [L("Il paraît qu'autrefois, les Gouttières jouaient sur la Grande Scène, avec les musiciens du Camp des Fleurs. Ma mère y était. Elle dit que c'était le plus beau concert du monde.", {})],
				"interpelle": [L("Psst. Tu aimes les guitares qui grincent ?", {})],
			}},
		{"id": "gresil", "nom": "Grésil", "titre": "guitariste des Gouttières", "yourte": "rain_2", "maison": "porte_gresil", "village": "larsen",
			"agenda": [[12, 16, ["canape_1", "canape_3"]], [16, 17, "mare_2"], [17, 22, "garage_guitare"], [22, 24, "canape_3"], [0, 12, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "long", "yeux": Y_GRIS, "haut": [0.25, 0.32, 0.22], "barbe": "courte", "taille": 1.08, "carrure": 0.8},
			"teinte": PEAU[0],
			"larsen": {"style": "grunge", "tenue": "cardigan"},
			"punk": {"objet": "guitare"},
			"humeur_base": 0.1, "traits": {"bavard": 0.05, "humour": 0.6, "curiosite": 0.2, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"cafe_vapeur": 2.5, "partition": 1.5, "pomme": 1.0}, "deteste": {},
			"tics": ["… Ouais.", "… Cool.", "… (Il hoche la tête.)", "… Mmmh."],
			"surnoms": [[0, "… toi"], [25, "… mec"], [50, "… pote"], [75, "… frangin"], [95, "… frangin pour la vie"]],
			"repliques": {
				"accueil": [
					L("… Salut. … Grésil. … Guitare. … (Un long silence.) … C'était bien, ce silence. … Hein ?", {"visites_max": 1}, "salut"),
					L("… {surnom}. … Ça va. … Moi aussi.", {"visites_min": 2}),
				],
				"humeur": [L("… Bien. … Je crois. … Oui.", {}), L("… Le soir, la guitare parle à ma place. … Elle est plus bavarde que moi.", {"soir": true})],
				"lui": [L("… Je parle lentement. … Mais je joue vite. … Très vite. … C'est équilibré.", {}, "rire")],
				"ile": [L("… Le larsen. … Le sifflement de l'ampli, quand la guitare est trop près. … Tout le monde déteste. … Moi, j'adore. … C'est le chant de l'île.", {})],
				"rumeur": [L("… Mantra. … Il médite. … Moi aussi. … Enfin. … Je dors. … Chut.", {}, "rire")],
				"interpelle": [L("… Hé.", {})],
			}},
		{"id": "bruine", "nom": "Bruine", "titre": "bassiste des Gouttières", "yourte": "rain_6", "maison": "porte_bruine", "village": "larsen",
			"agenda": [[10, 13, ["disquaire_1", "disquaire_2"]], [13, 17, ["rue_4", "cafe_terrasse_3"]], [17, 22, "garage_basse"], [22, 10, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": Y_BRUN, "haut": [0.1, 0.1, 0.12], "taille": 0.95},
			"teinte": PEAU[3],
			"larsen": {"style": "grunge", "tenue": "robe_grunge"},
			"punk": {"objet": "basse"},
			"humeur_base": 0.2, "traits": {"bavard": 0.15, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.7, "rancunier": 0.1},
			"aime": {"fanzine": 2.0, "sirop_menthe": 1.5, "gateau_lune": 2.0}, "deteste": {},
			"tics": ["Euh…", "Pardon.", "C'est… oui.", "(Elle rougit.)"],
			"repliques": {
				"accueil": [
					L("Oh ! Euh… bonjour. Pardon. Je… je m'appelle Bruine. Je joue de la basse. C'est l'instrument qu'on entend sans l'entendre. Comme moi.", {"visites_max": 1}),
					L("Oh, {surnom}… (Elle sourit, un tout petit peu.) Bonjour.", {"visites_min": 2}),
				],
				"humeur": [L("Ça va… Merci de demander. Personne ne demande jamais à la bassiste.", {})],
				"lui": [L("Sur scène, je ne regarde jamais le public. Je regarde mes chaussures. Mes chaussures connaissent toutes nos chansons par cœur.", {})],
				"ile": [L("Chez Vinyle, il y a un disque des Gouttières d'il y a vingt ans, avec la chanteuse du Camp des Fleurs… Les deux villages ensemble, sur le même disque. C'est mon disque préféré.", {})],
				"rumeur": [L("Euh… Bouton-d'Or et Clapotis se font des signes, le soir, avec des lampes de poche. D'un bout de l'île à l'autre. Je trouve ça… très joli.", {})],
				"interpelle": [L("Oh… bonjour.", {})],
			}},
		{"id": "bourrasque", "nom": "Bourrasque", "titre": "batteuse des Gouttières", "yourte": "rain_5", "maison": "porte_bourrasque", "village": "larsen",
			"agenda": [[9, 12, ["rue_2", "bus_3"]], [12, 14, "cafe_terrasse_3"], [14, 17, ["rampe", "bus_3", "rue_1"]], [17, 22, "garage_batterie"], [22, 9, "maison"]],
			"azur": {"cheveux": [0.55, 0.15, 0.4], "coiffure": "queue", "yeux": Y_VERT, "haut": [0.85, 0.82, 0.78], "carrure": 1.1},
			"teinte": PEAU[2],
			"larsen": {"style": "grunge", "tenue": "salopette_grunge", "chapeau": "casquette"},
			"punk": {"objet": "baguettes"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.85, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"limonade_boucan": 2.0, "gateau_miel": 2.0, "patch_rat": 2.0}, "deteste": {},
			"tics": ["BOUM !", "Tchak !", "Un, deux, trois, quatre !", "Pas assez fort !"],
			"repliques": {
				"accueil": [
					L("SALUT ! Moi, c'est Bourrasque, batteuse des Gouttières ! Je tape FORT ! Pas sur les gens, hein, sur les fûts ! Tu veux entendre un roulement ? TRRRRRRRA-BOUM !", {"visites_max": 1}, "rire"),
					L("{surnom} ! TCHAK ! Ça va ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("À fond ! J'ai cassé deux baguettes ce matin. Juste en les regardant.", {}, "rire")],
				"lui": [L("Un secret ? J'adore les djembés du Camp des Fleurs. Je vais les écouter, cachée derrière un bus. Arc-en-Ciel joue vraiment bien. Ne lui dis pas. Il prendrait la grosse tête. Une grosse tête à dreadlocks.", {})],
				"ile": [L("Si un jour la Grande Scène se rallume, je veux jouer avec tous les tambours du camp en même temps ! Imagine : TRRRRA-BOUM-BA-DA-BOUM ! Les mouettes en tomberaient du ciel !", {})],
				"rumeur": [L("Grésil s'est endormi pendant un solo, hier. Il a continué à jouer. Le meilleur solo de sa vie.", {}, "rire")],
				"interpelle": [L("HÉ ! Toi ! TCHAK !", {}, "salut")],
			}},
		{"id": "spleen", "nom": "Spleen", "titre": "patron du Café Feedback", "yourte": "cafe", "maison": "porte_spleen", "village": "larsen",
			"agenda": [[8, 22, "cafe_comptoir"], [22, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.18, 0.18, 0.2], "tablier": [0.12, 0.1, 0.09], "carrure": 1.15},
			"teinte": PEAU[4],
			"larsen": {"style": "grunge", "tenue": "tablier_cafe", "chapeau": "bonnet"},
			"punk": {"objet": ""},
			"humeur_base": -0.1, "traits": {"bavard": 0.4, "humour": 0.9, "curiosite": 0.3, "susceptible": 0.2, "rancunier": 0.2},
			"aime": {"cafe_vapeur": 2.0, "gateau_lune": 1.5, "fanzine": 1.0}, "deteste": {},
			"tics": ["La vie est une tasse.", "Bof.", "Encore un café ?", "Tout finit en flaque."],
			"repliques": {
				"accueil": [
					L("Bienvenue au Café Feedback. Le seul café au monde où il pleut dedans. Un peu. Par le toit. Je suis Spleen. Je sers du chocolat chaud, du café et de la tisane. Et de la mélancolie, gratuite.", {"visites_max": 1}),
					L("{surnom}. Ta tasse t'attend. Elle est triste sans toi. Moi aussi, un peu.", {"visites_min": 2}),
				],
				"humeur": [L("Comme d'habitude : nuageux avec des éclaircies. Surtout des nuages.", {}), L("J'ai souri ce matin. Personne ne l'a vu. C'est mieux comme ça.", {})],
				"lui": [L("Le Café Feedback, je l'ai ouvert dans la plus grande yourte de Rainville. Il y a un juke-box qui ne joue qu'une chanson, un chat qui dort sur l'ampli, et une fuite au-dessus de la table trois. Les habitués se battent pour la table trois.", {})],
				"ile": [L("Ici, on aime la pluie parce qu'elle fait rentrer tout le monde au café. Les gens se serrent, ils parlent, ils rient. La pluie, c'est un bon prétexte pour être ensemble.", {})],
				"rumeur": [L("Vinyle, le disquaire, cache un disque très rare dans son arrière-boutique. Un disque où les deux villages chantent ensemble. Il ne le fait écouter qu'aux gens qui pleurent. Je l'ai entendu trois fois.", {})],
				"interpelle": [L("Un chocolat chaud ? Ça soigne tout. Sauf la pluie.", {})],
			}},
		{"id": "vinyle", "nom": "Vinyle", "titre": "disquaire de Rainville", "yourte": "disquaire", "maison": "porte_vinyle", "village": "larsen",
			"agenda": [[10, 19, ["disquaire_1", "disquaire_2"]], [19, 22, "cafe_terrasse_3"], [22, 10, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "queue", "barbe": "courte", "yeux": Y_GRIS, "haut": [0.3, 0.25, 0.2], "lunettes": true},
			"teinte": PEAU[1],
			"larsen": {"style": "grunge", "tenue": "cardigan"},
			"punk": {"objet": "livre"},
			"humeur_base": 0.3, "traits": {"bavard": 0.8, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"partition": 2.5, "affiche_concert": 2.0, "fanzine": 1.5}, "deteste": {},
			"tics": ["Face A, face B.", "Écoute ce son…", "Édition originale !", "Ça craque, c'est vivant."],
			"repliques": {
				"accueil": [
					L("Entre, entre ! Je suis Vinyle, le disquaire. Ici, il y a tous les disques de l'île : les Gouttières, les chansons du Camp des Fleurs, les vieux concerts du Festival du Larsen… Tu entends ce petit craquement ? C'est la musique qui respire.", {"visites_max": 1}, "salut"),
					L("{surnom} ! J'ai reçu un nouveau vieux disque. Enfin, un vieux disque nouveau. Tu vois ce que je veux dire.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("En 33 tours : tranquille, ça tourne.", {})],
				"lui": [L("J'ai six mille disques. Je les ai tous écoutés. Deux fois. Sauf un, que je garde pour le jour où les deux villages joueront de nouveau ensemble.", {})],
				"ile": [L("Le Festival du Larsen, c'était chaque été. Tout le monde venait. Et puis Mère Averse et Mamie Tournesol se sont disputées, et plus personne n'a osé monter sur scène. Une scène sans musique, c'est comme un disque sans sillon.", {})],
				"rumeur": [L("Jack, le roadie, répare la Grande Scène en cachette. Tous les jours. Il dit que « ça ne coûte rien d'être prêt ».", {})],
				"interpelle": [L("Tu veux écouter un disque ?", {})],
			}},
		{"id": "clapotis", "nom": "Clapotis", "titre": "enfant de Rainville (10 ans), skateur", "yourte": "rain_9", "maison": "porte_clapotis", "village": "larsen",
			"agenda": [[9, 12, "rampe"], [12, 14, "cafe_terrasse_2"], [14, 19, ["rampe", "rue_4", "plage_2"], ["rampe", "rue_3"]], [19, 21, "garage_public"], [21, 9, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "yeux": Y_VERT, "haut": [0.95, 0.82, 0.1], "taille": 0.78},
			"teinte": PEAU[6],
			"larsen": {"style": "grunge", "tenue": "enfant", "chapeau": "casque_skate"},
			"punk": {"objet": "skate"},
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.9, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"limonade_boucan": 2.0, "gateau_miel": 2.0, "pomme": 1.0, "coquillage": 1.5}, "deteste": {"champignon": -0.5},
			"tics": ["Trop stylé !", "Regarde !", "Ouille.", "Je l'ai presque eu !"],
			"surnoms": [[0, "toi"], [25, "mec"], [50, "mon pote"], [75, "mon super pote"], [95, "le roi du skate"]],
			"repliques": {
				"accueil": [
					L("Salut ! Je suis Clapotis ! Regarde ma figure ! (Il saute, tombe, se relève.) … Je l'ai presque eue ! Mon ciré jaune, c'est pour qu'on me voie dans la pluie. Et quand je tombe dans une flaque.", {"visites_max": 1}, "rire"),
					L("{surnom} ! T'as vu, j'ai réussi un ollie ! Enfin, à moitié.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Trop bien ! Il pleut, donc la rampe glisse, donc je vais plus vite !", {}, "rire")],
				"lui": [L("Je m'appelle Clapotis parce que, bébé, je sautais dans toutes les flaques. Maintenant, je saute avec un skate. C'est plus dur.", {}, "rire")],
				"ile": [L("Au Camp des Fleurs, il y a une fille qui s'appelle Bouton-d'Or. Elle fait des couronnes de fleurs. On se fait des signes avec des lampes, le soir. Mais on n'a pas le droit de jouer ensemble, à cause des mamies. C'est vraiment nul.", {})],
				"rumeur": [L("Bourrasque m'a dit qu'avant, il y avait un énorme concert sur la prairie. Avec des feux d'artifice. Moi, j'en ai jamais vu, des feux d'artifice.", {})],
				"interpelle": [L("Hé ! Regarde ma figure !", {}, "salut")],
			}},
		# ================================================================ le Hameau des Roadies
		{"id": "jack", "nom": "Jack", "titre": "chef roadie de la Grande Scène", "yourte": "roadies_1", "maison": "porte_jack", "village": "larsen",
			"agenda": [[8, 12, ["scene_1", "scene_2"]], [12, 13, "roadies_1"], [13, 19, ["scene_1", "scene_3", "regie"]], [19, 22, ["roadies_1", "scene_1"]], [22, 8, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.1, 0.1, 0.1], "carrure": 1.25},
			"teinte": PEAU[3],
			"larsen": {"style": "grunge", "tenue": "roadie", "chapeau": "casquette"},
			"punk": {"objet": "cle_molette"},
			"humeur_base": 0.4, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"cafe_vapeur": 2.0, "corde_chanvre": 2.0, "limonade_boucan": 1.5}, "deteste": {},
			"tics": ["Câble !", "Ça tient ?", "Un, deux, un, deux.", "Prêt dans cinq minutes."],
			"repliques": {
				"accueil": [
					L("Salut ! Jack, chef roadie. Je monte les scènes, je tire les câbles, je porte les amplis. Celle-là, la Grande Scène, je la répare tous les jours. Au cas où. Une scène, ça doit toujours être prête.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens m'aider à porter un ampli ? Je plaisante. Quoique.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Prêt ! Comme toujours. Il ne manque plus que des musiciens. Et un public. Et une réconciliation.", {})],
				"lui": [L("Mon hameau, derrière la scène, c'est celui des roadies. On vient des deux villages : on a un pied dans les fleurs et l'autre dans les flaques. Nous, on ne s'est jamais disputés : on était trop occupés à porter des trucs lourds.", {}, "rire")],
				"ile": [L("La Grande Scène : vingt-deux mètres de large, des tours en treillis, des projecteurs, des murs d'enceintes. Il lui manque la toile du fond, que Lune doit tisser, et les cordes de Galet. Et puis il faudra un festival.", {})],
				"rumeur": [L("Mégaphone teste les micros tous les matins. « Un, deux, un, deux. » Depuis dix ans. Elle dit qu'un jour, quelqu'un répondra « trois ».", {}, "rire")],
				"interpelle": [L("Attention, câble !", {})],
			}},
		{"id": "megaphone", "nom": "Mégaphone", "titre": "ingénieure du son, à la régie", "yourte": "roadies_6", "maison": "porte_megaphone", "village": "larsen",
			"agenda": [[9, 13, "regie"], [13, 14, "roadies_2"], [14, 19, ["regie", "scene_2"]], [19, 21, "roadies_2"], [21, 9, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "queue", "yeux": Y_BLEU, "haut": [0.22, 0.25, 0.3], "lunettes": true},
			"teinte": PEAU[0],
			"larsen": {"style": "grunge", "tenue": "roadie"},
			"punk": {"objet": "casque_audio"},
			"humeur_base": 0.4, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"partition": 1.5, "sirop_menthe": 1.5, "gateau_lune": 1.5}, "deteste": {},
			"tics": ["Un, deux…", "Plus de basses !", "Ça sature.", "Chut, j'écoute."],
			"repliques": {
				"accueil": [
					L("Un, deux, un, deux… Oh ! Salut. Mégaphone, ingénieure du son. Je règle la console de la régie. Tu entends ? Non ? Normal : il n'y a personne sur scène. Mais le jour où il y aura quelqu'un, le son sera parfait.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Dis « trois ». Allez, dis « trois ».", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("En réglage. Comme toujours.", {})],
				"lui": [L("Le larsen, c'est mon pire ennemi et mon meilleur ami. Quand ça siffle, c'est que le micro entend l'enceinte qui l'entend… Une boucle infinie. Comme deux vieilles dames qui ne se parlent plus et qui pensent l'une à l'autre tout le temps.", {})],
				"ile": [L("L'île porte le nom d'un sifflement. C'est pour ça qu'ici, tout le monde a un peu de musique dans les oreilles.", {})],
				"rumeur": [L("Grésil s'endort sur ses amplis. Il ronfle en la mineur. Je l'ai enregistré.", {}, "rire")],
				"interpelle": [L("Un, deux… Tu m'entends ?", {})],
			}},
	]

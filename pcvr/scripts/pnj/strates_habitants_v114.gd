extends RefCounted
## V114 : les gens des Strates, la ville creusée dans la roche, cent mètres sous la Place de la
## Colonne de Hautefond : une grande caverne de grès en couches (ocre, crème, rouille, gris), éclairée
## par le Soleil de Laiton (la grande sphère armillaire qui entoure la Colonne Renversée, une lampe à
## arc au cœur : forte le jour, ambrée la nuit). La Ligne des Strates (la cabine dorée du pavillon de
## la Place de la Colonne, puis la cabine de la Colonne Renversée jusqu'à la Gare des Strates) vient de
## rouvrir, après dix ans de travaux.
##  - la Gare des Strates : Anatole Crémaillère, le liftier de la Ligne (vieil ami de Maîtresse
##    Capucine, la Grande Liftière d'en haut ; il garde la grille de la Ligne du Dôme d'Azur) ;
##  - la Grande Forge des Strates : Maîtresse Brunehaut Enclume (celle qui répond aux coups de
##    Mathilde Soufflet depuis vingt ans) et Tom Taraud, son apprenti (11 ans, qui parle en code à
##    Pimprenelle à travers la roche) ;
##  - les Mines de Cristaux : Ludovic Grisou, le contremaître (qui parle à la roche, « la Vieille ») ;
##  - l'Atelier des Lumières : la Docteure Opaline Quartz, cristallière (le cristal bleu des bijoux
##    d'Ysaé, c'est elle) ;
##  - les Jardins des Champignons : Bertille Champignac (la cascade lui dit le temps qu'il fait en haut) ;
##  - la Place des Rouages : Honorine Lanterne (La Marmite, la cantine, sans une goutte d'alcool) et
##    Papy Ferdinand Vapeur (le Petit Train et sa locomotive Bernadette ; il a vendu à Firmin la
##    chaudière qui fait le chocolat du Piston Joyeux) ;
##  - la Maison de la Guilde : la Doyenne Agathe Basalte (qui « surveille la Fronde de loin, avec fierté »).
## La Fronde (de l'autre côté du Pont des Frondeurs) a ses propres habitants (fichier à part) ; ici, on
## les cite seulement (Rivet et Bielle, Brasero, Gamelle, Fusain, Ressort…). La Ligne du Dôme d'Azur,
## qui part de la Gare des Strates (la grille d'Anatole, la cage de laiton, puis le Funiculaire d'Azur),
## a rouvert à son tour (V115), après douze ans de travaux.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd), même costume que Hautefond et Montjoie (fiche « mj », pnj_montjoie_v71.gd ; voir
## l'en-tête de hautefond_habitants_v112.gd pour les tenues, objets et chapeaux). Les liftiers portent la
## casquette à galon (fiche « azur »). Fiche « village » : strates. Points de rendez-vous : « st_… ».
## Identifiants : ces prénoms existent déjà ailleurs dans l'archipel, alors on suffixe « _st » :
## brunehaut_st, tom_st, honorine_st, ferdinand_st, agathe_st ; leur porte reste « porte_<prénom> »
## (porte_brunehaut, porte_tom…). anatole, ludovic, opaline, bertille restent tels quels.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bonne route, {surnom} ! Et regarde où tu mets les pieds : ici, il y a des rails partout, même là où on ne les attend pas.", "si": {}, "geste": "salut"},
		{"t": "À plus tard ! Si tu entends un grand « BONG », ne t'inquiète pas : c'est la Grande Horloge. Ou Maîtresse Brunehaut qui rit.", "si": {}, "geste": "rire"},
		{"t": "Va ! Et si tu te perds, lève la tête : le Soleil de Laiton est toujours au milieu. Tout le reste tourne autour.", "si": {}},
		{"t": "Bonne nuit ! Regarde : le Soleil de Laiton baisse sa lampe, il devient tout ambré. Chez nous, c'est ça, la lune.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Ici, on tape sur les enclumes, pas sur les voisins !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu veux que j'appelle la Doyenne Agathe ? Elle ne crie jamais. Elle te regarde. C'est bien pire.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Holà ! Sous terre, le moindre coup résonne jusqu'à la Fronde. Ils vont croire qu'on leur répond !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? C'est gentil. Je vais le poser sur ma cheminée, à côté de ma lanterne à cristal. Elle aime la compagnie.", "si": {}},
		{"t": "Merci, {surnom}. Ici, on dit qu'un cadeau, ça éclaire une galerie entière.", "si": {}},
		{"t": "Oh, merci ! Ça vient d'en haut ? Tout ce qui vient d'en haut a un petit goût de ciel.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par le Soleil de Laiton, tu as visé juste, {surnom} !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau qui brille plus qu'un cristal de la mine ! Merci, {surnom}. Toute la Place des Rouages va le savoir.", "si": {}, "geste": "rire"},
		{"t": "{dernier_cadeau} ! Pour moi ? Attends, je m'assois. Voilà. Merci. J'ai les yeux qui piquent. C'est la poussière de grès, sûrement.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… Je vais le mettre dans un wagonnet. Il ira là où vont les wagonnets. Loin.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, le plus dangereux, c'est le marteau-pilon. Et lui, il ne se bat pas : il travaille.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Sous terre, on n'oublie pas un visage : il y a si peu de lumière qu'on regarde chacun très attentivement.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Ici, on ne te demande qu'une chose : ne pas traîner sur les rails quand Bernadette siffle.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les mineurs ne s'ennuient jamais ? Parce qu'ils creusent toujours la question. … Ludovic ne rit jamais à celle-là. Il dit qu'on ne creuse rien sans étayer.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un cristal dit à une lanterne ? « Arrête de me regarder comme ça, je vais rougir. » Et la lanterne : « Trop tard, tu brilles. »", "si": {}, "geste": "rire"},
		{"t": "Un voyageur d'en haut sort de la cabine : « Il fait sombre, ici ! » Anatole, tout content : « Comment ? Il fait combien ? »", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on un champignon qui fait la fête ? Un champignon de la Fronde : il brille toute la nuit et il ne rentre jamais. … Bertille dit que c'est injuste. Les siens se couchent très tôt.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi le Soleil de Laiton ne se couche jamais ? Parce qu'il est déjà au plafond : il ne peut pas aller plus haut. Alors il baisse juste la lumière, comme tout le monde.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand la forge aura refroidi entre nous.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Solide comme le grès !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même un wagonnet ne roule pas sans qu'on le pousse.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Sous terre, on voyage léger : les galeries sont étroites.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}. Même un wagonnet de la mine refuserait de le porter.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et un coup de marteau en prime ! Sur l'enclume, hein.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu as une bonne tête de voyageur d'en haut. Un petit geste. Ne le dis pas à Honorine, elle voudrait te nourrir en plus.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont taillés dans le grès. Ça ne bouge pas d'un doigt par siècle. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. Ici, la roche a de la mémoire. Moi aussi.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par le Soleil de Laiton !", "Ça tourne !", "Ho ho !", "Quelle merveille !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Misère…", "Pfff…", "Tout s'éteint…"],
		"colere": ["Par tous les marteaux !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Par le Soleil de Laiton !", "Solide comme le grès.", "Attention aux rails !", "En bas, on dit…"],
	"humeur_mots": [[0.6, "rayonnant comme un cristal"], [0.25, "de bonne humeur"], [-0.25, "un peu terne"], [-0.6, "ombrageux"], [-2.0, "en plein éboulement"]],
	"surnoms": [[0, "voyageur"], [25, "ami des profondeurs"], [50, "mon camarade de galerie"], [75, "cœur de cristal"], [95, "enfant des Strates"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.68, 0.32]
const BLOND_PALE := [0.92, 0.84, 0.6]
const ROUX := [0.82, 0.3, 0.1]
const ARGENT := [0.82, 0.82, 0.86]
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
## Le bleu nuit des Liftiers (la casquette à galon doré).
const LIFTIER := [0.12, 0.17, 0.36]
## Les couleurs du travail d'en bas : le cuir des tabliers, le bleu de chauffe, la toile des mineurs.
const CUIR := [0.3, 0.19, 0.11]
const CHAUFFE := [0.2, 0.26, 0.42]
const TOILE := [0.42, 0.4, 0.32]


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
	out["groupe"] = "strates"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Gare des Strates
		{"id": "anatole", "nom": "Anatole Crémaillère", "titre": "liftier de la Ligne des Strates", "maison": "porte_anatole", "village": "strates",
			"agenda": [[6, 7, "st_gare_banc_1"], [7, 12, "st_gare_guichet"], [12, 13, "st_marmite_table_1"], [13, 20, "st_gare_quai"], [20, 22, "st_galerie_1"], [22, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BLEU, "chapeau": "casquette", "chapeau_c": LIFTIER, "haut": LIFTIER, "vieux": true, "taille": 0.95, "carrure": 1.1},
			"teinte": PEAU[2],
			"mj": {"tenue": "garde", "objet": "cloche"},
			"humeur_base": 0.6, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"chocolat_chaud": 2.0, "chocolat_mineur": 2.5, "biscuit_engrenage": 2.0, "engrenage": 1.5, "cafe_vapeur": 1.5, "carte_postale": 1.5}, "deteste": {"sifflet_muet": -0.5, "gelee_slime": -1.5},
			"tics": ["Comment ?", "Hein ? Parle plus fort !", "Tenez la rampe, comme dit Capucine.", "Ça descend !"],
			"surnoms": [[0, "cher passager"], [25, "passager du fond"], [50, "mon vieux boulon"], [75, "mon contrepoids"], [95, "mon passager d'honneur"]],
			"repliques": {
				"accueil": [
					L("Bienvenue en bas ! Anatole Crémaillère, liftier de la Ligne des Strates ! Cent mètres sous la Place, cinquante ans de métier, et pas une seule fois en retard. Enfin, si : une fois. Je n'avais pas entendu le réveil. Je n'entends plus grand-chose, d'ailleurs. Parle fort, mais souris : ça, je l'entends très bien.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Te revoilà ! Comment ? Tu as dit « bonjour » ou « encore toi » ? … Les deux ? Ha ! Alors bonjour, et encore toi !", {"visites_min": 2}, "rire"),
					L("Ah, {surnom} ! Tu descends si souvent que la cabine connaît ton poids. Elle a fait « ding » avant même que tu arrives. Enfin, je crois. Je l'ai senti dans mes pieds.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Grognon. La grille du Dôme d'Azur a grincé toute la nuit. Douze ans que je l'huile, et maintenant qu'elle s'ouvre trente fois par jour, elle grince ! Moi, je dis qu'elle fait l'intéressante. Je la comprends. Mais elle me casse les oreilles. Ce qu'il en reste.", {"humeur_max": -0.2}),
					L("Formidable ! La Ligne a rouvert, et la cabine descend pleine à chaque voyage ! Des gens d'en haut, avec des chapeaux, des parapluies (ici, il ne pleut pas !) et des yeux grands comme des lanternes. J'adore leurs yeux quand la porte s'ouvre sur la caverne.", {}, "rire"),
					L("Un peu fatigué des bras. Dix ans de cabine immobile, et maintenant soixante voyages par jour. Mes bras avaient oublié. Mon cœur, non.", {}),
					L("Ce matin, j'ai fait la première descente avec le pain d'en haut, pour La Marmite. Toute la cabine sentait la croûte chaude. Honorine m'a embrassé sur le crâne. Je n'ai pas entendu ce qu'elle a dit, mais j'ai senti que c'était gentil.", {"matin": true}),
					L("Le soir, je m'assois sur mon balcon de la galerie et je regarde le Soleil de Laiton baisser sa lampe. Tout devient couleur miel. C'est l'heure où j'entends le mieux : tout le monde se tait. Sauf la Fronde.", {"soir": true}),
				],
				"lui": [
					L("J'ai commencé liftier à quinze ans, dans cette même cabine. À l'époque, les machines faisaient un tel vacarme qu'on se parlait par gestes. Cinquante ans plus tard, les machines sont devenues douces. Mes oreilles, elles, sont restées au temps des gestes.", {}),
					L("Maîtresse Capucine et moi, on se parle par le tuyau acoustique de la Colonne. Cent mètres de tuyau ! En haut, elle chuchote. En bas, je hurle. Et on se comprend parfaitement. C'est le secret des vieux collègues de la Colonne.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Dix ans de Ligne fermée, {surnom}. Dix ans à huiler une cabine qui ne partait pas. Tous les matins. Les gens me disaient : « À quoi bon ? » Je répondais : « Comment ? » Ça m'évitait de répondre. Et un matin, elle est repartie. Bien huilée.", {"sujet_min": ["lui", 2]}),
					L("Douze ans, {surnom}, que j'huilais la grille du Dôme tous les soirs, au cas où. Et j'écrivais à Marius, le chef de gare d'en bas : « Grille huilée. Toujours fermée. Toujours prête. » Trois lignes. Lui me répondait douze pages. Le jour de la réouverture, je ne lui ai rien écrit. Je suis descendu avec lui.", {"sujet_min": ["lui", 3]}),
					L("Tu as rencontré Capucine, en haut ? Dis-lui qu'Anatole a bien graissé la poulie douze. Elle comprendra. Entre liftiers, c'est notre façon de dire « tu me manques ». Ne rougis pas. Moi, je ne rougis plus, j'ai l'âge.", {"a_rencontre": "capucine_hf"}, "rire"),
				],
				"ile": [
					L("La Ligne des Strates, c'est deux cabines, {surnom}. Celle d'en haut part du pavillon de la Place de la Colonne. Puis on change, et la mienne descend dans la Colonne Renversée : la Grande Colonne qui continue sous terre, en laiton et en verre, et qui pend de la voûte jusqu'à ma Gare. Une tour à l'envers ! Il fallait y penser.", {}),
					L("Tu as vu le Soleil de Laiton, autour de la Colonne Renversée ? Une grande sphère de cercles de laiton, et au cœur, une lampe à arc qui éclaire toute la caverne. Le jour, il brille fort. La nuit, il devient ambré. C'est notre soleil à nous. Il ne se couche jamais : il baisse juste les yeux.", {"sujet_min": ["ile", 1]}),
					L("La Colonne relie quatre mondes : les Nuées tout en haut, Hautefond, nous, les Strates, et tout au fond de la mer, le Dôme d'Azur. La grille du Dôme est juste derrière moi. Douze ans « fermée pour travaux ». C'est moi qui garde la clé. Elle a enfin rouvert ! Derrière, la cage de laiton descend jusqu'au Funiculaire. Je le savais : la grille grinçait d'impatience.", {"sujet_min": ["ile", 2]}),
					L("Le petit Barnabé, l'apprenti de Capucine, est descendu pour la réouverture. Tout vert. Il m'a dit : « Au moins, en descendant, on ne voit pas le vide. » J'ai dit : « Comment ? » Il a répété trois fois. À la troisième, il riait. Ça lui a fait du bien, je crois.", {"a_rencontre": "barnabe_hf"}, "rire"),
				],
				"rumeur": [
					L("Le Bourgmestre Hector est descendu pour la réouverture. Il a coupé le ruban avec la Doyenne Agathe, puis il a fait un discours de quarante minutes. Je n'en ai pas entendu un mot. C'est le plus beau discours de ma vie.", {}, "rire"),
					L("Le petit Tom, l'apprenti de la Forge, vient attendre près du quai tous les soirs. Il attend une petite d'en haut, Pimprenelle, avec qui il se parle à coups de marteau à travers la roche. Il dit que ce n'est pas pour elle. Il se recoiffe à chaque cabine.", {}, "rire"),
					L("Ferdinand, du Petit Train, dit que sa Bernadette siffle plus fort que ma cabine. Je ne sais pas. Je n'entends ni l'une ni l'autre. Mais je sens Bernadette dans mes pieds quand elle passe. Elle a un bon fond.", {}),
					L("Tu es passé au Piston Joyeux ? Firmin a la vieille chaudière de Ferdinand ! En haut, toute la ville règle ses montres sur son sifflet. Moi, je l'entends d'ici, quand le vent descend la Colonne. C'est la seule chose d'en haut que j'entends bien.", {"a_rencontre": "firmin"}, "rire"),
					L("Tu as vu Marius, au Funiculaire d'Azur ? Le jour de la réouverture, je me suis assis à côté de son pupitre. En bas, la Grande Chanteuse est passée au-dessus du Dôme. J'ai posé les mains sur la vitre, j'ai fermé les yeux… et je l'ai entendue, {surnom}. Moi ! Dans les mains, dans les pieds. On a pleuré tous les deux. Dans nos moustaches. Ne le répète pas. Enfin, si. Mais fort.", {"a_rencontre": "marius"}),
				],
				"interpelle": [L("Hé ! Vous descendez ? Comment ? Vous remontez ? Comment ?", {"visites_max": 0}, "salut"), L("{surnom} ! La cabine part ! Tenez la rampe, comme dit Capucine !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bonne route, {surnom} ! Et parle fort, en haut : qu'on t'entende jusqu'ici !", {}, "salut"), L("À bientôt ! Si tu cherches la grille du Dôme, elle est au bout du quai, grande ouverte. Elle te dit bonjour. Et « Bonnes bulles ! », comme on dit en bas.", {}, "rire"), L("Bonne nuit ! Après la dernière cabine, la Colonne Renversée dort la tête en bas. Comme une chauve-souris. Très bien élevée.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr ! Je ne retiens pas les voix, {surnom}, je retiens les visages. Et le tien a souri quand la porte s'est ouverte sur la caverne. Ça, je l'ai vu.", {})],
			}},
		# ================================================================ la Grande Forge des Strates
		{"id": "brunehaut_st", "nom": "Maîtresse Brunehaut Enclume", "titre": "cheffe de la Grande Forge des Strates", "maison": "porte_brunehaut", "village": "strates",
			"agenda": [[6, 12, "st_forge_enclume"], [12, 13, "st_marmite_table_2"], [13, 18, "st_forge_four"], [18, 20, "st_forge_comptoir"], [20, 22, "st_place_banc_2"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "tresse", "yeux": Y_BRUN, "haut": [0.5, 0.32, 0.22], "tablier": CUIR, "taille": 1.12, "carrure": 1.5},
			"teinte": PEAU[4],
			"mj": {"tenue": "forgeron", "objet": "marteau"},
			"humeur_base": 0.7, "traits": {"bavard": 0.8, "humour": 0.95, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"minerai_fer": 2.5, "coeur_magma": 3.0, "obsidienne": 2.0, "bouillon_strates": 2.0, "chocolat_chaud": 1.5, "ragout_nain": 1.5}, "deteste": {"gelee_slime": -1.5, "the_sommets": -0.5},
			"tics": ["HO HO HO !", "Derrière la ligne jaune !", "Deux coups, puis un.", "Ça, c'est du solide !"],
			"surnoms": [[0, "toi là"], [25, "mon gaillard"], [50, "mon vieux rail"], [75, "ma belle enclume"], [95, "mon acier des profondeurs"]],
			"boutique": {"vend": {"pelle": 14, "hache": 32, "engrenage": 3, "boulon": 1, "corde_chanvre": 4}, "achete": {"minerai_fer": 5, "obsidienne": 8, "coeur_magma": 12, "boulon": 1, "engrenage": 2, "ressort": 1, "hache": 14, "pelle": 6}},
			"repliques": {
				"accueil": [
					L("HO HO HO ! Un visiteur d'en haut ! Entre, entre, mais reste derrière la ligne jaune : le marteau-pilon n'aime pas les inconnus. Maîtresse Brunehaut Enclume, cheffe de la Grande Forge des Strates ! Ici, on forge les rails, les roues, les cages des lanternes, et les plus beaux rires de la caverne. HO HO !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te revoilà ! Approche, que je te serre la main. … Doucement ? Ah, pardon. HO HO ! On n'a pas l'habitude des mains d'en haut, elles sont toutes molles.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom} ! Tu viens si souvent que le marteau-pilon a ralenti en te voyant. C'est sa façon de dire bonjour. Il ne le fait que pour moi. Et pour Honorine, quand elle apporte la soupe.", {"visites_min": 4}),
				],
				"humeur": [
					L("Pas fameuse. Un four s'est éteint ce matin. Un four de la Grande Forge, ça ne s'éteint pas : ça boude. J'ai passé une heure à lui parler. Il est reparti. Moi, j'ai de la suie jusque dans les oreilles.", {"humeur_max": -0.2}),
					L("Excellente ! Douze roues de wagonnet, trente mètres de rail, et une lanterne pour la Gare. Et j'ai ri à chaque coup du marteau-pilon. Ça en fait, des rires. HO HO HO !", {}, "rire"),
					L("Un peu chiffonnée. La Fronde a encore « emprunté » ma grande pince pour son concert. Ils tapent dessus en rythme. Ils me la rendent toujours. Mais avec des autocollants.", {}, "rire"),
					L("Le matin, j'allume les fours avant tout le monde, et je donne le premier coup sur l'enclume : deux coups, puis un. Là-haut, sous la Basse-Ville, Mathilde me répond. Depuis vingt ans. Comme ça, on sait toutes les deux que l'autre est réveillée.", {"matin": true}),
					L("Le soir, je m'assois sur la Place et j'écoute la Forge refroidir. Tic, tic. Et de l'autre côté du Gouffre, la Fronde commence à jouer. Mes enclumes vibrent en rythme. Je crois qu'elles aimeraient aller danser.", {"soir": true}),
				],
				"lui": [
					L("Ma mère était forgeronne, ma grand-mère aussi, et son arrière-grand-mère a forgé les premiers cercles du Soleil de Laiton. Chez les Enclume, on naît presque avec un marteau dans la main. La sage-femme a dit que je serrais son doigt comme une pince.", {}),
					L("Mon rire ? C'est un outil. Sous terre, quand il y a du bruit partout, un bon rire, ça s'entend jusqu'au fond de la mine. Ludovic dit que c'est sa meilleure alarme : tant qu'il l'entend, tout va bien.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret, {surnom}. Le grand-père de Mathilde, la forgeronne d'en haut, a appris ici. Avec ma grand-mère, et avec les forgerons de la Fronde. Quand Mathilde tape fort, on tape en retour. Ça fait vingt ans qu'on se parle comme ça. Et on ne s'est encore jamais vues.", {"sujet_min": ["lui", 2]}),
					L("Tu as rencontré Mathilde ? Elle rit comment ? En « HA » ? Ha ! Je le savais. Moi, je ris en « HO ». À nous deux, on fera « HAHO ». Le jour où elle descendra, on fera trembler la caverne. Préviens Ludovic. Qu'il étaye.", {"a_rencontre": "mathilde"}, "rire"),
				],
				"ile": [
					L("La Grande Forge, c'est le cœur des Strates. Les rails, les wagonnets, les roues du Petit Train, les cages des lanternes : tout passe par mes fours. Et le marteau-pilon, là, c'est Grand-Mère. Il tape lentement, très fort, et il ne se trompe jamais. Mathilde, en haut, a appelé le sien Mamie. On n'a pas fait exprès. Enfin… je crois.", {}, "rire"),
					L("La Ligne a rouvert, et ceux d'en haut descendent voir la Forge. Ils restent sur le seuil, les yeux ronds, les mains sur les oreilles. Puis Grand-Mère tape, ils sursautent, je ris, et ils rient avec moi. Au troisième coup, ils sont de la maison.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Fronde, de l'autre côté du Pont des Frondeurs, c'est notre petite sœur bruyante. Ils jouent trop fort, ils peignent nos rails, ils empruntent mes pinces. Et quand un four tombe en panne, ils sont là les premiers, avec leurs outils et une chanson. On se chamaille. On s'aime bien.", {"sujet_min": ["ile", 2]}),
					L("Ysaé ? La petite bleue de la Fronde ! Elle venait ramasser les chutes de cuivre sous mon établi quand elle avait six ans. Maintenant, c'est Mathilde qui les lui garde, en haut. Elle raconte que c'est son oncle qui répond aux coups. Je ne suis pas son oncle. Je suis bien plus large.", {"a_rencontre": "ysae"}, "rire"),
				],
				"rumeur": [
					L("Le Bourgmestre Hector est passé à la Forge pour la réouverture. Il a demandé si on faisait des médailles. J'ai dit : « On fait des rails. » Il a dit : « Et une petite médaille en forme de rail ? » Je lui en ai fait une. Il l'a épinglée tout de suite. HO HO !", {}, "rire"),
					L("Mon apprenti, Tom, tape un code sur la roche pour parler à la fille de Mathilde. Trois coups vite, c'est « boulon trouvé ». Un long frottement, c'est « bonne nuit ». Il croit que je ne comprends pas. J'ai inventé la moitié de ces signes à son âge.", {}, "rire"),
					L("Papy Ferdinand a vendu la chaudière de secours de Bernadette à un tavernier d'en haut, pour en faire une machine à chocolat. J'ai forgé les rivets de cette chaudière quand j'avais vingt ans. Alors ce chocolat a un peu de ma forge dedans. Ça explique pourquoi il siffle.", {}),
					L("Tu as vu la petite Pimprenelle, en haut ? Tom ne parle que d'elle. Enfin, de « la personne qui tape ». Il rougit comme un fer chaud. Quand elle descendra, je lui offrirai un boulon forgé exprès. Le plus beau. Fait par Tom. Il ne le sait pas encore.", {"a_rencontre": "pimprenelle_hf"}, "rire"),
					L("Tu es descendu au Dôme d'Azur ? Tu as vu Yolande, à l'Atelier des Scaphandres ? Les roues du Funiculaire, c'est ici, à la Grande Forge, qu'on les a coulées ! J'avais mis un mot sur la caisse : « Trempées dans le rire. HO HO ! » Elle a gardé la caisse. Et elle tapote ses vitres deux coups, puis un. C'est moi qui lui ai appris. Elle rit en « hm », paraît-il. Ça compte. HO HO HO !", {"a_rencontre": "yolande"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Viens voir taper ! Derrière la ligne jaune !", {"visites_max": 0}, "salut"), L("{surnom} ! HO HO ! Viens, le four est chaud !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("À plus, {surnom} ! Et si tu entends deux coups, puis un, réponds ! Ça veut dire bonjour, merci.", {}, "salut"), L("Salut ! Dis à Honorine que j'arrive pour la soupe. Elle le sait déjà. Elle le sait toujours. HO HO !", {}, "rire"), L("Bonne nuit ! La Forge s'endort. Elle ronfle un peu par les cheminées. Comme moi.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? HO ! Tu as fait un bond jusqu'à la voûte la première fois que Grand-Mère a tapé. On en parle encore à La Marmite.", {}, "rire")],
				"boutique": [L("Pelles, haches, engrenages, boulons, cordes ! Forgés dans les Strates et trempés dans le rire ! Pas d'épées : ici, on forge pour bâtir. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "tom_st", "nom": "Tom Taraud", "titre": "apprenti de la Grande Forge (11 ans)", "maison": "porte_tom", "village": "strates",
			"agenda": [[7, 8, "st_marmite_table_3"], [8, 12, "st_forge_apprenti"], [12, 13, "st_marmite_table_3"], [13, 17, "st_forge_apprenti"], [17, 19, "st_gare_banc_2"], [19, 20, "st_train_quai"], [20, 7, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "yeux": Y_VERT, "haut": [0.6, 0.36, 0.2], "tablier": CUIR, "lunettes": true, "enfant": true, "taille": 0.76},
			"teinte": PEAU[3],
			"mj": {"tenue": "enfant", "objet": "marteau"},
			"humeur_base": 0.7, "traits": {"bavard": 0.9, "humour": 0.75, "curiosite": 0.95, "susceptible": 0.35, "rancunier": 0.05},
			"aime": {"boulon": 2.5, "chocolat_chaud": 2.5, "chocolat_mineur": 2.5, "biscuit_engrenage": 2.0, "engrenage": 2.0, "canard_mecanique": 1.5}, "deteste": {"the_menthe": -0.5, "vieille_botte": -0.5},
			"tics": ["Deux coups, puis un !", "C'est un code. Secret.", "Il a du caractère.", "Pimprenelle dirait…"],
			"surnoms": [[0, "monsieur-madame d'en haut"], [25, "copain"], [50, "mon équipier"], [75, "mon meilleur copain"], [95, "mon frère de forge"]],
			"repliques": {
				"accueil": [
					L("Salut ! Moi, c'est Tom Taraud, j'ai onze ans, je suis apprenti à la Grande Forge. Tu viens d'en haut ? Tu connais Pimprenelle ? Non ? Tant pis. Si tu la vois, dis-lui : trois coups vite. Elle comprendra. Bon, je retourne taper.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Regarde mes mains ! Des cals ! Des vrais ! Maîtresse Brunehaut dit que c'est le début d'un forgeron. Moi, je dis que ça fait mal. Mais je suis fier.", {"visites_min": 2}, "rire"),
					L("Tiens, {surnom} ! Tu veux que je t'apprenne le code ? Deux coups, puis un : bonjour, merci. Trois coups vite : boulon trouvé. Un long frottement : bonne nuit. Le reste, c'est secret.", {"visites_min": 4}),
				],
				"humeur": [
					L("Bof. Ce matin, j'ai tapé deux coups, puis un. Personne n'a répondu d'en haut. Maîtresse Brunehaut dit que Pimprenelle dort peut-être encore. Moi, je me suis levé à six heures exprès. C'est pas grave. Je retaperai demain.", {"humeur_max": -0.2}),
					L("Super ! J'ai forgé mon premier crochet tout seul ! Il est un peu tordu. Maîtresse Brunehaut a dit : « Il a du caractère. » Ça veut dire qu'il est raté, mais gentiment.", {}, "rire"),
					L("Un peu fatigué. Tenir la pince toute la journée, ça fait des bras en coton. Mais Honorine m'a donné une galette en plus, à midi. Elle dit que les apprentis, c'est comme les fours : ça s'entretient.", {}),
					L("Ce matin, Pimprenelle a répondu tout de suite ! Trois coups vite ! Elle a trouvé un boulon ! Je ne sais pas lequel. Je l'imagine doré. Avec six pans.", {"matin": true}, "rire"),
					L("Le soir, je vais regarder Bernadette rentrer au dépôt. Papy Ferdinand me laisse tirer le sifflet. Un coup, pas plus. Le dernier coup du soir, c'est pour Pimprenelle. Elle ne l'entend pas. Mais c'est pour elle quand même.", {"soir": true}),
				],
				"lui": [
					L("Mon papa est cheminot, il répare les aiguillages. Ma maman est lampiste à l'Atelier des Lumières. Moi, j'ai choisi la forge, parce que c'est là qu'on fait le plus de bruit. Ils ont dit : « Évidemment. »", {}, "rire"),
					L("Le code, c'est un peu moi qui l'ai commencé. Un jour, j'ai entendu taper au-dessus, à travers la roche : deux coups, puis un. Pas comme Mathilde : plus petit, plus rapide. J'ai répondu. Ça fait deux ans. C'est Pimprenelle. Je lui apprends le code. Elle apprend super vite. Trop vite, même.", {"sujet_min": ["lui", 1]}),
					L("Tu veux savoir un secret, {surnom} ? Je forge un boulon. Un vrai, à six pans, avec un « P » gravé dessus. Je le fais en cachette, à la pause. Le jour où elle descendra, je le lui donnerai. Ou je le laisserai tomber exprès devant elle. Elle ramasse tous les boulons, paraît-il.", {"sujet_min": ["lui", 2]}),
					L("Tu l'as vue ? Pimprenelle ? En vrai ? Elle est comment ? Elle a vraiment trois cents boulons ? … Ne lui dis pas que j'ai demandé. Dis-lui juste… trois coups vite. Non, deux coups, puis un. Non… Dis-lui bonjour. Voilà. Bonjour.", {"a_rencontre": "pimprenelle_hf"}),
				],
				"ile": [
					L("Les Strates, c'est la meilleure ville du monde. Il y a des rails partout, des wagonnets, un train, une forge, des cristaux qui brillent, et un soleil en laiton qu'on peut regarder sans avoir mal aux yeux. En haut, paraît qu'il ne faut pas regarder le soleil. C'est nul.", {}),
					L("Quand la Ligne a rouvert, tout le monde était sur la Place des Rouages. La Grande Horloge a sonné, la cabine est arrivée, et les gens d'en haut sont sortis en clignant des yeux. Un monsieur a dit : « Oh, il y a un soleil ! » Toute la Place a applaudi. On était fiers de notre soleil.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Après le Pont des Frondeurs, il y a la Fronde, et le skatepark. Ressort, de la Fronde, a onze ans comme moi. Ressort descend la rampe en criant « LIBERTÉ ! ». Moi, je crie « ATTENTION AUX RAILS ! ». On s'entend très bien : Ressort m'a appris à tomber, moi, je lui ai appris à freiner.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Tu connais Mathilde, la maman de Pimprenelle ? Maîtresse Brunehaut dit qu'elle tape aussi fort qu'elle. Moi, j'ai jamais vu personne taper aussi fort que Maîtresse Brunehaut. Si c'est vrai, la Basse-Ville doit sauter en l'air tous les matins.", {"a_rencontre": "mathilde"}, "rire"),
				],
				"rumeur": [
					L("Maîtresse Brunehaut croit que je ne sais pas qu'elle comprend notre code. Je sais qu'elle le comprend. Elle a souri quand j'ai tapé « bonne nuit ». Je fais semblant de rien. C'est plus simple pour tout le monde.", {}, "rire"),
					L("Papy Ferdinand a vendu une chaudière à un monsieur d'en haut, pour faire du chocolat. Une chaudière de train ! Pour du chocolat ! Je trouve que c'est la meilleure idée de toute l'histoire des Strates.", {}),
					L("Le contremaître Ludovic parle à la roche. Il lui dit bonjour, merci, pardon. J'ai rigolé, la première fois. Puis je me suis dit : la roche, elle est là depuis des millions d'années, elle a bien le droit qu'on lui dise bonjour. Alors maintenant, je lui dis bonjour aussi.", {}),
					L("Ysaé, la grande aux cheveux bleus, m'a dit que Pimprenelle porte un collier avec un boulon et un cristal bleu. Un cristal de chez nous ! De l'Atelier de la Docteure Opaline ! Alors elle a déjà un peu des Strates autour du cou. C'est bien, non ?", {"a_rencontre": "ysae"}),
				],
				"interpelle": [L("Hé ! Tu viens d'en haut ? Tu connais Pimprenelle ?", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir mon crochet ! Il a du caractère !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut, {surnom} ! Si tu montes, tape deux coups, puis un, sur n'importe quoi. Ça porte bonheur.", {}, "salut"), L("À plus ! Faut que j'y retourne : Maîtresse Brunehaut compte les coups. Elle sait quand j'en rate un.", {}, "rire"), L("Bonne nuit ! Je vais faire un long frottement sur le mur de ma chambre. Ça veut dire bonne nuit. Peut-être que ça monte jusqu'en haut.", {"soir": true})],
				"souvenir": [L("Bien sûr que je me souviens de toi ! T'es la personne qui m'a écouté expliquer le code jusqu'au bout. Même Papy Ferdinand s'endort au milieu.", {}, "rire")],
			}},
		# ================================================================ les Mines de Cristaux
		{"id": "ludovic", "nom": "Ludovic Grisou", "titre": "contremaître des Mines de Cristaux", "maison": "porte_ludovic", "village": "strates", "vouvoie": true,
			"agenda": [[6, 7, "st_mine_bureau"], [7, 12, "st_mine_front"], [12, 13, "st_marmite_table_4"], [13, 17, "st_mine_wagon"], [17, 19, "st_mine_bureau"], [19, 21, "st_place_banc_3"], [21, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "courte", "yeux": Y_GRIS, "haut": TOILE, "tablier": [0.32, 0.3, 0.26], "taille": 1.02, "carrure": 1.2},
			"teinte": PEAU[1],
			"mj": {"tenue": "artisan", "objet": "lanterne", "chapeau": "casque"},
			"humeur_base": 0.35, "traits": {"bavard": 0.4, "humour": 0.45, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"chocolat_mineur": 2.5, "eclat_cristal": 2.0, "caillou": 1.5, "obsidienne": 1.5, "cafe_vapeur": 1.5, "corde_chanvre": 1.5}, "deteste": {"bombe_peinture": -1.0, "piment_infernal": -1.0},
			"tics": ["La sécurité d'abord.", "Le casque !", "Bonjour, la Vieille.", "On étaye, puis on discute."],
			"surnoms": [[0, "visiteur"], [25, "apprenti mineur"], [50, "mon équipier"], [75, "mon lumignon"], [95, "mon filon d'or"]],
			"repliques": {
				"accueil": [
					L("Halte ! Casque ? Pas de casque. Bon. Restez derrière la ligne blanche. Ludovic Grisou, contremaître des Mines de Cristaux. Règle numéro un : la sécurité. Règle numéro deux : la sécurité. Règle numéro trois : dire bonjour à la Vieille. La roche. Elle aime qu'on la salue.", {"visites_max": 1}),
					L("{surnom}. Toujours pas de casque ? … Tenez, je vous en ai gardé un. Il est un peu grand : il était à mon grand-père. Il a protégé trois générations. Il vous protégera bien un après-midi.", {"visites_min": 2}),
					L("Ah, {surnom}. La Vieille vous connaît, maintenant. Elle ne craque plus quand vous entrez. C'est rare. Elle est très méfiante avec ceux d'en haut.", {"visites_min": 4}, "salut"),
				],
				"humeur": [
					L("Soucieux. Un petit craquement, ce matin, dans la galerie quatre. Rien de grave. Mais j'ai tout fait étayer, tout vérifier, et j'ai demandé pardon à la Vieille. Trois fois. Elle s'est calmée. Moi, pas encore.", {"humeur_max": -0.2}),
					L("Bonne. Quatre mille deux cents jours sans un seul accident. J'ai un tableau dans mon bureau. Chaque matin, j'ajoute un jour. C'est le plus beau chiffre que je connaisse.", {}),
					L("Un peu fatigué. Depuis que la Ligne a rouvert, tous les gens d'en haut veulent visiter la Grotte aux Cristaux. Je leur explique le casque, la ligne blanche, les wagonnets… Ils écoutent. Puis ils voient les cristaux, et ils oublient tout. Je recommence.", {}),
					L("Le matin, j'entre le premier dans la mine. Seul. J'éteins ma lampe une minute, et je regarde les cristaux bleus s'allumer dans le noir. Une minute. Pas plus. Puis je rallume. La sécurité d'abord. Mais la beauté juste avant.", {"matin": true}),
					L("Le soir, je m'assois sur un banc de la Place des Rouages et je compte mes mineurs qui rentrent. Tous. Un par un. Quand le compte est bon, j'enlève mon casque. Pas avant.", {"soir": true}),
				],
				"lui": [
					L("Mon grand-père était mineur, mon père aussi. Mon père m'a appris la règle la plus importante : « La roche parle. Il faut juste se taire assez longtemps pour l'entendre. » Je me tais beaucoup. Les gens me trouvent sérieux. Moi, je les trouve bavards.", {}),
					L("Je parle à la roche, oui. Je l'appelle la Vieille. Elle a des millions d'années, elle a droit au respect. Je lui dis bonjour en entrant, merci en sortant, et pardon quand on creuse. Les jeunes rigolent. Puis ils le font aussi. En cachette.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous dire pourquoi je suis si prudent, {surnom}. Quand j'avais douze ans, une vieille galerie s'est affaissée. Tout le monde était dehors. Tout le monde. Parce que mon père avait entendu la roche craquer une minute avant, et qu'il avait sifflé la sortie. Depuis, j'écoute. Pour lui.", {"sujet_min": ["lui", 2]}),
					L("Vous connaissez le Professeur Lunette, l'astronome d'en haut ? Il m'a écrit qu'il voulait voir « les étoiles d'en bas ». Mes cristaux. Je lui ferai visiter la Grotte, lampes éteintes. Mais avec un casque. Même les astronomes ont une tête.", {"a_rencontre": "octave_hf"}),
				],
				"ile": [
					L("Les Mines de Cristaux sont à l'ouest de la caverne, par le grand tunnel. Au bout, la Grotte aux Cristaux : des cristaux bleus partout, aux murs, au plafond, qui brillent dans le noir. Les rails vont jusqu'au fond, et les wagonnets ramènent les cristaux à l'Atelier des Lumières. Doucement. On ne secoue pas un cristal.", {}),
					L("Le grès des Strates est en couches : ocre, crème, rouille, gris. Chaque couche, ce sont des milliers d'années. On lit la roche comme un livre, de bas en haut. Tout en haut, la dernière page, c'est Hautefond. Elle est encore en cours d'écriture.", {"sujet_min": ["ile", 1]}),
					L("La Colonne relie quatre mondes, et sous le Dôme d'Azur, au fond de la mer, il y a encore de la roche, paraît-il. Plus vieille que la nôtre. La Ligne du Dôme a rouvert, et je suis descendu lui dire bonjour, de la part de la Vieille. Elles doivent être cousines. Il fallait faire les présentations. J'ai gardé mon casque.", {"sujet_min": ["ile", 2]}),
					L("Le Bourgmestre Hector voulait visiter la Grotte sans casque, « pour le portrait ». J'ai dit non. Il a fait un discours sur la liberté. J'ai fait un discours sur la gravité. Le mien était plus court. Il a mis le casque. Le portrait est très réussi.", {"a_rencontre": "hector_hf"}, "rire"),
				],
				"rumeur": [
					L("La Docteure Opaline vient choisir ses cristaux elle-même, au fond de la Grotte. Elle oublie son casque. Toujours. Je lui en ai accroché un à la porte de l'Atelier. Elle s'en sert comme pot à crayons. Bon. Au moins, ses crayons sont en sécurité.", {}, "rire"),
					L("Les jeunes de la Fronde sont venus peindre l'entrée de la mine, une nuit. J'ai d'abord grogné. Puis j'ai vu qu'au-dessus de l'entrée, ils avaient peint un mineur avec un casque. Bien attaché. Avec la jugulaire. Je n'ai plus rien dit.", {}),
					L("Maîtresse Brunehaut rit si fort qu'on l'entend jusqu'au fond de la mine. C'est mon alarme. Tant que j'entends son rire, tout va bien en surface. Le jour où elle se taira, j'évacuerai. Par principe.", {}, "rire"),
					L("Ysaé, la petite aux cheveux bleus ? Elle est descendue dans ma mine le jour de ses quinze ans, pour choisir sa couleur. Elle a regardé les cristaux pendant une heure. Sans casque ! Je lui en ai mis un. Elle est ressortie bleue. Les cheveux. Le casque était très bien attaché.", {"a_rencontre": "ysae"}),
				],
				"interpelle": [L("Halte ! Le casque !", {"visites_max": 0}), L("{surnom}. Bonjour. La Vieille vous salue.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et regardez où vous mettez les pieds. Même en haut.", {}, "salut"), L("Allez. Dites merci à la Vieille en sortant. Elle s'en souviendra.", {}), L("Bonsoir. Mes mineurs sont tous rentrés. Rentrez bien, vous aussi. Ça me fera un de plus.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Je me souviens de tous ceux qui sont entrés dans ma mine, {surnom}. Et de tous ceux qui en sont ressortis. C'est-à-dire tout le monde. C'est ça, mon métier.", {})],
			}},
		# ================================================================ l'Atelier des Lumières
		{"id": "opaline", "nom": "Docteure Opaline Quartz", "titre": "cristallière de l'Atelier des Lumières", "maison": "porte_opaline", "village": "strates", "vouvoie": true,
			"agenda": [[7, 8, "st_mine_entree"], [8, 13, "st_lumieres_etabli"], [13, 14, "st_marmite_table_1"], [14, 18, "st_lumieres_etabli"], [18, 20, "st_lumieres_comptoir"], [20, 22, "st_jardin_bassin"], [22, 7, "maison"]],
			"azur": {"cheveux": BLOND_PALE, "coiffure": "chignon", "yeux": Y_VIOLET, "haut": [0.3, 0.36, 0.56], "robe": [0.22, 0.26, 0.42], "robe_longue": true, "tablier": [0.78, 0.75, 0.68], "lunettes": true, "taille": 0.98, "carrure": 0.9},
			"teinte": PEAU[0],
			"mj": {"tenue": "savant", "objet": "lanterne"},
			"humeur_base": 0.5, "traits": {"bavard": 0.75, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.25, "rancunier": 0.0},
			"aime": {"eclat_cristal": 3.0, "cristal_astral": 2.5, "fragment_meteorite": 2.0, "cristal_soufre": 2.0, "the_menthe": 1.5, "champignon_lune": 1.5}, "deteste": {"vieille_botte": -1.0, "lunettes_kaleido": -1.0},
			"tics": ["Fascinant… attendez.", "Où ai-je mis mes lunettes ?", "Ça brille !", "Pardon, je pensais à un cristal."],
			"surnoms": [[0, "cher visiteur"], [25, "cher curieux"], [50, "cher assistant"], [75, "mon éclat préféré"], [95, "mon cristal parfait"]],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour ! Pardon, je ne vous avais pas vu, j'étais dans un cristal. Dans ma tête, je veux dire. Docteure Opaline Quartz, cristallière de l'Atelier des Lumières. Je fabrique les lanternes à cristal des Strates. Toutes. Même celle qui est sur ma tête. Ah non, ce sont mes lunettes. Je les cherchais.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous tombez bien. Enfin, j'espère que vous n'êtes pas tombé. J'ai taillé un cristal qui brille un peu plus fort quand on lui parle. Dites-lui quelque chose. … Vous voyez ? Ou alors, c'est la lampe. Je vérifierai.", {"visites_min": 2}, "rire"),
					L("Ah, mon cher {surnom}. Asseyez-vous. Pas là, c'est un cristal. Ni là, c'est mon déjeuner. Je ne sais plus de quel jour.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Contrariée. Un cristal s'est fendu pendant la taille. Il était parfait. Il est toujours beau, remarquez. Mais il brille en deux couleurs, maintenant. On dirait qu'il hésite. Je le comprends. J'hésite aussi.", {"humeur_max": -0.2}),
					L("Merveilleuse ! Je crois avoir compris pourquoi les cristaux bleus brillent plus fort le soir. Ils boivent la lumière du Soleil de Laiton toute la journée, et la nuit, ils la rendent. Comme un enfant qui a trop goûté et qui ne veut pas se coucher.", {}, "rire"),
					L("Distraite. Plus que d'habitude. J'ai mis du sucre dans mon encre et de l'encre dans mon thé. Le thé est bleu. Il est très bon, d'ailleurs. Ne le dites pas à Honorine.", {}, "rire"),
					L("Le matin, je vais jusqu'à la mine choisir mes cristaux, avant les wagonnets. Ludovic me crie « Casque ! ». Je réponds « Oui ! ». Puis j'oublie. Il me rattrape toujours à l'entrée. C'est notre petit rituel.", {"matin": true}),
					L("Le soir, je vais au bord de l'étang des Jardins. Les champignons brillent, mes lanternes brillent, et l'eau reflète le Soleil de Laiton qui baisse. Trois lumières qui se répondent. J'essaie de comprendre ce qu'elles se disent.", {"soir": true}),
				],
				"lui": [
					L("J'ai étudié les cristaux en haut, à Hautefond, puis dans toutes les bibliothèques de l'archipel. Un jour, je suis descendue voir les cristaux bleus en vrai. Je suis restée. Trente ans. J'avais prévu une semaine. Ma valise est encore sous le lit. Je ne l'ai jamais défaite.", {}),
					L("Une lanterne à cristal, c'est simple : un cristal bleu de la mine, un peu de lumière pour le nourrir, une cage de laiton de la Forge, et beaucoup de patience. Elle éclaire toute la nuit, sans flamme ni fumée. Chaque famille des Galeries en a une. Je les connais toutes par leur prénom. Les lanternes. Les familles aussi, un peu.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous confier quelque chose, {surnom}. Le petit cristal bleu des bijoux d'Ysaé, c'est moi qui le lui donne. Les éclats trop petits pour une lanterne. Quand elle était petite, elle venait les chiper sous mon établi. Je faisais semblant de ne rien voir. Aujourd'hui, elle les porte jusqu'en haut. Mes petits éclats voyagent mieux que moi.", {"sujet_min": ["lui", 2]}),
					L("Vous connaissez Mademoiselle Philippine, de la Bibliothèque des Cartes ? Nous nous écrivons. Elle m'a envoyé une copie de sa carte de la Fronde, dessinée d'après les mots d'Ysaé. Elle est fausse à quatre endroits, et c'est la plus belle carte que j'aie jamais vue. Je ne corrigerai rien.", {"a_rencontre": "philippine"}),
				],
				"ile": [
					L("L'Atelier des Lumières fabrique toutes les lanternes des Strates, et il veille sur le cœur du Soleil de Laiton : la lampe à arc, au milieu de la sphère. Chaque soir, à vingt heures, un lampiste tourne la grande manivelle pour baisser sa lumière. Quarante tours. Les soirs où c'est mon tour, j'oublie de compter. La caverne reste toute rose. Les gens adorent.", {}, "rire"),
					L("Les cristaux bleus de la Grotte ne brillent pas tout seuls. Ils boivent la lumière du Soleil de Laiton, et ils la rendent dans le noir. Sans notre soleil, pas de lanternes. Sans lanternes, pas de nuit tranquille. Tout se tient, ici. Comme les couches de la roche.", {"sujet_min": ["ile", 1]}),
					L("Quatre mondes sur une seule Colonne : les Nuées, Hautefond, nous, et le Dôme d'Azur au fond de la mer. En haut, ils ont le vrai soleil. Au Dôme, ils ont la lumière bleue de l'eau. Ici, nous avons fabriqué la nôtre. Je trouve que c'est la plus courageuse des trois.", {"sujet_min": ["ile", 2]}),
					L("Le Professeur Lunette, l'astronome d'en haut, m'a demandé de lui tailler une lentille en cristal bleu pour sa grande lunette. Pour voir « des étoiles bleues ». Je lui ai répondu que les étoiles n'étaient pas bleues. Il m'a répondu : « Pas encore. » J'ai commencé la lentille.", {"a_rencontre": "octave_hf"}, "rire"),
				],
				"rumeur": [
					L("Le contremaître Ludovic m'a accroché un casque à la porte de l'Atelier, pour que je ne l'oublie plus. J'y range mes crayons. C'est le pot à crayons le plus sûr des Strates. Ludovic ne trouve pas ça drôle. Mais je l'ai vu sourire sous sa moustache. Enfin, sous sa barbe.", {}, "rire"),
					L("Bertille, aux Jardins, prétend que ses champignons brillent plus fort que mes cristaux. Nous avons fait un concours, toutes lumières éteintes. Le jury, c'était le petit Tom. Il a dit : « Les deux. » Diplomate, à onze ans. Il ira loin.", {}, "rire"),
					L("Les parents d'Ysaé, Rivet et Bielle, entretiennent les rails des wagonnets de la mine. Le jour, des clés à molette. La nuit, des guitares et des tambours, avec leur groupe, les Soupapes. Je leur ai fait une lanterne qui clignote en rythme, pour la scène. Elle clignote même quand ils jouent faux. Surtout, même.", {}, "rire"),
					L("La petite Pimprenelle, en haut, porte un collier avec un de mes éclats. Ysaé me l'a raconté : elle ne l'enlève jamais, même pour le bain. Un cristal des Strates qui prend des bains à Hautefond ! Je n'aurais jamais imaginé une si belle carrière pour un éclat de rebut.", {"a_rencontre": "pimprenelle_hf"}),
				],
				"interpelle": [L("Oh ! Attention, ne marchez pas sur… Ah. C'était un caillou. Bonjour !", {"visites_max": 0}), L("{surnom} ! Venez voir, ça brille !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et si vous voyez mes lunettes quelque part, rapportez-les-moi. … Elles sont sur ma tête ? Ah.", {}, "rire"), L("À bientôt. Gardez un peu de lumière pour le chemin.", {}, "salut"), L("Bonsoir. Regardez le Soleil de Laiton baisser. Si la caverne reste toute rose, c'est que c'était mon tour de manivelle.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de vous ? Oh oui. Je me souviens de tout ce qui brille. Vous aviez les yeux qui brillaient, la première fois, devant les lanternes. Je l'ai noté. Quelque part. Sur un cristal, peut-être.", {})],
			}},
		# ================================================================ les Jardins des Champignons
		{"id": "bertille", "nom": "Bertille Champignac", "titre": "jardinière des Jardins des Champignons", "maison": "porte_bertille", "village": "strates",
			"agenda": [[6, 9, "st_jardin_bassin"], [9, 13, "st_jardin_1"], [13, 14, "st_marmite_table_2"], [14, 18, "st_jardin_2"], [18, 20, "st_jardin_3"], [20, 22, "st_jardin_banc"], [22, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "boucles", "yeux": Y_VERT, "chapeau": "capeline", "haut": [0.45, 0.55, 0.4], "robe": [0.35, 0.3, 0.25], "tablier": [0.42, 0.32, 0.2], "taille": 0.96, "carrure": 1.05},
			"teinte": PEAU[2],
			"mj": {"tenue": "paysan", "objet": "panier", "chapeau": "chaperon"},
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"champignon_lune": 3.0, "champignon": 2.0, "pomme": 2.5, "graines": 2.0, "goutte_rosee": 1.5, "sirop_cascade": 2.0}, "deteste": {"hache": -1.0, "gelee_slime": -1.0},
			"tics": ["Chut, ils poussent.", "La cascade le dit.", "Il pleut en haut.", "Doucement, ça brille."],
			"surnoms": [[0, "petit spore"], [25, "jeune pousse de l'ombre"], [50, "mon champignon"], [75, "ma lumière douce"], [95, "mon plus beau mycélium"]],
			"boutique": {"vend": {"champignon": 2, "graines": 2}, "achete": {"pomme": 2, "baies": 1, "graines": 1, "miel": 3, "champignon": 1}},
			"repliques": {
				"accueil": [
					L("Bienvenue aux Jardins des Champignons ! Bertille Champignac, jardinière. Ici, rien ne pousse au soleil : tout pousse dans l'ombre, et tout brille quand même. Des bleus, des verts, des orangés… Ne les touche pas trop, ils sont chatouilleux. Regarde, celui-là vient de clignoter. Il t'aime bien.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Écoute la cascade. Elle chante fort, aujourd'hui : il pleut en haut, à Hautefond. Tu as bien fait de descendre. Ici, il ne pleut qu'à un seul endroit, et c'est exprès.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Mes champignons te reconnaissent. Ils s'allument un peu plus quand tu arrives. Enfin, je crois. Ou alors c'est la vapeur de l'étang. Disons que c'est toi.", {"visites_min": 4}),
				],
				"humeur": [
					L("Triste. La cascade est presque à sec : ça veut dire qu'en haut, il n'a pas plu depuis deux semaines. Mes champignons ont soif. Je les arrose à la main, avec l'eau de l'étang. Un par un. Ils sont deux mille.", {"humeur_max": -0.2}),
					L("Très bien ! Un nouveau champignon a poussé cette nuit, au bord de l'étang. Violet, avec des points dorés. Je l'ai appelé Hector, parce qu'il est très fier et qu'il a un joli petit chapeau. Ne le répète pas au Bourgmestre.", {}, "rire"),
					L("Rêveuse. J'ai passé la matinée à écouter la cascade. Elle m'a raconté la pluie d'en haut : sur les toits d'ardoise, dans les Vergers, sur le chapeau d'une dame au marché. Toute l'eau de Hautefond finit ici. Avec ses histoires.", {}),
					L("Le matin, je m'assois au bord du bassin et je regarde les champignons s'endormir. Ils brillent moins quand le Soleil de Laiton reprend sa force. Comme des veilleuses qu'on éteint. Eux, ils dorment toute la journée. Moi, je travaille.", {"matin": true}),
					L("Le soir, quand le Soleil de Laiton devient ambré, mes Jardins s'allument tous en même temps. Bleu, vert, orange, violet. Les gens viennent s'asseoir sur le banc et ne disent plus rien. C'est le plus beau silence des Strates.", {"soir": true}),
				],
				"lui": [
					L("Ma grand-mère a planté le premier champignon lumineux ici, il y a soixante ans, dans un seau, au pied de la cascade. Elle l'avait trouvé au fond d'une vieille galerie. Aujourd'hui, ils sont deux mille, et ils descendent tous de celui-là. C'est une très grande famille. Un peu bavarde.", {}),
					L("La cascade tombe d'une fissure de la voûte : c'est la pluie de Hautefond qui traverse la roche et qui arrive ici. Quand elle grossit, je sais qu'il pleut en haut. Quand elle chante doucement, il fait beau. Je suis la seule météo des Strates. Je ne me trompe jamais. Enfin, avec un jour de retard.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux mon secret, {surnom} ? Je n'ai vu le vrai soleil qu'une fois, toute petite. J'ai pleuré : il faisait mal aux yeux. Depuis, je suis restée en bas, avec mes champignons. Eux non plus n'aiment pas le grand soleil. Maintenant que la Ligne a rouvert, je me dis que je pourrais réessayer. Avec un chapeau. Un très grand.", {"sujet_min": ["lui", 2]}),
					L("Tu connais le Père Bastien, des Vergers d'en haut ? Il m'a fait dire qu'il descendrait avec un panier de pommes, pour faire des échanges. Des pommes ! Je n'en ai mangé que trois dans ma vie. Paraît qu'il parle à ses arbres. Moi, j'écoute la cascade. On va bien s'entendre.", {"a_rencontre": "bastien_hf"}),
				],
				"ile": [
					L("Les Jardins des Champignons sont au sud de la caverne, sous une grande arche : l'étang, la cascade qui tombe de la voûte, et des champignons partout, grands comme des tabourets ou petits comme des boutons. Il y en a qui brillent bleu, d'autres vert, d'autres orange. On ne cueille que ceux qui ne brillent plus. Les autres, on les laisse vivre.", {}),
					L("Honorine, à La Marmite, fait sa soupe avec mes champignons. Pas ceux qui brillent, hein : ceux-là, on ne les mange jamais, on les regarde. Les autres, les bruns, sont tout simples et très bons. Ils ne savent pas briller, mais ils savent réchauffer. Chacun son talent.", {"sujet_min": ["ile", 1]}),
					L("La Colonne relie quatre mondes. Et toute l'eau descend : la pluie des Nuées tombe sur Hautefond, celle de Hautefond tombe ici, par ma cascade, et la nôtre file vers la mer. Peut-être jusqu'au Dôme d'Azur. Au fond, dans les quatre mondes, on boit tous la même pluie.", {"sujet_min": ["ile", 2]}),
					L("La petite Pimprenelle, en haut, déteste les champignons. Tom me l'a dit. Je lui garde quand même un champignon bleu dans un bocal, rien que pour le regarder. Je suis sûre qu'elle n'a jamais détesté un champignon qui brille.", {"a_rencontre": "pimprenelle_hf"}, "rire"),
				],
				"rumeur": [
					L("La Docteure Opaline et moi, on a fait un concours : qui brille le plus, ses cristaux ou mes champignons ? Toutes lumières éteintes. Le petit Tom était le jury. Il a dit « les deux ». Opaline dit qu'il fera un excellent diplomate. Moi, je dis qu'il a peur de nous deux.", {}, "rire"),
					L("Fusain, de la Fronde, vient peindre aux Jardins. Paraît que mes champignons ont des couleurs qu'on ne trouve dans aucun pot de peinture. Depuis, les fresques de la Fronde ont des taches qui brillent la nuit. Je ne dirai pas d'où vient le secret.", {}),
					L("Les amoureux des Galeries viennent s'asseoir sur mon banc, le soir, quand tout brille. Ils chuchotent. Les champignons clignotent. Moi, je fais semblant d'arroser. J'arrose beaucoup, le soir.", {}, "rire"),
					L("Rosalie, la marchande d'épices d'en haut, m'a écrit : elle veut vendre mes champignons lumineux au Grand Marché. Je lui ai répondu qu'ils ne se vendent pas, ils se regardent. Elle m'a répondu : « Alors je vendrai des places pour les regarder. » Cette femme est un génie.", {"a_rencontre": "rosalie_hf"}, "rire"),
					L("Tu es allé au Dôme des Serres, au fond de la mer ? Tu as vu Mélisande ? Avec Flora, aux Nuées, on est « les trois jardinières ». Je lui ai envoyé un champignon qui brille, dans un bocal. Il vit au bord de son bassin, paraît-il, et ses nénuphars le trouvent bavard. Maintenant que la Ligne a rouvert, je descends voir son jardin. Elle allume son soleil avec un bouton. Moi, je n'en ai pas du tout. On va bien s'entendre.", {"a_rencontre": "melisande"}, "rire"),
				],
				"interpelle": [L("Chut… doucement… ils se réveillent.", {"visites_max": 0}), L("{surnom} ! Viens voir, il y en a un nouveau qui s'allume !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et s'il pleut en haut, pense à moi : la pluie arrive ici le lendemain.", {}, "salut"), L("Va, petit spore. Et ne mange jamais un champignon qui brille. Même s'il te fait de l'œil.", {}, "rire"), L("Bonne nuit. Les Jardins s'allument. Reste un peu, si tu veux. Le banc est fait pour ça.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Le jour où tu es venu la première fois, la cascade chantait doucement : il faisait beau en haut. C'est comme ça que je range mes souvenirs. Par météo.", {})],
				"boutique": [L("Des champignons bruns pour la soupe, et des graines pour ton jardin d'en haut. Les lumineux, eux, ne se vendent pas : ils se regardent. Tu as {pieces} pièces.", {})],
			}},
		# ================================================================ la Place des Rouages
		{"id": "honorine_st", "nom": "Honorine Lanterne", "titre": "cantinière de La Marmite", "maison": "porte_honorine", "village": "strates",
			"agenda": [[5, 7, "st_marmite_cuisine"], [7, 14, "st_marmite_comptoir"], [14, 16, "st_marmite_cuisine"], [16, 22, "st_marmite_comptoir"], [22, 5, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.7, 0.32, 0.24], "robe": [0.5, 0.25, 0.2], "tablier": [0.95, 0.92, 0.85], "foulard": [0.9, 0.7, 0.2], "taille": 0.96, "carrure": 1.35},
			"teinte": PEAU[5],
			"mj": {"tenue": "cuisinier", "objet": "louche"},
			"humeur_base": 0.65, "traits": {"bavard": 0.85, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"cacao": 2.5, "miel": 2.0, "pomme": 2.0, "champignon": 1.5, "chocolat_chaud": 1.5, "pain_miel": 1.5}, "deteste": {"soda_neon": -1.5, "gelee_slime": -1.5},
			"tics": ["Tu as mangé ?", "Assieds-toi.", "Encore un bol ?", "Ça tient au corps."],
			"surnoms": [[0, "mon petit"], [25, "mon grand"], [50, "mon poussin"], [75, "mon trésor de marmite"], [95, "mon enfant des Strates"]],
			"boutique": {"vend": {"chocolat_mineur": 3, "bouillon_strates": 3, "galette_rouages": 4, "sirop_cascade": 2, "chocolat_chaud": 3, "pain_miel": 3, "tarte_potiron": 6}, "achete": {"champignon": 2, "cacao": 3, "miel": 4, "pomme": 2, "baies": 1, "graines": 1}},
			"repliques": {
				"accueil": [
					L("Entre, entre, ne reste pas dans le courant d'air ! Bienvenue à La Marmite, mon petit. Honorine Lanterne. Ici, on mange chaud, on boit chaud, et on repart le cœur chaud. Soupe, galettes, chocolat. Pas une goutte de boisson forte : sous terre, on garde la tête claire et le pied sûr. Assieds-toi. Tu as mangé ? Non. Je le vois.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te voilà ! Tu as maigri. Si, si. Un peu. Depuis hier. Assieds-toi, je t'apporte un bol.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Ta place est libre. Je te la garde, maintenant. Même Brunehaut n'a pas le droit de s'y asseoir. Elle essaie tous les jours.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Fatiguée. La grande marmite a débordé ce matin. Toute la cuisine sentait le bouillon. Les mineurs ont dit que c'était la meilleure odeur de la semaine. Moi, j'ai frotté jusqu'à midi.", {"humeur_max": -0.2}),
					L("Très bien ! Trois cents bols servis, et pas un seul qui m'est revenu plein. C'est ma façon de compter les bonnes journées.", {}, "rire"),
					L("Un peu inquiète. Depuis que la Ligne a rouvert, il y a des gens d'en haut à toutes mes tables. Très polis. Trop maigres. Ils mangent du bout de la cuillère. Je leur apprends. Doucement. Un bol après l'autre.", {}),
					L("Le matin, j'allume les fourneaux à cinq heures. La première soupe est pour les mineurs, la deuxième pour les forgerons, la troisième pour le petit Tom. Il passe avant tout le monde. Il ne le sait pas. Il croit que c'est le hasard.", {"matin": true}),
					L("Le soir, La Marmite est pleine. On chante un peu, on rit beaucoup, Ferdinand raconte la même histoire de train que d'habitude, et tout le monde fait semblant de ne pas la connaître. C'est ça, une cantine : une maison avec plus de chaises.", {"soir": true}),
				],
				"lui": [
					L("Dans ma famille, on était allumeurs de lanternes. Avant le Soleil de Laiton, il fallait allumer chaque lanterne des Galeries, une par une, matin et soir. Mon arrière-grand-mère connaissait toutes les familles par leur porte. Moi, je les connais par leur assiette. C'est pareil : on s'occupe des gens.", {}),
					L("La Marmite, c'est la cantine des Strates. Les forgerons, les mineurs, les cheminots, les lampistes, et ceux de la Fronde qui traversent le Pont quand la Cantine Libre de Gamelle est fermée. Tout le monde au même banc. Les disputes, on les laisse à la porte, avec les bottes crottées.", {"sujet_min": ["lui", 1]}),
					L("Je vais te dire pourquoi je donne toujours un bol de plus, {surnom}. Quand j'étais petite, l'année de la grande panne, le Soleil de Laiton s'est éteint trois jours. Il faisait noir et froid. Ma mère a ouvert La Marmite jour et nuit. Tout le monde est venu. On a chanté pour se tenir chaud. Depuis, je n'ai jamais fermé ma porte à personne.", {"sujet_min": ["lui", 2]}),
					L("Tu connais Firmin, du Piston Joyeux, en haut ? Il m'a envoyé sa recette de chocolat par la cabine d'Anatole. Je lui ai renvoyé la mienne : le chocolat du mineur, assez épais pour faire tenir la cuillère debout. Il m'a répondu : « Madame, c'est une soupe. » Je l'ai pris comme un compliment.", {"a_rencontre": "firmin"}, "rire"),
				],
				"ile": [
					L("La Marmite est sur la Place des Rouages, juste sous la Grande Horloge. Quand elle sonne midi, toute la caverne descend chez moi. Je l'entends arriver : les bottes sur les pavés, les rires de la Forge. Je remue la soupe en rythme. Ça la rend meilleure.", {}),
					L("Mes champignons viennent des Jardins de Bertille, mon eau de la cascade, ma farine descend d'en haut par la cabine d'Anatole, et mon cacao… c'est un secret. Tout ce qu'il y a dans mon bol vient d'un bout ou de l'autre de la Colonne. Une soupe des quatre mondes. Enfin, de trois, pour l'instant : le Dôme vient de rouvrir, et Josette, de La Conque, m'a promis ses algues.", {"sujet_min": ["ile", 1]}),
					L("Le jour de la réouverture, le Bourgmestre a pris trois bols. Puis il a fait un discours sur la soupe. Je l'ai écouté jusqu'au bout, et je lui ai servi un quatrième bol. Pour qu'il ait la bouche pleine. Ça a très bien marché.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Le petit Barnabé, l'apprenti liftier d'en haut, est descendu pour la réouverture. Tout vert. Je lui ai servi un chocolat du mineur. Il a repris des couleurs en trois gorgées : rouge, rose, puis normal. Il y a des gens comme ça, qu'on a envie de réchauffer.", {"a_rencontre": "barnabe_hf"}),
				],
				"rumeur": [
					L("Maîtresse Brunehaut prend deux bols à midi : un pour elle, et un « pour le marteau-pilon ». Elle dit que c'est une tradition. Le marteau-pilon n'a jamais mangé de soupe de sa vie. Je fais semblant de la croire. On a toutes nos traditions.", {}, "rire"),
					L("Papy Ferdinand vient à treize heures, toujours à la même table, avec sa casquette. Il raconte la fois où Bernadette a fait le tour de la caverne sans lui. Tout le monde connaît l'histoire. Tout le monde rit quand même. C'est une très bonne histoire.", {}),
					L("Gamelle, de la Cantine Libre, à la Fronde, et moi, on s'échange nos recettes. Ses soupes sont à prix libre, les miennes à prix doux. On se dispute sur le sel. Jamais sur le reste. Quelqu'un qui nourrit les gens, c'est de la famille, même de l'autre côté du Gouffre.", {}),
					L("Ysaé, la petite de Rivet et Bielle, venait manger ici après l'école. Elle vidait son bol, puis elle me fabriquait un bijou avec la cuillère. J'ai une boîte pleine de cuillères tordues. Je ne les jetterai jamais. Ce sont ses premières œuvres.", {"a_rencontre": "ysae"}),
				],
				"interpelle": [L("Hé ! Tu as mangé ? Viens, il y a de la soupe !", {"visites_max": 0}, "salut"), L("{surnom} ! Ton bol t'attend !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, mon petit ! Et couvre-toi en remontant : en haut, il y a du vent.", {}, "salut"), L("File ! Mais tu reviens ce soir, hein ? Je fais des galettes.", {}, "rire"), L("Bonne nuit ! Je range les bancs. Il en reste toujours un de travers : celui de Brunehaut.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Mon petit, je me souviens de tous ceux qui ont mangé à ma table. Et toi, tu as saucé ton bol avec ton pain. Ça, je ne l'oublie jamais.", {})],
				"boutique": [L("Chocolat du mineur, bouillon des Strates, galettes des Rouages, sirop de la Cascade, et la tarte du jour ! Tout est chaud, tout est fait ici, et sans une goutte de boisson forte. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "ferdinand_st", "nom": "Papy Ferdinand Vapeur", "titre": "mécanicien et conducteur du Petit Train des Strates", "maison": "porte_ferdinand", "village": "strates",
			"agenda": [[5, 7, "st_train_depot"], [7, 13, "st_train_quai"], [13, 14, "st_marmite_table_3"], [14, 19, "st_train_quai"], [19, 21, "st_train_depot"], [21, 5, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BLEU, "chapeau": "casquette", "chapeau_c": [0.16, 0.16, 0.2], "haut": CHAUFFE, "lunettes": true, "vieux": true, "taille": 0.92, "carrure": 1.1},
			"teinte": PEAU[1],
			"mj": {"tenue": "artisan", "objet": "lanterne"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.75, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"chaussettes_vapeur": 2.5, "chocolat_chaud": 2.5, "cafe_vapeur": 2.0, "engrenage": 2.0, "ressort": 1.5, "biscuit_engrenage": 1.5}, "deteste": {"soda_neon": -1.0, "parapluie_helice": -0.5},
			"tics": ["Tchou-tchou !", "En voiture !", "De mon temps…", "Elle siffle un peu."],
			"surnoms": [[0, "voyageur"], [25, "passager"], [50, "mon chauffeur"], [75, "mon mécano"], [95, "ma chaudière de cœur"]],
			"repliques": {
				"accueil": [
					L("En voiture ! Ah, tu ne montes pas ? Tant pis, bonjour quand même ! Papy Ferdinand Vapeur, mécanicien et conducteur du Petit Train des Strates. Et voici Bernadette, la plus jolie locomotive de la caverne. Elle fait le tour des Strates toute la journée, et elle n'a jamais été en retard. Enfin, si. Mais c'était ma faute.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien, Bernadette est chaude. Tu veux tirer le sifflet ? Un coup. Pas plus. Elle est susceptible.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom} ! Bernadette te reconnaît. Si, si : elle a lâché un petit nuage quand tu es arrivé. Elle ne fait ça que pour ceux qu'elle aime bien. Et pour Honorine.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Grippé. Bernadette tousse, ce matin. Un peu de suie dans la cheminée. Je l'ai ramonée, je lui ai parlé, je lui ai chanté sa chanson. Elle repart. Mais mes genoux, eux, ne repartent pas.", {"humeur_max": -0.2}),
					L("Formidable ! Pas un retard, et un passager d'en haut qui a crié « Encore ! » à la fin du tour. Je lui en ai fait faire un deuxième. Gratuit. Bernadette était ravie.", {}, "rire"),
					L("Un peu nostalgique. Tout à l'heure, j'ai entendu siffler, très loin, par la Colonne. C'était mon ancienne chaudière, chez Firmin. Elle fait du chocolat, maintenant. Elle a bien tourné. Mieux que moi, peut-être.", {}),
					L("Le matin, je réveille Bernadette au dépôt. D'abord le feu, puis la pression, puis un petit coup de chiffon sur le laiton. Elle met une heure à se réveiller. Moi aussi. On se comprend.", {"matin": true}),
					L("Le soir, je ramène Bernadette au dépôt et je lui raconte ma journée. Elle fait « pfff » en refroidissant. C'est sa façon de dire : « Je sais, j'y étais. »", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je conduis le Petit Train depuis cinquante-deux ans. Avant moi, c'était mon père. Avant lui, le sien. Bernadette, elle, a cent ans. C'est la doyenne de la famille. On la respecte. Et on l'astique.", {}),
					L("La machine à chocolat de Firmin, en haut, c'était la chaudière de secours de Bernadette. Une belle chaudière, faite pour une locomotive. Firmin la voulait pour sa taverne. Je lui ai dit : « Elle siffle un peu. » Il a ri. Il ne rit plus quand elle siffle : il sursaute. Mais il l'aime.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret, {surnom}. Je n'ai jamais pris la Ligne d'en haut. Cinquante-deux ans à tourner en rond dans la caverne. La mer, je ne l'ai vue que par en dessous, depuis la bulle du Funiculaire. Pour la voir par au-dessus, Anatole me pousse. Je dis « demain ». Je n'aime pas les trains qui montent tout droit. Ils n'ont pas de virages.", {"sujet_min": ["lui", 2]}),
					L("Tu as goûté le chocolat de Firmin ? Alors tu as goûté ma vieille chaudière ! Dis-lui de bien la détartrer tous les mois, et de lui dire bonjour le matin, avant de la faire siffler. Elle aime ça. Il le fait déjà ? Ah, brave garçon.", {"a_rencontre": "firmin"}, "rire"),
				],
				"ile": [
					L("Le Petit Train fait le tour de la Grande Strate : la Gare, la Place des Rouages, la Forge, l'entrée des Mines, les Jardins, les Galeries. Un tour, vingt minutes, si personne ne traîne sur les rails. Les enfants courent à côté. Bernadette fait semblant de ne pas pouvoir les rattraper.", {}),
					L("Bernadette a été construite ici même, à la Grande Forge, par la grand-mère de Brunehaut. Elle est en laiton, comme le Soleil. Quand le Soleil de Laiton reprend sa force, le matin, elle brille aussi. On dirait qu'ils se disent bonjour.", {"sujet_min": ["ile", 1]}),
					L("La Ligne a rouvert, et les gens d'en haut font la queue pour monter dans mon train. Ils sont étonnés qu'il tourne en rond. « Il ne va nulle part ? » Je leur réponds : « Si : partout. Puis il recommence. » C'est la plus belle façon de voyager. On revient toujours.", {"sujet_min": ["ile", 2]}),
					L("L'horloger d'en haut, Gaspard, est descendu chronométrer Bernadette. Vingt minutes et quatre secondes. Il m'a regardé comme si j'avais commis un crime. Le lendemain, j'ai fait le tour en vingt minutes pile. Il a hoché la tête. Je crois qu'on est amis, maintenant.", {"a_rencontre": "gaspard_hf"}, "rire"),
				],
				"rumeur": [
					L("Anatole, le liftier, n'entend presque plus rien. Mais il sent Bernadette dans ses pieds quand elle passe devant la Gare. Il dit qu'elle a un bon fond. C'est vrai. C'est la chaudière.", {}, "rire"),
					L("Le petit Tom vient me voir rentrer au dépôt tous les soirs. Je lui laisse tirer le sifflet, un coup. Il dit que c'est pour une amie d'en haut. Elle ne l'entend pas. Mais Bernadette siffle un peu plus fort, pour lui. Je le jure.", {}),
					L("La Fronde a repeint mon dépôt, une nuit. Des étoiles, des rails, des notes de musique, et Bernadette avec des lunettes de soleil. J'ai fait semblant d'être fâché. Puis je me suis acheté des lunettes de soleil. On est assortis.", {}, "rire"),
					L("La Capitaine Héloïse, celle du dirigeable, est descendue voir Bernadette. Elle a dit que c'était « un dirigeable qui a peur du vide ». J'ai dit que son dirigeable, c'était « un train qui a perdu ses rails ». On s'est serré la main. Les vieux machinistes se comprennent.", {"a_rencontre": "heloise_hf"}, "rire"),
				],
				"interpelle": [L("En voiture ! … Non ? Bonjour, alors !", {"visites_max": 0}, "salut"), L("{surnom} ! Tchou-tchou ! Bernadette te salue !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bonne route, {surnom} ! Et si tu entends siffler en haut, dis bonjour à ma vieille chaudière.", {}, "salut"), L("À plus tard ! Prochain départ dans vingt minutes. Ou vingt minutes et quatre secondes. Ne le dis pas à Gaspard.", {}, "rire"), L("Bonne nuit ! Bernadette s'endort au dépôt. Elle fait « pfff ». Moi aussi, bientôt.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu as fait un tour entier en tenant ton chapeau, alors qu'on roule à la vitesse d'une poule. C'était très prudent. J'ai apprécié.", {}, "rire")],
			}},
		# ================================================================ la Maison de la Guilde
		{"id": "agathe_st", "nom": "Doyenne Agathe Basalte", "titre": "Doyenne de la Guilde des Strates", "maison": "porte_agathe", "village": "strates", "vouvoie": true,
			"agenda": [[7, 8, "st_guilde_balcon"], [8, 12, "st_guilde_bureau"], [12, 13, "st_place_banc_4"], [13, 17, "st_guilde_bureau"], [17, 19, "st_horloge"], [19, 21, "st_guilde_balcon"], [21, 7, "maison"]],
			"azur": {"cheveux": ARGENT, "coiffure": "chignon", "yeux": Y_GRIS, "haut": [0.28, 0.24, 0.22], "robe": [0.22, 0.19, 0.17], "robe_longue": true, "foulard": [0.62, 0.3, 0.16], "lunettes": true, "vieux": true, "taille": 0.92},
			"teinte": PEAU[3],
			"mj": {"tenue": "noble", "objet": "canne"},
			"humeur_base": 0.45, "traits": {"bavard": 0.35, "humour": 0.85, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"the_menthe": 2.0, "fanzine": 2.0, "caillou": 1.5, "montre_envers": 1.5, "chocolat_chaud": 1.5, "carte_postale": 1.5}, "deteste": {"coupe_course": -0.5, "gelee_slime": -1.0},
			"tics": ["Hm. Intéressant.", "Je surveille.", "Nous verrons.", "La roche a le temps."],
			"surnoms": [[0, "cher visiteur"], [25, "cher hôte"], [50, "cher ami des Strates"], [75, "pierre de ma galerie"], [95, "citoyen d'honneur des Strates"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Agathe Basalte, Doyenne de la Guilde des Strates. On me dit sage. C'est parce que je parle peu. Vous êtes descendu par la Ligne ? Bien. Elle a rouvert pour ça. Pour vous. Et pour quelques autres. Bienvenue.", {"visites_max": 1}, "salut"),
					L("{surnom}. Vous revenez. Les gens d'en haut qui reviennent, je les note dans un carnet. Le carnet est encore très mince. Vous en êtes une page importante.", {"visites_min": 2}),
					L("Ah, {surnom}. Asseyez-vous. Je ne dirai rien pendant une minute. C'est ma façon d'être contente de vous voir. Vous verrez, c'est très reposant.", {"visites_min": 4}),
				],
				"humeur": [
					L("Agacée. Une lettre de la Haute-Ville nous demande de faire « un peu moins de bruit ». J'ai répondu qu'ils pourraient faire un peu moins de silence. Nous en sommes là.", {"humeur_max": -0.2}),
					L("Satisfaite. La Grande Horloge est à l'heure, les fours tournent, la mine est sûre, La Marmite déborde, et la Ligne descend pleine. Je n'ai rien à faire. C'est le signe d'une ville qui marche.", {}),
					L("Amusée. Le Bourgmestre m'a envoyé un discours par la cabine. Douze pages. J'ai répondu par une ligne : « Reçu. Bien. Venez. » Il m'a renvoyé quatorze pages pour me remercier de ma concision.", {}, "rire"),
					L("Le matin, je monte sur le balcon de la Guilde avant tout le monde, et je regarde le Soleil de Laiton reprendre sa force, cercle après cercle. Puis la Forge s'allume. Puis la Place. À huit heures, les Strates sont réveillées. Je descends travailler.", {"matin": true}),
					L("Le soir, du balcon de la Guilde, on voit l'est : le tunnel, le Pont des Frondeurs, et derrière, les lumières de la Fronde qui s'allument. Puis la musique commence. Je surveille. De loin. Avec fierté. Ne le leur dites pas : ils joueraient encore plus fort.", {"soir": true}),
				],
				"lui": [
					L("Je suis née dans les Galeries, au deuxième étage. Mon père était mineur, ma mère lampiste. Moi, j'ai un peu tout fait : apprentie à la Forge, cheminote, vingt ans à la mine. Un jour, la Guilde m'a demandé de devenir Doyenne. J'ai dit : « Je réfléchis. » J'ai réfléchi trente secondes. C'est long, pour moi.", {}),
					L("On me trouve pince-sans-rire. C'est faux : je ris beaucoup. Mais à l'intérieur. Comme la roche : on croit qu'elle ne bouge pas, et elle avance d'un doigt par siècle. Moi, je souris d'un millimètre par an. Cette année, j'en suis à deux.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais vous dire une chose, {surnom}. Il y a cinquante ans, Brasero et une bande de jeunes ont traversé le Gouffre pour fonder la Fronde et vivre à leur façon. Les anciens de la Guilde étaient furieux. Moi, j'étais jeune. J'ai porté leurs premières planches pour le Pont. Je ne l'ai jamais dit à la Guilde. Maintenant, la Guilde, c'est moi. Alors je le dis.", {"sujet_min": ["lui", 2]}),
					L("Vous connaissez le Bourgmestre Hector ? Nous avons fait rouvrir la Ligne ensemble. Il voulait un ruban de trente mètres. J'ai proposé trente centimètres, comme pour les Nuées. Il a soupiré, puis il a coupé avec moi. Ensuite, il a fait un discours de quarante minutes. J'ai répondu en deux phrases. Les gens ont applaudi les deux phrases.", {"a_rencontre": "hector_hf"}, "rire"),
				],
				"ile": [
					L("Les Strates, {surnom}, c'est une ville creusée dans le grès, cent mètres sous Hautefond. Au milieu, la Grande Strate et le Soleil de Laiton. Au nord, les Galeries : deux étages de maisons dans la paroi. À l'ouest, les Mines. Au sud, les Jardins. À l'est, le Pont, et la Fronde. Ici, tout le monde travaille, et tout le monde se connaît. Trop, parfois.", {}),
					L("La Ligne a rouvert après dix ans de travaux. Dix ans de lettres, de réunions et de discours du Bourgmestre. J'ai tenu bon. Ce n'est pas que je voulais voir le haut. C'est que je voulais que le haut nous voie. Maintenant, ils descendent, ils regardent, ils reviennent. C'était le but.", {"sujet_min": ["ile", 1]}),
					L("La Colonne relie quatre mondes : les Nuées, Hautefond, nous, et le Dôme d'Azur au fond de la mer. Les Nuées ont le ciel, Hautefond a la vue, le Dôme a la mer. Nous, nous avons les mains : les rails, les lanternes, les cristaux, et la moitié des boulons de Hautefond. On l'oublie souvent, en haut. Ce n'est pas grave. Le métal s'en souvient.", {"sujet_min": ["ile", 2]}),
					L("Ysaé, la petite de la Fronde qui vend ses bijoux en haut… Elle est venue me voir avant sa première montée. Elle m'a demandé la permission. Je lui ai dit : « Vous n'en avez pas besoin. » Elle a dit : « Je sais. Je voulais vous le dire quand même. » Ce jour-là, j'ai souri de trois millimètres.", {"a_rencontre": "ysae"}),
				],
				"rumeur": [
					L("Brasero, le vieux fondateur de la Fronde, vient prendre le thé à la Guilde une fois par mois. Nous ne sommes d'accord sur rien. Nous ne nous sommes jamais disputés. Il apporte les biscuits, je fournis le thé. C'est notre traité de paix.", {}),
					L("Maîtresse Brunehaut rit si fort que la Grande Horloge s'est déréglée deux fois. J'ai proposé une règle : pas de rire pendant que l'horloge sonne. Elle a ri. L'horloge s'est déréglée une troisième fois. J'ai retiré la règle.", {}, "rire"),
					L("Le contremaître Ludovic m'apporte chaque mois son tableau : « Jours sans accident ». Quatre mille deux cents. Je le félicite. Il répond : « Ce n'est pas moi, c'est la Vieille. » La roche. Il a raison. Mais c'est un peu lui aussi.", {}),
					L("Maîtresse Capucine, la Grande Liftière, m'a dit le jour de la réouverture : « La Colonne est contente de redescendre. » Je lui ai répondu : « Les Strates sont contentes de la revoir. » Nous nous sommes regardées. C'était la conversation la plus sincère de toute la cérémonie.", {"a_rencontre": "capucine_hf"}),
					L("Vous êtes descendu au Dôme ? Vous avez vu la Présidente Ondine ? Pendant les douze ans de travaux, je lui ai écrit une ligne par mois : « Tenez bon. » Cent quarante-quatre fois. Le jour de la réouverture, je lui ai serré la main et j'ai dit : « Bien tenu. » Deux mots. Elle dit que c'est son plus beau compliment. J'ai souri de cinq millimètres. Un record.", {"a_rencontre": "ondine_da"}, "rire"),
				],
				"interpelle": [L("Vous. Bonjour. C'est tout.", {"visites_max": 0}), L("{surnom}. Venez. J'ai une minute de silence pour vous.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Revenez. C'est un conseil de la Guilde. Le seul que je donne gratuitement.", {}, "salut"), L("Allez. Et si on vous demande, en haut, comment c'est, en bas, dites : « Ça travaille, et ça chante. » C'est assez juste.", {}), L("Bonsoir. Je vais surveiller la Fronde depuis le balcon. De loin. Avec fierté. Mais ne le répétez pas.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Vous êtes dans mon carnet, {surnom}. Page sept. Avec une petite étoile. Je n'en ai mis que trois.", {})],
			}},
	]

extends Node

const Brain := preload("res://scripts/pnj/pnj_brain_v31.gd")
## V56 : le carnet de quêtes. Il connaît :
##  - les petites quêtes de Port-Azur (QUETES, ci-dessous) : étapes (parler à quelqu'un,
##    apporter des objets, ramasser des objets posés dans le monde, creuser, faire une
##    course chronométrée, attendre un exploit, avoir rendu assez de services), récompenses
##    (pièces, objets, bonus permanents, réputation, titres, réductions) ;
##  - les quêtes des habitants des autres îles (lues dans leur cerveau : pnj_brain_v31) ;
##  - les grandes aventures du jeu (temple, elfes, fées, nains, ciel, mer), suivies par les
##    « trouvailles » de main._npc_ctx_v31().
## Les habitants proposent les quêtes dans leurs dialogues : main ajoute les sujets du carnet
## (topics_for) à chaque réponse et lui confie les choix « q56:… » (choose).
## Les bonus : cœurs (+1 cœur), endurance, souffle (air sous l'eau sans masque), force
## (dégâts) ; la réputation à Port-Azur donne des réductions chez les commerçants de l'île.

signal changed

const REP_LEVELS := [[0, "Touriste", 0.0], [20, "Visiteur apprécié", 0.05], [50, "Habitué", 0.1], [90, "Ami de Port-Azur", 0.15], [140, "Enfant du pays", 0.2]]

const QUETES := [
	{"id": "bienvenue", "titre": "Bienvenue à Port-Azur", "donneur": "aristide", "lieu": "Port-Azur, la mairie",
		"resume": "Le maire veut que je fasse connaissance avec la ville : la capitainerie, l'hôtel et la taverne.",
		"offre_label": "Que puis-je faire pour Port-Azur ?",
		"offre": "Ah ! Un nouveau venu plein de bonne volonté ! Commencez par faire le tour : saluez Odette à la capitainerie, Edmond à l'hôtel et Toni au Perroquet Bleu. Dites-leur que c'est le maire qui vous envoie. Revenez me voir ensuite.",
		"etapes": [
			{"type": "parler", "pnj": "odette", "label": "Le maire m'envoie vous saluer.", "texte": "Le maire ? Hm. Il envoie tout le monde me saluer. Bon. Bonjour. Le port est à vous, ne faites pas de bêtises.", "objectif": "Saluer Odette à la capitainerie, sur le quai"},
			{"type": "parler", "pnj": "edmond", "label": "Le maire m'envoie vous saluer.", "texte": "Monsieur le maire est trop aimable. Si vous cherchez un lit, nos chambres vous attendent. La nuit passe vite, ici.", "objectif": "Saluer Edmond, à la réception du Grand Hôtel"},
			{"type": "parler", "pnj": "toni", "label": "Le maire m'envoie vous saluer.", "texte": "Aristide t'envoie ? Alors le premier verre est pour moi ! Reviens ce soir, Django joue.", "objectif": "Saluer Toni au Perroquet Bleu"},
			{"type": "rendre", "pnj": "aristide", "label": "J'ai salué tout le monde.", "objectif": "Retourner voir le maire, devant la mairie"},
		],
		"fin": "Parfait, parfait ! Vous voilà presque citoyen. Tenez, quelques pièces, et voici une carte détaillée de notre ville : je l'ai fait ajouter à votre carnet. Et n'hésitez pas à aider nos habitants : Port-Azur sait remercier.",
		"recompense": {"pieces": 20, "rep": 10, "flag": "carte_azur"}},
	{"id": "registre", "titre": "Le registre du port", "donneur": "odette", "lieu": "Port-Azur, la capitainerie",
		"resume": "Odette doit tenir le registre des bateaux. Il lui manque le nom des bateaux de Fernand, de Yannick et de Lucas.",
		"offre_label": "Vous avez l'air débordée.", "si": {"apres": "bienvenue"},
		"offre": "Débordée, oui. Le registre des bateaux doit être à jour pour la saison, et personne ne passe me déclarer son embarcation. Pépé Fernand, Yannick le loueur, et Lucas qui a une barque même s'il dit que non. Demandez-leur le nom de leur bateau. Je vous paierai.",
		"etapes": [
			{"type": "parler", "pnj": "fernand", "label": "Odette veut le nom de votre bateau.", "texte": "Ma barque ? « La Marguerite ». Comme ma femme. Dis-le à Odette, et dis-lui aussi qu'elle peut venir prendre l'anisette.", "objectif": "Demander à Pépé Fernand le nom de sa barque (sur le quai, à l'est)"},
			{"type": "parler", "pnj": "yannick", "label": "Odette veut le nom de vos bateaux.", "texte": "J'en ai six ! « Vague 1 », « Vague 2 »… jusqu'à « Vague 6 ». C'est pratique, non ? Bon, et le pédalo s'appelle « Gérard ». Comme le touriste. Il ne le sait pas.", "objectif": "Demander à Yannick le nom de ses bateaux (location, sur le quai)"},
			{"type": "parler", "pnj": "lucas", "label": "Odette dit que vous avez une barque.", "texte": "Quoi ? Bon… oui. Elle s'appelle « Gertrude ». Comme la caisse numéro douze. Me regarde pas comme ça.", "objectif": "Demander à Lucas, le docker, le nom de sa barque"},
			{"type": "rendre", "pnj": "odette", "label": "Voici les noms des bateaux.", "objectif": "Rapporter les noms à Odette, à la capitainerie"},
		],
		"fin": "« La Marguerite », « Vague 1 » à « Vague 6 », « Gérard » et… « Gertrude » ? Bon. C'est noté. Merci, vraiment. Tenez, pour votre peine.",
		"recompense": {"pieces": 15, "rep": 8}},
	{"id": "pain_du_matin", "titre": "Le pain du matin", "donneur": "margaux", "lieu": "Port-Azur, la boulangerie",
		"resume": "Margaux n'a personne pour livrer le pain à Chez Paulo, au Café de la Place et au Grand Hôtel.",
		"offre_label": "Besoin d'un coup de main ?",
		"offre": "Oh, vous tombez bien ! Mon livreur s'est fait une entorse en jouant à la pétanque. Il faut porter ce panier à Paulo, à Gisèle au café et à Edmond, à l'hôtel. Vous voulez bien ?",
		"donne": [["panier_pain", 1]],
		"etapes": [
			{"type": "parler", "pnj": "paulo", "label": "Le pain de Margaux !", "texte": "Ah ! Le pain ! Sans pain, la bouillabaisse est orpheline. Grazie mille !", "objectif": "Livrer le pain à Paulo (Chez Paulo, sur le quai)"},
			{"type": "parler", "pnj": "gisele", "label": "Le pain de Margaux.", "texte": "Enfin ! Mes clients réclamaient leurs tartines. Merci, et dites à Margaux qu'elle est un ange.", "objectif": "Livrer le pain à Gisèle (Café de la Place)"},
			{"type": "parler", "pnj": "edmond", "label": "Le pain de la boulangerie.", "texte": "Parfait. Le Lord de la douze réclamait ses croissants depuis l'aube. Il nourrit les mouettes avec, mais il les réclame.", "objectif": "Livrer le pain à Edmond (Grand Hôtel)"},
			{"type": "rendre", "pnj": "margaux", "label": "Tout est livré !", "prend": [["panier_pain", 1]], "objectif": "Rapporter le panier vide à Margaux"},
		],
		"fin": "Merci, merci ! Tenez, des croissants tout chauds. Et désormais, chez moi, vous aurez toujours un petit prix.",
		"recompense": {"objets": [["croissant", 4]], "rep": 6, "remise": {"margaux": 0.15}}},
	{"id": "partition", "titre": "La partition envolée", "donneur": "django", "lieu": "Port-Azur",
		"resume": "Le vent a dispersé les trois pages de la plus belle chanson de Django, sur le quai, la place et la plage.",
		"offre_label": "Pourquoi cet air triste ?",
		"offre": "Le vent… il a emporté ma partition. Trois pages. Une est partie vers la plage, une vers la place, une vers l'est du quai. Sans elles, je ne peux plus jouer « La Valse d'Azur ». Si tu les trouves…",
		"etapes": [
			{"type": "ramasser", "objets": {"partition": 3}, "lieux": ["partition_1", "partition_2", "partition_3"], "objectif": "Retrouver les trois pages de la partition (la plage, la place, le quai à l'est)"},
			{"type": "rendre", "pnj": "django", "label": "J'ai retrouvé votre partition.", "prend": [["partition", 3]], "objectif": "Rapporter la partition à Django"},
		],
		"fin": "Mes pages ! Les trois ! … Ce soir, au Perroquet, je joue « La Valse d'Azur » pour toi. Et cette chanson… elle te donnera du souffle, tu verras.",
		"recompense": {"rep": 8, "bonus": {"endurance": 1}, "flag": "valse"}},
	{"id": "cerf_volant", "titre": "Le cerf-volant de Théo", "donneur": "theo", "lieu": "Port-Azur, la plage",
		"resume": "Le cerf-volant de Théo s'est envolé vers les collines de l'ouest.",
		"offre_label": "Pourquoi tu pleures ?",
		"offre": "Mon cerf-volant… Le vent l'a emporté vers la colline, là-bas, au-dessus des maisons. Il est accroché quelque part, j'en suis sûr. Tu peux le retrouver ? S'il te plaît ?",
		"etapes": [
			{"type": "ramasser", "objets": {"cerf_volant": 1}, "lieux": ["cerf_volant"], "objectif": "Retrouver le cerf-volant de Théo sur les collines, à l'ouest de la ville"},
			{"type": "rendre", "pnj": "theo", "label": "Regarde ce que j'ai trouvé !", "prend": [["cerf_volant", 1]], "objectif": "Rendre le cerf-volant à Théo"},
		],
		"fin": "MON CERF-VOLANT ! Merci merci merci ! Tiens, mes plus beaux coquillages. Et papa a dit de te donner ça aussi.",
		"recompense": {"objets": [["coquillage", 3]], "pieces": 10, "rep": 5}},
	{"id": "alliance", "titre": "L'alliance perdue", "donneur": "lea", "lieu": "Port-Azur, la plage",
		"resume": "Hugo a perdu son alliance dans le sable, près de la paillote du Coco Loco, là où arrivent les vagues.",
		"offre_label": "Je peux vous aider ?",
		"offre": "Vous feriez ça ? Hugo a perdu son alliance en jouant dans les vagues, près de la paillote. Elle doit être enfouie dans le sable mouillé. Il faudrait une pelle… et beaucoup de chance.",
		"etapes": [
			{"type": "creuser", "lieu": "alliance", "objet": "alliance", "objectif": "Creuser le sable près de la paillote, au bord de l'eau (pelle en main)"},
			{"type": "rendre", "pnj": "lea", "label": "Est-ce que c'est ceci ?", "prend": [["alliance", 1]], "objectif": "Rapporter l'alliance à Léa"},
		],
		"fin": "C'est elle ! C'est elle ! Hugo ! HUGO ! … Merci. Vous nous avez rendu notre voyage de noces. Ce que vous ressentez, là, au fond du cœur ? C'est du bonheur. Gardez-le.",
		"recompense": {"pieces": 15, "rep": 8, "bonus": {"coeur": 1}}},
	{"id": "voleur", "titre": "Le voleur de croissants", "donneur": "lefort", "lieu": "Port-Azur",
		"resume": "Quelqu'un vole les croissants de Margaux chaque nuit. Le brigadier Lefort veut des témoignages.",
		"offre_label": "Une enquête en cours ?",
		"offre": "Exact. L'affaire des croissants. Chaque nuit, il en manque une demi-douzaine à la boulangerie. J'ai trois témoins : Margaux, sa fille Nina et Bruno le glacier. Interrogez-les. Moi, je surveille… le glacier.",
		"etapes": [
			{"type": "parler", "pnj": "margaux", "label": "Vous avez vu le voleur de croissants ?", "texte": "Non… mais j'ai trouvé des miettes jusqu'à la porte, et des petites traces dans la farine. Des traces… de pattes ?", "objectif": "Interroger Margaux, la boulangère"},
			{"type": "parler", "pnj": "nina", "label": "Tu sais qui vole les croissants ?", "texte": "… D'accord, je te le dis. C'est un petit chien tout blanc ! Il les cache près des caisses, au bout du quai, du côté du phare. Mais tu le gronderas pas, hein ?", "objectif": "Interroger Nina, sur la place"},
			{"type": "parler", "pnj": "bruno", "label": "Vous avez vu passer le voleur ?", "texte": "Une petite ombre blanche, un croissant dans la gueule, qui filait vers les caisses à l'est du quai. Je dirais un chien. Ou un très petit boulanger.", "objectif": "Interroger Bruno, le glacier de la promenade"},
			{"type": "ramasser", "objets": {"croissant": 3}, "lieux": ["croissants"], "objectif": "Fouiller les caisses au bout du quai, côté phare"},
			{"type": "rendre", "pnj": "lefort", "label": "J'ai retrouvé les croissants.", "prend": [["croissant", 3]], "objectif": "Faire votre rapport au brigadier Lefort"},
		],
		"fin": "Un chien ! Je le savais. Enfin, je m'en doutais. Enfin… Affaire classée ! Margaux lui laissera un croissant par jour, et tout le monde sera content. Excellent travail, enquêteur.",
		"recompense": {"pieces": 10, "rep": 10, "bonus": {"force": 1}, "titre": "Fin limier"}},
	{"id": "lentille", "titre": "La lentille du phare", "donneur": "anselme", "lieu": "Port-Azur, la pointe du phare",
		"resume": "La grande lentille du phare a perdu un morceau, tombé dans la mer au pied de la pointe.",
		"offre_label": "Votre phare a un problème ?",
		"offre": "Un éclat de la grande lentille s'est détaché pendant la tempête. Il est tombé dans la mer, au pied de la pointe, côté large. À six mètres de fond, peut-être. Je suis trop vieux pour plonger. Sans lui, mon phare n'éclaire plus la nuit.",
		"etapes": [
			{"type": "ramasser", "objets": {"lentille_phare": 1}, "lieux": ["lentille_phare"], "objectif": "Plonger au pied de la pointe du phare, côté large, et retrouver l'éclat de lentille"},
			{"type": "rendre", "pnj": "anselme", "label": "Voici votre lentille.", "prend": [["lentille_phare", 1]], "objectif": "Rapporter l'éclat de lentille à Anselme, au phare"},
		],
		"fin": "Elle est intacte ! Ce soir, mon phare brillera de nouveau jusqu'au village. Tenez… quand on veille un phare, on apprend à respirer lentement. Je vous apprends : vous tiendrez plus longtemps sous l'eau.",
		"recompense": {"pieces": 15, "rep": 10, "bonus": {"souffle": 1}, "flag": "phare"}},
	{"id": "defi_plongee", "titre": "Le défi du maître-nageur", "donneur": "kevin", "lieu": "Port-Azur, la plage",
		"resume": "Kevin met au défi de remonter trois étoiles de mer du fond de la baie.",
		"offre_label": "C'est quoi, ton défi ?",
		"offre": "Trois étoiles de mer orange, au fond de la baie, devant la plage. Remonte-les toutes les trois et je te reconnais comme un vrai plongeur. Pas besoin de masque, juste du souffle. Allez, champion !",
		"etapes": [
			{"type": "ramasser", "objets": {"etoile_mer": 3}, "lieux": ["etoile_1", "etoile_2", "etoile_3"], "objectif": "Remonter les trois étoiles de mer du fond de la baie, devant la plage"},
			{"type": "rendre", "pnj": "kevin", "label": "Voilà tes trois étoiles !", "prend": [["etoile_mer", 3]], "objectif": "Montrer les étoiles de mer à Kevin, au poste de secours"},
		],
		"fin": "Les trois ! Respect, champion. Je les remets à l'eau, elles sont mieux là-bas. Et toi, tes poumons ont grandi, je le vois.",
		"recompense": {"pieces": 10, "rep": 6, "bonus": {"souffle": 1}}},
	{"id": "course_phare", "titre": "La course du phare", "donneur": "bernard", "lieu": "Port-Azur",
		"resume": "Bernard défie quiconque de courir de la fontaine au phare en moins d'une minute.",
		"offre_label": "Tu me lances un défi ?",
		"offre": "Ha ! De la fontaine de la place jusqu'à la porte du phare, en moins de soixante secondes. Le chrono part quand tu passes près de la fontaine. Tu es prêt ?",
		"etapes": [
			{"type": "course", "depart": "fontaine", "arrivee": "phare_porte", "temps": 60.0, "objectif": "Courir de la fontaine de la place à la porte du phare en moins de 60 secondes"},
			{"type": "rendre", "pnj": "bernard", "label": "J'ai battu ton record !", "objectif": "Annoncer ta victoire à Bernard"},
		],
		"fin": "Moins d'une minute ! Tu as des ailes aux pieds. Tiens, je t'apprends mon secret : bien respirer, et ne jamais regarder en arrière.",
		"recompense": {"rep": 6, "bonus": {"endurance": 1}, "titre": "Pied léger"}},
	{"id": "pigments", "titre": "Les couleurs de Clémence", "donneur": "clemence", "lieu": "Port-Azur, le belvédère",
		"resume": "Clémence veut peindre avec des couleurs naturelles : un corail rouge du fond de la baie, du miel et une noix de coco.",
		"offre_label": "Qu'est-ce qui vous manque ?",
		"offre": "Des vraies couleurs ! Le rouge d'un corail, au fond de la baie, à l'ouest de la plage. Le jaune d'or d'un pot de miel. Et le brun d'une noix de coco. Avec ça, je peindrai la plus belle toile de ma vie.",
		"etapes": [
			{"type": "objets", "pnj": "clemence", "objets": {"corail_rouge": 1, "miel": 1, "noix_coco": 1}, "apparait": ["corail_rouge"], "label": "Voici vos couleurs.", "objectif": "Apporter à Clémence un corail rouge (fond de la baie, à l'ouest), du miel et une noix de coco"},
		],
		"fin": "Le corail ! Le miel ! La noix de coco ! Je vais broyer, mélanger, et… regardez ce rouge ! Tenez, c'est tout ce que j'ai, mais je vous offre aussi mon admiration éternelle.",
		"recompense": {"pieces": 30, "rep": 8, "titre": "Mécène des arts"}},
	{"id": "bouillabaisse", "titre": "La bouillabaisse de Paulo", "donneur": "paulo", "lieu": "Port-Azur, Chez Paulo",
		"resume": "Paulo veut des poissons pêchés du jour : deux dorades et deux maquereaux.",
		"offre_label": "Un souci en cuisine ?",
		"offre": "Un drame ! Il me faut du poisson frais du jour pour ma bouillabaisse du dimanche. Deux dorades, deux maquereaux. Pêchés par toi, je te fais confiance.",
		"etapes": [
			{"type": "objets", "pnj": "paulo", "objets": {"dorade": 2, "maquereau": 2}, "label": "Voici vos poissons.", "objectif": "Pêcher et apporter à Paulo deux dorades et deux maquereaux"},
		],
		"fin": "Magnifique ! Ils sentent encore la mer ! Tiens, trois bols de ma bouillabaisse, et pour toi, chez Paulo, ce sera toujours prix d'ami.",
		"recompense": {"objets": [["bouillabaisse", 3]], "rep": 8, "remise": {"paulo": 0.15}}},
	{"id": "cartes_postales", "titre": "Les cartes postales", "donneur": "nadine", "lieu": "Port-Azur, la poste",
		"resume": "Nadine voudrait que des cartes postales de Port-Azur arrivent aux quatre coins de l'archipel.",
		"offre_label": "Vous rêvez de voyager ?",
		"offre": "Oh oui ! J'ai écrit quatre cartes postales pour des gens dont on parle, ici : Barnabé, le vieux de la jungle ; Lyra, l'elfe ; Ulfa, la tavernière des nains ; et… la reine de la cité engloutie, si elle existe. Vous voyagez beaucoup, vous. Vous voulez bien les porter ?",
		"donne": [["carte_postale", 4]],
		"etapes": [
			{"type": "parler", "pnj": "barnabe", "label": "Une carte postale de Port-Azur pour vous !", "prend": [["carte_postale", 1]], "texte": "Une carte ? Pour moi ? Personne ne m'a écrit depuis… Gaston, regarde, une carte ! Il y a un phare dessus. Je vais la clouer au-dessus de mon hamac.", "objectif": "Porter une carte postale à Barnabé (île de la jungle)"},
			{"type": "parler", "pnj": "lyra", "label": "Une carte postale de Port-Azur.", "prend": [["carte_postale", 1]], "texte": "Une image de la ville des humains, au bord de la mer… Comme c'est étrange, et doux. Remercie celle qui l'a écrite.", "objectif": "Porter une carte postale à Lyra, l'elfe"},
			{"type": "parler", "pnj": "ulfa", "label": "Une carte postale de Port-Azur !", "prend": [["carte_postale", 1]], "texte": "Une carte ? De la surface ? Ha ! Je vais l'accrocher derrière mon comptoir. Les gars vont être jaloux.", "objectif": "Porter une carte postale à Ulfa, à la taverne de Forgefer"},
			{"type": "parler", "pnj": "nerea", "label": "Une carte postale de la surface.", "prend": [["carte_postale", 1]], "texte": "Une image du monde d'en haut… le soleil, les maisons de couleur… Dites à Nadine que la reine de l'Atlantide la remercie. Et qu'elle existe.", "objectif": "Porter une carte postale à la reine de l'Atlantide"},
			{"type": "rendre", "pnj": "nadine", "label": "Toutes vos cartes sont arrivées.", "objectif": "Raconter à Nadine le voyage de ses cartes"},
		],
		"fin": "Toutes ? Même… la reine ? Oh ! J'ai les larmes aux yeux. Vous avez porté un peu de mon cœur jusqu'au bout du monde. Prenez un peu du mien : il est grand, j'en ai trop.",
		"recompense": {"pieces": 10, "rep": 12, "bonus": {"coeur": 1}, "titre": "Globe-trotteur"}},
	{"id": "punch", "titre": "Le punch du Perroquet", "donneur": "toni", "lieu": "Port-Azur, le Perroquet Bleu",
		"resume": "Toni n'a plus de noix de coco pour son célèbre punch.",
		"offre_label": "Il te manque quelque chose ?",
		"offre": "Trois noix de coco, et mon punch revit ! Le bateau de la jungle n'est pas passé. Tu peux en trouver chez Colette, ou sous les cocotiers de la jungle.",
		"etapes": [
			{"type": "objets", "pnj": "toni", "objets": {"noix_coco": 3}, "label": "Voici trois noix de coco.", "objectif": "Apporter trois noix de coco à Toni"},
		],
		"fin": "Ah ! Le parfum ! Tiens, trois punchs, et quelques pièces. Au Perroquet, tu es chez toi.",
		"recompense": {"objets": [["punch_coco", 3]], "pieces": 10, "rep": 5}},
	{"id": "collectionneur", "titre": "Le collectionneur", "donneur": "pemberton", "lieu": "Port-Azur, le Grand Hôtel",
		"resume": "Lord Pemberton paierait cher une vraie curiosité : une plume de l'aigle géant, une écaille de naga, ou une dent de requin.",
		"offre_label": "Que cherchez-vous, milord ?",
		"offre": "Une curiosité authentique, my friend ! Une plume de l'aigle géant des nains, une écaille du serpent-naga des profondeurs… ou, à défaut, une dent de requin. Apportez-m'en une, et je vous paierai en or.",
		"etapes": [
			{"type": "un_de", "pnj": "pemberton", "objets": ["plume_ventaile", "ecaille_naga", "dent_requin"], "label": "J'ai une vraie curiosité pour vous.", "objectif": "Apporter à Lord Pemberton une plume de Ventaile, une écaille de naga ou une dent de requin"},
		],
		"fin": "Extraordinary ! Elle sera la reine de ma collection. Voici deux pièces d'or, frappées par mon arrière-grand-père. Cheers !",
		"recompense": {"objets": [["piece_or", 2]], "rep": 6}},
	{"id": "horloge", "titre": "L'horloge arrêtée", "donneur": "hortense", "lieu": "Port-Azur, la mairie",
		"resume": "L'horloge de la place est arrêtée : il lui faut un rouage neuf, que seul Hector peut forger.",
		"offre_label": "Que se passe-t-il, avec l'horloge ?",
		"offre": "Un rouage s'est brisé dans le mécanisme. Hector, l'armurier, pourrait en forger un neuf. Mais il dit toujours qu'il n'a pas le temps. Vous voulez bien lui parler ?",
		"etapes": [
			{"type": "parler", "pnj": "hector", "label": "Hortense a besoin d'un rouage.", "texte": "Un rouage ? Pour l'horloge ? … Bon. Apporte-moi deux bûches pour chauffer la forge, et trois cailloux pour le moule. Je ferai le reste.", "objectif": "Parler à Hector, l'armurier (rue du Phare)"},
			{"type": "objets", "pnj": "hector", "objets": {"buche": 2, "caillou": 3}, "label": "Voici les bûches et les cailloux.", "texte": "Bien. … (Hector frappe, chauffe, frappe encore.) … Voilà. Un rouage de bronze, aussi précis qu'une montre de capitaine. Porte-le à Hortense.", "donne": [["rouage", 1]], "objectif": "Apporter à Hector deux bûches et trois cailloux"},
			{"type": "rendre", "pnj": "hortense", "label": "Voici le rouage d'Hector.", "prend": [["rouage", 1]], "objectif": "Porter le rouage à Hortense, devant la mairie"},
		],
		"fin": "Il est parfait… Attendez… Écoutez ! Tic, tac… et… DONG ! Elle sonne ! Après tant d'années ! Merci, merci… Vous avez rendu son cœur à la place.",
		"recompense": {"rep": 10, "bonus": {"force": 1}, "titre": "Maître des heures", "flag": "horloge"}},
	{"id": "cochonnet", "titre": "Le cochonnet perdu", "donneur": "raymond", "lieu": "Port-Azur, la place",
		"resume": "Raymond et Marcel ont perdu leur cochonnet, du côté de la fontaine.",
		"offre_label": "Un problème avec la partie ?",
		"offre": "Un problème ? Une catastrophe ! Marcel a tiré comme un manche et le cochonnet a filé du côté de la fontaine. Plus moyen de le retrouver. Sans cochonnet, pas de pétanque. Sans pétanque, pas de vie.",
		"etapes": [
			{"type": "ramasser", "objets": {"cochonnet": 1}, "lieux": ["cochonnet"], "objectif": "Retrouver le cochonnet, près de la fontaine de la place"},
			{"type": "rendre", "pnj": "raymond", "label": "Voilà votre cochonnet.", "prend": [["cochonnet", 1]], "objectif": "Rendre le cochonnet à Raymond"},
		],
		"fin": "Sous le banc ! Marcel, il était sous le banc ! … Merci, petit. Tiens, quelques pièces. Et quand tu veux, on t'apprend à pointer.",
		"recompense": {"pieces": 8, "rep": 5}},
	{"id": "photo", "titre": "La photo perdue", "donneur": "gerard", "lieu": "Port-Azur",
		"resume": "Gérard Dupuis a oublié son appareil photo au belvédère, en haut de la colline.",
		"offre_label": "Vous avez perdu quelque chose ?",
		"offre": "Mon appareil photo ! Je l'ai posé au belvédère, en haut de la colline, pour photographier le coucher de soleil, et je suis redescendu sans lui. Mes jambes ne veulent pas remonter. Vous voulez bien ?",
		"etapes": [
			{"type": "ramasser", "objets": {"appareil_photo": 1}, "lieux": ["appareil_photo"], "objectif": "Récupérer l'appareil photo de Gérard au belvédère (en haut du chemin des collines)"},
			{"type": "rendre", "pnj": "gerard", "label": "Votre appareil photo !", "prend": [["appareil_photo", 1]], "objectif": "Rendre l'appareil photo à Gérard"},
		],
		"fin": "Mon appareil ! Et… vous avez pris une photo avec ? Ah non. Tant mieux. Tenez, pour la grimpette.",
		"recompense": {"pieces": 20, "rep": 5}},
	{"id": "secret_atlantide", "titre": "Le secret de l'Atlantide", "donneur": "moreau", "lieu": "Port-Azur, le Grand Hôtel",
		"resume": "Le professeur Moreau rêve de la cité engloutie. Il faudrait la trouver, rallumer son cristal, et lui raconter.",
		"offre_label": "Parlez-moi de votre Atlantide.",
		"offre": "Toute ma vie, j'ai cherché la cité engloutie. Les textes parlent d'un grand cristal qui donnait l'air et la lumière. Si un jour vous trouvez cette cité, si vous voyez ce cristal briller… revenez me le raconter. Je vous en supplie.",
		"etapes": [
			{"type": "etat", "cle": "cristal", "objectif": "Trouver l'Atlantide et rallumer son Grand Cristal"},
			{"type": "rendre", "pnj": "moreau", "label": "J'ai vu l'Atlantide.", "objectif": "Raconter l'Atlantide au professeur Moreau"},
		],
		"fin": "Elle existe… Elle existe ! Une reine, un dôme, un cristal qui chante… Quarante ans de moqueries, et j'avais raison ! Prenez ceci, c'est tout mon salaire de vacances. Et retenez ceci : les Atlantes respiraient lentement. Faites comme eux.",
		"recompense": {"pieces": 40, "rep": 10, "bonus": {"souffle": 1}, "titre": "Archéologue"}},
	{"id": "citoyen", "titre": "Citoyen d'honneur", "donneur": "aristide", "lieu": "Port-Azur, la mairie",
		"resume": "Le maire fera citoyen d'honneur celui qui rendra service à toute la ville.",
		"offre_label": "Comment devenir citoyen de Port-Azur ?", "si": {"apres": "bienvenue"},
		"offre": "Citoyen d'honneur, ça se mérite ! Rendez service à nos habitants : dix services, et je vous remets la clé de la ville devant tout le monde, avec fanfare. Enfin, avec Django.",
		"etapes": [
			{"type": "quetes", "n": 10, "objectif": "Accomplir dix quêtes pour les habitants de Port-Azur"},
			{"type": "rendre", "pnj": "aristide", "label": "J'ai aidé toute la ville.", "objectif": "Retourner voir le maire"},
		],
		"fin": "Mesdames et messieurs ! Port-Azur reconnaît aujourd'hui l'un des siens ! Voici la clé de la ville. Désormais, tous nos commerçants vous feront un prix, et vous aurez toujours une place à nos terrasses. Et dans nos cœurs. Django, la musique !",
		"recompense": {"objets": [["cle_ville", 1]], "rep": 20, "bonus": {"coeur": 1}, "titre": "Citoyen d'honneur de Port-Azur", "remise": {"tout": 0.1}}},
	# V58 : le royaume des fées
	{"id": "graine_yggdrasil", "titre": "La graine d'Yggdrasil", "donneur": "oriane", "lieu": "Le royaume des fées", "sorte": "Royaume des fées",
		"resume": "Yggdrasil, l'Arbre-Monde, ne donne plus de graines depuis cent ans : des plantes méchantes ont envahi son tronc. La reine Oriane voudrait la graine qui dort tout en haut de l'arbre.",
		"offre_label": "Vous avez l'air inquiète, Majesté.",
		"offre": "Inquiète, oui. Yggdrasil n'a plus donné de graine depuis cent ans. Une ronce est entrée dans son cœur, et toutes les plantes de l'arbre sont devenues méchantes. Sans graine, pas de nouvel Arbre-Monde… et un jour, les îles se faneront. Nous, les fées, sommes trop petites pour ce combat. Toi, peut-être… Si tu acceptes, l'arbre t'ouvrira sa porte. Monte jusqu'à sa couronne, et rapporte-nous la graine.",
		"etapes": [
			{"type": "etat", "cle": "graine_ygg", "objectif": "Entrer dans Yggdrasil par la porte aux runes, traverser ses trois salles jusqu'à la Couronne et recevoir la graine"},
			{"type": "rendre", "pnj": "oriane", "label": "Voici la graine d'Yggdrasil, Majesté.", "prend": [["graine_yggdrasil", 1]], "objectif": "Rapporter la graine à la reine Oriane, dans la clairière des fées"},
		],
		"fin": "La graine… Elle respire ! Cent ans que nous l'attendions. Nous la planterons dans la clairière, et dans mille ans, un nouvel Yggdrasil veillera sur les îles. Pour te remercier, je t'offre ce que les fées ont de plus précieux : la magie de voyager. Pense très fort à un lieu que tu as déjà vu… et tu y seras.",
		"recompense": {"pieces": 60, "titre": "Ami des fées", "flag": "teleportation"}},
	# V59 : Carène, le port dans l'épave du Léviathan
	{"id": "porte_scellee", "titre": "La Porte aux Quatre Sceaux", "donneur": "matthias", "lieu": "Carène, la capitainerie", "sorte": "Carène",
		"resume": "Matthias, le cartographe de Carène, rêve de dessiner le cœur de l'île. Il voudrait savoir à quoi ressemble la grande porte scellée, au pied du Cœur-de-Pierre.",
		"offre_label": "Que cherchez-vous sur cette carte ?",
		"offre": "Le milieu ! Regarde : tout autour, j'ai dessiné les côtes, les landes, les marais, les dunes… et au centre, un grand blanc. Le Cœur-de-Pierre. Au pied de sa face ouest, il y a une porte, la Porte aux Quatre Sceaux. Je n'ai jamais osé y monter seul : on dit que la montagne respire. Toi, tu as l'air de ne pas avoir peur. Va la voir, examine-la bien, et reviens me raconter.",
		"etapes": [
			{"type": "etat", "cle": "porte_sceaux", "objectif": "Monter vers le centre de l'île (à l'est de Carène) et examiner la grande porte, au pied du Cœur-de-Pierre"},
			{"type": "rendre", "pnj": "matthias", "label": "J'ai vu la Porte aux Quatre Sceaux.", "objectif": "Raconter à Matthias ce que j'ai vu (capitainerie de Carène, sur la dunette)"},
		],
		"fin": "Quatre creux ronds… vides. Et un cercle qui luit ! Alors Corentin disait vrai : quatre sceaux, un pour chaque peuple de l'île. Tiens, voilà pour ta peine, et ma carte de l'île, recopiée pour toi. Un jour, il faudra aller voir les bergers du nord, les gens des brumes et les caravaniers du sud. Et retrouver notre sceau à nous.",
		"recompense": {"pieces": 40, "flag": "carte_grande_ile"}},
	{"id": "calfatage", "titre": "Le bois de Tobias", "donneur": "tobias", "lieu": "Carène, l'entrepont", "sorte": "Carène",
		"resume": "Tobias, le calfat, doit reboucher une voie d'eau dans la coque du Léviathan. Il lui faut du bon bois.",
		"offre_label": "Il vous faut du bois ?",
		"offre": "Il me faut du bois, oui. Une voie d'eau s'est ouverte sous la forge, à bâbord : rien de grave, mais si je ne la bouche pas, Jos finira la semaine les pieds dans l'eau. Quatre bûches. Du bon bois, pas du bois flotté. Une hache, un arbre, et tu reviens.",
		"etapes": [
			{"type": "objets", "pnj": "tobias", "objets": {"buche": 4}, "label": "Voici quatre bûches.", "texte": "Ça, c'est du bois. Bien sec, bien droit.", "objectif": "Rapporter 4 bûches à Tobias (une hache et un arbre suffisent), dans l'entrepont du Léviathan"},
		],
		"fin": "La voie d'eau est bouchée. Le Léviathan te remercie, et moi aussi. Tiens, des pièces, et la galette que Gwenola m'a donnée ce matin. Je n'ai plus faim, je suis content.",
		"recompense": {"pieces": 25, "objets": [["galette_sarrasin", 2]]}},
	# V60 : Tazira, le port des sables
	{"id": "carte_croc", "titre": "La carte de Croc-de-Sel", "donneur": "croc", "lieu": "Tazira, le pont de la Murène Noire", "sorte": "Tazira",
		"resume": "Un chat roux a volé la carte au trésor du Capitaine Croc-de-Sel, le pirate amarré à Tazira. Les chats, ça monte…",
		"offre_label": "Qu'est-ce que ce chat vous a volé ?",
		"offre": "Ma carte ! La carte de mon grand-père, le Capitaine Sel ! Je l'avais posée sur un tonneau, sur le quai, le temps d'allumer ma pipe. Un chat roux a sauté dessus, l'a prise dans sa gueule, et hop : une caisse, une autre caisse, un toit. Je ne grimpe pas sur les toits, moi, j'ai le vertige. Retrouve-la, et tu auras ta part. Une petite part. Mais une part.",
		"etapes": [
			{"type": "ramasser", "objets": {"carte_tresor": 1}, "lieux": ["carte_tresor"], "objectif": "Retrouver la carte volée par le chat roux : il grimpe sur les toits de Tazira par des caisses, près des maisons du quai, à l'est de la place"},
			{"type": "rendre", "pnj": "croc", "label": "Voici votre carte, capitaine.", "prend": [["carte_tresor", 1]], "objectif": "Rapporter la carte au Capitaine Croc-de-Sel (sur le pont de la Murène Noire le jour, à La Murène Ivre le soir)"},
		],
		"fin": "MA CARTE ! Un peu mâchonnée, un peu sentant la sardine… mais c'est elle ! Regarde : la falaise, les grottes, la croix. Derrière la Skala, j'en étais sûr ! Tiens, ta part, moussaillon. Et une bouteille de Mama Lou. Si un jour tu veux signer sur la Murène, il y a toujours un hamac pour toi.",
		"recompense": {"pieces": 50, "objets": [["rhum_murene", 2]], "titre": "Ami des pirates"}},
	{"id": "tajine_zohra", "titre": "Le tajine du vendredi", "donneur": "zohra", "lieu": "Tazira, la criée", "sorte": "Tazira",
		"resume": "Zohra, la poissonnière, veut faire son grand tajine du vendredi. Il lui faut deux belles dorades, pêchées par quelqu'un d'autre que les hommes de la criée.",
		"offre_label": "Je peux vous aider pour le tajine ?",
		"offre": "Tu ferais ça ? Mon tajine du vendredi, c'est toute une affaire : il me faut deux dorades, des belles, des fraîches. Pas celles de Saïd : il leur crie dessus toute la matinée, elles ont la chair stressée. Pêche-les toi-même, ou trouve-les, mais rapporte-m'en deux. Et tu goûteras le meilleur tajine de toute l'île.",
		"etapes": [
			{"type": "objets", "pnj": "zohra", "objets": {"dorade": 2}, "label": "Voici deux dorades.", "texte": "Oh, qu'elles sont belles ! L'œil clair, les ouïes rouges… Parfait. Reviens dans trois heures. Non, je plaisante : j'en avais un sur le feu.", "objectif": "Apporter 2 dorades à Zohra, à la criée de Tazira (une canne à pêche, au bout de la jetée par exemple)"},
		],
		"fin": "Tiens, goûte. … Alors ? Je le savais. Le safran vient de chez Aïcha, le citron confit de chez ma mère, et les dorades… de chez toi. Prends-en un pour la route, et ces quelques pièces. Et reviens vendredi.",
		"recompense": {"pieces": 15, "objets": [["tajine_poisson", 2]]}},
	# V61 : Cliquetis, la cité des ingénieurs fous
	{"id": "engrenage_or", "titre": "L'engrenage d'or", "donneur": "cogne", "lieu": "Cliquetis, la Foire des Inventions", "sorte": "Cliquetis",
		"resume": "Firmin Cogne a perdu l'engrenage d'or de son moteur perpétuel pendant une démonstration. Il a roulé jusqu'en bas des falaises, vers le port.",
		"offre_label": "Pourquoi votre moteur s'est-il arrêté ?",
		"offre": "Parce qu'il lui manque son cœur ! L'engrenage d'or de mon grand-père : quatorze dents, de l'or massif, mon nom gravé dessus. Pendant la démonstration d'hier, il a sauté de son axe, il a roulé sur la place, il a passé la balustrade… et il est tombé de la falaise. Jusqu'au port, je crois. Moi, j'ai le vertige, et le téléphérique me donne le mal de mer. Vous voulez bien aller voir ?",
		"etapes": [
			{"type": "ramasser", "objets": {"engrenage_or": 1}, "lieux": ["engrenage_or"], "objectif": "Descendre au port de Cliquetis (téléphérique ou route en lacet) et retrouver l'engrenage d'or, près de la grue"},
			{"type": "rendre", "pnj": "cogne", "label": "Voici votre engrenage d'or.", "prend": [["engrenage_or", 1]], "objectif": "Rapporter l'engrenage à Firmin Cogne, à son stand de la Foire"},
		],
		"fin": "Mon engrenage ! Pas une dent de cassée ! Regardez… je le remets… je tourne la manivelle… IL TOURNE ! Il tourne ! Pour toujours ! Ou au moins jusqu'à la fin de la Foire. Tenez, prenez ça, et ce chapeau : il a un ventilateur. Je ne sais pas pourquoi je l'avais, mais il est à vous.",
		"recompense": {"pieces": 40, "objets": [["chapeau_ventilateur", 1]]}},
	{"id": "jury_foire", "titre": "Le jury de la Foire", "donneur": "heloise", "lieu": "Cliquetis, l'Académie des Ingénieurs", "sorte": "Cliquetis",
		"resume": "Héloïse Manivelle, ingénieure-en-chef, préside le jury de la Foire des Inventions. Il lui faut l'avis d'un visiteur sans parti pris.",
		"offre_label": "Puis-je aider le jury de la Foire ?",
		"offre": "Vous tombez à pic ! Je préside le jury de la Foire, et tous les membres du jury ont une invention en compétition. C'est un petit problème. Il me faudrait l'avis de quelqu'un d'impartial : vous. Allez voir le piano mécanique de Prudence, la machine à bulles de Basile et l'automate d'Ambroise. Parlez-leur, regardez bien, puis revenez me dire ce que vous en pensez.",
		"etapes": [
			{"type": "parler", "pnj": "prudence", "label": "Le jury m'envoie voir votre piano.", "texte": "Le jury ? Oh ! Écoutez… (Le piano joue une valse. Les touches s'enfoncent toutes seules. À la fin, le piano salue.) Il joue mieux le matin. Il est un peu enrhumé le soir.", "objectif": "Écouter le piano mécanique de Prudence Touche (stand de la Foire, côté ouest)"},
			{"type": "parler", "pnj": "basile", "label": "Le jury m'envoie voir votre machine.", "texte": "Regardez ! Trois mille bulles par minute ! Et celle-là… celle-là est en forme de cœur. Je ne sais pas comment je fais. Dites au jury qu'on sourit trente-quatre pour cent plus près de ma machine.", "objectif": "Admirer la machine à bulles de Basile Bulle (stand de la Foire, côté ouest)"},
			{"type": "parler", "pnj": "ambroise", "label": "Le jury m'envoie voir votre automate.", "texte": "Une partie ? Non ? Regardez-le jouer contre lui-même, alors. … Match nul. Il est vexé. Ne dites pas au jury qu'il est vexé.", "objectif": "Voir l'automate joueur d'échecs d'Ambroise Échec (stand de la Foire, au sud)"},
			{"type": "rendre", "pnj": "heloise", "label": "J'ai vu les trois inventions.", "objectif": "Donner votre avis à Héloïse Manivelle, devant l'Académie"},
		],
		"fin": "Un piano enrhumé, des bulles en forme de cœur et un automate vexé. C'est exactement ce que je pensais : ils ont tous gagné. Je vais créer trois prix. Merci, juré ! Vous méritez votre titre. Et prenez cette montre : elle tourne à l'envers, mais elle est d'une précision… à l'envers.",
		"recompense": {"pieces": 30, "titre": "Juré de la Foire", "objets": [["montre_envers", 1]]}},
	{"id": "toit_boum", "titre": "Un toit pour le professeur Boum", "donneur": "boum", "lieu": "Cliquetis, l'atelier du professeur Boum", "sorte": "Cliquetis",
		"resume": "Le professeur Boum a encore perdu le toit de son atelier. Pour le quinzième, il lui faut du minerai de fer.",
		"offre_label": "Votre atelier n'a plus de toit ?",
		"offre": "Plus de toit, plus de porte, plus de sourcils ! Mon quinzième toit, je veux le faire en fer. En fer épais. Il me faut trois blocs de minerai de fer. Les bergers du nord en vendent, les nains de la Montagne de Feu aussi, et on en trouve en creusant dans les rochers. Rapportez-m'en trois, et je vous donne… quelque chose. Quelque chose de joli. Qui n'explose pas.",
		"etapes": [
			{"type": "objets", "pnj": "boum", "objets": {"minerai_fer": 3}, "label": "Voici trois blocs de minerai de fer.", "texte": "Magnifique ! Du fer bien lourd. Avec ça, mon toit tiendra au moins… une semaine !", "objectif": "Apporter 3 minerais de fer au professeur Boum, devant son atelier (à l'ouest de Cliquetis, près des falaises)"},
		],
		"fin": "Voilà ! Le quinzième toit sera le bon. Tenez, ces lunettes : des kaléidoscopes. Le monde entier devient une rosace. C'est inutile, c'est merveilleux, et ça n'explose pas. Enfin, je crois.",
		"recompense": {"pieces": 25, "objets": [["lunettes_kaleido", 1]]}},
	# V62 : Ramure, le village des oreilles
	{"id": "lanternes_lune", "titre": "Les lanternes de lune", "donneur": "merelune", "lieu": "Ramure, le Chêne-Mère", "sorte": "Ramure",
		"resume": "Mère-Lune, la doyenne de Ramure, change chaque printemps les lanternes de lune des ponts. Ses vieilles pattes ne vont plus jusqu'au bord des mares, où poussent les champignons qui luisent.",
		"offre_label": "Que sont ces lanternes bleues, sur les ponts ?",
		"offre": "Des lanternes de lune, petit. Dedans, il y a un champignon des mares qui luit la nuit, doux et bleu, comme un morceau de lune. Chaque printemps, je les remplace. Cette année, mes pattes ne descendent plus jusqu'à l'eau… Il en pousse cinq, au bord des cinq mares de la forêt, autour du village. Tu me les rapporterais ? Cueille-les délicatement : ils sont timides.",
		"etapes": [
			{"type": "ramasser", "objets": {"champignon_lune": 5}, "lieux": ["champi_lune_1", "champi_lune_2", "champi_lune_3", "champi_lune_4", "champi_lune_5"], "objectif": "Cueillir les cinq champignons de lune, au bord des mares de la forêt autour de Ramure (la grande mare à l'ouest du Cercle, la mare de la Clairière des Jeux, celles de l'ouest, du sud et du nord)"},
			{"type": "rendre", "pnj": "merelune", "label": "Voici vos cinq champignons de lune.", "prend": [["champignon_lune", 5]], "objectif": "Rapporter les champignons à Mère-Lune (devant sa maison, au milieu du Chêne-Mère, ou au Cercle de la Lune la nuit)"},
		],
		"fin": "Cinq… et tous intacts. Regarde comme ils brillent, même en plein jour. Cette nuit, les ponts de Ramure seront bleus comme autrefois. Tu as le cœur doux, petit, et les mains aussi. Tiens : des oreilles de renard, cousues par Pivoine. Mets-les, et tout Ramure saura que tu es des nôtres.",
		"recompense": {"pieces": 30, "titre": "Ami de la Lune", "objets": [["oreilles_renard", 1]]}},
	{"id": "grande_course", "titre": "La Grande Course", "donneur": "pepin", "lieu": "Ramure, la Clairière des Jeux", "sorte": "Ramure",
		"resume": "Pépin, le lapin qui organise la Grande Course de Ramure, cherche quelqu'un capable de battre Bondi, le champion depuis trois ans.",
		"offre_label": "Je peux courir la Grande Course ?",
		"offre": "Tu veux courir ? Vraiment ? Formidable ! La règle est simple : tu pars de l'arche, là, tu passes sous les dix arches de lanternes, dans l'ordre, tout autour du village, et tu reviens ici. Bondi, Grisou et Éclair courent avec toi. Arrive le premier, et ton nom ira tout en haut du tableau des records. Personne n'a battu Bondi depuis trois ans. Personne n'a vraiment essayé, remarque.",
		"etapes": [
			{"type": "etat", "cle": "course_ramure", "objectif": "Gagner la Grande Course : prendre le départ sous l'arche de la Clairière des Jeux (E), passer sous les dix arches dans l'ordre et revenir le premier"},
			{"type": "rendre", "pnj": "pepin", "label": "J'ai gagné la Grande Course !", "objectif": "Annoncer la victoire à Pépin, à la Clairière des Jeux"},
		],
		"fin": "TU AS GAGNÉ ! Devant Bondi ! Bondi a les oreilles toutes plates, regarde-le ! Je vais peindre ton nom tout en haut du tableau, en lettres de lanterne. Tiens, la coupe de la Grande Course : elle est en bois de chêne-mère, et elle n'a jamais quitté Bondi depuis trois ans. Elle va bien s'amuser avec toi.",
		"recompense": {"pieces": 35, "titre": "Pattes de Vent", "objets": [["coupe_course", 1]]}},
	{"id": "grand_troc", "titre": "Le Grand Troc", "donneur": "bedaine", "lieu": "Ramure, le Marché aux trocs", "sorte": "Ramure",
		"resume": "Bedaine, le tanuki du Marché aux trocs, veut t'apprendre le Grand Troc : un caillou qui, d'échange en échange, devient un trésor.",
		"offre_label": "C'est quoi, le Grand Troc ?",
		"offre": "Ho ho ! Le Grand Troc, c'est une chaîne, mon ami. Je te donne ce caillou-qui-chante : écoute, quand le vent passe dedans, il siffle. Tu vas le troquer contre quelque chose de mieux, puis ce quelque chose contre quelque chose de mieux encore… Pomme-de-Pin, la charpentière, adore les cailloux-qui-chantent. Commence par elle. Et à la fin, reviens me voir : je veux savoir ce que mon caillou est devenu !",
		"donne": [["caillou_chantant", 1]],
		"etapes": [
			{"type": "objets", "pnj": "pommedepin", "objets": {"caillou_chantant": 1}, "label": "Bedaine vous troque ce caillou-qui-chante.", "texte": "Un caillou-qui-chante ! Écoute-le siffler ! Je l'accroche sous le pont de l'ouest dès ce soir. Tiens, mon plus beau gland d'or, trouvé à la cime du Chêne-Mère. Plumette, la postière, en raffole.", "donne": [["gland_dore", 1]], "objectif": "Troquer le caillou-qui-chante avec Pomme-de-Pin, la charpentière des ponts (sur l'arbre de l'ouest le matin, près de la grande mare l'après-midi)"},
			{"type": "objets", "pnj": "plumette", "objets": {"gland_dore": 1}, "label": "Un gland d'or contre une plume ?", "texte": "Hou ! Un gland d'or ! Je le mettrai sur mon guichet, il portera chance au courrier. Voilà une plume de lune : elle tombe de nos ailes les nuits de pleine lune. C'est-à-dire toutes les nuits, ici. Pivoine en cherche pour ses fioles.", "donne": [["plume_lune", 1]], "objectif": "Troquer le gland d'or avec Plumette, à la Poste, tout en haut du Chêne-Mère"},
			{"type": "objets", "pnj": "pivoine", "objets": {"plume_lune": 1}, "label": "Une plume de lune pour vos fioles ?", "texte": "Une plume de lune ! Avec ça, ma brume ne s'envolera plus. Tiens, une fiole de brume : de la brume du matin, en bouteille. Ursule dit qu'elle en a besoin pour tremper l'argent. Je ne pose pas de questions aux ours.", "donne": [["fiole_brume", 1]], "objectif": "Troquer la plume de lune avec Pivoine, l'herboriste, à l'échoppe des Simples (au milieu du Chêne-Mère)"},
			{"type": "objets", "pnj": "ursule", "objets": {"fiole_brume": 1}, "label": "Une fiole de brume, pour la forge ?", "texte": "… De la brume. Bien. On trempe l'argent dedans : il chante plus clair. Tiens. Une clochette d'argent. Je l'avais faite pour rien. Maintenant elle est pour toi.", "donne": [["clochette_argent", 1]], "objectif": "Troquer la fiole de brume avec Ursule, la forgeronne (la forge des ours, au sud-est du village)"},
			{"type": "rendre", "pnj": "bedaine", "label": "Votre caillou est devenu une clochette d'argent !", "prend": [["clochette_argent", 1]], "objectif": "Rapporter la clochette d'argent à Bedaine, au Marché aux trocs (en bas du Chêne-Mère)"},
		],
		"fin": "Une clochette d'argent ! Écoute… ting ! Tu vois ? Un caillou au début, une clochette à la fin, et en chemin, quatre amis contents. Voilà le Grand Troc. Tu es un vrai tanuki, maintenant. Tiens, mon grelot de tanuki : on l'accroche à la ceinture, et tous les marchands de Ramure te feront un clin d'œil.",
		"recompense": {"pieces": 30, "titre": "Roi du troc", "objets": [["grelot_tanuki", 1]]}},
	# V63 : la grande enquête des Quatre Sceaux, à travers les quatre villages de la grande île
	{"id": "quatre_sceaux", "titre": "La grande enquête des Quatre Sceaux", "donneur": "matthias", "lieu": "Carène, la capitainerie", "sorte": "Carène", "si": {"apres": "porte_scellee"},
		"resume": "Matthias rêve d'ouvrir la Porte aux Quatre Sceaux. Il faut retrouver les quatre sceaux, un par peuple de la grande île : les embruns de Carène, les sables de Tazira, l'airain des bergers du nord, les brumes de Ramure. Chaque sceau mène au suivant.",
		"offre_label": "Et si on retrouvait les quatre sceaux ?",
		"offre": "Les quatre sceaux ? Tu veux… vraiment ? Ha ! Je savais que tu étais de ceux qui finissent les cartes ! Écoute : personne ici ne sait où ils sont. Mais le Vieux Corentin connaît toutes les vieilles histoires de Carène. Va le voir : sur le pont près de la cloche le jour, à La Dernière Bordée le soir. Moi, je garde un coin de carte bien propre pour le Cœur-de-Pierre.",
		"etapes": [
			{"type": "parler", "pnj": "corentin", "label": "Matthias m'envoie : que savez-vous des quatre sceaux ?",
				"texte": "Les quatre sceaux… Assieds-toi, petit. Il y a deux cents ans, la montagne s'est réveillée : le Cœur-de-Pierre battait si fort que la mer tremblait jusqu'ici. Les quatre peuples sont descendus sous la montagne et ont endormi ce qui battait là-dessous. Puis ils ont fermé la porte, et chacun est reparti avec un sceau. Le nôtre, le Sceau des Embruns, le dernier capitaine du Léviathan l'a caché quelque part à bord. Où ? Il l'a écrit dans son journal de bord… que mon grand-père a vendu, un hiver de famine, à un conteur de Tazira. Ba Sidi, qu'il s'appelait. Il doit être bien vieux, s'il vit encore.",
				"objectif": "Écouter le Vieux Corentin, le conteur de Carène (sur le pont du Léviathan, ou à La Dernière Bordée le soir)"},
			{"type": "parler", "pnj": "basidi", "label": "Corentin, de Carène, cherche le journal de bord du Léviathan.",
				"texte": "Corentin ? Le petit-fils de Yann-le-Borgne ? Ha ! Oui, j'ai le journal. Le voici… Mais regarde : les pages qui parlent du sceau sont blanches. De l'encre de lune, disaient les marins : elle ne se lit qu'au clair d'une lune que l'on porte avec soi. Je n'ai jamais compris. Garde-le, il te parlera peut-être un jour. Et puisque tu cours après les sceaux : le nôtre, celui du désert, dort sous la dune qui marche. Rachid, le marchand de tapis, a un tapis ancien qui en montre le chemin. Il te le dira… s'il arrête de parler de ses prix.",
				"donne": [["journal_bord", 1]],
				"objectif": "Retrouver Ba Sidi, le conteur de Tazira (sur la place des Lanternes), qui a le journal de bord du Léviathan"},
			{"type": "parler", "pnj": "rachid", "label": "Ba Sidi dit que vous avez un tapis ancien qui montre le chemin du sceau.",
				"texte": "Le tapis des étoiles ? Il n'est pas à vendre. Bon. À toi, je le montre. Regarde : la porte de la ville, en bas. Puis trois étoiles, l'une après l'autre, qui marchent vers le nord-est, vers les dunes. Ce sont les vieilles bornes des caravanes : la nuit, elles s'allument encore toutes seules, va savoir pourquoi. Après la troisième, la dune en croissant : la dune qui marche. Et sous la dune, un soleil. Sur la bordure, trois signes, toujours dans le même ordre : l'étoile, la dune, le soleil. Ma grand-mère disait : « c'est la clé ». Moi, je dis : c'est joli.",
				"objectif": "Écouter Rachid, le marchand de tapis du souk de Tazira, parler du tapis des étoiles"},
			{"type": "etat", "cle": "sceau_sables",
				"objectif": "Sortir de Tazira par la porte du nord, suivre les trois bornes des caravanes vers le nord-est (elles s'allument la nuit), ouvrir le tombeau de la Dune qui Marche (l'étoile, la dune, le soleil) et prendre le Sceau des Sables"},
			{"type": "parler", "pnj": "celeste", "label": "Dans le tombeau du désert, une fresque montre une bergerie sous la montagne.",
				"texte": "Une bergerie sous la montagne ? Montrez-moi… Des moutons, une roue dentée, une crête. Mais je la connais ! Avec ma grande lunette, je vois tout le versant nord du Cœur-de-Pierre. Au sud-est de la cité, au pied de la montagne, il y a une grotte : la Bergerie du Vent, disent les bergers. Ils n'y vont plus depuis que des ronces noires en ferment l'entrée. Des ronces qui ne brûlent pas, paraît-il… Enfin, qui ne brûlent pas avec un briquet ordinaire.",
				"objectif": "Montrer la fresque du tombeau à Céleste Lunette, l'astronome de Cliquetis (à son observatoire)"},
			{"type": "etat", "cle": "sceau_airain",
				"objectif": "Trouver la Bergerie du Vent, au pied du Cœur-de-Pierre au sud-est de Cliquetis, brûler ses ronces avec la Flamme (touche 2 puis X ; en VR, B), et prendre le Sceau d'Airain"},
			{"type": "parler", "pnj": "merelune", "label": "Dans la Bergerie du Vent, j'ai vu une lune au-dessus d'une mare et d'une vanne.",
				"texte": "… Alors la lune t'a parlé, à toi aussi. Écoute bien. Quand les anciens ont rapporté le sceau des brumes, ils l'ont couché au fond de la grande mare, sur une pierre ronde, et ils ont fermé la vieille vanne pour que l'eau le garde. La vanne, c'est un mécanisme de bronze, au bord ouest de la mare, que plus personne ne sait faire tourner. Si le sceau d'airain t'obéit, il la fera tourner. Quand l'eau sera basse, attends la lune : le sceau ne se montre qu'à elle.",
				"objectif": "Raconter la fresque de la Bergerie à Mère-Lune, la doyenne de Ramure"},
			{"type": "etat", "cle": "sceau_brumes",
				"objectif": "Faire tourner la vieille vanne de la grande mare de Ramure avec le Rouage (touche 3 puis X ; en VR, B), puis, la nuit, prendre le Sceau des Brumes sur la pierre ronde, au fond de la mare"},
			{"type": "etat", "cle": "journal_lu",
				"objectif": "Lire les pages blanches du journal de bord à la Lueur de lune (touche 4 puis X ; en VR, B), le journal dans le sac"},
			{"type": "etat", "cle": "sceau_embruns",
				"objectif": "Montrer les trois sceaux à la Dame de Proue, la figure de proue du Léviathan (tout à l'avant du pont, près de la longue-vue)"},
			{"type": "etat", "cle": "porte_ouverte",
				"objectif": "Poser les quatre sceaux dans la Porte aux Quatre Sceaux, au pied du Cœur-de-Pierre"},
			{"type": "rendre", "pnj": "matthias", "label": "La Porte aux Quatre Sceaux est ouverte !",
				"objectif": "Annoncer à Matthias que la Porte aux Quatre Sceaux est ouverte (capitainerie de Carène)"},
		],
		"fin": "Ouverte ?! OUVERTE ! Deux cents ans fermée, et c'est toi… Attends, je note. « Porte aux Quatre Sceaux : ouverte. Par… » Je mettrai « par le voyageur ». Tiens : tout ce que j'avais économisé pour l'expédition que je n'ai jamais osé faire. Et maintenant, descends. Dessine-moi ce qu'il y a là-dessous. Mais reviens. Les cartographes ont besoin qu'on revienne.",
		"recompense": {"pieces": 120, "titre": "Gardien des Sceaux", "objets": [["galette_sarrasin", 3]]}},
	# V67 : Arcanelle, l'île des sorciers : on y apprend six sorts, un par maître
	{"id": "arc_academie", "titre": "L'apprenti d'Arcanelle", "donneur": "archimage", "lieu": "Arcanelle, l'Académie", "sorte": "Arcanelle",
		"resume": "L'archimage Séraphine Astrelune veut bien me prendre comme apprenti. Il me faut un grimoire, et faire la connaissance des apprentis.",
		"offre_label": "Je voudrais apprendre la magie.",
		"offre": "Apprendre la magie ? … Le Cristal a frémi. Bon signe. Écoute : tout apprenti commence par un grimoire. Va voir Théophraste, à la bibliothèque : il t'en donnera un, tout neuf, aux pages blanches. Puis présente-toi à Pip : c'est le plus jeune des apprentis, et le plus bavard ; il te montrera tout. Reviens me voir ensuite, dans la cour du Grand Cristal.",
		"etapes": [
			{"type": "parler", "pnj": "theophraste", "label": "L'archimage m'envoie chercher un grimoire.", "texte": "Un grimoire ? … (Théophraste disparaît entre deux rayonnages et revient avec un gros livre de cuir violet.) Voilà. Les pages sont blanches : c'est vous qui les écrirez. Chaque sort que vous apprendrez s'y inscrira tout seul. Ne le cornez pas.", "donne": [["grimoire", 1]], "objectif": "Demander un grimoire à Théophraste Filandre, à la bibliothèque (le grand bâtiment d'ardoise, sur la montée de l'Académie)"},
			{"type": "parler", "pnj": "pip", "label": "Bonjour ! Je suis le nouvel apprenti.", "texte": "Un nouveau ! Génial ! Viens, je te montre : là, le dortoir, Oscar ronfle ; là-bas, l'Aire des Duels, Pyra crie ; en bas, le Chaudron Fumant, Berthe fait des tartes ; et là-haut, l'Observatoire, Lumen dort le jour. Six maîtres, six sorts ! Moi j'en ai zéro. Mais bientôt un !", "objectif": "Faire la connaissance de Pip, le plus jeune des apprentis (dans la cour de l'Académie le matin, sur la place du bourg le soir)"},
			{"type": "rendre", "pnj": "archimage", "label": "J'ai mon grimoire, et Pip m'a tout montré.", "objectif": "Retourner voir l'archimage, dans la cour du Grand Cristal"},
		],
		"fin": "Bien. Te voilà apprenti d'Arcanelle. Écoute : six maîtres, six sorts. Aurélien Lumen t'apprendra la lumière, Pyra le feu, Borée le gel, Zéphyrine la lévitation, Théophraste la télékinésie, et Mère Sauge le soin. Chacun te demandera quelque chose : la magie ne se donne pas, elle s'échange. Quand ton grimoire aura ses six sorts, reviens me voir.",
		"recompense": {"pieces": 10, "titre": "Apprenti d'Arcanelle", "flag": "apprenti_arc"}},
	{"id": "arc_lumiere", "titre": "Fiat lux", "donneur": "lumen", "lieu": "Arcanelle, l'Observatoire", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Aurélien Lumen m'apprendra le sort de lumière si je lui rapporte trois éclats de lune tombés sur l'île. Ensuite, il faudra réveiller les runes de la Crypte.",
		"offre_label": "Vous m'apprendriez la lumière ?",
		"offre": "La lumière ! Le premier des sorts ! Écoutez : pour l'apprendre, il faut d'abord tenir un peu de vraie lumière dans la main. Les éclats de lune : il en est tombé trois cette saison. Un près de l'autel du Cercle des Pierres-Lunes, un dans le Bois Tors, un sur la grève de l'ouest. Rapportez-les-moi, et je vous apprendrai à faire naître la vôtre.",
		"etapes": [
			{"type": "ramasser", "objets": {"eclat_lune": 3}, "lieux": ["eclat_lune_1", "eclat_lune_2", "eclat_lune_3"], "objectif": "Ramasser les trois éclats de lune : près de l'autel du Cercle des Pierres-Lunes (à l'ouest de l'Académie), dans le Bois Tors (au sud-ouest) et sur la grève de l'ouest"},
			{"type": "objets", "pnj": "lumen", "objets": {"eclat_lune": 3}, "sort": "lumiere", "label": "Voici les trois éclats de lune.", "texte": "Regardez-les briller dans vos mains… Maintenant, fermez les yeux. Pensez au matin, à la première lueur sur la mer. Ouvrez la main. … Voilà ! Une petite lumière, à vous. Elle vous suivra. Allez donc l'essayer dans la Crypte aux Runes : les trois runes du fond ne se montrent qu'à elle.", "objectif": "Apporter les trois éclats de lune à Aurélien Lumen (près de l'Observatoire, au nord-ouest de l'Académie ; à la bibliothèque l'après-midi)"},
			{"type": "etat", "cle": "lecon_lumiere", "objectif": "Réveiller les trois runes de la Crypte aux Runes avec le sort de lumière (touche 5 puis V ; en VR, gâchette gauche) : la crypte est au-dessus du jardin, sur le chemin du Bois Tors"},
			{"type": "rendre", "pnj": "lumen", "label": "Les trois runes de la crypte brillent !", "objectif": "Le dire à Aurélien Lumen"},
		],
		"fin": "Les trois runes ! « Fiat lux » : « que la lumière soit ». C'est la devise de l'Académie, et désormais c'est un peu la vôtre. Gardez ces pièces. Et revenez voir les étoiles avec moi, une nuit : c'est encore plus beau avec quelqu'un qui sait faire de la lumière.",
		"recompense": {"pieces": 25}},
	{"id": "arc_feu", "titre": "Le cœur des braseros", "donneur": "pyra", "lieu": "Arcanelle, l'Aire des Duels", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Pyra Flammèche m'apprendra la boule de feu si je lui rapporte trois bûches de bois tordu. Ensuite, il faudra allumer les cinq braseros de l'Aire des Duels d'affilée.",
		"offre_label": "Apprenez-moi le feu !",
		"offre": "Le feu ! Enfin quelqu'un qui demande le feu et pas la lumière ! Bon. Règle numéro un : le feu se nourrit. Va me chercher trois bûches de bois tordu, dans le Bois Tors, au sud-ouest. Le bois tordu brûle longtemps et sans fumée. Rapporte-les, et je t'apprends.",
		"etapes": [
			{"type": "ramasser", "objets": {"buche": 3}, "lieux": ["buche_arc_1", "buche_arc_2", "buche_arc_3"], "objectif": "Ramasser trois bûches de bois tordu dans le Bois Tors (au sud-ouest de l'île)"},
			{"type": "objets", "pnj": "pyra", "objets": {"buche": 3}, "sort": "feu", "label": "Voici trois bûches de bois tordu.", "texte": "Parfait. (Pyra pose une bûche dans sa main nue et souffle dessus : elle s'enflamme.) À toi. Tends la main. Sens la chaleur. Ne la retiens pas : pousse-la devant toi. … HA ! Une boule de feu ! Une petite, mais une vraie ! Maintenant, les cinq braseros de l'Aire. Tous les cinq, d'affilée : chacun s'éteint au bout d'une minute et demie.", "objectif": "Apporter trois bûches à Pyra Flammèche (à l'Aire des Duels, à l'est de l'Académie)"},
			{"type": "etat", "cle": "lecon_feu", "objectif": "Allumer les cinq braseros de l'Aire des Duels d'affilée avec la boule de feu (touche 6 puis V ; en VR, gâchette gauche), avant que le premier ne s'éteigne"},
			{"type": "rendre", "pnj": "pyra", "label": "Les cinq braseros brûlent !", "objectif": "Le dire à Pyra Flammèche"},
		],
		"fin": "J'ai vu ! Cinq braseros, et pas un sourcil roussi ! Tu es plus doué qu'Oscar. Bon, ce n'est pas difficile. Tiens, des pièces, et un conseil : le feu, on ne le lance jamais vers quelqu'un qu'on aime. Sauf Borée. Borée, ça ne compte pas.",
		"recompense": {"pieces": 25}},
	{"id": "arc_gel", "titre": "Le chemin de glace", "donneur": "boree", "lieu": "Arcanelle, le Lac Miroir", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Borée Givrelin m'apprendra le gel si je lui rapporte trois flocons de givre éternel des falaises du nord. Ensuite, il faudra traverser le Lac Miroir jusqu'au Cristal de Givre.",
		"offre_label": "Pouvez-vous m'apprendre le gel ?",
		"offre": "Le gel. Hm. Il faut de la patience. Vous en avez ? On va voir. Sur les falaises du nord, là où le vent ne s'arrête jamais, tombent des flocons qui ne fondent pas : le givre éternel. Rapportez-m'en trois. Sans courir. Le givre n'aime pas qu'on coure.",
		"etapes": [
			{"type": "ramasser", "objets": {"flocon_givre": 3}, "lieux": ["flocon_1", "flocon_2", "flocon_3"], "objectif": "Ramasser trois flocons de givre éternel sur les falaises du nord de l'île"},
			{"type": "objets", "pnj": "boree", "objets": {"flocon_givre": 3}, "sort": "gel", "label": "Voici trois flocons de givre éternel.", "texte": "Ils n'ont pas fondu. Vous avez marché doucement. Bien. Tenez la paume ouverte. Soufflez dessus, lentement, comme sur une soupe trop chaude. … Voilà. Le froid vous écoute. Maintenant, le lac. Sur l'îlot dort le Cristal de Givre. Demandez au lac de durcir sous vos pas, et allez le toucher.", "objectif": "Apporter les trois flocons à Borée Givrelin (au bord du Lac Miroir, au nord-est de l'Académie)"},
			{"type": "etat", "cle": "lecon_gel", "objectif": "Traverser le Lac Miroir sur un chemin de glace (sort de gel, touche 7 puis V, tourné vers l'îlot ; en VR, gâchette gauche) et toucher le Cristal de Givre (E)"},
			{"type": "rendre", "pnj": "boree", "label": "J'ai touché le Cristal de Givre.", "objectif": "Le dire à Borée Givrelin"},
		],
		"fin": "Le cristal a brillé. Je l'ai vu d'ici. Il ne brille pas pour tout le monde. Tenez. Des pièces. Et quand vous aurez chaud, l'été, pensez au lac. Il pensera à vous.",
		"recompense": {"pieces": 25}},
	{"id": "arc_levitation", "titre": "La cloche de la Tour Penchée", "donneur": "zephyrine", "lieu": "Arcanelle, la Tour Penchée", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Zéphyrine Plume m'apprendra la lévitation si je lui rapporte trois plumes du vent. Ensuite, il faudra faire sonner la cloche au sommet de la Tour Penchée.",
		"offre_label": "Je voudrais voler !",
		"offre": "Voler ? Presque ! Léviter. C'est mieux : on ne se cogne pas aux mouettes. Pour apprendre, il faut d'abord sentir le vent dans la main. Le vent perd des plumes quand il tourne trop vite : rapporte-m'en trois. Elles se posent là où il souffle le plus fort : sur la colline de l'ouest, au bord des falaises du nord, et sur la falaise de l'est, au-dessus de la mer.",
		"etapes": [
			{"type": "ramasser", "objets": {"plume_vent": 3}, "lieux": ["plume_vent_1", "plume_vent_2", "plume_vent_3"], "objectif": "Ramasser trois plumes du vent : sur la colline de l'ouest, au bord des falaises du nord, et sur la falaise de l'est"},
			{"type": "objets", "pnj": "zephyrine", "objets": {"plume_vent": 3}, "sort": "levitation", "label": "Voici trois plumes du vent.", "texte": "Oh, elles sont belles ! Tiens-les contre toi. Ferme les yeux. Ne pense pas à monter : pense à ne plus peser. … Tu vois ? Tes pieds ! Ils ne touchent plus rien ! Maintenant, la Tour Penchée : sa cloche n'a pas sonné depuis la grande tempête, l'escalier s'est effondré. Mais toi, tu n'as plus besoin d'escalier.", "objectif": "Apporter les trois plumes à Zéphyrine Plume (au pied de la Tour Penchée, au sud de l'île)"},
			{"type": "etat", "cle": "lecon_levitation", "objectif": "Monter au sommet de la Tour Penchée en lévitant (touche 8 puis V ; en VR, gâchette gauche) et faire sonner la cloche (E)"},
			{"type": "rendre", "pnj": "zephyrine", "label": "La cloche de la Tour Penchée a sonné !", "objectif": "Le dire à Zéphyrine Plume"},
		],
		"fin": "Je l'ai entendue ! Toute l'île l'a entendue ! Même Borée a levé la tête ! Tiens, des pièces pour toi. Et reviens léviter avec moi au coucher du soleil : d'en haut, la mer devient toute rose.",
		"recompense": {"pieces": 25}},
	{"id": "arc_telekinesie", "titre": "Les livres envolés", "donneur": "theophraste", "lieu": "Arcanelle, la bibliothèque", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Théophraste Filandre m'apprend la télékinésie. Quatre de ses livres se sont envolés pendant la grande tempête et sont coincés là où personne ne peut monter : il faut les faire redescendre.",
		"offre_label": "Vos livres envolés… je peux aider ?",
		"offre": "Mes livres… Quatre. Pendant la grande tempête, ils se sont envolés par la fenêtre. Un est sur le toit de la bibliothèque. Un autre sur la plus haute des Pierres-Lunes. Le troisième sur le rebord d'une fenêtre de la Tour Penchée. Le dernier dans un grand chêne tordu du Bois Tors. Personne ne peut y monter. Mais on peut les appeler. Je vais vous apprendre.",
		"etapes": [
			{"type": "parler", "pnj": "theophraste", "sort": "telekinesie", "label": "Je suis prêt à apprendre.", "texte": "Regardez ce livre, sur l'étagère. Ne tendez pas le bras : tendez l'envie. Voulez-le. Doucement. … Il vient ! Il vient ! Attrapez-le ! Parfait. Visez, et appelez : le livre volera jusqu'à vous. Maintenant, allez me chercher les quatre fugitifs.", "objectif": "Apprendre la télékinésie avec Théophraste Filandre, à la bibliothèque"},
			{"type": "ramasser", "objets": {"livre_envole": 4}, "lieux": ["livre_toit", "livre_menhir", "livre_tour", "livre_arbre"], "objectif": "Faire redescendre les quatre livres envolés par télékinésie (touche 9 puis V, en visant le livre ; en VR, gâchette gauche) : sur le toit de la bibliothèque, sur la plus haute Pierre-Lune du Cercle, à une fenêtre de la Tour Penchée et dans un grand chêne du Bois Tors"},
			{"type": "rendre", "pnj": "theophraste", "label": "Voici vos quatre livres envolés.", "prend": [["livre_envole", 4]], "objectif": "Rapporter les quatre livres à Théophraste Filandre"},
		],
		"fin": "Tous les quatre ! Le traité des nuages, l'herbier des ombres, la grammaire des corbeaux et… « Recettes de Berthe, tome deux ». Je l'avais oublié, celui-là. Merci. Vraiment. Tenez, des pièces. Et vous pourrez emprunter n'importe quel livre, quand vous voudrez. Sans le corner.",
		"recompense": {"pieces": 30}},
	{"id": "arc_soin", "titre": "L'aile de la chouette", "donneur": "sauge", "lieu": "Arcanelle, le Jardin des simples", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Mère Sauge m'apprendra le sort de soin si je lui rapporte trois champignons du Bois Tors. Ensuite, il faudra soigner la chouette blessée qui vit près de la roulotte d'Agathe.",
		"offre_label": "Vous pourriez m'apprendre à soigner ?",
		"offre": "Soigner ? Oh, mon petit, c'est la plus belle des magies. Mais il faut d'abord apprendre à connaître ce qui soigne. Va me cueillir trois champignons dans le Bois Tors : les bruns au pied blanc, pas les autres. Les autres font chanter faux.",
		"etapes": [
			{"type": "ramasser", "objets": {"champignon": 3}, "lieux": ["champi_arc_1", "champi_arc_2", "champi_arc_3"], "objectif": "Cueillir trois champignons des bois dans le Bois Tors (au sud-ouest de l'île)"},
			{"type": "objets", "pnj": "sauge", "objets": {"champignon": 3}, "sort": "soin", "label": "Voici trois champignons du Bois Tors.", "texte": "Les bons ! Tu as l'œil. Donne-moi tes mains. Elles sont chaudes, c'est bien. Pense à quelqu'un que tu aimes, très fort, et pose ta main sur ton cœur. … Tu sens ? C'est ça, le soin. Maintenant, va voir la chouette blessée, près de la roulotte d'Agathe, dans le Bois Tors. Elle ne se laisse approcher par personne. Toi, peut-être.", "objectif": "Apporter les trois champignons à Mère Sauge (au jardin des simples, au sud de l'Académie)"},
			{"type": "etat", "cle": "lecon_soin", "objectif": "Soigner la chouette blessée du Bois Tors avec le sort de soin (touche 0 puis V, tout près d'elle ; en VR, gâchette gauche)"},
			{"type": "rendre", "pnj": "sauge", "label": "La chouette s'est envolée !", "objectif": "Le dire à Mère Sauge"},
		],
		"fin": "Elle s'est envolée ? Oh, mon petit… Tu as les mains douces et le cœur aussi. Tiens, des pièces, et une plume qu'elle a laissée sur mon toit ce matin : elle était venue te remercier, je crois.",
		"recompense": {"pieces": 25, "objets": [["chouette_plume", 1]]}},
	{"id": "arc_diplome", "titre": "Le Cercle des Pierres-Lunes", "donneur": "archimage", "lieu": "Arcanelle, le Cercle des Pierres-Lunes", "sorte": "Arcanelle", "si": {"apres": "arc_academie"},
		"resume": "Quand j'aurai appris les six sorts des maîtres d'Arcanelle, l'archimage me conduira au Cercle des Pierres-Lunes pour la cérémonie.",
		"offre_label": "Et après les six sorts ?",
		"offre": "Après les six sorts ? La cérémonie, au Cercle des Pierres-Lunes. Tu poseras la main sur l'autel, et les neuf pierres décideront. Elles n'ont jamais dit non. Mais apprends d'abord les six sorts : la lumière, le feu, le gel, la lévitation, la télékinésie et le soin.",
		"etapes": [
			{"type": "etat", "cle": "six_sorts", "objectif": "Apprendre les six sorts des maîtres d'Arcanelle : la lumière, le feu, le gel, la lévitation, la télékinésie et le soin"},
			{"type": "etat", "cle": "ceremonie", "objectif": "Aller au Cercle des Pierres-Lunes (à l'ouest de l'Académie) et poser la main sur l'autel (E)"},
			{"type": "rendre", "pnj": "archimage", "label": "Les Pierres-Lunes ont chanté.", "objectif": "Retourner voir l'archimage"},
		],
		"fin": "Elles ont chanté pour toi. Je les ai entendues jusqu'ici. Alors c'est dit : tu es sorcier d'Arcanelle. Tiens, ton bâton : du bois du Bois Tors et un cristal du Cercle. En main, il rend tes sorts plus légers. Et ta magie est plus grande désormais. Va, sorcier. Le monde a besoin de lumière, de feu, de glace, de vent, de patience et de soin. Surtout de soin.",
		"recompense": {"pieces": 60, "titre": "Sorcier d'Arcanelle", "objets": [["baton_sorcier", 1]], "flag": "diplome_arc"}},
	# V68 : l'Île de la Balafre, Port-Coutelas et ses pirates
	{"id": "bal_perroquet", "titre": "Rhubarbe s'est envolé", "donneur": "anne_rose", "lieu": "La Balafre, le Requin Borgne", "sorte": "Balafre",
		"resume": "Rhubarbe, le perroquet rouge de la capitaine Anne-Rose Corbeau, s'est envolé vers le vieux camp abandonné, au nord-ouest de l'île. Perroquet-Joe saura comment l'attirer.",
		"offre_label": "Ton perroquet… je peux le chercher ?",
		"offre": "Tu ferais ça ? … Rhubarbe. Rouge comme un coucher de soleil, mal élevé comme un mousse. Il s'est envolé il y a trois jours vers la jungle du nord. Joe l'a entendu jurer du côté du vieux camp abandonné. Les araignées y ont fait leur nid, fais attention. Va d'abord voir Joe, sur la place : il sait parler aux oiseaux mieux qu'aux hommes.",
		"etapes": [
			{"type": "parler", "pnj": "joe", "label": "Comment attirer le perroquet de la capitaine ?", "texte": "Rhubarbe ? Ha ! Il ne descend pour personne. Sauf pour ça. (Il te tend un petit sachet.) Des graines de tournesol grillées au sel. Montre-les-lui, et ne le regarde pas dans les yeux : il déteste ça. Et s'il te traite de tête de méduse, c'est qu'il t'aime bien.", "donne": [["graines", 1]], "objectif": "Demander conseil à Perroquet-Joe (son étal est sur la place de Port-Coutelas, près du puits)"},
			{"type": "etat", "cle": "perroquet_trouve", "objectif": "Retrouver Rhubarbe au vieux camp abandonné (au nord-ouest, par le sentier du camp), et l'appeler au pied de son perchoir avec les graines (E)"},
			{"type": "rendre", "pnj": "anne_rose", "label": "Voici Rhubarbe, capitaine.", "objectif": "Ramener Rhubarbe à la capitaine Anne-Rose Corbeau (à la barre du Requin Borgne, le jour ; au Crâne Fendu à midi)"},
		],
		"fin": "RHUBARBE ! (L'oiseau saute sur son épaule et lui mordille l'oreille : « Mille sabords ! ») … Bon. Tu n'as rien vu. Une capitaine ne pleure pas. Tiens, des pièces, et une de ses plumes : celle-là, il l'a perdue en me mordant le jour où je l'ai trouvé. Tu es l'ami du Requin Borgne, maintenant.",
		"recompense": {"pieces": 40, "rep": 5, "objets": [["plume_perroquet", 1]]}},
	{"id": "bal_dette", "titre": "La dette de Jambe-de-Bois", "donneur": "mama_grog", "lieu": "La Balafre, le Crâne Fendu", "sorte": "Balafre",
		"resume": "Gontran Lestrange, dit Jambe-de-Bois, le capitaine de la Veuve Écarlate, doit quarante pièces à Mama Grog depuis trois lunes. Elle veut sa bourse.",
		"offre_label": "Quelqu'un te doit de l'argent ?",
		"offre": "Quelqu'un ? TOUT LE MONDE me doit de l'argent, mon chou. Mais un seul me doit quarante pièces depuis trois lunes : Gontran Lestrange, Jambe-de-Bois, le capitaine de la Veuve Écarlate. Va lui réclamer ma bourse. Poliment, d'abord. Et s'il fait le malin… ici, on règle ça à la loyale, avec les poings. Mais ne le casse pas trop : il boit beaucoup.",
		"etapes": [
			{"type": "parler", "pnj": "lestrange", "label": "Mama Grog réclame ses quarante pièces.", "texte": "Ses quarante pièces ?! Elle les aura quand la mer sera sèche ! … Quoi ? Tu insistes ? Écoute-moi bien, terrien : soit tu paies ma dette toi-même, soit tu me la prends à la loyale, aux poings. Personne n'a jamais mis Gontran Lestrange au tapis. Personne.", "objectif": "Réclamer la dette à Gontran Lestrange, dit Jambe-de-Bois (sur la Veuve Écarlate, le jour ; à la Dent du Requin, le soir)"},
			{"type": "rendre", "pnj": "mama_grog", "label": "Voici la bourse de Jambe-de-Bois.", "prend": [["bourse_lestrange", 1]], "objectif": "Obtenir la bourse de Jambe-de-Bois (payer sa dette, ou le battre en duel à la loyale), puis l'apporter à Mama Grog, au Crâne Fendu"},
		],
		"fin": "Ma bourse ! Quarante pièces, le compte est bon. (Elle mord une pièce.) Et elles sont vraies, en plus. Toi, mon chou, tu es le bienvenu au Crâne Fendu. Tiens : ta part, et deux grogs de ma réserve personnelle. Ne dis à personne que j'ai une réserve personnelle.",
		"recompense": {"pieces": 25, "rep": 4, "objets": [["grog_bordee", 2]]}},
	{"id": "bal_crocs", "titre": "Le poing de fer", "donneur": "brutus", "lieu": "La Balafre, la forge", "sorte": "Balafre",
		"resume": "Brutus, le forgeron de Port-Coutelas, me forgera un poing de fer si je lui rapporte trois dents de crocodile du Marais des Noyés.",
		"offre_label": "Ce poing de fer, tu me le forges ?",
		"offre": "Un poing de fer ? Pour toi ? … Hm. Il me faut trois dents de crocodile. Pas des dents de chien, pas des dents de requin : du crocodile du Marais des Noyés, à l'ouest. Elles sont dures comme l'acier. Je les sertis dans le métal, et tes poings frapperont comme des marteaux. Mais les crocodiles, eux, mordent comme des enclumes. Fais attention à l'eau.",
		"etapes": [
			{"type": "objets", "pnj": "brutus", "objets": {"dent_croco": 3}, "label": "Voici trois dents de crocodile.", "texte": "(Brutus prend les dents, les frappe sur l'enclume : elles sonnent comme du fer.) Bonnes dents. (Il chauffe, tape, trempe, tape encore. La forge rugit. Une heure plus tard…) Voilà. Un poing de fer. Dans une bagarre, tes coups compteront plus. Mais aux poings seulement : une lame, c'est pour les lâches.", "objectif": "Rapporter trois dents de crocodile à Brutus, à la forge (on les prend aux crocodiles du Marais des Noyés, à l'ouest de l'île)"},
		],
		"fin": "Et ne viens pas te plaindre si tu casses une mâchoire. Ou deux. Les mâchoires, ça se répare. Le Doc est là pour ça.",
		"recompense": {"pieces": 10, "objets": [["poing_fer", 1]]}},
	{"id": "bal_fievre", "titre": "La fièvre des marais", "donneur": "doc", "lieu": "La Balafre, chez le Doc", "sorte": "Balafre",
		"resume": "La fièvre des marais a couché la moitié de l'équipage de la Veuve Écarlate. Le Doc a besoin de trois touffes d'herbe à fièvre, qui poussent au bord de l'eau du Marais des Noyés.",
		"offre_label": "Je peux t'aider pour la fièvre ?",
		"offre": "Tu ferais ça ? Bien. L'herbe à fièvre pousse au bord de l'eau, dans le Marais des Noyés : des touffes argentées, qui brillent un peu quand le soleil est bas. Il m'en faut trois. Et regarde l'eau, pas les touffes : c'est de l'eau que sortent les crocodiles.",
		"etapes": [
			{"type": "ramasser", "objets": {"herbe_fievre": 3}, "lieux": ["herbe_fievre_1", "herbe_fievre_2", "herbe_fievre_3"], "objectif": "Cueillir trois touffes d'herbe à fièvre au bord de l'eau du Marais des Noyés (à l'ouest de l'île)"},
			{"type": "objets", "pnj": "doc", "objets": {"herbe_fievre": 3}, "label": "Voici trois touffes d'herbe à fièvre.", "texte": "Parfaites ! Argentées jusqu'à la racine. (Il les pile dans un mortier avec du miel et une goutte de rhum.) Une cuillère chacun, matin et soir, et dans trois jours ils se battront de nouveau comme des chiffonniers. Ce qui n'est pas forcément une bonne nouvelle pour moi.", "objectif": "Apporter les trois touffes au Doc (Fulbert Saignée, devant sa porte, près de la forge)"},
		],
		"fin": "Tiens. Des pièces, et trois flacons de mon remontant : rhum, miel, herbe à fièvre et un secret. Une gorgée, et tu te relèves de n'importe quelle bagarre. Enfin, de presque n'importe laquelle.",
		"recompense": {"pieces": 30, "rep": 4, "objets": [["remontant_doc", 3]]}},
	{"id": "bal_roi", "titre": "Le Roi de la Bagarre", "donneur": "tom", "lieu": "La Balafre, le Crâne Fendu", "sorte": "Balafre",
		"resume": "Tom le Violoneux chantera la gloire de celui qui mettra au tapis les trois champions du port, aux poings : Gros-Louis du Requin Borgne, le Muet de la Veuve Écarlate et Belle-Humeur de la Morue Enragée.",
		"offre_label": "Ta Chanson du Roi de la Bagarre… il lui manque un couplet ?",
		"offre": "Le dernier couplet ! Il n'existe pas encore : il faut d'abord un Roi. Le Roi de la Bagarre, c'est celui qui met au tapis les trois champions du port. Gros-Louis, du Requin Borgne. Le Muet, de la Veuve Écarlate. Belle-Humeur, de la Morue Enragée. Aux poings, sans lame : sinon ça ne compte pas. Un duel à la loyale, ou une bonne bagarre, comme tu veux. Et après… je chante !",
		"etapes": [
			{"type": "etat", "cle": "champions_3", "objectif": "Mettre au tapis les trois champions du port, aux poings et sans lame : Gros-Louis (Requin Borgne), le Muet (Veuve Écarlate), Belle-Humeur (Morue Enragée) — on peut leur proposer un duel à la loyale"},
			{"type": "rendre", "pnj": "tom", "label": "Les trois champions sont tombés.", "objectif": "Le dire à Tom le Violoneux (au Crâne Fendu, le soir)"},
		],
		"fin": "TOUS LES TROIS ?! (Tom saute sur la table et joue à en casser ses cordes.) ♪ Et puis vint un étranger, aux poings durs comme l'airain, il a mis les trois au tapis : vive le Roi, le roi des poings ! ♪ … Tiens, la ceinture du Roi : elle appartenait au dernier champion, il y a quarante ans. Personne ne l'a portée depuis.",
		"recompense": {"pieces": 50, "rep": 8, "titre": "Roi de la Bagarre", "objets": [["ceinture_champion", 1]], "bonus": {"force": 1}}},
	{"id": "bal_vieille_dent", "titre": "La main de Crochet", "donneur": "crochet", "lieu": "La Balafre, le Marais des Noyés", "sorte": "Balafre",
		"resume": "Vieille-Dent, le crocodile géant du Marais des Noyés, a pris la main de Crochet il y a des années. Crochet veut qu'on le venge.",
		"offre_label": "Vieille-Dent… tu veux qu'on t'en débarrasse ?",
		"offre": "… Tu as entendu parler de Vieille-Dent. Bien. Il dort au fond du marais, sous les palétuviers morts, à l'ouest. Le plus gros crocodile que la mer ait jamais vomi. Il a gardé ma main. Je ne te demande pas de me la rapporter. Je te demande qu'il ne mange plus jamais personne. Si tu fais ça… je te devrai quelque chose. Je n'aime pas devoir quelque chose.",
		"etapes": [
			{"type": "etat", "cle": "vieille_dent", "objectif": "Vaincre Vieille-Dent, le crocodile géant, au fond du Marais des Noyés (à l'ouest de l'île, sous les palétuviers morts)"},
			{"type": "rendre", "pnj": "crochet", "label": "Vieille-Dent ne mangera plus personne.", "objectif": "Le dire à Crochet (sur le quai le matin, à la forge l'après-midi, à la Dent du Requin le soir)"},
		],
		"fin": "(Crochet reste longtemps silencieux. Puis il pose son crochet sur ton épaule, très doucement.) … Merci. Tiens. Deux pièces d'or. Je les gardais pour le jour où je l'aurais tué moi-même. Ce jour ne viendra plus. Et c'est très bien comme ça.",
		"recompense": {"pieces": 35, "rep": 6, "objets": [["piece_or", 2]]}},
	{"id": "bal_carte", "titre": "La carte de Barbe-Sanglante", "donneur": "silas", "lieu": "La Balafre, le Rocher du Crâne", "sorte": "Balafre",
		"resume": "Le Vieux Silas jure que la carte du trésor de Barbe-Sanglante existe, déchirée en trois morceaux : un dans le donjon du Fort Maudit, un dans le mausolée du cimetière, et le troisième dans la manche de Sylvain, le croupier. Philémon Lunette saura la recomposer.",
		"offre_label": "Le trésor de Barbe-Sanglante… raconte-moi.",
		"offre": "Approche… Barbe-Sanglante a déchiré sa carte en trois, pour que ses hommes ne se trahissent pas. Un morceau dort dans le donjon du Fort Maudit, à l'est, gardé par ses vieux matelots, ceux qui ne sont plus que des os. Un autre dans le mausolée du cimetière, sur la colline de l'ouest. Le troisième… Sylvain, à la Dent du Requin, le garde dans sa manche : il ne le mise que contre celui qui le bat trois fois d'affilée. Réunis les trois, porte-les à Philémon, le cartographe. Et que la mer te garde.",
		"etapes": [
			{"type": "ramasser", "objets": {"carte_morceau": 2}, "lieux": ["carte_fort", "carte_mausolee"], "objectif": "Trouver deux morceaux de la carte : dans le donjon du Fort Maudit (sur la pointe est) et dans le mausolée du cimetière (sur la colline de l'ouest) — gare aux squelettes, surtout la nuit"},
			{"type": "objets", "pnj": "philemon", "objets": {"carte_morceau": 3}, "donne": [["carte_barbe", 1]], "label": "Voici les trois morceaux de la carte.", "texte": "Les trois ! (Philémon les étale, les tourne, les retourne, et les recoud avec un fil de soie.) Regardez : le Pic, la Balafre… et là, au bout, un crâne, et une croix rouge. Le Rocher du Crâne ! Mais lisez la marge : « Mon second veille. » Le Capitaine Sans-Chair… Prenez garde, jeune homme.", "objectif": "Gagner le troisième morceau contre Sylvain (trois victoires d'affilée à la grande table de la Dent du Requin), puis porter les trois morceaux à Philémon Lunette, le cartographe (devant sa tour)"},
			{"type": "etat", "cle": "capitaine_os", "objectif": "Aller au Cirque du Crâne, au bout de la Balafre, avec la carte : vaincre le Capitaine Sans-Chair qui garde le trésor"},
			{"type": "etat", "cle": "tresor_crane", "objectif": "Entrer dans le Rocher du Crâne par sa bouche et ouvrir le coffre de Barbe-Sanglante (E)"},
			{"type": "rendre", "pnj": "silas", "label": "J'ai trouvé le trésor de Barbe-Sanglante.", "objectif": "Raconter tout au Vieux Silas (près des feux de la grève le matin, au Crâne Fendu le soir)"},
		],
		"fin": "Tu… tu l'as trouvé. Le trésor du capitaine. (Le vieux Silas pleure et rit à la fois.) Cent ans que j'en parle, et personne ne m'a cru. Tiens, prends ça : son tricorne. Il me l'avait laissé, le jour où il est parti en mer pour ne jamais revenir. Il te va mieux qu'à moi. Va, héritier de Barbe-Sanglante. Et raconte-la bien, cette histoire. C'est tout ce qui reste, à la fin : les histoires.",
		"recompense": {"pieces": 100, "rep": 10, "titre": "Héritier de Barbe-Sanglante", "objets": [["tricorne_or", 1]], "flag": "tresor_balafre"}},
	# V69 : l'Île des Trois Soleils (Per-Hâpy, Yaxché, Aztlán) et ses trois grands donjons
	{"id": "eg_pyramide", "titre": "La nuit de Rê", "donneur": "neferet", "lieu": "Trois Soleils, Per-Hâpy", "sorte": "Trois Soleils",
		"resume": "Chaque nuit, Rê traverse le monde d'en dessous dans sa barque, et Apophis, le serpent du chaos, veut l'avaler. Depuis que la Pyramide de Rê est scellée, Néferet n'entend plus Rê chanter à l'aube.",
		"offre_label": "Vous avez l'air inquiète, prêtresse.",
		"offre": "Inquiète… Chaque matin, je salue Rê qui renaît. Depuis des lunes, il se lève pâle, comme s'il avait mal dormi. Je crois qu'Apophis le harcèle, la nuit, au fond de la Douat. La Pyramide de Rê, de l'autre côté du fleuve, garde le chemin de la nuit ; mais sa porte est scellée, et le Sphinx n'ouvre qu'à ceux qui savent répondre. Va le voir. Réfléchis avant de parler. Et si tu descends… protège la barque du soleil.",
		"etapes": [
			{"type": "etat", "cle": "sphinx", "objectif": "Répondre aux trois questions du Sphinx (sur le plateau de Rê, de l'autre côté du fleuve, au sud de Per-Hâpy)"},
			{"type": "etat", "cle": "pyramide", "objectif": "Descendre dans la Pyramide de Rê, traverser le voyage de la nuit et vaincre Apophis au fond de la Douat"},
			{"type": "rendre", "pnj": "neferet", "label": "Apophis est vaincu. Rê est sauvé.", "objectif": "Le dire à Néferet, la prêtresse de Rê (au temple de Per-Hâpy)"},
		],
		"fin": "Je le savais. Ce matin, Rê s'est levé rouge et or, comme un jeune homme. (Elle pose la main sur ton front.) Que sa lumière te suive partout où tu iras. Tiens : du pain de Mérit, et de quoi remplir ta bourse. Et l'Œil d'Horus, garde-le bien : sur les hautes terres, au milieu de l'île, une niche l'attend.",
		"recompense": {"pieces": 60, "rep": 6, "objets": [["pain_egypte", 3]]}},
	{"id": "eg_chat", "titre": "Miou a disparu", "donneur": "nebet", "lieu": "Trois Soleils, Per-Hâpy", "sorte": "Trois Soleils",
		"resume": "Miou, le chat roux à l'oreille tordue de la petite Nebet, a disparu depuis trois jours. Khéty dit que les chats aiment le frais des tombeaux, sur le plateau de Rê.",
		"offre_label": "Ton chat… je peux le chercher ?",
		"offre": "C'est vrai ? Tu veux bien ? Il s'appelle Miou. Il est roux, avec une oreille tordue, comme ça. (Elle tord son oreille.) Khéty dit que les chats aiment aller chez les morts, sur le plateau, près des tombes carrées. Mais maman ne veut pas que j'y aille toute seule. Tu le ramènes ? Promis ?",
		"etapes": [
			{"type": "etat", "cle": "chat_trouve", "objectif": "Chercher Miou sur le plateau de Rê, près des mastabas (les tombes carrées), et le prendre dans tes bras (E)"},
			{"type": "rendre", "pnj": "nebet", "label": "Regarde qui est là, Nebet !", "objectif": "Ramener Miou à Nebet, à Per-Hâpy"},
		],
		"fin": "MIOU ! (Le chat saute de tes bras dans les siens et ronronne comme un moulin.) Tu sens le tombeau, vilain chat ! … Merci, merci ! Tiens, c'est mon scarabée porte-bonheur. Ptahmosé l'a fait pour moi. Il te portera bonheur à toi aussi, maintenant.",
		"recompense": {"pieces": 10, "rep": 4, "objets": [["scarabee", 1]]}},
	{"id": "eg_crocodiles", "titre": "Le voleur de filets", "donneur": "kheti", "lieu": "Trois Soleils, le fleuve Iterou", "sorte": "Trois Soleils",
		"resume": "Les crocodiles de l'embouchure de l'Iterou volent les filets de Khéty, le pêcheur. Il veut qu'on lui rapporte deux de leurs dents, pour qu'ils comprennent.",
		"offre_label": "Ces crocodiles… je peux t'aider ?",
		"offre": "M'aider ? Avec les crocodiles ? Ha ! … Tu es sérieux. Bon. À l'embouchure, à l'est, trois gros crocodiles se couchent sur les bancs de sable. Ils mangent mes poissons dans mes filets, et parfois les filets avec. Rapporte-moi deux de leurs dents : je les pendrai à ma barque. Les autres comprendront.",
		"etapes": [
			{"type": "objets", "pnj": "kheti", "objets": {"dent_croco": 2}, "label": "Voici deux dents de crocodile.", "texte": "(Khéty les soupèse, et siffle.) Elles sont plus longues que mes doigts ! Je les pends à la proue, tout de suite. Sobek, le dieu crocodile, ne m'en voudra pas : c'étaient des voleurs.", "objectif": "Rapporter deux dents de crocodile à Khéty (les crocodiles se couchent à l'embouchure de l'Iterou, à l'est de Per-Hâpy)"},
		],
		"fin": "Tiens, des pièces, et deux jarres de la bière de Mérit. Et si un jour tu veux pêcher, ma barque est la tienne.",
		"recompense": {"pieces": 25, "rep": 3, "objets": [["biere_heqet", 2]]}},
	{"id": "ma_xibalba", "titre": "La descente des Jumeaux", "donneur": "ixkanul", "lieu": "Trois Soleils, Yaxché", "sorte": "Trois Soleils",
		"resume": "Sous le Temple de Kukulkan s'ouvre le chemin de Xibalba, le royaume des Seigneurs de la mort. Ix Kanul, la grande prêtresse, voudrait qu'on y descende comme les Jumeaux du Popol Vuh, et qu'on en rapporte le Masque de Jade des rois de Yaxché.",
		"offre_label": "Le chemin de Xibalba… on peut y descendre ?",
		"offre": "On peut. On ne devrait pas. Mais le Masque de Jade de nos rois est là-dessous, depuis que les Seigneurs l'ont pris, et sans lui Kinich Ahau, notre soleil, se lève sans visage. La porte du temple ne s'ouvre qu'à la date où les dieux ont créé le monde. Ah Kin, l'astronome, la connaît ; la grande stèle de la place aussi. Ensuite… souviens-toi des Jumeaux. Ils ont rusé à chaque épreuve.",
		"etapes": [
			{"type": "etat", "cle": "calendrier", "objectif": "Au sommet du Temple de Kukulkan, mettre les deux roues du calendrier sur la date de la création du monde (la grande stèle de la place la montre ; Ah Kin, l'astronome, la connaît)"},
			{"type": "etat", "cle": "xibalba", "objectif": "Descendre dans Xibalba, déjouer les Seigneurs de la mort et rapporter le Masque de Jade"},
			{"type": "rendre", "pnj": "ixkanul", "label": "J'ai le Masque de Jade.", "objectif": "Le dire à Ix Kanul, la grande prêtresse (au temple, ou au Cénote le matin)"},
		],
		"fin": "Tu l'as… tu es remonté de Xibalba. (Ix Kanul s'agenouille.) Les Jumeaux ont trompé les Seigneurs et sont devenus le Soleil et la Lune. Toi, tu es devenu une histoire. Garde le masque : sa place est sur l'Autel des Trois Soleils, sur les hautes terres. Tiens, du cacao des fêtes.",
		"recompense": {"pieces": 60, "rep": 6, "objets": [["cacao", 3]]}},
	{"id": "ma_moustique", "titre": "Xan le moustique", "donneur": "kinich", "lieu": "Trois Soleils, Yaxché", "sorte": "Trois Soleils",
		"resume": "Kinich, le garçon au moustique, veut bien prêter Xan, son moustique, à qui descendra dans Xibalba. Mais il a faim.",
		"offre_label": "Ton moustique… tu me le prêterais ?",
		"offre": "Xan ? Pour descendre dans Xibalba ? Comme les Jumeaux ?! … D'accord ! Mais j'ai faim. J'ai trop faim pour prêter un moustique. Ix Chab fait les meilleures galettes de maïs de la place. Tu m'en apportes une ?",
		"etapes": [
			{"type": "objets", "pnj": "kinich", "objets": {"galette_mais": 1}, "label": "Tiens, une galette d'Ix Chab.", "texte": "(Il mord dedans, la bouche pleine.) Merchi ! Tiens, voilà Xan. Ne le lâche que pour les choses importantes. Et ça aussi : Peek' a déterré des os énormes. Pour les jaguars, comme dans l'histoire !", "objectif": "Apporter une galette de maïs à Kinich (Ix Chab en vend sur la place de Yaxché)"},
		],
		"fin": "Xan, tu obéis bien, d'accord ? Et tu reviens ! (Il tapote la calebasse.) Au revoir, Xan…",
		"recompense": {"pieces": 0, "rep": 3, "objets": [["moustique", 1], ["os_jaguar", 2]]}},
	{"id": "az_temple", "titre": "Les Cinq Soleils", "donneur": "cuauhtli", "lieu": "Trois Soleils, Aztlán", "sorte": "Trois Soleils",
		"resume": "Cuauhtli, le grand prêtre d'Aztlán, cherche quelqu'un pour offrir la pluie à Tlaloc et le feu à Huitzilopochtli, au sommet du Grand Temple, et descendre sous le temple, dans la salle des Cinq Soleils.",
		"offre_label": "Que faut-il faire, au sommet du Grand Temple ?",
		"offre": "Deux offrandes. À Tlaloc, une jarre d'eau de pluie : Coyotl, le potier, en façonne. À Huitzilopochtli, du copal qui brûle : Tochtli en vend au marché. Alors la dalle ronde s'ouvrira entre les deux sanctuaires, et tu descendras chez les Cinq Soleils. Au plus profond dort la Plume du Serpent à plumes… et Cipactli, qui la garde.",
		"etapes": [
			{"type": "etat", "cle": "offrandes", "objectif": "Au sommet du Grand Temple, offrir une jarre de pluie à Tlaloc (sanctuaire bleu) et du copal à Huitzilopochtli (sanctuaire rouge)"},
			{"type": "etat", "cle": "cinq_soleils", "objectif": "Descendre sous le Grand Temple, rallumer la Pierre du Soleil, mettre le Cinquième Soleil en mouvement, vaincre Cipactli"},
			{"type": "rendre", "pnj": "cuauhtli", "label": "Le Cinquième Soleil tourne, et Cipactli dort pour de bon.", "objectif": "Le dire à Cuauhtli, le grand prêtre (au pied du Grand Temple)"},
		],
		"fin": "(L'Aigle te regarde longtemps.) Les anciens disent que le Cinquième Soleil s'arrêtera un jour. Pas aujourd'hui. Pas grâce à toi. Garde la Plume : sa place est sur l'Autel des Trois Soleils, sur les hautes terres. Et prends ceci, pour la route.",
		"recompense": {"pieces": 60, "rep": 6, "objets": [["copal", 2]]}},
	{"id": "az_jarre", "titre": "Une jarre pour Tlaloc", "donneur": "coyotl", "lieu": "Trois Soleils, Aztlán", "sorte": "Trois Soleils",
		"resume": "Coyotl, le potier d'Aztlán, façonne les jarres de pluie de Tlaloc ; mais il n'en donne une que si le grand prêtre l'envoie demander.",
		"offre_label": "Tu me ferais une jarre de pluie ?",
		"offre": "Une jarre de Tlaloc ? Ce n'est pas un pot à soupe, ami. On ne la donne pas à n'importe qui : il faut que Cuauhtli, le grand prêtre, t'envoie. Va le voir, au pied du Grand Temple. S'il dit oui, je t'en fais une.",
		"etapes": [
			{"type": "parler", "pnj": "cuauhtli", "label": "Coyotl demande si c'est vous qui m'envoyez.", "texte": "Coyotl et ses manières ! Oui. Dis-lui que Cuauhtli l'Aigle t'envoie, et que Tlaloc a soif.", "objectif": "Demander à Cuauhtli, le grand prêtre (au pied du Grand Temple), de t'envoyer chez Coyotl"},
			{"type": "rendre", "pnj": "coyotl", "label": "Cuauhtli m'envoie : Tlaloc a soif.", "objectif": "Retourner voir Coyotl, le potier (à son atelier, ou au marché à midi)"},
		],
		"fin": "« Tlaloc a soif » ? Alors c'est sérieux. (Il sort de son four une jarre bleue aux grands yeux ronds, la plonge dans le lac et la bouche d'une feuille.) Voilà. Pleine d'eau du lac, et ne la renverse pas en route.",
		"recompense": {"pieces": 0, "rep": 3, "objets": [["jarre_pluie", 1]]}},
	{"id": "az_cempasuchil", "titre": "Les fleurs des morts", "donneur": "xochitl", "lieu": "Trois Soleils, les chinampas", "sorte": "Trois Soleils",
		"resume": "Xóchitl, la jardinière des chinampas, a besoin de cinq bouquets de cempasúchil, les fleurs orange qui guident les âmes des morts, pour les autels du temple.",
		"offre_label": "Je peux cueillir tes fleurs ?",
		"offre": "Tu ferais ça ? Les cempasúchil poussent sur les chinampas du sud, au bord des canaux : des touffes orange, comme des petits soleils. Il m'en faut cinq bouquets. Ne marche pas sur les haricots !",
		"etapes": [
			{"type": "ramasser", "objets": {"cempasuchil": 5}, "lieux": ["cempasuchil_0", "cempasuchil_1", "cempasuchil_2", "cempasuchil_3", "cempasuchil_4"], "objectif": "Cueillir cinq bouquets de cempasúchil sur les chinampas, au sud et à l'ouest du lac d'Aztlán"},
			{"type": "objets", "pnj": "xochitl", "objets": {"cempasuchil": 5}, "label": "Voici tes cinq bouquets.", "texte": "Qu'elles sentent bon ! Les âmes trouveront le chemin, cette année. (Elle en glisse une derrière ton oreille.) Celle-là, c'est pour toi.", "objectif": "Apporter les cinq bouquets à Xóchitl (sur les chinampas, ou au marché)"},
		],
		"fin": "Tiens, des pièces, et du copal pour le temple : on dit que les dieux aiment l'odeur des fleurs et du copal ensemble.",
		"recompense": {"pieces": 30, "rep": 4, "objets": [["copal", 1]]}},
	{"id": "az_jaguars", "titre": "Les jaguars du Mont Fumant", "donneur": "mixtli", "lieu": "Trois Soleils, le Mont Fumant", "sorte": "Trois Soleils",
		"resume": "Deux vrais jaguars rôdent sur les pentes du Mont Fumant, à l'ouest. Ils ont tué un dindon de Xóchitl. Mixtli, le guerrier-jaguar, veut qu'on les affronte.",
		"offre_label": "Les jaguars du volcan… je viens avec toi.",
		"offre": "Avec moi ? Non : à ta place. Un guerrier-jaguar contre des jaguars, Cuauhtli trouve ça trop drôle, il ne me laisse pas partir. Les pentes du Mont Fumant, à l'ouest, sous les pins. Quand un jaguar se tapit, il va bondir : écarte-toi, puis frappe.",
		"etapes": [
			{"type": "etat", "cle": "jaguars_volcan", "objectif": "Vaincre les jaguars des pentes du Mont Fumant (à l'ouest de l'île, sous les pins)"},
			{"type": "rendre", "pnj": "mixtli", "label": "Les jaguars du volcan ne tueront plus de dindons.", "objectif": "Le dire à Mixtli, le guerrier-jaguar (sur la place d'Aztlán)"},
		],
		"fin": "(Mixtli te tape sur l'épaule, fort.) Toi, tu as un cœur de jaguar. Tiens : des os de leurs repas. Dans Xibalba, chez les Mayas, ça sert, paraît-il. Et des pièces.",
		"recompense": {"pieces": 40, "rep": 5, "objets": [["os_jaguar", 2]]}},
	# V70 : l'Île de Braise et Pandémonia, la cité des démons gentils
	{"id": "br_coeur", "titre": "Le Cœur-Brasier faiblit", "donneur": "ignatia", "lieu": "Île de Braise, la Citadelle", "sorte": "Île de Braise",
		"resume": "Le Cœur-Brasier, le grand feu de la Cathédrale-Forge qui réchauffe tout Pandémonia, pâlit de jour en jour. Un froid monte des Neuf Cercles, sous la cathédrale : on dit que le Titan de Givre y a emporté la Flamme Éternelle.",
		"offre_label": "Votre Altesse a l'air soucieuse…",
		"offre": "Soucieuse ? Je grelotte, voilà ce que je suis. Moi ! Une archiduchesse des enfers ! Le Cœur-Brasier s'éteint, petite flamme : il n'est plus qu'une lueur bleue, et la cité refroidit. Le froid monte des Neuf Cercles, sous la Cathédrale-Forge. Le Titan de Givre s'est réveillé au fond du Cocyte, et il a pris la Flamme Éternelle. Frère Cendrin garde la clé de la porte. Descends, cercle après cercle… et ramène-nous notre feu.",
		"etapes": [
			{"type": "parler", "pnj": "cendrin", "label": "L'Archiduchesse m'envoie : je descends chercher la Flamme Éternelle.", "texte": "Toi ? Dans les Neuf Cercles ? (Le vieux gardien te regarde longtemps, puis décroche une grosse clé noire de sa ceinture.) La Clé du Brasier. La porte est au fond de la nef. Écoute bien : une obole pour Charon, des gâteaux de miel pour Cerbère, de bonnes réponses pour Minos. Et prends un manteau, petit. Le Cocyte ne plaisante pas.", "donne": [["cle_brasier", 1]], "objectif": "Demander la Clé du Brasier à Frère Cendrin (dans la Cathédrale-Forge, près du Cœur-Brasier)"},
			{"type": "etat", "cle": "cercles", "objectif": "Descendre dans les Neuf Cercles (la porte de fer au fond de la Cathédrale-Forge), vaincre le Titan de Givre au fond du Cocyte et rapporter la Flamme Éternelle"},
			{"type": "etat", "cle": "coeur_vif", "objectif": "Rendre la Flamme Éternelle au Cœur-Brasier (au milieu de la nef de la Cathédrale-Forge)"},
			{"type": "rendre", "pnj": "ignatia", "label": "Le Cœur-Brasier brûle de nouveau !", "objectif": "Le dire à l'Archiduchesse Ignatia (au palais, sur la Citadelle)"},
		],
		"fin": "Je le sens jusqu'au bout de mes cornes : il fait chaud ! (L'Archiduchesse rit, et toute la salle du trône rit avec elle.) Pandémonia te doit son feu, petite flamme. À partir d'aujourd'hui, tu es chez toi ici. Tiens : des brioches du Four Éternel, et de quoi remplir ta bourse. Et ce titre, qu'on gravera sur la grande porte.",
		"recompense": {"pieces": 120, "rep": 10, "titre": "Sauveur de Pandémonia", "objets": [["brioche_braise", 3]]}},
	{"id": "br_pepin", "titre": "Pépin a disparu", "donneur": "zebuline", "lieu": "Île de Braise, le Grand Marché", "sorte": "Île de Braise",
		"resume": "Pépin, le petit diablotin de Zébuline, n'est pas rentré de l'Académie. Ses camarades l'ont vu partir vers le Bois de Cendre, pour voir les champignons qui brillent.",
		"offre_label": "Vous cherchez quelqu'un ?",
		"offre": "Mon Pépin ! Mon petit Pépin ! Il n'est pas rentré de l'Académie, et Ortie dit qu'il voulait voir les champignons qui brillent, dans le Bois de Cendre… Le bois, la nuit, c'est plein de diablotins sauvages ! Tu veux bien aller le chercher ? Il a une petite lanterne, et des cornes grosses comme des noisettes.",
		"etapes": [
			{"type": "etat", "cle": "pepin_trouve", "objectif": "Chercher Pépin dans le Bois de Cendre (au sud-est de la cité, sous les arbres de braise) et l'appeler (E)"},
			{"type": "rendre", "pnj": "zebuline", "label": "Pépin est rentré !", "objectif": "Le dire à Zébuline (à son étal d'épices du Grand Marché)"},
		],
		"fin": "Mon trésor de braise ! (Elle serre Pépin si fort que ses petites cornes rougissent.) Toi, tu reviens au marché quand tu veux : les piments sont pour toi, à vie. Enfin, ceux-là. Tiens.",
		"recompense": {"pieces": 25, "rep": 4, "objets": [["piment_infernal", 3]]}},
	{"id": "br_examens", "titre": "Les examens de l'Académie", "donneur": "malachar", "lieu": "Île de Braise, l'Académie Infernale", "sorte": "Île de Braise",
		"resume": "Le Professeur Malachar propose de passer les examens de l'Académie Infernale : l'épreuve des flammes, l'épreuve du contrat et l'épreuve des étincelles. Le jury est sévère, mais juste (et un peu brûlé).",
		"offre_label": "On peut passer les examens de l'Académie ?",
		"offre": "Un candidat libre ! Hm. Trois épreuves, comme tout le monde. Les flammes : Mademoiselle Sulfura veut voir si tu sais où naît le feu. Le contrat : notre bibliothécaire, Ombreline, te fera signer… après lecture, j'espère. Les étincelles : devant moi, tu croqueras un piment infernal sans pleurer. Ou presque sans pleurer.",
		"etapes": [
			{"type": "objets", "pnj": "sulfura", "objets": {"cristal_soufre": 1}, "label": "Voici un cristal de soufre : c'est là que naît le feu.", "texte": "Un cristal des sources ! Bien. Le soufre, l'air, une étincelle : voilà le feu. (Elle claque des doigts : le cristal s'enflamme d'une petite flamme bleue.) Épreuve des flammes : réussie !", "objectif": "Apporter un cristal de soufre à Mademoiselle Sulfura (à l'Académie ; Bulle en vend aux Thermes de Soufre)"},
			{"type": "parler", "pnj": "ombreline", "label": "Je viens pour l'épreuve du contrat.", "texte": "Signez ici. Non : lisez d'abord. TOUJOURS lire d'abord. (Tu lis.) « Le soussigné s'engage à ranger les livres à leur place, à ne pas corner les pages, et à rendre sa bonne humeur à la sortie. » … Vous avez lu jusqu'au bout. Vous êtes bien le premier. Épreuve du contrat : réussie.", "objectif": "Passer l'épreuve du contrat avec Ombreline, la bibliothécaire (à la Bibliothèque des Âmes)"},
			{"type": "objets", "pnj": "malachar", "objets": {"piment_infernal": 1}, "label": "Je croque le piment devant le jury.", "texte": "(Tu croques. Tu ne pleures pas. Enfin… une seule larme. De la fumée te sort des oreilles.) Admirable ! Le jury est ému. Le jury tousse un peu, aussi. Épreuve des étincelles : réussie !", "objectif": "Croquer un piment infernal devant le Professeur Malachar (Zébuline en vend au Grand Marché)"},
		],
		"fin": "Par mes cornes ! Trois épreuves sur trois. (Malachar sort un parchemin roussi et y appose son sceau.) Je te déclare Bachelier des Flammes de l'Académie Infernale, avec les félicitations un peu brûlées du jury.",
		"recompense": {"pieces": 40, "rep": 6, "titre": "Bachelier des Flammes", "objets": [["diplome_infernal", 1]]}},
	{"id": "br_tournoi", "titre": "Le Tournoi des Cornes", "donneur": "hurla", "lieu": "Île de Braise, l'Arène des Cornes", "sorte": "Île de Braise",
		"resume": "Madame Hurla, la maîtresse de l'Arène des Cornes, cherche un concurrent pour le grand tournoi : quatre manches, et la dernière contre Gorgoth le Cornu, le champion invaincu.",
		"offre_label": "Je veux m'inscrire au tournoi !",
		"offre": "UN CONCURRENT ! (Elle hurle tellement que trois pigeons tombent du toit.) Quatre manches ! Des diablotins, des chiens d'enfer, des automates de bronze… et en finale, GORGOTH LE CORNU ! Frappe le gong au bord du sable pour lancer chaque manche. Si tu sors du sable, c'est l'abandon. Si tu tombes, on te ramasse. INSCRIT !",
		"etapes": [
			{"type": "etat", "cle": "tournoi", "objectif": "Gagner les quatre manches du Tournoi des Cornes (frapper le gong, au bord du sable de l'arène)"},
			{"type": "rendre", "pnj": "hurla", "label": "Je suis le nouveau Champion des Cornes !", "objectif": "Le dire à Madame Hurla (au guichet de l'arène, ou sur la place)"},
		],
		"fin": "LE NOUVEAU CHAMPION ! (Elle te soulève d'un bras.) Même Gorgoth est content : il dit que tu te bats comme on écrit un poème. Tiens, ta part de la recette, et deux laves glacées, offertes par la maison.",
		"recompense": {"pieces": 60, "rep": 8, "titre": "Champion des Cornes", "objets": [["lave_glacee", 2]]}},
	{"id": "br_lanternes", "titre": "La Nuit des Lanternes", "donneur": "lumina", "lieu": "Île de Braise, la Grand-Place", "sorte": "Île de Braise",
		"resume": "Lumina, la lanternière, prépare la Nuit des Lanternes : il faut allumer les sept Grandes Lanternes de la cité. Quand elles brilleront toutes, et que les fusées de Zigomar seront prêtes, Pandémonia dansera toute la nuit sur la Grand-Place.",
		"offre_label": "Je peux vous aider pour la fête ?",
		"offre": "Oh, oui ! La Nuit des Lanternes ! Il faut allumer les sept Grandes Lanternes : celle du port, du marché, de l'arène, des thermes, de l'Académie, de la Cathédrale-Forge et celle d'ici, sur la Grand-Place. Prends ma lanterne de braise : sa flamme ne s'éteint jamais. Et demande à Zigomar si ses fusées sont prêtes. Ensuite… la nuit tombe, et on danse !",
		"donne": [["lanterne_braise", 1]],
		"etapes": [
			{"type": "etat", "cle": "sept_lanternes", "objectif": "Allumer les sept Grandes Lanternes de Pandémonia avec la lanterne de braise (le port, le marché, l'arène, les thermes, l'Académie, la Cathédrale-Forge, la Grand-Place)"},
			{"type": "etat", "cle": "fete_lanternes", "objectif": "Les fusées de Zigomar prêtes, revenir la nuit (après 20 h) sur la Grand-Place pour la fête"},
			{"type": "rendre", "pnj": "lumina", "label": "Quelle fête, Lumina !", "objectif": "Remercier Lumina, la lanternière"},
		],
		"fin": "La plus belle Nuit des Lanternes depuis mille ans ! (Lumina a encore des étincelles dans les cheveux.) Tu es des nôtres, maintenant. Garde la lanterne : elle te reconnaîtra toujours.",
		"recompense": {"pieces": 50, "rep": 10, "titre": "Ami des Démons"}},
	{"id": "br_artifice", "titre": "Le feu d'artifice", "donneur": "zigomar", "lieu": "Île de Braise, le quartier des Artisans", "sorte": "Île de Braise",
		"resume": "Zigomar, l'inventeur et artificier, n'a plus de soufre pour ses fusées de la Nuit des Lanternes. Il lui faut trois cristaux de soufre des sources chaudes.",
		"offre_label": "Vos fusées… elles sont prêtes ?",
		"offre": "Prêtes ? PRÊTES ? (Ses lunettes fument.) Il me manque le principal : le soufre ! Trois beaux cristaux, des sources chaudes, au pied du volcan, à l'ouest. Sans eux, mes fusées feront « pfff ». Avec eux : BADABOUM, en sept couleurs !",
		"etapes": [
			{"type": "ramasser", "objets": {"cristal_soufre": 3}, "lieux": ["cristal_soufre_1", "cristal_soufre_2", "cristal_soufre_3"], "objectif": "Ramasser trois cristaux de soufre au bord des sources chaudes (au pied du Grand Brasier)"},
			{"type": "objets", "pnj": "zigomar", "objets": {"cristal_soufre": 3}, "label": "Voici tes trois cristaux de soufre.", "texte": "Magnifiques ! Jaunes comme des canaris ! (Il les écrase dans un mortier, il mélange, il éternue, il rit.) Les fusées sont prêtes ! Dis à Lumina que la Nuit des Lanternes aura son feu d'artifice !", "objectif": "Apporter les trois cristaux à Zigomar (à son atelier d'inventeur)"},
		],
		"fin": "Tiens, une petite fusée de remerciement… non, des pièces, plutôt. Les fusées, c'est pour la fête.",
		"recompense": {"pieces": 30, "rep": 4}},
	{"id": "br_gateaux", "titre": "Trois gâteaux pour trois têtes", "donneur": "bobor", "lieu": "Île de Braise, le Four Éternel", "sorte": "Île de Braise",
		"resume": "Grand-père Ébène raconte que Cerbère, le chien à trois têtes des Neuf Cercles, ne résiste pas aux gâteaux de miel : un par tête. Bobor, le boulanger, veut bien en cuire trois… s'il a du miel.",
		"offre_label": "Ébène dit que Cerbère adore les gâteaux de miel…",
		"offre": "Cerbère ? Ha ! Ce gros toutou ! Trois têtes, trois gâteaux, et il dort comme un bébé. Je veux bien les cuire, mais je n'ai plus une goutte de miel de feu. Les abeilles de feu font leur nid dans deux vieux troncs creux, au Bois de Cendre. Rapporte-moi deux rayons de miel. Doucement : elles piquent, mais elles sont polies.",
		"etapes": [
			{"type": "ramasser", "objets": {"miel": 2}, "lieux": ["miel_braise_1", "miel_braise_2"], "objectif": "Récolter deux rayons de miel aux ruches des abeilles de feu, dans le Bois de Cendre (au sud-est de la cité)"},
			{"type": "objets", "pnj": "bobor", "objets": {"miel": 2}, "label": "Voici deux rayons de miel de feu.", "texte": "Ça sent le printemps et le volcan ! (Il pétrit, il enfourne, et le Four Éternel ronronne.) Et voilà : trois gâteaux de miel, tout chauds. Un par tête, hein ! Ne les mange pas en route.", "donne": [["gateau_miel", 3]], "objectif": "Apporter le miel à Bobor, au Four Éternel (la boulangerie du Grand Marché)"},
		],
		"fin": "Et si Cerbère n'en veut pas… mange-les ! Ils sont très bons aussi pour les humains.",
		"recompense": {"pieces": 10, "rep": 3}},
	{"id": "br_courrier", "titre": "Le courrier de Brindille", "donneur": "brindille_braise", "lieu": "Île de Braise, la poste du port", "sorte": "Île de Braise",
		"resume": "Brindille, la factrice ailée, s'est foulé une aile. Il reste trois lettres à porter : à Grumbald, le tavernier, à Ombreline, la bibliothécaire, et à Gorgoth, le champion de l'arène.",
		"offre_label": "Vous avez l'air embêtée, factrice.",
		"offre": "Embêtée ? Je suis CLOUÉE AU SOL ! (Elle montre son aile en écharpe.) Je me la suis foulée sur une cheminée. Il me reste trois lettres : une pour Grumbald, au Diable Repu ; une pour Ombreline, à la Bibliothèque des Âmes ; une pour Gorgoth, à l'arène. Tu veux bien ? Je te paierai en timbres. Non, en pièces.",
		"donne": [["lettre", 3]],
		"etapes": [
			{"type": "objets", "pnj": "grumbald", "objets": {"lettre": 1}, "label": "Une lettre pour vous, de la part de Brindille.", "texte": "Une lettre ? Pour moi ? (Il l'ouvre avec un couteau à beurre.) Ma cousine de Vulcanie arrive pour la Nuit des Lanternes ! Elle mange comme quatre. Il me faudra plus de grog.", "objectif": "Porter une lettre à Grumbald (au comptoir de la taverne « Au Diable Repu », au port)"},
			{"type": "objets", "pnj": "ombreline", "objets": {"lettre": 1}, "label": "Une lettre pour vous, de la part de Brindille.", "texte": "(Elle l'ouvre avec un coupe-papier d'os.) Un livre en retard depuis trois cent douze ans. Je savais bien que je le retrouverais. Merci.", "objectif": "Porter une lettre à Ombreline (à la Bibliothèque des Âmes, dans la Haute-Ville)"},
			{"type": "objets", "pnj": "gorgoth", "objets": {"lettre": 1}, "label": "Une lettre pour toi, Gorgoth.", "texte": "Une lettre ? Pour Gorgoth ? (Le colosse la lit très lentement, et ses yeux se mouillent.) C'est un poème. Quelqu'un m'a écrit un poème. … Tu ne dis à personne que Gorgoth a pleuré, d'accord ?", "objectif": "Porter une lettre à Gorgoth le Cornu (à l'arène, ou aux thermes)"},
			{"type": "rendre", "pnj": "brindille_braise", "label": "Les trois lettres sont arrivées.", "objectif": "Revenir voir Brindille (à la poste du port)"},
		],
		"fin": "Les trois ! Et pas une seule cornée. (Elle te fait une petite révérence, d'une seule aile.) Si un jour tu veux un travail, la poste recrute. Même sans ailes.",
		"recompense": {"pieces": 20, "rep": 4}},
	{"id": "br_chiens", "titre": "Les chiens du champ de lave", "donneur": "pyrus", "lieu": "Île de Braise, le champ de lave", "sorte": "Île de Braise",
		"resume": "Des chiens d'enfer sauvages ont pris le champ de lave, à l'est du Grand Brasier, et grognent sur les voyageurs. Le capitaine Pyrus voudrait qu'on les chasse.",
		"offre_label": "Un souci, capitaine ?",
		"offre": "Un souci à trois têtes… non, à trois chiens. Des chiens d'enfer sauvages, sur le champ de lave, à l'est du volcan. Ce ne sont pas des méchants, juste des mal élevés. Ils crachent le feu sur les promeneurs. Ma garde est occupée à garder. Tu t'en charges ? Quand la gueule rougeoie, écarte-toi.",
		"etapes": [
			{"type": "etat", "cle": "chiens_champ", "objectif": "Chasser les chiens d'enfer sauvages du champ de lave (à l'est du Grand Brasier)"},
			{"type": "rendre", "pnj": "pyrus", "label": "Le champ de lave est tranquille.", "objectif": "Le dire au capitaine Pyrus (à la porte du palais, ou à la caserne)"},
		],
		"fin": "Bien. Très bien. (Pyrus frappe le sol de sa fourche.) Au nom de la Garde : merci. Tiens, de quoi te réchauffer.",
		"recompense": {"pieces": 35, "rep": 5, "objets": [["cafe_brasier", 2]]}},
	{"id": "br_gargouilles", "titre": "Les gargouilles des Ruines", "donneur": "charbonnel", "lieu": "Île de Braise, les Ruines", "sorte": "Île de Braise",
		"resume": "Des gargouilles se sont réveillées dans les Ruines de l'Ancien Pandémonium, sur les falaises du nord-ouest. Elles plongent sur les navires qui passent. Le capitaine Charbonnel, maître du port, voudrait qu'on les chasse.",
		"offre_label": "Les navires ont un problème, capitaine ?",
		"offre": "Des gargouilles, mille sabords ! Des statues qui s'envolent, je vous demande un peu. Elles nichent dans les Ruines de l'Ancien Pandémonium, sur les falaises du nord-ouest, et elles plongent sur mes voiles. Allez les déloger. Elles sont en pierre : frappez fort.",
		"etapes": [
			{"type": "etat", "cle": "gargouilles_ruines", "objectif": "Chasser les gargouilles des Ruines de l'Ancien Pandémonium (sur les falaises du nord-ouest de l'île)"},
			{"type": "rendre", "pnj": "charbonnel", "label": "Les gargouilles ne plongeront plus sur vos voiles.", "objectif": "Le dire au capitaine Charbonnel (à la capitainerie du port)"},
		],
		"fin": "Hé hé ! Mes voiles vous disent merci. Prenez ça : la prime du port.",
		"recompense": {"pieces": 40, "rep": 5}},
	{"id": "br_fleurs", "titre": "Les fleurs de braise", "donneur": "brasille", "lieu": "Île de Braise, les Jardins de Cendre", "sorte": "Île de Braise",
		"resume": "Mère Brasille, la jardinière des Jardins de Cendre, voudrait cinq fleurs de braise pour ses massifs. Elles ne poussent que sur les pentes du Grand Brasier.",
		"offre_label": "Vos massifs sont magnifiques…",
		"offre": "Magnifiques ? Il leur manque le principal : des fleurs de braise ! Des pétales de flamme, jaunes au cœur, rouges au bout. Elles ne poussent que sur les pentes du Grand Brasier, là où la terre est tiède. Rapporte-m'en cinq. Ne marche pas sur les coulées, hein : je n'ai plus l'âge de soigner les brûlures.",
		"etapes": [
			{"type": "ramasser", "objets": {"fleur_braise": 5}, "lieux": ["fleur_braise_1", "fleur_braise_2", "fleur_braise_3", "fleur_braise_4", "fleur_braise_5"], "objectif": "Cueillir cinq fleurs de braise sur les pentes du Grand Brasier (loin des coulées de lave)"},
			{"type": "objets", "pnj": "brasille", "objets": {"fleur_braise": 5}, "label": "Voici vos cinq fleurs de braise.", "texte": "Qu'elles sont belles ! (Elle les plante une à une, et la cendre autour se met à luire.) Elles brilleront toute la nuit. Comme toi, petite étincelle.", "objectif": "Apporter les cinq fleurs à Mère Brasille (aux Jardins de Cendre)"},
		],
		"fin": "Tiens, un gâteau de miel de Bobor, que je gardais pour moi. Je te le donne : tu as fait le plus dur, moi je n'ai fait que planter.",
		"recompense": {"pieces": 25, "rep": 4, "objets": [["gateau_miel", 1]]}},
	{"id": "mj_inscription", "titre": "L'inscription à la Guilde", "donneur": "eglantine", "lieu": "Île de Montjoie, la Guilde des Aventuriers", "sorte": "Île de Montjoie",
		"resume": "Pour accepter des contrats, recruter des compagnons et monter de rang, il faut être inscrit à la Guilde des Aventuriers de Montjoie. Églantine, la réceptionniste, demande dix pièces et une petite lecture à la boule de cristal.",
		"offre_label": "Je voudrais m'inscrire à la Guilde !",
		"offre": "Une inscription ! (Elle sort un formulaire, deux tampons et une loupe.) C'est très simple : dix pièces de frais, une signature ici, ici et là, et une petite lecture de vos aptitudes à la boule de cristal. Elle ne mord presque pas. Elle sent un peu la pomme, c'est normal. Vous avez les dix pièces ?",
		"etapes": [
			{"type": "objets", "pnj": "eglantine", "objets": {"piece": 10}, "label": "Voici mes dix pièces. Je pose la main sur la boule ?", "texte": "Posez la main, bien à plat… (La boule s'allume, hésite, fait « bzzz », puis affiche des lettres dorées.) Voyons : Force, correcte. Agilité, enthousiaste. Magie, « peut-être plus tard ». Chance, « hmm ». Appétit : EXCEPTIONNEL. Talent caché : « sait se relever ». (Elle tamponne trois fois.) Félicitations ! Voici votre Carte d'aventurier. Rang F. Comme tout le monde. Même Maître Hugues, au début. Surtout Maître Hugues.", "donne": [["carte_aventurier", 1]], "objectif": "Payer dix pièces à Églantine et poser la main sur la boule de cristal (au comptoir de la Guilde des Aventuriers, sur la Grand-Place de la Ville-Moyenne)"},
		],
		"fin": "Bienvenue dans la Guilde ! Le tableau des quêtes est juste derrière vous : quatre contrats nouveaux chaque jour. Rapportez-les-moi, je tamponne, vous montez de rang. Et maintenant que vous êtes inscrit, les aventuriers de la taverne voudront peut-être faire équipe avec vous. Parlez à Sœur Pétronille, à Violette et à Sire Tancrède. Ils ont tous les trois… un petit souci.",
		"recompense": {"pieces": 0, "rep": 3}},
	{"id": "mj_donjon", "titre": "Le Roi Gélatineux", "donneur": "hugues", "lieu": "Île de Montjoie, le Donjon des Mille Marches", "sorte": "Île de Montjoie",
		"si": {"apres": "mj_inscription", "rang": "D"},
		"resume": "Du slime remonte dans les puits de la Basse-Ville et dans la fontaine de la Grand-Place. Maître Hugues sait d'où il vient : du fond du Donjon des Mille Marches, au pied des Crocs, où règne le Roi Gélatineux. Il faut descendre les cinq étages, vaincre le Roi et rapporter son Cœur de gelée royale.",
		"offre_label": "Maître Hugues, la fontaine fait des bulles vertes…",
		"offre": "Tu l'as vu aussi, gamin ? Le slime remonte. Dans les puits, dans la fontaine, et ce matin dans la soupe de Rissole. Elle est furieuse. Ça vient d'en bas, du Donjon des Mille Marches, au pied des Crocs. Cinq étages. Tout au fond, il y a le Roi Gélatineux, avec sa petite couronne. Tant qu'il est là, la gelée montera. Tu es rang D, maintenant : tu es prêt. Descends, vaincs-le, et rapporte-moi son Cœur de gelée royale. Et quand il se coupe en petits morceaux… surtout, ne panique pas. Je sais de quoi je parle.",
		"etapes": [
			{"type": "etat", "cle": "roi_gelatineux", "objectif": "Descendre les cinq étages du Donjon des Mille Marches (l'entrée est sous la tour en ruine, au pied des Crocs, au sud-ouest de l'île ; Odon tient la grille) et vaincre le Roi Gélatineux dans la Salle du Trône Gélatineux"},
			{"type": "objets", "pnj": "hugues", "objets": {"coeur_gelee": 1}, "label": "Voici le Cœur de gelée royale, Maître.", "texte": "(Il le prend dans ses deux grosses mains. Le cœur tremble comme un flan.) Le Cœur de gelée royale… Par ma barbe. Par mes trois tresses. Par la tourte de Rissole. (Il pleure, évidemment.) Gamin, tu viens de faire ce que je n'ai jamais fait. J'ai paniqué au troisième étage. Toi, tu es allé au fond, et tu es revenu. Odon va devoir racheter de l'encre rouge.", "objectif": "Rapporter le Cœur de gelée royale à Maître Hugues (dans son bureau, au fond de la Guilde, ou à une table de la taverne le soir)"},
		],
		"fin": "OYEZ, OYEZ ! (C'est Mélusine, qui a tout entendu depuis la porte.) … Bon. Tout Montjoie va le savoir dans trois minutes. Tant mieux ! Tu es le Héros de Montjoie, et je veux que Bertrand en fasse une chanson. Sans exagérer. Enfin, un peu. Tiens, la prime de la Guilde. Et viens dîner : Rissole a fait une tourte. Elle ne fera plus de bulles.",
		"recompense": {"pieces": 150, "rep": 10, "titre": "Héros de Montjoie"}},
	{"id": "mj_petronille", "titre": "Le chapelet perdu", "donneur": "petronille", "lieu": "Île de Montjoie, le Lac des Grenouilles", "sorte": "Île de Montjoie",
		"si": {"apres": "mj_inscription"},
		"resume": "Sœur Pétronille, la prêtresse du Temple de l'Aube, priait au bord du Lac des Grenouilles quand la plus grosse grenouille géante du lac a avalé son chapelet du soleil. Sans lui, elle n'ose plus partir à l'aventure.",
		"offre_label": "Ma sœur, vous avez l'air bouleversée…",
		"offre": "Bouleversée ? Je suis… je suis… (Elle trébuche sur rien.) Pardon. Mon chapelet du soleil ! Père Clotaire me l'a offert pour mes quinze ans. Je priais au bord du lac pour Monsieur Yvon, et une grenouille énorme, ÉNORME, a sorti sa langue et… slurp. Elle l'a avalé. Monsieur Yvon l'appelle la Duchesse. Les grenouilles recrachent ce qu'elles avalent quand on les bat, paraît-il. Vous voudriez bien… ? Moi, je prierai. De loin. De très loin.",
		"etapes": [
			{"type": "objets", "pnj": "petronille", "objets": {"chapelet_soleil": 1}, "label": "Voici votre chapelet du soleil, ma sœur. La Duchesse l'a rendu.", "texte": "Mon chapelet ! (Elle le serre contre elle, puis s'écarte.) Il est… un peu gluant. Ce n'est rien ! Ce n'est rien du tout ! Ô Aube, merci. Et merci à vous. Vous êtes allé chercher quelque chose dans une grenouille, pour moi. Personne n'avait jamais fait ça.", "objectif": "Chasser les grenouilles géantes du Lac des Grenouilles (à l'est de la ville, par la Porte de l'Est) : la plus grosse, la Duchesse, rendra le chapelet du soleil ; puis le rapporter à Sœur Pétronille (au Temple de l'Aube, dans la Haute-Ville, ou à la Guilde l'après-midi)"},
		],
		"fin": "Je… je voudrais vous demander une chose. (Elle prend une grande inspiration.) Est-ce que je pourrais venir avec vous ? Dans vos aventures ? Je soigne très bien. Je tombe aussi, mais je soigne très bien. Si vous voulez de moi, dites-le-moi quand vous voulez. Je serai au temple, ou à la Guilde. Je prierai pour que vous disiez oui.",
		"recompense": {"pieces": 20, "rep": 4}},
	{"id": "mj_violette", "titre": "Les cristaux d'orage", "donneur": "violette", "lieu": "Île de Montjoie, les Crocs", "sorte": "Île de Montjoie",
		"si": {"apres": "mj_inscription"},
		"resume": "Violette, la jeune mage de la Guilde, ne sait lancer que des éclairs, et ils la touchent souvent elle-même. D'après un vieux livre, trois cristaux d'orage, qui poussent au sommet des Crocs, canaliseraient sa foudre « vers l'avant ».",
		"offre_label": "Violette, vos cheveux… ils se dressent tout seuls.",
		"offre": "Oh. Oui. (Bzzt.) … Ça arrive. J'ai lu quelque chose. Dans un livre que Madame Olga m'a prêté. Au hasard. Les cristaux d'orage, au sommet des Crocs, boivent la foudre et la renvoient droit devant. Pas vers le chapeau. Pas vers les cheveux. Droit devant. Il m'en faudrait trois. Mais si je monte là-haut toute seule, l'orage et moi, on va se disputer les éclairs. Vous voudriez bien… ?",
		"etapes": [
			{"type": "ramasser", "objets": {"cristal_orage": 3}, "lieux": ["cristal_orage_1", "cristal_orage_2", "cristal_orage_3"], "objectif": "Grimper au sommet des Crocs (les collines rocheuses du sud-ouest, au-dessus de l'entrée du donjon) et ramasser trois cristaux d'orage"},
			{"type": "objets", "pnj": "violette", "objets": {"cristal_orage": 3}, "label": "Voici trois cristaux d'orage, Violette.", "texte": "(Elle les prend un par un. Ils grésillent, ils chantent, et pour une fois, ses cheveux restent à plat.) Bzzzz… Vous entendez ? Ils chantent. Je vais les monter sur mon bâton. (Une petite étincelle part droit devant, et touche… le mur. Pas elle.) Oh. OH. Vous avez vu ? Vers l'avant !", "objectif": "Apporter les trois cristaux à Violette (à une table de la Guilde, ou au belvédère de la Haute-Ville l'après-midi)"},
		],
		"fin": "Je n'ose pas vous le demander. Je vous le demande quand même. Est-ce que je peux venir avec vous ? Je lirai pendant les voyages, je ne parlerai presque pas, et je foudroierai les monstres. Surtout les monstres. Presque toujours les monstres. Si vous voulez, dites-le-moi. Je serai à la Guilde.",
		"recompense": {"pieces": 25, "rep": 4}},
	{"id": "mj_tancrede", "titre": "Un vrai exploit", "donneur": "tancrede", "lieu": "Île de Montjoie, le Bois des Lutins", "sorte": "Île de Montjoie",
		"si": {"apres": "mj_inscription"},
		"resume": "Sire Tancrède de Tournevent raconte des exploits magnifiques. Tous imaginaires. Il voudrait enfin en vivre un vrai, avec un témoin : vaincre le chef des gobelins du Bois des Lutins et rapporter sa bannière.",
		"offre_label": "Sire Tancrède, racontez-moi votre plus grand exploit.",
		"offre": "Mon plus grand exploit ? (Il bombe le torse, puis le dégonfle.) Ami… je vais vous avouer une chose. Ils sont tous dans le brouillard. Tous. Il me faut un VRAI exploit. Avec un témoin. Et du soleil. Au fond du Bois des Lutins, les gobelins ont un camp, et un chef, et une bannière décorée avec les plumes des casques de la garde. Vainquez-le avec moi, ou devant moi, ou même un peu à ma place, et rapportez la bannière. MOI, SIRE TANCRÈDE DE TOURNEVENT, je jure de vous suivre ensuite jusqu'au bout du monde !",
		"etapes": [
			{"type": "etat", "cle": "chef_gobelin", "objectif": "Vaincre le chef des gobelins dans son camp, au fond du Bois des Lutins (au nord-est de l'île, après la Porte de l'Est)"},
			{"type": "objets", "pnj": "tancrede", "objets": {"banniere_gobelin": 1}, "label": "Voici la bannière du chef gobelin, Sire Tancrède.", "texte": "La bannière ! LA BANNIÈRE ! (Il la brandit, se prend les pieds dans sa cape, tombe, et la brandit toujours, allongé.) Un vrai exploit ! Avec un témoin ! Avec du soleil ! Bertrand ! BERTRAND ! Il faut une chanson ! Et pas un seul nuage dedans !", "objectif": "Rapporter la bannière à Sire Tancrède (à la Guilde, dans la cour du château le matin, ou sur les remparts l'après-midi)"},
		],
		"fin": "Ami, frère d'armes, compagnon de légende : j'ai une dette envers vous. Laissez-moi la payer avec mon épée. Quand vous voudrez, dites seulement « viens avec moi », et MOI, SIRE TANCRÈDE DE TOURNEVENT, je chargerai à vos côtés ! Une fois sur trois, je tomberai. Mais les deux autres fois… ah, les deux autres fois !",
		"recompense": {"pieces": 40, "rep": 5}},
	{"id": "mj_grenouilles", "titre": "Les grenouilles du lac", "donneur": "yvon", "lieu": "Île de Montjoie, le Lac des Grenouilles", "sorte": "Île de Montjoie",
		"resume": "Yvon, le pêcheur du lac, a peur des grenouilles géantes depuis quarante ans. Elles sont de plus en plus nombreuses : elles volent ses poissons, ses appâts et, une fois, sa barque. Il voudrait qu'on en chasse quelques-unes.",
		"offre_label": "Vous tremblez, Yvon…",
		"offre": "Je tremble depuis quarante ans, l'ami. Mais là, c'est trop. Elles sont partout ! Sur le ponton, dans les roseaux, dans ma barque ! Hier, l'une d'elles a avalé mon déjeuner. Avec la boîte. Chasse-les un peu, tu veux ? Pas toutes, hein. Juste assez pour que je puisse pêcher sans crier. Et si l'une d'elles t'avale… ne te débats pas. Ça dure trois secondes. Quatre si tu te débats.",
		"etapes": [
			{"type": "etat", "cle": "grenouilles_lac", "objectif": "Chasser les grenouilles géantes du Lac des Grenouilles (à l'est de Montjoie, par la Porte de l'Est ; attention à leur langue, elles avalent)"},
			{"type": "rendre", "pnj": "yvon", "label": "Le lac est plus calme, Yvon.", "objectif": "Le dire à Yvon (sur son ponton de pêche, au bord du lac)"},
		],
		"fin": "Plus calme… (Il regarde le lac longtemps.) C'est vrai. On entend les canards. Je n'avais pas entendu les canards depuis des années. Tiens, l'ami : des cuisses de grenouille pour Ulric, il te les cuisinera. Et ma reconnaissance éternelle. Elle est très grande, ma reconnaissance. Comme mes peurs.",
		"recompense": {"pieces": 35, "rep": 5, "objets": [["cuisse_grenouille", 2]]}},
	{"id": "mj_navets", "titre": "La récolte qui court", "donneur": "gaubert", "lieu": "Île de Montjoie, les Champs du Sud", "sorte": "Île de Montjoie",
		"resume": "Chaque printemps, les navets de Père Gaubert se réveillent et se sauvent à travers les Champs du Sud. Avec ses genoux, il n'en rattrape plus un seul. Il voudrait cinq navets dorés, attrapés pendant une Grande Alerte des Navets.",
		"offre_label": "Vos navets… ils bougent, Père Gaubert ?",
		"offre": "Ils bougent, mon gars. Ils dorment, mais ils bougent. Bientôt, Mélusine sonnera sa cloche, et ils vont tous se sauver d'un coup ! La Grande Alerte des Navets ! Moi, avec mes genoux, je n'en attrape plus un seul. Germaine, oui, avec son filet, mais elle les garde pour embêter Babette. Quand la cloche sonnera, cours aux champs et attrape-m'en cinq. Un petit coup, pas plus ! Ils deviennent dorés quand on les attrape. Doucement avec mes petits.",
		"etapes": [
			{"type": "objets", "pnj": "gaubert", "objets": {"navet_dore": 5}, "label": "Voici cinq navets dorés, Père Gaubert. Doucement, promis.", "texte": "Cinq ! Cinq beaux dorés ! (Il les caresse un par un, comme des petits chats.) Tu les as attrapés doucement, je le vois. Ils n'ont pas une bosse. Ils ont juste l'air un peu vexés. Ça leur passera. Ça leur passe toujours.", "objectif": "Pendant une Grande Alerte des Navets (quand Mélusine sonne sa cloche, le jour), courir aux Champs du Sud (au sud de la ville, par la Porte Sud), attraper cinq navets fuyards d'un petit coup, puis les apporter à Père Gaubert (dans ses champs, près de la ferme)"},
		],
		"fin": "Merci, mon gars. Tiens, quelques pièces, et un sac de graines. Plante-les où tu veux. Mais si un jour ils se sauvent… ce ne sera pas ma faute. Ce sera la terre de Montjoie.",
		"recompense": {"pieces": 25, "rep": 4, "objets": [["graines", 3]]}},
	{"id": "mj_chapeau", "titre": "Le chapeau du Baron", "donneur": "barthelemy", "lieu": "Île de Montjoie, le Château", "sorte": "Île de Montjoie",
		"resume": "Le Baron Barthélemy a perdu son plus beau chapeau, le chapeau à plume : le vent l'a emporté par-dessus la muraille du château. On l'a vu passer sur les toits de la Ville-Moyenne… puis plus rien.",
		"offre_label": "Monsieur le Baron, vous êtes tout décoiffé !",
		"offre": "Décoiffé ! C'est le mot ! Mon chapeau à plume ! Le plus beau ! Celui des grandes occasions, des petites occasions, et des jours sans occasion ! Le vent l'a emporté depuis le rempart. Il a sauté de toit en toit, au-dessus de la Ville-Moyenne, puis il s'est envolé vers le sud. Aurore dit qu'il reviendra tout seul. Il ne revient jamais tout seul. Vous voudriez bien le chercher, jeune personne ? Il a une plume verte. Il est très distingué. Vous le reconnaîtrez.",
		"etapes": [
			{"type": "ramasser", "objets": {"chapeau_baron": 1}, "lieux": ["chapeau_baron"], "objectif": "Retrouver le chapeau à plume du Baron (le vent l'a emporté vers le sud : cherchez au sommet du moulin de Clovis, aux Champs du Sud)"},
			{"type": "objets", "pnj": "barthelemy", "objets": {"chapeau_baron": 1}, "label": "Voici votre chapeau à plume, Monsieur le Baron.", "texte": "MON CHAPEAU ! (Il le pose sur sa tête, l'enlève, l'embrasse, le remet.) Sur le moulin ! Il voulait voir la campagne, le coquin. Il a un peu de farine sur la plume. Ça lui donne l'air sage. Merci, merci, merci ! Aurore ! AURORE ! Mon chapeau est revenu ! Tout seul ! … Avec de l'aide.", "objectif": "Rapporter le chapeau au Baron Barthélemy (au château, au sommet de la Butte : salle du trône le matin, jardin ou rempart l'après-midi)"},
		],
		"fin": "Pour vous, jeune personne, une petite bourse. Et une invitation permanente au château. Venez quand vous voulez. Aurore vous fera visiter les placards à chapeaux. Il y en a quarante-deux. Prévoyez la journée.",
		"recompense": {"pieces": 30, "rep": 4}},
	{"id": "mj_maison", "titre": "Une maison à soi", "donneur": "prosper", "lieu": "Île de Montjoie, la Haute-Ville", "sorte": "Île de Montjoie",
		"resume": "Monsieur Prosper, le marchand de maisons de la Haute-Ville, vend la Chaumière des Glycines : un lit, une cheminée, une étagère à trophées et une façade couverte de glycines. Trois cents pièces. Il exagère tout. Sauf les glycines.",
		"offre_label": "Parlez-moi de la Chaumière des Glycines.",
		"offre": "LA CHAUMIÈRE DES GLYCINES ! Un palais ! Un rêve ! Un lit si doux qu'on s'y réveille reposé, quelle que soit la nuit qu'on a passée ! Une étagère où vos trophées des autres îles brilleront comme des étoiles ! Une cheminée ! Un toit ! Presque entier ! Et si vous vous évanouissez sur l'île, c'est chez vous qu'on vous ramènera, pas entre deux bancs du temple ! Trois cents pièces. Pas une de moins. Croyez-moi : c'est une affaire exceptionnelle. Et en plus… c'est vrai.",
		"etapes": [
			{"type": "objets", "pnj": "prosper", "objets": {"piece": 300}, "label": "Voici trois cents pièces. Je l'achète.", "texte": "(Il compte les pièces une par une. Sa moustache tremble.) Trois cents… Exceptionnel. (Il sort de sa poche un vieux parchemin, noué d'un ruban violet.) Le titre de propriété. Et la clé : elle était à ma grand-mère. La maison est à vous. Elle vous attend. Une maison, c'est un endroit qui vous attend.", "donne": [["titre_propriete", 1]], "objectif": "Payer trois cents pièces à Monsieur Prosper (à son agence de la Haute-Ville, ou dans le jardin de la Chaumière des Glycines à midi)"},
		],
		"fin": "Allez-y. Poussez la porte. Le lit est fait. L'étagère est vide, mais plus pour longtemps. Et le soir, quand je passerai devant… ne faites pas attention à moi. Je regarderai juste si la fenêtre est allumée.",
		"recompense": {"pieces": 0, "rep": 6, "titre": "Propriétaire à Montjoie"}},
	{"id": "mj_grimoire", "titre": "Les pages envolées", "donneur": "olga", "lieu": "Île de Montjoie, la boutique de magie", "sorte": "Île de Montjoie",
		"resume": "Madame Olga a ouvert sa fenêtre pour faire sortir un sortilège de courant d'air. Le sortilège est sorti, avec trois pages de son grimoire. Elles se sont éparpillées dans toute la ville.",
		"offre_label": "Madame Olga, votre grimoire a l'air bien mince…",
		"offre": "Mince ! Il est maigre comme un balai, mon pauvre grimoire ! J'ai ouvert la fenêtre pour faire sortir un petit sortilège de courant d'air, et il est parti avec trois pages ! Les plus importantes ! Enfin, je crois : je ne me souviens plus de ce qu'il y avait dessus. C'est pour ça qu'elles sont importantes. Elles se sont envolées au-dessus de la ville. Retrouve-les-moi, mon chou. Elles brillent un peu. Elles sont sûrement magiques.",
		"etapes": [
			{"type": "ramasser", "objets": {"page_grimoire": 3}, "lieux": ["page_grimoire_1", "page_grimoire_2", "page_grimoire_3"], "objectif": "Retrouver trois pages de grimoire envolées dans Montjoie (elles brillent un peu : sur la Grand-Place, dans la Haute-Ville, dans la Basse-Ville…)"},
			{"type": "objets", "pnj": "olga", "objets": {"page_grimoire": 3}, "label": "Voici vos trois pages, Madame Olga.", "texte": "Mes pages ! (Elle les recoud dans le grimoire avec une aiguille qui coud toute seule… presque.) Voyons… « Comment changer une bulle en papillon. » « Comment retrouver ses lunettes. » « Soupe aux orties. » Oh ! La soupe ! Je la cherchais depuis des années !", "objectif": "Rapporter les trois pages à Madame Olga (à sa boutique de magie, sur la Grand-Place)"},
		],
		"fin": "Tiens, mon chou : deux potions de mana, pour ta peine. Elles sont sûrement magiques. Celles-là, j'en suis presque sûre.",
		"recompense": {"pieces": 30, "rep": 4, "objets": [["potion_mana", 2]]}},
	{"id": "mj_pain", "titre": "La tournée du pain", "donneur": "honorine", "lieu": "Île de Montjoie, la boulangerie", "sorte": "Île de Montjoie",
		"resume": "Honorine est seule au four ce matin. Il reste trois pains à livrer : un à Mamie Rissole, à la taverne de la Guilde ; un à Aurore, au château ; un à Gilles, à la Porte Nord. Si elle quitte le four, tout brûle.",
		"offre_label": "Je peux vous aider, Honorine ?",
		"offre": "Oh, oui, mon petit ! Je suis toute seule, Noisette est partie suivre un aventurier, et il me reste trois pains à livrer ! Un pour Mamie Rissole, à la taverne de la Guilde. Un pour Aurore, au château, tout en haut : sans son pain, le Baron met son chapeau de deuil. Et un pour Gilles, à la Porte Nord. S'il dort, pose-le sous son nez : il se réveillera. Tiens, voilà les trois. Ne les mange pas en route ! Enfin… pas tout.",
		"donne": [["pain_montjoie", 3]],
		"etapes": [
			{"type": "objets", "pnj": "rissole", "objets": {"pain_montjoie": 1}, "label": "Le pain d'Honorine, pour la taverne.", "texte": "Ah ! Le pain d'Honorine ! (Elle le renifle, ravie.) Il sent le matin. Merci, mon poussin. Assieds-toi, tu as fait tout ce chemin… Non ? Tu as encore deux pains ? Alors prends au moins une part pour la route. Mange !", "objectif": "Porter un pain à Mamie Rissole (à la taverne, au fond de la Guilde des Aventuriers)"},
			{"type": "objets", "pnj": "aurore", "objets": {"pain_montjoie": 1}, "label": "Le pain du château, de la part d'Honorine.", "texte": "Le pain ! (Elle soupire de soulagement.) Le Baron avait déjà sorti son chapeau de deuil. Je vais le lui porter tout de suite. Merci. Vous avez sauvé la matinée du château. Ce n'est pas rien : elle est souvent en danger.", "objectif": "Porter un pain à Aurore (au château, au sommet de la Butte : prenez les rampes en lacets jusqu'en haut)"},
			{"type": "objets", "pnj": "gilles", "objets": {"pain_montjoie": 1}, "label": "Gilles ? Le pain d'Honorine…", "texte": "Zzz… (Il renifle, sans ouvrir les yeux.) … Honorine ? (Il ouvre un œil.) Oh ! C'est vous ! Merci ! Je ne dormais pas, hein. Je sentais. C'est le meilleur pain de l'île. Dites-lui merci. Dites-lui que je ne dormais pas.", "objectif": "Porter un pain à Gilles (le garde de la Porte Nord, dans la Basse-Ville, du côté du port)"},
			{"type": "rendre", "pnj": "honorine", "label": "Les trois pains sont livrés, Honorine !", "objectif": "Revenir voir Honorine (à la boulangerie, dans la Ville-Moyenne)"},
		],
		"fin": "Tous les trois ! Et chauds encore, je parie. Tu es un amour, mon petit. Tiens, des pièces, et un pain au miel tout chaud. Celui-là, tu as le droit de le manger en route.",
		"recompense": {"pieces": 15, "rep": 3, "objets": [["pain_miel", 1]]}},
	# ================================================================ V75 : l'Île du Boucan (Port-Boucan)
	{"id": "bo_bienvenue", "titre": "Bienvenue au Boucan", "donneur": "rouille", "lieu": "Île du Boucan, la Conserverie", "sorte": "Île du Boucan",
		"resume": "Rouille, la chanteuse des Rats de Cale, veut que tu fasses connaissance avec Port-Boucan. Pour commencer : saluer Lentille à la Cantine à prix libre, Rustine à l'atelier vélo et Sirène au bar de la Halle Hurlante.",
		"offre_label": "Rouille, tu peux me présenter un peu la ville ?",
		"offre": "TE PRÉSENTER ? Avec plaisir ! Bon, je ne peux pas te présenter tout le monde, on est trop nombreux et Tapage parlerait pendant trois jours. Alors commence par les trois piliers du Boucan : Lentille, qui nourrit tout le monde à la Cantine, au rez-de-chaussée de la Conserverie ; Rustine, qui fait rouler tout ce qui a des roues, à l'atelier vélo de la Filature ; et Sirène, qui abreuve tout ce qui a soif, au bar de la Halle Hurlante. Dis-leur que c'est Rouille qui t'envoie. Ils te feront un accueil… bruyant.",
		"etapes": [
			{"type": "parler", "pnj": "lentille", "label": "Rouille m'envoie te dire bonjour !", "texte": "Rouille t'envoie ? Alors tu fais partie de la famille ! Tiens, goûte. (Il te tend sa louche géante, pleine de soupe.) Non, pas la louche entière. Juste une gorgée. … Voilà. Maintenant tu connais le goût du Boucan. Reviens quand tu veux : ici, tu paies ce que tu peux. Même zéro. Surtout si tu as faim.", "objectif": "Saluer Lentille à la Cantine à prix libre (au rez-de-chaussée de la Conserverie, la grande usine de briques à fresques, à l'ouest de la Halle Hurlante)"},
			{"type": "parler", "pnj": "rustine", "label": "Rouille m'envoie te dire bonjour !", "texte": "(Elle siffle deux notes et s'essuie les mains. Ça ne change rien.) Bienvenue ! Une amie de Rouille, c'est une amie à moi. Si un jour tu as un vélo qui grince, une roue voilée ou une chaîne qui saute, viens à l'atelier. Je ne te le réparerai pas : je t'apprendrai à le réparer. C'est mieux. Et c'est plus long. Mais c'est mieux.", "objectif": "Saluer Rustine à l'atelier vélo (à la Filature, le long hangar de briques aux toits en dents de scie, au sud de la Place des Palettes)"},
			{"type": "parler", "pnj": "sirene", "label": "Rouille m'envoie te dire bonjour !", "texte": "Rouille ? Alors c'est la maison qui offre. (Elle pose devant toi une limonade avec une paille en forme de rat.) Limonade de Sirène, citron, menthe et bulles. Rien qui tourne la tête : juste de quoi danser jusqu'à minuit. Le soir, il y a concert. Viens. Et apporte tes oreilles, Larsen se charge du reste.", "objectif": "Saluer Sirène au bar de la Halle Hurlante (l'ancienne halle des forges à grande verrière, au nord-est de la Place des Palettes)"},
			{"type": "rendre", "pnj": "rouille", "label": "J'ai salué Lentille, Rustine et Sirène !", "objectif": "Retourner voir Rouille (à la Conserverie le matin, sur la place ou les quais l'après-midi, à la Halle Hurlante le soir)"},
		],
		"fin": "LES TROIS ! Bravo ! Maintenant, tu as goûté la soupe, entendu siffler Rustine et bu la limonade de Sirène : tu es officiellement du Boucan. Bon, il n'y a pas de papier officiel. On a voté contre les papiers en assemblée. Tiens, quelques pièces de la caisse commune, pour tes premiers jours. Et viens au concert ce soir : on t'attend dans la fosse !",
		"recompense": {"pieces": 10, "rep": 0}},
	{"id": "bo_concert", "titre": "Le Grand Boucan", "donneur": "rouille", "lieu": "Île du Boucan, la Halle Hurlante", "sorte": "Île du Boucan",
		"si": {"apres": "bo_bienvenue"},
		"resume": "Les robots déménageurs de Monsieur Lisse ont volé le matériel des Rats de Cale juste avant le Grand Boucan, le plus grand concert de l'année : Germaine-la-Terrible, la guitare de Clou, l'ampli à lampes et les baguettes de batterie. Il faut tout retrouver, rendre la guitare et l'ampli à Rouille, puis venir au Grand Boucan, le soir, à la Halle Hurlante.",
		"offre_label": "Rouille, pourquoi tout le monde fait cette tête ?",
		"offre": "Parce que c'est la CATASTROPHE ! Cette nuit, les robots de Lisse sont entrés dans la Halle. Poliment, en s'excusant, mais ils sont entrés. Ils ont emporté Germaine, la guitare de Clou. Clou n'a rien dit. Il n'a rien dit encore plus fort que d'habitude. Ils ont aussi pris l'ampli, et les baguettes de batterie ! Et le Grand Boucan, c'est bientôt : des invités vont venir de toutes les îles ! Ferraille a vu des robots porter une guitare vers l'Usine Grise ; un ampli traîne peut-être à la Casse ; et Tornade jure qu'un robot a fait tomber quelque chose au Bassin à sec. Tu nous aides ? Tu seras notre héros. Notre roadie-héros.",
		"etapes": [
			{"type": "ramasser", "objets": {"guitare_rouille": 1}, "lieux": ["guitare_rouille"], "objectif": "Retrouver Germaine-la-Terrible, la guitare de Clou (au repaire des robots, devant le portail de l'Usine Grise, au sud-est, derrière le Bois des Spores)"},
			{"type": "ramasser", "objets": {"ampli": 1}, "lieux": ["ampli"], "objectif": "Retrouver l'ampli à lampes (à la Casse, au sud-est, au milieu des tas de ferraille, près du dragon de Ferraille)"},
			{"type": "ramasser", "objets": {"baguettes": 1}, "lieux": ["baguettes"], "objectif": "Retrouver les baguettes de batterie (au Bassin à sec, le skatepark, au nord-est de la ville, à côté du port)"},
			{"type": "objets", "pnj": "rouille", "objets": {"guitare_rouille": 1, "ampli": 1}, "label": "Voici Germaine et l'ampli ! Et j'ai aussi les baguettes.", "texte": "GERMAINE ! L'AMPLI ! (Elle court chercher Clou. Clou arrive, prend Germaine, la serre contre lui et ne dit rien pendant une minute entière. Puis il te fait un signe de tête. Un seul. Rouille pleure.) Il t'a fait un signe de tête ! Tu sais combien de gens ont eu un signe de tête de Clou ? Quatre ! Et les baguettes… garde-les, toi. On n'a pas encore de vrai batteur. Elles attendent quelqu'un. Peut-être que tu trouveras qui.", "objectif": "Rendre la guitare et l'ampli à Rouille (à la Conserverie le matin, sur la place l'après-midi, à la Halle Hurlante le soir)"},
			{"type": "etat", "cle": "grand_boucan", "objectif": "Venir au Grand Boucan, le grand concert des Rats de Cale, le soir (à partir de 21 h) à la Halle Hurlante, et danser dans la fosse"},
			{"type": "rendre", "pnj": "rouille", "label": "Quel concert, Rouille !", "objectif": "Parler à Rouille après le concert (à la Halle Hurlante, ou le lendemain à la Conserverie)"},
		],
		"fin": "QUEL CONCERT ! Tu as vu la fosse ? Tu as vu Mamie Barricade lever le poing sur la mezzanine ? Tu as vu Clou SOURIRE ? Moi oui, j'ai tout vu, et je n'ai plus de voix. (Elle chuchote.) Merci. Sans toi, ça aurait été un tout petit boucan. Tiens : la recette des entrées. Il n'y avait pas d'entrées, c'est gratuit, alors c'est la recette de la boîte à dons. Et tu es désormais, officiellement, pour toujours… Fan n°1 des Rats de Cale.",
		"recompense": {"pieces": 60, "rep": 0, "titre": "Fan n°1 des Rats de Cale", "objets": [["patch_rat", 1]]}},
	{"id": "bo_affiches", "titre": "L'affiche qui voyage", "donneur": "agrafe", "lieu": "Île du Boucan, l'imprimerie de la Filature", "sorte": "Île du Boucan",
		"si": {"apres": "bo_concert"},
		"resume": "Agrafe et Pigment ont imprimé les affiches du prochain Grand Boucan. Pour que le monde entier vienne, il faut les porter sur les autres îles : à Paulo, à Port-Azur ; à Ulric, l'aubergiste de Montjoie ; et à Tom le Violoneux, au Crâne Fendu, sur l'Île de la Balafre.",
		"offre_label": "Elles sont belles, ces affiches !",
		"offre": "Belles ? Elles sont AFFICHE-NANTES ! … Bon. Pigment a peint le rat, j'ai imprimé les lettres, et on s'est disputés sur la couleur pendant trois heures. Elle voulait du vert, je voulais du noir. On a mis du vert. Le prochain Grand Boucan doit être le plus grand de tous les temps, avec des gens venus de partout ! Mais nos affiches ne savent pas nager. Toi, tu voyages. Tu pourrais en porter trois : une à Paulo, le cuisinier de Port-Azur ; une à Ulric, l'aubergiste de Montjoie ; et une à Tom le Violoneux, le musicien du Crâne Fendu, à la Balafre. Les belles rencontres, ça commence par une affiche !",
		"donne": [["affiche_concert", 3]],
		"etapes": [
			{"type": "objets", "pnj": "paulo", "objets": {"affiche_concert": 1}, "label": "Une affiche du Grand Boucan, de la part de Port-Boucan !", "texte": "Un concert ? Des punks ? (Il regarde l'affiche, le rat, la crête.) Mamma mia, quel rat ! Il a la crête de mon cousin Gino ! Je la mets dans ma vitrine, à côté de la bouillabaisse. Et tu sais quoi ? Je viendrai ! Avec une marmite ! Une soupe de poissons pour toute la fosse ! Les punks, ils mangent, non ? Tout le monde mange. Même en sautant.", "objectif": "Porter une affiche à Paulo (à Port-Azur, à son restaurant Chez Paulo, sur le port, de 10 h à 15 h et de 18 h à 23 h)"},
			{"type": "objets", "pnj": "ulric", "objets": {"affiche_concert": 1}, "label": "Une affiche du Grand Boucan, pour votre auberge !", "texte": "Un concert ! Avec des rats ! (Il plisse les yeux.) Des rats musiciens, pas des rats de cuisine ? Bon. Je l'accroche au-dessus du comptoir, à côté de ma grenouille à serviette. Elles vont bien ensemble. Et je viendrai ! Avec ma grenouille en croûte numéro neuf : celle qu'on peut manger en sautant. Elle tient très bien dans la main. Elle a été conçue pour les aventuriers en fuite.", "objectif": "Porter une affiche à Ulric (sur l'Île de Montjoie, à son auberge « La Grenouille Repue », dans la Ville-Moyenne, près de la Grand-Place)"},
			{"type": "objets", "pnj": "tom", "objets": {"affiche_concert": 1}, "label": "Une affiche du Grand Boucan, pour le Crâne Fendu !", "texte": "Un concert de punks ? (Il fait grincer son violon, ravi.) Des gens qui jouent fort et vite, et qui sautent partout ? Mais ce sont des pirates sans bateau ! Je l'accroche au-dessus de ma scène. Et je viendrai ! Avec mon violon ! J'ai toujours rêvé de faire une gigue avec une guitare électrique. Dis à ta chanteuse que Tom le Violoneux sera dans la fosse. Au premier rang. Avec un tricorne. Elle me reconnaîtra.", "objectif": "Porter une affiche à Tom le Violoneux (sur l'Île de la Balafre, à Port-Coutelas : il joue le soir sur la scène du Crâne Fendu, l'après-midi on le croise sur la place)"},
			{"type": "rendre", "pnj": "agrafe", "label": "Les trois affiches ont voyagé, Agrafe !", "objectif": "Revenir voir Agrafe (à l'imprimerie de la Filature, ou le soir au Mur d'Expression)"},
		],
		"fin": "Paulo vient avec une marmite ? Ulric avec des grenouilles ? Et un pirate violoniste ? (Il note tout dans son carnet, plein d'encre.) Stop les presses ! Ça, c'est la une du prochain Boucanier : « LES ÎLES SE DONNENT RENDEZ-VOUS AU BOUCAN ! » Et en dessous, en petit : « grâce à un facteur d'affiches héroïque ». C'est toi. Tiens, pour tes pieds fatigués, et un fanzine encore chaud.",
		"recompense": {"pieces": 35, "rep": 0, "objets": [["fanzine", 1]]}},
	{"id": "bo_champignons", "titre": "Le Grand Herbier", "donneur": "morille", "lieu": "Île du Boucan, la Cathédrale des Spores", "sorte": "Île du Boucan",
		"resume": "Mère Morille, la sage de la Cathédrale des Spores, veut t'apprendre les cinq champignons féeriques qui poussent dans l'ancien gazomètre : le Bolet-Ressort, la Lunaire, le Babillard, l'Arc-en-ciel et le Petit-Géant. Il faut les cueillir et venir les lui montrer. Ce sont des champignons de conte : dans la vraie vie, on ne mange jamais un champignon qu'on ne connaît pas.",
		"offre_label": "Mère Morille, quels sont ces champignons qui brillent ?",
		"offre": "Ah… tu les as vus briller, mon petit champignon. Ce sont les champignons féeriques. Ils n'existent que dans les contes, et dans cette cathédrale, qui est un peu un conte elle-même. Il y en a cinq : le Bolet-Ressort, la Lunaire, le Babillard, l'Arc-en-ciel et le Petit-Géant. Va les cueillir, un de chaque, et rapporte-les-moi : je te dirai ce que chacun fait. Mais écoute-moi bien, c'est le plus important. (Elle pose sa main sur ton épaule.) Dans un conte, oui. Dans la vraie forêt : jamais ! Jamais, jamais tu ne mangeras un champignon que tu ne connais pas. Même s'il est joli. Surtout s'il est joli. Promis ?",
		"etapes": [
			{"type": "ramasser", "objets": {"champi_ressort": 1}, "lieux": ["champi_1"], "objectif": "Cueillir un Bolet-Ressort, au chapeau orange tout bondissant (dans la Cathédrale des Spores, l'ancien gazomètre au sud de la ville)"},
			{"type": "ramasser", "objets": {"champi_lune": 1}, "lieux": ["champi_2"], "objectif": "Cueillir une Lunaire, pâle et argentée (dans la Cathédrale des Spores)"},
			{"type": "ramasser", "objets": {"champi_babil": 1}, "lieux": ["champi_3"], "objectif": "Cueillir un Babillard, qui fait de petits bruits quand on s'approche (dans la Cathédrale des Spores)"},
			{"type": "ramasser", "objets": {"champi_arcenciel": 1}, "lieux": ["champi_4"], "objectif": "Cueillir un Arc-en-ciel, aux lamelles de toutes les couleurs (dans la Cathédrale des Spores)"},
			{"type": "ramasser", "objets": {"champi_geant": 1}, "lieux": ["champi_5"], "objectif": "Cueillir un Petit-Géant, minuscule mais très fier (dans la Cathédrale des Spores)"},
			{"type": "rendre", "pnj": "morille", "label": "Voici les cinq champignons féeriques, Mère Morille.", "objectif": "Montrer les cinq champignons à Mère Morille (à sa roulotte, au milieu de la Cathédrale des Spores)"},
		],
		"fin": "(Elle les regarde un par un, en souriant.) Le Bolet-Ressort : tu sauteras trois fois plus haut. La Lunaire : tu verras ce qui est caché. Le Babillard : tu comprendras les bêtes, et crois-moi, elles ont beaucoup à dire. L'Arc-en-ciel : le monde dansera de couleurs et tes pieds iront plus vite. Le Petit-Géant : tu grandiras un moment, et tu seras plus fort. Garde-les : ce sont les tiens. Tu peux les manger depuis ton sac, ici, dans notre conte. Et dans la vraie forêt ? … Jamais ! Bien. Tu as retenu. Tiens, pour la route, deux Bolets-Ressorts de plus.",
		"recompense": {"pieces": 30, "rep": 0, "objets": [["champi_ressort", 2]]}},
	{"id": "bo_sardine", "titre": "Où est Sardine ?", "donneur": "tornade", "lieu": "Île du Boucan, la Casse", "sorte": "Île du Boucan",
		"resume": "Sardine, le chien de Tornade, un bâtard joyeux au bandana rouge, a suivi un robot de Lisse et n'est pas revenu. Chaussette pense qu'il est parti vers la Casse, au sud-est.",
		"offre_label": "Tornade, tu as l'air tout triste…",
		"offre": "C'est Sardine ! Mon chien ! Il est parti ce matin derrière un robot de Lisse. Il court toujours après les robots, il croit que ce sont des grosses boîtes de croquettes ! Il a un bandana rouge, une oreille levée, une oreille baissée, et il sent un peu le poisson. J'ai cherché partout dans la ville. Chaussette dit que ses chiens ont senti sa piste vers la Casse. Mais Maman ne veut pas que j'aille à la Casse tout seul. Tu veux bien y aller, toi ? S'il te plaît ? Il s'appelle Sardine. Il vient quand on siffle. Enfin, quand il veut.",
		"etapes": [
			{"type": "etat", "cle": "sardine_trouvee", "objectif": "Retrouver Sardine, le chien au bandana rouge (à la Casse, au sud-est de l'île, au milieu des carcasses de voitures : écoute bien, il aboie aux robots)"},
			{"type": "rendre", "pnj": "tornade", "label": "J'ai retrouvé Sardine !", "objectif": "Ramener Sardine à Tornade (au Bassin à sec, le skatepark, au nord-est de la ville)"},
		],
		"fin": "SARDINE ! (Le chien saute sur Tornade, lui lèche toute la figure, puis revient s'asseoir à tes pieds. Tornade le regarde, puis te regarde, et renifle.) … Il ne veut plus te quitter, hein. Je le vois bien. Il t'a choisi. (Il frotte ses yeux avec son poing.) C'est d'accord. Tu peux le garder avec toi. Mais tu prends soin de lui, hein ! Il aime les os à mâcher, il mord les robots, et parfois il rapporte des pièces. Personne ne sait où il les trouve. Tiens, ses os à mâcher. Et tu me le ramènes au skatepark de temps en temps. Promis ?",
		"recompense": {"pieces": 20, "rep": 0, "objets": [["os_sardine", 3]]}},
	{"id": "bo_radio", "titre": "Ici Radio Boucan", "donneur": "sergent", "lieu": "Île du Boucan, le Cargo", "sorte": "Île du Boucan",
		"resume": "Pendant la dernière tempête, l'antenne de Radio Boucan s'est envolée du mât de la Baleine Rouillée et s'est posée au sommet du château d'eau peint. Sans elle, Sergent Fréquence parle dans le vide.",
		"offre_label": "Sergent, votre radio grésille…",
		"offre": "Grésille ? Elle ne grésille même plus ! Elle fait… rien ! Pschhh… rien du tout ! La tempête a arraché mon antenne du mât de la Baleine Rouillée. Je l'ai vue s'envoler comme une mouette en ferraille, par-dessus la ville, et se poser tout en haut du château d'eau peint, à l'est. Vingt-huit mètres ! Fusible a le vertige au deuxième barreau, Boulon est trop lourd pour l'échelle, et moi… moi, je suis animateur radio, pas alpiniste. Tu veux bien aller la chercher ? Je te ferai une émission spéciale. De quatre heures. Rien que sur toi.",
		"etapes": [
			{"type": "ramasser", "objets": {"antenne_radio": 1}, "lieux": ["antenne_radio"], "objectif": "Récupérer l'antenne de Radio Boucan (tout en haut du château d'eau peint, à l'est de la ville)"},
			{"type": "objets", "pnj": "sergent", "objets": {"antenne_radio": 1}, "label": "Voici votre antenne, Sergent !", "texte": "MON ANTENNE ! (Il la serre dans ses bras, grimpe au mât, la revisse, redescend, se jette sur son micro.) Pschhh… Pschhh… ICI RADIO BOUCAN, 98.7, LA RADIO QUI NE S'ÉTEINT JAMAIS… SAUF QUAND L'ANTENNE TOMBE ! ET ELLE EST REMONTÉE ! Mesdames et messieurs, chers auditeurs, chères mouettes, l'antenne a été sauvée par un héros que vous connaissez tous ! … Enfin, que vous allez connaître. Je vais en parler jusqu'à demain.", "objectif": "Rapporter l'antenne à Sergent Fréquence (au studio de Radio Boucan, dans la timonerie du Cargo échoué au nord-ouest)"},
		],
		"fin": "Désormais, quand tu te promèneras en ville, tu m'entendras dans tous les haut-parleurs : les nouvelles, les petites annonces, la météo… et toi, de temps en temps. Tu es une vedette de la radio, maintenant. Tiens, ton cachet. Et reste à l'écoute !",
		"recompense": {"pieces": 30, "rep": 0}},
	{"id": "bo_mur", "titre": "Le mur qui parle", "donneur": "pigment", "lieu": "Île du Boucan, le Mur d'Expression", "sorte": "Île du Boucan",
		"resume": "Pigment, la graffeuse, trouve que tu as « une tête à faire de beaux murs ». Elle te confie trois bombes de peinture : il faut peindre trois graffitis sur les murs peignables de Port-Boucan.",
		"offre_label": "Pigment, je peux essayer de peindre ?",
		"offre": "Pschhht ! Évidemment ! Tout le monde peut peindre ici ! Tiens : trois bombes de peinture, faites maison, à la betterave, à l'épinard et à la myrtille. Elles sentent un peu la soupe, c'est normal. Va au Mur d'Expression, à l'ouest de la ville, ou sur un autre mur peignable, et laisse ta marque. Trois graffitis ! Un mur, c'est comme une page de fanzine, mais en plus grand et en plus vertical. Et n'aie pas peur de rater : le mur ne juge pas. Moi un peu, mais gentiment.",
		"donne": [["bombe_peinture", 3]],
		"etapes": [
			{"type": "etat", "cle": "graffitis_3", "objectif": "Peindre trois graffitis avec les bombes de peinture (au Mur d'Expression, à l'ouest de la ville, ou sur un autre mur peignable de Port-Boucan)"},
			{"type": "rendre", "pnj": "pigment", "label": "J'ai peint trois graffitis, Pigment !", "objectif": "Le dire à Pigment (au Mur d'Expression le matin, l'après-midi près du château d'eau ou du skatepark, le soir à l'imprimerie)"},
		],
		"fin": "Je les ai vus ! (Elle a des étoiles dans les yeux. Et un peu de peinture verte.) Ils sont… vivants ! Tu as le geste ! Le poignet souple, le pschhht franc ! Le mur te dit merci. Moi aussi. Tiens, une petite récompense, et sache une chose : sur le château d'eau, il y a une place pour ton nom. Je l'écrirai ce soir. En vert. Ne discute pas.",
		"recompense": {"pieces": 25, "rep": 0, "objets": [["bombe_peinture", 2]]}},
	{"id": "bo_cantine", "titre": "La soupe de tout le monde", "donneur": "lentille", "lieu": "Île du Boucan, la Cantine à prix libre", "sorte": "Île du Boucan",
		"resume": "Les paniers de légumes des Jardins Partagés ne sont pas arrivés à la Cantine à prix libre. Sans légumes, pas de soupe, et sans soupe, la moitié du Boucan aura faim ce soir. Il faut aller chercher trois paniers aux Jardins Partagés.",
		"offre_label": "Ça ne sent pas la soupe, aujourd'hui…",
		"offre": "Tu as le nez fin ! Pas de soupe ! Les paniers de légumes des Jardins Partagés ne sont pas arrivés. Radis les a préparés ce matin, mais il a dû les laisser dans les carrés : il interrogeait ses carottes. Ma marmite est vide, et une marmite vide, ça fait de l'écho. Va aux Jardins Partagés, à l'est de la ville, près des Boîtes, et ramène-moi trois paniers. Ne les mange pas en route ! Enfin… une carotte. Une seule. Je compterai.",
		"etapes": [
			{"type": "ramasser", "objets": {"panier_legumes": 3}, "lieux": ["panier_1", "panier_2", "panier_3"], "objectif": "Ramasser trois paniers de légumes dans les Jardins Partagés (à l'est de la ville, près du village de conteneurs des Boîtes)"},
			{"type": "objets", "pnj": "lentille", "objets": {"panier_legumes": 3}, "label": "Voici trois paniers de légumes, Lentille !", "texte": "Trois paniers ! Des poireaux, des courges, des pommes de terre, et… (Il sort une carotte croquée.) Une carotte. Une seule. Je t'avais dit que je compterais ! Ha ha ! (Il verse tout dans la marmite.) Ce soir, soupe de tout le monde ! Parce qu'elle est faite par tout le monde, et pour tout le monde. Et un peu par toi.", "objectif": "Apporter les trois paniers à Lentille (à la Cantine à prix libre, au rez-de-chaussée de la Conserverie)"},
		],
		"fin": "Tiens, quelques pièces, et deux bols de soupe à emporter. Ils sont dans des bocaux, avec un couvercle. Copeau a fait les couvercles. En palette, évidemment.",
		"recompense": {"pieces": 20, "rep": 0, "objets": [["soupe_prix_libre", 2]]}},
	{"id": "bo_velo", "titre": "Roue libre", "donneur": "rustine", "lieu": "Île du Boucan, l'atelier vélo", "sorte": "Île du Boucan",
		"resume": "Rustine n'a plus de pièces de vélo : les robots de Lisse ont fouillé la Casse pour se fabriquer des bras. Il reste trois lots de pièces cachés dans la Casse, au sud-est.",
		"offre_label": "Rustine, tu as l'air contrariée.",
		"offre": "(Elle siffle une note très longue et très grave.) Contrariée ? J'ai quatorze vélos à réparer et plus une seule pièce ! Plus de chaînes, plus de pédales, plus de rayons ! Les robots de Lisse ont fouillé la Casse et ils ont tout pris pour se fabriquer des bras. Mais Ferraille m'a dit qu'il avait caché trois lots de pièces sous ses tas de ferraille, juste pour moi. Tu veux bien aller les chercher ? C'est à la Casse, au sud-est. Si tu croises Ferraille, ne lui parle pas de son dragon : tu en aurais pour la journée.",
		"etapes": [
			{"type": "ramasser", "objets": {"pieces_velo": 3}, "lieux": ["velo_1", "velo_2", "velo_3"], "objectif": "Trouver trois lots de pièces de vélo cachés dans la Casse (au sud-est de l'île, sous les tas de ferraille)"},
			{"type": "objets", "pnj": "rustine", "objets": {"pieces_velo": 3}, "label": "Voici trois lots de pièces de vélo, Rustine !", "texte": "(Elle siffle trois notes joyeuses, ouvre les sacs, et sort une chaîne, des pédales, des rayons, une sonnette en forme de rat.) Une sonnette en forme de rat ! Ferraille, tu es un génie ! (Elle a déjà les mains dans le cambouis.) Avec ça, je remets dix vélos sur la route. Et le onzième, je te le garde. Enfin, si tu sais réparer une crevaison. Non ? Je t'apprendrai.", "objectif": "Apporter les trois lots de pièces à Rustine (à l'atelier vélo de la Filature)"},
		],
		"fin": "Tiens, des pièces. Des vraies, des rondes. Et une rustine, au cas où. On ne sait jamais quand on va crever. Un pneu, je veux dire.",
		"recompense": {"pieces": 25, "rep": 0}},
	{"id": "bo_robots", "titre": "La chaîne humaine", "donneur": "barricade", "lieu": "Île du Boucan, Port-Boucan", "sorte": "Île du Boucan",
		"si": {"apres": "bo_concert"},
		"resume": "De plus en plus souvent, les robots déménageurs de Monsieur Lisse débarquent sur les quais pour vider les squats. Mamie Barricade voudrait que tu aides le Boucan à repousser la prochaine Descente des Déménageurs.",
		"offre_label": "Mamie, que se passe-t-il quand la sirène sonne ?",
		"offre": "Quand la sirène sonne, mon grand, c'est que les robots de Lisse débarquent. Les déménageurs. Ils entrent dans un squat, ils prennent les canapés, les tables, les caisses, et ils emportent tout vers le port en disant « Merci de votre compréhension ». On ne comprend pas. Alors on sort tous, on se tient par les bras devant la porte, et on fait une chaîne. Une chaîne humaine. Les robots détestent ça : ce n'est pas dans leur programme. La prochaine fois que Sergent crie l'alerte, viens nous aider. Arrête les robots, sans faire de mal à personne d'autre qu'à des boulons. Et nous, on tiendra la porte.",
		"etapes": [
			{"type": "etat", "cle": "descente_repoussee", "objectif": "Quand la sirène sonne et que Sergent Fréquence crie l'alerte à la radio (le jour, en ville), repousser la Descente des Déménageurs : arrêter les robots avant qu'ils n'emportent les meubles jusqu'au port"},
			{"type": "rendre", "pnj": "barricade", "label": "Les robots sont repartis, Mamie !", "objectif": "Retrouver Mamie Barricade (à la Conserverie, salle des assemblées sur le toit, ou devant l'entrée l'après-midi)"},
		],
		"fin": "Je t'ai vu, mon grand. Depuis la chaîne. Tu les as arrêtés un par un, et pendant ce temps-là, nous, on se tenait par les bras, du premier étage jusqu'au trottoir. Quarante bras. Et les tiens. (Elle te passe une écharpe cloutée autour du cou.) C'est ça, le Boucan : personne ne tient tout seul, mais ensemble, on ne lâche rien. Tiens, la caisse commune a voté une petite prime. À l'unanimité. Même Tapage.",
		"recompense": {"pieces": 35, "rep": 0}},
	{"id": "bo_lisse", "titre": "Le Lisse-Center n'aura pas lieu", "donneur": "barricade", "lieu": "Île du Boucan, l'Usine Grise", "sorte": "Île du Boucan",
		"si": {"apres": "bo_robots"},
		"resume": "Tant que l'Usine Grise de Lisse & Fils fabriquera des robots, les descentes continueront. Mamie Barricade sait que les plans du Lisse-Center sont gardés tout au fond de l'usine, sous terre, par la machine préférée de Monsieur Lisse : la Grande Pelleteuse. Il faut descendre les cinq étages, vaincre la machine et rapporter les plans.",
		"offre_label": "Mamie, comment arrêter Lisse pour de bon ?",
		"offre": "Pour de bon ? (Elle pose son tricot.) Écoute-moi, mon grand. Lisse a une usine, au sud-est, derrière le Bois des Spores : l'Usine Grise. Sous l'usine, il y a cinq étages. Des bureaux, une chaîne de montage, une chaufferie, un entrepôt… et tout au fond, la Fosse du Président, où dort sa Grande Pelleteuse, une machine énorme, pilotée par un ordinateur. C'est là qu'il garde les plans du Lisse-Center. Sans plans, pas de Lisse-Center. Et sans Pelleteuse, plus de robots. Je suis trop vieille pour descendre. Mais toi… Descends, vaincs cette machine, et rapporte-moi les plans. Et si tu croises le petit Aldric, là-dessous… ne lui fais pas de mal. C'est un gamin qui a oublié comment on joue.",
		"etapes": [
			{"type": "etat", "cle": "grande_pelleteuse", "objectif": "Entrer dans l'Usine Grise (au sud-est de l'île, derrière le Bois des Spores), descendre les cinq étages et vaincre la Grande Pelleteuse dans la Fosse du Président"},
			{"type": "objets", "pnj": "barricade", "objets": {"plans_lisse": 1}, "label": "Voici les plans du Lisse-Center, Mamie.", "texte": "(Elle déroule les plans sur ses genoux, très lentement. Quatre cents boutiques. Deux mille places de parking. Une fontaine qui joue un hymne.) … C'est tout ? C'est ça qu'il voulait mettre à la place de nos vies ? (Elle roule les plans.) Bon. On va les garder. On les accrochera dans la salle des assemblées, pour se souvenir. Et regarde qui arrive. (Monsieur Lisse est là, la cravate de travers, sa tablette éteinte sous le bras. Il ne dit rien. Puis il sort un stylo. Mamie lui tend un papier. Il signe. Ses mains tremblent un peu.) Le Bail collectif de Port-Boucan. Les lieux sont à ceux qui les font vivre. Signé Aldric Lisse. (Elle sourit.) Tiens, Aldric. Un caramel. Ça faisait longtemps.", "donne": [["bail_collectif", 1]], "objectif": "Rapporter les plans du Lisse-Center à Mamie Barricade (à la Conserverie, salle des assemblées sur le toit)"},
		],
		"fin": "Garde le Bail, mon grand. Non, ne discute pas : l'assemblée a voté. Il sera mieux chez toi que dans un tiroir : comme ça, il voyagera. Le Boucan est à nous, pour toujours, et grâce à toi. Tiens, la caisse commune au complet. Et un titre. On n'aime pas les titres, ici. Mais celui-là, on l'a voté en riant : Héros de Port-Boucan. Ce soir, concert. Tu passes devant tout le monde.",
		"recompense": {"pieces": 150, "rep": 0, "titre": "Héros de Port-Boucan"}},
	{"id": "bo_gedeon", "titre": "Le batteur caché", "donneur": "gedeon", "lieu": "Île du Boucan, la Halle Hurlante", "sorte": "Île du Boucan",
		"si": {"apres": "bo_lisse"},
		"resume": "Gédéon, le fils de Monsieur Lisse, tapote des rythmes sur tout ce qu'il touche. Tous les soirs, il écoute les Rats de Cale derrière la porte de la Halle Hurlante. C'est un batteur génial, mais il n'a ni baguettes ni courage. Les baguettes, tu les as gardées depuis le Grand Boucan…",
		"offre_label": "Gédéon, pourquoi vous tapotez toujours ?",
		"offre": "Moi ? Je ne tapote pas. (Tap-tap-tap, boum-tchak.) … Bon. Si. Je tapote. Depuis toujours. Sur tout. Vous savez, tous les soirs, j'écoute les Rats de Cale derrière la porte de la Halle. Je connais toutes les chansons. Toutes les parties de batterie. Et chaque soir, le batteur de remplacement se trompe, et moi, dans ma tête, je joue juste. Mais je n'ai pas de baguettes. Papa n'aurait jamais voulu. Et puis… je suis un Lisse. Ils ne voudront jamais d'un Lisse sur leur scène. (Il regarde tes mains.) Vous… vous avez des baguettes, non ? Celles du Grand Boucan ?",
		"etapes": [
			{"type": "objets", "pnj": "gedeon", "objets": {"baguettes": 1}, "label": "Tenez, Gédéon. Ces baguettes vous attendaient.", "texte": "(Il prend les baguettes comme on prend un oiseau. Il les fait tourner une fois entre ses doigts, sans même y penser. Puis il tapote le rebord d'un banc : un roulement si rapide, si net, que trois pigeons s'envolent et qu'un chien de Chaussette s'assoit pour écouter.) … Elles sont parfaites. (Il devient tout rouge.) Mais… monter sur scène ? Devant tout le monde ? Devant Rouille ? Je… Venez ce soir. Restez près de moi. Si vous êtes là, peut-être que j'oserai.", "objectif": "Donner les baguettes de batterie à Gédéon (au Bureau de vente de Lisse & Fils le jour, sur les quais en fin d'après-midi, à l'entrée de la Halle Hurlante le soir)"},
			{"type": "etat", "cle": "gedeon_batteur", "objectif": "Le soir (à partir de 21 h), retrouver Gédéon à l'entrée de la Halle Hurlante et l'accompagner jusqu'à la batterie : qu'il joue son premier concert avec les Rats de Cale"},
			{"type": "rendre", "pnj": "gedeon", "label": "Gédéon, vous avez été incroyable !", "objectif": "Parler à Gédéon après le concert (à la Halle Hurlante, ou le lendemain en ville)"},
		],
		"fin": "J'ai joué. J'ai JOUÉ ! (Il tapote ton épaule en rythme, il ne s'en rend même pas compte.) Rouille m'a demandé si je voulais revenir demain. Et après-demain. Et tous les soirs. Clou m'a fait un signe de tête. Mouette a fait la mouette. Tapage a pleuré, il a dit que c'était la poussière. Et Papa… Papa était au fond de la salle. Il a tapé du pied. Tout le concert. Il dit que c'était une crampe. (Il rit.) Je suis le batteur des Rats de Cale. Et le « Fils » de Lisse & Fils. Les deux. Merci. Tenez : mes premières pièces de musicien. Je n'en ai pas encore beaucoup. Mais celles-là, je les ai gagnées en jouant.",
		"recompense": {"pieces": 40, "rep": 0, "objets": [["patch_rat", 1]]}},
	# ================================================================ V76 : Astralys, l'île flottante des Lumens
	{"id": "as_bienvenue", "titre": "Bienvenue chez les Lumens", "donneur": "halo", "lieu": "Astralys, le Portail d'accueil", "sorte": "Astralys",
		"resume": "Halo, le gardien du Portail d'accueil, veut que tu deviennes un visiteur officiel d'Astralys, selon la tradition : te faire inscrire au registre par Écliptique, goûter le thé stellaire chez Gloubi, puis aller saluer la Doyenne Astrée.",
		"offre_label": "Halo, comment devient-on visiteur d'Astralys ?",
		"offre": "Ah ! Excellente question ! Je vous réponds en quatre minutes. (Il inspire.) Bien. Au nom du Conseil, de la Doyenne, de la Flèche, des ponts, des dômes et des planètes de la fontaine… Bon, je vois à votre visage que vous préférez la version courte. La tradition dit trois choses. Un : vous faire inscrire au registre des visiteurs par Écliptique, le chef du protocole, à la Salle du Conseil, au pied de la Flèche. Deux : goûter le thé stellaire de Gloubi, au Café Nébuleuse, sur l'Agora. Trois : aller saluer la Doyenne Astrée. Après ça, vous ne serez plus un simple Pied-Lourd. Vous serez un Pied-Lourd officiel. C'est beaucoup mieux. Il y a un badge.",
		"etapes": [
			{"type": "parler", "pnj": "ecliptique", "label": "Halo m'envoie m'inscrire au registre des visiteurs.", "texte": "Un visiteur ! À inscrire ! Au registre ! (Il ouvre un livre immense, qui lui tombe sur le pied.) Hum hum. Selon l'article douze, j'écris votre nom en lettres lumens… Voilà. Selon l'article treize, vous devez maintenant faire une révérence. Non, pas comme ça. Pas comme ça non plus. Selon l'article quatorze… Ah, il n'y a pas d'article quatorze. Bon. Vous êtes inscrit. Félicitations. C'était très protocolaire.", "objectif": "Se faire inscrire au registre par Écliptique (à la Salle du Conseil, au pied de la Flèche de Cristal, au centre de l'île ; à midi au Café Nébuleuse)"},
			{"type": "parler", "pnj": "gloubi", "label": "Halo dit qu'il faut goûter votre thé stellaire.", "texte": "Le thé de bienvenue ! Assieds-toi ! (Ses quatre bras s'agitent : une théière, une tasse, une soucoupe, une petite cuillère, tout en même temps.) Thé stellaire, servi bleu nuit, avec des paillettes d'or. Bois doucement : il a le goût de la menthe, de la pluie, et d'autre chose que personne n'arrive à nommer. Alors ? Tu ne trouves pas le nom non plus ? Bienvenue chez nous !", "objectif": "Goûter le thé stellaire de Gloubi (au Café Nébuleuse, à l'ouest de l'Agora des Étoiles)"},
			{"type": "rendre", "pnj": "astree", "label": "Bonjour, Doyenne. Halo m'envoie vous saluer.", "objectif": "Aller saluer la Doyenne Astrée (à la Salle du Conseil, au pied de la Flèche, le jour ; sur son banc de l'Agora pendant la Nuit des Aurores)"},
		],
		"fin": "Inscrit au registre, et le thé bu jusqu'à la dernière paillette ? Alors bienvenue, mon petit astre. Bienvenue pour de bon. (Elle épingle un badge rond sur ta poitrine : il brille et fait « bip-bip ».) Ton badge de visiteur. Il dit : « Pieds-Lourds, mais gentil. » C'est Écliptique qui a choisi les mots. Il voulait en mettre quarante. Tiens, aussi, un peu de thé pour la route, et quelques rondelles. Je ne sais pas à quoi elles servent, mais il paraît qu'en bas, c'est très apprécié.",
		"recompense": {"pieces": 15, "rep": 0, "objets": [["badge_visiteur", 1], ["the_stellaire", 2]]}},
	{"id": "as_musee", "titre": "La vitrine des îles", "donneur": "orbe", "lieu": "Astralys, le Musée des Mondes", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "Orbe, l'Archiviste du Musée des Mondes, veut compléter la grande vitrine des îles d'en bas : un coquillage de la mer de Port-Azur, une plume de perroquet de la Balafre, un scarabée de l'Île des Trois Soleils, un patch des Rats de Cale de l'Île du Boucan et un navet doré de Montjoie.",
		"offre_label": "Orbe, cette grande vitrine est presque vide…",
		"offre": "Presque vide ? Elle est VIDE ! Enfin, il y a l'étiquette. L'étiquette est très belle. « La vitrine des îles : un objet de chaque île d'en bas. » Mais je n'ai rien à mettre dessous ! Solenne dit qu'elle ne descend jamais. Les oiseaux ne rapportent que des brindilles. Et moi… je n'ose pas descendre. Vous, vous voyagez ! Rapportez-moi un coquillage de la mer, du côté de Port-Azur ; une plume de perroquet de la Balafre, l'île des pirates ; un scarabée du désert des Trois Soleils ; un patch des Rats de Cale, ces punks très bruyants du Boucan ; et un navet doré de Montjoie. On dit qu'ils courent. Un objet qui court ! Fascinant !",
		"etapes": [
			{"type": "objets", "pnj": "orbe", "objets": {"coquillage": 1, "plume_perroquet": 1, "scarabee": 1, "patch_rat": 1, "navet_dore": 1}, "label": "Voici cinq objets des îles d'en bas, Orbe !", "texte": "(Il pose chaque objet sous la vitrine comme on pose un œuf d'oiseau.) Un coquillage… il a la forme d'une petite maison ! Une plume… elle parle ? Non ? Dommage. Un scarabée… il est vivant ? Il est en pierre. Fascinant aussi. Un patch… un rat qui hurle, avec une crête. Ma préférée. Et le navet doré… (Le navet frissonne un peu.) Il bouge ! Il ne court plus, mais il bouge ! Fascinant, fascinant, FASCINANT !", "objectif": "Rapporter à Orbe un coquillage (sur les plages de Port-Azur ou de l'île du village), une plume de perroquet (Île de la Balafre), un scarabée (Île des Trois Soleils), un patch des Rats de Cale (Île du Boucan) et un navet doré (Île de Montjoie, aux Champs du Sud) — Orbe est au Musée des Mondes, à l'ouest de l'Agora"},
		],
		"fin": "La vitrine des îles est complète ! Les Lumens vont faire la queue jusqu'à la Flèche pour la voir. J'ai écrit les étiquettes moi-même. Le coquillage est étiqueté « petite maison de mer ». Le navet, « légume coureur, à ne pas laisser sans surveillance ». Tenez : une fleur de nébuleuse, la plus belle du Bazar, et quelques-unes de ces rondelles que vous aimez tant. Et revenez ! Il y a d'autres îles. Il y a toujours d'autres îles.",
		"recompense": {"pieces": 60, "rep": 0, "objets": [["fleur_nebuleuse", 1]]}},
	{"id": "as_etoiles", "titre": "Les lentilles du ciel", "donneur": "zenith", "lieu": "Astralys, l'Observatoire", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "La dernière pluie d'étoiles filantes a fêlé trois lentilles du grand télescope de Zénith. Pour en fondre de nouvelles, il lui faut trois fragments de météorite, tombés cette nuit-là sur l'île. Ensuite, il voudrait te montrer la Nuit des Aurores à travers le télescope réparé.",
		"offre_label": "Zénith, vous avez l'air bien triste…",
		"offre": "Triste ? Je suis… aveugle, presque. (Il montre le grand télescope.) La dernière pluie d'étoiles filantes. Un petit fragment de météorite, gros comme une noisette, est tombé pile dans le tube. Trois lentilles fêlées. Je vois les étoiles en trois morceaux. La Grande Ourse ressemble à trois petits ours fâchés. Il me faudrait trois fragments de météorite pour fondre de nouvelles lentilles. Il en est tombé partout, cette nuit-là : sur l'Agora, dans les Jardins suspendus, au Spatioport… Tu veux bien les chercher ? Ils sont noirs, lourds, et ils brillent encore un peu.",
		"etapes": [
			{"type": "ramasser", "objets": {"fragment_meteorite": 3}, "lieux": ["meteorite_1", "meteorite_2", "meteorite_3"], "objectif": "Ramasser trois fragments de météorite tombés pendant la dernière pluie d'étoiles filantes (un sur l'Agora des Étoiles, un dans les Jardins suspendus, un au Spatioport)"},
			{"type": "objets", "pnj": "zenith", "objets": {"fragment_meteorite": 3}, "label": "Voici trois fragments de météorite, Zénith.", "texte": "Trois ! Ils sont encore tièdes… (Il les fait fondre dans un petit four à lumière, souffle dessus, les polit avec sa cape.) Trois lentilles neuves. (Il colle son œil au télescope.) Oh… Oh ! La Grande Ourse est de nouveau une seule ourse ! Elle a l'air soulagée. Reviens cette nuit, pendant les aurores. Je veux te montrer quelque chose.", "objectif": "Apporter les trois fragments à Zénith (à l'Observatoire, sur l'îlot au nord, par le pont de lumière ; il dort le matin et travaille du soir jusqu'à l'aube)"},
			{"type": "etat", "cle": "aurores", "objectif": "Assister à la Nuit des Aurores (chaque nuit de 22 h à 2 h, au-dessus d'Astralys : la regarder depuis l'Agora, ou mieux, depuis l'Observatoire)"},
			{"type": "rendre", "pnj": "zenith", "label": "Zénith, j'ai vu les aurores !", "objectif": "Retrouver Zénith (à l'Observatoire, au télescope, la nuit)"},
		],
		"fin": "Tu as vu ? Au milieu des aurores, à travers mes nouvelles lentilles… (Il te fait regarder.) Là. Une toute petite étoile, au bord du ciel. Le soleil d'Ondelune. On ne le voit que les nuits d'aurores, quand le ciel est bien lavé. Je voulais que quelqu'un d'en bas le voie aussi. Maintenant, nous sommes deux. Tiens : un cristal astral, et un élixir d'étoile. Le cristal, c'est pour tes machines. L'élixir, c'est pour les soirs où tu te sentiras loin de chez toi.",
		"recompense": {"pieces": 50, "rep": 0, "objets": [["cristal_astral", 1], ["elixir_etoile", 1]]}},
	{"id": "as_graines", "titre": "Les graines qui tombent vers le haut", "donneur": "photon", "lieu": "Astralys, les Jardins suspendus", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "Les graines lumineuses de Photon se sont envolées vers le Jardin des Apesanteurs : là-bas, rien ne retombe, et elles flottent tout en haut. Photon n'a plus les genoux pour sauter si haut. Il faut les rattraper (trois graines) et les lui rapporter pour les planter ensemble.",
		"offre_label": "Photon, vos plantes clignotent bizarrement…",
		"offre": "Elles s'inquiètent. (Une grande fleur clignote trois fois, très vite.) Tu vois ? Trois fois vite, ça veut dire « où sont les petites ? ». Les petites, ce sont mes graines lumineuses. Je les faisais sécher au soleil, au bout du pont de lumière… et un coup de vent les a poussées dans le Jardin des Apesanteurs. Là-bas, rien ne retombe. Elles flottent, tout en haut, entre les feuilles qui tombent vers le haut. Moi, avec mes genoux de huit cents ans, je saute comme une vieille courge. Toi, tu es jeune. Saute ! Attrape-les ! Trois graines, rondes et tièdes, qui luisent comme des veilleuses.",
		"etapes": [
			{"type": "ramasser", "objets": {"graine_lumineuse": 3}, "lieux": ["graine_lumineuse_1", "graine_lumineuse_2", "graine_lumineuse_3"], "objectif": "Rattraper trois graines lumineuses qui flottent en hauteur dans le Jardin des Apesanteurs (au bout du pont de lumière, après les Jardins suspendus : on y saute trois fois plus haut)"},
			{"type": "objets", "pnj": "photon", "objets": {"graine_lumineuse": 3}, "label": "Voici vos trois graines lumineuses, Photon.", "texte": "Les petites ! (Il les prend dans ses mains en coupe. Toutes les fleurs des Jardins clignotent deux fois. Deux fois, c'est merci.) Viens, on les plante ensemble. Un trou du doigt, une graine, un peu de terre, un peu d'eau… et un mot gentil. C'est le plus important, le mot gentil. Dis-lui quelque chose. … Voilà. Tu as vu ? Elle a clignoté. Elle t'a entendu. Demain matin, au lever du soleil, elles chanteront. Faux, sûrement. Mais avec beaucoup de cœur.", "objectif": "Rapporter les trois graines à Photon et les planter avec lui (dans les Jardins suspendus, à l'ouest de l'Agora)"},
		],
		"fin": "Merci, petite pousse. Tiens, une fleur de nébuleuse de mon jardin : elle s'ouvre quand tu es content. Et deux biscuits lunaires : Gloubi les fait avec la farine de mes fleurs. Ne le lui dis pas, il croit que c'est un secret.",
		"recompense": {"pieces": 35, "rep": 0, "objets": [["fleur_nebuleuse", 1], ["biscuit_lunaire", 2]]}},
	{"id": "as_meduse", "titre": "Plume-de-Nuage", "donneur": "nova", "lieu": "Astralys, la Serre des Espèces", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "Plume-de-Nuage, la plus jeune méduse de ciel de Nova, s'est échappée de la Serre des Espèces. Elle flotte quelque part autour de l'île et ne sait pas rentrer toute seule. Sextant, qui dessine l'île depuis les belvédères, l'a peut-être vue passer.",
		"offre_label": "Nova, vous cherchez quelque chose ?",
		"offre": "Quelqu'un ! Plume-de-Nuage, ma plus jeune méduse de ciel ! Elle est grande comme un parapluie, transparente, avec des petits reflets roses, et elle chante tout bas, comme un verre qu'on frotte. Ce matin, j'ai ouvert le toit de la Serre pour aérer… et pfuit. Elle est partie. Elle a un sens de l'orientation de méduse : nul. Elle doit flotter quelque part autour de l'île. Sextant passe ses journées à dessiner depuis les belvédères : demande-lui s'il l'a vue. Et si tu la trouves, approche doucement. Elle suit la lumière, et la gentillesse.",
		"etapes": [
			{"type": "parler", "pnj": "sextant", "label": "Sextant, avez-vous vu une méduse de ciel ?", "texte": "Une méduse ? Rose ? Qui chante faux ? (Il feuillette son carnet.) Je l'ai dessinée ce matin sans le faire exprès : je croyais que c'était un nuage. Là, regardez : elle dérivait vers l'ouest, du côté du Jardin des Apesanteurs. Les méduses adorent cet endroit, elles y tombent vers le haut. Si elle n'y est plus, cherchez sous les chutes de lumière, au bord de l'île. Ne vous penchez pas trop. J'ai déjà assez de mal à dessiner les gens debout.", "objectif": "Demander à Sextant s'il a vu Plume-de-Nuage (il dessine sur le belvédère du Portail le matin, au Musée vers midi, puis sur le pont de l'Observatoire, dans les Jardins ou au Spatioport)"},
			{"type": "etat", "cle": "meduse_rendue", "objectif": "Retrouver Plume-de-Nuage (une petite méduse de ciel rose, du côté du Jardin des Apesanteurs, à l'ouest) et la raccompagner doucement jusqu'à la Serre des Espèces : elle te suit si tu restes près d'elle"},
			{"type": "rendre", "pnj": "nova", "label": "Plume-de-Nuage est rentrée, Nova !", "objectif": "Retourner voir Nova (à la Serre des Espèces, au nord-est, après l'Académie)"},
		],
		"fin": "Elle est là ! Elle flotte au-dessus du bassin, avec son petit air coupable ! (Nova essuie une larme bleue.) Merci, merci ! Tu sais ce qu'elle chante, en ce moment ? Les glouglous traduisent : « Je suis allée voir le monde. Il est grand. Je préfère ici. » Tiens : deux gelées cosmiques de Gloubi, c'est tout ce que j'ai de précieux. Et tu peux venir voir Plume-de-Nuage quand tu veux. Elle se souviendra de toi. Les méduses n'oublient jamais ceux qui les ramènent.",
		"recompense": {"pieces": 40, "rep": 0, "objets": [["gelee_cosmique", 2]]}},
	{"id": "as_cache_cache", "titre": "Cache-cache à Astralys", "donneur": "pixel", "lieu": "Astralys, la cité", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "Pixel et son petit frère Quark jouent à cache-cache, et Quark triche toujours. Pixel propose une partie au héros : les deux enfants vont se cacher quelque part dans Astralys, et il faut les retrouver tous les deux.",
		"offre_label": "Pixel, tu veux jouer à quelque chose ?",
		"offre": "OUI ! À cache-cache ! Avec Quark ! Mais tu cherches, et nous, on se cache ! Pourquoi ? Parce que tu as les pieds lourds, tu fais du bruit, on t'entendra arriver, c'est plus juste ! Les règles : on se cache dans la ville, où on veut, mais pas dans les planètes de la fontaine. Ça, c'est Quark qui triche. Pas dans la Flèche non plus, Volt n'aime pas. Tu dois nous retrouver tous les deux ! Ferme les yeux et compte jusqu'à mille ! … Bon, jusqu'à dix. Les Pieds-Lourds comptent trop lentement.",
		"etapes": [
			{"type": "etat", "cle": "cache_cache_trouves", "objectif": "Retrouver Pixel et Quark, cachés quelque part dans Astralys (dans un coin de rue, derrière une plante géante, sur un banc flottant… Quark fredonne quand il se cache)"},
			{"type": "rendre", "pnj": "pixel", "label": "Je vous ai trouvés tous les deux !", "objectif": "Retourner voir Pixel pour la fin de la partie"},
		],
		"fin": "Tu nous as trouvés ! Tous les DEUX ! Même Quark ! Pourquoi tu es si fort ? Tu as des antennes cachées ? Montre ! … Non ? Bon. Tu es le premier Pied-Lourd champion de cache-cache. Quark boude. Il dit que tu as triché. C'est lui qui triche ! Tiens, nos biscuits lunaires de la récréation. On en a gardé trois. Enfin, quatre. Quark en a mangé un en se cachant. C'est comme ça que tu l'as trouvé : les miettes.",
		"recompense": {"pieces": 15, "rep": 0, "objets": [["biscuit_lunaire", 3]]}},
	{"id": "as_souvenirs", "titre": "Les holo-photos de Glorb", "donneur": "glorb", "lieu": "Astralys, l'Agora des Étoiles", "sorte": "Astralys",
		"si": {"apres": "as_bienvenue"},
		"resume": "Glorb, le touriste de la planète Gloop, voudrait envoyer à sa maman des photos des quatre coins de l'archipel. Mais il est vert et gélatineux, et il a peur d'effrayer les gens d'en bas. Il te confie son holo-photo : il faut photographier le maire de Port-Azur, Mama Grog à la Balafre, le Baron de Montjoie et Mamie Barricade au Boucan, puis lui rapporter l'appareil.",
		"offre_label": "Glorb, pourquoi tu photographies tout ?",
		"offre": "Blorp ! Pour maman ! Elle est restée sur Gloop, elle est trop molle pour voyager, alors je lui envoie des photos de tout. Mais il me manque l'essentiel : les gens d'en bas ! Les vrais Pieds-Lourds, dans leurs îles ! Moi, je n'ose pas descendre. Je suis vert, je tremblote, et la dernière fois que j'ai dit bonjour à un pêcheur, il a crié « UNE GELÉE GÉANTE ! » et il a sauté dans l'eau. Toi, tu pourrais ? Prends mon holo-photo. Photographie le maire de Port-Azur, la dame de la taverne des pirates, le Baron de Montjoie et la mamie à crête du Boucan. Quatre coins de l'archipel ! Maman va rebondir de joie !",
		"donne": [["appareil_holo", 1]],
		"etapes": [
			{"type": "parler", "pnj": "aristide", "label": "Monsieur le maire, une holo-photo pour un touriste ?", "texte": "Une photo ? Pour un touriste ? (Il redresse son écharpe, lisse sa moustache, rentre le ventre.) Un instant ! Le profil gauche ! C'est mon meilleur. Le droit a été battu aux élections de la pétanque. Voilà. Souriez, Port-Azur ! (Clic ! Un petit hologramme de lui apparaît, en train de sourire.) Oh ! Je suis en trois dimensions ! Colette va être jalouse : elle n'est qu'en deux.", "objectif": "Prendre en holo-photo Aristide, le maire de Port-Azur (à la mairie, sur la place ; à midi chez Paulo, en fin d'après-midi à la pétanque)"},
			{"type": "parler", "pnj": "mama_grog", "label": "Mama Grog, une holo-photo pour un touriste de l'espace ?", "texte": "Un touriste de l'espace ? Vert ? Gélatineux ? (Elle éclate de rire.) Il peut venir boire un grog, il ne sera pas le plus bizarre de la salle ! Bon, la photo. Attends. (Elle crache dans sa main, se recoiffe, prend la pose les poings sur les hanches.) Comme ça. Avec le Crâne Fendu derrière. Qu'on voie que c'est une taverne sérieuse. Clic ! … Je suis petite, là-dedans. Et toute brillante. J'aime bien. Dis à ta gelée qu'on paie AVANT de se bagarrer.", "objectif": "Prendre en holo-photo Mama Grog (Île de la Balafre, à Port-Coutelas : au comptoir du Crâne Fendu, de 10 h jusque tard dans la nuit)"},
			{"type": "parler", "pnj": "barthelemy", "label": "Monsieur le Baron, une holo-photo, s'il vous plaît ?", "texte": "Une photo ? Charmant, charmant ! Attendez, attendez… quel chapeau ? Le chapeau du mardi ? Le chapeau aux cerises ? (Il en essaie trois.) Celui-là. Non, celui-là. Bon, les trois. (Il les empile sur sa tête.) Clic ! Oh ! Un petit Baron en lumière ! Avec trois chapeaux ! C'est mon meilleur portrait. Aurore ! Aurore, venez voir ! … Ah, non, rien. Elle va me gronder pour les chapeaux.", "objectif": "Prendre en holo-photo le Baron Barthélemy (Île de Montjoie, au château, au sommet de la Butte : salle du trône le matin, jardin ou rempart l'après-midi)"},
			{"type": "parler", "pnj": "barricade", "label": "Mamie Barricade, une holo-photo pour un touriste de l'espace ?", "texte": "Un touriste de l'espace qui a peur de descendre ? (Elle pose son tricot.) Dis-lui qu'ici, au Boucan, on accueille tout le monde. Les punks, les robots repentis, les rats, les chiens à bandana… Une gelée verte, ça manquait. (Elle lève le poing, très droite, avec un grand sourire.) Clic ! Tu lui diras : « La porte est ouverte. Elle est tombée en 1998, mais elle est ouverte. »", "objectif": "Prendre en holo-photo Mamie Barricade (Île du Boucan, à Port-Boucan : à la Conserverie, salle des assemblées sur le toit, ou devant l'entrée l'après-midi)"},
			{"type": "rendre", "pnj": "glorb", "prend": [["appareil_holo", 1]], "label": "Glorb ! Voici tes holo-photos des quatre coins de l'archipel.", "objectif": "Rapporter l'holo-photo à Glorb (il se promène partout dans Astralys : Musée, Agora, Café Nébuleuse, belvédères, Bazar…)"},
		],
		"fin": "BLORP ! (Il fait défiler les hologrammes : un maire qui rentre le ventre, une tavernière qui fait les gros yeux, un baron à trois chapeaux, une mamie à crête qui lève le poing.) Ils sont PARFAITS ! Ils sont si… si Pieds-Lourds ! J'envoie tout à maman ! (Clic-clic-clic. Un long silence. Puis l'appareil fait « bip ».) Elle a répondu ! Elle dit : « Mon Glorb, tu as des amis ! » … (Il tremblote très fort.) J'ai des amis. Tiens, mes lunettes kaléidoscope : avec elles, on voit le monde comme moi. En mille morceaux, et tous jolis.",
		"recompense": {"pieces": 50, "rep": 0, "objets": [["lunettes_kaleido", 1]]}},
	{"id": "as_glisseur", "titre": "Le Glisseur stellaire", "donneur": "ionie", "lieu": "Astralys, le Spatioport", "sorte": "Astralys",
		"si": {"apres": "as_etoiles", "aeronef": 3},
		"resume": "Ionie, la mécanicienne du Spatioport, rêve de transformer l'aéronef du héros (l'Albatros, construit à Cliquetis) en Glisseur stellaire : une petite soucoupe rapide, capable de monter très haut et de se poser sur Astralys. Il lui faut des matériaux, une puce holographique pour la navigation (envolée du laboratoire du Professeur Quasar) et une carte stellaire dessinée par Sextant.",
		"offre_label": "Ionie, vous pourriez améliorer ma machine volante ?",
		"offre": "AMÉLIORER ? (Ses yeux brillent.) Ta machine des inventeurs de Cliquetis, avec son ballon et ses hélices ? Elle est magnifique ! Courageuse ! Bruyante ! Et si on lui mettait un cœur de cristal ? Plus de ballon : une coque de soucoupe. Plus d'hélices : un moteur astral, silencieux, qui monte jusqu'à six cents mètres ! Le Glisseur stellaire ! Il me faut trois cristaux astraux, deux fragments de météorite, quatre engrenages et deux rouleaux de toile à voile pour l'habitacle. Et pour la navigation, une puce holographique : le Professeur Quasar en a fait exploser une ce matin. Et une carte stellaire : Sextant en dessine de très belles. Tu me rapportes tout ça ? Je te fais la plus belle machine de l'archipel. Promis. Clac !",
		"etapes": [
			{"type": "objets", "pnj": "ionie", "objets": {"cristal_astral": 3, "fragment_meteorite": 2, "engrenage": 4, "toile_voile": 2}, "label": "Voici les matériaux pour le Glisseur, Ionie.", "texte": "Trois cristaux, deux fragments, quatre engrenages, deux rouleaux de toile ! (Elle disparaît dans le hangar. Bruits de clés, de soudure lumineuse, un « clac », un « oups », un autre « clac ».) Ça avance ! La coque est faite, le moteur ronronne. Maintenant, il me faut la navigation : la puce holographique du Professeur, et une carte stellaire de Sextant.", "objectif": "Apporter à Ionie trois cristaux astraux, deux fragments de météorite, quatre engrenages et deux rouleaux de toile à voile (Ionie et Nébula en vendent ; les fragments tombent aussi les nuits d'étoiles filantes) — Ionie est au hangar du Spatioport, à l'est"},
			{"type": "ramasser", "objets": {"puce_holo": 1}, "lieux": ["puce_holo_1"], "objectif": "Retrouver la puce holographique envolée pendant l'explosion du laboratoire du Professeur Quasar (à l'Académie des Sciences, à l'est de l'Agora)"},
			{"type": "parler", "pnj": "sextant", "label": "Sextant, Ionie a besoin d'une carte stellaire.", "texte": "Une carte stellaire ? Pour un glisseur ? (Il sort un rouleau de son sac, le déroule : des étoiles dessinées à l'encre de lumière, qui bougent doucement.) Je l'ai faite pour moi, mais je ne vole jamais. J'ai le vertige au-delà de trois marches. Prenez-la. Le nord est en haut. Enfin… sur cette carte, le nord bouge un peu. Comme les étoiles. Faites confiance aux étoiles, elles connaissent le chemin.", "donne": [["carte_stellaire", 1]], "objectif": "Demander une carte stellaire à Sextant (le matin sur le belvédère du Portail, vers midi au Musée, l'après-midi sur le pont de l'Observatoire, dans les Jardins ou au Spatioport)"},
			{"type": "objets", "pnj": "ionie", "objets": {"puce_holo": 1, "carte_stellaire": 1}, "label": "Voici la puce holographique et la carte stellaire !", "texte": "La puce et la carte ! (Elle glisse la puce dans le tableau de bord ; la carte se déroule toute seule et devient un hologramme qui tourne au-dessus des commandes.) Navigation… branchée. Moteur astral… chaud. Coque… (Elle tapote.) Clac. Parfaite. Le Glisseur stellaire est prêt ! Appelle-le comme ton ancienne machine, monte, et va voir le ciel de très haut. Et fais attention : il est rapide. Vraiment rapide. Comète va être jalouse.", "objectif": "Apporter la puce holographique et la carte stellaire à Ionie (au hangar du Spatioport)"},
			{"type": "etat", "cle": "glisseur", "objectif": "Essayer le Glisseur stellaire : l'appeler, monter à bord et s'envoler au-dessus d'Astralys"},
			{"type": "rendre", "pnj": "ionie", "label": "Ionie, le Glisseur est merveilleux !", "objectif": "Revenir voir Ionie au Spatioport"},
		],
		"fin": "Je t'ai vu passer au-dessus de la Flèche ! Tu as fait une boucle ! Une boucle ! Avec MA machine ! (Elle te serre la main si fort qu'une étincelle bleue saute.) Le Glisseur stellaire monte jusqu'à six cents mètres, se pose sur Astralys et sur l'île céleste, et il ne fait presque aucun bruit. Juste un petit « vzzz » quand il est content. Prends soin de lui. Tiens, un cristal astral de rechange, et quelques rondelles : je n'en ai pas l'usage, elles traînaient dans ma boîte à vis.",
		"recompense": {"pieces": 40, "rep": 0, "objets": [["cristal_astral", 1]]}},
	{"id": "as_course", "titre": "La course des anneaux", "donneur": "comete", "lieu": "Astralys, le Spatioport", "sorte": "Astralys",
		"si": {"apres": "as_glisseur"},
		"resume": "Comète, la pilote de soucoupe, s'ennuie : personne ne veut faire la course avec elle. Maintenant que tu as le Glisseur stellaire, elle te défie : d'abord un entraînement au parcours d'anneaux du Jardin des Apesanteurs, puis la grande course d'anneaux dans le ciel, autour d'Astralys.",
		"offre_label": "Comète, tu cherches un adversaire ?",
		"offre": "Vziiiou ! Toi ! Avec le Glisseur d'Ionie ! Enfin un adversaire ! Bon. Avant, il faut que je voie si tu sais te tenir en l'air. Va au Jardin des Apesanteurs, à l'ouest, et fais le parcours d'anneaux lumineux. Établis un record, n'importe lequel : c'est pour voir si tu sais viser. Ensuite… la vraie course. Dans le ciel. Des anneaux de lumière tout autour de l'île : sous le plateau, entre les îlots, à travers les chutes de lumière, et retour au Spatioport. Moi dans ma soucoupe, toi dans ton Glisseur. Le premier arrivé a gagné. Le deuxième paie les glaces. J'adore la glace.",
		"etapes": [
			{"type": "etat", "cle": "apesanteur_record", "objectif": "L'entraînement : faire le parcours d'anneaux lumineux du Jardin des Apesanteurs (à l'ouest, au bout du pont de lumière) et y établir un record"},
			{"type": "etat", "cle": "course_comete", "objectif": "La grande course : retrouver Comète au-dessus du Spatioport, à bord du Glisseur stellaire, et passer tous les anneaux du ciel autour d'Astralys avant elle"},
			{"type": "rendre", "pnj": "comete", "label": "Alors, Comète ? Qui paie les glaces ?", "objectif": "Retrouver Comète (au Spatioport, ou l'après-midi au Jardin des Apesanteurs)"},
		],
		"fin": "C'est moi qui paie les glaces. (Elle croise les bras, fait la moue… puis éclate de rire.) Tu m'as battue ! Personne ne m'avait jamais battue ! Sauf une mouette, une fois, mais la mouette a triché, elle a pris le vent. Tu sais quoi ? C'est la plus belle course de ma vie. Tiens : deux gelées cosmiques, c'est plus rare que la glace, et des rondelles pour la glace quand même. Et revanche demain ! Et après-demain ! Toute la vie !",
		"recompense": {"pieces": 50, "rep": 0, "objets": [["gelee_cosmique", 2]]}},
	{"id": "as_coeur", "titre": "Le Cœur de la Flèche", "donneur": "astree", "lieu": "Astralys, la Flèche de Cristal", "sorte": "Astralys",
		"si": {"apres": "as_glisseur"},
		"resume": "Le Cœur de la Flèche, le grand cristal qui fait flotter Astralys, faiblit : trois éclats s'en sont détachés et sont tombés sur l'île. Volt, l'ingénieur de l'énergie, peut les ressouder avec trois cristaux astraux, mais il faut ensuite rendre au Cœur sa lumière, tout en haut de la Flèche.",
		"offre_label": "Doyenne, pourquoi les ponts de lumière clignotent-ils ?",
		"offre": "Tu as remarqué. (Elle pose sa main sur la tienne ; elle est légère comme une feuille.) Les ponts clignotent, la fontaine hésite entre deux planètes, et la Flèche bat moins fort. Le Cœur faiblit, mon petit astre. Il est très vieux : il est arrivé d'Ondelune avec nous. Cette nuit, trois éclats s'en sont détachés et sont tombés sur l'île. Sans eux, il bat comme un cœur fatigué. Et si le Cœur s'arrête… (Elle sourit.) Nous ne nous envolerons pas. Nous tomberons. Doucement, je l'espère. Je n'aime pas les grandes chutes à mon âge. Va voir Volt, au pied de la Flèche. Il fait semblant que tout va bien. Il sait tout. Aide-le.",
		"etapes": [
			{"type": "parler", "pnj": "volt", "label": "La Doyenne m'envoie. Que se passe-t-il avec le Cœur ?", "texte": "Bzzt. Elle t'envoie. Évidemment. (Il soupire, montre sa tablette : une courbe qui fait des zigzags.) Bon. Le Cœur a perdu trois éclats cette nuit. Un est tombé du côté de l'Observatoire, un dans la Serre des Espèces, au milieu des glouglous, et le troisième… quelque part en hauteur, dans le Jardin des Apesanteurs : là-bas, il ne retombera jamais tout seul. Ramène-les-moi. Avec trois cristaux astraux, je peux les ressouder. Après, il faudra les remettre dans le Cœur. Tout en haut. Cent dix mètres. Ce n'est rien. Enfin, si.", "objectif": "Aller voir Volt, l'ingénieur de l'énergie (au pied de la Flèche de Cristal, le jour et pendant la Nuit des Aurores)"},
			{"type": "ramasser", "objets": {"coeur_fleche": 3}, "lieux": ["coeur_fleche_1", "coeur_fleche_2", "coeur_fleche_3"], "objectif": "Retrouver les trois éclats du Cœur de la Flèche (un près de l'Observatoire, au nord ; un dans la Serre des Espèces, au nord-est ; un en hauteur dans le Jardin des Apesanteurs, à l'ouest) : ils battent doucement et chantent une seule note"},
			{"type": "objets", "pnj": "volt", "objets": {"coeur_fleche": 3, "cristal_astral": 3}, "label": "Voici les trois éclats du Cœur, et trois cristaux astraux.", "texte": "(Il pose les éclats sur l'établi, entre les trois cristaux astraux. Ses mains, d'habitude si brusques, deviennent très douces. Une lumière bleue passe d'un cristal à l'autre. Les éclats se mettent à battre ensemble, au même rythme.) … Voilà. Ils sont prêts. (Il renifle.) La poussière de cristal. Ça pique. Maintenant, il faut les rapporter au Cœur, tout en haut de la Flèche. L'escalier est fermé depuis trois cents ans. Mais toi, tu as le Glisseur. Pose-toi au sommet, et rends-lui sa lumière.", "objectif": "Apporter à Volt les trois éclats et trois cristaux astraux (au pied de la Flèche de Cristal)"},
			{"type": "etat", "cle": "fleche_coeur", "objectif": "Monter au sommet de la Flèche de Cristal (avec le Glisseur stellaire) et rendre au Cœur ses éclats et sa lumière"},
			{"type": "rendre", "pnj": "astree", "label": "Doyenne, le Cœur bat de nouveau.", "objectif": "Retourner voir la Doyenne Astrée (à la Salle du Conseil, au pied de la Flèche ; sur son banc de l'Agora pendant les aurores)"},
		],
		"fin": "Je l'ai senti. Toute l'île l'a senti. (Les ponts de lumière brillent, la fontaine choisit enfin sa planète, et tout là-haut, la Flèche bat comme un tambour joyeux.) Mille ans que le Cœur nous porte, et c'est un Pied-Lourd qui l'a soigné. Les anciens d'Ondelune ne le croiraient pas. Moi, je le crois. (Elle se lève, très droite, et pose ses deux mains sur tes épaules.) Au nom du Conseil, de Tempo qui a pleuré à l'heure pile, d'Écliptique qui prépare un discours de deux heures, et de Volt qui dit que ce n'est rien : tu es désormais l'Ami des Lumens. Le premier. Hi hi. Tiens, des rondelles, puisque vous aimez ça, et trois gelées cosmiques de Gloubi. Il a pleuré dedans. Elles sont un peu salées.",
		"recompense": {"pieces": 200, "rep": 0, "titre": "Ami des Lumens", "objets": [["gelee_cosmique", 3]]}},
	# ================================================================ V76 : les compagnons animaux (Brioche, Biscotte, Truffe)
	{"id": "pet_brioche", "titre": "La chatte des toits", "donneur": "rosalie", "lieu": "Port-Azur, la poissonnerie",
		"resume": "Une chatte tigrée rousse et blanche, très digne, vit sur les toits du port de Port-Azur. Chaque matin, elle chipe une sardine à Rosalie, la poissonnière. Rosalie l'appelle Brioche. Elle voudrait qu'elle ait enfin quelqu'un à elle. Brioche ne se laisse approcher par personne… sauf, peut-être, par quelqu'un qui aurait une pelote de laine.",
		"offre_label": "Rosalie, c'est à qui, ce chat roux sur le toit ?",
		"offre": "À personne, et c'est bien ça le souci ! C'est Brioche. Rousse et blanche, comme une brioche dorée, tu vois ? Tous les matins, à six heures, elle descend du toit, me prend UNE sardine, une seule, très poliment, et remonte la manger en me regardant. Elle ne vole pas, elle se sert. Elle est digne, cette chatte. Plus digne que le maire. Seulement voilà : elle n'a personne. L'hiver, elle dort contre la cheminée de la capitainerie, et Odette fait semblant de ne pas la voir. Moi, je ne peux pas la prendre, j'ai trois étages et un mari allergique. Toi, tu voyages… Un chat qui voyage, ça lui plairait, je crois. Mais elle ne se laisse approcher par personne. Sauf… Pauline, la femme de chambre du Grand Hôtel, tricote sur la terrasse : un jour, Brioche est venue jouer avec sa pelote. Elle a même ronronné. Va voir Pauline !",
		"etapes": [
			{"type": "parler", "pnj": "pauline", "label": "Pauline, Rosalie dit que Brioche aime votre laine…", "texte": "Brioche ? La chatte rousse ? (Elle sourit.) Oh oui. Elle vient sur la terrasse quand je tricote. Elle fait semblant de dormir, et dès que la pelote roule… hop ! Elle l'attrape, elle la mordille, elle me la rend. Enfin, presque. Justement : ce matin, une pelote rouge est tombée de mon panier. Elle a roulé dans le jardin de l'hôtel. Je n'ai pas eu le temps de la chercher : Monsieur Edmond m'appelait pour le linge. Prends-la, si tu la trouves. Pour Brioche, c'est un trésor.", "objectif": "Parler à Pauline, la femme de chambre (au Grand Hôtel : dans les couloirs le matin et l'après-midi, au jardin de l'hôtel à midi)"},
			{"type": "ramasser", "objets": {"pelote_laine": 1}, "lieux": ["pelote_laine_1"], "objectif": "Retrouver la pelote de laine rouge tombée du panier de Pauline (dans le jardin du Grand Hôtel)"},
			{"type": "etat", "cle": "brioche_adoptee", "objectif": "Trouver Brioche, la chatte rousse et blanche, sur les toits du port (près de la poissonnerie et de la capitainerie), lui montrer la pelote de laine et la laisser venir à toi : c'est elle qui choisit"},
			{"type": "rendre", "pnj": "rosalie", "label": "Rosalie, Brioche vient avec moi !", "objectif": "Retourner voir Rosalie (à la poissonnerie, sur le port, le matin ; en terrasse ou sur la promenade l'après-midi)"},
		],
		"fin": "Elle te suit ! Brioche te suit ! Regarde-la, assise à tes pieds, la queue bien enroulée, comme une reine qui a choisi son carrosse. (Rosalie s'essuie les yeux avec son tablier.) C'est l'odeur du poisson, ça pique. Écoute-moi : elle mange une sardine par jour, pas deux, elle a sa dignité. Elle chasse les papillons, elle ne les attrape jamais. Et elle a un don : elle sent les trésors cachés. Je l'ai vue miauler pendant une heure devant une dalle de la place ; dessous, il y avait une vieille pièce d'or. Écoute-la quand elle miaule. Tiens, quelques pièces. Et si tu n'as pas encore de quoi appeler tes bêtes, prends ce sifflet en os : mon grand-père, le pêcheur, l'avait gravé d'un chien, d'un chat, d'un rat et d'un cochon. Il disait qu'un jour, quelqu'un aurait les quatre. Siffle, et ceux qui t'aiment accourront.",
		"recompense": {"pieces": 15, "rep": 3, "objets": [["sifflet_compagnons", 1]]}},
	{"id": "pet_biscotte", "titre": "Le rat du Requin Borgne", "donneur": "petit_pierre", "lieu": "La Balafre, le Requin Borgne", "sorte": "Balafre",
		"resume": "Biscotte, un petit rat blanc et brun, vit dans la cale du Requin Borgne. C'est l'ami secret de Petit-Pierre, le mousse. Mais Mange-Clous, le cuisinier, a juré de le jeter par-dessus bord : ses fromages disparaissent. Petit-Pierre voudrait que Biscotte parte avec quelqu'un de gentil, avant qu'il ne soit trop tard. Pour l'attirer hors de la cale, il faut du fromage affiné.",
		"offre_label": "Petit-Pierre, pourquoi tu caches du pain dans ta poche ?",
		"offre": "Chut ! Parle moins fort ! (Il regarde partout.) C'est pour Biscotte. C'est un rat. Mon rat. Enfin, le rat du navire, mais c'est mon ami. Il est tout petit, blanc avec des taches brunes, et il dort dans mon hamac quand la capitaine ne regarde pas. Seulement, Mange-Clous a perdu trois fromages, et il a juré sur sa louche qu'il jetterait « ce sale rat » par-dessus bord ! Biscotte n'est pas sale ! Il se lave trois fois par jour ! Moi, je suis mousse, je ne peux pas avoir un rat à moi, la capitaine dit qu'un mousse n'a rien à lui. Mais toi… tu pourrais le prendre ? Il aime les épaules et le fromage. Surtout le fromage. Va voir Mange-Clous : s'il sait que Biscotte s'en va, il te donnera peut-être de quoi l'attirer. Il est grognon, mais il n'a pas un mauvais fond. Juste un mauvais fromage.",
		"etapes": [
			{"type": "parler", "pnj": "mange_clous", "label": "Mange-Clous, je viens vous débarrasser du rat.", "texte": "Le rat ? Ce voleur ? Ce brigand à moustaches ? (Il frappe sa louche sur la table.) Trois fromages ! Mes trois plus beaux fromages affinés, ceux qui sentent si fort que même les mouettes s'évanouissent ! Disparus ! Je l'ai vu filer dans le port avec un morceau plus gros que lui. Il les a cachés quelque part, ce maudit ! (Il grogne.) … Bon. Si tu l'emmènes loin de ma cuisine, je ne dis plus rien. Retrouve mes fromages : là où il les a planqués, il reviendra. Mets-les près de la cale, et il sortira. Ce rat ferait n'importe quoi pour un fromage. Moi aussi, remarque. C'est peut-être pour ça qu'on ne s'aime pas.", "objectif": "Parler à Mange-Clous, le cuisinier du Requin Borgne (sur le pont du Requin Borgne le matin, à la cheminée du Crâne Fendu vers midi, aux filets du quai l'après-midi)"},
			{"type": "ramasser", "objets": {"fromage_affine": 3}, "lieux": ["fromage_affine_1", "fromage_affine_2", "fromage_affine_3"], "objectif": "Retrouver les trois fromages affinés cachés par Biscotte dans Port-Coutelas (entre les caisses du quai, sous le ponton de pêche, près du puits) : suis ton nez"},
			{"type": "etat", "cle": "biscotte_adoptee", "objectif": "Poser le fromage près de la cale du Requin Borgne et attendre que Biscotte sorte de son trou : s'il grimpe sur ton épaule, c'est gagné"},
			{"type": "rendre", "pnj": "petit_pierre", "label": "Petit-Pierre, Biscotte est sur mon épaule !", "objectif": "Retourner voir Petit-Pierre (sur le quai, aux caisses, le matin ; au ponton de pêche l'après-midi ; sur la place le soir)"},
		],
		"fin": "Biscotte ! (Le petit rat saute de ton épaule sur la sienne, lui mordille l'oreille, puis revient sur la tienne.) Tu vois ? Il t'a choisi. Il revient toujours sur ton épaule. (Petit-Pierre renifle.) C'est pas grave. Il sera mieux avec toi, en voyage, qu'ici avec Mange-Clous et sa louche. Il est très malin, tu sais : quand il disparaît dans un trou, il revient toujours avec quelque chose. Une pièce, un bouton, une perle… Les rats savent où sont les trésors. Tiens, mes pièces de mousse. Et si tu n'as pas encore de sifflet pour appeler tes bêtes, prends celui-là : Gwen me l'a sculpté dans un os, avec un chien, un chat, un rat et un cochon gravés autour. Siffle, et Biscotte reviendra. Et tu repasseras me voir, hein ? Avec lui ?",
		"recompense": {"pieces": 15, "rep": 0, "objets": [["sifflet_compagnons", 1]]}},
	{"id": "pet_truffe", "titre": "Le petit cochon fugueur", "donneur": "gaubert", "lieu": "Île de Montjoie, les Champs du Sud", "sorte": "Île de Montjoie",
		"resume": "Truffe, le plus petit des cochons de la ferme de Père Gaubert, rose et noir, se sauve tous les jours pour aller fouiller les bois au bord des Champs du Sud. Il déterre des truffes… et les navets. Père Gaubert, avec ses genoux, ne peut plus le rattraper, et sa clochette est tombée. Il cherche quelqu'un qui aime marcher pour le prendre avec lui.",
		"offre_label": "Père Gaubert, qu'est-ce qui a creusé ce trou dans votre champ ?",
		"offre": "Ce trou ? C'est Truffe, mon gars. Le plus petit de mes cochons. Rose et noir, gros comme un panier à pain, et un nez… un nez d'or ! Il sent les truffes sous la terre à cinquante pas. Seulement voilà : il sent aussi les navets. Et mes navets, quand on les déterre, ils se réveillent, et ils se sauvent ! L'autre jour, il en a réveillé douze. Douze ! Germaine a couru jusqu'au moulin. Alors Truffe se sauve tous les matins vers les bois, et moi, avec mes genoux, je ne le rattrape plus. Il avait une clochette, pour qu'on l'entende venir. Il l'a perdue. Un cochon comme lui, il lui faudrait quelqu'un qui marche beaucoup, qui voyage, qui aime les surprises sous la terre. Quelqu'un comme toi, tiens. Va voir Germaine : elle sait toujours où il traîne.",
		"etapes": [
			{"type": "parler", "pnj": "germaine", "label": "Germaine, Père Gaubert m'envoie, pour le petit cochon.", "texte": "Truffe ? Ce petit diable ? (Elle soupire, mais elle sourit.) Ce matin, je l'ai vu passer devant le moulin de Clovis, au triple galop, le groin dans l'herbe. Sa clochette a dû se décrocher par là : je l'ai entendue tinter, puis plus rien. Retrouve-la. Truffe connaît son tintement : quand il l'entend, il accourt. C'est la clochette du goûter. Je la secouais pour l'appeler quand il était tout petit. Il est resté tout petit, remarque. Sauf pour l'appétit.", "objectif": "Parler à Germaine, la femme de Père Gaubert (à la ferme, dans la cour le matin et en fin d'après-midi, aux champs en fin de matinée, au marché l'après-midi)"},
			{"type": "ramasser", "objets": {"clochette_cochon": 1}, "lieux": ["clochette_cochon_1"], "objectif": "Retrouver la clochette de Truffe (tombée dans l'herbe près du moulin de Clovis, aux Champs du Sud)"},
			{"type": "etat", "cle": "truffe_adoptee", "objectif": "Retrouver Truffe dans les bosquets au bord des Champs du Sud et faire tinter sa clochette : il viendra"},
			{"type": "rendre", "pnj": "gaubert", "label": "Père Gaubert, Truffe veut venir avec moi.", "objectif": "Retourner voir Père Gaubert (aux Champs du Sud, devant sa ferme ; dans la cour à midi)"},
		],
		"fin": "Il te suit ! Regarde-le, le groin collé à tes chaussures ! (Père Gaubert rit, puis se mouche bruyamment.) C'est le pollen. Écoute-moi bien, mon gars : il mange de tout, mais pas les navets dorés, hein, eux, ce sont mes petits. Dans les bois et les prés, laisse-le renifler : il te trouvera des truffes, et parfois une vieille chose enfouie, une pièce, une bague… Il a un groin d'or, je te dis. Tiens, deux truffes qu'il m'a trouvées hier, et quelques pièces. Et si tu n'as pas déjà un sifflet pour appeler tes bêtes, prends celui de mon père, en os sculpté : un chien, un chat, un rat et un cochon tout autour. Siffle, et ton cochon reviendra. Doucement avec mon petit, hein !",
		"recompense": {"pieces": 15, "rep": 0, "objets": [["truffe", 2], ["sifflet_compagnons", 1]]}},
]

## Les grandes aventures du jeu, suivies par les trouvailles (main._npc_ctx_v31).
const AVENTURES := [
	{"id": "temple", "titre": "Le temple oublié", "lieu": "Sous l'île du village", "debut": "temple",
		"etapes": [["temple", "Trouver l'entrée du temple sous le village (une trappe cachée)"], ["braseros", "Allumer les braseros du temple"], ["fragment", "Ouvrir le coffre du premier fragment d'amulette"],
			["tunnel", "Dégager l'éboulement de la galerie sous la mer"], ["boss1", "Vaincre Karkinos, le Crabe-Roi"], ["serpents", "Résoudre l'énigme des serpents"],
			["fragment3", "Trouver le troisième fragment"], ["porte_serpent", "Ouvrir la Porte du Serpent"], ["abysses", "Briser le sceau des Abysses"],
			["lac", "Traverser le lac noir"], ["abime", "Éveiller l'abîme"], ["naga", "Vaincre la Naga des profondeurs"]]},
	{"id": "arbre_sacre", "titre": "L'Arbre sacré", "lieu": "Île du village, puis le Bois-Doré", "debut": "quete_elfe",
		"etapes": [["quete_elfe", "Rencontrer Lyra, l'elfe, au cœur de l'île du village"], ["arbre_sacre", "Soigner l'Arbre sacré"], ["ile_elfes", "Rejoindre l'île des elfes en bateau"]]},
	{"id": "racines", "titre": "Le Royaume des Racines", "lieu": "Île des elfes", "debut": "ile_elfes",
		"etapes": [["porte_racines", "Réveiller les esprits de la forêt et ouvrir la porte des racines"], ["royaume", "Entrer dans le Royaume des Racines"], ["prismes", "Aligner les prismes de lumière"],
			["clochettes", "Faire chanter les clochettes"], ["village_fees", "Découvrir le Village des Fées"], ["ronces", "Vaincre les ronces maudites"], ["reine", "Rencontrer la Reine des fées"], ["carte_naine", "Recevoir la carte des nains"]]},
	{"id": "forgefer", "titre": "Forgefer, la cité des nains", "lieu": "La Montagne de Feu", "debut": "ile_nains",
		"etapes": [["ile_nains", "Accoster sur l'île des nains"], ["porte_forgefer", "Ouvrir la Grande Porte de Forgefer"], ["ville_naine", "Entrer dans la cité sous la montagne"], ["nains_aides_3", "Aider trois nains de Forgefer"]]},
	{"id": "ciel", "titre": "La Citadelle des Nuées", "lieu": "Le ciel", "debut": "ventaile",
		"etapes": [["ventaile", "Apprivoiser Ventaile, l'aigle géant"], ["citadelle", "Atteindre l'île flottante et sa citadelle"], ["orage", "Vaincre Sire Orage"]]},
	{"id": "atlantide", "titre": "Les perles de l'Atlantide", "lieu": "Sous la mer", "debut": "masque",
		"etapes": [["masque", "Obtenir le masque de plongée"], ["atlantide", "Trouver la cité engloutie"], ["perles_1", "Trouver une première Perle de Lumière"], ["perles_3", "Réunir les trois Perles"], ["cristal", "Rallumer le Grand Cristal"]]},
	{"id": "yggdrasil", "titre": "Yggdrasil, l'Arbre-Monde", "lieu": "Le royaume des fées", "debut": "royaume_fees",
		"etapes": [["royaume_fees", "Entrer dans le royaume des fées (le champignon de Lulu)"], ["porte_ygg", "Entrer dans Yggdrasil par la porte aux runes"], ["lucioles", "Rejouer l'air des lucioles"],
			["seve", "Mener la lumière de la sève jusqu'au cœur de bois"], ["saisons", "Faire fleurir les quatre saisons"], ["mere_ronce", "Vaincre la Mère-Ronce"],
			["graine_ygg", "Recevoir la graine de l'esprit de l'arbre"], ["teleportation", "Apprendre la magie de téléportation"]]},
	{"id": "coeur_pierre", "titre": "Le Cœur-de-Pierre", "lieu": "Sous la grande île de l'est", "debut": "porte_ouverte",
		"etapes": [["porte_ouverte", "Ouvrir la Porte aux Quatre Sceaux"], ["entree_coeur", "Descendre sous le Cœur-de-Pierre, dans la Rose des Sceaux"],
			["aile_marees", "Rallumer le cristal de l'Aile des Marées (à l'ouest)"], ["aile_sables", "Rallumer le cristal de l'Aile des Sables (au sud)"],
			["aile_rouages", "Rallumer le cristal de l'Aile des Rouages (au nord)"], ["aile_lune", "Rallumer le cristal de l'Aile de la Lune (à l'est)"],
			["coeur_ouvert", "Ouvrir la salle du Cœur"], ["gardien_coeur", "Apaiser le Gardien du Cœur"]]},
	{"id": "trois_soleils", "titre": "Les Trois Soleils", "lieu": "L'Île des Trois Soleils", "debut": "soleils",
		"etapes": [["soleils", "Accoster sur l'Île des Trois Soleils"], ["sphinx", "Répondre aux trois questions du Sphinx"], ["pyramide", "Rapporter l'Œil d'Horus de la Pyramide de Rê"],
			["calendrier", "Ouvrir le Temple de Kukulkan à la date de la création"], ["xibalba", "Rapporter le Masque de Jade de Xibalba"],
			["offrandes", "Faire les offrandes du Grand Temple d'Aztlán"], ["cinq_soleils", "Rapporter la Plume de Quetzalcóatl des Cinq Soleils"],
			["trois_soleils", "Poser les trois reliques sur l'Autel des Trois Soleils"]]},
	{"id": "braise", "titre": "Pandémonia, la cité des démons", "lieu": "L'Île de Braise", "debut": "braise",
		"etapes": [["braise", "Accoster sur l'Île de Braise"], ["pandemonia", "Entrer dans Pandémonia, la cité aux mille lanternes"], ["porte_cercles", "Ouvrir la porte des Neuf Cercles"],
			["titan_givre", "Vaincre le Titan de Givre au fond du Cocyte"], ["coeur_vif", "Rallumer le Cœur-Brasier"], ["tournoi", "Gagner le Tournoi des Cornes"],
			["fete_lanternes", "Danser à la Nuit des Lanternes"]]},
	{"id": "montjoie", "titre": "Montjoie, la ville des aventuriers", "lieu": "L'Île de Montjoie", "debut": "montjoie",
		"etapes": [["montjoie", "Accoster sur l'Île de Montjoie"], ["inscription", "S'inscrire à la Guilde des Aventuriers"], ["compagnon", "Recruter un premier compagnon"],
			["rang_d", "Atteindre le rang D de la Guilde"], ["donjon_5", "Descendre au cinquième étage du Donjon des Mille Marches"], ["roi_gelatineux", "Vaincre le Roi Gélatineux"],
			["chaumiere", "Acheter la Chaumière des Glycines"]]},
	{"id": "boucan", "titre": "Port-Boucan, la ville libre", "lieu": "L'Île du Boucan", "debut": "boucan",
		"etapes": [["boucan", "Accoster sur l'Île du Boucan"], ["boucan_concert", "Danser le pogo à un concert de la Halle Hurlante"], ["boucan_champignon", "Goûter un champignon féerique"],
			["sardine_trouvee", "Adopter Sardine"], ["grand_boucan", "Le Grand Boucan"], ["grande_pelleteuse", "Vaincre la Grande Pelleteuse"],
			["gedeon_batteur", "Un batteur pour les Rats de Cale"]]},
	{"id": "astralys", "titre": "Astralys, l'île flottante des Lumens", "lieu": "Astralys, dans le ciel du nord-ouest", "debut": "astralys",
		"etapes": [["astralys", "Monter sur Astralys par le rayon d'accueil (la bouée lumineuse, au nord-ouest de l'archipel)"], ["astralys_ville", "Entrer dans la cité de cristal et de lumière"],
			["apesanteur_record", "Établir un record au parcours d'anneaux du Jardin des Apesanteurs"], ["aurores", "Assister à la Nuit des Aurores"],
			["glisseur", "Piloter le Glisseur stellaire"], ["fleche_coeur", "Rendre sa lumière au Cœur de la Flèche"]]},
	{"id": "ailes", "titre": "Les Ailes de Philibert", "lieu": "Cliquetis, puis le ciel", "debut": "atelier_ailes",
		"etapes": [["aeronef_1", "L'Alouette, le deltaplane de Philibert (à l'Atelier des Ailes, à l'ouest de Cliquetis)"], ["aeronef_2", "L'Alouette à hélice"], ["aeronef_3", "L'Albatros, le petit aéronef"],
			["vol_haut", "Voler à plus de 250 m"], ["aeronef_4", "Le Glisseur stellaire des Lumens (Ionie, au Spatioport d'Astralys)"]]},
]

var main: Node
var states: Dictionary = {}          # id -> {etat, etape, debut, fin}
var bonus := {"coeur": 0, "endurance": 0, "souffle": 0, "force": 0}
var reputation: int = 0
var titres: Array = []
var flags: Dictionary = {}
var remises: Dictionary = {}
var services: Dictionary = {}        # id pnj -> [Callable sujets(npc) -> Array, Callable choix(npc, id) -> Dictionary]
var lieux: Dictionary = {}           # objets de quête : nom -> Vector3 monde (fourni par Port-Azur)
var creuser: Dictionary = {}         # lieux à creuser : nom -> Vector3
var _course_t: float = -1.0
var _clock: float = 0.0
var _by_id: Dictionary = {}


func setup(main_node: Node) -> void:
	main = main_node
	for q in QUETES:
		_by_id[str(q["id"])] = q


func quest(id: String) -> Dictionary:
	return _by_id.get(id, {})


## V72 : une quête de Port-Azur (pour la réputation et le titre de citoyen).
func is_azur(q: Dictionary) -> bool:
	return str(q.get("lieu", "")).begins_with("Port-Azur")


func state(id: String) -> String:
	return str((states.get(id, {}) as Dictionary).get("etat", ""))


func step_of(id: String) -> int:
	return int((states.get(id, {}) as Dictionary).get("etape", 0))


## États des quêtes pour les conditions des dialogues (« q56 »).
func ctx_states() -> Dictionary:
	var out := {}
	for q in QUETES:
		out[str(q["id"])] = state(str(q["id"]))
	return out


func finished_count() -> int:
	var n: int = 0
	for q in QUETES:
		if state(str(q["id"])) == "finie":
			n += 1
	return n


func rep_level() -> Array:
	var lvl: Array = REP_LEVELS[0]
	for l in REP_LEVELS:
		if reputation >= int(l[0]):
			lvl = l
	return lvl


func rep_next() -> int:
	for l in REP_LEVELS:
		if reputation < int(l[0]):
			return int(l[0])
	return -1


# =================================================================== services (bac, hôtel…)

func add_service(npc_id: String, topics: Callable, handler: Callable) -> void:
	services[npc_id] = [topics, handler]


# =================================================================== dialogues

func _npc_met(id: String) -> bool:
	var n: Node = _npc(id)
	return n != null and int(n.brain.memoire.get("visites", 0)) > 0


func _npc(id: String) -> Node:
	if main == null:
		return null
	for n in main.npcs_v31:
		if is_instance_valid(n) and str(n.profile.get("id", "")) == id:
			return n
	return null


func npc_name(id: String) -> String:
	var n: Node = _npc(id)
	return str(n.display_name) if n != null else id.capitalize()


func _can_offer(q: Dictionary) -> bool:
	var si: Dictionary = q.get("si", {})
	if si.has("apres") and state(str(si["apres"])) != "finie":
		return false
	# V71 : un rang minimum à la Guilde des Aventuriers de Montjoie (« rang D au moins »)
	if si.has("rang"):
		var mj: Variant = main.get("montjoie_v71") if main != null else null
		if mj == null or mj.get("guilde") == null or not mj.guilde.rang_au_moins(str(si["rang"])):
			return false
	# V76 : un niveau d'aéronef minimum (le Glisseur stellaire se fait à partir de l'Albatros)
	if si.has("aeronef"):
		var ae: Variant = main.get("aeronef_v76") if main != null else null
		if ae == null or int(ae.level()) < int(si["aeronef"]):
			return false
	return true


## Sujets que le carnet ajoute à la conversation avec ce personnage.
func topics_for(npc: Node) -> Array:
	var id: String = str(npc.profile.get("id", ""))
	var out: Array = []
	for q in QUETES:
		var qid: String = str(q["id"])
		var st: String = state(qid)
		if st == "finie":
			continue
		if str(q["donneur"]) == id and st in ["", "connue"] and _can_offer(q):
			out.append({"id": "q56:offre:" + qid, "label": "★ " + str(q.get("offre_label", "Je peux vous aider ?"))})
			continue
		if st != "en_cours":
			continue
		var e: Dictionary = _step(qid)
		if e.is_empty():
			continue
		var t: String = str(e["type"])
		if str(e.get("pnj", "")) == id and t in ["parler", "objets", "rendre", "un_de"]:
			out.append({"id": "q56:etape:" + qid, "label": "★ " + str(e.get("label", "À propos de votre demande…"))})
	if services.has(id):
		for s in (services[id][0] as Callable).call(npc):
			out.append(s)
	return out


func _step(qid: String) -> Dictionary:
	var q: Dictionary = quest(qid)
	var i: int = step_of(qid)
	var steps: Array = q.get("etapes", [])
	return steps[i] if i < steps.size() else {}


func _has_items(need: Dictionary) -> Dictionary:
	var miss := {}
	for k in need:
		var have: int = main.inventory_v28.count(str(k))
		if have < int(need[k]):
			miss[k] = int(need[k]) - have
	return miss


func _names(d: Dictionary) -> String:
	var parts: Array = []
	for k in d:
		var nm: String = str(main.inventory_v28.ITEMS.get(str(k), {"name": str(k)})["name"]).to_lower()
		parts.append(("%d × %s" % [int(d[k]), nm]) if int(d[k]) > 1 else nm)
	return ", ".join(parts)


## Réponse à un choix « q56:… ». Renvoie {texte, geste, donner, prendre} (+ choix ajoutés par main).
func choose(npc: Node, choice: String) -> Dictionary:
	var parts: PackedStringArray = choice.split(":")
	if parts.size() < 3:
		return {}
	var kind: String = parts[1]
	var qid: String = parts[2]
	if kind == "service":
		var sid: String = str(npc.profile.get("id", ""))
		if services.has(sid):
			return (services[sid][1] as Callable).call(npc, choice)
		return {}
	var q: Dictionary = quest(qid)
	if q.is_empty():
		return {}
	match kind:
		"offre":
			return {"texte": str(q["offre"]), "geste": "parle", "choix": [{"id": "q56:accepte:" + qid, "label": "D'accord, je m'en occupe."}, {"id": "q56:refuse:" + qid, "label": "Pas maintenant."}]}
		"refuse":
			_set_state(qid, "connue")
			return {"texte": "Bon… si tu changes d'avis, tu sais où me trouver.", "geste": "parle"}
		"accepte":
			states[qid] = {"etat": "en_cours", "etape": 0, "debut": _now()}
			npc.brain._bond(3.0)
			main._show_message_v28("Nouvelle quête : " + str(q["titre"]))
			main.sfx("ui_quete")
			_enter_step(qid)
			changed.emit()
			var r := {"texte": "Merci ! " + str(_step(qid).get("objectif", "")) + ".", "geste": "salut"}
			if q.has("donne"):
				r["donner"] = q["donne"]
			return r
		"etape":
			# V67 : une étape d'un maître d'Arcanelle apprend un sort (main le transmet à sorts_v67)
			var before: int = step_of(qid)
			var e0: Dictionary = _step(qid)
			var res: Dictionary = _do_step(npc, qid)
			if e0.has("sort") and (step_of(qid) != before or res.has("_fin56")):
				res["_sort67"] = str(e0["sort"])
			return res
	return {}


func _do_step(npc: Node, qid: String) -> Dictionary:
	var q: Dictionary = quest(qid)
	var e: Dictionary = _step(qid)
	var t: String = str(e.get("type", ""))
	var r := {"geste": "parle"}
	match t:
		"parler":
			r["texte"] = str(e.get("texte", "Ah, merci."))
			if e.has("prend"):
				r["prendre"] = e["prend"]
			if e.has("donne"):
				r["donner"] = e["donne"]
			npc.brain._bond(2.0)
			_advance(qid)
		"objets", "un_de":
			var need: Dictionary = {}
			if t == "objets":
				need = e.get("objets", {})
			else:
				# V72 : on donne d'abord le moins précieux (jamais un outil, s'il y a autre chose)
				var opts: Array = (e.get("objets", []) as Array).duplicate()
				opts.reverse()
				for pass_i in range(2):
					for k in opts:
						var kind: String = str(main.inventory_v28.ITEMS.get(str(k), {}).get("kind", ""))
						if pass_i == 0 and kind in ["outil", "quete"]:
							continue
						if main.inventory_v28.count(str(k)) > 0:
							need = {str(k): 1}
							break
					if not need.is_empty():
						break
				if need.is_empty():
					return {"texte": "Je ne vois rien de tel dans ton sac. Une plume de Ventaile, une écaille de naga, une dent de requin… c'est tout ce qui m'intéresse.", "geste": "parle"}
			var miss: Dictionary = _has_items(need)
			if not miss.is_empty():
				return {"texte": "Il me manque encore : %s." % _names(miss), "geste": "parle"}
			var take: Array = []
			for k2 in need:
				take.append([str(k2), int(need[k2])])
			r["prendre"] = take
			if e.has("donne"):
				r["donner"] = e["donne"]
			r["texte"] = str(e.get("texte", "Parfait, merci !"))
			if _is_last(qid):
				return _finish(npc, qid, r)
			_advance(qid)
		"rendre":
			if e.has("prend"):
				var need2 := {}
				for p in e["prend"]:
					need2[str(p[0])] = int(p[1])
				var miss2: Dictionary = _has_items(need2)
				if not miss2.is_empty():
					return {"texte": "Il te manque encore : %s." % _names(miss2), "geste": "parle"}
				r["prendre"] = e["prend"]
			return _finish(npc, qid, r)
	return r


func _is_last(qid: String) -> bool:
	return step_of(qid) >= (quest(qid).get("etapes", []) as Array).size() - 1


func _finish(npc: Node, qid: String, r: Dictionary) -> Dictionary:
	var q: Dictionary = quest(qid)
	var rec: Dictionary = q.get("recompense", {})
	var texte: String = str(q.get("fin", "Merci !"))
	if r.has("texte") and str(r["texte"]) != "" and str(_step(qid).get("type", "")) == "objets" and _step(qid).has("texte"):
		texte = str(r["texte"]) + "\n\n" + texte
	r["texte"] = texte
	r["geste"] = "salut"
	var gives: Array = (r.get("donner", []) as Array).duplicate()
	if int(rec.get("pieces", 0)) > 0:
		gives.append(["piece", int(rec["pieces"])])
	for o in rec.get("objets", []):
		# V76 : un objet unique (max 1, comme le Sifflet des compagnons) déjà dans le sac n'est pas redonné
		if main != null and main.inventory_v28 != null and int((main.inventory_v28.ITEMS.get(str(o[0]), {}) as Dictionary).get("max", 0)) == 1 and main.inventory_v28.count(str(o[0])) > 0:
			continue
		gives.append(o)
	r["donner"] = gives
	r["_fin56"] = qid
	return r


## Appelé par main quand l'échange a réussi (le sac avait la place).
func commit_reply(r: Dictionary, npc: Node) -> void:
	if not r.has("_fin56"):
		return
	var qid: String = str(r["_fin56"])
	var q: Dictionary = quest(qid)
	var rec: Dictionary = q.get("recompense", {})
	states[qid] = {"etat": "finie", "etape": (q.get("etapes", []) as Array).size(), "debut": float((states.get(qid, {}) as Dictionary).get("debut", 0.0)), "fin": _now()}
	# V72 : la réputation, c'est celle de Port-Azur : seules ses quêtes la font monter
	if is_azur(q):
		reputation += int(rec.get("rep", 0))
	var b: Dictionary = rec.get("bonus", {})
	var msgs: Array = []
	for k in b:
		bonus[k] = int(bonus.get(k, 0)) + int(b[k])
		msgs.append({"coeur": "+1 cœur", "endurance": "+ endurance", "souffle": "+ souffle sous l'eau", "force": "+1 de force"}.get(k, k))
	if rec.has("titre") and not titres.has(str(rec["titre"])):
		titres.append(str(rec["titre"]))
		msgs.append("titre : « %s »" % str(rec["titre"]))
	for k2 in rec.get("remise", {}):
		remises[k2] = float(rec["remise"][k2])
	if rec.has("flag"):
		flags[str(rec["flag"])] = true
	if npc != null:
		npc.brain._bond(12.0)
		# V65 : la nouvelle fait le tour des proches
		var npid: Variant = (npc.get("profile") as Dictionary).get("id", "") if npc.get("profile") is Dictionary else ""
		if str(npid) != "":
			preload("res://scripts/pnj/societe_v65.gd").noter("quete", str(npid), _now(), {"titre": str(q.get("titre", ""))})
	apply_bonuses()
	# V63 : de l'expérience pour chaque quête accomplie (V66 : le message le dit)
	var pr: Node = main.get("progression_v63")
	if pr != null:
		msgs.push_front("+%d XP" % int(pr.quest_xp(qid, (q.get("etapes", []) as Array).size())))
	main._show_message_v28("Quête accomplie : %s%s" % [str(q["titre"]), ("  (" + ", ".join(msgs) + ")") if not msgs.is_empty() else ""])
	if pr != null:
		pr.on_quest(qid, (q.get("etapes", []) as Array).size())
	if main.has_method("jingle"):
		main.jingle("victoire")
	changed.emit()


func _set_state(qid: String, st: String) -> void:
	var d: Dictionary = states.get(qid, {"etape": 0})
	d["etat"] = st
	states[qid] = d


func _advance(qid: String) -> void:
	var d: Dictionary = states.get(qid, {})
	d["etape"] = int(d.get("etape", 0)) + 1
	states[qid] = d
	var e: Dictionary = _step(qid)
	if not e.is_empty():
		main._show_message_v28("Quête « %s » : %s" % [str(quest(qid)["titre"]), str(e.get("objectif", ""))])
	_enter_step(qid)
	changed.emit()


## En arrivant sur une étape : on pose les objets à ramasser dans le monde.
func _enter_step(qid: String) -> void:
	var e: Dictionary = _step(qid)
	var spots: Array = e.get("lieux", []) + e.get("apparait", [])
	for i in range(spots.size()):
		var where: String = str(spots[i])
		if not lieux.has(where):
			continue
		var item: String = where
		var n: int = 1
		if e.has("objets") and e["objets"] is Dictionary:
			var keys: Array = (e["objets"] as Dictionary).keys()
			item = str(keys[0])
			if str(e["type"]) == "objets":
				item = where
			if item == "croissant":
				n = 3
		var uid: String = "q56_%s_%s" % [qid, where]
		if main.inventory_v28.taken.has(uid):
			continue
		main.inventory_v28.spawn_pickup(uid, item, n, lieux[where])


## Les objets de quête posés dans le monde, à recréer au chargement d'une partie.
func respawn_pickups() -> void:
	for q in QUETES:
		var qid: String = str(q["id"])
		if state(qid) == "en_cours":
			_enter_step(qid)


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== chaque seconde

func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		return
	_clock += delta
	if _course_t >= 0.0:
		_course_tick(delta)
	if _clock < 0.5:
		return
	_clock = 0.0
	for q in QUETES:
		var qid: String = str(q["id"])
		if state(qid) != "en_cours":
			continue
		var e: Dictionary = _step(qid)
		match str(e.get("type", "")):
			"ramasser":
				var all_taken: bool = true
				for where in e.get("lieux", []):
					if not main.inventory_v28.taken.has("q56_%s_%s" % [qid, str(where)]):
						all_taken = false
				if all_taken:
					_advance(qid)
			"etat":
				var tr: Dictionary = main._npc_ctx_v31().get("trouvailles", {})
				if int(tr.get(str(e["cle"]), 0)) > 0:
					_advance(qid)
			"quetes":
				var n: int = 0
				for q2 in QUETES:
					if str(q2["id"]) != qid and is_azur(q2) and state(str(q2["id"])) == "finie":
						n += 1
				if n >= int(e["n"]):
					_advance(qid)
			"course":
				if _course_t < 0.0 and lieux.has("fontaine"):
					var p: Vector3 = main._player_pos_v27()
					if Vector2(p.x, p.z).distance_to(Vector2(lieux["fontaine"].x, lieux["fontaine"].z)) < 4.5:
						_course_t = 0.0
						main._show_message_v28("Partez ! Jusqu'à la porte du phare !")
						main.sfx("ui_quete")


func _course_tick(delta: float) -> void:
	_course_t += delta
	var e: Dictionary = _step("course_phare")
	var limit: float = float(e.get("temps", 60.0))
	var p: Vector3 = main._player_pos_v27()
	var goal: Vector3 = lieux.get("phare_porte", Vector3.INF)
	if goal != Vector3.INF and p.distance_to(goal) < 4.0:
		var t: float = _course_t
		_course_t = -1.0
		if t <= limit:
			main._show_message_v28("Arrivé en %.1f secondes ! Va l'annoncer à Bernard." % t)
			_advance("course_phare")
		else:
			main._show_message_v28("%.1f secondes… trop lent ! Retourne à la fontaine pour réessayer." % t)
		return
	if _course_t > limit + 30.0:
		_course_t = -1.0
		main._show_message_v28("Course abandonnée. Retourne à la fontaine pour réessayer.")
		return
	if int(_course_t * 2.0) != int((_course_t - delta) * 2.0):
		main._show_message_v28("Course du phare : %d s" % int(_course_t))


## Creuser à un endroit de quête (appelé par la manette de la pelle).
func try_dig(p: Vector3) -> bool:
	for q in QUETES:
		var qid: String = str(q["id"])
		if state(qid) != "en_cours":
			continue
		var e: Dictionary = _step(qid)
		if str(e.get("type", "")) != "creuser":
			continue
		var w: Vector3 = lieux.get(str(e["lieu"]), Vector3.INF)
		if w != Vector3.INF and Vector2(p.x, p.z).distance_to(Vector2(w.x, w.z)) < 2.2:
			var got: int = main.inventory_v28.add(str(e["objet"]), 1)
			if got <= 0:
				main._show_message_v28("Ton sac est plein !")
				return true
			main._show_message_v28("Tu as trouvé : " + str(main.inventory_v28.ITEMS[str(e["objet"])]["name"]) + " !")
			main.sfx("ui_quete")
			_advance(qid)
			return true
	return false


## Les endroits à creuser ou à fouiller qui brillent (pour l'affichage).
func dig_spots() -> Array:
	var out: Array = []
	for q in QUETES:
		var qid: String = str(q["id"])
		if state(qid) == "en_cours" and str(_step(qid).get("type", "")) == "creuser":
			var w: Vector3 = lieux.get(str(_step(qid)["lieu"]), Vector3.INF)
			if w != Vector3.INF:
				out.append(w)
	return out


# =================================================================== bonus

func apply_bonuses() -> void:
	if main == null:
		return
	var hero: Node = main.get("hero_v28")
	# V63 : les points de caractéristique de la progression s'ajoutent aux bonus des quêtes
	var pr: Node = main.get("progression_v63")
	if hero != null:
		var hp_max: int = 10 + 2 * (int(bonus["coeur"]) + (int(pr.extra("coeur")) if pr != null else 0))
		if int(hero.HP_MAX) != hp_max:
			hero.set_max_hearts(hp_max)
		hero.STAMINA_MAX = 10.0 + 3.0 * float(bonus["endurance"]) + (float(pr.extra("endurance")) if pr != null else 0.0)
		hero.bonus_force = int(bonus["force"]) + (int(pr.extra("force")) if pr != null else 0)
		if pr != null:
			pr.apply_hero()
	var mer: Node = main.get("mer_v55")
	if mer != null:
		mer.AIR_MAX = 18.0 + 7.0 * float(bonus["souffle"])
	# les réductions chez les commerçants
	var r := remises.duplicate()
	r["azur"] = float(rep_level()[2])
	Brain.remises = r


func discount_text() -> String:
	var parts: Array = []
	var lvl: Array = rep_level()
	if float(lvl[2]) > 0.0:
		parts.append("-%d %% chez les commerçants de Port-Azur" % int(float(lvl[2]) * 100.0))
	if remises.has("tout"):
		parts.append("-%d %% partout (clé de la ville)" % int(float(remises["tout"]) * 100.0))
	if remises.has("margaux"):
		parts.append("-15 % à la boulangerie")
	if remises.has("paulo"):
		parts.append("-15 % chez Paulo")
	return "\n".join(parts) if not parts.is_empty() else "Aucune pour l'instant."


# =================================================================== listes pour le carnet

## Toutes les quêtes connues, rangées : {"en_cours": [], "a_faire": [], "accomplies": []}.
## Chaque entrée : {titre, lieu, qui, texte, objectif, recompense, sorte, id}
func listing() -> Dictionary:
	var out := {"en_cours": [], "a_faire": [], "accomplies": []}
	var ctx: Dictionary = main._npc_ctx_v31()
	var tr: Dictionary = ctx.get("trouvailles", {})
	# les quêtes de Port-Azur
	for q in QUETES:
		var qid: String = str(q["id"])
		var st: String = state(qid)
		var giver: String = str(q["donneur"])
		var known: bool = st != "" or _npc_met(giver)
		if not known:
			continue
		var e := {"id": qid, "titre": str(q["titre"]), "lieu": str(q["lieu"]), "qui": npc_name(giver), "texte": str(q["resume"]),
			"recompense": _reward_text(q.get("recompense", {})), "sorte": str(q.get("sorte", "Port-Azur"))}
		match st:
			"finie":
				e["objectif"] = "Accomplie."
				out["accomplies"].append(e)
			"en_cours":
				e["objectif"] = str(_step(qid).get("objectif", ""))
				if str(_step(qid).get("type", "")) == "ramasser":
					var got: int = 0
					var tot: int = 0
					for where in _step(qid).get("lieux", []):
						tot += 1
						if main.inventory_v28.taken.has("q56_%s_%s" % [qid, str(where)]):
							got += 1
					if tot > 1:
						e["objectif"] += "  (%d / %d)" % [got, tot]
				e["etapes"] = _steps_text(qid)
				out["en_cours"].append(e)
			_:
				if not _can_offer(q):
					continue
				e["objectif"] = "Parler à %s : « %s »" % [npc_name(giver), str(q.get("offre_label", ""))]
				out["a_faire"].append(e)
	# les quêtes des habitants des autres îles
	for n in main.npcs_v31:
		if not is_instance_valid(n) or str(n.profile.get("groupe", "")) == "azur":
			continue
		var qd: Dictionary = n.profile.get("quete", {})
		if qd.is_empty():
			continue
		var mst: String = str(n.brain.memoire.get("quete", ""))
		var met: bool = int(n.brain.memoire.get("visites", 0)) > 0
		if not met and mst == "":
			continue
		var need: Dictionary = qd.get("objets", {str(qd.get("objet", "")): int(qd.get("nombre", 1))})
		var e2 := {"id": "pnj_" + str(n.profile["id"]), "titre": str(qd.get("sujet", "La demande de " + str(n.display_name))).replace("…", ""),
			"lieu": place_name(n.global_position), "qui": str(n.display_name), "sorte": "Habitants",
			"texte": ("%s m'a demandé : %s." % [str(n.display_name), _names(need)]) if mst != "" else ("%s a peut-être besoin d'aide. Il faut apprendre à le connaître." % str(n.display_name)),
			"recompense": _items_text(qd.get("recompense", []))}
		match mst:
			"finie":
				e2["objectif"] = "Accomplie."
				out["accomplies"].append(e2)
			"demandee":
				e2["objectif"] = "Apporter : " + _names(need)
				out["en_cours"].append(e2)
			_:
				e2["objectif"] = "Parler avec %s (de sa vie, de ses soucis)." % str(n.display_name)
				out["a_faire"].append(e2)
	# les grandes aventures
	for a in AVENTURES:
		var steps: Array = a["etapes"]
		var done: int = 0
		for s in steps:
			if int(tr.get(str(s[0]), 0)) > 0:
				done += 1
			else:
				break
		var started: bool = int(tr.get(str(a["debut"]), 0)) > 0 or done > 0
		var e3 := {"id": "av_" + str(a["id"]), "titre": str(a["titre"]), "lieu": str(a["lieu"]), "qui": "Grande aventure", "sorte": "Aventure",
			"texte": "Étapes franchies : %d / %d." % [done, steps.size()], "recompense": "Des trésors, des amis et des souvenirs."}
		if done >= steps.size():
			e3["objectif"] = "Accomplie."
			out["accomplies"].append(e3)
		elif started:
			e3["objectif"] = str(steps[done][1])
			out["en_cours"].append(e3)
	return out


func _steps_text(qid: String) -> Array:
	var out: Array = []
	var steps: Array = quest(qid).get("etapes", [])
	var cur: int = step_of(qid)
	for i in range(steps.size()):
		out.append([str(steps[i].get("objectif", "")), i < cur, i == cur])
	return out


func _reward_text(rec: Dictionary) -> String:
	var parts: Array = []
	if int(rec.get("pieces", 0)) > 0:
		parts.append("%d pièces" % int(rec["pieces"]))
	for o in rec.get("objets", []):
		parts.append(_names({str(o[0]): int(o[1])}))
	for k in rec.get("bonus", {}):
		parts.append({"coeur": "+1 cœur", "endurance": "+ endurance", "souffle": "+ souffle", "force": "+1 force"}.get(k, k))
	if rec.has("titre"):
		parts.append("titre « %s »" % str(rec["titre"]))
	if rec.has("remise"):
		parts.append("réduction")
	if str(rec.get("flag", "")) == "teleportation":
		parts.append("la magie de téléportation")
	if int(rec.get("rep", 0)) > 0:
		parts.append("+%d réputation" % int(rec["rep"]))
	return ", ".join(parts)


func _items_text(list: Array) -> String:
	var parts: Array = []
	for o in list:
		parts.append(_names({str(o[0]): int(o[1])}))
	return ", ".join(parts) if not parts.is_empty() else "Sa reconnaissance."


## Le nom du lieu où se trouve un point du monde.
func place_name(p: Vector3) -> String:
	if main == null:
		return ""
	if main.get("azur_v56") != null and main.azur_v56 != null and main.azur_v56.contains(p):
		return "Port-Azur"
	if main.get("mer_v55") != null and main.mer_v55 != null and main.mer_v55.atl != null and main.mer_v55.atl.in_dome(p + Vector3.UP):
		return "L'Atlantide"
	if main.get("feerie_v58") != null and main.feerie_v58 != null and main.feerie_v58.contains(p):
		return "Le royaume des fées"
	if main.get("arcanelle_v67") != null and main.arcanelle_v67 != null and main.arcanelle_v67.contains(p):
		var az: String = str(main.arcanelle_v67.zone_at(p))
		return {"arcanelle_bourg": "Arcanelle, le bourg", "arcanelle_chaudron": "Arcanelle, Le Chaudron Fumant", "arcanelle_bibliotheque": "Arcanelle, la bibliothèque",
			"arcanelle_salle": "Arcanelle, la Salle des Cours", "arcanelle_crypte": "Arcanelle, la Crypte aux Runes", "arcanelle_bois": "Arcanelle, le Bois Tors",
			"arcanelle_falaises": "Arcanelle, les falaises du nord", "arcanelle_rivage": "Arcanelle, le rivage"}.get(az, "Arcanelle, l'île des sorciers")
	if main.get("montjoie_v71") != null and main.montjoie_v71 != null and main.montjoie_v71.city != null and main.montjoie_v71.owns_point(p):
		return str(main.montjoie_v71.place_name(p))
	if main.get("astralys_v76") != null and main.astralys_v76 != null and main.astralys_v76.city != null and main.astralys_v76.owns_point(p):
		return str(main.astralys_v76.place_name(p))
	if main.get("boucan_v75") != null and main.boucan_v75 != null and main.boucan_v75.city != null and main.boucan_v75.owns_point(p):
		return str(main.boucan_v75.place_name(p))
	if main.get("moai_v87") != null and main.moai_v87 != null and main.moai_v87.ile != null and main.moai_v87.owns_point(p):
		return str(main.moai_v87.place_name(p))
	if main.get("pixel_v90") != null and main.pixel_v90 != null and main.pixel_v90.ile != null and main.pixel_v90.owns_point(p):
		return str(main.pixel_v90.place_name(p))
	if main.get("larsen_v91") != null and main.larsen_v91 != null and main.larsen_v91.ile != null and main.larsen_v91.owns_point(p):
		return str(main.larsen_v91.place_name(p))
	if main.get("braise_v70") != null and main.braise_v70 != null and main.braise_v70.city != null and main.braise_v70.owns_point(p):
		return str(main.braise_v70.place_name(p))
	if main.get("soleils_v69") != null and main.soleils_v69 != null and main.soleils_v69.egypte != null and main.soleils_v69.owns_point(p):
		return str(main.soleils_v69.place_name(p))
	if main.get("pirates_v68") != null and main.pirates_v68 != null and main.pirates_v68.contains(p):
		var bz: String = str(main.pirates_v68.zone_at(p))
		return {"balafre_port": "La Balafre, Port-Coutelas", "balafre_crane_fendu": "La Balafre, le Crâne Fendu", "balafre_dent_requin": "La Balafre, la Dent du Requin",
			"balafre_navire": "La Balafre, à bord d'un navire", "balafre_marais": "La Balafre, le Marais des Noyés", "balafre_ravin": "La Balafre, le ravin du Crâne",
			"balafre_fort": "La Balafre, le Fort Maudit", "balafre_cimetiere": "La Balafre, le cimetière", "balafre_plage": "La Balafre, la Plage des Os",
			"balafre_rivage": "La Balafre, le rivage"}.get(bz, "L'Île de la Balafre")
	if main.get("grande_v59") != null and main.grande_v59 != null and main.grande_v59.contains(p):
		var gz: String = str(main.grande_v59.zone_at(p))
		if gz.begins_with("carene"):
			return "Carène, le port de l'épave"
		if gz.begins_with("ramure"):
			return {"ramure_cercle": "Ramure, le Cercle de la Lune", "ramure_arbres": "Ramure, dans les arbres", "ramure_ponton": "Ramure, le ponton"}.get(gz, "Ramure, le village des oreilles")
		if gz.begins_with("cliquetis"):
			return {"cliquetis_port": "Cliquetis, le port", "cliquetis_foire": "Cliquetis, la Foire des Inventions"}.get(gz, "Cliquetis, la cité des ingénieurs")
		if gz.begins_with("tazira"):
			return {"tazira_navire": "Tazira, à bord de la Murène Noire", "tazira_murene": "Tazira, La Murène Ivre", "tazira_souk": "Tazira, le souk",
				"tazira_place": "Tazira, la place des Lanternes", "tazira_port": "Tazira, le port"}.get(gz, "Tazira, le port des sables")
		return {"grande_nord": "Les hautes terres du nord", "grande_est": "La forêt des brumes", "grande_sud": "Le désert du sud",
			"grande_massif": "Le Cœur-de-Pierre"}.get(gz, "La grande île de l'est")
	if p.y > 100.0:
		return "L'île flottante"
	if main.get("nains_v46") != null and main.nains_v46 != null and main.nains_v46.ile != null and main.nains_v46.ile.contains(p.x, p.z):
		return "Forgefer, chez les nains" if p.y < 10.0 and absf(p.y - main._height_at(p.x, p.z)) > 6.0 else "La Montagne de Feu"
	if main.get("elfes_v41") != null and main.elfes_v41 != null and main.elfes_v41.ile != null and main.elfes_v41.ile.contains(p.x, p.z):
		return "Le Bois-Doré, chez les elfes"
	if main.get("jungle_v29") != null and main.jungle_v29 != null and main.jungle_v29.contains(p.x, p.z):
		return "L'île de la jungle"
	if Vector2(p.x, p.z).length() < 120.0:
		return "L'île du village" if p.y > -20.0 else "Le temple, sous le village"
	return "En mer"


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return {"etats": states.duplicate(true), "bonus": bonus.duplicate(), "rep": reputation, "titres": titres.duplicate(), "flags": flags.duplicate(), "remises": remises.duplicate()}


func load_data(d: Dictionary) -> void:
	states = (d.get("etats", {}) as Dictionary).duplicate(true) if d.get("etats", {}) is Dictionary else {}
	bonus = {"coeur": 0, "endurance": 0, "souffle": 0, "force": 0}
	var b: Variant = d.get("bonus", {})
	if b is Dictionary:
		for k in b:
			bonus[k] = int(b[k])
	reputation = int(d.get("rep", 0))
	titres = (d.get("titres", []) as Array).duplicate() if d.get("titres", []) is Array else []
	flags = (d.get("flags", {}) as Dictionary).duplicate() if d.get("flags", {}) is Dictionary else {}
	remises = (d.get("remises", {}) as Dictionary).duplicate() if d.get("remises", {}) is Dictionary else {}
	_course_t = -1.0
	apply_bonuses()
	changed.emit()

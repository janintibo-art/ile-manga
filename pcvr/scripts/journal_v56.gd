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
		"resume": "Paulo veut des poissons pêchés du jour : deux daurades et deux maquereaux.",
		"offre_label": "Un souci en cuisine ?",
		"offre": "Un drame ! Il me faut du poisson frais du jour pour ma bouillabaisse du dimanche. Deux daurades, deux maquereaux. Pêchés par toi, je te fais confiance.",
		"etapes": [
			{"type": "objets", "pnj": "paulo", "objets": {"dorade": 2, "maquereau": 2}, "label": "Voici vos poissons.", "objectif": "Pêcher et apporter à Paulo deux daurades et deux maquereaux"},
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
				for k in e.get("objets", []):
					if main.inventory_v28.count(str(k)) > 0:
						need = {str(k): 1}
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
					if str(q2["id"]) != qid and state(str(q2["id"])) == "finie":
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

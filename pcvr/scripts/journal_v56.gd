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
			return _do_step(npc, qid)
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
	apply_bonuses()
	main._show_message_v28("Quête accomplie : %s%s" % [str(q["titre"]), ("  (" + ", ".join(msgs) + ")") if not msgs.is_empty() else ""])
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
	if hero != null:
		var hp_max: int = 10 + 2 * int(bonus["coeur"])
		if int(hero.HP_MAX) != hp_max:
			hero.set_max_hearts(hp_max)
		hero.STAMINA_MAX = 10.0 + 3.0 * float(bonus["endurance"])
		hero.bonus_force = int(bonus["force"])
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

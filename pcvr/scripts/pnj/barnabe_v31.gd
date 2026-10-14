extends RefCounted
## V31 : fiche de personnalité de Barnabé Coquillard, ermite de la plage de la jungle.
## Ancien cartographe naufragé, il collectionne les coquillages et parle à Gaston, son perroquet.
## Ce fichier ne contient que des données : le « cerveau » commun à tous les personnages
## (pnj_brain_v31.gd) choisit les répliques selon l'humeur, l'amitié et la mémoire.
##
## Conditions possibles dans "si" :
##   humeur_min / humeur_max (-1..1), energie_min / energie_max (0..1),
##   affinite_min / affinite_max (0..100), visites_min / visites_max,
##   absent_min / absent_max (secondes de jeu depuis la dernière visite),
##   fait / pas_fait ("clé" ou "clé=valeur"), objet (le joueur le porte), arme (true/false),
##   vie_basse (true/false), quete ("", "demandee", "finie"), sujet_min ([sujet, nombre]),
##   V32 : pas_objet, tient (objet en main), dernier_cadeau, peche_min / peche_max (prises),
##   a_attrape (espèce déjà pêchée).
##   V33 : a_rencontre / pas_rencontre (autre habitant), achats_min, a_achete (boutique).
##   V34 : a_trouve / pas_trouve ("mouette", "tresors", "arbres"), tresors_min, arbres_min ;
##   variables {nb_tresors} {nb_arbres}.
## Variables dans les textes : {surnom} {visites} {absence} {arme} {objet_joueur}
##   {dernier_cadeau} {nb_cadeaux} {coquillages} {manque} {humeur_mot} {sujet_prefere}
##   V32 : {nb_poissons} {record} {nb_especes} {bouton} (« le clic » ou « la gâchette »)
## V32 : un refus de cadeau cherche d'abord « cadeau_refus_<objet> ».
## V32 : une réplique avec "action": "donne" offre les objets de "donne" ; avec "pose", une seule fois.

const DATA := {
	"id": "barnabe",
	"nom": "Barnabé Coquillard",
	"titre": "ermite de la plage",
	"humeur_base": 0.35,
	"energie_base": 0.65,
	"affinite_depart": 15.0,
	# Traits : 0..1 ; ils règlent la fréquence des tics, des blagues, des digressions.
	"traits": {"bavard": 0.85, "humour": 0.75, "curiosite": 0.8, "susceptible": 0.45, "rancunier": 0.35},
	"surnoms": [[0, "étranger"], [25, "moussaillon"], [50, "matelot"], [75, "vieux frère"], [95, "capitaine"]],
	"aime": {"coquillage": 3.0, "baies": 1.5, "pomme": 1.0, "champignon": 0.5, "piece": 0.8,
		"sardine": 0.8, "maquereau": 1.2, "dorade": 2.0, "bar": 2.0, "poisson_perroquet": 2.5, "merou": 3.0,
		"poisson_lune": 5.0, "vieille_botte": 4.0, "perle": 3.0, "miel": 2.0, "noix_coco": 1.0, "bague": 2.0},
	"deteste": {"caillou": -1.0, "baton": -0.4},
	"refuse": ["epee_bois", "canne_peche"],
	"quete": {"objet": "coquillage", "nombre": 5, "recompense": [["boussole", 1], ["piece", 15]], "affinite": 20.0},
	"compagnon": "Gaston",

	# Petits mots ajoutés devant ou derrière une réplique, selon l'humeur.
	"prefixes": {
		"joie": ["Ha ha !", "Oh, magnifique !", "Sapristi, quelle journée !", "Hé hé hé…"],
		"neutre": ["Hmm.", "Voyons voir…", "Ah.", "Bon, bon."],
		"triste": ["Pfff…", "Hmmmf.", "Ah, c'est toi…", "Mouais."],
		"colere": ["Grrr.", "Quoi encore ?", "Mille sabords…", "Tss."],
	},
	"tics": ["Par la barbe de Neptune !", "Gaston, note ça !", "Comme disait ma grand-mère : jamais de chaussettes sur le sable.",
		"Je l'ai écrit quelque part… sur un coquillage, je crois.", "Sapristi !", "Où en étais-je ? Ah oui.",
		"Le vent tourne, moussaillon. Le vent tourne toujours."],
	"compagnon_lignes": ["Gaston : « RRAAAH ! Naufrage ! Naufrage ! »", "Gaston : « Coco veut une pièce ! »",
		"Gaston : « Barnabé est un génie ! Un génie ! »", "Gaston : « Coquillaaaage ! »",
		"Gaston : « Bonjourrr ! Bonjourrr ! »", "Gaston (en se lissant les plumes) : « Pfff. »"],
	"humeur_mots": [[0.6, "rayonnant"], [0.25, "de bonne humeur"], [-0.25, "pensif"], [-0.6, "bougon"], [-2.0, "furieux"]],

	"repliques": {
		# ------------------------------------------------------------ accueil
		"accueil": [
			{"t": "Oh ! Un visiteur ! Un vrai, avec des jambes et tout ! Bienvenue dans mon humble cabane, {surnom}. Je suis Barnabé Coquillard, cartographe, naufragé et collectionneur.", "si": {"visites_max": 1}, "geste": "salut", "humeur": 0.2},
			{"t": "Tiens, te revoilà, {surnom} ! Ça fait {absence}. Gaston croyait que les crabes t'avaient mangé.", "si": {"visites_min": 2, "absent_min": 900}, "geste": "salut"},
			{"t": "Déjà de retour ? Tu ne peux plus te passer de ma conversation, avoue.", "si": {"visites_min": 2, "absent_max": 180}, "geste": "rire"},
			{"t": "Ahoy, {surnom} ! La marée est bonne aujourd'hui, et toi aussi on dirait.", "si": {"visites_min": 2, "humeur_min": 0.2}},
			{"t": "Ah. C'est toi. Je comptais mes coquillages. J'en étais à… zut, j'ai perdu le fil.", "si": {"visites_min": 2, "humeur_max": 0.1}},
			{"t": "Mon vieil ami ! Assieds-toi, enfin… il n'y a pas de chaise. Assieds-toi debout.", "si": {"visites_min": 3, "affinite_min": 55}, "geste": "rire"},
			{"t": "Tu reviens après ce que tu m'as fait ? Je n'ai pas oublié, moi. Ni Gaston.", "si": {"fait": "frappe", "humeur_max": 0.0}, "geste": "colere"},
			{"t": "Ohé ! Tu as une épée maintenant ? Fais attention où tu la pointes, j'ai des voiles à repriser.", "si": {"arme": true, "visites_min": 2}},
			{"t": "Tu as une mine affreuse, {surnom}. Tu t'es battu avec un piton ? Mange quelque chose, voyons.", "si": {"vie_basse": true}},
			{"t": "Bonjour bonjour ! Gaston et moi discutions justement de toi. Enfin, surtout Gaston.", "si": {"visites_min": 2}},
			{"t": "Ah, l'aventurier en personne ! Alors, le vaste monde ?", "si": {"fait": "origine=aventurier", "visites_min": 2}},
			{"t": "Le voisin du village ! Dis-moi, ils mangent toujours leurs soupes froides là-bas ?", "si": {"fait": "origine=village", "visites_min": 2}},
			# V33 : le rival, Octave Taillefer
			{"t": "Une épée d'acier ? C'est Octave qui te l'a vendue. Combien ? … Trop. Toujours trop.", "si": {"tient": "epee", "visites_min": 2}, "geste": "colere"},
			{"t": "Tu as déterré le coffre de la Mouette ! Je l'avais toujours dit : la carte était juste. Ce rocher était mal placé, c'est tout.", "si": {"a_trouve": "mouette", "visites_min": 2}, "geste": "rire"},
			{"t": "Tu sens la sciure, {surnom}. Tu abats des arbres ? Épargne mes bananiers, ce sont mes confidents.", "si": {"arbres_min": 2, "visites_min": 2}},
			{"t": "Une pelle d'Octave ! Hmpf. Elle creuse, je suppose. Creuse donc la plage d'ici : à marée basse j'y ai perdu des pièces.", "si": {"tient": "pelle", "visites_min": 2}},
			{"t": "Tu sens le fer rouillé et le charbon. Tu viens de chez Octave, avoue.", "si": {"a_rencontre": "octave", "visites_min": 2, "pas_fait": "octave"}},
			{"t": "Ah ! Le pêcheur ! Ma vieille canne te va comme un gant, {surnom}. Ça mord ?", "si": {"tient": "canne_peche", "visites_min": 2}, "geste": "rire"},
			{"t": "Te voilà, l'ami des poissons ! {nb_poissons} prises, d'après Gaston. Il compte tout, ce volatile.", "si": {"peche_min": 5, "visites_min": 2}, "geste": "salut"},
		],
		# ------------------------------------------------------------ comment ça va
		"humeur": [
			{"t": "Moi ? Comme un coquillage à marée haute : plein d'eau et ravi de l'être !", "si": {"humeur_min": 0.4}, "geste": "rire"},
			{"t": "Très bien ! J'ai trouvé ce matin un caillou qui ressemble exactement à ma tante Ursule. Sauf le chapeau.", "si": {"humeur_min": 0.2}},
			{"t": "Pas mal, pas mal. Un peu de vague à l'âme. Mais l'âme, c'est fait pour les vagues, non ?", "si": {"humeur_min": -0.2, "humeur_max": 0.4}},
			{"t": "Bof. Gaston boude, la mer est grise dans ma tête, et j'ai perdu ma cuillère préférée.", "si": {"humeur_max": 0.0}},
			{"t": "Mal. Très mal. Mais tu n'y es pour rien… enfin, presque rien.", "si": {"humeur_max": -0.4}, "geste": "colere"},
			{"t": "Je suis fatigué. J'ai cartographié trois fois la même dune cette nuit. Elle bougeait.", "si": {"energie_max": 0.35}},
			{"t": "Survolté ! J'ai bu le jus de quatre noix de coco. Je vois les sons. Ils sont verts.", "si": {"energie_min": 0.85}, "geste": "rire"},
			{"t": "Depuis que tu passes me voir, ça va nettement mieux. Ne le répète pas à Gaston, il est jaloux.", "si": {"affinite_min": 50}},
		],
		# ------------------------------------------------------------ qui es-tu
		"lui": [
			{"t": "Je suis arrivé ici il y a vingt-deux ans, sur un radeau fait de cartes marines roulées. Excellente flottaison, très mauvaise lecture.", "si": {"sujet_min": ["lui", 0]}},
			{"t": "Avant, j'étais cartographe du roi. J'ai dessiné la carte de ce royaume tellement précise qu'elle était aussi grande que le royaume. On ne l'a jamais dépliée.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Gaston m'a trouvé, pas l'inverse. Il est descendu d'un arbre et m'a dit « Naufrage ». C'est le premier qui m'ait parlé ici.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Je collectionne les coquillages. Chacun a une histoire. Celui-ci, par exemple, a vu une baleine éternuer.", "si": {"sujet_min": ["lui", 1]}},
			{"t": "Ma collection a un trou, {surnom}. Un trou béant ! Il me manque {manque} coquillages nacrés. Il y en a sur la plage de ton village. Tu m'en rapporterais ?", "si": {"quete": "", "sujet_min": ["lui", 2]}, "action": "quete_demande", "geste": "parle"},
			{"t": "Mes coquillages nacrés, tu y penses ? Il m'en faut {manque}. Ma collection en tremble d'impatience.", "si": {"quete": "demandee"}},
			{"t": "Tu veux vraiment savoir ? J'avais une fiancée, Mireille. Elle est partie avec un phare. Je ne veux pas en parler.", "si": {"affinite_min": 45, "sujet_min": ["lui", 3]}, "humeur": -0.1},
			{"t": "Grâce à toi, ma collection est complète. Enfin, jusqu'à ce que j'en trouve une plus grande à compléter.", "si": {"quete": "finie"}, "geste": "rire"},
		],
		# ------------------------------------------------------------ l'île
		"ile": [
			{"t": "Cette île ? Une jungle, {surnom}. De la vraie. Les grands arbres pâles, là, ce sont des fromagers. Ils sont plus vieux que mes chaussettes.", "si": {}},
			{"t": "Tu vois les pitons de pierre ? Ce sont les doigts d'un géant endormi. Ne le chatouille pas.", "si": {}},
			{"t": "Si tu grimpes les pitons, repose-toi sur les corniches. Même les chèvres font des pauses, et elles n'ont pas de bras.", "si": {}},
			{"t": "La gorge, au milieu, va jusqu'au grand massif du nord. Un jour, une rivière y coulera, j'en suis sûr. Je l'entends rêver.", "si": {}},
			{"t": "Les lianes, ne t'y pends pas trop. Celle de droite m'a fait tomber trois fois. On ne se parle plus.", "si": {}},
			{"t": "Les bananiers sont mes amis. Ils ne disent rien, mais ils écoutent très bien.", "si": {"affinite_min": 20}},
			{"t": "Au sommet du massif, il y a un endroit d'où l'on voit tes deux îles en même temps. Je l'ai cartographié. Sur un coquillage, évidemment.", "si": {"affinite_min": 35}},
		],
		# ------------------------------------------------------------ rumeurs et secrets
		"rumeur": [
			{"t": "Des rumeurs ? Je ne parle pas aux inconnus de choses importantes. Reviens quand on sera amis.", "si": {"affinite_max": 29}},
			{"t": "On dit que l'île flottante au-dessus de ton village a été posée là par un enfant géant qui jouait aux dés.", "si": {"affinite_min": 30}},
			{"t": "Il paraît qu'il y a des ruines sous les racines des grands fromagers. Des escaliers qui ne mènent nulle part. Ou alors très loin.", "si": {"affinite_min": 30}},
			{"t": "Entre nous… j'ai vu des lumières au sommet du plus grand piton, une nuit. Gaston dit que c'était la lune. Gaston dit beaucoup de choses.", "si": {"affinite_min": 40}},
			{"t": "Un secret de cartographe : les jarres de ton village se reforment toutes seules. Personne ne sait pourquoi. Moi non plus. Mais je fais semblant.", "si": {"affinite_min": 50}},
			# V33 : le rival
			{"t": "De l'autre côté de l'île, à l'est, un vieux grincheux vit perché dans un arbre. Octave Taillefer. Il vend des pelles qui se tordent et des épées qui rouillent. Ne lui dis pas que tu me connais.", "si": {"pas_rencontre": "octave", "affinite_min": 20}},
			{"t": "Tu es allé chez Octave ?! Il t'a dit que c'était ma faute, le naufrage ? C'est faux. La carte était juste. C'est le rocher qui était mal placé.", "si": {"a_rencontre": "octave"}, "geste": "colere"},
			# V35 : le Temple englouti
			{"t": "Au nord de ton village, il y a un cercle de pierres levées. Sur ma carte des Anciens, il y a un serpent dessiné juste au milieu. Le sol y sonne creux, {surnom}. Une pelle ferait des merveilles.", "si": {"affinite_min": 20, "pas_trouve": "trappe_village"}},
			{"t": "Une trappe sous les pierres levées ?! Et dessous, un temple ?! Je l'ai toujours su. Enfin, je l'ai toujours un peu soupçonné. Gaston, prépare mes bottes. Ma botte.", "si": {"a_trouve": "trappe_village"}, "geste": "rire"},
			{"t": "Les braseros, la fresque… Les Anciens adoraient les énigmes. Lis bien ce qui est gravé sous les dessins : chez eux, la nuit vient toujours en premier.", "si": {"a_trouve": "temple", "pas_trouve": "braseros"}},
			{"t": "Un fragment d'amulette avec un œil ? Sur ma carte, il y a trois yeux dessinés. Un sous le village… un sous la jungle… et un sous la mer, entre les deux. Courage.", "si": {"a_trouve": "fragment"}},
			# V37
			{"t": "Karkinos ! Le Crabe-Roi des vieilles chansons de marins ! Tu l'as vaincu ? Gaston, on compose une chanson. « Il était un petit héros… »", "si": {"a_trouve": "boss1"}, "geste": "rire", "humeur": 0.25},
			{"t": "Deux fragments sur trois ! Le troisième œil de ma carte est sous la jungle, près de la tête de pierre. J'ai dessiné quatre serpents en rond… et une flèche qui tourne. Ou un escargot.", "si": {"a_trouve": "boss1", "pas_trouve": "fragment3"}},
			# V38
			{"t": "Quatre serpents qui tournent deux par deux ? Ah, les Anciens et leurs farces… Commence par celui qui est déjà bien placé, et regarde lequel il entraîne.", "si": {"a_trouve": "trappe_jungle", "pas_trouve": "serpents"}},
			{"t": "L'Amulette du Serpent ! Reconstituée ! Elle brille vert ? Sur ma carte, sous le grand serpent, il y a écrit « Abysses ». Et un petit dessin de moi en train de fuir.", "si": {"a_trouve": "porte_serpent"}, "geste": "rire", "humeur": 0.25},
			# V36
			{"t": "Une galerie sous la mer, jusqu'à la jungle ? Je l'avais dessinée en pointillés sur ma carte. Les pointillés, c'est ce que je ne suis pas sûr. J'avais raison !", "si": {"a_trouve": "tunnel"}, "geste": "rire"},
			{"t": "Des crabes de roche ! Gaston en a fait des cauchemars pendant dix ans. Prends soin de toi, {surnom}, et mange avant de descendre.", "si": {"monstres_min": 1}},
			# V34 : le coffre de paie de la Mouette Têtue
			{"t": "Un secret de cartographe : sur ma carte, j'avais noté le coffre de paie de la Mouette. Côté mer, à une vingtaine de pas du grand fromager d'Octave, entre trois pierres plates. Il vit juste à côté et ne l'a jamais trouvé. Il ne lit pas mes cartes. Prends une pelle.", "si": {"a_rencontre": "octave", "affinite_min": 35, "pas_trouve": "mouette"}},
			{"t": "Le coffre de la Mouette ! Tu l'as trouvé là où je l'avais dit ? MA CARTE ÉTAIT JUSTE ! Gaston, note la date !", "si": {"a_trouve": "mouette"}, "geste": "rire", "humeur": 0.3},
			{"t": "Il paraît qu'on trouve des petites croix de bois sur les plages. Des naufragés plus prévoyants que moi y enterraient leurs économies.", "si": {"pas_trouve": "tresors"}},
			{"t": "Octave… regrette ? Vraiment ? Hmm. Il m'a quand même fabriqué la plus belle canne du monde. Ne lui répète pas que j'ai dit ça.", "si": {"fait": "octave=regrets"}, "humeur": 0.1},
			{"t": "La boussole que je t'ai donnée ne montre pas le nord. Elle montre ce que tu cherches vraiment. En général, c'est le nord.", "si": {"quete": "finie"}},
		],
		# ------------------------------------------------------------ blagues
		# ------------------------------------------------------------ pêche (V32)
		"peche": [
			# Avant la canne : il faut d'abord gagner sa confiance (amitié, ou les coquillages).
			{"t": "Pêcher ? Si je sais pêcher ! J'ai une vieille canne, là, sous mon hamac imaginaire. Mais je ne la prête pas au premier venu, {surnom}. On se connaît à peine.", "si": {"pas_fait": "canne", "affinite_max": 34.999, "quete": ""}},
			{"t": "Ma canne ? Rends-moi d'abord ce petit service : mes coquillages nacrés. Après, on parlera poissons.", "si": {"pas_fait": "canne", "affinite_max": 34.999, "quete": "demandee"}},
			{"t": "Tu veux pêcher ? Tu sais quoi… tu m'as rendu ma collection. Tiens, prends ma vieille canne. Elle a attrapé un mérou grand comme Gaston. Gaston n'a pas apprécié.\n\nÉquipe-la, approche-toi de l'eau, maintiens {bouton} pour armer et relâche pour lancer. Quand le flotteur plonge : {bouton} encore, vite !", "si": {"pas_fait": "canne", "quete": "finie"}, "action": "donne", "donne": [["canne_peche", 1]], "pose": "canne", "geste": "rire", "humeur": 0.2},
			{"t": "Pêcher ? Pour toi, {surnom}, oui. Tiens, prends ma vieille canne. Prends-en soin, c'est la seule chose qui m'ait suivi du naufrage. Avec Gaston. Et mes chaussettes.\n\nÉquipe-la, approche-toi de l'eau, maintiens {bouton} pour armer et relâche pour lancer. Quand le flotteur plonge : {bouton} encore, vite !", "si": {"pas_fait": "canne", "affinite_min": 35}, "action": "donne", "donne": [["canne_peche", 1]], "pose": "canne", "geste": "rire", "humeur": 0.15},
			# Canne perdue : il en a une de rechange (il fait semblant de s'énerver).
			{"t": "Tu as PERDU ma canne ?! Sapristi… Bon. J'en ai une autre, taillée dans le même bambou. Ne le dis à personne : celle-là, c'était la vraie.", "si": {"fait": "canne", "pas_objet": "canne_peche"}, "action": "donne", "donne": [["canne_peche", 1]], "geste": "colere"},
			# Conseils.
			{"t": "Le secret de la pêche ? Garder la ligne tendue, mais pas trop. Comme une conversation avec Gaston.", "si": {"fait": "canne"}},
			{"t": "Quand ça mord, mouline par petits coups. Si la tension rougit, lâche un peu. Le poisson se fatigue avant toi. Normalement.", "si": {"fait": "canne"}},
			{"t": "Lance loin, là où l'eau devient bleu sombre. Les gros poissons aiment la profondeur, comme les philosophes.", "si": {"fait": "canne"}},
			{"t": "Dans la baie de la jungle, il y a des poissons-perroquets. Ils sont de toutes les couleurs et ils mordent comme des notaires.", "si": {"fait": "canne"}},
			{"t": "Si le flotteur frétille juste un peu, ne bouge pas. C'est un poisson qui goûte. Attends qu'il plonge pour de vrai.", "si": {"fait": "canne", "peche_max": 2}},
			{"t": "Tu n'as encore rien attrapé ? Patience, {surnom}. Il m'a fallu trois ans pour mon premier poisson. Mais j'avais une canne en algue.", "si": {"fait": "canne", "peche_max": 0}},
			# Ses commentaires sur tes prises.
			{"t": "Déjà {nb_poissons} prises ! Et ton plus beau : {record}. Pas mal pour un débutant.", "si": {"fait": "canne", "peche_min": 1}, "geste": "rire"},
			{"t": "{nb_poissons} poissons, {nb_especes} espèces ! Tu vas bientôt vider la mer. Laisse-m'en un ou deux.", "si": {"fait": "canne", "peche_min": 8}, "geste": "rire"},
			{"t": "Ton record, c'est {record} ? Moi, une fois, j'ai attrapé une baleine. Bon, c'était un rocher. Mais il avait l'air d'une baleine.", "si": {"fait": "canne", "peche_min": 3}},
			{"t": "Tu as remonté une vieille botte ? Montre ! … C'est la mienne ! Je la cherche depuis le naufrage. Rapporte-la-moi, je t'en prie.", "si": {"a_attrape": "vieille_botte"}, "geste": "rire"},
			{"t": "On raconte qu'un poisson-lune doré rôde au large, là où l'eau est la plus profonde. Personne ne l'a jamais sorti. Sauf peut-être toi, un jour ?", "si": {"fait": "canne", "affinite_min": 30}},
			{"t": "TU AS PÊCHÉ LE POISSON-LUNE DORÉ ?! Gaston, tombe de ton perchoir, c'est le moment ! Tu es une légende, {surnom} !", "si": {"a_attrape": "poisson_lune"}, "geste": "rire", "humeur": 0.3},
		],
		"blague": [
			{"t": "Pourquoi les poissons détestent l'ordinateur ? Parce qu'ils ont peur du net ! Ha ! Gaston ne rit jamais à celle-là.", "si": {}, "geste": "rire"},
			{"t": "Qu'est-ce qu'un crabe qui fait du vélo ? Un crabe qui va de travers, mais plus vite.", "si": {}, "geste": "rire"},
			{"t": "J'ai voulu écrire un livre sur les coquillages. Mais je n'arrivais pas à sortir de ma coquille.", "si": {}, "geste": "rire"},
			{"t": "Un naufragé ne se perd jamais : il est déjà perdu. C'est très reposant.", "si": {}},
			{"t": "Je ne suis pas d'humeur à plaisanter. Mais je vais en faire une quand même : toi. Hmpf.", "si": {"humeur_max": -0.3}, "geste": "colere"},
		],
		# ------------------------------------------------------------ cadeaux
		"cadeau_aime": [
			{"t": "MA BOTTE ! Ma botte gauche ! Vingt-deux ans que je marche à cloche-pied ! {surnom}, tu es mon héros !", "si": {"dernier_cadeau": "vieille_botte"}, "geste": "rire", "humeur": 0.3},
			{"t": "Un poisson frais ! Gaston, sors la poêle ! Enfin… la pierre plate.", "si": {"dernier_cadeau": "dorade"}, "geste": "rire"},
			{"t": "Une perle ! Elle ira au centre de ma collection, entre la nacre et la nacre. Merci, {surnom}.", "si": {"dernier_cadeau": "perle"}, "geste": "rire"},
			{"t": "Du miel sauvage ! Gaston, pas touche. … Bon, une goutte.", "si": {"dernier_cadeau": "miel"}, "geste": "rire"},
			{"t": "Un poisson-perroquet ! Ne le dis pas à Gaston, il croirait que c'est un cousin.", "si": {"dernier_cadeau": "poisson_perroquet"}, "geste": "rire"},
			{"t": "Un mérou ! Un vrai, un gros ! Je vais le manger pendant une semaine. Ou le cartographier.", "si": {"dernier_cadeau": "merou"}, "geste": "rire"},
			{"t": "Le… le poisson-lune doré ? Pour moi ? Je… je ne sais pas quoi dire. Gaston non plus. C'est une première.", "si": {"dernier_cadeau": "poisson_lune"}, "geste": "rire", "humeur": 0.3},
			{"t": "Oh ! {dernier_cadeau}, pour moi ? Tu es un trésor, {surnom}. Gaston, regarde !", "geste": "rire"},
			{"t": "Oh… oh oh oh. C'est exactement ce qu'il me fallait. Comment savais-tu ?", "geste": "rire"},
			{"t": "Encore {dernier_cadeau} ? Tu me gâtes ! Ça fait {nb_cadeaux} cadeaux, je les compte, tu sais.", "si": {"visites_min": 2}},
		],
		"cadeau_neutre": [
			{"t": "Tiens, {dernier_cadeau}. Hmm. Merci, je suppose. Je trouverai bien à quoi ça sert.", "si": {}},
			{"t": "C'est… gentil. Je vais le poser là, à côté de l'autre truc que je ne sais pas utiliser.", "si": {}},
		],
		"cadeau_deteste": [
			{"t": "Sérieusement ? {dernier_cadeau} ? Tu te moques de moi, {surnom} ?", "geste": "colere"},
			{"t": "Gaston, on m'offre {dernier_cadeau}. Oui. Ne ris pas.", "si": {}},
		],
		"cadeau_refus": [
			{"t": "Garde ça, {surnom}. Tu en auras plus besoin que moi. Moi, je me bats avec des métaphores.", "si": {}},
		],
		"cadeau_refus_canne_peche": [
			{"t": "Me rendre ma canne ? Jamais de la vie ! Elle est à toi maintenant. Va pêcher, {surnom}.", "si": {}},
		],
		"quete_fin": [
			{"t": "Cinq coquillages nacrés ! Ma collection est complète ! Tiens, prends ma vieille boussole, et quelques pièces. Tu les as bien méritées, {surnom} !", "geste": "rire", "humeur": 0.5},
		],
		"quete_manque": [
			{"t": "Tu n'en as que {coquillages}. Il m'en faut {manque} en tout. Cherche sur la plage de ton village, ils brillent au soleil.", "si": {}},
		],
		# ------------------------------------------------------------ souvenirs (complétés par le cerveau)
		"souvenir": [
			{"t": "Si je me souviens de toi ? Mais bien sûr ! Ma mémoire est un coquillage : tout résonne dedans.", "si": {}},
			{"t": "Évidemment. Je n'ai pas tant de visiteurs. En fait, je n'en ai qu'un. Toi.", "si": {}},
		],
		# ------------------------------------------------------------ au revoir
		"au_revoir": [
			{"t": "Bon vent, {surnom} ! Et méfie-toi des lianes de droite.", "si": {"humeur_min": 0.0}, "geste": "salut"},
			{"t": "Déjà ? Bon. Gaston va encore bouder. Reviens vite.", "si": {"affinite_min": 40}},
			{"t": "C'est ça, file. Les coquillages, eux, ne partent jamais.", "si": {"humeur_max": 0.0}},
			{"t": "À la prochaine marée ! Ou celle d'après. Je ne suis pas pressé, j'ai vingt-deux ans d'avance.", "si": {}},
		],
		# ------------------------------------------------------------ interpellations à distance
		"interpelle": [
			{"t": "Ohé, là-bas ! Un visiteur !", "si": {"visites_max": 0}},
			{"t": "Hé ! {surnom} ! Viens par ici !", "si": {"visites_min": 1, "humeur_min": 0.0}},
			{"t": "Tiens, revoilà {surnom}…", "si": {"visites_min": 1, "humeur_max": 0.0}},
			{"t": "Gaston, cache les coquillages, il revient !", "si": {"visites_min": 2}},
			{"t": "Ahoy !", "si": {}},
		],
		"frappe": [
			{"t": "AÏE ! Mais ça va pas ?!", "geste": "colere"},
			{"t": "Gaston, tu as vu ? Il m'a frappé ! Note-le !", "geste": "colere"},
			{"t": "Encore ?! Je m'en souviendrai, crois-moi.", "si": {"fait": "frappe"}, "geste": "colere"},
		],
	},

	# Questions qu'il pose une fois chacune ; la réponse est retenue et colore la suite.
	"questions": [
		{"id": "octave", "si": {"a_rencontre": "octave", "visites_min": 2}, "texte": "Alors… tu l'as vu, Octave. Il parle encore de moi ?",
			"reponses": [
				{"label": "Il dit que ta carte était fausse.", "valeur": "carte", "affinite": 1.0, "humeur": -0.25, "t": "FAUSSE ?! Ma carte était un chef-d'œuvre ! Gaston, rappelle-moi de ne plus jamais parler de ce bonhomme."},
				{"label": "Il a l'air de regretter votre dispute.", "valeur": "regrets", "affinite": 3.0, "humeur": 0.2, "t": "… Il a dit ça ? Vingt-deux ans… Bon. On verra. Peut-être. Un jour. Pas aujourd'hui."},
				{"label": "Je ne me mêle pas de vos histoires.", "valeur": "neutre", "affinite": 0.5, "humeur": 0.0, "t": "Sage. Très sage. Plus sage que nous deux réunis, ce qui n'est pas difficile."},
			]},
		{"id": "origine", "si": {"visites_max": 1}, "texte": "Dis-moi, d'où viens-tu, comme ça ?",
			"reponses": [
				{"label": "Du village, sur l'île d'en face.", "valeur": "village", "affinite": 3.0, "humeur": 0.05, "t": "Le village ! Je vois parfois vos lanternes la nuit. Ça me fait de la compagnie."},
				{"label": "Je suis un aventurier, je viens de partout.", "valeur": "aventurier", "affinite": 5.0, "humeur": 0.15, "t": "Un aventurier ! Comme moi à ton âge. Sauf que moi, je suis resté coincé ici. Ne fais pas pareil."},
				{"label": "Ça ne te regarde pas.", "valeur": "secret", "affinite": -4.0, "humeur": -0.15, "t": "Oh. Pardon, monsieur le mystérieux. Gaston, on a un mystérieux."},
			]},
		{"id": "coquillage_prefere", "si": {"visites_min": 2, "affinite_min": 20}, "texte": "Question importante : tu préfères les coquillages ronds ou pointus ?",
			"reponses": [
				{"label": "Ronds, évidemment.", "valeur": "ronds", "affinite": 4.0, "humeur": 0.2, "t": "Évidemment ! Enfin quelqu'un de sensé sur cette île."},
				{"label": "Pointus.", "valeur": "pointus", "affinite": 1.0, "humeur": -0.05, "t": "Pointus… Bon. Chacun ses défauts. Je ne te juge pas. Un peu quand même."},
				{"label": "Je m'en fiche complètement.", "valeur": "aucun", "affinite": -3.0, "humeur": -0.2, "t": "Tu… tu t'en fiches ? Gaston, bouche-toi les oreilles."},
			]},
		{"id": "gaston", "si": {"visites_min": 3, "affinite_min": 30}, "texte": "Gaston veut savoir : tu le trouves beau ?",
			"reponses": [
				{"label": "Magnifique, le plus beau perroquet du monde.", "valeur": "beau", "affinite": 5.0, "humeur": 0.25, "t": "Gaston : « Rrrah ! Il a bon goût ! » Il t'adore maintenant. C'est rare."},
				{"label": "Il a l'air un peu déplumé.", "valeur": "deplume", "affinite": -2.0, "humeur": -0.1, "t": "Gaston : « RRRAAAH ! » Il ne te parlera plus pendant une semaine. Moi non plus, peut-être."},
			]},
	],
}

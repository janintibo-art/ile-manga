extends RefCounted
## V76 : les petits textes d'Astralys (l'île flottante des Lumens), en dehors des habitants, et ceux
## des compagnons animaux.
##  - AURORES : la Nuit des Aurores (chaque nuit de 22 h à 2 h) : debut (l'annonce, à 22 h),
##    pendant (petites phrases de l'île : messages à l'écran de temps en temps), reactions (ce que
##    disent les Lumens qui regardent : bulles au-dessus des spectateurs), fin (à 2 h) ; « annonce » =
##    « debut » ;
##  - HOLOGUIDE : la visite guidée de l'Hologuide, 15 étapes, dans l'ordre (il la répète) ; chaque
##    étape : {"lieu": spot où il la dit, "t": texte} ;
##  - FONTAINE : les planètes de la fontaine holographique (elle change toutes les minutes) :
##    {"nom", "couleur" (RGB), "t" (le petit panneau qui s'affiche)} ;
##  - METEORES : la pluie d'étoiles filantes : debut, pendant, ramasse (on ramasse un fragment de
##    météorite), fin ;
##  - APESANTEUR : le Jardin des Apesanteurs : entree, sortie, saut (de temps en temps, au premier
##    grand saut), depart (le départ du parcours d'anneaux), anneau (« {n} / {total} »), arrivee
##    (« {temps} »), record (nouveau record : « {temps} »), rate (pas de record : « {temps} »,
##    « {record} ») ;
##  - RAYON : le rayon d'accueil (bouée ↔ portail) : bouee_invite (E sur la bouée), monter (pendant
##    la montée ; alias « monte »), arrivee_haut, portail_invite (E au portail), descendre (alias
##    « descend »), arrivee_bas ;
##  - PONTS : les ponts de lumière qui s'allument quand on s'approche ;
##  - COMPAGNONS : pour brioche (la chatte), biscotte (le rat), truffe (le cochon) : adopte (la
##    narration de l'adoption), content, trouve (Brioche sent un trésor caché à moins de ~40 m ;
##    Biscotte rapporte « {objet} » ; Truffe déterre une truffe), trouve_objet (Truffe déterre
##    « {objet} »), dort, bateau, babil (ce qu'ils disent quand le joueur a mangé un Babillard) ;
##    sardine : babil seulement (ses autres textes sont dans boucan_textes_v75.gd) ;
##  - SIFFLET : le Sifflet des compagnons : titre (le menu), choix (« {nom} vient avec moi »), maison
##    (« {nom} rentre à la maison »), aucun (personne n'est adopté), seul (un seul compagnon).
## Variables : {objet} (l'objet avec son article, ex. « une pièce »), {nom}, {n}, {total}, {temps},
## {record} : à remplacer par le jeu. Rien d'autre.

const AURORES_DEBUT := [
	"Dix heures du soir : là-haut, le ciel s'allume. C'est la Nuit des Aurores !",
	"Des rubans de lumière verte, rose et violette se déroulent au-dessus d'Astralys. La Flèche de Cristal se met à battre comme un cœur.",
	"Un long « ouuuuuh » monte de l'Agora : Vibrato vient d'allumer son thérémine. Les aurores arrivent.",
	"Toutes les lumières de la ville baissent d'un coup. Puis le ciel prend le relais. La Nuit des Aurores commence.",
]

const AURORES := {
	"debut": AURORES_DEBUT,
	"annonce": AURORES_DEBUT,          # (même chose que debut)
	"pendant": [
		"Les aurores ondulent au rythme du thérémine de Vibrato.",
		"Sur l'Agora, Prisme danse : des rubans de lumière tournent autour d'elle et montent rejoindre le ciel.",
		"La Flèche pulse : bleu… violet… rose… Tout là-haut, le Cœur bat au rythme des aurores.",
		"Les dômes du Quartier des Bulles deviennent transparents et prennent les couleurs du ciel.",
		"Les méduses de ciel s'allument une à une et viennent nager dans les aurores.",
		"Les fleurs des Jardins suspendus se tournent toutes vers le ciel et clignotent avec lui.",
		"Une aurore descend si bas qu'elle effleure le sommet de la Flèche. Toute l'Agora fait « oooh ».",
		"Le ciel vire au violet profond. Quelqu'un, sur un banc, applaudit tout doucement.",
		"Une aurore dorée passe au-dessus de l'île. Les Lumens disent qu'elle porte bonheur à ceux qui la voient en premier.",
		"Si tu lèves les bras sur l'Agora, la lumière te suit un peu. Essaie !",
	],
	"reactions": [
		"Oooooh…",
		"Regarde celle-là ! Elle est rose !",
		"Mille ans, et toujours la même émotion.",
		"Vibrato joue mieux que jamais ce soir.",
		"Tu as vu Prisme ? Elle a sauté jusqu'à l'aurore !",
		"Chut… elle va passer au-dessus de nous.",
		"Ô ciel qui danse et qui scintille… euh… qui brille… comme une… Bon. C'est beau.",
		"Blorp ! Clic ! Clic-clic-clic ! J'ai tout ! Non, attends, encore une !",
		"Sur Ondelune, le ciel était gris. Je ne m'en lasserai jamais.",
		"Bzzt. Le Cœur est content. Les compteurs dansent aussi.",
		"(chuchoté) …magnifique…",
		"Par les sept lunes ! Celle-là, elle a la forme d'un biscuit !",
		"Hum hum. Selon le protocole, il est maintenant permis de dire « ooooh ».",
		"Pixel, retourne au lit ! … Bon, cinq minutes.",
		"Elle est violette ! Comme ma soucoupe ! Enfin, ma soucoupe est verte. Mais en violet, elle serait belle.",
		"Pied-Lourd, lève les bras ! Tu vois ? Le ciel te répond !",
	],
	"fin": [
		"Deux heures du matin : les aurores pâlissent, se replient, s'éteignent. La Flèche reprend son battement tranquille.",
		"Le dernier ruban de lumière s'en va vers le nord. Vibrato joue une dernière note, très longue. Bonne nuit, Astralys.",
		"Les aurores s'effacent. Sur l'Agora, les Lumens se lèvent en s'étirant, les yeux encore pleins de couleurs.",
	],
}

const HOLOGUIDE := [
	{"lieu": "agora_holo", "t": "Bip ! Bienvenue à Astralys, la cité de cristal et de lumière ! Je suis l'Hologuide. Veuillez suivre le guide. Veuillez ne pas traverser le guide. Étape un : l'île. Astralys flotte à trois cent quatre-vingts mètres au-dessus de la mer. Veuillez ne pas vous pencher. Si vous vous êtes penché, veuillez vous redresser."},
	{"lieu": "fleche_base", "t": "Étape deux : la Flèche de Cristal. Cent dix mètres de cristal pur. Tout en haut bat le Cœur de la Flèche, qui fait flotter l'île. Ne frappez pas à la porte du Cœur. Il est occupé."},
	{"lieu": "fleche_base", "t": "Étape trois : la Salle du Conseil, au pied de la Flèche. La Doyenne Astrée y siège depuis mille ans. Elle a mille quarante-trois ans. Ne le lui dites pas. Elle le sait."},
	{"lieu": "agora_fontaine", "t": "Étape quatre : l'Agora des Étoiles, la grande place. Ses bancs flottent à quarante centimètres du sol. Asseyez-vous doucement. Les bancs sont sensibles."},
	{"lieu": "agora_fontaine", "t": "Étape cinq : à l'ouest, le Café Nébuleuse. Le cuisinier, Gloubi, a quatre bras. Si on vous serre la main trois fois, c'est normal. Si c'est quatre fois, c'est de l'affection."},
	{"lieu": "agora_fontaine", "t": "Étape six : à l'est, le Bazar galactique de Nébula. On y trouve tout ce qui existe dans la galaxie. Et un canard mécanique. Bip."},
	{"lieu": "musee_accueil", "t": "Étape sept : le Musée des Mondes. L'Archiviste Orbe y expose des objets de toutes les îles d'en bas. La pièce maîtresse est une vieille botte. Veuillez l'admirer. Orbe vous regarde."},
	{"lieu": "musee_accueil", "t": "Étape huit : en face, l'Académie des Sciences. Si vous entendez une explosion, c'est le Professeur Quasar. Si vous n'entendez rien du tout, c'est Murmure, la bibliothécaire."},
	{"lieu": "agora_holo", "t": "Étape neuf : au nord, l'Observatoire, sur son îlot, relié par un pont de lumière. Le pont s'allume quand on s'approche. Il s'éteint quand on a peur. Non. C'est une blague. Bip. Erreur : blague non autorisée."},
	{"lieu": "agora_holo", "t": "Étape dix : à l'est, le Spatioport. Trois aires d'atterrissage, un hangar, une Tour de contrôle. Les soucoupes rouges sont à Comète. Veuillez vous écarter des soucoupes rouges."},
	{"lieu": "agora_fontaine", "t": "Étape onze : la fontaine holographique. Toutes les minutes, une nouvelle planète tourne dans le jet d'eau. Ondelune, Saturne, la Terre… Regardez bien. Oooh. … Bip. Étape préférée du guide. Erreur agréable."},
	{"lieu": "agora_holo", "t": "Étape douze : à l'ouest, les Jardins suspendus, et au bout du pont de lumière, le Jardin des Apesanteurs. On y saute trois fois plus haut. Veuillez retomber. Tout le monde retombe. Doucement."},
	{"lieu": "musee_accueil", "t": "Étape treize : au nord-ouest et au nord-est, le Quartier des Bulles, où vivent les Lumens. Et au nord-est encore, la Serre des Espèces : méduses de ciel, glouglous. Ne tapez pas sur les vitres. Les glouglous répondent."},
	{"lieu": "agora_fontaine", "t": "Étape quatorze : au sud-est, le Portail d'accueil et son rayon, qui relie l'île à la mer. Le gardien Halo vous y fera un discours de quatre minutes. Prévoyez quatre minutes. Prévoyez cinq."},
	{"lieu": "agora_holo", "t": "Étape quinze : la Nuit des Aurores, chaque nuit de vingt-deux heures à deux heures. Prisme danse, Vibrato joue, le ciel s'allume. Fin de la visite. Merci de votre attention. Début de la visite. Bip."},
]

const FONTAINE := [
	{"nom": "Ondelune", "couleur": [0.55, 0.6, 0.95], "t": "ONDELUNE — la planète des Lumens. Nuageuse, douce, sans une seule étoile visible dans son ciel. « Nous l'aimons beaucoup. De loin. »"},
	{"nom": "La Terre", "couleur": [0.3, 0.6, 0.9], "t": "LA TERRE — la planète des Pieds-Lourds. Bleue, pleine de mer, d'îles, de chats et de soupe. Préférée de 26 Lumens sur 26."},
	{"nom": "Saturne", "couleur": [0.9, 0.8, 0.55], "t": "SATURNE — elle porte des anneaux. Comète a demandé si on pouvait faire la course dedans. Réponse du Conseil : non."},
	{"nom": "Jupiter", "couleur": [0.85, 0.6, 0.4], "t": "JUPITER — la plus grosse. Une tempête y tourne depuis des siècles. Quark s'y cache souvent. Ce n'est pas autorisé."},
	{"nom": "Mars", "couleur": [0.85, 0.35, 0.2], "t": "MARS — la planète rouge. Toute en poussière et en collines. Glorb dit que le service de soucoupe y est très lent."},
	{"nom": "Gloop", "couleur": [0.35, 0.85, 0.3], "t": "GLOOP — la planète de Glorb. Verte, molle, tremblotante. Ses habitants rebondissent quand ils sont très contents. Ne pas confondre avec une gelée."},
	{"nom": "Pétillane", "couleur": [0.95, 0.55, 0.85], "t": "PÉTILLANE — une planète où il pleut de la limonade. Les parapluies y sont inutiles. Les pailles, indispensables."},
	{"nom": "Brumelle", "couleur": [0.75, 0.78, 0.82], "t": "BRUMELLE — toujours dans le brouillard. On n'y a jamais rien vu. Peut-être qu'il n'y a rien. Peut-être qu'il y a tout."},
	{"nom": "Cristallune", "couleur": [0.6, 0.85, 1.0], "t": "CRISTALLUNE — toute en cristal. Quand le vent souffle, elle chante. Vibrato la trouve un peu fausse dans les aigus."},
	{"nom": "Ronronne", "couleur": [0.95, 0.65, 0.3], "t": "RONRONNE — une petite planète orange qui vibre doucement. Personne ne sait pourquoi. Nova pense qu'elle ronronne."},
	{"nom": "Neptune", "couleur": [0.25, 0.4, 0.95], "t": "NEPTUNE — bleu profond, très loin, très froid. Les vents y soufflent plus vite qu'une soucoupe de Comète. Elle le conteste."},
	{"nom": "La Lune", "couleur": [0.9, 0.9, 0.88], "t": "LA LUNE — la voisine de la Terre. Elle n'a pas d'air, pas d'eau, mais elle a très bonne mine. Gloubi en a fait des biscuits."},
]

const METEORES := {
	"debut": [
		"Une étoile filante traverse le ciel… puis deux… puis cent ! Une pluie d'étoiles filantes tombe sur Astralys !",
		"Le ciel se met à scintiller de traits de lumière : c'est une pluie d'étoiles filantes ! Fais un vœu. Ou dix.",
		"Zénith crie depuis l'Observatoire : « Une pluie ! Une pluie d'étoiles ! Tout le monde dehors ! »",
	],
	"pendant": [
		"Une étoile filante file juste au-dessus de la Flèche.",
		"Petit « toc » sur les dalles de nacre : un fragment de météorite vient de tomber, tout fumant.",
		"Des traînées d'argent rayent le ciel dans tous les sens.",
		"Quelque part, un Lumen fait un vœu à voix haute. Il souhaite « une gelée de Gloubi ». C'est Gloubi.",
		"Un fragment de météorite est tombé tout près. Il brille encore, comme une braise.",
		"Les enfants lumens courent dans les rues en comptant les étoiles. Ils sont arrivés à mille. Ils recommencent.",
	],
	"ramasse": [
		"Tu ramasses un fragment de météorite. Il est encore tiède et sent l'orage.",
		"Un fragment de météorite ! Noir, lourd, avec des reflets de fer. Il vient de très, très loin.",
		"Tu ramasses le fragment. Il crépite un peu dans ta main, puis se tait, comme s'il était content d'être arrivé.",
	],
	"fin": [
		"La pluie d'étoiles filantes s'arrête. Le ciel redevient calme, un peu essoufflé.",
		"Plus une seule étoile ne tombe. Il en reste des milliers là-haut. Elles attendent leur tour.",
	],
}

const APESANTEUR := {
	"entree": [
		"Tu entres dans le Jardin des Apesanteurs : tu te sens tout léger, comme une bulle de savon.",
		"Ton pied quitte le pont de lumière… et ne retombe pas tout de suite. Bienvenue dans le Jardin des Apesanteurs !",
		"Ici, la gravité ne marche plus qu'à un tiers. Saute ! Tu montes trois fois plus haut, et tu retombes tout doucement.",
	],
	"sortie": [
		"Tu retrouves ton poids normal. Tes pieds sont de nouveau des Pieds-Lourds.",
		"Le Jardin des Apesanteurs est derrière toi. Ton ventre fait un petit « oh » en retrouvant la gravité.",
	],
	"saut": [
		"Hop ! Tu flottes au-dessus des feuilles, au milieu des graines qui tombent vers le haut.",
		"Quel saut ! Une méduse de ciel te regarde passer, un peu vexée qu'on vole mieux qu'elle.",
		"Tu montes, tu montes… et tu redescends en planant comme une plume. C'est merveilleux.",
		"Tu as sauté si haut que tu vois le sommet des Jardins suspendus. Et un glouglou qui dort dessus.",
	],
	"depart": [
		"Le parcours d'anneaux s'allume ! Traverse tous les anneaux lumineux le plus vite possible. Partez !",
		"Trois… deux… un… Les anneaux brillent : à toi de jouer !",
	],
	"anneau": [
		"Anneau {n} / {total} !",
		"Ding ! Anneau {n} / {total}.",
	],
	"arrivee": [
		"Dernier anneau ! Parcours terminé en {temps}.",
		"Tu traverses le dernier anneau en planant. Temps : {temps}.",
	],
	"record": [
		"NOUVEAU RECORD : {temps} ! Les anneaux clignotent de toutes les couleurs pour toi.",
		"Record battu : {temps} ! Quelque part au Spatioport, Comète vient de sentir un frisson.",
	],
	"rate": [
		"Temps : {temps}. Le record est de {record}. Les anneaux t'attendent pour un nouvel essai.",
		"{temps}… Presque ! Le record tient bon : {record}. Encore un saut ?",
	],
}

const RAYON_MONTER := [
	"Le rayon d'accueil te soulève tout doucement. La mer s'éloigne, les nuages approchent…",
	"Tu montes dans le rayon de lumière, léger comme une plume. En bas, ton bateau devient tout petit.",
	"Le rayon te porte vers le ciel. Tes cheveux flottent. Ton ventre fait « ouh ».",
]

const RAYON_DESCENDRE := [
	"Tu redescends tout doucement dans le rayon de lumière. L'île flottante s'éloigne au-dessus de toi.",
	"Le rayon te dépose doucement vers la mer. Les aurores, les dômes, la Flèche… tout devient une petite lumière dans le ciel.",
]

const RAYON := {
	"bouee_invite": [
		"La bouée d'accueil brille doucement. Un faisceau de lumière monte tout droit vers le ciel. [E] : monter à Astralys.",
	],
	"monter": RAYON_MONTER,
	"monte": RAYON_MONTER,               # (même chose que monter)
	"arrivee_haut": [
		"Tu te poses en douceur devant le Portail d'accueil d'Astralys. Quelqu'un, tout près, s'éclaircit la gorge pour un discours.",
		"Te voilà sur Astralys, à trois cent quatre-vingts mètres au-dessus de la mer. Bienvenue chez les Lumens !",
	],
	"portail_invite": [
		"Le rayon d'accueil descend jusqu'à la bouée, sur la mer, où ton bateau t'attend. [E] : redescendre.",
	],
	"descendre": RAYON_DESCENDRE,
	"descend": RAYON_DESCENDRE,           # (même chose que descendre)
	"arrivee_bas": [
		"Tes pieds touchent la bouée d'accueil. Ton bateau t'attend, bien sage.",
		"Te revoilà sur la mer. Là-haut, l'île flottante brille comme une étoile posée sur un nuage.",
	],
}

const PONTS := [
	"Le pont de lumière s'allume sous tes pieds, dalle après dalle.",
	"Un pont de lumière se déroule devant toi jusqu'à l'îlot flottant. Ne regarde pas en bas. Ou regarde : c'est magnifique.",
	"Le pont de lumière bourdonne doucement à ton passage.",
]

const COMPAGNONS := {
	"brioche": {
		"adopte": [
			"Brioche s'approche enfin. Elle renifle ta main, très longtemps, très dignement. Puis elle se frotte contre ta jambe, une seule fois. C'est décidé : elle vient avec toi.",
			"La chatte rousse et blanche te regarde droit dans les yeux, cligne lentement… et saute du toit pour se poser à tes pieds. Brioche t'a adopté. (C'est elle qui choisit. C'est toujours elle qui choisit.)",
		],
		"content": [
			"Brioche ronronne comme un petit moteur.",
			"Brioche se frotte contre tes jambes, la queue dressée en point d'interrogation.",
			"Brioche cligne lentement des yeux en te regardant. Chez les chats, c'est un bisou.",
			"Brioche s'assoit, très droite, enroule sa queue autour de ses pattes et contemple le monde, satisfaite.",
			"Brioche bondit sur un papillon… le rate… et fait semblant de n'avoir jamais essayé.",
			"Brioche fait sa toilette avec le plus grand sérieux. Une oreille, puis l'autre. Puis la patte. Puis encore l'oreille.",
			"Brioche te donne un petit coup de tête dans la main. Elle veut une caresse. Mais elle ne le demandera pas deux fois.",
			"Brioche s'étire au soleil, tout en longueur. Une chatte qui s'étire, c'est trente centimètres de bonheur en plus.",
			"Brioche poursuit un papillon jusqu'en haut d'un muret, puis te regarde d'en haut comme une reine.",
		],
		"trouve": [
			"Brioche s'arrête net. Les oreilles en avant, elle fixe un point au loin et miaule doucement. Il y a un trésor par là !",
			"Brioche se fige, une patte levée, le regard tourné vers quelque chose que toi seul ne vois pas encore. Miaou ? Un trésor est caché dans cette direction.",
			"Brioche miaule, se retourne vers toi, puis regarde au loin. Encore. Puis encore. Elle a flairé un trésor.",
			"La queue de Brioche se met à frétiller. Elle fixe un endroit, très concentrée, et lâche un petit « mrrraou ». Quelque chose est enfoui par là.",
			"Brioche s'arrête, renifle l'air, puis te lance un regard qui veut dire : « Tu ne sens donc RIEN ? Là-bas. Un trésor. »",
		],
		"dort": [
			"Brioche s'est roulée en boule à tes pieds, le nez dans sa queue. Elle ronronne en dormant.",
			"Brioche dort, une patte sur les yeux. Ne la réveille pas. Elle ne te le pardonnerait pas.",
		],
		"bateau": [
			"Brioche monte dans le bateau d'un bond élégant et s'installe à la proue, comme une figure de proue en fourrure.",
			"Brioche déteste l'eau. Mais elle adore les bateaux. Elle s'installe sur le banc le plus sec et surveille les poissons.",
		],
		"babil": [
			"Ah. Tu me comprends, maintenant. Bien. Alors écoute : je t'ai choisi. Ne me déçois pas.",
			"Ce papillon ? Je ne le chassais pas. Je l'inspectais. Nuance.",
			"Là-bas. Oui, là-bas. Il y a un trésor. Je le sens depuis dix minutes. Tu en as mis, du temps.",
			"Tu sens le poisson. C'est un compliment. Le plus grand.",
			"Rosalie me donnait les têtes de sardines. Je les mangeais devant tout le monde, très lentement. Pour l'élégance.",
			"Je ne suis pas ta chatte. Tu es mon humain. C'est très différent, et c'est beaucoup mieux pour toi.",
			"Le chien ? Il est gentil. Bête, mais gentil. Il remue la queue pour tout. Moi, je la remue seulement quand je réfléchis.",
			"Caresse-moi. Non, pas là. Là. … Voilà. Tu as le droit de continuer.",
			"La pelote de laine rouge… Je ne l'ai pas oubliée. Je ne joue plus avec, bien sûr. Mais si tu l'as encore, je pourrais la surveiller.",
			"Les toits de Port-Azur étaient à moi. Tous. Maintenant, le monde entier est à moi. Merci de me le montrer.",
			"Je ronronne ? Non. C'est ton imagination. … Bon. Un peu.",
			"Je t'ai apporté une souris. Imaginaire. C'est l'intention qui compte.",
			"Quand tu dors, je veille sur toi. Les yeux fermés. C'est une technique très avancée.",
			"Ces Lumens, là-haut, n'ont jamais vu de chat. Ils me regardent comme si j'étais une reine. Ils ont raison.",
			"Miaou. … Pardon. C'était pour les autres. Avec toi, je n'ai plus besoin de faire semblant.",
		],
	},
	"biscotte": {
		"adopte": [
			"Biscotte sort de son trou, renifle le fromage, renifle ta main… et grimpe d'un trait jusqu'à ton épaule. Il s'installe dans ton cou, les moustaches qui chatouillent. Tu as un rat !",
			"Le petit rat blanc et brun te regarde, croque le dernier bout de fromage, puis court le long de ton bras et se pose sur ton épaule comme sur un mât. Biscotte a choisi son navire : toi.",
		],
		"content": [
			"Biscotte se frotte les moustaches avec ses petites pattes, très content de lui.",
			"Biscotte fait un petit bond sur ton épaule et te mordille l'oreille. Tout doucement. C'est de l'affection de rat.",
			"Biscotte grignote un bout de quelque chose qu'il a trouvé on ne sait où. Il a l'air ravi.",
			"Biscotte se met debout sur tes épaules, le nez en l'air, comme une vigie en haut du mât.",
			"Biscotte se roule en boule dans ton col et pousse un tout petit soupir de bonheur.",
			"Biscotte fait le tour de ta tête en courant, s'arrête, puis recommence dans l'autre sens.",
			"Biscotte te chatouille le cou avec ses moustaches. Il sait que ça te fait rire. Il recommence.",
			"Biscotte couine trois fois. Il raconte quelque chose. C'est sûrement très drôle.",
		],
		"trouve": [
			"Biscotte saute de ton épaule, file dans un trou… et revient quelques secondes plus tard avec {objet} entre les dents. Il te le pose dans la main, très fier.",
			"Biscotte disparaît dans une fente du mur. Tu entends un petit remue-ménage. Il ressort avec {objet}, les moustaches pleines de poussière.",
			"Biscotte file sous une planche, ressort en marche arrière et te rapporte {objet}. « Pour toi », disent ses petits yeux noirs.",
			"Biscotte revient en trottinant, {objet} dans la gueule. Il le dépose à tes pieds et se dresse sur ses pattes arrière, en attendant les compliments.",
			"Un petit couinement : Biscotte a trouvé {objet} au fond d'une cachette. Les rats savent toujours où sont les trésors. C'est leur métier.",
		],
		"dort": [
			"Biscotte s'est endormi dans ton col, roulé en boule. Il ronfle. Tout petit.",
			"Biscotte dort sur ton épaule, la queue enroulée autour de ton cou comme une écharpe minuscule.",
		],
		"bateau": [
			"Biscotte saute dans le bateau et file droit en haut du mât. Un rat de navire n'oublie jamais.",
			"Biscotte inspecte le bateau de la proue à la poupe. Pas de fromage. Il revient sur ton épaule, déçu mais fidèle.",
		],
		"babil": [
			"Moussaillon ! Tu me comprends ? Alors écoute : ton épaule, c'est le meilleur poste de vigie de tout l'archipel.",
			"Mange-Clous m'a poursuivi avec sa louche pendant trois ans. Trois ans ! Je lui ai mangé un fromage. Un seul. Bon, douze.",
			"Petit-Pierre me cachait des croûtes de pain dans son hamac. C'est mon premier ami. Toi, tu es mon capitaine.",
			"Tu veux un trésor ? J'en connais un, derrière ce mur. Il est tout petit. Comme moi. Les petits trésors sont les meilleurs.",
			"Le fromage affiné, c'est le parfum de l'aventure. Les humains disent que ça sent les pieds. Les humains n'y connaissent rien.",
			"Je ne suis pas un « sale rat ». Je suis un rat de navire. Je me lave trois fois par jour. Les pirates, eux…",
			"Sur ton épaule, je vois tout. Le monde est grand, vu d'en haut. Avant, je le voyais depuis la cale. Il était surtout fait de tonneaux.",
			"Si tu tombes, je tombe. Si tu cours, je m'accroche. Si tu manges, je regarde. Très fort.",
			"Un chat ? Où ça ? Ah, la nôtre. Brioche. Elle me regarde comme un goûter. Mais elle est polie : elle ne me mange pas. Pas encore.",
			"Je t'ai rapporté une pièce. Ne demande pas où je l'ai trouvée. Un rat ne révèle jamais ses sources.",
			"Couic ! Ça veut dire « merci ». Couic-couic ! Ça veut dire « encore du fromage, merci ».",
			"Les Lumens, là-haut, n'avaient jamais vu un rat. Ils m'ont appelé « petit nuage à moustaches ». J'aime bien.",
			"Quand tu dors, je garde ton sac. Personne n'y touche. Sauf moi. Un peu. Pour vérifier.",
			"La mer, c'est grand, c'est mouillé, et ça ne sent pas le fromage. Mais avec toi, j'aime bien quand même.",
		],
	},
	"truffe": {
		"adopte": [
			"Truffe accourt en faisant tinter sa clochette, glisse dans la boue, se relève, et vient poser son groin tout rond contre ta main. Grouik ! Il ne te quittera plus.",
			"Le petit cochon rose et noir entend la clochette, dresse les oreilles, et fonce vers toi en trottinant, la queue en tire-bouchon. Il frotte son nez contre tes chaussures. Truffe t'a adopté.",
		],
		"content": [
			"Truffe grogne de bonheur, le groin en l'air.",
			"Truffe se roule dans l'herbe, les quatre pattes en l'air, en couinant de joie.",
			"Truffe trottine à côté de toi, sa clochette fait « ding-ding » à chaque pas.",
			"Truffe renifle tout : tes chaussures, une fleur, un caillou, encore tes chaussures. Tout est passionnant.",
			"Truffe pousse ta main avec son groin tout mouillé. Il réclame une gratouille derrière les oreilles.",
			"Truffe fait des petits bonds sur place, comme un ressort rose. Il est très, très content.",
			"Truffe a trouvé une flaque. Truffe est dans la flaque. Truffe est heureux.",
			"Truffe grogne doucement en te regardant. C'est une chanson. Une chanson de cochon. Elle parle de pommes.",
		],
		"trouve": [
			"Truffe s'arrête, renifle, renifle encore… et se met à creuser frénétiquement avec son groin. Il déterre une belle truffe noire et te la tend, tout fier !",
			"Le groin de Truffe frémit. Il fonce sous un arbre, gratte, grogne… Une truffe ! Il la pose à tes pieds avec un « grouik » triomphant.",
			"Truffe a senti quelque chose sous la terre. Trois coups de groin, une motte qui vole… et voilà une truffe noire, parfumée comme la forêt après la pluie.",
			"Truffe tourne en rond, le nez au sol, puis plonge dans la mousse. Il ressort couvert de terre, une truffe dans la bouche. Il porte bien son nom.",
		],
		"trouve_objet": [
			"Truffe creuse, creuse, creuse… et ce n'est pas une truffe ! Il a déterré {objet}. Il te le rapporte, un peu étonné lui-même.",
			"Grouik ! Le groin d'or de Truffe a encore frappé : il sort de terre {objet}, couvert de boue, et le pose à tes pieds.",
			"Truffe a déterré quelque chose qui brille : {objet} ! Il le pousse vers toi avec son nez, la queue en tire-bouchon qui frétille.",
		],
		"dort": [
			"Truffe dort sur le flanc, les pattes qui bougent : il rêve qu'il court après une pomme.",
			"Truffe s'est endormi contre toi. Il ronfle comme un tout petit tracteur.",
		],
		"bateau": [
			"Truffe saute dans le bateau, glisse, roule, se relève, et s'installe au fond avec dignité. Enfin, avec une dignité de cochon.",
			"Truffe regarde la mer par-dessus le bord. Il renifle. La mer ne sent pas les truffes. Il est déçu, mais il reste.",
		],
		"babil": [
			"Grouik ! Tu me comprends ? Alors je te dis tout : j'ai faim. Toujours. C'est mon métier.",
			"Sous tes pieds, il y a des trésors. Des truffes, des racines, des glands, une vieille cuillère. Le monde entier sent bon, par en dessous.",
			"Père Gaubert disait que j'étais un bon à rien. Puis je lui ai trouvé une truffe grosse comme son poing. Il a pleuré. Germaine a fait une omelette.",
			"La boue, c'est comme un bain, mais en mieux. Les humains ne comprennent pas. Les humains ont des baignoires. Les pauvres.",
			"Ma clochette, c'est pour qu'on me retrouve. Moi, je ne me perds jamais. Je sais toujours où est la nourriture. Et la nourriture, c'est là où tu es.",
			"Les navets de Montjoie se sauvaient en courant. Je les suivais. Ce n'était pas pour les manger. Enfin, un peu.",
			"Tu sens la pomme. Tu sens le pain. Tu sens le gentil. C'est mon odeur préférée.",
			"Le chien court après les monstres. La chatte cherche les trésors. Le rat rapporte des pièces. Moi, je cherche les truffes. Mais je les partage. Presque toutes.",
			"Grouik grouik ! Ça veut dire « merci ». Grouik grouik grouik ! Ça veut dire « encore une gratouille ».",
			"Je ne suis pas gros. Je suis rond. Rond comme une pomme. C'est très différent.",
			"Là-haut, sur l'île qui flotte, la terre ne sent rien. Ni truffe, ni racine. Juste un peu le cristal. Ils ont besoin de cochons, je crois.",
			"Si un jour tu as faim, demande-moi. Je trouverai. Je trouve toujours. C'est ma promesse de cochon.",
			"J'ai trouvé une truffe ! Ah non, c'est une pierre. Ah si, c'est une truffe ! Ah non. Bon. Je continue.",
		],
	},
	"sardine": {
		"babil": [
			"Tu as d'autres amis, maintenant ! Une chatte, un rat, un cochon ! Je les aime tous ! Surtout le cochon : il sent la saucisse !",
			"Le sifflet ! Quand tu siffles, je cours ! Même quand ce n'est pas pour moi ! Surtout quand ce n'est pas pour moi !",
			"La chatte me regarde de haut. Je lui ai rapporté une pièce pour lui faire plaisir. Elle l'a poussée sous un meuble. C'est un jeu ? J'adore ce jeu !",
			"Je mords les robots. Je mords les monstres. Je ne mords jamais les amis. Tu es mon ami. Je te lèche. C'est le contraire de mordre.",
			"Là-haut, sur l'île qui flotte, il n'y a pas de robots ! Il n'y a rien à mordre ! J'ai mordu un banc. Il flottait. Il n'a rien dit.",
			"Quand tu me laisses à la maison, je t'attends devant la porte. Toute la journée. Je ne bouge pas. Bon, je fais pipi. Mais je reviens.",
			"Tornade me manque un peu. Mais tu es là. Et le monde est grand. Et il sent bon. Et tu es là.",
			"Le rat dort sur ton épaule. Moi, je suis trop gros pour ton épaule. J'ai essayé. Tu es tombé. Pardon.",
			"Wouf ! Je sens une pièce ! Je la rapporte ! Je l'ai ! Elle est à toi ! Je suis un bon chien ? Je suis un bon chien.",
			"Le cochon trouve des truffes. Moi, je trouve des pièces. On fait une équipe ! Une équipe qui sent bon !",
			"Le bateau ! On va sur le bateau ! J'adore le bateau ! Les vagues ! Le vent ! Les mouettes ! À MOI, les mouettes !",
			"Tu sais ce que je préfère dans la vie ? Toi. Et les os. Mais toi d'abord. Enfin, souvent.",
		],
	},
}

const SIFFLET := {
	"titre": "Qui vient avec moi ?",
	"choix": "{nom} vient avec moi",
	"maison": "{nom} rentre à la maison et t'attendra.",
	"vient": [
		"Tu siffles. {nom} arrive en courant !",
		"Un coup de sifflet, et voilà {nom} à tes côtés.",
		"Tu siffles deux notes. {nom} dresse la tête et accourt.",
	],
	"aucun": "Tu siffles… mais aucun compagnon ne t'a encore adopté. Un jour, peut-être, quelqu'un répondra.",
	"seul": "Tu siffles. {nom} te regarde comme pour dire : « Mais je suis déjà là. »",
	"personne": "Personne ne viendra : tous tes compagnons restent à la maison.",
}

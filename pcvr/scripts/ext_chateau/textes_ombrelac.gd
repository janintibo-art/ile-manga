extends RefCounted
## Extension « Le Château d'Ombrelac » (v15) : les textes des objets de l'Académie : les livres des
## rayonnages (la Bibliothèque, la Salle des Astres, la Salle Commune, l'Observatoire, le cabinet des
## Sortilèges, le Bureau du Recteur), les leçons des tableaux et des maîtres, les cartes du ciel, les
## anciens Recteurs des portraits, les reliques, le grimoire, la sphère de cristal, ce qu'on voit dans
## les lunettes. Tout est d'ici : le lac d'Ombre, la brume, la Couronne, les fondateurs.

## Les livres de la Bibliothèque : [titre, ce qu'on y lit]
const BIBLIOTHEQUE := [
	["Histoire de l'Académie d'Ombrelac, tome I", "« Il y a quatre cents ans, quatre voyageurs posèrent leurs sacs sur ce roc : Mélisende d'Ombre, Aubin le Polisseur, Gaucelin Fer-de-Lance et Ermengarde la Scribe. Ils cherchaient un endroit où l'on entend ses propres pensées. Ils le trouvèrent, et bâtirent une école autour. »"],
	["Histoire de l'Académie d'Ombrelac, tome II", "« La première année, l'Académie comptait trois élèves, une chèvre et un toit qui fuyait. La chèvre fut nommée intendante d'honneur. Le toit fut réparé la sixième année. »"],
	["Le Lac d'Ombre, ses eaux et ses mystères", "« Le lac est profond de seize mètres en son milieu. Les pêcheurs disent qu'il est plus profond la nuit. Les savants disent que c'est impossible. Les pêcheurs ne discutent pas avec les savants : ils pêchent. »"],
	["De la brume, et de ceux qui la lisent", "« La brume d'Ombrelac n'est pas une brume ordinaire : elle garde ce qu'on lui confie. Ermengarde la Scribe écrivait à l'encre de brume ; ses pages ne se lisent que les jours de brouillard. Pensez-y avant de lui confier un secret. »"],
	["La Couronne des Fondateurs", "« Les quatre fondateurs forgèrent la Couronne ensemble, chacun y laissant un peu de son savoir. Elle tourne depuis ce jour dans la Grosse Tour. Tant qu'elle tourne, l'Académie apprend. Il est fortement déconseillé de vérifier ce qui se passe quand elle s'arrête. »"],
	["Petit traité de la Nacelle", "« La Nacelle de la Tour de l'Astrolabe monte de cinquante-quatre mètres en quatorze secondes. Elle n'est jamais tombée. Elle a seulement, une fois, refusé de partir, un jour où un élève avait le hoquet. »"],
	["Les Grenouilles du Cloître, étude", "« La grenouille de la fontaine du cloître est observée depuis cent douze ans. Elle a toujours le même air entendu. Il s'agit soit d'une très vieille grenouille, soit d'une longue lignée de grenouilles très bien renseignées. »"],
	["Règlement de l'Académie (édition révisée)", "« Article 1 : le silence de la Bibliothèque est sacré. Article 2 : le sommeil des élèves aussi. Article 3 : le jardin de Firmin encore plus. Article 14 : il est interdit de changer un camarade en grenouille, même pour rire, même s'il a commencé. »"],
	["Mémoires d'un portier, par Gaspard Herse l'Ancien", "« En quarante ans à la porte, j'ai vu passer des princes, des marchands, des sorcières et un ours. L'ours fut le plus poli. Il s'essuya les pattes. »"],
	["Botanique des falaises", "« Sur les falaises d'Ombrelac pousse la fougère-qui-écoute : elle se tourne vers ceux qui parlent. Firmin Buis en fait pousser dans les serres. Il dit qu'elle aime surtout les histoires qui finissent bien. »"],
	["Recueil de chansons d'élèves", "« Dans la cour d'Ombrelac / On court jusqu'au lac / Le portier fait mine / De rien voir, la mine / Sévère et l'œil qui rit / Tout le monde le dit… » (La suite est raturée. Quelqu'un a écrit dans la marge : « Ombeline, rends-nous la page. »)"],
	["L'Horloge et ses rouages, par Maître Rouage", "« Une horloge, c'est un cœur qu'on a appris à compter. Celle d'Ombrelac bat depuis trois siècles. Elle avance parfois d'une minute. Je n'ai pas d'explication scientifique. J'en ai une autre, mais elle concerne les mensonges dans la cour. »"],
	["Les Quatre Maisons d'autrefois", "« Autrefois, l'Académie avait quatre maisons : l'Aube, le Zénith, le Crépuscule et la Minuit. Le Zénith partit fonder une école au soleil. La Minuit dort toujours quelque part dans les caves, dit-on. Personne n'est allé vérifier. »"],
	["De la cuisine des élixirs, par Ysaure Alambic", "« Chapitre premier : la hotte. Chapitre deux : encore la hotte. Chapitre trois : maintenant que votre hotte fonctionne, nous pouvons parler d'élixirs. »"],
	["Atlas des îles de l'archipel", "« On compte dans l'archipel des îles de feu et des îles de glace, des îles qui flottent et des îles qui chantent. Ombrelac est la plus silencieuse. Ce n'est pas un défaut : c'est sa spécialité. »"],
	["Contes de la brume", "« Il était une fois une élève qui voulait savoir ce qu'il y a au fond du lac. Elle demanda à la brume. La brume lui répondit : « Une question. » Depuis, l'élève est devenue Rectrice, et elle n'a toujours pas fini d'y réfléchir. »"],
	["Manuel de politesse envers les livres", "« Un livre se prend par le dos, jamais par la coiffe. On ne corne pas ses pages. On ne lui dit pas qu'il est trop long. Les livres de la galerie entendent tout, et certains sont rancuniers. »"],
	["Registre des étoiles nommées", "« Étoile nommée par Maître Fauconnier, troisième de la liste : Gertrude. Motif : « Elle me fait penser à quelqu'un. » Aucune autre explication n'a été fournie. »"],
	["Vie de Mélisende d'Ombre", "« La fondatrice ne levait jamais la voix. Quand elle voulait le silence, elle levait sa baguette, dont le bout s'allumait comme une étoile. On dit que les élèves se taisaient surtout pour voir de quelle couleur elle allait briller. »"],
	["Les Fantômes de l'Académie (il n'y en a pas)", "« L'Académie d'Ombrelac n'a pas de fantôme. Les bruits dans la galerie la nuit sont des livres qui se rangent. Les pas dans l'escalier de l'horloge sont ceux de Maître Rouage. Le chant dans la Grande Salle est… nous y travaillons. »"],
]

## Les livres d'astronomie (la Salle des Astres, l'Observatoire)
const ASTRES := [
	["Le Ciel d'Ombrelac, cartes et saisons", "« Au printemps, le Héron monte au-dessus de la Tour de l'Horloge. En été, la Couronne Boréale se pose sur la Grosse Tour, comme si elle venait rendre visite à sa cousine. »"],
	["Des planètes et de leurs anneaux", "« Avec la Grande Lunette, on voit les anneaux de la planète Saturnelle. Ils tournent dans le même sens que ceux du Grand Astrolabe. Les fondateurs n'ont jamais dit si c'était une coïncidence. »"],
	["Manuel d'usage de l'astrolabe", "« Pour trouver l'heure de nuit, visez l'étoile du Nord, faites tourner l'alidade, lisez le limbe. Pour trouver l'heure de jour, demandez à Maître Rouage. C'est plus rapide. »"],
	["Les étoiles filantes, où elles vont", "« Une étoile filante ne tombe pas : elle va quelque part. Les élèves de l'Aube pensent qu'elles tombent dans le lac. Ceux du Crépuscule pensent qu'elles tombent dans le lac de l'Aube. »"],
	["Le pari du miel", "Un carnet glissé entre deux livres : « Pari entre O. Fauconnier et Maître Rouage. Question : qui donne l'heure exacte, les étoiles ou l'horloge ? Enjeu : un pot de miel. Année 1 : égalité. Année 11 : égalité. Le miel attend toujours. »"],
	["Tables des éclipses", "Des colonnes de chiffres, à perte de vue. Dans la marge, une petite écriture : « La prochaine, je la regarde avec Nour. Elle a déjà réservé la meilleure place. »"],
]

## Les livres de la Salle Commune (ceux des élèves)
const COMMUNE := [
	["Les Aventures de la Capitaine Brumaille, tome 3", "« La Capitaine Brumaille sauta du mât, attrapa la corde, rata la corde, tomba dans le lac, et déclara que c'était exactement ce qu'elle avait prévu. » Quelqu'un a souligné cette phrase trois fois."],
	["Cent problèmes d'échecs", "Problème 47 : « Les blancs jouent et gagnent en trois coups. » Dessous, au crayon : « Anatole a trouvé en quatre. Il dit que c'est mieux, parce que c'est plus long. »"],
	["Recueil de devinettes", "« Je tourne sans bouger, je sonne sans parler, je compte sans savoir compter. Qui suis-je ? » (Réponse à l'envers, en bas de la page : « L'horloge. Ou Barnabé pendant un contrôle. »)"],
	["Journal de la Maison du Crépuscule", "« Points de la semaine : Crépuscule, 42. Aube, 41. Note de la préfète : l'Aube a demandé un recomptage. Le recomptage a donné 43 à 41. Personne ne sait d'où viennent les deux points. »"],
	["Le Petit Livre des Recettes de Mère Fournil", "« Tarte aux myrtilles des falaises : de la pâte, des myrtilles, du sucre, et surtout ne pas laisser Tobie seul avec la tarte. »"],
]

## Les grimoires du cabinet des Sortilèges
const SORTILEGES := [
	["Grimoire des lumières", "« Pour allumer une bougie d'un regard, il faut d'abord apprendre à regarder une bougie. Cela prend trois semaines. Allumer la bougie prend ensuite une seconde. »"],
	["Des sorts de rangement", "« Le sort de rangement est le plus utile de tous et le moins pratiqué. Les livres de la galerie l'ont appris tout seuls, à force de voir Dame Reliure le lancer. »"],
	["Petit traité de lévitation", "« Commencez par une plume. Puis une pomme. Ne commencez jamais par un camarade. »"],
	["Les sortilèges interdits (version pour élèves)", "Toutes les pages sont blanches, sauf la dernière : « Bien essayé. — D. Sortelame »"],
]

## Les registres du Bureau du Recteur
const BUREAU := [
	["Registre des Recteurs", "Quatorze noms, d'une écriture qui change à chaque page. Le dernier : « Aldegonde Vespérine. Promesse : garder la flamme, sans jamais l'enfermer. »"],
	["Livre des admissions", "« Admis cette année : huit élèves. Remarques : l'un d'eux a demandé si la Couronne pouvait se porter. Réponse : non. Il a demandé pourquoi. Réponse : parce que. Il a dit que ce n'était pas une réponse. Il a raison. »"],
	["Correspondance avec les îles", "Une lettre : « Madame la Rectrice, notre fils nous écrit que l'on mange des tartes tous les jours. Pourriez-vous confirmer ? » En dessous, la réponse au brouillon : « Presque tous. »"],
	["Inventaire des reliques", "« L'épée de Gaucelin. La coupe des fondateurs. Le cristal de la source. Le premier grimoire. La baguette de Mélisende. L'astrolabe de poche d'Aubin. La Couronne. Tout est là. La chèvre n'est plus là, mais elle n'était pas une relique. »"],
]

## Les livres de l'Observatoire (en plus de ceux d'astronomie)
const OBSERVATOIRE := ASTRES

## Les tableaux des salles de cours : ce qui y est écrit à la craie
const TABLEAUX := {
	"tableau": [
		"Au tableau, des orbites tracées à la craie : « Leçon : pourquoi les planètes ne se cognent pas. Réponse courte : elles font attention. Réponse longue : voir page 112. »",
		"Au tableau : « Devoir pour jeudi : repérer le Héron, la Couronne Boréale et l'étoile du Nord. Ceux qui trouvent Gertrude ont un point de plus. »",
		"Au tableau, une spirale et une flèche : « Ceci n'est pas un escargot. C'est une galaxie. — O. F. » Quelqu'un a ajouté des antennes.",
	],
	"tableau_amphi": [
		"Au grand tableau, une démonstration parfaite : « Théorème d'Équerre : la somme des angles d'un triangle fait toujours deux angles droits, même un mardi. »",
		"Au tableau : « Exercice : la Tour de l'Horloge mesure quarante mètres, son ombre en mesure trente. Combien mesure l'ombre de Maître Équerre ? » Personne n'a osé répondre.",
		"Au tableau, un cercle si rond qu'on le dirait tracé au compas. Il a été tracé à main levée. Dessous : « Rondeur : 99 %. Je recommencerai demain. — É. »",
	],
}

## Les cartes du ciel accrochées aux murs
const CARTES_CIEL := [
	"Une carte du ciel d'été : le Héron, la Lyre, la Couronne Boréale. Une petite étoile est entourée à l'encre : « Gertrude ».",
	"La carte des étoiles d'hiver, piquée de trous d'épingle : chaque trou laisse passer un peu de lumière. On dirait le vrai ciel.",
	"Une carte des constellations du sud, que l'on ne voit jamais d'Ombrelac. Nour y a ajouté, au crayon : « Vues de chez moi. Toutes. »",
	"Le chemin de la lune, mois par mois, en fines courbes d'argent. Au bas de la carte : « D'après les relevés d'Aubin le Polisseur. »",
	"Une carte des étoiles filantes de l'an passé. Une flèche pointe vers le lac : « Tombée ici ? » Une autre écriture : « Non. »",
]

## Ce qu'enseignent les maîtres pendant le cours (quand on s'assied dans la salle) : [matière, lignes]
const LECONS := {
	"astres": ["Maître Fauconnier : « Le ciel ne bouge pas : c'est nous qui tournons. Retenez bien cela, et pensez-y la prochaine fois que vous aurez le tournis. »",
		"Maître Fauconnier : « Voici l'étoile du Nord. Elle ne bouge jamais. C'est la plus fidèle des étoiles. Gertrude, elle, est la plus capricieuse. »",
		"Maître Fauconnier : « Un astronome a besoin de trois choses : de la patience, une bonne lunette et un manteau chaud. Surtout le manteau. »",
		"Maître Fauconnier : « Les anneaux du Grand Astrolabe suivent le ciel. Si vous les faites tourner plus vite, le ciel, lui, ne s'en aperçoit pas. Heureusement. »",
		"Maître Fauconnier : « Pour demain : regardez le ciel. Pas longtemps. Juste assez pour qu'il vous regarde aussi. »"],
	"amphi": ["Maître Équerre : « Un point n'a pas de taille. Une droite n'a pas de fin. Un élève n'a pas d'excuse. Commençons. »",
		"Maître Équerre : « Le cercle est la forme la plus parfaite. C'est pourquoi la Couronne est ronde, et pourquoi votre devoir ne l'est pas. »",
		"Maître Équerre : « Le plus court chemin d'un point à un autre est la ligne droite. Sauf dans les couloirs de l'Académie, où c'est l'escalier de service. »",
		"Maître Équerre : « Le nombre pi ne se termine jamais. Comme mes cours, d'après certains. Je les ai entendus, Anatole. »",
		"Maître Équerre : « Pour la prochaine fois : mesurez la hauteur de la Tour de l'Horloge avec un bâton et votre ombre. Le bâton est fourni. L'ombre aussi. »"],
}

## Les anciens Recteurs (les portraits du Bureau, dans l'ordre de leurs numéros) : [nom, ce qu'on en dit]
const RECTEURS := [
	["Mélisende d'Ombre, fondatrice et première Rectrice", "Le regard qui a choisi ce roc. Sur le cadre : « Ici, on entend mieux ses propres pensées. »"],
	["Ermengarde la Scribe", "Elle tint les registres de l'Académie pendant cinquante ans, à l'encre de brume. Plusieurs sont encore illisibles. Les jours de soleil."],
	["Gaucelin Fer-de-Lance", "Premier maître d'armes, Recteur malgré lui : il avait perdu une partie d'échecs contre Ermengarde."],
	["Aubin le Polisseur", "Il polit la Grande Lunette avec du sable du lac, grain par grain, pendant onze hivers."],
	["Hyacinthe Lamberge", "Elle fit bâtir la Bibliothèque et sa galerie. Sa devise : « Un livre de plus, une sottise de moins. »"],
	["Bertrand des Falaises", "Il planta les premières serres. On lui doit les myrtilles des tartes de Mère Fournil."],
	["Oriane Clairvent", "Elle dompta la Nacelle, qui refusait de monter les jours de vent. Elle lui parla longtemps. Personne ne sait ce qu'elle lui a dit."],
	["Anselme Tourneroue", "Il construisit la Tour de l'Horloge. Il arrivait en retard à tout, sauf à l'heure de sonner la cloche."],
	["Pétronille Ancolie", "La seule Rectrice qui ait réussi l'élixir d'invisibilité. Son portrait a été peint de mémoire."],
	["Grégoire le Bref", "Recteur pendant trois jours. Il partit faire le tour de l'archipel « pour une semaine ». On l'attend toujours, avec affection."],
	["Sidoine Mortelune", "Il créa le cours de sortilèges, et l'interdiction de changer ses camarades en grenouilles (article 14)."],
	["Aurore Pléiade", "Elle nomma quarante étoiles. Maître Fauconnier, qui fut son élève, n'en a nommé qu'une : Gertrude."],
	["Léonce Brunebois", "Il fit agrandir la Grande Salle parce que, disait-il, « on pense mieux le ventre plein ». Il avait raison, sauf en géométrie."],
	["Clémence Vespérine", "La grand-mère de l'actuelle Rectrice. Elle aussi, on la voyait rarement sourire. Elle aussi, on dit qu'elle souriait quand personne ne regardait."],
]

## Les reliques (les vitrines de la Salle des Reliques, dans l'ordre de leurs numéros)
const RELIQUES := [
	["L'épée de Gaucelin Fer-de-Lance", "La lame du premier maître d'armes. Elle n'a jamais servi qu'à couper le ruban, le jour de l'ouverture de l'Académie. Et une tarte, une fois."],
	["La coupe des fondateurs", "Les quatre fondateurs y burent l'eau du lac, le premier soir, pour promettre de rester. L'eau avait, dit-on, un goût de brume."],
	["Le cristal de la source", "Trois aiguilles de cristal trouvées sous la fontaine du cloître. Elles luisent quand quelqu'un apprend quelque chose. Elles luisent beaucoup les jours d'examen."],
	["Le premier grimoire de l'Académie", "Fermé depuis quatre siècles. La plaque dit : « Ne pas ouvrir. » Une autre plaque, plus petite : « Vraiment. »"],
	["La baguette de Mélisende", "Le bout luit encore, doucement, comme une étoile qu'on aurait mise en veilleuse."],
	["L'astrolabe de poche d'Aubin", "Trois anneaux d'or autour d'une petite sphère bleue. Le modèle du Grand Astrolabe, en tout petit. Il tourne encore, au même rythme que le grand."],
]

## La devise gravée au-dessus de la cheminée du Bureau
const DEVISE := "Gravé dans la pierre, au-dessus du feu : « GARDER UNE ÉCOLE, C'EST GARDER UNE FLAMME : LA PROTÉGER DU VENT, MAIS JAMAIS L'ENFERMER. » Dessous, plus petit : « Mélisende, Ermengarde, Gaucelin, Aubin. »"

## Le grimoire du pupitre (cabinet des Sortilèges) : une page au hasard
const GRIMOIRE := [
	"Le grimoire s'ouvre de lui-même à la page du sort de lumière : « Lumos ? Non. Ici, on dit : « Brille », poliment. » Une petite lueur danse un instant au-dessus de la page.",
	"Page du sort de rangement : un schéma montre une chaussette qui retourne toute seule dans un tiroir. Dans la marge : « Ne fonctionne pas sur la girouette de l'horloge. — T. »",
	"Page du sort de bulles : « Effet : des bulles qui chantent. Durée : jusqu'à ce que Maîtresse Alambic vous demande d'arrêter. »",
	"Page blanche. Puis, lentement, des lettres d'argent apparaissent : « Reviens quand tu sauras ce que tu cherches. »",
	"Page du sort de gel : « Pour refroidir une soupe trop chaude. Pas pour patiner dans la Grande Salle. (Voir incident n° 4.) »",
]

## La sphère de cristal : ce qu'on croit y voir
const SPHERE := [
	"Dans la sphère, la brume tourne… et dessine un instant un bateau qui file sur le lac.",
	"La sphère s'éclaire : tu y vois une tarte aux myrtilles. C'est soit une prophétie, soit l'heure du goûter.",
	"Au fond du cristal, une grenouille te regarde d'un air entendu. Puis elle disparaît.",
	"La brume de la sphère forme des lettres : « BIENTÔT ». Bientôt quoi ? La sphère ne précise pas.",
	"Tu vois la Couronne des Fondateurs qui tourne, tourne… et tu te sens soudain un peu plus savant.",
	"La sphère te montre ton propre reflet, en plus sage. C'est encourageant.",
]

## Dans la Grande Lunette (l'Observatoire) ou la lunette de la Salle des Astres : le jour, la nuit
const LUNETTE_JOUR := [
	"Dans la lunette, le lac d'Ombre, si net qu'on compte les nénuphars. Un héron pêche au bord des roseaux.",
	"La lunette montre le débarcadère, tout petit, et un bateau qui arrive dans la brume.",
	"Au loin, très loin, la ligne bleue d'une autre île. Le jour, les étoiles se cachent : on regarde la terre à leur place.",
	"Tu vises la girouette de la Tour de l'Horloge. Pas de chaussette aujourd'hui.",
]
## La nuit : les constellations (on en découvre une de plus à chaque regard)
const CONSTELLATIONS := [
	["l'étoile du Nord", "Elle ne bouge pas d'un cheveu : tout le ciel tourne autour d'elle."],
	["le Héron", "Ses longues pattes d'étoiles trempent dans la brume, au-dessus du lac."],
	["la Couronne Boréale", "Un demi-cercle de perles, juste au-dessus de la Grosse Tour. On dirait qu'elle salue la Couronne des Fondateurs."],
	["la Lyre", "Une petite harpe d'étoiles, et la plus brillante au bout : Véga."],
	["Saturnelle et ses anneaux", "Une planète couleur de miel, entourée de son anneau. Elle tourne dans le même sens que le Grand Astrolabe."],
	["la Grande Ourse", "Sept étoiles en casserole. Mère Fournil dit qu'il y manque un couvercle."],
	["Gertrude", "Une petite étoile, un peu à l'écart, qui clignote comme si elle avait un secret. Maître Fauconnier serait content : tu as trouvé Gertrude !"],
]

## La table des cartes de l'Observatoire
const TABLE_CARTES := "Sur la grande table, la carte du ciel de cette nuit, tenue par des presse-papiers en laiton. Les étoiles déjà vues sont piquées d'une épingle d'or. Il y en a beaucoup. Il en reste davantage."

## Le registre du gardien de l'horloge (la Chambre des Rouages)
const REGISTRE_HORLOGE := [
	"Le registre de Maître Rouage : « Lundi : l'horloge avance d'une minute. Mensonge dans la cour, probablement. Remise à l'heure. »",
	"Le registre de Maître Rouage : « Mardi : graissé la roue des minutes. La roue a dit merci. (Elle grince d'une certaine façon quand elle est contente.) »",
	"Le registre de Maître Rouage : « Mercredi : retrouvé une chaussette sur la girouette. Rendue à Tobie. Deuxième fois ce mois-ci. »",
	"Le registre de Maître Rouage : « Pari avec O. Fauconnier, année 11 : toujours égalité. Le miel commence à cristalliser. »",
]

## Les mannequins d'entraînement (la salle des cercles des Sortilèges)
const MANNEQUIN := [
	"Tu lèves la main comme Dame Sortelame l'a montré : une étincelle bleue file vers le mannequin, qui tourne sur lui-même avec dignité.",
	"Un petit éclair de lumière frappe le mannequin. Il ne bronche pas. C'est un mannequin. Mais il a l'air impressionné.",
	"Ton sort part un peu de travers et fait voler la poussière du cercle. Les runes au sol clignotent, amusées.",
	"Pfuit ! Une gerbe d'étincelles dorées. Le mannequin en garde une petite trace noire, comme une médaille.",
]

## Les vœux de la fontaine
const VOEUX := [
	"La pièce tourne, brille, et disparaît dans l'eau claire. Une petite bulle remonte. Ton vœu a été reçu.",
	"Plouf ! La pièce rejoint les autres au fond du bassin. Les ondes font trembler le reflet des arcades.",
	"La pièce tombe pile au milieu. Quelque part, quelqu'un a dû sourire. Peut-être la Rectrice.",
	"La pièce s'enfonce lentement, en se balançant comme une feuille. On dit que ce sont les meilleurs vœux.",
]

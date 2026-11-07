extends "res://scripts/hautefond_activite_v116.gd"
## V117 : la vie dans les lieux ouverts de la Cité des Nuées (comme à Hautefond, hautefond_activite_v116 :
## les gens viennent quand on approche, à leurs heures, et repartent quand on s'éloigne ; quelques-uns
## parlent) : les voyageurs de la Gare et le porteur-robot, les curieux du Belvédère de verre, les
## enfants qui font la course autour du miroir d'eau, le violoniste, la peintre et le marchand de
## ballons de l'Esplanade, le serveur et les gourmands de la terrasse du Café Cumulus, l'apprenti de
## l'Atelier des Inventeurs, la file du bureau et la classe en visite à la Maison du Conseil, les
## jardiniers des Serres, le lâcher de ballon-sonde de l'Institut des Vents, les veilleurs des
## Sustentateurs, les passagers de la Libellule et l'élève planeuse du Port, les voisins des
## Résidences, le pique-nique, les cerfs-volants et le coureur du Parc des Brumes.
## Les repères : nuees_ville_v113.cadres117 (chaque lieu : +Z local vers la ville, ou le monde).

## [lieu, rôle, position (repère du lieu), regard (degrés), pose, [heure de début, de fin], phrases, options]
## options : va (l'autre bout de son aller-retour), rond ([rayon, vitesse] autour de la position),
## phase, porte (ce qu'il porte), vr (aussi en VR), parle ([accueils], [[id, question, [réponses]]]),
## style (une autre allure : nuees_android, un robot des Nuées).
const POSTES117 := [
	# --- la Gare des Nuées (+Z : vers la sortie ; la cage de la capsule en z = -6 ; le guichet en x = 7)
	["gare", "femme", Vector3(-2.6, 0.05, -3.0), 180.0, "debout", [6.0, 22.0], ["La capsule arrive dans deux minutes. Ou deux nuages. Ici, on compte en nuages.", "J'emmène ma grand-mère voir la mer, en bas. Elle dit que la mer, c'est un ciel qui est tombé."], {"porte": "valise", "vr": true}],
	["gare", "homme", Vector3(2.8, 0.05, -2.6), 200.0, "bras_croises", [7.0, 20.0], ["Mon fils veut monter dans la capsule pour la cinquième fois. Moi, je veux un café.", "Théo nous a fait coucou depuis la cabine. Trois fois. Il est très accueillant, Théo."], {}],
	["gare", "garcon", Vector3(3.5, 0.05, -2.0), 170.0, "pointer", [8.0, 19.0], ["Elle descend ! Elle descend ! … Elle remonte !", "Quand je serai grand, je conduirai la capsule. Et je klaxonnerai aux nuages."], {}],
	["gare", "vieille", Vector3(5.6, 0.05, -1.0), 90.0, "debout", [7.0, 18.0], ["Un aller pour le Plancher, s'il vous plaît. Et un retour. Surtout le retour.", "Mon billet est bleu ciel. Assorti à mon chapeau. C'est important, l'élégance, en altitude."],
		{"vr": true, "parle": [["Bon vent ! Tu prends la capsule, toi aussi ?", "Bonjour ! Tu fais la queue ? Moi, je fais la conversation."],
			[["billet", "Il faut un billet ?", ["Un billet ? Non, la Ligne est gratuite depuis qu'elle a rouvert ! Mais j'aime bien en demander un quand même. Ça me fait un souvenir."]],
			["bas", "Vous descendez souvent ?", ["Une fois par semaine, pour voir ma sœur. Elle habite à Hautefond. Elle m'appelle « la Perchée ». Je l'appelle « la Plancheuse ». On s'adore."]]]]}],
	["gare", "homme", Vector3(0.6, 0.05, -2.4), 0.0, "marcher", [7.0, 21.0], ["Pardon, pardon ! Je descends acheter du pain au Plancher. Monsieur Pascal dit qu'il est meilleur en bas.", "Je reviens dans une heure ! Avec le pain. Et des nouvelles."], {"va": Vector3(0.6, 0.05, 8.4), "porte": "valise", "vr": true}],
	["gare", "homme", Vector3(-6.2, 0.05, -3.8), 0.0, "marcher", [6.0, 22.0], ["Bagages ! Bagages ! Bip. Attention, valise à gauche.", "Je suis le porteur de la Gare. Je porte tout, sauf les nuages. Ils glissent."], {"va": Vector3(-6.2, 0.05, 5.4), "porte": "chariot", "style": "nuees_android"}],
	# --- le Belvédère de verre (+Z : vers l'île ; le bout du plancher en z = -9,5)
	["belvedere", "homme", Vector3(3.9, 0.05, 4.5), -90.0, "bras_croises", [8.0, 20.0], ["Je ne regarde pas en bas. Je ne regarde pas en bas. … J'ai regardé en bas.", "Ma femme est au bout. Moi, je garde la rambarde. Il faut bien que quelqu'un la garde."],
		{"vr": true, "parle": [["Tu vas jusqu'au bout, toi ? Courageux.", "Ne fais pas attention à moi. Je profite de la vue. Les yeux fermés."],
			[["peur", "Vous avez le vertige ?", ["Moi ? Non ! J'ai juste une grande admiration pour le sol. Surtout quand il est sous moi, et pas deux cents mètres plus bas."]],
			["verre", "Le verre est solide ?", ["L'Ingénieure Nova dit qu'il tiendrait un éléphant. J'ai demandé : « Et deux éléphants ? » Elle n'a pas répondu. Je suis resté ici."]]]]}],
	["belvedere", "femme", Vector3(0.3, 0.05, -6.6), 180.0, "observer", [8.0, 21.0], ["Là, en bas : la Grande Colonne. Et tout petit, le Phare. On dirait une maquette.", "Les bateaux du Port des Cordages ressemblent à des miettes sur une nappe bleue."], {"vr": true}],
	["belvedere", "fille", Vector3(-1.2, 0.05, -5.0), 200.0, "pointer", [9.0, 19.0], ["Regarde ! Un nuage passe sous mes pieds ! Je marche sur un nuage !", "Si je saute, est-ce que j'atterris à Hautefond ? … Je demandais juste."], {}],
	["belvedere", "vieux", Vector3(-3.8, 0.05, 1.5), 90.0, "mains_dos", [7.0, 19.0], ["Je viens ici tous les matins depuis soixante ans. Le paysage n'a jamais été le même deux fois.", "Les gens d'en bas viennent voir le vide. Nous, on vient voir les gens d'en bas qui voient le vide. C'est très distrayant."], {}],
	# --- l'Esplanade du Ciel (repère du monde, au milieu du miroir d'eau)
	["esplanade", "garcon", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [9.0, 19.0], ["Le premier qui fait le tour du miroir d'eau a gagné !", "Je vais plus vite que la navette !"], {"rond": [11.2, 1.6], "vr": true}],
	["esplanade", "fille", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [9.0, 19.0], ["Attends-moi ! … Non, ne m'attends pas, je vais te dépasser !", "On fait la course jusqu'à la Plume ! … Ah non, elle est dans l'eau."], {"rond": [11.2, 1.6], "phase": 0.7}],
	["esplanade", "homme", Vector3(-12.69, 0.05, -4.62), 70.0, "violon", [10.0, 20.0], ["♪ La la lère… C'est la valse des nuages. Elle n'a pas de fin : le vent la continue.", "Ici, les pièces qu'on me lance remontent avec le vent. … Non, je plaisante. Merci !"], {"vr": true}],
	["esplanade", "femme", Vector3(7.0, 0.05, -12.12), -30.0, "peindre", [9.0, 18.0], ["Je peins la Plume de Séraphin. Elle bouge un peu avec le vent. Moi aussi, du coup.", "Ombeline m'a appris : « On ne peint pas le ciel. On l'écoute, et on le recopie. »"],
		{"vr": true, "parle": [["Bonjour ! Tu veux voir ? Ne regarde pas le nez de la Plume, je l'ai raté.", "Chut… le ciel est en train de changer de bleu. Ah, c'est fait."],
			[["tableau", "Qu'est-ce que vous peignez ?", ["La Plume de Séraphin, avec le ciel derrière. Le ciel change toutes les dix minutes. Alors je peins vite, ou je peins dix tableaux."]],
			["ombeline", "Vous connaissez Ombeline ?", ["Bien sûr ! C'est la peintre des couchers de soleil. Elle dit qu'il n'y en a jamais deux pareils. Moi, je n'arrive même pas à en peindre un pareil."]]]]}],
	["esplanade", "vieux", Vector3(-12.73, 0.05, 12.73), 135.0, "debout", [9.0, 19.0], ["Des ballons ! Des ballons qui montent ! Ici, ils montent encore plus haut, forcément.", "Un ballon pour la petite ? Il est gonflé à l'air des sommets. Le meilleur."], {}],
	["esplanade", "femme", Vector3(16.45, 0.05, 9.5), 0.0, "marcher", [8.0, 21.0], ["On fait le tour de l'Esplanade trois fois après le déjeuner. C'est le règlement de la digestion.", "Regarde le miroir d'eau : on y voit le ciel deux fois. Une fois en haut, une fois en bas."], {"va": Vector3(3.3, 0.05, 18.71), "vr": true}],
	# --- la terrasse du Café Cumulus (+Z : vers l'Esplanade ; le kiosque en x = -6)
	["cafe", "homme", Vector3(-4.4, 0.05, -2.0), 0.0, "marcher", [7.0, 20.0], ["Un lait de nuage pour la table deux ! Avec sa moustache offerte !", "Attention, chouquettes brûlantes ! Enfin, tièdes. Le four solaire est très poli."], {"va": Vector3(2.2, 0.05, 0.2), "porte": "plateau", "vr": true}],
	["cafe", "femme", Vector3(-4.6, 0.05, -2.9), -90.0, "debout", [7.0, 19.0], ["Un thé des sommets, s'il vous plaît. Et une chouquette. Et une autre chouquette. Pour mon chapeau.", "Gustave dit que sa meilleure recette, c'est la vue. Elle est servie avec tout."], {}],
	["cafe", "garcon", Vector3(-3.8, 0.05, -3.4), -80.0, "pointer", [8.0, 18.0], ["Maman, je veux la chouquette la plus grosse ! Celle qui ressemble à un nuage !", "Le lait de nuage, ça donne une moustache blanche. J'en ai déjà trois."], {}],
	["cafe", "homme", Vector3(5.4, 0.05, 0.9), -120.0, "boire", [7.0, 21.0], ["Ce lait de nuage… On dirait de boire un oreiller. Un oreiller délicieux.", "J'ai pris une chouquette pour le pigeon. Il en a pris deux. Il est très fort, ce pigeon."], {"vr": true}],
	["cafe", "vieille", Vector3(-1.2, 0.05, 2.9), 150.0, "rire", [9.0, 18.0], ["Gustave m'a raconté une blague sur les cumulus. Elle était légère. Comme un nuage.", "À mon âge, une chouquette par jour. Le docteur a dit « une ». Il n'a pas dit « une petite »."], {}],
	# --- l'Atelier des Inventeurs (+Z : vers l'Esplanade ; l'établi en x = 3,8, le comptoir en x = -3,4)
	["atelier", "femme", Vector3(-3.4, 0.05, 3.5), 180.0, "debout", [9.0, 18.0], ["Je viens rapporter mon grille-pain solaire. Il fait des tartines parfaites. Mais la nuit, il boude.", "Mireille m'a dit : « Ça marche presque. » Presque, c'est déjà beaucoup, ici."], {"vr": true}],
	["atelier", "garcon", Vector3(5.8, 0.05, 2.6), -90.0, "bricoler", [9.0, 18.0], ["Je suis apprenti inventeur ! Aujourd'hui, j'invente un tournevis qui tourne tout seul. Il tourne. Il ne visse pas encore.", "Mireille dit qu'une bonne invention rate au moins cent fois. J'en suis à quatre-vingt-dix-sept. Bientôt !"],
		{"vr": true, "parle": [["Chut ! Je suis en train d'inventer. … Bon, tu peux parler. Ça ne marchait pas, de toute façon.", "Bonjour ! Tu veux voir mon invention ? Elle n'existe pas encore, mais elle est géniale."],
			[["invention", "Qu'est-ce que tu inventes ?", ["Un parapluie qui pleut. Pour arroser les plantes en se promenant. Mireille dit que c'est une idée « à l'envers ». Moi, je trouve que c'est une idée à l'endroit des plantes."]],
			["mireille", "Mireille est une bonne maîtresse ?", ["La meilleure ! Elle ne se fâche jamais quand ça explose. Elle dit : « Note ce qui s'est passé, et recommence en reculant un peu. »"]]]]}],
	["atelier", "homme", Vector3(2.0, 0.05, 5.4), 200.0, "observer", [10.0, 17.0], ["Il paraît que Mireille a inventé un parapluie qui monte. Je viens voir s'il redescend.", "J'ai acheté une boussole à nuages. Elle indique toujours le plus joli. C'est pratique, mais lent."], {}],
	# --- la Maison du Conseil (+Z : vers l'Esplanade ; le bureau en x = -5, la loggia jusqu'en z = 2,8)
	["conseil", "homme", Vector3(-5.0, 0.05, 1.3), 180.0, "bras_croises", [8.0, 18.0], ["Je viens proposer une loi : interdire aux nuages de cacher le coucher de soleil. Le Conseil étudie la question.", "Ma demande est en lecture depuis trois jours. C'est normal, elle est longue : quarante pages, et un dessin."], {"vr": true}],
	["conseil", "vieille", Vector3(-4.4, 0.05, 2.1), 190.0, "debout", [8.0, 17.0], ["Je fais la queue pour remercier la Première Conseillère. Elle a fait réparer le banc de mon allée. Je lui ai tricoté une écharpe.", "Céleste Altaïr écoute tout le monde. Même moi. Et moi, je parle beaucoup."], {}],
	["conseil", "femme", Vector3(1.0, 0.05, 5.4), 180.0, "enseigner", [9.0, 16.0], ["Les enfants, voici la Maison du Conseil. Ici, on décide de tout : des jardins, de l'eau des nuages, et de l'heure du goûter.", "Qui sait qui a fait flotter notre île ? … Oui ! Séraphin Altaïr, il y a cent vingt ans !"],
		{"vr": true, "parle": [["Bonjour ! Nous sommes en sortie scolaire. Tu veux te joindre à nous ? Il y a un questionnaire.", "Chut, les enfants, on a de la visite ! Dites « Bon vent »."],
			[["conseil", "À quoi sert le Conseil ?", ["Le Conseil des Nuées décide de tout ce qui se partage : l'eau des nuages, les jardins, les ballons-sondes, les horaires de la Navette. Et une fois par an, le nom du plus beau nuage."]],
			["seraphin", "Qui était Séraphin Altaïr ?", ["L'inventeur des Sustentateurs ! Il y a cent vingt ans, il a fait monter cette montagne dans le ciel, avec quatre moteurs et beaucoup de patience. Son arrière-petit-fils, le Grand-Père Séverin, raconte encore l'histoire à qui veut l'entendre."]]]]}],
	["conseil", "garcon", Vector3(0.2, 0.05, 7.0), 0.0, "pointer", [9.0, 16.0], ["Maîtresse, maîtresse ! Est-ce que la Première Conseillère sait voler ?", "Quand je serai grand, je serai conseiller. Je voterai le goûter deux fois par jour."], {}],
	["conseil", "fille", Vector3(1.9, 0.05, 7.2), 10.0, "debout", [9.0, 16.0], ["J'ai vu la Première Conseillère ! Elle m'a dit « Bon vent » ! À MOI !", "On va voter pour choisir le nom du nouveau nuage. Je propose « Chouquette »."], {}],
	# --- les Serres d'Altitude (le grand dôme ; +Z : vers le sas ; le sol de terre en y = 0)
	["serres", "femme", Vector3(3.6, 0.05, 2.6), -60.0, "jardiner", [7.0, 18.0], ["Les fraisiers géants ont besoin de chansons. Je leur chante des berceuses. Ils poussent en dormant.", "Une seule fraise de Flora suffit pour une tarte. Une tarte pour six. Ou pour moi, un dimanche."],
		{"vr": true, "parle": [["Bonjour ! Attention où tu marches, les courgettes sont susceptibles.", "Bon vent ! Tu viens voir les fraises géantes ? Tout le monde vient voir les fraises géantes."],
			[["fraises", "Comment les fraises deviennent-elles si grosses ?", ["Le soleil d'ici ne se couche presque jamais derrière une montagne. Et Flora leur parle tous les matins. Moi, je leur chante des berceuses. On ne sait pas laquelle des trois choses marche le mieux."]],
			["serres", "Que pousse-t-il dans les serres ?", ["Des tomates, des salades, des pommiers nains, des fraises géantes, et tout le miel des abeilles des terrasses. De quoi nourrir la Cité, avec l'eau des nuages."]]]]}],
	["serres", "homme", Vector3(-4.6, 0.05, 3.6), 0.0, "marcher", [7.0, 17.0], ["Terreau frais pour les dômes ! Pardon, ça passe !", "J'ai trouvé une fraise grosse comme ma tête. Je l'ai portée jusqu'à Flora. On l'a mesurée. Ma tête a perdu."], {"va": Vector3(-4.6, 0.05, -4.2), "porte": "caisse"}],
	["serres", "fille", Vector3(1.8, 0.05, 5.6), 160.0, "pointer", [9.0, 17.0], ["Il fait chaud comme en été, ici ! Dehors, c'est l'été aussi. Mais ici, c'est l'été de l'été.", "Une abeille m'a regardée. Je l'ai regardée. On est amies, maintenant."], {"vr": true}],
	["serres", "vieux", Vector3(-3.2, 0.05, 0.6), 90.0, "observer", [8.0, 18.0], ["Je viens chaque jour voir pousser les tomates. Elles poussent quand je ne regarde pas. Alors je regarde ailleurs, très fort.", "De mon temps, on faisait pousser des salades sur le toit de la Gare. Elles avaient le vertige."], {}],
	# --- l'Institut des Vents (repère tourné comme le monde ; la façade en z = 0 ; le mât de mesure en x = -28)
	["institut", "femme", Vector3(-1.0, 0.05, 2.6), 0.0, "marcher", [8.0, 18.0], ["Bulletin de midi : vent d'ouest, ciel bleu, et un nuage en forme de lapin. Je l'ai noté.", "Le Docteur Aurèle veut le ballon en l'air dans dix minutes. Ou dans dix nuages."], {"va": Vector3(-18.5, 0.05, 3.2), "porte": "dossiers", "vr": true}],
	["institut", "homme", Vector3(-20.2, 0.05, 4.2), 30.0, "pointer", [8.0, 17.0], ["Trois, deux, un… On lâche ! … Il faut le lâcher, Jules. Lâche-le.", "Ce ballon-sonde va monter à dix kilomètres. Il nous enverra la température de là-haut. Et une carte postale, j'espère."],
		{"vr": true, "parle": [["Bonjour ! Recule un peu : le ballon a le hoquet quand il y a du monde.", "Bon vent ! Tu tombes bien : on lâche un ballon-sonde dans un instant."],
			[["ballon", "À quoi sert ce ballon ?", ["Il monte très haut avec ses instruments : la température, le vent, l'humidité. Le Docteur Aurèle en tire ses prévisions. Et quand le ballon éclate, très haut, le petit parachute ramène les instruments. En général."]],
			["aurele", "Le Docteur Aurèle est là ?", ["Il est dans son bureau, à l'étage, en train de baptiser un nouveau nuage. Il hésite entre « Hortense » et « Cumulus le Brave ». Ça peut durer."]]]]}],
	["institut", "homme", Vector3(-21.6, 0.05, 2.6), 60.0, "observer", [8.0, 17.0], ["Je tiens la corde. C'est mon travail. Le plus important de l'Institut, d'après moi.", "La dernière fois, le ballon est revenu avec un pigeon dedans. Très surpris, le pigeon."], {}],
	["institut", "homme", Vector3(-25.6, 0.05, -0.6), -60.0, "bricoler", [8.0, 17.0], ["L'anémomètre du haut tourne un peu de travers. Je le soigne d'en bas. Avec des encouragements.", "Trente-quatre mètres de mât. Je monte une fois par semaine. Le reste du temps, je lui parle d'en bas."], {}],
	["institut", "femme", Vector3(6.0, 0.05, 3.1), 180.0, "debout", [9.0, 18.0], ["Je viens inscrire mon nuage. Il est passé au-dessus de mon balcon trois matins de suite. Je crois qu'il m'aime bien.", "Le Docteur Aurèle donne un nom à chaque nouveau nuage. Il y en a un qui s'appelle « Gaston-du-Mardi »."], {}],
	# --- la Salle des Sustentateurs (+Z : vers la ville ; les pupitres derrière, à trois mètres)
	["sustentateurs", "homme", Vector3(1.616, 0.05, -1.493), 133.0, "holo", [7.0, 22.0], ["Sustentateur numéro trois : quatre-vingt-dix-neuf virgule huit pour cent. Il ronronne. C'est bon signe.", "On surveille les moteurs nuit et jour. La nuit, ils ronronnent plus doucement. Comme nous."],
		{"vr": true, "parle": [["Bon vent ! Ne touche à rien, s'il te plaît : ce bouton-là fait monter l'île d'un centimètre.", "Bonjour ! Tu entends ? Ce ronronnement, c'est l'île qui flotte."],
			[["moteurs", "Comment marchent les Sustentateurs ?", ["Quatre grands anneaux tournent sous l'île, dans la roche, et repoussent le sol très loin en dessous. Séraphin Altaïr l'a calculé il y a cent vingt ans. Nous, on vérifie qu'ils ne s'endorment pas."]],
			["descendre", "On peut les voir ?", ["Oui ! L'escalier, là, sous la trappe de verre, descend jusqu'au cœur des Sustentateurs. Mets ton casque… non, je plaisante, il n'y a pas de casque. Mais tiens la rampe."]]]]}],
	["sustentateurs", "femme", Vector3(-0.597, 0.05, -2.117), 196.0, "holo", [6.0, 20.0], ["Équilibre de l'île : parfait. Bon, à un millimètre près. C'est Théo qui saute dans sa capsule.", "L'Ingénieure Nova dit que l'île flotte grâce aux calculs et au thé. Je m'occupe du thé."], {}],
	["sustentateurs", "vieux", Vector3(-3.4, 0.05, 3.8), 150.0, "observer", [9.0, 18.0], ["Sous nos pieds, quatre moteurs tiennent toute une ville en l'air depuis cent vingt ans. Et moi, je n'arrive pas à tenir mon chapeau.", "Séraphin Altaïr était mon arrière-grand-oncle. Enfin, je crois. Tout le monde ici dit ça."], {}],
	# --- le Port des Nuées (+Z : vers l'île ; le ponton de z = -15 à 15 ; la cabine de la Libellule en z = -12)
	["port", "femme", Vector3(-2.4, 0.05, -8.8), 180.0, "debout", [9.0, 19.0], ["J'ai un billet pour le tour de l'île en dirigeable ! La Capitaine Zéphyrine dit qu'on verra la cascade d'en dessous.", "Mon mari a peur en dirigeable. Il est resté au café. Il m'a demandé une photo du vide."], {"porte": "valise", "vr": true}],
	["port", "garcon", Vector3(-1.4, 0.05, -9.4), 170.0, "pointer", [9.0, 18.0], ["La Libellule ! Elle est amarrée par le nez, comme un chien en laisse. Un très gros chien.", "Quand je serai grand, je serai capitaine. Comme Zéphyrine. Et comme Héloïse. Les deux en même temps."], {}],
	["port", "homme", Vector3(3.0, 0.05, -6.2), 90.0, "bricoler", [7.0, 20.0], ["Je vérifie les amarres. Un dirigeable mal attaché, ça part faire un tour tout seul.", "La Capitaine Zéphyrine veut que tout brille. Même le vent. Je fais de mon mieux."],
		{"vr": true, "parle": [["Bon vent ! Attention aux cordes, elles sont plus vieilles que moi.", "Bonjour ! Tu embarques ? La cabine de verre, là, au pied du mât, monte jusqu'à la nacelle."],
			[["libellule", "Où va la Libellule ?", ["Elle fait le tour de l'île deux fois par jour, et descend parfois jusqu'au Port des Cordages, à Hautefond. Là-bas, il y a l'Albatros de la Capitaine Héloïse. Ces deux-là font la course dès qu'elles se croisent."]],
			["planeur", "Et les planeurs ?", ["Ça, c'est Icare Plané et son école. Ils partent du bout du ponton et planent autour de l'île. Icare n'a pas marché depuis trois ans, paraît-il."]]]]}],
	["port", "fille", Vector3(1.6, 0.05, 12.0), 180.0, "marcher", [9.0, 18.0], ["Leçon de planeur avec Icare ! Je porte l'aile. Elle est plus grande que moi.", "Icare dit : « Le vent, c'est un ami qui ne prévient jamais. » Alors je reste polie."], {"va": Vector3(1.6, 0.05, -3.5), "porte": "aile"}],
	["port", "homme", Vector3(-2.6, 0.05, 13.0), 120.0, "enseigner", [9.0, 17.0], ["Un planeur, ça ne tombe pas : ça cherche un endroit où atterrir. Nuance.", "Leçon numéro un : on regarde les oiseaux. Leçon numéro deux : on ne leur demande pas leur avis."], {}],
	# --- les Résidences des Terrasses (+Z : vers la ville ; les portes en x = -7 et x = 5)
	["residences", "femme", Vector3(8.4, 0.05, 2.4), 10.0, "jardiner", [8.0, 19.0], ["J'arrose les fraisiers de la jardinière. Ils sont à tout le monde. Les fraises aussi. En théorie.", "Mon balcon donne sur le Parc des Brumes. Le matin, la brume monte me dire bonjour."], {"vr": true}],
	["residences", "garcon", Vector3(2.5, 0.05, 7.8), 0.0, "marcher", [9.0, 19.0], ["Chat perché ! … Ici, on dit « nuage perché ». Il faut monter sur un banc.", "Je suis le vent ! Personne ne m'attrape !"], {"rond": [1.4, 1.5], "vr": true}],
	["residences", "fille", Vector3(2.5, 0.05, 7.8), 0.0, "marcher", [9.0, 19.0], ["Tu es le vent, moi je suis la tempête ! Ouuuuh !", "Monsieur Pascal a dit « Moins fort ! ». Alors on court moins fort. Mais plus vite."], {"rond": [1.4, 1.5], "phase": 3.1}],
	["residences", "vieux", Vector3(-10.4, 0.05, 5.6), 60.0, "bras_croises", [8.0, 20.0], ["Monsieur Pascal a encore écrit une réclamation. Contre le vent, cette fois. Il dit qu'il souffle trop fort sur son journal.", "Ici, tout le monde connaît tout le monde. Et tout le monde connaît le chat de tout le monde."], {}],
	["residences", "vieille", Vector3(-9.3, 0.05, 6.4), 240.0, "rire", [8.0, 20.0], ["Ha ha ! Et le chat, il est remonté tout seul par la navette ? Il a pris un billet ?", "Ma voisine du troisième fait des confitures de fraises géantes. Une fraise, douze pots."], {}],
	# --- le Parc des Brumes (repère du monde, près de l'étang)
	["parc", "homme", Vector3(-13.4, 0.05, 8.6), 90.0, "mediter", [10.0, 18.0], ["Pique-nique au Parc des Brumes ! Le seul endroit où les nuages viennent goûter avec vous.", "J'ai apporté des fraises géantes. Une seule. Elle prend toute la nappe."], {"vr": true}],
	["parc", "femme", Vector3(-12.0, 0.05, 9.8), 200.0, "mediter", [10.0, 18.0], ["Chut, écoute : la Cascade, là-bas. Elle tombe dans le vide et se change en nuage. Elle ne fait presque pas de bruit.", "On vient ici chaque dimanche. Aujourd'hui, c'est mardi. Mais il faisait trop beau pour attendre."], {}],
	["parc", "fille", Vector3(-11.6, 0.05, 8.0), 300.0, "mediter", [10.0, 18.0], ["J'ai fait une couronne de trèfles. Elle est pour le nuage qui ressemble à un mouton.", "Papa dit qu'on ne nourrit pas les nuages. Mais celui-là, il a l'air d'avoir faim."], {}],
	["parc", "garcon", Vector3(-9.0, 0.05, 2.0), 153.0, "pointer", [9.0, 19.0], ["Mon cerf-volant touche presque les nuages ! … Il est dans un nuage. Il revient tout mouillé.", "Lili Altaïr fait voler le sien plus haut que tout le monde. Un jour, je la battrai. Peut-être."],
		{"vr": true, "parle": [["Regarde mon cerf-volant ! Le rouge, là-haut ! … Non, l'autre rouge.", "Bon vent ! Aujourd'hui, il y a du vent. Donc c'est un bon vent."],
			[["cerf", "Comment tu le fais monter si haut ?", ["Il faut courir trois pas, lâcher la ficelle doucement, et dire merci au vent. Lili dit que le merci est le plus important."]],
			["lili", "Tu connais Lili ?", ["Lili Altaïr ! La fille de la Première Conseillère ! Elle a un cerf-volant en forme de dragon. Elle n'est jamais descendue en bas, mais son cerf-volant, si : la ficelle a cassé. Il est à Hautefond, maintenant."]]]]}],
	["parc", "fille", Vector3(-6.0, 0.05, 6.0), 146.0, "pointer", [9.0, 19.0], ["Le vent tire très fort ! Si je m'envole, dis à Maman que je reviens pour le goûter !", "Mon cerf-volant est en forme de baleine. Comme celle du Dôme d'Azur. En plus petit. Et en plus haut."], {}],
	["parc", "homme", Vector3(-20.0, 0.05, 14.0), 0.0, "marcher", [7.0, 20.0], ["Une, deux ! Une, deux ! Le tour de l'île, c'est six kilomètres. Moi, j'en fais un. Mais avec conviction.", "Bon vent ! … Pardon, je n'ai plus de souffle pour le reste de la phrase."], {"va": Vector3(12.0, 0.05, 20.0)}],
]

var _anim117: Array = []                 # [nœud, base, amplitude, période, phase, lieu, heures] : ce qui se balance au vent


func build(owner: Node) -> void:
	owner_hf = owner
	main = owner.main
	pc = owner.pc
	name = "Activite_nuees_v117"
	style = "nuees"
	prefix = "nu117_"
	var nu: Node = owner.nuees
	_rng.seed = 117117
	for k in nu.cadres117:
		cadres[k] = nu.cadres117[k]
	for k3 in cadres:
		var g: String = _groupe(str(k3))
		if not centres.has(g):
			centres[g] = (cadres[k3] as Transform3D).origin
	_decors117(nu.kit)
	print("ILE_MANGA_V117: %d travailleurs et visiteurs dans les lieux de la Cité des Nuées" % _poster(POSTES117))


# =================================================================== les décors

func _decors117(kit) -> void:
	# l'Esplanade : le chevalet de la peintre (face à elle), les ballons du marchand
	if cadres.has("esplanade"):
		var ex: Transform3D = cadres["esplanade"]
		var cv := Transform3D(Basis(Vector3.UP, deg_to_rad(-30.0 + 180.0)), ex * Vector3(6.55, 0.0, -11.34))
		for e in [[-0.32, 0.18, -0.12], [0.32, 0.18, -0.12], [0.0, -0.3, 0.25]]:
			kit.beam(cv * Vector3(float(e[0]), 0.0, float(e[1])), cv * Vector3(float(e[0]) * 0.3, 1.75, float(e[1]) * 0.2 + float(e[2]) * 0.1), 0.025, "bois113")
		kit.box(cv * T(0, 0.92, -0.02), Vector3(0.7, 0.03, 0.06), "bois113", 1.0)
		_toile(cv * T(0, 1.32, 0.0), Vector2(0.62, 0.78), "res://assets/textures/nuees/tableau_coucher.png")
		var bal := Node3D.new()
		add_child(bal)
		bal.global_position = ex * Vector3(-12.4, 1.3, 12.4)
		var cols: Array = [Color(0.92, 0.3, 0.3), Color(0.3, 0.6, 0.95), Color(0.98, 0.82, 0.25), Color(0.5, 0.82, 0.45), Color(0.85, 0.5, 0.9), Color(1.0, 1.0, 1.0), Color(1.0, 0.6, 0.3)]
		for i in range(cols.size()):
			var a: float = TAU * i / cols.size()
			var top := Vector3(cos(a) * 0.35, 1.1 + (i % 3) * 0.18, sin(a) * 0.35)
			_boule(bal, top, 0.17, cols[i])
			_fil(bal, Vector3.ZERO, top - Vector3(0, 0.17, 0))
		_anim117.append([bal, bal.transform.basis, 0.08, 3.1, 0.0, "esplanade", [9.0, 19.0]])
	# l'Institut des Vents : le ballon-sonde sur son aire de lâcher, sa corde, sa nacelle d'instruments
	if cadres.has("institut"):
		var ix: Transform3D = cadres["institut"]
		kit.cyl(ix * T(-19.8, 0.0, 3.2), 1.0, 1.0, 0.08, "composite113", 20)
		kit.box(ix * T(-18.4, 0.45, 4.6), Vector3(1.0, 0.9, 0.6), "composite113", 1.0)
		kit.col_box(ix * T(-18.4, 0.45, 4.6), Vector3(1.0, 0.9, 0.6))
		kit.box(ix * T(-18.4, 0.92, 4.6), Vector3(1.04, 0.04, 0.64), "acier113", 1.0)
		var bs := Node3D.new()
		add_child(bs)
		bs.global_position = ix * Vector3(-19.8, 0.1, 3.2)
		_boule(bs, Vector3(0, 4.6, 0), 0.95, Color(0.96, 0.96, 0.94), Vector3(1.0, 1.15, 1.0))
		_fil(bs, Vector3.ZERO, Vector3(0, 3.6, 0))
		var boite := MeshInstance3D.new()
		boite.mesh = _bx(Vector3(0.22, 0.18, 0.22))
		boite.material_override = _matc(Color(0.95, 0.55, 0.2))
		boite.position = Vector3(0, 2.9, 0)
		bs.add_child(boite)
		_anim117.append([bs, bs.transform.basis, 0.05, 4.3, 1.2, "", []])
	# le Parc des Brumes : la nappe du pique-nique, son panier ; deux cerfs-volants très haut
	if cadres.has("parc"):
		var px: Transform3D = cadres["parc"]
		kit.box(px * Transform3D(Basis(Vector3.UP, 0.3), Vector3(-12.4, 0.02, 8.9)), Vector3(2.4, 0.02, 1.8), "toile113_bleu", 1.0)
		kit.box(px * Transform3D(Basis(Vector3.UP, 0.3), Vector3(-12.6, 0.16, 9.1)), Vector3(0.45, 0.28, 0.32), "bois113", 1.0)
		var fr := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.36
		fr.mesh = sm
		fr.material_override = _matc(Color(0.85, 0.12, 0.15))
		add_child(fr)
		fr.global_position = px * Vector3(-12.0, 0.2, 8.6)
		for e2 in [[Vector3(-9.0, 1.2, 2.0), Vector3(-2.0, 21.0, -12.0), Color(0.9, 0.2, 0.2)], [Vector3(-6.0, 1.2, 6.0), Vector3(2.0, 17.0, -6.0), Color(0.35, 0.55, 0.95)]]:
			var hand: Vector3 = px * (e2[0] as Vector3)
			var kite := Node3D.new()
			add_child(kite)
			kite.global_position = px * (e2[1] as Vector3)
			_cerf_volant(kite, e2[2])
			kite.set_meta("main117", hand)
			_anim117.append([kite, kite.transform.basis, 0.25, 2.3 + randf() * 0.6, randf() * 3.0, "parc", [9.0, 19.0]])
			var ficelle := MeshInstance3D.new()
			ficelle.name = "ficelle"
			ficelle.material_override = _matc(Color(0.92, 0.92, 0.9))
			add_child(ficelle)
			kite.set_meta("ficelle117", ficelle)
	# le Port des Nuées : la manche à air, au pied du ponton
	if cadres.has("port"):
		var pt: Transform3D = cadres["port"]
		kit.cyl(pt * T(3.6, 0.0, 13.8), 0.05, 0.04, 4.2, "acier113", 8, false)
		var ma := Node3D.new()
		add_child(ma)
		ma.global_position = pt * Vector3(3.6, 4.1, 13.8)
		for k4 in range(4):
			var cm := CylinderMesh.new()
			cm.top_radius = 0.22 - k4 * 0.035
			cm.bottom_radius = 0.22 - (k4 + 1) * 0.035
			cm.height = 0.32
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = _matc(Color(1.0, 0.45, 0.12) if k4 % 2 == 0 else Color(0.96, 0.96, 0.96))
			mi.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.16 + k4 * 0.32, 0, 0))
			ma.add_child(mi)
		_anim117.append([ma, ma.transform.basis, 0.35, 2.7, 0.4, "", []])
	kit.commit()


## Une petite toile peinte (le chevalet de l'Esplanade).
func _toile(xf: Transform3D, size: Vector2, tex: String) -> void:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.96, 0.95, 0.92)
	if ResourceLoader.exists(tex):
		m.albedo_texture = load(tex)
		m.albedo_color = Color(1, 1, 1)
	m.roughness = 0.8
	mi.material_override = m
	add_child(mi)
	mi.global_transform = xf


func _matc(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	return m


func _boule(parent: Node3D, pos: Vector3, r: float, c: Color, scl: Vector3 = Vector3.ONE) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	var m := _matc(c)
	m.roughness = 0.25
	mi.material_override = m
	mi.transform = Transform3D(Basis.from_scale(scl), pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _fil(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.004
	cm.bottom_radius = 0.004
	cm.height = a.distance_to(b)
	cm.radial_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = _matc(Color(0.9, 0.9, 0.88))
	var dir: Vector3 = (b - a).normalized()
	var bs := Basis(Quaternion(Vector3.UP, dir)) if absf(dir.dot(Vector3.UP)) < 0.999 else Basis()
	mi.transform = Transform3D(bs, (a + b) * 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Un cerf-volant : un losange de toile, sa croix de baguettes, sa queue de nœuds.
func _cerf_volant(n: Node3D, c: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = [Vector3(0, 0.75, 0), Vector3(0.5, 0.15, 0), Vector3(0, -0.85, 0), Vector3(-0.5, 0.15, 0)]
	for tri in [[0, 1, 2], [0, 2, 3]]:
		for idx in tri:
			st.set_normal(Vector3.BACK)
			st.add_vertex(pts[idx])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _matc(c)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	n.add_child(mi)
	for k in range(5):
		var nb := MeshInstance3D.new()
		nb.mesh = _bx(Vector3(0.14, 0.06, 0.02))
		nb.material_override = _matc(Color(1, 1, 1) if k % 2 == 0 else c)
		nb.position = Vector3(sin(k * 1.3) * 0.12, -1.05 - k * 0.32, 0)
		n.add_child(nb)


## Ce qu'il porte : en plus de Hautefond, une aile de planeur.
func _objet(f: Node, what: String) -> Node3D:
	if what != "aile":
		return super._objet(f, what)
	var n := Node3D.new()
	f.npc.add_child(n)
	var mi := MeshInstance3D.new()
	mi.mesh = _bx(Vector3(3.2, 0.05, 0.42))
	var m := _matc(Color(0.96, 0.96, 0.95))
	m.roughness = 0.3
	mi.material_override = m
	mi.transform = Transform3D(Basis(Vector3.BACK, 0.1), Vector3(0.0, 1.42, -0.12))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	return n


# =================================================================== ce qui bouge au vent

func _process(delta: float) -> void:
	super._process(delta)
	if main == null or not bool(main.get("game_started")) or _anim117.is_empty():
		return
	var p: Vector3 = main._player_pos_v27()
	var hour: float = float(main.temps_v56.hour) if main.get("temps_v56") != null else 12.0
	for a in _anim117:
		var n: Node3D = a[0]
		if not is_instance_valid(n):
			continue
		# les ballons du marchand, les cerfs-volants des enfants : seulement quand ils sont là
		if str(a[5]) != "":
			var on: bool = bool(_actifs.get(str(a[5]), false)) and _heure(hour, a[6])
			n.visible = on
			if n.has_meta("ficelle117"):
				(n.get_meta("ficelle117") as Node3D).visible = on
			if not on:
				continue
		if n.global_position.distance_to(p) > 160.0:
			continue
		var ang: float = float(a[2]) * sin(TAU * _t / float(a[3]) + float(a[4]))
		n.transform.basis = (a[1] as Basis) * Basis(Vector3.BACK, ang) * Basis(Vector3.RIGHT, ang * 0.5)
		if n.has_meta("ficelle117"):
			var fi: MeshInstance3D = n.get_meta("ficelle117")
			var hand: Vector3 = n.get_meta("main117")
			var to: Vector3 = n.global_position + n.global_transform.basis * Vector3(0, -0.2, 0)
			var cm := fi.mesh as CylinderMesh
			if cm == null:
				cm = CylinderMesh.new()
				cm.top_radius = 0.008
				cm.bottom_radius = 0.008
				cm.radial_segments = 4
				fi.mesh = cm
			cm.height = hand.distance_to(to)
			var dir: Vector3 = (to - hand).normalized()
			fi.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (hand + to) * 0.5)

extends "res://scripts/hautefond_activite_v116.gd"
## V118 : la vie dans les lieux ouverts des Strates et de la Fronde (comme à Hautefond et dans la Cité
## des Nuées : les gens viennent quand on approche, à leurs heures, et repartent quand on s'éloigne ;
## quelques-uns parlent). Les repères : strates_ville_v114.cadres118 et fronde_v114.cadres118.
##  - les Strates (les corps de Montjoie, les prénoms d'en bas) : la Gare des Strates, la Place des
##    Rouages, la Grande Forge, la terrasse de La Marmite, l'étal de l'Atelier des Lumières, le quai des
##    wagonnets des Mines, les Jardins des Champignons, le quai du Petit Train, la Galerie ;
##  - la Fronde (les corps de Port-Boucan, les surnoms d'atelier) : le Pont des Frondeurs, la Place Libre,
##    la Scène des Soupapes et sa fosse, la Cantine Libre, l'Atelier Libre, le Troc, l'Assemblée, le
##    Skatepark, le Mur des Fresques.

## Les lieux de la Fronde : leurs gens ont l'allure des Frondeurs (« fronde » : les corps de Port-Boucan).
const FRONDE := ["pont", "place_libre", "scene", "cantine", "atelier_libre", "troc", "assemblee", "skate", "fresques"]

## [lieu, rôle, position (repère du lieu), regard (degrés), pose, [heure de début, de fin], phrases, options]
## options : va (l'autre bout de son aller-retour), rond ([rayon, vitesse] autour de la position),
## phase, porte (ce qu'il porte), vr (aussi en VR), parle ([accueils], [[id, question, [réponses]]]),
## style (une autre allure).
const POSTES118 := [
	# --- la Gare des Strates (repère du monde, au milieu de la marquise ; le guichet vers (5.5, -4.5), la cage du Dôme en (0, -7.6))
	["gare", "femme", Vector3(4.57, 0.05, -3.74), 129.0, "debout", [6.0, 22.0], ["C'est ma première descente ! J'ai pris un chapeau et un parapluie. Il paraît qu'ici, il ne pleut jamais. Je le garde quand même.", "Le monsieur du guichet m'a demandé trois fois où j'allais. Je crois qu'il n'entend pas très bien. Ou alors, il aime ma voix."],
		{"porte": "valise", "vr": true, "parle": [["Bonjour ! Vous aussi, vous venez d'en haut ? On reconnaît ceux d'en haut : ils regardent tous le plafond.", "Bonne descente ! … C'est bien comme ça qu'on dit, ici ? J'apprends."],
			[["ou", "Où allez-vous ?", ["Au Dôme d'Azur, tout au fond de la mer ! La grille du vieux liftier est grande ouverte. Je vais voir la baleine qui chante. On dit qu'elle chante faux. Moi aussi : on s'entendra bien."]],
			["soleil", "Que pensez-vous du Soleil de Laiton ?", ["Un soleil qu'on peut regarder sans plisser les yeux ! Celui d'en haut est bien plus prétentieux. Celui-ci a l'air gentil. Il tourne doucement, comme s'il réfléchissait."]]]]}],
	["gare", "homme", Vector3(3.95, 0.05, -3.23), 129.0, "bras_croises", [7.0, 21.0], ["J'ai crié « Un billet pour le Dôme ! » quatre fois. Le liftier m'a répondu « Comment ? » quatre fois. On progresse.", "Ma femme dit que je fais toujours la queue derrière la personne la plus bavarde. Elle a raison. Encore."], {}],
	["gare", "vieux", Vector3(-5.45, 0.05, -5.19), 50.0, "lire", [6.0, 20.0], ["Le journal d'en haut. Il descend par la cabine du matin, encore tiède. Les nouvelles aussi.", "« Demain, il pleuvra sur Hautefond. » Formidable. Ici, il fait toujours le temps du Soleil de Laiton."], {"vr": true}],
	["gare", "fille", Vector3(-1.4, 0.05, -4.4), 156.0, "pointer", [8.0, 20.0], ["Papa ! La cage descend jusqu'à la mer ! Est-ce qu'on verra des poissons ? Des vrais ?", "Je veux voir la baleine. Et le funiculaire. Et encore la baleine."], {}],
	["gare", "homme", Vector3(-7.0, 0.05, 4.5), 77.0, "marcher", [6.0, 22.0], ["Bagages ! Bagages pour la cabine ! Bonne descente à tous !", "Attention, chariot qui passe ! Il ne freine pas très bien, mais il s'excuse."],
		{"va": Vector3(4.5, 0.05, 7.2), "porte": "chariot", "vr": true}],
	# --- la Place des Rouages (repère du monde ; la Grande Horloge vers (15.5, 17), la Fontaine aux Rouages vers (-15.5, 17))
	["place", "vieux", Vector3(12.21, 0.05, 14.58), 42.0, "observer", [7.0, 21.0], ["Je règle ma montre sur la Grande Horloge depuis cinquante ans. Ma montre retarde. L'Horloge, jamais.", "Regarde les engrenages : ils tournent dans un sens, puis dans l'autre. Comme les potins de la Place."], {"vr": true}],
	["place", "vieille", Vector3(11.14, 0.05, -10.36), 315.0, "tricot", [8.0, 19.0], ["Une écharpe pour mon petit-fils, qui est mineur. Rouge, pour qu'on le voie de loin dans la galerie.", "Sous terre, il ne fait jamais froid. Mais une écharpe, c'est comme un câlin qu'on emporte."], {}],
	["place", "garcon", Vector3(-15.5, 0.05, 17.0), 0.0, "marcher", [9.0, 20.0], ["Le premier qui fait trois tours de la Fontaine aux Rouages a gagné !", "Je cours plus vite que la roue à aubes ! … Presque."], {"rond": [5.0, 1.5], "vr": true}],
	["place", "fille", Vector3(-15.5, 0.05, 17.0), 0.0, "marcher", [9.0, 20.0], ["Attends-moi ! Non, ne m'attends pas : je vais te doubler !", "Si je tombe dans la fontaine, je dirai que c'était pour arroser la roue."], {"rond": [5.0, 1.5], "phase": 3.1}],
	["place", "homme", Vector3(-17.85, 0.05, -6.5), 130.0, "marcher", [6.0, 11.0], ["Pain d'en haut ! Tout chaud, il vient de descendre par la cabine !", "Une miche pour La Marmite, une pour la Forge, et la croûte pour moi. C'est le salaire du livreur."],
		{"va": Vector3(-3.3, 0.05, -18.7), "porte": "sac"}],
	# --- la Grande Forge des Strates (+Z : la façade ouverte ; les fours au fond, le marteau-pilon en (7.5, 2.5), le comptoir en (0, 9.9))
	["forge", "fille", Vector3(6.5, 0.05, -2.9), 180.0, "forger", [6.0, 18.0], ["Le four de droite a faim à six heures pile. Si on le fait attendre, il boude, comme dit Maîtresse Brunehaut.", "Deux coups, puis un : c'est bonjour. Trois coups : « passe-moi la pince ». Quatre coups : « où est la pince ? »."],
		{"vr": true, "parle": [["Salut ! Reste derrière la ligne jaune, s'il te plaît : Grand-Mère va bientôt taper.", "Bonne descente ! Tu viens voir la Forge ? Mets tes mains sur tes oreilles, c'est le seul conseil."],
			[["grandmere", "Qui est Grand-Mère ?", ["Le marteau-pilon, là, au fond ! Il tape lentement, très fort, et il ne se trompe jamais. Quand il tape, les tasses de La Marmite font « ding ». Honorine dit que c'est l'heure de la soupe."]],
			["metier", "C'est dur, d'être apprentie ?", ["Un peu ! Le soir, j'ai des bras en coton. Mais hier, j'ai forgé mon premier clou. Il est tordu comme un point d'interrogation. Maîtresse Brunehaut l'a gardé : elle dit que c'est le début d'une grande question."]]]]}],
	["forge", "garcon", Vector3(5.6, 0.05, 2.5), 90.0, "bricoler", [7.0, 18.0], ["Je règle la vapeur de Grand-Mère. Un quart de tour à gauche… Attention… BOUM ! Parfait.", "Tom dit que le marteau-pilon a du caractère. Moi, je dis qu'il a du rythme. Boum… boum… comme un cœur de géant."], {}],
	["forge", "homme", Vector3(0.6, 0.05, 10.9), 180.0, "bras_croises", [8.0, 19.0], ["J'attends les roues de mon wagonnet. Maîtresse Brunehaut a dit « dix minutes ». Chez elle, ça veut dire « après la soupe ».", "Mon grand-père achetait déjà ses rails ici. Et il riait déjà avec les Enclume."], {"vr": true}],
	["forge", "homme", Vector3(-9.0, 0.05, 10.5), 182.0, "marcher", [6.0, 18.0], ["Du charbon pour les fours ! Ils ont un appétit de dragon, ce matin.", "Un sac, deux sacs… Grand-Mère mange plus que tout le quartier réuni."],
		{"va": Vector3(-9.6, 0.05, -4.5), "porte": "sac"}],
	# --- La Marmite (+Z : la terrasse ; les tables vers (-4.5 + i*3, 5 ou 6.4), le comptoir en (3.6, 1.6))
	["marmite", "homme", Vector3(2.6, 0.05, 2.5), 300.0, "marcher", [7.0, 22.0], ["Chaud devant ! Bouillon des Strates pour la table deux !", "Une galette aux rouages, une ! Les rouages sont en sucre. Ne mordez pas trop fort quand même."],
		{"va": Vector3(-1.5, 0.05, 4.9), "porte": "plateau", "vr": true,
		"parle": [["Bonjour ! Assieds-toi où tu veux, sauf sur le banc du fond : c'est celui de Maîtresse Brunehaut, il est renforcé.", "Bonne descente ! Ici, on sert chaud, on sert vite, et on ressert si tu fais une petite mine."],
			[["menu", "Qu'est-ce qui est bon, aujourd'hui ?", ["Le bouillon des Strates, avec les champignons bruns de Bertille, et le chocolat des mineurs : épais comme une lampe de mine, doux comme un oreiller. Pas une goutte de boisson forte : Honorine dit qu'ici, on garde la tête claire et le pied sûr."]],
			["honorine", "Honorine est sévère ?", ["Sévère ? Elle ne laisse jamais personne repartir le ventre vide. Ce matin, elle a obligé un pigeon perdu, descendu par la cabine, à prendre une galette. Le pigeon a dit merci. Enfin, il a fait « rou ». C'est pareil."]]]]}],
	["marmite", "femme", Vector3(-4.14, 0.05, 4.05), 0.0, "manger", [11.5, 14.0], ["Le bouillon d'Honorine, c'est comme une couverture : on le prend à midi, et on a chaud jusqu'au soir.", "Je reprends une galette. C'est pour ma santé. Et pour la galette, qui avait l'air toute seule."], {}],
	["marmite", "homme", Vector3(4.14, 0.05, 5.45), 0.0, "manger", [11.0, 13.5], ["Remonté du fond de la mine à onze heures. Le casque, la lampe, et vite, la soupe !", "Ludovic compte ses mineurs le soir. Honorine compte nos bols à midi. On est très bien comptés, ici."], {"vr": true}],
	["marmite", "femme", Vector3(4.2, 0.05, 2.4), 180.0, "boire", [7.0, 21.0], ["Un chocolat des mineurs, s'il vous plaît, Honorine ! Avec la mousse en forme de pioche.", "Ce chocolat est si épais que la cuillère tient debout toute seule. C'est comme ça qu'on sait qu'il est bon."], {}],
	# --- l'Atelier des Lumières (+Z : devant ; le comptoir aux lanternes en (1.6, 1.6), l'établi dehors en (-3.4, 2.6))
	["lumieres", "homme", Vector3(1.2, 0.05, 2.6), 180.0, "pointer", [8.0, 20.0], ["Celle-ci, la bleue ! Non, celle-là, la violette ! Non… J'en prends deux. Une pour chaque humeur.", "Une lanterne à cristal, ça éclaire toute la nuit, sans flamme et sans fumée. Ma grand-mère disait que ça éclairait aussi les rêves."], {"vr": true}],
	["lumieres", "garcon", Vector3(-3.4, 0.05, 3.7), 180.0, "bricoler", [9.0, 18.0], ["Je suis apprenti chez la Docteure Opaline. Aujourd'hui, je polis des éclats. Doucement : un cristal, ça se vexe.", "La Docteure a encore perdu ses lunettes. Elles sont sur sa tête. Je ne dis rien : elle aime bien les chercher."], {}],
	["lumieres", "fille", Vector3(2.4, 0.05, 3.2), 180.0, "observer", [10.0, 19.0], ["Elles brillent toutes d'une couleur différente ! On dirait des bonbons qui font de la lumière.", "Quand je serai grande, j'aurai une lanterne violette. Pour lire sous la couverture sans que Maman le sache."], {}],
	# --- les Mines de Cristaux (repère au portail : +Z vers la caverne et le quai des wagonnets, la voie en x = 0 de z = 3 à 9 ; -Z dans la mine)
	["mines", "homme", Vector3(1.1, 0.05, 2.5), 0.0, "marcher", [6.0, 17.0], ["Un wagonnet de cristaux pour l'Atelier des Lumières ! Doucement : on ne secoue pas un cristal.", "Pousse, pousse… Ce wagonnet est plus têtu que la Vieille. Et la Vieille, c'est la roche."],
		{"va": Vector3(1.1, 0.05, 10.0), "porte": "caisse", "vr": true}],
	["mines", "homme", Vector3(-2.3, 0.05, 9.5), 180.0, "marcher", [6.5, 16.0], ["Les sacs d'éclats pour le tri ! Bonjour, la Vieille. Merci, la Vieille.", "Casque, lampe, sac. Et le sourire : Ludovic dit que ça éclaire aussi."],
		{"va": Vector3(-2.3, 0.05, 2.0), "porte": "sac"}],
	["mines", "femme", Vector3(2.6, 0.05, 5.0), 90.0, "bricoler", [7.0, 18.0], ["Je tamise les éclats : les gros pour les lanternes, les petits pour les bijoux, et la poussière pour les champignons de Bertille.", "Un cristal bleu, c'est de la lumière du Soleil de Laiton mise en conserve."],
		{"vr": true, "parle": [["Bonne descente ! Tu as un casque ? Non ? Ludovic va te voir. Ludovic voit toujours tout.", "Salut ! Attention au baquet : l'eau est froide, et les cristaux adorent éclabousser."],
			[["tamis", "Qu'est-ce que vous faites ?", ["Je lave et je trie les éclats qui sortent de la Grotte. Les beaux vont chez la Docteure Opaline, pour les lanternes. Les tout petits, je les garde pour Lumi, de la Fronde : elle en fait des bagues. Rien ne se perd, pas même une étincelle."]],
			["vieille", "Pourquoi tout le monde parle à la roche ?", ["Ludovic l'appelle la Vieille, et il lui dit bonjour, merci et pardon. Au début, on rit. Puis on remarque qu'elle ne craque jamais quand on est poli. Alors on est poli. On ne sait jamais."]]]]}],
	["mines", "vieux", Vector3(-4.2, 0.05, 2.0), 45.0, "bras_croises", [6.0, 14.0], ["Quatre mille deux cents jours sans accident. Ludovic a ajouté un jour au tableau ce matin. J'ai applaudi.", "À mon âge, je ne descends plus au fond. Je surveille les jeunes. Et les jeunes surveillent mon casque."], {}],
	# --- les Jardins des Champignons (repère du monde ; les planches de culture en x = -10, -4, 2, z = -2 ; l'étang au nord-est)
	["jardins", "homme", Vector3(-10.6, 0.05, -0.7), 180.0, "jardiner", [7.0, 18.0], ["Chut, ils poussent. Si on parle trop fort, ils poussent de travers.", "Un peu de terre noire, une goutte de cascade, et beaucoup de patience. Voilà toute la recette."],
		{"vr": true, "parle": [["Bonjour ! Marche sur les planches, s'il te plaît : les petits champignons dorment dans la terre.", "Bonne descente ! Tu viens voir briller les Jardins ? Reviens ce soir : ils s'allument tous d'un coup."],
			[["briller", "Pourquoi ils brillent ?", ["Ils boivent l'eau de la cascade et la lumière du Soleil de Laiton toute la journée, et la nuit, ils la rendent. Bertille dit que c'est leur façon de dire merci. Les bruns, eux, ne brillent pas : ils vont dans la soupe d'Honorine. Chacun son talent."]],
			["cascade", "D'où vient la cascade ?", ["C'est la pluie de Hautefond ! Elle traverse la roche et tombe ici, par une fissure de la voûte. Quand elle chante fort, on sait qu'il pleut en haut. Alors on plaint ceux d'en haut, et on arrose un peu moins."]]]]}],
	["jardins", "femme", Vector3(2.5, 0.05, -0.7), 180.0, "jardiner", [9.0, 19.0], ["Ce petit-là clignote quand je chante. Alors je chante. Faux, mais il ne dit rien.", "On ne cueille que ceux qui ne brillent plus. Les autres, on les laisse vivre leur vie lumineuse."], {}],
	["jardins", "homme", Vector3(0.6, 0.05, -8.5), 343.0, "marcher", [8.0, 17.0], ["Une caisse de champignons bruns pour La Marmite ! Honorine les attend pour le bouillon.", "Pardon, ça passe ! Ceux-là ne brillent pas, mais ils sentent bon."],
		{"va": Vector3(-2.6, 0.05, 2.0), "porte": "caisse"}],
	["jardins", "garcon", Vector3(-7.0, 0.05, 6.0), 304.0, "pointer", [10.0, 20.0], ["Regarde, le gros bleu ! Il est plus grand que Papa ! Et il brille plus que Papa.", "Bertille a dit de ne jamais manger un champignon qui brille. Même s'il te fait de l'œil. Celui-là me fait de l'œil."], {"vr": true}],
	["jardins", "fille", Vector3(-6.0, 0.05, 6.9), 300.0, "observer", [10.0, 20.0], ["Chut… Je compte les champignons qui s'allument. Trois cent douze. Trois cent treize…", "Celui-là est tout rose. Je l'appelle Gustave. Il a une tête de Gustave."], {}],
	# --- le quai du Petit Train (le quai : y = 0.45 ; -Z la voie, +Z la ville ; le banc en (-3, -0.9))
	["train", "homme", Vector3(1.0, 0.45, -0.6), 180.0, "debout", [7.0, 21.0], ["Le Petit Train fait le tour de la caverne en vingt minutes. Moi, je l'attends depuis vingt-cinq. C'est le charme des Strates.", "J'entends Bernadette siffler ! … Non, c'est la bouilloire de La Marmite."],
		{"porte": "valise", "vr": true, "parle": [["Bonjour ! Vous attendez Bernadette, vous aussi ? Elle est en retard. Elle a le droit : elle a cent ans.", "Bonne descente ! Restez derrière la ligne : Bernadette freine avec beaucoup d'enthousiasme."],
			[["bernadette", "Qui est Bernadette ?", ["La locomotive ! Verte et laiton, avec une cheminée qui fume des ronds. C'est Papy Ferdinand qui la conduit. Il lui parle tout le long du trajet, et elle répond en sifflant. Ils ne sont pas toujours d'accord."]],
			["ou", "Où allez-vous ?", ["Aux Jardins des Champignons, de l'autre côté de la caverne. Ce soir, ils s'allument tous en même temps, et j'ai promis à ma fiancée de les lui montrer. Elle croit qu'on va voir des champignons. Elle ne sait pas encore qu'il y aura aussi une bague."]]]]}],
	["train", "vieille", Vector3(-3.0, 0.45, -0.6), 0.0, "tricot", [8.0, 19.0], ["Une écharpe pour Papy Ferdinand. Il dit qu'il n'a jamais froid. Il a toujours froid.", "Je prends le train pour aller voir ma sœur, aux Galeries. À pied, c'est à dix minutes. Mais le train, c'est plus joli."], {}],
	["train", "garcon", Vector3(3.4, 0.45, -0.9), 180.0, "pointer", [9.0, 20.0], ["Coucou, Bernadette ! Coucou, Papy Ferdinand ! Il m'a vu ! Il a sifflé pour moi !", "Quand je serai grand, je conduirai Bernadette. Et je sifflerai devant chaque champignon."], {"vr": true}],
	["train", "homme", Vector3(-5.8, 0.45, 0.2), 180.0, "bras_croises", [6.5, 21.0], ["Le train de six heures quarante passe à six heures cinquante. Toujours. C'est l'heure des Strates.", "Je vais au dépôt voir Papy Ferdinand. Il m'a promis de me laisser tirer le sifflet. Un coup, pas plus."], {}],
	# --- la Galerie (la façade de la Maison de la Guilde ; +Z vers le vide, la galerie de z = 1 à 7)
	["galerie", "homme", Vector3(-1.5, 0.05, 1.6), 277.0, "marcher", [8.0, 19.0], ["Les registres de la Guilde ! Pardon, les registres passent !", "La Doyenne Agathe veut tout relire avant ce soir. Même les virgules."],
		{"va": Vector3(-9.5, 0.05, 2.6), "porte": "dossiers", "vr": true,
		"parle": [["Bonjour ! Commis de la Guilde, pour vous servir. Enfin, pour servir les registres. Mais je peux vous servir en passant.", "Bonne descente ! Vous êtes monté par le grand escalier ? Je compte les marches tous les jours. Il y en a toujours autant. C'est rassurant."],
			[["guilde", "À quoi sert la Guilde ?", ["La Guilde veille sur tout ce qui fait tenir les Strates : les étais des mines, les rails, les lanternes, l'eau de la cascade. La Doyenne Agathe signe tout, et elle lit tout. Même les petites lignes. Surtout les petites lignes."]],
			["fronde", "Et la Fronde ?", ["La Doyenne dit qu'elle la surveille de loin, avec fierté. Moi, j'y vais le soir écouter les Soupapes, avec mes registres sous le bras. Les Frondeurs disent que je danse comme un classeur. Je le prends comme un compliment."]]]]}],
	["galerie", "homme", Vector3(-10.5, 0.05, 6.8), 0.0, "observer", [18.0, 22.0], ["D'ici, on voit toute la caverne : la Place, la Forge, et le Petit Train qui fait le tour comme un jouet.", "Vingt heures : le lampiste tourne la manivelle. Quarante tours. Regarde, le Soleil de Laiton devient tout ambré."], {}],
	["galerie", "vieille", Vector3(10.2, 0.05, 6.9), 0.0, "observer", [17.0, 22.0], ["Chaque soir, je regarde le Soleil de Laiton baisser sa lampe. Chez nous, c'est ça, le coucher de soleil. Et il ne s'en va jamais.", "Là-bas, les Jardins s'allument. Bleu, vert, rose… On dirait que la caverne met ses bijoux."], {"vr": true}],
	# --- le Pont des Frondeurs (+Z : le long du pont, vers la Fronde ; le tablier de x = -1.5 à 1.5)
	["pont", "vieux", Vector3(-1.0, 0.05, -3.0), 270.0, "observer", [10.0, 20.0], ["Je ne regarde pas en bas. … J'ai regardé en bas. Il y a une rivière qui brille, tout au fond !", "On m'a dit : « Dis bonjour au Gouffre, il répond trois fois. » Bonjour ! … Bonjour… bonjour… bonjour. C'est vrai !"], {"vr": true}],
	["pont", "fille", Vector3(1.05, 0.05, 2.5), 90.0, "pointer", [10.0, 19.0], ["Coucou, la rivière ! Elle brille en bleu, comme les cheveux d'Écho !", "Ressort traverse le Pont en skate. Moi, je le traverse en sautillant. C'est plus musical."], {}],
	["pont", "homme", Vector3(0.3, 0.05, 5.6), 180.0, "marcher", [10.0, 22.0], ["Une caisse de boulons pour la Grande Forge ! Maîtresse Brunehaut nous a prêté ses pinces : on lui rend des boulons. Salut, camarade !", "Ce pont, Rivet et Bielle en ont resserré chaque boulon. Il chante quand on marche dessus. En rythme."],
		{"va": Vector3(0.3, 0.05, -5.6), "porte": "caisse"}],
	# --- la Place Libre (repère du monde, au centre des ronds peints)
	["place_libre", "homme", Vector3(5.5, 0.05, -6.0), 318.0, "violon", [16.0, 23.0], ["♪ Un boulon, deux boulons, le Pont tient bon… ♪ Les paroles sont de Bielle. La fausse note est de moi.", "Ici, on joue à prix libre. On me paie en sourires. J'ai les poches pleines."], {"vr": true}],
	["place_libre", "garcon", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [10.0, 20.0], ["On fait le tour du rond violet sans marcher sur le turquoise ! Celui qui marche dessus devient une chaudière !", "Je suis une locomotive ! Tchou-tchou ! … Pardon, Bernadette."], {"rond": [4.0, 1.4], "vr": true}],
	["place_libre", "fille", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [10.0, 20.0], ["Attrape-moi ! Je suis le Gouffre : je réponds trois fois ! Ha ! Ha ! Ha !", "Brasero dit que la Place Libre est à tout le monde. Alors aujourd'hui, elle est à nous."], {"rond": [4.0, 1.4], "phase": 3.1}],
	# --- la Scène des Soupapes (+Z : vers la fosse ; la scène de z = -7 à 0, à 1,1 m de haut ; la fosse vers z = 4 à 7)
	["scene", "femme", Vector3(-3.0, 0.05, 5.3), 180.0, "danse", [19.5, 23.5], ["Les Soupapes ! Les Soupapes ! … Bielle m'a regardée ! Enfin, elle a regardé par ici.", "Quand l'orgue à vapeur fait « pouêêt », tout le monde lève les bras. C'est la règle. Il n'y en a pas d'autre."],
		{"vr": true, "parle": [["Salut, camarade ! Viens danser ! Ici, on saute, on tombe, et on se relève les uns les autres.", "Tu entends la basse d'Écho ? Elle fait trembler les guirlandes. Et mes genoux."],
			[["soupapes", "Qui sont les Soupapes ?", ["Rivet à la batterie, Bielle au chant et à la guitare, Écho à la basse ! Le jour, Rivet et Bielle réparent les rails ; le soir, ils font trembler la caverne. Et l'orgue à vapeur de Bricole joue tout seul, sur des cartes perforées. Lui, il ne rate jamais son entrée. Les autres, parfois."]],
			["danser", "Comment on danse, ici ?", ["Facile ! On saute, on tourne, on lève les bras. Si quelqu'un tombe, tout le monde l'aide à se relever. Et si c'est toi qui tombes, tu dis « même pas mal », comme Ressort. Ça marche presque toujours."]]]]}],
	["scene", "homme", Vector3(0.0, 0.05, 5.0), 180.0, "danse", [19.5, 23.5], ["Encore une ! Encore une ! … Ils en jouent toujours une de plus. C'est voté.", "Je danse comme un rail tordu. Rivet dit que c'est un style. Je le crois."], {}],
	["scene", "homme", Vector3(3.0, 0.05, 5.4), 180.0, "danse", [20.0, 23.5], ["Je suis descendu d'en haut exprès pour le concert. J'ai mis mon chapeau du dimanche. Il est déjà tout de travers.", "Ces gens dansent comme des pistons ! Je veux être un piston !"], {}],
	["scene", "garcon", Vector3(-1.6, 0.05, 7.4), 180.0, "applaudir", [19.5, 22.0], ["Bravo ! Bravo ! Plus fort, Rivet !", "Maman a dit : au lit à vingt-deux heures. Il me reste encore trois chansons."], {}],
	["scene", "homme", Vector3(2.9, 1.15, -6.4), 180.0, "bricoler", [13.0, 19.0], ["J'accorde l'orgue à vapeur. Un tuyau chante faux… Ah non, c'est moi qui chante faux.", "Ce soir, l'orgue joue une nouvelle carte perforée de Bricole. Elle a fait tous les trous à la main. Il y en a deux mille."], {}],
	# --- la Cantine Libre (repère du monde, au mât du parachute ; les tables vers (±3.5, ±2.4), la cuisine vers (-1, -6.8))
	["cantine", "homme", Vector3(-0.6, 0.05, -5.4), 347.0, "marcher", [11.0, 22.0], ["Potée chaude ! Prix libre ! Ici, tu paies ce que tu peux, même zéro, même un sourire !", "Mémé Gamelle dit que sa louche s'appelle Excalibur. Moi, je dis surtout qu'elle est très lourde."],
		{"va": Vector3(-1.6, 0.05, -1.0), "porte": "plateau", "vr": true,
		"parle": [["Salut, camarade ! Assieds-toi où tu veux : ici, chaque table est la table de tout le monde.", "Tu as faim ? Ne réponds pas : Mémé Gamelle le voit déjà. Elle repère les ventres vides à vingt mètres."],
			[["prix", "Combien ça coûte ?", ["Prix libre ! Tu mets ce que tu peux dans la boîte. Si tu ne peux rien, tu mets un merci. Et si tu peux beaucoup, tu paies le bol de quelqu'un d'autre. C'est la seule règle que l'Assemblée n'a jamais osé voter : elle était là avant."]],
			["menu", "Qu'est-ce qu'il y a au menu ?", ["La potée de Mémé Gamelle, le pain de chaudière, des galettes et la limonade du Gouffre. Les légumes viennent des Jardins par le Petit Train, puis Ressort finit la livraison en skate. Les carottes arrivent un peu étourdies, mais elles arrivent."]]]]}],
	["cantine", "femme", Vector3(-2.98, 0.05, 3.35), 180.0, "manger", [11.5, 14.0], ["La potée de Mémé Gamelle ! Le fond de la marmite, c'est le meilleur : c'est là que les champignons se racontent leurs histoires.", "Mange tes carottes, mon cœur. Elles ont traversé toute la caverne pour toi. En skate."], {}],
	["cantine", "garcon", Vector3(-4.02, 0.05, 1.45), 0.0, "manger", [11.5, 14.0], ["Je peux avoir un deuxième pain de chaudière ? Il est en forme d'engrenage ! On peut le faire rouler !", "Maman, la limonade du Gouffre fait des bulles qui remontent par le nez !"], {"vr": true}],
	["cantine", "vieux", Vector3(4.02, 0.05, -1.45), 180.0, "manger", [18.0, 21.5], ["Je mange tôt, et après, je vais au concert. À mon âge, on danse assis. Mais on danse.", "Cinquante ans que je mange ici. Mémé Gamelle m'appelle encore « mon caillou ». Je suis un très vieux caillou."], {}],
	# --- l'Atelier Libre (repère du monde ; les conteneurs vers (-3, -4) et (4.5, -2), l'établi vers (-2, 0.5))
	["atelier_libre", "homme", Vector3(-3.2, 0.05, 1.45), 180.0, "bricoler", [10.0, 19.0], ["Un grille-pain qui fait aussi radio. Il grille le pain en musique. Pour l'instant, il grille surtout la musique.", "La règle de l'Atelier : tu prends un outil, tu répares, tu remets l'outil. La troisième partie est la plus difficile."],
		{"vr": true, "parle": [["Salut, camarade ! Tu as un truc cassé ? Pose-le là, on va le réparer ensemble. Ensemble, c'est-à-dire toi, moi et beaucoup de ruban adhésif.", "Attention, ça va faire… (PSCHIT !) … Voilà. Bonjour !"],
			[["reparer", "Qu'est-ce que vous réparez ?", ["Tout ! Hier : un parapluie, deux lanternes, une bouilloire qui sifflait trop fort, et le skate de Ressort, pour la troisième fois de la semaine. Ici, rien ne se jette : tout se répare, ou devient autre chose. Mon parapluie est devenu un abat-jour. Il a l'air très content."]],
			["bricole", "Qui est Bricole ?", ["L'inventrice de l'Atelier ! C'est elle qui a construit l'orgue à vapeur de la Scène, avec des tuyaux de récup'. Elle dit « c'est impossible » avant chaque invention. Après, elle la construit. Alors quand elle dit « c'est impossible », on sort les outils."]]]]}],
	["atelier_libre", "femme", Vector3(2.65, 0.05, 3.3), 90.0, "bricoler", [11.0, 20.0], ["Je fabrique un vélo avec deux roues de wagonnet. Il ne roule pas encore. Mais il est magnifique à l'arrêt.", "Une soudure, une chanson. Une soudure, une chanson. C'est la méthode de la Fronde."], {}],
	["atelier_libre", "homme", Vector3(-6.2, 0.05, 3.0), 90.0, "marcher", [10.0, 18.0], ["Des pièces de récup' pour l'établi ! Elles ont l'air cassées, mais elles sont juste en vacances.", "Pardon, ça passe ! Cette caisse contient trois boulons, un ressort et beaucoup d'espoir."],
		{"va": Vector3(-0.6, 0.05, 2.9), "porte": "caisse"}],
	# --- le Troc (le repère du conteneur : +Z devant ; le comptoir en (-1, 2.6), l'établi des bijoux en (2.4, 3.6))
	["troc", "femme", Vector3(-1.3, 0.05, 3.7), 180.0, "debout", [11.0, 20.0], ["J'échange une théière sans couvercle contre un couvercle sans théière. Lumi dit que c'est le troc parfait.", "Une bague en boulon ! Elle brille comme un cristal. Et elle ne coûte qu'une histoire."], {"vr": true}],
	["troc", "fille", Vector3(2.4, 0.05, 4.5), 180.0, "pointer", [10.0, 19.0], ["Celui-là ! Le collier avec le cristal bleu ! Comme celui d'Ysaé !", "Je peux l'échanger contre mon caillou porte-bonheur ? Il est très rond. Il porte vraiment bonheur."], {}],
	["troc", "homme", Vector3(-5.5, 0.05, 5.0), 116.0, "marcher", [10.0, 21.0], ["Un sac de trésors pour Lumi ! Enfin, de la ferraille. Mais chez Lumi, c'est pareil.", "J'apporte des boutons. Lumi fait des merveilles avec les boutons."],
		{"va": Vector3(-2.6, 0.05, 3.6), "porte": "sac"}],
	# --- l'Assemblée (repère du monde, au brasero ; les six canapés à 4,6 m)
	["assemblee", "vieille", Vector3(0.37, 0.0, 4.53), 193.0, "tricot", [10.0, 19.0], ["Je tricote une écharpe pour le brasero. Il n'en a pas besoin. Mais tout le monde mérite une écharpe.", "Aujourd'hui, on vote la couleur du nouveau canapé. J'ai voté « confortable »."], {"vr": true}],
	["assemblee", "homme", Vector3(-2.86, 0.0, 3.54), 133.0, "assis", [10.0, 23.0], ["Je prends la parole ! … Ah non, il faut d'abord la clé de parole. Brasero, tu me passes la clé ?", "Ici, on prend le temps de penser avant de parler. Je pense depuis ce matin. J'ai presque fini."],
		{"parle": [["Salut, camarade ! Assieds-toi. Le canapé bleu est le moins défoncé. Enfin, après le vert. Non, avant.", "Bienvenue à l'Assemblée ! Ici, tout le monde a le droit de parler. Pas tous en même temps. Enfin, on essaie."],
			[["assemblee", "Comment marche l'Assemblée ?", ["On s'assoit en rond autour du brasero, et celui qui tient la clé de parole parle. Les autres écoutent. Ensuite, on vote. Ensuite, on revote, parce que Rivet n'écoutait pas. À la fin, tout le monde est d'accord, ou au moins tout le monde a goûté."]],
			["vote", "Qu'est-ce qu'on vote, aujourd'hui ?", ["Trois choses : la couleur des nouvelles guirlandes, l'heure du goûter des enfants, et si Ressort a le droit de traverser le Pont en skate. Les guirlandes et le goûter, c'est facile. Ressort, ça fait trois ans qu'on en discute."]]]]}],
	["assemblee", "femme", Vector3(-0.36, 0.0, -4.53), 13.0, "assis", [14.0, 23.0], ["Je propose qu'on repeigne le Pont en violet. … Personne n'a dit non. Ça veut dire oui, ici ?", "Le brasero ronronne. Brasero aussi. On ne sait jamais lequel des deux s'est endormi."], {}],
	["assemblee", "garcon", Vector3(2.86, 0.0, -3.54), 313.0, "assis", [14.0, 20.0], ["Moi aussi, j'ai le droit de voter ! Je vote pour deux goûters par jour.", "Un jour, j'ai tenu la clé de parole ! J'ai dit « bonjour ». Tout le monde a applaudi."], {"vr": true}],
	# --- le Skatepark (repère du monde, au milieu de la funbox)
	["skate", "garcon", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [10.0, 20.0], ["L'échauffement : trois tours en courant, et après, la planche ! Ressort dit que c'est le secret.", "Tu as vu Ressort sur la rampe ? Boïng ! Un jour, je ferai pareil. Avec moins de bleus."], {"rond": [5.8, 2.2], "vr": true}],
	["skate", "fille", Vector3(0.0, 0.05, 0.0), 0.0, "marcher", [11.0, 19.0], ["Je cours pour m'échauffer ! Après, je monte sur la grande rampe. Enfin, sur le bas de la grande rampe.", "Si je tombe, je dirai « même pas mal ». Ça marche presque toujours."], {"rond": [5.8, 2.2], "phase": 3.1}],
	["skate", "femme", Vector3(3.5, 0.05, -6.0), 330.0, "applaudir", [12.0, 21.0], ["Bravo ! Bravo ! … Il est tombé. Bravo quand même !", "Je viens applaudir tous les après-midi. Ici, on applaudit aussi les chutes. Surtout les belles."], {}],
	# --- le Mur des Fresques (repère du monde ; les fresques au nord, la première vers (-5, -8.5), la deuxième vers (5, -5))
	["fresques", "femme", Vector3(-3.24, 0.05, -6.58), 165.0, "peindre", [10.0, 19.0], ["Un peu de bleu pour la rivière du Gouffre, un peu d'orange pour la crête de Brasero…", "Fusain m'a dit : « Peins ce que tu aimes, et le mur s'occupera du reste. » Le mur fait très bien son travail."],
		{"vr": true, "parle": [["Salut, camarade ! Ne bouge pas… Voilà, tu es sur le Mur. Tout petit, dans un coin. Avec un chapeau.", "Attention, la peinture est fraîche ! Et moi aussi, j'ai du bleu sur le nez."],
			[["mur", "Que racontent les fresques ?", ["L'histoire de la Fronde ! Là, Brasero et ses trois amis qui arrivent avec une brouette et un feu. Ici, la première Assemblée. Et là-bas, les Soupapes, avec Rivet qui tape si fort qu'on a peint des étoiles autour de sa tête."]],
			["couleurs", "Pourquoi certaines couleurs brillent ?", ["C'est un secret des Jardins des Champignons ! Fusain y va souvent, et depuis, nos fresques brillent un peu la nuit. Bertille ne dit rien. Fusain non plus. Moi, je fais semblant de ne pas savoir."]]]]}],
	["fresques", "homme", Vector3(-7.49, 0.05, -7.71), 165.0, "peindre", [12.0, 20.0], ["Je peins une baleine qui chante. Je ne l'ai jamais vue. Mais je l'ai beaucoup imaginée.", "Mon pinceau, c'est un vieux balai coupé. Il peint large, et il a le sens de l'humour."], {}],
	["fresques", "vieux", Vector3(-1.5, 0.05, -1.5), 207.0, "observer", [10.0, 20.0], ["Là, en haut à gauche : c'est moi, il y a cinquante ans. J'avais une crête verte. Et des cheveux.", "Chaque fois que je viens, il y a quelque chose de nouveau sur le Mur. Il grandit plus vite que mes petits-enfants."], {}],
	["fresques", "garcon", Vector3(6.5, 0.05, 1.2), 194.0, "pointer", [11.0, 19.0], ["Regarde, le skate avec des flammes ! C'est Ressort qui l'a dessiné ! Enfin, les flammes, c'est Fusain.", "Quand je serai grand, je peindrai un dragon sur toute la paroi. Un gentil. Qui fait du skate."], {}],
]


func build(owner: Node) -> void:
	owner_hf = owner
	main = owner.main
	pc = owner.pc
	name = "Activite_strates_v118"
	style = "strates"
	prefix = "st118_"
	var st: Node = owner.strates
	_rng.seed = 118118
	for k in st.cadres118:
		cadres[k] = st.cadres118[k]
	for k2 in st.fronde.cadres118:
		cadres[k2] = st.fronde.cadres118[k2]
	for k3 in cadres:
		var g: String = _groupe(str(k3))
		if not centres.has(g):
			centres[g] = (cadres[k3] as Transform3D).origin
	# les Frondeurs ont leur allure à eux
	var postes: Array = []
	for e in POSTES118:
		var e2: Array = (e as Array).duplicate()
		if str(e2[0]) in FRONDE:
			var opts: Dictionary = (e2[7] as Dictionary).duplicate() if e2.size() > 7 else {}
			if not opts.has("style"):
				opts["style"] = "fronde"
			if e2.size() > 7:
				e2[7] = opts
			else:
				e2.append(opts)
		postes.append(e2)
	_decors118(st.kit)
	print("ILE_MANGA_V118: %d travailleurs et visiteurs dans les lieux des Strates et de la Fronde" % _poster(postes))


## Les Strates sont sous terre : personne tant qu'elles ne sont pas affichées (à la surface, au Dôme).
func _cache() -> bool:
	return owner_hf.strates == null or not (owner_hf.strates as Node3D).is_visible_in_tree()


# =================================================================== les décors

func _decors118(kit) -> void:
	# la Grande Forge : le tas de charbon et ses sacs, au fond à gauche, au bout du chemin du porteur
	if cadres.has("forge"):
		var fo: Transform3D = cadres["forge"]
		for k in range(6):
			kit.cyl(fo * T(-10.6 - (k % 2) * 0.5, 0.0, -5.1 - floorf(k / 2.0) * 0.55), 0.22, 0.26, 0.55, "cuir71", 10)
		kit.ball(fo * T(-10.3, 0.0, -6.45), 0.6, "tole114_noir", 8, 4)
		kit.col_box(fo * T(-10.65, 0.4, -5.85), Vector3(1.5, 0.8, 2.1))
	# les Mines : le baquet du tamiseur (l'eau, le tamis de laiton) et la planche des cristaux triés
	if cadres.has("mines"):
		var mx: Transform3D = cadres["mines"]
		var bq: Vector3 = mx * Vector3(3.45, 0.0, 5.0)
		kit.cyl(Transform3D(Basis(), bq), 0.48, 0.42, 0.5, "bois112", 14)
		kit.disc(Transform3D(Basis(), bq + Vector3.UP * 0.44), 0.42, "eau114", 14)
		kit.ring(Transform3D(Basis(), bq + Vector3.UP * 0.5), 0.34, 0.42, 0.04, "laiton112", 14)
		kit.col_cyl(bq, 0.5, 0.55)
		var pl: Transform3D = mx * T(3.4, 0.0, 6.3)
		kit.box(pl * T(0, 0.5, 0), Vector3(0.9, 0.06, 0.5), "bois112", 1.0)
		for s in [-1.0, 1.0]:
			kit.box(pl * T(s * 0.38, 0.24, 0), Vector3(0.06, 0.48, 0.42), "bois112", 1.0)
		for k2 in range(5):
			kit.ball(pl * T(-0.32 + k2 * 0.16, 0.57, 0.05 * (k2 % 2)), 0.045, "cristal114", 6, 3)
		kit.col_box(pl * T(0, 0.3, 0), Vector3(0.9, 0.6, 0.5))
	kit.commit()

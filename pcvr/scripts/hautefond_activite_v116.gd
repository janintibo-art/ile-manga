extends Node3D
## V116 : la vie dans les grands lieux ouverts de Hautefond. Chacun a ses travailleurs et ses
## visiteurs (en plus des habitants qui y passent), et ce qu'il faut pour travailler :
##  - l'Hôtel de Ville : le guichet des formulaires et sa file d'attente, deux commis à leurs bureaux
##    (et un visiteur), l'huissier à l'entrée, le coursier qui porte les dossiers au Bourgmestre ;
##    la nuit, le veilleur qui somnole près de la porte ;
##  - la Bibliothèque des Cartes : des lecteurs aux tables (l'un s'est endormi sur son atlas), la
##    cartographe à sa table à dessin, un enfant au grand globe, l'aide-bibliothécaire et son chariot ;
##  - le Piston Joyeux : des clients au comptoir et aux tables, le serveur et son plateau, le
##    violoneux près de la cheminée, un grand-père qui somnole dans son fauteuil ;
##  - le Grand Marché : les marchands des deux derniers étals, des clients devant les étals, la
##    chanteuse de la fontaine, le porteur et ses cageots, des enfants qui jouent autour de la fontaine ;
##  - la Forge à vapeur : l'apprenti au soufflet, l'apprentie du marteau-pilon, un client qui attend,
##    le porteur de charbon ;
##  - le lavoir : les lavandières, leurs paniers, le linge qui sèche (et qui bouge au vent) ;
##  - le hall de la Colonne : les voyageurs et leurs valises qui font la queue au guichet, le porteur
##    de bagages ;
##  - le Port des Cordages : les dockers et leurs caisses, le marin qui love les cordages.
## Ils n'existent que près du joueur (moins de 55 m du lieu) et aux heures où le lieu vit ; en VR,
## moins de monde. Chacun a ses petites phrases ; quelques-uns parlent (« E : parler à … »).
## Les repères des lieux : hautefond_ville_v112.cadres116 et hautefond_dehors_v112.cadres116 (+Z :
## vers la rue ou la porte, comme les façades).

const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const PRES: float = 55.0                 # on fait venir les gens d'un lieu en deçà
const LOIN: float = 70.0                 # on les renvoie au-delà
## Les postes : [lieu, rôle, position (repère du lieu), yaw (degrés, 0 : regarde +Z), pose, [h0, h1],
## phrases, options]. options : « va » (l'autre bout de son aller-retour), « rond » ([rayon, vitesse] :
## il tourne autour de sa position), « porte » (ce qu'il porte), « vr » (gardé en VR), « parle »
## ([accueil, [[id, question, [réponses]], …]]).
const POSTES := [
	# --- l'Hôtel de Ville
	["mairie", "femme", Vector3(-8.7, 0.1, -6.0), 90.0, "comptoir", [8.0, 18.0], ["Formulaire bleu pour une demande, rose pour une réclamation, vert pour se plaindre du formulaire rose.",
		"Suivant ! … Ah non, c'est encore vous.", "Tamponné ! Signez ici, ici, et là. Non, pas là : là."],
		{"vr": true, "parle": [["Bonjour ! Guichet des formulaires de Hautefond. Que puis-je faire pour vous ? Attention : chaque question a son formulaire."],
			[["form", "J'ai besoin d'un formulaire.", ["Très bien ! Il vous faut d'abord le formulaire pour demander un formulaire. C'est le jaune. Il est en rupture depuis mardi.",
				"Pour quoi faire ? Ah, vous ne savez pas encore ? Alors c'est le formulaire « Je ne sais pas encore ». Le plus demandé."]],
			["file", "Pourquoi tant de monde ?", ["Le Bourgmestre a décidé que les pigeons de la Place auraient un permis. Tout le monde veut déclarer le sien.",
				"Lundi, c'est le jour des réclamations. Mardi aussi. En fait, tous les jours."]]]]}],
	["mairie", "vieux", Vector3(-6.95, 0.1, -6.05), -90.0, "bras_croises", [8.0, 18.0], ["Ça fait trois fois que je reviens. Le formulaire rose était bleu.", "De mon temps, on s'expliquait d'homme à homme. Et on remplissait quand même un formulaire."], {"vr": true}],
	["mairie", "femme", Vector3(-6.15, 0.1, -6.2), -95.0, "debout", [8.5, 17.5], ["Je viens déclarer mon pigeon. Il s'appelle Bernard.", "Si la file avance encore d'un pas, je chante."], {}],
	["mairie", "garcon", Vector3(-5.35, 0.1, -5.9), -80.0, "pointer", [9.0, 17.0], ["Maman, c'est quand notre tour ?", "J'ai compté les dalles du sol : cent quarante-deux. Et une cassée."], {}],
	["mairie", "homme", Vector3(7.7, 0.1, -4.5), -90.0, "lire", [8.0, 18.0], ["Registre des naissances, des mariages… et des pigeons.", "Qui a encore pris ma plume ? Ah, je l'ai derrière l'oreille."],
		{"vr": true, "parle": [["Bonjour. Commis aux registres. Si c'est pour un pigeon, c'est au guichet, à gauche. Si c'est pour autre chose, c'est aussi au guichet."],
			[["registre", "Qu'est-ce que vous écrivez ?", ["Tout ce qui se passe à Hautefond. Hier : une cabine en avance, deux mariages, et un chapeau perdu au Belvédère. Il volait encore à midi.",
				"Le registre des inventions de la ville. Ce matin : une bouilloire qui siffle « La Marche des Liftiers ». Brevet accordé."]]]]}],
	["mairie", "femme", Vector3(7.7, 0.1, -8.5), -90.0, "lire", [8.0, 18.0], ["Les archives… Je classe les classeurs.", "Encore un tampon, et j'ai le record de la semaine."], {}],
	["mairie", "homme", Vector3(5.9, 0.1, -4.6), 90.0, "bras_croises", [9.0, 17.0], ["Je voudrais simplement changer le nom de ma rue. Elle s'appelle « Rue en Pente ». Elle n'est pas en pente.", "Oui, j'attends. Non, je ne suis pas pressé. Si, un peu."], {}],
	["mairie", "homme", Vector3(1.9, 0.1, -1.4), 0.0, "mains_dos", [8.0, 18.0], ["Bienvenue à l'Hôtel de Ville. Essuyez vos bottes, la vapeur salit tout.", "Le Bourgmestre reçoit… quand il ne fait pas de discours."], {"vr": true}],
	["mairie", "garcon", Vector3(-4.6, 0.1, -7.6), 0.0, "marcher", [8.0, 18.0], ["Dossier urgent ! Pardon ! Dossier urgent !", "Le Bourgmestre veut sa tasse. Et ses lunettes. Et son autre tasse."],
		{"va": Vector3(1.9, 0.1, -9.9), "porte": "dossiers"}],
	["mairie", "vieux", Vector3(-2.0, 0.1, -1.3), 30.0, "dormir_assis", [19.0, 7.0], ["Zzz… halte-là… qui va là… zzz…", "Zzz… Je ne dors pas, je veille… les yeux fermés…"], {"vr": true, "siege": true}],
	# --- la Bibliothèque des Cartes
	["bibliotheque", "femme", Vector3(-0.9, 0.1, -4.15), 180.0, "lire", [9.0, 19.0], ["Chut…", "Cette carte montre une île qui n'existe pas. Ou pas encore."], {"vr": true, "siege": true}],
	["bibliotheque", "homme", Vector3(0.9, 0.1, -5.85), 0.0, "lire", [9.5, 18.5], ["L'Atlas des Vents, tome trois. Le tome deux s'est envolé.", "Fascinant : les Strates ont des rues sous les rues."], {"siege": true}],
	["bibliotheque", "vieille", Vector3(-0.8, 0.1, -8.15), 180.0, "lire", [10.0, 18.0], ["Je relis ce livre pour la quarantième fois. Il finit toujours bien.", "Ah, la carte de ma jeunesse ! Il y avait une île de plus, à l'époque."], {"siege": true}],
	["bibliotheque", "homme", Vector3(0.9, 0.1, -9.85), 0.0, "dormir_assis", [11.0, 18.0], ["Zzz… cap au nord… zzz…", "Zzz… page cent douze… zzz…"], {"vr": true, "siege": true}],
	["bibliotheque", "femme", Vector3(-4.6, 0.1, -3.35), 180.0, "peindre", [9.0, 18.0], ["Un trait pour la côte, un point pour le phare…", "Je dessine la Cité des Nuées. Elle n'arrête pas de bouger !"],
		{"vr": true, "parle": [["Bonjour ! Je suis cartographe : je dessine Hautefond, rue par rue. C'est la ville la plus difficile à dessiner : elle a des étages."],
			[["carte", "Qu'est-ce que vous dessinez ?", ["La nouvelle carte des Strates et du Dôme d'Azur. Avant, il n'y avait rien sous la ville, sur les cartes. Maintenant, il y a tout !",
				"Les Vergers en terrasses. Chaque terrasse a sa couleur. Le Père Bastien voulait que je dessine aussi chaque pomme. J'ai refusé poliment."]],
			["dur", "C'est difficile ?", ["Le plus dur, c'est la Colonne : elle est si haute qu'elle dépasse toujours de la feuille.",
				"Le plus dur, c'est l'Albatros : il ne reste jamais au même endroit sur la carte."]]]]}],
	["bibliotheque", "fille", Vector3(-3.0, 0.1, -10.8), -125.0, "pointer", [10.0, 18.0], ["Là ! C'est là qu'on habite !", "Le globe tourne, mais nous, on ne tombe pas. C'est magique."], {}],
	["bibliotheque", "garcon", Vector3(4.6, 0.1, -5.6), 180.0, "marcher", [9.0, 19.0], ["Je range… je range… Qui a mis le Dictionnaire des Nuages avec les livres de cuisine ?", "Pardon, chariot qui passe !"],
		{"va": Vector3(4.6, 0.1, -12.0), "porte": "chariot", "vr": true}],
	# --- le Piston Joyeux
	["taverne", "homme", Vector3(-4.3, 0.1, -11.25), 180.0, "boire", [8.0, 23.0], ["Une limonade à la vapeur, Firmin ! Avec le petit sifflet !", "Ce chocolat chaud, c'est un câlin dans une tasse."], {"vr": true}],
	["taverne", "femme", Vector3(-1.7, 0.1, -11.2), 200.0, "rire", [10.0, 22.0], ["Ha ha ! Et la cabine est repartie sans lui !", "Firmin, ta machine a encore sifflé l'heure du goûter à midi !"], {}],
	["taverne", "homme", Vector3(1.8, 0.1, -5.45), 0.0, "manger", [11.0, 21.0], ["La tourte de Firmin. Je la mange lentement : comme ça, elle dure plus longtemps.", "Mmh… Ça sent la cannelle et la vapeur."], {"siege": true, "vr": true}],
	["taverne", "femme", Vector3(3.1, 0.1, -5.45), 0.0, "rire_assis", [11.0, 22.0], ["Et là, Barnabé a crié « Tout le monde descend ! » au premier étage !", "Je ris, mais j'ai le vertige rien que d'y penser."], {"siege": true}],
	["taverne", "vieux", Vector3(-2.56, 0.1, -5.95), 0.0, "assis", [9.0, 20.0], ["La pluie tombe de bas en haut, aujourd'hui. C'est la vapeur.", "Encore un chocolat, et je rentre. Ça fait trois fois que je le dis."], {"siege": true}],
	["taverne", "vieille", Vector3(3.06, 0.1, -9.05), 180.0, "tricot", [9.0, 20.0], ["Une écharpe pour mon petit-fils. Il est liftier : il a toujours froid au cou.", "Une maille à l'endroit, une maille à l'envers… comme la cabine."], {"siege": true, "vr": true}],
	["taverne", "garcon", Vector3(-0.4, 0.1, -10.9), 0.0, "marcher", [8.0, 23.0], ["Chaud devant ! Chocolat qui passe !", "Table trois, deux limonades ; table un, un sourire."],
		{"va": Vector3(1.0, 0.1, -7.0), "porte": "plateau", "vr": true,
		"parle": [["Bonjour ! Je sers ici avec Firmin. Ce soir, la spécialité, c'est le chocolat qui siffle. Il siffle parce qu'il est content d'être bu."],
			[["quoi", "Qu'est-ce qui est bon, ici ?", ["Tout ! Mais surtout la tourte aux pommes des Vergers, et le chocolat à la vapeur. Avec de la crème, si vous êtes sage.",
				"La limonade à la vapeur : elle pique le nez et fait des bulles dans les oreilles."]],
			["machine", "Et cette grande machine ?", ["La machine à chocolat ! Quand elle siffle, il est quatre heures. Même quand il n'est pas quatre heures. Elle a son caractère.",
				"Firmin l'a construite lui-même. Elle a trois cadrans, deux sifflets et un seul défaut : elle est jalouse des théières."]]]]}],
	["taverne", "homme", Vector3(5.3, 0.1, -5.6), -115.0, "violon", [17.0, 23.0], ["Une valse pour les liftiers ! Un, deux, trois… et on monte !", "Cette chanson parle d'un dirigeable amoureux d'un nuage. Elle finit en pluie."], {"vr": true}],
	["taverne", "vieux", Vector3(5.3, 0.1, -9.9), -70.0, "dormir_assis", [13.0, 22.0], ["Zzz… encore un chocolat… zzz…", "Zzz… la cabine… plus vite… zzz…"], {"siege": true, "fauteuil": true}],
	# --- le Grand Marché (les étals : etal_0 à etal_5 ; le marché : la fontaine)
	["etal_4", "homme", Vector3(0, 0.05, -2.0), 0.0, "comptoir", [7.0, 19.0], ["Des pommes des Vergers ! Croquantes comme des engrenages neufs !", "Approchez ! Trois poires pour le prix de deux, et la troisième est gratuite !"],
		{"vr": true, "parle": [["Bonjour ! Fruits et légumes des Vergers, cueillis ce matin par le Père Bastien lui-même. Il leur a dit au revoir un par un."],
			[["prix", "Combien, les pommes ?", ["Une pièce les trois. Ou un sourire les deux. Mais avec un sourire, je n'ai pas de monnaie.",
				"Pour vous, c'est le prix d'ami : une pièce. Pour les mouettes, c'est gratuit, mais elles ne demandent pas."]]]]}],
	["etal_5", "femme", Vector3(0, 0.05, -2.0), 0.0, "comptoir", [7.0, 19.0], ["Du miel des terrasses ! Les abeilles ont le vertige, mais pas le miel !", "Confitures de mûres, de prunes, et de rouages… non, je plaisante, pas de rouages."], {}],
	["etal_0", "vieille", Vector3(0.4, 0.05, 1.1), 180.0, "pointer", [8.0, 18.0], ["Rosalie, c'est la cannelle de la semaine dernière ? Elle sent plus fort.", "Un sachet de poivre, et un potin, s'il vous plaît."], {"vr": true}],
	["etal_2", "femme", Vector3(-0.4, 0.05, 1.0), 180.0, "debout", [9.0, 18.0], ["Ce collier de boulons… il me le faut.", "Un bracelet qui brille comme les lampes du Dôme !"], {}],
	["etal_4", "homme", Vector3(0.5, 0.05, 1.0), 170.0, "bras_croises", [8.0, 18.0], ["Elle est belle, cette pomme. Mais l'autre aussi. Dilemme.", "Je prends tout ! Enfin, ce que je peux porter."], {}],
	["etal_5", "garcon", Vector3(-0.3, 0.05, 0.9), 190.0, "pointer", [9.0, 18.0], ["Du miel ! Maman, du miel !", "Je peux goûter ? Juste un doigt ? Un petit doigt ?"], {}],
	["marche", "femme", Vector3(-5.8, 0.05, -2.4), -110.0, "chanter", [10.0, 20.0], ["♪ Hautefond, Hautefond, tes rues montent, tes chansons aussi… ♪", "♪ Une cabine dorée, un dirigeable au ciel… ♪"],
		{"vr": true, "parle": [["Bonjour ! Je chante pour la fontaine. Elle fait les chœurs : écoute, elle gargouille en mesure."],
			[["chanson", "Tu peux chanter pour moi ?", ["♪ Il était une liftière, qui montait, qui montait… elle est arrivée si haut qu'elle a dit bonjour à la lune ! ♪ … Merci, merci !",
				"♪ Petit pigeon de la Place, ne mange pas mon chapeau… ♪ C'est une chanson vraie, malheureusement."]]]]}],
	["marche", "homme", Vector3(-7.5, 0.05, 6.8), 90.0, "marcher", [7.0, 18.0], ["Attention, cageots ! Ça passe, ça passe !", "Pommes à gauche, poires à droite… ou l'inverse ?"], {"va": Vector3(7.5, 0.05, 6.8), "porte": "caisse", "vr": true}],
	["marche", "fille", Vector3(0, 0.05, 0), 0.0, "marcher", [9.0, 19.0], ["Attrape-moi ! Attrape-moi !", "Hi hi ! Plus vite !"], {"rond": [4.9, 1.4]}],
	["marche", "garcon", Vector3(0, 0.05, 0), 0.0, "marcher", [9.0, 19.0], ["Je vais t'attraper !", "C'est toi le loup !"], {"rond": [4.9, 1.4], "phase": 2.2, "vr": true}],
	# --- la Forge à vapeur
	["forge", "garcon", Vector3(-3.2, 0.08, -6.3), 180.0, "bricoler", [7.0, 19.0], ["Souffle, soufflet ! Le feu a faim.", "Mathilde dit qu'un bon feu, ça se nourrit comme un dragon : souvent et pas trop."],
		{"vr": true, "parle": [["Salut ! Je suis l'apprenti de Mathilde. Je m'occupe du feu : c'est le plus important. Enfin, c'est ce qu'elle me dit pour que je ne m'ennuie pas."],
			[["feu", "C'est chaud ?", ["Très ! Le fer devient rouge, puis orange, puis jaune. Quand il est blanc, Mathilde crie « Maintenant ! » et tout le monde se pousse.",
				"Assez chaud pour cuire une crêpe en trois secondes. J'ai essayé. Elle était croustillante. Et un peu noire."]]]]}],
	["forge", "fille", Vector3(1.6, 0.08, -4.55), 180.0, "bricoler", [7.0, 19.0], ["Attention, le marteau-pilon va frapper ! Trois, deux, un… BOUM !", "Je règle la vapeur. Un tour de trop, et il fait des claquettes."], {}],
	["forge", "homme", Vector3(-1.8, 0.08, -0.3), 180.0, "bras_croises", [8.0, 18.0], ["J'attends mon fer à cheval. Je n'ai pas de cheval, mais ça porte bonheur.", "Mathilde répare tout. Même ma bouilloire qui chantait faux."], {"vr": true}],
	["forge", "homme", Vector3(-4.15, 0.08, -1.45), 180.0, "marcher", [7.0, 19.0], ["Du charbon pour la gueule du dragon !", "Un sac, deux sacs… La forge mange plus que moi."], {"va": Vector3(-4.15, 0.08, -6.2), "porte": "sac"}],
	# --- le lavoir
	["lavoir", "femme", Vector3(1.1, 0.0, 0.05), 180.0, "cuisiner", [7.0, 18.0], ["Frotte, frotte ! La vapeur fait le reste.", "Ce drap a vu trois tempêtes et un pique-nique. Il en reste des traces."],
		{"vr": true, "parle": [["Bonjour ! Ici, on lave le linge de tout le quartier. Avec l'eau chaude des tuyaux de la Forge, il est propre avant d'être mouillé."],
			[["potins", "Quoi de neuf, au lavoir ?", ["Tout se sait, au lavoir. Par exemple : le Bourgmestre porte des chaussettes à rayures. Les lundis.",
				"On dit que Barnabé a fermé les yeux pendant toute la montée de la cabine. Moi, je dis qu'il dormait."]]]]}],
	["lavoir", "vieille", Vector3(2.5, 0.0, 0.05), 175.0, "cuisiner", [7.0, 17.0], ["De mon temps, on lavait à l'eau froide. Et on chantait pour se réchauffer.", "Le battoir, c'est comme la vie : il faut taper au bon endroit."], {}],
	["lavoir", "femme", Vector3(-1.8, 0.0, -4.05), 0.0, "cuisiner", [8.0, 18.0], ["Une chemise de liftier : toujours une tache de graisse, toujours au même endroit.", "Le soleil sèche, le vent plie. Nous, on discute."], {"vr": true}],
	["lavoir", "fille", Vector3(-4.4, 0.0, -0.9), 60.0, "debout", [9.0, 17.0], ["Maman, je peux faire des bulles ?", "Je garde le panier. C'est un travail important."], {}],
	# --- le hall de la Colonne
	["colonne", "homme", Vector3(4.5, 0.05, 6.6), 90.0, "debout", [7.0, 21.0], ["Deux billets pour le Belvédère, s'il vous plaît. Aller simple : je redescendrai à pied. Non, je plaisante.", "C'est la première fois que je monte. Mes genoux tremblent déjà."],
		{"vr": true, "parle": [["Bonjour ! Je viens des Vergers pour voir la Colonne de près. Elle est encore plus haute qu'on ne le dit. Et on le dit beaucoup."],
			[["ou", "Où allez-vous ?", ["Au Belvédère ! Puis, si j'ose, à la Cité des Nuées. Ma femme dit que je n'oserai pas. Elle a sûrement raison.",
				"Tout en bas, au Dôme d'Azur ! Je veux voir la baleine qui chante. Mon fils dit qu'elle chante faux. Je veux vérifier."]]]]}],
	["colonne", "femme", Vector3(3.6, 0.05, 6.8), 95.0, "bras_croises", [7.0, 21.0], ["Mes valises sont plus lourdes que moi. Et j'ai mis le chapeau dans la petite.", "On monte par la cabine, puis par la capsule… Je vais avoir besoin d'un grand chocolat."], {"vr": true}],
	["colonne", "garcon", Vector3(2.8, 0.05, 6.5), 80.0, "pointer", [8.0, 20.0], ["Papa, regarde la cabine ! Elle monte toute seule !", "Je veux m'asseoir à côté de la fenêtre !"], {}],
	["colonne", "homme", Vector3(-5.0, 0.05, 9.2), 90.0, "marcher", [7.0, 21.0], ["Bagages ! Bagages pour la cabine !", "Attention les pieds ! Valise qui roule !"], {"va": Vector3(1.6, 0.05, 9.6), "porte": "valise", "vr": true}],
	# --- le Port des Cordages
	["port", "homme", Vector3(-8.5, 0.05, 5.8), 90.0, "marcher", [6.0, 20.0], ["Une caisse de pommes pour le bateau de ligne !", "Hop ! Encore une ! Le bateau a faim, ce matin."], {"va": Vector3(9.5, 0.05, 5.8), "porte": "caisse", "vr": true}],
	["port", "homme", Vector3(2.5, 0.05, 7.6), -90.0, "marcher", [6.0, 20.0], ["Un sac de farine du moulin ! Augustin l'a pesé deux fois.", "Ça pèse ! C'est de la farine, ou des pavés ?"], {"va": Vector3(-9.0, 0.05, 7.6), "porte": "sac"}],
	["port", "vieux", Vector3(-1.0, 0.05, 5.0), 180.0, "bricoler", [6.0, 21.0], ["Un cordage bien lové, c'est un cordage qui ne fait pas de nœuds tout seul.", "Quarante ans de mer, et je n'ai jamais perdu un bout. Sauf celui-là."],
		{"vr": true, "parle": [["Ahoy ! Je love les cordages du port. Tu sais faire un nœud de chaise ? Non ? C'est le roi des nœuds : il tient tout, et se défait d'un geste."],
			[["mer", "La mer est bonne, aujourd'hui ?", ["Calme comme un chat qui dort. Ce soir, le vent tournera : regarde les mouettes, elles volent bas.",
				"Elle est d'humeur joueuse. Les barques dansent, le bateau de ligne aussi, et Léon a le mal de mer. Sur le quai."]]]]}],
]

var main: Node
var owner_hf: Node                       # hautefond_v112
var pc: bool = true
var cadres: Dictionary = {}              # lieu -> Transform3D
var centres: Dictionary = {}             # lieu (ou groupe) -> centre (pour savoir si le joueur est près)
var gens: Array = []                     # {poste, fig, it, porte, t, sens, pause, actif}
var draps: Array = []                    # le linge qui sèche : [nœud, phase]
var _rng := RandomNumberGenerator.new()
var _t_check: float = 0.0
var _t: float = 0.0
var _actifs: Dictionary = {}             # groupe -> bool
var style: String = "hautefond"          # V117 : l'allure des gens (la Cité des Nuées réutilise ce script)
var prefix: String = "hf116_"            # V117 : le préfixe des interactions (pour ne pas mélanger)


## Construit les décors (bureaux, chaises, file d'attente, chariot, linge…) ; les gens viendront quand
## le joueur approchera.
func build(owner: Node) -> void:
	owner_hf = owner
	main = owner.main
	pc = owner.pc
	name = "Activite_hautefond_v116"
	var city: Node = owner.city
	var dehors: Node = owner.dehors
	_rng.seed = 116116
	for k in city.cadres116:
		cadres[k] = city.cadres116[k]
	if dehors != null:
		for k2 in dehors.cadres116:
			cadres[k2] = dehors.cadres116[k2]
	if city.colonne != null:
		cadres["colonne"] = Transform3D(Basis(), city.colonne.foot)
	# un groupe par lieu (les étals vont avec le marché)
	for k3 in cadres:
		var g: String = _groupe(str(k3))
		if not centres.has(g):
			centres[g] = (cadres[k3] as Transform3D).origin
	if cadres.has("marche"):
		centres["marche"] = (cadres["marche"] as Transform3D).origin
	_decors(city.kit, dehors.kit if dehors != null else null)
	print("ILE_MANGA_V116: %d travailleurs et visiteurs dans les lieux de Hautefond" % _poster(POSTES))


## Les postes de ce qui a un repère (en VR, seulement ceux marqués « vr »).
func _poster(list: Array) -> int:
	var n: int = 0
	for p in list:
		if not cadres.has(str(p[0])):
			continue
		var opts: Dictionary = p[7]
		if not pc and not bool(opts.get("vr", false)):
			continue
		gens.append({"poste": p, "fig": null, "it": {}, "t": _rng.randf() * TAU, "sens": 1, "pause": 0.0, "angle": float(opts.get("phase", 0.0))})
		n += 1
	return n


func _groupe(lieu: String) -> String:
	return "marche" if lieu.begins_with("etal_") else lieu


func _xf(lieu: String) -> Transform3D:
	return cadres.get(lieu, Transform3D.IDENTITY)


# =================================================================== les décors

func _decors(kit, kit_d) -> void:
	if cadres.has("mairie"):
		var fx: Transform3D = _xf("mairie")
		# le guichet des formulaires, son écriteau, la file (poteaux et cordons rouges)
		var gx: Transform3D = fx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-7.4, 0.1, -6.0))
		kit.counter71(gx, 3.0, "bois112")
		for b in range(9):
			kit.box(gx * T(-1.4 + b * 0.35, 1.62, -0.3), Vector3(0.02, 0.9, 0.02), "laiton112", 1.0)
		kit.box(gx * T(0, 2.08, -0.3), Vector3(3.0, 0.04, 0.05), "laiton112", 1.0)
		kit.box(gx * T(0, 2.25, -0.3), Vector3(3.2, 0.3, 0.12), "bois112", 1.0)
		_ecriteau(gx * T(0, 2.25, -0.23), "Guichet des formulaires")
		for e in [[-6.6, -5.25], [-5.2, -5.25], [-3.8, -5.25], [-6.6, -6.85], [-5.2, -6.85], [-3.8, -6.85]]:
			kit.cyl(fx * T(float(e[0]), 0.1, float(e[1])), 0.03, 0.03, 0.95, "laiton112", 8)
			kit.cyl(fx * T(float(e[0]), 0.1, float(e[1])), 0.14, 0.12, 0.04, "laiton112", 12)
		for zc in [-5.25, -6.85]:
			kit.box(fx * T(-5.2, 0.98, zc), Vector3(2.8, 0.035, 0.035), "tissu112_rouge", 1.0)
		for k in range(4):
			kit.box(fx * T(-7.6, 1.175 + k * 0.012, -6.9 + k * 0.05), Vector3(0.3, 0.012, 0.22), "tissu112_creme" if k % 2 == 0 else "tissu112_bleu", 1.0)
		# les bureaux des commis (à droite), leurs chaises, leurs registres
		for zd in [-4.5, -8.5]:
			var dx: Transform3D = fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(6.85, 0.1, zd))
			_table(kit, dx, 1.6, 0.8)
			_chaise(kit, fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.7, 0.1, zd)))
			kit.box(dx * T(-0.35, 0.8, 0.0), Vector3(0.42, 0.06, 0.3), "cuir71", 1.0)
			kit.box(dx * T(0.3, 0.79, 0.05), Vector3(0.3, 0.012, 0.22), "tissu112_creme", 1.0)
			kit.cyl(dx * T(0.55, 0.78, -0.2), 0.035, 0.03, 0.07, "acier112", 8)
		# la chaise du veilleur, près de la porte
		_chaise(kit, fx * Transform3D(Basis(Vector3.UP, deg_to_rad(30.0)), Vector3(-2.0, 0.1, -1.3)))
	if cadres.has("bibliotheque"):
		var bx: Transform3D = _xf("bibliotheque")
		# des chaises autour des deux tables
		for zt in [-5.0, -9.0]:
			for e2 in [[-0.9, 0.85, 180.0], [0.9, -0.85, 0.0], [0.9, 0.85, 180.0], [-0.9, -0.85, 0.0]]:
				_chaise(kit, bx * Transform3D(Basis(Vector3.UP, deg_to_rad(float(e2[2]))), Vector3(float(e2[0]), 0.1, zt + float(e2[1]))))
			for k2 in range(3):
				kit.box(bx * T(-1.2 + k2 * 1.1, 0.84, zt + (0.15 if k2 % 2 == 0 else -0.2)), Vector3(0.36, 0.03, 0.26), ["tissu112_rouge", "tissu112_vert", "cuir71"][k2], 1.0)
		# la table à dessin de la cartographe
		var tdx: Transform3D = bx * T(-4.6, 0.1, -4.1)
		for s in [-1.0, 1.0]:
			kit.box(tdx * T(s * 0.55, 0.5, 0), Vector3(0.06, 1.0, 0.06), "bois112", 1.0)
		kit.box(tdx * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 1.05, 0)), Vector3(1.3, 0.04, 0.85), "bois112", 1.0)
		kit.box(tdx * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 1.075, 0.0)), Vector3(1.1, 0.01, 0.7), "tissu112_creme", 1.0)
		kit.col_box(tdx * T(0, 0.6, 0), Vector3(1.3, 1.2, 0.7))
	if cadres.has("taverne"):
		var tx: Transform3D = _xf("taverne")
		# le fauteuil du grand-père, près du feu
		var fa: Transform3D = tx * Transform3D(Basis(Vector3.UP, deg_to_rad(-70.0)), Vector3(5.3, 0.1, -9.9))
		kit.box(fa * T(0, 0.25, 0), Vector3(0.8, 0.3, 0.75), "tissu112_rouge", 1.0)
		kit.box(fa * T(0, 0.75, -0.32), Vector3(0.8, 0.75, 0.15), "tissu112_rouge", 1.0)
		for s2 in [-1.0, 1.0]:
			kit.box(fa * T(s2 * 0.36, 0.5, 0), Vector3(0.12, 0.3, 0.72), "tissu112_rouge", 1.0)
		kit.col_box(fa * T(0, 0.4, 0), Vector3(0.8, 0.8, 0.75))
	if cadres.has("forge"):
		var fo: Transform3D = _xf("forge")
		# le soufflet, les sacs de charbon
		kit.box(fo * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-1.9, 0.6, -7.1)), Vector3(0.5, 0.25, 0.9), "cuir71", 1.0)
		kit.box(fo * Transform3D(Basis(Vector3.UP, 0.4), Vector3(-1.9, 0.35, -7.1)), Vector3(0.12, 0.5, 0.12), "bois112", 1.0)
		for k3 in range(4):
			kit.cyl(fo * T(-3.9 - (k3 % 2) * 0.5, 0.08, -0.4 - floorf(k3 / 2.0) * 0.5), 0.22, 0.27, 0.55, "fer71", 10)
		kit.col_box(fo * T(-4.15, 0.35, -0.65), Vector3(1.1, 0.7, 1.0))
	if cadres.has("lavoir"):
		var lx: Transform3D = _xf("lavoir")
		# les paniers de linge, le séchoir et ses draps
		for e3 in [[1.9, 0.75], [-0.4, 0.8], [-2.6, -4.8], [0.0, -4.8]]:
			kit.cyl(lx * T(float(e3[0]), 0.0, float(e3[1])), 0.28, 0.33, 0.32, "planches71_clair", 12)
			kit.cyl(lx * T(float(e3[0]), 0.32, float(e3[1])), 0.27, 0.27, 0.06, "tissu71_blanc", 12)
		var sx: Transform3D = lx * T(-5.4, 0.0, -2.0)
		for s3 in [-1.0, 1.0]:
			kit.box(sx * T(0, 1.0, s3 * 1.6), Vector3(0.08, 2.0, 0.08), "bois112", 1.0)
			kit.col_box(sx * T(0, 1.0, s3 * 1.6), Vector3(0.12, 2.0, 0.12))
		kit.box(sx * T(0, 1.95, 0), Vector3(0.02, 0.02, 3.2), "fer71", 1.0)
		var tissus: Array = ["tissu71_blanc", "tissu112_creme", "tissu112_bleu", "tissu71_blanc"]
		for k4 in range(4):
			var n := Node3D.new()
			add_child(n)
			n.global_transform = sx * T(0, 1.95, -1.2 + k4 * 0.8)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.02, 1.0, 0.7)
			mi.mesh = bm
			mi.material_override = kit.mat(str(tissus[k4]))
			mi.position = Vector3(0, -0.5, 0)
			n.add_child(mi)
			draps.append([n, float(k4) * 1.3, n.transform.basis])
	if cadres.has("colonne"):
		var cx: Transform3D = _xf("colonne")
		# les valises des voyageurs
		for e4 in [[4.4, 6.25, 0.2], [3.6, 7.2, -0.3], [3.35, 7.25, 0.5]]:
			kit.box(cx * Transform3D(Basis(Vector3.UP, float(e4[2])), Vector3(float(e4[0]), 0.3, float(e4[1]))), Vector3(0.55, 0.42, 0.22), "cuir71", 1.0)
			kit.box(cx * Transform3D(Basis(Vector3.UP, float(e4[2])), Vector3(float(e4[0]), 0.55, float(e4[1]))), Vector3(0.14, 0.05, 0.04), "laiton112", 1.0)
	kit.commit()
	if kit_d != null and cadres.has("port"):
		var px: Transform3D = _xf("port")
		# des caisses empilées au bout du chemin des dockers
		for e5 in [[10.4, 6.2, 0.0], [10.4, 6.2, 0.62], [11.1, 5.5, 0.0], [-9.4, 6.4, 0.0]]:
			kit_d.box(px * Transform3D(Basis(Vector3.UP, 0.2), Vector3(float(e5[0]), float(e5[2]) + 0.3, float(e5[1]))), Vector3(0.6, 0.6, 0.6), "planches71", 1.0)
			kit_d.col_box(px * Transform3D(Basis(Vector3.UP, 0.2), Vector3(float(e5[0]), float(e5[2]) + 0.3, float(e5[1]))), Vector3(0.6, 0.6, 0.6))
		kit_d.commit()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Une table simple (xf : au sol, au milieu).
func _table(kit, xf: Transform3D, w: float, d: float) -> void:
	kit.box(xf * T(0, 0.74, 0), Vector3(w, 0.06, d), "bois112", 1.0)
	for s in [-1.0, 1.0]:
		for s2 in [-1.0, 1.0]:
			kit.box(xf * T(s * (w * 0.5 - 0.06), 0.36, s2 * (d * 0.5 - 0.06)), Vector3(0.06, 0.72, 0.06), "bois112", 1.0)
	kit.col_box(xf * T(0, 0.4, 0), Vector3(w, 0.8, d))


## Une chaise (xf : au sol, au milieu ; elle regarde +Z).
func _chaise(kit, xf: Transform3D) -> void:
	kit.box(xf * T(0, 0.45, 0), Vector3(0.44, 0.05, 0.42), "bois112", 1.0)
	for s in [-1.0, 1.0]:
		for s2 in [-1.0, 1.0]:
			kit.box(xf * T(s * 0.18, 0.22, s2 * 0.17), Vector3(0.04, 0.45, 0.04), "bois112", 1.0)
	kit.box(xf * T(0, 0.75, -0.19), Vector3(0.44, 0.55, 0.04), "bois112", 1.0)


## Un écriteau (le texte, sur un panneau) : xf regarde +Z.
func _ecriteau(xf: Transform3D, text: String) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 40
	lab.pixel_size = 0.0032
	lab.outline_size = 8
	lab.modulate = Color(1.0, 0.94, 0.78)
	lab.outline_modulate = Color(0.16, 0.1, 0.05)
	lab.double_sided = false
	add_child(lab)
	lab.global_transform = xf


# =================================================================== les gens

func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		return
	_t += delta
	_t_check -= delta
	if _t_check <= 0.0:
		_t_check = 0.25
		_check()
	for w in gens:
		var f: Variant = w["fig"]
		if f == null or not is_instance_valid(f):
			continue
		var opts: Dictionary = w["poste"][7]
		if opts.has("va"):
			_marche(w, delta)
		elif opts.has("rond"):
			_rond(w, delta)
		var it: Dictionary = w["it"]
		if not it.is_empty() and (opts.has("va") or opts.has("rond")):
			it["pos"] = (f.npc as Node3D).global_position + Vector3.UP * 0.05
	for d in draps:
		var n: Node3D = d[0]
		if is_instance_valid(n) and n.is_visible_in_tree():
			n.transform.basis = (d[2] as Basis) * Basis(Vector3.BACK, 0.12 * sin(_t * 1.3 + float(d[1])) + 0.05)


## Qui doit être là : près du joueur, et à son heure (tout : tous les arrivants d'un coup, pour les tests).
func _check(tout: bool = false) -> void:
	var p: Vector3 = main._player_pos_v27()
	var hour: float = float(main.temps_v56.hour) if main.get("temps_v56") != null else 12.0
	var maisons: Node = main.get("maisons_v81")
	var dedans: bool = maisons != null and bool(maisons.get("inside"))
	# sous terre (les Strates, le Dôme), la surface est cachée : personne
	if _cache():
		dedans = true
	for g in centres:
		var c: Vector3 = centres[g]
		var d: float = p.distance_to(c)
		var on: bool = bool(_actifs.get(g, false))
		if dedans:
			on = false
		elif not on and d < PRES:
			on = true
		elif on and d > LOIN:
			on = false
		_actifs[g] = on
	# (un seul arrivant à la fois : fabriquer quelqu'un prend un peu de temps ; d'abord le plus proche
	# du joueur, pour que le lieu où il entre se remplisse en premier)
	var best: Dictionary = {}
	var bd: float = INF
	for w in gens:
		var pst: Array = w["poste"]
		var want: bool = bool(_actifs.get(_groupe(str(pst[0])), false)) and _heure(hour, pst[5])
		var f: Variant = w["fig"]
		var here: bool = f != null and is_instance_valid(f)
		if want and not here and not w.has("rate"):
			if tout:
				_venir(w)
			else:
				var d2: float = p.distance_squared_to(_xf(str(pst[0])) * (pst[2] as Vector3))
				if d2 < bd:
					bd = d2
					best = w
		elif not want and here:
			_partir(w)
	if not best.is_empty():
		_venir(best)


## Personne quand on n'est pas au bon étage : sous terre (les Strates, le Dôme), la surface est cachée.
func _cache() -> bool:
	return owner_hf.city != null and not (owner_hf.city as Node3D).is_visible_in_tree()


static func _heure(h: float, hh: Array) -> bool:
	var h0: float = hh[0]
	var h1: float = hh[1]
	if h0 <= h1:
		return h >= h0 and h < h1
	return h >= h0 or h < h1


func _venir(w: Dictionary) -> void:
	var pst: Array = w["poste"]
	var opts: Dictionary = pst[7]
	var xf: Transform3D = _xf(str(pst[0]))
	var role: String = str(pst[1])
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(pst[0]) + str(pst[2]) + role)
	var st: String = str(opts.get("style", style))
	var prof: Dictionary = Gens.pick(st, role, r)
	if prof.is_empty():
		w["rate"] = true        # (personne pour ce rôle : on ne réessaie pas à chaque fois)
		return
	prof["nom"] = Gens.prenom(st, role, r)
	var pos: Vector3 = xf * (pst[2] as Vector3)
	var face: Vector3 = xf.basis * (Basis(Vector3.UP, deg_to_rad(float(pst[3]))) * Vector3(0, 0, 1))
	if opts.has("rond"):
		var rr: float = float((opts["rond"] as Array)[0])
		pos = xf * ((pst[2] as Vector3) + Vector3(cos(float(w["angle"])), 0, sin(float(w["angle"]))) * rr)
	var f: Node = Figurant.spawn(self, main, prof, pos, face, str(pst[4]))
	if f == null:
		w["rate"] = true
		return
	f.lines = pst[6]
	f.line_every = Vector2(10.0, 18.0)
	if opts.has("va") or opts.has("rond"):
		f.follow = false
	w["fig"] = f
	w["sens"] = 1
	w["pause"] = 0.0
	var porte: String = str(opts.get("porte", ""))
	if porte != "":
		w["objet"] = _objet(f, porte)
	if opts.has("parle"):
		var me = self
		var court: String = load("res://scripts/maisons_v81.gd").nom_court(str(prof["nom"]))
		var it := {"id": prefix + str(gens.find(w)), "pos": pos + Vector3.UP * 0.05, "radius": 1.7, "text": "E : parler à " + court,
			"vr": "Gâchette : parler à " + court, "call": func(): me._parler(w), "when": func(): return true}
		var dj: Node = main.get("donjon_v35")
		if dj != null:
			dj._interactions.append(it)
		w["it"] = it


func _partir(w: Dictionary) -> void:
	var f: Variant = w["fig"]
	var it: Dictionary = w["it"]
	if not it.is_empty():
		var dj: Node = main.get("donjon_v35")
		if dj != null:
			dj._interactions.erase(it)
		w["it"] = {}
	if f != null and is_instance_valid(f):
		var npc: Node3D = f.npc
		if npc != null and is_instance_valid(npc):
			var b: Variant = npc.get("_body")
			if b != null and is_instance_valid(b):
				var PnjV31: Script = load("res://scripts/pnj/pnj_v31.gd")
				PnjV31._npc_bodies.erase((b as AnimatableBody3D).get_rid())
			npc.queue_free()
	w["fig"] = null


## Ce qu'il porte : des dossiers, un plateau, un sac, une caisse, une valise, un chariot.
func _objet(f: Node, what: String) -> Node3D:
	var n := Node3D.new()
	f.npc.add_child(n)
	var add := func(mesh: Mesh, c: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, metal: float = 0.0) -> void:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.7 if metal == 0.0 else 0.35
		m.metallic = metal
		mi.material_override = m
		mi.position = pos
		mi.rotation = rot
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	match what:
		"dossiers":
			for k in range(3):
				add.call(_bx(Vector3(0.3, 0.04, 0.22)), [Color(0.85, 0.75, 0.55), Color(0.55, 0.65, 0.8), Color(0.9, 0.6, 0.6)][k], Vector3(0, 1.0 + k * 0.045, 0.3), Vector3(0, k * 0.15, 0))
		"plateau":
			add.call(_cy(0.18, 0.03), Color(0.85, 0.86, 0.88), Vector3(0, 1.05, 0.35), Vector3.ZERO, 0.9)
			for k2 in range(2):
				add.call(_cy(0.035, 0.07), Color(0.96, 0.95, 0.92), Vector3(-0.08 + k2 * 0.16, 1.1, 0.35))
		"sac":
			add.call(_cy(0.2, 0.6), Color(0.3, 0.27, 0.25), Vector3(0.18, 1.45, -0.05), Vector3(0, 0, 1.3))
		"caisse":
			add.call(_bx(Vector3(0.5, 0.4, 0.4)), Color(0.66, 0.5, 0.32), Vector3(0, 1.05, 0.32))
		"valise":
			add.call(_bx(Vector3(0.5, 0.36, 0.2)), Color(0.42, 0.24, 0.14), Vector3(0.28, 0.45, 0.0))
		"chariot":
			add.call(_bx(Vector3(0.5, 0.5, 0.75)), Color(0.45, 0.3, 0.18), Vector3(0, 0.55, 0.65))
			for k3 in range(3):
				add.call(_bx(Vector3(0.44, 0.2, 0.1)), [Color(0.7, 0.16, 0.14), Color(0.2, 0.32, 0.62), Color(0.25, 0.5, 0.3)][k3], Vector3(0, 0.88, 0.4 + k3 * 0.22))
			for s in [-1.0, 1.0]:
				add.call(_cy(0.09, 0.04), Color(0.1, 0.1, 0.1), Vector3(s * 0.27, 0.09, 0.65), Vector3(0, 0, PI * 0.5))
	return n


static func _bx(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cy(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	return c


## Aller-retour : il marche vers l'autre bout, s'arrête, pose ou prend ce qu'il porte, repart.
func _marche(w: Dictionary, delta: float) -> void:
	var f: Node = w["fig"]
	if f.npc == null or not is_instance_valid(f.npc) or bool(f.talking):
		return
	var pst: Array = w["poste"]
	var xf: Transform3D = _xf(str(pst[0]))
	var a: Vector3 = xf * (pst[2] as Vector3)
	var b: Vector3 = xf * ((pst[7] as Dictionary)["va"] as Vector3)
	var to: Vector3 = b if int(w["sens"]) == 1 else a
	if float(w["pause"]) > 0.0:
		w["pause"] = float(w["pause"]) - delta
		if float(w["pause"]) <= 0.0:
			f.set_pose("marcher", to - (f.npc.global_position as Vector3))
			f.follow = false
		return
	var p: Vector3 = f.npc.global_position
	var d := Vector3(to.x - p.x, 0, to.z - p.z)
	var step: float = 1.0 * delta
	if d.length() <= step:
		f.npc.global_position = Vector3(to.x, to.y, to.z)
		w["sens"] = 1 - int(w["sens"])
		w["pause"] = 2.5
		var ob: Variant = w.get("objet", null)
		if ob is Node3D and is_instance_valid(ob):
			(ob as Node3D).visible = int(w["sens"]) == 1
		f.set_pose("debout")
		f._play("v28/pickup", 0.2)
		f._gest = 1.0
		return
	var np: Vector3 = p + d.normalized() * step
	np.y = lerpf(a.y, b.y, clampf(Vector2(np.x - a.x, np.z - a.z).length() / maxf(0.01, Vector2(b.x - a.x, b.z - a.z).length()), 0.0, 1.0))
	f.npc.global_position = np
	f.face_dir = d.normalized()


## Tourner en rond (les enfants autour de la fontaine).
func _rond(w: Dictionary, delta: float) -> void:
	var f: Node = w["fig"]
	if f.npc == null or not is_instance_valid(f.npc) or bool(f.talking):
		return
	var pst: Array = w["poste"]
	var opts: Dictionary = pst[7]
	var rr: float = float((opts["rond"] as Array)[0])
	var sp: float = float((opts["rond"] as Array)[1])
	w["angle"] = float(w["angle"]) + sp * delta / rr
	var xf: Transform3D = _xf(str(pst[0]))
	var an: float = float(w["angle"])
	f.npc.global_position = xf * ((pst[2] as Vector3) + Vector3(cos(an), 0, sin(an)) * rr)
	f.face_dir = xf.basis * Vector3(-sin(an), 0, cos(an))
	f.npc.rotation.y = atan2(f.face_dir.x, f.face_dir.z)


## Parler à quelqu'un qui a quelque chose à dire.
func _parler(w: Dictionary) -> void:
	var f: Variant = w["fig"]
	if f == null or not is_instance_valid(f):
		return
	var opts: Dictionary = w["poste"][7]
	var pa: Array = opts["parle"]
	var accueil: Array = pa[0]
	var sujets: Array = pa[1]
	var choices: Array = []
	for s in sujets:
		choices.append({"id": str(s[0]), "label": str(s[1])})
	choices.append({"id": "fermer", "label": "Au revoir !"})
	var who: String = str(f.npc.get("display_name"))
	f.begin_talk()
	# V120 : le salut suit la popularité sur l'île
	var txt120: String = preload("res://scripts/popularite_v120.gd").avec_salut(preload("res://scripts/popularite_v120.gd").region_at(f.npc.global_position), str(accueil[_rng.randi() % accueil.size()]), _rng)
	main.ask_v69(f.npc, who, "de bonne humeur", txt120, choices, func(id):
		for s2 in sujets:
			if str(s2[0]) == str(id):
				var rep: Array = s2[2]
				main.ask_v69(f.npc, who, "de bonne humeur", str(rep[_rng.randi() % rep.size()]), [{"id": "fermer", "label": "Merci !"}], func(_i): _fin(f))
				return
		_fin(f))


func _fin(f: Variant) -> void:
	main._close_dialogue_v31()
	if f != null and is_instance_valid(f):
		f.end_talk()


## Combien de gens sont là (les tests).
func presents() -> int:
	var n: int = 0
	for w in gens:
		if w["fig"] != null and is_instance_valid(w["fig"]):
			n += 1
	return n

extends RefCounted
## V114 : les gens de la Fronde, le quartier libre des Strates, sous Hautefond. Une caverne à l'est de
## la Grande Strate : on y arrive par un tunnel, puis par le Pont des Frondeurs, un pont de rails et de
## boulons jeté au-dessus du Gouffre (une faille très profonde où gronde une rivière souterraine). Du
## punk « à vapeur », sous terre : des maisons faites de conteneurs et de vieilles chaudières empilés,
## reliés par des passerelles ; des guirlandes, des cristaux, des tuyaux d'orgue, des fresques sur la
## roche, et des bannières au A cerclé dessiné en engrenage. Ici, tout est à prix libre ou au troc, et
## tout se décide en Assemblée, sur les vieux canapés, autour du brasero.
##  - la Scène des Soupapes (et la fosse) : Rivet (Corentin Ferrand, la batterie ; il répare les rails
##    le jour), Bielle (Maëlle Ferrand, le chant et la guitare ; elle aussi aux rails le jour) et Écho
##    (la basse, qui écoute la roche). Rivet et Bielle sont les parents d'Ysaé, la créatrice de bijoux
##    du Grand Marché de Hautefond (hautefond_habitants_v112.gd) ;
##  - la Cantine Libre : Mémé Gamelle et sa louche, Excalibur (on mange ensemble, prix libre, pas une
##    goutte d'alcool) ;
##  - l'Atelier Libre : Bricole (l'inventrice ; c'est elle qui a fait l'orgue à vapeur) ;
##  - le Troc : Lumi (bijoux de boulons et de cristal ; elle a appris le métier à Ysaé) ;
##  - le Mur des Fresques : Fusain (le peintre de la roche) ;
##  - le Skatepark : Ressort (11 ans, le fils de Bricole ; copain de Tom, l'apprenti de la Grande Forge
##    des Strates, et de Pimprenelle, la fille de la forgeronne d'en haut) ;
##  - l'Assemblée : Brasero (Barthélemy Ferrand, 80 ans, ancien mineur, le fondateur de la Fronde, le
##    père de Rivet et le grand-père d'Ysaé : « le orange », à la crête qui tient toute seule).
## Les concerts : chaque soir de 20 h à 23 h, les Soupapes sont sur scène (fr_scene_batterie,
## fr_scene_chant, fr_scene_basse) ; l'orgue à vapeur joue tout seul, sur les cartes perforées de
## Bricole. La fosse : fr_fosse_1 … 8. La Ligne des Strates (depuis Hautefond) a rouvert (V114), puis
## celle du Dôme d'Azur (plus bas, V115), dont Rivet et Bielle ont posé les rails.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd), même corps que Port-Boucan (fiches « azur » et « punk », pnj_boucan_v75.gd ; les
## coiffures « crete » et « crete_courte » en plus). Fiche « village » : fronde.
## Identifiants : rivet, fusain et lumi existent déjà ailleurs dans l'archipel, alors on suffixe « _fr » :
## rivet_fr, fusain_fr, lumi_fr ; leur porte reste « porte_<prénom> » (porte_rivet, porte_fusain,
## porte_lumi). bielle, echo, gamelle, bricole, ressort et brasero gardent leur prénom.
## Les gens des Strates cités avec « a_rencontre » : anatole, ludovic, opaline, bertille, tom_st ; ceux de
## Hautefond : ysae, mathilde, pimprenelle_hf, capucine_hf, hector_hf, philippine, firmin, gaspard_hf ;
## ceux des Nuées : pascal, mireille.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Salut, {surnom} ! Et quand tu passes le Pont des Frondeurs, dis bonjour au Gouffre. Il répond toujours. Trois fois.", "si": {}, "geste": "salut"},
		{"t": "À plus ! Ce soir, les Soupapes jouent à vingt heures. C'est à prix libre : tu paies en applaudissements.", "si": {}, "geste": "rire"},
		{"t": "Bonne route ! Ici, la porte est toujours ouverte. Enfin, c'est une porte de chaudière. Elle est lourde. Mais elle est ouverte.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit ! Dors bien, si tu y arrives : l'orgue à vapeur fait « pouêêt » jusqu'à vingt-trois heures. Après, il ronfle.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Ici, on ne tape que sur les fûts de la batterie et sur les rivets des rails ! Et encore, en rythme !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Ça va pas, non ? On en parle ce soir à l'Assemblée. Autour du brasero. Brasero va te faire un discours de philosophie. Un long.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? C'est chouette. Si je n'en ai pas besoin, je le poserai au Troc : Lumi lui trouvera un nouveau copain.", "si": {}},
		{"t": "Merci, {surnom}. Ici, on dit qu'un cadeau, c'est un boulon de plus dans le pont entre deux personnes.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! En plein dans le mille, {surnom} ! Comme une baguette de Rivet sur la cymbale !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau de Frondeur ! Merci, {surnom}. Je vais le raconter à toute l'Assemblée. Deux fois. Et on votera pour savoir si c'est le plus beau cadeau de la semaine.", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Euh… merci. Je vais le… porter au Troc. Lumi trouve preneur pour tout. Même pour ça. Surtout pour ça.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, on règle tout à l'Assemblée, avec des mots et une tisane. C'est plus long. Mais ça tient mieux.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Évidemment ! Dans une caverne, on se croise tous les jours. Et puis tout résonne, ici. Même les gens.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Tu confonds avec l'Assemblée : là-bas, tout le monde demande tout. En même temps. Et après, on vote.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Combien de Frondeurs faut-il pour changer une ampoule ? Un pour la changer, trente pour voter la couleur, et Bricole pour la brancher sur une chaudière.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un rail dit à un autre rail ? « On se retrouve au prochain aiguillage ! » … Bielle la raconte à chaque concert. On rit à chaque fois. Avant, par politesse. Maintenant, par tradition.", "si": {}, "geste": "rire"},
		{"t": "Un monsieur d'en haut descend à la Fronde : « C'est bien bruyant, ici ! » Mémé Gamelle lui tend un bol : « C'est la soupe qui chante, mon caillou. » Il en a repris trois fois.", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on une chaudière qui chante ? Une Soupape ! … Voilà. Le groupe s'appelle comme ça à cause de cette blague. Personne ne sait si c'est une raison ou une excuse.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi les gens des Strates portent un casque pour venir au concert ? Parce qu'à la mine, on leur a appris : quand ça gronde, on se protège. … Ici, quand ça gronde, c'est Rivet.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Ici, les prix sont tout petits, et le reste se troque. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Pas pour toi, pas aujourd'hui. On en reparlera à l'Assemblée, quand on se sera réconciliés. Avec un sourire, ça ira plus vite.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Fais-en bon usage, et passe-le à quelqu'un quand tu n'en auras plus besoin !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Va manger à la Cantine Libre : chez Mémé Gamelle, tu paies ce que tu peux. Même zéro.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Ici, on évite d'avoir deux fois la même chose : il y a toujours quelqu'un qui en a zéro.", "si": {}}],
	"achat_plein": [{"t": "Ton sac déborde, {surnom}. Dépose un truc au Troc, Lumi sera ravie.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces. Et un merci de récup' en prime.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et un concert des Soupapes en pensée !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… Ici, on ne laisse personne au fond du Gouffre. Un petit geste. Ne le dis pas à l'Assemblée : ils voudraient voter pour savoir s'il était assez petit.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont déjà plus petits qu'un boulon de montre. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. J'ai une mémoire de caverne : tout y résonne longtemps.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Ouais !", "Trop bien !", "Ha ha !", "Par mes soupapes !"],
		"neutre": ["Bon.", "Ouais…", "Hm.", "Alors…"],
		"triste": ["Bof…", "Pff…", "Ça grince…", "Aïe aïe aïe…"],
		"colere": ["Par tous les boulons !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["C'est fait main.", "On en parle à l'Assemblée ?", "Prix libre !", "Ça, c'est la Fronde !"],
	"humeur_mots": [[0.6, "à pleine vapeur"], [0.25, "de bonne humeur"], [-0.25, "un peu rouillé"], [-0.6, "tout grinçant"], [-2.0, "en surpression"]],
	"surnoms": [[0, "l'ami d'en haut"], [25, "camarade"], [50, "mon pote de fosse"], [75, "Frondeur d'honneur"], [95, "enfant de la Fronde"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
## Les cheveux de la Fronde : chacun choisit sa couleur le jour de ses quinze ans (les couleurs des
## cristaux, du cuivre, des braises), et quelques couleurs naturelles.
const ROUGE_CUIVRE := [0.8, 0.32, 0.12]
const VERT_CRISTAL := [0.2, 0.78, 0.48]
const ORANGE_BRAISE := [1.0, 0.48, 0.06]
const ROSE_PALE := [0.96, 0.7, 0.8]
const BLEU_GIVRE := [0.62, 0.78, 0.92]
const VIOLET_CRISTAL := [0.6, 0.3, 0.9]
const JAUNE_LAITON := [0.92, 0.74, 0.24]
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
## Les tissus de la Fronde : cuir patiné, toile de cheminot, bleu de chauffe, cuivre, suie.
const CUIR := [0.2, 0.14, 0.1]
const SUIE := [0.12, 0.12, 0.13]
const BLEU_CHAUFFE := [0.2, 0.3, 0.46]
const CUIVRE := [0.72, 0.42, 0.2]
const TOILE := [0.5, 0.44, 0.34]
const VERT_BOUTEILLE := [0.16, 0.34, 0.26]
const PRUNE := [0.4, 0.16, 0.3]


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
	out["groupe"] = "fronde"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ les Soupapes (et les rails)
		{"id": "rivet_fr", "nom": "Rivet", "titre": "batteur des Soupapes, réparateur de rails", "maison": "porte_rivet", "village": "fronde",
			"agenda": [[7, 12, "fr_rail_1"], [12, 13.5, ["fr_cantine_table_1", "fr_cantine_table_2"]], [13.5, 17, "fr_rail_1"], [17, 18, ["fr_assemblee_2", "fr_place_1"]], [18, 19.5, "fr_cantine_table_1"], [19.5, 20, "fr_place_2"], [20, 23, "fr_scene_batterie"], [23, 7, "maison"]],
			"azur": {"cheveux": ROUGE_CUIVRE, "coiffure": "crete", "barbe": "courte", "yeux": Y_BRUN, "haut": BLEU_CHAUFFE, "taille": 1.1, "carrure": 1.4},
			"teinte": PEAU[2],
			"punk": {"tenue": "bleu_travail", "clous": true, "patchs": true, "objet": "baguettes", "chapeau": "bandana"},
			"humeur_base": 0.75, "traits": {"bavard": 0.85, "humour": 0.9, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"baguettes": 3.0, "chocolat_chaud": 2.0, "potee_gamelle": 2.0, "boulon": 1.5, "gateau_miel": 1.5, "ampli": 1.5}, "deteste": {"sifflet_muet": -1.5, "vieille_botte": -0.5},
			"tics": ["Boum-tchak !", "Un, deux, un-deux-trois-quatre !", "Ça tient comme un rivet.", "Tape là !"],
			"surnoms": [[0, "l'ami d'en haut"], [25, "mon pote"], [50, "mon métronome"], [75, "mon frère de rythme"], [95, "cinquième Soupape"]],
			"repliques": {
				"accueil": [
					L("BOUM-TCHAK ! Salut ! Un nouveau ! Bienvenue à la Fronde ! Rivet. Le jour, je répare les rails ; le soir, je tape sur des casseroles très chères qu'on appelle une batterie. Les deux, c'est pareil : il faut que ça tienne, et il faut que ça sonne. Tape là !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Te revoilà ! Écoute ça : (Il tapote un rail avec sa clé.) Ting-ting-tong. C'est le rail numéro quatre. Il est de bonne humeur, aujourd'hui. Moi aussi.", {"visites_min": 2}, "rire"),
					L("Tiens, mon métronome préféré ! Tu sais que tu marches en rythme, toi ? Si, si. Je l'ai entendu depuis le pont. Un pas, deux pas, un-deux-trois-quatre… Tu es fait pour la fosse.", {"visites_min": 5}, "rire"),
				],
				"humeur": [
					L("Bof. J'ai cassé ma dernière paire de baguettes sur la cymbale, hier soir. Ce soir, je vais jouer avec deux cuillères en bois. Ça fait « poc ». Le public est poli. Il fait « poc » aussi.", {"humeur_max": -0.2}),
					L("À pleine vapeur ! La Ligne a rouvert, {surnom} ! Hier soir, il y avait des gens d'en haut dans la fosse. Avec des chapeaux ! Un monsieur a sauté avec son chapeau sur la tête pendant tout le morceau. Il ne l'a pas perdu. Respect.", {}, "rire"),
					L("Un peu fatigué des bras. Huit heures de rails, trois heures de batterie… Bielle dit que je devrais choisir. J'ai choisi : les deux. Mais un peu moins fort. … Non, je mens. Pareil.", {}, "rire"),
					L("Le matin, je cale mes coups de marteau sur les gouttes qui tombent de la voûte. Plic, tang, plic, tang. Écho dit que c'est le plus vieux batteur de la Fronde, la voûte. Elle a de l'avance sur moi.", {"matin": true}),
					L("Le soir, avant de monter sur scène, je tape sur tout. La table, le banc, le dos de Bricole. Elle dit que c'est mon échauffement. Moi, je dis que c'est de l'affection. Elle dit que l'affection, c'est moins fort.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Les rails, c'est mon métier depuis mes seize ans. Je les répare, je les resserre, je les écoute. Un rail qui chante juste, c'est un rail en bonne santé. Un rail qui chante faux, je le soigne. Je suis un peu docteur, en fait. Docteur des rails.", {}),
					L("J'ai appris la batterie sur les vieilles chaudières de la Fronde. Il y en avait une qui faisait « dong », une qui faisait « bam », une qui faisait « tchiii ». Mon père, Brasero, disait : « Ce petit fera du bruit toute sa vie. » Il avait raison. Il a toujours raison. C'est fatigant.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma fille, Ysaé, vend des bijoux au Grand Marché de Hautefond. Toute seule, en haut, au milieu des gens qui la regardent de travers. Moi, je tape fort pour faire du courage. Elle, elle sourit pour en faire. Je crois que c'est elle, la plus forte de la famille.", {"sujet_min": ["lui", 2]}),
					L("Tu veux un secret, {surnom} ? Quand Ysaé est montée vendre en haut pour la première fois, j'ai pleuré dans les fûts toute la soirée. Personne ne l'a vu. Je jouais trop vite. Bielle l'a vu. Elle a chanté plus fort pour couvrir. On est une bonne équipe.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("La Fronde, c'est notre caverne, à l'est des Strates. Des conteneurs, des vieilles chaudières, des passerelles, des guirlandes. Rien n'était à nous, au début : c'était la décharge des Strates. Maintenant, c'est la décharge la plus vivante du monde.", {}),
					L("La Scène des Soupapes, c'est au fond de la caverne. Tous les soirs à vingt heures : moi aux fûts, Bielle au micro, Écho à la basse, et l'orgue à vapeur de Bricole qui fait les refrains tout seul. Il ne se trompe jamais. C'est vexant.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Ligne des Strates a rouvert ! Les gens d'en haut descendent dans la Colonne, ils voient le Soleil de Laiton, ils font « oooh ». Puis ils passent le Pont des Frondeurs, ils entendent le Gouffre, et ils font « ooh-oh ». Puis ils arrivent ici, et ils font « boum-tchak ». Ça, c'est moi.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Plus bas, il y a la Ligne du Dôme d'Azur, au fond de la mer. Elle a rouvert ! Les rails, c'est Bielle et moi qui les avons posés. Un jour, on jouera là-bas, sous le dôme, avec les poissons dans le public. Il paraît que les baleines aiment la batterie. Il paraît.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Ma fille t'a parlé de nous ? Ysaé ! Elle redescend tous les soirs pour le dernier morceau. Elle se met au fond de la fosse et elle chante les paroles plus fort que sa mère. Ne le dis pas à Bielle. Bielle le sait.", {"a_rencontre": "ysae"}, "rire"),
					L("La Grande Liftière d'en haut, Maîtresse Capucine… Elle dit qu'elle n'entend rien de la musique qui monte par la Colonne. Anatole, le liftier des Strates, l'a vue taper du pied sous son guichet. En rythme. Je l'adore, cette dame.", {"a_rencontre": "capucine_hf"}, "rire"),
					L("Un monsieur des Nuées, tout en haut, nous a écrit quarante réclamations contre le bruit. Fusain les a collées sur le Mur. Il paraît qu'il bat la mesure en les écrivant. Alors on lui a envoyé une paire de baguettes. Pour qu'il batte mieux.", {}, "rire"),
					L("Le petit Tom, l'apprenti de la Grande Forge, tape sur l'enclume en même temps que moi sur la batterie. On ne s'est jamais mis d'accord. On joue ensemble depuis des mois, à trois cents mètres l'un de l'autre. C'est mon meilleur duo.", {}),
					L("Tu as pris le Funiculaire d'Azur ? Tu as entendu Marius faire « boum-tchak » ? C'est quand sa cabine passe sur la dernière traverse. Bielle et moi, on a posé les rails pendant des mois, et le dernier jour, on a peint cette traverse en violet. Il ne l'a jamais repeinte. Il dit que c'est plus fort que lui. Je le comprends. Boum-tchak !", {"a_rencontre": "marius"}, "rire"),
				],
				"interpelle": [L("HÉ ! Boum-tchak ! Tu viens d'en haut, toi !", {"visites_max": 0}, "salut"), L("{surnom} ! Concert ce soir ! Vingt heures ! Tape là !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut, {surnom} ! Garde le rythme : un pied, puis l'autre. C'est tout le secret.", {}, "salut"), L("À plus ! Et si tu croises ma fille en haut, dis-lui que son père joue toujours trop fort. Elle sera rassurée.", {}, "rire"), L("Bonne nuit ! Mes bras dorment déjà. Mes pieds tapent encore un peu. Ils finissent toujours le morceau tout seuls.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu as tapé du pied, la première fois. Pas en rythme. Mais avec cœur. Ça, je n'oublie jamais.", {}, "rire")],
			}},
		{"id": "bielle", "nom": "Bielle", "titre": "chanteuse et guitariste des Soupapes, réparatrice de rails", "maison": "porte_bielle", "village": "fronde", "femme": true,
			"agenda": [[7, 12, "fr_rail_2"], [12, 13.5, ["fr_cantine_table_1", "fr_cantine_table_3"]], [13.5, 17, "fr_rail_2"], [17, 18.5, ["fr_assemblee_3", "fr_troc_comptoir"]], [18.5, 19.5, "fr_cantine_table_1"], [19.5, 20, "fr_place_2"], [20, 23, "fr_scene_chant"], [23, 7, "maison"]],
			"azur": {"cheveux": VERT_CRISTAL, "coiffure": "crete_courte", "yeux": Y_VERT, "haut": CUIR, "taille": 1.0},
			"teinte": PEAU[3],
			"punk": {"tenue": "perfecto", "clous": true, "patchs": true, "objet": "guitare"},
			"humeur_base": 0.6, "traits": {"bavard": 0.75, "humour": 0.75, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"partition": 2.5, "sirop_menthe": 2.0, "eclat_cristal": 2.0, "limonade_gouffre": 2.0, "cafe_vapeur": 1.5, "tarte_potiron": 1.5}, "deteste": {"chapeau_ventilateur": -1.0, "sifflet_muet": -1.0},
			"tics": ["Un, deux, trois, VAPEUR !", "Ça siffle !", "On aiguille.", "Plus fort, je n'entends pas !"],
			"surnoms": [[0, "l'ami d'en haut"], [25, "camarade"], [50, "mon pote de fosse"], [75, "mon refrain"], [95, "ma chanson préférée"]],
			"repliques": {
				"accueil": [
					L("Salut, toi ! Tu as la tête de quelqu'un qui vient de traverser le Pont des Frondeurs : les yeux grands ouverts et les genoux un peu mous. Bienvenue à la Fronde ! Moi, c'est Bielle. Rails le jour, micro le soir. Et toujours de la graisse sous les ongles.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien, j'ai un couplet coincé dans la tête depuis ce matin. Dis-moi ce qui rime avec « chaudière ». … « Hier » ? Trop facile. « Caillou-de-rivière » ? Ça, c'est punk. Je le garde.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Un peu enrouée. Hier soir, j'ai chanté le dernier refrain trois fois, parce que la fosse ne voulait pas qu'on s'arrête. Ce matin, ma voix fait « crr ». Gamelle m'a donné une tisane au miel. Elle dit que dans deux heures, je ferai « laaa ».", {"humeur_max": -0.2}),
					L("À pleine vapeur ! Le rail numéro sept est redressé, ma guitare est accordée, et Ysaé est descendue manger avec nous ce midi. Trois bonnes nouvelles avant treize heures. Je vais en faire une chanson.", {}, "rire"),
					L("Pensive. Depuis que la Ligne a rouvert, il y a des gens d'en haut dans la fosse. Ils ne savent pas encore pogoter : ils sautent poliment, chacun dans son carré. Ça viendra. Il faut juste qu'ils comprennent qu'ici, on se relève les uns les autres.", {}),
					L("Le matin, sur les rails, je chante pour vérifier les éclisses. Si l'écho revient juste, le rail est droit. Si l'écho revient faux… c'est peut-être moi. Je recommence. Rivet dit que je suis la seule cheminote qui fait ses mesures en do majeur.", {"matin": true}, "rire"),
					L("Le soir, avant le concert, je regarde la fosse se remplir depuis la passerelle. Les Strates arrivent avec leurs casques, les gens d'en haut avec leurs chapeaux, les Frondeurs avec leurs crêtes. Tout le monde finit pareil : en sueur et content.", {"soir": true}),
				],
				"lui": [
					L("Je suis née dans les Strates, dans une famille de cheminots du Petit Train. Très sérieux. Très ponctuels. Un jour, à quinze ans, j'ai entendu Rivet taper sur une chaudière, de l'autre côté du Gouffre. J'ai traversé le pont pour voir qui faisait ce boucan. Je ne suis jamais repartie.", {}),
					L("Mes cheveux sont verts depuis mes quinze ans. Ici, c'est le jour où l'on choisit sa couleur. J'ai choisi le vert des cristaux qui poussent au bord du Gouffre. Ma mère a dit : « Tu ressembles à un signal de voie libre. » C'était le but.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ysaé a appris à chanter avant de parler. Elle chantait « boum-tchak » dans son berceau, et on la berçait avec la basse d'Écho. Quand elle est partie vendre en haut, la Fronde a été silencieuse pendant une soirée. Une seule. Puis on a joué pour qu'elle nous entende par la Colonne.", {"sujet_min": ["lui", 2]}),
					L("Les chansons des Soupapes, c'est moi qui les écris. Il y en a une sur les rails, une sur la soupe de Gamelle, une sur le Pont, une sur la crête de Brasero… Et une sur Ysaé. Je ne la chante jamais quand elle est dans la fosse. Elle pleure. Moi aussi. Ça fait beaucoup de pleurs pour un concert punk.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("Le Pont des Frondeurs, c'est la porte de la Fronde. Des rails soudés, des boulons gros comme le poing, et en dessous, le Gouffre. On n'en voit pas le fond. On entend la rivière qui gronde. Les gens d'en haut traversent en se tenant la main. Ici, on appelle ça « le pont des nouveaux amis ».", {}),
					L("La Fronde, on la décide ensemble, à l'Assemblée. Les canapés, le brasero, et Brasero lui-même, qui tient la clé de parole. Celui qui tient la clé parle, les autres écoutent. On a voté la couleur des guirlandes, le nom du chat, et l'heure des concerts. Le nom du chat a pris trois soirées.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Grande Colonne relie quatre mondes, tu sais. La Cité des Nuées tout en haut, Hautefond, nous, ici dans les Strates, et le Dôme d'Azur au fond de la mer. Une chanson, c'est pareil : un couplet en haut, un refrain en bas. Et le pont au milieu.", {"sujet_min": ["ile", 2]}),
					L("Les gens des Strates disent qu'on est « le quartier qui fait du bruit ». Nous, on dit qu'ils sont « le quartier qui se couche tôt ». Puis à vingt heures, ils sont tous dans la fosse. Et à vingt-trois heures, ils râlent parce que c'est fini.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Ma fille, Ysaé ! Tu l'as vue, en haut ? Elle t'a parlé de ses bijoux ? Elle a appris avec Lumi, au Troc. Maintenant, elle a des clients en haut-de-forme. Elle m'a dit que le Bourgmestre lui avait acheté une broche. En douce. J'ai ri pendant tout le dîner.", {"a_rencontre": "ysae"}, "rire"),
					L("Mathilde, la forgeronne d'en haut, garde ses chutes de cuivre pour Ysaé. Le jour de la réouverture, elle a ri si fort, là-haut, que son rire est descendu par la Colonne jusqu'à la Fronde. On l'a invitée à l'Assemblée, par lettre. Elle a répondu : « Je vote pour tout ! » Sans demander pour quoi. Elle dit que c'est plus gai.", {"a_rencontre": "mathilde"}, "rire"),
					L("Écho m'a dit quatre mots, ce matin. Quatre ! « Ta guitare est fausse. » Il avait raison. Le mi grave. Il l'entend depuis l'autre bout de la caverne. Avec ses oreilles, il pourrait accorder la Colonne.", {}, "rire"),
					L("Ferdinand, le conducteur du Petit Train des Strates, me fait signe avec son sifflet chaque fois qu'il passe sur mes rails réparés. Deux coups : « C'est bon. » Trois coups : « C'est très bon. » Un coup : « Bielle, tu as encore oublié ta clé à molette sur la voie. »", {}, "rire"),
					L("Des mois à poser les rails du Funiculaire d'Azur, avec Rivet, dans un grand tube de verre, au fond de la mer. Le matin, je chantais pour vérifier les éclisses, comme ici. Mais là-bas, c'était une raie qui passait sous nos pieds pour écouter. Le dernier jour, on a peint la dernière traverse en violet. Personne ne nous l'avait demandé. Personne ne l'a repeinte.", {}),
				],
				"interpelle": [L("Hé ! Toi ! Viens dire bonjour, la Fronde ne mord pas !", {"visites_max": 0}, "salut"), L("{surnom} ! Ce soir, nouvelle chanson ! Viens !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut, {surnom} ! Et si tu as une rime en « -ière », reviens me la dire.", {}, "salut"), L("À plus ! Fais attention sur le Pont. Pas à cause du Gouffre : à cause de Ressort, qui le traverse en skate.", {}, "rire"), L("Bonne nuit ! Je vais dormir comme un rail : bien droite, et sans grincer.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Tu as traversé le Pont des Frondeurs sans te tenir à la rambarde. Ou alors, tu t'y tenais très discrètement. Les deux me vont.", {}, "rire")],
			}},
		{"id": "echo", "nom": "Écho", "titre": "bassiste des Soupapes, écouteur de roche", "maison": "porte_echo", "village": "fronde",
			"agenda": [[9, 12, "fr_pont"], [12, 13, "fr_cantine_table_3"], [13, 16, ["fr_atelier_2", "fr_fresque_2"]], [16, 19, "fr_pont"], [19, 20, "fr_cantine_table_4"], [20, 23, "fr_scene_basse"], [23, 9, "maison"]],
			"azur": {"cheveux": BLEU_GIVRE, "coiffure": "long", "yeux": Y_GRIS, "haut": SUIE, "taille": 1.14, "carrure": 0.8},
			"teinte": PEAU[4],
			"punk": {"tenue": "veste_jean", "clous": false, "patchs": true, "objet": "basse", "chapeau": "bonnet"},
			"humeur_base": 0.45, "traits": {"bavard": 0.15, "humour": 0.55, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"caillou_chantant": 3.0, "sifflet_muet": 2.5, "coquillage": 2.0, "eclat_cristal": 1.5, "the_menthe": 1.5, "tisane_brume": 1.0}, "deteste": {"canard_mecanique": -1.0, "chaussettes_vapeur": -0.5},
			"tics": ["… Écoute.", "Chut. (Il sourit.)", "La roche est d'accord.", "Mm."],
			"surnoms": [[0, "toi qui marches fort"], [25, "toi qui écoutes"], [50, "mon calme"], [75, "ma note juste"], [95, "mon silence préféré"]],
			"repliques": {
				"accueil": [
					L("… Bonjour. (Il pose un doigt sur ses lèvres.) Écoute. … Tu entends ? C'est le Gouffre. Il dit bonjour aussi. Moi, c'est Écho. Je joue de la basse. Et j'écoute. Surtout j'écoute.", {"visites_max": 1}, "salut"),
					L("{surnom}. (Il tend l'oreille vers toi.) Tu marches plus doucement qu'avant. C'est bien. La roche aime ça.", {"visites_min": 2}),
					L("… Ah. C'est toi. Je t'ai reconnu au pas, depuis le bout du pont. (Un petit sourire.) Ça n'arrive qu'aux gens que j'aime bien.", {"visites_min": 5}),
				],
				"humeur": [
					L("Un peu brouillé. Il y avait trop de bruit sur le pont, aujourd'hui. Des gens d'en haut qui criaient pour entendre le Gouffre répondre. Il a répondu. Beaucoup. Il est fatigué. Moi aussi.", {"humeur_max": -0.2}),
					L("Bien. Très bien. (Un temps.) Ce matin, une goutte est tombée de la voûte sur une plaque de cuivre. « Ding. » Un la parfait. J'ai attendu la suivante pendant une heure. Elle n'est pas venue. C'était une très bonne heure.", {}),
					L("Calme. La rivière du Gouffre a baissé d'un demi-ton cette semaine. Elle chante en sol, maintenant. Je l'ai dit à Bricole. Elle a réaccordé l'orgue. Personne d'autre ne l'a remarqué. Mais ce soir, tout sonnera mieux.", {}),
					L("Le matin, la caverne est très silencieuse. On entend les chaudières qui respirent, les guirlandes qui grésillent, et Mémé Gamelle qui chantonne dans la cuisine. Elle chante faux. (Il sourit.) C'est mon moment préféré.", {"matin": true}),
					L("Le soir, sur scène, je ferme les yeux. La basse, ça ne s'entend pas : ça se sent, dans le ventre. Je joue pour les ventres. Et pour la roche. Elle vibre avec nous. Si tu poses la main sur le mur, tu sens le concert.", {"soir": true}),
				],
				"lui": [
					L("Avant, j'étais écouteur, aux Mines de Cristaux. On posait l'oreille sur la paroi, et on écoutait si la roche était solide. Une roche qui chante, ça va. Une roche qui se tait trop, on s'en va. Je n'ai jamais eu peur. J'ai seulement très bien écouté.", {}),
					L("Écho, ce n'est pas mon vrai nom. C'est Brasero qui me l'a donné, le jour où je suis arrivé. Je n'avais dit qu'un mot de toute la soirée. Il a dit : « Celui-là, il répète ce que dit la roche. » Mon vrai prénom… (Il hausse les épaules.) Je l'ai prêté au Gouffre. Il le garde bien.", {"sujet_min": ["lui", 1]}),
					L("Je parle peu. Les mots, ça fait beaucoup de bruit pour ce que ça dit. Une note grave, au bon moment, ça dit tout. Bielle dit que je suis le seul bassiste qui fait des phrases avec des silences. (Un temps.) … Celle-là, elle était longue.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Quand Ysaé était bébé, elle ne s'endormait qu'avec ma basse. Une note, très bas, très lent. Elle fermait les yeux au troisième temps. Maintenant, elle est en haut. Le soir, je joue cette note-là en dernier. Elle monte par la Colonne. Je crois qu'elle l'entend.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("Le Gouffre. (Il s'appuie sur la rambarde du pont.) Personne n'en a vu le fond. En bas, une rivière. Elle vient de très loin, elle va très loin. Elle chante une seule note, depuis toujours. Les Soupapes s'accordent sur elle. Tous les soirs.", {}),
					L("La Fronde résonne comme une grande coquille. Si tu chuchotes près du Mur des Fresques, on t'entend à la Cantine. Mémé Gamelle sait tous les secrets de la caverne. Elle ne les répète pas. Elle les met dans la soupe.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Colonne, c'est un grand tuyau d'orgue de quatre mondes. Quand on joue, le son monte jusqu'à Hautefond. Et plus haut, jusqu'aux Nuées. Et le soir, quand tout se tait, j'entends des choses qui descendent. Des cloches. Des vents. Des gens qui rient.", {"sujet_min": ["ile", 2]}),
					L("Sous la Gare des Strates, il y a la grille de la Ligne du Dôme d'Azur. Avant qu'elle rouvre, j'y collais l'oreille. Tout en bas, très loin… quelque chose de grand qui chantait. Lent. Grave. Plus grave que ma basse. (Il sourit.) C'était bien une baleine. Je suis descendu l'écouter de près.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Ludovic, le contremaître des Mines. On écoutait la roche ensemble, avant. Il vient au concert, au fond de la fosse, les bras croisés. Il ne danse pas. Mais son pied bat la mesure. Le gauche. Toujours le gauche.", {"a_rencontre": "ludovic"}),
					L("Ressort m'a demandé de lui apprendre à écouter la roche. Il a collé l'oreille au mur pendant… quatre secondes. Puis il a dit : « Elle dit qu'elle veut faire du skate. » (Il rit tout bas.) Il n'avait pas complètement tort.", {}, "rire"),
					L("Rivet tape trop fort. (Un temps.) Mais il tape juste. C'est rare, les deux ensemble. Ne lui dis pas. Il taperait encore plus fort.", {}, "rire"),
					L("Brasero parle au brasero, le soir, quand tout le monde est parti. Je l'ai entendu. Il lui raconte la journée. Le feu répond en craquant. Je crois qu'ils sont d'accord sur presque tout.", {}),
				],
				"interpelle": [L("… Chut. Tu entends ?", {"visites_max": 0}), L("{surnom}. (Un petit signe de la main, très doux.)", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Marche doucement. La roche te remercie.", {}, "salut"), L("… (Il hoche la tête, puis tend l'oreille vers le Gouffre.) Il te dit au revoir aussi. Trois fois.", {}), L("Bonne nuit. Écoute, avant de dormir. Le silence a une note, lui aussi. Très basse. C'est la plus belle.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? (Il ferme les yeux.) Oui. Ton pas. Ta voix. La façon dont tu t'es arrêté pour écouter le Gouffre. Peu de gens s'arrêtent. Toi, si.", {})],
			}},
		# ================================================================ la Cantine Libre
		{"id": "gamelle", "nom": "Mémé Gamelle", "titre": "cuisinière de la Cantine Libre", "maison": "porte_gamelle", "village": "fronde", "femme": true,
			"agenda": [[6, 11, "fr_cantine_cuisine"], [11, 15, "fr_cantine_comptoir"], [15, 16.5, ["fr_assemblee_4", "fr_place_3"]], [16.5, 20, "fr_cantine_comptoir"], [20, 21.5, ["fr_fosse_8", "fr_cantine_table_4"]], [21.5, 6, "maison"]],
			"azur": {"cheveux": ROSE_PALE, "coiffure": "chignon", "yeux": Y_BLEU, "haut": PRUNE, "tablier": [0.92, 0.88, 0.8], "vieux": true, "lunettes": true, "taille": 0.86, "carrure": 1.25},
			"teinte": PEAU[1],
			"punk": {"tenue": "tablier", "patchs": true, "objet": "louche", "chapeau": "bandana", "lunettes": true},
			"humeur_base": 0.7, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.35, "rancunier": 0.1},
			"aime": {"champignon": 2.5, "panier_legumes": 2.5, "pelote_laine": 2.0, "miel": 1.5, "pomme": 1.5, "the_menthe": 1.5}, "deteste": {"gelee_slime": -1.5, "galette_algue": -0.5},
			"boutique": {"vend": {"potee_gamelle": 1, "pain_chaudiere": 1, "limonade_gouffre": 1, "galette_sarrasin": 1, "tarte_potiron": 2, "chocolat_chaud": 1}, "achete": {"champignon": 1, "pomme": 1, "panier_legumes": 2, "miel": 2, "graines": 1, "baies": 1}},
			"tics": ["Mange, mon caillou.", "Ressers-toi.", "Personne ne repart le ventre vide.", "Excalibur a parlé."],
			"surnoms": [[0, "mon caillou"], [25, "mon petit galet"], [50, "mon cristal"], [75, "mon diamant brut"], [95, "mon trésor de la mine"]],
			"repliques": {
				"accueil": [
					L("Ah ! Un estomac d'en haut ! Approche, mon caillou, approche. Mémé Gamelle, de la Cantine Libre. Ici, on mange tous à la même table, on paie ce qu'on peut, et personne ne repart le ventre vide. C'est la seule règle que l'Assemblée n'a jamais osé voter. Elle était là avant.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as maigri. Si, si. Depuis hier. Assieds-toi. Excalibur va s'occuper de toi.", {"visites_min": 2}, "rire"),
					L("Te voilà, mon diamant brut ! Je t'ai gardé le fond de la marmite. Le fond, c'est le meilleur : c'est là que les champignons se racontent leurs histoires.", {"visites_min": 5}, "rire"),
				],
				"humeur": [
					L("Bof. Le Petit Train m'a livré des champignons des Jardins tout tristes. Des champignons tristes, mon caillou, ça fait une potée triste. J'ai mis double ration de chansons dans la marmite. On verra.", {"humeur_max": -0.2}),
					L("À pleine vapeur ! Quarante-deux bols servis ce midi. Dont onze à des gens d'en haut. Un monsieur à moustache m'a demandé la carte. Je lui ai dit : « La carte, c'est moi. » Il a pris ce que je lui ai donné. Il en a repris deux fois.", {}, "rire"),
					L("Un peu fatiguée du bras. Excalibur pèse son poids, tu sais. Ressort a essayé de la soulever. Il a réussi ! À moitié. Il a dit qu'il était « l'élu ». Je lui ai dit que l'élu, il fait aussi la vaisselle.", {}, "rire"),
					L("Le matin, je suis la première debout. Avant les chaudières, avant les guirlandes, avant Brasero. J'allume le feu, je coupe les légumes, et je chante. Faux. Très faux. Écho dit que c'est son moment préféré. Il est trop gentil, ce garçon.", {"matin": true}),
					L("Le soir, je vais dans la fosse, tout au bord, avec mes bouchons d'oreilles en mie de pain. Je ne saute pas. Je hoche la tête. Bien fort. Bielle dit que je suis la plus vieille fan des Soupapes. Je suis surtout la seule qui leur apporte la soupe après.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Pendant trente-cinq ans, j'ai fait la cuisine pour les mineurs, à la grande cantine des Strates. Trois cents gamelles par jour. C'est de là que vient mon nom. Quand je suis partie, j'ai traversé le pont avec ma louche, ma marmite et mon tablier. Brasero a dit : « Enfin, on va manger. »", {}),
					L("Ma louche s'appelle Excalibur. Parce qu'il n'y a que moi qui peux la soulever. Enfin, moi et Bricole, avec un levier. Elle sert un bol entier d'un seul coup. Et elle sert aussi à taper sur la marmite pour appeler tout le monde. « DONG ! » Tout le monde vient. Même le chat.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le prix libre, mon caillou, c'est simple. Celui qui a beaucoup laisse beaucoup. Celui qui n'a rien laisse un merci. Celui qui n'a même pas de merci laisse un sourire. Et moi, avec tout ça, je fais la soupe de demain. Ça marche depuis vingt-cinq ans. Les comptables des Strates n'y comprennent rien.", {"sujet_min": ["lui", 2]}),
					L("Je n'ai jamais eu d'enfants. Mais j'ai nourri tous ceux de la Fronde. Rivet, Bielle, Écho, la petite Ysaé, maintenant Ressort… Quand Ysaé est montée vivre en haut, je lui ai mis un bocal de potée dans son sac. Elle m'a écrit : « Je l'ai mangé en trois jours, en pleurant. » Elle a toujours mangé trop vite, cette petite.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("La Cantine Libre, ce sont quatre grandes tables faites avec des portes de wagons, des bancs en tuyaux, et une marmite qui était une chaudière de locomotive. Bricole l'a coupée en deux. L'autre moitié, c'est la baignoire de Brasero.", {}, "rire"),
					L("Ici, on ne sert pas une goutte d'alcool. Jamais. De l'eau du Gouffre filtrée par les cristaux, de la limonade, des tisanes, du chocolat. Ceux qui veulent autre chose remontent à Hautefond. Ils reviennent toujours pour la limonade.", {"sujet_min": ["ile", 1]}),
					L("Mes légumes viennent des Jardins des Champignons, chez Bertille, de l'autre côté des Strates. Le Petit Train me les apporte jusqu'au tunnel, et Ressort finit la livraison en skate. Les carottes arrivent un peu étourdies. Mais elles arrivent.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Depuis que la Ligne a rouvert, il en descend de partout, des gens d'en haut. Des Hautefondais, et même un ou deux des Nuées, tout pâles d'être si bas. Je leur donne de la potée. Ils remontent avec des joues roses. Ça, c'est de la diplomatie, mon caillou.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Honorine, à La Marmite, la cantine des Strates, c'est mon ancienne apprentie. Elle met trop de sel. Je le lui dis tous les mardis. Elle me répond que je n'en mets pas assez. On a raison toutes les deux. On déjeune ensemble tous les mardis.", {}, "rire"),
					L("Bertille, des Jardins des Champignons, m'a apporté un champignon qui brille dans le noir. Je l'ai mis dans la potée. Ce soir-là, toute la Cantine avait les dents qui brillaient. Le concert n'a jamais été aussi lumineux.", {"a_rencontre": "bertille"}, "rire"),
					L("Firmin, le patron du Piston Joyeux, là-haut, est descendu goûter ma potée. Il a pris des notes. Il a demandé la recette. Je lui ai dit : « Une louche de champignons, une louche d'amour, et Excalibur. » Il a écrit « Excalibur » sur son carnet. Il cherche encore où ça s'achète.", {"a_rencontre": "firmin"}, "rire"),
					L("Brasero mange toujours à la même table, la deuxième, et il laisse toujours une pièce sous son bol, « pour la soupe d'un inconnu ». Ça fait vingt-cinq ans que je le vois faire, et il dit qu'il le faisait déjà avant. Je n'ai jamais su qui était l'inconnu. Peut-être que c'est toi.", {}),
					L("Tu as mangé à La Conque, au fond de la mer ? Chez Josette ? Je lui ai écrit pour savoir si ses soupes étaient à prix libre. Elle m'a répondu : « À prix doux, et à cœur grand ouvert. » Alors je lui ai envoyé une louche. Pas Excalibur, mon caillou : Excalibur ne quitte jamais la Fronde. Sa petite sœur. Durandal. Elle sert la soupe de salicorne, maintenant. Elle a de la chance.", {"a_rencontre": "josette"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Tu as une tête à avoir faim !", {"visites_max": 0}, "salut"), L("{surnom} ! La potée est chaude ! Excalibur t'attend !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("File, mon caillou. Et reviens avec un ventre vide, j'ai horreur de gâcher.", {}, "salut"), L("À plus tard ! Et ne cours pas sur le Pont après le repas, ça remue la potée.", {}, "rire"), L("Bonne nuit, mon caillou. La marmite dort, Excalibur dort, et moi, je vais dormir aussi. Dans cet ordre-là.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Mon caillou, je me souviens de tous les ventres que j'ai nourris. Toi, tu as repris deux fois de la potée et tu as dit merci les deux fois. Ça, ça se retient.", {})],
				"boutique": [L("Potée, pain de chaudière, galettes, limonade du Gouffre ! Tout est fait ici, tout est presque gratuit. Le reste, tu le laisses dans la boîte, si tu peux. Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ le Mur des Fresques
		{"id": "fusain_fr", "nom": "Fusain", "titre": "peintre des fresques de la roche", "maison": "porte_fusain", "village": "fronde",
			"agenda": [[9, 13, "fr_fresque_1"], [13, 14, ["fr_cantine_table_2", "fr_cantine_table_3"]], [14, 18, "fr_fresque_2"], [18, 20, ["fr_place_3", "fr_assemblee_5"]], [20, 23, ["fr_fosse_2", "fr_fosse_3"]], [23, 9, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "crete_courte", "yeux": Y_AMBRE, "haut": TOILE, "taille": 1.02, "carrure": 0.85},
			"teinte": PEAU[5],
			"punk": {"tenue": "salopette", "patchs": true, "objet": "bombe_peinture", "chapeau": "casquette"},
			"humeur_base": 0.55, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.95, "susceptible": 0.45, "rancunier": 0.05},
			"aime": {"pinceau": 2.5, "pot_rouge": 2.0, "pot_turquoise": 2.0, "bombe_peinture": 2.0, "carte_postale": 1.5, "chocolat_chaud": 1.5}, "deteste": {"lunettes_kaleido": -1.0, "vieille_botte": -0.5},
			"tics": ["Ne bouge pas… voilà.", "Ça, c'est une fresque.", "Couleur de braise, ça.", "Tu as une tête à peindre."],
			"surnoms": [[0, "mon modèle"], [25, "mon modèle préféré"], [50, "ma couleur"], [75, "mon chef-d'œuvre"], [95, "ma fresque vivante"]],
			"repliques": {
				"accueil": [
					L("Ne bouge pas. … Encore un peu. … Voilà ! Tu es sur le Mur. Enfin, ton chapeau. Bonjour ! Fusain, peintre de la roche. Tout ce que tu vois sur cette paroi, c'est l'histoire de la Fronde. Et maintenant, il y a un petit bout de toi dedans.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens voir : je t'ai ajouté une écharpe. Tu n'en as pas ? Ce n'est pas grave. Sur la roche, tu as toujours chaud.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bof. Le rouge ne veut pas sécher. La roche est humide, aujourd'hui : le Gouffre a soufflé toute la nuit. Mon coucher de soleil coule. Ça fait un coucher de soleil qui pleure. C'est joli, remarque. Mais ce n'était pas prévu.", {"humeur_max": -0.2}),
					L("À pleine vapeur ! J'ai trouvé le bleu ! Le vrai bleu des cristaux de la mine : Opaline, de l'Atelier des Lumières, m'a donné de la poudre de cristal pilé. Sur la roche, ça brille dans le noir. Ce soir, le Mur va s'allumer. Viens voir.", {}, "rire"),
					L("Pensif. Je cherche comment peindre un son. Bielle m'a dit : « Peins le concert. » D'accord. Mais comment on peint un « boum-tchak » ? J'ai essayé avec du jaune. Ça faisait plutôt « tiii ».", {}),
					L("Le matin, la lumière des guirlandes est douce sur le Mur. Toutes les couleurs se réveillent une par une. Le rouge d'abord, il est impatient. Le bleu à la fin. Il est timide. Comme moi.", {"matin": true}),
					L("Le soir, je vais dans la fosse avec un carnet et un bout de fusain. Je dessine les gens qui sautent. Ils ne restent jamais immobiles. Alors je dessine des traits qui bougent. Brasero dit que c'est ma meilleure période.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je m'appelle Fusain parce que j'ai commencé avec le charbon des vieilles chaudières. Je dessinais sur les murs, sur les wagons, sur les portes. Partout. Un jour, l'Assemblée a voté : « Fusain peut peindre sur la roche. Toute la roche. Mais pas sur les canapés. » J'ai respecté les canapés.", {}),
					L("Mes couleurs, je les fabrique. Le noir, c'est la suie de la Grande Forge. Le rouge, la rouille des rails de Rivet. Le vert, de la mousse des Jardins. Le bleu, du cristal pilé. Et le doré, c'est du laiton râpé du Soleil de Laiton. Enfin, une toute petite miette. Ne le dis pas à la Guilde.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je ne parle pas très bien. Je peins mieux. Quand quelqu'un est triste, je ne dis rien : je peins quelque chose pour lui sur le Mur. Une fleur, une étoile, une vague. Le lendemain, il passe devant, et il comprend. C'est ma façon de parler.", {"sujet_min": ["lui", 2]}),
					L("Tu sais ce que je n'ai jamais réussi à peindre, {surnom} ? Le ciel. Je ne l'ai vu qu'une fois, en montant à Hautefond pour la réouverture. Je suis resté une heure sur la Place, la tête en l'air, la bouche ouverte. Une dame m'a donné une pièce. Je l'ai gardée. Elle est bleue de peinture, maintenant.", {"sujet_min": ["lui", 3]}, "rire"),
				],
				"ile": [
					L("Le Mur des Fresques raconte tout. Là, la fondation : Brasero, tout jeune, qui allume le premier brasero dans une brouette. Là, le Pont des Frondeurs qu'on soude. Là, la première Assemblée. Là, Ysaé qui monte en haut sur une échelle de lumière. Et là… un espace vide. C'est pour la suite.", {}),
					L("La Fronde est la seule ville de l'archipel où l'on peut peindre sur sa maison sans demander. Les conteneurs, les chaudières, les passerelles. Chaque maison a sa couleur. Celle de Bricole change toutes les semaines. Ressort repeint par-dessus avec ses roues.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Dans les Strates, à côté, tout est rangé, propre, à angle droit. La Grande Horloge, les rails, les galeries. C'est beau aussi. Moi, je leur ai proposé de peindre la Gare. Ils ont dit non. Puis pendant les travaux de la Ligne, la Gare s'est retrouvée toute colorée. Personne ne sait comment. (Il siffle.)", {"sujet_min": ["ile", 2]}, "rire"),
					L("La prochaine fresque, ce sera la Colonne. Les quatre mondes, l'un au-dessus de l'autre : les Nuées en blanc, Hautefond en doré, les Strates en couleur de roche, et le Dôme d'Azur en bleu, tout en bas. Avec une petite cabine qui monte et qui descend. Et toi dedans, peut-être.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Une bibliothécaire d'en haut, Mademoiselle Philippine, a dessiné une carte de la Fronde sans jamais l'avoir vue, rien qu'avec les mots d'Ysaé. Je l'ai vue, la carte. Il y a des erreurs partout. Et c'est la plus belle carte du monde. Je vais la peindre sur le Mur. Avec les erreurs.", {"a_rencontre": "philippine"}),
					L("Opaline, de l'Atelier des Lumières, me fait des petites lampes de cristal pour éclairer le Mur. En échange, je lui peins des étoiles sur ses abat-jour. Les gens des Strates disent que c'est « trop coloré ». Puis ils achètent tous les abat-jour.", {"a_rencontre": "opaline"}, "rire"),
					L("Il paraît que la peintre des Nuées, Ombeline, peint le coucher de soleil tous les soirs. Moi, je n'ai jamais vu de coucher de soleil. Elle n'a jamais vu de fresque sur la roche. On s'écrit des lettres avec des dessins dedans. Je lui envoie des braseros. Elle m'envoie des soleils.", {}),
					L("Ressort a dessiné un skate sur le Mur. Tout petit, dans un coin. Il croit que je ne l'ai pas vu. Je l'ai vu. Je lui ai ajouté des flammes. Il est très fier. Il croit qu'elles ont poussé toutes seules.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Ne bouge pas ! … Trop tard. Bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir le Mur, j'ai ajouté quelque chose !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Salut, {surnom} ! Ne te lave pas trop vite, tu as un peu de bleu sur le nez. Ça te va bien.", {}, "rire"), L("À plus ! Quand tu reviendras, regarde le Mur. Tu y seras peut-être un peu plus grand.", {}, "salut"), L("Bonne nuit ! Les fresques dorment aussi. Enfin, elles brillent un peu. C'est le cristal. Elles rêvent en bleu.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Je t'ai peint. Une fois qu'on est sur la roche, on ne s'en va plus. C'est pour ça qu'il faut faire attention à ce qu'on peint.", {})],
			}},
		# ================================================================ l'Atelier Libre
		{"id": "bricole", "nom": "Bricole", "titre": "inventrice de l'Atelier Libre", "maison": "porte_bricole", "village": "fronde", "femme": true,
			"agenda": [[8, 12, "fr_atelier_etabli"], [12, 13, "fr_cantine_table_4"], [13, 18, "fr_atelier_etabli"], [18, 20, ["fr_atelier_2", "fr_assemblee_2"]], [20, 22.5, ["fr_fosse_4", "fr_fosse_5"]], [22.5, 8, "maison"]],
			"azur": {"cheveux": JAUNE_LAITON, "coiffure": "queue", "yeux": Y_VERT, "haut": VERT_BOUTEILLE, "tablier": [0.3, 0.22, 0.16], "lunettes": true, "carrure": 1.05},
			"teinte": PEAU[0],
			"punk": {"tenue": "salopette", "patchs": true, "objet": "cle_molette", "lunettes": true, "chapeau": "bandana"},
			"humeur_base": 0.7, "traits": {"bavard": 0.95, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"engrenage": 2.5, "ressort": 2.0, "rouage": 2.0, "biscuit_engrenage": 2.0, "canard_mecanique": 2.0, "cafe_vapeur": 1.5, "boulon": 1.5}, "deteste": {"boite_a_rien": -1.0, "gelee_slime": -1.0},
			"tics": ["Ça se répare !", "Passe-moi la clé de douze !", "Rien ne se jette.", "Et si on y mettait une soupape ?"],
			"surnoms": [[0, "l'apprenti"], [25, "mon aide-soudeur"], [50, "mon tournevis"], [75, "ma pièce de rechange préférée"], [95, "mon chef-d'œuvre de récup'"]],
			"repliques": {
				"accueil": [
					L("Attention, ça va… (PSCHIIIT !) … Voilà. Ça a marché. Enfin, je crois. Bonjour ! Bricole, Atelier Libre. Ici, on répare tout, et on le répare ensemble. Tu as un truc cassé ? Non ? Tu en auras un. Tout le monde finit par en avoir un.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tiens, tiens-moi ça. Non, pas comme ça. Comme ça. Voilà. Ne bouge plus pendant… disons… une heure ? Je plaisante. Dix minutes.", {"visites_min": 2}, "rire"),
					L("Mon chef-d'œuvre de récup' ! Regarde ce que j'ai fait avec le boulon que tu m'as laissé l'autre jour : une machine qui dit merci. Elle fait « pschit-merci ». C'est le pschit qui est le plus réussi.", {"visites_min": 5}, "rire"),
				],
				"humeur": [
					L("Grinçante. La Machine-à-Crêpes-à-Vapeur a encore lancé une crêpe au plafond. Elle y est restée. Au plafond d'une caverne, c'est haut. Elle est toujours là-haut. Elle sèche. Écho dit qu'elle fait de l'écho.", {"humeur_max": -0.2}, "rire"),
					L("À pleine vapeur ! J'ai réparé onze choses aujourd'hui : un grille-pain, une guitare, deux skates, une chaudière, un parapluie et cinq fois la même lampe. La lampe a un problème. Ou elle m'aime bien.", {}, "rire"),
					L("Contente. Ce matin, un monsieur des Strates m'a apporté une montre en me demandant de la réparer. Je lui ai donné la clé, le tournevis, et je lui ai montré. Il l'a réparée lui-même. Il est reparti tout fier. Ici, on ne répare pas POUR toi. On répare AVEC toi.", {}),
					L("Le matin, j'allume la chaudière de l'atelier en chantant la chanson des soupapes : « Pschit, pschit, la pression monte… » C'est moi qui l'ai écrite. Bielle dit qu'elle n'ira jamais dans un concert. Je dis que c'est dommage pour les concerts.", {"matin": true}, "rire"),
					L("Le soir, je vais dans la fosse et je surveille l'orgue à vapeur de loin. Quarante-deux tuyaux. Si l'un d'eux tousse, je cours. En général, c'est le trente-sept. Il a toujours été un peu fragile des poumons.", {"soir": true}),
				],
				"lui": [
					L("L'orgue à vapeur des Soupapes, c'est moi qui l'ai fait. Quarante-deux tuyaux recyclés : des tuyaux de chaudière, de poêle, de locomotive, et un vieux tuyau de la Colonne, qu'Anatole m'a donné quand on a changé ceux de la Ligne. Il joue tout seul, sur des cartes perforées. Il fait les refrains. Il les fait très bien.", {}),
					L("Mon fils, Ressort, a onze ans. Il roule sur une planche que je lui ai faite avec une porte de four et quatre roues de wagonnet. Je l'ai limitée à la vitesse d'un escargot pressé. Il l'a débridée en deux jours. C'est mon fils, ça.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma règle, à l'Atelier Libre : on ne jette rien. Une vis toute seule, c'est une vis qui attend ses copines. Un vieux réveil, c'est un futur grille-pain. Et un grille-pain, c'est un futur réveil. Bon, celui-là n'a pas marché. Il sonne quand le pain est prêt. À trois heures du matin.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Quand j'étais petite, je démontais tout. Les jouets, les lampes, la radio de ma mère. Je ne savais pas remonter. Ma mère pleurait un peu. Un jour, Brasero m'a dit : « Démonter, c'est la moitié du chemin. L'autre moitié, on la fait ensemble. » Depuis, je remonte tout. Presque.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("L'Atelier Libre, c'est une grande chaudière couchée, avec des établis dedans et des outils accrochés partout. Tout le monde peut entrer, prendre un outil, réparer son truc, et remettre l'outil. La règle, c'est de remettre l'outil. Pas tout le monde l'a comprise. Je pense à quelqu'un qui fait du skate.", {}, "rire"),
					L("Toute la Fronde, c'est de la récup'. Les maisons sont des conteneurs et des chaudières empilés, reliés par des passerelles de rails. Les guirlandes, ce sont de vieilles lampes de mine. Les canapés de l'Assemblée viennent de toutes les maisons des Strates. Rien de neuf. Tout est vivant.", {"sujet_min": ["ile", 1]}),
					L("Le Soleil de Laiton, la grande lampe des Strates, c'est la plus belle machine du monde. Je suis montée la voir de près, une fois, par les échelles de service. Une merveille. Il manquait juste une soupape. J'ai proposé à la Guilde. Ils ont dit non. Sans même regarder mes plans.", {"sujet_min": ["ile", 2]}, "rire"),
					L("La Ligne a rouvert, et j'ai enfin vu la Colonne de l'intérieur ! Les câbles, les poulies, les contrepoids… J'ai demandé à Anatole si je pouvais toucher. Il a dit : « Avec les yeux. » J'ai touché avec les yeux pendant tout le trajet. Mes yeux étaient pleins de graisse.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Firmin, du Piston Joyeux, en haut, a une machine à chocolat qui siffle comme une locomotive. Il dit qu'il l'a achetée à un vieux mécanicien des Strates. Ce vieux mécanicien, c'était mon maître d'apprentissage. Et la machine, je l'ai rafistolée avant qu'elle monte. Le sifflet, c'est moi. Exprès.", {"a_rencontre": "firmin"}, "rire"),
					L("L'horloger d'en haut, Gaspard, il paraît qu'il ne supporte pas qu'un rouage soit « hors tolérance ». Je lui ai envoyé un réveil de ma fabrication, avec trois rouages hors tolérance. Il me l'a renvoyé. Réparé. Avec un mot : « C'est juste. » Je vais l'encadrer.", {"a_rencontre": "gaspard_hf"}, "rire"),
					L("L'inventrice des Nuées, Mireille Volta, m'a écrit. Elle a inventé un parapluie qui monte. Moi, j'ai inventé une pelle qui descend. On pense s'associer. Ça ferait un parapluie qui ne bouge pas. C'est déjà inventé, mais le nôtre sera mieux.", {"a_rencontre": "mireille"}, "rire"),
					L("Lumi, au Troc, me garde tous les boulons trop moches pour faire des bijoux. Moi, je lui garde tous les boulons trop beaux pour faire des machines. On se les échange le jeudi. C'est le plus vieux troc de la Fronde.", {}),
				],
				"interpelle": [L("Hé ! Tu n'aurais pas une clé de douze, par hasard ?", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir ce que j'ai inventé ! Ça ne marche pas encore, mais c'est beau !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut, {surnom} ! Et si quelque chose se casse, ne le jette pas : apporte-le-moi !", {}, "salut"), L("À plus ! Attention en sortant, la porte a un ressort. Et ce n'est pas mon fils. Enfin, pas cette fois.", {}, "rire"), L("Bonne nuit ! J'éteins la chaudière. Pschiiit… Elle soupire toujours avant de dormir. Moi aussi.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu as tenu la lampe pendant que je réparais la guitare de Bielle. Tu as tenu la lampe très bien. Peu de gens savent tenir une lampe.", {}, "rire")],
			}},
		# ================================================================ le Troc
		{"id": "lumi_fr", "nom": "Lumi", "titre": "gardienne du Troc, bijoutière de boulons et de cristal", "maison": "porte_lumi", "village": "fronde", "femme": true,
			"agenda": [[9, 12, "fr_troc_etabli"], [12, 13, ["fr_cantine_table_1", "fr_cantine_table_2"]], [13, 18, "fr_troc_comptoir"], [18, 20, "fr_troc_etabli"], [20, 23, ["fr_fosse_6", "fr_fosse_1", "fr_assemblee_6"]], [23, 9, "maison"]],
			"azur": {"cheveux": VIOLET_CRISTAL, "coiffure": "tresse", "yeux": Y_VIOLET, "haut": [0.28, 0.2, 0.36], "foulard": CUIVRE, "lunettes": true, "taille": 0.95},
			"teinte": PEAU[3],
			"punk": {"tenue": "robe_recup", "patchs": true, "objet": "panier", "lunettes": true},
			"humeur_base": 0.65, "traits": {"bavard": 0.6, "humour": 0.65, "curiosite": 0.85, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"eclat_cristal": 3.0, "cristal_astral": 2.5, "boulon": 2.0, "cristal_soufre": 2.0, "perle": 2.0, "bague_boulon": 1.5, "coquillage": 1.5}, "deteste": {"coupe_course": -1.0, "vieille_botte": -0.5},
			"boutique": {"vend": {"bague_boulon": 5, "eclat_cristal": 4, "boulon": 1, "ressort": 1, "engrenage": 2, "rouage": 2}, "achete": {"boulon": 1, "ressort": 1, "engrenage": 2, "rouage": 2, "eclat_cristal": 3, "cristal_soufre": 3, "coquillage": 1, "perle": 6}},
			"tics": ["Ça brille, hein ?", "Un boulon, c'est un bijou qui s'ignore.", "On échange ?", "Regarde de plus près."],
			"surnoms": [[0, "toi qui brilles un peu"], [25, "mon éclat"], [50, "mon petit cristal"], [75, "ma pierre précieuse"], [95, "mon trésor du Troc"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Approche, regarde. Tu peux toucher. Lumi, du Troc. Ici, on ne vend presque rien : on échange. Un boulon contre une bague, une bague contre une histoire, une histoire contre un sourire. Ça brille, hein ? Ce sont des boulons. Si, si. Regarde de plus près.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu m'apportes quelque chose qui brille ? Même un tout petit peu ? Même un bouton ? Je fais des merveilles avec les boutons.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Un peu terne. Personne n'a rien apporté au Troc, aujourd'hui. Rien. Même pas une vis. Le Troc, c'est comme un estomac : vide, il fait des bruits tristes.", {"humeur_max": -0.2}),
					L("Lumineuse ! Ludovic, des Mines, m'a apporté un éclat de cristal tombé du front de taille. Il chante quand on souffle dessus. J'en ai fait un pendentif. Je l'ai mis au cou de la statue du Troc. Elle chante, maintenant.", {}, "rire"),
					L("Contente. Une dame d'en haut a échangé son chapeau à plume contre un collier de boulons. Elle est repartie toute fière, les cheveux au vent. Et moi, j'ai un chapeau à plume. Je ne sais pas quoi en faire. Je vais en faire un abat-jour.", {}, "rire"),
					L("Le matin, je trie ce qu'on m'a apporté la veille. Une boîte pour ce qui brille, une boîte pour ce qui pourrait briller, une boîte pour ce qui brillera un jour. La troisième boîte est la plus grande. C'est normal. Tout finit par briller, si on le frotte assez.", {"matin": true}),
					L("Le soir, je vais au concert avec tous mes bijoux. Sous les lumières de la scène, je fais des reflets partout. Rivet dit que je suis la boule à facettes de la Fronde. C'est le plus beau compliment qu'on m'ait jamais fait.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Le métier, je l'ai appris toute seule, en ramassant ce que les autres jetaient. Un boulon tordu, ça ne sert plus à rien. Sauf si on le regarde de près. De très près. Alors on voit qu'il a une forme de cœur. Et ça, ça sert à quelque chose.", {}),
					L("C'est moi qui ai appris le métier à Ysaé. Elle avait huit ans. Elle venait au Troc tous les jours, elle s'asseyait sur la caisse, et elle regardait mes mains. Un jour, elle m'a pris la pince et elle a fait une bague. Du premier coup. J'ai su qu'elle irait plus loin que moi. Plus haut, même.", {"sujet_min": ["lui", 1]}),
					L("« Ça brille, hein ? » C'est ma phrase. Ysaé me l'a prise. Maintenant, elle la dit au Grand Marché de Hautefond. Je ne lui en veux pas. Une phrase qui monte en haut, c'est un peu de moi qui voit le jour.", {"sujet_min": ["lui", 2]}),
					L("Je vais te dire un secret, {surnom}. Je n'ai jamais quitté la Fronde. Jamais. Même pas pour aller dans les Strates. J'ai peur des grands espaces. Ici, la caverne me tient comme une main. Mais depuis que la Ligne a rouvert… je regarde la Colonne. Un peu plus chaque jour.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("Le Troc, c'est la grande étagère au milieu de la Fronde. Tu donnes ce que tu n'utilises plus, tu prends ce dont tu as besoin. Pas de prix, pas de compte. Juste une règle : on ne prend pas le dernier de quelque chose. Il faut toujours laisser une chance au suivant.", {}),
					L("Les cristaux de la Fronde poussent au bord du Gouffre, là où la vapeur de la rivière remonte. Ils sont bleus, verts, et parfois roses quand il fait plus chaud. Je ne les arrache pas : je ramasse ceux qui tombent tout seuls. Ce sont les plus beaux. Ils ont choisi.", {"sujet_min": ["ile", 1]}),
					L("La Colonne, c'est le plus grand bijou du monde, si on y pense. Un collier qui relie quatre mondes, du ciel jusqu'au fond de la mer. Les Nuées, Hautefond, les Strates, le Dôme d'Azur. Quatre perles sur un même fil. Ysaé dit que je suis poétique. Je dis que je suis bijoutière.", {"sujet_min": ["ile", 2]}),
					L("Depuis que la Ligne a rouvert, des gens d'en haut descendent au Troc. Ils ne comprennent pas tout de suite. Ils demandent : « C'est combien ? » Je leur dis : « Qu'est-ce que tu as ? » Ils fouillent leurs poches. Ils trouvent toujours quelque chose. Un bouton, un ticket, une bille. Tout le monde a un trésor dans ses poches.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Ysaé, tu l'as vue ? Elle t'a montré sa bague qui tourne ? Le rouage qui tourne quand on bouge le doigt ? C'est une idée à elle. Je ne la lui ai jamais apprise. (Elle sourit très fort.) C'est la plus belle chose qu'une élève puisse faire.", {"a_rencontre": "ysae"}),
					L("Le Bourgmestre d'en haut a une broche en forme de Colonne, sous son écharpe. C'est Ysaé qui l'a faite. Mais le petit cristal au sommet, c'est moi qui l'ai taillé. Alors, quelque part, le Bourgmestre porte un bout de la Fronde contre son cœur. Ça me fait rire toute la journée.", {"a_rencontre": "hector_hf"}, "rire"),
					L("La petite Pimprenelle, d'en haut, collectionne les boulons ! Elle est venue au Troc avec un sac plein. Elle n'a rien voulu échanger. Elle voulait juste me montrer. On a passé l'après-midi à les regarder un par un. Le meilleur après-midi du mois.", {"a_rencontre": "pimprenelle_hf"}, "rire"),
					L("Bricole me garde les boulons trop beaux pour ses machines. Je lui garde ceux trop moches pour mes bijoux. Le jeudi, on échange. Mais je triche un peu : je lui donne aussi des beaux. Elle triche aussi. On le sait toutes les deux.", {}),
				],
				"interpelle": [L("Hé ! Tu veux voir ce qui brille ?", {"visites_max": 0}, "salut"), L("{surnom} ! Viens, j'ai un nouveau trésor !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom} ! Et regarde par terre en marchant : il y a toujours un boulon qui attend quelqu'un.", {}, "salut"), L("À plus ! Tu as des choses dans tes poches ? Garde-les. Ce sont peut-être des trésors.", {}, "rire"), L("Bonne nuit ! Les cristaux du Gouffre brillent plus fort la nuit. Si tu passes par le Pont, fais un vœu sur le plus bleu.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Tu as regardé un boulon de très près, la première fois. Et tu as souri. Ça, c'est le début d'une bijoutière. Ou d'un bijoutier.", {})],
				"boutique": [L("Bagues de boulons, éclats de cristal, pièces de récup' ! Ce qui est sur l'étagère se troque, ce qui est dans la vitrine coûte trois fois rien. Ça brille, hein ? Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ le Skatepark
		{"id": "ressort", "nom": "Ressort", "titre": "skateur du Skatepark (11 ans), le fils de Bricole", "maison": "porte_ressort", "village": "fronde",
			"agenda": [[8, 10, "fr_skate_1"], [10, 12, ["fr_atelier_2", "fr_fresque_1", "fr_pont"]], [12, 13, "fr_cantine_table_3"], [13, 17, ["fr_skate_1", "fr_skate_2"]], [17, 18.5, ["fr_place_4", "fr_troc_comptoir"]], [18.5, 19.5, "fr_cantine_table_4"], [19.5, 21.5, "fr_fosse_7"], [21.5, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "yeux": Y_VERT, "haut": [0.85, 0.42, 0.12], "enfant": true, "taille": 0.78},
			"teinte": PEAU[1],
			"punk": {"tenue": "enfant", "patchs": true, "objet": "skate", "chapeau": "casque_skate"},
			"humeur_base": 0.8, "traits": {"bavard": 1.0, "humour": 0.85, "curiosite": 0.95, "susceptible": 0.4, "rancunier": 0.05},
			"aime": {"ressort": 3.0, "sirop_menthe": 2.5, "glace": 2.5, "biscuit_engrenage": 2.0, "limonade_gouffre": 2.0, "boulon": 1.5}, "deteste": {"champignon": -1.0, "tisane_brume": -0.5},
			"tics": ["Trop fort !", "Regarde, regarde !", "Boïng !", "Même pas mal !"],
			"surnoms": [[0, "le grand d'en haut"], [25, "mon pote"], [50, "mon équipier"], [75, "mon frère de rampe"], [95, "mon meilleur copain de tous les mondes"]],
			"repliques": {
				"accueil": [
					L("Salut ! Tu viens d'en haut ? Du VRAI haut ? Avec le ciel ? Regarde, regarde : (Il saute sur sa planche, fait un demi-tour et retombe.) Boïng ! Même pas mal ! Moi, c'est Ressort, j'ai onze ans, et je suis le meilleur skateur de la Fronde. Je suis aussi le seul. Mais je suis très bon.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as vu ? J'ai réussi le saut de la chaudière ! Enfin, à moitié. L'autre moitié, c'était la chaudière qui a sauté sur moi. Même pas mal !", {"visites_min": 2}, "rire"),
					L("Mon frère de rampe ! Viens, je t'apprends le « Boïng ». C'est ma figure. On saute, on tourne, et on dit « Boïng ». Le plus important, c'est de dire « Boïng ».", {"visites_min": 5}, "rire"),
				],
				"humeur": [
					L("Bof. Je suis tombé sur le genou. Maman l'a réparé avec un pansement. Elle a voulu mettre une soupape dessus. J'ai dit non. Elle a dit « dommage ». Elle répare tout, Maman. Même les genoux.", {"humeur_max": -0.2}),
					L("TROP BIEN ! Tom est venu au Skatepark après la forge ! Il a fait un tour de rampe ! Il est tombé quatre fois ! Il a dit « même pas mal » quatre fois ! C'est moi qui lui ai appris à le dire. Ça marche.", {}, "rire"),
					L("Un peu énervé. Maman dit que je ne pourrai choisir ma couleur de cheveux qu'à quinze ans. QUINZE ! J'en ai onze ! Ça fait quatre ans ! Quatre ans, c'est presque toute une vie ! … J'ai déjà choisi, de toute façon. Rouge et turquoise. Les deux. Je négocie.", {}),
					L("Le matin, le Skatepark est tout vide et tout calme. J'adore. J'entends mes roues sur la tôle : « vrrrr… tac ! » Le « tac », c'est quand je retombe. Le « aïe », c'est quand je retombe mal. Ce matin, que des « tac ».", {"matin": true}, "rire"),
					L("Le soir, je vais dans la fosse, tout devant, à côté de Mémé Gamelle. Elle me tient par la capuche quand ça saute trop fort. Maman dit que je dois rentrer à vingt et une heures trente. Je rentre à vingt et une heures trente. Et deux minutes.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je m'appelle Ressort parce que, bébé, je sautais tout le temps dans mon berceau. Boïng, boïng, boïng. Maman a dit : « Celui-là, il a un ressort dans les pieds. » Elle a vérifié. Il n'y en avait pas. Mais le nom est resté.", {}),
					L("Ma planche, c'est Maman qui l'a faite, avec une porte de four et des roues de wagonnet. Elle l'avait réglée « vitesse escargot ». Je l'ai débridée. Maintenant, elle va vitesse « escargot très, très pressé ». Maman fait semblant d'être fâchée. Mais elle a souri.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon meilleur copain, c'est Tom, l'apprenti de la Grande Forge des Strates. Lui, il tape sur l'enclume. Moi, je tape sur la rampe. On a le même âge, les mêmes bleus aux genoux, et on veut tous les deux changer le monde. Lui avec un marteau, moi avec une planche.", {"sujet_min": ["lui", 2]}),
					L("Tu veux savoir un secret ? Quand je serai grand, je veux construire un skatepark dans la Colonne. Une rampe qui descend de la Cité des Nuées jusqu'au Dôme d'Azur. Quatre mondes en une seule descente ! Maman dit que c'est impossible. Elle dit ça avant chaque invention. Après, elle la construit.", {"sujet_min": ["lui", 3]}, "rire"),
				],
				"ile": [
					L("Le Skatepark, c'est tout au bout de la Fronde. Les rampes, ce sont des moitiés de vieilles chaudières. La grande, c'est « la Baleine ». La petite, c'est « le Bol ». Et le gros tuyau, c'est « le Tunnel de la Mort ». Enfin, « le Tunnel de la Mort Pas Grave ». Maman a fait changer le nom à l'Assemblée.", {}, "rire"),
					L("Le Pont des Frondeurs, je le traverse en skate. Brasero dit que c'est interdit. Mais personne ne l'a jamais voté. Alors je le traverse. Doucement. Très doucement. Il y a le Gouffre en dessous, quand même. Je ne suis pas fou. Je suis courageux. C'est différent.", {"sujet_min": ["ile", 1]}),
					L("Depuis que la Ligne a rouvert, je suis monté à Hautefond ! Il y a un CIEL ! Bleu ! Tout en haut ! Sans roche ! J'ai eu peur qu'il tombe. Pimprenelle m'a dit qu'il ne tombait jamais. Elle vérifie tous les matins. Je la crois.", {"sujet_min": ["ile", 2]}, "rire"),
					L("La Ligne du Dôme d'Azur, en dessous de la Gare des Strates, était fermée pour travaux. J'avais collé l'oreille à la grille. J'avais entendu « glouglou ». Écho disait que c'était la mer. Tom, que c'était mon ventre. On avait voté : deux voix contre une pour mon ventre. Elle a rouvert, je suis descendu vérifier : c'était la mer ! J'ai gagné en appel.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Tom ! L'apprenti de la Grande Forge ! Tu le connais ? Il m'a forgé une petite plaque pour ma planche, avec mon nom dessus : « RESORT ». Il manque un S. On ne lui a rien dit. Elle est parfaite.", {"a_rencontre": "tom_st"}, "rire"),
					L("Pimprenelle, la fille de la forgeronne d'en haut ! Elle collectionne les boulons ! Je lui en ai donné un du Pont des Frondeurs. Elle l'a mis dans une boîte toute seule. Elle dit que c'est « le boulon le plus courageux du monde ». Elle a raison. Il tient au-dessus du Gouffre.", {"a_rencontre": "pimprenelle_hf"}, "rire"),
					L("En haut, il y a un horloger qui s'appelle Gaspard Ressort. RESSORT ! Comme moi ! Il dit que c'est son nom de famille. Moi, c'est mon nom tout court. Je crois qu'on est un peu cousins. Il n'est pas d'accord. Mais il m'a donné un ressort.", {"a_rencontre": "gaspard_hf"}, "rire"),
					L("Anatole, le liftier de la Ligne des Strates, ne me laisse pas monter dans la cabine avec ma planche « en position de roulement ». Alors je la porte sous le bras. Mais je fais le bruit des roues avec ma bouche. Vrrrr. Il fait semblant de ne pas entendre.", {"a_rencontre": "anatole"}, "rire"),
				],
				"interpelle": [L("Hé ! Regarde, regarde ! Boïng !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir ma nouvelle figure !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut ! Et si tu tombes, dis « même pas mal ». Ça marche à tous les coups. Presque.", {}, "salut"), L("À plus ! Je retourne au Skatepark. La Baleine m'attend !", {}, "rire"), L("Bonne nuit ! Maman a dit vingt et une heures trente. Il est vingt et une heures trente. Et deux minutes. J'y vais, j'y vais !", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu m'as regardé faire le Boïng, et tu as applaudi même quand je suis tombé. Tu es mon public préféré.", {}, "rire")],
			}},
		# ================================================================ l'Assemblée
		{"id": "brasero", "nom": "Brasero", "titre": "fondateur de la Fronde, gardien du brasero de l'Assemblée", "maison": "porte_brasero", "village": "fronde",
			"agenda": [[7, 12, "fr_assemblee_1"], [12, 13.5, "fr_cantine_table_2"], [13.5, 15, ["fr_fresque_1", "fr_pont"]], [15, 19, "fr_assemblee_1"], [19, 20, "fr_cantine_table_2"], [20, 23, ["fr_assemblee_1", "fr_fosse_8"]], [23, 7, "maison"]],
			"azur": {"cheveux": ORANGE_BRAISE, "coiffure": "crete", "barbe": "longue", "yeux": Y_GRIS, "haut": CUIR, "vieux": true, "taille": 0.94, "carrure": 1.15},
			"teinte": PEAU[2],
			"punk": {"tenue": "perfecto", "clous": true, "patchs": true, "objet": "livre"},
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.7, "susceptible": 0.25, "rancunier": 0.1},
			"aime": {"buche": 2.5, "potee_gamelle": 2.5, "pain_miel": 2.0, "the_menthe": 2.0, "minerai_fer": 1.5, "eclat_cristal": 1.5}, "deteste": {"badge_usine": -1.0, "coupe_course": -0.5},
			"tics": ["Hm. Réfléchissons.", "Qui tient la clé ?", "Le feu est d'accord.", "Mon petit, écoute bien."],
			"surnoms": [[0, "mon petit"], [25, "jeune homme-jeune fille"], [50, "mon camarade"], [75, "mon braiseur"], [95, "ma relève"]],
			"repliques": {
				"accueil": [
					L("Approche, mon petit, approche. Assieds-toi sur le canapé bleu, il est moins défoncé que le vert. Brasero. J'ai fondé cette caverne il y a cinquante ans, avec trois amis, une brouette et un feu. Le feu est toujours là. Les amis aussi, en peinture, sur le Mur. Et moi, comme tu vois. Avec ma crête.", {"visites_max": 1}, "salut"),
					L("{surnom}. Assieds-toi. Le feu a envie de discuter. Moi aussi. Qu'est-ce qui t'amène, ce soir ? Ne réponds pas trop vite. Ici, on prend le temps de penser avant de parler. Sauf Rivet. Rivet, on a voté une exception.", {"visites_min": 2}, "rire"),
					L("Ma relève ! Tiens, prends la clé de parole. Non, je ne plaisante pas. Tiens-la une minute. … Alors ? C'est lourd, hein ? C'est fait pour. Ce que l'on dit, il faut le porter.", {"visites_min": 6}),
				],
				"humeur": [
					L("Bof. L'Assemblée a duré cinq heures hier soir. On devait choisir la couleur de la nouvelle passerelle. On a fini par parler du sens de la vie. On n'a pas choisi la couleur. Mais le sens de la vie, on a presque trouvé.", {"humeur_max": -0.2}, "rire"),
					L("Content, mon petit. Très content. La Ligne a rouvert. Pendant des années, on a été « ceux d'en bas ». Maintenant, des gens d'en haut viennent s'asseoir sur nos canapés et donnent leur avis. C'est exactement pour ça que j'ai allumé ce feu.", {}),
					L("Pensif. Le feu craque fort, ce soir. Il a quelque chose à dire. Quand il craque comme ça, c'est qu'un vote va être difficile. Ou qu'il y a une bûche humide. Les deux arrivent souvent ensemble.", {}, "rire"),
					L("Le matin, je suis seul à l'Assemblée. Je remets du bois, je balaie les cendres, j'arrange les coussins. Je dis bonjour à chaque canapé. Ils sont tous venus d'une maison différente des Strates. Chacun a une histoire. Le jaune a connu trois mariages. Le vert, un éléphant. Je n'ai jamais su comment.", {"matin": true}),
					L("Le soir, quand les Soupapes jouent, je reste au brasero. J'entends le concert de loin, à travers les flammes. Ça fait comme un vieux disque. Parfois, je vais dans la fosse, tout au bord. Ma crête bat la mesure. Elle tient toute seule, tu sais. À quatre-vingts ans.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'étais mineur, aux Mines de Cristaux, comme mon père. Quand la grande veine de l'est s'est épuisée, la Guilde a fermé cette caverne et l'a remplie de vieilles chaudières, de rails tordus, de conteneurs vides. Une décharge. Moi, j'y voyais des maisons. J'avais trente ans. On voit beaucoup de maisons, à trente ans.", {}),
					L("La première nuit, on était quatre. Il faisait froid, il faisait noir. J'ai renversé une brouette, j'y ai mis du charbon, et j'ai allumé un feu. On s'est assis autour. Et on a parlé jusqu'au matin de ce qu'on voulait construire. C'était la première Assemblée. Ce feu-là, je ne l'ai jamais laissé s'éteindre.", {"sujet_min": ["lui", 1]}),
					L("Pourquoi « la Fronde » ? Parce que les vieux des Strates disaient qu'on « frondait » : qu'on ne voulait pas se taire après vingt heures, qu'on peignait sur la roche, qu'on décidait tout ensemble. On a pris le mot. On l'a peint sur le pont. On l'a gardé. Un reproche qu'on porte avec fierté devient un nom.", {"sujet_min": ["lui", 2]}),
					L("Mon fils, Rivet, tape sur une batterie. Ma petite-fille, Ysaé, vend des bijoux à Hautefond. Quand j'ai allumé ce feu, je ne savais pas qu'il réchaufferait jusqu'en haut de la Colonne. Le feu va plus loin qu'on ne croit, mon petit. C'est pour ça qu'il faut toujours le garder gentil.", {"sujet_min": ["lui", 3]}),
				],
				"ile": [
					L("L'Assemblée, c'est simple. Un cercle de canapés, un brasero au milieu, une clé à molette. Celui qui tient la clé parle. Les autres écoutent. Quand tout le monde a parlé, on vote à main levée. Même les enfants. Surtout les enfants : ils votent pour des choses qu'on avait oubliées.", {}),
					L("Les gens des Strates, à côté, sont nos cousins. Ils ont la Guilde, la Grande Horloge, le Soleil de Laiton, des règlements pour tout. Nous, on a l'Assemblée et un brasero. Ils disent qu'on est désordonnés. On dit qu'ils sont trop rangés. Le soir, ils viennent au concert. Le dimanche, on va à leur marché. Tout va bien.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Soleil de Laiton, c'est la grande lampe de la caverne des Strates. Une merveille. Il s'allume le matin, il baisse le soir, comme un vrai soleil. Nous, ici, on n'a pas de soleil. On a ce feu. Il est plus petit. Mais on peut s'asseoir autour.", {"sujet_min": ["ile", 2]}),
					L("La Colonne relie quatre mondes, mon petit : les Nuées, Hautefond, les Strates, et le Dôme d'Azur, au fond de la mer, dont la ligne vient enfin de rouvrir. Quatre mondes, et pas une seule Assemblée commune. Un jour, il faudra s'asseoir tous ensemble autour d'un même feu. J'aimerais voir ça avant d'éteindre le mien.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Ma petite-fille, Ysaé ! Tu l'as vue ? Elle a les cheveux bleus, comme les cristaux. Elle les a choisis à quinze ans, ici, devant ce feu. Moi, j'ai choisi l'orange il y a soixante-cinq ans. Pour aller avec le feu. Elle m'a dit : « Grand-père, ta crête tient toute seule. » Évidemment. Elle a de l'entraînement.", {"a_rencontre": "ysae"}, "rire"),
					L("Le Bourgmestre de Hautefond est descendu pour la réouverture. Il a fait un discours de deux heures, debout devant le brasero. On l'a écouté jusqu'au bout. Puis on lui a tendu la clé de parole pour qu'il continue. Il a été si surpris qu'il s'est tu. Il est reparti tout ému.", {"a_rencontre": "hector_hf"}, "rire"),
					L("Mathilde, la forgeronne d'en haut… Son grand-père est descendu apprendre à forger ici, dans la première forge de la Fronde, quand j'étais tout jeune. Un grand gaillard roux qui tapait fort et riait plus fort encore. Elle rit pareil : le jour de la réouverture, son rire est descendu par la Colonne jusqu'ici. J'ai cru qu'il était revenu. Quand elle descendra, je lui donnerai la clé de parole.", {"a_rencontre": "mathilde"}),
					L("Agathe, la Doyenne de la Guilde des Strates, et moi, nous ne sommes d'accord sur rien depuis cinquante ans. Les horaires, les règlements, le bruit. Et pourtant, une fois par mois, je monte prendre le thé à la Guilde. J'apporte les biscuits, elle fournit le thé. Elle dit que c'est notre traité de paix. Moi, je dis que c'est pour ses biscuits… enfin, pour son thé. Elle portait nos planches, en cachette, quand on a construit le Pont. Je ne l'ai jamais oublié.", {}, "rire"),
					L("La Présidente d'en bas, Ondine… Je lui ai écrit : « Quatre mondes, et pas une seule assemblée commune. » Elle m'a répondu : « Venez. Nous nous assiérons autour de la Fontaine des Bulles. » Une fontaine ! Moi, je voulais un feu. Sous la mer, paraît-il, c'est compliqué. Nous négocions. (Il sourit.) Ça fait du bien, de négocier avec quelqu'un qui écoute.", {"a_rencontre": "ondine_da"}),
				],
				"interpelle": [L("Toi, là, avec tes yeux tout ronds ! Viens t'asseoir près du feu.", {"visites_max": 0}, "salut"), L("{surnom} ! Le feu t'a gardé une place.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Va, mon petit. Et souviens-toi : ce qui se décide ensemble tient mieux que ce qui se décide seul. Même un pont.", {}, "salut"), L("À bientôt. Si tu as une idée en route, garde-la au chaud. Tu me la diras ici. Le feu aime les idées.", {}), L("Bonne nuit, mon petit. Je vais couvrir les braises. Elles ne s'éteignent jamais. Elles dorment, c'est tout. Comme les bonnes idées.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Mon petit, j'ai quatre-vingts ans, et je me souviens de tous ceux qui se sont assis autour de ce feu. Toi, tu as écouté avant de parler. C'est rare. C'est précieux.", {})],
			}},
	]

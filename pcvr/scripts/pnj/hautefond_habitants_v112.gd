extends RefCounted
## V112 : les gens de Hautefond, la cité-colonne, sur sa butte en terrasses au milieu de son île
## ronde, au sud-ouest de l'archipel. Une ville « fantastique-vapeur » : pierre blonde, ardoise bleue,
## laiton, engrenages, horloges, tuyaux qui soufflent, et au centre la Grande Colonne, la tour de
## laiton et de verre où montent les cabines des Liftiers.
##  - la Place de la Colonne : Maîtresse Capucine Rouage (la Grande Liftière) et Barnabé, son apprenti
##    (qui a le vertige), et Pimprenelle (9 ans, collectionneuse de boulons, future liftière) ;
##  - la Haute-Ville : le Professeur Octave Lunette (l'Observatoire), Mademoiselle Philippine Feuillet
##    (la Bibliothèque des Cartes) et le Bourgmestre Hector Bellevue (l'Hôtel de Ville) ;
##  - la Ville-Moyenne : Rosalie Cannelle (épices et fruits du Grand Marché), Gaspard Ressort
##    (l'horloger), Firmin Bouilloire (la taverne « Le Piston Joyeux », sans une goutte d'alcool), la
##    Capitaine Héloïse Nimbus (le dirigeable « l'Albatros », au Mât) et Ysaé (bijoux de boulons et de
##    cristal, « qui vient d'en bas », de la Fronde) ;
##  - la Basse-Ville : Mathilde Soufflet, la forgeronne de la Forge à vapeur (la mère de Pimprenelle) ;
##  - dehors : Léon Calfat (le Port des Cordages), Margot (le Phare de la Pointe), Augustin Meule (le
##    Moulin des Quatre Vents) et Père Bastien Greffe (les Vergers en terrasses).
## Pas encore de quête à Hautefond : les lignes de la Colonne vers la Cité des Nuées (en haut, V113) et
## vers les Strates et la Fronde (en bas, V114 : le pavillon de la Place de la Colonne) ont rouvert ;
## celle du Dôme d'Azur (au fond de la mer) « rouvre bientôt ».
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd), même costume que Montjoie (fiche « mj », pnj_montjoie_v71.gd).
## Fiche « village » : hautefond. Fiche « mj » : tenue (aventurier | pretresse | mage | chevalier |
## archere | barde | noble | marchand | artisan | forgeron | garde | paysan | enfant | cuisinier | marin |
## savant), objet (epee | masse | baton | arc | luth | marteau | louche | plateau | cloche | lanterne |
## livre | canne | panier | filet | canne_peche | tampon, facultatif), chapeau (mage | plume | chaperon |
## bonnet | toque | casque, facultatif). Les Liftiers portent la casquette à galon (fiche « azur »).
## Identifiants : ces prénoms existent déjà ailleurs dans l'archipel (Port-Azur, Cliquetis, les fées,
## les teufeurs…), alors on suffixe « _hf » : capucine_hf, barnabe_hf, octave_hf, hector_hf, rosalie_hf,
## gaspard_hf, heloise_hf, leon_hf, margot_hf, augustin_hf, pimprenelle_hf, bastien_hf ; leur porte reste
## « porte_<prénom> » (porte_capucine, porte_leon…). philippine, firmin, mathilde, ysae restent tels quels.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bonne route, {surnom} ! Et huile tes rouages : à Hautefond, tout grince, sauf les gens.", "si": {}, "geste": "salut"},
		{"t": "À plus tard ! Si tu entends siffler, ce n'est pas un train : c'est le chocolat de Firmin qui est prêt.", "si": {}, "geste": "rire"},
		{"t": "Va ! Et lève le nez de temps en temps : ici, tout se passe au-dessus de ta tête.", "si": {}},
		{"t": "Bonne nuit ! Écoute bien : la nuit, la Colonne ronronne. Maîtresse Capucine dit qu'elle rêve.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Je ne suis pas un piston, moi ! On ne tape pas sur les gens, on tape sur les enclumes !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu veux que j'appelle le Bourgmestre ? Il te ferait un discours de deux heures. Personne ne mérite ça.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? C'est gentil. Je vais le poser sur la cheminée, entre la pendule et la pendule.", "si": {}},
		{"t": "Merci, {surnom}. À Hautefond, on dit qu'un cadeau, ça fait monter le cœur d'un étage.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par la Colonne, tu as visé juste, {surnom} !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau tout en haut de l'échelle ! Merci, {surnom}. Toute la Place va le savoir.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… Je vais le donner à Pimprenelle. Elle collectionne tout ce qui ressemble à un boulon.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, le plus dangereux, c'est la file d'attente du guichet. Et elle ne craint pas les épées.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! À Hautefond, tout le monde se croise dans la cabine. On finit par connaître les têtes. Et les chapeaux.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Ici, on ne te demande qu'une chose : tenir la rampe dans la cabine.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi la Colonne ne raconte jamais de blagues ? Parce qu'elle a peur que ça tombe à plat. De soixante mètres.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un engrenage dit à un autre engrenage ? « On tourne ensemble ? » Et l'autre répond : « Dans quel sens ? » C'est le début d'une longue dispute.", "si": {}, "geste": "rire"},
		{"t": "Un voyageur entre dans la cabine : « Ça monte ? » Barnabé, tout pâle : « Pour vous, oui. Pour mon estomac, ça descend. »", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on une horloge qui chante faux ? Une pendule qui a perdu le la. … Gaspard ne rit jamais à celle-là. Il dit que la sienne chante juste.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand j'aurai relâché la vapeur.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Ça monte !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même la cabine ne monte pas sans contrepoids.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Dans les cages de la Colonne, on monte léger.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}. Même l'Albatros refuserait de le soulever.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et un coup de chapeau en prime !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu as une bonne tête de voyageur. Un petit geste. Ne le dis pas à Rosalie, elle le répéterait au marché entier.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont réglés comme une horloge de Gaspard. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. Ma mémoire a plus de rouages que tu ne crois.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par la Colonne !", "Ça monte !", "Ha ha !", "Quelle merveille !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Misère…", "Pfff…", "Tout le monde descend…"],
		"colere": ["Par tous les pistons !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Huile tes rouages.", "Par la Colonne !", "Ça monte !", "Comme disait Dame Ysolde."],
	"humeur_mots": [[0.6, "gonflé à bloc"], [0.25, "de bonne humeur"], [-0.25, "un peu grippé"], [-0.6, "grinçant"], [-2.0, "en surpression"]],
	"surnoms": [[0, "voyageur"], [25, "ami des hauteurs"], [50, "mon camarade"], [75, "cœur de laiton"], [95, "enfant de la Colonne"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.68, 0.32]
const BLOND_PALE := [0.92, 0.84, 0.6]
const ROUX := [0.82, 0.3, 0.1]
const CUIVRE := [0.72, 0.38, 0.18]
const ARGENT := [0.82, 0.82, 0.86]
const BLEU_VIF := [0.18, 0.45, 0.92]
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
## Le bleu nuit des Liftiers (la casquette à galon doré).
const LIFTIER := [0.12, 0.17, 0.36]


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
	out["groupe"] = "hautefond"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Place de la Colonne
		{"id": "capucine_hf", "nom": "Maîtresse Capucine Rouage", "titre": "Grande Liftière, cheffe de la Confrérie des Liftiers", "maison": "porte_capucine", "village": "hautefond", "vouvoie": true,
			"agenda": [[6, 7, "place_fontaine"], [7, 19, "colonne_guichet"], [19, 22, "place_banc_1"], [22, 6, "maison"]],
			"azur": {"cheveux": CUIVRE, "coiffure": "chignon", "yeux": Y_AMBRE, "chapeau": "casquette", "chapeau_c": LIFTIER, "haut": LIFTIER, "robe": [0.2, 0.22, 0.3], "robe_longue": true, "lunettes": true, "taille": 1.02},
			"teinte": PEAU[1],
			"mj": {"tenue": "garde", "objet": "lanterne"},
			"humeur_base": 0.4, "traits": {"bavard": 0.7, "humour": 0.4, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"engrenage": 2.0, "chocolat_chaud": 1.5, "biscuit_engrenage": 2.0, "montre_envers": 1.5, "cafe_vapeur": 1.5}, "deteste": {"vieille_botte": -1.5, "gelee_slime": -1.5},
			"tics": ["Dans l'ordre, s'il vous plaît.", "Elle n'aime pas qu'on la presse.", "Ça monte !", "Tenez la rampe."],
			"surnoms": [[0, "cher passager"], [25, "passager régulier"], [50, "passager d'honneur"], [75, "liftier de cœur"], [95, "ami de la Colonne"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au pied de la Grande Colonne ! Maîtresse Capucine Rouage, Grande Liftière de la Confrérie. Billets, horaires, réclamations, objets oubliés dans la cabine : tout passe par ce guichet. Aujourd'hui, la Colonne monte jusqu'au Belvédère, et la capsule vous emmène jusqu'aux Nuées. Elle a rouvert. Elle en est fière.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous revoilà. La Colonne vous salue. Si, si : vous n'avez pas entendu ce petit « ding » ? C'est elle. Elle vous reconnaît.", {"visites_min": 2}),
					L("Ah, {surnom}. Vous tombez bien : la cabine vient de redescendre, Barnabé est encore vert, et j'ai trois minutes. Trois. Je les ai comptées.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Excellente ! Quatre cents montées depuis ce matin, zéro retard, zéro cri. Enfin, un cri. C'était Barnabé. Ça ne compte pas, il crie à chaque fois.", {}, "rire"),
					L("Un peu inquiète. Les lignes des Nuées et des Strates ont rouvert, et la Colonne n'a plus l'habitude d'avoir autant de monde. Elle grince la nuit. Je lui parle. Elle se calme.", {}),
					L("Le soir, je m'assois sur le banc de la Place et je la regarde, toute dorée sous les réverbères. Deux cents ans, et pas une ride. Enfin, quelques rivets.", {"soir": true}),
				],
				"lui": [
					L("Mon arrière-arrière-grand-mère a tiré la corde du panier à salade avec Dame Ysolde Hautefond. Depuis, il y a toujours eu une Rouage au guichet. On a la Colonne dans le sang. Et un peu d'huile sous les ongles.", {}),
					L("Mes lunettes de cuivre ? Je ne les mets jamais sur mes yeux. Elles sont sur mon front pour que la Colonne voie que je suis prête. C'est un code entre nous. Barnabé n'a pas encore compris le code.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais vous dire un secret, {surnom}. Quand j'étais petite, j'avais peur dans la cabine. Comme Barnabé. Ma mère me disait : « Regarde les gens, pas le vide. » Je le dis à Barnabé tous les jours. Un jour, ça marchera.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Grande Colonne relie quatre mondes, {surnom}. En haut, la Cité des Nuées, au-dessus des nuages. Ici, Hautefond. En dessous, les Strates, creusées dans la roche. Et tout au fond de la mer, sous son grand dôme de verre, le Dôme d'Azur. Une seule tour. Quatre mondes. Pas mal pour un panier à salade.", {}),
					L("La ligne des Nuées a rouvert. Câbles neufs, poulies graissées, capsule cirée. J'ai fait la première montée, avec Barnabé aux commandes. Là-haut, j'ai posé la main sur la capsule et j'ai dit : « Elle est bien élevée. » Elle l'est.", {"sujet_min": ["ile", 1]}),
					L("La ligne du bas, celle des Strates, a rouvert. Officiellement, pour les forges et les cristaux. Vous entendez cette musique qui monte du pavillon ? Moi non plus. Je n'entends rien. Je suis la Grande Liftière. Je n'entends que ce qui est réglementaire.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Le jour de la réouverture des Strates, j'ai tiré moi-même le levier du pavillon. La cabine est descendue sans un grincement. En bas, la Doyenne Agathe m'attendait. Nous nous sommes dit deux phrases. C'était parfait. Le Bourgmestre en a dit quatre cents.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Le Bourgmestre voulait couper un ruban de trente mètres autour de la Colonne, pour la réouverture des Nuées. J'ai dit non. Nous en avons coupé un de trente centimètres, à deux. Il a fait un discours quand même. Elle a grincé pendant tout le discours.", {}, "rire"),
					L("La petite Pimprenelle m'apporte un boulon chaque matin, « pour la Colonne ». J'en ai une boîte pleine. Je ne lui dirai jamais qu'ils ne vont nulle part. Enfin… j'en ai vissé un. Un seul. Il tient très bien.", {}),
					L("Cette Ysaé, du marché… Elle s'arrête devant la cage du bas et elle écoute la musique en battant du pied. Je fais semblant de ne pas voir. Elle fait semblant de ne pas savoir que je vois. On s'entend très bien, comme ça.", {}),
					L("Vous avez vu Anatole, à la Gare des Strates ? Il vous a parlé de la poulie douze, je parie. (Elle remet ses lunettes.) Elle est très bien graissée, la poulie douze. Je le sais. Je l'entends d'ici. Je n'entends que ce qui est réglementaire, et ça, c'est réglementaire.", {"a_rencontre": "anatole"}),
				],
				"interpelle": [L("Vous ! Oui, vous ! Vous avez une tête de passager !", {"visites_max": 0}, "salut"), L("{surnom} ! La cabine part dans deux minutes !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bonne journée, {surnom}. Et tenez la rampe, même sur la terre ferme : c'est une bonne habitude.", {}, "salut"), L("À bientôt ! La Colonne vous attend. Elle attend tout le monde. Elle est très patiente. Moi, moins.", {}, "rire"), L("Bonsoir, {surnom}. Dernière montée à vingt-deux heures. Ensuite, elle dort. Ne la réveillez pas.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Je me souviens de chaque passager, {surnom}. Et de l'étage où il est descendu. Et de ce qu'il a oublié dans la cabine. Vous, rien. C'est bien.", {})],
			}},
		{"id": "barnabe_hf", "nom": "Barnabé", "titre": "apprenti liftier (qui a le vertige)", "maison": "porte_barnabe", "village": "hautefond",
			"agenda": [[7, 12, "colonne_cabine"], [12, 13, "taverne_table_3"], [13, 18, "colonne_cabine"], [18, 20, "belvedere_1"], [20, 7, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "boucles", "yeux": Y_BLEU, "chapeau": "casquette", "chapeau_c": LIFTIER, "haut": LIFTIER, "taille": 0.98, "carrure": 0.9},
			"teinte": PEAU[0],
			"mj": {"tenue": "garde"},
			"humeur_base": 0.55, "traits": {"bavard": 0.85, "humour": 0.7, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"chocolat_chaud": 2.5, "biscuit_engrenage": 2.0, "plume_vent": 1.5, "parapluie_helice": 1.5, "pain_miel": 1.5}, "deteste": {"chapeau_ventilateur": -1.0, "sardine": -1.0},
			"tics": ["Ça monte ! … Hélas.", "Je ne regarde pas en bas.", "Ouh là.", "Tout va bien. Tout va très bien."],
			"surnoms": [[0, "passager"], [25, "copain de cabine"], [50, "mon pote"], [75, "mon parachute"], [95, "mon héros des hauteurs"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Bienvenue dans la cabine ! Je suis Barnabé, apprenti liftier. Accrochez-vous à la rampe. Moi aussi, je m'accroche. Très fort. Ce n'est pas de la peur, c'est… du professionnalisme.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu remontes avec moi ? Super ! Enfin, super pour toi. Moi, je vais fermer les yeux à partir du deuxième étage. Ne t'inquiète pas, je connais les boutons par cœur.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Génial ! Aujourd'hui, j'ai regardé par la vitre jusqu'au troisième étage. Le troisième ! Après, j'ai vu un pigeon, et j'ai dû m'asseoir.", {}, "rire"),
					L("Bien, bien. J'ai un peu la tête qui tourne, mais c'est normal : la cabine aussi, elle tourne. Non ? Elle ne tourne pas ? … Ah. Alors c'est moi.", {}),
					L("Le soir, je monte au Belvédère tout seul, pour m'entraîner. Je reste cinq minutes près de la rambarde. Hier, six. Théo m'attend sur son Belvédère de verre, aux Nuées. Je lui ai dit « un jour ». Il a apporté une chaise.", {"soir": true}),
				],
				"lui": [
					L("Je veux être liftier depuis que j'ai cinq ans. J'ai découvert que j'avais le vertige à six ans, dans la cabine. J'ai décidé que ce n'était pas une raison. Mes genoux, eux, ne sont toujours pas d'accord.", {}),
					L("Maîtresse Capucine m'a pris comme apprenti parce que j'étais le seul candidat qui connaissait le nom de toutes les poulies. Il y en a quarante-deux. J'ai donné un prénom à chacune. Elle a trouvé ça « inquiétant, mais utile ».", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu sais pourquoi je n'abandonne pas ? Parce que quand la cabine arrive au Belvédère et que les portes s'ouvrent, les gens font tous « oooh ». Tous. Et pendant une seconde, j'oublie que j'ai peur. Je fais « oooh » avec eux.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Belvédère, c'est un balcon tout rond, à soixante mètres. De là, on voit toute l'île : le Moulin, les Vergers, le Phare, les Arches dans la mer… et au-dessus, la Cité des Nuées qui flotte. Paraît-il. Moi, je regarde mes chaussures. Elles sont très belles.", {}, "rire"),
					L("La ligne des Nuées a rouvert, et c'est moi qui ai fait la première montée ! Là-haut, Théo, mon correspondant, m'attendait sur le quai. Je suis sorti tout vert. Mais très fier. Les deux en même temps, c'est possible, je te le confirme.", {"sujet_min": ["ile", 1]}),
					L("Mon oncle travaille au Dôme d'Azur, tout au fond de la mer. Il m'écrit que là-bas, on voit passer des baleines par le plafond. Descendre au fond de la mer ? Ça, je pourrais. C'est monter, mon problème.", {"sujet_min": ["ile", 2]}),
					L("Pour la réouverture des Strates, je suis descendu avec Maîtresse Capucine. Descendre, c'est mieux : on ne voit pas le vide. En bas, une cantinière m'a servi un chocolat si épais que la cuillère tenait debout. J'ai repris des couleurs. Trois, d'après elle.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("La Capitaine Héloïse m'a proposé un tour en dirigeable. Moi ! Dans l'Albatros ! J'ai dit oui. Puis j'ai dit « peut-être ». Puis je suis allé m'asseoir. Elle m'a dit que l'offre tenait toujours. Elle est vraiment chic.", {}),
					L("Pimprenelle me corrige tout le temps. « On ne dit pas monter vite, on dit monter en régime. » Elle a neuf ans. Elle connaît le règlement mieux que moi. Je crois qu'elle va me piquer ma casquette.", {}, "rire"),
					L("Gaspard l'horloger m'a offert une montre, pour que je ne sois plus jamais en retard. Elle sonne cinq minutes avant chaque montée. Et une minute avant. Et pile à l'heure. Je suis toujours en retard, mais maintenant, je le sais.", {}, "rire"),
				],
				"interpelle": [L("Bonjour ! Vous montez ? … S'il vous plaît, dites oui, je déteste monter tout seul !", {"visites_max": 0}, "salut"), L("{surnom} ! Ça monte ! … Malheureusement.", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Salut, {surnom} ! Moi, je reste ici. Au rez-de-chaussée. Pour l'instant.", {}, "salut"), L("À plus ! Et si tu vois Maîtresse Capucine, dis-lui que j'ai regardé en bas aujourd'hui. Une fois. Un peu.", {}, "rire"), L("Bonne nuit ! Moi, je vais dormir au rez-de-chaussée. J'ai choisi mon appartement exprès.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu es la personne qui m'a tenu compagnie pendant que je fermais les yeux. C'est comme ça que je reconnais mes vrais amis.", {})],
			}},
		{"id": "pimprenelle_hf", "nom": "Pimprenelle", "titre": "collectionneuse de boulons, future liftière", "maison": "porte_pimprenelle", "village": "hautefond",
			"agenda": [[8, 12, "place_fontaine"], [12, 13, "forge_comptoir"], [13, 17, "marche_fontaine"], [17, 19, "place_fontaine"], [19, 20, "forge_comptoir"], [20, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "tresse", "yeux": Y_VERT, "haut": [0.85, 0.55, 0.2], "tablier": [0.4, 0.28, 0.16], "enfant": true, "taille": 0.7},
			"teinte": PEAU[0],
			"mj": {"tenue": "enfant", "objet": "panier"},
			"humeur_base": 0.7, "traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 0.95, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"boulon": 3.0, "engrenage": 2.5, "ressort": 2.0, "canard_mecanique": 2.5, "biscuit_engrenage": 1.5, "eclat_cristal": 1.5}, "deteste": {"champignon": -1.0, "vieille_botte": -0.5},
			"tics": ["C'est dans le règlement !", "Je le note dans ma tête.", "Ça monte !", "Boulon !"],
			"surnoms": [[0, "monsieur-madame"], [25, "passager"], [50, "mon équipier"], [75, "mon meilleur collègue"], [95, "mon liftier préféré"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Tu as un boulon ? Non ? Ce n'est pas grave. Moi, c'est Pimprenelle. J'ai neuf ans, j'ai trois cent douze boulons, et quand je serai grande, je serai Grande Liftière. C'est déjà décidé. Il faut juste prévenir Maîtresse Capucine.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Regarde ! Un boulon à six pans ! Je l'ai trouvé sous un banc. C'est le plus beau de la semaine. Tu peux le toucher. Avec un doigt. Doucement.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super bien ! J'ai trouvé quatre boulons, un écrou et un truc. Je ne sais pas ce que c'est, le truc. Je l'ai appelé Gérard.", {}, "rire"),
					L("Un peu fâchée. Maman dit que je n'ai pas le droit de démonter le banc pour récupérer ses boulons. Pourtant, il tiendrait sûrement debout tout seul. Sûrement.", {}),
					L("Le soir, je rentre à la forge et je range mes boulons par taille. Puis par couleur. Puis par ceux que je préfère. Maman dit que c'est pour ça que je me couche tard.", {"soir": true}),
				],
				"lui": [
					L("Ma maman, c'est Mathilde, la forgeronne. Elle tape tellement fort que tout le quartier fait des petits bonds. Moi, je ramasse ce qui tombe de l'établi. C'est comme ça que j'ai commencé ma collection.", {}),
					L("Je connais le règlement des Liftiers par cœur. Article un : on tient la rampe. Article deux : on ne crie pas « tout le monde descend » pour rire. Article trois : on ne nourrit pas les pigeons dans la cabine. L'article trois, c'est à cause de moi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon boulon préféré, je ne le montre à personne. Il vient de Dame Ysolde. Enfin, je crois. Je l'ai trouvé au fond de la fontaine, sous sa statue. Il est tout vert et tout vieux. Je lui dis bonne nuit.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Tu as vu la statue de Dame Ysolde, dans la fontaine ? Elle lève une lanterne. Elle a construit la première cabine avec une corde, une poulie et un panier à salade ! Moi aussi, j'ai essayé. Avec le chat. Il n'a pas aimé.", {}, "rire"),
					L("Tout en haut de la Colonne, il y a la Cité des Nuées. La ligne a rouvert, et j'y suis montée avec Maman ! Les maisons sont en verre, c'est vrai. Mais les boulons, non. J'ai vérifié. Tous.", {"sujet_min": ["ile", 1]}),
					L("En dessous de la ville, il y a les Strates, et la Fronde. C'est là qu'habite Ysaé ! Elle dit qu'il y a des forges, des rails, des cristaux qui brillent dans le noir, et de la musique tout le temps. La ligne a rouvert, et Maman a dit « on verra ». Ça voulait dire oui ! J'y suis allée avec Ysaé. C'est encore mieux.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Barnabé a le vertige. C'est un secret. Enfin, tout le monde le sait. Mais c'est quand même un secret. Moi, je n'ai jamais le vertige. Je pourrais le remplacer. Je dis ça pour l'aider.", {}, "rire"),
					L("Ysaé m'a fait un collier avec un boulon et un petit cristal bleu. Le Bourgmestre l'a regardé avec des gros sourcils. Puis il m'a demandé où elle vendait les mêmes. Je crois qu'il en veut un.", {}, "rire"),
					L("Monsieur Gaspard l'horloger me donne les rouages trop petits. Il dit qu'ils sont « hors tolérance ». Moi, je les tolère très bien.", {}),
					L("Ce matin, j'ai tapé deux coups, puis un, sur le tuyau de la cuisine. Sous mes pieds, quelqu'un a répondu : trois coups vite. Ça veut dire « boulon trouvé ». Je sais qui c'est. Je ne le dirai pas. (Elle devient toute rouge.)", {}),
					L("Tu as vu Tom, à la Grande Forge ? Celui qui tape trois coups vite ? … Moi, je ne l'ai pas encore vu en vrai. Le jour où je suis descendue, il m'attendait au quai, et moi, j'étais au Troc. On s'est ratés de cent mètres. Après deux ans à se parler à travers la roche !", {"a_rencontre": "tom_st"}, "rire"),
				],
				"interpelle": [L("Hé ! Tu as un boulon ?", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir ma nouvelle trouvaille !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir ! Si tu trouves un boulon, tu sais où j'habite. Partout.", {}, "salut"), L("Salut ! Tiens bien la rampe ! C'est l'article un !", {}, "rire"), L("Bonne nuit ! Je vais dire bonne nuit à mes boulons. Ça prend un moment.", {"soir": true}, "rire")],
				"souvenir": [L("Bien sûr que je me souviens de toi ! Tu es dans ma liste des gens gentils. Juste entre Barnabé et un boulon doré.", {})],
			}},
		# ================================================================ la Haute-Ville
		{"id": "octave_hf", "nom": "Professeur Octave Lunette", "titre": "astronome de l'Observatoire", "maison": "porte_octave", "village": "hautefond", "vouvoie": true,
			"agenda": [[19, 5, "observatoire_lunette"], [5, 13, "maison"], [13, 19, "observatoire_bureau"]],
			"azur": {"cheveux": BLANC, "coiffure": "boucles", "barbe": "courte", "yeux": Y_GRIS, "haut": [0.22, 0.2, 0.38], "robe": [0.18, 0.16, 0.3], "robe_longue": true, "lunettes": true, "vieux": true, "taille": 1.05, "carrure": 0.85},
			"teinte": PEAU[1],
			"mj": {"tenue": "savant", "objet": "livre"},
			"humeur_base": 0.45, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"fragment_meteorite": 3.0, "cristal_astral": 2.5, "the_stellaire": 2.0, "eclat_lune": 2.0, "biscuit_lunaire": 1.5, "chocolat_chaud": 1.5}, "deteste": {"lunettes_kaleido": -1.0, "cafe_vapeur": -0.5},
			"tics": ["Fascinant.", "Où en étais-je ?", "Trois mille quatre cent… zut.", "Elle m'a fait un clin d'œil !"],
			"surnoms": [[0, "cher visiteur"], [25, "cher observateur"], [50, "cher confrère"], [75, "mon étoile du berger"], [95, "constellation de mon cœur"]],
			"repliques": {
				"accueil": [
					L("Oh ! Un visiteur ! Professeur Octave Lunette, astronome. Pardon, je compte… trois mille quatre cent douze, trois mille quatre cent… Zut. Je recommencerai. J'ai l'habitude, je recommence tous les soirs depuis trente ans.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous tombez à pic. Enfin, à pic… Je ne sais plus quelle heure il est. Le jour ? Ah. Les étoiles sont toujours là, vous savez. Elles se cachent derrière la lumière, c'est tout.", {"visites_min": 2}),
				],
				"humeur": [
					L("Excellente ! Cette nuit, l'étoile m'a fait deux clins d'œil. Deux ! Elle ne m'en avait jamais fait deux. Nous progressons.", {}, "rire"),
					L("Un peu fatigué. Le matin, je dors. L'après-midi, je calcule. La nuit, je regarde. Il ne reste pas beaucoup de place pour le reste. Le reste, c'est surtout manger. J'oublie.", {}),
					L("La nuit tombe : c'est mon matin à moi. Bonjour, la nuit ! Bonjour, les étoiles ! Bonjour, vous. Vous êtes une étoile, d'ailleurs ? Non ? Dommage.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis devenu astronome à sept ans, le jour où j'ai voulu compter les étoiles avant de dormir. Je ne me suis jamais endormi. Ma mère a acheté des rideaux. J'ai acheté une lunette.", {}),
					L("Il y a une étoile, au-dessus du Phare, qui me fait des clins d'œil. Je l'ai baptisée Clémentine. Mes confrères disent que c'est la lumière du Phare. Ou la lanterne de l'Albatros. Ou mes lunettes sales. Ce sont des jaloux.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Vous savez ce que je préfère, dans l'astronomie ? Ce n'est pas de compter. C'est qu'à chaque fois que je lève la tête, il y a quelque chose de nouveau. Une vie entière à regarder le même ciel, et pas une nuit pareille. C'est un cadeau.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Observatoire est tout en haut de la Haute-Ville, sous sa coupole. La grande lunette pèse trois tonnes et tourne avec un seul doigt. Gaspard l'a réglée. Il a dit « c'est parfait ». Je ne l'avais jamais entendu dire ça.", {}),
					L("La Cité des Nuées flotte au-dessus des nuages, juste à côté des étoiles. La ligne a rouvert, et j'y suis monté avec ma lunette. Elle a pris deux places. Hélas, un certain Docteur Aurèle a mis des nuages partout. Avec des prénoms !", {"sujet_min": ["ile", 1]}),
					L("Au Dôme d'Azur, au fond de la mer, ils ont leurs propres étoiles : des poissons qui s'allument dans le noir. J'ai écrit à leur astronome. Il m'a répondu qu'il était « océanographe ». J'ai trouvé ça très beau, comme mot.", {"sujet_min": ["ile", 2]}),
					L("La ligne des Strates a rouvert, et l'on m'a parlé d'une grotte où les cristaux brillent comme un ciel étoilé. Sous terre ! J'ai écrit au contremaître des Mines. Il accepte de me la montrer, lampes éteintes. Mais avec un casque. Il a souligné « casque » trois fois.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Mademoiselle Philippine me prête les cartes du ciel de la Bibliothèque. Je les lui rends en retard. Toujours. Elle me gronde en chuchotant. C'est le plus doux des savons. Je les rends un peu plus en retard pour l'entendre.", {}, "rire"),
					L("Margot, au Phare, prétend que mon étoile, c'est sa lumière qui tourne. Un soir, je lui ai demandé d'éteindre le Phare une minute. Elle l'a fait. Et Clémentine a quand même cligné. Ha ! Margot a dit « ça, c'est une mouette ».", {}, "rire"),
					L("Le Bourgmestre veut donner mon nom à une étoile. Je lui ai expliqué que les étoiles avaient déjà des noms. Il a dit qu'il en trouverait une « libre ». Il cherche depuis deux mois, avec ma lunette. Il ne sait pas dans quel sens on regarde.", {}, "rire"),
				],
				"interpelle": [L("Psst ! Vous ! Regardez là-haut ! … Ah, il fait jour. Pardon.", {"visites_max": 0}), L("{surnom} ! Clémentine m'a encore fait un clin d'œil !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Levez la tête de temps en temps : le ciel aime qu'on le regarde.", {}, "salut"), L("À bientôt ! Si vous voyez une étoile cligner, notez l'heure. Pour la science. Et pour moi.", {}), L("Bonne nuit, {surnom}. Moi, je commence ma journée. Trois mille quatre cent… zut.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de vous ? Bien sûr ! Vous êtes entre l'étoile trois mille douze et l'étoile trois mille treize, dans mon carnet. C'est une très bonne place.", {})],
			}},
		{"id": "philippine", "nom": "Mademoiselle Philippine Feuillet", "titre": "bibliothécaire de la Bibliothèque des Cartes", "maison": "porte_philippine", "village": "hautefond", "vouvoie": true,
			"agenda": [[8, 12, "bibliotheque_bureau"], [12, 13, "haute_banc_1"], [13, 18, "bibliotheque_rayons"], [18, 20, "haute_banc_1"], [20, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "chignon", "yeux": Y_VERT, "haut": [0.35, 0.45, 0.35], "robe": [0.28, 0.36, 0.3], "robe_longue": true, "lunettes": true, "taille": 0.94},
			"teinte": PEAU[3],
			"mj": {"tenue": "savant", "objet": "livre"},
			"humeur_base": 0.4, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.9, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"carte_postale": 2.0, "the_menthe": 2.0, "plume_corbeau": 1.5, "chouette_plume": 2.0, "tisane_brume": 1.5, "boussole_sud": 2.0}, "deteste": {"sifflet_muet": -0.5, "sardine": -1.0},
			"tics": ["Chut…", "(Elle chuchote.)", "Ce pays n'existe pas. Hélas.", "Rayon trois, étagère douze."],
			"surnoms": [[0, "cher lecteur"], [25, "lecteur assidu"], [50, "lecteur adoré"], [75, "mon explorateur"], [95, "mon pays préféré"]],
			"repliques": {
				"accueil": [
					L("(Elle chuchote.) Bienvenue à la Bibliothèque des Cartes. Je suis Mademoiselle Philippine Feuillet. Ici, on parle tout bas, on tourne les pages doucement, et on ne plie jamais une carte dans le mauvais sens. Elle s'en souviendrait.", {"visites_max": 1}, "salut"),
					L("(Elle chuchote.) {surnom} ! Quel plaisir. J'ai reçu une carte d'un pays qui n'existe pas. Avec des montagnes en forme de théière. Vous voulez la voir ? Chut. Venez.", {"visites_min": 2}),
				],
				"humeur": [
					L("(Elle chuchote.) Très bien. J'ai rangé l'archipel entier, du nord au sud, puis du plus petit au plus grand. Puis par couleur de mer. C'était le plus joli.", {}),
					L("(Elle chuchote.) Un peu agacée. Le Professeur Lunette a encore emprunté les cartes du ciel. En retard de six semaines. Je vais le gronder. Tout doucement. Il a horreur de ça. Enfin, je crois.", {}, "rire"),
					L("(Elle chuchote.) Le soir, je m'assois sur le banc de la promenade et je regarde la mer. Je dessine dans ma tête les pays qu'il y a derrière l'horizon. Il y en a toujours un de plus.", {"soir": true}),
				],
				"lui": [
					L("(Elle chuchote.) Je chuchote depuis que j'ai six ans. Mon père était bibliothécaire, ma mère aussi. À la maison, quand on se disputait, on se disputait en chuchotant. C'était très reposant.", {}),
					L("(Elle chuchote.) J'adore les cartes de pays qui n'existent pas. Des îles inventées par des marins fatigués, des royaumes dessinés par des enfants, des continents nés d'une tache d'encre. J'en ai deux cents. Ce sont mes préférées. Elles ne changent jamais d'avis.", {"sujet_min": ["lui", 1]}),
					L("(Elle chuchote.) Un jour, j'ai crié. Une seule fois. Une souris était entrée dans le rayon des Mers du Sud. Toute la Haute-Ville a entendu. Le Bourgmestre a cru à un incendie. Il a fait un discours pour me rassurer. C'est la souris qui est partie la première.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("(Elle chuchote.) Nous avons ici la première carte de Hautefond, dessinée par Dame Ysolde elle-même. Il n'y a que la butte, la mer, et une petite colonne dessinée au crayon, avec écrit : « un jour ». Je la regarde souvent.", {}),
					L("(Elle chuchote.) Notre carte de la Cité des Nuées était fausse : elle avait été dessinée depuis en bas, en regardant en l'air. La ligne a rouvert, et je suis montée la corriger moi-même. Quarante erreurs. Et une très longue gomme.", {"sujet_min": ["ile", 1]}),
					L("(Elle chuchote.) Les plans des Strates sont rangés dans un tiroir fermé, « par ordre du Bourgmestre ». Mais Ysaé est venue me décrire la Fronde. J'ai fait une carte d'après ses mots. Elle est pleine de musique et de couleurs. C'est la plus belle de la Bibliothèque.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("(Elle chuchote.) Augustin, le meunier, m'apporte un poème chaque semaine. « Pour la Bibliothèque », dit-il. Je les range dans un tiroir à part. Un tiroir à moi. Il ne faut pas le lui dire.", {}),
					L("(Elle chuchote.) Le Professeur Lunette a dessiné une étoile sur une de mes cartes de la côte. Au crayon. « Pour Clémentine », a-t-il dit. Je ne l'ai pas effacée. Je ne sais pas pourquoi. Enfin, si, je sais.", {}),
					L("(Elle chuchote.) La Capitaine Héloïse m'a promis de cartographier le ciel au-dessus de la mer, depuis l'Albatros. Des cartes de nuages ! Ils changent tout le temps. Je vais devoir faire une nouvelle carte chaque matin. J'ai hâte.", {}, "rire"),
					L("(Elle chuchote.) Depuis que la ligne a rouvert, je suis descendue voir la Fronde en vrai, avec ma carte faite d'après les mots d'Ysaé. Elle est fausse à quatre endroits. Un peintre, Fusain, va la peindre sur son Mur. Avec les erreurs. Ce sont mes plus jolies erreurs.", {"a_rencontre": "fusain_fr"}),
				],
				"interpelle": [L("(Elle chuchote.) Psst… Bonjour…", {"visites_max": 0}), L("(Elle chuchote.) {surnom}… J'ai une nouvelle carte…", {"visites_min": 1}, "salut")],
				"au_revoir": [L("(Elle chuchote.) Au revoir, {surnom}. Ne vous perdez pas. Ou alors, perdez-vous quelque part de joli.", {}, "salut"), L("(Elle chuchote.) À bientôt. Et si vous découvrez un pays, revenez me le dessiner.", {}), L("(Elle chuchote.) Bonne nuit… La Bibliothèque dort. Les cartes, elles, rêvent de voyages.", {"soir": true})],
				"souvenir": [L("(Elle chuchote.) Si je me souviens de vous ? Je vous ai rangé dans ma mémoire, rayon « voyageurs aimables », étagère du haut.", {})],
			}},
		{"id": "hector_hf", "nom": "le Bourgmestre Hector Bellevue", "titre": "Bourgmestre de Hautefond", "maison": "porte_hector", "village": "hautefond", "vouvoie": true,
			"agenda": [[8, 11, "mairie_bureau"], [11, 12, "mairie_balcon"], [12, 14, "place_fontaine"], [14, 18, "mairie_bureau"], [18, 19, "mairie_balcon"], [19, 21, "place_fontaine"], [21, 8, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.5, 0.12, 0.16], "taille": 1.06, "carrure": 1.3},
			"teinte": PEAU[2],
			"mj": {"tenue": "noble", "objet": "canne"},
			"humeur_base": 0.55, "traits": {"bavard": 1.0, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.7, "rancunier": 0.15},
			"aime": {"coupe_course": 3.0, "bague": 2.0, "piece_or": 2.0, "gateau_miel": 2.0, "chocolat_chaud": 1.5, "bouquet_tournesols": 1.5}, "deteste": {"vieille_botte": -2.0, "bombe_peinture": -1.5},
			"tics": ["Mes chers concitoyens…", "Hum hum !", "Je serai bref.", "Une médaille !"],
			"surnoms": [[0, "cher visiteur"], [25, "cher administré"], [50, "citoyen d'honneur"], [75, "mon cher conseiller"], [95, "médaille d'or de Hautefond"]],
			"repliques": {
				"accueil": [
					L("Hum hum ! Mes chers concitoyens… ah, un seul concitoyen. Ce n'est pas grave : je serai bref. Hector Bellevue, Bourgmestre de Hautefond, chevalier de l'Ordre du Rouage, médaillé de la Vapeur, trois fois coupeur de ruban d'honneur. Bienvenue ! Voilà. C'était bref. Pour moi.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Quel bonheur ! Vous avez vu ma nouvelle médaille ? Non ? C'est la médaille de la Médaille. On me l'a remise pour avoir remis tant de médailles. Je l'ai remise moi-même. C'était émouvant.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Magnifique ! Ce matin, j'ai coupé le ruban du nouveau banc de la Place. Un discours de quarante minutes. Le banc était très ému. Les gens assis dessus, un peu moins.", {}, "rire"),
					L("Un peu vexé. Pour la réouverture de la ligne des Nuées, Maîtresse Capucine ne m'a laissé couper qu'un ruban de trente centimètres. À deux. Mon discours, lui, a duré trente minutes. Elle dit que c'est encore trop.", {}),
					L("Le soir, je fais le tour de la fontaine et je salue Dame Ysolde. Je lui raconte ma journée. Elle ne m'interrompt jamais. C'est mon public préféré.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis Bourgmestre depuis douze ans. Réélu quatre fois ! Bon, j'étais le seul candidat. Mais j'ai fait campagne avec le même enthousiasme. On ne se bat pas contre un adversaire, on se bat pour une ville.", {}),
					L("Ma moustache ? Je la cire chaque matin avec de l'huile de rouage. Une goutte de chaque côté. Gaspard l'horloger dit que c'est la moustache la mieux réglée de l'île. Je l'ai fait graver sur une plaque.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Vous voulez savoir pourquoi j'aime tant les discours ? Quand j'étais petit, je bégayais. Je n'osais pas parler. Aujourd'hui, toute la Place m'écoute. Enfin, elle m'entend. C'est déjà beaucoup.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Hautefond, mes chers concitoyens, c'est la plus belle ville de l'archipel ! Pierre blonde, ardoise bleue, laiton et cuivre ! La Place de la Colonne, la Haute-Ville, la Ville-Moyenne, la Basse-Ville… une ville en étages, comme un beau gâteau. Avec une Colonne en guise de bougie.", {}),
					L("Les Strates, sous la ville… Hum. Des ateliers, des mines de cristaux, des forges. Très utiles. Et puis il y a la Fronde. Des musiciens, des crêtes de couleur, des bannières… Bon. Ce n'est pas mon style. Mais la ligne a rouvert, et j'ai fait un discours. Un discours très ouvert. Devant un brasero.", {"sujet_min": ["ile", 1]}),
					L("Les Nuées, c'est fait. Les Strates aussi : deux rubans, deux discours. Reste le Dôme d'Azur… Quand toutes les lignes seront ouvertes, Hautefond sera le cœur de quatre mondes ! J'ai déjà écrit le discours qui reste. Il fait deux heures.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Cette jeune Ysaé, du marché, avec ses cheveux bleus et ses bijoux de boulons… Hum. Ce n'est pas très réglementaire. Mais j'ai vu une broche, sur son étal, en forme de petite Colonne… Si vous la voyez, ne lui dites pas que je l'ai regardée. Deux fois.", {}),
					L("Mathilde la forgeronne m'a forgé toutes mes médailles. Elle rit si fort quand je viens en commander une nouvelle que la forge tremble. Je pense qu'elle rit de joie. J'en suis presque sûr.", {}, "rire"),
					L("Rosalie, au marché, sait tout avant tout le monde. Elle a su que j'allais faire un discours avant que je le sache moi-même. Je soupçonne mes moustaches de bavarder.", {}, "rire"),
					L("Le grand-père d'Ysaé, celui à la crête orange, m'a tendu une clé, devant son brasero, pour que je continue mon discours. Une « clé de parole ». Personne ne m'avait jamais demandé de continuer ! Je me suis tu. Je ne sais toujours pas pourquoi.", {"a_rencontre": "brasero"}),
					L("La Doyenne Agathe, en bas… Je lui ai fait un discours de quarante minutes. Elle m'a répondu en deux phrases. Les gens ont applaudi les deux phrases. Je les ai notées. Je les relis le soir. Elles sont très bien. Un peu courtes.", {"a_rencontre": "agathe_st"}, "rire"),
				],
				"interpelle": [L("Hum hum ! Vous, là ! Approchez, je serai bref !", {"visites_max": 0}, "salut"), L("{surnom} ! Mon cher ! Juste un petit mot !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom} ! Et n'oubliez pas de voter pour moi. Il n'y a pas d'élection, mais l'habitude est bonne.", {}, "rire"), L("Allez, mon cher. Hautefond vous salue. C'est-à-dire moi. Mais au nom de tous.", {}, "salut"), L("Bonne soirée ! Je vais réviser mon discours de demain. Il n'y a rien à inaugurer demain. Je trouverai.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de vous ? Mon cher, je n'oublie jamais un visage ! Ni un nom. Ni une poignée de main. Vous avez une excellente poignée de main. Je l'ai notée.", {})],
			}},
		# ================================================================ la Ville-Moyenne
		{"id": "rosalie_hf", "nom": "Rosalie Cannelle", "titre": "marchande d'épices et de fruits du Grand Marché", "maison": "porte_rosalie", "village": "hautefond",
			"agenda": [[6, 18, "marche_etal_1"], [18, 22, "taverne_table_1"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "boucles", "yeux": Y_BRUN, "haut": [0.85, 0.4, 0.2], "tablier": [0.95, 0.85, 0.6], "robe": [0.6, 0.25, 0.18], "carrure": 1.15},
			"teinte": PEAU[4],
			"mj": {"tenue": "marchand", "objet": "panier"},
			"humeur_base": 0.65, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"dattes": 2.0, "miel": 2.0, "the_menthe": 2.0, "bouquet_tournesols": 2.0, "chocolat_chaud": 1.5, "truffe": 1.5}, "deteste": {"gelee_slime": -1.5, "piment_infernal": -0.5},
			"tics": ["Tu ne le sais pas par moi !", "Goûte, goûte !", "Ha ha ha !", "Entre nous…"],
			"surnoms": [[0, "mon chou"], [25, "ma cannelle"], [50, "mon petit piment"], [75, "ma muscade"], [95, "mon trésor d'épices"]],
			"boutique": {"vend": {"pomme": 1, "baies": 1, "dattes": 3, "miel": 4, "pain_miel": 4, "tarte_potiron": 7}, "achete": {"pomme": 1, "baies": 1, "miel": 4, "champignon": 2, "truffe": 9, "noix_coco": 2, "graines": 1}},
			"repliques": {
				"accueil": [
					L("Approche, approche, mon chou ! Rosalie Cannelle, épices et fruits ! Cannelle, muscade, poivre qui chatouille, pommes des Vergers, dattes du sud… Goûte ! Et en échange, raconte-moi tout. Qui tu es, d'où tu viens, ce que tu as mangé ce matin. Surtout ce que tu as mangé.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te voilà ! Tu tombes bien, j'ai des nouvelles toutes chaudes. Plus chaudes que mes épices. Assieds-toi sur la caisse. Pas celle-là, elle contient du poivre. Elle éternue.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Formidable ! J'ai vendu trois sacs de cannelle, deux paniers de pommes, et j'ai appris onze secrets. Une très bonne journée. Les secrets, je ne les vends pas. Je les offre.", {}, "rire"),
					L("Un peu enrhumée. C'est le poivre. Il fait ça quand il est content. Atchoum ! … Voilà, il est très content.", {}, "rire"),
					L("Le soir, je vais au Piston Joyeux, à ma table près du comptoir. Firmin me sert un chocolat à la cannelle. Ma cannelle. Il dit que c'est la sienne. Nous nous disputons tous les soirs. C'est délicieux.", {"soir": true}),
				],
				"lui": [
					L("Mes parents venaient d'une île très loin, au sud, avec un bateau plein d'épices. Le bateau a coulé dans le Port des Cordages. Tout doucement. Toute la baie a senti la cannelle pendant un mois. Ils ont décidé de rester. Moi, je suis née dans l'odeur.", {}),
					L("Mon rire, on l'entend depuis le Mât des dirigeables. La Capitaine Héloïse dit qu'elle s'en sert pour se repérer par temps de brouillard. « Tout droit, vers le rire de Rosalie. » Je trouve ça très flatteur.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux savoir pourquoi je connais tous les potins ? Parce que les gens me racontent tout. Et tu sais pourquoi ils me racontent tout ? Parce que je ne répète jamais rien de méchant. Seulement les jolies choses. Ce sont celles qui voyagent le mieux.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Grand Marché, c'est le ventre de Hautefond, mon chou. Les auvents rayés, les fontaines, les étals… Il y a des fruits des Vergers, de la farine du Moulin, du poisson du Port, et les bijoux d'Ysaé. Tout Hautefond passe ici. Et tout Hautefond me dit bonjour.", {}),
					L("Mes fruits viennent des Vergers en terrasses, au sud. Père Bastien parle à ses arbres. Il dit que les pommes poussent mieux quand on leur raconte des histoires. Je lui en fournis. Des histoires. Ses pommes sont très bien informées.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Ma cousine habite au Dôme d'Azur, au fond de la mer. Elle m'écrit que là-bas, les épices ne sentent rien, à cause de l'air filtré. Quand la ligne rouvrira, je descends avec un sac de cannelle. Je vais leur réveiller le nez, à ces gens-là.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Entre nous, mon chou : Augustin le meunier écrit des poèmes à Mademoiselle Philippine. Il les cache dans les sacs de farine qu'il livre à la Bibliothèque. La Bibliothèque n'a pas besoin de farine. Tu ne le sais pas par moi !", {}, "rire"),
					L("Ysaé, l'étal à côté du mien, les notables la regardent de travers. Moi, je la regarde de face. Elle a le cœur sur la main et des boulons aux oreilles. Le Bourgmestre lui a acheté une broche en douce. Je l'ai vu. Tout le monde l'a vu. Il croit que non.", {}, "rire"),
					L("Firmin dit que sa machine à chocolat siffle comme une locomotive. Moi, je dis qu'elle siffle comme Firmin quand il perd aux cartes. Ils se ressemblent beaucoup, d'ailleurs. La moustache, la vapeur…", {}, "rire"),
				],
				"interpelle": [L("Hé, mon chou ! Viens goûter !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai des nouvelles !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Au revoir, mon chou ! Reviens vite : demain, j'aurai sûrement un nouveau potin. J'en ai toujours un.", {}, "salut"), L("File ! Et dis bonjour à tout le monde de ma part. Tout le monde. Je compterai.", {}, "rire"), L("Bonne nuit ! Je vais chez Firmin, gagner ma dispute du soir.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Mon chou, je me souviens même de ce que tu as acheté la première fois. Et de la tête que tu as faite en goûtant le poivre.", {})],
				"boutique": [L("Fruits frais, épices qui chatouillent, et miel qui chante ! Goûte d'abord, paie ensuite. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "gaspard_hf", "nom": "Gaspard Ressort", "titre": "horloger", "maison": "porte_gaspard", "village": "hautefond",
			"agenda": [[7, 12, "horloger_comptoir"], [12, 14, "horloger_etabli"], [14, 19, "horloger_comptoir"], [19, 22, "horloger_etabli"], [22, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_GRIS, "haut": [0.3, 0.24, 0.18], "tablier": [0.42, 0.3, 0.2], "lunettes": true, "taille": 0.92, "carrure": 0.85},
			"teinte": PEAU[2],
			"mj": {"tenue": "artisan"},
			"humeur_base": 0.3, "traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.6, "susceptible": 0.7, "rancunier": 0.3},
			"aime": {"engrenage": 2.5, "ressort": 2.5, "montre_envers": 1.0, "the_menthe": 1.5, "cristal_astral": 2.0, "biscuit_engrenage": 1.5}, "deteste": {"boite_a_rien": -1.5, "gelee_slime": -2.0},
			"tics": ["Tic. Tac.", "Vous avez quatre secondes de retard.", "Précisément.", "À la seconde près."],
			"surnoms": [[0, "client"], [25, "client ponctuel"], [50, "client exemplaire"], [75, "mon ami réglé"], [95, "mon chronomètre"]],
			"boutique": {"vend": {"boussole_sud": 15, "parapluie_helice": 22, "canard_mecanique": 18, "corde_chanvre": 4, "canne_peche": 12, "ressort": 2, "engrenage": 3}, "achete": {"engrenage": 2, "ressort": 1, "boulon": 1, "montre_envers": 8, "fragment_meteorite": 6, "eclat_cristal": 7, "cristal_astral": 9}},
			"repliques": {
				"accueil": [
					L("Bonjour. Il est… quatorze heures, douze minutes, et sept secondes. Huit. Neuf. Gaspard Ressort, horloger. Je répare tout ce qui fait tic-tac, et ce qui devrait faire tic-tac mais ne le fait plus. Vous avez une montre ? Non ? Nous allons arranger ça.", {"visites_max": 1}, "salut"),
					L("{surnom}. Vous arrivez pile à l'heure. Je ne sais pas à quelle heure vous deviez arriver, mais vous y êtes pile. Je le sens.", {"visites_min": 2}),
				],
				"humeur": [
					L("Bonne. Toutes les horloges de la boutique sonnent en même temps. Toutes. Sauf une, qui a une demi-seconde d'avance. Je ne dormirai pas tant qu'elle n'aura pas présenté ses excuses.", {}),
					L("Agacé. La machine à chocolat de Firmin a sifflé à seize heures et trois secondes. Trois secondes ! Toute la Ville-Moyenne règle sa montre sur ce sifflet. J'ai dû corriger quarante montres.", {}, "rire"),
					L("Le soir, je travaille à l'établi, sous la lampe. C'est l'heure où les ressorts sont les plus calmes. On s'entend bien, les ressorts et moi. Nous n'aimons pas le bruit.", {"soir": true}),
				],
				"lui": [
					L("J'ai démonté ma première montre à quatre ans. Celle de mon grand-père. Je l'ai remontée à quatre ans et demi. Il restait une pièce. Je l'ai gardée. Je ne sais toujours pas où elle va. La montre marche quand même. Cela m'empêche de dormir.", {}),
					L("Ma grande œuvre, c'est l'Horloge Chantante, au-dessus du comptoir. À chaque heure, elle chante l'heure. « Il est trois heures, tra-la-la. » Elle chante juste. Toujours. C'est la seule chose dans ma vie qui ne me fasse jamais attendre.", {"sujet_min": ["lui", 1]}, "rire"),
					L("On dit que je déteste le retard. C'est vrai. Mais vous savez pourquoi ? Une seconde perdue, on ne la retrouve jamais. Alors je préfère qu'on les passe ensemble, à l'heure. Au moins, on ne les perd pas tout seuls.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Grande Colonne tient son horloge de moi. L'horloge des départs, au-dessus du guichet. Maîtresse Capucine et moi, nous la vérifions chaque lundi à sept heures pile. Nous ne disons rien. Nous hochons la tête. C'est notre façon d'être heureux.", {}),
					L("Le Moulin des Quatre Vents, sur la colline, tourne si régulièrement par vent d'ouest qu'on pourrait y lire l'heure. J'ai essayé. Augustin a changé une aile ce jour-là. J'ai été en retard pour la première fois de ma vie. Je ne lui ai jamais pardonné. Si, un peu.", {"sujet_min": ["ile", 1]}, "rire"),
					L("On m'avait dit que les horloges de la Cité des Nuées étaient en verre. Je suis monté pour la réouverture, avec mon tournevis. Pas une seule ! Mais l'inventrice de là-haut m'en fabrique une. J'y retourne bientôt. Juste pour regarder. Peut-être pour régler.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Barnabé a la montre que je lui ai offerte. Elle sonne cinq minutes avant chaque départ. Il est encore en retard. Je suis en train de mettre au point une montre qui le pousse dans le dos.", {}, "rire"),
					L("Ysaé m'a acheté trois vieux rouages, l'autre jour. Elle en a fait une bague qui tourne quand on bouge le doigt. Je n'aime pas qu'on démonte mes rouages. Mais je dois admettre… la bague est juste. Parfaitement juste.", {}),
					L("La petite Pimprenelle passe tous les jours ramasser les rouages trop petits. Elle arrive à neuf heures pile. Pile ! C'est la personne la plus ponctuelle de Hautefond. Elle a neuf ans. Il y a de l'espoir.", {}),
				],
				"interpelle": [L("Vous. Quelle heure avez-vous ?", {"visites_max": 0}), L("{surnom}. Pile à l'heure. Entrez.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Vous partez à… quatorze heures trente-deux et cinq secondes. Je note.", {}), L("À bientôt. Et ne soyez pas en retard. Ni en avance. Les deux me fatiguent.", {}, "salut"), L("Bonsoir. L'Horloge Chantante va bientôt chanter vingt-deux heures. Elle chante plus doucement, le soir.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Vous êtes venu la première fois un jour à onze heures quarante-trois. Je m'en souviens à la seconde près. C'est ma façon de me souvenir des gens que j'aime bien.", {})],
				"boutique": [L("Boussoles, parapluies, mécaniques et ressorts. Tout est réglé, tout est garanti, tout est à l'heure. Tu as {pieces} pièces.", {})],
			}},
		{"id": "firmin", "nom": "Firmin Bouilloire", "titre": "patron de la taverne « Le Piston Joyeux »", "maison": "porte_firmin", "village": "hautefond",
			"agenda": [[6, 23, "taverne_comptoir"], [23, 6, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.75, 0.68, 0.55], "tablier": [0.92, 0.9, 0.85], "taille": 1.04, "carrure": 1.4},
			"teinte": PEAU[1],
			"mj": {"tenue": "cuisinier", "objet": "plateau"},
			"humeur_base": 0.6, "traits": {"bavard": 0.85, "humour": 0.85, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"cacao": 3.0, "miel": 2.0, "biscuit_engrenage": 1.5, "gateau_miel": 2.0, "noix_coco": 1.5, "dattes": 1.5}, "deteste": {"soda_neon": -1.5, "gelee_slime": -1.5},
			"tics": ["TCHOUUU !", "Chaud devant !", "Par ma moustache !", "Encore une tasse ?"],
			"surnoms": [[0, "voyageur"], [25, "habitué"], [50, "pilier du comptoir"], [75, "mon chocolat préféré"], [95, "piston de mon cœur"]],
			"boutique": {"vend": {"chocolat_chaud": 4, "cafe_vapeur": 3, "limonade_boucan": 3, "sirop_menthe": 2, "the_menthe": 3, "biscuit_engrenage": 5, "tarte_potiron": 7}, "achete": {"cacao": 3, "miel": 4, "baies": 1, "pomme": 1, "noix_coco": 2, "dattes": 2}},
			"repliques": {
				"accueil": [
					L("TCHOUUU ! Ah, pardon, c'est la machine. Bienvenue au Piston Joyeux ! Firmin Bouilloire, patron, serveur, et gardien de la moustache la plus grande de Hautefond. Chocolat chaud ? Thé fumé ? Limonade à la vapeur ? Soda au gingembre ? Assieds-toi, tout arrive en sifflant.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Ta tasse t'attend ! Enfin, une tasse. Elles se ressemblent toutes. Mais celle-là, je l'ai chauffée en pensant à toi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Formidable ! La machine a sifflé quarante fois aujourd'hui. Quarante chocolats ! Les vitres ont tremblé, les chats ont fui, et Gaspard a corrigé sa montre trente-neuf fois.", {}, "rire"),
					L("Un peu de vapeur dans la moustache. Rosalie dit que mon chocolat à la cannelle est le sien. LE SIEN ! C'est ma machine, c'est ma tasse, c'est ma moustache dedans quand je goûte ! … Bon, c'est sa cannelle.", {}),
					L("Le soir, le Piston Joyeux est plein. On rit, on joue aux cartes, Héloïse raconte ses voyages, Rosalie raconte tout le reste. Et moi, je sers. Je suis l'homme le plus heureux de la Ville-Moyenne. Et le plus essoufflé.", {"soir": true}),
				],
				"lui": [
					L("Ma machine à chocolat, je l'ai achetée à un vieux mécanicien des Strates. Elle était faite pour une locomotive. Elle fait le meilleur chocolat de l'archipel, mais elle siffle comme si elle allait partir. Un jour, elle partira. Avec moi dessus.", {}, "rire"),
					L("Ma moustache fait trente-deux centimètres d'une pointe à l'autre. Je la roule en spirale le matin. Quand je goûte le chocolat, elle trempe un peu. C'est pour ça qu'elle sent si bon. Rosalie dit que c'est dégoûtant. Rosalie est jalouse.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le Piston Joyeux, c'était la taverne de mon père. Il servait des boissons fortes, et les gens se disputaient. Moi, j'ai tout remplacé par du chocolat. Depuis, les gens se disputent encore, mais ils finissent par rire. Le chocolat, ça arrondit les coins.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Piston Joyeux est au cœur de la Ville-Moyenne, entre le Grand Marché et l'horloger. Si tu te perds, écoute : quand ça siffle, c'est ici. Quand ça rit très fort, c'est Rosalie, ici aussi.", {}, "rire"),
					L("Mon frère Gustave tient le Café Cumulus, dans la Cité des Nuées. Depuis que la ligne a rouvert, je lui envoie un chocolat par la première capsule du matin. Il arrive encore chaud. Il fait la grimace, et il le finit. Ma moustache a gagné.", {"sujet_min": ["ile", 1]}),
					L("La nuit, quand la taverne est calme, j'entends de la musique monter de la cage du bas de la Colonne. De la Fronde, dans les Strates. Ça tape, ça grince, ça chante. Ma machine siffle en rythme. Je crois qu'elle a de la famille, là-dessous.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("La Capitaine Héloïse boit un soda au gingembre avant chaque décollage. « Pour l'équilibre », dit-elle. Le jour où elle a oublié, l'Albatros a fait trois fois le tour du Mât avant de partir. Je ne dis pas qu'il y a un lien. Mais je le pense très fort.", {}, "rire"),
					L("Le vieux Léon, du Port, vient ici le dimanche. Il prend un chocolat, il grogne, il le boit, il grogne, il en reprend un. Il grogne en partant. C'est mon meilleur client. Il ne l'avouera jamais.", {}, "rire"),
					L("Barnabé vient à midi, tout pâle, après ses montées. Je lui sers un chocolat bien sucré, et en trois gorgées, il reprend des couleurs. Rouge. Puis rose. Puis normal. C'est très joli à regarder.", {}),
					L("En bas, dans la Fronde, une mémé m'a donné la recette de sa potée : « une louche de champignons, une louche d'amour, et Excalibur ». J'ai cherché de l'Excalibur dans tout le Grand Marché. Rosalie dit que c'est une épice très rare. Je crois qu'elle invente.", {"a_rencontre": "gamelle"}, "rire"),
					L("Je suis descendu dans les Strates pour la réouverture, et j'ai retrouvé le vieux mécanicien qui m'a vendu ma machine : Papy Ferdinand ! Il m'a demandé si je disais bonjour à la chaudière, le matin. Je le fais. Je ne l'avais jamais avoué à personne.", {"a_rencontre": "ferdinand_st"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Tu as froid ? Tu as soif ? Tu as les deux ? TCHOUUU !", {"visites_max": 0}, "salut"), L("{surnom} ! Ta tasse refroidit !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("À plus tard, {surnom} ! Et essuie-toi la lèvre : tu as une moustache de chocolat. Bienvenue au club !", {}, "rire"), L("Reviens vite ! La machine s'ennuie quand elle ne siffle pas pour toi.", {}, "salut"), L("Bonne nuit ! Je ferme à vingt-trois heures. La machine aussi. Elle fait un dernier petit « tchou » tout doux. Écoute.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Par ma moustache, oui ! Tu as fait le saut le plus haut de la taverne la première fois que la machine a sifflé.", {}, "rire")],
				"boutique": [L("Chocolat chaud, café à la vapeur, limonade, sirop, et biscuits-engrenages tout juste sortis du four ! Sans une goutte de boisson forte : ici, on est joyeux tout seul. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "heloise_hf", "nom": "Capitaine Héloïse Nimbus", "titre": "aéronaute, capitaine du dirigeable « l'Albatros »", "maison": "porte_heloise", "village": "hautefond",
			"agenda": [[7, 11, "mat_pied"], [11, 17, "mat_passerelle"], [17, 19, "mat_pied"], [19, 23, "taverne_table_2"], [23, 7, "maison"]],
			"azur": {"cheveux": BLOND_PALE, "coiffure": "queue", "yeux": Y_BLEU, "haut": [0.5, 0.32, 0.2], "foulard": [0.85, 0.2, 0.18], "lunettes": true, "taille": 1.04},
			"teinte": PEAU[2],
			"mj": {"tenue": "aventurier", "objet": "lanterne", "chapeau": "plume"},
			"humeur_base": 0.65, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.95, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"plume_vent": 2.5, "plume_ventaile": 3.0, "boussole_sud": 2.0, "toile_voile": 2.0, "limonade_boucan": 1.5, "carte_postale": 1.5}, "deteste": {"vieille_botte": -1.0, "caillou": -1.0},
			"tics": ["Larguez les amarres !", "Cap à l'ouest !", "Vent arrière !", "Là-haut, tout est plus simple."],
			"surnoms": [[0, "terrien"], [25, "moussaillon des airs"], [50, "mon second"], [75, "mon co-pilote"], [95, "mon étoile de navigation"]],
			"repliques": {
				"accueil": [
					L("Ohé, terrien ! Capitaine Héloïse Nimbus, aéronaute, et voici l'Albatros, le plus beau dirigeable de l'archipel. Ne le regarde pas trop longtemps, il rougit. Enfin, il est déjà rouge. Mais il rougit de l'intérieur.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Belle brise aujourd'hui, hein ? Vent d'ouest, nuages à mille pieds, une mouette de Margot à bâbord. Le ciel est d'excellente humeur.", {"visites_min": 2}),
				],
				"humeur": [
					L("Splendide ! J'ai fait le tour de l'île en vingt minutes, avec le vent dans le dos. Les Arches, le Phare, les Vergers… Père Bastien m'a fait coucou avec une branche. Avec l'arbre entier, presque.", {}, "rire"),
					L("Un peu impatiente. L'Albatros a besoin d'une nouvelle voile de stabilisation, et Mathilde n'a pas fini les rivets. Elle dit « demain ». Elle le dit en riant. Je n'arrive jamais à savoir si c'est bon signe.", {}),
					L("Le soir, je raconte mes voyages au Piston Joyeux. J'exagère un peu. Les nuages deviennent des montagnes, les mouettes deviennent des dragons. Firmin me ressert du chocolat chaque fois que j'invente un dragon.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai eu mon premier ballon à six ans. Un ballon de fête, rouge. Je l'ai lâché, il est monté, il est monté… J'ai pleuré, puis j'ai décidé de le rattraper. Je le cherche encore. C'est pour ça que l'Albatros est rouge : pour qu'il me reconnaisse.", {}),
					L("L'Albatros, je l'ai construit avec des toiles de tente, des tonneaux, et un moteur à vapeur trouvé au fond d'une grange. Il a volé du premier coup. Bon, à l'envers. Mais il a volé.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon rêve, c'est de faire le tour du monde par les airs. Sans m'arrêter. Juste en regardant tout, d'en haut. Je sais que je reviendrai à Hautefond quand même. On revient toujours là où quelqu'un vous attend avec un chocolat.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Mât des dirigeables, c'est mon port à moi. Il est en acier, il a cent marches, et en haut, il y a une passerelle où l'Albatros vient s'accrocher par le nez. Le nez, c'est l'endroit le plus solide d'un dirigeable. Comme chez les gens têtus.", {}, "rire"),
					L("La Cité des Nuées… On peut accoster au Port des Nuées, en dirigeable, mais seulement par vent calme : les vents tournent fort autour de l'île flottante. Et Zéphyrine dit toujours qu'elle est arrivée la première. Alors pour la réouverture, j'ai pris la capsule. Avec Barnabé. Je lui ai tenu la main.", {"sujet_min": ["ile", 1]}),
					L("Par temps clair, d'en haut, on voit une grande tache bleue sous la mer, au large : c'est le Dôme d'Azur, la ville sous-marine. Parfois, une baleine passe par-dessus. On dirait un nuage qui nage. Je n'ai jamais rien vu d'aussi beau.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le vieux Léon, au Port, dit que les dirigeables, « c'est des bateaux qui ont perdu la mer ». Je lui dis que les bateaux, ce sont des dirigeables qui ont oublié de monter. On se dispute depuis dix ans. C'est mon meilleur ami.", {}, "rire"),
					L("Barnabé veut faire un tour avec moi. Il est venu trois fois jusqu'au pied du Mât. Une fois jusqu'à la dixième marche. La prochaine fois, je l'attends en haut avec un chocolat. Les gens montent beaucoup mieux quand il y a du chocolat en haut.", {}),
					L("Le Professeur Lunette croit qu'une étoile lui fait des clins d'œil. Je n'ose pas lui dire que, certaines nuits, c'est peut-être ma lanterne de navigation. Mais certaines nuits, l'Albatros est au sol… et l'étoile cligne quand même. Alors je me tais.", {}),
				],
				"interpelle": [L("Ohé, terrien ! Tu as déjà vu un dirigeable de près ?", {"visites_max": 0}, "salut"), L("{surnom} ! Belle brise ! Viens voir !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom} ! Et si tu vois un ballon rouge, dis-lui que je le cherche.", {}, "salut"), L("À la prochaine ! Garde la tête dans les nuages, mais les pieds sur la passerelle.", {}, "rire"), L("Bonne nuit ! Ce soir, l'Albatros dort au Mât. Il ronfle un peu quand le vent souffle dans ses cordages.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? D'en haut, je reconnais tout le monde, {surnom}. Toi, tu es celui qui lève la tête quand l'Albatros passe. Ils ne sont pas si nombreux.", {})],
			}},
		{"id": "ysae", "nom": "Ysaé", "titre": "créatrice de bijoux, « qui vient d'en bas »", "maison": "porte_ysae", "village": "hautefond",
			"agenda": [[9, 17, "marche_etal_3"], [17, 21, "rue_2"], [21, 9, "maison"]],
			"azur": {"cheveux": BLEU_VIF, "coiffure": "carre", "yeux": Y_VIOLET, "haut": [0.12, 0.12, 0.14], "foulard": [0.2, 0.75, 0.75], "taille": 0.98, "carrure": 0.95},
			"teinte": PEAU[3],
			"mj": {"tenue": "artisan"},
			"humeur_base": 0.5, "traits": {"bavard": 0.55, "humour": 0.75, "curiosite": 0.75, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"eclat_cristal": 2.5, "boulon": 2.0, "bombe_peinture": 2.5, "cristal_soufre": 2.0, "sirop_menthe": 1.5, "fanzine": 2.0}, "deteste": {"coupe_course": -0.5, "vieille_botte": -1.0},
			"tics": ["Tranquille.", "Ça brille, hein ?", "En bas, on dit…", "On verra bien d'où souffle le vent."],
			"surnoms": [[0, "toi"], [25, "l'ami d'en haut"], [50, "camarade"], [75, "frangin de cœur"], [95, "l'enfant de la Fronde"]],
			"repliques": {
				"accueil": [
					L("Salut. Ysaé. Bijoux de boulons et de cristal, faits main, faits en bas. Tu peux regarder, tu peux toucher, tu peux même ne rien acheter. Ici, on dit que je « viens d'en bas ». C'est vrai. Et j'en suis fière.", {"visites_max": 1}, "salut"),
					L("{surnom}. Tranquille ? Regarde, j'ai fait une nouvelle bague : un rouage qui tourne quand tu bouges le doigt. Gaspard a grimacé. Puis il a dit « c'est juste ». Chez lui, c'est une déclaration d'amour.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Deux dames de la Haute-Ville m'ont regardée de travers ce matin. Une heure après, elles sont revenues acheter des boucles d'oreilles. C'est toujours comme ça. Ça commence de travers, ça finit de face.", {}, "rire"),
					L("Calme. J'ai trouvé un éclat de cristal qui chante quand on souffle dessus. Je ne vais pas le vendre. Certaines choses, il faut les garder pour soi. Ou pour quelqu'un.", {}),
					L("Le soir, je traîne dans la rue en bas du marché, je regarde la Colonne s'allumer, et j'écoute. Tu entends la musique qui monte de la cage ? C'est chez moi. Ils commencent à jouer quand le soleil se couche.", {"soir": true}),
				],
				"lui": [
					L("Je suis née dans la Fronde, dans les Strates, sous la ville. Mes parents réparent des rails le jour et jouent de la musique la nuit. J'ai grandi entre une forge et une batterie. Alors, le bruit, ça ne me fait pas peur. Le silence, un peu.", {}),
					L("Mes cheveux ? En bas, chacun choisit sa couleur le jour de ses quinze ans. J'ai choisi le bleu des cristaux de la mine. Ma mère a choisi le vert. Mon grand-père, le orange. Il a quatre-vingts ans, et sa crête tient toute seule. Il en est très fier.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je monte vendre au marché parce que je veux qu'en haut, on voie ce qu'on fait en bas. Pas des gens bizarres. Des gens qui fabriquent, qui chantent, qui s'entraident. Un bijou à la fois. C'est lent. Mais un boulon, c'est petit aussi, et ça tient des ponts.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Strates, c'est la ville sous la ville. Des étages creusés dans la roche : des ateliers, des mines de cristaux, des rails, des forges. Et la Fronde : notre quartier. Des bannières au A cerclé, des peintures sur tous les murs, et de la musique tout le temps. La ligne a rouvert. Descends, tu verras.", {}),
					L("Pendant dix ans, la ligne du bas était fermée « pour travaux ». En vrai, les travaux, c'était un peu nous. On a repeint la gare. En couleurs. Beaucoup de couleurs. Maîtresse Capucine a fait semblant de ne rien savoir. Elle est plus cool qu'elle n'en a l'air.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Cité des Nuées, en haut, et le Dôme d'Azur, tout au fond… Les gens d'en haut rêvent de monter, ceux d'en bas rêvent du ciel, et ceux du Dôme rêvent de pluie. Moi, je crois que la Colonne est là pour qu'on aille se voir. Tous.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Bourgmestre m'a acheté une broche en forme de Colonne. Il a fait comme si c'était pour sa nièce. Il n'a pas de nièce. Il la porte sous son écharpe. Je l'ai vue briller pendant son discours de mardi. Je n'ai rien dit. Je suis une professionnelle.", {}, "rire"),
					L("Rosalie, à l'étal d'à côté, est la seule qui m'a dit bonjour le premier jour. Elle m'a aussi donné une pomme et posé quarante questions. J'ai répondu à trois. Elle a deviné les trente-sept autres.", {}, "rire"),
					L("Mathilde, la forgeronne, me garde les chutes de cuivre de sa forge. Elle dit qu'en bas, son grand-père a appris à frapper avec les forgerons de la Fronde. Elle ne le dit pas trop fort, devant les notables. Mais elle rit très fort, alors ça compense.", {}),
					L("Ma mère, Bielle, chante une chanson sur moi. Elle ne la chante jamais quand je suis dans la fosse. Alors, un soir, je me suis cachée derrière l'orgue à vapeur. Je l'ai entendue. J'ai pleuré. Je ne lui ai jamais dit. Ne lui dis pas.", {"a_rencontre": "bielle"}),
					L("Tu es descendu jusqu'à la Fronde ? Tu as vu mon grand-père, au brasero ? Il t'a parlé de sa crête, je parie. … Il t'a tendu la clé de parole ? Alors tu es des nôtres. Il ne la donne pas à n'importe qui. Le Bourgmestre l'a eue. Il ne s'en est pas remis.", {"a_rencontre": "brasero"}, "rire"),
				],
				"interpelle": [L("Hé. Tu veux voir ce qui brille ?", {"visites_max": 0}), L("{surnom}. Viens, j'ai un truc à te montrer.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Salut, {surnom}. Et si quelqu'un te regarde de travers, souris-lui de face. Ça les déroute.", {}, "salut"), L("À plus. La ligne a rouvert : un de ces soirs, je t'emmène en bas. Promis. Prépare tes oreilles.", {}), L("Bonne nuit. Moi, je redescends. Par la cabine, maintenant, comme tout le monde. L'escalier de service, je le garde pour les grandes occasions.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Évidemment. Tu es la première personne d'en haut qui m'a demandé comment c'était, en bas. Ça, on ne l'oublie pas.", {})],
			}},
		# ================================================================ la Basse-Ville
		{"id": "mathilde", "nom": "Mathilde Soufflet", "titre": "forgeronne de la Forge à vapeur", "maison": "porte_mathilde", "village": "hautefond",
			"agenda": [[6, 12, "forge_enclume"], [12, 13, "forge_comptoir"], [13, 18, "forge_enclume"], [18, 20, "forge_comptoir"], [20, 6, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "queue", "yeux": Y_VERT, "haut": [0.45, 0.3, 0.2], "tablier": [0.25, 0.18, 0.12], "taille": 1.1, "carrure": 1.4},
			"teinte": PEAU[1],
			"mj": {"tenue": "forgeron", "objet": "marteau"},
			"humeur_base": 0.7, "traits": {"bavard": 0.75, "humour": 0.95, "curiosite": 0.5, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"minerai_fer": 2.0, "obsidienne": 2.0, "coeur_magma": 3.0, "tarte_potiron": 2.0, "chocolat_chaud": 1.5, "boulon": 1.0}, "deteste": {"gelee_slime": -1.5, "tisane_brume": -0.5},
			"tics": ["HA HA HA !", "Pfiou !", "Ça, c'est du solide !", "Tiens bon le manche !"],
			"surnoms": [[0, "toi là"], [25, "mon gars"], [50, "mon vieux rivet"], [75, "ma belle enclume"], [95, "mon acier trempé"]],
			"boutique": {"vend": {"epee": 60, "hache": 34, "pelle": 15, "epee_bois": 6}, "achete": {"minerai_fer": 5, "obsidienne": 8, "boulon": 1, "engrenage": 2, "ressort": 1, "hache": 14, "epee": 26, "epee_bois": 2}},
			"repliques": {
				"accueil": [
					L("HA HA HA ! Un visiteur ! Entre, entre, mais pas trop près de la presse : elle a mauvais caractère. Mathilde Soufflet, forgeronne ! Mes marteaux marchent à la vapeur, et moi, je marche au rire. HA HA ! Tu vois ? Ça marche !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te revoilà ! Tiens, regarde ce rivet. Il est beau, hein ? Non, tu as raison, c'est un rivet. Mais je l'ai fait avec amour. HA HA HA !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("En pleine forme ! Le grand marteau a tapé mille fois ce matin, et j'ai ri mille et une fois. La dernière, c'était parce que Pimprenelle a essayé de soulever ma pince. Elle l'a soulevée ! Un peu ! HA HA !", {}, "rire"),
					L("Un peu fatiguée. Le Bourgmestre a commandé une nouvelle médaille. La médaille de quoi, je lui ai demandé. Il a dit : « On verra. » J'ai ri si fort que j'ai cabossé l'enclume.", {}, "rire"),
					L("Le soir, je ferme les soupapes, j'éteins le grand feu, et j'écoute la forge refroidir. Tic, tic, tic, fait le métal. Pimprenelle dit qu'il dit bonne nuit. Elle a raison. Comme toujours. C'est fatigant.", {"soir": true}),
				],
				"lui": [
					L("J'ai appris à forger avec mon père, et lui avec son père, qui avait appris en bas, dans les Strates, avec les forgerons de la Fronde. Ils lui ont appris deux choses : bien taper, et bien rire. Je suis assez douée pour les deux.", {}),
					L("Mes marteaux sont mus par la vapeur. Trois grands marteaux, qui s'appellent Pif, Paf et Mamie. Mamie, c'est le plus gros. Il tape très lentement, très fort, et il ne se trompe jamais. Comme ma vraie mamie.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Pimprenelle, ma fille, veut être liftière. Pas forgeronne. Au début, ça m'a fait un petit pincement. Puis je me suis dit : la Colonne, c'est des tonnes de métal qui montent vers le ciel. C'est un peu de la forge qui s'envole. Ça me va.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Basse-Ville, c'est là où Hautefond travaille. Les ateliers, le lavoir, la Forge à vapeur, les rues des artisans. En haut, ils ont la vue. En bas, on a le bruit. Moi, je préfère le bruit. HA HA ! Il me ressemble.", {}, "rire"),
					L("Les câbles de la Colonne, c'est ma forge qui fait les crochets. Pour la ligne des Nuées, Maîtresse Capucine m'en a commandé deux cents tout neufs. Je les ai faits, elle les a vérifiés un par un avec ses lunettes. La ligne a rouvert. Pas un crochet n'a bougé. Elle, presque.", {"sujet_min": ["ile", 1]}),
					L("Juste sous la forge, il y a les premières galeries des Strates. Quand je tape fort, ils tapent en retour. Un coup, deux coups. C'est notre bonjour. La ligne a rouvert : un de ces jours, je descends serrer la main de ceux qui tapent. Fort.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Ysaé, du marché, je lui garde mes chutes de cuivre. Elle en fait des bijoux plus beaux que tout ce que je forge. Les notables font les gros yeux. Moi, je fais les gros rires. HA HA ! On verra bien qui fatigue le premier.", {}, "rire"),
					L("La Capitaine Héloïse attend ses rivets pour l'Albatros. Je les ai finis hier. Je ne lui ai pas encore dit. Elle vient tous les jours me demander, et j'adore sa tête quand je dis « demain ». Je lui dirai demain. Promis.", {}, "rire"),
					L("Pimprenelle a caché trois cents boulons sous son lit. Trois cents ! Le lit est monté de dix centimètres. Elle dit que c'est « pour s'entraîner à la hauteur ». C'est ma fille, ça.", {}, "rire"),
					L("Le jour où la ligne des Strates a rouvert, j'ai ri si fort de joie que, paraît-il, on m'a entendue jusque dans la Fronde. Ils m'ont écrit pour m'inviter à leur Assemblée. J'ai répondu : « Je vote pour tout ! » HA HA ! C'est plus gai.", {}, "rire"),
					L("Tu es descendu à la Grande Forge des Strates ? Alors c'est elle ! Maîtresse Brunehaut ! Celle qui me répond depuis vingt ans ! Elle rit en « HO » ? … HA HA HA ! Je le savais ! Dimanche, je descends. Préviens-la : qu'elle tienne bien son enclume.", {"a_rencontre": "brunehaut_st"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Viens voir taper !", {"visites_max": 0}, "salut"), L("{surnom} ! HA HA ! Viens par là !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("À plus, {surnom} ! Et tiens bon le manche, dans la vie comme à la forge !", {}, "salut"), L("Salut ! Si tu croises Pimprenelle, dis-lui de rentrer pour le goûter. Elle ne t'écoutera pas. Moi non plus. HA HA !", {}, "rire"), L("Bonne nuit ! La forge refroidit, et moi aussi. Enfin, pas le rire. Le rire, il ne refroidit jamais.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? HA ! Tu as sursauté si fort quand Mamie a tapé la première fois que tu as touché le plafond. On ne l'oublie pas, ça.", {}, "rire")],
				"boutique": [L("Épées, haches, pelles ! Forgées à la vapeur et trempées au rire ! Soupèse, ne te gêne pas. Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ dehors
		{"id": "leon_hf", "nom": "Léon Calfat", "titre": "maître du Port des Cordages", "maison": "porte_leon", "village": "hautefond",
			"agenda": [[5, 9, "port_q1"], [9, 16, "port_capitainerie"], [16, 19, "port_q2"], [19, 21, "port_banc"], [21, 5, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "court", "barbe": "longue", "yeux": Y_GRIS, "chapeau": "marin", "chapeau_c": [0.12, 0.16, 0.3], "haut": [0.14, 0.2, 0.36], "vieux": true, "carrure": 1.2},
			"teinte": PEAU[3],
			"mj": {"tenue": "marin", "objet": "canne"},
			"humeur_base": 0.2, "traits": {"bavard": 0.35, "humour": 0.6, "curiosite": 0.3, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"sardines_grillees": 2.5, "corde_chanvre": 2.0, "chocolat_chaud": 2.0, "dorade": 1.5, "toile_voile": 1.5, "bouillabaisse": 2.0}, "deteste": {"parapluie_helice": -1.0, "chapeau_ventilateur": -1.0},
			"tics": ["Hm.", "Mille sabords de laiton.", "De mon temps…", "Ça, c'est un bateau."],
			"surnoms": [[0, "moussaillon"], [25, "matelot"], [50, "mon gars"], [75, "mon second"], [95, "mon vieux frère de bord"]],
			"repliques": {
				"accueil": [
					L("Hm. Un nouveau. Léon Calfat, maître du Port des Cordages. Tu es arrivé avec le bateau de ligne ? Bon bateau. Mauvaise peinture. Pas ta faute. Bienvenue à Hautefond. Ne marche pas sur les cordages, ils ont mauvais caractère. Moi aussi.", {"visites_max": 1}),
					L("{surnom}. Hm. Tu reviens. C'est bien. La mer aime les gens qui reviennent. Moi aussi. Mais je ne le dirai qu'une fois.", {"visites_min": 2}),
				],
				"humeur": [
					L("Ça va. Douze bateaux sont entrés, douze sont sortis. Personne n'est tombé à l'eau. Si : une caisse de pommes de Rosalie. Les mouettes ont été très contentes.", {}, "rire"),
					L("Bof. Il y a trop de dirigeables, ces temps-ci. Un bateau, ça flotte. Un dirigeable, ça flotte aussi, mais en l'air. Ce n'est pas naturel. Ne le dis pas à Héloïse, elle rirait.", {}),
					L("Le soir, je m'assois sur le banc du port et je regarde les bateaux dormir. Ils se balancent tous ensemble. Comme de vieux amis qui ronflent.", {"soir": true}),
				],
				"lui": [
					L("J'ai navigué cinquante ans. Sur des goélettes, des trois-mâts, des chalutiers, un radeau, une fois. Le radeau, c'était involontaire. On n'en parle pas.", {}),
					L("On m'appelle bourru. C'est faux. Je suis précis. Je dis « hm » quand ça va, « hmm » quand ça ne va pas, et « hmmm » quand Héloïse passe en dirigeable au-dessus de mon port. Tout le monde comprend.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Chaque matin, je prends ma barque et j'apporte du pain frais à Margot, au Phare. Elle ne me dit jamais merci. Elle me donne une mouette à saluer. C'est mieux. Ne le répète pas, on me croirait gentil.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Port des Cordages, au nord-est. On l'appelle comme ça à cause des cordes : il y en a partout. Pour les bateaux, pour les filets, pour les grues. Dame Ysolde a acheté sa première corde ici. Je la garde dans la capitainerie. Elle est très vieille, très courte, et très importante.", {}),
					L("Le Dôme d'Azur… Les jeunes disent que c'est une ville sous la mer, avec des rues en verre. De mon temps, sous la mer, il y avait des poissons. Maintenant, il y a des gens. Les poissons doivent être surpris. La ligne rouvre bientôt, paraît-il. On verra si elle mouille.", {"sujet_min": ["ile", 1]}),
					L("Les Arches de pierre, au sud-ouest, sous les falaises… Quand j'étais mousse, on passait dessous en barque, à marée haute, en retenant notre souffle. Pour la chance. Je le fais encore. J'ai beaucoup de chance. Et un très bon souffle.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Héloïse dit que les bateaux, ce sont des dirigeables qui ont oublié de monter. Pff. Je lui ai dit que les dirigeables, ce sont des bateaux qui ont perdu la mer. On se dispute depuis dix ans. Hm. C'est ma meilleure amie. Ne le lui dis pas.", {}),
					L("Margot, au Phare, a donné un nom à chaque mouette de l'île. J'ai essayé d'en retenir trois. Il y avait une Hortense, un Firmin… Firmin, c'est aussi le nom du tavernier. Il n'a pas l'air de le savoir. Je ne vais pas le lui dire.", {}, "rire"),
					L("Le Père Bastien et moi, on joue aux cartes le dimanche. Il parle à ses cartes comme à ses arbres. « Allez, ma petite dame de cœur, pousse. » Il gagne. Je ne comprends pas comment.", {}, "rire"),
				],
				"interpelle": [L("Hm. Toi. Attention aux cordages.", {"visites_max": 0}), L("{surnom}. Hm. Belle mer.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Hm. Bon vent, {surnom}. Et bonne mer.", {}, "salut"), L("Va. Et si tu prends un bateau, dis-lui bonjour de ma part. Il comprendra.", {}), L("Bonne nuit. Les bateaux dorment. Moi aussi, bientôt. Hm.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Hm. Je me souviens de tous ceux qui sont descendus du bateau de ligne. Toi, tu as dit merci au capitaine. Ça, c'est rare.", {})],
			}},
		{"id": "margot_hf", "nom": "Margot", "titre": "gardienne du Phare de la Pointe", "maison": "porte_margot", "village": "hautefond",
			"agenda": [[6, 10, "phare_rochers"], [10, 17, "phare_porte"], [17, 20, "phare_rochers"], [20, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "tresse", "yeux": Y_BLEU, "haut": [0.85, 0.82, 0.75], "foulard": [0.2, 0.35, 0.6], "taille": 0.96},
			"teinte": PEAU[1],
			"mj": {"tenue": "marin", "objet": "lanterne"},
			"humeur_base": 0.35, "traits": {"bavard": 0.3, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"sardine": 2.5, "coquillage": 2.0, "etoile_mer": 2.0, "pain_miel": 1.5, "the_menthe": 1.5, "perle": 2.0}, "deteste": {"sifflet_muet": -1.0, "canard_mecanique": -0.5},
			"tics": ["Hein, Hortense ?", "Les mouettes le savent.", "Chut, elles écoutent.", "Bonne mer."],
			"surnoms": [[0, "promeneur"], [25, "visiteur du Phare"], [50, "ami des mouettes"], [75, "presque une mouette"], [95, "ma mouette préférée"]],
			"repliques": {
				"accueil": [
					L("… Oh. Un visiteur. Bonjour. Je suis Margot, la gardienne du Phare. Et voici Hortense, Basile, Colette, et le petit, là-bas, c'est Firmin. Ce sont des mouettes. Dis bonjour. Non, à elles. Elles sont susceptibles.", {"visites_max": 1}, "salut"),
					L("{surnom}. Hortense t'a reconnu. Elle a fait « kia ». Ça veut dire « encore lui ». C'est un compliment, chez les mouettes.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Colette a pondu. Basile boude. Firmin a volé une sardine à Firmin. Le vrai, le tavernier, quand il est venu pêcher. Ils ont crié pareil. C'était très drôle.", {}, "rire"),
					L("Tranquille. Je ne parle pas beaucoup aux gens. Je parle surtout aux mouettes. Elles répondent moins, mais elles écoutent mieux.", {}),
					L("Le soir, j'allume la grande lampe. Elle tourne toute la nuit. Les bateaux la voient, les mouettes la voient, et le Professeur Lunette, là-haut, croit que c'est une étoile qui cligne. Je le laisse croire. Les gens heureux, on les laisse.", {"soir": true}),
				],
				"lui": [
					L("Je suis arrivée au Phare à dix-neuf ans, pour un remplacement d'une semaine. C'était il y a trente ans. Le gardien n'est jamais revenu. Il m'a écrit qu'il avait trouvé un phare plus calme. Je me demande lequel. Il n'y a pas plus calme qu'ici.", {}, "rire"),
					L("Chaque mouette a un nom, une histoire, un caractère. Hortense est la cheffe. Basile est poète. Colette est maman. Firmin est un voleur. Il y en a cent douze. Je les reconnais toutes. Les gens, j'ai plus de mal.", {"sujet_min": ["lui", 1]}),
					L("Les gens croient que je suis seule. Je ne suis jamais seule. J'ai cent douze mouettes, une lampe, la mer, et Léon qui m'apporte du pain chaque matin en grognant. C'est beaucoup de compagnie, pour quelqu'un qui n'aime pas le bruit.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Phare de la Pointe guide les bateaux vers le Port des Cordages. Il y a des rochers partout, ici. Ma lampe leur dit : « Pas par là, par là. » Les bateaux obéissent. Les mouettes, jamais.", {}),
					L("D'ici, la nuit, je vois des lumières dans la mer, au large. C'est le Dôme d'Azur, sous l'eau. Parfois, une grande ombre passe devant : une baleine. Les mouettes deviennent toutes silencieuses. Même Firmin.", {"sujet_min": ["ile", 1]}),
					L("Les mouettes montent parfois jusqu'à la Cité des Nuées. Elles redescendent avec des miettes de gâteau tout blanc. Depuis que la ligne a rouvert, tout le monde monte voir. Ce sont des chouquettes, paraît-il. Hortense le savait déjà. Moi, je reste. Il faut bien que quelqu'un garde la lampe.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Léon fait le bourru. Mais chaque matin, il traverse la baie en barque pour m'apporter du pain. Il dit que c'est « en passant ». Le Phare n'est sur le chemin de rien. Hortense le sait. Hortense sait tout.", {}),
					L("Le Professeur Lunette m'a demandé d'éteindre le Phare une minute, pour vérifier son étoile. Je l'ai fait. Et elle a cligné quand même. Je lui ai dit que c'était une mouette. Je ne sais pas ce que c'était. Hortense non plus. Ça l'agace.", {}, "rire"),
					L("Augustin, le meunier, monte parfois jusqu'aux rochers pour lire ses poèmes au vent. Le vent les emporte. Les mouettes aussi. Basile en a gardé un dans son nid. Il le relit souvent. Enfin, il s'assoit dessus.", {}, "rire"),
				],
				"interpelle": [L("… Bonjour. Doucement, Colette couve.", {"visites_max": 0}), L("{surnom}. Hortense te dit bonjour.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Bonne mer. Même sur la terre.", {}, "salut"), L("Va. Et si une mouette te suit, c'est Firmin. Garde une main sur ton goûter.", {}, "rire"), L("Bonne nuit. Je monte allumer la lampe. Regarde-la tourner, ce soir. Elle tourne aussi pour toi.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Les mouettes se souviennent de toi. Donc moi aussi. On partage tout, ici.", {})],
			}},
		{"id": "augustin_hf", "nom": "Augustin Meule", "titre": "meunier du Moulin des Quatre Vents", "maison": "porte_augustin", "village": "hautefond",
			"agenda": [[6, 12, "moulin_champ"], [12, 14, "moulin_porte"], [14, 19, "moulin_champ"], [19, 21, "moulin_porte"], [21, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "long", "barbe": "courte", "yeux": Y_BLEU, "haut": [0.92, 0.9, 0.85], "tablier": [0.85, 0.82, 0.75], "taille": 1.08, "carrure": 1.0},
			"teinte": PEAU[1],
			"mj": {"tenue": "paysan", "chapeau": "bonnet"},
			"humeur_base": 0.5, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.6, "rancunier": 0.0},
			"aime": {"plume_vent": 2.5, "cerf_volant": 3.0, "pain_miel": 2.0, "graines": 1.5, "partition": 2.0, "bouquet_tournesols": 2.0}, "deteste": {"boite_a_rien": -1.0, "piment_infernal": -1.0},
			"tics": ["Ô vent…", "Écoute, il souffle.", "Ça rime ? Presque.", "La farine vole, et moi aussi."],
			"surnoms": [[0, "passant"], [25, "ami du vent"], [50, "frère de brise"], [75, "ma rime riche"], [95, "mon plus beau poème"]],
			"repliques": {
				"accueil": [
					L("« Ô voyageur, que le vent t'amène, sur la colline où tourne ma… » … ma… Bon, je n'ai pas de rime avec « amène ». Augustin Meule, meunier, et poète du vent. Bienvenue au Moulin des Quatre Vents. Attention à la farine : elle vole.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien : le vent vient de l'ouest, mon préféré. Il sent la mer et la pomme. J'ai fait un poème dessus. Il fait deux vers. Le vent a emporté le troisième.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Merveilleuse ! Le vent a soufflé des quatre côtés aujourd'hui. Le moulin a tourné dans tous les sens. La farine est un peu étourdie, mais elle est excellente.", {}, "rire"),
					L("Un peu mélancolique. Pas de vent depuis ce matin. Les ailes du moulin ne bougent pas. J'ai soufflé dessus. Ça ne marche pas. J'ai récité un poème. Ça ne marche pas non plus. Mais c'était joli.", {}),
					L("Le soir, je m'assois devant la porte du moulin et j'écoute le vent tomber. Il chuchote, à cette heure-là. Comme Mademoiselle Philippine. … Pourquoi je dis ça ? Pour rien.", {"soir": true}),
				],
				"lui": [
					L("Je suis né un jour de grand vent. Ma mère dit que mon premier cri est parti tout seul vers la mer. Depuis, je cherche les mots que le vent m'a pris. J'en retrouve un de temps en temps. Dans un sac de farine.", {}),
					L("Le moulin a quatre ailes, une pour chaque vent. Le Nord, c'est le grognon. L'Est, c'est le timide. Le Sud, c'est le paresseux. L'Ouest, c'est le poète. Comme moi. Il fait des courants d'air très sentimentaux.", {"sujet_min": ["lui", 1]}, "rire"),
					L("J'écris un poème par semaine pour la Bibliothèque des Cartes. Pour la Bibliothèque. Pas pour quelqu'un en particulier. Pour… les cartes. Elles aiment la poésie. Tout le monde sait ça. Ne regarde pas mes oreilles, elles rougissent toutes seules.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Moulin des Quatre Vents est sur la colline de l'ouest. D'ici, on voit toute Hautefond en étages, la Colonne qui brille, et les Vergers au sud. Toute la farine de la ville vient d'ici. Tout le pain de Hautefond a un peu de poésie dedans.", {}),
					L("Là-haut, à la Cité des Nuées, le vent souffle sans jamais toucher terre. Un vent qui n'a jamais rencontré d'arbre ! La ligne a rouvert, et j'ai mon billet pour dimanche. J'irai l'écouter. Il doit parler une autre langue. Une langue toute neuve.", {"sujet_min": ["ile", 1]}),
					L("La Cascade des Falaises, au sud-ouest, fait un bruit de pluie qui ne finit jamais. Et sous les falaises, les Arches de pierre. Le vent y passe en sifflant comme dans une flûte. J'y vais pour accorder mes poèmes.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Gaspard l'horloger ne me pardonne pas d'avoir changé une aile du moulin un mardi. Il réglait sa montre dessus, paraît-il. Je lui ai écrit un poème d'excuse. Il l'a chronométré. Il a dit que c'était « quatre secondes trop long ».", {}, "rire"),
					L("Le Père Bastien m'apporte des pommes, je lui donne de la farine, et ensemble on fait des tartes. Il parle aux pommes pendant la cuisson. Moi, je leur récite des vers. Les tartes sont très cultivées.", {}, "rire"),
					L("La Capitaine Héloïse vole parfois si bas au-dessus du moulin que les ailes tournent toutes seules. Elle dit que c'est pour me dépanner les jours sans vent. Je crois que c'est pour me faire peur. Ça marche très bien dans les deux cas.", {}, "rire"),
				],
				"interpelle": [L("« Ô passant de la colline… » Bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Écoute ! Il souffle de l'ouest !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. « Que le vent te pousse, et la route soit douce. » Ah ! Ça rime ! Enfin !", {}, "rire"), L("Va, ami du vent. Et si tu trouves un mot qui s'est envolé, rapporte-le-moi.", {}, "salut"), L("Bonne nuit. Le vent se couche. Moi aussi. On fait ça ensemble depuis toujours.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Tu es dans un de mes poèmes. Le troisième vers. Celui que le vent n'a pas emporté.", {})],
			}},
		{"id": "bastien_hf", "nom": "Père Bastien Greffe", "titre": "jardinier des Vergers en terrasses", "maison": "porte_bastien", "village": "hautefond",
			"agenda": [[6, 11, "verger_1"], [11, 13, "verger_2"], [13, 18, "verger_1"], [18, 20, "verger_2"], [20, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_VERT, "chapeau": "paille", "haut": [0.4, 0.5, 0.3], "tablier": [0.45, 0.35, 0.22], "vieux": true, "taille": 0.9, "carrure": 1.05},
			"teinte": PEAU[2],
			"mj": {"tenue": "paysan", "objet": "panier"},
			"humeur_base": 0.6, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"graines": 2.5, "pomme": 1.5, "miel": 2.0, "eau_source": 2.5, "goutte_rosee": 2.0, "tarte_potiron": 2.0}, "deteste": {"hache": -2.0, "gelee_slime": -1.0},
			"tics": ["Allez, ma belle, pousse.", "Les arbres le savent.", "Doucement, doucement.", "Une pomme par jour…"],
			"surnoms": [[0, "jeune pousse"], [25, "petit bourgeon"], [50, "mon greffon"], [75, "ma belle branche"], [95, "mon plus bel arbre"]],
			"repliques": {
				"accueil": [
					L("Bonjour, jeune pousse. Père Bastien Greffe, jardinier des Vergers. Parle doucement, s'il te plaît : la petite reinette, là, vient de fleurir. Elle est très timide. Dis-lui qu'elle est jolie. … Voilà. Regarde comme elle est contente.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Les arbres t'ont reconnu. Si, si : les feuilles ont bougé. Ce n'est pas le vent. Enfin, un peu le vent. Mais surtout toi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bien ! Le vieux poirier du haut m'a donné sa première poire depuis trois ans. Je lui ai raconté l'histoire de Dame Ysolde pendant tout l'hiver. Il aime les histoires qui finissent en hauteur.", {}),
					L("Un peu soucieux. Le petit cerisier du coin boude. Je crois qu'il est jaloux du pommier d'à côté, que tout le monde prend en photo. Je lui ai fait un compliment par jour. Il commence à rosir.", {}, "rire"),
					L("Le soir, je fais le tour des terrasses et je dis bonne nuit à chaque arbre. Il y en a deux cent quarante. Je finis vers minuit. Les derniers dorment déjà.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis jardinier depuis soixante ans. J'ai planté la moitié de ces arbres. L'autre moitié, c'est mon père. Et le grand pommier tout en haut, on dit que c'est Dame Ysolde elle-même. Il porte encore des pommes. Petites, dures, et fières.", {}),
					L("On m'appelle « Père » Bastien, mais je n'ai pas d'enfants. Juste deux cent quarante arbres. Ils sont très sages. Ils ne répondent jamais, ils grandissent doucement, et ils me nourrissent quand je suis vieux. Que demander de plus ?", {"sujet_min": ["lui", 1]}),
					L("Je parle aux arbres, oui. Tout le monde rit un peu. Mais tu sais, quand on parle à quelqu'un tous les jours, même s'il ne répond pas, on apprend à écouter. Et un arbre, ça a beaucoup de choses à dire. Juste très lentement.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Vergers en terrasses, au sud de l'île, descendent jusqu'à la mer. Pommiers en haut, poiriers au milieu, cerisiers en bas. Les pommes finissent au marché, chez Rosalie, et dans les tartes d'Augustin. Et un peu dans le ventre des voleurs. Je ne leur en veux pas.", {}),
					L("On m'avait dit qu'à la Cité des Nuées, les arbres poussaient dans le vide. La ligne a rouvert, je suis monté leur parler. Ils ont de la terre, en vérité, et une jardinière, Flora, qui leur fait la conversation. Elle m'a donné une fraise grosse comme le poing.", {"sujet_min": ["ile", 1]}),
					L("Sous nos pieds, dans les Strates, il y a des jardins de champignons qui brillent dans le noir. Ysaé me l'a raconté. Des jardins sans soleil ! J'ai hâte de voir ça. La ligne a rouvert : je descends la semaine prochaine avec un panier de pommes. On fera des échanges.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Rosalie vient chercher mes pommes tous les mardis. Elle leur raconte les potins du marché pendant que je les cueille. Les pommes du mardi sont les plus sucrées. Je pense que c'est le potin.", {}, "rire"),
					L("Le vieux Léon et moi, on joue aux cartes le dimanche. Il perd tout le temps. Il dit que je triche en parlant aux cartes. Je ne triche pas. Je les encourage. Ce n'est pas pareil.", {}, "rire"),
					L("La petite Pimprenelle est venue planter un boulon, pour voir s'il pousserait un arbre à boulons. Je lui ai dit que ça ne marcherait pas. Puis je l'ai arrosé quand même. On ne sait jamais.", {}, "rire"),
				],
				"interpelle": [L("Doucement, jeune pousse ! La reinette dort.", {"visites_max": 0}), L("{surnom} ! Viens, les cerisiers ont une nouvelle !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et si tu croises un arbre triste, dis-lui un mot gentil. Il s'en souviendra pendant cent ans.", {}, "salut"), L("Va, petite branche. Une pomme par jour, et reviens me voir.", {}), L("Bonne nuit. Je dois encore dire bonne nuit à cent dix-sept arbres. Je vais faire vite. Enfin, à ma vitesse.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Je me souviens de tout ce qui pousse. Et toi, tu as poussé un peu depuis la dernière fois.", {})],
			}},
	]

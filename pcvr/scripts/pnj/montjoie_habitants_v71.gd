extends RefCounted
## V71 : les gens de Montjoie, la ville fortifiée des aventuriers, sur sa butte au milieu de
## l'Île de Montjoie. Une ville de départ comme on les aime : une Guilde, un tableau de quêtes,
## des slimes, des grenouilles géantes, des navets qui se sauvent… et des aventuriers maladroits
## au grand cœur.
##  - la Guilde des Aventuriers : Églantine la réceptionniste, Maître Hugues « Barbe-de-Fer », Mamie
##    Rissole la cuisinière, Bertrand le barde, et les aventuriers : Hilaire (rang F depuis douze ans),
##    Lison l'archère, Rodrigue l'épéiste (le rival autoproclamé du joueur) ; et les trois compagnons
##    qu'on peut recruter : Sœur Pétronille (soins, peureuse), Violette (foudre, qui la touche souvent
##    elle-même) et Sire Tancrède de Tournevent (chevalier vantard au grand cœur) ;
##  - le Château : le Baron Barthélemy (un chapeau différent chaque jour) et Aurore, son intendante ;
##  - le Temple de l'Aube : Père Clotaire, qui s'endort pendant ses sermons ;
##  - la Ville-Moyenne : Brunehaut la forgeronne et son fils Titouan, Madame Olga (magie), Aubin
##    (potions), Honorine la boulangère et sa fille Noisette, Ulric l'aubergiste de « La Grenouille
##    Repue », Colombe la couturière, Mélusine la crieuse (et sa cloche), Babette (fruits et légumes),
##    Monsieur Prosper (les maisons), Grand-mère Philomène la conteuse ;
##  - la garde : le Capitaine Ferdinand et Gilles, de la Porte Nord ;
##  - dehors : Père Gaubert et Germaine (la ferme, les navets), Clovis le meunier, Yvon le pêcheur du
##    lac, le Capitaine Isidore au Port des Mouettes, Odon, gardien du Donjon des Mille Marches.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd). Fiche « village » : montjoie (les lieux : voir la note V71).
## Fiche « mj » : tenue (aventurier | pretresse | mage | chevalier | archere | barde | noble |
## marchand | artisan | forgeron | garde | paysan | enfant | cuisinier | marin | savant), objet (epee |
## masse | baton | arc | luth | marteau | louche | plateau | cloche | lanterne | livre | canne | panier |
## filet | canne_peche | tampon, facultatif), chapeau (mage | plume | chaperon | bonnet | toque |
## casque, facultatif).
## Identifiant : « noisette_mj », car « noisette » (la fée des graines) existe déjà ; sa porte reste
## « porte_noisette ».

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bonne route, {surnom} ! Et méfie-toi des grenouilles : elles ont la langue plus longue que Mélusine.", "si": {}, "geste": "salut"},
		{"t": "À plus tard ! Si tu croises un navet qui court, ne lui dis pas où j'habite.", "si": {}, "geste": "rire"},
		{"t": "Va, aventurier ! Et reviens entier. Ou au moins avec la plupart des morceaux.", "si": {}},
		{"t": "Bonne nuit ! Dors bien : les gardes veillent. Enfin… Gilles veille. À sa façon.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Je ne suis pas un slime, moi ! Les monstres, c'est dehors, derrière les remparts !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu veux que j'appelle le Capitaine Ferdinand ? Il a déjà assez de travail avec les navets !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? C'est gentil. Je vais lui trouver une petite place sur l'étagère.", "si": {}},
		{"t": "Merci, {surnom}. À Montjoie, on dit qu'un cadeau, c'est une aventure qui finit bien.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par l'Aube, tu as tapé en plein dans le mille, {surnom} !", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau de héros ! Merci, {surnom}. Je vais le raconter à toute la Grand-Place.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… Je vais le donner à Madame Olga. Elle achète n'importe quoi.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Dehors, entre les slimes et les gobelins, tu en auras bien plus besoin que moi.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Ici, on n'oublie pas les aventuriers. Églantine a même une fiche sur toi.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Tu confonds avec le tableau de la Guilde : lui, il demande tout le temps.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les slimes ne jouent jamais aux cartes ? Parce qu'ils ont toujours les mains qui collent ! … Enfin, ils n'ont pas de mains. C'est pour ça qu'ils perdent.", "si": {}, "geste": "rire"},
		{"t": "Un aventurier entre à la Guilde : « Je voudrais une quête facile. » Églantine tamponne sa fiche : « Hilaire vous la laisse, il la rate depuis douze ans. »", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on un navet qui court plus vite que tout le monde ? Un navet-dette ! … Parce qu'il file. Bon. C'est une blague de Père Gaubert.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'une grenouille géante dit à un aventurier ? Rien : elle a la bouche pleine !", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, et prends ce qu'il te faut pour l'aventure. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand je serai calmé.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Bonne aventure !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Va donc voir le tableau de la Guilde : il y a toujours des slimes à chasser.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Un aventurier, ça voyage léger. Enfin, en théorie.", "si": {}}],
	"achat_plein": [{"t": "Ton sac déborde, {surnom}. Même Sire Tancrède n'arriverait pas à le porter. Il essaierait quand même.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et une tape dans le dos en prime !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu as une tête d'aventurier honnête. Un petit geste. Ne le dis pas à Églantine, elle le noterait.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont déjà plus doux qu'un slime au soleil. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. J'ai une mémoire de réceptionniste.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par l'Aube !", "Hourra !", "Ha ha !", "Quelle aventure !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Misère…", "Pff…", "Aïe aïe aïe…"],
		"colere": ["Par la barbe de Maître Hugues !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Foi de Montjoie.", "Comme on dit à la Guilde.", "Ça, c'est de l'aventure !", "Attention aux navets."],
	"humeur_mots": [[0.6, "aux anges"], [0.25, "de bonne humeur"], [-0.25, "un peu ronchon"], [-0.6, "grognon"], [-2.0, "furieux comme un navet"]],
	"surnoms": [[0, "petit nouveau"], [25, "aventurier"], [50, "mon compagnon"], [75, "mon héros"], [95, "légende de Montjoie"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.68, 0.32]
const BLOND_PALE := [0.92, 0.84, 0.6]
const ROUX := [0.82, 0.3, 0.1]
const ROSE := [0.94, 0.68, 0.74]
const ARGENT := [0.82, 0.82, 0.86]
const VIOLET := [0.3, 0.15, 0.4]
const BLEU_NUIT := [0.12, 0.15, 0.34]
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
	out["groupe"] = "montjoie"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Guilde des Aventuriers
		{"id": "eglantine", "nom": "Églantine", "titre": "réceptionniste de la Guilde", "maison": "porte_eglantine", "village": "montjoie", "vouvoie": true,
			"agenda": [[7, 12, "guilde_comptoir"], [12, 13, "guilde_table_1"], [13, 19, "guilde_comptoir"], [19, 21, "place_banc_1"], [21, 7, "maison"]],
			"azur": {"cheveux": ROSE, "coiffure": "chignon", "yeux": Y_VERT, "haut": [0.2, 0.3, 0.55], "robe": [0.2, 0.3, 0.55], "robe_longue": true},
			"teinte": PEAU[0],
			"mj": {"tenue": "noble", "objet": "tampon"},
			"humeur_base": 0.45, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"the_menthe": 2.0, "croissant": 1.5, "pain_montjoie": 1.5, "clochette_argent": 2.0, "carte_postale": 1.5}, "deteste": {"gelee_slime": -1.5, "vieille_botte": -1.5},
			"tics": ["Je note.", "Tampon !", "Dans l'ordre, s'il vous plaît.", "C'est sur la fiche."],
			"surnoms": [[0, "cher candidat"], [25, "cher aventurier"], [50, "aventurier modèle"], [75, "notre fierté"], [95, "légende de la Guilde"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à la Guilde des Aventuriers de Montjoie ! Je suis Églantine, réceptionniste. Inscription, contrats, réclamations, objets trouvés, pleurs de Maître Hugues : tout passe par ce comptoir. Vous souhaitez vous inscrire ? Ce n'est que dix pièces, et une petite boule de cristal qui ne mord presque pas.", {"visites_max": 1, "q56": "mj_inscription="}, "salut"),
					L("{surnom} ! Votre fiche est à jour, votre carte est tamponnée, et votre sourire est… réglementaire. Que puis-je pour vous ? Un contrat ? Le tableau est juste derrière vous. Il ne bouge pas. Contrairement aux navets.", {"visites_min": 2, "q56": "mj_inscription=finie"}),
					L("Vous revoilà ! Toujours pas inscrit ? Je garde votre formulaire au chaud. Je l'ai même rempli à moitié. Par habitude. Et par impatience.", {"visites_min": 2, "q56": "mj_inscription="}, "rire"),
				],
				"humeur": [
					L("Excellente ! J'ai classé trois cents fiches ce matin, par rang, par ordre alphabétique et par nombre de fois où l'aventurier s'est fait avaler par une grenouille. Hilaire a une colonne à lui tout seul.", {}, "rire"),
					L("Le Roi Gélatineux est vaincu, les puits ne gargouillent plus, et la fontaine ne fait plus de bulles vertes. J'ai enfin pu ranger le formulaire « Plainte pour slime dans la soupe ». Il était très épais.", {"a_trouve": "roi_gelatineux"}, "rire"),
					L("Le soir, je m'assois sur un banc de la Grand-Place et je ne tamponne rien. Rien du tout. C'est très difficile. Ma main bouge toute seule.", {"soir": true}),
				],
				"lui": [
					L("J'ai été engagée à la Guilde à seize ans, pour ranger un seul tiroir. Il contenait quarante ans de papiers, deux sandwichs fossiles et une épée. J'ai tout classé en une semaine. Maître Hugues a pleuré. Il m'a confié la Guilde entière. Enfin, le comptoir. C'est pareil.", {}),
					L("Mon tampon s'appelle Clac. Oui, il a un nom. Il a tamponné toutes les cartes d'aventurier de Montjoie depuis huit ans. Il est un peu usé sur le côté gauche, parce que je tamponne avec enthousiasme.", {"sujet_min": ["lui", 1]}, "rire"),
					L("On croit que je souris tout le temps parce que c'est mon métier. C'est vrai. Mais parfois, quand quelqu'un revient du donjon entier, je souris pour de vrai. Ça se voit à peine. C'est fait exprès.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Montjoie est bâtie en terrasses, sur la Butte : la Basse-Ville derrière les remparts, la Ville-Moyenne avec la Grand-Place et la Guilde, la Haute-Ville avec le Temple de l'Aube, et tout en haut, le Château du Baron. Les rues montent en lacets. Ça forge les mollets des aventuriers.", {}),
					L("Les rangs vont de F à S. F, c'est le début : slimes et grenouilles. S, c'est la légende : Maître Hugues, autrefois. Entre les deux, il y a beaucoup de contrats, beaucoup de bosses, et beaucoup de tampons.", {"sujet_min": ["ile", 1]}),
					L("Au pied des Crocs, au sud-ouest, s'ouvre le Donjon des Mille Marches. Il n'y en a pas mille, je les ai fait compter : il y en a neuf cent quatre-vingt-sept. Mais « le Donjon des Neuf Cent Quatre-Vingt-Sept Marches », ça ne tenait pas sur l'enseigne.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Rodrigue est venu contester sa lecture de la boule de cristal. Pour la neuvième fois. La boule a dit « courage : beaucoup ; prudence : euh… ». Il trouve que le « euh » est vexant. Je l'ai noté.", {}, "rire"),
					L("Mélusine m'a demandé d'écrire ses annonces d'alerte. J'ai écrit « Navets en fuite, Champs du Sud, prière de se presser calmement ». Elle a crié : « ALERTE ! TOUT LE MONDE COURT ! ». C'est presque pareil.", {}, "rire"),
					L("Maître Hugues signe tout ce que je pose devant lui sans le lire. Un jour, je lui ai fait signer une promesse de manger moins de tourte. Il l'a signée. Il ne la respecte pas, mais elle est classée.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Oui, vous ! Vous avez l'air d'un aventurier non inscrit !", {"visites_max": 0}), L("{surnom} ! Un nouveau contrat vous attend au tableau !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bonne aventure, {surnom}. Revenez entier : les fiches de blessés sont très longues à remplir.", {}, "salut"), L("À bientôt ! Et n'oubliez pas : un contrat accepté est un contrat rendu.", {}), L("Bonne soirée. La Guilde ferme, mais le comptoir veille. Enfin, Clac veille.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de vous ? Vous avez une fiche, {surnom}. Tout le monde a une fiche. Même le chat de la Guilde.", {})],
			}},
		{"id": "hugues", "nom": "Maître Hugues", "titre": "maître de la Guilde, dit « Barbe-de-Fer »", "maison": "porte_hugues", "village": "montjoie",
			"agenda": [[8, 12, "guilde_maitre"], [12, 14, "guilde_table_2"], [14, 18, "guilde_maitre"], [18, 22, "guilde_table_1"], [22, 8, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "longue", "yeux": Y_GRIS, "haut": [0.38, 0.26, 0.16], "vieux": true, "taille": 1.14, "carrure": 1.35},
			"teinte": PEAU[2],
			"mj": {"tenue": "aventurier", "objet": "epee"},
			"humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"tourte_montjoie": 2.5, "cidre_montjoie": 1.5, "viande_cerf": 2.0, "ragout_nain": 2.0, "coeur_gelee": 2.0}, "deteste": {"gelee_slime": -1.0, "tisane_lune": -1.0},
			"tics": ["Par ma barbe !", "De mon temps…", "Ha ! Ha ! Ha !", "Snif."],
			"surnoms": [[0, "gamin"], [25, "jeune pousse"], [50, "mon brave"], [75, "mon héritier"], [95, "rang S de mon cœur"]],
			"repliques": {
				"accueil": [
					L("HA ! Un nouveau ! Approche, gamin, approche ! Hugues, maître de la Guilde. On m'appelle Barbe-de-Fer. Pourquoi ? Assieds-toi, je vais te raconter. C'était il y a quarante ans, dans les montagnes, un dragon grand comme… Bon, Églantine me fait les gros yeux. Une autre fois.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu tombes bien ! Je t'ai déjà raconté mon dragon ? … Oui ? Tant mieux, tu connais la fin. Elle est très belle. Je pleure à chaque fois.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Le Roi Gélatineux ! Vaincu ! Par toi ! (Il se mouche dans sa barbe.) Pardon. Je suis ému. Je suis toujours ému. Mais là, je suis très ému.", {"a_trouve": "roi_gelatineux"}),
					L("En pleine forme ! Mamie Rissole m'a fait une tourte de deux kilos. J'en ai mangé la moitié, et elle m'a regardé jusqu'à ce que je finisse l'autre.", {}, "rire"),
					L("Le soir, je m'installe à une table de la taverne et je regarde les jeunes rentrer de mission, couverts de gelée. Ça me rappelle ma jeunesse. J'étais couvert de gelée, moi aussi. Tout le temps.", {"soir": true}),
				],
				"lui": [
					L("J'ai été rang S. Le seul de Montjoie. J'ai vaincu des trolls, des hydres, et un dragon. Le dragon, c'est ma plus belle histoire. Il était énorme. Enfin… Philomène dit qu'il était grand comme une chèvre. Philomène n'y était pas. Moi, j'y étais. Il était énorme.", {}),
					L("Ma barbe, je la tresse moi-même chaque matin. Trois tresses : une pour le courage, une pour l'amitié, une pour la tourte. Odon dit qu'il en faudrait une quatrième pour la modestie. Odon n'a pas de barbe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je pleure aux mariages, aux baptêmes, aux montées de rang, et quand Bertrand chante. Un maître de Guilde qui pleure, ce n'est pas très sérieux. Mais un maître de Guilde qui ne pleure jamais, je n'en voudrais pas.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Guilde, c'est le cœur de Montjoie, au milieu de la Ville-Moyenne, au bord de la Grand-Place. Le comptoir d'Églantine, le tableau des quêtes, la taverne de Mamie Rissole, la scène de Bertrand. On y entre débutant, on en sort héros. Ou couvert de gelée. Souvent les deux.", {}),
					L("Du slime remonte dans les puits et dans la fontaine de la place. Ça vient d'en bas, du Donjon des Mille Marches, au pied des Crocs. Cinq étages. Tout au fond, il y a un Roi Gélatineux. Pas un vrai roi. Mais il a une couronne, et il se prend très au sérieux.", {"sujet_min": ["ile", 1]}),
					L("Le Roi Gélatineux se coupe en petits morceaux quand on le frappe trop fort. Des petits slimes partout ! Il faut les taper un par un, sans paniquer. Surtout sans paniquer. La dernière fois que j'ai paniqué, c'était il y a trente ans. Odon s'en souvient encore.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Sire Tancrède m'a raconté qu'il avait vaincu un géant à mains nues. Je lui ai demandé où. Il a dit : « Loin. Très loin. Dans le brouillard. » Ha ! Il me plaît, ce garçon. Il me rappelle moi, en plus blond.", {}, "rire"),
					L("Hilaire est rang F depuis douze ans. Douze ans ! Je l'ai vu rater des contrats que même un enfant réussirait. Mais je ne l'ai jamais vu abandonner. C'est ça, un aventurier.", {}),
				],
				"interpelle": [L("Hé, gamin ! Viens par ici !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens, j'ai une histoire !", {"visites_min": 1}, "rire")],
			}},
		{"id": "rissole", "nom": "Mamie Rissole", "titre": "cuisinière de la taverne de la Guilde", "maison": "porte_rissole", "village": "montjoie",
			"agenda": [[6, 9, "guilde_bar"], [9, 10, "marche_flane_1"], [10, 21, "guilde_bar"], [21, 22, "place_banc_2"], [22, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.6, 0.3, 0.28], "tablier": [0.95, 0.92, 0.85], "vieux": true, "taille": 0.86, "carrure": 1.25},
			"teinte": PEAU[1],
			"mj": {"tenue": "cuisinier", "objet": "louche", "chapeau": "bonnet"},
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"miel": 2.0, "cuisse_grenouille": 1.5, "champignon": 1.5, "pomme": 1.5, "graines": 1.0}, "deteste": {"gelee_slime": -1.5, "glace": -0.5},
			"boutique": {"vend": {"tourte_montjoie": 6, "jus_pomme": 3}, "achete": {"cuisse_grenouille": 3, "pomme": 1, "miel": 4, "champignon": 2}},
			"tics": ["Mange !", "Tu as maigri.", "Encore une part ?", "Ressers-toi."],
			"surnoms": [[0, "mon petit"], [25, "mon poussin"], [50, "mon lapin"], [75, "mon trésor"], [95, "mon petit-fils de cœur"]],
			"repliques": {
				"accueil": [
					L("Assieds-toi. Non, ne discute pas. Assieds-toi. Mamie Rissole, la cuisinière de la Guilde. Tu as une mine de navet oublié. Tiens, une part de tourte. Et une autre, pour le chemin. Et une troisième, parce que deux, ça fait triste.", {"visites_max": 1}),
					L("{surnom} ! Tu as maigri ! Tu as maigri depuis ce matin, je le vois ! Viens ici, j'ai gardé une part.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien, bien. J'ai nourri quarante aventuriers, un baron et un garde qui dormait. Le garde a mangé en dormant. C'est un talent.", {}, "rire"),
					L("Le soir, quand la taverne se vide, je m'assois un moment sur la place. Mes pieds me remercient. Ma louche, elle, s'ennuie.", {"soir": true}),
				],
				"lui": [
					L("J'ai été aventurière, tu sais. Une seule journée. J'ai assommé un gobelin avec ma louche, et ensuite je lui ai fait à manger, parce qu'il avait l'air affamé. On m'a dit que ce n'était pas le principe. Alors j'ai ouvert une cuisine.", {}, "rire"),
					L("Hugues, je le nourris depuis qu'il avait quinze ans et des genoux pointus. Aujourd'hui, c'est le plus grand aventurier de Montjoie. Tu crois que c'est grâce à quoi ? À mes tourtes. Il le sait. Il a peur de ma louche.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ma louche s'appelle Gertrude. Elle a plus d'expérience que la moitié des aventuriers inscrits. Elle a même vaincu un slime qui était entré dans la marmite. Il était là pour la soupe. Il est reparti dans le seau.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Ma taverne est au fond de la Guilde, à droite du comptoir d'Églantine. Le jour, on y mange. Le soir, on y mange aussi, mais avec la musique de Bertrand. Il faut bien manger pour supporter Bertrand.", {}, "rire"),
					L("Ulric, à La Grenouille Repue, cuisine la grenouille de vingt façons. Moi, j'ai une seule recette de tourte, mais je la fais parfaitement. Une bonne chose bien faite vaut mieux que vingt choses gluantes.", {"sujet_min": ["ile", 1]}),
					L("Si tu descends au Donjon des Mille Marches, prends des tourtes. Au fond, un aventurier qui a faim, c'est un aventurier qui pleure. J'en ai vu remonter en larmes, et ce n'était pas à cause des monstres.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Sire Tancrède mange comme quatre. Comme quatre ! Je l'adore. C'est le seul qui finit son assiette avant que je dise « mange ».", {}, "rire"),
					L("Ulric raconte que sa grenouille en croûte est meilleure que ma tourte. Qu'il vienne le dire devant Gertrude.", {}),
				],
				"interpelle": [L("Toi ! Tu as mangé ?", {"visites_max": 0}), L("{surnom} ! Viens manger !", {"visites_min": 1}, "salut")],
				"boutique": [L("Tu veux acheter ? Bon. Mais je te mets une part en plus, et tu ne discutes pas. Tu as {pieces} pièces.", {})],
			}},
		{"id": "petronille", "nom": "Sœur Pétronille", "titre": "prêtresse du Temple de l'Aube", "maison": "porte_petronille", "village": "montjoie", "vouvoie": true,
			"agenda": [[6, 9, "temple_banc_1"], [9, 12, "temple_parvis"], [12, 17, ["guilde_table_4", "guilde_tableau"]], [17, 19, "temple_banc_1"], [19, 21, "place_fontaine"], [21, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "long", "yeux": Y_BLEU, "haut": [0.97, 0.95, 0.9], "robe": [0.97, 0.95, 0.9], "robe_longue": true, "taille": 0.96},
			"teinte": PEAU[0],
			"mj": {"tenue": "pretresse", "objet": "masse"},
			"humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.5, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.05},
			"aime": {"chapelet_soleil": 3.0, "pain_montjoie": 1.5, "jus_pomme": 1.5, "gateau_miel": 2.0, "fleur_lune": 1.5}, "deteste": {"cuisse_grenouille": -2.0, "gelee_slime": -1.5},
			"tics": ["Ô Aube…", "Pardon ! Pardon !", "Je n'ai pas peur. Si.", "Que la lumière vous garde."],
			"surnoms": [[0, "cher voyageur"], [25, "cher aventurier"], [50, "cher compagnon"], [75, "mon protecteur"], [95, "lumière de mon chemin"]],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour ! Je… je suis Sœur Pétronille, du Temple de l'Aube. Je soigne les aventuriers. Très bien, d'ailleurs. C'est le reste qui… (Elle trébuche sur rien.) … Voilà. C'est le reste.", {"visites_max": 1}, "salut"),
					L("Vous êtes revenu ! Avec mon chapelet ! Ô Aube… Je vous suivrai. Partout. Enfin, presque partout. Pas dans le ventre des grenouilles, si possible.", {"q56": "mj_petronille=finie", "visites_min": 2}, "rire"),
					L("{surnom} ! Vous n'êtes pas blessé ? Montrez-moi. Non ? Tant mieux. Enfin, tant pis. Enfin… tant mieux !", {"visites_min": 2}),
				],
				"humeur": [
					L("Une grenouille géante a avalé mon chapelet du soleil. Mon chapelet ! Il était dans ma main, et puis… slurp. Je prie très fort. Mais elle ne le rend pas.", {"q56": "mj_petronille="}),
					L("Bien, merci ! Je ne suis tombée que deux fois aujourd'hui. Dont une dans l'escalier du temple. Mais c'était un escalier très glissant. Et sec. Mais glissant.", {}, "rire"),
					L("La nuit, j'ai un peu peur. Je prie. Si quelque chose fait « crac », je prie plus fort. Si ça fait « slurp », je cours.", {"soir": true}),
				],
				"lui": [
					L("Je suis entrée au Temple de l'Aube à dix ans, parce que j'avais peur du noir, et que le temple est toujours éclairé. Père Clotaire m'a appris les prières de soin. Je les ai apprises très vite. Mes jambes, elles, n'ont jamais appris à marcher droit.", {}),
					L("Mes soins sont parmi les meilleurs de l'île. Père Clotaire le dit. Le problème, c'est qu'il faut s'approcher des blessés, et les blessés sont souvent près des monstres. Alors je ferme les yeux et je soigne au hasard. Ça marche très bien. Sauf pour les monstres.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Quand j'ai très peur, je prie à voix haute. Très haute. Mélusine m'a dit un jour que j'avais une voix de crieuse. J'étais si fière que j'ai trébuché.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Temple de l'Aube est dans la Haute-Ville, au-dessus de la Grand-Place. Ses vitraux s'allument au lever du soleil. On dit que l'Aube protège les débutants. Elle a beaucoup de travail, à Montjoie.", {}),
					L("Le Lac des Grenouilles, à l'est de la ville, derrière la Porte de l'Est… Les grenouilles y sont grandes comme des charrettes. Elles avalent tout ce qui brille. Et tout ce qui crie. Moi, je brille et je crie.", {"sujet_min": ["ile", 1]}),
					L("Si une grenouille vous avale, ne paniquez pas : elles recrachent toujours. Au bout de trois secondes, à peu près. Ce sont les trois secondes les plus longues de votre vie. Et après, il faut se laver. Beaucoup.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Violette dit que c'est elle la plus maladroite de la Guilde. Elle s'est foudroyée trois fois cette semaine. Moi, je suis tombée sept fois. Je ne sais pas qui gagne. Ce n'est peut-être pas un concours.", {}, "rire"),
					L("Sire Tancrède veut toujours me protéger. C'est gentil. Mais d'habitude, c'est moi qui le soigne, parce qu'il s'est pris les pieds dans sa cape.", {}, "rire"),
				],
				"interpelle": [L("Oh ! Bonjour ! … Pardon, je vous ai fait peur ? Non, c'est moi qui ai eu peur.", {"visites_max": 0}), L("{surnom} ! Que l'Aube vous garde !", {"visites_min": 1}, "salut")],
			}},
		{"id": "violette", "nom": "Violette", "titre": "mage de la foudre", "maison": "porte_violette", "village": "montjoie", "vouvoie": true,
			"agenda": [[8, 12, "guilde_table_5"], [12, 13, "haute_banc"], [13, 16, "haute_belvedere"], [16, 20, "guilde_table_5"], [20, 23, "haute_banc"], [23, 8, "maison"]],
			"azur": {"cheveux": VIOLET, "coiffure": "long", "yeux": Y_VIOLET, "haut": BLEU_NUIT, "robe": BLEU_NUIT, "robe_longue": true, "taille": 0.9},
			"teinte": PEAU[6],
			"mj": {"tenue": "mage", "objet": "baton", "chapeau": "mage"},
			"humeur_base": 0.2, "traits": {"bavard": 0.3, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.6, "rancunier": 0.05},
			"aime": {"cristal_orage": 3.0, "grimoire": 2.5, "page_grimoire": 2.0, "eclat_cristal": 1.5, "tisane_lune": 1.5, "gateau_miel": 1.0}, "deteste": {"minerai_fer": -1.5, "vieille_botte": -1.0},
			"tics": ["… ça arrive.", "Pardon.", "Bzzt.", "D'après le livre…"],
			"surnoms": [[0, "monsieur ou madame"], [25, "cher aventurier"], [50, "cher compagnon"], [75, "mon ami précieux"], [95, "mon paratonnerre"]],
			"repliques": {
				"accueil": [
					L("Oh. Bonjour. (Elle referme son livre ; une petite étincelle lui saute au nez.) … Ça arrive. Je suis Violette. Mage. De la foudre. Seulement de la foudre. J'ai essayé le feu, une fois. C'était de la foudre aussi.", {"visites_max": 1}),
					L("Les trois cristaux d'orage… Ils chantent. Vous les entendez ? Bzzzz. Avec eux, ma foudre ira là où je la vise. Enfin, plus souvent. Je viens avec vous, si vous voulez bien.", {"q56": "mj_violette=finie", "visites_min": 2}),
					L("{surnom}. Bonjour. J'ai lu un chapitre de plus. Je suis prête. (Ses cheveux se dressent tout seuls.) … Presque prête.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Je ne me suis foudroyée qu'une fois aujourd'hui. Un record. Je l'ai écrit dans mon carnet. Ensuite, mon carnet a pris feu. Un peu.", {}, "rire"),
					L("Le soir, je lis sur le banc de la Haute-Ville. Quand il y a de l'orage, je n'ose pas : mes cheveux attirent les éclairs. Je lis sous mon chapeau.", {"soir": true}),
				],
				"lui": [
					L("Je suis née pendant un orage. La sage-femme dit que j'ai fait une petite étincelle en éternuant. Ma mère dit que c'était une coïncidence. Mes cheveux disent le contraire.", {}),
					L("J'ai étudié tous les sorts : le feu, la glace, la lumière, les fleurs. À chaque fois, c'est de la foudre qui sort. Mon professeur a fini par me dire : « Violette, tu es une mage de la foudre. Point. » Puis il s'est foudroyé. C'était moi, pardon.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Quand l'éclair me touche, je fais semblant que ça ne fait rien. « … ça arrive. » C'est vrai, ça arrive. Mais j'aimerais tellement qu'un jour, il arrive seulement aux monstres.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Crocs, au sud-ouest, sont des collines de roche pointue. Au sommet poussent des cristaux d'orage. Ils attirent la foudre. Moi aussi. Je n'y monte pas seule : on finirait par se battre pour les éclairs.", {}),
					L("D'après le livre de Madame Olga, un cristal d'orage canalise la foudre « vers l'avant ». Pas vers le chapeau, pas vers les cheveux. Vers l'avant. Il m'en faudrait trois. Au sommet des Crocs.", {"sujet_min": ["ile", 1]}),
					L("Le belvédère de la Haute-Ville est mon endroit préféré. On voit tout : le lac à l'est, la forêt au nord-est, les Crocs au sud-ouest, la mer partout. Et pas une seule grenouille.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Sire Tancrède dit qu'il a « absorbé » mon éclair, la semaine dernière. Il fumait encore. Il a dit que c'était « une technique de chevalier ». J'ai fait semblant de le croire. C'était gentil de sa part.", {}, "rire"),
					L("Monsieur Aubin m'a fait une potion contre la foudre. Je suis restée bleue toute une journée. La foudre, elle, n'a pas remarqué la différence.", {}, "rire"),
				],
				"interpelle": [L("… Bonjour.", {"visites_max": 0}), L("{surnom}. Bonjour. Bzzt.", {"visites_min": 1})],
			}},
		{"id": "tancrede", "nom": "Sire Tancrède", "titre": "chevalier, Sire Tancrède de Tournevent", "maison": "porte_tancrede", "village": "montjoie", "vouvoie": true,
			"agenda": [[7, 9, "chateau_cour"], [9, 12, ["guilde_tableau", "place_fontaine"]], [12, 14, "guilde_table_3"], [14, 18, "rempart_1", ["porte_est", "chateau_rempart"]], [18, 22, "guilde_table_3"], [22, 7, "maison"]],
			"azur": {"cheveux": BLOND_PALE, "coiffure": "court", "yeux": Y_BLEU, "haut": [0.7, 0.72, 0.76], "taille": 1.1, "carrure": 1.2},
			"teinte": PEAU[1],
			"mj": {"tenue": "chevalier", "objet": "epee"},
			"humeur_base": 0.6, "traits": {"bavard": 0.95, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.05},
			"aime": {"banniere_gobelin": 3.0, "tourte_montjoie": 2.5, "viande_cerf": 2.0, "ragout_nain": 2.0, "pain_montjoie": 1.5, "cidre_montjoie": 1.0}, "deteste": {"tisane_lune": -1.0, "gelee_slime": -1.0},
			"tics": ["Moi, Sire Tancrède de Tournevent !", "Hardi !", "Foi de chevalier !", "C'était dans le brouillard."],
			"surnoms": [[0, "noble inconnu"], [25, "vaillant ami"], [50, "frère d'armes"], [75, "compagnon de légende"], [95, "presque aussi glorieux que moi"]],
			"repliques": {
				"accueil": [
					L("Halte ! Qui va là ? … Un aventurier ! Je me présente : MOI, SIRE TANCRÈDE DE TOURNEVENT ! Vainqueur du Géant des Brumes, du Serpent à Sept Queues et du Grand Ours de Givre ! … Dans le brouillard. Il y avait beaucoup de brouillard. Personne n'a rien vu. Mais c'était grandiose.", {"visites_max": 1}, "rire"),
					L("La bannière du chef gobelin ! Un VRAI exploit ! Avec des témoins ! Je vous suis, ami : désormais, nous écrirons la légende ensemble. Et sans brouillard.", {"q56": "mj_tancrede=finie", "visites_min": 2}),
					L("{surnom} ! Mon frère d'armes ! Savez-vous que ce matin, j'ai vaincu trois slimes avant le petit déjeuner ? Deux. Un. J'ai vu un slime. De loin. Il avait peur.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Magnifique ! J'ai mangé quatre parts de tourte. Mamie Rissole m'a regardé avec amour. Je crois que c'est la plus grande victoire de ma journée.", {}, "rire"),
					L("Tous mes exploits sont imaginaires, ami. Je le sais. Tout Montjoie le sait. Il me faut un vrai exploit. Le chef gobelin du Bois des Lutins… voilà un adversaire ! Mais seul, je… j'aurais besoin d'un témoin. Et d'un peu d'aide. Surtout d'aide.", {"q56": "mj_tancrede="}),
					L("Le soir, je raconte mes exploits à la taverne de la Guilde. Bertrand les met en chanson. Les chansons sont encore plus belles que les exploits. Et les exploits n'existaient déjà pas.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Les Tournevent sont une noble famille de chevaliers. Mon arrière-grand-père a sauvé un roi. Mon grand-père a sauvé une princesse. Mon père a sauvé un chat. Moi, je cherche encore quelqu'un à sauver. Je suis ouvert à toutes les propositions.", {}),
					L("Ma cape rouge est un cadeau de ma mère. Elle est un peu longue. Je me prends les pieds dedans une fois sur trois. Je ne la raccourcirai jamais : un chevalier ne renonce pas à sa cape. Même la tête dans l'herbe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais vous confier un secret : j'invente mes exploits parce que je n'en ai jamais eu de vrai. Mais quand un ami est en danger, je charge. Toujours. Sans réfléchir. C'est la seule chose de vraie chez moi. Et ma faim.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Bois des Lutins, au nord-est, est plein de gobelins. Ils ont un camp, au fond du bois, avec un chef et une bannière. Un chef ! Une bannière ! Voilà enfin un exploit digne de figurer dans une chanson. Une vraie.", {}),
					L("Le château du Baron couronne la Butte, tout en haut. Le matin, je m'entraîne dans sa cour. Le Baron applaudit depuis sa fenêtre, avec un chapeau différent chaque jour. Hier, c'était un chapeau en forme de poisson.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Donjon des Mille Marches… J'y suis descendu. Une fois. Jusqu'à la sixième marche. Il y avait un bruit. C'était mon ventre. Je suis remonté manger. Mais la prochaine fois, ami, nous irons jusqu'au Roi Gélatineux !", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Rodrigue prétend être votre rival. Votre rival ! Il ne sait pas que c'est MOI, votre rival. Enfin, votre allié. Votre rival-allié. C'est une catégorie très noble.", {}, "rire"),
					L("Violette m'a foudroyé par accident. Je n'ai rien senti ! J'ai absorbé l'éclair, grâce à une technique secrète des Tournevent. Mes cheveux ont mis trois jours à redescendre. Mais je n'ai rien senti.", {}, "rire"),
				],
				"interpelle": [L("Halte, noble inconnu ! Écoutez mon nom !", {"visites_max": 0}, "salut"), L("{surnom} ! Hardi ! L'aventure nous appelle !", {"visites_min": 1}, "salut")],
			}},
		{"id": "hilaire", "nom": "Hilaire", "titre": "aventurier de rang F (depuis douze ans)", "maison": "porte_hilaire", "village": "montjoie",
			"agenda": [[8, 12, "guilde_tableau", ["place_fontaine", "guilde_tableau"]], [12, 14, "guilde_table_6"], [14, 17, ["lac_rive", "foret_lisiere"]], [17, 22, "guilde_table_6"], [22, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "boucles", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.4, 0.45, 0.3], "carrure": 0.95},
			"teinte": PEAU[2],
			"mj": {"tenue": "aventurier", "objet": "epee"},
			"humeur_base": 0.6, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"pain_montjoie": 1.5, "tourte_montjoie": 2.0, "titre_propriete": 1.0, "potion_seve": 2.0, "jus_pomme": 1.5}, "deteste": {"cuisse_grenouille": -1.5, "gelee_slime": -1.0},
			"tics": ["Conseil d'ami :", "Ça aurait pu être pire.", "La prochaine fois, c'est la bonne !", "Je dis ça, je dis rien."],
			"surnoms": [[0, "petit nouveau"], [25, "collègue"], [50, "mon élève"], [75, "mon maître"], [95, "mon héros à moi"]],
			"repliques": {
				"accueil": [
					L("Salut, petit nouveau ! Hilaire, aventurier. Rang F. Depuis douze ans. Non, ne fais pas cette tête : c'est un rang très stable. Conseil d'ami : ne cours jamais vers une grenouille la bouche ouverte. Elle aussi, elle aura la bouche ouverte.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu as déjà monté de rang ? Ah. Bravo ! Non, sincèrement, bravo. Moi, je suis très bien en F. On s'y fait des amis. Tous les nouveaux passent par là.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Je me suis fait avaler deux fois par la même grenouille ce matin. Elle me reconnaît, maintenant. C'est presque une amie.", {}, "rire"),
					L("Le soir, je m'assois toujours à la même table de la taverne. Celle du fond. Celle des aventuriers qui reviennent bredouilles. Il y a de l'ambiance.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis arrivé à Montjoie à vingt-trois ans, avec une épée neuve et un plan parfait : devenir rang S en un an. Le premier jour, un slime m'a volé ma chaussure. Le plan a pris un peu de retard.", {}, "rire"),
					L("Je connais tous les monstres de l'île, leurs habitudes, leurs faiblesses. Je donne des conseils formidables aux nouveaux. Ils réussissent tous. Moi, j'oublie mes propres conseils au moment de les appliquer. C'est un genre de don.", {"sujet_min": ["lui", 1]}, "rire"),
					L("J'économise pour acheter la Chaumière des Glycines. Ça fait douze ans. J'ai cent quarante pièces. Monsieur Prosper dit qu'elle coûte trois cents. Il dit aussi que je serai le premier prévenu si elle baisse. Elle n'a jamais baissé.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Conseil d'ami : les slimes, tu les tapes une fois, ils rebondissent ; deux fois, ils fondent. Les grenouilles, tu restes sur le côté, jamais devant. Les gobelins, tu les laisses courir, ils se fatiguent. Moi, je fais tout le contraire. Fais comme je dis.", {}),
					L("Le Lac des Grenouilles, à l'est, c'est mon lieu de travail. Yvon, le pêcheur, a compté : je me suis fait avaler quarante-sept fois. Il a un carnet. Il dit que je suis son meilleur indicateur de grenouilles.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Dans le Donjon des Mille Marches, mon record, c'est le premier étage. Les Caves Gluantes. Odon a écrit « Hilaire : étage 1 (a glissé) » dans son registre. Douze ans de suite. C'est une tradition.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Lison, l'archère, je lui ai donné un conseil il y a trois ans : « Vise un peu à gauche du vent. » Depuis, elle ne rate plus jamais. Moi, je n'ai jamais essayé. J'ai oublié dans quel sens souffle le vent.", {}, "rire"),
					L("Le petit Titouan veut devenir rang S. Il me demande souvent des conseils. Je lui en donne de très bons. Puis il me regarde rater un slime, et il prend des notes sur ce qu'il ne faut pas faire. C'est un garçon intelligent.", {}, "rire"),
				],
				"interpelle": [L("Hé, petit nouveau ! Un conseil ?", {"visites_max": 0}, "salut"), L("{surnom} ! Conseil d'ami !", {"visites_min": 1}, "rire")],
			}},
		{"id": "lison", "nom": "Lison", "titre": "archère", "maison": "porte_lison", "village": "montjoie",
			"agenda": [[7, 10, "rempart_2"], [10, 12, "marche_flane_2"], [12, 14, "auberge_table_1"], [14, 18, "foret_lisiere", ["rempart_2"]], [18, 22, "guilde_table_2"], [22, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "tresse", "yeux": Y_VERT, "haut": [0.25, 0.4, 0.22], "taille": 0.98},
			"teinte": PEAU[0],
			"mj": {"tenue": "archere", "objet": "arc"},
			"humeur_base": 0.25, "traits": {"bavard": 0.1, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"gateau_miel": 3.0, "pain_miel": 2.5, "croissant": 2.0, "tourte_montjoie": 1.5, "plume_corbeau": 1.5}, "deteste": {"cuisse_grenouille": -1.0, "vieille_botte": -1.0},
			"tics": ["Hm.", "Juste.", "Gâteau ?", "Raté. Pas moi."],
			"surnoms": [[0, "toi"], [25, "aventurier"], [50, "compagnon"], [75, "ami"], [95, "ami de gâteau"]],
			"repliques": {
				"accueil": [
					L("Lison. Archère. … Tu as un gâteau ? Non ? Dommage. Bonjour quand même.", {"visites_max": 1}),
					L("{surnom}. Salut. (Elle te regarde les mains.) Pas de gâteau. Je note.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Honorine a fait des éclairs. J'en ai mangé six. Je vise mieux après un gâteau.", {}),
					L("Rodrigue m'a encore fait un discours. Vingt minutes. J'ai dit « non ». Il est reparti. Efficace.", {}, "rire"),
					L("Le soir, je m'assois au fond de la taverne. J'écoute. Je ne parle pas. Les autres parlent pour quatre.", {"soir": true}),
				],
				"lui": [
					L("J'ai grandi dans une ferme, au bord du Bois des Lutins. Je chassais les corbeaux des cerisiers avec un arc en noisetier. Je n'en ai jamais touché un. Je touchais les cerises. Une par une. Mon père les ramassait.", {}),
					L("Les gens croient que je ne parle pas parce que je suis timide. Non. C'est juste qu'à la Guilde, il y a Tancrède, Rodrigue, Bertrand et Mélusine. Il ne reste plus de place pour les mots.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Hilaire m'a donné un conseil, à mes débuts : « Vise un peu à gauche du vent. » Depuis, je ne rate rien. Je ne lui ai jamais dit que c'était grâce à lui. Je lui achète une part de gâteau tous les vendredis. Il croit que c'est le hasard.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les remparts. Ronds. Trois portes : nord, sud, est. Le matin, je m'entraîne sur le rempart. On voit loin. Les cibles ne bougent pas. Les gobelins, si.", {}),
					L("Bois des Lutins. Nord-est. Gobelins rapides. Ils lancent des lances. Petites. Ça pique. Reste derrière un arbre, compte jusqu'à trois, tire.", {"sujet_min": ["ile", 1]}),
					L("La boulangerie d'Honorine. Ville-Moyenne. Les éclairs au chocolat, le jeudi. C'est l'endroit le plus important de l'île.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Rodrigue. Trop de mots. Bon épéiste, quand même. Ne lui dis pas.", {}),
					L("Bertrand chante une chanson sur moi. « La flèche silencieuse ». Quarante couplets. Moi, j'aurais fait un couplet.", {}, "rire"),
				],
				"interpelle": [L("Toi.", {"visites_max": 0}), L("{surnom}. Gâteau ?", {"visites_min": 1})],
			}},
		{"id": "rodrigue", "nom": "Rodrigue", "titre": "épéiste (ton rival autoproclamé)", "maison": "porte_rodrigue", "village": "montjoie",
			"agenda": [[6, 9, "place_fontaine"], [9, 12, "chateau_cour"], [12, 14, "auberge_table_2"], [14, 18, ["porte_sud", "place_jeu_1", "rue_3"]], [18, 22, "guilde_table_4"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "yeux": Y_GRIS, "haut": [0.12, 0.1, 0.14], "taille": 1.06, "carrure": 0.95},
			"teinte": PEAU[3],
			"mj": {"tenue": "aventurier", "objet": "epee"},
			"humeur_base": 0.2, "traits": {"bavard": 0.85, "humour": 0.35, "curiosite": 0.4, "susceptible": 0.85, "rancunier": 0.4},
			"aime": {"plume_corbeau": 2.0, "rubis": 2.0, "cidre_montjoie": 1.0, "potion_seve": 1.5, "plume_furie": 2.0}, "deteste": {"gelee_slime": -1.5, "navet_dore": -1.5, "cuisse_grenouille": -1.0},
			"tics": ["Hmph.", "Le destin…", "Nous nous reverrons !", "Mon rival !"],
			"surnoms": [[0, "toi"], [25, "mon rival"], [50, "mon grand rival"], [75, "mon rival éternel"], [95, "le seul rival digne de moi"]],
			"repliques": {
				"accueil": [
					L("Halte ! (Il dégaine, sa cape claque au vent… le vent tombe, la cape aussi.) Je suis Rodrigue, épéiste de la Guilde. Et toi… je le sens… tu seras mon RIVAL. Ne discute pas : c'est le destin. Je l'ai décidé ce matin.", {"visites_max": 1}),
					L("Mon rival ! Te voilà enfin ! J'ai battu trois slimes de plus que toi cette semaine. Je crois. Je n'ai pas compté les tiens. Mais je le sens.", {"visites_min": 2}),
				],
				"humeur": [
					L("Tu as vaincu le Roi Gélatineux. Toi. Avant moi. (Il serre les poings, puis soupire.) … Félicitations. Je te hais. Non. Bravo. Je te hais un peu. Bravo quand même.", {"a_trouve": "roi_gelatineux"}),
					L("Terrible. Lison m'a dit « non » au milieu de mon discours sur l'honneur de l'épée. J'étais à peine au quart. Elle avait raison, c'est ce qui m'énerve.", {}),
					L("La nuit tombe… comme le rideau sur notre duel de demain. Quel duel ? Je ne sais pas encore. Mais il sera magnifique.", {"soir": true}),
				],
				"lui": [
					L("Je viens d'un petit village de montagne où il ne se passait rien. Rien ! J'ai lu toutes les légendes de la bibliothèque. Dans chacune, le héros avait un rival. Je suis venu à Montjoie chercher le mien. Tu es arrivé. C'est le destin.", {}),
					L("Mon épée s'appelle Crépuscule. Je l'ai baptisée moi-même, sur la falaise, au coucher du soleil. J'ai fait un long discours. Ensuite, j'ai glissé, et j'ai passé la nuit sur la falaise. Mais le nom est resté.", {"sujet_min": ["lui", 1]}),
					L("Je vais te dire une chose, mais ne la répète pas. Avant que tu arrives, je n'avais personne à qui me comparer. Je m'entraînais pour rien. Maintenant, je me lève à cinq heures. Merci. Je te hais. Merci.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La cour du château, en haut de la Butte. C'est là que je m'entraîne, chaque matin, face au vent. Sire Tancrède s'entraîne juste avant moi. Il laisse toujours des miettes de tourte sur les pavés.", {}),
					L("Le Donjon des Mille Marches… Cinq étages. Au fond, le Roi Gélatineux. Celui de nous deux qui le vaincra le premier sera le vrai héros de Montjoie. Je suis prêt. Presque. J'attends le bon moment dramatique.", {"sujet_min": ["ile", 1]}),
					L("Les Crocs, au sud-ouest : des rochers pointus, du vent, de l'orage. L'endroit parfait pour un duel. On s'y donne rendez-vous un jour, toi et moi ? Pas aujourd'hui. Il pleut. Ma cape n'aime pas la pluie.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Bertrand a écrit une chanson sur moi. « Rodrigue et sa cape ». Elle est… comique. Je lui avais demandé « tragique ». Il dit que c'est la même chose avec un luth.", {}),
					L("Sire Tancrède se prétend ton rival, lui aussi. Il n'y a qu'UN rival par héros. C'est dans les livres. Nous réglerons ça… autour d'une tourte. Il a insisté pour la tourte.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Oui, toi ! Tu seras mon rival !", {"visites_max": 0}), L("Mon rival ! Approche, si tu l'oses !", {"visites_min": 1})],
				"au_revoir": [L("Va ! Et deviens plus fort. Je veux un rival à ma hauteur.", {}), L("Nous nous reverrons, {surnom}. C'est écrit. Par moi.", {}), L("La nuit sépare les rivaux… jusqu'à demain matin, neuf heures. Sois à l'heure.", {"soir": true})],
			}},
		{"id": "bertrand", "nom": "Bertrand", "titre": "barde de la Guilde", "maison": "porte_bertrand", "village": "montjoie",
			"agenda": [[10, 12, "place_musique"], [12, 14, "guilde_table_5"], [14, 17, "place_musique"], [17, 23, "guilde_scene"], [23, 10, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "queue", "barbe": "moustache", "yeux": Y_AMBRE, "haut": [0.55, 0.15, 0.2]},
			"teinte": PEAU[2],
			"mj": {"tenue": "barde", "objet": "luth", "chapeau": "plume"},
			"humeur_base": 0.55, "traits": {"bavard": 0.95, "humour": 0.85, "curiosite": 0.7, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"partition": 3.0, "plume_ara": 2.0, "plume_perroquet": 2.0, "miel": 1.5, "cidre_montjoie": 1.0, "jus_pomme": 1.0}, "deteste": {"sifflet_muet": -2.0, "gelee_slime": -0.5},
			"tics": ["Tralala !", "Quelle rime !", "Ça fera un couplet.", "Et le public pleure !"],
			"surnoms": [[0, "noble inconnu"], [25, "mon héros"], [50, "mon héros favori"], [75, "ma muse"], [95, "le héros de ma plus belle ballade"]],
			"repliques": {
				"accueil": [
					L("(Il gratte un accord.) Voici venir un aventurier… au regard fier, au pas léger… Bertrand, barde de la Guilde ! Je chante les exploits de Montjoie. Les tiens aussi, bientôt. Tu en as déjà ? Pas grave : j'en invente très bien.", {"visites_max": 1}, "salut"),
					L("{surnom} ! J'ai écrit un couplet sur toi ! « Il affronta mille slimes… » Combien en as-tu affronté ? Trois ? « Il affronta mille slimes. » La rime l'exige.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Le Roi Gélatineux ! Vaincu ! J'ai déjà quatre-vingts couplets. Dans ma version, tu l'as vaincu d'une seule main, en chantant. Ne me contredis pas, c'est plus beau comme ça.", {"a_trouve": "roi_gelatineux"}, "rire"),
					L("Inspiré ! Ce matin, une mouette s'est posée sur mon luth. J'ai composé « La complainte de la mouette ». Elle est partie au deuxième couplet. Les critiques sont sévères, ici.", {}, "rire"),
					L("Le soir, c'est mon heure ! La scène de la Guilde, les bougies, la tourte qui sent bon… et Maître Hugues qui pleure au troisième couplet. Toujours au troisième.", {"soir": true}),
				],
				"lui": [
					L("Mon père était barde, mon grand-père aussi. Mon arrière-grand-père a chanté pour trois rois. Les trois l'ont prié de s'arrêter. Mais avec respect. C'est une tradition familiale.", {}, "rire"),
					L("J'ai été aventurier, une semaine. J'ai passé six jours à composer ma chanson d'adieu au cas où je mourrais héroïquement, et le septième à m'enfuir devant une grenouille. J'ai chanté la chanson quand même. Elle était très bien.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La vérité, c'est que j'exagère tout, parce que les vrais exploits sont trop petits pour le cœur des gens. Un aventurier qui revient entier, couvert de gelée, avec trois pièces… pour moi, c'est un héros. Je le chante comme tel.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Grand-Place du Marché, au milieu de la Ville-Moyenne : la fontaine, les étals de Babette, la cloche de Mélusine… Je joue près de la fontaine l'après-midi. Mélusine sonne sa cloche au milieu de mes refrains. Elle dit que c'est le hasard. C'est une crieuse : rien n'est jamais un hasard chez elle.", {}),
					L("La Grande Alerte des Navets ! Quel spectacle ! Mélusine sonne, la ville court, les navets courent plus vite, et Père Gaubert crie « doucement avec mes petits ! ». J'ai écrit un opéra là-dessus. Trois actes. Le troisième, ce sont les navets qui gagnent.", {"sujet_min": ["ile", 1]}, "rire"),
					L("On dit que le Roi Gélatineux, au fond du donjon, porte une petite couronne. Une couronne ! Sur un slime ! Si tu la vois, raconte-moi tout. La couronne, le slime, la tête du slime. Enfin, s'il a une tête.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Rodrigue m'a commandé une chanson tragique sur lui. J'ai fait de mon mieux. Le public a ri pendant vingt minutes. Ce n'est pas ma faute : il est tombé de la scène au refrain.", {}, "rire"),
					L("Sire Tancrède me raconte un nouvel exploit chaque soir. Je les mets en chanson. Ce sont mes plus beaux succès. Et aucun n'a eu lieu.", {}, "rire"),
				],
				"interpelle": [L("Tralala ! Un nouveau héros !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai un nouveau couplet !", {"visites_min": 1}, "rire")],
			}},
		# ================================================================ le Château et le Temple
		{"id": "barthelemy", "nom": "Baron Barthélemy", "titre": "Baron de Montjoie, seigneur de la ville", "maison": "porte_barthelemy", "village": "montjoie", "vouvoie": true,
			"agenda": [[8, 11, "chateau_trone"], [11, 13, "chateau_jardin"], [13, 15, "chateau_salon"], [15, 17, ["haute_belvedere", "place_fontaine"]], [17, 18, "chateau_jardin"], [18, 20, "chateau_rempart"], [20, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BLEU, "haut": [0.45, 0.12, 0.2], "vieux": true, "carrure": 1.1},
			"teinte": PEAU[0],
			"mj": {"tenue": "noble", "objet": "canne", "chapeau": "plume"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.65, "curiosite": 0.9, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"chapeau_baron": 3.0, "chapeau_ventilateur": 2.5, "tricorne_or": 2.5, "plume_ara": 2.0, "pain_montjoie": 1.0}, "deteste": {"vieille_botte": -1.0, "gelee_slime": -1.0},
			"tics": ["Hein ? Quoi ?", "Charmant, charmant !", "Où ai-je mis mon chapeau ?", "Aurore ! … Ah, non, rien."],
			"surnoms": [[0, "jeune personne"], [25, "cher ami"], [50, "très cher ami"], [75, "ami du château"], [95, "chevalier de mon cœur"]],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour, bonjour ! Barthélemy, Baron de Montjoie. Ce chapeau ? C'est le chapeau du mardi. … Nous sommes jeudi ? Ah. Aurore va me gronder. Charmant de vous rencontrer, jeune personne !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Comment trouvez-vous mon chapeau d'aujourd'hui ? Il a des cerises dessus. De vraies cerises. Les oiseaux l'adorent. Un peu trop.", {"visites_min": 2}, "rire"),
					L("Mon chapeau à plume ! Vous l'avez retrouvé ! Sur le moulin, vraiment ? Il voyage plus que moi, ce chapeau. Merci, merci !", {"q56": "mj_chapeau=finie", "visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Mon chapeau à plume s'est envolé ! Le plus beau ! Le vent l'a emporté par-dessus la muraille. Je l'ai vu passer sur les toits de la Ville-Moyenne, puis plus rien. Sans lui, je me sens tout… décoiffé.", {"q56": "mj_chapeau="}),
					L("Formidable ! Aurore m'a laissé signer un document toute seul. Enfin, tout seul… elle tenait la plume. Et ma main. Mais c'était ma signature !", {}, "rire"),
					L("Le soir, je monte sur le rempart du château et je salue la ville. La ville ne me répond pas. Sauf Mélusine. Elle répond toujours. Très fort.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai trois cent soixante-cinq chapeaux. Un pour chaque jour de l'année. Et un de plus pour les années bissextiles : c'est un chapeau en forme de lapin. Je ne le porte que tous les quatre ans. Il me manque beaucoup.", {}, "rire"),
					L("Mon père était un grand baron, sérieux, sévère, toujours tête nue. À sa mort, j'ai trouvé dans son armoire un seul chapeau : un petit chapeau de paille d'enfant. Le mien, quand j'avais cinq ans. Il l'avait gardé. Depuis, je porte des chapeaux.", {"sujet_min": ["lui", 1]}),
					L("Je suis un baron très distrait. J'ai oublié trois fois le nom de ma ville. Mais je n'ai jamais oublié le nom d'un seul habitant. C'est le plus important, non ? Les noms, ce sont les gens.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon château est tout en haut de la Butte. Pour y monter, on suit les lacets : la rampe de la Basse-Ville, puis celle de la Ville-Moyenne, puis la dernière, le long du mur du château. Mon grand-père voulait des rues droites. Il est tombé dans la pente le jour de l'inauguration.", {}, "rire"),
					L("La Guilde est la fierté de Montjoie. C'est mon arrière-grand-mère qui l'a fondée, pour que les aventuriers aient un endroit chaud où rentrer. Elle disait : « Un héros, c'est quelqu'un qui revient. » Elle portait un chapeau magnifique.", {"sujet_min": ["ile", 1]}),
					L("Mon chapeau à plume s'envole souvent. Il est allé sur le toit de la Guilde, sur le clocher du temple, et une fois sur la tête d'une grenouille du lac. Elle l'a gardé une semaine. Elle avait l'air très distinguée.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Monsieur Prosper a essayé de vendre ma tour nord à des voyageurs. « Vue imprenable, calme absolu. » Aurore l'a raccompagné jusqu'à la porte. Avec beaucoup de calme. Absolu.", {}, "rire"),
					L("Colombe me fait un nouveau chapeau pour la fête de l'Aube. Elle m'a dit : « Pas de cerises, cette fois. » Je ne promets rien.", {}, "rire"),
				],
				"interpelle": [L("Oh ! Jeune personne ! Bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Venez voir mon chapeau !", {"visites_min": 1}, "rire")],
			}},
		{"id": "aurore", "nom": "Aurore", "titre": "intendante du château", "maison": "porte_aurore", "village": "montjoie", "vouvoie": true,
			"agenda": [[6, 12, "chateau_salon"], [12, 13, "chateau_cour"], [13, 15, "chateau_trone"], [15, 19, "chateau_salon"], [19, 21, "temple_banc_2"], [21, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.18, 0.22, 0.3], "robe": [0.18, 0.22, 0.3], "robe_longue": true, "lunettes": true},
			"teinte": PEAU[2],
			"mj": {"tenue": "noble", "objet": "livre"},
			"humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.55, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"the_menthe": 2.0, "pain_montjoie": 1.5, "boussole": 1.5, "tisane_lune": 2.0, "croissant": 1.5}, "deteste": {"chapeau_ventilateur": -1.5, "gelee_slime": -1.0},
			"tics": ["Évidemment.", "C'est réglé.", "Je m'en occupe.", "Soupir."],
			"surnoms": [[0, "visiteur"], [25, "cher aventurier"], [50, "aide précieuse"], [75, "ami du château"], [95, "mon seul repos"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Aurore, intendante du château. Si vous cherchez le Baron, il est dans le jardin, ou sur le rempart, ou sur un toit à la poursuite d'un chapeau. Si vous cherchez quelqu'un qui sait où sont les choses, c'est moi.", {"visites_max": 1}),
					L("{surnom}. Bonjour. Vous tombez bien : j'ai trois minutes de libres. Je les ai notées à l'avance.", {"visites_min": 2}),
				],
				"humeur": [
					L("Correcte. Le Baron voulait offrir la Grand-Place à un marchand de chapeaux. Contre un chapeau. J'ai déchiré le contrat. J'ai gardé le chapeau : il était joli.", {}, "rire"),
					L("Le soir, je vais m'asseoir au Temple de l'Aube. Ce n'est pas pour prier. C'est le seul endroit de Montjoie où personne ne me demande rien. Père Clotaire dort. C'est parfait.", {"soir": true}),
				],
				"lui": [
					L("J'étais la fille de la cuisinière du château. À neuf ans, j'ai retrouvé les clés du trésor que le Baron avait perdues : elles étaient dans son chapeau. Sur sa tête. Depuis ce jour, je retrouve tout ce qu'il perd. C'est devenu un métier.", {}),
					L("On croit que je gouverne Montjoie à la place du Baron. C'est faux. Je fais les comptes, le courrier, les audiences, les réparations et le calendrier. Lui, il connaît tout le monde par son nom et il rend les gens heureux. C'est le plus difficile.", {"sujet_min": ["lui", 1]}),
					L("Un soir d'hiver, j'ai voulu démissionner. J'avais écrit la lettre. Le Baron l'a lue, il a pleuré, puis il a mis son chapeau du dimanche et il m'a fait une crêpe. Elle était ratée. Je suis restée.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le château a une cour, un jardin, un salon, une salle du trône et un rempart. Et quarante-deux placards à chapeaux. J'ai l'inventaire. Il fait quatre-vingts pages.", {}, "rire"),
					L("Monsieur Prosper vend la Chaumière des Glycines, dans la Haute-Ville. Trois cents pièces. Il dira que c'est un château. C'est une jolie maison avec un toit qui fuit un peu. Mais les glycines sont vraiment belles.", {"sujet_min": ["ile", 1]}),
					L("Le pain du château vient de chez Honorine, tous les matins. Le jour où il ne vient pas, le Baron pense que c'est la fin du monde, et il met son chapeau de deuil. Ça arrive plus souvent qu'on croit.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Capitaine Ferdinand et moi, nous faisons le point chaque semaine. Lui avec ses alertes, moi avec le Baron. Nous comparons nos journées. Il gagne souvent. Les navets, c'est pire qu'un baron.", {}),
					L("Monsieur Prosper m'envoie des fleurs depuis que j'ai refusé de vendre la tour nord. Il espère me faire changer d'avis. Les fleurs sont belles. Mon avis n'a pas bougé.", {}),
				],
				"interpelle": [L("Vous, là. Vous cherchez quelque chose ?", {"visites_max": 0}), L("{surnom}. Bonjour.", {"visites_min": 1}, "salut")],
			}},
		{"id": "clotaire", "nom": "Père Clotaire", "titre": "prêtre du Temple de l'Aube", "maison": "porte_clotaire", "village": "montjoie",
			"agenda": [[6, 12, "temple_autel"], [12, 14, "temple_banc_2"], [14, 18, "temple_autel"], [18, 20, "temple_parvis"], [20, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "courte", "yeux": Y_GRIS, "haut": [0.95, 0.9, 0.75], "robe": [0.95, 0.9, 0.75], "robe_longue": true, "vieux": true, "taille": 0.94},
			"teinte": PEAU[1],
			"mj": {"tenue": "pretresse", "objet": "livre"},
			"humeur_base": 0.45, "traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.4, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"pain_montjoie": 2.0, "tisane_lune": 2.0, "miel": 1.5, "chapelet_soleil": 2.0, "fleur_lune": 1.5}, "deteste": {"cafe_brasier": -1.5, "cafe_vapeur": -1.0},
			"tics": ["Mon enfant…", "Zzz… Hein ? Oui !", "Que l'Aube t'éclaire.", "Bénis sois-tu."],
			"surnoms": [[0, "mon enfant"], [25, "mon enfant"], [50, "mon cher enfant"], [75, "mon fils de lumière"], [95, "enfant béni de l'Aube"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au Temple de l'Aube, mon enfant. Je suis Père Clotaire. Assieds-toi. Je vais te dire quelques mots sur la lumière qui se lève chaque matin, et sur l'espoir qui… zzz… (Il sursaute.) … qui se lève aussi. Voilà. C'était le sermon.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te voilà ! J'étais justement en train de méditer. Les yeux fermés. Très longuement. Avec un petit ronflement de méditation.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Paisible. Sœur Pétronille a rangé les cierges, n'en a renversé que la moitié, et a soigné le chat qui les avait fait tomber. C'était le chat, cette fois. Pour une fois.", {}, "rire"),
					L("Le soir, je me tiens sur le parvis et je regarde la ville s'allumer. Ce sont les plus belles prières, les fenêtres qui s'allument. Elles ne disent rien, et elles disent tout.", {"soir": true}),
				],
				"lui": [
					L("Je suis entré au temple à quinze ans, avec Philomène qui m'accompagnait jusqu'à la porte pour être sûre que je n'allais pas m'enfuir. Elle avait raison : je voulais m'enfuir. Je suis resté cinquante-cinq ans.", {}, "rire"),
					L("Je m'endors pendant mes sermons. Oui, je le sais. On me l'a dit. Mais vois-tu, le temple est si calme, les bancs si doux, et ma propre voix si… reposante. Mes fidèles ne s'en plaignent pas : ils dorment aussi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La petite Pétronille, je l'ai recueillie un soir d'orage. Elle avait peur du noir. Je lui ai appris à soigner, parce que quand on soigne, on n'a plus le temps d'avoir peur. Elle a encore peur. Mais elle soigne mieux que moi.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Temple de l'Aube est dans la Haute-Ville. Ses vitraux s'allument au lever du soleil. Le matin, la lumière tombe sur l'autel, et pendant une minute, tout Montjoie est en or. Même Mélusine se tait. Presque.", {}),
					L("L'Aube protège les débutants. C'est pour cela qu'il y a tant de débutants à Montjoie : ils se sentent protégés. Et c'est pour cela qu'il y a tant de bosses : l'Aube ne peut pas être partout.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Donjon des Mille Marches est très ancien. Philomène dit que les marches ont été taillées par un roi qui avait peur de la lumière. Il est descendu, descendu, et on ne l'a jamais revu. Ses marches, elles, sont restées.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Gilles, le garde de la Porte Nord, dort debout. Il prétend que je dors assis. Nous avons fait un concours. Personne n'a gagné : nous nous sommes endormis tous les deux avant la fin.", {}, "rire"),
					L("Honorine m'apporte le pain du temple chaque matin, en chantant. C'est le plus beau cantique de Montjoie, et il sent la croûte chaude.", {}),
				],
				"interpelle": [L("Approche, mon enfant. N'aie pas peur.", {"visites_max": 0}, "salut"), L("{surnom} ! Que l'Aube t'éclaire !", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ les boutiques de la Ville-Moyenne
		{"id": "brunehaut", "nom": "Brunehaut", "titre": "forgeronne", "maison": "porte_brunehaut", "village": "montjoie",
			"agenda": [[6, 12, "forge_enclume"], [12, 13, "place_banc_2"], [13, 19, "forge_enclume"], [19, 21, "rue_6"], [21, 6, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "queue", "yeux": Y_VERT, "haut": [0.42, 0.3, 0.2], "tablier": [0.3, 0.2, 0.12], "taille": 1.08, "carrure": 1.4},
			"teinte": PEAU[2],
			"mj": {"tenue": "forgeron", "objet": "marteau"},
			"humeur_base": 0.55, "traits": {"bavard": 0.7, "humour": 0.85, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"minerai_fer": 2.0, "obsidienne": 2.0, "tourte_montjoie": 1.5, "cidre_montjoie": 1.0, "rune_golem": 2.0, "croc_gobelin": 1.0}, "deteste": {"gelee_slime": -1.5, "tisane_lune": -0.5},
			"boutique": {"vend": {"epee": 60, "hache": 34, "epee_bois": 6}, "achete": {"epee_bois": 2, "hache": 14, "epee": 26, "minerai_fer": 5, "obsidienne": 8, "croc_gobelin": 3}},
			"tics": ["HA HA HA !", "Bien trempé !", "Ça, c'est du solide !", "Clang !"],
			"surnoms": [[0, "petit gabarit"], [25, "aventurier"], [50, "costaud"], [75, "mon lascar"], [95, "acier de Montjoie"]],
			"repliques": {
				"accueil": [
					L("HA HA HA ! Un nouveau ! Brunehaut, forgeronne ! Des épées, des haches, des boucliers, et des poignées de main qui écrasent ! (Elle te serre la main. Tu ne sens plus tes doigts.) Pardon. Je ne connais pas ma force. Si, je la connais. Elle est grande.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Ton épée tient le coup ? Montre ! … Hm. Tu as tapé sur un rocher. Ne mens pas, ça se voit. Les rochers, ça ne se combat pas, ça se contourne.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Rouge comme mon fer ! J'ai forgé six épées, réparé trois boucliers, et Titouan n'a brûlé qu'un seul tablier. Une bonne journée.", {}, "rire"),
					L("Le soir, je vais faire un tour dans la Basse-Ville. Je fais un bras de fer avec ceux qui veulent. Personne ne veut plus. Même Clovis a renoncé, et il soulève des sacs de farine toute la journée.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Ma mère était forgeronne, et sa mère aussi. Le premier jour, à six ans, j'ai soulevé le marteau de ma mère. Le deuxième jour, je l'ai lâché sur son pied. Elle a ri si fort que les voisins ont cru à un coup de tonnerre. Chez nous, on rit fort.", {}, "rire"),
					L("Titouan veut être aventurier de rang S. Pas forgeron. Je le sais. Je lui apprends la forge quand même, parce qu'un aventurier qui sait réparer son épée revient plus souvent à la maison. C'est tout ce que je veux, moi. Qu'il revienne.", {"sujet_min": ["lui", 1]}),
					L("Madame Olga veut enchanter mes épées. La dernière fois, l'épée est devenue rose et elle chantait quand on la sortait du fourreau. Je l'ai vendue à Rodrigue. Il ne sait pas encore qu'elle chante.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Ma forge est dans la Ville-Moyenne, près de la Grand-Place. Tu la trouveras à l'oreille : clang, clang, HA HA HA. Si tu entends seulement HA HA HA, c'est que j'ai fini.", {}, "rire"),
					L("Les gobelins du Bois des Lutins ont des crocs très durs. Rapporte-m'en : je les monte en pointes de flèches pour Lison. Elle me paie en gâteaux. Enfin, elle me montre les gâteaux. Puis elle les mange.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Roi Gélatineux, au fond du donjon, colle à tout. Une épée bien affûtée le coupe, une épée émoussée reste coincée dedans. Passe me voir avant de descendre : je t'affûte tout ça. Gratuitement. Enfin, presque.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Capitaine Ferdinand m'a commandé vingt épées pour la garde. Il les veut « réglementaires ». Je lui ai demandé ce que ça voulait dire. Il a réfléchi longtemps. Il a dit : « Pointues. »", {}, "rire"),
					L("Madame Olga m'a encore apporté une « pierre magique ». C'était un caillou. Elle me l'a fait payer. J'ai payé. Elle est trop gentille pour qu'on lui dise non.", {}, "rire"),
				],
				"interpelle": [L("HA ! Toi ! Viens voir de l'acier !", {"visites_max": 0}, "rire"), L("{surnom} ! Clang ! Bonjour !", {"visites_min": 1}, "salut")],
				"boutique": [L("Regarde, touche, soupèse ! De l'acier de Montjoie. Tu as {pieces} pièces.", {})],
			}},
		{"id": "titouan", "nom": "Titouan", "titre": "apprenti forgeron, le fils de Brunehaut", "maison": "porte_titouan", "village": "montjoie",
			"agenda": [[8, 12, "forge_comptoir"], [12, 13, "place_jeu_1", ["place_jeu_2", "place_fontaine"]], [13, 16, "forge_comptoir"], [16, 19, ["guilde_tableau", "place_jeu_1", "porte_sud"]], [19, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "court", "yeux": Y_VERT, "haut": [0.5, 0.36, 0.22], "tablier": [0.3, 0.2, 0.12], "enfant": true, "taille": 0.78},
			"teinte": PEAU[1],
			"mj": {"tenue": "enfant", "objet": "marteau"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.05},
			"aime": {"carte_aventurier": 3.0, "croc_gobelin": 2.5, "gateau_miel": 2.0, "coeur_gelee": 2.5, "banniere_gobelin": 2.5}, "deteste": {"tisane_lune": -1.0, "vieille_botte": -0.5},
			"tics": ["Trop fort !", "Quand je serai rang S…", "C'est pas juste !", "Promis !"],
			"surnoms": [[0, "l'aventurier"], [25, "chef"], [50, "grand chef"], [75, "mon héros"], [95, "mon modèle de rang S"]],
			"repliques": {
				"accueil": [
					L("T'es un aventurier ? Un vrai ? T'es de quel rang ? Moi c'est Titouan, j'ai onze ans, et je serai rang S. Pas maintenant. Maman dit à seize ans. Moi je dis à douze. On négocie.", {"visites_max": 1}, "rire"),
					L("{surnom} ! T'as vaincu quoi aujourd'hui ? Raconte ! Avec les détails ! Surtout les détails dégoûtants !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("T'AS VAINCU LE ROI GÉLATINEUX ?! Trop fort ! Il était gros comment ? Il t'a collé ? T'as gardé un bout de gelée ? Je peux le toucher ?", {"a_trouve": "roi_gelatineux"}, "rire"),
					L("Super ! J'ai forgé mon premier clou. Il est tordu. Maman dit que c'est un clou « d'aventurier ». Ça veut dire qu'il est tordu.", {}, "rire"),
				],
				"lui": [
					L("Quand j'étais petit, Maman m'a fabriqué une épée en bois. Je l'ai appelée Tonnerre. J'ai vaincu tous les poteaux de la Basse-Ville. Et un poulet. Enfin, le poulet m'a vaincu. Mais je me suis bien battu.", {}, "rire"),
					L("Mon héros, c'est Sire Tancrède. Il a vaincu un géant, un serpent et un ours. Hilaire dit que c'était dans le brouillard. Moi je dis que le brouillard, ça rend encore plus courageux, parce qu'on ne voit rien.", {"sujet_min": ["lui", 1]}),
					L("Noisette et moi, on a fondé une guilde secrète. La Guilde des Petits Héros. Elle a deux membres. Noisette est la cheffe, parce qu'elle a fait le badge. Moi, je suis le guerrier. On cherche un mage.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Au tableau de la Guilde, il y a des contrats de chasse : des slimes, des grenouilles, des gobelins… Églantine ne veut pas m'en donner. Elle dit « pas avant seize ans ». Alors je les lis. Je les connais tous par cœur.", {}),
					L("Le Bois des Lutins, au nord-est, c'est là qu'il y a le camp des gobelins. Avec un chef ! Il a une bannière ! Si tu le bats, tu me montres la bannière ? Juste la montrer. Je ne la touche pas. Un tout petit peu.", {"sujet_min": ["ile", 1]}),
					L("Le Donjon des Mille Marches, à l'étage quatre, il y a des coffres qui mordent ! Des mimiques ! Philomène me l'a dit. Moi, si j'en vois un, je lui donne un coup de marteau sur le couvercle. Bonk.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Hilaire, il rate tout, mais il donne des conseils trop bien. Je les note dans un carnet. Et je note aussi ce qu'il fait, pour faire le contraire. Ça fait deux carnets.", {}, "rire"),
					L("Noisette suit les aventuriers partout. Elle dit que c'est pour « étudier ». Moi je dis qu'elle cherche des bonbons dans leurs sacs. Elle dit que les deux, c'est de l'étude.", {}, "rire"),
				],
				"interpelle": [L("Hé ! T'es un aventurier ?", {"visites_max": 0}, "salut"), L("{surnom} ! Raconte !", {"visites_min": 1}, "rire")],
			}},
		{"id": "olga", "nom": "Madame Olga", "titre": "marchande de magie", "maison": "porte_olga", "village": "montjoie",
			"agenda": [[9, 13, "magie_comptoir"], [13, 14, "place_banc_1"], [14, 19, "magie_comptoir"], [19, 22, "haute_belvedere"], [22, 9, "maison"]],
			"azur": {"cheveux": ARGENT, "coiffure": "boucles", "yeux": Y_VIOLET, "haut": [0.35, 0.18, 0.45], "robe": [0.35, 0.18, 0.45], "robe_longue": true, "vieux": true, "lunettes": true, "taille": 0.9},
			"teinte": PEAU[1],
			"mj": {"tenue": "mage", "objet": "baton", "chapeau": "mage"},
			"humeur_base": 0.5, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"page_grimoire": 3.0, "grimoire": 2.5, "eclat_lune": 2.0, "caillou_chantant": 2.0, "poussiere_fee": 2.0, "vieille_botte": 0.5}, "deteste": {"gelee_slime": -0.5},
			"boutique": {"vend": {"potion_mana": 9, "elixir_etoile": 16, "baton_sorcier": 45, "poussiere_fee": 8}, "achete": {"eclat_cristal": 8, "fleur_lune": 12, "eclat_lune": 10, "plume_lune": 8, "caillou_chantant": 6, "poussiere_fee": 5, "champignon_magique": 5, "gelee_slime": 3, "plume_corbeau": 3, "coquillage": 2, "caillou": 1, "vieille_botte": 1}},
			"tics": ["Fascinant !", "C'est sûrement magique.", "Où ai-je mis mes lunettes ?", "Abracadabr… non, attends."],
			"surnoms": [[0, "mon chou"], [25, "mon petit sortilège"], [50, "mon apprenti"], [75, "ma merveille"], [95, "mon grand enchanteur"]],
			"repliques": {
				"accueil": [
					L("Entre, entre ! Attention à la marche, au hibou empaillé, et à la marche. Madame Olga, marchande de magie ! Potions, élixirs, bâtons, et… tout ça. Je ne sais plus ce que c'est, tout ça. Mais c'est sûrement magique.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu m'apportes quelque chose de magique ? Montre ! … Un caillou ? Fascinant ! Je te l'achète. Il est sûrement magique. Tous les cailloux sont un peu magiques, quand on y pense.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Mon grimoire ! Les pages se sont envolées quand j'ai ouvert la fenêtre pour faire sortir un sortilège de courant d'air. Trois pages, éparpillées dans toute la ville ! Sans elles, mon grimoire raconte des recettes de soupe.", {"q56": "mj_grimoire="}),
					L("Merveilleuse ! J'ai acheté une chaussure magique ce matin. Une seule. Elle ne fait rien. C'est sûrement très puissant, ce qui ne fait rien.", {}, "rire"),
					L("Le soir, je monte au belvédère regarder les étoiles. Je les compte. Il en manque toujours une. Je soupçonne quelqu'un de l'avoir achetée.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai étudié la magie pendant soixante ans. J'ai appris dix mille sortilèges. J'en ai oublié neuf mille neuf cent quatre-vingt-dix. Il me reste les dix meilleurs. Enfin, je crois que ce sont les meilleurs. Je ne me souviens plus des autres.", {}, "rire"),
					L("Ma boutique déborde. Je n'arrive pas à vendre. J'achète tout ! Un objet magique, ça ne se laisse pas partir. Même s'il n'est pas magique. Surtout s'il n'est pas magique : il pourrait le devenir, et je serais bien bête.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La petite Violette me fait penser à moi, jeune. Moi, tous mes sorts finissaient en bulles de savon. Pendant trois ans. Puis un jour, une bulle s'est changée en papillon. Je pleure encore quand j'y pense. Je lui souhaite son papillon.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ma boutique est sur la Grand-Place, entre la forge de Brunehaut et la boutique d'Aubin. Aubin dit que ses potions sont de la science. Moi je dis que c'est de la magie qui a mis des lunettes.", {}, "rire"),
					L("Les cristaux d'orage, au sommet des Crocs, sont de vraies merveilles. Ils boivent la foudre et la recrachent droit devant. Exactement ce qu'il faudrait à Violette. Ne lui dis pas que c'est moi qui ai eu l'idée : laisse-la croire qu'elle l'a lue.", {"sujet_min": ["ile", 1]}),
					L("Au quatrième étage du donjon, il y a une bibliothèque, avec des coffres qui sont des mimiques. Une mimique ! Un coffre vivant ! Si tu en rapportes un petit morceau, je t'en donne un bon prix. Enfin, si le morceau ne mord pas.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Aubin a goûté une de ses potions et il est devenu vert. Il dit que c'est un effet « attendu ». Il a mis deux jours à redevenir rose. J'ai acheté le reste de la potion. C'est sûrement magique.", {}, "rire"),
					L("Philomène et moi, nous échangeons des légendes contre des tisanes. Elle en sait plus que mon grimoire. Et elle, elle ne perd pas ses pages.", {}),
				],
				"interpelle": [L("Oh ! Toi ! Tu as quelque chose de magique ?", {"visites_max": 0}), L("{surnom} ! Viens voir ma nouvelle merveille !", {"visites_min": 1}, "rire")],
				"boutique": [L("Regarde, mais ne touche pas au hibou. Il est empaillé, mais il est susceptible. Tu as {pieces} pièces.", {}, "rire")],
				"vente": [L("Oh ! Magique ! Sûrement ! Je t'en donne {prix} pièces !", {}, "rire")],
			}},
		{"id": "aubin", "nom": "Aubin", "titre": "apothicaire", "maison": "porte_aubin", "village": "montjoie", "vouvoie": true,
			"agenda": [[8, 12, "apothicaire_comptoir"], [12, 13, "marche_flane_1"], [13, 19, "apothicaire_comptoir"], [19, 21, "puits"], [21, 8, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "court", "yeux": Y_BLEU, "haut": [0.85, 0.88, 0.82], "lunettes": true, "carrure": 0.85},
			"teinte": PEAU[0],
			"mj": {"tenue": "savant", "objet": "livre"},
			"humeur_base": 0.35, "traits": {"bavard": 0.75, "humour": 0.55, "curiosite": 0.95, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"herbe_fievre": 2.0, "fleur_lune": 2.5, "gelee_slime": 2.0, "champignon_lune": 2.0, "fiole_vide": 1.5, "miel": 1.0}, "deteste": {"cidre_montjoie": -0.5, "vieille_botte": -1.0},
			"boutique": {"vend": {"potion_seve": 14, "tisane_lune": 6, "potion_mana": 9}, "achete": {"herbe_fievre": 3, "champignon": 2, "fleur_lune": 12, "gelee_slime": 4, "baies": 1, "fiole_vide": 2, "cuisse_grenouille": 2}},
			"tics": ["Hypothèse :", "Intéressant…", "Je vais goûter.", "Effet secondaire attendu."],
			"surnoms": [[0, "cher client"], [25, "cher patient"], [50, "cher cobaye"], [75, "cher collègue"], [95, "cher ami et confrère"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Aubin, apothicaire. Potions de soin, tisanes, remèdes. Tout est testé. Par moi. (Il remonte ses lunettes ; ses oreilles sont légèrement vertes.) L'effet secondaire de ce matin. Attendu. Plus ou moins.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous avez l'air en forme. Tant mieux. Ou alors c'est l'effet de mes potions. Hypothèse : les deux.", {"visites_min": 2}),
				],
				"humeur": [
					L("Très bien ! J'ai mis au point une potion qui soigne les bosses. Je l'ai goûtée. Je n'avais pas de bosse. Maintenant, j'ai les cheveux orange. Les bosses n'ont qu'à bien se tenir.", {}, "rire"),
					L("Le soir, je vais au puits de la Basse-Ville, prendre de l'eau fraîche pour mes potions. Et vérifier qu'il n'y a pas de slime dedans. Il y en a parfois. Je les mets en flacon.", {"soir": true}),
				],
				"lui": [
					L("Mon grand-père était apothicaire, et il goûtait tout, lui aussi. Il disait : « Une potion qu'on n'ose pas boire, on n'ose pas la vendre. » Il a été bleu pendant tout l'hiver 1102. On a des portraits. Il souriait.", {}, "rire"),
					L("La gelée de slime est un ingrédient merveilleux. Elle colle les fractures, elle apaise les brûlures, et elle fait des bulles amusantes dans le thé. Les aventuriers me regardent bizarrement quand je leur achète. Ils devraient la garder pour eux.", {"sujet_min": ["lui", 1]}),
					L("J'ai une peur secrète : un jour, goûter une potion qui me change en grenouille. Yvon ne me parlerait plus. Ulric me regarderait d'un drôle d'air. Alors je goûte toujours avec un verre d'eau à côté. Ça ne sert à rien. Ça rassure.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Ma boutique est sur la Grand-Place, à côté de celle de Madame Olga. Elle vend de la magie, je vends de la science. Le résultat est le même : les gens changent de couleur. Mais chez moi, c'est expliqué.", {}, "rire"),
					L("Odon, le gardien du donjon, revend mes potions au pied des Crocs. Il dit qu'on en a plus besoin en bas qu'en haut. C'est vrai : personne ne se fait mordre par un coffre sur la Grand-Place.", {"sujet_min": ["ile", 1]}),
					L("Les grenouilles géantes du lac ont une bave qui soigne les ampoules. Les aventuriers avalés en ressortent avec des pieds tout neufs. Ce n'est pas une recommandation. C'est une observation.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("J'ai fait une potion contre la foudre pour Violette. Elle est devenue bleue. La foudre est passée quand même. J'ai noté : « La foudre ne fait pas de différence entre les couleurs. »", {}, "rire"),
					L("Gilles m'a demandé une potion pour rester éveillé. Il a dormi deux jours. Je crois que j'ai inversé deux étiquettes. Il dit que c'était la meilleure nuit de sa vie.", {}, "rire"),
				],
				"interpelle": [L("Bonjour ! Une petite potion ?", {"visites_max": 0}, "salut"), L("{surnom} ! Vous tombez bien, j'ai besoin d'un avis !", {"visites_min": 1})],
			}},
		{"id": "honorine", "nom": "Honorine", "titre": "boulangère", "maison": "porte_honorine", "village": "montjoie",
			"agenda": [[4, 13, "boulangerie_comptoir"], [13, 15, "maison"], [15, 19, "boulangerie_comptoir"], [19, 21, "place_banc_2"], [21, 4, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "chignon", "yeux": Y_BRUN, "haut": [0.8, 0.55, 0.4], "tablier": [0.96, 0.94, 0.88], "robe": [0.8, 0.55, 0.4]},
			"teinte": PEAU[1],
			"mj": {"tenue": "artisan", "objet": "panier", "chapeau": "bonnet"},
			"humeur_base": 0.55, "traits": {"bavard": 0.75, "humour": 0.65, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"miel": 2.5, "baies": 1.5, "pomme": 1.5, "graines": 1.5, "fleur_lune": 1.0, "jus_pomme": 1.0}, "deteste": {"gelee_slime": -2.0, "cuisse_grenouille": -0.5},
			"boutique": {"vend": {"pain_montjoie": 3, "croissant": 2, "pain_miel": 4, "gateau_miel": 9}, "achete": {"miel": 5, "baies": 1, "pomme": 1, "graines": 1}},
			"tics": ["Tra la la…", "Ça lève !", "Tout chaud !", "Pétris, pétris…"],
			"surnoms": [[0, "mon petit"], [25, "mon bon client"], [50, "mon chou à la crème"], [75, "mon petit pain d'or"], [95, "mon brioché"]],
			"repliques": {
				"accueil": [
					L("(Elle chante en pétrissant.) … Ah ! Bonjour ! Honorine, boulangère. Tout est sorti du four ce matin, à quatre heures. Pain de Montjoie, croissants, pains au miel. Et pour les aventuriers, je fais des miches qui tiennent trois jours dans un sac. Et qui assomment un slime, au besoin.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tout chaud ! Tiens, sens-moi ça. … Non, ne croque pas, c'est celui de Lison. Elle compte.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Je suis toute seule au four, ce matin, et il me reste trois pains à porter : un à la Guilde, pour Mamie Rissole ; un au château, pour Aurore ; un à la Porte Nord, pour Gilles. Si je quitte le four, tout brûle. Tu ne voudrais pas… ?", {"q56": "mj_pain="}),
					L("Levée à quatre heures, j'ai chanté onze chansons, et la pâte a levé comme jamais. Je crois que c'est la onzième chanson. Elle parle d'un navet amoureux.", {}, "rire"),
					L("Le soir, je m'assois sur un banc de la place, et Noisette me raconte sa journée. Elle a suivi quatre aventuriers, interrogé deux gardes, et caressé une grenouille. Pas une géante. J'espère.", {"soir": true}),
				],
				"lui": [
					L("Je chante en pétrissant depuis toute petite. Ma grand-mère disait que la pâte lève mieux quand on lui chante quelque chose. J'ai fait le test : sans chanson, elle lève ; avec chanson, elle lève et elle sourit. Enfin, moi je souris.", {}),
					L("Le père de Noisette était aventurier. Un jour, il est parti pour une grande quête, très loin, au-delà de la mer. Il écrit à chaque saison. Noisette garde toutes ses lettres dans une boîte à biscuits. Moi, je garde la boîte.", {"sujet_min": ["lui", 1]}),
					L("Clovis, le meunier, m'apporte la farine chaque matin. Il est tout blanc, de la tête aux pieds. Il dit que c'est la farine. Moi je crois qu'il rougit dessous, et que la farine cache tout.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Ma boulangerie est dans la Ville-Moyenne, près de la Grand-Place. Le matin, la rue sent le pain chaud jusqu'à la Guilde. Maître Hugues dit qu'il se réveille à l'odeur. Il arrive à quatre heures et demie. En chemise de nuit.", {}, "rire"),
					L("La farine vient du moulin de Clovis, aux Champs du Sud, près de la ferme de Père Gaubert. Le blé, c'est Gaubert ; la farine, c'est Clovis ; le pain, c'est moi. Et les navets, c'est le chaos.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Les jours d'Alerte des Navets, je fais des petits pains en forme de navet. Ils partent tous. Le Capitaine Ferdinand en prend toujours un. Il dit que c'est pour s'entraîner à les attraper.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Lison m'achète six éclairs tous les jeudis. Elle ne dit rien. Elle pose l'argent, elle prend les éclairs, elle sourit. C'est ma cliente préférée.", {}),
					L("Babette, au marché, vend les plus belles pommes de l'île. Germaine dit le contraire. Moi, je fais des chaussons avec les pommes des deux, et personne ne voit la différence. Surtout ne le leur dis pas.", {}, "rire"),
				],
				"interpelle": [L("Tout chaud ! Tout chaud !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai gardé un croissant !", {"visites_min": 1}, "rire")],
			}},
		{"id": "noisette_mj", "nom": "Noisette", "titre": "la fille d'Honorine", "maison": "porte_noisette", "village": "montjoie",
			"agenda": [[8, 11, "place_jeu_2"], [11, 12, "rue_2"], [12, 13, "place_jeu_2"], [13, 16, ["guilde_table_6", "temple_parvis", "place_jeu_2"]], [16, 19, ["lavoir_1", "place_jeu_2", "puits"]], [19, 8, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "tresse", "yeux": Y_BRUN, "haut": [0.85, 0.5, 0.25], "robe": [0.85, 0.5, 0.25], "enfant": true, "taille": 0.68},
			"teinte": PEAU[1],
			"mj": {"tenue": "enfant", "objet": "panier"},
			"humeur_base": 0.65, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"gateau_miel": 2.5, "pain_miel": 2.0, "baies": 2.0, "coquillage": 2.0, "plume_ara": 2.0, "carte_aventurier": 2.0}, "deteste": {"gelee_slime": -1.0, "cuisse_grenouille": -1.5},
			"tics": ["Pourquoi ?", "C'est vrai ?", "Je note !", "Et après ?"],
			"surnoms": [[0, "monsieur l'aventurier"], [25, "mon aventurier"], [50, "mon aventurier préféré"], [75, "mon héros"], [95, "membre d'honneur de la Guilde des Petits Héros"]],
			"repliques": {
				"accueil": [
					L("T'es qui ? T'es un aventurier ? T'as combien d'épées ? T'as déjà été avalé par une grenouille ? C'est comment dedans ? Ça sent quoi ? Moi c'est Noisette. J'ai huit ans. Je pose des questions.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Je t'ai suivi tout à l'heure ! Tu ne m'as pas vue ? C'est normal, je suis très forte. Pourquoi tu t'es arrêté devant la fontaine ? T'avais soif ? T'avais peur ? T'avais soif ?", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super ! J'ai suivi Sire Tancrède jusqu'au rempart. Il s'est pris les pieds dans sa cape deux fois. Je l'ai noté. Il m'a dit que c'était une technique. Je l'ai noté aussi.", {}, "rire"),
					L("Maman dit qu'il faut rentrer quand les lanternes s'allument. Moi je dis que les lanternes, c'est pour les aventuriers. Maman dit que je suis une aventurière qui va au lit.", {"soir": true}),
				],
				"lui": [
					L("Mon papa est aventurier. Il est parti très loin, au-delà de la mer, pour une grande quête. Il m'écrit à chaque saison. Dans sa dernière lettre, il a dessiné un dragon. Il dit qu'il était tout petit. Moi je crois qu'il dit ça pour pas que j'aie peur.", {}),
					L("Avec Titouan, on a fondé la Guilde des Petits Héros. J'ai fait le badge, avec un bouton et du fil. Alors je suis la cheffe. Titouan est le guerrier. On cherche un mage. Violette a dit peut-être. Peut-être, c'est presque oui.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Quand je serai grande, je serai réceptionniste, comme Églantine. Parce que la réceptionniste, elle connaît TOUS les aventuriers, elle sait tout ce qu'ils font, et elle a un tampon. Un tampon !", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Grand-Place, c'est mon bureau. De là, je vois qui entre à la Guilde, qui sort de la forge, qui achète des pommes chez Babette, et qui se dispute avec Germaine. C'est souvent Babette.", {}, "rire"),
					L("Grand-mère Philomène dit qu'au fond du donjon, il y a un roi en gelée avec une couronne. Une couronne en vrai ! Si tu la trouves, tu me la prêtes ? Juste pour une photo. Enfin, un dessin. On n'a pas d'appareil.", {"sujet_min": ["ile", 1]}),
					L("Quand Mélusine sonne la cloche, il faut courir aux Champs du Sud, parce que les navets se sauvent ! Moi j'ai le droit de regarder depuis la Porte Sud. J'en ai attrapé un, une fois. Il m'a regardée. Je l'ai relâché. Il avait l'air triste.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Mamie Rissole m'a donné trois parts de tourte aujourd'hui. Je n'en voulais qu'une. Elle a dit « mange ». J'ai mangé. Je ne peux plus courir. C'est un problème pour suivre les aventuriers.", {}, "rire"),
					L("Sœur Pétronille est tombée dans la fontaine ce matin. Elle a dit que c'était pour bénir l'eau. Elle était toute mouillée et elle riait. Je l'aime bien.", {}, "rire"),
				],
				"interpelle": [L("Hé ! T'es un aventurier ? Pourquoi ?", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une question ! Non, dix !", {"visites_min": 1}, "rire")],
				"cadeau_refus": [L("Maman dit que je n'ai pas le droit de toucher les armes. Même les petites. Même pour voir.", {})],
			}},
		{"id": "ulric", "nom": "Ulric", "titre": "aubergiste de « La Grenouille Repue »", "maison": "porte_ulric", "village": "montjoie",
			"agenda": [[7, 9, "auberge_comptoir"], [9, 10, "lac_rive"], [10, 23, "auberge_comptoir"], [23, 7, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.35, 0.45, 0.25], "tablier": [0.92, 0.9, 0.84], "carrure": 1.45},
			"teinte": PEAU[3],
			"mj": {"tenue": "cuisinier", "objet": "plateau", "chapeau": "toque"},
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"cuisse_grenouille": 2.5, "champignon": 1.5, "navet_dore": 2.0, "miel": 1.0, "the_menthe": 1.0}, "deteste": {"tourte_montjoie": -0.5, "gelee_slime": -1.5},
			"boutique": {"vend": {"cuisse_grenouille": 5, "cidre_montjoie": 4, "jus_pomme": 3}, "achete": {"cuisse_grenouille": 3, "navet_dore": 3, "champignon": 2, "sardine": 2, "pomme": 1}},
			"tics": ["Croâ ! … Pardon, l'habitude.", "À point !", "Goûte-moi ça !", "Vingt façons, mon ami !"],
			"surnoms": [[0, "voyageur"], [25, "bon client"], [50, "fine gueule"], [75, "habitué"], [95, "ami de la grenouille"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à La Grenouille Repue ! Ulric, aubergiste ! Ici, on cuisine la grenouille géante de vingt façons : rôtie, grillée, en ragoût, en beignets, en croûte, en tarte, en soupe, en… Bon, je te donne la carte. Elle fait trois pages. Toutes des grenouilles.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Tu as faim ? Aujourd'hui, grenouille à la crème. Hier aussi. Mais aujourd'hui, avec plus de crème.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Le lac est calme, les grenouilles se tiennent tranquilles, Yvon m'en a apporté une belle ce matin. Une belle cuisse ! Grande comme mon bras ! J'ai fait des beignets pour tout le quartier.", {"a_trouve": "grenouilles_lac"}, "rire"),
					L("Épatante ! Ma grenouille en croûte a fait pleurer de joie un voyageur. Enfin, peut-être que c'était le poivre. Mais j'ai décidé que c'était la joie.", {}, "rire"),
					L("Le soir, l'auberge se remplit. Ceux qui reviennent du lac racontent qu'ils se sont fait avaler. Je leur sers de la grenouille. C'est une vengeance délicieuse.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mon père tenait l'auberge avant moi. Elle s'appelait « Le Mouton Tranquille ». Un jour, une grenouille géante est entrée par la porte et s'est assise à table. Mon père lui a servi une soupe. Elle a tout mangé, la soupe, la table, la nappe. On a changé le nom.", {}, "rire"),
					L("Vingt recettes de grenouille ! Il m'en manque une vingt et unième, pour faire un compte rond. J'essaie la grenouille au miel. Pour l'instant, elle a goût de grenouille. Avec du miel.", {"sujet_min": ["lui", 1]}),
					L("Mamie Rissole et moi, nous sommes rivaux depuis trente ans. Sa tourte contre ma grenouille. Je vais te dire un secret : sa tourte est meilleure. Un tout petit peu. Si tu le répètes, je te sers une grenouille crue.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Grenouille Repue est dans la Ville-Moyenne, près de la Grand-Place. Tu reconnaîtras l'enseigne : une grenouille avec une serviette autour du cou. C'est mon portrait. Non, c'est une grenouille. Mais elle me ressemble.", {}, "rire"),
					L("Le Lac des Grenouilles est à l'est, derrière la Porte de l'Est. Yvon y pêche, et il me vend les grenouilles qu'il attrape. Enfin, celles qui ne l'attrapent pas d'abord.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Si tu rapportes des cuisses de grenouille géante, je te les achète. Ne les mange pas crues ! Il faut les cuire longtemps, avec du thym. Sinon, elles sautent dans l'assiette. Si, si.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Yvon a peur des grenouilles. Il en pêche tous les jours. Il tremble, il crie, il les ramène. C'est l'homme le plus courageux de Montjoie. Et le plus mouillé.", {}),
					L("Babette me vend ses légumes. Pas ses navets : les navets, elle les garde pour se disputer avec Germaine. Elles se les lancent, parfois. Ça me fait des légumes gratuits.", {}, "rire"),
				],
				"interpelle": [L("Croâ ! … Pardon. Bienvenue à l'auberge !", {"visites_max": 0}, "rire"), L("{surnom} ! Grenouille du jour !", {"visites_min": 1}, "salut")],
				"boutique": [L("Grenouille, cidre, jus de pomme ! Tout est frais, sauf les blagues. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "colombe", "nom": "Colombe", "titre": "couturière", "maison": "porte_colombe", "village": "montjoie",
			"agenda": [[8, 12, "couture_comptoir"], [12, 13, "place_banc_1"], [13, 19, "couture_comptoir"], [19, 21, "auberge_table_2"], [21, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": Y_BRUN, "haut": [0.65, 0.2, 0.35], "robe": [0.65, 0.2, 0.35]},
			"teinte": PEAU[4],
			"mj": {"tenue": "artisan", "objet": "livre"},
			"humeur_base": 0.35, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.55, "rancunier": 0.2},
			"aime": {"plume_ara": 2.5, "plume_perroquet": 2.0, "perle": 2.0, "plume_furie": 2.5, "chapeau_baron": 1.0, "clochette_argent": 1.5}, "deteste": {"gelee_slime": -2.0, "vieille_botte": -1.5},
			"boutique": {"vend": {}, "achete": {"plume_ara": 6, "plume_perroquet": 5, "plume_corbeau": 2, "plume_furie": 9, "perle": 11, "coquillage": 1}},
			"tics": ["Tourne-toi.", "Non, non, non…", "La tenue parfaite…", "Une épingle !"],
			"surnoms": [[0, "mon mannequin"], [25, "ma silhouette"], [50, "ma muse"], [75, "mon chef-d'œuvre"], [95, "ma tenue parfaite"]],
			"repliques": {
				"accueil": [
					L("Ne bouge pas. Tourne-toi. … Hm. Bonjour. Colombe, couturière. Je cherche à dessiner LA tenue d'aventurier parfaite : solide, jolie, qui ne colle pas à la gelée et qui ne prend pas feu. J'en suis à la trois cent douzième esquisse.", {"visites_max": 1}),
					L("{surnom} ! Tu as encore de la gelée sur la manche. Viens ici. Je ne dis rien. Je frotte.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Concentrée. J'ai fait une cape anti-foudre pour Violette. Elle a pris feu au premier éclair. Mais elle a pris feu avec élégance.", {}, "rire"),
					L("Le soir, je dîne à La Grenouille Repue. Pas pour la grenouille : pour regarder les tenues des aventuriers qui rentrent. Ce sont mes meilleurs modèles. Surtout les ratés.", {"soir": true}),
				],
				"lui": [
					L("Je suis arrivée à Montjoie avec une valise de tissus et un rêve : habiller les héros. Le premier héros qui est entré dans ma boutique était Hilaire. Il avait déchiré son pantalon sur un slime. Je l'ai recousu. Il revient chaque semaine. C'est mon meilleur client.", {}, "rire"),
					L("Je fais tous les chapeaux du Baron. Trois cent soixante-cinq. Plus le lapin. Il me commande un chapeau par semaine et en perd deux. C'est une source de revenus très stable.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La tenue parfaite… je crois qu'elle n'existe pas. Chaque aventurier tombe à sa façon. Alors je fais des tenues qui tombent avec eux. Celle d'Églantine, je l'ai cousue à la main, point par point, un hiver entier. Elle ne le sait pas. Elle croit que je l'ai achetée.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ma boutique est sur la Grand-Place, dans la Ville-Moyenne. En vitrine, il y a ma « tenue d'aventurier presque parfaite ». Presque. Il manque une poche. Il manque toujours une poche.", {}),
					L("Les plumes, c'est mon trésor. Une belle plume sur un chapeau, et un débutant ressemble à un héros. Si tu en trouves, des belles, des colorées, je te les achète.", {"sujet_min": ["ile", 1]}),
					L("La gelée de slime, c'est mon ennemie. Elle tache tout, elle ne part jamais, et elle sent la pomme pourrie. Si tu combats le Roi Gélatineux, ne mets pas ta plus belle tenue. Mets la plus moche. Je t'en prête une.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Rodrigue m'a commandé une cape « qui claque au vent même sans vent ». J'y ai mis du fil de fer. Elle claque. Elle claque même quand il dort.", {}, "rire"),
					L("Églantine est ma meilleure amie. Le dimanche, on prend le thé, et elle classe mes boutons par couleur sans s'en rendre compte. Je ne l'arrête pas. Ça la détend.", {}),
				],
				"interpelle": [L("Toi ! Ne bouge pas ! Cette manche…", {"visites_max": 0}), L("{surnom} ! Viens, que je prenne tes mesures !", {"visites_min": 1})],
			}},
		# ================================================================ la garde et la crieuse
		{"id": "ferdinand", "nom": "Capitaine Ferdinand", "titre": "capitaine de la garde", "maison": "porte_ferdinand", "village": "montjoie", "vouvoie": true,
			"agenda": [[6, 9, "caserne"], [9, 12, "rue_1", ["rue_2", "rue_4"]], [12, 13, "caserne"], [13, 17, "rue_5", ["rue_6", "porte_sud", "porte_est"]], [17, 20, "caserne"], [20, 22, "rempart_1"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.2, 0.25, 0.45], "taille": 1.06, "carrure": 1.15},
			"teinte": PEAU[3],
			"mj": {"tenue": "garde", "objet": "epee", "chapeau": "casque"},
			"humeur_base": -0.05, "traits": {"bavard": 0.4, "humour": 0.35, "curiosite": 0.4, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"cafe_vapeur": 2.0, "the_menthe": 1.5, "pain_montjoie": 1.5, "boussole": 1.5, "navet_dore": 1.0}, "deteste": {"gelee_slime": -1.5, "sifflet_muet": -1.0},
			"tics": ["Rapport !", "Encore une alerte…", "Au pas !", "C'est réglementaire."],
			"surnoms": [[0, "citoyen"], [25, "aventurier"], [50, "auxiliaire de la garde"], [75, "lieutenant honoraire"], [95, "pilier de Montjoie"]],
			"repliques": {
				"accueil": [
					L("Halte. Capitaine Ferdinand, de la garde de Montjoie. Rien à signaler. Enfin… trois navets en fuite, un chapeau sur un toit, un slime dans le puits et Gilles qui dort. Comme d'habitude. Rien à signaler.", {"visites_max": 1}),
					L("{surnom}. Repos. Vous n'avez rien vu de suspect ? Un navet qui court ? Un chapeau qui vole ? Un barde qui chante faux ? Ce dernier point n'est pas un délit. Malheureusement.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Débordé. Mélusine a sonné quatre alertes ce matin. Une pour les navets, une pour un slime, une pour le chapeau du Baron, et une pour dire qu'il n'y avait plus d'alerte.", {}),
					L("Le soir, je fais le tour du rempart. Tout est calme. C'est le moment que je préfère : celui où rien ne court.", {"soir": true}),
				],
				"lui": [
					L("Je suis entré dans la garde à dix-huit ans pour protéger Montjoie des dragons. Il n'y a jamais eu de dragon. Il y a eu des navets. Beaucoup de navets. On ne m'avait pas prévenu.", {}, "rire"),
					L("J'ai rédigé le Règlement de la Garde. Quarante articles. L'article douze dit : « Le garde ne dort pas debout. » Je l'ai écrit pour Gilles. Gilles l'a lu. Debout. En dormant.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je fais semblant d'être agacé par les alertes. En vérité, quand la cloche de Mélusine sonne et que toute la ville court aux Champs du Sud, je me sens utile. C'est la seule fois de la semaine où tout le monde m'obéit.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le rempart fait le tour de la Basse-Ville. Trois portes : la Porte Nord vers le Port des Mouettes, la Porte Sud vers les champs, la Porte de l'Est vers le lac. Gilles garde la Porte Nord. Les deux autres, c'est moi. Parfois en même temps.", {}),
					L("Les gobelins du Bois des Lutins sont devenus audacieux. Ils ont un chef, maintenant, avec une bannière. Ils ont volé trois casques à la caserne. Pas les casques : les plumes des casques. Pour décorer la bannière.", {"sujet_min": ["ile", 1]}),
					L("Les jours d'Alerte des Navets, toute la ville court à la Porte Sud. J'ai fait peindre une flèche sur le sol. Les gens la suivent. Les navets aussi, d'ailleurs. Dans l'autre sens.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Mélusine sonne sa cloche pour tout et pour rien. Une fois, elle a sonné l'alerte parce qu'un nuage ressemblait à un dragon. J'ai mobilisé toute la garde. C'était un beau nuage, je dois dire.", {}),
					L("Brunehaut fait les épées de la garde. Elles sont parfaites. Elle a gravé « Ne pas réveiller Gilles » sur celle de Gilles. Elle dit que c'est pour sa sécurité. La sienne ou celle de Gilles, je ne sais pas.", {}, "rire"),
				],
				"interpelle": [L("Halte ! … Ah, un aventurier. Circulez.", {"visites_max": 0}), L("{surnom}. Rapport ?", {"visites_min": 1}, "salut")],
			}},
		{"id": "gilles", "nom": "Gilles", "titre": "garde de la Porte Nord", "maison": "porte_gilles", "village": "montjoie", "vouvoie": true,
			"agenda": [[6, 14, "porte_nord"], [14, 15, "rue_4"], [15, 22, "porte_nord"], [22, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "boucles", "yeux": Y_BLEU, "haut": [0.2, 0.25, 0.45], "taille": 1.04},
			"teinte": PEAU[0],
			"mj": {"tenue": "garde", "objet": "lanterne", "chapeau": "casque"},
			"humeur_base": 0.5, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"pain_montjoie": 2.5, "croissant": 2.0, "tisane_lune": 1.5, "cafe_vapeur": 1.0, "jus_pomme": 1.5}, "deteste": {"gelee_slime": -1.0, "sifflet_muet": -0.5},
			"tics": ["Zzz… Hein ? Halte !", "Je ne dormais pas.", "Bonne journée !", "Tout va bien."],
			"surnoms": [[0, "voyageur"], [25, "l'ami"], [50, "copain"], [75, "mon grand copain"], [95, "mon meilleur ami de la Porte"]],
			"repliques": {
				"accueil": [
					L("Zzz… Hein ? Halte ! Qui va là ? … Oh, bonjour ! Gilles, garde de la Porte Nord. Je ne dormais pas. Je réfléchissais avec les yeux fermés. C'est une technique de garde. Très avancée.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Bonjour ! Vous êtes passé tout à l'heure ? Je ne vous ai pas vu. Je… réfléchissais.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bien ! Honorine m'a envoyé un pain tout chaud. Il sentait si bon que j'ai rêvé de lui. Enfin, j'ai pensé à lui. Éveillé. Debout.", {"q56": "mj_pain=finie"}, "rire"),
					L("Bien ! Il fait beau, la porte est fermée… ouverte… fermée ? Ouverte. Tout va bien.", {}, "rire"),
					L("La nuit, je garde la porte avec ma lanterne. Je compte les étoiles pour rester éveillé. À la quarantième, d'habitude, je m'endors. Je recommence à une.", {"soir": true}),
				],
				"lui": [
					L("Je suis le fils d'un berger. Petit, je gardais les moutons. Je m'endormais, et les moutons se gardaient tout seuls. Quand je suis devenu garde, j'ai pensé que les portes, ce serait pareil. Les portes ne bougent pas. C'est encore mieux que les moutons.", {}, "rire"),
					L("Je m'endors debout depuis toujours. Aubin dit que c'est un talent rare. Père Clotaire dit que c'est une bénédiction. Le Capitaine Ferdinand dit que c'est l'article douze. Moi, je dis que c'est reposant.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Une nuit, un gobelin a essayé d'entrer par la Porte Nord. Je dormais. Il a pensé que j'étais une statue, il a voulu m'emporter, et il n'a pas réussi à me soulever. Il est reparti en pleurant. C'est mon seul exploit. Je ne l'ai pas vu.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("La Porte Nord donne sur le chemin du Port des Mouettes, au nord-ouest. Le Capitaine Isidore vient parfois me dire bonjour. Avec ses mouettes. Elles me picorent le casque. Ça me réveille. C'est gentil de leur part.", {}),
					L("Derrière moi, c'est la Basse-Ville, puis les rampes qui montent en lacets jusqu'au château. Les gens qui sont pressés essaient de grimper tout droit. Ils redescendent tout droit. Sur le derrière.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La nuit, depuis la porte, on voit le phare du Port des Mouettes qui tourne. Une lumière, puis le noir, puis une lumière. C'est comme une berceuse pour les yeux. C'est un problème, pour un garde.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Capitaine Ferdinand m'a écrit un article rien que pour moi dans le règlement. L'article douze. Je suis très fier. Personne d'autre n'a d'article.", {}, "rire"),
					L("Père Clotaire et moi, on a fait un concours de sieste. Personne n'a gagné. On s'est réveillés le lendemain, et on avait tous les deux oublié qu'on faisait un concours.", {}, "rire"),
				],
				"interpelle": [L("Zzz… Halte ! … Bonjour !", {"visites_max": 0}, "rire"), L("{surnom} ! Je ne dormais pas !", {"visites_min": 1}, "salut")],
			}},
		{"id": "melusine", "nom": "Mélusine", "titre": "crieuse publique", "maison": "porte_melusine", "village": "montjoie",
			"agenda": [[7, 12, "place_crieur"], [12, 13, "marche_flane_2"], [13, 18, "place_crieur"], [18, 21, "guilde_tableau"], [21, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "boucles", "yeux": Y_VERT, "haut": [0.75, 0.55, 0.15], "robe": [0.75, 0.55, 0.15], "taille": 1.02, "carrure": 1.1},
			"teinte": PEAU[1],
			"mj": {"tenue": "marchand", "objet": "cloche", "chapeau": "chaperon"},
			"humeur_base": 0.55, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 0.8, "susceptible": 0.35, "rancunier": 0.1},
			"aime": {"clochette_argent": 3.0, "miel": 2.0, "tisane_lune": 1.5, "the_menthe": 1.5, "gateau_miel": 1.5}, "deteste": {"sifflet_muet": -2.5, "gelee_slime": -0.5},
			"tics": ["OYEZ, OYEZ !", "ALERTE !", "Je disais donc…", "DING DING !"],
			"surnoms": [[0, "BONJOUR TOI"], [25, "aventurier"], [50, "mon grand"], [75, "mon héros de la place"], [95, "la plus belle nouvelle de Montjoie"]],
			"repliques": {
				"accueil": [
					L("OYEZ, OYEZ ! UN NOUVEL AVENTURIER EST ARRIVÉ À MONTJOIE ! … C'est toi. Bonjour ! Mélusine, crieuse publique. Les nouvelles, les annonces, les ALERTES : c'est moi. (Elle agite sa grosse cloche.) Et elle, c'est Marguerite.", {"visites_max": 1}, "rire"),
					L("{surnom} ! OYEZ ! … Pardon. Je ne sais plus parler doucement. Bonjour. Ça, c'était doucement.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("EXCELLENTE ! … Pardon. Excellente. J'ai annoncé trois montées de rang, un mariage et une Grande Alerte des Navets. Une matinée parfaite.", {}, "rire"),
					L("Le soir, je vais lire les nouveaux contrats au tableau de la Guilde. Demain matin, je les crierai sur la place. Il faut bien que je répète. Dans ma tête. À voix basse. Enfin, aussi basse que possible.", {"soir": true}),
				],
				"lui": [
					L("Bébé, j'ai crié si fort à ma naissance que la sage-femme a cru à une alerte. Toute la rue est sortie avec des seaux. Ma mère a dit : « Celle-là, elle sera crieuse. » Elle avait raison. Les seaux, on les a gardés.", {}, "rire"),
					L("Ma cloche s'appelle Marguerite. Elle pèse onze kilos. Je l'ai depuis quinze ans. Brunehaut l'a fondue elle-même. Quand je la sonne, on l'entend jusqu'au Lac des Grenouilles. Les grenouilles plongent toutes en même temps. C'est très beau à voir.", {"sujet_min": ["lui", 1]}),
					L("Une fois, j'ai perdu ma voix pendant trois jours. Tout Montjoie est venu me voir. On m'a apporté du miel, des tisanes, des écharpes. Personne ne savait plus ce qui se passait en ville. Ce sont les trois jours où je me suis sentie la plus aimée.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ma place, c'est le coin du crieur, sur la Grand-Place du Marché, dans la Ville-Moyenne. De là, ma voix monte jusqu'au château et descend jusqu'aux remparts. Le Baron dit qu'il n'a pas besoin de journal. Il a Mélusine.", {}),
					L("LA GRANDE ALERTE DES NAVETS ! C'est mon moment ! Quand les navets de Père Gaubert se réveillent, je sonne Marguerite, je crie, et tous les aventuriers courent aux Champs du Sud. On a deux minutes pour les attraper. Après, ils s'enterrent, et ils boudent.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Quand un aventurier monte de rang, c'est moi qui l'annonce à toute la ville. Je dis son nom, son nouveau rang, et un petit compliment. Pour Hilaire, ça fait douze ans que je prépare le compliment. Il est très beau. Il attend.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Capitaine Ferdinand dit que je sonne trop d'alertes. Une fois, une seule fois, j'ai sonné pour un nuage en forme de dragon. Il était VRAIMENT en forme de dragon.", {}, "rire"),
					L("Bertrand chante sur la place pendant que je crie. Il dit que je le couvre. Moi je dis que c'est lui qui fait les chœurs. Nous sommes un duo. Il ne le sait pas encore.", {}, "rire"),
				],
				"interpelle": [L("OYEZ ! TOI ! BONJOUR !", {"visites_max": 0}, "salut"), L("{surnom} ! DING DING ! Bonjour !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("À BIENTÔT ! … Pardon. À bientôt.", {}, "salut"), L("Va ! Et si tu entends Marguerite, cours aux Champs du Sud !", {}), L("BONNE NUIT ! … chut, bonne nuit.", {"soir": true}, "rire")],
			}},
		# ================================================================ la Haute-Ville et le marché
		{"id": "prosper", "nom": "Monsieur Prosper", "titre": "marchand de maisons", "maison": "porte_prosper", "village": "montjoie", "vouvoie": true,
			"agenda": [[9, 12, "agence_bureau"], [12, 14, "chaumiere_jardin"], [14, 18, "agence_bureau"], [18, 20, "haute_banc"], [20, 9, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "haut": [0.5, 0.35, 0.15], "carrure": 0.9, "taille": 0.98},
			"teinte": PEAU[2],
			"mj": {"tenue": "marchand", "objet": "canne", "chapeau": "plume"},
			"humeur_base": 0.45, "traits": {"bavard": 1.0, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"piece_or": 2.5, "rubis": 2.0, "bague": 2.0, "perle": 1.5, "titre_propriete": 1.5}, "deteste": {"vieille_botte": -1.5, "gelee_slime": -1.0},
			"tics": ["Exceptionnel !", "Une affaire en or !", "Croyez-moi.", "Rarissime !"],
			"surnoms": [[0, "cher client"], [25, "cher acheteur"], [50, "cher investisseur"], [75, "cher propriétaire"], [95, "cher ami et voisin"]],
			"repliques": {
				"accueil": [
					L("Ah ! Un client ! Monsieur Prosper, marchand de maisons ! J'ai pour vous une affaire EXCEPTIONNELLE : la Chaumière des Glycines, dans la Haute-Ville ! Un palais ! Un rêve ! Une maison avec un toit ! Presque entier ! Trois cents pièces seulement !", {"visites_max": 1, "q56": "mj_maison="}, "salut"),
					L("{surnom} ! Cher propriétaire ! Comment va votre Chaumière ? Les glycines fleurissent ? Le toit tient ? Le toit tient, croyez-moi. Presque toujours.", {"visites_min": 1, "q56": "mj_maison=finie"}, "rire"),
					L("{surnom} ! La Chaumière vous attend ! Elle m'a demandé de vos nouvelles ce matin. Si, si. Les maisons parlent, quand on sait les écouter. Celle-ci dit « achète-moi ».", {"visites_min": 2, "q56": "mj_maison="}, "rire"),
				],
				"humeur": [
					L("Exceptionnelle ! J'ai vendu une cabane de pêcheur à un voyageur en lui disant qu'elle avait « vue sur le lac ». Elle a vue sur le lac. Et le lac a vue sur elle. Les grenouilles aussi.", {}, "rire"),
					L("Le soir, je m'assois sur le banc de la Haute-Ville et je regarde les maisons. Je les estime. C'est plus fort que moi. Ce banc vaut au moins douze pièces.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai vendu ma première maison à sept ans. C'était une cabane en carton. Je l'ai vendue à ma sœur, contre ses billes. Elle s'est envolée le lendemain. La cabane, pas ma sœur. Ma sœur m'en veut encore.", {}, "rire"),
					L("Ma moustache, je la cire tous les matins avec une cire spéciale. Une moustache bien cirée, c'est une maison bien vendue. Une moustache molle, et les clients voient les fuites du toit.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La Chaumière des Glycines, c'était la maison de ma grand-mère. Je n'arrive pas à la vendre, parce que je raconte trop de choses dessus. Je veux la donner à quelqu'un de bien. Alors j'exagère, pour faire peur aux mauvais acheteurs. Ça marche trop bien.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Chaumière des Glycines est dans la Haute-Ville, près du belvédère. Un lit, une cheminée, une étagère pour vos trophées, et des glycines violettes qui couvrent toute la façade. Exceptionnel ! Et en plus, c'est vrai.", {}),
					L("Avec une maison à Montjoie, vous aurez un lit à vous : quand vous dormirez, vous vous réveillerez reposé, et si vous vous évanouissez sur l'île, c'est chez vous qu'on vous ramènera. Pas au temple, entre deux bancs. Chez vous !", {"sujet_min": ["ile", 1]}),
					L("Mon agence est dans la Haute-Ville, au-dessus de la Grand-Place. Si je n'y suis pas, je suis dans le jardin de la Chaumière. J'arrose les glycines. Elles n'en ont pas besoin. Mais c'est un argument de vente.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("J'ai proposé au Baron de vendre sa tour nord. Une tour vide ! Avec une vue ! Mademoiselle Aurore m'a raccompagné. Je lui envoie des fleurs depuis. Pour la tour. Uniquement pour la tour.", {}),
					L("Hilaire économise pour la Chaumière depuis douze ans. Il a cent quarante pièces. Je lui ai promis qu'il serait le premier prévenu si le prix baisse. J'espère qu'il ne le sera jamais. Le prix ne baissera pas. Mais j'espère pour lui.", {}),
				],
				"interpelle": [L("Cher client ! Une affaire en or !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une proposition exceptionnelle !", {"visites_min": 1})],
			}},
		{"id": "philomene", "nom": "Grand-mère Philomène", "titre": "conteuse", "maison": "porte_philomene", "village": "montjoie",
			"agenda": [[9, 12, "place_banc_1"], [12, 14, "maison"], [14, 17, "place_banc_1"], [17, 19, "puits"], [19, 9, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "yeux": Y_GRIS, "haut": [0.35, 0.3, 0.4], "robe": [0.35, 0.3, 0.4], "robe_longue": true, "vieux": true, "taille": 0.85},
			"teinte": PEAU[1],
			"mj": {"tenue": "paysan", "objet": "canne", "chapeau": "chaperon"},
			"humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.75, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"tisane_lune": 2.5, "miel": 2.0, "gateau_miel": 2.0, "livre_envole": 2.0, "page_grimoire": 1.5, "plume_lune": 1.0}, "deteste": {"cafe_brasier": -1.0, "gelee_slime": -1.0},
			"tics": ["Écoute, mon petit…", "De mon temps…", "C'est une vraie histoire.", "Hé hé hé."],
			"surnoms": [[0, "mon petit"], [25, "mon petit"], [50, "mon petit trésor"], [75, "mon petit héros"], [95, "le héros de mes histoires"]],
			"repliques": {
				"accueil": [
					L("Approche, mon petit. Assieds-toi là. Philomène. On m'appelle Grand-mère, même ceux qui ont soixante ans. Je connais toutes les légendes de l'île. Les vraies, les fausses, et celles de Maître Hugues, qui sont entre les deux.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te revoilà. Tu veux une histoire ? J'en ai une sur un roi en gelée. Ou sur un dragon grand comme une chèvre. Hé hé hé.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien, bien. Mes genoux grincent, mais ma mémoire est huilée. Ce matin, j'ai raconté trois légendes à Noisette. Elle m'en a raconté quatre. Dont une sur moi. Elle était fausse, et très belle.", {}, "rire"),
					L("Le soir, je rentre tôt. Les légendes, il faut les laisser dormir la nuit. Sinon, elles s'agitent et elles changent de fin.", {"soir": true}),
				],
				"lui": [
					L("Je suis née dans la Basse-Ville, il y a quatre-vingt-cinq ans. À l'époque, il n'y avait pas de Guilde, seulement une grande table dans une grange, et les aventuriers y rentraient en boitant. J'étais la petite qui leur demandait de raconter. Je n'ai jamais arrêté.", {}),
					L("Ma fille Germaine est fermière, aux Champs du Sud, avec son Gaubert. Ils se disputent avec Babette pour des navets. Des navets ! De mon temps, on se disputait pour des choses sérieuses. Des choux, par exemple.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Hugues raconte qu'il a vaincu un dragon. J'y étais, moi. Enfin, j'étais au village quand il est revenu. Il portait le dragon sous le bras. Il était grand comme une chèvre. Mais Hugues tremblait comme s'il avait vaincu une montagne. C'était un vrai exploit, pour un garçon de dix-neuf ans.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Donjon des Mille Marches, sous la tour en ruine des Crocs. On raconte qu'un roi peureux a fait tailler ces marches pour fuir la lumière. Il est descendu si bas qu'il est devenu tout mou, tout vert, tout gluant. Et il a gardé sa couronne. Hé hé hé.", {}),
					L("Il y a cinq étages. Les caves gluantes, la salle des pièges, le lac souterrain, la bibliothèque aux coffres qui mordent, et la salle du trône. Au quatrième, une énigme désigne le vrai coffre. Lis-la jusqu'au bout. Les impatients se font mordre.", {"sujet_min": ["ile", 1]}),
					L("Les navets de Gaubert se sauvent au printemps depuis cent ans. Mon grand-père disait qu'une fée avait béni le champ, un jour qu'elle était de mauvaise humeur. Depuis, les navets ont des jambes. Et pas de manières.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Quand Père Clotaire était petit, c'est moi qui le gardais. Il s'endormait déjà partout, même sur la balançoire. Je le réveillais d'un coup de coude. Aujourd'hui encore, quand j'entre au temple, il se réveille en se frottant les côtes.", {}, "rire"),
					L("Odon, au donjon, dit que je me trompe sur le quatrième étage. Il dit que les mimiques ne mordent pas, qu'elles « pincent ». Je lui ai dit de mettre sa main dedans pour vérifier. Il a refusé. J'ai gagné.", {}, "rire"),
				],
				"interpelle": [L("Toi, mon petit. Viens écouter une histoire.", {"visites_max": 0}), L("{surnom} ! J'en ai une nouvelle !", {"visites_min": 1}, "salut")],
			}},
		{"id": "babette", "nom": "Babette", "titre": "marchande de fruits et légumes du marché", "maison": "porte_babette", "village": "montjoie",
			"agenda": [[6, 18, "marche_fruits"], [18, 20, "rue_2"], [20, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "queue", "yeux": Y_BLEU, "haut": [0.35, 0.55, 0.25], "tablier": [0.8, 0.75, 0.6]},
			"teinte": PEAU[1],
			"mj": {"tenue": "marchand", "objet": "panier", "chapeau": "chaperon"},
			"humeur_base": 0.4, "traits": {"bavard": 0.85, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.7, "rancunier": 0.6},
			"aime": {"navet_dore": 2.5, "pomme": 1.5, "graines": 2.0, "miel": 1.5, "jus_pomme": 1.5}, "deteste": {"gelee_slime": -1.5, "vieille_botte": -1.0, "cuisse_grenouille": -1.0},
			"boutique": {"vend": {"pomme": 1, "baies": 1, "champignon": 2, "graines": 2}, "achete": {"navet_dore": 4, "pomme": 1, "baies": 1, "champignon": 1, "noix_coco": 2}},
			"tics": ["Elles sont belles, mes pommes !", "Tout frais !", "Germaine ? Pff.", "Approchez !"],
			"surnoms": [[0, "mon client"], [25, "mon bon client"], [50, "mon chou"], [75, "ma pomme d'amour"], [95, "mon navet d'or"]],
			"repliques": {
				"accueil": [
					L("Approchez, approchez ! Babette, fruits et légumes de Montjoie ! Pommes croquantes, baies sucrées, champignons des bois ! Et les navets dorés, je les achète, moi : à un meilleur prix que Germaine. Elle ne les vend même pas, elle les garde. Pff.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tiens, croque-moi cette pomme. Alors ? Meilleure que celles de Germaine ? Ne réponds pas, je vois ta tête. Oui.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Très bien ! J'ai vendu deux paniers de pommes avant neuf heures, et Germaine n'est pas venue. Une journée parfaite.", {}, "rire"),
					L("Le soir, je remballe mon étal et je fais un tour dans la Basse-Ville. Je regarde les potagers des gens. Je ne critique pas. Je pense, c'est tout. Très fort.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Ma mère tenait cet étal, et sa mère avant elle. Trois générations de Babette. Oui, elles s'appelaient toutes Babette. C'était plus simple pour l'enseigne.", {}, "rire"),
					L("Germaine et moi, ça a commencé il y a dix ans, au concours du plus beau navet de la fête de l'Aube. J'ai gagné. Elle dit que mon navet était peint. Il était juste très bien lavé. Avec un peu de couleur. Pour le lustre.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret. L'hiver où Gaubert est tombé malade, c'est moi qui ai porté les sacs de graines à la ferme, la nuit, sans rien dire. Germaine n'a jamais su qui. Si elle le savait, il faudrait qu'on arrête de se disputer. Et je ne saurais plus quoi faire de mes matinées.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon étal est sur la Grand-Place du Marché, à côté de la fontaine. Le meilleur emplacement de Montjoie. Monsieur Prosper voulait me l'acheter pour y mettre une « boutique de prestige ». Je lui ai offert une pomme. Il est reparti. Avec la pomme.", {}, "rire"),
					L("Les navets dorés, ce sont ceux qu'on attrape pendant la Grande Alerte. Ils brillent un peu, ils sont sucrés, et ils ne courent plus une fois attrapés. Je les achète un bon prix. La Guilde aussi. Mais moi, je souris en plus.", {"sujet_min": ["ile", 1]}),
					L("Les champignons, je les cueille à la lisière du Bois des Lutins, à l'aube. Jamais plus loin : les gobelins ramassent les mêmes. Une fois, on s'est retrouvés nez à nez devant un cèpe. Il est parti avec. J'ai gardé mon panier. Match nul.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Germaine dit que mes pommes ont un goût de vent. Le vent, c'est sain ! Ses pommes à elle ont un goût de navet. Tout a un goût de navet, chez eux.", {}),
					L("Clovis, le meunier, passe tous les jours devant mon étal en revenant de chez Honorine. Il achète une pomme et il soupire. Je crois que ce n'est pas la pomme qui le fait soupirer.", {}, "rire"),
				],
				"interpelle": [L("Approchez ! Tout frais !", {"visites_max": 0}, "salut"), L("{surnom} ! Une pomme ?", {"visites_min": 1}, "rire")],
				"boutique": [L("Tout frais, tout beau, tout de Montjoie ! Tu as {pieces} pièces.", {}, "salut")],
			}},
		# ================================================================ hors les murs : les champs, le lac, le port, le donjon
		{"id": "gaubert", "nom": "Père Gaubert", "titre": "fermier des Champs du Sud", "maison": "porte_gaubert", "village": "montjoie",
			"agenda": [[5, 12, "ferme_champ_1"], [12, 14, "ferme_cour"], [14, 19, "ferme_champ_1"], [19, 5, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BLEU, "haut": [0.45, 0.4, 0.3], "vieux": true, "carrure": 1.05, "taille": 0.96},
			"teinte": PEAU[3],
			"mj": {"tenue": "paysan", "objet": "panier", "chapeau": "bonnet"},
			"humeur_base": 0.35, "traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.3, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"navet_dore": 3.0, "graines": 2.5, "cidre_montjoie": 1.0, "pain_montjoie": 1.5}, "deteste": {"gelee_slime": -1.0, "vieille_botte": -0.5},
			"tics": ["Doucement avec mes petits !", "Ah, mes navets…", "Ça pousse, ça pousse.", "Hé, la terre, c'est la vie."],
			"surnoms": [[0, "mon gars"], [25, "mon gars"], [50, "mon bon gars"], [75, "mon fiston"], [95, "le meilleur attrapeur de navets de l'île"]],
			"repliques": {
				"accueil": [
					L("Bonjour, mon gars ! Gaubert, fermier. Ces champs, c'est ma vie : du blé, des carottes, et des navets. Les navets, ils sont… vivants. Un peu. Au printemps, ils se réveillent et ils se sauvent. Mais ce sont de bons petits. Juste un peu sportifs.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens m'aider ? Les navets dorment, pour l'instant. Parle doucement. Ils ont l'oreille fine. Enfin, ils n'ont pas d'oreilles, mais ils entendent quand même.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Si la cloche de Mélusine sonne, cours aux champs ! Mes navets dorés vont se sauver, et moi, avec mes genoux, je n'en attrape plus un seul. Rapporte-m'en cinq, mon gars. Doucement avec mes petits.", {"q56": "mj_navets="}),
					L("Bien ! Germaine a attrapé trois navets au filet ce matin, avant le petit déjeuner. Je l'ai épousée pour ça. Et pour ses yeux. Mais surtout pour le filet.", {}, "rire"),
					L("Le soir, je rentre à la ferme. Les navets dorment sous la terre. Je leur souhaite bonne nuit. Germaine dit que c'est ridicule. Elle le fait aussi.", {"soir": true}),
				],
				"lui": [
					L("Mon père était fermier, mon grand-père aussi, et les navets se sauvaient déjà. Mon grand-père en a poursuivi un jusqu'au port. Le navet a pris un bateau. On ne l'a jamais revu. On dit qu'il a fondé une famille quelque part.", {}, "rire"),
					L("J'ai rencontré Germaine à la fête de l'Aube, il y a trente-cinq ans. Un navet m'a échappé et lui est tombé dans les bras. Elle l'a attrapé d'une main, sans même regarder. Je me suis dit : c'est elle.", {"sujet_min": ["lui", 1]}),
					L("Je ne les mange pas, mes navets dorés, tu sais. Je les vends, je les donne, mais je ne les mange pas. Quand on a couru derrière quelqu'un pendant trois heures, on finit par s'attacher.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Les Champs du Sud sont au sud de la ville, après la Porte Sud. Ma ferme, mes champs, et le moulin de Clovis, qui tourne quand il y a du vent. Quand il n'y a pas de vent, Clovis souffle dessus. Pour le principe.", {}, "rire"),
					L("La Grande Alerte des Navets, c'est quand ils se réveillent tous en même temps. Une vingtaine ! Ils courent dans tous les sens pendant deux minutes. Après, ils s'enterrent de nouveau et ils boudent. Il faut les attraper avant. D'un petit coup. Pas fort !", {"sujet_min": ["ile", 1]}),
					L("Un navet attrapé devient doré. Ne me demande pas pourquoi. Philomène dit que c'est une bénédiction de fée. Moi je dis qu'ils rougissent d'avoir perdu. Mais en jaune.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Babette, au marché, essaie de me racheter mes navets depuis dix ans. Germaine refuse. Elles se disputent devant moi. Moi, je mange ma soupe et j'attends que ça passe. Ça ne passe jamais.", {}, "rire"),
					L("Ulric m'a demandé des navets pour sa grenouille aux navets. J'ai dit oui. Le navet a refusé. Il s'est sauvé de la marmite. Ulric l'a poursuivi jusqu'à la Grand-Place. Avec sa toque.", {}, "rire"),
				],
				"interpelle": [L("Bonjour, mon gars ! Doucement, ils dorment !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir mes petits !", {"visites_min": 1}, "rire")],
			}},
		{"id": "germaine", "nom": "Germaine", "titre": "fermière, la femme de Père Gaubert", "maison": "porte_germaine", "village": "montjoie",
			"agenda": [[5, 8, "ferme_cour"], [8, 14, "ferme_champ_2"], [14, 16, "marche_flane_2"], [16, 19, "ferme_cour"], [19, 5, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chignon", "yeux": Y_GRIS, "haut": [0.55, 0.3, 0.25], "tablier": [0.7, 0.65, 0.5], "robe": [0.55, 0.3, 0.25], "carrure": 1.1},
			"teinte": PEAU[2],
			"mj": {"tenue": "paysan", "objet": "filet", "chapeau": "chaperon"},
			"humeur_base": 0.15, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.7, "rancunier": 0.6},
			"aime": {"navet_dore": 2.5, "graines": 2.0, "miel": 1.5, "tisane_lune": 1.5, "pain_montjoie": 1.0}, "deteste": {"pomme": -0.5, "gelee_slime": -1.0},
			"tics": ["Hop ! Au filet !", "Babette ? Ne m'en parlez pas.", "Gaubert !", "Ça, c'est du travail."],
			"surnoms": [[0, "mon petit"], [25, "mon petit gars"], [50, "mon brave"], [75, "mon champion"], [95, "mon meilleur filet"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Germaine. La femme de Gaubert, et le filet de la ferme. Si un navet passe, ne bouge pas. Hop ! … Celui-là, je l'avais vu venir. Tu as besoin de quelque chose ? Si c'est Babette qui t'envoie, la réponse est non.", {"visites_max": 1}),
					L("{surnom}. Bonjour. Tu as vu Babette ? Elle a dit quelque chose sur moi ? Non, ne me le dis pas. Si, dis-le-moi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Six navets au filet avant le lever du soleil. Babette n'en a jamais attrapé un seul. Elle les achète. Ce n'est pas pareil.", {}),
					L("Le soir, je raccommode mon filet. Gaubert me raconte sa journée. C'est toujours la même : il a parlé à ses navets. Ils ne lui ont pas répondu. Il est content.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis la fille de Philomène, la conteuse. Petite, j'écoutais ses histoires de héros. Moi, je voulais attraper des choses. N'importe quoi : des papillons, des poules, des courants d'air. J'ai épousé un homme dont les navets se sauvent. C'était le destin.", {}, "rire"),
					L("Mon filet, je l'ai tressé moi-même, il y a trente ans. Il a attrapé des milliers de navets, deux poules, un chapeau du Baron et, une fois, Gaubert. Il dormait dans le champ. Je l'ai pris pour un gros navet. Il ne me l'a jamais pardonné. Si, au bout d'une heure.", {"sujet_min": ["lui", 1]}, "rire"),
					L("L'hiver où Gaubert a été malade, quelqu'un a déposé des sacs de graines devant la ferme, la nuit. Je n'ai jamais su qui. J'ai cherché partout. Si je le savais, je lui dirais merci. Je déteste ne pas savoir à qui dire merci.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La ferme est aux Champs du Sud, au bout du chemin qui sort par la Porte Sud. Il y a la cour, les deux champs, et le moulin de Clovis. Et des navets partout. Partout. Même dans le puits, une fois.", {}),
					L("Pendant la Grande Alerte, ne tape pas les navets trop fort. Un petit coup suffit. Ils se rendent tout de suite, ce sont des froussards. Sauf les gros. Les gros, il faut les prendre de côté.", {"sujet_min": ["ile", 1]}),
					L("Au marché, sur la Grand-Place, il y a l'étal de Babette. Ses pommes sont trop rouges. Je dis ça, je ne dis rien. Mais trop rouges.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Babette raconte que j'ai triché au concours du plus beau navet. Elle, elle a PEINT le sien. Avec de la peinture. Rouge. Un navet rouge ! Tout le monde a vu.", {}),
					L("Clovis, le meunier, apporte sa farine chez Honorine tous les matins. Il revient toujours en souriant. La farine, ça ne fait pas sourire comme ça.", {}, "rire"),
				],
				"interpelle": [L("Attention, il en arrive un ! … Bonjour.", {"visites_max": 0}), L("{surnom}. Bonjour.", {"visites_min": 1}, "salut")],
			}},
		{"id": "clovis", "nom": "Clovis", "titre": "meunier", "maison": "porte_clovis", "village": "montjoie",
			"agenda": [[6, 17, "moulin"], [17, 18, "rue_1"], [18, 20, "place_jeu_1"], [20, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.92, 0.9, 0.86], "carrure": 1.25, "taille": 1.08},
			"teinte": PEAU[0],
			"mj": {"tenue": "artisan", "chapeau": "bonnet"},
			"humeur_base": 0.35, "traits": {"bavard": 0.35, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"pain_montjoie": 2.0, "croissant": 2.0, "pomme": 1.5, "miel": 1.5, "fleur_lune": 2.0}, "deteste": {"gelee_slime": -1.0, "vieille_botte": -0.5},
			"tics": ["Atchoum !", "Ça tourne.", "Pfff… (un nuage de farine)", "Hm, oui."],
			"surnoms": [[0, "l'ami"], [25, "l'ami"], [50, "mon ami"], [75, "mon grand ami"], [95, "mon frère de farine"]],
			"repliques": {
				"accueil": [
					L("(Un nuage de farine.) Atchoum ! … Bonjour. Clovis, meunier. Non, je n'ai pas les cheveux blancs. Enfin, si. Mais en dessous, ils sont bruns. Je crois. Je ne les ai pas vus depuis dix ans.", {"visites_max": 1}, "rire"),
					L("{surnom}. Bonjour. (Il te tape l'épaule : te voilà tout blanc.) Pardon. Ça arrive à tout le monde.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Bien. Le vent souffle, le moulin tourne, la farine coule. Et un navet s'est encore caché dans un sac. Je l'ai moulu. Non ! Je l'ai rendu à Gaubert. Il était tout blanc. Il avait l'air d'un fantôme.", {}, "rire"),
					L("Le soir, je m'assois sur la Grand-Place. Les enfants jouent autour de moi. Ils m'appellent « le bonhomme de neige ». Je ne les détrompe pas.", {"soir": true}),
				],
				"lui": [
					L("J'ai hérité du moulin de mon oncle. Le premier jour, j'ai ouvert la mauvaise trappe, et toute la farine m'est tombée dessus. Depuis, elle ne m'a jamais vraiment quitté. Je suis un meunier permanent.", {}, "rire"),
					L("Chaque matin, je porte la farine chez Honorine. Elle chante en pétrissant. Je reste un moment devant la porte, pour écouter. Je dis que c'est pour reprendre mon souffle. Le sac pèse cinquante kilos. C'est un bon prétexte.", {"sujet_min": ["lui", 1]}),
					L("Je voudrais dire à Honorine ce que je pense d'elle. Mais quand je la vois, je rougis, et la farine… la farine ne cache pas tout. Elle croit que c'est l'effort. C'est l'effort. L'effort de ne rien dire.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon moulin est aux Champs du Sud, à côté de la ferme de Gaubert. On le voit depuis toute la ville. Quand le chapeau du Baron s'envole, il finit souvent accroché à une aile. Je le rends au château. Le Baron me donne un chapeau en remerciement. J'en ai neuf.", {}, "rire"),
					L("Quand il n'y a pas de vent, le moulin ne tourne pas. Alors je souffle dessus. Ça ne sert à rien. Mais Gaubert trouve ça drôle, et les navets ont peur. Ça fait deux bonnes raisons.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le sommet du moulin, c'est l'endroit le plus haut des Champs du Sud. De là-haut, on voit les Crocs, le lac, la mer. Et le chapeau du Baron, quand il passe. Il passe souvent.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Brunehaut m'a battu au bras de fer. Trois fois. La quatrième fois, j'ai éternué de la farine, elle a ri, et j'ai gagné. Elle dit que ça ne compte pas. Moi, je dis que la farine fait partie de moi.", {}, "rire"),
					L("Babette m'offre une pomme chaque soir. Elle me demande comment va Honorine. Je rougis. Elle sourit. Elle sait des choses, Babette.", {}),
				],
				"interpelle": [L("Atchoum ! … Bonjour.", {"visites_max": 0}, "rire"), L("{surnom}. Ça tourne ?", {"visites_min": 1}, "salut")],
			}},
		{"id": "yvon", "nom": "Yvon", "titre": "pêcheur du lac", "maison": "porte_yvon", "village": "montjoie",
			"agenda": [[5, 12, "lac_ponton"], [12, 13, "lac_rive"], [13, 19, "lac_ponton"], [19, 21, "auberge_table_1"], [21, 5, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "courte", "yeux": Y_GRIS, "haut": [0.3, 0.4, 0.45], "vieux": true, "carrure": 0.9},
			"teinte": PEAU[3],
			"mj": {"tenue": "marin", "objet": "canne_peche", "chapeau": "bonnet"},
			"humeur_base": -0.1, "traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.3, "susceptible": 0.6, "rancunier": 0.2},
			"aime": {"sardine": 1.5, "the_menthe": 1.5, "pain_montjoie": 1.5, "tisane_lune": 2.0, "jus_pomme": 1.5}, "deteste": {"cuisse_grenouille": -2.0, "gelee_slime": -1.0},
			"tics": ["Aaah ! … Ah, non, c'est une feuille.", "Elles sont là, je le sens.", "Chut !", "Brrr."],
			"surnoms": [[0, "l'étranger"], [25, "l'ami"], [50, "mon ami"], [75, "mon sauveur"], [95, "le terreur des grenouilles"]],
			"repliques": {
				"accueil": [
					L("AAAH ! … Ah. Un humain. Pardon. Yvon, pêcheur. Je pêche au lac depuis quarante ans. J'ai peur des grenouilles géantes depuis quarante ans. Je pêche quand même. Il faut bien que quelqu'un le fasse. Et je ne sais rien faire d'autre.", {"visites_max": 1}),
					L("{surnom}. Bonjour. Ne bouge pas. … Ça va. C'était une feuille. Elle ressemblait à une grenouille. Tout ressemble à une grenouille, ici.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Les grenouilles géantes sont de plus en plus nombreuses. Elles me volent mes poissons, mes appâts, et une fois, ma barque. Si tu pouvais en chasser quelques-unes… Je te paierai en poissons. Et en reconnaissance éternelle.", {"q56": "mj_grenouilles="}),
					L("Le lac est calme. Trop calme. Je n'aime pas quand c'est calme. Elles préparent quelque chose.", {}),
					L("Le soir, je vais à l'auberge d'Ulric. Il me sert de la grenouille. Je la mange en la regardant dans les yeux. C'est ma petite vengeance.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis né au bord du lac. À six ans, une grenouille géante m'a avalé, avec ma canne et mon seau. Elle m'a recraché trois secondes plus tard. J'ai gardé la canne. J'ai perdu le courage. Depuis, je tremble, mais je reviens.", {}),
					L("J'ai un carnet où je note tous les aventuriers avalés au lac. Hilaire en est à quarante-sept. C'est mon meilleur indicateur. Quand Hilaire se fait avaler, je sais qu'il y a une grenouille. Ça m'évite d'y aller voir.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire une chose. J'ai peur des grenouilles, mais je les trouve belles. Le matin, quand elles sortent la tête de l'eau et que le soleil se lève derrière, c'est le plus beau spectacle du monde. De loin. De très loin.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Lac des Grenouilles est à l'est de Montjoie, par la Porte de l'Est. Il y a des roseaux, un ponton, et des grenouilles grandes comme des charrettes. Une rivière en sort vers la mer, au sud-est. Les grenouilles la descendent pour aller se baigner. Dans la mer. Je ne sais pas pourquoi.", {}),
					L("Les grenouilles bondissent, et elles ont une langue longue comme une corde. Si elles t'avalent, ne te débats pas. Elles recrachent au bout de trois secondes. Si tu te débats, ça dure quatre. C'est pire.", {"sujet_min": ["ile", 1]}),
					L("La plus grosse grenouille du lac, je l'appelle la Duchesse. Elle avale tout ce qui brille. Les bagues, les clés, les boutons, les chapelets. Un jour, il faudra lui ouvrir la bouche pour voir tout ce qu'il y a dedans. Pas moi.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Sœur Pétronille vient prier au bord du lac pour que les grenouilles me laissent tranquille. Une grenouille lui a avalé son chapelet pendant la prière. Je crois que la prière n'a pas marché.", {}),
					L("Le Capitaine Isidore se moque de moi parce que je pêche dans un lac. Il dit que la mer, c'est plus dangereux. Il n'y a pas de grenouilles géantes dans la mer. Seulement des mouettes. Lui, il leur parle.", {}),
				],
				"interpelle": [L("Chut ! Elles écoutent !", {"visites_max": 0}), L("{surnom} ! Tu n'as pas vu de grenouille ?", {"visites_min": 1})],
			}},
		{"id": "isidore", "nom": "Capitaine Isidore", "titre": "maître du Port des Mouettes", "maison": "porte_isidore", "village": "montjoie",
			"agenda": [[6, 12, "port_capitainerie"], [12, 14, "port_poisson"], [14, 19, "port_quai_1"], [19, 21, "port_quai_2"], [21, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "court", "barbe": "longue", "yeux": Y_BLEU, "haut": [0.15, 0.2, 0.4], "vieux": true, "carrure": 1.1},
			"teinte": PEAU[3],
			"mj": {"tenue": "marin", "objet": "lanterne", "chapeau": "bonnet"},
			"humeur_base": 0.35, "traits": {"bavard": 0.75, "humour": 0.65, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"sardine": 2.5, "boussole": 2.0, "journal_bord": 2.0, "coquillage": 1.5, "maquereau": 1.5, "cidre_montjoie": 1.0}, "deteste": {"gelee_slime": -1.0, "sifflet_muet": -1.0},
			"tics": ["Hé, Albertine !", "Par tous les vents !", "Les mouettes l'ont dit.", "Cap au nord !"],
			"surnoms": [[0, "moussaillon"], [25, "matelot"], [50, "mon second"], [75, "mon capitaine"], [95, "l'ami des mouettes"]],
			"repliques": {
				"accueil": [
					L("Ohé, moussaillon ! Bienvenue au Port des Mouettes ! Capitaine Isidore, maître du port. Et voici Albertine, Bigorneau et Pompon. (Trois mouettes te regardent.) Ils disent bonjour. Enfin, Albertine dit bonjour. Bigorneau dit « poisson ». Pompon ne dit rien, il boude.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Albertine t'a vu arriver de loin. Elle a dit : « C'est l'aventurier, il a une bonne tête. » Elle a bon goût, Albertine.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Par tous les vents ! La mer est belle, la barque est amarrée, et Bigorneau a volé un maquereau à la poissonnerie. Encore. Je l'ai payé. Encore.", {}, "rire"),
					L("Le soir, je m'assois au bout du quai et je raconte ma journée aux mouettes. Elles me racontent la leur. Elle est toujours pareille : du poisson, du vent, du poisson.", {"soir": true}),
				],
				"lui": [
					L("J'ai navigué trente ans sur tous les océans. Un jour, une mouette s'est posée sur mon épaule, au milieu de la tempête, et elle m'a regardé. J'ai compris qu'elle me disait de rentrer. Je suis rentré. La tempête a coulé trois navires ce jour-là. C'était Albertine.", {}),
					L("Je comprends les mouettes. Pas les mots, les humeurs. Un cri court, c'est « poisson ». Un cri long, c'est « tempête ». Deux cris et un battement d'ailes, c'est « Bigorneau a encore volé quelque chose ».", {"sujet_min": ["lui", 1]}, "rire"),
					L("Monsieur Prosper m'a vendu une maison « avec vue sur la mer ». C'était le phare. Vide, sans meubles, avec cent quarante marches. J'y habite quand même. La vue est vraiment belle. Mais ne le dis pas à Prosper.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Port des Mouettes est au nord-ouest de l'île, au bout du chemin de la Porte Nord. Les quais, la capitainerie, la poissonnerie, le phare, et le ponton où tu as amarré ta barque. Les mouettes la surveillent. Gratuitement.", {}),
					L("Le Baron a perdu son chapeau dans la mer, une fois. Albertine l'a repêché. Elle l'a gardé trois jours pour y faire un nid. Le Baron a dit que c'était un honneur. Il l'a porté avec un œuf dedans.", {"sujet_min": ["ile", 1]}, "rire"),
					L("D'ici, on voit tout l'archipel par beau temps : le village au nord-ouest, les autres îles plus loin. Les mouettes vont partout. Elles me rapportent des nouvelles. Surtout des nouvelles de poisson.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Yvon pêche dans le lac, avec les grenouilles. Moi, je lui dis : viens en mer ! Il dit que la mer, c'est trop grand. Le lac, c'est petit, mais plein de bouches. Chacun ses peurs.", {}),
					L("Gilles, à la Porte Nord, dort debout. Mes mouettes lui picorent le casque pour le réveiller. Il leur dit merci. Elles l'adorent. Il leur donne ses croûtes de pain.", {}, "rire"),
				],
				"interpelle": [L("Ohé, moussaillon !", {"visites_max": 0}, "salut"), L("{surnom} ! Albertine te salue !", {"visites_min": 1}, "rire")],
			}},
		{"id": "odon", "nom": "Odon", "titre": "gardien du Donjon des Mille Marches", "maison": "porte_odon", "village": "montjoie",
			"agenda": [[7, 20, "donjon_entree"], [20, 7, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "chauve", "yeux": Y_BRUN, "haut": [0.3, 0.28, 0.24], "vieux": true, "carrure": 1.05},
			"teinte": PEAU[2],
			"mj": {"tenue": "aventurier", "objet": "lanterne"},
			"humeur_base": 0.15, "traits": {"bavard": 0.55, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"coeur_gelee": 2.5, "cle_cuivre": 2.0, "tourte_montjoie": 1.5, "cidre_montjoie": 1.0, "lentille_phare": 1.5, "boussole": 1.5}, "deteste": {"gelee_slime": -0.5, "sifflet_muet": -0.5},
			"boutique": {"vend": {"potion_seve": 15, "potion_mana": 10, "tisane_lune": 6}, "achete": {"gelee_slime": 3, "croc_gobelin": 4, "champignon": 2}},
			"tics": ["Je note.", "Étage combien ?", "Prends une corde.", "Hé hé."],
			"surnoms": [[0, "le descendant"], [25, "l'explorateur"], [50, "le plongeur"], [75, "l'abyssal"], [95, "le maître des marches"]],
			"repliques": {
				"accueil": [
					L("Halte. Odon, gardien du Donjon des Mille Marches. Tu veux descendre ? Je note ton nom dans le registre, et l'étage le plus profond que tu atteins. Si tu ne remontes pas, je note aussi. Mais tu remonteras. Il y a des cristaux de retour à chaque étage.", {"visites_max": 1}),
					L("{surnom}. Le registre dit que tu es descendu. Il dit aussi que tu es remonté. C'est la partie que je préfère.", {"visites_min": 2}),
				],
				"humeur": [
					L("Le Roi Gélatineux est vaincu. J'ai écrit ton nom en lettres rouges dans le registre. C'est la première fois depuis trente ans que j'utilise l'encre rouge. Elle avait séché. J'en ai racheté.", {"a_trouve": "roi_gelatineux"}),
					L("Calme. Deux aventuriers sont descendus ce matin. Ils sont remontés au premier étage, couverts de gelée. Comme d'habitude. Le donjon les mange un peu, puis il les recrache.", {}),
					L("Le soir, je ferme la grille et je rentre dans ma cabane. J'écoute le donjon. Il fait « gloup » toutes les dix minutes. C'est le Roi qui respire. Enfin, je crois.", {"soir": true}),
				],
				"lui": [
					L("J'étais dans l'équipe de Hugues, autrefois. Il frappait, moi je portais les cordes, les lanternes et le casse-croûte. Hugues dit que j'étais « le cœur de l'équipe ». Le cœur, et les épaules. Surtout les épaules.", {}),
					L("Il y a trente ans, Hugues a paniqué au troisième étage, devant une grenouille. Il a couru si vite qu'il est remonté sans les cristaux. Je l'ai attendu en bas avec le casse-croûte. Il me le rappelle tous les ans. C'est notre fête.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je garde l'entrée parce que je ne peux plus descendre. Mes genoux. Mais chaque fois que quelqu'un remonte, je lui demande : « Comment c'était ? » Et pendant qu'il raconte, j'y suis encore. Merci de raconter.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le donjon a cinq étages. Un : les Caves Gluantes, des slimes et un petit labyrinthe. Deux : la Salle des Pièges, attention au rocher qui roule, cours. Trois : le Lac Souterrain, des grenouilles. Quatre : la Bibliothèque des Mimiques. Cinq : le Roi. Et sa couronne.", {}),
					L("Au troisième étage, il faut la clé de cuivre pour ouvrir la porte du quatrième. Elle est dans le ventre d'une grenouille. Ne me demande pas comment elle est arrivée là. Les grenouilles avalent tout.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Au quatrième étage, une énigme désigne le vrai coffre. Les autres sont des mimiques. Philomène dit qu'elles mordent. Moi je dis qu'elles pincent. Personne n'a envie de vérifier la différence.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Hilaire est descendu au premier étage cent fois. Le registre dit : « étage 1, a glissé ». Cent fois. Je lui ai proposé de lui écrire « étage 1, très régulier ». Il était ému.", {}, "rire"),
					L("Je vends les potions d'Aubin ici, au pied des Crocs. Elles soignent bien. Elles changent un peu la couleur. Les aventuriers remontent du donjon verts, bleus, roses. On dirait un arc-en-ciel fatigué.", {}, "rire"),
				],
				"interpelle": [L("Toi. Tu descends ?", {"visites_max": 0}), L("{surnom}. Étage combien, aujourd'hui ?", {"visites_min": 1}, "salut")],
				"boutique": [L("Potions et tisanes, pour le fond du trou. Tu as {pieces} pièces.", {})],
			}},
	]

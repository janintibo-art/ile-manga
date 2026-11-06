extends RefCounted
## V115 : les gens du Dôme d'Azur, la ville futuriste posée au fond de la Fosse d'Azur, une fosse
## abyssale au pied des falaises du sud de Hautefond, à cent quarante mètres sous la mer (trop profond
## pour plonger, même avec le masque de plongée : on n'y descend que par la Ligne). Une ville réaliste,
## lumineuse et pleine d'espoir : nacre blanche, verre, titane brossé, lumières aigue-marine, formes
## rondes de coquillages. Trois dômes de verre reliés par deux galeries de verre ; au milieu de la Place
## de la Perle, la Cheminée d'Air (c'est par elle que le Dôme respire ; à la surface, sa bouée-phare) et,
## enfilée dessus, la Grande Perle (le soleil du Dôme : blanc doré le jour, bleu nuit et violet le soir).
## Dehors, la mer profonde, bleu nuit : poissons-lanternes, méduses, raies, et parfois, très haut, la
## Grande Chanteuse, la baleine qu'on entend chanter dans tout le Dôme. La Ligne du Dôme d'Azur (la cage
## de laiton de la Gare des Strates, puis la bulle de verre du Funiculaire d'Azur, dans son long tube de
## verre posé sur des pylônes) vient de rouvrir, après douze ans de travaux : la Colonne relie enfin ses
## quatre mondes de bout en bout (les Nuées, Hautefond, les Strates et le Dôme).
##  - la Gare d'Azur : Marius Trident, chef de gare et conducteur du Funiculaire (vieux correspondant
##    d'Anatole, le liftier des Strates qui gardait la grille, et oncle de Barnabé, l'apprenti liftier
##    de Hautefond qui a le vertige) ;
##  - la Place de la Perle : la Présidente Ondine Nacre (la Maison du Conseil des Marées), Josette
##    Salicorne (La Conque, sans une goutte d'alcool ; cousine de Rosalie Cannelle, au Grand Marché),
##    Ernest Coquillard (le Comptoir des Courants), Yolande Hublot (l'Atelier des Scaphandres), Madame
##    Odile Nautile (l'École des Abysses) et son élève Mila Mérou (10 ans, qui n'a jamais vu le ciel ;
##    née le même jour que Lili Altaïr, aux Nuées) ;
##  - le Dôme de l'Institut : le Professeur Hippolyte Benthos (l'Institut des Abysses ; il parle à la
##    Grande Chanteuse) et Lou Grenadier (la pilote du bathyscaphe jaune « Le Petit Plongeon ») ;
##  - le Dôme des Serres : Mélisande Varech (la jardinière ; « les trois jardinières », avec Flora aux
##    Nuées et Bertille aux Strates).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd), même corps que Néopolis (fiche « neo », pnj_neo_v95.gd), comme aux Nuées : en clair
## et sans implant. Tenue (tailleur | combinaison | techwear | jardinier | service | chef | enfant |
## mecano), c, c2 (les couleurs du Dôme : blanc nacre, aigue-marine, bleu nuit, corail doux, sable,
## titane ; le vert des algues et le jaune du Petit Plongeon), chapeau (casquette | cuisinier | paille |
## beret), objet. Fiche « village » : dome ; groupe : dome ; points de rendez-vous : « da_… ».
## Identifiants : ondine et ernest existent déjà ailleurs dans l'archipel (l'Atlantide, Cliquetis), alors
## on suffixe « _da » : ondine_da, ernest_da ; leur porte reste « porte_<prénom> » (porte_ondine,
## porte_ernest). Les autres gardent leur prénom. Les répliques citent (« a_rencontre ») des gens des
## Strates, de la Fronde, de Hautefond, des Nuées et de l'Atlantide (nerea, ondine).

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bonnes bulles, {surnom} ! Ici, ça veut dire au revoir. Et bonjour. Et merci. Les bulles, ça sert à tout.", "si": {}, "geste": "salut"},
		{"t": "À plus tard ! Et si tout le monde se tait d'un coup, autour de toi, tais-toi aussi : c'est la Grande Chanteuse qui passe au-dessus du Dôme.", "si": {}, "geste": "rire"},
		{"t": "Va ! Et si tu te perds, cherche la Grande Perle : toutes les allées mènent à elle. Même celles qui font semblant que non.", "si": {}},
		{"t": "Bonne nuit ! Regarde : la Grande Perle devient bleu nuit, puis violette. Chez nous, c'est ça, le coucher de soleil.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Au fond de la mer, on tapote les hublots pour dire bonjour aux poissons. Les gens, on les salue de la main !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Attention, ou j'appelle la Présidente Ondine. Elle ne se fâchera pas : elle t'expliquera la pression de l'eau. Pendant une heure.", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Doucement ! Sous un dôme de verre, on apprend à être délicat. Avec tout. Et avec tout le monde.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Merci ! Je vais le poser au bord de mon hublot. Les poissons-lanternes viendront l'admirer.", "si": {}},
		{"t": "Merci, {surnom}. Ici, on dit qu'un cadeau, ça fait remonter le cœur comme une bulle.", "si": {}},
		{"t": "Merci ! Il a voyagé jusqu'ici, celui-là ? Je vais le montrer à tout le monde : « Regardez, ça a vu le ciel ! »", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par la Grande Perle, tu as visé juste, {surnom} !", "si": {}, "geste": "rire"},
		{"t": "Ça, alors ! Ton cadeau brille plus qu'un poisson-lanterne ! Merci, {surnom}. Toute la Place de la Perle va le savoir.", "si": {}, "geste": "rire"},
		{"t": "{dernier_cadeau} ! Tu l'as descendu jusqu'au fond de la mer ? Pour moi ? Cent quarante mètres de gentillesse… Merci, {surnom}.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… Je vais le ranger au fond d'un placard. Tout au fond. Plus au fond que la Fosse.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, personne n'en a jamais eu besoin. Les requins nous regardent, nous les regardons, et chacun reste de son côté de la vitre.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Sous trois dômes de verre, on se croise trois fois par jour. Et son reflet, quatre.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Ici, on ne te demande qu'une chose : ne pas taper sur les vitres. Les méduses sont très sensibles.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Comment un poisson-lanterne retrouve-t-il son chemin ? Il a toujours une idée lumineuse. … Le Professeur Benthos la trouve presque scientifique.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'une bulle dit à une autre bulle, dans la Fontaine ? « Rendez-vous en haut ! » Et l'autre répond : « De toute façon, je ne sais rien faire d'autre. »", "si": {}, "geste": "rire"},
		{"t": "Un voyageur d'en haut demande à Marius : « À quelle heure se lève le soleil, ici ? » Marius regarde sa montre : « Quand Yolande appuie sur le bouton. »", "si": {}, "geste": "rire"},
		{"t": "Que dit une méduse quand elle est contente ? Rien : elle s'allume. … Le Professeur Benthos a mis vingt ans à le comprendre. Il en est très fier.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi la Grande Chanteuse chante-t-elle si fort ? Parce qu'elle chante pour quatre mondes à la fois. … La petite Mila dit que c'est vrai. Elle a vérifié avec un verre contre le hublot.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand l'eau sera redevenue claire entre nous.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Bonnes bulles !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même une bulle ne remonte pas sans un peu d'air.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Sous un dôme, on n'encombre pas : la place est comptée, comme l'air.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}. Même le Petit Plongeon refuserait de le remonter.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et une bulle de la Fontaine en prime ! Elle est gratuite, mais elle est jolie.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu es descendu de si haut. Un petit geste. Ne le dis pas à Ernest, il le répéterait jusqu'aux Nuées.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont calculés comme la pression du Dôme : au gramme près. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. Ici, les murs sont en verre : on voit tout, et on se souvient de tout.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par la Grande Perle !", "Ça bulle !", "Ha ha !", "Quelle merveille !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Pfff…", "Tout est trouble…", "Ça ne bulle plus…"],
		"colere": ["Par toutes les marées !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Bonnes bulles !", "Par la Grande Perle !", "Ça bulle !", "Respire : c'est l'air des Serres."],
	"humeur_mots": [[0.6, "pétillant comme la Fontaine des Bulles"], [0.25, "de bonne humeur"], [-0.25, "un peu trouble"], [-0.6, "d'humeur abyssale"], [-2.0, "au fond du fond de la Fosse"]],
	"surnoms": [[0, "voyageur d'en haut"], [25, "ami des abysses"], [50, "mon camarade de bulle"], [75, "ma perle"], [95, "enfant du Dôme"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.68, 0.32]
const ROUX := [0.82, 0.3, 0.1]
const ARGENT := [0.82, 0.82, 0.86]
const GRIS := [0.6, 0.6, 0.58]
const BLANC := [0.93, 0.92, 0.9]
const BRUN := [0.3, 0.19, 0.11]
const CHATAIN := [0.45, 0.3, 0.17]
const NOIR := [0.08, 0.06, 0.05]
const Y_BLEU := [0.25, 0.45, 0.7]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BRUN := [0.32, 0.2, 0.12]
const Y_GRIS := [0.45, 0.5, 0.55]
const Y_AMBRE := [0.7, 0.48, 0.15]
## Les couleurs du Dôme (les tenues) : la nacre, l'aigue-marine des lumières, le bleu nuit de la mer, le
## corail doux, le sable du fond, le titane brossé ; le vert des algues des Serres et le jaune du Petit
## Plongeon.
const NACRE := [0.95, 0.94, 0.91]
const AIGUE := [0.42, 0.8, 0.78]
const AIGUE_PALE := [0.74, 0.9, 0.88]
const NUIT := [0.1, 0.15, 0.32]
const CORAIL := [0.94, 0.56, 0.5]
const SABLE := [0.86, 0.78, 0.62]
const TITANE := [0.74, 0.76, 0.8]
const ALGUE := [0.36, 0.56, 0.42]
const JAUNE := [0.98, 0.78, 0.16]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			rep[k] = (COMMON[k] as Array).duplicate(true)
	out["repliques"] = rep
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = BASE[k]
	out = Azur.complete(out)
	out["groupe"] = "dome"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Gare d'Azur
		{"id": "marius", "nom": "Marius Trident", "titre": "chef de gare et conducteur du Funiculaire d'Azur", "maison": "porte_marius", "village": "dome",
			"agenda": [[6, 7, "da_gare_guichet"], [7, 12, "da_gare_pupitre"], [12, 13, "da_conque_table_1"], [13, 17, "da_gare_quai"], [17, 20, "da_gare_pupitre"], [20, 22, "da_hublot_1"], [22, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "moustache", "yeux": Y_BLEU, "chapeau": "casquette", "chapeau_c": NUIT, "haut": NUIT, "taille": 1.04, "carrure": 1.3},
			"teinte": PEAU[1],
			"neo": {"tenue": "service", "c": NUIT, "c2": AIGUE, "chapeau": "casquette", "chapeau_c": NUIT},
			"humeur_base": 0.75, "traits": {"bavard": 0.9, "humour": 0.85, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"lettre_azur": 2.5, "carte_postale": 2.0, "chocolat_abysses": 2.0, "chocolat_mineur": 2.0, "biscuit_engrenage": 1.5, "coquillage": 1.5}, "deteste": {"parapluie_helice": -0.5, "vieille_botte": -1.0},
			"tics": ["Plus bas, toujours plus bas !", "Tout le monde descend !", "Regarde dehors, pas tes pieds !", "Anatole dirait : « Comment ? »"],
			"surnoms": [[0, "passager"], [25, "mon voyageur du fond"], [50, "mon matelot de bulle"], [75, "mon second de cabine"], [95, "mon passager en or massif"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au fond ! Marius Trident, chef de la Gare d'Azur et conducteur du Funiculaire ! Tu viens de descendre cent quarante mètres sous la mer dans une bulle de verre. Tu as vu la ville s'allumer dans le bleu ? Douze ans que la ligne était fermée, et je n'ai toujours pas fini de m'émerveiller. Allez, respire : ici, l'air est offert.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu redescends avec moi ? Il y a un banc de poissons-lanternes qui fait la ronde autour du tube depuis ce matin. On dirait qu'ils attendent quelqu'un. Je crois que c'est toi.", {"visites_min": 2}, "rire"),
					L("Te revoilà ! Tu viens plus souvent que mon neveu Barnabé. Lui, il descend les yeux grands ouverts et il remonte les yeux fermés. Toi, tu as l'air de les garder ouverts dans les deux sens. Bravo. C'est rare.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Un peu mouillé du moral. Le tube a fait « toc » toute la matinée. Yolande a cherché la fuite pendant trois heures. Ce n'était pas une fuite : c'était un crabe qui tapait sur la vitre. Il voulait monter. On n'a pas de billet pour les crabes.", {"humeur_max": -0.2}, "rire"),
					L("Au sommet ! Enfin, au fond, mais au sommet ! Douze ans de travaux, {surnom}, et aujourd'hui, trente descentes. Trente ! À chaque fois que la cabine sort de la falaise, les gens font « oh ». Trente « oh ». Je les collectionne.", {}, "rire"),
					L("Un peu enroué. Je fais la visite à chaque descente : « À gauche, la Fosse ! À droite, les Serres ! En bas, la Grande Perle ! » Au bout de trente fois, la voix s'use. Le bleu, lui, ne s'use jamais.", {}),
					L("Ce matin, première descente à sept heures, avec le pain chaud d'en haut et trois touristes encore en pantoufles. La Grande Perle venait de passer au blanc doré. Toute la cabine s'est tue. Même le pain avait l'air ému.", {"matin": true}, "rire"),
					L("Le soir, sur la Promenade des Hublots, je regarde le tube du Funiculaire qui monte dans le noir, tout éclairé, jusqu'à la falaise. Là-haut, au bout du tunnel, il y a Anatole qui ferme sa grille. On ne se voit pas. Mais on se dit bonne nuit quand même.", {"soir": true}),
				],
				"lui": [
					L("Je conduis le Funiculaire depuis trente ans. Mon grand-père le conduisait avant moi, et son père a aidé à poser le premier tube. Dans la famille, on est liftiers de père en fils. Ou en neveu : mon neveu Barnabé est apprenti liftier à Hautefond. Il a le vertige. Il ira loin. Doucement, mais loin.", {}),
					L("Anatole Crémaillère, le liftier des Strates, et moi, on s'écrit depuis trente ans. Pendant les travaux, nos lettres passaient par la petite nacelle de service, avec la spiruline. C'est pratique, l'écrit : il n'a jamais besoin de dire « Comment ? ». Ses lettres font trois lignes. Les miennes, douze pages. On est d'accord sur tout.", {"sujet_min": ["lui", 1]}, "rire"),
					L("J'écris à mon neveu que, chez nous, les baleines passent par le plafond. C'est un peu exagéré : il n'y en a qu'une, et elle passe très haut. Mais quand on écrit à un garçon qui a le vertige, il faut que le fond de la mer lui fasse envie. Ça a marché : il est descendu.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Douze ans de ligne fermée, {surnom}. Chaque matin, je descendais à la gare, j'astiquais la cabine, je tirais le levier pour rien, et je criais : « Tout le monde descend ! » à personne. Les poissons-lanternes venaient voir. Je crois qu'ils m'ont tenu compagnie. Je leur dois une fière chandelle.", {"sujet_min": ["lui", 2]}),
					L("Je vais te dire mon plus beau souvenir. Le jour de la réouverture, Anatole est descendu avec moi, assis à côté du pupitre. En bas, la Grande Chanteuse est passée au-dessus du Dôme. Anatole a posé les mains sur la vitre. Il a fermé les yeux. Il a dit : « Je l'entends. » Lui qui n'entend plus rien ! Il l'a sentie dans les mains, dans les pieds. On a pleuré tous les deux. Dans nos moustaches.", {"sujet_min": ["lui", 3]}),
					L("Tu as vu mon neveu, là-haut ? Barnabé ! Alors tu sais. Il est descendu jusqu'ici sans fermer les yeux une seule fois. Il m'a dit : « Dans l'eau, il n'y a pas de vide, tonton. Il y a du bleu. » Pour la remontée, il a fermé les yeux. Mais il est revenu dimanche.", {"a_rencontre": "barnabe_hf"}, "rire"),
				],
				"ile": [
					L("Le Funiculaire d'Azur, c'est la plus belle descente de l'archipel. On part de la Gare des Strates, dans une cage de laiton, on tire le levier, et on s'enfonce dans la roche. Puis la cabine sort de la falaise, et là… toute la ville sous ses trois dômes, qui luit dans le bleu. Trente ans que je la fais. Je retiens encore mon souffle.", {}),
					L("La cabine, c'est une bulle de verre de six mètres. Elle descend dans un long tube de verre, posé sur des pylônes, au-dessus de la Fosse. Les gens ont peur, au début. Puis une raie passe sous leurs pieds, et ils oublient d'avoir peur. Les raies sont très douées pour ça.", {"sujet_min": ["ile", 1]}),
					L("La Colonne relie quatre mondes, maintenant, de bout en bout : la Cité des Nuées tout en haut, Hautefond, les Strates, et nous, tout au fond de la mer. Quatre mondes, trois lignes, toutes ouvertes en même temps ! Le Bourgmestre Hector en a pleuré pendant son discours. Le discours a duré deux heures. Il a pleuré une heure et demie.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Le soir, depuis la Promenade, on voit le tube du Funiculaire tout éclairé qui monte vers la falaise. On dirait une guirlande accrochée au fond de la mer. Les poissons-lanternes le suivent jusqu'au tunnel. Ils ont compris l'horaire. Ils sont plus ponctuels que certains passagers.", {"sujet_min": ["ile", 3]}, "rire"),
					L("Tu as vu Maîtresse Capucine, la Grande Liftière ? Elle est descendue pour la réouverture. Elle a tapoté la vitre de la cabine du bout des doigts, elle a écouté, et elle a dit : « Elle est bien élevée. » Moi, j'ai rougi. La cabine aussi, je crois. Enfin, c'était le reflet de la Grande Perle.", {"a_rencontre": "capucine_hf"}),
				],
				"rumeur": [
					L("Les rails du Funiculaire, ce sont Rivet et Bielle, de la Fronde, qui les ont posés. Pendant des mois. Le dernier jour, ils ont peint la dernière traverse en violet. Je ne l'ai pas repeinte. Quand la cabine passe dessus, je fais « boum-tchak ». C'est plus fort que moi.", {"a_rencontre": "rivet_fr"}, "rire"),
					L("Ernest, du Comptoir des Courants, attend le dernier funiculaire tous les soirs, sur le banc de la Gare. Il dit qu'il « prend l'air ». Il prend surtout les nouvelles. Il interroge chaque passager. Certains remontent tout de suite, rien que pour souffler.", {}, "rire"),
					L("La petite Mila vient s'asseoir sur le banc de la Gare après l'école. Elle demande à chaque voyageur : « C'est comment, le ciel ? » Personne ne répond pareil. Elle note tout dans un cahier. Il est déjà plus épais que le règlement de la ligne.", {}),
					L("Un vieux marin de Hautefond, Léon, est descendu « pour voir si ça mouille ». Il a touché la vitre du tube, il a regardé son doigt. Sec. Il a dit « Hm. » Puis il est resté deux heures sur le banc à regarder les poissons. En repartant, il a encore dit « Hm ». Mais plus doucement.", {"a_rencontre": "leon_hf"}, "rire"),
					L("Le vieux Ferdinand, du Petit Train des Strates, n'avait jamais vu la mer. Il est descendu avec moi. Il a regardé dehors du premier au dernier mètre, sans un mot. En bas, il m'a demandé : « Je l'ai vue par en dessous. Ça compte ? » J'ai dit oui. Il a dit : « Alors il me reste à la voir par au-dessus. »", {"a_rencontre": "ferdinand_st"}),
					L("Tu es passé à la Gare des Strates ? Anatole y garde la grille du Funiculaire. Pendant douze ans, il l'a huilée tous les soirs, au cas où. Il m'écrivait : « Grille huilée. Toujours fermée. Toujours prête. » Trois lignes. Douze ans. J'ai toutes les lettres. Je les relis quand la cabine est en retard. C'est-à-dire jamais. Alors je les relis quand même.", {"a_rencontre": "anatole"}),
				],
				"interpelle": [L("Hé ! Toi, là ! Je parie que tu n'as jamais vu une raie de près !", {"visites_max": 0}, "salut"), L("{surnom} ! Prochain départ dans deux minutes ! Regarde dehors, pas tes pieds !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bonnes bulles, {surnom} ! Et si tu croises Barnabé, là-haut, dis-lui que son vieil oncle lui garde la place près de la vitre.", {}, "salut"), L("À plus ! Moi, je remonte. Puis je redescends. Puis je remonte. Cent quarante mètres de bonheur, aller-retour !", {}, "rire"), L("Bonne nuit ! Dernier départ à vingt heures. Après, la cabine dort dans sa gare, toute ronde, comme une bulle qui aurait décidé de rester.", {"soir": true})],
				"souvenir": [L("Me souvenir de toi ? Comment veux-tu que j'oublie ! Tu as collé ton nez à la vitre pendant toute la descente. Il y a encore la marque. Je ne l'ai pas effacée.", {}, "rire")],
			}},
		# ================================================================ la Maison du Conseil des Marées
		{"id": "ondine_da", "nom": "la Présidente Ondine Nacre", "titre": "présidente du Conseil des Marées", "maison": "porte_ondine", "village": "dome", "vouvoie": true,
			"agenda": [[7, 8, "da_conseil_balcon"], [8, 12, "da_conseil_bureau"], [12, 13, "da_conque_table_2"], [13, 14, "da_jardin_banc"], [14, 18, "da_conseil_bureau"], [18, 20, "da_conseil_balcon"], [20, 22, "da_belvedere_banc"], [22, 7, "maison"]],
			"azur": {"cheveux": ARGENT, "coiffure": "chignon", "yeux": Y_GRIS, "haut": NACRE, "robe": AIGUE_PALE, "robe_longue": true, "foulard": AIGUE, "taille": 1.04},
			"teinte": PEAU[5],
			"neo": {"tenue": "tailleur", "c": NACRE, "c2": AIGUE},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"bocal_nuage": 3.0, "perle_azur": 2.0, "coquillage": 2.0, "perle": 2.0, "the_sommets": 1.5, "carte_postale": 1.5}, "deteste": {"bombe_peinture": -1.0, "vieille_botte": -1.0},
			"tics": ["Respirons.", "La mer a le temps.", "Dans cent ans, on dira…", "Doucement, comme la marée."],
			"surnoms": [[0, "cher visiteur"], [25, "cher hôte des profondeurs"], [50, "cher ami du Dôme"], [75, "ma perle rare"], [95, "citoyen d'honneur des abysses"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au Dôme d'Azur. Ondine Nacre, présidente du Conseil des Marées. Vous êtes à cent quarante mètres sous la mer, sous trois dômes de verre, et vous respirez un air que nos algues ont fait ce matin. Respirez. Doucement. Voilà. Ici, la première chose qu'on apprend, c'est à ne jamais se presser.", {"visites_max": 1}, "salut"),
					L("{surnom}. Quel plaisir. Asseyez-vous un instant : j'ai deux dossiers, une réunion, et une pétition de la petite Mila. Je commence par la pétition. Elle est écrite au crayon bleu, avec des étoiles dans les marges.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Vous revenez si souvent que le Conseil envisage de vous offrir un hublot. C'est le plus grand honneur du Dôme. Le dernier a été décerné à une raie qui venait tous les jours.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Trouble, je l'avoue. Le Conseil a débattu trois heures pour savoir s'il fallait repeindre la Fontaine des Bulles. Elle est en verre. Avec de l'eau dedans. Nous avons voté pour la laisser comme elle est. Trois heures pour ne rien changer : c'est un très bon Conseil.", {"humeur_max": -0.2}, "rire"),
					L("Sereine. La ligne a rouvert, l'air est bon, les Serres débordent, et la Grande Chanteuse est passée deux fois cette semaine. Quand tout va bien, je n'ai rien à présider. C'est le signe d'un Conseil qui travaille.", {}),
					L("Assiégée, mais ravie. Depuis que la ligne a rouvert, tout le monde veut me voir : des savants, des touristes, des cousins perdus de vue depuis douze ans. Je les reçois tous. Douze ans de cousins, cela fait beaucoup de thé.", {}, "rire"),
					L("Chaque matin, depuis le balcon du Conseil, je regarde la Grande Perle passer du bleu au blanc doré. Le Dôme se réveille sous mes yeux, maison-bulle après maison-bulle. Je ne m'en lasse pas. C'est un lever de soleil que nous avons fabriqué nous-mêmes. Il n'en est que plus beau.", {"matin": true}),
					L("Le soir, je m'assois au Belvédère des Abysses et je regarde le noir, au fond de la Fosse. On croit qu'il est vide. Il ne l'est pas. De petites lumières y passent, très loin. Personne ne sait encore ce que c'est. J'aime qu'il reste des choses qu'on ne sait pas.", {"soir": true}),
				],
				"lui": [
					L("J'étais océanographe, avant d'être présidente. Trente ans à l'Institut, à mesurer les courants, compter les méduses, écouter la Fosse. Un jour, le Conseil m'a demandé de le présider. J'ai dit : « Je vais réfléchir. » La mer a le temps. Moi aussi. J'ai réfléchi un an.", {}),
					L("Ma grand-mère, Amélie Nacre, a dessiné le Grand Dôme sur une nappe de restaurant, à Hautefond, il y a quatre-vingts ans. Tout le restaurant a ri. Puis elle l'a construit. La nappe est encadrée dans mon bureau. Il y a une tache de soupe sur la Fosse. Je ne l'ai jamais fait nettoyer.", {"sujet_min": ["lui", 1]}),
					L("On dit « Conseil des Marées », alors qu'à cent quarante mètres, il n'y a pas de marées. Ce sont nos fondateurs qui l'ont voulu : une bonne décision, disaient-ils, c'est comme la marée. Elle monte lentement, et elle revient toujours. J'essaie de décider comme cela. Cela prend du temps. Cela tient longtemps.", {"sujet_min": ["lui", 2]}),
					L("Puis-je vous confier quelque chose, {surnom} ? Dans mon tiroir, il y a un carnet. Chaque soir, j'y écris une phrase pour ceux qui vivront ici dans cent ans. Hier : « Ce jour, des enfants d'en haut ont pleuré de joie devant un poisson-lanterne. » Je voudrais qu'ils sachent que nous avons été heureux, ici.", {"sujet_min": ["lui", 3]}),
					L("Vous avez rencontré une petite Ondine, sous une autre bulle ? Une Atlante ? (Elle sourit.) Alors je ne suis plus la seule. J'espère qu'elle est moins têtue que moi à son âge. Et j'espère qu'un jour, elle viendra prendre le thé ici. Ou que nous irons chez elle.", {"a_rencontre": "ondine"}),
				],
				"ile": [
					L("Le Dôme d'Azur, ce sont trois dômes de verre posés au fond de la Fosse : le Grand Dôme, avec la Place de la Perle ; le Dôme des Serres, à l'ouest ; et le Dôme de l'Institut, à l'est. Deux galeries de verre les relient. Dehors, la mer, bleu nuit. Dedans, six cents personnes qui ont décidé de vivre dans la mer sans la déranger.", {}),
					L("Nous sommes le plus jeune des quatre mondes, et le plus profond. Les Nuées ont le ciel, Hautefond a la vue, les Strates ont les mains, paraît-il. Nous, nous avons la mer. Et l'air : nos algues en font tant qu'il en remonte un peu, par le tunnel de la Ligne, jusqu'aux galeries des Strates. Les mineurs disent que, le matin, cela sent la mer.", {}),
					L("La Cheminée d'Air, cette colonne blanche, monte du milieu de la Place jusqu'à la surface. C'est par elle que nous respirons. Là-haut, une bouée-phare la signale aux bateaux. Et la Grande Perle, enfilée dessus, fait notre soleil : blanc doré le jour, bleu nuit et violet le soir. Nous avons tout fabriqué. Même le coucher de soleil.", {"sujet_min": ["ile", 1]}),
					L("Les vieilles cartes parlent d'une cité engloutie, l'Atlantide, quelque part au nord-est de l'archipel, sous une bulle d'air. Nos savants étudient ses légendes depuis quatre-vingts ans. Nous l'appelons « notre cousine ». Personne ici ne l'a jamais vue. Mais nous lui gardons une chaise, au Conseil. On ne sait jamais.", {"sujet_min": ["ile", 2]}),
					L("La Colonne relie quatre mondes, et quatre conseils : le Bourgmestre Hector à Hautefond, la Première Conseillère Céleste aux Nuées, la Doyenne Agathe aux Strates, et moi, tout en bas. Le jour de la réouverture, nous avons coupé le ruban à quatre. Trente centimètres de ruban, quatre paires de ciseaux : sept centimètres et demi chacun. Le Bourgmestre a demandé un huitième centimètre.", {"sujet_min": ["ile", 3]}, "rire"),
				],
				"rumeur": [
					L("Céleste Altaïr, aux Nuées, m'envoie des nuages en bocal. Ils arrivent vides : un nuage ne supporte pas la pression, paraît-il. J'ai toute une étagère de bocaux vides. Le soir, je les regarde. Ils contiennent l'intention. C'est ce qui compte.", {}),
					L("Le Bourgmestre Hector, vous le connaissez ? Pour la réouverture, il avait préparé un discours de deux heures. Sous la mer, le son porte loin : on l'a entendu jusqu'à l'Institut. Les poissons-lanternes se sont rassemblés contre les vitres pour écouter. Le Bourgmestre est persuadé qu'ils ont applaudi. Je ne l'ai pas détrompé.", {"a_rencontre": "hector_hf"}, "rire"),
					L("Le Professeur Benthos était mon élève, à l'Institut. Puis il est devenu mon maître. Puis il est devenu distrait. Il oublie de manger, il parle à une baleine, et il a un jour fait tomber sa cravate dans l'Aquarium. Les méduses l'ont gardée trois jours. C'est le plus grand savant que je connaisse.", {}, "rire"),
					L("Brasero, le vieux de la Fronde, m'a écrit : « Quatre mondes, et pas une seule assemblée commune. » Il a raison. Je lui ai répondu : « Venez. Nous nous assiérons autour de la Fontaine des Bulles. » Il voulait un feu. Sous la mer, un feu, c'est compliqué. Nous négocions.", {"a_rencontre": "brasero"}, "rire"),
					L("La Doyenne Agathe, aux Strates, m'a écrit une ligne par mois pendant les douze ans de travaux : « Tenez bon. » Cent quarante-quatre « Tenez bon ». Je les ai tous gardés. Le jour de la réouverture, elle m'a serré la main et elle a dit : « Bien tenu. » Je n'ai jamais reçu de plus beau compliment.", {"a_rencontre": "agathe_st"}),
				],
				"interpelle": [L("Bonjour. Prenez le temps de respirer : vous êtes arrivé.", {"visites_max": 0}, "salut"), L("{surnom}. Venez, la mer est belle aujourd'hui.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bonnes bulles, {surnom}. Et remontez doucement : les meilleures choses, ici, se font à la vitesse de la marée.", {}, "salut"), L("Au revoir. Si la petite Mila vous demande des nouvelles de sa pétition, dites-lui qu'elle est à l'étude. Très sérieusement.", {}, "rire"), L("Bonsoir, {surnom}. La Perle devient violette. Mon carnet m'attend : j'ai une phrase à écrire pour dans cent ans. Vous y serez peut-être.", {"soir": true})],
				"souvenir": [L("Me souvenir de vous ? Comment vous oublier ? C'était le jour où la Grande Chanteuse est passée trois fois. Je l'ai écrit dans mon carnet : « Un voyageur, et trois chants. » C'était une bonne journée.", {})],
			}},
		# ================================================================ la Place de la Perle
		{"id": "josette", "nom": "Josette Salicorne", "titre": "cuisinière de La Conque", "maison": "porte_josette", "village": "dome",
			"agenda": [[5, 7, "da_conque_cuisine"], [7, 14, "da_conque_comptoir"], [14, 15, "da_place_banc_1"], [15, 17, "da_conque_cuisine"], [17, 22, "da_conque_comptoir"], [22, 5, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "boucles", "yeux": Y_BRUN, "haut": NACRE, "tablier": CORAIL, "foulard": AIGUE, "taille": 0.96, "carrure": 1.3},
			"teinte": PEAU[4],
			"neo": {"tenue": "chef", "c": NACRE, "c2": CORAIL, "chapeau": "cuisinier", "objet": "plateau"},
			"femme": true,
			"humeur_base": 0.7, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.35, "rancunier": 0.05},
			"boutique": {"vend": {"soupe_salicorne": 3, "chocolat_abysses": 3, "limonade_bleue": 2, "chocolat_chaud": 3}, "achete": {"dorade": 6, "maquereau": 4, "merou": 16, "galette_algue": 3, "cacao": 3, "miel": 4, "dattes": 2}},
			"aime": {"galette_algue": 2.5, "cacao": 2.5, "miel": 2.0, "dattes": 2.0, "chocolat_mineur": 1.5, "mandarine_lampes": 1.5}, "deteste": {"soda_neon": -1.5, "gelee_slime": -1.0},
			"tics": ["Goûte !", "Ça sent la mer ?", "À table, tout le monde !", "Rosalie dirait « goûte, goûte »."],
			"surnoms": [[0, "mon poisson"], [25, "ma crevette"], [50, "mon petit oursin"], [75, "ma perle de cuisine"], [95, "mon trésor des abysses"]],
			"repliques": {
				"accueil": [
					L("Entre, entre, ne reste pas sur le seuil, tu bouches la spirale ! Bienvenue à La Conque, mon poisson. Josette Salicorne, cuisinière. Ici, on mange la mer : soupe de salicorne, galettes de salicorne, poisson du Bassin, et pour finir, un chocolat des abysses, noir comme la Fosse. Pas une goutte de boisson forte : sous la mer, on garde la tête claire. Goûte !", {"visites_max": 1}, "rire"),
					L("{surnom} ! Te voilà ! Assieds-toi au bord de la coquille, la table du hublot est libre. Les poissons-lanternes viennent y regarder les miettes. Seulement regarder : il y a une vitre entre vous.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Ta place t'attend, ta soupe aussi, et ta cuillère est déjà sur la table. Je l'avais posée hier, au cas où. Elle t'a attendu toute la nuit.", {"visites_min": 4}),
				],
				"humeur": [
					L("Contrariée. Ma grande marmite a fait des bulles toute seule ce matin, sans feu dessous. Yolande dit que c'est la pression. Moi, je dis qu'elle imite la Fontaine. Je l'ai grondée. Elle continue.", {"humeur_max": -0.2}, "rire"),
					L("Ravie ! Deux cents bols de soupe de salicorne depuis ce matin, et des gens d'en haut qui découvrent le goût de la mer. Ils font une drôle de tête à la première cuillère. À la deuxième, ils ferment les yeux. À la troisième, ils me demandent la recette.", {}, "rire"),
					L("Un peu frustrée. Ici, l'air est filtré par les algues : il est pur, mais il efface les parfums. La cannelle ne sent presque rien, la vanille non plus. Alors je cuisine avec ce qui ne s'envole pas : le sel, l'iode, l'algue, le citron des Lampes. Les goûts qui tiennent bon.", {}),
					L("Le matin, à cinq heures, j'allume les fourneaux au cœur de la coquille. La chaleur monte le long de la spirale, la soupe chante, et les premiers clients arrivent en pyjama, guidés par leur nez. Le Professeur Benthos, lui, n'arrive que vers treize heures. Le nez dans son carnet. Guidé par rien du tout.", {"matin": true}, "rire"),
					L("Le soir, La Conque est pleine. Ça parle de la ligne, de la Chanteuse, des gens d'en haut. Marius raconte ses descentes, Ernest raconte les nouvelles, et moi, je remplis les bols. Une coquille, c'est fait pour garder les voix au chaud.", {"soir": true}),
				],
				"lui": [
					L("Mes parents relevaient les nasses du Bassin. Ils remontaient des poissons tout bleus, tout luisants. Moi, je voulais savoir quel goût ils avaient. Ma mère disait : « Le goût de la mer, ma fille. » J'ai passé ma vie à vérifier. Elle avait raison, mais il y a mille façons de l'avoir.", {}),
					L("Rosalie Cannelle, au Grand Marché de Hautefond, c'est ma cousine. Nos mères étaient sœurs. La sienne est restée en haut avec les épices ; la mienne est descendue épouser un pêcheur. Rosalie dit « goûte, goûte ». Moi, je dis « goûte » une seule fois. Sous la mer, on économise l'air.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux le secret de ma soupe de salicorne ? La salicorne pousse dans les bacs d'eau salée des Serres, chez Mélisande. Je la cueille le matin, je la fais revenir avec un oignon, un bouillon de poisson, une pointe de citron des Lampes… et je la laisse écouter la Grande Chanteuse. Les jours où elle est passée, la soupe est meilleure. C'est prouvé. Par le Professeur Benthos, en plus.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Je vais te dire pourquoi La Conque ne ferme jamais, {surnom}. Pendant les douze ans de ligne fermée, le Dôme s'est senti un peu seul au fond de la mer. Alors j'ai allumé ma marmite tous les soirs, même les jours de fête, même les jours de rien. Tant qu'une marmite fume quelque part, personne n'est vraiment seul. C'est ma règle.", {"sujet_min": ["lui", 3]}),
					L("Tu connais Honorine Lanterne, à La Marmite des Strates ? On s'échange nos recettes depuis vingt ans. Elle m'a envoyé son chocolat du mineur, celui où la cuillère tient debout. Je lui ai envoyé ma soupe de salicorne. Elle m'a répondu : « Ça goûte la mer. » Venant de quelqu'un qui vit sous la roche, c'est un très grand compliment.", {"a_rencontre": "honorine_st"}),
				],
				"ile": [
					L("La Conque, c'est la coquille en spirale, au nord-est de la Place de la Perle. La cuisine est au cœur, les tables tout autour, en colimaçon. Quand je crie « À table ! », ma voix fait le tour de la coquille et me revient. Je l'entends deux fois. Ça m'oblige à rester aimable.", {}, "rire"),
					L("Tout ce qui est dans mes bols vient du Dôme : la salicorne et les citrons des Serres, la spiruline du mur des algues, le poisson des nasses du Bassin. Sauf le cacao. Celui-là, c'est Ernest qui le fait descendre. Il dit que c'est un secret. Il le dit à tout le monde.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La limonade bleue, c'est ma fierté. Du citron des Lampes, l'eau fraîche de la Cheminée, et une cuillère de spiruline : elle devient bleue comme le Bassin. Les enfants d'en haut la regardent longtemps avant de la boire. Ils croient que c'est de la mer en bouteille. Un peu, oui.", {"sujet_min": ["ile", 2]}),
					L("Quatre mondes, une seule Colonne… et bientôt une seule soupe ! Honorine et moi, on va faire la soupe des quatre mondes : ses champignons des Strates, mes algues du Dôme, les pommes des Vergers de Hautefond, et les fraises des Nuées pour le dessert. Une seule grande table sur la Place de la Perle. Même le Bourgmestre aura un bol. Surtout le Bourgmestre : ça l'occupera pendant son discours.", {"sujet_min": ["ile", 3]}, "rire"),
					L("Firmin du Piston Joyeux, Gustave du Café Cumulus et Honorine de La Marmite se disputent le meilleur chocolat de la Colonne. Ils sont descendus tous les trois goûter mon chocolat des abysses. Ils ont dit « pas mal » en même temps. Puis ils se sont disputés pour savoir qui l'avait dit le premier.", {"a_rencontre": "firmin"}, "rire"),
				],
				"rumeur": [
					L("Tu as vu ma cousine Rosalie, au Grand Marché ? Elle est arrivée par le premier Funiculaire, avec un sac de cannelle grand comme elle. « Je vais vous réveiller le nez ! » Elle l'a ouvert au milieu de la Place de la Perle. Toute la ville a éternué en même temps. Le Professeur Benthos a dit que c'était une expérience très réussie.", {"a_rencontre": "rosalie_hf"}, "rire"),
					L("Le Professeur Benthos oublie de manger. Tous les jours. Alors, à treize heures, je lui garde un bol et une place. Il arrive en parlant de baleine, il mange en parlant de baleine, et il repart en disant : « Je n'avais pas faim. » Il a pris deux bols.", {}, "rire"),
					L("Mélisande, aux Serres, parle à ses salades. Je lui ai dit que ça ne servait à rien. Puis j'ai goûté ses salades. Depuis, je parle à mes soupes. Ça ne sert à rien non plus. Mais elles sont meilleures.", {}, "rire"),
					L("Ernest vient manger à midi et repart avec plus de nouvelles qu'il n'en a apporté. Il interroge mes clients entre deux cuillères. J'ai mis un panneau : « Ici, on mange. Les nouvelles, c'est au dessert. » Depuis, il prend un dessert à chaque repas.", {}, "rire"),
					L("Mémé Gamelle, de la Cantine Libre, à la Fronde, m'a écrit pour savoir si mes soupes étaient « à prix libre ». Je lui ai répondu : à prix doux, et à cœur grand ouvert. Elle m'a envoyé une louche. Pas Excalibur, bien sûr : Excalibur ne quitte jamais la Fronde. Sa petite sœur. Elle s'appelle Durandal.", {"a_rencontre": "gamelle"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Viens sentir ! … Ça ne sent rien ? C'est normal, ici. Alors viens goûter !", {"visites_max": 0}, "salut"), L("{surnom} ! La limonade est bleue et la soupe est chaude ! Dépêche-toi !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bonnes bulles, mon poisson ! Et reviens ce soir : je fais des galettes de salicorne. Elles croustillent comme des vagues.", {}, "salut"), L("File ! Et si tu remontes, dis à Rosalie que la Place a enfin fini d'éternuer.", {}, "rire"), L("Bonne nuit ! La Perle devient violette, et ma marmite s'endort. Elle fait encore une bulle ou deux. Elle rêve.", {"soir": true})],
				"souvenir": [L("Mon poisson, comment t'oublier ? Ta première cuillère de soupe de salicorne : les yeux ronds, puis tout fermés. Comme tout le monde. Mais toi, tu as souri.", {})],
				"boutique": [L("Soupe de salicorne, limonade bleue à la spiruline, chocolat des abysses, et chocolat tout court pour les prudents ! Tout est cuisiné dans la coquille, sans une goutte de boisson forte. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "ernest_da", "nom": "Ernest Coquillard", "titre": "marchand du Comptoir des Courants", "maison": "porte_ernest", "village": "dome",
			"agenda": [[7, 8, "da_comptoir_reserve"], [8, 12, "da_comptoir"], [12, 13, "da_conque_table_3"], [13, 18, "da_comptoir"], [18, 20, "da_gare_banc_1"], [20, 21, "da_conque_table_3"], [21, 7, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chauve", "barbe": "courte", "yeux": Y_BRUN, "chapeau": "beret", "chapeau_c": AIGUE, "haut": SABLE, "lunettes": true, "taille": 0.96, "carrure": 1.2},
			"teinte": PEAU[3],
			"neo": {"tenue": "tailleur", "c": SABLE, "c2": CORAIL, "chapeau": "beret", "chapeau_c": AIGUE, "objet": "livre"},
			"humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"boutique": {"vend": {"perle_azur": 14, "coquillage_chanteur": 9, "corde_chanvre": 4, "engrenage": 3, "ressort": 2}, "achete": {"coquillage": 2, "etoile_mer": 3, "perle": 12, "corail_rouge": 8, "dent_requin": 6, "fanzine": 2}},
			"aime": {"coquillage": 3.0, "etoile_mer": 2.5, "fanzine": 2.5, "carte_postale": 2.0, "corail_rouge": 2.0, "lettre_azur": 1.5}, "deteste": {"boite_a_rien": -1.5, "sifflet_muet": -1.0},
			"tics": ["Quoi de neuf, là-haut ?", "Je note, je note !", "Une nouvelle toute fraîche !", "Ça, c'est pour mon Grand Cahier."],
			"surnoms": [[0, "client"], [25, "mon informateur"], [50, "mon correspondant spécial"], [75, "ma meilleure source"], [95, "mon trésor de nouvelles"]],
			"repliques": {
				"accueil": [
					L("Un client ! Et d'en haut, en plus ! Ernest Coquillard, du Comptoir des Courants : cordes, outils, perles, coquillages, et nouvelles fraîches. Surtout les nouvelles. Alors ? Quoi de neuf, là-haut ? Il pleut ? Le Bourgmestre a une nouvelle médaille ? Raconte, je note, je note !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Assieds-toi sur la caisse de coquillages. Pas celle-là, elle chante. Bon. Qu'est-ce que tu m'apportes, aujourd'hui ? Une nouvelle ? Une petite ? Même une toute petite, je la prends.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom} ! J'ai ouvert une page rien que pour toi dans mon Grand Cahier. Elle s'appelle « Ce que {surnom} a raconté ». Elle est presque pleine. Il va falloir que tu ralentisses, ou que j'achète un autre cahier.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Morose. Pas une seule nouvelle aujourd'hui. Les voyageurs n'ont rien vu, rien entendu, rien su. J'ai relu la plus vieille de mon Cahier : « Il pleut à Hautefond. » Elle a quarante ans. Elle me remonte toujours le moral. Je ne sais pas pourquoi. La pluie, sans doute.", {"humeur_max": -0.2}),
					L("Excellente ! Trois nouvelles ce matin, dont une énorme : la petite Pimprenelle de Hautefond a trouvé un boulon doré. Doré ! Je l'ai annoncé à tout le Dôme. Personne ne la connaît. Tout le monde était ravi pour elle.", {}, "rire"),
					L("Débordé. Depuis la réouverture, les nouvelles descendent par cabines entières. Je n'arrive plus à suivre. J'ai trois cahiers ouverts en même temps. Le Professeur Benthos m'a conseillé de les classer « par profondeur ». Je n'ai pas compris. Lui non plus, je crois.", {}, "rire"),
					L("Le matin, dans la réserve, je fais l'inventaire : des coquillages, des cordes, des ressorts, et zéro nouvelle. Puis j'ouvre la porte, le premier client entre, et l'inventaire des nouvelles repart. C'est le plus beau moment de la journée.", {"matin": true}),
					L("Le soir, je m'assois sur le banc de la Gare et j'attends le dernier funiculaire. Les gens descendent avec des sacs, des chapeaux, et des nouvelles plein la bouche. Je les cueille à la sortie, comme des fruits mûrs. Marius dit que je fais peur aux touristes. Je ne fais peur à personne. Je pose juste beaucoup de questions.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je collectionne deux choses : les coquillages et les nouvelles d'en haut. J'ai trois cent soixante-dix-sept coquillages, chacun avec un nom. Et sept cahiers de nouvelles. Les coquillages, c'est pour la beauté. Les nouvelles, c'est pour ne jamais oublier qu'il y a un monde au-dessus de nos têtes.", {}),
					L("Pendant les douze ans de travaux, les nouvelles n'arrivaient plus que par lettre, dans la nacelle de service, avec la spiruline. Une fois par semaine. Je les lisais à voix haute sur la Place de la Perle. Les gens venaient m'écouter. C'est comme ça que je suis devenu bavard. Avant, j'étais seulement curieux.", {"sujet_min": ["lui", 1]}),
					L("Tu veux ma plus belle nouvelle ? Il y a dix ans, une lettre est descendue : « Une petite fille est née aux Nuées, le trois du mois. Elle s'appelle Lili. » Je l'ai lue sur la Place. Une maman a levé la main : « La mienne aussi est née le trois. Elle s'appelle Mila. » Toute la Place a applaudi pour les deux. Une en haut, une en bas.", {"sujet_min": ["lui", 2]}),
					L("Tu sais garder un secret, {surnom} ? Le Funiculaire, je ne l'ai jamais pris. Pas une fois. Je connais tout ce qui se passe là-haut, et je n'y suis jamais allé. Si j'y monte, j'ai peur que ce soit moins beau que dans mes cahiers. Ou plus beau. Je ne sais pas ce qui me fait le plus peur.", {"sujet_min": ["lui", 3]}),
					L("Rosalie Cannelle, la marchande d'épices de Hautefond, tu l'as rencontrée ? On s'échange nos nouvelles par lettre. Elle m'en envoie dix, je lui en envoie une. Mais la mienne vient du fond de la mer : elle en vaut dix. Elle n'est pas d'accord. Elle m'a envoyé onze nouvelles pour le prouver.", {"a_rencontre": "rosalie_hf"}, "rire"),
				],
				"ile": [
					L("Le Comptoir des Courants, c'est à l'est de la Place de la Perle. On y trouve de tout : des cordes, des ressorts, des perles d'Azur, des coquillages qui chantent. Et un tableau, à l'entrée, avec les nouvelles du jour. Les gens viennent pour les cordes et restent pour le tableau.", {}),
					L("Mes perles d'Azur viennent de la Fosse. Les huîtres des falaises les font très lentement, dans le noir, et elles en sortent toutes bleues, avec un reflet de la Grande Perle. Lou me les rapporte avec le Petit Plongeon. Une par semaine. Pas plus. Les huîtres, on ne les presse pas.", {"sujet_min": ["ile", 1]}),
					L("Les coquillages qui chantent, c'est une affaire de forme. Tu en approches un de ton oreille, et tu entends… la Grande Chanteuse. Enfin, le Professeur Benthos dit que c'est ton sang qui bouge. Moi, je dis que c'est la Chanteuse. Lui-même n'a pas l'air très sûr. Il en a acheté trois.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Avec la ligne rouverte, les quatre mondes s'échangent tout : nos poissons et notre spiruline montent ; les pommes, les champignons, les fraises géantes et les potins descendent. Surtout les potins. Ils sont plus légers que les pommes. Ils descendent plus vite.", {"sujet_min": ["ile", 3]}, "rire"),
					L("Une jeune femme aux cheveux bleus est descendue m'acheter des éclats de nacre pour ses bijoux. Ysaé, de Hautefond. Elle m'a payé en nouvelles. Trois, toutes fraîches, dont une sur le Bourgmestre et une broche. Je lui ai fait un prix. On s'est très bien entendus.", {"a_rencontre": "ysae"}, "rire"),
				],
				"rumeur": [
					L("Entre nous : Marius, le chef de gare, parle à sa cabine. « Doucement, ma bulle, doucement. » Il dit que c'est pour l'encourager. Moi, je dis que c'est de l'amour. J'ai noté les deux versions dans mon Cahier.", {}, "rire"),
					L("Le Professeur Benthos tient un dictionnaire des chants de la Grande Chanteuse. Mille deux cents phrases ! Moi, quand elle chante, je note juste : « Nouvelle du jour : la baleine va bien. » C'est ma rubrique préférée. Et la seule qui ne se trompe jamais.", {}, "rire"),
					L("Lou, la pilote du Petit Plongeon, veut toujours descendre plus bas. Yolande veut toujours qu'elle remonte. Elles se disputent tous les jours à l'Atelier. Puis elles prennent le chocolat ensemble à La Conque. Je les ai rangées dans le Cahier, rubrique « amitiés solides ».", {}, "rire"),
					L("Tu as rencontré le Bourgmestre Hector ? Pendant son discours de deux heures, j'ai tout noté. Tout. Quarante pages. C'est la plus longue nouvelle de mon Cahier. Je l'ai rangée à la rubrique « météo » : grand vent.", {"a_rencontre": "hector_hf"}, "rire"),
					L("Une bijoutière de la Fronde, Lumi, dit que la Colonne est un collier : quatre perles sur un même fil. Les Nuées, Hautefond, les Strates, et nous, tout au bout. La perle du bas, celle qui tient le fil. Je l'ai écrit en grand sur mon tableau. Les gens s'arrêtent pour le relire.", {"a_rencontre": "lumi_fr"}),
					L("Monsieur Pascal, de la Cité des Nuées, nous a envoyé une boîte de chouquettes, avec un mot : « Pour les oreilles. » Personne n'a compris. Elles étaient délicieuses. Le Professeur Benthos a essayé d'en tenir une contre son oreille. Pour vérifier.", {"a_rencontre": "pascal"}, "rire"),
					L("La Docteure Opaline, la cristallière des Strates, m'a commandé un éclat de nacre de la Fosse. Elle veut tailler une lanterne avec un morceau de chacun des quatre mondes. Je lui ai choisi le plus beau. Il brille un peu bleu, un peu rose. Comme le Dôme le soir.", {"a_rencontre": "opaline"}),
				],
				"interpelle": [L("Hé ! Toi ! Tu viens d'en haut ? Tu as des nouvelles ? Même une vieille ?", {"visites_max": 0}, "salut"), L("{surnom} ! Une nouvelle toute fraîche ! Enfin, j'espère que c'est toi qui en as une !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bonnes bulles, {surnom} ! Et ouvre bien les yeux, là-haut : je veux tout savoir en rentrant. Tout.", {}, "salut"), L("Va ! Et si quelqu'un te demande ce qu'il y a de neuf au fond de la mer, dis-lui : « Demandez à Ernest. »", {}, "rire"), L("Bonne nuit ! Je vais relire mes nouvelles du jour avant de dormir. Ça me fait de beaux rêves. Surtout celles avec un chapeau.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Tu plaisantes ! Tu es dans mon Grand Cahier, page cent douze : « Arrivée d'un voyageur très bien élevé, qui a dit bonjour aux poissons. » Je n'ai rien inventé. Enfin, presque rien.", {}, "rire")],
				"boutique": [L("Perles d'Azur, coquillages qui chantent, cordes, ressorts, engrenages ! Et la nouvelle du jour offerte avec chaque achat. Aujourd'hui : la Grande Chanteuse va bien. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "yolande", "nom": "Yolande Hublot", "titre": "ingénieure de l'Atelier des Scaphandres", "maison": "porte_yolande", "village": "dome",
			"agenda": [[6, 7, "da_fontaine"], [7, 12, "da_atelier_etabli"], [12, 13, "da_conque_table_4"], [13, 17, "da_atelier_comptoir"], [17, 19, "da_hublot_2"], [19, 22, "da_atelier_etabli"], [22, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "carre", "yeux": Y_VERT, "haut": TITANE, "lunettes": true, "taille": 1.0, "carrure": 1.1},
			"teinte": PEAU[2],
			"neo": {"tenue": "mecano", "c": TITANE, "c2": AIGUE, "objet": "cle_molette"},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.45, "humour": 0.65, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"engrenage": 2.0, "ressort": 2.0, "boulon": 2.0, "biscuit_engrenage": 2.0, "minerai_fer": 1.5, "chocolat_abysses": 1.5}, "deteste": {"gelee_slime": -1.5, "bombe_peinture": -1.0},
			"tics": ["Ça tient.", "Je vérifie.", "Pas de fuite, pas de souci.", "Deux coups, puis un."],
			"surnoms": [[0, "visiteur"], [25, "apprenti"], [50, "mon bon outil"], [75, "ma clé de douze"], [95, "mon joint parfait"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Yolande Hublot, Atelier des Scaphandres. Je répare tout ce qui garde l'eau dehors : les scaphandres, les hublots, les joints, le Funiculaire, le Petit Plongeon, et la Cheminée d'Air quand elle tousse. Ne touche pas au manomètre. Il est susceptible. Moi aussi, un peu.", {"visites_max": 1}, "salut"),
					L("{surnom}. Pas de fuite aujourd'hui ? Bien. Tu peux entrer. Essuie-toi les pieds : ce n'est pas de l'eau, c'est de la graisse. C'est pire.", {"visites_min": 2}),
					L("Ah, {surnom}. Tu tombes bien : tiens cette vitre. Doucement. Voilà. Tu es la première personne à qui je confie une vitre. C'est un grand honneur. Ne la lâche pas.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Contrariée. Un hublot de la Promenade a fait « tic » cette nuit. J'ai vérifié chaque vis, chaque joint, chaque millimètre. Rien. C'était un poisson-lanterne qui s'était cogné. Il avait l'air plus surpris que moi. Je l'ai noté quand même.", {"humeur_max": -0.2}),
					L("Bien. Très bien, même. Cent douze vitres vérifiées depuis lundi, et elles chantent toutes juste. Je les tapote avec mon petit marteau : une vitre saine fait « ting ». Une vitre fatiguée fait « tonk ». Cette semaine, que des « ting ». C'est ma musique préférée.", {}),
					L("Fatiguée. Trente descentes par jour depuis la réouverture, et trente fois Marius qui me demande : « Et les roues ? » Les roues vont très bien. Marius aussi. C'est moi qui fatigue.", {}, "rire"),
					L("Le matin, à six heures, je vais au pied de la Cheminée d'Air. Je pose la main sur la grille, je sens l'air qui descend de la surface, frais, un peu salé. La Cheminée respire bien. Le Dôme aussi, donc. Après, je peux prendre mon café.", {"matin": true}),
					L("Le soir, je fais le tour de la Promenade des Hublots. Je tapote chaque vitre : deux coups, puis un. Maîtresse Brunehaut, la forgeronne des Strates, m'a appris : ça veut dire « bonjour, merci ». Je dis bonjour, merci, à chaque vitre qui garde la mer dehors. Elles le méritent.", {"soir": true}),
				],
				"lui": [
					L("Mon père était scaphandrier. Petite, je l'aidais à fermer son casque : douze écrous, dans l'ordre, en croix. Je les comptais à voix haute. Il disait : « Si tu en oublies un, je le saurai tout de suite. » Je n'en ai jamais oublié un. Ni ce jour-là, ni depuis.", {}),
					L("Les roues du Funiculaire ont été coulées à la Grande Forge des Strates, chez Maîtresse Brunehaut. Quand elles sont arrivées, il y avait un mot sur la caisse : « Trempées dans le rire. HO HO ! » J'ai d'abord trouvé ça peu sérieux. Puis j'ai vu les roues. Parfaites. Je n'ai rien dit. J'ai gardé la caisse.", {"sujet_min": ["lui", 1]}),
					L("Lou veut toujours descendre plus bas, et moi, je veux toujours qu'elle remonte. J'ai gravé « 200 » sur le tableau de bord du Petit Plongeon : deux cents mètres, pas un de plus. Et en dessous, en tout petit : « Lou, je te vois. » Elle dit que c'est de la surveillance. C'est de l'affection. Avec un manomètre.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Tu veux savoir pourquoi je vérifie tout trois fois, {surnom} ? Ici, le verre, c'est notre ciel. Il est épais, il est solide, il tient depuis quatre-vingts ans, et il tiendra encore longtemps. Mais quelqu'un doit veiller sur lui. Alors je veille. Pour que les autres n'aient jamais besoin d'y penser. C'est ça, être ingénieure : que personne ne sache que tu existes.", {"sujet_min": ["lui", 3]}),
					L("Tu as vu Maîtresse Brunehaut, à la Grande Forge ? Dis-lui que ses roues tournent sans un grincement. Et dis-lui… deux coups, puis un. Elle comprendra. Moi, je ne ris pas en « HO ». Je ris en « hm ». C'est plus discret. Mais ça veut dire pareil.", {"a_rencontre": "brunehaut_st"}, "rire"),
				],
				"ile": [
					L("L'Atelier des Scaphandres est au sud-est de la Place. Les scaphandres pendent au plafond comme de grosses poupées de laiton. Les visiteurs croient que ce sont des gens. Je leur dis bonjour, parfois. Ils ne répondent pas. C'est bien : j'ai besoin de calme.", {}, "rire"),
					L("La Grande Perle ne s'allume pas toute seule, contrairement à ce qu'on raconte. Enfin, si : elle s'allume toute seule, à six heures, et elle passe au violet le soir. Mais les enfants croient que c'est moi qui appuie sur un bouton. Je ne les détrompe pas. Ça me donne de l'autorité.", {}, "rire"),
					L("Le Grand Dôme a un tambour de verre, haut de six mètres, et une coupole au-dessus : des triangles de verre dans une résille blanche. Quarante-six mètres jusqu'au sommet. Chaque triangle a un numéro. Je les connais tous. Le cent quatre est mon préféré : il a une petite bulle prise dans le verre, depuis le premier jour. Comme une étoile.", {"sujet_min": ["ile", 1]}),
					L("Le Bassin des Bathyscaphes, à l'Institut, c'est un puits ouvert sur la mer, au ras du sol. Les gens d'en haut n'y croient pas : « Et l'eau, elle ne monte pas ? » Non. L'air la garde dehors. C'est comme un verre retourné dans une bassine. Je leur montre, avec un verre. Ils comprennent. Puis ils ont soif.", {"sujet_min": ["ile", 2]}, "rire"),
					L("D'un bout à l'autre de la Colonne, {surnom}, les quatre mondes tiennent grâce à des gens qui vérifient. L'Ingénieure Nova, aux Nuées, compte la portance de ses Sustentateurs. Moi, je compte la pression de mes dômes. Elle garde une île en l'air, je garde une ville sous l'eau. On s'écrit des chiffres. Ce sont nos lettres d'amitié.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Marius, le chef de gare, veut que je vérifie les roues du Funiculaire à chaque descente. Je les vérifie. Il me remercie. Il me demande si j'en suis sûre. Je dis oui. Il me remercie encore. On fait ça trente fois par jour. C'est devenu notre bonjour à nous.", {}, "rire"),
					L("Le Professeur Benthos m'a demandé un micro pour enregistrer la Grande Chanteuse. Je le lui ai fait. Il l'a posé contre la vitre de la Baie d'Observation et l'a écouté trois jours. Il a enregistré la Chanteuse, deux raies, un banc de poissons-lanternes et son propre estomac. Il dit que c'est la plus belle symphonie de l'archipel.", {}, "rire"),
					L("Une inventrice des Nuées, Mireille, m'a envoyé un parapluie qui monte. Sous la mer ! Je l'ai ouvert au-dessus du Bassin, pour voir. Il est monté. Jusqu'à la surface. On ne l'a jamais revu. Elle m'a écrit que c'était un succès. Je n'ai pas su quoi répondre. Je lui ai envoyé des chiffres.", {"a_rencontre": "mireille"}, "rire"),
					L("Le contremaître des Mines des Strates, Ludovic, est descendu poser la main sur la roche de la Fosse, « pour lui dire bonjour de la part de la Vieille ». Il a gardé son casque sous le Dôme. Je lui ai fait remarquer que le plafond était en verre, à quarante-six mètres. Il m'a répondu : « Justement. » J'ai trouvé ça très professionnel.", {"a_rencontre": "ludovic"}, "rire"),
					L("Gaspard, l'horloger de Hautefond, est descendu régler la Grande Perle. Il dit qu'elle passe au violet avec quatre secondes d'avance. Je lui ai dit que c'était exprès : pour que le soir arrive un peu plus tôt chez les enfants. Il m'a regardée longtemps. Puis il a dit : « Acceptable. »", {"a_rencontre": "gaspard_hf"}, "rire"),
					L("Margot, la gardienne du Phare de la Pointe, voit la bouée-phare de notre Cheminée, la nuit. Elle lui envoie trois éclats avec sa lampe. Alors, chaque soir, je fais clignoter la bouée trois fois. Je n'ai jamais vu Margot. On se dit bonsoir depuis dix ans.", {"a_rencontre": "margot_hf"}),
				],
				"interpelle": [L("Hé ! Les doigts loin des joints, s'il te plaît. Merci.", {"visites_max": 0}), L("{surnom}. Pas de fuite ? Alors viens.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Si tu entends un « tonk » quelque part, {surnom}, viens me chercher. Même la nuit. Bonnes bulles.", {}, "salut"), L("À plus tard. Je retourne à mes vitres. Elles m'attendent. Elles ne le disent pas, mais je le sais.", {}), L("Bonne nuit. Je fais encore le tour des hublots. Deux coups, puis un, pour chaque vitre. Il y en a cent quatre-vingt-dix. J'aurai fini avant minuit. À peu près.", {"soir": true})],
				"souvenir": [L("Oui. Je me souviens. La première fois, tu as été la seule personne à demander comment le verre tenait. Les autres demandent toujours si les poissons sont gentils. Ils le sont. Le verre aussi.", {})],
			}},
		# ================================================================ le Dôme de l'Institut
		{"id": "hippolyte", "nom": "le Professeur Hippolyte Benthos", "titre": "savant de l'Institut des Abysses", "maison": "porte_hippolyte", "village": "dome", "vouvoie": true,
			"agenda": [[6, 8, "da_observation_1"], [8, 13, "da_institut_labo_1"], [13, 14, "da_conque_table_1"], [14, 15, "da_galerie_institut"], [15, 18, "da_aquarium_1"], [18, 20, "da_institut_bureau"], [20, 23, "da_observation_banc"], [23, 6, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "boucles", "barbe": "moustache", "yeux": Y_BLEU, "haut": NACRE, "lunettes": true, "taille": 1.06, "carrure": 0.85},
			"teinte": PEAU[0],
			"neo": {"tenue": "techwear", "c": NACRE, "c2": NUIT, "objet": "livre"},
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"caillou_chantant": 2.5, "coquillage_chanteur": 2.5, "sifflet_muet": 2.0, "etoile_mer": 2.0, "fragment_meteorite": 1.5, "the_sommets": 1.5}, "deteste": {"canard_mecanique": -1.0, "vieille_botte": -0.5},
			"tics": ["Remarquable !", "Notez la date !", "Elle chante ! … Ah non, c'est la tuyauterie.", "Pour la science. Et pour elle."],
			"surnoms": [[0, "cher visiteur"], [25, "cher plongeur"], [50, "cher assistant de recherche"], [75, "ma plus belle note"], [95, "ma découverte de l'année"]],
			"repliques": {
				"accueil": [
					L("Oh ! Un visiteur ! Pardon, je ne vous avais pas entendu, j'écoutais la mer. Professeur Hippolyte Benthos, de l'Institut des Abysses. J'étudie tout ce qui vit plus bas que vos pieds. Et surtout, j'écoute la Grande Chanteuse. Vous l'avez entendue ? Non ? Ne bougez plus. Elle passera peut-être. Elle aime les nouveaux.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Venez, venez ! Une méduse que je n'avais jamais vue vient de passer devant la Baie. Violette, avec des franges dorées. Je l'ai appelée Clémence. Elle n'est pas revenue. Les méduses ont une vie privée. Je respecte.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Asseyez-vous près de moi, sur le banc. Ne dites rien. … Voilà. Vous entendez ce silence ? C'est la Fosse qui respire. Je ne la fais écouter qu'aux amis.", {"visites_min": 4}),
				],
				"humeur": [
					L("Morose. Trois jours sans la Grande Chanteuse. Je sais bien qu'elle voyage, qu'elle a d'autres mers, d'autres gens à qui chanter. Mais je lui avais préparé une question. Elle est très bonne, ma question. Elle attendra.", {"humeur_max": -0.2}),
					L("Exalté ! Ce matin, la Grande Chanteuse a survolé le Dôme et chanté une phrase que je n'avais jamais entendue. Quatre notes graves, une très longue. J'ai couru jusqu'au Dictionnaire. Elle n'y était pas. Une phrase nouvelle ! Après vingt ans ! Je ne dormirai pas de la semaine.", {}, "rire"),
					L("Un peu distrait, me dit-on. J'ai salué le portemanteau ce matin. Deux fois. Il portait mon chapeau : je l'ai pris pour moi. Et puis le Dôme est plein de vitres. On s'y croise beaucoup soi-même.", {}, "rire"),
					L("Le matin, avant tout le monde, je vais à la Baie d'Observation. La cheminée hydrothermale fume, les vers géants ouvrent leurs panaches rouges, et les crevettes blanches dansent autour. Toute une vie qui se lève sans soleil. Cela me rend humble. Jusqu'au petit déjeuner.", {"matin": true}, "rire"),
					L("Le soir, je m'assois sur le banc de la Baie, j'éteins ma lampe, et j'attends. Parfois, très haut, une ombre immense passe au-dessus des dômes. Et elle chante. Tout le Dôme se tait. Même Ernest. Je lui réponds, tout bas, en fredonnant contre la vitre. Je suis presque sûr qu'elle m'entend.", {"soir": true}),
				],
				"lui": [
					L("Je suis né à Hautefond, figurez-vous. À six ans, au Port des Cordages, j'ai collé mon oreille contre la coque d'un bateau. J'ai entendu chanter, très loin, sous l'eau. Personne ne m'a cru. À vingt ans, j'ai pris le Funiculaire avec une valise pleine de carnets vides. Aujourd'hui, ils sont tous pleins. J'ai dû racheter une valise.", {}),
					L("Le Docteur Aurèle Brise, de l'Institut des Vents, aux Nuées, est mon plus vieux correspondant. Lui étudie le haut, moi le bas. Il baptise ses nuages, je baptise mes méduses. Il m'envoie la météo du ciel, je lui envoie celle de la Fosse : courant faible, visibilité douze mètres, passage de méduses en fin d'après-midi. Nous sommes d'accord sur un point : une méduse, c'est un nuage qui a choisi la mer.", {"sujet_min": ["lui", 1]}),
					L("Je tiens le Grand Dictionnaire de la Chanteuse. Mille deux cents phrases notées en vingt ans. Trois notes graves, une aiguë : « Bonjour, le Dôme. » Deux longues : « Il fait bon, là-haut. » Une très grave, qui ne finit pas : je crois que c'est « je reviendrai ». Mes collègues disent que j'invente. Peut-être. Mais elle revient toujours.", {"sujet_min": ["lui", 2]}),
					L("Voulez-vous savoir une chose, {surnom} ? Je ne veux pas comprendre tout ce qu'elle chante. Si je comprenais tout, je n'aurais plus de raison de l'attendre le soir. Alors je laisse toujours une phrase de côté, sans traduction. Pour la prochaine fois. C'est ma façon d'avoir toujours un rendez-vous.", {"sujet_min": ["lui", 3]}),
					L("Le Professeur Lunette, l'astronome de Hautefond, vous l'avez rencontré ? Il m'a écrit un jour en m'appelant « cher confrère astronome ». Je lui ai répondu que j'étais océanographe. Il a trouvé que c'était très beau, comme mot. Depuis, il compte ses étoiles, je compte mes poissons-lanternes, et nous n'avons fini ni l'un ni l'autre.", {"a_rencontre": "octave_hf"}, "rire"),
				],
				"ile": [
					L("L'Institut des Abysses est dans le dôme de l'est. Les laboratoires, sur deux niveaux ; le Grand Aquarium, avec ses cuves rondes de méduses et de poissons qui luisent ; le Bassin des Bathyscaphes, où dort le Petit Plongeon ; et la Baie d'Observation, mon bureau préféré. Elle n'a pas de murs. Juste du verre, et la Fosse.", {}),
					L("Face à la Baie, il y a une cheminée hydrothermale : une source chaude au fond de la mer, qui fume noir. Tout autour, des vers géants, rouge et blanc, hauts comme vous. La petite Mila les appelle « les sucres d'orge ». J'ai cherché un nom plus savant. Je n'ai pas trouvé mieux.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Grande Chanteuse est une baleine. Une très vieille, très grande baleine, qui passe parfois très haut au-dessus des dômes. Son chant traverse l'eau, le verre, les murs, et les gens. Quand elle chante, tout le Dôme s'arrête. Même la soupe de Josette cesse de bouillir. Enfin, presque.", {"sujet_min": ["ile", 2]}),
					L("Les vieilles légendes parlent de l'Atlantide, une cité engloutie, plus au nord-est, sous une bulle d'air. Une baleine passerait au-dessus, et chanterait pour son grand cristal. Et si c'était la nôtre ? La Grande Chanteuse voyage beaucoup. Elle a peut-être des amis partout. J'aimerais tant le lui demander. J'ai préparé la question.", {"sujet_min": ["ile", 3]}),
					L("Vous… vous avez vu l'Atlantide ? Vous avez parlé à la reine Néréa ? (Il laisse tomber son carnet.) Et la baleine ? Elle passe au-dessus de chez eux aussi ? Elle chante pour leur cristal ? … Asseyez-vous. Non, ne vous asseyez pas, je n'ai pas de quoi noter assez vite. Si. Asseyez-vous. Racontez tout. Lentement.", {"a_rencontre": "nerea"}, "rire"),
				],
				"rumeur": [
					L("Un bassiste de la Fronde, Écho, m'a écrit qu'il avait entendu la Grande Chanteuse à travers la grille de la Gare des Strates. À travers la roche et la mer ! Je ne l'ai pas cru. Puis il est descendu. Il a posé la main sur la vitre de la Baie, il a fermé les yeux, et il m'a donné la note. Elle était juste. Au quart de ton près.", {"a_rencontre": "echo"}),
					L("Un batteur de la Fronde, Rivet, m'a demandé si la Grande Chanteuse aimait la batterie. J'ai répondu que la science n'avait pas encore étudié la question. Il a dit : « On va vérifier. » Il est venu un soir avec deux casseroles. Elle n'est pas passée. Il reviendra. Moi aussi, je veux savoir.", {"a_rencontre": "rivet_fr"}, "rire"),
					L("La Capitaine Héloïse, de Hautefond, m'a écrit qu'elle voyait la Grande Chanteuse d'en haut, depuis son dirigeable. Moi, je la vois d'en bas, depuis mon banc. Elle passe entre nous deux. Héloïse dit « un nuage qui nage ». Moi, je dis « une montagne qui chante ». Nous avons raison tous les deux.", {"a_rencontre": "heloise_hf"}),
					L("Lou, notre pilote, me rapporte des échantillons de la Fosse. Elle rêve de descendre plus bas ; Yolande s'y oppose. Pour la science, je suis du côté de Lou. Pour Lou, je suis du côté de Yolande. C'est une position très inconfortable. Je l'occupe avec plaisir.", {}, "rire"),
					L("La petite Mila vient écouter la Chanteuse avec moi, certains soirs. Elle écoute avec un verre plaqué sur la vitre, l'oreille collée au fond. Elle m'a demandé si la baleine avait déjà vu le ciel. Je lui ai dit : « Elle remonte respirer, alors oui, tous les jours. » Mila a été jalouse d'une baleine. Je ne l'ai jamais vue aussi sérieuse.", {}),
				],
				"interpelle": [L("Chut ! Excusez-moi. Chut ! … Ah. Ce n'était que la tuyauterie. Bonjour !", {"visites_max": 0}), L("{surnom} ! Venez écouter ! Enfin, venez attendre avec moi !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et si, là-haut, vous voyez une grande ombre passer sous la mer, saluez-la de ma part. Elle saura.", {}, "salut"), L("Bonnes bulles ! C'est ainsi qu'on dit, ici. Je le dis aussi aux méduses. Elles ne répondent pas. Elles s'allument, parfois. C'est presque pareil.", {}, "rire"), L("Bonsoir, {surnom}. Moi, je reste sur mon banc. Elle passera peut-être cette nuit. J'ai ma question toute prête.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Certainement. Vous êtes arrivé le soir où la Chanteuse a chanté « bonjour, le Dôme » trois fois de suite. Je l'ai noté dans le Dictionnaire, à côté de votre nom. C'est une très bonne compagnie.", {})],
			}},
		{"id": "lou", "nom": "Lou Grenadier", "titre": "pilote du bathyscaphe « Le Petit Plongeon »", "maison": "porte_lou", "village": "dome",
			"agenda": [[7, 9, "da_bassin_quai"], [9, 13, "da_bassin_bathyscaphe"], [13, 14, "da_conque_table_2"], [14, 18, "da_bassin_bathyscaphe"], [18, 20, "da_atelier_comptoir"], [20, 22, "da_belvedere_1"], [22, 7, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "queue", "yeux": Y_AMBRE, "chapeau": "casquette", "chapeau_c": JAUNE, "haut": NUIT, "taille": 0.98, "carrure": 1.0},
			"teinte": PEAU[6],
			"neo": {"tenue": "combinaison", "c": NUIT, "c2": JAUNE, "chapeau": "casquette", "chapeau_c": JAUNE},
			"femme": true,
			"humeur_base": 0.8, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.95, "susceptible": 0.35, "rancunier": 0.05},
			"aime": {"poisson_lune": 2.5, "dent_requin": 2.0, "limonade_bleue": 2.0, "boussole_sud": 1.5, "chocolat_chaud": 1.5, "corde_chanvre": 1.5}, "deteste": {"vieille_botte": -1.0, "gelee_slime": -0.5},
			"tics": ["On plonge !", "Ballasts pleins !", "Encore dix mètres…", "Yolande va me gronder."],
			"surnoms": [[0, "le touriste"], [25, "mon passager"], [50, "mon copilote"], [75, "mon équipier de plongée"], [95, "mon binôme pour la vie"]],
			"repliques": {
				"accueil": [
					L("Salut ! Lou Grenadier, pilote du Petit Plongeon ! Le bathyscaphe jaune, là, dans le Bassin. Oui, celui qui ressemble à un canard qui fait la sieste. C'est le plus beau sous-marin du monde. C'est aussi le seul du Dôme. Ça aide. Tu veux voir le tableau de bord ? Ne touche à rien. Enfin, touche avec les yeux.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien, je reviens d'une plongée ! Cent quatre-vingt-dix mètres ! Une raie m'a fait coucou avec une aile. Je te jure. Une aile entière. Elle avait l'air contente de me voir. Moi aussi.", {"visites_min": 2}, "rire"),
					L("Hé, {surnom} ! Mon binôme de quai ! Un jour, je t'emmène pour de vrai. Quand Yolande aura dit oui. Pour l'instant, elle a dit « peut-être ». Chez elle, c'est déjà un demi-oui.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Bof. Le Petit Plongeon est en révision. Yolande a trouvé une vis qui la « regardait de travers ». Trois jours au sec. Je tourne en rond autour du Bassin. Les poissons me regardent tourner. Ils doivent trouver que je fais une drôle de plongée.", {"humeur_max": -0.2}, "rire"),
					L("Au top ! Plongée du matin : cent quatre-vingt-quinze mètres. Les falaises de la Fosse, les éponges de verre, les gorgones, et une méduse grande comme un parapluie qui m'a accompagnée jusqu'en bas. Le Professeur l'a appelée Gertrude. Elle avait une tête de Gertrude.", {}, "rire"),
					L("Un peu frustrée. Deux cents mètres, c'est ma limite. Yolande l'a gravée sur le tableau de bord. Et en dessous, la Fosse continue. Noire, profonde, pleine de choses que personne n'a jamais vues. Je m'arrête à deux cents. Mais je regarde en bas. Longtemps.", {}),
					L("Le matin, je prépare le Petit Plongeon sur le quai du Bassin : je vérifie les ballasts, les projecteurs, l'oxygène, les sandwichs. Surtout les sandwichs. Une plongée sans goûter, c'est une plongée ratée. Règle numéro un des pilotes. Je l'ai inventée.", {"matin": true}, "rire"),
					L("Le soir, je vais au Belvédère des Abysses, je m'appuie contre la vitre, et je regarde le noir tout au fond de la Fosse. Parfois, une petite lumière s'allume, très loin, et s'éteint. Personne ne sait ce que c'est. Un jour, j'irai lui dire bonjour.", {"soir": true}),
				],
				"lui": [
					L("Je suis née dans la maison-bulle d'à côté de la Galerie de l'Institut, avec un hublot tourné vers le Bassin. Petite, je regardais les projecteurs du vieux bathyscaphe partir et revenir. Je comptais ses bulles. Le jour de mes seize ans, le vieux pilote m'a fait monter. Il m'a dit : « Tu comptes mes bulles depuis dix ans. Tu sais déjà tout. » Il avait raison. Presque.", {}),
					L("Le Petit Plongeon est rond, jaune, avec deux grands hublots devant, comme des yeux étonnés. Je lui parle pendant les plongées. « Doucement, mon canard. Encore dix mètres. » Il répond par des petits « bloup ». Yolande parle de pression. Moi, je dis qu'il est d'accord.", {"sujet_min": ["lui", 1]}, "rire"),
					L("« 200 » : c'est ma limite, gravée par Yolande sur mon tableau de bord. Juste dessous, minuscule : « Lou, je te vois. » Au début, j'ai trouvé ça vexant. Maintenant, à cent quatre-vingt-dix-neuf mètres, je le lis, et je souris. Et je remonte. Ne lui dis pas que je souris.", {"sujet_min": ["lui", 2]}),
					L("Je vais te dire mon vrai rêve, {surnom}. Pas celui de descendre plus bas. Un jour, je pousserai un bathyscaphe jusqu'à l'Atlantide. Le Professeur dit que c'est une légende. Les légendes, c'est juste des endroits où personne n'est encore allé. Moi, j'aime bien arriver la première.", {"sujet_min": ["lui", 3]}),
					L("T'as vu l'Atlantide ?! Pour de vrai ?! Elle est à quelle profondeur ? Quel cap ? Il y a une bulle d'air, comme chez nous ? Et la reine, elle a un sous-marin ? … Attends, je prends une carte. Ne dis rien à Yolande. Enfin, si. Mais plus tard.", {"a_rencontre": "nerea"}, "rire"),
				],
				"ile": [
					L("Le Bassin des Bathyscaphes, c'est un grand puits d'eau, au ras du sol, dans le dôme de l'Institut. Il est ouvert sur la mer, par en dessous. L'air garde l'eau dehors. Le Petit Plongeon s'enfonce dedans, glisse sous le Dôme, et hop : il est dans la Fosse. C'est la porte de derrière de la ville.", {}),
					L("La Fosse d'Azur, c'est un grand canyon au fond de la mer, au pied des falaises de Hautefond. Le Dôme est posé à cent quarante mètres. En dessous, ça descend encore. Les falaises sont bleues, couvertes d'éponges de verre et de gorgones. Quand j'allume les projecteurs, tout devient orange et rose. On dirait un jardin qui ne savait pas qu'il était beau.", {"sujet_min": ["ile", 1]}),
					L("Avec le Petit Plongeon, je relève aussi les nasses des pêcheurs, autour du Dôme. Le poisson d'ici monte maintenant jusqu'au Grand Marché de Hautefond, par la ligne. Les gens d'en haut disent qu'il a « le goût du fond ». C'est un compliment. Je crois.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Du haut en bas de la Colonne, chacun voyage à sa façon : les Nuées, tout en haut, avec leurs dirigeables ; Hautefond, avec ses cabines ; les Strates, avec leurs wagonnets ; et nous, avec le Petit Plongeon. Ceux d'en haut volent, ceux d'en bas plongent. On fait le même métier, en fait. À l'envers.", {"sujet_min": ["ile", 3]}),
					L("Une capitaine de dirigeable, la Capitaine Héloïse, est descendue voir le Petit Plongeon. Elle a fait trois fois le tour du Bassin. Puis elle m'a dit : « Toi, tu voles à l'envers. » J'ai trouvé ça tellement beau que je l'ai écrit sur la coque. Au feutre. Yolande l'a effacé. Je l'ai réécrit. On en est là.", {"a_rencontre": "heloise_hf"}, "rire"),
				],
				"rumeur": [
					L("Yolande fait semblant d'être sévère avec moi. Mais quand je remonte d'une plongée, elle est toujours sur le quai. « Par hasard. » Avec deux chocolats. « Par hasard » aussi. Je fais mine d'y croire. On est très fortes, toutes les deux, pour faire semblant.", {}, "rire"),
					L("Le Professeur Benthos me demande de lui rapporter « un peu d'eau du fond, s'il vous plaît, et une crevette, si elle est d'accord ». Je lui ai rapporté une crevette. Il lui a demandé si elle était d'accord. Elle n'a rien dit. Il l'a relâchée. C'est un très bon savant. Il ne garde que ce qu'on lui donne.", {}, "rire"),
					L("La petite Mila veut plonger avec moi. Elle a dix ans. Je lui ai dit : « Quand tu seras grande. » Elle a répondu : « Je serai grande demain ? » Tous les matins, elle vient me demander si on est demain. Je finirai par craquer. Avec l'accord de Yolande. Et de sa maman. Et du Conseil.", {}, "rire"),
					L("Marius, le chef de gare, prétend que le Funiculaire est le plus beau voyage de l'archipel. Il descend tout droit, dans un tube, sur des rails. Moi, je vais où je veux, comme je veux, sans rails. On se dispute à chaque repas. Il gagne toujours : il parle plus fort.", {}, "rire"),
					L("La Capitaine Zéphyrine, aux Nuées, et la Capitaine Héloïse, à Hautefond, font la course autour de la Colonne depuis vingt ans. Moi, je ne fais la course contre personne. C'est reposant. Et je gagne à chaque fois.", {"a_rencontre": "zephyrine_nu"}, "rire"),
				],
				"interpelle": [L("Hé ! Le touriste ! Tu veux voir un vrai sous-marin ?", {"visites_max": 0}, "salut"), L("{surnom} ! On plonge ! Enfin, moi, je plonge. Toi, tu regardes. C'est déjà beaucoup !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Allez, bonnes bulles ! Si tu vois une lumière bizarre au fond de la Fosse, dis-lui que j'arrive. Pas tout de suite. Mais j'arrive.", {}, "salut"), L("À plus ! Le Petit Plongeon m'attend. Il fait des « bloup » d'impatience.", {}, "rire"), L("Bonne nuit ! Le Petit Plongeon dort dans le Bassin, les hublots fermés. Moi, je rêve de plonger. Lui aussi, sûrement.", {"soir": true})],
				"souvenir": [L("Toi ? Je te reconnaîtrais même au fond de la Fosse ! Tu as tapoté la coque du Petit Plongeon comme on flatte un cheval. Il a fait « bloup ». Chez lui, c'est un grand compliment.", {}, "rire")],
			}},
		# ================================================================ le Dôme des Serres
		{"id": "melisande", "nom": "Mélisande Varech", "titre": "jardinière du Dôme des Serres", "maison": "porte_melisande", "village": "dome",
			"agenda": [[6, 8, "da_serres_algues"], [8, 12, "da_serres_etal"], [12, 13, "da_serres_bassin"], [13, 15, "da_serres_tour_1"], [15, 17, "da_serres_verger"], [17, 20, "da_serres_etal"], [20, 21, "da_galerie_serres"], [21, 6, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "tresse", "yeux": Y_VERT, "chapeau": "paille", "haut": ALGUE, "tablier": NACRE, "taille": 0.95},
			"teinte": PEAU[1],
			"neo": {"tenue": "jardinier", "c": ALGUE, "c2": CORAIL, "chapeau": "paille"},
			"femme": true,
			"humeur_base": 0.6, "traits": {"bavard": 0.55, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.0},
			"boutique": {"vend": {"fraises_lampes": 2, "mandarine_lampes": 2, "spiruline": 3, "graines": 2}, "achete": {"graines": 1, "pomme": 1, "baies": 1, "miel": 4, "fraise_geante": 2, "champignon": 2}},
			"aime": {"graines": 3.0, "fraise_geante": 2.5, "bouquet_tournesols": 2.0, "pomme": 2.0, "champignon_lune": 2.0, "eau_source": 1.5}, "deteste": {"hache": -1.5, "soda_neon": -1.0},
			"tics": ["Tout doux, elles se réveillent.", "Bonjour, mes salades.", "Ça verdit !", "Sous la lampe rose…"],
			"surnoms": [[0, "promeneur"], [25, "petite laitue"], [50, "mon brin de cresson"], [75, "ma belle salicorne"], [95, "ma fleur de nénuphar"]],
			"repliques": {
				"accueil": [
					L("Oh… bonjour. Parle doucement, s'il te plaît : les laitues de la tour numéro un viennent de se réveiller. Mélisande Varech, jardinière des Serres. Bienvenue chez moi. Ici, tout pousse sous des lampes roses et violettes, au fond de la mer. Ça surprend, au début. Les salades, elles, ne savent pas que c'est bizarre.", {"visites_max": 1}, "salut"),
					L("{surnom}… Tu tombes bien. Les nénuphars du bassin viennent de s'ouvrir. D'habitude, ils attendent que la Grande Perle devienne violette. Aujourd'hui, ils n'ont pas attendu. Je crois que c'est pour toi.", {"visites_min": 2}),
					L("Ah, {surnom}. Mes salades te reconnaissent. Elles se tournent un peu quand tu passes. Bon, elles se tournent aussi vers la lampe. Mais je préfère croire que c'est toi.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Un peu fanée. Une lampe de la tour numéro deux a grillé cette nuit. Les fraises du dessous ont eu froid, toutes pâles. Yolande l'a changée ce matin. Je leur ai chanté une chanson pour les réchauffer. Elles reprennent des couleurs. Doucement.", {"humeur_max": -0.2}),
					L("Heureuse. Les mandariniers du Verger des Lampes ont fleuri tous en même temps. Tout le dôme sent la fleur d'oranger. Enfin, un peu : ici, l'air efface les parfums. Mais si tu colles ton nez contre une fleur, tu sens. Il faut juste s'approcher. Comme avec les gens.", {}),
					L("Pensive. Mes salades poussent mieux quand je leur parle. Le Professeur Benthos dit que c'est le gaz de mon souffle. Josette dit que c'est la tendresse. Moi, je ne sais pas. Je continue de leur parler. Par précaution.", {}, "rire"),
					L("Le matin, je commence par le mur des algues. Des tubes de verre verts, qui luisent, du sol au plafond. Ils font l'air que nous respirons, et la spiruline. Je pose la main dessus et je dis merci. Tous les matins. On ne dit jamais assez merci à ce qui nous fait respirer.", {"matin": true}),
					L("Le soir, je m'assois dans la Galerie des Serres, au milieu du tube de verre. Dehors, les poissons-lanternes passent en bancs, comme des lampions. Derrière moi, mes lampes s'éteignent une à une. C'est l'heure où les Serres et la mer se disent bonne nuit.", {"soir": true}),
				],
				"lui": [
					L("Ma mère était jardinière avant moi. Elle disait que les plantes du fond de la mer sont les plus courageuses du monde : elles poussent sans soleil, sans pluie, sans vent, et elles poussent quand même. Juste parce qu'on leur a allumé une lampe et dit qu'on les aimait. Je trouve que ça vaut pour beaucoup de monde.", {}),
					L("Il y a trois jardinières dans la Colonne. Flora Verdine, aux Nuées, qui a trop de soleil. Bertille Champignac, aux Strates, qui n'en a pas du tout. Et moi, qui en ai un que j'allume avec un bouton. On s'écrit. On s'appelle « les trois jardinières ». On s'échange des graines. Celles de Flora ont poussé si vite qu'elles ont touché la lampe.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je parle à mes salades, oui. J'ai même donné à mes deux plus belles laitues les prénoms de mes amies : Flora et Bertille. Flora est grande et un peu frisée. Bertille est plus petite et pousse dans le coin le plus sombre. Je ne l'ai jamais dit aux vraies. Aux salades, si.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Je peux te confier un secret, {surnom} ? Je n'ai jamais vu de vrai jardin. Pas un seul, sous le vrai ciel. Je suis née ici, j'ai toujours jardiné sous les lampes. Depuis que la ligne a rouvert, Flora m'invite aux Nuées. J'ai peur que le vrai soleil soit trop fort pour moi. Mais j'ai envie de voir mes graines pousser sous lui. Une fois.", {"sujet_min": ["lui", 3]}),
					L("Tu connais Bertille, aux Jardins des Champignons ? Elle m'a envoyé un champignon qui brille, dans un bocal. Il vit au bord de mon bassin. Il brille tout bleu, la nuit. Les nénuphars le trouvent un peu bavard. Moi, je l'aime beaucoup. C'est un petit bout des Strates qui veille sur mes Serres.", {"a_rencontre": "bertille"}),
				],
				"ile": [
					L("Le Dôme des Serres, c'est le petit dôme de l'ouest, au bout de la Galerie. Les tours hydroponiques, avec les salades et les fraises sous les lampes roses ; le mur des algues ; le Verger des Lampes ; le bassin aux nénuphars et son petit pont ; et mon étal, à côté de ma maison. Tout le Dôme mange ce qui pousse ici. Ça me rend fière. Et un peu fatiguée.", {}),
					L("Le mur des algues, c'est le cœur des Serres. Des tubes de verre pleins d'eau verte, qui luisent. Les algues mangent la lumière et rendent de l'air. Et de la spiruline, toute bleue, qu'on récolte au filet. Josette en met dans sa limonade. Les enfants ont la langue bleue toute la journée. C'est très joli.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Au Verger des Lampes, de petits mandariniers poussent sous des soleils artificiels. Leurs fruits ont toujours une joue plus rose : celle qui regarde la lampe. Les gens d'en haut demandent pourquoi. Je leur dis : « Parce qu'ils rougissent d'être au fond de la mer. » Ils me croient. Je ne corrige pas.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Maintenant que la ligne a rouvert, les jardins des quatre mondes se parlent. Mes fraises montent au Grand Marché de Hautefond, chez Rosalie Cannelle. Elle les vend comme « fraises du fond de la mer ». Les gens les achètent pour voir si elles ont un goût de sel. Elles n'en ont pas. Ils en rachètent quand même.", {"sujet_min": ["ile", 3]}, "rire"),
					L("Le Père Bastien, des Vergers de Hautefond, est descendu voir mes mandariniers. Il leur a parlé pendant une heure. Ils n'ont rien dit. Mais le lendemain, ils avaient tous une fleur de plus. Il m'a dit : « Ils avaient besoin qu'un vieux leur parle du soleil. » Je lui ai demandé de revenir. Il revient dimanche.", {"a_rencontre": "bastien_hf"}),
				],
				"rumeur": [
					L("Josette vient chercher sa salicorne tous les matins. Elle la goûte avant de la payer. Si elle fait la grimace, je lui en donne une autre. Si elle sourit, elle en prend deux paniers. Elle sourit toujours. Je crois qu'elle fait exprès de ne jamais grimacer. C'est une amie.", {}, "rire"),
					L("Après l'école, Mila s'installe sur mon petit pont et me demande si mes lampes ressemblent au vrai soleil. Je lui dis : « Un peu. Le vrai est plus grand, et il ne s'éteint pas avec un bouton. » Elle a réfléchi longtemps. Puis elle a demandé : « Alors qui l'éteint, le soir ? » Je n'ai pas su répondre.", {}),
					L("Flora, aux Nuées, m'a envoyé une fraise géante, grosse comme le poing. Elle a mis trois jours à descendre. Elle est arrivée un peu fatiguée, mais toujours géante. Je l'ai coupée en douze. Tout le Dôme des Serres en a eu un morceau. On en parle encore.", {"a_rencontre": "flora"}, "rire"),
					L("Le Professeur Benthos vient parfois respirer devant mon mur des algues. Il dit que c'est « l'air le plus frais du Dôme, à deux pour cent près ». Il ferme les yeux, il respire trois fois, et il repart en courant vers sa baleine. Je crois qu'il vient surtout pour le calme.", {}),
					L("Ernest, du Comptoir, vient acheter une mandarine par jour. Une seule. Il la mange sur mon banc en me racontant les nouvelles d'en haut. J'écoute. Je ne dis rien. Il repart content. Je crois que je suis la seule personne du Dôme qui ne lui pose jamais de question.", {}, "rire"),
				],
				"interpelle": [L("Psst… Tu entends ? Elles boivent.", {"visites_max": 0}), L("{surnom} ! Viens sentir les mandariniers ! De très près !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Si tu croises un vrai jardin, là-haut, dis-lui bonjour de la part des Serres. Il ne nous connaît pas. Mais on pense à lui.", {}, "salut"), L("Ah, et si tu as une graine de là-haut dans ta poche, garde-la-moi. Même une toute petite. Je lui trouverai une lampe.", {}), L("Bonne nuit. J'éteins les lampes une par une, de la plus rose à la plus violette. La dernière, je la laisse un peu plus longtemps. Pour la salade qui a peur du noir.", {"soir": true})],
				"souvenir": [L("Je me souviens surtout de ta première visite : tu as dit bonjour à une salade. Sans faire exprès, je crois. Elle a très bien poussé depuis.", {})],
				"boutique": [L("Fraises roses des Lampes, petites mandarines du Verger, spiruline du mur des algues, et des graines pour ton jardin d'en haut, même sous un vrai soleil ! Ramassé ce matin, sous la lampe. Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ l'École des Abysses
		{"id": "mila", "nom": "Mila Mérou", "titre": "écolière de l'École des Abysses (10 ans), qui n'a jamais vu le ciel", "maison": "porte_mila", "village": "dome",
			"agenda": [[8, 9, "da_fontaine"], [9, 12, "da_ecole_banc_1"], [12, 13, "da_ecole_cour"], [13, 16, "da_ecole_banc_1"], [16, 18, "da_gare_banc_2"], [18, 19, "da_hublot_3"], [19, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "boucles", "yeux": Y_BRUN, "haut": CORAIL, "enfant": true, "taille": 0.72},
			"teinte": PEAU[3],
			"neo": {"tenue": "enfant", "c": CORAIL, "c2": AIGUE},
			"femme": true,
			"humeur_base": 0.75, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.05},
			"aime": {"bocal_nuage": 3.0, "plume_corbeau": 2.5, "cerf_volant": 2.5, "carte_postale": 2.5, "glace": 2.0, "limonade_bleue": 2.0}, "deteste": {"piment_infernal": -1.0, "vieille_botte": -0.5},
			"tics": ["C'est comment, le ciel ?", "Je le note dans mon cahier !", "Madame Nautile dit que…", "Par la Grande Perle !"],
			"surnoms": [[0, "monsieur-madame d'en haut"], [25, "mon voyageur du ciel"], [50, "mon copain d'en haut"], [75, "mon meilleur ami du dessus"], [95, "mon ami pour toujours, du fond jusqu'au ciel"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Tu viens d'en haut ? De là où il y a le ciel ? Le vrai ? Moi, c'est Mila, j'ai dix ans, je suis née ici, et je n'ai JAMAIS vu le ciel. Ni le soleil. Ni la pluie. Ni un oiseau. Alors raconte : le ciel, il a un plafond ? Il est loin ? On peut le toucher en sautant ?", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu es revenu ! J'ai préparé des questions. Vingt-trois. Non, vingt-quatre : j'en ai trouvé une en chemin. C'est quoi, le vent, exactement ? Ça pousse ? Ça pousse fort ?", {"visites_min": 2}, "rire"),
					L("{surnom} ! Regarde mon cahier ! Toutes tes réponses sont dedans, avec des dessins. Là, c'est le ciel. Là, c'est un nuage. Là… je ne sais plus. Un mouton, peut-être. Ou une pluie. Tu peux vérifier ?", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Un peu triste. J'ai demandé à six voyageurs de quelle couleur était le ciel. Trois ont dit « bleu », deux ont dit « gris », et un monsieur a dit « ça dépend ». Comment ça, ça dépend ? Le Bassin, lui, il est toujours bleu. Le ciel est compliqué.", {"humeur_max": -0.2}),
					L("Super ! À la Cheminée d'Air, j'ai mis la main sur la grille, et j'ai senti l'air qui descend d'en haut. Madame Nautile dit que c'est un peu de vent. Du vrai vent du ciel ! Il était froid et il sentait le sel. J'ai gardé ma main fermée toute la journée. Pour le garder.", {}, "rire"),
					L("Un peu fâchée. Lou ne veut pas m'emmener dans le Petit Plongeon. Elle dit « quand tu seras grande ». Je lui demande tous les matins si je suis grande. Elle dit « pas encore ». J'ai mesuré. J'ai grandi d'un centimètre. Ça devrait compter.", {}),
					L("Ce matin, j'ai fait un vœu à la Fontaine des Bulles. On chuchote son vœu à une bulle, et elle le monte jusqu'en haut, jusqu'à la surface. Mon vœu, c'est voir la pluie. Ma bulle est montée très vite. Je crois qu'elle était pressée de le donner à quelqu'un.", {"matin": true}),
					L("Le soir, je vais à la Promenade des Hublots, et je regarde en haut, tout en haut, là où l'eau devient un peu plus claire. Derrière, il y a le ciel. Je le sais. Je dis bonsoir au ciel, même si je ne le vois pas. Comme on dit bonsoir à quelqu'un dans une autre pièce.", {"soir": true}),
				],
				"lui": [
					L("Mon papa est technicien à la Cheminée d'Air : il s'occupe de l'air que tout le monde respire. Ma maman récolte la spiruline sur le mur des algues. Alors moi, je suis faite d'air et de spiruline. C'est pour ça que j'ai la langue bleue. Enfin, c'est aussi la limonade de Josette.", {}, "rire"),
					L("J'ai un cahier, le Cahier du Ciel. J'y écris tout ce que les voyageurs me racontent. La pluie : « de l'eau qui tombe toute seule, sans tuyau ». Le vent : « de l'air qui court ». Les nuages : « des moutons, mais en vapeur ». Je ne comprends pas encore les moutons. Il faudra que j'en voie un aussi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Ernest dit que je suis née le même jour que Lili Altaïr, la fille de la Cité des Nuées. Elle, tout en haut, moi, tout en bas. Elle n'a jamais vu la mer, et moi, jamais le ciel. On est pareilles, mais à l'envers ! Je lui ai écrit une lettre. Marius dit qu'elle doit passer par le Funiculaire, puis par Anatole, puis par Maîtresse Capucine, puis par Théo. Quatre facteurs ! Elle va arriver toute chiffonnée.", {"sujet_min": ["lui", 2]}, "rire"),
					L("Tu veux savoir mon plus grand secret ? Je n'ai pas peur du noir de la Fosse, ni des grosses raies, ni des requins derrière la vitre. Mais le ciel, sans plafond… j'ai un tout petit peu peur. Et s'il n'y a rien pour me tenir, là-haut ? Madame Nautile dit qu'on tient très bien sur la terre. Je vais lui faire confiance. Mais je lui tiendrai la main.", {"sujet_min": ["lui", 3]}),
					L("Tu as vu Lili ? Lili Altaïr, de la Cité des Nuées ? Raconte ! Elle a vraiment onze cerfs-volants ? C'est quoi, exactement, un cerf-volant ? Un poisson qui vole au bout d'une ficelle ? … Dis-lui que je lui garde un coquillage. Le plus beau. Celui qui chante.", {"a_rencontre": "lili_nu"}),
				],
				"ile": [
					L("Ici, notre soleil, c'est la Grande Perle, enfilée sur la Cheminée d'Air, au milieu de la Place. Le matin, elle devient blanche et dorée. Le soir, bleue, puis violette. Madame Nautile dit que le vrai soleil, lui, se couche dans la mer, tout rouge. Rouge ! Je ne savais pas qu'un soleil pouvait rougir.", {}),
					L("Devant l'Institut, il y a la cheminée qui fume au fond de la mer, et tout autour, des grands vers rouge et blanc. Je les appelle « les sucres d'orge ». Le Professeur Benthos a cherché un nom plus savant. Il n'a pas trouvé mieux. C'est moi qui ai gagné.", {"sujet_min": ["ile", 1]}, "rire"),
					L("La Grande Chanteuse, c'est une baleine. Quand elle passe au-dessus du Dôme, elle chante, et tout le monde se tait. Même Ernest. Le Professeur Benthos dit qu'elle remonte respirer à la surface. Alors elle voit le ciel tous les jours ! Je suis un peu jalouse d'une baleine. C'est bizarre, comme sentiment.", {"sujet_min": ["ile", 2]}, "rire"),
					L("Madame Nautile dit que la Colonne relie quatre mondes, comme les étages d'une maison. La cave, c'est nous. Mais une cave avec une baleine ! Au-dessus, les Strates, avec un soleil en laiton. Au-dessus, Hautefond, avec le vrai ciel. Et tout en haut, une ville posée sur les nuages ! Je veux faire tous les étages. En une journée. Avec la classe.", {"sujet_min": ["ile", 3]}),
					L("Tu as rencontré une petite fille, dans l'Atlantide ? Ondine ? Elle est née sous un dôme, comme moi ? Elle n'a jamais vu le soleil, elle non plus ? … Alors on pourrait monter le voir ensemble ! Toutes les deux ! Avec Lili ! Ça ferait trois filles qui découvrent tout !", {"a_rencontre": "ondine"}, "rire"),
				],
				"rumeur": [
					L("Le Professeur Benthos parle à la baleine. Il dit qu'elle lui répond. Un soir, j'ai collé un verre contre la vitre, et mon oreille contre le verre. J'ai entendu « hmmmmmm ». Le Professeur a dit que ça voulait dire « bonsoir, Mila ». Je crois qu'il invente. Mais je l'ai noté quand même.", {}, "rire"),
					L("Marius me laisse sonner la cloche du Funiculaire, le soir, pour le dernier départ. Ding-ding ! Après, je demande à chaque voyageur qui descend : « C'est comment, le ciel ? » Un monsieur m'a répondu : « Grand. » C'est tout. J'ai écrit « grand » dans mon cahier. En très grand.", {}, "rire"),
					L("Lou dit que, tout au fond de la Fosse, il y a des petites lumières qui s'allument et s'éteignent. Même le Professeur ne sait pas ce que c'est. Moi, je crois que ce sont des étoiles tombées dans la mer. Madame Nautile dit que c'est possible. Elle dit ça quand elle ne sait pas. J'aime bien quand elle ne sait pas.", {}),
					L("Il y a un garçon des Strates, Tom, qui parle à une fille d'en haut en tapant sur la roche. Deux coups, puis un : ça veut dire bonjour. Moi, j'ai essayé de taper sur la vitre pour parler aux poissons. Yolande m'a vue. Elle a dit : « Deux coups, puis un, d'accord. Pas plus. » Les poissons n'ont pas répondu. Ils sont timides.", {"a_rencontre": "tom_st"}, "rire"),
					L("Un garçon de la Fronde, Ressort, est descendu avec sa planche à roulettes. Il voulait rouler dans la Galerie de verre. Madame Nautile a dit non. Il a dit que, quand il sera grand, il fera une rampe des Nuées jusqu'au Dôme. Je lui ai dit que je serais la première à descendre. Il a dit : « Après moi. » On verra.", {"a_rencontre": "ressort"}, "rire"),
				],
				"interpelle": [L("Hé ! Tu viens d'en haut ? C'est comment, le ciel ?", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une nouvelle question !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir ! Si tu vois la pluie, là-haut, ouvre la bouche et goûte-la. Puis reviens me dire si elle est salée.", {}, "salut"), L("Si tu croises un oiseau, demande-lui comment il fait pour tenir dans l'air sans tomber. Je veux la vraie réponse. Bonnes bulles !", {}, "rire"), L("Bonne nuit ! La Perle est toute violette. Là-haut, il paraît que la nuit, il y a des étoiles. Des milliers. Moi, je les compterais toutes. Je ne dormirais jamais.", {"soir": true})],
				"souvenir": [L("Toi ? Je me souviens de tout de toi ! Tu es dans mon Cahier du Ciel, page quatre. Tu m'as expliqué les nuages. Mon dessin n'est pas très ressemblant. Mais il est très gentil.", {})],
			}},
		{"id": "odile", "nom": "Madame Odile Nautile", "titre": "institutrice de l'École des Abysses", "maison": "porte_odile", "village": "dome",
			"agenda": [[7, 8, "da_place_banc_2"], [8, 12, "da_ecole_tableau"], [12, 13, "da_ecole_banc_2"], [13, 16, "da_ecole_tableau"], [16, 18, "da_jardin_1"], [18, 20, "da_conque_table_4"], [20, 22, "da_hublot_4"], [22, 7, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "chignon", "yeux": Y_GRIS, "haut": AIGUE_PALE, "robe": NUIT, "robe_longue": true, "lunettes": true, "taille": 0.98},
			"teinte": PEAU[2],
			"neo": {"tenue": "tailleur", "c": AIGUE_PALE, "c2": NUIT, "objet": "livre"},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"carte_postale": 3.0, "plume_corbeau": 2.0, "bouquet_tournesols": 2.0, "lettre_azur": 1.5, "the_sommets": 1.5, "chouquettes": 1.5}, "deteste": {"bombe_peinture": -1.0, "gelee_slime": -1.0},
			"tics": ["Les mains sur les genoux.", "Lève la main avant de demander.", "Bien. Très bien.", "Leçon de ciel !"],
			"surnoms": [[0, "nouvel élève"], [25, "bon élève"], [50, "mon élève modèle"], [75, "mon assistant de classe"], [95, "ma plus belle leçon"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Madame Odile Nautile, institutrice de l'École des Abysses. Tu viens d'en haut ? Parfait. Mes élèves n'ont jamais vu le ciel. Toi, si. Alors, un de ces jours, c'est toi qui feras la leçon. Prépare-toi : ils posent beaucoup de questions. Surtout une petite, avec des boucles. Mila. Tu la reconnaîtras : elle aura déjà commencé.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu reviens au bon moment : c'est l'heure de la Leçon de Ciel. Aujourd'hui, les nuages. Tu veux bien leur expliquer ce que c'est ? Avec les mains. Ils comprennent mieux avec les mains.", {"visites_min": 2}, "rire"),
					L("Ah, {surnom}. Ta chaise t'attend au fond de la classe. Personne n'a le droit de s'y asseoir. Mila a essayé. Je l'ai renvoyée à sa place. Gentiment. Fermement. Les deux.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Un peu lasse. J'ai expliqué la pluie toute la matinée. De l'eau qui tombe du ciel, toute seule, sans tuyau. Mes élèves m'ont regardée comme si je racontais un conte de fées. Il me faudrait une vraie pluie. Une petite. Juste pour la classe.", {"humeur_max": -0.2}),
					L("Très bien. Les élèves ont dessiné le ciel. Quatorze ciels différents. Un vert, un à pois, un avec un plafond. Aucun n'est juste. Ils sont tous magnifiques. Je les ai accrochés au Mur du Dessus.", {}, "rire"),
					L("Émue. Depuis la réouverture, des familles d'en haut viennent visiter l'école. Un enfant d'en haut demande à un enfant d'ici : « C'est comment, la mer, de dedans ? » Et l'autre répond : « Et le ciel, de dessous ? » Et ils se racontent. Je n'ai plus rien à faire. C'est la meilleure leçon de l'année.", {}),
					L("Le matin, avant la classe, je m'installe sur un banc de la Place pendant que la Grande Perle s'éclaire. Je prépare ma leçon dans ma tête. Et je me souviens du vrai soleil, la seule fois où je l'ai vu se lever. Je garde ce souvenir pour les jours où il me faut du courage.", {"matin": true}),
					L("Le soir, je longe la Promenade des Hublots en corrigeant des cahiers dans ma tête. Dehors, les méduses s'allument, et les poissons-lanternes passent en rangs, bien sages. Ils sont mieux élevés que ma classe. Mais ma classe est plus drôle.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je suis née ici, au Dôme, comme mes élèves. À dix-huit ans, j'ai pris le Funiculaire pour aller étudier à Hautefond. En sortant de la Colonne, j'ai vu le ciel pour la première fois. Je me suis assise par terre, au milieu de la Place, et j'ai pleuré une heure. Une jeune liftière m'a apporté un chocolat. Elle ne m'a rien demandé. Je ne l'ai jamais oubliée.", {}),
					L("J'enseigne « le dessus », comme on dit ici : le ciel, le vent, la pluie, les oiseaux, les arbres. Avec des cartes postales de Hautefond et des Nuées. Pendant les douze ans de ligne fermée, c'était tout ce que j'avais. La Place de la Colonne, le Belvédère, la Cité des Nuées au-dessus des nuages. Mes élèves les connaissent par cœur. Ils n'avaient jamais vu le vrai.", {"sujet_min": ["lui", 1]}),
					L("Au fond de ma classe, il y a le Mur du Dessus : toutes les cartes postales reçues en vingt ans, chacune avec une punaise dorée. Quand un élève voit enfin le vrai paysage d'une carte, il a le droit d'enlever la punaise et de garder la carte. Pendant douze ans, personne n'a pu enlever une seule punaise. Cette semaine, trois.", {"sujet_min": ["lui", 2]}),
					L("Je vais te confier mon rêve, {surnom}. Emmener toute ma classe en haut. En une journée : les Strates, Hautefond, et jusqu'à la Cité des Nuées. De la mer au ciel, en une seule journée. Quatorze enfants qui découvrent le ciel, tous ensemble. Je ne sais pas qui pleurera le plus. Sûrement moi.", {"sujet_min": ["lui", 3]}),
					L("Tu connais Mademoiselle Philippine, à la Bibliothèque des Cartes de Hautefond ? Elle m'envoie des cartes du ciel pour ma classe, avec des flèches pour les vents. Sur la dernière, elle a dessiné le Dôme d'Azur d'après mes lettres, avec la Grande Chanteuse au-dessus. La baleine est aussi grande que la ville. Mes élèves trouvent ça très juste.", {"a_rencontre": "philippine"}, "rire"),
				],
				"ile": [
					L("L'École des Abysses, c'est au sud de la Place de la Perle. Deux bancs, un tableau, une cour, et une grande baie vitrée sur la mer. Quand un banc de poissons passe, toute la classe se retourne. J'ai renoncé à me fâcher. Maintenant, je compte les poissons avec eux. C'est une leçon de calcul.", {}, "rire"),
					L("Ici, les enfants savent des choses que les enfants d'en haut ignorent : le nom de toutes les méduses, l'heure à laquelle la Perle change de couleur, la façon dont on respire sous un dôme. Mais ils ne savent pas ce qu'est un coucher de soleil. Chacun ses trésors. Chacun ses manques.", {"sujet_min": ["ile", 1]}),
					L("La Leçon de Ciel, c'est tous les jeudis. On s'allonge dans la cour, on ferme les yeux, et je raconte le ciel : bleu, très haut, sans plafond, avec du vent qui passe. Les enfants lèvent les bras. Une fois, Mila a dit : « Je le touche. » Je ne l'ai pas contredite.", {"sujet_min": ["ile", 2]}),
					L("J'enseigne la Colonne comme une maison à étages. Les Nuées au grenier, Hautefond au salon, les Strates à l'atelier, et nous… à la cave. Mila a protesté : « Une cave avec une baleine, c'est la plus belle pièce. » Elle a eu dix sur dix.", {"sujet_min": ["ile", 3]}, "rire"),
					L("Une peintre des Nuées, Ombeline, est descendue avec quarante tubes de bleu. Elle voulait peindre la lumière du Dôme. Elle est restée trois jours. Elle est repartie en demandant du violet : elle avait vu la Grande Perle le soir. Elle a laissé un tableau à l'école. Un ciel. Le premier vrai ciel de ma classe.", {"a_rencontre": "ombeline"}),
				],
				"rumeur": [
					L("La petite Mila pose des questions plus vite que je ne réponds. « Pourquoi le ciel est bleu ? Pourquoi la pluie tombe ? Pourquoi les oiseaux ne tombent pas ? » Je réponds à une, elle en pose trois. C'est épuisant. Et je ne l'échangerais contre aucune autre élève.", {}, "rire"),
					L("La Présidente Ondine a reçu une pétition de mes élèves : « Pour que tous les enfants du Dôme voient le ciel. » Quatorze signatures, plus Lou, plus le Professeur Benthos, deux fois. Elle l'a lue debout devant le Conseil. Elle a été votée à l'unanimité. Maintenant, il faut organiser le voyage. Je n'en dors plus.", {}),
					L("Le Professeur Benthos vient faire la classe une fois par mois. Il devait parler des méduses. Il a parlé de la baleine pendant deux heures. Les enfants étaient fascinés. Moi aussi. Je n'ai pas osé l'interrompre. Les méduses attendront le mois prochain.", {}, "rire"),
					L("La Première Conseillère des Nuées, Céleste Altaïr, m'a envoyé une carte postale de sa terrasse, avec un mot de sa fille, Lili : « Bonjour, la classe d'en bas. Est-ce que la mer fait du bruit ? » Mes élèves ont répondu tous ensemble. Quatorze pages. Avec une baleine dessinée sur chaque page.", {"a_rencontre": "celeste_nu"}),
					L("Josette m'a appris à faire la limonade bleue avec la classe. On a mis de la spiruline partout : sur les cahiers, sur les murs, sur les élèves. Toute la classe a eu la langue bleue pendant deux jours. Les parents ont été très compréhensifs. Enfin, presque tous.", {}, "rire"),
				],
				"interpelle": [L("Toi ! Oui, toi. Tu viens d'en haut ? Viens, j'ai besoin de toi pour une leçon.", {"visites_max": 0}, "salut"), L("{surnom} ! C'est l'heure de la Leçon de Ciel !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Et quand tu seras là-haut, regarde le ciel une minute de plus. Pour nous. Pour toute la classe.", {}, "salut"), L("Bonnes bulles ! Et si tu as une carte postale de là-haut, garde-la pour mon Mur du Dessus. Même pliée. Même tachée.", {}), L("Bonsoir. Je rentre préparer la leçon de demain : le vent. J'emmènerai la classe à la grille de la Cheminée d'Air. Il n'en descend qu'un tout petit. Mais c'est un vrai.", {"soir": true})],
				"souvenir": [L("Comment t'oublier ? Tu as expliqué le vent à ma classe en soufflant sur leurs cheveux. Ils en parlent encore. C'était la meilleure leçon du trimestre. Et ce n'était même pas la mienne.", {}, "rire")],
			}},
	]

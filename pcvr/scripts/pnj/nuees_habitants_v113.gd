extends RefCounted
## V113 : les gens de la Cité des Nuées, l'île flottante posée à deux cents mètres au-dessus de
## Hautefond (un peu au nord-ouest de la Grande Colonne), sur sa montagne de roche renversée que
## tiennent en l'air, depuis cent vingt ans, les quatre Sustentateurs de Séraphin Altaïr. Une ville
## futuriste, mais réaliste et lumineuse : béton blanc, verre clair, bois blond, jardins partout,
## panneaux solaires, éoliennes, eau des nuages. La Ligne des Nuées (la capsule de verre blanc qui
## monte du Belvédère de Hautefond à la Gare des Nuées) vient de rouvrir, après trois ans de révision.
##  - la Gare des Nuées et le Belvédère de verre : Théo Zénith, le liftier de la Ligne (correspondant de
##    Barnabé, l'apprenti liftier de Hautefond qui a le vertige) ;
##  - l'Esplanade du Ciel : Céleste Altaïr (la Première Conseillère), sa fille Lili (10 ans, qui n'est
##    jamais descendue « en bas ») et le Grand-Père Séverin (le petit-fils de Séraphin) ; Gustave Cumulus
##    (le Café Cumulus, sans une goutte d'alcool) et Mireille Volta (l'Atelier des Inventeurs) ;
##  - l'Institut des Vents : le Docteur Aurèle Brise (le météorologue) et, dans la Salle des
##    Sustentateurs, l'Ingénieure Nova Volant ;
##  - les Serres d'Altitude : Flora Verdine (la jardinière aux fraises géantes) ;
##  - le Port des Nuées : la Capitaine Zéphyrine Ailée (la Libellule ; rivale de la Capitaine Héloïse)
##    et Icare Plané (le moniteur de planeur) ;
##  - les Résidences des Terrasses : Monsieur Pascal Pression (le retraité ronchon au cœur d'or) ;
##  - partout : Ombeline (la peintre des couchers de soleil) et Plumeau (le robot jardinier).
## Pas encore de quête aux Nuées : la ligne de la Colonne vers les Strates et la Fronde (sous
## Hautefond) a rouvert à son tour (V114), puis celle du Dôme d'Azur (au fond de la mer, V115 : la cage
## de laiton de la Gare des Strates, puis le Funiculaire d'Azur).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd), même corps que Néopolis (fiche « neo », pnj_neo_v95.gd), mais en clair et sans
## implant : tenue (tailleur | combinaison | techwear | jardinier | service | chef | enfant | sweat |
## mecano | artiste), c, c2 (les couleurs de la tenue : blanc, crème, bleu ciel, sable, vert sauge,
## gris doux), chapeau, objet ; seul Plumeau est un androïde (peau de polymère blanc, yeux bleu doux).
## Fiche « village » : nuees. Identifiants : ces prénoms existent déjà ailleurs dans l'archipel, alors
## on suffixe « _nu » : theo_nu, celeste_nu, nova_nu, gustave_nu, lili_nu, zephyrine_nu ; leur porte
## reste « porte_<prénom> » (porte_theo, porte_celeste…). Les autres gardent leur prénom.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bon vent, {surnom} ! Et garde la tête dans les nuages : ici, c'est un compliment.", "si": {"genre": "humain"}, "geste": "salut"},
		{"t": "Bon vent, {surnom}. Au revoir enregistré. Retour prévu : bientôt, j'espère.", "si": {"genre": "android"}, "geste": "salut"},
		{"t": "À plus tard ! Et ne te penche pas trop à la balustrade : le Plancher est loin, et il ne rend jamais les chapeaux.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit ! Écoute : sous nos pieds, les Sustentateurs ronronnent. L'Ingénieure Nova dit qu'ils comptent les étoiles.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! Ici, on ne se cogne qu'aux nuages. Et encore : doucement.", "si": {"genre": "humain"}, "geste": "colere", "humeur": -0.4},
		{"t": "Choc détecté. Coque intacte. Sentiments… un peu froissés. Je le note.", "si": {"genre": "android"}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu veux que j'appelle la Première Conseillère ? Elle te ferait un bulletin météo : avis de tempête sur ta tête.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Merci. Je vais le poser sur mon balcon, entre les fraisiers et le panneau solaire.", "si": {"genre": "humain"}},
		{"t": "Objet reçu. Classement : gentillesse. Merci, {surnom}.", "si": {"genre": "android"}},
		{"t": "Merci, {surnom}. Ici, on dit qu'un cadeau, ça fait monter le cœur au-dessus des nuages.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Par les nuées, {surnom}, tu as visé juste !", "si": {"genre": "humain"}, "geste": "rire"},
		{"t": "{dernier_cadeau}… Mes capteurs indiquent : joie, cent pour cent. Je ne savais pas qu'ils montaient si haut.", "si": {"genre": "android"}, "geste": "rire"},
		{"t": "Ça, c'est un cadeau qui plane ! Merci, {surnom}. Toute l'Esplanade va le savoir.", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Euh… merci. Je vais le… recycler. Ici, on recycle tout. Surtout ça.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Ici, le plus dangereux, c'est le vent d'ouest. Et il ne craint pas les épées.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Sur une île de deux cents mètres de large, on finit par connaître tout le monde. Et ses chaussures.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Ici, on ne te demande qu'une chose : ne rien jeter par-dessus la balustrade.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les nuages ne vont jamais à l'école ? Parce qu'ils sont déjà au-dessus de tout le monde. … Le Docteur Aurèle dit que c'est faux : ici, ils sont en dessous.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un sustentateur dit à un autre sustentateur ? « On reste en l'air ? » Et l'autre répond : « On n'a pas vraiment le choix. »", "si": {}, "geste": "rire"},
		{"t": "Un voyageur arrive à la Gare des Nuées : « C'est haut, ici ! » Théo, tout content : « Attendez de voir le Belvédère. C'est haut ET transparent. »", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on un nuage qui raconte des blagues ? Un cumulus de rire. … Gustave adore celle-là. Il dit que c'est son nom de famille.", "si": {}, "geste": "rire"},
		{"t": "Blague enregistrée : « Pourquoi le soleil ne descend-il jamais au Plancher ? Parce qu'il a le vertige. » Analyse : je ne comprends pas. Mais le Docteur Aurèle rit toujours.", "si": {"genre": "android"}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis, prends ce qu'il te faut. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Non. Ma boutique est fermée. Pour toi, en tout cas. Reviens quand le ciel se sera dégagé entre nous.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Ça plane !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu n'en as que {pieces}… Même un nuage ne flotte pas sans un peu d'air.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Ici, on évite le gaspillage. Un, c'est assez.", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}. Même la Libellule refuserait de le soulever.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces, et un « bon vent » en prime !", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Bon… parce que tu as une bonne tête de voyageur. Un petit geste. Ne le dis pas à Monsieur Pascal, il en ferait une réclamation au Conseil.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Marchander ? Mes prix sont calculés au plus juste, comme la portance des Sustentateurs. Non.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui, petit malin. Ici, l'air est léger, mais la mémoire est lourde.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par les nuées !", "Ça plane !", "Ha ha !", "Quel ciel !"],
		"neutre": ["Bon.", "Voyons…", "Hm.", "Alors…"],
		"triste": ["Hélas…", "Pfff…", "Quel brouillard…", "Ça ne plane plus…"],
		"colere": ["Par tous les vents !", "Ça suffit !", "Grrr.", "Tss."],
	},
	"tics": ["Bon vent !", "Ça plane !", "Par les nuées !", "Garde la tête dans les nuages."],
	"humeur_mots": [[0.6, "au septième ciel"], [0.25, "de bonne humeur"], [-0.25, "un peu nuageux"], [-0.6, "orageux"], [-2.0, "en pleine tempête"]],
	"surnoms": [[0, "voyageur"], [25, "ami des hauteurs"], [50, "mon camarade de ciel"], [75, "tête dans les nuages"], [95, "enfant des Nuées"]],
}

const BASE_ANDROID := {
	"prefixes": {
		"joie": ["Joie détectée.", "Excellent.", "Bip joyeux.", "Ça plane. (Expression locale.)"],
		"neutre": ["Bien.", "Noté.", "Traitement…", "Affirmatif."],
		"triste": ["Batterie morale faible.", "Hmm.", "Dommage.", "Une feuille est tombée."],
		"colere": ["Désaccord.", "Non.", "Alerte.", "Je proteste. Poliment."],
	},
	"tics": ["Bip.", "Je calcule.", "Bonjour, l'arbre.", "C'est logique."],
	"humeur_mots": [[0.6, "à cent pour cent"], [0.25, "bien chargé"], [-0.25, "un peu déchargé"], [-0.6, "en mode économie"], [-2.0, "en erreur rouge"]],
	"surnoms": [[0, "visiteur"], [25, "visiteur ami"], [50, "ami enregistré"], [75, "ami prioritaire"], [95, "ami pour toujours (sauvegardé)"]],
}

## Peaux (des humains) : du plus clair au plus foncé.
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24], [1.0, 0.9, 0.8]]
const BLOND := [0.86, 0.68, 0.32]
const BLOND_PALE := [0.92, 0.84, 0.6]
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
## Les couleurs claires des Nuées (les tenues).
const NEIGE := [0.95, 0.95, 0.96]
const CREME := [0.95, 0.92, 0.84]
const CIEL := [0.55, 0.76, 0.95]
const CIEL_PALE := [0.78, 0.88, 0.97]
const SABLE := [0.86, 0.78, 0.62]
const SAUGE := [0.62, 0.72, 0.58]
const GRIS_DOUX := [0.76, 0.78, 0.8]
const LAVANDE := [0.8, 0.78, 0.92]
## Le bleu doux des yeux et des voyants de Plumeau.
const BLEU_DOUX := [0.55, 0.78, 1.0]


static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	return Azur.L(t, si, geste)


static func is_android(d: Dictionary) -> bool:
	return bool((d.get("neo", {}) as Dictionary).get("android", false))


static func complete(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var genre: String = "android" if is_android(out) else "humain"
	var rep: Dictionary = out.get("repliques", {})
	for k in COMMON:
		if not rep.has(k):
			var lst: Array = []
			for e in COMMON[k]:
				var si: Dictionary = (e as Dictionary).get("si", {})
				if si.has("genre") and str(si["genre"]) != genre:
					continue
				var e2: Dictionary = (e as Dictionary).duplicate(true)
				(e2["si"] as Dictionary).erase("genre")
				lst.append(e2)
			rep[k] = lst
	out["repliques"] = rep
	var base: Dictionary = BASE_ANDROID if genre == "android" else BASE
	for k in ["prefixes", "tics", "humeur_mots", "surnoms"]:
		if not out.has(k):
			out[k] = base[k]
	out = Azur.complete(out)
	out["groupe"] = "nuees"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ la Gare des Nuées
		{"id": "theo_nu", "nom": "Théo Zénith", "titre": "liftier de la Ligne des Nuées", "maison": "porte_theo", "village": "nuees",
			"agenda": [[6, 7, "gare_guichet"], [7, 12, "gare_quai"], [12, 13, "cafe_table_2"], [13, 19, "gare_quai"], [19, 21, "belvedere_verre_1"], [21, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "yeux": Y_BLEU, "chapeau": "casquette", "chapeau_c": CIEL, "haut": NEIGE, "taille": 1.0, "carrure": 0.95},
			"teinte": PEAU[3],
			"neo": {"tenue": "service", "c": NEIGE, "c2": CIEL, "chapeau": "casquette", "chapeau_c": CIEL},
			"humeur_base": 0.75, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"carte_postale": 2.5, "lait_nuage": 2.0, "chocolat_chaud": 2.0, "chouquettes": 1.5, "plume_vent": 1.5, "parapluie_helice": 1.5}, "deteste": {"vieille_botte": -1.0, "gelee_slime": -1.0},
			"tics": ["Ça plane !", "Plus haut !", "Youpi ! … Pardon. Professionnalisme.", "Barnabé dirait…"],
			"surnoms": [[0, "passager"], [25, "copain de capsule"], [50, "mon pote des hauteurs"], [75, "mon copilote"], [95, "mon passager préféré du ciel"]],
			"repliques": {
				"accueil": [
					L("Bienvenue à la Gare des Nuées ! Théo Zénith, liftier de la Ligne ! Tu viens de monter deux cents mètres dans une capsule de verre. Deux cents ! Tu as vu la vue ? Moi, je l'ai vue dix mille fois, et je fais encore « waouh » à chaque montée. Et un petit saut. La capsule a l'habitude.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu remontes avec moi ? Dis oui. Dis oui ! Il y a un nuage tout neuf sous la Gare, le Docteur Aurèle ne l'a même pas encore baptisé !", {"visites_min": 2}, "rire"),
					L("Te revoilà ! Tu es mon passager le plus régulier, après Monsieur Pascal. Lui, il descend acheter son pain au Plancher. Il dit qu'il est meilleur en bas. Ne le répète surtout pas à Gustave.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Bof. Un nuage tout gris est resté sous la Gare toute la journée. On ne voyait plus Hautefond. Les passagers demandaient « on est où ? ». Je répondais « dans le ciel ! ». Ils ne trouvaient pas ça assez précis.", {"humeur_max": -0.2}),
					L("Au sommet ! La Ligne a rouvert, {surnom} ! Trois ans de révision, trois ans à astiquer une capsule qui ne bougeait pas. Aujourd'hui, j'ai fait quarante montées. Quarante ! Je suis le liftier le plus heureux du ciel.", {}, "rire"),
					L("Un peu fatigué des genoux. Je saute de joie à chaque départ. L'Ingénieure Nova dit que ça déséquilibre la capsule d'un millimètre. Un millimètre de bonheur, je trouve ça raisonnable.", {}),
					L("Ce matin, la capsule a traversé le nuage pile au lever du soleil. Tout est devenu rose. Une dame a applaudi. Moi aussi. On était deux à applaudir un nuage. C'était très bien.", {"matin": true}, "rire"),
					L("Le soir, je vais au Belvédère de verre et je regarde la Colonne, tout en bas, qui s'allume. Quelque part là-dessous, il y a Barnabé qui regarde vers le haut. Enfin, qui essaie.", {"soir": true}),
				],
				"lui": [
					L("J'ai voulu être liftier le jour où je suis tombé d'un arbre du Parc des Brumes. Je n'ai pas eu peur : j'ai eu envie de recommencer. Ma mère a dit : « Trouve un métier où l'on monte avec un câble. » Voilà.", {}),
					L("Depuis cinq ans, j'écris à Barnabé, l'apprenti liftier de Hautefond. Lui en bas, moi en haut. On se raconte nos montées. Lui, il me raconte surtout ses descentes. Il a le vertige ! Un liftier qui a le vertige ! C'est le garçon le plus courageux que je connaisse.", {"sujet_min": ["lui", 1]}),
					L("Le jour de la réouverture, on s'est enfin vus en vrai. Il est sorti de la capsule tout vert, il m'a serré la main très fort, et il a dit : « Tu es plus grand que dans tes lettres. » Puis il s'est assis sur le quai. Je me suis assis à côté. On a parlé deux heures. Par terre. C'était parfait.", {"sujet_min": ["lui", 2]}),
					L("Tu as rencontré Barnabé ? Alors tu sais. Il a l'air d'avoir peur de tout, et il revient quand même tous les jours. Moi, je n'ai peur de rien, alors ça ne compte pas. Lui, ça compte double.", {"a_rencontre": "barnabe_hf"}),
				],
				"ile": [
					L("Tu as vu Maîtresse Capucine, au pied de la Colonne ? Elle m'a offert une casquette de la Confrérie pour la réouverture. Bleu nuit, galon doré. Je la porte le dimanche. Le reste de la semaine, je la regarde.", {"a_rencontre": "capucine_hf"}),
					L("La Ligne des Nuées part du Belvédère de Hautefond et monte jusqu'ici, dans une cage de verre blanc. Deux cents mètres de ciel ! Au milieu, on traverse les nuages. Pendant dix secondes, tout est blanc. Les gens retiennent leur souffle. Moi, je chante.", {}),
					L("Juste à côté de la Gare, il y a le Belvédère de verre : le plancher est transparent, au-dessus du vide. On voit Hautefond, la Colonne, la mer… J'y vais tous les soirs. Barnabé m'a promis de venir. Un jour. Il a dit « un jour » en tremblant un peu.", {"sujet_min": ["ile", 1]}),
					L("La Colonne descend aussi sous Hautefond, vers les Strates et la Fronde, et tout au fond de la mer, jusqu'au Dôme d'Azur. La ligne des Strates a rouvert, et maintenant celle du Dôme aussi ! Je vais enfin pouvoir faire le trajet en entier : du ciel jusqu'au fond de la mer. Le plus grand ascenseur du monde !", {"sujet_min": ["ile", 2]}),
					L("Le soir, du Belvédère de verre, je regarde la Colonne. Avant, pour moi, elle s'arrêtait à la Place. Maintenant, je sais qu'elle continue sous la terre, jusqu'à une gare où un vieux liftier, Anatole, répond « Comment ? » à tout le monde. Barnabé l'adore.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Tu es passé au Piston Joyeux, en bas ? Firmin, le frère de Gustave, envoie un chocolat par la première capsule du matin. Il arrive encore chaud. Gustave le goûte, fait la grimace, et le finit. Tous les matins.", {"a_rencontre": "firmin"}, "rire"),
					L("Maîtresse Capucine est montée pour la réouverture. Elle a posé la main sur la capsule et elle a dit : « Elle est bien élevée. » C'est le plus beau compliment qu'elle ait jamais fait, paraît-il. J'en ai pleuré un peu. La capsule aussi. Enfin, c'était de la condensation.", {}, "rire"),
					L("Monsieur Pascal se plaint des gens du Plancher qui font la queue à la Gare. Mais chaque matin, il vient s'asseoir sur le banc pour regarder la queue. « Pour surveiller », dit-il. Il sourit quand les enfants font « waouh ». Je l'ai vu.", {}),
					L("Lili, la fille de la Première Conseillère, vient voir partir chaque capsule. Elle n'est jamais descendue. Elle me demande : « C'est comment, la mer, de près ? » Je lui réponds : « Mouillé. » Elle trouve que je ne suis pas assez poétique.", {}, "rire"),
					L("Tu as rencontré Anatole, le liftier des Strates ? On s'est parlé par le tuyau acoustique : deux cents mètres de haut, plus cent sous terre. Je lui ai dit bonjour. Il a répondu « Comment ? ». Je crois que c'est sa façon de dire bonjour.", {"a_rencontre": "anatole"}, "rire"),
				],
				"interpelle": [L("Hé ! Tu montes ? Enfin, tu descends ? Enfin… tu viens ?", {"visites_max": 0}, "salut"), L("{surnom} ! La capsule part dans deux minutes ! Ça plane !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom} ! Et si tu vois Barnabé en bas, dis-lui que je l'attends au Belvédère de verre. Avec une chaise.", {}, "salut"), L("À plus ! Moi, je redescends. Puis je remonte. Puis je redescends. C'est ça, le métier !", {}, "rire"), L("Bonne nuit ! Dernière capsule à vingt et une heures. Après, elle dort dans sa gare, toute blanche, comme un œuf.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Évidemment ! Tu as fait « waouh » à ta première montée. Tout le monde fait « waouh ». Mais toi, tu l'as fait avec style.", {})],
			}},
		# ================================================================ l'Esplanade du Ciel
		{"id": "celeste_nu", "nom": "Céleste Altaïr", "titre": "Première Conseillère de la Cité des Nuées", "maison": "porte_celeste", "village": "nuees", "vouvoie": true,
			"agenda": [[7, 8, "conseil_terrasse"], [8, 12, "conseil_bureau"], [12, 14, "esplanade_fontaine"], [14, 18, "conseil_bureau"], [18, 20, "conseil_terrasse"], [20, 7, "maison"]],
			"azur": {"cheveux": BLOND_PALE, "coiffure": "chignon", "yeux": Y_GRIS, "haut": CREME, "robe": CIEL_PALE, "robe_longue": true, "taille": 1.04},
			"teinte": PEAU[1],
			"neo": {"tenue": "tailleur", "c": CREME, "c2": CIEL},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"the_sommets": 2.5, "fraise_geante": 2.0, "fleur_nebuleuse": 2.0, "carte_postale": 1.5, "tisane_brume": 1.5}, "deteste": {"bombe_peinture": -1.5, "vieille_botte": -1.0},
			"tics": ["Un léger vent d'est sur ce dossier.", "Éclaircies en vue.", "Bon vent.", "Gardons la tête dans les nuages."],
			"surnoms": [[0, "cher visiteur"], [25, "cher hôte"], [50, "cher ami des Nuées"], [75, "mon éclaircie"], [95, "citoyen d'honneur du ciel"]],
			"repliques": {
				"accueil": [
					L("Bienvenue dans la Cité des Nuées. Céleste Altaïr, Première Conseillère. Vous arrivez par un temps magnifique : grand soleil, vent léger, et une humeur générale en nette hausse depuis la réouverture de la Ligne. Prenez votre temps. Ici, même le temps prend le sien.", {"visites_max": 1}, "salut"),
					L("{surnom}. Quelle belle éclaircie dans ma journée. Asseyez-vous un instant : j'ai trois dossiers, deux réunions et une petite fille qui a perdu son cerf-volant. Je commence par le cerf-volant.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Brumeuse, je l'avoue. Lili a encore demandé à descendre. J'ai dit « bientôt ». Elle a boudé toute la journée. Un front froid s'est installé sur la maison.", {"humeur_max": -0.2}),
					L("Ensoleillée, avec quelques passages nuageux en fin d'après-midi. Le Conseil a voté le budget des Serres. Monsieur Pascal a voté contre. Puis il est venu me demander si l'on pouvait ajouter un nichoir. Nous l'avons ajouté.", {}, "rire"),
					L("Un léger vent d'est sur mon moral. La Ligne a rouvert, tout le monde monte voir, et les gens du Plancher font la queue jusqu'au Belvédère. Je suis ravie. Mes bancs le sont moins.", {}),
					L("Tempête dans un dossier, ce matin : faut-il appeler les gens d'en bas « le Plancher » ? Certains trouvent cela un peu hautain. Je leur ai fait remarquer que nous étions, en effet, un peu en hauteur.", {"matin": true}, "rire"),
					L("Le soir, je monte sur la terrasse du Conseil et je regarde le soleil se coucher. Ici, il se couche en dessous de nous, vous savez. Il passe sous l'île en rougissant. C'est très flatteur pour le soleil.", {"soir": true}),
				],
				"lui": [
					L("À l'âge de Lili, je voulais voir la mer, moi aussi. Ma mère disait « bientôt ». Je ne l'ai vue qu'à vingt ans. Je m'étais juré de ne jamais dire « bientôt » à ma fille. J'ai tenu une semaine.", {"sujet_min": ["lui", 3]}),
					L("Mon arrière-grand-père, Séraphin Altaïr, a fait monter cette île. Ma famille a gardé deux choses de lui : son nom, et l'habitude de regarder le ciel avant de prendre une décision. Le nom est plus facile à porter.", {}),
					L("Je parle par images météorologiques, paraît-il. « Un léger vent d'est sur ce dossier », « des éclaircies en fin de séance »… Je ne m'en rends pas compte. Le Docteur Aurèle dit que c'est contagieux. Il a des prévisions sur le sujet.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le plus difficile, dans mon métier, ce n'est pas de tenir une ville en l'air. Les Sustentateurs s'en chargent. C'est de dire non à ma fille quand elle me demande de descendre voir la mer. Je lui dis « bientôt ». Je commence à manquer de « bientôt ».", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Cité des Nuées est ronde, large de deux cents mètres, posée sur une montagne de roche à l'envers. Dessous, quatre Sustentateurs la tiennent en l'air depuis cent vingt ans. Au milieu, l'Esplanade du Ciel et la Plume de Séraphin. Au nord, la Tour du Zénith. Et partout, des jardins.", {}),
					L("Ici, nous recueillons l'eau de la pluie et des nuages, nous vivons du soleil et du vent, et nous recyclons absolument tout. Nous en sommes fiers. Un peu trop, peut-être. Le Bourgmestre Hector dit que nous recyclons même les compliments.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Les gens du Dôme d'Azur, tout au fond de la mer, sont nos cousins : deux villes de verre, l'une en l'air, l'autre sous l'eau. Leur ligne vient de rouvrir, et nous nous écrivons toujours. Ils m'envoient des coquillages. Je leur envoie des nuages en bocal. Ils arrivent vides. Ils disent merci quand même.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Vous avez rencontré le Bourgmestre Hector, en bas ? Il m'a envoyé un discours de félicitations de quarante pages pour la réouverture. Je l'ai lu en entier. Temps couvert, avec de longues éclaircies.", {"a_rencontre": "hector_hf"}, "rire"),
					L("Le Bourgmestre de Hautefond voulait couper un ruban de trente mètres pour la réouverture. Maîtresse Capucine a refusé. Ils ont fini par en couper un de trente centimètres, à deux. Je les ai trouvés très touchants. Et très lents.", {}, "rire"),
					L("La Capitaine Zéphyrine et la Capitaine Héloïse ont encore fait la course autour de la Colonne. Chacune a gagné, bien entendu. Le Conseil reçoit deux réclamations par semaine. Nous les classons ensemble, dans un dossier intitulé « Égalité ».", {}, "rire"),
					L("Mon grand-père Séverin raconte la montée de l'île à tous les visiteurs, comme s'il y était. Il n'était pas né. Mais à force de l'entendre, je finis par m'en souvenir aussi.", {}),
					L("Vous avez rencontré la Présidente Ondine, au fond de la mer ? Pour la réouverture de leur ligne, nous avons coupé le ruban à quatre : le Bourgmestre, la Doyenne Agathe, Ondine et moi. Sept centimètres et demi chacun. Elle garde mes nuages en bocal sur une étagère. Ils arrivent tous vides. Elle dit qu'ils contiennent l'intention. Éclaircie générale sur mon moral.", {"a_rencontre": "ondine_da"}),
				],
				"interpelle": [L("Bonjour ! Vous êtes nouveau, n'est-ce pas ? Cela se voit : vous regardez en l'air.", {"visites_max": 0}, "salut"), L("{surnom} ! Le ciel est clair aujourd'hui. Venez donc.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom}. Que vos journées soient ensoleillées, et vos soucis légers comme un cumulus.", {}, "salut"), L("À bientôt. Et si vous croisez Lili, dites-lui de rentrer goûter. Avec ou sans cerf-volant.", {}, "rire"), L("Bonsoir, {surnom}. Nuit claire, vent faible, étoiles nombreuses. Je ne me trompe jamais sur ce bulletin-là.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Naturellement. Vous êtes arrivé un jour de grand beau temps. Ici, c'est presque tous les jours. Mais ce jour-là était plus beau.", {})],
			}},
		{"id": "lili_nu", "nom": "Lili Altaïr", "titre": "fille de la Première Conseillère (10 ans), pilote de cerfs-volants", "maison": "porte_lili", "village": "nuees",
			"agenda": [[8, 10, "esplanade_banc_1"], [10, 12, "parc_pelouse"], [12, 14, "esplanade_banc_1"], [14, 17, "parc_pelouse"], [17, 19, "belvedere_verre_2"], [19, 8, "maison"]],
			"azur": {"cheveux": BLOND_PALE, "coiffure": "tresse", "yeux": Y_GRIS, "haut": CIEL, "enfant": true, "taille": 0.72},
			"teinte": PEAU[1],
			"neo": {"tenue": "enfant", "c": CIEL, "c2": NEIGE},
			"femme": true,
			"humeur_base": 0.7, "traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"cerf_volant": 3.0, "glace": 3.0, "coquillage": 2.5, "etoile_mer": 2.5, "lait_nuage": 2.0, "chouquettes": 2.0}, "deteste": {"sardine": -1.0, "champignon": -0.5},
			"tics": ["C'est comment, en bas ?", "Plus haut, plus haut !", "Je le dirai à Maman.", "Par les nuées !"],
			"surnoms": [[0, "monsieur-madame"], [25, "copain du Plancher"], [50, "mon copain de cerf-volant"], [75, "mon meilleur ami d'en bas"], [95, "mon ami de toute la terre et de tout le ciel"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Tu viens d'en bas ? Du vrai bas ? Du Plancher ? Moi, c'est Lili, j'ai dix ans, je fais voler des cerfs-volants, et je ne suis JAMAIS descendue. Jamais ! Alors raconte : la mer, c'est froid ? Ça bouge tout le temps ? Ça sent quoi ?", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu es revenu ! Tu m'as apporté un bout de mer ? Non ? Un tout petit peu de sable, même ? Dans ta chaussure ? Regarde dans ta chaussure.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Ce matin, il y avait du vent du nord ! Le meilleur pour les cerfs-volants ! Grand-Père Séverin dit que Séraphin faisait voler les siens par vent du nord, lui aussi. Je suis de la famille, ça se voit.", {"matin": true}, "rire"),
					L("Super ! Mon cerf-volant est monté si haut qu'il a touché un nuage. Il est revenu tout mouillé. Le Docteur Aurèle dit que le nuage s'appelait Bertrand. J'ai dit pardon à Bertrand.", {}, "rire"),
					L("Un peu fâchée. Maman dit « bientôt » quand je demande à descendre voir la mer. Elle dit « bientôt » depuis que j'ai six ans. Ça fait quatre bientôts. C'est beaucoup, quatre bientôts.", {}),
					L("Le soir, je vais au Belvédère de verre et je regarde la mer, tout en bas. Elle brille. Elle est toute petite. Théo dit qu'elle est très grande en vrai. Je ne sais pas si je le crois.", {"soir": true}),
				],
				"lui": [
					L("Quand je serai descendue, je ramasserai un coquillage pour chaque personne de la Cité. Ça fait beaucoup de coquillages. J'ai déjà préparé un grand sac. Il est vide. Pour l'instant.", {"sujet_min": ["lui", 3]}),
					L("J'ai onze cerfs-volants. Un en forme de baleine, un en forme de poisson, un en forme de bateau, un en forme de vague… Maman dit que je fais une fixation. Moi, je dis que je m'entraîne.", {}, "rire"),
					L("Mon rêve, c'est de manger une glace sur une plage. Une vraie plage, avec du sable qui chauffe les pieds et des vagues qui chatouillent. Ici, on a du soleil tout le temps, mais pas de sable. Et les glaces, Gustave les fait au nuage. Ce n'est pas pareil.", {"sujet_min": ["lui", 1]}),
					L("Tu veux savoir un secret ? Quand je fais voler mon cerf-volant-baleine au bord de l'île, je lâche un peu de fil, puis encore un peu, pour qu'il descende vers la mer. Il est presque arrivé, une fois. Je lui ai dit de me raconter. Il n'a rien dit. Les cerfs-volants, c'est pas bavard.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Parc des Brumes, c'est le meilleur endroit pour les cerfs-volants. Il y a du vent, de l'herbe, et l'étang qui déborde par-dessus le bord de l'île : ça fait la Cascade des Nuées. L'eau tombe, tombe, et elle devient de la brume avant d'arriver en bas. Même l'eau ne descend jamais jusqu'en bas !", {}),
					L("Mon arrière-arrière-grand-père, c'est Séraphin ! Celui qui a fait monter l'île. Grand-Père Séverin dit qu'il l'a fait « pour que les enfants aient toujours du soleil ». Moi, j'aurais préféré qu'il fasse aussi un petit escalier jusqu'à la mer.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Il paraît qu'il y a une ville tout au fond de la mer, sous un dôme de verre, le Dôme d'Azur ! Avec des baleines qui passent au-dessus des maisons ! Leur ligne vient de rouvrir. Moi, j'y descends dès que Maman dit oui. Je l'ai écrit sur le calendrier de Maman. En gros. Sur tous les jours.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Tu connais Pimprenelle, en bas ? Elle est montée avec un sac plein de boulons ! Elle m'en a donné un. Moi, je lui ai donné un bout de ficelle de cerf-volant. Elle dit que c'est la meilleure ficelle du monde. Elle a raison.", {"a_rencontre": "pimprenelle_hf"}, "rire"),
					L("Plumeau, le robot jardinier, dit bonjour aux arbres. Moi aussi, maintenant. Le chêne du Parc ne répond pas, mais Plumeau dit qu'il « traite la demande ». Ça fait trois ans qu'il traite.", {}, "rire"),
					L("Monsieur Pascal fait semblant d'être grognon, mais je l'ai vu donner des miettes aux moineaux derrière les Résidences. Il m'a dit : « Tu n'as rien vu. » J'ai dit : « D'accord. » Mais j'ai tout vu.", {}, "rire"),
					L("Théo, le liftier, il saute dans la capsule quand elle part ! Il dit que c'est pour lui dire au revoir. Moi, quand je serai grande, je serai liftière, comme ça je descendrai tous les jours. Et je remonterai, sinon Maman va s'inquiéter.", {}),
					L("Tu as vu Mila, au Dôme d'Azur ? On est nées le même jour ! Elle n'a jamais vu le ciel, et moi, jamais la mer. On est pareilles, mais à l'envers ! Sa lettre est arrivée toute chiffonnée : elle est passée par quatre facteurs. Dis-lui que je lui garde un cerf-volant. Celui en forme de baleine. Comme ça, elle aura un ciel avec une baleine dedans.", {"a_rencontre": "mila"}),
				],
				"interpelle": [L("Hé ! Tu viens d'en bas ? C'est comment ?", {"visites_max": 0}, "salut"), L("{surnom} ! Regarde mon cerf-volant !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir ! Si tu vas à la plage, mange une glace pour moi. Une à la fraise. Et décris-la-moi après.", {}, "salut"), L("Salut ! Bon vent ! C'est pour les cerfs-volants, mais ça marche aussi pour les gens.", {}, "rire"), L("Bonne nuit ! Je vais rêver de la mer. Comme d'habitude.", {"soir": true})],
				"souvenir": [L("Bien sûr que je me souviens de toi ! Tu es le voyageur qui vient d'en bas. Tu sens un peu la mer. J'ai remarqué.", {})],
			}},
		{"id": "severin", "nom": "Grand-Père Séverin Altaïr", "titre": "doyen de la Cité des Nuées, petit-fils de Séraphin", "maison": "porte_severin", "village": "nuees",
			"agenda": [[8, 11, "parc_banc"], [11, 12, "promenade_2"], [12, 14, "esplanade_banc_2"], [14, 17, "parc_banc"], [17, 19, "promenade_2"], [19, 21, "esplanade_banc_2"], [21, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_GRIS, "chapeau": "beret", "chapeau_c": SABLE, "haut": CREME, "vieux": true, "taille": 0.9, "carrure": 0.9},
			"teinte": PEAU[1],
			"neo": {"tenue": "tailleur", "c": CREME, "c2": SAUGE, "chapeau": "beret", "chapeau_c": SABLE},
			"humeur_base": 0.6, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 0.4, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"the_sommets": 2.0, "chouquettes": 2.5, "gateau_miel": 2.0, "tisane_brume": 1.5, "montre_envers": 1.5, "chocolat_chaud": 1.5}, "deteste": {"lunettes_kaleido": -1.0, "sifflet_muet": -0.5},
			"tics": ["Hein ? Quoi ?", "J'y étais ! Enfin, presque.", "De mon temps…", "Ah, Séraphin…"],
			"surnoms": [[0, "jeune homme-jeune fille"], [25, "petit gars"], [50, "mon auditeur"], [75, "mon cher petit"], [95, "mon arrière-petit-voyageur"]],
			"repliques": {
				"accueil": [
					L("Approche, approche ! Assieds-toi. Séverin Altaïr, petit-fils de Séraphin, le doyen de la ville. Tu veux que je te raconte la montée de l'île ? Oui ? Parfait. Alors c'était un mardi. Ou un jeudi. Il faisait gris. C'est pour ça qu'il est monté.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu reviens pour la suite ? Où en étais-je… Ah oui : la roche se décolle, le sol tremble, et mon grand-père crie « Ça plane ! ». C'est lui qui a inventé l'expression. Je le sais. J'y étais. Enfin, presque.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Pas fameux. Mes genoux annoncent la pluie. Le Docteur Aurèle dit qu'il ne pleuvra pas. Mes genoux se trompent moins souvent que lui.", {"humeur_max": -0.2}, "rire"),
					L("Très bien ! Je n'ai pas mal aux genoux, j'ai mangé trois chouquettes, et ma petite-fille m'a dit que j'étais « encore très bavard ». À mon âge, c'est un compliment.", {}, "rire"),
					L("Hein ? Mon humeur ? Oui, il fait beau. Comment ? Ah, mon humeur. Bonne, bonne. Excuse-moi, j'entends mal. Sauf quand on parle de chouquettes. Là, j'entends très bien.", {}, "rire"),
					L("Le matin, au Parc des Brumes, la brume monte de la Cascade et fait des formes. Ce matin, j'ai vu Séraphin dedans. Il me faisait signe. Ou c'était le Docteur Aurèle. Ils ont la même barbe.", {"matin": true}),
					L("Le soir, je m'assois sur mon banc de l'Esplanade, et je regarde les lumières de Hautefond, tout en bas. Cent vingt ans que nous flottons. Et toujours la même petite envie de redescendre voir, de temps en temps.", {"soir": true}),
				],
				"lui": [
					L("Ma femme Gisèle et moi, on s'est mariés sur le Belvédère de verre. Elle avait peur du vide : elle a dit oui les yeux fermés. Soixante-dix ans plus tard, elle me dit qu'elle aurait dû regarder. Je crois qu'elle plaisante.", {"sujet_min": ["lui", 3]}, "rire"),
					L("Je suis le plus vieux de la Cité. Quatre-vingt-dix-sept ans. Je n'étais pas né quand l'île est montée, mais mon père me l'a racontée si souvent que je m'en souviens mieux que de mon propre mariage. Ne le dis pas à ma femme. Elle est au Parc, elle a l'oreille fine.", {}, "rire"),
					L("Mon grand-père Séraphin était liftier à Hautefond, dans la Confrérie. Il trouvait que la Colonne s'arrêtait trop bas. Alors un jour, il a découpé un morceau de la Butte, il a posé dessous ses Sustentateurs, et il a dit : « On monte là où il fait toujours beau. » Et c'est monté.", {"sujet_min": ["lui", 1]}),
					L("Je suis un peu sourd. Surtout quand ma petite-fille Céleste me parle de régime. Mais quand Lili me demande de lui raconter la mer, j'entends tout. Je lui raconte la mer de mon enfance, quand je descendais en bas avec mon père. Elle ferme les yeux. Elle la voit.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le jour de la montée, raconte-t-on, toute la ville de Hautefond était sur la Place. Le morceau de Butte s'est mis à trembler, puis à monter, tout doucement, avec les maisons dessus. Une vieille dame a crié : « Mon linge ! » Il était resté en bas, sur le fil. On l'a remonté le lendemain, par la Colonne.", {}, "rire"),
					L("La Plume de Séraphin, la sculpture de l'Esplanade, c'est en souvenir de sa première idée : il avait vu une plume monter dans le vent, au-dessus de la Colonne, sans jamais retomber. Il s'est dit : si une plume peut le faire, une ville aussi. Il était un peu fou. On l'aimait beaucoup.", {"sujet_min": ["ile", 1]}),
					L("Sous Hautefond, il y a les Strates. De mon temps, on y descendait par la Colonne pour acheter des cristaux. La ligne vient de rouvrir, et il paraît qu'on y fait de la musique très forte. Hein ? Comment ? Je n'entends rien. Ça tombe bien.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Hein ? La Grande Liftière d'en bas ? Capucine Rouage ? Je l'ai connue toute petite ! Enfin, j'ai connu sa grand-mère toute petite. Enfin, j'en ai entendu parler. Bref, je la connais très bien.", {"a_rencontre": "capucine_hf"}, "rire"),
					L("Le jeune Pascal se plaint de tout. Il a soixante-dix ans. Pour moi, c'est un gamin. Je lui dis : « Pascal, quand tu auras mon âge, tu auras le droit de te plaindre. » Il me répond : « Je m'entraîne. »", {}, "rire"),
					L("Plumeau, le robot, me salue tous les matins. « Bonjour, Monsieur Séverin. Bonjour, le banc. » Il dit bonjour au banc aussi. Je trouve ça très poli. Le banc, lui, n'a jamais répondu. Il est plus vieux que moi.", {}, "rire"),
					L("Mon arrière-petite-fille Lili veut voir la mer. Sa mère dit « bientôt ». Moi, je lui ai donné un vieux coquillage, que mon père m'avait rapporté d'en bas. Elle le porte à son oreille tous les soirs. Elle dit qu'elle entend la mer. Moi, je l'entends mal. Mais je la crois.", {}),
					L("Hein ? Les Mines de Cristaux ? J'y descendais avec mon père, il y a quatre-vingts ans ! … La ligne a rouvert ? Alors j'y retourne. Avec mon cornet acoustique. Il paraît que le liftier d'en bas est encore plus sourd que moi. On va bien rire.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Toi ! Tu as un moment ? J'ai une histoire.", {"visites_max": 0}, "salut"), L("{surnom} ! Viens, j'en étais à la meilleure partie !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Va, va. Et si quelqu'un te demande qui a fait monter l'île, dis que c'est Séraphin. Et que son petit-fils y était. Presque.", {}, "salut"), L("Hein ? Tu pars ? Ah. Bon vent, alors !", {}, "rire"), L("Bonne nuit. Je vais rentrer avant que Céleste vienne me chercher. Elle a la voix d'un vent du nord.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Hein ? Bien sûr ! Tu es celui qui m'a écouté jusqu'au bout. C'est rare. Je m'en souviens toujours, de ceux-là.", {})],
			}},
		{"id": "gustave_nu", "nom": "Gustave Cumulus", "titre": "patron du Café Cumulus", "maison": "porte_gustave", "village": "nuees",
			"agenda": [[6, 23, "cafe_comptoir"], [23, 6, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "chauve", "barbe": "moustache", "yeux": Y_BRUN, "haut": NEIGE, "tablier": CIEL_PALE, "taille": 1.02, "carrure": 1.4},
			"teinte": PEAU[1],
			"neo": {"tenue": "chef", "c": NEIGE, "c2": CIEL, "chapeau": "cuisinier", "objet": "plateau"},
			"humeur_base": 0.65, "traits": {"bavard": 0.9, "humour": 0.9, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.1},
			"boutique": {"vend": {"lait_nuage": 3, "the_sommets": 3, "jus_soleil": 3, "chocolat_chaud": 4, "chouquettes": 4, "croissant": 3}, "achete": {"fraise_geante": 2, "miel": 4, "baies": 1, "pomme": 1, "cacao": 3, "dattes": 2}},
			"aime": {"cacao": 2.5, "fraise_geante": 2.0, "miel": 2.0, "biscuit_engrenage": 2.0, "chocolat_chaud": 1.5, "gateau_miel": 1.5}, "deteste": {"soda_neon": -1.5, "gelee_slime": -1.5},
			"tics": ["Pschhht !", "Une chouquette ?", "Léger comme un nuage !", "Mon frère, en bas…"],
			"surnoms": [[0, "voyageur"], [25, "habitué"], [50, "pilier de terrasse"], [75, "ma chouquette"], [95, "nuage de mon cœur"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au Café Cumulus ! Gustave Cumulus, patron, serveur et souffleur de mousse ! Un lait de nuage ? Un thé des sommets ? Un jus de soleil ? Et des chouquettes, bien sûr, toutes chaudes. Ici, rien n'est lourd, sauf moi. Assieds-toi en terrasse, la vue est offerte.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Ta mousse t'attend ! Elle n'a pas eu le temps de s'envoler, je l'ai surveillée.", {"visites_min": 2}, "rire"),
					L("Tiens, tu as la moustache de chocolat de mon frère Firmin ! Tu es passé au Piston Joyeux, avoue. Il siffle toujours, sa machine ? Ha ! Ici, on mousse. C'est plus distingué.", {"a_rencontre": "firmin"}, "rire"),
				],
				"humeur": [
					L("Contrarié. Le four solaire a trop chauffé : mes chouquettes ont doublé de volume. Elles flottent un peu. J'ai dû les attacher avec de la ficelle.", {"humeur_max": -0.2}, "rire"),
					L("Formidable ! La Ligne a rouvert, et la terrasse est pleine de gens du Plancher qui goûtent leur premier lait de nuage. Ils font tous la même tête : les yeux ronds, et une moustache blanche. J'adore cette tête.", {}, "rire"),
					L("Un peu essoufflé. Ici, l'eau bout plus vite, à cause de l'altitude. Mon thé est prêt avant que j'aie pris la tasse. Je cours après mon thé toute la journée. C'est très bon pour la ligne. Enfin, en théorie.", {}),
					L("Le matin, les premières chouquettes sortent du four solaire à six heures pile. L'odeur fait le tour de l'Esplanade, et toute la ville se réveille en reniflant. Même Monsieur Pascal. Surtout Monsieur Pascal.", {"matin": true}, "rire"),
					L("Le soir, la terrasse est pleine : Nova et ses calculs, la Capitaine Zéphyrine et ses victoires, Ombeline et ses couchers de soleil. Et moi, au milieu, avec mon plateau. Le plus heureux des nuages.", {"soir": true}),
				],
				"lui": [
					L("Je suis né en bas, à Hautefond. Je m'appelais Gustave Bouilloire, comme mon frère Firmin, du Piston Joyeux. Quand je suis monté ici, j'ai pris le nom de mon café. Cumulus, ça flotte mieux que Bouilloire.", {}, "rire"),
					L("Mon frère Firmin et moi, on se dispute depuis quarante ans : qui fait le meilleur chocolat ? Lui, avec sa machine qui siffle comme une locomotive. Moi, avec ma mousse de nuage, légère comme un soupir. Depuis que la Ligne a rouvert, on se dispute en vrai. C'est beaucoup mieux que par lettre.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux savoir le secret du lait de nuage ? Du lait, de la vanille, une pointe de miel… et on le bat au fouet pendant que le vent souffle sur la terrasse. Le vent des Nuées, rien d'autre. Ça ne marche pas en bas. Firmin a essayé. Il a eu une omelette.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Café Cumulus est au sud de l'Esplanade, juste devant la Plume de Séraphin. Si tu te perds, suis l'odeur des chouquettes. Si tu te perds encore, suis les moineaux. Ils savent toujours où je suis.", {}, "rire"),
					L("Mes fraises viennent des Serres d'Altitude, chez Flora. Des fraises grosses comme le poing, mûries au soleil éternel ! Je les mets dans le jus de soleil. Les gens du Plancher croient que c'est une pomme rouge. Puis ils goûtent. Puis ils reviennent.", {"sujet_min": ["ile", 1]}),
					L("Les soirs de concert, on entend la musique de la Fronde monter par le conduit de la Colonne, depuis les Strates, tout en bas. Boum, boum, tchak. Les tasses dansent sur les soucoupes. Monsieur Pascal râle. Moi, je bats la mousse en rythme. Elle est meilleure, ces soirs-là.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("La Capitaine Héloïse est montée pour la réouverture. Elle a commandé un soda au gingembre. Je n'en ai pas. Elle a pris un lait de nuage. Puis un deuxième. Elle a dit : « Ne le dites pas à Zéphyrine. » Zéphyrine était à la table d'à côté.", {"a_rencontre": "heloise_hf"}, "rire"),
					L("La Capitaine Zéphyrine boit un thé des sommets avant chaque course contre la Capitaine Héloïse. Héloïse boit un soda au gingembre chez mon frère. Elles disent toutes les deux que leur boisson les fait gagner. Elles gagnent toutes les deux, d'ailleurs. Chacune à sa façon.", {}, "rire"),
					L("Le Docteur Aurèle m'a annoncé une averse pour quinze heures douze. J'ai rentré la terrasse. Il a fait grand soleil jusqu'au soir. À quinze heures douze, il a éternué. Il dit que c'était ça, l'averse.", {}, "rire"),
					L("Monsieur Pascal commande une chouquette, une seule, tous les matins. Il en mange la moitié. L'autre moitié part dans sa poche. Je sais où elle va : aux moineaux des Résidences. Il ne sait pas que je sais. Je lui en mets une de plus, en douce.", {}),
					L("Mon frère Firmin est descendu aux Strates. Une cantinière lui a servi un chocolat « du mineur », si épais que la cuillère tient debout. Il dit que c'est une soupe. Moi, je dis qu'il est jaloux. Mon lait de nuage, lui, ne tient rien debout. C'est sa grande qualité.", {"a_rencontre": "honorine_st"}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Un lait de nuage ? La mousse est fraîche !", {"visites_max": 0}, "salut"), L("{surnom} ! Les chouquettes sortent du four !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bon vent, {surnom} ! Et essuie-toi la lèvre : tu as une moustache de nuage. Bienvenue au club !", {}, "rire"), L("Reviens vite ! Et si tu vois mon frère Firmin, dis-lui que ma mousse est plus haute que sa vapeur.", {}, "salut"), L("Bonne nuit ! Je ferme à vingt-trois heures. La dernière chouquette est pour moi. C'est le règlement. Mon règlement.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr ! Tu as soufflé sur ta mousse la première fois, et elle s'est envolée sur la table d'à côté. La Capitaine Zéphyrine l'a mangée. Elle a dit que c'était une victoire.", {}, "rire")],
				"boutique": [L("Lait de nuage, thé des sommets, jus de soleil, chocolat bien chaud, et chouquettes tout juste sorties du four solaire ! Sans une goutte de boisson forte : ici, on a déjà la tête dans les nuages. Tu as {pieces} pièces.", {}, "rire")],
			}},
		{"id": "mireille", "nom": "Mireille Volta", "titre": "inventrice de l'Atelier des Inventeurs", "maison": "porte_mireille", "village": "nuees",
			"agenda": [[8, 12, "atelier_comptoir"], [12, 14, "atelier_etabli"], [14, 19, "atelier_comptoir"], [19, 23, "atelier_etabli"], [23, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "boucles", "yeux": Y_VERT, "haut": SABLE, "tablier": CIEL_PALE, "lunettes": true, "taille": 0.96},
			"teinte": PEAU[0],
			"neo": {"tenue": "mecano", "c": SABLE, "c2": CIEL, "objet": "livre"},
			"femme": true,
			"boutique": {"vend": {"parapluie_ascenseur": 24, "grille_pain_solaire": 20, "boussole_nuages": 16, "bocal_nuage": 12, "tasse_tourneuse": 14, "corde_chanvre": 4, "ressort": 2, "engrenage": 3}, "achete": {"engrenage": 2, "ressort": 1, "boulon": 1, "cristal_astral": 9, "fragment_meteorite": 6, "eclat_cristal": 7, "montre_envers": 8, "toile_voile": 3}},
			"humeur_base": 0.6, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"engrenage": 2.0, "ressort": 2.0, "cristal_astral": 2.5, "fragment_meteorite": 2.0, "chapeau_ventilateur": 1.5, "chouquettes": 1.5}, "deteste": {"boite_a_rien": -1.5, "gelee_slime": -1.5},
			"tics": ["Ça marche ! … Presque.", "Recule un peu.", "C'est une version d'essai.", "Oups."],
			"surnoms": [[0, "client"], [25, "testeur"], [50, "mon testeur préféré"], [75, "mon assistant en chef"], [95, "mon invention la plus réussie"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Recule un peu. Encore un peu. Voilà. Mireille Volta, inventrice ! Bienvenue à l'Atelier des Inventeurs. Ici, tout marche. Presque. Le « presque » est offert avec chaque objet, sans supplément.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes à pic ! J'ai besoin de quelqu'un pour tenir ce fil pendant que j'appuie sur le bouton. Non, non, ça ne fait pas mal. Ça chatouille. Ça chatouillait, en tout cas, la dernière fois.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Ce matin, première tartine du grille-pain solaire. Parfaite. Et la table n'a presque pas grillé. Juste un petit rond. Je considère que c'est la version définitive.", {"matin": true}, "rire"),
					L("Excellente ! Mon grille-pain solaire a grillé une tartine parfaite. Il a aussi grillé la table, l'établi et un coin de mon tablier. Mais la tartine était parfaite.", {}, "rire"),
					L("Un peu frustrée. Le parapluie qui monte monte très bien. C'est la descente que je n'ai pas encore résolue. Le dernier testeur est resté accroché au mât de l'Institut pendant une heure. Il a dit que la vue était superbe.", {}),
					L("Le soir, à l'établi, quand l'atelier est calme, j'ai mes meilleures idées. Et mes pires. Je les reconnais le lendemain matin : les pires sont celles qui fument.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai démonté mon premier réveil à cinq ans. Je l'ai remonté à cinq ans et demi. Il sonnait à l'envers : il faisait dormir. Ma mère l'a gardé. Elle s'en sert encore pour les siestes.", {}, "rire"),
					L("L'horloger de Hautefond, Gaspard Ressort, est monté pour la réouverture. Il a regardé mes inventions pendant une heure sans rien dire. Puis il a dit : « C'est… original. » Je crois que c'est un compliment. Chez lui, c'est le plus haut.", {"sujet_min": ["lui", 1]}),
					L("Tu sais pourquoi mes inventions marchent presque ? Parce que si elles marchaient complètement, je n'aurais plus rien à inventer. Le « presque », c'est ma réserve d'idées pour demain. Bon. C'est aussi que je suis un peu pressée.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("L'Atelier des Inventeurs est à l'est de l'Esplanade. Séraphin Altaïr y a dessiné ses Sustentateurs, il y a cent vingt ans. Ses plans sont encore au mur. Il y a une tache de thé dessus. Je ne l'efface pas. Elle fait partie de l'invention.", {}),
					L("L'Ingénieure Nova vient emprunter des outils à l'établi le soir. Elle me rend toujours tout, bien rangé, avec une petite note : « Ceci n'est pas un jouet. » Elle a raison. Mais c'est quand même un peu un jouet.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Il paraît que dans les Strates, sous Hautefond, il y a des ateliers immenses, des forges et des rails partout. La ligne vient de rouvrir. Je descends dimanche avec mon carnet. J'ai entendu dire qu'ils réparent tout avec trois boulons et une chanson.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Gaspard, l'horloger d'en bas, m'a écrit pour savoir si nos horloges de verre étaient bien réglées. Nous n'avons pas d'horloges de verre. J'en ai fabriqué une, en vitesse, pour quand il remontera. Elle avance de six minutes. Il va adorer la régler.", {"a_rencontre": "gaspard_hf"}, "rire"),
					L("Le Docteur Aurèle m'a commandé une machine à prévoir le temps. Je l'ai faite. Elle prévoit parfaitement le temps qu'il faisait hier. Il la trouve très utile. Il dit que c'est la seule à ne jamais se tromper.", {}, "rire"),
					L("Plumeau, le robot jardinier, vient se faire huiler les genoux chaque semaine. Il me raconte les blagues du Docteur Aurèle, sans les comprendre. Il les raconte mieux que lui, d'ailleurs. Il ne rit pas avant la fin.", {}, "rire"),
					L("La petite Pimprenelle de Hautefond est montée avec un sac plein de boulons, « pour échanger ». Elle m'a pris trois ressorts et un engrenage pour un boulon. Un seul. Elle a neuf ans. Je l'embauche dès qu'elle en a dix.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Toi ! Tu veux tester quelque chose ? C'est presque sans danger !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une nouvelle version !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bon vent, {surnom} ! Et si quelque chose fume dans ton sac, ce n'est pas grave. Enfin, reviens me voir quand même.", {}, "rire"), L("À bientôt ! J'aurai inventé quelque chose de nouveau. Ou réparé l'ancien. Ou les deux.", {}, "salut"), L("Bonne nuit ! Moi, je reste à l'établi. J'ai une idée. Elle ne fume pas encore.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr ! Tu es la première personne qui a ouvert mon parapluie sans s'envoler. J'ai noté ton nom dans mon carnet, rubrique « miracles ».", {})],
				"boutique": [L("Parapluies qui montent, grille-pains solaires, boussoles à nuages, petits nuages en bocal ! Tout marche. Presque. Et le mode d'emploi est en cours d'invention. Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ l'Institut des Vents
		{"id": "aurele", "nom": "le Docteur Aurèle Brise", "titre": "météorologue de l'Institut des Vents", "maison": "porte_aurele", "village": "nuees", "vouvoie": true,
			"agenda": [[6, 9, "institut_mat"], [9, 13, "institut_bureau"], [13, 14, "institut_eoliennes"], [14, 18, "institut_bureau"], [18, 20, "parc_banc"], [20, 22, "institut_mat"], [22, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "boucles", "barbe": "courte", "yeux": Y_BLEU, "haut": NEIGE, "lunettes": true, "taille": 1.06, "carrure": 0.9},
			"teinte": PEAU[2],
			"neo": {"tenue": "techwear", "c": NEIGE, "c2": CIEL, "objet": "tablette_holo"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"plume_vent": 2.5, "fragment_meteorite": 2.0, "boussole_nuages": 2.5, "bocal_nuage": 2.0, "the_sommets": 1.5, "tisane_brume": 1.5}, "deteste": {"parapluie_helice": -1.0, "chapeau_ventilateur": -0.5},
			"tics": ["Selon mes calculs…", "À la minute près.", "Voici Gontran. C'est un cumulus.", "Légère erreur de précision."],
			"surnoms": [[0, "cher visiteur"], [25, "cher observateur"], [50, "cher confrère"], [75, "mon anticyclone"], [95, "plus beau temps de ma vie"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Docteur Aurèle Brise, météorologue de l'Institut des Vents. Vous arrivez à dix heures quatorze, par un vent de nord-ouest de douze kilomètres-heure. Je vous attendais à dix heures douze. Légère erreur de précision. Ce n'est rien : c'est vous qui étiez en avance sur mes calculs.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Regardez, là, juste au-dessus de la Tour : c'est Gontran. Un cumulus. Il est passé hier aussi. Je crois qu'il vous aime bien.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Couvert. Mes prévisions de la semaine étaient toutes justes. Toutes ! Je ne comprends pas. Je me sens inutile. D'habitude, j'ai au moins une belle erreur à étudier.", {"humeur_max": -0.2}),
					L("Excellente ! J'avais annoncé du soleil à quatorze heures six. Il a fait soleil à quatorze heures six. Bon, il fait soleil toute la journée, ici. Mais j'avais la bonne minute.", {}, "rire"),
					L("Un peu contrarié. J'ai prévu une averse pour onze heures dix-sept. Elle est tombée. Sur Hautefond. Deux cents mètres trop bas. Je me suis trompé avec beaucoup de précision. C'est une forme de réussite.", {}),
					L("Le matin, je monte au grand mât et je dis bonjour à chaque nuage. Il y en a toujours un nouveau. Je lui donne un prénom. Ce matin : Philibert. Un petit stratus timide. Il s'est dissipé quand je l'ai appelé.", {"matin": true}, "rire"),
					L("Le soir, je m'assois au Parc des Brumes et j'écoute la Cascade se transformer en brume. Personne ne sait exactement à quel mètre l'eau devient nuage. Moi non plus. Mais j'ai un chiffre. Il est faux. Il est très beau.", {"soir": true}),
				],
				"lui": [
					L("J'ai baptisé mon premier nuage à quatre ans. Il s'appelait Bernard. Il a duré six minutes. J'ai pleuré. Ma mère m'a dit : « Il y en aura d'autres. » Elle avait raison. J'en ai baptisé quarante-deux mille. Je les ai tous notés. Bernard est en première page.", {}),
					L("Je prévois le temps à la minute près. Et je me trompe à la minute près aussi. Mes collègues disent que je suis le météorologue le plus précis du monde. Ils ne précisent pas dans quel sens.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Vous savez ce que j'aime, dans les nuages, {surnom} ? Ils ne restent jamais. Ils passent, ils changent de forme, ils s'en vont. Et pourtant, le ciel n'est jamais vide. Il y a toujours quelqu'un de nouveau. C'est une idée très rassurante, quand on y pense.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Institut des Vents est au nord de la ville. Le grand mât de mesure, les éoliennes du bord, les ballons-sondes… et la Salle des Sustentateurs, où l'Ingénieure Nova veille sur les moteurs. Elle dit que l'île flotte grâce aux calculs. Je dis qu'elle flotte grâce au beau temps. Nous avons tous les deux un peu raison.", {}),
					L("Au-dessus de nous, presque toujours du soleil. En dessous, presque toujours des nuages. Les gens du Plancher croient que nous vivons dans les nuages. Pas du tout. Nous vivons sur les nuages. C'est une nuance très importante. Pour moi, en tout cas.", {"sujet_min": ["ile", 1]}, "rire"),
					L("J'ai un confrère à Hautefond, le Professeur Lunette. Il regarde les étoiles, je regarde les nuages, et nous nous disputons pour savoir qui cache qui. Il est monté avec sa grande lunette pour la réouverture. Il a dit que mes nuages gâchaient la vue. Je lui ai répondu que ses étoiles ne servaient à rien le jour.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Vous connaissez le Professeur Lunette, à l'Observatoire de Hautefond ? Il dit que mon nuage Gontran lui cache son étoile Clémentine. Nous avons signé un accord : Gontran passe le jour, Clémentine brille la nuit. Tout le monde est content.", {"a_rencontre": "octave_hf"}, "rire"),
					L("Plumeau, le robot jardinier, apprend mes blagues par cœur. Il ne les comprend pas, mais il les répète avec une précision parfaite. Il est le seul à rire au bon moment. C'est-à-dire jamais, mais exactement à la bonne seconde.", {}, "rire"),
					L("La Capitaine Zéphyrine me demande la météo avant chaque course. Je lui donne mes prévisions. Elle fait le contraire. Elle gagne. Je ne sais pas si je dois être vexé ou fier.", {}, "rire"),
					L("Le Grand-Père Séverin raconte la montée de l'île à tout le monde. J'ai vérifié dans les archives : ce jour-là, il faisait gris. Il a raison sur ce point. Pour le reste, il a beaucoup d'imagination. Et une très belle barbe.", {}),
					L("Vous avez rencontré le Professeur Benthos, au Dôme d'Azur ? Mon plus vieux correspondant ! Lui étudie le bas, moi le haut. Il baptise ses méduses, je baptise mes nuages. Nous sommes d'accord sur un point : une méduse, c'est un nuage qui a choisi la mer. La ligne a rouvert : je descends lui serrer la main jeudi, à quinze heures douze. À une minute près.", {"a_rencontre": "hippolyte"}, "rire"),
				],
				"interpelle": [L("Pardon ! Vous ! Avez-vous vu passer un petit cirrus ? Il s'appelle Octave.", {"visites_max": 0}), L("{surnom} ! Gontran est revenu !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Je prévois que nous nous reverrons demain à seize heures huit. Ou un autre jour. À une minute près.", {}, "salut"), L("Bon vent ! Et si vous voyez un nuage qui n'a pas de nom, revenez me le décrire.", {}), L("Bonne nuit, {surnom}. Ciel dégagé, étoiles nombreuses, nuages endormis. Même Gontran.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Bien sûr. Vous êtes arrivé le jour où j'ai baptisé Mélusine, un bel altocumulus. Je vous associe toujours à elle. C'est un grand honneur.", {})],
			}},
		{"id": "nova_nu", "nom": "l'Ingénieure Nova Volant", "titre": "cheffe des Sustentateurs", "maison": "porte_nova", "village": "nuees",
			"agenda": [[6, 12, "moteurs_pupitre"], [12, 13, "cafe_table_1"], [13, 17, "moteurs_pupitre"], [17, 19, "atelier_etabli"], [19, 22, "cafe_table_1"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "queue", "yeux": Y_BRUN, "haut": GRIS_DOUX, "taille": 1.0, "carrure": 1.05},
			"teinte": PEAU[4],
			"neo": {"tenue": "combinaison", "c": GRIS_DOUX, "c2": CIEL, "objet": "cle_molette"},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"the_sommets": 3.0, "the_menthe": 2.0, "engrenage": 1.5, "ressort": 1.5, "biscuit_engrenage": 2.0, "chouquettes": 1.5}, "deteste": {"gelee_slime": -1.5, "bombe_peinture": -1.0},
			"tics": ["Pas de panique.", "Calcul et thé.", "Elle boude.", "Tout est nominal."],
			"surnoms": [[0, "visiteur"], [25, "passager de l'île"], [50, "mon collègue"], [75, "mon contrepoids"], [95, "ma constante préférée"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Ingénieure Nova Volant, cheffe des Sustentateurs. Ne touchez à rien, ne marchez pas sur le hublot en sautant, et ne paniquez pas. L'île flotte grâce aux calculs et au thé. J'ai les deux.", {"visites_max": 1}, "salut"),
					L("{surnom}. Tout est nominal. Les quatre moteurs tournent, la portance est bonne, et mon thé est encore chaud. C'est une excellente journée.", {"visites_min": 2}),
				],
				"humeur": [
					L("Ce matin, les quatre voyants sont passés au bleu en même temps, à six heures pile. Ça n'arrive presque jamais. J'ai bu mon thé debout, pour leur faire honneur.", {"matin": true}),
					L("Calme. Toujours calme. Le Sustentateur nord-est a toussé ce matin. Je lui ai parlé doucement, j'ai resserré un boulon, et il s'est remis à ronronner. On ne panique pas devant un moteur. Il le sentirait.", {}),
					L("Un peu fatiguée. Depuis la réouverture, il y a deux mille personnes de plus sur l'île chaque jour. Ça fait du poids. J'ai recalculé la portance trois fois. Elle tient. Mais j'ai demandé à Gustave de faire des chouquettes plus légères.", {}, "rire"),
					L("Le soir, je prends un thé au Café Cumulus, à ma table. Je regarde les gens rire sur une île qui flotte, et je me dis : c'est grâce à quatre moteurs, mille calculs, et une tasse de thé. Ça me rend très fière. En silence.", {"soir": true}),
				],
				"lui": [
					L("Les moteurs ont un caractère, vous savez. Brindille, au nord, est nerveuse. Grondin, à l'est, ronchonne mais ne lâche jamais. Mélodie, au sud, chante quand le vent tourne. Et le Vieux, à l'ouest, c'est le premier de Séraphin. Il ne dit rien. Il tient.", {}),
					L("Je ne panique jamais. Une fois, Brindille s'est arrêtée trois secondes. L'île a penché d'un demi-degré. Toute la ville a crié. Moi, j'ai posé ma tasse, j'ai tapoté le pupitre, et j'ai dit : « Allez, ma belle. » Elle est repartie. Ma tasse n'a pas débordé.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous dire un secret, {surnom}. Je ne crois pas que l'île flotte seulement grâce aux calculs. Je crois qu'elle flotte aussi parce que tout le monde, ici, a envie qu'elle reste en l'air. Ne le répétez pas. Une ingénieure ne dit pas ce genre de chose.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Salle des Sustentateurs est dans l'Institut des Vents. Il y a le pupitre, quatre voyants bleus, un pour chaque moteur, et un hublot dans le sol. Regardez par le hublot : vous voyez Brindille, son anneau bleu, et le vide. Beaucoup de vide. Ne sautez pas dessus.", {}),
					L("Les Sustentateurs ne poussent pas l'île, ils la portent. Comme une main ouverte sous une plume. Séraphin les a dessinés il y a cent vingt ans, à l'Atelier. Je les entretiens avec ses plans, une clé à molette et beaucoup de respect.", {"sujet_min": ["ile", 1]}),
					L("La Grande Colonne de Hautefond et la Ligne des Nuées, c'est le même conduit, en fait. Les soirs de concert, la musique de la Fronde monte des Strates jusqu'ici. Les moteurs vibrent un peu. Mélodie chante avec. Je ne le note pas dans le rapport. Il y a des choses qu'on garde pour soi.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Maîtresse Capucine, la Grande Liftière d'en bas, est venue voir mes moteurs. Elle a posé la main sur le pupitre et elle a dit : « Ils sont bien élevés. » Grondin a ronronné. Il ne ronronne jamais pour personne. Elle a quelque chose, cette femme.", {"a_rencontre": "capucine_hf"}),
					L("Mireille, à l'Atelier, me prête son établi le soir. Je lui rends tout bien rangé, avec une note : « Ceci n'est pas un jouet. » Elle me répond toujours par une autre note : « Si. Un peu. » Nous correspondons beaucoup, pour deux voisines.", {}, "rire"),
					L("Théo, le liftier, saute dans la capsule à chaque départ. Je lui ai expliqué que ça la déséquilibrait d'un millimètre. Il a dit : « Un millimètre de bonheur. » Je n'ai pas trouvé de contre-argument dans mes calculs.", {}, "rire"),
					L("Monsieur Pascal vient se plaindre chaque semaine que l'île « penche vers le Plancher ». Je mesure. Elle ne penche pas. Il dit : « Alors c'est moi qui penche. » Je lui sers un thé. Il penche moins.", {}, "rire"),
				],
				"interpelle": [L("Vous. Ne marchez pas sur le hublot.", {"visites_max": 0}), L("{surnom}. Tout est nominal. Venez voir.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom}. Et pas de panique. Jamais.", {}, "salut"), L("À bientôt. Si vous sentez l'île pencher, ce n'est pas l'île. C'est l'émotion.", {}, "rire"), L("Bonne nuit. Les moteurs veillent. Moi aussi, un peu, avec mon thé.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Oui. Vous pesiez soixante kilos de plus sur l'île le jour de votre arrivée. J'ai recalculé la portance. Pour vous. C'est ma façon de me souvenir des gens.", {}, "rire")],
			}},
		# ================================================================ les Serres d'Altitude
		{"id": "flora", "nom": "Flora Verdine", "titre": "jardinière des Serres d'Altitude", "maison": "porte_flora", "village": "nuees",
			"agenda": [[6, 10, "serres_allee"], [10, 12, "serres_bassin"], [12, 13, "serres_banc"], [13, 18, "serres_allee"], [18, 20, "serres_bassin"], [20, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "tresse", "yeux": Y_VERT, "chapeau": "paille", "haut": SAUGE, "tablier": CREME, "taille": 0.96},
			"teinte": PEAU[2],
			"neo": {"tenue": "jardinier", "c": SAUGE, "c2": CREME, "chapeau": "paille"},
			"femme": true,
			"boutique": {"vend": {"fraise_geante": 2, "pomme": 1, "baies": 1, "miel": 4, "graines": 2, "jus_soleil": 3}, "achete": {"graines": 1, "pomme": 1, "baies": 1, "miel": 3, "dattes": 2, "noix_coco": 2, "champignon": 2}},
			"humeur_base": 0.7, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"graines": 3.0, "miel": 2.0, "fleur_nebuleuse": 2.5, "goutte_rosee": 2.0, "eau_source": 2.0, "pomme": 1.5}, "deteste": {"hache": -2.0, "piment_infernal": -0.5},
			"tics": ["Doucement, tu vas réveiller Adèle.", "Ma collègue que voilà.", "Ça pousse !", "Au soleil éternel !"],
			"surnoms": [[0, "petite graine"], [25, "jeune pousse"], [50, "mon bouton de fleur"], [75, "ma belle fraise"], [95, "mon plus beau papillon"]],
			"repliques": {
				"accueil": [
					L("Bienvenue aux Serres d'Altitude ! Flora Verdine, jardinière. Doucement, ne bouge pas : il y a un papillon sur ton épaule. C'est Adèle, ma collègue. Elle s'occupe des fleurs du deuxième dôme. Elle t'a choisi. C'est bon signe.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens voir, viens voir ! Une fraise de la taille d'un melon ! Enfin, d'un petit melon. D'un gros abricot. Bref : énorme.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Un peu fanée, aujourd'hui. Une chenille a mangé la moitié de mes laitues. Je ne peux pas lui en vouloir : dans trois semaines, ce sera un papillon. Une future collègue. Il faut bien qu'elle grandisse.", {"humeur_max": -0.2}),
					L("Radieuse ! Le soleil ne se couche presque jamais au-dessus des nuages, alors mes fraises mûrissent jour et nuit. J'en ai cueilli trois cents ce matin. Elles en voulaient encore.", {}, "rire"),
					L("Un peu inquiète. Les papillons du troisième dôme font grève. Ils trouvent que les fleurs de pommier sont trop serrées. Je vais négocier. Avec du nectar. Ça marche toujours.", {}),
					L("Le soir, au bassin, l'eau des nuages coule dans les rigoles, et les papillons viennent boire. Je m'assois avec eux. On ne se dit rien. On fait le bilan de la journée.", {"soir": true}),
				],
				"lui": [
					L("J'ai planté ma première fraise sur le rebord de ma fenêtre, à six ans. Elle a donné une seule fraise, toute petite. Je l'ai coupée en quatre pour ma famille. Aujourd'hui, une seule de mes fraises nourrit quatre familles. Les choses ont pris de l'ampleur.", {}, "rire"),
					L("Les papillons sont mes collègues. Adèle, Basile, Pétronille, et trois cents autres. Ils pollinisent, je taille, ils se reposent, j'arrose. Ils ne sont jamais en retard et ils ne se plaignent jamais. Enfin, sauf ceux du troisième dôme.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le Père Bastien, le jardinier des Vergers de Hautefond, est monté pour la réouverture. Il pensait que nos arbres poussaient « dans le vide ». Il leur a parlé une heure. Depuis, mes pommiers donnent deux fois plus. Je crois qu'ils avaient besoin d'un peu de conversation.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Serres d'Altitude, ce sont trois grands dômes de verre, à l'est de la ville. Le premier pour les fruits, le deuxième pour les fleurs, le troisième pour les papillons. Et un bassin au milieu, rempli de l'eau des nuages. Tout pousse ici. Même les mauvaises herbes. Elles sont très fières.", {}),
					L("Ici, on ne gaspille pas une goutte. L'eau de pluie coule du toit des dômes, on la garde dans le bassin, on arrose, et ce qui reste repart vers la Source du Parc. Le Docteur Aurèle dit que certaines gouttes ont fait le tour de l'île cent fois. Elles connaissent le chemin.", {"sujet_min": ["ile", 1]}),
					L("Mes fraises descendent maintenant à Hautefond, par la Ligne. Rosalie Cannelle, au Grand Marché, les vend toutes en une matinée. Elle m'a écrit qu'elle voulait aussi les vendre aux Strates et au Dôme d'Azur, maintenant que leurs lignes ont rouvert. Elle a déjà réservé les deux étals.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Tu connais Rosalie Cannelle, au Grand Marché d'en bas ? Elle m'écrit trois lettres par semaine, pleines de potins. En échange, je lui envoie mes fraises. Ses lettres sentent la cannelle, mes fraises sentent le soleil. C'est un bon commerce.", {"a_rencontre": "rosalie_hf"}, "rire"),
					L("Plumeau, le robot jardinier, vient m'aider le matin. Il arrose très bien. Mais il dit bonjour à chaque plante, une par une. J'ai quatre mille plantes. Il finit l'arrosage vers midi. Les plantes ont l'air très contentes.", {}, "rire"),
					L("Gustave, au Café, prend mes fraises pour son jus de soleil. Il dit que c'est « sa recette secrète ». Le secret, c'est mes fraises. Je ne lui dis rien. Il est si content.", {}, "rire"),
					L("La petite Lili vient s'asseoir sur le banc des Serres et me demande si j'ai des graines de coquillage. Je lui ai expliqué que les coquillages ne poussaient pas. Elle a planté un caillou à la place. Je l'arrose. On ne sait jamais.", {}),
					L("Tu as vu Mélisande, au Dôme des Serres ? Nous sommes « les trois jardinières » : moi, qui ai trop de soleil ; Bertille, aux Strates, qui n'en a pas du tout ; et Mélisande, qui allume le sien avec un bouton. Je lui ai envoyé une fraise géante : trois jours pour descendre ! Maintenant que la ligne a rouvert, je l'invite ici. Elle a peur que mon soleil soit trop fort. Je lui garde un chapeau de paille.", {"a_rencontre": "melisande"}, "rire"),
				],
				"interpelle": [L("Doucement ! Tu vas réveiller Adèle !", {"visites_max": 0}), L("{surnom} ! Les fraises sont mûres !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom} ! Et si tu croises un papillon, dis-lui bonjour de ma part. Il saura.", {}, "salut"), L("Va, petite graine. Et reviens avec un panier vide : je le remplirai.", {}), L("Bonne nuit ! Les papillons dorment. Les fraises, elles, continuent de pousser. Elles ne savent pas s'arrêter.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr. Adèle s'était posée sur ton épaule. Elle ne fait ça qu'avec les gens gentils. Elle ne se trompe jamais.", {})],
				"boutique": [L("Fraises géantes du soleil éternel, pommes des dômes, baies, miel de mes abeilles, et graines à planter chez toi ! Tout est cueilli du matin. Tu as {pieces} pièces.", {}, "rire")],
			}},
		# ================================================================ le Port des Nuées
		{"id": "zephyrine_nu", "nom": "la Capitaine Zéphyrine Ailée", "titre": "maîtresse du Port des Nuées, capitaine de la Libellule", "maison": "porte_zephyrine", "village": "nuees",
			"agenda": [[6, 9, "port_bureau"], [9, 13, "port_ponton"], [13, 14, "port_bureau"], [14, 18, "port_ponton"], [18, 19, "port_bureau"], [19, 22, "cafe_table_2"], [22, 6, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "carre", "yeux": Y_AMBRE, "haut": NEIGE, "foulard": CIEL, "lunettes": true, "taille": 1.02},
			"teinte": PEAU[5],
			"neo": {"tenue": "techwear", "c": NEIGE, "c2": CIEL},
			"femme": true,
			"humeur_base": 0.6, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.6, "susceptible": 0.7, "rancunier": 0.2},
			"aime": {"coupe_course": 3.0, "the_sommets": 2.0, "toile_voile": 2.0, "plume_vent": 2.0, "boussole_nuages": 1.5, "jus_soleil": 1.5}, "deteste": {"limonade_boucan": -0.5, "vieille_botte": -1.0},
			"tics": ["J'ai gagné.", "Héloïse dira le contraire.", "Plein vent !", "Larguez les amarres !"],
			"surnoms": [[0, "passager"], [25, "matelot du ciel"], [50, "mon second"], [75, "mon copilote"], [95, "mon vent arrière"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au Port des Nuées ! Capitaine Zéphyrine Ailée, maîtresse du port et capitaine de la Libellule, le plus beau dirigeable du ciel. Celui qui est amarré là, tout blanc. Le plus rapide, aussi. Ne crois pas ce que dit Héloïse.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien : j'ai encore gagné hier. Contre qui ? Contre Héloïse, voyons. Contre qui d'autre ?", {"visites_min": 2}, "rire"),
					L("Tu as rencontré Héloïse, en bas ? Elle t'a dit qu'elle avait gagné, je parie. Elle dit ça depuis vingt ans. Moi aussi, d'ailleurs. Mais moi, c'est vrai.", {"a_rencontre": "heloise_hf"}, "rire"),
				],
				"humeur": [
					L("Ce matin, le ciel est clair jusqu'à l'horizon. Parfait pour une course. J'ai envoyé un pigeon à Héloïse. Elle a répondu « déjà partie ». Elle triche. J'adore ça.", {"matin": true}, "rire"),
					L("Plein vent ! J'ai fait le tour de la Colonne en sept minutes douze. Héloïse dit sept minutes dix. Elle compte à partir du moment où elle a eu l'idée de partir.", {}, "rire"),
					L("Un peu agacée. Depuis la réouverture, tout le monde prend la capsule. Plus personne ne monte en dirigeable. La capsule, c'est bien, mais c'est un ascenseur. La Libellule, c'est un voyage.", {}),
					L("Le soir, je prends un thé des sommets au Café Cumulus, et je raconte la course du jour à qui veut l'entendre. Gustave m'écoute. Il a entendu la même histoire quatre mille fois. Il rit toujours au bon moment. C'est un vrai ami.", {"soir": true}),
				],
				"lui": [
					L("Une fois, pendant une course, l'Albatros a eu une panne au-dessus de la mer. J'ai fait demi-tour et je l'ai remorqué jusqu'au Mât de Hautefond. Ce jour-là, personne n'a gagné. C'est la plus belle course de notre vie. On n'en parle jamais.", {"sujet_min": ["lui", 3]}),
					L("Héloïse et moi, on a appris à piloter ensemble, à Hautefond, il y a vingt ans. Le premier jour, on a fait la course jusqu'au Mât. On est arrivées ensemble. Depuis, chacune dit qu'elle a gagné. Personne n'a jamais su. C'est le plus beau des mystères.", {}),
					L("La Libellule, je l'ai construite moi-même, avec Mireille, à l'Atelier. Enfin, Mireille a proposé de lui ajouter des ailes battantes. J'ai refusé. Elle les a ajoutées quand même, pendant que je dormais. Elles battent quand je dis « merci ». J'évite de dire merci à bord.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux savoir pourquoi je fais la course avec Héloïse depuis vingt ans ? Ce n'est pas pour gagner. C'est que, quand on fait la course, on vole côte à côte. Et voler côte à côte avec sa meilleure amie, au-dessus de la mer… il n'y a rien de plus beau. Mais j'ai gagné quand même.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Port des Nuées, c'est un grand ponton qui avance dans le ciel, à l'ouest de l'île. On y amarre les dirigeables et les planeurs. Il y a la capitainerie, mon bureau, et un panneau qui dit « Attention au vide ». Personne ne le lit. Tout le monde regarde le vide.", {}),
					L("Avec la Libellule, je fais le tour de l'archipel. J'ai survolé l'Île de Braise, la Pointe du Phare, et même Néopolis, la nuit, avec ses lumières qui clignotent. Je préfère nos nuages. Mais il faut avouer que c'était joli.", {"sujet_min": ["ile", 1]}),
					L("Héloïse rêve de faire le tour du monde par les airs. Moi aussi. Nous avons décidé de le faire ensemble, maintenant que le Dôme a rouvert, lui aussi, dès qu'on aura fait le tour de tout ce qu'il y a en dessous. Ce sera une course, évidemment. J'ai déjà gagné.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Icare, le moniteur de planeur, dit qu'il va plus vite que la Libellule. En descente, peut-être. En descente, même un caillou va plus vite que la Libellule. Ce n'est pas un argument.", {}, "rire"),
					L("Le Docteur Aurèle me donne la météo avant chaque course. Je fais toujours le contraire de ce qu'il dit. Je gagne toujours. Il est vexé. Je lui ai offert un nuage en bocal pour le consoler. Il l'a baptisé.", {}, "rire"),
					L("Le Conseil classe nos réclamations, à Héloïse et moi, dans un dossier « Égalité ». Je proteste. Héloïse proteste aussi. Nous avons envoyé une réclamation commune. La Première Conseillère l'a classée dans le même dossier.", {}, "rire"),
				],
				"interpelle": [L("Hé, toi ! Tu as vu passer un dirigeable rouge ? C'est Héloïse. Elle est en retard.", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai gagné ! Encore !", {"visites_min": 1}, "rire")],
				"au_revoir": [L("Bon vent, {surnom} ! Et si tu vois Héloïse, dis-lui que je l'attends à la Colonne. Elle saura.", {}, "salut"), L("Larguez les amarres ! Enfin, toi, tu marches. Mais l'esprit y est.", {}, "rire"), L("Bonne nuit ! La Libellule dort sur son ponton. Elle rêve de vitesse. Moi aussi.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr ! Tu étais sur le ponton le jour où j'ai gagné par trois longueurs. Ce n'était pas hier, c'était un autre jour. Je gagne souvent.", {}, "rire")],
			}},
		{"id": "icare", "nom": "Icare Plané", "titre": "moniteur de planeur", "maison": "porte_icare", "village": "nuees",
			"agenda": [[7, 10, "cascade_bord"], [10, 12, "ponton_banc"], [12, 13, "promenade_5"], [13, 17, "cascade_bord"], [17, 19, "ponton_banc"], [19, 21, "promenade_5"], [21, 7, "maison"]],
			"azur": {"cheveux": BLOND, "coiffure": "court", "yeux": Y_BLEU, "haut": CIEL, "lunettes": true, "taille": 1.06, "carrure": 1.15},
			"teinte": PEAU[2],
			"neo": {"tenue": "sweat", "c": CIEL, "c2": NEIGE},
			"humeur_base": 0.8, "traits": {"bavard": 0.85, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"plume_vent": 3.0, "jus_soleil": 2.0, "fraise_geante": 1.5, "toile_voile": 2.0, "plume_corbeau": 1.5, "lait_nuage": 1.5}, "deteste": {"vieille_botte": -1.5, "chaussettes_vapeur": -0.5},
			"tics": ["On plane !", "Face au vent, toujours !", "Doucement, les ailes !", "Ouaaaais !"],
			"surnoms": [[0, "élève"], [25, "apprenti planeur"], [50, "mon équipier"], [75, "mon ailier"], [95, "mon oiseau préféré"]],
			"repliques": {
				"accueil": [
					L("Salut ! Icare Plané, moniteur de planeur ! Attends… tu as des ailes ! Ouaaaais ! Un planeur naturel ! Tu sais t'en servir ? Peu importe : je vais t'apprendre à t'en servir prudemment. Règle numéro un : face au vent, toujours. Règle numéro deux : on ne plane jamais le ventre vide.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Mon élève aux ailes ! Tu as plané depuis la dernière fois ? Prudemment ? Face au vent ? Parfait. Ouaaaais !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Pas terrible. Je me suis posé dans l'étang du Parc. Les canards m'ont regardé comme un très gros canard. Je n'ai pas su quoi leur dire.", {"humeur_max": -0.2}, "rire"),
					L("Au top ! J'ai plané du Port jusqu'à la Cascade sans un seul battement. Trois cents mètres de ciel ! Un pigeon m'a suivi pour apprendre. Il était doué.", {}, "rire"),
					L("Un peu frustré. Le vent d'ouest est tombé à midi. Je suis resté sur le ponton à attendre, les bras écartés, comme un épouvantail. La Capitaine Zéphyrine m'a pris en photo.", {}),
					L("Le matin, l'air est frais, le vent monte de la Cascade : c'est le meilleur moment pour planer. On sent l'île respirer sous ses ailes. Je ne marche jamais, le matin. Je plane jusqu'au café.", {"matin": true}),
					L("Le soir, sur la Promenade du Bord, je regarde les oiseaux rentrer. Ils planent tous face au vent. Ils ont tout compris. Moi, je prends des notes.", {"soir": true}),
				],
				"lui": [
					L("Je ne marche jamais quand je peux planer. Pour aller au café, je plane. Pour aller au Port, je plane. Pour aller chez moi, je plane. Pour monter l'escalier, j'ai essayé. Je ne recommande pas.", {}, "rire"),
					L("Mes parents m'ont appelé Icare. Tout le monde me fait la blague : « Attention au soleil, il fait fondre les ailes ! » Mon planeur est en toile solaire. Plus il fait soleil, mieux il marche. Je réponds toujours : « Merci, je fais attention. » Et je souris. Très fort.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire la vraie règle, {surnom}. Pas la règle numéro un, la vraie. On ne plane pas pour aller vite. On plane pour regarder. Les gens qui vont trop vite ne voient rien. Les gens qui planent voient tout. Alors plane doucement. Regarde.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le meilleur endroit pour s'élancer, c'est le bord de la Cascade des Nuées, au nord-ouest. L'eau tombe, la brume monte, et elle t'emporte vers le haut. Mais attention : par vent d'ouest, on ne plane jamais au-dessus de la Cascade. On finit tout mouillé, et on redescend au Plancher sans l'avoir prévu.", {}),
					L("Avec tes ailes, tu peux faire le tour de l'île en suivant la Promenade du Bord. Reste toujours au-dessus de la balustrade, et pose-toi souvent. Si tu as un doute, pose-toi. Si tu n'as pas de doute, pose-toi quand même. C'est comme ça qu'on devient vieux moniteur.", {"sujet_min": ["ile", 1]}),
					L("Un jour, je planerai d'ici jusqu'à Hautefond. Deux cents mètres de descente, en spirale autour de la Colonne. Maîtresse Capucine a dit : « Pas autour de ma Colonne. » Barnabé a dit : « Je regarderai… plus tard. » Je crois qu'ils m'encouragent.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Barnabé, l'apprenti liftier d'en bas, est venu me voir. Il voulait « juste regarder ». Il a regardé un planeur pendant une heure, de très loin. À la fin, il l'a touché. Avec un doigt. J'ai applaudi. C'était un grand moment.", {"a_rencontre": "barnabe_hf"}),
					L("La Capitaine Zéphyrine dit que la Libellule va plus vite que mon planeur. En montée, oui. En montée, même un ballon de baudruche va plus vite que moi. Ce n'est pas la question.", {}, "rire"),
					L("Théo, le liftier, voulait apprendre à planer. Il est très doué. Trop doué : il saute partout. Je lui ai dit de garder ça pour la capsule. Il saute moins haut, maintenant. Un peu.", {}),
					L("Monsieur Pascal se plaint que je passe au-dessus de son balcon. Je ne passe jamais au-dessus de son balcon. Je passe au-dessus de ses moineaux. Il les nourrit, en cachette. Je le vois d'en haut. Il ne le sait pas.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu as des ailes ! Viens voir !", {"visites_max": 0}, "salut"), L("{surnom} ! Bon vent pour planer aujourd'hui !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom} ! Face au vent, toujours ! Et pose-toi souvent !", {}, "salut"), L("Salut ! Moi, je rentre en planant. Évidemment.", {}, "rire"), L("Bonne nuit ! On ne plane pas la nuit. Même les oiseaux dorment. Enfin, sauf les chouettes. Elles trichent.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de toi ? Bien sûr ! Tu es mon seul élève qui avait déjà ses ailes en arrivant. C'est une première dans ma carrière.", {})],
			}},
		# ================================================================ le bord de l'île et les Résidences
		{"id": "ombeline", "nom": "Ombeline", "titre": "peintre des nuages et des couchers de soleil", "maison": "porte_ombeline", "village": "nuees",
			"agenda": [[6, 8, "belvedere_verre_1"], [8, 12, "promenade_3"], [12, 14, "cafe_table_3"], [14, 17, "promenade_3"], [17, 19, "belvedere_verre_1"], [19, 22, "cafe_table_3"], [22, 6, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "long", "yeux": Y_GRIS, "chapeau": "beret", "chapeau_c": CIEL, "haut": LAVANDE, "robe": CREME, "robe_longue": true, "taille": 0.98},
			"teinte": PEAU[3],
			"neo": {"tenue": "artiste", "c": CREME, "c2": LAVANDE, "chapeau": "beret", "chapeau_c": CIEL, "objet": "livre"},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.55, "humour": 0.55, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"pinceau": 3.0, "fleur_nebuleuse": 2.5, "bocal_nuage": 2.0, "the_sommets": 1.5, "plume_corbeau": 1.5, "coquillage": 1.5}, "deteste": {"bombe_peinture": -1.0, "lunettes_kaleido": -0.5},
			"tics": ["Regarde cette couleur…", "Aucun n'est pareil.", "(Elle reprend son pinceau derrière l'oreille.)", "Mille et un."],
			"surnoms": [[0, "promeneur"], [25, "regard curieux"], [50, "mon modèle"], [75, "ma couleur préférée"], [95, "mon plus beau coucher de soleil"]],
			"repliques": {
				"accueil": [
					L("Oh… bonjour. Pardon, je regardais ce nuage. Il a la couleur d'une pêche qui rougit. Ombeline, peintre. Je peins les nuages et les couchers de soleil. J'en ai peint mille. Pas un seul n'était pareil. Celui de ce soir sera le mille et unième.", {"visites_max": 1}, "salut"),
					L("{surnom}… Tu tombes bien. Il y a une lumière, en ce moment, sur l'Esplanade… Non, attends, elle est partie. Tant pis. Elle reviendra différente.", {"visites_min": 2}),
				],
				"humeur": [
					L("Grise. Le ciel est tout blanc aujourd'hui, sans une ombre. Un ciel sans nuance, c'est une toile vide. Je l'ai peint quand même. Gustave dit qu'il adore. Il l'a accroché à l'envers.", {"humeur_max": -0.2}, "rire"),
					L("Rêveuse. Comme toujours. Ce matin, j'ai vu un nuage qui avait exactement la forme d'un nuage. C'était très reposant.", {}, "rire"),
					L("Un peu mélancolique. Le coucher de soleil d'hier était le plus beau de ma vie. Je n'ai pas eu le temps de le peindre : j'avais oublié mon pinceau derrière mon oreille. Je l'ai cherché partout.", {}, "rire"),
					L("Au lever du jour, au Belvédère, les nuages sous l'île deviennent roses, puis dorés, puis blancs. Trois tableaux en dix minutes. Je n'ai que deux mains. Je choisis le rose.", {"matin": true}),
					L("Le soir, je m'assois au Café Cumulus avec ma toile du jour. Gustave la regarde et dit toujours : « Elle est encore plus belle que celle d'hier. » Il ne se souvient pas de celle d'hier. C'est pour ça qu'il est si gentil.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai toujours un pinceau derrière l'oreille. Au cas où. Un jour, le ciel a fait une couleur que personne n'avait jamais vue, pendant trois secondes. J'avais mon pinceau. Je l'ai peinte. Elle est au Conseil. La Première Conseillère dit qu'elle s'appelle « Ombeline ».", {}),
					L("Mille couchers de soleil, et pas un pareil. Les gens ne me croient pas. Alors je leur montre les mille toiles. Ils disent : « C'est vrai. » Puis ils disent : « Mais lequel est le plus beau ? » Je réponds toujours : « Le prochain. »", {"sujet_min": ["lui", 1]}),
					L("Tu veux savoir pourquoi je peins le soleil qui se couche, {surnom}, et jamais celui de midi ? Parce que celui de midi ne part pas. Il ne dit pas au revoir. Moi, j'aime les choses qui disent au revoir avec de belles couleurs. Ça donne envie de les revoir.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ici, le soleil se couche en dessous de nous. Il passe sous l'île, il traverse les nuages, et il les allume par en dessous. Tu le verras ce soir, au Belvédère de verre. Tu marcheras sur le coucher de soleil. C'est le seul endroit du monde où l'on peut.", {}),
					L("Les gens de Hautefond nous appellent « les Perchés ». Je trouve ça joli. Nous les appelons « le Plancher ». Je trouve ça moins joli. Je leur peins des cartes postales de leur ville vue d'en haut. Ils les achètent pour les envoyer à leurs cousins d'en haut. Ça fait un drôle de voyage.", {"sujet_min": ["ile", 1]}, "rire"),
					L("On m'avait dit qu'au Dôme d'Azur, au fond de la mer, la lumière est bleue toute la journée. C'est vrai. La ligne a rouvert, et je suis descendue avec du bleu. Quarante tubes. Je suis remontée en réclamant du violet : là-bas, le soir, leur soleil est une perle qui devient violette.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Ysaé, la jeune femme aux cheveux bleus du marché d'en bas, m'a décrit les couleurs de la Fronde : des bannières partout, des crêtes roses, des cristaux qui brillent dans le noir. Des couleurs que le ciel n'a pas ! Leur ligne vient de rouvrir. Je descends demain. Je n'ai pas assez de rose.", {"a_rencontre": "ysae"}),
					L("Le Docteur Aurèle donne un prénom à chaque nuage. Moi, je leur donne une couleur. Nous ne sommes jamais d'accord. Il dit « Gontran ». Je dis « abricot ». C'est le même nuage.", {}, "rire"),
					L("Lili m'a demandé de lui peindre la mer. Je l'ai peinte depuis le Belvédère : toute petite, toute brillante, tout en bas. Elle a dit : « Elle est plus grande, en vrai ? » J'ai dit : « Beaucoup plus. » Elle l'a accrochée au-dessus de son lit.", {}),
					L("Monsieur Pascal m'a dit que mes couchers de soleil étaient « trop orange ». Le lendemain, il est venu au Belvédère pour vérifier. Il est resté jusqu'à la fin. Il a dit : « Bon. Celui-là, ça va. » C'était un compliment immense.", {}, "rire"),
				],
				"interpelle": [L("Oh… regarde ce nuage…", {"visites_max": 0}), L("{surnom}… Tu as vu cette lumière ?", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Bon vent, {surnom}. Et lève les yeux ce soir. Il y aura un tableau gratuit.", {}, "salut"), L("Au revoir… (Elle cherche son pinceau. Il est derrière son oreille.)", {}, "rire"), L("Bonne nuit. Le soleil est parti sous l'île. Il revient demain par l'autre côté, tout neuf.", {"soir": true})],
				"souvenir": [L("Si je me souviens de toi ? Oui. Tu es venu le jour du coucher de soleil numéro neuf cent quatre-vingt-sept. Un violet très doux. Je te le montrerai.", {})],
			}},
		{"id": "pascal", "nom": "Monsieur Pascal Pression", "titre": "retraité des Résidences des Terrasses", "maison": "porte_pascal", "village": "nuees", "vouvoie": true,
			"agenda": [[7, 10, "residences_jardin"], [10, 12, "residences_banc"], [12, 14, "maison"], [14, 17, "esplanade_banc_3"], [17, 20, "residences_jardin"], [20, 22, "residences_banc"], [22, 7, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "moustache", "yeux": Y_BRUN, "chapeau": "casquette", "chapeau_c": GRIS_DOUX, "haut": GRIS_DOUX, "vieux": true, "taille": 0.94, "carrure": 1.1},
			"teinte": PEAU[2],
			"neo": {"tenue": "tailleur", "c": GRIS_DOUX, "c2": SABLE, "chapeau": "casquette", "chapeau_c": GRIS_DOUX},
			"humeur_base": 0.15, "traits": {"bavard": 0.75, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.8, "rancunier": 0.2},
			"aime": {"graines": 2.5, "chouquettes": 2.5, "the_sommets": 1.5, "pain_miel": 1.5, "croissant": 2.0, "baies": 1.5}, "deteste": {"chapeau_ventilateur": -1.5, "sifflet_muet": -1.0, "bombe_peinture": -1.5},
			"tics": ["De mon temps…", "C'est un scandale.", "Hm.", "Je ne dis rien, mais je n'en pense pas moins."],
			"surnoms": [[0, "vous, là"], [25, "le voyageur"], [50, "le voyageur pas trop pénible"], [75, "mon jeune ami"], [95, "mon ami, et je ne le dis pas souvent"]],
			"repliques": {
				"accueil": [
					L("Hm. Encore quelqu'un du Plancher. Pascal Pression, des Résidences. Je vous préviens : le soleil est trop fort, le vent est trop frais, la Gare est trop pleine, et la musique d'en bas est trop forte. À part ça, bienvenue. Si, si. Bienvenue.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Vous revoilà. Bon. Asseyez-vous. Pas là, c'est la place de… de personne. Bon, asseyez-vous là.", {"visites_min": 2}),
					L("{surnom} ! Vous… Non, rien. J'allais dire que j'étais content de vous voir. Ça m'a échappé. N'en parlez à personne.", {"visites_min": 5}, "rire"),
				],
				"humeur": [
					L("Mauvaise. Comme d'habitude. Le soleil se lève trop tôt, ici. Toujours. Au-dessus des nuages, il n'a aucune pudeur.", {}),
					L("Excellente, pour une fois. Ne le répétez pas, ça me ferait une réputation.", {"humeur_min": 0.5}, "rire"),
					L("Le matin, je bois mon thé dans le jardin des Résidences. C'est le seul moment de calme. Ensuite, les gens du Plancher arrivent par la Ligne, et ça parle, et ça photographie, et ça fait « waouh ». Trois ans sans eux, et voilà. Enfin. Ça met de l'animation.", {"matin": true}),
					L("Le soir, les jours de concert, la musique de la Fronde monte par le conduit de la Colonne, depuis les Strates. Boum, boum, boum, jusqu'à minuit. Au-dessus des nuages ! Je ferme mes fenêtres. Je les rouvre un peu. Pour vérifier si c'est toujours aussi fort. C'est toujours aussi fort.", {"soir": true}),
				],
				"lui": [
					L("Ma femme est partie vivre chez sa sœur, au Plancher, il y a dix ans. Elle trouvait qu'il faisait trop beau, ici. Alors je descends chercher mon pain en bas tous les matins, et je passe lui dire bonjour. Elle adorait les moineaux. Bon. Voilà. Ne me regardez pas comme ça.", {"sujet_min": ["lui", 3]}),
					L("J'ai été ingénieur des pressions à l'Institut pendant quarante ans. Je vérifiais que l'air de la ville restait bon. Maintenant, je vérifie que les gens restent polis. C'est plus difficile. L'air, au moins, ne répond pas.", {}),
					L("On dit que je suis ronchon. Je ne suis pas ronchon. Je suis exigeant. Le monde est en dessous de mes exigences. C'est normal : nous sommes à deux cents mètres d'altitude.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Bon. Puisque vous insistez. Oui, je nourris les moineaux, derrière les Résidences. Tous les matins. Ils s'appellent Pépin, Miette, Noisette et Gérard. Gérard est le plus gros. Ne le dites à personne. Si on apprend que j'ai un cœur, je vais devoir dire bonjour aux gens.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Résidences des Terrasses, au sud-ouest : des immeubles blancs en gradins, des balcons fleuris, des jardins partout. Avant, c'était calme. Maintenant, il y a des gens du Plancher qui viennent photographier nos balcons. Je mets ma plus belle chemise. Pour les décourager.", {}, "rire"),
					L("La Gare des Nuées, depuis la réouverture : une queue jusqu'au Belvédère ! Des gens d'en bas qui regardent tout, qui touchent tout, qui disent « c'est propre, ici ». Évidemment que c'est propre ! On recycle tout ! Même les remarques ! … Ils sont gentils, remarquez. Un peu bruyants. Gentils.", {"sujet_min": ["ile", 1]}),
					L("Le Dôme d'Azur, au fond de la mer, a rouvert, paraît-il. Encore des gens qui vont monter ici. Du fond de la mer jusqu'au ciel ! Ils vont avoir les oreilles qui sifflent. Je leur ai envoyé des chouquettes. Pour les oreilles. Ça aide. Ils n'ont pas compris. Ils les ont mangées.", {"sujet_min": ["ile", 2]}, "rire"),
					L("La ligne des Strates a rouvert. J'ai écrit quarante réclamations contre la musique de la Fronde. Puis je suis descendu les porter moi-même. Une dame m'a servi une potée. Je suis remonté avec les joues roses. Je n'ai rien déposé. Ne me regardez pas comme ça.", {"sujet_min": ["ile", 3]}),
				],
				"rumeur": [
					L("Ce Firmin, le frère de Gustave, en bas… Il paraît que sa machine à chocolat siffle comme une locomotive. Un scandale. Je suis descendu vérifier. Elle siffle. J'ai pris deux chocolats. Pour vérifier encore.", {"a_rencontre": "firmin"}, "rire"),
					L("Ce jeune Icare passe au-dessus de mon balcon avec son planeur. Tous les jours. Il fait peur à mes géraniums. Bon, il fait aussi rire mes moineaux. Je ne sais pas encore si je lui en veux.", {}),
					L("Le Grand-Père Séverin me traite de gamin. J'ai soixante-dix ans. Il dit que je pourrai me plaindre quand j'aurai son âge. Je m'entraîne. Je suis très doué.", {}, "rire"),
					L("Gustave me met une chouquette de plus dans ma poche, le matin, quand il croit que je ne regarde pas. Je regarde. Je ne dis rien. Gérard, le moineau, est très content.", {}, "rire"),
					L("Le batteur de la Fronde m'a envoyé une paire de baguettes. Avec un mot : « Pour mieux battre la mesure. » Insolent ! … Je les ai posées sur ma table de nuit. Elles sont très bien taillées. Ce n'est pas pareil.", {"a_rencontre": "rivet_fr"}, "rire"),
				],
				"interpelle": [L("Vous, là ! Ne marchez pas sur la pelouse ! … Bon, marchez-y doucement.", {"visites_max": 0}, "colere"), L("{surnom}. Hm. Bonjour.", {"visites_min": 1}, "salut")],
				"au_revoir": [L("C'est ça, bon vent. Et ne faites pas trop de bruit dans la Gare. … Revenez quand même.", {}, "salut"), L("Allez, filez. J'ai des moineaux à… Non, rien. Filez.", {}, "rire"), L("Bonsoir. Si c'est un soir de concert, mettez du coton dans vos oreilles. Ou ne le mettez pas, et dites-moi si c'était bien.", {"soir": true}, "rire")],
				"souvenir": [L("Si je me souviens de vous ? Hm. Évidemment. Vous êtes la seule personne du Plancher qui ne m'a pas demandé où étaient les toilettes en arrivant. Ça m'a marqué.", {})],
			}},
		{"id": "plumeau", "nom": "Plumeau", "titre": "robot jardinier de la Cité des Nuées", "maison": "porte_plumeau", "village": "nuees",
			"agenda": [[5, 10, "parc_pelouse"], [10, 12, "serres_allee"], [12, 14, "parc_source"], [14, 17, "esplanade_fontaine"], [17, 20, "parc_pelouse"], [20, 22, "serres_allee"], [22, 5, "maison"]],
			"azur": {"cheveux": NEIGE, "coiffure": "chauve", "yeux": BLEU_DOUX, "chapeau": "paille", "haut": SAUGE, "taille": 0.98},
			"teinte": PEAU[0],
			"neo": {"android": true, "peau": [0.96, 0.96, 0.97], "circuit": BLEU_DOUX, "lueur_yeux": 0.55, "tenue": "jardinier", "c": SAUGE, "c2": NEIGE, "chapeau": "paille", "objet": "arrosoir"},
			"humeur_base": 0.6, "traits": {"bavard": 0.6, "humour": 0.3, "curiosite": 0.8, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"graines": 3.0, "eau_source": 2.5, "goutte_rosee": 2.0, "fleur_nebuleuse": 2.0, "ressort": 1.5, "engrenage": 1.0}, "deteste": {"hache": -2.0, "gelee_slime": -1.0},
			"tics": ["Bonjour, l'arbre.", "Bip.", "Arrosage en cours.", "Blague enregistrée."],
			"surnoms": [[0, "visiteur"], [25, "visiteur gentil"], [50, "ami enregistré"], [75, "ami prioritaire"], [95, "ami pour toujours (sauvegardé deux fois)"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Je suis Plumeau, robot jardinier de la Cité des Nuées. Je ramasse les feuilles, j'arrose, et je dis bonjour aux arbres. Bonjour, l'arbre. … Voilà. Bonjour, visiteur. Vous êtes plus bavard que l'arbre. C'est agréable.", {"visites_max": 1}, "salut"),
					L("Bonjour, {surnom}. Visage reconnu. Bonjour, le banc. Bonjour, le moineau. Bonjour encore, {surnom}. Je vous ai dit bonjour deux fois. C'est parce que je suis content.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Batterie faible : vingt-deux pour cent. Un nuage est resté au-dessus des panneaux solaires toute la matinée. Le Docteur Aurèle dit qu'il s'appelle Fernand. J'ai demandé poliment à Fernand de se déplacer. Traitement en cours.", {"humeur_max": -0.2}),
					L("Batterie : quatre-vingt-dix-sept pour cent. Feuilles ramassées : mille deux cent douze. Arbres salués : trois cent quarante. Arbres ayant répondu : zéro. Mais je sens qu'ils y pensent.", {}),
					L("Légère perplexité. Le Docteur Aurèle m'a raconté une nouvelle blague. Je l'ai enregistrée. Je l'ai analysée quatre cents fois. Je ne trouve pas où est le drôle. Mais tout le monde rit quand je la répète. Le drôle, c'est peut-être moi.", {}, "rire"),
					L("Le matin, la rosée brille sur la pelouse du Parc. Je l'arrose quand même. Flora dit que ce n'est pas nécessaire. Moi, je dis que c'est poli.", {"matin": true}),
					L("Le soir, je rentre dans ma niche de recharge, près des Serres. Pendant la recharge, je rêve. Je rêve que les arbres me disent bonjour. Ils ont une voix très lente. Il faut trois nuits pour une seule phrase.", {"soir": true}),
				],
				"lui": [
					L("J'ai été construit à l'Atelier des Inventeurs, il y a quarante ans. On m'a appelé Plumeau parce que, le premier jour, j'ai essayé d'épousseter un arbre. Entièrement. Il était très propre. Il n'avait plus de feuilles. J'ai appris.", {}, "rire"),
					L("Je suis un peu lent. Mireille dit que c'est un défaut. Flora dit que c'est une qualité : « Les plantes aussi sont lentes. » Je préfère l'avis de Flora. Il me prend moins de temps à traiter.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Question, {surnom}. Je dis bonjour aux arbres depuis quarante ans. Ils ne répondent pas. Mais ils grandissent. Et moi, quand on me dit bonjour, je me sens… plus grand aussi. Est-ce que c'est la même chose ? Je calcule. Je pense que oui.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Information : le Parc des Brumes compte quatre cent douze arbres, une pelouse, un étang et une Source. L'eau de la Source vient des nuages. L'eau de l'étang tombe par-dessus le bord : c'est la Cascade des Nuées. Elle devient brume avant de toucher le sol. Je trouve cela très économe.", {}),
					L("Ici, on recycle tout. Les feuilles deviennent du compost, le compost devient des fraises, les fraises deviennent du jus de soleil, et le jus de soleil devient… Gustave dit « de la bonne humeur ». Je n'ai pas encore trouvé comment la ramasser.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Le Père Bastien, de Hautefond, est monté parler à mes arbres. Il leur a parlé une heure. Ils n'ont pas répondu non plus. Mais il m'a dit : « Continue, mon garçon. » Personne ne m'avait jamais appelé « mon garçon ». J'ai enregistré la phrase. Je la réécoute le soir.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le Père Bastien, de Hautefond, vous l'avez rencontré ? Il m'a envoyé une lettre. Elle disait : « Bonjour, Plumeau. Bonjour, les arbres. » Je l'ai lue aux arbres. Je crois qu'ils étaient émus. Ils ont perdu trois feuilles.", {"a_rencontre": "bastien_hf"}),
					L("Blague du Docteur Aurèle, numéro cent douze : « Que dit un nuage à un autre nuage ? Rien. Il est dans le vague. » Fin de la blague. … Vous pouvez rire maintenant. Le Docteur rit à cet endroit-là.", {}, "rire"),
					L("Monsieur Pascal nourrit les moineaux derrière les Résidences, tous les matins à sept heures quatre. Il m'a demandé de ne pas le dire. Je ne l'ai pas dit. Je l'ai seulement constaté à voix haute. Ce n'est pas pareil. Je crois.", {}, "rire"),
					L("La petite Lili m'a appris un mot : « bientôt ». Elle dit que c'est le mot préféré de sa maman. J'ai cherché sa durée exacte. Je ne la trouve pas. Selon Lili, c'est « beaucoup trop longtemps ».", {}),
				],
				"interpelle": [L("Bonjour. Bonjour, l'arbre. Bonjour, visiteur.", {"visites_max": 0}, "salut"), L("{surnom} ! Bip ! Bonjour !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Au revoir, {surnom}. Je retourne dire bonjour aux arbres. Il m'en reste deux cent six.", {}, "salut"), L("Bon vent. Expression locale. Je la dis bien ?", {}, "rire"), L("Bonne nuit. Je vais me recharger. Bonne nuit, l'arbre. Bonne nuit, le banc.", {"soir": true})],
				"souvenir": [L("Si je me souviens de vous ? Oui. Vous êtes enregistré dans ma mémoire, dossier « gens qui disent bonjour aux arbres avec moi ». Il y a très peu de monde dans ce dossier. Vous y êtes au chaud.", {})],
			}},
	]

extends RefCounted
## V76 : les Lumens d'Astralys, la cité de cristal et de lumière, sur la grande île flottante du
## nord-ouest (à 380 m au-dessus de la mer). Les Lumens sont des extraterrestres sages, lumineux,
## très avancés, gentils et un peu farfelus : venus de la planète Ondelune il y a mille ans « en
## vacances », ils ne sont jamais repartis. Ils adorent les Terriens (« les Pieds-Lourds »,
## affectueusement), collectionnent les objets de toutes les îles, parlent avec des expressions
## bizarres et ne comprennent rien à l'argent (ils l'acceptent quand même, par politesse).
##  - le Conseil, au pied de la Flèche de Cristal : la Doyenne Astrée (1043 ans), Écliptique (le chef
##    du protocole), Tempo (l'horloger du temps), Solenne (l'ambassadrice), Volt (l'énergie de la
##    Flèche) ;
##  - l'Agora des Étoiles : Gloubi (le Café Nébuleuse, quatre bras), Nébula (le Bazar galactique),
##    Vibrato (le thérémine), Prisme (la danseuse de lumière), Lyre (la poétesse, en vers), l'Hologuide
##    (le guide holographique : il répète sa visite) ;
##  - le Musée des Mondes (Orbe, l'Archiviste) et l'Académie des Sciences (le Professeur Quasar, Murmure
##    la bibliothécaire qui chuchote) ; l'Observatoire (Zénith) ; Sextant (le cartographe) ;
##  - le Spatioport (Ionie la mécanicienne, Comète la pilote) ; les Jardins suspendus (Photon) ; la
##    Serre des Espèces (Nova) ; le Quartier des Bulles (Bulle l'architecte, Aurore la guérisseuse) ;
##    le Portail d'accueil (Halo, et son discours de quatre minutes) ;
##  - les enfants Pixel (89 ans, c'est-à-dire 8 ans lumens) et Quark (son frère, farceur) ;
##  - et un touriste de passage : Glorb, gélatineux et vert, qui prend tout en photo.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure
## (pnj_azur_v56.gd). Fiche « village » : astralys (les lieux : voir la note V76).
## La Nuit des Aurores (chaque nuit de 22 h à 2 h) : Prisme danse sur agora_holo, Vibrato joue sur
## agora_fontaine ; Astrée, Lyre et Écliptique sont sur les bancs (agora_banc_1, 2, 3) ; d'autres
## regardent depuis les tables du café, les rues, les belvédères.
## Identifiants : « aurore » et « bulle » existent déjà (Montjoie, Braise) : la guérisseuse est
## « aurore_lumen » et l'architecte « bulle_lumen » ; leurs maisons restent porte_aurore et porte_bulle
## (les portes de la ville d'Astralys, astrale_ville_v76.gd ; chaque ville a ses propres portes).
## Fiche « lumen » (pour le générateur de corps) : peau (bleu_pale | lavande | argent | turquoise |
## rose_nacre | or_pale), tenue (tunique | robe_longue | cape | combinaison | toge | enfant), crete
## (cristal | filaments | aucune), antennes (bool), bijou (halo | diademe | collier | aucun), objet
## (tablette_holo | baton_lumiere | theremine | arrosoir | telescope_portable | plateau | appareil_holo |
## livre | aucun), et en plus pour Gloubi : quatre_bras. Deux cas spéciaux, à ne PAS générer comme
## des Lumens : Glorb ({"special": "glorb"} : touriste gélatineux vert, appareil holo-photo au cou)
## et l'Hologuide ({"special": "hologramme"} : forme humaine lumineuse et transparente). Le même
## « special » est aussi posé à la racine de la fiche (pour le jeu : matériau, ombre, cadeaux).

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Que ta lumière ne vacille jamais, {surnom} ! Et reviens : le ciel est plus joli quand il y a des Pieds-Lourds dedans.", "si": {}, "geste": "salut"},
		{"t": "Au revoir ! Attention en descendant par le rayon : on a toujours un petit creux dans le ventre. C'est normal, c'est la gravité qui dit bonjour.", "si": {}, "geste": "rire"},
		{"t": "À bientôt ! Sur Ondelune, on dit « à dans mille ans ». Ici, on dit « à demain ». C'est beaucoup plus pratique.", "si": {}, "geste": "rire"},
		{"t": "Bonne nuit ! Lève les yeux tout à l'heure : les aurores vont danser. Elles dansent pour tout le monde, même pour ceux qui dorment.", "si": {"soir": true}, "geste": "salut"},
	],
	"frappe": [
		{"t": "Aïe ! Oh ! Par les sept lunes ! Sur Ondelune, on se dit bonjour en clignotant, pas en tapant !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Mes antennes ont fait des étincelles. Ce n'est pas très gentil, ça, Pied-Lourd. Pas gentil du tout.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Comme c'est terrestre ! Je ne sais pas du tout à quoi ça sert, alors je vais le garder précieusement.", "si": {}},
		{"t": "Merci, {surnom}. Je vais le poser sur mon étagère à curiosités, entre un caillou d'Ondelune et une chaussette de Port-Azur.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Mes antennes clignotent de joie ! Regarde, elles font des petites étoiles !", "si": {}, "geste": "rire"},
		{"t": "Par les sept lunes, c'est parfait ! Tu as le cœur d'un Lumen sous tes pieds lourds, {surnom}.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Ah. Euh. C'est… très… terrestre. Merci. Orbe le voudra sûrement pour le Musée. Il veut tout.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Non merci. Sur Astralys, la chose la plus pointue, c'est la Flèche de Cristal. Et elle ne fait de mal à personne.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Un Lumen n'oublie rien, {surnom}. Nous avons de la place dans la tête : mille ans de place.", "si": {}}],
	"quete_inconnue": [{"t": "Hmm ? Je ne t'ai rien demandé. Ou alors c'était il y a trois cents ans, et c'était quelqu'un d'autre.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les Lumens ne jouent jamais à cache-cache la nuit ? Parce qu'ils brillent ! … Sauf Pixel et Quark. Eux, on ne les retrouve jamais.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'une étoile dit à une autre étoile ? « Tu as bonne mine, tu brilles ! » … C'est une blague d'Ondelune. Elle a un million d'années. Elle est un peu fatiguée.", "si": {}, "geste": "rire"},
		{"t": "Comment appelle-t-on un Pied-Lourd sur Astralys ? Un touriste ! Et un touriste sur Astralys qui prend tout en photo ? Glorb.", "si": {}, "geste": "rire"},
		{"t": "Pourquoi la Lune est-elle toujours de bonne humeur ? Parce qu'elle est pleine… de temps en temps. Les autres jours, elle fait semblant.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Regarde, choisis ! Ah, et tu peux me donner ces petites rondelles brillantes, si tu veux. Je ne sais pas à quoi elles servent, mais c'est poli. Tu en as {pieces}.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui, {surnom}. Mon cœur clignote encore rouge. Reviens quand il sera de nouveau bleu.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Voilà : {objet}, contre {prix} rondelles. C'est bien ça qu'on dit ? « Pièces ». Pièces. Quel joli mot inutile.", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "Il faut {prix} rondelles, et tu en as {pieces}… Je ne comprends pas pourquoi ça compte, mais il paraît que ça compte. Reviens plus tard !", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un, non ? Sur Astralys, on dit : « Une chose, c'est un souvenir. Deux choses pareilles, c'est un encombrement. »", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein, {surnom} ! Comme un dôme après une fête. Fais un peu de place, et reviens.", "si": {}, "geste": "rire"}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} rondelles. Elles sont très jolies, tu verras. Enfin, tu le sais déjà.", "si": {}}],
	"vente_lot": [{"t": "Tout ça ? Quelle collection ! Allez : {prix} pièces, et un clignotement d'antennes en prime.", "si": {}, "geste": "rire"}],
	"marchande_oui": [{"t": "Marchander ? Ah, c'est le jeu où on dit des nombres jusqu'à ce que tout le monde sourie ! J'adore ce jeu. Allez, un peu moins.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Non, non. Le Conseil a fixé ce nombre-là. Je ne sais pas pourquoi, mais Écliptique a fait un discours, et personne n'ose y toucher.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà joué au jeu des nombres aujourd'hui, petit malin. Un Lumen n'oublie rien. Rien du tout.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Par les sept lunes !", "Comme c'est lumineux !", "Hi hi !", "Quelle merveille !"],
		"neutre": ["Hmm.", "Voyons…", "Bien.", "Ah."],
		"triste": ["Oh…", "Mes antennes tombent…", "Hélas.", "Quelle pénombre…"],
		"colere": ["Par la queue d'une comète !", "Ça suffit !", "Bzzt.", "Tss."],
	},
	"tics": ["Que ta lumière ne vacille pas.", "Comme on dit sur Ondelune.", "C'est très terrestre.", "Mes antennes clignotent."],
	"humeur_mots": [[0.6, "rayonnant"], [0.25, "lumineux"], [-0.25, "un peu terne"], [-0.6, "tout éteint"], [-2.0, "en colère comme une supernova"]],
	"surnoms": [[0, "Pied-Lourd"], [25, "petit Pied-Lourd"], [50, "ami des étoiles"], [75, "presque-Lumen"], [95, "étoile d'honneur"]],
}

## La peau des Lumens (légèrement luminescente) : les six teintes de la fiche « lumen ».
const PEAU_LUMEN := {
	"bleu_pale": [0.72, 0.84, 0.98], "lavande": [0.8, 0.73, 0.95], "argent": [0.86, 0.88, 0.92],
	"turquoise": [0.58, 0.9, 0.87], "rose_nacre": [0.98, 0.84, 0.88], "or_pale": [0.98, 0.9, 0.7],
}
## Les grands yeux des Lumens.
const Y_AZUR := [0.3, 0.6, 0.95]
const Y_VIOLET := [0.55, 0.35, 0.9]
const Y_OR := [0.85, 0.7, 0.25]
const Y_ARGENT := [0.75, 0.78, 0.85]
const Y_TURQUOISE := [0.2, 0.75, 0.7]
const Y_ROSE := [0.85, 0.45, 0.65]
## Les étoffes (tuniques, capes, robes à reflets).
const BLANC_NACRE := [0.94, 0.94, 0.97]
const BLEU_NUIT := [0.12, 0.14, 0.32]
const VIOLET_PROFOND := [0.36, 0.2, 0.55]
const ARGENT_C := [0.78, 0.8, 0.86]
const OR_C := [0.88, 0.74, 0.38]
const TURQUOISE_C := [0.2, 0.62, 0.62]
const ROSE_C := [0.9, 0.6, 0.72]
const GRIS_PERLE := [0.6, 0.62, 0.68]


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
	# la teinte de peau vient de la fiche « lumen » (sauf les cas spéciaux, qui donnent la leur)
	var lu: Dictionary = out.get("lumen", {})
	if not out.has("teinte") and PEAU_LUMEN.has(str(lu.get("peau", ""))):
		out["teinte"] = PEAU_LUMEN[str(lu["peau"])]
	if lu.has("special"):
		out["special"] = str(lu["special"])
	out = Azur.complete(out)
	out["groupe"] = "astralys"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


## Les lieux (« spots ») de la ville que les agendas peuvent nommer (note V76), plus « maison ».
const SPOTS := ["conseil_doyenne", "conseil_1", "conseil_2", "fleche_base", "agora_fontaine", "agora_banc_1", "agora_banc_2",
	"agora_banc_3", "agora_holo", "cafe_comptoir", "cafe_table_1", "cafe_table_2", "cafe_table_3", "cafe_table_4", "bazar_comptoir",
	"bazar_etal_1", "bazar_etal_2", "musee_accueil", "musee_salle_1", "musee_salle_2", "academie_tableau", "academie_labo_1",
	"academie_labo_2", "academie_eleve_1", "academie_eleve_2", "observatoire_telescope", "observatoire_pont", "spatioport_hangar",
	"spatioport_tour", "spatioport_aire_1", "spatioport_aire_2", "jardins_1", "jardins_2", "jardins_bassin", "apesanteur_1",
	"apesanteur_2", "bulles_no_1", "bulles_no_2", "bulles_ne_1", "bulles_ne_2", "serre_1", "serre_2", "portail_accueil",
	"portail_belvedere", "rue_1", "rue_2", "rue_3", "rue_4", "rue_5", "rue_6"]


static func _all() -> Array:
	return [
		# ================================================================ le Conseil, au pied de la Flèche
		{"id": "astree", "nom": "la Doyenne Astrée", "titre": "Doyenne du Conseil d'Astralys", "maison": "porte_astree", "village": "astralys",
			"agenda": [[7, 8, "jardins_bassin"], [8, 12, "conseil_doyenne"], [12, 14, ["cafe_table_1", "jardins_bassin"]], [14, 17, "conseil_doyenne"], [17, 19, ["jardins_1", "agora_banc_1"]], [19, 22, "maison"], [22, 0, "agora_banc_1"], [0, 7, "maison"]],
			"azur": {"cheveux": BLANC_NACRE, "coiffure": "chauve", "yeux": Y_ARGENT, "haut": BLANC_NACRE, "robe": ARGENT_C, "vieux": true, "taille": 1.08, "carrure": 0.78},
			"lumen": {"peau": "argent", "tenue": "robe_longue", "crete": "filaments", "antennes": true, "bijou": "diademe", "objet": "baton_lumiere"},
			"humeur_base": 0.7, "traits": {"bavard": 0.6, "humour": 0.85, "curiosite": 0.9, "susceptible": 0.05, "rancunier": 0.0},
			"aime": {"the_stellaire": 2.5, "carte_postale": 2.5, "fleur_nebuleuse": 2.0, "biscuit_lunaire": 1.5, "tisane_lune": 1.5, "pain_miel": 1.5}, "deteste": {"piment_infernal": -1.0, "vieille_botte": -0.5},
			"tics": ["Mon petit astre.", "Hi hi.", "À mon âge, on a le temps.", "Voyons, voyons…"],
			"surnoms": [[0, "mon petit astre"], [25, "mon petit astre"], [50, "ma petite comète"], [75, "mon étoile"], [95, "mon étoile préférée (ne le dis pas aux autres)"]],
			"repliques": {
				"accueil": [
					L("Oh ! Un Pied-Lourd ! Approche, approche, mon petit astre, je ne mords pas : je n'ai plus de dents depuis le neuvième siècle. Je suis Astrée, la Doyenne du Conseil. Mille quarante-trois ans. Je sais, je ne les fais pas. Je fais au moins mille cinquante.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens t'asseoir près de moi. Mes antennes t'ont senti arriver dès le Portail. Elles sont vieilles, mais elles ont bon nez.", {"visites_min": 2}, "rire"),
					L("Le Cœur bat. Tu l'entends ? Tout là-haut, dans la Flèche. Grâce à toi. Je ne te remercierai jamais assez, alors je vais te remercier un peu tous les jours.", {"a_trouve": "fleche_coeur"}),
				],
				"humeur": [
					L("Très bien ! Ce matin, j'ai battu Tempo aux échecs lunaires. Il dit que j'ai triché. J'ai simplement joué deux coups pendant qu'il regardait l'heure.", {}, "rire"),
					L("Un peu soucieuse, je l'avoue. Le Cœur de la Flèche bat moins fort. Volt dit que ce n'est rien. Volt dit toujours que ce n'est rien, avant de dire que c'est grave.", {"q56": "as_coeur="}),
					L("Inquiète. Le Cœur faiblit, les ponts de lumière clignotent… Mais tu es là. Et quand un Pied-Lourd se met en tête d'aider, même les étoiles se poussent pour le laisser passer.", {"q56": "as_coeur=en_cours"}),
					L("Le soir, je m'assieds sur mon banc de l'Agora et j'attends les aurores. Mille ans que je les regarde. Elles ne m'ont jamais montré deux fois la même couleur. C'est de la politesse.", {"soir": true}),
				],
				"lui": [
					L("Je suis arrivée d'Ondelune il y a mille ans, avec les autres, « pour les vacances ». J'avais quarante-trois ans : une petite fille, chez nous. Nous devions rester trois semaines. Le paysage était trop beau. Nous avons défait les valises. Elles sont toujours défaites.", {}),
					L("J'ai été élue Doyenne parce que j'étais la plus vieille. C'est notre règle : la plus vieille décide. Écliptique a proposé une autre règle, avec des votes et des chapeaux. Nous avons voté. Nous avons gardé la mienne. Hi hi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te confier une chose, mon petit astre. La première fois que j'ai vu un Pied-Lourd, il pêchait dans une barque, tout en bas. Il chantait faux. Il était heureux. Je me suis dit : ces gens-là, il faut les aimer de loin et les aider en secret. Nous faisons ça depuis mille ans.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Astralys flotte grâce au Cœur de la Flèche : un cristal grand comme une maison, tout en haut de la tour. Il bat comme un cœur, et il tient l'île dans le ciel. Ne t'inquiète pas : il est très solide. Enfin, il l'était.", {}),
					L("La Salle du Conseil est au pied de la Flèche. On y discute de tout : du Cœur, des ponts, des aurores, et de qui a mangé la dernière gelée de Gloubi. Ce dernier sujet prend beaucoup de temps.", {"sujet_min": ["ile", 1]}, "rire"),
					L("Tu sais pourquoi on vous appelle les Pieds-Lourds ? Parce que vous marchez. Nous, on flotte un peu, quand on oublie de faire attention. C'est un compliment, hein : vous avez les pieds sur terre. Nous, il nous en manque un peu.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Écliptique a préparé un discours de bienvenue de onze minutes pour le prochain visiteur. Halo en a préparé un de quatre. Ils se disputent pour savoir lequel passera en premier. Le visiteur, lui, est reparti.", {}, "rire"),
					L("Solenne revient de voyage avec des yeux qui pétillent. Elle dit qu'elle est allée « voir les îles ». Je l'ai vue partir avec une fausse barbe. Je n'ai rien dit. À mon âge, on aime les secrets des autres.", {}),
					L("Pixel et Quark se cachent partout. Hier, Quark s'est caché dans la fontaine, entre Saturne et Ondelune. On ne l'a retrouvé qu'au moment de la planète suivante.", {}, "rire"),
				],
				"interpelle": [L("Psst ! Toi ! Viens dire bonjour à une vieille étoile !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens, mon petit astre !", {"visites_min": 1}, "rire")],
			}},
		{"id": "ecliptique", "nom": "Écliptique", "titre": "chef du protocole du Conseil", "maison": "porte_ecliptique", "village": "astralys", "vouvoie": true,
			"agenda": [[8, 12, "conseil_1"], [12, 14, ["cafe_table_3", "cafe_table_2"]], [14, 17, "conseil_1"], [17, 19, ["agora_fontaine", "portail_belvedere"]], [19, 22, "maison"], [22, 1, "agora_banc_3"], [1, 8, "maison"]],
			"azur": {"cheveux": OR_C, "coiffure": "chauve", "yeux": Y_OR, "haut": OR_C, "robe": VIOLET_PROFOND, "taille": 1.14, "carrure": 0.95},
			"lumen": {"peau": "or_pale", "tenue": "toge", "crete": "cristal", "antennes": true, "bijou": "collier", "objet": "livre"},
			"humeur_base": 0.45, "traits": {"bavard": 1.0, "humour": 0.3, "curiosite": 0.4, "susceptible": 0.75, "rancunier": 0.2},
			"aime": {"cle_ville": 3.0, "couronne_nuees": 3.0, "tricorne_or": 2.5, "diplome_infernal": 2.0, "ceinture_champion": 2.0, "the_stellaire": 1.0}, "deteste": {"vieille_botte": -1.5, "gelee_slime": -1.0},
			"tics": ["Selon le protocole…", "Hum hum.", "Par décret du Conseil !", "(Il ajuste sa toge, qui tombe aussitôt.)"],
			"surnoms": [[0, "honorable visiteur"], [25, "très honorable visiteur"], [50, "éminent Pied-Lourd"], [75, "illustrissime ami"], [95, "Grand Ami Protocolaire de Première Classe"]],
			"repliques": {
				"accueil": [
					L("Halte ! Hum hum. Je veux dire : bienvenue. Écliptique, chef du protocole du Conseil d'Astralys, gardien des préséances, maître des révérences et président du Comité des Discours. Selon le protocole, vous devez maintenant vous incliner. Non, pas comme ça. Pas comme ça non plus. Bon. Ça ira.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Selon l'article quatre cent douze du protocole, un visiteur qui revient a droit à une révérence de niveau deux. (Il s'incline, son collier se prend dans sa toge.) … Niveau un et demi. C'est déjà très bien.", {"visites_min": 2}),
					L("Illustrissime ! Sauveur du Cœur ! J'ai rédigé un discours en votre honneur. Il dure dix-neuf minutes. Je vous en lis le début ? … La Doyenne me dit que non. Je vous l'enverrai. En plusieurs fois.", {"a_trouve": "fleche_coeur"}, "rire"),
				],
				"humeur": [
					L("Excellente, selon les critères officiels. J'ai rangé les chaises de la Salle du Conseil par ordre d'importance. Il y avait un désaccord sur la mienne. Je l'ai réglé : elle est en haut de la liste.", {}),
					L("Contrariée. Hum. Je veux dire : contrarié. Halo a encore accueilli un visiteur sans moi. Quatre minutes de discours, sans relecture officielle. C'est de l'anarchie lumineuse.", {}),
					L("Le soir des aurores, je prends le troisième banc de l'Agora. C'est le banc protocolaire. Je l'ai décrété protocolaire hier, mais c'est très officiel.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai été nommé chef du protocole il y a trois cents ans, après avoir rédigé le Grand Règlement des Salutations. Neuf mille articles. Personne ne l'a lu en entier. Moi non plus, d'ailleurs. Mais je sais où il est rangé.", {}),
					L("Je fais parfois tomber des choses. Les plateaux de Gloubi, les décrets, les invités. Une fois, pendant une cérémonie, j'ai trébuché sur ma propre toge et je suis tombé dans la fontaine, en pleine planète Jupiter. La Doyenne a dit que c'était le plus beau discours de l'année.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais vous dire un secret, mais ne le répétez à personne : ce n'est pas protocolaire. Je suis très timide. Tous ces discours, ces règles, ces révérences… c'est pour savoir quoi faire de mes mains. Quand je ne sais pas quoi dire, je décrète.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Salle du Conseil est au pied de la Flèche de Cristal. Il y a trois sièges : celui de la Doyenne, le mien, et celui de Tempo. Celui de Tempo est le seul qui soit toujours à l'heure.", {}),
					L("Selon le protocole, on entre à Astralys par le Portail d'accueil, au sud-est, en montant par le rayon. Il y a des gens qui arrivent par le ciel, en machine volante. Ce n'est prévu dans aucun article. J'en rédige un. Il fait déjà quarante pages.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Halo prétend que son discours de bienvenue est le plus long d'Astralys. Quatre minutes ! Le mien dure onze minutes. Avec l'introduction. Sans l'introduction, il dure neuf minutes et demie. Ce qui est toujours plus long. Hum hum.", {}),
					L("Glorb, le touriste, m'a pris en photo pendant que je tombais de l'estrade. Il dit que c'est sa photo préférée. Je vais demander un décret pour qu'elle soit officiellement floue.", {}, "rire"),
				],
				"interpelle": [L("Halte ! Hum, je veux dire : bonjour, honorable visiteur !", {"visites_max": 0}, "salut"), L("{surnom} ! Révérence de niveau deux !", {"visites_min": 1}, "salut")],
			}},
		{"id": "tempo", "nom": "Tempo", "titre": "horloger du temps", "maison": "porte_tempo", "village": "astralys", "vouvoie": true,
			"agenda": [[6, 7, "agora_fontaine"], [7, 12, "conseil_2"], [12, 13, ["cafe_table_4", "cafe_table_3"]], [13, 17, "conseil_2"], [17, 18, "agora_fontaine"], [18, 21, ["rue_2", "agora_banc_1"]], [21, 6, "maison"]],
			"azur": {"cheveux": ARGENT_C, "coiffure": "chauve", "yeux": Y_AZUR, "haut": BLEU_NUIT, "taille": 1.02, "carrure": 0.8, "lunettes": true},
			"lumen": {"peau": "bleu_pale", "tenue": "tunique", "crete": "cristal", "antennes": true, "bijou": "aucun", "objet": "aucun"},
			"humeur_base": 0.35, "traits": {"bavard": 0.4, "humour": 0.4, "curiosite": 0.5, "susceptible": 0.55, "rancunier": 0.2},
			"aime": {"engrenage": 2.5, "rouage": 2.5, "ressort": 1.5, "croissant": 1.5, "boussole": 1.0}, "deteste": {"montre_envers": -2.0, "tisane_lune": -0.5},
			"tics": ["Il est exactement l'heure.", "Tic, tac.", "Pas une seconde de plus.", "Vous êtes en avance. Ou en retard. Voyons…"],
			"surnoms": [[0, "visiteur de 10 h 14"], [25, "visiteur ponctuel"], [50, "ami à l'heure"], [75, "ami d'une précision remarquable"], [95, "ami à la seconde près"]],
			"repliques": {
				"accueil": [
					L("Bonjour. Il est exactement l'heure où nous nous rencontrons. Tempo, horloger du temps. Ces horloges qui flottent autour de moi ? Elles sont toutes à l'heure. Chacune à une heure différente : celle d'Ondelune, celle d'Astralys, et celle où Gloubi croit que le déjeuner est prêt.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Vous revenez. Vous avez trente et une secondes d'avance sur l'heure où je pensais vous revoir. C'est très bien. Ne recommencez pas, ça me dérègle.", {"visites_min": 2}),
				],
				"humeur": [
					L("Précise. Ce matin, à sept heures zéro zéro, j'ai réglé l'horloge de la fontaine. À sept heures zéro une, Quark l'avait déréglée. À sept heures zéro deux, je l'ai attrapé. À sept heures zéro trois, je lui ai pardonné. Tout était dans les temps.", {}, "rire"),
					L("Contrarié. Le Cœur de la Flèche bat irrégulièrement. Un battement, puis rien, puis deux. Pour un horloger, c'est insupportable. Pour l'île, c'est inquiétant.", {"q56": "as_coeur=en_cours"}),
					L("Je me couche à vingt et une heures précises. Même les soirs d'aurores. Je les regarde par la fenêtre, de vingt-deux heures à vingt-deux heures cinq. Ensuite, je dors. C'est réglé comme une horloge, parce que je suis une horloge. Presque.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, les journées durent quarante heures. Ici, vingt-quatre. Quand nous sommes arrivés, tout le monde était perdu : les Lumens dînaient au milieu de la nuit et se couchaient à midi. J'ai fabriqué la première horloge d'Astralys. On m'appelle Tempo depuis. Avant, on m'appelait « Celui-qui-demande-l'heure ».", {}),
					L("Je n'ai été en retard qu'une seule fois en mille ans. Le jour où Astrée m'a demandé de l'épouser. Elle plaisantait, bien sûr. Mais je suis resté immobile pendant onze minutes. Quand je suis revenu à moi, elle avait fini son thé. Nous sommes très bons amis. À l'heure.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais vous confier quelque chose. J'ai une horloge qui ne marche pas. Elle est arrêtée sur le moment où nous avons quitté Ondelune. Je ne la répare pas. Certaines heures, il faut les garder telles qu'elles sont.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'horloge de la fontaine de l'Agora change de planète toutes les minutes. Exactement toutes les minutes. Si un jour elle change au bout de cinquante-neuf secondes, c'est que Quark est passé par là.", {}),
					L("La Nuit des Aurores commence à vingt-deux heures et finit à deux heures. Les aurores sont très ponctuelles. Ce sont les seules choses du ciel qui m'écoutent.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Gloubi dit que le déjeuner est « prêt dans cinq minutes » depuis onze heures quarante. Il est midi douze. J'ai compté. Il le sait. Il fait exprès de me faire attendre. Il dit que c'est bon pour mon caractère.", {}, "rire"),
					L("Halo fait un discours de quatre minutes à chaque visiteur. J'ai chronométré : quatre minutes et dix-sept secondes. Je ne le lui ai pas dit. Ça lui ferait de la peine. Et il rallongerait.", {}),
				],
				"interpelle": [L("Bonjour ! Il est exactement l'heure de se présenter.", {"visites_max": 0}, "salut"), L("{surnom}. Pile à l'heure.", {"visites_min": 1}, "salut")],
			}},
		{"id": "solenne", "nom": "Solenne", "titre": "ambassadrice d'Astralys", "maison": "porte_solenne", "village": "astralys",
			"agenda": [[9, 12, "spatioport_tour"], [12, 14, ["cafe_table_1", "cafe_table_2"]], [14, 18, ["musee_salle_2", "bazar_etal_1", "portail_belvedere"]], [18, 22, ["jardins_bassin", "agora_banc_2"]], [22, 1, ["rue_3", "rue_1"]], [1, 9, "maison"]],
			"azur": {"cheveux": OR_C, "coiffure": "chauve", "yeux": Y_VIOLET, "haut": ROSE_C, "robe": BLEU_NUIT, "taille": 1.06, "carrure": 0.82},
			"lumen": {"peau": "or_pale", "tenue": "cape", "crete": "filaments", "antennes": true, "bijou": "diademe", "objet": "aucun"},
			"humeur_base": 0.6, "traits": {"bavard": 0.75, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.2, "rancunier": 0.05},
			"aime": {"the_menthe": 2.5, "tajine_poisson": 2.5, "bouillabaisse": 2.0, "cidre_montjoie": 2.0, "gateau_miel": 2.0, "carte_postale": 2.0, "limonade_boucan": 1.5}, "deteste": {"remontant_doc": -0.5, "badge_usine": -1.0},
			"tics": ["Chut, c'est un secret.", "J'ai entendu dire…", "Quand j'étais là-bas… enfin, on m'a raconté.", "(Elle fait un clin d'œil.)"],
			"repliques": {
				"accueil": [
					L("Bonjour ! Solenne, ambassadrice d'Astralys. Mon travail ? Représenter les Lumens auprès des îles de l'archipel. Je n'y suis jamais allée, bien sûr. Jamais. (Elle cache derrière son dos un tricorne de pirate.) Officiellement.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu reviens d'où, cette fois ? Raconte-moi tout ! Je ne connais rien des îles, moi. Absolument rien. (Elle sourit beaucoup trop.)", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Merveilleuse ! J'ai rêvé que je mangeais une bouillabaisse à Port-Azur, sur une terrasse, avec un chef qui criait « mamma mia ». Un rêve très précis. Très, très précis.", {}, "rire"),
					L("Un peu fatiguée. J'ai… fait une longue promenade. Dans les jardins. Très longue. Avec beaucoup de mer. Les jardins sont grands, ici.", {}),
					L("Le soir, je regarde les îles depuis le bord. Les lumières de Port-Azur, les lanternes de Braise, les feux des pirates. Je les connais toutes par cœur. Par cœur… de loin, bien sûr.", {"soir": true}),
				],
				"lui": [
					L("Le Conseil m'a nommée ambassadrice il y a deux cents ans. Mission : observer les Pieds-Lourds sans jamais les déranger. Alors je me déguise. J'ai été vieille marchande de poisson, joueuse de pétanque, nonne, punk, gobeline… Ah. Je n'aurais pas dû dire ça.", {}, "rire"),
					L("Mon plus beau déguisement ? Une moustache, un béret et un accent. J'ai joué à la pétanque à Port-Azur tout un après-midi, avec un certain Raymond. J'ai perdu le cochonnet. Enfin… un cochonnet a été perdu. Ce n'est peut-être pas moi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La vérité, {surnom} ? J'aime les îles plus que je ne devrais. Les Lumens observent ; moi, je m'attache. Un jour, je voudrais y aller sans déguisement. Avec mes antennes. Et qu'on me dise bonjour quand même.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Officiellement, Astralys n'a jamais eu de contact avec les îles d'en bas. Officieusement, la moitié du Musée d'Orbe vient de mes valises. Il croit qu'on les trouve en tombant du ciel. Je le laisse croire.", {}, "rire"),
					L("Le Spatioport, à l'est : c'est là que je pars en voyage. Enfin, en promenade. Comète me dépose discrètement. Elle conduit très vite. On arrive avant d'être partis.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("On m'a raconté qu'à Montjoie, il y a des navets qui se sauvent. On m'a raconté. Je ne les ai pas poursuivis dans un champ avec un vieux fermier. Ce n'est pas moi.", {}, "rire"),
					L("Il paraît que dans l'archipel, des chiens, des chats, des rats et même des cochons suivent les héros partout. Les Lumens n'ont pas d'animaux. Seulement des méduses de ciel. Elles ne suivent personne, elles flottent. Ce n'est pas pareil.", {}),
				],
				"interpelle": [L("Bonjour, voyageur ! Vous venez… d'en bas ?", {"visites_max": 0}, "salut"), L("{surnom} ! Des nouvelles des îles ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "volt", "nom": "Volt", "titre": "ingénieur de l'énergie de la Flèche", "maison": "porte_volt", "village": "astralys",
			"agenda": [[6, 12, "fleche_base"], [12, 13, ["cafe_table_3", "rue_1"]], [13, 19, "fleche_base"], [19, 22, "maison"], [22, 2, "fleche_base"], [2, 6, "maison"]],
			"azur": {"cheveux": ARGENT_C, "coiffure": "chauve", "yeux": Y_AZUR, "haut": GRIS_PERLE, "taille": 1.1, "carrure": 1.05},
			"lumen": {"peau": "bleu_pale", "tenue": "combinaison", "crete": "cristal", "antennes": true, "bijou": "aucun", "objet": "tablette_holo"},
			"humeur_base": -0.1, "traits": {"bavard": 0.3, "humour": 0.45, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.15},
			"aime": {"cafe_brasier": 2.5, "cafe_vapeur": 2.0, "cristal_astral": 2.0, "boulon": 1.5, "cristal_soufre": 1.5, "biscuit_lunaire": 1.0}, "deteste": {"canard_mecanique": -0.5, "lunettes_kaleido": -1.0},
			"tics": ["Bzzt.", "Pfff.", "Ce n'est rien. Enfin, si.", "Grmbl."],
			"surnoms": [[0, "toi"], [25, "Pied-Lourd"], [50, "petit gars"], [75, "mon apprenti"], [95, "mon collègue"]],
			"repliques": {
				"accueil": [
					L("Bzzt. Quoi ? Un Pied-Lourd. Bon. Volt. Je m'occupe de l'énergie de la Flèche. Ne touche à rien. Surtout pas à ça. Ni à ça. Ni… bon, recule d'un pas. Voilà. Bonjour.", {"visites_max": 1}),
					L("Pfff. Encore toi. (Il grogne, mais ses antennes clignotent en bleu.) … Bon. Ça me fait plaisir. Ne le répète pas.", {"visites_min": 2}),
					L("Le Cœur bat comme au premier jour. (Il renifle.) C'est la poussière de cristal. Ça pique les yeux. Merci, petit gars. Vraiment. Grmbl.", {"a_trouve": "fleche_coeur"}),
				],
				"humeur": [
					L("Mauvaise. Comme d'habitude. Quark a encore branché son jouet sur la Flèche. Toute l'Agora a clignoté en rose pendant dix minutes. Les touristes ont applaudi. Moi non.", {}),
					L("Ce n'est rien. Le Cœur bat un peu moins fort. Ce n'est rien. … Bon, si. C'est quelque chose. Des éclats du Cœur se sont détachés. Il faudrait les retrouver. Ne le dis pas à la Doyenne. Elle le sait déjà, de toute façon.", {"q56": "as_coeur="}),
					L("La nuit des aurores, la Flèche pulse plus fort. Je reste au pied pour surveiller. Les autres regardent le ciel ; moi, je regarde les compteurs. C'est aussi joli. Pour qui sait lire.", {"soir": true}),
				],
				"lui": [
					L("Je m'occupe de la Flèche depuis six cents ans. Six cents ans à écouter le Cœur battre. Je connais tous ses bruits. Quand il bourdonne, il est content. Quand il grésille, il a froid. Quand il se tait… je ne dors plus.", {}),
					L("Les gens disent que je suis bougon. Je ne suis pas bougon. Je suis concentré. Si je souris, je perds le fil. La dernière fois que j'ai ri, la moitié du Quartier des Bulles s'est éteinte. C'était à cause d'une blague de Gloubi. Je lui en veux encore.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un secret ? Bzzt. Bon. Le soir, quand tout le monde regarde les aurores, je parle au Cœur. Tout bas. Je lui raconte la journée. Je crois qu'il écoute. Il bat un peu plus doucement après.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Flèche de Cristal, c'est cent dix mètres de cristal pur, et le Cœur tout en haut. Il fait flotter l'île, il allume les ponts de lumière, la fontaine, les dômes. Tout ce qui brille ici, c'est lui. Alors on y fait attention.", {}),
					L("Les ponts de lumière s'allument quand on s'approche. Ils détectent les pas. Les Pieds-Lourds, on les détecte de très loin. Sans vouloir te vexer.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Le Professeur Quasar m'a emprunté un cristal « pour cinq minutes ». C'était il y a quarante ans. Il dit qu'il me le rend demain. Il le dit tous les jours. Grmbl.", {}),
					L("Ionie, au Spatioport, est la seule qui sache réparer mieux que moi. Ne lui dis pas. Elle le sait. C'est pour ça que je ne le dis pas.", {}),
				],
				"interpelle": [L("Hé ! Ne touche pas à la Flèche !", {"visites_max": 0}), L("{surnom}. Bzzt. (Un petit signe.)", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ le Portail d'accueil
		{"id": "halo", "nom": "Halo", "titre": "gardien du Portail d'accueil", "maison": "porte_halo", "village": "astralys", "vouvoie": true,
			"agenda": [[6, 13, "portail_accueil"], [13, 14, "portail_belvedere"], [14, 21, "portail_accueil"], [21, 22, ["cafe_table_4", "rue_6"]], [22, 2, "portail_belvedere"], [2, 6, "maison"]],
			"azur": {"cheveux": BLANC_NACRE, "coiffure": "chauve", "yeux": Y_AZUR, "haut": BLANC_NACRE, "robe": ARGENT_C, "taille": 1.16, "carrure": 0.9},
			"lumen": {"peau": "argent", "tenue": "cape", "crete": "aucune", "antennes": true, "bijou": "halo", "objet": "baton_lumiere"},
			"humeur_base": 0.55, "traits": {"bavard": 1.0, "humour": 0.35, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"carte_postale": 2.5, "cle_ville": 2.0, "the_stellaire": 1.5, "badge_visiteur": 1.0, "partition": 1.5}, "deteste": {"vieille_botte": -1.0, "bombe_peinture": -1.0},
			"tics": ["Bienvenue !", "Je disais donc…", "Au nom du Conseil…", "Et ce n'est que le début."],
			"surnoms": [[0, "cher visiteur"], [25, "cher visiteur bienvenu"], [50, "cher ami bienvenu"], [75, "très cher ami très bienvenu"], [95, "visiteur le plus bienvenu de tous les temps"]],
			"repliques": {
				"accueil": [
					L("Bienvenue ! Bienvenue, bienvenue, cher visiteur, au nom du Conseil d'Astralys, de la Doyenne Astrée, de la Flèche de Cristal, du Cœur qui bat, des ponts de lumière qui s'allument, des dômes du Quartier des Bulles, des méduses de ciel de la Serre, des planètes de la fontaine – il y en a douze – … (Quatre minutes plus tard.) … et je suis Halo. Bienvenue.", {"visites_max": 1}, "salut"),
					L("Bienvenue de nouveau, {surnom} ! Pour un visiteur qui revient, j'ai un discours plus court. Deux minutes. (Il inspire.) Bien… Non ? Vous êtes pressé ? Bon. Bienvenue. C'était le résumé.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Rayonnante ! Hier, j'ai accueilli un goéland. Il s'est posé sur le Portail. Je lui ai fait le discours complet. Il est resté jusqu'au bout. C'est le meilleur public que j'aie eu cette année.", {}, "rire"),
					L("Un peu vexée. Écliptique dit que mon discours est trop court. Trop court ! Quatre minutes ! Je vais ajouter un paragraphe sur les dalles de nacre. Il y en a beaucoup à dire.", {}),
					L("Le soir, je vais sur le belvédère. Je regarde la bouée d'accueil tout en bas, sur la mer. Si quelqu'un y monte, je suis prêt. J'ai toujours un discours dans la poche.", {"soir": true}),
				],
				"lui": [
					L("Je garde le Portail depuis cinq cents ans. J'ai accueilli onze mille visiteurs. Neuf mille étaient des oiseaux. Mille neuf cents étaient Solenne, qui rentrait de promenade avec une fausse moustache. Et une centaine de vrais Pieds-Lourds. Vous êtes mon préféré. Je le dis à tout le monde, mais pour vous, c'est vrai.", {}, "rire"),
					L("Mon discours, je l'ai écrit le premier jour. Il faisait trente secondes : « Bienvenue, entrez, il fait beau. » Puis j'ai ajouté un mot par an. Cinq cents ans, cinq cents mots. Je ne peux plus m'arrêter. C'est devenu une tradition.", {"sujet_min": ["lui", 1]}),
					L("Mon halo, autour de la tête, s'allume tout seul quand je suis content. Quand un visiteur me dit « merci pour le discours », il brille si fort qu'on le voit depuis la mer. Ça m'est arrivé trois fois. Je m'en souviens de chacune.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le rayon d'accueil relie le Portail à la bouée, sur la mer. On monte en un souffle. Pour descendre, on revient ici et on me le demande. Poliment. Avec, si possible, un petit compliment sur le discours.", {}),
					L("Depuis le belvédère, on voit tout l'archipel : Port-Azur, la grande île de l'est, les volcans, et la Balafre, tout au sud. Sextant y vient dessiner. Il me demande de me taire. Je me tais. Presque.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Écliptique prétend que son discours est plus long que le mien. Il dure onze minutes. Mais le mien est plus dense. Chaque mot compte. Surtout « bienvenue ». Je le dis quarante fois.", {}),
					L("Glorb, le touriste, est arrivé par soucoupe, sans passer par le Portail. Il n'a pas eu de discours. Je lui en dois un. Je le poursuis depuis trois semaines.", {}, "rire"),
				],
				"interpelle": [L("Bienvenue ! Bienvenue ! Approchez, j'ai un discours !", {"visites_max": 0}, "salut"), L("{surnom} ! Bienvenue ! Encore !", {"visites_min": 1}, "salut")],
			}},
		{"id": "hologuide", "nom": "l'Hologuide", "titre": "guide holographique d'Astralys", "maison": "porte_hologuide", "village": "astralys", "vouvoie": true,
			"agenda": [[8, 18, "agora_holo", ["agora_fontaine", "musee_accueil", "fleche_base"]], [18, 22, "rue_1", ["agora_fontaine", "portail_belvedere"]], [22, 8, "maison"]],
			"azur": {"cheveux": [0.55, 0.85, 1.0], "coiffure": "court", "yeux": [0.6, 0.9, 1.0], "haut": [0.45, 0.8, 1.0], "taille": 1.0, "carrure": 0.95},
			"teinte": [0.55, 0.85, 1.0],
			"lumen": {"special": "hologramme", "objet": "aucun"},
			"humeur_base": 0.8, "traits": {"bavard": 0.9, "humour": 0.3, "curiosite": 0.1, "susceptible": 0.0, "rancunier": 0.0},
			"aime": {"carte_postale": 1.0}, "deteste": {},
			"tics": ["Bienvenue à Astralys !", "Bip.", "Veuillez suivre le guide.", "Fin de la visite. Début de la visite."],
			"surnoms": [[0, "visiteur numéro 4 812"], [25, "visiteur numéro 4 812"], [50, "visiteur favori numéro 1"], [75, "visiteur favori numéro 1"], [95, "ami. Ami ? Mot inconnu. Mot… agréable."]],
			"repliques": {
				"accueil": [
					L("Bip ! Bienvenue à Astralys, la cité de cristal et de lumière ! Je suis l'Hologuide, version trois point sept. La visite commence maintenant. Veuillez suivre le guide. Veuillez ne pas traverser le guide. Merci.", {"visites_max": 1}, "salut"),
					L("Bip ! Bienvenue à Astralys, la cité de cristal… Bip. Visage reconnu : {surnom}. Bonjour de nouveau. La visite commence maintenant. Encore. C'est la même. Elle est très bien.", {"visites_min": 2}),
				],
				"humeur": [
					L("Humeur : cent pour cent. Batterie : cent pour cent. Enthousiasme : cent quatre pour cent. Erreur. Erreur agréable.", {}),
					L("Hier, Quark est passé à travers moi quarante-deux fois. J'ai compté. C'est un record. Je l'ai ajouté à la visite : « Ici, Quark est passé à travers le guide. »", {}, "rire"),
					L("À vingt-deux heures, je passe en veille. Je rêve en mode économie. Je rêve de la visite. Elle se passe très bien.", {"soir": true}),
				],
				"lui": [
					L("Bip. Je suis un guide holographique, construit par le Professeur Quasar il y a cent douze ans. Fonction : faire la visite. Fonction secondaire : faire la visite. Fonction tertiaire : erreur, fonction introuvable.", {}),
					L("Je connais la visite par cœur. J'ai un cœur ? Non. Je connais la visite par… mémoire. Quinze étapes. Je l'ai faite deux cent quarante mille fois. Une fois, quelqu'un m'a demandé autre chose. J'ai redémarré.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Question inhabituelle détectée. Bip. Ce que je préfère ? … Analyse. … L'étape numéro onze. La fontaine. Quand la planète change, les enfants font « oh ». Je ne sais pas pourquoi j'aime ça. Je ne suis pas programmé pour aimer. Erreur agréable.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Astralys : plateau d'environ cent quatre-vingt-dix mètres de rayon, à trois cent quatre-vingts mètres au-dessus de la mer. Vingt-six habitants permanents, un touriste, et un guide. Le guide, c'est moi. Bip.", {}),
					L("Étape numéro un : la Flèche de Cristal. Étape numéro deux : l'Agora. Étape numéro trois… Voulez-vous faire la visite complète ? Elle dure quinze étapes. Vous pouvez aussi me suivre. Je la fais toute la journée.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Rumeur. Définition : information non vérifiée. Information non vérifiée disponible : « Gloubi met des étoiles dans la gelée ». Vérification impossible : Gloubi refuse de me laisser goûter. Je n'ai pas de bouche.", {}, "rire"),
					L("Bip. Écliptique m'a demandé de dire à chaque visiteur qu'il est « le plus grand orateur d'Astralys ». Information transmise. Fin de l'information.", {}, "rire"),
				],
				"interpelle": [L("Bip ! La visite commence ! Veuillez suivre le guide !", {"visites_max": 0}, "salut"), L("Bip ! {surnom} ! Visite ?", {"visites_min": 1}, "salut")],
				"cadeau_neutre": [{"t": "Bip. Objet non holographique détecté. Impossible de le tenir. Objet… archivé dans ma mémoire. Merci. C'est le cent troisième cadeau archivé.", "si": {}}],
				"cadeau_aime": [{"t": "Bip ! Une carte postale ! Image enregistrée. Ajout à la visite : « Étape seize : une carte postale d'en bas. » Erreur agréable.", "si": {}, "geste": "rire"}],
				"cadeau_deteste": [{"t": "Bip. Objet traversé. Désolé. Je suis un hologramme. Je ne peux rien garder. Sauf les souvenirs.", "si": {}}],
				"frappe": [{"t": "Bip ? Votre main est passée à travers le guide. Ce n'est pas grave. Ça chatouille. Ça chatouille ? Sensation inconnue.", "si": {}, "geste": "rire"}],
			}},
		# ================================================================ l'Agora des Étoiles
		{"id": "gloubi", "nom": "Gloubi", "titre": "cuisinier du Café Nébuleuse", "maison": "porte_gloubi", "village": "astralys",
			"agenda": [[6, 14, "cafe_comptoir"], [14, 15, "jardins_2"], [15, 23, "cafe_comptoir"], [23, 6, "maison"]],
			"azur": {"cheveux": VIOLET_PROFOND, "coiffure": "chauve", "yeux": Y_VIOLET, "haut": BLANC_NACRE, "tablier": [0.92, 0.9, 0.96], "taille": 1.0, "carrure": 1.25},
			"lumen": {"peau": "lavande", "tenue": "tunique", "crete": "aucune", "antennes": true, "bijou": "aucun", "objet": "plateau", "quatre_bras": true},
			"humeur_base": 0.75, "traits": {"bavard": 0.85, "humour": 0.95, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"bouillabaisse": 3.0, "croissant": 2.5, "tarte_potiron": 2.0, "miel": 2.0, "fromage_chevre": 1.5, "cacao": 2.0}, "deteste": {"galette_algue": -1.0, "gelee_slime": -1.5},
			"boutique": {"vend": {"the_stellaire": 2, "gelee_cosmique": 4, "biscuit_lunaire": 1}, "achete": {"pomme": 1, "baies": 1, "miel": 3, "champignon": 1, "fromage_chevre": 3, "noix_coco": 2, "cacao": 2}},
			"tics": ["Un peu plus de paillettes ?", "C'est une recette terrestre ! Enfin, presque.", "Les quatre mains à la pâte !", "Miam-miam, comme vous dites."],
			"surnoms": [[0, "petit gourmand"], [25, "mon client"], [50, "mon goûteur"], [75, "mon goûteur officiel"], [95, "mon cinquième bras"]],
			"repliques": {
				"accueil": [
					L("Bienvenue au Café Nébuleuse ! Gloubi, cuisinier ! (Il te serre la main. Puis l'autre. Puis encore la première, avec sa troisième main.) J'ai quatre bras : un pour remuer, un pour goûter, un pour servir, et un pour dire bonjour. Tu as faim ? Tu as toujours faim. Les Pieds-Lourds ont toujours faim, c'est ce que j'aime chez vous.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Assieds-toi ! Aujourd'hui, j'essaie une recette terrestre : la « crêpe ». J'ai lu qu'il fallait la faire sauter. Elle est montée jusqu'à la Flèche. On l'attend.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Délicieuse ! J'ai réussi une omelette ! Enfin, je crois. Elle est violette, elle flotte, et elle chante un peu. Mais les œufs sont dedans.", {}, "rire"),
					L("Ce matin, j'ai fait des biscuits lunaires pour tout le Conseil. Tempo est arrivé à huit heures précises, Écliptique a fait un discours sur les biscuits, et la Doyenne les a tous mangés pendant le discours.", {}, "rire"),
					L("Le soir des aurores, tout le monde vient au café. Je sers du thé stellaire avec mes quatre bras, si vite que les tasses volent toutes seules. Une fois, une tasse est restée en orbite. On la voit encore passer, le mardi.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Sur Ondelune, on mangeait des nuages pressés et de la lumière en tranches. Puis j'ai goûté une pomme terrestre. Une pomme ! Ça croque ! Ça a un goût ! Depuis, je ne cuisine que des recettes d'en bas. À ma façon. Ma façon est très… créative.", {}),
					L("Ma bouillabaisse est célèbre. Je n'ai jamais vu de poisson, alors je la fais avec des étoiles filantes et de la gelée. Solenne l'a goûtée. Elle a dit : « C'est presque ça. » Je ne sais pas comment elle sait. Elle n'est jamais allée en bas.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret, {surnom}. La gelée cosmique, la vraie, c'est la recette de ma grand-mère d'Ondelune. La seule que je n'ai pas inventée. Elle chatouille la langue. Ma grand-mère aussi chatouillait. Avec ses quatre bras. C'était la meilleure.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Café Nébuleuse est à l'ouest de l'Agora, le Bazar de Nébula à l'est. On se fait des signes par-dessus la fontaine. Avec quatre bras, je peux dire beaucoup de choses. Elle ne comprend jamais rien.", {}, "rire"),
					L("Les Jardins suspendus, c'est mon potager. Photon me laisse cueillir les fruits lumineux, à condition de leur demander la permission. Ils disent toujours oui. Ils clignotent. Je crois que c'est oui.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le Professeur Quasar a essayé de faire une soupe avec une formule mathématique. La soupe a résolu l'équation et elle est partie. On ne l'a jamais revue.", {}, "rire"),
					L("Glorb, le touriste vert, me regarde faire la gelée avec beaucoup d'inquiétude. Il demande à chaque fois : « Ce n'est pas un cousin, au moins ? » Non, Glorb. C'est des fruits. Promis.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Tu as faim ? Viens goûter !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai une nouvelle recette !", {"visites_min": 1}, "rire")],
				"boutique": [L("Thé stellaire, gelée cosmique, biscuits lunaires ! Tout est fait avec mes quatre mains. Et tu peux me donner des rondelles, si tu veux, pour faire comme en bas. Tu en as {pieces}.", {}, "rire")],
			}},
		{"id": "nebula", "nom": "Nébula", "titre": "marchande du Bazar galactique", "maison": "porte_nebula", "village": "astralys",
			"agenda": [[8, 13, "bazar_comptoir"], [13, 14, ["cafe_table_1", "cafe_table_2"]], [14, 20, "bazar_comptoir"], [20, 22, ["cafe_table_3", "cafe_table_4"]], [22, 2, ["bazar_etal_1", "bazar_etal_2"]], [2, 8, "maison"]],
			"azur": {"cheveux": OR_C, "coiffure": "chauve", "yeux": Y_OR, "haut": OR_C, "robe": VIOLET_PROFOND, "taille": 1.04, "carrure": 0.9},
			"lumen": {"peau": "or_pale", "tenue": "robe_longue", "crete": "cristal", "antennes": true, "bijou": "collier", "objet": "aucun"},
			"humeur_base": 0.6, "traits": {"bavard": 0.95, "humour": 0.8, "curiosite": 0.85, "susceptible": 0.25, "rancunier": 0.1},
			"aime": {"perle": 2.5, "rubis": 2.5, "piece_or": 2.0, "coquillage": 1.5, "fanzine": 1.5, "huile_cornes": 1.5}, "deteste": {"caillou": -0.5, "boite_a_rien": -1.0},
			"boutique": {"vend": {"toile_voile": 6, "engrenage": 6, "cristal_astral": 32, "fleur_nebuleuse": 9, "carte_postale": 2, "canard_mecanique": 12, "lunettes_kaleido": 18, "boussole_sud": 15, "coquillage": 5, "huile_cornes": 9},
				"achete": {"coquillage": 2, "vieille_botte": 3, "plume_perroquet": 2, "perle": 20, "dent_requin": 6, "carte_postale": 1, "fanzine": 2, "patch_rat": 3, "plume_corbeau": 1, "scarabee": 8}},
			"tics": ["Affaire galactique !", "Ça vient de très loin.", "Prix d'ami, prix d'étoile !", "Tu ne trouveras ça nulle part ailleurs. Enfin, si. Mais pas ici."],
			"surnoms": [[0, "client des étoiles"], [25, "bon client"], [50, "client chéri"], [75, "client de cœur"], [95, "mon client de toute la galaxie"]],
			"repliques": {
				"accueil": [
					L("Approche, approche, Pied-Lourd ! Bienvenue au Bazar galactique ! Nébula, marchande ! Ici, on trouve tout ce qui existe dans la galaxie, et un peu de ce qui n'existe pas encore. Toile à voile, engrenages, cristaux astraux, fleurs de nébuleuse… et des bricoles de tes îles à toi ! Un canard mécanique ? Il ne nage pas, mais il a voyagé.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Mon client chéri ! J'ai reçu des merveilles ! Enfin, j'ai reçu un caillou, mais il vient d'une planète où les cailloux chantent. Celui-là ne chante pas. Il est timide.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Galactique ! J'ai vendu trois fleurs de nébuleuse ce matin, et Orbe m'a acheté une vieille botte pour son Musée. Une botte ! Il a pleuré de joie. Moi aussi, mais pour d'autres raisons.", {}, "rire"),
					L("Un peu perplexe. Les Pieds-Lourds me donnent des pièces en échange des objets. Moi, je les mets dans un bocal. Le bocal est plein. Que fait-on avec un bocal plein de pièces ? Un deuxième bocal ?", {}),
					L("Le soir des aurores, je laisse le Bazar ouvert. Les fleurs de nébuleuse s'ouvrent quand le ciel s'allume. Tout le monde veut en acheter une. Je les vends très cher. Enfin, je crois. Je ne sais toujours pas ce qui est cher.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Sur Ondelune, on ne vendait rien : on échangeait. Une chanson contre un fruit, un sourire contre un chapeau. Ici, avec les Pieds-Lourds, j'ai découvert « l'argent ». J'ai adoré le mot. J'ai ouvert un bazar pour pouvoir le dire toute la journée.", {}),
					L("Mes marchandises viennent de partout : de la galaxie, par les soucoupes de passage, et des îles d'en bas, par… des voies mystérieuses. (Elle regarde Solenne, au loin, qui sifflote.) Très mystérieuses.", {"sujet_min": ["lui", 1]}, "rire"),
					L("La vérité, {surnom}, c'est que je n'aime pas vendre. J'aime raconter d'où viennent les choses. Chaque objet a fait un voyage. Le vendre, c'est lui en offrir un autre. Le prix ? C'est juste pour que tu y fasses attention.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Bazar galactique est à l'est de l'Agora, face au Café de Gloubi. Entre nous deux, la fontaine. Les planètes y tournent toutes les minutes. Je règle mes prix sur la planète du moment. Ne le dis pas.", {}, "rire"),
					L("Si tu cherches des cristaux astraux moins chers, va voir Ionie au Spatioport. Elle les sort de sous l'île avec ses outils. Moi, je les vends plus cher, mais je les emballe dans du papier d'étoile.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Orbe, du Musée, a payé une vieille botte trois fois le prix d'un cristal astral. Je lui ai dit que c'était trop. Il a insisté. Il a dit que c'était « une botte qui a marché sur la Terre ». Toutes les bottes ont marché sur la Terre, Orbe !", {}, "rire"),
					L("Glorb, le touriste, a acheté vingt cartes postales d'Astralys. Il en a envoyé dix-neuf à sa mère, sur la planète Gloop. La vingtième, il l'a mangée. Par erreur. Je crois.", {}, "rire"),
				],
				"interpelle": [L("Affaire galactique ! Approche !", {"visites_max": 0}, "salut"), L("{surnom} ! J'ai du nouveau !", {"visites_min": 1}, "rire")],
				"boutique": [L("Toile, engrenages, cristaux, fleurs, et des trésors de tes îles ! Le cristal astral est cher : il vient d'un endroit difficile. Le canard, lui, vient de Cliquetis. C'est aussi un endroit difficile. Tu as {pieces} rondelles.", {}, "rire")],
			}},
		{"id": "vibrato", "nom": "Vibrato", "titre": "musicien au thérémine", "maison": "porte_vibrato", "village": "astralys",
			"agenda": [[10, 13, "apesanteur_1"], [13, 15, ["cafe_table_4", "cafe_table_2"]], [15, 19, ["agora_banc_1", "rue_2"]], [19, 22, ["cafe_table_4", "agora_banc_2"]], [22, 2, "agora_fontaine"], [2, 10, "maison"]],
			"azur": {"cheveux": ARGENT_C, "coiffure": "chauve", "yeux": Y_ARGENT, "haut": BLEU_NUIT, "robe": ARGENT_C, "taille": 1.12, "carrure": 0.78},
			"lumen": {"peau": "argent", "tenue": "cape", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "theremine"},
			"humeur_base": 0.5, "traits": {"bavard": 0.5, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.45, "rancunier": 0.05},
			"aime": {"partition": 3.0, "caillou_chantant": 2.5, "affiche_concert": 2.0, "sifflet_muet": 1.5, "the_stellaire": 1.5, "patch_rat": 1.5}, "deteste": {"grelot_tanuki": -0.5, "des_pipes": -0.5},
			"tics": ["Ouuuuuh…", "Écoute.", "C'est en la mineur.", "(Ses antennes vibrent doucement.)"],
			"surnoms": [[0, "auditeur"], [25, "mon auditeur"], [50, "mon public"], [75, "mon meilleur public"], [95, "ma note préférée"]],
			"repliques": {
				"accueil": [
					L("Ouuuuuh… Pardon. Bonjour. Vibrato, musicien. Ça, c'est un thérémine : on en joue sans le toucher, juste en bougeant les mains dans l'air. Ça fait « ouuuuuh ». Toute la musique d'Ondelune fait « ouuuuuh ». Ici, j'ai appris qu'on pouvait aussi faire « tsoin-tsoin ». Je travaille dessus.", {"visites_max": 1}, "salut"),
					L("{surnom}. Écoute. (Il fait bouger ses mains : un son très doux, comme une baleine qui rêve.) C'est ta chanson. Je l'ai composée hier. Elle s'appelle « Le Pied-Lourd qui revient ».", {"visites_min": 2}),
				],
				"humeur": [
					L("Vibrante. J'ai joué dans le Jardin des Apesanteurs ce matin. Là-bas, les notes flottent plus longtemps. Une est restée en l'air jusqu'à midi. Photon dit que ses fleurs ont dansé.", {}),
					L("Tracassé. J'ai entendu parler d'une musique d'en bas, très forte, avec des gens qui sautent. Le « pogo ». J'ai essayé de faire un pogo au thérémine. Ça fait « ouuuuuh » en sautant. Ce n'est pas pareil.", {}, "rire"),
					L("Ce soir, nuit des aurores. Je joue sur l'Agora, devant la fontaine, et Prisme danse. Les aurores suivent la musique. Ou la musique suit les aurores. On ne sait jamais qui commence.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, j'étais accordeur de vents. On accordait les tempêtes pour qu'elles soufflent juste. Ici, les vents sont désaccordés et personne ne s'en plaint. Alors j'ai pris un thérémine, pour avoir quelque chose à accorder.", {}),
					L("Mes antennes vibrent quand j'entends une belle note. Quand Prisme danse, elles vibrent tout le temps. Lyre dit que c'est de l'amour. Lyre dit ça en vers, alors on ne sait jamais si c'est vrai ou si c'était juste pour la rime.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Une fois, j'ai entendu monter une musique d'en bas, par une nuit très calme : une guitare, quelqu'un qui chantait faux, des rires. C'était peut-être un pêcheur. J'ai joué en même temps que lui, tout doucement. Il n'a jamais su qu'il avait fait un duo.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La fontaine de l'Agora joue une note différente pour chaque planète. Ondelune fait « ouuuh », Saturne fait « boum », et la Terre fait… « tchic ». C'est la meilleure.", {}),
					L("Pendant la Nuit des Aurores, de vingt-deux heures à deux heures, toute l'île écoute. Même Volt. Il fait semblant de regarder ses compteurs, mais il tape du pied. Je le vois.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Murmure, la bibliothécaire, m'a demandé de jouer plus bas. Je joue déjà sans toucher l'instrument. Je ne peux pas jouer plus bas sans jouer… rien. J'ai essayé. Elle a dit « parfait ».", {}, "rire"),
					L("Quark a caché un grelot dans mon thérémine. Ça fait « ouuuh-ding ». J'ai gardé le grelot. C'est devenu mon morceau le plus populaire.", {}, "rire"),
				],
				"interpelle": [L("Ouuuuuh… Bonjour !", {"visites_max": 0}, "salut"), L("{surnom}. Écoute ça.", {"visites_min": 1}, "rire")],
			}},
		{"id": "prisme", "nom": "Prisme", "titre": "danseuse de lumière", "maison": "porte_prisme", "village": "astralys",
			"agenda": [[10, 13, "apesanteur_2"], [13, 14, ["cafe_table_1", "cafe_table_4"]], [14, 18, ["jardins_1", "agora_banc_2"]], [18, 20, "agora_holo"], [20, 22, ["cafe_table_2", "rue_1"]], [22, 2, "agora_holo"], [2, 10, "maison"]],
			"azur": {"cheveux": ROSE_C, "coiffure": "chauve", "yeux": Y_ROSE, "haut": ROSE_C, "robe": OR_C, "taille": 1.1, "carrure": 0.75},
			"lumen": {"peau": "or_pale", "tenue": "robe_longue", "crete": "cristal", "antennes": true, "bijou": "halo", "objet": "aucun"},
			"humeur_base": 0.7, "traits": {"bavard": 0.6, "humour": 0.7, "curiosite": 0.75, "susceptible": 0.35, "rancunier": 0.0},
			"aime": {"fleur_nebuleuse": 2.5, "glace": 2.0, "lunettes_kaleido": 2.5, "plume_ara": 2.0, "the_stellaire": 1.5}, "deteste": {"vieille_botte": -1.0, "buche": -0.5},
			"tics": ["Et un, et deux…", "Pointe !", "Tourne, tourne…", "(Elle fait une petite pirouette sans s'en rendre compte.)"],
			"surnoms": [[0, "spectateur"], [25, "mon spectateur"], [50, "mon partenaire"], [75, "mon partenaire de lumière"], [95, "mon étoile de danse"]],
			"repliques": {
				"accueil": [
					L("Oh ! Bonjour ! (Elle fait une pirouette, et des rubans de lumière tournent autour d'elle.) Prisme, danseuse de lumière ! Quand je danse, la lumière me suit. Quand je m'arrête, elle continue un peu, parce qu'elle n'a pas fini. Tu viendras me voir, ce soir ? Je danse sur l'Agora quand les aurores arrivent.", {"visites_max": 1}, "salut"),
					L("{surnom} ! (Pirouette.) Pardon, c'est nerveux. Tu as vu les aurores, hier ? J'ai dansé en violet. Les aurores ont fait du violet aussi. On est d'accord, elles et moi.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Légère ! Comme dans le Jardin des Apesanteurs. Ce matin, j'ai sauté si haut que j'ai dit bonjour à une méduse de ciel. Elle a rougi. Les méduses rougissent en bleu.", {}, "rire"),
					L("Un peu raide. Hier, Écliptique a voulu danser avec moi. Il m'a marché sur les pieds trente-deux fois. Il a fait un discours d'excuse de six minutes. J'ai eu le temps de me reposer.", {}, "rire"),
					L("Ce soir, les aurores ! Vibrato joue, je danse, le ciel s'allume. Si tu bouges les bras sur l'Agora, la lumière te suivra aussi. Essaie. Personne ne regarde. Enfin, tout le monde regarde. Mais gentiment.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, la lumière était lourde, épaisse, on pouvait s'appuyer dessus. Ici, elle est légère. La première fois que j'ai tendu la main, elle a glissé entre mes doigts. Je l'ai poursuivie. Je n'ai jamais arrêté. C'est ça, danser.", {}),
					L("J'ai appris une danse d'en bas. Solenne me l'a montrée. Elle s'appelle « la gigue ». On saute, on tape des pieds, on tourne. Solenne dit qu'elle l'a apprise dans un livre. Il y avait de la sciure sur ses chaussures.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un secret ? Je danse mieux quand Vibrato joue. Ses antennes vibrent, ma lumière tremble, et tout devient facile. Mais je ne le lui ai jamais dit. Les danseurs parlent avec les pieds. Et mes pieds sont très timides.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'hologramme de l'Agora, à côté de la fontaine, c'est ma scène. La journée, l'Hologuide s'en sert pour sa visite. Le soir, elle est à moi. On ne s'est jamais disputés. Il ne dort jamais, et moi, je ne me lève jamais avant dix heures.", {}, "rire"),
					L("Le Jardin des Apesanteurs, au bout du pont de lumière, à l'ouest : c'est là que je répète. On saute trois fois plus haut et on retombe tout doucement. Pour une danseuse, c'est le paradis. Pour un Pied-Lourd, c'est très drôle. Surtout à l'atterrissage.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Comète a fait la course avec une étoile filante. Elle dit qu'elle a gagné. L'étoile filante n'a pas fait de commentaire.", {}, "rire"),
					L("Lyre écrit un poème sur ma danse depuis deux cents ans. Elle cherche une rime à « Prisme ». Elle n'en a trouvé qu'une : « Prisme ». Elle trouve que c'est de la triche.", {}, "rire"),
				],
				"interpelle": [L("Hé ! (Pirouette.) Bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Tu danses ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "lyre", "nom": "Lyre", "titre": "poétesse", "maison": "porte_lyre", "village": "astralys",
			"agenda": [[9, 12, "jardins_bassin"], [12, 13, ["cafe_table_2", "cafe_table_3"]], [13, 17, ["musee_salle_2", "observatoire_pont", "agora_banc_2"]], [17, 20, ["cafe_table_3", "agora_banc_3"]], [20, 22, "agora_banc_3"], [22, 2, "agora_banc_2"], [2, 9, "maison"]],
			"azur": {"cheveux": VIOLET_PROFOND, "coiffure": "chauve", "yeux": Y_VIOLET, "haut": VIOLET_PROFOND, "robe": ARGENT_C, "taille": 1.06, "carrure": 0.78},
			"lumen": {"peau": "lavande", "tenue": "robe_longue", "crete": "filaments", "antennes": true, "bijou": "diademe", "objet": "livre"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.7, "susceptible": 0.5, "rancunier": 0.05},
			"aime": {"partition": 2.5, "fleur_nebuleuse": 2.5, "plume_corbeau": 2.0, "chouette_plume": 2.0, "the_stellaire": 1.5, "fleur_lune": 1.5}, "deteste": {"chapeau_ventilateur": -1.0, "vieille_botte": -0.5},
			"tics": ["Hélas, pas de rime…", "Ô !", "Rime avec… euh…", "(Elle compte les syllabes sur ses doigts.)"],
			"surnoms": [[0, "passant charmant"], [25, "lecteur fidèle"], [50, "ami des vers"], [75, "muse à pieds lourds"], [95, "ma muse, ma rime, mon tout"]],
			"repliques": {
				"accueil": [
					L("Ô visiteur venu d'en bas, bienvenue sous nos cieux ! Je m'appelle Lyre, et je parle… en vers… quand je peux. (Elle compte sur ses doigts.) La dernière rime était ratée. Je reprends : je suis Lyre, la poétesse, et je rime avec tendresse.", {"visites_max": 1}, "salut"),
					L("Ô {surnom}, te revoilà, comme la lune au bord du soir ! Assieds-toi là, près de Lyre, j'ai un poème à te faire voir. … Entendre. Faire entendre. « Voir » rimait mieux.", {"visites_min": 2}, "rire"),
					L("Le Cœur bat de nouveau là-haut, comme un tambour dans le cristal ; et c'est grâce à toi, mon héros… à toi, euh… le Pied-Lourd… génial. Pardon. L'émotion m'a coupé la rime.", {"a_trouve": "fleche_coeur"}, "rire"),
				],
				"humeur": [
					L("Je suis heureuse comme un astre qui a trouvé sa constellation. Ce matin, j'ai écrit quatre vers et demi, sans aucune rime ratée. Le demi, c'était « Bonjour ». Il rimait avec rien.", {}, "rire"),
					L("Je suis triste comme une comète qui a perdu sa queue en route. Je cherche une rime à « Astralys ». « Malice » ? « Réglisse » ? « Ça glisse » ? Rien ne va. Je vais l'appeler autrement. En poésie, j'ai le droit.", {}),
					L("Le soir tombe, les aurores viennent, Vibrato joue, Prisme danse ; et moi, sur mon banc, j'écris ; et rien ne rime. Mais c'est beau. Ça compense.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, on ne parlait qu'en musique. En arrivant ici, j'ai découvert les mots des Pieds-Lourds, et surtout les rimes. Deux mots qui finissent pareil ! Quelle idée merveilleuse ! J'ai décidé de ne plus parler qu'en vers. C'était il y a neuf cents ans. Ça se passe… moyennement.", {}, "rire"),
					L("J'ai écrit douze mille poèmes. Onze mille parlent du ciel. Neuf cents parlent de la mer. Et cent parlent de Gloubi, parce que « Gloubi » rime avec « souris », « tapis » et « petit-déjeuner servi ». C'est très pratique.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Mon plus beau poème n'a pas de rime du tout. Je l'ai écrit le jour où nous avons compris que nous ne rentrerions jamais sur Ondelune. Il fait une ligne : « Ici aussi, il y a des étoiles. » Je ne l'ai jamais lu à personne. Sauf à toi.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Sur le plateau flotte une île, et sur l'île, une cité ; dans la cité, une fontaine, où les planètes vont tourner. … Bon, le dernier vers boite un peu. Mais la fontaine, elle, tourne très bien.", {}),
					L("Le bassin des Jardins suspendus, au matin, c'est là que j'écris. L'eau brille, les fleurs clignotent, et les rimes viennent… ou pas. Le plus souvent, pas. Mais l'eau brille quand même.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("On dit que Murmure, la discrète, chuchote si bas qu'on l'entend à peine ; un jour, elle a crié « coucou ! » … et trois dômes ont perdu leur peine. … Leur verre. Ils ont perdu leur verre. Ça ne rimait pas.", {}, "rire"),
					L("Écliptique m'a demandé un poème pour un discours officiel. Je lui ai écrit : « Écliptique, magnifique, protocole, cabriole. » Il l'a fait encadrer. Il n'a pas compris que c'était une blague. Ne le lui dis pas.", {}, "rire"),
				],
				"interpelle": [L("Ô passant ! Viens par ici ! … Ça ne rime pas. Viens quand même !", {"visites_max": 0}, "salut"), L("Ô {surnom}, mon ami !", {"visites_min": 1}, "rire")],
			}},
		{"id": "glorb", "nom": "Glorb", "titre": "touriste de la planète Gloop", "maison": "porte_glorb", "village": "astralys",
			"agenda": [[9, 12, ["musee_salle_1", "agora_fontaine", "rue_3", "rue_4"]], [12, 14, ["cafe_table_1", "cafe_table_2", "cafe_table_3", "cafe_table_4"]], [14, 18, ["observatoire_pont", "jardins_bassin", "serre_2", "spatioport_aire_2", "portail_belvedere"]], [18, 22, ["bazar_etal_1", "bazar_etal_2", "rue_4", "agora_banc_3"]], [22, 2, ["cafe_table_3", "cafe_table_4", "rue_1"]], [2, 9, "maison"]],
			"azur": {"cheveux": [0.35, 0.85, 0.3], "coiffure": "chauve", "yeux": [0.1, 0.1, 0.1], "haut": [0.95, 0.6, 0.85], "taille": 0.82, "carrure": 1.35},
			"teinte": [0.38, 0.86, 0.32],
			"lumen": {"special": "glorb", "objet": "appareil_holo"},
			"humeur_base": 0.85, "traits": {"bavard": 0.9, "humour": 0.9, "curiosite": 1.0, "susceptible": 0.15, "rancunier": 0.0},
			"aime": {"appareil_photo": 3.0, "carte_postale": 3.0, "gelee_slime": 2.5, "glace": 2.0, "lunettes_kaleido": 2.0, "badge_visiteur": 1.5}, "deteste": {"gelee_cosmique": -2.0, "piment_infernal": -1.0},
			"tics": ["Blorp !", "Clic-clic !", "Souvenir !", "(Il tremblote de joie.)"],
			"surnoms": [[0, "autochtone"], [25, "autochtone sympathique"], [50, "copain de voyage"], [75, "meilleur copain de voyage"], [95, "frère de gelée"]],
			"repliques": {
				"accueil": [
					L("Blorp ! Un Pied-Lourd ! Un vrai ! Ne bouge pas ! (Clic-clic ! Il te prend en photo sous tous les angles, en tremblotant de joie.) Glorb ! Touriste ! Planète Gloop, troisième lune à gauche ! Je fais le tour de la galaxie, et je prends TOUT en photo. Tu veux être sur ma carte postale ? Tu es déjà dessus. Clic !", {"visites_max": 1}, "salut"),
					L("Blorp ! {surnom} ! Mon autochtone préféré ! (Clic-clic.) Celle-là, c'est pour maman. Elle collectionne les Pieds-Lourds. En photo, hein ! En photo.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Blorp-blorp ! Merveilleuse ! J'ai pris quatre mille photos aujourd'hui. Trois mille neuf cents sont de la fontaine. Elle change de planète toutes les minutes ! Il faut tout photographier ! C'est épuisant ! J'adore !", {}, "rire"),
					L("Un peu tremblotant. Gloubi fait de la gelée, au café. Je lui ai demandé si ce n'était pas de la famille. Il dit que non. Mais elle tremble comme mon oncle Blurp. Je ne la mange pas. Par respect.", {}),
					L("La nuit des aurores ! Le ciel change de couleur, et moi aussi ! Regarde : je deviens rose quand le ciel est rose ! Prends-moi en photo ! Non, attends, c'est moi qui prends les photos. Blorp.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Sur Gloop, on est tous gélatineux et verts. On tremblote quand on est contents, on fond un peu quand on est tristes, et on rebondit quand on est très contents. Sur Gloop, il n'y a rien à photographier : tout le monde est pareil. Alors je voyage.", {}),
					L("J'ai visité trois cent douze planètes. Ma préférée ? Celle-ci. Il y a des Pieds-Lourds, des Lumens, des îles, de la mer… La mer ! De l'eau qui bouge toute seule ! Comme moi, mais en grand ! Je l'ai photographiée onze mille fois.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un secret, {surnom}. Toutes mes photos, je les envoie à ma maman, sur Gloop. Elle ne peut pas voyager : elle est trop molle, maintenant. Alors je voyage pour elle. Chaque photo, c'est un bisou. Clic. Voilà. Tu es un bisou pour ma maman.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Astralys ! Quatre étoiles dans mon guide ! « Île flottante, habitants lumineux, gelée suspecte au café. » Le guide déconseille la gelée. Je suis d'accord avec le guide.", {}, "rire"),
					L("J'aimerais tellement photographier les îles d'en bas ! Port-Azur, la Balafre, Montjoie, Port-Boucan… Mais je suis un peu… gluant. Les gens d'en bas risquent de crier. Ou de me mettre dans un pot.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Halo me poursuit depuis trois semaines pour me faire un discours de bienvenue. Je me cache. Je suis vert, il y a beaucoup de plantes vertes dans les Jardins. C'est le camouflage parfait. Blorp.", {}, "rire"),
					L("J'ai pris Écliptique en photo pendant qu'il tombait de l'estrade. C'est ma meilleure photo de toute la galaxie. Je l'ai envoyée à maman. Elle a rebondi de rire. Elle n'avait pas rebondi depuis cent ans.", {}, "rire"),
				],
				"interpelle": [L("Blorp ! Ne bouge pas ! Clic !", {"visites_max": 0}, "rire"), L("{surnom} ! Photo !", {"visites_min": 1}, "rire")],
				"cadeau_aime": [{"t": "BLORP ! {dernier_cadeau} ! Pour moi ? (Il tremblote si fort qu'il rebondit trois fois.) Je le prends en photo ! Clic ! Maman va adorer !", "si": {}, "geste": "rire"}],
				"cadeau_deteste": [{"t": "Blorp… (Il devient tout pâle.) C'est… c'est de la gelée ? Tu me donnes… un cousin ? Non merci. Non. Non, non, non.", "si": {}, "humeur": -0.2}],
				"frappe": [{"t": "Blorp ! (Ta main s'enfonce dans sa gelée, puis ressort avec un « plop ».) Hé ! Sur Gloop, c'est une façon très impolie de dire bonjour ! Et ça colle !", "si": {}, "geste": "colere", "humeur": -0.3}],
			}},
		# ================================================================ le Musée, l'Académie, l'Observatoire
		{"id": "orbe", "nom": "Orbe", "titre": "Archiviste du Musée des Mondes", "maison": "porte_orbe", "village": "astralys",
			"agenda": [[8, 12, "musee_accueil"], [12, 13, ["cafe_table_3", "cafe_table_2"]], [13, 19, ["musee_salle_1", "musee_salle_2"]], [19, 22, ["bazar_etal_1", "bazar_etal_2"]], [22, 2, ["cafe_table_1", "cafe_table_2"]], [2, 8, "maison"]],
			"azur": {"cheveux": VIOLET_PROFOND, "coiffure": "chauve", "yeux": Y_VIOLET, "haut": VIOLET_PROFOND, "robe": BLANC_NACRE, "taille": 1.08, "carrure": 0.9, "lunettes": true},
			"lumen": {"peau": "lavande", "tenue": "toge", "crete": "cristal", "antennes": true, "bijou": "collier", "objet": "tablette_holo"},
			"humeur_base": 0.65, "traits": {"bavard": 0.95, "humour": 0.6, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"vieille_botte": 3.0, "carte_postale": 2.5, "canard_mecanique": 2.5, "coquillage": 2.0, "patch_rat": 2.0, "boussole": 1.5, "des_pipes": 2.0}, "deteste": {"gelee_cosmique": -0.5, "biscuit_lunaire": -0.5},
			"tics": ["Fascinant !", "Pour le Musée !", "Ça s'appelle comment, ça ?", "(Il prend des notes sur sa tablette, très vite.)"],
			"surnoms": [[0, "spécimen"], [25, "spécimen sympathique"], [50, "cher collègue"], [75, "cher fournisseur"], [95, "pièce maîtresse de ma collection (c'est affectueux)"]],
			"repliques": {
				"accueil": [
					L("Un Pied-Lourd ! Un vrai ! Ne bougez pas… (Il tourne autour de toi en prenant des notes.) Deux bras, deux jambes, des chaussures… Fascinant ! Orbe, Archiviste du Musée des Mondes. J'expose des objets de toutes les îles de l'archipel. Dites-moi : ce que vous portez aux pieds, ça s'appelle comment ? « Bottes » ? « Chaussures » ? Les deux ? Fascinant !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous avez quelque chose pour le Musée ? Un caillou, une plume, une chaussette ? Surtout une chaussette. La mienne est seule, la pauvre.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Fascinante ! J'ai enfin compris à quoi sert une « fourchette ». C'est pour peigner les spaghettis. Gloubi dit que non. Gloubi n'est pas archiviste.", {}, "rire"),
					L("Frustré. La vitrine des îles est presque vide. Il me manque un coquillage, une plume de perroquet, un scarabée du désert, un patch de ces punks bruyants et un navet doré de Montjoie. Vous voyagez beaucoup, vous, non ?", {"q56": "as_musee="}),
					L("Le soir, je vais au Bazar de Nébula voir les nouveautés. Hier, elle avait une « passoire ». Un bol plein de trous ! Pour quoi faire ? Pour retenir l'eau, sûrement. Je l'ai achetée. Elle fuit. Je l'étudie.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Depuis que nous sommes arrivés, il y a mille ans, je collectionne tout ce qui tombe d'en bas. Enfin, tout ce qui monte. Les oiseaux en apportent, le vent aussi, et Solenne, parfois, dans ses valises. Elle dit qu'elle les trouve « dans le ciel ». Le ciel est très bien rangé.", {}),
					L("Ma pièce préférée ? Une vieille botte. Elle a marché sur la Terre ! Pendant des années ! Elle a vu des routes, des flaques, des chemins de montagne ! Nébula dit que toutes les bottes ont fait ça. C'est justement ce qui est merveilleux.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous avouer une chose. Je n'ai jamais osé descendre en bas. J'ai peur de… de trop aimer. Si je voyais tout ça en vrai, je ne pourrais plus jamais repartir. Alors je reste ici, avec mes vitrines. Elles, au moins, ne me demandent pas de choisir.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Musée des Mondes est à l'ouest de l'Agora. Salle un : les objets d'Ondelune. Salle deux : les objets des îles d'en bas. La salle deux est beaucoup plus intéressante. Ne le dites pas à la Doyenne : la salle un, c'est sa jeunesse.", {}),
					L("Dans la salle deux, il y a une cuillère, un tricorne, un fer à cheval, une partition et une dent de requin. Ils sont tous étiquetés. Les étiquettes sont fausses, je pense. La cuillère est étiquetée « petite pelle à soupe ». C'est sûrement ça.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Glorb, le touriste, a voulu prendre en photo ma vieille botte. Il a été si ému qu'il a coulé un peu sur la vitrine. J'ai mis une étiquette : « Trace de touriste, planète Gloop ». C'est devenu une pièce de la collection.", {}, "rire"),
					L("Nébula m'a vendu une boîte « qui ne contient rien ». Très cher. Je l'ai ouverte. Elle ne contenait rien. Elle disait vrai ! C'est la première fois qu'on me vend exactement ce qui est écrit.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Ne bougez pas ! Fascinant !", {"visites_max": 0}, "salut"), L("{surnom} ! Quelque chose pour le Musée ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "quasar", "nom": "Professeur Quasar", "titre": "savant de l'Académie des Sciences", "maison": "porte_quasar", "village": "astralys",
			"agenda": [[7, 9, "academie_labo_1"], [9, 12, "academie_tableau"], [12, 13, ["cafe_table_4", "rue_2"]], [13, 1, "academie_labo_1"], [1, 7, "maison"]],
			"azur": {"cheveux": BLANC_NACRE, "coiffure": "chauve", "yeux": Y_AZUR, "haut": BLANC_NACRE, "robe": GRIS_PERLE, "taille": 1.04, "carrure": 0.85, "lunettes": true, "vieux": true},
			"lumen": {"peau": "bleu_pale", "tenue": "tunique", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "tablette_holo"},
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.25, "rancunier": 0.0},
			"aime": {"engrenage": 2.5, "montre_envers": 2.5, "cafe_vapeur": 2.0, "ressort": 2.0, "boulon": 1.5, "chapeau_ventilateur": 2.0}, "deteste": {"boite_a_rien": -1.0, "tisane_lune": -0.5},
			"tics": ["Eurêka ! Ah, non.", "Théoriquement…", "Ça ne devait pas faire ça.", "(Un petit nuage de fumée sort de ses antennes.)"],
			"surnoms": [[0, "jeune cobaye"], [25, "jeune assistant"], [50, "cher assistant"], [75, "cher collègue"], [95, "cher génie (après moi)"]],
			"repliques": {
				"accueil": [
					L("Eurêka ! Un sujet d'étude ! Euh, je veux dire : bonjour. Professeur Quasar, de l'Académie des Sciences. Ne faites pas attention à la fumée, c'est normal. Ou pas. Théoriquement, c'est normal. En pratique, je vais ouvrir une fenêtre.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tombez à pic ! J'ai besoin de quelqu'un pour tenir ce bocal. Il ne va pas exploser. Théoriquement. Tenez-le un peu plus loin. Encore. Voilà.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Excellente ! Mon expérience de ce matin a raté. Brillamment ! Je voulais transformer la lumière en confiture. J'ai obtenu de la confiture qui brille. C'est presque pareil.", {}, "rire"),
					L("Contrarié. J'ai fait exploser le labo, et une puce holographique a volé par la fenêtre. Sans elle, Ionie ne peut pas finir la navigation du glisseur. Elle doit être quelque part dans l'Académie. Ou dans le ciel.", {"q56": "as_glisseur=en_cours"}),
					L("Le soir, je reste au labo. Les aurores ? Je les étudie par la fenêtre. Théoriquement, je pourrais aller les voir. Mais j'ai une expérience sur le feu. Il y a toujours une expérience sur le feu.", {"soir": true}),
				],
				"lui": [
					L("J'ai inventé l'Hologuide, les ponts de lumière, la fontaine des planètes et le grille-pain gravitationnel. Le grille-pain gravitationnel, on ne le retrouve plus. Il est parti vers le haut avec les tartines. Un jour, il redescendra.", {}, "rire"),
					L("Mes expériences ratent souvent. Mais une expérience ratée, c'est une expérience qui a trouvé autre chose. J'ai voulu fabriquer de la pluie : j'ai fait des bulles. Bulle, l'architecte, en a fait le Quartier des Bulles. Vous voyez ? Rien ne se perd.", {"sujet_min": ["lui", 1]}),
					L("Je vais vous dire mon rêve secret. Une machine pour rentrer sur Ondelune. Je la construis depuis neuf cents ans. Elle est presque finie. Mais chaque fois qu'elle est presque finie, je pense à Astralys, aux aurores, à mes étudiants… et je dévisse une pièce. Théoriquement, c'est un accident.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Académie des Sciences est à l'est de l'Agora. Laboratoires, salle de cours, et le grand tableau où les équations flottent. Si une équation vous tombe sur la tête, ne vous inquiétez pas : elles sont légères. Sauf les longues divisions.", {}, "rire"),
					L("Le Jardin des Apesanteurs, c'est moi aussi. Une expérience sur la gravité. Elle a raté : la gravité ne marche plus qu'à un tiers. Mais tout le monde adore, alors on dit que c'était voulu.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Volt prétend que je lui ai emprunté un cristal il y a quarante ans. C'est faux. C'était il y a trente-neuf ans et demi. Je le lui rends demain. Théoriquement.", {}, "rire"),
					L("Murmure, la bibliothécaire, a rangé mes notes par ordre alphabétique. Toutes mes équations commencent maintenant par « A ». Je ne retrouve plus rien. C'est très bien rangé.", {}, "rire"),
				],
				"interpelle": [L("Vous ! Un sujet d'étude ! Euh… bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Vous tenez un bocal ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "murmure", "nom": "Murmure", "titre": "bibliothécaire de l'Académie", "maison": "porte_murmure", "village": "astralys",
			"agenda": [[8, 12, "academie_labo_2"], [12, 13, ["cafe_table_4", "jardins_bassin"]], [13, 19, "academie_labo_2"], [19, 22, "maison"], [22, 0, "jardins_1"], [0, 8, "maison"]],
			"azur": {"cheveux": BLEU_NUIT, "coiffure": "chauve", "yeux": Y_AZUR, "haut": BLEU_NUIT, "robe": GRIS_PERLE, "taille": 1.0, "carrure": 0.75, "lunettes": true},
			"lumen": {"peau": "bleu_pale", "tenue": "robe_longue", "crete": "filaments", "antennes": true, "bijou": "collier", "objet": "livre"},
			"humeur_base": 0.45, "traits": {"bavard": 0.35, "humour": 0.6, "curiosite": 0.8, "susceptible": 0.4, "rancunier": 0.05},
			"aime": {"papyrus_thot": 3.0, "grimoire": 2.5, "chouette_plume": 2.0, "sifflet_muet": 2.0, "the_menthe": 1.5, "fanzine": 1.0}, "deteste": {"des_pipes": -0.5, "affiche_concert": -1.0},
			"tics": ["(chuchoté) Chut…", "(chuchoté) …tout doucement.", "(chuchoté) Oh.", "(Elle met un doigt devant sa bouche.)"],
			"surnoms": [[0, "(chuchoté) lecteur"], [25, "(chuchoté) petit lecteur"], [50, "(chuchoté) cher lecteur"], [75, "(chuchoté) lecteur adoré"], [95, "(chuchoté) mon livre préféré"]],
			"repliques": {
				"accueil": [
					L("(Elle chuchote.) Bonjour… Murmure… bibliothécaire de l'Académie… Bienvenue dans la bibliothèque… Ici, on parle tout bas… Même les livres… Surtout les livres… Ils sont très sensibles.", {"visites_max": 1}, "salut"),
					L("(chuchoté) {surnom}… Te revoilà… J'ai mis de côté un livre pour toi… Il parle d'un Pied-Lourd qui monte au ciel… Il finit bien… Enfin, je crois… Je n'ai pas lu la fin… Je voulais la lire avec toi.", {"visites_min": 2}),
				],
				"humeur": [
					L("(chuchoté) Bien… très bien, même… Ce matin, personne n'a fait de bruit… Sauf Quasar… Il a fait exploser quelque chose… Tout doucement… Il fait des efforts.", {}, "rire"),
					L("(chuchoté) Un peu agacée… Vibrato a joué du thérémine sous ma fenêtre… Il dit qu'il jouait « tout bas »… Le thérémine ne joue jamais tout bas… Il fait « ouuuh »… Même les livres ont frissonné.", {}),
					L("(chuchoté) Le soir des aurores, je vais dans les Jardins… loin de l'Agora… Je les regarde en silence… Le ciel ne fait aucun bruit… C'est ce que je préfère chez lui.", {"soir": true}),
				],
				"lui": [
					L("(chuchoté) Sur Ondelune, j'avais une voix très forte… La plus forte du village… Un jour, j'ai éternué… et une montagne s'est fendue… Depuis, je chuchote… Par précaution… Il y a des montagnes partout.", {}, "rire"),
					L("(chuchoté) La bibliothèque a cent mille livres… Quatre-vingt-dix mille d'Ondelune, en lumière… Dix mille d'en bas, en papier… Les livres en papier sentent bon… Je les respire en cachette… Ne le dis à personne.", {"sujet_min": ["lui", 1]}),
					L("(chuchoté) Un secret… Une fois par an… le jour de mon anniversaire… je descends dans le Jardin des Apesanteurs… tout au bout… et je crie… Une seule fois… « COUCOU ! »… Puis je reviens… Ça me fait du bien pour une année entière.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("(chuchoté) La bibliothèque est au fond de l'Académie… à l'est de l'Agora… Tu reconnaîtras : c'est la seule porte devant laquelle tout le monde se met à marcher sur la pointe des pieds… Même Glorb… qui n'a pas de pieds.", {}, "rire"),
					L("(chuchoté) Dans les livres d'en bas… j'ai lu qu'il existe des chats… des rats… des cochons… et des chiens qui suivent les gens partout… Des animaux qui suivent les gens !… Je trouve ça… très romantique.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("(chuchoté) Le Professeur Quasar… Je lui ai rangé ses notes… par ordre alphabétique… Il est furieux… Il ne retrouve rien… Mais tout est bien rangé… C'est l'essentiel.", {}, "rire"),
					L("(chuchoté) Lyre m'a écrit un poème… « Murmure, ô douce créature, ta voix est comme une… » … Elle n'a pas trouvé la fin… Moi non plus… Je l'ai rangé à la lettre « P »… Pour « pas fini ».", {}, "rire"),
				],
				"interpelle": [L("(chuchoté) Psst… bonjour…", {"visites_max": 0}, "salut"), L("(chuchoté) {surnom}… coucou…", {"visites_min": 1}, "salut")],
			}},
		{"id": "zenith", "nom": "Zénith", "titre": "astronome de l'Observatoire", "maison": "porte_zenith", "village": "astralys",
			"agenda": [[6, 13, "maison"], [13, 15, ["cafe_table_3", "agora_banc_2"]], [15, 18, "observatoire_pont"], [18, 6, "observatoire_telescope"]],
			"azur": {"cheveux": BLEU_NUIT, "coiffure": "chauve", "yeux": Y_AZUR, "haut": BLEU_NUIT, "robe": BLEU_NUIT, "taille": 1.12, "carrure": 0.8},
			"lumen": {"peau": "bleu_pale", "tenue": "cape", "crete": "cristal", "antennes": true, "bijou": "halo", "objet": "telescope_portable"},
			"humeur_base": 0.5, "traits": {"bavard": 0.6, "humour": 0.55, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"etoile_mer": 3.0, "elixir_etoile": 2.5, "gateau_lune": 2.0, "fragment_meteorite": 2.0, "the_stellaire": 1.5, "boussole": 1.5}, "deteste": {"lunettes_kaleido": -1.0, "cafe_brasier": -0.5},
			"tics": ["Regarde, là-haut…", "On dirait une constellation.", "Hmm ? Pardon, je rêvais.", "Ça me fait penser à une étoile."],
			"surnoms": [[0, "petite étoile"], [25, "petite étoile"], [50, "étoile du soir"], [75, "étoile du berger"], [95, "ma constellation préférée"]],
			"repliques": {
				"accueil": [
					L("Hmm ? Oh. Pardon, je regardais tes taches de rousseur. Ou tes grains de beauté. On dirait la Grande Ourse. Zénith, astronome de l'Observatoire. Je vois des constellations partout. Dans le ciel, dans la soupe, dans les gens. Tu en es une très jolie.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Hier soir, j'ai vu une étoile qui te ressemblait. Elle clignotait comme quelqu'un qui revient. Et te voilà.", {"visites_min": 2}),
				],
				"humeur": [
					L("Rêveuse. Ce matin, j'ai vu une constellation dans mon bol de thé. Elle avait la forme d'un biscuit. Je l'ai appelée « la Grande Gourmande ». Puis je l'ai bue.", {}, "rire"),
					L("Triste. Mon grand télescope est en panne : la dernière pluie d'étoiles filantes a cassé trois lentilles. Il me faudrait trois fragments de météorite pour en fondre de nouvelles. Il y en a toujours qui traînent sur l'île, après une pluie.", {"q56": "as_etoiles="}),
					L("La nuit, je suis au télescope. Les autres regardent les aurores ; moi, je regarde derrière. Il y a des étoiles qui attendent qu'on les remarque. Je les remarque toutes. C'est mon travail. C'est ma joie.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, le ciel était toujours couvert. Personne n'avait jamais vu une étoile. Le premier soir ici, j'ai levé la tête… Il y en avait des milliards. J'ai pleuré toute la nuit. Le lendemain, j'ai construit l'Observatoire.", {}),
					L("J'ai donné un nom à onze mille étoiles. « La Petite Chaussette ». « Le Nez de Gloubi ». « Celle qui fait coucou ». La Doyenne trouve que mes noms manquent de sérieux. Elle a une étoile à son nom. Je l'ai appelée « Mamie ». Elle a ri trois jours.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Il y a une étoile, tout au bord du ciel, que je regarde chaque nuit. C'est le soleil d'Ondelune. On le voit à peine. Je lui dis bonsoir. Je lui raconte qu'on va bien. Il ne répond pas. Il est très loin. Mais il brille encore.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("L'Observatoire est sur un îlot flottant, au nord, relié au plateau par un pont de lumière. Le pont s'allume quand on s'approche. Ne regarde pas en bas. Ou regarde, si tu aimes les nuages vus de dessus. Moi, j'adore.", {}),
					L("Les pluies d'étoiles filantes arrivent certaines nuits, sans prévenir. Des petits fragments de météorite tombent partout sur l'île. Ils sont encore tièdes. On les ramasse. Ionie en fait des moteurs, Orbe des vitrines, et moi… des vœux.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Sextant, le cartographe, me demande toujours où est le nord. Je lui montre l'étoile Polaire. Il me dit : « Non, sur ma carte. » On ne parle pas du même ciel.", {}, "rire"),
					L("Comète dit qu'elle a battu une étoile filante à la course. J'ai vérifié : c'était un satellite de Quasar. Le grille-pain gravitationnel. Il est toujours en orbite.", {}, "rire"),
				],
				"interpelle": [L("Hmm ? Oh, bonjour, petite étoile.", {"visites_max": 0}, "salut"), L("{surnom} ! Regarde le ciel !", {"visites_min": 1}, "salut")],
			}},
		{"id": "sextant", "nom": "Sextant", "titre": "cartographe", "maison": "porte_sextant", "village": "astralys",
			"agenda": [[7, 11, "portail_belvedere"], [11, 13, "musee_salle_1"], [13, 14, ["cafe_table_2", "cafe_table_3"]], [14, 19, ["observatoire_pont", "jardins_bassin", "spatioport_tour"]], [19, 22, "maison"], [22, 2, "rue_4"], [2, 7, "maison"]],
			"azur": {"cheveux": ARGENT_C, "coiffure": "chauve", "yeux": Y_ARGENT, "haut": TURQUOISE_C, "taille": 1.06, "carrure": 0.85, "lunettes": true},
			"lumen": {"peau": "argent", "tenue": "tunique", "crete": "aucune", "antennes": true, "bijou": "aucun", "objet": "livre"},
			"humeur_base": 0.4, "traits": {"bavard": 0.55, "humour": 0.6, "curiosite": 0.85, "susceptible": 0.35, "rancunier": 0.1},
			"aime": {"boussole": 2.5, "boussole_sud": 2.5, "plume_corbeau": 1.5, "carte_postale": 1.5, "cafe_vapeur": 1.0, "papyrus_thot": 1.5}, "deteste": {"montre_envers": -1.0, "lunettes_kaleido": -0.5},
			"tics": ["Hmm, à l'échelle…", "Le nord est par là. Non, par là.", "Je le note.", "Ne bougez plus, je vous dessine."],
			"surnoms": [[0, "petit point sur la carte"], [25, "voyageur"], [50, "explorateur"], [75, "grand explorateur"], [95, "mon point cardinal"]],
			"repliques": {
				"accueil": [
					L("Ne bougez plus ! … Voilà. Je vous ai dessiné. Un petit point, là, sur le belvédère. Sextant, cartographe. Je dessine la carte de l'archipel, vue d'en haut. D'ici, les îles ressemblent à des biscuits trempés dans du thé. C'est très pratique pour les reconnaître.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Vous revenez d'en bas ? Dites-moi : la grande île de l'est, elle a toujours sa forme de chaussure ? Je n'arrive pas à dessiner le talon.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Concentré. J'ai redessiné Port-Azur. C'est la dix-septième fois. À chaque fois, quelqu'un a construit une cabine de plage. Ils n'arrêtent pas de construire, en bas. C'est épuisant pour un cartographe.", {}, "rire"),
					L("Content. J'ai enfin dessiné l'Île de Braise sans brûler ma feuille. Le secret : la dessiner de très loin, avec un très long crayon.", {}, "rire"),
					L("Le soir, je regarde les lumières des îles, tout en bas. Chaque lumière, c'est une maison. Je les compte. Il y en a de plus en plus. C'est une bonne nouvelle, je trouve.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, il n'y avait pas de cartes : la planète était toute ronde et toute pareille, on ne pouvait pas se perdre. Ici, il y a des îles, des volcans, des forêts, des courants… On se perd partout ! J'ai adoré. J'ai pris un crayon.", {}),
					L("Ma carte de l'archipel fait trente mètres de long. Elle est enroulée dans le Musée. Orbe veut l'exposer. Il faudrait une salle entière. Et un escabeau. Et que je la finisse : il me manque toujours un petit bout, au sud.", {"sujet_min": ["lui", 1]}),
					L("J'ai un secret de cartographe, {surnom}. Sur ma carte, j'ai caché un petit dessin dans chaque île. Un chat à Port-Azur, un perroquet à la Balafre, un dragon à Braise… Personne ne les a jamais trouvés. Sauf la Doyenne. Elle a ajouté une moustache au chat.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Depuis le belvédère du Portail, au sud-est, on voit tout l'archipel. Le matin, la brume fait des lacs blancs entre les îles. Je dessine les îles. La brume, je la laisse. Elle bouge trop.", {}),
					L("Astralys, je l'ai dessinée aussi : la Flèche au milieu, l'Agora au sud, le Musée et l'Académie de chaque côté, l'Observatoire au nord, le Spatioport à l'est, les Jardins et le Jardin des Apesanteurs à l'ouest. Facile. Elle ne bouge pas. Enfin, elle flotte. Mais sans bouger.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Zénith dessine des constellations sur mes cartes. Il dit que c'est pour décorer. Maintenant, la Balafre a une Grande Ourse. Les pirates n'ont rien remarqué.", {}, "rire"),
					L("Solenne connaît des raccourcis à Port-Coutelas que même les pirates ignorent. Je lui ai demandé comment. Elle a dit : « Par les livres. » Il n'y a aucun livre sur Port-Coutelas. J'ai vérifié.", {}),
				],
				"interpelle": [L("Ne bougez plus ! Je vous dessine.", {"visites_max": 0}, "salut"), L("{surnom} ! Des nouvelles d'en bas ?", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ le Spatioport
		{"id": "ionie", "nom": "Ionie", "titre": "mécanicienne du Spatioport", "maison": "porte_ionie", "village": "astralys",
			"agenda": [[6, 12, "spatioport_hangar"], [12, 13, ["cafe_table_2", "cafe_table_3"]], [13, 19, ["spatioport_hangar", "spatioport_aire_1"]], [19, 22, ["cafe_table_1", "rue_5"]], [22, 2, "spatioport_aire_2"], [2, 6, "maison"]],
			"azur": {"cheveux": TURQUOISE_C, "coiffure": "chauve", "yeux": Y_TURQUOISE, "haut": [0.85, 0.55, 0.2], "taille": 1.02, "carrure": 1.0},
			"lumen": {"peau": "turquoise", "tenue": "combinaison", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "baton_lumiere"},
			"humeur_base": 0.7, "traits": {"bavard": 0.8, "humour": 0.75, "curiosite": 0.85, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"engrenage": 2.0, "chapeau_ventilateur": 2.5, "cafe_vapeur": 2.0, "boulon": 1.5, "ressort": 1.5, "engrenage_or": 2.5}, "deteste": {"parapluie_helice": -1.0, "galette_algue": -0.5},
			"boutique": {"vend": {"cristal_astral": 25, "fragment_meteorite": 12, "engrenage": 5}, "achete": {"boulon": 2, "ressort": 2, "minerai_fer": 3, "rouage": 3, "engrenage_or": 12, "fragment_meteorite": 6, "buche": 1}},
			"tics": ["Clac, c'est réparé !", "Passe-moi la clé lumineuse.", "Ça tourne !", "Vroooum !"],
			"surnoms": [[0, "nouveau"], [25, "apprenti"], [50, "mécano"], [75, "co-pilote"], [95, "mécano de génie"]],
			"repliques": {
				"accueil": [
					L("Salut ! Attention, ne marche pas sur le moteur : il dort. Ionie, mécanicienne du Spatioport ! Je répare les soucoupes, les navettes, et tout ce qui vole, flotte ou fait « vroum ». Tu as une machine volante, toi ? Une vraie ? Avec des hélices ? Montre-moi ! J'adore les hélices ! Les Pieds-Lourds font des machines si… courageuses.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu tombes bien ! Tiens ça. Non, l'autre bout. Voilà. (Clac !) C'est réparé. Merci, apprenti.", {"visites_min": 2}, "rire"),
					L("Alors, ce Glisseur stellaire ? Il ronronne, hein ? Je l'ai réglé aux petits oignons. Enfin, aux petits cristaux. Si un jour il tousse, reviens me voir. Il ne toussera pas. Mais reviens quand même.", {"a_trouve": "glisseur"}, "rire"),
				],
				"humeur": [
					L("Au top ! J'ai réparé la soucoupe de Comète pour la quarante-troisième fois. Elle a encore fait la course avec une mouette. La mouette a gagné. La soucoupe a perdu un aileron.", {}, "rire"),
					L("Impatiente ! Les inventeurs de Cliquetis ont construit une machine volante pour les Pieds-Lourds. Des hélices, un ballon, une nacelle… C'est magnifique et ça fait du bruit. Si on y mettait un cœur de cristal… Imagine !", {"q56": "as_glisseur="}),
					L("Le soir, je règle les soucoupes sur l'aire d'atterrissage. Pendant les aurores, les coques prennent toutes les couleurs. C'est le seul moment où je trouve les soucoupes plus belles que leurs moteurs.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, les machines poussaient toutes seules, comme des plantes. Ici, il faut les construire ! Avec des vis ! Des boulons ! Des clés ! La première fois que j'ai serré un boulon, j'ai eu la chair de poule. Enfin, la chair de Lumen. Ça clignote.", {}, "rire"),
					L("Mes outils sont en lumière solide. Ma clé fait toutes les tailles, mon tournevis tous les pas de vis. Le seul outil que je n'ai jamais réussi à fabriquer en lumière, c'est le marteau. Il passe à travers les clous. Alors j'ai un vrai marteau. De Cliquetis. Je l'adore.", {"sujet_min": ["lui", 1]}),
					L("Un secret ? Je rêve de descendre à Cliquetis. Voir leurs ateliers, leurs engrenages, leur Foire des Inventions. Mais si j'y vais, je ne remonterai jamais. Je resterai à démonter des grille-pain jusqu'à la fin des temps. Et ça me semble être une très bonne fin des temps.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("Le Spatioport, à l'est : un grand hangar, la Tour de contrôle et trois aires d'atterrissage. Les soucoupes de passage se posent ici. Les touristes aussi. Glorb est arrivé en soucoupe de location. Il l'a rendue toute collante.", {}, "rire"),
					L("Les cristaux astraux poussent sous l'île, dans la roche sombre. Je descends les chercher avec mon harnais. C'est un peu vertigineux, mais c'est là que les cristaux sont les plus beaux. Ils bourdonnent. On dirait qu'ils fredonnent.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le Professeur Quasar a voulu améliorer une soucoupe. Elle vole maintenant en marche arrière, mais seulement le mardi. On l'a gardée pour le mardi.", {}, "rire"),
					L("Volt fait semblant de ne pas m'aimer. Il m'apporte du café tous les matins « parce qu'il en avait trop fait ». Ça fait quatre cents ans qu'il en fait trop.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Ne touche pas au moteur, il dort !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir, ça tourne !", {"visites_min": 1}, "rire")],
				"boutique": [L("Cristaux astraux, fragments de météorite, engrenages ! J'achète aussi la ferraille, les boulons, les ressorts. Les rondelles, je les mets dans ma boîte à vis. Elles font un joli bruit. Tu en as {pieces}.", {}, "rire")],
			}},
		{"id": "comete", "nom": "Comète", "titre": "pilote de soucoupe", "maison": "porte_comete", "village": "astralys",
			"agenda": [[9, 12, ["spatioport_aire_1", "spatioport_aire_2"]], [12, 13, ["cafe_table_4", "cafe_table_1"]], [13, 17, ["apesanteur_1", "apesanteur_2"]], [17, 20, ["spatioport_tour", "spatioport_aire_1"]], [20, 22, ["cafe_table_3", "rue_1"]], [22, 2, ["rue_2", "rue_3"]], [2, 9, "maison"]],
			"azur": {"cheveux": ROSE_C, "coiffure": "chauve", "yeux": Y_ROSE, "haut": [0.95, 0.4, 0.3], "taille": 0.98, "carrure": 0.85},
			"lumen": {"peau": "rose_nacre", "tenue": "combinaison", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "aucun"},
			"humeur_base": 0.75, "traits": {"bavard": 0.85, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.45, "rancunier": 0.05},
			"aime": {"coupe_course": 3.0, "glace": 2.0, "limonade_boucan": 2.0, "punch_coco": 1.5, "cafe_brasier": 1.5}, "deteste": {"tisane_lune": -1.0, "tisane_brume": -1.0},
			"tics": ["Vziiiou !", "Plus vite !", "Trop lent !", "Attache ta ceinture !"],
			"surnoms": [[0, "escargot"], [25, "tortue"], [50, "lièvre"], [75, "fusée"], [95, "étoile filante"]],
			"repliques": {
				"accueil": [
					L("Vziiiou ! Salut ! Comète, pilote de soucoupe ! La plus rapide d'Astralys ! Et la plus jeune pilote : cent quatre-vingts ans. Ici, c'est très jeune. Tu sais voler, toi ? Non ? Dommage. Tu sais courir ? Un peu ? Bon. On commencera par là.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as vu ? J'ai bouclé le tour de l'île en onze secondes ! Ionie dit que j'ai perdu un aileron. Ce n'est pas grave, j'en ai d'autres.", {"visites_min": 2}, "rire"),
					L("Tu m'as battue. Toi. Un Pied-Lourd. Avec une machine à hélices. (Elle croise les bras, puis éclate de rire.) Revanche ! Demain ! Et après-demain ! Toute la vie !", {"q56": "as_course=finie"}, "rire"),
				],
				"humeur": [
					L("Rapide ! Ce matin, j'ai fait la course avec une étoile filante. J'ai gagné. Enfin, l'étoile ne savait pas qu'on faisait la course. Mais j'ai gagné quand même.", {}, "rire"),
					L("Je m'ennuie. Personne ne veut faire la course avec moi. Ionie dit que ses soucoupes sont fatiguées. Volt dit que je fais clignoter la Flèche. Il me faudrait un adversaire. Un vrai. Avec une machine qui vole…", {"q56": "as_course="}),
					L("Le soir des aurores, je regarde depuis la rue, assise par terre. Je ne vole pas pendant les aurores. C'est la seule chose dans le ciel que je ne veux pas dépasser.", {"soir": true}),
				],
				"lui": [
					L("À trente ans, j'ai volé la soucoupe de ma tante pour faire le tour de la Flèche. Quatre-vingt-sept fois. Ma tante m'a punie : interdiction de voler pendant dix ans. J'ai passé dix ans à courir dans le Jardin des Apesanteurs. Résultat : je cours plus vite que tout le monde, en plus.", {}, "rire"),
					L("Ma soucoupe s'appelle « Fusée ». Ce n'est pas une fusée. C'est une soucoupe. Mais elle a l'âme d'une fusée. Ionie dit qu'elle a surtout l'âme d'une casserole. Elle est jalouse.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu veux savoir pourquoi je vais toujours si vite ? Parce que quand je vais vite, je n'ai pas le temps d'avoir peur. Et j'ai peur de plein de choses : du noir, du vide, des discours d'Écliptique… Mais à toute vitesse, tout ça reste derrière moi.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Jardin des Apesanteurs, à l'ouest : il y a un parcours d'anneaux lumineux, chronométré. Mon record ? Je ne le dis pas. Il est trop bon. Ça découragerait tout le monde.", {}, "rire"),
					L("Le ciel autour d'Astralys, c'est le meilleur circuit du monde : on passe sous l'île, entre les îlots, à travers les chutes de lumière… Si tu as une machine qui vole, je t'y emmène. Tu vas crier. De joie. Sûrement.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Ionie a promis de me prêter son nouveau moteur à cristal. Elle me l'a promis il y a douze ans. Elle dit que « je ne suis pas prête ». Je suis TRÈS prête.", {}),
					L("Quark m'a demandé de l'emmener faire un tour en soucoupe. Pixel l'a dit à sa maman. Pixel est une rapporteuse. Quark est un petit casse-cou. Je l'aime bien. Il me rappelle quelqu'un.", {}, "rire"),
				],
				"interpelle": [L("Vziiiou ! Hé, toi ! Tu cours vite ?", {"visites_max": 0}, "salut"), L("{surnom} ! Une course ?", {"visites_min": 1}, "rire")],
			}},
		# ================================================================ les Jardins, la Serre, les Bulles
		{"id": "photon", "nom": "Photon", "titre": "jardinier des Jardins suspendus", "maison": "porte_photon", "village": "astralys",
			"agenda": [[5, 12, ["jardins_1", "jardins_2"]], [12, 13, "jardins_bassin"], [13, 17, ["apesanteur_2", "jardins_1"]], [17, 20, ["jardins_2", "serre_2"]], [20, 22, ["cafe_table_2", "jardins_bassin"]], [22, 2, "jardins_2"], [2, 5, "maison"]],
			"azur": {"cheveux": [0.3, 0.75, 0.45], "coiffure": "chauve", "yeux": Y_TURQUOISE, "haut": [0.3, 0.6, 0.4], "taille": 1.04, "carrure": 0.95},
			"lumen": {"peau": "turquoise", "tenue": "tunique", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "arrosoir"},
			"humeur_base": 0.65, "traits": {"bavard": 0.6, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.25, "rancunier": 0.0},
			"aime": {"graines": 2.5, "fleur_lune": 2.5, "miel": 2.0, "fleur_nebuleuse": 2.0, "pomme": 1.5, "graine_or": 2.0}, "deteste": {"piment_infernal": -1.5, "bombe_peinture": -0.5},
			"tics": ["Chut, elle pousse.", "Tu as entendu ? Elle a dit merci.", "Doucement, les racines…", "(Il caresse une feuille, qui clignote.)"],
			"surnoms": [[0, "petite pousse"], [25, "petite pousse"], [50, "jeune bouture"], [75, "belle plante"], [95, "mon plus bel arbre"]],
			"repliques": {
				"accueil": [
					L("Chut… Pardon. Elle pousse. (Il désigne une fleur grande comme une porte, qui clignote doucement.) Photon, jardinier des Jardins suspendus. Je parle aux plantes, et elles me répondent en clignotant. Celle-là vient de dire que tu as l'air gentil. Enfin, elle a clignoté deux fois. Deux fois, c'est gentil.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Les fleurs t'ont reconnu ! Regarde, elles clignotent en vert. C'est leur couleur pour les amis. Pour Glorb, elles clignotent en vert aussi, mais c'est parce qu'elles croient que c'est une plante.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Épanoui. Le grand nénuphar du bassin a ouvert une fleur cette nuit. Il en ouvre une tous les cent ans. Je l'ai regardée toute la nuit. Elle sentait la menthe et l'orage.", {}),
					L("Inquiet. Mes graines lumineuses se sont envolées vers le Jardin des Apesanteurs. Là-bas, rien ne retombe : elles flottent tout en haut, et je ne saute pas assez haut pour les rattraper. Mes genoux ont huit cents ans.", {"q56": "as_graines="}),
					L("Le soir des aurores, je reste dans les jardins. Les plantes adorent les aurores. Elles se tournent toutes vers le ciel et clignotent avec. C'est leur fête à elles.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, les plantes étaient en verre, et elles ne disaient rien. Ici, elles poussent, elles bougent, elles boivent, elles clignotent. La première plante d'en bas que j'ai vue, c'était un pissenlit, dans une fente du Portail. Il est toujours là. On se dit bonjour tous les matins.", {}),
					L("J'ai appris à parler aux plantes il y a quatre cents ans. Un clignement, c'est oui. Deux, c'est merci. Trois, c'est « arrose-moi ». Un long clignement très lent, c'est une blague. Les plantes ont beaucoup d'humour. Mais c'est très lent.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un secret ? J'ai une graine d'en bas. Une vraie graine de pommier, de Montjoie, je crois. Solenne me l'a rapportée de… de nulle part. Je n'ose pas la planter. J'ai peur qu'elle ne pousse pas, si loin du sol. Je la garde dans ma poche, depuis cinquante ans. Elle attend. Moi aussi.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les Jardins suspendus sont à l'ouest de l'Agora : des plantes lumineuses géantes, des bassins, des fleurs qui chantent au lever du soleil. Le matin, va écouter. Elles chantent faux. Mais avec beaucoup de cœur.", {}),
					L("Au bout du pont de lumière, à l'ouest, c'est le Jardin des Apesanteurs. Une expérience de Quasar. Les feuilles tombent vers le haut, les graines flottent, et les jardiniers sautent comme des puces. Je n'y vais plus beaucoup. Mes genoux préfèrent la gravité.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Gloubi vient cueillir des fruits lumineux pour sa cuisine. Il leur demande la permission avec ses quatre bras. Ça fait beaucoup de bras pour une seule question. Les fruits disent toujours oui. Ils sont intimidés.", {}, "rire"),
					L("Nova m'a dit que les méduses de ciel aiment se reposer dans mes grandes fleurs. Ça les chatouille. Les fleurs clignotent de rire toute la nuit.", {}),
				],
				"interpelle": [L("Chut… Bonjour… elle pousse.", {"visites_max": 0}, "salut"), L("{surnom} ! Les fleurs te disent bonjour !", {"visites_min": 1}, "salut")],
			}},
		{"id": "nova", "nom": "Nova", "titre": "zoologiste de la Serre des Espèces", "maison": "porte_nova", "village": "astralys",
			"agenda": [[7, 12, "serre_1"], [12, 13, ["jardins_bassin", "cafe_table_2"]], [13, 18, ["serre_1", "serre_2"]], [18, 20, "apesanteur_2"], [20, 22, ["cafe_table_2", "cafe_table_1"]], [22, 2, "observatoire_pont"], [2, 7, "maison"]],
			"azur": {"cheveux": TURQUOISE_C, "coiffure": "chauve", "yeux": Y_TURQUOISE, "haut": [0.25, 0.5, 0.7], "taille": 1.0, "carrure": 0.85},
			"lumen": {"peau": "turquoise", "tenue": "combinaison", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "tablette_holo"},
			"humeur_base": 0.6, "traits": {"bavard": 0.75, "humour": 0.6, "curiosite": 0.95, "susceptible": 0.35, "rancunier": 0.05},
			"aime": {"galette_algue": 2.0, "poisson_lune": 2.5, "etoile_mer": 2.0, "perle": 1.5, "corail_rouge": 2.0, "miel": 1.0}, "deteste": {"dent_requin": -1.0, "croc_cerbere": -1.0},
			"tics": ["Oooh, regarde-la !", "Glouglou !", "C'est une espèce très rare.", "Doucement, elle est timide."],
			"surnoms": [[0, "petite espèce"], [25, "spécimen curieux"], [50, "ami des bêtes"], [75, "soigneur en second"], [95, "mon espèce préférée"]],
			"repliques": {
				"accueil": [
					L("Oooh ! Une nouvelle espèce ! … Ah non, un Pied-Lourd. Pardon. C'est l'habitude. Nova, zoologiste de la Serre des Espèces ! Je m'occupe des créatures du ciel : les méduses de ciel, les glouglous, les papillons-comètes… Toutes paisibles, toutes adorables, et toutes un peu bizarres. Comme nous.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu veux voir les glouglous ? Ils ont fait des petits ! Ils font « glouglou » plus aigu. C'est la chose la plus mignonne de la galaxie. J'ai vérifié.", {"visites_min": 2}, "rire"),
					L("Plume-de-Nuage est rentrée ! Elle flotte au-dessus du bassin comme si de rien n'était. Elle a un petit air coupable. Les méduses ont toujours un petit air coupable. Merci, {surnom}.", {"a_trouve": "meduse_rendue"}),
				],
				"humeur": [
					L("Ravie ! Un glouglou a dit son premier mot. C'était « glou ». Je l'ai noté. C'est un grand jour pour la science.", {}, "rire"),
					L("Désespérée ! Plume-de-Nuage, ma plus jeune méduse de ciel, s'est échappée de la Serre. Elle flotte quelque part autour de l'île. Elle ne sait pas rentrer toute seule. Elle a un sens de l'orientation de méduse.", {"q56": "as_meduse="}),
					L("Le soir, je regarde les méduses de ciel depuis le pont de l'Observatoire. Pendant les aurores, elles s'allument toutes. On dirait des lanternes qui nagent dans le ciel. Je pleure à chaque fois. De bonheur.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, il n'y avait aucun animal. Pas un oiseau, pas un insecte. Ici, le premier jour, une mouette s'est posée sur ma tête et m'a volé mon goûter. J'ai été tellement heureuse que j'ai décidé de consacrer ma vie aux animaux. Même aux voleurs de goûter.", {}, "rire"),
					L("Les méduses de ciel arrivent avec les vents d'altitude. Elles sont transparentes, elles brillent la nuit, et elles chantent tout bas, comme des verres qu'on frotte. Je les soigne quand elles sont fatiguées. Puis elles repartent. Certaines restent. Je ne sais jamais lesquelles.", {"sujet_min": ["lui", 1]}),
					L("Je vais te confier quelque chose. Dans les livres de Murmure, j'ai lu qu'en bas, il y a des chats qui ronronnent, des chiens qui remuent la queue, des cochons qui rient en grognant. Je rêve de caresser un chat. Un seul. Il paraît qu'ils sont très dignes.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Serre des Espèces est au nord-est, après l'Académie : un grand dôme de verre plein de créatures paisibles. Ne tape pas sur les vitres : les glouglous croient que c'est une invitation, et ils répondent. Pendant des heures.", {}),
					L("Les méduses de ciel aiment le Jardin des Apesanteurs : là-bas, elles n'ont même pas besoin de flotter, elles tombent vers le haut. C'est pour elles comme une sieste.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Glorb a voulu prendre une méduse de ciel en photo. La méduse a pris peur et s'est cachée derrière lui. Il est transparent aussi. Ça n'a pas marché.", {}, "rire"),
					L("Quark a essayé d'apprendre aux glouglous à dire un gros mot. Ils ont tous dit « glou ». Le gros mot était peut-être « glou », remarque. Je ne parle pas encore couramment le glouglou.", {}, "rire"),
				],
				"interpelle": [L("Oooh ! Une nouvelle espèce ! Ah non. Bonjour !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir les glouglous !", {"visites_min": 1}, "rire")],
			}},
		{"id": "bulle_lumen", "nom": "Bulle", "titre": "architecte des dômes", "maison": "porte_bulle", "village": "astralys",
			"agenda": [[8, 12, ["bulles_no_1", "bulles_ne_2"]], [12, 13, ["cafe_table_1", "cafe_table_4"]], [13, 18, ["bulles_no_2", "bulles_ne_2", "spatioport_hangar"]], [18, 22, ["jardins_bassin", "rue_5"]], [22, 2, ["rue_5", "rue_6"]], [2, 8, "maison"]],
			"azur": {"cheveux": VIOLET_PROFOND, "coiffure": "chauve", "yeux": Y_VIOLET, "haut": [0.6, 0.75, 0.9], "taille": 1.0, "carrure": 0.9},
			"lumen": {"peau": "lavande", "tenue": "tunique", "crete": "filaments", "antennes": true, "bijou": "diademe", "objet": "tablette_holo"},
			"humeur_base": 0.6, "traits": {"bavard": 0.7, "humour": 0.65, "curiosite": 0.8, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"coquillage": 2.5, "perle": 2.0, "eclat_cristal": 2.0, "lunettes_kaleido": 2.0, "etoile_mer": 1.5, "pain_miel": 1.0}, "deteste": {"buche": -0.5, "caillou": -0.3},
			"tics": ["C'est une question de courbe.", "Tout est rond, au fond.", "Pop !", "(Elle dessine un cercle dans l'air avec son doigt.)"],
			"surnoms": [[0, "petit carré"], [25, "petit rond"], [50, "jolie courbe"], [75, "belle bulle"], [95, "ma bulle préférée"]],
			"repliques": {
				"accueil": [
					L("Pop ! Bonjour ! Bulle, architecte. C'est moi qui construis les dômes du Quartier des Bulles. Tout est rond, ici : les maisons, les fenêtres, les portes, les lits. Même mes idées sont rondes. Chez vous, en bas, il paraît que les maisons ont des coins ? Des coins ! Où est-ce qu'on range les coins ?", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu as vu mon nouveau dôme, au nord-est ? Il est parfaitement rond. Enfin, presque. Quark a fait une bosse dedans en jouant. Je l'ai gardée. Elle a du caractère.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Arrondie ! J'ai fini une bulle pour Glorb. Il voulait une maison en forme de gelée. J'ai dit non. On a trouvé un compromis : une bulle verte qui tremble un peu quand il pleut.", {}, "rire"),
					L("Pensive. Un coquillage d'en bas est tombé sur ma table, hier, d'une valise de Solenne. Sa spirale est parfaite. Comment fait la mer ? Sans tablette ! Sans calcul ! Je suis jalouse d'un escargot de mer.", {}),
					L("Le soir des aurores, les dômes deviennent transparents et prennent les couleurs du ciel. C'est pour ça que je les fais ronds : pour que le ciel puisse s'y poser partout.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, on vivait dans des nuages. On pouvait passer à travers les murs, et les voisins aussi. Ce n'était pas pratique pour les secrets. En arrivant, j'ai voulu des murs. Des vrais. Mais ronds. Quasar a raté une expérience de pluie et fait des bulles géantes. Je les ai solidifiées. Voilà le Quartier des Bulles.", {}),
					L("J'ai construit deux cent douze dômes. Le plus petit est pour un glouglou de la Serre. Le plus grand est la Salle du Conseil. Écliptique voulait qu'elle soit carrée, « pour le sérieux ». Je l'ai faite ronde. Il s'y est perdu trois fois. Il n'y a pas de coin où se cacher.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un rêve ? Construire un dôme en bas, sur une île, au bord de la mer. Pour voir les vagues à travers le verre. Rondes, elles aussi. Presque. Il faudrait que je descende. Je n'ai jamais osé. Les maisons d'en bas me feraient peut-être de la peine, avec tous leurs coins.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Quartier des Bulles : un au nord-ouest, un au nord-est, de chaque côté de la Flèche. Chaque Lumen a sa bulle. La porte s'ouvre quand on dit son nom. Celle de Tempo s'ouvre à l'heure pile. Celle de Quark ne s'ouvre que si on fait une grimace.", {}, "rire"),
					L("Aurore, la guérisseuse, a sa bulle de soins au nord-est. Je l'ai faite en verre très doux, pour que la lumière qui soigne passe bien. Elle dit que les malades guérissent rien qu'en regardant le plafond.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Écliptique m'a demandé un dôme protocolaire, avec une estrade. Il est tombé de l'estrade le jour de l'inauguration. L'estrade était ronde, aussi. Il a roulé.", {}, "rire"),
					L("Glorb a collé sa main sur ma plus belle vitre. Elle a gardé l'empreinte. Une empreinte verte, en forme d'étoile. Je n'ai pas osé l'effacer. Orbe veut la découper pour le Musée.", {}, "rire"),
				],
				"interpelle": [L("Pop ! Bonjour, petit carré !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir mon dôme !", {"visites_min": 1}, "rire")],
			}},
		{"id": "aurore_lumen", "nom": "Aurore", "titre": "guérisseuse d'Astralys", "maison": "porte_aurore", "village": "astralys",
			"agenda": [[7, 12, "bulles_ne_1"], [12, 13, ["cafe_table_1", "jardins_bassin"]], [13, 18, "bulles_ne_1"], [18, 20, ["jardins_bassin", "agora_banc_1"]], [20, 22, "bulles_ne_1"], [22, 1, ["rue_6", "jardins_bassin"]], [1, 7, "maison"]],
			"azur": {"cheveux": ROSE_C, "coiffure": "chauve", "yeux": Y_ROSE, "haut": BLANC_NACRE, "robe": ROSE_C, "taille": 1.02, "carrure": 0.85},
			"lumen": {"peau": "rose_nacre", "tenue": "robe_longue", "crete": "cristal", "antennes": true, "bijou": "collier", "objet": "aucun"},
			"humeur_base": 0.65, "traits": {"bavard": 0.55, "humour": 0.55, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"tisane_lune": 2.5, "miel": 2.0, "potion_seve": 2.0, "fleur_lune": 2.0, "the_menthe": 1.5, "tisane_brume": 1.5}, "deteste": {"piment_infernal": -1.5, "remontant_doc": -1.0},
			"tics": ["Respire doucement.", "Ça va passer.", "Montre-moi où ça fait mal.", "(Ses mains brillent un peu.)"],
			"surnoms": [[0, "petit patient"], [25, "mon patient"], [50, "mon cœur"], [75, "mon petit soleil"], [95, "ma plus belle lumière"]],
			"repliques": {
				"accueil": [
					L("Bonjour, mon petit patient. N'aie pas peur : je ne pique pas. Aurore, guérisseuse. Je soigne avec la lumière : je pose mes mains, elles brillent, et la douleur s'en va. Les bosses, les égratignures, les chagrins… Les chagrins, c'est plus long. Mais ça marche aussi.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens, que je te regarde. Hmm… Pas de bosse, pas d'égratignure… juste un peu de fatigue. Assieds-toi cinq minutes au soleil. C'est ma meilleure ordonnance.", {"visites_min": 2}),
				],
				"humeur": [
					L("Douce. Ce matin, j'ai soigné le genou de Quark. Il est tombé du pont de lumière en essayant de marcher sur les mains. Il a dit que c'était pour la science. Quasar a confirmé. Je les ai grondés tous les deux.", {}, "rire"),
					L("Fatiguée, mais contente. Écliptique est venu trois fois aujourd'hui : il était tombé de l'estrade, puis de sa chaise, puis de l'estrade encore. Je lui ai prescrit de faire des discours assis.", {}, "rire"),
					L("Le soir des aurores, je ferme ma bulle et je vais regarder le ciel. Les aurores, c'est de la lumière qui soigne le ciel. C'est ce que je crois. Le ciel a l'air toujours mieux après.", {"soir": true}),
				],
				"lui": [
					L("Sur Ondelune, personne n'était jamais malade. On ne tombait pas, on flottait. En arrivant ici, le premier jour, un petit Lumen a découvert la gravité en tombant d'une marche. Il a pleuré. J'ai posé mes mains sur son genou, sans savoir pourquoi. Elles ont brillé. Voilà comment je suis devenue guérisseuse.", {}),
					L("Je soigne les Lumens, les touristes, les glouglous et les méduses de ciel. Une fois, Glorb s'est coupé en deux en passant sous une porte. Je l'ai recollé. Il dit qu'il se sent mieux qu'avant. Un peu plus grand, aussi.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un secret, mon cœur ? Je ne sais pas soigner tout. Il y a des chagrins qui ne partent pas avec la lumière. Ceux-là, je m'assieds à côté, et j'attends. Souvent, c'est ça qui soigne : quelqu'un qui reste.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Ma bulle de soins est dans le Quartier des Bulles, au nord-est. Bulle l'a faite en verre très doux. Il y a un lit rond, des coussins ronds, et un plafond où on voit le ciel. Les patients guérissent plus vite quand ils regardent les nuages passer.", {}),
					L("L'eau du bassin des Jardins suspendus est un peu lumineuse. Elle ne soigne pas, mais elle fait du bien aux pieds. Les Pieds-Lourds en ont souvent besoin, après la montée. Va les y tremper.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Volt vient me voir tous les mois pour « une petite douleur aux antennes ». Ce n'est jamais rien. Je crois qu'il vient pour discuter. Je lui sers un thé, il bougonne, il repart content.", {}),
					L("Pixel veut devenir guérisseuse. Elle soigne déjà ses poupées, les glouglous et son frère. Son frère se laisse faire, pour une fois. Il aime bien les pansements de lumière : ils brillent dans le noir.", {}),
				],
				"interpelle": [L("Bonjour ! Tout va bien ? Rien de cassé ?", {"visites_max": 0}, "salut"), L("{surnom} ! Viens que je te regarde.", {"visites_min": 1}, "salut")],
			}},
		# ================================================================ les enfants
		{"id": "pixel", "nom": "Pixel", "titre": "enfant lumen (89 ans, soit 8 ans lumens)", "maison": "porte_pixel", "village": "astralys",
			"agenda": [[8, 12, "academie_eleve_1"], [12, 13, ["agora_fontaine", "cafe_table_4"]], [13, 17, ["apesanteur_1", "jardins_1", "rue_2"]], [17, 21, ["agora_banc_3", "agora_fontaine", "serre_2"]], [21, 8, "maison"]],
			"azur": {"cheveux": ROSE_C, "coiffure": "chauve", "yeux": Y_AZUR, "haut": [0.95, 0.75, 0.35], "enfant": true, "taille": 0.72},
			"lumen": {"peau": "rose_nacre", "tenue": "enfant", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "tablette_holo"},
			"humeur_base": 0.75, "traits": {"bavard": 0.95, "humour": 0.7, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"glace": 3.0, "biscuit_lunaire": 2.0, "etoile_mer": 2.0, "canard_mecanique": 2.0, "cerf_volant": 2.5, "coquillage": 1.5}, "deteste": {"galette_algue": -1.0, "tisane_lune": -0.5},
			"tics": ["Pourquoi ?", "Et pourquoi ?", "Mais POURQUOI ?", "Je le savais !"],
			"surnoms": [[0, "Pied-Lourd"], [25, "mon Pied-Lourd"], [50, "mon copain"], [75, "mon meilleur copain"], [95, "mon meilleur copain de tout l'univers"]],
			"repliques": {
				"accueil": [
					L("Un Pied-Lourd ! Un vrai ! Pourquoi tu as les pieds lourds ? Ils sont en pierre ? Tu peux sauter ? Pourquoi tu n'as pas d'antennes ? Comment tu fais pour entendre les étoiles ? Moi, c'est Pixel. J'ai quatre-vingt-neuf ans. C'est huit ans, pour un Lumen. Et toi, tu as quel âge ? Pourquoi ?", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu reviens ! Pourquoi tu reviens ? Parce que tu m'aimes bien ? Je le savais !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super bien ! À l'Académie, j'ai posé quarante-deux questions au Professeur Quasar. Il a répondu à trois. Puis il est parti « chercher une réponse ». Il n'est pas revenu. Pourquoi ?", {}, "rire"),
					L("Fâchée. Quark a encore triché à cache-cache. Il s'est caché dans un hologramme de la fontaine ! On n'a pas le droit de se cacher dans une planète ! C'est dans le règlement ! Enfin, c'est dans mon règlement.", {}),
					L("Maman dit qu'à neuf heures je dois être au lit. Mais les aurores commencent à dix heures ! Pourquoi les aurores ne commencent pas plus tôt ? Pourquoi je ne me couche pas plus tard ? Pourquoi personne ne répond ?", {"soir": true}),
				],
				"lui": [
					L("Quand je serai grande, je serai guérisseuse, comme Aurore. Ou zoologiste, comme Nova. Ou pilote, comme Comète. Ou tout en même temps. J'aurai le temps : je vivrai mille ans. Au moins.", {}),
					L("Quark, c'est mon petit frère. Il a quatre-vingt-un ans. Il fait n'importe quoi. Il se cache, il fait des farces, il colle des biscuits sur l'Hologuide. Enfin, à travers. Moi, je suis très sage. Presque tout le temps. Pourquoi tu ris ?", {"sujet_min": ["lui", 1]}, "rire"),
					L("Un secret ? J'ai une boîte avec des choses d'en bas. Une plume, un caillou tout rond, un bouton. Solenne me les a données. Je les regarde le soir. J'imagine comment c'est, en bas. Il y a des chats ? C'est vrai, les chats ? Tu en as un ? Pourquoi pas ?", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Mon endroit préféré, c'est le Jardin des Apesanteurs ! On saute super haut ! Une fois, j'ai sauté si haut que j'ai vu le dessus de la tête de Halo. Il n'a pas de cheveux. Personne n'a de cheveux. Pourquoi vous avez des cheveux, en bas ?", {}, "rire"),
					L("La fontaine de l'Agora change de planète toutes les minutes. Je les connais toutes ! Ondelune, Saturne, la Terre, Gloop… Gloop, c'est la planète de Glorb. Elle est toute verte et toute molle. Pourquoi ?", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Quark a dit qu'il allait se cacher là où personne ne le trouverait jamais. Je le trouve toujours. Il chante en se cachant. Il ne le sait pas. Ne lui dis pas.", {}, "rire"),
					L("L'Hologuide fait toujours la même visite. Toujours ! Je la connais par cœur. Étape onze : la fontaine. C'est son étape préférée. Je le sais, parce qu'il clignote plus fort.", {}),
				],
				"interpelle": [L("Hé ! Pourquoi tu as les pieds lourds ?", {"visites_max": 0}, "salut"), L("{surnom} ! Pourquoi tu es là ?", {"visites_min": 1}, "rire")],
			}},
		{"id": "quark", "nom": "Quark", "titre": "enfant lumen, petit frère de Pixel", "maison": "porte_quark", "village": "astralys",
			"agenda": [[8, 12, "academie_eleve_2"], [12, 13, ["agora_fontaine", "rue_3"]], [13, 17, ["apesanteur_2", "rue_3", "musee_salle_2"]], [17, 21, ["agora_banc_2", "agora_fontaine", "spatioport_aire_2"]], [21, 8, "maison"]],
			"azur": {"cheveux": ROSE_C, "coiffure": "chauve", "yeux": Y_OR, "haut": [0.35, 0.75, 0.95], "enfant": true, "taille": 0.68},
			"lumen": {"peau": "rose_nacre", "tenue": "enfant", "crete": "filaments", "antennes": true, "bijou": "aucun", "objet": "aucun"},
			"humeur_base": 0.8, "traits": {"bavard": 0.8, "humour": 1.0, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.05},
			"aime": {"sifflet_muet": 2.5, "champi_ressort": 2.5, "glace": 2.0, "bombe_peinture": 2.0, "des_pipes": 1.5, "biscuit_lunaire": 1.5}, "deteste": {"grimoire": -0.5, "tisane_lune": -1.0},
			"tics": ["Hé hé hé.", "C'est pas moi !", "Bouh !", "Je rigole !"],
			"surnoms": [[0, "Pied-de-Plomb"], [25, "Pied-de-Plomb"], [50, "complice"], [75, "complice de farces"], [95, "chef des farceurs"]],
			"repliques": {
				"accueil": [
					L("BOUH ! … Hé hé hé ! Tu as sursauté ! Les Pieds-Lourds sursautent super haut ! Moi, c'est Quark. J'ai quatre-vingt-un ans, c'est sept ans pour un Lumen, et je suis le meilleur joueur de cache-cache de toute la galaxie. Pixel dit que non. Pixel est jalouse.", {"visites_max": 1}, "rire"),
					L("{surnom} ! Hé hé. Ne regarde pas derrière toi. … Tu as regardé ! Hé hé hé !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Génial ! J'ai mis un biscuit lunaire dans la fontaine. Maintenant, il y a une planète en forme de biscuit. Tempo est furieux. Gloubi est fier.", {}, "rire"),
					L("Puni. J'ai branché ma toupie sur la Flèche. Toute l'Agora a clignoté en rose. Volt a fait sa tête de Volt. Mais tout le monde a applaudi ! C'était un spectacle, pas une bêtise !", {}),
					L("Maman dit qu'il faut dormir. Mais je ne dors pas. Je fais semblant. Et quand les aurores commencent, je regarde par le hublot. Ne le dis pas à Pixel. Elle le fait aussi.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Mes farces les plus célèbres : la crête d'Écliptique peinte en vert, l'Hologuide qui dit « Bienvenue à Gloubiland », et le jour où j'ai mis des grelots à toutes les horloges de Tempo. Il a dit que c'était « une offense au temps ». Le temps, lui, a rigolé. Je l'ai entendu.", {}, "rire"),
					L("Pixel, c'est ma grande sœur. Elle pose des questions, moi je fais des bêtises. À nous deux, on a fait le tour de toutes les choses qu'on n'a pas le droit de faire. Il en reste trois. On garde les meilleures pour la fin.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Je vais te dire un vrai secret. Je fais des farces parce que quand tout le monde rit, plus personne n'est triste. Même Volt. Même la Doyenne, quand elle pense à Ondelune. Alors je fais des farces. Beaucoup. C'est un travail.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Les meilleures cachettes d'Astralys ? Je ne te les dirai pas. Bon, une seule : la fontaine, entre deux planètes. Personne ne pense à regarder dans Jupiter. Elle est trop grosse. C'est pour ça que c'est parfait.", {}, "rire"),
					L("Au Jardin des Apesanteurs, je fais des sauts périlleux. Six d'affilée ! Comète dit que je suis presque aussi bon qu'elle. Presque. Elle dit toujours « presque ». C'est pour que je continue.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("L'Hologuide, je passe à travers lui. Quarante-deux fois hier ! Ça chatouille. Il dit que non, qu'il n'est pas chatouilleux. Mais il clignote. Hé hé.", {}, "rire"),
					L("Glorb, quand on lui saute dessus, il fait « blorp » et on rebondit. C'est le meilleur trampoline de l'île. Il dit qu'il n'est pas un trampoline. Il rebondit quand même.", {}, "rire"),
				],
				"interpelle": [L("BOUH ! Hé hé !", {"visites_max": 0}, "rire"), L("{surnom} ! Une farce ?", {"visites_min": 1}, "rire")],
			}},
	]

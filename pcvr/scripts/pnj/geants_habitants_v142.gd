extends RefCounted
## V142 : la famille Grandpré, les géants de l'Île des Géants (au sud-est de l'archipel). Des géants
## gentils, qui vivent dans leur ferme de conte et font très attention où ils mettent les pieds :
##  - Mère Mathurine, la fermière (13 m) : le potager, la cour, le linge ; elle a perdu son alliance
##    en désherbant les choux (quête « La bague de Mère Mathurine ») ;
##  - Père Eustache, le meunier (14 m) : le Moulin de la Butte, la grange et ses sacs de farine ;
##  - Grand-mère Ernestine (12 m) : dans son fauteuil à bascule, devant la maison, elle tricote une
##    écharpe plus longue que l'île ;
##  - Pâquerette, sept ans (9 m) : elle joue partout ; elle rêve d'un « tout petit ami » pour jouer à
##    cache-cache (quête « Cache-cache avec Pâquerette ») ;
##  - Oncle Théophile, le jardinier (13,5 m) : sa citrouille « la Géante », et les limaces qui lui
##    mangent ses choux (quête « Les limaces du potager »).
## Même cerveau que les autres habitants (pnj_brain_v31.gd) ; le corps est celui d'un habitant V64
## agrandi (pnj_geant_v142.gd, tools/generate_geants_v142.gd). Fiche « geant » : taille (m), agenda
## ([h0, h1, lieu] : potager_choux, potager_tomates, potager_citrouilles, cour, puits, porte, fauteuil,
## linge, grange, moulin, verger, ble, mare, pres ; « maison » : la nuit, il est rentré), vitesse.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Au revoir, {surnom} ! Et regarde bien où tu marches : chez nous, une flaque, c'est un lac.", "si": {}, "geste": "salut"},
		{"t": "À bientôt ! Reviens quand tu veux : on laisse toujours le ponton des petits bien propre.", "si": {}},
		{"t": "Bonne nuit, {surnom}. Si tu entends le tonnerre cette nuit, ce n'est pas l'orage : c'est Eustache qui ronfle.", "si": {"soir": true}, "geste": "rire"},
	],
	"frappe": [
		{"t": "Hi hi ! Arrête, ça chatouille ! On dirait une fourmi qui joue du tambour sur mon orteil.", "si": {}, "geste": "rire"},
		{"t": "Oh ! Tu me donnes des petits coups ? C'est tout doux. Mais ce n'est pas très gentil, {surnom}.", "si": {}, "humeur": -0.2},
	],
	"cadeau_neutre": [
		{"t": "Pour moi ? Oh, que c'est petit ! Je vais le poser sur le bout de mon doigt pour le regarder. Merci, {surnom}.", "si": {}},
		{"t": "Un cadeau ! Je le range dans mon dé à coudre, avec les trésors des petits. Il y en a déjà trois.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "Oh ! {dernier_cadeau} ! Si petit, et si parfait ! Tu as un cœur de géant, {surnom}.", "si": {}, "geste": "rire"},
		{"t": "Ça, c'est un vrai cadeau ! Je vais le montrer à toute la famille. Doucement, sans le perdre dans un sillon.", "si": {}},
	],
	"cadeau_deteste": [{"t": "Euh… merci. C'est… minuscule. Et ça sent un peu bizarre. Je vais le donner aux poules.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Garde-la, {surnom}. Chez nous, la seule chose qu'on combat, ce sont les limaces. Et les mauvaises herbes.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! On ne voit pas tous les jours un si petit voyageur. Tu es le seul qui tienne dans une coquille de noix.", "si": {}}],
	"quete_inconnue": [{"t": "Hein ? Je ne t'ai rien demandé, moi. Enfin, je crois. Les petites voix, on les entend mal d'en haut.", "si": {}, "geste": "rire"}],
	"blague": [
		{"t": "Pourquoi les géants ne jouent jamais à saute-mouton ? Parce que les moutons ne sont jamais d'accord !", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un géant met dans son café ? Une montagne de sucre. Et il le tourne avec une rame !", "si": {}, "geste": "rire"},
		{"t": "Tu sais ce qui est le plus dur, quand on est géant ? Trouver des chaussettes. On en tricote deux par an. C'est Grand-mère qui s'y colle.", "si": {}, "geste": "rire"},
		{"t": "Un petit demande à un géant : « Il fait beau, là-haut ? » Le géant répond : « Je ne sais pas, j'ai la tête dans un nuage. »", "si": {}, "geste": "rire"},
	],
}

const BASE := {
	"prefixes": {
		"joie": ["Ho ho !", "Par mes sabots !", "Quelle joie !", "Ha ha !"],
		"neutre": ["Hmm…", "Voyons…", "Bon.", "Alors…"],
		"triste": ["Hélas…", "Oh là là…", "Misère…", "Pff…"],
		"colere": ["Sapristi !", "Ça suffit !", "Grrr…", "Tss."],
	},
	"tics": ["Doucement, les petits pieds.", "Par mes sabots !", "Attention où tu marches.", "C'est grand, hein ?"],
	"humeur_mots": [[0.6, "gai comme un pinson géant"], [0.25, "de bonne humeur"], [-0.25, "un peu bougon"], [-0.6, "grognon"], [-2.0, "furieux comme un orage"]],
	"surnoms": [[0, "tout-petit"], [25, "petit voisin"], [50, "mon petit ami"], [75, "notre petit trésor"], [95, "petit géant"]],
}

## Les peaux, les couleurs (les corps eux-mêmes sont dans pnj64/<id>.bin)
const PEAU := [0.9, 0.7, 0.57]


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
	out["groupe"] = "geants"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		{"id": "mathurine_gt", "nom": "Mère Mathurine", "titre": "la fermière (une géante)", "maison": "potager_choux", "village": "geants",
			"geant": {"taille": 13.0, "vitesse": 3.6, "agenda": [[6, 7, "cour"], [7, 11, "potager_choux"], [11, 13, "puits"], [13, 16, "linge"], [16, 19, "potager_tomates"], [19, 21, "cour"], [21, 6, "maison"]]},
			"teinte": PEAU,
			"humeur_base": 0.5, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"miel": 2.0, "pain_miel": 2.0, "tarte_potiron": 2.0, "coquillage": 1.5, "bouquet_tournesols": 1.5}, "deteste": {"vieille_botte": -1.0, "sardine": -1.0},
			"tics": ["Par mes sabots !", "Doucement, les petits pieds.", "Mes choux, mes beaux choux…", "Ça pousse, ça pousse !"],
			"repliques": {
				"accueil": [
					L("Oh ! Mais qu'est-ce que c'est que ce petit bout de chose qui bouge dans l'herbe ? Un visiteur ! Un vrai petit visiteur ! Bonjour, bonjour ! Je suis Mère Mathurine, la fermière. Ne bouge pas, je me mets à genoux, sinon on va se parler à vingt mètres d'écart.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Te revoilà ! Attends, je pose ma binette. Voilà. Alors, comment va le plus petit ami de la ferme ?", {"visites_min": 2}),
					L("Ah, {surnom} ! Tu tombes bien, je parlais à mes choux. Ils ne répondent jamais, eux. Toi, si.", {"visites_min": 4}, "rire"),
				],
				"humeur": [
					L("Très bien ! Les choux sont gros comme des rochers, les tomates rougissent, et il fait un temps à étendre le linge. Que demander de plus ?", {}, "rire"),
					L("Un peu soucieuse. Avec ces limaces, Théophile ne dort plus. Il les compte la nuit au lieu de compter les moutons.", {}),
					L("Le soir, je m'assois sur le pas de la porte et je regarde les lumières des îles des petits, là-bas, sur la mer. On dirait des lucioles posées sur l'eau.", {"soir": true}),
				],
				"lui": [
					L("Je suis née ici, dans cette ferme, comme ma mère et la mère de ma mère. Les Grandpré ont toujours cultivé cette île. Elle est petite pour nous, mais elle est bonne.", {}),
					L("Mon secret pour des choux pareils ? Je leur chante des chansons. Eustache dit que c'est le fumier. Moi, je dis que c'est la chanson. On ne saura jamais.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Quand j'étais petite, je voulais voir les îles des petits. Ma mère m'a dit : « Si tu y mets un pied, tu écrases un village. » Alors je les regarde de loin. Et aujourd'hui, c'est un petit qui vient me voir. La vie est bien faite.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Bienvenue à la ferme des Grandpré ! La maison, la grange, le potager, le verger, le champ de blé, et là-haut sur la butte, le moulin d'Eustache. Pour toi, c'est un royaume. Pour nous, c'est un jardin.", {}),
					L("Fais attention dans le potager : pour toi, les sillons sont des fossés et les choux sont des maisons. Si tu te perds, crie très fort. Je t'entendrai peut-être.", {"sujet_min": ["ile", 1]}),
					L("Tu as vu le ponton, en bas, sur la grève ? Eustache l'a construit pour vous, les petits. Il a mis trois semaines. Il avait peur de l'écraser en plantant les clous.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [
					L("Théophile parle à sa citrouille. Il lui a donné un nom : « la Géante ». Il dit qu'elle gagnera le concours. Il n'y a pas de concours. Enfin, il y en a un : lui contre lui-même. Il gagne à chaque fois.", {}, "rire"),
					L("Pâquerette cherche un ami de sa taille pour jouer à cache-cache. Il n'y en a pas. Mais un tout petit ami, ça pourrait lui plaire encore plus.", {}),
					L("Grand-mère tricote une écharpe depuis l'hiver dernier. Elle fait déjà le tour de la maison. Deux fois.", {}, "rire"),
				],
				"interpelle": [L("Oh ! Un tout petit ! Ne bouge pas, j'arrive !", {"visites_max": 0}, "salut"), L("{surnom} ! Coucou, en bas !", {"visites_min": 1}, "salut")],
				"au_revoir": [L("À bientôt, {surnom} ! Et ne te perds pas dans les choux !", {}, "salut"), L("File ! Et reviens goûter mes tartes : une miette, et tu n'auras plus faim de la semaine.", {}, "rire")],
			}},
		{"id": "eustache_gt", "nom": "Père Eustache", "titre": "le meunier (un géant)", "maison": "moulin", "village": "geants",
			"geant": {"taille": 14.2, "vitesse": 3.4, "agenda": [[6, 12, "moulin"], [12, 14, "cour"], [14, 18, "grange"], [18, 21, "moulin"], [21, 6, "maison"]]},
			"teinte": PEAU,
			"humeur_base": 0.45, "traits": {"bavard": 0.5, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.1, "rancunier": 0.0},
			"aime": {"pain_miel": 2.0, "fromage_chevre": 2.0, "croissant": 1.5, "baguette": 1.5, "plume_vent": 1.5}, "deteste": {"vieille_botte": -1.0},
			"tics": ["Chut… je parle doucement, sinon je t'envoie au milieu de la mer.", "Le vent tourne.", "Hm hm.", "Farine et compagnie !"],
			"repliques": {
				"accueil": [
					L("(Il chuchote, et c'est encore un vent qui te décoiffe.) Bonjour, tout petit. Je suis Eustache, le meunier. Je parle tout bas, hein : la dernière fois que j'ai dit bonjour à une mouette, elle a atterri sur l'Île Crayonnée.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Approche, approche. Pas trop près des pieds. Voilà.", {"visites_min": 2}),
				],
				"humeur": [
					L("Bien. Le vent souffle du bon côté, les ailes tournent, le moulin chante. Un meunier n'a pas besoin d'autre chose.", {}),
					L("J'ai le nez qui me chatouille… Recule un peu, {surnom}. Non, plus. Encore. Ah non, fausse alerte.", {}, "rire"),
					L("Le soir, j'écoute le moulin s'arrêter. Le dernier tour d'aile, c'est le plus beau bruit du monde.", {"soir": true}),
				],
				"lui": [
					L("Je mouds le blé de la ferme depuis quarante ans. Un sac de ma farine, c'est de quoi nourrir tout un village de petits pendant un an. Et Mathurine en fait une seule tarte.", {}, "rire"),
					L("Quand j'éternue, il faut prévenir. La dernière fois, trois voiliers ont changé de cap au large de Crayonnée. Je leur ai fait des excuses. De loin.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Tu sais pourquoi j'aime le vent ? Parce que lui, il est plus grand que moi. Ça repose, de ne pas être le plus grand, de temps en temps.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Le Moulin de la Butte, c'est mon moulin. De là-haut, on voit toute l'île, et par temps clair les îles des petits, comme des miettes sur une nappe bleue.", {}),
					L("Le ponton des petits, c'est moi qui l'ai fait. Avec une pince à épiler et beaucoup de patience. Les clous étaient si petits que j'en ai avalé un. Ne le dis pas à Mathurine.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Théophile dit que les limaces ont un chef. Une limace énorme, avec une moustache. Moi, je crois qu'il ne dort pas assez.", {}, "rire"),
					L("Grand-mère dit qu'autrefois, il y avait beaucoup de géants dans l'archipel, et que les îles des petits étaient nos jardins. Puis les géants sont partis, et les petits sont arrivés. C'est une belle histoire. Peut-être vraie.", {}),
					L("Pâquerette a caché une bille dans le champ de blé. Elle me l'a dit. C'était un secret. Oups.", {}, "rire"),
				],
				"interpelle": [L("Psst ! Tout petit ! Par ici !", {"visites_max": 0}, "salut"), L("{surnom} ! Viens voir le moulin !", {"visites_min": 1})],
			}},
		{"id": "ernestine_gt", "nom": "Grand-mère Ernestine", "titre": "la doyenne de la ferme (une géante)", "maison": "fauteuil", "village": "geants",
			"geant": {"taille": 12.0, "vitesse": 2.6, "agenda": [[8, 21, "fauteuil"], [21, 8, "maison"]]},
			"teinte": PEAU,
			"humeur_base": 0.6, "traits": {"bavard": 0.9, "humour": 0.5, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.0},
			"aime": {"miel": 2.0, "tisane_lune": 2.0, "the_menthe": 1.5, "gateau_lune": 1.5, "perle": 2.0}, "deteste": {"sardine": -1.0},
			"tics": ["Mon poussin…", "De mon temps…", "Une maille à l'endroit, une maille à l'envers.", "Hm hm hm."],
			"repliques": {
				"accueil": [
					L("Approche, mon poussin. Plus près. Mes yeux ne sont plus ce qu'ils étaient : pour moi, tu es une petite tache qui parle. Une jolie petite tache. Je suis Ernestine, la grand-mère de cette maison.", {"visites_max": 1}, "salut"),
					L("Ah, te revoilà, mon poussin. Assieds-toi sur mon pied, si tu veux. C'est le seul banc à ta taille.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Je vais bien, mon poussin. J'ai mon fauteuil, ma laine et le soleil. À mon âge, c'est un royaume.", {}),
					L("Mon écharpe avance. Elle fait le tour de la maison, deux fois. Je la finirai pour l'hiver. Lequel, je ne sais pas.", {}, "rire"),
					L("Le soir, je regarde les étoiles. Elles sont plus petites que toi, et pourtant tout le monde les voit. Ça me fait penser à toi.", {"soir": true}),
				],
				"lui": [
					L("J'ai cent vingt ans, mon poussin. Pour une géante, c'est la fleur de l'âge. Enfin, une fleur un peu fanée.", {}, "rire"),
					L("Quand j'étais jeune fille, je dansais au bal des géants, sur l'Île de la Lune. Elle a sombré depuis longtemps. Il ne reste que nous, ici.", {"sujet_min": ["lui", 1]}),
					L("Je tricote pour ne pas oublier. Chaque rang, un souvenir. Le rang rouge, là, c'est le jour où Pâquerette est née. Le bleu, c'est le jour où tu es arrivé.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("Autrefois, il y avait beaucoup de géants dans l'archipel. Les îles des petits étaient nos jardins, et nos fermes. Un jour, les géants sont partis vers le grand large. Les Grandpré sont restés. Quelqu'un devait garder la ferme.", {}),
					L("Les petits nous ont oubliés, je crois. Ou ils pensent qu'on est une légende. Tant mieux : une légende, on ne vient pas lui demander de déplacer une montagne.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Mathurine cherche quelque chose dans le potager depuis ce matin. Elle a les yeux tout rouges. Va la voir, mon poussin. Les petits voient ce que les grands ne voient plus.", {}),
					L("Pâquerette joue toute seule. Ça me fend le cœur. Un ami, même tout petit, ça change une enfance.", {}),
					L("Eustache ronfle tellement fort que les vitres tremblent. Théophile dort avec du coton dans les oreilles. Du coton de géant : un mouton entier.", {}, "rire"),
				],
				"interpelle": [L("Hou hou ! Le petit, là ! Viens voir la vieille Ernestine !", {"visites_max": 0}, "salut"), L("Mon poussin ! Viens t'asseoir près de moi.", {"visites_min": 1})],
				"au_revoir": [L("Va, mon poussin. Et couvre-toi : les courants d'air, chez nous, ce sont des tempêtes.", {}, "salut")],
			}},
		{"id": "paquerette_gt", "nom": "Pâquerette", "titre": "sept ans (une petite géante)", "maison": "pres", "village": "geants", "enfant": true,
			"geant": {"taille": 9.0, "vitesse": 4.2, "agenda": [[8, 11, "mare"], [11, 13, "cour"], [13, 17, "ble"], [17, 20, "pres"], [20, 8, "maison"]]},
			"teinte": PEAU,
			"humeur_base": 0.75, "traits": {"bavard": 1.0, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.0},
			"aime": {"coquillage": 2.5, "perle": 2.5, "cerf_volant": 2.0, "glace": 2.0, "caillou_chantant": 2.0, "canard_mecanique": 2.0}, "deteste": {"vieille_botte": -1.5, "sardine": -1.0},
			"tics": ["Trop bien !", "Hi hi hi !", "T'es tout petit !", "On joue ?"],
			"surnoms": [[0, "tout-petit"], [25, "mon petit copain"], [50, "mon meilleur ami"], [75, "mon ami de poche"], [95, "mon géant à moi"]],
			"repliques": {
				"accueil": [
					L("Oh ! OH ! Maman ! Il y a un tout petit ! Il bouge ! Il parle ? Tu parles ? Je m'appelle Pâquerette, j'ai sept ans, et toi, tu es le plus petit ami du monde ! Tu veux être mon ami ? Dis oui !", {"visites_max": 1}, "salut"),
					L("Mon tout petit ami est revenu ! Hi hi ! Tu veux voir ma collection de billes ? Elles sont plus grosses que toi !", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Super bien ! J'ai vu un têtard gros comme un cochon, dans la mare ! Enfin, gros comme un cochon pour toi. Pour moi, il est riquiqui.", {}, "rire"),
					L("Un peu triste… Personne ne veut jouer à cache-cache avec moi. Maman dit que je suis trop grande pour me cacher. C'est même pas vrai.", {}),
					L("C'est bientôt l'heure de dormir. Grand-mère va me raconter l'histoire du bal sur l'Île de la Lune. Je la connais par cœur, mais je fais semblant que non.", {"soir": true}),
				],
				"lui": [
					L("Quand je serai grande, je serai encore plus grande ! Et je construirai un bateau pour aller voir les îles des petits. Sans rien écraser. Promis.", {}),
					L("Je collectionne les billes. J'en ai quarante-deux. La plus belle, c'est la bleue avec une spirale dedans. Elle s'appelle Gustave.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Ma cachette préférée, c'est le champ de blé ! Personne ne me trouve jamais. Enfin, si, tout le monde. Mais ils font semblant que non, et c'est gentil.", {}),
					L("Dans la mare, il y a des nénuphars. Pour toi, c'est des radeaux ! Tu peux sauter de l'un à l'autre ! Moi, j'ai essayé une fois. Plouf.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Tonton Théophile parle à sa citrouille. Je l'ai entendu. Il lui a dit « tu es la plus belle ». Elle n'a rien répondu. Les citrouilles sont timides.", {}, "rire"),
					L("Papa Eustache a avalé un clou du ponton. Maman ne le sait pas. Chut !", {}, "rire"),
				],
				"interpelle": [L("Coucou, tout petit ! Viens jouer !", {"visites_max": 0}, "salut"), L("{surnom} ! {surnom} ! On joue ?", {"visites_min": 1}, "salut")],
				"au_revoir": [L("Reviens vite, hein ! Promis juré craché ? Hi hi !", {}, "salut"), L("Au revoir, mon tout petit ami ! Ne te fais pas manger par un moineau !", {}, "rire")],
				"frappe": [L("Aïe ! Hi hi… non, ça fait pas mal. Ça fait des guilis ! Encore !", {}, "rire")],
			}},
		{"id": "theophile_gt", "nom": "Oncle Théophile", "titre": "le jardinier (un géant)", "maison": "potager_citrouilles", "village": "geants",
			"geant": {"taille": 13.6, "vitesse": 3.4, "agenda": [[6, 12, "potager_citrouilles"], [12, 14, "cour"], [14, 18, "verger"], [18, 20, "potager_citrouilles"], [20, 6, "maison"]]},
			"teinte": PEAU,
			"humeur_base": 0.3, "traits": {"bavard": 0.6, "humour": 0.5, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"tarte_potiron": 2.5, "graine_or": 2.0, "tomate_coeur": 2.0, "miel": 1.5}, "deteste": {"vieille_botte": -1.5, "gelee_slime": -1.5},
			"tics": ["Ma Géante…", "Ces limaces !", "Hmpf.", "Un jardinier ne dort jamais."],
			"repliques": {
				"accueil": [
					L("Hmpf ? Qui va là ? Ah ! Un tout petit ! Fais attention à mes plants, toi. Je suis Théophile, le jardinier. Et voici ma Géante. (Il montre une citrouille grosse comme une maison.) N'est-ce pas qu'elle est belle ?", {"visites_max": 1}, "salut"),
					L("Ah, {surnom}. Tu viens admirer la Géante ? Elle a encore pris un pouce cette nuit.", {"visites_min": 2}),
				],
				"humeur": [
					L("Ma Géante grossit, mes tomates rougissent, mes haricots montent jusqu'au ciel. Tout irait bien, s'il n'y avait pas ces limaces.", {}),
					L("Grognon. Les limaces ont encore mangé trois choux cette nuit. TROIS. Des choux plus gros que toi, {surnom}.", {}),
					L("Le soir, j'arrose la Géante et je lui raconte ma journée. Elle écoute très bien.", {"soir": true}),
				],
				"lui": [
					L("Je suis le frère de Mathurine. Elle fait pousser les choux, moi je fais pousser les rêves. Enfin, les citrouilles. C'est presque pareil.", {}),
					L("Mon père cultivait des citrouilles, et le père de mon père aussi. Moi, j'ai fait la plus grosse de toute la lignée : la Géante. Je l'ai pesée : elle pèse autant que moi. Ou que trois cents de tes villages.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("Le potager, c'est ma fierté. Les choux et les laitues au nord, les poireaux et les carottes à côté, les citrouilles et les tomates au sud. Les tournesols montent la garde le long de la clôture.", {}),
					L("Tu peux te glisser entre les piquets de la clôture, toi. Moi, je dois passer par la porte. Et me baisser. Et faire attention à mes tomates. La vie de géant n'est pas simple.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Les limaces se cachent sous les feuilles. Moi, je suis trop grand pour les voir. Mais toi… toi, tu les verrais. Tu es à leur hauteur.", {}),
					L("Mathurine dit que je parle trop à la Géante. C'est faux. C'est la Géante qui ne parle pas assez.", {}, "rire"),
				],
				"interpelle": [L("Hé, le tout petit ! Attention à mes plants !", {"visites_max": 0}), L("{surnom} ! Viens voir la Géante !", {"visites_min": 1})],
			}},
	]

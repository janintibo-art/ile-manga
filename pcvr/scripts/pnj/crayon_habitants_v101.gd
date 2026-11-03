extends RefCounted
## V101 : les habitants du Village des Arbres-Maisons, sur l'Île Crayonnée. Une nuit, la Grande
## Averse (une pluie d'eau claire, venue d'un nuage tout blanc) a lavé l'île : elle a fait déborder la
## Palette de pierre, et les neuf pots de couleur de l'île ont été emportés aux quatre coins de l'île.
## Depuis, tout est en noir et blanc. Les habitants, eux, ont gardé leurs couleurs (ils dormaient sous
## leurs toits) ; ils cherchent les pots, chacun de son côté.
##  - le Grand-Chêne (la Maison du Conseil) : Grand-Mère Aquarelle (la doyenne, présidente du
##    Conseil) et Gaspard Fusain (le guetteur du Belvédère, un vieux dessinateur de cartes) ;
##  - le Chêne-Pinceau : Basile Pinceau (peintre en bâtiment, et en tout le reste) et sa fille Lili ;
##  - le Chêne-Gomme : Rosalie Gomme (la jardinière) et son père, Papi Augustin (l'ancien maître
##    d'école, qui gomme tout ce qu'il écrit) ;
##  - le Chêne-Buvard : Capucine Buvard (la fleuriste) et Achille Buvard (le poète, toujours taché d'encre).
## Les quêtes (journal_v56) : « Les neuf couleurs de l'île » (Grand-Mère Aquarelle) et une quête de
## couleur par habitant qui cherche un pot (Basile, Rosalie, Capucine, Lili, Gaspard, Achille).
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même vie réglée par l'heure (les lieux :
## crayon_vie_v101.gd) ; les objets à la main : pnj/pnj_crayon_v101.gd.
## Fiche « crayon » : tenue, c, c2 (les couleurs de la tenue), chapeau, objet.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "À bientôt, {surnom} ! Et regarde bien partout : un pot de couleur, ça se cache n'importe où.", "si": {}, "geste": "salut"},
		{"t": "Bonne route ! Si tu croises une couleur, ramène-la à la Palette.", "si": {}, "geste": "salut"},
		{"t": "À plus tard ! Attention aux traits d'encre, ils glissent quand il a plu.", "si": {}},
		{"t": "Au revoir, {surnom}. Que tes couleurs tiennent bon !", "si": {}, "geste": "salut"},
	],
	"frappe": [
		{"t": "Aïe ! Hé ! On ne tape pas les gens, même en noir et blanc !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Ouille ! Tu vas me faire déborder du trait !", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Hé ! Ça ne se fait pas ! Va donc te calmer à l'Étang Gommé.", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Oh, merci, {surnom}. C'est gentil.", "si": {}},
		{"t": "Un cadeau ! Ça fait une petite tache de couleur dans ma journée.", "si": {}},
	],
	"cadeau_aime": [
		{"t": "{dernier_cadeau} ! Oh, {surnom}, ça me met des couleurs plein le cœur !", "si": {}, "geste": "rire"},
		{"t": "{dernier_cadeau} ! Merci ! Tu sais faire plaisir, toi.", "si": {}, "geste": "rire"},
	],
	"cadeau_deteste": [{"t": "Hum… merci. Je vais le ranger. Tout au fond. Derrière la gomme.", "si": {}, "humeur": -0.1}],
	"cadeau_refus": [{"t": "Une arme ? Ici ? Oh non. Ici, les seules choses qui piquent, ce sont les crayons bien taillés.", "si": {}}],
	"souvenir": [{"t": "Si je me souviens de toi ? Bien sûr ! Tu es en couleurs, ça se remarque, par ici.", "si": {}}],
	"quete_inconnue": [{"t": "Moi ? Je ne t'ai rien demandé… Mais Grand-Mère Aquarelle, devant la Palette, a sûrement besoin d'aide.", "si": {}}],
	"blague": [
		{"t": "Qu'est-ce qui est noir et blanc et qui rougit ? Un zèbre qui a fait une bêtise !", "si": {}, "geste": "rire"},
		{"t": "Pourquoi le crayon est-il toujours fatigué ? Parce qu'il a mauvaise mine !", "si": {}, "geste": "rire"},
		{"t": "Que dit une gomme à un crayon ? « Arrête de faire des bêtises, c'est moi qui ramasse ! »", "si": {}, "geste": "rire"},
		{"t": "Quel est le comble pour un peintre ? Avoir une peur bleue… et rire jaune !", "si": {}, "geste": "rire"},
		{"t": "Pourquoi les arbres-maisons ne déménagent jamais ? Parce qu'ils ont des racines !", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Choisis ! Tout est fait main, ici, au village. Tu as {pieces} pièces.", "si": {}}],
	"boutique_fermee": [{"t": "Pas aujourd'hui. Reviens quand on sera de nouveau amis.", "si": {}, "geste": "colere"}],
	"achat": [{"t": "Et voilà : {objet}, pour {prix} pièces. Merci !", "si": {}, "geste": "salut"}],
	"achat_pauvre": [{"t": "C'est {prix} pièces, et tu en as {pieces}. Repasse plus tard, je te le garde.", "si": {}}],
	"achat_deja": [{"t": "Tu en as déjà un !", "si": {}}],
	"achat_plein": [{"t": "Ton sac est plein à craquer, {surnom}.", "si": {}}],
	"vente": [{"t": "Pour ça ? Je t'en donne {prix} pièces.", "si": {}}],
	"vente_lot": [{"t": "Tout le lot ? Allez : {prix} pièces.", "si": {}}],
	"marchande_oui": [{"t": "Bon, d'accord. Pour toi, je fais un prix pastel.", "si": {}, "geste": "rire"}],
	"marchande_non": [{"t": "Non, non. Mes prix sont déjà tout petits, comme des miettes de gomme.", "si": {}}],
	"marchande_deja": [{"t": "On a déjà marchandé aujourd'hui. Demain, peut-être.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Oh, chouette !", "Ha ha !", "Quelle couleur !", "Formidable !"],
		"neutre": ["Bon.", "Hm.", "Voyons…", "Eh bien…"],
		"triste": ["Bof…", "Pfff…", "Tout gris…", "Hélas…"],
		"colere": ["Ça suffit !", "Grrr.", "Non mais !", "Quelle mine !"],
	},
	"tics": ["Tout en noir et blanc…", "Il nous faut nos couleurs.", "Trait pour trait.", "Ça va revenir, ça va revenir."],
	"humeur_mots": [[0.6, "haut en couleur"], [0.25, "de bonne humeur"], [-0.25, "un peu gris"], [-0.6, "tout délavé"], [-2.0, "noir de colère"]],
	"surnoms": [[0, "voyageur"], [25, "ami"], [50, "ami des couleurs"], [75, "notre coloriste"], [95, "grand coloriste de l'île"]],
}

## Peaux, cheveux, yeux
const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [0.5, 0.34, 0.24]]
const NOIR := [0.06, 0.05, 0.05]
const BRUN := [0.25, 0.16, 0.1]
const CHATAIN := [0.38, 0.24, 0.14]
const ROUX := [0.62, 0.28, 0.12]
const BLOND := [0.86, 0.72, 0.42]
const BLANC := [0.93, 0.92, 0.9]
const GRIS := [0.62, 0.61, 0.6]
const Y_BRUN := [0.3, 0.18, 0.1]
const Y_NOIR := [0.14, 0.1, 0.08]
const Y_VERT := [0.3, 0.5, 0.28]
const Y_BLEU := [0.3, 0.45, 0.62]
const Y_NOISETTE := [0.42, 0.3, 0.14]
## Les couleurs des pots de l'île
const BLEU := [0.16, 0.36, 0.72]
const VERT := [0.22, 0.52, 0.24]
const ROUGE := [0.8, 0.14, 0.12]
const JAUNE := [0.96, 0.8, 0.2]
const MARRON := [0.48, 0.3, 0.16]
const VIOLET := [0.46, 0.26, 0.62]
const ORANGE := [0.95, 0.52, 0.14]
const TURQUOISE := [0.16, 0.66, 0.66]
const ROSE := [0.94, 0.52, 0.66]
const ECRU := [0.95, 0.93, 0.87]


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
	out["groupe"] = "crayon"
	return out


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out


static func _all() -> Array:
	return [
		# ================================================================ le Grand-Chêne (le Conseil)
		{"id": "aquarelle", "nom": "Grand-Mère Aquarelle", "titre": "doyenne du village et présidente du Conseil", "maison": "porte_grand", "village": "crayon",
			"agenda": [[7, 12, "palette_1"], [12, 14, "grand_terrasse"], [14, 19, "palette_1"], [19, 21, "grand_terrasse"], [21, 7, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chignon", "yeux": Y_BLEU, "haut": [0.62, 0.56, 0.78], "vieux": true, "taille": 0.92},
			"teinte": PEAU[1],
			"crayon": {"tenue": "doyenne", "c": [0.62, 0.56, 0.78], "c2": [0.95, 0.9, 0.8], "chapeau": ""},
			"femme": true,
			"humeur_base": 0.45, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.5, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"the_menthe": 2.5, "miel": 2.0, "gateau_miel": 2.0, "bouquet_tournesols": 2.0, "fleur_lune": 1.5}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Mon petit…", "Du calme, du calme.", "Chaque chose en son temps, chaque couleur à sa place.", "Une goutte d'eau, deux gouttes de couleur."],
			"surnoms": [[0, "mon petit"], [25, "mon petit pinceau"], [50, "ma petite couleur"], [75, "mon arc-en-ciel"], [95, "le coloriste de l'île"]],
			"repliques": {
				"accueil": [
					L("Oh ! Un visiteur… et en couleurs ! Quelle joie de voir du bleu et du rouge, depuis le temps. Je suis Grand-Mère Aquarelle, la doyenne du village. Bienvenue au Village des Arbres-Maisons. Enfin, à ce qu'il en reste : tout est devenu gris comme une vieille page.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Viens, approche. Tu as vu la Palette ? Les godets sont encore secs. Mais je sens que ça va changer.", {"visites_min": 2, "q56": "cr_couleurs="}),
					L("{surnom} ! Alors, ces couleurs ? Chaque pot que tu rapportes, c'est un morceau de l'île qui se réveille.", {"visites_min": 2, "q56": "cr_couleurs=en_cours"}, "rire"),
					L("{surnom}… Regarde autour de toi. Le vert des feuilles, le bleu de l'étang, le rouge des coquelicots. Grâce à toi. Je pourrais pleurer. D'ailleurs, je pleure un peu. C'est de l'aquarelle, ça s'efface.", {"visites_min": 2, "q56": "cr_couleurs=finie"}, "rire"),
				],
				"humeur": [
					L("Patiente, mon petit. À mon âge, on a appris qu'après la pluie, les couleurs reviennent toujours. Il faut juste les aider un peu.", {"q56": "cr_couleurs="}),
					L("Pleine d'espoir ! Une couleur de plus, et je retrouve mes vingt ans. Enfin, mes soixante-dix. C'est déjà bien.", {"q56": "cr_couleurs=en_cours"}, "rire"),
					L("Le soir, je m'assois sur la terrasse du Conseil et je regarde la clairière. En noir et blanc, elle est jolie aussi. Mais elle a l'air de s'ennuyer.", {"soir": true}),
					L("Radieuse ! Toute l'île en couleurs, et des habitants qui chantent sur les passerelles. Le Conseil a voté une fête. À l'unanimité. Même Gaspard a levé la main.", {"q56": "cr_couleurs=finie"}, "rire"),
				],
				"lui": [
					L("Je suis née dans le Grand-Chêne, il y a soixante-quinze ans. À l'époque, il n'y avait qu'une cabane et une échelle de corde. Mon père a construit l'escalier. Ma mère a peint la première porte. En bleu.", {}),
					L("Pourquoi « Aquarelle » ? Parce que, petite, je pleurais pour un rien, et mes larmes faisaient couler les dessins. Mon père disait : « Tu es une vraie aquarelle. » C'est resté. Je pleure moins. Un peu moins.", {"sujet_min": ["lui", 1]}, "rire"),
					L("Le Pinceau de l'île, celui que je t'ai confié, c'est le pinceau des doyens. Il passe de main en main depuis la fondation du village. Il ne peint qu'avec les couleurs de la Palette. Prends-en soin.", {"sujet_min": ["lui", 2]}),
				],
				"ile": [
					L("La Palette de pierre, au milieu de la clairière, c'est le cœur de l'île. Chaque couleur vit dans un pot, dans son godet numéroté. Quand les neuf pots sont à leur place, toute l'île est en couleurs. Quand ils manquent…", {}),
					L("La Grande Averse, c'était il y a dix jours. Un nuage tout blanc, venu de la mer. Il a plu de l'eau claire, si claire qu'elle a lavé les couleurs de tout. La Palette a débordé, et les pots sont partis avec l'eau. Aux quatre coins de l'île.", {"sujet_min": ["ile", 1]}),
					L("Les quatre chênes du village ont plus de mille ans. Le Grand-Chêne, le Pinceau, la Gomme et le Buvard. On leur a donné des noms d'outils de dessin parce que, vus du Belvédère, ils ressemblent à quatre crayons plantés dans la clairière.", {"sujet_min": ["ile", 2]}),
				],
				"rumeur": [
					L("Le panier de la poulie, sous la terrasse du Conseil… Gaspard jure qu'il a entendu quelque chose tomber dedans, la nuit de l'Averse. Je n'ai plus la force de le hisser. Toi, peut-être ?", {"q56": "cr_couleurs="}),
					L("Lili Pinceau a creusé la moitié de la plage pour retrouver le jaune. Son père dit qu'elle a trouvé trois coquillages, un vieux seau et beaucoup de sable dans ses chaussures.", {}, "rire"),
					L("Augustin dit qu'il a vu briller du rose sur une passerelle. Mais Augustin voit des choses briller partout depuis qu'il a perdu ses lunettes. Elles sont sur son nez.", {"sujet_min": ["rumeur", 1]}, "rire"),
				],
				"interpelle": [L("Mon petit ! Viens par ici, viens voir la Palette.", {"visites_max": 0}, "salut"), L("{surnom} ! Te voilà !", {"visites_min": 1}, "salut")],
			}},
		{"id": "fusain", "nom": "Gaspard Fusain", "titre": "guetteur du Belvédère des Couleurs", "maison": "porte_grand", "village": "crayon",
			"agenda": [[6, 12, "belvedere_vue"], [12, 14, "belvedere_banc"], [14, 20, "belvedere_vue"], [20, 22, "grand_terrasse"], [22, 6, "maison"]],
			"azur": {"cheveux": GRIS, "coiffure": "court", "barbe": "courte", "yeux": Y_NOISETTE, "haut": [0.28, 0.3, 0.34], "vieux": true, "carrure": 1.05},
			"teinte": PEAU[2],
			"crayon": {"tenue": "guetteur", "c": [0.28, 0.3, 0.34], "c2": [0.62, 0.42, 0.22], "chapeau": "casquette", "objet": "telescope_portable"},
			"humeur_base": 0.35, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"boussole": 2.5, "the_menthe": 1.5, "pomme": 1.5, "carte_tresor": 2.0}, "deteste": {},
			"tics": ["Je vois tout, d'ici.", "Hm. Au nord-nord-est.", "Trait de fusain, trait de génie.", "Le vent tourne."],
			"surnoms": [[0, "petit"], [25, "matelot de vigie"], [50, "mon second guetteur"], [75, "œil de lynx"], [95, "guetteur d'honneur"]],
			"repliques": {
				"accueil": [
					L("Hm ? Un visiteur, au Belvédère. Ça faisait longtemps. Gaspard Fusain, guetteur. Je surveille l'île depuis là-haut avec ma longue-vue. Avant, je dessinais les cartes. Maintenant, je regarde le gris.", {"visites_max": 1}),
					L("{surnom}. Tu as de bonnes jambes, pour monter jusqu'ici. Viens voir la vue.", {"visites_min": 2}),
				],
				"humeur": [
					L("Vigilant. Toujours vigilant. Quand on guette, on n'a pas d'humeur : on a des yeux.", {}),
					L("Content, je crois. Ce matin, j'ai vu une tache de couleur s'étaler sur l'île, depuis le Belvédère. Comme une goutte d'encre sur du papier buvard. C'était beau.", {"a_trouve": "crayon_pots_1"}),
					L("Le soir, la longue-vue ne sert plus à rien. Alors je descends au Conseil, et je dessine ce que j'ai vu dans la journée. Au fusain, évidemment.", {"soir": true}),
				],
				"lui": [
					L("J'ai dessiné les cartes de toutes les îles de l'archipel. Toutes. Avec un bâton de fusain et une règle. Les gens disaient que mes cartes étaient trop jolies pour qu'on s'en serve. Ils s'en servaient quand même.", {}),
					L("Grand-Mère Aquarelle et moi, on a été à l'école ensemble. Elle pleurait sur ses dessins, moi je les noircissais. Le maître, c'était le père d'Augustin. Il nous gommait tous les deux.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("D'ici, on voit toute l'île : le Mont Fusain au nord, l'Étang Gommé et sa cascade, le Bois des Hachures à l'ouest, les Prés Blancs à l'est, la Grève au sud. Un vrai dessin. Il manque juste les couleurs.", {}),
					L("Le Mont Fusain porte mon nom, ou c'est moi qui porte le sien. On ne sait plus. Il est gris foncé, même quand l'île a ses couleurs. Enfin, presque : au printemps, la bruyère le rend violet.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Avec ma longue-vue, j'ai vu un petit éclat, tout là-haut, au sommet du Mont Fusain. Ça brillait. Pas comme une pierre. Comme un pot. Regarde toi-même, si tu veux.", {"q56": "cr_violet="}),
					L("La nuit de l'Averse, j'ai entendu quelque chose tomber dans le panier de la poulie, sous la terrasse du Conseil. Un « ploc ». Un ploc de pot. Je suis sûr de mon ploc.", {}),
				],
				"interpelle": [L("Hm. Toi. Regarde un peu la vue.", {})],
			}},
		# ================================================================ le Chêne-Pinceau
		{"id": "basile_pinceau", "nom": "Basile Pinceau", "titre": "peintre en bâtiment (et en tout le reste)", "maison": "porte_pinceau", "village": "crayon",
			"agenda": [[7, 12, "etang_rive"], [12, 14, "pinceau_terrasse"], [14, 19, "etang_rive"], [19, 21, "palette_banc_1"], [21, 7, "maison"]],
			"azur": {"cheveux": CHATAIN, "coiffure": "court", "barbe": "courte", "yeux": Y_BRUN, "haut": [0.95, 0.94, 0.9], "carrure": 1.15},
			"teinte": PEAU[2],
			"crayon": {"tenue": "salopette", "c": [0.94, 0.93, 0.88], "c2": [0.2, 0.4, 0.75], "chapeau": "casquette", "objet": "pinceau_geant"},
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.8, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"bombe_peinture": 2.5, "pomme": 1.5, "miel": 1.5, "glace": 1.5}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Une couche, deux couches…", "Ça va sécher.", "Bleu ciel ou bleu nuit ?", "Attention, c'est frais !"],
			"surnoms": [[0, "l'ami"], [25, "mon apprenti"], [50, "mon collègue"], [75, "mon associé"], [95, "le meilleur peintre de l'archipel (après moi)"]],
			"repliques": {
				"accueil": [
					L("Salut ! Basile Pinceau, peintre. En bâtiment, en portes, en volets, en bateaux, en tout. Enfin, quand il y a de la peinture. Depuis l'Averse, je peins avec de l'eau. Ça ne se voit pas beaucoup.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens m'aider à chercher ? Je suis sûr que le bleu est là, dans l'étang. Il me nargue.", {"visites_min": 2, "q56": "cr_bleu="}),
					L("{surnom} ! Le bleu ! Regarde l'étang, il est BLEU ! Je l'ai repeint trois fois dans ma tête, cette nuit, pour fêter ça.", {"visites_min": 2, "q56": "cr_bleu=finie"}, "rire"),
				],
				"humeur": [
					L("Un peu déprimé. Un peintre sans couleurs, c'est comme un boulanger sans farine. Je pétris du vent.", {"q56": "cr_bleu="}),
					L("En pleine forme ! Le bleu est revenu, le ciel se reflète de nouveau dans l'étang. J'ai envie de tout repeindre. Même Lili. Elle n'est pas d'accord.", {"q56": "cr_bleu=finie"}, "rire"),
					L("Le soir, je m'assois près de la Palette, et je compte les godets pleins. C'est mon nouveau passe-temps.", {"soir": true}),
				],
				"lui": [
					L("J'ai peint toutes les portes du village. La bleue, c'est la nôtre. Enfin, c'était. Elle est gris clair, maintenant. Lili dit que c'est « bleu fantôme ».", {}, "rire"),
					L("Ma femme, Mélisse, est partie peindre les phares des autres îles. Elle revient à la fin de l'été. Si elle voit la maison en noir et blanc, elle va croire que je n'ai rien fait de toute l'année.", {"sujet_min": ["lui", 1]}),
					L("Mon grand pinceau, là ? C'est un pinceau à façade. Il peut repeindre une maison en une matinée. Je l'ai appelé Bertrand. Un pinceau, ça a besoin d'un nom.", {"sujet_min": ["lui", 2]}, "rire"),
				],
				"ile": [
					L("L'Étang Gommé, on l'appelle comme ça parce que la nuit, il efface les reflets. Le matin, ils reviennent. C'est un étang très soigneux.", {}),
					L("Le bleu de l'île, c'est le pot numéro un. Le premier godet de la Palette. Sans bleu, pas de ciel dans l'étang, pas de ruisseau, pas de cascade. Juste des traits.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le pot de bleu, je l'ai vu flotter sur l'étang, le lendemain de l'Averse ! Il est allé se coincer sur un nénuphar, loin du bord. Moi, je nage comme un caillou. Un caillou peint.", {"q56": "cr_bleu="}),
					L("Achille écrit un poème sur la Grande Averse. Il en est à la page quarante. Il n'a pas encore fini la première goutte.", {}, "rire"),
				],
				"interpelle": [L("Hé ! Attention, c'est frais ! Ah non, c'est vrai, il n'y a plus de peinture.", {}, "rire")],
			}},
		{"id": "lili", "nom": "Lili Pinceau", "titre": "fille de Basile (9 ans)", "maison": "porte_pinceau", "village": "crayon",
			"agenda": [[8, 12, "plage_chateau"], [12, 14, "pinceau_terrasse_2"], [14, 18, ["plage_chateau", "plage_bord"]], [18, 20, "balancoire"], [20, 8, "maison"]],
			"azur": {"cheveux": ROUX, "coiffure": "tresse", "yeux": Y_VERT, "haut": [0.96, 0.8, 0.22], "taille": 0.74},
			"teinte": PEAU[0],
			"crayon": {"tenue": "enfant", "c": [0.96, 0.8, 0.22], "c2": [0.2, 0.4, 0.75], "chapeau": ""},
			"femme": true,
			"humeur_base": 0.7, "traits": {"bavard": 1.0, "humour": 0.9, "curiosite": 1.0, "susceptible": 0.3, "rancunier": 0.0},
			"aime": {"glace": 2.5, "coquillage": 2.5, "cerf_volant": 2.5, "pomme": 1.5, "gateau_miel": 2.0}, "deteste": {"champignon": -0.5},
			"tics": ["Trop bien !", "Pourquoi ?", "Moi aussi je veux !", "Regarde, regarde !"],
			"surnoms": [[0, "toi"], [25, "copain"], [50, "mon super copain"], [75, "mon meilleur copain"], [95, "mon héros en couleurs"]],
			"repliques": {
				"accueil": [
					L("Oh ! T'es en COULEURS ! Comment t'as fait ? Moi, c'est Lili. Lili Pinceau. J'ai neuf ans. Et demi. Je cherche le jaune. Le jaune du sable, le jaune du soleil, le jaune de tout !", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens chercher le jaune avec moi ? J'ai un seau, une pelle et beaucoup de patience. Enfin, un peu de patience.", {"visites_min": 2, "q56": "cr_jaune="}),
					L("{surnom} ! Le sable est JAUNE ! Comme avant ! J'ai fait un château jaune, avec un drapeau jaune, et un roi jaune. Le roi, c'est un coquillage.", {"visites_min": 2, "q56": "cr_jaune=finie"}, "rire"),
				],
				"humeur": [
					L("Un peu triste. Le soleil est blanc, le sable est blanc, mes chaussettes sont blanches. Avant, elles étaient à rayures.", {"q56": "cr_jaune="}),
					L("TROP CONTENTE ! Le jaune est revenu ! J'ai roulé dans le sable pour vérifier. Il est vraiment jaune. Papa dit que moi aussi, maintenant.", {"q56": "cr_jaune=finie"}, "rire"),
					L("Le soir, je fais de la balançoire sous le Chêne-Gomme. Papi Augustin me pousse. Il dit que si je vais assez haut, je toucherai la passerelle. Je n'ai pas encore réussi.", {"soir": true}),
				],
				"lui": [
					L("Plus tard, je serai peintre, comme Papa. Ou guetteuse, comme Gaspard. Ou pot de peinture. Non, pas pot de peinture.", {}, "rire"),
					L("Maman peint les phares des autres îles. Elle m'a promis de m'emmener, l'an prochain. Je prendrai mes crayons. Tous. Même le blanc, qui ne sert à rien.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La balançoire, sous le Chêne-Gomme, c'est la meilleure de l'archipel. Elle est accrochée à la terrasse ! Quand on va très haut, on voit la mer.", {}),
					L("Sur la Grève Blanche, il y a des coquillages qui chantent. Enfin, il faut les mettre contre l'oreille. Et il faut avoir beaucoup d'imagination.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le pot de jaune, je l'ai vu rouler sur la plage le matin après l'Averse ! Il est allé tout au bout, vers l'ouest, dans mon grand château de sable. Mais la marée a tout recouvert, et maintenant je ne sais plus où est la porte du château.", {"q56": "cr_jaune="}),
					L("Papi Augustin dit qu'il a vu un éclat rose sur une passerelle. Moi, je l'ai vu aussi ! Enfin, je crois. C'était peut-être un papillon.", {}),
				],
				"interpelle": [L("Hé ! T'es en couleurs ! Viens !", {}, "salut"), L("Regarde, regarde !", {}, "rire")],
			}},
		# ================================================================ le Chêne-Gomme
		{"id": "rosalie_gomme", "nom": "Rosalie Gomme", "titre": "jardinière du village", "maison": "porte_gomme", "village": "crayon",
			"agenda": [[7, 12, "bois_lisiere"], [12, 14, "gomme_terrasse"], [14, 19, "bois_lisiere"], [19, 21, "palette_banc_2"], [21, 7, "maison"]],
			"azur": {"cheveux": BRUN, "coiffure": "queue", "yeux": Y_VERT, "haut": [0.36, 0.56, 0.32]},
			"teinte": PEAU[3],
			"crayon": {"tenue": "jardiniere", "c": [0.9, 0.86, 0.76], "c2": [0.3, 0.5, 0.26], "chapeau": "paille", "objet": "arrosoir"},
			"femme": true,
			"humeur_base": 0.5, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.7, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"graines": 2.5, "fleur_lune": 2.0, "miel": 1.5, "pomme": 1.5, "bouquet_tournesols": 2.0}, "deteste": {"vieille_botte": -0.5},
			"tics": ["Ça pousse, ça pousse.", "Chut, elles écoutent.", "Un peu d'eau, un peu de soleil.", "Ne rien effacer !"],
			"surnoms": [[0, "petite graine"], [25, "petite pousse"], [50, "mon beau plant"], [75, "ma plus belle fleur"], [95, "jardinier de cœur"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Rosalie Gomme, la jardinière. Je m'occupe des jardinières du village, des haies, des arbres, de tout ce qui pousse. Enfin, tout ce qui pousse en gris, maintenant. Les plantes ont l'air d'avoir froid.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Le vert me manque tellement. Les feuilles sont blanches comme du papier. Les chenilles ne savent plus quoi manger.", {"visites_min": 2, "q56": "cr_vert="}),
					L("{surnom} ! Regarde le bois ! Tout vert ! Les feuilles respirent, les mousses brillent, les chenilles ont repris leur goûter.", {"visites_min": 2, "q56": "cr_vert=finie"}, "rire"),
				],
				"humeur": [
					L("Inquiète pour mes plantes. Sans vert, elles ne savent plus qu'elles sont des plantes. Hier, une fougère s'est prise pour une plume.", {"q56": "cr_vert="}),
					L("Heureuse ! Le vert est revenu, et avec lui, l'odeur de la mousse. Je ne savais pas qu'une couleur pouvait sentir. Le vert sent bon.", {"q56": "cr_vert=finie"}),
					L("Le soir, je m'assois près de la Palette, et j'écoute pousser l'herbe. Il faut beaucoup de silence.", {"soir": true}),
				],
				"lui": [
					L("Mon père, c'est Augustin, l'ancien maître d'école. Il gomme tout ce qu'il écrit. C'est pour ça qu'on s'appelle Gomme. Moi, je n'efface rien : je plante.", {}),
					L("Les fleurs des jardinières, c'est moi qui les ai semées. Rouge chez les Buvard, jaune chez les Pinceau, bleu au Conseil. Enfin, c'était ça. Maintenant, c'est blanc, blanc et blanc.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Le Bois des Hachures, à l'ouest, s'appelle comme ça parce que ses ombres sont faites de petits traits. Quand on marche dedans, on a l'impression d'être dans un dessin à la plume.", {}),
					L("Au fond du bois, il y a la Souche Creuse, la plus vieille souche de l'île. On dit que c'était le cinquième géant du village, avant la foudre.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le pot de vert… je crois qu'il a roulé jusqu'à la Souche Creuse, au fond du Bois des Hachures. Je n'ose pas y aller : il y a un gros hibou dedans, et il me regarde de travers.", {"q56": "cr_vert="}),
					L("Capucine dit que ses coquelicots sont tristes. Moi, je crois qu'ils boudent. Un coquelicot blanc, c'est un coquelicot vexé.", {}, "rire"),
				],
				"interpelle": [L("Psst… Tu as vu des feuilles vertes, toi ?", {}, "salut")],
			}},
		{"id": "augustin", "nom": "Papi Augustin Gomme", "titre": "ancien maître d'école du village", "maison": "porte_gomme", "village": "crayon",
			"agenda": [[8, 11, "palette_banc_3"], [11, 17, ["gomme_terrasse", "palette_banc_3"]], [17, 20, "balancoire_pousse"], [20, 8, "maison"]],
			"azur": {"cheveux": BLANC, "coiffure": "chauve", "barbe": "longue", "yeux": Y_BRUN, "haut": [0.62, 0.52, 0.4], "vieux": true, "lunettes": true, "taille": 0.95},
			"teinte": PEAU[1],
			"crayon": {"tenue": "maitre", "c": [0.42, 0.32, 0.24], "c2": [0.7, 0.18, 0.16], "chapeau": "beret"},
			"accessoire": "livre",
			"humeur_base": 0.5, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"the_menthe": 2.5, "partition": 1.5, "grimoire": 2.0, "gateau_miel": 2.0, "boussole": 1.0}, "deteste": {},
			"tics": ["Bien. Très bien.", "Pas de bavardage !", "Je gomme et je recommence.", "Où sont mes lunettes ?"],
			"surnoms": [[0, "mon petit élève"], [25, "bon élève"], [50, "premier de la classe"], [75, "mon meilleur élève"], [95, "le tableau d'honneur"]],
			"repliques": {
				"accueil": [
					L("Bonjour, bonjour ! Augustin Gomme, ancien maître d'école. J'ai appris à lire à tout le village. À écrire, aussi. Et surtout à gommer. (Il remonte ses lunettes.) Vous êtes en couleurs ? C'est très bien. Dix sur dix.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Asseyez-vous. Non, pas sur mon livre. À côté.", {"visites_min": 2}, "rire"),
				],
				"humeur": [
					L("Philosophe. Tout est en noir et blanc, comme un vieux cahier. J'ai passé cinquante ans devant un tableau noir : le gris, je connais.", {}),
					L("Content ! Une couleur de plus, c'est comme une bonne note : ça fait chaud au cœur, même à mon âge.", {"a_trouve": "crayon_pots_1"}, "rire"),
					L("Le soir, je pousse Lili sur la balançoire. Elle crie « plus haut ! ». Je crie « plus doucement ! ». On ne s'entend jamais. C'est très agréable.", {"soir": true}, "rire"),
				],
				"lui": [
					L("Je gomme tout ce que j'écris. Tout. Mes lettres, mes listes de courses, mes mémoires. Cinquante ans de mémoires, gommées. Il me reste une gomme toute petite et des souvenirs tout neufs.", {}, "rire"),
					L("Ma fille Rosalie fait pousser tout ce qu'elle touche. Moi, j'efface tout ce que je touche. Sa mère disait qu'on était les deux bouts du même crayon.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("La Palette de pierre a neuf godets, numérotés de un à neuf. Un, le bleu. Deux, le vert. Trois, le rouge. Quatre, le jaune. Cinq, le brun. Six, le violet. Sept, l'orange. Huit, le turquoise. Neuf, le rose. Je l'ai fait réciter à tous mes élèves.", {}),
					L("Le Ruisseau Pointillé file jusqu'à la mer, à l'est. Son embouchure, c'est là que tout ce qui roule finit par s'arrêter. Les cailloux, les feuilles, les pots… Allez voir, à tout hasard.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("J'ai vu briller du rose, sur la passerelle au-dessus de l'entrée du village. Entre deux planches. Rosalie dit que j'ai besoin de nouvelles lunettes. Ce sont des lunettes neuves. De quarante ans.", {}),
					L("Le turquoise ? Le pot numéro huit ? Il a dû suivre le Ruisseau Pointillé jusqu'à la mer. Tout ce qui roule sur cette île finit à l'embouchure. C'est de la géographie élémentaire.", {"sujet_min": ["rumeur", 1]}),
				],
				"interpelle": [L("Vous, là-bas ! Approchez, je ne mords pas. Je gomme, c'est tout.", {}, "salut")],
			}},
		# ================================================================ le Chêne-Buvard
		{"id": "capucine_buvard", "nom": "Capucine Buvard", "titre": "fleuriste du village", "maison": "porte_buvard", "village": "crayon",
			"agenda": [[7, 12, "pres_fleurs"], [12, 14, "buvard_terrasse"], [14, 19, "pres_fleurs"], [19, 21, "buvard_terrasse"], [21, 7, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "boucles", "yeux": Y_NOIR, "haut": [0.86, 0.3, 0.3]},
			"teinte": PEAU[4],
			"crayon": {"tenue": "fleuriste", "c": [0.96, 0.92, 0.84], "c2": [0.82, 0.2, 0.2], "chapeau": "capeline", "objet": "panier"},
			"femme": true,
			"humeur_base": 0.55, "traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.6, "susceptible": 0.5, "rancunier": 0.1},
			"aime": {"bouquet_tournesols": 2.5, "fleur_lune": 2.5, "miel": 1.5, "graines": 2.0}, "deteste": {"champignon": -0.5},
			"tics": ["Oh, une fleur !", "Ça sent bon, non ?", "Rouge, il me faut du rouge.", "Un bouquet, deux bouquets…"],
			"surnoms": [[0, "petit bouton"], [25, "mon petit bouquet"], [50, "ma jolie fleur"], [75, "mon coquelicot"], [95, "le plus beau bouquet de l'île"]],
			"repliques": {
				"accueil": [
					L("Bonjour ! Capucine Buvard, fleuriste. Enfin, fleuriste en noir et blanc, depuis l'Averse. Mes bouquets ressemblent à des faire-part. Je ne vends plus rien.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Tu viens me voir aux Prés ? Il y a des milliers de fleurs. Toutes blanches. On dirait un champ de neige qui sent la rose.", {"visites_min": 2, "q56": "cr_rouge="}),
					L("{surnom} ! Les coquelicots ! Ils sont ROUGES ! J'en ai fait un bouquet si rouge qu'Achille a écrit trois poèmes dessus.", {"visites_min": 2, "q56": "cr_rouge=finie"}, "rire"),
				],
				"humeur": [
					L("Triste. Une fleuriste sans couleurs, c'est une fleuriste qui vend de l'odeur. Ça ne se met pas dans un vase.", {"q56": "cr_rouge="}),
					L("Ravie ! Le rouge est revenu dans les prés. Les abeilles sont revenues aussi. Elles ne venaient plus : elles ne trouvaient pas les fleurs.", {"q56": "cr_rouge=finie"}, "rire"),
					L("Le soir, Achille me lit ses poèmes sur la terrasse. Je fais semblant de dormir pendant les longs. Il fait semblant de ne pas voir.", {"soir": true}, "rire"),
				],
				"lui": [
					L("J'ai épousé Achille parce qu'il m'a écrit un poème sur une capucine. La fleur, pas moi. Mais j'ai cru que c'était moi. Il ne m'a jamais détrompée.", {}, "rire"),
					L("Notre nom, Buvard, vient de l'arrière-grand-père d'Achille. Il fabriquait le papier buvard du village. Achille, lui, fabrique surtout des taches.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Les Prés Blancs, à l'est. Il y a des coquelicots, des bleuets, des marguerites. Enfin, il y aura. Avant l'Averse, on les appelait les Prés Fleuris.", {}),
					L("Mon épouvantail, au milieu des prés, s'appelle Monsieur Paille. Il ne fait peur à personne. Les corbeaux s'assoient sur ses bras pour bavarder.", {"sujet_min": ["ile", 1]}, "rire"),
				],
				"rumeur": [
					L("Le pot de rouge… Un lapin l'a fait rouler, j'en suis sûre. Je l'ai vu filer vers Monsieur Paille, mon épouvantail, au milieu des Prés. Mais les herbes sont si hautes ! Et moi, j'ai peur des lapins. Ils ont de trop grandes oreilles.", {"q56": "cr_rouge="}),
					L("Gaspard regarde l'île toute la journée avec sa longue-vue. S'il y a un pot quelque part, il le sait. Il ne le dit qu'à ceux qui montent jusqu'au Belvédère.", {}),
				],
				"interpelle": [L("Bonjour ! Une fleur ? Elle est blanche, mais elle sent bon.", {}, "salut")],
			}},
		{"id": "achille", "nom": "Achille Buvard", "titre": "poète du village (toujours taché d'encre)", "maison": "porte_buvard", "village": "crayon",
			"agenda": [[8, 12, "cascade_rocher"], [12, 14, "buvard_terrasse_2"], [14, 18, "cascade_rocher"], [18, 21, "palette_banc_4"], [21, 8, "maison"]],
			"azur": {"cheveux": NOIR, "coiffure": "long", "barbe": "moustache", "yeux": Y_NOIR, "haut": [0.2, 0.2, 0.26], "taille": 1.04},
			"teinte": PEAU[5],
			"crayon": {"tenue": "poete", "c": [0.18, 0.18, 0.24], "c2": [0.9, 0.86, 0.78], "chapeau": "beret"},
			"accessoire": "livre",
			"humeur_base": 0.4, "traits": {"bavard": 1.0, "humour": 0.5, "curiosite": 0.8, "susceptible": 0.7, "rancunier": 0.2},
			"aime": {"partition": 2.5, "grimoire": 2.0, "fleur_lune": 2.0, "the_menthe": 1.5, "plume_ara": 2.0}, "deteste": {"soda_neon": -0.5},
			"tics": ["Ô…", "Quelle rime !", "Attends, je note.", "Hélas, hélas."],
			"surnoms": [[0, "lecteur"], [25, "ami des rimes"], [50, "ma muse"], [75, "mon héros en alexandrins"], [95, "le héros de mon épopée"]],
			"repliques": {
				"accueil": [
					L("Ô voyageur venu des mers lointaines, en couleurs vives et en chaussures pleines… (Il s'arrête.) Pleines de sable, je voulais dire. Achille Buvard, poète. J'écris l'épopée de la Grande Averse. J'en suis à la première goutte.", {"visites_max": 1}, "salut"),
					L("{surnom} ! Écoute ce vers : « La cascade d'encre pleure sans couleur… ». Hmm. Il manque une rime. Il manque surtout l'orange.", {"visites_min": 2, "q56": "cr_orange="}),
					L("{surnom} ! « Ô cascade orangée, au soleil retrouvé… » Ça y est, j'ai ma rime ! Merci, merci !", {"visites_min": 2, "q56": "cr_orange=finie"}, "rire"),
				],
				"humeur": [
					L("Mélancolique. C'est mon état naturel, mais l'Averse l'a aggravé. Un poète a besoin de couchers de soleil. Les nôtres sont gris.", {"q56": "cr_orange="}),
					L("Inspiré ! Le soleil se couche de nouveau en orange sur la cascade. J'ai écrit douze pages. Capucine en a lu deux. C'est un record.", {"q56": "cr_orange=finie"}, "rire"),
					L("Le soir, je lis mes poèmes à la Palette. Les godets écoutent. Ils ne disent rien, mais ils écoutent très bien.", {"soir": true}),
				],
				"lui": [
					L("Je suis toujours taché d'encre. Les doigts, le nez, la chemise. Capucine dit que je ne suis pas un poète, je suis un buvard qui marche.", {}, "rire"),
					L("J'ai écrit trois livres : « Ode au crayon », « Élégie pour une gomme » et « Le buvard et la tache, roman d'amour ». Le troisième s'est vendu à un exemplaire. C'est Capucine qui l'a acheté.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [
					L("La Cascade d'Encre tombe du Mont Fusain dans l'Étang Gommé. Le jour, elle est blanche. Au coucher du soleil, elle était orange, avant. C'était le plus beau moment de la journée. Je venais y écrire.", {}),
					L("En haut de la cascade, sur la Lèvre (le bord de la falaise, là où l'eau tombe), on entend le monde entier respirer. Et on se mouille les pieds.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [
					L("Le pot d'orange… Je l'ai vu ! Il est resté coincé en haut de la cascade, sur la Lèvre, au bord de l'eau. Il hésite à tomber. Comme moi devant une page blanche. Moi, je n'ose pas monter : j'ai le vertige des hauteurs et des rimes.", {"q56": "cr_orange="}),
					L("Lili a creusé un trou si profond sur la plage qu'elle dit avoir entendu la mer de l'autre côté de l'île. C'était le Ruisseau Pointillé. Mais quand même.", {}, "rire"),
				],
				"interpelle": [L("Ô toi qui passes ! Écoute ce vers !", {}, "salut")],
			}},
	]

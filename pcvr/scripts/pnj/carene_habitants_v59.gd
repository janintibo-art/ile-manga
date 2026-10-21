extends RefCounted
## V59 : les gens de Carène, le port bâti dans l'épave du Léviathan, sur la côte ouest de la
## grande île. Des descendants de naufragés venus d'outre-mer il y a deux siècles : des noms
## de Bretagne, des chants de marins, du cidre, des galettes et beaucoup de goudron.
## Même cerveau que les autres habitants (pnj_brain_v31.gd), même allure que ceux de
## Port-Azur (fiche « azur », pnj_azur_v56.gd), même vie réglée par l'heure (agenda).
## Lieux de l'agenda : voir carene_v59.gd (spots). "maison" : rentrer chez soi.
## Ils parlent des trois autres régions de l'île (les hautes terres du nord, la forêt des
## brumes à l'est, le désert du sud) et du Cœur-de-Pierre, le massif du centre, où dort la
## Porte aux Quatre Sceaux.

const Azur = preload("res://scripts/pnj/azur_habitants_v56.gd")

const COMMON := {
	"au_revoir": [
		{"t": "Bon vent, {surnom} !", "si": {}, "geste": "salut"},
		{"t": "Kenavo ! Ça veut dire « à la revoyure », chez nous.", "si": {}, "geste": "salut"},
		{"t": "Va, et garde l'œil sur la mer.", "si": {}},
		{"t": "Bonne nuit. Le Léviathan craque, mais il tient.", "si": {"soir": true}},
	],
	"frappe": [
		{"t": "Hé ! Tu veux finir par-dessus bord ?", "si": {}, "geste": "colere", "humeur": -0.4},
		{"t": "Aïe ! L'Amirale va entendre parler de toi !", "si": {}, "geste": "colere", "humeur": -0.4},
	],
	"cadeau_neutre": [
		{"t": "Merci bien. Ça trouvera sa place dans la cale.", "si": {}},
		{"t": "Un cadeau ? À Carène, on dit merci avec une bolée de cidre. Je t'en dois une.", "si": {}},
	],
	"cadeau_refus": [
		{"t": "Une arme ? On en a plein les cales, des armes. Garde-la.", "si": {}},
	],
	"blague": [
		{"t": "Tu sais pourquoi le Léviathan ne coule jamais ? Parce qu'il a déjà touché le fond ! … C'est la blague de Corentin, il la raconte tous les soirs.", "si": {}, "geste": "rire"},
		{"t": "Qu'est-ce qu'un crabe qui a perdu une pince ? Un crabe qui fait la pince-sans-rire. … Bon, d'accord, elle est de Ewen.", "si": {}, "geste": "rire"},
		{"t": "Un goéland entre dans la taverne. Gwenola lui dit : « On ne sert pas les oiseaux. » Il répond : « Je suis pas un oiseau, je suis un client à plumes. » Elle l'a servi. Il n'a pas payé.", "si": {}, "geste": "rire"},
	],
	"boutique": [{"t": "Approche, regarde. Tout vient de la mer ou de la cale. Tu as {pieces} pièces.", "si": {}}],
	"achat": [{"t": "{objet}, {prix} pièces. Marché conclu, et que la mer te garde !", "si": {}, "geste": "salut"}],
	"marchande_non": [{"t": "Marchander ? Sur un bateau, les prix sont cloués au mât.", "si": {}}],
}

const BASE := {
	"prefixes": {
		"joie": ["Ah !", "Hé là !", "Par les bordées !", "Quel beau temps pour la pêche !"],
		"neutre": ["Bon.", "Eh bien…", "Voyons voir…", "Hmm."],
		"triste": ["Ah… ", "Misère.", "Pff…", "Le vent tourne mal."],
		"colere": ["Tss.", "Largue-moi.", "Écoute un peu…", "Bon, ça suffit."],
	},
	"tics": ["Bon vent.", "Par la quille !", "Comme on dit à bord.", "Ma doue !"],
	"humeur_mots": [[0.6, "radieux"], [0.25, "de bonne humeur"], [-0.25, "songeur"], [-0.6, "grognon"], [-2.0, "furieux"]],
	"surnoms": [[0, "l'étranger"], [25, "matelot"], [50, "camarade"], [75, "frère de bord"], [95, "enfant de Carène"]],
}

const PEAU := [[1.0, 0.86, 0.74], [0.98, 0.8, 0.66], [0.92, 0.72, 0.56], [0.82, 0.6, 0.44], [0.66, 0.46, 0.34], [1.0, 0.9, 0.8]]


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
	out["groupe"] = "carene"
	return out


static func _all() -> Array:
	return [
		# ================================================================ la capitainerie
		{"id": "morgane", "nom": "Amirale Morgane Kerhervé", "titre": "amirale de Carène", "maison": "porte_capitainerie",
			"agenda": [[7, 12, "capitainerie_bureau"], [12, 14, ["tav_table_1", "tav_table_2"]], [14, 18, ["dunette_1", "capitainerie_bureau"]], [18, 22, "dunette_1"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.12, 0.08, 0.07], "coiffure": "queue", "chapeau": "marin", "chapeau_c": [0.08, 0.1, 0.2], "haut": [0.1, 0.13, 0.26], "yeux": [0.2, 0.35, 0.45], "carrure": 1.05},
			"teinte": PEAU[2], "humeur_base": 0.1, "traits": {"bavard": 0.4, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.4},
			"aime": {"boussole": 2.0, "perle": 1.5, "bar": 1.0}, "deteste": {"vieille_botte": -1.5},
			"repliques": {
				"accueil": [
					L("Halte. Tu es sur le pont du Léviathan, et ce pont, c'est chez nous. Je suis Morgane Kerhervé, amirale de Carène. Qui t'envoie, et par quelle mer ?", {"visites_max": 1}),
					L("Toi encore. Bien. Tant que tu respectes le bord, tu es le bienvenu.", {"visites_min": 2, "affinite_max": 30}),
					L("{surnom}. Approche. Carène t'est reconnaissante, et moi aussi.", {"visites_min": 2, "affinite_min": 30}, "salut"),
				],
				"humeur": [L("Comme une amirale sans flotte : occupée. Une ville de deux cents âmes dans une coque qui prend l'eau, ça ne se gouverne pas tout seul.", {}), L("Le soir, je monte sur la dunette. De là-haut, on voit le Cœur-de-Pierre rougir au couchant. Ça me calme.", {"soir": true})],
				"lui": [
					L("Mon aïeule commandait le Léviathan quand il s'est échoué. Deux cents ans plus tard, c'est toujours une Kerhervé qui tient la barre. Une barre qui ne tourne plus, mais quand même.", {}),
					L("On m'appelle l'Amirale. Je n'ai jamais commandé un seul navire qui flotte. Ça fait rire Corentin. Pas moi.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("L'île est grande, et chaque côte a son ciel. Nous, c'est l'ouest : la mer, les prairies et le vent. Au nord, les hautes terres et leur neige ; à l'est, la forêt des brumes ; au sud, le désert. Et au milieu, le Cœur-de-Pierre.", {}),
					L("Nous commerçons avec les trois autres peuples de l'île. Pas toujours de bon cœur, mais nous commerçons. Matthias, notre cartographe, te dira tout ça mieux que moi.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [L("Tobias dit que la coque tiendra encore cent ans. Tobias dit ça depuis trente ans.", {}), L("Grégoire jure qu'il a vu de la lumière dans le Cœur-de-Pierre, la nuit. Grégoire a de bons yeux. C'est bien ce qui m'inquiète.", {})],
				"interpelle": [L("Toi, l'étranger. Viens par ici.", {"visites_max": 0}), L("Bon vent, {surnom}.", {"visites_min": 1})],
			}},
		{"id": "matthias", "nom": "Matthias Le Goff", "titre": "cartographe", "maison": "porte_logis_1",
			"agenda": [[8, 12, "capitainerie_carte"], [12, 13, "tav_table_3"], [13, 18, "capitainerie_carte"], [18, 21, ["tav_table_3", "tav_table_4"]], [21, 8, "maison"]],
			"azur": {"cheveux": [0.55, 0.38, 0.2], "coiffure": "boucles", "lunettes": true, "haut": [0.45, 0.4, 0.3], "yeux": [0.35, 0.45, 0.3], "barbe": "courte"},
			"teinte": PEAU[0], "humeur_base": 0.3, "traits": {"bavard": 0.9, "humour": 0.5, "curiosite": 0.95, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"boussole": 2.5, "carte_naine": 2.0, "plume_corbeau": 1.0}, "deteste": {"sardine": -0.8},
			"repliques": {
				"accueil": [
					L("Un visiteur ! D'où viens-tu ? Non, attends, laisse-moi deviner… de l'ouest, par la mer, hein ? Matthias, cartographe. Je dessine l'île depuis quinze ans et elle n'est toujours pas finie.", {"visites_max": 1}, "salut"),
					L("Ah, {surnom} ! Viens voir, j'ai redessiné la côte des brumes. Elle bouge, je te jure qu'elle bouge.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Excellente ! J'ai une carte à moitié blanche devant moi. Il n'y a rien de plus excitant au monde.", {}), L("Fatigué. J'ai compté les dunes du sud toute la journée. Elles ne restent pas en place.", {"soir": true})],
				"lui": [
					L("Je suis le seul à Carène qui ait traversé toute l'île à pied. Les hautes terres, les brumes, le désert. J'en suis revenu avec des ampoules et douze carnets.", {}),
					L("Mon rêve ? Entrer dans le Cœur-de-Pierre et dessiner ce qu'il y a dedans. Il faudrait d'abord ouvrir la porte. Et pour ça…", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Quatre régions, quatre peuples. Nous, à l'ouest, sur la côte. Au nord, les bergers des hautes terres : des gens durs, qui parlent peu. À l'est, ceux de la forêt des brumes : on ne les voit presque jamais. Au sud, les caravaniers du désert : ils vendent de tout, et surtout cher.", {}),
					L("Le Cœur-de-Pierre, au centre, c'est un plateau tout rond, entouré de falaises. Personne n'y monte. Au pied de sa face ouest, il y a une porte géante : la Porte aux Quatre Sceaux.", {"sujet_min": ["ile", 1]}),
				],
				"rumeur": [L("Les caravaniers du sud disent que le désert avance. Les bergers du nord disent que la neige descend. Si tout le monde a raison, on finira sur le Léviathan. Ah, mais on y est déjà.", {}, "rire"), L("Lucie a trouvé des pierres taillées au fond de la baie. Taillées ! Quelqu'un vivait ici avant nous.", {})],
				"interpelle": [L("Hé ! Tu as l'air d'avoir voyagé. Tu as des cartes ?", {"visites_max": 0}), L("{surnom} ! Viens voir ma carte !", {"visites_min": 1})],
			}},
		# ================================================================ la taverne
		{"id": "gwenola", "nom": "Mère Gwenola", "titre": "patronne de La Dernière Bordée", "maison": "porte_taverne_chambre",
			"agenda": [[9, 23, "tav_comptoir"], [23, 9, "maison"]],
			"azur": {"cheveux": [0.85, 0.85, 0.82], "coiffure": "chignon", "tablier": [0.92, 0.9, 0.84], "robe": [0.15, 0.15, 0.2], "vieux": true, "yeux": [0.3, 0.4, 0.5], "carrure": 1.15, "foulard": [0.6, 0.15, 0.15]},
			"teinte": PEAU[1], "humeur_base": 0.4, "traits": {"bavard": 0.8, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.2, "rancunier": 0.2},
			"aime": {"miel": 2.0, "pomme": 1.5, "maquereau": 1.0}, "deteste": {"champignon": -1.0},
			"boutique": {"vend": {"galette_sarrasin": 6, "grog_bordee": 5, "cidre_carene": 4, "maquereau": 8}, "achete": {"pomme": 2, "miel": 5, "maquereau": 4, "sardine": 2}},
			"repliques": {
				"accueil": [
					L("Entre, entre, ne reste pas dans le courant d'air ! Bienvenue à La Dernière Bordée. Ici, on mange, on boit, on chante faux et on dort au sec. Je suis Gwenola. Tout le monde dit « Mère Gwenola ». Toi aussi.", {"visites_max": 1}, "salut"),
					L("Te voilà, {surnom} ! Assieds-toi, j'ai une galette sur le billig.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Comme une vieille coque : ça grince, mais ça flotte.", {}), L("Le soir, c'est le meilleur moment. Les pêcheurs rentrent, Corentin raconte, et quelqu'un finit toujours par chanter.", {"soir": true})],
				"lui": [
					L("Quarante ans que je tiens cette taverne. Elle était à ma mère, et à sa mère avant. La cheminée, c'est un ancien poêle de la cuisine du Léviathan. Elle n'a jamais refroidi.", {}),
					L("Pierrick ? C'est mon neveu. Il croit qu'il tient l'auberge. Je le laisse croire, ça le rend heureux.", {"sujet_min": ["lui", 1]}, "rire"),
				],
				"ile": [L("La taverne est dans le château arrière, sous la dunette. Les grandes fenêtres, là, au fond, c'est l'ancienne galerie du capitaine. Le plus beau coucher de soleil de l'île, et on est assis.", {})],
				"rumeur": [L("Fañch a encore parlé à son poisson. Il dit qu'il lui répond.", {}), L("Les caravaniers du sud viennent parfois vendre leurs épices. La dernière fois, ils m'ont vendu du sable rouge en jurant que c'était du piment.", {}, "rire")],
				"interpelle": [L("Toi ! Tu as l'air affamé. Entre donc !", {"visites_max": 0}), L("{surnom} ! Une galette ?", {"visites_min": 1})],
			}},
		{"id": "pierrick", "nom": "Pierrick", "titre": "aubergiste de La Dernière Bordée", "maison": "porte_taverne_chambre",
			"agenda": [[8, 15, ["tav_service", "tav_bar_2"], ["tav_table_2"]], [15, 17, "pont_banc_1"], [17, 24, "tav_service", ["tav_table_1", "tav_table_4"]], [0, 8, "maison"]],
			"azur": {"cheveux": [0.85, 0.55, 0.25], "coiffure": "court", "tablier": [0.82, 0.78, 0.7], "haut": [0.75, 0.72, 0.62], "yeux": [0.3, 0.5, 0.4]},
			"teinte": PEAU[5], "humeur_base": 0.3, "traits": {"bavard": 0.7, "humour": 0.6, "curiosite": 0.4, "susceptible": 0.5, "rancunier": 0.2},
			"aime": {"galette_sarrasin": 1.5, "glace": 2.0, "croissant": 1.0}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [
					L("Bienvenue à l'auberge de La Dernière Bordée ! Pierrick, aubergiste, pour vous servir. Une table ? Un hamac pour la nuit ? Les hamacs sont neufs. Enfin, ils ont moins de cinquante ans.", {"visites_max": 1}, "salut"),
					L("Ah, un habitué ! Le hamac du fond est libre, si tu veux.", {"visites_min": 2}),
				],
				"humeur": [L("Bien ! Tout va bien ! Tant que ma tante ne regarde pas.", {}, "rire")],
				"lui": [L("Je suis l'aubergiste. Ma tante Gwenola tient la taverne, et moi l'auberge. C'est très différent. L'auberge, c'est quand on dort. Elle trouve que c'est pareil.", {}), L("Un jour, j'ouvrirai une vraie auberge, avec des lits. Sur la terre ferme. Qui ne bouge pas.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les chambres sont dans l'entrepont, sous le pont principal. On y dort dans des hamacs, comme les marins d'avant. Ça berce, même quand le bateau ne bouge plus.", {})],
				"rumeur": [L("Ewen a encore grimpé à la grande hune sans permission. L'Amirale l'a fait récurer le pont pendant trois jours.", {}), L("Le vieux Corentin dit qu'il y a un trésor dans les cales noyées. Il le dit surtout après le troisième grog.", {})],
				"interpelle": [L("Une chambre ? Une table ?", {"visites_max": 0}), L("Re-bonjour, {surnom} !", {"visites_min": 1})],
			}},
		{"id": "corentin", "nom": "Vieux Corentin", "titre": "conteur", "maison": "porte_logis_2",
			"agenda": [[9, 12, "pont_banc_2"], [12, 16, "bastingage_3"], [16, 23, "tav_poele"], [23, 9, "maison"]],
			"azur": {"cheveux": [0.95, 0.95, 0.93], "coiffure": "long", "barbe": "longue", "chapeau": "beret", "chapeau_c": [0.1, 0.12, 0.2], "haut": [0.3, 0.32, 0.4], "vieux": true, "yeux": [0.5, 0.55, 0.6], "taille": 0.97},
			"teinte": PEAU[1], "humeur_base": 0.3, "traits": {"bavard": 1.0, "humour": 0.7, "curiosite": 0.4, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"grog_bordee": 2.5, "cidre_carene": 2.0, "biere_naine": 1.5}, "deteste": {"glace": -0.5},
			"repliques": {
				"accueil": [
					L("Assieds-toi, petit, assieds-toi. Tu veux une histoire ? Bien sûr que tu veux une histoire. Tout le monde veut une histoire. Je suis Corentin, et j'en connais mille.", {"visites_max": 1}),
					L("Te revoilà ! Où en étais-je ? Ah oui. La nuit où le Léviathan a touché la terre…", {"visites_min": 2}),
				],
				"humeur": [L("À mon âge, chaque matin est un cadeau. Même les matins de pluie. Surtout les matins de pluie : personne ne me demande de travailler.", {}, "rire")],
				"lui": [
					L("J'étais mousse, il y a… longtemps. Puis pêcheur, puis charpentier, puis rien du tout. Maintenant je raconte. C'est le meilleur métier : on ne se mouille jamais.", {}),
					L("Mon arrière-arrière-grand-père était à bord la nuit du naufrage. Il a raconté l'histoire à son fils, qui l'a racontée au sien… jusqu'à moi. Je suis la dernière page du livre.", {"sujet_min": ["lui", 1]}),
				],
				"ile": [
					L("Écoute bien. Il y a deux cents ans, le Léviathan venait d'au-delà de l'horizon. Le plus grand navire jamais construit. Ses maîtres cherchaient une île dont on disait qu'elle avait un cœur. Une nuit de tempête, ils l'ont trouvée. Un peu trop vite.", {}),
					L("La suite ? Le Cœur-de-Pierre, au milieu de l'île, et la Porte aux Quatre Sceaux. On dit que chacun des peuples de l'île en garde un. Celui des hautes terres, celui des brumes, celui du désert… et le quatrième. Le nôtre. Personne ne sait où il est passé.", {"sujet_min": ["ile", 1]}),
					L("Et derrière la porte ? Ah… ceux qui savaient sont morts depuis longtemps. Un trésor, disent les uns. Un monstre, disent les autres. Moi, je dis : les deux. C'est toujours les deux.", {"sujet_min": ["ile", 2]}, "rire"),
				],
				"rumeur": [L("La nuit, quand la mer est calme, on entend la coque chanter. Les jeunes disent que c'est le bois qui travaille. Moi, je dis que le Léviathan se souvient.", {}), L("Une fois, j'ai vu une baleine si grande qu'elle avait des arbres sur le dos. … Non, c'était une île. Mais elle bougeait, je te jure.", {}, "rire")],
				"interpelle": [L("Psst ! Tu veux une histoire ?", {"visites_max": 0}), L("{surnom} ! Viens t'asseoir !", {"visites_min": 1})],
			}},
		# ================================================================ les métiers de la mer
		{"id": "tobias", "nom": "Tobias", "titre": "calfat et charpentier de marine", "maison": "porte_logis_3",
			"agenda": [[7, 12, ["calfat_atelier", "ponton_coque"]], [12, 13, "tav_bar_1"], [13, 19, ["ponton_coque", "calfat_atelier"]], [19, 22, "tav_bar_1"], [22, 7, "maison"]],
			"azur": {"cheveux": [0.3, 0.22, 0.15], "coiffure": "court", "barbe": "courte", "chapeau": "casquette", "chapeau_c": [0.3, 0.25, 0.2], "haut": [0.4, 0.3, 0.22], "tablier": [0.35, 0.28, 0.2], "yeux": [0.3, 0.25, 0.15], "carrure": 1.15},
			"teinte": PEAU[3], "humeur_base": 0.0, "traits": {"bavard": 0.3, "humour": 0.4, "curiosite": 0.3, "susceptible": 0.5, "rancunier": 0.3},
			"aime": {"buche": 2.0, "minerai_fer": 1.5, "biere_naine": 1.5}, "deteste": {"coquillage": -0.5},
			"repliques": {
				"accueil": [
					L("Attention où tu mets les pieds, il y a du goudron partout. Tobias. Calfat. Je bouche les trous. Dans un bateau de cent quarante mètres, il y a toujours un trou.", {"visites_max": 1}),
					L("Ah, c'est toi. Tu ne viendrais pas avec du bois, par hasard ?", {"visites_min": 2}),
				],
				"humeur": [L("Comme quelqu'un qui écope avec une cuillère.", {}), L("Fatigué. Mais la coque n'a pas pris une goutte aujourd'hui. Enfin, presque pas.", {"soir": true})],
				"lui": [L("Mon père était calfat, mon grand-père aussi. Toute ma famille a passé sa vie à empêcher ce bateau de se noyer. Il est échoué, mais il pourrait encore se noyer. C'est un talent.", {}), L("Le bois de l'île est bon. Le chêne des hautes terres surtout. Mais les bergers du nord le vendent au poids de l'or.", {"sujet_min": ["lui", 1]})],
				"ile": [L("L'arrière du Léviathan est sous l'eau : la mer est entrée par la grande brèche du sud, et la cale s'est remplie. On en a fait un bassin pour les barques. Ce qui est noyé ne peut plus couler. C'est ma philosophie.", {})],
				"rumeur": [L("Jos tape sur son enclume au-dessus de ma tête toute la journée. Un jour, il passera à travers le pont.", {}), L("Lucie plonge sous la coque. Elle dit qu'il y a des choses gravées sur la quille, en dessous. Des choses que personne n'a écrites.", {})],
				"interpelle": [L("Toi ! Tu sais manier la hache ?", {"visites_max": 0}), L("{surnom}. Salut.", {"visites_min": 1})],
			}},
		{"id": "fanch", "nom": "Fañch", "titre": "pêcheur", "maison": "porte_barque",
			"agenda": [[5, 9, "ponton_peche"], [9, 13, "cale_etal_poisson"], [13, 16, "plage_filets"], [16, 19, "bassin_barque"], [19, 23, ["plage_feu_1", "plage_feu_2"]], [23, 5, "maison"]],
			"azur": {"cheveux": [0.4, 0.4, 0.42], "coiffure": "court", "barbe": "longue", "chapeau": "beret", "chapeau_c": [0.15, 0.15, 0.17], "haut": [0.7, 0.55, 0.2], "vieux": true, "yeux": [0.35, 0.5, 0.6]},
			"teinte": PEAU[3], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.8, "curiosite": 0.4, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"canne_peche": 2.0, "grog_bordee": 1.5, "galette_sarrasin": 1.5}, "deteste": {"vieille_botte": -0.3},
			"boutique": {"vend": {"sardine": 3, "maquereau": 6, "canne_peche": 15}, "achete": {"sardine": 2, "maquereau": 4, "dorade": 7, "bar": 8, "merou": 18, "poisson_lune": 30, "vieille_botte": 1}},
			"repliques": {
				"accueil": [
					L("Salut, toi. Fañch. Pêcheur. Ma maison, c'est la barque retournée sur la plage, là-bas. Elle a fait naufrage avant moi, alors on s'entend bien.", {"visites_max": 1}, "salut"),
					L("Re-bonjour ! Ça mord, aujourd'hui. Ou alors c'est moi qui mords. On verra.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("La mer est bonne, le poisson est bête. Que demander de plus ?", {}), L("Le soir, on fait un feu sur la plage, avec les autres. On grille ce qu'on a pêché, on raconte ce qu'on n'a pas pêché.", {"soir": true}, "rire")],
				"lui": [L("Soixante ans de pêche. J'ai attrapé une fois un mérou si gros qu'il a fallu deux barques. Je l'ai relâché : il avait l'air plus vieux que moi.", {}), L("Je parle à mes poissons. Ils ne répondent pas. Enfin, presque jamais.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("La baie est poissonneuse, abritée par les deux pointes. Plus loin, au large, il y a les gros. Et au nord, sous les falaises des hautes terres, des homards comme des chiens.", {})],
				"rumeur": [L("Les gens des brumes, à l'est, pêchent dans les mares, avec des paniers. Paraît que leurs poissons brillent la nuit.", {}), L("Grégoire, là-haut dans sa hune, compte les bateaux qui passent. Il n'en passe jamais. Il compte quand même.", {})],
				"interpelle": [L("Hé ! Un poisson tout frais ?", {"visites_max": 0}), L("{surnom} ! Ça mord !", {"visites_min": 1})],
			}},
		{"id": "nolwenn", "nom": "Nolwenn", "titre": "voilière", "maison": "porte_cabane_1",
			"agenda": [[8, 12, "voilerie"], [12, 14, ["pont_banc_1", "pont_banc_2"]], [14, 19, "voilerie"], [19, 22, ["plage_feu_2", "plage_feu_3"]], [22, 8, "maison"]],
			"azur": {"cheveux": [0.08, 0.06, 0.05], "coiffure": "long", "haut": [0.85, 0.82, 0.72], "robe": [0.25, 0.35, 0.55], "yeux": [0.25, 0.45, 0.55], "foulard": [0.85, 0.4, 0.15]},
			"teinte": PEAU[0], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.5, "curiosite": 0.5, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"perle": 2.0, "fleur_lune": 2.0, "coquillage": 1.0}, "deteste": {"buche": -0.5},
			"repliques": {
				"accueil": [
					L("Bonjour. Nolwenn, voilière. Tu vois les auvents rouges et bleus, partout dans Carène ? Ce sont mes vieilles voiles. Je les recouds, je les recoupe, je leur donne une deuxième vie.", {"visites_max": 1}),
					L("Ah, toi. Assieds-toi si tu veux, mais ne marche pas sur la toile.", {"visites_min": 2}),
				],
				"humeur": [L("Paisible. Coudre, c'est comme écouter la mer : on ne pense plus à rien.", {})],
				"lui": [L("La grande voile, là-haut, sous la vergue, c'est la dernière voile d'origine du Léviathan. Personne n'a le droit d'y toucher. Même pas moi. Elle part en lambeaux, et je la regarde partir.", {}), L("Je rêve de coudre une voile neuve pour une barque, et de partir voir les autres îles. Un jour.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Les caravaniers du sud m'apportent du coton du désert. Les bergers du nord, de la laine. Les gens des brumes… rien. Ils ne commercent pas. Mais une fois, l'un d'eux m'a laissé un fil d'argent qui brille dans le noir.", {})],
				"rumeur": [L("Ewen veut devenir capitaine. Il a douze ans et il a déjà le chapeau.", {}, "rire"), L("Salomé vend n'importe quoi à n'importe qui. Hier, elle a vendu un seau percé à un goéland.", {})],
				"interpelle": [L("Attention à la toile !", {"visites_max": 0}), L("Bonjour, {surnom}.", {"visites_min": 1})],
			}},
		{"id": "gregoire", "nom": "Grégoire", "titre": "guetteur", "maison": "porte_logis_4",
			"agenda": [[6, 11, "proue"], [11, 13, "tav_bar_2"], [13, 20, ["proue", "dunette_2"]], [20, 23, "proue"], [23, 6, "maison"]],
			"azur": {"cheveux": [0.65, 0.65, 0.62], "coiffure": "court", "barbe": "moustache", "chapeau": "kepi", "chapeau_c": [0.2, 0.2, 0.25], "haut": [0.2, 0.28, 0.25], "yeux": [0.25, 0.4, 0.3], "vieux": true},
			"teinte": PEAU[2], "humeur_base": -0.1, "traits": {"bavard": 0.3, "humour": 0.3, "curiosite": 0.7, "susceptible": 0.6, "rancunier": 0.4},
			"aime": {"boussole": 2.0, "grog_bordee": 1.5}, "deteste": {"glace": -0.5},
			"repliques": {
				"accueil": [
					L("Hm ? Ah. Pardon, je regardais l'horizon. Grégoire, guetteur. Je surveille la mer pour Carène. Et la terre aussi, maintenant. On ne sait jamais d'où ça vient.", {"visites_max": 1}),
					L("Tu reviens. Je t'ai vu arriver de loin.", {"visites_min": 2}),
				],
				"humeur": [L("Vigilant. Toujours vigilant.", {}), L("La nuit, j'allume la lanterne, là-haut, au sommet du grand mât. Les barques rentrent grâce à elle.", {"soir": true})],
				"lui": [L("Quarante ans dans la grande hune. Maintenant mes genoux ne veulent plus grimper, alors je guette depuis la proue. Ewen monte allumer la lanterne pour moi.", {}), L("Une nuit, j'ai vu une lumière bleue sur le Cœur-de-Pierre. Juste devant la grande porte. Elle clignotait, comme un cœur qui bat.", {"sujet_min": ["lui", 1]})],
				"ile": [L("D'ici, on voit tout : la baie, les deux pointes, les prairies, et le Cœur-de-Pierre au fond, avec la neige des hautes terres derrière. Par temps clair, on voit même la fumée des caravanes, au sud.", {})],
				"rumeur": [L("Il passe parfois une barque, loin, à l'ouest. Elle vient des îles du village et des elfes. Je les compte. Cette année : trois. Avec toi.", {}), L("Les bergers des hautes terres allument des feux sur les crêtes, les nuits de pleine lune. Je ne sais pas ce qu'ils fêtent.", {})],
				"interpelle": [L("Toi ! D'où viens-tu ?", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "jos", "nom": "Jos Le Floc'h", "titre": "forgeron de La Forge du Canon", "maison": "porte_logis_5",
			"agenda": [[7, 12, "forge"], [12, 13, "tav_bar_1"], [13, 19, "forge"], [19, 23, ["plage_feu_1", "tav_bar_2"]], [23, 7, "maison"]],
			"azur": {"cheveux": [0.12, 0.1, 0.08], "coiffure": "chauve", "barbe": "longue", "haut": [0.25, 0.22, 0.2], "tablier": [0.3, 0.2, 0.12], "yeux": [0.2, 0.15, 0.1], "carrure": 1.25},
			"teinte": PEAU[4], "humeur_base": 0.2, "traits": {"bavard": 0.4, "humour": 0.6, "curiosite": 0.3, "susceptible": 0.4, "rancunier": 0.3},
			"aime": {"minerai_fer": 2.5, "obsidienne": 2.0, "coeur_magma": 2.5}, "deteste": {"fleur_lune": -0.5},
			"boutique": {"vend": {"hache": 32, "pelle": 18, "epee": 58, "sabre_corsaire": 135}, "achete": {"minerai_fer": 6, "obsidienne": 10, "coeur_magma": 18, "buche": 2}},
			"repliques": {
				"accueil": [
					L("Bienvenue à La Forge du Canon ! Jos. Mon foyer, c'est le vieux canon de bâbord : je l'ai ouvert, rempli de briques, et il chauffe mieux qu'un volcan. Tu as besoin d'une lame ?", {"visites_max": 1}, "salut"),
					L("Ha ! Le revoilà ! Approche, approche, le fer est chaud.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Comme mon enclume : solide, et un peu sourde.", {}, "rire")],
				"lui": [L("Les canons du Léviathan ne tirent plus depuis deux siècles. J'en ai fait un foyer, deux enclumes et une marmite. C'est mieux comme ça.", {}), L("J'ai appris le métier avec un nain de Forgefer, venu ici sur un radeau. Il est reparti au bout d'un an. Il disait qu'il y avait trop d'eau.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Le fer, on le trouve au nord, dans les hautes terres. Les bergers le sortent des rochers et le vendent aux caravaniers, qui nous le revendent deux fois plus cher.", {})],
				"rumeur": [L("Tobias se plaint du bruit. Tobias se plaint de tout.", {}, "rire"), L("Il paraît que la Porte aux Quatre Sceaux est en pierre, mais que ses gonds sont en métal. Un métal que personne ne connaît. J'aimerais bien en voir un bout.", {})],
				"interpelle": [L("Une lame ? Une hache ?", {"visites_max": 0}), L("{surnom} ! Le fer est chaud !", {"visites_min": 1})],
			}},
		{"id": "salome", "nom": "Salomé", "titre": "marchande du Marché de la Cale", "maison": "porte_cabane_2",
			"agenda": [[8, 19, "cale_comptoir"], [19, 22, ["tav_table_2", "tav_bar_2"]], [22, 8, "maison"]],
			"azur": {"cheveux": [0.55, 0.15, 0.08], "coiffure": "boucles", "haut": [0.7, 0.2, 0.2], "robe": [0.3, 0.15, 0.25], "yeux": [0.4, 0.55, 0.3], "foulard": [0.95, 0.75, 0.2]},
			"teinte": PEAU[2], "humeur_base": 0.4, "traits": {"bavard": 0.9, "humour": 0.7, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"perle": 2.0, "rubis": 2.5, "piece_or": 2.5}, "deteste": {"vieille_botte": -1.0},
			"boutique": {"vend": {"boussole": 26, "masque_plongee": 60, "fiole_vide": 3, "corail_rouge": 14, "galette_algue": 4}, "achete": {"perle": 28, "rubis": 38, "piece_or": 55, "coquillage": 3, "corail_rouge": 8, "etoile_mer": 6, "eclat_cristal": 12, "dent_requin": 14}},
			"repliques": {
				"accueil": [
					L("Bienvenue, bienvenue au Marché de la Cale ! Salomé, la meilleure marchande de l'île. Et la seule de Carène, mais ça ne change rien. Tout ce qui flotte, tout ce qui brille, tout ce qui se vend !", {"visites_max": 1}, "salut"),
					L("Mon client préféré ! Enfin, mon client. Viens voir les nouveautés !", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Excellente ! J'ai vendu trois cordes, deux lanternes et un crabe qui ne voulait pas être vendu.", {}, "rire")],
				"lui": [L("Ma grand-mère disait : « Une cale vide, c'est un cœur vide. » Alors je la remplis. Tu entres par la brèche de la plage, et tu tombes droit sur mon étal. C'est fait exprès.", {}), L("Je commerce avec les caravaniers du sud. Ce sont des voleurs. Je les adore.", {"sujet_min": ["lui", 1]}, "rire")],
				"ile": [L("Le marché est dans la cale du Léviathan, au fond. Le jour, on entre par la grande brèche du côté de la plage. Au-delà des étals, la cale est sous l'eau : c'est le bassin, où rentrent les barques.", {})],
				"rumeur": [L("Matthias raconte à qui veut l'entendre qu'il ouvrira la Porte aux Quatre Sceaux. Je lui ai proposé de lui vendre une clé. Il n'a pas ri.", {}, "rire"), L("Anouk soigne tout le monde avec des algues. Même les rhumes. Même les jambes cassées.", {})],
				"interpelle": [L("Approchez ! Tout doit disparaître !", {"visites_max": 0}), L("{surnom} ! J'ai ce qu'il te faut !", {"visites_min": 1})],
			}},
		{"id": "ewen", "nom": "Ewen", "titre": "mousse", "maison": "porte_logis_6",
			"agenda": [[7, 10, "pont_cloche", ["proue", "pont_place"]], [10, 13, "cale_flane_1", ["bassin_ponton_2", "cale_flane_2"]], [13, 17, "pont_place", ["pont_cloche", "bastingage_2"]], [17, 21, "plage_feu_3", ["ponton_bout"]], [21, 7, "maison"]],
			"azur": {"cheveux": [0.9, 0.7, 0.35], "coiffure": "court", "chapeau": "marin", "chapeau_c": [0.08, 0.1, 0.2], "haut": [0.85, 0.85, 0.9], "yeux": [0.3, 0.5, 0.65], "taille": 0.72},
			"teinte": PEAU[5], "humeur_base": 0.5, "traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 1.0, "susceptible": 0.4, "rancunier": 0.1},
			"aime": {"cerf_volant": 2.5, "glace": 2.0, "boussole": 1.5, "coquillage": 1.0}, "deteste": {"tisane_lune": -0.8},
			"repliques": {
				"accueil": [
					L("Ohé ! Tu viens d'où ? T'as un bateau ? Il est grand ? Plus grand que le Léviathan ? Non, hein. Rien n'est plus grand que le Léviathan. Moi c'est Ewen, je suis mousse. Futur capitaine.", {"visites_max": 1}, "salut"),
					L("Hé, c'est toi ! Tu veux voir la grande hune ? Faut pas le dire à l'Amirale.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Super ! J'ai sonné la cloche trois fois ce matin. Deux fois, c'était exprès.", {}, "rire")],
				"lui": [L("Je sonne la cloche pour les heures, je porte les messages, j'allume la lanterne du grand mât pour Grégoire, et je récure le pont quand je fais des bêtises. Donc je récure souvent.", {}), L("Un jour, je serai capitaine. Je réparerai le Léviathan, on le remettra à l'eau, et on partira tous. Tout le monde rit quand je dis ça. Sauf Tobias. Lui, il soupire.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Tu as vu la grande porte, au pied du Cœur-de-Pierre ? Moi j'y suis allé ! Enfin, presque. Jusqu'au premier rocher. Après, j'ai eu faim.", {}, "rire")],
				"rumeur": [L("Corentin dit qu'il y a un monstre dans le bassin. Je l'ai cherché tout un après-midi. J'ai trouvé une botte.", {}), L("Lucie peut rester sous l'eau plus longtemps qu'un phoque. Je l'ai chronométrée. Enfin, j'ai compté. Jusqu'à cent, après je me suis trompé.", {})],
				"interpelle": [L("Ohé ! Ohé !", {"visites_max": 0}), L("{surnom} ! Viens voir !", {"visites_min": 1})],
			}},
		{"id": "lucie", "nom": "Lucie", "titre": "plongeuse", "maison": "porte_cabane_3",
			"agenda": [[7, 12, "ponton_bout"], [12, 14, "bassin_ponton_1"], [14, 18, "ponton_bout"], [18, 22, ["plage_feu_1", "plage_feu_3"]], [22, 7, "maison"]],
			"azur": {"cheveux": [0.12, 0.1, 0.08], "coiffure": "queue", "haut": [0.1, 0.45, 0.5], "yeux": [0.3, 0.55, 0.6]},
			"teinte": PEAU[4], "humeur_base": 0.3, "traits": {"bavard": 0.4, "humour": 0.5, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"masque_plongee": 2.0, "perle": 2.0, "etoile_mer": 1.5, "corail_rouge": 1.5}, "deteste": {"grog_bordee": -0.5},
			"repliques": {
				"accueil": [
					L("Salut. Lucie, plongeuse. Je ramasse ce que la mer veut bien donner : des perles, du corail, et des morceaux du Léviathan qui sont tombés depuis deux cents ans.", {"visites_max": 1}),
					L("Tiens, toi. L'eau est bonne, aujourd'hui. Tu viens ?", {"visites_min": 2}),
				],
				"humeur": [L("Bien. Sous l'eau, tout est calme. C'est en surface que les gens parlent trop.", {})],
				"lui": [L("J'ai appris à nager avant de marcher. Ma mère plongeait, sa mère aussi. On dit qu'on a des branchies cachées derrière les oreilles. C'est faux. Je crois.", {}, "rire"), L("Sous la quille du Léviathan, il y a des signes gravés. Pas par des naufragés : c'est trop ancien, et c'est fait dans la pierre, sous le sable. Le bateau s'est échoué sur quelque chose.", {"sujet_min": ["lui", 1]})],
				"ile": [L("Au fond de la baie, il y a des pierres taillées, couvertes d'algues. Des marches, peut-être. Elles descendent vers le large. Matthias voudrait que je les dessine. Sous l'eau. Avec un crayon.", {})],
				"rumeur": [L("La mer est plus profonde au large de la baie. Bien plus profonde. Il y fait noir dès dix brasses.", {}), L("Les gens des brumes viennent parfois sur la plage, la nuit, sans bruit. Ils laissent des coquillages sur la barque de Fañch. On ne sait pas pourquoi.", {})],
				"interpelle": [L("Tu sais nager ?", {"visites_max": 0}), L("{surnom}.", {"visites_min": 1})],
			}},
		{"id": "anouk", "nom": "Anouk", "titre": "guérisseuse", "maison": "porte_cabane_4",
			"agenda": [[8, 13, "infirmerie"], [13, 15, ["plage_filets", "bastingage_1"]], [15, 20, "infirmerie"], [20, 22, "tav_table_4"], [22, 8, "maison"]],
			"azur": {"cheveux": [0.82, 0.8, 0.75], "coiffure": "chignon", "haut": [0.45, 0.55, 0.4], "robe": [0.35, 0.42, 0.32], "yeux": [0.35, 0.5, 0.35], "lunettes": true},
			"teinte": PEAU[1], "humeur_base": 0.2, "traits": {"bavard": 0.5, "humour": 0.4, "curiosite": 0.6, "susceptible": 0.3, "rancunier": 0.1},
			"aime": {"fleur_lune": 2.0, "goutte_rosee": 1.5, "miel": 1.5, "champignon": 1.0}, "deteste": {"biere_naine": -0.5},
			"boutique": {"vend": {"potion_seve": 14, "tisane_lune": 9, "galette_algue": 4}, "achete": {"fleur_lune": 14, "goutte_rosee": 6, "champignon": 3, "baies": 1, "miel": 4}},
			"repliques": {
				"accueil": [
					L("Bonjour. Anouk, la guérisseuse. Mon infirmerie est dans l'entrepont, entre les hamacs. Algues, miel, et beaucoup de patience. Tu es blessé ?", {"visites_max": 1}),
					L("Te voilà. Montre-moi ces égratignures… Hmm. Tu vivras.", {"visites_min": 2}, "rire"),
				],
				"humeur": [L("Sereine. Personne ne s'est cassé la jambe aujourd'hui. Ewen est en retenue.", {}, "rire")],
				"lui": [L("Les algues de la baie soignent les plaies. Le miel des prairies, la toux. Et le grog de Gwenola… rien du tout, mais tout le monde se sent mieux.", {}), L("Je voudrais aller dans la forêt des brumes. On dit que ses gens connaissent des plantes qui guérissent la fièvre en une nuit. Mais on ne revient pas toujours des brumes.", {"sujet_min": ["lui", 1]})],
				"ile": [L("À l'est, la forêt des brumes : mousse, mares et brouillard. Des plantes que je ne connais pas. Au sud, le désert : on y trouve un cactus dont la sève fait dormir. Au nord, la bruyère et le thym. L'île est une pharmacie, il faut juste savoir lire.", {})],
				"rumeur": [L("Corentin me cache ses grogs dans ma réserve d'algues. Il croit que je ne le sais pas.", {}), L("Les caravaniers du sud ont la peau dure comme du cuir. Ils disent que c'est le soleil. Moi, je crois que c'est une crème. Je veux la recette.", {})],
				"interpelle": [L("Tu as mauvaise mine. Approche.", {"visites_max": 0}), L("Bonjour, {surnom}.", {"visites_min": 1})],
			}},
	]


static func all_profiles() -> Array:
	var out: Array = []
	for d in _all():
		out.append(complete(d))
	return out

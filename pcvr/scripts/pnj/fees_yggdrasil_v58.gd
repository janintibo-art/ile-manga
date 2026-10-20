extends RefCounted
## V58 : les fées du royaume d'Yggdrasil, l'île du ciel où pousse l'Arbre-Monde. On y arrive
## en mangeant le champignon magique de Lulu (la teuf de la plage). La reine Oriane confie la
## quête de la graine d'Yggdrasil (journal_v56.gd, « graine_yggdrasil ») ; les autres fées en
## parlent, chacune à sa façon, avant, pendant et après.
## Même corps que les fées du Village des Fées (pnj/fee_v44.gd), même cerveau.

const Habitants = preload("res://scripts/pnj/elfes_habitants_v42.gd")

static func L(t: String, si: Dictionary = {}, geste: String = "") -> Dictionary:
	var e := {"t": t, "si": si}
	if geste != "":
		e["geste"] = geste
	return e


## [fiche, position (repère local du royaume : x, z autour d'Yggdrasil)]
static func _all() -> Array:
	return [
		[{"id": "oriane", "nom": "Reine Oriane", "titre": "reine des fées d'Yggdrasil",
			"fee": {"robe": [0.97, 0.94, 0.85], "cheveux": [0.95, 0.85, 0.55], "ailes": [0.8, 0.95, 1.0], "yeux": [0.35, 0.55, 0.85], "fleur": [1.0, 0.8, 0.95]},
			"humeur_base": 0.5, "energie_base": 0.7, "affinite_depart": 15.0,
			"traits": {"bavard": 0.6, "humour": 0.4, "curiosite": 0.7, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"fleur_lune": 3.0, "nectar_fee": 2.0, "perle": 2.0}, "deteste": {"vieille_botte": -1.0},
			"refuse": ["hache"],
			"repliques": {
				"accueil": [
					L("Un humain… dans mon royaume ? Le champignon de Lulu, je parie. Bienvenue, voyageur. Ici pousse Yggdrasil, l'Arbre-Monde, dont les racines boivent dans toutes les îles.", {"visites_max": 1}, "salut"),
					L("Te revoilà parmi nous. Yggdrasil murmure ton nom, tu sais.", {"visites_min": 2, "q56": "graine_yggdrasil=en_cours"}),
					L("Ami des fées ! Le royaume tout entier chante ton nom.", {"q56": "graine_yggdrasil=finie"}, "rire"),
				],
				"humeur": [
					L("Inquiète. Yggdrasil ne donne plus de graines depuis cent ans. Sans graine, pas de nouvel arbre ; sans nouvel arbre, les îles finiront par se faner.", {"q56": "graine_yggdrasil="}),
					L("Pleine d'espoir. Tu es là-dedans pour nous, je le sens.", {"q56": "graine_yggdrasil=en_cours"}),
					L("Heureuse. La graine dort dans la terre de la clairière. Dans mille ans, un nouvel Yggdrasil veillera sur vous.", {"q56": "graine_yggdrasil=finie"}),
				],
				"lui": [
					L("Je règne sur les fées du ciel depuis que le monde est jeune. Ma tâche est simple : veiller sur l'Arbre, et l'Arbre veille sur tout le reste.", {}),
					L("Les fées des racines, sous l'Arbre-Mère des elfes, sont nos cousines. Elles creusent ; nous, nous volons.", {"affinite_min": 20}),
				],
				"ile": [
					L("Notre île flotte au-dessus des nuages, loin de l'archipel. Personne n'y vient… sauf ceux qui rêvent assez fort. Ou qui mangent le bon champignon.", {}),
					L("Le cercle de champignons, au bord de la clairière, te ramènera sur ta plage quand tu voudras.", {}),
				],
				"rumeur": [
					L("Dans Yggdrasil, des plantes se sont réveillées, méchantes et affamées. La Mère-Ronce garde la couronne de l'Arbre.", {"q56": "graine_yggdrasil=en_cours"}),
					L("L'esprit de l'Arbre ne parle qu'à ceux qui ont traversé ses quatre salles. C'est ainsi depuis toujours.", {}),
				],
				"interpelle": [L("Voyageur, approche…", {})],
			}}, Vector2(-6.0, 62.0)],
		[{"id": "lumi", "nom": "Lumi", "titre": "fée des lucioles",
			"fee": {"robe": [0.75, 0.95, 0.5], "cheveux": [0.95, 1.0, 0.55], "ailes": [0.9, 1.0, 0.6], "yeux": [0.4, 0.6, 0.2], "fleur": [1.0, 1.0, 0.5]},
			"humeur_base": 0.8, "energie_base": 1.0, "affinite_depart": 10.0,
			"traits": {"bavard": 0.9, "humour": 0.8, "curiosite": 0.8, "susceptible": 0.2, "rancunier": 0.1},
			"aime": {"miel": 2.0, "baies": 1.5}, "deteste": {"caillou": -0.5},
			"repliques": {
				"accueil": [L("Coucou ! Tu brilles pas du tout, toi. C'est normal pour un humain ? Bienvenue !", {"visites_max": 1}, "rire"), L("Hé ! Te revoilà !", {"visites_min": 2})],
				"humeur": [L("Pétillante ! Mes lucioles ont dansé toute la nuit.", {}, "rire")],
				"lui": [L("Je guide les lucioles. Le soir, je les envoie dessiner des chemins dans l'air pour les fées qui rentrent tard.", {})],
				"ile": [L("Dans la première salle de l'Arbre, les lucioles chantent un air en lumière. Écoute avec les yeux, et marche sur les pierres dans le même ordre !", {}), L("Les lucioles d'Yggdrasil sont mes cousines. Elles connaissent tous les secrets de l'Arbre.", {})],
				"rumeur": [L("Zéphyr dit qu'il vole plus vite que le vent. Le vent dit le contraire.", {}, "rire")],
				"interpelle": [L("Youhou !", {})],
			}}, Vector2(7.0, 58.0)],
		[{"id": "perlee", "nom": "Perlée", "titre": "fée de la rosée",
			"fee": {"robe": [0.6, 0.85, 1.0], "cheveux": [0.85, 0.95, 1.0], "ailes": [0.7, 0.9, 1.0], "yeux": [0.25, 0.45, 0.8], "fleur": [0.7, 0.9, 1.0]},
			"humeur_base": 0.5, "energie_base": 0.6, "affinite_depart": 10.0,
			"traits": {"bavard": 0.5, "humour": 0.3, "curiosite": 0.6, "susceptible": 0.4, "rancunier": 0.2},
			"aime": {"eau_source": 2.5, "perle": 2.0, "goutte_rosee": 3.0}, "deteste": {},
			"repliques": {
				"accueil": [L("Bonjour… Attention où tu marches, chaque goutte de rosée a son nom.", {"visites_max": 1}), L("Bonjour, toi.", {"visites_min": 2})],
				"humeur": [L("Calme comme l'étang à l'aube.", {})],
				"lui": [L("Chaque matin, je dépose une goutte sur chaque fleur du royaume. Il y en a quatre mille trois cent deux. Je les connais toutes.", {})],
				"ile": [L("Dans la salle de la Sève, la lumière ne va que tout droit… sauf si une fleur-miroir la fait tourner. Tourne-les jusqu'à ce que la lumière touche le cœur de bois.", {}), L("L'étang reflète Yggdrasil la tête en bas. Les anciennes disent que l'Arbre pousse aussi dans l'autre sens, sous les nuages.", {})],
				"rumeur": [L("Noisette garde un trésor de graines dans sa poche. Elle croit que personne ne le sait.", {})],
				"interpelle": [L("Doucement…", {})],
			}}, Vector2(-14.0, 52.0)],
		[{"id": "noisette", "nom": "Noisette", "titre": "fée des graines",
			"fee": {"robe": [0.75, 0.5, 0.3], "cheveux": [0.55, 0.3, 0.15], "ailes": [1.0, 0.8, 0.55], "yeux": [0.35, 0.2, 0.1], "fleur": [1.0, 0.6, 0.3]},
			"humeur_base": 0.6, "energie_base": 0.9, "affinite_depart": 10.0,
			"traits": {"bavard": 0.8, "humour": 0.6, "curiosite": 0.9, "susceptible": 0.3, "rancunier": 0.2},
			"aime": {"pomme": 2.0, "baies": 2.0, "noix_coco": 1.5}, "deteste": {"vieille_botte": -1.0},
			"repliques": {
				"accueil": [L("Oh, un grand ! Tu as des graines sur toi ? Non ? Dommage. Bienvenue quand même !", {"visites_max": 1}, "rire"), L("Re-bonjour ! Toujours pas de graines ?", {"visites_min": 2}, "rire")],
				"humeur": [L("Impatiente ! La graine d'Yggdrasil… je rêve de la voir germer.", {"q56": "graine_yggdrasil=en_cours"}), L("Ravie ! J'ai planté la graine moi-même. Enfin, la reine m'a laissée tenir la pelle.", {"q56": "graine_yggdrasil=finie"}, "rire"), L("Curieuse, comme toujours.", {})],
				"lui": [L("Je collectionne les graines. J'en ai de toutes les îles : jungle, elfes, même une graine de cactus des nains. Il ne me manque que la plus belle.", {})],
				"ile": [L("La salle des Saisons ! Il y a une stèle qui dit dans quel ordre fleurissent les saisons. Les fleurs changent de couleur quand on les touche.", {}), L("Yggdrasil a quatre salles, comme les quatre saisons. Et une couronne tout en haut.", {})],
				"rumeur": [L("Perlée parle à ses gouttes de rosée. Elles ne répondent pas. Enfin, je crois.", {}, "rire")],
				"interpelle": [L("Des graines ?", {})],
			}}, Vector2(14.0, 50.0)],
		[{"id": "zephyr", "nom": "Zéphyr", "titre": "fée du vent",
			"fee": {"robe": [0.85, 0.85, 0.95], "cheveux": [0.75, 0.8, 0.95], "ailes": [0.95, 0.95, 1.0], "yeux": [0.3, 0.35, 0.6], "fleur": [0.8, 0.85, 1.0]},
			"humeur_base": 0.6, "energie_base": 1.0, "affinite_depart": 5.0,
			"traits": {"bavard": 0.7, "humour": 0.7, "curiosite": 0.5, "susceptible": 0.6, "rancunier": 0.3},
			"aime": {"plume_ventaile": 3.0, "nectar_fee": 2.0}, "deteste": {"caillou": -1.0},
			"repliques": {
				"accueil": [L("Salut, le terrestre ! Tu marches ? Comme c'est… lent. Bienvenue !", {"visites_max": 1}, "rire"), L("Encore toi ! Tu vas finir par voler, à force.", {"visites_min": 2}, "rire")],
				"humeur": [L("En pleine forme ! J'ai fait trois fois le tour de l'Arbre avant le petit-déjeuner.", {}, "rire")],
				"lui": [L("Je porte les messages entre les îles. Si un jour tu entends le vent siffler ton nom, c'est moi.", {})],
				"ile": [L("Du bord de l'île, on voit tout l'archipel, tout petit, au milieu de la mer. Ne te penche pas trop : les nuages, ça ne porte pas.", {}), L("Quand la reine sera contente de toi, elle t'apprendra peut-être à voyager comme nous : un battement de cils, et hop, ailleurs.", {"q56": "graine_yggdrasil=en_cours"})],
				"rumeur": [L("Lumi croit que ses lucioles l'aiment. Elles aiment surtout le miel qu'elle leur donne.", {}, "rire")],
				"interpelle": [L("Fffiou !", {})],
			}}, Vector2(0.0, 46.0)],
	]


static func all_profiles() -> Array:
	var out: Array = []
	for e in _all():
		var d: Dictionary = Habitants.complete(e[0])
		d["groupe"] = "fees_ygg"
		out.append([d, e[1]])
	return out

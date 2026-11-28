## V220 : en VR, la main droite change d'arme et de pouvoir d'un geste (gestes simulés, comme 65_roue) : la
## poignée tapée reprend l'arme d'avant (mains nues : la meilleure arme) ; tenue, la roue des armes s'ouvre
## autour de la main, on pousse la main vers une case, on relâche ; la roue ne garde que ce qu'on possède et
## qu'on peut tenir (douze cases au plus) ; B tapé lance le pouvoir, B tenu ouvre la roue des pouvoirs ;
## dans l'eau, B garde son usage ; la main droite ne frappe pas pendant qu'elle choisit.
const NOM := "65_roue_armes"
const TETE220 := Vector3(0.0, 1.6, 0.0)


func _geste220(n220: int, poignee220: bool, b220: bool, pos220: Callable) -> void:
	for k220 in range(n220):
		roue_armes_v220.tick(1.0 / 72.0, poignee220, b220, pos220.call(k220), TETE220)


## La place d'un objet dans la roue ouverte (-1 : absent).
func _case220(id220: String) -> int:
	for i220 in range(roue_armes_v220.cases.size()):
		if str(roue_armes_v220.cases[i220]["id"]) == id220:
			return i220
	return -1


## Pousse la main droite de 8 cm vers la case i (la roue est ouverte), puis relâche le bouton.
func _pousser220(i220: int, p0_220: Vector3, poignee220: bool) -> void:
	var d220: Vector2 = roue_armes_v220.dir_case(i220)
	var vers220: Vector3 = roue_armes_v220._plan * Vector3(d220.x, d220.y, 0.0)
	_geste220(20, poignee220, not poignee220, func(k220): return p0_220 + vers220 * (0.08 * float(k220 + 1) / 20.0))


func _serie() -> void:
	var R220: Node3D = roue_armes_v220
	_ok(R220 != null, "le module de la roue de la main droite existe")
	R220.test_mode = true
	_close_dialogue_v31()
	await _att(0.3)
	var p0_220 := Vector3(0.25, 1.2, -0.3)
	var ici220: Callable = func(_k220): return p0_220
	# --- on vide ce qui se tient, on repart de rien
	for id220 in inventory_v28.ITEMS:
		if R220._se_tient(inventory_v28.ITEMS[id220]) and inventory_v28.count(str(id220)) > 0:
			inventory_v28.remove(str(id220), inventory_v28.count(str(id220)))
	inventory_v28.equip_item("")
	R220.reset()
	# (une image sans rien : comme dans le jeu, où la roue est écoutée à chaque image)
	_geste220(1, false, false, ici220)
	var l0_220: Array = R220.liste_armes()
	_ok(l0_220.size() == 1 and str(l0_220[0]["id"]) == "", "rien dans le sac : la roue n'aurait que les mains nues")
	_geste220(30, true, false, ici220)
	_ok(R220.ouverte == "", "poignée tenue sans rien à tenir : la roue ne s'ouvre pas")
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "" and R220.retours == 0, "… et rien ne change")
	# --- quatre choses à tenir
	for id220 in ["epee_bois", "hache", "epee", "canne_peche"]:
		inventory_v28.add(str(id220), 1)
	var l1_220: Array = R220.liste_armes()
	var ids220: Array = []
	for c220 in l1_220:
		ids220.append(str(c220["id"]))
	_ok(ids220.size() == 5 and ids220[0] == "" and ids220.has("epee_bois") and ids220.has("hache") and ids220.has("epee") and ids220.has("canne_peche"),
		"la roue : les mains nues d'abord, puis ce qu'on possède et qu'on peut tenir %s" % str(ids220))
	_ok(not ids220.has("pelle") and not ids220.has("pomme"), "ni ce qu'on n'a pas, ni ce qui ne se tient pas")
	_ok(R220.meilleure_arme() == "epee", "la meilleure arme : l'épée d'acier (%s)" % R220.meilleure_arme())
	# --- la poignée tapée
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "epee" and R220.retours == 1, "poignée tapée, mains nues : la meilleure arme vient en main (%s)" % str(inventory_v28.equipped))
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "", "tapée encore : les mains nues (%s)" % str(inventory_v28.equipped))
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "epee" and R220.retours == 3, "et encore : l'épée revient")
	# --- la poignée tenue : la roue ; on pousse la main vers la hache
	_geste220(24, true, false, ici220)
	_ok(R220.ouverte == "armes" and R220.cases.size() == 5, "poignée tenue : la roue des armes s'ouvre (%d cases)" % R220.cases.size())
	_ok(R220.main_droite_occupee(), "la main droite ne frappe pas pendant qu'elle choisit")
	_ok(R220._roue3d != null and R220._roue3d.visible and R220._slots3d.size() == 5, "elle se voit : cinq cases autour de la main")
	_ok(R220.survol == -1, "la main n'a pas bougé : rien de désigné")
	var ih220: int = _case220("hache")
	_pousser220(ih220, p0_220, true)
	_ok(R220.survol == ih220, "la main poussée vers la hache : elle est désignée (%d)" % R220.survol)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache" and R220.ouverte == "" and R220.choix_faits == 1, "on relâche : la hache est en main (%s)" % str(inventory_v28.equipped))
	_ok(not R220._roue3d.visible and not R220.main_droite_occupee(), "la roue se referme")
	_ok(R220.avant == "epee", "on se souvient de l'arme d'avant (%s)" % R220.avant)
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "epee", "poignée tapée : l'épée d'avant revient")
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache", "tapée encore : la hache")
	# --- par la roue : les mains nues (la case du haut), la canne à pêche
	_geste220(24, true, false, ici220)
	_pousser220(0, p0_220, true)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "", "la case du haut : les mains nues")
	_geste220(24, true, false, ici220)
	_pousser220(_case220("canne_peche"), p0_220, true)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "canne_peche", "la canne à pêche se prend aussi par la roue")
	# --- tenue longtemps sans bouger : rien ne change ; tenue un instant de trop : un coup bref
	var r0_220: int = R220.retours
	_geste220(90, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "canne_peche" and R220.retours == r0_220, "roue ouverte longtemps, rien de désigné : rien ne change")
	_geste220(27, true, false, ici220)
	_ok(R220.ouverte == "armes", "tenue un tiers de seconde : la roue s'ouvre déjà")
	_geste220(2, false, false, ici220)
	_ok(R220.retours == r0_220 + 1 and inventory_v28.equipped == "", "relâchée aussitôt sans rien désigner : c'est un coup bref (l'objet d'avant : %s)" % str(inventory_v28.equipped))
	# --- la main qui bouge pendant l'appui (un coup d'épée, la poignée serrée par habitude) : rien du tout
	inventory_v28.equip_item("hache")
	var r1_220: int = R220.retours
	var c1_220: int = R220.choix_faits
	_geste220(40, true, false, func(k220): return p0_220 + Vector3(0.012 * float(k220), 0.0, -0.008 * float(k220)))
	_ok(R220.ouverte == "", "la poignée serrée pendant un grand geste : la roue ne s'ouvre pas")
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache" and R220.retours == r1_220 and R220.choix_faits == c1_220, "… et l'arme ne change pas")
	_geste220(8, true, false, func(k220): return p0_220 + Vector3(0.02 * float(k220), 0.0, 0.0))
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache" and R220.retours == r1_220, "un appui bref pendant un geste vif : rien non plus")
	# --- la roue ouverte, la main s'en va loin (on y renonce, ou un coup d'épée la poignée serrée) : annulée
	var a0_220: int = R220.annulees
	_geste220(24, true, false, ici220)
	_ok(R220.ouverte == "armes", "la roue est ouverte, la hache en main")
	_geste220(20, true, false, func(k220): return p0_220 + Vector3(0.02 * float(k220 + 1), 0.0, 0.0))
	_ok(R220.ouverte == "" and R220.annulees == a0_220 + 1 and not R220._roue3d.visible, "la main part à quarante centimètres : la roue se referme")
	_ok(not R220.main_droite_occupee(), "… la main droite frappe de nouveau")
	_geste220(30, true, false, ici220)
	_ok(R220.ouverte == "", "la poignée toujours serrée : la roue ne revient pas")
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache" and R220.retours == r1_220 and R220.choix_faits == c1_220, "on relâche : rien n'a changé")
	# --- la roue ouverte, le jeu passe à autre chose (le sac, le menu, une conversation) : elle se referme seule
	_geste220(24, true, false, ici220)
	_pousser220(_case220("epee"), p0_220, true)
	_ok(R220.ouverte == "armes" and R220.survol == _case220("epee"), "la roue est ouverte, l'épée désignée")
	await _att(0.3)
	_ok(R220.ouverte == "" and not R220._roue3d.visible and R220.annulees == a0_220 + 2, "le jeu n'écoute plus la roue : elle se referme seule")
	_geste220(3, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "hache" and R220.retours == r1_220 and R220.choix_faits == c1_220, "… sans rien prendre, et la poignée relâchée ensuite ne change rien")
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.retours == r1_220 + 1, "la poignée tapée de nouveau : elle répond comme avant")
	# --- le jeu était ailleurs (un objet jeté avec la poignée, le sac refermé) : la poignée encore serrée ne compte pas
	await _att(0.2)
	var r2_220: int = R220.retours
	_geste220(4, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.retours == r2_220, "le jeu revient, la poignée encore serrée : elle ne compte pas")
	_geste220(30, true, false, ici220)
	_ok(R220.ouverte == "armes", "serrée de nouveau : la roue s'ouvre")
	_geste220(60, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.ouverte == "" and R220.retours == r2_220, "… et se referme sans rien changer")
	inventory_v28.equip_item("")
	_geste220(1, false, false, ici220)
	# --- on tient autre chose par le sac : la roue s'en souvient aussi
	inventory_v28.equip_item("epee_bois")
	_geste220(6, true, false, ici220)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "", "une arme prise par le sac, poignée tapée : on revient à ce qu'on tenait avant")
	# --- beaucoup d'armes : douze cases au plus, les plus faibles restent au sac
	var toutes220: Array = []
	for id220 in inventory_v28.ITEMS:
		if R220._se_tient(inventory_v28.ITEMS[id220]):
			toutes220.append(str(id220))
			if inventory_v28.count(str(id220)) == 0:
				inventory_v28.add(str(id220), 1)
	var l2_220: Array = R220.liste_armes()
	var ids2_220: Array = []
	for c220 in l2_220:
		ids2_220.append(str(c220["id"]))
	_ok(toutes220.size() >= 12, "le jeu compte %d choses à tenir" % toutes220.size())
	_ok(l2_220.size() == R220.PLACES_MAX and ids2_220[0] == "", "tout dans le sac : douze cases, les mains nues d'abord (%d)" % l2_220.size())
	_ok(not ids2_220.has("epee_bois") and ids2_220.has("epee_nuees") and ids2_220.has("canne_peche") and ids2_220.has("pelle"),
		"les armes les plus faibles restent au sac ; les outils et les meilleures armes sont là")
	_geste220(24, true, false, ici220)
	_ok(R220.ouverte == "armes" and R220._slots3d.size() == 12, "la grande roue s'ouvre (%d cases)" % R220._slots3d.size())
	var in220: int = _case220("epee_nuees")
	_pousser220(in220, p0_220, true)
	_ok(R220.survol == in220, "douze cases : on désigne encore la bonne (%d)" % R220.survol)
	_geste220(2, false, false, ici220)
	_ok(inventory_v28.equipped == "epee_nuees", "l'Épée des Nuées est en main")
	# --- les pouvoirs : aucun sceau
	var sceaux220: Dictionary = progression_v63.seals.duplicate()
	var pouvoir220: String = progression_v63.power
	progression_v63.seals.clear()
	progression_v63.power = ""
	var la220: int = R220.lances
	_geste220(30, false, true, ici220)
	_ok(R220.ouverte == "", "aucun pouvoir : B tenu n'ouvre pas de roue")
	_geste220(2, false, false, ici220)
	_ok(R220.lances == la220 + 1, "… et au relâchement, le jeu dit qu'on n'a pas encore de pouvoir")
	# --- deux sceaux : le vent et la flamme
	progression_v63.seals[str(progression_v63.POWER_OF["vent"])] = true
	progression_v63.seals[str(progression_v63.POWER_OF["flamme"])] = true
	progression_v63.power = "vent"
	var lp220: Array = R220.liste_pouvoirs()
	var eveilles220: int = 0
	for c220 in lp220:
		if bool(c220["ok"]):
			eveilles220 += 1
	_ok(lp220.size() == 4 and eveilles220 == 2, "la roue des pouvoirs : quatre cases, deux éveillées (%d)" % eveilles220)
	_geste220(24, false, true, ici220)
	_ok(R220.ouverte == "pouvoirs" and R220.cases.size() == 4, "B tenu : la roue des pouvoirs s'ouvre")
	_pousser220(_case220("flamme"), p0_220, false)
	_geste220(2, false, false, ici220)
	_ok(progression_v63.power == "flamme" and R220.ouverte == "", "la main poussée vers la Flamme, on relâche : c'est le pouvoir choisi (%s)" % progression_v63.power)
	_geste220(24, false, true, ici220)
	_pousser220(_case220("lune"), p0_220, false)
	_geste220(2, false, false, ici220)
	_ok(progression_v63.power == "flamme", "un pouvoir qui dort encore ne se choisit pas (%s)" % progression_v63.power)
	# --- la roue des pouvoirs annulée : la main s'en va loin, rien n'est lancé
	progression_v63.power = "vent"
	var lz220: int = R220.lances
	_geste220(24, false, true, ici220)
	_geste220(20, false, true, func(k220): return p0_220 + Vector3(0.0, 0.02 * float(k220 + 1), 0.0))
	_ok(R220.ouverte == "", "la roue des pouvoirs, la main partie loin : elle se referme")
	_geste220(2, false, false, ici220)
	_ok(progression_v63.power == "vent" and R220.lances == lz220, "… le pouvoir ne change pas, rien n'est lancé")
	progression_v63.power = "flamme"
	# --- B tapé : le pouvoir part
	hero_v28.stamina = hero_v28.STAMINA_MAX if hero_v28.get("STAMINA_MAX") != null else hero_v28.stamina
	pouvoirs_v63._cd.clear()
	var lb220: int = R220.lances
	var cercles220: int = int(combat_fx_v129.count.get("cercle", 0))
	_geste220(6, false, true, ici220)
	_geste220(2, false, false, ici220)
	await _images(2)
	_ok(R220.lances == lb220 + 1, "B tapé : le pouvoir est lancé")
	_ok(int(combat_fx_v129.count.get("cercle", 0)) > cercles220, "… son cercle de runes paraît")
	# --- le jeu était ailleurs (une conversation fermée avec B) : B encore tenu en revenant ne lance rien
	await _att(0.2)
	var lr220: int = R220.lances
	_geste220(5, false, true, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.lances == lr220, "le jeu revient, B encore tenu : rien n'est lancé")
	_geste220(5, false, true, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.lances == lr220 + 1, "B tapé ensuite : le pouvoir part")
	# --- B tenu pendant un grand geste : pas de roue, le pouvoir part quand même
	pouvoirs_v63._cd.clear()
	var lm220: int = R220.lances
	_geste220(40, false, true, func(k220): return p0_220 + Vector3(0.012 * float(k220), 0.0, 0.0))
	_ok(R220.ouverte == "", "B tenu pendant un grand geste : la roue ne s'ouvre pas")
	_geste220(2, false, false, ici220)
	_ok(R220.lances == lm220 + 1 and progression_v63.power == "flamme", "… le pouvoir choisi part, il ne change pas")
	# --- dans l'eau, B sert à plonger
	var nage220: bool = bool(mer_v55.swimming)
	mer_v55.swimming = true
	var lc220: int = R220.lances
	_ok(R220.b_comme_avant(), "dans l'eau : B garde son usage d'avant")
	_geste220(30, false, true, ici220)
	_ok(R220.ouverte == "", "dans l'eau : B tenu n'ouvre pas la roue des pouvoirs")
	_geste220(2, false, false, ici220)
	_ok(R220.lances == lc220, "… et ne lance rien par la roue")
	_geste220(3, false, true, ici220)
	mer_v55.swimming = false
	_geste220(3, false, true, ici220)
	_geste220(2, false, false, ici220)
	_ok(R220.lances == lc220, "on sort de l'eau B encore tenu : rien n'est lancé")
	mer_v55.swimming = nage220
	# --- on remet tout en place
	progression_v63.seals = sceaux220
	progression_v63.power = pouvoir220
	inventory_v28.equip_item("")
	R220.reset()
	R220.test_mode = false
	# --- le chemin du casque, sans casque : les manettes au repos, rien ne se passe ; le rappel, une seule fois
	var rv220: int = R220.retours
	var lv220: int = R220.lances
	for k220 in range(6):
		R220.vr_tick(1.0 / 72.0)
	_ok(R220.ouverte == "" and R220.retours == rv220 and R220.lances == lv220, "le chemin du casque, manettes au repos : rien ne se passe")
	R220.conseil_donne = false
	R220._conseil_t = 0.0
	R220._conseil(30.0)
	_ok(R220.conseil_donne and str(message.text).begins_with("Dans le casque"), "le rappel des trois gestes s'affiche (%s…)" % str(message.text).left(24))
	message.text = ""
	R220._conseil(30.0)
	_ok(str(message.text) == "", "… une seule fois")
	var cf220 := ConfigFile.new()
	_ok(cf220.load(R220.FICHIER) == OK and bool(cf220.get_value("conseil", "vu", false)), "… et c'est retenu d'une partie à l'autre")
	# --- les icônes dessinées
	var noires220: Array = []
	for nom220 in ["main", "lune", "rouage", "vent"]:
		var img220: Image = R220.icone(str(nom220)).get_image()
		var pleins220: int = 0
		for y220 in range(0, 64, 2):
			for x220 in range(0, 64, 2):
				if img220.get_pixel(x220, y220).a > 0.5:
					pleins220 += 1
		if pleins220 < 60 or pleins220 > 900:
			noires220.append("%s:%d" % [str(nom220), pleins220])
	_ok(noires220.is_empty(), "les quatre icônes de la roue sont dessinées %s" % str(noires220))
	# --- dans le casque, tout est dessiné pendant le chargement (ici, sans casque : rien avant qu'on le demande)
	_ok(not R220.prepare, "sans casque, rien n'est préparé d'avance")
	R220.preparer()
	_ok(R220.prepare and R220._pastille != null and R220._anneau != null and R220._icones.size() >= 4, "préparées : les pastilles et les icônes de la main droite")
	var faites220: int = 0
	for id220 in roue_v145._ordre():
		if roue_v145._icones.has(str(id220)):
			faites220 += 1
	_ok(faites220 == roue_v145._ordre().size() and faites220 >= 6, "… et les %d icônes de la roue des sorts" % faites220)
	# --- en anglais
	var L220 = load("res://scripts/langue_v104.gd")
	L220.choisir("en", false)
	var t1_220: String = L220.t("Mains nues")
	var t2_220: String = L220.t("dégâts : %d") % 6
	L220.choisir("fr", false)
	_ok(t1_220 == "Bare hands", "anglais : « %s »" % t1_220)
	_ok(t2_220 == "damage: 6", "anglais : « %s »" % t2_220)
	await _att(0.3)
	var debout220: bool = await _debout("après la roue")
	_ok(debout220, "le héros tient debout")
	_ranger()

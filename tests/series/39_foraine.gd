## L'Île Foraine, V209 : l'île existe (le relief, le ponton, le Grand Portail, le quai) ; on y arrive par
## le mode testeur et par la téléportation, debout ; sans billet la barrière est fermée et le grand huit
## refuse ; le billet s'achète en pièces (pas assez : refusé ; assez : la bourse baisse, la barrière
## s'ouvre, il vaut pour la journée) ; la voie du Grand Frisson (sa longueur, sa hauteur, le sol toujours
## sous les rails, les poteaux) ; on monte au premier rang, on peut redescendre avant le départ ; un tour
## entier : le sommet, la vitesse, la tête en bas dans la boucle, le retour à quai, le héros reposé sur le
## quai, la caméra rendue ; « en douceur » : l'horizon reste droit jusque dans la boucle ; en réalité
## virtuelle, la tête est bien au siège ; la sauvegarde garde le billet et les tours ; la quête du carnet.
const NOM := "39_foraine"
const Ile209 := preload("res://scripts/ile_foraine_v209.gd")
const Trace209 := preload("res://scripts/grand_huit_trace_v209.gd")


func _plat209(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _serie() -> void:
	var fo209: Node3D = foraine_v209
	_ok(fo209 != null and fo209.ile != null and fo209.huit != null, "l'Île Foraine et son grand huit sont construits")
	if fo209 == null or fo209.ile == null or fo209.huit == null:
		return
	var hu209: Node3D = fo209.huit
	var c209: Vector3 = Ile209.CENTER
	_ok(_height_at(c209.x - 20.0, c209.z + 20.0) > 2.0 and _height_at(c209.x - 20.0, c209.z + 20.0) < 4.5, "la Place du Mât est sur l'esplanade, à 3 m au-dessus de la mer")
	_ok(_height_at(c209.x + 18.0, c209.z - 116.0) > 15.0, "la Butte aux Frissons s'élève au nord")
	_ok(_height_at(c209.x + 280.0, c209.z) < -10.0, "la mer est profonde au large")
	var dock209: Array = fo209.dock()
	_ok(_height_at((dock209[0] as Vector3).x, (dock209[0] as Vector3).z) > -1.5 and _height_at((dock209[1] as Vector3).x, (dock209[1] as Vector3).z) < -1.0, "le ponton part de la grève et finit dans l'eau")
	_ok(teleport_v58.place_name("foraine") != "foraine" and not teleport_v58.spot("foraine").is_empty() and not teleport_v58.spot("foraine_quai").is_empty(), "l'île est dans la téléportation (le portail, le quai)")
	_ok(testeur_v78.RECENTES_V206.has("foraine") and testeur_v78.RECENTES_V206.has("foraine_quai"), "l'île est en tête du mode testeur")
	# on arrive devant le Grand Portail
	_ranger()
	var sp209: Array = teleport_v58.spot("foraine")
	await _poser(sp209[0], sp209[1])
	_ok(await _debout("devant le Grand Portail"), "on tient debout devant le Grand Portail")
	await _att(0.6)
	_ok(str(journal_v56.place_name(_pos())).begins_with("Île Foraine"), "le lieu s'appelle l'Île Foraine (%s)" % str(journal_v56.place_name(_pos())))
	_ok(teleport_v58.current_place() == "foraine", "on est bien à « foraine » (%s)" % teleport_v58.current_place())
	_ok(bool(fo209.state["visite"]), "l'île est notée visitée")
	# sans billet
	fo209.state["billet_jour"] = -1
	await _images(3)
	_ok(not fo209.billet_valide() and not fo209._barriere.disabled, "sans billet, la barrière du tourniquet est fermée")
	_ok(not fo209.monter() and not fo209.riding(), "sans billet, le Grand Frisson refuse")
	var bourse209: int = int(inventory_v28.count("piece"))
	if bourse209 > 0:
		inventory_v28.remove("piece", bourse209)
	_ok(not fo209.acheter_billet() and not fo209.billet_valide(), "sans pièces, pas de billet")
	inventory_v28.add("piece", 40)
	_ok(fo209.acheter_billet() and fo209.billet_valide(), "avec 40 pièces, on achète le billet")
	_ok(int(inventory_v28.count("piece")) == 40 - fo209.PRIX, "le billet coûte %d pièces (reste %d)" % [fo209.PRIX, int(inventory_v28.count("piece"))])
	_ok(not fo209.acheter_billet() and int(inventory_v28.count("piece")) == 40 - fo209.PRIX, "on ne paie pas deux fois le même jour")
	await _images(3)
	_ok(fo209._barriere.disabled, "avec le billet, la barrière est ouverte")
	var jour209: int = int(temps_v56.day_count)
	temps_v56.day_count = jour209 + 1
	_ok(not fo209.billet_valide(), "le lendemain, il faut un nouveau billet")
	temps_v56.day_count = jour209
	# on passe le tourniquet à pied
	var avant209: Vector3 = _pos()
	_touche(KEY_Z, true)
	for k209 in range(60):
		pc_root.rotation.y = atan2(-1.0, 0.0)
		await _att(0.1)
		if _pos().x > fo209.portail_pos.x + 3.0:
			break
	_touche(KEY_Z, false)
	_ok(_pos().x > fo209.portail_pos.x + 1.0, "on passe le tourniquet à pied (de x %.1f à x %.1f, le portail à %.1f)" % [avant209.x, _pos().x, fo209.portail_pos.x])
	# la voie
	var d209: Dictionary = hu209.d
	var pts209: PackedVector3Array = d209["pts"]
	var hauts209: PackedVector3Array = d209["haut"]
	_ok(int(d209["n"]) > 1500 and float(d209["longueur"]) < 2200.0, "la voie fait %d m" % int(d209["longueur"]))
	_ok(pts209[int(d209["sommet"])].y > 50.0, "le sommet est à %.0f m" % pts209[int(d209["sommet"])].y)
	var pire209: float = 99.0
	var tete_bas209: int = 0
	for i209 in range(pts209.size()):
		var p209: Vector3 = pts209[i209]
		pire209 = minf(pire209, p209.y - float(fo209.ile.height_l(p209.x, p209.z)))
		if hauts209[i209].y < -0.5:
			tete_bas209 += 1
	_ok(pire209 > 1.6, "le sol reste partout sous les rails (au plus près : %.1f m)" % pire209)
	# V213 : l'île volcanique
	var il213: Node3D = fo209.ile
	_ok(float(il213.height_l(18.0 + 34.0, -116.0)) > 45.0 and float(il213.height_l(18.0, -116.0 - 34.0)) > 45.0, "V213 : la crête du volcan dépasse 45 m (%.0f m à l'est)" % float(il213.height_l(52.0, -116.0)))
	_ok(absf(float(il213.height_l(18.0, -116.0)) - 21.0) < 0.6 and float(il213.height_l(18.0 - 18.0, -116.0)) < 20.5, "V213 : au fond du cratère, l'îlot de la Chute et la croûte de lave autour")
	_ok(float(il213.height_l(18.0, -90.0)) < 26.0 and float(il213.height_l(18.0 + 14.0, -84.0)) > 34.0, "V213 : la Brèche entaille le flanc jusqu'au cratère (le sentier à %.0f m, la paroi à %.0f m)" % [float(il213.height_l(18.0, -90.0)), float(il213.height_l(32.0, -84.0))])
	_ok(float(il213.height_l(121.5, -30.0)) < 6.0 and float(il213.height_l(121.5 + 11.0, -30.0)) > 11.0 and float(il213.height_l(121.5 - 11.0, -30.0)) > 11.0, "V213 : la Faille : la voie passe entre deux parois de basalte (le fond à %.1f m, les bords à %.0f et %.0f m)" % [float(il213.height_l(121.5, -30.0)), float(il213.height_l(110.5, -30.0)), float(il213.height_l(132.5, -30.0))])
	var vo213: Node3D = fo209.volcan
	_ok(vo213 != null and int(vo213.colonnes) > 600 and int(vo213.bouquets) > 30, "V213 : %d colonnes de basalte en %d bouquets le long de la voie" % [int(vo213.colonnes), int(vo213.bouquets)])
	_ok(int(vo213.arches) == 4 and float(vo213.au_plus_pres) > 3.0, "V213 : quatre arches de roche ; rien à moins de %.1f m de l'axe de la voie" % float(vo213.au_plus_pres))
	_ok(vo213.lueurs.size() == 2 and vo213.get_node_or_null("Panache_v213") != null, "V213 : le panache du cratère, la lueur de la lave")

	# V214 : les bornes « monter ici », les invites pendant que ça tourne, les lampions
	var fo214: Node3D = foraine_v209
	_ok(fo214.bornes.size() == 4, "V214 : une borne « monter ici » par attraction (%d)" % fo214.bornes.size())
	var pres214: bool = true
	for bk214 in range(fo214.bornes.size()):
		var bo214: Dictionary = fo214.bornes[bk214]
		var ma214: Node3D = bo214["manege"]
		pres214 = pres214 and (bo214["disque"] as Node3D).global_position.distance_to(ma214.quai_pos) < 0.3
	_ok(pres214, "V214 : chaque disque est à l'endroit exact où l'on monte")
	fo214.state["billet_jour"] = -5
	fo214._bornes(0.0, true)
	var eb214: String = fo214.etat_borne(0)
	_ok(eb214 == "billet" or eb214 == "marche", "V214 : sans billet, la borne le dit (%s)" % eb214)
	fo214.offrir_billet()
	fo214._bornes(0.0, true)
	var ep214: String = fo214.etat_borne(0)
	_ok(ep214 == "pret" or ep214 == "marche", "V214 : avec le billet, la borne passe au vert (%s)" % ep214)
	var ids214: Array = []
	for in214 in fo214._interactions:
		ids214.append(str(in214["id"]))
	_ok(ids214.has("fo_attendre") and ids214.has("fo_attendre_marteau"), "V214 : une invite aussi pendant que l'attraction tourne")
	_ok(int(fo214.lampions["portiques"]) > 20 and int(fo214.lampions["lampions"]) > 160 and fo214.get_node_or_null("Guirlandes_v214") != null, "V214 : les portiques de lampions le long des allées (%d portiques, %d lampions)" % [int(fo214.lampions["portiques"]), int(fo214.lampions["lampions"])])
	# V214 : la barque — la bôme au-dessus de la tête, la voile ouverte sur le côté
	var gr214: Node3D = boat_v29.hull.find_child("Greement_v214", true, false) as Node3D
	if gr214 != null:
		var vo214: Node3D = gr214.get_node("Voile") as Node3D
		var bas214: float = (vo214 as MeshInstance3D).get_aabb().position.y
		_ok(bas214 > 2.0 and absf(gr214.rotation.y) > 0.3, "V214 : la voile de la barque passe au-dessus de la tête (bas à %.2f m) et s'ouvre sur le côté" % bas214)
	else:
		_ok(float(boat_v29.BOME_Y) > 2.0, "V214 : la bôme de la barque au-dessus de la tête (autre coque à l'essai)")
	_ok(tete_bas209 > 20 and tete_bas209 < 120, "on a la tête en bas sur %d m (la boucle, la vrille)" % tete_bas209)
	_ok(int(hu209.supports) > 120, "%d poteaux portent la voie" % int(hu209.supports))
	_ok(hu209.wagons.size() == 3, "le train a trois wagons")
	# le quai
	_ranger()
	var sq209: Array = teleport_v58.spot("foraine_quai")
	await _poser(sq209[0], sq209[1])
	_ok(await _debout("sur le quai"), "on tient debout sur le quai")
	_ok(absf(_pos().y - fo209.QUAI_Y) < 0.6, "le quai est à %.1f m (on est à %.1f)" % [fo209.QUAI_Y, _pos().y])
	_ok(teleport_v58.current_place() == "foraine_quai", "on est bien à « foraine_quai » (%s)" % teleport_v58.current_place())
	# le train tourne tout seul : s'il est en route, on attend son retour
	for w209 in range(400):
		if hu209.a_quai():
			break
		await _att(0.5)
	_ok(_plat209(hu209.quai_pos, (hu209.wagons[0] as Node3D).global_position) < 5.0, "le premier wagon attend devant l'embarquement")
	# monter, redescendre avant le départ
	hu209.etat = "quai"
	hu209.attente = 30.0
	hu209.pos = float(int(d209["arret"])) * float(d209["pas"])
	_ok(fo209.monter() and fo209.riding(), "avec le billet, on monte au premier rang")
	await _images(3)
	_ok(hu209._cam.current, "la vue est celle du wagon")
	_ok(_plat209(hu209._cam.global_position, (hu209.wagons[0] as Node3D).global_position) < 1.5, "les yeux sont dans le premier wagon")
	_ok(str(fo209.ride_prompt()).contains("descendre"), "à quai, on peut encore descendre (%s)" % str(fo209.ride_prompt()))
	fo209.ride_interact()
	await _images(3)
	_ok(not fo209.riding() and pc_camera.current and _plat209(_pos(), hu209.quai_pos) < 1.5, "on redescend sur le quai avant le départ")
	# un tour entier, toutes les sensations
	fo209.state["doux"] = false
	hu209.attente = 30.0
	_ok(fo209.monter(), "on remonte")
	hu209.attente = 0.2
	var haut_max209: float = 0.0
	var bas209: float = 1.0
	var pas209: int = 0
	var tours0_209: int = int(hu209.tours)
	while hu209.a_bord and pas209 < 40000:
		hu209.avancer(0.02)
		pas209 += 1
		var w209: Transform3D = (hu209.wagons[0] as Node3D).global_transform
		haut_max209 = maxf(haut_max209, w209.origin.y)
		bas209 = minf(bas209, w209.basis.y.y)
		if pas209 % 400 == 0:
			hu209._porter(0.02)
			await _images(1)
	_ok(not hu209.a_bord and int(hu209.tours) == tours0_209 + 1, "le tour se termine à quai (%.0f s de manège)" % (pas209 * 0.02))
	_ok(pas209 * 0.02 > 90.0 and pas209 * 0.02 < 200.0, "le tour dure entre une minute et demie et trois minutes")
	_ok(haut_max209 > 50.0, "le train monte à %.0f m" % haut_max209)
	_ok(float(hu209.vmax_tour) > 28.0 and float(hu209.vmax_tour) < 36.0, "il atteint %d km/h" % int(float(hu209.vmax_tour) * 3.6))
	_ok(bas209 < -0.8, "il passe la tête en bas")
	await _images(3)
	_ok(pc_camera.current and not hu209._cam.current, "la caméra du héros est rendue")
	_ok(_plat209(_pos(), hu209.quai_pos) < 1.5 and await _debout("après le tour"), "le héros est reposé sur le quai, debout")
	_ok(hero_v28.hero == null or (hero_v28.hero as Node3D).visible, "le héros est de nouveau visible")
	await _att(0.3)
	_ok(int(fo209.trouvailles().get("fo_tour", 0)) == 1 and int(fo209.trouvailles().get("fo_billet", 0)) == 1, "le carnet note le billet et le tour")
	# en douceur : l'horizon reste droit dans la boucle
	fo209.changer_sensations()
	_ok(bool(fo209.state["doux"]), "le panneau règle les sensations « en douceur »")
	hu209.etat = "quai"
	hu209.attente = 30.0
	_ok(fo209.monter(), "on remonte, en douceur")
	hu209.attente = 0.2
	var penche209: float = 1.0
	var pas2_209: int = 0
	while hu209.a_bord and pas2_209 < 40000:
		hu209.avancer(0.02)
		pas2_209 += 1
		if pas2_209 % 5 == 0:
			hu209._porter(0.1)
			penche209 = minf(penche209, hu209._cam.global_transform.basis.y.y)
		if pas2_209 % 800 == 0:
			await _images(1)
	_ok(penche209 > 0.99, "en douceur, la vue reste droite tout le tour (au pire %.3f)" % penche209)
	fo209.changer_sensations()
	# en réalité virtuelle : la tête au siège, le monde penché avec le wagon
	if xr_origin != null and xr_camera != null and vr_body != null:
		var garde209: Transform3D = xr_origin.global_transform
		hu209.pos = float(int(d209["boucle0"]) + 55) * float(d209["pas"])
		hu209._placer_wagons()
		hu209.a_bord = true
		hu209.doux = false
		hu209._tete0 = xr_camera.position
		hu209._lacet0 = 0.0
		xr_active = true
		hu209._porter(0.0)
		xr_active = false
		hu209.a_bord = false
		var tete209: Vector3 = xr_origin.global_transform * xr_camera.position
		_ok(tete209.distance_to(hu209.siege().origin) < 0.05, "en VR, la tête est au siège du premier rang (écart %.3f m)" % tete209.distance_to(hu209.siege().origin))
		_ok(xr_origin.global_transform.basis.y.y < 0.0, "en VR, dans la boucle, le monde est retourné avec le wagon")
		xr_origin.global_transform = garde209
		hu209.pos = float(int(d209["arret"])) * float(d209["pas"])
		hu209._placer_wagons()
		_ok(absf(xr_origin.global_transform.basis.y.y - 1.0) < 0.001, "en VR, tout est remis droit après")
	# la sauvegarde
	var sauve209: Dictionary = fo209.serialize()
	fo209.load_data({})
	_ok(not fo209.billet_valide() and int(fo209.state["tours"]) == 0, "une nouvelle partie n'a ni billet ni tour")
	fo209.load_data(JSON.parse_string(JSON.stringify(sauve209)))
	_ok(fo209.billet_valide() and int(fo209.state["tours"]) >= 1, "la sauvegarde garde le billet du jour et les tours")
	var quete209: bool = false
	for q209 in journal_v56.AVENTURES:
		if str((q209 as Dictionary).get("id", "")) == "foraine":
			quete209 = true
	_ok(quete209, "le carnet a la quête « La fête foraine »")

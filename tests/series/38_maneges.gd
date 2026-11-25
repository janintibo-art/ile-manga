## Les manèges à sensations de l'Île Foraine, V210 : le Marteau, la Chute et la Grande Balançoire sont
## construits, loin de la voie du grand huit ; on arrive devant chacun par la téléportation, debout ;
## sans billet ils refusent ; on monte, on peut redescendre avant le départ ; un tour entier de chacun :
## la hauteur, la vitesse, ce qu'on pèse, la tête en bas (le Marteau), la chute libre (la Chute), plus
## haut que l'horizontale (la Balançoire) ; à la fin tout revient à l'arrêt, le héros est reposé à
## l'embarquement, la caméra rendue ; « en douceur » : la vue reste droite ; en réalité virtuelle la
## tête est au siège ; on ne monte pas dans deux manèges à la fois ; la sauvegarde garde les tours.
const NOM := "38_maneges"
const Trace210 := preload("res://scripts/grand_huit_trace_v209.gd")


func _plat210(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Un tour entier, pas à pas : rend [durée, la plus basse valeur de « haut.y » du siège, pire écart tête-siège]
func _tour210(m210: Node3D, fo210: Node3D) -> Array:
	var pas210: int = 0
	var bas210: float = 1.0
	m210.attente = 0.2
	while m210.a_bord and pas210 < 20000:
		m210.avancer(0.02)
		pas210 += 1
		bas210 = minf(bas210, m210.siege().basis.y.y)
		if pas210 % 300 == 0:
			m210._porter(0.02)
			await _images(1)
	fo210._process(0.02)
	return [pas210 * 0.02, bas210]


func _serie() -> void:
	var fo210: Node3D = foraine_v209
	_ok(fo210 != null and fo210.ile != null and fo210.maneges.size() == 3, "l'Île Foraine a ses trois manèges à sensations")
	if fo210 == null or fo210.ile == null or fo210.maneges.size() != 3:
		return
	var ma210: Node3D = fo210.manege("marteau")
	var ch210: Node3D = fo210.manege("chute")
	var ba210: Node3D = fo210.manege("balancoire")
	_ok(ma210 != null and ch210 != null and ba210 != null, "le Marteau, la Chute, la Grande Balançoire")
	# loin de la voie du grand huit : aucun siège ne passe à moins de 12 m des rails
	var d210: Dictionary = Trace210.tracer()
	var pts210: PackedVector3Array = d210["pts"]
	var c210: Vector3 = fo210.ile.CENTER
	for m210 in fo210.maneges:
		var mm210: Node3D = m210
		mm210.etat = "marche"
		mm210.t = 0.0
		mm210.fini = false
		mm210._remise()
		var pres210: float = 999.0
		var garde210: int = 0
		while not bool(mm210.fini) and garde210 < 20000:
			mm210.t += 0.05
			mm210._poser(0.05)
			garde210 += 1
			if garde210 % 4 == 0:
				var o210: Vector3 = mm210.siege().origin - c210
				for i210 in range(0, pts210.size(), 3):
					pres210 = minf(pres210, o210.distance_to(pts210[i210]))
		mm210.etat = "quai"
		mm210.attente = 40.0
		mm210.t = 0.0
		mm210.fini = false
		mm210._remise()
		mm210._poser(0.0)
		_ok(pres210 > 12.0, "%s : le siège reste à plus de 12 m des rails du grand huit (au plus près %.1f m)" % [str(mm210.titre), pres210])
	_ok(not teleport_v58.spot("foraine_marteau").is_empty() and not teleport_v58.spot("foraine_chute").is_empty() and not teleport_v58.spot("foraine_balancoire").is_empty(), "les trois manèges sont dans la téléportation")
	_ok(testeur_v78.RECENTES_V206.has("foraine_marteau") and testeur_v78.RECENTES_V206.has("foraine_chute") and testeur_v78.RECENTES_V206.has("foraine_balancoire"), "ils sont en tête du mode testeur")
	fo210.state["doux"] = false
	var lieux210: Array = [["foraine_marteau", ma210], ["foraine_chute", ch210], ["foraine_balancoire", ba210]]
	for paire210 in lieux210:
		var m2_210: Node3D = paire210[1]
		var nom210: String = str(m2_210.titre)
		_ranger()
		var sp210: Array = teleport_v58.spot(str(paire210[0]))
		await _poser(sp210[0], sp210[1])
		_ok(await _debout(nom210), "%s : on tient debout à l'embarquement" % nom210)
		await _att(0.6)
		_ok(teleport_v58.current_place() == str(paire210[0]), "%s : on est bien à « %s » (%s)" % [nom210, str(paire210[0]), teleport_v58.current_place()])
		_ok(_plat210(_pos(), m2_210.quai_pos) < 1.5, "%s : on est à l'embarquement" % nom210)
		# sans billet
		fo210.state["billet_jour"] = -1
		m2_210.etat = "quai"
		m2_210.attente = 40.0
		_ok(not fo210.monter_manege(m2_210) and not fo210.riding(), "%s : sans billet, on ne monte pas" % nom210)
		fo210.offrir_billet()
		# on monte, on redescend avant le départ
		_ok(fo210.monter_manege(m2_210) and fo210.riding() and bool(m2_210.a_bord), "%s : avec le billet, on monte" % nom210)
		await _images(3)
		_ok(m2_210._cam.current, "%s : la vue est celle du siège" % nom210)
		_ok(m2_210._cam.global_position.distance_to(m2_210.siege().origin) < 0.05, "%s : les yeux sont au siège" % nom210)
		_ok(str(fo210.ride_prompt()).contains("descendre"), "%s : à l'arrêt, on peut encore descendre (%s)" % [nom210, str(fo210.ride_prompt())])
		_ok(not fo210.monter() and not fo210.monter_manege(lieux210[(lieux210.find(paire210) + 1) % 3][1]), "%s : assis là, on ne monte pas ailleurs" % nom210)
		fo210.ride_interact()
		await _images(3)
		_ok(not fo210.riding() and pc_camera.current and _plat210(_pos(), m2_210.quai_pos) < 1.5, "%s : on redescend avant le départ" % nom210)
		# un tour entier, toutes les sensations
		m2_210.attente = 30.0
		_ok(fo210.monter_manege(m2_210), "%s : on remonte" % nom210)
		var tours0_210: int = int(m2_210.tours)
		var r210: Array = await _tour210(m2_210, fo210)
		_ok(not bool(m2_210.a_bord) and int(m2_210.tours) == tours0_210 + 1 and m2_210.a_quai(), "%s : le tour se termine à l'arrêt (%.0f s)" % [nom210, float(r210[0])])
		_ok(float(r210[0]) > 35.0 and float(r210[0]) < 90.0, "%s : le tour dure entre 35 s et une minute et demie" % nom210)
		await _images(3)
		_ok(pc_camera.current and not m2_210._cam.current, "%s : la caméra du héros est rendue" % nom210)
		_ok(_plat210(_pos(), m2_210.quai_pos) < 1.5 and await _debout("après " + nom210), "%s : le héros est reposé à l'embarquement, debout" % nom210)
		_ok(hero_v28.hero == null or (hero_v28.hero as Node3D).visible, "%s : le héros est de nouveau visible" % nom210)
		_ok(int(fo210.trouvailles().get("fo_" + str(m2_210.cle), 0)) == 1, "%s : le carnet note le tour" % nom210)
		match str(m2_210.cle):
			"marteau":
				_ok(float(m2_210.hmax_tour) > 55.0 and float(m2_210.hmax_tour) < 64.0, "le Marteau monte à %.0f m" % float(m2_210.hmax_tour))
				_ok(float(m2_210.vmax_tour) > 23.0 and float(m2_210.vmax_tour) < 32.0, "le Marteau atteint %d km/h" % int(float(m2_210.vmax_tour) * 3.6))
				_ok(float(r210[1]) < -0.8, "le Marteau nous met la tête en bas (%.2f)" % float(r210[1]))
				_ok(float(m2_210.gmax_tour) > 2.5 and float(m2_210.gmax_tour) < 5.5, "le Marteau : jusqu'à %.1f g" % float(m2_210.gmax_tour))
				_ok(absf(float(m2_210.theta)) < 0.001 and absf((m2_210.nacelles[0] as Node3D).position.y - (m2_210.H_AXE - m2_210.R)) < 0.01, "le Marteau s'arrête, notre nacelle en bas")
			"chute":
				_ok(float(m2_210.hmax_tour) > 74.0, "la Chute monte à %.0f m" % float(m2_210.hmax_tour))
				_ok(float(m2_210.vmax_tour) > 26.0 and float(m2_210.vmax_tour) < 31.0, "la Chute atteint %d km/h" % int(float(m2_210.vmax_tour) * 3.6))
				_ok(float(m2_210.gmax_tour) > 2.2 and float(m2_210.gmax_tour) < 3.4, "la Chute : %.1f g dans les freins" % float(m2_210.gmax_tour))
				_ok(float(r210[1]) > 0.99, "la Chute reste bien droite")
				_ok(absf(float(m2_210.y) - float(m2_210.Y_BAS)) < 0.01, "la couronne est redescendue")
			"balancoire":
				_ok(float(m2_210.hmax_tour) > 40.0 and float(m2_210.hmax_tour) < 48.0, "la Balançoire monte à %.0f m" % float(m2_210.hmax_tour))
				_ok(float(m2_210.vmax_tour) > 22.0 and float(m2_210.vmax_tour) < 30.0, "la Balançoire atteint %d km/h" % int(float(m2_210.vmax_tour) * 3.6))
				_ok(float(r210[1]) < -0.3, "la Balançoire passe l'horizontale (%.2f)" % float(r210[1]))
				_ok(absf(float(m2_210.theta)) < 0.001, "la Balançoire s'arrête à la verticale")
	# la Chute : trois secondes sans rien peser
	_ok(float(ch210.chute_s) == 0.0, "la Chute est prête pour un autre tour")
	ch210.etat = "marche"
	ch210.t = 0.0
	ch210.fini = false
	ch210._remise()
	var libre210: float = 0.0
	var garde2_210: int = 0
	while not bool(ch210.fini) and garde2_210 < 20000:
		ch210.t += 0.02
		ch210._poser(0.02)
		garde2_210 += 1
		libre210 = maxf(libre210, float(ch210.chute_s))
	ch210.etat = "quai"
	ch210.attente = 40.0
	ch210.fini = false
	ch210._remise()
	ch210._poser(0.0)
	_ok(libre210 > 2.6 and libre210 < 3.3, "la Chute : %.1f s de chute libre" % libre210)
	# en douceur : la vue reste droite, même sur le Marteau
	fo210.changer_sensations()
	_ranger()
	var sp2_210: Array = teleport_v58.spot("foraine_marteau")
	await _poser(sp2_210[0], sp2_210[1])
	ma210.etat = "quai"
	ma210.attente = 30.0
	_ok(bool(fo210.state["doux"]) and fo210.monter_manege(ma210), "on remonte sur le Marteau, en douceur")
	ma210.attente = 0.2
	var penche210: float = 1.0
	var pas3_210: int = 0
	while ma210.a_bord and pas3_210 < 20000:
		ma210.avancer(0.02)
		pas3_210 += 1
		if pas3_210 % 5 == 0:
			ma210._porter(0.1)
			penche210 = minf(penche210, ma210._cam.global_transform.basis.y.y)
		if pas3_210 % 600 == 0:
			await _images(1)
	_ok(penche210 > 0.99, "en douceur, la vue reste droite tout le tour de Marteau (au pire %.3f)" % penche210)
	fo210.changer_sensations()
	# en réalité virtuelle : la tête au siège, le monde retourné avec la nacelle
	if xr_origin != null and xr_camera != null and vr_body != null:
		var garde3_210: Transform3D = xr_origin.global_transform
		ba210.etat = "marche"
		ba210.t = 0.0
		ba210._remise()
		var g4_210: int = 0
		while float(ba210.theta) > -1.9 and g4_210 < 5000:
			ba210.t += 0.02
			ba210._poser(0.02)
			g4_210 += 1
		ba210.a_bord = true
		ba210.doux = false
		ba210._tete0 = xr_camera.position
		ba210._lacet0 = 0.0
		xr_active = true
		ba210._porter(0.0)
		xr_active = false
		ba210.a_bord = false
		var tete210: Vector3 = xr_origin.global_transform * xr_camera.position
		_ok(tete210.distance_to(ba210.siege().origin) < 0.05, "en VR, la tête est au siège de la Balançoire (écart %.3f m)" % tete210.distance_to(ba210.siege().origin))
		_ok(xr_origin.global_transform.basis.y.y < 0.0, "en VR, tout en haut du retour, le monde bascule avec le siège (%.2f)" % xr_origin.global_transform.basis.y.y)
		xr_origin.global_transform = garde3_210
		ba210.etat = "quai"
		ba210.attente = 40.0
		ba210.t = 0.0
		ba210.fini = false
		ba210._remise()
		ba210._poser(0.0)
		_ok(absf(xr_origin.global_transform.basis.y.y - 1.0) < 0.001, "en VR, tout est remis droit après")
	# la sauvegarde
	var sauve210: Dictionary = fo210.serialize()
	fo210.load_data({})
	_ok(int(fo210.state["marteau"]) == 0 and int(ma210.tours) == 0, "une nouvelle partie n'a aucun tour de manège")
	fo210.load_data(JSON.parse_string(JSON.stringify(sauve210)))
	_ok(int(fo210.state["marteau"]) >= 1 and int(fo210.state["chute"]) >= 1 and int(fo210.state["balancoire"]) >= 1 and int(ch210.tours) >= 1, "la sauvegarde garde les tours des trois manèges")
	var etapes210: int = 0
	for q210 in journal_v56.AVENTURES:
		if str((q210 as Dictionary).get("id", "")) == "foraine":
			etapes210 = ((q210 as Dictionary)["etapes"] as Array).size()
	_ok(etapes210 == 6, "la quête « La fête foraine » a six étapes (%d)" % etapes210)
	_ranger()

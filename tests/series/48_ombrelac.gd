## Extension « Le Château d'Ombrelac » : l'île est construite et compte dans le monde (le relief, le
## plateau du château, le lac, la gorge) ; le débarcadère ; la mer de l'île est navigable et rejoint
## celle de l'Île aux Moaïs ; le château est bâti (ses bâtiments, ses formes de collision) ; on y arrive
## par la téléportation et l'on tient debout au débarcadère, sur la route, sur le viaduc, dans la Cour
## d'Honneur, dans le Cloître, sur le Pont Couvert ; les noms des lieux ; les fenêtres s'allument la
## nuit et s'éteignent le jour ; la sauvegarde. La Grande Salle : on y entre, on y tient debout,
## ses murs arrêtent le héros, ses lumières. La Bibliothèque : on y entre, on tient debout en bas et
## sur la galerie, ses lumières. Les salles d'étude : on y entre depuis le Cloître. Les dortoirs : on
## entre dans la tour de l'escalier, on monte l'escalier à vis à pied, on passe d'une salle à l'autre.
## La Tour de l'Astrolabe : on entre dans la salle du bas, la Nacelle monte le héros à l'Observatoire
## et le redescend, la grille du puits arrête le héros quand elle n'est pas là, on tient debout dans
## l'Observatoire et sur la terrasse, dont le parapet arrête le héros. La Tour de l'Horloge : on entre
## dans la Salle des Poids, on monte à pied les huit volées jusqu'à la Chambre des Rouages, les
## rambardes arrêtent le héros, les aiguilles donnent l'heure du jeu, la cloche sonne les heures. La
## Tour des Sortilèges : on entre dans la Salle des Cercles, on monte à pied les marches flottantes
## jusqu'au Cabinet, la rambarde de lumière arrête le héros, on sort sur le balcon. La Grosse Tour :
## on entre dans la Salle du Conseil, on monte à pied l'escalier à vis jusqu'à la Salle des Reliques,
## on entre dans le Bureau du Recteur, la Couronne des Fondateurs tourne.
## v10 : les falaises, le jardin du cloître, la Cour d'Honneur. v11 : les matières du bois, des métaux et
## des étoffes ; les tables garnies, les lampes, les lits faits. v12 : les détails des tours.
const NOM := "48_ombrelac"
const IleO := preload("res://scripts/ext_chateau/ile_ombrelac.gd")


func _wo(x: float, z: float, dy: float = 0.4) -> Vector3:
	return IleO.W(x, z, ombrelac_ext.ile.height_l(x, z) + dy)


## (v11) Le maillage de meubles « nom » (sous le château) : la surface faite de la matière « cle », ou -1
func _surface_de(nom: String, cle: String) -> Array:
	var mi := ombrelac_ext.chateau.find_child(nom, true, false) as MeshInstance3D
	if mi == null or mi.mesh == null:
		return [null, -1]
	var m: Material = ombrelac_ext.Kit.mat(cle)
	for i in range(mi.mesh.get_surface_count()):
		if mi.mesh.surface_get_material(i) == m:
			return [mi.mesh, i]
	return [mi.mesh, -1]


## Le monde, au-dessus d'un point du château (repère château), posé sur ce qu'il y a dessous
func _wc(lieu: Vector3, dy: float = 1.0) -> Vector3:
	return ombrelac_ext.chateau.position + lieu + Vector3(0, dy, 0)


func _serie() -> void:
	_ok(ombrelac_ext != null and ombrelac_ext.ile != null, "l'île d'Ombrelac est construite")
	var roc: Vector3 = IleO.W(IleO.ROC.x, IleO.ROC.y)
	_ok(absf(_height_at(roc.x, roc.z) - IleO.ROC_Y) < 0.6, "le plateau du château compte dans le monde (%.1f m)" % _height_at(roc.x, roc.z))
	var lac: Vector3 = IleO.W(IleO.LAC.x, IleO.LAC.y)
	_ok(_height_at(lac.x, lac.z) < IleO.LAC_Y - 4.0, "le Lac d'Ombre est profond (%.1f m)" % _height_at(lac.x, lac.z))
	var gm: Vector3 = IleO.W(80.0, 150.0)
	_ok(_height_at(gm.x, gm.z) < 5.0, "la gorge du Torrent passe sous le viaduc (%.1f m)" % _height_at(gm.x, gm.z))
	var dock_ok: bool = false
	for d in boat_v29.docks:
		if str(d["name"]) == "Ponton_ombrelac":
			dock_ok = true
	_ok(dock_ok, "le débarcadère d'Ombrelac")
	var GI = load("res://scripts/grande_ile_v59.gd")
	var moai_mer: Vector3 = IleO.CENTER + Vector3(0, 0, 450.0)
	_ok(GI.sea_contains(IleO.CENTER.x, IleO.CENTER.z + 400.0, Vector2(0, 0), 10.0) and GI.sea_contains(moai_mer.x, moai_mer.z, Vector2(0, 0), 10.0),
		"la mer de l'île est navigable et rejoint celle de l'Île aux Moaïs")
	# --- le château
	_ok(ombrelac_ext.chateau != null and ombrelac_ext.chateau.get_child_count() > 20, "le château est bâti (%d pièces)" % (ombrelac_ext.chateau.get_child_count() if ombrelac_ext.chateau != null else 0))
	var cols: int = 0
	for c in ombrelac_ext.chateau.get_children():
		if c is StaticBody3D:
			cols += c.get_child_count()
	_ok(cols > 100, "ses murs arrêtent le héros (%d formes de collision)" % cols)
	# --- on y arrive, on tient debout
	var tp: Array = teleport_v58.spot("ombrelac")
	_ok(not tp.is_empty(), "un point d'arrivée (le débarcadère)")
	place_player_v35(tp[0], tp[1])
	await _att(1.5)
	_ok(await _debout("arrivée au débarcadère d'Ombrelac"), "on tient debout au débarcadère")
	_ok(str(teleport_v58.current_place()) == "ombrelac", "la téléportation reconnaît l'île (%s)" % str(teleport_v58.current_place()))
	_ok(str(journal_v56.place_name(_pos())).contains("Ombrelac"), "le nom du lieu : %s" % str(journal_v56.place_name(_pos())))
	# la route, le haut du Guet, le viaduc
	for r in [[-34.0, 266.0, "la route, au premier lacet"], [62.0, 228.0, "la route, en haut"], [80.0, 205.0, "la Colline du Guet"]]:
		await _poser(_wo(float(r[0]), float(r[1])))
		_ok(await _debout(str(r[2])), "on tient debout : %s" % str(r[2]))
	var vn: Vector3 = ombrelac_ext.chateau.lieux["viaduc_nord"]
	var vs: Vector3 = ombrelac_ext.chateau.lieux["viaduc_sud"]
	var mid: Vector3 = _wc(vn.lerp(vs, 0.5), 1.0)
	await _poser(mid, Vector3(0, 0, -1))
	_ok(await _debout("le milieu du viaduc"), "on tient debout au milieu du viaduc (y %.1f)" % _pos().y)
	_ok(_pos().y > 40.0, "on est bien sur le tablier, pas au fond de la gorge (y %.1f)" % _pos().y)
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_viaduc", "le lieu : le grand viaduc (%s)" % str(ombrelac_ext.zone_at(_pos())))
	# dans le château
	var tc: Array = teleport_v58.spot("ombrelac_cour")
	_ok(not tc.is_empty(), "un point d'arrivée dans la Cour d'Honneur")
	place_player_v35(tc[0], tc[1])
	await _att(1.0)
	_ok(await _debout("la Cour d'Honneur"), "on tient debout dans la Cour d'Honneur")
	_ok(absf(_pos().y - IleO.ROC_Y) < 1.5, "à la hauteur du plateau (y %.1f)" % _pos().y)
	_ok(str(teleport_v58.current_place()) == "ombrelac_cour", "la téléportation reconnaît la cour (%s)" % str(teleport_v58.current_place()))
	# on passe la porte du château (le passage est ouvert) : de la cour vers le viaduc
	var dedans: Vector3 = _wc(Vector3(0, 0, 60.0), 0.3)
	var dehors: Vector3 = _wc(Vector3(0, 0, 86.0), 0.3)
	_ok(_voie_libre(dedans, dehors), "le passage de la Porte du Viaduc est libre")
	await _poser(_wc(ombrelac_ext.chateau.lieux["cloitre"], 1.0))
	_ok(await _debout("le Cloître"), "on tient debout dans le Cloître")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_cloitre", "le lieu : le Cloître (%s)" % str(ombrelac_ext.zone_at(_pos())))
	# la Grande Salle : on y entre par le porche, on se tient sur son dallage
	var gp: Vector3 = _wc(ombrelac_ext.chateau.lieux["grande_salle_porte"], 0.3)
	var gd: Vector3 = _wc(ombrelac_ext.chateau.lieux["grande_salle_dedans"], 0.3)
	_ok(_voie_libre(gp, gd), "on entre dans la Grande Salle par le porche")
	await _poser(_wc(ombrelac_ext.chateau.lieux["grande_salle_dedans"], 1.0))
	_ok(await _debout("la Grande Salle"), "on tient debout dans la Grande Salle")
	_ok(absf(_pos().y - IleO.ROC_Y) < 1.0, "sur son dallage (y %.1f)" % _pos().y)
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_grande_salle", "le lieu : la Grande Salle (%s)" % str(ombrelac_ext.zone_at(_pos())))
	var inter = ombrelac_ext.chateau.get_node_or_null("Ombrelac_interieurs")
	_ok(inter != null and inter.lumieres.size() >= 5 and inter.sonde != null, "la salle est meublée et éclairée (%d lumières)" % (inter.lumieres.size() if inter != null else 0))
	var mur_n: Vector3 = _wc(Vector3(0, 0, 4.0 - 10.5 + 1.4 + 0.5), 0.3)
	_ok(not _voie_libre(gd, mur_n + Vector3(0, 0, -3.0)), "les murs de la salle arrêtent le héros")
	# la Bibliothèque : on y entre par la cour, on monte à la galerie
	var lx: Dictionary = ombrelac_ext.chateau.lieux
	_ok(_voie_libre(_wc(lx["bibliotheque_porte"], 0.3), _wc(lx["bibliotheque"], 0.3)), "on entre dans la Bibliothèque par sa porte")
	await _poser(_wc(lx["bibliotheque"], 1.0))
	_ok(await _debout("la Bibliothèque"), "on tient debout dans la Bibliothèque")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_bibliotheque", "le lieu : la Bibliothèque (%s)" % str(ombrelac_ext.zone_at(_pos())))
	await _poser(_wc(lx["bibliotheque_galerie"], 1.0))
	_ok(await _debout("la galerie de la Bibliothèque"), "on tient debout sur la galerie")
	_ok(_pos().y > IleO.ROC_Y + 5.0, "à l'étage, pas retombé en bas (y %.1f)" % _pos().y)
	var bib = ombrelac_ext.chateau.get_node_or_null("Ombrelac_bibliotheque")
	_ok(bib != null and bib.lumieres.size() >= 4 and bib.sonde != null, "la Bibliothèque est éclairée (%d lumières)" % (bib.lumieres.size() if bib != null else 0))
	# les salles d'étude : on y entre depuis la galerie nord du Cloître
	var salles := [["salle_astres", "la Salle des Astres", "ombrelac_salle_astres"],
		["salle_elixirs", "la Salle des Élixirs", "ombrelac_salle_elixirs"],
		["amphitheatre", "l'Amphithéâtre", "ombrelac_amphitheatre"]]
	for i in range(3):
		var sa: Array = salles[i]
		_ok(_voie_libre(_wc(lx["salles_porte_%d" % i], 0.3), _wc(lx[sa[0]], 0.3)), "on entre dans %s depuis le Cloître" % sa[1])
		await _poser(_wc(lx[sa[0]], 1.0))
		_ok(await _debout(str(sa[1])), "on tient debout dans %s" % sa[1])
		_ok(str(ombrelac_ext.zone_at(_pos())) == sa[2], "le lieu : %s (%s)" % [sa[1], str(ombrelac_ext.zone_at(_pos()))])
	var sl = ombrelac_ext.chateau.get_node_or_null("Ombrelac_salles")
	_ok(sl != null and sl.lumieres.size() >= 6 and sl.sondes.size() == 3, "les salles sont éclairées (%d lumières)" % (sl.lumieres.size() if sl != null else 0))
	# les dortoirs : la tour de l'escalier (sa porte sur le cloître), l'étage, la Salle Commune
	_ok(_voie_libre(_wc(lx["tour_dortoirs_porte"], 0.4), _wc(lx["tour_dortoirs_bas"], 0.4)), "on entre dans la tour de l'escalier par sa porte")
	await _poser(_wc(lx["tour_dortoirs_bas"], 1.0))
	_ok(await _debout("le bas de la tour de l'escalier"), "on tient debout au pied de l'escalier")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_tour_dortoirs", "le lieu : la Tour des Dortoirs (%s)" % str(ombrelac_ext.zone_at(_pos())))
	# on monte l'escalier à vis à pied : on marche en tournant autour du noyau
	var tcw: Vector3 = _wc(lx["tour_dortoirs_centre"], 0.0)
	for i in range(60):
		var rv: Vector3 = _pos() - tcw
		rv.y = 0.0
		var rl: float = rv.length()
		rv = rv / maxf(rl, 0.01)
		var dirm: Vector3 = (rv.cross(Vector3.UP) + rv * clampf(2.4 - rl, -0.6, 0.6)).normalized()
		place_player_v35(_pos() + Vector3.UP * 0.05, dirm)
		await _att(0.1)
		_touche(KEY_Z, true)
		_touche(KEY_W, true)
		await _att(0.3)
		_touche(KEY_Z, false)
		_touche(KEY_W, false)
		if _pos().y > IleO.ROC_Y + 6.0:
			break
	await _att(0.4)
	_ok(_pos().y > IleO.ROC_Y + 5.9, "on monte l'escalier à vis à pied jusqu'à l'étage (y %.2f, l'étage à %.2f)" % [_pos().y, IleO.ROC_Y + 6.25])
	await _poser(_wc(lx["tour_dortoirs_haut"], 1.0))
	_ok(await _debout("le palier de l'étage"), "on tient debout sur le palier de l'étage")
	_ok(_pos().y > IleO.ROC_Y + 5.5, "en haut de l'escalier (y %.1f)" % _pos().y)
	_ok(_voie_libre(_wc(lx["tour_dortoirs_haut"], 0.4), _wc(lx["dortoir_crepuscule"], 0.4)), "du palier, on passe dans le Dortoir du Crépuscule")
	var dortoirs := [["dortoir_crepuscule", "le Dortoir du Crépuscule", "ombrelac_dortoir_crepuscule"],
		["salle_commune", "la Salle Commune", "ombrelac_salle_commune"],
		["dortoir_aube", "le Dortoir de l'Aube", "ombrelac_dortoir_aube"]]
	for dd in dortoirs:
		await _poser(_wc(lx[dd[0]], 1.0))
		_ok(await _debout(str(dd[1])), "on tient debout dans %s" % dd[1])
		_ok(_pos().y > IleO.ROC_Y + 5.5, "à l'étage (y %.1f)" % _pos().y)
		_ok(str(ombrelac_ext.zone_at(_pos())) == dd[2], "le lieu : %s (%s)" % [dd[1], str(ombrelac_ext.zone_at(_pos()))])
	_ok(_voie_libre(_wc(lx["salle_commune"], 0.4), _wc(lx["dortoirs_passage_o"], 0.4)), "de la Salle Commune, on passe dans le Dortoir de l'Aube")
	_ok(_voie_libre(_wc(lx["salle_commune_est"], 0.4), _wc(lx["dortoirs_passage_e"], 0.4)), "de la Salle Commune, on passe dans le Dortoir du Crépuscule")
	var dt = ombrelac_ext.chateau.get_node_or_null("Ombrelac_dortoirs")
	_ok(dt != null and dt.lumieres.size() >= 6 and dt.feu != null, "les dortoirs sont éclairés, le feu brûle (%d lumières)" % (dt.lumieres.size() if dt != null else 0))
	# la Tour de l'Astrolabe : la salle du bas, la Nacelle, l'Observatoire, la terrasse
	var ast = ombrelac_ext.chateau.get_node_or_null("Ombrelac_astrolabe_dedans")
	_ok(ast != null and ast.main != null, "la Tour de l'Astrolabe a son dedans, la Nacelle connaît le héros")
	_ok(_voie_libre(_wc(lx["astrolabe_porte"], 0.4), _wc(lx["astrolabe_salle"], 0.4)), "on entre dans la Salle de l'Astrolabe par sa porte")
	await _poser(_wc(lx["astrolabe_salle"], 1.0))
	_ok(await _debout("la Salle de l'Astrolabe"), "on tient debout dans la Salle de l'Astrolabe")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_salle_astrolabe", "le lieu : la Salle de l'Astrolabe (%s)" % str(ombrelac_ext.zone_at(_pos())))
	if ast != null:
		ast.t_nacelle = 1.0
		ast.en_route = false
		await _att(1.5)
		_ok(not _voie_libre(_wc(lx["nacelle_attente_bas"], 0.4), _wc(lx["nacelle_bas"], 0.4)), "la Nacelle en haut, la grille du bas est fermée")
		ast.t_nacelle = 0.0
		await _att(2.5)
		_ok(_voie_libre(_wc(lx["nacelle_attente_bas"], 0.4), _wc(lx["nacelle_bas"], 0.4)), "la Nacelle en bas, sa grille s'ouvre")
		var v0: int = ast.voyages
		await _poser(_wc(lx["nacelle_bas"], 1.0))
		_ok(_pos().y < IleO.ROC_Y + 2.0 and ast.dans_nacelle(ast.to_local(_pos())), "on entre dans la Nacelle (y %.1f)" % _pos().y)
		await _att(ast.NACELLE_ATTENTE + ast.NACELLE_DUREE + 3.0)
		_ok(ast.voyages == v0 + 1 and ast.en_haut(), "la Nacelle part seule et arrive en haut (%d voyage, t %.2f)" % [ast.voyages - v0, ast.t_nacelle])
		_ok(_pos().y > IleO.ROC_Y + 53.0, "elle a monté le héros jusqu'à l'Observatoire (y %.1f)" % _pos().y)
		_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_observatoire", "le lieu : l'Observatoire (%s)" % str(ombrelac_ext.zone_at(_pos())))
	await _poser(_wc(lx["observatoire"], 1.0))
	_ok(await _debout("l'Observatoire"), "on tient debout dans l'Observatoire")
	_ok(_pos().y > IleO.ROC_Y + 53.0, "en haut de la tour (y %.1f)" % _pos().y)
	_ok(_voie_libre(_wc(lx["observatoire"], 0.4), _wc(lx["terrasse_astrolabe"], 0.4)), "de l'Observatoire, on sort sur la terrasse")
	await _poser(_wc(lx["terrasse_astrolabe"], 1.0))
	_ok(await _debout("la terrasse"), "on tient debout sur la terrasse de l'Astrolabe")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_terrasse_astrolabe", "le lieu : la Terrasse de l'Astrolabe (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["terrasse_astrolabe"], 0.4), _wc(lx["terrasse_astrolabe_dehors"], 0.4)), "le parapet de la terrasse arrête le héros")
	if ast != null:
		await _poser(_wc(lx["nacelle_attente_haut"], 1.0))
		ast.t_nacelle = 0.0
		ast.en_route = false
		await _att(1.0)
		_ok(ast.en_route or ast.en_haut(), "on l'attend devant sa grille : la Nacelle vient")
		await _att(ast.NACELLE_DUREE + 1.0)
		_ok(ast.en_haut(), "la Nacelle est arrivée en haut (t %.2f)" % ast.t_nacelle)
		await _poser(_wc(lx["nacelle_haut"], 1.0))
		await _att(ast.NACELLE_ATTENTE + ast.NACELLE_DUREE + 3.0)
		_ok(ast.en_bas() and _pos().y < IleO.ROC_Y + 3.0, "elle redescend le héros à la Salle de l'Astrolabe (y %.1f)" % _pos().y)
		_ok(await _debout("la Nacelle en bas"), "on tient debout dans la Nacelle, en bas")
		_ok(ast.lumieres.size() >= 4 and ast.anneaux.size() >= 3, "la tour est éclairée, les anneaux de l'astrolabe tournent (%d lumières)" % ast.lumieres.size())
	# la Tour de l'Horloge : la Salle des Poids, l'escalier à pied, la Chambre des Rouages
	var hz = ombrelac_ext.chateau.get_node_or_null("Ombrelac_horloge_dedans")
	_ok(hz != null and hz.main != null, "la Tour de l'Horloge a son dedans, elle connaît l'heure du jeu")
	_ok(_voie_libre(_wc(lx["horloge_porte"], 0.4), _wc(lx["horloge_salle"], 0.4)), "on entre dans la Tour de l'Horloge par sa porte")
	await _poser(_wc(lx["horloge_salle"], 1.0))
	_ok(await _debout("la Salle des Poids"), "on tient debout dans la Salle des Poids")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_tour_horloge", "le lieu : la Tour de l'Horloge (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["horloge_volee_mi"], 0.4), _wc(lx["horloge_vide_mi"], 0.4)), "la rampe de l'escalier arrête le héros au bord du vide")
	# on monte à pied : chaque volée tout droit, on tourne au palier
	if hz != null:
		await _poser(_wc(lx["horloge_escalier_bas"], 1.0))
		var hcw: Vector3 = _wc(lx["horloge_centre"], 0.0)
		var hi_t: float = 6.0 - 1.2
		var volees_ok: int = 0
		for i in range(hz.VOLEES):
			var v: Array = hz.volee(i, hi_t)
			var dv: Vector3 = v[1]
			var fin: Vector3 = hcw + (v[0] as Vector3) + dv * (2.0 * (hi_t - hz.LARGEUR) + hz.LARGEUR * 0.5)
			for n in range(40):
				var vers: Vector3 = fin - _pos()
				vers.y = 0.0
				if vers.dot(dv) < 0.15:
					break
				# (on garde le milieu de la volée)
				var lat: Vector3 = vers - dv * vers.dot(dv)
				place_player_v35(_pos() + Vector3.UP * 0.03, (dv + lat * 0.8).normalized())
				await _att(0.05)
				_touche(KEY_Z, true)
				_touche(KEY_W, true)
				await _att(0.25)
				_touche(KEY_Z, false)
				_touche(KEY_W, false)
			if _pos().y > IleO.ROC_Y + (i + 1) * hz.MONTEE - 0.6:
				volees_ok += 1
		await _att(0.5)
		_ok(volees_ok == hz.VOLEES and _pos().y > IleO.ROC_Y + 27.5, "on monte à pied les huit volées jusqu'à la Chambre des Rouages (%d volées, y %.1f)" % [volees_ok, _pos().y - IleO.ROC_Y])
	await _poser(_wc(lx["horloge_rouages"], 1.0))
	_ok(await _debout("la Chambre des Rouages"), "on tient debout dans la Chambre des Rouages")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_chambre_rouages", "le lieu : la Chambre des Rouages (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["horloge_bord_vide"], 0.4), _wc(lx["horloge_dans_vide"], 0.4)), "la rambarde de la trémie arrête le héros")
	_ok(not _voie_libre(_wc(lx["horloge_cadran_dedans"], 5.0), _wc(lx["horloge_cadran_dehors"], 5.0)), "le verre du cadran arrête le héros")
	if hz != null:
		temps_v56.set_hour(15.5)
		await _att(0.3)
		_ok(absf(hz.angle_heure - TAU * 3.5 / 12.0) < 0.02 and absf(hz.angle_minute - PI) < 0.05, "les aiguilles donnent l'heure du jeu (15 h 30 : %.2f, %.2f)" % [hz.angle_heure, hz.angle_minute])
		var c0: int = hz.coups_sonnes
		hz.sonner(2)
		await _att(hz.COUP_INTERVALLE * 2.0 + 0.8)
		_ok(hz.coups_sonnes == c0 + 2 and hz.son != null and hz.son.stream != null, "la cloche sonne les coups (%d)" % (hz.coups_sonnes - c0))
		var b0: float = hz.balancier.rotation.z
		await _att(1.0)
		_ok(absf(hz.balancier.rotation.z - b0) > 0.001, "le balancier bat")
		_ok(hz.lumieres.size() >= 6, "la tour est éclairée (%d lumières)" % hz.lumieres.size())
	# la Tour des Sortilèges : la Salle des Cercles, les marches flottantes, le Cabinet, le balcon
	var so = ombrelac_ext.chateau.get_node_or_null("Ombrelac_sortileges_dedans")
	_ok(so != null, "la Tour des Sortilèges a son dedans")
	_ok(_voie_libre(_wc(lx["sortileges_porte"], 0.4), _wc(lx["sortileges_salle"], 0.4)), "on entre dans la Tour des Sortilèges par sa porte")
	await _poser(_wc(lx["sortileges_salle"], 1.0))
	_ok(await _debout("la Salle des Cercles"), "on tient debout dans la Salle des Cercles")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_tour_sortileges", "le lieu : la Tour des Sortilèges (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["sortileges_escalier_mi"], 0.4), _wc(lx["sortileges_vide_mi"], 0.4)), "la rambarde de lumière arrête le héros au bord du vide")
	# on monte à pied : en tournant le long du mur
	await _poser(_wc(lx["sortileges_escalier_bas"], 1.0))
	var scw: Vector3 = _wc(lx["sortileges_centre"], 0.0)
	for i in range(220):
		var rv: Vector3 = _pos() - scw
		rv.y = 0.0
		var rl: float = rv.length()
		rv = rv / maxf(rl, 0.01)
		var dirm: Vector3 = (rv.cross(Vector3.UP) + rv * clampf(4.6 - rl, -0.6, 0.6)).normalized()
		place_player_v35(_pos() + Vector3.UP * 0.03, dirm)
		await _att(0.05)
		_touche(KEY_Z, true)
		_touche(KEY_W, true)
		await _att(0.3)
		_touche(KEY_Z, false)
		_touche(KEY_W, false)
		if _pos().y > IleO.ROC_Y + 23.8:
			break
	await _att(0.4)
	_ok(_pos().y > IleO.ROC_Y + 23.5, "on monte à pied les marches flottantes jusqu'au Cabinet (y %.1f)" % (_pos().y - IleO.ROC_Y))
	await _poser(_wc(lx["sortileges_cabinet"], 1.0))
	_ok(await _debout("le Cabinet des Sortilèges"), "on tient debout dans le Cabinet des Sortilèges")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_cabinet_sortileges", "le lieu : le Cabinet des Sortilèges (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["sortileges_bord_tremie"], 0.4), _wc(lx["sortileges_dans_tremie"], 0.4)), "la rambarde de la trémie arrête le héros")
	_ok(_voie_libre(_wc(lx["sortileges_avant_balcon"], 0.4), _wc(lx["sortileges_balcon"], 0.4)), "du Cabinet, on sort sur le balcon")
	await _poser(_wc(lx["sortileges_balcon"], 1.0))
	_ok(await _debout("le balcon"), "on tient debout sur le balcon, au-dessus du lac")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_balcon_sortileges", "le lieu : le Balcon des Sortilèges (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(not _voie_libre(_wc(lx["sortileges_balcon"], 0.4), _wc(lx["sortileges_balcon_dehors"], 0.4)), "la balustrade du balcon arrête le héros")
	if so != null:
		var f0: Vector3 = (so.follets[0][0] as Node3D).position
		await _att(0.5)
		_ok((so.follets[0][0] as Node3D).position.distance_to(f0) > 0.01 and so.livres.size() == 6, "les feux follets montent, les livres volent")
		_ok(so.lumieres.size() >= 6, "la tour est éclairée (%d lumières)" % so.lumieres.size())
	# la Grosse Tour : la Salle du Conseil, l'escalier à vis, le Bureau du Recteur, la Salle des Reliques
	var gt = ombrelac_ext.chateau.get_node_or_null("Ombrelac_grosse_tour_dedans")
	_ok(gt != null, "la Grosse Tour a son dedans")
	_ok(_voie_libre(_wc(lx["grosse_porte"], 0.4), _wc(lx["grosse_conseil"], 0.4)), "on entre dans la Grosse Tour par sa porte")
	await _poser(_wc(lx["grosse_conseil"], 1.0))
	_ok(await _debout("la Salle du Conseil"), "on tient debout dans la Salle du Conseil")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_salle_conseil", "le lieu : la Salle du Conseil (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(_voie_libre(_wc(lx["grosse_vis_porte"], 0.4), _wc(lx["grosse_vis_bas"], 0.4)), "on entre dans la cage de l'escalier par sa porte")
	_ok(not _voie_libre(_wc(lx["grosse_vis_mi"], 0.6), _wc(lx["grosse_vis_mi_dehors"], 0.6)), "le mur de la cage arrête le héros")
	# on monte à pied : en tournant autour du noyau
	await _poser(_wc(lx["grosse_vis_bas"], 1.0))
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_vis_grosse_tour", "le lieu : l'escalier de la Grosse Tour (%s)" % str(ombrelac_ext.zone_at(_pos())))
	var gvc: Vector3 = _wc(lx["grosse_vis_c"], 0.0)
	var y_e1: float = -1.0
	for i in range(300):
		var rv: Vector3 = _pos() - gvc
		rv.y = 0.0
		var rl: float = rv.length()
		rv = rv / maxf(rl, 0.01)
		var dirm: Vector3 = (rv.cross(Vector3.UP) + rv * clampf(1.3 - rl, -0.6, 0.6)).normalized()
		place_player_v35(_pos() + Vector3.UP * 0.03, dirm)
		await _att(0.05)
		_touche(KEY_Z, true)
		_touche(KEY_W, true)
		await _att(0.3)
		_touche(KEY_Z, false)
		_touche(KEY_W, false)
		if y_e1 < 0.0 and _pos().y > IleO.ROC_Y + 11.8:
			y_e1 = _pos().y
		if _pos().y > IleO.ROC_Y + 23.8:
			break
	await _att(0.4)
	_ok(y_e1 > 0.0, "on passe le palier du Bureau du Recteur (12 m)")
	_ok(_pos().y > IleO.ROC_Y + 23.5, "on monte à pied l'escalier à vis jusqu'à la Salle des Reliques (y %.1f)" % (_pos().y - IleO.ROC_Y))
	_ok(not _voie_libre(_wc(lx["grosse_vis_haut"], 0.4), _wc(lx["grosse_vis_vide"], 0.4)), "la rambarde du dernier palier arrête le héros")
	_ok(_voie_libre(_wc(lx["grosse_vis_e1"], 0.4), _wc(lx["grosse_bureau_porte"], 0.4)), "du palier, on entre dans le Bureau du Recteur")
	await _poser(_wc(lx["grosse_bureau"], 1.0))
	_ok(await _debout("le Bureau du Recteur"), "on tient debout dans le Bureau du Recteur")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_bureau_recteur", "le lieu : le Bureau du Recteur (%s)" % str(ombrelac_ext.zone_at(_pos())))
	_ok(_voie_libre(_wc(lx["grosse_vis_e2"], 0.4), _wc(lx["grosse_reliques_porte"], 0.4)), "du dernier palier, on entre dans la Salle des Reliques")
	await _poser(_wc(lx["grosse_reliques"], 1.0))
	_ok(await _debout("la Salle des Reliques"), "on tient debout dans la Salle des Reliques")
	_ok(str(ombrelac_ext.zone_at(_pos())) == "ombrelac_salle_reliques", "le lieu : la Salle des Reliques (%s)" % str(ombrelac_ext.zone_at(_pos())))
	if gt != null:
		var r0: float = (gt.couronne as Node3D).rotation.y
		await _att(0.5)
		_ok(absf((gt.couronne as Node3D).rotation.y - r0) > 0.01, "la Couronne des Fondateurs tourne")
		_ok(gt.lumieres.size() >= 8, "la tour est éclairée (%d lumières)" % gt.lumieres.size())
	await _poser(_wc(ombrelac_ext.chateau.lieux["pont_milieu"], 1.0))
	_ok(await _debout("le Pont Couvert"), "on tient debout au milieu du Pont Couvert, au-dessus du lac (y %.1f)" % _pos().y)
	_ok(_pos().y > IleO.ROC_Y - 1.5, "sur le tablier, pas dans le lac (y %.1f)" % _pos().y)
	# --- v10 : la passe graphique (les falaises sculptées, le jardin du cloître, la Cour d'Honneur)
	var fal: Node = ombrelac_ext.falaises
	_ok(fal != null and fal.get_node_or_null("Ombrelac_falaises_roc") != null and fal.get_node_or_null("Ombrelac_falaises_aiguille") != null,
		"les falaises du Roc et de l'Aiguille sont sculptées")
	var esp := get_world_3d().direct_space_state
	var roc_c: Vector3 = IleO.W(IleO.ROC.x, IleO.ROC.y, 30.0)
	var depuis: Vector3 = IleO.W(IleO.ROC.x - 170.0, IleO.ROC.y, 30.0)
	var qf := PhysicsRayQueryParameters3D.create(depuis, roc_c, 1)
	var hf: Dictionary = esp.intersect_ray(qf)
	_ok(not hf.is_empty() and str((hf["collider"] as Node).name).begins_with("Ombrelac_falaises"),
		"la roche de la falaise arrête le héros, devant le sol (%s)" % (str((hf["collider"] as Node).name) if not hf.is_empty() else "rien"))
	if not hf.is_empty():
		var dr: float = Vector2(hf["position"].x, hf["position"].z).distance_to(Vector2(roc_c.x, roc_c.z))
		var sol_r: float = 0.0
		for k2 in range(400):
			var rr: float = IleO.ROC_R0 + k2 * 0.25
			if ombrelac_ext.ile.height_l(IleO.ROC.x - rr, IleO.ROC.y) < 30.0:
				sol_r = rr
				break
		_ok(dr > sol_r - 0.2 and dr < sol_r + 4.0, "la paroi suit le relief (%.1f m du centre, le sol à %.1f m)" % [dr, sol_r])
	var fl: Node = ombrelac_ext.flore
	_ok(fl != null and int(fl.placed.get("o_cloitre_gazon", 0)) > 500 and int(fl.placed.get("o_cloitre_arbre", 0)) == 4,
		"le jardin du cloître est planté (%d touffes de gazon)" % (int(fl.placed.get("o_cloitre_gazon", 0)) if fl != null else 0))
	_ok(ombrelac_ext.chateau.get_node_or_null("Ombrelac_cour") != null, "la Cour d'Honneur a ses réverbères et ses bancs")
	_ok(_voie_libre(_wc(lx["porte"], 0.0), _wc(lx["grande_salle_porte"], 0.0)), "l'allée de la Cour d'Honneur reste libre")
	_ok(_voie_libre(_wc(lx["cour"], 0.0), _wc(lx["sortileges"], 0.0)), "on va de la cour à la Tour des Sortilèges")
	await _poser(_wc(lx["cloitre"], 1.0))
	_ok(await _debout("le jardin du cloître"), "on tient debout dans le jardin du cloître")
	# --- v11 : les détails des intérieurs (le bois, les métaux, les étoffes ; la table garnie, les lits)
	var Kt = ombrelac_ext.Kit
	var sh_ok: bool = true
	for paire in [["bois", "ombrelac_bois"], ["chene", "ombrelac_bois"], ["parquet", "ombrelac_bois"], ["fer", "ombrelac_metal"],
			["or", "ombrelac_metal"], ["bronze", "ombrelac_metal"], ["velours_bleu", "ombrelac_etoffe"], ["drap", "ombrelac_etoffe"]]:
		var mt: Material = Kt.mat(str(paire[0]))
		if not (mt is ShaderMaterial and str((mt as ShaderMaterial).shader.resource_path).ends_with(str(paire[1]) + ".gdshader")):
			sh_ok = false
	_ok(sh_ok, "le bois, les métaux et les étoffes ont leurs matières dessinées")
	var sb: Array = _surface_de("Ombrelac_salle_meubles", "chene")
	var axe_ok: bool = false
	if int(sb[1]) >= 0:
		var cols11 = (sb[0] as ArrayMesh).surface_get_arrays(int(sb[1]))[Mesh.ARRAY_COLOR]
		axe_ok = cols11 != null and cols11.size() > 0 and (cols11[0] as Color).a > 0.5
	_ok(axe_ok, "le bois des meubles connaît le sens de son fil")
	_ok(int(_surface_de("Ombrelac_salle_meubles", "pomme_rouge")[1]) >= 0 and int(_surface_de("Ombrelac_salle_meubles", "pain")[1]) >= 0,
		"les tables de la Grande Salle sont garnies (les fruits, le pain)")
	_ok(int(_surface_de("Ombrelac_biblio_meubles", "lampe_dedans")[1]) >= 0, "les lampes de la Bibliothèque ont leur verre opalin")
	_ok(int(_surface_de("Ombrelac_dortoirs_meubles", "cuivre_neuf")[1]) >= 0 and int(_surface_de("Ombrelac_dortoirs_meubles", "drap")[1]) >= 0,
		"les dortoirs ont leurs lits faits et la bouilloire sur le poêle")
	# --- v12 : les détails des tours (la table des cartes de l'Observatoire, le registre du gardien de l'horloge)
	_ok(int(_surface_de("Ombrelac_astrolabe_meubles", "drap")[1]) >= 0, "l'Observatoire a ses cartes roulées et sa plume")
	_ok(int(_surface_de("Ombrelac_horloge_meubles", "drap")[1]) >= 0 and int(_surface_de("Ombrelac_horloge_meubles", "velours_bleu")[1]) >= 0,
		"la Tour de l'Horloge a son registre ouvert et son banc à coussin")
	# --- v13 : la passe graphique de l'île (la maçonnerie, l'eau, la brume, les rayons, la végétation)
	var mac_ok: bool = true
	for cle13 in ["pierre", "pierre_int", "pierre_claire"]:
		var mt13: Material = Kt.mat(cle13)
		if not (mt13 is ShaderMaterial and str((mt13 as ShaderMaterial).shader.resource_path).ends_with("ombrelac_maconnerie.gdshader")):
			mac_ok = false
	_ok(mac_ok, "les murs sont une vraie maçonnerie (les assises, les pierres une à une, les joints)")
	var eau_ok: bool = true
	for nom13 in ["Lac_ombrelac", "Torrent_ombrelac"]:
		var mi13 := ombrelac_ext.find_child(nom13, true, false) as MeshInstance3D
		if mi13 == null or not (mi13.material_override is ShaderMaterial) or not str((mi13.material_override as ShaderMaterial).shader.resource_path).ends_with("ombrelac_eau.gdshader"):
			eau_ok = false
	_ok(eau_ok, "le lac et le torrent ont leur eau (les rides, la transparence au bord, l'écume)")
	_ok(ombrelac_ext.find_child("Brume_lac", true, false) != null, "la brume flotte sur le lac")
	_ok(inter != null and inter.find_child("Ombrelac_salle_rayons", true, false) != null and inter.rayons != null, "les rayons du soleil tombent des baies de la Grande Salle")
	_ok(fl != null and int(fl.placed.get("o_nenuphar", 0)) > 40 and int(fl.placed.get("o_herbe_haute", 0)) > 1000
		and int(fl.placed.get("o_bosquet_0", 0)) + int(fl.placed.get("o_bosquet_1", 0)) > 50,
		"l'île a ses bosquets, son herbe haute et ses nénuphars (%d)" % (int(fl.placed.get("o_nenuphar", 0)) if fl != null else 0))
	# --- les fenêtres : allumées la nuit, éteintes le jour
	temps_v56.set_hour(22.0)
	await _att(1.5)
	var vit: ShaderMaterial = ombrelac_ext.Kit.mat("vitre")
	_ok(float(vit.get_shader_parameter("nuit")) > 0.9, "la nuit, les fenêtres s'allument")
	_ok(inter != null and inter.nuit > 0.9, "la nuit, les bougies de la Grande Salle éclairent plus fort")
	_ok(inter != null and inter.rayons != null and float(inter.rayons.get_shader_parameter("force")) < 0.01, "la nuit, pas de rayons de soleil")
	temps_v56.set_hour(12.0)
	await _att(1.5)
	_ok(float(vit.get_shader_parameter("nuit")) < 0.1, "le jour, elles s'éteignent")
	# --- la sauvegarde
	_ok(bool(ombrelac_ext.state.get("visite", false)), "la visite est notée")
	var d: Dictionary = ombrelac_ext.serialize()
	ombrelac_ext.load_data({})
	_ok(not bool(ombrelac_ext.state.get("visite", false)), "une nouvelle partie oublie la visite")
	ombrelac_ext.load_data(d)
	_ok(bool(ombrelac_ext.state.get("visite", false)), "une partie chargée la retrouve")

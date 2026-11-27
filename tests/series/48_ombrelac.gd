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
	# (v18) pas de rebord entre les dernières marches et le palier de l'étage (le héros s'y coinçait)
	var rebord: float = _rebord_palier_v18()
	_ok(rebord < 0.2, "de la dernière marche au palier, pas de rebord (au plus %.2f m d'une mesure à l'autre)" % rebord)
	# (v18.1) chaque pas se compte en images de physique, pas en secondes : quand la série tourne en
	# groupe, la machine est chargée, et un pas « de 0,3 s » n'avançait presque plus (le héros n'arrivait
	# pas en haut à temps). Jusqu'à 160 pas ; un pas qui ne monte pas recommence un peu plus au large.
	var pas_rates: int = 0
	var y_max: float = _pos().y
	for i in range(160):
		var rv: Vector3 = _pos() - tcw
		rv.y = 0.0
		var rl: float = rv.length()
		rv = rv / maxf(rl, 0.01)
		var r_vise: float = 2.4 + 0.3 * float(pas_rates % 3)
		var dirm: Vector3 = (rv.cross(Vector3.UP) + rv * clampf(r_vise - rl, -0.6, 0.6)).normalized()
		place_player_v35(_pos() + Vector3.UP * 0.05, dirm)
		await _physique_v181(6)
		_touche(KEY_Z, true)
		_touche(KEY_W, true)
		await _physique_v181(18)
		_touche(KEY_Z, false)
		_touche(KEY_W, false)
		if _pos().y > y_max + 0.02:
			y_max = _pos().y
			pas_rates = 0
		else:
			pas_rates += 1
		if _pos().y > IleO.ROC_Y + 6.0:
			break
	await _physique_v181(24)
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
	# --- v14 : les habitants de l'Académie (vie_ombrelac.gd, habitants_ombrelac.gd, chemins_ombrelac.gd)
	await _habitants_v14()
	# --- v15 : les objets du château (objets_ombrelac.gd, textes_ombrelac.gd)
	await _objets_v15()
	# --- v16 : les quêtes des habitants, la Maison de Minuit (quetes_ombrelac.gd, minuit_ombrelac.gd)
	await _quetes_v16()
	# --- v17 : les cours de l'Académie (cours_ombrelac.gd)
	await _cours_v17()
	# --- v18 : les créatures du château (creatures_ombrelac.gd)
	await _creatures_v18()


## (v14) Les dix-huit habitants : leurs lieux, leurs chemins, leurs corps, leur journée, la parole
func _habitants_v14() -> void:
	var vie: Node = ombrelac_ext.vie
	_ok(vie != null and vie._built, "la vie au château est en place")
	if vie == null:
		return
	for k in range(20):
		if vie.habitants.size() >= 18:
			break
		await _att(0.5)
	_ok(vie.habitants.size() == 18, "les dix-huit habitants de l'Académie sont là (%d)" % vie.habitants.size())
	var dans_liste: int = 0
	for h in vie.habitants:
		if npcs_v31.has(h):
			dans_liste += 1
	_ok(dans_liste == 18, "ils comptent parmi les habitants du jeu (la sauvegarde, la parole)")
	_ok(vie.spots.size() > 150, "les lieux des habitants (%d places)" % vie.spots.size())
	var g_ok: bool = true
	for g in ["gs_aube", "gs_crepuscule", "astres", "elixirs", "amphi", "cercle", "biblio", "commune", "fontaine", "cour_jeu", "cour", "conseil", "service", "jardin", "serres"]:
		if (vie.groupes.get(g, []) as Array).size() < 4 and not (g in ["conseil", "serres"] and (vie.groupes.get(g, []) as Array).size() >= 3):
			g_ok = _note(false, "le groupe de places « %s » : %d" % [g, (vie.groupes.get(g, []) as Array).size()])
	_ok(g_ok, "chaque groupe de places a assez de places (les bancs, les pupitres, la cour…)")
	var lieux_ok: bool = true
	var corps_ok: bool = true
	for h2 in vie.habitants:
		for e in h2.agenda:
			var cibles: Array = e[2] if e[2] is Array else [e[2]]
			for c in cibles:
				if str(c) != "maison" and not vie.spots.has(str(c)):
					lieux_ok = _note(false, "%s : le lieu « %s » n'existe pas" % [h2.display_name, str(c)])
		if not vie.points.has(h2.home):
			lieux_ok = _note(false, "%s : sa maison « %s » n'est pas sur le plan" % [h2.display_name, h2.home])
		if h2.v64.is_empty():
			corps_ok = _note(false, "%s : pas de corps à lui" % h2.display_name)
	_ok(lieux_ok, "chaque lieu de chaque emploi du temps existe, chaque maison est sur le plan")
	_ok(corps_ok, "chacun a son propre corps (tenue de son dortoir, robe de maître…)")
	var liens_ok: bool = true
	for a in vie.graph:
		for b in vie.graph[a]:
			if not vie.points.has(str(a)) or not vie.points.has(str(b)):
				liens_ok = false
	for s in vie.spots:
		if not vie.points.has(str(vie.spots[s]["node"])):
			liens_ok = false
	_ok(liens_ok, "le plan des chemins tient (chaque lien, chaque lieu a son point)")
	# les chemins : pas de mur au travers, le sol continue (à hauteur de genou et de poitrine)
	var space := get_world_3d().direct_space_state
	var murs: int = 0
	var n_liens: int = 0
	# (les habitants ne comptent pas : ils se tiennent sur leurs lieux)
	var sans_pnj: Array[RID] = []
	if not vie.habitants.is_empty():
		sans_pnj.append_array(vie.habitants[0]._npc_bodies)
	if pc_body != null:
		sans_pnj.append(pc_body.get_rid())
	for a2 in vie.graph:
		for b2 in vie.graph[a2]:
			# (du siège au point d'approche : on se lève, ce n'est pas un chemin)
			if str(a2) < str(b2) and not str(a2).ends_with("~") and not str(b2).ends_with("~"):
				n_liens += 1
				var pa: Vector3 = vie.points[a2]
				var pb: Vector3 = vie.points[b2]
				for hh in [0.5, 1.3]:
					if not space.intersect_ray(PhysicsRayQueryParameters3D.create(pa + Vector3.UP * hh, pb + Vector3.UP * hh, 1, sans_pnj)).is_empty():
						murs += 1
						print("  mur entre %s et %s" % [a2, b2])
						break
	_ok(murs == 0, "aucun chemin ne traverse un mur ou un meuble (%d liens)" % n_liens)
	var aube: Array = []
	for id in ["lison_om", "barnabe_om", "nour_om", "tobie_om"]:
		if vie.by_id.has(id):
			aube.append(vie.by_id[id])
	var tous_eleves: Array = aube.duplicate()
	for id2 in ["ombeline_om", "anatole_om", "sidonie_om", "malo_om"]:
		if vie.by_id.has(id2):
			tous_eleves.append(vie.by_id[id2])
	# loin du château, la journée passe d'un coup : chacun est à sa place
	var loin: Array = ombrelac_ext.village_point("ombrelac")
	await _poser(loin[0] + Vector3(0, 1.0, 0))
	var d_min: float = INF
	for h3 in vie.habitants:
		d_min = minf(d_min, h3.global_position.distance_to(_pos()))
	temps_v56.set_hour(8.5)
	await _att(3.0)
	var en_cours: int = 0
	for e2 in aube:
		if str(e2.target_spot).begins_with("astres_") and e2.pose == "assis" and not e2.hidden_home:
			en_cours += 1
	_ok(en_cours == aube.size(), "à 8 h 30, l'Aube est au cours des astres, assise sur les bancs (%d/%d)" % [en_cours, aube.size()])
	var maitre = vie.by_id.get("fauconnier_om")
	_ok(maitre != null and maitre.target_spot == "astres_maitre" and maitre.global_position.distance_to(vie.spots["astres_maitre"]["pos"]) < 1.0,
		"Maître Fauconnier fait son cours, debout devant les élèves")
	temps_v56.set_hour(12.5)
	await _att(3.0)
	var a_table: int = 0
	var bien_assis: int = 0
	for e3 in tous_eleves:
		if str(e3.target_spot).begins_with("gs_") and e3.pose == "assis":
			a_table += 1
			var bc: Dictionary = vie.Bancs183.sous(e3.global_position + Vector3.UP * 0.2)
			var sp: Dictionary = vie.spots[e3.target_spot]
			if not bc.is_empty() and Vector2(e3.global_position.x - sp["pos"].x, e3.global_position.z - sp["pos"].z).length() < 0.5:
				bien_assis += 1
	_ok(a_table == tous_eleves.size(), "à midi et demi, les élèves déjeunent dans la Grande Salle (%d/%d)" % [a_table, tous_eleves.size()])
	_ok(bien_assis == a_table, "ils sont assis sur les bancs, à leur place (%d/%d)" % [bien_assis, a_table])
	var rectrice = vie.by_id.get("vesperine_om")
	_ok(rectrice != null and rectrice.target_spot == "estrade_s4" and rectrice.pose == "assis", "la Rectrice préside, au milieu de l'estrade")
	var places: Dictionary = {}
	var double: bool = false
	for h4 in vie.habitants:
		if h4.hidden_home or str(h4.target_spot) == "":
			continue
		if places.has(h4.target_spot):
			double = true
		places[h4.target_spot] = true
	_ok(not double, "deux habitants n'ont jamais la même place")
	temps_v56.set_hour(23.5)
	await _att(3.0)
	var couches: int = 0
	for e4 in tous_eleves:
		if e4.hidden_home:
			couches += 1
	_ok(couches == tous_eleves.size(), "à 23 h 30, les élèves sont couchés dans leur dortoir (%d/%d)" % [couches, tous_eleves.size()])
	# près des élèves : à 10 h, la récréation, ils sortent de leur salle de cours et marchent jusqu'à la
	# fontaine du cloître
	temps_v56.set_hour(9.9)
	await _att(3.0)
	# (le héros sur la vasque de la fontaine : près d'eux, mais pas sur leur chemin ; un habitant qui
	# croise le héros s'arrête et attend qu'il passe)
	await _poser(_wc(lx_v14("fontaine"), 3.6))
	temps_v56.set_hour(10.05)
	var dans_mur: int = 0
	var arrives: int = 0
	var p_dep: Array = []
	for e0 in tous_eleves:
		p_dep.append(e0.global_position)
	for k2 in range(110):
		await _att(0.5)
		for e5 in tous_eleves:
			if e5.state == "marche" and not e5.hidden_home:
				var pq := PhysicsPointQueryParameters3D.new()
				pq.position = e5.global_position + Vector3.UP * 1.0
				pq.collision_mask = 1
				var sauf: Array[RID] = []
				sauf.append_array(e5._npc_bodies)
				if pc_body != null:
					sauf.append(pc_body.get_rid())
				pq.exclude = sauf
				for r in space.intersect_point(pq, 4):
					if r["collider"] is StaticBody3D:
						dans_mur += 1
						if dans_mur <= 6:
							print("  %s dans %s à %s (vers %s)" % [e5.display_name, r["collider"].name, e5.global_position, e5.route.slice(0, 2)])
		arrives = 0
		for e6 in tous_eleves:
			if str(e6.target_spot).begins_with("fontaine") and e6.state != "marche":
				arrives += 1
		if arrives == tous_eleves.size():
			break
	var bouge: int = 0
	for i7 in range(tous_eleves.size()):
		var e7 = tous_eleves[i7]
		if e7.global_position.distance_to(p_dep[i7]) > 5.0:
			bouge += 1
		if not str(e7.target_spot).begins_with("fontaine") or e7.state == "marche":
			print("  %s : %s, %s, %.1f h, à %s, reste %d étapes" % [e7.display_name, e7.target_spot, e7.state, vie.hour(), e7.global_position, e7.route.size()])
	_ok(bouge >= tous_eleves.size() - 1, "à 10 h, ils quittent leur salle de cours (%d/%d)" % [bouge, tous_eleves.size()])
	_ok(arrives >= tous_eleves.size() - 1, "ils vont à pied jusqu'à la fontaine du cloître (%d/%d arrivés)" % [arrives, tous_eleves.size()])
	_ok(dans_mur == 0, "en chemin, personne ne passe dans un mur (%d)" % dans_mur)
	# la parole
	var parle: int = 0
	for id3 in ["lison_om", "vesperine_om", "herse_om"]:
		var n = vie.by_id.get(id3)
		if n == null:
			continue
		var f: Vector3 = -n.global_transform.basis.z
		f.y = 0.0
		f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
		place_player_v35(n.global_position + f * 1.6 + Vector3.UP * 0.1, -f)
		await _images(2)
		_talk_v31(n)
		await _images(3)
		if dialogue_v31.opened and dialogue_v31._text != null and dialogue_v31._text.text.strip_edges() != "" and not n.brain.topics(_npc_ctx_v31()).is_empty():
			parle += 1
		_close_dialogue_v31()
		await _images(1)
	_ok(parle == 3, "on leur parle : une élève, la Rectrice, le portier (%d/3)" % parle)
	temps_v56.set_hour(12.0)
	_ranger()


func lx_v14(nom: String) -> Vector3:
	return ombrelac_ext.chateau.lieux.get(nom, Vector3.ZERO)


# =================================================================== v15 : les objets du château

## (v15) Un objet du château (le premier de cette sorte qui convient), ou {}
func ob_v15(sorte: String, filtre: Callable = Callable()) -> Dictionary:
	for o in ombrelac_ext.objets.objets:
		if str(o["sorte"]) == sorte and (not filtre.is_valid() or bool(filtre.call(o))):
			return o
	return {}


## (v15) Se poser devant un objet (du côté de sa face ; sinon à « d » mètres, du côté libre)
func devant_v15(o: Dictionary, d: float = 0.6) -> void:
	var m: Vector3 = (o["a"] as Vector3).lerp(o["b"], 0.5)
	var f: Vector3 = o["face"]
	if f == Vector3.ZERO:
		f = Vector3.BACK
		var space := get_world_3d().direct_space_state
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.3
		cyl.height = 1.2
		for k in range(16):
			var a: float = TAU * k / 16.0
			var dd := Vector3(cos(a), 0, sin(a))
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = cyl
			q.transform = Transform3D(Basis(), m + dd * d + Vector3.UP * 1.0)
			var sauf: Array[RID] = []
			if pc_body != null:
				sauf.append(pc_body.get_rid())
			q.exclude = sauf
			if space.intersect_shape(q, 1).is_empty():
				f = dd
				break
	await _poser(m + f * d + Vector3.UP * 0.3, -f)
	await _att(0.4)


func _message_v15() -> String:
	return str(message.text) if message != null else ""


## (v15) S'asseoir, lire, faire tourner, sonner, dormir, préparer un élixir, jouer aux échecs…
func _objets_v15() -> void:
	var O: Node = ombrelac_ext.objets
	_ok(O != null, "les objets du château sont en place")
	if O == null:
		return
	var compte_ok: bool = true
	for e in [["siege", 90], ["livres", 60], ["portrait", 14], ["relique", 6], ["lit", 12], ["paillasse", 4], ["tableau", 2], ["carte_ciel", 3],
			["lunette", 2], ["globe", 2], ["astrolabe", 1], ["cloche", 1], ["fontaine", 1], ["echecs", 1], ["grimoire", 1], ["sphere", 1],
			["mannequin", 3], ["devise", 1], ["registre", 1], ["table_cartes", 1]]:
		if O.nombre(str(e[0])) < int(e[1]):
			compte_ok = _note(false, "objets « %s » : %d (au moins %d)" % [e[0], O.nombre(str(e[0])), e[1]])
	_ok(compte_ok, "les objets : %d sièges, %d rayonnages, 14 portraits, 6 reliques, 12 lits, les paillasses, les lunettes, la cloche, la fontaine…" % [O.nombre("siege"), O.nombre("livres")])
	_ok(donjon_v35._interactions.has(O._ia), "ils passent par les interactions du jeu (E, la gâchette)")
	# la nuit : les élèves dorment, les couloirs sont calmes
	temps_v56.set_hour(23.5)
	await _att(1.0)
	# --- lire : un livre de la Bibliothèque (loin du comptoir), avec la touche E
	var bp: Vector3 = ombrelac_ext.chateau.global_transform * (lx_v14("bibliotheque_porte") + Vector3(7.6, 0, -1.0))
	var liv: Dictionary = ob_v15("livres", func(o): return str(o["fonds"]) == "bibliotheque" and absf((o["a"] as Vector3).y - bp.y) < 0.5 and (o["a"] as Vector3).lerp(o["b"], 0.5).distance_to(bp) > 9.0)
	_ok(not liv.is_empty(), "un rayonnage de la Bibliothèque")
	if not liv.is_empty():
		await devant_v15(liv)
		_ok(str(O.courant.get("sorte", "")) == "livres" and donjon_v35.prompt(_pos()) == "E : prendre un livre", "devant un rayonnage : « E : prendre un livre » (%s)" % donjon_v35.prompt(_pos()))
		var avant: int = O._liste("livres").size()
		await _appui(KEY_E)
		_ok(_message_v15().begins_with("Tu prends un livre") and O._liste("livres").size() == avant + 1, "E : on lit un livre de la Bibliothèque (%s…)" % _message_v15().left(60))
		_ok(dialogue_v31 == null or not dialogue_v31.opened, "E lit le livre (sans parler à personne)")
	# --- s'asseoir : un banc de la Salle des Astres ; le héros assis à la bonne hauteur ; E pour se lever
	var banc: Dictionary = ob_v15("siege", func(o): return str(o["piece"]) == "astres")
	_ok(not banc.is_empty(), "un banc de la Salle des Astres")
	if not banc.is_empty():
		var t: Transform3D = banc["banc"]
		await _poser(t * Vector3(0, 0, float(banc["arriere"]) - 0.6) + Vector3.UP * 0.3, t.basis.z)
		await _att(0.4)
		var p0: Vector3 = pc_body.global_position
		_ok(str(O.courant.get("sorte", "")) == "siege" and donjon_v35.prompt(_pos()) == "E : s'asseoir", "près d'un banc : « E : s'asseoir » (%s)" % donjon_v35.prompt(_pos()))
		await _appui(KEY_E)
		await _att(1.0)
		_ok(not O.assis.is_empty() and hero_v28.state == "bateau" and hero_v28.current_anim == "v28/sit", "E : le héros s'assied (%s, %s)" % [hero_v28.state, hero_v28.current_anim])
		var dessus: float = (t * Vector3(0, float(banc["dessus"]), 0)).y
		var hips: int = hero_v28.skel.find_bone("Hips") if hero_v28.skel != null else -1
		var hy: float = (hero_v28.skel.global_transform * hero_v28.skel.get_bone_global_pose(hips).origin).y if hips >= 0 else -99.0
		_ok(hips >= 0 and absf(hy - dessus - 0.1) < 0.15, "assis à la bonne hauteur : le bassin %.2f m au-dessus de l'assise" % (hy - dessus))
		var sv: Vector3 = (O.assis["siege"] as Transform3D).origin
		var sur_banc: bool = Vector2(hero_v28.hero.global_position.x - sv.x, hero_v28.hero.global_position.z - sv.z).length() < 0.05
		_ok(sur_banc and hero_v28.facing.dot(t.basis.z) > 0.7, "sur le banc, face au tableau")
		await _att(1.0)
		_ok(pc_body.global_position.distance_to(p0) < 0.3 and hero_v28.state == "bateau", "on reste assis (le corps ne glisse pas)")
		await _appui(KEY_E)
		await _att(0.5)
		_ok(O.assis.is_empty() and hero_v28.state == "sol", "E : on se lève (%s)" % hero_v28.state)
		_ok(_pos().distance_to(p0) < 1.5, "debout, là d'où l'on s'était assis")
		# marcher : on se lève aussi
		await _appui(KEY_E)
		await _att(0.5)
		_touche(KEY_W, true)
		await _att(0.4)
		_touche(KEY_W, false)
		await _att(0.3)
		_ok(O.assis.is_empty() and hero_v28.state != "bateau", "assis, on avance : on se lève")
		# le cours : le maître à son tableau, on écoute la leçon
		var m: Node3D = ombrelac_ext.vie.by_id.get("fauconnier_om")
		var sp: Dictionary = ombrelac_ext.vie.spots.get("astres_maitre", {})
		if m != null and not sp.is_empty():
			m.global_position = sp["pos"]
			await _poser(t * Vector3(0, 0, float(banc["arriere"]) - 0.6) + Vector3.UP * 0.3, t.basis.z)
			await _att(0.3)
			O.asseoir(banc)
			await _att(2.2)
			m.global_position = sp["pos"]
			_ok(_message_v15().begins_with("Maître Fauconnier"), "assis en classe, le maître au tableau : on écoute la leçon (%s…)" % _message_v15().left(50))
			O.lever()
			await _att(0.3)
	# --- le repas : à table dans la Grande Salle à midi, Mère Fournil sert, les cœurs reviennent
	temps_v56.set_hour(12.6)
	await _att(0.5)
	var servi: bool = false
	for s in O.objets:
		if str(s["sorte"]) != "siege" or str(s["piece"]) != "grande_salle":
			continue
		var t2: Transform3D = s["banc"]
		await _poser(t2 * Vector3(0, 0, float(s["arriere"]) - 0.6) + Vector3.UP * 0.3, t2.basis.z)
		await _att(0.2)
		hero_v28.hp = 1
		if O.asseoir(s):
			await _att(6.0)
			servi = _message_v15().contains("Mère Fournil") and hero_v28.hp == hero_v28.HP_MAX
			O.lever()
			await _att(0.3)
			break
	_ok(servi, "à table à midi : Mère Fournil sert, les cœurs reviennent")
	temps_v56.set_hour(23.5)
	await _att(0.5)
	# --- agir
	var ast: Node = ombrelac_ext.chateau.get_node("Ombrelac_astrolabe_dedans")
	var o_ast: Dictionary = ob_v15("astrolabe")
	await devant_v15(o_ast, 2.6)
	_ok(str(O.courant.get("sorte", "")) == "astrolabe", "devant le Grand Astrolabe : « %s »" % donjon_v35.prompt(_pos()))
	O.agir_sur(o_ast)
	_ok(float(ast.elan) > 4.0, "on fait tourner l'astrolabe : ses anneaux s'emballent (×%.1f)" % float(ast.elan))
	await _att(3.0)
	_ok(float(ast.elan) < 6.0 and float(ast.elan) > 1.0, "puis ils ralentissent (×%.1f)" % float(ast.elan))
	O.agir_sur(ob_v15("lunette", func(o): return bool(o.get("grande", false))))
	_ok(O._liste("constellations").size() == 1 and _message_v15().contains("étoile du Nord"), "la nuit, dans la Grande Lunette : une constellation (%s…)" % _message_v15().left(60))
	var horl: Node = ombrelac_ext.chateau.get_node("Ombrelac_horloge_dedans")
	var coups: int = int(horl.coups_sonnes) + int(horl.coups_a_sonner)
	var o_cl: Dictionary = ob_v15("cloche")
	await devant_v15(o_cl, 0.7)
	_ok(str(O.courant.get("sorte", "")) == "cloche", "dans la Chambre des Rouages, la corde : « %s »" % donjon_v35.prompt(_pos()))
	O.agir_sur(o_cl)
	await _att(0.5)
	_ok(int(horl.coups_sonnes) + int(horl.coups_a_sonner) == coups + 1 and int(horl.coups_sonnes) >= 1, "on tire la corde : la cloche sonne un coup de plus (%d)" % (int(horl.coups_sonnes) + int(horl.coups_a_sonner) - coups))
	var o_fo: Dictionary = ob_v15("fontaine")
	inventory_v28.add("piece", 3)
	var pieces: int = inventory_v28.count("piece")
	O.agir_sur(o_fo)
	_ok(inventory_v28.count("piece") == pieces - 1 and int(O._st().get("voeux", 0)) == 1, "une pièce dans la fontaine : un vœu")
	var potions := func() -> int: return inventory_v28.count("potion_seve") + inventory_v28.count("potion_mana") + inventory_v28.count("elixir_etoile")
	var avant_p: int = potions.call()
	var o_pa: Dictionary = ob_v15("paillasse")
	O.agir_sur(o_pa)
	_ok(potions.call() == avant_p + 1, "à la paillasse : on prépare un élixir (il va dans le sac)")
	O.agir_sur(o_pa)
	_ok(potions.call() == avant_p + 1 and _message_v15().contains("un élixir par jour"), "un seul par jour")
	for so in ["portrait", "relique", "grimoire", "sphere", "devise", "registre", "tableau", "carte_ciel", "table_cartes", "globe", "mannequin"]:
		message.text = ""
		O.agir_sur(ob_v15(so))
		_note(_message_v15().length() > 20, "« %s » : un texte" % so)
	_ok(O._liste("portraits").size() == 1, "les portraits des anciens Recteurs, les reliques, le grimoire, la sphère, la devise… ont leur texte")
	# les échecs : assis devant l'échiquier, une partie
	var o_ec: Dictionary = ob_v15("echecs")
	await devant_v15(o_ec, 1.3)
	O.agir_sur(o_ec)
	await _att(0.5)
	_ok(not O.assis.is_empty() and O.assis.has("partie"), "à l'échiquier : on s'assied pour une partie")
	await _att(18.0)
	_ok(int(O._st().get("parties", 0)) == 1, "la partie se joue jusqu'au bout (%s)" % _message_v15().left(50))
	O.lever()
	await _att(0.3)
	# dormir : un lit du dortoir, la nuit, jusqu'au matin
	temps_v56.set_hour(22.0)
	var o_li: Dictionary = ob_v15("lit")
	await devant_v15(o_li, 0.6)
	_ok(str(O.courant.get("sorte", "")) == "lit" and donjon_v35.prompt(_pos()) == "E : dormir", "au pied d'un lit, la nuit : « E : dormir » (%s)" % donjon_v35.prompt(_pos()))
	var jour: int = temps_v56.day_count
	O.agir_sur(o_li)
	await _att(3.5)
	_ok(temps_v56.day_count == jour + 1 and absf(temps_v56.hour - 7.0) < 0.3, "on dort jusqu'au matin (%.1f h)" % temps_v56.hour)
	# la sauvegarde
	var d: Dictionary = ombrelac_ext.serialize()
	ombrelac_ext.load_data({})
	_ok(O._liste("livres").is_empty(), "une nouvelle partie oublie les livres lus")
	ombrelac_ext.load_data(d)
	_ok(O._liste("livres").size() >= 1 and O._liste("constellations").size() == 1 and int(O._st().get("voeux", 0)) == 1, "une partie chargée retrouve les livres lus, les constellations, les vœux")
	temps_v56.set_hour(12.0)
	_ranger()


# =================================================================== v16 : les quêtes, la Maison de Minuit

## (v16) Une réplique de l'habitant, comme si on avait cliqué le choix (le sac, les récompenses : comme en jeu)
func dire_v16(id_pnj: String, choix: String) -> Dictionary:
	var n: Node = ombrelac_ext.vie.by_id.get(id_pnj)
	var boite: Dictionary = {}
	_brain_reply_v48(n, func():
		boite["r"] = journal_v56.choose(n, choix)
		return boite["r"])
	return boite.get("r", {})


## (v16) Les sujets « ★ » qu'un habitant propose (leurs identifiants)
func sujets_v16(id_pnj: String) -> Array:
	var n: Node = ombrelac_ext.vie.by_id.get(id_pnj)
	return journal_v56.topics_for(n).map(func(t): return str(t["id"]))


## (v16) Une quête du carnet (onglet « Quêtes »), par son titre : [la liste, l'entrée] ou []
func carnet_v16(titre: String) -> Array:
	var l: Dictionary = journal_v56.listing()
	for k in ["en_cours", "a_faire", "accomplies"]:
		for e in l[k]:
			if str(e["titre"]) == titre:
				return [k, e]
	return []


func accepter_v16(qid: String) -> void:
	var Qn: Node = ombrelac_ext.quetes
	var qui: String = str(Qn.Q[qid]["qui"])
	dire_v16(qui, Qn._id(qid, "offre"))
	dire_v16(qui, Qn._id(qid, "accepte"))
	await _att(0.6)


func _quetes_v16() -> void:
	var Qn: Node = ombrelac_ext.quetes
	var O: Node = ombrelac_ext.objets
	_ok(Qn != null and Qn.minuit != null, "les quêtes et les caves de la Minuit sont en place")
	if Qn == null or Qn.minuit == null:
		return
	var M: Node = Qn.minuit
	var vie: Node = ombrelac_ext.vie
	_ok(not O.objet("hortense").is_empty() and not O.objet("escalier_fontaine").is_empty() and not O.objet("coffre_minuit").is_empty() and not O.objet("roue_2").is_empty(),
		"leurs objets : Hortense, l'escalier, les énigmes des caves, le coffre")
	_ok(Qn.eau_surfaces.size() == 1, "l'eau de la fontaine est trouvée dans le maillage du cloître")
	var bien: int = 0
	for id in Qn.SERVICES:
		if journal_v56.services.has(id):
			bien += 1
	_ok(bien == Qn.SERVICES.size(), "les habitants ont leurs sujets dans le carnet (%d/%d)" % [bien, Qn.SERVICES.size()])
	# les caves sont dans le roc, sous le cloître
	var dessus: float = 999.0
	for c in [[4.0, -40.0], [31.0, -40.0], [31.0, -18.0], [4.0, -18.0], [16.0, -30.0], [10.0, -23.0]]:
		var w: Vector3 = M.monde(Vector3(float(c[0]), M.FY + M.H + 0.6, float(c[1])))
		dessus = minf(dessus, ombrelac_ext.ile.height(w.x, w.z) - w.y)
	_ok(dessus > 8.0, "les caves sont dans le roc : au moins %.0f m de roche au-dessus" % dessus)
	# --- le carnet : la quête de Tobie, avant même qu'il en parle (le point d'exclamation au-dessus de lui)
	var tobie: Node = vie.by_id.get("tobie_om")
	tobie.brain.memoire["visites"] = maxi(1, int(tobie.brain.memoire.get("visites", 0)))
	await _att(0.7)
	var c0: Array = carnet_v16("La chaussette de Tobie")
	_ok(not c0.is_empty() and str(c0[0]) == "a_faire", "dans le carnet : « La chaussette de Tobie », à faire (%s)" % str(c0))
	_ok(indicateurs_v130 == null or indicateurs_v130._genre_cerveau(tobie.brain) == "quete", "un point d'exclamation au-dessus de Tobie")
	_ok(sujets_v16("tobie_om").has(Qn._id("chaussette", "offre")), "Tobie : « ★ Ta chaussette est encore sur la girouette ? »")
	# --- comme en jeu : on lui parle, on choisit, on accepte
	place_player_v35(tobie.global_position + Vector3(1.4, 0.1, 0), Vector3(-1, 0, 0))
	await _images(2)
	_talk_v31(tobie)
	await _images(3)
	_on_dialogue_choice_v31(Qn._id("chaussette", "offre"))
	await _images(2)
	var vu: bool = dialogue_v31.opened and str(dialogue_v31._text.text).contains("girouette")
	_on_dialogue_choice_v31(Qn._id("chaussette", "accepte"))
	await _images(2)
	_close_dialogue_v31()
	_ok(vu and Qn.etape("chaussette") == 0, "Tobie raconte, on accepte : la quête commence")
	await _att(0.7)
	c0 = carnet_v16("La chaussette de Tobie")
	_ok(not c0.is_empty() and str(c0[0]) == "en_cours" and str(c0[1]["objectif"]).to_lower().contains("grande lunette"), "le carnet : en cours, « %s »" % (str(c0[1]["objectif"]) if not c0.is_empty() else "?"))
	_ok(str(tobie.brain.choose("quete", _npc_ctx_v31()).get("texte", "")).contains("Lunette"), "Tobie, si on lui en reparle : où chercher")
	# la chaussette : la lunette, la cloche, au pied de la tour, Tobie
	var lun: Dictionary = ob_v15("lunette", func(o): return bool(o.get("grande", false)))
	temps_v56.set_hour(12.0)
	O.agir_sur(lun)
	_ok(Qn.etape("chaussette") == 1 and _message_v15().contains("chaussette"), "à la Grande Lunette : la chaussette sur la girouette")
	O.agir_sur(ob_v15("cloche"))
	_ok(Qn.etape("chaussette") == 2 and _message_v15().contains("chaussette"), "on sonne la cloche : la chaussette tombe")
	await _att(4.0)
	_ok(Qn.chaussette_sol.visible and not Qn.chaussette_haut.visible, "elle est au pied de la Tour de l'Horloge")
	await devant_v15(O.objet("chaussette"), 0.5)
	_ok(str(O.courant.get("id", "")) == "chaussette" and donjon_v35.prompt(_pos()) == "E : ramasser la chaussette", "« %s »" % donjon_v35.prompt(_pos()))
	await _appui(KEY_E)
	_ok(Qn.etape("chaussette") == 3 and not Qn.chaussette_sol.visible, "E : on la ramasse")
	var pieces: int = inventory_v28.count("piece")
	var r: Dictionary = dire_v16("tobie_om", Qn._id("chaussette", "rendre"))
	_ok(Qn.finie("chaussette") and Qn.indices() == 1 and str(r.get("texte", "")).contains("Indice de la Minuit (1 / 5)"), "on la rend à Tobie : la quête est accomplie, premier indice de la Minuit")
	_ok(inventory_v28.count("piece") == pieces + 6 and inventory_v28.count("croissant") >= 2, "la récompense de Tobie (6 pièces, 2 croissants)")
	await _att(0.7)
	c0 = carnet_v16("La chaussette de Tobie")
	_ok(not c0.is_empty() and str(c0[0]) == "accomplies", "le carnet : accomplie")
	# --- le pari du miel : la lunette la nuit, Fauconnier, Mère Fournil, Rouage
	await accepter_v16("miel")
	_ok(Qn.etape("miel") == 0, "Maître Rouage : le pari du miel commence")
	O.agir_sur(lun)
	_ok(Qn.etape("miel") == 0, "le jour, la lunette ne dit rien de l'heure des étoiles")
	temps_v56.set_hour(23.0)
	O.agir_sur(lun)
	_ok(Qn.etape("miel") == 1, "la nuit : on relève l'heure des étoiles")
	_ok(sujets_v16("fauconnier_om").has(Qn._id("miel", "etoiles")), "Fauconnier : « ★ J'ai relevé l'heure des étoiles. »")
	r = dire_v16("fauconnier_om", Qn._id("miel", "etoiles"))
	_ok(Qn.etape("miel") == 2 and str(r.get("texte", "")).contains("treizième"), "Fauconnier fait ses calculs (le treizième coup)")
	inventory_v28.remove("miel", inventory_v28.count("miel"))
	dire_v16("fournil_om", Qn._id("miel", "pot"))
	await _att(0.7)
	_ok(inventory_v28.count("miel") == 1 and Qn.etape("miel") == 3, "Mère Fournil donne un pot de miel")
	var rouages: int = inventory_v28.count("rouage")
	dire_v16("rouage_om", Qn._id("miel", "rendre"))
	_ok(Qn.finie("miel") and inventory_v28.count("miel") == 0 and inventory_v28.count("rouage") == rouages + 1 and Qn.indices() == 2, "Rouage prend le miel : pari tranché, deuxième indice")
	# --- l'élixir de rire : trois ingrédients, la paillasse, Maître Équerre, Sidonie
	for it in ["fleur_lune", "chouette_plume", "fiole_vide"]:
		inventory_v28.remove(it, inventory_v28.count(it))
	await accepter_v16("elixir")
	_ok(Qn.etape("elixir") == 0 and sujets_v16("buis_om").has(Qn._id("elixir", "fleur")) and sujets_v16("alambic_om").has(Qn._id("elixir", "fiole")), "Sidonie : l'élixir de rire ; Firmin et Maîtresse Alambic ont de quoi aider")
	dire_v16("buis_om", Qn._id("elixir", "fleur"))
	dire_v16("fauconnier_om", Qn._id("elixir", "plume"))
	dire_v16("alambic_om", Qn._id("elixir", "fiole"))
	await _att(0.8)
	_ok(Qn.etape("elixir") == 1, "les trois ingrédients dans le sac : à la paillasse")
	O.agir_sur(ob_v15("paillasse"))
	_ok(Qn.etape("elixir") == 2 and inventory_v28.count("fiole_vide") == 0 and inventory_v28.count("fleur_lune") == 0, "à la paillasse : l'élixir de rire (les ingrédients y passent)")
	r = dire_v16("equerre_om", Qn._id("elixir", "gouter"))
	_ok(Qn.etape("elixir") == 3 and str(r.get("geste", "")) == "rire", "Maître Équerre goûte… et rit")
	dire_v16("sidonie_om", Qn._id("elixir", "rendre"))
	_ok(Qn.finie("elixir") and Qn.indices() == 3, "Sidonie : accomplie, troisième indice")
	# --- la fougère géante : les racines la nuit, la fontaine, Firmin
	await accepter_v16("fougere")
	temps_v56.set_hour(12.0)
	await devant_v15(O.objet("racines"), 0.3)
	_ok(str(O.courant.get("id", "")) == "racines", "devant la serre : « %s »" % donjon_v35.prompt(_pos()))
	O.agir_sur(O.objet("racines"))
	_ok(Qn.etape("fougere") == 0, "le jour, la fougère fait semblant de dormir")
	temps_v56.set_hour(22.5)
	O.agir_sur(O.objet("racines"))
	_ok(Qn.etape("fougere") == 1, "la nuit, ses racines filent vers le cloître")
	pieces = inventory_v28.count("piece")
	O.agir_sur(ob_v15("fontaine"))
	_ok(Qn.etape("fougere") == 2 and inventory_v28.count("piece") == pieces, "à la fontaine : on écoute l'eau (sans y jeter de pièce)")
	dire_v16("buis_om", Qn._id("fougere", "rendre"))
	_ok(Qn.finie("fougere") and Qn.indices() == 4, "Firmin : accomplie, quatrième indice")
	# --- le livre bien élevé : deux rayons de la Bibliothèque, Dame Reliure
	await accepter_v16("livre")
	var r1: Dictionary = ob_v15("livres", func(o): return str(o.get("noeud", "")) == "Ombrelac_bibliotheque")
	var r2: Dictionary = ob_v15("livres", func(o): return str(o.get("noeud", "")) == "Ombrelac_bibliotheque" and int(o["n"]) != int(r1.get("n", -1)))
	O.agir_sur(r1)
	_ok(Qn.etape("livre") == 0 and _message_v15().contains("autre rayon"), "un premier rayon : pas là")
	O.agir_sur(r1)
	_ok(Qn.etape("livre") == 0, "le même rayon : toujours pas")
	O.agir_sur(r2)
	_ok(Qn.etape("livre") == 1 and _message_v15().contains("Journal de la Maison de Minuit"), "un autre rayon : le Journal de la Maison de Minuit")
	r = dire_v16("reliure_om", Qn._id("livre", "rendre"))
	_ok(Qn.finie("livre") and Qn.indices() == 5 and str(r.get("texte", "")).contains("cinq indices"), "Dame Reliure : accomplie, les cinq indices")
	# --- la Maison de Minuit : Anatole, Hortense, l'escalier
	await accepter_v16("minuit")
	await _att(0.7)
	_ok(Qn.etape("minuit") == 1, "Anatole : les cinq indices sont déjà là, il faut parler à Hortense")
	temps_v56.set_hour(14.0)
	var oh: Dictionary = O.objet("hortense")
	await devant_v15(oh, 0.5)
	_ok(str(O.courant.get("id", "")) == "hortense" and donjon_v35.prompt(_pos()) == "E : parler à Hortense, la grenouille", "au bord de la fontaine : « %s »" % donjon_v35.prompt(_pos()))
	await _appui(KEY_E)
	_ok(not Qn.ouverte and _message_v15().contains("la nuit"), "le jour, Hortense dort")
	temps_v56.set_hour(23.5)
	await _appui(KEY_E)
	_ok(Qn.ouverte and Qn.etape("minuit") == 2, "la nuit, avec les cinq indices : Hortense ouvre le passage")
	await _att(5.0)
	_ok(not Qn.eau_visible() and Qn.trou.visible, "le bassin s'est vidé, l'escalier est là")
	await _poser(M.monde(M.FONTAINE + Vector3(4.9, 0.3, -1.6)), Vector3(-1, 0, 0))
	await _att(0.5)
	_ok(str(O.courant.get("id", "")) == "escalier_fontaine", "au bord du bassin : « %s »" % donjon_v35.prompt(_pos()))
	await Qn.descendre()
	await _att(1.5)
	var fy: float = M.monde(Vector3(0, M.FY, 0)).y
	_ok(absf(_pos().y - fy) < 0.6 and Qn.etape("minuit") == 3, "en bas de l'escalier : les caves de la Minuit (%.1f m sous le cloître)" % (M.monde(Vector3.ZERO).y - _pos().y))
	_ok(ombrelac_ext.zone_at(_pos()) == "ombrelac_caves_minuit" and str(journal_v56.place_name(_pos())).contains("Minuit"), "le lieu : %s" % str(journal_v56.place_name(_pos())))
	await _att(2.0)
	_ok(absf(_pos().y - fy) < 0.6, "on tient debout sur le sol des caves")
	# la Porte du Treizième Coup : douze coups puis le silence, quatorze, treize
	var g1: StaticBody3D = M.portes["treize"]
	for i in 12:
		O.agir_sur(O.objet("cloche_minuit"))
		await _att(0.2)
	await _att(8.6)
	_ok(not M.ouverte("treize") and M.coups == 0, "douze coups, puis trop de silence : le compte s'efface")
	for i in 14:
		O.agir_sur(O.objet("cloche_minuit"))
		await _att(0.2)
	await _att(3.0)
	_ok(not M.ouverte("treize"), "quatorze coups : la porte reste fermée")
	for i in 13:
		O.agir_sur(O.objet("cloche_minuit"))
		await _att(0.2)
	await _att(3.0)
	_ok(M.ouverte("treize"), "treize coups, puis le silence : la Porte du Treizième Coup s'ouvre")
	await _att(3.0)
	_ok(g1.position.y < M.FY - 3.0, "la grille s'est enfoncée dans le sol")
	# on passe la porte à pied (la grille ne bloque plus)
	await _poser(M.monde(Vector3(10.0, M.FY + 0.2, -26.6)), M.monde(Vector3(10.0, 0, -40.0)) - M.monde(Vector3(10.0, 0, -26.6)))
	_touche(KEY_W, true)
	await _att(1.6)
	_touche(KEY_W, false)
	await _att(0.3)
	var lp: Vector3 = ombrelac_ext.chateau.global_transform.affine_inverse() * _pos()
	_ok(lp.z < -28.5, "on passe la porte à pied, dans la Salle des Veilleurs (z %.1f)" % lp.z)
	# la Salle des Veilleurs
	await devant_v15(O.objet("statue_coq"), 0.6)
	_ok(str(O.courant.get("id", "")) == "statue_coq", "devant une statue : « %s »" % donjon_v35.prompt(_pos()))
	await _appui(KEY_E)
	_ok(not M.ouverte("veilleurs"), "le Coq : rien ne se passe")
	O.agir_sur(O.objet("statue_chouette"))
	_ok(M.ouverte("veilleurs"), "la Chouette (celle qui veille la nuit) : la porte s'ouvre")
	# la Galerie des Trois Angles
	O.agir_sur(O.objet("roue_0"))
	_ok(not M.ouverte("angles") and M.roue_haut(0) == 1, "un quart de tour : la roue change de signe")
	for i in 2:
		O.agir_sur(O.objet("roue_0"))
	for i in 2:
		O.agir_sur(O.objet("roue_1"))
	_ok(not M.ouverte("angles"), "deux lunes noires sur trois : fermé")
	O.agir_sur(O.objet("roue_2"))
	_ok(M.ouverte("angles"), "les trois lunes noires en haut : la dernière porte s'ouvre")
	# le trésor, la lettre
	var po: int = inventory_v28.count("piece_or")
	O.agir_sur(O.objet("coffre_minuit"))
	_ok(M.ouverte("coffre") and inventory_v28.count("piece_or") == po + 8 and inventory_v28.count("carte_tresor") >= 1, "le coffre de la Minuit : le trésor")
	_ok(Qn.etape("minuit") == 4, "le carnet : tout raconter à Anatole")
	O.agir_sur(O.objet("coffre_minuit"))
	_ok(inventory_v28.count("piece_or") == po + 8, "le coffre ne se vide qu'une fois")
	message.text = ""
	O.agir_sur(O.objet("lettre_minuit"))
	_ok(_message_v15().contains("Séraphine"), "la lettre de la dernière préfète")
	# remonter
	await Qn.remonter()
	await _att(1.0)
	_ok(ombrelac_ext.zone_at(_pos()) == "ombrelac_cloitre", "on remonte au cloître")
	await _att(12.0)
	_ok(not Qn.ouverte and Qn.eau_visible() and not Qn.trou.visible, "derrière nous, l'eau revient dans le bassin")
	r = dire_v16("anatole_om", Qn._id("minuit", "rendre"))
	_ok(Qn.finie("minuit") and str(r.get("texte", "")).contains("JE LE SAVAIS"), "Anatole : « JE LE SAVAIS ! » (accomplie)")
	_ok(sujets_v16("vesperine_om").has(Qn._id("minuit", "rectrice")), "la Rectrice a un mot à dire")
	dire_v16("vesperine_om", Qn._id("minuit", "rectrice"))
	_ok(bool(Qn.st().get("rectrice", false)) and not sujets_v16("vesperine_om").has(Qn._id("minuit", "rectrice")), "une seule fois")
	await _att(0.7)
	var acc: int = 0
	for qid in Qn.ORDRE:
		var cq: Array = carnet_v16(str(Qn.Q[qid]["titre"]))
		if not cq.is_empty() and str(cq[0]) == "accomplies":
			acc += 1
	_ok(acc == 6, "le carnet : les six quêtes du château accomplies (%d/6)" % acc)
	# Hortense rouvre quand on veut (le jour aussi)
	temps_v56.set_hour(11.0)
	Qn.parler_hortense()
	_ok(Qn.ouverte, "Hortense rouvre le passage, une fois qu'on la connaît")
	Qn.fermer()
	# la sauvegarde
	var d: Dictionary = ombrelac_ext.serialize()
	ombrelac_ext.load_data({})
	_ok(Qn.etape("minuit") < 0 and not M.ouverte("treize") and M.portes["treize"].position.y == M.FY and Qn.chaussette_haut.visible, "une nouvelle partie : rien n'est fait, les portes sont fermées")
	ombrelac_ext.load_data(d)
	_ok(Qn.finie("minuit") and Qn.indices() == 5 and M.ouverte("angles") and M.portes["angles"].position.y < M.FY - 3.0 and M.roue_haut(1) == 3, "une partie chargée : les quêtes, les portes, les roues")
	temps_v56.set_hour(12.0)
	_ranger()


# =================================================================== v17 : les cours de l'Académie

## (v17) Le maître à son poste de cours (comme pendant le cours)
func en_classe_v17(m: String, l: int) -> Node:
	var Cn: Node = ombrelac_ext.cours
	var le: Dictionary = Cn.lecon(m, l)
	var n: Node3D = ombrelac_ext.vie.by_id.get(str(Cn.C[m]["maitre"]))
	n.global_position = ombrelac_ext.vie.spots[str(le["poste"])]["pos"]
	return n


## (v17) L'objet d'un exercice « jauge » (la paillasse, le grand tableau, une lunette)
func objet_jauge_v17(p: Dictionary) -> Dictionary:
	var Cn: Node = ombrelac_ext.cours
	for o in ombrelac_ext.objets.objets:
		if Cn._bon_objet(o, p):
			return o
	return {}


## (v17) Une leçon entière : le maître à son poste, les questions (justes ou fausses), l'exercice (réussi ou
## manqué), la note. Rend la réponse de la note.
func lecon_v17(m: String, justes: bool = true, exercice: bool = true) -> Dictionary:
	var Cn: Node = ombrelac_ext.cours
	var O: Node = ombrelac_ext.objets
	var qui: String = str(Cn.C[m]["maitre"])
	var l: int = Cn.reussies(m)
	var le: Dictionary = Cn.lecon(m, l)
	temps_v56.set_hour(22.5 if bool(le.get("nuit", false)) else 12.0)
	en_classe_v17(m, l)
	dire_v16(qui, Cn._id(m, "lecon"))
	dire_v16(qui, Cn._id(m, "reprendre"))
	var qs: Array = le["questions"]
	for i in range(qs.size()):
		var k: int = int(qs[i][2]) if justes else (int(qs[i][2]) + 1) % (qs[i][1] as Array).size()
		dire_v16(qui, Cn._id(m, "r%dx%d" % [i, k]))
	var p: Dictionary = le["pratique"]
	match str(p.get("type", "")):
		"cartes":
			for o in Cn.cartes_astres():
				if str(Cn.actuelle().get("etape", "")) == "pratique":
					O.agir_sur(o)
		"jauge":
			var o: Dictionary = objet_jauge_v17(p)
			await devant_v15(o, 0.7)
			O.agir_sur(o)
			for i in range(int(p.get("besoin", 3)) + 3):
				if Cn.jeu.is_empty():
					break
				Cn.caler(exercice)
				O.agir_sur(o)
		"runes":
			await _poser(Cn._centre_cercle() + Vector3(0.3, 0.3, 0.0), Vector3.FORWARD)
			await _att(0.5)
			for i in range(int(p.get("n", 3)) + 3):
				if Cn.jeu.is_empty():
					break
				Cn.jeu["phase"] = "joue"
				var seq: Array = Cn.jeu["seq"]
				var r: int = int(seq[int(Cn.jeu["k"])])
				Cn.marcher_sur(r if exercice else (r + 1) % Cn.RUNES_N)
		"mannequins":
			var ms: Array = O.objets.filter(func(x): return str(x["sorte"]) == "mannequin")
			await devant_v15(ms[0], 0.9)
			O.agir_sur(ms[0])
			for i in range(int(p.get("n", 5)) + 3):
				if Cn.jeu.is_empty():
					break
				Cn.allumer_mannequin(i % ms.size())
				O.agir_sur(ms[i % ms.size()] if exercice else ms[(i + 1) % ms.size()])
	return dire_v16(qui, Cn._id(m, "note"))


func _cours_v17() -> void:
	var Cn: Node = ombrelac_ext.cours
	var O: Node = ombrelac_ext.objets
	_ok(Cn != null and Cn.runes.size() == 5 and Cn.chevalet != null and not O.objet("bulletin").is_empty(), "les cours sont en place : les cinq runes du Cercle, le chevalet du bulletin")
	if Cn == null:
		return
	var vie: Node = ombrelac_ext.vie
	_ok(journal_v56.services.has("sortelame_om"), "Dame Sortelame a ses sujets dans le carnet")
	var nb: Dictionary = {"jauge": 0, "cartes": 0, "runes": 0, "mannequins": 0}
	for m in Cn.ORDRE:
		for le in Cn.C[m]["lecons"]:
			var t: String = str(le["pratique"].get("type", ""))
			if nb.has(t):
				nb[t] += 1
			if t == "jauge":
				_ok(not objet_jauge_v17(le["pratique"]).is_empty(), "l'exercice « %s » a son objet (%s)" % [str(le["titre"]), str(le["pratique"]["sorte"])])
	_ok(Cn.cartes_astres().size() >= 2, "des cartes du ciel dans la Salle des Astres (%d)" % Cn.cartes_astres().size())
	_ok(O.objets.filter(func(x): return str(x["sorte"]) == "mannequin").size() >= 2, "des mannequins d'entraînement")
	_ok(nb["jauge"] == 8 and nb["cartes"] == 1 and nb["runes"] == 2 and nb["mannequins"] == 1, "les exercices : %s" % str(nb))
	for m in Cn.ORDRE:
		for l in range(3):
			var po: String = str(Cn.lecon(m, l)["poste"])
			_ok(vie.spots.has(po), "%s, leçon %d : le maître a son poste « %s »" % [m, l + 1, po])
	# --- le carnet : la Rectrice et le diplôme
	var ves: Node = vie.by_id.get("vesperine_om")
	ves.brain.memoire["visites"] = maxi(1, int(ves.brain.memoire.get("visites", 0)))
	await _att(0.7)
	var c0: Array = carnet_v16("Le diplôme de l'Académie")
	_ok(not c0.is_empty() and str(c0[0]) == "a_faire", "dans le carnet : « Le diplôme de l'Académie », à faire (%s)" % str(c0))
	_ok(sujets_v16("vesperine_om").has(Cn._id("rectrice", "cours")), "la Rectrice : « ★ Comment suivre les cours de l'Académie ? »")
	var r: Dictionary = dire_v16("vesperine_om", Cn._id("rectrice", "cours"))
	_ok(str(r.get("texte", "")).contains("Cinq matières"), "elle explique les cours")
	# --- hors des heures de cours : le maître donne son horaire
	var fau: Node3D = vie.by_id.get("fauconnier_om")
	_ok(sujets_v16("fauconnier_om").has(Cn._id("astres", "lecon")), "Fauconnier : « ★ Suivre la leçon : L'étoile du Nord (1/3) »")
	fau.global_position = vie.spots["terrasse"]["pos"]
	r = dire_v16("fauconnier_om", Cn._id("astres", "lecon"))
	_ok(Cn.actuelle().is_empty() and str(r.get("texte", "")).contains("13 h"), "hors du cours : « Mon cours a lieu… »")
	# --- comme en jeu : on lui parle pendant le cours
	en_classe_v17("astres", 0)
	place_player_v35(fau.global_position + Vector3(1.2, 0.1, 0), Vector3(-1, 0, 0))
	await _images(2)
	en_classe_v17("astres", 0)
	_talk_v31(fau)
	await _images(3)
	en_classe_v17("astres", 0)
	_on_dialogue_choice_v31(Cn._id("astres", "lecon"))
	await _images(2)
	var vu: bool = dialogue_v31.opened and str(dialogue_v31._text.text).contains("Grande Casserole")
	_on_dialogue_choice_v31(Cn._id("astres", "reprendre"))
	await _images(2)
	var vu2: bool = dialogue_v31.opened and str(dialogue_v31._text.text).contains("Question 1 sur 2")
	_on_dialogue_choice_v31(Cn._id("astres", "r0x0"))
	await _images(2)
	var vu3: bool = str(dialogue_v31._text.text).contains("Gertrude bouge beaucoup") and str(dialogue_v31._text.text).contains("Question 2 sur 2")
	_on_dialogue_choice_v31(Cn._id("astres", "r1x0"))
	await _images(2)
	_close_dialogue_v31()
	_ok(vu and vu2, "la leçon : l'explication, puis « Question 1 sur 2 »")
	_ok(vu3, "une mauvaise réponse : le maître corrige, et pose la question suivante")
	_ok(str(Cn.actuelle().get("etape", "")) == "pratique" and int(Cn.actuelle()["pts"]) == 1, "une bonne réponse sur deux ; place à l'exercice")
	await _att(0.7)
	c0 = carnet_v16("Le diplôme de l'Académie")
	_ok(not c0.is_empty() and str(c0[0]) == "en_cours", "le carnet : le diplôme, en cours")
	_ok(str(ves.brain.choose("quete", _npc_ctx_v31()).get("texte", "")).contains("cartes du ciel"), "la Rectrice rappelle l'exercice")
	_ok(sujets_v16("fauconnier_om").has(Cn._id("astres", "consigne")) and not sujets_v16("alambic_om").has(Cn._id("elixirs", "lecon")), "une leçon à la fois")
	# l'exercice : la bonne carte du ciel
	var cartes: Array = Cn.cartes_astres()
	await devant_v15(cartes[0], 0.6)
	var vus: int = 0
	for o in cartes:
		if str(Cn.actuelle().get("etape", "")) == "pratique":
			O.agir_sur(o)
			vus += 1
	_ok(str(Cn.actuelle().get("etape", "")) == "note" and _message_v15().contains("étoile du Nord"), "l'exercice : la carte de la Petite Ourse trouvée (%d regards)" % vus)
	_ok(sujets_v16("fauconnier_om").has(Cn._id("astres", "note")), "Fauconnier : « ★ J'ai fini l'exercice : ma note ? »")
	r = dire_v16("fauconnier_om", Cn._id("astres", "note"))
	_ok(Cn.reussies("astres") == 1 and str(r.get("texte", "")).contains("Mention"), "la note : %s" % str(r.get("texte", "")).left(60))
	_ok(sujets_v16("fauconnier_om").has(Cn._id("astres", "lecon")), "la leçon suivante est proposée")
	# --- la jauge : la lunette de la Salle des Astres (une erreur, puis trois justes)
	var le1: Dictionary = Cn.lecon("astres", 1)
	en_classe_v17("astres", 1)
	dire_v16("fauconnier_om", Cn._id("astres", "lecon"))
	dire_v16("fauconnier_om", Cn._id("astres", "reprendre"))
	for i in range(2):
		dire_v16("fauconnier_om", Cn._id("astres", "r%dx%d" % [i, int(le1["questions"][i][2])]))
	var lun: Dictionary = objet_jauge_v17(le1["pratique"])
	await devant_v15(lun, 0.7)
	O.agir_sur(lun)
	_ok(str(Cn.jeu.get("mode", "")) == "balancier" and Cn.jeu["noeud"].is_inside_tree(), "E à la lunette : Vénus traverse le cercle")
	await _att(0.8)
	Cn.caler(false)
	O.agir_sur(lun)
	_ok(int(Cn.jeu.get("rates", 0)) == 1 and int(Cn.jeu.get("touches", 0)) == 0, "trop tôt : une erreur")
	for i in range(3):
		Cn.caler(true)
		_ok(Cn.dans_la_fenetre(), "au centre du cercle (%d)" % (i + 1))
		O.agir_sur(lun)
	_ok(Cn.jeu.is_empty() and str(Cn.actuelle().get("etape", "")) == "note" and int(Cn.actuelle()["pts"]) == 3, "trois fois au centre : l'exercice est fait (une erreur : 1 point sur 2)")
	r = dire_v16("fauconnier_om", Cn._id("astres", "note"))
	_ok(Cn.reussies("astres") == 2 and str(r.get("texte", "")).contains("3 sur 4") and str(r.get("texte", "")).contains("Très bien"), "3 sur 4 : « Très bien »")
	# --- la nuit, à l'Observatoire
	temps_v56.set_hour(12.0)
	en_classe_v17("astres", 2)
	r = dire_v16("fauconnier_om", Cn._id("astres", "lecon"))
	_ok(Cn.actuelle().is_empty() and str(r.get("texte", "")).contains("Observatoire"), "la troisième leçon se donne la nuit, à l'Observatoire")
	var gouttes: int = inventory_v28.count("goutte_rosee")
	r = await lecon_v17("astres")
	_ok(Cn.matiere_finie("astres") and str(r.get("texte", "")).contains("Excellent") and inventory_v28.count("goutte_rosee") == gouttes + 1, "la nuit : les étoiles filantes ; les astres sont réussis (le cadeau de Fauconnier)")
	# --- les élixirs : un échec (à revoir), puis trois réussites
	r = await lecon_v17("elixirs", false, false)
	_ok(Cn.reussies("elixirs") == 0 and Cn.actuelle().is_empty() and str(r.get("texte", "")).contains("à revoir"), "tout faux, la fiole ratée : « à revoir », on recommencera")
	for l in range(3):
		r = await lecon_v17("elixirs")
		_ok(Cn.reussies("elixirs") == l + 1 and str(r.get("texte", "")).contains("Excellent"), "élixirs, leçon %d : Excellent" % (l + 1))
	# --- la géométrie : la règle de craie au grand tableau
	for l in range(3):
		r = await lecon_v17("geometrie")
		_ok(Cn.reussies("geometrie") == l + 1, "géométrie, leçon %d : %s" % [l + 1, str(r.get("texte", "")).left(50)])
	# --- les sortilèges : les runes (en marchant dessus), la passe d'armes
	var le_s: Dictionary = Cn.lecon("sortileges", 0)
	en_classe_v17("sortileges", 0)
	temps_v56.set_hour(14.0)
	dire_v16("sortelame_om", Cn._id("sortileges", "lecon"))
	dire_v16("sortelame_om", Cn._id("sortileges", "reprendre"))
	for i in range(2):
		dire_v16("sortelame_om", Cn._id("sortileges", "r%dx%d" % [i, int(le_s["questions"][i][2])]))
	await _poser(Cn._centre_cercle() + Vector3(0.3, 0.3, 0.0), Vector3.FORWARD)
	await _att(0.6)
	_ok(str(Cn.jeu.get("type", "")) == "runes" and (Cn.runes[0] as Node3D).visible, "dans le Cercle : les runes s'éveillent")
	await _att(3.4)
	_ok(str(Cn.jeu.get("phase", "")) == "joue", "elles se sont allumées l'une après l'autre ; à nous")
	var seq: Array = Cn.jeu["seq"]
	for i in range(seq.size()):
		await _poser(Cn.rune_pos(int(seq[i])) + Vector3(0, 0.3, 0), Vector3.FORWARD)
		await _att(0.4)
		if i < seq.size() - 1:
			await _poser(Cn._centre_cercle() + Vector3(0, 0.3, 0), Vector3.FORWARD)
			await _att(0.3)
	_ok(str(Cn.actuelle().get("etape", "")) == "note", "on marche sur les trois runes, dans l'ordre : réussi")
	r = dire_v16("sortelame_om", Cn._id("sortileges", "note"))
	_ok(Cn.reussies("sortileges") == 1, "sortilèges, leçon 1 : %s" % str(r.get("texte", "")).left(40))
	r = await lecon_v17("sortileges")
	_ok(Cn.reussies("sortileges") == 2, "les cinq runes : %s" % str(r.get("texte", "")).left(40))
	r = await lecon_v17("sortileges")
	_ok(Cn.matiere_finie("sortileges") and str(r.get("texte", "")).contains("poussière de fée"), "la passe d'armes contre les mannequins : les sortilèges sont réussis")
	# --- la calligraphie : seulement des questions
	_ok(not sujets_v16("vesperine_om").has(Cn._id("rectrice", "diplome")), "pas encore de diplôme : il manque la calligraphie")
	for l in range(3):
		r = await lecon_v17("calligraphie")
		_ok(Cn.reussies("calligraphie") == l + 1, "calligraphie, leçon %d : %s" % [l + 1, str(r.get("texte", "")).left(40)])
	_ok(Cn.tout_fini() and (Cn.st()["recues"] as Array).size() == 5, "les cinq matières réussies, les cinq cadeaux des maîtres")
	# --- le bulletin, le diplôme
	message.text = ""
	await devant_v15(O.objet("bulletin"), 0.4)
	_ok(str(O.courant.get("id", "")) == "bulletin" and donjon_v35.prompt(_pos()) == "E : lire le bulletin de l'Académie", "au cloître, le chevalet : « %s »" % donjon_v35.prompt(_pos()))
	await _appui(KEY_E)
	_ok(_message_v15().contains("Astres : ") and _message_v15().contains("Très bien, Excellent (réussi !)"), "le bulletin : %s" % _message_v15().left(90))
	_ok(sujets_v16("vesperine_om").has(Cn._id("rectrice", "diplome")), "la Rectrice : « ★ J'ai réussi mes cinq matières. »")
	var por: int = inventory_v28.count("piece_or")
	r = dire_v16("vesperine_om", Cn._id("rectrice", "diplome"))
	_ok(Cn.diplome() and inventory_v28.count("piece_or") == por + 10 and str(r.get("texte", "")).contains("diplômé"), "le diplôme de l'Académie (et dix pièces d'or)")
	_ok(Cn.sceau.visible and Cn.bulletin().contains("DIPLÔMÉ"), "le sceau d'or sur le bulletin")
	_ok(not sujets_v16("vesperine_om").has(Cn._id("rectrice", "diplome")), "une seule fois")
	await _att(0.7)
	c0 = carnet_v16("Le diplôme de l'Académie")
	_ok(not c0.is_empty() and str(c0[0]) == "accomplies", "le carnet : le diplôme, accompli")
	# --- la sauvegarde
	var d: Dictionary = ombrelac_ext.serialize()
	ombrelac_ext.load_data({})
	_ok(not Cn.diplome() and Cn.reussies("astres") == 0 and not Cn.sceau.visible, "une nouvelle partie : pas de notes, pas de sceau")
	ombrelac_ext.load_data(JSON.parse_string(JSON.stringify(d)))
	_ok(Cn.diplome() and Cn.tout_fini() and Cn.sceau.visible and Cn.bulletin().contains("Excellent"), "une partie chargée : les notes, le diplôme, le sceau")
	temps_v56.set_hour(12.0)
	_ranger()


## (v18) Le sol, tous les degrés, en tournant de 60° avant le palier de l'étage jusqu'à 25° après (à 1,2 m
## et 2,4 m du noyau, là où l'on marche) : la plus grande marche d'une mesure à la suivante
func _rebord_palier_v18() -> float:
	var dt: Node = ombrelac_ext.chateau.get_node_or_null("Ombrelac_dortoirs")
	if dt == null:
		return 99.0
	var xs: Transform3D = dt.xf_sol
	var tc: Vector3 = xs.affine_inverse() * (dt.lieux["tour_dortoirs_centre"] as Vector3)
	var cg: Transform3D = ombrelac_ext.chateau.global_transform
	var F: float = 6.25
	var space := get_world_3d().direct_space_state
	var pire: float = 0.0
	for r in [1.2, 2.4]:
		var prec: float = -99.0
		for k in range(-60, 26):
			var a: float = PI + deg_to_rad(float(k))
			var p: Vector3 = cg * (xs * (tc + Vector3(cos(a), 0, sin(a)) * float(r)))
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * (F + 0.6), p + Vector3.UP * (F - 1.8))
			if pc_body != null:
				q.exclude = [pc_body.get_rid()]
			var h: Dictionary = space.intersect_ray(q)
			if h.is_empty():
				continue
			var y: float = (h["position"] as Vector3).y
			if prec > -90.0:
				pire = maxf(pire, absf(y - prec))
			prec = y
	return pire


# =================================================================== v18 : les créatures du château

## (v18) Faire E devant un objet de quête (comme en jeu) : vrai si c'est bien lui qu'on visait
func e_devant_v18(id: String, d: float = 0.7) -> bool:
	var O: Node = ombrelac_ext.objets
	await devant_v15(O.objet(id), d)
	var vise: bool = str(O.courant.get("id", "")) == id
	if vise:
		await _appui(KEY_E)
	else:
		O.agir_sur(O.objet(id))
	await _att(0.3)
	return vise


## (v18) Mistigri, Minerve, les chauves-souris, Séraphine
func _creatures_v18() -> void:
	var Cr: Node = ombrelac_ext.creatures
	var O: Node = ombrelac_ext.objets
	var Qn: Node = ombrelac_ext.quetes
	_ok(Cr != null and Cr.chat != null and Cr.chouette != null and Cr.fantome != null and Cr.nuee != null and Cr.souvenirs.size() == 3,
		"les créatures sont là : Mistigri, Minerve, les chauves-souris, la dame pâle, ses trois souvenirs")
	if Cr == null:
		return
	_ok(not O.objet("chat").is_empty() and not O.objet("chouette").is_empty() and not O.objet("seraphine").is_empty() and not O.objet("souvenir_lanterne").is_empty(),
		"leurs objets (E) : le chat, la chouette, la dame pâle, les souvenirs")
	_ok(journal_v56.services.has("herse_om"), "Gaspard Herse a ses sujets dans le carnet")
	for id in Cr.souvenirs:
		var sp: Vector3 = (Cr.souvenirs[id] as Node3D).position
		_ok(sp.length() > 1.0 and Cr.chateau.global_transform.affine_inverse() * sp != Vector3.ZERO, "le souvenir « %s » a sa place (%s)" % [id, str(sp)])
	# --- Mistigri, le jour, dans la Cour d'Honneur
	temps_v56.set_hour(12.0)
	var cour: Vector3 = Cr.monde(Cr.COUR)
	await _poser(cour + Vector3(0, 0.5, 6.0), Vector3(0, 0, -1))
	await _att(1.0)
	_ok(Cr.chat.position.distance_to(cour) < Cr.COUR_R + 1.0 and absf(Cr.chat.position.y - cour.y) < 0.6, "le jour, Mistigri est dans la cour, sur le pavé (%s)" % str(Cr.chat.position - cour))
	var p0: Vector3 = Cr.chat.position
	Cr._cible_chat()
	await _att(3.0)
	_ok(Cr.chat.position.distance_to(p0) > 0.5, "il se promène (%.1f m en 3 s)" % Cr.chat.position.distance_to(p0))
	# on le caresse, sans sardine
	inventory_v28.remove("sardine", inventory_v28.count("sardine"))
	Cr._chat = {"etat": "assis", "t": -1000.0}
	await _att(0.3)
	var vise: bool = await e_devant_v18("chat", 0.6)
	_ok(vise and _message_v15().contains("Mistigri") and int(Cr.st().get("caresses", 0)) >= 1, "E : on caresse Mistigri (« %s »)" % _message_v15().left(60))
	# une sardine : un cadeau, un seul par jour
	inventory_v28.add("sardine", 2)
	Cr._chat = {"etat": "assis", "t": -1000.0}
	_ok(str(O.objet("chat")["verbe"].call()) == "donner une sardine à Mistigri", "avec une sardine : « donner une sardine à Mistigri »")
	var avant: Dictionary = {}
	for c in Cr.CADEAUX:
		avant[c[0]] = inventory_v28.count(str(c[0]))
	O.agir_sur(O.objet("chat"))
	var recu: int = 0
	for c in Cr.CADEAUX:
		recu += inventory_v28.count(str(c[0])) - int(avant[c[0]])
	_ok(inventory_v28.count("sardine") == 1 and recu >= 1 and _message_v15().contains("cadeau"), "il croque la sardine et rapporte un cadeau")
	O.agir_sur(O.objet("chat"))
	_ok(inventory_v28.count("sardine") == 1 and not _message_v15().contains("cadeau"), "un seul cadeau par jour (la deuxième sardine reste dans le sac)")
	Cr.st()["chat_jour"] = Cr._jour() - 1
	O.agir_sur(O.objet("chat"))
	_ok(inventory_v28.count("sardine") == 0 and _message_v15().contains("cadeau"), "le lendemain : un autre cadeau")
	# le soir, il dort devant la cheminée de la Grande Salle (il y va quand personne ne le voit)
	var ter: Vector3 = Cr.monde(ombrelac_ext.chateau.lieux["terrasse_astrolabe"])
	await _poser(ter + Vector3(-1.0, 0.5, -1.0))
	temps_v56.set_hour(21.0)
	await _att(1.5)
	_ok(Cr.chat.position.distance_to(Cr.monde(Cr.CHEMINEE)) < 3.0 and str(Cr._chat.get("etat", "")) == "dort", "le soir, Mistigri dort devant la cheminée de la Grande Salle")
	temps_v56.set_hour(12.0)
	await _att(1.5)
	_ok(Cr.chat.position.distance_to(cour) < Cr.COUR_R + 4.0, "le matin, il retourne dans la cour")
	# --- Minerve, la chouette (si elle s'est envolée pendant la soirée de Mistigri, elle revient se poser)
	for i in range(20):
		if str(Cr._vol.get("etat", "")) == "posee" and Cr.chouette.position.distance_to(Cr.perchoir) < 0.5:
			break
		await _att(0.5)
	_ok(Cr.chouette.position.distance_to(Cr.perchoir) < 0.5 and Cr.perchoir.y > cour.y + 40.0, "le jour, Minerve dort sur la terrasse de la Tour de l'Astrolabe")
	vise = await e_devant_v18("chouette", 0.8)
	_ok(vise and _message_v15().contains("dort"), "E : elle dort (« %s »)" % _message_v15().left(50))
	temps_v56.set_hour(23.0)
	await _att(0.3)
	inventory_v28.remove("chouette_plume", inventory_v28.count("chouette_plume"))
	Cr._vol = {"etat": "posee", "t": 0.0}
	O.agir_sur(O.objet("chouette"))
	_ok(inventory_v28.count("chouette_plume") == 1 and _message_v15().contains("plume"), "la nuit, on lui parle : elle laisse une plume")
	inventory_v28.remove("chouette_plume", 1)
	O.agir_sur(O.objet("chouette"))
	_ok(inventory_v28.count("chouette_plume") == 0, "une seule plume par nuit")
	# elle s'envole (on s'éloigne), tourne autour de la tour, puis revient
	await _poser(cour + Vector3(0, 0.5, 6.0), Vector3(0, 0, -1))
	Cr._vol = {"etat": "posee", "t": 30.0}
	await _att(3.0)
	_ok(str(Cr._vol.get("etat", "")) == "vole" and Cr.chouette.position.distance_to(Cr.perchoir) > 1.0 and O.courant.get("id", "") != "chouette", "la nuit, elle s'envole autour de la tour")
	temps_v56.set_hour(12.0)
	await _att(6.0)
	_ok(str(Cr._vol.get("etat", "")) == "posee" and Cr.chouette.position.distance_to(Cr.perchoir) < 0.5, "au matin, elle revient se poser")
	# --- les chauves-souris
	_ok(not Cr.nuee.visible and Cr.caves.visible and Cr.caves.get_child_count() == 2, "le jour : pas de chauves-souris au clocher (mais dans les caves, toujours)")
	temps_v56.set_hour(23.0)
	await _images(2)
	var b0: Vector3 = (Cr.nuee.get_child(0) as Node3D).global_position
	await _att(0.5)
	var b1: Vector3 = (Cr.nuee.get_child(0) as Node3D).global_position
	_ok(Cr.nuee.visible and Cr.nuee.get_child_count() == 12 and b0.distance_to(b1) > 0.2 and b1.distance_to(Cr.monde(Cr.CLOCHER)) < 12.0, "la nuit, elles tournent autour du clocher")
	# --- Séraphine : tant qu'on ne connaît pas la Minuit, elle s'efface
	var minuit_e: int = Qn.etape("minuit")
	Qn.st()["etapes"]["minuit"] = 0
	temps_v56.set_hour(12.0)
	await _att(1.5)
	_ok(not Cr.fantome.visible and O.objet("seraphine")["si"].call() == false, "le jour, pas de dame pâle")
	temps_v56.set_hour(23.0)
	Cr.placer_fantome(0, 0.4)
	await _att(1.8)
	_ok(Cr.fantome.visible and float(Cr._fant["alpha"]) > 0.9, "la nuit, une dame pâle sous les galeries du cloître")
	var pf: Vector3 = Cr.fantome.position
	await _poser(pf + Vector3(0, 0.3, 1.5), Vector3(0, 0, -1))
	await _att(2.0)
	_ok(float(Cr._fant["alpha"]) < 0.3 and not O.objet("seraphine")["si"].call() and _message_v15().contains("Gaspard"), "on approche : elle s'efface (« %s »)" % _message_v15().left(50))
	var herse: Node = ombrelac_ext.vie.by_id.get("herse_om")
	herse.brain.memoire["visites"] = maxi(1, int(herse.brain.memoire.get("visites", 0)))
	_ok(sujets_v16("herse_om").has("q56:service:omk_fantome"), "Gaspard : « ★ On dit qu'une dame pâle erre la nuit dans le cloître ? »")
	var r: Dictionary = dire_v16("herse_om", "q56:service:omk_fantome")
	await _att(0.7)
	_ok(str(r.get("texte", "")).contains("Anatole") and Cr.etape() == -1 and carnet_v16("Le repos de Séraphine").is_empty(), "sans la Minuit : une rumeur, pas de quête")
	# --- avec la Minuit : la quête
	Qn.st()["etapes"]["minuit"] = minuit_e
	_ok(Qn.finie("minuit"), "la Maison de Minuit est trouvée (série v16)")
	await _att(0.7)
	var c0: Array = carnet_v16("Le repos de Séraphine")
	_ok(not c0.is_empty() and str(c0[0]) == "a_faire", "dans le carnet : « Le repos de Séraphine », à faire (%s)" % str(c0))
	r = dire_v16("herse_om", "q56:service:omk_fantome")
	await _att(0.7)
	c0 = carnet_v16("Le repos de Séraphine")
	_ok(Cr.etape() == 0 and str(r.get("texte", "")).contains("Minuit") and not c0.is_empty() and str(c0[0]) == "en_cours" and str(c0[1]["objectif"]).contains("dame pâle"),
		"Gaspard en dit plus : la quête commence (« %s »)" % (str(c0[1]["objectif"]) if not c0.is_empty() else "?"))
	_ok(not sujets_v16("herse_om").has("q56:service:omk_fantome"), "le sujet ne revient pas")
	Cr.placer_fantome(1, 0.5)
	await _poser(Cr.fantome.position + Vector3(0, 0.3, 2.2), Vector3(0, 0, -1))
	await _att(2.0)
	_ok(float(Cr._fant["alpha"]) > 0.8 and Cr.fantome.position.distance_to(_pos()) < 4.5, "elle ne s'efface plus : elle s'arrête et nous regarde")
	vise = await e_devant_v18("seraphine", 1.2)
	c0 = carnet_v16("Le repos de Séraphine")
	_ok(vise and Cr.etape() == 1 and _message_v15().contains("Séraphine") and not c0.is_empty() and str(c0[1]["objectif"]).contains("0 / 3"), "E : Séraphine raconte ; le carnet : les trois souvenirs (0 / 3)")
	# --- les souvenirs : seulement la nuit
	temps_v56.set_hour(12.0)
	await _att(0.8)
	_ok(not (Cr.souvenirs["ruban"] as Node3D).visible and not O.objet("souvenir_ruban")["si"].call(), "le jour, les souvenirs ne se voient pas")
	temps_v56.set_hour(23.0)
	await _att(0.8)
	var n: int = 0
	for id in ["ruban", "plume", "lanterne"]:
		_ok((Cr.souvenirs[id] as Node3D).visible, "la nuit : %s" % Cr.SOUVENIRS[id]["nom"])
		vise = await e_devant_v18("souvenir_" + id, 1.0)
		n += 1
		_ok(vise and (Cr.st()["souvenirs"] as Array).has(id) and not (Cr.souvenirs[id] as Node3D).visible, "E : on prend %s (%d / 3)" % [Cr.SOUVENIRS[id]["nom"], n])
	c0 = carnet_v16("Le repos de Séraphine")
	_ok(Cr.etape() == 2 and not c0.is_empty() and str(c0[1]["objectif"]).to_lower().contains("rendre"), "les trois souvenirs : les rendre à Séraphine")
	# --- on les lui rend
	var lf: int = inventory_v28.count("lanterne_fee")
	var po: int = inventory_v28.count("piece_or")
	Cr.placer_fantome(2, 0.5)
	await _poser(Cr.fantome.position + Vector3(-2.0, 0.3, 0.0), Vector3(1, 0, 0))
	await _att(1.5)
	vise = await e_devant_v18("seraphine", 1.2)
	_ok(vise and Cr.etape() == 3 and inventory_v28.count("lanterne_fee") == lf + 1 and inventory_v28.count("piece_or") == po + 5, "Séraphine reprend ses souvenirs : une lanterne de fée, cinq pièces d'or")
	await _att(1.5)
	c0 = carnet_v16("Le repos de Séraphine")
	_ok(not Cr.fantome.visible and not O.objet("seraphine")["si"].call() and not c0.is_empty() and str(c0[0]) == "accomplies", "elle s'en va en lumières bleues ; le carnet : accomplie")
	# --- la partie enregistrée
	var d: Dictionary = ombrelac_ext.serialize()
	ombrelac_ext.load_data({})
	_ok(Cr.etape() == -1 and Cr.trouves() == 0, "une nouvelle partie : Séraphine attend encore")
	ombrelac_ext.load_data(JSON.parse_string(JSON.stringify(d)))
	_ok(Cr.etape() == 3 and Cr.trouves() == 3, "une partie chargée : Séraphine repose en paix")
	temps_v56.set_hour(12.0)
	_ranger()


## (v18.1) Attendre n images de physique (le temps du jeu, et non celui de la machine)
func _physique_v181(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

## Extension « Le Château d'Ombrelac » : l'île est construite et compte dans le monde (le relief, le
## plateau du château, le lac, la gorge) ; le débarcadère ; la mer de l'île est navigable et rejoint
## celle de l'Île aux Moaïs ; le château est bâti (ses bâtiments, ses formes de collision) ; on y arrive
## par la téléportation et l'on tient debout au débarcadère, sur la route, sur le viaduc, dans la Cour
## d'Honneur, dans le Cloître, sur le Pont Couvert ; les noms des lieux ; les fenêtres s'allument la
## nuit et s'éteignent le jour ; la sauvegarde. La Grande Salle : on y entre, on y tient debout,
## ses murs arrêtent le héros, ses lumières. La Bibliothèque : on y entre, on tient debout en bas et
## sur la galerie, ses lumières.
const NOM := "48_ombrelac"
const IleO := preload("res://scripts/ext_chateau/ile_ombrelac.gd")


func _wo(x: float, z: float, dy: float = 0.4) -> Vector3:
	return IleO.W(x, z, ombrelac_ext.ile.height_l(x, z) + dy)


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
	await _poser(_wc(ombrelac_ext.chateau.lieux["pont_milieu"], 1.0))
	_ok(await _debout("le Pont Couvert"), "on tient debout au milieu du Pont Couvert, au-dessus du lac (y %.1f)" % _pos().y)
	_ok(_pos().y > IleO.ROC_Y - 1.5, "sur le tablier, pas dans le lac (y %.1f)" % _pos().y)
	# --- les fenêtres : allumées la nuit, éteintes le jour
	temps_v56.set_hour(22.0)
	await _att(1.5)
	var vit: ShaderMaterial = ombrelac_ext.Kit.mat("vitre")
	_ok(float(vit.get_shader_parameter("nuit")) > 0.9, "la nuit, les fenêtres s'allument")
	_ok(inter != null and inter.nuit > 0.9, "la nuit, les bougies de la Grande Salle éclairent plus fort")
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

## Le jeu démarre : le monde est construit, une nouvelle partie commence au village.
const NOM := "demarrage"


func _serie() -> void:
	var nom: String = str(ProjectSettings.get_setting("application/config/name"))
	_ok(nom.contains(" V"), "version : « %s »" % nom)
	_ok(chargement_v131 == null or not is_instance_valid(chargement_v131) or not chargement_v131.en_cours, "l'écran de chargement s'est effacé")
	for v in ["faune_v132", "sombreval_v121", "pasta_v97", "crayon_v99", "grande_v59", "moai_v87", "pixel_v90", "maisons_v81", "teleport_v58"]:
		_ok(get(v) != null, "le monde contient « %s »" % v)
	_ok(not get_tree().paused, "le jeu n'est pas en pause")
	_ok(npcs_v31.size() > 300, "habitants : %d" % npcs_v31.size())
	_ok(maisons_v81.portes.size() > 1000, "maisons où l'on peut entrer : %d" % maisons_v81.portes.size())
	var sans: Array = []
	for pl in teleport_v58.PLACES:
		if teleport_v58.spot(str(pl[0])).size() != 2:
			sans.append(str(pl[0]))
	_ok(sans.is_empty(), "les %d îles et grandes places ont un point d'arrivée %s" % [teleport_v58.PLACES.size(), str(sans)])
	_ok(hero_v28.hp == hero_v28.HP_MAX, "nouvelle partie : vie pleine (%d)" % hero_v28.hp)
	var p: Vector3 = _pos()
	_ok(Vector2(p.x - 2.0, p.z - 8.0).length() < 4.0, "nouvelle partie : le héros commence au village %s" % str(p))
	var debout: bool = await _debout("au départ")
	_ok(debout, "le héros tient debout au départ")
	var h0: float = temps_v56.hour
	await _att(2.0)
	_ok(temps_v56.hour != h0 or temps_v56.frozen, "l'heure avance (%.3f -> %.3f)" % [h0, temps_v56.hour])
	# le mode testeur s'ouvre et se ferme
	testeur_v78.open_menu()
	await _att(0.3)
	_ok(dialogue_v31.opened, "le menu du mode testeur s'ouvre")
	_close_dialogue_v31()
	await _att(0.2)
	_ok(not dialogue_v31.opened, "et se ferme")
	# V204 : les Long-Cous et les Grand-Becs sont sur l'Île Pixelithique, pas à côté du feu de camp
	var egares204: int = 0
	var betes204: int = 0
	for motif204 in ["Long_Cou_*", "Grand_Bec_*"]:
		for bete204 in find_children(str(motif204), "Node3D", true, false):
			betes204 += 1
			var pb204: Vector3 = (bete204 as Node3D).global_position
			if Vector2(pb204.x, pb204.z).length() < 300.0:
				egares204 += 1
	_ok(betes204 == 9 and egares204 == 0, "les bêtes de l'Île Pixelithique sont chez elles dès le départ (%d bêtes, %d égarées près du village)" % [betes204, egares204])
	# V205 : envoyé ailleurs alors qu'on tient la barre, on quitte le bateau (avant : coincé à bord)
	_board_boat_v29()
	await _images(3)
	var bord205: bool = boat_v29.driving
	var but205 := Vector3(2.0, _height_at(2.0, 8.0) + 0.2, 8.0)
	place_player_v35(but205, Vector3.FORWARD)
	await _images(6)
	var ou205: Vector3 = _player_pos_v27()
	_ok(bord205 and not boat_v29.driving and Vector2(ou205.x - but205.x, ou205.z - but205.z).length() < 1.5, "téléporté depuis la barque : on la quitte et on reste à l'arrivée (%.1f, %.1f)" % [ou205.x, ou205.z])
	# V206 : une échelle au bout de chaque ponton ; à la nage, à son pied, on se hisse sur le plancher
	var ech206: Dictionary = boat_v29.echelles[0] if not boat_v29.echelles.is_empty() else {}
	_ok(boat_v29.echelles.size() == boat_v29.docks.size() and boat_v29.echelles.size() >= 10, "chaque ponton a son échelle (%d)" % boat_v29.echelles.size())
	var pied206: Vector3 = ech206.get("pied", Vector3.ZERO)
	place_player_v35(pied206 + Vector3(0.0, -0.9, 0.0), Vector3.FORWARD)
	await _att(1.5)
	var haut206: Vector3 = ech206.get("haut", Vector3.ZERO)
	var la206: Vector3 = _player_pos_v27()
	_ok(Vector2(la206.x - haut206.x, la206.z - haut206.z).length() < 1.5 and absf(la206.y - boat_v29.DECK_Y) < 0.6, "à la nage au pied de l'échelle du ponton du village : on se retrouve sur le plancher (%.1f m de haut)" % la206.y)
	place_player_v35(Vector3(2.0, _height_at(2.0, 8.0) + 0.2, 8.0), Vector3.FORWARD)
	await _images(4)
	# V207 : le temple englouti (70 m sous terre) n'est montré que si l'on est sous terre, pas trop loin
	await _images(4)
	var sec207: Node3D = donjon_v35.sections.get("village", null)
	var blocs207: int = sec207.get_child_count() if sec207 != null else 0
	_ok(sec207 != null and blocs207 > 500 and not sec207.visible and not donjon_v35.montre, "à la surface, le temple englouti n'est pas dessiné (%d morceaux)" % blocs207)
	place_player_v35(sec207.global_position + sec207.global_transform.basis * Vector3(0.0, 0.6, -10.0), Vector3.FORWARD)
	await _images(6)
	_ok(sec207.visible and (donjon_v35.sections["jungle"] as Node3D).visible, "dans le temple, il est dessiné")
	_ok(not donjon_v35.voir_v207(Vector3(900.0, -90.0, 1400.0)) and donjon_v35.voir_v207(sec207.global_position), "sous terre mais à l'autre bout de la carte : pas dessiné")
	place_player_v35(Vector3(2.0, _height_at(2.0, 8.0) + 0.2, 8.0), Vector3.FORWARD)
	await _images(6)
	_ok(not sec207.visible, "revenu au village : il n'est plus dessiné")

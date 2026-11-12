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

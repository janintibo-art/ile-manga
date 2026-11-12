## Les parties : on sauvegarde, une nouvelle partie remet tout à zéro, on recharge et tout revient ;
## la copie de secours sauve une partie abîmée ; le choix « Tout public / Public averti ».
const NOM := "sauvegarde"
const Saves := preload("res://scripts/save_manager.gd")
const Public := preload("res://scripts/public_v111.gd")


func _ile(id: String) -> void:
	var l: Array = testeur_v78._islands()
	testeur_v78._list = l
	for i in l.size():
		if str(l[i][1]) == id:
			testeur_v78._go(i)
			return


func _serie() -> void:
	# --- partie 1 : on vit un peu
	inventory_v28.add("pomme", 3)
	inventory_v28.add("piece", 77)
	progression_v63.gain(40, "test")
	_ile("azur")
	await _att(0.8)
	var lieu: Vector3 = _pos()
	var pom: int = inventory_v28.count("pomme")
	var pie: int = inventory_v28.count("piece")
	var xp: int = int(progression_v63.xp)
	var niv: int = int(progression_v63.level)
	_ok(pom >= 3 and pie >= 77, "partie 1 : pommes %d, pièces %d" % [pom, pie])
	_ok(_save_slot(1), "sauvegarde dans l'emplacement 1")
	_ok(FileAccess.file_exists(Saves.path_for(1)), "le fichier de la partie existe")
	_ok(not Saves.read_slot(1).is_empty(), "la partie se relit")
	# --- une nouvelle partie dans l'emplacement 2 : tout est remis
	game_menu._load_or_create(2, true)
	await _att(1.2)
	_ok(inventory_v28.count("pomme") == 0 and inventory_v28.count("piece") < pie, "nouvelle partie : le sac est vide (pommes %d, pièces %d)" % [inventory_v28.count("pomme"), inventory_v28.count("piece")])
	_ok(Vector2(_pos().x - 2.0, _pos().z - 8.0).length() < 5.0, "nouvelle partie : au village %s" % str(_pos()))
	# --- on recharge la partie 1 : tout revient
	game_menu._load_or_create(1, false)
	await _att(1.5)
	_ok(inventory_v28.count("pomme") == pom and inventory_v28.count("piece") == pie, "partie rechargée : pommes %d / %d, pièces %d / %d" % [inventory_v28.count("pomme"), pom, inventory_v28.count("piece"), pie])
	_ok(int(progression_v63.xp) == xp and int(progression_v63.level) == niv, "partie rechargée : expérience %d / %d, niveau %d" % [int(progression_v63.xp), xp, int(progression_v63.level)])
	_ok(_pos().distance_to(lieu) < 6.0, "partie rechargée : à Port-Azur (%.1f m de l'endroit sauvegardé)" % _pos().distance_to(lieu))
	# --- la copie de secours (V83) : on sauvegarde deux fois, on abîme la partie, elle revient quand même
	_ok(_save_slot(1), "deuxième sauvegarde")
	_ok(FileAccess.file_exists(Saves.path_for(1) + ".bak"), "la copie de secours existe")
	var f: FileAccess = FileAccess.open(Saves.path_for(1), FileAccess.WRITE)
	f.store_string("{abîmé")
	f.close()
	var relu: Dictionary = Saves.read_slot(1)
	_ok(not relu.is_empty(), "partie abîmée : la copie de secours prend le relais")
	_ok(_save_slot(1), "on resauvegarde par-dessus")
	_ok(not Saves.read_slot(1).is_empty(), "la partie est de nouveau saine")
	# --- Tout public / Public averti
	var avant: bool = Public.averti()
	Public.choisir("averti", false)
	_ok(Public.averti(), "Public averti choisi")
	Public.choisir("tout", false)
	_ok(Public.tout() and not Public.averti(), "Tout public choisi")
	if avant:
		Public.choisir("averti", false)
	Saves.delete_slot(2)

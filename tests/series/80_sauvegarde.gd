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
	# (en arrivant, une découverte peut rapporter de l'expérience : on la laisse tomber avant de compter)
	await _att(2.0)
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
	# --- V218 : la sauvegarde automatique s'écrit à part (sur un autre cœur) : même fichier que sur place
	_ok(_save_slot(0), "sauvegarde automatique, écrite sur place")
	var sur_place218: Dictionary = Saves.read_slot(0)
	var pommes218: int = inventory_v28.count("pomme")
	var t218: int = Time.get_ticks_usec()
	_ok(_save_slot(0, true), "sauvegarde automatique, écrite à part : elle part")
	var parti218: float = float(Time.get_ticks_usec() - t218) / 1000.0
	# (la partie change aussitôt : ce qui s'écrit est la copie prise à l'instant de la sauvegarde)
	inventory_v28.add("pomme", 5)
	var a_part218: Dictionary = Saves.read_slot(0)          # (lire attend la fin de l'écriture)
	_ok(Saves.tache_finie_v218() and Saves.tache_reussie_v218(), "l'écriture à part se termine et réussit (partie en %.1f ms)" % parti218)
	for cle218 in ["saved_at", "play_seconds"]:
		sur_place218.erase(cle218)
		a_part218.erase(cle218)
	_ok(not a_part218.is_empty() and JSON.stringify(sur_place218) == JSON.stringify(a_part218), "le fichier écrit à part est le même que le fichier écrit sur place (%d octets ; les 5 pommes ajoutées ensuite n'y sont pas)" % JSON.stringify(a_part218).length())
	_ok(FileAccess.file_exists(Saves.path_for(0) + ".bak") and not FileAccess.file_exists(Saves.path_for(0) + ".tmp"), "la copie de secours est là, pas de fichier temporaire oublié")
	# une sauvegarde à la main juste après une sauvegarde automatique : l'une après l'autre, les deux saines
	_ok(_save_slot(0, true) and _save_slot(1), "une sauvegarde à la main juste derrière la sauvegarde automatique")
	var auto218: Dictionary = Saves.read_slot(0)
	var main218: Dictionary = Saves.read_slot(1)
	_ok(not auto218.is_empty() and not main218.is_empty() and int(auto218.get("slot", -1)) == 0 and int(main218.get("slot", -1)) == 1, "les deux fichiers sont sains")
	inventory_v28.remove("pomme", inventory_v28.count("pomme") - pommes218)
	# --- Tout public / Public averti
	var avant: bool = Public.averti()
	Public.choisir("averti", false)
	_ok(Public.averti(), "Public averti choisi")
	Public.choisir("tout", false)
	_ok(Public.tout() and not Public.averti(), "Tout public choisi")
	if avant:
		Public.choisir("averti", false)
	Saves.delete_slot(2)

## Les langues : en anglais et en espagnol, les textes des tables se traduisent (un échantillon
## de 400 au hasard, et les motifs à trous), le menu et les objets changent de langue ; retour au français.
const NOM := "langues"
const Langue := preload("res://scripts/langue_v104.gd")


func _table(code: String) -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/langues/%s.json" % code))
	return d if d is Dictionary else {}


func _serie() -> void:
	for code in ["en", "es"]:
		var tb: Dictionary = _table(code)
		var textes: Dictionary = tb.get("textes", {})
		_ok(textes.size() > 20000, "%s : %d textes dans la table" % [code, textes.size()])
		Langue.choisir(code, false)
		await _images(2)
		var cles: Array = textes.keys()
		var rng := RandomNumberGenerator.new()
		rng.seed = 104
		var faux: Array = []
		for k in range(400):
			var fr: String = str(cles[rng.randi_range(0, cles.size() - 1)])
			var attendu: String = str(textes[fr])
			var vu: String = Langue.t(fr)
			if vu != attendu and vu.strip_edges() != attendu.strip_edges():
				faux.append("%s -> %s" % [fr.left(30), vu.left(30)])
		_ok(faux.size() <= 4, "%s : %d textes sur 400 mal traduits %s" % [code, faux.size(), str(faux.slice(0, 4))])
		# les objets du sac
		var pomme: String = Langue.t(str(inventory_v28.ITEMS["pomme"]["name"]))
		_ok(pomme != str(inventory_v28.ITEMS["pomme"]["name"]), "%s : la pomme s'appelle « %s »" % [code, pomme])
		# un texte à trous (motif)
		var m: String = Langue.t("La mouette lâche %s !" % "une pomme")
		_ok(not m.begins_with("La mouette"), "%s : texte à trous traduit (« %s »)" % [code, m])
		# le menu de jeu s'ouvre et se ferme dans cette langue
		game_menu.open_menu()
		await _att(0.4)
		_ok(game_menu.opened, "%s : le menu s'ouvre" % code)
		game_menu._close()
		await _att(0.2)
	Langue.choisir("fr", false)
	await _images(2)
	_ok(Langue.t("La mouette lâche %s !" % "une pomme").begins_with("La mouette"), "retour au français")

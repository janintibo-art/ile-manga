## Toutes les îles et grandes places du mode testeur, et un lieu de quête sur quatre (un autre quart
## à chaque version, selon le numéro) : on y arrive et l'on tient debout.
const NOM := "voyages"


func _tour(liste: Array, genre: String, attente: float) -> int:
	testeur_v78._list = liste
	var n: int = 0
	var t0: int = Time.get_ticks_msec()
	for i in liste.size():
		_ranger()
		testeur_v78._go(i)
		await _att(0.25)
		var debout: bool = await _debout("%s « %s »" % [genre, str(liste[i][0])], attente)
		if debout:
			n += 1
		if i % 25 == 24:
			print("  … %s : %d / %d (%.0f s)" % [genre, i + 1, liste.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	return n


func _serie() -> void:
	var iles: Array = testeur_v78._islands()
	_ok(iles.size() == teleport_v58.PLACES.size() and iles.size() > 30, "îles et grandes places au menu : %d" % iles.size())
	var n1: int = await _tour(iles, "île", 1.0)
	_ok(n1 == iles.size(), "arrivée sur les îles : %d sur %d" % [n1, iles.size()])
	var tous: Array = testeur_v78._quest_places()
	_ok(tous.size() > 20, "lieux de quête au carnet : %d" % tous.size())
	var nom: String = str(ProjectSettings.get_setting("application/config/name"))
	var v: int = int(nom.get_slice(" V", nom.get_slice_count(" V") - 1)) if nom.contains(" V") else 0
	var lieux: Array = []
	for i in tous.size():
		if i % 4 == v % 4:
			lieux.append(tous[i])
	var n2: int = await _tour(lieux, "lieu de quête", 0.8)
	_ok(n2 == lieux.size(), "arrivée aux lieux de quête (un quart) : %d sur %d" % [n2, lieux.size()])
	_ranger()
	testeur_v78._list = iles
	testeur_v78._go(0)
	await _debout("retour au village")

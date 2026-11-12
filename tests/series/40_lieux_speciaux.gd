## Les raccourcis spéciaux du mode testeur : souterrain du Grand Moaï, Île Pixelithique (cirque et
## grotte), château du comte (vestibule, porte du comte, souterrains).
const NOM := "lieux_speciaux"


func _serie() -> void:
	for id in ["moai89", "pixel90", "pixel90g", "chateau124", "comte128", "cachots128"]:
		_ranger()
		var p0: Vector3 = _pos()
		testeur_v78._pick(id)
		await _att(2.5)
		var p1: Vector3 = _pos()
		_ok(p1.distance_to(p0) > 5.0, "%s : le héros a été emmené (%s)" % [id, str(p1)])
		var debout: bool = await _debout(id, 1.2)
		_ok(debout, "%s : le héros tient debout" % id)
	# les donjons à énigmes ne sont construits qu'à l'entrée : le testeur y entre par la porte (V134)
	var lieux: Dictionary = journal_v56.lieux
	for id in ["pyramide_interieur", "xibalba", "cinq_soleils", "neuf_cercles", "mille_marches", "usine_grise"]:
		if not _ok(lieux.has(id), "donjon « %s » : au carnet des lieux" % id):
			continue
		_ranger()
		testeur_v78._list = [[id, lieux[id]]]
		testeur_v78._go(0)
		await _att(2.5)
		var debout2: bool = await _debout("donjon « %s »" % id, 1.2)
		_ok(debout2 and _pos().distance_to(lieux[id]) < 12.0, "donjon « %s » : on y entre et l'on tient debout (%.1f m de l'arrivée)" % [id, _pos().distance_to(lieux[id])])
	_ranger()
	testeur_v78._list = testeur_v78._islands()
	testeur_v78._go(0)
	await _debout("retour au village")

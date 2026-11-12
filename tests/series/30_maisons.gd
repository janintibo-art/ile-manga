## Toutes les histoires de maisons du mode testeur : on entre, la pièce est construite, on tient debout.
const NOM := "maisons"


func _serie() -> void:
	var hist: Array = testeur_v78._house_stories()
	_ok(hist.size() > 40, "histoires de maisons : %d" % hist.size())
	var n_ok: int = 0
	for i in hist.size():
		_ranger()
		await _images(2)
		var sc: String = str((hist[i][1] as Array)[0])
		var quoi: String = "maison « %s »" % str(hist[i][0])
		testeur_v78._visit(sc)
		await _att(0.3)
		# on attend la fin de l'entrée (fondu, porte) avant de regarder… et avant de ressortir
		for k in range(40):
			if not maisons_v81.busy:
				break
			await _att(0.1)
		var ok: bool = _note(maisons_v81.inside, quoi + " : on n'est pas entré")
		if ok:
			ok = _note(maisons_v81.room != null and is_instance_valid(maisons_v81.room), quoi + " : pas de pièce") and ok
			var debout: bool = await _debout(quoi, 0.6)
			ok = debout and ok
		if ok:
			n_ok += 1
		maisons_v81._teardown()
		await _att(0.15)
	_ok(n_ok == hist.size(), "maisons visitées : %d sur %d" % [n_ok, hist.size()])
	_ok(not maisons_v81.inside, "on est bien ressorti")

## Montjoie, le Lac des Grenouilles (V152) : la cabane d'Yvon, la ferme de Gaubert, la capitainerie et la
## cabane d'Odon s'ouvrent (on y entre) ; on peut entrer dans le lac : on y marche, puis on y nage (à la
## hauteur du lac, pas de la mer), on plonge, on remonte, et l'on ressort sur la rive.
const NOM := "lac"


func _serie() -> void:
	temps_v56.set_hour(9.0)
	var yvon := Vector3(962.7, 6.3, 678.1)
	var mi: int = maisons_v81.nearest(yvon, 3.0)
	_ok(mi >= 0, "la cabane d'Yvon a une porte")
	if mi >= 0:
		var e0: Dictionary = maisons_v81.portes[mi]
		_ok(str(e0.get("owner", "")) == "yvon", "c'est la maison d'Yvon (%s)" % str(e0.get("owner", "")))
		_poser((e0["door"] as Vector3) + (e0["out"] as Vector3) * 1.0, -(e0["out"] as Vector3))
		await _att(0.5)
		maisons_v81.enter(mi)
		for k in range(60):
			await _att(0.1)
			if maisons_v81.inside and not maisons_v81.busy:
				break
		_ok(maisons_v81.inside, "on entre chez Yvon")
		maisons_v81._teardown()
		await _att(0.5)
	var proprios: Dictionary = {}
	for e in maisons_v81.portes:
		proprios[str(e.get("owner", ""))] = true
	_ok(proprios.has("gaubert") or proprios.has("germaine"), "la ferme de Gaubert s'ouvre")
	_ok(proprios.has("odon"), "la cabane d'Odon s'ouvre")
	# le lac
	var rive := Vector3(986.0, 3.8, 679.3)
	_ok(montjoie_v71.lac_niveau(rive + Vector3(0, 0, 10)) == 3.2 and montjoie_v71.lac_niveau(Vector3(961.9, 6.3, 678.0)) == -INF, "la surface du lac : 3,2 m (et rien hors du lac)")
	_poser(rive, Vector3.BACK)
	await _att(1.0)
	_touche(KEY_Z, true)
	_touche(KEY_W, true)
	await _att(4.0)
	_touche(KEY_Z, false)
	_touche(KEY_W, false)
	await _att(0.5)
	_ok(str(hero_v28.state) == "nage" and _pos().z > rive.z + 5.0, "on entre dans le lac, et l'on nage (%s, %.1f m)" % [str(hero_v28.state), _pos().z - rive.z])
	_ok(absf(mer_v55.eau - 3.2) < 0.01 and _pos().y > 1.5, "à la surface du lac, pas de la mer (pieds à %.2f)" % _pos().y)
	# plonger, remonter
	_touche(KEY_CTRL, true)
	await _att(1.2)
	_touche(KEY_CTRL, false)
	var bas: float = _pos().y
	_touche(KEY_SPACE, true)
	await _att(1.6)
	_touche(KEY_SPACE, false)
	await _att(0.5)
	_ok(bas < 1.6 and _pos().y > bas + 0.4, "on plonge (%.2f) et l'on remonte (%.2f)" % [bas, _pos().y])
	# ressortir : on revient au ponton (au nord) et l'on s'y hisse (Espace)
	_poser(Vector3(986.0, 2.2, 681.2), Vector3.FORWARD)
	await _att(0.8)
	var sorti: bool = false
	for k in range(8):
		_touche(KEY_Z, true)
		_touche(KEY_W, true)
		await _att(0.4)
		_appui(KEY_SPACE)
		await _att(0.6)
		_touche(KEY_Z, false)
		_touche(KEY_W, false)
		if str(hero_v28.state) != "nage":
			sorti = true
			break
	await _att(1.0)
	_ok(sorti and _pos().y > 3.4, "on se hisse sur le ponton (%s, %s)" % [str(hero_v28.state), str(_pos())])
	# V152 : le menu du mode testeur, « Voyager », se range en pages (dix touches au plus)
	_close_dialogue_v31()
	await _att(0.2)
	testeur_v78._menu_voyage()
	await _att(0.3)
	var ids: Array = []
	for c in dialogue_v31.choices:
		ids.append(str(c["id"]))
	_ok(ids.size() <= 10 and ids.has("mpage:1") and ids.has("menu"), "le mode testeur : « Voyager » en pages (%d choix)" % ids.size())
	testeur_v78._pick("mpage:1")
	await _att(0.3)
	var ids2: Array = []
	for c2 in dialogue_v31.choices:
		ids2.append(str(c2["id"]))
	_ok(ids2.size() <= 10 and ids2.has("mpage:0"), "page suivante, et retour possible")
	_close_dialogue_v31()

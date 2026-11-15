## Les quartiers de Néopolis, dedans (V155) : le rez-de-chaussée selon le quartier (le hangar du Quai,
## l'atelier, le comptoir de nouilles et la boutique des Ruelles, la salle de jeux des Arcades) ; le
## karaoké et l'hôtel capsule ; une porte d'appartement qui s'ouvre (« Entrez donc ! »), l'appartement
## (on y entre, ses murs tiennent, ses habitants) ; le toit (par l'ascenseur du dernier étage : le
## parapet tient, la longue-vue, on redescend) ; debout sur un toit sans y être monté : il se bâtit ;
## l'anglais.
const NOM := "quartiers"
const Langue := preload("res://scripts/langue_v104.gd")


func _tour(T: Node, rdc: String, min_n: int = 3) -> int:
	for t in T.tours:
		if str(t.get("rdc", "")) == rdc and (t["etages"] as Array).size() >= min_n:
			return int(t["id"])
	return -1


func _entrer(T: Node, id: int) -> void:
	var t: Dictionary = T.tours[id]
	place_player_v35((t["sortie"] as Vector3) + Vector3.UP * 0.3, -(t["n"] as Vector3))
	await _att(0.8)
	T.enter(id)
	await _att(1.0)


func _sortir(T: Node) -> void:
	T.aller(0)
	await _att(0.5)
	T.leave()
	await _att(0.8)


func _marcher(dir: Vector3, s: float) -> void:
	place_player_v35(_pos() + Vector3.UP * 0.1, dir)
	await _att(0.3)
	_touche(KEY_Z, true)
	_touche(KEY_W, true)
	await _att(s)
	_touche(KEY_Z, false)
	_touche(KEY_W, false)
	await _att(0.3)


func _serie() -> void:
	var T: Node = neo_v94.tours
	_ok(T != null, "les tours de Néopolis sont là")
	if T == null:
		return
	T.test_mode = true
	temps_v56.set_hour(14.0)
	var rdcs: Dictionary = {}
	for t in T.tours:
		var r: String = str(t.get("rdc", ""))
		rdcs[r] = int(rdcs.get(r, 0)) + 1
	_ok(rdcs.has("hangar") and rdcs.has("atelier") and rdcs.has("nouilles") and rdcs.has("boutique") and rdcs.has("salle_jeux"), "les rez-de-chaussée des quartiers : %s" % str(rdcs))
	# --- les rez-de-chaussée, et les étages des Arcades
	for rdc in ["hangar", "atelier", "nouilles", "boutique", "salle_jeux"]:
		var id: int = _tour(T, rdc)
		if id < 0:
			_ok(false, "une tour « %s »" % rdc)
			continue
		var nom: String = str(T.tours[id].get("enseigne", T.tours[id]["nom"]))
		var t0: Dictionary = T.tours[id]
		place_player_v35((t0["sortie"] as Vector3) + Vector3.UP * 0.3, -(t0["n"] as Vector3))
		await _att(0.8)
		var pr: String = str(donjon_v35.prompt(_pos()))
		await _entrer(T, id)
		_ok(T.inside == id and str(T.info.get("type", "")) == rdc and T._gens.size() >= 1, "%s : « %s » (%d personnes ; dehors : %s)" % [rdc, nom, T._gens.size(), pr])
		_ok(pr.contains(nom), "l'enseigne à la porte : « %s »" % pr)
		_ok(await _debout(rdc, 0.8), "on tient debout : %s" % rdc)
		if rdc == "salle_jeux":
			_ok(T._ecrans.size() >= 4, "les bornes s'animent (%d écrans)" % T._ecrans.size())
			T.aller(1)
			await _att(0.5)
			_ok(str(T.info.get("type", "")) == "karaoke" and T._ecrans.size() >= 1, "le karaoké : des cabines, %d écrans, %d chanteurs" % [T._ecrans.size(), T._gens.size()])
			_ok(await _debout("au karaoké", 0.8), "on tient debout au karaoké")
			T.aller(2)
			await _att(0.5)
			_ok(str(T.info.get("type", "")) == "capsules" and T._node.get_child_count() > 3, "l'hôtel capsule (%d personnes)" % T._gens.size())
			_ok(await _debout("à l'hôtel capsule", 0.8), "on tient debout à l'hôtel capsule")
		await _sortir(T)
		_ok(T.inside == -1, "on ressort : %s" % rdc)
	# --- une porte d'appartement qui s'ouvre
	var idl: int = -1
	for t2 in T.tours:
		if str(t2["type"]) == "logements" and str(t2.get("rdc", "")) == "hall" and (t2["etages"] as Array).size() >= 6:
			idl = int(t2["id"])
			break
	_ok(idl >= 0, "une résidence")
	if idl >= 0:
		await _entrer(T, idl)
		var ouverte: Dictionary = {}
		var ouvrables: int = 0
		for k in range(1, 6):
			T.aller(k)
			await _att(0.4)
			for it in T._its:
				if str(it["id"]).begins_with("porte153_"):
					var c: Callable = it["call"]
					if c.get_bound_arguments().size() > 1 and bool(c.get_bound_arguments()[1]):
						ouvrables += 1
						if ouverte.is_empty():
							ouverte = it
			if not ouverte.is_empty():
				break
		_ok(not ouverte.is_empty(), "des portes qui s'ouvrent (%d à cet étage)" % ouvrables)
		if not ouverte.is_empty():
			var num: int = int(str(ouverte["id"]).substr(9))
			var pos: Vector3 = ouverte["pos"]
			var g0: int = T._gens.size()
			place_player_v35(pos + Vector3.UP * 0.1, Vector3.FORWARD)
			await _att(0.4)
			(ouverte["call"] as Callable).call()
			await _att(0.8)
			var reste: bool = false
			for it2 in T._its:
				if str(it2["id"]) == str(ouverte["id"]):
					reste = true
			_ok(T._ouverte == num and not reste and T._gens.size() > g0, "« Entrez donc ! » : la porte %d s'ouvre, chez les %s (%d habitants)" % [num, T.famille(num), T._gens.size() - g0])
			# dedans
			var core: Rect2 = T.info["core"]
			var dc: Vector3 = pos - Vector3(core.get_center().x, pos.y, core.get_center().y)
			var dehors: Vector3 = Vector3(signf(dc.x), 0, 0) if absf(dc.x) * core.size.y > absf(dc.z) * core.size.x else Vector3(0, 0, signf(dc.z))
			place_player_v35(pos + dehors * 2.4 + Vector3.UP * 0.15, dehors)
			await _att(0.8)
			_ok(await _debout("dans l'appartement", 0.8), "on tient debout dans l'appartement")
			var p0: Vector3 = _pos()
			var lat: Vector3 = dehors.cross(Vector3.UP)
			await _marcher(lat, 4.0)
			var dl: float = absf((_pos() - p0).dot(lat))
			_ok(dl < 4.6 and absf(_pos().y - p0.y) < 0.6, "les murs mitoyens tiennent (%.1f m)" % dl)
			# on rebâtit l'étage : c'est toujours le même appartement
			var n1: int = T._gens.size()
			var k0: int = T.etage
			T.aller(k0 + 1 if k0 + 1 < (T.tours[idl]["etages"] as Array).size() else k0 - 1)
			await _att(0.4)
			_ok(T._ouverte == -1 and T.etage != k0, "un autre étage : les portes sont refermées")
			T.aller(k0)
			await _att(0.4)
			_ok(T._ouverte == -1 and T._gens.size() < n1, "en revenant : la porte est refermée")
		await _sortir(T)
	# --- le toit
	var idb: int = -1
	for t3 in T.tours:
		if str(t3["type"]) == "bureaux" and (idb < 0 or (t3["etages"] as Array).size() > (T.tours[idb]["etages"] as Array).size()):
			idb = int(t3["id"])
	var tb: Dictionary = T.tours[idb]
	var n: int = (tb["etages"] as Array).size()
	await _entrer(T, idb)
	T.aller(n - 1)
	await _att(0.6)
	place_player_v35((T.info["ascenseur"] as Vector3) + Vector3.UP * 0.1, T.info["regard"])
	await _att(0.4)
	T.ascenseur()
	await _att(0.4)
	var ids: Array = []
	for c2 in dialogue_v31.choices:
		ids.append(str(c2["id"]))
	_ok(ids.has("toit"), "au dernier étage, l'ascenseur monte au toit (%s)" % str(ids))
	T._choix_ascenseur("toit")
	await _att(1.0)
	var yt: float = 1.4 + float(tb["b"]["h"])
	_ok(str(T.info.get("type", "")) == "toit" and absf(_pos().y - yt) < 0.8, "sur le toit : à %.0f m (le toit est à %.0f m)" % [_pos().y, yt])
	_ok(await _debout("sur le toit", 0.8), "on tient debout sur le toit")
	var lv: bool = false
	for it3 in T._its:
		if str(it3["id"]) == "longue_vue155":
			lv = true
	_ok(lv, "la longue-vue")
	var rect: Rect2 = T.info["rect"]
	for dir in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		await _marcher(dir, 6.0)
	_ok(rect.grow(0.1).has_point(Vector2(_pos().x, _pos().z)) and absf(_pos().y - yt) < 0.8, "le parapet tient (%s)" % str(_pos()))
	T.aller(n - 1)
	await _att(0.6)
	var cs0: CollisionShape3D = (tb["b"]["cols"] as Array)[0]
	_ok(T.etage == n - 1 and str(T.info.get("type", "")) == "direction" and cs0.disabled, "on redescend : la direction, la façade ne bloque plus")
	await _sortir(T)
	# --- debout sur un toit sans y être monté (une sauvegarde faite là-haut) : le toit se bâtit
	var top: Array = tb["b"]["top"]
	var sur: Vector3 = preload("res://scripts/ile_neo_v94.gd").W((float(top[0]) + float(top[2])) * 0.5 + 1.5, (float(top[1]) + float(top[3])) * 0.5 + 1.5, yt + 0.2)
	place_player_v35(sur, Vector3.FORWARD)
	await _att(3.5)
	_ok(T.inside == idb and str(T.info.get("type", "")) == "toit", "debout sur un toit : le parapet et l'escalier sont là (%s ; dedans %d)" % [str(_pos()), T.inside])
	T.aller(n - 1)
	await _att(0.5)
	await _sortir(T)
	T.test_mode = false
	# --- l'anglais
	Langue.choisir("en", false)
	var e1: String = Langue.t("Porte 304 : « Entrez donc ! » — chez les Tanaka.")
	var e2: String = Langue.t("Tour Sora — le toit, à 160 mètres au-dessus des rues.")
	var e3: String = Langue.t("E : regarder dans la longue-vue")
	Langue.choisir("fr", false)
	_ok(e1.begins_with("Door 304") and e2.begins_with("Sora Tower — the roof") and e3 == "E: look through the telescope", "en anglais : %s · %s · %s" % [e1, e2, e3])

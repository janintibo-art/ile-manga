## Les tours de Néopolis (V153) : chaque tour a sa porte, du côté de la rue ; on entre (le hall :
## l'accueil, le vigile, le grand écran) ; les collisions de la façade se coupent, celles de l'étage
## tiennent (on ne traverse pas les murs, on ne tombe pas) ; l'ascenseur monte et descend (un étage,
## cinq, le dernier, le hall), l'escalier aussi ; chaque type d'étage se bâtit (les bureaux, la
## cafétéria, la salle des serveurs, la direction, les couloirs des logements) ; on frappe aux portes ;
## on parle aux gens ; on ressort dans la rue (les collisions reviennent) ; le filet de sécurité ;
## un étage est toujours le même ; la sauvegarde.
const NOM := "tours"
const Langue := preload("res://scripts/langue_v104.gd")


func _tour_de(type: String, min_etages: int) -> int:
	var T: Node = neo_v94.tours
	var best: int = -1
	for t in T.tours:
		if str(t["type"]) == type and (t["etages"] as Array).size() >= min_etages:
			if best < 0 or (t["etages"] as Array).size() > (T.tours[best]["etages"] as Array).size():
				best = int(t["id"])
	return best


func _serie() -> void:
	var T: Node = neo_v94.tours
	_ok(T != null and T.tours.size() > 90, "les tours de Néopolis ont leur porte (%d)" % (T.tours.size() if T != null else 0))
	if T == null:
		return
	T.test_mode = true
	var portes_rue: int = 0
	for t in T.tours:
		var s: Vector3 = t["sortie"]
		var l: Vector2 = preload("res://scripts/ile_neo_v94.gd").L(s.x, s.z)
		if T.tour_at(s + Vector3.UP * 0.5).is_empty():
			portes_rue += 1
	_ok(portes_rue == T.tours.size(), "chaque porte s'ouvre dehors, hors des tours (%d/%d)" % [portes_rue, T.tours.size()])
	var id: int = _tour_de("bureaux", 20)
	_ok(id >= 0, "une grande tour de bureaux (%s, %d étages)" % [str(T.tours[id]["nom"]) if id >= 0 else "?", (T.tours[id]["etages"] as Array).size() if id >= 0 else 0])
	if id < 0:
		return
	var t0: Dictionary = T.tours[id]
	temps_v56.set_hour(14.0)
	place_player_v35((t0["sortie"] as Vector3) + Vector3.UP * 0.3, -(t0["n"] as Vector3))
	await _att(1.5)
	var dj: Node = donjon_v35
	_ok(str(dj.prompt(_pos())).contains("entrer"), "devant la porte : « %s »" % str(dj.prompt(_pos())))
	dj.interact(_pos())
	await _att(1.0)
	_ok(T.inside == id and T.etage == 0 and T.info.get("type", "") == "hall", "on entre : le hall")
	var cs0: CollisionShape3D = (t0["b"]["cols"] as Array)[0]
	_ok(cs0.disabled, "les collisions de la façade sont coupées")
	_ok(await _debout("dans le hall", 0.8), "on tient debout dans le hall")
	_ok(T._gens.size() >= 2, "du monde dans le hall (%d)" % T._gens.size())
	# on marche vers le mur du fond : il tient
	var p0: Vector3 = _pos()
	_touche(KEY_Z, true)
	_touche(KEY_W, true)
	await _att(6.0)
	_touche(KEY_Z, false)
	_touche(KEY_W, false)
	await _att(0.3)
	var rect: Rect2 = T.info["rect"]
	_ok(rect.grow(0.2).has_point(Vector2(_pos().x, _pos().z)) and absf(_pos().y - p0.y) < 0.6, "les murs de l'étage tiennent (%s)" % str(_pos()))
	# l'ascenseur
	place_player_v35((T.info["ascenseur"] as Vector3) + Vector3.UP * 0.1, T.info["regard"])
	await _att(0.6)
	_ok(str(dj.prompt(_pos())).contains("ascenseur"), "devant l'ascenseur : « %s »" % str(dj.prompt(_pos())))
	dj.interact(_pos())
	await _att(0.4)
	var ids: Array = []
	for c in dialogue_v31.choices:
		ids.append(str(c["id"]))
	_ok(ids.has("+1") and ids.has("+5") and ids.has("max") and ids.size() <= 10, "le panneau de l'ascenseur (%s)" % str(ids))
	T._choix_ascenseur("+5")
	await _att(1.0)
	_ok(T.etage == 5 and absf(_pos().y - float((t0["etages"] as Array)[5]["y"])) < 0.6, "cinq étages plus haut (pieds à %.1f m)" % _pos().y)
	_ok(await _debout("au 5ᵉ", 0.8), "on tient debout au 5ᵉ")
	# les types d'étages
	var vus: Dictionary = {}
	var n: int = (t0["etages"] as Array).size()
	for k in range(1, n):
		var ty: String = T.type_etage(id, k)
		if vus.has(ty):
			continue
		T.aller(k)
		await _att(0.4)
		vus[ty] = T._gens.size()
		_ok(T.etage == k and T.info.get("type", "") == ty and T._node != null, "%s : l'étage %d se bâtit (%d personnes)" % [ty, k, T._gens.size()])
	_ok(vus.has("bureaux") and vus.has("cafeteria") and vus.has("direction"), "bureaux, cafétéria, direction (%s)" % str(vus.keys()))
	# un étage est toujours le même
	T.aller(1)
	await _att(0.4)
	var a1: int = T._gens.size()
	var m1: int = T._node.get_child_count()
	T.aller(2)
	await _att(0.4)
	T.aller(1)
	await _att(0.4)
	_ok(T._gens.size() == a1 and T._node.get_child_count() == m1, "un étage est toujours le même (%d personnes)" % a1)
	# parler à quelqu'un
	if not T._gens.is_empty():
		var f: Node = T._gens[0]
		place_player_v35(f.npc.global_position + Vector3(0.0, 0.1, 0.0) + (T.info["regard"] as Vector3) * 0.0, Vector3.FORWARD)
		await _att(0.3)
	# l'escalier
	T._escalier()
	await _att(0.3)
	T._choix_ascenseur("+1")
	await _att(0.8)
	_ok(T.etage == 2, "l'escalier : un étage plus haut")
	# le dernier étage, la vue
	T.aller(n - 1)
	await _att(0.5)
	_ok(T.etage == n - 1 and _pos().y > 40.0, "le dernier étage : à %.0f m au-dessus de la mer" % _pos().y)
	# redescendre, sortir
	T.aller(0)
	await _att(0.5)
	T.leave()
	await _att(1.0)
	_ok(T.inside == -1 and not cs0.disabled and T._node == null, "on ressort : les collisions de la façade reviennent")
	_ok(T.tour_at(_pos()).is_empty(), "dehors, dans la rue")
	# une tour de logements : les couloirs, les portes
	var idl: int = _tour_de("logements", 4)
	if idl >= 0:
		var tl: Dictionary = T.tours[idl]
		place_player_v35((tl["sortie"] as Vector3) + Vector3.UP * 0.3, -(tl["n"] as Vector3))
		await _att(1.0)
		T.enter(idl)
		await _att(0.6)
		T.aller(2)
		await _att(0.6)
		var portes: int = 0
		for it in T._its:
			if str(it["id"]).begins_with("porte153_"):
				portes += 1
		_ok(T.info.get("type", "") == "logements" and portes >= 4, "les logements : un couloir, %d portes" % portes)
		_ok(await _debout("dans le couloir", 0.8), "on tient debout dans le couloir")
		for it2 in T._its:
			if str(it2["id"]).begins_with("porte153_"):
				(it2["call"] as Callable).call()
				break
		T.aller(0)
		await _att(0.5)
		T.leave()
		await _att(0.8)
	# le filet de sécurité : coincé dans une tour (une vieille sauvegarde), on ressort
	var tf: Dictionary = T.tours[id]
	var r0: Array = (tf["etages"] as Array)[0]["rect"]
	var dedans: Vector3 = preload("res://scripts/ile_neo_v94.gd").W((float(r0[0]) + float(r0[2])) * 0.5, (float(r0[1]) + float(r0[3])) * 0.5, 1.6)
	place_player_v35(dedans, Vector3.FORWARD)
	await _att(1.5)
	_ok(T.tour_at(_pos()).is_empty(), "coincé dans une tour : on ressort par sa porte")
	# la sauvegarde
	var d: Dictionary = neo_v94.serialize()
	_ok((d.get("tours153", {}) as Dictionary).get("visites", []).size() >= 1, "la sauvegarde note les tours visitées")
	T.test_mode = false
	# l'anglais
	Langue.choisir("en", false)
	var e1: String = Langue.t("E : entrer — Tour Sora")
	var e2: String = Langue.t("12ᵉ étage — les bureaux de Sora Aéronefs")
	var e3: String = Langue.t("Porte 204 : Personne ne répond.")
	Langue.choisir("fr", false)
	_ok(e1 == "E: enter — Sora Tower" and e2 == "Floor 12 — the offices of Sora Aircraft" and e3 == "Door 204: No one answers.", "en anglais : %s · %s · %s" % [e1, e2, e3])

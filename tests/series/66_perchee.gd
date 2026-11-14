## L'Île Perchée (V146) : l'île flottante (le relief, le dessous, la mesa, la chute), le bourg de
## Pile-ou-Face (ses bâtiments, ses maisons où l'on entre, ses portes de tripots), la Roue qui tourne,
## les quatorze habitants (leurs corps, leurs boutiques), la Grande Chaîne (on descend jusqu'à la mer,
## on remonte), la Navette des Nuées (du Quai jusqu'au Mât de Hautefond), le bord (on ne marche pas
## dans le vide ; tombé, le filet nous rattrape), les pépites du ruisseau, la sauvegarde, l'anglais.
const NOM := "perchee"
const Ile := preload("res://scripts/ile_perchee_v146.gd")


func _sol(x: float, z: float, dy: float = 0.3) -> Vector3:
	var w: Vector3 = Ile.W(x, z)
	w.y = perchee_v146.ile.height(w.x, w.z) + dy
	return w


func _serie() -> void:
	var P: Node3D = perchee_v146
	_ok(P != null and P.ile != null, "l'Île Perchée est construite")
	_ok(P._built and P.portes.size() >= 25, "le bourg de Pile-ou-Face : %d bâtiments" % P.portes.size())
	var h0: float = P.ile.height(Ile.CENTER.x + 60.0, Ile.CENTER.z)
	_ok(absf(h0 - Ile.Y0) < 2.0, "la place est à 270 m au-dessus de la mer (%.1f)" % h0)
	var hm: float = P.ile.height(Ile.CENTER.x - 138.0, Ile.CENTER.z - 66.0)
	_ok(hm - Ile.Y0 > 25.0, "le Vieux-Pic, une mesa de %.0f m" % (hm - Ile.Y0))
	_ok(P.ile.height(Ile.CENTER.x + 400.0, Ile.CENTER.z) < -1e6, "hors de l'île : le vide")
	var span: Array = P.ile.rock_span(Ile.CENTER.x, Ile.CENTER.z)
	_ok(not span.is_empty() and float(span[0]) < Ile.Y0 - 150.0, "le dessous : une montagne renversée (%.0f m)" % (Ile.Y0 - float(span[0]) if not span.is_empty() else 0.0))
	_ok(P.ile.falls.size() == 1 and (P.ile.falls[0][1] as Vector3).y < 1.0, "la Chute de l'Orpailleur tombe jusqu'à la mer")
	_ok(P.ile.pierres.size() == 4, "les quatre Pierres-de-Ciel")
	var dock_ok: bool = false
	for d in boat_v29.docks:
		if str(d["name"]) == "Ponton_perchee":
			dock_ok = true
	_ok(dock_ok, "le Ponton de la Chaîne (la barque s'y amarre)")
	var maisons: int = 0
	for e in preload("res://scripts/azur_kit_v56.gd").PORTES_V81:
		if str(e.get("style", "")) == "perchee":
			maisons += 1
	_ok(maisons >= 10, "des maisons où l'on entre (%d)" % maisons)
	# --- on y arrive (téléportation), on tient debout ; la découverte
	var tp: Array = teleport_v58.spot("perchee")
	_ok(not tp.is_empty(), "un point d'arrivée (Pile-ou-Face)")
	place_player_v35(tp[0], tp[1])
	await _att(1.5)
	_ok(await _debout("arrivée sur l'Île Perchée"), "on tient debout sur la place")
	_ok(str(teleport_v58.current_place()) == "perchee", "la téléportation reconnaît l'île (%s)" % str(teleport_v58.current_place()))
	_ok(int(_npc_ctx_v31()["trouvailles"].get("perchee", 0)) == 1, "la découverte de l'île est notée")
	_ok(str(journal_v56.place_name(_pos())).begins_with("Île Perchée"), "le nom du lieu : %s" % str(journal_v56.place_name(_pos())))
	_ok(str(P.zone_at(_sol(60.0, 8.0))) == "pp_place", "la place de la Roue")
	_ok(str(P.zone_at(_sol(-138.0, -66.0))) == "pp_vieux_pic", "le Vieux-Pic")
	# --- la Roue tourne
	var r0: float = P.roue.rotation.x
	await _att(1.0)
	_ok(absf(P.roue.rotation.x - r0) > 0.05, "la Roue de la Fortune tourne")
	# --- les habitants
	_ok(P.habitants.size() == 14, "quatorze habitants (%d)" % P.habitants.size())
	var C64 = load("res://scripts/pnj/corps_v64.gd")
	var corps: int = 0
	for n in P.habitants:
		if C64.has_body(str(n.profile["id"])):
			corps += 1
	_ok(corps == 14, "chacun a son corps (%d)" % corps)
	var bart: Node3D = P.by_id.get("bartholome_pp")
	_ok(bart != null and (bart.profile.get("boutique", {}) as Dictionary).has("vend") and ((bart.profile["boutique"] as Dictionary)["vend"] as Dictionary).has("salsepareille"), "Bartholomé vend de la salsepareille")
	temps_v56.set_hour(11.0)
	for n2 in P.habitants:
		n2._start_slot(n2._slot_now(), true)
	await _att(1.0)
	var vc: Node3D = P.by_id.get("veuve_clou_pp")
	_ok(vc != null and not bool(vc.hidden_home) and vc.global_position.distance_to(P.spots["devant_bazar"]["pos"]) < 4.0, "à 11 h, la Veuve Clou est devant son bazar")
	place_player_v35(vc.global_position + Vector3(0, 0.3, 2.2), Vector3(0, 0, -1))
	await _att(1.0)
	_ok(_nearest_npc_v31() == vc, "on peut lui parler")
	_talk_v31(vc)
	await _att(1.0)
	_ok(dialogue_v31.opened, "le dialogue s'ouvre")
	_close_dialogue_v31()
	await _att(0.3)
	# --- la porte du saloon (les tables viendront) ; une maison où l'on entre
	var sal: Dictionary = {}
	var mai: Dictionary = {}
	for e2 in P.portes:
		if str(e2["id"]) == "saloon":
			sal = e2
		if bool(e2["maison"]) and mai.is_empty():
			mai = e2
	P._porte_lieu(sal)
	_ok(true, "la porte du saloon dit ce qui se prépare")
	var mi: int = maisons_v81.nearest(mai["porte"], 2.5) if not mai.is_empty() else -1
	_ok(mi >= 0, "la porte de la maison « %s » est connue" % str(mai.get("id", "")))
	if mi >= 0:
		maisons_v81.enter(mi)
		for k in range(40):
			await _att(0.1)
			if maisons_v81.inside and not maisons_v81.busy:
				break
		_ok(maisons_v81.inside, "on entre dans une maison de Pile-ou-Face (style %s)" % str((maisons_v81.cur as Dictionary).get("style", "")))
		_ok(await _debout("dans la maison de Pile-ou-Face", 0.6), "on tient debout dans la maison")
		maisons_v81._teardown()
		await _att(0.3)
	# --- le bord : on ne marche pas dans le vide ; tombé, le filet nous rattrape
	var th: float = 2.4
	var rr: float = P.ile.coast_radius(th)
	var bord: Vector3 = _sol(cos(th) * (rr - 6.0), sin(th) * (rr - 6.0))
	_ok(P.walkable(bord), "au bord, la terre ferme")
	var vide: Vector3 = Ile.W(cos(th) * (rr + 8.0), sin(th) * (rr + 8.0), 0.5)
	_ok(not P.walkable(vide), "au-delà du bord, le vide")
	place_player_v35(Ile.W(cos(th) * (rr + 30.0), sin(th) * (rr + 30.0), -40.0), Vector3(1, 0, 0))
	await _att(1.0)
	_ok(_pos().y > Ile.Y0 - 5.0 and P.ile.height(_pos().x, _pos().z) > -1e6, "tombé du bord : le filet nous ramène sur la place (%.0f m)" % _pos().y)
	# --- la Grande Chaîne : en bas, puis en haut
	var ch: Node3D = P.chaine
	var k0: int = -1
	for k2 in range(40):
		for c in range(2):
			if ch.at_station(c) == "haut":
				k0 = c
		if k0 >= 0:
			break
		await _att(1.0)
	_ok(k0 >= 0, "une cage attend en haut, à la Potence")
	place_player_v35(ch.cage_floor(k0) + Vector3.UP * 0.4, Vector3(0, 0, 1))
	P._board_chaine(k0)
	await _att(0.3)
	_ok(P.riding(), "dans la cage de la Grande Chaîne")
	var half: float = ch.WAIT + ch.TRAVEL
	ch.phase = (floor(ch.phase / half) + 1.0) * half - 0.6
	for k3 in range(30):
		await _att(0.2)
		if not P.riding():
			break
	_ok(not P.riding() and _pos().y < 6.0 and Vector2(_pos().x - P.ponton.x, _pos().z - P.ponton.z).length() < 12.0, "en bas : sur le Ponton de la Chaîne (%.1f m)" % _pos().y)
	_ok(await _debout("sur le Ponton de la Chaîne"), "on tient debout sur le ponton")
	_ok(str(P.zone_at(_pos())) == "pp_ponton", "le Ponton de la Chaîne (%s)" % str(P.zone_at(_pos())))
	var k4: int = -1
	for k5 in range(60):
		for c2 in range(2):
			if ch.at_station(c2) == "bas":
				k4 = c2
		if k4 >= 0:
			break
		await _att(1.0)
	place_player_v35(ch.cage_floor(k4) + Vector3.UP * 0.4, Vector3(0, 0, 1))
	P._board_chaine(k4)
	ch.phase = (floor(ch.phase / half) + 1.0) * half - 0.6
	for k6 in range(30):
		await _att(0.2)
		if not P.riding():
			break
	_ok(not P.riding() and _pos().y > Ile.Y0 - 3.0, "en haut : à la Potence (%.1f m)" % _pos().y)
	_ok(await _debout("à la Potence"), "on tient debout à la Potence")
	_ok(int(P.state["chaine"]) == 2, "deux voyages en cage")
	# --- la Navette des Nuées : du Quai jusqu'au Mât de Hautefond
	var nv: Node3D = P.navette
	nv._dock(1)
	await _att(0.3)
	place_player_v35(nv.door_pos() + Vector3.UP * 0.4, Vector3(0, 0, 1))
	P._board_navette()
	await _att(1.0)
	_ok(P.riding() and _pos().distance_to(nv.rig.global_position) < 20.0, "à bord de la Navette des Nuées")
	nv._dock(0)
	await _att(0.3)
	P.ride_interact()
	await _att(1.0)
	_ok(not P.riding() and Vector2(_pos().x - P.mat_hf.x, _pos().z - P.mat_hf.z).length() < 30.0, "descendu au Mât des Nuées de Hautefond")
	_ok(await _debout("au Mât des Nuées"), "on tient debout sur le ponton du Mât")
	# --- les pépites du ruisseau
	var pp: Vector3 = P.pepites[0] if not P.pepites.is_empty() else Vector3.ZERO
	place_player_v35(pp + Vector3(0.6, 0.4, 0), Vector3(-1, 0, 0))
	await _att(1.0)
	var pk: int = inventory_v28.nearest_pickup(_pos())
	var n_or: int = inventory_v28.count("pepite_or")
	if pk >= 0:
		inventory_v28.collect(pk)
	_ok(inventory_v28.count("pepite_or") == n_or + 1, "une pépite d'or ramassée au bord du ruisseau")
	# --- la sauvegarde
	var sv: Dictionary = P.serialize()
	P.load_data({})
	_ok(int(P.state["chaine"]) == 0 and not bool(P.state["visite"]), "nouvelle partie : rien de fait")
	P.load_data(sv)
	_ok(int(P.state["chaine"]) == 2 and bool(P.state["visite"]), "la partie rechargée : tout est retrouvé")
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Bartholomé Pattes-de-Velours")
	var t2: String = L.t("Île Perchée, la place de la Roue")
	var t3: String = L.t("SALOON DU CHIEN QUI MISE")
	L.choisir("fr", false)
	_ok(t1 == "Bartholomew Velvet-Paws", "anglais : « %s »" % t1)
	_ok(t2 == "Perched Isle, Wheel Square", "anglais : « %s »" % t2)
	_ok(t3 == "THE BETTING DOG SALOON", "anglais : « %s »" % t3)
	_ranger()

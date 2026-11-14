## L'Île des Géants (V142) : le relief et la ferme, le ponton, les cinq géants (leur taille, ils parlent
## de loin et s'agenouillent, ils marchent et le sol tremble, ils s'arrêtent si l'on est devant leurs
## pieds, ils rentrent la nuit), les nénuphars qui portent le héros, la bague de Mère Mathurine (on la
## trouve dans le potager, on la rapporte), les limaces du potager (on les chasse d'un coup), le
## cache-cache avec Pâquerette (trois fois), la sauvegarde, les textes en anglais.
const NOM := "geants"
const Ile := preload("res://scripts/ile_geants_v142.gd")


func _g(id: String) -> Node3D:
	return geants_v142.by_id.get(id)


func _w(x: float, z: float, dy: float = 0.3) -> Vector3:
	return Ile.W(x, z, geants_v142.ile.height_l(x, z) + dy)


## Parler à un géant et choisir une réplique du carnet (q56:…)
func _choisir(npc: Node3D, choix: String) -> void:
	if not dialogue_v31.opened:
		_talk_v31(npc)
		await _images(3)
	_on_dialogue_choice_v31(choix)
	await _images(3)


func _serie() -> void:
	_ok(geants_v142 != null and geants_v142.ile != null, "l'Île des Géants est construite")
	var c: Vector3 = Ile.CENTER
	_ok(absf(geants_v142.ile.height_l(Ile.PLATEAU.x, Ile.PLATEAU.y) - Ile.PLATEAU_Y) < 0.6, "le plateau de la ferme (%.1f m)" % geants_v142.ile.height_l(Ile.PLATEAU.x, Ile.PLATEAU.y))
	_ok(absf(_height_at(c.x, c.z) - Ile.PLATEAU_Y) < 1.0, "le relief compte dans le monde (%.1f m)" % _height_at(c.x, c.z))
	var dock_ok: bool = false
	for d in boat_v29.docks:
		if str(d["name"]) == "Ponton_geants":
			dock_ok = true
	_ok(dock_ok, "le ponton des petits")
	var GI = load("res://scripts/grande_ile_v59.gd")
	_ok(GI.sea_contains(c.x, c.z + 380.0, Vector2(0, 0), 10.0) and GI.sea_contains(c.x + 60.0, c.z - 400.0, Vector2(0, 0), 10.0), "la mer de l'île est navigable (elle rejoint celle de l'Île Crayonnée)")
	# --- on y arrive (téléportation), on tient debout ; la découverte
	var tp: Array = teleport_v58.spot("geants")
	_ok(not tp.is_empty(), "un point d'arrivée (le Ponton des Petits)")
	place_player_v35(tp[0], tp[1])
	await _att(1.5)
	_ok(await _debout("arrivée sur l'Île des Géants"), "on tient debout sur la grève")
	_ok(str(teleport_v58.current_place()) == "geants", "la téléportation reconnaît l'île (%s)" % str(teleport_v58.current_place()))
	_ok(int(_npc_ctx_v31()["trouvailles"].get("geants", 0)) == 1, "la découverte de l'île est notée")
	_ok(str(journal_v56.place_name(_pos())).begins_with("Île des Géants"), "le nom du lieu : %s" % str(journal_v56.place_name(_pos())))
	# --- la ferme est construite, les cinq géants y vivent
	_ok(geants_v142._built and geants_v142.habitants.size() == 5, "la ferme et ses géants (%d)" % geants_v142.habitants.size())
	temps_v56.set_hour(9.5)
	for g in geants_v142.habitants:
		g.impose = ""
		g.place_now()
	await _att(0.5)
	var m: Node3D = _g("mathurine_gt")
	var pq: Node3D = _g("paquerette_gt")
	_ok(m != null and absf(float(m.body_height()) - 13.0) < 0.6, "Mère Mathurine mesure 13 m (%.1f)" % (float(m.body_height()) if m != null else 0.0))
	_ok(pq != null and float(pq.body_height()) < 10.0 and float(pq.body_height()) > 8.0, "Pâquerette, 9 m (%.1f)" % (float(pq.body_height()) if pq != null else 0.0))
	_ok(str(m.lieu) == "potager_choux" and not bool(m.hidden_home), "à 9 h 30, Mathurine est au potager (%s)" % str(m.lieu))
	_ok(m in npcs_v31, "les géants sont des habitants (on leur parle)")
	# --- on lui parle de loin ; elle s'agenouille
	var f: Vector3 = Vector3(sin(m.rotation.y), 0, cos(m.rotation.y))
	var at: Vector3 = m.global_position + f * 7.5
	at.y = _height_at(at.x, at.z) + 0.3
	place_player_v35(at, -f)
	await _att(2.5)
	_ok(_nearest_npc_v31() == m, "à 7,5 m, c'est à elle qu'on parle")
	_talk_v31(m)
	await _att(2.0)
	_ok(dialogue_v31.opened, "le dialogue s'ouvre")
	_ok(str(m._anim_now) == "g142/genou_parle", "elle s'agenouille pour parler (%s)" % str(m._anim_now))
	_ok(float(m.face_height()) < 10.0, "son visage descend vers le tout petit (%.1f m)" % float(m.face_height()))
	_close_dialogue_v31()
	await _att(0.3)
	# --- elle marche : le sol tremble à chaque pas ; elle s'arrête si on est devant ses pieds
	place_player_v35(_w(0, -130), Vector3(0, 0, 1))
	await _att(0.5)
	var p0: int = int(geants_v142.pas_total)
	var x0: Vector3 = m.global_position
	m.impose = "cour"
	m._agenda_tick()
	await _att(5.0)
	_ok(m.global_position.distance_to(x0) > 8.0, "elle marche à grandes enjambées (%.0f m en 5 s)" % m.global_position.distance_to(x0))
	_ok(int(geants_v142.pas_total) > p0 + 2, "ses pas font trembler le sol (%d pas)" % (int(geants_v142.pas_total) - p0))
	if str(m.etat) == "marche":
		var fw: Vector3 = Vector3(sin(m.rotation.y), 0, cos(m.rotation.y))
		var dev: Vector3 = m.global_position + fw * 4.0
		dev.y = _height_at(dev.x, dev.z) + 0.3
		place_player_v35(dev, -fw)
		await _att(0.6)
		_ok(str(m.etat) == "attend", "elle s'arrête : le tout petit est devant ses pieds (%s)" % str(m.etat))
		place_player_v35(_w(0, -130), Vector3(0, 0, 1))
	var cour: Vector3 = geants_v142.stations["cour"]["pos"]
	for k in range(140):
		if str(m.etat) == "repos" and Vector2(m.global_position.x - cour.x, m.global_position.z - cour.z).length() < 3.0:
			break
		await _att(0.5)
	_ok(str(m.lieu) == "cour" and str(m.etat) == "repos" and Vector2(m.global_position.x - cour.x, m.global_position.z - cour.z).length() < 3.0,
		"elle arrive dans la cour, par la porte du potager (%s, %s)" % [str(m.lieu), str(m.etat)])
	m.impose = ""
	# --- la nuit, ils rentrent ; au matin, ils ressortent
	temps_v56.set_hour(23.0)
	for g2 in geants_v142.habitants:
		g2.place_now()
	await _att(0.5)
	var caches: int = geants_v142.habitants.filter(func(x): return bool(x.hidden_home)).size()
	_ok(caches == 5, "la nuit, les cinq géants sont à la maison (%d)" % caches)
	temps_v56.set_hour(9.5)
	for g3 in geants_v142.habitants:
		g3.place_now()
	await _att(0.5)
	_ok(not bool(m.hidden_home) and m.model.visible, "au matin, Mathurine est ressortie")
	# --- les nénuphars portent le héros ; l'eau de la mare, non
	var nen: Array = geants_v142.flore.nenuphars if geants_v142.flore != null else []
	_ok(nen.size() > 10, "des nénuphars sur la mare (%d)" % nen.size())
	if not nen.is_empty():
		var np: Vector3 = nen[0]
		_ok(geants_v142.walkable(np + Vector3.UP * 0.1), "on tient sur un nénuphar")
		var eau: Vector3 = Ile.W(Ile.MARE.x, Ile.MARE.y, Ile.MARE_Y - 0.2)
		var libre: bool = true
		for q in nen:
			if Vector2((q as Vector3).x - eau.x, (q as Vector3).z - eau.z).length() < 1.6:
				libre = false
		if libre:
			_ok(not geants_v142.walkable(eau), "on ne marche pas sur l'eau de la mare")
	# --- la bague de Mère Mathurine : on la trouve dans le potager, on la rapporte
	place_player_v35(m.global_position + Vector3(sin(m.rotation.y), 0, cos(m.rotation.y)) * 7.0 + Vector3.UP * 0.5, -Vector3(sin(m.rotation.y), 0, cos(m.rotation.y)))
	await _att(1.0)
	await _choisir(m, "q56:offre:gt_bague")
	await _choisir(m, "q56:accepte:gt_bague")
	_close_dialogue_v31()
	_ok(str(journal_v56.state("gt_bague")) == "en_cours", "quête « La bague de Mère Mathurine » acceptée")
	await _att(0.5)
	var bp: Vector3 = journal_v56.lieux["gt_bague"]
	place_player_v35(bp + Vector3(1.0, 0.3, 0.0), Vector3(-1, 0, 0))
	await _att(0.8)
	var ip: int = inventory_v28.nearest_pickup(_pos())
	_ok(ip >= 0 and str(inventory_v28.pickups[ip]["id"]) == "bague_geante", "la bague brille entre les sillons")
	if ip >= 0:
		inventory_v28.collect(ip)
	await _att(1.2)
	_ok(inventory_v28.count("bague_geante") == 1 and journal_v56.step_of("gt_bague") == 1, "la bague est dans le sac, l'étape suivante")
	place_player_v35(m.global_position + Vector3(sin(m.rotation.y), 0, cos(m.rotation.y)) * 7.0 + Vector3.UP * 0.5, -Vector3(sin(m.rotation.y), 0, cos(m.rotation.y)))
	await _att(0.8)
	await _choisir(m, "q56:etape:gt_bague")
	_close_dialogue_v31()
	await _att(0.3)
	_ok(str(journal_v56.state("gt_bague")) == "finie" and inventory_v28.count("miette_geante") >= 2, "la bague rendue : deux miettes de pain des géants")
	# --- les limaces du potager (Oncle Théophile)
	var th: Node3D = _g("theophile_gt")
	place_player_v35(th.global_position + Vector3(sin(th.rotation.y), 0, cos(th.rotation.y)) * 7.0 + Vector3.UP * 0.5, -Vector3(sin(th.rotation.y), 0, cos(th.rotation.y)))
	await _att(1.0)
	await _choisir(th, "q56:offre:gt_limaces")
	await _choisir(th, "q56:accepte:gt_limaces")
	_close_dialogue_v31()
	_ok(str(journal_v56.state("gt_limaces")) == "en_cours", "quête « Les limaces du potager » acceptée")
	place_player_v35(_w(107, -20), Vector3(-1, 0, 0))
	await _att(3.0)
	var vives: Array = geants_v142.limaces.filter(func(l): return is_instance_valid(l))
	_ok(vives.size() >= 3, "des limaces dans le potager (%d)" % vives.size())
	for tour in range(12):
		for l in geants_v142.limaces.duplicate():
			if is_instance_valid(l) and l.is_hittable():
				var lp: Vector3 = l.global_position
				place_player_v35(lp + Vector3(1.2, 0.3, 0), Vector3(-1, 0, 0))
				await _att(0.15)
				combat_v28.strike(_pos() + Vector3.UP * 0.5, Vector3(-1, 0, 0), 2.0, 1)
				await _att(0.2)
		if int(geants_v142.state["limaces"]) >= 6:
			break
		await _att(1.2)
	_ok(int(geants_v142.state["limaces"]) >= 6, "six limaces chassées (%d)" % int(geants_v142.state["limaces"]))
	await _att(1.0)
	_ok(journal_v56.step_of("gt_limaces") == 1, "l'étape suivante : retourner voir Théophile")
	place_player_v35(th.global_position + Vector3(sin(th.rotation.y), 0, cos(th.rotation.y)) * 7.0 + Vector3.UP * 0.5, -Vector3(sin(th.rotation.y), 0, cos(th.rotation.y)))
	await _att(0.8)
	await _choisir(th, "q56:etape:gt_limaces")
	_close_dialogue_v31()
	_ok(str(journal_v56.state("gt_limaces")) == "finie" and inventory_v28.count("pomme_geante") >= 2, "les limaces parties : des pommes des géants")
	# --- le cache-cache avec Pâquerette
	place_player_v35(pq.global_position + Vector3(sin(pq.rotation.y), 0, cos(pq.rotation.y)) * 6.0 + Vector3.UP * 0.5, -Vector3(sin(pq.rotation.y), 0, cos(pq.rotation.y)))
	await _att(1.0)
	await _choisir(pq, "q56:offre:gt_cache")
	await _choisir(pq, "q56:accepte:gt_cache")
	_close_dialogue_v31()
	_ok(str(journal_v56.state("gt_cache")) == "en_cours", "quête « Cache-cache avec Pâquerette » acceptée")
	for rond in range(3):
		for k in range(80):
			await _att(0.25)
			if str(geants_v142._cache_phase) == "court" and k > 8:
				pq._jump(pq.impose)
			if str(geants_v142._cache_phase) == "cachee":
				break
		_ok(str(geants_v142._cache_phase) == "cachee" and str(pq._anim_now) == "g142/cache", "tour %d : Pâquerette est cachée (%s)" % [rond + 1, str(pq.lieu)])
		var cp: Vector3 = pq.global_position + Vector3(6.0, 0, 0)
		cp.y = _height_at(cp.x, cp.z) + 0.4
		place_player_v35(cp, Vector3(-1, 0, 0))
		await _att(1.0)
		_ok(int(geants_v142.state["cache"]) == rond + 1, "tour %d : trouvée !" % (rond + 1))
		place_player_v35(_w(0, -130), Vector3(0, 0, 1))
		await _att(7.5)
	await _att(1.0)
	_ok(journal_v56.step_of("gt_cache") == 1, "trouvée trois fois : retourner voir Pâquerette")
	place_player_v35(pq.global_position + Vector3(sin(pq.rotation.y), 0, cos(pq.rotation.y)) * 6.0 + Vector3.UP * 0.5, -Vector3(sin(pq.rotation.y), 0, cos(pq.rotation.y)))
	await _att(0.8)
	await _choisir(pq, "q56:etape:gt_cache")
	_close_dialogue_v31()
	_ok(str(journal_v56.state("gt_cache")) == "finie" and inventory_v28.count("bille_geante") == 1, "Pâquerette donne Gustave, sa plus belle bille")
	# --- la sauvegarde
	var sv: Dictionary = geants_v142.serialize()
	geants_v142.load_data({})
	_ok(int(geants_v142.state["cache"]) == 0, "nouvelle partie : rien de fait")
	geants_v142.load_data(sv)
	_ok(int(geants_v142.state["cache"]) == 3 and int(geants_v142.state["limaces"]) >= 6 and bool(geants_v142.state["visite"]), "la partie rechargée : tout est retrouvé")
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Mère Mathurine")
	var t2: String = L.t("Île des Géants, le potager")
	var t3: String = L.t("Trouvée ! (2 / 3)")
	L.choisir("fr", false)
	_ok(t1 == "Mother Mathurine", "anglais : « %s »" % t1)
	_ok(t2 == "Island of Giants, the vegetable garden", "anglais : « %s »" % t2)
	_ok(t3 == "Found her! (2 / 3)", "anglais : « %s »" % t3)
	_ranger()

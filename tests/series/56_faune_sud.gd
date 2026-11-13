## La faune des îles des villes (V139) : l'Île du Boucan, Néopolis, Sombreval et la Cité des Nuées.
## Les naissances de jour et de nuit (la cane sur l'étang du Parc des Brumes) ; les rats qui
## s'égaillent puis se tapissent ; le chat errant qui vient se frotter au héros immobile, le suit,
## crache et file si on le frappe (sans une égratignure) ; le chat noir qui coupe la route au héros
## qui marche ; les pigeons qui s'envolent tous ensemble puis se reposent plus loin ; la cane qui
## s'approche du héros tranquille au bord de l'étang, les canetons à la file, et toute la famille qui
## file de l'autre côté s'il s'agite ; les textes en anglais.
const NOM := "faune_sud"


func _h(x: float, z: float) -> float:
	return float(faune_v132.hauteur(x, z))


func _pres(kind: String, d: float, haut: float = 0.1, cote: float = 0.0) -> Node3D:
	var p: Vector3 = _pos()
	var dir: Vector3 = hero_v28.facing
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	var lat := Vector3(-dir.z, 0, dir.x)
	var q: Vector3 = p + dir * d + lat * cote
	q.y = _h(q.x, q.z)
	for k in range(16):
		if absf(q.y - p.y) < 1.2 and q.y > 0.3 and not testeur_v78._sous_toit(q, q.y):
			break
		var a: float = TAU * float(k) / 16.0
		q = p + Vector3(cos(a), 0, sin(a)) * d
		q.y = _h(q.x, q.z)
	q.y += haut
	return faune_v132.spawn(kind, q)


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()


func _apparitions(F: Node, n: int) -> void:
	F.enabled = true
	F.spawned.clear()
	for k in range(n):
		F._tick = 0.0
		F._cool.clear()
		await _att(0.1)


func _noms(table: Array) -> Array:
	var out: Array = []
	for e in table:
		out.append(str(e[0]))
	return out


func _suivre(b: Node3D, n: int, stop: Callable = Callable()) -> Dictionary:
	var st: Dictionary = {}
	for k in range(n):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if not is_instance_valid(b):
			break
		st[str(b.state)] = true
		if stop.is_valid() and bool(stop.call()):
			break
	return st


func _naissances(F: Node, ile: String, quoi: String) -> void:
	_vider()
	await _apparitions(F, 14)
	var ok_kinds: Array = _noms(F.table_de(ile))
	_ok(not F.spawned.is_empty(), "%s : des bêtes naissent %s" % [quoi, str(F.spawned)])
	for k in F.spawned:
		_ok(str(k) in ok_kinds, "%s : « %s » est à sa place" % [quoi, str(k)])
	F._tick = 9999.0
	_vider()


func _aller(F: Node, ile: String) -> void:
	testeur_v78._faune_v132(ile)
	# (la faune ne regarde plus où est le héros : on lui dit sur quelle île il est, pour son relief)
	F.ile_joueur = ile
	await _att(0.5)
	F._tick = 9999.0
	_vider()


func _poser_ici(q: Vector3, face: Vector3 = Vector3.FORWARD) -> void:
	place_player_v35(Vector3(q.x, _h(q.x, q.z) + 0.3, q.z), face)
	await _images(3)


## Le héros marche droit devant lui (à « v » m/s) pendant « duree » secondes, ou jusqu'à « stop ».
func _marcher(dir: Vector3, v: float, duree: float, stop: Callable = Callable()) -> void:
	var t: float = 0.0
	var p: Vector3 = _pos()
	while t < duree:
		var t0: int = Time.get_ticks_msec()
		await _images(1)
		var dt: float = maxf(float(Time.get_ticks_msec() - t0) / 1000.0, 0.001)
		t += dt
		p += dir * v * dt
		place_player_v35(Vector3(p.x, _h(p.x, p.z) + 0.3, p.z), dir)
		hero_v28.hp = hero_v28.HP_MAX
		if stop.is_valid() and bool(stop.call()):
			break


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["boucan", "neo", "sombreval", "nuees"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée (rayon %.0f m)" % [id, float(F.iles.get(id, {}).get("r", 0.0))])
	var et: Array = F.etang_de("nuees")
	_ok(et.size() == 2 and float(et[1]) > 6.0, "la Cité des Nuées : l'étang du Parc des Brumes est repéré %s" % str(et))
	# --- naissances, de jour puis de nuit
	temps_v56.set_hour(12.0)
	for ile in ["boucan", "neo", "sombreval", "nuees"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		_ok(F.ile_de(_pos()) == ile, "testeur : un coin tranquille sur l'île « %s »" % ile)
		await _naissances(F, ile, "%s, de jour" % ile)
	temps_v56.set_hour(22.5)
	await _images(2)
	for ile in ["boucan", "neo", "sombreval", "nuees"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		await _naissances(F, ile, "%s, la nuit" % ile)
	temps_v56.set_hour(12.0)
	await _images(2)
	testeur_v78.invincible = false
	# ================================================== l'Île du Boucan
	await _aller(F, "boucan")
	# le chat errant : le héros reste tranquille, il vient se frotter à ses jambes en ronronnant
	var ch: Node3D = _pres("chat_errant", 3.5)
	var sch: Dictionary = await _suivre(ch, 300, func() -> bool: return str(ch.state) == "caline")
	_ok(sch.has("approche") and int(ch.calins) >= 1, "chat errant : immobile, le chat vient se frotter au héros %s" % str(sch.keys()))
	_ok(ch.global_position.distance_to(_pos()) < 1.4, "chat errant : il tourne autour de ses jambes (%.1f m)" % ch.global_position.distance_to(_pos()))
	# le héros s'en va (sur un sol à la même hauteur, à ciel ouvert) : le chat le suit un moment
	var dir_c: Vector3 = hero_v28.facing
	dir_c.y = 0.0
	dir_c = dir_c.normalized()
	var p_c: Vector3 = _pos()
	var loin: Vector3 = p_c - dir_c * 6.0
	for k in range(16):
		var a: float = TAU * float(k) / 16.0
		var q: Vector3 = p_c + Vector3(cos(a), 0, sin(a)) * 6.0
		var hq: float = _h(q.x, q.z)
		if absf(hq - _h(p_c.x, p_c.z)) < 0.8 and not testeur_v78._sous_toit(q, hq):
			loin = q
			break
	await _poser_ici(loin, (loin - p_c).normalized())
	var a_plat := func() -> float:
		return Vector2(ch.global_position.x - _pos().x, ch.global_position.z - _pos().z).length()
	var sch2: Dictionary = await _suivre(ch, 250, func() -> bool: return str(ch.state) == "suit" and float(a_plat.call()) < 3.0)
	_ok(sch2.has("suit") and float(a_plat.call()) < 3.0, "chat errant : puis il suit le héros (%.1f m) %s" % [float(a_plat.call()), str(sch2.keys())])
	# un coup : il crache et s'enfuit ; on ne peut pas lui faire de mal
	var pv0: int = int(ch.hp)
	ch.take_hit(5, _pos())
	var sch3: Dictionary = await _suivre(ch, 120, func() -> bool: return int(ch.fuites) >= 1)
	_ok(sch3.has("crache") and sch3.has("fuit") and int(ch.fuites) >= 1, "chat errant : frappé, il crache et s'enfuit %s" % str(sch3.keys()))
	_ok(int(ch.hp) == pv0 and str(ch.state) != "mort", "chat errant : sans une égratignure (%d pv)" % int(ch.hp))
	_vider()
	# les rats : le héros approche, ils s'égaillent, puis se tapissent
	var ra: Node3D = _pres("rat", 9.0)
	await _att(0.5)
	_ok(str(ra.state) == "fouille", "rats : ils fouillent la friche (%s)" % str(ra.state))
	var vr: Vector3 = ra.global_position - _pos()
	vr.y = 0.0
	await _poser_ici(ra.global_position - vr.normalized() * 3.0, vr.normalized())
	var sra: Dictionary = await _suivre(ra, 200, func() -> bool: return str(ra.state) == "tapis")
	_ok(sra.has("fuite") and sra.has("tapis") and int(ra.fuites) >= 1, "rats : ils s'égaillent, puis se tapissent %s" % str(sra.keys()))
	_vider()
	# ================================================== Néopolis
	await _aller(F, "neo")
	# les pigeons : on passe trop près, ils s'envolent tous ensemble, tournent, se reposent plus loin
	var pg: Node3D = _pres("pigeon", 10.0)
	await _att(0.6)
	_ok(str(pg.state) == "picore", "pigeons : ils picorent sur la place (%s)" % str(pg.state))
	var vp: Vector3 = pg.global_position - _pos()
	vp.y = 0.0
	await _poser_ici(pg.global_position - vp.normalized() * 2.5, vp.normalized())
	var p_envol: Vector3 = _pos()
	var spg: Dictionary = await _suivre(pg, 500, func() -> bool: return int(pg.envolees) >= 1 and str(pg.state) == "picore")
	_ok(spg.has("vol") and spg.has("pose") and int(pg.envolees) >= 1, "pigeons : ils s'envolent tous ensemble, puis se reposent %s" % str(spg.keys()))
	var dpg: float = Vector2(pg.global_position.x - p_envol.x, pg.global_position.z - p_envol.z).length()
	_ok(str(pg.state) == "picore" and dpg > 7.0, "pigeons : posés plus loin (%.1f m)" % dpg)
	_ok(absf(pg.global_position.y - _h(pg.global_position.x, pg.global_position.z)) < 1.5, "pigeons : bien posés au sol")
	_vider()
	# ================================================== Sombreval
	await _aller(F, "sombreval")
	# le chat noir : le héros marche, le chat lui coupe la route
	var cn: Node3D = _pres("chat_noir", 7.0, 0.1, 5.0)
	cn._croise_cd = 0.0
	await _att(0.3)
	var dir_s: Vector3 = hero_v28.facing
	dir_s.y = 0.0
	dir_s = dir_s.normalized()
	var vus_n: Dictionary = {}
	var croise_vu := func() -> bool:
		vus_n[str(cn.state)] = true
		return int(cn.croisements) >= 1
	await _marcher(dir_s, 2.0, 8.0, croise_vu)
	_ok(vus_n.has("croise") and int(cn.croisements) >= 1, "chat noir : il coupe la route au héros qui marche %s" % str(vus_n.keys()))
	_ok(float(cn._croise_cd) > 30.0, "chat noir : et pas sans arrêt")
	_vider()
	# ================================================== la Cité des Nuées
	await _aller(F, "nuees")
	if _ok(not et.is_empty(), "la Cité des Nuées : l'étang"):
		var c0: Vector3 = et[0]
		var r0: float = float(et[1])
		var ca: Node3D = F.spawn("canard", c0)
		await _att(0.5)
		_ok(absf(ca.global_position.y - c0.y) < 0.05, "cane : elle flotte sur l'étang (%.2f / %.2f)" % [ca.global_position.y, c0.y])
		var hero_c: float = Vector2(_pos().x - c0.x, _pos().z - c0.z).length()
		_ok(hero_c < r0 + 8.0, "le héros est au bord de l'étang (%.1f m du centre)" % hero_c)
		# le héros reste tranquille au bord : la cane s'approche en cancanant
		var d0: float = ca.global_position.distance_to(_pos())
		var sca: Dictionary = await _suivre(ca, 500, func() -> bool: return str(ca.state) == "approche" and ca.global_position.distance_to(_pos()) < d0 - 2.0)
		_ok(sca.has("approche") and int(ca.approches) >= 1, "cane : le héros est tranquille, elle s'approche %s" % str(sca.keys()))
		_ok(ca.global_position.distance_to(_pos()) < d0 - 2.0, "cane : elle vient vers le bord (%.1f → %.1f m)" % [d0, ca.global_position.distance_to(_pos())])
		var dc: float = Vector2(ca.global_position.x - c0.x, ca.global_position.z - c0.z).length()
		_ok(dc < r0, "cane : elle reste sur l'eau (%.1f m du centre)" % dc)
		# les canetons à la file derrière leur mère
		var file_ok: bool = true
		for i in range(1, ca._bande.size()):
			var dk: float = (ca._bande[i][0] as Node3D).global_position.distance_to(ca.global_position)
			if dk < 0.1 or dk > 1.6:
				file_ok = false
		_ok(ca._bande.size() == 5 and file_ok, "canetons : quatre, à la file derrière leur mère")
		# le héros s'agite : toute la famille file de l'autre côté de l'étang
		var vh: Vector3 = Vector3(_pos().x - c0.x, 0, _pos().z - c0.z).normalized()
		var tang := Vector3(-vh.z, 0, vh.x)
		await _marcher(tang, 4.0, 1.5, func() -> bool: return int(ca.fuites) >= 1)
		_ok(int(ca.fuites) >= 1 and str(ca.state) == "eloigne", "cane : le héros s'agite, elle file (%s)" % str(ca.state))
		var d1: float = ca.global_position.distance_to(_pos())
		await _suivre(ca, 150)
		_ok(ca.global_position.distance_to(_pos()) > d1 + 2.0, "cane : de l'autre côté de l'étang (%.1f → %.1f m)" % [d1, ca.global_position.distance_to(_pos())])
		_vider()
	# --- le filet anti-chute de la Cité des Nuées : il rattrape les vraies chutes, pas les voyages
	var NI: Node = hautefond_v112.nuees_ile
	var y0: float = float(NI.Y0)
	var nc := Vector3(NI.CENTER.x, 0.0, NI.CENTER.z)
	# un bord sans rien dessous (pas le Belvédère de Verre, pas une passerelle)
	var dir_b := Vector3.ZERO
	var r_b: float = 0.0
	for k in range(16):
		var ang: float = TAU * float(k) / 16.0
		var dk := Vector3(cos(ang), 0, sin(ang))
		var rb: float = 0.0
		for i in range(20, 170):
			var qb: Vector3 = nc + dk * float(i)
			if not (float(NI.height(qb.x, qb.z)) > -1e6):
				rb = float(i)
				break
		if rb <= 0.0:
			continue
		var qd: Vector3 = nc + dk * (rb + 3.0)
		var ray := PhysicsRayQueryParameters3D.create(Vector3(qd.x, y0 + 6.0, qd.z), Vector3(qd.x, y0 - 40.0, qd.z))
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			dir_b = dk
			r_b = rb
			break
	if _ok(r_b > 0.0, "Cité des Nuées : un bord donnant sur le vide"):
		# on marche jusqu'au bord, on l'enjambe… et on tombe : le filet nous rattrape
		var pm: Vector3 = nc + dir_b * (r_b - 6.0)
		pm.y = float(NI.height(pm.x, pm.z)) + 0.4
		place_player_v35(pm, dir_b)
		await _att(0.5)
		for k in range(300):
			await _images(1)
			pm += dir_b * 0.06
			var hh: float = float(NI.height(pm.x, pm.z))
			if hh > -1e6:
				pm.y = hh + 0.4
			place_player_v35(pm, dir_b)
			if Vector2(pm.x - nc.x, pm.z - nc.z).length() > r_b + 2.0:
				break
		var y_min: float = _pos().y
		var repris: bool = false
		for k in range(400):
			await _att(0.03)
			hero_v28.hp = hero_v28.HP_MAX
			y_min = minf(y_min, _pos().y)
			if y_min < y0 - 15.0 and _pos().y > y0 - 8.0:
				repris = true
				break
		_ok(repris, "Cité des Nuées : on tombe, le filet nous rattrape et nous remonte (tombé jusqu'à %.0f m, puis %.0f m)" % [y_min, _pos().y])
		# un voyage (déposé d'un coup tout en bas, sur l'île de Hautefond, sous la Cité) n'est pas une chute
		await _att(0.5)
		var sous: Vector3 = nc + Vector3(12.0, 0, 12.0)
		sous.y = float(F.hauteur(sous.x, sous.z, "hautefond")) + 0.4
		place_player_v35(sous, Vector3.FORWARD)
		await _att(2.0)
		_ok(_pos().y < y0 - 60.0, "Cité des Nuées : déposé en bas par un voyage, on y reste (%.0f m)" % _pos().y)
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Un chat noir te coupe la route…")
	L.choisir("fr", false)
	_ok(t1 == "A black cat crosses your path…", "anglais : « %s »" % t1)

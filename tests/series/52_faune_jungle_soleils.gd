## La faune de l'île de la jungle et de l'Île des Trois Soleils (V135) : les naissances par île, par
## région, de jour et de nuit ; le singe qui lance des fruits, le mille-pattes, l'araignée qui bondit,
## les lucioles paisibles, le crocodile tapi sous l'eau, le scarabée qui roule, la meute de chacals,
## le coati chapardeur, le jaguar qui rôde puis bondit, l'aigle qui pique, l'axolotl qui file.
const NOM := "faune_jungle_soleils"


func _pres(kind: String, d: float) -> Node3D:
	# le sol monte et descend : on cherche autour du héros un endroit à sa hauteur
	var p: Vector3 = _pos()
	var q: Vector3 = p + hero_v28.facing * d
	q.y = _height_at(q.x, q.z)
	for k in range(16):
		if absf(q.y - p.y) < 1.2 and q.y > 0.3:
			break
		var a: float = TAU * float(k) / 16.0
		q = p + Vector3(cos(a), 0, sin(a)) * d
		q.y = _height_at(q.x, q.z)
	q.y += {"luciole": 1.3, "aigle_royal": 9.0}.get(kind, 0.1)
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


## Observe une bête : les états par lesquels elle passe ; le héros ne meurt pas (on le soigne).
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


func _naissances(F: Node, ile: String, region: String, quoi: String) -> void:
	_vider()
	await _apparitions(F, 14)
	var ok_kinds: Array = _noms(F.table_de(ile, region))
	_ok(not F.spawned.is_empty(), "%s : des bêtes naissent %s" % [quoi, str(F.spawned)])
	for k in F.spawned:
		_ok(str(k) in ok_kinds, "%s : « %s » est à sa place" % [quoi, str(k)])
	F._tick = 9999.0
	_vider()


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["jungle", "soleils"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée" % id)
	# --- les trois régions des Trois Soleils
	var vues: Dictionary = {}
	var c: Vector3 = F.iles["soleils"]["c"]
	var r: float = float(F.iles["soleils"]["r"])
	for i in range(400):
		var a: float = randf() * TAU
		var d: float = randf_range(0.1, 0.9) * r
		vues[F.region_de("soleils", Vector3(c.x + cos(a) * d, 0, c.z + sin(a) * d))] = true
	for reg in ["egypte", "maya", "azteque"]:
		_ok(vues.has(reg), "Trois Soleils : la région « %s » existe" % reg)
	# --- naissances, de jour puis de nuit
	temps_v56.set_hour(12.0)
	testeur_v78._faune_v132("jungle")
	await _att(0.5)
	_ok(F.ile_de(_pos()) == "jungle", "testeur : un coin sauvage dans la jungle")
	await _naissances(F, "jungle", "", "jungle, de jour")
	for reg in ["egypte", "maya", "azteque"]:
		testeur_v78._faune_v132("soleils", reg)
		await _att(0.5)
		_ok(F.region_de("soleils", _pos()) == reg, "testeur : un coin sauvage côté « %s »" % reg)
		await _naissances(F, "soleils", reg, "Trois Soleils, côté %s, de jour" % reg)
	temps_v56.set_hour(22.5)
	await _images(2)
	testeur_v78._faune_v132("jungle")
	await _att(0.4)
	await _naissances(F, "jungle", "", "jungle, la nuit")
	testeur_v78._faune_v132("soleils", "maya")
	await _att(0.4)
	await _naissances(F, "soleils", "maya", "côté maya, la nuit")
	temps_v56.set_hour(12.0)
	await _images(2)
	# --- l'île de la jungle : le singe lance des fruits, le mille-pattes pince, l'araignée bondit
	testeur_v78._faune_v132("jungle")
	await _att(0.4)
	F._tick = 9999.0
	_vider()
	testeur_v78.invincible = false
	var sg: Node3D = _pres("singe_hurleur", 7.5)
	var fruit_vu: bool = false
	for k in range(160):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		for s in F._spits:
			if str(s.get("sorte", "")) == "fruit":
				fruit_vu = true
		if is_instance_valid(sg) and int(sg.throws) >= 1 and fruit_vu:
			break
	_ok(is_instance_valid(sg) and int(sg.throws) >= 1 and fruit_vu, "singe hurleur : il lance un fruit")
	# il reprend son souffle après le lancer, puis file si le héros est trop près
	var fuit: bool = false
	for k in range(40):
		if is_instance_valid(sg):
			var q: Vector3 = _pos() + hero_v28.facing * 2.0
			q.y = _height_at(q.x, q.z) + 0.1
			sg.global_position = q
			sg.home = q
		await _att(0.1)
		if is_instance_valid(sg) and str(sg.state) == "fuite":
			fuit = true
			break
	_ok(fuit, "singe hurleur : de trop près, il file (%s)" % (str(sg.state) if is_instance_valid(sg) else "-"))
	_vider()
	# (dans la jungle, un tronc peut se trouver entre eux : on le pose tout près)
	var mp: Node3D = _pres("mille_pattes", 2.6)
	var stm: Dictionary = await _suivre(mp, 150)
	_ok(stm.has("armer") and stm.has("frappe"), "mille-pattes : il fonce et pince %s" % str(stm.keys()))
	_vider()
	var ar: Node3D = _pres("araignee_geante", 5.0)
	await _suivre(ar, 150, func() -> bool: return int(ar.jumps) >= 1)
	_ok(is_instance_valid(ar) and int(ar.jumps) >= 1, "araignée géante : elle bondit")
	_vider()
	# les lucioles : paisibles ; frappées, elles s'éparpillent
	var lu: Node3D = _pres("luciole", 2.0)
	await _att(0.5)
	_ok(bool(lu.peaceful) and not F.hostile_zone(_pos()), "lucioles : paisibles (pas de cœurs de menace)")
	var xp0: int = int(progression_v63.xp)
	lu.take_hit(1, _pos())
	await _att(1.2)
	_ok(not is_instance_valid(lu), "lucioles : frappées, elles s'éparpillent et s'éteignent")
	_ok(int(progression_v63.xp) >= xp0, "lucioles : pas d'expérience perdue")
	_vider()
	# --- côté égyptien : le crocodile tapi dans le fleuve
	testeur_v78._faune_v132("soleils", "egypte")
	await _att(0.4)
	F._tick = 9999.0
	_vider()
	var eau: Vector3 = testeur_v78._milieu_pres(F, _pos(), "fleuve", 40.0)
	if _ok(eau != Vector3.INF, "le fleuve est près du coin sauvage égyptien"):
		# le héros d'abord loin de l'eau : le crocodile reste tapi
		var cr: Node3D = F.spawn("crocodile", Vector3(eau.x, _height_at(eau.x, eau.z) + 0.1, eau.z))
		var away: Vector3 = (_pos() - eau)
		away.y = 0.0
		away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
		var loin: Vector3 = eau + away * 12.0
		await _poser(Vector3(loin.x, _height_at(loin.x, loin.z) + 0.3, loin.z))
		await _att(0.6)
		_ok(str(cr.state) == "cache" and float(cr._sink) > 0.5, "crocodile : tapi sous l'eau tant qu'on est loin (%s)" % str(cr.state))
		# le héros longe la rive : il jaillit et mord
		var rive: Vector3 = eau + away * 2.8
		await _poser(Vector3(rive.x, maxf(_height_at(rive.x, rive.z), -0.3) + 0.3, rive.z), -away)
		var stc: Dictionary = await _suivre(cr, 200, func() -> bool: return int(cr.landed_hits) >= 1)
		_ok(stc.has("surgit") or stc.has("chasse"), "crocodile : il jaillit quand on longe la rive %s" % str(stc.keys()))
		_ok(int(cr.landed_hits) >= 1, "crocodile : il mord")
		# le héros s'en va : il retourne se cacher
		var far: Vector3 = eau + away * 40.0
		await _poser(Vector3(far.x, _height_at(far.x, far.z) + 0.3, far.z))
		var cache_vu: bool = false
		for k in range(120):
			await _att(0.1)
			if is_instance_valid(cr) and str(cr.state) == "cache":
				cache_vu = true
				break
		_ok(cache_vu, "crocodile : il retourne se cacher sous l'eau (%s)" % (str(cr.state) if is_instance_valid(cr) else "-"))
	_vider()
	testeur_v78._faune_v132("soleils", "egypte")
	await _att(0.4)
	F._tick = 9999.0
	_vider()
	# le scarabée roule sa boule sur le héros
	var sc: Node3D = _pres("scarabee_geant", 6.0)
	var vers: Vector3 = _pos() - sc.global_position
	vers.y = 0.0
	sc.facing = vers.normalized()
	await _suivre(sc, 260, func() -> bool: return int(sc.landed_hits) >= 1)
	_ok(is_instance_valid(sc) and int(sc.landed_hits) >= 1, "scarabée géant : sa boule roule sur le héros")
	_vider()
	# la meute de chacals : un seul bondit à la fois
	var ch: Array = []
	for i in range(3):
		ch.append(_pres("chacal", 8.0 + i))
	var max_att: int = 0
	for k in range(160):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		var n: int = 0
		for w in ch:
			if is_instance_valid(w) and str(w.state) in ["armer", "frappe"]:
				n += 1
		max_att = maxi(max_att, n)
	_ok(max_att == 1, "chacals : au plus %d à l'attaque en même temps (il en faut un, pas plus)" % max_att)
	_vider()
	# --- côté maya : le coati chapardeur
	testeur_v78._faune_v132("soleils", "maya")
	await _att(0.4)
	F._tick = 9999.0
	_vider()
	inventory_v28.add("pomme", 2)
	var pommes0: int = inventory_v28.count("pomme")
	F._chap_cd = 0.0
	var co: Node3D = _pres("coati", 6.0)
	var vols0: int = F.vols
	await _suivre(co, 260, func() -> bool: return F.vols > vols0)
	var pommes1: int = inventory_v28.count("pomme")
	_ok(F.vols == vols0 + 1 and str(co.butin) != "", "coati : il chipe à manger (« %s »)" % str(co.butin))
	var rendus0: int = F.rendus
	co.take_hit(3, _pos())
	await _att(0.2)
	_ok(F.rendus == rendus0 + 1 and inventory_v28.count("pomme") >= pommes1 + (1 if pommes1 < pommes0 else 0), "coati : frappé, il lâche ce qu'il a pris")
	_ok(is_instance_valid(co) and str(co.state) == "fuite", "coati : on ne lui fait pas de mal, il file (%s)" % (str(co.state) if is_instance_valid(co) else "-"))
	_vider()
	# le jaguar, la nuit : il rôde, se tasse, bondit
	temps_v56.set_hour(22.5)
	await _images(2)
	var jg: Node3D = _pres("jaguar_sauvage", 11.0)
	# (sur les collines, une bosse ou un tronc peut couper un bond : on lui en laisse trois)
	var stj: Dictionary = await _suivre(jg, 750, func() -> bool: return int(jg.landed_hits) >= 1 or (int(jg.pounces) >= 3 and str(jg.state) == "souffle"))
	_ok(stj.has("rode"), "jaguar : il rôde autour du héros %s" % str(stj.keys()))
	_ok(stj.has("armer") and int(jg.pounces) >= 1, "jaguar : il se tasse, puis bondit")
	_ok(int(jg.landed_hits) >= 1, "jaguar : son bond porte")
	temps_v56.set_hour(12.0)
	_vider()
	# --- côté aztèque : l'aigle pique, l'axolotl file
	testeur_v78._faune_v132("soleils", "azteque")
	await _att(0.4)
	F._tick = 9999.0
	_vider()
	var ai: Node3D = _pres("aigle_royal", 6.0)
	var sta: Dictionary = await _suivre(ai, 420, func() -> bool: return int(ai.landed_hits) >= 1)
	_ok(sta.has("chasse") and sta.has("pique"), "aigle royal : il tourne, puis pique %s" % str(sta.keys()))
	_ok(int(ai.landed_hits) >= 1, "aigle royal : ses serres portent")
	_vider()
	var ax: Node3D = _pres("axolotl", 2.5)
	await _att(0.6)
	_ok(bool(ax.peaceful) and str(ax.state) == "fuite", "axolotl : paisible, il file quand on approche (%s)" % str(ax.state))
	_vider()
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Le coati lâche %s !" % "une pomme")
	var t2: String = L.t(str(ai.ALERTES135["crocodile"]) if is_instance_valid(ai) else "Un crocodile ! Il guette sous l'eau, on ne voit que ses yeux : quand tu longes le fleuve, regarde l'eau. S'il ouvre la gueule, recule vite, puis frappe-le. Il ne s'éloigne pas de l'eau.")
	L.choisir("fr", false)
	_ok(t1.begins_with("The coati drops"), "anglais : « %s »" % t1)
	_ok(t2.begins_with("A crocodile!"), "anglais : « %s »" % t2.left(30))

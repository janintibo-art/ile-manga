## La faune sauvage (V132) : île du village paisible, Bois-Doré, Montagne de Feu ; sanglier, ronceux,
## meute de loups, salamandre, mouette chapardeuse, crabe ; butin et expérience ; textes anglais.
const NOM := "faune_iles"


func _pres(kind: String, d: float) -> Node3D:
	# sur la montagne, le sol monte et descend : on cherche autour du héros un endroit à sa hauteur
	# (une bête qui voit le héros trois mètres au-dessus d'elle ne l'attaque pas)
	var p: Vector3 = _pos()
	var q: Vector3 = p + hero_v28.facing * d
	q.y = _height_at(q.x, q.z)
	for k in range(16):
		if absf(q.y - p.y) < 1.2:
			break
		var a: float = TAU * float(k) / 16.0
		q = p + Vector3(cos(a), 0, sin(a)) * d
		q.y = _height_at(q.x, q.z)
	q.y += 2.5 if kind == "chauve_souris_mont" else (12.0 if kind == "mouette" else 0.1)
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


func _serie() -> void:
	var F: Node = faune_v132
	if not _ok(F != null, "la faune existe"):
		return
	_ok(not F.enabled, "la faune dort tant que la partie n'est pas lancée par l'écran")
	F._resolve_iles()
	for id in ["village", "elfes", "nains"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée" % id)
	# --- le Bois-Doré : le coin sauvage du testeur, les bêtes autour
	testeur_v78._faune_v132("elfes")
	await _att(1.0)
	_ok(F.ile_de(_pos()) == "elfes" and int(F.spawned.get("sanglier", 0)) >= 1, "Bois-Doré : île « %s », bêtes %s" % [F.ile_de(_pos()), str(F.spawned)])
	_vider()
	await _images(1)
	# le sanglier gratte le sol… et charge
	var sg: Node3D = _pres("sanglier", 8.0)
	var states: Dictionary = {}
	testeur_v78.invincible = false
	for k in range(120):
		await _att(0.03)
		if is_instance_valid(sg):
			states[str(sg.state)] = true
	testeur_v78.invincible = true
	_ok(states.has("armer") and states.has("charge"), "sanglier : il arme puis charge %s" % str(states.keys()))
	hero_v28.hp = hero_v28.HP_MAX
	var pieces0: int = inventory_v28.count("piece")
	for k in range(12):
		if is_instance_valid(sg) and sg.state != "mort":
			sg.take_hit(3, _pos())
	await _att(0.3)
	_ok(inventory_v28.count("piece") > pieces0, "sanglier vaincu : du butin (%d -> %d pièces)" % [pieces0, inventory_v28.count("piece")])
	_vider()
	# le ronceux dort dans les fourrés et se lève quand on passe
	var rc: Node3D = _pres("ronceux_sauvage", 6.0)
	await _att(0.3)
	var st0: String = str(rc.state)
	rc.global_position = _pos() + hero_v28.facing * 2.5
	await _att(0.8)
	_ok(st0 == "cache" and str(rc.state) != "cache", "ronceux : %s puis %s" % [st0, str(rc.state)])
	_vider()
	# la meute : un seul loup bondit à la fois
	var loups: Array = []
	for i in range(3):
		loups.append(_pres("loup_bois", 9.0 + i))
	var max_att: int = 0
	for k in range(150):
		await _att(0.03)
		var n: int = 0
		for w in loups:
			if is_instance_valid(w) and str(w.state) in ["armer", "frappe"]:
				n += 1
		max_att = maxi(max_att, n)
	_ok(max_att == 1, "meute : au plus %d loup à l'attaque en même temps (il en faut un, pas plus)" % max_att)
	_vider()
	# --- la Montagne de Feu : la salamandre crache, la faune naît toute seule
	testeur_v78._faune_v132("nains")
	await _att(0.5)
	_vider()
	var sa: Node3D = _pres("salamandre", 8.0)
	var spat: bool = false
	for k in range(120):
		await _att(0.03)
		if not F._spits.is_empty():
			spat = true
	_ok(spat, "salamandre : elle crache (état %s)" % (str(sa.state) if is_instance_valid(sa) else "-"))
	_vider()
	await _apparitions(F, 14)
	_ok(not F.spawned.is_empty(), "Montagne de Feu : des bêtes naissent %s" % str(F.spawned))
	for k2 in F.spawned:
		_ok(str(k2) in ["salamandre", "bouc", "chauve_souris_mont"], "Montagne de Feu : « %s » est à sa place" % str(k2))
	# --- loin de tout : les bêtes s'en vont
	pc_body.global_position = Vector3(0, 60, -900)
	F._tick = 0.0
	await _att(0.3)
	_ok(F.betes.is_empty(), "loin de tout : %d bête(s)" % F.betes.size())
	# --- l'île du village : paisible (crabes et mouettes seulement)
	testeur_v78._faune_v132("village")
	await _att(0.5)
	_vider()
	await _apparitions(F, 14)
	for k3 in F.spawned:
		_ok(str(k3) in ["crabe_plage", "mouette"], "île du village paisible : « %s »" % str(k3))
	# la mouette chapardeuse : elle chipe une pomme, la lâche si on la frappe
	_vider()
	inventory_v28.add("pomme", 1)
	var g: Node3D = _pres("mouette", 4.0)
	await _images(1)
	F._steal_cd = 0.0
	var vols0: int = F.vols
	var rendus0: int = F.rendus
	F.mouette_vole(g)
	var food: String = str(g.butin)
	g.take_hit(2, _pos())
	_ok(food != "" and F.vols == vols0 + 1 and F.rendus == rendus0 + 1, "mouette : chipe « %s », frappée elle le rend" % food)
	_ok(is_instance_valid(g) and g.state != "mort", "mouette : on ne peut pas la tuer")
	# le crabe file quand on approche
	var cr: Node3D = _pres("crabe_plage", 3.0)
	await _att(0.5)
	_ok(str(cr.state) == "fuite", "crabe : il file (%s)" % str(cr.state))
	_vider()
	F.enabled = false
	# --- les textes en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("La mouette lâche %s !" % "une pomme")
	L.choisir("fr", false)
	_ok(t1.begins_with("The gull drops"), "anglais : « %s »" % t1)

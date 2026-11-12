## La faune de la grande île (par région), de l'Île Al Dente et de l'Île Crayonnée (V133) :
## les cinq caractères (colosse, sauteur, rouleur, fouet, kamikaze) et les taches au sol.
const NOM := "faune_grande"


func _pres(kind: String, d: float) -> Node3D:
	# le sol monte et descend : on cherche autour du héros un endroit à sa hauteur
	# (une bête qui voit le héros plusieurs mètres au-dessus d'elle ne l'attaque pas)
	var p: Vector3 = _pos()
	var q: Vector3 = p + hero_v28.facing * d
	q.y = _height_at(q.x, q.z)
	for k in range(16):
		if absf(q.y - p.y) < 1.2:
			break
		var a: float = TAU * float(k) / 16.0
		q = p + Vector3(cos(a), 0, sin(a)) * d
		q.y = _height_at(q.x, q.z)
	q.y += 2.8 if kind == "feu_follet" else 0.1
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


## Observe une bête un moment : les états par lesquels elle passe.
func _etats(b: Node3D, n: int) -> Dictionary:
	var st: Dictionary = {}
	for k in range(n):
		await _att(0.03)
		if is_instance_valid(b):
			st[str(b.state)] = true
	return st


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["grande", "aldente", "crayon"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée" % id)
	# --- les quatre régions de la grande île
	var vues: Dictionary = {}
	var c: Vector3 = F.iles["grande"]["c"]
	var r: float = float(F.iles["grande"]["r"])
	for i in range(500):
		var a: float = randf() * TAU
		var d: float = randf_range(0.1, 0.9) * r
		vues[F.region_de("grande", Vector3(c.x + cos(a) * d, 0, c.z + sin(a) * d))] = true
	for reg in ["ouest", "nord", "est", "sud"]:
		_ok(vues.has(reg), "grande île : la région « %s » existe %s" % [reg, str(vues.keys())])
	# --- chaque région a ses bêtes, de jour, et la nuit
	temps_v56.set_hour(12.0)
	for reg in ["ouest", "nord", "est", "sud"]:
		_vider()
		testeur_v78._faune_v132("grande", reg)
		await _att(0.5)
		_ok(F.region_de("grande", _pos()) == reg, "testeur : un coin sauvage dans la région « %s »" % reg)
		_vider()
		await _apparitions(F, 14)
		var ok_kinds: Array = _noms(F.table_de("grande", reg))
		_ok(not F.spawned.is_empty(), "région « %s », de jour : des bêtes naissent %s" % [reg, str(F.spawned)])
		for k in F.spawned:
			_ok(str(k) in ok_kinds, "région « %s », de jour : « %s » est à sa place" % [reg, str(k)])
	temps_v56.set_hour(22.5)
	await _images(2)
	_ok(F.night(), "la nuit tombe")
	testeur_v78._faune_v132("grande", "ouest")
	await _att(0.4)
	_vider()
	await _apparitions(F, 14)
	var nuit_ouest: Array = _noms(F.table_de("grande", "ouest"))
	_ok(nuit_ouest.has("loup_plaine"), "la nuit, des loups des plaines dans les prairies")
	for k in F.spawned:
		_ok(str(k) in nuit_ouest, "prairies, la nuit : « %s » est à sa place" % str(k))
	temps_v56.set_hour(12.0)
	_vider()
	F._tick = 9999.0   # plus de naissances pendant les essais (la faune reste éveillée)
	# --- le scorpion arme son dard puis frappe ; le serpent caché jaillit
	testeur_v78._faune_v132("grande", "sud")
	await _att(0.4)
	_vider()
	var sc: Node3D = _pres("scorpion_dunes", 5.0)
	var st: Dictionary = await _etats(sc, 120)
	_ok(st.has("armer") and st.has("frappe"), "scorpion : il arme puis frappe %s" % str(st.keys()))
	_vider()
	var sp: Node3D = _pres("serpent_sable", 7.0)
	await _att(0.3)
	var s0: String = str(sp.state)
	sp.global_position = _pos() + hero_v28.facing * 2.0
	await _att(0.8)
	_ok(s0 == "cache" and str(sp.state) != "cache", "serpent : %s puis %s" % [s0, str(sp.state)])
	_vider()
	# --- l'ours se dresse, s'abat ; un coup ne l'arrête pas
	testeur_v78._faune_v132("grande", "nord")
	await _att(0.4)
	_vider()
	testeur_v78.invincible = false
	var ours: Node3D = _pres("ours_lande", 3.0)
	var rear: float = 0.0
	var frappe_malgre_coup: bool = false
	var touche: bool = false
	for k in range(160):
		await _att(0.03)
		if not is_instance_valid(ours):
			break
		rear = maxf(rear, float(ours._rear))
		if str(ours.state) == "armer" and not touche:
			ours.take_hit(1, _pos())
			touche = true
		if touche and str(ours.state) == "frappe":
			frappe_malgre_coup = true
		hero_v28.hp = hero_v28.HP_MAX
	testeur_v78.invincible = true
	_ok(rear >= 0.5, "ours : il se dresse (%.2f)" % rear)
	_ok(frappe_malgre_coup, "ours : un coup ne l'arrête pas")
	_ok(is_instance_valid(ours) and int(ours.landed_hits) >= 1, "ours : ses griffes portent")
	_vider()
	# --- le crapaud bondit ; le feu follet danse puis pique
	testeur_v78._faune_v132("grande", "est")
	await _att(0.4)
	_vider()
	var cr: Node3D = _pres("crapaud_vase", 5.0)
	await _etats(cr, 100)
	_ok(is_instance_valid(cr) and int(cr.jumps) >= 1, "crapaud : il bondit")
	_vider()
	var ff: Node3D = _pres("feu_follet", 6.0)
	var stf: Dictionary = await _etats(ff, 200)
	_ok(stf.has("chasse") and stf.has("pique"), "feu follet : il danse puis pique %s" % str(stf.keys()))
	_vider()
	# --- l'Île Al Dente : les bêtes naissent ; la boulette roule et se coupe en deux
	testeur_v78._faune_v132("aldente")
	await _att(0.4)
	_vider()
	await _apparitions(F, 14)
	var t_al: Array = _noms(F.table_de("aldente"))
	_ok(not F.spawned.is_empty(), "Al Dente : des bêtes naissent %s" % str(F.spawned))
	for k in F.spawned:
		_ok(str(k) in t_al, "Al Dente : « %s » est à sa place" % str(k))
	F._tick = 9999.0   # plus de naissances pendant les essais (la faune reste éveillée)
	_vider()
	testeur_v78.invincible = false
	var bo: Node3D = _pres("boulette", 5.0)
	var vers: Vector3 = _pos() - bo.global_position
	vers.y = 0.0
	bo.facing = vers.normalized()
	var stb: Dictionary = {}
	for k in range(260):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if is_instance_valid(bo):
			stb[str(bo.state)] = true
			if int(bo.landed_hits) >= 1:
				break
	testeur_v78.invincible = true
	_ok(is_instance_valid(bo) and int(bo.landed_hits) >= 1, "boulette : elle roule sur le héros %s" % str(stb.keys()))
	var minis0: int = int(F.spawned.get("boulette_mini", 0))
	for k in range(10):
		if is_instance_valid(bo) and bo.state != "mort":
			bo.take_hit(4, _pos())
	await _att(0.4)
	_ok(int(F.spawned.get("boulette_mini", 0)) - minis0 == 2, "boulette coupée en deux : deux petites boulettes")
	_vider()
	# le spaghetti fouette de loin
	testeur_v78.invincible = false
	var spa: Node3D = _pres("spaghetti_sauvage", 2.2)
	var stp: Dictionary = {}
	for k in range(150):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if is_instance_valid(spa):
			stp[str(spa.state)] = true
			if int(spa.landed_hits) >= 1:
				break
	testeur_v78.invincible = true
	_ok(is_instance_valid(spa) and int(spa.landed_hits) >= 1, "spaghetti : son fouet porte %s" % str(stp.keys()))
	_vider()
	# la tomate gonfle et éclate : de la sauce, ni butin ni expérience
	var xp0: int = int(progression_v63.xp)
	var sauce0: int = int(F.taches.get("sauce", 0))
	var to: Node3D = _pres("tomate_kamikaze", 3.0)
	for k in range(150):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if not is_instance_valid(to) or str(to.state) == "mort":
			break
	await _att(0.3)
	_ok(int(F.taches.get("sauce", 0)) > sauce0, "tomate : elle éclate en tache de sauce")
	_ok(int(progression_v63.xp) == xp0, "tomate éclatée : pas d'expérience (%d -> %d)" % [xp0, int(progression_v63.xp)])
	_vider()
	# --- l'Île Crayonnée : les bêtes naissent ; la tache d'encre et la gomme marquent le sol
	testeur_v78._faune_v132("crayon")
	await _att(0.4)
	_vider()
	await _apparitions(F, 14)
	var t_cr: Array = _noms(F.table_de("crayon"))
	_ok(not F.spawned.is_empty(), "Crayonnée : des bêtes naissent %s" % str(F.spawned))
	for k in F.spawned:
		_ok(str(k) in t_cr, "Crayonnée : « %s » est à sa place" % str(k))
	F._tick = 9999.0   # plus de naissances pendant les essais (la faune reste éveillée)
	_vider()
	var encre0: int = int(F.taches.get("encre", 0))
	var te: Node3D = _pres("tache_encre", 4.5)
	for k in range(150):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if int(F.taches.get("encre", 0)) > encre0:
			break
	_ok(is_instance_valid(te) and int(te.jumps) >= 1, "tache d'encre : elle bondit")
	_ok(int(F.taches.get("encre", 0)) > encre0, "tache d'encre : elle marque le sol")
	_vider()
	var gomme0: int = int(F.taches.get("gomme", 0))
	var go: Node3D = _pres("gomme_geante", 3.0)
	for k in range(200):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		if int(F.taches.get("gomme", 0)) > gomme0:
			break
	_ok(int(F.taches.get("gomme", 0)) > gomme0, "gomme géante : elle s'abat et efface le sol")
	_vider()
	# les gribouillis : un seul bondit à la fois
	var gr: Array = []
	for i in range(3):
		gr.append(_pres("gribouillis", 7.0 + i))
	var max_att: int = 0
	for k in range(150):
		await _att(0.03)
		var n: int = 0
		for w in gr:
			if is_instance_valid(w) and str(w.state) in ["armer", "frappe"]:
				n += 1
		max_att = maxi(max_att, n)
	_ok(max_att == 1, "gribouillis : au plus %d à l'attaque en même temps (il en faut un, pas plus)" % max_att)
	_vider()
	# --- les taches s'effacent
	F.decal(_pos() + hero_v28.facing * 2.0, "encre", 1.0, 0.6)
	F.decal(_pos() + hero_v28.facing * 3.0, "sauce", 1.0, 0.6)
	var n0: int = F._decals.size()
	await _att(1.2)
	_ok(F._decals.size() <= n0 - 2, "les taches s'effacent (%d -> %d)" % [n0, F._decals.size()])
	_vider()
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Un aurochs ! Quand il baisse ses grandes cornes et gratte le sol, il va charger : écarte-toi au dernier moment, puis frappe-le pendant qu'il souffle.")
	L.choisir("fr", false)
	_ok(t1.begins_with("An aurochs!"), "anglais : « %s »" % t1.left(40))

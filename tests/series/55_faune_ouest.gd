## La faune d'Arcanelle, de l'Île de Braise et de Hautefond (V138) : les naissances de jour et de nuit
## (jamais sur la lave) ; le corbeau qui vole des pièces et les lâche si on le frappe, l'hermine
## curieuse, l'iguane marin qui éternue puis s'écarte, les vautours qui descendent quand le héros
## est mal en point, les phalènes attirées par sa lumière, les molosses qui harcèlent (un seul
## fonce à la fois), le macareux qui s'envole puis revient, le troupeau de moutons, l'effraie qui
## plonge dans l'herbe ; les textes en anglais.
const NOM := "faune_ouest"


func _h(x: float, z: float) -> float:
	return float(faune_v132.hauteur(x, z))


func _pres(kind: String, d: float, haut: float = 0.1) -> Node3D:
	var p: Vector3 = _pos()
	var q: Vector3 = p + hero_v28.facing * d
	q.y = _h(q.x, q.z)
	for k in range(16):
		if absf(q.y - p.y) < 1.2 and q.y > 0.3 and not faune_v132.lave(q):
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
	var sur_lave: int = 0
	for b in F.betes:
		if is_instance_valid(b) and not bool(b.vol) and F.lave((b as Node3D).global_position, ile):
			sur_lave += 1
	_ok(sur_lave == 0, "%s : aucune bête sur la lave" % quoi)
	for k in F.spawned:
		_ok(str(k) in ok_kinds, "%s : « %s » est à sa place" % [quoi, str(k)])
	F._tick = 9999.0
	_vider()


func _aller(F: Node, ile: String) -> void:
	testeur_v78._faune_v132(ile)
	await _att(0.5)
	F._tick = 9999.0
	_vider()


func _poser_ici(q: Vector3, face: Vector3 = Vector3.FORWARD) -> void:
	place_player_v35(Vector3(q.x, maxf(_h(q.x, q.z), 0.0) + 0.3, q.z), face)
	await _images(3)


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["arcanelle", "braise", "hautefond"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée (rayon %.0f m)" % [id, float(F.iles.get(id, {}).get("r", 0.0))])
	var cb: Vector3 = F.iles["braise"]["c"]
	var cratere := Vector3(cb.x - 170.0, 0.0, cb.z + 170.0)
	_ok(F.lave(cratere, "braise") and not F.lave(Vector3(cb.x - 170.0, 0.0, cb.z + 250.0), "braise"), "Braise : la lave du cratère est repérée")
	# --- naissances, de jour puis de nuit
	temps_v56.set_hour(12.0)
	for ile in ["arcanelle", "braise", "hautefond"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		_ok(F.ile_de(_pos()) == ile, "testeur : un coin sauvage sur l'île « %s »" % ile)
		await _naissances(F, ile, "%s, de jour" % ile)
	temps_v56.set_hour(22.5)
	await _images(2)
	for ile in ["arcanelle", "braise", "hautefond"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		await _naissances(F, ile, "%s, la nuit" % ile)
	temps_v56.set_hour(12.0)
	await _images(2)
	testeur_v78.invincible = false
	# ================================================== Arcanelle
	await _aller(F, "arcanelle")
	# le corbeau : il se pose, sautille jusqu'au héros, lui vole des pièces ; frappé, il les lâche
	inventory_v28.add("piece", 30)
	F._corbeau_cd = 0.0
	var pieces0: int = inventory_v28.count("piece")
	var co: Node3D = _pres("corbeau", 8.0, 6.0)
	co._cd136 = 0.0
	var vols0: int = F.vols
	var sco: Dictionary = await _suivre(co, 400, func() -> bool: return F.vols > vols0)
	_ok(sco.has("descend") and sco.has("sautille"), "corbeau : il se pose et sautille jusqu'au héros %s" % str(sco.keys()))
	_ok(F.vols == vols0 + 1 and int(co.butin_n) > 0 and inventory_v28.count("piece") < pieces0, "corbeau : il vole des pièces (%d)" % int(co.butin_n))
	var rendus0: int = F.rendus
	co.take_hit(1, _pos())
	await _att(0.2)
	_ok(F.rendus == rendus0 + 1 and inventory_v28.count("piece") == pieces0, "corbeau : frappé, il lâche les pièces (%d / %d)" % [inventory_v28.count("piece"), pieces0])
	_vider()
	# l'hermine : elle suit le héros à distance, se dresse pour le regarder ; trop près, elle file
	var he: Node3D = _pres("hermine", 8.0)
	var she: Dictionary = await _suivre(he, 200, func() -> bool: return str(he.state) == "guette")
	var dh: float = he.global_position.distance_to(_pos())
	_ok(she.has("suit") and she.has("guette") and dh > 3.5 and dh < 7.5, "hermine : curieuse, elle s'approche et se dresse à %.1f m %s" % [dh, str(she.keys())])
	var vh: Vector3 = he.global_position - _pos()
	vh.y = 0.0
	await _poser_ici(he.global_position - vh.normalized() * 1.8, vh.normalized())
	await _suivre(he, 60, func() -> bool: return int(he.fuites) >= 1)
	_ok(int(he.fuites) >= 1, "hermine : trop près, elle file")
	_vider()
	# ================================================== l'Île de Braise
	await _aller(F, "braise")
	# l'iguane marin, sur la côte : on approche, il hoche la tête, éternue, puis s'écarte
	var cote: Vector3 = testeur_v78._milieu_pres(F, _pos(), "cote", 360.0)
	if _ok(cote != Vector3.INF, "Braise : la côte près du coin sauvage"):
		var ig: Node3D = F.spawn("iguane_marin", Vector3(cote.x, _h(cote.x, cote.z) + 0.1, cote.z))
		var dir_i: Vector3 = Vector3(1, 0, 0)
		await _poser_ici(cote - dir_i * 7.0, dir_i)
		await _att(0.6)
		_ok(str(ig.state) == "bain", "iguane marin : il se chauffe au soleil (%s)" % str(ig.state))
		await _poser_ici(ig.global_position - dir_i * 2.4, dir_i)
		var sig: Dictionary = await _suivre(ig, 200, func() -> bool: return str(ig.state) == "s_en_va")
		_ok(sig.has("menace") and int(ig.eternuements) >= 1, "iguane marin : il hoche la tête et éternue %s" % str(sig.keys()))
		var d1: float = ig.global_position.distance_to(_pos())
		await _suivre(ig, 80)
		_ok(str(ig.state) == "s_en_va" or ig.global_position.distance_to(_pos()) > d1, "iguane marin : puis il s'écarte")
		_vider()
	# les vautours : le héros est mal en point, ils descendent tourner au-dessus de lui ; l'un se pose
	await _aller(F, "braise")
	var vs: Array = []
	for i in range(3):
		var v: Node3D = _pres("vautour_fauve", 10.0 + float(i) * 3.0, 25.0)
		v._flank = 0.5 if i == 0 else -0.6
		vs.append(v)
	testeur_v78.invincible = true
	hero_v28.hp = 3
	var bas: bool = false
	var pose: bool = false
	for k in range(500):
		await _att(0.03)
		hero_v28.hp = 3
		for v in vs:
			if is_instance_valid(v):
				bas = bas or str(v.state) == "tourne_bas"
				pose = pose or str(v.state) == "pose"
		if pose:
			break
	_ok(bas, "vautours : le héros est mal en point, ils descendent tourner au-dessus de lui")
	_ok(pose, "vautours : l'un d'eux se pose, et attend")
	hero_v28.hp = hero_v28.HP_MAX
	var partis: bool = false
	for k in range(120):
		await _att(0.03)
		var n: int = 0
		for v in vs:
			if is_instance_valid(v) and str(v.state) in ["vol", "fuite_air"]:
				n += 1
		if n == vs.size():
			partis = true
			break
	_ok(partis, "vautours : le héros va mieux, ils repartent")
	testeur_v78.invincible = false
	_vider()
	# la nuit : les phalènes tournent autour de sa lumière ; les molosses harcèlent
	temps_v56.set_hour(22.5)
	await _images(2)
	var ph: Node3D = _pres("phalene_braise", 4.5, 1.2)
	await _suivre(ph, 120, func() -> bool: return str(ph.state) == "lumiere" and ph.global_position.distance_to(_pos() + Vector3.UP * 1.6) < 1.5)
	_ok(str(ph.state) == "lumiere" and ph.global_position.distance_to(_pos() + Vector3.UP * 1.6) < 1.5, "phalènes : elles tournent autour de la lumière du héros")
	_vider()
	var mo: Array = [_pres("molosse_cendre", 9.0), _pres("molosse_cendre", 10.0)]
	var max_f: int = 0
	var vus: Dictionary = {}
	for k in range(800):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		var n2: int = 0
		for m in mo:
			if is_instance_valid(m):
				vus[str(m.state)] = true
				if str(m.state) == "fonce":
					n2 += 1
		max_f = maxi(max_f, n2)
		if int(mo[0].landed_hits) + int(mo[1].landed_hits) >= 2:
			break
	_ok(vus.has("garde") and vus.has("fonce") and vus.has("repli"), "molosses : ils aboient à distance, foncent, repartent %s" % str(vus.keys()))
	_ok(int(mo[0].landed_hits) + int(mo[1].landed_hits) >= 1, "molosses : leurs morsures portent")
	_ok(max_f == 1, "molosses : un seul fonce à la fois (%d)" % max_f)
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# ================================================== Hautefond
	await _aller(F, "hautefond")
	# le macareux : sur la côte ; on approche, il s'envole au-dessus de la mer ; on part, il revient
	var cote2: Vector3 = testeur_v78._milieu_pres(F, _pos(), "cote", 150.0)
	if _ok(cote2 != Vector3.INF, "Hautefond : la côte près du coin sauvage"):
		var mc: Node3D = F.spawn("macareux", Vector3(cote2.x, _h(cote2.x, cote2.z) + 0.1, cote2.z))
		var mer: Vector3 = Vector3.ZERO
		for k in range(8):
			var a: float = TAU * float(k) / 8.0
			if _h(cote2.x + cos(a) * 9.0, cote2.z + sin(a) * 9.0) < -0.6:
				mer = Vector3(cos(a), 0, sin(a))
				break
		await _poser_ici(cote2 - mer * 12.0, mer)
		await _att(0.5)
		_ok(str(mc.state) == "pose" and not bool(mc._vole), "macareux : posé sur la côte (%s)" % str(mc.state))
		await _poser_ici(cote2 - mer * 2.5, mer)
		await _suivre(mc, 60, func() -> bool: return bool(mc._vole))
		_ok(bool(mc._vole), "macareux : on approche, il s'envole")
		await _poser_ici(cote2 - mer * 30.0, mer)
		var revenu: bool = false
		for k in range(600):
			await _att(0.03)
			if is_instance_valid(mc) and not bool(mc._vole) and str(mc.state) == "pose":
				revenu = true
				break
		_ok(revenu, "macareux : on s'éloigne, il revient se poser")
		_vider()
	await _aller(F, "hautefond")
	# les moutons : on s'approche, tout le troupeau s'enfuit
	var mts: Array = []
	for i in range(3):
		mts.append(_pres("mouton", 11.0 + float(i) * 1.5))
	await _att(0.5)
	var m0: Node3D = mts[0]
	var vm: Vector3 = m0.global_position - _pos()
	vm.y = 0.0
	await _poser_ici(m0.global_position - vm.normalized() * 3.5, vm.normalized())
	var galop: int = 0
	var vus_m: Array = [{}, {}, {}]
	for k in range(200):
		await _att(0.03)
		galop = 0
		for i in range(mts.size()):
			var m: Node3D = mts[i]
			if is_instance_valid(m):
				vus_m[i][str(m.state)] = true
				if str(m.state) == "galop":
					galop += 1
		if galop == mts.size():
			break
	_ok(galop == mts.size(), "moutons : tout le troupeau s'enfuit (%d / %d) %s %s %s %.1f m" % [galop, mts.size(), str(vus_m[0].keys()), str(vus_m[1].keys()), str(vus_m[2].keys()), m0.global_position.distance_to(_pos())])
	_vider()
	# l'effraie, la nuit : elle survole le pré, fait du sur-place, et plonge dans l'herbe
	temps_v56.set_hour(22.5)
	await _images(2)
	var ef: Node3D = _pres("effraie", 18.0, 3.0)
	ef._cd136 = 1.0
	var sef: Dictionary = await _suivre(ef, 400, func() -> bool: return int(ef.plongeons) >= 1)
	_ok(sef.has("sur_place") and int(ef.plongeons) >= 1, "effraie : sur-place, puis elle plonge dans l'herbe %s" % str(sef.keys()))
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var Bete = load("res://scripts/monstre_v138.gd")
	var t1: String = L.t("Le corbeau lâche tes %d pièces !" % 3)
	var t2: String = L.t(str(Bete.ALERTES138["molosse_cendre"]))
	L.choisir("fr", false)
	_ok(t1 == "The raven drops your 3 coins!", "anglais : « %s »" % t1)
	_ok(t2.begins_with("Ash hounds!"), "anglais : « %s »" % t2.left(30))

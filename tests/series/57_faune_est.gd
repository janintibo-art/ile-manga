## La faune de l'Île de Montjoie, de Port-Azur et de l'Île Pixelithique (V140) : les îles, leurs régions
## (la ferme, le lac, le bois…), la lave de l'Île Pixelithique ; les naissances de jour et de nuit ;
## la basse-cour (les poules s'égaillent, le coq vous chasse d'un coup de bec, et chante à l'aube),
## le héron qui pêche puis s'envole vers une autre rive, la cane sur un lac en ellipse, l'écureuil
## qui grimpe à un tronc puis redescend, le lézard qui file dans une fente, la tortue d'Hermann qui
## rentre dans sa carapace, les guêpiers qui suivent le héros dans le maquis ; en petits cubes, les
## compsognathes (ils suivent le héros, lui chipent à manger, dorment la nuit), l'archéoptéryx qui
## plane d'un arbre à l'autre, la meganeura qui vient voir le héros de tout près ; les textes en
## anglais.
const NOM := "faune_est"


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
		if absf(q.y - p.y) < 1.2 and q.y > 0.3 and not testeur_v78._sous_toit(q, q.y) and not faune_v132.lave(q):
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


func _naissances(F: Node, ile: String, region: String, quoi: String) -> void:
	_vider()
	await _apparitions(F, 14)
	var ok_kinds: Array = _noms(F.table_de(ile, region))
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


func _aller(F: Node, ile: String, region: String = "") -> void:
	testeur_v78._faune_v132(ile, region)
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


func _plat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["montjoie", "azur", "pixel"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée (rayon %.0f m)" % [id, float(F.iles.get(id, {}).get("r", 0.0))])
	var etm: Array = F.etang_de("montjoie")
	_ok(etm.size() == 3, "Montjoie : le Lac des Grenouilles, une ellipse %s" % str(etm))
	var etp: Array = F.etang_de("pixel")
	_ok(etp.size() == 2, "Île Pixelithique : le Lac des Long-Cous %s" % str(etp))
	# les régions de Montjoie et de Port-Azur
	var IM = load("res://scripts/ile_montjoie_v71.gd")
	var mc: Vector3 = IM.CENTER
	var pts := {"ferme": IM.FARM, "lac": IM.LAKE, "bois": IM.FOREST, "port": IM.HARBOR, "ville": IM.TOWN}
	for rg in pts:
		var lp: Vector2 = pts[rg]
		_ok(F.region_de("montjoie", Vector3(mc.x + lp.x, 0, mc.z + lp.y)) == rg, "Montjoie : la région « %s »" % rg)
	var IA = load("res://scripts/ile_azur_v56.gd")
	_ok(F.region_de("azur", IA.to_world(IA.HEADLAND.x, IA.HEADLAND.y)) == "pointe", "Port-Azur : la pointe du phare")
	_ok(F.region_de("azur", IA.to_world(0.0, 40.0)) == "ville", "Port-Azur : la ville")
	# la lave du cratère de l'Île Pixelithique
	var IP = load("res://scripts/ile_pixel_v90.gd")
	var lave_vue: bool = false
	for k in range(24):
		var a: float = TAU * float(k) / 24.0
		for rr in [0.0, 4.0, 8.0]:
			var vq: Vector3 = IP.W(float(IP.VOLCAN[0]) + cos(a) * rr, float(IP.VOLCAN[1]) + sin(a) * rr)
			if F.lave(vq, "pixel"):
				lave_vue = true
	_ok(lave_vue and not F.lave(IP.W(float(IP.LAC[0]), float(IP.LAC[1])), "pixel"), "Île Pixelithique : la lave du cratère est repérée")
	# (la cane suit la rive d'un lac en ellipse)
	var ca0: Node3D = F.spawn("canard", etm[0])
	_ok(absf(float(ca0._r_canard(etm, Vector3(0, 0, 1))) - (float(etm[2]) - 2.5)) < 0.01 and absf(float(ca0._r_canard(etm, Vector3(1, 0, 0))) - (float(etm[1]) - 2.5)) < 0.01,
		"cane : sur le Lac des Grenouilles, elle nage le long de la rive (une ellipse)")
	_vider()
	# --- naissances, de jour puis de nuit
	var lieux: Array = [["montjoie", "ferme"], ["montjoie", "lac"], ["montjoie", "bois"], ["azur", "collines"], ["pixel", ""]]
	temps_v56.set_hour(12.0)
	for L in lieux:
		testeur_v78._faune_v132(str(L[0]), str(L[1]))
		await _att(0.5)
		_ok(F.ile_de(_pos()) == str(L[0]) and F.region_de(str(L[0]), _pos()) == str(L[1]), "testeur : un coin sauvage, %s %s" % [str(L[0]), str(L[1])])
		await _naissances(F, str(L[0]), str(L[1]), "%s %s, de jour" % [str(L[0]), str(L[1])])
	temps_v56.set_hour(22.5)
	await _images(2)
	for L in lieux:
		testeur_v78._faune_v132(str(L[0]), str(L[1]))
		await _att(0.5)
		await _naissances(F, str(L[0]), str(L[1]), "%s %s, la nuit" % [str(L[0]), str(L[1])])
	temps_v56.set_hour(12.0)
	await _images(2)
	testeur_v78.invincible = false
	# ================================================== Montjoie : la ferme
	await _aller(F, "montjoie", "ferme")
	var bc: Node3D = _pres("poule", 8.0)
	await _att(0.6)
	_ok(str(bc.state) == "picore", "poules : elles picorent (%s)" % str(bc.state))
	var vb: Vector3 = bc.global_position - _pos()
	vb.y = 0.0
	vb = vb.normalized()
	await _poser_ici(bc.global_position - vb * 1.8, vb)
	var sbc: Dictionary = await _suivre(bc, 120, func() -> bool: return int(bc.fuites) >= 1)
	_ok(sbc.has("affole") and int(bc.fuites) >= 1, "poules : on court vers elles, elles s'égaillent en caquetant")
	await _suivre(bc, 200, func() -> bool: return str(bc.state) == "picore")
	# on s'attarde près d'elles : le coq fonce et vous chasse d'un coup de bec (sans vous blesser)
	var vb2: Vector3 = bc.global_position - _pos()
	vb2.y = 0.0
	vb2 = vb2.normalized() if vb2.length() > 0.05 else vb
	await _poser_ici(bc.global_position - vb2 * 3.8, vb2)
	bc._coq_cd = 0.0
	var hp0: int = int(hero_v28.hp)
	var vus_coq: Dictionary = {}
	for k in range(400):
		await _att(0.03)
		vus_coq[str(bc.state)] = true
		if int(bc.coups_de_bec) >= 1:
			break
	_ok(vus_coq.has("coq_fonce") and int(bc.coups_de_bec) >= 1, "coq : on s'attarde, il fonce et vous chasse d'un coup de bec %s" % str(vus_coq.keys()))
	_ok(int(hero_v28.hp) == hp0, "coq : son coup de bec ne blesse pas (%d / %d)" % [int(hero_v28.hp), hp0])
	# à l'aube, il chante
	await _poser_ici(bc.global_position - vb2 * 12.0, vb2)
	temps_v56.set_hour(6.2)
	await _images(2)
	await _suivre(bc, 200, func() -> bool: return str(bc.state) == "picore")
	bc._chant_t = 0.0
	await _suivre(bc, 150, func() -> bool: return int(bc.chants) >= 1)
	_ok(int(bc.chants) >= 1, "coq : à l'aube, il chante")
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# ================================================== Montjoie : le lac
	await _aller(F, "montjoie", "lac")
	var c0: Vector3 = etm[0]
	var dh: Vector3 = Vector3(_pos().x - c0.x, 0, _pos().z - c0.z).normalized().rotated(Vector3.UP, 0.6)
	var qh: Vector3 = c0 + dh * (float(F.rayon_etang(etm, dh)) - 1.2)
	qh.y = _h(qh.x, qh.z) + 0.05
	var he: Node3D = F.spawn("heron", qh)
	he.timer = 0.3
	var she: Dictionary = await _suivre(he, 150, func() -> bool: return str(he.state) == "frappe")
	_ok(she.has("frappe"), "héron : immobile dans l'eau, il pêche d'un coup de bec %s" % str(she.keys()))
	var lq0: float = float(IM.lake_q(he.global_position.x - mc.x, he.global_position.z - mc.z))
	_ok(lq0 > 0.85 and lq0 < 1.05 and he.global_position.y < float(IM.LAKE_Y), "héron : dans l'eau peu profonde, au bord du lac (%.2f)" % lq0)
	var dehors: Vector3 = Vector3(qh.x - c0.x, 0, qh.z - c0.z).normalized()
	await _poser_ici(qh + dehors * 9.0, -dehors)
	var p_vol: Vector3 = _pos()
	var shf: Dictionary = await _suivre(he, 1000, func() -> bool: return int(he.envols) >= 1 and str(he.state) == "guette")
	_ok(shf.has("envol") and shf.has("vol") and int(he.envols) >= 1, "héron : on approche, il s'envole en croassant %s" % str(shf.keys()))
	_ok(str(he.state) == "guette" and _plat(he.global_position, p_vol) > 20.0, "héron : il se pose plus loin (%.0f m)" % _plat(he.global_position, p_vol))
	var lq1: float = float(IM.lake_q(he.global_position.x - mc.x, he.global_position.z - mc.z))
	_ok(lq1 > 0.85 and lq1 < 1.08, "héron : de nouveau dans l'eau peu profonde, sur une autre rive (%.2f)" % lq1)
	_vider()
	# ================================================== Montjoie : le Bois des Lutins
	await _aller(F, "montjoie", "bois")
	var ec: Node3D = _pres("ecureuil", 10.0)
	await _att(0.5)
	_ok(str(ec.state) == "fouille", "écureuil : il fouille au pied des arbres (%s)" % str(ec.state))
	var ve: Vector3 = ec.global_position - _pos()
	ve.y = 0.0
	ve = ve.normalized()
	await _poser_ici(ec.global_position - ve * 4.0, ve)
	var sec: Dictionary = await _suivre(ec, 300, func() -> bool: return str(ec.state) == "perche")
	_ok(sec.has("court") and sec.has("grimpe") and str(ec.state) == "perche", "écureuil : on approche, il file au tronc le plus proche et grimpe %s" % str(sec.keys()))
	var haut_e: float = ec.global_position.y - _h(ec.global_position.x, ec.global_position.z)
	_ok(haut_e > 2.5, "écureuil : il vous gronde de là-haut (%.1f m)" % haut_e)
	await _poser_ici(ec.global_position + Vector3(ve.x, 0, ve.z) * 16.0, ve)
	var sed: Dictionary = await _suivre(ec, 500, func() -> bool: return str(ec.state) == "fouille")
	_ok(sed.has("descend") and str(ec.state) == "fouille", "écureuil : on est parti, il redescend %s" % str(sed.keys()))
	_vider()
	# ================================================== Port-Azur : le maquis
	await _aller(F, "azur", "collines")
	var lz: Node3D = _pres("lezard", 6.0)
	await _att(0.4)
	_ok(str(lz.state) == "soleil", "lézard : il se chauffe au soleil (%s)" % str(lz.state))
	var vl: Vector3 = lz.global_position - _pos()
	vl.y = 0.0
	vl = vl.normalized()
	await _poser_ici(lz.global_position - vl * 2.0, vl)
	var slz: Dictionary = await _suivre(lz, 120, func() -> bool: return str(lz.state) == "cache")
	_ok(slz.has("file") and int(lz.caches) >= 1 and not lz._visual.visible, "lézard : il file en zigzag et disparaît dans une fente %s" % str(slz.keys()))
	await _poser_ici(lz.global_position - vl * 10.0, vl)
	lz.timer = 0.5
	await _suivre(lz, 120, func() -> bool: return str(lz.state) == "soleil")
	_ok(str(lz.state) == "soleil" and lz._visual.visible, "lézard : puis il ressort un peu plus loin")
	_vider()
	var tt: Node3D = _pres("tortue_terre", 5.0)
	await _att(0.4)
	_ok(str(tt.state) == "broute", "tortue d'Hermann : elle broute (%s)" % str(tt.state))
	var vt: Vector3 = tt.global_position - _pos()
	vt.y = 0.0
	vt = vt.normalized()
	await _poser_ici(tt.global_position - vt * 1.5, vt)
	await _suivre(tt, 80, func() -> bool: return str(tt.state) == "rentree")
	_ok(str(tt.state) == "rentree" and int(tt.rentrees) >= 1, "tortue d'Hermann : on s'approche, elle rentre dans sa carapace")
	await _poser_ici(tt.global_position - vt * 8.0, vt)
	var stt: Dictionary = await _suivre(tt, 500, func() -> bool: return str(tt.state) == "broute")
	_ok(stt.has("ressort") and str(tt.state) == "broute", "tortue d'Hermann : on est parti, elle ressort et broute %s" % str(stt.keys()))
	_vider()
	# les guêpiers suivent le héros qui marche dans le maquis
	var gp: Node3D = F.spawn("guepier", _pos() + Vector3(10.0, 6.0, 0.0))
	await _att(0.4)
	var dir_g: Vector3 = hero_v28.facing
	dir_g.y = 0.0
	dir_g = dir_g.normalized() if dir_g.length() > 0.05 else Vector3.FORWARD
	var cap0: int = int(gp.captures)
	await _marcher(dir_g, 1.6, 7.0, func() -> bool: return str(gp.state) == "suit" and int(gp.captures) > cap0 and _plat(gp._orbit_c, _pos()) < 8.0)
	_ok(str(gp.state) == "suit" and _plat(gp._orbit_c, _pos()) < 8.0, "guêpiers : le héros marche dans le maquis, ils le suivent (%.1f m)" % _plat(gp._orbit_c, _pos()))
	_ok(int(gp.captures) > cap0, "guêpiers : ils attrapent les insectes qu'il dérange")
	_vider()
	# ================================================== l'Île Pixelithique (en petits cubes)
	await _aller(F, "pixel")
	inventory_v28.add("pomme", 2)
	F._chap_cd = 0.0
	var cps: Array = [_pres("compsognathe", 8.0, 0.1, -1.0), _pres("compsognathe", 8.5, 0.1, 0.0), _pres("compsognathe", 9.0, 0.1, 1.0)]
	var vols0: int = F.vols
	var vus_c: Dictionary = {}
	for k in range(600):
		await _att(0.03)
		hero_v28.hp = hero_v28.HP_MAX
		for cp in cps:
			if is_instance_valid(cp):
				vus_c[str(cp.state)] = true
		if F.vols > vols0:
			break
	_ok(vus_c.has("suit"), "compsognathes : une petite bande curieuse qui suit le héros %s" % str(vus_c.keys()))
	_ok(F.vols > vols0, "compsognathes : le héros reste tranquille, le plus hardi lui chipe à manger")
	var voleur: Node3D = null
	for cp in cps:
		if is_instance_valid(cp) and str(cp.butin) != "":
			voleur = cp
	if _ok(voleur != null, "compsognathe : il emporte le butin dans la gueule"):
		var rendus0: int = F.rendus
		voleur.take_hit(3, _pos())
		await _att(0.2)
		_ok(F.rendus == rendus0 + 1 and str(voleur.state) == "detale", "compsognathe : frappé, il lâche ce qu'il a pris et détale, sans une égratignure (%s)" % str(voleur.state))
	_vider()
	temps_v56.set_hour(22.5)
	await _images(2)
	var cn: Node3D = _pres("compsognathe", 7.0)
	await _att(0.6)
	_ok(str(cn.state) == "dort", "compsognathe : la nuit, il dort (%s)" % str(cn.state))
	var vc: Vector3 = cn.global_position - _pos()
	vc.y = 0.0
	vc = vc.normalized()
	await _poser_ici(cn.global_position - vc * 2.0, vc)
	await _suivre(cn, 80, func() -> bool: return str(cn.state) == "detale")
	_ok(str(cn.state) == "detale", "compsognathe : on s'approche, il se réveille et détale")
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# l'archéoptéryx : perché à la cime d'un arbre ; on passe dessous, il plane jusqu'à un autre
	var cime: Vector3 = F.arbre_pres(_pos(), 14.0, 90.0, Vector3.INF)
	if _ok(cime != Vector3.INF, "Île Pixelithique : un grand arbre pas loin"):
		var ar: Node3D = F.spawn("archeopteryx", cime)
		await _att(0.5)
		_ok(str(ar.state) == "perche" and ar.global_position.distance_to(cime) < 0.5 and cime.y - _h(cime.x, cime.z) > 2.0,
			"archéoptéryx : perché à la cime d'un arbre (%.1f m)" % (cime.y - _h(cime.x, cime.z)))
		await _poser_ici(Vector3(cime.x + 2.0, 0.0, cime.z + 1.0), Vector3.FORWARD)
		var sar: Dictionary = await _suivre(ar, 800, func() -> bool: return int(ar.planes) >= 1 and str(ar.state) == "perche")
		_ok(sar.has("plane") and str(ar.state) == "perche", "archéoptéryx : on passe dessous, il plane jusqu'à un autre arbre %s" % str(sar.keys()))
		_ok(_plat(ar.global_position, cime) > 8.0 and ar.global_position.y - _h(ar.global_position.x, ar.global_position.z) > 2.0,
			"archéoptéryx : perché sur un autre arbre (à %.0f m du premier)" % _plat(ar.global_position, cime))
		_vider()
	# la meganeura : le héros reste tranquille au bord du lac, elle vient le voir de tout près
	var cl: Vector3 = etp[0]
	var rl: float = float(etp[1])
	var dl: Vector3 = Vector3(_pos().x - cl.x, 0, _pos().z - cl.z)
	dl = dl.normalized() if dl.length() > 0.5 else Vector3.FORWARD
	# (sur la terre ferme, au sec, pas dans l'eau du bord)
	var bord: Vector3 = cl + dl * (rl + 5.0)
	var trouve: bool = false
	for k in range(16):
		for rb in [5.0, 7.0]:
			var qb: Vector3 = cl + dl.rotated(Vector3.UP, TAU * float(k) / 16.0) * (rl + rb)
			if not trouve and _h(qb.x, qb.z) > float(etp[0].y) + 0.3 and not testeur_v78._sous_toit(qb, _h(qb.x, qb.z)):
				bord = qb
				trouve = true
	dl = Vector3(bord.x - cl.x, 0, bord.z - cl.z).normalized()
	await _poser_ici(bord, -dl)
	await _att(0.8)
	var ml: Node3D = F.spawn("meganeura", cl + dl * rl * 0.8 + Vector3.UP * 1.5)
	var sml: Dictionary = await _suivre(ml, 600, func() -> bool: return int(ml.inspections) >= 1)
	_ok(sml.has("inspecte") and int(ml.inspections) >= 1, "meganeura : elle vient voir le héros de tout près %s (à %.0f m du lac, %.1f m/s)" % [str(sml.keys()), _plat(_pos(), cl) - rl, float(ml._hero_v)])
	await _marcher(Vector3(-dl.z, 0, dl.x), 3.0, 1.5, func() -> bool: return str(ml.state) == "file")
	_ok(str(ml.state) == "file", "meganeura : le héros bouge, elle file (%s)" % str(ml.state))
	_vider()
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var Lg = load("res://scripts/langue_v104.gd")
	Lg.choisir("en", false)
	var t1: String = Lg.t("Le coq défend ses poules !")
	var t2: String = Lg.t("Le compsognathe lâche %s !" % "XYZ")
	Lg.choisir("fr", false)
	_ok(t1 == "The rooster defends his hens!", "anglais : « %s »" % t1)
	_ok(t2 == "The compsognathus drops XYZ!", "anglais : « %s »" % t2)

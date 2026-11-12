## La faune de l'Île aux Moaïs, de l'Île de la Balafre et de l'Île de Larsen (V136) : les naissances
## par île, de jour et de nuit ; le troupeau de chevaux (alerte, galop de tout le troupeau, ruade,
## cabrade), la frégate qui pêche, la tortue qui se fige et retourne à la mer (un coup : « toc »), les
## aras qui crient, le varan (morsure devant, coup de queue derrière), le crabe de cocotier blindé
## devant, le lapin et son terrier, les frelons qui poursuivent puis renoncent, le hérisson qui se
## roule en boule (et pique), le grand-duc qui suit des yeux puis s'envole, le renard chapardeur ;
## rien ne naît sous terre ; les textes en anglais.
const NOM := "faune_nord"


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
	q.y += {"frelon": 1.3, "perroquet": 3.0, "fregate": 16.0}.get(kind, 0.1)
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
	await _att(0.5)
	F._tick = 9999.0
	_vider()


## Le héros juste derrière une bête (à « d » mètres de son arrière-train), tourné vers elle.
func _derriere(b: Node3D, d: float) -> void:
	var f: Vector3 = b.facing
	var q: Vector3 = b.global_position - f * d
	q.y = _height_at(q.x, q.z) + 0.2
	place_player_v35(q, f)
	await _images(2)


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["moai", "balafre", "larsen"]:
		_ok(F.iles.has(id) and float(F.iles[id]["r"]) >= 40.0, "île « %s » repérée (rayon %.0f m)" % [id, float(F.iles.get(id, {}).get("r", 0.0))])
	# --- naissances, de jour puis de nuit
	temps_v56.set_hour(12.0)
	for ile in ["moai", "balafre", "larsen"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		_ok(F.ile_de(_pos()) == ile, "testeur : un coin sauvage sur l'île « %s »" % ile)
		await _naissances(F, ile, "%s, de jour" % ile)
	temps_v56.set_hour(22.5)
	await _images(2)
	for ile in ["moai", "balafre", "larsen"]:
		testeur_v78._faune_v132(ile)
		await _att(0.5)
		await _naissances(F, ile, "%s, la nuit" % ile)
	temps_v56.set_hour(12.0)
	await _images(2)
	# sous terre, rien ne naît
	var p0: Vector3 = _pos()
	_ok(F._blocked(Vector3(p0.x, _height_at(p0.x, p0.z) - 6.0, p0.z)), "sous terre, rien ne naît")
	testeur_v78.invincible = false
	# ================================================== l'Île aux Moaïs
	await _aller(F, "moai")
	# le troupeau : on s'approche d'un cheval, il lève la tête… et tous partent au galop
	var chevaux: Array = []
	var dirs: Array = [hero_v28.facing, hero_v28.facing.rotated(Vector3.UP, 0.5), hero_v28.facing.rotated(Vector3.UP, -0.5)]
	for i in range(3):
		var q: Vector3 = _pos() + (dirs[i] as Vector3) * (11.0 + float(i) * 1.5)
		q.y = _height_at(q.x, q.z) + 0.1
		chevaux.append(F.spawn("cheval_sauvage", q))
	await _att(0.6)
	var calmes: bool = true
	for c in chevaux:
		calmes = calmes and str(c.state) == "erre"
	_ok(calmes and not F.hostile_zone(_pos()), "chevaux sauvages : ils broutent tranquilles, sans menace")
	var c0: Node3D = chevaux[0]
	var pres: Vector3 = c0.global_position - (c0.global_position - _pos()).normalized() * 3.5
	pres.y = _height_at(pres.x, pres.z) + 0.2
	place_player_v35(pres, (c0.global_position - pres).normalized())
	var etats: Array = [{}, {}, {}]
	for k in range(120):
		await _att(0.03)
		for i in range(3):
			if is_instance_valid(chevaux[i]):
				etats[i][str(chevaux[i].state)] = true
	_ok(etats[0].has("alerte"), "cheval : il lève la tête quand on approche %s" % str(etats[0].keys()))
	var tous: bool = true
	for i in range(3):
		tous = tous and etats[i].has("galop")
	_ok(tous, "chevaux : tout le troupeau part au galop %s %s %s" % [str(etats[0].keys()), str(etats[1].keys()), str(etats[2].keys())])
	_vider()
	# frappé par derrière : il rue (et la ruade porte)
	var cv: Node3D = _pres("cheval_sauvage", 6.0)
	await _att(0.2)
	cv.state = "erre"
	cv._graze = 5.0
	await _derriere(cv, 1.3)
	cv.take_hit(3, _pos())
	var stv: Dictionary = await _suivre(cv, 60, func() -> bool: return int(cv.kicks) >= 1 and str(cv.state) != "ruade")
	_ok(stv.has("ruade") and int(cv.kicks) >= 1, "cheval : frappé par derrière, il rue %s" % str(stv.keys()))
	_ok(int(cv.landed_hits) >= 1, "cheval : la ruade porte quand on est derrière lui")
	_vider()
	# frappé de face : il se cabre, puis s'enfuit
	var cf: Node3D = _pres("cheval_sauvage", 3.0)
	cf.facing = (_pos() - cf.global_position).normalized()
	cf.facing.y = 0.0
	cf.facing = cf.facing.normalized()
	cf.take_hit(3, _pos())
	var stf: Dictionary = await _suivre(cf, 60, func() -> bool: return str(cf.state) == "galop")
	_ok(stf.has("cabre") and stf.has("galop"), "cheval : frappé de face, il se cabre puis s'enfuit %s" % str(stf.keys()))
	_vider()
	# la frégate : au-dessus de la côte, elle plonge pêcher en mer
	var plage: Vector3 = testeur_v78._milieu_pres(F, _pos(), "plage", 90.0)
	if _ok(plage != Vector3.INF, "Moaïs : une plage près du coin sauvage"):
		var fr: Node3D = F.spawn("fregate", plage + Vector3(0, _height_at(plage.x, plage.z) + 16.0, 0))
		fr._cd136 = 0.0
		var stp: Dictionary = await _suivre(fr, 400, func() -> bool: return int(fr.peches) >= 1 and str(fr.state) == "remonte")
		_ok(int(fr.peches) >= 1 and stp.has("pique"), "frégate : elle plonge pêcher en mer %s" % str(stp.keys()))
		_ok(is_instance_valid(fr) and fr._poisson != null and fr._poisson.visible, "frégate : elle remonte un poisson au bec")
		_ok(bool(fr.peaceful) and not F.hostile_zone(_pos()), "frégate : paisible")
		_vider()
		# la tortue verte : sur la plage ; on approche, elle se fige, puis retourne à la mer
		var to: Node3D = F.spawn("tortue_verte", Vector3(plage.x, _height_at(plage.x, plage.z) + 0.1, plage.z))
		var loin: Vector3 = plage + Vector3(9.0, 0, 0)
		loin.y = _height_at(loin.x, loin.z) + 0.3
		await _poser(Vector3(loin.x, maxf(loin.y, 0.0), loin.z))
		await _att(0.5)
		_ok(str(to.state) in ["monte", "ponte"], "tortue verte : tranquille sur la plage (%s)" % str(to.state))
		var pt: Vector3 = to.global_position + Vector3(1.8, 0, 0)
		place_player_v35(Vector3(pt.x, maxf(_height_at(pt.x, pt.z), 0.0) + 0.3, pt.z), Vector3(-1, 0, 0))
		var stt: Dictionary = await _suivre(to, 120, func() -> bool: return str(to.state) == "descend")
		_ok(stt.has("fige") and stt.has("descend"), "tortue verte : dérangée, elle se fige, puis retourne vers la mer %s" % str(stt.keys()))
		var hp0: int = int(to.hp)
		to.take_hit(5, _pos())
		_ok(int(to.hp) == hp0 and int(to.tocs) == 1, "tortue verte : un coup sur la carapace ne lui fait rien (toc !)")
		var h0: float = _height_at(to.global_position.x, to.global_position.z)
		await _poser(Vector3(loin.x, maxf(loin.y, 0.0) + 0.2, loin.z) + Vector3(20, 0, 0))
		await _att(5.0)
		var plus_bas: bool = not is_instance_valid(to) or str(to.state) == "plonge" or _height_at(to.global_position.x, to.global_position.z) < h0 - 0.05
		_ok(plus_bas, "tortue verte : elle descend vers l'eau")
		_vider()
	# ================================================== l'Île de la Balafre
	await _aller(F, "balafre")
	var aras: Array = []
	for i in range(3):
		aras.append(_pres("perroquet", 7.0 + float(i)))
	var parle: bool = false
	var tourne: bool = false
	for k in range(200):
		await _att(0.03)
		var n2: int = 0
		for a in aras:
			if is_instance_valid(a):
				n2 += int(a.paroles)
				tourne = tourne or str(a.state) == "tourne"
		if n2 >= 1 and tourne:
			parle = true
			break
	_ok(parle, "aras : ils tournent autour du héros en criant des mots de pirate")
	var ar0: Node3D = aras[0]
	ar0.take_hit(3, _pos())
	_ok(int(ar0.hp) == 99 and str(ar0.state) == "file", "ara : frappé, il n'a rien et file plus loin (%s)" % str(ar0.state))
	_vider()
	# le varan : il vient mordre de face
	var va: Node3D = _pres("varan", 6.0)
	var sva: Dictionary = await _suivre(va, 300, func() -> bool: return int(va.landed_hits) >= 1)
	_ok(sva.has("chasse") and sva.has("armer"), "varan : il approche et ouvre la gueule %s" % str(sva.keys()))
	_ok(int(va.landed_hits) >= 1, "varan : sa morsure porte")
	_vider()
	# … et si l'on passe derrière lui, la queue part
	var vb: Node3D = _pres("varan", 5.0)
	await _att(0.1)
	vb.state = "chasse"
	await _derriere(vb, 1.6)
	var hits0: int = int(vb.landed_hits)
	var svb: Dictionary = await _suivre(vb, 120, func() -> bool: return int(vb.whips) >= 1)
	_ok(svb.has("fouet_armer") and int(vb.whips) >= 1, "varan : derrière lui, il fouette de la queue %s" % str(svb.keys()))
	_ok(int(vb.landed_hits) > hits0, "varan : le coup de queue porte")
	_vider()
	# le crabe de cocotier : la carapace encaisse de face, pas par derrière
	var cr: Node3D = _pres("crabe_cocotier", 2.5)
	cr.set_physics_process(false)
	var vers: Vector3 = _pos() - cr.global_position
	vers.y = 0.0
	cr.facing = vers.normalized()
	var a0: int = int(cr.hp)
	cr.take_hit(6, _pos())
	var face_perte: int = a0 - int(cr.hp)
	cr.facing = -vers.normalized()
	var a1: int = int(cr.hp)
	cr.take_hit(6, _pos())
	var dos_perte: int = a1 - int(cr.hp)
	_ok(face_perte < dos_perte and int(cr.tocs) == 1, "crabe de cocotier : de face, il ne perd que %d ; par derrière, %d" % [face_perte, dos_perte])
	_vider()
	# ================================================== l'Île de Larsen
	await _aller(F, "larsen")
	# le lapin : il se dresse, détale, plonge dans son terrier… et ressort plus loin
	var la: Node3D = _pres("lapin_garenne", 5.0)
	var sla: Dictionary = await _suivre(la, 160, func() -> bool: return str(la.state) == "terre")
	_ok(sla.has("alerte") and sla.has("fuite") and int(la.terriers) >= 1, "lapin : il se dresse, détale et plonge dans son terrier %s" % str(sla.keys()))
	_ok(is_instance_valid(la) and not la.visible and not la.is_hittable(), "lapin : dans son terrier, on ne le voit plus")
	var ici: Vector3 = _pos()
	var ailleurs: Vector3 = ici + (ici - la.global_position).normalized() * 12.0
	ailleurs.y = _height_at(ailleurs.x, ailleurs.z) + 0.3
	await _poser(ailleurs)
	await _suivre(la, 400, func() -> bool: return int(la.sorties) >= 1)
	_ok(is_instance_valid(la) and int(la.sorties) >= 1 and la.visible, "lapin : il ressort plus loin quand on est parti")
	_vider()
	# les frelons : ils poursuivent et piquent ; on court loin, ils renoncent
	var fl: Node3D = _pres("frelon", 5.0)
	var sfl: Dictionary = await _suivre(fl, 260, func() -> bool: return int(fl.stings) >= 1)
	_ok(sfl.has("chasse") and int(fl.stings) >= 1, "frelons : ils foncent sur le héros et piquent %s" % str(sfl.keys()))
	fl.take_hit(2, _pos())
	var vus: int = 0
	for e in fl._frelons:
		if (e[0] as Node3D).visible:
			vus += 1
	_ok(vus < fl._frelons.size(), "frelons : un coup en chasse quelques-uns (%d sur %d)" % [vus, fl._frelons.size()])
	var fuite: Vector3 = _pos() + (_pos() - fl.global_position).normalized() * 35.0
	fuite.y = _height_at(fuite.x, fuite.z) + 0.3
	await _poser(fuite)
	var sfr: Dictionary = await _suivre(fl, 80, func() -> bool: return str(fl.state) == "retour")
	_ok(sfr.has("retour"), "frelons : quand on court loin, ils renoncent %s" % str(sfr.keys()))
	_vider()
	# le hérisson : il se roule en boule ; le frapper en boule, ça pique
	var he: Node3D = _pres("herisson", 4.0)
	place_player_v35(he.global_position + (_pos() - he.global_position).normalized() * 1.4 + Vector3(0, 0.3, 0), (he.global_position - _pos()).normalized())
	await _att(0.9)
	_ok(str(he.state) == "boule" and float(he._ball) > 0.9, "hérisson : il se roule en boule quand on approche (%s)" % str(he.state))
	var hh: int = int(he.hp)
	he.take_hit(3, _pos())
	_ok(int(he.piques) == 1 and int(he.hp) == hh, "hérisson : frappé en boule, il n'a rien… et ça pique")
	var hl: Vector3 = _pos() + (_pos() - he.global_position).normalized() * 10.0
	hl.y = _height_at(hl.x, hl.z) + 0.3
	await _poser(hl)
	var she: Dictionary = await _suivre(he, 160, func() -> bool: return str(he.state) == "erre")
	_ok(she.has("deroule") or str(he.state) == "erre", "hérisson : on s'éloigne, il se déroule %s" % str(she.keys()))
	_vider()
	# le grand-duc : posé, il suit le héros des yeux ; on approche, il s'envole et se pose plus loin
	temps_v56.set_hour(22.5)
	await _images(2)
	var hb: Node3D = _pres("hibou_grand_duc", 12.0)
	await _att(0.4)
	var cote: Vector3 = hb.global_position + Vector3(hb.facing.z, 0, -hb.facing.x) * 8.0
	cote.y = _height_at(cote.x, cote.z) + 0.3
	await _poser(cote)
	await _att(1.2)
	var dh: Vector3 = _pos() - hb.global_position
	var rel: float = wrapf(atan2(dh.x, dh.z) - atan2(hb.facing.x, hb.facing.z), -PI, PI)
	_ok(str(hb.state) == "perche" and absf(wrapf(float(hb._head_yaw) - clampf(rel, -2.3, 2.3), -PI, PI)) < 0.35, "grand-duc : il tourne la tête vers le héros (%.2f / %.2f)" % [float(hb._head_yaw), rel])
	var avant: Vector3 = hb.global_position
	var pp: Vector3 = avant + (_pos() - avant).normalized() * 3.0
	place_player_v35(Vector3(pp.x, _height_at(pp.x, pp.z) + 0.3, pp.z), (avant - pp).normalized())
	var shb: Dictionary = await _suivre(hb, 300, func() -> bool: return int(hb.envols) >= 1 and str(hb.state) == "perche")
	_ok(shb.has("envol") and str(hb.state) == "perche", "grand-duc : il s'envole et se pose plus loin %s" % str(shb.keys()))
	_ok(is_instance_valid(hb) and hb.global_position.distance_to(avant) > 10.0, "grand-duc : posé à %.0f m de là" % (hb.global_position.distance_to(avant) if is_instance_valid(hb) else 0.0))
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# le renard : il chipe à manger ; frappé, il lâche et file (dans un coin dégagé : un rocher, une
	# yourte peuvent le gêner)
	await _aller(F, "larsen")
	inventory_v28.add("pomme", 2)
	F._chap_cd = 0.0
	var re: Node3D = _pres("renard_roux", 6.0)
	var vols0: int = F.vols
	var sre: Dictionary = await _suivre(re, 400, func() -> bool: return F.vols > vols0)
	_ok(F.vols == vols0 + 1 and str(re.butin) != "", "renard : il chipe à manger (« %s ») %s" % [str(re.butin), str(sre.keys())])
	var rendus0: int = F.rendus
	re.take_hit(3, _pos())
	await _att(0.2)
	_ok(F.rendus == rendus0 + 1 and str(re.state) == "fuite", "renard : frappé, il lâche ce qu'il a pris et file")
	_vider()
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var Bete = load("res://scripts/monstre_v136.gd")
	var t1: String = L.t("Le renard lâche %s !" % "une pomme")
	var t2: String = L.t(str(Bete.ALERTES136["varan"]))
	var t3: String = L.t("Mille sabords !")
	L.choisir("fr", false)
	_ok(t1.begins_with("The fox drops"), "anglais : « %s »" % t1)
	_ok(t2.begins_with("A monitor lizard!"), "anglais : « %s »" % t2.left(30))
	_ok(t3 == "Blistering barnacles!", "anglais : « %s »" % t3)

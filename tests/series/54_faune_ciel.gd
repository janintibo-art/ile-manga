## La faune des îles du ciel (V137) : le royaume des fées, l'île flottante et Astralys. Le sol des îles
## du ciel (leur relief, le vide autour), les naissances de jour et de nuit ; les papillons qui se
## posent sur le héros immobile, le cerf blanc qui observe puis s'enfuit en bondissant (sans jamais
## sauter dans le vide), le blaireau qui gronde puis mord mais ne quitte pas son terrier, les
## marmottes (la sentinelle siffle, toutes plongent, puis ressortent), le gypaète qui lâche un os,
## le lynx à l'affût qui bondit puis se retire, la méduse qui pique qui passe dessous, les raies
## qui rasent le héros ; les textes en anglais.
const NOM := "faune_ciel"


func _h(F: Node, x: float, z: float) -> float:
	return float(F.hauteur(x, z))


## Une bête à « d » mètres devant le héros (ou autour), sur l'île, à sa hauteur.
func _pres(F: Node, kind: String, d: float, haut: float = 0.1) -> Node3D:
	var p: Vector3 = _pos()
	var q: Vector3 = p + hero_v28.facing * d
	for k in range(17):
		if F.sur_ile(F.ile_joueur, q) and absf(_h(F, q.x, q.z) - p.y) < 1.5:
			break
		var a: float = TAU * float(k) / 16.0
		q = p + Vector3(cos(a), 0, sin(a)) * d
	q.y = _h(F, q.x, q.z) + haut
	return F.spawn(kind, q)


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
	var dans_le_vide: int = 0
	for b in F.betes:
		if is_instance_valid(b) and not bool(b.vol) and F.vide((b as Node3D).global_position, ile):
			dans_le_vide += 1
	_ok(dans_le_vide == 0, "%s : aucune bête ne naît dans le vide" % quoi)
	for k in F.spawned:
		_ok(str(k) in ok_kinds, "%s : « %s » est à sa place" % [quoi, str(k)])
	F._tick = 9999.0
	_vider()


func _aller(F: Node, ile: String) -> void:
	testeur_v78._faune_v132(ile)
	await _att(0.6)
	F._tick = 0.0
	await _att(0.1)
	F._tick = 9999.0
	_vider()


## Le héros posé sur l'île, à (x, z), tourné vers « face ».
func _poser_ici(F: Node, q: Vector3, face: Vector3 = Vector3.FORWARD) -> void:
	place_player_v35(Vector3(q.x, _h(F, q.x, q.z) + 0.3, q.z), face)
	await _images(3)


func _serie() -> void:
	var F: Node = faune_v132
	F._resolve_iles()
	for id in ["fees", "celeste", "astrale"]:
		_ok(F.iles.has(id) and F.iles[id].has("y") and float(F.iles[id]["r"]) >= 40.0, "île du ciel « %s » repérée (à %.0f m)" % [id, float(F.iles.get(id, {}).get("y", 0.0))])
	# le sol d'une île du ciel : son relief, et le vide autour ; à la mer, dessous, ce n'est plus l'île
	var cf: Vector3 = F.iles["fees"]["c"]
	var yf: float = float(F.iles["fees"]["y"])
	_ok(absf(float(F.hauteur(cf.x + 5.0, cf.z + 40.0, "fees")) - yf) < 12.0, "fées : le sol est à l'altitude de l'île")
	_ok(F.vide(Vector3(cf.x + 300.0, yf, cf.z), "fees") and not F.vide(Vector3(cf.x + 5.0, yf, cf.z + 40.0), "fees"), "fées : le vide autour de l'île")
	_ok(F.ile_de(Vector3(cf.x + 5.0, yf + 2.0, cf.z + 40.0)) == "fees" and F.ile_de(Vector3(cf.x + 5.0, 0.0, cf.z + 40.0)) != "fees", "fées : on n'y est qu'à son altitude")
	# --- naissances, de jour puis de nuit
	temps_v56.set_hour(12.0)
	for ile in ["fees", "celeste", "astrale"]:
		testeur_v78._faune_v132(ile)
		await _att(0.6)
		_ok(F.ile_de(_pos()) == ile, "testeur : un coin sauvage sur « %s » (%s)" % [ile, F.ile_de(_pos())])
		await _naissances(F, ile, "%s, de jour" % ile)
	temps_v56.set_hour(22.5)
	await _images(2)
	for ile in ["fees", "celeste", "astrale"]:
		testeur_v78._faune_v132(ile)
		await _att(0.6)
		await _naissances(F, ile, "%s, la nuit" % ile)
	temps_v56.set_hour(12.0)
	await _images(2)
	testeur_v78.invincible = false
	# ================================================== le royaume des fées
	await _aller(F, "fees")
	# les papillons : le héros ne bouge plus, ils viennent se poser sur lui ; il bouge, ils s'envolent
	var pa: Node3D = _pres(F, "papillon_morpho", 2.5, 1.2)
	var spa: Dictionary = await _suivre(pa, 200, func() -> bool: return str(pa.state) == "pose")
	_ok(int(pa.poses) >= 1 and str(pa.state) == "pose", "papillons : ils se posent sur le héros immobile %s" % str(spa.keys()))
	await _att(1.8)
	_ok(pa.global_position.distance_to(_pos() + Vector3.UP * 1.45) < 1.2, "papillons : posés tout contre lui (%.1f m)" % pa.global_position.distance_to(_pos() + Vector3.UP * 1.45))
	var ici: Vector3 = _pos()
	await _poser_ici(F, ici + hero_v28.facing * 2.5, hero_v28.facing)
	await _att(0.3)
	_ok(str(pa.state) == "envol", "papillons : le héros bouge, ils s'envolent (%s)" % str(pa.state))
	_vider()
	# le cerf blanc : il observe, puis s'enfuit en bondissant ; on ne peut pas le toucher
	var ce: Node3D = _pres(F, "cerf_blanc", 12.0)
	await _att(0.8)
	_ok(str(ce.state) == "observe", "cerf blanc : il lève la tête et observe (%s)" % str(ce.state))
	var d0: float = ce.global_position.distance_to(_pos())
	var vers: Vector3 = (ce.global_position - _pos())
	vers.y = 0.0
	await _poser_ici(F, _pos() + vers.normalized() * (d0 - 6.0), vers.normalized())
	var vide_vu: bool = false
	var sce: Dictionary = {}
	for k in range(200):
		await _att(0.03)
		if not is_instance_valid(ce):
			break
		sce[str(ce.state)] = true
		vide_vu = vide_vu or F.vide(ce.global_position, "fees")
		if int(ce.bonds) >= 4 and str(ce.state) == "observe":
			break
	_ok(sce.has("bonds") and int(ce.bonds) >= 3, "cerf blanc : on approche, il s'enfuit en bondissant (%d bonds)" % int(ce.bonds))
	_ok(ce.global_position.distance_to(_pos()) > 12.0, "cerf blanc : il est maintenant loin (%.0f m)" % ce.global_position.distance_to(_pos()))
	_ok(not vide_vu, "cerf blanc : ses bonds ne l'emmènent jamais dans le vide")
	ce.take_hit(9, _pos())
	_ok(int(ce.hp) == 99, "cerf blanc : on ne peut pas lui faire de mal")
	_vider()
	# le blaireau : il gronde ; on approche encore, il mord ; on s'en va, il ne suit pas
	temps_v56.set_hour(22.5)
	await _images(2)
	var bl: Node3D = _pres(F, "blaireau", 5.0)
	var sbl: Dictionary = await _suivre(bl, 60)
	_ok(sbl.has("grogne") and int(bl.landed_hits) == 0, "blaireau : il gronde d'abord, sans mordre %s" % str(sbl.keys()))
	var vb: Vector3 = (bl.global_position - _pos())
	vb.y = 0.0
	await _poser_ici(F, bl.global_position - vb.normalized() * 2.0, vb.normalized())
	var sbm: Dictionary = await _suivre(bl, 150, func() -> bool: return int(bl.landed_hits) >= 1)
	_ok(int(bl.landed_hits) >= 1, "blaireau : on approche encore, il mord %s" % str(sbm.keys()))
	var maison: Vector3 = bl.home
	await _poser_ici(F, maison - vb.normalized() * 15.0, vb.normalized())
	await _suivre(bl, 150, func() -> bool: return str(bl.state) == "erre")
	_ok(Vector2(bl.global_position.x - maison.x, bl.global_position.z - maison.z).length() < 8.0, "blaireau : il ne quitte pas son terrier (%s)" % str(bl.state))
	_ok(is_instance_valid(bl._terrier_n), "blaireau : son terrier est là")
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# ================================================== l'île flottante
	await _aller(F, "celeste")
	# les marmottes : la sentinelle siffle, toutes plongent ; on s'en va, elles ressortent
	var mm: Array = []
	var base: Vector3 = _pos() + hero_v28.facing * 16.0
	for i in range(3):
		var q: Vector3 = base + Vector3(float(i) * 2.0 - 2.0, 0, float(i % 2) * 1.5)
		if not F.sur_ile("celeste", q):
			q = _pos() + hero_v28.facing.rotated(Vector3.UP, 0.4 * float(i)) * 14.0
		q.y = _h(F, q.x, q.z) + 0.1
		mm.append(F.spawn("marmotte", q))
	await _att(0.5)
	var m0: Node3D = mm[0]
	var vm: Vector3 = m0.global_position - _pos()
	vm.y = 0.0
	await _poser_ici(F, m0.global_position - vm.normalized() * 8.0, vm.normalized())
	var toutes: bool = false
	var siff: int = 0
	for k in range(200):
		await _att(0.03)
		siff = 0
		var n_terre: int = 0
		for m in mm:
			if is_instance_valid(m):
				siff += int(m.sifflets)
				if str(m.state) == "terre":
					n_terre += 1
		if n_terre == mm.size():
			toutes = true
			break
	_ok(siff >= 1, "marmottes : la sentinelle siffle")
	_ok(toutes, "marmottes : toutes plongent dans leur terrier")
	await _poser_ici(F, m0.global_position - vm.normalized() * 26.0, vm.normalized())
	var sortie: bool = false
	for k in range(500):
		await _att(0.03)
		if is_instance_valid(m0) and m0.visible and str(m0.state) in ["guette", "erre"]:
			sortie = true
			break
	_ok(sortie, "marmottes : on s'est éloigné, elles ressortent la tête")
	_vider()
	# le gypaète : il monte un os et le lâche sur les rochers
	var os0: int = int(F.os_tombes)
	var gy: Node3D = _pres(F, "gypaete", 4.0, 22.0)
	gy._cd136 = 0.0
	var sgy: Dictionary = await _suivre(gy, 600, func() -> bool: return int(F.os_tombes) > os0)
	_ok(sgy.has("monte_os") and int(gy.lachers) >= 1, "gypaète : il monte un os et le lâche %s" % str(sgy.keys()))
	_ok(int(F.os_tombes) > os0, "gypaète : l'os éclate sur le sol")
	_vider()
	# le lynx : à l'affût ; on passe près de lui, il bondit, puis se retire
	temps_v56.set_hour(22.5)
	await _images(2)
	var ly: Node3D = _pres(F, "lynx", 10.0)
	await _att(0.6)
	_ok(str(ly.state) == "aguet", "lynx : tapi à l'affût (%s)" % str(ly.state))
	var vl: Vector3 = ly.global_position - _pos()
	vl.y = 0.0
	# (V139 : on arrive par un côté où le sol est plat jusqu'à lui, sans rocher ni tronc entre nous, loin du bord)
	var dir_l: Vector3 = vl.normalized()
	var a0: float = atan2(dir_l.z, dir_l.x)
	var yl: float = _h(F, ly.global_position.x, ly.global_position.z)
	for k in range(16):
		var al: float = a0 + TAU * float((k + 1) / 2) / 16.0 * (1.0 if k % 2 == 0 else -1.0)
		var dk := Vector3(cos(al), 0, sin(al))
		var ql: Vector3 = ly.global_position - dk * 4.8
		var ml: Vector3 = ly.global_position - dk * 2.4
		if not F.sur_ile(F.ile_joueur, ql) or absf(_h(F, ql.x, ql.z) - yl) > 0.6 or absf(_h(F, ml.x, ml.z) - yl) > 0.6:
			continue
		var rl := PhysicsRayQueryParameters3D.create(Vector3(ly.global_position.x, yl + 0.6, ly.global_position.z), Vector3(ql.x, yl + 0.6, ql.z), 1, [ly.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(rl).is_empty():
			dir_l = dk
			break
	await _poser_ici(F, ly.global_position - dir_l * 4.8, dir_l)
	var sly: Dictionary = await _suivre(ly, 200, func() -> bool: return int(ly.landed_hits) >= 1 and str(ly.state) in ["souffle", "retraite"])
	_ok(sly.has("armer") and int(ly.jumps) >= 1, "lynx : il se ramasse et bondit %s" % str(sly.keys()))
	var tly: Vector3 = ly.global_position - _pos()
	_ok(int(ly.landed_hits) >= 1, "lynx : son bond porte (posé à %.1f m, %.1f m plus bas, bond de %.1f m)" % [Vector2(tly.x, tly.z).length(), -tly.y, Vector2(ly._jump_to.x - ly._jump_from.x, ly._jump_to.z - ly._jump_from.z).length()])
	var sret: Dictionary = await _suivre(ly, 120, func() -> bool: return str(ly.state) == "retraite")
	_ok(sret.has("retraite") or sly.has("retraite"), "lynx : il se retire ensuite %s" % str(sret.keys()))
	temps_v56.set_hour(12.0)
	await _images(2)
	_vider()
	# ================================================== Astralys
	await _aller(F, "astrale")
	# la méduse : qui passe dessous se fait piquer ; loin d'elle, plus rien
	var me: Node3D = _pres(F, "meduse_celeste", 3.0, 2.0)
	await _att(0.3)
	for k in range(8):
		await _poser_ici(F, me.global_position, hero_v28.facing)
		await _att(0.35)
		hero_v28.hp = hero_v28.HP_MAX
		if int(me.stings) >= 1:
			break
	_ok(int(me.stings) >= 1, "méduse de ciel : on passe dessous, ses filaments piquent")
	_ok(bool(me.peaceful) and not F.hostile_zone(_pos()), "méduse de ciel : elle ne chasse personne")
	var loin: Vector3 = me.global_position + hero_v28.facing * 12.0
	if not F.sur_ile("astrale", loin):
		loin = me.global_position - hero_v28.facing * 12.0
	await _poser_ici(F, loin, hero_v28.facing)
	var st0: int = int(me.stings)
	await _att(2.5)
	_ok(int(me.stings) == st0, "méduse de ciel : loin d'elle, plus de piqûre")
	_vider()
	# les raies : elles planent, puis rasent le héros
	var ra: Node3D = _pres(F, "raie_celeste", 6.0, 8.0)
	ra._cd136 = 0.0
	var sra: Dictionary = await _suivre(ra, 400, func() -> bool: return int(ra.passages) >= 1)
	_ok(int(ra.passages) >= 1, "raie céleste : elle rase le héros %s" % str(sra.keys()))
	_ok(ra.global_position.y > float(F.iles["astrale"]["y"]) - 5.0, "raie céleste : elle reste au-dessus de son île")
	_vider()
	testeur_v78.invincible = true
	F.enabled = false
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var Bete = load("res://scripts/monstre_v137.gd")
	var t1: String = L.t(str(Bete.ALERTES137["lynx"]))
	var t2: String = L.t(str(Bete.ALERTES137["meduse_celeste"]))
	L.choisir("fr", false)
	_ok(t1.begins_with("A lynx!"), "anglais : « %s »" % t1.left(30))
	_ok(t2.begins_with("A wild sky jellyfish!"), "anglais : « %s »" % t2.left(30))

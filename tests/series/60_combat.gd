## Le combat : une bête vaincue donne butin et expérience ; chaque arme porte ses coups ; les six
## sorts et les quatre pouvoirs des sceaux se lancent ; le mode testeur « tout d'un coup ».
const NOM := "combat"


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()


## Une bête immobile juste devant le héros.
func _cible(kind: String = "sanglier") -> Node3D:
	var q: Vector3 = _pos() + hero_v28.facing * 1.4
	q.y = _height_at(q.x, q.z) + 0.1
	var b: Node3D = faune_v132.spawn(kind, q)
	b.set_physics_process(false)
	return b


func _sol() -> void:
	for k in range(40):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _serie() -> void:
	testeur_v78._faune_v132("elfes")
	await _att(0.5)
	faune_v132.enabled = false
	_vider()
	await _images(2)
	# --- une bête vaincue : butin et expérience
	var xp0: int = int(progression_v63.xp)
	var pieces0: int = inventory_v28.count("piece")
	var b0: Node3D = _cible()
	for k in range(12):
		if is_instance_valid(b0) and b0.state != "mort":
			b0.take_hit(3, _pos())
	await _att(0.4)
	_ok(int(progression_v63.xp) > xp0, "sanglier vaincu : de l'expérience (%d -> %d)" % [xp0, int(progression_v63.xp)])
	_ok(inventory_v28.count("piece") > pieces0, "sanglier vaincu : des pièces (%d -> %d)" % [pieces0, inventory_v28.count("piece")])
	_vider()
	# --- le mode testeur : tout d'un coup
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.2)
	_ok(int(progression_v63.level) >= 30, "testeur : niveau maximum (%d)" % int(progression_v63.level))
	_ok(sorts_v67.known.size() == sorts_v67.ORDRE.size(), "testeur : les %d sorts sont appris (%d)" % [sorts_v67.ORDRE.size(), sorts_v67.known.size()])
	# --- chaque arme porte ses coups
	var armes: Array = []
	for id in inventory_v28.ITEMS:
		if str(inventory_v28.ITEMS[id].get("kind", "")) == "arme" and inventory_v28.count(str(id)) > 0:
			armes.append(str(id))
	_ok(armes.size() >= 5, "armes dans le sac : %d %s" % [armes.size(), str(armes)])
	var n_ok: int = 0
	for a in armes:
		_vider()
		await _images(1)
		inventory_v28.equip_item(a)
		await _att(0.3)
		await _sol()
		var b: Node3D = _cible()
		var hp0: int = int(b.hp)
		for k in range(3):
			hero_v28.attack()
			await _att(0.5)
		var ok: bool = _note(str(hero_v28.weapon) == a, "arme « %s » : en main (%s)" % [a, str(hero_v28.weapon)])
		ok = _note(not is_instance_valid(b) or int(b.hp) < hp0 or str(b.state) == "mort", "arme « %s » : le coup porte" % a) and ok
		if ok:
			n_ok += 1
	_ok(n_ok == armes.size(), "armes qui portent : %d sur %d" % [n_ok, armes.size()])
	_vider()
	inventory_v28.equip_item("")
	await _att(0.3)
	# --- les six sorts
	await _sol()
	var lances: Array = []
	for id in sorts_v67.ORDRE:
		sorts_v67.mana = float(sorts_v67.mana_max())
		sorts_v67._cd.clear()
		if id == "telekinesie":
			_cible("sanglier")
		await _sol()
		var ok2: bool = sorts_v67.cast(str(id))
		if ok2:
			lances.append(str(id))
		_note(ok2 or id == "telekinesie", "sort « %s » : il se lance" % id)
		await _att(0.7)
		if id == "levitation":
			await _att(3.0)
	_ok(lances.size() >= sorts_v67.ORDRE.size() - 1, "sorts lancés : %s" % str(lances))
	_vider()
	# --- les quatre pouvoirs des sceaux
	var pouvoirs: Array = []
	for pid in progression_v63.POWER_ORDER:
		pouvoirs_v63._cd.clear()
		await _sol()
		if pouvoirs_v63.use(str(pid)):
			pouvoirs.append(str(pid))
		await _att(0.8)
	_ok(pouvoirs.size() == progression_v63.POWER_ORDER.size(), "pouvoirs des sceaux : %s" % str(pouvoirs))
	await _att(1.0)
	var debout: bool = await _debout("après le combat")
	_ok(debout, "le héros tient debout après le combat")

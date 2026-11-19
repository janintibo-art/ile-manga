## On entre chez les Géants (V174) : la maison des Grandpré par la chatière, le Moulin de la Butte par
## le trou de souris. Les deux portes sont à leur place (la chatière, le trou au pied du moulin) ; on
## entre, on tient debout ; la pièce est à l'échelle des géants ; Tante Brindille et Pépin (des Petits)
## y habitent et on peut aller leur parler ; l'escalier de livres mène bien du carrelage à la table (des
## marches de moins de 0,42 m) et l'on tient debout sur la table ; ce qui bouge (le balancier, le
## rouet, la lanterne) ; ce qu'on y fait ; la nuit, tout se construit aussi.
const NOM := "geants174"
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const L174 = preload("res://scripts/lieux_v174.gd")


func _portes() -> Array:
	var out: Array = []
	for e in Kit56.PORTES_V81:
		if str(e.get("histoire", "")) == L174.HISTOIRE:
			out.append(e)
	return out


func _indice(metier: String) -> int:
	for i in range(maisons_v81.portes.size()):
		var e: Dictionary = maisons_v81.portes[i]
		if str(e.get("histoire", "")) == L174.HISTOIRE and str(e.get("metier", "")) == metier:
			return i
	return -1


func _entrer(i: int) -> bool:
	_ranger()
	await _images(2)
	var p: Dictionary = maisons_v81.portes[i]
	place_player_v35((p["door"] as Vector3) + Vector3.UP * 0.1, -(p["out"] as Vector3))
	await _att(0.3)
	maisons_v81.force_scenario = ""
	maisons_v81.enter(i)
	for k in range(60):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	return maisons_v81.inside and maisons_v81.room != null


## Peut-on aller jusqu'à celui qui tient le lieu (en ligne droite depuis la porte, ou par le milieu) ?
func _accessible(f: Node) -> bool:
	var R = maisons_v81.R
	var a: Vector3 = R.P(0.0, 0.0, R.D * 0.5 - 1.1)
	var c: Vector3 = (f.npc as Node3D).global_position
	c.y = a.y
	var mids: Array = [R.P(0.0, 0.0, 0.0), R.P(-R.W * 0.25, 0.0, 0.3), R.P(R.W * 0.25, 0.0, 0.3)]
	for k in range(12):
		var ang: float = TAU * k / 12.0
		for d in [1.1, 1.45]:
			var p: Vector3 = c + Vector3(cos(ang), 0, sin(ang)) * d
			if _voie_libre(a, p):
				return true
			for m in mids:
				if _voie_libre(a, m) and _voie_libre(m, p):
					return true
	return false


## La hauteur du dessus (repère de la pièce), d'un rayon tiré d'en haut.
func _haut(x: float, z: float, y0: float = 9.0) -> float:
	var R = maisons_v81.R
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(R.P(x, y0, z), R.P(x, -1.0, z), 1)
	var sauf: Array = []
	if pc_body != null:
		sauf.append(pc_body.get_rid())
	if vr_body != null:
		sauf.append(vr_body.get_rid())
	q.exclude = sauf
	var r: Dictionary = space.intersect_ray(q)
	if r.is_empty():
		return -99.0
	return ((r["position"] as Vector3) - R.P(0, 0, 0)).y


## Le chemin de l'escalier de livres (repère de la pièce) : du carrelage, devant la pile, jusqu'à la
## paille de la chaise ; le long de la chaise, puis sur la deuxième pile, jusqu'au plateau de la table.
func _marches() -> Array:
	var pts: Array = []
	var z: float = 7.6
	while z > -0.6:
		pts.append(Vector2(-7.6, z))
		z -= 0.1
	var x: float = -7.6
	while x > -8.6:
		pts.append(Vector2(x, -0.6))
		x -= 0.1
	z = -0.6
	while z > -1.6:
		pts.append(Vector2(-8.6, z))
		z -= 0.1
	x = -8.6
	while x < -4.8:
		pts.append(Vector2(x, -1.6))
		x += 0.1
	return pts


func _actes(textes: Array) -> Array:
	var manque: Array = []
	for t in textes:
		var vu: bool = false
		for it in maisons_v81._its:
			if str(it.get("text", "")).contains(t):
				vu = true
		if not vu:
			manque.append(t)
	return manque


func _anime(nom: String) -> bool:
	for a in maisons_v81.ctx.get("anims170", []):
		if is_instance_valid(a[0]) and str((a[0] as Node).name).begins_with(nom):
			return true
	return false


func _serie() -> void:
	# --- les portes
	var ps: Array = _portes()
	# (V177 : et la porte du donjon du château de sable : 96_chateau_sable)
	_ok(ps.size() == 3, "les trois portes des Petits chez les Géants (%d)" % ps.size())
	await _att(5.5)
	var vus: int = 0
	for e in maisons_v81.portes:
		if str(e.get("histoire", "")) == L174.HISTOIRE:
			vus += 1
	_ok(vus == 3, "maisons_v81 connaît les trois portes (%d)" % vus)
	var g: Node = geants_v142
	if g != null and g.get("reperes") is Dictionary:
		var ch: Vector3 = g.reperes["maison"]["chatiere"]
		var tr: Vector3 = g.reperes["moulin"]["trou"]
		var im: int = _indice("maison_grandpre")
		var io: int = _indice("moulin_butte")
		_ok(im >= 0 and Vector2(ch.x, ch.z).distance_to(Vector2((maisons_v81.portes[im]["door"] as Vector3).x, (maisons_v81.portes[im]["door"] as Vector3).z)) < 2.0, "la porte de la maison est devant la chatière")
		_ok(io >= 0 and (maisons_v81.portes[io]["door"] as Vector3).distance_to(tr) < 0.5, "la porte du moulin est devant le trou de souris")
		_ok(Vector2(tr.x, tr.z).distance_to(Vector2((g.reperes["moulin"]["porte"] as Vector3).x, (g.reperes["moulin"]["porte"] as Vector3).z)) > 8.0, "le trou de souris est loin de la porte des géants (et du géant qui s'y tient)")
	else:
		_ok(false, "l'Île des Géants est construite")
	# --- la maison des Grandpré
	var i1: int = _indice("maison_grandpre")
	var ok: bool = false
	if i1 >= 0:
		ok = await _entrer(i1)
	_ok(ok and str(maisons_v81.ctx.get("scenario", "")) == L174.HISTOIRE, "on entre dans la maison des Grandpré (par la chatière)")
	if ok:
		var R = maisons_v81.R
		_ok(await _debout("dans la maison des Grandpré", 0.6), "on tient debout dans la salle commune")
		_ok(R.W > 70.0 and R.D > 40.0 and R.H > 18.0, "la salle est à l'échelle des géants (%.0f × %.0f × %.0f m)" % [R.W, R.D, R.H])
		var f: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f != null and is_instance_valid(f) and str(f.npc.display_name) == "Tante Brindille", "Tante Brindille habite sous le vaisselier")
		if f != null and is_instance_valid(f):
			_ok(_accessible(f), "on peut aller parler à Tante Brindille")
		# l'escalier de livres : du sol à la table, sans marche trop haute
		var pts: Array = _marches()
		var prev: float = _haut(-7.6, 7.6)
		var pire: float = 0.0
		var ou: Vector2 = Vector2.ZERO
		for p in pts:
			var h: float = _haut((p as Vector2).x, (p as Vector2).y)
			if h - prev > pire:
				pire = h - prev
				ou = p
			prev = h
		_ok(_haut(-7.6, 7.6) < 0.2 and pire <= 0.43, "l'escalier de livres : des marches de moins de 0,42 m (la plus haute : %.2f m, en %s)" % [pire, str(ou)])
		_ok(absf(prev - 5.85) < 0.1, "l'escalier de livres mène au plateau de la table (%.2f m)" % prev)
		# debout sur la table
		_poser(R.P(4.0, 6.0, 0.6), Vector3(1, 0, 0))
		await _att(1.2)
		var yt: float = (_pos() - R.P(0, 0, 0)).y
		_ok(yt > 5.6 and yt < 6.4, "on tient debout sur la table (%.2f m)" % yt)
		var manque: Array = _actes(["caresser Pompon", "écouter l'horloge", "goûter une miette", "regarder le dessin", "écharpe", "sortir"])
		_ok(manque.is_empty(), "ce qu'on fait dans la maison (manque : %s)" % str(manque))
		_ok(_anime("Balancier"), "le balancier de l'horloge bat")
		_ok(maisons_v81.room.find_child("Pompon", true, false) != null, "Pompon dort devant la cheminée")
		maisons_v81._teardown()
		await _att(0.3)
	# --- le Moulin de la Butte
	var i2: int = _indice("moulin_butte")
	var ok2: bool = false
	if i2 >= 0:
		ok2 = await _entrer(i2)
	_ok(ok2 and str(maisons_v81.ctx.get("metier", "")) == "moulin_butte", "on entre dans le Moulin de la Butte (par le trou de souris)")
	if ok2:
		_ok(await _debout("dans le moulin", 0.6), "on tient debout dans le moulin")
		var f2: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f2 != null and is_instance_valid(f2) and str(f2.npc.display_name) == "Pépin", "Pépin, le boulanger des Petits, est dans son fournil")
		if f2 != null and is_instance_valid(f2):
			_ok(_accessible(f2), "on peut aller parler à Pépin")
		_ok(_anime("Rouet") and _anime("Lanterne"), "le rouet et la lanterne tournent")
		_ok(_actes(["regarder tourner le rouet", "sortir"]).is_empty(), "ce qu'on fait dans le moulin")
		maisons_v81._teardown()
		await _att(0.3)
	# --- la nuit (les braises, la lune) : tout se construit aussi
	var tp: Node = temps_v56
	if tp != null:
		var h0: float = tp.hour
		tp.hour = 23.0
		for met in ["maison_grandpre", "moulin_butte"]:
			var i3: int = _indice(met)
			var ok3: bool = false
			if i3 >= 0:
				ok3 = await _entrer(i3)
			_ok(ok3 and not maisons_v81.R.day, "la nuit, on entre aussi : %s" % met)
			if ok3:
				maisons_v81._teardown()
				await _att(0.2)
		tp.hour = h0
	_ok(not maisons_v81.inside, "on est bien ressorti")

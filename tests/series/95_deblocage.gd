## Le héros ne reste plus coincé, V176 (les signalements : la Balafre, le village, les Moaïs, l'armoire).
## La Balafre : on entre dans l'eau sur la côte sud-est, on y nage sans à-coups ; toutes les côtes : là
## où l'eau est trop profonde pour y marcher, on peut y nager. Le village : sorti de l'eau à moitié
## sous la plage, on se dégage ; on marche dans l'eau peu profonde (plus de mur à 63 m) ; on sort de
## l'eau à la nage sans s'enfoncer. Les Moaïs : la rampe de galets est solide (on y monte). Une maison :
## pris dans l'armoire, on se dégage tout seul ; coincé dans un recoin, aussi ; « Me débloquer » (le
## menu) ; l'arrivée encombrée (le bus) ; les dormeurs n'ont plus la tête dans le mur.
const NOM := "deblocage"
const IleRef := [
	preload("res://scripts/ile_arcane_v67.gd"), preload("res://scripts/ile_pirate_v68.gd"), preload("res://scripts/ile_soleils_v69.gd"),
	preload("res://scripts/ile_braise_v70.gd"), preload("res://scripts/ile_montjoie_v71.gd"), preload("res://scripts/ile_boucan_v75.gd"),
	preload("res://scripts/ile_moai_v87.gd"), preload("res://scripts/ile_pixel_v90.gd"), preload("res://scripts/ile_larsen_v91.gd"),
	preload("res://scripts/ile_neo_v94.gd"), preload("res://scripts/ile_pasta_v97.gd"), preload("res://scripts/ile_crayon_v99.gd"),
	preload("res://scripts/ile_hautefond_v112.gd"), preload("res://scripts/ile_sombreval_v121.gd"), preload("res://scripts/ile_geants_v142.gd"),
	preload("res://scripts/grande_ile_v59.gd"), preload("res://scripts/ile_azur_v56.gd"), preload("res://scripts/ile_elfes_v41.gd"),
	preload("res://scripts/ile_nains_v46.gd")]


func _marche(face: Vector3, secs: float) -> void:
	pc_root.rotation.y = atan2(-face.x, -face.z)
	_touche(KEY_Z, true)
	await _att(secs)
	_touche(KEY_Z, false)
	await _att(0.2)


func _plat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Toutes les côtes : là où l'eau est trop profonde pour y marcher (plus de 0,9 m), on doit pouvoir
## nager ; là où l'on a pied, marcher. Renvoie les endroits fautifs (au plus 6).
func _cotes() -> Array:
	var faux: Array = []
	var carres: Array = [[Vector3(0, 0, 0), 150.0]]
	for S in IleRef:
		var cm: Dictionary = S.get_script_constant_map()
		if cm.has("CENTER") and cm.has("HALF"):
			carres.append([cm["CENTER"], float(cm["HALF"])])
	var n: int = 0
	for c in carres:
		var ce: Vector3 = c[0]
		var hf: float = c[1]
		var x: float = ce.x - hf
		while x <= ce.x + hf:
			var z: float = ce.z - hf
			while z <= ce.z + hf:
				var h: float = _height_at(x, z)
				if h < -0.5 and h > -5.0 and absf(mer_v55.niveau(Vector3(x, h, z)) - mer_v55.SEA_Y) < 0.01:
					n += 1
					var p := Vector3(x, h + 0.05, z)
					var ok: bool = mer_v55.in_world(p) if h <= -1.3 else pied_ok_v176(p)
					# (la sauce d'Al Dente, qui coule jusqu'à la mer, brûle : on n'y marche pas, exprès)
					if not ok and pasta_v97 != null and pasta_v97.contains(p) and pasta_v97.in_sauce(p):
						ok = true
					if not ok and faux.size() < 6:
						faux.append("(%.0f, %.0f) fond %.1f" % [x, z, h])
					elif not ok:
						faux.append("…")
				z += 5.0
			x += 5.0
	print("  côtes : %d points d'eau peu profonde regardés" % n)
	return faux


func _serie() -> void:
	var D: Node = deblocage_v176
	_ok(D != null, "le déblocage du héros est là")
	if D == null:
		return
	# --- toutes les côtes
	var faux: Array = _cotes()
	_ok(faux.is_empty(), "sur toutes les côtes, on entre dans l'eau (à pied, puis à la nage) %s" % ("" if faux.is_empty() else str(faux.slice(0, 7))))
	# --- la Balafre : la côte sud-est (l'endroit exact où l'on n'entrait pas dans l'eau)
	var b2 := Vector3(603.9, 0.0, -585.8)
	var dep := Vector3(b2.x - 6.0, 0, b2.z)
	dep.y = _height_at(dep.x, dep.z) + 0.2
	await _poser(dep, Vector3(1, 0, 0))
	await _att(0.6)
	var p0: Vector3 = _pos()
	await _marche(Vector3(1, 0, 0), 7.0)
	var p1: Vector3 = _pos()
	_ok(p1.x > b2.x + 4.0, "la Balafre : on entre dans l'eau sur la côte sud-est (%.1f m)" % (p1.x - p0.x))
	# la nage le long du bord de l'ancienne mer (on y nageait par à-coups)
	var b1 := Vector3(574.2, 0.0, -547.2)
	var f1 := Vector3(1, 0, 1).normalized()
	var dn: Vector3 = b1 - f1 * 8.0
	await _poser(Vector3(dn.x, -1.8, dn.z), f1)
	await _att(0.5)
	_ok(str(hero_v28.state) == "nage", "la Balafre : on nage au large du rivage (%s)" % str(hero_v28.state))
	var q0: Vector3 = _pos()
	pc_root.rotation.y = atan2(-f1.x, -f1.z)
	_touche(KEY_Z, true)
	var recul: int = 0
	var prev: Vector3 = q0
	for k in range(30):
		await _att(0.2)
		var q: Vector3 = _pos()
		if (q - prev).dot(f1) < -0.02:
			recul += 1
		prev = q
	_touche(KEY_Z, false)
	await _att(0.2)
	var q1: Vector3 = _pos()
	_ok((q1 - q0).dot(f1) > 8.0 and recul == 0, "la Balafre : on nage tout droit, sans à-coups (%.1f m, %d reculs)" % [(q1 - q0).dot(f1), recul])
	# --- le village : le héros sorti de l'eau à moitié sous la plage (là où il restait collé)
	var v := Vector3(-57.2, -1.0, -25.9)
	await _poser(v, Vector3(0, 0, 1))
	var n0: int = D.degages
	await _att(1.5)
	var pv: Vector3 = _pos()
	_ok(D.degages > n0 and pv.y > _height_at(pv.x, pv.z) - 0.1 and not D.pris(pv), "le village : enfoncé sous la plage, le héros se dégage tout seul (%.2f, sol %.2f)" % [pv.y, _height_at(pv.x, pv.z)])
	await _marche(Vector3(1, 0, 0.3), 1.2)
	_ok(_plat(_pos(), pv) > 1.5, "le village : on repart (%.1f m)" % _plat(_pos(), pv))
	# on marche dans l'eau peu profonde, vers le large (plus de mur rond à 63 m)
	var pw: Vector3 = Vector3(-58.0, 0, -25.0)
	pw.y = _height_at(pw.x, pw.z) + 0.1
	await _poser(pw, Vector3(-1, 0, -0.4))
	await _att(0.4)
	var w0: Vector3 = _pos()
	await _marche(Vector3(-1, 0, -0.4), 3.0)
	_ok(Vector2(_pos().x, _pos().z).length() > 64.5, "le village : on avance dans l'eau peu profonde (%.1f m du centre)" % Vector2(_pos().x, _pos().z).length())
	# on revient à la nage vers la plage : on reprend pied sans s'enfoncer dans le sable (on part du
	# premier endroit, vers le large, où l'on nage)
	var plage := Vector3(-57.2, 0, -25.9)
	var vl: Vector3 = Vector3(-57.2, 0, -25.9).normalized()
	var large: Vector3 = plage
	for k in range(60):
		large = plage + vl * float(k)
		if mer_v55.niveau(large) - _height_at(large.x, large.z) > 2.0:
			break
	large.y = mer_v55.SEA_Y - 1.4
	await _poser(large, -vl)
	await _att(0.6)
	_ok(str(hero_v28.state) == "nage", "le village : au large de la plage, on nage (%s, à %.0f m du bord)" % [str(hero_v28.state), _plat(large, plage)])
	_touche(KEY_Z, true)
	pc_root.rotation.y = atan2(vl.x, vl.z)
	var pire: float = 0.0
	for k in range(75):
		await _att(0.2)
		var q2: Vector3 = _pos()
		pire = maxf(pire, _height_at(q2.x, q2.z) - q2.y)
		if str(hero_v28.state) == "sol" and _plat(q2, large) > 3.0:
			break
	_touche(KEY_Z, false)
	await _att(0.3)
	_ok(str(hero_v28.state) == "sol" and pire < 0.15 and not D.pris(_pos()), "le village : à la nage vers la plage, on reprend pied sans s'enfoncer (%s, %.2f m sous le sable au pire)" % [str(hero_v28.state), pire])
	# --- les Moaïs : la rampe de galets devant l'ahu du levant
	var m := Vector3(50.4, 11.6, -820.5)
	m.y = _height_at(m.x, m.z) + 0.1
	await _poser(m, Vector3(1, 0, 0))
	await _att(0.5)
	var ym: float = _pos().y
	await _marche(Vector3(1, 0, 0), 2.5)
	_ok(_pos().y > ym + 0.5, "les Moaïs : on monte la rampe de galets (+%.2f m)" % (_pos().y - ym))
	var hr: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(m.x + 0.6, m.y + 4.0, m.z), Vector3(m.x + 0.6, m.y - 2.0, m.z), 1))
	_ok(not hr.is_empty() and float((hr["position"] as Vector3).y) > m.y + 0.1, "les Moaïs : la rampe est solide (les bêtes ne passent plus au travers)")
	# --- coincé dans un recoin : quatre planches autour du héros (il y tient, sans y toucher) ; on pousse
	# en tous sens sans avancer : il se dégage, hors du recoin
	var c0 := Vector3(-53.5, 0, -26.0)
	c0.y = _height_at(c0.x, c0.z) + 0.05
	await _poser(c0, Vector3(0, 0, -1))
	await _att(0.5)
	c0 = _pos()
	var cage := StaticBody3D.new()
	cage.collision_layer = 1
	add_child(cage)
	cage.global_position = c0
	for e in [[Vector3(0.47, 1.0, 0), Vector3(0.1, 2.4, 1.05)], [Vector3(-0.47, 1.0, 0), Vector3(0.1, 2.4, 1.05)], [Vector3(0, 1.0, 0.47), Vector3(1.05, 2.4, 0.1)], [Vector3(0, 1.0, -0.47), Vector3(1.05, 2.4, 0.1)]]:
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = e[1]
		cs.shape = bx
		cs.position = e[0]
		cage.add_child(cs)
	await _att(0.3)
	var n3: int = D.degages
	_touche(KEY_Z, true)
	for k in range(40):
		pc_root.rotation.y += 0.45
		await _att(0.1)
		if D.degages > n3:
			break
	_touche(KEY_Z, false)
	await _att(0.3)
	_ok(D.degages > n3 and _plat(_pos(), c0) > 0.6 and D.libre(_pos()), "coincé dans un recoin (on pousse en tous sens sans avancer), on se dégage (%.1f m)" % _plat(_pos(), c0))
	cage.queue_free()
	await _att(0.2)
	# --- dans une maison : l'armoire du dormeur
	_ranger()
	await _images(2)
	testeur_v78._visit("dormeur")
	await _att(0.3)
	for k in range(40):
		if not maisons_v81.busy:
			break
		await _att(0.1)
	_ok(maisons_v81.inside, "on entre chez le dormeur")
	if maisons_v81.inside:
		var R = maisons_v81.R
		var hw: float = R.W * 0.5
		var hd: float = R.D * 0.5
		await _att(0.8)
		# sa tête est dans la pièce (avant : dans le mur)
		var tete: bool = true
		for f in maisons_v81.people:
			var sk: Skeleton3D = f.npc.get("skel")
			if sk != null and sk.find_bone("Head") >= 0:
				var hp: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin - R.P(0, 0, 0)
				if absf(hp.x) > hw - 0.2 or absf(hp.z) > hd - 0.2:
					tete = false
		_ok(tete, "le dormeur a la tête sur l'oreiller, pas dans le mur")
		# coincé entre l'armoire (contre le mur de droite) et une caisse, dans un passage trop étroit : on
		# se dégage tout seul, et l'on reste dans la pièce
		var fa: float = hw - 0.35 - 0.275
		var caisse := StaticBody3D.new()
		caisse.collision_layer = 1
		maisons_v81.room.add_child(caisse)
		var csx := CollisionShape3D.new()
		var bxx := BoxShape3D.new()
		bxx.size = Vector3(0.5, 1.2, 1.2)
		csx.shape = bxx
		caisse.add_child(csx)
		caisse.global_position = R.P(fa - 0.4 - 0.25, 0.6, -hd * 0.35)
		await _att(0.2)
		var arm: Vector3 = R.P(fa - 0.2, 0.02, -hd * 0.35)
		await _poser(arm, Vector3(-1, 0, 0))
		var n1: int = D.degages
		await _att(1.5)
		var pa: Vector3 = _pos() - R.P(0, 0, 0)
		_ok(D.degages > n1 and not D.pris(_pos()) and D.libre(_pos()) and absf(pa.x) < hw and absf(pa.z) < hd and absf(pa.y) < 0.3, "coincé entre l'armoire et une caisse, on se dégage tout seul, dans la pièce, sur le plancher (%.1f, %.1f, %.1f)" % [pa.x, pa.y, pa.z])
		caisse.queue_free()
		await _marche(Vector3(-1, 0, 0.2), 1.0)
		_ok(_plat(_pos(), arm) > 1.0, "et l'on repart")
		# « Me débloquer » (le menu) : on repart d'une place libre, un peu plus loin
		game_menu.open_menu()
		await _att(0.2)
		_ok(game_menu.options.has("Me débloquer"), "le menu propose « Me débloquer »")
		var pm: Vector3 = _pos()
		var im: int = game_menu.options.find("Me débloquer")
		if im >= 0:
			game_menu._activate(im)
		await _att(0.4)
		_ok(not game_menu.opened and _plat(_pos(), pm) > 0.85 and D.libre(_pos()), "« Me débloquer » : on repart d'une place libre (%.1f m plus loin)" % _plat(_pos(), pm))
		# coincé dans un recoin (on pousse en tous sens, on n'avance pas) : on se dégage aussi
		var coin: Vector3 = R.P(-hw + 0.33, 0.02, hd - 0.33)
		await _poser(coin, Vector3(-1, 0, 0))
		await _att(0.3)
		var n2: int = D.degages
		# on ne fait que pousser contre le mur : on ne bouge pas le héros pour si peu
		await _marche(Vector3(-1, 0, 0), 3.2)
		_ok(D.degages == n2, "pousser contre un mur, ce n'est pas être coincé")
		maisons_v81._teardown()
		await _att(0.3)
	# --- l'arrivée encombrée : le bus (le tableau de bord)
	var ib: int = -1
	for i in range(maisons_v81.portes.size()):
		if str(maisons_v81.portes[i].get("metier", "")) == "bus_soleil":
			ib = i
	if ib >= 0:
		_ranger()
		var pb: Dictionary = maisons_v81.portes[ib]
		place_player_v35((pb["door"] as Vector3) + Vector3.UP * 0.1, -(pb["out"] as Vector3))
		await _att(0.3)
		maisons_v81.enter(ib)
		for k in range(50):
			await _att(0.1)
			if maisons_v81.inside and not maisons_v81.busy:
				break
		await _att(0.3)
		_ok(maisons_v81.inside and D.libre(_pos()), "dans le bus, on arrive à une place libre (plus dans le tableau de bord)")
		maisons_v81._teardown()
		await _att(0.3)
	_ok(not maisons_v81.inside, "on est bien ressorti")

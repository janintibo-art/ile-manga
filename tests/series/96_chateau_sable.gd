## Le château de sable de Pâquerette, V177 (l'Île des Géants). Dehors : la motte de sable est solide
## (on ne s'y enfonce plus) et se monte depuis la grève ; la porte du rempart est ouverte ; on marche de
## la plage jusqu'à la porte du donjon ; on fait le tour du donjon par la cour. Dedans : on entre, on
## tient debout ; Firmin, le gardien, et l'on peut aller lui parler ; l'escalier taillé dans le mur, des
## marches de moins de 0,42 m, et on le monte pour de vrai jusqu'à la galerie ; debout devant la
## meurtrière ; ce qu'on y fait ; Sire Bernard rentre dans sa coquille quand on approche ; le sablier se
## retourne ; on ressort devant la porte, libre ; la nuit, les bougies.
const NOM := "chateau177"
const Ile := preload("res://scripts/ile_geants_v142.gd")
const Kit := preload("res://scripts/geants_kit_v142.gd")
const L174 := preload("res://scripts/lieux_v174.gd")


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


func _plat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Marcher en ligne droite vers un point (au plus « secs ») ; vrai si l'on y arrive.
func _aller(vers: Vector3, secs: float, pres: float = 0.8) -> bool:
	var t: float = 0.0
	_touche(KEY_Z, true)
	while t < secs:
		var f: Vector3 = vers - _pos()
		f.y = 0.0
		if f.length() < pres:
			break
		f = f.normalized()
		pc_root.rotation.y = atan2(-f.x, -f.z)
		await _att(0.1)
		t += 0.1
	_touche(KEY_Z, false)
	await _att(0.3)
	return _plat(_pos(), vers) < pres + 0.3


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


func _serie() -> void:
	await _att(5.5)
	var g: Node = geants_v142
	if g == null or not (g.get("reperes") is Dictionary) or not (g.reperes as Dictionary).has("chateau"):
		_ok(false, "le château de sable de Pâquerette est construit")
		return
	var ch: Dictionary = g.reperes["chateau"]
	var porte: Vector3 = ch["porte"]
	var centre: Vector3 = ch["centre"]
	var D = deblocage_v176
	# --- dehors : la porte du donjon est connue
	var i0: int = _indice("donjon_paquerette")
	_ok(i0 >= 0 and (maisons_v81.portes[i0]["door"] as Vector3).distance_to(porte) < 0.3, "la porte du donjon est devant le donjon")
	_ok(absf(_plat(porte, centre) - (Kit.DONJON_R0 + 0.5)) < 0.3, "la porte est au pied du donjon (%.1f m du milieu)" % _plat(porte, centre))
	# --- la motte est solide : posé dessus, on reste dessus (avant : on s'y enfonçait jusqu'aux yeux)
	_ranger()
	var cour: Vector3 = centre + Vector3(5.2, 0.0, 0.0)
	_poser(cour + Vector3.UP * 0.6, Vector3(0, 0, 1))
	await _att(1.0)
	_ok(_pos().y > centre.y - 0.15 and _pos().y < centre.y + 0.4, "debout sur la motte, dans la cour (%.2f m au-dessus du haut de la motte)" % (_pos().y - centre.y))
	var flanc: Vector3 = centre + Vector3(-15.0, 0, 6.0)
	_poser(Vector3(flanc.x, centre.y + 3.0, flanc.z), Vector3(1, 0, 0))
	await _att(1.2)
	var attendu: float = centre.y - (Vector2(-15.0, 6.0).length() - Kit.MOTTE_R1) * (2.0 + Kit.MOTTE_BAS) / (Kit.MOTTE_R0 - Kit.MOTTE_R1)
	var sol: float = maxf(attendu, main_height_ok(flanc))
	_ok(_pos().y > sol - 0.25, "debout sur le flanc de la motte (%.2f m ; la pente : %.2f)" % [_pos().y, attendu])
	# --- la cour : la porte du rempart est ouverte, on fait le tour du donjon
	var libres: int = 0
	for k in range(16):
		var a: float = TAU * k / 16.0
		var q: Vector3 = centre + Vector3(cos(a), 0, sin(a)) * (Kit.DONJON_R0 + 0.78)
		if D.libre(q):
			libres += 1
	_ok(libres == 16, "on fait le tour du donjon par la cour (%d places libres sur 16)" % libres)
	var pr: Vector3 = ch["porte_rempart"]
	_ok(D.libre(pr) and D.libre(pr + Vector3(0, 0, -0.8)), "la porte du rempart est ouverte")
	_ok(not D.libre(pr + Vector3(2.4, 0, 0)) and not D.libre(pr + Vector3(-2.4, 0, 0)), "le rempart tient, de part et d'autre de la porte")
	# --- de la grève jusqu'à la porte du donjon, à pied
	_ranger()
	var greve: Vector3 = centre + Vector3(0, 0, -24.0)
	greve.y = geants_v142.ile.height(greve.x, greve.z) + 0.3
	_poser(greve, Vector3(0, 0, 1))
	await _att(0.8)
	var ok_g: bool = await _aller(Vector3(centre.x, centre.y, centre.z - 9.0), 14.0, 0.7)
	ok_g = ok_g and await _aller(porte, 8.0, 0.6)
	_ok(ok_g and absf(_pos().y - centre.y) < 0.35, "de la grève, par la motte et la porte du rempart, jusqu'à la porte du donjon (%.1f m de la porte ; %.2f m)" % [_plat(_pos(), porte), _pos().y - centre.y])
	_ok(maisons_v81.nearest(_pos(), 1.8) == i0, "devant la porte : « entrer dans le donjon »")
	# --- dedans
	var ok: bool = await _entrer(i0)
	_ok(ok and str(maisons_v81.ctx.get("metier", "")) == "donjon_paquerette", "on entre dans le donjon du château de sable")
	if ok:
		var R = maisons_v81.R
		_ok(await _debout("dans le donjon", 0.6), "on tient debout dans le donjon")
		_ok(not D.pris(_pos()), "on n'arrive pas pris dans le décor")
		var f: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f != null and is_instance_valid(f) and str(f.npc.display_name) == "Firmin", "Firmin, le gardien, habite le donjon")
		if f != null and is_instance_valid(f):
			var fp: Vector3 = (f.npc as Node3D).global_position
			_ok(_voie_libre(R.P(0.0, 0.0, R.D * 0.5 - 1.1), fp + (R.P(0, 0, 0) - fp).normalized() * 1.0), "on peut aller parler à Firmin")
		# l'escalier taillé dans le mur : des marches de moins de 0,42 m, du sol à la galerie
		# (le rayon part juste au-dessus de la marche : au pied de l'escalier, la galerie passe au-dessus)
		var prev: float = _haut(L174._dj(30.0, 3.25).x, L174._dj(30.0, 3.25).z, 1.0)
		var pire: float = 0.0
		var a2: float = 30.0
		while a2 < 165.0:
			var q2: Vector3 = L174._dj(a2, 3.25)
			var h: float = _haut(q2.x, q2.z, L174._dj_marche(a2) + 1.0)
			pire = maxf(pire, h - prev)
			prev = h
			a2 += 1.0
		_ok(pire <= 0.42, "l'escalier : des marches de moins de 0,42 m (la plus haute : %.2f m)" % pire)
		_ok(absf(prev - L174.DJ_GAL) < 0.1, "l'escalier mène à la galerie (%.2f m)" % prev)
		# on le monte pour de vrai (en suivant le mur)
		var bas: Vector3 = L174._dj(28.0, 3.3)
		_poser(R.P(bas.x, 0.1, bas.z), Vector3(1, 0, 0))
		await _att(0.5)
		_touche(KEY_Z, true)
		var t: float = 0.0
		while t < 30.0:
			var l: Vector3 = _pos() - R.P(0, 0, 0)
			var al: float = fposmod(rad_to_deg(atan2(l.x, l.z)), 360.0)
			if al > 175.0 and al < 300.0:
				break
			var cible: Vector3 = L174._dj(al + 12.0, 3.3)
			var fd: Vector3 = Vector3(cible.x - l.x, 0, cible.z - l.z).normalized()
			pc_root.rotation.y = atan2(-fd.x, -fd.z)
			await _att(0.1)
			t += 0.1
		_touche(KEY_Z, false)
		await _att(0.5)
		var yg: float = (_pos() - R.P(0, 0, 0)).y
		_ok(yg > L174.DJ_GAL - 0.15 and yg < L174.DJ_GAL + 0.4, "on monte l'escalier jusqu'à la galerie (%.2f m, en %.0f s)" % [yg, t])
		# debout sur la galerie, devant la meurtrière
		var me: Vector3 = L174._dj(0.0, 3.2)
		_poser(R.P(me.x, L174.DJ_GAL + 0.5, me.z), Vector3(0, 0, 1))
		await _att(1.0)
		var ym: float = (_pos() - R.P(0, 0, 0)).y
		_ok(absf(ym - L174.DJ_GAL) < 0.2, "debout sur la galerie, devant la meurtrière (%.2f m)" % ym)
		_ok(not D.pris(_pos()), "devant la meurtrière, on n'est pas pris dans le décor")
		var manque: Array = _actes(["écouter la mer dans le grand coquillage", "regarder la mer par la meurtrière", "lire l'ardoise des marées",
			"retourner le sablier", "dire bonjour à Sire Bernard", "compter les coquillages", "regarder la cuillère", "regarder le trésor", "sortir"])
		_ok(manque.is_empty(), "ce qu'on fait dans le donjon (manque : %s)" % str(manque))
		_ok(int(maisons_v81.ctx.get("coquillages177", 0)) >= 50, "les coquillages de Pâquerette, dans le mur (%d)" % int(maisons_v81.ctx.get("coquillages177", 0)))
		# Sire Bernard rentre dans sa coquille quand on approche
		var b: Dictionary = maisons_v81.ctx.get("bernard177", {})
		if not b.is_empty() and is_instance_valid(b["n"]):
			var bn: Node3D = b["n"]
			var vers: Vector3 = (R.P(0, 0, 0) - bn.global_position)
			vers.y = 0.0
			_poser(bn.global_position + vers.normalized() * 0.9 + Vector3.UP * 0.1, -vers)
			await _att(0.8)
			_ok((b["corps"] as Node3D).scale.x < 0.4, "Sire Bernard rentre dans sa coquille quand on approche")
			_poser(R.P(0.0, 0.1, 0.3), Vector3(0, 0, 1))
			b["cache"] = 0.0
			await _att(3.5)
			_ok((b["corps"] as Node3D).scale.x > 0.8, "puis il ressort")
		else:
			_ok(false, "Sire Bernard est là")
		# le sablier se retourne
		var sb: Dictionary = maisons_v81.ctx.get("sablier177", {})
		for it in maisons_v81._its:
			if str(it.get("text", "")).contains("retourner le sablier"):
				(it["call"] as Callable).call()
		await _att(1.2)
		_ok(not sb.is_empty() and absf(fposmod((sb["n"] as Node3D).rotation.x, TAU) - PI) < 0.05, "le sablier se retourne")
		# on ressort : devant la porte, libre, sur la motte
		_close_dialogue_v31()
		maisons_v81.leave()
		for k in range(30):
			await _att(0.1)
			if not maisons_v81.inside and not maisons_v81.busy:
				break
		await _att(0.6)
		_ok(not maisons_v81.inside and _plat(_pos(), porte) < 0.8 and absf(_pos().y - centre.y) < 0.35, "on ressort devant la porte du donjon, sur la motte")
		_ok(not D.pris(_pos()) and D.libre(_pos()), "dehors, on est libre")
	# --- la nuit : les bougies d'anniversaire
	var tp: Node = temps_v56
	if tp != null:
		var h0: float = tp.hour
		tp.hour = 23.0
		var ok3: bool = await _entrer(i0)
		_ok(ok3 and not maisons_v81.R.day and (maisons_v81.R.flames as Array).size() >= 3, "la nuit, on entre aussi : les bougies sont allumées (%d flammes)" % ((maisons_v81.R.flames as Array).size() if ok3 else 0))
		if ok3:
			maisons_v81._teardown()
			await _att(0.2)
		tp.hour = h0
	_ranger()
	_ok(not maisons_v81.inside, "on est bien ressorti")


## La hauteur du sol (le relief seul) sous un point.
func main_height_ok(p: Vector3) -> float:
	return geants_v142.ile.height(p.x, p.z)

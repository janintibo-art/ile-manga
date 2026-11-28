## La veille, V218 (veille_v218.gd) : ce qui est loin du joueur ne travaille plus à chaque image. Les
## habitants endormis (loin) ou rentrés chez eux passent « au ralenti » (visités deux fois par seconde) ;
## leur agenda continue ; ils repassent à chaque image AVANT leur distance de veille (ils apparaissent donc
## comme avant) ; on peut leur parler dès qu'on arrive ; ce que les autres morceaux du jeu coupent (un
## compagnon de route, l'arène) reste coupé. Les particules lointaines sont calculées moins souvent, plus du
## tout hors de leur portée d'affichage, et reprennent à l'approche. Les points d'interaction : la liste
## courte donne la même réponse que la liste entière. Le contrôle des îles aériennes suit le regard.
const NOM := "31_veille"


func _eligibles218v() -> int:
	var n218v: int = 0
	for npc218v in npcs_v31:
		if is_instance_valid(npc218v) and (npc218v as Node).has_method("ralenti_ok_v218") and bool(npc218v.ralenti_ok_v218()):
			n218v += 1
	return n218v


func _caches218v() -> int:
	var n218v: int = 0
	for npc218v in npcs_v31:
		if is_instance_valid(npc218v) and npc218v.get("hidden_home") == true:
			n218v += 1
	return n218v


## Pose le joueur au sol à cette distance de l'habitant (on essaie huit directions : un sol hors de l'eau,
## à peu près à la hauteur de l'habitant). Vrai si un endroit a été trouvé.
func _a_distance218v(c: Vector3, dist: float) -> bool:
	for k218v in 8:
		var a218v: float = TAU * float(k218v) / 8.0
		var dir218v: Vector3 = Vector3(cos(a218v), 0.0, sin(a218v))
		var q218v: Vector3 = c + dir218v * dist
		var h218v: float = _height_at(q218v.x, q218v.z)
		if h218v > 0.3 and absf(h218v - c.y) < 2.5:
			place_player_v35(Vector3(q218v.x, h218v + 0.2, q218v.z), -dir218v)
			return true
	return false


func _serie() -> void:
	var v218v: Node = veille_v218
	_ok(v218v != null, "la veille existe")
	if v218v == null:
		return
	# --- 1. au large, loin de toutes les villes : presque tout le monde passe au ralenti
	temps_v56.set_hour(12.0)
	await _poser(Vector3(238.0, 2.0, 1484.0))
	await _att(4.0)
	var total218v: int = npcs_v31.size()
	var lents218v: int = v218v.lents.size()
	_ok(total218v > 300, "le monde a ses habitants (%d)" % total218v)
	_ok(lents218v > total218v / 2, "loin de tout, la plupart des habitants sont au ralenti (%d sur %d)" % [lents218v, total218v])
	var coherent218v: bool = true
	var arretes218v: int = 0
	for npc218v in npcs_v31:
		if not is_instance_valid(npc218v):
			continue
		var nn218v: Node = npc218v
		var lent218v: bool = v218v.lents.has(nn218v.get_instance_id())
		if lent218v != (nn218v.process_mode == Node.PROCESS_MODE_DISABLED):
			coherent218v = _note(false, "%s : au ralenti %s, mode de calcul %d" % [str(nn218v.name), str(lent218v), nn218v.process_mode])
		if not nn218v.can_process():
			arretes218v += 1
	_ok(coherent218v, "au ralenti = calculs arrêtés par le moteur, et seulement ceux-là")
	_ok(v218v.eveilles.size() + lents218v == total218v, "chaque habitant est soit éveillé, soit au ralenti (%d + %d = %d)" % [v218v.eveilles.size(), lents218v, total218v])
	var vis0_218v: int = v218v.visites
	await _att(2.5)
	_ok(v218v.visites - vis0_218v > lents218v / 2, "la veille les visite (%d visites en 2,5 s pour %d habitants)" % [v218v.visites - vis0_218v, lents218v])
	_ok(v218v.visites - vis0_218v < lents218v * 7, "… sans les appeler à chaque image (%d visites en 2,5 s)" % (v218v.visites - vis0_218v))
	# --- 2. leur agenda continue : la nuit ils rentrent, le jour ils sortent, même loin du joueur
	temps_v56.set_hour(2.5)
	await _att(6.0)
	var nuit218v: int = _caches218v()
	temps_v56.set_hour(12.0)
	await _att(6.0)
	var jour218v: int = _caches218v()
	_ok(nuit218v > 60 and jour218v < nuit218v * 2 / 3, "au ralenti, l'agenda continue : %d rentrés chez eux à 2 h 30, %d à midi" % [nuit218v, jour218v])
	# --- 3. un habitant endormi loin : il repasse à chaque image avant sa distance de veille, et ne se montre
	#        qu'à cette distance, comme avant (on essaie des habitants jusqu'à en trouver un au bord duquel on
	#        peut se tenir, sur un sol dégagé, à la bonne distance)
	var cible218v: Node3D = null
	var seuil218v: bool = false
	var essayes218v: int = 0
	for npc4_218v in npcs_v31:
		if seuil218v or essayes218v >= 30:
			break
		if not is_instance_valid(npc4_218v):
			continue
		var c218v: Node3D = npc4_218v
		if not v218v.lents.has(c218v.get_instance_id()) or c218v.get("hidden_home") == true or c218v.get("_asleep") != true or not c218v.is_visible_in_tree():
			continue
		if str(c218v.get("state")) != "repos" or float(c218v.get("sleep_far")) < 30.0 or c218v.global_position.y < 0.5 or c218v.global_position.y > 60.0:
			continue
		var veille218v: float = float(c218v.get("sleep_far"))
		var cp218v: Vector3 = c218v.global_position
		if not _a_distance218v(cp218v, veille218v + 3.0):
			continue
		essayes218v += 1
		cible218v = c218v
		await _att(1.5)
		var d1_218v: float = c218v.global_position.distance_to(_pos())
		if d1_218v > veille218v + 0.5 and d1_218v < veille218v + 5.5 and c218v.get("hidden_home") != true and str(c218v.get("state")) == "repos":
			seuil218v = true
			_ok(not v218v.lents.has(c218v.get_instance_id()) and c218v.process_mode == Node.PROCESS_MODE_INHERIT, "%s, à %.1f m (sa veille : %.0f m) : il est de nouveau appelé à chaque image" % [str(c218v.get("display_name")), d1_218v, veille218v])
			_ok(c218v.get("_asleep") == true and not (c218v.get("model") as Node3D).visible, "… mais ne se montre pas encore (comme avant la V218)")
			if _a_distance218v(cp218v, veille218v - 8.0):
				await _att(1.0)
				var d2_218v: float = c218v.global_position.distance_to(_pos())
				if d2_218v < veille218v - 0.5 and c218v.get("hidden_home") != true:
					_ok(c218v.get("_asleep") != true and (c218v.get("model") as Node3D).visible, "à %.1f m : il est réveillé, on le voit" % d2_218v)
		# (retour au large avant l'essai suivant : tout le monde se rendort)
		await _poser(Vector3(238.0, 2.0, 1484.0))
		await _att(2.5)
	_ok(seuil218v, "le seuil de veille a pu être essayé sur un habitant (%d essayés)" % essayes218v)
	_ok(cible218v != null, "un habitant endormi, dehors, au ralenti")
	if cible218v != null:
		# --- 4. on arrive d'un coup à côté de lui : on peut lui parler tout de suite
		await _poser(Vector3(238.0, 2.0, 1484.0))
		await _att(3.0)
		var etait218v: bool = v218v.lents.has(cible218v.get_instance_id())
		var face218v: Vector3 = cible218v.global_position + Vector3(1.4, 0.0, 0.0)
		place_player_v35(Vector3(face218v.x, cible218v.global_position.y + 0.2, face218v.z), Vector3(-1, 0, 0))
		await _att(0.6)
		var pres218v: Node3D = _nearest_npc_v31()
		_ok(pres218v != null, "arrivé d'un coup à côté d'un habitant %s : on peut parler (à %s)" % ["qui était au ralenti" if etait218v else "", str(pres218v.get("display_name")) if pres218v != null else "personne"])
		_ok(not v218v.lents.has(cible218v.get_instance_id()) or cible218v.get("hidden_home") == true, "il n'est plus au ralenti")
	# --- 5. ce qu'un autre morceau du jeu coupe (un compagnon de route, l'arène) reste coupé
	await _poser(Vector3(238.0, 2.0, 1484.0))
	await _att(4.0)
	var autre218v: Node3D = null
	for id2_218v in v218v.lents:
		var e2_218v: Array = v218v.lents[id2_218v]
		if is_instance_valid(e2_218v[0]) and (e2_218v[0] as Node).get("hidden_home") != true:
			autre218v = e2_218v[0]
			break
	_ok(autre218v != null, "un autre habitant au ralenti")
	if autre218v != null:
		autre218v.set_process(false)
		await _att(3.0)
		_ok(not v218v.lents.has(autre218v.get_instance_id()) and autre218v.process_mode == Node.PROCESS_MODE_INHERIT, "un habitant dont on coupe les calculs (comme un compagnon de route) : la veille ne s'en occupe plus")
		_ok(not autre218v.is_processing(), "… et ne les rallume pas")
		autre218v.set_process(true)
		await _att(3.5)
		_ok(v218v.lents.has(autre218v.get_instance_id()), "rendu au jeu, il repasse au ralenti (il dort toujours loin)")
	# --- 6. si l'on coupe la veille, tout le monde revient à chaque image
	v218v.actif = false
	v218v.tout_reveiller()
	var reste218v: int = 0
	for npc3_218v in npcs_v31:
		if is_instance_valid(npc3_218v) and (npc3_218v as Node).process_mode == Node.PROCESS_MODE_DISABLED:
			reste218v += 1
	_ok(v218v.lents.is_empty() and reste218v == 0, "la veille coupée : plus personne au ralenti")
	v218v.actif = true
	await _att(3.0)
	_ok(v218v.lents.size() > total218v / 2, "la veille remise : ils y repassent (%d)" % v218v.lents.size())
	# --- 7. les particules
	var grains218v: Array = v218v.grains
	_ok(grains218v.size() > 100, "les particules du monde sont suivies (%d)" % grains218v.size())
	_ok(v218v.grains_arretes + v218v.grains_ralentis > grains218v.size() / 2, "loin du joueur : %d ne sont plus calculées, %d le sont moins souvent" % [v218v.grains_arretes, v218v.grains_ralentis])
	var pres_ok218v: bool = true
	var loin218v: CPUParticles3D = null
	for g218v in grains218v:
		if not is_instance_valid(g218v[0]) or not (g218v[0] as Node).is_inside_tree():
			continue
		var pt218v: CPUParticles3D = g218v[0]
		var dg218v: float = pt218v.global_position.distance_to(_pos())
		if dg218v < 100.0 and int(g218v[2]) != 0:
			pres_ok218v = _note(false, "%s à %.0f m est au palier %d" % [str(pt218v.name), dg218v, int(g218v[2])])
		if int(g218v[2]) == v218v.GRAINS_ARRET and int(g218v[1]) >= 0 and pt218v.emitting and pt218v.is_visible_in_tree() and loin218v == null:
			loin218v = pt218v
	_ok(pres_ok218v, "près du joueur (moins de 100 m), elles sont calculées à chaque image, comme avant")
	_ok(loin218v != null, "des particules hors de portée, arrêtées")
	if loin218v != null:
		_ok(not loin218v.is_processing_internal(), "arrêtées : le moteur ne les calcule plus")
		place_player_v35(loin218v.global_position + Vector3(3.0, 1.0, 0.0), Vector3(-1, 0, 0))
		await _att(1.2)
		var palier218v: int = -1
		var origine218v: int = -1
		for g2_218v in v218v.grains:
			if g2_218v[0] == loin218v:
				palier218v = int(g2_218v[2])
				origine218v = int(g2_218v[1])
		_ok(palier218v == 0 and loin218v.is_processing_internal() and loin218v.fixed_fps == origine218v, "on arrive à côté : elles reprennent à plein rythme (palier %d)" % palier218v)
	# --- 8. les points d'interaction : la liste courte répond comme la liste entière
	var pareil218v: bool = true
	var essais218v: int = 0
	var pas218v: int = maxi(donjon_v35._interactions.size() / 120, 1)
	for i218v in range(0, donjon_v35._interactions.size(), pas218v):
		var it218v: Dictionary = donjon_v35._interactions[i218v]
		var q218v: Vector3 = it218v["pos"]
		if q218v.y < -400.0:
			continue
		essais218v += 1
		var exact218v: Dictionary = donjon_v35._current(q218v, true)
		var court218v: Dictionary = donjon_v35._current(q218v)
		if str(exact218v.get("id", "")) != str(court218v.get("id", "")):
			pareil218v = _note(false, "au point « %s » : la liste entière dit « %s », la liste courte « %s »" % [str(it218v.get("id", "")), str(exact218v.get("id", "")), str(court218v.get("id", ""))])
	_ok(pareil218v and essais218v > 50, "les points d'interaction : même réponse qu'avant en %d endroits (%d points dans le monde)" % [essais218v, donjon_v35._interactions.size()])
	# --- 9. le contrôle des îles aériennes suit le regard : immobile, le petit contrôle de fond seulement
	if cache_v215 != null and cache_v215.pret:
		await _poser(Vector3(238.0, 2.0, 1484.0))
		var garde218v: int = 0
		while cache_v215.par_image_v218 != cache_v215.PAR_IMAGE_MIN_V218 and garde218v < 40:
			await _att(0.5)
			garde218v += 1
		_ok(cache_v215.par_image_v218 == cache_v215.PAR_IMAGE_MIN_V218, "regard immobile : %d objets contrôlés par image (au lieu de %d ; %d objets sur les îles au-dessus)" % [cache_v215.par_image_v218, cache_v215.PAR_IMAGE, cache_v215.a_controler_v218])

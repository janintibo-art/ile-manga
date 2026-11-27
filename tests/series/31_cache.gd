## Ce qu'on ne peut pas voir n'est pas dessiné, V215 (cache_v215.gd) : le Royaume des Racines n'est dessiné
## que sous terre, près de lui ; le dessus des cinq îles aériennes n'est pas dessiné vu d'en bas, là où l'île
## le masque (le disque de roche est bien dans l'île ; ce qui est au bord reste dessiné) ; tout revient dès
## que le regard passe au-dessus, ou à l'aplomb de l'île ; les calques de rendu sont rendus tels quels.
const NOM := "31_cache"


func _serie() -> void:
	_ok(cache_v215 != null, "le jeu ne dessine pas ce qu'on ne peut pas voir")
	if cache_v215 == null:
		return
	var garde215: int = 0
	while not cache_v215.pret and garde215 < 240:
		await _att(0.5)
		garde215 += 1
	_ok(cache_v215.pret, "le recensement se termine")
	cache_v215.actif = false
	cache_v215.tout_montrer()
	_ok(cache_v215.racines.size() > 50, "le Royaume des Racines est recensé (%d objets)" % cache_v215.racines.size())
	_ok(cache_v215.iles.size() == 5, "les cinq îles aériennes sont recensées (%d)" % cache_v215.iles.size())
	var noms215: Array = [["ciel_v54", "ile"], ["astralys_v76", "ile"], ["perchee_v146", "ile"], ["hautefond_v112", "nuees_ile"], ["feerie_v58", "ile"]]
	var dedans215: bool = true
	var peu215: String = ""
	for il215 in cache_v215.iles:
		if (il215["objets"] as Array).size() < 20:
			peu215 += " %s (%d)" % [str(il215["nom"]), (il215["objets"] as Array).size()]
		for d215 in noms215:
			if str(d215[0]) != str(il215["nom"]):
				continue
			var ile215: Node = get(d215[0]).get(d215[1])
			var c215: Vector2 = il215["c"]
			for k215 in 24:
				for q215 in [0.3, 0.6, 1.0]:
					var r215: float = (float(il215["rd"]) + cache_v215.DISQUE_MARGE) * float(q215)
					var a215: float = TAU * float(k215) / 24.0
					var h215: float = ile215.height(c215.x + cos(a215) * r215, c215.y + sin(a215) * r215)
					if h215 < float(il215["yd"]):
						dedans215 = false
						print("31_cache : %s, le sol (%.1f) est sous le disque (%.1f) à %.0f m du centre" % [str(il215["nom"]), h215, float(il215["yd"]), r215])
	_ok(peu215 == "", "chaque île porte ses objets%s" % peu215)
	_ok(dedans215, "le disque de roche est partout sous le sol de son île")
	# la règle : une boîte au milieu de l'île est masquée vue de loin et d'en bas ; au bord, non ; d'en haut, non
	var i215: Dictionary = cache_v215.iles[0]
	var ci215: Vector2 = i215["c"]
	var y215: float = float(i215["y0"])
	var loin215 := Vector3(ci215.x + 200.0, 2.0, ci215.y)
	var milieu215 := AABB(Vector3(ci215.x - 2.0, y215 + 1.0, ci215.y - 2.0), Vector3(4, 6, 4))
	var bord215 := AABB(Vector3(ci215.x + float(i215["r0"]) - 4.0, y215 + 1.0, ci215.y - 2.0), Vector3(4, 6, 4))
	var haute215 := AABB(Vector3(ci215.x - 2.0, y215 + 1.0, ci215.y - 2.0), Vector3(4, 60, 4))
	_ok(cache_v215.masque(i215, loin215, milieu215), "une maison au milieu de l'île est masquée, vue de la mer à 200 m")
	_ok(not cache_v215.masque(i215, loin215, bord215), "au bord de l'île, elle reste dessinée")
	_ok(not cache_v215.masque(i215, loin215, haute215), "une tour de 60 m au milieu dépasse : elle reste dessinée")
	_ok(not cache_v215.masque(i215, Vector3(ci215.x + 600.0, y215 + 40.0, ci215.y), milieu215), "vue d'en haut, rien n'est masqué")
	_ok(not cache_v215.en_dessous(i215, Vector3(ci215.x + 10.0, 2.0, ci215.y)), "à l'aplomb de l'île (les puits, les tubes), on ne masque rien")
	# du village : le Royaume des Racines n'est pas dessiné, et une part du dessus des îles non plus
	var village215 := Vector3(2.0, 2.0, 8.0)
	for t215 in 80:
		cache_v215.controler(village215, 400)
	var rac0_215: int = cache_v215._racines_calques.size()
	_ok(not cache_v215.racines_vues and rac0_215 > cache_v215.racines.size() * 9 / 10, "du village, le Royaume des Racines n'est pas dessiné (%d sur %d)" % [rac0_215, cache_v215.racines.size()])
	var tot215: int = 0
	for il2_215 in cache_v215.iles:
		tot215 += (il2_215["objets"] as Array).size()
	_ok(cache_v215.caches > 100 and cache_v215.caches < tot215, "du village, une part du dessus des îles n'est pas dessinée (%d objets sur %d)" % [cache_v215.caches, tot215])
	var faux215: int = 0
	for il3_215 in cache_v215.iles:
		for g3_215 in il3_215["objets"]:
			if is_instance_valid(g3_215) and (il3_215["calques"] as Dictionary).has(g3_215.get_instance_id()) and not cache_v215.masque(il3_215, village215, (g3_215 as GeometryInstance3D).global_transform * (g3_215 as GeometryInstance3D).get_aabb()):
				faux215 += 1
	_ok(faux215 == 0, "aucun objet visible du village n'est effacé (%d)" % faux215)
	# sous terre, chez les elfes : le Royaume revient
	cache_v215.controler(cache_v215.racines_centre + Vector3(0, -70.0, 0), 400)
	var rac1_215: int = cache_v215._racines_calques.size()
	_ok(cache_v215.racines_vues and rac1_215 == 0, "sous terre, le Royaume des Racines est dessiné")
	# au-dessus d'une île : tout son dessus revient d'un coup
	cache_v215.controler(village215, 400)
	for t2_215 in 80:
		cache_v215.controler(village215, 400)
	cache_v215.controler(Vector3(ci215.x, y215 + 3.0, ci215.y), 400)
	var reste215: int = (i215["calques"] as Dictionary).size()
	_ok(reste215 == 0, "posé sur une île, tout son dessus est redessiné aussitôt (%d encore effacés)" % reste215)
	cache_v215.tout_montrer()
	_ok(cache_v215._racines_calques.is_empty() and cache_v215.caches == 0, "les calques de rendu sont tous rendus")
	cache_v215.actif = true

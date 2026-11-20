## V185 : la foule des lieux (les gens des maisons, des boutiques, des étages des tours). Ils sont tirés
## d'une réserve de corps par ville (pnj/maisons_habitants_v81.gd) : avec 4 à 10 corps par ville, on croisait
## les mêmes côte à côte (un étage de tour de Néopolis : jusqu'à 14 personnes, 3 corps d'homme). 32 corps
## par ville ; les villes qui empruntaient ceux d'une autre ont les leurs ; dans un même lieu, pas deux
## fois le même corps tant qu'il en reste.
##   - chaque fiche de la réserve a son corps (pnj64/<id>.bin) ;
##   - 14 adultes tirés pour un même lieu, dans chaque ville : 14 corps différents ;
##   - les villes qui empruntent ne prennent pas les mêmes corps que la ville prêteuse ;
##   - dans un étage de tour de Néopolis, pas deux personnes au même corps.
const NOM := "42_foule"


func _serie() -> void:
	var G = load("res://scripts/pnj/maisons_habitants_v81.gd")
	var C = load("res://scripts/pnj/corps_v64.gd")
	var sans: Array = []
	var n: int = 0
	for p in G.all_profiles():
		n += 1
		if not C.has_body(str(p["id"])) and sans.size() < 8:
			sans.append(str(p["id"]))
	_ok(n >= 880 and sans.is_empty(), "chaque fiche de la réserve a son corps (%d fiches)%s" % [n, "" if sans.is_empty() else " ; sans corps : " + ", ".join(PackedStringArray(sans))])
	var styles: Array = G.STYLES.keys() + G.DECALAGE.keys()
	var mauvais: Array = []
	var k: int = 0
	for st in styles:
		if str(st).contains("android"):
			continue
		k += 1
		var rng := RandomNumberGenerator.new()
		rng.seed = 4200 + k
		var vus: Dictionary = {}
		for i in range(14):
			vus[str(G.pick(str(st), "adulte", rng)["id"])] = true
		if vus.size() < 14:
			mauvais.append("%s (%d)" % [st, vus.size()])
	_ok(mauvais.is_empty(), "14 adultes tirés pour un même lieu, dans chacune des %d villes : 14 corps différents%s" % [k, "" if mauvais.is_empty() else " ; pas : " + ", ".join(PackedStringArray(mauvais))])
	var communs: Array = []
	for paire in [["neo", "nuees"], ["neo", "dome"], ["nuees", "dome"], ["montjoie", "hautefond"], ["montjoie", "strates"], ["hautefond", "strates"], ["boucan", "fronde"], ["carene", "perchee"]]:
		var ens: Array = [{}, {}]
		for j in range(2):
			var rng2 := RandomNumberGenerator.new()
			for essai in range(40):
				rng2.seed = 9000 + essai * 7 + j
				for r in ["homme", "femme", "ancien", "enfant"]:
					(ens[j] as Dictionary)[str(G.pick(str(paire[j]), r, rng2)["id"])] = true
		for id in ens[0]:
			if (ens[1] as Dictionary).has(id):
				communs.append("%s/%s : %s" % [paire[0], paire[1], id])
				break
	_ok(communs.is_empty(), "les villes qui empruntent ne prennent pas les corps de la ville prêteuse%s" % ["" if communs.is_empty() else " ; " + ", ".join(PackedStringArray(communs))])
	# des étages de tours de Néopolis
	var T: Node = neo_v94.tours if neo_v94 != null else null
	if _ok(T != null and not (T.tours as Array).is_empty(), "les tours de Néopolis"):
		var pires: Array = []
		var etages: int = 0
		var gens_n: int = 0
		var plus: int = 0
		# les trois tours qui ont le plus d'étages
		var ordre: Array = range((T.tours as Array).size())
		ordre.sort_custom(func(a, b): return (T.tours[a]["etages"] as Array).size() > (T.tours[b]["etages"] as Array).size())
		for ti in ordre.slice(0, 3):
			for _w in range(40):
				if not bool(T.get("busy")) and int(T.get("inside")) < 0:
					break
				await _att(0.25)
			await T.enter(int(ti))
			await _att(0.5)
			if int(T.get("inside")) != int(ti):
				_note(false, "on n'est pas entré dans la tour %d" % ti)
				continue
			var ne: int = (T.tours[ti]["etages"] as Array).size()
			for etage in range(0, ne, maxi(1, ne / 8)):
				# (par l'ascenseur : on y est posé, la tour ne nous croit pas sorti)
				if etage > 0:
					await T.aller(etage)
				await _att(0.4)
				if int(T.get("inside")) != int(ti) or int(T.get("etage")) != etage:
					_note(false, "tour %d : on n'est pas arrivé à l'étage %d" % [ti, etage])
					break
				var ids: Dictionary = {}
				var total: int = 0
				for f in T.get("_gens"):
					if is_instance_valid(f) and (f as Node).get("npc") != null:
						var pr: Variant = ((f as Node).get("npc") as Node).get("profile")
						if pr is Dictionary:
							total += 1
							var id2: String = str((pr as Dictionary).get("id", "?"))
							ids[id2] = int(ids.get(id2, 0)) + 1
				etages += 1
				gens_n += total
				plus = maxi(plus, total)
				for id3 in ids:
					if int(ids[id3]) > 1:
						pires.append("tour %d étage %d : %d × %s" % [ti, etage, ids[id3], id3])
			await T.leave()
			await _att(0.5)
		_ok(etages > 0 and gens_n > 20 and pires.is_empty(), "dans %d étages de trois tours (%d personnes, jusqu'à %d par étage), pas deux personnes au même corps%s" % [etages, gens_n, plus, "" if pires.is_empty() else " ; " + ", ".join(PackedStringArray(pires.slice(0, 5)))])

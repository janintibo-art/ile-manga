## V190 : la Tour Vertex, dedans. Les étages de la banque sont faits à la main
## (scripts/neo/tour_vertex_dedans_v190.gd), un par un : la salle des guichets et la salle des coffres, les
## conseillers, le restaurant « La Corbeille », la salle des marchés, la comptabilité, le grand livre, la sécurité,
## l'orangerie, le club, l'atelier des pièces, la direction.
##   - la tour a onze étages, tous faits à la main, et chacun a son nom (à l'ascenseur, sur le panneau) ;
##   - on arrive à chacun par l'ascenseur : la place devant l'ascenseur est libre (on ne sort pas dans un meuble) ;
##   - chaque étage a ses gens, et personne n'est à la même place qu'un autre ;
##   - ce qui bouge : les cartouches du pneumatique aux guichets, les pièces sur le tapis de la comptabilité ;
##   - la Tour Kumo a gardé ses étages.
const NOM := "47_tour_vertex_dedans"
const ATTENDUS := 11


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	if u.size() < 2:
		_ok(false, "la ville a deux immeubles faits à la main")
		return
	var k: Node3D = u[1]
	var T: Node = N.tours
	var tid: int = int(k.tid)
	var t: Dictionary = T.tours[tid]
	var D = load("res://scripts/neo/tour_vertex_dedans_v190.gd")
	var n: int = (t["etages"] as Array).size()
	var faits: int = 0
	for e in range(n):
		if D.fait(e):
			faits += 1
	_ok(n == 11 and faits == ATTENDUS and str((t["b"] as Dictionary).get("unique_dedans", "")).contains("vertex"), "la Tour Vertex a %d étages, dont %d faits à la main" % [n, faits])
	await T.enter(tid)
	await _att(0.6)
	var noms: Dictionary = {}
	var sans_nom: Array = []
	var bouches: Array = []
	var vides: Array = []
	var colles: Array = []
	var gens_n: int = 0
	for e2 in range(n):
		if e2 > 0:
			await T.aller(e2)
			await _att(0.5)
		if int(T.get("etage")) != e2:
			_note(false, "on n'est pas arrivé à l'étage %d" % e2)
			continue
		var nom: String = str(T._nom_etage(e2))
		if str(D.nom(e2)) == "" or not nom.contains(str(D.nom(e2))):
			sans_nom.append("%d (%s)" % [e2, nom])
		noms[nom] = true
		var noeud: Node3D = T.get("_node")
		var asc: Vector3 = T.info["ascenseur"]
		for cs in noeud.find_children("*", "CollisionShape3D", true, false):
			var sh: Shape3D = (cs as CollisionShape3D).shape
			if sh is BoxShape3D:
				var l: Vector3 = (cs as CollisionShape3D).global_transform.affine_inverse() * (asc + Vector3.UP * 1.0)
				var h: Vector3 = (sh as BoxShape3D).size * 0.5
				if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
					bouches.append(e2)
					break
		var gens: Array = T.get("_gens")
		gens_n += gens.size()
		if gens.size() < 2:
			vides.append("%d (%d)" % [e2, gens.size()])
		var places: Array = []
		for g in gens:
			if is_instance_valid(g) and (g as Node).has_meta("it"):
				var pg: Vector3 = ((g as Node).get_meta("it") as Dictionary)["pos"]
				if not (T.info["core"] as Rect2).grow(1.2).has_point(Vector2(pg.x, pg.z)):
					places.append(pg)
		for i in range(places.size()):
			for j in range(i + 1, places.size()):
				if (places[i] as Vector3).distance_to(places[j] as Vector3) < 0.35:
					colles.append("%d %s" % [e2, str(((places[i] as Vector3) - Vector3((T.info["rect"] as Rect2).position.x, 0, (T.info["rect"] as Rect2).position.y)).snapped(Vector3(0.1, 0.1, 0.1)))])
		if e2 == 0 or e2 == 4:
			var a: Node3D = noeud.find_child("Anime_v188", true, false) as Node3D
			var ok_a: bool = a != null and (a.tapis as Array).size() >= 2
			var d: float = 0.0
			if ok_a:
				var p0: Vector3 = ((a.tapis as Array)[0][0] as Node3D).global_position
				await _att(1.0)
				d = p0.distance_to(((a.tapis as Array)[0][0] as Node3D).global_position)
			_ok(ok_a and d > 0.05, ("aux guichets : les cartouches du pneumatique filent (%.2f m en une seconde)" if e2 == 0 else "à la comptabilité : les pièces avancent sur le tapis (%.2f m en une seconde)") % d)
	_ok(sans_nom.is_empty() and noms.size() == n, "chaque étage a son nom, à l'ascenseur (%d noms)%s" % [noms.size(), "" if sans_nom.is_empty() else " ; pas : " + ", ".join(PackedStringArray(sans_nom))])
	_ok(bouches.is_empty(), "à chaque étage, la place devant l'ascenseur est libre%s" % ("" if bouches.is_empty() else " ; pas au : " + str(bouches)))
	_ok(vides.is_empty() and gens_n >= 60, "chaque étage a ses gens (%d dans la tour)%s" % [gens_n, "" if vides.is_empty() else " ; trop peu au : " + ", ".join(PackedStringArray(vides))])
	_ok(colles.is_empty(), "personne à la même place qu'un autre%s" % ("" if colles.is_empty() else " ; au : " + str(colles)))
	await T.leave()
	await _att(0.8)
	_ok(int(T.inside) < 0, "on ressort")
	var K = load("res://scripts/neo/tour_kumo_dedans_v188.gd")
	var tk: int = int((u[0] as Node3D).tid)
	await T.enter(tk)
	await _att(0.6)
	var nk: String = str(T._nom_etage(1))
	_ok(nk.contains(str(K.nom(1))) and not nk.contains("conseillers"), "la Tour Kumo a gardé ses étages (« %s »)" % nk)
	await T.leave()
	await _att(0.6)

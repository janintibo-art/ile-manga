## V188 : la Tour Kumo, dedans. Ses treize étages sont faits à la main (scripts/neo/tour_kumo_dedans_v188.gd),
## un par un : le Dépôt 01, l'agence Kumo Express, la cantine « Au Bol volant », le contrôle des vols, la clinique
## des drones, la mémoire (les serveurs), le standard, le jardin d'hiver, le Nuage, le bureau d'études, les
## objets trouvés, la météo du ciel, la présidence. Avant : les mêmes bureaux, la même cafétéria, à tous les étages
## de toutes les tours.
##   - la tour a treize étages, tous faits à la main, et chacun a son nom (à l'ascenseur, sur le panneau) ;
##   - on arrive à chacun par l'ascenseur : la place devant l'ascenseur est libre (on ne sort pas dans un meuble) ;
##   - chaque étage a ses gens (personne à la même place qu'un autre), et ce qui y bouge (tapis, drones, îles…) ;
##   - les voyants des serveurs, la carte des vols : leurs matières sont là ;
##   - une autre tour n'a pas changé : ses étages s'appellent comme avant.
const NOM := "45_tour_kumo_dedans"


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	if u.is_empty():
		_ok(false, "la ville a un immeuble fait à la main")
		return
	var k: Node3D = u[0]
	var T: Node = N.tours
	var tid: int = int(k.tid)
	var t: Dictionary = T.tours[tid]
	var D = load("res://scripts/neo/tour_kumo_dedans_v188.gd")
	var n: int = (t["etages"] as Array).size()
	var faits: int = 0
	for e in range(n):
		if D.fait(e):
			faits += 1
	_ok(n == 13 and faits == 13 and str((t["b"] as Dictionary).get("unique_dedans", "")) != "", "la Tour Kumo a %d étages, dont %d faits à la main" % [n, faits])
	await T.enter(tid)
	await _att(0.6)
	var noms: Dictionary = {}
	var sans_nom: Array = []
	var bouches: Array = []
	var vides: Array = []
	var colles: Array = []
	var figes: Array = []
	var gens_n: int = 0
	var cartes: int = 0
	var baies: int = 0
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
		# la place devant l'ascenseur : dans aucune boîte où l'on se cogne
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
		# ses gens
		var gens: Array = T.get("_gens")
		gens_n += gens.size()
		if gens.size() < 2:
			vides.append("%d (%d)" % [e2, gens.size()])
		# (un figurant n'est pas un objet de l'espace : sa place est celle où l'on vient lui parler)
		var places: Array = []
		for g in gens:
			if is_instance_valid(g) and (g as Node).has_meta("it"):
				var pg: Vector3 = ((g as Node).get_meta("it") as Dictionary)["pos"]
				# (les promeneurs de toutes les tours font le tour du cœur, et partent du même coin : pas eux)
				if not (T.info["core"] as Rect2).grow(1.2).has_point(Vector2(pg.x, pg.z)):
					places.append(pg)
		for i in range(places.size()):
			for j in range(i + 1, places.size()):
				if (places[i] as Vector3).distance_to(places[j] as Vector3) < 0.35:
					colles.append("%d %s" % [e2, str(((places[i] as Vector3) - Vector3((T.info["rect"] as Rect2).position.x, 0, (T.info["rect"] as Rect2).position.y)).snapped(Vector3(0.1, 0.1, 0.1)))])
		# ce qui bouge, ses matières
		var anime: Node = noeud.find_child("Anime_v188", true, false)
		if anime == null:
			figes.append(e2)
		for mi in noeud.find_children("*", "MeshInstance3D", true, false):
			var mo: Material = (mi as MeshInstance3D).material_override
			if mo is ShaderMaterial and (mo as ShaderMaterial).shader != null and (mo as ShaderMaterial).shader.resource_path.contains("carte_v188"):
				cartes += 1
		if e2 == 5:
			var Kit = load("res://scripts/neo_kit_v94.gd")
			if Kit._mcache.has("k188_baie") and (Kit._mcache["k188_baie"] as ShaderMaterial).shader != null:
				baies = 1
		if e2 == 0:
			var a: Node3D = anime as Node3D
			_ok(a != null and (a.tapis as Array).size() >= 8 and (a.flotte as Array).size() >= 1, "au dépôt : les colis du tapis roulant, le drone qui s'essaie au vol")
			if a != null and (a.tapis as Array).size() > 0:
				var p0: Vector3 = ((a.tapis as Array)[0][0] as Node3D).global_position
				await _att(1.0)
				var p1: Vector3 = ((a.tapis as Array)[0][0] as Node3D).global_position
				_ok(p0.distance_to(p1) > 0.1, "les colis avancent sur le tapis (%.2f m en une seconde)" % p0.distance_to(p1))
	_ok(sans_nom.is_empty() and noms.size() == n, "chaque étage a son nom, à l'ascenseur (%d noms)%s" % [noms.size(), "" if sans_nom.is_empty() else " ; pas : " + ", ".join(PackedStringArray(sans_nom))])
	_ok(bouches.is_empty(), "à chaque étage, la place devant l'ascenseur est libre%s" % ("" if bouches.is_empty() else " ; pas au : " + str(bouches)))
	_ok(vides.is_empty() and gens_n >= 60, "chaque étage a ses gens (%d dans la tour)%s" % [gens_n, "" if vides.is_empty() else " ; trop peu au : " + ", ".join(PackedStringArray(vides))])
	_ok(colles.is_empty(), "personne à la même place qu'un autre%s" % ("" if colles.is_empty() else " ; au : " + str(colles)))
	_ok(figes.is_empty(), "chaque étage a ce qui bouge ou ce qui pousse%s" % ("" if figes.is_empty() else " ; pas au : " + str(figes)))
	_ok(cartes >= 6 and baies == 1, "la carte des vols (%d écrans dans la tour), les voyants des serveurs" % cartes)
	await T.leave()
	await _att(0.8)
	_ok(int(T.inside) < 0, "on ressort")
	# une autre tour de bureaux : ses étages s'appellent comme avant
	var autre: int = -1
	for i2 in range(T.tours.size()):
		if i2 != tid and str(T.tours[i2]["type"]) == "bureaux" and (T.tours[i2]["etages"] as Array).size() >= 4 and not (T.tours[i2]["b"] as Dictionary).has("unique_dedans"):
			autre = i2
			break
	if autre >= 0:
		await T.enter(autre)
		await _att(0.6)
		var na: String = str(T._nom_etage(1))
		_ok(na.begins_with("1er étage — ") and not na.contains("Kumo Express"), "une autre tour n'a pas changé (%s : « %s »)" % [str(T.tours[autre]["nom"]), na])
		await T.leave()
		await _att(0.6)

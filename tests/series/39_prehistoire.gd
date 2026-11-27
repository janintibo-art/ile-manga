## Le Parc du Volcan, V217 (l'Île Foraine au temps des dinosaures) : les huit animaux de décoration sont là
## (le Long-Cou, Grosse-Dent, Corne-Sur-Nez et son petit, le Dos-à-Plaques, les raptors, deux Grand-Becs, le
## squelette), chacun avec son écriteau ; aucun ne passe à moins de 4,3 m de l'axe de la voie du Grand
## Frisson (on mesure sur leurs sommets) ; les plantes non plus (leur couronne comprise, sauf là où la voie
## passe bien au-dessus) ; rien sur les allées, ni plante ni obstacle ; aucune plante haute entre une allée
## et un animal ; la terre et la mousse sous les massifs ; on marche toujours de la grande allée à la Place.
const NOM := "39_prehistoire"
const Ile217p := preload("res://scripts/ile_foraine_v209.gd")
const Trace217p := preload("res://scripts/grand_huit_trace_v209.gd")


var grille217p: Dictionary = {}           # carré de 8 m -> les bouts de voie qui y passent


## Les bouts de voie rangés par carré de 8 m (pour mesurer vite)
func _ranger_voie217p(voie: Array) -> void:
	grille217p.clear()
	for i in range(voie.size() - 1):
		var a: Vector3 = voie[i]
		var b: Vector3 = voie[i + 1]
		var x0: int = int(floor(minf(a.x, b.x) / 8.0))
		var x1: int = int(floor(maxf(a.x, b.x) / 8.0))
		var z0: int = int(floor(minf(a.z, b.z) / 8.0))
		var z1: int = int(floor(maxf(a.z, b.z) / 8.0))
		for cx in range(x0, x1 + 1):
			for cz in range(z0, z1 + 1):
				var k := Vector2i(cx, cz)
				if not grille217p.has(k):
					grille217p[k] = []
				(grille217p[k] as Array).append([a, b])


## La distance d'un point (monde) à l'axe de la voie (au-delà de 16 m : 16)
func _a_la_voie217p(p: Vector3) -> float:
	var best: float = 16.0
	var cx: int = int(floor(p.x / 8.0))
	var cz: int = int(floor(p.z / 8.0))
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var k := Vector2i(cx + dx, cz + dz)
			if not grille217p.has(k):
				continue
			for sg in grille217p[k]:
				var a: Vector3 = sg[0]
				var ab: Vector3 = (sg[1] as Vector3) - a
				var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
				best = minf(best, p.distance_to(a + ab * t))
	return best


## La distance à plat à la voie, pour les bouts de voie plus bas que « plafond » (au-delà de 16 m : 16)
func _a_plat217p(p: Vector3, plafond: float) -> float:
	var best: float = 16.0
	var cx: int = int(floor(p.x / 8.0))
	var cz: int = int(floor(p.z / 8.0))
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var k := Vector2i(cx + dx, cz + dz)
			if not grille217p.has(k):
				continue
			for sg in grille217p[k]:
				for q in sg:
					var qv: Vector3 = q
					if qv.y > plafond:
						continue
					best = minf(best, Vector2(qv.x - p.x, qv.z - p.z).length())
	return best


func _serie() -> void:
	var fo217p: Node3D = foraine_v209
	_ok(fo217p != null and fo217p.ile != null, "l'Île Foraine est construite")
	if fo217p == null or fo217p.ile == null:
		return
	var pr217p: Node3D = fo217p.get("prehistoire")
	_ok(pr217p != null, "le Parc du Volcan est là")
	if pr217p == null:
		return
	var voie217p: Array = []
	for q217p in Trace217p.tracer()["pts"]:
		var qq217p: Vector3 = q217p
		voie217p.append(Ile217p.W(qq217p.x, qq217p.z, qq217p.y))
	_ok(voie217p.size() > 100, "la voie du Grand Frisson est connue (%d points)" % voie217p.size())
	_ranger_voie217p(voie217p)
	# les animaux
	var cles217p: Array = []
	for st217p in pr217p.statues:
		cles217p.append(str(st217p["cle"]))
	_ok(cles217p.size() == 8, "huit animaux sont posés (%s)" % ", ".join(cles217p))
	for c217p in ["long_cou", "grosse_dent", "corne", "plaques", "raptors", "grand_bec", "grand_bec2", "squelette"]:
		_ok(cles217p.has(c217p), "%s est là" % c217p)
	_ok(pr217p.get_node_or_null("Petit_corne_v217") != null and pr217p.get_node_or_null("Oeuf_0_v217") != null, "Corne-Sur-Nez a son petit et son nid")
	var raptors217p: int = 0
	for n217p in pr217p.get_children():
		if str(n217p.name).begins_with("Raptor_"):
			raptors217p += 1
	_ok(raptors217p == 3, "trois raptors (%d)" % raptors217p)
	# aucun sommet d'animal à moins de 4,3 m de l'axe de la voie
	var pire217p: float = 1e9
	var qui217p: String = ""
	var bas217p: int = 0
	var bas_qui217p: String = ""
	for n2217p in pr217p.get_children():
		if not n2217p is MeshInstance3D or str(n2217p.name).begins_with("Plantes_"):
			continue
		var mi217p: MeshInstance3D = n2217p
		if mi217p.mesh == null:
			continue
		var xf217p: Transform3D = mi217p.global_transform
		for s217p in range(mi217p.mesh.get_surface_count()):
			var sommets217p: PackedVector3Array = mi217p.mesh.surface_get_arrays(s217p)[Mesh.ARRAY_VERTEX]
			var pas217p: int = maxi(1, sommets217p.size() / 900)
			for k217p in range(0, sommets217p.size(), pas217p):
				var w217p: Vector3 = xf217p * sommets217p[k217p]
				var d217p: float = _a_la_voie217p(w217p)
				if d217p < pire217p:
					pire217p = d217p
					qui217p = str(mi217p.name)
				# rien de bas au-dessus d'une allée (on s'y cognerait)
				var lw217p: Vector2 = Ile217p.L(w217p.x, w217p.z)
				var aw217p: Vector2 = Ile217p.allee_at(lw217p.x, lw217p.y)
				if aw217p.x < aw217p.y and w217p.y - fo217p.ile.height(w217p.x, w217p.z) < 2.4:
					bas217p += 1
					bas_qui217p = str(mi217p.name)
	_ok(pire217p >= 4.25, "aucun animal à moins de 4,3 m de l'axe de la voie (le plus près : %s, %.2f m)" % [qui217p, pire217p])
	_ok(bas217p == 0, "aucun animal ne passe bas au-dessus d'une allée (%d sommets, %s)" % [bas217p, bas_qui217p])
	# les plantes : la couronne aussi (sauf là où la voie passe bien au-dessus d'elles)
	var plantes217p: int = 0
	var trop217p: int = 0
	var allee217p: int = 0
	var vue217p: int = 0
	var exemple217p: String = ""
	for n3217p in pr217p.get_children():
		if not n3217p is MultiMeshInstance3D:
			continue
		var mm217p: MultiMesh = (n3217p as MultiMeshInstance3D).multimesh
		var bo217p: AABB = mm217p.mesh.get_aabb()
		for i217p in range(mm217p.instance_count):
			var t217p: Transform3D = mm217p.get_instance_transform(i217p)
			var e217p: float = t217p.basis.get_scale().x
			var haut217p: float = maxf(bo217p.end.y, 0.3) * e217p
			var cour217p: float = maxf(maxf(absf(bo217p.position.x), absf(bo217p.end.x)), maxf(absf(bo217p.position.z), absf(bo217p.end.z))) * e217p
			var p217p: Vector3 = t217p.origin
			plantes217p += 1
			var proche217p: float = _a_plat217p(p217p, p217p.y + haut217p + 4.3)
			if proche217p < 4.3 + cour217p - 0.05:
				trop217p += 1
				exemple217p = "%s à %.1f m (couronne %.1f m)" % [n3217p.name, proche217p, cour217p]
			var l217p: Vector2 = Ile217p.L(p217p.x, p217p.z)
			var al217p: Vector2 = Ile217p.allee_at(l217p.x, l217p.y)
			if al217p.x < al217p.y + 0.3:
				allee217p += 1
			if pr217p._cache_la_vue(l217p.x, l217p.y, haut217p):
				vue217p += 1
	_ok(plantes217p > 700, "le parc est planté (%d plantes, %s)" % [plantes217p, str(pr217p.plantes)])
	_ok(trop217p == 0, "aucune plante n'entre dans le passage du train (%d ; %s)" % [trop217p, exemple217p])
	_ok(allee217p == 0, "aucune plante sur une allée (%d)" % allee217p)
	_ok(vue217p == 0, "aucune plante haute entre une allée et un animal (%d)" % vue217p)
	# les obstacles (troncs, pattes, rochers, écriteaux) : jamais sur une allée
	var sur217p: int = 0
	for o217p in pr217p.obstacles:
		var ol217p: Vector2 = Ile217p.L((o217p[0] as Vector3).x, (o217p[0] as Vector3).z)
		var oa217p: Vector2 = Ile217p.allee_at(ol217p.x, ol217p.y)
		if oa217p.x < oa217p.y + float(o217p[1]) - 0.05:
			sur217p += 1
	_ok(pr217p.obstacles.size() > 50 and sur217p == 0, "aucun obstacle sur une allée (%d sur %d)" % [sur217p, pr217p.obstacles.size()])
	# les écriteaux
	var ecr217p: int = 0
	for n4217p in pr217p.get_children():
		if n4217p is Label3D and str((n4217p as Label3D).text).length() > 0:
			ecr217p += 1
	_ok(ecr217p >= 14, "chaque animal a son écriteau (%d lignes)" % ecr217p)
	# la terre et la mousse sous les massifs
	var mousse217p: int = 0
	var vus217p: int = 0
	for ta217p in pr217p._taches_sol:
		var tc217p: Vector2 = ta217p[0]
		var px217p: float = float(Ile217p.BIOME_RES - 1) / (Ile217p.HALF * 2.0)
		var xi217p: int = clampi(int(round((tc217p.x + Ile217p.HALF) * px217p)), 0, Ile217p.BIOME_RES - 1)
		var zi217p: int = clampi(int(round((tc217p.y + Ile217p.HALF) * px217p)), 0, Ile217p.BIOME_RES - 1)
		var col217p: Color = fo217p.ile.biome.get_pixel(xi217p, zi217p)
		if col217p.a > 0.25 or col217p.g > 0.06:
			continue
		vus217p += 1
		if col217p.b > 0.5:
			mousse217p += 1
	_ok(vus217p > 40 and mousse217p >= vus217p * 0.8, "la mousse sous les massifs (%d sur %d)" % [mousse217p, vus217p])
	# on marche de l'entrée de la grande allée jusqu'à la Place, sans être arrêté
	_ranger()
	fo217p.offrir_billet()
	var depart217p: Vector3 = Ile217p.W(-140.0, 20.0)
	depart217p.y = fo217p.ile.height(depart217p.x, depart217p.z) + 0.3
	await _poser(depart217p, Vector3.RIGHT)
	_ok(await _debout("sur la grande allée"), "debout sur la grande allée")
	var cible217p: Vector3 = Ile217p.W(Ile217p.PLACE.x - Ile217p.PLACE_R + 2.0, Ile217p.PLACE.y)
	_touche(KEY_Z, true)
	for k217p in range(400):
		var dir217p: Vector3 = cible217p - _pos()
		pc_root.rotation.y = atan2(-dir217p.x, -dir217p.z)
		await _att(0.1)
		if _plat217p(_pos(), cible217p) < 3.0:
			break
	_touche(KEY_Z, false)
	await _images(3)
	_ranger()
	_ok(_plat217p(_pos(), cible217p) <= 3.0, "on va à pied de la grande allée à la Place (reste %.1f m)" % _plat217p(_pos(), cible217p))


func _plat217p(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

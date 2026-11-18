## On entre dans l'Arcade du Dragon-Pixel (Néopolis) et dans les quatre bus peints (l'Île de Larsen), V175.
## Les portes sont à leur place (entre les deux bornes de la façade ; devant la porte vitrée de chaque
## bus) ; on entre, on tient debout ; l'arcade : Octet au comptoir, les bornes et leurs écrans qui
## jouent, ce qu'on y fait (jouer, danser, la pince, le palet, la photo), le palet qui file ; chaque bus :
## son habitant (Papy Rayon, Pastel, Marque-Page, Écume), l'allée libre jusqu'au fond, ce qu'on y fait ;
## la nuit, tout se construit aussi.
const NOM := "arcade_bus"
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const L175 = preload("res://scripts/lieux_v175.gd")


func _portes(style: String) -> Array:
	var out: Array = []
	for e in Kit56.PORTES_V81:
		if str(e.get("histoire", "")) == L175.HISTOIRE and str(e.get("style", "")) == style:
			out.append(e)
	return out


func _indice(metier: String) -> int:
	for i in range(maisons_v81.portes.size()):
		var e: Dictionary = maisons_v81.portes[i]
		if str(e.get("histoire", "")) == L175.HISTOIRE and str(e.get("metier", "")) == metier:
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


## Peut-on aller jusqu'à celui qui tient le lieu (depuis l'arrivée, en ligne droite ou par un détour) ?
func _accessible(f: Node) -> bool:
	var R = maisons_v81.R
	var a: Vector3 = R.P(R.door_x, 0.0, R.D * 0.5 - 1.1)
	var c: Vector3 = (f.npc as Node3D).global_position
	c.y = a.y
	var mids: Array = [R.P(0.0, 0.0, 0.0), R.P(R.door_x * 0.5, 0.0, 0.0), R.P(-R.W * 0.25, 0.0, 0.3), R.P(R.W * 0.25, 0.0, 0.3)]
	for k in range(12):
		var ang: float = TAU * k / 12.0
		for d in [0.75, 1.1, 1.45]:
			var p: Vector3 = c + Vector3(cos(ang), 0, sin(ang)) * d
			if _voie_libre(a, p):
				return true
			for m in mids:
				if _voie_libre(a, m) and _voie_libre(m, p):
					return true
	return false


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


func _ecrans() -> int:
	var n: int = 0
	# (la pièce regroupe ses morceaux par matière : un maillage par écran, sa matière en material_override)
	for mi in maisons_v81.room.find_children("*", "MeshInstance3D", true, false):
		var m: Material = (mi as MeshInstance3D).material_override
		if m is ShaderMaterial and (m as ShaderMaterial).shader != null and str((m as ShaderMaterial).shader.resource_path).contains("arcade_ecran"):
			n += 1
	return n


func _serie() -> void:
	# --- les portes
	_ok(_portes("neo").size() == 1, "la porte de l'Arcade du Dragon-Pixel (%d)" % _portes("neo").size())
	_ok(_portes("larsen").size() == 4, "les portes des quatre bus peints (%d)" % _portes("larsen").size())
	await _att(5.5)
	var vus: int = 0
	for e in maisons_v81.portes:
		if str(e.get("histoire", "")) == L175.HISTOIRE:
			vus += 1
	_ok(vus == 5, "maisons_v81 connaît les cinq portes (%d)" % vus)
	var nv: Node = neo_v94
	var ia: int = _indice("arcade_dragon")
	if nv != null and ia >= 0:
		var dp: Vector3 = maisons_v81.portes[ia]["door"]
		var aa: Vector3 = nv.arcade_at
		_ok(Vector2(dp.x, dp.z).distance_to(Vector2(aa.x, aa.z)) < 5.0 and (maisons_v81.portes[ia]["out"] as Vector3).x > 0.9,
			"la porte de l'arcade est sur la façade, entre les bornes, face au boulevard")
	else:
		_ok(false, "Néopolis est construite (l'arcade)")
	var lv: Node = larsen_v91
	var ok_bus: bool = lv != null
	var pts: Array = []
	for met in ["bus_soleil", "bus_atelier", "bus_livres", "bus_plage"]:
		var ib: int = _indice(met)
		if ib < 0:
			ok_bus = false
			continue
		var d: Vector3 = maisons_v81.portes[ib]["door"]
		if lv != null and not lv.contains(d):
			ok_bus = false
		for q in pts:
			if (q as Vector3).distance_to(d) < 3.0:
				ok_bus = false
		pts.append(d)
	_ok(ok_bus and pts.size() == 4, "chaque bus a sa porte, sur l'Île de Larsen, chacune à son bus")
	# --- l'arcade
	var ok: bool = false
	if ia >= 0:
		ok = await _entrer(ia)
	_ok(ok and str(maisons_v81.ctx.get("metier", "")) == "arcade_dragon", "on entre dans l'Arcade du Dragon-Pixel")
	if ok:
		var R = maisons_v81.R
		_ok(await _debout("dans l'arcade", 0.6), "on tient debout dans l'arcade")
		_ok(R.W >= 15.0 and R.D >= 17.0, "la salle est grande (%.0f × %.0f m)" % [R.W, R.D])
		var f: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f != null and is_instance_valid(f) and str(f.npc.display_name) == "Octet", "Octet, l'androïde, tient le comptoir des lots")
		if f != null and is_instance_valid(f):
			_ok(_accessible(f), "on peut aller parler à Octet")
		var ne: int = _ecrans()
		_ok(ne >= 15, "les bornes ont leurs écrans qui jouent (%d)" % ne)
		var manque: Array = _actes(["jouer à Dragon-Pixel", "Carpe Cosmos", "Néo-Kart", "danser", "essayer la pince", "jouer au palet", "faire une photo", "jetons", "meilleurs scores", "sortir"])
		_ok(manque.is_empty(), "ce qu'on fait dans l'arcade (manque : %s)" % str(manque))
		var pl: Variant = maisons_v81.ctx.get("palet175", null)
		var p0: Vector3 = Vector3.ZERO
		if pl is Array and is_instance_valid(pl[0]):
			p0 = (pl[0] as Node3D).global_position
		await _att(0.8)
		_ok(pl is Array and is_instance_valid(pl[0]) and (pl[0] as Node3D).global_position.distance_to(p0) > 0.05, "le palet file sur sa table")
		# on traverse la salle, de la porte au fond
		_ok(_voie_libre(R.P(0.0, 0.0, R.D * 0.5 - 1.2), R.P(1.6, 0.0, -1.0)) and _voie_libre(R.P(1.6, 0.0, -1.0), R.P(2.4, 0.0, -6.6)), "on traverse la salle jusqu'à la grande borne")
		maisons_v81._teardown()
		await _att(0.3)
	# --- les bus
	var gens := {"bus_soleil": "Papy Rayon", "bus_atelier": "Pastel", "bus_livres": "Marque-Page", "bus_plage": "Écume"}
	var faits := {"bus_soleil": "tisane", "bus_atelier": "peindre une fleur", "bus_livres": "lire une page", "bus_plage": "écouter le coquillage"}
	for met2 in gens:
		var ib2: int = _indice(met2)
		var ok2: bool = false
		if ib2 >= 0:
			ok2 = await _entrer(ib2)
		_ok(ok2 and str(maisons_v81.ctx.get("metier", "")) == met2, "on entre dans le bus : %s" % met2)
		if not ok2:
			continue
		var R2 = maisons_v81.R
		_ok(await _debout("dans le bus " + met2, 0.6), "on tient debout dans le bus : %s" % met2)
		_ok(R2.D < 2.5 and R2.H < 2.3 and absf(R2.door_x - L175.BUS_PORTE) < 0.01, "la pièce a la taille d'un bus, la porte devant à droite (%s)" % met2)
		var f2: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f2 != null and is_instance_valid(f2) and str(f2.npc.display_name) == str(gens[met2]), "%s habite le bus" % str(gens[met2]))
		if f2 != null and is_instance_valid(f2):
			_ok(_accessible(f2), "on peut aller parler à %s" % str(gens[met2]))
		# l'allée : de la porte jusqu'au fond du bus
		var fond: float = -R2.W * 0.5 + 1.95
		_ok(_voie_libre(R2.P(R2.door_x - 0.1, 0.0, 0.0), R2.P(fond, 0.0, 0.0)), "l'allée est libre jusqu'au fond (%s)" % met2)
		_ok(_actes([str(faits[met2]), "sortir"]).is_empty(), "ce qu'on fait dans le bus : %s" % met2)
		maisons_v81._teardown()
		await _att(0.3)
	# --- la nuit : tout se construit aussi
	var tp: Node = temps_v56
	if tp != null:
		var h0: float = tp.hour
		tp.hour = 23.0
		for met3 in ["arcade_dragon", "bus_soleil", "bus_atelier", "bus_livres", "bus_plage"]:
			var i3: int = _indice(met3)
			var ok3: bool = false
			if i3 >= 0:
				ok3 = await _entrer(i3)
			_ok(ok3 and not maisons_v81.R.day, "la nuit, on entre aussi : %s" % met3)
			if ok3:
				maisons_v81._teardown()
				await _att(0.2)
		tp.hour = h0
	_ok(not maisons_v81.inside, "on est bien ressorti")

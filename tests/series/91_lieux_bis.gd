## On entre dans les lieux de Tazira, de Ramure et de Port-Boucan (V172) : le Fondouk, la tour de
## guet de la Skala, les deux petits phares de la jetée ; l'échoppe des Simples, la Poste des
## chouettes, la boulangerie des lapins, la pêcherie des chats ; le bureau de vente de Lisse & Fils,
## la roulotte de Mère Morille, le phare tagué. Chaque lieu a sa porte ; la maison du chat de Tazira
## s'ouvre aussi ; on entre dans chaque lieu (quelqu'un le tient, on tient debout, on peut aller lui
## parler) ; c'est la vraie personne de la ville quand elle existe, et à Ramure, elle garde ses
## oreilles et sa queue.
const NOM := "lieux172"
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const L172 = preload("res://scripts/lieux_v172.gd")


func _portes(style: String) -> Array:
	var out: Array = []
	for e in Kit56.PORTES_V81:
		if str(e.get("histoire", "")) == L172.HISTOIRE and str(e.get("style", "")) == style:
			out.append(e)
	return out


## Entrer par la porte i (et attendre que l'entrée soit finie).
func _entrer(i: int) -> bool:
	_ranger()
	await _images(2)
	var p: Dictionary = maisons_v81.portes[i]
	place_player_v35((p["door"] as Vector3) + Vector3.UP * 0.1, -(p["out"] as Vector3))
	await _att(0.3)
	maisons_v81.force_scenario = ""
	maisons_v81.enter(i)
	for k in range(50):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	return maisons_v81.inside and maisons_v81.room != null


func _indice(metier: String, style: String) -> int:
	for i in range(maisons_v81.portes.size()):
		var e: Dictionary = maisons_v81.portes[i]
		if str(e.get("histoire", "")) == L172.HISTOIRE and str(e.get("metier", "")) == metier and str(e.get("style", "")) == style:
			return i
	return -1


## Peut-on aller jusqu'à celui qui tient le lieu (un point à moins de 1,5 m de lui, en ligne droite
## depuis la porte, ou en passant par le milieu de la pièce) ?
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


func _vrai(id: String) -> Node:
	for n in npcs_v31:
		if is_instance_valid(n) and n.get("profile") is Dictionary and str((n.get("profile") as Dictionary).get("id", "")) == id:
			return n
	return null


func _serie() -> void:
	# --- les portes
	var total: int = 0
	for st in L172.VILLES:
		var n: int = _portes(st).size()
		total += (L172.VILLES[st] as Dictionary).size()
		_ok(n == (L172.VILLES[st] as Dictionary).size(), "%s : chaque lieu a sa porte (%d sur %d)" % [st, n, (L172.VILLES[st] as Dictionary).size()])
	await _att(5.5)
	var vus: int = 0
	for e in maisons_v81.portes:
		if str(e.get("histoire", "")) == L172.HISTOIRE:
			vus += 1
	_ok(vus == total, "maisons_v81 connaît toutes les portes des lieux (%d)" % vus)
	# --- la maison du chat de Tazira (l'îlot entre le quai et la place) s'ouvre aussi
	var chat: bool = false
	var tz: Node = grande_v59.get("tazira") if grande_v59 != null else null
	if tz != null:
		var pc: Variant = (tz.points as Dictionary).get("porte_maison_chat", null)
		for e3 in maisons_v81.portes:
			if pc is Vector3 and str(e3.get("style", "")) == "tazira" and (e3["door"] as Vector3).distance_to(pc) < 2.5:
				chat = true
	_ok(chat, "on entre dans la maison du chat, à Tazira")
	# --- on entre dans chaque lieu
	for st2 in L172.VILLES:
		for id in L172.VILLES[st2]:
			var e4: Array = L172.VILLES[st2][id]
			var met: String = str(e4[0])
			var i: int = _indice(met, st2)
			if i < 0:
				_ok(false, "la porte : %s" % met)
				continue
			var ok: bool = await _entrer(i)
			_ok(ok and str(maisons_v81.ctx.get("scenario", "")) == L172.HISTOIRE and str(maisons_v81.ctx.get("metier", "")) == met, "on entre : %s (%s)" % [met, st2])
			if not ok:
				continue
			var f: Variant = maisons_v81.ctx.get("marchand", null)
			_ok(f != null and is_instance_valid(f), "%s : quelqu'un tient le lieu" % met)
			_ok(await _debout("dans le lieu : " + met, 0.5), "on tient debout : %s" % met)
			if f != null and is_instance_valid(f):
				_ok(_accessible(f), "%s : on peut aller parler à %s" % [met, str(f.npc.display_name)])
				var vraie: Node = _vrai(str(e4[1]))
				if vraie != null:
					_ok(str(f.npc.display_name) == str(vraie.get("display_name")), "%s : c'est la vraie personne (%s)" % [met, str(f.npc.display_name)])
					if st2 == "ramure":
						_ok(str((f.npc.get_script() as Script).resource_path).contains("ramure"), "%s : %s garde ses oreilles et sa queue" % [met, str(f.npc.display_name)])
			maisons_v81._teardown()
			await _att(0.2)
	_ok(not maisons_v81.inside, "on est bien ressorti")

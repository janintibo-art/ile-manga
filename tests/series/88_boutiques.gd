## On entre dans les boutiques et les bâtiments publics (V170) de Pile-ou-Face, de Port-Azur, de
## Pandémonia, de Montjoie et de Cliquetis : les portes (chaque boutique a la sienne, plus aucune porte
## « fermée » à Pile-ou-Face) ; on entre dans chaque sorte de boutique (le métier, la pièce construite,
## le marchand, on tient debout, on peut aller lui parler) ; le marchand est la vraie personne de la
## ville quand elle existe, et on lui parle comme dehors ; le menu de secours n'a pas d'alcool ;
## le théâtre joue sa scène, l'hôtel loue ses chambres.
const NOM := "boutiques"
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const B170 = preload("res://scripts/boutiques_v170.gd")
const L147 = preload("res://scripts/lieux_perchee_v147.gd")


func _portes(style: String = "") -> Array:
	var out: Array = []
	for e in Kit56.PORTES_V81:
		if str(e.get("histoire", "")) == "b170" and (style == "" or str(e.get("style", "")) == style):
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


func _indice(metier: String, style: String = "") -> int:
	for i in range(maisons_v81.portes.size()):
		var e: Dictionary = maisons_v81.portes[i]
		if str(e.get("histoire", "")) != "b170" or str(e.get("metier", "")) != metier:
			continue
		if style != "" and str(e.get("style", "")) != style:
			continue
		return i
	return -1


## Peut-on aller jusqu'au marchand (un point à moins de 1,5 m de lui, en ligne droite depuis la porte,
## ou en passant par le milieu de la pièce) ?
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


func _serie() -> void:
	# --- les portes
	var total: int = 0
	for st in B170.VILLES:
		var n: int = _portes(st).size()
		total += (B170.VILLES[st] as Dictionary).size()
		_ok(n == (B170.VILLES[st] as Dictionary).size(), "%s : chaque boutique a sa porte (%d sur %d)" % [st, n, (B170.VILLES[st] as Dictionary).size()])
	await _att(5.5)
	var vus: int = 0
	for e in maisons_v81.portes:
		if str(e.get("histoire", "")) == "b170":
			vus += 1
	_ok(vus == total, "maisons_v81 connaît toutes les portes des boutiques (%d)" % vus)
	# --- Pile-ou-Face : plus aucune porte « fermée pour l'instant »
	var fermes: Array = []
	if perchee_v146 != null:
		for e2 in perchee_v146.portes:
			var lieu: String = str(e2.get("lieu", ""))
			if lieu != "" and not L147.has("pp_" + lieu) and not B170.ouvre("perchee", lieu):
				fermes.append(lieu)
	_ok(perchee_v146 != null and fermes.is_empty(), "Pile-ou-Face : tous les lieux s'ouvrent (encore fermés : %s)" % ", ".join(fermes))
	# --- on entre dans chaque sorte de boutique
	var metiers: Dictionary = {}
	for st2 in B170.VILLES:
		for id in B170.VILLES[st2]:
			var met: String = str(B170.VILLES[st2][id][0])
			if not metiers.has(met):
				metiers[met] = st2
	for met2 in metiers:
		var i: int = _indice(met2, str(metiers[met2]))
		if i < 0:
			_ok(false, "la porte : %s" % met2)
			continue
		var ok: bool = await _entrer(i)
		_ok(ok and str(maisons_v81.ctx.get("scenario", "")) == "b170" and str(maisons_v81.ctx.get("metier", "")) == met2, "on entre : %s (%s)" % [met2, metiers[met2]])
		if not ok:
			continue
		var f: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(f != null and is_instance_valid(f), "%s : quelqu'un tient la boutique" % met2)
		_ok(await _debout("dans la boutique : " + met2, 0.5), "on tient debout : %s" % met2)
		if f != null and is_instance_valid(f):
			_ok(_accessible(f), "%s : on peut aller parler à %s" % [met2, str(f.npc.display_name)])
		maisons_v81._teardown()
		await _att(0.2)
	# --- la vraie personne derrière son comptoir : Margaux, à la boulangerie de Port-Azur
	var ib: int = _indice("boulangerie", "azur")
	var vraie: Node = null
	for n in npcs_v31:
		if is_instance_valid(n) and str((n.get("profile") as Dictionary).get("id", "")) == "margaux":
			vraie = n
	if ib >= 0 and vraie != null:
		var okb: bool = await _entrer(ib)
		var f2: Variant = maisons_v81.ctx.get("marchand", null)
		_ok(okb and f2 != null and str(f2.npc.display_name) == str(vraie.get("display_name")), "à la boulangerie, c'est Margaux qui sert (%s)" % (str(f2.npc.display_name) if f2 != null else "personne"))
		if f2 != null:
			B170._parler(maisons_v81, f2, {})
			await _att(0.4)
			_ok(dialogue_v31.opened and talking_npc_v31 == vraie, "on parle à la vraie Margaux (sa boutique, ses histoires)")
			_ok(dialogue_v31.get("_npc") == f2.npc, "le portrait et le panneau regardent la Margaux d'ici")
			_close_dialogue_v31()
			await _att(0.3)
			_ok(not bool(maisons_v81.ctx.get("parle170", false)) and not bool(f2.get("talking")), "la conversation finie, Margaux reprend son travail")
		maisons_v81._teardown()
		await _att(0.2)
	else:
		_note(false, "pas de Margaux à Port-Azur pour l'essai")
	# --- le menu de secours n'a pas d'alcool
	var alcool: Array = []
	for id2 in ["biere_naine", "cidre_montjoie", "grog_soufre", "rhum_murene", "pain_miel"]:
		if not B170._sans_alcool(id2):
			alcool.append(id2)
	_ok(alcool == ["biere_naine", "cidre_montjoie", "grog_soufre", "rhum_murene"], "pas d'alcool dans les boutiques (%s)" % ", ".join(alcool))
	# --- le théâtre joue sa scène ; l'hôtel loue ses chambres
	var it: int = _indice("theatre")
	if it >= 0 and await _entrer(it):
		maisons_v81.ctx["scene_t"] = 0.0
		await _att(5.5)
		var a: Dictionary = maisons_v81.ctx.get("acteurs170", {})
		_ok(maisons_v81.ctx.has("scene_t") and float(maisons_v81.ctx["scene_t"]) > 4.0 and a.size() == 3, "le Théâtre des Mirages répète sa scène")
		maisons_v81._teardown()
		await _att(0.2)
	var ih: int = _indice("hotel")
	if ih >= 0 and await _entrer(ih):
		var mh: Dictionary = maisons_v81.ctx.get("menu170", {})
		_ok((mh.get("services", []) as Array).size() >= 1, "l'Hôtel des Nuages loue ses chambres")
		maisons_v81._teardown()
		await _att(0.2)
	_ok(not maisons_v81.inside, "on est bien ressorti")

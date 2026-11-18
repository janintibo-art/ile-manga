## On entre dans tous les bâtiments d'Al Dente, de l'Île Crayonnée et de Sombreval (V169) : les portes
## (les six maisons du Borgo et la Barque-Maison, les quatre arbres-maisons, chaque immeuble fermé et
## chaque maison des Faubourgs de Sombreval, la gare, le beffroi) ; on entre dans chaque sorte de
## pièce (le style, l'histoire, la pièce construite, on tient debout) ; l'arbre-maison est dessiné
## comme l'île (le coloriage, puis on le rend en sortant) ; les histoires de Sombreval sont variées.
const NOM := "maisons_sud"
const Kit56 = preload("res://scripts/azur_kit_v56.gd")
const Sud = preload("res://scripts/maisons_sud_v169.gd")


func _portes(style: String, histoire: String = "") -> Array:
	var out: Array = []
	for e in Kit56.PORTES_V81:
		if str(e.get("style", "")) == style and (histoire == "" or str(e.get("histoire", "")) == histoire):
			out.append(e)
	return out


## Entrer par la porte i (et attendre que l'entrée soit finie).
func _entrer(i: int, force: String = "") -> bool:
	_ranger()
	await _images(2)
	var p: Dictionary = maisons_v81.portes[i]
	place_player_v35((p["door"] as Vector3) + Vector3.UP * 0.1, -(p["out"] as Vector3))
	await _att(0.3)
	maisons_v81.force_scenario = force
	maisons_v81.enter(i)
	for k in range(50):
		await _att(0.1)
		if maisons_v81.inside and not maisons_v81.busy:
			break
	return maisons_v81.inside and maisons_v81.room != null


func _indice(style: String, histoire: String = "", owner: String = "") -> int:
	for i in range(maisons_v81.portes.size()):
		var e: Dictionary = maisons_v81.portes[i]
		if str(e.get("style", "")) != style:
			continue
		if histoire != "" and str(e.get("histoire", "")) != histoire:
			continue
		if owner != "" and str(e.get("owner", "")) != owner:
			continue
		return i
	return -1


func _serie() -> void:
	# --- les portes
	_ok(_portes("pasta").size() == 6, "les six maisons du Borgo d'Al Dente ont leur porte (%d)" % _portes("pasta").size())
	var barque: int = 0
	for e in _portes("pirate"):
		if str(e.get("owner", "")) == "rigatoni":
			barque += 1
	_ok(barque == 1, "la Barque-Maison du Capitaine Rigatoni a sa porte")
	_ok(_portes("crayon").size() == 4 and _portes("crayon", "cr_conseil").size() == 1, "les quatre arbres-maisons de l'Île Crayonnée (dont la Maison du Conseil)")
	var S: Node = sombreval_v121
	_ok(S != null and S.hd_v169, "Sombreval : les portes V169")
	# (les portes des lieux V17x, comme le mausolée, sont comptées par leurs séries : 92_lieux_ter)
	var nsv: int = 0
	for e5 in _portes("sombreval"):
		if not str(e5.get("histoire", "")).begins_with("b17"):
			nsv += 1
	_ok(nsv >= 60 and S != null and S.portes_v169 == nsv, "Sombreval : chaque bâtiment debout a sa porte (%d)" % nsv)
	_ok(_portes("sombreval", "sv_gare").size() == 1 and _portes("sombreval", "sv_beffroi").size() == 1, "la gare et le beffroi ont leur porte")
	await _att(5.5)
	var vus: int = 0
	for e2 in maisons_v81.portes:
		if str(e2.get("style", "")) in ["pasta", "crayon", "sombreval"] and not str(e2.get("histoire", "")).begins_with("b17"):
			vus += 1
	_ok(vus == 10 + nsv, "maisons_v81 connaît toutes ces portes (%d)" % vus)
	# --- les histoires de Sombreval : variées
	var sortes: Dictionary = {}
	for e3 in _portes("sombreval"):
		if str(e3.get("histoire", "")) != "":
			continue
		sortes[Sud.pick_id("sombreval", "m81_%d_%d" % [roundi((e3["door"] as Vector3).x * 2.0), roundi((e3["door"] as Vector3).z * 2.0)])] = true
	_ok(sortes.size() >= 5 and not sortes.has("famille"), "Sombreval : des histoires variées, et personne n'y fait la fête (%s)" % ", ".join(sortes.keys()))
	# --- on entre : Al Dente (chez Mamma Lasagna)
	var ip: int = _indice("pasta")
	_ok(ip >= 0, "une maison du Borgo")
	if ip >= 0:
		var ok: bool = await _entrer(ip)
		_ok(ok and str(maisons_v81.ctx.get("style", "")) == "pasta", "on entre dans une maison du Borgo (%s, %s)" % [str(maisons_v81.ctx.get("style", "")), str(maisons_v81.ctx.get("scenario", ""))])
		_ok(await _debout("dans une maison du Borgo", 0.6), "on tient debout chez les adeptes")
		maisons_v81._teardown()
		await _att(0.3)
	# --- la Barque-Maison
	var ib: int = _indice("pirate", "", "rigatoni")
	if ib >= 0:
		var okb: bool = await _entrer(ib)
		_ok(okb and str(maisons_v81.ctx.get("style", "")) == "pirate", "on entre dans la Barque-Maison du Capitaine")
		maisons_v81._teardown()
		await _att(0.3)
	# --- l'Île Crayonnée : un arbre-maison, la Maison du Conseil
	for h in ["cr_maison", "cr_conseil"]:
		var ic: int = _indice("crayon", h)
		_ok(ic >= 0, "la porte : %s" % h)
		if ic < 0:
			continue
		var okc: bool = await _entrer(ic)
		_ok(okc and str(maisons_v81.ctx.get("scenario", "")) == h, "on entre : %s" % h)
		var conv: int = 0
		for mi in maisons_v81.room.find_children("*", "MeshInstance3D", true, false):
			if mi.has_meta("crayon_fait"):
				conv += 1
		_ok(conv >= 5, "la pièce ronde est dessinée comme l'île (%d maillages au coloriage)" % conv)
		_ok(Sud.dedans and bool(maisons_v81.ctx.get("crayon_dedans", false)), "le coloriage sait qu'on est dans la maison")
		_ok(await _debout("dans l'arbre-maison", 0.6), "on tient debout dans la pièce ronde")
		var id: String = str(maisons_v81.cur.get("maison_id", ""))
		_ok(crayon_v99 != null and (crayon_v99.state.get("portes", {}) as Dictionary).has(id), "la porte est notée (les trouvailles du village)")
		maisons_v81._teardown()
		await _att(0.3)
		_ok(not Sud.dedans, "en sortant, le coloriage revient à l'île")
	# --- Sombreval : un immeuble (chaque histoire), la gare, le beffroi
	var isv: int = -1
	for i in range(maisons_v81.portes.size()):
		if str(maisons_v81.portes[i].get("style", "")) == "sombreval" and str(maisons_v81.portes[i].get("histoire", "")) == "":
			isv = i
			break
	_ok(isv >= 0, "une porte d'immeuble à Sombreval")
	if isv >= 0:
		for sc in ["sv_souper", "sv_refuge", "sv_enfant", "sv_chat", "sv_pharmacie", "abandon"]:
			var oks: bool = await _entrer(isv, sc)
			_ok(oks and str(maisons_v81.ctx.get("scenario", "")) == sc and maisons_v81.R.style == "sombreval", "Sombreval : %s" % sc)
			_note(await _debout("Sombreval : " + sc, 0.5), "on tient debout : " + sc)
			maisons_v81._teardown()
			await _att(0.3)
	for h2 in ["sv_gare", "sv_beffroi"]:
		var ih: int = _indice("sombreval", h2)
		if ih < 0:
			_ok(false, "la porte : %s" % h2)
			continue
		var okh: bool = await _entrer(ih)
		_ok(okh and str(maisons_v81.ctx.get("scenario", "")) == h2, "on entre : %s" % h2)
		_ok(await _debout(h2, 0.5), "on tient debout : %s" % h2)
		maisons_v81._teardown()
		await _att(0.3)
	_ok(not maisons_v81.inside, "on est bien ressorti")

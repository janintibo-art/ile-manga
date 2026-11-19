## Toutes les histoires de maisons du mode testeur : on entre, la pièce est construite, on tient debout.
## V176 : on n'arrive pas pris dans un meuble, et personne n'a la tête dans un mur.
const NOM := "maisons"


func _serie() -> void:
	var hist: Array = testeur_v78._house_stories()
	_ok(hist.size() > 40, "histoires de maisons : %d" % hist.size())
	var n_ok: int = 0
	for i in hist.size():
		_ranger()
		await _images(2)
		var sc: String = str((hist[i][1] as Array)[0])
		var quoi: String = "maison « %s »" % str(hist[i][0])
		testeur_v78._visit(sc)
		await _att(0.3)
		# on attend la fin de l'entrée (fondu, porte) avant de regarder… et avant de ressortir
		for k in range(40):
			if not maisons_v81.busy:
				break
			await _att(0.1)
		var ok: bool = _note(maisons_v81.inside, quoi + " : on n'est pas entré")
		if ok:
			ok = _note(maisons_v81.room != null and is_instance_valid(maisons_v81.room), quoi + " : pas de pièce") and ok
			var debout: bool = await _debout(quoi, 0.6)
			ok = debout and ok
			# V176 : on n'arrive pas pris dans un meuble ; personne n'a la tête dans un mur
			if deblocage_v176 != null:
				ok = _note(not deblocage_v176.pris(_pos()), quoi + " : on arrive pris dans un meuble") and ok
			ok = _note(_tetes_ok(), quoi + " : quelqu'un a la tête dans un mur") and ok
		if ok:
			n_ok += 1
		maisons_v81._teardown()
		await _att(0.15)
	_ok(n_ok == hist.size(), "maisons visitées : %d sur %d" % [n_ok, hist.size()])
	_ok(not maisons_v81.inside, "on est bien ressorti")


## V176 : la tête de chaque habitant est dans la pièce (pas dans un mur : le dormeur, le pirate dans son
## hamac). On ne regarde que près des murs : une cave, une pièce secrète sont ailleurs, plus loin.
func _tetes_ok() -> bool:
	var R = maisons_v81.R
	if R == null:
		return true
	var hw: float = R.W * 0.5
	var hd: float = R.D * 0.5
	for f in maisons_v81.people:
		if not is_instance_valid(f) or f.get("npc") == null or not is_instance_valid(f.npc):
			continue
		var sk: Skeleton3D = f.npc.get("skel")
		if sk == null or sk.find_bone("Head") < 0:
			continue
		var l: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin - R.P(0, 0, 0)
		if l.y < 0.0 or l.y > R.H + 0.5:
			continue
		var bx: bool = absf(l.x) > hw - 0.08 and absf(l.x) < hw + 0.8 and absf(l.z) < hd + 0.8
		var bz: bool = absf(l.z) > hd - 0.08 and absf(l.z) < hd + 0.8 and absf(l.x) < hw + 0.8
		if bx or bz:
			print("  la tête de %s : (%.2f %.2f %.2f), pièce %.1f × %.1f" % [str(f.npc.get("display_name")), l.x, l.y, l.z, R.W, R.D])
			return false
	return true

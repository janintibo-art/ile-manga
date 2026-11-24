## V202 : la vie qui accompagne le plongeur (les bancs et les crabes autour de soi, où que l'on plonge).
const NOM := "37_vie_ambiante"


func _tours(am: Node, n: int, oeil: Vector3, eau: bool) -> void:
	for i in range(n):
		am.pas(0.05, oeil, Vector3(0, 0, 1), eau)


## De l'eau profonde sur 60 m à la ronde ?
func _pleine_mer(c: Vector3) -> bool:
	for k in range(9):
		var a: float = TAU * k / 8.0
		var r: float = 0.0 if k == 8 else 60.0
		if _height_at(c.x + cos(a) * r, c.z + sin(a) * r) > -16.0:
			return false
	return true


func _serie() -> void:
	var vie: Node = mer_v55.vie if mer_v55 != null else null
	_ok(vie != null and vie.ambiante != null, "la vie ambiante existe")
	if vie == null or vie.ambiante == null:
		return
	var am: Node = vie.ambiante
	am.essai = true
	_ok(am.bancs.size() >= 8, "des bancs de plusieurs espèces (%d)" % am.bancs.size())
	# ------------------------------------------------------------------ au large, loin de tout banc fixe
	var ici := Vector3.ZERO
	var la := Vector3.ZERO
	var trouve: bool = false
	for gx in range(-12, 13):
		for gz in range(-12, 13):
			if trouve:
				break
			var c := Vector3(gx * 50.0, -9.0, gz * 50.0)
			if not _pleine_mer(c) or not _pleine_mer(c + Vector3(0, 0, 260.0)):
				continue
			var libre: bool = true
			for s in vie.schools:
				if (s["anchor"] as Vector3).distance_to(c) < 120.0:
					libre = false
			if libre:
				ici = c
				la = c + Vector3(0, 0, 260.0)
				trouve = true
	_ok(trouve, "un point en pleine mer, sans banc fixe à moins de 120 m : avant, on n'y voyait pas un poisson %s" % ici)
	if not trouve:
		am.essai = false
		return
	var fond: float = _height_at(ici.x, ici.z)
	_tours(am, 4, ici, true)
	_ok(am.bancs_pres(ici, 45.0) >= 6, "on plonge : de la vie tout de suite (%d bancs à moins de 45 m)" % am.bancs_pres(ici, 45.0))
	_ok(am.crabes_pres(ici, 45.0) >= 4 or ici.y - fond > 20.0, "des crabes sur le sable autour de soi (%d)" % am.crabes_pres(ici, 45.0))
	_tours(am, 200, ici, true)
	var dedans: bool = true
	var vus: int = 0
	var pire: String = ""
	for b in am.bancs:
		if not bool(b["vivant"]):
			continue
		# (sans écran, le moteur ne garde pas la place de chaque poisson : on juge le banc)
		var p: Vector3 = b["pos"]
		vus += int(b["n"])
		if p.y > -0.42 - 0.5 or p.y < _height_at(p.x, p.z) + 0.3:
			dedans = false
			pire = "%s, fond %.1f" % [p, _height_at(p.x, p.z)]
	_ok(vus > 80, "des poissons par dizaines (%d)" % vus)
	_ok(dedans, "aucun banc hors de l'eau ni sous le sable %s" % pire)
	# ------------------------------------------------------------------ on nage loin : la vie suit
	_tours(am, 60, la, true)
	_ok(am.bancs_pres(la, 62.0) >= 6 and am.bancs_pres(ici, 62.0) == 0, "260 m plus loin : les bancs sont revenus autour de soi (%d)" % am.bancs_pres(la, 62.0))
	# près du fond : les crabes
	var bas := Vector3(la.x, _height_at(la.x, la.z) + 1.5, la.z)
	_tours(am, 80, bas, true)
	var sur_le_fond: bool = true
	for c in am._crabes:
		if bool(c["vivant"]) and absf((c["pos"] as Vector3).y - _height_at((c["pos"] as Vector3).x, (c["pos"] as Vector3).z)) > 0.4:
			sur_le_fond = false
	_ok(am.crabes_pres(bas, 45.0) >= 6 and sur_le_fond, "au fond : des crabes posés sur le sable (%d)" % am.crabes_pres(bas, 45.0))
	# ------------------------------------------------------------------ hors de l'eau, sous le dôme
	_tours(am, 2, la, false)
	var caches: bool = not bool(am.crabes.visible)
	for b in am.bancs:
		if (b["mmi"] as Node3D).visible:
			caches = false
	_ok(caches, "hors de l'eau : plus rien (aucun coût à terre)")
	if mer_v55.atl != null:
		var dome := Vector3(-220.0, -28.0, 260.0)
		if mer_v55.atl.in_dome(dome):
			_tours(am, 5, dome, true)
			_ok(am.bancs_pres(dome, 200.0) == 0, "sous le dôme de l'Atlantide : pas de poisson dans l'air")
	# une eau trop peu profonde : aucun banc ne vient
	_tours(am, 2, la, false)
	var plage := Vector3(0.0, -0.6, 0.0)
	_tours(am, 20, plage, true)
	var bien: bool = true
	for b in am.bancs:
		if bool(b["vivant"]):
			var p2: Vector3 = b["pos"]
			if _height_at(p2.x, p2.z) > -0.42 - 3.4:
				bien = false
	_ok(bien, "près du village : aucun banc là où il n'y a pas 3,5 m d'eau")
	_tours(am, 2, plage, false)
	am.essai = false

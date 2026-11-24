## V201 : le parachute (le Saut des Nuées).
##   - un kiosque au bord de chaque île flottante, sur la terre ferme, avec un parachute à prendre ;
##   - sans parachute, on ne s'avance pas au-delà du bord ; avec, on peut sauter (là où il y a du vide) ;
##   - au PC : on saute, la chute libre accélère jusqu'à 200 km/h, la voile s'ouvre toute seule vers
##     60 m du sol, on se pose ;
##   - en VR : de même (le parachute mène le corps, l'origine XR suit) ; le voile de confort au choix.
const NOM := "36_parachute"


func _kiosque(nom: String) -> Array:
	for k in parachute_v201.kiosques:
		if str(k[0]) == nom:
			return k
	return []


## Le kiosque d'une île, sa direction vers le vide, et un point au-delà du bord.
func _bord(nom: String) -> Dictionary:
	var k: Array = _kiosque(nom)
	if k.is_empty():
		return {}
	var at: Vector3 = k[1]
	var n: Node3D = parachute_v201.get_node("Saut_des_Nuees_" + nom)
	var vers: Vector3 = -n.global_basis.z
	vers.y = 0.0
	vers = vers.normalized()
	# au-delà du bord : le premier point, en allant vers le vide, où l'on n'a plus le droit d'être
	var dehors: Vector3 = at
	for i in range(1, 40):
		var p: Vector3 = at + vers * (i * 1.0)
		if not pied_ok_v176(p):
			dehors = p + vers * 2.0
			break
	return {"at": at, "vers": vers, "dehors": dehors}


func _serie() -> void:
	var pa: Node3D = parachute_v201
	_ok(pa != null, "le parachute existe")
	# ------------------------------------------------------------------ les kiosques
	_ok(pa.kiosques.size() == 4, "un kiosque du Saut des Nuées sur chaque île flottante (%d)" % pa.kiosques.size())
	for k in pa.kiosques:
		var at: Vector3 = k[1]
		_ok(pied_ok_v176(at + Vector3.UP * 0.1) and at.y > 100.0, "%s : le kiosque est sur la terre ferme, là-haut (%.0f m)" % [k[0], at.y])
	_ok(inventory_v28.ITEMS.has("parachute") and inventory_v28.make_model("parachute").find_children("*", "MeshInstance3D", true, false).size() >= 3, "le parachute est un objet du sac, avec son modèle")
	# ------------------------------------------------------------------ le bord
	var b: Dictionary = _bord("astralys")
	_ok(not b.is_empty() and b["dehors"] != b["at"], "Astralys : on trouve le bord, devant le kiosque")
	if b.is_empty():
		return
	var dehors: Vector3 = b["dehors"]
	while inventory_v28.count("parachute") > 0:
		inventory_v28.remove("parachute", 1)
	_ok(not pa.laisse_sauter(dehors), "sans parachute : on ne s'avance pas au-delà du bord")
	inventory_v28.add("parachute", 1)
	_ok(pa.laisse_sauter(dehors), "avec un parachute : on peut sauter du bord")
	_ok(not pa.laisse_sauter(Vector3(0, 3, 0)), "ailleurs (le village) : rien ne change")
	# ------------------------------------------------------------------ au PC : le saut
	await _poser(b["at"] + b["vers"] * 1.0, b["vers"])
	await _att(0.5)
	pc_body.global_position = dehors + Vector3.UP * 0.3
	pc_body.velocity = Vector3(b["vers"].x * 2.0, 0.0, b["vers"].z * 2.0)
	hero_v28.state = "air"
	var vu_chute := false
	var vu_voile := false
	var h_ouverture: float = -1.0
	var v_max: float = 0.0
	var t: float = 0.0
	while t < 70.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if str(hero_v28.state) == "parachute":
			if pa.etat == "chute":
				vu_chute = true
				v_max = maxf(v_max, -pa.vitesse.y)
			elif pa.etat == "voile" and not vu_voile:
				vu_voile = true
				h_ouverture = pa.hauteur
		elif vu_chute and pa.etat == "sol":
			break
	_ok(vu_chute, "PC : on saute du bord, la chute libre commence")
	_ok(v_max > 50.0, "PC : la chute accélère jusqu'à %.0f km/h" % (v_max * 3.6))
	_ok(vu_voile and h_ouverture > 40.0 and h_ouverture < 75.0, "PC : la voile s'ouvre toute seule près du sol (à %.0f m)" % h_ouverture)
	_ok(pa.etat == "sol" and str(hero_v28.state) != "parachute", "PC : on se pose (%.0f s)" % t)
	_ok(inventory_v28.count("parachute") == 1, "le parachute se replie : on le garde")
	await _debout("PC : après l'atterrissage")
	# ------------------------------------------------------------------ en VR
	var c: Dictionary = _bord("citadelle")
	_ok(not c.is_empty(), "la Citadelle : on trouve le bord")
	if c.is_empty():
		return
	pa.confort = true
	vr_body.global_position = c["dehors"] + Vector3.UP * 0.3
	vr_body.velocity = Vector3(0, -5.0, 0)
	xr_camera.position = Vector3(0, 1.6, 0)
	var vu_vr := false
	var vu_voile_vr := false
	var vignette_vue := false
	var suit := true
	t = 0.0
	while t < 70.0:
		await get_tree().physics_frame
		var dt: float = get_physics_process_delta_time()
		t += dt
		var mene: bool = pa.vr_tick(dt)
		if not mene:
			if vu_vr:
				break
			continue
		vu_vr = true
		if pa.etat == "voile":
			vu_voile_vr = true
		if pa._vignette != null and pa._vignette.visible:
			vignette_vue = true
		if absf(xr_origin.position.y - vr_body.position.y) > 0.01:
			suit = false
	_ok(vu_vr, "VR : on saute, le parachute mène le corps")
	_ok(vu_voile_vr, "VR : la voile s'ouvre")
	_ok(suit, "VR : l'origine (la tête) suit le corps pendant toute la chute")
	_ok(vignette_vue, "VR : le voile de confort, si on l'a choisi")
	_ok(pa.etat == "sol", "VR : on se pose (%.0f s)" % t)
	pa.confort = false
	# ------------------------------------------------------------------ le réglage
	var avant: String = pa.libelle_confort()
	pa.basculer_confort()
	var apres: String = pa.libelle_confort()
	pa.basculer_confort()
	_ok(avant != apres and pa.libelle_confort() == avant, "Paramètres : le confort de chute se règle (%s / %s)" % [avant, apres])

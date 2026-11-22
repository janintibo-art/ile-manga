## V193 : Port-Boucan, la nuit, en « Public averti » (scripts/boucan_nuit_v193.gd).
##   - en Tout public : rien ne se voit (le nœud caché, pas de gens posés), Sirène ne sert pas de bière, le
##     Rieur ne pousse pas ;
##   - en Public averti, la nuit : les trois couples (enlacés : Pose193) et les quatre fumeurs du toit (deux
##     joints) sont posés ; Sirène sert la Hurlante, qui fait tourner la tête ; le Rieur pousse, on le croque :
##     le trip commence (l'écran, les sons), puis s'arrête et rend le bus son comme il était ;
##   - pendant le concert : Rouille arrose la fosse ; le slam porte le héros au-dessus de la foule jusqu'à la
##     régie, où il retombe debout ;
##   - retour en Tout public : tout s'éteint (les gens ne sont plus là ni dans le monde physique).
const NOM := "32_public_averti"


func _sert_biere() -> bool:
	var sir: Node = boucan_v75.by_id.get("sirene", null)
	if sir == null:
		return false
	for t in objets_v66._bar_topics(sir, "sirene", null):
		if str(t.get("id", "")) == "q56:service:boire193":
			return true
	return false


func _rieur_visible() -> bool:
	for e in boucan_v75.champis._picks:
		if str(e["kind"]) == "champi_rieur" and (e["node"] as Node3D).visible:
			return true
	return false


func _serie() -> void:
	var P = load("res://scripts/public_v111.gd")
	var B: Node = boucan_v75
	var N: Node = B.nuit if B != null else null
	_ok(N != null, "la nuit de Port-Boucan (boucan_nuit_v193) est là")
	if N == null:
		return
	P.choisir("tout", false)
	temps_v56.set_hour(22.0)
	await _poser(N.H(0.0, 0.3, -6.0), N.halle_xf.basis * Vector3(0, 0, -1))
	await _att(2.0)
	_ok(not N.root.visible and not N.gens_poses, "Tout public : rien de la nuit averti (caché, personne de posé)")
	_ok(not _sert_biere(), "Tout public : Sirène ne sert pas de bière")
	_ok(not _rieur_visible(), "Tout public : le Rieur ne pousse pas")
	P.choisir("averti", false)
	await _att(2.0)
	_ok(N.root.visible and N.gens_poses, "Public averti, la nuit : la nuit est là")
	_ok(N.couples.size() == 3 and N.fumeurs.size() == 4, "trois couples (%d), quatre fumeurs (%d)" % [N.couples.size(), N.fumeurs.size()])
	var poses: int = 0
	for c in N.couples:
		for f in c:
			var sk: Skeleton3D = f.npc.get("skel")
			if sk != null and sk.get_node_or_null("Pose193") != null:
				poses += 1
	_ok(poses == 6, "les six amoureux s'enlacent (%d poses)" % poses)
	var joints: int = 0
	for e in N.fumeurs:
		if e["joint"] != null and is_instance_valid(e["joint"]):
			joints += 1
	_ok(joints == 2, "deux joints qui tournent dans le cercle (%d)" % joints)
	_ok(_sert_biere(), "Sirène sert la Hurlante")
	objets_v66.ivresse = 0.0
	objets_v66.drink("biere_hurlante", true)
	_ok(objets_v66.ivresse > 0.3, "la Hurlante fait tourner la tête (%.2f)" % objets_v66.ivresse)
	objets_v66.ivresse = 0.0
	await _att(1.0)
	_ok(_rieur_visible(), "le Rieur pousse dans la Cathédrale des Spores")
	# le trip
	var bus: int = AudioServer.get_bus_index("Master")
	var fx0: int = AudioServer.get_bus_effect_count(bus)
	inventory_v28.add("champi_rieur", 1)
	_ok(B.champis.eat("champi_rieur"), "on croque le Rieur")
	await _att(4.0)
	_ok(N.trip_on and N._trip_layer != null and N.force() > 0.2, "le trip commence (force %.2f)" % N.force())
	_ok(AudioServer.get_bus_effect_count(bus) == fx0 + 2, "les sons s'étirent (deux effets sur le bus)")
	B.champis.active["champi_rieur"] = 0.2
	await _att(1.5)
	_ok(not N.trip_on and N._trip_layer == null, "le trip s'arrête")
	_ok(AudioServer.get_bus_effect_count(bus) == fx0, "le bus son est rendu comme il était")
	# le concert : la douche, le slam
	_ok(B.events.concert_on(), "le concert est en cours (22 h)")
	var d0: int = N.douches
	N.douche()
	_ok(N.douches == d0 + 1, "Rouille arrose la fosse")
	await _poser(N.H(0.0, 0.3, -14.0), N.halle_xf.basis * Vector3(0, 0, -1))
	await _att(1.0)
	_ok(N.can_slam(), "au bord de la scène, on peut se jeter dans la foule")
	var sol: float = _pos().y
	N.slam()
	await _att(3.0)
	_ok(N.slamming() and _pos().y > sol + 1.2, "la foule porte le héros (%.2f m au-dessus du sol)" % (_pos().y - sol))
	await _att(6.5)
	_ok(not N.slamming(), "le slam est fini")
	_ok(await _debout("après le slam"), "on retombe debout")
	_ok(_pos().distance_to(N._slam_b) < 2.0, "près de la régie (%.1f m)" % _pos().distance_to(N._slam_b))
	# retour en Tout public
	P.choisir("tout", false)
	await _att(1.5)
	var allumes: int = 0
	for c2 in N.couples:
		for f2 in c2:
			if f2.npc.visible or f2.npc.process_mode != Node.PROCESS_MODE_DISABLED:
				allumes += 1
	_ok(not N.root.visible and allumes == 0, "Tout public : tout s'éteint (%d encore là)" % allumes)
	_ok(not _sert_biere() and not _rieur_visible(), "Tout public : ni bière ni Rieur")
	P.oublier()
	temps_v56.set_hour(12.0)

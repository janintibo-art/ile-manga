## V197 : Néopolis, immeuble par immeuble. Le quatrième fait à la main : la Tour Orion (Orion Biotech, la
## maison du vivant), au sud de la Tour Hikari (scripts/neo/tour_orion_v197.gd).
##   - la ville a quatre immeubles faits à la main, dans l'ordre : Kumo, Vertex, Hikari, Orion ;
##   - la Tour Orion est bien l'immeuble au sud de Hikari ; ses boîtes ne sont plus dessinées (elles gardent
##     leurs collisions et leurs étages) ;
##   - ses vitres, ses jardinières et leurs arbustes (en lots : peu d'objets), l'Hélice et ses barreaux ;
##   - l'Hélice tourne ; les étoiles de la Ceinture d'Orion sont plus vives la nuit ;
##   - le socle de l'Hélice est solide ;
##   - on y entre comme avant (par la porte de l'ouest), on monte, on ressort ; dedans, ce qui est dans le
##     volume de la tour est caché ;
##   - les tours voisines ont gardé leur nom.
const NOM := "34_tour_orion"


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	var noms_u: Array = []
	for n in u:
		noms_u.append(str((n as Node).name))
	_ok(noms_u == ["Tour_Kumo_v187", "Tour_Vertex_v189", "Tour_Hikari_v195", "Tour_Orion_v197"], "quatre immeubles faits à la main, dans l'ordre (%s)" % ", ".join(PackedStringArray(noms_u)))
	if u.size() < 4:
		return
	var k: Node3D = u[3]
	var bt: Dictionary = k.bt
	var r: Array = bt["rect"]
	_ok(absf(float(r[0]) + 53.0) < 0.2 and absf(float(r[3]) + 127.0) < 0.2 and bt.has("unique"), "c'est l'immeuble au sud de Hikari (%s)" % str(r))
	var cachees: int = int(bt.get("boites_cachees", 0))
	_ok(cachees >= 1 and (bt["cols"] as Array).size() == cachees and (bt["segs"] as Array).size() == cachees, "ses boîtes ne sont plus dessinées (%d) ; elles gardent leurs collisions et leurs étages" % cachees)
	_ok(int(k.nb_vitres) > 350, "ses vitres (%d)" % int(k.nb_vitres))
	_ok(int(k.nb_jardinieres) > 50 and int(k.nb_plantes) > 300, "ses jardins : %d jardinières, %d arbustes" % [int(k.nb_jardinieres), int(k.nb_plantes)])
	var lots: int = k.find_children("Orion_jardins_*", "MultiMeshInstance3D", true, false).size()
	_ok(lots == 3, "les arbustes sont dessinés en trois lots (%d)" % lots)
	_ok(int(k.nb_barreaux) > 30, "l'Hélice et ses barreaux (%d)" % int(k.nb_barreaux))
	var lettres: int = k.find_children("*", "Label3D", true, false).size()
	_ok(lettres >= 3, "son nom : au-dessus de la porte, en haut, au pied de l'Hélice (%d)" % lettres)
	# l'Hélice tourne ; les étoiles, le jour et la nuit
	var a0: Basis = k.helice.global_transform.basis
	await _att(0.8)
	_ok(not a0.is_equal_approx(k.helice.global_transform.basis), "l'Hélice tourne")
	temps_v56.set_hour(13.0)
	await _att(1.0)
	var jour: float = (k._etoiles as StandardMaterial3D).emission_energy_multiplier
	temps_v56.set_hour(23.0)
	await _att(1.5)
	var nuit: float = (k._etoiles as StandardMaterial3D).emission_energy_multiplier
	_ok(jour < 2.0 and nuit > 4.0, "les étoiles de la Ceinture d'Orion : %.1f le jour, %.1f la nuit" % [jour, nuit])
	temps_v56.set_hour(12.0)
	# le socle de l'Hélice : solide
	var F: Array = k._faces(k.RO)
	var fw: Dictionary = F[3]
	var c: Vector3 = k._p(fw, k.S_HELICE, 8.0, k.D_HELICE)
	var q := PhysicsRayQueryParameters3D.create(c, c + Vector3.DOWN * 8.0)
	var hit: Dictionary = k.get_world_3d().direct_space_state.intersect_ray(q)
	_ok(not hit.is_empty() and float((hit["position"] as Vector3).y) > 4.4, "l'Hélice est solide (on bute dessus à %.2f m)" % (float((hit.get("position", Vector3.ZERO) as Vector3).y) if not hit.is_empty() else -1.0))
	# on y entre, on monte, on ressort
	var T: Node = N.tours
	_ok(int(k.tid) >= 0 and str(T.tours[int(k.tid)]["nom"]) == "Tour Orion", "la tour s'appelle toujours la Tour Orion (n° %d)" % int(k.tid))
	_ok((k.dedans as Node3D).visible, "dehors : le hall et son mur végétal sont là")
	await T.enter(int(k.tid))
	await _att(0.6)
	_ok(int(T.inside) == int(k.tid) and not (k.dedans as Node3D).visible, "dedans : ce qui est dans le volume de la tour est caché")
	await T.aller(5)
	await _att(0.6)
	_ok(int(T.etage) == 5, "on monte au 5e")
	await T.leave()
	await _att(0.8)
	_ok(int(T.inside) < 0 and (k.dedans as Node3D).visible, "on ressort : tout revient")
	var f: Vector3 = T.tours[int(k.tid)]["face"]
	var att: Vector3 = N._ground(float(r[0]), (float(r[1]) + float(r[3])) * 0.5)
	_ok(Vector2(f.x - att.x, f.z - att.z).length() < 0.3, "la porte est toujours au milieu de la façade de l'ouest (sous l'auvent)")
	var noms: Array = []
	for i2 in [72, 73, 74, 83]:
		noms.append(str(T.tours[i2]["nom"]))
	_ok(noms == ["Tour Hikari", "Tour Orion", "Tour Kumo", "Tour Vertex"], "les tours voisines ont gardé leur nom (%s)" % ", ".join(PackedStringArray(noms)))

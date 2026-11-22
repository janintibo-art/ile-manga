## V195 : Néopolis, immeuble par immeuble. Le troisième fait à la main : la Tour Hikari (Hikari Systèmes, la
## maison de la lumière), à l'ouest de la Tour Kumo, sur le quai (scripts/neo/tour_hikari_v195.gd).
##   - la ville a trois immeubles faits à la main, dans l'ordre : Kumo, Vertex, Hikari ;
##   - la Tour Hikari est bien l'immeuble du quai, à l'ouest de Kumo ; ses boîtes ne sont plus dessinées
##     (elles gardent leurs collisions et leurs étages) ;
##   - ses vitres, ses lames, ses fibres (leur matière est bien le shader des impulsions) ;
##   - l'anneau de l'entrée tourne ; le faisceau du toit est éteint le jour, allumé la nuit ;
##   - le Prisme et son projecteur sont solides ;
##   - on y entre comme avant (par la porte de l'ouest), on monte, on ressort ; dedans, ce qui est dans le
##     volume de la tour est caché ;
##   - les tours voisines ont gardé leur nom.
const NOM := "33_tour_hikari"


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	var noms_u: Array = []
	for n in u:
		noms_u.append(str((n as Node).name))
	_ok(noms_u.slice(0, 3) == ["Tour_Kumo_v187", "Tour_Vertex_v189", "Tour_Hikari_v195"], "les trois premiers immeubles faits à la main, dans l'ordre (%s)" % ", ".join(PackedStringArray(noms_u)))
	if u.size() < 3:
		return
	var k: Node3D = u[2]
	var bt: Dictionary = k.bt
	var r: Array = bt["rect"]
	_ok(absf(float(r[0]) + 53.0) < 0.2 and absf(float(r[1]) + 173.0) < 0.2 and bt.has("unique"), "c'est l'immeuble du quai, à l'ouest de Kumo (%s)" % str(r))
	var cachees: int = int(bt.get("boites_cachees", 0))
	_ok(cachees >= 1 and (bt["cols"] as Array).size() == cachees and (bt["segs"] as Array).size() == cachees, "sa boîte n'est plus dessinée (%d) ; elle garde ses collisions et ses étages" % cachees)
	_ok(int(k.nb_vitres) > 350, "ses vitres (%d)" % int(k.nb_vitres))
	_ok(int(k.nb_lames) > 400, "ses lames blanches (%d)" % int(k.nb_lames))
	_ok(int(k.nb_fibres) > 40, "ses fibres (%d)" % int(k.nb_fibres))
	var Kit = load("res://scripts/neo_kit_v94.gd")
	var fi: Variant = Kit._mcache.get("k195_fibre")
	_ok(fi is ShaderMaterial and (fi as ShaderMaterial).shader != null and (fi as ShaderMaterial).shader.resource_path.contains("fibre_v195"), "les fibres ont leur matière (les impulsions)")
	var lettres: int = k.find_children("*", "Label3D", true, false).size()
	_ok(lettres >= 14, "son nom : au-dessus de la porte, sur le toit, sur la lame (%d)" % lettres)
	# l'anneau tourne ; le faisceau, le jour et la nuit
	var a0: Basis = k._anneau.global_transform.basis
	await _att(0.8)
	_ok(not a0.is_equal_approx(k._anneau.global_transform.basis), "l'anneau de lumière de l'entrée tourne")
	temps_v56.set_hour(13.0)
	await _att(1.0)
	var jour: float = (k._faisceau as StandardMaterial3D).albedo_color.v
	temps_v56.set_hour(23.0)
	await _att(1.5)
	var nuit: float = (k._faisceau as StandardMaterial3D).albedo_color.v
	_ok(jour < 0.02 and nuit > 0.2, "le faisceau du toit : éteint le jour (%.2f), allumé la nuit (%.2f)" % [jour, nuit])
	temps_v56.set_hour(12.0)
	# le Prisme : solide
	var F: Array = k._faces(k.RH)
	var fq: Dictionary = F[0]
	var c: Vector3 = k._p(fq, float(fq["l"]) - 6.0, 4.0, 1.7)
	var q := PhysicsRayQueryParameters3D.create(c, c + Vector3.DOWN * 4.0)
	var hit: Dictionary = k.get_world_3d().direct_space_state.intersect_ray(q)
	_ok(not hit.is_empty() and float((hit["position"] as Vector3).y) > 1.4 + 0.6, "le socle du Prisme est solide (on s'y pose à %.2f m)" % (float((hit.get("position", Vector3.ZERO) as Vector3).y) if not hit.is_empty() else -1.0))
	# on y entre, on monte, on ressort
	var T: Node = N.tours
	_ok(int(k.tid) >= 0 and str(T.tours[int(k.tid)]["nom"]) == "Tour Hikari", "la tour s'appelle toujours la Tour Hikari (n° %d)" % int(k.tid))
	_ok((k.dedans as Node3D).visible, "dehors : le laboratoire et le sas sont là")
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
	_ok(Vector2(f.x - att.x, f.z - att.z).length() < 0.3, "la porte est toujours au milieu de la façade de l'ouest (au bout du tunnel)")
	var noms: Array = []
	for i2 in [72, 73, 74, 83]:
		noms.append(str(T.tours[i2]["nom"]))
	_ok(noms == ["Tour Hikari", "Tour Orion", "Tour Kumo", "Tour Vertex"], "les tours voisines ont gardé leur nom (%s)" % ", ".join(PackedStringArray(noms)))

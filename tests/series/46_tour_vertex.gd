## V189 : Néopolis, immeuble par immeuble. Le deuxième fait à la main : la Tour Vertex, la banque Vertex Finances
## (scripts/neo/tour_vertex_v189.gd), de l'autre côté du Boulevard des Néons : avec la Tour Kumo, elle fait la
## porte de la ville. Avant : une grande boîte habillée du même matériau que toute la ville.
##   - la ville a deux immeubles faits à la main ; le second est bien celui d'en face (la « Tour Vertex ») ;
##   - ses boîtes ne sont plus dessinées (elles gardent leurs collisions et leurs étages) ;
##   - il a ses vitres (plus de 400), le bandeau des cours, son nom ; la pièce d'or de l'entrée tourne ;
##     l'horloge de l'angle a ses quatre aiguilles (deux cadrans), et elles suivent l'heure ;
##   - on y entre comme avant (par la porte de l'est), on ressort ; dedans, ce qui est dans le volume de la
##     tour (la colonnade, le jardin d'hiver) est caché, et revient quand on sort ;
##   - la Tour Kumo est toujours la première, et les tours voisines ont gardé leur nom.
const NOM := "46_tour_vertex"


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	_ok(u.size() >= 2 and str((u[0] as Node).name) == "Tour_Kumo_v187", "la ville a %d immeubles faits à la main, la Tour Kumo d'abord" % u.size())
	if u.size() < 2:
		return
	var k: Node3D = u[1]
	var bt: Dictionary = k.bt
	var r: Array = bt["rect"]
	_ok(str(k.name) == "Tour_Vertex_v189" and absf(float(r[0]) - 9.5) < 0.2 and absf(float(r[1]) + 173.0) < 0.2 and bt.has("unique"), "le second est l'immeuble d'en face, sur le quai (%s)" % str(r))
	var cachees: int = int(bt.get("boites_cachees", 0))
	_ok(cachees >= 1 and (bt["cols"] as Array).size() == cachees and (bt["segs"] as Array).size() == cachees, "sa boîte n'est plus dessinée (%d) ; elle garde ses collisions et ses étages" % cachees)
	_ok(int(k.nb_vitres) > 400, "ses vitres (%d)" % int(k.nb_vitres))
	var Kit = load("res://scripts/neo_kit_v94.gd")
	var tk: Variant = Kit._mcache.get("k189_ticker")
	_ok(tk is ShaderMaterial and (tk as ShaderMaterial).shader != null, "le bandeau des cours a sa matière")
	var images: int = 0
	for mi in k.find_children("*", "MeshInstance3D", true, false):
		var mo: Material = (mi as MeshInstance3D).material_override
		if mo is ShaderMaterial and (mo as ShaderMaterial).shader != null and (mo as ShaderMaterial).shader.resource_path.contains("ecran_v94"):
			images += 1
	_ok(images >= 3, "son nom, sur le toit et au-dessus des guichets (%d)" % images)
	# la pièce d'or tourne ; l'horloge suit l'heure
	var p: Node3D = k._piece
	var a0: float = p.rotation.y
	await _att(0.6)
	_ok(absf(angle_difference(a0, p.rotation.y)) > 0.1, "la pièce d'or de l'entrée tourne")
	var aig: Array = k._aiguilles
	_ok(aig.size() == 4, "l'horloge de l'angle : deux cadrans, quatre aiguilles")
	if aig.size() == 4:
		var h: float = float(N.hour())
		var petite: Node3D = aig[0][0]
		var base: Transform3D = aig[0][1]
		var vu: float = (base.basis.inverse() * petite.global_transform.basis).get_euler().z
		_ok(absf(angle_difference(vu, -fposmod(h, 12.0) / 12.0 * TAU)) < 0.05, "la petite aiguille est à l'heure (%.1f h)" % h)
	# on y entre, on ressort
	var T: Node = N.tours
	_ok(int(k.tid) >= 0 and str(T.tours[int(k.tid)]["nom"]) == "Tour Vertex", "la tour s'appelle toujours la Tour Vertex (n° %d)" % int(k.tid))
	_ok((k.dedans as Node3D).visible, "dehors : la colonnade et le jardin d'hiver sont là")
	await T.enter(int(k.tid))
	await _att(0.6)
	_ok(int(T.inside) == int(k.tid) and not (k.dedans as Node3D).visible, "dedans : ce qui est dans le volume de la tour est caché")
	await T.leave()
	await _att(0.8)
	_ok(int(T.inside) < 0 and (k.dedans as Node3D).visible, "on ressort : tout revient")
	var f: Vector3 = T.tours[int(k.tid)]["face"]
	var att: Vector3 = N._ground(float(r[2]), (float(r[1]) + float(r[3])) * 0.5)
	_ok(Vector2(f.x - att.x, f.z - att.z).length() < 0.3, "la porte est toujours au milieu de la façade de l'est")
	var noms: Array = []
	for i2 in [72, 74, 75, 84]:
		noms.append(str(T.tours[i2]["nom"]))
	_ok(noms == ["Tour Hikari", "Tour Kumo", "Tour Prisme", "Tour Zénith"], "les tours voisines ont gardé leur nom (%s)" % ", ".join(PackedStringArray(noms)))

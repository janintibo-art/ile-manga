## V187 : Néopolis, immeuble par immeuble. Le premier fait à la main : la Tour Kumo (Kumo Logistique), à l'angle
## du Quai des Drones et du Boulevard des Néons (scripts/neo/tour_kumo_v187.gd). Avant : deux boîtes empilées et
## un matériau qui peignait fenêtres, rideau de fer et vitrine, les mêmes dans toute la ville.
##   - la ville a un immeuble fait à la main, et c'est bien celui de l'angle du quai (la « Tour Kumo ») ;
##   - ses boîtes ne sont plus dessinées (elles gardent leurs collisions et leurs étages) ;
##   - il a ses vitres (plus de 400), ses enseignes, ses drones en vol, et ses drones avancent ;
##   - on y entre comme avant (par la porte du quai), on monte, on ressort ; dedans, ce qui est dans le volume
##     de la tour (le dépôt, la vitrine, les loggias) est caché, et revient quand on sort ;
##   - les autres tours n'ont pas changé de place ni de nom (le hasard de la ville est tiré comme avant).
const NOM := "44_tour_kumo"


func _serie() -> void:
	var N: Node3D = neo_v94
	var u: Array = N.uniques
	_ok(u.size() >= 1, "la ville a un immeuble fait à la main (%d)" % u.size())
	if u.is_empty():
		return
	var k: Node3D = u[0]
	var bt: Dictionary = k.bt
	var r: Array = bt["rect"]
	_ok(absf(float(r[2]) + 9.5) < 0.2 and absf(float(r[1]) + 173.0) < 0.2 and bt.has("unique"), "c'est l'immeuble de l'angle du quai et du boulevard (%s)" % str(r))
	# ses boîtes : cachées dans le lot des tours (réduites à rien, sous le sol)
	var cachees: int = int(bt.get("boites_cachees", 0))
	_ok(cachees >= 2, "ses %d boîtes ne sont plus dessinées" % cachees)
	_ok((bt["cols"] as Array).size() == cachees and (bt["segs"] as Array).size() == cachees, "elles gardent leurs collisions et leurs étages")
	_ok(int(k.nb_vitres) > 400, "ses vitres (%d)" % int(k.nb_vitres))
	var images: int = 0
	for mi in k.find_children("*", "MeshInstance3D", true, false):
		var mo: Material = (mi as MeshInstance3D).material_override
		if mo is ShaderMaterial and (mo as ShaderMaterial).shader != null and (mo as ShaderMaterial).shader.resource_path.contains("ecran_v94"):
			images += 1
	_ok(images >= 8, "son écran et ses enseignes (%d)" % images)
	var d0: Vector3 = (k._drones[0]["n"] as Node3D).global_position
	await _att(1.0)
	var d1: Vector3 = (k._drones[0]["n"] as Node3D).global_position
	_ok(k._drones.size() == 6 and d0.distance_to(d1) > 0.5, "ses six drones volent (le premier a fait %.1f m en une seconde)" % d0.distance_to(d1))
	# on y entre, on monte, on ressort
	var T: Node = N.tours
	_ok(int(k.tid) >= 0 and str(T.tours[int(k.tid)]["nom"]) == "Tour Kumo", "la tour s'appelle toujours la Tour Kumo (n° %d)" % int(k.tid))
	_ok((k.dedans as Node3D).visible, "dehors : le dépôt, la vitrine et les loggias sont là")
	await T.enter(int(k.tid))
	await _att(0.6)
	_ok(int(T.inside) == int(k.tid) and not (k.dedans as Node3D).visible, "dedans : ce qui est dans le volume de la tour est caché")
	await T.aller(7)
	await _att(0.6)
	_ok(int(T.etage) == 7 and str(T.info.get("type", "")) == "jardin", "on monte au jardin du 7e")
	await T.leave()
	await _att(0.8)
	_ok(int(T.inside) < 0 and (k.dedans as Node3D).visible, "on ressort : tout revient")
	# la porte de la tour : au milieu de la façade du quai
	var f: Vector3 = T.tours[int(k.tid)]["face"]
	var att: Vector3 = N._ground((float(r[0]) + float(r[2])) * 0.5, float(r[1]))
	_ok(Vector2(f.x - att.x, f.z - att.z).length() < 0.3, "la porte est toujours au milieu de la façade du quai")
	# le hasard de la ville : les voisines n'ont pas bougé
	var noms: Array = []
	for i2 in [72, 73, 75, 76]:
		noms.append(str(T.tours[i2]["nom"]))
	_ok(noms == ["Tour Hikari", "Tour Orion", "Tour Prisme", "Tour Quasar"], "les tours voisines ont gardé leur nom (%s)" % ", ".join(PackedStringArray(noms)))

## V192 : la rue vitrine (scripts/neo/rue_vitrine_v192.gd) et la portée des petites choses (scripts/portee_v192.gd).
##   - la rue est posée : ses quatre lumières (deux lanternes de bronze, deux mâts froids), ses quatre bornes,
##     le robot de livraison ;
##   - on marche librement le long des deux trottoirs, du quai jusqu'au banc, et on traverse entre les deux
##     portes ; on tient debout sur la traversée ;
##   - la portée : une petite chose (1,3 m) n'est plus dessinée au-delà de 300 m environ, une grande (50 m)
##     toujours ; des milliers d'objets ont reçu leur portée ; les grands modèles de l'île de départ aussi ;
##     les tours de Néopolis, non.
const NOM := "49_rue_vitrine"


func _serie() -> void:
	var N: Node3D = neo_v94
	var r: Dictionary = N.rue_v192
	_ok(not r.is_empty() and r.get("noeud") != null, "la rue vitrine est posée")
	if r.is_empty():
		return
	var lum: Array = r["lumieres"]
	var bonnes: int = 0
	for l in lum:
		if l is OmniLight3D and is_instance_valid(l) and not (l as OmniLight3D).shadow_enabled:
			bonnes += 1
	_ok(bonnes == 4, "ses quatre lumières, sans ombres (%d)" % bonnes)
	_ok(int(r["bornes"]) == 4 and int(r["mats"]) == 4, "ses bornes (%d) et ses mâts (%d)" % [int(r["bornes"]), int(r["mats"])])
	# les trottoirs et la traversée : rien qui arrête le héros
	var zc: float = float((r["traversee"] as Vector2).x + (r["traversee"] as Vector2).y) * 0.5
	for x in [-7.25, 7.75]:
		var a: Vector3 = N._ground(x, -175.0)
		var b: Vector3 = N._ground(x, -151.0)
		_ok(_voie_libre(a, b), "on longe le trottoir (x %.2f) du quai jusqu'au banc" % x)
	_ok(_voie_libre(N._ground(-7.25, zc), N._ground(7.75, zc)), "on traverse le boulevard entre les deux portes")
	await _poser(N._ground(0.0, zc) + Vector3.UP * 0.3, Vector3(1, 0, 0))
	_ok(await _debout("la traversée"), "on tient debout sur la traversée")
	_ok(absf(_pos().y - N._ground(0.0, zc).y) < 0.6, "à la hauteur de la rue (%.2f / %.2f)" % [_pos().y, N._ground(0.0, zc).y])
	# la portée
	var P = load("res://scripts/portee_v192.gd")
	_ok(absf(float(P.portee(1.3)) - 302.0) < 1.0 and float(P.portee(50.0)) == 0.0 and float(P.portee(29.0)) == 1200.0, "la règle : 1,3 m → %.0f m, 29 m → %.0f m, 50 m → toujours" % [float(P.portee(1.3)), float(P.portee(29.0))])
	_ok(int(portee_v192.reglees) > 5000, "%d petites choses ont leur portée" % int(portee_v192.reglees))
	var maison: Node = get_node_or_null("Petite_maison")
	var reglee: bool = false
	if maison != null:
		for g in maison.find_children("*", "GeometryInstance3D", true, false):
			if (g as GeometryInstance3D).visibility_range_end > 0.0:
				reglee = true
	_ok(maison != null and reglee, "la Petite maison de l'île de départ a sa portée")
	var tours_ok: bool = true
	for u in N.uniques:
		for g in (u as Node).find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if (gi.global_transform * gi.get_aabb()).size.length() > 40.0 and gi.visibility_range_end > 0.0:
				tours_ok = false
	_ok(tours_ok, "les grandes masses des tours de Néopolis restent visibles de loin")

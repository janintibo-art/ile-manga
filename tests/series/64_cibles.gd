## La lisibilité et le ciblage (V144) : la barre de vie des ennemis blessés (la part perdue, l'état,
## la faiblesse), l'anneau de la cible, le verrouillage (C : verrouiller, suivant, relâcher), les
## coups et les sorts vers la cible verrouillée, l'alerte « ! », les textes en anglais.
const NOM := "cibles"


func _vider() -> void:
	for b in faune_v132.betes.duplicate():
		if is_instance_valid(b):
			b.queue_free()
	faune_v132.betes.clear()
	elements_v143.reset()
	cibles_v144.reset()


## Une bête immobile devant le héros (à « avant » mètres, décalée de « cote » mètres).
func _bete(kind: String, avant: float = 2.5, cote: float = 0.0) -> Node3D:
	var f: Vector3 = hero_v28.facing
	var q: Vector3 = _pos() + f * avant + f.cross(Vector3.UP) * cote
	q.y = _height_at(q.x, q.z) + 0.1
	var b: Node3D = faune_v132.spawn(kind, q)
	b.set_physics_process(false)
	return b


## Un coin bien plat et dégagé autour du héros (les bêtes y sont à sa hauteur, et ni arbre ni rocher
## n'arrête une boule de feu ou un éclair en chemin) : on s'y pose, tourné vers le nord. S'il n'y a
## pas de coin à la fois plat et dégagé, on prend le plus plat.
func _plat() -> bool:
	var o: Vector3 = _pos()
	var best: Vector3 = o
	var bd: float = INF
	var libre: Vector3 = Vector3.INF
	var ld: float = 0.5
	for r in range(0, 90, 3):
		for k in range(16):
			var a: float = TAU * k / 16.0 + r * 0.37
			var c := Vector3(o.x + cos(a) * r, 0, o.z + sin(a) * r)
			var h0: float = _height_at(c.x, c.z)
			if h0 < 1.0:
				continue
			var d: float = 0.0
			for dz in [0.0, -3.0, -6.0, -9.0, -12.0]:
				for dx in [-3.0, 0.0, 3.0]:
					d = maxf(d, absf(_height_at(c.x + dx, c.z + dz) - h0))
			if d < bd:
				bd = d
				best = Vector3(c.x, h0, c.z)
			if d < ld and _degage(Vector3(c.x, h0, c.z)):
				ld = d
				libre = Vector3(c.x, h0, c.z)
		if libre != Vector3.INF and ld < 0.3:
			break
	if libre != Vector3.INF:
		best = libre
		bd = ld
	_poser(best + Vector3.UP * 0.2, Vector3.FORWARD)
	return bd < 0.5


## Rien entre le héros (posé en c, tourné vers le nord) et les bêtes que l'on met devant lui ?
func _degage(c: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var sauf: Array = []
	if pc_body != null:
		sauf.append(pc_body.get_rid())
	for h in [0.7, 1.3]:
		for vers in [Vector3(0, 0, -13.0), Vector3(-2.2, 0, -12.0), Vector3(2.2, 0, -12.0)]:
			var b: Vector3 = c + vers
			b.y = _height_at(b.x, b.z) + h
			var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * h, b, 1)
			q.exclude = sauf
			if not space.intersect_ray(q).is_empty():
				return false
	return true


func _sol() -> void:
	for k in range(40):
		if str(hero_v28.state) == "sol":
			return
		await _att(0.05)


func _pret() -> void:
	sorts_v67.mana = float(sorts_v67.mana_max())
	sorts_v67._cd.clear()
	pouvoirs_v63._cd.clear()
	await _sol()


func _serie() -> void:
	testeur_v78._faune_v132("elfes")
	await _att(0.5)
	faune_v132.enabled = false
	var plat: bool = _plat()
	await _att(0.6)
	await _sol()
	_ok(plat, "un coin plat pour l'essai")
	var cv: Node = cibles_v144
	var el: Node = elements_v143
	_ok(cv != null, "le module des cibles existe")
	_vider()
	await _images(2)
	testeur_v78._pick("h_tout")
	await _att(0.3)
	_close_dialogue_v31()
	await _att(0.2)
	inventory_v28.equip_item("")
	await _att(0.3)
	# --- une bête paisible et intacte : ni cible, ni barre
	cv.barres_vues = 0
	var b: Node3D = _bete("sanglier", 4.0)
	await _att(0.4)
	_ok(cv.cible == null and cv.barres_vues == 0, "une bête intacte et tranquille : pas de cible, pas de barre (%s, %d, état %s, hp %d)" % [str(cv.cible), cv.barres_vues, str(b.state), int(b.hp)])
	# --- blessée : la barre de vie, l'anneau
	var pv: int = int(b.hp)
	b.take_hit(5, _pos())
	await _att(0.4)
	var s: Dictionary = cv._suivi.get(b.get_instance_id(), {})
	_ok(cv.barres_vues == 1 and s.get("bar") != null and (s["bar"] as Node3D).visible, "blessée : sa barre de vie apparaît")
	_ok(int(s.get("max", 0)) == pv and int(s.get("hp", 0)) == pv - 5, "la barre connaît sa vie (%d / %d)" % [int(s.get("hp", 0)), int(s.get("max", 0))])
	var fill: QuadMesh = (s["fill_q"] as MeshInstance3D).mesh
	var plein: float = clampf(float(b.get("hit_radius")) * 2.4, 0.7, 2.6)
	_ok(absf(fill.size.x - plein * float(pv - 5) / float(pv)) < 0.02, "la barre est remplie à proportion (%.2f sur %.2f)" % [fill.size.x, plein])
	_ok(float(s["ghost"]) > float(pv - 5) / float(pv) + 0.05, "la part perdue reste claire un instant")
	await _att(1.2)
	_ok(absf(float(s["ghost"]) - float(pv - 5) / float(pv)) < 0.02, "… puis elle se vide")
	_ok((s["nom"] as Label3D).text == "Sanglier des bois", "son nom est écrit (%s)" % (s["nom"] as Label3D).text)
	_ok(cv.cible == b and not cv.verrou and cv._anneau != null and cv._anneau.visible, "la bête blessée devant soi est la cible : l'anneau est à ses pieds")
	_ok(cv._anneau.global_position.distance_to(b.global_position) < 0.3, "l'anneau est sous la cible")
	# --- l'état et la faiblesse sur la barre
	el.enflammer(b)
	await _images(3)
	_ok((s["info"] as Label3D).text == "En feu", "la barre dit « En feu » (%s)" % (s["info"] as Label3D).text)
	el._efface(b)
	_vider()
	await _images(2)
	el.decouvertes.clear()
	var ro: Node3D = _bete("ronceux_sauvage", 3.0)
	ro.hp = 60
	ro.take_hit(1, _pos())
	await _att(0.4)
	var sr: Dictionary = cv._suivi.get(ro.get_instance_id(), {})
	_ok(cv.cible == ro and (sr["info"] as Label3D).text == "Craint : ?", "une faiblesse inconnue : « Craint : ? » (%s)" % (sr["info"] as Label3D).text)
	el.hit(ro, "feu", 2, _pos())
	el._efface(ro)
	await _images(3)
	_ok(el.connue(ro) and (sr["info"] as Label3D).text == "Craint le feu", "la faiblesse trouvée : « Craint le feu » (%s)" % (sr["info"] as Label3D).text)
	var sv: Dictionary = el.serialize()
	el.load_data(sv)
	_ok(el.decouvertes.has("plante"), "la faiblesse découverte est retenue dans la sauvegarde")
	_vider()
	await _images(2)
	# --- le verrouillage
	await _pret()
	var f: Vector3 = hero_v28.facing
	var a1: Node3D = _bete("sanglier", 6.0, 0.0)
	var a2: Node3D = _bete("sanglier", 3.0, 7.0)
	a1.hp = 60
	a2.hp = 60
	a1.state = "chasse"
	a2.state = "chasse"
	await _att(0.3)
	var ev := InputEventKey.new()
	ev.keycode = KEY_C
	ev.pressed = true
	_ok(cv.handle_input(ev) and cv.verrou and cv.cible == a1, "C : l'ennemi devant soi est verrouillé")
	await _images(3)
	_ok(cv._anneau_mat.albedo_color.g < 0.5, "l'anneau devient rouge")
	# le héros regarde ailleurs : le sort part quand même vers la cible verrouillée
	hero_v28.facing = f.cross(Vector3.UP).normalized()
	var d: Vector3 = cv.direction(_pos() + Vector3.UP)
	var vers: Vector3 = a1.global_position - _pos()
	vers.y = 0.0
	_ok(d.dot(vers.normalized()) > 0.98, "la direction du coup : vers la cible verrouillée")
	_ok(sorts_v67.cast("foudre"), "la Foudre part")
	await _images(3)
	_ok(el.last_chain.size() >= 1 and el.last_chain[0] == a1 and int(a1.hp) == 55, "la Foudre frappe la cible verrouillée, pas l'ennemi le plus proche (%d)" % int(a1.hp))
	_ok(hero_v28.facing.dot(vers.normalized()) > 0.95, "le héros s'est tourné vers elle")
	await _att(1.6)
	await _pret()
	hero_v28.facing = f.cross(Vector3.UP).normalized()
	_ok(sorts_v67.cast("feu"), "la boule de feu part")
	await _att(0.8)
	_ok(int(a1.hp) < 55, "la boule de feu touche la cible verrouillée (%d)" % int(a1.hp))
	# de près : le coup d'arme se tourne vers elle
	var p1: Vector3 = a1.global_position - vers.normalized() * 2.2
	_poser(Vector3(p1.x, _height_at(p1.x, p1.z) + 0.2, p1.z), -vers.normalized())
	await _att(0.4)
	hero_v28.facing = -vers.normalized()
	hero_v28._face_nearest_target()
	_ok(hero_v28.facing.dot(vers.normalized()) > 0.95, "de près, le coup se tourne vers la cible verrouillée (même dos à elle)")
	# C de nouveau : le suivant ; puis on relâche
	cv.basculer()
	_ok(cv.verrou and cv.cible == a2, "C de nouveau : l'ennemi suivant")
	# la caméra tourne doucement pour garder l'ennemi verrouillé devant
	await _att(2.5)
	var cf: Vector3 = -pc_root.global_basis.z
	cf.y = 0.0
	var v2: Vector3 = a2.global_position - pc_root.global_position
	v2.y = 0.0
	_ok(cv.verrou and absf(cf.signed_angle_to(v2, Vector3.UP)) < 0.45, "la caméra a tourné vers l'ennemi verrouillé (%.2f rad d'écart)" % absf(cf.signed_angle_to(v2, Vector3.UP)))
	cv.basculer()
	_ok(not cv.verrou, "C après le dernier : on relâche")
	# la cible meurt : le verrou tombe
	cv.cible = a1
	cv.verrou = true
	a1.take_hit(999, _pos())
	await _att(0.4)
	_ok(not cv.verrou and cv.cible != a1, "la cible vaincue : le verrou tombe")
	# --- l'alerte : il arme son coup
	var n0: int = cv.alertes
	a2.state = "armer"
	await _images(3)
	_ok(cv.alertes == n0 + 1, "« ! » : l'ennemi arme son coup")
	a2.state = "chasse"
	await _att(0.6)
	a2.state = "armer"
	await _images(3)
	_ok(cv.alertes == n0 + 2, "… à chaque nouveau coup")
	a2.state = "frappe"
	await _att(0.6)
	a2.state = "souffle"
	await _att(0.6)
	_ok(cv.alertes == n0 + 2, "pas de « ! » quand il frappe ni quand il reprend son souffle")
	a2.state = "charge"
	await _att(0.6)
	_ok(cv.alertes == n0 + 3, "« ! » pour une charge qui part sans prévenir")
	a2.state = "armer"
	await _att(0.6)
	a2.state = "charge"
	await _att(0.6)
	_ok(cv.alertes == n0 + 4, "… mais un seul « ! » quand il arme puis charge")
	# un vrai sanglier (il gratte le sol, charge, souffle) : un « ! » chaque fois qu'il arme, pas un de plus
	_vider()
	await _images(3)
	var n1: int = cv.alertes
	var sg: Node3D = _bete("sanglier", 6.0)
	sg.set_physics_process(true)
	faune_v132.enabled = true
	faune_v132._tick = 9999.0
	var armes: int = 0
	var avant: String = ""
	for k in range(150):
		await _att(0.03)
		if not is_instance_valid(sg):
			break
		var st2: String = str(sg.state)
		if st2 != avant:
			if st2 == "armer":
				armes += 1
			avant = st2
	faune_v132.enabled = false
	_ok(armes >= 1 and cv.alertes - n1 == armes, "un vrai sanglier : %d fois il arme sa charge, %d « ! » (à %.0f m)" % [armes, cv.alertes - n1, sg.global_position.distance_to(_pos()) if is_instance_valid(sg) else -1.0])
	_vider()
	await _images(3)
	_ok(cv.cible == null and not cv._anneau.visible, "plus d'ennemi : plus de cible, plus d'anneau")
	# --- en anglais
	var L = load("res://scripts/langue_v104.gd")
	L.choisir("en", false)
	var t1: String = L.t("Craint le feu")
	var t2: String = L.t("Aucun ennemi à verrouiller devant toi.")
	L.choisir("fr", false)
	_ok(t1 == "Fears fire", "anglais : « %s »" % t1)
	_ok(t2 == "No enemy to lock on to in front of you.", "anglais : « %s »" % t2)
	var debout: bool = await _debout("après le ciblage")
	_ok(debout, "le héros tient debout")
	_ranger()

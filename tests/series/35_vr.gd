## V199 : la VR, sans casque (les tests tournent sans OpenXR : on monte les pièces à la main).
##   - les mains : une paume, quatre doigts de trois phalanges, un pouce ; la gâchette et la poignée
##     ferment les doigts autour du manche (vers la paume : -X pour la main droite, +X pour la gauche) ;
##     une arme en main : le poing reste fermé ;
##   - le menu VR est posé dans le monde, devant la tête (il ne la suit plus) ; un rayon part de la
##     manette (pose « aim ») : la ligne visée devient le choix en cours ; si on perd le panneau de vue,
##     il revient devant soi ;
##   - la vue de dehors : une seconde origine XR, derrière la tête (2,6 m) et au-dessus (75 cm) ; contre un
##     mur, elle se rapproche ; le héros est dessiné là où est le joueur, tourné vers où il marche ; on
##     revient dans la peau quand un menu est ouvert.
const NOM := "35_vr"


func _bout(art: Array) -> Vector3:
	var j: Node3D = art[2]
	return j.to_global(Vector3(0, -0.02, 0))


func _serie() -> void:
	# ------------------------------------------------------------------ les mains
	var o := XROrigin3D.new()
	o.name = "Origine_essai_v199"
	add_child(o)
	o.global_position = Vector3(5000, 200, 5000)
	var cd := XRController3D.new()
	o.add_child(cd)
	var cg := XRController3D.new()
	cg.position = Vector3(-0.3, 0, 0)
	o.add_child(cg)
	var md: Node3D = load("res://scripts/vr_mains_v199.gd").new()
	md.setup(cd, false)
	var mg: Node3D = load("res://scripts/vr_mains_v199.gd").new()
	mg.setup(cg, true)
	await _images(3)
	var dd: Dictionary = md._doigts
	_ok(dd.size() == 4 and (dd["index"] as Array).size() == 3 and md._pouce.size() == 3, "la main : quatre doigts de trois phalanges et un pouce")
	var meshes: int = md.find_children("*", "MeshInstance3D", true, false).size()
	_ok(meshes >= 20, "la main est dessinée (%d morceaux)" % meshes)
	var ouvert_d: Vector3 = cd.to_local(_bout(dd["index"]))
	var ouvert_g: Vector3 = cg.to_local(_bout(mg._doigts["index"]))
	md.essai_ferme = 1.0
	mg.essai_ferme = 1.0
	await _images(30)
	var ferme_d: Vector3 = cd.to_local(_bout(dd["index"]))
	var ferme_g: Vector3 = cg.to_local(_bout(mg._doigts["index"]))
	# fermé, le bout de l'index revient près de la paume (il fait le tour du manche, côté paume : -X à droite)
	var paume_d := Vector3(0.032, -0.002, 0.0)
	var paume_g := Vector3(-0.032, -0.002, 0.0)
	_ok(ferme_d.distance_to(paume_d) < ouvert_d.distance_to(paume_d) - 0.02 and ferme_d.x < 0.0, "main droite : l'index se ferme autour du manche, vers la paume (%.3f m -> %.3f m de la paume)" % [ouvert_d.distance_to(paume_d), ferme_d.distance_to(paume_d)])
	_ok(ferme_g.distance_to(paume_g) < ouvert_g.distance_to(paume_g) - 0.02 and ferme_g.x > 0.0, "main gauche : de même, de l'autre côté (%.3f m -> %.3f m)" % [ouvert_g.distance_to(paume_g), ferme_g.distance_to(paume_g)])
	md.essai_ferme = -1.0
	md.tient = true
	await _images(30)
	var tenu: Vector3 = cd.to_local(_bout(dd["majeur"]))
	_ok(tenu.x < 0.0, "une arme en main : le poing reste fermé (x %.3f)" % tenu.x)
	o.queue_free()
	# ------------------------------------------------------------------ le menu VR et son rayon
	var o2 := XROrigin3D.new()
	add_child(o2)
	o2.global_position = Vector3(5000, 200, 5000)
	var tete := XRCamera3D.new()
	o2.add_child(tete)
	tete.position = Vector3(0, 1.65, 0)
	var droite := XRController3D.new()
	o2.add_child(droite)
	var visee := XRController3D.new()
	o2.add_child(visee)
	var m: Node = load("res://scripts/menu_v8.gd").new()
	add_child(m)
	m.visee = visee
	m.setup(true, tete, droite)
	m.open_menu()
	await _images(3)
	var p: Node3D = m.vr_panel
	var devant: Vector3 = p.global_position - tete.global_position
	_ok(p.get_parent() == o2 and absf(Vector2(devant.x, devant.z).length() - 1.8) < 0.1 and devant.z < 0.0, "le menu est posé dans le monde, devant la tête (à %.2f m)" % Vector2(devant.x, devant.z).length())
	_ok(m.options.size() >= 4 and (m.vr_rangees[0] as Label3D).visible and (m.vr_rangees[0] as Label3D).text != "", "une ligne par choix (%d choix)" % m.options.size())
	# on vise la troisième ligne
	var cible: Vector3 = p.to_global(Vector3(0.1, m.RANGEE_HAUT - m.RANGEE_H * 2, 0))
	visee.global_position = tete.global_position + Vector3(0.2, -0.3, -0.2)
	visee.look_at(cible, Vector3.UP)
	await _images(3)
	_ok(m.selection == 2, "la ligne visée par le rayon devient le choix en cours (%d)" % m.selection)
	_ok(m.vr_rayon.visible and m.vr_point.visible, "le rayon et son point sont visibles")
	_ok(absf(m.vr_surbrillance.position.y - (m.RANGEE_HAUT - m.RANGEE_H * 2)) < 0.001, "la barre dorée est derrière la ligne visée")
	# on tourne la tête : au bout d'un moment, le panneau revient devant
	tete.rotation_degrees = Vector3(0, 120, 0)
	await _att(1.6)
	var devant2: Vector3 = p.global_position - tete.global_position
	var regard: Vector3 = -tete.global_basis.z
	_ok(Vector2(devant2.x, devant2.z).normalized().dot(Vector2(regard.x, regard.z).normalized()) > 0.9, "on tourne la tête : le panneau revient devant soi")
	m._close()
	await _images(2)
	_ok(not m.vr_rayon.visible and not p.visible, "menu fermé : plus de rayon ni de panneau")
	m.queue_free()
	o2.queue_free()
	# ------------------------------------------------------------------ la vue de dehors
	var v: Node = load("res://scripts/vr_vue_v199.gd").new()
	v.setup(self)
	await _images(2)
	_ok(v.origine2 != null and v.tete2 != null and v.origine2.get_parent() == self, "la seconde origine XR (la vue de dehors) existe")
	# à découvert, au-dessus de la mer
	var lieu := Vector3(60.0, 0.0, 140.0)
	vr_body.global_position = Vector3(lieu.x, 80.0, lieu.z)
	xr_origin.global_position = Vector3(lieu.x, 80.0, lieu.z)
	xr_origin.global_basis = Basis()
	xr_camera.position = Vector3(0, 1.6, 0)
	v._recul = v.RECUL
	v._suivre(0.016)
	var ecart: Vector3 = v.origine2.global_position - xr_origin.global_position
	_ok(absf(ecart.z - v.RECUL) < 0.05 and absf(ecart.y - v.HAUT) < 0.05, "la vue de dehors : derrière (%.2f m) et au-dessus (%.2f m)" % [ecart.z, ecart.y])
	# un mur juste derrière : la vue se rapproche
	var mur := StaticBody3D.new()
	var forme := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(6, 6, 0.3)
	forme.shape = bx
	mur.add_child(forme)
	mur.collision_layer = 1
	add_child(mur)
	mur.global_position = Vector3(lieu.x, 81.6, lieu.z + 1.2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	v._suivre(0.016)
	var ecart2: Vector3 = v.origine2.global_position - xr_origin.global_position
	_ok(ecart2.z < 1.1 and ecart2.z > 0.1, "contre un mur : la vue se rapproche du héros (%.2f m)" % ecart2.z)
	mur.queue_free()
	# le héros, là où est le joueur, tourné vers où il marche
	vr_body.velocity = Vector3(1.5, 0, 0)
	for i in range(30):
		v._heros(0.016)
	var h: Node3D = pc_hero
	_ok(h.visible and Vector2(h.global_position.x - vr_body.global_position.x, h.global_position.z - vr_body.global_position.z).length() < 0.01, "le héros est dessiné là où est le joueur")
	var face: Vector3 = h.global_basis.z
	_ok(face.x > 0.8, "il est tourné vers où il marche (%.2f)" % face.x)
	vr_body.velocity = Vector3.ZERO
	h.visible = false
	# de dehors, les mains VR se cachent (on voit celles du héros) ; elles reviennent dans la peau
	v._montrer_mains(false)
	var mv: Node3D = right_hand.get_node_or_null("Manette_visible")
	_ok(mv != null and not mv.visible, "de dehors : les mains VR ne flottent plus sur la tête du héros")
	v._montrer_mains(true)
	_ok(mv.visible, "dans la peau : les mains reviennent")
	# la rotation au joystick : continue par défaut, par crans au choix (gardé dans les réglages)
	var r0: String = v.libelle_rotation()
	v.basculer_rotation()
	var r1: String = v.libelle_rotation()
	v.basculer_rotation()
	_ok(r0 == "Rotation VR : continue" and r1 == "Rotation VR : par crans" and not v.crans, "la rotation : continue, ou par crans au choix (%s / %s)" % [r0, r1])
	v.queue_free()
	v.origine2.queue_free()
	# ------------------------------------------------------------------ les conversations : le rayon aussi
	var dl: Node = load("res://scripts/pnj/dialogue_v31.gd").new()
	add_child(dl)
	dl.setup(true)
	var visee_avant: Variant = visee_droite_v199
	var vis := XRController3D.new()
	xr_origin.add_child(vis)
	visee_droite_v199 = vis
	xr_origin.global_position = Vector3(5000, 200, 5000)
	xr_origin.global_basis = Basis()
	xr_camera.position = Vector3(0, 1.6, 0)
	xr_camera.rotation = Vector3.ZERO
	var hab := Node3D.new()
	add_child(hab)
	hab.global_position = xr_camera.global_position + Vector3(0, -1.6, -2.2)
	dl.open(hab)
	dl.show_line("Essai", "de bonne humeur", "Bonjour.", [{"id": "a", "label": "Première réponse"}, {"id": "b", "label": "Deuxième réponse"}, {"id": "c", "label": "Troisième réponse, un peu plus longue que les autres pour voir"}])
	await _images(2)
	var pn: Node3D = dl._vr_panel
	_ok(dl._vr_choix.size() >= 3 and (dl._vr_choix[2] as Label3D).visible, "en VR, une ligne par réponse")
	var cib: Vector3 = pn.to_global(Vector3(0.1, (float(dl._vr_y[2][0]) + float(dl._vr_y[2][1])) * 0.5, 0))
	vis.global_position = xr_camera.global_position + Vector3(0.2, -0.3, -0.2)
	vis.look_at(cib, Vector3.UP)
	await _images(3)
	_ok(dl.selection == 2, "le rayon vise une réponse : elle devient le choix (%d)" % dl.selection)
	_ok(dl.vr_rayon.visible and dl.vr_point.visible and dl._vr_barre.visible, "le rayon, son point et la barre dorée sont là")
	var choisi: Array = []
	dl.chosen.connect(func(id): choisi.append(id))
	dl._vr_trigger_ready = true
	dl.vr_tick(0.0, 1.0, false)
	_ok(choisi == ["c"], "la gâchette répond (%s)" % str(choisi))
	# sans habitant en face (le mode testeur) : le panneau se pose devant soi
	hab.global_position = xr_camera.global_position + Vector3(0, -1.4, 0)
	dl.show_line("Mode testeur", "malin", "Que veux-tu faire ?", [{"id": "x", "label": "Voyager"}, {"id": "y", "label": "(Fermer)"}])
	await _images(2)
	var dv: Vector3 = pn.global_position - xr_camera.global_position
	_ok(dv.z < -1.0 and absf(dv.x) < 0.2, "le mode testeur s'ouvre devant soi (%.2f m)" % -dv.z)
	dl.close()
	await _images(1)
	_ok(not dl.vr_rayon.visible, "conversation finie : plus de rayon")
	visee_droite_v199 = visee_avant
	vis.queue_free()
	hab.queue_free()
	dl.queue_free()
	# ------------------------------------------------------------------ courir (clic du joystick gauche)
	_ok(is_equal_approx(_vitesse_xr_v199(0.016), WALK_SPEED), "en VR, on marche au départ")
	course_v199 = true
	hero_v28.stamina_lock = false
	hero_v28.stamina = hero_v28.STAMINA_MAX
	var vc: float = _vitesse_xr_v199(0.016)
	_ok(vc > WALK_SPEED * 1.4 and course_v199, "un clic : on court (%.1f m/s au lieu de %.1f)" % [vc, WALK_SPEED])
	hero_v28.stamina_lock = true
	var vl: float = _vitesse_xr_v199(0.016)
	_ok(is_equal_approx(vl, WALK_SPEED) and not course_v199, "à bout de souffle : on remarche")
	hero_v28.stamina_lock = false
	hero_v28.stamina = hero_v28.STAMINA_MAX
	# ------------------------------------------------------------------ la fluidité
	var fl: Node = load("res://scripts/vr_fluidite_v199.gd").new()
	fl.setup(self)
	await _images(2)
	fl.fluide = true
	fl.appliquer()
	var maison: MeshInstance3D = null
	for mi in find_child("Maison_village", true, false).find_children("*", "MeshInstance3D", true, false):
		maison = mi
	_ok(fl.lourds.size() >= 5 and fl.lourds.has(maison), "les modèles lourds sont trouvés (%d), la maison du village en est" % fl.lourds.size())
	_ok(is_equal_approx(maison.lod_bias, fl.BIAIS_LOURD) and is_equal_approx(get_viewport().mesh_lod_threshold, fl.SEUIL_FLUIDE), "fluidité optimisée : les versions allégées arrivent plus tôt")
	var tri_casque: int = fl._triangles(maison.mesh)
	_ok(fl.casques.size() == 7 and fl.casques.has(maison) and maison.mesh == fl.casques[maison] and tri_casque < 300000, "les sept modèles lourds ont leur version casque (%d), la maison : %d k triangles au lieu de 1923 k" % [fl.casques.size(), tri_casque / 1000])
	_ok(maison.mesh.surface_get_material(0) == (fl.entiers[maison] as Mesh).surface_get_material(0) and maison.mesh.get_aabb().size.distance_to((fl.entiers[maison] as Mesh).get_aabb().size) < 0.02, "la version casque garde la matière et la taille de l'original")
	var basse: GeometryInstance3D = fl.basses[0] if not fl.basses.is_empty() else null
	_ok(basse != null and basse.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "l'herbe rase ne fait plus d'ombre (%d nappes)" % fl.basses.size())
	var grand := 0
	for mm in find_children("*", "MultiMeshInstance3D", true, false):
		var g: MultiMeshInstance3D = mm
		if g.multimesh != null and g.multimesh.mesh != null and g.multimesh.mesh.get_aabb().size.y > 2.0 and g.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
			grand += 1
	_ok(grand > 20, "les arbres et les grandes plantes gardent leur ombre (%d nappes)" % grand)
	fl.fluide = false
	fl.appliquer()
	_ok(is_equal_approx(maison.lod_bias, 1.0) and is_equal_approx(get_viewport().mesh_lod_threshold, fl.SEUIL_MAX) and basse.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and maison.mesh == fl.entiers[maison], "détail maximum : tout revient comme avant")
	_ok(fl.libelle() == "Fluidité VR : détail maximum", "le réglage se lit dans les Paramètres (%s)" % fl.libelle())
	fl.queue_free()
	# ------------------------------------------------------------------ V205 : debout ou assis
	var po205: Node = load("res://scripts/vr_posture_v205.gd").new()
	po205.setup(self)
	po205.assis = false
	po205.appliquer()
	_ok(socle_v205 != null and xr_origin.get_parent() == socle_v205 and is_zero_approx(socle_v205.position.y), "le joueur VR est sur son socle, au sol quand on joue debout")
	xr_origin.position = Vector3(2, 5, 8)
	var tete205: float = xr_camera.global_position.y
	var main205: float = right_hand.global_position.y
	_ok(is_equal_approx(po205.mesurer(1.2), 0.45) and is_zero_approx(po205.mesurer(1.75)) and is_equal_approx(po205.mesurer(0.5), po205.REHAUSSE_MAX) and is_equal_approx(po205.mesurer(0.0), po205.REHAUSSE_DEFAUT), "la rehausse se mesure au casque : 45 cm pour des yeux à 1,20 m, rien pour quelqu'un debout")
	po205.assis = true
	po205.rehausse = po205.mesurer(1.2)
	po205.appliquer()
	_ok(is_equal_approx(xr_camera.global_position.y - tete205, 0.45) and is_equal_approx(right_hand.global_position.y - main205, 0.45), "assis : la tête et les mains montent de 45 cm")
	_ok(is_equal_approx(xr_origin.position.y, 5.0) and po205.libelle().begins_with("Posture VR : assis"), "… et le jeu règle toujours les pieds au même endroit")
	po205.assis = false
	po205.appliquer()
	_ok(is_equal_approx(xr_camera.global_position.y, tete205) and po205.libelle() == "Posture VR : debout", "debout : tout revient comme avant")
	po205.queue_free()

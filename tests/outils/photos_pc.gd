## V182 : les photos de contrôle sur le PC de l'auteur. Le vrai jeu, avec une vraie carte graphique : le
## serveur des tests n'en a pas, et le jeu entier n'y tient pas en mémoire avec un écran. Collé à la fin de
## main.gd, après _commun.gd, comme une série (tests/outils/photos_pc.py fabrique ce main.gd et la liste
## des photos) ; sur le PC, 3_photos.bat lance le jeu, qui passe aux endroits de la liste et range les
## photos (jpg) dans le dossier « photos », à côté du dossier du jeu.
## La liste (photos_liste.json, à côté du dossier du jeu) : chaque entrée est un dictionnaire.
##   "nom" : le début du nom des photos ;
##   "pnj" : le nom d'un habitant (on va le voir là où il est, à l'heure de la liste) ; sans "pnj", une vue
##           libre : "oeil" et "cible" ([x, y, z]) ;
##   "lieu" : on l'envoie à ce lieu, comme s'il y arrivait (assis : sur son siège) ;
##   "pos", "face" ([x, y, z]) : V184, on le pose là, tourné par là (en chemin : "geste": ["Walking", t]) ;
##   "geste" : ["clip", instant] : il joue ce clip, figé à cet instant ;
##   "vues" : parmi "face" (de trois quarts), "profil", "dos", "dessus", "pieds" (au ras du sol, de côté) ;
##   "dist", "haut", "cible_h" : la caméra (m, à l'échelle de l'habitant) ; "heure" : l'heure du jeu.
const NOM := "photos_pc"
const PP_ASSIS := ["assis", "allonge", "guitare", "lire"]
var _pp_cam: Camera3D
var _pp_dossier: String = ""


func _serie() -> void:
	var base: String = ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	_pp_dossier = base.path_join("photos")
	DirAccess.make_dir_recursive_absolute(_pp_dossier)
	var f := FileAccess.open(base.path_join("photos_liste.json"), FileAccess.READ)
	if f == null:
		print("PHOTOS pas de liste dans ", base)
		return
	var liste: Variant = JSON.parse_string(f.get_as_text())
	# la liste, ou {"dossier": "…", "photos": [la liste]} : les photos rangées dans photos/<dossier>
	if liste is Dictionary:
		if (liste as Dictionary).has("dossier"):
			_pp_dossier = _pp_dossier.path_join(str(liste["dossier"]))
			DirAccess.make_dir_recursive_absolute(_pp_dossier)
		if (liste as Dictionary).get("corps", false):
			_pp_corps()
		liste = (liste as Dictionary).get("photos", [])
	if not (liste is Array):
		print("PHOTOS liste illisible")
		return
	temps_v56.frozen = true
	# (V183 : pas l'heure pile, où les habitants changent de lieu)
	temps_v56.set_hour(14.3)
	_pp_cam = Camera3D.new()
	_pp_cam.name = "Camera_photos"
	add_child(_pp_cam)
	if pc_camera != null:
		_pp_cam.cull_mask = pc_camera.cull_mask
		_pp_cam.attributes = pc_camera.attributes
		_pp_cam.environment = pc_camera.environment
	_pp_cam.fov = 50.0
	_pp_cam.near = 0.05
	_pp_cam.far = 4000.0
	await _att(2.0)
	var n: int = 0
	for p in liste:
		if p is Dictionary:
			n += await _pp_une(p)
	print("PHOTOS_FINIES %d photos dans %s" % [n, _pp_dossier])


func _pp_une(p: Dictionary) -> int:
	var nom: String = str(p.get("nom", "photo"))
	print("PHOTO_DEBUT ", nom)
	if p.has("heure"):
		temps_v56.set_hour(float(p["heure"]))
	if not p.has("pnj"):
		if not (p.has("oeil") and p.has("cible")):
			return 0
		var oeil: Vector3 = _pp_v(p["oeil"])
		var cible: Vector3 = _pp_v(p["cible"])
		_pp_joueur(oeil - (cible - oeil).normalized() * 2.0, cible - oeil)
		await _att(float(p.get("attente", 4.0)))
		return 1 if await _pp_photo(nom, oeil, cible) else 0
	var npc: Node3D = null
	for e in testeur_v78._npcs():
		if str(e[0]) == str(p["pnj"]):
			npc = e[1]
			break
	if npc == null:
		print("PHOTO %s : pas d'habitant « %s »" % [nom, p["pnj"]])
		return 0
	# « lieu_pose » : le premier lieu de son emploi du temps où il prend cette pose
	if p.has("lieu_pose") and npc.get("azur") != null and npc.get("agenda") is Array:
		for e in npc.get("agenda"):
			var nl: String = str(e[2]) if (e is Array and (e as Array).size() > 2) else ""
			if nl != "" and nl != "maison" and not nl.begins_with("course:"):
				var spp: Dictionary = (npc.get("azur") as Object).call("spot", nl)
				if not spp.is_empty() and str(spp.get("pose", "")) == str(p["lieu_pose"]):
					p["lieu"] = nl
					break
		if not p.has("lieu"):
			print("PHOTO %s : %s n'a pas de lieu « %s »" % [nom, p["pnj"], p["lieu_pose"]])
	# V184 : « pos » ([x, y, z]) et « face » ([x, y, z]) : on le pose là, tourné par là (en marche sur un
	# chemin : avec "geste": ["Walking", instant])
	if p.has("pos"):
		_pp_poser(npc, p)
	elif p.has("lieu"):
		npc.set("slot", npc.call("_slot_now"))
		npc.call("_set_hidden", false)
		npc.set("state", "repos")
		npc.set("target_spot", str(p["lieu"]))
		var az: Object = npc.get("azur")
		if az != null:
			var sp: Dictionary = az.call("spot", str(p["lieu"]))
			if not sp.is_empty():
				npc.global_position = sp["pos"]
		npc.call("_arrive")
		if not (str(npc.get("pose")) in PP_ASSIS) and npc.has_method("_snap_to_floor"):
			npc.call("_snap_to_floor")
	# on s'approche (son corps se construit quand on vient, la ville aussi) ; s'il est parti ailleurs
	# entre-temps (son emploi du temps), on le suit
	for essai in range(3):
		var ici: Vector3 = npc.global_position
		_pp_joueur(ici + _pp_avant(npc) * 3.5, -_pp_avant(npc))
		await _att(float(p.get("attente", 3.5)))
		if npc.global_position.distance_to(ici) < 3.0:
			break
	# (V183 : son corps peut être caché un instant, quand il change de lieu à l'heure pile : on l'attend)
	var corps0: Node3D = npc.get("model") if npc.get("model") is Node3D else npc
	for _i in range(12):
		if npc.is_visible_in_tree() and corps0.is_visible_in_tree():
			break
		await _att(0.5)
	if not (npc.is_visible_in_tree() and corps0.is_visible_in_tree()):
		print("PHOTO %s : %s est caché (chez lui, ou en chemin ?)" % [nom, p["pnj"]])
		return 0
	if p.has("pos"):
		# (il a pu repartir pendant qu'on approchait : on le repose)
		_pp_poser(npc, p)
	var an0: AnimationPlayer = npc.get("anim")
	print("PHOTO_PNJ %s %s %s %s" % [nom, str(npc.global_position), str(npc.get("pose")), an0.current_animation if an0 != null else "?"])
	# on le fige (le même geste pour chaque vue)
	var anim: AnimationPlayer = npc.get("anim")
	var geste: Array = p.get("geste", [])
	npc.set_process(false)
	npc.set_physics_process(false)
	if anim != null:
		if not geste.is_empty() and anim.has_animation(str(geste[0])):
			anim.play(str(geste[0]), 0.0)
			anim.seek(float(geste[1]), true)
		anim.pause()
	var ech: float = 1.0
	if npc.get("model") is Node3D:
		ech = (npc.get("model") as Node3D).global_transform.basis.get_scale().x
	var pos: Vector3 = npc.global_position
	var av: Vector3 = _pp_avant(npc)
	var cote: Vector3 = Vector3.UP.cross(av).normalized()
	var dist: float = float(p.get("dist", 2.8)) * ech
	var haut: float = float(p.get("haut", 1.1)) * ech
	var cible: Vector3 = pos + Vector3.UP * float(p.get("cible_h", 0.85)) * ech
	var n: int = 0
	for v in p.get("vues", ["face", "pieds"]):
		var oeil: Vector3
		var vise: Vector3 = cible
		match str(v):
			"profil":
				oeil = pos + cote * dist + Vector3.UP * haut
			"dos":
				oeil = pos + (-av * 0.8 + cote * 0.6).normalized() * dist + Vector3.UP * haut
			"dessus":
				oeil = pos + av * 0.9 * ech + Vector3.UP * 3.2 * ech
				vise = pos + Vector3.UP * 0.3 * ech
			"pieds":
				oeil = pos + (cote * 0.9 + av * 0.45).normalized() * 1.7 * ech + Vector3.UP * 0.22 * ech
				vise = pos + Vector3.UP * 0.25 * ech
			_:
				oeil = pos + (av * 0.8 + cote * 0.6).normalized() * dist + Vector3.UP * haut
		if await _pp_photo("%s_%s" % [nom, str(v)], oeil, vise):
			n += 1
	if anim != null:
		anim.play()
	npc.set_process(true)
	npc.set_physics_process(true)
	return n


## Les habitants qui ont encore l'ancien corps (celui du héros, en dessin animé) : pas de corps à eux
## (pnj64/<id>.bin). Une ligne « CORPS_ANCIEN » chacun.
func _pp_corps() -> void:
	var n: int = 0
	for e in testeur_v78._npcs():
		var npc: Node3D = e[1]
		var v64: Variant = npc.get("v64")
		if v64 is Dictionary and (v64 as Dictionary).is_empty():
			var prof: Variant = npc.get("profile")
			var id: String = str((prof as Dictionary).get("id", "?")) if prof is Dictionary else "?"
			var ville: String = ""
			if npc.get("azur") != null and (npc.get("azur") as Object).get_script() != null:
				ville = ((npc.get("azur") as Object).get_script() as Script).resource_path.get_file()
			print("CORPS_ANCIEN\t%s\t%s\t%s\t%s" % [str(e[0]), id, ville, str(npc.global_position.snapped(Vector3.ONE))])
			n += 1
	print("CORPS_ANCIEN_TOTAL %d sur %d" % [n, testeur_v78._npcs().size()])


func _pp_poser(npc: Node3D, p: Dictionary) -> void:
	npc.set("state", "repos")
	npc.set("route", [])
	npc.set("_flane", [])
	if npc.has_method("_set_hidden"):
		npc.call("_set_hidden", false)
	npc.global_position = _pp_v(p["pos"])
	if npc.has_method("_snap_to_floor"):
		npc.call("_snap_to_floor")
	var f: Vector3 = _pp_v(p.get("face", [0, 0, 1]))
	f.y = 0.0
	if f.length() > 0.01:
		npc.rotation.y = atan2(f.x, f.z)


func _pp_v(a: Variant) -> Vector3:
	var t: Array = a
	return Vector3(float(t[0]), float(t[1]), float(t[2]))


func _pp_avant(npc: Node3D) -> Vector3:
	var fw: Vector3 = npc.global_transform.basis.z
	fw.y = 0.0
	return fw.normalized() if fw.length() > 0.01 else Vector3.FORWARD


## Le joueur tout près (les villes, les habitants se construisent quand il approche), le héros caché.
func _pp_joueur(at: Vector3, face: Vector3) -> void:
	place_player_v35(at + Vector3.UP * 0.3, face)
	if pc_hero != null:
		pc_hero.visible = false


func _pp_photo(nom: String, oeil: Vector3, cible: Vector3) -> bool:
	_pp_cam.global_position = oeil
	var d: Vector3 = cible - oeil
	if d.length() > 0.01:
		_pp_cam.look_at(cible, Vector3.UP if absf(d.normalized().y) < 0.98 else Vector3.FORWARD)
	_pp_cam.current = true
	if pc_hero != null:
		pc_hero.visible = false
	# l'écran du jeu (messages, boussole, barres) caché le temps de la photo
	var caches: Array = []
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if (cl as CanvasLayer).visible:
			(cl as CanvasLayer).visible = false
			caches.append(cl)
	await _images(5)
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		img = get_viewport().get_texture().get_image()
	for cl in caches:
		if is_instance_valid(cl):
			(cl as CanvasLayer).visible = true
	if img == null or img.is_empty():
		print("PHOTO %s : pas d'image (sans écran ?) oeil %s cible %s" % [nom, str(oeil), str(cible)])
		return false
	var err: int = img.save_jpg(_pp_dossier.path_join(nom + ".jpg"), 0.88)
	print("PHOTO %s %s" % [nom, "ok" if err == OK else "erreur %d" % err])
	return err == OK

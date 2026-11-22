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
##   "tour" : [n° de tour, étage] : V185, les portraits des gens d'un étage d'une tour de Néopolis ;
##   "neo": true : V187, "oeil" et "cible" sont [x, hauteur au-dessus du sol, z] dans le repère de Néopolis ;
##   "salles": true : V187, l'intérieur des tours de Néopolis : un étage de chaque sorte, huit vues larges
##             ("tour_seule": n° : tous les étages de cette tour) ;
##   "foule" : un style de la réserve des figurants ("neo", "boucan"…) : V186, les corps n° "de" à "de" +
##             "combien" (8) de ce style, debout en rang sur un plateau nu (300 m au-dessus du joueur), en pied sur une seule photo
##             (ou "ids" : la liste des fiches à aligner) ;
##   "pos", "face" ([x, y, z]) : V184, on le pose là, tourné par là (en chemin : "geste": ["Walking", t]) ;
##   "geste" : ["clip", instant] : il joue ce clip, figé à cet instant ;
##   "vues" : parmi "face" (de trois quarts), "profil", "dos", "dessus", "pieds" (au ras du sol, de côté) ;
##   "dist", "haut", "cible_h" : la caméra (m, à l'échelle de l'habitant) ; "heure" : l'heure du jeu.
## V193 : "public" : "averti" ou "tout" (la version du jeu, pour cette photo et les suivantes) ; "repere" :
## "halle" ou "conserverie" : "oeil" et "cible" dans le repère de ce lieu de Port-Boucan (boucan_nuit_v193) ;
## "ombrelac" : le nom d'un lieu du château d'Ombrelac : "oeil" et "cible" en décalage de ce lieu ;
## "action" : "trip" (on croque un Rieur : l'écran du trip reste sur la photo), "douche" (Rouille arrose la
## fosse juste avant la photo).
## V192 : la fluidité. Avant chaque photo, on mesure le jeu pendant "mesure" secondes (2 par défaut, en tête
## de liste ; 0 : pas de mesure), sans synchro verticale : le temps de chaque image (médiane et pire 5 %),
## le temps de la carte graphique et du processeur pour le rendu, les appels de dessin, les triangles, la
## mémoire vidéo, le temps des scripts et de la physique. Une ligne MESURE dans le journal, et mesures.csv dans le dossier des photos.
const NOM := "photos_pc"
const PP_ASSIS := ["assis", "allonge", "guitare", "lire"]
var _pp_cam: Camera3D
var _pp_dossier: String = ""
var _pp_mesure: float = 2.0
var _pp_csv: String = ""


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
		_pp_mesure = float((liste as Dictionary).get("mesure", 2.0))
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
	if _pp_mesure > 0.0:
		_pp_mesure_debut()
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
	if p.has("public"):
		load("res://scripts/public_v111.gd").choisir(str(p["public"]), false)
	if p.has("tour"):
		return await _pp_tour(p)
	if p.has("salles"):
		return await _pp_salles(p)
	if p.has("foule"):
		return await _pp_foule(p)
	if not p.has("pnj"):
		if not (p.has("oeil") and p.has("cible")):
			return 0
		var oeil: Vector3 = _pp_v(p["oeil"])
		var cible: Vector3 = _pp_v(p["cible"])
		if bool(p.get("neo", false)) and neo_v94 != null:
			# V187 : à Néopolis : [x, hauteur au-dessus du sol, z] dans le repère de la ville
			var so: Vector3 = neo_v94._ground(oeil.x, oeil.z)
			var sc: Vector3 = neo_v94._ground(cible.x, cible.z)
			oeil = Vector3(so.x, so.y + oeil.y, so.z)
			cible = Vector3(sc.x, sc.y + cible.y, sc.z)
		var nuit: Node = boucan_v75.get("nuit") if boucan_v75 != null else null
		# V193 : "ombrelac" : un lieu du château d'Ombrelac (chateau.lieux) ; "oeil" et "cible" en décalage de ce lieu
		if p.has("ombrelac") and ombrelac_ext != null and ombrelac_ext.chateau != null:
			var base_o: Vector3 = ombrelac_ext.chateau.position + (ombrelac_ext.chateau.lieux.get(str(p["ombrelac"]), Vector3.ZERO) as Vector3)
			oeil += base_o
			cible += base_o
		if p.has("repere") and nuit != null:
			var xf: Transform3D = nuit.halle_xf if str(p["repere"]) == "halle" else nuit.conserverie_xf
			oeil = xf * oeil
			cible = xf * cible
		_pp_joueur(oeil - (cible - oeil).normalized() * 2.0, cible - oeil)
		await _att(float(p.get("attente", 4.0)))
		if str(p.get("action", "")) == "trip" and nuit != null:
			inventory_v28.add("champi_rieur", 1)
			boucan_v75.champis.eat("champi_rieur")
			await _att(14.0)
		elif str(p.get("action", "")) == "douche" and nuit != null:
			nuit.douche()
			await _att(0.7)
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


## V185 : « tour » : [n° de la tour de Néopolis, étage] : on y monte par l'ascenseur, et l'on tire le
## portrait de chaque personne de l'étage (au plus « combien », 12 par défaut).
func _pp_tour(p: Dictionary) -> int:
	var nom: String = str(p.get("nom", "tour"))
	var T: Node = neo_v94.tours if neo_v94 != null else null
	if T == null:
		return 0
	var ti: int = int(p["tour"][0])
	var k: int = int(p["tour"][1])
	for _w in range(40):
		if not bool(T.get("busy")) and int(T.get("inside")) < 0:
			break
		await _att(0.25)
	await T.enter(ti)
	await _att(0.8)
	if k > 0:
		await T.aller(k)
	await _att(1.5)
	var n: int = 0
	var i: int = 0
	for f in T.get("_gens"):
		if i >= int(p.get("combien", 12)):
			break
		if not is_instance_valid(f) or (f as Node).get("npc") == null:
			continue
		var npc: Node3D = (f as Node).get("npc")
		var ech: float = 1.0
		if npc.get("model") is Node3D:
			ech = (npc.get("model") as Node3D).global_transform.basis.get_scale().x
		var tete: Vector3 = npc.global_position + Vector3.UP * 1.5 * ech
		var sk: Skeleton3D = npc.get("skel")
		if sk != null and sk.find_bone("Head") >= 0:
			tete = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
		var av: Vector3 = _pp_avant(npc)
		var pr: Variant = npc.get("profile")
		var id: String = str((pr as Dictionary).get("id", "?")) if pr is Dictionary else "?"
		print("PHOTO_TOUR %s %d %s" % [nom, i, id])
		if await _pp_photo("%s_%02d_%s" % [nom, i, id], tete + av * 1.25 + Vector3.UP * 0.05, tete - Vector3.UP * 0.12):
			n += 1
		i += 1
	await T.leave()
	await _att(0.6)
	return n


## V187 : « salles » : l'état des lieux des tours de Néopolis. On passe les tours en revue, et pour chaque
## sorte d'étage pas encore vue (hall, bureaux, cafétéria, logements…), on y monte et l'on prend huit vues
## larges : quatre de la sortie de l'ascenseur, quatre de six mètres plus loin dans la salle.
func _pp_salles(p: Dictionary) -> int:
	var nom: String = str(p.get("nom", "salle"))
	var T: Node = neo_v94.tours if neo_v94 != null else null
	if T == null:
		return 0
	var vus: Dictionary = {}
	var n: int = 0
	var max_par: int = int(p.get("par_sorte", 1))
	# (« tour_seule » : tous les étages de cette tour-là, et d'elle seule ; « vues » : par étage ("7": […]), des
	# vues choisies [x, h, z de l'œil, x, h, z de la cible], en mètres depuis le coin nord-ouest de l'étage)
	var seule: int = int(p.get("tour_seule", -1))
	var vues: Dictionary = p.get("vues", {})
	for ti in range((T.get("tours") as Array).size()):
		if seule >= 0 and ti != seule:
			continue
		var t: Dictionary = (T.get("tours") as Array)[ti]
		var ne: int = (t["etages"] as Array).size()
		var ici: Array = []
		for k in range(ne):
			var ty: String = str(T.type_etage(ti, k))
			if seule >= 0:
				if vues.is_empty() or vues.has(str(k)):
					ici.append("%02d_%s" % [k, ty])
					ici.append(k)
			elif int(vus.get(ty, 0)) < max_par and not (ty in ici):
				ici.append(ty)
				vus[ty] = int(vus.get(ty, 0)) + 1
				ici.append(k)
		if ici.is_empty():
			continue
		for _w in range(40):
			if not bool(T.get("busy")) and int(T.get("inside")) < 0:
				break
			await _att(0.25)
		await T.enter(ti)
		await _att(0.8)
		for q in range(0, ici.size(), 2):
			var k2: int = int(ici[q + 1])
			if k2 > 0:
				await T.aller(k2)
			await _att(1.5)
			var inf: Dictionary = T.get("info")
			var base: Vector3 = (inf["ascenseur"] as Vector3) + Vector3.UP * 1.6
			var reg: Vector3 = inf["regard"]
			print("PHOTO_SALLE %s tour %d étage %d %s" % [nom, ti, k2, str(ici[q])])
			var a: int = 0
			if vues.has(str(k2)):
				var rc: Rect2 = inf["rect"]
				var o0 := Vector3(rc.position.x, float(inf["y"]), rc.position.y)
				for v in vues[str(k2)]:
					if await _pp_photo("%s_%s_v%d" % [nom, str(ici[q]), a], o0 + Vector3(float(v[0]), float(v[1]), float(v[2])), o0 + Vector3(float(v[3]), float(v[4]), float(v[5]))):
						n += 1
					a += 1
				continue
			for depart in [base, base + reg * 6.0]:
				for dir in [reg, -reg, reg.cross(Vector3.UP), -reg.cross(Vector3.UP)]:
					if await _pp_photo("%s_%s_t%d_e%d_%d" % [nom, str(ici[q]), ti, k2, a], depart, depart + (dir as Vector3) * 8.0 - Vector3.UP * 0.6):
						n += 1
					a += 1
		await T.leave()
		await _att(0.6)
	return n


## V186 : « foule » : les corps d'un style de la réserve des figurants, en rang, là où est le joueur.
func _pp_foule(p: Dictionary) -> int:
	var Gens: Script = load("res://scripts/pnj/maisons_habitants_v81.gd")
	var Fig: Script = load("res://scripts/pnj/figurant_v81.gd")
	var st: String = str(p["foule"])
	var i0: int = int(p.get("de", 0))
	var nb: int = int(p.get("combien", 8))
	var c0: Vector3 = _player_pos_v27()
	# un plateau nu, 300 m au-dessus du joueur : le rang entier sur un sol plat, sans décor devant ni derrière
	var c: Vector3 = c0 + Vector3.UP * 300.0
	var plateau := StaticBody3D.new()
	plateau.name = "Plateau_photos"
	add_child(plateau)
	plateau.global_position = c - Vector3.UP * 0.1
	var bm := BoxMesh.new()
	bm.size = Vector3(60.0, 0.2, 60.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.56, 0.53, 0.48)
	mat.roughness = 1.0
	bm.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	plateau.add_child(mi)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = bm.size
	cs.shape = bx
	plateau.add_child(cs)
	_pp_joueur(c, Vector3(0, 0, -1))
	await _att(0.4)
	var crees: Array = []
	var ys: float = 0.0
	# (« ids » : la liste des fiches à aligner, au lieu de « de » et « combien »)
	var ids: Array = p.get("ids", [])
	if ids.is_empty():
		for k0 in range(nb):
			ids.append("f81_%s_%d" % [st, i0 + k0])
	nb = ids.size()
	for k in range(nb):
		var prof: Dictionary = Gens.profile(str(ids[k]))
		if prof.is_empty():
			prof = _pp_fiche(str(ids[k]))
		if prof.is_empty():
			continue
		var at := c + Vector3((float(k) - float(nb - 1) * 0.5) * 0.72, 0.0, -4.4)
		var f: Node = Fig.spawn(self, self, prof, at, Vector3(0, 0, 1), "debout")
		crees.append(f.get("npc"))
		ys += at.y
	if crees.is_empty():
		print("PHOTO_FOULE %s : aucun corps (%s, %d)" % [str(p.get("nom", "")), st, i0])
		return 0
	await _att(float(p.get("attente", 2.0)))
	var y0: float = ys / float(crees.size())
	var mil := Vector3(c.x, y0 + 0.95, c.z - 4.4)
	print("PHOTO_FOULE %s %s %d %d" % [str(p.get("nom", "")), st, i0, crees.size()])
	var ok: bool = await _pp_photo(str(p.get("nom", "foule_" + st)), mil + Vector3(0, 0.15, 4.3), mil)
	for n in crees:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_pp_joueur(c0, Vector3(0, 0, -1))
	plateau.queue_free()
	await _att(0.3)
	return 1 if ok else 0


## La fiche d'un habitant nommé (cherchée dans les listes d'habitants des villes).
func _pp_fiche(id: String) -> Dictionary:
	for m in ["azur_habitants_v56", "carene_habitants_v59", "cliquetis_habitants_v61", "tazira_habitants_v60", "ramure_habitants_v62",
			"teufeurs_v57", "arcanelle_habitants_v67", "pirates_habitants_v68", "soleils_habitants_v69", "braise_habitants_v70",
			"montjoie_habitants_v71", "boucan_habitants_v75", "astralys_habitants_v76", "larsen_habitants_v92", "neo_habitants_v95",
			"pasta_habitants_v98", "crayon_habitants_v101", "hautefond_habitants_v112", "nuees_habitants_v113", "strates_habitants_v114",
			"fronde_habitants_v114", "dome_habitants_v115"]:
		var s: Script = load("res://scripts/pnj/%s.gd" % m)
		if s == null:
			continue
		for d in s.all_profiles():
			if d is Dictionary and str((d as Dictionary).get("id", "")) == id:
				var f: Dictionary = (d as Dictionary).duplicate(true)
				if not f.has("classe"):
					f["classe"] = "lumen"
				return f
	return {}


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
		if (cl as CanvasLayer).visible and cl.name != "Trip193":
			(cl as CanvasLayer).visible = false
			caches.append(cl)
	await _images(5)
	if _pp_mesure > 0.0:
		await _pp_mesurer(nom)
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


## V192 : la fluidité, mesurée sur le vrai PC (la synchro verticale coupée : le temps réel de chaque image)
func _pp_mesure_debut() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var taille: Vector2i = get_viewport().get_visible_rect().size
	var carte: String = RenderingServer.get_video_adapter_name()
	print("MESURE_MACHINE carte « %s », pilote %s, image %dx%d" % [carte, RenderingServer.get_video_adapter_api_version(), taille.x, taille.y])
	_pp_csv = _pp_dossier.path_join("mesures.csv")
	var f := FileAccess.open(_pp_csv, FileAccess.WRITE)
	if f != null:
		f.store_line("# %s ; %dx%d ; %s" % [carte, taille.x, taille.y, str(ProjectSettings.get_setting("application/config/name", ""))])
		f.store_line("vue;images;mediane_ms;p95_ms;pire_ms;ips;gpu_ms;cpu_ms;appels;triangles;vram_mo;scripts_ms;physique_ms")
		f.close()


func _pp_mesurer(nom: String) -> void:
	var rid: RID = get_viewport().get_viewport_rid()
	await _images(10)
	var dts: Array = []
	var gpu: Array = []
	var cpu: Array = []
	var scr: Array = []
	var phy: Array = []
	var t0: int = Time.get_ticks_usec()
	var prec: int = t0
	while Time.get_ticks_usec() - t0 < int(_pp_mesure * 1000000.0) and dts.size() < 2000:
		await get_tree().process_frame
		var t: int = Time.get_ticks_usec()
		dts.append(float(t - prec) / 1000.0)
		prec = t
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
		scr.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		phy.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if dts.is_empty():
		return
	dts.sort()
	gpu.sort()
	cpu.sort()
	scr.sort()
	phy.sort()
	var n: int = dts.size()
	var med: float = dts[n / 2]
	var p95: float = dts[mini(n - 1, int(n * 0.95))]
	var pire: float = dts[n - 1]
	var g: float = gpu[n / 2]
	var c: float = cpu[n / 2]
	var sc: float = scr[n / 2]
	var ph: float = phy[n / 2]
	var appels: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var tri: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var vram: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var ips: float = 1000.0 / med if med > 0.0 else 0.0
	print("MESURE %s : %d images, médiane %.2f ms (%.0f i/s), pire 5 %% %.2f ms, pire %.2f ms, carte %.2f ms, processeur %.2f ms, %d appels, %d triangles, %.0f Mo, scripts %.2f ms, physique %.2f ms" % [nom, n, med, ips, p95, pire, g, c, appels, tri, vram, sc, ph])
	var f := FileAccess.open(_pp_csv, FileAccess.READ_WRITE)
	if f != null:
		f.seek_end()
		f.store_line("%s;%d;%.2f;%.2f;%.2f;%.0f;%.2f;%.2f;%d;%d;%.0f;%.2f;%.2f" % [nom, n, med, p95, pire, ips, g, c, appels, tri, vram, sc, ph])
		f.close()

extends SceneTree
## V179 : les poses des habitants en photo (lancé par tests/outils/rendu_poses.sh) : chaque pose, chaque
## sorte de corps, de face, de trois quarts et de profil, sans décor (un sol, une lumière), pour voir les
## bras tordus, les mains dans le ventre, les coudes à l'envers.
##     args : DOSSIER  corps  poses
##     corps : « montjoie:0,pirate:1 » (le style des maisons, le n° du corps : 0 homme, 1 femme, 2 vieux,
##             3 vieille, 4 garçon, 5 fille) ; vide : montjoie:0
##     poses : « bras_croises,colere » ; « @v102/saluer » : une animation jouée telle quelle (« @v102/saluer:0.6 » :
##             arrêtée à 0,6 s) ; vide : toutes

const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const POSES := ["debout", "bras_croises", "colere", "rire", "comptoir", "mains_dos", "applaudir", "pointer",
	"peindre", "bricoler", "cuisiner", "danse", "violon", "cache", "pompes", "mime", "boire", "guitare_bo",
	"basse_bo", "leviter", "mediter", "forger", "jardiner", "enseigner", "observer", "holo", "crier", "moudre",
	"prier", "chanter", "marcher", "assis", "manger", "rire_assis", "tricot", "bain", "lire", "guitare",
	"dormir", "dormir_assis"]


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = true
	var temps_v56: Node
	var inventory_v28: Node = null
	var dialogue_v31: Node = null
	var donjon_v35: Node = null

	func _player_pos_v27() -> Vector3:
		return cam.global_position - Vector3.UP * 1.6 if cam != null else Vector3.ZERO

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func jingle(_n: String) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		print("MESSAGE ", t)

	func ask_v69(_a, _b, _c, _d, _e, _f) -> void:
		pass

	func _close_dialogue_v31() -> void:
		pass


class FakeTemps:
	extends Node
	var hour: float = 15.0
	var day_count: int = 3
	var lamps_on: bool = false

	func register_glow(_m: Variant, _a: Variant = null, _b: Variant = null) -> void:
		pass

	func register_lamp(_l: Variant, _e: Variant = null) -> void:
		pass


var out: String = ""
var cam: Camera3D
var vp: SubViewport
var reperes: Array = []          # les os (petites boules rouges), si RENDU_OS=1


func _reperes(npc: Node) -> void:
	for r in reperes:
		r.queue_free()
	reperes.clear()
	if OS.get_environment("RENDU_OS") != "1":
		return
	var sk: Skeleton3D = npc.get("skel")
	if sk == null:
		return
	for nm in ["LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand", "Head", "Hips", "LeftShoulder", "RightShoulder"]:
		var b: int = sk.find_bone(nm)
		if b < 0:
			continue
		var mi := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.025
		sp.height = 0.05
		mi.mesh = sp
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.no_depth_test = true
		m.albedo_color = Color(1, 0.1, 0.1) if nm.begins_with("Left") else (Color(0.1, 0.3, 1) if nm.begins_with("Right") else Color(1, 1, 0))
		mi.material_override = m
		root.add_child(mi)
		mi.global_position = sk.global_transform * sk.get_bone_global_pose(b).origin
		reperes.append(mi)


func _attendre(n: int) -> void:
	for k in range(n):
		await process_frame


func _photo(nom: String) -> void:
	await _attendre(2)
	var img: Image = vp.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, nom])


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	out = str(a[0])
	var corps: Array = Array((a[1] if a.size() > 1 and a[1] != "" else "montjoie:0").split(","))
	var poses: Array = Array(a[2].split(",")) if a.size() > 2 and a[2] != "" else POSES
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.9)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(500, 40)
	sol.mesh = pm
	sol.position.x = 200.0
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.42, 0.4, 0.37)
	sol.material_override = sm
	root.add_child(sol)
	var fm := FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	# une image de taille fixe (la fenêtre suit les réglages du projet)
	vp = SubViewport.new()
	vp.size = Vector2i(320, 440)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.near = 0.05
	cam.far = 200.0
	vp.add_child(cam)
	cam.current = true
	fm.cam = cam
	await _attendre(3)
	Engine.time_scale = 2.0
	var vues: Array = [["face", 0.0], ["trois_quarts", 50.0], ["profil", 90.0]]
	for c in corps:
		var st: String = str(c).get_slice(":", 0)
		var i: int = int(str(c).get_slice(":", 1)) if str(c).contains(":") else 0
		var p: Dictionary = Gens.profile("f81_%s_%d" % [Gens.style_of(st), i])
		# tous à la fois, en rang (4 m entre deux), le corps construit tout de suite ; puis on les
		# photographie un par un (les autres cachés)
		var gens: Array = []
		for k in poses.size():
			var pose: String = str(poses[k])
			var brut: String = ""
			if pose.begins_with("@"):
				brut = pose.substr(1)
				pose = "debout"
			var x0 := Vector3(k * 4.0, 0, 0)
			var f: Node = Figurant.spawn(fm, fm, p.duplicate(true), x0, Vector3(0, 0, 1), pose)
			f.follow = false
			if f.npc.has_method("body64_build"):
				f.npc.call("body64_build")
			gens.append([f, pose, brut, x0])
		await _attendre(4)
		if OS.get_environment("RENDU_SANS_EPAULES") == "1":
			for g in gens:
				var sk0: Skeleton3D = g[0].npc.get("skel")
				var ep: Node = sk0.get_node_or_null("Epaules64") if sk0 != null else null
				if ep != null:
					ep.set("active", false)
		for g in gens:
			if str(g[2]) != "":
				# « @bibliothèque/clip:instant » : le clip arrêté à cet instant
				var nom: String = str(g[2]).get_slice(":", 0)
				g[0]._gest = 9999.0
				g[0]._play(nom, 0.0)
				var ap: AnimationPlayer = g[0].npc.get("anim")
				if str(g[2]).contains(":") and ap != null:
					ap.seek(float(str(g[2]).get_slice(":", 1)), true)
					ap.pause()
		await _attendre(50)
		for g in gens:
			g[0].npc.visible = false
		for g in gens:
			var f: Node = g[0]
			f.npc.visible = true
			var mdl: Node3D = f.npc.get("model")
			var s: float = mdl.global_transform.basis.get_scale().x if mdl != null else 1.0
			var cible: Vector3 = g[3] + Vector3(0, 0.88 * s, 0)
			var d: float = 2.5 * s + 0.4
			for v in vues:
				var ang: float = deg_to_rad(float(v[1]))
				f.npc.rotation.y = 0.0
				cam.global_position = cible + Vector3(sin(ang) * d, 0.25 * s, cos(ang) * d)
				cam.look_at(cible, Vector3.UP)
				_reperes(f.npc)
				await _photo("%s_%d__%s__%s" % [st, i, (str(g[2]).replace("/", "-").replace(":", "_") if str(g[2]) != "" else str(g[1])), v[0]])
			f.npc.visible = false
			print("RENDU ", st, ":", i, " ", g[1], " ", g[2])
		for g in gens:
			g[0].npc.queue_free()
		await _attendre(3)
	quit()

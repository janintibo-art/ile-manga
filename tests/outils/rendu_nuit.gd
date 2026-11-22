extends SceneTree
## V193 : des images des gens de la nuit de Port-Boucan (Public averti), pour régler les poses :
## les couples enlacés (boucan_nuit_v193.Pose193 : les bras autour du cou, de la taille, la tête qui
## cherche l'autre), les fumeurs assis (le joint dans la main, porté à la bouche). Lancé par
## tests/outils/rendu_nuit.sh.

const Nuit = preload("res://scripts/boucan_nuit_v193.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = true
	var temps_v56: Node
	var dialogue_v31: Node = null

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		print("MESSAGE ", t)


class FakeTemps:
	extends Node
	var hour: float = 22.0
	var day_count: int = 3
	var lamps_on: bool = true

	func register_glow(_m: Variant, _a: Variant = null, _b: Variant = null) -> void:
		pass

	func register_lamp(_l: Variant, _e: Variant = null) -> void:
		pass


var out: String = ""
var cam: Camera3D
var n_img: int = 0


func _photo(nom: String) -> void:
	for k in range(8):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	n_img += 1
	img.save_png("%s/%02d_%s.png" % [out, n_img, nom])
	print("RENDU ", nom)


func _vue(from: Vector3, to: Vector3) -> void:
	cam.global_position = from
	cam.look_at(to, Vector3.UP)


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.5)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	root.add_child(sun)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	sol.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.35, 0.33, 0.3)
	sol.material_override = sm
	root.add_child(sol)
	var fm := FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.05
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	var N: Node = Nuit.new()
	fm.add_child(N)
	N.main = fm
	N.root = Node3D.new()
	fm.add_child(N.root)
	N._rng.seed = 7
	for k in range(3):
		await process_frame
	var paires: Array = []
	var roles := [["femme", "homme"], ["femme", "femme"], ["homme", "homme"]]
	for i in range(3):
		var c := Vector3(-3.0 + i * 3.0, 0, 0)
		var d := Vector3(1, 0, 0)
		var a: Node = N._figurant(roles[i][0], c - d * 0.17, d, "debout")
		var b: Node = N._figurant(roles[i][1], c + d * 0.17, -d, "debout")
		paires.append([a, b])
	for i in range(3):
		N._enlacer(paires[i][0], paires[i][1], "cou", 1.0)
		N._enlacer(paires[i][1], paires[i][0], "taille", -1.0)
	# deux fumeurs assis (sur une caisse : le corps assis pose son bassin à 0,45 m)
	var fum: Array = []
	for k in range(2):
		var p := Vector3(-1.0 + k * 2.0, 0, 4.0)
		var boite := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.45, 0.42, 0.45)
		boite.mesh = bm
		root.add_child(boite)
		boite.global_position = p + Vector3(0, 0.21, -0.12)
		var f: Node = N._figurant(["homme", "femme"][k], p, Vector3(0, 0, 1), "assis")
		var j: Node3D = N._joint(f)
		var m = N._poser_mod(f, "taf", null, 1.0)
		fum.append([f, m])
	# le temps que les corps se construisent (le visage les construit quand la caméra approche)
	_vue(Vector3(0, 1.6, 5.0), Vector3(0, 1.3, 0))
	for k in range(90):
		await process_frame
	for i in range(3):
		var c2 := Vector3(-3.0 + i * 3.0, 0, 0)
		_vue(c2 + Vector3(0.2, 1.55, 1.6), c2 + Vector3(0, 1.45, 0))
		for k in range(40):
			await process_frame
		await _photo("couple_%d_face" % i)
		_vue(c2 + Vector3(1.4, 1.5, 0.9), c2 + Vector3(0, 1.35, 0))
		await _photo("couple_%d_trois_quarts" % i)
		_vue(c2 + Vector3(0, 1.65, -1.6), c2 + Vector3(0, 1.4, 0))
		await _photo("couple_%d_dos" % i)
	for k in range(2):
		var p2 := Vector3(-1.0 + k * 2.0, 0, 4.0)
		_vue(p2 + Vector3(0.6, 1.25, 1.5), p2 + Vector3(0, 0.95, 0))
		for k2 in range(40):
			await process_frame
		fum[k][1].poids = 0.0
		await _photo("fumeur_%d_repos" % k)
		fum[k][1].poids = 1.0
		await _photo("fumeur_%d_taf" % k)
		_vue(p2 + Vector3(0.9, 1.15, 0.5), p2 + Vector3(0, 1.0, 0.1))
		await _photo("fumeur_%d_taf_profil" % k)
	quit()

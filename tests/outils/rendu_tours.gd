extends SceneTree
## Des images des tours de Néopolis (V153), pour juger l'effet (lancé par tests/outils/rendu_tours.sh) :
## une entrée vue de la rue, le hall, les bureaux, la cafétéria, la salle des serveurs, la direction et
## la vue par la fenêtre, un couloir de logements.

const Neo = preload("res://scripts/neo_v94.gd")


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
		return 1.4

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func jingle(_n: String) -> void:
		pass

	func _show_message_v28(t: String) -> void:
		print("MESSAGE ", t)

	func place_player_v35(at: Vector3, facing: Vector3) -> void:
		facing.y = 0.0
		cam.global_position = at + Vector3.UP * 1.62
		cam.look_at(cam.global_position + facing.normalized(), Vector3.UP)

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
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.fog_enabled = true
	env.fog_density = 0.0015
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var fm := FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.05
	cam.far = 2500.0
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k0 in range(3):
		await process_frame
	var N: Node3D = Neo.new()
	fm.add_child(N)
	N.setup(fm)
	N.build_island()
	N.build_town()
	var T: Node3D = N.tours
	T.test_mode = true
	for k in range(5):
		await process_frame
	# la plus grande tour de bureaux
	var id: int = -1
	for t in T.tours:
		if str(t["type"]) == "bureaux" and (id < 0 or (t["etages"] as Array).size() > (T.tours[id]["etages"] as Array).size()):
			id = int(t["id"])
	var t0: Dictionary = T.tours[id]
	var s: Vector3 = t0["sortie"]
	var n: Vector3 = t0["n"]
	var side: Vector3 = n.cross(Vector3.UP)
	_vue(s + n * 9.0 + side * 3.0 + Vector3.UP * 2.2, s + Vector3.UP * 2.4)
	await _photo("entree_rue")
	await T.enter(id)
	var rect: Rect2 = T.info["rect"]
	var y: float = T.info["y"]
	_vue((t0["face"] as Vector3) - n * 0.8 + Vector3.UP * 1.9 + side * 1.0, T.info["ascenseur"] + Vector3.UP * 1.2)
	await _photo("hall")
	_vue(Vector3(rect.position.x + 1.0, y + 2.2, rect.position.y + 1.0), Vector3(rect.get_center().x, y + 1.0, rect.get_center().y))
	await _photo("hall_coin")
	for k in [1, 2]:
		await T.aller(k)
		rect = T.info["rect"]
		y = T.info["y"]
		_vue(Vector3(rect.position.x + 0.9, y + 2.2, rect.position.y + 0.9), Vector3(rect.get_center().x, y + 0.6, rect.get_center().y))
		await _photo("%s_%d" % [T.info["type"], k])
		_vue(Vector3(rect.end.x - 0.9, y + 1.7, rect.end.y - 0.9), Vector3(rect.get_center().x, y + 0.9, rect.get_center().y))
		await _photo("%s_%d_b" % [T.info["type"], k])
	var ns: int = (t0["etages"] as Array).size()
	for k2 in range(3, ns):
		if T.type_etage(id, k2) == "serveurs":
			await T.aller(k2)
			rect = T.info["rect"]
			y = T.info["y"]
			_vue(Vector3(rect.position.x + 0.9, y + 1.8, rect.position.y + 0.9), Vector3(rect.get_center().x, y + 1.0, rect.get_center().y))
			await _photo("serveurs")
			break
	await T.aller(ns - 1)
	rect = T.info["rect"]
	y = T.info["y"]
	_vue(Vector3(rect.get_center().x, y + 1.7, rect.position.y + 1.2), Vector3(rect.get_center().x + 3.0, y + 0.8, rect.end.y))
	await _photo("direction")
	# la vue : vers la fenêtre la plus proche
	_vue(Vector3(rect.position.x + 1.5, y + 1.7, rect.get_center().y), Vector3(rect.position.x - 30.0, y - 25.0, rect.get_center().y + 10.0))
	await _photo("vue_fenetre")
	await T.leave()
	# des logements
	var idl: int = -1
	for t2 in T.tours:
		if str(t2["type"]) == "logements" and (t2["etages"] as Array).size() >= 6:
			idl = int(t2["id"])
			break
	await T.enter(idl)
	await T.aller(3)
	var a: Vector3 = T.info["ascenseur"]
	var rg: Vector3 = T.info["regard"]
	_vue(a + Vector3.UP * 1.6 - rg * 0.5, a + Vector3.UP * 1.4 + rg.cross(Vector3.UP) * 6.0)
	await _photo("logements")
	_vue(a + Vector3.UP * 1.6 + rg * 0.3, a + Vector3.UP * 1.4 - rg.cross(Vector3.UP) * 6.0)
	await _photo("logements_b")
	await T.leave()
	_vue(Vector3(300, 60, 1150), Vector3(300, 30, 1400))
	await _photo("ville")
	quit()

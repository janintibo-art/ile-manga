extends SceneTree
## Des images de l'Île Perchée (V146), pour juger l'effet (lancé par tests/outils/rendu_perchee.sh) :
## l'île vue de loin et de dessous, le bourg de Pile-ou-Face, ses rues, ses saloons, la place de la Roue,
## les mesas, le ruisseau et sa chute, le Quai des Nuées, la Grande Chaîne, les habitants.

const Ile = preload("res://scripts/ile_perchee_v146.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var perchee: Node
	var ile: Node
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = false
	var temps_v56: Node

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func _height_at(x: float, z: float) -> float:
		if ile != null:
			var h: float = ile.height(x, z)
			if h > -1e6:
				return h
		return 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass


class FakeTemps:
	extends Node
	var hour: float = 10.0
	var lamps_on: bool = false


var out: String = ""
var cam: Camera3D
var fm: FakeMain
var ile: Node3D
var mod: Node


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var quoi: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "tout"
	_monde()
	fm = FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	tp.hour = 16.5
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 62.0
	cam.far = 4000.0
	cam.near = 0.1
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k in range(4):
		await process_frame
	if ResourceLoader.exists("res://scripts/perchee_v146.gd"):
		mod = load("res://scripts/perchee_v146.gd").new()
		fm.add_child(mod)
		fm.perchee = mod
		mod.setup(fm)
		mod.pc = true
		mod.build_all()
		ile = mod.ile
		if "habitants" in mod:
			for n in mod.habitants:
				if n.has_method("body64_build"):
					n.body64_build()
	else:
		ile = Ile.new()
		fm.add_child(ile)
		ile.build(true)
	fm.ile = ile
	var C: Vector3 = Ile.CENTER
	for k2 in range(20):
		await process_frame
	if quoi in ["tout", "ile"]:
		await _vue("01_loin", C + Vector3(520, 120, 380), C + Vector3(0, -40, 0))
		await _vue("02_dessus", C + Vector3(-80, 330, 320), C + Vector3(10, 0, 0))
		await _vue("03_dessous", C + Vector3(300, -140, 160), C + Vector3(0, -90, 0))
		await _vue("04_chute", C + Vector3(-330, -60, 140), C + Vector3(-226, -120, 50))
		await _vue("05_mesa", _sol(-60, -10) + Vector3(0, 1.7, 0), C + Vector3(-138, 18, -66))
		await _vue("06_ruisseau", _sol(-118, 30) + Vector3(0, 1.7, 0), C + Vector3(-210, -6, 44))
		await _vue("07_mare", _sol(-30, 82) + Vector3(0, 1.8, 0), C + Vector3(-62, 0, 62))
		await _vue("08_bord", _sol(150, 140) + Vector3(0, 1.7, 0), C + Vector3(260, -40, 200))
	if quoi in ["tout", "bourg"]:
		await _vue("10_grandrue", _sol(-30, 2) + Vector3(0, 1.7, 0), C + Vector3(60, 4, 0))
		await _vue("11_place", _sol(40, 14) + Vector3(0, 1.7, 0), C + Vector3(60, 5, 0))
		await _vue("12_rue_pique", _sol(58, 80) + Vector3(0, 1.7, 0), C + Vector3(60, 5, -40))
		await _vue("13_rue_est", _sol(150, -3) + Vector3(0, 1.7, 0), C + Vector3(60, 5, 0))
		await _vue("14_bourg_haut", C + Vector3(60, 70, 120), C + Vector3(60, 0, 0))
		await _vue("15_quai", _sol(190, 12) + Vector3(0, 1.7, 0), C + Vector3(240, 0, 0))
		await _vue("16_chaine", _sol(120, 120) + Vector3(0, 1.7, 0), C + Vector3(150, 4, 180))
		await _vue("17_chapelle", _sol(60, -60) + Vector3(0, 1.7, 0), C + Vector3(60, 6, -96))
	quit()


func _sol(x: float, z: float) -> Vector3:
	var w: Vector3 = Ile.W(x, z)
	var h: float = ile.height(w.x, w.z)
	w.y = h if h > -1e6 else Ile.Y0
	return w


func _vue(nom: String, at: Vector3, look: Vector3, images: int = 6) -> void:
	cam.global_position = at
	cam.look_at(look)
	for k in range(images):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, nom])


func _monde() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.52, 0.82)
	sm.sky_horizon_color = Color(0.78, 0.8, 0.86)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_density = 0.0004
	env.fog_light_color = Color(0.74, 0.78, 0.86)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -60, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.light_energy = 1.3
	sun.directional_shadow_max_distance = 400.0
	root.add_child(sun)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4000, 4000)
	sea.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.32, 0.46)
	m.roughness = 0.15
	sea.material_override = m
	root.add_child(sea)
	sea.position = Vector3(Ile.CENTER.x, -0.42, Ile.CENTER.z)

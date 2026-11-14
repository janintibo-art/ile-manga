extends SceneTree
## Des images de l'Île des Géants (V142), pour juger l'effet (lancé par tests/outils/rendu_geants.sh) :
## l'île vue de haut, l'arrivée au ponton, la ferme, le potager, le moulin, la mare, le verger, les
## géants à leur travail, un géant agenouillé qui parle au tout petit visiteur (un repère de 1,75 m).

const Geants = preload("res://scripts/geants_v142.gd")
const Ile = preload("res://scripts/ile_geants_v142.gd")


class FakeMain:
	extends Node3D
	var xr_active: bool = false
	var cam: Camera3D
	var geants: Node
	var npcs_v31: Array = []
	var pending_pnj_v31: Dictionary = {}
	var game_started: bool = false
	var temps_v56: Node

	func _player_pos_v27() -> Vector3:
		return cam.global_position if cam != null else Vector3.ZERO

	func _height_at(x: float, z: float) -> float:
		return geants.ile.height(x, z) if geants != null and geants.ile != null else 0.0

	func _npc_ctx_v31() -> Dictionary:
		return {"now": 0.0, "objets": {}, "vr": false}

	func sfx(_n: String, _at: Variant = null, _db: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass


class FakeTemps:
	extends Node
	var hour: float = 10.0


var out: String = ""
var cam: Camera3D
var fm: FakeMain
var g: Node3D


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	var quoi: String = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "tout"
	_monde()
	fm = FakeMain.new()
	root.add_child(fm)
	var tp := FakeTemps.new()
	tp.hour = 9.5
	fm.add_child(tp)
	fm.temps_v56 = tp
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.far = 3000.0
	cam.near = 0.1
	root.add_child(cam)
	cam.current = true
	fm.cam = cam
	for k in range(4):
		await process_frame
	g = Geants.new()
	fm.add_child(g)
	fm.geants = g
	g.setup(fm)
	g.build_island()
	g.build_town()
	for n in g.habitants:
		n.body64_build()
	var C: Vector3 = Ile.CENTER
	for k2 in range(20):
		await process_frame
	if quoi in ["tout", "vues"]:
		await _vue("01_dessus", C + Vector3(-60, 380, 300), C + Vector3(0, 0, 0))
		await _vue("02_ponton", g.dock()[1] + Vector3(4, 2.2, -6), C + Vector3(0, 30, 0))
		await _vue("03_chemin", _sol(20, -150) + Vector3(0, 1.7, 0), C + Vector3(0, 25, 0))
		await _vue("04_cour", _sol(-20, -95) + Vector3(0, 1.7, 0), C + Vector3(5, 18, -20))
		await _vue("05_porte", _sol(-6, -50) + Vector3(0, 1.7, 0), C + Vector3(0, 14, -30))
		await _vue("06_potager", _sol(64, -60) + Vector3(0, 1.8, 0), C + Vector3(100, 6, -10))
		await _vue("07_choux", _sol(88, -30) + Vector3(0, 1.7, 0), C + Vector3(100, 2, -20))
		await _vue("08_citrouilles", _sol(70, 2) + Vector3(0, 1.8, 0), C + Vector3(90, 3, 25))
		await _vue("09_moulin", _sol(-100, -60) + Vector3(0, 1.7, 0), C + Vector3(-150, 50, -100))
		await _vue("10_mare", _sol(-80, 100) + Vector3(0, 1.8, 0), C + Vector3(-112, 4, 135))
		await _vue("11_verger", _sol(70, 80) + Vector3(0, 1.8, 0), C + Vector3(110, 14, 125))
		await _vue("12_ble", _sol(10, 62) + Vector3(0, 1.8, 0), C + Vector3(10, 4, 100))
		await _vue("13_linge", _sol(-46, 82) + Vector3(0, 1.8, 0), C + Vector3(-48, 9, 46))
		await _vue("14_grange", _sol(-70, -60) + Vector3(0, 1.8, 0), C + Vector3(-98, 12, 0))
		await _vue("15_chateau_sable", _sol(60, -214) + Vector3(0, 1.8, 0), C + Vector3(92, 4, -196))
		await _vue("16_porte_pres", _sol(4, -40) + Vector3(0, 1.7, 0), C + Vector3(0, 12, -28))
	if quoi in ["tout", "geants"]:
		var noms := ["mathurine_gt", "eustache_gt", "ernestine_gt", "paquerette_gt", "theophile_gt"]
		for i in range(noms.size()):
			var n: Node3D = g.by_id.get(noms[i])
			if n == null:
				continue
			var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
			var at: Vector3 = n.global_position + fwd * 7.0
			at.y = fm._height_at(at.x, at.z) + 1.6
			# (le temps que le géant voie le visiteur et s'agenouille : la pose a le temps de se poser)
			cam.global_position = at
			for k3 in range(60):
				cam.look_at(n.global_position + Vector3.UP * float(n.face_height()) * 0.8)
				await process_frame
			await _vue("2%d_%s_pres" % [i, noms[i]], at, n.global_position + Vector3.UP * float(n.face_height()) * 0.8, 10)
			var at2: Vector3 = n.global_position + fwd * 30.0 + fwd.cross(Vector3.UP) * 10.0
			at2.y = fm._height_at(at2.x, at2.z) + 3.0
			await _vue("3%d_%s_loin" % [i, noms[i]], at2, n.global_position + Vector3.UP * float(n.taille) * 0.5, 40)
	quit()


func _sol(x: float, z: float) -> Vector3:
	var w: Vector3 = Ile.W(x, z)
	w.y = g.ile.height(w.x, w.z)
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
	sm.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	# (celui du jeu, main.gd : AgX ; avec Filmic, le sable clair sortait blanc)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_density = 0.0006
	env.fog_light_color = Color(0.7, 0.78, 0.86)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.25
	sun.directional_shadow_max_distance = 300.0
	root.add_child(sun)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2000, 2000)
	sea.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.32, 0.46)
	m.roughness = 0.15
	sea.material_override = m
	root.add_child(sea)
	sea.position = Ile.CENTER + Vector3(0, -0.42, 0)

extends SceneTree
## Des images de la roue des sorts (V145), pour juger l'effet (lancé par tests/outils/rendu_roue.sh) :
## la roue de l'écran (PC), la rangée des sorts avec leurs icônes, la roue autour de la main (VR).

const Roue := preload("res://scripts/roue_v145.gd")
const Sorts := preload("res://scripts/sorts_v67.gd")
const Bete := preload("res://scripts/monstre_v140.gd")


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var combat_v28: Node = null
	var sorts_v67: Node = null
	var roue_v145: Node = null
	var inventory_v28: Node = null
	var journal_v56: Node = null
	var xr_origin: Node3D = null
	var xr_active: bool = false
	var game_started: bool = true
	var game_menu: Node = null
	var dialogue_v31: Node = null

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func sfx(_n: String, _at: Variant = null, _v: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass

	func _player_pos_v27() -> Vector3:
		return Vector3(0, 0, 4)


class FakeMgr:
	extends Node3D
	var main: Node
	var active: bool = false

	func night() -> bool:
		return false

	func alert(_m: Node) -> void:
		pass

	func hurt_player(_a: int, _f: Vector3) -> void:
		pass

	func take_token(_b: Node) -> bool:
		return true

	func release_token(_b: Node) -> void:
		pass

	func shove(_v: Vector3) -> void:
		pass


var out: String = ""
var cam: Camera3D


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	_monde()
	var fm := FakeMain.new()
	root.add_child(fm)
	fm.xr_origin = Node3D.new()
	fm.add_child(fm.xr_origin)
	var so: Node = Sorts.new()
	fm.add_child(so)
	so.setup(fm)
	fm.sorts_v67 = so
	for id in so.ORDRE:
		if str(id) != "foudre":
			so.known[str(id)] = true
	so.choisi = "feu"
	so.mana = 7.0
	var r: Node = Roue.new()
	fm.add_child(r)
	r.setup(fm)
	r.test_mode = true
	fm.roue_v145 = r
	var layer := CanvasLayer.new()
	root.add_child(layer)
	so.make_hud(layer)
	r.make_hud(layer)
	var mgr := FakeMgr.new()
	mgr.main = fm
	root.add_child(mgr)
	var b: CharacterBody3D = Bete.new()
	mgr.add_child(b)
	b.setup(mgr, "sanglier", Vector3(0.6, 0, -2.0))
	b.set_physics_process(false)
	cam = Camera3D.new()
	cam.fov = 60.0
	root.add_child(cam)
	cam.current = true
	for i in range(12):
		await process_frame
	# la rangée des sorts (en haut à droite), avec les icônes
	_vise(Vector3(0, 0.6, -2.0), 4.0)
	await _shot("1_rangee", 0.3)
	# la roue de l'écran : le Gel survolé
	r.pc_appui_b()
	r.pc_tick(0.3, true)
	r.pc_souris(r.dir_pc(2) * 80.0)
	await _shot("2_roue_pc", 0.3)
	r.pc_souris(-r._souris + r.dir_pc(6) * 80.0)
	await _shot("3_roue_pc_inconnu", 0.2)
	r._fermer(false)
	Engine.time_scale = 1.0
	# la roue autour de la main (VR) : la tête en (0, 1.6, 0), la main gauche devant
	var tete := Vector3(0, 1.6, 0)
	cam.global_position = tete
	cam.fov = 90.0
	cam.look_at(Vector3(0.12, 1.2, -0.45), Vector3.UP)
	var main_g := Vector3(0.12, 1.22, -0.42)
	r._ancre = main_g
	r._ouvrir_vr(tete)
	r._roue3d.scale = Vector3.ONE
	r._maj_3d(0.0)
	await _shot("4_roue_vr", 0.2)
	var d1: Vector2 = r.dir_vr(1)
	r._survoler(1)
	r._maj_3d(0.0)
	await _shot("5_roue_vr_feu", 0.2)
	quit()


func _vise(at: Vector3, d: float) -> void:
	cam.global_position = at + Vector3(d * 0.62, d * 0.45, d * 0.72)
	cam.look_at(at, Vector3.UP)


func _attendre(s: float) -> void:
	await create_timer(s).timeout


func _shot(nom: String, apres: float) -> void:
	await create_timer(apres).timeout
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, nom])


func _monde() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.3
	root.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.36, 0.42, 0.24)
	gm.roughness = 0.95
	g.material_override = gm
	root.add_child(g)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(40, 1, 40)
	cs.shape = bs
	cs.position.y = -0.5
	body.add_child(cs)
	root.add_child(body)

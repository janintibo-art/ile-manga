extends SceneTree
## Des images des réactions aux coups et des ondes de choc (V141), pour juger l'effet (lancé par
## tests/outils/rendu_coups.sh). Un sanglier et un loup ; à chaque image, un instant d'un coup.

const Bete := preload("res://scripts/monstre_v140.gd")
const Fx := preload("res://scripts/combat_fx_v129.gd")
const Coups := preload("res://scripts/coups_v141.gd")


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var combat_v28: Node = null
	var coups_v141: Node = null
	var inventory_v28: Node = null
	var xr_active: bool = false

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func sfx(_n: String, _at: Vector3 = Vector3.ZERO, _v: float = 0.0) -> void:
		pass

	func _player_pos_v27() -> Vector3:
		return Vector3(0, 0, 60)


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
	var fx: Node = Fx.new()
	fm.add_child(fx)
	fx.setup(fm)
	fm.combat_fx_v129 = fx
	var cp: Node = Coups.new()
	fm.add_child(cp)
	cp.setup(fm)
	fm.coups_v141 = cp
	var mgr := FakeMgr.new()
	mgr.main = fm
	root.add_child(mgr)
	cam = Camera3D.new()
	cam.fov = 45.0
	root.add_child(cam)
	cam.current = true
	for i in range(12):
		await process_frame
	# un coup simple, puis un coup qui met à terre (le sanglier roule sur le flanc)
	var b: CharacterBody3D = Bete.new()
	mgr.add_child(b)
	b.setup(mgr, "sanglier", Vector3.ZERO)
	b.facing = Vector3(0, 0, 1)
	b.rotation.y = 0.0
	_vise(Vector3(0, 0.45, 0), 3.4)
	await _shot("1_repos", 0.05)
	cp.reagir(b, Vector3(-1.5, 0.5, 0.2), 1)
	await _shot("2_plie", 0.07)
	await _attendre(0.6)
	cp.reagir(b, Vector3(-1.5, 0.5, 0.2), 3)
	await _shot("3_tombe", 0.16)
	await _shot("4_a_terre", 0.45)
	await _shot("5_se_releve", 1.3)
	await _attendre(1.0)
	b.queue_free()
	# un loup (un bipède ? non : il roule aussi) et le coup final
	var lp: CharacterBody3D = Bete.new()
	mgr.add_child(lp)
	lp.setup(mgr, "loup_bois", Vector3.ZERO)
	lp.facing = Vector3(1, 0, 0)
	lp.rotation.y = PI * 0.5
	cp.coup_final(Vector3(-0.6, 0.3, 0), Vector3(1, 0, 0), true)
	cp.reagir(lp, Vector3(-1.4, 0.5, 0), 3)
	await _shot("6_coup_final", 0.12)
	await _shot("7_loup_a_terre", 0.6)
	await _attendre(1.5)
	lp.queue_free()
	# l'onde de choc au sol (coup plongeant)
	_vise(Vector3(0, 0.3, 0), 6.5)
	cp.onde_sol(Vector3.ZERO, 2.4)
	await _shot("8_onde", 0.08)
	await _shot("9_onde_poussiere", 0.35)
	await _shot("10_fente", 1.6)
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

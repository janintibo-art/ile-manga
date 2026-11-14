extends SceneTree
## Des images de la lisibilité du combat (V144), pour juger l'effet (lancé par
## tests/outils/rendu_cibles.sh) : la barre de vie (la part perdue, l'état, la faiblesse), l'anneau
## de la cible, l'anneau rouge du verrouillage, le « ! » de l'ennemi qui arme son coup.

const Bete := preload("res://scripts/monstre_v140.gd")
const Fx := preload("res://scripts/combat_fx_v129.gd")
const Coups := preload("res://scripts/coups_v141.gd")
const Elements := preload("res://scripts/elements_v143.gd")
const Combat := preload("res://scripts/combat_v28.gd")
const Cibles := preload("res://scripts/cibles_v144.gd")


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var combat_v28: Node = null
	var coups_v141: Node = null
	var inventory_v28: Node = null
	var elements_v143: Node = null
	var cibles_v144: Node = null
	var hero_v28: Node = null
	var game_started: bool = true
	var pc_root: Node3D = null
	var talking_npc_v31: Node3D = null
	var joueur := Vector3(-4.0, 0, 1.0)
	var pc_body: Node = null
	var vr_body: Node = null
	var xr_active: bool = false

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func sfx(_n: String, _at: Vector3 = Vector3.ZERO, _v: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass

	func _player_pos_v27() -> Vector3:
		return joueur


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


class FakeHero:
	extends Node
	var facing := Vector3(1, 0, -0.2).normalized()


var out: String = ""
var cam: Camera3D
var mgr: Node3D


func _bete(kind: String, at: Vector3) -> CharacterBody3D:
	var b: CharacterBody3D = Bete.new()
	mgr.add_child(b)
	b.setup(mgr, kind, at)
	b.facing = Vector3(0, 0, 1)
	b.rotation.y = 0.0
	b.set_physics_process(false)
	return b


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	_monde()
	var fm := FakeMain.new()
	root.add_child(fm)
	fm.hero_v28 = FakeHero.new()
	fm.add_child(fm.hero_v28)
	var fx: Node = Fx.new()
	fm.add_child(fx)
	fx.setup(fm)
	fm.combat_fx_v129 = fx
	var cb: Node = Combat.new()
	fm.add_child(cb)
	cb.set("main", fm)
	fm.combat_v28 = cb
	var el: Node = Elements.new()
	fm.add_child(el)
	el.setup(fm)
	fm.elements_v143 = el
	var cv: Node = Cibles.new()
	fm.add_child(cv)
	cv.setup(fm)
	fm.cibles_v144 = cv
	mgr = FakeMgr.new()
	mgr.main = fm
	root.add_child(mgr)
	cam = Camera3D.new()
	cam.fov = 45.0
	root.add_child(cam)
	cam.current = true
	for i in range(12):
		await process_frame
	var b: CharacterBody3D = _bete("sanglier", Vector3.ZERO)
	var l: CharacterBody3D = _bete("loup_bois", Vector3(2.6, 0, -1.6))
	var r: CharacterBody3D = _bete("ronceux_sauvage", Vector3(1.0, 0, 2.6))
	b.state = "chasse"
	l.state = "chasse"
	_vise(Vector3(1.0, 0.8, 0.3), 7.0)
	await _shot("1_cible", 0.5)
	b.take_hit(8, Vector3(-2, 0.5, 0))
	b.state = "chasse"
	await _shot("2_blesse", 0.25)
	await _shot("3_barre", 1.3)
	cv.basculer()
	await _shot("4_verrou", 0.4)
	el.enflammer(b)
	await _shot("5_en_feu", 0.6)
	el._efface(b)
	r.take_hit(3, Vector3(-2, 0.5, 0))
	l.take_hit(7, Vector3(-2, 0.5, 0))
	l.state = "chasse"
	await _attendre(0.3)
	l.state = "armer"
	await _shot("6_alerte", 0.25)
	cv.basculer()
	await _shot("7_suivant", 0.6)
	cv.relacher()
	fm.hero_v28.facing = Vector3(0.75, 0, 0.6).normalized()
	el.decouvertes["plante"] = true
	_vise(Vector3(1.0, 0.9, 2.6), 3.6)
	await _shot("8_faiblesse", 0.6)
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

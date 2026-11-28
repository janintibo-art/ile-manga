extends SceneTree
## V220 : des images de la roue de la main droite, pour juger l'effet (lancé par
## tests/outils/rendu_roue_armes.sh) : la roue des armes (cinq cases, la hache désignée), la grande roue
## (douze cases), la roue des pouvoirs (deux éveillés, deux qui dorment). Vue depuis la tête, comme dans le
## casque. Un atelier : un sac et des sceaux factices ; les vraies icônes, la vraie main (V199) et les vraies
## armes (V129) du jeu, tenues comme dans le casque ; la main est poussée vers la case désignée.

const Roue := preload("res://scripts/roue_armes_v220.gd")
const Sac := preload("res://scripts/inventory_v28.gd")
const Prog := preload("res://scripts/progression_v63.gd")
const Fx := preload("res://scripts/combat_fx_v129.gd")
const Bete := preload("res://scripts/monstre_v140.gd")
const Mains := preload("res://scripts/vr_mains_v199.gd")
const Armes := preload("res://scripts/armes_v129.gd")


class FauxSac:
	extends Node
	var ITEMS: Dictionary = {}
	var equipped: String = ""
	var _icons: Dictionary = {}
	var a_moi: Dictionary = {}

	func count(id: String) -> int:
		return int(a_moi.get(id, 0))

	func equip_item(id: String) -> void:
		equipped = id


class FauxProgres:
	extends Node
	var POWER_ORDER: Array = []
	var POWER_OF: Dictionary = {}
	var SEALS: Dictionary = {}
	var seals: Dictionary = {}
	var power: String = ""

	func power_owned(pid: String) -> bool:
		return POWER_OF.has(pid) and seals.has(str(POWER_OF[pid]))

	func select_power(pid: String) -> bool:
		power = pid
		return true

	func use_power() -> bool:
		return true


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var inventory_v28: Node = null
	var progression_v63: Node = null
	var mer_v55: Node = null
	var xr_origin: Node3D = null
	var xr_active: bool = false
	var right_hand: Node3D = null

	func sfx(_n: String, _at: Variant = null, _v: float = 0.0) -> void:
		pass

	func _show_message_v28(_t: String) -> void:
		pass


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
var n_img: int = 0
var manette: XRController3D


func _initialize() -> void:
	out = str(OS.get_cmdline_user_args()[0])
	_monde()
	var fm := FakeMain.new()
	root.add_child(fm)
	fm.xr_origin = Node3D.new()
	fm.add_child(fm.xr_origin)
	var sac := FauxSac.new()
	sac.ITEMS = Sac.ITEMS
	for id in Sac.ITEMS:
		var chemin: String = "res://assets/textures/items/%s.png" % id
		if ResourceLoader.exists(chemin):
			sac._icons[id] = load(chemin)
	fm.add_child(sac)
	fm.inventory_v28 = sac
	var pr := FauxProgres.new()
	pr.POWER_ORDER = Prog.POWER_ORDER
	pr.POWER_OF = Prog.POWER_OF
	pr.SEALS = Prog.SEALS
	fm.add_child(pr)
	fm.progression_v63 = pr
	var fx: Node = Fx.new()
	fm.add_child(fx)
	fx.setup(fm)
	fm.combat_fx_v129 = fx
	var r: Node3D = Roue.new()
	fm.add_child(r)
	r.setup(fm)
	r.test_mode = true
	var mgr := FakeMgr.new()
	mgr.main = fm
	root.add_child(mgr)
	cam = Camera3D.new()
	cam.fov = 62.0
	root.add_child(cam)
	cam.current = true
	var tete := Vector3(0, 1.6, 0)
	var main_d := Vector3(0.2, 1.25, -0.45)
	for i in range(6):
		await process_frame
	# (une fois dans la scène : un sanglier au fond, pour l'échelle)
	var b: CharacterBody3D = Bete.new()
	mgr.add_child(b)
	b.setup(mgr, "sanglier", Vector3(-0.9, 0, -3.2))
	b.set_physics_process(false)
	b.set_process(false)
	# la main droite du joueur (V199), le poing fermé sur la poignée, là où la roue s'ouvre
	manette = XRController3D.new()
	fm.xr_origin.add_child(manette)
	manette.position = main_d
	manette.rotation_degrees = Vector3(38.0, 8.0, 0.0)
	var poing: Node3D = Mains.new()
	poing.setup(manette, false)
	poing.essai_ferme = 1.0
	for i in range(6):
		await process_frame
	# (une fois dans la scène : la tête regarde la main droite)
	cam.look_at_from_position(tete, Vector3(0.17, 1.25, -0.45), Vector3.UP)
	# --- la roue des armes : cinq cases, l'épée en main, la hache désignée
	for id in ["epee_bois", "hache", "epee", "canne_peche"]:
		sac.a_moi[id] = 1
	sac.equipped = "epee"
	_tenir("epee")
	await _roue(r, "armes", main_d, tete, "hache", "1_roue_des_armes")
	# --- tout le sac : douze cases
	for id in Sac.ITEMS:
		if r._se_tient(Sac.ITEMS[id]):
			sac.a_moi[id] = 1
	sac.equipped = "epee_nuees"
	_tenir("epee_nuees")
	await _roue(r, "armes", main_d, tete, "canne_peche", "2_grande_roue")
	# --- la roue des pouvoirs : le vent et la flamme éveillés
	pr.seals[str(Prog.POWER_OF["vent"])] = true
	pr.seals[str(Prog.POWER_OF["flamme"])] = true
	pr.power = "vent"
	await _roue(r, "pouvoirs", main_d, tete, "flamme", "3_roue_des_pouvoirs")
	quit()


## L'arme dans la main droite, tenue comme dans le jeu (main._on_equip_v28) : la lame vers l'avant.
func _tenir(id: String) -> void:
	var vieux: Node = manette.get_node_or_null("Arme")
	if vieux != null:
		manette.remove_child(vieux)
		vieux.queue_free()
	if id == "" or not Armes.has(id):
		return
	var porte := Node3D.new()
	porte.name = "Arme"
	porte.rotation_degrees = Vector3(-90, 0, 0)
	porte.position = Vector3(0, -0.01, 0.03)
	porte.add_child(Armes.build(id))
	manette.add_child(porte)


## Ouvre une roue autour de la main, pousse la main vers une case, prend l'image, referme.
func _roue(r: Node3D, quelle: String, main_d: Vector3, tete: Vector3, vise: String, nom: String) -> void:
	manette.position = main_d
	r._ouvrir(quelle, tete, main_d)
	# (l'atelier tient la roue ouverte lui-même : la veille du module la refermerait, faute de gestes)
	r.set_physics_process(false)
	r._roue3d.scale = Vector3.ONE
	for i in range(r.cases.size()):
		if str(r.cases[i]["id"]) == vise:
			r._survoler(i)
			var d: Vector2 = r.dir_case(i)
			manette.position = main_d + r._plan * Vector3(d.x, d.y, 0.0) * 0.07
	r._maj_3d(0.0)
	await _shot(nom, 0.2)
	r._fermer()
	manette.position = main_d


func _shot(nom: String, apres: float) -> void:
	await create_timer(apres).timeout
	await process_frame
	n_img += 1
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, nom])
	print("RENDU ", nom)


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

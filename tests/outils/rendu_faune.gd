extends SceneTree
## Des images des bêtes sauvages, pour juger les modèles (lancé par tests/outils/rendu_faune.sh).
##     godot --path pcvr --rendering-driver opengl3 --script res://rendu_faune.gd -- DOSSIER [nuit] espèce espèce…
## Pour chaque espèce : une image au repos (en marche) et une image en attaque, de trois quarts.

const Bete := preload("res://scripts/monstre_v136.gd")

## La distance de la caméra et la hauteur visée (et, si on veut, l'avancée du point visé), selon la taille de la bête.
const CADRE := {"crocodile": [3.6, 0.3], "aigle_royal": [3.2, 0.0], "jaguar_sauvage": [2.4, 0.45], "scarabee_geant": [2.4, 0.4],
	"mille_pattes": [2.3, 0.15], "araignee_geante": [2.2, 0.3], "coyote": [2.0, 0.42], "chacal": [1.8, 0.38],
	"coati": [1.6, 0.25], "singe_hurleur": [2.0, 0.5], "axolotl": [1.5, 0.12], "luciole": [1.8, 0.2],
	"cheval_sauvage": [4.2, 0.85], "fregate": [3.2, 0.0], "tortue_verte": [2.4, 0.2], "perroquet": [1.7, 0.0], "varan": [3.0, 0.2],
	"crabe_cocotier": [2.0, 0.25], "lapin_garenne": [1.0, 0.15], "frelon": [1.6, 0.0], "herisson": [0.75, 0.08],
	"hibou_grand_duc": [1.7, 0.35], "renard_roux": [1.9, 0.3]}
## La pose d'attaque de chaque espèce : [état, minuteur].
const ATTAQUE := {"crocodile": ["armer", 0.05], "aigle_royal": ["pique", 1.0], "jaguar_sauvage": ["armer", 0.1], "scarabee_geant": ["chasse", 0.0],
	"mille_pattes": ["armer", 0.1], "araignee_geante": ["armer", 0.05], "coyote": ["armer", 0.1], "chacal": ["armer", 0.1],
	"coati": ["emporte", 3.0], "singe_hurleur": ["armer", 0.3], "axolotl": ["fuite", 1.0], "luciole": ["vol", 0.0],
	"cheval_sauvage": ["ruade_fin", 0.3], "fregate": ["pique", 1.0], "tortue_verte": ["ponte", 5.0], "perroquet": ["tourne", 3.0],
	"varan": ["fouet", 0.2], "crabe_cocotier": ["armer", 0.3], "lapin_garenne": ["alerte", 0.3], "frelon": ["chasse", 0.0],
	"herisson": ["boule", 0.0], "hibou_grand_duc": ["envol", 0.0], "renard_roux": ["emporte", 3.0]}

var nuit: bool = false


class FakeMain:
	extends Node3D
	var combat_fx_v129: Node = null
	var combat_v28: Node = null
	var inventory_v28: Node = null

	func _height_at(_x: float, _z: float) -> float:
		return 0.0

	func sfx(_n: String, _at: Vector3 = Vector3.ZERO) -> void:
		pass

	func _player_pos_v27() -> Vector3:
		return Vector3(0, 0, 60)


class FakeMgr:
	extends Node3D
	var main: Node
	var active: bool = false
	var de_nuit: bool = false

	func night() -> bool:
		return de_nuit

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


func _initialize() -> void:
	var args: Array = OS.get_cmdline_user_args()
	var out: String = str(args[0])
	var kinds: Array = []
	for a in args.slice(1):
		if a == "nuit":
			nuit = true
		else:
			kinds.append(a)
	_monde()
	var fm := FakeMain.new()
	root.add_child(fm)
	var mgr := FakeMgr.new()
	mgr.main = fm
	mgr.de_nuit = nuit
	root.add_child(mgr)
	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	cam.current = true
	# les premières images servent à compiler les matières : on les laisse passer
	for i in range(12):
		await process_frame
	for k in kinds:
		for pose in ["repos", "attaque"]:
			var b: CharacterBody3D = Bete.new()
			mgr.add_child(b)
			b.setup(mgr, str(k), Vector3.ZERO)
			b.set_physics_process(false)
			b.facing = Vector3(0, 0, 1)
			b.rotation.y = 0.0
			b._sink = 0.0
			b._visual.position = Vector3.ZERO
			if b.vol:
				b.global_position = Vector3(0, 0.9 if k == "aigle_royal" else 0.6, 0)
			var speed: float = 0.0
			if pose == "repos":
				b.state = "erre" if not b.vol else ("chasse" if k == "aigle_royal" else "vol")
				speed = float(b.spec["vitesse"]) * (0.5 if k != "luciole" else 0.0)
			else:
				var at: Array = ATTAQUE.get(str(k), ["armer", 0.2])
				b.state = str(at[0])
				b.timer = float(at[1])
				if str(k) == "herisson":
					b._ball = 1.0
			for i in range(40):
				b._clock += 0.013
				b._animate132(0.016, speed)
			var c: Array = CADRE.get(str(k), [2.5, 0.4])
			var d: float = float(c[0])
			var aim := Vector3(0, float(c[1]) + (b.global_position.y if b.vol else 0.0), float(c[2]) if c.size() > 2 else 0.0)
			cam.global_position = aim + Vector3(d * 0.72, d * 0.42, d * 0.62)
			cam.look_at(aim, Vector3.UP)
			for i in range(4):
				await process_frame
			var img: Image = root.get_texture().get_image()
			img.save_png("%s/%s_%s.png" % [out, k, pose])
			b.queue_free()
			await process_frame
	quit()


func _monde() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	if nuit:
		sm.sky_top_color = Color(0.02, 0.03, 0.07)
		sm.sky_horizon_color = Color(0.05, 0.07, 0.12)
		sm.ground_bottom_color = Color(0.01, 0.01, 0.02)
		sm.ground_horizon_color = Color(0.04, 0.05, 0.08)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.25 if nuit else 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 0.12 if nuit else 1.3
	sun.light_color = Color(0.6, 0.7, 1.0) if nuit else Color(1.0, 0.96, 0.9)
	root.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.34, 0.33, 0.24)
	gm.roughness = 0.95
	g.material_override = gm
	root.add_child(g)

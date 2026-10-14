extends Node
## V28 : le héros PC bouge vraiment.
## - Animations : les clips du modèle (course, marche, combo de coups, chute) et des poses
##   construites ici, os par os (repos, saut, chute, réception, escalade, se hisser,
##   pousser une porte, coups d'épée, parade, roulade, ramasser, manger, être touché).
## - Mouvements : courir (Maj), sauter (Espace), s'accrocher à un mur et grimper,
##   se hisser sur un rebord, roulade (Ctrl), frapper (clic gauche), parer (F maintenu).
## - Vie (cœurs) et endurance (escalade, sprint, roulade), dégâts de chute.
## La VR garde son déplacement au joystick ; elle réutilise seulement la recherche de rebord.

signal health_changed(hp: int, hp_max: int)
signal fainted

const JUMP_SPEED: float = 6.6          # ~1,2 m de haut avec la gravité du jeu (18)
const RUN_SPEED: float = 5.0
const WALK_SPEED: float = 3.1
const CLIMB_SPEED: float = 1.25
const ROLL_SPEED: float = 6.2
const ROLL_TIME: float = 0.62
const COYOTE: float = 0.14
const JUMP_BUFFER: float = 0.16
const STAMINA_MAX: float = 10.0
const HP_MAX: int = 10                  # 5 cœurs, par demi-cœurs
const HEARTS: int = 5
const LEDGE_MIN: float = 0.45           # en dessous, la marche automatique suffit
const LEDGE_MAX: float = 2.15           # rebord le plus haut qu'on attrape depuis le sol
const SAFE_FALL: float = 5.0            # chute sans dégâts (m)

const BONES := ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "RightUpLeg", "RightLeg",
	"RightFoot", "RightToeBase", "Spine02", "Spine01", "Spine", "LeftShoulder", "LeftArm", "LeftForeArm",
	"LeftHand", "RightShoulder", "RightArm", "RightForeArm", "RightHand", "neck", "Head"]

## Combo de poings : [début, fin, instants des coups] dans le clip Punch_Combo_5.
const PUNCH_SEGMENTS := [[0.30, 1.12, [0.92]], [1.12, 1.58, [1.40]], [1.58, 1.93, [1.80]], [1.93, 3.05, [2.06, 2.60]]]
const PUNCH_SPEED: float = 1.35
const SLASHES := ["v28/slash1", "v28/slash2", "v28/slash3"]
const SLASH_HIT: float = 0.22           # instant du coup dans une animation d'épée (s)

var main: Node                          # main.gd (pour _move_player, la caméra, les entrées)
var body: CharacterBody3D
var root: Node3D
var hero: Node3D
var camera: Camera3D
var anim: AnimationPlayer
var skel: Skeleton3D
var sword_holder: Node3D                # épée visible dans la main droite
var weapon: String = ""                 # identifiant de l'arme équipée ("" = mains nues)
var weapon_damage: int = 1

var state: String = "sol"               # sol, air, escalade, hisser, roulade, attaque, action, ko
var hp: int = HP_MAX
var stamina: float = STAMINA_MAX
var stamina_lock: bool = false          # endurance vidée : il faut attendre qu'elle remonte
var facing: Vector3 = Vector3.FORWARD
var coyote: float = 0.0
var jump_buffer: float = 0.0
var fall_top: float = 0.0
var action_time: float = 0.0
var action_length: float = 0.0
var roll_dir: Vector3 = Vector3.ZERO
var blocking: bool = false
var wall_normal: Vector3 = Vector3.BACK
var mantle_from: Vector3
var mantle_mid: Vector3
var mantle_to: Vector3
var combo_index: int = 0
var combo_queued: bool = false
var hits_pending: Array = []            # instants (dans l'animation en cours) des coups à porter
var attack_clock: float = 0.0
var cam_distance: float = 1.0
var current_anim: String = ""
var ko_time: float = 0.0
var hurt_cooldown: float = 0.0
var air_time: float = 0.0
var climb_time: float = 0.0

## Fonction appelée pour frapper : (origine, direction, portée, dégâts) -> nombre de cibles touchées.
var strike: Callable


func setup(main_node: Node, player_body: CharacterBody3D, player_root: Node3D, hero_model: Node3D, cam: Camera3D) -> void:
	main = main_node
	body = player_body
	root = player_root
	hero = hero_model
	camera = cam
	if hero != null:
		anim = hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var found := hero.find_children("*", "Skeleton3D", true, false)
		skel = found[0] if found.size() > 0 else null
	if anim != null and skel != null:
		_build_animations()
		_play("v28/idle", 0.0)
	print("ILE_MANGA_V28: héros animé = ", anim != null and skel != null)


# =================================================================== animations

func _build_animations() -> void:
	var lib: AnimationLibrary = anim.get_animation_library("")
	for clip in ["Walking", "Running"]:
		if lib.has_animation(clip):
			lib.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if lib.has_animation("Knock_Down"):
		_pin_root(lib.get_animation("Knock_Down"))
	var poses := AnimationLibrary.new()
	var arms_in := {"LeftArm": Vector3(0, 0, -13), "RightArm": Vector3(0, 0, 13), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-14, 0, 0)}
	var idle_b := arms_in.duplicate()
	idle_b["Spine"] = Vector3(-2.5, 0, 0)
	idle_b["Head"] = Vector3(2, 3, 0)
	idle_b["LeftArm"] = Vector3(-2, 0, -11)
	idle_b["RightArm"] = Vector3(-2, 0, 11)
	poses.add_animation("idle", _clip(3.2, true, [[0.0, arms_in, Vector3.ZERO], [1.6, idle_b, Vector3(0, -0.6, 0)], [3.2, arms_in, Vector3.ZERO]]))
	# Saut : impulsion bras levés, puis jambes repliées.
	var push := {"LeftArm": Vector3(-75, 0, 18), "RightArm": Vector3(-75, 0, -18), "LeftForeArm": Vector3(-25, 0, 0), "RightForeArm": Vector3(-25, 0, 0),
		"Spine02": Vector3(-6, 0, 0), "LeftUpLeg": Vector3(-10, 0, 0), "RightUpLeg": Vector3(8, 0, 0), "RightLeg": Vector3(25, 0, 0), "Head": Vector3(-8, 0, 0)}
	var tuck := {"LeftArm": Vector3(-35, 0, 45), "RightArm": Vector3(-35, 0, -45), "LeftForeArm": Vector3(-40, 0, 0), "RightForeArm": Vector3(-40, 0, 0),
		"LeftUpLeg": Vector3(-60, 0, 0), "LeftLeg": Vector3(85, 0, 0), "RightUpLeg": Vector3(-25, 0, 0), "RightLeg": Vector3(70, 0, 0), "Spine02": Vector3(8, 0, 0)}
	poses.add_animation("jump", _clip(0.4, false, [[0.0, push, Vector3(0, 2, 0)], [0.4, tuck, Vector3(0, 4, 0)]]))
	var fall_a := {"LeftArm": Vector3(-25, 0, 62), "RightArm": Vector3(-25, 0, -62), "LeftForeArm": Vector3(-25, 0, 0), "RightForeArm": Vector3(-25, 0, 0),
		"LeftUpLeg": Vector3(-30, 0, 0), "LeftLeg": Vector3(45, 0, 0), "RightUpLeg": Vector3(-8, 0, 0), "RightLeg": Vector3(25, 0, 0), "Spine02": Vector3(-4, 0, 0), "Head": Vector3(10, 0, 0)}
	var fall_b := fall_a.duplicate()
	fall_b["LeftArm"] = Vector3(-30, 0, 70)
	fall_b["RightArm"] = Vector3(-20, 0, -66)
	fall_b["LeftUpLeg"] = Vector3(-14, 0, 0)
	fall_b["RightUpLeg"] = Vector3(-26, 0, 0)
	poses.add_animation("fall", _clip(0.9, true, [[0.0, fall_a, Vector3.ZERO], [0.45, fall_b, Vector3.ZERO], [0.9, fall_a, Vector3.ZERO]]))
	var crouch := {"LeftUpLeg": Vector3(-52, 0, 0), "RightUpLeg": Vector3(-52, 0, 0), "LeftLeg": Vector3(88, 0, 0), "RightLeg": Vector3(88, 0, 0),
		"LeftFoot": Vector3(-34, 0, 0), "RightFoot": Vector3(-34, 0, 0), "Spine02": Vector3(28, 0, 0), "Head": Vector3(-18, 0, 0),
		"LeftArm": Vector3(-30, 0, 25), "RightArm": Vector3(-30, 0, -25), "LeftForeArm": Vector3(-30, 0, 0), "RightForeArm": Vector3(-30, 0, 0)}
	poses.add_animation("land", _clip(0.36, false, [[0.0, crouch, Vector3(0, -17, 0)], [0.36, arms_in, Vector3.ZERO]]))
	# Escalade : main gauche haute / main droite haute, en alternance, genoux qui montent.
	var climb_a := {"LeftArm": Vector3(-155, 0, 12), "LeftForeArm": Vector3(-25, 0, 0), "RightArm": Vector3(-100, 0, -14), "RightForeArm": Vector3(-70, 0, 0),
		"LeftUpLeg": Vector3(-18, 0, 0), "LeftLeg": Vector3(30, 0, 0), "RightUpLeg": Vector3(-62, 0, 0), "RightLeg": Vector3(85, 0, 0),
		"Spine02": Vector3(6, 0, 0), "Head": Vector3(-22, 0, 0)}
	var climb_b := {"RightArm": Vector3(-155, 0, -12), "RightForeArm": Vector3(-25, 0, 0), "LeftArm": Vector3(-100, 0, 14), "LeftForeArm": Vector3(-70, 0, 0),
		"RightUpLeg": Vector3(-18, 0, 0), "RightLeg": Vector3(30, 0, 0), "LeftUpLeg": Vector3(-62, 0, 0), "LeftLeg": Vector3(85, 0, 0),
		"Spine02": Vector3(6, 0, 0), "Head": Vector3(-22, 0, 0)}
	poses.add_animation("climb", _clip(1.1, true, [[0.0, climb_a, Vector3(0, 0, -4)], [0.55, climb_b, Vector3(0, 0, -4)], [1.1, climb_a, Vector3(0, 0, -4)]]))
	# Se hisser : suspendu, traction coudes pliés, appui sur les mains, debout.
	var hang := {"LeftArm": Vector3(-168, 0, 8), "RightArm": Vector3(-168, 0, -8), "LeftForeArm": Vector3(-10, 0, 0), "RightForeArm": Vector3(-10, 0, 0),
		"LeftUpLeg": Vector3(-12, 0, 0), "RightUpLeg": Vector3(-4, 0, 0), "LeftLeg": Vector3(20, 0, 0), "RightLeg": Vector3(14, 0, 0), "Head": Vector3(-20, 0, 0)}
	var pull := {"LeftArm": Vector3(-110, 0, 20), "RightArm": Vector3(-110, 0, -20), "LeftForeArm": Vector3(-105, 0, 0), "RightForeArm": Vector3(-105, 0, 0),
		"LeftUpLeg": Vector3(-75, 0, 0), "LeftLeg": Vector3(95, 0, 0), "RightUpLeg": Vector3(-30, 0, 0), "RightLeg": Vector3(50, 0, 0), "Spine02": Vector3(25, 0, 0)}
	var press := {"LeftArm": Vector3(-25, 0, 22), "RightArm": Vector3(-25, 0, -22), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0),
		"LeftUpLeg": Vector3(-80, 0, 0), "LeftLeg": Vector3(110, 0, 0), "RightUpLeg": Vector3(-10, 0, 0), "RightLeg": Vector3(30, 0, 0), "Spine02": Vector3(35, 0, 0)}
	poses.add_animation("mantle", _clip(0.85, false, [[0.0, hang, Vector3(0, -6, -6)], [0.35, pull, Vector3(0, -4, 0)], [0.62, press, Vector3(0, -14, 6)], [0.85, arms_in, Vector3.ZERO]]))
	# Pousser une porte : bras droit tendu, petit pas en avant.
	var shove := {"RightArm": Vector3(-82, 0, -4), "RightForeArm": Vector3(-8, 0, 0), "LeftArm": Vector3(10, 0, -10), "LeftForeArm": Vector3(-20, 0, 0),
		"Spine02": Vector3(10, 12, 0), "LeftUpLeg": Vector3(-22, 0, 0), "LeftLeg": Vector3(20, 0, 0), "RightUpLeg": Vector3(10, 0, 0)}
	poses.add_animation("push", _clip(0.7, false, [[0.0, arms_in, Vector3.ZERO], [0.25, shove, Vector3(0, -2, 3)], [0.45, shove, Vector3(0, -2, 4)], [0.7, arms_in, Vector3.ZERO]]))
	# Ramasser : on s'accroupit, main droite au sol.
	var reach := crouch.duplicate()
	reach["Spine02"] = Vector3(45, 0, 0)
	reach["RightArm"] = Vector3(-55, 0, -5)
	reach["RightForeArm"] = Vector3(-10, 0, 0)
	poses.add_animation("pickup", _clip(0.75, false, [[0.0, arms_in, Vector3.ZERO], [0.32, reach, Vector3(0, -24, 0)], [0.45, reach, Vector3(0, -24, 0)], [0.75, arms_in, Vector3.ZERO]]))
	# Manger : main droite à la bouche.
	var bite := arms_in.duplicate()
	bite["RightArm"] = Vector3(-38, 0, 30)
	bite["RightForeArm"] = Vector3(-135, 0, 0)
	bite["Head"] = Vector3(8, 0, 0)
	poses.add_animation("eat", _clip(1.1, false, [[0.0, arms_in, Vector3.ZERO], [0.3, bite, Vector3.ZERO], [0.8, bite, Vector3.ZERO], [1.1, arms_in, Vector3.ZERO]]))
	# Touché : recul du buste.
	var flinch := {"Spine02": Vector3(-18, 0, 0), "Head": Vector3(-20, 0, 0), "LeftArm": Vector3(-30, 0, 35), "RightArm": Vector3(-30, 0, -35)}
	poses.add_animation("hurt", _clip(0.4, false, [[0.0, arms_in, Vector3.ZERO], [0.12, flinch, Vector3(0, -3, -6)], [0.4, arms_in, Vector3.ZERO]]))
	# Parade : avant-bras devant le visage, genoux fléchis.
	var guard := {"LeftArm": Vector3(-72, 0, -22), "RightArm": Vector3(-72, 0, 22), "LeftForeArm": Vector3(-105, 0, 0), "RightForeArm": Vector3(-105, 0, 0),
		"Spine02": Vector3(10, 0, 0), "LeftUpLeg": Vector3(-20, 0, 0), "RightUpLeg": Vector3(-12, 0, 0), "LeftLeg": Vector3(28, 0, 0), "RightLeg": Vector3(22, 0, 0), "Head": Vector3(-6, 0, 0)}
	poses.add_animation("block", _clip(0.2, true, [[0.0, guard, Vector3(0, -5, 0)], [0.2, guard, Vector3(0, -5, 0)]]))
	# Roulade avant : le bassin fait un tour complet, corps groupé.
	var keys := []
	var curled := {"LeftUpLeg": Vector3(-115, 0, 0), "RightUpLeg": Vector3(-115, 0, 0), "LeftLeg": Vector3(130, 0, 0), "RightLeg": Vector3(130, 0, 0),
		"LeftArm": Vector3(-70, 0, 15), "RightArm": Vector3(-70, 0, -15), "LeftForeArm": Vector3(-95, 0, 0), "RightForeArm": Vector3(-95, 0, 0),
		"Spine02": Vector3(30, 0, 0), "Spine01": Vector3(10, 0, 0), "Head": Vector3(30, 0, 0)}
	for k in range(9):
		var u: float = float(k) / 8.0
		var pose := curled.duplicate()
		pose["Hips"] = Vector3(u * 360.0 if k < 8 else 0.0, 0, 0)
		var low: float = sin(u * PI)
		keys.append([u * ROLL_TIME, pose if k > 0 and k < 8 else crouch, Vector3(0, -48.0 * low - (17.0 if k == 0 or k == 8 else 0.0), 0)])
	poses.add_animation("roll", _clip(ROLL_TIME, false, keys))
	# Épée : revers, coup droit, coup de haut en bas.
	var stance := {"LeftUpLeg": Vector3(-28, 0, 0), "LeftLeg": Vector3(26, 0, 0), "RightUpLeg": Vector3(14, 0, 0), "RightLeg": Vector3(12, 0, 0)}
	var w1 := _merge(stance, {"Spine02": Vector3(0, -38, 0), "RightArm": Vector3(-70, 0, -75), "RightForeArm": Vector3(-75, 0, 0), "LeftArm": Vector3(-30, 0, 20)})
	var s1 := _merge(stance, {"Spine02": Vector3(6, 42, 0), "RightArm": Vector3(-88, 0, 18), "RightForeArm": Vector3(-8, 0, 0), "LeftArm": Vector3(-10, 0, 35)})
	poses.add_animation("slash1", _clip(0.5, false, [[0.0, arms_in, Vector3.ZERO], [0.12, w1, Vector3(0, -6, 0)], [SLASH_HIT, s1, Vector3(0, -8, 6)], [0.5, arms_in, Vector3.ZERO]]))
	var w2 := _merge(stance, {"Spine02": Vector3(0, 40, 0), "RightArm": Vector3(-85, 0, 25), "RightForeArm": Vector3(-95, 0, 0), "LeftArm": Vector3(-10, 0, 30)})
	var s2 := _merge(stance, {"Spine02": Vector3(6, -40, 0), "RightArm": Vector3(-80, 0, -70), "RightForeArm": Vector3(-10, 0, 0), "LeftArm": Vector3(-35, 0, 15)})
	poses.add_animation("slash2", _clip(0.5, false, [[0.0, s1, Vector3(0, -8, 6)], [0.12, w2, Vector3(0, -6, 0)], [SLASH_HIT, s2, Vector3(0, -8, 6)], [0.5, arms_in, Vector3.ZERO]]))
	var w3 := _merge(stance, {"Spine02": Vector3(-12, 0, 0), "RightArm": Vector3(-175, 0, -8), "RightForeArm": Vector3(-70, 0, 0), "LeftArm": Vector3(-150, 0, 10), "LeftForeArm": Vector3(-60, 0, 0)})
	var s3 := _merge(stance, {"Spine02": Vector3(30, 0, 0), "RightArm": Vector3(-55, 0, -5), "RightForeArm": Vector3(-5, 0, 0), "LeftArm": Vector3(-50, 0, 5), "LeftForeArm": Vector3(-20, 0, 0)})
	poses.add_animation("slash3", _clip(0.62, false, [[0.0, arms_in, Vector3.ZERO], [0.16, w3, Vector3(0, -2, -4)], [SLASH_HIT + 0.05, s3, Vector3(0, -16, 10)], [0.62, arms_in, Vector3.ZERO]]))
	# V29 : assis sur le banc de la barque, main droite sur la barre.
	var seated := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0),
		"LeftFoot": Vector3(-5, 0, 0), "RightFoot": Vector3(-5, 0, 0), "Spine02": Vector3(4, 0, 0),
		"RightArm": Vector3(-30, 0, -20), "RightForeArm": Vector3(-45, 0, 0), "LeftArm": Vector3(-35, 0, 12), "LeftForeArm": Vector3(-50, 0, 0)}
	var seated_b := seated.duplicate()
	seated_b["Head"] = Vector3(-4, 8, 0)
	seated_b["Spine02"] = Vector3(6, 3, 0)
	poses.add_animation("sit", _clip(4.0, true, [[0.0, seated, Vector3(0, -38, 0)], [2.0, seated_b, Vector3(0, -38, 0)], [4.0, seated, Vector3(0, -38, 0)]]))
	anim.add_animation_library("v28", poses)


func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = b[k]
	return out


## Rotation locale d'un os : « rot » est donnée dans le repère du personnage au repos
## (X vers sa gauche, Y vers le haut, Z vers l'avant), autour de l'articulation.
func _local_rotation(bone: int, rot_deg: Vector3) -> Quaternion:
	var rest: Quaternion = skel.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion()
	if rot_deg == Vector3.ZERO:
		return rest
	var parent: int = skel.get_bone_parent(bone)
	var gp := Quaternion.IDENTITY
	if parent >= 0:
		gp = skel.get_bone_global_rest(parent).basis.orthonormalized().get_rotation_quaternion()
	var r := Quaternion.from_euler(rot_deg * (PI / 180.0))
	return (gp.inverse() * r * gp * rest).normalized()


## keys : [[instant, {os: rotation en degrés}, décalage du bassin (cm)], ...]
func _clip(length: float, loop: bool, keys: Array) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var base: String = str(anim.get_node(anim.root_node).get_path_to(skel)) + ":"
	for bone_name in BONES:
		var b: int = skel.find_bone(bone_name)
		if b < 0:
			continue
		var t: int = a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, NodePath(base + bone_name))
		for key in keys:
			var pose: Dictionary = key[1]
			a.rotation_track_insert_key(t, float(key[0]), _local_rotation(b, pose.get(bone_name, Vector3.ZERO)))
	var hips: int = skel.find_bone("Hips")
	var pt: int = a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pt, NodePath(base + "Hips"))
	for key in keys:
		a.position_track_insert_key(pt, float(key[0]), skel.get_bone_rest(hips).origin + Vector3(key[2]))
	return a


## Le clip de chute part en arrière de plusieurs mètres : on le ramène sur place.
func _pin_root(a: Animation) -> void:
	for t in a.get_track_count():
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and str(a.track_get_path(t)).ends_with(":Hips"):
			var first: Vector3 = a.track_get_key_value(t, 0)
			for k in a.track_get_key_count(t):
				var v: Vector3 = a.track_get_key_value(t, k)
				a.track_set_key_value(t, k, Vector3(v.x - first.x, v.y, v.z - first.z))


func _play(name: String, blend: float = 0.18, speed: float = 1.0, from: float = -1.0) -> void:
	if anim == null:
		return
	if name != current_anim or from >= 0.0:
		anim.play(name, blend, speed)
		if from >= 0.0:
			anim.seek(from, true)
		current_anim = name
	else:
		anim.play(name, blend, speed)


# =================================================================== entrées

func _unhandled_input(event: InputEvent) -> void:
	if not _can_act():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				jump_buffer = JUMP_BUFFER
				if state == "escalade":
					_climb_leap()
			KEY_CTRL:
				if state == "escalade":
					_let_go()
				else:
					_start_roll()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_distance = clampf(cam_distance - 0.1, 0.45, 1.6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_distance = clampf(cam_distance + 0.1, 0.45, 1.6)


func _can_act() -> bool:
	if main == null or not main.game_started or main.xr_active:
		return false
	if main.game_menu != null and main.game_menu.opened:
		return false
	if main.inventory_v28 != null and main.inventory_v28.opened:
		return false
	if main.dialogue_v31 != null and main.dialogue_v31.opened:
		return false
	return true


func _axis() -> Vector2:
	var axis := Vector2.ZERO
	if not _can_act():
		return axis
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		axis.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		axis.y += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis.x += 1.0
	return axis.normalized() if axis.length() > 0.0 else axis


# =================================================================== boucle

func physics(delta: float) -> void:
	if body == null:
		return
	var axis: Vector2 = _axis()
	var dir: Vector3 = root.global_basis.x * axis.x + root.global_basis.z * axis.y
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
	jump_buffer = maxf(jump_buffer - delta, 0.0)
	hurt_cooldown = maxf(hurt_cooldown - delta, 0.0)
	match state:
		"escalade":
			_climb_tick(delta, axis)
		"hisser":
			_mantle_tick(delta)
		"ko":
			_ko_tick(delta)
		_:
			_ground_tick(delta, dir, axis)
	_regen(delta)
	update_hud()
	_update_visual(delta)
	_update_camera()


func _ground_tick(delta: float, dir: Vector3, axis: Vector2) -> void:
	var on_floor: bool = body.is_on_floor()
	coyote = COYOTE if on_floor else maxf(coyote - delta, 0.0)
	blocking = Input.is_key_pressed(KEY_F) and _can_act() and state in ["sol", "air"] and on_floor
	var sprint: bool = Input.is_key_pressed(KEY_SHIFT) and _can_act() and dir.length() > 0.1 and not stamina_lock and not blocking
	var speed: float = RUN_SPEED if sprint else WALK_SPEED
	var move: Vector3 = dir * speed
	if state == "roulade":
		action_time += delta
		var k: float = 1.0 - smoothstep(0.55, 1.0, action_time / ROLL_TIME)
		move = roll_dir * ROLL_SPEED * k
		if action_time >= ROLL_TIME:
			state = "sol"
	elif state == "attaque":
		move = dir * 0.6
		_attack_tick(delta)
	elif state == "action":
		move = Vector3.ZERO
		action_time += delta
		if action_time >= action_length:
			state = "sol"
	elif blocking:
		move = dir * 1.2
	if sprint and state == "sol" and on_floor:
		_spend(1.6 * delta)
	if dir.length() > 0.1 and state in ["sol", "air"] and not blocking:
		facing = dir
	# Saut (ou rebord à saisir / mur à attraper).
	if jump_buffer > 0.0 and state in ["sol", "air"] and not blocking:
		var aim: Vector3 = facing if dir.length() < 0.1 else dir
		if _try_mantle(body, aim):
			jump_buffer = 0.0
			return
		if coyote > 0.0 and _wall_close(aim) and _try_grab_wall(aim):
			jump_buffer = 0.0
			return
		if coyote > 0.0:
			body.velocity.y = JUMP_SPEED
			coyote = 0.0
			jump_buffer = 0.0
			state = "air"
			fall_top = body.position.y
			_play("v28/jump", 0.1)
		elif _try_grab_wall(dir if dir.length() > 0.1 else facing):
			jump_buffer = 0.0
			return
	# En l'air en avançant vers un rebord à portée de mains : on l'agrippe.
	if state == "air" and dir.length() > 0.1 and body.velocity.y < 2.0:
		if _try_mantle(body, dir):
			return
	main._move_player(root, move * delta)
	on_floor = body.is_on_floor()
	air_time = 0.0 if on_floor else air_time + delta
	# Coincé sur une pente trop raide sans vraiment tomber : on considère qu'on a pied.
	if not on_floor and air_time > 0.35 and absf(body.velocity.y) < 0.4 and body.get_slide_collision_count() > 0:
		on_floor = true
		coyote = COYOTE
	if not on_floor:
		fall_top = maxf(fall_top, body.position.y)
		if state == "sol":
			state = "air"
	elif state == "air":
		_landed()
	if on_floor and state == "sol":
		fall_top = body.position.y
	_pick_locomotion(move, on_floor)


func _pick_locomotion(move: Vector3, on_floor: bool) -> void:
	if state == "air":
		if body.velocity.y < -1.0 and current_anim != "v28/fall" and (current_anim != "v28/jump" or not anim.is_playing()):
			_play("v28/fall", 0.25)
		return
	if state != "sol":
		return
	if not on_floor:
		return
	if blocking:
		_play("v28/block", 0.12)
		return
	var v: float = Vector2(move.x, move.z).length()
	if v > 2.2:
		_play("Running", 0.2, v / 2.6)
	elif v > 0.3:
		_play("Walking", 0.2, maxf(v / 1.0, 0.8))
	elif current_anim != "v28/land" or not anim.is_playing():
		_play("v28/idle", 0.25)


func _landed() -> void:
	state = "sol"
	var drop: float = fall_top - body.position.y
	fall_top = body.position.y
	if drop > SAFE_FALL:
		# En demi-cœurs : 8 m = 2, 11 m = 4 (deux cœurs), 20 m = 8.
		var dmg: int = 1 + int((drop - SAFE_FALL) / 2.0)
		hurt(dmg, Vector3.ZERO)
		if hp <= 0:
			return
	if drop > 0.6:
		_play("v28/land", 0.06)


# =================================================================== rebords et escalade

## Cherche un rebord devant « forward » : renvoie {top, wall_normal} ou {} si rien.
func find_ledge(b: CharacterBody3D, forward: Vector3, reach_max: float = LEDGE_MAX) -> Dictionary:
	forward.y = 0.0
	if forward.length() < 0.01:
		return {}
	forward = forward.normalized()
	var space := b.get_world_3d().direct_space_state
	var feet: Vector3 = b.global_position
	var exclude := [b.get_rid()]
	# Un mur juste devant, à hauteur des genoux ou de la taille.
	var wall := {}
	for h in [0.2, 0.55, 1.0, 1.5]:
		var q := PhysicsRayQueryParameters3D.create(feet + Vector3.UP * h, feet + Vector3.UP * h + forward * 0.85, b.collision_mask, exclude)
		wall = space.intersect_ray(q)
		if not wall.is_empty() and absf(wall.normal.y) < 0.6:
			break
		wall = {}
	if wall.is_empty():
		return {}
	var n: Vector3 = Vector3(wall.normal.x, 0, wall.normal.z).normalized()
	# On tâte le dessus de plus en plus loin de l'arête (les bords de rocher sont arrondis).
	for depth in [0.3, 0.6, 0.9, 1.2]:
		var probe_xz: Vector3 = Vector3(wall.position.x, feet.y, wall.position.z) - n * float(depth)
		var down := PhysicsRayQueryParameters3D.create(probe_xz + Vector3.UP * (reach_max + 0.35), probe_xz + Vector3.UP * (LEDGE_MIN - 0.1), b.collision_mask, exclude)
		var top := space.intersect_ray(down)
		if top.is_empty() or top.normal.y < 0.72:
			continue
		var rise: float = top.position.y - feet.y
		if rise < LEDGE_MIN or rise > reach_max:
			continue
		var target: Vector3 = Vector3(wall.position.x, top.position.y + 0.04, wall.position.z) - n * (float(depth) + 0.15)
		if not _capsule_free(b, target) or not _capsule_free(b, Vector3(feet.x, top.position.y + 0.06, feet.z)):
			continue
		return {"top": target, "normal": n}
	return {}


func _capsule_free(b: CharacterBody3D, at: Vector3) -> bool:
	var shape_node: CollisionShape3D = b.get_node_or_null("Capsule_joueur")
	if shape_node == null:
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape_node.shape
	q.collision_mask = b.collision_mask
	q.exclude = [b.get_rid()]
	q.margin = 0.02
	q.transform = Transform3D(Basis.IDENTITY, at) * shape_node.transform
	return b.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _try_mantle(b: CharacterBody3D, forward: Vector3) -> bool:
	var ledge: Dictionary = find_ledge(b, forward)
	if ledge.is_empty():
		return false
	_start_mantle(ledge)
	return true


func _start_mantle(ledge: Dictionary) -> void:
	state = "hisser"
	action_time = 0.0
	wall_normal = ledge["normal"]
	facing = -wall_normal
	mantle_from = body.global_position
	mantle_to = ledge["top"]
	mantle_mid = Vector3(mantle_from.x, mantle_to.y + 0.02, mantle_from.z)
	body.velocity = Vector3.ZERO
	_play("v28/mantle", 0.08)


func _mantle_tick(delta: float) -> void:
	action_time += delta
	var u: float = clampf(action_time / 0.85, 0.0, 1.0)
	var p: Vector3
	if u < 0.6:
		p = mantle_from.lerp(mantle_mid, smoothstep(0.0, 1.0, u / 0.6))
	else:
		p = mantle_mid.lerp(mantle_to, smoothstep(0.0, 1.0, (u - 0.6) / 0.4))
	body.global_position = p
	body.velocity = Vector3.ZERO
	root.position = body.position
	if u >= 1.0:
		state = "sol"
		fall_top = body.position.y
		main._move_player(root, Vector3.ZERO)


## Surface d'escalade : pente raide, et pas un tronc ou un tonneau (cylindres).
func _climbable(hit: Dictionary) -> bool:
	# V29 : tout ce qui est trop raide pour marcher (plus de 45°) s'escalade.
	if hit.is_empty() or absf(hit.normal.y) > 0.7:
		return false
	var col: Object = hit.collider
	if col is CollisionObject3D:
		var owner_id: int = (col as CollisionObject3D).shape_find_owner(int(hit.shape))
		if owner_id >= 0 and (col as CollisionObject3D).shape_owner_get_shape_count(owner_id) > 0:
			if (col as CollisionObject3D).shape_owner_get_shape(owner_id, 0) is CylinderShape3D:
				return false
	return true


func _wall_ray(from_h: float, dir: Vector3, length: float = 0.9) -> Dictionary:
	var space := body.get_world_3d().direct_space_state
	var o: Vector3 = body.global_position + Vector3.UP * from_h
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + dir * length, body.collision_mask, [body.get_rid()]))


func _wall_close(forward: Vector3) -> bool:
	forward.y = 0.0
	if forward.length() < 0.01:
		return false
	var hit: Dictionary = _wall_ray(1.2, forward.normalized(), 1.3)
	return _climbable(hit)


func _try_grab_wall(forward: Vector3) -> bool:
	if stamina_lock or stamina <= 0.5:
		return false
	forward.y = 0.0
	if forward.length() < 0.01:
		return false
	var hit: Dictionary = _wall_ray(1.2, forward.normalized(), 1.35)
	if not _climbable(hit):
		return false
	wall_normal = Vector3(hit.normal.x, 0, hit.normal.z).normalized()
	state = "escalade"
	climb_time = 0.0
	facing = -wall_normal
	body.velocity = Vector3.ZERO
	_play("v28/climb", 0.15, 0.0)
	return true


func _climb_tick(delta: float, axis: Vector2) -> void:
	body.velocity = Vector3.ZERO
	var chest: Dictionary = _wall_ray(1.25, -wall_normal, 1.5)
	var up_along: Vector3 = Vector3.UP
	if not chest.is_empty() and absf(chest.normal.y) < 0.75:
		# Orientation d'ensemble du mur (trois contacts), lissée : les reliefs en grille
		# ont de petites faces en escalier dont la normale saute d'un carreau à l'autre.
		var n3: Vector3 = _sample_wall_normal(chest)
		var flat_n := Vector3(n3.x, 0, n3.z).normalized()
		if flat_n.dot(wall_normal) > 0.3:
			wall_normal = wall_normal.lerp(flat_n, 0.25).normalized()
		up_along = (Vector3.UP - n3 * n3.dot(Vector3.UP)).normalized()
	elif chest.is_empty():
		# Plus de mur à hauteur de poitrine : on est en haut, on se hisse.
		var ledge: Dictionary = find_ledge(body, -wall_normal, 1.6)
		if ledge.is_empty():
			ledge = _ledge_from_climb()
		if not ledge.is_empty():
			_start_mantle(ledge)
			return
		if _wall_ray(0.5, -wall_normal, 1.0).is_empty() and _wall_ray(0.1, -wall_normal, 1.0).is_empty():
			_let_go()
			return
	var right: Vector3 = (-wall_normal).cross(Vector3.UP).normalized()
	var move: Vector3 = (up_along * -axis.y + right * axis.x) * CLIMB_SPEED * delta
	# Rester collé au mur à distance constante.
	if not chest.is_empty():
		var gap: float = Vector2(chest.position.x - body.global_position.x, chest.position.z - body.global_position.z).length()
		move += -wall_normal * clampf(gap - 0.42, -0.05, 0.05) * minf(delta * 90.0, 1.0)
	body.velocity = move / maxf(delta, 0.001)
	body.move_and_slide()
	body.velocity = Vector3.ZERO
	root.position = body.position
	climb_time += delta
	# Arrivé sur un replat où l'on tient debout (vire, sommet en pente douce) : on lâche le mur.
	if climb_time > 0.4 and body.is_on_floor():
		state = "sol"
		fall_top = body.position.y
		return
	var moving: bool = axis.length() > 0.1
	_spend((0.85 if moving else 0.3) * delta)
	_play("v28/climb", 0.15, 1.2 if moving else 0.0)
	if stamina <= 0.0:
		_let_go()
		return
	# Redescendu jusqu'au sol.
	if axis.y > 0.1:
		var space := body.get_world_3d().direct_space_state
		var feet: Vector3 = body.global_position
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(feet + Vector3.UP * 0.1, feet - Vector3.UP * 0.12, body.collision_mask, [body.get_rid()]))
		if not floor_hit.is_empty() and floor_hit.normal.y > 0.7:
			state = "sol"
			fall_top = body.position.y


func _sample_wall_normal(center_hit: Dictionary) -> Vector3:
	var right: Vector3 = (-wall_normal).cross(Vector3.UP).normalized()
	var space := body.get_world_3d().direct_space_state
	var pts: Array = []
	for off in [[-0.35, 1.0], [0.35, 1.0], [0.0, 1.75]]:
		var o: Vector3 = body.global_position + right * float(off[0]) + Vector3.UP * float(off[1])
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o - wall_normal * 1.8, body.collision_mask, [body.get_rid()]))
		if hit.is_empty():
			return center_hit.normal
		pts.append(hit.position)
	var n: Vector3 = (pts[1] - pts[0]).cross(pts[2] - pts[0])
	if n.length() < 0.0001:
		return center_hit.normal
	n = n.normalized()
	if n.dot(wall_normal) < 0.0:
		n = -n
	return n


## Pendant l'escalade : un replat où poser les pieds, juste au-dessus et devant.
func _ledge_from_climb() -> Dictionary:
	var space := body.get_world_3d().direct_space_state
	var feet: Vector3 = body.global_position
	for i in range(8):
		var depth: float = 0.45 + i * 0.25
		var q: Vector3 = feet - wall_normal * depth
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3.UP * 2.1, q - Vector3.UP * 0.6, body.collision_mask, [body.get_rid()]))
		if hit.is_empty() or hit.normal.y < 0.72:
			continue
		var target: Vector3 = hit.position + Vector3.UP * 0.04 - wall_normal * 0.15
		if _capsule_free(body, target) and _capsule_free(body, Vector3(feet.x, hit.position.y + 0.06, feet.z)):
			return {"top": target, "normal": wall_normal}
	return {}


func _climb_leap() -> void:
	if stamina < 2.0:
		return
	_spend(2.0)
	body.move_and_collide(Vector3.UP * 0.8)
	root.position = body.position


func _let_go() -> void:
	state = "air"
	fall_top = body.position.y
	body.velocity = wall_normal * 2.0
	_play("v28/fall", 0.2)


# =================================================================== roulade et combat

func _start_roll() -> void:
	if state != "sol" or not body.is_on_floor() or stamina_lock or stamina < 1.0:
		return
	_spend(1.5)
	state = "roulade"
	action_time = 0.0
	var axis: Vector2 = _axis()
	var dir: Vector3 = root.global_basis.x * axis.x + root.global_basis.z * axis.y
	dir.y = 0.0
	roll_dir = dir.normalized() if dir.length() > 0.1 else facing
	facing = roll_dir
	_play("v28/roll", 0.05)


func attack() -> void:
	if state == "attaque":
		combo_queued = true
		return
	if state != "sol" or blocking:
		return
	combo_index = 0
	_start_attack_step()


func _start_attack_step() -> void:
	state = "attaque"
	combo_queued = false
	attack_clock = 0.0
	_face_nearest_target()
	if weapon != "":
		var name: String = SLASHES[combo_index % SLASHES.size()]
		action_length = anim.get_animation(name).length
		hits_pending = [SLASH_HIT + (0.05 if combo_index % 3 == 2 else 0.0)]
		_play(name, 0.06, 1.0, 0.0)
	else:
		var seg: Array = PUNCH_SEGMENTS[combo_index % PUNCH_SEGMENTS.size()]
		action_length = (float(seg[1]) - float(seg[0])) / PUNCH_SPEED
		hits_pending = []
		for h in seg[2]:
			hits_pending.append((float(h) - float(seg[0])) / PUNCH_SPEED)
		_play("Punch_Combo_5", 0.08 if combo_index == 0 else 0.0, PUNCH_SPEED, float(seg[0]))


func _attack_tick(delta: float) -> void:
	attack_clock += delta
	while hits_pending.size() > 0 and attack_clock >= float(hits_pending[0]):
		hits_pending.pop_front()
		_deliver_hit()
	var steps: int = SLASHES.size() if weapon != "" else PUNCH_SEGMENTS.size()
	# Enchaîner : on peut relancer dès la fin du coup.
	if combo_queued and hits_pending.is_empty() and attack_clock >= action_length * 0.75 and combo_index + 1 < steps:
		combo_index += 1
		_start_attack_step()
		return
	if attack_clock >= action_length:
		state = "sol"
		combo_index = 0


func _deliver_hit() -> void:
	if not strike.is_valid():
		return
	var reach: float = 1.9 if weapon != "" else 1.35
	strike.call(body.global_position + Vector3.UP * 1.1, facing, reach, weapon_damage if weapon != "" else 1)


func _face_nearest_target() -> void:
	var best: Node3D = null
	var best_d: float = 2.8
	for t in get_tree().get_nodes_in_group("cibles_v28"):
		var n3: Node3D = t as Node3D
		var off: Vector3 = n3.global_position - body.global_position
		off.y = 0.0
		var d: float = off.length()
		if d < best_d and (facing.dot(off.normalized()) > 0.2 or d < 1.2):
			best_d = d
			best = n3
	if best != null:
		var off2: Vector3 = best.global_position - body.global_position
		off2.y = 0.0
		if off2.length() > 0.05:
			facing = off2.normalized()


## Arme tenue en main (identifiant d'objet, dégâts, maillage à afficher).
func equip(item_id: String, damage: int, model: Node3D) -> void:
	weapon = item_id
	weapon_damage = damage
	if sword_holder != null:
		sword_holder.queue_free()
		sword_holder = null
	if item_id == "" or model == null or skel == null:
		return
	var att := BoneAttachment3D.new()
	att.name = "Arme_main_v28"
	att.bone_name = "RightHand"
	skel.add_child(att)
	# Os de la main : Y vers les doigts. La poignée traverse le poing, la lame part vers l'avant.
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	hold.rotation_degrees = Vector3(90, 0, 0)
	hold.scale = Vector3.ONE * 100.0      # le squelette est en centimètres
	att.add_child(hold)
	hold.add_child(model)
	sword_holder = att


# =================================================================== actions simples

func play_action(name: String, look_at_point: Variant = null) -> void:
	if state != "sol" or anim == null:
		return
	if look_at_point is Vector3:
		var off: Vector3 = (look_at_point as Vector3) - body.global_position
		off.y = 0.0
		if off.length() > 0.05:
			facing = off.normalized()
	state = "action"
	action_time = 0.0
	action_length = anim.get_animation("v28/" + name).length
	_play("v28/" + name, 0.1, 1.0, 0.0)


# =================================================================== bateau (V29)

## Le héros assis dans la barque : il suit le banc (tangage et roulis compris).
func ride(seat: Transform3D) -> void:
	state = "bateau"
	if current_anim != "v28/sit":
		_play("v28/sit", 0.25)
	if hero != null:
		hero.global_transform = Transform3D(seat.basis * Basis(Vector3.UP, PI), seat.origin - seat.basis.y * 0.37)
	facing = -seat.basis.z
	facing.y = 0.0
	facing = facing.normalized()
	update_hud()
	_update_camera()


func leave_ride() -> void:
	state = "sol"
	if hero != null:
		hero.rotation = Vector3(0, hero.rotation.y, 0)
	_play("v28/idle", 0.2)


# =================================================================== vie et endurance

func _spend(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	if stamina <= 0.0:
		stamina_lock = true


func _regen(delta: float) -> void:
	var resting: bool = state in ["sol", "action"] and body.is_on_floor() and not (Input.is_key_pressed(KEY_SHIFT) and _axis().length() > 0.1)
	if resting:
		stamina = minf(stamina + 2.6 * delta, STAMINA_MAX)
	if stamina_lock and stamina >= STAMINA_MAX * 0.35:
		stamina_lock = false


func heal(amount: int) -> bool:
	if hp >= HP_MAX:
		return false
	hp = mini(hp + amount, HP_MAX)
	health_changed.emit(hp, HP_MAX)
	return true


func hurt(amount: int, from_pos: Vector3) -> void:
	if state == "ko" or hurt_cooldown > 0.0:
		return
	if blocking and from_pos != Vector3.ZERO and facing.dot((from_pos - body.global_position).normalized()) > 0.3:
		amount = int(amount * 0.5)
		_spend(1.5)
	hurt_cooldown = 0.6
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, HP_MAX)
	if hp <= 0:
		state = "ko"
		ko_time = 0.0
		_play("Knock_Down", 0.1)
	elif state in ["sol", "attaque"]:
		state = "action"
		action_time = 0.0
		action_length = 0.4
		_play("v28/hurt", 0.05, 1.0, 0.0)


func _ko_tick(delta: float) -> void:
	ko_time += delta
	main._move_player(root, Vector3.ZERO)
	if ko_time > 3.0:
		hp = HP_MAX
		stamina = STAMINA_MAX
		state = "sol"
		health_changed.emit(hp, HP_MAX)
		fainted.emit()


func set_health(value: int) -> void:
	hp = clampi(value, 1, HP_MAX)
	health_changed.emit(hp, HP_MAX)


# =================================================================== affichage

var _hearts: Array = []
var _ring: Control
var _hud_box: Control


## Cœurs en haut à droite, roue d'endurance à côté du personnage (seulement quand elle baisse).
func make_hud(hud: CanvasLayer) -> void:
	var box := HBoxContainer.new()
	box.name = "Coeurs_v28"
	box.add_theme_constant_override("separation", 2)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -20.0 - HEARTS * 42.0
	box.offset_right = -20.0
	box.offset_top = 16.0
	box.offset_bottom = 56.0
	hud.add_child(box)
	for i in range(HEARTS):
		var heart := TextureRect.new()
		heart.custom_minimum_size = Vector2(40, 40)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(heart)
		_hearts.append(heart)
	_hud_box = box
	_ring = Control.new()
	_ring.name = "Endurance_v28"
	_ring.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ring.offset_left = 90.0
	_ring.offset_top = -110.0
	_ring.offset_right = 150.0
	_ring.offset_bottom = -50.0
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	hud.add_child(_ring)
	health_changed.connect(func(_a: int, _b: int): _refresh_hearts())
	_refresh_hearts()


func _refresh_hearts() -> void:
	var full: Texture2D = load("res://assets/textures/items/coeur_plein.png") if ResourceLoader.exists("res://assets/textures/items/coeur_plein.png") else null
	var half: Texture2D = load("res://assets/textures/items/coeur_moitie.png") if ResourceLoader.exists("res://assets/textures/items/coeur_moitie.png") else null
	var empty: Texture2D = load("res://assets/textures/items/coeur_vide.png") if ResourceLoader.exists("res://assets/textures/items/coeur_vide.png") else null
	for i in range(_hearts.size()):
		var left: int = hp - i * 2
		(_hearts[i] as TextureRect).texture = full if left >= 2 else (half if left == 1 else empty)


func _draw_ring() -> void:
	if stamina >= STAMINA_MAX - 0.01:
		return
	var c := Vector2(30, 30)
	var ratio: float = stamina / STAMINA_MAX
	_ring.draw_arc(c, 22.0, 0.0, TAU, 48, Color(0, 0, 0, 0.45), 9.0, true)
	var col := Color(0.95, 0.35, 0.25) if stamina_lock else Color(0.45, 0.95, 0.45)
	_ring.draw_arc(c, 22.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, col, 7.0, true)


func update_hud() -> void:
	var show: bool = main != null and main.game_started and not main.xr_active
	if _hud_box != null:
		_hud_box.visible = show
	if _ring != null:
		_ring.visible = show
		_ring.queue_redraw()

func _update_visual(delta: float) -> void:
	if hero == null:
		return
	hero.position = root.position + Vector3.UP * main.hero_mesh_floor_offset_v11
	var target_yaw: float = atan2(facing.x, facing.z)
	var k: float = 1.0 if state in ["escalade", "hisser"] else clampf(delta * 14.0, 0.0, 1.0)
	hero.rotation.y = lerp_angle(hero.rotation.y, target_yaw, k)


## Caméra à l'épaule qui ne traverse plus les murs (intérieurs des maisons).
func _update_camera() -> void:
	if camera == null or not camera.current:
		return
	var pivot: Vector3 = root.global_position + Vector3.UP * 1.5
	var wanted: Vector3 = root.global_transform * (Vector3(0, 2.5, 5.0) * cam_distance + Vector3(0, 1.5 * (1.0 - cam_distance), 0))
	# V31 : pendant un dialogue, plan de côté qui montre les deux personnages.
	var npc: Node3D = main.talking_npc_v31 if main.get("talking_npc_v31") != null else null
	if npc != null:
		var to_npc: Vector3 = npc.global_position - root.global_position
		to_npc.y = 0.0
		var dist: float = maxf(to_npc.length(), 0.5)
		var fwd: Vector3 = to_npc / dist
		var side: Vector3 = fwd.cross(Vector3.UP)
		var mid: Vector3 = root.global_position + to_npc * 0.5 + Vector3.UP * 1.45
		pivot = mid
		wanted = mid + side * (2.6 + dist * 0.4) - fwd * 1.2 + Vector3.UP * 0.35
	var space := body.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pivot, wanted, 1, [body.get_rid()])
	var hit := space.intersect_ray(q)
	var place: Vector3 = wanted
	if not hit.is_empty():
		place = hit.position + (pivot - hit.position).normalized() * 0.25
	camera.global_position = place
	var look: Vector3 = root.global_position + Vector3.UP * 1.2
	if npc != null:
		# La fenêtre de dialogue couvre le bas de l'écran : on vise un peu plus bas.
		look = pivot + Vector3.DOWN * 0.55
	if place.distance_to(look) > 0.1:
		camera.look_at(look, Vector3.UP)

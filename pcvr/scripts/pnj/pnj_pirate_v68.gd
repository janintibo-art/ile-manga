extends "res://scripts/pnj/pnj_arcanelle_v67.gd"
## V68 : un pirate (ou un habitant) de Port-Coutelas, sur l'Île de la Balafre. Même vie réglée
## par l'heure que les autres habitants (pnj_azur_v56.gd et la suite), avec :
##  - le cerveau des pirates (pnj_brain_pirate_v68.gd) : la tension qui monte au moindre mot de
##    travers, les dés, les tournées, les duels ;
##  - des postures : jouer_des (penché sur un tonneau, le cornet qui secoue, le lancer, puis la
##    tête qui se secoue… ou le poing levé), croupier (les deux mains sur le tapis, le râteau des
##    mises, l'œil sur la salle), violon (Tom au Crâne Fendu), forger (Brutus à l'enclume, le
##    marteau qui monte et qui tombe, les étincelles) ;
##  - la BAGARRE (menée par bagarre_v68.gd) : la garde, les poings levés, les coups (les mêmes que
##    ceux du héros : Punch_Combo_5), la parade, les coups encaissés, le K.-O. (étendu par terre,
##    des étoiles qui tournent au-dessus de la tête, quarante secondes), puis il se relève, se
##    frotte la mâchoire, et reprend sa journée — en s'en souvenant ;
##  - les spectateurs : ceux qui ne se battent pas regardent et acclament ;
##  - des accessoires : la jambe de bois de Lestrange, le crochet de Crochet, la chope de ceux
##    qui boivent, le violon de Tom, le marteau de Brutus.

const PirateBrain = preload("res://scripts/pnj/pnj_brain_pirate_v68.gd")
const PUNCH_SEGS := [[0.30, 1.12, [0.92]], [1.12, 1.58, [1.40]], [1.58, 1.93, [1.80]], [1.93, 3.05, [2.06, 2.60]]]
const PUNCH_SPEED: float = 1.2
const REACH: float = 1.12            # distance de frappe (m, entre les deux centres)
const WAIT_DIST: float = 2.7         # ceux qui attendent leur tour tournent autour, à distance
const FIGHT_RUN: float = 3.0
const KO_TIME: float = 40.0
const LEASH: float = 30.0            # on ne poursuit pas le joueur plus loin que ça

var bagarre: Node                    # bagarre_v68.gd, tant qu'il se bat
var fight: Dictionary = {}           # role, target (null = le joueur), hp, hp_max, act, t, cd, hits, seg_end
var ko_left: float = 0.0
var _ko_phase: String = ""           # "tombe", "sol", "releve"
var _stars: Node3D
var _mug: Node3D
var _violin: Node3D
var _bow: Node3D
var _hammer: Node3D
var _sparks: CPUParticles3D
var _forge_hit: float = -1.0
var _watch_center: Vector3 = Vector3.INF
var _watch_t: float = 0.0
var _path: Array = []
var _path_t: float = 0.0
var _knock: Vector3 = Vector3.ZERO
var _strafe: float = 1.0
var _strafe_t: float = 0.0
var _rngp := RandomNumberGenerator.new()
var _menace_t: float = 0.0             # fâché, et le joueur reste sous son nez : ça va mal finir
var _watch_walk: bool = false          # il marchait quand la bagarre l'a arrêté


func setup(main_node: Node, profile_data: Dictionary, spots: Dictionary, graph: Dictionary, start: String) -> void:
	super.setup(main_node, profile_data, spots, graph, start)
	# le cerveau des pirates (la tension, les dés, les bagarres)
	brain = PirateBrain.new()
	brain.setup(profile)
	_rngp.seed = hash(str(profile.get("id", "p")) + "68")


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_pir_poses()
	_pir_accessories(data)


# =================================================================== postures

func _build_pir_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("pir"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	if anim.has_animation("Knock_Down"):
		lib._pin_root(anim.get_animation("Knock_Down"))
	for clip in ["Motivational_Cheer"]:
		var ac: Animation = anim.get_animation(clip)
		if ac != null:
			ac.loop_mode = Animation.LOOP_LINEAR
	var poses := AnimationLibrary.new()
	# la garde : genoux pliés, pied gauche devant, les poings à hauteur du menton, qui sautille
	var g_a := {"LeftUpLeg": Vector3(-26, 0, -4), "LeftLeg": Vector3(26, 0, 0), "RightUpLeg": Vector3(6, 0, 6), "RightLeg": Vector3(24, 0, 0),
		"Spine02": Vector3(8, -10, 0), "Spine01": Vector3(4, 0, 0), "Head": Vector3(6, 10, 0),
		"RightArm": Vector3(-46, 0, 24), "RightForeArm": Vector3(-132, 0, 0), "LeftArm": Vector3(-58, 0, -20), "LeftForeArm": Vector3(-124, 0, 0)}
	var g_b := lib._merge(g_a, {"LeftUpLeg": Vector3(-30, 0, -4), "LeftLeg": Vector3(32, 0, 0), "RightLeg": Vector3(30, 0, 0),
		"RightArm": Vector3(-50, 0, 22), "LeftArm": Vector3(-62, 0, -18), "Head": Vector3(8, 6, 0)})
	poses.add_animation("garde", lib._clip(0.9, true, [[0.0, g_a, Vector3(0, -5, 0)], [0.45, g_b, Vector3(0, -8, 0)], [0.9, g_a, Vector3(0, -5, 0)]]))
	# les dés : penché sur le tonneau, le cornet qui secoue, le lancer, on regarde… on peste, puis
	# on relance, et cette fois le poing se lève
	var d0 := {"Spine02": Vector3(14, 0, 0), "Spine01": Vector3(6, 0, 0), "Head": Vector3(16, 0, 0), "LeftArm": Vector3(-36, 0, -10), "LeftForeArm": Vector3(-52, 0, 0),
		"LeftUpLeg": Vector3(-4, 0, 0), "LeftLeg": Vector3(6, 0, 0), "RightUpLeg": Vector3(-4, 0, 0), "RightLeg": Vector3(6, 0, 0)}
	var sh_a := lib._merge(d0, {"RightArm": Vector3(-42, 0, 22), "RightForeArm": Vector3(-112, 0, 0)})
	var sh_b := lib._merge(d0, {"RightArm": Vector3(-48, 0, 20), "RightForeArm": Vector3(-92, 0, 0)})
	var thr := lib._merge(d0, {"RightArm": Vector3(-72, 0, 8), "RightForeArm": Vector3(-14, 0, 0), "Spine02": Vector3(22, 0, 0)})
	var look := lib._merge(d0, {"RightArm": Vector3(-30, 0, 10), "RightForeArm": Vector3(-46, 0, 0), "Head": Vector3(26, 0, 0), "Spine02": Vector3(18, 0, 0)})
	var no_l := lib._merge(look, {"Head": Vector3(18, -16, 0)})
	var no_r := lib._merge(look, {"Head": Vector3(18, 16, 0)})
	var win := lib._merge(d0, {"RightArm": Vector3(-128, 0, 18), "RightForeArm": Vector3(-64, 0, 0), "Head": Vector3(-8, 0, 0), "Spine02": Vector3(0, 0, 0), "Spine01": Vector3(0, 0, 0)})
	var keys: Array = []
	for half in [0.0, 4.6]:
		var t0: float = half
		for k in range(6):
			keys.append([t0 + k * 0.14, sh_a if k % 2 == 0 else sh_b, Vector3.ZERO])
		keys.append([t0 + 1.1, thr, Vector3.ZERO])
		keys.append([t0 + 1.4, thr, Vector3.ZERO])
		keys.append([t0 + 1.8, look, Vector3.ZERO])
		keys.append([t0 + 2.6, look, Vector3.ZERO])
		if half == 0.0:
			keys.append([t0 + 2.9, no_l, Vector3.ZERO])
			keys.append([t0 + 3.2, no_r, Vector3.ZERO])
			keys.append([t0 + 3.5, no_l, Vector3.ZERO])
			keys.append([t0 + 3.8, look, Vector3.ZERO])
		else:
			keys.append([t0 + 2.9, win, Vector3(0, 2, 0)])
			keys.append([t0 + 3.5, win, Vector3(0, 2, 0)])
			keys.append([t0 + 3.9, d0, Vector3.ZERO])
		keys.append([t0 + 4.4, sh_a, Vector3.ZERO])
	keys.append([9.2, sh_a, Vector3.ZERO])
	poses.add_animation("jouer_des", lib._clip(9.2, true, keys))
	# le croupier : les mains sur le tapis, il ramasse les mises au râteau, surveille la salle
	var c0 := {"Spine02": Vector3(16, 0, 0), "Head": Vector3(10, 0, 0), "LeftArm": Vector3(-52, 0, -12), "LeftForeArm": Vector3(-36, 0, 0),
		"RightArm": Vector3(-52, 0, 12), "RightForeArm": Vector3(-36, 0, 0)}
	var c_l := lib._merge(c0, {"RightArm": Vector3(-60, 0, 34), "RightForeArm": Vector3(-28, 0, 0), "Head": Vector3(14, 12, 0)})
	var c_r := lib._merge(c0, {"RightArm": Vector3(-58, 0, -6), "RightForeArm": Vector3(-24, 0, 0), "Head": Vector3(14, -12, 0)})
	var c_w := lib._merge(c0, {"Head": Vector3(0, 22, 0), "Spine02": Vector3(6, 8, 0)})
	var c_w2 := lib._merge(c0, {"Head": Vector3(0, -22, 0), "Spine02": Vector3(6, -8, 0)})
	poses.add_animation("croupier", lib._clip(9.0, true, [[0.0, c0, Vector3.ZERO], [1.2, c_l, Vector3.ZERO], [2.0, c_r, Vector3.ZERO], [2.8, c_l, Vector3.ZERO],
		[3.6, c0, Vector3.ZERO], [5.0, c_w, Vector3.ZERO], [6.4, c_w, Vector3.ZERO], [7.4, c_w2, Vector3.ZERO], [9.0, c0, Vector3.ZERO]]))
	# le violon : le bras gauche tient le manche, la tête penchée sur la mentonnière, l'archet va
	# et vient ; le corps se balance en mesure
	var v_a := {"LeftArm": Vector3(-74, 0, 26), "LeftForeArm": Vector3(-62, 0, 0), "Head": Vector3(12, 18, 0), "Spine02": Vector3(2, 6, 0),
		"RightArm": Vector3(-52, 0, 30), "RightForeArm": Vector3(-74, 0, 0)}
	var v_b := lib._merge(v_a, {"RightArm": Vector3(-46, 0, 8), "RightForeArm": Vector3(-24, 0, 0), "Spine02": Vector3(2, 2, 0), "Head": Vector3(10, 14, 0)})
	poses.add_animation("violon", lib._clip(1.0, true, [[0.0, v_a, Vector3(-1, 0, 0)], [0.5, v_b, Vector3(1, -1, 0)], [1.0, v_a, Vector3(-1, 0, 0)]]))
	# forger : le marteau monte au-dessus de l'épaule, tombe sur l'enclume (la pince dans l'autre main)
	var f_up := {"Spine02": Vector3(6, 0, 0), "Head": Vector3(16, 0, 0), "RightArm": Vector3(-148, 0, 8), "RightForeArm": Vector3(-46, 0, 0),
		"LeftArm": Vector3(-42, 0, -12), "LeftForeArm": Vector3(-62, 0, 0), "LeftUpLeg": Vector3(-10, 0, 0), "LeftLeg": Vector3(12, 0, 0), "RightUpLeg": Vector3(4, 0, 0), "RightLeg": Vector3(8, 0, 0)}
	var f_hit := lib._merge(f_up, {"RightArm": Vector3(-58, 0, 14), "RightForeArm": Vector3(-28, 0, 0), "Spine02": Vector3(20, 0, 0), "Head": Vector3(22, 0, 0)})
	poses.add_animation("forger", lib._clip(1.4, true, [[0.0, f_up, Vector3.ZERO], [0.4, f_up, Vector3.ZERO], [0.62, f_hit, Vector3(0, -3, 0)], [0.85, f_hit, Vector3(0, -3, 0)], [1.4, f_up, Vector3.ZERO]]))
	# encaisser un coup : la tête part en arrière, le buste recule
	var h_a := {"Head": Vector3(-24, 14, 0), "Spine02": Vector3(-14, 8, 0), "RightArm": Vector3(-30, 0, 30), "RightForeArm": Vector3(-90, 0, 0), "LeftArm": Vector3(-20, 0, -10), "LeftForeArm": Vector3(-40, 0, 0),
		"LeftUpLeg": Vector3(-10, 0, 0), "LeftLeg": Vector3(14, 0, 0)}
	var h_b := lib._merge(g_a, {})
	poses.add_animation("encaisse", lib._clip(0.5, false, [[0.0, h_b, Vector3(0, -5, 0)], [0.12, h_a, Vector3(0, -4, -6)], [0.5, h_b, Vector3(0, -5, 0)]]))
	# parer : les deux avant-bras devant le visage
	var p_a := lib._merge(g_a, {"RightArm": Vector3(-70, 0, 30), "RightForeArm": Vector3(-140, 0, 0), "LeftArm": Vector3(-74, 0, -28), "LeftForeArm": Vector3(-140, 0, 0), "Head": Vector3(16, 0, 0)})
	poses.add_animation("pare", lib._clip(0.5, false, [[0.0, g_a, Vector3(0, -5, 0)], [0.1, p_a, Vector3(0, -7, -3)], [0.4, p_a, Vector3(0, -7, -3)], [0.5, g_a, Vector3(0, -5, 0)]]))
	# se frotter la mâchoire en se relevant
	var j_a := {"RightArm": Vector3(-40, 0, 30), "RightForeArm": Vector3(-140, 0, 0), "Head": Vector3(6, -10, 4), "Spine02": Vector3(6, 0, 0)}
	var j_b := lib._merge(j_a, {"Head": Vector3(6, 6, -4), "RightForeArm": Vector3(-134, 0, 0)})
	poses.add_animation("machoire", lib._clip(2.4, false, [[0.0, j_a, Vector3.ZERO], [0.6, j_b, Vector3.ZERO], [1.2, j_a, Vector3.ZERO], [1.8, j_b, Vector3.ZERO], [2.4, {}, Vector3.ZERO]]))
	anim.add_animation_library("pir", poses)
	lib.free()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	# spectateur d'une bagarre : il regarde et acclame (assis, il reste assis)
	if _watch_t > 0.0:
		_watch_t -= delta
		_show_props("")
		if vr_label != null:
			vr_label.visible = false
		if pose in ["assis", "lire", "guitare", "allonge"]:
			_play("v28/sit", 0.4)
		else:
			if _watch_center != Vector3.INF:
				_face(_watch_center - global_position, delta, 4.0)
			_play("Motivational_Cheer", 0.4, 0.9)
		if _watch_t <= 0.0:
			current_anim = ""
		return
	match pose:
		"jouer_des":
			_show_props("")
			if dist < 2.2:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("pir/jouer_des", 0.5)
		"croupier":
			_show_props("")
			if dist < 2.2:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("pir/croupier", 0.5)
		"violon":
			_show_props("violon")
			_play("pir/violon", 0.4)
		"forger":
			_show_props("marteau")
			if dist < 2.2:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("pir/forger", 0.4)
				_forge_tick()
		"boire":
			_show_props("chope")
			super._activity(delta, dist, to_player)
		_:
			_show_props("")
			super._activity(delta, dist, to_player)


## Les étincelles et le bruit quand le marteau tombe sur l'enclume.
func _forge_tick() -> void:
	if anim == null or anim.current_animation != "pir/forger":
		return
	var t: float = anim.current_animation_position
	if t >= 0.62 and _forge_hit < 0.62:
		if _sparks != null and _hammer != null:
			_sparks.global_position = _hammer.global_transform * Vector3(0, 0.36, 0)
			_sparks.restart()
			_sparks.emitting = true
		if main.has_method("sfx") and global_position.distance_to(main._player_pos_v27()) < 18.0:
			main.sfx("forge", global_position + Vector3.UP)
	_forge_hit = t


func _show_props(which: String) -> void:
	if _mug != null:
		_mug.visible = which == "chope"
	if _violin != null:
		_violin.visible = which == "violon"
	if _bow != null:
		_bow.visible = which == "violon"
	if _hammer != null:
		_hammer.visible = which == "marteau"


func end_talk() -> void:
	super.end_talk()
	if pose in ["jouer_des", "croupier", "violon", "forger"]:
		current_anim = ""


# =================================================================== la tenue

func _pir_accessories(data: Dictionary) -> void:
	if skel == null:
		return
	var nid: String = str(data.get("id", ""))
	var wood := _mat(Color(0.42, 0.28, 0.16), 0.8)
	var dark_wood := _mat(Color(0.26, 0.16, 0.09), 0.75)
	var iron := _mat(Color(0.32, 0.32, 0.34), 0.4)
	iron.metallic = 0.8
	# une chope d'étain (au comptoir)
	_mug = Node3D.new()
	var pewter := _mat(Color(0.62, 0.62, 0.6), 0.35)
	pewter.metallic = 0.7
	_part(_mug, _cyl(0.042, 0.048, 0.13), pewter, Vector3(0, 0.0, 0))
	_part(_mug, _cyl(0.038, 0.038, 0.005), _mat(Color(0.95, 0.92, 0.85), 0.9), Vector3(0, 0.064, 0))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.022
	handle.outer_radius = 0.034
	_part(_mug, handle, pewter, Vector3(0.055, 0.0, 0), Vector3.ONE, Vector3(90, 0, 0))
	_mug.visible = false
	_attach("RightHand", Vector3(0, -8, 5), _mug)
	# Gontran Lestrange : la jambe de bois (un fût de chêne cerclé de fer, du genou au sol)
	if nid == "lestrange":
		var peg := Node3D.new()
		_part(peg, _cyl(0.062, 0.05, 0.3), wood, Vector3(0, -0.14, 0))
		_part(peg, _cyl(0.05, 0.03, 0.2), dark_wood, Vector3(0, -0.38, 0))
		_part(peg, _cyl(0.066, 0.066, 0.025), iron, Vector3(0, -0.02, 0))
		_part(peg, _cyl(0.034, 0.034, 0.02), iron, Vector3(0, -0.47, 0))
		_attach("RightLeg", Vector3(0, -4, 0), peg)
	# Crochet : le crochet de fer à la place de la main gauche
	if nid == "crochet":
		var hk := Node3D.new()
		_part(hk, _cyl(0.05, 0.045, 0.12), _mat(Color(0.3, 0.2, 0.12), 0.7), Vector3(0, 0, 0))
		var tm := TorusMesh.new()
		tm.inner_radius = 0.045
		tm.outer_radius = 0.06
		tm.rings = 14
		_part(hk, _cyl(0.008, 0.008, 0.1), iron, Vector3(0, -0.11, 0))
		_part(hk, tm, iron, Vector3(0.045, -0.17, 0), Vector3(1.0, 1.0, 0.35), Vector3(90, 0, 0))
		_attach("LeftHand", Vector3(0, -2, 0), hk)
	# Tom : le violon (sous le menton) et l'archet
	if nid == "tom":
		_violin = Node3D.new()
		var vm := _mat(Color(0.55, 0.24, 0.08), 0.35)
		_part(_violin, _sphere(0.1), vm, Vector3(0, 0, 0.0), Vector3(0.9, 0.3, 1.0))
		_part(_violin, _sphere(0.08), vm, Vector3(0, 0, 0.13), Vector3(0.85, 0.3, 0.9))
		_part(_violin, _box_mesh_np(Vector3(0.025, 0.02, 0.26)), _mat(Color(0.08, 0.06, 0.05), 0.5), Vector3(0, 0.025, 0.3))
		_part(_violin, _sphere(0.025), dark_wood, Vector3(0, 0.03, 0.44))
		_violin.visible = false
		_attach("Spine02", Vector3(8, 26, 14), _violin, Vector3(0, 40, -30))
		_bow = Node3D.new()
		_part(_bow, _cyl(0.004, 0.006, 0.7), dark_wood, Vector3(0, 0.3, 0))
		_part(_bow, _box_mesh_np(Vector3(0.002, 0.66, 0.01)), _mat(Color(0.92, 0.9, 0.84), 0.6), Vector3(0, 0.3, 0.014))
		_bow.visible = false
		_attach("RightHand", Vector3(0, -7, 3), _bow, Vector3(0, 0, 90))
	# Brutus : le marteau de forge (et les étincelles)
	if nid == "brutus":
		_hammer = Node3D.new()
		_part(_hammer, _cyl(0.016, 0.02, 0.42), wood, Vector3(0, 0.12, 0))
		_part(_hammer, _box_mesh_np(Vector3(0.16, 0.07, 0.07)), iron, Vector3(0, 0.36, 0))
		_hammer.visible = false
		_attach("RightHand", Vector3(0, -8, 3), _hammer, Vector3(90, 0, 0))
		_sparks = CPUParticles3D.new()
		_sparks.emitting = false
		_sparks.one_shot = true
		_sparks.amount = 24
		_sparks.lifetime = 0.6
		_sparks.explosiveness = 0.95
		_sparks.direction = Vector3.UP
		_sparks.spread = 70.0
		_sparks.initial_velocity_min = 1.5
		_sparks.initial_velocity_max = 3.5
		_sparks.gravity = Vector3(0, -9.0, 0)
		_sparks.scale_amount_min = 0.5
		_sparks.scale_amount_max = 1.0
		var sq := QuadMesh.new()
		sq.size = Vector2(0.03, 0.03)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.albedo_color = Color(1.0, 0.7, 0.3)
		sq.material = sm
		_sparks.mesh = sq
		add_child(_sparks)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if ko_left > 0.0 or _ko_phase != "":
		_ko_tick(delta)
		return
	if not fight.is_empty():
		_fight_tick(delta)
		return
	_menace_tick(delta)
	super._process(delta)


## Déjà fâché (tension à mi-chemin), et le joueur reste là, sous son nez, sans rien dire : il
## prévient… puis il cogne. On s'éloigne, ou on lui parle (des excuses, un verre).
func _menace_tick(delta: float) -> void:
	if hidden_home or ko_left > 0.0 or state == "parle" or brain == null or not brain.has_method("tension"):
		_menace_t = 0.0
		return
	if brain.tension() < 0.5 or not brain.can_fight():
		_menace_t = maxf(0.0, _menace_t - delta)
		return
	var dp: float = global_position.distance_to(main._player_pos_v27())
	if dp < 2.3:
		var before: float = _menace_t
		_menace_t += delta
		_face(main._player_pos_v27() - global_position, delta, 4.0)
		if before < 3.0 and _menace_t >= 3.0:
			say_bubble(["Tu cherches les ennuis ?", "Recule. Tout de suite.", "Tu veux ma photo ?", "Encore un pas, et je cogne."][_rngp.randi() % 4], 3.0)
			gesture("colere")
		if _menace_t > 7.0:
			_menace_t = 0.0
			brain.set_tension(1.1)
			say_bubble("Tu l'auras voulu !", 2.5)
			if azur != null and azur.has_method("brawl"):
				azur.brawl(self, "cherche", false)
	else:
		_menace_t = maxf(0.0, _menace_t - delta * 2.0)


func _bubble_tick(delta: float) -> void:
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false


func is_hittable() -> bool:
	return super.is_hittable() and ko_left <= 0.0 and _ko_phase == ""


## Peut-on lui parler ? Pas en pleine bagarre, pas étendu par terre, pas en regardant le spectacle.
func can_talk() -> bool:
	return fight.is_empty() and ko_left <= 0.0 and _ko_phase == "" and not hidden_home and _watch_t <= 0.0


## Le joueur assiste-t-il à quelque chose ? (spectateur d'une bagarre)
func watch(center: Vector3, seconds: float) -> void:
	if hidden_home or not fight.is_empty() or ko_left > 0.0:
		return
	_watch_center = center
	_watch_t = seconds
	if state == "marche":
		route.clear()
		state = "repos"
		idle_clock = 1e9
		_watch_walk = true
	current_anim = ""


func stop_watch() -> void:
	if _watch_t > 0.0:
		_watch_t = 0.0
		current_anim = ""
	if _watch_walk:
		# il allait quelque part : il reprend son chemin
		_watch_walk = false
		at_point = _nearest_point(global_position)
		slot = -3
		_check = 0.0


# =================================================================== la bagarre

## Il entre dans la bagarre. role : "attaquant" (contre le joueur), "allie" (aide le joueur
## contre target), "melee" (contre target, un rival d'un autre équipage).
func start_fight(role: String, target: Node, mgr_fight: Node) -> void:
	bagarre = mgr_fight
	var p: Dictionary = brain.pir()
	var hpmax: int = int(p.get("pv", 6))
	var hp: int = int(fight.get("hp", hpmax)) if not fight.is_empty() else hpmax
	fight = {"role": role, "target": target, "hp": hp, "hp_max": hpmax, "act": "approche", "t": 0.0,
		"cd": _rngp.randf_range(0.5, 1.2), "hits": [], "seg_end": 0.0, "force": int(p.get("force", 1)), "origin": global_position}
	_watch_t = 0.0
	_set_hidden(false)
	_free_spot()
	route.clear()
	state = "bagarre"
	if vr_label != null:
		vr_label.visible = false
	if pose in ["assis", "lire", "guitare", "allonge"]:
		_snap_to_floor()
	pose = "debout"
	_show_props("")
	current_anim = ""
	_path.clear()
	_strafe = 1.0 if _rngp.randf() < 0.5 else -1.0


## La bagarre est finie pour lui (debout) : il reprend le cours de sa journée.
func stop_fight() -> void:
	if fight.is_empty():
		return
	fight = {}
	bagarre = null
	_resume()


func _resume() -> void:
	state = "repos"
	pose = "debout"
	idle_clock = 1e9
	gesture_clock = 0.0
	current_anim = ""
	at_point = _nearest_point(global_position)
	slot = -3
	_check = 0.0
	target_spot = ""


## Le point du graphe le plus proche (que l'on voit sans traverser de mur, si possible).
func _nearest_point(p: Vector3) -> String:
	var best: String = at_point
	var best_d: float = INF
	for k in points:
		var q: Vector3 = points[k]
		var d: float = Vector2(q.x - p.x, q.z - p.z).length() + absf(q.y - p.y) * 2.0
		if d < best_d and (d < 1.5 or _clear(p, q)):
			best_d = d
			best = str(k)
	return best


## Rien entre a et b (à hauteur de poitrine) ? Le joueur et les habitants ne comptent pas.
func _clear(a: Vector3, b: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(a + Vector3.UP * 0.9, b + Vector3.UP * 0.9, 1, _npc_bodies)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.collider is CharacterBody3D


## Après une bagarre : il reprend son agenda depuis le point le plus proche (sans traverser
## les murs : d'abord ce point-là, puis le chemin).
func _start_slot(i: int, teleport: bool) -> void:
	super._start_slot(i, teleport)
	if state == "marche" and points.has(at_point):
		var q: Vector3 = points[at_point]
		if Vector2(q.x - global_position.x, q.z - global_position.z).length() > 0.5:
			route.push_front(at_point)


func _target_pos() -> Vector3:
	var t: Variant = fight.get("target", null)
	if t == null:
		return main._player_pos_v27()
	if is_instance_valid(t):
		return (t as Node3D).global_position
	return Vector3.INF


func _fight_tick(delta: float) -> void:
	brain.tick(delta)
	_bubble_tick(delta)
	gesture_clock = maxf(gesture_clock - delta, 0.0)
	fight["t"] = float(fight["t"]) + delta
	fight["cd"] = float(fight["cd"]) - delta
	var goal: Vector3 = _target_pos()
	var tgt: Variant = fight.get("target", null)
	if goal == Vector3.INF or (tgt != null and is_instance_valid(tgt) and ((tgt.get("fight") as Dictionary).is_empty() or float(tgt.get("ko_left")) > 0.0)):
		# sa cible est au tapis (ou partie) : la bagarre lui en trouve une autre, ou c'est fini
		if bagarre != null and is_instance_valid(bagarre):
			bagarre.retarget(self)
		else:
			stop_fight()
		return
	# il ne poursuit pas le joueur à travers toute l'île : trente mètres autour de là où ça a commencé
	var leashed: bool = false
	if tgt == null and fight.has("origin"):
		var o: Vector3 = fight["origin"]
		var from_o: Vector3 = goal - o
		from_o.y = 0.0
		if from_o.length() > LEASH:
			goal = o + from_o.normalized() * LEASH
			leashed = true
	var to: Vector3 = goal - global_position
	to.y = 0.0
	var d: float = to.length()
	var act: String = str(fight["act"])
	if leashed and d < 1.0:
		_face(_target_pos() - global_position, delta, 5.0)
		_play("pir/garde", 0.3)
		if bubble_clock <= 0.0 and _rngp.randf() < delta * 0.4:
			say_bubble(["Reviens ici, froussard !", "C'est ça, file !", "On n'a pas fini, toi et moi !"][_rngp.randi() % 3], 2.0)
		return
	match act:
		"frappe":
			_face(to, delta, 8.0)
			var hits: Array = fight["hits"]
			while not hits.is_empty() and float(fight["t"]) >= float(hits[0]):
				hits.pop_front()
				_deliver_punch()
			if float(fight["t"]) >= float(fight["seg_end"]):
				_set_act("garde")
				var fast: bool = bool(brain.pir().get("costaud", false))
				fight["cd"] = _rngp.randf_range(0.7, 1.5) if fast else _rngp.randf_range(1.0, 2.1)
		"touche":
			global_position += _knock * delta
			_knock *= maxf(0.0, 1.0 - delta * 6.0)
			_snap_to_floor()
			if float(fight["t"]) > 0.5:
				_set_act("garde")
		"pare":
			_face(to, delta, 8.0)
			if float(fight["t"]) > 0.5:
				_set_act("garde")
		_:
			_face(to, delta, 7.0)
			var may: bool = bagarre == null or not is_instance_valid(bagarre) or bagarre.can_attack(self)
			var player_down: bool = tgt == null and main.hero_v28 != null and str(main.hero_v28.state) == "ko"
			var want: float = REACH if may and not player_down else WAIT_DIST
			if d > want + 0.3:
				_move_toward(goal, delta, FIGHT_RUN if d > 3.2 else 1.6)
				_play("Running" if d > 3.2 else "Walking", 0.2, 1.0 if d > 3.2 else 1.3)
			elif d < want - 0.45:
				_move_dir(-to.normalized(), delta, 1.2)
				_play("pir/garde", 0.2)
			else:
				_strafe_t -= delta
				if _strafe_t <= 0.0:
					_strafe_t = _rngp.randf_range(1.2, 2.6)
					_strafe = -_strafe if _rngp.randf() < 0.5 else _strafe
				if not may:
					_move_dir(Vector3(-to.z, 0, to.x).normalized() * _strafe, delta, 0.7)
				_play("Motivational_Cheer" if player_down else "pir/garde", 0.25)
			if may and not player_down and d <= REACH + 0.25 and float(fight["cd"]) <= 0.0:
				_start_punch()


func _set_act(a: String) -> void:
	fight["act"] = a
	fight["t"] = 0.0


func _start_punch() -> void:
	var seg: Array = PUNCH_SEGS[_rngp.randi() % PUNCH_SEGS.size()]
	var hits: Array = []
	for h in seg[2]:
		hits.append((float(h) - float(seg[0])) / PUNCH_SPEED)
	fight["hits"] = hits
	fight["seg_end"] = (float(seg[1]) - float(seg[0])) / PUNCH_SPEED
	_set_act("frappe")
	_play("Punch_Combo_5", 0.1, PUNCH_SPEED, float(seg[0]))


## Le poing arrive : sur le joueur (s'il est toujours à portée, en face), ou sur l'autre bagarreur.
func _deliver_punch() -> void:
	var tgt: Variant = fight.get("target", null)
	var goal: Vector3 = _target_pos()
	if goal == Vector3.INF:
		return
	var off: Vector3 = goal - global_position
	off.y = 0.0
	if off.length() > REACH + 0.5 or absf(goal.y - global_position.y) > 1.4:
		if main.has_method("sfx"):
			main.sfx("fendre_air", global_position + Vector3.UP * 1.3)
		return
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	if off.length() > 0.2 and fwd.dot(off.normalized()) < 0.35:
		return
	if tgt == null:
		var dmg: int = int(fight.get("force", 1))
		if bagarre != null and is_instance_valid(bagarre) and bool(bagarre.lame):
			dmg += 1
		if main.has_method("sfx"):
			main.sfx("coup_poing", goal + Vector3.UP * 1.4)
		var ms: Node = main.get("monstres_v36")
		if ms != null:
			ms.hurt_player(dmg, global_position)
		elif main.hero_v28 != null:
			main.hero_v28.hurt(dmg, global_position)
	elif is_instance_valid(tgt) and tgt.has_method("npc_hit"):
		tgt.npc_hit(1, self)


## Un coup reçu d'un autre bagarreur.
func npc_hit(dmg: int, from: Node3D) -> void:
	if fight.is_empty() or ko_left > 0.0:
		return
	# un vieux briscard pare une fois sur deux
	if str(fight["act"]) in ["garde", "approche"] and _rngp.randf() < 0.45:
		_set_act("pare")
		_play("pir/pare", 0.08)
		if main.has_method("sfx"):
			main.sfx("parade", global_position + Vector3.UP * 1.3)
		return
	if main.has_method("sfx"):
		main.sfx("coup_poing", global_position + Vector3.UP * 1.4)
	_take_damage(dmg, from.global_position, false)


## Frappé par le joueur (un coup de poing, de pied, ou… de lame).
func take_hit(damage: int, from_pos: Vector3) -> void:
	if ko_left > 0.0 or _ko_phase != "" or hidden_home:
		return
	var mgr: Node = azur
	if fight.is_empty():
		# frappé à froid : il se fâche tout rouge, et c'est la bagarre (un pacifique appelle à l'aide)
		var line: String = brain.hit(main._npc_ctx_v31())
		say_bubble(line, 3.5)
		_face(from_pos - global_position, 1.0, 50.0)
		if state == "parle":
			main._close_dialogue_v31()
		if mgr != null and mgr.has_method("brawl"):
			mgr.brawl(self, "frappe", false)
		if fight.is_empty():
			gesture("colere")
			return
	elif str(fight["role"]) != "attaquant":
		# il aidait le joueur (ou se battait contre un autre) : maintenant c'est contre lui
		fight["role"] = "attaquant"
		fight["target"] = null
		if bagarre != null and is_instance_valid(bagarre):
			bagarre.turn_on_player(self)
	var eff: int = damage
	if bagarre != null and is_instance_valid(bagarre):
		eff = int(bagarre.player_damage(damage))
	# la garde : il pare parfois (plus souvent les costauds)
	var to_p: Vector3 = from_pos - global_position
	to_p.y = 0.0
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var block: float = 0.14 + (0.12 if bool(brain.pir().get("costaud", false)) else 0.0)
	if str(fight["act"]) in ["garde", "approche"] and to_p.length() > 0.1 and fwd.dot(to_p.normalized()) > 0.5 and _rngp.randf() < block:
		_set_act("pare")
		_play("pir/pare", 0.08)
		if main.has_method("sfx"):
			main.sfx("parade", global_position + Vector3.UP * 1.3)
		if main.get("combat_v28") != null and main.combat_v28 != null:
			main.combat_v28.float_text(global_position + Vector3.UP * 2.1, "Paré !", Color(0.85, 0.9, 1.0))
		return
	_take_damage(eff, from_pos, true)


func _take_damage(dmg: int, from_pos: Vector3, by_player: bool) -> void:
	fight["hp"] = int(fight["hp"]) - maxi(dmg, 0)
	var cb: Node = main.get("combat_v28")
	if by_player and cb != null and dmg > 0:
		cb.damage_number(global_position + Vector3.UP * 2.0, dmg)
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	_knock = away.normalized() * (1.6 + dmg * 0.3) if away.length() > 0.01 else Vector3.ZERO
	if int(fight["hp"]) <= 0:
		knock_out(by_player)
		return
	_set_act("touche")
	_play("pir/encaisse", 0.06, 1.0, 0.0)
	if randf() < 0.3:
		say_bubble(["Ouch !", "Aïe !", "Grrr…", "Pas mal…", "C'est tout ?", "Tu vas me le payer !"][_rngp.randi() % 6], 1.6)


## Au tapis : il tombe, des étoiles tournent au-dessus de sa tête ; il se relèvera.
func knock_out(by_player: bool) -> void:
	var b: Node = bagarre
	fight = {}
	bagarre = null
	ko_left = KO_TIME
	_ko_phase = "tombe"
	state = "ko"
	_play("Knock_Down", 0.12, 1.0, 0.0)
	if main.has_method("sfx"):
		main.sfx("ko", global_position + Vector3.UP * 0.6)
	_make_stars()
	_stars.visible = true
	say_bubble(["Ooooh…", "Les étoiles… je vois les étoiles…", "Maman…", "Où suis-je ?", "Pas… la… figure…"][_rngp.randi() % 5], 3.0)
	if b != null and is_instance_valid(b):
		b.on_ko(self, by_player)


func _ko_tick(delta: float) -> void:
	_bubble_tick(delta)
	brain.tick(delta)
	if _stars != null and _stars.visible and skel != null:
		var hb: int = skel.find_bone("Head")
		if hb >= 0:
			var hp: Vector3 = skel.global_transform * skel.get_bone_global_pose(hb).origin
			_stars.global_position = hp + Vector3.UP * 0.32
		_stars.rotation.y += delta * 3.0
	match _ko_phase:
		"tombe":
			if anim == null or anim.current_animation != "Knock_Down" or anim.current_animation_position >= anim.current_animation_length - 0.1:
				if anim != null and anim.current_animation == "Knock_Down":
					anim.pause()
				_ko_phase = "sol"
		"sol":
			ko_left -= delta
			if ko_left <= 0.0:
				ko_left = 0.0
				_ko_phase = "releve"
				if _stars != null:
					_stars.visible = false
				if anim != null and anim.has_animation("Knock_Down"):
					anim.play_backwards("Knock_Down", 0.2)
					current_anim = "Knock_Down_back"
		"releve":
			if anim == null or not anim.is_playing() or anim.current_animation_position <= 0.05:
				_ko_phase = ""
				_play("pir/machoire", 0.3, 1.0, 0.0)
				gesture_clock = 2.4
				_resume()
		_:
			_ko_phase = ""


## Relevé de force (fin de partie, chargement) : debout tout de suite.
func wake_now() -> void:
	ko_left = 0.0
	_ko_phase = ""
	if _stars != null:
		_stars.visible = false
	fight = {}
	bagarre = null
	_watch_t = 0.0
	_resume()


func _make_stars() -> void:
	if _stars != null:
		return
	_stars = Node3D.new()
	_stars.name = "Etoiles_KO"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for k in range(10):
		var a: float = -PI * 0.5 + k * PI / 5.0
		var r: float = 0.06 if k % 2 == 0 else 0.026
		pts.append(Vector3(cos(a) * r, -sin(a) * r, 0.0))
	for k in range(10):
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(pts[k])
		st.add_vertex(pts[(k + 1) % 10])
	var star_mesh: ArrayMesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.86, 0.25)
	for i in range(3):
		var mi := MeshInstance3D.new()
		mi.mesh = star_mesh
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a2: float = TAU * i / 3.0
		mi.position = Vector3(cos(a2) * 0.22, sin(a2 * 2.0) * 0.03, sin(a2) * 0.22)
		mi.rotation.y = -a2
		_stars.add_child(mi)
	add_child(_stars)
	_stars.top_level = true
	_stars.visible = false


func _move_toward(goal: Vector3, delta: float, speed: float) -> void:
	var to: Vector3 = goal - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	var dir: Vector3 = to.normalized()
	# un mur entre lui et sa cible : il passe par le graphe des rues (portes, couloirs)
	_path_t -= delta
	if not _clear(global_position, goal):
		if _path.is_empty() or _path_t <= 0.0:
			_path_t = 1.0
			var a: String = _nearest_point(global_position)
			var b: String = _nearest_point(goal)
			var keep: String = at_point
			at_point = a
			_path = _route_to(b)
			_path.push_front(a)
			at_point = keep
		while not _path.is_empty():
			var w: Vector3 = points[_path[0]]
			var tw: Vector3 = w - global_position
			tw.y = 0.0
			if tw.length() < 0.4:
				_path.pop_front()
				continue
			dir = tw.normalized()
			break
	else:
		_path.clear()
	_move_dir(dir, delta, speed)


func _move_dir(dir: Vector3, delta: float, speed: float) -> void:
	# on ne se marche pas dessus : un petit écart entre les bagarreurs
	if bagarre != null and is_instance_valid(bagarre):
		for o in bagarre.fighters():
			if o == self or not is_instance_valid(o):
				continue
			var off: Vector3 = global_position - (o as Node3D).global_position
			off.y = 0.0
			if off.length() < 0.85 and off.length() > 0.001:
				dir += off.normalized() * (0.85 - off.length()) * 2.0
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	var step: Vector3 = dir.normalized() * speed * delta
	# pas à travers les murs
	if not _clear(global_position, global_position + step.normalized() * 0.45):
		return
	global_position += step
	_snap_to_floor()

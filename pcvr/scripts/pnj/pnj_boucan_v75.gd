extends "res://scripts/pnj/pnj_montjoie_v71.gd"
## V75 : un habitant de Port-Boucan (l'Île du Boucan, la ville-friche des punks). Même vie réglée
## par l'heure que les autres (et toutes les postures des îles d'avant), avec en plus :
##  - pogo : dans la fosse de la Halle Hurlante, on saute, on se bouscule gentiment, les poings en
##    l'air ;
##  - chanter (le micro à la main), guitare et basse (debout, sur scène : on gratte, on headbangue),
##    batterie (assis derrière les fûts : les baguettes volent) ;
##  - skate (sur la planche, au Bassin à sec : on va, on vient, on saute) ; peindre (une bombe de
##    peinture à la main) ; cuisiner (la louche dans la grande marmite).
## Et ce qui fait un habitant du Boucan (fiche « punk » : tenue, objet, chapeau) : les objets se
## voient (la guitare dans le dos, la basse, les baguettes dans la poche, le micro, la clé à
## molette, la bombe de peinture, le casque audio autour du cou, l'arrosoir, la tablette de
## Monsieur Lisse, le skate sous le bras, les aiguilles à tricoter, les balles de jongleur).

const HOLD_BO := ["pogo", "chanter", "guitare", "basse", "batterie", "skate", "peindre", "cuisiner"]

var _punk: Dictionary = {}
var _guitar: Node3D                      # la guitare (ou la basse) : dans le dos, ou jouée
var _sticks: Node3D                      # les baguettes (dans les mains, à la batterie)
var _mic: Node3D
var _board: Node3D                       # le skate (sous les pieds, ou sous le bras)
var _spray: Node3D
var _bo_clock: float = 0.0
var _pogo_phase: float = 0.0
var _skate_x: float = 0.0
var _home_pos := Vector3.ZERO


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_bo_poses()
	punk_props(data.get("punk", {}))
	_bo_clock = _rng2.randf() * 10.0
	_pogo_phase = _rng2.randf() * TAU


## Les objets de la fiche « punk » (le chapeau du vrai corps est cousu avec les habits, V64).
func punk_props(pk: Dictionary) -> void:
	if skel == null or pk.is_empty() or not _punk.is_empty():
		return
	_punk = pk
	var obj: String = str(pk.get("objet", ""))
	match obj:
		"guitare", "basse":
			_make_guitar(obj == "basse")
		"baguettes":
			_make_sticks()
		"micro":
			_mic = Node3D.new()
			_part(_mic, _cyl(0.014, 0.018, 0.16), _m(Color(0.08, 0.08, 0.09), 0.4, 0.6), Vector3(0, 0.0, 0))
			_part(_mic, _sphere(0.03), _m(Color(0.55, 0.56, 0.58), 0.3, 0.9), Vector3(0, 0.1, 0))
			_attach("RightHand", Vector3(0, -6, 3), _mic, Vector3(180, 0, 0))
			_hand_prop = _mic
		"bombe_peinture":
			_spray = Node3D.new()
			_part(_spray, _cyl(0.03, 0.03, 0.17), _m([Color(0.9, 0.2, 0.3), Color(0.2, 0.7, 0.3), Color(0.2, 0.4, 0.9)][abs(hash(str(profile.get("id", "")))) % 3], 0.35, 0.5), Vector3(0, 0.08, 0))
			_part(_spray, _cyl(0.012, 0.012, 0.025), _m(Color(0.95, 0.95, 0.95), 0.4), Vector3(0, 0.18, 0))
			_attach("RightHand", Vector3(0, -6, 3), _spray, Vector3(180, 0, 0))
			_hand_prop = _spray
		"cle_molette":
			_hand_prop = Node3D.new()
			var st := _m(Color(0.62, 0.64, 0.66), 0.35, 0.9)
			_part(_hand_prop, _box_mesh_np(Vector3(0.025, 0.24, 0.012)), st, Vector3(0, 0.08, 0))
			_part(_hand_prop, _box_mesh_np(Vector3(0.06, 0.05, 0.016)), st, Vector3(0, 0.21, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))
		"casque_audio":
			var hp := Node3D.new()
			var blk := _m(Color(0.07, 0.07, 0.08), 0.5)
			var tm := TorusMesh.new()
			tm.inner_radius = 0.075
			tm.outer_radius = 0.09
			_part(hp, tm, blk, Vector3(0, 0, 0), Vector3(1.0, 1.0, 0.8), Vector3(90, 0, 0))
			for s in [-1.0, 1.0]:
				_part(hp, _cyl(0.04, 0.04, 0.03), blk, Vector3(s * 0.085, -0.02, 0), Vector3.ONE, Vector3(0, 0, 90))
			_attach("Neck", Vector3(0, -2, 2), hp, Vector3(-20, 0, 0))
		"arrosoir":
			_hand_prop = Node3D.new()
			var zn := _m(Color(0.6, 0.64, 0.6), 0.35, 0.7)
			_part(_hand_prop, _cyl(0.08, 0.08, 0.2), zn, Vector3(0, -0.2, 0))
			_part(_hand_prop, _cyl(0.012, 0.02, 0.24), zn, Vector3(0.1, -0.14, 0), Vector3.ONE, Vector3(0, 0, -50))
			_attach("LeftHand", Vector3(0, -6, 2), _hand_prop)
		"tablette":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _box_mesh_np(Vector3(0.17, 0.24, 0.01)), _m(Color(0.12, 0.12, 0.14), 0.2, 0.4), Vector3.ZERO)
			var scr := _m(Color(0.4, 0.6, 0.9), 0.2)
			scr.emission_enabled = true
			scr.emission = Color(0.3, 0.5, 0.9)
			scr.emission_energy_multiplier = 0.6
			_part(_hand_prop, _box_mesh_np(Vector3(0.15, 0.21, 0.002)), scr, Vector3(0, 0, 0.006))
			_attach("LeftHand", Vector3(0, -6, 6), _hand_prop, Vector3(-60, 0, 0))
		"skate":
			_make_board()
		"aiguilles":
			_hand_prop = Node3D.new()
			var laine := _m([Color(0.85, 0.2, 0.2), Color(0.3, 0.3, 0.75), Color(0.85, 0.7, 0.2)][abs(hash(str(profile.get("id", "")))) % 3], 0.95)
			_part(_hand_prop, _sphere(0.06), laine, Vector3(0, 0.02, 0), Vector3(1.4, 0.7, 1.0))
			for s2 in [-1.0, 1.0]:
				_part(_hand_prop, _cyl(0.004, 0.004, 0.3), _m(Color(0.75, 0.75, 0.78), 0.3, 0.9), Vector3(s2 * 0.04, 0.08, 0), Vector3.ONE, Vector3(0, 0, s2 * 25))
			_attach("LeftHand", Vector3(0, -6, 6), _hand_prop, Vector3(-30, 0, 0))
		"balles_jonglage":
			_hand_prop = Node3D.new()
			for k in range(3):
				_part(_hand_prop, _sphere(0.035), _m([Color(0.9, 0.2, 0.2), Color(0.2, 0.7, 0.9), Color(0.95, 0.85, 0.2)][k], 0.5), Vector3((k - 1) * 0.06, 0.0, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop)
		_:
			# les objets des autres îles (louche, panier, livre, canne à pêche…)
			if obj != "":
				_mj_object(obj, str(pk.get("tenue", "")))


## La guitare (ou la basse) : un corps plat, un manche, une tête ; dans le dos, en bandoulière.
func _make_guitar(bass: bool) -> void:
	_guitar = Node3D.new()
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(profile.get("id", "")) + "guitare")
	var col: Color = [Color(0.75, 0.08, 0.08), Color(0.06, 0.06, 0.07), Color(0.95, 0.94, 0.9), Color(0.1, 0.3, 0.6), Color(0.85, 0.65, 0.15)][r.randi() % 5]
	var body := _m(col, 0.25, 0.1)
	body.clearcoat_enabled = true
	body.clearcoat = 0.8
	var neck := _m(Color(0.42, 0.26, 0.14), 0.5)
	var metal := _m(Color(0.8, 0.8, 0.82), 0.25, 0.9)
	var lw: float = 1.12 if bass else 1.0
	_part(_guitar, _sphere(0.15), body, Vector3(0, 0, 0), Vector3(1.0, 0.24, 1.25))
	_part(_guitar, _sphere(0.11), body, Vector3(0, 0, 0.16), Vector3(1.0, 0.24, 1.0))
	_part(_guitar, _box_mesh_np(Vector3(0.045, 0.025, 0.46 * lw)), neck, Vector3(0, 0.012, 0.42 * lw))
	_part(_guitar, _box_mesh_np(Vector3(0.07, 0.02, 0.12)), neck, Vector3(0, 0.01, 0.7 * lw))
	_part(_guitar, _box_mesh_np(Vector3(0.08, 0.01, 0.025)), metal, Vector3(0, 0.035, -0.06))
	_part(_guitar, _box_mesh_np(Vector3(0.05, 0.012, 0.05)), _m(Color(0.1, 0.1, 0.1), 0.5), Vector3(0, 0.034, 0.08))
	for k in range(4 if bass else 6):
		_part(_guitar, _box_mesh_np(Vector3(0.002, 0.002, 0.7 * lw)), metal, Vector3(-0.015 + k * (0.03 / (3.0 if bass else 5.0)), 0.04, 0.3 * lw))
	_attach("Spine02", Vector3(0, 2, -16), _guitar, Vector3(70, 0, 40))


func _make_sticks() -> void:
	_sticks = Node3D.new()
	var wood := _m(Color(0.86, 0.72, 0.5), 0.6)
	for s in [-1.0, 1.0]:
		_part(_sticks, _cyl(0.006, 0.009, 0.4), wood, Vector3(s * 0.02, 0.0, 0))
	_attach("Hips", Vector3(12, 2, -8), _sticks, Vector3(0, 0, 10))


func _make_board() -> void:
	_board = Node3D.new()
	var deck := _m(Color(0.15, 0.15, 0.17), 0.8)
	_part(_board, _box_mesh_np(Vector3(0.2, 0.015, 0.8)), deck, Vector3.ZERO)
	for z in [-0.28, 0.28]:
		for s in [-0.08, 0.08]:
			_part(_board, _cyl(0.026, 0.026, 0.03), _m(Color(0.95, 0.9, 0.6), 0.6), Vector3(s, -0.03, z), Vector3.ONE, Vector3(0, 0, 90))
	_attach("LeftHand", Vector3(0, -8, 6), _board, Vector3(0, 90, 90))


# =================================================================== postures

func _build_bo_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("bo"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# le pogo : des sauts, les poings en l'air, les épaules qui tanguent
	var j_up := {"LeftUpLeg": Vector3(-24, 0, -6), "LeftLeg": Vector3(30, 0, 0), "RightUpLeg": Vector3(-20, 0, 6), "RightLeg": Vector3(26, 0, 0),
		"RightArm": Vector3(-160, 0, 20), "RightForeArm": Vector3(-20, 0, 0), "LeftArm": Vector3(-70, 0, -40), "LeftForeArm": Vector3(-60, 0, 0),
		"Spine02": Vector3(-6, 0, -6), "Head": Vector3(-14, 0, 4)}
	var j_dn := {"LeftUpLeg": Vector3(-34, 0, -6), "LeftLeg": Vector3(56, 0, 0), "RightUpLeg": Vector3(-34, 0, 6), "RightLeg": Vector3(56, 0, 0),
		"RightArm": Vector3(-120, 0, 30), "RightForeArm": Vector3(-50, 0, 0), "LeftArm": Vector3(-60, 0, -30), "LeftForeArm": Vector3(-70, 0, 0),
		"Spine02": Vector3(14, 0, 4), "Head": Vector3(18, 0, -4)}
	var j_up2 := lib._merge(j_up, {"LeftArm": Vector3(-160, 0, -20), "LeftForeArm": Vector3(-20, 0, 0), "RightArm": Vector3(-70, 0, 40), "RightForeArm": Vector3(-60, 0, 0),
		"Spine02": Vector3(-6, 0, 6), "Head": Vector3(-14, 0, -4)})
	poses.add_animation("pogo", lib._clip(0.9, true, [[0.0, j_dn, Vector3(0, -6, 0)], [0.22, j_up, Vector3(0, 28, 0)], [0.45, j_dn, Vector3(0, -6, 0)], [0.67, j_up2, Vector3(0, 28, 0)], [0.9, j_dn, Vector3(0, -6, 0)]]))
	# chanter : le micro à la bouche, l'autre bras qui bat la mesure, un genou qui plie
	var c_a := {"RightArm": Vector3(-64, 0, 34), "RightForeArm": Vector3(-128, 0, 0), "Head": Vector3(-8, 0, 0), "Spine02": Vector3(-6, 0, 0),
		"LeftArm": Vector3(-100, 0, -40), "LeftForeArm": Vector3(-40, 0, 0), "LeftUpLeg": Vector3(-12, 0, -4), "LeftLeg": Vector3(18, 0, 0)}
	var c_b := lib._merge(c_a, {"LeftArm": Vector3(-150, 0, -26), "LeftForeArm": Vector3(-14, 0, 0), "Head": Vector3(-18, 6, 0), "Spine02": Vector3(-10, 4, 0),
		"LeftUpLeg": Vector3(-4, 0, -4), "LeftLeg": Vector3(4, 0, 0), "RightUpLeg": Vector3(-14, 0, 4), "RightLeg": Vector3(20, 0, 0)})
	var c_c := lib._merge(c_a, {"Spine02": Vector3(18, 0, 0), "Head": Vector3(10, 0, 0), "LeftArm": Vector3(-30, 0, -50)})
	poses.add_animation("chanter", lib._clip(2.0, true, [[0.0, c_a, Vector3.ZERO], [0.5, c_b, Vector3(0, -2, 0)], [1.0, c_a, Vector3.ZERO], [1.5, c_c, Vector3(0, -4, 0)], [2.0, c_a, Vector3.ZERO]]))
	# la guitare debout : la main gauche au manche, la droite qui gratte, on headbangue
	var g_a := {"LeftArm": Vector3(-56, 34, -12), "LeftForeArm": Vector3(-78, 0, 0), "RightArm": Vector3(-30, 0, 28), "RightForeArm": Vector3(-80, 0, 0),
		"Head": Vector3(22, -10, 0), "Spine02": Vector3(10, 0, 0), "LeftUpLeg": Vector3(-8, 0, -10), "RightUpLeg": Vector3(-6, 0, 12)}
	var g_b := lib._merge(g_a, {"RightForeArm": Vector3(-96, 0, 0), "Head": Vector3(-6, -10, 0), "Spine02": Vector3(-2, 0, 0)})
	poses.add_animation("guitare", lib._clip(0.5, true, [[0.0, g_a, Vector3(0, -2, 0)], [0.25, g_b, Vector3(0, 1, 0)], [0.5, g_a, Vector3(0, -2, 0)]]))
	var b_a := lib._merge(g_a, {"LeftArm": Vector3(-46, 40, -16), "Head": Vector3(10, -14, 0)})
	var b_b := lib._merge(b_a, {"RightForeArm": Vector3(-92, 0, 0), "Head": Vector3(4, -14, 0)})
	poses.add_animation("basse", lib._clip(0.7, true, [[0.0, b_a, Vector3.ZERO], [0.35, b_b, Vector3(0, -2, 0)], [0.7, b_a, Vector3.ZERO]]))
	# la batterie : assis, les deux baguettes qui tapent l'une après l'autre, la tête qui suit
	var seated := {"LeftUpLeg": Vector3(-80, 0, 12), "RightUpLeg": Vector3(-80, 0, -12), "LeftLeg": Vector3(80, 0, 0), "RightLeg": Vector3(80, 0, 0), "Spine02": Vector3(8, 0, 0)}
	var d_l := lib._merge(seated, {"LeftArm": Vector3(-70, 0, -30), "LeftForeArm": Vector3(-30, 0, 0), "RightArm": Vector3(-40, 0, 30), "RightForeArm": Vector3(-90, 0, 0), "Head": Vector3(14, 8, 0)})
	var d_r := lib._merge(seated, {"LeftArm": Vector3(-40, 0, -30), "LeftForeArm": Vector3(-90, 0, 0), "RightArm": Vector3(-70, 0, 30), "RightForeArm": Vector3(-30, 0, 0), "Head": Vector3(14, -8, 0)})
	var d_x := lib._merge(seated, {"LeftArm": Vector3(-110, 0, -40), "LeftForeArm": Vector3(-20, 0, 0), "RightArm": Vector3(-110, 0, 40), "RightForeArm": Vector3(-20, 0, 0), "Head": Vector3(-10, 0, 0)})
	poses.add_animation("batterie", lib._clip(1.2, true, [[0.0, d_l, Vector3(0, -38, 0)], [0.15, d_r, Vector3(0, -38, 0)], [0.3, d_l, Vector3(0, -38, 0)], [0.45, d_r, Vector3(0, -38, 0)],
		[0.6, d_l, Vector3(0, -38, 0)], [0.75, d_r, Vector3(0, -38, 0)], [0.9, d_x, Vector3(0, -36, 0)], [1.05, d_r, Vector3(0, -38, 0)], [1.2, d_l, Vector3(0, -38, 0)]]))
	# le skate : de profil sur la planche, genoux fléchis, les bras pour l'équilibre
	var s_a := {"LeftUpLeg": Vector3(-30, 0, -14), "LeftLeg": Vector3(40, 0, 0), "RightUpLeg": Vector3(-20, 0, 14), "RightLeg": Vector3(30, 0, 0),
		"LeftArm": Vector3(-30, 0, -60), "RightArm": Vector3(-30, 0, 60), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0), "Spine02": Vector3(10, 0, 0), "Head": Vector3(0, -60, 0)}
	var s_b := lib._merge(s_a, {"LeftUpLeg": Vector3(-46, 0, -14), "LeftLeg": Vector3(70, 0, 0), "RightUpLeg": Vector3(-46, 0, 14), "RightLeg": Vector3(70, 0, 0), "Spine02": Vector3(20, 0, 0)})
	poses.add_animation("skate", lib._clip(3.0, true, [[0.0, s_a, Vector3(0, 6, 0)], [1.2, s_a, Vector3(0, 6, 0)], [1.5, s_b, Vector3(0, -4, 0)], [1.8, s_a, Vector3(0, 40, 0)], [2.1, s_a, Vector3(0, 6, 0)], [3.0, s_a, Vector3(0, 6, 0)]]))
	# cuisiner : on touille la grande marmite, à deux mains, en se penchant un peu
	var k_a := {"Spine02": Vector3(16, 0, 0), "Head": Vector3(14, 0, 0), "RightArm": Vector3(-50, 10, 20), "RightForeArm": Vector3(-70, 0, 0),
		"LeftArm": Vector3(-46, -10, -20), "LeftForeArm": Vector3(-74, 0, 0)}
	var k_b := lib._merge(k_a, {"RightArm": Vector3(-56, -16, 30), "LeftArm": Vector3(-52, 12, -12), "Spine02": Vector3(18, 6, 0)})
	var k_c := lib._merge(k_a, {"RightArm": Vector3(-44, 26, 14), "LeftArm": Vector3(-40, -22, -26), "Spine02": Vector3(14, -6, 0)})
	poses.add_animation("cuisiner", lib._clip(2.4, true, [[0.0, k_a, Vector3.ZERO], [0.6, k_b, Vector3.ZERO], [1.2, k_a, Vector3.ZERO], [1.8, k_c, Vector3.ZERO], [2.4, k_a, Vector3.ZERO]]))
	anim.add_animation_library("bo", poses)
	lib.free()


## On se place pile à son lieu pour jouer, chanter, danser (la scène, la fosse, la batterie).
func _arrive() -> void:
	super._arrive()
	_home_pos = Vector3.ZERO
	if hidden_home or not pose in HOLD_BO:
		return
	var sp: Dictionary = azur.spot(target_spot)
	if sp.is_empty():
		return
	global_position = sp["pos"]
	var f: Vector3 = _spot_face(sp)
	f.y = 0.0
	if f.length() > 0.01:
		rotation.y = atan2(f.x, f.z)
	if _body != null:
		_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	_bo_clock += delta
	if not pose in HOLD_BO:
		_bo_props("")
		super._activity(delta, dist, to_player)
		return
	match pose:
		"pogo":
			_bo_props("")
			if not _concert_on():
				_play("v28/idle", 0.4)
				if dist < 2.2:
					_face(to_player, delta, 3.0)
				return
			_play("bo/pogo", 0.25, 1.0 + 0.08 * sin(_bo_clock * 0.7 + _pogo_phase))
			# on se bouscule un peu : on tourne, on bouge de quelques centimètres
			rotation.y += sin(_bo_clock * 1.3 + _pogo_phase) * delta * 0.8
		"chanter":
			_bo_props("micro")
			if not _concert_on():
				_play("v28/idle", 0.4)
				return
			_play("bo/chanter", 0.3)
		"guitare", "basse":
			_bo_props("guitare")
			if not _concert_on() and not _on_stage():
				# hors de la scène : la guitare assise des autres îles
				super._activity(delta, dist, to_player)
				return
			_play("bo/" + pose, 0.25)
		"batterie":
			_bo_props("baguettes")
			if not _concert_on():
				_play("v28/sit", 0.4)
				return
			_play("bo/batterie", 0.25, 1.0)
		"skate":
			_bo_props("skate")
			_play("bo/skate", 0.3)
			if _home_pos == Vector3.ZERO:
				_home_pos = global_position
			_skate_x = sin(_bo_clock * 0.6) * 4.0
			global_position = _home_pos + Vector3(cos(rotation.y) * _skate_x, 0, -sin(rotation.y) * _skate_x)
			if _body != null:
				_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)
		"peindre":
			_bo_props("bombe")
			_play("v56/peindre", 0.4)
		"cuisiner":
			_bo_props("")
			if dist < 2.2:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("bo/cuisiner", 0.4)
	if pose != "skate":
		_home_pos = Vector3.ZERO


## Les objets tenus selon ce qu'on fait : la guitare passe du dos aux mains, les baguettes aussi,
## le skate passe sous les pieds.
func _bo_props(which: String) -> void:
	if _guitar != null:
		var playing: bool = which == "guitare" and (_concert_on() or _on_stage())
		_place_prop(_guitar, "Spine02", Vector3(0, 2, -16) if not playing else Vector3(0, -4, 14), Vector3(70, 0, 40) if not playing else Vector3(-10, 0, -70))
	if _sticks != null:
		var drum: bool = which == "baguettes" and _concert_on()
		_place_prop(_sticks, "RightHand" if drum else "Hips", Vector3(0, -6, 3) if drum else Vector3(12, 2, -8), Vector3(90, 0, 0) if drum else Vector3(0, 0, 10))
	if _board != null:
		var ride: bool = which == "skate"
		_place_prop(_board, "Hips" if ride else "LeftHand", Vector3(0, -96, 0) if ride else Vector3(0, -8, 6), Vector3(0, 90, 0) if ride else Vector3(0, 90, 90))
	if _mic != null:
		_mic.visible = true
	if _spray != null:
		_spray.visible = true


## Accroche un objet déjà fait à un autre os (ou au même, à une autre place).
func _place_prop(prop: Node3D, bone: String, offset_cm: Vector3, rot_deg: Vector3) -> void:
	if prop == null:
		return
	var key: String = bone + str(offset_cm) + str(rot_deg)
	if prop.has_meta("place") and str(prop.get_meta("place")) == key:
		return
	prop.set_meta("place", key)
	var p: Node = prop.get_parent()
	if p != null:
		p.remove_child(prop)
	prop.position = Vector3.ZERO
	prop.rotation = Vector3.ZERO
	_attach(bone, offset_cm, prop, rot_deg)


func _concert_on() -> bool:
	return azur != null and azur.has_method("concert_on") and bool(azur.concert_on())


func _on_stage() -> bool:
	return target_spot.begins_with("halle_scene")

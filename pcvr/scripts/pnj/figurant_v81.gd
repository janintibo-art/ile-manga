extends Node
## V81 : un habitant d'une maison qu'on visite (maisons_v81.gd). Le corps et les accessoires
## sont ceux des habitants de sa ville (on crée un vrai habitant de la bonne classe, puis on
## éteint sa vie réglée par l'heure) ; ce petit chef d'orchestre le fait tenir sa pose (assis,
## couché, accoudé, mort de rire, bras croisés, à tricoter…), se tourner vers le joueur, lancer
## une petite phrase de temps en temps, et parler quand on lui adresse la parole.

const HeroLib = preload("res://scripts/hero_v28.gd")
const PnjLumen = preload("res://scripts/pnj/pnj_lumen_v76.gd")
const PnjPirate = preload("res://scripts/pnj/pnj_pirate_v68.gd")
const PnjRamure = preload("res://scripts/pnj/pnj_ramure_v62.gd")

var main: Node
var npc: Node3D
var pose: String = "debout"
var face_dir: Vector3 = Vector3(0, 0, 1)
var follow: bool = true                 # se tourne vers le joueur quand il est près
var lines: Array = []                   # petites phrases (bulles) de temps en temps
var line_every: Vector2 = Vector2(7.0, 13.0)
var talking: bool = false
var _line_t: float = 3.0
var _t: float = 0.0
var _gest: float = 0.0
var _rng := RandomNumberGenerator.new()
var _bubble_far: bool = false
var _lying: bool = false                 # couché (sur un lit, un canapé) : on ne le tourne plus
var _plank: Array = []                  # pompes : [pieds, direction]


## Crée l'habitant (corps de la bonne ville) à `pos` (pieds), regard `face`.
static func spawn(parent: Node3D, main_node: Node, profile: Dictionary, pos: Vector3, face: Vector3, pose_name: String) -> Node:
	var kind: String = str(profile.get("classe", "lumen"))
	var npc: Node3D
	match kind:
		"pirate":
			npc = PnjPirate.new()
		"ramure":
			npc = PnjRamure.new()
		_:
			npc = PnjLumen.new()
	parent.add_child(npc)
	npc.setup(main_node, profile, {"ici": pos}, {"ici": []}, "ici")
	var stub := Node.new()
	stub.name = "Maison_v81"
	npc.add_child(stub)
	npc.setup_azur(stub, profile)
	npc.set_process(false)
	npc.remove_from_group("pnj_v31")
	npc.sleep_far = 0.0
	npc.global_position = pos
	var ctl: Node = (load("res://scripts/pnj/figurant_v81.gd") as Script).new()
	ctl.name = "Figurant_v81"
	npc.add_child(ctl)
	ctl.setup(main_node, npc, pose_name, face)
	return ctl


func setup(main_node: Node, n: Node3D, pose_name: String, face: Vector3) -> void:
	main = main_node
	npc = n
	pose = pose_name
	face_dir = face
	_rng.seed = hash(str(npc.get("display_name")))
	_line_t = _rng.randf_range(2.0, 6.0)
	_build_poses()
	set_pose(pose_name, face)


func set_pose(p: String, face: Vector3 = Vector3.ZERO) -> void:
	pose = p
	if face.length() > 0.01:
		face_dir = face
		var f := Vector3(face.x, 0, face.z).normalized()
		npc.rotation.y = atan2(f.x, f.z)
	follow = pose in ["debout", "bras_croises", "colere", "rire", "comptoir", "mains_dos", "applaudir", "pointer"]
	npc.set("current_anim", "")
	_apply_anim(true)


func say(text: String, seconds: float = 4.0) -> void:
	npc.say_bubble(text, seconds)


## Couché sur le dos : les pieds en `feet` (à hauteur du matelas), la tête vers `toward`.
func lie(feet: Vector3, toward: Vector3) -> void:
	pose = "dormir"
	follow = false
	_lying = true
	_plank = []
	var y_axis: Vector3 = Vector3(toward.x, 0, toward.z).normalized()
	var z_axis := Vector3.UP
	var x_axis: Vector3 = y_axis.cross(z_axis)
	npc.global_transform = Transform3D(Basis(x_axis, y_axis, z_axis), feet + Vector3.UP * 0.13)
	npc.set("current_anim", "")
	_play("v81/dormir", 0.3)


## Faire des pompes : les pieds en `feet`, le corps tendu vers `dir`, face au sol.
func plank(feet: Vector3, dir: Vector3) -> void:
	pose = "pompes"
	follow = false
	_lying = true
	_plank = [feet, Vector3(dir.x, 0, dir.z).normalized()]
	npc.set("current_anim", "")
	_play("v81/pompes", 0.3)
	_plank_tick()


func _plank_tick() -> void:
	if _plank.is_empty():
		return
	var tilt: float = deg_to_rad(14.0 + 7.0 * sin(_t * TAU / 1.4))
	var d: Vector3 = _plank[1]
	var y_axis: Vector3 = (d * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
	var x_axis: Vector3 = Vector3.UP.cross(d).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	npc.global_transform = Transform3D(Basis(x_axis, y_axis, z_axis), _plank[0])


## Se relever (après avoir été couché ou fait des pompes), debout à `at`.
func stand_up(at: Vector3, face: Vector3) -> void:
	_lying = false
	_plank = []
	npc.global_transform = Transform3D(Basis(), at)
	set_pose("debout", face)


## Une réaction : rire, saluer, se fâcher, sursauter.
func gesture(kind: String, seconds: float = 2.5) -> void:
	match kind:
		"rire":
			_play("v81/rire" if not _seated() else "v81/rire_assis", 0.2)
		"salut":
			_play("Formal_Bow", 0.2, 1.3, 0.4)
		"colere":
			_play("v81/colere", 0.2)
		"sursaut":
			_play("v28/hurt", 0.1, 0.7, 0.0)
		"applaudir":
			_play("v81/applaudir", 0.2)
		"joie":
			_play("Motivational_Cheer", 0.2, 1.1, 0.6)
	_gest = seconds


func _seated() -> bool:
	return pose in ["assis", "rire_assis", "tricot", "lire", "manger", "guitare", "dormir_assis"]


func _play(n: String, blend: float = 0.3, speed: float = 1.0, from: float = -1.0) -> void:
	if npc.has_method("_play"):
		npc.call("_play", n, blend, speed, from)


func _apply_anim(force: bool = false) -> void:
	if _gest > 0.0 and not force:
		return
	match pose:
		"assis":
			_play("v28/sit", 0.4)
		"manger":
			_play("v81/manger", 0.4)
		"rire_assis":
			_play("v81/rire_assis", 0.3)
		"tricot":
			_play("v81/tricot", 0.4)
		"lire":
			_play("v56/lire", 0.4)
		"guitare":
			_play("v56/guitare", 0.3)
		"dormir", "allonge":
			_play("v81/dormir", 0.5)
		"dormir_assis":
			_play("v81/dormir_assis", 0.5)
		"bras_croises":
			_play("v56/bras_croises", 0.4)
		"colere":
			_play("v81/colere", 0.3)
		"rire":
			_play("v81/rire", 0.3)
		"comptoir":
			_play("v56/comptoir", 0.4)
		"peindre":
			_play("v56/peindre", 0.4)
		"bricoler":
			_play("cq/bricoler", 0.4)
		"cuisiner":
			_play("bo/cuisiner", 0.4)
		"danse":
			_play("br/danse", 0.3)
		"violon":
			_play("br/violon", 0.3)
		"applaudir":
			_play("v81/applaudir", 0.3)
		"cache":
			_play("v81/cache", 0.4)
		"pompes":
			_play("v81/pompes", 0.3)
		"mime":
			_play("v81/mime", 0.3)
		"mains_dos":
			_play("v81/mains_dos", 0.4)
		"pointer":
			_play("v81/pointer", 0.3)
		"boire":
			_play("Stand_and_Drink", 0.4)
		_:
			_play("v28/idle", 0.4)


func _process(delta: float) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	_t += delta
	# la bulle s'efface
	var bc: float = float(npc.get("bubble_clock"))
	if bc > 0.0:
		bc -= delta
		npc.set("bubble_clock", bc)
		var b: Label3D = npc.get("bubble")
		if b != null:
			b.modulate.a = clampf(bc, 0.0, 1.0)
			if bc <= 0.0:
				b.visible = false
	var player: Vector3 = main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else npc.global_position + Vector3(0, 0, 3)
	var to_p: Vector3 = player - npc.global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	var vl: Label3D = npc.get("vr_label")
	if vl != null:
		vl.visible = false
	if _gest > 0.0:
		_gest -= delta
		if _gest <= 0.0:
			npc.set("current_anim", "")
			_apply_anim(true)
	if not _plank.is_empty():
		_plank_tick()
	if talking and main != null and main.get("dialogue_v31") != null and not main.dialogue_v31.opened:
		end_talk()
	if talking:
		if (follow or not _seated()) and not _lying:
			_turn(to_p, delta, 5.0)
		if _gest <= 0.0 and not _seated() and not _lying and pose not in ["dormir", "allonge", "cache"]:
			_play("Talk_with_Right_Hand_Open", 0.3, 0.9)
		return
	if _lying:
		pass
	elif follow and dist < 4.0 and dist > 0.3:
		_turn(to_p, delta, 3.0)
	elif face_dir.length() > 0.01:
		_turn(face_dir, delta, 2.0)
	if _gest <= 0.0:
		_apply_anim()
	# une petite phrase de temps en temps quand on est dans la pièce
	if not lines.is_empty() and dist < 7.5:
		_line_t -= delta
		if _line_t <= 0.0 and bc <= 0.0:
			_line_t = _rng.randf_range(line_every.x, line_every.y)
			say(str(lines[_rng.randi() % lines.size()]), 3.8)


func _turn(dir: Vector3, delta: float, speed: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target: float = atan2(dir.x, dir.z)
	npc.rotation.y = lerp_angle(npc.rotation.y, target, clampf(delta * speed, 0.0, 1.0))


func begin_talk() -> void:
	talking = true
	var b: Label3D = npc.get("bubble")
	if b != null:
		b.visible = false
	npc.set("bubble_clock", 0.0)


func end_talk() -> void:
	talking = false
	npc.set("current_anim", "")
	_apply_anim(true)


# =================================================================== les poses en plus

func _build_poses() -> void:
	var anim: AnimationPlayer = npc.get("anim")
	var skel: Skeleton3D = npc.get("skel")
	if anim == null or skel == null or anim.has_animation_library("v81"):
		return
	var lib = HeroLib.new()
	lib.hero = npc.get("model")
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var seated := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0),
		"LeftFoot": Vector3(-5, 0, 0), "RightFoot": Vector3(-5, 0, 0), "Spine02": Vector3(4, 0, 0),
		"RightArm": Vector3(-30, 0, -20), "RightForeArm": Vector3(-45, 0, 0), "LeftArm": Vector3(-35, 0, 12), "LeftForeArm": Vector3(-50, 0, 0)}
	var sy := Vector3(0, -38, 0)
	# rire debout : on se tient le ventre, le buste part en arrière puis en avant, la tête aussi
	var r_a := {"Spine02": Vector3(-12, 0, 0), "Spine01": Vector3(-4, 0, 0), "Head": Vector3(-22, 0, 0),
		"LeftArm": Vector3(-22, 0, 18), "LeftForeArm": Vector3(-100, 0, 0), "RightArm": Vector3(-22, 0, -18), "RightForeArm": Vector3(-100, 0, 0)}
	var r_b := lib._merge(r_a, {"Spine02": Vector3(18, 0, 0), "Spine01": Vector3(6, 0, 0), "Head": Vector3(10, 0, 0)})
	var r_c := lib._merge(r_a, {"Spine02": Vector3(8, 4, 0), "Head": Vector3(-8, 6, 0)})
	poses.add_animation("rire", lib._clip(1.2, true, [[0.0, r_a, Vector3(0, 0.5, 0)], [0.3, r_b, Vector3(0, -2.5, 0)], [0.6, r_c, Vector3(0, 0.5, 0)], [0.9, r_b, Vector3(0, -2.5, 0)], [1.2, r_a, Vector3(0, 0.5, 0)]]))
	# rire assis : le buste rebondit, une main tape la cuisse
	var ra_a := lib._merge(seated, {"Spine02": Vector3(-10, 0, 0), "Head": Vector3(-18, 0, 0), "RightArm": Vector3(-40, 0, -10), "RightForeArm": Vector3(-30, 0, 0)})
	var ra_b := lib._merge(seated, {"Spine02": Vector3(22, 0, 0), "Head": Vector3(8, 0, 0), "RightArm": Vector3(-20, 0, -14), "RightForeArm": Vector3(-10, 0, 0)})
	poses.add_animation("rire_assis", lib._clip(0.9, true, [[0.0, ra_a, sy], [0.25, ra_b, sy + Vector3(0, -1, 0)], [0.45, ra_a, sy], [0.7, ra_b, sy + Vector3(0, -1, 0)], [0.9, ra_a, sy]]))
	# manger : la cuillère monte à la bouche
	var m_a := lib._merge(seated, {"RightArm": Vector3(-38, 0, -16), "RightForeArm": Vector3(-60, 0, 0), "Spine02": Vector3(10, 0, 0), "Head": Vector3(8, 0, 0)})
	var m_b := lib._merge(seated, {"RightArm": Vector3(-62, 0, -26), "RightForeArm": Vector3(-125, 0, 0), "Spine02": Vector3(6, 0, 0), "Head": Vector3(0, 0, 0)})
	poses.add_animation("manger", lib._clip(3.0, true, [[0.0, m_a, sy], [1.0, m_a, sy], [1.4, m_b, sy], [1.8, m_b, sy], [2.2, m_a, sy], [3.0, m_a, sy]]))
	# tricoter : les deux avant-bras devant, les mains qui s'agitent
	var t_a := lib._merge(seated, {"LeftArm": Vector3(-30, 0, 20), "LeftForeArm": Vector3(-80, 0, 0), "RightArm": Vector3(-30, 0, -20), "RightForeArm": Vector3(-80, 0, 0),
		"Head": Vector3(18, 0, 0), "Spine02": Vector3(8, 0, 0)})
	var t_b := lib._merge(t_a, {"LeftForeArm": Vector3(-92, 0, 0), "RightForeArm": Vector3(-70, 0, 0)})
	poses.add_animation("tricot", lib._clip(0.8, true, [[0.0, t_a, sy], [0.4, t_b, sy], [0.8, t_a, sy]]))
	# dormir assis (dans un fauteuil) : la tête tombe sur l'épaule, on respire
	var ds_a := lib._merge(seated, {"Head": Vector3(26, 0, 14), "Spine02": Vector3(-6, 0, 0), "LeftArm": Vector3(-14, 0, 6), "RightArm": Vector3(-14, 0, -6), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0)})
	var ds_b := lib._merge(ds_a, {"Spine02": Vector3(-9, 0, 0), "Head": Vector3(22, 0, 14)})
	poses.add_animation("dormir_assis", lib._clip(4.0, true, [[0.0, ds_a, sy], [2.0, ds_b, sy + Vector3(0, 0.6, 0)], [4.0, ds_a, sy]]))
	# dormir couché (sur le dos ; le nœud entier est couché par lie()) : les bras le long du corps,
	# la tête un peu de côté, la poitrine qui se soulève
	var lie := {"LeftArm": Vector3(0, 0, -8), "RightArm": Vector3(0, 0, 8), "LeftForeArm": Vector3(-25, 0, 0), "RightForeArm": Vector3(-25, 0, 0),
		"Head": Vector3(-6, 18, 0), "LeftUpLeg": Vector3(0, 0, 3), "RightUpLeg": Vector3(0, 0, -3), "LeftFoot": Vector3(30, 0, 0), "RightFoot": Vector3(30, 0, 0)}
	var lie_b := lib._merge(lie, {"Spine02": Vector3(-5, 0, 0), "Spine01": Vector3(-2, 0, 0), "Head": Vector3(-8, 16, 0)})
	poses.add_animation("dormir", lib._clip(4.5, true, [[0.0, lie, Vector3.ZERO], [2.2, lie_b, Vector3(0, 0, 0.6)], [4.5, lie, Vector3.ZERO]]))
	# colère : poings sur les hanches, la tête qui fait non
	var c_a := {"LeftArm": Vector3(-10, 0, -40), "LeftForeArm": Vector3(-95, 0, 0), "RightArm": Vector3(-10, 0, 40), "RightForeArm": Vector3(-95, 0, 0),
		"Spine02": Vector3(-4, 0, 0), "Head": Vector3(-4, -14, 0)}
	var c_b := lib._merge(c_a, {"Head": Vector3(-4, 14, 0)})
	poses.add_animation("colere", lib._clip(1.0, true, [[0.0, c_a, Vector3.ZERO], [0.25, c_b, Vector3.ZERO], [0.5, c_a, Vector3.ZERO], [0.75, c_b, Vector3.ZERO], [1.0, c_a, Vector3.ZERO]]))
	# mains dans le dos (le collectionneur, le guide)
	var md := {"LeftArm": Vector3(14, 0, -10), "LeftForeArm": Vector3(-70, 0, 0), "RightArm": Vector3(14, 0, 10), "RightForeArm": Vector3(-70, 0, 0), "Spine02": Vector3(-3, 0, 0), "Head": Vector3(-4, 0, 0)}
	var md_b := lib._merge(md, {"Head": Vector3(-2, 10, 0), "Spine02": Vector3(-4, 4, 0)})
	poses.add_animation("mains_dos", lib._clip(5.0, true, [[0.0, md, Vector3.ZERO], [2.5, md_b, Vector3(0, -0.5, 0)], [5.0, md, Vector3.ZERO]]))
	# applaudir
	var ap_a := {"LeftArm": Vector3(-55, 0, 30), "LeftForeArm": Vector3(-60, 0, 0), "RightArm": Vector3(-55, 0, -30), "RightForeArm": Vector3(-60, 0, 0), "Head": Vector3(-6, 0, 0)}
	var ap_b := lib._merge(ap_a, {"LeftArm": Vector3(-55, 0, 18), "RightArm": Vector3(-55, 0, -18)})
	poses.add_animation("applaudir", lib._clip(0.4, true, [[0.0, ap_a, Vector3.ZERO], [0.2, ap_b, Vector3(0, -0.5, 0)], [0.4, ap_a, Vector3.ZERO]]))
	# se cacher (accroupi, les mains sur la tête)
	var ca := {"LeftUpLeg": Vector3(-100, 0, 10), "RightUpLeg": Vector3(-100, 0, -10), "LeftLeg": Vector3(120, 0, 0), "RightLeg": Vector3(120, 0, 0),
		"LeftFoot": Vector3(-20, 0, 0), "RightFoot": Vector3(-20, 0, 0), "Spine02": Vector3(30, 0, 0), "Head": Vector3(20, 0, 0),
		"LeftArm": Vector3(-150, 0, 30), "LeftForeArm": Vector3(-120, 0, 0), "RightArm": Vector3(-150, 0, -30), "RightForeArm": Vector3(-120, 0, 0)}
	poses.add_animation("cache", lib._clip(2.0, true, [[0.0, ca, Vector3(0, -48, 0)], [1.0, ca, Vector3(0, -47, 0)], [2.0, ca, Vector3(0, -48, 0)]]))
	# les pompes (le nœud entier est incliné par plank()) : les bras tendus vers le sol, la tête levée
	var po_a := {"LeftArm": Vector3(-82, 0, 8), "RightArm": Vector3(-82, 0, -8), "LeftForeArm": Vector3(-4, 0, 0), "RightForeArm": Vector3(-4, 0, 0), "Head": Vector3(-25, 0, 0),
		"LeftHand": Vector3(-60, 0, 0), "RightHand": Vector3(-60, 0, 0)}
	var po_b := lib._merge(po_a, {"LeftArm": Vector3(-60, 0, 30), "RightArm": Vector3(-60, 0, -30), "LeftForeArm": Vector3(-55, 0, 0), "RightForeArm": Vector3(-55, 0, 0)})
	poses.add_animation("pompes", lib._clip(1.4, true, [[0.0, po_b, Vector3.ZERO], [0.7, po_a, Vector3.ZERO], [1.4, po_b, Vector3.ZERO]]))
	# le mime coincé dans sa boîte invisible : les mains à plat devant, qui tâtent le mur
	var mi_a := {"LeftArm": Vector3(-80, 0, 10), "LeftForeArm": Vector3(-60, 0, 0), "LeftHand": Vector3(-70, 0, 0), "RightArm": Vector3(-80, 0, -10), "RightForeArm": Vector3(-60, 0, 0), "RightHand": Vector3(-70, 0, 0), "Head": Vector3(0, -10, 0)}
	var mi_b := lib._merge(mi_a, {"LeftArm": Vector3(-110, 0, 30), "RightArm": Vector3(-60, 0, -30), "Head": Vector3(-5, 12, 0), "Spine02": Vector3(0, 8, 0)})
	var mi_c := lib._merge(mi_a, {"LeftArm": Vector3(-60, 0, 30), "RightArm": Vector3(-110, 0, -30), "Head": Vector3(-5, -12, 0), "Spine02": Vector3(0, -8, 0)})
	poses.add_animation("mime", lib._clip(3.0, true, [[0.0, mi_a, Vector3.ZERO], [1.0, mi_b, Vector3.ZERO], [2.0, mi_c, Vector3.ZERO], [3.0, mi_a, Vector3.ZERO]]))
	# montrer du doigt (« là ! »)
	var pt := {"RightArm": Vector3(-88, 0, -10), "RightForeArm": Vector3(-6, 0, 0), "LeftArm": Vector3(0, 0, -13), "LeftForeArm": Vector3(-14, 0, 0), "Head": Vector3(0, 0, 0)}
	poses.add_animation("pointer", lib._clip(2.0, true, [[0.0, pt, Vector3.ZERO], [1.0, lib._merge(pt, {"RightArm": Vector3(-92, 0, -6)}), Vector3.ZERO], [2.0, pt, Vector3.ZERO]]))
	anim.add_animation_library("v81", poses)
	lib.free()

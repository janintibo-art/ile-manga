extends "res://scripts/pnj/pnj_cliquetis_v61.gd"
## V67 : un habitant d'Arcanelle, l'île des sorciers. Même vie réglée par l'heure que les autres
## (pnj_azur_v56.gd ; et les postures « bricoler », « observer » de Cliquetis), avec en plus :
##  - enseigner : un maître devant ses élèves (une main levée, l'autre qui montre, la tête qui va
##    de l'un à l'autre) ;
##  - lancer_sort : les deux mains tendues, une lueur qui naît entre elles et s'en va ;
##  - jardiner : penché sur les carrés de simples, les mains dans la terre ;
##  - pecher : la canne tenue à deux mains, au bout du ponton.
## Et la tenue des sorciers (fiche « arc ») : le bâton noueux au cristal qui luit (les maîtres),
## et pour les anciens corps seulement, le chapeau pointu et la cape (les vrais corps les portent
## déjà : générateur V64, chapeau « ch_sorcier »).

var _glow: MeshInstance3D
var _glow_mat: StandardMaterial3D
var _glow_t: float = 0.0
var _rod: Node3D


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_arc_poses()
	_arc_accessories(data.get("arc", {}))


func _build_arc_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("arc"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# enseigner : la main droite levée, l'index vers le ciel ; la gauche ouverte vers les élèves
	var e_a := {"RightArm": Vector3(-130, 0, 20), "RightForeArm": Vector3(-40, 0, 0), "LeftArm": Vector3(-50, -20, -14), "LeftForeArm": Vector3(-40, 0, 0), "Head": Vector3(-8, -14, 0), "Spine02": Vector3(-2, -6, 0)}
	var e_b := lib._merge(e_a, {"RightArm": Vector3(-100, -10, 26), "RightForeArm": Vector3(-60, 0, 0), "Head": Vector3(-4, 0, 0), "Spine02": Vector3(0, 0, 0)})
	var e_c := {"RightArm": Vector3(-40, 0, 14), "RightForeArm": Vector3(-80, 0, 0), "LeftArm": Vector3(-80, 20, -20), "LeftForeArm": Vector3(-20, 0, 0), "Head": Vector3(-4, 16, 0), "Spine02": Vector3(-2, 8, 0)}
	poses.add_animation("enseigner", lib._clip(7.0, true, [[0.0, e_a, Vector3.ZERO], [1.8, e_a, Vector3.ZERO], [2.6, e_b, Vector3.ZERO], [4.0, e_c, Vector3.ZERO], [5.6, e_c, Vector3.ZERO], [7.0, e_a, Vector3.ZERO]]))
	# lancer un sort : on rassemble les mains, on pousse devant soi, on relâche
	var s_a := {"RightArm": Vector3(-40, 30, 30), "RightForeArm": Vector3(-90, 0, 0), "LeftArm": Vector3(-40, -30, -30), "LeftForeArm": Vector3(-90, 0, 0), "Spine02": Vector3(6, 0, 0), "Head": Vector3(6, 0, 0),
		"LeftUpLeg": Vector3(-10, 0, -4), "LeftLeg": Vector3(14, 0, 0), "RightUpLeg": Vector3(8, 0, 4), "RightLeg": Vector3(6, 0, 0)}
	var s_b := lib._merge(s_a, {"RightArm": Vector3(-85, 10, 14), "RightForeArm": Vector3(-10, 0, 0), "LeftArm": Vector3(-85, -10, -14), "LeftForeArm": Vector3(-10, 0, 0), "Spine02": Vector3(-4, 0, 0), "Head": Vector3(-6, 0, 0)})
	var s_c := lib._merge(s_a, {"RightArm": Vector3(-20, 0, 14), "RightForeArm": Vector3(-30, 0, 0), "LeftArm": Vector3(-20, 0, -14), "LeftForeArm": Vector3(-30, 0, 0), "Spine02": Vector3(0, 0, 0), "Head": Vector3(0, 0, 0)})
	poses.add_animation("lancer_sort", lib._clip(4.0, true, [[0.0, s_c, Vector3.ZERO], [1.2, s_a, Vector3(0, -2, 0)], [2.2, s_a, Vector3(0, -2, 0)], [2.5, s_b, Vector3(0, -1, 0)], [3.2, s_b, Vector3.ZERO], [4.0, s_c, Vector3.ZERO]]))
	# jardiner : penché, les mains vers le sol, qui grattent
	var j_a := {"Spine01": Vector3(30, 0, 0), "Spine02": Vector3(24, 0, 0), "Head": Vector3(10, 0, 0), "RightArm": Vector3(-60, 0, 10), "RightForeArm": Vector3(-30, 0, 0), "LeftArm": Vector3(-56, 0, -10), "LeftForeArm": Vector3(-36, 0, 0),
		"LeftUpLeg": Vector3(-24, 0, 0), "LeftLeg": Vector3(36, 0, 0), "RightUpLeg": Vector3(-24, 0, 0), "RightLeg": Vector3(36, 0, 0)}
	var j_b := lib._merge(j_a, {"RightArm": Vector3(-70, 0, 14), "RightForeArm": Vector3(-14, 0, 0), "LeftForeArm": Vector3(-46, 0, 0)})
	poses.add_animation("jardiner", lib._clip(3.0, true, [[0.0, j_a, Vector3(0, -16, 0)], [0.8, j_b, Vector3(0, -16, 0)], [1.5, j_a, Vector3(0, -16, 0)], [2.2, j_b, Vector3(0, -16, 0)], [3.0, j_a, Vector3(0, -16, 0)]]))
	# pêcher : les deux mains sur la canne, un petit coup de poignet de temps en temps
	var p_a := {"RightArm": Vector3(-50, 10, 16), "RightForeArm": Vector3(-60, 0, 0), "LeftArm": Vector3(-40, -10, -10), "LeftForeArm": Vector3(-70, 0, 0), "Head": Vector3(8, 0, 0)}
	var p_b := lib._merge(p_a, {"RightArm": Vector3(-64, 10, 16), "RightForeArm": Vector3(-50, 0, 0)})
	poses.add_animation("pecher", lib._clip(6.0, true, [[0.0, p_a, Vector3.ZERO], [3.6, p_a, Vector3.ZERO], [3.9, p_b, Vector3.ZERO], [4.4, p_a, Vector3.ZERO], [6.0, p_a, Vector3.ZERO]]))
	anim.add_animation_library("arc", poses)
	lib.free()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"enseigner":
			if dist < 2.5:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("arc/enseigner", 0.5)
		"lancer_sort":
			if dist < 2.5:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
				_set_glow(0.0)
			else:
				_play("arc/lancer_sort", 0.4)
				_tick_glow(delta)
		"jardiner":
			if dist < 2.5:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("arc/jardiner", 0.4)
		"pecher":
			if _rod != null:
				_rod.visible = true
			_play("arc/pecher", 0.4)
		_:
			super._activity(delta, dist, to_player)
	if pose != "lancer_sort" and _glow != null and _glow.visible:
		_set_glow(0.0)
	if pose != "pecher" and _rod != null and _rod.visible:
		_rod.visible = false


## La lueur entre les mains, qui naît, grossit, et s'en va quand les mains se tendent.
func _tick_glow(delta: float) -> void:
	if _glow == null:
		return
	var t: float = anim.current_animation_position if anim != null and anim.current_animation == "arc/lancer_sort" else 0.0
	var k: float = 0.0
	if t > 0.9 and t < 2.5:
		k = smoothstep(0.9, 2.2, t)
	elif t >= 2.5 and t < 3.0:
		k = 1.0 - smoothstep(2.5, 3.0, t)
	_set_glow(k)


func _set_glow(k: float) -> void:
	if _glow == null:
		return
	_glow.visible = k > 0.02
	_glow.scale = Vector3.ONE * (0.4 + k * 0.8)
	_glow_mat.emission_energy_multiplier = 1.0 + k * 3.0


func _arrive() -> void:
	super._arrive()
	if pose == "jardiner" and not hidden_home:
		var sp: Dictionary = azur.spot(target_spot)
		if not sp.is_empty():
			global_position = sp["pos"]


# =================================================================== la tenue

## Fiche "arc" : robe [r,g,b], cape [r,g,b], chapeau [r,g,b], baton (bool), etoiles (bool).
func _arc_accessories(t: Dictionary) -> void:
	if skel == null:
		return
	var nid: String = str(profile.get("id", ""))
	# la lueur des sorts (dans la main droite)
	_glow_mat = StandardMaterial3D.new()
	var gc: Color = {"pyra": Color(1.0, 0.5, 0.15), "boree": Color(0.6, 0.85, 1.0), "zephyrine": Color(0.85, 1.0, 0.95), "sauge": Color(0.55, 1.0, 0.6), "lumen": Color(1.0, 0.92, 0.6)}.get(nid, Color(0.7, 0.55, 1.0))
	_glow_mat.albedo_color = gc
	_glow_mat.emission_enabled = true
	_glow_mat.emission = gc
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow = MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = 0.08
	gs.height = 0.16
	_glow.mesh = gs
	_glow.material_override = _glow_mat
	_glow.visible = false
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gh := Node3D.new()
	gh.add_child(_glow)
	_attach("RightHand", Vector3(0, -9, 6), gh)
	# la canne à pêche (le passeur)
	if nid == "mathurin":
		_rod = Node3D.new()
		_part(_rod, _cyl(0.008, 0.016, 2.2), _mat(Color(0.45, 0.32, 0.18), 0.7), Vector3(0, 1.0, 0))
		_rod.visible = false
		_attach("RightHand", Vector3(0, -6, 2), _rod, Vector3(-60, 0, 0))
	if t.is_empty():
		return
	# le bâton noueux, un cristal au bout
	if bool(t.get("baton", false)):
		var st := Node3D.new()
		var wood := _mat(Color(0.36, 0.24, 0.14), 0.85)
		_part(st, _cyl(0.022, 0.03, 1.7), wood, Vector3(0, 0.2, 0))
		_part(st, _sphere(0.045), wood, Vector3(0, 1.05, 0), Vector3(1.2, 0.8, 1.2))
		var cm := _mat(Color(0.7, 0.55, 1.0), 0.1)
		cm.emission_enabled = true
		cm.emission = Color(0.65, 0.5, 1.0) if nid != "boree" else Color(0.6, 0.85, 1.0)
		cm.emission_energy_multiplier = 1.6
		var cr := CylinderMesh.new()
		cr.top_radius = 0.0
		cr.bottom_radius = 0.05
		cr.height = 0.16
		cr.radial_segments = 6
		_part(st, cr, cm, Vector3(0, 1.17, 0))
		var cr2 := CylinderMesh.new()
		cr2.top_radius = 0.05
		cr2.bottom_radius = 0.0
		cr2.height = 0.08
		cr2.radial_segments = 6
		_part(st, cr2, cm, Vector3(0, 1.05, 0))
		_attach("LeftHand", Vector3(0, -8, 3), st, Vector3(90, 0, 0))
		staff_node = st
	# anciens corps : le chapeau pointu et la cape
	if not v64.is_empty():
		return
	if t.has("chapeau"):
		var c: Array = t["chapeau"]
		var hm := _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.85)
		var hat := Node3D.new()
		_part(hat, _cyl(0.34, 0.34, 0.02), hm, Vector3(0, 0.38, -0.06))
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.2
		cone.height = 0.5
		_part(hat, cone, hm, Vector3(0.0, 0.64, -0.12), Vector3.ONE, Vector3(-14, 0, 0))
		_attach("Head", Vector3(0, 18.0, 2.5), hat)
	if t.has("cape"):
		var c2: Array = t["cape"]
		var capm := _mat(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.9)
		capm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cap := Node3D.new()
		_part(cap, _box_mesh_np(Vector3(0.5, 1.1, 0.02)), capm, Vector3(0, -0.5, -0.16))
		_attach("Spine02", Vector3(0, 6.0, -2.0), cap)

extends "res://scripts/pnj/pnj_azur_v56.gd"
## V57 : un teufeur (ou le DJ) de la plage de l'île du village. Il danse sur place, face au
## mur de son, au tempo du morceau (145 battements par minute, voir teuf_v57.gd) ; quand on
## lui parle, il s'arrête, se tourne vers nous et discute (cerveau pnj_brain_v31), puis
## reprend sa danse. Le DJ, lui, se tient sur son estrade, les mains sur les platines, et
## hoche la tête à chaque temps ; de temps en temps il lève le poing.
## Danses (bibliothèque « teuf ») : saut, balance, bras, hoche, pas, dj, dj_poing.

const BEAT: float = 60.0 / 145.0

var teuf: Node
var dance: String = "teuf_balance"
var dj: bool = false
var focus: Vector3 = Vector3.ZERO           # vers où il danse
var _dj_clock: float = 6.0
var _dj_fist: float = 0.0


func setup_teuf(manager: Node, data: Dictionary, look_at_point: Vector3) -> void:
	teuf = manager
	agenda = []
	dance = str(data.get("danse", "teuf_balance"))
	dj = bool(data.get("dj", false))
	focus = look_at_point
	sleep_far = 90.0
	_rng2.seed = hash(str(data.get("id", "x")))
	if bubble != null:
		bubble.position.y = 2.35
	_build_extra_poses()
	_build_dance_poses()
	_teuf_accessories(data.get("teuf", {}))
	_face_now(focus - global_position)
	_start_dance(true)


func _face_now(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)


# =================================================================== les pas de danse

func _build_dance_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("teuf"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var B: float = BEAT
	var bent := {"LeftUpLeg": Vector3(-20, 0, 0), "LeftLeg": Vector3(30, 0, 0), "RightUpLeg": Vector3(-20, 0, 0), "RightLeg": Vector3(30, 0, 0)}
	var straight := {"LeftUpLeg": Vector3(-4, 0, 0), "LeftLeg": Vector3(6, 0, 0), "RightUpLeg": Vector3(-4, 0, 0), "RightLeg": Vector3(6, 0, 0)}
	# le saut : on plie à chaque temps, un poing en l'air, puis l'autre
	var s_a := lib._merge(bent, {"RightArm": Vector3(-155, 0, 10), "RightForeArm": Vector3(-30, 0, 0), "LeftArm": Vector3(-30, 0, -14), "LeftForeArm": Vector3(-95, 0, 0), "Head": Vector3(12, 0, 0), "Spine02": Vector3(6, 0, 0)})
	var s_b := lib._merge(straight, {"RightArm": Vector3(-172, 0, 6), "RightForeArm": Vector3(-6, 0, 0), "LeftArm": Vector3(-35, 0, -12), "LeftForeArm": Vector3(-100, 0, 0), "Head": Vector3(-4, 0, 0)})
	var s_c := lib._merge(bent, {"LeftArm": Vector3(-155, 0, -10), "LeftForeArm": Vector3(-30, 0, 0), "RightArm": Vector3(-30, 0, 14), "RightForeArm": Vector3(-95, 0, 0), "Head": Vector3(12, 0, 0), "Spine02": Vector3(6, 0, 0)})
	var s_d := lib._merge(straight, {"LeftArm": Vector3(-172, 0, -6), "LeftForeArm": Vector3(-6, 0, 0), "RightArm": Vector3(-35, 0, 12), "RightForeArm": Vector3(-100, 0, 0), "Head": Vector3(-4, 0, 0)})
	poses.add_animation("teuf_saut", lib._clip(2 * B, true, [[0.0, s_a, Vector3(0, -8, 0)], [0.5 * B, s_b, Vector3(0, 2, 0)], [B, s_c, Vector3(0, -8, 0)], [1.5 * B, s_d, Vector3(0, 2, 0)], [2 * B, s_a, Vector3(0, -8, 0)]]))
	# la balance : le corps ondule d'un côté à l'autre, bras pliés, la tête suit
	var b_a := lib._merge(bent, {"Spine02": Vector3(4, 6, 9), "Spine01": Vector3(0, 0, 4), "LeftArm": Vector3(-38, 0, -12), "LeftForeArm": Vector3(-100, 0, 0), "RightArm": Vector3(-30, 0, 16), "RightForeArm": Vector3(-90, 0, 0), "Head": Vector3(10, 0, -8)})
	var b_m := lib._merge(straight, {"Spine02": Vector3(2, 0, 0), "LeftArm": Vector3(-34, 0, -14), "LeftForeArm": Vector3(-96, 0, 0), "RightArm": Vector3(-34, 0, 14), "RightForeArm": Vector3(-96, 0, 0), "Head": Vector3(-2, 0, 0)})
	var b_b := lib._merge(bent, {"Spine02": Vector3(4, -6, -9), "Spine01": Vector3(0, 0, -4), "LeftArm": Vector3(-30, 0, -16), "LeftForeArm": Vector3(-90, 0, 0), "RightArm": Vector3(-38, 0, 12), "RightForeArm": Vector3(-100, 0, 0), "Head": Vector3(10, 0, 8)})
	poses.add_animation("teuf_balance", lib._clip(2 * B, true, [[0.0, b_a, Vector3(-3, -6, 0)], [0.5 * B, b_m, Vector3(0, -1, 0)], [B, b_b, Vector3(3, -6, 0)], [1.5 * B, b_m, Vector3(0, -1, 0)], [2 * B, b_a, Vector3(-3, -6, 0)]]))
	# les bras en l'air, qui se balancent
	var a_a := lib._merge(bent, {"LeftArm": Vector3(-165, 0, -22), "RightArm": Vector3(-165, 0, 22), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-14, 0, 0), "Spine02": Vector3(-4, 0, 7), "Head": Vector3(-10, 0, -5)})
	var a_b := lib._merge(straight, {"LeftArm": Vector3(-172, 0, -10), "RightArm": Vector3(-172, 0, 10), "LeftForeArm": Vector3(-6, 0, 0), "RightForeArm": Vector3(-6, 0, 0), "Spine02": Vector3(-6, 0, 0), "Head": Vector3(-14, 0, 0)})
	var a_c := lib._merge(bent, {"LeftArm": Vector3(-165, 0, -22), "RightArm": Vector3(-165, 0, 22), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-14, 0, 0), "Spine02": Vector3(-4, 0, -7), "Head": Vector3(-10, 0, 5)})
	poses.add_animation("teuf_bras", lib._clip(2 * B, true, [[0.0, a_a, Vector3(0, -6, 0)], [0.5 * B, a_b, Vector3(0, 1, 0)], [B, a_c, Vector3(0, -6, 0)], [1.5 * B, a_b, Vector3(0, 1, 0)], [2 * B, a_a, Vector3(0, -6, 0)]]))
	# le hochement : penché vers les enceintes, la tête frappe chaque temps
	var h_a := lib._merge(bent, {"Spine02": Vector3(24, 0, 0), "Spine01": Vector3(8, 0, 0), "Head": Vector3(30, 0, 0), "LeftArm": Vector3(-24, 0, -10), "LeftForeArm": Vector3(-60, 0, 0), "RightArm": Vector3(-24, 0, 10), "RightForeArm": Vector3(-60, 0, 0)})
	var h_b := lib._merge(bent, {"Spine02": Vector3(16, 0, 0), "Spine01": Vector3(5, 0, 0), "Head": Vector3(-4, 0, 0), "LeftArm": Vector3(-28, 0, -10), "LeftForeArm": Vector3(-70, 0, 0), "RightArm": Vector3(-28, 0, 10), "RightForeArm": Vector3(-70, 0, 0)})
	poses.add_animation("teuf_hoche", lib._clip(B, true, [[0.0, h_a, Vector3(0, -9, 0)], [0.5 * B, h_b, Vector3(0, -5, 0)], [B, h_a, Vector3(0, -9, 0)]]))
	# le pas : un genou, puis l'autre, les bras qui pompent
	var p_a := {"LeftUpLeg": Vector3(-42, 0, 0), "LeftLeg": Vector3(55, 0, 0), "RightUpLeg": Vector3(-8, 0, 0), "RightLeg": Vector3(10, 0, 0),
		"LeftArm": Vector3(-40, 0, -14), "LeftForeArm": Vector3(-110, 0, 0), "RightArm": Vector3(-55, 0, 14), "RightForeArm": Vector3(-80, 0, 0), "Spine02": Vector3(6, 10, 0), "Head": Vector3(6, -6, 0)}
	var p_m := lib._merge(bent, {"LeftArm": Vector3(-45, 0, -14), "LeftForeArm": Vector3(-95, 0, 0), "RightArm": Vector3(-45, 0, 14), "RightForeArm": Vector3(-95, 0, 0), "Spine02": Vector3(4, 0, 0)})
	var p_b := {"RightUpLeg": Vector3(-42, 0, 0), "RightLeg": Vector3(55, 0, 0), "LeftUpLeg": Vector3(-8, 0, 0), "LeftLeg": Vector3(10, 0, 0),
		"RightArm": Vector3(-40, 0, 14), "RightForeArm": Vector3(-110, 0, 0), "LeftArm": Vector3(-55, 0, -14), "LeftForeArm": Vector3(-80, 0, 0), "Spine02": Vector3(6, -10, 0), "Head": Vector3(6, 6, 0)}
	poses.add_animation("teuf_pas", lib._clip(2 * B, true, [[0.0, p_a, Vector3(0, -2, 0)], [0.5 * B, p_m, Vector3(0, -7, 0)], [B, p_b, Vector3(0, -2, 0)], [1.5 * B, p_m, Vector3(0, -7, 0)], [2 * B, p_a, Vector3(0, -2, 0)]]))
	# le DJ : penché sur les platines, les deux mains dessus, la tête bat la mesure
	var d_a := {"Spine02": Vector3(28, 0, 0), "Spine01": Vector3(9, 0, 0), "Head": Vector3(4, 0, 0),
		"LeftArm": Vector3(-62, 0, -8), "LeftForeArm": Vector3(-28, 0, 0), "RightArm": Vector3(-62, 0, 8), "RightForeArm": Vector3(-28, 0, 0),
		"LeftUpLeg": Vector3(-8, 0, 0), "LeftLeg": Vector3(12, 0, 0), "RightUpLeg": Vector3(-8, 0, 0), "RightLeg": Vector3(12, 0, 0)}
	var d_b := lib._merge(d_a, {"Head": Vector3(-8, 0, 0), "RightForeArm": Vector3(-38, 0, 0), "RightArm": Vector3(-58, 6, 10)})
	var d_c := lib._merge(d_a, {"Head": Vector3(4, -10, 0), "LeftForeArm": Vector3(-38, 0, 0), "LeftArm": Vector3(-58, -6, -10)})
	var d_d := lib._merge(d_a, {"Head": Vector3(-8, -10, 0)})
	poses.add_animation("dj", lib._clip(2 * B, true, [[0.0, d_a, Vector3(0, -3, 0)], [0.5 * B, d_b, Vector3(0, 0, 0)], [B, d_c, Vector3(0, -3, 0)], [1.5 * B, d_d, Vector3(0, 0, 0)], [2 * B, d_a, Vector3(0, -3, 0)]]))
	var f_a := lib._merge(d_a, {"RightArm": Vector3(-168, 0, 8), "RightForeArm": Vector3(-20, 0, 0), "Spine02": Vector3(4, 0, 0), "Head": Vector3(-8, 0, 0)})
	var f_b := lib._merge(f_a, {"RightForeArm": Vector3(-45, 0, 0), "Head": Vector3(8, 0, 0)})
	poses.add_animation("dj_poing", lib._clip(B, true, [[0.0, f_a, Vector3(0, -2, 0)], [0.5 * B, f_b, Vector3(0, -4, 0)], [B, f_a, Vector3(0, -2, 0)]]))
	anim.add_animation_library("teuf", poses)
	lib.free()


## Lance la danse, calée sur le temps du morceau (le kick tombe sur la pose « basse »).
func _start_dance(force: bool = false) -> void:
	var clip: String = "teuf/" + ("dj_poing" if dj and _dj_fist > 0.0 else dance)
	if anim == null or not anim.has_animation(clip):
		return
	if current_anim == clip and not force:
		return
	_play(clip, 0.25, 1.0)
	var t: float = teuf.music_time() if teuf != null and teuf.has_method("music_time") else 0.0
	var L: float = anim.get_animation(clip).length
	anim.seek(fmod(t, L), true)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if state == "parle":
		super._process(delta)      # discussion : comme tout le monde (pnj_v31)
		return
	if sleep_far > 0.0:
		var far: bool = global_position.distance_to(main._player_pos_v27()) > sleep_far
		if far != _asleep:
			_asleep = far
			model.visible = not far
			if anim != null:
				if far:
					anim.pause()
				else:
					current_anim = ""
		if far:
			return
	brain.tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	called_clock = maxf(called_clock - delta, 0.0)
	var to_player: Vector3 = main._player_pos_v27() - global_position
	var dist: float = Vector2(to_player.x, to_player.z).length()
	if vr_label != null:
		vr_label.visible = main.xr_active and dist < TALK_REACH
	var near: bool = dist < 8.0 and absf(to_player.y) < 5.0
	if near and not player_was_near and called_clock <= 0.0 and _rng2.randf() < 0.35:
		var line: String = brain.call_out(main._npc_ctx_v31())
		if line != "":
			say_bubble(line, 3.5)
		called_clock = 60.0
	player_was_near = near
	# le DJ lève le poing de temps en temps, sur deux temps
	if dj:
		if _dj_fist > 0.0:
			_dj_fist -= delta
			if _dj_fist <= 0.0:
				_start_dance(true)
		else:
			_dj_clock -= delta
			if _dj_clock <= 0.0:
				_dj_clock = _rng2.randf_range(8.0, 16.0)
				_dj_fist = 4.0 * BEAT
				_start_dance(true)
	# tourné vers la sono (ou vers le joueur qui arrive tout près), il danse
	var want: Vector3 = to_player if (dist < 2.2 and not dj) else (focus - global_position)
	_face(want, delta, 2.5)
	if current_anim == "" or not current_anim.begins_with("teuf/"):
		_start_dance(true)


func end_talk() -> void:
	state = "repos"
	gesture_clock = 0.0
	current_anim = ""


func _pick_destination() -> void:
	pass


# =================================================================== les accessoires de fête

func _teuf_accessories(t: Dictionary) -> void:
	if skel == null or t.is_empty():
		return
	var R: float = 0.228
	if t.has("lunettes_soleil"):
		var g := Node3D.new()
		var black := _mat(Color(0.03, 0.03, 0.05), 0.15)
		black.metallic = 0.6
		black.emission_energy_multiplier = 0.0
		for sx in [-1.0, 1.0]:
			_part(g, _sphere(0.05), black, Vector3(sx * 0.072, 0.008, R - 0.006), Vector3(1.15, 0.8, 0.35))
		_part(g, _box_mesh_np(Vector3(0.06, 0.012, 0.012)), black, Vector3(0, 0.02, R + 0.008))
		for sx2 in [-1.0, 1.0]:
			_part(g, _box_mesh_np(Vector3(0.012, 0.012, 0.2)), black, Vector3(sx2 * 0.2, 0.02, R * 0.45))
		_attach("Head", Vector3(0, 18.0, 2.5), g)
	if t.has("bandana"):
		var c: Array = t["bandana"]
		var bd := Node3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = R * 0.97
		tm.outer_radius = R * 1.07
		_part(bd, tm, _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.8), Vector3(0, 0.1, 0), Vector3(1.0, 1.6, 1.0), Vector3(-12, 0, 0))
		_part(bd, _sphere(0.04), _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.8), Vector3(0, 0.08, -R - 0.02))
		_attach("Head", Vector3(0, 18.0, 2.5), bd)
	if t.has("bonnet"):
		var c2: Array = t["bonnet"]
		var bn := Node3D.new()
		var m2 := _mat(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.95)
		_part(bn, _sphere(R * 1.08), m2, Vector3(0, 0.07, -0.01), Vector3(1.0, 0.8, 1.0))
		var rim := TorusMesh.new()
		rim.inner_radius = R * 0.96
		rim.outer_radius = R * 1.12
		_part(bn, rim, m2, Vector3(0, 0.06, 0), Vector3(1.0, 1.4, 1.0), Vector3(-6, 0, 0))
		_part(bn, _sphere(0.06), _mat(Color(0.95, 0.95, 0.9), 0.95), Vector3(0, 0.28, -0.02))
		_attach("Head", Vector3(0, 18.0, 2.5), bn)
	if t.has("dreads"):
		var c3: Array = t["dreads"]
		var dr := Node3D.new()
		var m3 := _mat(Color(float(c3[0]), float(c3[1]), float(c3[2])), 0.9)
		var k := 0
		for ang in range(100, 261, 16):
			var a: float = deg_to_rad(float(ang))
			for row in [0.06, -0.04]:
				var p := Vector3(sin(a) * R * 1.0, row, cos(a) * R * 1.0)
				var ln: float = 0.34 + 0.08 * float((k * 7) % 3)
				_part(dr, _cyl(0.022, 0.018, ln), m3, p + Vector3(0, -ln * 0.5, 0) + p.normalized() * 0.03, Vector3.ONE, Vector3(sin(a) * -8.0, 0, cos(a) * 8.0))
				k += 1
		_attach("Head", Vector3(0, 18.0, 2.5), dr)
	if t.has("casque"):
		var c4: Array = t["casque"]
		var hp := Node3D.new()
		var m4 := _mat(Color(float(c4[0]), float(c4[1]), float(c4[2])), 0.4)
		var arc := TorusMesh.new()
		arc.inner_radius = R * 1.12
		arc.outer_radius = R * 1.22
		_part(hp, arc, m4, Vector3(0, 0.02, 0), Vector3(1.0, 1.0, 0.7), Vector3(0, 0, 90))
		for sx3 in [-1.0, 1.0]:
			_part(hp, _cyl(0.085, 0.085, 0.07), m4, Vector3(sx3 * (R + 0.03), -0.01, 0), Vector3.ONE, Vector3(0, 0, 90))
			_part(hp, _cyl(0.06, 0.06, 0.02), _mat(Color(0.85, 0.2, 0.15), 0.5), Vector3(sx3 * (R + 0.07), -0.01, 0), Vector3.ONE, Vector3(0, 0, 90))
		_attach("Head", Vector3(0, 18.0, 2.5), hp)
	if t.has("batons"):
		var c5: Array = t["batons"]
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(float(c5[0]), float(c5[1]), float(c5[2]))
		glow.emission_enabled = true
		glow.emission = Color(float(c5[0]), float(c5[1]), float(c5[2]))
		glow.emission_energy_multiplier = 3.0
		for hand in ["LeftHand", "RightHand"]:
			var st := Node3D.new()
			var mi := MeshInstance3D.new()
			mi.mesh = _cyl(0.012, 0.012, 0.2)
			mi.material_override = glow
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			st.add_child(mi)
			_attach(hand, Vector3(0, 9.0, 2.0), st, Vector3(70, 0, 0))

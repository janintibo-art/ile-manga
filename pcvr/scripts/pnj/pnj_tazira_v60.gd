extends "res://scripts/pnj/pnj_azur_v56.gd"
## V60 : un habitant de Tazira (le port berbère du sud de la grande île), ou un pirate de la
## Murène Noire. Même vie réglée par l'heure que ceux de Port-Azur (pnj_azur_v56.gd), avec
## des postures en plus :
##  - danse : à la fête du soir, sur la place des Lanternes (pas chassés, épaules, mains qui
##    frappent, au tempo de la musique de la fête : 116 battements par minute) ;
##  - crier : le crieur de la criée et les marchands du souk qui appellent le client
##    (un bras tendu, puis l'autre, la tête qui va de l'un à l'autre) ;
##  - tambour : assis, le bendir sur la cuisse, les mains qui frappent.
## Et des tenues : turban, fez, foulard de tête, djellaba (robe longue), et pour les pirates :
## tricorne, bandana, bandeau sur l'œil, anneau d'or à l'oreille, perroquet sur l'épaule.

const BEAT_TZ: float = 60.0 / 116.0

var _tz_built: bool = false


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_tz_poses()
	_tz_accessories(data.get("tz", {}))


# =================================================================== postures

func _build_tz_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("tz"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var B: float = BEAT_TZ
	var bent := {"LeftUpLeg": Vector3(-16, 0, 0), "LeftLeg": Vector3(24, 0, 0), "RightUpLeg": Vector3(-16, 0, 0), "RightLeg": Vector3(24, 0, 0)}
	var straight := {"LeftUpLeg": Vector3(-3, 0, 0), "LeftLeg": Vector3(5, 0, 0), "RightUpLeg": Vector3(-3, 0, 0), "RightLeg": Vector3(5, 0, 0)}
	# la danse des épaules : on plie, les épaules roulent, les mains à hauteur de poitrine
	var e_a := lib._merge(bent, {"Spine02": Vector3(4, 10, 6), "LeftArm": Vector3(-50, 0, -20), "LeftForeArm": Vector3(-110, 0, 0), "RightArm": Vector3(-40, 0, 26), "RightForeArm": Vector3(-100, 0, 0), "Head": Vector3(6, -8, -6)})
	var e_b := lib._merge(straight, {"Spine02": Vector3(2, 0, 0), "LeftArm": Vector3(-46, 0, -22), "LeftForeArm": Vector3(-104, 0, 0), "RightArm": Vector3(-46, 0, 22), "RightForeArm": Vector3(-104, 0, 0), "Head": Vector3(-4, 0, 0)})
	var e_c := lib._merge(bent, {"Spine02": Vector3(4, -10, -6), "LeftArm": Vector3(-40, 0, -26), "LeftForeArm": Vector3(-100, 0, 0), "RightArm": Vector3(-50, 0, 20), "RightForeArm": Vector3(-110, 0, 0), "Head": Vector3(6, 8, 6)})
	poses.add_animation("epaules", lib._clip(2 * B, true, [[0.0, e_a, Vector3(-2, -5, 0)], [0.5 * B, e_b, Vector3(0, 0, 0)], [B, e_c, Vector3(2, -5, 0)], [1.5 * B, e_b, Vector3(0, 0, 0)], [2 * B, e_a, Vector3(-2, -5, 0)]]))
	# les mains qui frappent au-dessus de la tête, un pied qui marque le temps
	var c_a := lib._merge(straight, {"LeftArm": Vector3(-150, 0, -14), "RightArm": Vector3(-150, 0, 14), "LeftForeArm": Vector3(-40, 0, 0), "RightForeArm": Vector3(-40, 0, 0), "Head": Vector3(-8, 0, 0)})
	var c_b := lib._merge(bent, {"LeftArm": Vector3(-160, 0, -4), "RightArm": Vector3(-160, 0, 4), "LeftForeArm": Vector3(-26, 0, 0), "RightForeArm": Vector3(-26, 0, 0), "Head": Vector3(-2, 0, 0),
		"LeftUpLeg": Vector3(-30, 0, 0), "LeftLeg": Vector3(40, 0, 0)})
	poses.add_animation("mains", lib._clip(B, true, [[0.0, c_a, Vector3(0, 0, 0)], [0.5 * B, c_b, Vector3(0, -5, 0)], [B, c_a, Vector3(0, 0, 0)]]))
	# le pas chassé : de côté, les bras ouverts, le buste qui tourne
	var p_a := {"LeftUpLeg": Vector3(-6, 0, -14), "LeftLeg": Vector3(10, 0, 0), "RightUpLeg": Vector3(-20, 0, 4), "RightLeg": Vector3(32, 0, 0),
		"LeftArm": Vector3(-60, 0, -50), "LeftForeArm": Vector3(-40, 0, 0), "RightArm": Vector3(-60, 0, 50), "RightForeArm": Vector3(-40, 0, 0), "Spine02": Vector3(4, 14, 0), "Head": Vector3(0, -10, 0)}
	var p_b := lib._merge(bent, {"LeftArm": Vector3(-70, 0, -40), "LeftForeArm": Vector3(-50, 0, 0), "RightArm": Vector3(-70, 0, 40), "RightForeArm": Vector3(-50, 0, 0), "Spine02": Vector3(4, 0, 0)})
	var p_c := {"RightUpLeg": Vector3(-6, 0, 14), "RightLeg": Vector3(10, 0, 0), "LeftUpLeg": Vector3(-20, 0, -4), "LeftLeg": Vector3(32, 0, 0),
		"LeftArm": Vector3(-60, 0, -50), "LeftForeArm": Vector3(-40, 0, 0), "RightArm": Vector3(-60, 0, 50), "RightForeArm": Vector3(-40, 0, 0), "Spine02": Vector3(4, -14, 0), "Head": Vector3(0, 10, 0)}
	poses.add_animation("chasse", lib._clip(2 * B, true, [[0.0, p_a, Vector3(-6, -2, 0)], [0.5 * B, p_b, Vector3(0, -6, 0)], [B, p_c, Vector3(6, -2, 0)], [1.5 * B, p_b, Vector3(0, -6, 0)], [2 * B, p_a, Vector3(-6, -2, 0)]]))
	# le crieur : un bras tendu vers les acheteurs, puis l'autre, la tête suit
	var k_a := {"RightArm": Vector3(-95, -30, 10), "RightForeArm": Vector3(-20, 0, 0), "LeftArm": Vector3(-20, 0, -8), "LeftForeArm": Vector3(-60, 0, 0), "Head": Vector3(-6, -18, 0), "Spine02": Vector3(-2, -10, 0)}
	var k_b := {"RightArm": Vector3(-40, 0, 12), "RightForeArm": Vector3(-90, 0, 0), "LeftArm": Vector3(-40, 0, -12), "LeftForeArm": Vector3(-90, 0, 0), "Head": Vector3(-4, 0, 0)}
	var k_c := {"LeftArm": Vector3(-95, 30, -10), "LeftForeArm": Vector3(-20, 0, 0), "RightArm": Vector3(-20, 0, 8), "RightForeArm": Vector3(-60, 0, 0), "Head": Vector3(-6, 18, 0), "Spine02": Vector3(-2, 10, 0)}
	poses.add_animation("crier", lib._clip(4.0, true, [[0.0, k_a, Vector3.ZERO], [1.2, k_a, Vector3.ZERO], [2.0, k_b, Vector3.ZERO], [2.8, k_c, Vector3.ZERO], [3.6, k_b, Vector3.ZERO], [4.0, k_a, Vector3.ZERO]]))
	# le tambour : assis, le bendir tenu à gauche, la droite frappe, la gauche roule
	var seated := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0), "Spine02": Vector3(6, 0, 0)}
	var t_a := lib._merge(seated, {"LeftArm": Vector3(-50, 20, -30), "LeftForeArm": Vector3(-80, 0, 0), "RightArm": Vector3(-36, 0, 20), "RightForeArm": Vector3(-70, 0, 0), "Head": Vector3(10, 8, 0)})
	var t_b := lib._merge(t_a, {"RightForeArm": Vector3(-96, 0, 0), "LeftForeArm": Vector3(-86, 0, 0), "Head": Vector3(14, 6, 0)})
	poses.add_animation("tambour", lib._clip(B, true, [[0.0, t_a, Vector3(0, -38, 0)], [0.25 * B, t_b, Vector3(0, -38, 0)], [0.5 * B, t_a, Vector3(0, -38, 0)], [0.75 * B, t_b, Vector3(0, -38, 0)], [B, t_a, Vector3(0, -38, 0)]]))
	anim.add_animation_library("tz", poses)
	lib.free()


func _arrive() -> void:
	super._arrive()
	if pose == "en_mer":
		_set_hidden(true)
		return
	if pose == "tambour" and not hidden_home:
		var sp: Dictionary = azur.spot(target_spot)
		if not sp.is_empty():
			global_position = sp["pos"]
			_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"danse":
			_gest -= delta
			if _gest <= 0.0 or current_anim == "" or not current_anim.begins_with("tz/"):
				_gest = _rng2.randf_range(10.0, 20.0)
				var clips := ["tz/epaules", "tz/mains", "tz/chasse"]
				var c: String = str(clips[_rng2.randi() % clips.size()])
				_play(c, 0.4, 1.0)
				if anim != null and anim.has_animation(c):
					var t: float = Time.get_ticks_msec() * 0.001
					anim.seek(fmod(t, anim.get_animation(c).length), true)
			if dist < 2.2:
				_face(to_player, delta, 2.0)
		"crier":
			if dist < 3.0:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("tz/crier", 0.4)
		"tambour":
			_play("tz/tambour", 0.3)
		_:
			super._activity(delta, dist, to_player)


func end_talk() -> void:
	super.end_talk()
	if pose == "tambour":
		_arrive()


# =================================================================== tenues

## Fiche "tz" : turban [r,g,b], fez, foulard_tete [r,g,b], tricorne [r,g,b], bandana [r,g,b],
## cache_oeil, boucle, perroquet, sabre.
func _tz_accessories(t: Dictionary) -> void:
	if skel == null or t.is_empty():
		return
	var R: float = 0.228
	if t.has("turban"):
		var c: Array = t["turban"]
		var m := _mat(Color(float(c[0]), float(c[1]), float(c[2])), 0.9)
		var tb := Node3D.new()
		for k in range(3):
			var tm := TorusMesh.new()
			tm.inner_radius = R * (0.92 - k * 0.12)
			tm.outer_radius = R * (1.18 - k * 0.14)
			_part(tb, tm, m, Vector3(0, 0.1 + k * 0.07, -0.01), Vector3(1.0, 1.5, 1.0), Vector3(-8 + k * 6, k * 30, 0))
		_part(tb, _sphere(R * 0.7), m, Vector3(0, 0.22, -0.01), Vector3(1.0, 0.6, 1.0))
		_attach("Head", Vector3(0, 18.0, 2.5), tb)
	if t.has("fez"):
		var fz := Node3D.new()
		_part(fz, _cyl(0.15, 0.18, 0.2), _mat(Color(0.62, 0.08, 0.1), 0.7), Vector3(0, 0.43, -0.07))
		_part(fz, _cyl(0.006, 0.006, 0.14), _mat(Color(0.08, 0.06, 0.05)), Vector3(0.07, 0.55, -0.09), Vector3.ONE, Vector3(0, 0, -40))
		_attach("Head", Vector3(0, 18.0, 2.5), fz)
	if t.has("foulard_tete"):
		var c2: Array = t["foulard_tete"]
		var m2 := _mat(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.9)
		var ft := Node3D.new()
		_part(ft, _sphere(0.29), m2, Vector3(0, 0.12, -0.1), Vector3(1.24, 1.08, 1.02))
		_part(ft, _sphere(R * 1.1), m2, Vector3(0, -0.22, -0.14), Vector3(1.2, 1.0, 0.6))
		_attach("Head", Vector3(0, 18.0, 2.5), ft)
	if t.has("tricorne"):
		var c3: Array = t["tricorne"]
		var m3 := _mat(Color(float(c3[0]), float(c3[1]), float(c3[2])), 0.8)
		var tr := Node3D.new()
		_part(tr, _cyl(0.19, 0.22, 0.16), m3, Vector3(0, 0.44, -0.08))
		for k2 in range(3):
			var a: float = TAU * k2 / 3.0
			_part(tr, _box_mesh_np(Vector3(0.46, 0.15, 0.03)), m3, Vector3(sin(a) * 0.25, 0.42, cos(a) * 0.25 - 0.08), Vector3.ONE, Vector3(-14, rad_to_deg(a), 0))
		_part(tr, _box_mesh_np(Vector3(0.38, 0.025, 0.02)), _mat(Color(0.85, 0.68, 0.25), 0.3), Vector3(0, 0.49, 0.175))
		_attach("Head", Vector3(0, 18.0, 2.5), tr)
	if t.has("bandana"):
		var c4: Array = t["bandana"]
		var bd := Node3D.new()
		var m4 := _mat(Color(float(c4[0]), float(c4[1]), float(c4[2])), 0.85)
		_part(bd, _sphere(0.285), m4, Vector3(0, 0.12, -0.095), Vector3(1.22, 1.06, 1.0))
		_part(bd, _sphere(0.06), m4, Vector3(0.07, 0.08, -0.4))
		_part(bd, _box_mesh_np(Vector3(0.06, 0.18, 0.014)), m4, Vector3(0.09, -0.04, -0.41), Vector3.ONE, Vector3(0, 0, 12))
		_attach("Head", Vector3(0, 18.0, 2.5), bd)
	if t.has("cache_oeil"):
		var eye := Node3D.new()
		var black := _mat(Color(0.03, 0.03, 0.03), 0.6)
		_part(eye, _sphere(0.042), black, Vector3(-0.072, 0.006, R - 0.006), Vector3(1.1, 1.0, 0.3))
		var band := TorusMesh.new()
		band.inner_radius = R * 1.0
		band.outer_radius = R * 1.04
		_part(eye, band, black, Vector3(0, 0.03, 0), Vector3(1.0, 1.0, 1.0), Vector3(-10, 0, -12))
		_attach("Head", Vector3(0, 18.0, 2.5), eye)
	if t.has("boucle"):
		var ring := Node3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = 0.018
		tm2.outer_radius = 0.026
		var gold := _mat(Color(0.95, 0.75, 0.3), 0.25)
		gold.metallic = 0.9
		_part(ring, tm2, gold, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
		_attach("Head", Vector3(23.0, 12.0, 3.0), ring)
	if t.has("perroquet"):
		var pq := Node3D.new()
		var red := _mat(Color(0.85, 0.12, 0.08), 0.6)
		var blue := _mat(Color(0.1, 0.35, 0.85), 0.6)
		var yellow := _mat(Color(0.98, 0.8, 0.15), 0.6)
		_part(pq, _sphere(0.07), red, Vector3(0, 0.08, 0), Vector3(0.9, 1.5, 1.0))
		_part(pq, _sphere(0.05), red, Vector3(0, 0.2, 0.02))
		_part(pq, _cyl(0.0, 0.018, 0.05), yellow, Vector3(0, 0.19, 0.07), Vector3.ONE, Vector3(80, 0, 0))
		for sx in [-1.0, 1.0]:
			_part(pq, _sphere(0.045), blue, Vector3(sx * 0.05, 0.07, -0.01), Vector3(0.4, 1.4, 1.0))
		_part(pq, _box_mesh_np(Vector3(0.04, 0.16, 0.02)), blue, Vector3(0, -0.06, -0.05), Vector3.ONE, Vector3(-20, 0, 0))
		_attach("RightShoulder", Vector3(0, 8.0, 0.0), pq)
	if t.has("sabre"):
		var sb := Node3D.new()
		var steel := _mat(Color(0.75, 0.77, 0.8), 0.25)
		steel.metallic = 0.85
		_part(sb, _box_mesh_np(Vector3(0.025, 0.7, 0.05)), steel, Vector3(0, -0.35, 0), Vector3.ONE, Vector3(0, 0, 8))
		_part(sb, _box_mesh_np(Vector3(0.12, 0.02, 0.06)), _mat(Color(0.8, 0.62, 0.25), 0.3), Vector3(0, 0.02, 0))
		_attach("Hips", Vector3(-18.0, 0.0, 4.0), sb, Vector3(0, 0, -15))

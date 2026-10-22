extends "res://scripts/pnj/pnj_cliquetis_v61.gd"
## V62 : un habitant de Ramure, le village des oreilles. Même vie réglée par l'heure que les
## autres (pnj_azur_v56.gd ; postures de Tazira et de Cliquetis), mais ils ont des oreilles et
## une queue d'animal : renard, loup, chat, lapin, ours, tanuki, chouette, écureuil, biche.
##  - la queue se balance doucement (plus vite quand ils sont contents de vous voir), les
##    oreilles frémissent de temps en temps ;
##  - la nuit, le bout des oreilles et de la queue luit doucement (« les oreilles de lune ») ;
##  - pecher : assis au bord de la mare, la canne tendue ;
##  - la Grande Course : le village leur donne un parcours et une allure, ils courent
##    (start_race), puis reprennent leur journée.

## Fiche "kemo" : espece, poil [r,g,b], pointe [r,g,b] (le bout de la queue / des oreilles),
## interieur [r,g,b] (l'intérieur des oreilles), oreille_tombante (lapin), queue (0..1.5).
var _ears: Array = []                  # [nœud, côté]
var _tail: Node3D
var _tail_amp: float = 0.25
var _tail_speed: float = 1.6
var _glow_mats: Array = []
var _glow_now: float = 0.35
var _glow_check: float = 0.0
var _twitch_t: float = 3.0
var _twitch: float = 0.0
var _kemo_clock: float = 0.0
var espece: String = ""
var _rod: Node3D
var _flute: Node3D

# la course
var _race: Array = []                  # les points du parcours (monde)
var _race_i: int = 0
var _race_speed: float = 3.0
var _race_burst: float = 0.0           # mètres de départ « en sprint »
var _race_dist: float = 0.0
var _race_done: Callable
var racing: bool = false


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_rm_poses()
	_kemo(data.get("kemo", {}))
	_kemo_clock = _rng2.randf() * 10.0


func _build_rm_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("rm"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# pêcher : assis au bord, les deux mains tendues sur la canne, la tête qui guette le bouchon
	var seated := {"LeftUpLeg": Vector3(-80, 0, 8), "RightUpLeg": Vector3(-80, 0, -8), "LeftLeg": Vector3(70, 0, 0), "RightLeg": Vector3(70, 0, 0), "Spine02": Vector3(8, 0, 0)}
	var f_a := lib._merge(seated, {"RightArm": Vector3(-62, 0, 8), "RightForeArm": Vector3(-36, 0, 0), "LeftArm": Vector3(-58, 0, -6), "LeftForeArm": Vector3(-44, 0, 0), "Head": Vector3(14, 0, 0)})
	var f_b := lib._merge(f_a, {"Head": Vector3(10, 10, 0), "RightArm": Vector3(-66, 0, 8)})
	var f_c := lib._merge(f_a, {"RightArm": Vector3(-80, 0, 8), "RightForeArm": Vector3(-20, 0, 0), "Head": Vector3(6, 0, 0)})
	poses.add_animation("pecher", lib._clip(12.0, true, [[0.0, f_a, Vector3(0, -38, 0)], [4.0, f_b, Vector3(0, -38, 0)], [8.0, f_a, Vector3(0, -38, 0)], [9.0, f_c, Vector3(0, -38, 0)], [10.0, f_a, Vector3(0, -38, 0)], [12.0, f_a, Vector3(0, -38, 0)]]))
	# le taiko : debout, un peu fléchi, les deux baguettes frappent tour à tour
	var bent := {"LeftUpLeg": Vector3(-14, 0, 6), "RightUpLeg": Vector3(-14, 0, -6), "LeftLeg": Vector3(22, 0, 0), "RightLeg": Vector3(22, 0, 0), "Spine02": Vector3(8, 0, 0), "Head": Vector3(6, 0, 0)}
	var r_up := lib._merge(bent, {"RightArm": Vector3(-140, 0, 14), "RightForeArm": Vector3(-28, 0, 0), "LeftArm": Vector3(-72, 0, -12), "LeftForeArm": Vector3(-58, 0, 0)})
	var r_hit := lib._merge(bent, {"RightArm": Vector3(-72, 0, 12), "RightForeArm": Vector3(-52, 0, 0), "LeftArm": Vector3(-96, 0, -12), "LeftForeArm": Vector3(-46, 0, 0)})
	var l_up := lib._merge(bent, {"LeftArm": Vector3(-140, 0, -14), "LeftForeArm": Vector3(-28, 0, 0), "RightArm": Vector3(-72, 0, 12), "RightForeArm": Vector3(-58, 0, 0)})
	var l_hit := lib._merge(bent, {"LeftArm": Vector3(-72, 0, -12), "LeftForeArm": Vector3(-52, 0, 0), "RightArm": Vector3(-96, 0, 12), "RightForeArm": Vector3(-46, 0, 0)})
	var dip := Vector3(0, -5, 0)
	poses.add_animation("taiko", lib._clip(1.0, true, [[0.0, r_up, dip], [0.22, r_hit, dip], [0.5, l_up, dip], [0.72, l_hit, dip], [1.0, r_up, dip]]))
	# la flûte : assis, les deux mains à droite de la bouche, la tête qui suit la mélodie
	var sit2 := {"LeftUpLeg": Vector3(-88, 0, 6), "RightUpLeg": Vector3(-88, 0, -6), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(85, 0, 0), "Spine02": Vector3(4, 0, 0)}
	var fl_a := lib._merge(sit2, {"RightArm": Vector3(-62, -40, 30), "RightForeArm": Vector3(-118, 0, 0), "LeftArm": Vector3(-58, -34, -4), "LeftForeArm": Vector3(-122, 0, 0), "Head": Vector3(4, -14, 6)})
	var fl_b := lib._merge(fl_a, {"Head": Vector3(-4, -10, 10), "Spine02": Vector3(-2, 4, 0)})
	poses.add_animation("flute", lib._clip(4.0, true, [[0.0, fl_a, Vector3(0, -38, 0)], [2.0, fl_b, Vector3(0, -38, 0)], [4.0, fl_a, Vector3(0, -38, 0)]]))
	anim.add_animation_library("rm", poses)
	lib.free()


# =================================================================== oreilles et queue

func _kemo(k: Dictionary) -> void:
	if skel == null or k.is_empty():
		return
	espece = str(k.get("espece", "renard"))
	var fur: Color = _col(k.get("poil", [0.8, 0.45, 0.2]))
	var tip: Color = _col(k.get("pointe", [0.95, 0.93, 0.9]))
	var inner: Color = _col(k.get("interieur", [0.98, 0.82, 0.78]))
	var m_fur := _mat(fur, 0.85)
	var m_inner := _mat(inner, 0.8)
	var m_tip := _mat(tip, 0.8)
	_glow_mats = [[m_inner, inner], [m_tip, tip]]
	var big: float = float(k.get("queue", 1.0))
	match espece:
		"renard", "loup", "chat", "ecureuil":
			var h: float = {"renard": 0.23, "loup": 0.2, "chat": 0.16, "ecureuil": 0.15}[espece]
			var r: float = {"renard": 0.09, "loup": 0.095, "chat": 0.085, "ecureuil": 0.06}[espece]
			for sx in [-1.0, 1.0]:
				var e := Node3D.new()
				_part(e, _cyl(0.0, r, h), m_fur, Vector3(0, h * 0.5, 0), Vector3(1.0, 1.0, 0.45))
				_part(e, _cyl(0.0, r * 0.62, h * 0.78), m_inner, Vector3(0, h * 0.42, 0.022), Vector3(1.0, 1.0, 0.3))
				if espece == "renard":
					_part(e, _cyl(0.0, r * 0.42, h * 0.3), m_tip if k.has("pointe") else _mat(Color(0.12, 0.08, 0.06)), Vector3(0, h * 0.86, 0.004), Vector3(1.0, 1.0, 0.5))
				if espece == "ecureuil":
					_part(e, _cyl(0.0, 0.025, 0.08), m_fur, Vector3(0, h + 0.03, 0))
				_ear(e, sx, Vector3(sx * 0.165, 0.3, -0.03), Vector3(-8, 0, -sx * 18))
		"lapin":
			for sx in [-1.0, 1.0]:
				var e2 := Node3D.new()
				_part(e2, _sphere(0.075), m_fur, Vector3(0, 0.2, 0), Vector3(0.75, 2.9, 0.38))
				_part(e2, _sphere(0.06), m_inner, Vector3(0, 0.2, 0.018), Vector3(0.6, 2.5, 0.2))
				var droop: bool = bool(k.get("oreille_tombante", false)) and sx > 0.0
				_ear(e2, sx, Vector3(sx * 0.1, 0.32, -0.04), Vector3(-6 if not droop else 40, 0, -sx * (8 if not droop else 70)))
		"ours", "tanuki":
			var rr: float = 0.075 if espece == "ours" else 0.06
			for sx in [-1.0, 1.0]:
				var e3 := Node3D.new()
				_part(e3, _sphere(rr), m_fur, Vector3(0, rr * 0.6, 0), Vector3(1.0, 1.0, 0.55))
				_part(e3, _sphere(rr * 0.6), m_inner, Vector3(0, rr * 0.6, 0.025), Vector3(1.0, 1.0, 0.3))
				_ear(e3, sx, Vector3(sx * 0.2, 0.29, -0.02), Vector3(0, 0, -sx * 25))
		"chouette":
			for sx in [-1.0, 1.0]:
				var e4 := Node3D.new()
				for j in range(3):
					_part(e4, _cyl(0.0, 0.03, 0.17 - j * 0.03), m_fur if j > 0 else m_tip, Vector3(sx * j * 0.025, 0.08, -j * 0.02), Vector3(1.0, 1.0, 0.4), Vector3(0, 0, -sx * (10 + j * 8)))
				_ear(e4, sx, Vector3(sx * 0.15, 0.3, 0.0), Vector3(-20, 0, -sx * 35))
		"biche":
			for sx in [-1.0, 1.0]:
				var e5 := Node3D.new()
				_part(e5, _sphere(0.07), m_fur, Vector3(sx * 0.09, 0.0, 0), Vector3(1.9, 0.75, 0.32))
				_part(e5, _sphere(0.055), m_inner, Vector3(sx * 0.09, 0.0, 0.02), Vector3(1.7, 0.6, 0.18))
				_ear(e5, sx, Vector3(sx * 0.2, 0.18, -0.02), Vector3(0, 0, -sx * 20))
	# la queue
	_tail = Node3D.new()
	var tl := Node3D.new()
	_tail.add_child(tl)
	match espece:
		"renard", "loup", "ecureuil":
			var up: float = {"renard": 0.55, "loup": -0.25, "ecureuil": 0.95}[espece]
			var R: float = {"renard": 0.11, "loup": 0.1, "ecureuil": 0.12}[espece] * big
			var n: int = 5
			for i in range(n):
				var t: float = float(i) / (n - 1)
				var p := Vector3(0, up * 0.5 * t * t + (0.2 * t * t if espece == "ecureuil" else 0.0), -0.1 - 0.42 * t * (0.7 if espece == "ecureuil" else 1.0))
				if espece == "ecureuil":
					# la queue en panache remonte dans le dos et s'enroule vers l'arrière
					p.z += sin(t * PI) * -0.12 + t * t * 0.06
				var rad: float = R * (0.6 + 0.7 * sin(t * PI * 0.85 + 0.25))
				_part(tl, _sphere(rad), m_tip if (i == n - 1 and espece != "loup") else m_fur, p, Vector3(1.0, 1.0, 1.35))
			_tail_amp = 0.3
			_tail_speed = 1.4
		"chat":
			var prev := Vector3(0, 0, -0.08)
			for i in range(8):
				var t2: float = float(i) / 7.0
				var p2 := Vector3(0, 0.36 * t2 * t2, -0.08 - 0.28 * t2 + 0.08 * t2 * t2 * t2)
				_part(tl, _sphere(0.04 - t2 * 0.008), m_tip if i == 7 else m_fur, p2)
				prev = p2
			_tail_amp = 0.5
			_tail_speed = 1.1
		"lapin", "biche":
			_part(tl, _sphere(0.075 if espece == "lapin" else 0.05), m_tip, Vector3(0, 0.02, -0.09))
			_tail_amp = 0.12
			_tail_speed = 4.0
		"ours":
			_part(tl, _sphere(0.06), m_fur, Vector3(0, 0.0, -0.08))
			_tail_amp = 0.08
		"tanuki":
			for i3 in range(4):
				var t3: float = float(i3) / 3.0
				var dark: bool = i3 % 2 == 1
				_part(tl, _sphere(0.1 - t3 * 0.02), _mat(Color(0.18, 0.13, 0.1), 0.85) if dark else m_fur, Vector3(0, -0.06 * t3, -0.1 - 0.12 * i3), Vector3(1.0, 1.0, 1.2))
			_tail_amp = 0.2
		"chouette":
			for j2 in range(5):
				var a: float = (j2 - 2) * 16.0
				_part(tl, _box_mesh_np(Vector3(0.07, 0.012, 0.26)), m_fur if j2 != 2 else m_tip, Vector3(sin(deg_to_rad(a)) * 0.08, -0.04, -0.17), Vector3.ONE, Vector3(-25, a, 0))
			_tail_amp = 0.06
	_attach("Hips", Vector3(0, 2.0, -11.0), _tail)


func _col(c: Variant) -> Color:
	var a: Array = c
	return Color(float(a[0]), float(a[1]), float(a[2]))


func _ear(node: Node3D, side: float, at: Vector3, rot_deg: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees = rot_deg
	holder.add_child(node)
	var wrap := Node3D.new()
	wrap.add_child(holder)
	_attach("Head", Vector3(0, 18.0, 2.5), wrap)
	_ears.append([holder, side, rot_deg])


func _tick_kemo(delta: float) -> void:
	if _tail == null or hidden_home or _asleep:
		return
	_kemo_clock += delta
	var happy: float = 1.0
	if state == "parle":
		happy = 2.2
	elif racing:
		happy = 3.0
	_tail.rotation.y = sin(_kemo_clock * _tail_speed * happy) * _tail_amp
	_tail.rotation.x = sin(_kemo_clock * _tail_speed * 0.5) * _tail_amp * 0.25
	_twitch_t -= delta
	if _twitch_t <= 0.0:
		_twitch_t = _rng2.randf_range(2.5, 8.0)
		_twitch = 0.25
	if _twitch > 0.0:
		_twitch = maxf(0.0, _twitch - delta)
		var w: float = sin((0.25 - _twitch) / 0.25 * PI) * 14.0
		for e in _ears:
			var r0: Vector3 = e[2]
			(e[0] as Node3D).rotation_degrees = r0 + Vector3(-w * 0.5, 0, -float(e[1]) * w)
	_glow_check -= delta
	if _glow_check <= 0.0:
		_glow_check = 1.0
		var h: float = float(azur.hour()) if azur != null else 12.0
		var night: bool = h >= 20.0 or h < 5.0
		var want: float = 2.2 if night else 0.35
		if absf(want - _glow_now) > 0.01:
			_glow_now = move_toward(_glow_now, want, 0.6)
			var k: float = clampf((_glow_now - 0.35) / 1.85, 0.0, 1.0)
			for gm in _glow_mats:
				var m: StandardMaterial3D = gm[0]
				m.emission_energy_multiplier = _glow_now
				m.emission = (gm[1] as Color).lerp(Color(0.72, 0.86, 1.0), k)


# =================================================================== la canne à pêche

func _arrive() -> void:
	super._arrive()
	_show_rod(pose == "pecher" and not hidden_home)
	_show_flute(pose == "flute" and not hidden_home)
	if pose in ["pecher", "flute"] and not hidden_home:
		var sp: Dictionary = azur.spot(target_spot)
		if not sp.is_empty():
			global_position = sp["pos"]
			_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _show_rod(on: bool) -> void:
	if on and _rod == null and skel != null:
		_rod = Node3D.new()
		_part(_rod, _cyl(0.008, 0.018, 2.2), _mat(Color(0.55, 0.42, 0.22), 0.6), Vector3(0, 1.1, 0))
		_part(_rod, _cyl(0.002, 0.002, 1.6), _mat(Color(0.9, 0.9, 0.9), 0.5), Vector3(0, 1.4, 0.75), Vector3.ONE, Vector3(60, 0, 0))
		_attach("RightHand", Vector3(0, -4, 2), _rod, Vector3(70, 0, 0))
	if _rod != null:
		_rod.visible = on


## La flûte de bambou (dans la main droite, vers la droite de la bouche).
func _show_flute(on: bool) -> void:
	if on and _flute == null and skel != null:
		_flute = Node3D.new()
		_part(_flute, _cyl(0.012, 0.012, 0.42), _mat(Color(0.72, 0.62, 0.36), 0.55), Vector3(0, 0.12, 0))
		for k in range(3):
			_part(_flute, _cyl(0.0135, 0.0135, 0.012), _mat(Color(0.3, 0.12, 0.08), 0.6), Vector3(0, 0.02 + k * 0.12, 0))
		_attach("RightHand", Vector3(0, -3, 3), _flute, Vector3(80, 0, -60))
	if _flute != null:
		_flute.visible = on


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"pecher":
			_play("rm/pecher", 0.4)
		"taiko":
			_play("rm/taiko", 0.25)
		"flute":
			_play("rm/flute", 0.4)
		_:
			super._activity(delta, dist, to_player)


func end_talk() -> void:
	super.end_talk()
	if pose in ["pecher", "flute"]:
		_arrive()


# =================================================================== la Grande Course

## Le village lance la course : le parcours (points du monde, l'arrivée à la fin), l'allure
## (m/s ; 0 : sur la ligne, il attend le départ), les mètres du départ en sprint, et quoi faire
## à l'arrivée.
func start_race(path: Array, speed: float, burst: float, done: Callable) -> void:
	_free_spot()
	_set_hidden(false)
	if model != null:
		model.visible = true
	_asleep = false
	_show_rod(false)
	_show_flute(false)
	_race = path.duplicate()
	_race_i = 1
	_race_speed = speed
	_race_burst = burst
	_race_dist = 0.0
	_race_done = done
	racing = true
	state = "course"
	route.clear()
	global_position = _race[0]
	_snap_to_floor()
	current_anim = ""


## Le départ est donné.
func race_go(speed: float, burst: float, done: Callable) -> void:
	_race_speed = speed
	_race_burst = burst
	_race_dist = 0.0
	_race_done = done


func stop_race() -> void:
	if not racing:
		return
	racing = false
	_race.clear()
	state = "repos"
	idle_clock = 1e9
	current_anim = ""
	# il reprend sa journée en marchant (pas de saut)
	at_point = ""
	var best: String = ""
	var bd: float = INF
	for k in points:
		var d: float = (points[k] as Vector3).distance_to(global_position)
		if d < bd and not str(k).begins_with("@"):
			bd = d
			best = str(k)
	at_point = best
	slot = -3


func _race_tick(delta: float) -> void:
	if _race_i >= _race.size():
		var cb: Callable = _race_done
		stop_race()
		_play("v28/idle", 0.3)
		if cb.is_valid():
			cb.call(self)
		return
	var goal: Vector3 = _race[_race_i]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if _race_speed <= 0.0:
		# sur la ligne de départ : on regarde la première arche, on sautille sur place
		_face(to_goal, delta, 6.0)
		_play("v28/idle", 0.3)
		return
	if to_goal.length() < 0.9:
		_race_i += 1
		return
	# l'allure : un départ en sprint, puis un pas de course régulier (qui ondule un peu)
	var v: float = _race_speed * (1.0 + 0.06 * sin(_kemo_clock * 0.7 + float(hash(name) % 1000)))
	if _race_dist < _race_burst:
		v *= 1.25
	_face(to_goal, delta, 8.0)
	var step: float = minf(v * delta, to_goal.length())
	global_position += to_goal.normalized() * step
	_race_dist += step
	_snap_to_floor()
	_play("Running", 0.2, v / 3.0)


func _process(delta: float) -> void:
	if racing:
		_race_tick(delta)
		_tick_kemo(delta)
		return
	super._process(delta)
	_tick_kemo(delta)

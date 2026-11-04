extends Node3D
## V103 : les oiseaux, partout autour du joueur (le jour).
##  - des goélands qui tournent en planant au-dessus de la mer et des côtes, qui crient, et qui se
##    posent sur le ponton le plus proche (ils s'envolent quand on s'approche, et reviennent) ;
##  - une petite bande de moineaux qui sautillent et picorent par terre près du joueur ; ils
##    s'envolent tous d'un coup si l'on vient trop près, puis se reposent un peu plus loin ;
##  - de temps en temps, un vol d'oiseaux qui traverse le ciel en ondulant.
## Les modèles sont ceux d'animaux_v75.gd (la mouette ; le pigeon, en petit et en brun, pour
## les moineaux). Rien dans les donjons, les maisons ni sous l'eau ; pas de moineaux sur l'Île
## Crayonnée (en noir et blanc) ni sur l'Île Pixelithique (tout en cubes).
##
## API : setup(main) ; gulls, sparrows, passing (les oiseaux) ; flee_test() pour les essais.

const A = preload("res://scripts/animaux_v75.gd")
const N_GULLS: int = 9
const N_SPARROWS: int = 6
const N_PASS: int = 11
const WATER: float = -0.42
const ANIM_R: float = 90.0

var main: Node
var gulls: Array = []
var sparrows: Array = []
var passing: Array = []
var flock_c: Vector3 = Vector3.INF
var _flock_target: Vector3 = Vector3.INF
var _flock_t: float = 0.0
var _spar_c: Vector3 = Vector3.INF
var _spar_state: String = "aucun"         # "aucun", "sol", "envol"
var _spar_t: float = 2.0
var _pass_t: float = 25.0
var _pass_on: bool = false
var _pass_pos: Vector3
var _pass_dir: Vector3
var _pass_d: float = 0.0
var _cry_t: float = 6.0
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _cries: Array = []
var _cry_players: Array = []
var _cry_i: int = 0
var _hidden: bool = false
var _perch_dock: int = -1
var _perches: Array = []                # points où les goélands se posent (ponton le plus proche)
var _last_pl: Vector3 = Vector3.INF
var _pl_speed: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Oiseaux_v103"
	_rng.seed = 1031
	for i in range(N_GULLS):
		var n: Node3D = A.build("mouette", {"taille": snappedf(_rng.randf_range(0.9, 1.1), 0.1), "seed": 3 + i % 3})
		add_child(n)
		gulls.append({"node": n, "etat": "orbite", "r": _rng.randf_range(16.0, 38.0), "ang": _rng.randf() * TAU,
			"dir": 1.0 if _rng.randf() < 0.6 else -1.0, "alt": _rng.randf_range(11.0, 28.0), "v": _rng.randf_range(6.5, 9.0),
			"ph": _rng.randf() * TAU, "flap": 0.0, "pose": "plane", "t": _rng.randf_range(5.0, 20.0), "perch": -1,
			"pos": Vector3.ZERO, "vel": Vector3.ZERO, "clock": _rng.randf() * 10.0})
	var brun := {"taille": 0.55, "base": Color(0.5, 0.39, 0.27), "aile": Color(0.44, 0.31, 0.19), "tete": Color(0.42, 0.37, 0.33), "cou": Color(0.5, 0.39, 0.27), "seed": 7}
	for j in range(N_SPARROWS):
		var s: Node3D = A.build("pigeon", brun)
		s.visible = false
		add_child(s)
		sparrows.append({"node": s, "pos": Vector3.ZERO, "from": Vector3.ZERO, "to": Vector3.ZERO, "hop": 0.0, "wait": _rng.randf_range(0.2, 1.5),
			"pose": "", "vel": Vector3.ZERO, "clock": _rng.randf() * 10.0, "yaw": _rng.randf() * TAU})
	var sombre := {"taille": 0.5, "base": Color(0.16, 0.16, 0.2), "aile": Color(0.12, 0.12, 0.16), "tete": Color(0.14, 0.14, 0.18), "cou": Color(0.16, 0.16, 0.2), "seed": 9}
	for k in range(N_PASS):
		var p: Node3D = A.build("pigeon", sombre)
		p.visible = false
		add_child(p)
		passing.append({"node": p, "off": Vector3(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-2.5, 2.5), _rng.randf_range(-5.0, 5.0)),
			"ph": _rng.randf() * TAU, "clock": _rng.randf() * 10.0})
	for c in range(1, 4):
		var path: String = "res://assets/sons/ponctuels/mouette_%d.ogg" % c
		if ResourceLoader.exists(path):
			_cries.append(load(path))
	for q in range(2):
		var pl := AudioStreamPlayer3D.new()
		pl.unit_size = 14.0
		pl.max_distance = 110.0
		pl.volume_db = -8.0
		pl.bus = "Ambiance" if AudioServer.get_bus_index("Ambiance") >= 0 else "Master"
		add_child(pl)
		_cry_players.append(pl)


func _player() -> Vector3:
	return main._player_pos_v27()


func _hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _indoors() -> bool:
	var d: Node = main.get("donjon_v35")
	if d != null and d.get("inside") == true:
		return true
	var m: Node = main.get("maisons_v81")
	if m != null and m.get("inside") == true:
		return true
	return false


func _ground(x: float, z: float) -> float:
	return maxf(main._height_at(x, z), WATER)


func _in_island(node_name: String, p: Vector3) -> bool:
	var isl: Node = main.get(node_name)
	if isl == null or isl.get("ile") == null:
		return false
	var ile: Node = isl.ile
	var c: Vector3 = ile.CENTER
	var h: float = float(ile.HALF)
	return absf(p.x - c.x) < h and absf(p.z - c.z) < h


# =================================================================== la boucle

func _process(delta: float) -> void:
	if main == null:
		return
	delta = minf(delta, 0.1)
	_clock += delta
	var pl: Vector3 = _player()
	if _last_pl != Vector3.INF:
		_pl_speed = lerpf(_pl_speed, Vector2(pl.x - _last_pl.x, pl.z - _last_pl.z).length() / maxf(delta, 0.001), clampf(delta * 5.0, 0.0, 1.0))
	_last_pl = pl
	var h: float = _hour()
	var day: bool = h >= 6.0 and h < 20.5
	var hide: bool = not day or _indoors() or pl.y < WATER - 1.5
	if hide != _hidden:
		_hidden = hide
		for g in gulls:
			(g["node"] as Node3D).visible = not hide
		if hide:
			_spar_hide()
			_pass_stop()
	if hide:
		return
	_tick_gulls(delta, pl)
	_tick_sparrows(delta, pl)
	_tick_passing(delta, pl)


# =================================================================== les goélands

func _tick_gulls(delta: float, pl: Vector3) -> void:
	# le centre de la ronde suit le joueur de loin (de préférence au-dessus de l'eau)
	_flock_t -= delta
	if flock_c == Vector3.INF:
		flock_c = _pick_flock_center(pl)
		_flock_target = flock_c
		for g0 in gulls:
			g0["pos"] = _orbit_point(g0)
			(g0["node"] as Node3D).global_position = g0["pos"]
	if _flock_t <= 0.0:
		_flock_t = 4.0
		if Vector2(_flock_target.x - pl.x, _flock_target.z - pl.z).length() > 110.0:
			_flock_target = _pick_flock_center(pl)
		_update_perches(pl)
	flock_c = flock_c.move_toward(_flock_target, 6.0 * delta)
	for g in gulls:
		g["clock"] = float(g["clock"]) + delta
		g["t"] = float(g["t"]) - delta
		var etat: String = str(g["etat"])
		match etat:
			"orbite":
				g["ang"] = float(g["ang"]) + float(g["dir"]) * float(g["v"]) / float(g["r"]) * delta
				var ideal: Vector3 = _orbit_point(g)
				var pos: Vector3 = g["pos"]
				var to: Vector3 = ideal - pos
				var max_v: float = 13.0
				var step: Vector3 = to if to.length() < max_v * delta else to.normalized() * max_v * delta
				g["vel"] = (g["vel"] as Vector3).lerp(step / maxf(delta, 0.001), clampf(delta * 3.0, 0.0, 1.0))
				g["pos"] = pos + step
				# quelques battements d'ailes de temps en temps (et quand il rattrape la ronde)
				g["flap"] = float(g["flap"]) - delta
				if float(g["flap"]) <= 0.0 and _rng.randf() < delta * 0.12:
					g["flap"] = _rng.randf_range(1.0, 2.2)
				g["pose"] = "vol" if float(g["flap"]) > 0.0 or to.length() > 6.0 else "plane"
				# se poser sur le ponton ?
				if float(g["t"]) <= 0.0:
					g["t"] = _rng.randf_range(8.0, 22.0)
					var k: int = _free_perch()
					if k >= 0 and _rng.randf() < 0.55 and pl.distance_to(_perches[k]) > 8.0:
						g["etat"] = "atterrit"
						g["perch"] = k
			"atterrit":
				var k2: int = int(g["perch"])
				if k2 < 0 or k2 >= _perches.size():
					g["etat"] = "orbite"
				else:
					var tgt: Vector3 = _perches[k2]
					var pos2: Vector3 = g["pos"]
					var d: float = pos2.distance_to(tgt)
					var sp: float = clampf(d * 0.8, 1.6, 9.0)
					var dir: Vector3 = (tgt - pos2).normalized()
					var stp: float = minf(sp * delta, d)
					g["vel"] = dir * sp
					g["pos"] = pos2 + dir * stp
					g["pose"] = "vol" if d < 7.0 else "plane"
					if d < 0.06:
						g["etat"] = "pose"
						g["vel"] = Vector3.ZERO
						g["t"] = _rng.randf_range(20.0, 60.0)
						g["yaw"] = _rng.randf() * TAU
						g["pose"] = ""
					if pl.distance_to(tgt) < 6.0:
						g["etat"] = "orbite"
						g["perch"] = -1
			"pose":
				var near_p: bool = pl.distance_to(g["pos"]) < 4.5
				g["pose"] = "picore" if fmod(float(g["clock"]), 9.0) > 7.5 else ""
				if near_p or float(g["t"]) <= 0.0 or int(g["perch"]) >= _perches.size():
					_take_off(g, pl)
			"envol":
				g["vel"] = (g["vel"] as Vector3) + Vector3.UP * 2.0 * delta
				g["pos"] = (g["pos"] as Vector3) + (g["vel"] as Vector3) * delta
				g["pose"] = "vol"
				if float(g["t"]) <= 0.0:
					g["etat"] = "orbite"
					g["t"] = _rng.randf_range(15.0, 30.0)
		_place_bird(g, delta, pl, 1.0)
	# les cris
	_cry_t -= delta
	if _cry_t <= 0.0:
		_cry_t = _rng.randf_range(4.0, 12.0)
		var g2: Dictionary = gulls[_rng.randi() % gulls.size()]
		if pl.distance_to(g2["pos"]) < 80.0 and not _cries.is_empty():
			var ap: AudioStreamPlayer3D = _cry_players[_cry_i % _cry_players.size()]
			_cry_i += 1
			ap.global_position = g2["pos"]
			ap.stream = _cries[_rng.randi() % _cries.size()]
			ap.pitch_scale = _rng.randf_range(0.92, 1.1)
			ap.play()


func _orbit_point(g: Dictionary) -> Vector3:
	var a: float = float(g["ang"])
	var c: Vector3 = flock_c
	var base: float = _ground(c.x, c.z)
	var y: float = base + float(g["alt"]) + sin(float(g["clock"]) * 0.3 + float(g["ph"])) * 2.5
	return Vector3(c.x + cos(a) * float(g["r"]), y, c.z + sin(a) * float(g["r"]))


func _pick_flock_center(pl: Vector3) -> Vector3:
	var best: Vector3 = pl + Vector3(30, 0, 0)
	for i in range(10):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(25.0, 70.0)
		var p: Vector3 = pl + Vector3(cos(a), 0, sin(a)) * d
		best = p
		if main._height_at(p.x, p.z) < WATER:
			break
	best.y = 0.0
	return best


func _take_off(g: Dictionary, pl: Vector3) -> void:
	var away: Vector3 = (g["pos"] as Vector3) - pl
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3(1, 0, 0)
	away = away.normalized().rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6))
	g["vel"] = away * 5.0 + Vector3.UP * 3.5
	g["etat"] = "envol"
	g["perch"] = -1
	g["t"] = 2.5
	g["pose"] = "vol"
	if pl.distance_to(g["pos"]) < 25.0:
		main.sfx("ailes", g["pos"], -10.0)


func _update_perches(pl: Vector3) -> void:
	var bt: Node = main.get("boat_v29")
	if bt == null:
		return
	var best: int = -1
	var bd: float = 90.0
	for i in range(bt.docks.size()):
		var d: Dictionary = bt.docks[i]
		var dd: float = pl.distance_to(d["end"])
		if dd < bd:
			bd = dd
			best = i
	if best == _perch_dock:
		return
	_perch_dock = best
	_perches.clear()
	if best >= 0:
		var d2: Dictionary = bt.docks[best]
		var axis: Vector3 = d2["axis"]
		var side: Vector3 = d2["side"]
		var e: Vector3 = d2["end"]
		for k in range(4):
			var p: Vector3 = e - axis * (0.5 + k * 1.7) + side * (1.08 if k % 2 == 0 else -1.08)
			p.y = 1.0 - 0.07
			_perches.append(p)
	for g in gulls:
		if str(g["etat"]) in ["pose", "atterrit"]:
			if str(g["etat"]) == "pose":
				_take_off(g, pl)
			else:
				g["etat"] = "orbite"
				g["perch"] = -1


func _free_perch() -> int:
	if _perches.is_empty():
		return -1
	var used := {}
	for g in gulls:
		if str(g["etat"]) in ["pose", "atterrit"]:
			used[int(g["perch"])] = true
	var free: Array = []
	for k in range(_perches.size()):
		if not used.has(k):
			free.append(k)
	if free.is_empty():
		return -1
	return int(free[_rng.randi() % free.size()])


## Place et oriente un oiseau (regard dans le sens du vol, penché dans les virages), et l'anime.
func _place_bird(g: Dictionary, delta: float, pl: Vector3, wing_k: float) -> void:
	var n: Node3D = g["node"]
	var pos: Vector3 = g["pos"]
	var vel: Vector3 = g["vel"]
	var flat := Vector3(vel.x, 0.0, vel.z)
	var yaw: float = float(g.get("yaw", 0.0))
	if flat.length() > 0.3:
		yaw = lerp_angle(yaw, atan2(flat.x, flat.z), clampf(delta * 4.0, 0.0, 1.0))
	var turn: float = wrapf(yaw - float(g.get("yaw", yaw)), -PI, PI) / maxf(delta, 0.001)
	g["yaw"] = yaw
	var flying: bool = str(g["pose"]) in ["vol", "plane"]
	var bank: float = clampf(-turn * 0.35, -0.6, 0.6) if flying else 0.0
	g["bank"] = lerpf(float(g.get("bank", 0.0)), bank, clampf(delta * 3.0, 0.0, 1.0))
	var climb: float = 0.0
	if flying and vel.length() > 0.5:
		climb = clampf(-atan2(vel.y, maxf(flat.length(), 0.1)), -0.5, 0.5)
	n.global_transform = Transform3D(Basis.from_euler(Vector3(climb, yaw, float(g["bank"])), EULER_ORDER_YXZ), pos)
	if pl.distance_to(pos) < ANIM_R:
		A.animate(n, float(g["clock"]) * wing_k, 0.0 if flying else flat.length(), str(g["pose"]), 0.0, delta)


# =================================================================== les moineaux

func _spar_hide() -> void:
	for s in sparrows:
		(s["node"] as Node3D).visible = false
	_spar_state = "aucun"
	_spar_t = 3.0


func _spar_ok_at(p: Vector3) -> bool:
	return not _in_island("crayon_v99", p) and not _in_island("pixel_v90", p)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.collide_with_areas = false
	return space.intersect_ray(q)


## Un endroit dégagé par terre, près du joueur (mais pas sous ses pieds).
func _find_ground(pl: Vector3, dmin: float, dmax: float) -> Vector3:
	var feet: float = pl.y - (1.6 if main.get("xr_active") else 0.0)
	for i in range(6):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(dmin, dmax)
		var c: Vector3 = pl + Vector3(cos(a), 0, sin(a)) * d
		var hit: Dictionary = _ray(Vector3(c.x, feet + 6.0, c.z), Vector3(c.x, feet - 8.0, c.z))
		if hit.is_empty():
			continue
		var hp: Vector3 = hit["position"]
		var nn: Vector3 = hit["normal"]
		if nn.y < 0.85 or hp.y < 0.4 or absf(hp.y - feet) > 3.5:
			continue
		if not _ray(hp + Vector3.UP * 0.3, hp + Vector3.UP * 14.0).is_empty():
			continue
		if not _spar_ok_at(hp):
			continue
		return hp
	return Vector3.INF


func _tick_sparrows(delta: float, pl: Vector3) -> void:
	match _spar_state:
		"aucun":
			_spar_t -= delta
			if _spar_t > 0.0:
				return
			_spar_t = 1.5
			if pl.y < 0.3 or _pl_speed > 6.0:
				return
			var c: Vector3 = _find_ground(pl, 8.0, 17.0)
			if c == Vector3.INF:
				return
			_spar_c = c
			_spar_state = "sol"
			for s in sparrows:
				var p: Vector3 = _hop_target(c)
				s["pos"] = p
				s["to"] = p
				s["from"] = p
				s["hop"] = 0.0
				s["vel"] = Vector3.ZERO
				s["pose"] = ""
				var n: Node3D = s["node"]
				n.visible = true
				n.scale = Vector3.ONE
		"sol":
			var dpl: float = Vector2(pl.x - _spar_c.x, pl.z - _spar_c.z).length()
			var feet: float = pl.y - (1.6 if main.get("xr_active") else 0.0)
			if dpl > 45.0 or absf(feet - _spar_c.y) > 6.0:
				_spar_hide()
				return
			if dpl < 3.2 or (dpl < 7.0 and _pl_speed > 4.0):
				flee(pl)
				return
			for s in sparrows:
				s["clock"] = float(s["clock"]) + delta
				if float(s["hop"]) > 0.0:
					var t: float = 1.0 - float(s["hop"]) / 0.22
					s["hop"] = maxf(0.0, float(s["hop"]) - delta)
					var a: Vector3 = s["from"]
					var b: Vector3 = s["to"]
					s["pos"] = a.lerp(b, t) + Vector3.UP * sin(PI * t) * 0.09
					s["vel"] = (b - a) / 0.22
					s["pose"] = ""
				else:
					s["pos"] = s["to"]
					s["vel"] = Vector3.ZERO
					s["wait"] = float(s["wait"]) - delta
					s["pose"] = "picore" if fmod(float(s["clock"]), 3.0) < 1.6 else ""
					if float(s["wait"]) <= 0.0:
						s["wait"] = _rng.randf_range(0.3, 1.8)
						s["from"] = s["pos"]
						s["to"] = _hop_target(_spar_c, s["pos"])
						s["hop"] = 0.22
				_place_bird(s, delta, pl, 1.0)
		"envol":
			_spar_t -= delta
			var any: bool = false
			for s2 in sparrows:
				var n2: Node3D = s2["node"]
				if not n2.visible:
					continue
				s2["clock"] = float(s2["clock"]) + delta
				s2["vel"] = (s2["vel"] as Vector3) + Vector3.UP * 1.5 * delta
				s2["pos"] = (s2["pos"] as Vector3) + (s2["vel"] as Vector3) * delta
				s2["pose"] = "vol"
				if _spar_t < 0.6:
					n2.scale = Vector3.ONE * maxf(0.01, _spar_t / 0.6)
				if _spar_t <= 0.0:
					n2.visible = false
				else:
					any = true
					_place_bird(s2, delta, pl, 1.6)
			if not any:
				_spar_state = "aucun"
				_spar_t = _rng.randf_range(6.0, 12.0)


func _hop_target(c: Vector3, from: Vector3 = Vector3.INF) -> Vector3:
	var p: Vector3
	for i in range(4):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(0.2, 1.8)
		p = c + Vector3(cos(a), 0, sin(a)) * r
		if from != Vector3.INF and from.distance_to(p) > 0.7:
			p = from + (p - from).normalized() * 0.5
		var hit: Dictionary = _ray(Vector3(p.x, c.y + 1.0, p.z), Vector3(p.x, c.y - 1.5, p.z))
		if not hit.is_empty() and (hit["normal"] as Vector3).y > 0.8:
			p.y = (hit["position"] as Vector3).y
			return p
	return c if from == Vector3.INF else from


## Tous les moineaux s'envolent d'un coup (on s'est approché trop près).
func flee(pl: Vector3) -> void:
	if _spar_state != "sol":
		return
	_spar_state = "envol"
	_spar_t = 3.2
	for s in sparrows:
		var away: Vector3 = (s["pos"] as Vector3) - pl
		away.y = 0.0
		if away.length() < 0.1:
			away = Vector3(0, 0, 1)
		away = away.normalized().rotated(Vector3.UP, _rng.randf_range(-0.9, 0.9))
		s["vel"] = away * _rng.randf_range(6.0, 8.5) + Vector3.UP * _rng.randf_range(3.0, 5.0)
	if pl.distance_to(_spar_c) < 20.0:
		main.sfx("ailes", _spar_c + Vector3.UP * 0.4, -9.0)


func flee_test() -> void:
	flee(_spar_c + Vector3(2, 0, 0))


# =================================================================== le vol qui passe

func _pass_stop() -> void:
	_pass_on = false
	for p in passing:
		(p["node"] as Node3D).visible = false


func _tick_passing(delta: float, pl: Vector3) -> void:
	if not _pass_on:
		_pass_t -= delta
		if _pass_t > 0.0:
			return
		_pass_t = _rng.randf_range(35.0, 80.0)
		if _in_island("crayon_v99", pl):
			return
		var a: float = _rng.randf() * TAU
		_pass_dir = Vector3(cos(a), 0, sin(a))
		var side := Vector3(-_pass_dir.z, 0, _pass_dir.x)
		_pass_pos = pl - _pass_dir * 110.0 + side * _rng.randf_range(-35.0, 35.0)
		_pass_pos.y = maxf(pl.y, 0.0) + _rng.randf_range(22.0, 38.0)
		_pass_d = 0.0
		_pass_on = true
		for p0 in passing:
			(p0["node"] as Node3D).visible = true
		return
	_pass_d += 12.0 * delta
	_pass_dir = _pass_dir.rotated(Vector3.UP, sin(_clock * 0.2) * 0.05 * delta)
	_pass_pos += _pass_dir * 12.0 * delta
	for p in passing:
		p["clock"] = float(p["clock"]) + delta
		var off: Vector3 = p["off"]
		var wob := Vector3(0, sin(float(p["clock"]) * 2.6 + float(p["ph"])) * 0.7, 0)
		var basis := Basis(Vector3.UP, atan2(_pass_dir.x, _pass_dir.z))
		p["pos"] = _pass_pos + basis * off + wob
		p["vel"] = _pass_dir * 12.0 + Vector3(0, cos(float(p["clock"]) * 2.6 + float(p["ph"])) * 1.8, 0)
		p["pose"] = "vol" if fmod(float(p["clock"]) + float(p["ph"]), 2.4) < 1.6 else "plane"
		_place_bird(p, delta, pl, 1.7)
	if _pass_d > 230.0:
		_pass_stop()

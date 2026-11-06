extends Node3D
## V115 : la vie autour du Dôme d'Azur (dehors, dans l'eau : on la voit à travers le verre) :
##  - des bancs de poissons qui tournent autour des dômes (et au-dessus de la grande coupole) ;
##  - des méduses qui luisent, près des vitres (dessinées après le verre, déjà noyées de bleu) ;
##  - deux raies mantas ;
##  - la GRANDE CHANTEUSE : une baleine qui passe, très haut au-dessus des dômes, toutes les six minutes
##    environ, en chantant (on l'entend dans tout le Dôme) ;
##  - la neige marine : de minuscules flocons qui tombent lentement dans l'eau, autour de la caméra
##    (shaders/neige_marine_v115 : on ne les voit que dans l'eau, à travers le verre).
## Les corps et les matières viennent de la vie marine de la V55 (vie_marine_v55 : les poissons, la
## baleine, les raies, les méduses).

const F = preload("res://scripts/fosse_azur_v115.gd")
const Vie = preload("res://scripts/vie_marine_v55.gd")
const D = preload("res://scripts/dome_azur_v115.gd")
const WHALE_PERIOD: float = 360.0
const WHALE_SPEED: float = 2.6

var main: Node
var pc: bool = true
var schools: Array = []                  # {mmi, center, r_orb, y, w, t, offs, sizes, n}
var jellies: Array = []                  # [Node3D, ShaderMaterial, centre, rayon, phase]
var mantas: Array = []
var whale: Node3D
var whale_t: float = -150.0              # < 0 : en attente ; 0..WHALE_PERIOD : la traversée
var whale_from := Vector3.ZERO
var whale_to := Vector3.ZERO
var song: AudioStreamPlayer
var passes: int = 0
var _song_t: float = 3.0
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fish_mesh: ArrayMesh
var _fish_mat: ShaderMaterial
var snow: CPUParticles3D
var _was_inside: bool = false


func build(main_node: Node, high_quality: bool) -> void:
	main = main_node
	pc = high_quality
	_rng.seed = 11550
	var vm = Vie.new()
	_fish_mesh = vm._make_fish_mesh()
	_fish_mat = ShaderMaterial.new()
	_fish_mat.shader = load("res://shaders/poisson_v55.gdshader")
	if ResourceLoader.exists("res://assets/textures/mer/poissons.png"):
		_fish_mat.set_shader_parameter("atlas", load("res://assets/textures/mer/poissons.png"))
	_schools()
	_mantas(vm)
	_whale(vm)
	_jellies(vm)
	_neige()
	vm.free()


func _school(center: Vector3, r_orb: float, y: float, n: int, radius: float, size: float, species: int, w: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _fish_mesh
	mm.instance_count = n
	var offs: Array = []
	var sizes: Array = []
	for i in range(n):
		offs.append(Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.45, 0.45), _rng.randf_range(-1, 1)).normalized() * pow(_rng.randf(), 0.5) * radius)
		sizes.append(size * _rng.randf_range(0.8, 1.25))
		mm.set_instance_custom_data(i, Color(_rng.randf(), (species + 0.0) / 8.0, _rng.randf_range(0.6, 1.1), 0.0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size), center))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Banc_azur_%d" % schools.size()
	mmi.multimesh = mm
	mmi.material_override = _fish_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	schools.append({"mmi": mmi, "center": center, "r_orb": r_orb, "y": y, "w": w, "t": _rng.randf() * 100.0, "offs": offs, "sizes": sizes, "n": n})


func _schools() -> void:
	var g: Vector3 = D.P(0, 0)
	var s: Vector3 = D.P(D.S_C.x, D.S_C.y)
	var i: Vector3 = D.P(D.I_C.x, D.I_C.y)
	var k: int = 1 if pc else 2
	# autour du Grand Dôme (entre les galeries et les coupoles des satellites)
	_school(g, 84.0, 12.0, 70 / k, 4.5, 0.28, 3, 0.012)
	_school(g, 88.0, 22.0, 40 / k, 3.5, 0.36, 1, -0.009)
	_school(g, 86.0, 30.0, 26 / k, 3.0, 0.45, 6, 0.007)
	# au-dessus de la grande coupole (on les voit en levant la tête) : de plus gros poissons
	_school(g, 38.0, 56.0, 46 / k, 7.0, 0.62, 2, 0.006)
	_school(g, 22.0, 64.0, 16 / k, 5.0, 0.95, 7, -0.005)
	# autour des Serres et de l'Institut
	_school(s, 42.0, 10.0, 40 / k, 3.5, 0.24, 4, 0.014)
	_school(i, 42.0, 14.0, 44 / k, 3.8, 0.24, 3, -0.013)
	_school(i, 46.0, 24.0, 18 / k, 3.0, 0.4, 5, 0.006)


func _tick_schools(delta: float) -> void:
	for sc in schools:
		sc["t"] = float(sc["t"]) + delta
		var t: float = sc["t"]
		var a: float = t * float(sc["w"]) * TAU
		var r: float = float(sc["r_orb"]) + sin(t * 0.07) * 3.0
		var c: Vector3 = (sc["center"] as Vector3) + Vector3(cos(a) * r, float(sc["y"]) + sin(t * 0.11) * 2.5, sin(a) * r)
		var dirv := Vector3(-sin(a), 0.03 * cos(t * 0.11), cos(a)) * signf(float(sc["w"]))
		var turn := Basis.looking_at(dirv.normalized(), Vector3.UP)
		var mm: MultiMesh = (sc["mmi"] as MultiMeshInstance3D).multimesh
		var offs: Array = sc["offs"]
		var sizes: Array = sc["sizes"]
		for i in range(int(sc["n"])):
			var o: Vector3 = offs[i]
			var wob := Vector3(sin(t * 0.7 + i) * 0.3, sin(t * 0.9 + i * 1.7) * 0.2, cos(t * 0.6 + i * 0.5) * 0.3)
			mm.set_instance_transform(i, Transform3D(turn.scaled(Vector3.ONE * float(sizes[i])), c + turn * (o + wob)))


func _mantas(vm) -> void:
	var mesh: ArrayMesh = vm._manta_mesh()
	var mat: ShaderMaterial = vm._manta_mat()
	for spec in [[D.P(0, 0), 92.0, 18.0, 0.006], [D.P(D.I_C.x, D.I_C.y), 50.0, 26.0, -0.008]]:
		var mi := MeshInstance3D.new()
		mi.name = "Raie_manta_azur"
		mi.mesh = mesh
		mi.material_override = mat
		add_child(mi)
		mantas.append({"node": mi, "center": spec[0], "r": spec[1], "y": spec[2], "w": spec[3], "t": _rng.randf() * 100.0})


func _tick_mantas(delta: float) -> void:
	for m in mantas:
		m["t"] = float(m["t"]) + delta
		var t: float = m["t"]
		var a: float = t * float(m["w"]) * TAU
		var r: float = m["r"]
		var p: Vector3 = (m["center"] as Vector3) + Vector3(cos(a) * r, float(m["y"]) + sin(t * 0.13) * 3.0, sin(a) * r)
		var dir := Vector3(-sin(a), 0.05 * cos(t * 0.13), cos(a)) * signf(float(m["w"]))
		var b := Basis.looking_at(dir.normalized(), Vector3.UP).rotated(dir.normalized(), sin(t * 0.3) * 0.12)
		(m["node"] as Node3D).global_transform = Transform3D(b.scaled(Vector3.ONE * 2.2), p)


func _whale(vm) -> void:
	whale = MeshInstance3D.new()
	whale.name = "La_Grande_Chanteuse"
	(whale as MeshInstance3D).mesh = vm._whale_mesh()
	(whale as MeshInstance3D).material_override = vm._swimmer_mat(14.0, 1.0, 0.04, 0.2, 0.5)
	whale.visible = false
	add_child(whale)
	song = AudioStreamPlayer.new()
	song.name = "Chant_de_la_Grande_Chanteuse"
	song.bus = "Bruitages"
	song.volume_db = -9.0
	add_child(song)


func _start_whale() -> void:
	var a: float = _rng.randf() * TAU
	var mid: Vector3 = D.P(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-20.0, 20.0), 0.0)
	var dir := Vector3(cos(a), 0, sin(a))
	var y: float = _rng.randf_range(72.0, 88.0)
	whale_from = mid - dir * 210.0 + Vector3.UP * y
	whale_to = mid + dir * 210.0 + Vector3.UP * (y + _rng.randf_range(-6.0, 6.0))
	whale_t = 0.0
	whale.visible = true
	passes += 1
	_song_t = 6.0


func _tick_whale(delta: float, inside: bool) -> void:
	if whale_t < 0.0:
		whale_t += delta
		if whale_t >= 0.0:
			_start_whale()
		return
	whale_t += delta
	var dur: float = whale_from.distance_to(whale_to) / WHALE_SPEED
	var u: float = whale_t / dur
	if u >= 1.0:
		whale.visible = false
		whale_t = -(WHALE_PERIOD - dur)
		return
	var p: Vector3 = whale_from.lerp(whale_to, u) + Vector3.UP * sin(u * PI * 3.0) * 2.0
	var dir: Vector3 = (whale_to - whale_from).normalized()
	whale.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP).scaled(Vector3.ONE * 1.6), p)
	_song_t -= delta
	if _song_t <= 0.0 and inside:
		_song_t = _rng.randf_range(18.0, 30.0)
		var path: String = "res://assets/sons/sfx/baleine_%d.ogg" % (1 + _rng.randi() % 2)
		if ResourceLoader.exists(path) and song != null:
			song.stream = load(path)
			song.play()


## La baleine passe tout de suite (pour les tests et les rendus).
func whale_now() -> void:
	_start_whale()


func _jellies(vm) -> void:
	var sh: Shader = load("res://shaders/meduse_v55.gdshader")
	var bell := SphereMesh.new()
	bell.radius = 0.5
	bell.height = 0.6
	bell.is_hemisphere = true
	bell.radial_segments = 16
	bell.rings = 6
	var tent: ArrayMesh = vm._tentacle_mesh()
	var tints := [Color(0.95, 0.45, 0.85), Color(0.45, 0.75, 1.0), Color(0.75, 0.55, 1.0), Color(0.5, 1.0, 0.85)]
	var spots: Array = []
	for k in range(7):
		spots.append([D.P(0, 0), D.R_G + _rng.randf_range(5.0, 12.0), _rng.randf_range(5.0, 22.0)])
	for k2 in range(3):
		spots.append([D.P(D.I_C.x, D.I_C.y), D.R_SAT + _rng.randf_range(4.0, 9.0), _rng.randf_range(4.0, 14.0)])
	for k3 in range(2):
		spots.append([D.P(D.S_C.x, D.S_C.y), D.R_SAT + _rng.randf_range(4.0, 9.0), _rng.randf_range(4.0, 14.0)])
	for sp in spots:
		var root := Node3D.new()
		root.name = "Meduse_azur"
		add_child(root)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.render_priority = 2
		m.set_shader_parameter("tint", tints[_rng.randi() % tints.size()])
		m.set_shader_parameter("seed", _rng.randf() * 10.0)
		m.set_shader_parameter("energy", 0.2)
		var bi := MeshInstance3D.new()
		bi.mesh = bell
		bi.material_override = m
		root.add_child(bi)
		var tm: ShaderMaterial = m.duplicate()
		tm.set_shader_parameter("tentacle", 1.0)
		var ti := MeshInstance3D.new()
		ti.mesh = tent
		ti.material_override = tm
		root.add_child(ti)
		root.scale = Vector3.ONE * _rng.randf_range(0.45, 0.95)
		jellies.append([root, m, sp[0], sp[1], sp[2], _rng.randf() * TAU, _rng.randf_range(-0.012, 0.012)])


## La neige marine : des particules qui suivent la caméra (en coordonnées du monde : elles restent où
## elles tombent) ; le shader jette celles qui sont dans l'air (les volumes du verre).
func _neige() -> void:
	var p := CPUParticles3D.new()
	p.name = "Neige_marine"
	p.amount = 900 if pc else 360
	p.lifetime = 30.0
	p.preprocess = 30.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(26.0, 15.0, 26.0)
	p.direction = Vector3.DOWN
	p.spread = 70.0
	p.gravity = Vector3(0, -0.015, 0)
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.1
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.08
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.add_point(0.15, Color(1, 1, 1, 1))
	grad.add_point(0.85, Color(1, 1, 1, 1))
	grad.set_color(grad.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/neige_marine_v115.gdshader")
	m.render_priority = 2
	if main != null and main.has_method("_soft_dot_v24"):
		m.set_shader_parameter("flocon", main._soft_dot_v24())
	var g: ShaderMaterial = load("res://scripts/dome_mats_v115.gd").make("verre115") as ShaderMaterial
	if g != null:
		for k in ["n_ell", "ell_c", "ell_r", "n_cap", "cap_a", "cap_b"]:
			m.set_shader_parameter(k, g.get_shader_parameter(k))
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	qm.material = m
	p.mesh = qm
	p.visibility_aabb = AABB(Vector3(-60, -40, -60), Vector3(120, 80, 120))
	add_child(p)
	snow = p


func _tick_jellies(delta: float) -> void:
	for j in jellies:
		j[5] = float(j[5]) + delta
		var ph: float = j[5]
		var a: float = ph * float(j[6]) * TAU + float(j[3])
		var p: Vector3 = (j[2] as Vector3) + Vector3(cos(a) * float(j[3]), float(j[4]) + sin(ph * 0.21) * 1.5, sin(a) * float(j[3]))
		(j[0] as Node3D).global_position = p
		(j[1] as ShaderMaterial).set_shader_parameter("pulse", 0.5 + 0.5 * sin(ph * 1.7))


func tick(delta: float, inside: bool) -> void:
	_clock += delta
	if not inside:
		_was_inside = false
		if song != null and song.playing:
			song.stop()
		return
	_tick_schools(delta)
	_tick_mantas(delta)
	_tick_whale(delta, inside)
	_tick_jellies(delta)
	if snow != null:
		var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam != null:
			snow.global_position = cam.global_position
			# en arrivant : la neige est déjà là, tout autour (pas seulement dans trente secondes)
			if not _was_inside:
				snow.restart()
	_was_inside = true

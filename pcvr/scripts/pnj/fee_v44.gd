extends Node3D
## V44 : une habitante du Village des Fées (ou le lutin Grommelot). Même cerveau et même
## dialogue que les autres habitants (pnj_brain_v31.gd), mais un petit corps qui vole :
## robe en pétales, grandes ailes qui battent, une lueur et des étincelles.
## Fiche : la clé "fee" donne {robe, cheveux, ailes, peau, yeux} ; "lutin": true pour Grommelot.
## Interface commune avec pnj_v31.gd : display_name, brain, profile, state, begin_talk,
## end_talk, gesture, say_bubble, serialize, load_data, et la règle des cibles de combat.

const Brain = preload("res://scripts/pnj/pnj_brain_v31.gd")
const TALK_REACH: float = 2.8

var main: Node
var brain
var profile: Dictionary
var display_name: String = ""
var home: Vector3
var points: Dictionary = {}          # comme pnj_v31 (les arbres et trésors évitent ces points)
var state: String = "repos"
var bubble: Label3D
var bubble_clock: float = 0.0
var vr_label: Label3D
var hit_radius: float = 0.3
var hit_height: float = 1.3
var _body: Node3D
var _wings: Array = []
var _clock: float = 0.0
var _spin: float = 0.0
var _called: float = 0.0
var _was_near: bool = false
var _light: OmniLight3D
var _lutin: bool = false
var _wander := Vector3.ZERO
var _wander_clock: float = 0.0


func setup(main_node: Node, data: Dictionary, at: Vector3) -> void:
	main = main_node
	profile = data
	display_name = str(data.get("nom", "?"))
	name = "Fee_" + str(data.get("id", "x"))
	brain = Brain.new()
	brain.setup(profile)
	home = at
	points = {"maison": at}
	_lutin = bool(data.get("lutin", false))
	_clock = randf() * 10.0
	_build()
	global_position = at
	add_to_group("cibles_v28")
	add_to_group("pnj_v31")


func _mat(c: Color, glow: float = 0.3, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = 0.5
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = glow
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _sphere(r: float, segs: int = 14) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 4)
	return s


func _cyl(a: float, b: float, h: float, segs: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = segs
	return c


func _col(key: String, def: Array) -> Color:
	var look: Dictionary = profile.get("fee", {})
	var a: Array = look.get(key, def)
	return Color(float(a[0]), float(a[1]), float(a[2]))


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Corps"
	add_child(_body)
	if _lutin:
		_build_lutin()
	else:
		_build_fairy()
		# V45 : un peu plus grandes, pour qu'on les voie bien (environ 80 cm, ailes comprises)
		_body.scale = Vector3.ONE * 1.3
		_body.position = Vector3.ZERO
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 36
	bubble.pixel_size = 0.0026
	bubble.outline_size = 12
	bubble.width = 600
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.position = Vector3(0, 2.0, 0)
	bubble.no_depth_test = true
	bubble.visible = false
	add_child(bubble)
	vr_label = Label3D.new()
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 40
	vr_label.pixel_size = 0.0024
	vr_label.outline_size = 10
	vr_label.position = Vector3(0, 1.8, 0)
	vr_label.no_depth_test = true
	vr_label.text = "Gâchette droite : parler à " + display_name.split(" ")[0]
	vr_label.visible = false
	add_child(vr_label)


## Une fée d'une soixantaine de centimètres qui vole à hauteur de visage.
func _build_fairy() -> void:
	var skin := _mat(_col("peau", [1.0, 0.88, 0.85]), 0.25)
	var dress := _mat(_col("robe", [0.6, 0.85, 0.65]), 0.35)
	var hair := _mat(_col("cheveux", [0.95, 0.75, 0.9]), 0.3)
	var eye := _mat(_col("yeux", [0.3, 0.5, 0.9]), 0.8)
	var dark := _mat(Color(0.05, 0.05, 0.08), 0.0)
	var wing_c: Color = _col("ailes", [0.7, 0.95, 1.0])
	var f := Node3D.new()
	f.position = Vector3(0, 1.3, 0)
	_body.add_child(f)
	# Robe en corolle de pétales, buste, bras
	for k in range(6):
		var a: float = TAU * k / 6.0
		_part(f, _sphere(0.08, 10), dress, Vector3(cos(a) * 0.06, -0.12, sin(a) * 0.06), Vector3(0.7, 1.6, 0.45), Vector3(sin(a) * 0.5, -a, -cos(a) * 0.5))
	_part(f, _cyl(0.05, 0.07, 0.14), dress, Vector3(0, 0.0, 0))
	for sx in [-1.0, 1.0]:
		_part(f, _cyl(0.015, 0.018, 0.13), skin, Vector3(sx * 0.07, -0.01, 0.01), Vector3.ONE, Vector3(0.3, 0, sx * 0.35))
		_part(f, _cyl(0.014, 0.018, 0.16), skin, Vector3(sx * 0.03, -0.27, 0.0), Vector3.ONE, Vector3(0.1, 0, sx * 0.08))
	# Tête : grands yeux, joues, cheveux en chignon fleuri, petites oreilles pointues
	var head := Node3D.new()
	head.position = Vector3(0, 0.15, 0)
	f.add_child(head)
	_part(head, _sphere(0.075), skin, Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.017, 8), _mat(Color(1, 1, 1), 0.2), Vector3(sx * 0.027, 0.005, 0.064), Vector3(1.0, 1.25, 0.5))
		_part(head, _sphere(0.012, 8), eye, Vector3(sx * 0.027, 0.003, 0.07), Vector3(1.0, 1.2, 0.5))
		_part(head, _sphere(0.006, 6), dark, Vector3(sx * 0.027, 0.002, 0.075))
		_part(head, _sphere(0.014, 8), _mat(Color(1.0, 0.6, 0.7), 0.2, 0.5), Vector3(sx * 0.045, -0.025, 0.057), Vector3(1.2, 0.7, 0.4))
		_part(head, _cyl(0.0, 0.016, 0.06, 6), skin, Vector3(sx * 0.075, 0.02, 0.0), Vector3.ONE, Vector3(0, 0, sx * -1.2))
	_part(head, _sphere(0.082), hair, Vector3(0, 0.022, -0.012), Vector3(1.05, 0.95, 1.0))
	_part(head, _sphere(0.04), hair, Vector3(0, 0.09, -0.04))
	var flower := _mat(_col("fleur", [1.0, 0.95, 0.6]), 1.0)
	for k in range(5):
		var a2: float = TAU * k / 5.0
		_part(head, _sphere(0.015, 6), flower, Vector3(0.05 + cos(a2) * 0.017, 0.07 + sin(a2) * 0.017, 0.03))
	# Ailes (deux paires), translucides et irisées
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	wm.albedo_color = Color(wing_c.r, wing_c.g, wing_c.b, 0.55)
	for sx in [-1.0, 1.0]:
		for up in [1.0, -1.0]:
			var hinge := Node3D.new()
			hinge.position = Vector3(sx * 0.02, 0.04, -0.05)
			f.add_child(hinge)
			var w := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.12 if up > 0 else 0.085
			sm.height = sm.radius * 2.0
			sm.radial_segments = 12
			sm.rings = 6
			w.mesh = sm
			w.material_override = wm
			w.scale = Vector3(1.0, 0.55, 0.06)
			w.position = Vector3(sx * (0.11 if up > 0 else 0.08), up * 0.06, 0)
			w.rotation.z = up * sx * 0.5
			hinge.add_child(w)
			_wings.append([hinge, sx])
	_light = OmniLight3D.new()
	_light.light_color = wing_c
	_light.light_energy = 0.8
	_light.omni_range = 4.0
	_light.position = Vector3(0, 1.3, 0)
	_body.add_child(_light)
	var sp := CPUParticles3D.new()
	sp.amount = 18
	sp.lifetime = 1.3
	sp.local_coords = false
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.12
	sp.gravity = Vector3(0, -0.25, 0)
	sp.initial_velocity_min = 0.02
	sp.initial_velocity_max = 0.12
	var q := QuadMesh.new()
	q.size = Vector2(0.04, 0.04)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.albedo_color = Color(wing_c.r, wing_c.g, wing_c.b, 0.9)
	pm.albedo_texture = main._soft_dot_v24()
	q.material = pm
	sp.mesh = q
	sp.position = Vector3(0, 1.2, -0.03)
	_body.add_child(sp)


## Grommelot, le lutin bougon : bonnet pointu, grande barbe, nez rond, assis sur sa souche.
func _build_lutin() -> void:
	var skin := _mat(Color(0.95, 0.75, 0.62), 0.15)
	var coat := _mat(_col("robe", [0.35, 0.45, 0.25]), 0.15)
	var hat := _mat(_col("cheveux", [0.7, 0.2, 0.18]), 0.2)
	var beard := _mat(Color(0.92, 0.92, 0.9), 0.15)
	var dark := _mat(Color(0.05, 0.04, 0.03), 0.0)
	_part(_body, _cyl(0.32, 0.38, 0.45), _mat(Color(0.45, 0.32, 0.2), 0.05), Vector3(0, 0.225, 0))
	var g := Node3D.new()
	g.position = Vector3(0, 0.45, 0)
	_body.add_child(g)
	_part(g, _sphere(0.18), coat, Vector3(0, 0.2, 0), Vector3(1.0, 1.15, 0.9))
	for sx in [-1.0, 1.0]:
		_part(g, _cyl(0.04, 0.05, 0.22), coat, Vector3(sx * 0.08, 0.04, 0.12), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_part(g, _sphere(0.055), dark, Vector3(sx * 0.08, 0.02, 0.24), Vector3(1.0, 0.7, 1.4))
	_part(g, _sphere(0.12), skin, Vector3(0, 0.48, 0))
	_part(g, _sphere(0.04), _mat(Color(0.95, 0.55, 0.5), 0.1), Vector3(0, 0.46, 0.12))
	for sx in [-1.0, 1.0]:
		_part(g, _sphere(0.014, 6), dark, Vector3(sx * 0.045, 0.51, 0.105))
		_part(g, _box_mesh(Vector3(0.05, 0.012, 0.01)), beard, Vector3(sx * 0.045, 0.545, 0.105), Vector3.ONE, Vector3(0, 0, sx * -0.4))
	_part(g, _sphere(0.11), beard, Vector3(0, 0.36, 0.08), Vector3(1.1, 1.5, 0.7))
	_part(g, _cyl(0.0, 0.14, 0.38), hat, Vector3(0, 0.72, -0.02), Vector3.ONE, Vector3(-0.35, 0, 0))
	_part(g, _sphere(0.035), beard, Vector3(0, 0.88, -0.1))
	hit_height = 0.8


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


# =================================================================== comportement

func _process(delta: float) -> void:
	_clock += delta
	brain.tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	_called = maxf(_called - delta, 0.0)
	var player: Vector3 = main._player_pos_v27()
	var to_p: Vector3 = player - global_position
	var dist: float = Vector2(to_p.x, to_p.z).length()
	if dist > 60.0:
		return
	vr_label.visible = main.xr_active and state != "parle" and dist < TALK_REACH
	var near: bool = dist < 9.0 and absf(to_p.y) < 5.0
	if near and not _was_near and _called <= 0.0 and state != "parle":
		var line: String = brain.call_out(main._npc_ctx_v31())
		if line != "":
			say_bubble(line, 4.5)
		_called = 60.0
	_was_near = near
	# Vol : petites boucles autour de sa maison, sur place quand on lui parle.
	if not _lutin:
		_wander_clock -= delta
		if _wander_clock <= 0.0 and state != "parle":
			_wander_clock = randf_range(3.0, 7.0)
			_wander = Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		var goal: Vector3 = home + (Vector3.ZERO if state == "parle" or dist < 3.0 else _wander)
		var flat: Vector3 = (goal - global_position) * Vector3(1, 0, 1)
		global_position += flat * clampf(delta * 0.8, 0.0, 1.0)
		_body.position.y = sin(_clock * 2.2) * 0.08
		var flap: float = 22.0 if _spin <= 0.0 else 40.0
		for w in _wings:
			(w[0] as Node3D).rotation.y = float(w[1]) * (0.25 + sin(_clock * flap) * 0.55)
		if _light != null:
			_light.light_energy = 0.8 + sin(_clock * 3.0) * 0.15
	# Regard : vers le joueur s'il est proche, sinon dans le sens du vol
	var look: Vector3 = to_p if dist < 5.0 or state == "parle" else Vector3.ZERO
	if _spin > 0.0:
		_spin -= delta
		_body.rotation.y += delta * 14.0
	elif look.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(look.x, look.z), clampf(delta * 5.0, 0.0, 1.0))
		_body.rotation.y = lerp_angle(_body.rotation.y, 0.0, clampf(delta * 8.0, 0.0, 1.0))


func gesture(kind: String) -> void:
	match kind:
		"rire", "salut":
			_spin = 0.45
		"colere":
			_spin = 0.0
			if _light != null:
				_light.light_color = Color(1.0, 0.4, 0.3)
				create_tween().tween_property(_light, "light_color", _col("ailes", [0.7, 0.95, 1.0]), 1.2)


func say_bubble(text: String, seconds: float) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble_clock = seconds


func begin_talk() -> void:
	state = "parle"
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	state = "repos"


func is_hittable() -> bool:
	return true


func take_hit(_damage: int, from_pos: Vector3) -> void:
	var line: String = brain.hit(main._npc_ctx_v31())
	say_bubble(line, 3.5)
	gesture("colere")
	var away: Vector3 = (global_position - from_pos) * Vector3(1, 0, 1)
	if away.length() > 0.05 and not _lutin:
		global_position += away.normalized() * 0.8
	if state == "parle":
		main._close_dialogue_v31()


func serialize() -> Dictionary:
	return brain.serialize()


func load_data(d: Dictionary) -> void:
	brain.load_data(d)

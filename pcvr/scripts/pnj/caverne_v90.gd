extends Node3D
## V90 : un homme (ou une femme, ou un enfant) des cavernes du Clan, sur l'Île Pixelithique. Tout en
## petits cubes, comme l'île (vox_v90 : tronc, tête, bras, jambes) ; pour eux, c'est le héros qui
## est bizarre : tout lisse, sans un seul pixel. Ils sont cool : ils rient fort, dansent autour du
## feu, tapent sur des tambours, peignent sur les murs, et parlent un peu… à leur façon.
## Même façon de parler que les autres habitants (say, gesture, lines, begin_talk, end_talk,
## set_pose ; le nœud tient lieu de « npc » pour la fenêtre de dialogue).
##   gestes : rire, joie, salut, peur, pointer, colere, applaudir, danse, tambour, peindre, frapper
##   poses : debout, assis, dormir, danse, tambour, peindre, garde

const Vox = preload("res://scripts/vox_v90.gd")

var npc: Node3D
var main: Node
var display_name: String = "Ougha"
var id: String = "ougha"
var lines: Array = []
var line_every := Vector2(7.0, 14.0)
var follow: bool = true
var talking: bool = false
var pose: String = "debout"
var face_dir := Vector3(0, 0, 1)
var taille: float = 1.0
var bubble: Label3D
var bubble_clock: float = 0.0
var vr_label: Label3D
var model: Node3D
var parts: Dictionary = {}
var ground: Callable                   # (x, z) -> y : pour marcher sur le sol
var target := Vector3.INF              # où il marche
var speed: float = 1.3
var arrived: bool = true
var _t: float = 0.0
var _walk: float = 0.0
var _gest: String = ""
var _gest_t: float = 0.0
var _gest_len: float = 0.0
var _line_t: float = 4.0
var _rng := RandomNumberGenerator.new()
var _prop: Node3D


static func spawn(parent: Node3D, main_node: Node, who: String, nom: String, pos: Vector3, face: Vector3, pose_name: String = "debout", objet: String = "") -> Node3D:
	var m: Node3D = (load("res://scripts/pnj/caverne_v90.gd") as Script).new()
	m.name = "Caverne_" + who
	parent.add_child(m)
	m.setup(main_node, who, nom, pos, face, pose_name, objet)
	return m


func setup(main_node: Node, who: String, nom: String, pos: Vector3, face: Vector3, pose_name: String, objet: String) -> void:
	main = main_node
	npc = self
	id = who
	display_name = nom
	_rng.seed = hash(who)
	global_position = pos
	model = Node3D.new()
	model.name = "Corps"
	add_child(model)
	var r: Dictionary = Vox.rig_data(who)
	taille = float((r.get("taille", [1.0]) as Array)[0]) if r.has("taille") else 1.0
	parts = Vox.rig(model, who)
	model.scale = Vector3.ONE * taille
	if objet != "" and parts.has("brasD") and Vox.has(objet):
		_prop = MeshInstance3D.new()
		(_prop as MeshInstance3D).mesh = Vox.mesh(objet)
		(_prop as MeshInstance3D).material_override = Vox.material()
		(parts["brasD"] as Node3D).add_child(_prop)
		_prop.position = Vector3(0, -0.5, 0.06)
		_prop.rotation = Vector3(PI * 0.5, 0, 0)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 36
	bubble.pixel_size = 0.0026
	bubble.outline_size = 12
	bubble.width = 620
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.no_depth_test = true
	bubble.visible = false
	bubble.position = Vector3(0, 1.95 * taille, 0)
	add_child(bubble)
	vr_label = Label3D.new()
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 28
	vr_label.pixel_size = 0.0025
	vr_label.no_depth_test = true
	vr_label.visible = false
	vr_label.position = Vector3(0, 1.75 * taille, 0)
	vr_label.text = "Gâchette droite : parler à " + display_name
	add_child(vr_label)
	set_pose(pose_name, face)
	_line_t = _rng.randf_range(2.0, 8.0)


# =================================================================== comme un habitant

func face_height() -> float:
	return 1.65 * taille


func say_bubble(text: String, seconds: float) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble_clock = seconds


func say(text: String, seconds: float = 4.0) -> void:
	say_bubble(text, seconds)


func begin_talk() -> void:
	talking = true
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	talking = false


func set_pose(p: String, face: Vector3 = Vector3.ZERO) -> void:
	pose = p
	if face.length() > 0.01:
		face_dir = Vector3(face.x, 0, face.z).normalized()
		rotation.y = atan2(face_dir.x, face_dir.z)
	follow = p in ["debout", "garde"]


func gesture(kind: String, seconds: float = 2.0) -> void:
	_gest = kind
	_gest_t = 0.0
	_gest_len = seconds


func freeze(_on: bool) -> void:
	pass


## Marcher jusqu'à un point (sur le sol, grâce à ground).
func walk_to(p: Vector3, spd: float = 1.3) -> void:
	target = p
	speed = spd
	arrived = false


# =================================================================== la vie

func _set_rot(k: String, r: Vector3) -> void:
	if parts.has(k):
		(parts[k] as Node3D).rotation = r


func _process(delta: float) -> void:
	_t += delta
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	var player: Vector3 = main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else global_position + Vector3(0, 0, 3)
	var to_p: Vector3 = player - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	# la marche
	var moving: bool = false
	if not arrived and target != Vector3.INF and not talking:
		var to: Vector3 = target - global_position
		to.y = 0.0
		if to.length() < 0.25:
			arrived = true
		else:
			moving = true
			var step: Vector3 = to.normalized() * minf(to.length(), speed * delta)
			var np: Vector3 = global_position + step
			if ground.is_valid():
				np.y = float(ground.call(np.x, np.z))
			global_position = np
			face_dir = to.normalized()
	var want: Vector3 = face_dir
	if (talking or (follow and dist < 4.5 and not moving)) and dist > 0.3:
		want = to_p / dist
	rotation.y = lerp_angle(rotation.y, atan2(want.x, want.z), clampf(delta * 5.0, 0.0, 1.0))
	_walk = move_toward(_walk, 1.0 if moving else 0.0, delta * 4.0)
	_animate(delta, moving)
	# une petite phrase de temps en temps
	if vr_label != null:
		vr_label.visible = main != null and bool(main.get("xr_active")) and dist < 2.4 and not talking
	if not talking and not lines.is_empty() and dist < 9.0:
		_line_t -= delta
		if _line_t <= 0.0 and bubble_clock <= 0.0:
			_line_t = _rng.randf_range(line_every.x, line_every.y)
			say(str(lines[_rng.randi() % lines.size()]), 4.0)


func _animate(_delta: float, moving: bool) -> void:
	var w: float = _walk
	var ph: float = _t * 7.0 * clampf(speed / 1.3, 0.6, 1.8)
	var arm_l := Vector3.ZERO
	var arm_r := Vector3.ZERO
	var leg_l := Vector3.ZERO
	var leg_r := Vector3.ZERO
	var head := Vector3.ZERO
	var body := Vector3.ZERO
	var pos := Vector3.ZERO
	# la marche : jambes et bras en balancier, le corps qui sautille un peu
	leg_l.x = sin(ph) * 0.55 * w
	leg_r.x = -sin(ph) * 0.55 * w
	arm_l.x = -sin(ph) * 0.45 * w
	arm_r.x = sin(ph) * 0.45 * w
	pos.y = absf(sin(ph)) * 0.04 * w
	# respirer
	body.x = sin(_t * 1.8) * 0.02
	head.x = sin(_t * 1.1) * 0.04
	match pose:
		"assis":
			pos.y = -0.38
			leg_l.x = -1.45
			leg_r.x = -1.45
			arm_l.x = -0.4
			arm_r.x = -0.4
		"dormir":
			pos.y = -0.42
			body.x = -1.45
			leg_l.x = -0.1
			leg_r.x = -0.1
			arm_l.x = -0.2
			arm_r.x = -0.2
		"danse":
			var dp: float = _t * 6.0
			pos.y = absf(sin(dp)) * 0.18
			arm_l = Vector3(-2.4 + sin(dp) * 0.4, 0, 0.3)
			arm_r = Vector3(-2.4 - sin(dp) * 0.4, 0, -0.3)
			leg_l.x = sin(dp) * 0.5
			leg_r.x = -sin(dp) * 0.5
			body.z = sin(dp * 0.5) * 0.12
			head.z = sin(dp * 0.5) * 0.15
		"tambour":
			pos.y = -0.36
			leg_l.x = -1.45
			leg_r.x = -1.45
			arm_l.x = -1.0 - maxf(0.0, sin(_t * 9.0)) * 0.6
			arm_r.x = -1.0 - maxf(0.0, sin(_t * 9.0 + PI)) * 0.6
			head.x = absf(sin(_t * 4.5)) * 0.15
		"peindre":
			arm_r = Vector3(-1.8 + sin(_t * 2.0) * 0.3, 0, -0.2 + sin(_t * 3.1) * 0.3)
			head.x = -0.15
		"garde":
			arm_r.x = -0.35
	if talking:
		head.x += sin(_t * 5.0) * 0.06
		arm_r.x += -0.5 - sin(_t * 3.0) * 0.25
	if _gest != "":
		_gest_t += _delta
		var g: float = _gest_t
		var k: float = clampf(g / maxf(_gest_len, 0.1), 0.0, 1.0)
		match _gest:
			"rire":
				body.x = -0.25 + sin(g * 18.0) * 0.06
				head.x = -0.35
				pos.y += absf(sin(g * 12.0)) * 0.04
				arm_l.x = -0.3
				arm_r.x = -0.3
			"joie":
				pos.y += absf(sin(g * 8.0)) * 0.3
				arm_l = Vector3(-2.8, 0, 0.4)
				arm_r = Vector3(-2.8, 0, -0.4)
			"salut":
				arm_r = Vector3(-2.7, 0, -0.3 + sin(g * 10.0) * 0.35)
			"peur":
				body.x = 0.35
				pos.y -= 0.12
				arm_l = Vector3(-2.0, 0, 0.7)
				arm_r = Vector3(-2.0, 0, -0.7)
				head.x = 0.4
			"pointer":
				arm_r = Vector3(-1.5, 0, 0)
			"colere":
				arm_l = Vector3(-2.2 + sin(g * 14.0) * 0.4, 0, 0.3)
				arm_r = Vector3(-2.2 - sin(g * 14.0) * 0.4, 0, -0.3)
				pos.y += absf(sin(g * 9.0)) * 0.06
			"applaudir":
				arm_l = Vector3(-1.3, 0, -0.5 + absf(sin(g * 12.0)) * 0.5)
				arm_r = Vector3(-1.3, 0, 0.5 - absf(sin(g * 12.0)) * 0.5)
			"frapper":
				arm_r.x = -2.6 + sin(k * PI) * 2.4
			"tambour":
				arm_l.x = -1.0 - maxf(0.0, sin(g * 12.0)) * 0.8
				arm_r.x = -1.0 - maxf(0.0, sin(g * 12.0 + PI)) * 0.8
		if _gest_t >= _gest_len:
			_gest = ""
	_set_rot("brasG", arm_l)
	_set_rot("brasD", arm_r)
	_set_rot("jambeG", leg_l)
	_set_rot("jambeD", leg_r)
	_set_rot("tete", head)
	_set_rot("tronc", body)
	model.position = pos

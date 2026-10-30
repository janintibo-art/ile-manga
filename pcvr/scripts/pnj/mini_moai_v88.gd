extends Node3D
## V88 : un petit Moaï. Un Moaï en miniature (un mètre, à peu près), en tuf comme les grands, mais
## vivant : deux yeux de corail qui clignent, deux pieds de galet pour sautiller, et toujours une
## parure (un collier de fleurs, un collier de coquillages, une couronne de feuilles, un petit
## chignon de pierre rouge, des lunettes de coquillage). Ils sont farceurs : ils rigolent en
## rebondissant, saluent en se penchant, sursautent, tournent sur eux-mêmes de joie, se figent en
## statue quand on les regarde (le jeu du « 1, 2, 3, Moaï ! »)…
## Il remplace un habitant (pnj/figurant_v81.gd) dans les maisons : même façon de parler (say,
## gesture, lines, begin_talk, end_talk, set_pose) ; le nœud lui-même tient lieu de « npc »
## (display_name, say_bubble, face_height) pour la fenêtre de dialogue et maisons_v81.

const Statue = preload("res://scripts/moai_statue_v87.gd")

const NOMS := ["Caillou", "Galet", "Pépite", "Rocaille", "Gravillon", "Silex", "Ponce", "Granit", "Basalte", "Moellon",
	"Pavé", "Rocher", "Tuf", "Petit-Roc", "Gravier", "Obsidienne", "Lave", "Scorie", "Cailloutis", "Menhir"]
const PARURES := ["fleurs", "coquillages", "feuilles", "chignon", "lunettes", "fleur_oreille"]

var npc: Node3D                 # (lui-même : maisons_v81 et les histoires parlent à « f.npc »)
var main: Node
var display_name: String = "Caillou"
var lines: Array = []
var line_every := Vector2(6.0, 12.0)
var follow: bool = true
var talking: bool = false
var pose: String = "debout"
var face_dir := Vector3(0, 0, 1)
var h: float = 1.0
var bubble: Label3D
var bubble_clock: float = 0.0
var vr_label: Label3D
var model: Node3D               # le corps qui bouge (sautille, se penche, rit)
var frozen: bool = false        # figé en statue
var _eyes: Array = []           # [blanc, pupille]
var _t: float = 0.0
var _gest: String = ""
var _gest_t: float = 0.0
var _gest_len: float = 0.0
var _blink_t: float = 2.0
var _line_t: float = 4.0
var _hop_t: float = 3.0
var _rng := RandomNumberGenerator.new()


## Un petit Moaï dans parent, debout en pos, qui regarde face. opts : {"h", "v", "parure", "teinte"}
static func spawn(parent: Node3D, main_node: Node, nom: String, pos: Vector3, face: Vector3, pose_name: String = "debout", opts: Dictionary = {}) -> Node3D:
	var m: Node3D = (load("res://scripts/pnj/mini_moai_v88.gd") as Script).new()
	m.name = "Petit_Moai_" + nom.replace(" ", "_")
	parent.add_child(m)
	m.setup(main_node, nom, pos, face, pose_name, opts)
	return m


func setup(main_node: Node, nom: String, pos: Vector3, face: Vector3, pose_name: String, opts: Dictionary) -> void:
	main = main_node
	npc = self
	display_name = nom
	_rng.seed = hash(nom + str(pos))
	h = float(opts.get("h", _rng.randf_range(0.85, 1.15)))
	global_position = pos
	model = Node3D.new()
	model.name = "Corps"
	add_child(model)
	var v: int = int(opts.get("v", _rng.randi() % 3))
	# le corps : un Moaï en miniature, posé sur deux pieds de galet
	var body := MeshInstance3D.new()
	body.mesh = Statue.body_mesh(v)
	body.material_override = Statue.stone_mat("pierre_moai", (opts.get("teinte", Color(1, 1, 1)) as Color) * Color(0.84, 0.8, 0.74))
	body.scale = Vector3.ONE * h * 0.82
	body.position = Vector3(0, h * 0.16, 0)
	model.add_child(body)
	var pebble := StandardMaterial3D.new()
	pebble.albedo_color = Color(0.32, 0.3, 0.29)
	pebble.roughness = 0.6
	for sx in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		var fs := SphereMesh.new()
		fs.radius = 0.09 * h
		fs.height = 0.12 * h
		foot.mesh = fs
		foot.material_override = pebble
		foot.position = Vector3(sx * 0.08 * h, 0.06 * h, 0.03 * h)
		foot.scale = Vector3(1.0, 1.0, 1.5)
		model.add_child(foot)
		foot.set_meta("pied", sx)
	# les yeux de corail blanc, les pupilles noires (elles suivent un peu)
	var P: Array = Statue._var(v)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.97, 0.95, 0.9)
	white.roughness = 0.3
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.03, 0.03, 0.04)
	black.roughness = 0.15
	for sx2 in [-1.0, 1.0]:
		var ey: float = 0.815
		var ez: float = Statue._front_z(sx2 * 0.062, ey, P) - 0.004
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.034
		es.height = 0.05
		e.mesh = es
		e.material_override = white
		body.add_child(e)
		e.position = Vector3(sx2 * 0.062, ey, ez)
		e.scale = Vector3(1.2, 0.9, 0.55)
		var pu := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.016
		ps.height = 0.024
		pu.mesh = ps
		pu.material_override = black
		body.add_child(pu)
		pu.position = Vector3(sx2 * 0.062, ey - 0.002, ez + 0.016)
		_eyes.append([e, pu])
	_parure(body, str(opts.get("parure", PARURES[_rng.randi() % PARURES.size()])), P)
	# la bulle (ce qu'il dit) et l'étiquette VR
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 36
	bubble.pixel_size = 0.0026
	bubble.outline_size = 12
	bubble.width = 600
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.no_depth_test = true
	bubble.visible = false
	bubble.position = Vector3(0, h * 1.25, 0)
	add_child(bubble)
	vr_label = Label3D.new()
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 28
	vr_label.pixel_size = 0.0025
	vr_label.no_depth_test = true
	vr_label.visible = false
	vr_label.position = Vector3(0, h * 1.1, 0)
	vr_label.text = "Gâchette droite : parler à " + display_name
	add_child(vr_label)
	set_pose(pose_name, face)
	_line_t = _rng.randf_range(2.0, 6.0)
	_hop_t = _rng.randf_range(2.0, 6.0)


## La parure : ce qui le rend reconnaissable (et un peu coquet).
func _parure(body: Node3D, kind: String, P: Array) -> void:
	var c := func(col: Color, rough: float = 0.6, emit: float = 0.0) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = emit
		return m
	var neck_y: float = 0.56
	var neck_r: float = float(P[2]) * 1.05
	match kind:
		"fleurs", "coquillages":
			var cols: Array = [Color(0.98, 0.45, 0.6), Color(1.0, 0.85, 0.3), Color(0.98, 0.98, 0.95), Color(0.95, 0.5, 0.2), Color(0.7, 0.4, 0.95)]
			for k in range(14):
				var a: float = TAU * k / 14.0
				var b := MeshInstance3D.new()
				var s := SphereMesh.new()
				s.radius = 0.024 if kind == "fleurs" else 0.018
				s.height = s.radius * (1.6 if kind == "fleurs" else 1.2)
				b.mesh = s
				b.material_override = c.call(cols[k % cols.size()] if kind == "fleurs" else Color(0.95, 0.9, 0.82), 0.5)
				body.add_child(b)
				b.position = Vector3(sin(a) * neck_r, neck_y - 0.02 * cos(a), cos(a) * float(P[1]) * 1.25 + 0.02)
		"feuilles":
			for k2 in range(10):
				var a2: float = TAU * k2 / 10.0
				var l := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.05, 0.012, 0.09)
				l.mesh = bm
				l.material_override = c.call(Color(0.25, 0.55, 0.22), 0.7)
				body.add_child(l)
				l.position = Vector3(sin(a2) * float(P[2]) * 0.92, 1.0, cos(a2) * float(P[1]) * 1.15)
				l.rotation = Vector3(0.4, a2, 0)
		"chignon":
			var pk := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = float(P[2]) * 0.8
			cm.bottom_radius = float(P[2]) * 0.72
			cm.height = 0.12
			pk.mesh = cm
			pk.material_override = Statue.stone_mat("pukao")
			body.add_child(pk)
			pk.position = Vector3(0, 1.06, -0.01)
		"lunettes":
			for sx in [-1.0, 1.0]:
				var g := MeshInstance3D.new()
				var tm := TorusMesh.new()
				tm.inner_radius = 0.034
				tm.outer_radius = 0.044
				g.mesh = tm
				g.material_override = c.call(Color(0.95, 0.75, 0.55), 0.3)
				body.add_child(g)
				g.rotation = Vector3(PI * 0.5, 0, 0)
				g.position = Vector3(sx * 0.062, 0.815, Statue._front_z(sx * 0.062, 0.815, P) + 0.02)
		"fleur_oreille":
			var fl := MeshInstance3D.new()
			var fsm := SphereMesh.new()
			fsm.radius = 0.04
			fsm.height = 0.04
			fl.mesh = fsm
			fl.material_override = c.call(Color(1.0, 0.4, 0.5), 0.5)
			body.add_child(fl)
			fl.position = Vector3(float(P[2]) * 1.02, 0.86, -0.02)
			var hearts := MeshInstance3D.new()
			var hs := SphereMesh.new()
			hs.radius = 0.016
			hs.height = 0.02
			hearts.mesh = hs
			hearts.material_override = c.call(Color(1.0, 0.9, 0.3), 0.4, 0.4)
			body.add_child(hearts)
			hearts.position = Vector3(float(P[2]) * 1.06, 0.86, 0.01)


# =================================================================== comme un habitant

func face_height() -> float:
	return h * 0.82


func say_bubble(text: String, seconds: float) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble_clock = seconds


func say(text: String, seconds: float = 4.0) -> void:
	say_bubble(text, seconds)


func begin_talk() -> void:
	talking = true
	frozen = false
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	talking = false


func set_pose(p: String, face: Vector3 = Vector3.ZERO) -> void:
	pose = p
	if face.length() > 0.01:
		face_dir = Vector3(face.x, 0, face.z).normalized()
		rotation.y = atan2(face_dir.x, face_dir.z)
	follow = p in ["debout", "colere", "rire", "applaudir", "pointer", "mains_dos", "bras_croises", "comptoir"]
	frozen = p == "statue"


## Une réaction : rire, salut, colère, sursaut, joie (un tour sur lui-même), applaudir (des petits sauts).
func gesture(kind: String, seconds: float = 2.0) -> void:
	_gest = kind
	_gest_t = 0.0
	_gest_len = seconds
	frozen = false


## Figé en statue (le jeu du « 1, 2, 3, Moaï ! ») ou dégelé.
func freeze(on: bool) -> void:
	frozen = on


func _process(delta: float) -> void:
	_t += delta
	# la bulle s'efface
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	var player: Vector3 = main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else global_position + Vector3(0, 0, 3)
	var to_p: Vector3 = player - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	if frozen:
		model.position = Vector3.ZERO
		model.rotation = Vector3.ZERO
		return
	# il se tourne vers le joueur quand on lui parle (ou quand on s'approche, s'il est debout)
	var want: Vector3 = face_dir
	if (talking or (follow and dist < 4.0)) and dist > 0.3:
		want = to_p / dist
	rotation.y = lerp_angle(rotation.y, atan2(want.x, want.z), clampf(delta * 4.0, 0.0, 1.0))
	# les yeux clignent
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = _rng.randf_range(2.0, 5.0)
	var shut: bool = _blink_t < 0.12 or pose in ["dormir", "dormir_assis"]
	for e in _eyes:
		(e[0] as Node3D).scale.y = 0.08 if shut else 0.9
		(e[1] as Node3D).visible = not shut
	# le corps : respire, sautille de temps en temps, et les gestes
	var pos := Vector3.ZERO
	var rot := Vector3.ZERO
	match pose:
		"assis", "rire_assis", "tricot", "lire", "manger", "guitare":
			pos.y = -0.06 * h
			rot.x = -0.06
		"dormir", "allonge", "dormir_assis":
			rot.x = -0.35
			pos.y = -0.04 * h + 0.01 * sin(_t * 1.2)
		"cache":
			pos.y = -0.5 * h
	pos.y += 0.008 * h * sin(_t * 2.2)
	if _gest != "":
		_gest_t += delta
		var g: float = _gest_t
		match _gest:
			"rire":
				pos.y += absf(sin(g * 14.0)) * 0.05 * h
				rot.z = sin(g * 22.0) * 0.06
				rot.x = -0.08
			"joie":
				pos.y += absf(sin(g * PI / maxf(_gest_len, 0.1))) * 0.35 * h
				rot.y = g / maxf(_gest_len, 0.1) * TAU
			"colere":
				rot.z = sin(g * 30.0) * 0.08
				pos.y += absf(sin(g * 9.0)) * 0.03 * h
			"salut":
				rot.x = 0.45 * sin(clampf(g / maxf(_gest_len, 0.1), 0.0, 1.0) * PI)
			"sursaut":
				pos.y += maxf(0.0, sin(clampf(g / 0.45, 0.0, 1.0) * PI)) * 0.4 * h
			"applaudir":
				pos.y += absf(sin(g * 10.0)) * 0.12 * h
		if _gest_t >= _gest_len:
			_gest = ""
	elif not talking and pose == "debout":
		# un petit saut de temps en temps, comme pour se dégourdir les pieds de pierre
		_hop_t -= delta
		if _hop_t < 0.4:
			pos.y += maxf(0.0, sin((0.4 - _hop_t) / 0.4 * PI)) * 0.12 * h
		if _hop_t <= 0.0:
			_hop_t = _rng.randf_range(3.0, 8.0)
	model.position = pos
	model.rotation = rot
	# une petite phrase de temps en temps quand on est dans la pièce
	if vr_label != null:
		vr_label.visible = false
	if not talking and not lines.is_empty() and dist < 7.5:
		_line_t -= delta
		if _line_t <= 0.0 and bubble_clock <= 0.0:
			_line_t = _rng.randf_range(line_every.x, line_every.y)
			say(str(lines[_rng.randi() % lines.size()]), 3.8)

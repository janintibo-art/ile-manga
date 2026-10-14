extends Node3D
## V31 : un habitant de l'île (corps, déplacements, gestes) piloté par le cerveau commun.
## Chaque personnage = ce script + une fiche de personnalité (scripts/pnj/<nom>_v31.gd).
##  - Il va et vient entre quelques points (cabane, terrasse, feu, rivage).
##  - Il interpelle le joueur qui approche, se tourne vers lui, parle avec des gestes.
##  - Il fait partie des cibles de combat : le frapper le fâche… et il s'en souvient.

const Brain = preload("res://scripts/pnj/pnj_brain_v31.gd")
const HeroLib = preload("res://scripts/hero_v28.gd")
const WALK: float = 0.9
const TALK_REACH: float = 2.8

var main: Node
var brain
var profile: Dictionary
var display_name: String = ""
var model: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var floor_offset: float = 0.0
var points: Dictionary = {}
var links: Dictionary = {}
var at_point: String = ""
var route: Array = []
var state: String = "repos"          # repos, marche, parle
var idle_clock: float = 3.0
var gesture_clock: float = 0.0
var bubble: Label3D
var bubble_clock: float = 0.0
var vr_label: Label3D
var called_clock: float = 0.0
var player_was_near: bool = false
var parrot: Node3D
var _parrot_clock: float = 0.0
var _body: AnimatableBody3D
var current_anim: String = ""
# Cible de combat
var hit_radius: float = 0.35
var hit_height: float = 1.0


func setup(main_node: Node, profile_data: Dictionary, spots: Dictionary, graph: Dictionary, start: String) -> void:
	main = main_node
	profile = profile_data
	display_name = str(profile.get("nom", "?"))
	name = "PNJ_" + str(profile.get("id", "x"))
	brain = Brain.new()
	brain.setup(profile)
	points = spots
	links = graph
	at_point = start
	_build_body()
	global_position = points[start]
	_snap_to_floor()
	add_to_group("cibles_v28")
	add_to_group("pnj_v31")


# =================================================================== corps

func _build_body() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	model = packed.instantiate()
	add_child(model)
	model.rotation.y = 0.0
	anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	skel = found[0] if found.size() > 0 else null
	# Même bibliothèque d'animations que le héros (poses construites + clips du modèle).
	if anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
		for clip in ["Talk_with_Right_Hand_Open", "Stand_and_Drink"]:
			var a: Animation = anim.get_animation(clip)
			if a != null:
				a.loop_mode = Animation.LOOP_LINEAR
	# Teint hâlé de naufragé : le modèle tire ses couleurs de son émission (texture
	# multipliée par la couleur d'émission), c'est donc elle qu'on réchauffe.
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in range(m.mesh.get_surface_count()):
			var src: Material = m.mesh.surface_get_material(s)
			if src is StandardMaterial3D:
				var tinted: StandardMaterial3D = (src as StandardMaterial3D).duplicate()
				tinted.albedo_color = Color(0.95, 0.6, 0.4)
				tinted.emission = Color(0.95, 0.62, 0.42)
				m.set_surface_override_material(s, tinted)
	# Pieds au sol : décalage mesuré sur la boîte du modèle.
	floor_offset = 0.0
	if skel != null:
		_accessories()
	_body = AnimatableBody3D.new()
	_body.name = "Corps_collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	_body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_body.add_child(cs)
	add_child(_body)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 38
	bubble.pixel_size = 0.0028
	bubble.outline_size = 12
	bubble.width = 620
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.position = Vector3(0, 2.35, 0)
	bubble.no_depth_test = true
	bubble.visible = false
	add_child(bubble)
	vr_label = Label3D.new()
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 40
	vr_label.pixel_size = 0.0024
	vr_label.outline_size = 10
	vr_label.position = Vector3(0, 2.0, 0)
	vr_label.no_depth_test = true
	vr_label.text = "Gâchette droite : parler à " + display_name.split(" ")[0]
	vr_label.visible = false
	add_child(vr_label)


## Accroche un objet à un os ; offset et orientation donnés dans le repère du personnage
## au repos (cm, X gauche, Y haut, Z avant), objet fabriqué en mètres.
func _attach(bone_name: String, offset_cm: Vector3, node: Node3D, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var b: int = skel.find_bone(bone_name)
	if b < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone_name
	skel.add_child(att)
	var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
	var holder := Node3D.new()
	holder.transform = Transform3D(rest.inverse() * Basis.from_euler(rot_deg * (PI / 180.0)) * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * offset_cm)
	att.add_child(holder)
	holder.add_child(node)


## Accessoires : un peu d'émission, comme le modèle du personnage, pour garder les
## mêmes couleurs que lui sous la lumière bleutée du ciel.
func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.35
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 18
	return c


func _accessories() -> void:
	# Chapeau de paille cabossé.
	var hat := Node3D.new()
	var straw := _mat(Color(0.96, 0.7, 0.36), 0.95)
	_part(hat, _cyl(0.36, 0.38, 0.025), straw, Vector3.ZERO)
	_part(hat, _cyl(0.17, 0.21, 0.17), straw, Vector3(0, 0.09, 0))
	_part(hat, _cyl(0.212, 0.212, 0.04), _mat(Color(0.55, 0.12, 0.1)), Vector3(0, 0.035, 0))
	_attach("Head", Vector3(0, 41.0, 1.0), hat, Vector3(-8, 0, 6))
	# Longue barbe grise.
	var beard := Node3D.new()
	var white := _mat(Color(0.95, 0.93, 0.86), 1.0)
	_part(beard, _sphere(0.11), white, Vector3(0, -0.02, 0), Vector3(1.5, 0.7, 0.55))
	_part(beard, _sphere(0.1), white, Vector3(0, -0.15, 0.01), Vector3(1.05, 1.75, 0.45))
	_attach("Head", Vector3(0, -3.0, 15.0), beard, Vector3(6, 0, 0))
	# Gaston, le perroquet, sur l'épaule gauche.
	parrot = Node3D.new()
	var red := _mat(Color(0.82, 0.12, 0.08), 0.6)
	var blue := _mat(Color(0.1, 0.3, 0.75), 0.6)
	var yellow := _mat(Color(0.95, 0.75, 0.15), 0.5)
	_part(parrot, _sphere(0.07), red, Vector3(0, 0.1, 0), Vector3(0.95, 1.35, 1.0))
	for sx in [-1.0, 1.0]:
		_part(parrot, _sphere(0.055), blue, Vector3(sx * 0.055, 0.1, -0.01), Vector3(0.45, 1.3, 1.05), Vector3(0, 0, sx * 10))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.2, 0.015)
	parrot.add_child(head)
	_part(head, _sphere(0.05), red, Vector3.ZERO)
	_part(head, _cyl(0.0, 0.02, 0.055), yellow, Vector3(0, -0.01, 0.055), Vector3.ONE, Vector3(100, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.012), _mat(Color(0.95, 0.95, 0.9), 0.3), Vector3(sx * 0.035, 0.012, 0.03))
	_part(parrot, _cyl(0.035, 0.008, 0.22), blue, Vector3(0, -0.02, -0.07), Vector3.ONE, Vector3(-30, 0, 0))
	_part(parrot, _cyl(0.008, 0.008, 0.05), _mat(Color(0.3, 0.3, 0.3)), Vector3(0.02, 0.0, 0.01))
	_part(parrot, _cyl(0.008, 0.008, 0.05), _mat(Color(0.3, 0.3, 0.3)), Vector3(-0.02, 0.0, 0.01))
	_attach("LeftShoulder", Vector3(13.0, 9.0, -1.0), parrot)


# =================================================================== sol et déplacement

func _snap_to_floor() -> void:
	var p: Vector3 = global_position
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 3.0, 1, [_body.get_rid()])
	var hit := space.intersect_ray(q)
	var y: float = hit.position.y if not hit.is_empty() else main._height_at(p.x, p.z)
	global_position = Vector3(p.x, y + floor_offset, p.z)
	_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _face(dir: Vector3, delta: float, speed: float = 6.0) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * speed, 0.0, 1.0))


func _play(name_anim: String, blend: float = 0.25, speed: float = 1.0, from: float = -1.0) -> void:
	if anim == null or not anim.has_animation(name_anim):
		return
	if name_anim != current_anim or from >= 0.0:
		anim.play(name_anim, blend, speed)
		if from >= 0.0:
			anim.seek(from, true)
		current_anim = name_anim
	else:
		anim.play(name_anim, blend, speed)


## Chemin dans le graphe des points (parcours en largeur).
func _route_to(goal: String) -> Array:
	var prev := {at_point: ""}
	var queue: Array = [at_point]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == goal:
			break
		for nb in links.get(cur, []):
			if not prev.has(nb):
				prev[nb] = cur
				queue.append(nb)
	if not prev.has(goal):
		return []
	var path: Array = []
	var c: String = goal
	while c != at_point:
		path.push_front(c)
		c = prev[c]
	return path


# =================================================================== comportement

func _process(delta: float) -> void:
	brain.tick(delta)
	_parrot_tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	called_clock = maxf(called_clock - delta, 0.0)
	gesture_clock = maxf(gesture_clock - delta, 0.0)
	var player: Vector3 = main._player_pos_v27()
	var to_player: Vector3 = player - global_position
	var dist: float = Vector2(to_player.x, to_player.z).length()
	if vr_label != null:
		vr_label.visible = main.xr_active and state != "parle" and dist < TALK_REACH
	# Interpellation quand on arrive dans les parages.
	var near: bool = dist < 10.0 and absf(to_player.y) < 6.0
	if near and not player_was_near and called_clock <= 0.0 and state != "parle":
		var line: String = brain.call_out(main._npc_ctx_v31())
		if line != "":
			say_bubble(line, 4.5)
		called_clock = 75.0
	player_was_near = near
	match state:
		"parle":
			_face(to_player, delta)
			if gesture_clock <= 0.0:
				_play("Talk_with_Right_Hand_Open", 0.3, 0.9)
		"marche":
			_walk(delta, dist)
		_:
			if dist < 4.0:
				_face(to_player, delta, 3.0)
			if gesture_clock <= 0.0:
				_idle_anim()
			idle_clock -= delta
			if idle_clock <= 0.0 and dist > 3.0:
				_pick_destination()


func _idle_anim() -> void:
	var fam: String = brain.humeur_famille()
	if fam == "joie" and randf() < 0.002:
		gesture("rire")
	elif randf() < 0.0015:
		_play("Stand_and_Drink", 0.4)
		gesture_clock = 8.0
	elif current_anim != "v28/idle" and current_anim != "Stand_and_Drink":
		_play("v28/idle", 0.4, 0.8 if fam in ["triste", "colere"] else 1.0)
	elif current_anim == "Stand_and_Drink" and gesture_clock <= 0.0:
		_play("v28/idle", 0.4)


func _pick_destination() -> void:
	var options: Array = points.keys().filter(func(k): return k != at_point and k != "marche")
	if options.is_empty():
		idle_clock = 6.0
		return
	route = _route_to(options[randi() % options.size()])
	if route.is_empty():
		idle_clock = 6.0
		return
	state = "marche"


func _walk(delta: float, player_dist: float) -> void:
	if player_dist < 2.4 or route.is_empty():
		state = "repos"
		idle_clock = randf_range(5.0, 11.0)
		return
	var goal: Vector3 = points[route[0]]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.15:
		at_point = route.pop_front()
		if route.is_empty():
			state = "repos"
			idle_clock = randf_range(6.0, 14.0)
		return
	_face(to_goal, delta, 5.0)
	var step: Vector3 = to_goal.normalized() * minf(WALK * delta, to_goal.length())
	global_position += step
	_snap_to_floor()
	_play("Walking", 0.3, WALK / 1.0)


func gesture(kind: String) -> void:
	match kind:
		"salut":
			_play("Formal_Bow", 0.2, 1.3, 0.4)
			gesture_clock = 2.4
		"rire":
			_play("Motivational_Cheer", 0.2, 1.1, 0.6)
			gesture_clock = 2.8
		"colere":
			_play("v28/hurt", 0.1, 0.7, 0.0)
			gesture_clock = 0.8
		_:
			gesture_clock = 0.0


func say_bubble(text: String, seconds: float) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble_clock = seconds


func begin_talk() -> void:
	state = "parle"
	route.clear()
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	state = "repos"
	idle_clock = randf_range(4.0, 8.0)
	gesture_clock = 0.0


func _parrot_tick(delta: float) -> void:
	if parrot == null:
		return
	_parrot_clock += delta
	var head: Node3D = parrot.get_node_or_null("Tete")
	if head != null:
		head.rotation.y = sin(_parrot_clock * 1.7) * 0.6 + sin(_parrot_clock * 5.3) * 0.15
		head.rotation.x = sin(_parrot_clock * 2.3) * 0.15
	parrot.rotation.z = sin(_parrot_clock * 1.1) * 0.05


# =================================================================== combat

func is_hittable() -> bool:
	return true


func take_hit(_damage: int, from_pos: Vector3) -> void:
	var line: String = brain.hit(main._npc_ctx_v31())
	say_bubble(line, 3.5)
	gesture("colere")
	_face(from_pos - global_position, 1.0, 50.0)
	if state == "parle":
		main._close_dialogue_v31()


func serialize() -> Dictionary:
	return brain.serialize()


func load_data(d: Dictionary) -> void:
	brain.load_data(d)

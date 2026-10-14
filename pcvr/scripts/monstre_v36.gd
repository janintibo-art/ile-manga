extends CharacterBody3D
## V36 : un monstre du Temple englouti. Il suit la règle des cibles de combat
## (groupe « cibles_v28 », hit_radius, hit_height, is_hittable, take_hit).
## Deux espèces pour commencer :
##  - le crabe de roche : bas, rapide, pinces levées avant de frapper (1/2 cœur) ;
##  - le gardien de corail : un ancien soldat du temple pétrifié, lent, frappe fort (1 cœur)
##    avec sa lance après l'avoir levée.
## Comportement : il veille près de son poste, repère le joueur à quelques mètres, le
## poursuit sans trop s'éloigner, prépare son coup (le signal pour esquiver ou parer), frappe,
## souffle un instant. Touché, il recule et clignote ; à zéro, il s'effondre et laisse du butin.

const HeroLib = preload("res://scripts/hero_v28.gd")

const SPECS := {
	"crabe": {"pv": 8, "vitesse": 2.3, "degats": 1, "portee": 1.15, "armer": 0.55, "repos": 1.3, "vue": 9.0, "laisse": 12.0,
		"rayon": 0.5, "haut": 0.3, "nom": "Crabe de roche"},
	"gardien": {"pv": 22, "vitesse": 1.5, "degats": 2, "portee": 1.9, "armer": 0.85, "repos": 1.6, "vue": 11.0, "laisse": 13.0,
		"rayon": 0.38, "haut": 1.0, "nom": "Gardien de corail"},
}

signal died(monster: Node3D)

var manager: Node
var kind: String = "crabe"
var spec: Dictionary
var home: Vector3
var hp: int = 8
var state: String = "veille"        # veille, chasse, armer, frappe, souffle, recul, mort
var timer: float = 0.0
var hit_radius: float = 0.5
var hit_height: float = 0.3
var facing: Vector3 = Vector3.FORWARD
var _visual: Node3D
var _claws: Array = []
var _legs: Array = []
var _spear: Node3D
var _anim: AnimationPlayer
var _flash: float = 0.0
var _flash_mats: Array = []
var _clock: float = 0.0
var _knock: Vector3 = Vector3.ZERO


func setup(m: Node, k: String, at: Vector3) -> void:
	manager = m
	kind = k
	spec = SPECS[k]
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	if kind == "crabe":
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, 0.5, 0.7)
		cs.shape = box
		cs.position.y = 0.3
	else:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.32
		cap.height = 1.75
		cs.shape = cap
		cs.position.y = 0.88
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	if kind == "crabe":
		_build_crab()
	else:
		_build_guardian()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


func _mat(c: Color, rough: float = 0.6, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_flash_mats.append(m)
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _cyl(a: float, b: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = 8
	return c


## Crabe de roche : carapace bosselée couleur de pierre et de rouille, six pattes, deux pinces.
func _build_crab() -> void:
	var shell := _mat(Color(0.66, 0.34, 0.2), 0.5)
	var belly := _mat(Color(0.7, 0.55, 0.42), 0.7)
	var rock := _mat(Color(0.45, 0.43, 0.4), 0.9)
	_mesh(_visual, _sphere(0.45), shell, Vector3(0, 0.38, 0), Vector3(1.0, 0.42, 0.78))
	_mesh(_visual, _sphere(0.4), belly, Vector3(0, 0.3, 0), Vector3(0.95, 0.3, 0.72))
	for k in range(5):
		_mesh(_visual, _sphere(0.09), rock, Vector3(-0.25 + k * 0.13, 0.52, -0.05 + (k % 2) * 0.12), Vector3(1, 0.6, 1))
	for sx in [-1.0, 1.0]:
		var stalk := _mesh(_visual, _cyl(0.02, 0.025, 0.16), shell, Vector3(sx * 0.1, 0.55, 0.28))
		stalk.rotation.x = 0.3
		_mesh(_visual, _sphere(0.04), _mat(Color(0.05, 0.05, 0.05), 0.2, 0.0), Vector3(sx * 0.1, 0.64, 0.31))
		for k in range(3):
			var leg := Node3D.new()
			leg.position = Vector3(sx * 0.38, 0.32, 0.18 - k * 0.2)
			_visual.add_child(leg)
			# Patte : vers l'extérieur et vers le bas, jusqu'au sol.
			var seg := _mesh(leg, _cyl(0.025, 0.04, 0.46), shell, Vector3(sx * 0.19, -0.11, 0))
			seg.rotation.z = -sx * 2.04
			_legs.append([leg, sx, k])
		var arm := Node3D.new()
		arm.position = Vector3(sx * 0.3, 0.42, 0.3)
		_visual.add_child(arm)
		_mesh(arm, _cyl(0.045, 0.05, 0.3), shell, Vector3(0, 0.0, 0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(arm, _sphere(0.13), shell, Vector3(0, 0.02, 0.36), Vector3(0.8, 0.7, 1.3))
		_mesh(arm, _cyl(0.0, 0.06, 0.2), shell, Vector3(sx * 0.04, 0.07, 0.5), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_claws.append(arm)


## Gardien de corail : le corps du héros, couleur pierre bleutée, coraux et lance, yeux luisants.
func _build_guardian() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	_visual.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = found[0] if found.size() > 0 else null
	if _anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = _anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in range(m.mesh.get_surface_count()):
			var src: Material = m.mesh.surface_get_material(s)
			if src is StandardMaterial3D:
				# Pétrifié : toute la silhouette du soldat devient pierre bleutée.
				var stone := StandardMaterial3D.new()
				stone.albedo_color = Color(0.74, 0.78, 0.8)
				stone.roughness = 0.92
				# Une très légère lueur : on devine sa silhouette dans la pénombre.
				stone.emission_enabled = true
				stone.emission = Color(0.16, 0.22, 0.24)
				stone.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
				stone.uv1_scale = Vector3(3, 3, 3)
				m.set_surface_override_material(s, stone)
				_flash_mats.append(stone)
	var coral := _mat(Color(0.95, 0.45, 0.42), 0.7, 0.25)
	var eye := _mat(Color(0.4, 1.0, 0.95), 0.2, 4.0)
	if skel != null:
		_attach(skel, "Head", Vector3(0, 30, 10), _coral_tuft(coral))
		_attach(skel, "LeftShoulder", Vector3(14, 8, 0), _coral_tuft(coral))
		var eyes := Node3D.new()
		for sx in [-0.07, 0.07]:
			_mesh(eyes, _sphere(0.03), eye, Vector3(sx, 0, 0))
		_attach(skel, "Head", Vector3(0, 19, 19), eyes)
		_spear = Node3D.new()
		_mesh(_spear, _cyl(0.025, 0.025, 2.0), _mat(Color(0.35, 0.3, 0.25), 0.8), Vector3(0, 0.3, 0))
		_mesh(_spear, _cyl(0.0, 0.06, 0.3), _mat(Color(0.55, 0.45, 0.3), 0.3), Vector3(0, 1.45, 0))
		var att := BoneAttachment3D.new()
		att.bone_name = "RightHand"
		skel.add_child(att)
		var hold := Node3D.new()
		hold.position = Vector3(0, 8.5, 2.5)
		hold.rotation_degrees = Vector3(90, 0, 0)
		hold.scale = Vector3.ONE * 100.0
		att.add_child(hold)
		hold.add_child(_spear)
	_play("v28/idle")


func _coral_tuft(mat: Material) -> Node3D:
	var n := Node3D.new()
	for k in range(4):
		var c := _mesh(n, _cyl(0.015, 0.03, 0.16 + k * 0.03), mat, Vector3(-0.05 + k * 0.035, 0.07, 0.0))
		c.rotation.z = -0.5 + k * 0.33
		_mesh(n, _sphere(0.03), mat, c.position + Vector3(sin(-c.rotation.z) * 0.1, 0.08 + k * 0.015, 0))
	return n


func _attach(skel: Skeleton3D, bone_name: String, offset_cm: Vector3, node: Node3D) -> void:
	var b: int = skel.find_bone(bone_name)
	if b < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone_name
	skel.add_child(att)
	var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
	var holder := Node3D.new()
	holder.transform = Transform3D(rest.inverse() * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * offset_cm)
	att.add_child(holder)
	holder.add_child(node)


func _play(anim_name: String, blend: float = 0.2, speed: float = 1.0) -> void:
	if _anim != null and _anim.has_animation(anim_name) and (_anim.current_animation != anim_name or not _anim.is_playing()):
		_anim.play(anim_name, blend, speed)


# =================================================================== règle des cibles

func is_hittable() -> bool:
	return state != "mort"


func take_hit(damage: int, from_pos: Vector3) -> void:
	if state == "mort":
		return
	hp -= damage
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	_knock = away * (3.2 if kind == "crabe" else 1.6)
	var cb: Node = manager.main.combat_v28
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (0.9 if kind == "crabe" else 2.1)
		if bool(cb.get("critical")):
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, Color(0.8, 0.5, 0.4) if kind == "crabe" else Color(0.7, 0.75, 0.78))
	if hp <= 0:
		_die()
		return
	# Un coup interrompt la préparation de l'attaque (on peut « couper » l'élan).
	state = "recul"
	timer = 0.3 if kind == "crabe" else 0.22
	if kind == "gardien":
		_play("v28/hurt", 0.05)


func _die() -> void:
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	if kind == "gardien":
		_play("Knock_Down", 0.1)
	died.emit(self)


# =================================================================== comportement

func _player() -> Vector3:
	return manager.main._player_pos_v27()


func _physics_process(delta: float) -> void:
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	if state == "mort":
		timer += delta
		if kind == "crabe":
			_visual.rotation.z = minf(timer * 6.0, PI)
			_visual.position.y = sin(minf(timer * 6.0, PI)) * 0.4
		if timer > 1.6:
			_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 1.6) / 0.8, 0.01, 1.0)
		if timer > 2.4:
			visible = false
			set_physics_process(false)
		return
	if not manager.active:
		return
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if dist < float(spec["vue"]) and dy < 3.0:
				state = "chasse"
				manager.alert(self)
			elif from_home > 1.0:
				var back: Vector3 = home - global_position
				back.y = 0.0
				move = back.normalized() * float(spec["vitesse"]) * 0.5
				facing = facing.lerp(back.normalized(), delta * 4.0).normalized()
		"chasse":
			if dist > float(spec["vue"]) * 1.6 or from_home > float(spec["laisse"]) or dy > 3.0:
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				if kind == "gardien":
					_play("v28/slash3", 0.1, 0.55)
			else:
				move = dir_p * float(spec["vitesse"])
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.18
				_strike(dist, dir_p)
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle":
			if timer <= 0.0:
				state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate(delta, move.length())


func _strike(dist: float, dir_p: Vector3) -> void:
	if dist <= float(spec["portee"]) + 0.35 and facing.dot(dir_p) > 0.35:
		manager.hurt_player(int(spec["degats"]), global_position)
	if manager.main.combat_v28 != null:
		manager.main.combat_v28.puff(global_position + facing * float(spec["portee"]) * 0.8 + Vector3.UP * (0.4 if kind == "crabe" else 1.2), Color(0.85, 0.85, 0.8))


func _animate(delta: float, speed: float) -> void:
	if kind == "crabe":
		var walk: float = clampf(speed / 2.3, 0.0, 1.0)
		for l in _legs:
			var leg: Node3D = l[0]
			leg.rotation.x = sin(_clock * 14.0 + float(l[2]) * 2.1 + (0.0 if float(l[1]) > 0 else PI)) * 0.45 * walk
		var raise: float = 0.0
		if state == "armer":
			raise = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		var snap: bool = state == "frappe"
		for c in _claws:
			(c as Node3D).rotation.x = lerpf((c as Node3D).rotation.x, (-0.9 * raise) if not snap else 0.5, clampf(delta * 12.0, 0.0, 1.0))
		_visual.position.y = absf(sin(_clock * 14.0)) * 0.03 * walk
	else:
		match state:
			"chasse", "veille":
				if speed > 0.2:
					_play("Walking", 0.25, 0.75)
				else:
					_play("v28/idle", 0.3)
			"souffle":
				_play("v28/idle", 0.3, 0.6)


func _apply_flash() -> void:
	var on: bool = _flash > 0.0
	for m in _flash_mats:
		var sm: StandardMaterial3D = m
		if on:
			if not sm.has_meta("e0"):
				sm.set_meta("e0", [sm.emission_enabled, sm.emission, sm.emission_energy_multiplier])
			sm.emission_enabled = true
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 1.4
		elif sm.has_meta("e0"):
			var e: Array = sm.get_meta("e0")
			sm.emission_enabled = e[0]
			sm.emission = e[1]
			sm.emission_energy_multiplier = e[2]
			sm.remove_meta("e0")

extends CharacterBody3D
## V37 : Karkinos, le Crabe-Roi — premier boss du Temple englouti (antre à l'est de la salle
## aux colonnes). Il garde le deuxième fragment de l'amulette.
## Sa carapace encaisse presque tout (un coup ne lui retire qu'un tiers des dégâts). Il faut
## le punir quand il est vulnérable :
##  - BALAYAGE : il lève une pince (0,9 s) puis balaie devant lui -> reculer ou rouler ;
##  - ÉCRASEMENT : un cercle rouge s'élargit au sol sous le joueur, les deux pinces montent
##    (1,3 s) puis s'abattent -> sortir du cercle ; ses pinces restent coincées dans la
##    roche 3 s : il est ÉTOURDI et prend double dégâts ;
##  - à mi-vie, il devient FURIEUX : il CHARGE en travers de l'antre (il gratte le sol avant)
##    et, s'il percute un mur, il reste étourdi ; il appelle aussi des petits crabes.

signal defeated
signal health_changed(hp: int, hp_max: int)

const HP_MAX: int = 160
const Rocks = preload("res://scripts/rocks_v26.gd")

var arena: Node                       # le donjon (antre, messages, joueur)
var center: Vector3                   # centre de l'antre (monde)
var radius: float = 12.0
var hp: int = HP_MAX
var phase: int = 1
var state: String = "eveil"
var timer: float = 2.6
var facing: Vector3 = Vector3.BACK
var hit_radius: float = 1.9
var hit_height: float = 1.0
var _visual: Node3D
var _body_mesh: Node3D
var _claws: Array = []                # [pivot, mâchoire mobile]
var _legs: Array = []
var _eyes: Array = []
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _target: Vector3
var _charge_dir: Vector3
var _attacks: int = 0
var _summon_clock: float = 10.0
var _clock: float = 0.0
var _flash: float = 0.0
var _mats: Array = []
var _rise: float = 0.0


func setup(donjon: Node, at: Vector3, face: Vector3) -> void:
	arena = donjon
	center = at
	facing = face.normalized()
	name = "Karkinos_v37"
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 1.7, 2.6)
	cs.shape = box
	cs.position.y = 0.95
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	_build()
	_ring = MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 2.05
	rm.outer_radius = 2.3
	rm.rings = 32
	rm.ring_segments = 6
	_ring.mesh = rm
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.albedo_color = Color(1.0, 0.15, 0.05, 0.0)
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = _ring_mat
	_ring.scale = Vector3(1, 0.05, 1)
	_ring.top_level = true
	add_child(_ring)
	add_to_group("cibles_v28")
	global_position = at + Vector3.DOWN * 2.4
	rotation.y = atan2(facing.x, facing.z)


func _mat(c: Color, rough: float = 0.5, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats.append(m)
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
	s.radial_segments = 20
	s.rings = 10
	return s


func _cyl(a: float, b: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = 10
	return c


## Carapace rouge sombre couverte de coquillages et d'algues, huit pattes en deux segments,
## deux énormes pinces à mâchoire mobile, yeux pédonculés qui luisent.
func _build() -> void:
	var shell := _mat(Color(0.55, 0.16, 0.1), 0.45)
	var under := _mat(Color(0.78, 0.6, 0.45), 0.7)
	var tip := _mat(Color(0.18, 0.12, 0.1), 0.35)
	var weed := _mat(Color(0.2, 0.45, 0.25), 0.9)
	var barn: Material = Rocks.material(Color(0.8, 0.78, 0.72), 0.05, 0.6)
	_body_mesh = Node3D.new()
	_visual.add_child(_body_mesh)
	_mesh(_body_mesh, _sphere(1.6), shell, Vector3(0, 1.25, 0), Vector3(1.0, 0.42, 0.78))
	_mesh(_body_mesh, _sphere(1.5), under, Vector3(0, 1.05, 0), Vector3(0.95, 0.3, 0.72))
	# Bosses et piquants sur le dos
	for k in range(7):
		var a: float = TAU * k / 7.0
		_mesh(_body_mesh, _cyl(0.0, 0.16, 0.42), tip, Vector3(cos(a) * 1.25, 1.55, sin(a) * 0.95), Vector3.ONE, Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3737
	for k in range(14):
		var p := Vector3(rng.randf_range(-1.1, 1.1), 1.82, rng.randf_range(-0.8, 0.8))
		p.y -= (p.x * p.x / 1.2 + p.z * p.z / 0.64) * 0.32
		var b := _mesh(_body_mesh, Rocks.shape(3700 + k, Vector3(0.24, 0.16, 0.24), 0.8, 0.25), barn, p)
		b.rotation.y = rng.randf() * TAU
	for k in range(6):
		var w := _mesh(_body_mesh, _cyl(0.01, 0.04, 0.7), weed, Vector3(rng.randf_range(-1.2, 1.2), 1.0, rng.randf_range(-0.9, -0.5)))
		w.rotation = Vector3(0.4, 0, rng.randf_range(-0.4, 0.4))
	# Yeux
	for sx in [-0.35, 0.35]:
		_mesh(_body_mesh, _cyl(0.05, 0.07, 0.45), shell, Vector3(sx, 1.85, 1.0), Vector3.ONE, Vector3(0.3, 0, 0))
		var eye := _mesh(_body_mesh, _sphere(0.11), _mat(Color(1.0, 0.75, 0.2), 0.2, 3.0), Vector3(sx, 2.1, 1.08))
		_eyes.append(eye)
	# Pattes (quatre de chaque côté)
	for sx in [-1.0, 1.0]:
		for k in range(4):
			var hip := Node3D.new()
			hip.position = Vector3(sx * 1.35, 1.0, 0.6 - k * 0.45)
			_visual.add_child(hip)
			# Cuisse qui monte vers l'extérieur, puis tibia qui plonge jusqu'au sol.
			var upper := Node3D.new()
			upper.rotation.z = sx * 0.5
			hip.add_child(upper)
			_mesh(upper, _cyl(0.09, 0.12, 1.0), shell, Vector3(sx * 0.5, 0, 0), Vector3.ONE, Vector3(0, 0, -sx * PI * 0.5))
			var knee := Node3D.new()
			knee.position = Vector3(sx * 1.0, 0, 0)
			upper.add_child(knee)
			_mesh(knee, _sphere(0.12), shell, Vector3.ZERO)
			_mesh(knee, _cyl(0.04, 0.1, 1.6), shell, Vector3(0, -0.8, 0))
			_legs.append([hip, sx, k])
	# Pinces : pivot d'épaule, bras, pince fixe, mâchoire mobile
	for sx in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(sx * 1.1, 1.2, 1.05)
		_visual.add_child(shoulder)
		_mesh(shoulder, _cyl(0.17, 0.22, 1.0), shell, Vector3(sx * 0.2, 0.0, 0.45), Vector3.ONE, Vector3(PI * 0.5, 0, sx * 0.3))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.35, 0.05, 1.05)
		shoulder.add_child(hand)
		_mesh(hand, _sphere(0.48), shell, Vector3.ZERO, Vector3(0.9, 0.75, 1.25))
		_mesh(hand, _cyl(0.05, 0.22, 0.95), shell, Vector3(0, 0.12, 0.75), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(hand, _cyl(0.0, 0.05, 0.22), tip, Vector3(0, 0.12, 1.3), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		var jaw := Node3D.new()
		jaw.position = Vector3(0, -0.12, 0.35)
		hand.add_child(jaw)
		_mesh(jaw, _cyl(0.04, 0.16, 0.8), shell, Vector3(0, 0, 0.4), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(jaw, _cyl(0.0, 0.04, 0.2), tip, Vector3(0, 0, 0.9), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_claws.append([shoulder, jaw, sx])


# =================================================================== règle des cibles

func is_hittable() -> bool:
	return state != "mort" and state != "eveil"


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not is_hittable():
		return
	var cb: Node = arena.main.combat_v28
	var stunned: bool = state in ["coince", "sonne"]
	var dmg: int = damage * 2 if stunned else maxi(1, int(floor(damage / 3.0)))
	hp = maxi(hp - dmg, 0)
	_flash = 0.15
	health_changed.emit(hp, HP_MAX)
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * 2.6
		if stunned:
			cb.damage_number_color(at, dmg, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number_color(at, dmg, Color(0.7, 0.75, 0.8), "")
			if randf() < 0.35:
				cb.float_text(at + Vector3.UP * 0.5, "La carapace encaisse !", Color(0.8, 0.85, 0.9))
		cb.puff(global_position + Vector3.UP * 1.2 + (from_pos - global_position).normalized() * 1.2, Color(0.75, 0.35, 0.25))
	if hp <= 0:
		_die()
		return
	if phase == 1 and hp <= HP_MAX / 2:
		phase = 2
		_summon_clock = 3.0
		arena._say("Karkinos entre en furie ! Il va charger : quand il gratte le sol, écarte-toi de sa trajectoire.", 5.0)


func _die() -> void:
	state = "mort"
	timer = 0.0
	collision_layer = 0
	_ring_mat.albedo_color.a = 0.0
	defeated.emit()


# =================================================================== comportement

func _player() -> Vector3:
	return arena.main._player_pos_v27()


func _hurt_player(amount: int) -> void:
	arena.main.monstres_v36.hurt_player(amount, global_position)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_apply_flash()
	if state == "mort":
		timer += delta
		_visual.rotation.z = lerpf(_visual.rotation.z, 0.5, delta * 1.5)
		global_position.y = lerpf(global_position.y, center.y - 1.2, delta * 0.6) if timer > 2.0 else global_position.y
		for e in _eyes:
			(e as MeshInstance3D).visible = timer < 1.0 or fmod(timer, 0.3) < 0.15
		if timer > 5.0:
			set_physics_process(false)
		return
	if not arena.main.monstres_v36.active:
		return
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	var speed: float = 1.4 if phase == 1 else 2.0
	timer -= delta
	match state:
		"eveil":
			# Il sort de l'eau.
			_rise = clampf(1.0 - timer / 2.6, 0.0, 1.0)
			global_position.y = center.y - 2.4 * (1.0 - smoothstep(0.0, 1.0, _rise))
			if timer <= 0.0:
				global_position.y = center.y
				state = "approche"
		"approche":
			facing = facing.slerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
			if phase == 2 and dist > 7.0:
				_start("armer_charge", 1.2)
			elif phase == 2 and _attacks % 4 == 3:
				# Il recule pour prendre de l'élan avant de charger.
				_start("recule", 1.1)
			elif dist < 4.6:
				if _attacks % 3 == 2 or randf() < 0.35:
					_start("armer_ecrase", 1.3)
					_target = Vector3(p.x, center.y, p.z)
				else:
					_start("armer_balayage", 0.9 if phase == 1 else 0.7)
			else:
				move = dir_p * speed
		"armer_balayage":
			facing = facing.slerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				_start("balayage", 0.35)
				if dist < 4.4 and facing.dot(dir_p) > 0.3:
					_hurt_player(2)
				arena.main.combat_v28.puff(global_position + facing * 3.0 + Vector3.UP * 0.6, Color(0.8, 0.8, 0.75))
		"balayage":
			if timer <= 0.0:
				_attacks += 1
				_start("recup", 1.0 if phase == 1 else 0.7)
		"armer_ecrase":
			# Le cercle suit encore un peu le joueur, puis se fige.
			if timer > 0.5:
				_target = _target.lerp(Vector3(p.x, center.y, p.z), clampf(delta * 3.0, 0.0, 1.0))
			facing = facing.slerp((_target - global_position).normalized() * Vector3(1, 0, 1), clampf(delta * 3.0, 0.0, 1.0)).normalized()
			_ring.global_position = _target + Vector3.UP * 0.05
			_ring_mat.albedo_color.a = 0.85 * (1.0 - timer / 1.3) + 0.15
			_ring.scale = Vector3.ONE * (0.55 + 0.45 * (1.0 - timer / 1.3)) * Vector3(1, 0.05, 1)
			if timer <= 0.0:
				_ring_mat.albedo_color.a = 0.0
				var hit_d: float = Vector2(p.x - _target.x, p.z - _target.z).length()
				if hit_d < 2.3:
					_hurt_player(3)
				for k in range(5):
					arena.main.combat_v28.puff(_target + Vector3(randf_range(-1.5, 1.5), 0.2, randf_range(-1.5, 1.5)), Color(0.6, 0.55, 0.5))
				_attacks += 1
				_start("coince", 3.2)
				arena._say("Ses pinces sont coincées dans la roche ! Frappe maintenant !", 2.5)
		"coince", "sonne":
			if timer <= 0.0:
				_start("recup", 0.8)
		"armer_charge":
			facing = facing.slerp(dir_p, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			if fmod(_clock, 0.25) < delta:
				arena.main.combat_v28.puff(global_position - facing * 1.3 + Vector3.UP * 0.2, Color(0.6, 0.55, 0.5))
			if timer <= 0.0:
				_charge_dir = facing
				_start("charge", 2.2)
		"charge":
			move = _charge_dir * 9.0
			if dist < 2.4:
				_hurt_player(2)
			var wall: bool = get_slide_collision_count() > 0 and get_last_slide_collision() != null and absf(get_last_slide_collision().get_normal().y) < 0.5 and timer < 2.0
			var out: bool = Vector2(global_position.x - center.x, global_position.z - center.z).length() > radius - 1.5
			if wall or out:
				_attacks += 1
				_start("sonne", 2.6)
				arena._say("Il s'est assommé contre la paroi ! C'est le moment !", 2.5)
				for k in range(4):
					arena.main.combat_v28.puff(global_position + _charge_dir * 1.6 + Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)), Color(0.6, 0.55, 0.5))
			elif timer <= 0.0:
				_attacks += 1
				_start("recup", 1.0)
		"recule":
			move = -dir_p * 3.2
			facing = facing.slerp(dir_p, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				_attacks += 1
				_start("armer_charge", 1.2)
		"recup":
			if timer <= 0.0:
				state = "approche"
	# Phase 2 : il appelle des petits crabes.
	if phase == 2 and state != "mort":
		_summon_clock -= delta
		if _summon_clock <= 0.0:
			_summon_clock = 18.0
			arena.summon_crabs(2)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if state == "eveil" else (0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0))
	if state != "eveil":
		move_and_slide()
	# Rester dans l'antre
	var flat := Vector2(global_position.x - center.x, global_position.z - center.z)
	if flat.length() > radius - 1.2:
		flat = flat.normalized() * (radius - 1.2)
		global_position.x = center.x + flat.x
		global_position.z = center.z + flat.y
	rotation.y = atan2(facing.x, facing.z)
	_animate(delta, move.length())


func _start(s: String, t: float) -> void:
	state = s
	timer = t


func _animate(delta: float, speed: float) -> void:
	var walk: float = clampf(speed / 2.0, 0.0, 1.0) if state != "charge" else 1.0
	var rate: float = 9.0 if state != "charge" else 20.0
	for l in _legs:
		var hip: Node3D = l[0]
		hip.rotation.y = sin(_clock * rate + float(l[2]) * 1.6 + (0.0 if float(l[1]) > 0 else PI)) * 0.35 * walk
		hip.rotation.z = absf(sin(_clock * rate + float(l[2]) * 1.6)) * 0.15 * walk * float(l[1])
	var stunned: bool = state in ["coince", "sonne"]
	for c in _claws:
		var shoulder: Node3D = c[0]
		var jaw: Node3D = c[1]
		var sx: float = c[2]
		var lift: float = 0.0
		var yaw: float = 0.0
		match state:
			"armer_balayage":
				if sx > 0:
					lift = -1.1 * (1.0 - timer / 0.9)
					yaw = 0.7
			"balayage":
				if sx > 0:
					lift = -0.2
					yaw = lerpf(0.7, -1.2, 1.0 - timer / 0.35)
			"armer_ecrase":
				lift = -1.5 * (1.0 - timer / 1.3)
			"coince":
				lift = 0.75
			"charge":
				lift = -0.3
		shoulder.rotation.x = lerpf(shoulder.rotation.x, lift, clampf(delta * 10.0, 0.0, 1.0))
		shoulder.rotation.y = lerpf(shoulder.rotation.y, yaw * sx, clampf(delta * 10.0, 0.0, 1.0))
		jaw.rotation.x = 0.35 + sin(_clock * (14.0 if state.begins_with("armer") else 3.0)) * (0.3 if state.begins_with("armer") else 0.08)
	# Étourdi : les yeux tournent, le corps tangue.
	_body_mesh.rotation.z = sin(_clock * 6.0) * 0.06 if stunned else lerpf(_body_mesh.rotation.z, 0.0, delta * 5.0)
	for e in _eyes:
		(e as MeshInstance3D).position.x = signf((e as MeshInstance3D).position.x) * (0.35 + (sin(_clock * 9.0) * 0.06 if stunned else 0.0))
	_visual.position.y = absf(sin(_clock * rate)) * 0.04 * walk


func _apply_flash() -> void:
	var on: bool = _flash > 0.0
	for m in _mats:
		var sm: StandardMaterial3D = m
		if on:
			if not sm.has_meta("e0"):
				sm.set_meta("e0", [sm.emission_enabled, sm.emission, sm.emission_energy_multiplier])
			sm.emission_enabled = true
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 1.2
		elif sm.has_meta("e0"):
			var e: Array = sm.get_meta("e0")
			sm.emission_enabled = e[0]
			sm.emission = e[1]
			sm.emission_energy_multiplier = e[2]
			sm.remove_meta("e0")

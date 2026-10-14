extends Node3D
## V40 : Nâga, le Serpent des Abysses — le boss final du Temple englouti.
## Il nage dans l'anneau d'eau noire qui entoure la plate-forme de l'antre ; seuls ses
## anneaux crèvent la surface. Il suit la règle des cibles (groupe « cibles_v28 ») : ce
## nœud EST sa tête, et son corps (des anneaux qui suivent le chemin de la tête) est à part.
## On ne peut frapper sa tête que lorsqu'elle est à terre (dégâts ×2).
## Attaques :
##  - Morsure : il nage jusqu'au joueur, se dresse (cercle rouge au sol), plonge sur lui
##    (1 cœur et demi)… et reste la tête plantée dans la pierre quelques secondes.
##  - Coup de queue : une bande rouge traverse la plate-forme, puis la queue la balaie (1 cœur).
##  - Phase 2 (sous 200 PV) : crachats de venin qui laissent des flaques vertes (1/2 cœur).
##  - Phase 3 (sous 100 PV) : il plonge et devient intouchable ; il faut réveiller les trois
##    Yeux de pierre avec l'amulette. Leur rayon le foudroie : sa tête s'écrase sur la
##    plate-forme 6 secondes. On recommence jusqu'à la victoire.

signal defeated
signal health_changed(hp: int, hp_max: int)

const HP_MAX: int = 300
const RING_R: float = 14.5
const REAR_R: float = 12.6
const PLAT_R: float = 11.0
const N_SEG: int = 30

var arena: Node                           # l'antre (antre_v40.gd)
var center: Vector3                       # centre de la plate-forme, à hauteur du sol (monde)
var water_y: float
var hp: int = HP_MAX
var phase: int = 1
var state: String = "eveil"
var timer: float = 3.0
var facing: Vector3 = Vector3.BACK
var hit_radius: float = 1.6
var hit_height: float = 0.5
var theta: float = 0.0
var _dir: float = 1.0
var _from: Vector3
var _rear: Vector3
var _target: Vector3
var _trail: Array = []
var _segments: Array = []
var _body: Node3D
var _head: Node3D
var _jaw: Node3D
var _eye_mat: StandardMaterial3D
var _mats: Array = []
var _flash: float = 0.0
var _clock: float = 0.0
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _stripe: MeshInstance3D
var _stripe_mat: StandardMaterial3D
var _tail: Node3D
var _tail_a: Vector3
var _tail_b: Vector3
var _hit_done: bool = false
var _globs: Array = []                    # {node, from, to, t, mark}
var _puddles: Array = []                  # {node, pos, life}
var _puddle_clock: float = 0.0
var _attacks: int = 0
var _after: String = "nage"               # où revenir après une attaque (nage ou abysse)
var _sink: float = 0.0
var _told_head: bool = false


func setup(antre: Node, at: Vector3, water: float) -> void:
	arena = antre
	center = at
	water_y = water
	name = "Naga_v40"
	_body = Node3D.new()
	_body.name = "Corps_de_Naga"
	_body.top_level = true
	add_child(_body)
	_build()
	_ring = _decal_ring(Color(1.0, 0.15, 0.05, 0.0), 2.0)
	_stripe = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 0.02, 1)
	_stripe.mesh = bm
	_stripe_mat = _unshaded(Color(1.0, 0.12, 0.05, 0.0))
	_stripe.material_override = _stripe_mat
	_stripe.top_level = true
	add_child(_stripe)
	_tail = Node3D.new()
	_tail.top_level = true
	_tail.visible = false
	add_child(_tail)
	var skin: StandardMaterial3D = _mats[0]
	for k in range(12):
		var mi := MeshInstance3D.new()
		mi.mesh = _sphere(0.75 - k * 0.04)
		mi.material_override = skin
		_tail.add_child(mi)
	add_to_group("cibles_v28")
	theta = atan2((arena.main._player_pos_v27() - center).z, (arena.main._player_pos_v27() - center).x) + PI
	global_position = _ring_pos(theta, water_y - 3.0)
	for k in range(N_SEG * 2 + 4):
		_trail.append(_ring_pos(theta - k * 0.03, water_y - 1.0))
	_rear = _ring_pos(theta, water_y + 5.5, REAR_R)
	_from = global_position


# =================================================================== modèle

func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.no_depth_test = false
	return m


func _decal_ring(c: Color, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.25
	tm.outer_radius = r
	tm.rings = 36
	tm.ring_segments = 6
	mi.mesh = tm
	mi.material_override = _unshaded(c)
	mi.scale = Vector3(1, 0.05, 1)
	mi.top_level = true
	add_child(mi)
	if mi.material_override is StandardMaterial3D:
		_ring_mat = mi.material_override
	return mi


func _mat(c: Color, rough: float = 0.4, emit: float = 0.0, tex: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if tex:
		m.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
		m.normal_enabled = true
		m.normal_texture = load("res://assets/textures/jungle/jungle_rock_n.png")
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.9, 0.9, 0.9)
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats.append(m)
	return m


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 18
	s.rings = 10
	return s


func _cone(a: float, b: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = 8
	return c


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Tête construite le long de -Z (look_at), corps en anneaux qui s'affinent, crête dorsale.
func _build() -> void:
	var skin := _mat(Color(0.13, 0.22, 0.2), 0.35, 0.0, true)
	var belly := _mat(Color(0.55, 0.52, 0.38), 0.6)
	var crest := _mat(Color(0.25, 0.9, 0.5), 0.3, 1.2)
	var bone := _mat(Color(0.92, 0.9, 0.82), 0.4)
	_eye_mat = _mat(Color(0.4, 1.0, 0.55), 0.1, 5.0)
	var dark := _mat(Color(0.05, 0.02, 0.02), 0.9)
	_head = Node3D.new()
	add_child(_head)
	_mesh(_head, _sphere(0.95), skin, Vector3(0, 0.15, 0), Vector3(1.0, 0.62, 1.55))
	_mesh(_head, _sphere(0.6), skin, Vector3(0, 0.1, -1.15), Vector3(0.95, 0.55, 1.0))
	_mesh(_head, _sphere(1.6), skin, Vector3(0, 0.4, 1.2), Vector3(1.5, 1.25, 0.25), Vector3(-0.35, 0, 0))
	for sx in [-1.0, 1.0]:
		_mesh(_head, _sphere(0.17), _eye_mat, Vector3(sx * 0.48, 0.45, -0.55))
		_mesh(_head, _sphere(0.08), dark, Vector3(sx * 0.48, 0.47, -0.67), Vector3(0.4, 1.0, 0.3))
		var horn := _mesh(_head, _cone(0.0, 0.16, 1.1), bone, Vector3(sx * 0.45, 0.75, 0.55))
		horn.rotation = Vector3(-1.1, 0, sx * -0.35)
	# Une lueur verte autour de la tête : on le voit venir dans le noir.
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 1.0, 0.7)
	glow.light_energy = 1.8
	glow.omni_range = 8.0
	glow.position = Vector3(0, 1.2, -1.5)
	_head.add_child(glow)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, -0.15, 0.35)
	_head.add_child(_jaw)
	_mesh(_jaw, _sphere(0.75), belly, Vector3(0, -0.12, -0.9), Vector3(0.9, 0.35, 1.45))
	for sx in [-1.0, 1.0]:
		var fang := _mesh(_head, _cone(0.0, 0.07, 0.5), bone, Vector3(sx * 0.32, -0.25, -1.45))
		fang.rotation.x = PI
	for k in range(N_SEG):
		var t: float = float(k) / float(N_SEG - 1)
		var seg := Node3D.new()
		_body.add_child(seg)
		var r: float = 0.95 - t * 0.68
		_mesh(seg, _sphere(r), skin, Vector3.ZERO)
		_mesh(seg, _sphere(r * 0.92), belly, Vector3(0, -r * 0.22, 0), Vector3(1.0, 0.7, 1.0))
		if k % 2 == 0:
			_mesh(seg, _cone(0.0, r * 0.28, r * 0.9), crest, Vector3(0, r * 1.05, 0))
		_segments.append(seg)


# =================================================================== règle des cibles

func is_hittable() -> bool:
	return state in ["coince", "foudroye"]


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not is_hittable():
		return
	var dmg: int = damage * 2
	hp = maxi(hp - dmg, 0)
	_flash = 0.15
	health_changed.emit(hp, HP_MAX)
	var cb: Node = arena.main.combat_v28
	if cb != null:
		cb.damage_number_color(global_position + Vector3.UP * 1.8, dmg, Color(1.0, 0.55, 0.2), " !")
		cb.puff(global_position + Vector3.UP * 0.6 + (from_pos - global_position).normalized() * 0.8, Color(0.3, 0.6, 0.45))
	if hp <= 0:
		_die()
		return
	if phase == 1 and hp <= 200:
		phase = 2
		arena.say("Nâga siffle de rage ! Il va cracher son venin : ne reste pas dans les flaques vertes.", 5.0)
	if phase < 3 and hp <= 100:
		phase = 3
		_after = "abysse"
		_tail.visible = false
		_stripe_mat.albedo_color.a = 0.0
		_ring_mat.albedo_color.a = 0.0
		_go_back()
		arena.say("Nâga plonge dans les abysses : tu ne peux plus l'atteindre ! Les trois Yeux de pierre s'éveillent… réveille-les avec l'amulette (E).", 7.0)
		arena.activate_eyes(true)


func _die() -> void:
	state = "mort"
	timer = 0.0
	_ring_mat.albedo_color.a = 0.0
	_stripe_mat.albedo_color.a = 0.0
	_tail.visible = false
	for g in _globs:
		(g["node"] as Node3D).queue_free()
		(g["mark"] as Node3D).queue_free()
	_globs.clear()
	for p in _puddles:
		(p["node"] as Node3D).queue_free()
	_puddles.clear()
	defeated.emit()


## Les trois Yeux sont éveillés : le rayon le foudroie.
func stun() -> void:
	if state == "mort":
		return
	_tail.visible = false
	_stripe_mat.albedo_color.a = 0.0
	_ring_mat.albedo_color.a = 0.0
	var p: Vector3 = arena.main._player_pos_v27()
	theta = _angle_of(p)
	_from = global_position
	_rear = _ring_pos(theta, water_y + 6.0, REAR_R)
	var to_c: Vector3 = (center - _ring_pos(theta, center.y, PLAT_R)).normalized()
	_target = _ring_pos(theta, center.y + 0.7, PLAT_R - 2.2)
	facing = to_c
	_start("foudroye_chute", 1.2)
	arena.say("Les trois rayons frappent Nâga ! Sa tête s'écrase sur la plate-forme : FRAPPE !", 4.0)


# =================================================================== outils

func _ring_pos(a: float, y: float, r: float = RING_R) -> Vector3:
	return Vector3(center.x + cos(a) * r, y, center.z + sin(a) * r)


func _angle_of(p: Vector3) -> float:
	return atan2(p.z - center.z, p.x - center.x)


func _player() -> Vector3:
	return arena.main._player_pos_v27()


func _hurt(amount: int) -> void:
	arena.main.monstres_v36.hurt_player(amount, global_position)


func _start(s: String, t: float) -> void:
	state = s
	timer = t
	_hit_done = false


func _go_back() -> void:
	_from = global_position
	_start("retour", 1.0)


func _clamp_platform(p: Vector3, r_max: float) -> Vector3:
	var off := Vector3(p.x - center.x, 0, p.z - center.z)
	if off.length() > r_max:
		off = off.normalized() * r_max
	return Vector3(center.x + off.x, center.y, center.z + off.z)


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if arena == null:
		return
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_apply_flash()
	timer -= delta
	var p: Vector3 = _player()
	var pa: float = _angle_of(p)
	match state:
		"eveil":
			var k: float = clampf(1.0 - timer / 3.0, 0.0, 1.0)
			global_position = _from.lerp(_rear, k * k * (3.0 - 2.0 * k))
			facing = facing.lerp((p - global_position) * Vector3(1, 0, 1), delta * 3.0).normalized()
			if timer <= 0.0:
				_go_back()
				_after = "nage"
		"nage":
			theta += _dir * 0.45 * delta
			global_position = _ring_pos(theta, water_y - 0.45 + sin(_clock * 2.0) * 0.15)
			facing = Vector3(-sin(theta), 0, cos(theta)) * _dir
			if timer <= 0.0:
				_choose()
		"abysse":
			theta += _dir * 0.6 * delta
			global_position = _ring_pos(theta, water_y - 3.0)
			facing = Vector3(-sin(theta), 0, cos(theta)) * _dir
			if timer <= 0.0:
				if randf() < 0.5:
					_begin_tail(p)
				else:
					_start("approche_venin", 1.5)
		"approche", "approche_venin":
			var dth: float = wrapf(pa - theta, -PI, PI)
			theta += clampf(dth, -1.8 * delta, 1.8 * delta)
			global_position = _ring_pos(theta, (water_y - 0.45) if _after == "nage" else (water_y - 3.0))
			facing = Vector3(-sin(theta), 0, cos(theta)) * signf(dth if absf(dth) > 0.01 else 1.0)
			if absf(dth) < 0.12 or timer <= 0.0:
				_from = global_position
				_rear = _ring_pos(theta, water_y + 5.5, REAR_R)
				_start("surgir" if state == "approche" else "surgir_venin", 0.8)
		"surgir", "surgir_venin":
			var k2: float = clampf(1.0 - timer / 0.8, 0.0, 1.0)
			global_position = _from.lerp(_rear, k2)
			facing = facing.lerp((p - global_position) * Vector3(1, 0, 1), delta * 6.0).normalized()
			if timer <= 0.0:
				if state == "surgir":
					_target = _clamp_platform(p, PLAT_R - 0.8)
					_start("armer_morsure", 1.0)
				else:
					_start("armer_venin", 0.8)
		"armer_morsure":
			_target = _clamp_platform(_target.lerp(p, delta * 2.5), PLAT_R - 0.8)
			global_position = _rear + Vector3(sin(_clock * 3.0) * 0.4, sin(_clock * 5.0) * 0.2 - (1.0 - timer) * 0.8, 0)
			facing = facing.lerp((_target - global_position) * Vector3(1, 0, 1), delta * 6.0).normalized()
			_ring.global_position = _target + Vector3.UP * 0.05
			_ring_mat.albedo_color.a = 0.35 + 0.4 * absf(sin(_clock * 10.0))
			_jaw.rotation.x = lerpf(_jaw.rotation.x, 0.5, delta * 6.0)
			if timer <= 0.0:
				_from = global_position
				_start("morsure", 0.35)
		"morsure":
			var k3: float = clampf(1.0 - timer / 0.35, 0.0, 1.0)
			global_position = _from.lerp(_target + Vector3.UP * 0.7, k3 * k3)
			if timer <= 0.0:
				_ring_mat.albedo_color.a = 0.0
				_jaw.rotation.x = 0.15
				var off: Vector3 = (p - _target) * Vector3(1, 0, 1)
				if off.length() < 2.3 and absf(p.y - _target.y) < 2.0:
					_hurt(3)
				if arena.main.combat_v28 != null:
					arena.main.combat_v28.puff(_target + Vector3.UP * 0.3, Color(0.6, 0.58, 0.52))
				_start("coince", 2.8)
				if not _told_head:
					_told_head = true
					arena.say("Ses crocs sont plantés dans la pierre : sa tête est à terre, FRAPPE !", 3.5)
		"coince":
			global_position = _target + Vector3.UP * (0.7 + sin(_clock * 14.0) * 0.04)
			if timer <= 0.0:
				_attacks += 1
				_go_back()
		"armer_queue":
			_stripe_mat.albedo_color.a = 0.25 + 0.3 * absf(sin(_clock * 9.0))
			theta += _dir * 0.45 * delta
			global_position = _ring_pos(theta, (water_y - 0.45) if _after == "nage" else (water_y - 3.0))
			if timer <= 0.0:
				_stripe_mat.albedo_color.a = 0.0
				_tail.visible = true
				_start("queue", 0.75)
		"queue":
			var k4: float = clampf(1.0 - timer / 0.75, 0.0, 1.0)
			_place_tail(k4)
			var seg_d: float = _dist_to_segment(p * Vector3(1, 0, 1), _tail_a * Vector3(1, 0, 1), _tail_b * Vector3(1, 0, 1))
			var front: float = (p - _tail_a).dot((_tail_b - _tail_a).normalized()) / _tail_a.distance_to(_tail_b)
			if not _hit_done and seg_d < 1.7 and front <= k4 + 0.1 and absf(p.y - center.y) < 2.5:
				_hit_done = true
				_hurt(2)
			if timer <= 0.0:
				_tail.visible = false
				_start(_after, 2.2 if _after == "nage" else 3.5)
		"armer_venin":
			global_position = _rear + Vector3(0, sin(_clock * 4.0) * 0.2, 0)
			facing = facing.lerp((p - global_position) * Vector3(1, 0, 1), delta * 6.0).normalized()
			_jaw.rotation.x = lerpf(_jaw.rotation.x, 0.6, delta * 6.0)
			if timer <= 0.0:
				_spit(p)
				_start("venin", 0.6)
		"venin":
			if timer <= 0.0:
				_jaw.rotation.x = 0.0
				_go_back()
		"foudroye_chute":
			var k5: float = clampf(1.0 - timer / 1.2, 0.0, 1.0)
			var mid: Vector3 = _from.lerp(_rear, 0.6)
			global_position = (_from.lerp(mid, k5)).lerp(mid.lerp(_target, k5), k5)
			if timer <= 0.0:
				if arena.main.combat_v28 != null:
					arena.main.combat_v28.puff(_target, Color(0.4, 1.0, 0.6))
				_start("foudroye", 6.0)
		"foudroye":
			global_position = _target + Vector3(sin(_clock * 18.0) * 0.05, 0, 0)
			_jaw.rotation.x = 0.35
			if timer <= 0.0:
				_jaw.rotation.x = 0.0
				arena.activate_eyes(true)
				_go_back()
		"retour":
			var back_y: float = (water_y - 0.45) if _after == "nage" else (water_y - 3.0)
			var home: Vector3 = _ring_pos(theta, back_y)
			var k6: float = clampf(1.0 - timer / 1.0, 0.0, 1.0)
			global_position = _from.lerp(home, k6)
			if timer <= 0.0:
				_start(_after, randf_range(1.6, 2.8) if _after == "nage" else 3.0)
				_dir = -_dir if randf() < 0.3 else _dir
		"mort":
			_sink += delta
			global_position += Vector3.DOWN * delta * (0.4 + _sink * 0.3)
			_head.rotation.z = minf(_sink * 0.4, 0.8)
	_update_body(delta)
	_update_globs(delta)
	_update_puddles(delta, p)
	if facing.length() > 0.01 and state != "mort":
		_head.look_at(_head.global_position + Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP)
		if state in ["morsure", "foudroye_chute"]:
			_head.rotate_object_local(Vector3.RIGHT, -0.5)
		elif state in ["armer_morsure", "armer_venin", "surgir", "surgir_venin"]:
			_head.rotate_object_local(Vector3.RIGHT, -0.25)


## Choix de la prochaine attaque.
func _choose() -> void:
	var p: Vector3 = _player()
	var r: float = randf()
	if phase >= 2 and r < 0.35:
		_start("approche_venin", 2.5)
	elif r < (0.72 if phase == 1 else 0.75) or _attacks == 0:
		_start("approche", 2.5)
	else:
		_begin_tail(p)


func _begin_tail(p: Vector3) -> void:
	# Une corde de la plate-forme qui passe par le joueur, perpendiculaire au rayon.
	var off := Vector3(p.x - center.x, 0, p.z - center.z)
	var d: float = minf(off.length(), PLAT_R - 1.5)
	var radial: Vector3 = off.normalized() if off.length() > 0.3 else Vector3(1, 0, 0)
	var tang := Vector3(-radial.z, 0, radial.x)
	var half: float = sqrt(maxf(PLAT_R * PLAT_R - d * d, 4.0)) + 1.5
	var mid: Vector3 = center + radial * d
	if randf() < 0.5:
		tang = -tang
	_tail_a = mid - tang * half + Vector3.UP * 0.6
	_tail_b = mid + tang * half + Vector3.UP * 0.6
	_stripe.global_position = mid + Vector3.UP * 0.03
	_stripe.scale = Vector3(3.2, 1, half * 2.0)
	_stripe.rotation = Vector3(0, atan2(tang.x, tang.z), 0)
	_stripe_mat.albedo_color.a = 0.3
	_start("armer_queue", 1.4)


func _place_tail(k: float) -> void:
	var n: int = _tail.get_child_count()
	for i in range(n):
		var u: float = clampf(k * 1.3 - float(i) / float(n) * 0.3, 0.0, 1.0)
		var pt: Vector3 = _tail_a.lerp(_tail_b, u)
		var rise: float = sin(clampf(u, 0.0, 1.0) * PI) * 0.6
		(_tail.get_child(i) as Node3D).global_position = pt + Vector3.UP * (rise - (0.0 if u > 0.0 else 1.5))


func _dist_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _spit(p: Vector3) -> void:
	var mouth: Vector3 = global_position + facing * 1.2
	for k in range(3):
		var off := Vector3(randf_range(-2.4, 2.4), 0, randf_range(-2.4, 2.4)) if k > 0 else Vector3.ZERO
		var to: Vector3 = _clamp_platform(p + off, PLAT_R - 1.0)
		var g := MeshInstance3D.new()
		g.mesh = _sphere(0.28)
		g.material_override = _unshaded(Color(0.35, 1.0, 0.3, 0.9))
		g.top_level = true
		add_child(g)
		g.global_position = mouth
		var mark := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.25
		tm.outer_radius = 1.45
		tm.rings = 28
		tm.ring_segments = 6
		mark.mesh = tm
		mark.material_override = _unshaded(Color(0.4, 1.0, 0.3, 0.55))
		mark.scale = Vector3(1, 0.05, 1)
		mark.top_level = true
		add_child(mark)
		mark.global_position = to + Vector3.UP * 0.05
		_globs.append({"node": g, "from": mouth, "to": to, "t": -k * 0.15, "mark": mark})


func _update_globs(delta: float) -> void:
	for g in _globs.duplicate():
		g["t"] = float(g["t"]) + delta
		var t: float = clampf(float(g["t"]) / 1.0, 0.0, 1.0)
		var a: Vector3 = g["from"]
		var b: Vector3 = g["to"]
		(g["node"] as Node3D).global_position = a.lerp(b, t) + Vector3.UP * sin(t * PI) * 3.0
		if float(g["t"]) >= 1.0:
			(g["node"] as Node3D).queue_free()
			(g["mark"] as Node3D).queue_free()
			_globs.erase(g)
			var pud := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 1.5
			cm.bottom_radius = 1.5
			cm.height = 0.02
			cm.radial_segments = 24
			pud.mesh = cm
			var pm := _unshaded(Color(0.3, 0.9, 0.25, 0.6))
			pud.material_override = pm
			pud.top_level = true
			add_child(pud)
			pud.global_position = b + Vector3.UP * 0.04
			_puddles.append({"node": pud, "pos": b, "life": 6.0, "mat": pm})


func _update_puddles(delta: float, p: Vector3) -> void:
	_puddle_clock = maxf(_puddle_clock - delta, 0.0)
	for pd in _puddles.duplicate():
		pd["life"] = float(pd["life"]) - delta
		(pd["mat"] as StandardMaterial3D).albedo_color.a = clampf(float(pd["life"]) / 2.0, 0.0, 0.6)
		var q: Vector3 = pd["pos"]
		if _puddle_clock <= 0.0 and Vector2(p.x - q.x, p.z - q.z).length() < 1.5 and absf(p.y - q.y) < 1.5:
			_puddle_clock = 0.8
			_hurt(1)
		if float(pd["life"]) <= 0.0:
			(pd["node"] as Node3D).queue_free()
			_puddles.erase(pd)


## Les anneaux suivent le chemin parcouru par la tête.
func _update_body(_delta: float) -> void:
	var hp_pos: Vector3 = global_position
	if _trail.is_empty() or hp_pos.distance_to(_trail[0]) > 0.4:
		_trail.push_front(hp_pos)
		while _trail.size() > N_SEG * 2 + 6:
			_trail.pop_back()
	for k in range(_segments.size()):
		var idx: int = mini((k + 1) * 2, _trail.size() - 1)
		var pt: Vector3 = _trail[idx]
		if state == "mort":
			pt += Vector3.DOWN * _sink * 0.8
		(_segments[k] as Node3D).global_position = pt + Vector3.UP * sin(_clock * 3.0 + k * 0.5) * 0.05


func _apply_flash() -> void:
	var on: bool = _flash > 0.0
	for m in _mats:
		var sm: StandardMaterial3D = m
		if on:
			if not sm.has_meta("e0"):
				sm.set_meta("e0", [sm.emission_enabled, sm.emission, sm.emission_energy_multiplier])
			sm.emission_enabled = true
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 1.0
		elif sm.has_meta("e0"):
			var e: Array = sm.get_meta("e0")
			sm.emission_enabled = e[0]
			sm.emission = e[1]
			sm.emission_energy_multiplier = e[2]
			sm.remove_meta("e0")

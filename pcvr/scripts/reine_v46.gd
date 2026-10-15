extends Node3D
## V46 : la Reine des Ronces — boss final du Royaume des Racines.
## Une grande fée (2,6 m) à la robe d'épines et aux ailes noires déchirées, couronne de
## ronces, yeux magenta. Elle vole hors de portée et attaque :
##  - Ronces jaillissantes : trois cercles rouges suivent le joueur ; une seconde après, des
##    épines jaillissent du sol (1 cœur).
##  - Pluie d'épines : elle brille, puis lance un éventail de cinq épines (1/2 cœur chacune).
## Après trois attaques, épuisée, elle se pose : c'est le moment de frapper.
## Phase 2 (sous 160 PV) : plus rapide, et elle appelle deux araignées de cristal.
## Phase 3 (sous 80 PV) : un bouclier d'épines la protège ; les trois roses de lumière
## (ronces_v46.gd) le brisent et la foudroient : 6 secondes à terre, coups doublés.
## Elle suit la règle des cibles (groupe « cibles_v28 »).

signal defeated
signal health_changed(hp: int, hp_max: int)

const HP_MAX: int = 240
const HOVER: float = 3.6
const ORBIT: float = 6.0

var arena: Node
var center: Vector3
var hp: int = HP_MAX
var phase: int = 1
var state: String = "eveil"
var timer: float = 3.0
var hit_radius: float = 0.8
var hit_height: float = 1.2
var _look: Node3D
var _wings: Array = []
var _eye_mat: StandardMaterial3D
var _mats: Array = []
var _shield: MeshInstance3D
var _shield_mat: StandardMaterial3D
var _angle: float = 0.0
var _attacks: int = 0
var _clock: float = 0.0
var _flash: float = 0.0
var _from: Vector3
var _to: Vector3
var _circles: Array = []                 # {node, spikes, pos, t, done}
var _darts: Array = []                   # {node, vel, life}
var _queue: Array = []
var _queue_clock: float = 0.0


func setup(a: Node, c: Vector3) -> void:
	arena = a
	center = c
	name = "Reine_des_Ronces"
	_look = build_look(false, arena.main._soft_dot_v24())
	add_child(_look)
	for w in _look.find_children("Aile_*", "Node3D", true, false):
		_wings.append(w)
	_eye_mat = _look.get_meta("yeux")
	for mi in _look.find_children("*", "MeshInstance3D", true, false):
		var m: Material = (mi as MeshInstance3D).material_override
		if m is StandardMaterial3D and not _mats.has(m):
			_mats.append(m)
	# Bouclier d'épines (phase 3)
	_shield = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	sm.radial_segments = 20
	sm.rings = 10
	_shield.mesh = sm
	_shield_mat = StandardMaterial3D.new()
	_shield_mat.albedo_color = Color(0.5, 0.1, 0.3, 0.3)
	_shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_mat.emission_enabled = true
	_shield_mat.emission = Color(0.8, 0.15, 0.45)
	_shield_mat.emission_energy_multiplier = 1.2
	_shield_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield.material_override = _shield_mat
	_shield.position = Vector3(0, 1.4, 0)
	_shield.visible = false
	add_child(_shield)
	var throne: Vector3 = center + (arena.s.global_transform.basis * Vector3(0, 0, -11.0))
	global_position = throne + Vector3.UP * 0.9
	_from = global_position
	_to = center + Vector3.UP * HOVER + (throne - center).normalized() * ORBIT
	add_to_group("cibles_v28")


## La silhouette (aussi utilisée pour Églantine, purifiée).
static func build_look(pure: bool, dot: Texture2D) -> Node3D:
	var root := Node3D.new()
	root.name = "Silhouette"
	var robe_c: Color = Color(0.95, 0.85, 0.95) if pure else Color(0.16, 0.06, 0.14)
	var skin_c: Color = Color(1.0, 0.9, 0.88) if pure else Color(0.82, 0.78, 0.84)
	var hair_c: Color = Color(1.0, 0.78, 0.6) if pure else Color(0.08, 0.04, 0.08)
	var eye_c: Color = Color(0.45, 0.75, 1.0) if pure else Color(1.0, 0.15, 0.6)
	var mk := func(c: Color, glow: float, rough: float = 0.5) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
		return m
	var robe: StandardMaterial3D = mk.call(robe_c, 0.25 if pure else 0.08, 0.6)
	var skin: StandardMaterial3D = mk.call(skin_c, 0.2)
	var hair: StandardMaterial3D = mk.call(hair_c, 0.2 if pure else 0.05, 0.4)
	var eye: StandardMaterial3D = mk.call(eye_c, 4.0, 0.2)
	var thorn: StandardMaterial3D = mk.call(Color(0.1, 0.04, 0.08), 0.05, 0.4)
	var gold: StandardMaterial3D = mk.call(Color(1.0, 0.85, 0.5), 0.6, 0.3)
	gold.metallic = 0.8
	var flower: StandardMaterial3D = mk.call(Color(1.0, 0.6, 0.75), 0.8)
	root.set_meta("yeux", eye)
	var part := func(mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = pos
		mi.rotation = rot
		mi.scale = scl
		root.add_child(mi)
		return mi
	var cyl := func(a: float, b: float, h: float, segs: int = 14) -> CylinderMesh:
		var c := CylinderMesh.new()
		c.top_radius = a
		c.bottom_radius = b
		c.height = h
		c.radial_segments = segs
		return c
	var sph := func(r: float) -> SphereMesh:
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 16
		s.rings = 8
		return s
	# Robe longue en corolle, en lambeaux
	part.call(cyl.call(0.24, 0.95, 1.7, 20), robe, Vector3(0, 0.85, 0))
	for k in range(10):
		var a: float = TAU * k / 10.0
		part.call(sph.call(0.3), robe, Vector3(cos(a) * 0.75, 0.15, sin(a) * 0.75), Vector3(0.2 * sin(a), -a, -0.2 * cos(a)), Vector3(0.6, 0.35, 0.25))
	# Épines sur la robe (ou petites fleurs, une fois purifiée)
	for k in range(18):
		var a2: float = k * 2.4
		var y: float = 0.4 + float(k % 6) * 0.22
		var rr: float = lerpf(0.9, 0.3, (y - 0.0) / 1.7)
		if pure:
			part.call(sph.call(0.05), flower, Vector3(cos(a2) * rr, y, sin(a2) * rr))
		else:
			part.call(cyl.call(0.0, 0.05, 0.28, 5), thorn, Vector3(cos(a2) * rr, y, sin(a2) * rr), Vector3(0, -a2, PI * 0.5))
	# Buste, bras
	part.call(cyl.call(0.2, 0.26, 0.6), robe, Vector3(0, 1.95, 0))
	for sx in [-1.0, 1.0]:
		part.call(cyl.call(0.06, 0.07, 0.75), skin, Vector3(sx * 0.33, 1.85, 0.08), Vector3(0.4, 0, sx * 0.55))
		part.call(sph.call(0.07), skin, Vector3(sx * 0.53, 1.55, 0.2))
	# Tête, yeux, chevelure
	part.call(cyl.call(0.06, 0.08, 0.15), skin, Vector3(0, 2.3, 0))
	part.call(sph.call(0.19), skin, Vector3(0, 2.52, 0.02), Vector3.ZERO, Vector3(0.95, 1.1, 1.0))
	for sx in [-1.0, 1.0]:
		part.call(sph.call(0.04), eye, Vector3(sx * 0.07, 2.55, 0.18), Vector3.ZERO, Vector3(1.2, 0.7, 0.5))
		part.call(cyl.call(0.0, 0.03, 0.12, 5), skin, Vector3(sx * 0.19, 2.56, 0.0), Vector3(0, 0, sx * -1.2))
	part.call(sph.call(0.21), hair, Vector3(0, 2.58, -0.04), Vector3.ZERO, Vector3(1.05, 1.05, 1.0))
	part.call(sph.call(0.2), hair, Vector3(0, 1.95, -0.2), Vector3(0.1, 0, 0), Vector3(1.1, 2.8, 0.45))
	# Couronne : ronces noires, ou fleurs sur un anneau d'or
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.21
	part.call(tm, gold if pure else thorn, Vector3(0, 2.72, 0), Vector3(0.15, 0, 0))
	for k in range(9):
		var a3: float = TAU * k / 9.0
		if pure:
			part.call(sph.call(0.045), flower, Vector3(cos(a3) * 0.19, 2.76, sin(a3) * 0.19))
		else:
			part.call(cyl.call(0.0, 0.03, 0.22 + 0.08 * (k % 2), 5), thorn, Vector3(cos(a3) * 0.19, 2.85, sin(a3) * 0.19), Vector3(sin(a3) * 0.3, 0, -cos(a3) * 0.3))
	# Ailes : déchirées et noires, ou lumineuses et roses
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	if pure:
		wm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		wm.albedo_color = Color(1.0, 0.75, 0.9, 0.5)
	else:
		wm.albedo_color = Color(0.12, 0.03, 0.1, 0.82)
	for sx in [-1.0, 1.0]:
		for up in [1.0, -1.0]:
			var hinge := Node3D.new()
			hinge.name = "Aile_%d_%d" % [int(sx), int(up)]
			hinge.position = Vector3(sx * 0.1, 2.05, -0.22)
			root.add_child(hinge)
			var w := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.9 if up > 0 else 0.6
			sm.height = sm.radius * 2.0
			sm.radial_segments = 14
			sm.rings = 6
			w.mesh = sm
			w.material_override = wm
			w.scale = Vector3(1.0, 0.55, 0.04)
			w.position = Vector3(sx * (0.85 if up > 0 else 0.55), up * 0.35, 0)
			w.rotation.z = up * sx * 0.45
			hinge.add_child(w)
			hinge.set_meta("cote", sx)
	# Bâton de ronces (seulement maudite)
	if not pure:
		part.call(cyl.call(0.03, 0.04, 2.3, 6), thorn, Vector3(0.58, 1.3, 0.25), Vector3(0, 0, -0.1))
		part.call(sph.call(0.12), eye, Vector3(0.69, 2.45, 0.25))
	var halo := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(3.0, 3.0)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(1.0, 0.75, 0.9, 0.35) if pure else Color(0.6, 0.05, 0.3, 0.3)
	hm.albedo_texture = dot
	q.material = hm
	halo.mesh = q
	halo.position = Vector3(0, 1.6, 0)
	root.add_child(halo)
	return root


# =================================================================== règle des cibles

func is_hittable() -> bool:
	if state == "foudroyee":
		return true
	return state == "fatigue" and phase < 3


func take_hit(damage: int, from_pos: Vector3) -> void:
	var cb: Node = arena.main.combat_v28
	if state == "fatigue" and phase >= 3:
		if cb != null:
			cb.float_text(global_position + Vector3.UP * 2.6, "Bouclier d'épines !", Color(1.0, 0.5, 0.7))
		return
	if not is_hittable():
		return
	var dmg: int = damage * (2 if state == "foudroyee" else 1) + (1 if state == "fatigue" else 0)
	hp = maxi(hp - dmg, 0)
	_flash = 0.15
	health_changed.emit(hp, HP_MAX)
	if cb != null:
		cb.damage_number_color(global_position + Vector3.UP * 2.8, dmg, Color(1.0, 0.55, 0.8), " !")
		cb.puff(global_position + Vector3.UP * 1.4 + (from_pos - global_position).normalized() * 0.6, Color(0.6, 0.2, 0.4))
	if hp <= 0:
		_die()
		return
	if phase == 1 and hp <= 160:
		phase = 2
		arena.say("La Reine hurle : « Mes enfants, à moi ! » Des araignées de cristal surgissent des ronces !", 5.0)
		if arena.main.monstres_v36 != null:
			for k in range(2):
				var at: Vector3 = center + Vector3(cos(k * PI) * 7.0, 0.05, sin(k * PI) * 3.0)
				var m: Node3D = arena.main.monstres_v36.spawn_extra("araignee", at)
				m.home = at
	if phase < 3 and hp <= 80:
		phase = 3
		_shield.visible = true
		arena.say("Un bouclier d'épines entoure la Reine ! Tes coups n'y font plus rien… Réveille les trois roses de lumière (E) !", 7.0)
		arena.activate_roses(true)
		_take_off()


func _die() -> void:
	state = "mort"
	timer = 0.0
	_shield.visible = false
	for c in _circles:
		(c["node"] as Node3D).queue_free()
		(c["spikes"] as Node3D).queue_free()
	_circles.clear()
	for dd in _darts:
		(dd["node"] as Node3D).queue_free()
	_darts.clear()
	_from = global_position
	defeated.emit()


## Les trois roses de lumière ont brisé le bouclier.
func stun() -> void:
	if state == "mort":
		return
	_shield.visible = false
	_from = global_position
	var p: Vector3 = _player()
	_to = _clamp_floor(center + ((p - center) * Vector3(1, 0, 1)).limit_length(3.0))
	state = "foudroyee_chute"
	timer = 1.0
	arena.say("Les roses de lumière brûlent la Reine ! Son bouclier vole en éclats, elle tombe : FRAPPE !", 4.0)


## Disparition des ronces (avant qu'Églantine n'apparaisse).
func purify() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 3.0).set_trans(Tween.TRANS_SINE)
	if arena.main.combat_v28 != null:
		for k in range(5):
			arena.main.combat_v28.puff(global_position + Vector3(randf_range(-1, 1), 0.5 + k * 0.4, randf_range(-1, 1)), Color(1.0, 0.7, 0.85))


# =================================================================== comportement

func _player() -> Vector3:
	return arena.main._player_pos_v27()


func _hurt(amount: int, from: Vector3) -> void:
	arena.main.monstres_v36.hurt_player(amount, from)


func _clamp_floor(p: Vector3) -> Vector3:
	var off := Vector3(p.x - center.x, 0, p.z - center.z).limit_length(8.5)
	return Vector3(center.x + off.x, center.y, center.z + off.z)


func _take_off() -> void:
	_from = global_position
	_angle = atan2(global_position.z - center.z, global_position.x - center.x)
	_to = center + Vector3(cos(_angle) * ORBIT, HOVER, sin(_angle) * ORBIT)
	state = "envol"
	timer = 1.2


func _physics_process(delta: float) -> void:
	if arena == null:
		return
	_clock += delta
	_update_fx(delta)
	if state == "mort":
		timer += delta
		global_position = global_position.lerp(Vector3(global_position.x, center.y + 0.3, global_position.z), clampf(delta * 1.5, 0.0, 1.0))
		_animate(delta, 0.3)
		return
	if not arena.fight or not bool(arena.main.monstres_v36.active):
		_animate(delta, 1.0)
		return
	var p: Vector3 = _player()
	timer -= delta
	var speed: float = 1.0 if phase == 1 else 1.35
	match state:
		"eveil":
			var k: float = clampf(1.0 - timer / 3.0, 0.0, 1.0)
			global_position = _from.lerp(_to, smoothstep(0.0, 1.0, k))
			if timer <= 0.0:
				_angle = atan2(global_position.z - center.z, global_position.x - center.x)
				state = "vol"
				timer = 2.0
		"vol":
			_angle += delta * 0.45 * speed
			var goal: Vector3 = center + Vector3(cos(_angle) * ORBIT, HOVER + sin(_clock * 1.7) * 0.3, sin(_angle) * ORBIT)
			global_position = global_position.lerp(goal, clampf(delta * 2.0, 0.0, 1.0))
			if timer <= 0.0:
				_choose(p)
		"ronces":
			_queue_clock -= delta
			if not _queue.is_empty() and _queue_clock <= 0.0:
				_queue.pop_front()
				_place_circle(p)
				_queue_clock = 0.55 / speed
			if _queue.is_empty() and timer <= 0.0:
				state = "vol"
				timer = 1.6 / speed
		"epines_prep":
			if timer <= 0.0:
				_fire_darts(p)
				state = "vol"
				timer = 1.6 / speed
		"descente":
			var k2: float = clampf(1.0 - timer / 1.3, 0.0, 1.0)
			global_position = _from.lerp(_to, smoothstep(0.0, 1.0, k2))
			if timer <= 0.0:
				state = "fatigue"
				timer = 4.5
				if phase < 3:
					arena.say("La Reine se pose, épuisée : FRAPPE !", 2.5)
				else:
					arena.say("Elle se pose… mais le bouclier d'épines la protège. Les roses de lumière !", 3.0)
		"fatigue":
			if timer <= 0.0:
				_take_off()
		"foudroyee_chute":
			var k3: float = clampf(1.0 - timer / 1.0, 0.0, 1.0)
			global_position = _from.lerp(_to, k3 * k3)
			if timer <= 0.0:
				state = "foudroyee"
				timer = 6.0
		"foudroyee":
			if timer <= 0.0:
				_shield.visible = true
				arena.activate_roses(true)
				arena.say("La Reine se relève, et son bouclier d'épines repousse ! Les roses de lumière se referment…", 4.0)
				_take_off()
		"envol":
			var k4: float = clampf(1.0 - timer / 1.2, 0.0, 1.0)
			global_position = _from.lerp(_to, smoothstep(0.0, 1.0, k4))
			if timer <= 0.0:
				state = "vol"
				timer = 1.5
	# Regard vers le joueur
	var to_p: Vector3 = (p - global_position) * Vector3(1, 0, 1)
	if to_p.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to_p.x, to_p.z), clampf(delta * 4.0, 0.0, 1.0))
	_animate(delta, 1.0 if state != "fatigue" and state != "foudroyee" else 0.25)


func _choose(p: Vector3) -> void:
	if _attacks >= 3:
		_attacks = 0
		_from = global_position
		_to = _clamp_floor(center + ((p - center) * Vector3(1, 0, 1)).limit_length(4.0))
		state = "descente"
		timer = 1.3
		return
	_attacks += 1
	if randf() < 0.5:
		state = "ronces"
		_queue = [1, 2, 3] if phase == 1 else [1, 2, 3, 4]
		_queue_clock = 0.0
		timer = 2.6
	else:
		state = "epines_prep"
		timer = 0.9 if phase == 1 else 0.7


## Un cercle rouge sous le joueur ; une seconde après, les épines jaillissent.
func _place_circle(p: Vector3) -> void:
	var pos: Vector3 = _clamp_floor(p)
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.4
	cm.bottom_radius = 1.4
	cm.height = 0.02
	cm.radial_segments = 28
	ring.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.1, 0.2, 0.35)
	ring.material_override = m
	arena.s.add_child(ring)
	ring.global_position = pos + Vector3.UP * 0.06
	var spikes := Node3D.new()
	arena.s.add_child(spikes)
	spikes.global_position = pos
	spikes.visible = false
	var tm: Material = arena._thorn_mat
	for k in range(9):
		var a: float = k * 0.7
		var r: float = 0.25 + 0.12 * (k % 4)
		var sp := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.12
		c.height = 1.6 + 0.3 * (k % 3)
		c.radial_segments = 5
		sp.mesh = c
		sp.material_override = tm
		sp.position = Vector3(cos(a) * r, c.height * 0.5, sin(a) * r)
		sp.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
		spikes.add_child(sp)
	_circles.append({"node": ring, "spikes": spikes, "pos": pos, "t": 1.1, "done": false, "mat": m})


func _fire_darts(p: Vector3) -> void:
	var from: Vector3 = global_position + Vector3.UP * 1.8
	var aim: Vector3 = (p + Vector3.UP * 1.0) - from
	var n: int = 5 if phase == 1 else 7
	for k in range(n):
		var off: float = (k - (n - 1) * 0.5) * 0.16
		var dir: Vector3 = aim.normalized().rotated(Vector3.UP, off)
		var dart := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.06
		c.height = 0.5
		c.radial_segments = 5
		dart.mesh = c
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.3, 0.05, 0.15)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.2, 0.5)
		m.emission_energy_multiplier = 2.0
		dart.material_override = m
		arena.s.add_child(dart)
		dart.global_position = from
		dart.look_at(from + dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
		dart.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		_darts.append({"node": dart, "vel": dir * 11.0, "life": 2.5, "hit": false})


func _update_fx(delta: float) -> void:
	var p: Vector3 = _player()
	for c in _circles.duplicate():
		c["t"] = float(c["t"]) - delta
		var m: StandardMaterial3D = c["mat"]
		if not bool(c["done"]):
			m.albedo_color.a = 0.35 + 0.3 * (1.0 - clampf(float(c["t"]) / 1.1, 0.0, 1.0))
			if float(c["t"]) <= 0.0:
				c["done"] = true
				var sp: Node3D = c["spikes"]
				sp.visible = true
				sp.scale = Vector3(1, 0.05, 1)
				create_tween().tween_property(sp, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
				var cp: Vector3 = c["pos"]
				if Vector2(p.x - cp.x, p.z - cp.z).length() < 1.45 and absf(p.y - cp.y) < 1.6:
					_hurt(2, cp)
				if arena.main.combat_v28 != null:
					arena.main.combat_v28.puff(cp + Vector3.UP * 0.5, Color(0.35, 0.1, 0.2))
		elif float(c["t"]) < -0.9:
			(c["node"] as Node3D).queue_free()
			(c["spikes"] as Node3D).queue_free()
			_circles.erase(c)
	for dd in _darts.duplicate():
		var node: Node3D = dd["node"]
		node.global_position += (dd["vel"] as Vector3) * delta
		dd["life"] = float(dd["life"]) - delta
		if not bool(dd["hit"]) and node.global_position.distance_to(p + Vector3.UP * 1.0) < 0.7:
			dd["hit"] = true
			_hurt(1, node.global_position)
			dd["life"] = 0.0
		if float(dd["life"]) <= 0.0 or node.global_position.y < center.y - 0.2:
			node.queue_free()
			_darts.erase(dd)


func _animate(delta: float, flap_k: float) -> void:
	for w in _wings:
		var hinge: Node3D = w
		var sx: float = float(hinge.get_meta("cote", 1.0))
		hinge.rotation.y = sx * (0.35 + sin(_clock * 7.0 * flap_k + 0.3) * 0.5 * flap_k)
	if _look != null:
		_look.position.y = sin(_clock * 1.9) * 0.08 if state in ["vol", "eveil", "envol"] else 0.0
	var glow: float = 4.0
	if state == "epines_prep":
		glow = 4.0 + 6.0 * (1.0 - clampf(timer / 0.9, 0.0, 1.0))
	elif state in ["fatigue", "foudroyee"]:
		glow = 1.0
	if _eye_mat != null:
		_eye_mat.emission_energy_multiplier = glow
	if _shield.visible:
		_shield_mat.albedo_color.a = 0.25 + sin(_clock * 4.0) * 0.06
		_shield.rotation.y += delta * 0.8
	var on: bool = _flash > 0.0
	_flash = maxf(_flash - delta, 0.0)
	for mm in _mats:
		var sm: StandardMaterial3D = mm
		if on:
			if not sm.has_meta("e0"):
				sm.set_meta("e0", [sm.emission, sm.emission_energy_multiplier])
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 1.5
		elif sm.has_meta("e0"):
			var e: Array = sm.get_meta("e0")
			sm.emission = e[0]
			sm.emission_energy_multiplier = e[1]
			sm.remove_meta("e0")

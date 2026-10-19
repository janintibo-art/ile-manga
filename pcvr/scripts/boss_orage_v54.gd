extends CharacterBody3D
## V54 : Sire Orage, le Chevalier des Tempêtes — gardien de la Citadelle des Nuées, au sommet
## de la Tour des Tempêtes. Une armure de géant (3,3 m) que la foudre habite.
## Son armure encaisse (un coup ne lui retire que la moitié des dégâts). Il faut le punir quand
## il est vulnérable :
##  - TAILLE : il lève sa grande épée (1 s) puis balaie devant lui -> reculer, rouler ou parer ;
##  - ÉPÉE PLANTÉE : au troisième coup de taille, la lame se plante dans les dalles : il reste
##    coincé 3 s et prend double dégâts ;
##  - FOUDRE : il brandit l'épée vers le ciel ; trois cercles bleus suivent le joueur, la
##    foudre tombe sur chacun -> ne pas rester dans un cercle ;
##  - à mi-vie, la TEMPÊTE : il charge en bourrasque (il recule et s'éclaire avant), la foudre
##    tombe plus vite, et deux gargouilles viennent l'aider.

signal defeated
signal health_changed(hp: int, hp_max: int)

const HP_MAX: int = 240
const HeroLib = preload("res://scripts/hero_v28.gd")

var arena: Node                       # ciel_v54.gd (messages, joueur, invocations)
var center: Vector3
var radius: float = 8.6
var hp: int = HP_MAX
var phase: int = 1
var state: String = "eveil"
var timer: float = 2.4
var facing: Vector3 = Vector3.BACK
var hit_radius: float = 0.9
var hit_height: float = 1.6
var _visual: Node3D
var _anim: AnimationPlayer
var _sword: Node3D
var _eyes: Array = []
var _mats: Array = []
var _flash: float = 0.0
var _clock: float = 0.0
var _attacks: int = 0
var _strikes: Array = []              # {pos, t, ring, mat, done}
var _bolts: Array = []                # {node, t}
var _charge_dir: Vector3
var _summon_clock: float = 6.0
var _sky_light: OmniLight3D
var _aura: CPUParticles3D


func setup(owner_node: Node, at: Vector3, face: Vector3) -> void:
	arena = owner_node
	center = at
	facing = face.normalized()
	name = "Sire_Orage_v54"
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.75
	cap.height = 3.2
	cs.shape = cap
	cs.position.y = 1.6
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	_build()
	add_to_group("cibles_v28")
	global_position = at + facing * 5.0 + Vector3.UP * 6.0
	rotation.y = atan2(facing.x, facing.z)
	_sky_light = OmniLight3D.new()
	_sky_light.light_color = Color(0.6, 0.8, 1.0)
	_sky_light.light_energy = 0.0
	_sky_light.omni_range = 26.0
	_sky_light.top_level = true
	add_child(_sky_light)
	_sky_light.global_position = center + Vector3.UP * 12.0


func _mat(c: Color, rough: float = 0.4, emit: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
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


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


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


func _build() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.9
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
	# Acier bleui par la foudre, rehauts d'or
	var steel := _mat(Color(0.42, 0.46, 0.55), 0.28, 0.0, 0.9)
	steel.albedo_texture = load("res://assets/textures/terrain/rock.jpg")
	steel.uv1_scale = Vector3(5, 5, 5)
	_mats.append(steel)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, steel)
	var gold := _mat(Color(0.9, 0.72, 0.32), 0.3, 0.0, 0.95)
	var glow := _mat(Color(0.55, 0.85, 1.0), 0.1, 5.0)
	var cloth := _mat(Color(0.1, 0.16, 0.42), 0.9)
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark := _mat(Color(0.03, 0.03, 0.04), 0.6)
	if skel == null:
		return
	# Le heaume à couronne et ses yeux de foudre
	var helm := Node3D.new()
	_mesh(helm, _sphere(0.18), steel, Vector3(0, 0.02, 0), Vector3(1.0, 1.2, 1.1))
	_mesh(helm, _box(Vector3(0.24, 0.035, 0.05)), dark, Vector3(0, 0.03, 0.18))
	for sx in [-0.055, 0.055]:
		_eyes.append(_mesh(helm, _sphere(0.022), glow, Vector3(sx, 0.03, 0.175)))
	for k in range(5):
		var a: float = -0.9 + k * 0.45
		_mesh(helm, _box(Vector3(0.03, 0.12, 0.03)), gold, Vector3(sin(a) * 0.16, 0.22, cos(a) * 0.16), Vector3.ONE, Vector3(0, a, 0))
	_attach(skel, "Head", Vector3(0, 12, 2), helm)
	# Épaulières à pointes, cape bleu nuit
	for side in [["LeftShoulder", -1.0], ["RightShoulder", 1.0]]:
		var pad := Node3D.new()
		_mesh(pad, _sphere(0.13), steel, Vector3.ZERO, Vector3(1.4, 0.75, 1.3))
		_mesh(pad, _box(Vector3(0.05, 0.05, 0.05)), gold, Vector3(0, 0.1, 0))
		_attach(skel, str(side[0]), Vector3(float(side[1]) * 10.0, 6, 0), pad)
	var cape := Node3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(0.62, 1.15)
	_mesh(cape, cq, cloth, Vector3(0, -0.5, -0.14), Vector3.ONE, Vector3(0.12, 0, 0))
	_attach(skel, "Spine2", Vector3(0, 10, -8), cape)
	# La grande épée, lame veinée de bleu
	_sword = Node3D.new()
	_mesh(_sword, _box(Vector3(0.1, 1.5, 0.025)), steel, Vector3(0, 0.95, 0))
	_mesh(_sword, _box(Vector3(0.025, 1.4, 0.03)), glow, Vector3(0, 0.95, 0))
	_mesh(_sword, _box(Vector3(0.46, 0.06, 0.07)), gold, Vector3(0, 0.17, 0))
	_mesh(_sword, _box(Vector3(0.05, 0.28, 0.05)), cloth, Vector3(0, 0.0, 0))
	_mesh(_sword, _sphere(0.045), gold, Vector3(0, -0.15, 0))
	var att := BoneAttachment3D.new()
	att.bone_name = "RightHand"
	skel.add_child(att)
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	hold.rotation_degrees = Vector3(90, 0, 0)
	hold.scale = Vector3.ONE * 100.0
	att.add_child(hold)
	hold.add_child(_sword)
	# L'aura de foudre : étincelles bleues autour de lui
	_aura = CPUParticles3D.new()
	_aura.amount = 26
	_aura.lifetime = 0.5
	_aura.local_coords = false
	_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_aura.emission_box_extents = Vector3(0.7, 1.6, 0.5)
	_aura.position = Vector3(0, 1.7, 0)
	_aura.gravity = Vector3.ZERO
	_aura.initial_velocity_min = 0.5
	_aura.initial_velocity_max = 1.6
	_aura.spread = 180.0
	var pq := QuadMesh.new()
	pq.size = Vector2(0.06, 0.18)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.albedo_color = Color(0.6, 0.85, 1.0)
	pq.material = pm
	_aura.mesh = pq
	_visual.add_child(_aura)
	_play("v28/idle")


func _play(anim_name: String, blend: float = 0.2, speed: float = 1.0) -> void:
	if _anim != null and _anim.has_animation(anim_name) and (_anim.current_animation != anim_name or not _anim.is_playing()):
		_anim.play(anim_name, blend, speed)


# =================================================================== règle des cibles

func is_hittable() -> bool:
	return state != "mort" and state != "eveil"


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not is_hittable():
		return
	var cb: Node = arena.main.combat_v28
	var weak: bool = state == "plantee"
	var dmg: int = damage * 2 if weak else maxi(1, int(round(damage * 0.5)))
	hp = maxi(hp - dmg, 0)
	_flash = 0.15
	health_changed.emit(hp, HP_MAX)
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * 3.6
		if weak:
			cb.damage_number_color(at, dmg, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number_color(at, dmg, Color(0.7, 0.8, 0.95), "")
			if randf() < 0.3:
				cb.float_text(at + Vector3.UP * 0.5, "L'armure encaisse !", Color(0.8, 0.88, 1.0))
		cb.puff(global_position + Vector3.UP * 1.8 + (from_pos - global_position).normalized() * 0.8, Color(0.7, 0.8, 1.0))
	if hp <= 0:
		_die()
		return
	if phase == 1 and hp <= HP_MAX / 2:
		phase = 2
		_summon_clock = 2.0
		arena._say("Sire Orage lève son épée vers le ciel : LA TEMPÊTE SE DÉCHAÎNE ! Il va charger en bourrasque : quand il recule en s'illuminant, écarte-toi de sa trajectoire.", 6.0)


func _die() -> void:
	state = "mort"
	timer = 0.0
	collision_layer = 0
	_play("Knock_Down", 0.1)
	for s in _strikes:
		(s["ring"] as Node).queue_free()
	_strikes.clear()
	defeated.emit()


# =================================================================== comportement

func _player() -> Vector3:
	return arena.main._player_pos_v27()


func _hurt_player(amount: int) -> void:
	arena.main.monstres_v36.hurt_player(amount, global_position)


func _start(s: String, t: float) -> void:
	state = s
	timer = t


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_apply_flash()
	_update_bolts(delta)
	if state == "mort":
		timer += delta
		if _aura != null:
			_aura.emitting = timer < 1.5
		for e in _eyes:
			(e as MeshInstance3D).visible = timer < 1.2 or fmod(timer, 0.25) < 0.12
		if timer > 2.5:
			_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 2.5) / 1.5, 0.01, 1.0)
		if timer > 4.2:
			visible = false
			set_physics_process(false)
		return
	if not arena.main.monstres_v36.active and state != "eveil":
		return
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	var speed: float = 1.5 if phase == 1 else 2.2
	timer -= delta
	_update_strikes(delta, p)
	match state:
		"eveil":
			# Il descend du ciel dans un éclair et se pose sur la plate-forme
			var k: float = clampf(1.0 - timer / 2.4, 0.0, 1.0)
			global_position = (center + facing * 5.0) + Vector3.UP * 6.0 * (1.0 - smoothstep(0.0, 1.0, k))
			if timer <= 0.0:
				global_position = center + facing * 5.0
				_bolt(global_position, 0.0)
				_start("approche", 0.6)
		"approche":
			facing = facing.slerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
			_play("Walking", 0.25, 0.7)
			if timer > 0.0:
				pass
			elif phase == 2 and _attacks % 4 == 3:
				_start("recule", 1.0)
			elif dist > 6.0 or (_attacks % 3 == 1 and randf() < 0.6):
				_start("armer_foudre", 1.1)
				_play("v28/slash1", 0.15, 0.4)
				arena.main.sfx("boss_cri", global_position + Vector3.UP * 3.0)
			elif dist < 3.6:
				_start("armer_taille", 1.0 if phase == 1 else 0.75)
				_play("v28/slash3", 0.1, 0.5)
			else:
				move = dir_p * speed
		"armer_taille":
			facing = facing.slerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				_start("taille", 0.35)
				arena.main.sfx("fendre_lourd", global_position + Vector3.UP * 2.0)
				if dist < 3.9 and facing.dot(dir_p) > 0.2:
					_hurt_player(2)
				arena.main.combat_v28.puff(global_position + facing * 2.6 + Vector3.UP * 0.4, Color(0.75, 0.8, 0.9))
		"taille":
			if timer <= 0.0:
				_attacks += 1
				if _attacks % 3 == 0:
					_start("plantee", 3.0)
					_bolt(global_position + facing * 2.4, 0.0)
					arena._say("Sa lame s'est plantée dans les dalles ! Frappe maintenant !", 2.5)
				else:
					_start("recup", 0.9 if phase == 1 else 0.6)
		"plantee":
			_play("v28/idle", 0.2, 0.3)
			if timer <= 0.0:
				_start("recup", 0.6)
		"armer_foudre":
			facing = facing.slerp(dir_p, clampf(delta * 2.0, 0.0, 1.0)).normalized()
			_sky_light.light_energy = 1.5 + sin(_clock * 40.0) * 0.8
			if timer <= 0.0:
				_sky_light.light_energy = 0.0
				var n: int = 3 if phase == 1 else 4
				for k in range(n):
					_strikes.append({"t": -0.45 * k, "delay": 1.15 if phase == 1 else 0.85, "pos": Vector3(p.x, center.y, p.z), "ring": _make_ring(), "done": false})
				_attacks += 1
				_start("foudre", 0.9 * n)
		"foudre":
			if timer <= 0.0:
				_start("recup", 0.8)
		"recule":
			move = -dir_p * 3.0
			facing = facing.slerp(dir_p, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			_sky_light.light_energy = 2.0
			if timer <= 0.0:
				_charge_dir = facing
				_start("bourrasque", 1.6)
				arena.main.sfx("fendre_lourd", global_position + Vector3.UP * 2.0)
		"bourrasque":
			move = _charge_dir * 10.0
			if dist < 2.2 and not has_meta("touche"):
				set_meta("touche", true)
				_hurt_player(2)
			var out: bool = Vector2(global_position.x - center.x, global_position.z - center.z).length() > radius - 1.4
			if out or timer <= 0.0:
				remove_meta("touche")
				_sky_light.light_energy = 0.0
				_attacks += 1
				_start("plantee", 2.2)
				arena._say("Il s'est arrêté net au bord de la plate-forme ! Frappe !", 2.5)
		"recup":
			_play("v28/idle", 0.3)
			if timer <= 0.0:
				_start("approche", 0.4)
	# Phase 2 : des gargouilles viennent l'aider
	if phase == 2:
		_summon_clock -= delta
		if _summon_clock <= 0.0:
			_summon_clock = 20.0
			arena.summon_gargoyles(2)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if state == "eveil" else (0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0))
	if state != "eveil":
		move_and_slide()
	var flat := Vector2(global_position.x - center.x, global_position.z - center.z)
	if flat.length() > radius - 1.0:
		flat = flat.normalized() * (radius - 1.0)
		global_position.x = center.x + flat.x
		global_position.z = center.z + flat.y
	rotation.y = atan2(facing.x, facing.z)


func _make_ring() -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 1.75
	rm.outer_radius = 2.0
	rm.rings = 32
	rm.ring_segments = 4
	ring.mesh = rm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.45, 0.75, 1.0, 0.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = m
	ring.scale = Vector3(1, 0.05, 1)
	ring.top_level = true
	ring.visible = false
	add_child(ring)
	return ring


func _update_strikes(delta: float, p: Vector3) -> void:
	for s in _strikes:
		if bool(s["done"]):
			continue
		s["t"] = float(s["t"]) + delta
		var t: float = float(s["t"])
		var ring: MeshInstance3D = s["ring"]
		if t < 0.0:
			continue
		var d: float = float(s["delay"])
		# Le cercle suit le joueur, puis se fige juste avant la foudre
		if t < d * 0.6:
			s["pos"] = (s["pos"] as Vector3).lerp(Vector3(p.x, center.y, p.z), clampf(delta * 4.0, 0.0, 1.0))
		ring.visible = true
		ring.global_position = (s["pos"] as Vector3) + Vector3.UP * 0.08
		(ring.material_override as StandardMaterial3D).albedo_color.a = 0.25 + 0.7 * clampf(t / d, 0.0, 1.0)
		if t >= d:
			s["done"] = true
			ring.visible = false
			var at: Vector3 = s["pos"]
			_bolt(at, 0.0)
			if Vector2(p.x - at.x, p.z - at.z).length() < 2.0 and absf(p.y - at.y) < 2.6:
				_hurt_player(2)
	var keep: Array = []
	for s2 in _strikes:
		if bool(s2["done"]):
			(s2["ring"] as Node).queue_free()
		else:
			keep.append(s2)
	_strikes = keep


## Un éclair qui tombe du ciel en « at » : un trait lumineux en zigzag, un flash, le tonnerre.
func _bolt(at: Vector3, _delay: float) -> void:
	var root := Node3D.new()
	root.top_level = true
	add_child(root)
	root.global_position = at
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.93, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.6, 0.85, 1.0)
	m.emission_energy_multiplier = 6.0
	var p := Vector3(randf_range(-1.5, 1.5), 34.0, randf_range(-1.5, 1.5))
	var segs: int = 9
	for k in range(segs):
		var q: Vector3 = p.lerp(Vector3.ZERO, 1.0 / float(segs - k)) + (Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2)) if k < segs - 1 else Vector3.ZERO)
		var mid: Vector3 = (p + q) * 0.5
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.09
		cm.height = p.distance_to(q)
		cm.radial_segments = 5
		seg.mesh = cm
		seg.material_override = m
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(seg)
		seg.position = mid
		var up: Vector3 = (p - q).normalized()
		var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		seg.basis = Basis(side, up, side.cross(up).normalized())
		p = q
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.7, 0.85, 1.0)
	flash.light_energy = 8.0
	flash.omni_range = 18.0
	flash.position = Vector3.UP * 2.0
	root.add_child(flash)
	_bolts.append({"node": root, "t": 0.0, "light": flash})
	arena.main.sfx("tonnerre", at + Vector3.UP * 4.0)
	if arena.main.combat_v28 != null:
		for k in range(3):
			arena.main.combat_v28.puff(at + Vector3(randf_range(-0.8, 0.8), 0.2, randf_range(-0.8, 0.8)), Color(0.75, 0.85, 1.0))


func _update_bolts(delta: float) -> void:
	var keep: Array = []
	for b in _bolts:
		b["t"] = float(b["t"]) + delta
		var t: float = float(b["t"])
		(b["light"] as OmniLight3D).light_energy = maxf(8.0 - t * 30.0, 0.0)
		(b["node"] as Node3D).visible = t < 0.18 or (t > 0.24 and t < 0.3)
		if t > 0.4:
			(b["node"] as Node).queue_free()
		else:
			keep.append(b)
	_bolts = keep


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

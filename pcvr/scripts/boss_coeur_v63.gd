extends "res://scripts/monstre_v63.gd"
## V63 : le Gardien du Cœur, au fond du Cœur-de-Pierre. Un colosse de roche haut comme trois
## hommes, veiné de feu, qui porte les quatre runes des peuples :
##  - la rune des Embruns (épaule gauche, bleu-vert) se brise sous la Bourrasque ;
##  - la rune des Sables (épaule droite, orange) sous la Flamme ;
##  - la rune d'Airain (dans le dos, or) sous le Rouage ;
##  - la rune des Brumes (sur le front) est invisible : la Lueur de lune la montre, et un coup
##    d'arme la brise.
## Tant que des runes tiennent, l'acier rebondit sur lui. Quand les quatre sont tombées, il
## s'agenouille, sa poitrine s'ouvre : le cœur de feu est à nu. Il se relève, plus rapide ;
## à chaque quart de vie perdu, il s'agenouille encore et appelle des créatures des ailes.
## Ses coups : l'écrasement (il lève les deux poings), l'onde de choc (il frappe le sol : une
## onde court au ras du sol, on la saute ou on roule), la pluie de pierres (de loin).

signal phase_changed(p: int)

const PV_COEUR: int = 120
const RUNES := ["embruns", "sables", "airain", "brumes"]
const RUNE_POWER := {"embruns": "vent", "sables": "flamme", "airain": "rouage", "brumes": "lune"}
const RUNE_COL := {"embruns": Color(0.35, 0.95, 0.9), "sables": Color(1.0, 0.55, 0.15), "airain": Color(1.0, 0.8, 0.3), "brumes": Color(0.75, 0.85, 1.0)}

var phase: int = 1
var runes: Dictionary = {}               # nom -> {node, mat, broken}
var core: Node3D
var core_mat: StandardMaterial3D
var plate: Node3D
var _fists: Array = []
var _torso: Node3D
var _head: Node3D
var _kneel_t: float = 0.0
var _attack: String = ""
var _wave: Node3D
var _wave_r: float = -1.0
var _rocks: Array = []
var _rock_cd: float = 4.0
var _stomp_cd: float = 8.0
var _summon_marks: Array = [0.75, 0.5, 0.25]
var _minion_i: int = 0
var _veins: StandardMaterial3D
var _arena_c: Vector3 = Vector3.INF


func setup(m: Node, k: String, at: Vector3) -> void:
	manager = m
	kind = "gardien_coeur"
	spec = {"pv": 999, "vitesse": 1.3, "degats": 2, "portee": 4.2, "armer": 1.25, "repos": 1.6, "vue": 40.0, "laisse": 60.0,
		"rayon": 2.0, "haut": 2.3, "nom": "le Gardien du Cœur", "boss": true}
	home = at
	_arena_c = at
	hp = 999
	hit_radius = 2.0
	hit_height = 2.3
	name = "Gardien_du_coeur_v63"
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6
	cap.height = 6.6
	cs.shape = cap
	cs.position.y = 3.3
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	_build()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(0, 0, 1)
	state = "veille"


func is_boss() -> bool:
	return true


func runes_left() -> int:
	var n: int = 0
	for r in runes:
		if not bool(runes[r]["broken"]):
			n += 1
	return n


# =================================================================== le modèle

func _build() -> void:
	var Rk = load("res://scripts/rocks_v26.gd")
	var rock := _mat(Color(0.5, 0.47, 0.45), 0.95)
	rock.albedo_texture = load("res://assets/textures/coeur/pierre.png") if ResourceLoader.exists("res://assets/textures/coeur/pierre.png") else load("res://assets/textures/terrain/rock.jpg")
	rock.uv1_triplanar = true
	rock.uv1_scale = Vector3(0.6, 0.6, 0.6)
	var dark := _mat(Color(0.22, 0.2, 0.19), 0.95)
	dark.albedo_texture = rock.albedo_texture
	dark.uv1_triplanar = true
	dark.uv1_scale = Vector3(0.6, 0.6, 0.6)
	_veins = _mat(Color(1.0, 0.35, 0.08), 0.4, 3.0)
	_torso = Node3D.new()
	_visual.add_child(_torso)
	# jambes
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx * 0.9, 2.2, 0)
		_visual.add_child(leg)
		_mesh(leg, Rk.shape(6301 + int(sx), Vector3(1.0, 2.2, 1.1), 0.75, 0.15), rock, Vector3(0, -1.1, 0))
		_mesh(leg, Rk.shape(6303 + int(sx), Vector3(1.3, 0.6, 1.6), 0.8, 0.12), dark, Vector3(0, -2.0, 0.2))
		_legs.append([leg, sx, 0])
	# bassin, torse, épaules
	_mesh(_torso, Rk.shape(6310, Vector3(2.4, 1.2, 1.6), 0.7, 0.15), rock, Vector3(0, 2.6, 0))
	_mesh(_torso, Rk.shape(6311, Vector3(3.4, 2.4, 2.2), 0.7, 0.18), rock, Vector3(0, 4.2, -0.1))
	_mesh(_torso, Rk.shape(6312, Vector3(1.4, 1.2, 1.3), 0.75, 0.15), dark, Vector3(0, 5.6, 0.1))
	for k in range(9):
		_mesh(_torso, _box_mesh_g(Vector3(0.08, 0.6 + (k % 3) * 0.25, 0.06)), _veins, Vector3(-1.2 + (k % 5) * 0.6, 3.3 + (k % 4) * 0.5, 1.02 if k % 2 == 0 else -1.15), Vector3.ONE, Vector3(0, 0, 0.4 * ((k % 3) - 1)))
	# la tête, son front (la rune des Brumes), ses yeux
	_head = Node3D.new()
	_head.position = Vector3(0, 6.1, 0.3)
	_torso.add_child(_head)
	_mesh(_head, Rk.shape(6313, Vector3(1.2, 1.0, 1.1), 0.75, 0.12), rock, Vector3.ZERO)
	_eyes_mat = _mat(Color(1.0, 0.45, 0.15), 0.2, 5.0)
	for sx2 in [-1.0, 1.0]:
		_mesh(_head, _sphere(0.11), _eyes_mat, Vector3(sx2 * 0.26, 0.05, 0.5), Vector3(1.4, 0.6, 0.5))
	# la plaque de poitrine qui cache le cœur
	core = Node3D.new()
	core.position = Vector3(0, 4.3, 1.0)
	_torso.add_child(core)
	core_mat = _mat(Color(1.0, 0.3, 0.08), 0.2, 4.0)
	var gem := SphereMesh.new()
	gem.radius = 0.55
	gem.height = 1.1
	gem.radial_segments = 8
	gem.rings = 5
	_mesh(core, gem, core_mat, Vector3.ZERO)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.35, 0.12)
	cl.light_energy = 2.0
	cl.omni_range = 8.0
	core.add_child(cl)
	plate = Node3D.new()
	plate.position = Vector3(0, 4.3, 1.15)
	_torso.add_child(plate)
	_mesh(plate, Rk.shape(6314, Vector3(1.5, 1.4, 0.5), 0.8, 0.1), dark, Vector3.ZERO)
	# les bras et les poings
	for sx3 in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(sx3 * 2.1, 5.1, 0)
		_torso.add_child(arm)
		_mesh(arm, Rk.shape(6320 + int(sx3), Vector3(0.9, 2.2, 0.9), 0.75, 0.15), rock, Vector3(sx3 * 0.1, -1.2, 0))
		_mesh(arm, Rk.shape(6322 + int(sx3), Vector3(1.3, 1.1, 1.3), 0.75, 0.18), dark, Vector3(sx3 * 0.15, -2.7, 0.15))
		_arms.append([arm, sx3])
		_fists.append(arm)
	# les quatre runes
	var where := {"embruns": [_torso, Vector3(-2.1, 5.7, 0.2)], "sables": [_torso, Vector3(2.1, 5.7, 0.2)], "airain": [_torso, Vector3(0, 4.6, -1.25)], "brumes": [_head, Vector3(0, 0.45, 0.45)]}
	for r in RUNES:
		var host: Node3D = where[r][0]
		var rn := Node3D.new()
		rn.position = where[r][1]
		host.add_child(rn)
		var rm := _mat(RUNE_COL[r], 0.25, 3.5)
		var rs := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.6, 0.7, 0.25)
		rs.mesh = pm
		rs.material_override = rm
		rn.add_child(rs)
		var l := OmniLight3D.new()
		l.light_color = RUNE_COL[r]
		l.light_energy = 1.0
		l.omni_range = 3.0
		rn.add_child(l)
		if r == "airain":
			rn.rotation.y = PI
		runes[r] = {"node": rn, "mat": rm, "broken": false, "light": l}
	(runes["brumes"]["node"] as Node3D).visible = false


# =================================================================== réactions

func on_power(p: String, from: Vector3) -> void:
	if state == "mort":
		return
	if phase == 1:
		for r in RUNES:
			if RUNE_POWER[r] == p and r != "brumes" and not bool(runes[r]["broken"]):
				_break_rune(r)
				return
		if p == "flamme" or p == "vent" or p == "rouage":
			_hint("La rune de ce pouvoir est déjà brisée… Il en reste %d." % runes_left())
	else:
		if p == "flamme":
			take_hit(4, from)


func set_moonlit(on: bool) -> void:
	moonlit = on
	if phase == 1 and not bool(runes["brumes"]["broken"]):
		(runes["brumes"]["node"] as Node3D).visible = on
		if on:
			_hint("La Lueur de lune révèle une quatrième rune, sur son front ! Frappe-la !")


func take_hit(damage: int, from_pos: Vector3) -> void:
	if state == "mort":
		return
	var cb: Node = manager.main.combat_v28
	if phase == 1:
		if moonlit and not bool(runes["brumes"]["broken"]):
			_break_rune("brumes")
			return
		if cb != null and _clock - _through_t > 1.2:
			_through_t = _clock
			cb.float_text(global_position + Vector3.UP * 5.0, "Clang !", Color(0.85, 0.85, 0.9))
		if manager.main.has_method("sfx"):
			manager.main.sfx("touche_pierre", global_position + Vector3.UP * 3.0)
		_hint("L'acier rebondit sur la roche ! Ses quatre runes le protègent : chacune craint le pouvoir de son sceau.")
		return
	# phase 2 : le cœur est à nu
	var mult: float = 2.0 if state == "agenouille" else 1.0
	damage = int(round(damage * mult))
	hp -= damage
	_flash = 0.18
	if cb != null:
		var at: Vector3 = core.global_position + Vector3.UP * 0.8
		if bool(cb.get("critical")) or mult > 1.0:
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(core.global_position, Color(1.0, 0.55, 0.2))
	if hp <= 0:
		_die63()
		return
	var frac: float = float(hp) / float(PV_COEUR)
	if not _summon_marks.is_empty() and frac <= float(_summon_marks[0]):
		_summon_marks.pop_front()
		_kneel(4.5)
		_summon(2)


func _break_rune(r: String) -> void:
	runes[r]["broken"] = true
	var rn: Node3D = runes[r]["node"]
	var at: Vector3 = rn.global_position
	if manager.main.has_method("sfx"):
		manager.main.sfx("rune_brisee", at)
	var cb: Node = manager.main.combat_v28
	if cb != null:
		for k in range(4):
			cb.puff(at + Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), randf_range(-0.4, 0.4)), RUNE_COL[r])
		cb.float_text(at + Vector3.UP * 1.2, "La rune se brise !", RUNE_COL[r])
	var tw := create_tween()
	tw.tween_property(rn, "scale", Vector3.ONE * 0.01, 0.5)
	tw.tween_callback(func(): rn.visible = false)
	stun(2.5)
	if runes_left() == 0:
		_phase2()
	else:
		_hint("Une rune de moins ! Il en reste %d." % runes_left())


func _phase2() -> void:
	phase = 2
	hp = PV_COEUR
	phase_changed.emit(2)
	_kneel(5.0)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(plate, "position", plate.position + Vector3(0, -2.5, 1.6), 0.8).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(plate, "rotation:x", 1.4, 0.8)
	tw.tween_callback(func(): plate.visible = false)
	if manager.main.has_method("sfx"):
		manager.main.sfx("boss_coeur_cri", global_position + Vector3.UP * 5.0)
	_hint("Les quatre runes sont brisées ! Le Gardien tombe à genoux… sa poitrine s'ouvre : le cœur de feu est à nu. Frappe-le !")
	spec["vitesse"] = 1.7
	spec["armer"] = 1.0


func _kneel(t: float) -> void:
	state = "agenouille"
	timer = t
	_kneel_t = t


func _summon(n: int) -> void:
	var kinds := ["ondin", "scorpion", "automate", "spectre"]
	for k in range(n):
		var a: float = randf() * TAU
		var at: Vector3 = _arena_c + Vector3(cos(a) * 9.0, 0.1, sin(a) * 9.0)
		var m: Node3D = manager.spawn_extra(str(kinds[_minion_i % kinds.size()]), at)
		m.home = at
		_minion_i += 1
	_hint("Le Gardien frappe le sol : des créatures des quatre ailes accourent !")


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	_tick_rocks(delta)
	_tick_wave(delta)
	if state == "mort":
		_death_tick(delta)
		return
	_animate_boss(delta)
	if not manager.active:
		return
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to_p: Vector3 = p - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	timer -= delta
	_rock_cd -= delta
	_stomp_cd -= delta
	match state:
		"veille":
			if dist < 30.0:
				state = "chasse"
				manager.alert(self)
		"etourdi", "agenouille":
			if timer <= 0.0:
				state = "chasse"
				if _stars != null:
					_stars.visible = false
		"chasse":
			facing = facing.lerp(dir_p, clampf(delta * 2.0, 0.0, 1.0)).normalized()
			if _stomp_cd <= 0.0 and dist < 12.0:
				_stomp_cd = 9.0 if phase == 1 else 7.0
				state = "armer"
				_attack = "onde"
				timer = 1.1
				_sound63("menace")
			elif dist <= float(spec["portee"]):
				state = "armer"
				_attack = "poings"
				timer = float(spec["armer"])
				_sound63("menace")
			elif dist > 11.0 and _rock_cd <= 0.0:
				_rock_cd = 4.5 if phase == 1 else 3.2
				_throw_rock(p)
			else:
				move = dir_p * float(spec["vitesse"])
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 1.5, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.35
				if _attack == "onde":
					_start_wave()
				else:
					var at: Vector3 = global_position + facing * 3.0
					if Vector2(p.x - at.x, p.z - at.z).length() < 3.0:
						manager.hurt_player(int(spec["degats"]), global_position)
					_shockwave(at)
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
	if _knock.length() > 0.05:
		move += _knock * 0.2
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	if global_position.distance_to(_arena_c) > 16.0:
		var back: Vector3 = (_arena_c - global_position) * Vector3(1, 0, 1)
		global_position += back.normalized() * (global_position.distance_to(_arena_c) - 16.0)
	rotation.y = atan2(facing.x, facing.z)


func _animate_boss(delta: float) -> void:
	var t: float = _clock
	var raise: float = 0.0
	if state == "armer":
		raise = 1.0 - clampf(timer / maxf(float(spec["armer"]), 0.01), 0.0, 1.0)
	var slam: bool = state == "frappe"
	for a in _arms:
		var arm: Node3D = a[0]
		var target: float = -2.4 * raise if not slam else 0.4
		arm.rotation.x = lerpf(arm.rotation.x, target, clampf(delta * (14.0 if slam else 4.0), 0.0, 1.0))
	var kneel: bool = state == "agenouille" or state == "etourdi"
	_torso.position.y = lerpf(_torso.position.y, -1.4 if kneel else 0.0, clampf(delta * 3.0, 0.0, 1.0))
	_torso.rotation.x = lerpf(_torso.rotation.x, 0.35 if kneel else sin(t * 0.8) * 0.03, clampf(delta * 3.0, 0.0, 1.0))
	for l in _legs:
		(l[0] as Node3D).rotation.x = sin(t * 2.2 + (0.0 if float(l[1]) > 0.0 else PI)) * (0.18 if state == "chasse" else 0.0)
	_veins.emission_energy_multiplier = 2.5 + sin(t * (2.0 if phase == 1 else 4.0)) * 1.2
	if core_mat != null:
		core_mat.emission_energy_multiplier = 3.0 + sin(t * 5.0) * 1.5
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


## L'onde de choc : un anneau qui grandit au ras du sol ; on la saute, on roule, ou on prend
## un coup.
func _start_wave() -> void:
	if manager.main.has_method("sfx"):
		manager.main.sfx("onde_choc", global_position, 4.0)
	if _wave == null:
		_wave = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.95
		tm.outer_radius = 1.0
		tm.rings = 64
		(_wave as MeshInstance3D).mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.5, 0.2, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		(_wave as MeshInstance3D).material_override = m
		manager.add_child(_wave)
	_wave.global_position = global_position + Vector3.UP * 0.25
	_wave.visible = true
	_wave_r = 1.5
	set_meta("onde_touche", false)


func _tick_wave(delta: float) -> void:
	if _wave_r < 0.0 or _wave == null:
		return
	_wave_r += delta * 9.0
	_wave.scale = Vector3(_wave_r, 3.0, _wave_r)
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var d: float = Vector2(p.x - _wave.global_position.x, p.z - _wave.global_position.z).length()
	var hero: Node = manager.main.hero_v28
	var airborne: bool = p.y - _wave.global_position.y > 0.45
	if not bool(get_meta("onde_touche", false)) and absf(d - _wave_r) < 0.7 and not airborne:
		set_meta("onde_touche", true)
		if hero == null or str(hero.state) != "roulade":
			manager.hurt_player(2, _wave.global_position)
	if _wave_r > 22.0:
		_wave_r = -1.0
		_wave.visible = false


## La pluie de pierres : une pierre qui tombe sur l'endroit où l'on est (une ombre prévient).
func _throw_rock(target: Vector3) -> void:
	var at := Vector3(target.x, global_position.y, target.z)
	var shadow := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.0
	cm.bottom_radius = 2.0
	cm.height = 0.02
	shadow.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0, 0, 0, 0.45)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.material_override = sm
	manager.add_child(shadow)
	shadow.global_position = at + Vector3.UP * 0.05
	var Rk = load("res://scripts/rocks_v26.gd")
	var rock := MeshInstance3D.new()
	rock.mesh = Rk.shape(6390 + _rocks.size(), Vector3(1.4, 1.2, 1.3), 0.75, 0.15)
	rock.material_override = _flash_mats[0] if not _flash_mats.is_empty() else null
	manager.add_child(rock)
	rock.global_position = at + Vector3.UP * 16.0
	_rocks.append({"rock": rock, "shadow": shadow, "at": at, "t": 0.0})
	if manager.main.has_method("sfx"):
		manager.main.sfx("golem_menace", global_position + Vector3.UP * 5.0)


func _tick_rocks(delta: float) -> void:
	for i in range(_rocks.size() - 1, -1, -1):
		var r: Dictionary = _rocks[i]
		r["t"] = float(r["t"]) + delta
		var u: float = float(r["t"]) / 1.4
		var rock: Node3D = r["rock"]
		rock.global_position = (r["at"] as Vector3) + Vector3.UP * (16.0 * (1.0 - u * u))
		rock.rotate_x(delta * 3.0)
		(r["shadow"] as Node3D).scale = Vector3.ONE * (0.3 + 0.7 * u)
		if u >= 1.0:
			var p: Vector3 = _player()
			if manager.main.xr_active:
				p.y -= 1.5
			if Vector2(p.x - (r["at"] as Vector3).x, p.z - (r["at"] as Vector3).z).length() < 2.2:
				manager.hurt_player(2, r["at"])
			var cb: Node = manager.main.combat_v28
			if cb != null:
				for k in range(5):
					var a: float = TAU * k / 5.0
					cb.puff((r["at"] as Vector3) + Vector3(cos(a) * 1.2, 0.4, sin(a) * 1.2), Color(0.6, 0.56, 0.52))
			if manager.main.has_method("sfx"):
				manager.main.sfx("touche_pierre", r["at"], 4.0)
			rock.queue_free()
			(r["shadow"] as Node).queue_free()
			_rocks.remove_at(i)


func _die63() -> void:
	super._die63()
	for r in _rocks:
		(r["rock"] as Node).queue_free()
		(r["shadow"] as Node).queue_free()
	_rocks.clear()
	if _wave != null:
		_wave.visible = false
	_wave_r = -1.0


func _death_tick(delta: float) -> void:
	timer += delta
	_torso.position.y = -minf(timer * 1.2, 2.2)
	_torso.rotation.x = minf(timer * 0.5, 0.6)
	for a in _arms:
		(a[0] as Node3D).rotation.z = float(a[1]) * minf(timer * 0.8, 1.1)
	if core_mat != null:
		core_mat.emission = core_mat.emission.lerp(Color(1.0, 0.85, 0.4), clampf(delta * 0.8, 0.0, 1.0))
	if timer > 6.0:
		set_physics_process(false)


func alert_text() -> String:
	return "LE GARDIEN DU CŒUR ! Un colosse de roche, veiné de feu, quatre runes qui brillent sur son corps… Chacune répond au pouvoir d'un sceau. Brise-les !"


func loot(rng: RandomNumberGenerator) -> Array:
	return [["piece", rng.randi_range(80, 120)], ["piece_or", 3]]

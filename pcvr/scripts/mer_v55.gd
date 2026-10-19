extends Node3D
## V55 : la mer — nager, plonger, respirer, et ce qu'on trouve au fond.
##  - Nage (PC et VR) : dès qu'on n'a plus pied, on nage. À la surface, la tête dépasse.
##    PC : ZQSD pour nager, Espace pour remonter, Ctrl (ou C) pour plonger, Maj pour
##    accélérer, Espace face à un ponton ou un rocher pour se hisser dessus.
##    VR : stick gauche = nager dans la direction du regard (regarder vers le bas pour
##    plonger), A = remonter, B = descendre, gâchette gauche = accélérer.
##  - L'air : sans masque, ~18 s sous l'eau, puis on suffoque (un demi-cœur toutes les
##    1,5 s). Avec le masque de plongée (le trésor de Sire Orage), on respire sans limite.
##    Les palmes atlantes font nager une fois et demie plus vite.
##  - Sous l'eau : brume bleu-vert qui s'assombrit avec la profondeur, la surface vue
##    d'en dessous (fenêtre de Snell), rayons de soleil, particules en suspension, bulles,
##    sons étouffés (filtre passe-bas sur les ambiances et les bruitages).
##  - La quête des trois Perles de Lumière (le bénitier, l'épave, la fosse), le Grand
##    Cristal de l'Atlantide, la sauvegarde.

const Fond = preload("res://scripts/fond_marin_v55.gd")
const AtlScript = preload("res://scripts/atlantide_v55.gd")
const VieScript = preload("res://scripts/vie_marine_v55.gd")
const SEA_Y: float = -0.42
const SWIM_ENTER: float = 1.3            # profondeur d'eau au-delà de laquelle on nage
const AIR_MAX: float = 18.0
const DROWN_TICK: float = 1.5
const SPEED: float = 2.3
const SPEED_SUB: float = 2.9
const SPRINT_K: float = 1.6
const FINS_K: float = 1.55
const VERT: float = 2.3
const WORLD_MID := Vector3(-40.0, 0.0, -80.0)
const WORLD_R: float = 600.0
const PEARLS := ["perle_benitier", "perle_epave", "perle_fosse"]

var main: Node
var fond: Node3D
var atl: Node3D
var vie: Node3D
var state: Dictionary = {}
var air: float = AIR_MAX
var swimming: bool = false               # le joueur nage (PC ou VR)
var under: bool = false                  # la caméra est sous l'eau
var in_dome_now: bool = false
var zone: String = ""                    # "", "sous_marin", "atlantide"
var drowned_ticks: int = 0               # pour les tests
var strokes: int = 0
var _vr_swim: bool = false
var _vr_a_was: bool = false
var _below_was: bool = true
var _vel: Vector3 = Vector3.ZERO
var _pitch: float = 0.0
var _yaw: float = 0.0
var _drown: float = 0.0
var _bubble_clock: float = 2.0
var _stroke_clock: float = 0.0
var _head_was_under: bool = false
var _soft: float = 0.0
var _was_in_dome: bool = false
var _attack_t: float = -1.0
var _attack_hit: bool = false
var _push: Vector3 = Vector3.ZERO
var _env: Environment
var _sun: DirectionalLight3D
var _env_base: Dictionary = {}
var _env_mode: String = ""
var _lp_fx: Array = []                   # [bus, index]
var _underside: MeshInstance3D
var _motes: GPUParticles3D
var _rays: MultiMeshInstance3D
var _bubbles: GPUParticles3D
var _splash: GPUParticles3D
var _overlay: CanvasLayer
var _air_box: HBoxContainer
var _air_icons: Array = []
var _air_vr: Label3D
var _mask_node: Node3D
var _tips: Dictionary = {}


func _defaults() -> Dictionary:
	return {"visite": false, "perle_benitier": false, "perle_epave": false, "perle_fosse": false, "cristal": false, "masque_donne": false}


func setup(main_node: Node) -> void:
	main = main_node
	state = _defaults()


func build() -> void:
	name = "Mer_v55"
	fond = Fond.new()
	add_child(fond)
	fond.build(main)
	atl = AtlScript.new()
	add_child(atl)
	atl.build(main)
	vie = VieScript.new()
	add_child(vie)
	vie.build(main, self)
	_find_env()
	_build_fx()
	_setup_audio()


# =================================================================== repères

func seabed(x: float, z: float) -> float:
	return Fond.height(x, z)


func has_mask() -> bool:
	return main.inventory_v28 != null and int(main.inventory_v28.count("masque_plongee")) > 0


func has_fins() -> bool:
	return main.inventory_v28 != null and int(main.inventory_v28.count("palmes_atlante")) > 0


func pearls_found() -> int:
	var n: int = 0
	for k in PEARLS:
		if bool(state[k]):
			n += 1
	return n


func in_world(p: Vector3) -> bool:
	return Vector2(p.x - WORLD_MID.x, p.z - WORLD_MID.z).length() < WORLD_R


## Ce point est-il dans la mer (de l'eau au-dessus du fond) ?
func is_sea(p: Vector3) -> bool:
	return p.y > -40.0 and SEA_Y - main._height_at(p.x, p.z) > 0.5 and not atl.in_dome(p + Vector3.UP * 0.9)


## Pour main._limit_on_foot_v29 : dans l'eau, on peut aller partout (dans la limite du monde).
func water_ok(p: Vector3) -> bool:
	if not in_world(p):
		return false
	if swimming:
		return true
	return SEA_Y - main._height_at(p.x, p.z) > 0.6


func should_swim(feet: Vector3) -> bool:
	if feet.y < -40.0 or feet.y > SEA_Y - 0.9:
		return false
	if atl != null and atl.in_dome(feet + Vector3.UP * 0.9):
		return false
	return SEA_Y - main._height_at(feet.x, feet.z) > SWIM_ENTER


func should_stand(feet: Vector3) -> bool:
	if atl != null and atl.in_dome(feet + Vector3.UP * 0.9):
		return true
	var ground: float = main._height_at(feet.x, feet.z)
	return SEA_Y - ground < 1.15 and feet.y - ground < 0.6


## Hauteur des pieds quand on flotte à la surface (selon l'inclinaison du corps).
func _surface_feet() -> float:
	return SEA_Y - (0.95 + 0.62 * cos(_pitch) - 0.18)


func _at_surface(feet: Vector3) -> bool:
	return feet.y > _surface_feet() - 0.35


# =================================================================== nage (PC)

func start_swim_pc(h: Node) -> void:
	var body: CharacterBody3D = h.body
	h.state = "nage"
	swimming = true
	_vel = body.velocity
	_vel.y = clampf(_vel.y, -6.0, 1.0)
	_pitch = 0.2
	_yaw = atan2(h.facing.x, h.facing.z)
	var p: Vector3 = body.global_position
	if body.velocity.y < -4.0:
		main.sfx("plongeon", Vector3(p.x, SEA_Y, p.z), 0.0)
		splash(Vector3(p.x, SEA_Y, p.z), 1.3)
	else:
		main.sfx("nage", Vector3(p.x, SEA_Y, p.z), -4.0)
		splash(Vector3(p.x, SEA_Y, p.z), 0.6)
	if main.fishing_v32 != null:
		main.fishing_v32.cancel("")
	_tip("nage", "Tu nages ! Espace : remonter, Ctrl : plonger, Maj : nager vite. Face à un ponton ou un rocher, Espace pour te hisser.", 6.0)


func _leave_swim_pc(h: Node) -> void:
	h.state = "sol"
	h.fall_top = h.body.global_position.y
	swimming = false
	_vel = Vector3.ZERO
	_pitch = 0.0
	_update_mask(false)
	if h.hero != null:
		h.hero.rotation = Vector3(0, h.hero.rotation.y, 0)


func swim_pc(h: Node, delta: float, dir: Vector3) -> void:
	var body: CharacterBody3D = h.body
	var feet: Vector3 = body.global_position
	if should_stand(feet):
		_leave_swim_pc(h)
		return
	var can: bool = h._can_act()
	var up_in: bool = can and Input.is_key_pressed(KEY_SPACE)
	var down_in: bool = can and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C))
	var sprint: bool = can and Input.is_key_pressed(KEY_SHIFT) and dir.length() > 0.1 and not bool(h.stamina_lock)
	if sprint:
		h._spend(1.1 * delta)
	# Se hisser sur un ponton, un rocher, la barque… (Espace à la surface)
	if up_in and _at_surface(feet) and h.jump_buffer > 0.0:
		var aim: Vector3 = dir if dir.length() > 0.1 else h.facing
		var ledge: Dictionary = h.find_ledge(body, aim, 3.4)
		if not ledge.is_empty():
			h.jump_buffer = 0.0
			_leave_swim_pc(h)
			h._start_mantle(ledge)
			return
	var target: Vector3 = _swim_target(feet, dir, up_in, down_in, sprint)
	_vel = _vel.lerp(target, 1.0 - exp(-delta * 3.2)) + _push
	_push = _push.lerp(Vector3.ZERO, clampf(delta * 4.0, 0.0, 1.0))
	body.velocity = _vel
	body.move_and_slide()
	_clamp_swimmer(body)
	h.root.position = body.position
	if dir.length() > 0.1:
		h.facing = dir
	_attack_tick(h, delta)
	_strokes(delta, body.global_position)
	_breath(delta, body.global_position + Vector3.UP * (0.95 + 0.62 * cos(_pitch)))


func _swim_target(feet: Vector3, dir: Vector3, up_in: bool, down_in: bool, sprint: bool) -> Vector3:
	var surf: bool = _at_surface(feet)
	var sp: float = SPEED if surf else SPEED_SUB
	if sprint:
		sp *= SPRINT_K
	if has_fins():
		sp *= FINS_K
	var v: Vector3 = dir * sp
	if surf and v.y > 0.0:
		v.y = 0.0
	if up_in:
		v.y = VERT * (1.25 if has_fins() else 1.0)
	elif down_in:
		v.y = -VERT * (1.25 if has_fins() else 1.0)
	elif absf(dir.y) < 0.05:
		# on remonte doucement (sans masque, plus vite : le corps veut respirer)
		if feet.y < _surface_feet() - 0.05:
			v.y = 0.12 if has_mask() else 0.65
	return v


## Pas plus haut que la surface, pas hors du monde.
func _clamp_swimmer(body: CharacterBody3D) -> void:
	var p: Vector3 = body.global_position
	var top: float = _surface_feet() + sin(Time.get_ticks_msec() * 0.0016) * 0.04
	if p.y > top:
		p.y = lerpf(p.y, top, 0.5)
		if _vel.y > 0.0:
			_vel.y = 0.0
	var off := Vector2(p.x - WORLD_MID.x, p.z - WORLD_MID.z)
	if off.length() > WORLD_R:
		off = off.normalized() * WORLD_R
		p.x = WORLD_MID.x + off.x
		p.z = WORLD_MID.z + off.y
		_vel.x = 0.0
		_vel.z = 0.0
	body.global_position = p


func push_player(v: Vector3) -> void:
	_push += v


## L'attaque sous l'eau : un coup d'épée (ou de trident) devant soi, en 3D.
func swim_attack(h: Node) -> void:
	if _attack_t >= 0.0:
		return
	_attack_t = 0.0
	_attack_hit = false
	main.sfx("fendre_air", h.body.global_position + Vector3.UP * 1.0, -4.0)


func _attack_tick(h: Node, delta: float) -> void:
	if _attack_t < 0.0:
		return
	_attack_t += delta
	if not _attack_hit and _attack_t >= 0.2:
		_attack_hit = true
		var chest: Vector3 = h.body.global_position + Vector3.UP * 1.0
		var fwd: Vector3 = h.facing
		var dmg: int = int(h.weapon_damage) if str(h.weapon) != "" else 1
		var reach: float = 2.6 if str(h.weapon) != "" else 1.6
		for t in get_tree().get_nodes_in_group("cibles_v28"):
			var n3: Node3D = t as Node3D
			if not n3.is_hittable():
				continue
			var c: Vector3 = n3.global_position + Vector3.UP * float(n3.hit_height)
			var off: Vector3 = c - chest
			var d: float = off.length() - float(n3.hit_radius)
			if d > reach:
				continue
			var flat := Vector3(off.x, 0, off.z)
			if d > 0.4 and flat.length() > 0.3 and fwd.dot(flat.normalized()) < 0.2:
				continue
			n3.take_hit(dmg, chest)
			main.sfx("touche_chair", c)
	if _attack_t > 0.55:
		_attack_t = -1.0


## L'allure du héros dans l'eau : le corps se couche quand on avance, se redresse au repos,
## pique vers le fond quand on plonge. Pivot au bassin.
func swim_visual(h: Node, delta: float) -> void:
	var hero: Node3D = h.hero
	if hero == null:
		return
	var spd: float = _vel.length()
	var feet: Vector3 = h.body.global_position
	var surf: bool = _at_surface(feet)
	var pitch_t: float = 0.12
	if spd > 0.5:
		var elev: float = asin(clampf(_vel.y / spd, -1.0, 1.0))
		pitch_t = clampf(PI * 0.5 - elev, 0.25, PI * 0.92)
		if surf:
			pitch_t = minf(pitch_t, deg_to_rad(72.0))
	_pitch = lerp_angle(_pitch, pitch_t, 1.0 - exp(-delta * 3.5))
	_yaw = lerp_angle(_yaw, atan2(h.facing.x, h.facing.z), 1.0 - exp(-delta * 8.0))
	var sc: float = hero.scale.x
	var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch)
	var pivot := Vector3(0, 0.95, 0)
	var origin: Vector3 = h.root.position + Vector3.UP * main.hero_mesh_floor_offset_v11
	hero.transform = Transform3D(b.scaled(Vector3.ONE * sc), origin + pivot - b * pivot)
	if _attack_t >= 0.0:
		h._play("v28/slash2", 0.06)
	elif spd > 0.5 and not surf:
		h._play("v28/nage_crawl", 0.3, clampf(spd / 2.6, 0.6, 1.8))
	elif spd > 0.5:
		h._play("v28/nage_brasse", 0.3, clampf(spd / 2.2, 0.6, 1.6))
	else:
		h._play("v28/nage_surplace", 0.35)
	_update_mask(true)


# =================================================================== nage (VR)

func vr_swim_tick(delta: float) -> bool:
	var body: CharacterBody3D = main.vr_body
	if body == null:
		return false
	var feet: Vector3 = body.global_position
	if not _vr_swim:
		if not should_swim(feet):
			return false
		_vr_swim = true
		swimming = true
		_vel = body.velocity
		_vel.y = clampf(_vel.y, -6.0, 1.0)
		main.sfx("plongeon" if body.velocity.y < -4.0 else "nage", Vector3(feet.x, SEA_Y, feet.z), -2.0)
		splash(Vector3(feet.x, SEA_Y, feet.z), 1.0)
		_tip("nage_vr", "Tu nages ! Stick gauche : nager vers où tu regardes (regarde en bas pour plonger). A : remonter, B : descendre, gâchette gauche : nager vite.", 7.0)
	elif should_stand(feet):
		_vr_swim = false
		swimming = false
		_vel = Vector3.ZERO
		return false
	var cam: Camera3D = main.xr_camera
	var stick: Vector2 = main.left_hand.get_vector2("primary")
	var dir := Vector3.ZERO
	if stick.length() > float(main.DEADZONE):
		var fwd: Vector3 = -cam.global_transform.basis.z
		var right: Vector3 = cam.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		dir = right * stick.x + fwd * stick.y
		if dir.length() > 1.0:
			dir = dir.normalized()
	var up_in: bool = main.right_hand.is_button_pressed("ax_button")
	var down_in: bool = main.right_hand.is_button_pressed("by_button")
	var sprint: bool = main.left_hand.get_float("trigger") > 0.6
	var eye: float = cam.global_position.y - main.xr_origin.global_position.y
	_pitch = 0.0
	var surf_feet: float = SEA_Y + 0.14 - eye
	var surf: bool = feet.y > surf_feet - 0.35
	# A à la surface, face à un ponton ou un rocher : on se hisse dessus
	if up_in and not _vr_a_was and surf and main.hero_v28 != null:
		var look: Vector3 = -cam.global_transform.basis.z
		look.y = 0.0
		var ledge: Dictionary = main.hero_v28.find_ledge(body, look.normalized(), 3.4)
		if not ledge.is_empty():
			var hd: Vector3 = cam.global_position
			var ho := Vector3(hd.x - main.xr_origin.global_position.x, 0.0, hd.z - main.xr_origin.global_position.z)
			body.global_position = ledge["top"]
			body.velocity = Vector3.ZERO
			main.xr_origin.position = Vector3(body.position.x - ho.x, body.position.y, body.position.z - ho.z)
			_vr_swim = false
			swimming = false
			_vel = Vector3.ZERO
			_vr_a_was = true
			return true
	_vr_a_was = up_in
	var sp: float = (SPEED if surf else SPEED_SUB) * (SPRINT_K if sprint else 1.0) * (FINS_K if has_fins() else 1.0)
	var target: Vector3 = dir * sp
	if surf and target.y > 0.0:
		target.y = 0.0
	if up_in:
		target.y = VERT
	elif down_in:
		target.y = -VERT
	elif dir.length() < 0.1 and feet.y < surf_feet - 0.05:
		target.y = 0.12 if has_mask() else 0.65
	_vel = _vel.lerp(target, 1.0 - exp(-delta * 3.2)) + _push
	_push = _push.lerp(Vector3.ZERO, clampf(delta * 4.0, 0.0, 1.0))
	var head: Vector3 = cam.global_position
	var head_offset := Vector3(head.x - main.xr_origin.global_position.x, 0.0, head.z - main.xr_origin.global_position.z)
	var wanted := Vector3(head.x - feet.x, 0.0, head.z - feet.z)
	if wanted.length() > 1.5:
		body.global_position = Vector3(head.x, feet.y, head.z)
		wanted = Vector3.ZERO
	var dt: float = maxf(delta, 0.001)
	body.velocity = Vector3(wanted.x / dt + _vel.x, _vel.y, wanted.z / dt + _vel.z)
	body.move_and_slide()
	var p: Vector3 = body.global_position
	if p.y > surf_feet:
		p.y = lerpf(p.y, surf_feet, 0.5)
		_vel.y = minf(_vel.y, 0.0)
	var off := Vector2(p.x - WORLD_MID.x, p.z - WORLD_MID.z)
	if off.length() > WORLD_R:
		off = off.normalized() * WORLD_R
		p.x = WORLD_MID.x + off.x
		p.z = WORLD_MID.z + off.y
	body.global_position = p
	main.xr_origin.position = Vector3(p.x - head_offset.x, p.y, p.z - head_offset.z)
	# Rotation par crans (stick droit), comme à pied
	var turn: float = main.right_hand.get_vector2("primary").x
	if absf(turn) < 0.35:
		main.turn_ready = true
	elif absf(turn) > float(main.TURN_STICK_THRESHOLD) and bool(main.turn_ready):
		var pivot: Vector3 = cam.global_position
		main.xr_origin.rotate_y(-signf(turn) * float(main.SNAP_TURN))
		var after: Vector3 = cam.global_position
		main.xr_origin.global_position += Vector3(pivot.x - after.x, 0.0, pivot.z - after.z)
		main.turn_ready = false
	_strokes(delta, p)
	_breath(delta, cam.global_position)
	return true


# =================================================================== souffle

func _breath(delta: float, head: Vector3) -> void:
	var head_under: bool = head.y < SEA_Y - 0.05 and not atl.in_dome(head)
	if head_under and not has_mask():
		air = maxf(air - delta, 0.0)
		_tip("souffle", "Retiens ton souffle ! Sans masque, tu ne tiens que quelques secondes sous l'eau. Remonte respirer (Espace).", 5.0)
		if air <= 0.0:
			_drown += delta
			if _drown >= DROWN_TICK:
				_drown = 0.0
				drowned_ticks += 1
				main.sfx("suffoque", head, -2.0)
				bubbles(head, 2.0)
				if main.get("monstres_v36") != null and main.monstres_v36 != null:
					main.monstres_v36.hurt_player(1, Vector3.ZERO)
	else:
		if not head_under and _head_was_under and air < AIR_MAX * 0.6:
			main.sfx("respiration", head, -6.0)
		air = minf(air + delta * 8.0, AIR_MAX)
		_drown = 0.0
	if head_under and has_mask() and head.y < SEA_Y - 0.8:
		_tip("masque", "Le masque des Rois-Ciel : tu respires sous l'eau ! Explore les profondeurs… au sud-ouest du village, une lumière brille au fond.", 6.0)
	if head_under:
		_bubble_clock -= delta
		if _bubble_clock <= 0.0:
			_bubble_clock = 3.6 if has_mask() else 2.2
			bubbles(head, 1.0)
			main.sfx("bulles", head, -14.0)
	_head_was_under = head_under


func _strokes(delta: float, at: Vector3) -> void:
	var spd: float = Vector2(_vel.x, _vel.z).length() + absf(_vel.y) * 0.5
	if spd < 0.6:
		return
	_stroke_clock -= delta * clampf(spd / 2.4, 0.5, 1.8)
	if _stroke_clock <= 0.0:
		_stroke_clock = 0.95
		strokes += 1
		if _at_surface(at):
			main.sfx("nage", Vector3(at.x, SEA_Y, at.z), -6.0)
		else:
			main.sfx("nage_sous", at + Vector3.UP, -8.0)


# =================================================================== effets

func _find_env() -> void:
	for c in main.get_children():
		if c is WorldEnvironment:
			_env = (c as WorldEnvironment).environment
	_sun = main.get_node_or_null("Soleil_v24") as DirectionalLight3D


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 32
	t.height = 32
	return t


func _build_fx() -> void:
	# La surface vue d'en dessous
	_underside = MeshInstance3D.new()
	_underside.name = "Surface_dessous_v55"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1600.0, 1600.0)
	_underside.mesh = plane
	var um := ShaderMaterial.new()
	um.shader = load("res://shaders/surface_dessous_v55.gdshader")
	if ResourceLoader.exists("res://assets/textures/water/water_n.png"):
		um.set_shader_parameter("ripple_n", load("res://assets/textures/water/water_n.png"))
	_underside.material_override = um
	_underside.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_underside.visible = false
	add_child(_underside)
	_underside.global_position = Vector3(0, SEA_Y + 0.02, 0)
	# Les particules en suspension
	_motes = GPUParticles3D.new()
	_motes.name = "Plancton_v55"
	_motes.amount = 380
	_motes.lifetime = 9.0
	_motes.preprocess = 9.0
	_motes.local_coords = false
	_motes.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 28, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(14, 9, 14)
	pm.gravity = Vector3(0, -0.02, 0)
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.direction = Vector3(0.3, 0.2, 0.1)
	pm.spread = 180.0
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.8, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	_motes.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.045, 0.045)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	qm.albedo_texture = _soft_dot()
	qm.albedo_color = Color(0.75, 0.92, 0.95, 0.55)
	q.material = qm
	_motes.draw_pass_1 = q
	_motes.emitting = false
	_motes.visible = false
	add_child(_motes)
	# Les rayons de soleil
	var rm := MultiMesh.new()
	rm.transform_format = MultiMesh.TRANSFORM_3D
	rm.use_custom_data = true
	var ray := QuadMesh.new()
	ray.size = Vector2(1.0, 1.0)
	ray.center_offset = Vector3(0, -0.5, 0)
	rm.mesh = ray
	rm.instance_count = 16
	for i in range(16):
		rm.set_instance_custom_data(i, Color(randf(), 0, 0, 0))
	_rays = MultiMeshInstance3D.new()
	_rays.name = "Rayons_v55"
	_rays.multimesh = rm
	var rmat := ShaderMaterial.new()
	rmat.shader = load("res://shaders/rayons_v55.gdshader")
	_rays.material_override = rmat
	_rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rays.visible = false
	add_child(_rays)
	_ray_spots.resize(16)
	for i2 in range(16):
		_ray_spots[i2] = Vector3(randf_range(-22, 22), 0, randf_range(-22, 22))
	# Les bulles
	_bubbles = GPUParticles3D.new()
	_bubbles.name = "Bulles_v55"
	_bubbles.amount = 16
	_bubbles.lifetime = 3.0
	_bubbles.one_shot = true
	_bubbles.explosiveness = 0.55
	_bubbles.local_coords = false
	var bm := ParticleProcessMaterial.new()
	bm.direction = Vector3(0, 1, 0)
	bm.spread = 25.0
	bm.initial_velocity_min = 0.4
	bm.initial_velocity_max = 1.1
	bm.gravity = Vector3(0, 2.2, 0)
	bm.damping_min = 0.8
	bm.damping_max = 1.6
	bm.scale_min = 0.4
	bm.scale_max = 1.3
	bm.turbulence_enabled = true
	bm.turbulence_noise_strength = 0.4
	_bubbles.process_material = bm
	var bq := QuadMesh.new()
	bq.size = Vector2(0.09, 0.09)
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	if ResourceLoader.exists("res://assets/textures/mer/bulle.png"):
		bmat.albedo_texture = load("res://assets/textures/mer/bulle.png")
	bq.material = bmat
	_bubbles.draw_pass_1 = bq
	_bubbles.emitting = false
	add_child(_bubbles)
	# Les éclaboussures
	_splash = GPUParticles3D.new()
	_splash.name = "Eclaboussures_v55"
	_splash.amount = 36
	_splash.lifetime = 1.1
	_splash.one_shot = true
	_splash.explosiveness = 0.9
	_splash.local_coords = false
	var sm := ParticleProcessMaterial.new()
	sm.direction = Vector3(0, 1, 0)
	sm.spread = 35.0
	sm.initial_velocity_min = 2.0
	sm.initial_velocity_max = 4.5
	sm.gravity = Vector3(0, -9.8, 0)
	sm.scale_min = 0.5
	sm.scale_max = 1.5
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sm.emission_sphere_radius = 0.4
	_splash.process_material = sm
	var sq := QuadMesh.new()
	sq.size = Vector2(0.12, 0.12)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smat.albedo_texture = _soft_dot()
	smat.albedo_color = Color(0.92, 0.97, 1.0, 0.85)
	sq.material = smat
	_splash.draw_pass_1 = sq
	_splash.emitting = false
	add_child(_splash)
	# PC : le voile de l'eau (teinte, vignette, ondulation de l'image)
	_overlay = CanvasLayer.new()
	_overlay.name = "Voile_sous_marin_v55"
	_overlay.layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var osh := Shader.new()
	osh.code = """shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float depth_k = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen, uv).rgb;
	vec2 q = uv - 0.5;
	float vig = 1.0 - dot(q, q) * (0.9 + depth_k * 0.6);
	c = mix(c, c * vec3(0.78, 0.95, 1.0), 0.35) * vig;
	COLOR = vec4(c, 1.0);
}
"""
	var om := ShaderMaterial.new()
	om.shader = osh
	rect.material = om
	_overlay.add_child(rect)
	_overlay.visible = false
	add_child(_overlay)
	# Les bulles d'air (PC : sous les cœurs ; VR : sous le regard)
	if main.get("hud_v28") != null and main.hud_v28 != null:
		_air_box = HBoxContainer.new()
		_air_box.name = "Air_v55"
		_air_box.add_theme_constant_override("separation", 0)
		_air_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_air_box.offset_left = -20.0 - 9 * 26.0
		_air_box.offset_right = -20.0
		_air_box.offset_top = 60.0
		_air_box.offset_bottom = 86.0
		var tex: Texture2D = load("res://assets/textures/mer/bulle.png") if ResourceLoader.exists("res://assets/textures/mer/bulle.png") else null
		for i3 in range(9):
			var tr := TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(26, 26)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_air_box.add_child(tr)
			_air_icons.append(tr)
		_air_box.visible = false
		main.hud_v28.add_child(_air_box)
	if main.get("xr_camera") != null and main.xr_camera != null:
		_air_vr = Label3D.new()
		_air_vr.name = "Air_VR_v55"
		_air_vr.font_size = 44
		_air_vr.pixel_size = 0.0012
		_air_vr.outline_size = 10
		_air_vr.no_depth_test = true
		_air_vr.position = Vector3(0, -0.22, -0.7)
		_air_vr.modulate = Color(0.8, 0.95, 1.0)
		_air_vr.visible = false
		main.xr_camera.add_child(_air_vr)


var _ray_spots: Array = []


func splash(at: Vector3, size: float = 1.0) -> void:
	if _splash == null:
		return
	_splash.global_position = at
	_splash.amount_ratio = clampf(size, 0.2, 1.0)
	_splash.restart()


func bubbles(at: Vector3, size: float = 1.0) -> void:
	if _bubbles == null:
		return
	_bubbles.global_position = at
	_bubbles.amount_ratio = clampf(size * 0.5, 0.2, 1.0)
	_bubbles.restart()


func _setup_audio() -> void:
	for bus_name in ["Ambiance", "Bruitages"]:
		var b: int = AudioServer.get_bus_index(bus_name)
		if b < 0:
			continue
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 650.0 if bus_name == "Ambiance" else 2600.0
		lp.resonance = 0.5
		AudioServer.add_bus_effect(b, lp)
		var idx: int = AudioServer.get_bus_effect_count(b) - 1
		AudioServer.set_bus_effect_enabled(b, idx, false)
		_lp_fx.append([b, idx])


func _set_muffled(on: bool) -> void:
	for e in _lp_fx:
		if int(e[1]) < AudioServer.get_bus_effect_count(int(e[0])):
			AudioServer.set_bus_effect_enabled(int(e[0]), int(e[1]), on)


func _apply_env(mode: String) -> void:
	if _env == null:
		return
	if _env_base.is_empty():
		_env_base = {"fog_c": _env.fog_light_color, "fog_d": _env.fog_density, "fog_sky": _env.fog_sky_affect, "fog_aer": _env.fog_aerial_perspective,
			"vol_d": _env.volumetric_fog_density, "vol_a": _env.volumetric_fog_albedo, "sat": _env.adjustment_saturation,
			"glow": _env.glow_intensity, "sun": _sun.light_energy if _sun != null else 1.0}
	_env_mode = mode
	var pc: bool = OS.has_feature("ile_manga_pc")
	match mode:
		"sous_marin":
			_env.fog_light_color = Color(0.1, 0.4, 0.46)
			_env.fog_density = 0.042
			_env.fog_sky_affect = 1.0
			_env.fog_aerial_perspective = 0.0
			if pc:
				_env.volumetric_fog_density = 0.028
				_env.volumetric_fog_albedo = Color(0.45, 0.8, 0.85)
			_env.adjustment_saturation = 1.0
			_env.glow_intensity = 0.55
			if _sun != null:
				_sun.light_energy = float(_env_base["sun"]) * 0.8
		"atlantide":
			_env.fog_light_color = Color(0.07, 0.28, 0.34)
			_env.fog_density = 0.0095
			_env.fog_sky_affect = 1.0
			_env.fog_aerial_perspective = 0.0
			if pc:
				_env.volumetric_fog_density = 0.012
				_env.volumetric_fog_albedo = Color(0.5, 0.85, 0.9)
			_env.glow_intensity = 0.6
			if _sun != null:
				_sun.light_energy = float(_env_base["sun"]) * 0.32
		_:
			_env.fog_light_color = _env_base["fog_c"]
			_env.fog_density = _env_base["fog_d"]
			_env.fog_sky_affect = _env_base["fog_sky"]
			_env.fog_aerial_perspective = _env_base["fog_aer"]
			_env.volumetric_fog_density = _env_base["vol_d"]
			_env.volumetric_fog_albedo = _env_base["vol_a"]
			_env.adjustment_saturation = _env_base["sat"]
			_env.glow_intensity = _env_base["glow"]
			if _sun != null:
				_sun.light_energy = _env_base["sun"]
			_env_base = {}


func _update_fx(cam: Camera3D, delta: float) -> void:
	var cp: Vector3 = cam.global_position
	var mode: String = ""
	if under:
		mode = "sous_marin"
	elif atl.in_dome(cp):
		mode = "atlantide"
	if mode != _env_mode:
		_apply_env(mode)
		_set_muffled(mode == "sous_marin")
	zone = mode
	# Ce qui est transparent sous la mer (le dôme, les halos) ne se voit pas d'au-dessus de l'eau
	var below: bool = under or mode == "atlantide"
	if below != _below_was:
		_below_was = below
		for n in get_tree().get_nodes_in_group("sous_eau_v55"):
			(n as Node3D).visible = below
	_underside.visible = under
	_motes.visible = under
	_motes.emitting = under
	_rays.visible = under
	_overlay.visible = under and not bool(main.xr_active)
	if not under:
		return
	var depth: float = clampf((SEA_Y - cp.y) / 32.0, 0.0, 1.0)
	_env.fog_light_color = Color(0.1, 0.4, 0.46).lerp(Color(0.02, 0.13, 0.2), depth)
	_env.fog_density = lerpf(0.038, 0.055, depth)
	_underside.global_position = Vector3(cp.x, SEA_Y + 0.02, cp.z)
	_motes.global_position = cp
	(_overlay.get_child(0) as ColorRect).material.set("shader_parameter/depth_k", depth)
	# Les rayons : autour de la caméra, tournés vers elle, plus pâles au fond
	var rm: MultiMesh = _rays.multimesh
	(_rays.material_override as ShaderMaterial).set_shader_parameter("intensity", 0.09 * (1.0 - depth * 0.6))
	for i in range(_ray_spots.size()):
		var s: Vector3 = _ray_spots[i]
		var wx: float = snappedf(cp.x, 44.0) + s.x
		var wz: float = snappedf(cp.z, 44.0) + s.z
		if wx - cp.x > 22.0:
			wx -= 44.0
		elif wx - cp.x < -22.0:
			wx += 44.0
		if wz - cp.z > 22.0:
			wz -= 44.0
		elif wz - cp.z < -22.0:
			wz += 44.0
		var top := Vector3(wx, SEA_Y, wz)
		var floor_y: float = main._height_at(wx, wz)
		var length: float = clampf(SEA_Y - floor_y, 4.0, 36.0)
		var to_cam := Vector3(cp.x - wx, 0, cp.z - wz)
		var yaw: float = atan2(to_cam.x, to_cam.z)
		var b := Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, 0.08)
		rm.set_instance_transform(i, Transform3D(b.scaled(Vector3(1.6 + float(i % 3) * 0.9, length, 1.0)), top))


func _update_air_hud() -> void:
	var show: bool = air < AIR_MAX - 0.05
	if _air_box != null:
		_air_box.visible = show and not bool(main.xr_active)
		var n: int = int(ceil(air / AIR_MAX * _air_icons.size()))
		for i in range(_air_icons.size()):
			(_air_icons[i] as TextureRect).modulate = Color(1, 1, 1, 1.0 if i < n else 0.15)
	if _air_vr != null:
		_air_vr.visible = show and bool(main.xr_active)
		if _air_vr.visible:
			var k: int = int(ceil(air / AIR_MAX * 9.0))
			_air_vr.text = "Air  " + "●".repeat(k) + "○".repeat(9 - k)


func _tip(key: String, text: String, seconds: float) -> void:
	if bool(_tips.get(key, false)):
		return
	_tips[key] = true
	main._show_message_v28(text)
	if main.message_clock_v28 < seconds:
		main.message_clock_v28 = seconds


## Le masque, sur le visage du héros quand il nage (PC).
func _update_mask(on: bool) -> void:
	var hero: Node = main.get("hero_v28")
	if hero == null or hero.skel == null:
		return
	if _mask_node == null:
		var skel: Skeleton3D = hero.skel
		var b: int = skel.find_bone("Head")
		if b < 0:
			return
		var att := BoneAttachment3D.new()
		att.name = "Masque_plongee_v55"
		att.bone_name = "Head"
		skel.add_child(att)
		var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
		var holder := Node3D.new()
		holder.transform = Transform3D(rest.inverse() * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * Vector3(0, 20.0, 19.0))
		att.add_child(holder)
		_mask_node = Node3D.new()
		holder.add_child(_mask_node)
		var rubber := StandardMaterial3D.new()
		rubber.albedo_color = Color(0.08, 0.09, 0.1)
		rubber.roughness = 0.6
		var brass := StandardMaterial3D.new()
		brass.albedo_color = Color(0.78, 0.6, 0.28)
		brass.metallic = 0.9
		brass.roughness = 0.3
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.55, 0.85, 1.0, 0.45)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = 0.05
		glass.metallic = 0.3
		var skirt := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.36, 0.15, 0.08)
		skirt.mesh = bm
		skirt.material_override = rubber
		_mask_node.add_child(skirt)
		for sx in [-1.0, 1.0]:
			var ring := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.075
			cm.bottom_radius = 0.075
			cm.height = 0.04
			ring.mesh = cm
			ring.material_override = brass
			ring.rotation.x = PI * 0.5
			ring.position = Vector3(sx * 0.085, 0.0, 0.045)
			_mask_node.add_child(ring)
			var lens := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.062
			lm.bottom_radius = 0.062
			lm.height = 0.045
			lens.mesh = lm
			lens.material_override = glass
			lens.rotation.x = PI * 0.5
			lens.position = Vector3(sx * 0.085, 0.0, 0.05)
			_mask_node.add_child(lens)
		var strap := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.21
		tm.outer_radius = 0.235
		strap.mesh = tm
		strap.material_override = rubber
		strap.rotation.x = PI * 0.5
		strap.position = Vector3(0, 0, -0.17)
		_mask_node.add_child(strap)
	_mask_node.visible = on and has_mask()


# =================================================================== quête

func build_quest() -> void:
	var d: Node = main.donjon_v35
	var I: Array = d._interactions
	I.append({"id": "perle_benitier", "pos": fond.points["benitier"], "radius": 2.8, "text": "E : ouvrir le bénitier géant", "vr": "Gâchette : ouvrir le bénitier",
		"call": func(): _take_pearl("perle_benitier"), "when": func(): return not bool(state["perle_benitier"])})
	I.append({"id": "perle_epave", "pos": fond.points["coffre_epave"], "radius": 2.6, "text": "E : ouvrir le coffre du capitaine", "vr": "Gâchette : ouvrir le coffre",
		"call": func(): _take_pearl("perle_epave"), "when": func(): return not bool(state["perle_epave"])})
	I.append({"id": "perle_fosse", "pos": fond.points["autel_fosse"], "radius": 2.6, "text": "E : prendre la Perle de Lumière", "vr": "Gâchette : prendre la perle",
		"call": func(): _take_pearl("perle_fosse"), "when": func(): return not bool(state["perle_fosse"])})
	atl.spawn_npcs()
	var amb: Node = main.get("ambiance_v49")
	if amb != null:
		amb.add_emitter(self, atl.C + Vector3(0, 0.8, 0), "emetteurs/ruisseau", -8.0, 5.0, 30.0)


func _take_pearl(id: String) -> void:
	var inv: Node = main.inventory_v28
	if not inv.can_accept([["perle_lumiere", 1]]):
		main.donjon_v35._say("Ton sac est plein ! Fais de la place pour la Perle de Lumière.", 4.0)
		return
	state[id] = true
	inv.add("perle_lumiere", 1)
	var at: Vector3 = main._player_pos_v27() + Vector3.UP
	main.sfx("perle", at)
	main.jingle("decouverte")
	var n: int = pearls_found()
	var text: String = ""
	match id:
		"perle_benitier":
			fond.open_clam()
			get_tree().create_timer(1.4).timeout.connect(func(): fond.clam_pearl.visible = false)
			text = "Le bénitier géant s'entrouvre lentement… Au creux de son manteau bleu brille la Perle du Jardin, l'âge de la vie."
		"perle_epave":
			fond.open_wreck_chest()
			get_tree().create_timer(1.2).timeout.connect(func(): fond.wreck_pearl.visible = false)
			text = "Le coffre du capitaine grince… Entre les pièces moisies luit la Perle de l'Épave, l'âge des hommes."
		"perle_fosse":
			fond.altar_pearl.visible = false
			text = "Tu prends la Perle de la Fosse sur son autel. Elle est froide comme les profondeurs… l'âge des abysses."
	text += " (Perles de Lumière : %d / 3)" % n
	if n == 3:
		text += " Rapporte-les à la reine Néréa !"
	main.donjon_v35._say(text, 7.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(at, Color(0.6, 0.95, 1.0))


func _awaken_crystal() -> void:
	state["cristal"] = true
	atl.set_lit(true)
	main.sfx("cristal_eveil", atl.points["cristal"], 4.0)
	main.jingle("victoire")
	main.donjon_v35._say("Les trois Perles s'élèvent toutes seules vers la tour… et le Grand Cristal s'embrase ! Une lumière bleue inonde la cité, le dôme se met à chanter. L'Atlantide est sauvée !", 9.0)


func respawn_for(p: Vector3) -> Array:
	if atl != null and atl.near(p, 110.0):
		return atl.respawn_point()
	return []


func trouvailles() -> Dictionary:
	return {"masque": 1 if has_mask() else 0, "atlantide": 1 if bool(state["visite"]) else 0, "perles_1": 1 if pearls_found() >= 1 else 0,
		"perles_3": 1 if pearls_found() >= 3 else 0, "cristal": 1 if bool(state["cristal"]) else 0, "palmes": 1 if has_fins() else 0,
		"requins": int(vie.kills) if vie != null else 0}


# =================================================================== boucle

func _physics_process(delta: float) -> void:
	if main == null or not bool(main.game_started) or atl == null:
		return
	var body: CharacterBody3D = main.vr_body if bool(main.xr_active) else main.pc_body
	if body == null:
		return
	var hero: Node = main.get("hero_v28")
	if not bool(main.xr_active):
		swimming = hero != null and str(hero.state) == "nage"
	else:
		swimming = _vr_swim
	# Le héros (PC) ne reste pas couché quand il ne nage plus (téléporté, évanoui…)
	if not swimming and hero != null and hero.hero != null and absf(hero.hero.rotation.x) > 0.001 and str(hero.state) != "bateau":
		hero.hero.rotation = Vector3(0, hero.hero.rotation.y, 0)
	if not swimming and _mask_node != null and _mask_node.visible:
		_mask_node.visible = false
	var feet: Vector3 = body.global_position
	in_dome_now = atl.in_dome(feet + Vector3.UP * 0.9)
	# Entrer dans la bulle : on descend doucement jusqu'au sol (pas de chute)
	if in_dome_now and not _was_in_dome:
		_soft = 8.0
		if not bool(state["visite"]):
			state["visite"] = true
			main.jingle("decouverte")
			main.donjon_v35._say("L'Atlantide ! Une cité entière, sous une immense bulle d'air, à trente mètres sous la mer… Tu peux respirer. Au centre, sur sa tour, un grand cristal pâlit doucement.", 9.0)
	_was_in_dome = in_dome_now
	if _soft > 0.0:
		_soft -= delta
		if body.is_on_floor():
			_soft = 0.0
		elif body.velocity.y < -3.0:
			body.velocity.y = -3.0
		if hero != null:
			hero.fall_top = feet.y
	if not swimming:
		air = minf(air + delta * 8.0, AIR_MAX)
		_head_was_under = false
	_update_air_hud()
	# La quête : la reine a reçu les trois perles
	if not bool(state["cristal"]) and atl.quest_state("nerea") == "finie":
		_awaken_crystal()


func _process(delta: float) -> void:
	if main == null or not bool(main.game_started) or atl == null:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cp: Vector3 = cam.global_position
	under = cp.y < SEA_Y - 0.08 and cp.y > -40.0 and not atl.in_dome(cp) and in_world(cp) and main._height_at(cp.x, cp.z) < cp.y + 0.5
	_update_fx(cam, delta)


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	d["tips"] = _tips.duplicate()
	return d


func load_data(d: Dictionary) -> void:
	state = _defaults()
	for k in state:
		if d.has(k):
			state[k] = bool(d[k])
	_tips = (d.get("tips", {}) as Dictionary).duplicate() if d.get("tips", {}) is Dictionary else {}
	air = AIR_MAX
	_vr_swim = false
	swimming = false
	_vel = Vector3.ZERO
	apply_state()
	# Sire Orage déjà vaincu dans une ancienne partie : le masque était dans son trésor.
	var sky: Node = main.get("ciel_v54")
	if sky != null and bool(sky.state.get("tresor", false)) and not bool(state["masque_donne"]):
		state["masque_donne"] = true
		if not has_mask() and main.inventory_v28 != null:
			main.inventory_v28.add("masque_plongee", 1)


func apply_state() -> void:
	if fond == null:
		return
	if bool(state["perle_benitier"]):
		fond.open_clam(true)
	else:
		fond.clam_top.rotation.x = 0.06
	fond.clam_pearl.visible = not bool(state["perle_benitier"])
	if bool(state["perle_epave"]):
		fond.open_wreck_chest(true)
	else:
		fond.wreck_lid.rotation.x = 0.0
	fond.wreck_pearl.visible = false
	fond.altar_pearl.visible = not bool(state["perle_fosse"])
	atl.set_lit(bool(state["cristal"]), true)

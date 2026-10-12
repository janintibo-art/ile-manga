extends Node3D
## Île Manga PC VR : première conversion NATIVE, pas un navigateur.
## Les coordonnées du monde viennent du prototype Babylon.js existant.
## Les contrôles XR utilisent l'action map OpenXR par défaut de Godot.

const TERRAIN_SIZE: float = 200.0
const TERRAIN_STEPS: int = 110
const WALK_SPEED: float = 3.1
const DEADZONE: float = 0.22
const TURN_STICK_THRESHOLD: float = 0.75
const SNAP_TURN: float = PI / 6.0

var xr_active: bool = false
var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_hand: XRController3D
var right_hand: XRController3D
var pc_root: Node3D
var pc_camera: Camera3D
var pc_hero: Node3D
var message: Label
var info: Label
var turn_ready: bool = true
var native_vr: XRInterface


func _ready() -> void:
	_create_lighting()
	_create_land()
	_create_water()
	_create_village()
	_create_structures()
	_create_players()
	_init_native_xr()
	_update_status()
	print("ILE_MANGA_NATIVE: scene construite; OpenXR actif = ", xr_active)


func _height_at(x: float, z: float) -> float:
	var distance: float = sqrt(x * x + z * z) / (TERRAIN_SIZE * 0.5)
	var falloff: float = maxf(0.0, 1.0 - pow(distance / 0.72, 2.5))
	var noise: float = (sin(x * 0.045) * cos(z * 0.045) * 3.2
		+ sin(x * 0.1 + 1.3) * cos(z * 0.085) * 1.3
		+ sin(x * 0.21) * cos(z * 0.19) * 0.35)
	return noise * falloff * 0.6 + 7.0 * falloff - 2.2


func _terrain_color(y: float) -> Color:
	if y < 0.6:
		return Color(0.88, 0.80, 0.60)
	if y < 4.4:
		return Color(0.31, 0.67, 0.33)
	return Color(0.48, 0.60, 0.44)


func _append_ground_vertex(surface: SurfaceTool, x: float, z: float) -> void:
	var h: float = _height_at(x, z)
	surface.set_color(_terrain_color(h))
	surface.add_vertex(Vector3(x, h, z))


func _create_land() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = TERRAIN_SIZE / float(TERRAIN_STEPS)
	for zi in range(TERRAIN_STEPS):
		for xi in range(TERRAIN_STEPS):
			var x: float = -TERRAIN_SIZE * 0.5 + xi * step
			var z: float = -TERRAIN_SIZE * 0.5 + zi * step
			_append_ground_vertex(surface, x, z)
			_append_ground_vertex(surface, x + step, z + step)
			_append_ground_vertex(surface, x + step, z)
			_append_ground_vertex(surface, x, z)
			_append_ground_vertex(surface, x, z + step)
			_append_ground_vertex(surface, x + step, z + step)
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.name = "Ile_procedurale"
	terrain.mesh = surface.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = m
	add_child(terrain)


func _create_water() -> void:
	var sea := MeshInstance3D.new()
	sea.name = "Ocean"
	var plane := PlaneMesh.new()
	plane.size = Vector2(700.0, 700.0)
	sea.mesh = plane
	sea.position.y = -0.42
	var ocean_material := StandardMaterial3D.new()
	ocean_material.albedo_color = Color(0.22, 0.67, 0.83)
	ocean_material.metallic = 0.12
	ocean_material.roughness = 0.29
	sea.material_override = ocean_material
	add_child(sea)


func _create_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.17, 0.42, 0.89)
	sky_mat.sky_horizon_color = Color(0.78, 0.90, 0.99)
	sky_mat.ground_bottom_color = Color(0.16, 0.36, 0.49)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, -20)
	sun.light_color = Color(1.0, 0.95, 0.82)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.94
	return m


func _make_box(name: String, pos: Vector3, sz: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = sz
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = pos
	add_child(instance)


func _make_tree(x: float, z: float) -> void:
	var y: float = _height_at(x, z)
	_make_box("Tronc", Vector3(x, y + 1.1, z), Vector3(0.5, 2.2, 0.5), Color(0.41, 0.26, 0.13))
	var cone := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = 1.7
	shape.height = 3.6
	cone.mesh = shape
	cone.material_override = _material(Color(0.24, 0.65, 0.40))
	cone.position = Vector3(x, y + 3.3, z)
	add_child(cone)


func _create_village() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8142026
	for i in range(26):
		var x: float = rng.randf_range(-68, 68)
		var z: float = rng.randf_range(-68, 68)
		var y: float = _height_at(x, z)
		if y < 0.6 or y > 7.0 or Vector2(x, z - 4.0).length() < 17.0:
			continue
		_make_tree(x, z)
	# Feu de camp au centre du village, conservé sans importer le très lourd GLB.
	var camp_y: float = _height_at(0, 4)
	_make_box("Foyer", Vector3(0, camp_y + 0.12, 4), Vector3(2, 0.24, 2), Color(0.45, 0.30, 0.18))
	var fire := OmniLight3D.new()
	fire.light_color = Color(1, 0.45, 0.20)
	fire.light_energy = 1.1
	fire.omni_range = 10
	fire.position = Vector3(0, camp_y + 1.0, 4)
	add_child(fire)
	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.48
	flame_mesh.height = 1.15
	flame.mesh = flame_mesh
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.52, 0.11)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.25, 0.04)
	flame.material_override = flame_mat
	flame.position = Vector3(0, camp_y + 0.85, 4)
	add_child(flame)
	var sign := Label3D.new()
	sign.text = "ILE MANGA  |  VILLAGE"
	sign.font_size = 50
	sign.pixel_size = 0.008
	sign.modulate = Color(0.98, 0.94, 0.75)
	sign.position = Vector3(0, camp_y + 4.3, 4)
	add_child(sign)


func _add_glb(resource_file: String, model_name: String, world_pos: Vector3, scale_factor: float, angle: float) -> Node3D:
	if not ResourceLoader.exists(resource_file):
		push_warning("Modèle absent (optionnel) : " + resource_file)
		return null
	var packed: PackedScene = load(resource_file) as PackedScene
	if packed == null:
		push_warning("Import GLB indisponible : " + resource_file)
		return null
	var instance: Node = packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return null
	var root: Node3D = instance as Node3D
	root.name = model_name
	root.position = world_pos
	root.scale = Vector3.ONE * scale_factor
	root.rotation.y = angle
	add_child(root)
	return root


func _create_structures() -> void:
	var home := _add_glb("res://assets/models/buildings/Maison.glb", "Maison_village", Vector3(9, _height_at(9, 4) + 3.6, 4), 4.5, -PI * 0.5)
	if home == null:
		_make_box("Maison_refuge", Vector3(9, _height_at(9, 4) + 2, 4), Vector3(7, 4, 7), Color(0.83, 0.54, 0.45))
	_add_glb("res://assets/models/buildings/Petite_maison.glb", "Petite_maison", Vector3(-11, _height_at(-11, 9) + 2.244, 9), 3.0, PI * 0.5)
	_add_glb("res://assets/models/buildings/Ile_flottante.glb", "Ile_celeste", Vector3(20, 18, -15), 12, 0.0)
	# Le district plage / mur de son sera repris à la prochaine étape.


func _create_players() -> void:
	xr_origin = XROrigin3D.new()
	xr_origin.name = "Joueur_VR"
	xr_origin.position = Vector3(2, maxf(0.0, _height_at(2, 8)), 8)
	add_child(xr_origin)
	xr_camera = XRCamera3D.new()
	xr_camera.name = "Tete"
	xr_origin.add_child(xr_camera)
	left_hand = XRController3D.new()
	left_hand.name = "Main_gauche"
	left_hand.tracker = "left_hand"
	left_hand.pose = "grip"
	xr_origin.add_child(left_hand)
	right_hand = XRController3D.new()
	right_hand.name = "Main_droite"
	right_hand.tracker = "right_hand"
	right_hand.pose = "grip"
	xr_origin.add_child(right_hand)
	_make_hand(left_hand, Color(0.29, 0.80, 1.0))
	_make_hand(right_hand, Color(1.0, 0.61, 0.34))

	pc_root = Node3D.new()
	pc_root.name = "Joueur_ecran"
	pc_root.position = xr_origin.position
	add_child(pc_root)
	pc_camera = Camera3D.new()
	pc_camera.position = Vector3(0, 2.5, 5)
	pc_root.add_child(pc_camera)
	pc_camera.look_at(pc_root.global_position + Vector3(0, 1.2, 0))
	pc_camera.current = true
	pc_hero = _add_glb("res://assets/models/characters/hero.glb", "Heros_PC", pc_root.position, 1.0, 0.0)

	var hud := CanvasLayer.new()
	add_child(hud)
	info = Label.new()
	info.text = "ÎLE MANGA PC VR  |  ZQSD pour marcher  •  clic droit + souris : caméra  •  Échap : quitter"
	info.add_theme_font_size_override("font_size", 17)
	info.position = Vector2(20, 20)
	hud.add_child(info)
	message = Label.new()
	message.position = Vector2(20, 58)
	message.add_theme_font_size_override("font_size", 18)
	hud.add_child(message)


func _make_hand(controller: XRController3D, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Manette_visible"
	var box := BoxMesh.new()
	box.size = Vector3(0.075, 0.10, 0.18)
	mesh.mesh = box
	mesh.material_override = _material(color)
	mesh.position.z = -0.06
	controller.add_child(mesh)


func _init_native_xr() -> void:
	native_vr = XRServer.find_interface("OpenXR")
	if native_vr != null:
		if not native_vr.is_initialized():
			native_vr.initialize()
		xr_active = native_vr.is_initialized()
	if xr_active:
		XRServer.primary_interface = native_vr
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		pc_camera.current = false
		pc_root.visible = false
		if pc_hero != null:
			pc_hero.visible = false
		xr_camera.current = true
		info.visible = false
		message.visible = false
	else:
		get_viewport().use_xr = false
		pc_camera.current = true
		left_hand.visible = false
		right_hand.visible = false


func _update_status() -> void:
	if xr_active:
		message.text = "OpenXR connecté — Meta Quest Link / SteamVR"
	else:
		message.text = "Mode écran : connecte le Quest 3 via Meta Link ou SteamVR puis relance le jeu pour activer OpenXR."
	print("ILE_MANGA_NATIVE_STATUS: ", message.text)


func _process(delta: float) -> void:
	if xr_active:
		_move_xr(delta)
	else:
		_move_desktop(delta)


func _move_xr(delta: float) -> void:
	var stick: Vector2 = left_hand.get_vector2("primary")
	if stick.length() > DEADZONE:
		var forward: Vector3 = -xr_camera.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right: Vector3 = xr_camera.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		var move: Vector3 = (right * stick.x - forward * stick.y)
		_move_player(xr_origin, move * minf(stick.length(), 1.0) * WALK_SPEED * delta)
	var turn: float = right_hand.get_vector2("primary").x
	if absf(turn) < 0.35:
		turn_ready = true
	elif absf(turn) > TURN_STICK_THRESHOLD and turn_ready:
		xr_origin.rotate_y(-signf(turn) * SNAP_TURN)
		turn_ready = false


func _move_desktop(delta: float) -> void:
	var axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		axis.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		axis.y += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis.x += 1.0
	if axis.length() > 0.0:
		axis = axis.normalized()
		var direction: Vector3 = pc_root.global_basis.x * axis.x + pc_root.global_basis.z * axis.y
		_move_player(pc_root, direction * WALK_SPEED * delta)
		if pc_hero != null:
			pc_hero.position = pc_root.position


func _move_player(origin: Node3D, offset: Vector3) -> void:
	origin.position.x = clampf(origin.position.x + offset.x, -72.0, 72.0)
	origin.position.z = clampf(origin.position.z + offset.z, -72.0, 72.0)
	origin.position.y = maxf(0.0, _height_at(origin.position.x, origin.position.z))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
	if not xr_active and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pc_root.rotate_y(-event.relative.x * 0.005)

extends Node3D
## Île Manga V4 : exports séparés Quest 3 OpenXR et PC normal.
## Les coordonnées du monde viennent du prototype Babylon.js existant.
## Les contrôles XR utilisent l'action map OpenXR par défaut de Godot.

const TERRAIN_SIZE: float = 200.0
const TERRAIN_STEPS: int = 160
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
var ocean: MeshInstance3D
var ocean_material: ShaderMaterial
var xr_restart_button: Button


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
	terrain.name = "Ile_terrain_texture"
	terrain.mesh = surface.commit()
	var shader: Shader = load("res://shaders/terrain.gdshader")
	if shader != null:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("sand_tex", load("res://assets/textures/terrain/sand.jpg"))
		m.set_shader_parameter("grass_tex", load("res://assets/textures/terrain/grass.jpg"))
		m.set_shader_parameter("stone_tex", load("res://assets/textures/terrain/stone.jpg"))
		terrain.material_override = m
	else:
		var fallback := StandardMaterial3D.new()
		fallback.vertex_color_use_as_albedo = true
		terrain.material_override = fallback
	add_child(terrain)


func _create_water() -> void:
	ocean = MeshInstance3D.new()
	ocean.name = "Ocean_anime"
	var plane := PlaneMesh.new()
	plane.size = Vector2(700.0, 700.0)
	ocean.mesh = plane
	ocean.position.y = -0.42
	var shader: Shader = load("res://shaders/water.gdshader")
	if shader != null:
		ocean_material = ShaderMaterial.new()
		ocean_material.shader = shader
		ocean_material.set_shader_parameter("water_tex", load("res://assets/textures/water/water.jpg"))
		ocean.material_override = ocean_material
	else:
		ocean.material_override = _material(Color(0.24, 0.65, 0.83))
	add_child(ocean)


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


func _make_tree(x: float, z: float, seed: int) -> void:
	var y: float = _height_at(x, z)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var height: float = rng.randf_range(2.2, 3.5)
	var trunk := MeshInstance3D.new()
	trunk.name = "Tronc_arbre"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.22
	cylinder.bottom_radius = 0.34
	cylinder.height = height
	trunk.mesh = cylinder
	trunk.material_override = _material(Color(0.37, 0.24, 0.14))
	trunk.position = Vector3(x, y + height * 0.5, z)
	add_child(trunk)
	# Trois couronnes rondes au lieu des anciens sapins triangulaires.
	# Les volumes évitent l'effet décor de démonstration de la V2.
	for i in range(3):
		var leaf := MeshInstance3D.new()
		leaf.name = "Feuillage_anime"
		var sphere := SphereMesh.new()
		sphere.radius = 1.55 - i * 0.16
		sphere.height = sphere.radius * 1.7
		sphere.radial_segments = 10
		sphere.rings = 5
		leaf.mesh = sphere
		leaf.material_override = _material(Color(0.21 + 0.03 * float(i), 0.51 + 0.04 * float(i), 0.27))
		leaf.position = Vector3(x + rng.randf_range(-0.45, 0.45), y + height + float(i) * 0.45, z + rng.randf_range(-0.4, 0.4))
		add_child(leaf)


func _create_village() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8142026
	var trees_placed := 0
	for i in range(115):
		if trees_placed >= 34:
			break
		var x: float = rng.randf_range(-71, 71)
		var z: float = rng.randf_range(-71, 71)
		var y: float = _height_at(x, z)
		if y < 0.8 or y > 7.0 or Vector2(x, z - 4.0).length() < 17.0:
			continue
		_make_tree(x, z, i + 14001)
		trees_placed += 1
	var camp_y: float = _height_at(0.0, 4.0)
	# Le GLB du vrai feu remplace le simple cube de la V2.
	var camp := _add_glb("res://assets/models/props/Feu.glb", "Feu_camp_original", Vector3(0.0, camp_y + 1.04, 4.0), 1.2, 0.0)
	if camp == null:
		_make_box("Foyer_secours", Vector3(0, camp_y + 0.12, 4), Vector3(2, 0.24, 2), Color(0.45, 0.30, 0.18))
	var fire := OmniLight3D.new()
	fire.light_color = Color(1, 0.45, 0.20)
	fire.light_energy = 1.4
	fire.omni_range = 13
	fire.position = Vector3(0, camp_y + 1.0, 4)
	add_child(fire)
	var flame := MeshInstance3D.new()
	flame.name = "Flamme_lumineuse"
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.36
	flame_mesh.height = 0.85
	flame.mesh = flame_mesh
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.45, 0.08)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.28, 0.04)
	flame.material_override = flame_mat
	flame.position = Vector3(0, camp_y + 1.0, 4)
	add_child(flame)
	var sign := Label3D.new()
	sign.text = "Bienvenue sur Île Manga"
	sign.font_size = 48
	sign.pixel_size = 0.003
	sign.modulate = Color(0.98, 0.95, 0.78)
	sign.position = Vector3(-2, camp_y + 2.2, 4)
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
	# Quartier de la plage DJ : éléments originaux Babylon.js réintroduits.
	_add_glb("res://assets/models/props/Mur_de_son.glb", "Mur_de_son", Vector3(0, _height_at(0, 60) + 3.75, 60), 6, PI)
	_add_glb("res://assets/models/props/Table_de_mixage.glb", "Table_de_mixage", Vector3(9, _height_at(9, 60) + 0.988, 60), 2.5, PI)
	_add_glb("res://assets/models/props/Distributeur_8_6.glb", "Distributeur_8_6", Vector3(-9, _height_at(-9, 60) + 1.712, 60), 1.8, PI)
	_add_glb("res://assets/models/props/Corde.glb", "Corde", Vector3(16, 10, -9), 6.0, 0.0)


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
	info.text = "ÎLE MANGA VR V4  |  ZQSD : marcher  •  clic droit : caméra  •  R : relancer la VR  •  Échap : quitter"
	info.add_theme_font_size_override("font_size", 16)
	info.position = Vector2(20, 20)
	hud.add_child(info)
	message = Label.new()
	message.position = Vector2(20, 54)
	message.add_theme_font_size_override("font_size", 18)
	hud.add_child(message)
	xr_restart_button = Button.new()
	xr_restart_button.text = "Reconnecter le Quest 3 (redémarrer le jeu)"
	xr_restart_button.position = Vector2(20, 108)
	xr_restart_button.pressed.connect(_restart_xr)
	hud.add_child(xr_restart_button)


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
	# La version PC classique NE doit jamais utiliser la caméra du casque.
	# Un second export désactive également OpenXR dans project.godot.
	if OS.has_feature("ile_manga_pc"):
		xr_active = false
		native_vr = null
		get_viewport().use_xr = false
		pc_camera.current = true
		xr_camera.current = false
		left_hand.visible = false
		right_hand.visible = false
		xr_restart_button.visible = false
		print("ILE_MANGA_MODE: PC_CLASSIQUE")
		return
	# OpenXR/Vulkan initialise la connexion au démarrage du processus Godot.
	# Impossible de garantir une reconnexion au casque sans redémarrer le jeu.
	native_vr = XRServer.find_interface("OpenXR")
	xr_active = native_vr != null and native_vr.is_initialized()
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
		xr_restart_button.visible = false
		print("ILE_MANGA_OPENXR: SESSION_OK, interface=", native_vr.get_name())
	else:
		get_viewport().use_xr = false
		pc_camera.current = true
		left_hand.visible = false
		right_hand.visible = false
		xr_restart_button.visible = true
		push_warning("ILE_MANGA_OPENXR: non initialise au lancement ; controler Meta Link / SteamVR avant de demarrer")


func _update_status() -> void:
	if OS.has_feature("ile_manga_pc"):
		info.text = "ÎLE MANGA PC V4  |  ZQSD : marcher  •  clic droit : caméra  •  Échap : quitter"
		message.text = "Mode PC classique — aucun casque VR nécessaire."
		print("ILE_MANGA_NATIVE_STATUS: ", message.text)
		return
	if xr_active:
		message.text = "OpenXR actif : Quest Link / SteamVR"
	elif native_vr == null:
		message.text = "OpenXR absent. Relance en activant Meta Quest Link ou SteamVR."
	else:
		message.text = "OpenXR non connecté. Entre d'abord dans Quest Link sur le casque, puis presse R."
	print("ILE_MANGA_NATIVE_STATUS: ", message.text)


func _restart_xr() -> void:
	if xr_active:
		return
	var pid: int = OS.create_instance(PackedStringArray())
	if pid > 0:
		get_tree().quit()
	else:
		message.text = "Redémarrage impossible : ferme l'application et relance l'EXE après Quest Link."


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
		# Axe Quest 3 : pousser le stick vers l’avant = direction de la tête.
		var move: Vector3 = (right * stick.x + forward * stick.y)
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
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_R and not xr_active:
			_restart_xr()
	if not xr_active and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pc_root.rotate_y(-event.relative.x * 0.005)

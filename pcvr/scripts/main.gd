extends Node3D
const SaveStore = preload("res://scripts/save_manager.gd")
## Île Manga V8 : hameau détail, bordures végétales et sentiers — contrôles VR inchangés.
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
var ultranet_pc: bool = false
var game_menu: Node
var menu_panorama: Camera3D
var panorama_seconds: float = 0.0
var menu_panorama: Camera3D
var panorama_seconds: float = 0.0
var menu_panorama: Camera3D
var panorama_seconds: float = 0.0
var menu_panorama: Camera3D
var panorama_seconds: float = 0.0
var autosave_clock: float = 0.0
var game_started: bool = false


func _ready() -> void:
	_configure_quality()
	_create_lighting()
	_create_land()
	_create_water()
	_create_village()
	_create_ground_details()
	_create_scenery_v6()
	_create_village_details_v7()
	_create_structures()
	_create_players()
	_init_native_xr()
	_update_status()
	_create_game_menu_v8()
	print("ILE_MANGA_NATIVE: scene construite; OpenXR actif = ", xr_active)


# Profils distincts : rendu haute définition sur PC, charge VR maîtrisée.
func _configure_quality() -> void:
	if OS.has_feature("ile_manga_pc"):
		get_viewport().msaa_3d = Viewport.MSAA_4X
		get_viewport().scaling_3d_scale = 1.0
		print("ILE_MANGA_V6: PC NATIF, MSAA 4x, resolution ecran native")
	else:
		get_viewport().msaa_3d = Viewport.MSAA_2X
		print("ILE_MANGA_V6: VR, MSAA 2x, resolution geree par Quest Link / OpenXR")


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
		m.set_shader_parameter("extra_detail", OS.has_feature("ile_manga_pc"))
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
	# Davantage de sommets pour les ondulations réelles de l'eau.
	plane.subdivide_width = 64 if OS.has_feature("ile_manga_pc") else 40
	plane.subdivide_depth = 64 if OS.has_feature("ile_manga_pc") else 40
	ocean.mesh = plane
	ocean.position.y = -0.42
	var shader: Shader = load("res://shaders/water.gdshader")
	if shader != null:
		ocean_material = ShaderMaterial.new()
		ocean_material.shader = shader
		ocean_material.set_shader_parameter("water_tex", load("res://assets/textures/water/water.jpg"))
		ocean_material.set_shader_parameter("wave_strength", 1.0 if OS.has_feature("ile_manga_pc") else 0.65)
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
	# Brume aérienne très légère : le paysage garde son contraste de près.
	env.fog_enabled = true
	env.fog_light_color = Color(0.73, 0.84, 0.93)
	env.fog_density = 0.0015
	# Les effets coûteux restent réservés au PC sans casque.
	if OS.has_feature("ile_manga_pc"):
		env.ssao_enabled = true
		env.ssil_enabled = true
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.04
		env.adjustment_saturation = 1.07
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, -20)
	sun.light_color = Color(1.0, 0.95, 0.82)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if OS.has_feature("ile_manga_pc") else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 135.0 if OS.has_feature("ile_manga_pc") else 85.0
	sun.directional_shadow_blend_splits = OS.has_feature("ile_manga_pc")
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


# Brins d'herbe distribués par MultiMesh (un lot, pas des milliers de draw calls).
# Plus dense en mode PC ; parcimonieux en VR pour préserver le framerate.
func _create_ground_details() -> void:
	var target_count: int = 2700 if OS.has_feature("ile_manga_pc") else 850
	var rng := RandomNumberGenerator.new()
	rng.seed = 5012026
	var tuft_mesh := QuadMesh.new()
	tuft_mesh.size = Vector2(0.24, 0.54)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.27, 0.61, 0.25)
	leaf_mat.roughness = 1.0
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tuft_mesh.material = leaf_mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tuft_mesh
	mm.instance_count = target_count
	var placed: int = 0
	for trial in range(target_count * 6):
		if placed >= target_count:
			break
		var x: float = rng.randf_range(-72.0, 72.0)
		var z: float = rng.randf_range(-72.0, 72.0)
		var y: float = _height_at(x, z)
		if y < 1.2 or y > 5.7 or Vector2(x, z - 4.0).length() < 12.0:
			continue
		if Vector2(x - 9.0, z - 4.0).length() < 8.0 or Vector2(x + 11.0, z - 9.0).length() < 6.0:
			continue
		var scale_value: float = rng.randf_range(0.65, 1.6)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(scale_value, scale_value, scale_value))
		var transform := Transform3D(basis, Vector3(x, y + scale_value * 0.25, z))
		mm.set_instance_transform(placed, transform)
		mm.set_instance_color(placed, Color(rng.randf_range(0.84, 1.16), rng.randf_range(0.86, 1.12), rng.randf_range(0.79, 1.08)))
		placed += 1
	mm.visible_instance_count = placed
	var patch := MultiMeshInstance3D.new()
	patch.name = "Herbes_multimesh"
	patch.multimesh = mm
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	patch.visibility_range_end = 85.0 if OS.has_feature("ile_manga_pc") else 55.0
	add_child(patch)
	print("ILE_MANGA_V6: touffes herbe instanciees = ", placed)



# V6 — Décors naturels : instancing pour éviter un nombre élevé de draw calls.
# Tous les éléments sont purement visuels : aucun changement des contrôles VR.
func _scatter_v6(name: String, mesh: Mesh, tint: Color, amount: int, category: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.96
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = amount
	var placed := 0
	for trial in range(amount * 14):
		if placed >= amount:
			break
		var x := rng.randf_range(-78.0, 78.0)
		var z := rng.randf_range(-78.0, 78.0)
		var y := _height_at(x, z)
		var village_dist := Vector2(x, z - 4.0).length()
		if category == 0 and (y < 1.3 or y > 6.7 or village_dist < 12.0):
			continue # forêt : buissons
		if category == 1 and (y < 0.8 or y > 5.8 or village_dist < 8.0):
			continue # fleurs
		if category == 2 and (y < -0.35 or y > 1.55 or village_dist < 9.0):
			continue # pierres de plage
		if category == 3 and (y < 0.5 or y > 5.7 or village_dist > 22.0):
			continue # pierres/galets du village
		if Vector2(x - 9.0, z - 4.0).length() < 7.0 or Vector2(x + 11.0, z - 9.0).length() < 6.0:
			continue
		var size := rng.randf_range(0.7, 1.45)
		var scale_vec := Vector3(size, size * rng.randf_range(0.7, 1.3), size)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(scale_vec)
		batch.set_instance_transform(placed, Transform3D(basis, Vector3(x, y + 0.08, z)))
		batch.set_instance_color(placed, Color(rng.randf_range(0.85, 1.12), rng.randf_range(0.85, 1.12), rng.randf_range(0.85, 1.12), 1.0))
		placed += 1
	batch.visible_instance_count = placed
	var item := MultiMeshInstance3D.new()
	item.name = name
	item.multimesh = batch
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item.visibility_range_end = 100.0 if OS.has_feature("ile_manga_pc") else 65.0
	add_child(item)
	print("ILE_MANGA_V6: ", name, "=", placed)


func _create_scenery_v6() -> void:
	var high_quality := OS.has_feature("ile_manga_pc")
	# Petits feuillages. Le maillage est partagé par toutes les instances.
	var shrub := SphereMesh.new()
	shrub.radius = 0.75
	shrub.height = 1.05
	shrub.radial_segments = 8
	shrub.rings = 4
	_scatter_v6("Buissons_v6", shrub, Color(0.20, 0.48, 0.24), 520 if high_quality else 260, 0, 62131)

	# Fleurs colorées (3 lots) en maillages légers, espacées dans les prairies.
	for i in range(3):
		var flower := SphereMesh.new()
		flower.radius = 0.12
		flower.height = 0.28
		flower.radial_segments = 6
		flower.rings = 3
		var palette := [Color(0.96, 0.55, 0.68), Color(0.98, 0.85, 0.34), Color(0.70, 0.62, 0.96)]
		_scatter_v6("Fleurs_v6_" + str(i), flower, palette[i], 330 if high_quality else 130, 1, 71711 + i * 127)

	var pebble := SphereMesh.new()
	pebble.radius = 0.42
	pebble.height = 0.32
	pebble.radial_segments = 8
	pebble.rings = 4
	_scatter_v6("Galets_plage_v6", pebble, Color(0.72, 0.68, 0.58), 280 if high_quality else 130, 2, 89111)
	var pebble_path := SphereMesh.new()
	pebble_path.radius = 0.23
	pebble_path.height = 0.095
	pebble_path.radial_segments = 8
	pebble_path.rings = 3
	_scatter_v6("Pierres_village_v6", pebble_path, Color(0.59, 0.55, 0.45), 240 if high_quality else 110, 3, 92231)

	# Sentier entre feu central et maisons : pierres affleurantes, sans collision.
	var slab := CylinderMesh.new()
	slab.top_radius = 0.53
	slab.bottom_radius = 0.59
	slab.height = 0.07
	var path_material := _material(Color(0.73, 0.67, 0.54))
	for j in range(18):
		var t := float(j) / 17.0
		var px := lerpf(0.0, 9.0, t)
		var pz := 4.0 + 0.4 * sin(t * PI)
		var step_stone := MeshInstance3D.new()
		step_stone.name = "Sentier_village_v6"
		step_stone.mesh = slab
		step_stone.material_override = path_material
		step_stone.position = Vector3(px, _height_at(px, pz) + 0.04, pz)
		step_stone.scale = Vector3(1.0, 1.0, 0.65)
		step_stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(step_stone)

	# Lanternes au village : lumière chaude réservée à quelques points.
	var wood := _material(Color(0.28, 0.20, 0.13))
	var amber := StandardMaterial3D.new()
	amber.albedo_color = Color(1.0, 0.78, 0.39)
	amber.emission_enabled = true
	amber.emission = Color(1.0, 0.52, 0.16)
	amber.emission_energy_multiplier = 1.8
	for coord in [Vector2(4.0, 8.0), Vector2(-6.0, 7.0), Vector2(6.0, -1.0), Vector2(-4.0, -3.0)]:
		var h := _height_at(coord.x, coord.y)
		var pole := MeshInstance3D.new()
		pole.name = "Lanterne_poteau_v6"
		var rod := CylinderMesh.new()
		rod.top_radius = 0.08
		rod.bottom_radius = 0.12
		rod.height = 2.1
		pole.mesh = rod
		pole.material_override = wood
		pole.position = Vector3(coord.x, h + 1.05, coord.y)
		add_child(pole)
		var bulb := MeshInstance3D.new()
		bulb.name = "Lanterne_chaude_v6"
		var orb := SphereMesh.new()
		orb.radius = 0.20
		orb.height = 0.40
		bulb.mesh = orb
		bulb.material_override = amber
		bulb.position = Vector3(coord.x, h + 2.22, coord.y)
		add_child(bulb)
		if high_quality:
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.72, 0.42)
			light.light_energy = 0.30
			light.omni_range = 5.0
			light.shadow_enabled = false
			light.position = bulb.position
			add_child(light)

# Décors V7 séparés du gameplay pour ne pas toucher à OpenXR/aux contrôles.
func _create_village_details_v7() -> void:
	var details := preload("res://scripts/village_details.gd").new()
	details.name = "Village_detail_v7"
	add_child(details)
	details.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


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
	info.text = "ÎLE MANGA VR V6  |  ZQSD : marcher  •  clic droit : caméra  •  R : relancer la VR  •  Échap : quitter"
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
		info.text = "ÎLE MANGA PC V6  |  ZQSD : marcher  •  clic droit : caméra  •  Échap : quitter"
		message.text = "Mode PC classique — F11 plein écran • F6 netteté ultra (GPU) • aucun casque requis."
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


func _create_game_menu_v8() -> void:
	game_menu = preload("res://scripts/menu_v8.gd").new()
	add_child(game_menu)
	game_menu.start_slot.connect(_start_save_slot)
	game_menu.save_requested.connect(_save_slot)
	game_menu.delete_requested.connect(_delete_slot)
	game_menu.resume_requested.connect(func(): pass)
	game_menu.setup(xr_active, xr_camera, right_hand)
	# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
	if OS.has_feature("ile_manga_pc"):
		menu_panorama = Camera3D.new()
		menu_panorama.name = "Panorama_menu_V10"
		menu_panorama.fov = 66.0
		add_child(menu_panorama)
		menu_panorama.position = Vector3(-26.0, 17.0, 35.0)
		menu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
		menu_panorama.current = true
	# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
	if OS.has_feature("ile_manga_pc"):
		menu_panorama = Camera3D.new()
		menu_panorama.name = "Panorama_menu_V10"
		menu_panorama.fov = 66.0
		add_child(menu_panorama)
		menu_panorama.position = Vector3(-26.0, 17.0, 35.0)
		menu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
		menu_panorama.current = true
	# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
	if OS.has_feature("ile_manga_pc"):
		menu_panorama = Camera3D.new()
		menu_panorama.name = "Panorama_menu_V10"
		menu_panorama.fov = 66.0
		add_child(menu_panorama)
		menu_panorama.position = Vector3(-26.0, 17.0, 35.0)
		menu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
		menu_panorama.current = true
	# Caméra cinématique PC indépendante du joueur. En VR le monde reste stable.
	if OS.has_feature("ile_manga_pc"):
		menu_panorama = Camera3D.new()
		menu_panorama.name = "Panorama_menu_V10"
		menu_panorama.fov = 66.0
		add_child(menu_panorama)
		menu_panorama.position = Vector3(-26.0, 17.0, 35.0)
		menu_panorama.look_at(Vector3(0, 4, 0), Vector3.UP)
		menu_panorama.current = true


func _start_save_slot(slot: int, new_game: bool) -> void:
	game_started = true
	var origin: Node3D = xr_origin if xr_active else pc_root
	if new_game:
		origin.position = Vector3(2.0, maxf(0.0, _height_at(2.0, 8.0)), 8.0)
		origin.rotation.y = 0.0
		game_menu.seconds = 0.0
		_save_slot(slot)
	else:
		var data: Dictionary = SaveStore.read_slot(slot)
		var a: Array = data.get("position", [])
		if a.size() == 3:
			origin.position = Vector3(float(a[0]), float(a[1]), float(a[2]))
		origin.rotation.y = float(data.get("yaw", 0.0))
		game_menu.seconds = float(data.get("play_seconds", 0.0))
	if not xr_active and pc_hero != null:
		pc_hero.position = origin.position
		pc_hero.rotation.y = origin.rotation.y
	autosave_clock = 0.0


func _delete_slot(slot: int) -> void:
	print("ILE_MANGA_DELETE: ", slot, " = ", SaveStore.delete_slot(slot))


func _save_slot(slot: int) -> void:
	if not game_started:
		return
	var origin: Node3D = xr_origin if xr_active else pc_root
	var ok: bool = SaveStore.write_slot(slot, origin.position, origin.rotation.y, game_menu.seconds)
	print("ILE_MANGA_SAVE: ", slot, " = ", ok)


func _process(delta: float) -> void:
	# Défilement contemplatif seulement pendant un menu PC.
	if menu_panorama != null and game_menu != null:
		if game_menu.opened:
			panorama_seconds += delta
			var angle: float = panorama_seconds * 0.055
			menu_panorama.position = Vector3(-26.0 + sin(angle) * 6.0, 16.5 + sin(angle * 1.3) * 1.2, 33.0 + cos(angle) * 4.0)
			menu_panorama.look_at(Vector3(0, 4.5, 0), Vector3.UP)
			if not menu_panorama.current:
				menu_panorama.current = true
		elif menu_panorama.current:
			pc_camera.current = true
	if game_menu != null and xr_active and game_started and not game_menu.opened and right_hand.get_float("menu_button") > 0.8:
		game_menu.open_menu()
	if game_menu != null and (game_menu.opened or not game_started):
		return
	autosave_clock += delta
	if autosave_clock >= 90.0:
		_save_slot(0)
		autosave_clock = 0.0
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
			if game_menu != null:
				if game_menu.opened and game_started:
					game_menu._close()
				else:
					game_menu.open_menu()
			else:
				get_tree().quit()
		elif event.keycode == KEY_F5 and game_started:
			_save_slot(game_menu.active_slot)
		elif event.keycode == KEY_F9 and game_started:
			game_menu.open_menu()
		elif OS.has_feature("ile_manga_pc") and event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		elif OS.has_feature("ile_manga_pc") and event.keycode == KEY_F6:
			ultranet_pc = not ultranet_pc
			get_viewport().scaling_3d_scale = 1.2 if ultranet_pc else 1.0
			print("ILE_MANGA_V6: suréchantillonnage PC = ", get_viewport().scaling_3d_scale)
		elif event.keycode == KEY_R and not xr_active and not OS.has_feature("ile_manga_pc"):
			_restart_xr()
	if not xr_active and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pc_root.rotate_y(-event.relative.x * 0.005)

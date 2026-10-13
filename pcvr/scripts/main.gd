extends Node3D
const SaveStore = preload("res://scripts/save_manager.gd")
const Flora = preload("res://scripts/flora_v25.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const Falls = preload("res://scripts/scenery_v13.gd")
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
var hero_mesh_floor_offset_v11: float = 0.0
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
var autosave_clock: float = 0.0
var game_started: bool = false
var camp_light_v24: OmniLight3D
var houses_v27: Node3D
var door_prompt_v27: Label
var trigger_ready_v27: bool = true
var fire_clock_v24: float = 0.0
# V28 : héros animé, inventaire, combat.
var hero_v28: Node
var inventory_v28: Node3D
var combat_v28: Node3D
var hud_v28: CanvasLayer
var vr_buttons_v28: Dictionary = {}
var message_clock_v28: float = 0.0
const JUMP_SPEED_V28: float = 6.6
# V29 : deuxième île (jungle) et bateau.
var jungle_v29: Node3D
var boat_v29: Node3D
var last_ok_v29: Dictionary = {}
const ISLAND_DOCK_V29 := [Vector3(0.0, 1.0, -56.5), Vector3(0.0, 1.0, -72.5)]
# ILE_MANGA_PHYSICS_V11 : locomotion par CharacterBody3D et obstacles statiques.
var vr_body: CharacterBody3D
var pc_body: CharacterBody3D
const GRAVITY_V11: float = 18.0
const COLLISION_LAYER_V11: int = 1
# V21 : limite ronde de l'île, au bord de l'eau (au-delà le sol passe sous la mer).
const ISLAND_LIMIT_V21: float = 63.0
# V23 : hauteur de marche franchissable (perron, petites pierres).
const STEP_HEIGHT_V23: float = 0.42
# V27 : emprise au sol des pièces intérieures [x min, x max, z min, z max, plancher]
# (déduites de houses_v27.HOUSES et de la position des maisons).
const ROOMS_V27 := [[8.2, 11.4, 0.7, 7.3, 6.33], [-13.6, -9.55, 6.2, 10.7, 4.05]]



func _ready() -> void:
	_configure_quality()
	_create_lighting()
	_create_land()
	_create_water()
	_create_village()
	_create_ground_details()
	_create_scenery_v6()
	_create_village_details_v7()
	_create_scenery_v12()
	_create_scenery_v13()
	_create_scenery_v15()
	_create_scenery_v16()
	_create_scenery_v17()
	_create_village_v18()
	_create_structures()
	_create_jungle_v29()
	_create_players()
	_build_physical_world_v11()
	_init_native_xr()
	_update_status()
	_create_game_menu_v8()
	_create_gameplay_v28()
	print("ILE_MANGA_NATIVE: scene construite; OpenXR actif = ", xr_active)


# V24 : profils de qualité réglés pour une RTX 4070 ou mieux.
# PC : éclairage global, anticrénelage temporel, ombres 8K très douces.
# VR : même ciel et mêmes matériaux, effets d'écran lourds coupés pour tenir 90 i/s par œil.
func _configure_quality() -> void:
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.mesh_lod_threshold = 0.6
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	if OS.has_feature("ile_manga_pc"):
		vp.use_taa = true
		vp.scaling_3d_scale = 1.0
		RenderingServer.directional_shadow_atlas_set_size(8192, true)
		print("ILE_MANGA_V24: PC ultra, MSAA 4x + TAA, ombres 8192, filtrage ultra")
	else:
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
		print("ILE_MANGA_V24: VR haute qualite, MSAA 4x, ombres 4096")


func _height_at(x: float, z: float) -> float:
	# V29 : la jungle a son propre relief ; ailleurs, celui de l'île du village.
	var h: float = _height_island_v29(x, z)
	if jungle_v29 != null and jungle_v29.contains(x, z):
		return maxf(h, jungle_v29.height(x, z))
	return h


func _height_island_v29(x: float, z: float) -> float:
	# V26 : relief de base, puis bassins des chutes d'eau (seulement à proximité).
	var land: float = _base_height_v26(x, z)
	# V27 : sous les pièces des maisons, le terrain passe sous le plancher (pas d'herbe qui perce).
	for room in ROOMS_V27:
		if x > room[0] and x < room[1] and z > room[2] and z < room[3]:
			land = minf(land, room[4] - 0.15)
	if Falls.near_pool(x, z):
		return Falls.carve(x, z, land, Callable(self, "_base_height_v26"))
	return land


func _base_height_v26(x: float, z: float) -> float:
	var distance: float = sqrt(x * x + z * z) / (TERRAIN_SIZE * 0.5)
	var falloff: float = maxf(0.0, 1.0 - pow(distance / 0.72, 2.5))
	var noise: float = (sin(x * 0.045) * cos(z * 0.045) * 3.2
		+ sin(x * 0.1 + 1.3) * cos(z * 0.085) * 1.3
		+ sin(x * 0.21) * cos(z * 0.19) * 0.35)
	var land: float = noise * falloff * 0.6 + 7.0 * falloff - 2.2
	# V24 : au-delà du rivage, le fond descend vers le large (hors de la zone jouable).
	var r: float = sqrt(x * x + z * z)
	if r > 66.0:
		land -= (r - 66.0) * 0.28
	return land


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
	# V24 : maillage indexé de 320 x 320 carreaux (62 cm), normales lisses issues du relief.
	var steps: int = 320
	var step: float = TERRAIN_SIZE / float(steps)
	var count: int = steps + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	verts.resize(count * count)
	normals.resize(count * count)
	uvs.resize(count * count)
	var e: float = 0.25
	for zi in range(count):
		for xi in range(count):
			var x: float = -TERRAIN_SIZE * 0.5 + xi * step
			var z: float = -TERRAIN_SIZE * 0.5 + zi * step
			var i: int = zi * count + xi
			verts[i] = Vector3(x, _height_at(x, z), z)
			normals[i] = Vector3(_height_at(x - e, z) - _height_at(x + e, z), 2.0 * e, _height_at(x, z - e) - _height_at(x, z + e)).normalized()
			uvs[i] = Vector2(x, z) * 0.21
	var indices := PackedInt32Array()
	indices.resize(steps * steps * 6)
	var k: int = 0
	for zi in range(steps):
		for xi in range(steps):
			var a: int = zi * count + xi
			var b: int = a + 1
			var c: int = a + count
			var d: int = c + 1
			# Sens horaire vu du dessus = face visible pour Godot.
			indices[k] = a; indices[k + 1] = b; indices[k + 2] = d
			indices[k + 3] = a; indices[k + 4] = d; indices[k + 5] = c
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain := MeshInstance3D.new()
	terrain.name = "Ile_terrain_texture"
	terrain.mesh = mesh
	var shader: Shader = load("res://shaders/terrain.gdshader")
	if shader != null:
		var m := ShaderMaterial.new()
		m.shader = shader
		for tex in ["sand", "grass", "stone"]:
			m.set_shader_parameter(tex + "_tex", load("res://assets/textures/terrain/" + tex + ".jpg"))
			m.set_shader_parameter(tex + "_n", load("res://assets/textures/terrain/" + tex + "_n.png"))
		m.set_shader_parameter("extra_detail", OS.has_feature("ile_manga_pc"))
		terrain.material_override = m
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.35, 0.6, 0.3)
		terrain.material_override = fallback
	add_child(terrain)
	# Le relief est un corps statique triangulé pour la gravité et les pentes.
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "Sol_collision_v11"
	terrain_body.collision_layer = COLLISION_LAYER_V11
	terrain_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = terrain.mesh.create_trimesh_shape()
	if collision.shape is ConcavePolygonShape3D:
		(collision.shape as ConcavePolygonShape3D).backface_collision = true
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _create_water() -> void:
	ocean = MeshInstance3D.new()
	ocean.name = "Ocean_anime"
	var plane := PlaneMesh.new()
	var ripple: Texture2D = load("res://assets/textures/water/water_n.png")
	if OS.has_feature("ile_manga_pc"):
		# V24 : océan jusqu'à l'horizon, houle réelle, réfraction et profondeur.
		plane.size = Vector2(2400.0, 2400.0)
		plane.subdivide_width = 360
		plane.subdivide_depth = 360
		ocean_material = ShaderMaterial.new()
		ocean_material.shader = load("res://shaders/water_hd.gdshader")
		ocean_material.set_shader_parameter("ripple_n", ripple)
	else:
		plane.size = Vector2(1600.0, 1600.0)
		plane.subdivide_width = 160
		plane.subdivide_depth = 160
		ocean_material = ShaderMaterial.new()
		ocean_material.shader = load("res://shaders/water.gdshader")
		ocean_material.set_shader_parameter("water_tex", load("res://assets/textures/water/water.jpg"))
		ocean_material.set_shader_parameter("ripple_n", ripple)
		ocean_material.set_shader_parameter("wave_strength", 0.8)
	ocean.mesh = plane
	ocean.position.y = -0.42
	ocean.material_override = ocean_material
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ocean)


func _create_lighting() -> void:
	var pc: bool = OS.has_feature("ile_manga_pc")
	var world := WorldEnvironment.new()
	var env := Environment.new()
	# V24 : ciel peint par shader (atmosphère, soleil, nuages qui avancent).
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky_v24.gdshader")
	sky_mat.set_shader_parameter("cloud_octaves", 7 if pc else 5)
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	# Perspective aérienne : les lointains se fondent dans la couleur du ciel.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.66, 0.77, 0.9)
	env.fog_density = 0.0016
	env.fog_aerial_perspective = 0.75
	env.fog_sky_affect = 0.15
	# Occlusion ambiante et lumière rebondie de près : PC et VR (RTX 4070).
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.8
	env.ssao_power = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.15
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.06
	if pc:
		# Éclairage global temps réel : la lumière rebondit sur le sol et les murs.
		env.sdfgi_enabled = true
		env.sdfgi_use_occlusion = true
		env.sdfgi_cascades = 6
		env.sdfgi_min_cell_size = 0.15
		env.sdfgi_energy = 1.0
		env.ssil_enabled = true
		env.ssil_radius = 4.0
		env.ssr_enabled = true
		env.ssr_max_steps = 96
		env.ssr_fade_in = 0.12
		env.ssr_fade_out = 2.0
		# Brume volumétrique légère : rayons de soleil sous les arbres.
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0035
		env.volumetric_fog_albedo = Color(0.86, 0.9, 0.96)
		env.volumetric_fog_length = 96.0
		env.volumetric_fog_gi_inject = 0.6
		env.volumetric_fog_anisotropy = 0.55
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Soleil_v24"
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.35
	sun.light_angular_distance = 0.6
	sun.shadow_enabled = true
	sun.shadow_blur = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 220.0 if pc else 120.0
	sun.directional_shadow_blend_splits = true
	sun.light_volumetric_fog_energy = 1.4
	add_child(sun)


# V22 : un seul matériau par couleur, partagé par tous les objets (moins de travail GPU en VR).
var _materials_v22: Dictionary = {}
var _trunk_mesh_v22: CylinderMesh
var _leaf_meshes_v22: Array[SphereMesh] = []


func _material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if _materials_v22.has(key):
		return _materials_v22[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.94
	_materials_v22[key] = m
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
	# V25 : feuillu réaliste (tronc, charpentières, grappes de feuilles qui bougent au vent).
	var tree := MeshInstance3D.new()
	tree.name = "Arbre_v25"
	var leaves: int = 300 if OS.has_feature("ile_manga_pc") else 190
	tree.mesh = Flora.tree(4100 + seed % 4, 7.0, leaves)
	var s: float = rng.randf_range(0.85, 1.15)
	tree.scale = Vector3(s, s * rng.randf_range(0.92, 1.1), s)
	tree.rotation.y = rng.randf() * TAU
	tree.position = Vector3(x, y - 0.05, z)
	add_child(tree)
	_add_obstacle_cylinder_v11("Tronc_collision", Vector3(x, y + height * 0.5, z), 0.34, height)


# Brins d'herbe distribués par MultiMesh (Herbes_multimesh), découpés en parcelles de 20 m
# pour que la carte graphique ignore celles hors champ ou trop lointaines.
func _create_ground_details() -> void:
	var pc: bool = OS.has_feature("ile_manga_pc")
	var target_count: int = 60000 if pc else 18000
	var chunk: float = 20.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5012026
	var clumps: Array[Mesh] = [Flora.grass_clump(14, 0.34, 0.034, 3), Flora.grass_clump(12, 0.26, 0.03, 5), Flora.grass_clump(16, 0.42, 0.036, 9)]
	var buckets: Dictionary = {}
	var placed: int = 0
	for trial in range(target_count * 4):
		if placed >= target_count:
			break
		var x: float = rng.randf_range(-66.0, 66.0)
		var z: float = rng.randf_range(-66.0, 66.0)
		var y: float = _height_at(x, z)
		if y < 0.9 or y > 6.6 or Falls.occupied(x, z):
			continue
		if Vector2(x - 9.0, z - 4.0).length() < 5.0 or Vector2(x + 11.0, z - 9.0).length() < 4.8 or Vector2(x, z - 4.0).length() < 1.6:
			continue
		# Pas d'herbe sur les sentiers ni dans le foyer ; clairsemée en lisière de plage.
		if _near_path_v25(Vector2(x, z)):
			continue
		if y < 1.4 and rng.randf() < 0.6:
			continue
		var key := Vector3i(int(floor(x / chunk)), rng.randi_range(0, 2), int(floor(z / chunk)))
		if not buckets.has(key):
			buckets[key] = []
		var s: float = rng.randf_range(0.75, 1.2)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s))
		var tint := Color(rng.randf_range(0.82, 1.08), rng.randf_range(0.88, 1.1), rng.randf_range(0.78, 1.0))
		buckets[key].append([Transform3D(basis, Vector3(x, y - 0.02, z)), tint])
		placed += 1
	for key in buckets.keys():
		var items: Array = buckets[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = clumps[key.y]
		mm.instance_count = items.size()
		for i in range(items.size()):
			mm.set_instance_transform(i, items[i][0])
			mm.set_instance_color(i, items[i][1])
		var patch := MultiMeshInstance3D.new()
		patch.name = "Herbes_multimesh_%d_%d_%d" % [key.x, key.y, key.z]
		patch.multimesh = mm
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		patch.visibility_range_end = 85.0 if pc else 48.0
		patch.visibility_range_end_margin = 10.0
		patch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(patch)
	print("ILE_MANGA_V25: touffes d'herbe = ", placed, " en ", buckets.size(), " parcelles")



# V25 : sentiers du village (feu -> grande maison, feu -> petite maison) et foyer dégagés.
func _near_path_v25(p: Vector2) -> bool:
	if p.distance_to(Vector2(0.0, 4.0)) < 2.6:
		return true
	for seg in [[Vector2(0.0, 4.0), Vector2(9.0, 4.4)], [Vector2(0.0, 4.0), Vector2(-11.0, 9.0)]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var t: float = clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		if p.distance_to(a.lerp(b, t)) < 1.1:
			return true
	return false


# V6 — Décors naturels : instancing pour éviter un nombre élevé de draw calls.
# Tous les éléments sont purement visuels : aucun changement des contrôles VR.
func _scatter_v6(name: String, mesh: Mesh, tint: Color, amount: int, category: int, seed_value: int, size_range: Vector2 = Vector2(0.7, 1.45)) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# V25 : les maillages de végétation portent leur propre matériau ; la teinte passe
	# alors par la couleur de chaque instance (fleurs), sinon matériau simple (galets).
	var own_material: bool = mesh is ArrayMesh
	if not own_material:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.roughness = 0.96
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		(mesh as PrimitiveMesh).material = mat
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = amount
	var placed := 0
	# V23 : buissons et gros galets solides, regroupés dans un seul corps statique.
	var solid_body: StaticBody3D = null
	if category == 0 or category == 2:
		solid_body = StaticBody3D.new()
		solid_body.name = name + "_collision_v23"
		solid_body.collision_layer = COLLISION_LAYER_V11
		solid_body.collision_mask = 0
		add_child(solid_body)
	var mesh_box: AABB = mesh.get_aabb()
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
		if Falls.occupied(x, z, 1.0):
			continue
		var size := rng.randf_range(size_range.x, size_range.y)
		var scale_vec := Vector3(size, size * rng.randf_range(0.7, 1.3), size)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(scale_vec)
		batch.set_instance_transform(placed, Transform3D(basis, Vector3(x, y + 0.08, z)))
		if solid_body != null:
			var solid_h: float = mesh_box.size.y * scale_vec.y
			if solid_h > 0.38:
				var cyl := CylinderShape3D.new()
				cyl.radius = maxf(mesh_box.size.x * size * 0.4, 0.15)
				cyl.height = solid_h
				var cs := CollisionShape3D.new()
				cs.shape = cyl
				cs.position = Vector3(x, y + 0.08 + mesh_box.get_center().y * scale_vec.y, z)
				solid_body.add_child(cs)
		var variation := Color(rng.randf_range(0.85, 1.12), rng.randf_range(0.85, 1.12), rng.randf_range(0.85, 1.12), 1.0)
		batch.set_instance_color(placed, variation * tint if own_material and category >= 1 else variation)
		placed += 1
	batch.visible_instance_count = placed
	var item := MultiMeshInstance3D.new()
	item.name = name
	item.multimesh = batch
	# Les buissons projettent une ombre : ils s'ancrent dans le sol.
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if category == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item.visibility_range_end = 100.0 if OS.has_feature("ile_manga_pc") else 65.0
	add_child(item)
	print("ILE_MANGA_V6: ", name, "=", placed)


func _create_scenery_v6() -> void:
	var high_quality := OS.has_feature("ile_manga_pc")
	# Petits feuillages. Le maillage est partagé par toutes les instances.
	_scatter_v6("Buissons_v6", Flora.bush(7), Color.WHITE, 520 if high_quality else 260, 0, 62131)

	# Fleurs colorées (3 lots) en maillages légers, espacées dans les prairies.
	for i in range(3):
		var palette := [Color(0.96, 0.55, 0.68), Color(0.98, 0.85, 0.34), Color(0.70, 0.62, 0.96)]
		_scatter_v6("Fleurs_v6_" + str(i), Flora.flower_clump(), palette[i], 330 if high_quality else 130, 1, 71711 + i * 127, Vector2(0.55, 0.95))

	# V26 : galets et pierres sculptés (bruit 3D), teintés par instance.
	_scatter_v6("Galets_plage_v6", Rocks.pebble(89111), Color(0.95, 0.9, 0.82), 280 if high_quality else 130, 2, 89111)
	_scatter_v6("Pierres_village_v6", Rocks.flat_stone(92231), Color(0.85, 0.8, 0.7), 240 if high_quality else 110, 3, 92231)

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
		_add_obstacle_cylinder_v11("Lanterne_collision_v23", pole.position, 0.16, 2.1)
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
# Details uniquement visuels. Aucun changement des collisions ni des commandes VR.
func _create_scenery_v12() -> void:
	var visuals := preload("res://scripts/visuals_v12.gd").new()
	visuals.name = "Paysages_fantasy_V12"
	add_child(visuals)
	visuals.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


func _create_scenery_v16() -> void:
	var scenic := preload("res://scripts/scenery_v16.gd").new()
	scenic.name = "Forets_feeriques_v16"
	add_child(scenic)
	scenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


func _create_scenery_v13() -> void:
	var scenic := preload("res://scripts/scenery_v13.gd").new()
	scenic.name = "Falaises_cascades_v13"
	add_child(scenic)
	scenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


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
		if y < 0.8 or y > 7.0 or Vector2(x, z - 4.0).length() < 17.0 or Falls.occupied(x, z, 3.0):
			continue
		_make_tree(x, z, i + 14001)
		trees_placed += 1
	var camp_y: float = _height_at(0.0, 4.0)
	# Le GLB du vrai feu remplace le simple cube de la V2.
	var camp := _add_glb("res://assets/models/props/Feu.glb", "Feu_camp_original", Vector3(0.0, camp_y + 1.04, 4.0), 1.2, 0.0)
	if camp == null:
		_make_box("Foyer_secours", Vector3(0, camp_y + 0.12, 4), Vector3(2, 0.24, 2), Color(0.45, 0.30, 0.18))
	camp_light_v24 = OmniLight3D.new()
	camp_light_v24.name = "Lumiere_feu_v24"
	camp_light_v24.light_color = Color(1.0, 0.52, 0.22)
	camp_light_v24.light_energy = 2.2
	camp_light_v24.omni_range = 14.0
	camp_light_v24.shadow_enabled = true
	camp_light_v24.position = Vector3(0, camp_y + 1.1, 4)
	add_child(camp_light_v24)
	_create_fire_v24(Vector3(0, camp_y + 0.55, 4))
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


func _create_village_v18() -> void:
	var details := preload("res://scripts/village_v18.gd").new()
	details.name = "Village_amenage_v18"
	add_child(details)
	details.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


func _create_structures() -> void:
	# Hauteur des maisons prise sur le relief de base (le sol est abaissé sous leurs pièces).
	var home := _add_glb("res://assets/models/buildings/Maison.glb", "Maison_village", Vector3(9, _base_height_v26(9, 4) + 3.6, 4), 4.5, -PI * 0.5)
	if home == null:
		_make_box("Maison_refuge", Vector3(9, _height_at(9, 4) + 2, 4), Vector3(7, 4, 7), Color(0.83, 0.54, 0.45))
		_add_obstacle_box_v11("Maison_refuge_collision", Vector3(9, _height_at(9, 4) + 2, 4), Vector3(7, 4, 7))
	# V23 : les murs solides sont ceux du modèle lui-même (porte comprise).
	_solid_model_v23(home)
	# V27 : petite maison agrandie (x 4,15 au lieu de 3) pour que sa double porte (1,86 m) laisse passer.
	var small := _add_glb("res://assets/models/buildings/Petite_maison.glb", "Petite_maison", Vector3(-11, _base_height_v26(-11, 9) + 0.7477 * 4.15, 9), 4.15, PI * 0.5)
	_solid_model_v23(small)
	houses_v27 = preload("res://scripts/houses_v27.gd").new()
	houses_v27.name = "Maisons_portes_v27"
	add_child(houses_v27)
	houses_v27.build([home, small], OS.has_feature("ile_manga_pc"))
	_add_glb("res://assets/models/buildings/Ile_flottante.glb", "Ile_celeste", Vector3(20, 18, -15), 12, 0.0)
	# Quartier de la plage DJ : éléments originaux Babylon.js réintroduits.
	_solid_model_v23(_add_glb("res://assets/models/props/Mur_de_son.glb", "Mur_de_son", Vector3(0, _height_at(0, 60) + 3.75, 60), 6, PI))
	_solid_model_v23(_add_glb("res://assets/models/props/Table_de_mixage.glb", "Table_de_mixage", Vector3(9, _height_at(9, 60) + 0.988, 60), 2.5, PI))
	_solid_model_v23(_add_glb("res://assets/models/props/Distributeur_8_6.glb", "Distributeur_8_6", Vector3(-9, _height_at(-9, 60) + 1.712, 60), 1.8, PI))
	var rope := _add_glb("res://assets/models/props/Corde.glb", "Corde", Vector3(16, 10, -9), 6.0, 0.0)
	if rope != null:
		_add_obstacle_cylinder_v11("Corde_collision_v23", Vector3(16, _height_at(16, -9) + 1.5, -9), 0.3, 3.0)


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
	pc_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	pc_root.position = xr_origin.position
	add_child(pc_root)
	pc_camera = Camera3D.new()
	pc_camera.position = Vector3(0, 2.5, 5)
	pc_root.add_child(pc_camera)
	pc_camera.look_at(pc_root.global_position + Vector3(0, 1.2, 0))
	pc_camera.current = true
	pc_hero = _add_glb("res://assets/models/characters/hero.glb", "Heros_PC", pc_root.position, 1.0, 0.0)
	hero_mesh_floor_offset_v11 = _hero_foot_offset_v11()

	var hud := CanvasLayer.new()
	add_child(hud)
	hud_v28 = hud
	info = Label.new()
	info.text = "ÎLE MANGA VR " + _version_v21() + "  |  ZQSD : marcher  •  Maj : courir  •  Espace : sauter / grimper  •  Ctrl : roulade  •  clic droit : caméra\nClic gauche : frapper  •  F : parer  •  E : ouvrir / ramasser  •  I : inventaire  •  molette : zoom  •  Échap : menu"
	info.add_theme_font_size_override("font_size", 15)
	info.position = Vector2(20, 20)
	hud.add_child(info)
	message = Label.new()
	message.position = Vector2(20, 66)
	message.add_theme_font_size_override("font_size", 18)
	hud.add_child(message)
	door_prompt_v27 = Label.new()
	door_prompt_v27.add_theme_font_size_override("font_size", 24)
	door_prompt_v27.add_theme_color_override("font_outline_color", Color.BLACK)
	door_prompt_v27.add_theme_constant_override("outline_size", 6)
	door_prompt_v27.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	door_prompt_v27.position.y -= 90
	door_prompt_v27.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(door_prompt_v27)
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
		info.text = "ÎLE MANGA PC " + _version_v21() + "  |  ZQSD : marcher  •  clic droit : caméra  •  Échap : quitter"
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

func _start_save_slot(slot: int, new_game: bool) -> void:
	game_started = true
	var origin: Node3D = xr_origin if xr_active else pc_root
	if new_game:
		origin.position = Vector3(2.0, maxf(0.0, _height_at(2.0, 8.0)), 8.0)
		origin.rotation.y = 0.0
		game_menu.seconds = 0.0
		if inventory_v28 != null:
			inventory_v28.reset()
		if hero_v28 != null:
			hero_v28.set_health(hero_v28.HP_MAX)
		if boat_v29 != null:
			boat_v29.driving = false
			boat_v29.moor(0)
		_save_slot(slot)
	else:
		var data: Dictionary = SaveStore.read_slot(slot)
		var a: Array = data.get("position", [])
		if a.size() == 3:
			origin.position = Vector3(float(a[0]), float(a[1]), float(a[2]))
		origin.rotation.y = float(data.get("yaw", 0.0))
		game_menu.seconds = float(data.get("play_seconds", 0.0))
		# V28 : inventaire et vie (absents des sauvegardes plus anciennes).
		if inventory_v28 != null:
			var inv_data: Variant = data.get("inventaire", {})
			if inv_data is Dictionary:
				inventory_v28.load_data(inv_data)
		if hero_v28 != null:
			hero_v28.set_health(int(data.get("vie", hero_v28.HP_MAX)))
		if boat_v29 != null:
			var boat_data: Variant = data.get("bateau", {})
			boat_v29.driving = false
			boat_v29.load_data(boat_data if boat_data is Dictionary else {})
			if boat_data is Dictionary and bool(boat_data.get("a_bord", false)):
				_board_boat_v29()
	if not xr_active and pc_hero != null:
		pc_hero.position = origin.position
		pc_hero.rotation.y = origin.rotation.y
	if hero_v28 != null and (boat_v29 == null or not boat_v29.driving):
		hero_v28.state = "sol"
		hero_v28.facing = -origin.global_basis.z
	if boat_v29 == null or not boat_v29.driving:
		_sync_physics_after_load_v11()
	last_ok_v29.clear()
	autosave_clock = 0.0


func _delete_slot(slot: int) -> void:
	print("ILE_MANGA_DELETE: ", slot, " = ", SaveStore.delete_slot(slot))


func _save_slot(slot: int) -> void:
	if not game_started:
		return
	var origin: Node3D = xr_origin if xr_active else pc_root
	var extra: Dictionary = {}
	if inventory_v28 != null:
		extra["inventaire"] = inventory_v28.serialize()
	if hero_v28 != null:
		extra["vie"] = hero_v28.hp
	if boat_v29 != null:
		extra["bateau"] = boat_v29.serialize()
	var ok: bool = SaveStore.write_slot(slot, origin.position, origin.rotation.y, game_menu.seconds, extra)
	print("ILE_MANGA_SAVE: ", slot, " = ", ok)


func _physics_process(delta: float) -> void:
	# V24 : la lumière du feu vacille (deux sinus décalés, sans à-coups).
	if camp_light_v24 != null:
		fire_clock_v24 += delta
		camp_light_v24.light_energy = 2.2 + sin(fire_clock_v24 * 9.1) * 0.25 + sin(fire_clock_v24 * 23.7) * 0.15
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
	if game_menu != null and xr_active and game_started and not game_menu.opened and left_hand.get_float("menu_button") > 0.8:
		game_menu.open_menu()
	_doors_update_v27()
	if game_menu != null and (game_menu.opened or not game_started):
		return
	autosave_clock += delta
	if autosave_clock >= 90.0:
		_save_slot(0)
		autosave_clock = 0.0
	if xr_active:
		if boat_v29 != null and boat_v29.driving:
			_drive_boat_vr_v29(delta)
		else:
			_move_xr(delta)
			_vr_actions_v28(delta)
	else:
		_move_desktop(delta)
	if message_clock_v28 > 0.0:
		message_clock_v28 -= delta
		if message_clock_v28 <= 0.0 and message != null:
			message.text = ""


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
		_move_xr_body_v23(move * minf(stick.length(), 1.0) * WALK_SPEED * delta)
	else:
		_move_xr_body_v23(Vector3.ZERO)
	var turn: float = right_hand.get_vector2("primary").x
	if absf(turn) < 0.35:
		turn_ready = true
	elif absf(turn) > TURN_STICK_THRESHOLD and turn_ready:
		# V23 : rotation autour de la tête, le joueur ne glisse plus de côté.
		var pivot: Vector3 = xr_camera.global_position
		xr_origin.rotate_y(-signf(turn) * SNAP_TURN)
		var after: Vector3 = xr_camera.global_position
		xr_origin.global_position += Vector3(pivot.x - after.x, 0.0, pivot.z - after.z)
		turn_ready = false


func _move_desktop(delta: float) -> void:
	if boat_v29 != null and boat_v29.driving:
		_drive_boat_pc_v29(delta)
		return
	if hero_v28 != null:
		if inventory_v28 == null or not inventory_v28.opened:
			hero_v28.physics(delta)
		else:
			hero_v28.physics(0.0001)
		return
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
		pc_hero.position = pc_root.position + Vector3.UP * hero_mesh_floor_offset_v11
		if axis.length() > 0.05:
			# Mesh GLB is oriented opposite to the old visual rotation.
			pc_hero.rotation.y = atan2(-direction.x, -direction.z) + PI


func _build_physical_world_v11() -> void:
	vr_body = _new_player_body_v11("Physique_Quest3", xr_origin.position)
	pc_body = _new_player_body_v11("Physique_PC", pc_root.position)
	# V23 : maisons et installations DJ utilisent la forme exacte de leur modèle
	# (voir _solid_model_v23) ; les anciens murs estimés sont supprimés.
	_add_obstacle_cylinder_v11("Feu_collision", Vector3(0, _height_at(0, 4) + 0.55, 4), 0.9, 1.1)
	print("ILE_MANGA_PHYSICS_V11: terrain, maisons, arbres et props solides")


func _new_player_body_v11(label: String, spawn: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = label
	body.collision_layer = 2
	body.collision_mask = COLLISION_LAYER_V11
	body.floor_snap_length = 0.18
	body.floor_max_angle = deg_to_rad(45.0)
	body.safe_margin = 0.03
	body.position = spawn + Vector3.UP * 0.22
	var shape := CollisionShape3D.new()
	shape.name = "Capsule_joueur"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.87
	body.add_child(shape)
	add_child(body)
	return body


func _add_obstacle_box_v11(label: String, pos: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = COLLISION_LAYER_V11
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _add_obstacle_cylinder_v11(label: String, pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = COLLISION_LAYER_V11
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	add_child(body)


func _move_player(origin: Node3D, offset: Vector3) -> void:
	var body: CharacterBody3D = vr_body if origin == xr_origin else pc_body
	if body == null:
		return
	var dt: float = maxf(get_physics_process_delta_time(), 0.001)
	var ground: float = _height_at(body.position.x, body.position.z)
	if body.position.y < ground - 0.7:
		# Single rescue outside the surface; capsule must start above the terrain.
		body.global_position = Vector3(body.position.x, ground + 1.15, body.position.z)
		body.velocity = Vector3.ZERO
	body.velocity.x = offset.x / dt
	body.velocity.z = offset.z / dt
	# V28 : au sol on reste collé, sauf au moment d'un saut (vitesse vers le haut).
	if body.is_on_floor() and body.velocity.y <= 0.0:
		body.velocity.y = -0.05
	else:
		body.velocity.y = maxf(body.velocity.y - GRAVITY_V11 * dt, -24.0)
	body.move_and_slide()
	_try_step_v23(body, Vector3(offset.x, 0.0, offset.z))
	_limit_on_foot_v29(body)
	# Body origin represents the feet; avoid the old -0.09 m offset.
	origin.position = body.position


func _sync_physics_after_load_v11() -> void:
	if vr_body != null:
		var pos_vr: Vector3 = xr_origin.position
		pos_vr.y = maxf(pos_vr.y, _height_at(pos_vr.x, pos_vr.z) + 0.9)
		vr_body.global_position = pos_vr
		vr_body.velocity = Vector3.ZERO
		xr_origin.position = pos_vr
	if pc_body != null:
		var pos_pc: Vector3 = pc_root.position
		pos_pc.y = maxf(pos_pc.y, _height_at(pos_pc.x, pos_pc.z) + 0.9)
		pc_body.global_position = pos_pc
		pc_body.velocity = Vector3.ZERO
		pc_root.position = pos_pc
	if pc_hero != null:
		pc_hero.position = pc_root.position + Vector3.UP * hero_mesh_floor_offset_v11


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and inventory_v28 != null and inventory_v28.opened:
			inventory_v28.close()
		elif event.keycode == KEY_ESCAPE:
			if game_menu != null:
				if game_menu.opened and game_started:
					game_menu._close()
				else:
					game_menu.open_menu()
			else:
				get_tree().quit()
		elif event.keycode == KEY_E and game_started and houses_v27 != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened):
			_interact_v28()
		elif (event.keycode == KEY_I or event.keycode == KEY_TAB) and game_started and inventory_v28 != null and not game_menu.opened:
			inventory_v28.toggle()
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

func _hero_foot_offset_v11() -> float:
	if pc_hero == null:
		return 0.0
	var found: bool = false
	var min_y: float = 1e20
	var pending: Array[Node] = [pc_hero]
	while not pending.is_empty():
		var n: Node = pending.pop_back()
		if n is MeshInstance3D:
			var visual: MeshInstance3D = n as MeshInstance3D
			if visual.mesh != null:
				var bounds: AABB = visual.get_aabb()
				for xx in [0.0, 1.0]:
					for yy in [0.0, 1.0]:
						for zz in [0.0, 1.0]:
							var pt: Vector3 = bounds.position + bounds.size * Vector3(xx, yy, zz)
							min_y = minf(min_y, (visual.global_transform * pt).y)
							found = true
		for c in n.get_children():
			pending.append(c)
	return pc_hero.global_position.y - min_y if found else 0.0



func _create_scenery_v15() -> void:
	var scenic := preload("res://scripts/scenery_v15.gd").new()
	scenic.name = "Paysages_v15"
	add_child(scenic)
	scenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


func _create_scenery_v17() -> void:
	var scenic := preload("res://scripts/scenery_v17.gd").new()
	scenic.name = "Sentiers_et_clairieres_v17"
	add_child(scenic)
	scenic.build(Callable(self, "_height_at"), OS.has_feature("ile_manga_pc"))


# ILE_MANGA_V20_FINITION_2


# V21 : numéro lu dans project.godot, plus jamais d'affichage périmé.
func _version_v21() -> String:
	var parts: PackedStringArray = str(ProjectSettings.get_setting("application/config/name", "")).split(" ")
	return parts[parts.size() - 1] if parts.size() > 0 else ""


# V23 : collision exacte d'un modèle GLB (murs, porte, perron tels que dessinés).
func _solid_model_v23(root: Node3D) -> void:
	if root == null:
		return
	var body := StaticBody3D.new()
	body.name = str(root.name) + "_collision_v23"
	body.collision_layer = COLLISION_LAYER_V11
	body.collision_mask = 0
	add_child(body)
	# V24 : collision pré-calculée (tools/bake_collisions_v24.gd), chargée en un instant.
	var baked_path := "res://collision/%s.res" % str(root.name)
	if ResourceLoader.exists(baked_path):
		var baked := CollisionShape3D.new()
		baked.shape = load(baked_path)
		body.add_child(baked)
		baked.global_transform = Transform3D(root.global_basis.orthonormalized(), root.global_position)
		return
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var n: Node = pending.pop_back()
		for c in n.get_children():
			pending.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var visual: MeshInstance3D = n as MeshInstance3D
			var shape := visual.mesh.create_trimesh_shape()
			if shape == null:
				continue
			(shape as ConcavePolygonShape3D).backface_collision = true
			var cs := CollisionShape3D.new()
			cs.shape = shape
			body.add_child(cs)
			cs.global_transform = visual.global_transform


# V23 : franchir une marche basse (perron, galet) au lieu de rester bloqué.
# On vérifie que la capsule entière tient au-dessus de la marche : une clôture,
# une jardinière ou un mur restent infranchissables.
func _try_step_v23(body: CharacterBody3D, horizontal: Vector3) -> void:
	# Seulement les pieds au sol : pas de « marche » en pleine chute.
	if horizontal.length() < 0.0005 or not body.is_on_wall() or not body.is_on_floor():
		return
	var shape_node: CollisionShape3D = body.get_node_or_null("Capsule_joueur")
	if shape_node == null:
		return
	var space := body.get_world_3d().direct_space_state
	var ahead: Vector3 = horizontal.normalized() * 0.22
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = shape_node.shape
	probe.collision_mask = body.collision_mask
	probe.exclude = [body.get_rid()]
	probe.margin = 0.01
	var start: Transform3D = body.global_transform
	# V27 : on essaie la plus petite hauteur qui suffit (sous un auvent, 0,42 m d'un coup
	# ferait toucher la tête et la marche serait refusée).
	for lift_h in [0.12, 0.22, 0.32, STEP_HEIGHT_V23]:
		var lift := Vector3.UP * float(lift_h)
		var free: bool = true
		for place in [start.translated(lift), start.translated(lift + ahead)]:
			probe.transform = place * shape_node.transform
			if not space.intersect_shape(probe, 1).is_empty():
				free = false
				break
		if not free:
			continue
		var top: Vector3 = start.origin + lift + ahead
		# Le dessus de la marche se mesure sous l'avant du pied, pas sous le centre.
		var toe: Vector3 = top + horizontal.normalized() * 0.28
		var ray := PhysicsRayQueryParameters3D.create(toe + Vector3.UP * 0.05, toe - lift - Vector3.UP * 0.1, body.collision_mask, [body.get_rid()])
		var floor_hit := space.intersect_ray(ray)
		if floor_hit.is_empty() or floor_hit.normal.y < 0.7:
			continue
		var rise: float = floor_hit.position.y - start.origin.y
		if rise < 0.02 or rise > float(lift_h):
			continue
		body.global_position = Vector3(top.x, floor_hit.position.y + 0.01, top.z)
		return


# V23 : en VR le corps suit la tête ; si on marche physiquement dans un mur,
# c'est le monde qui recule : la tête ne traverse plus rien.
func _move_xr_body_v23(stick_offset: Vector3) -> void:
	var head: Vector3 = xr_camera.global_position
	var head_offset := Vector3(head.x - xr_origin.global_position.x, 0.0, head.z - xr_origin.global_position.z)
	var feet: Vector3 = vr_body.global_position
	var wanted := Vector3(head.x - feet.x, 0.0, head.z - feet.z) + stick_offset
	if wanted.length() > 1.5:
		# Grand saut du suivi (recentrage du casque) : on replace le corps sans physique.
		vr_body.global_position = Vector3(head.x, feet.y, head.z) + stick_offset
		wanted = Vector3.ZERO
	var dt: float = maxf(get_physics_process_delta_time(), 0.001)
	var ground: float = _height_at(vr_body.position.x, vr_body.position.z)
	if vr_body.position.y < ground - 0.7:
		vr_body.global_position = Vector3(vr_body.position.x, ground + 1.15, vr_body.position.z)
		vr_body.velocity = Vector3.ZERO
	vr_body.velocity.x = wanted.x / dt
	vr_body.velocity.z = wanted.z / dt
	if vr_body.is_on_floor() and vr_body.velocity.y <= 0.0:
		vr_body.velocity.y = -0.05
	else:
		vr_body.velocity.y = maxf(vr_body.velocity.y - GRAVITY_V11 * dt, -24.0)
	vr_body.move_and_slide()
	_try_step_v23(vr_body, wanted)
	_limit_on_foot_v29(vr_body)
	# L'origine se place pour que la tête reste exactement au-dessus du corps.
	xr_origin.position = Vector3(vr_body.position.x - head_offset.x, vr_body.position.y, vr_body.position.z - head_offset.z)


# V24 : feu de camp en particules (flammes additives, braises, fumée).
func _soft_dot_v24() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex


func _particles_v24(label: String, at: Vector3, amount: int, lifetime: float, size: float, ramp: Gradient, additive: bool, velocity: Vector2, spread: float) -> void:
	var parts := GPUParticles3D.new()
	parts.name = label
	parts.amount = amount
	parts.lifetime = lifetime
	parts.position = at
	parts.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = spread
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = velocity.x
	process.initial_velocity_max = velocity.y
	process.gravity = Vector3(0, 0.6, 0)
	process.damping_min = 0.4
	process.damping_max = 0.9
	process.scale_min = 0.7
	process.scale_max = 1.25
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.55))
	curve.add_point(Vector2(0.35, 1.0))
	curve.add_point(Vector2(1.0, 0.15))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve
	process.scale_curve = curve_tex
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	process.color_ramp = ramp_tex
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.6
	process.turbulence_noise_scale = 2.4
	parts.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_dot_v24()
	mat.disable_receive_shadows = true
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(parts)


func _create_fire_v24(at: Vector3) -> void:
	var flames := Gradient.new()
	flames.set_color(0, Color(1.0, 0.85, 0.45, 0.0))
	flames.add_point(0.12, Color(1.0, 0.72, 0.28, 0.95))
	flames.add_point(0.5, Color(0.95, 0.32, 0.06, 0.7))
	flames.set_color(flames.get_point_count() - 1, Color(0.4, 0.06, 0.02, 0.0))
	_particles_v24("Flammes_v24", at, 64, 0.85, 0.55, flames, true, Vector2(0.6, 1.4), 0.28)
	var embers := Gradient.new()
	embers.set_color(0, Color(1.0, 0.7, 0.3, 1.0))
	embers.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	_particles_v24("Braises_v24", at + Vector3.UP * 0.3, 24, 2.2, 0.05, embers, true, Vector2(1.0, 2.2), 0.3)
	var smoke := Gradient.new()
	smoke.set_color(0, Color(0.35, 0.33, 0.32, 0.0))
	smoke.add_point(0.2, Color(0.32, 0.31, 0.3, 0.32))
	smoke.set_color(smoke.get_point_count() - 1, Color(0.5, 0.5, 0.52, 0.0))
	_particles_v24("Fumee_v24", at + Vector3.UP * 1.0, 26, 4.5, 1.4, smoke, false, Vector2(0.5, 0.9), 0.25)


# V27 : position du joueur (tête en VR, corps au PC) pour les portes.
func _player_pos_v27() -> Vector3:
	return xr_camera.global_position if xr_active else pc_root.global_position


func _doors_update_v27() -> void:
	if houses_v27 == null:
		return
	var playing: bool = game_started and game_menu != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened)
	var text: String = houses_v27.prompt(_player_pos_v27(), xr_active) if playing else ""
	# V28 : l'objet à ramasser passe avant la porte s'il est plus proche.
	if playing and inventory_v28 != null and not xr_active:
		var pick: int = inventory_v28.nearest_pickup(_player_pos_v27())
		if pick >= 0 and (text == "" or inventory_v28.pickup_distance(pick, _player_pos_v27()) < _door_distance_v28()):
			text = inventory_v28.prompt_text(_player_pos_v27())
	if playing and boat_v29 != null and not xr_active:
		var boat_text: String = boat_v29.prompt(_player_pos_v27())
		if boat_text != "":
			text = boat_text
	if door_prompt_v27 != null:
		door_prompt_v27.text = text if not xr_active else ""
	if xr_active and playing and boat_v29 != null:
		boat_v29.update_vr_label(xr_camera.global_position)
	if xr_active and playing and boat_v29 != null and not boat_v29.driving and boat_v29.can_board(xr_camera.global_position):
		if right_hand.get_float("trigger") > 0.7 and trigger_ready_v27:
			_board_boat_v29()
		trigger_ready_v27 = right_hand.get_float("trigger") <= 0.7
		return
	if xr_active and playing and boat_v29 != null and boat_v29.driving:
		return
	if xr_active and playing:
		var hand_pick: int = inventory_v28.update_vr_labels(right_hand.global_position) if inventory_v28 != null else -1
		var pressed: bool = right_hand.get_float("trigger") > 0.7
		if pressed and trigger_ready_v27:
			if hand_pick >= 0:
				inventory_v28.collect(hand_pick)
			else:
				houses_v27.interact(_player_pos_v27())
		trigger_ready_v27 = not pressed


# =================================================================== V28 : mouvements, combat, inventaire

func _create_gameplay_v28() -> void:
	combat_v28 = preload("res://scripts/combat_v28.gd").new()
	combat_v28.name = "Combat_v28"
	add_child(combat_v28)
	inventory_v28 = preload("res://scripts/inventory_v28.gd").new()
	inventory_v28.name = "Inventaire_v28"
	add_child(inventory_v28)
	inventory_v28.setup(self, xr_active)
	inventory_v28.notify.connect(_show_message_v28)
	inventory_v28.equipped_changed.connect(_on_equip_v28)
	inventory_v28.use_food = func(half_hearts: int) -> bool:
		return hero_v28.heal(half_hearts) if hero_v28 != null and not xr_active else true
	inventory_v28.drop_point = _drop_point_v28
	combat_v28.build(self, inventory_v28)
	hero_v28 = preload("res://scripts/hero_v28.gd").new()
	hero_v28.name = "Heros_v28"
	add_child(hero_v28)
	hero_v28.setup(self, pc_body, pc_root, pc_hero, pc_camera)
	hero_v28.strike = combat_v28.strike
	hero_v28.fainted.connect(_respawn_v28)
	if not xr_active and hud_v28 != null:
		hero_v28.make_hud(hud_v28)
	# Les objets se posent sur le sol réel : on attend que la physique soit prête.
	_spawn_world_v28.call_deferred()


func _spawn_world_v28() -> void:
	await get_tree().physics_frame
	inventory_v28.spawn_world()
	print("ILE_MANGA_V28: ", inventory_v28.pickups.size(), " objets à ramasser")


func _show_message_v28(text: String) -> void:
	if message != null:
		message.text = text
		message_clock_v28 = 3.0


func _door_distance_v28() -> float:
	if houses_v27 == null:
		return INF
	var i: int = houses_v27.nearest(_player_pos_v27())
	if i < 0:
		return INF
	var c: Vector3 = houses_v27.doors[i]["center"]
	var p: Vector3 = _player_pos_v27()
	return Vector2(c.x - p.x, c.z - p.z).length()


## E : bateau (monter / débarquer), sinon ramasser l'objet le plus proche, sinon la porte.
func _interact_v28() -> void:
	var p: Vector3 = _player_pos_v27()
	if boat_v29 != null:
		if boat_v29.driving:
			_leave_boat_v29()
			return
		if boat_v29.can_board(p):
			_board_boat_v29()
			return
	var pick: int = inventory_v28.nearest_pickup(p) if inventory_v28 != null else -1
	if pick >= 0 and inventory_v28.pickup_distance(pick, p) < _door_distance_v28():
		var where: Vector3 = inventory_v28.pickups[pick]["pos"]
		if inventory_v28.collect(pick) and hero_v28 != null:
			hero_v28.play_action("pickup", where)
		return
	var door: int = houses_v27.nearest(p)
	if houses_v27.interact(p) and hero_v28 != null and door >= 0:
		hero_v28.play_action("push", houses_v27.doors[door]["center"])


func _drop_point_v28() -> Vector3:
	var origin: Vector3 = _player_pos_v27()
	var fwd: Vector3 = hero_v28.facing if hero_v28 != null and not xr_active else -xr_camera.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var spot: Vector3 = origin + fwd * 0.8
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 1.5, spot - Vector3.UP * 3.0, 1))
	spot.y = hit.position.y if not hit.is_empty() else _height_at(spot.x, spot.z)
	return spot


func _on_equip_v28(item_id: String) -> void:
	var damage: int = int(inventory_v28.ITEMS[item_id].get("damage", 1)) if item_id != "" else 1
	if hero_v28 != null:
		hero_v28.equip(item_id, damage, inventory_v28.make_model(item_id) if item_id != "" else null)
	# En VR, l'arme se tient dans la main droite, lame vers l'avant.
	var old: Node = right_hand.get_node_or_null("Arme_VR_v28")
	if old != null:
		old.queue_free()
	if item_id != "":
		var holder := Node3D.new()
		holder.name = "Arme_VR_v28"
		holder.rotation_degrees = Vector3(-90, 0, 0)
		holder.position = Vector3(0, -0.01, 0.03)
		holder.add_child(inventory_v28.make_model(item_id))
		right_hand.add_child(holder)
		right_hand.get_node("Manette_visible").visible = false
	else:
		right_hand.get_node("Manette_visible").visible = true


func _respawn_v28() -> void:
	pc_root.position = Vector3(2.0, maxf(0.0, _height_at(2.0, 8.0)), 8.0)
	_sync_physics_after_load_v11()
	_show_message_v28("Vous vous êtes évanoui… Vous voici de retour au village.")


## VR : A pour sauter (ou se hisser sur un rebord devant soi), Y pour l'inventaire,
## coups de poing ou d'épée en bougeant vite la main. Le déplacement au joystick ne change pas.
func _vr_actions_v28(delta: float) -> void:
	var a_now: bool = right_hand.is_button_pressed("ax_button")
	var y_now: bool = left_hand.is_button_pressed("by_button")
	var a_edge: bool = a_now and not vr_buttons_v28.get("a", false)
	var y_edge: bool = y_now and not vr_buttons_v28.get("y", false)
	vr_buttons_v28["a"] = a_now
	vr_buttons_v28["y"] = y_now
	if y_edge and inventory_v28 != null:
		inventory_v28.toggle()
	if inventory_v28 != null and inventory_v28.opened:
		inventory_v28.vr_tick(right_hand.get_vector2("primary").y, right_hand.get_float("trigger"), right_hand.get_float("grip"))
		return
	if a_edge:
		vr_jump_v28()
	if combat_v28 != null:
		var armed: bool = inventory_v28 != null and inventory_v28.equipped != ""
		var points := {"gauche": [left_hand.global_position, 0.12, 1, left_hand.position]}
		if armed:
			var dmg: int = int(inventory_v28.ITEMS[inventory_v28.equipped].get("damage", 1))
			var blade: Vector3 = -right_hand.global_basis.z
			var mid: Vector3 = right_hand.global_position + blade * 0.45
			var tip: Vector3 = right_hand.global_position + blade * 0.75
			points["lame"] = [mid, 0.15, dmg, xr_origin.to_local(mid)]
			points["pointe"] = [tip, 0.12, dmg, xr_origin.to_local(tip)]
		else:
			points["droite"] = [right_hand.global_position, 0.12, 1, right_hand.position]
		combat_v28.vr_tick(delta, points, xr_camera.global_position)


func vr_jump_v28() -> void:
	if vr_body == null:
		return
	var fwd: Vector3 = -xr_camera.global_basis.z
	if hero_v28 != null:
		var ledge: Dictionary = hero_v28.find_ledge(vr_body, fwd)
		if not ledge.is_empty():
			# Confort : on se retrouve directement sur le rebord, sans mouvement imposé.
			var head: Vector3 = xr_camera.global_position
			var head_offset := Vector3(head.x - xr_origin.global_position.x, 0.0, head.z - xr_origin.global_position.z)
			vr_body.global_position = ledge["top"]
			vr_body.velocity = Vector3.ZERO
			xr_origin.position = Vector3(vr_body.position.x - head_offset.x, vr_body.position.y, vr_body.position.z - head_offset.z)
			return
	if vr_body.is_on_floor():
		vr_body.velocity.y = JUMP_SPEED_V28


# =================================================================== V29 : île-jungle et bateau

func _create_jungle_v29() -> void:
	jungle_v29 = preload("res://scripts/jungle_v29.gd").new()
	jungle_v29.name = "Ile_jungle_v29"
	add_child(jungle_v29)
	jungle_v29.build(OS.has_feature("ile_manga_pc"))
	# V30 : la forêt tropicale de l'île.
	var flora: Node3D = preload("res://scripts/jungle_flora_v30.gd").new()
	flora.name = "Foret_jungle_v30"
	add_child(flora)
	flora.build(jungle_v29, OS.has_feature("ile_manga_pc"))
	boat_v29 = preload("res://scripts/boat_v29.gd").new()
	boat_v29.name = "Bateau_v29"
	add_child(boat_v29)
	boat_v29.build(self, ISLAND_DOCK_V29, [jungle_v29.dock_start, jungle_v29.dock_end])


## À pied : on ne s'avance pas dans la mer (l'île du village garde sa limite ronde,
## la jungle bloque dès que l'eau devient profonde) ; les pontons restent accessibles.
func _limit_on_foot_v29(body: CharacterBody3D) -> void:
	var p: Vector3 = body.position
	var key: String = str(body.name)
	if boat_v29 != null and boat_v29.on_dock(p):
		last_ok_v29[key] = p
		return
	if jungle_v29 != null and Vector2(p.x, p.z).length() > 120.0:
		if jungle_v29.height(p.x, p.z) > -0.3:
			last_ok_v29[key] = p
			return
		if last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	var flat := Vector2(p.x, p.z)
	if flat.length() > ISLAND_LIMIT_V21:
		flat = flat.normalized() * ISLAND_LIMIT_V21
		body.position.x = flat.x
		body.position.z = flat.y
	last_ok_v29[key] = body.position


func _board_boat_v29() -> void:
	if inventory_v28 != null and inventory_v28.opened:
		inventory_v28.close()
	boat_v29.board()
	if hero_v28 != null and not xr_active:
		hero_v28.cam_distance = maxf(hero_v28.cam_distance, 1.5)
	_show_message_v28("À bord ! Z / S pour avancer, Q / D pour barrer." if not xr_active else "À bord ! Stick gauche pour naviguer.")


func _leave_boat_v29() -> void:
	var spot: Variant = boat_v29.landing_spot()
	if spot == null:
		_show_message_v28("Trop loin du rivage : approchez un ponton ou une plage.")
		return
	boat_v29.leave()
	var origin: Node3D = xr_origin if xr_active else pc_root
	origin.position = spot
	if xr_active:
		vr_body.global_position = spot
		vr_body.velocity = Vector3.ZERO
	else:
		pc_body.global_position = spot
		pc_body.velocity = Vector3.ZERO
		if hero_v28 != null:
			hero_v28.leave_ride()
			hero_v28.cam_distance = 1.0
	last_ok_v29.clear()


func _drive_boat_pc_v29(delta: float) -> void:
	var throttle: float = 0.0
	var steer: float = 0.0
	var can_drive: bool = inventory_v28 == null or not inventory_v28.opened
	if can_drive:
		if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			throttle += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			throttle -= 1.0
		if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer += 1.0
	var before: float = boat_v29.yaw
	boat_v29.drive(delta, throttle, steer)
	# La caméra tourne avec la barque (le clic droit reste libre).
	pc_root.rotation.y += boat_v29.yaw - before
	var seat: Transform3D = boat_v29.seat_transform()
	pc_root.position = seat.origin
	pc_body.global_position = seat.origin + Vector3.UP * 0.4
	pc_body.velocity = Vector3.ZERO
	if hero_v28 != null:
		hero_v28.ride(seat)


func _drive_boat_vr_v29(delta: float) -> void:
	boat_v29.vr_tick(delta, left_hand.get_vector2("primary"), right_hand.get_float("trigger"))
	if not boat_v29.driving:
		return
	var seat: Transform3D = boat_v29.seat_transform()
	xr_origin.rotation.y = boat_v29.yaw + boat_v29._vr_yaw_offset
	var cam_local: Vector3 = xr_camera.position
	var offset: Vector3 = Basis(Vector3.UP, xr_origin.rotation.y) * Vector3(cam_local.x, 0.0, cam_local.z)
	xr_origin.position = Vector3(seat.origin.x - offset.x, seat.origin.y - 0.3, seat.origin.z - offset.z)
	vr_body.global_position = seat.origin + Vector3.UP * 0.4
	vr_body.velocity = Vector3.ZERO

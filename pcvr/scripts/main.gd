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
# V31 : habitants (petite IA commune) et dialogues.
var npcs_v31: Array = []
var dialogue_v31: Node3D
var fishing_v32: Node3D
# V33 : le rival de Barnabé (cabane dans l'arbre, boutique) et la pelle.
var flora_v30: Node3D
var elfes_v41: Node3D
var nains_v46: Node3D
var tree_spot_v33: Dictionary = {}
var treehouse_v33: Node3D
var digging_v33: Node3D
var vr_ladder_v33: Dictionary = {}
# V34 : arbres à abattre, traînée des lames.
var bucheron_v34: Node3D
var treasure_jungle_v34: Array = []      # cachettes de la jungle (avant la végétation)
var mouette_spot_v34: Vector3 = Vector3.INF
# V35 : le Temple englouti (souterrain sous les deux îles).
var donjon_v35: Node3D
var trap_jungle_spot_v35: Vector3 = Vector3.INF
var monstres_v36: Node3D
var trainee_v34: Node3D
var talking_npc_v31: Node3D
var cabin_spot_v31: Dictionary = {}
var pending_pnj_v31: Dictionary = {}
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
	# V81 : les portes des maisons décoratives sont notées pendant la construction des villes
	preload("res://scripts/azur_kit_v56.gd").PORTES_V81.clear()
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
	_bake_shore_v48()
	_create_ambiance_v49()
	_create_sfx_v50()
	_create_music_v51()
	_create_v52()
	_create_decor_v53()
	_create_v54()
	_create_v55()
	_create_v56()
	_create_v58()
	_create_v59()
	_create_v63()
	_create_v65()
	_create_v66()
	_create_v67()
	_create_v68()
	_create_v69()
	_create_v70()
	_create_v71()
	_create_v75()
	_create_v76()
	_create_v87()
	_create_manette_v74()
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
	var land: float = _height_land_v55(x, z)
	# V55 : le fond de la mer (au large, la pente des îles s'arrête sur lui)
	if mer_v55 != null:
		return maxf(land, mer_v55.seabed(x, z))
	return land


## Le relief des îles seules (sans le fond de la mer).
func _height_land_v55(x: float, z: float) -> float:
	# V29 : la jungle a son propre relief ; ailleurs, celui de l'île du village.
	var h: float = _height_island_v29(x, z)
	# V67 : Arcanelle, l'île des sorciers (son carré touche le bord du cercle de la jungle)
	if arcanelle_v67 != null and arcanelle_v67.ile != null and arcanelle_v67.ile.contains(x, z):
		h = maxf(h, arcanelle_v67.ile.height(x, z))
	# V68 : l'Île de la Balafre (son carré touche les coins de la jungle et de la grande île)
	if pirates_v68 != null and pirates_v68.ile != null and pirates_v68.ile.contains(x, z):
		h = maxf(h, pirates_v68.ile.height(x, z))
	# V69 : l'Île des Trois Soleils (loin à l'ouest : son carré ne touche aucune autre île)
	if soleils_v69 != null and soleils_v69.ile != null and soleils_v69.ile.contains(x, z):
		return maxf(h, soleils_v69.ile.height(x, z))
	# V70 : l'Île de Braise (au sud-ouest, sous l'île des fées ; son carré ne touche aucune autre île)
	if braise_v70 != null and braise_v70.ile != null and braise_v70.ile.contains(x, z):
		return maxf(h, braise_v70.ile.height(x, z))
	# V71 : l'Île de Montjoie (à l'est de la grande île ; son carré ne touche aucune autre île)
	if montjoie_v71 != null and montjoie_v71.ile != null and montjoie_v71.ile.contains(x, z):
		return maxf(h, montjoie_v71.ile.height(x, z))
	# V75 : l'Île du Boucan (au sud, sous l'île céleste ; son carré ne touche aucune autre île)
	if boucan_v75 != null and boucan_v75.ile != null and boucan_v75.ile.contains(x, z):
		return maxf(h, boucan_v75.ile.height(x, z))
	# V87 : l'Île aux Moaïs (au nord, entre la jungle et la Balafre ; son carré ne touche aucune autre île)
	if moai_v87 != null and moai_v87.ile != null and moai_v87.ile.contains(x, z):
		return maxf(h, moai_v87.ile.height(x, z))
	if jungle_v29 != null and jungle_v29.contains(x, z):
		return maxf(h, jungle_v29.height(x, z))
	# V41 : l'île des elfes
	if elfes_v41 != null and elfes_v41.ile != null and elfes_v41.ile.contains(x, z):
		return maxf(h, elfes_v41.ile.height(x, z))
	# V46 : l'île des nains
	if nains_v46 != null and nains_v46.ile != null and nains_v46.ile.contains(x, z):
		return maxf(h, nains_v46.ile.height(x, z))
	# V56 : Port-Azur
	if azur_v56 != null and azur_v56.ile != null and azur_v56.ile.contains(x, z):
		return maxf(h, azur_v56.ile.height(x, z))
	# V59 : la grande île de l'est
	if grande_v59 != null and grande_v59.ile != null and grande_v59.ile.contains(x, z):
		return maxf(h, grande_v59.ile.height(x, z))
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
	env.fog_density = 0.0011                 # V53 : les îles lointaines ne sont plus délavées
	env.fog_aerial_perspective = 0.6
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
	# V53 : quelques pierres arrondies, à moitié enterrées (plus de « crêpes » sur la pelouse).
	_scatter_v6("Pierres_village_v6", Rocks.pebble(92231), Color(0.72, 0.7, 0.64), 70 if high_quality else 40, 3, 92231)

	# V53 : sentiers dallés et lanternes de village (remplacent Sentier_village_v6 et Lanterne_chaude_v6) : voir decor_v53.gd.


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
	# V53 : le panneau d'accueil est un vrai panneau de bois (decor_v53.gd).


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
	# V57 : platines tournées vers la foule (le DJ se tient côté mer, face au public)
	_solid_model_v23(_add_glb("res://assets/models/props/Table_de_mixage.glb", "Table_de_mixage", Vector3(9, _height_at(9, 60) + 0.988, 60), 2.5, 0.0))
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
	_opaque_materials_v48(pc_hero)
	hero_mesh_floor_offset_v11 = _hero_foot_offset_v11()

	var hud := CanvasLayer.new()
	add_child(hud)
	hud_v28 = hud
	info = Label.new()
	info.text = "LES MONDES DE TRAVERS VR " + _version_v21() + "  |  ZQSD : marcher  •  Maj : courir  •  Espace : sauter / grimper  •  Ctrl : roulade  •  clic droit : caméra\nClic gauche : frapper  •  F : parer  •  E : ouvrir / ramasser  •  I : inventaire  •  molette : zoom  •  Échap : menu"
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
	_hud_v53(hud)


## V53 : les messages s'affichent dans un cadre centré en haut de l'écran, avec retour à la
## ligne ; l'aide des touches s'efface après 15 s de jeu (F1 pour la revoir).
var message_panel_v53: PanelContainer
var info_clock_v53: float = 15.0

func _hud_v53(hud: CanvasLayer) -> void:
	message_panel_v53 = PanelContainer.new()
	message_panel_v53.name = "Cadre_message_v53"
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.025, 0.08, 0.12, 0.82)
	st.border_color = Color(0.98, 0.76, 0.32, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 10
	st.content_margin_bottom = 12
	message_panel_v53.add_theme_stylebox_override("panel", st)
	message_panel_v53.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_panel_v53.offset_left = -460
	message_panel_v53.offset_right = 460
	message_panel_v53.offset_top = 64
	message_panel_v53.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_panel_v53.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel_v53.visible = false
	hud.add_child(message_panel_v53)
	message.get_parent().remove_child(message)
	message.position = Vector2.ZERO
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.custom_minimum_size = Vector2(876, 0)
	message.add_theme_font_size_override("font_size", 19)
	message.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88))
	message_panel_v53.add_child(message)
	info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	info.add_theme_constant_override("outline_size", 4)


func _hud_tick_v53(delta: float) -> void:
	if message_panel_v53 != null:
		var covered: bool = (inventory_v28 != null and inventory_v28.opened) or (game_menu != null and game_menu.opened and game_started)
		message_panel_v53.visible = message.visible and message.text != "" and not covered
	if info == null or xr_active:
		return
	var playing: bool = game_started and game_menu != null and not game_menu.opened
	if playing and info_clock_v53 > 0.0:
		info_clock_v53 -= delta
	var target: float = 1.0 if (not playing or info_clock_v53 > 0.0) else 0.0
	info.modulate.a = move_toward(info.modulate.a, target, delta * 1.5)


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
		info.text = "LES MONDES DE TRAVERS PC " + _version_v21() + "  |  ZQSD : marcher  •  Maj : courir  •  Espace : sauter / grimper  •  Ctrl : roulade  •  clic droit : caméra\nClic gauche : frapper  •  F : parer  •  E : ouvrir / ramasser  •  I : inventaire  •  molette : zoom  •  Échap : menu  •  G : appeler l'aigle  •  F11 : plein écran  •  F1 : aide"
		message.text = "Mode PC classique — F11 plein écran • F6 netteté ultra (GPU) • aucun casque requis."
		message_clock_v28 = 6.0
		xr_restart_button.visible = false
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
	game_menu.save_requested.connect(func(s: int):
		if _save_slot(s):
			_show_message_v28("Partie sauvegardée (emplacement %d)." % s))
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
	_reset_session_v48()
	# V81 : on charge une partie depuis une maison : on la démonte d'abord
	if maisons_v81 != null and maisons_v81.inside:
		maisons_v81._teardown()
	# V83 : le mode testeur ne survit pas à un changement de partie
	if testeur_v78 != null:
		testeur_v78.invincible = false
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
		pending_pnj_v31 = {}
		for npc in npcs_v31:
			npc.brain.reset()
		Societe_v65.load_data({})
		if objets_v66 != null:
			objets_v66.load_data({})
		if fishing_v32 != null:
			fishing_v32.cancel("")
			fishing_v32.load_data({})
		if digging_v33 != null:
			digging_v33.load_data({})
		if bucheron_v34 != null:
			bucheron_v34.load_data({})
		if donjon_v35 != null:
			donjon_v35.load_data({})
		if elfes_v41 != null:
			elfes_v41.load_data({})
		if nains_v46 != null:
			nains_v46.load_data({})
		if ciel_v54 != null:
			ciel_v54.load_data({})
		if mer_v55 != null:
			mer_v55.load_data({})
		if temps_v56 != null:
			temps_v56.load_data({})
		if azur_v56 != null:
			azur_v56.load_data({})
		if journal_v56 != null:
			journal_v56.load_data({})
		if feerie_v58 != null:
			feerie_v58.load_data({})
		if grande_v59 != null:
			grande_v59.load_data({})
		if arcanelle_v67 != null and arcanelle_v67.bourg != null:
			arcanelle_v67.load_data({})
		if pirates_v68 != null and pirates_v68.port != null:
			pirates_v68.load_data({})
		if soleils_v69 != null and soleils_v69.egypte != null:
			soleils_v69.load_data({})
		if braise_v70 != null and braise_v70.city != null:
			braise_v70.load_data({})
		if montjoie_v71 != null and montjoie_v71.city != null:
			montjoie_v71.load_data({})
		if boucan_v75 != null and boucan_v75.city != null:
			boucan_v75.load_data({})
		if astralys_v76 != null and astralys_v76.city != null:
			astralys_v76.load_data({})
		if moai_v87 != null and moai_v87.ile != null:
			moai_v87.load_data({})
		if compagnons_animaux_v76 != null:
			compagnons_animaux_v76.load_data({})
		if aeronef_v76 != null:
			aeronef_v76.load_data({})
		if chantier_v76 != null:
			chantier_v76.load_data({})
		if atelier_ailes_v76 != null:
			atelier_ailes_v76.load_data({})
		if maisons_v81 != null:
			maisons_v81.load_data({})
		if sorts_v67 != null:
			sorts_v67.load_data({})
		if teleport_v58 != null:
			teleport_v58.load_data({})
		if sceaux_v63 != null:
			sceaux_v63.load_data({})
		if coeur_v63 != null:
			coeur_v63.load_data({})
		if progression_v63 != null:
			progression_v63.load_data({})
		vr_ladder_v33 = {}
		_save_slot(slot)
	else:
		var data: Dictionary = SaveStore.read_slot(slot)
		var a: Array = data.get("position", [])
		if a.size() == 3:
			origin.position = Vector3(float(a[0]), float(a[1]), float(a[2]))
			# V63 : partie sauvée sous le Cœur-de-Pierre : le donjon doit être là avant d'y poser le pied
			if coeur_v63 != null and coeur_v63.region_contains(origin.position):
				coeur_v63.ensure_built()
			# V69 : partie sauvée dans un des trois grands donjons de l'Île des Trois Soleils
			if soleils_v69 != null and soleils_v69.egypte != null:
				soleils_v69.ensure_dungeon_at(origin.position)
			# V70 : partie sauvée dans les Neuf Cercles (sous la Cathédrale-Forge de Pandémonia)
			if braise_v70 != null and braise_v70.city != null:
				braise_v70.ensure_dungeon_at(origin.position)
			# V71 : partie sauvée dans le Donjon des Mille Marches (sous la tour en ruine des Crocs)
			if montjoie_v71 != null and montjoie_v71.city != null:
				montjoie_v71.ensure_dungeon_at(origin.position)
			# V75 : partie sauvée dans l'Usine Grise (sous l'usine de Lisse & Fils)
			if boucan_v75 != null and boucan_v75.city != null:
				boucan_v75.ensure_dungeon_at(origin.position)
		origin.rotation.y = float(data.get("yaw", 0.0))
		game_menu.seconds = float(data.get("play_seconds", 0.0))
		# V28 : inventaire et vie (absents des sauvegardes plus anciennes).
		if inventory_v28 != null:
			var inv_data: Variant = data.get("inventaire", {})
			if inv_data is Dictionary:
				inventory_v28.load_data(inv_data)
		if hero_v28 != null:
			hero_v28.set_health(int(data.get("vie", hero_v28.HP_MAX)))
		var pnj_data: Variant = data.get("pnj", {})
		pending_pnj_v31 = pnj_data if pnj_data is Dictionary else {}
		var soc_data: Variant = data.get("societe", {})
		Societe_v65.load_data(soc_data if soc_data is Dictionary else {})
		if objets_v66 != null:
			var ob_data: Variant = data.get("objets", {})
			objets_v66.load_data(ob_data if ob_data is Dictionary else {})
		if fishing_v32 != null:
			var fish_data: Variant = data.get("peche", {})
			fishing_v32.cancel("")
			fishing_v32.load_data(fish_data if fish_data is Dictionary else {})
		if digging_v33 != null:
			var dig_data: Variant = data.get("fouilles", {})
			digging_v33.load_data(dig_data if dig_data is Dictionary else {})
		if bucheron_v34 != null:
			var wood_data: Variant = data.get("bois", {})
			bucheron_v34.load_data(wood_data if wood_data is Dictionary else {})
		if donjon_v35 != null:
			var temple_data: Variant = data.get("donjon", {})
			donjon_v35.load_data(temple_data if temple_data is Dictionary else {})
		vr_ladder_v33 = {}
		for npc in npcs_v31:
			var one: Variant = pending_pnj_v31.get(str(npc.profile["id"]), {})
			npc.load_data(one if one is Dictionary else {})
		if elfes_v41 != null:
			var elf_data: Variant = data.get("elfes", {})
			elfes_v41.load_data(elf_data if elf_data is Dictionary else {})
		if nains_v46 != null:
			var dwarf_data: Variant = data.get("nains", {})
			nains_v46.load_data(dwarf_data if dwarf_data is Dictionary else {})
		if boat_v29 != null:
			var boat_data: Variant = data.get("bateau", {})
			boat_v29.driving = false
			boat_v29.load_data(boat_data if boat_data is Dictionary else {})
			# V76 : les évolutions du bateau (le chantier naval de Port-Azur)
			if chantier_v76 != null:
				var ch_data: Variant = data.get("chantier", {})
				chantier_v76.load_data(ch_data if ch_data is Dictionary else {})
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
	# V54 : Ventaile et la Citadelle (en dernier : on peut reprendre un vol en cours)
	if not new_game and ciel_v54 != null:
		var sky_data: Variant = SaveStore.read_slot(slot).get("ciel", {})
		ciel_v54.load_data(sky_data if sky_data is Dictionary else {})
	# V55 : la mer et l'Atlantide (après le ciel : le masque est dans le trésor de Sire Orage)
	if not new_game and mer_v55 != null:
		var sea_data: Variant = SaveStore.read_slot(slot).get("mer", {})
		mer_v55.load_data(sea_data if sea_data is Dictionary else {})
	# V56 : l'heure du jeu
	if not new_game and temps_v56 != null:
		var time_data: Variant = SaveStore.read_slot(slot).get("temps", {})
		temps_v56.load_data(time_data if time_data is Dictionary else {})
	# V56 : Port-Azur, le bateau de ligne, le carnet de quêtes (bonus, réputation, titres)
	if not new_game and azur_v56 != null:
		var azur_data: Variant = SaveStore.read_slot(slot).get("azur", {})
		azur_v56.load_data(azur_data if azur_data is Dictionary else {})
	if not new_game and journal_v56 != null:
		var jdata: Variant = SaveStore.read_slot(slot).get("journal", {})
		journal_v56.load_data(jdata if jdata is Dictionary else {})
	# V58 : le royaume des fées, la magie de téléportation (après le carnet de quêtes)
	if not new_game and feerie_v58 != null:
		var fdata: Variant = SaveStore.read_slot(slot).get("feerie", {})
		feerie_v58.load_data(fdata if fdata is Dictionary else {})
	# V59 : la grande île de l'est
	if not new_game and grande_v59 != null:
		var gdata: Variant = SaveStore.read_slot(slot).get("grande", {})
		grande_v59.load_data(gdata if gdata is Dictionary else {})
	# V67 : Arcanelle (leçons, braseros, runes, chouette, cérémonie) et les sorts appris
	if not new_game and arcanelle_v67 != null and arcanelle_v67.bourg != null:
		var adata67: Variant = SaveStore.read_slot(slot).get("arcanelle", {})
		arcanelle_v67.load_data(adata67 if adata67 is Dictionary else {})
	# V68 : l'Île de la Balafre (champions, perroquet, Vieille-Dent, le Capitaine, le trésor, le tatouage)
	if not new_game and pirates_v68 != null and pirates_v68.port != null:
		var bdata68: Variant = SaveStore.read_slot(slot).get("balafre", {})
		pirates_v68.load_data(bdata68 if bdata68 is Dictionary else {})
	# V69 : l'Île des Trois Soleils (le Sphinx, les donjons, les reliques, l'autel)
	if not new_game and soleils_v69 != null and soleils_v69.egypte != null:
		var sdata69: Variant = SaveStore.read_slot(slot).get("soleils", {})
		soleils_v69.load_data(sdata69 if sdata69 is Dictionary else {})
	# V70 : l'Île de Braise (le Cœur-Brasier, les Neuf Cercles, le tournoi, les lanternes, la fête)
	if not new_game and braise_v70 != null and braise_v70.city != null:
		var bdata70: Variant = SaveStore.read_slot(slot).get("braise", {})
		braise_v70.load_data(bdata70 if bdata70 is Dictionary else {})
	# V71 : l'Île de Montjoie (la Guilde, les compagnons, la Chaumière, le Donjon des Mille Marches)
	if not new_game and montjoie_v71 != null and montjoie_v71.city != null:
		var mdata71: Variant = SaveStore.read_slot(slot).get("montjoie", {})
		montjoie_v71.load_data(mdata71 if mdata71 is Dictionary else {})
	# V75 : l'Île du Boucan (les concerts, les graffitis, les champignons, Sardine, l'Usine Grise)
	if not new_game and boucan_v75 != null and boucan_v75.city != null:
		var bdata75: Variant = SaveStore.read_slot(slot).get("boucan", {})
		boucan_v75.load_data(bdata75 if bdata75 is Dictionary else {})
	# V76 : Astralys, l'île flottante des Lumens
	if not new_game and astralys_v76 != null and astralys_v76.city != null:
		var adata76: Variant = SaveStore.read_slot(slot).get("astralys", {})
		astralys_v76.load_data(adata76 if adata76 is Dictionary else {})
	# V87 : l'Île aux Moaïs
	if not new_game and moai_v87 != null and moai_v87.ile != null:
		var modata87: Variant = SaveStore.read_slot(slot).get("moai", {})
		moai_v87.load_data(modata87 if modata87 is Dictionary else {})
	# V76 : les compagnons animaux (Sardine, Brioche, Biscotte, Truffe)
	if not new_game and compagnons_animaux_v76 != null:
		var cdata76: Variant = SaveStore.read_slot(slot).get("compagnons", {})
		compagnons_animaux_v76.load_data(cdata76 if cdata76 is Dictionary else {})
	# V76 : l'aéronef et l'Atelier des Ailes (après le ciel : on peut reprendre un vol en cours)
	if not new_game and atelier_ailes_v76 != null:
		var adata_at: Variant = SaveStore.read_slot(slot).get("atelier_ailes", {})
		atelier_ailes_v76.load_data(adata_at if adata_at is Dictionary else {})
	# V81 : ce dont les maisons se souviennent (coffres ouverts, gens qui nous ont mis dehors…)
	if not new_game and maisons_v81 != null:
		var mdata81: Variant = SaveStore.read_slot(slot).get("maisons", {})
		maisons_v81.load_data(mdata81 if mdata81 is Dictionary else {})
	if not new_game and aeronef_v76 != null:
		var adata_ae: Variant = SaveStore.read_slot(slot).get("aeronef", {})
		aeronef_v76.load_data(adata_ae if adata_ae is Dictionary else {})
	if not new_game and sorts_v67 != null:
		var sdata67: Variant = SaveStore.read_slot(slot).get("sorts", {})
		sorts_v67.load_data(sdata67 if sdata67 is Dictionary else {})
	if not new_game and teleport_v58 != null:
		var tdata: Variant = SaveStore.read_slot(slot).get("teleport", {})
		teleport_v58.load_data(tdata if tdata is Dictionary else {})
	# V63 : la grande enquête, le donjon, puis la progression (après le carnet : elle ajoute ses
	# points aux bonus des quêtes)
	if not new_game:
		var saved63: Dictionary = SaveStore.read_slot(slot)
		if sceaux_v63 != null:
			var sd63: Variant = saved63.get("sceaux", {})
			sceaux_v63.load_data(sd63 if sd63 is Dictionary else {})
		if coeur_v63 != null:
			var cd63: Variant = saved63.get("coeur", {})
			coeur_v63.load_data(cd63 if cd63 is Dictionary else {})
		if progression_v63 != null:
			var pd63: Variant = saved63.get("progression", {})
			progression_v63.load_data(pd63 if pd63 is Dictionary else {})
	if pouvoirs_v63 != null:
		pouvoirs_v63.reset()
	if journal_v56 != null:
		journal_v56.respawn_pickups()
	# V72 : la vie sauvée, rendue une fois les cœurs maximum connus (le chargement soignait le héros)
	if not new_game and hero_v28 != null:
		var vie72: Variant = SaveStore.read_slot(slot).get("vie", null)
		if vie72 != null:
			hero_v28.set_health(clampi(int(vie72), 1, int(hero_v28.HP_MAX)))
	last_ok_v29.clear()
	autosave_clock = 0.0


## V48 : avant de charger une partie (ou d'en commencer une), on referme tout ce qui venait
## de la précédente : inventaire, dialogue, pêche, monstres du souterrain.
func _reset_session_v48() -> void:
	if dialogue_v31 != null and dialogue_v31.opened:
		_close_dialogue_v31()
	if talking_npc_v31 != null:
		talking_npc_v31.end_talk()
	talking_npc_v31 = null
	if inventory_v28 != null and inventory_v28.opened:
		inventory_v28.close()
	if fishing_v32 != null:
		fishing_v32.cancel("")
	if monstres_v36 != null:
		monstres_v36.reset_session()


func _delete_slot(slot: int) -> void:
	print("ILE_MANGA_DELETE: ", slot, " = ", SaveStore.delete_slot(slot))


func _save_slot(slot: int) -> bool:
	if not game_started:
		return false
	var origin: Node3D = xr_origin if xr_active else pc_root
	var extra: Dictionary = {}
	if inventory_v28 != null:
		extra["inventaire"] = inventory_v28.serialize()
	if hero_v28 != null:
		extra["vie"] = hero_v28.hp
	if boat_v29 != null:
		extra["bateau"] = boat_v29.serialize()
	var pnj := {}
	for npc in npcs_v31:
		pnj[str(npc.profile["id"])] = npc.serialize()
	for id in pending_pnj_v31:
		if not pnj.has(id):
			pnj[id] = pending_pnj_v31[id]
	extra["pnj"] = pnj
	extra["societe"] = Societe_v65.serialize()
	if objets_v66 != null:
		extra["objets"] = objets_v66.serialize()
	if fishing_v32 != null:
		extra["peche"] = fishing_v32.serialize()
	if digging_v33 != null:
		extra["fouilles"] = digging_v33.serialize()
	if bucheron_v34 != null:
		extra["bois"] = bucheron_v34.serialize()
	if donjon_v35 != null:
		extra["donjon"] = donjon_v35.serialize()
	if elfes_v41 != null:
		extra["elfes"] = elfes_v41.serialize()
	if nains_v46 != null:
		extra["nains"] = nains_v46.serialize()
	if ciel_v54 != null:
		extra["ciel"] = ciel_v54.serialize()
	if mer_v55 != null:
		extra["mer"] = mer_v55.serialize()
	if temps_v56 != null:
		extra["temps"] = temps_v56.serialize()
	if azur_v56 != null:
		extra["azur"] = azur_v56.serialize()
	if journal_v56 != null:
		extra["journal"] = journal_v56.serialize()
	if feerie_v58 != null:
		extra["feerie"] = feerie_v58.serialize()
	if grande_v59 != null:
		extra["grande"] = grande_v59.serialize()
	if arcanelle_v67 != null and arcanelle_v67.bourg != null:
		extra["arcanelle"] = arcanelle_v67.serialize()
	if sorts_v67 != null:
		extra["sorts"] = sorts_v67.serialize()
	if pirates_v68 != null and pirates_v68.port != null:
		extra["balafre"] = pirates_v68.serialize()
	if soleils_v69 != null and soleils_v69.egypte != null:
		extra["soleils"] = soleils_v69.serialize()
	if braise_v70 != null and braise_v70.city != null:
		extra["braise"] = braise_v70.serialize()
	if montjoie_v71 != null and montjoie_v71.city != null:
		extra["montjoie"] = montjoie_v71.serialize()
	if boucan_v75 != null and boucan_v75.city != null:
		extra["boucan"] = boucan_v75.serialize()
	if astralys_v76 != null and astralys_v76.city != null:
		extra["astralys"] = astralys_v76.serialize()
	if moai_v87 != null and moai_v87.ile != null:
		extra["moai"] = moai_v87.serialize()
	if compagnons_animaux_v76 != null:
		extra["compagnons"] = compagnons_animaux_v76.serialize()
	if aeronef_v76 != null:
		extra["aeronef"] = aeronef_v76.serialize()
	if chantier_v76 != null:
		extra["chantier"] = chantier_v76.serialize()
	if atelier_ailes_v76 != null:
		extra["atelier_ailes"] = atelier_ailes_v76.serialize()
	if maisons_v81 != null:
		extra["maisons"] = maisons_v81.serialize()
	if teleport_v58 != null:
		extra["teleport"] = teleport_v58.serialize()
	# V63 : la progression du héros, la grande enquête des sceaux, le donjon du Cœur-de-Pierre
	if progression_v63 != null:
		extra["progression"] = progression_v63.serialize()
	if sceaux_v63 != null:
		extra["sceaux"] = sceaux_v63.serialize()
	if coeur_v63 != null:
		extra["coeur"] = coeur_v63.serialize()
	# V72 : une île dont la ville n'est pas (encore) construite garde ce que disait la sauvegarde
	# précédente, au lieu de disparaître du fichier
	var prev: Dictionary = {}
	for k in ["azur", "grande", "arcanelle", "balafre", "soleils", "braise", "montjoie", "feerie", "journal", "progression", "sceaux", "coeur"]:
		if not extra.has(k):
			if prev.is_empty():
				prev = SaveStore.read_slot(slot)
				if prev.is_empty() and game_menu != null and game_menu.active_slot != slot:
					prev = SaveStore.read_slot(game_menu.active_slot)
			if prev.has(k):
				extra[k] = prev[k]
	var save_pos: Vector3 = origin.position
	if grande_v59 != null and grande_v59.riding():
		save_pos = grande_v59.ride_safe_pos()
	# V72 : à bord de L'Hirondelle, on se réveillera sur le quai d'arrivée (pas en pleine mer)
	if azur_v56 != null and azur_v56.get("ferry") != null and azur_v56.ferry != null and bool(azur_v56.ferry.riding) and teleport_v58 != null:
		var side: String = str(azur_v56.ferry.dest) if str(azur_v56.ferry.at) == "" else str(azur_v56.ferry.at)
		var sp: Array = teleport_v58.spot("azur" if side == "azur" else "village")
		if sp.size() == 2:
			save_pos = sp[0]
	# V81 : dans une maison, on se réveillera devant sa porte
	if maisons_v81 != null and maisons_v81.inside:
		save_pos = maisons_v81.outside_pos()
	var ok: bool = SaveStore.write_slot(slot, save_pos, origin.rotation.y, game_menu.seconds, extra)
	print("ILE_MANGA_SAVE: ", slot, " = ", ok)
	# V83 : une sauvegarde ratée se voit (la sauvegarde automatique aussi, si elle échoue)
	if not ok:
		_show_message_v28("La sauvegarde a échoué (disque plein ou dossier protégé ?). Ta partie précédente est intacte.")
	return ok


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
	if aeronef_v76 != null and aeronef_v76.riding:
		# V76 : à bord de son aéronef (de l'Alouette au Glisseur stellaire)
		aeronef_v76.ride_tick(delta)
	elif ciel_v54 != null and ciel_v54.riding:
		# V54 : en vol sur Ventaile
		ciel_v54.ride_tick(delta)
	elif azur_v56 != null and azur_v56.ferry != null and azur_v56.ferry.riding:
		# V56 : passager de L'Hirondelle (le bateau nous porte, voir ferry_v56.gd)
		if xr_active and inventory_v28 != null and inventory_v28.opened:
			inventory_v28.vr_tick(0.0, 0.0, 0.0)
	elif grande_v59 != null and grande_v59.riding():
		# V61 : passager du Zéphyr ou du téléphérique de Cliquetis (ils nous portent) ; V62 : la
		# nacelle et la tyrolienne de Ramure
		if xr_active:
			var trig_ride: bool = right_hand.get_float("trigger") > 0.8
			if trig_ride and not bool(vr_buttons_v28.get("ride_v61", false)):
				grande_v59.ride_interact()
			vr_buttons_v28["ride_v61"] = trig_ride
	elif xr_active:
		if boat_v29 != null and boat_v29.driving:
			_drive_boat_vr_v29(delta)
		elif not vr_ladder_v33.is_empty():
			_vr_ladder_tick_v33(delta)
		elif dialogue_v31 != null and dialogue_v31.opened:
			dialogue_v31.vr_tick(right_hand.get_vector2("primary").y, right_hand.get_float("trigger"), right_hand.is_button_pressed("by_button"))
		else:
			# V55 : dans l'eau, on nage (voir mer_v55.gd) ; sinon on marche
			if mer_v55 == null or not mer_v55.vr_swim_tick(delta):
				_move_xr(delta)
			_vr_actions_v28(delta)
	else:
		_move_desktop(delta)
	if message_clock_v28 > 0.0:
		message_clock_v28 -= delta
		if message_clock_v28 <= 0.0 and message != null:
			message.text = ""
	_hud_tick_v53(delta)


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
		if (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened):
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
	axis = (axis + pad_move_v74()).limit_length(1.0)
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
	if body.position.y < ground - 0.7 and not _in_dungeon_v35(body.position):
		# Single rescue outside the surface; capsule must start above the terrain.
		body.global_position = Vector3(body.position.x, ground + 1.15, body.position.z)
		body.velocity = Vector3.ZERO
	body.velocity.x = offset.x / dt
	body.velocity.z = offset.z / dt
	# V28 : au sol on reste collé, sauf au moment d'un saut (vitesse vers le haut).
	# V67 : pendant le sort de lévitation, on monte, on plane, puis on redescend doucement.
	if sorts_v67 != null and sorts_v67.levitating():
		body.velocity.y = sorts_v67.lev_vy(body.velocity.y, dt, body.is_on_floor())
	elif body.is_on_floor() and body.velocity.y <= 0.0:
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
		if not _in_dungeon_v35(pos_vr):
			pos_vr.y = maxf(pos_vr.y, _height_at(pos_vr.x, pos_vr.z) + 0.9)
		vr_body.global_position = pos_vr
		vr_body.velocity = Vector3.ZERO
		xr_origin.position = pos_vr
	if pc_body != null:
		var pos_pc: Vector3 = pc_root.position
		if not _in_dungeon_v35(pos_pc):
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
		elif inventory_v28 != null and inventory_v28.opened and inventory_v28.carnet != null and inventory_v28.carnet.handle_key(_digit_key_v80(event)):
			pass
		elif (event.keycode == KEY_I or event.keycode == KEY_TAB) and game_started and inventory_v28 != null and not game_menu.opened and (dialogue_v31 == null or not dialogue_v31.opened):
			inventory_v28.toggle(0)
		elif (event.keycode == KEY_J or event.keycode == KEY_M or event.keycode == KEY_P) and game_started and inventory_v28 != null and not game_menu.opened and (dialogue_v31 == null or not dialogue_v31.opened):
			# V56 : J les quêtes, M la carte, P les personnages
			inventory_v28.toggle({KEY_J: 1, KEY_M: 2, KEY_P: 3}[event.keycode])
		elif event.keycode == KEY_G and game_started and ciel_v54 != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened):
			ciel_v54.call_eagle()
		elif event.keycode == KEY_N and game_started and aeronef_v76 != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened):
			# V76 : appeler son aéronef (ou déplier l'Alouette)
			aeronef_v76.call_vehicle()
		elif event.keycode == KEY_T and game_started and teleport_v58 != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened):
			open_teleport_v58()
		elif event.keycode == KEY_H and game_started and inventory_v28 != null and not game_menu.opened and (dialogue_v31 == null or not dialogue_v31.opened):
			# V63 : H, le carnet ouvert sur la page du héros (niveau, talents, équipement, sceaux)
			inventory_v28.toggle(4)
		elif progression_v63 != null and not event.echo and game_started and not xr_active and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened) and progression_v63.handle_key(_digit_key_v80(event)):
			# V63 : 1 à 4 choisissent le pouvoir d'un sceau, X le lance
			pass
		elif sorts_v67 != null and not event.echo and game_started and not xr_active and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened) and sorts_v67.handle_key(_digit_key_v80(event)):
			# V67 : 5 à 0 choisissent un sort d'Arcanelle, V le lance, B passe au suivant
			pass
		elif event.keycode == KEY_F1 and info != null:
			info_clock_v53 = 0.0 if info.modulate.a > 0.5 else 1e9
		elif event.keycode == KEY_F5 and game_started:
			if _save_slot(game_menu.active_slot):
				_show_message_v28("Partie sauvegardée (emplacement %d)." % game_menu.active_slot)
		elif event.keycode == KEY_F9 and game_started:
			game_menu.open_menu()
		elif event.keycode == KEY_F8 and game_started and testeur_v78 != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened):
			# V78 : le mode testeur (se téléporter n'importe où, l'heure, invincible…)
			testeur_v78.open_menu()
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
	if vr_body.position.y < ground - 0.7 and not _in_dungeon_v35(vr_body.position):
		vr_body.global_position = Vector3(vr_body.position.x, ground + 1.15, vr_body.position.z)
		vr_body.velocity = Vector3.ZERO
	vr_body.velocity.x = wanted.x / dt
	vr_body.velocity.z = wanted.z / dt
	if sorts_v67 != null and sorts_v67.levitating():
		vr_body.velocity.y = sorts_v67.lev_vy(vr_body.velocity.y, dt, vr_body.is_on_floor())
	elif vr_body.is_on_floor() and vr_body.velocity.y <= 0.0:
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
	# V53 : flammes orangées moins nombreuses (l'addition des particules ne sature plus en
	# une boule blanche quand il n'y a pas de modèle de feu dessous).
	var flames := Gradient.new()
	flames.set_color(0, Color(1.0, 0.7, 0.3, 0.0))
	flames.add_point(0.12, Color(1.0, 0.55, 0.16, 0.32))
	flames.add_point(0.5, Color(0.9, 0.26, 0.05, 0.24))
	flames.set_color(flames.get_point_count() - 1, Color(0.35, 0.05, 0.02, 0.0))
	_particles_v24("Flammes_v24", at, 40, 0.8, 0.42, flames, true, Vector2(0.6, 1.3), 0.22)
	var embers := Gradient.new()
	embers.set_color(0, Color(1.0, 0.7, 0.3, 1.0))
	embers.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	_particles_v24("Braises_v24", at + Vector3.UP * 0.3, 24, 2.2, 0.05, embers, true, Vector2(1.0, 2.2), 0.3)
	# V53 : volutes claires qui montent et s'élargissent (plus de boule grise).
	preload("res://scripts/decor_v53.gd").smoke(self, at + Vector3.UP * 1.3)


# V27 : position du joueur (tête en VR, corps au PC) pour les portes.
func _player_pos_v27() -> Vector3:
	return xr_camera.global_position if xr_active else pc_root.global_position


func _doors_update_v27() -> void:
	if houses_v27 == null:
		return
	var playing: bool = game_started and game_menu != null and not game_menu.opened and (inventory_v28 == null or not inventory_v28.opened) and (dialogue_v31 == null or not dialogue_v31.opened)
	# V76 : à bord de l'aéronef
	if aeronef_v76 != null and aeronef_v76.riding:
		if door_prompt_v27 != null:
			door_prompt_v27.text = aeronef_v76.ride_prompt() if not xr_active else ""
		if donjon_v35 != null:
			donjon_v35.show_vr_hint(_player_pos_v27(), false)
		return
	# V54 : en vol, pas d'invites (E sert à se poser)
	if ciel_v54 != null and ciel_v54.riding:
		if door_prompt_v27 != null:
			door_prompt_v27.text = "E : se poser" if not xr_active else ""
		if donjon_v35 != null:
			donjon_v35.show_vr_hint(_player_pos_v27(), false)
		return
	# V61 : en dirigeable ou en téléphérique
	if grande_v59 != null and grande_v59.riding():
		if door_prompt_v27 != null:
			var rp: String = grande_v59.ride_prompt()
			door_prompt_v27.text = rp if not xr_active else rp.replace("E :", "Gâchette :")
		if donjon_v35 != null:
			donjon_v35.show_vr_hint(_player_pos_v27(), false)
		return
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
	var ladder: String = treehouse_v33.ladder_side(_player_pos_v27()) if playing and treehouse_v33 != null else ""
	if ladder != "" and not xr_active and hero_v28 != null and hero_v28.state in ["sol", "peche"]:
		text = "E : monter à l'échelle" if ladder == "bas" else "E : descendre l'échelle"
	if treehouse_v33 != null:
		treehouse_v33.show_vr_hint(ladder if xr_active and playing and vr_ladder_v33.is_empty() else "")
	# V35 : Temple englouti (invite PC ; en VR, étiquette et gâchette).
	var temple_text: String = donjon_v35.prompt(_player_pos_v27()) if playing and donjon_v35 != null else ""
	if temple_text != "" and not xr_active:
		text = temple_text
	if donjon_v35 != null:
		donjon_v35.show_vr_hint(_player_pos_v27(), xr_active and playing)
	if xr_active and playing and temple_text != "" and _nearest_npc_v31() == null:
		if right_hand.get_float("trigger") > 0.7 and trigger_ready_v27:
			donjon_v35.interact(_player_pos_v27())
		trigger_ready_v27 = right_hand.get_float("trigger") <= 0.7
		if door_prompt_v27 != null:
			door_prompt_v27.text = ""
		return
	if xr_active and playing and ladder != "" and vr_ladder_v33.is_empty() and _nearest_npc_v31() == null:
		if right_hand.get_float("trigger") > 0.7 and trigger_ready_v27:
			_vr_ladder_start_v33(ladder)
		trigger_ready_v27 = right_hand.get_float("trigger") <= 0.7
		if door_prompt_v27 != null:
			door_prompt_v27.text = ""
		return
	# V34 : cachette de trésor (pelle en main) ou arbre à abattre tout près.
	if playing and not xr_active:
		var dig_text: String = digging_v33.prompt(_player_pos_v27()) if digging_v33 != null else ""
		if dig_text != "":
			text = dig_text
		elif text == "" and bucheron_v34 != null:
			text = bucheron_v34.prompt(_player_pos_v27())
	var near_npc: Node3D = _nearest_npc_v31() if playing else null
	if near_npc != null and not xr_active:
		text = "E : parler à " + str(near_npc.display_name).split(" ")[0]
	if xr_active and playing and near_npc != null:
		if right_hand.get_float("trigger") > 0.7 and trigger_ready_v27:
			_talk_v31(near_npc)
		trigger_ready_v27 = right_hand.get_float("trigger") <= 0.7
		if door_prompt_v27 != null:
			door_prompt_v27.text = ""
		return
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
		# V48 : même soin en VR qu'au PC (avant, la VR consommait l'aliment sans soigner).
		return hero_v28.heal(half_hearts) if hero_v28 != null else false
	inventory_v28.drop_point = _drop_point_v28
	# V54 : la plume de Ventaile appelle l'aigle
	inventory_v28.use_tool = func(item_id: String) -> bool:
		if item_id == "plume_ventaile" and ciel_v54 != null:
			inventory_v28.close()
			ciel_v54.call_eagle()
			return true
		# V58 : le champignon de Lulu emmène au royaume des fées
		if item_id == "champignon_magique" and feerie_v58 != null:
			return feerie_v58.eat_mushroom()
		# V75 : les champignons féeriques de l'Île du Boucan
		if item_id.begins_with("champi_") and boucan_v75 != null and boucan_v75.city != null:
			return boucan_v75.eat_mushroom(item_id)
		# V76 : le sifflet des compagnons (« Qui vient avec moi ? »)
		if item_id == "sifflet_compagnons" and compagnons_animaux_v76 != null:
			return compagnons_animaux_v76.use_whistle(item_id)
		# V75 : un os à mâcher pour Sardine (s'il est là)
		if item_id == "os_sardine" and boucan_v75 != null and boucan_v75.chien != null and boucan_v75.chien.has_method("is_active") and boucan_v75.chien.is_active():
			inventory_v28.remove("os_sardine", 1)
			inventory_v28.close()
			_show_message_v28("Tu tends l'os à Sardine. Il le prend tout doucement, s'allonge à tes pieds et le mâchouille en grognant de bonheur. Sa queue balaie le sol : flap, flap, flap.")
			sfx("aboiement_petit", _player_pos_v27())
			return true
		return false
	combat_v28.build(self, inventory_v28)
	hero_v28 = preload("res://scripts/hero_v28.gd").new()
	hero_v28.name = "Heros_v28"
	add_child(hero_v28)
	hero_v28.setup(self, pc_body, pc_root, pc_hero, pc_camera)
	hero_v28.strike = combat_v28.strike
	hero_v28.fainted.connect(_respawn_v28)
	if not xr_active and hud_v28 != null:
		hero_v28.make_hud(hud_v28)
	dialogue_v31 = preload("res://scripts/pnj/dialogue_v31.gd").new()
	dialogue_v31.name = "Dialogue_v31"
	add_child(dialogue_v31)
	dialogue_v31.setup(xr_active)
	dialogue_v31.chosen.connect(_on_dialogue_choice_v31)
	# V32 : mode pêche (canne donnée par Barnabé).
	fishing_v32 = preload("res://scripts/fishing_v32.gd").new()
	fishing_v32.name = "Peche_v32"
	add_child(fishing_v32)
	fishing_v32.setup(self)
	# V33 : creuser avec la pelle.
	digging_v33 = preload("res://scripts/digging_v33.gd").new()
	digging_v33.name = "Fouilles_v33"
	add_child(digging_v33)
	digging_v33.setup(self)
	# V34 : bûcheronnage et traînée des coups de lame.
	bucheron_v34 = preload("res://scripts/bucheron_v34.gd").new()
	bucheron_v34.name = "Bucheron_v34"
	add_child(bucheron_v34)
	bucheron_v34.setup(self)
	trainee_v34 = preload("res://scripts/trainee_v34.gd").new()
	trainee_v34.name = "Trainee_v34"
	add_child(trainee_v34)
	trainee_v34.setup(self)
	donjon_v35 = preload("res://scripts/donjon_v35.gd").new()
	donjon_v35.name = "Temple_englouti_v35"
	add_child(donjon_v35)
	donjon_v35.setup(self)
	# V36 : les monstres du temple.
	monstres_v36 = preload("res://scripts/monstres_v36.gd").new()
	monstres_v36.name = "Monstres_v36"
	add_child(monstres_v36)
	monstres_v36.setup(self, donjon_v35)
	# Les objets se posent sur le sol réel : on attend que la physique soit prête.
	_spawn_world_v28.call_deferred()


func _spawn_world_v28() -> void:
	await get_tree().physics_frame
	# V77 : les lieux et chemins des habitants posés un peu sous le vrai sol (un môle, une marche,
	# un sentier, un pont…) remontent dessus : plus d'habitants enterrés jusqu'aux genoux
	_snap_spots_v77()
	inventory_v28.spawn_world()
	print("ILE_MANGA_V28: ", inventory_v28.pickups.size(), " objets à ramasser")
	_create_npcs_v31()
	# V56 : les habitants de Port-Azur (après Barnabé et Octave)
	_spawn_azur_v56()


const SEATED_V77 := ["assis", "boire", "prier", "lire", "dormir", "couche", "allonge", "pecher"]

func _snap_spots_v77() -> void:
	var space := get_world_3d().direct_space_state
	var moved: int = 0
	for node in get_children():
		for n in [node] + node.find_children("*", "Node3D", true, false):
			if n is CollisionObject3D or n is MeshInstance3D:
				continue
			for prop in ["spots", "points"]:
				var d: Variant = n.get(prop)
				if not (d is Dictionary):
					continue
				for k in (d as Dictionary).keys():
					var e: Variant = d[k]
					var is_spot: bool = e is Dictionary and (e as Dictionary).has("pos")
					var p: Variant = e["pos"] if is_spot else e
					if not (p is Vector3):
						continue
					if is_spot and str(e.get("pose", "")) in SEATED_V77:
						continue
					var y: float = _snap_y_v77(space, p)
					# V77 : un point de chemin pris dans un mur, une machine, un étal : on le pousse dehors
					var stuck_ok: bool = (prop == "points" and not str(k).begins_with("porte") and not str(k).begins_with("@") and not str(k).ends_with("_face")) or (is_spot and not (str(e.get("pose", "")) in ["comptoir", "dormir"]))
					if stuck_ok and _solid_at_v77(space, p + Vector3.UP * 0.35) and _solid_at_v77(space, p + Vector3.UP * 1.1):
						var free: Variant = _free_near_v77(space, p)
						if free is Vector3:
							if is_spot:
								e["pos"] = free
							else:
								d[k] = free
							moved += 1
							continue
					if y != (p as Vector3).y:
						moved += 1
						if is_spot:
							e["pos"] = Vector3(p.x, y, p.z)
						else:
							d[k] = Vector3(p.x, y, p.z)
	print("ILE_MANGA_V77: %d lieux d'habitants remontés sur le sol" % moved)


func _solid_at_v77(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var pq := PhysicsPointQueryParameters3D.new()
	pq.position = p
	pq.collision_mask = 1
	return not space.intersect_point(pq, 1).is_empty()


## La place libre la plus proche (jusqu'à 6 m) : debout, sans mur, avec un sol à moins de 0,6 m.
func _free_near_v77(space: PhysicsDirectSpaceState3D, p: Vector3) -> Variant:
	for r in [1.0, 1.6, 2.3, 3.0, 4.0, 5.0, 6.0]:
		for i in range(12):
			var a: float = TAU * i / 12.0
			var c: Vector3 = p + Vector3(cos(a) * r, 0.0, sin(a) * r)
			var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 0.9, c - Vector3.UP * 0.9, 1)
			var h: Dictionary = space.intersect_ray(q)
			if h.is_empty() or (h["normal"] as Vector3).y < 0.7:
				continue
			var f: Vector3 = h["position"]
			if absf(f.y - p.y) > 0.6:
				continue
			if _solid_at_v77(space, f + Vector3.UP * 0.35) or _solid_at_v77(space, f + Vector3.UP * 1.1) or _solid_at_v77(space, f + Vector3.UP * 1.7):
				continue
			return f
	return null


## Le sol juste au-dessus de p (0,12 à 0,75 m plus haut, avec de la place pour se tenir debout), ou p.y.
func _snap_y_v77(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.8, p - Vector3.UP * 0.3, 1)
	var h: Dictionary = space.intersect_ray(q)
	if h.is_empty():
		return p.y
	var fy: float = (h["position"] as Vector3).y
	var dy: float = fy - p.y
	if dy < 0.12 or dy > 0.75 or (h["normal"] as Vector3).y < 0.7:
		return p.y
	for up in [0.5, 1.2]:
		var pq := PhysicsPointQueryParameters3D.new()
		pq.position = Vector3(p.x, fy + up, p.z)
		pq.collision_mask = 1
		if not space.intersect_point(pq, 1).is_empty():
			return p.y
	return fy


func _show_message_v28(text: String) -> void:
	if message != null:
		message.text = text
		# V53 : le temps de lire (environ 20 lettres par seconde), entre 3 et 12 s
		message_clock_v28 = clampf(1.5 + text.length() * 0.05, 3.0, 12.0)


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
	# V76 : à bord de l'aéronef, E demande à se poser
	if aeronef_v76 != null and aeronef_v76.riding:
		aeronef_v76.request_landing()
		return
	# V54 : en vol, E demande à Ventaile de se poser
	if ciel_v54 != null and ciel_v54.riding:
		ciel_v54.request_landing()
		return
	if grande_v59 != null and grande_v59.riding():
		grande_v59.ride_interact()
		return
	var p: Vector3 = _player_pos_v27()
	var npc: Node3D = _nearest_npc_v31()
	# V56 : dans la foule de Port-Azur, un objet juste à nos pieds passe avant la conversation
	if npc != null and inventory_v28 != null:
		var pk: int = inventory_v28.nearest_pickup(p)
		if pk >= 0:
			var pd: float = inventory_v28.pickup_distance(pk, p)
			if pd < 1.4 and pd < Vector2(npc.global_position.x - p.x, npc.global_position.z - p.z).length():
				npc = null
	if npc != null and (boat_v29 == null or not boat_v29.driving):
		_talk_v31(npc)
		return
	# V56 : la cloche qui appelle L'Hirondelle
	if azur_v56 != null and azur_v56.ferry != null:
		var bell: String = azur_v56.ferry.bell_near(p)
		if bell != "":
			azur_v56.ferry.ring_bell(bell)
			return
	# V35 : trappes, braseros, coffre, fresque… du Temple englouti.
	if donjon_v35 != null and donjon_v35.interact(p):
		return
	# V33 : l'échelle de la cabane perchée.
	if treehouse_v33 != null and hero_v28 != null and hero_v28.state in ["sol", "peche"]:
		match treehouse_v33.ladder_side(p):
			"bas":
				hero_v28.climb_ladder(treehouse_v33.ladder_foot + Vector3.UP * 0.05, treehouse_v33.ladder_normal)
				_show_message_v28("Z pour monter, S pour descendre.")
				return
			"haut":
				hero_v28.climb_ladder(treehouse_v33.ladder_hang, treehouse_v33.ladder_normal)
				_show_message_v28("S pour descendre, Z pour remonter.")
				return
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
	# V63 : la lame trempée ou runique (forge) brille dans la main
	if progression_v63 != null:
		progression_v63.on_equip(item_id)


func _respawn_v28() -> void:
	if aeronef_v76 != null:
		aeronef_v76.force_end()
	if compagnons_animaux_v76 != null:
		compagnons_animaux_v76.on_faint()
	# V63 : évanoui sous le Cœur-de-Pierre (ou dans un sanctuaire des sceaux)
	if coeur_v63 != null and coeur_v63.region_contains(_player_pos_v27()):
		coeur_v63.respawn()
		return
	if sceaux_v63 != null and sceaux_v63.respawn_here(_player_pos_v27()):
		return
	# V69 : sur l'Île des Trois Soleils (dans un donjon : à son dernier point de reprise ; dehors : au village le plus proche)
	if soleils_v69 != null and soleils_v69.egypte != null and soleils_v69.owns_point(_player_pos_v27()):
		soleils_v69.on_faint(_player_pos_v27())
		return
	# V70 : sur l'Île de Braise (les Neuf Cercles : au dernier point de reprise ; l'arène ; dehors : la Grand-Place)
	if braise_v70 != null and braise_v70.city != null and braise_v70.owns_point(_player_pos_v27()):
		braise_v70.on_faint(_player_pos_v27())
		return
	# V71 : sur l'Île de Montjoie (le donjon : au dernier point de reprise ; dehors : la Grand-Place, ou son lit)
	if montjoie_v71 != null and montjoie_v71.city != null and montjoie_v71.owns_point(_player_pos_v27()):
		montjoie_v71.on_faint(_player_pos_v27())
		return
	# V76 : à Astralys (près du Portail d'accueil, Aurore veille)
	if astralys_v76 != null and astralys_v76.city != null and astralys_v76.owns_point(_player_pos_v27()):
		astralys_v76.on_faint(_player_pos_v27())
		return
	# V87 : sur l'Île aux Moaïs : sur la Plage Blanche
	if moai_v87 != null and moai_v87.ile != null and moai_v87.owns_point(_player_pos_v27()):
		moai_v87.on_faint(_player_pos_v27())
		return
	# V75 : sur l'Île du Boucan (l'usine : au dernier point de reprise ; dehors : la Place des Palettes)
	if boucan_v75 != null and boucan_v75.city != null and boucan_v75.owns_point(_player_pos_v27()):
		boucan_v75.on_faint(_player_pos_v27())
		return
	# V36 : évanoui dans le temple : on se réveille au pied de l'échelle la plus proche.
	if monstres_v36 != null and _in_dungeon_v35(_player_pos_v27()):
		monstres_v36.respawn_player()
		_show_message_v28("Vous vous êtes évanoui… et réveillé au pied de l'échelle.")
		return
	# V47 : sur l'île des nains, on se réveille sur la terrasse de Forgefer.
	var pp: Vector3 = _player_pos_v27()
	# V58 : au royaume des fées (ou dans Yggdrasil)
	if feerie_v58 != null and feerie_v58.contains(pp):
		var rf: Array = feerie_v58.respawn_point(pp)
		place_player_v35(rf[0], rf[1])
		_show_message_v28("Vous vous êtes évanoui… Des fées vous ont soigné avec de la rosée et des chansons.")
		return
	# V54 : sur l'île flottante, on se réveille sur l'Aire des Vents.
	if ciel_v54 != null and ciel_v54.on_sky(pp):
		var rs: Array = ciel_v54.respawn_point()
		place_player_v35(rs[0], rs[1])
		_show_message_v28("Vous vous êtes évanoui… et réveillé sur l'Aire des Vents, au bord de l'île flottante.")
		return
	# V55 : près de l'Atlantide, les Atlantes vous ramènent sous le dôme.
	if mer_v55 != null:
		var ra: Array = mer_v55.respawn_for(pp)
		if not ra.is_empty():
			place_player_v35(ra[0], ra[1])
			_show_message_v28("Vous vous êtes évanoui… Des Atlantes vous ont ramené sous le dôme, devant le palais.")
			return
	# V68 : sur l'Île de la Balafre (une bagarre perdue : sur le quai ; les monstres : chez le Doc)
	if pirates_v68 != null and pirates_v68.port != null and pirates_v68.contains(pp):
		pirates_v68.on_faint()
		return
	# V67 : à Arcanelle, Mère Sauge vous soigne ; on se réveille près de la fontaine du Fondateur
	if arcanelle_v67 != null and arcanelle_v67.bourg != null and arcanelle_v67.contains(pp):
		var rc: Array = arcanelle_v67.respawn_point()
		place_player_v35(rc[0], rc[1])
		_show_message_v28("Vous vous êtes évanoui… Mère Sauge vous a fait boire une tisane qui sentait le thym. Vous voilà sur la place du Chaudron, à Arcanelle.")
		return
	# V59 : sur la grande île, Anouk vous soigne ; on se réveille sur la plage de Carène
	if grande_v59 != null and grande_v59.contains(pp):
		var rg: Array = grande_v59.respawn_point(pp)
		place_player_v35(rg[0], rg[1])
		if grande_v59.ramure != null and grande_v59.ramure.contains(pp):
			_show_message_v28("Vous vous êtes évanoui… Pivoine, la renarde herboriste, vous a fait respirer une fiole de brume. Vous voilà au Cercle de la Lune.")
		elif grande_v59.cliquetis != null and grande_v59.cliquetis.contains(pp):
			_show_message_v28("Vous vous êtes évanoui… Le professeur Boum vous a ranimé avec une petite décharge (très petite). Vous voilà sur la promenade de Cliquetis.")
		elif grande_v59.tazira != null and grande_v59.tazira.contains(pp):
			_show_message_v28("Vous vous êtes évanoui… Zineb, la patronne du Fondouk, vous a fait boire un thé très sucré. Vous voilà sur la place des Lanternes.")
		else:
			_show_message_v28("Vous vous êtes évanoui… Anouk, la guérisseuse de Carène, vous a soigné avec des algues et du miel.")
		return
	# V56 : à Port-Azur, on se réveille sur la place de la Mairie
	if azur_v56 != null and azur_v56.ile != null and azur_v56.ile.contains(pp.x, pp.z):
		var rz: Array = azur_v56.respawn_point()
		place_player_v35(rz[0], rz[1])
		_show_message_v28("Vous vous êtes évanoui… Le docteur Roux vous a soigné. Vous voici sur la place de Port-Azur.")
		return
	if nains_v46 != null and nains_v46.ile != null and nains_v46.ile.contains(pp.x, pp.z):
		var rp: Array = nains_v46.respawn_point()
		place_player_v35(rp[0], rp[1])
		_show_message_v28("Vous vous êtes évanoui… Dagna vous a traîné jusqu'à la terrasse de Forgefer.")
		return
	pc_root.position = Vector3(2.0, maxf(0.0, _height_at(2.0, 8.0)), 8.0)
	_sync_physics_after_load_v11()
	# V52 : la barque laissée sur l'autre rive revient au ponton du village.
	if boat_v29 != null and boat_v29.return_home():
		_show_message_v28("Vous vous êtes évanoui… Vous voici de retour au village. Un pêcheur a ramené votre barque au ponton.")
		return
	_show_message_v28("Vous vous êtes évanoui… Vous voici de retour au village.")


## VR : A pour sauter (ou se hisser sur un rebord devant soi), Y pour l'inventaire,
## coups de poing ou d'épée en bougeant vite la main. Le déplacement au joystick ne change pas.
func _vr_actions_v28(delta: float) -> void:
	var a_now: bool = right_hand.is_button_pressed("ax_button")
	var y_now: bool = left_hand.is_button_pressed("by_button")
	# V54 : bouton X (main gauche) : appeler Ventaile
	# V76 : X bref = Ventaile (au relâchement) ; X maintenu 0,6 s = l'aéronef
	var x_now: bool = left_hand.is_button_pressed("ax_button")
	if x_now:
		vr_x_hold_v76 += delta
		if vr_x_hold_v76 >= 0.6 and not vr_buttons_v28.get("x_long", false):
			vr_buttons_v28["x_long"] = true
			if aeronef_v76 != null:
				aeronef_v76.call_vehicle()
	else:
		if vr_buttons_v28.get("x", false) and not vr_buttons_v28.get("x_long", false) and ciel_v54 != null:
			ciel_v54.call_eagle()
		vr_x_hold_v76 = 0.0
		vr_buttons_v28["x_long"] = false
	vr_buttons_v28["x"] = x_now
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
	# V63 : pouvoirs des sceaux (B), garde (grip gauche), esquive et tournoyante (clics des sticks)
	if progression_v63 != null:
		progression_v63.vr_tick(delta)
	# V67 : les sorts d'Arcanelle (gâchette gauche : lancer ; maintenue : sort suivant)
	if sorts_v67 != null:
		sorts_v67.vr_tick(delta)
	# V56 : gâchette près de la cloche du quai : appeler L'Hirondelle
	var trig_now: bool = right_hand.get_float("trigger") > 0.7
	if azur_v56 != null and azur_v56.ferry != null and trig_now and not vr_buttons_v28.get("cloche", false) and _nearest_npc_v31() == null:
		var bell_side: String = azur_v56.ferry.bell_near(_player_pos_v27())
		if bell_side != "":
			azur_v56.ferry.ring_bell(bell_side)
	vr_buttons_v28["cloche"] = trig_now
	if fishing_v32 != null:
		# Près d'une porte ou d'un habitant, la gâchette garde son usage ; sinon elle pêche.
		var free_hand: bool = fishing_v32.state != "repos" or (_door_distance_v28() > 2.0 and _nearest_npc_v31() == null)
		fishing_v32.vr_tick(right_hand.get_float("trigger") if fishing_v32.rod_in_hand() and free_hand else 0.0)
		# V33 : pelle en main, gâchette = creuser devant soi.
		var dig_now: bool = right_hand.get_float("trigger") > 0.7
		if digging_v33 != null and inventory_v28.equipped == "pelle" and free_hand and dig_now and not vr_buttons_v28.get("pelle", false):
			digging_v33.dig_vr()
		vr_buttons_v28["pelle"] = dig_now
	if combat_v28 != null:
		var armed: bool = inventory_v28 != null and inventory_v28.equipped != ""
		var points := {"gauche": [left_hand.global_position, 0.12, 1, left_hand.position]}
		if armed:
			var dmg: int = int(inventory_v28.ITEMS[inventory_v28.equipped].get("damage", 1)) + (int(journal_v56.bonus["force"]) if journal_v56 != null else 0)
			# V63 : la force gagnée en montant de niveau, la lame de la forge
			if progression_v63 != null and hero_v28 != null:
				dmg = hero_v28.damage_for(str(inventory_v28.equipped))
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
		if hero_v28 != null:
			hero_v28._double_used = false
	elif hero_v28 != null and hero_v28.talents.has("double_saut") and not hero_v28._double_used:
		# V63 : le double saut, en plein vol
		hero_v28._double_used = true
		vr_body.velocity.y = JUMP_SPEED_V28 * 0.95
		sfx("double_saut", vr_body.global_position + Vector3.UP * 0.5)


# =================================================================== V29 : île-jungle et bateau

func _create_jungle_v29() -> void:
	jungle_v29 = preload("res://scripts/jungle_v29.gd").new()
	jungle_v29.name = "Ile_jungle_v29"
	add_child(jungle_v29)
	jungle_v29.build_heights()
	# V31 : terrasse aplanie pour la cabane de Barnabé, avant de fabriquer le sol.
	cabin_spot_v31 = _cabin_spot_v31()
	if not cabin_spot_v31.is_empty():
		# La cabane suit la pente sur ses pilotis : le sol n'est pas retouché.
		pass
	# V33 : le grand fromager d'Octave, sur la côte est (de l'autre côté de l'île).
	tree_spot_v33 = _tree_spot_v33()
	jungle_v29.finish(OS.has_feature("ile_manga_pc"))
	# V30 : la forêt tropicale de l'île.
	var flora: Node3D = preload("res://scripts/jungle_flora_v30.gd").new()
	flora_v30 = flora
	flora.name = "Foret_jungle_v30"
	add_child(flora)
	if not cabin_spot_v31.is_empty():
		var lc: Vector3 = cabin_spot_v31["pos"] - jungle_v29.CENTER
		flora.clearings.append([Vector2(lc.x, lc.z) + Vector2(cabin_spot_v31["facing"].x, cabin_spot_v31["facing"].z) * 2.5, 9.5])
	if not tree_spot_v33.is_empty():
		var lt: Vector3 = tree_spot_v33["pos"] - jungle_v29.CENTER
		flora.clearings.append([Vector2(lt.x, lt.z) + Vector2(tree_spot_v33["facing"].x, tree_spot_v33["facing"].z) * 3.0, 13.0])
	# V34 : les cachettes de trésor de la jungle et le coffre de la Mouette sont choisis avant
	# de planter la forêt, pour qu'aucune fougère ne pousse sur leur croix de bois.
	_treasure_candidates_v34()
	# V35 : la tête de pierre et la trappe de la jungle, dans une petite clairière.
	trap_jungle_spot_v35 = _trap_jungle_spot_v35()
	if trap_jungle_spot_v35 != Vector3.INF:
		var lj: Vector3 = trap_jungle_spot_v35 - jungle_v29.CENTER
		flora.clearings.append([Vector2(lj.x, lj.z), 7.5])
	for q in treasure_jungle_v34:
		var lq: Vector3 = (q as Vector3) - jungle_v29.CENTER
		flora.clearings.append([Vector2(lq.x, lq.z), 2.6])
	if mouette_spot_v34 != Vector3.INF:
		var lm: Vector3 = mouette_spot_v34 - jungle_v29.CENTER
		flora.clearings.append([Vector2(lm.x, lm.z), 3.2])
	flora.build(jungle_v29, OS.has_feature("ile_manga_pc"))
	boat_v29 = preload("res://scripts/boat_v29.gd").new()
	boat_v29.name = "Bateau_v29"
	add_child(boat_v29)
	boat_v29.build(self, ISLAND_DOCK_V29, [jungle_v29.dock_start, jungle_v29.dock_end])
	# V41 : l'île des elfes (relief, forêt, village) et son ponton.
	elfes_v41 = preload("res://scripts/elfes_v41.gd").new()
	elfes_v41.name = "Elfes_v41"
	add_child(elfes_v41)
	elfes_v41.setup(self)
	elfes_v41.build_island()
	var ed: Array = elfes_v41.dock()
	boat_v29._make_dock("Ponton_elfes", ed[0], ed[1])
	# V46 : l'île volcanique des nains, cachée derrière les Récifs de Feu.
	nains_v46 = preload("res://scripts/nains_v46.gd").new()
	nains_v46.name = "Nains_v46"
	add_child(nains_v46)
	nains_v46.setup(self)
	nains_v46.build_island()
	var nd: Array = nains_v46.dock()
	boat_v29._make_dock("Ponton_nains", nd[0], nd[1])
	# V56 : Port-Azur (le relief d'abord ; la ville, ses habitants et le bateau de ligne
	# sont construits après l'heure du jour, voir _create_v56) ; ponton de L'Hirondelle au village.
	azur_v56 = preload("res://scripts/azur_v56.gd").new()
	azur_v56.name = "Port_Azur_v56"
	add_child(azur_v56)
	azur_v56.setup(self)
	azur_v56.build_island()
	boat_v29._make_dock("Ponton_ferry", FERRY_PIER_V56[0], FERRY_PIER_V56[1])
	# V59 : la grande île de l'est et l'épave du Léviathan (le relief d'abord ; Carène, ses
	# habitants et la végétation sont construits après l'heure du jour, voir _create_v59).
	grande_v59 = preload("res://scripts/grande_v59.gd").new()
	grande_v59.name = "Grande_ile_v59"
	add_child(grande_v59)
	grande_v59.setup(self)
	grande_v59.build_island()
	# V67 : Arcanelle, l'île des sorciers, au nord-ouest (le relief d'abord ; l'Académie, le
	# bourg, la communauté et les sorts sont construits après l'heure du jour, voir _create_v67).
	arcanelle_v67 = preload("res://scripts/arcanelle_v67.gd").new()
	arcanelle_v67.name = "Arcanelle_v67"
	add_child(arcanelle_v67)
	arcanelle_v67.setup(self)
	arcanelle_v67.build_island()
	var arc_d: Array = arcanelle_v67.dock()
	boat_v29._make_dock("Ponton_arcanelle", arc_d[0], arc_d[1])
	# V68 : l'Île de la Balafre, l'île des pirates, au nord (le relief d'abord ; Port-Coutelas,
	# ses navires, ses pirates et la jungle sont construits après l'heure du jour, voir _create_v68).
	pirates_v68 = preload("res://scripts/pirates_v68.gd").new()
	pirates_v68.name = "Pirates_v68"
	add_child(pirates_v68)
	pirates_v68.setup(self)
	pirates_v68.build_island()
	var pir_d: Array = pirates_v68.dock()
	boat_v29._make_dock("Ponton_balafre", pir_d[0], pir_d[1])
	# V69 : l'Île des Trois Soleils, la grande île verte de l'ouest (le relief d'abord ; les trois
	# villages, la végétation, les habitants et les donjons après l'heure du jour, voir _create_v69).
	soleils_v69 = preload("res://scripts/soleils_v69.gd").new()
	soleils_v69.name = "Soleils_v69"
	add_child(soleils_v69)
	soleils_v69.setup(self)
	soleils_v69.build_island()
	var sol_d: Array = soleils_v69.dock()
	boat_v29._make_dock("Ponton_soleils", sol_d[0], sol_d[1])
	# V70 : l'Île de Braise, l'île volcanique du sud-ouest, et Pandémonia, la cité des démons
	# gentils (le relief d'abord ; la cité, la végétation, la lave, les habitants, le donjon,
	# l'arène et la fête après l'heure du jour, voir _create_v70).
	braise_v70 = preload("res://scripts/braise_v70.gd").new()
	braise_v70.name = "Braise_v70"
	add_child(braise_v70)
	braise_v70.setup(self)
	braise_v70.build_island()
	var br_d: Array = braise_v70.dock()
	boat_v29._make_dock("Ponton_braise", br_d[0], br_d[1])
	# V71 : l'Île de Montjoie, à l'est de la grande île : la ville fortifiée sur la Butte, sa
	# Guilde des Aventuriers et son donjon (le relief d'abord ; la ville, la végétation, les
	# habitants, la Guilde, le donjon après l'heure du jour, voir _create_v71).
	montjoie_v71 = preload("res://scripts/montjoie_v71.gd").new()
	montjoie_v71.name = "Montjoie_v71"
	add_child(montjoie_v71)
	montjoie_v71.setup(self)
	montjoie_v71.build_island()
	var mj_d: Array = montjoie_v71.dock()
	boat_v29._make_dock("Ponton_montjoie", mj_d[0], mj_d[1])
	# V75 : l'Île du Boucan, au sud : Port-Boucan, la ville libre des punks dans la friche du vieux
	# port, et l'Usine Grise (le relief d'abord ; le reste après l'heure du jour, voir _create_v75).
	boucan_v75 = preload("res://scripts/boucan_v75.gd").new()
	boucan_v75.name = "Boucan_v75"
	add_child(boucan_v75)
	boucan_v75.setup(self)
	boucan_v75.build_island()
	var bo_d: Array = boucan_v75.dock()
	boat_v29._make_dock("Ponton_boucan", bo_d[0], bo_d[1])
	# V76 : Astralys, l'île flottante des Lumens, à 380 m au-dessus de la mer, au nord-ouest ; sur
	# la mer, en dessous, la Bouée d'accueil (son ponton) d'où le Rayon monte à la cité.
	astralys_v76 = preload("res://scripts/astrale_v76.gd").new()
	astralys_v76.name = "Astralys_v76"
	add_child(astralys_v76)
	astralys_v76.setup(self)
	astralys_v76.build_island()
	var as_d: Array = astralys_v76.dock()
	boat_v29._make_dock("Ponton_astralys", as_d[0], as_d[1])
	# V87 : l'Île aux Moaïs, au nord : les géants de pierre, la ronde des Moaïs habités, le Grand
	# Moaï (le relief d'abord ; les statues et la végétation après l'heure du jour, voir _create_v87).
	moai_v87 = preload("res://scripts/moai_v87.gd").new()
	moai_v87.name = "Moai_v87"
	add_child(moai_v87)
	moai_v87.setup(self)
	moai_v87.build_island()
	var mo_d: Array = moai_v87.dock()
	boat_v29._make_dock("Ponton_moai", mo_d[0], mo_d[1])


## À pied : on ne s'avance pas dans la mer (l'île du village garde sa limite ronde,
## la jungle bloque dès que l'eau devient profonde) ; les pontons restent accessibles.
func _limit_on_foot_v29(body: CharacterBody3D) -> void:
	var p: Vector3 = body.position
	# V35 : sous terre, les murs du temple suffisent.
	if _in_dungeon_v35(p):
		return
	var key: String = str(body.name)
	# V58 : au royaume des fées, on ne s'avance pas au-delà du bord (ni de la Couronne)
	if feerie_v58 != null and feerie_v58.contains(p):
		if feerie_v58.walkable_at(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V54 : sur l'île flottante, on ne s'avance pas au-delà du bord
	if ciel_v54 != null and ciel_v54.on_sky(p):
		if ciel_v54.walkable_at(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V55 : dans la mer, on nage où l'on veut (dans les limites du monde)
	if mer_v55 != null and mer_v55.water_ok(p):
		last_ok_v29[key] = p
		return
	if boat_v29 != null and boat_v29.on_dock(p):
		last_ok_v29[key] = p
		return
	# V67 : à Arcanelle, on ne marche pas dans l'eau du Lac Miroir (sauf sur la glace du sort de gel)
	if arcanelle_v67 != null and arcanelle_v67.contains(p) and arcanelle_v67.blocks_walk(p):
		if last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V76 : là-haut, à Astralys : le plateau, les îlots, les ponts de lumière (pas le vide)
	if astralys_v76 != null and astralys_v76.contains(p) and p.y > 150.0:
		if astralys_v76.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V87 : l'Île aux Moaïs : la terre ferme
	if moai_v87 != null and moai_v87.contains(p):
		if moai_v87.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V75 : l'Île du Boucan : la terre ferme, les quais, le pont du cargo (pas dans le bassin)
	if boucan_v75 != null and boucan_v75.contains(p):
		if boucan_v75.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V71 : l'Île de Montjoie : la terre ferme, les pontons, les quais (pas dans le lac)
	if montjoie_v71 != null and montjoie_v71.contains(p):
		if montjoie_v71.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V70 : l'Île de Braise : la terre ferme, les ponts, les quais (la lave : on y entre, elle brûle)
	if braise_v70 != null and braise_v70.contains(p):
		if braise_v70.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V69 : l'Île des Trois Soleils : la terre ferme, les ponts, les pontons (pas dans le lac)
	if soleils_v69 != null and soleils_v69.contains(p):
		if soleils_v69.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V68 : l'Île de la Balafre : la terre ferme, les navires, les pontons de Port-Coutelas
	if pirates_v68 != null and pirates_v68.contains(p):
		if pirates_v68.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	# V59 : la grande île : la terre ferme, le Léviathan et les pontons de Carène
	if grande_v59 != null and grande_v59.contains(p):
		if grande_v59.walkable(p):
			last_ok_v29[key] = p
		elif last_ok_v29.has(key):
			body.position = last_ok_v29[key]
			body.velocity = Vector3.ZERO
		return
	if jungle_v29 != null and Vector2(p.x, p.z).length() > 120.0:
		if _height_at(p.x, p.z) > -0.3:
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


## V35 : le joueur est-il dans le souterrain (bien sous le niveau de la mer) ?
func _in_dungeon_v35(p: Vector3) -> bool:
	return p.y < -40.0


## V35 : déplace le joueur (PC ou VR) d'un coup, pieds en « at », regard vers « facing ».
func place_player_v35(at: Vector3, facing: Vector3) -> void:
	facing.y = 0.0
	facing = facing.normalized() if facing.length() > 0.01 else Vector3.FORWARD
	if xr_active:
		var head: Vector3 = xr_camera.global_position
		var head_offset := Vector3(head.x - xr_origin.global_position.x, 0.0, head.z - xr_origin.global_position.z)
		vr_body.global_position = at
		vr_body.velocity = Vector3.ZERO
		xr_origin.position = Vector3(at.x - head_offset.x, at.y, at.z - head_offset.z)
	else:
		pc_root.position = at
		pc_body.global_position = at
		pc_body.velocity = Vector3.ZERO
		if hero_v28 != null:
			hero_v28.state = "sol"
			hero_v28.fall_top = at.y
			hero_v28.facing = facing
		if pc_hero != null:
			pc_hero.position = pc_root.position + Vector3.UP * hero_mesh_floor_offset_v11
	last_ok_v29.clear()


## V33 (VR) : gâchette au pied ou en haut de l'échelle : on grimpe (ou on descend) en
## douceur, le long des barreaux, puis on pose le pied sur la plate-forme (ou au sol).
func _vr_ladder_start_v33(side: String) -> void:
	var t: Node3D = treehouse_v33
	var out: Vector3 = t.ladder_normal * 0.5
	var a: Vector3 = vr_body.global_position
	var path: Array
	if side == "bas":
		var foot: Vector3 = t.ladder_foot
		path = [a, Vector3(foot.x, a.y, foot.z), Vector3(foot.x, t.ladder_top.y + 0.1, foot.z), t.ladder_top + Vector3.UP * 0.1]
	else:
		var hang: Vector3 = t.ladder_top + t.ladder_normal * 1.15
		path = [a, Vector3(hang.x, a.y + 0.1, hang.z), Vector3(hang.x, t.ladder_foot.y + 0.1, hang.z), t.ladder_foot + Vector3.UP * 0.1]
	vr_ladder_v33 = {"path": path, "seg": 0, "u": 0.0}
	if fishing_v32 != null:
		fishing_v32.cancel("")


func _vr_ladder_tick_v33(delta: float) -> void:
	var path: Array = vr_ladder_v33["path"]
	var seg: int = int(vr_ladder_v33["seg"])
	var a: Vector3 = path[seg]
	var b: Vector3 = path[seg + 1]
	var speed: float = 1.3 if absf(b.y - a.y) > 0.5 else 1.6
	vr_ladder_v33["u"] = float(vr_ladder_v33["u"]) + delta * speed / maxf(a.distance_to(b), 0.05)
	var u: float = minf(float(vr_ladder_v33["u"]), 1.0)
	vr_body.global_position = a.lerp(b, u)
	vr_body.velocity = Vector3.ZERO
	var head: Vector3 = xr_camera.global_position
	var head_offset := Vector3(head.x - xr_origin.global_position.x, 0.0, head.z - xr_origin.global_position.z)
	xr_origin.position = Vector3(vr_body.position.x - head_offset.x, vr_body.position.y, vr_body.position.z - head_offset.z)
	if u >= 1.0:
		vr_ladder_v33["u"] = 0.0
		vr_ladder_v33["seg"] = seg + 1
		if seg + 2 >= path.size():
			vr_ladder_v33 = {}
			last_ok_v29.erase(str(vr_body.name))


func _board_boat_v29() -> void:
	if fishing_v32 != null:
		fishing_v32.cancel("")
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
		var pad: Vector2 = pad_move_v74()
		throttle = clampf(throttle - pad.y, -1.0, 1.0)
		steer = clampf(steer + pad.x, -1.0, 1.0)
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


# =================================================================== V31 : habitants et dialogues

## Emplacement de la cabane sur la plage de la baie, à l'écart du ponton.
## On essaie plusieurs positions et orientations (face à la mer ou parallèle au rivage) et
## l'on garde celle qui demande les pilotis les plus courts, avec un escalier qui arrive
## sur du sable sec. La forme de la cabane : 4,2 m de large, 3,4 m + 1,6 m de terrasse.
func _cabin_spot_v31() -> Dictionary:
	if jungle_v29 == null:
		return {}
	var c: Vector3 = jungle_v29.CENTER
	var dock_a: Vector3 = jungle_v29.dock_start
	var ab: Vector3 = jungle_v29.dock_end - dock_a
	ab.y = 0.0
	var best: Dictionary = {}
	var best_score: float = INF
	for i in range(4, 34):
		for sgn in [1.0, -1.0]:
			var a: float = jungle_v29.BAY_ANGLE - sgn * i * 0.02
			var radial := Vector3(cos(a), 0, sin(a))
			for k in range(70):
				var r: float = 45.0 + k * 0.7
				var pos: Vector3 = c + radial * r
				var h0: float = jungle_v29.height(pos.x, pos.z)
				if h0 < 1.2 or h0 > 3.5:
					continue
				var tc: float = clampf((pos - dock_a).dot(ab) / ab.length_squared(), -0.5, 1.0)
				var closest: Vector3 = dock_a + ab * tc
				if Vector2(pos.x - closest.x, pos.z - closest.z).length() < 11.0:
					continue
				var tangent := Vector3(-radial.z, 0, radial.x)
				for facing in [radial, tangent, -tangent]:
					var right: Vector3 = facing.cross(Vector3.UP)
					var hi: float = -INF
					var lo: float = INF
					for corner in [Vector2(-2.1, -1.7), Vector2(2.1, -1.7), Vector2(-2.1, 3.3), Vector2(2.1, 3.3), Vector2(0, 0.8)]:
						var w: Vector3 = pos + right * corner.x + facing * corner.y
						var hc: float = jungle_v29.height(w.x, w.z)
						hi = maxf(hi, hc)
						lo = minf(lo, hc)
					var foot: Vector3 = pos + facing * 5.0
					var hf: float = jungle_v29.height(foot.x, foot.z)
					if hf < 0.9 or lo < 0.6:
						continue
					var drop: float = hi + 0.3 - hf
					var score: float = drop + 0.6 * (hi - lo) + absf(float(i)) * 0.02
					if score < best_score:
						best_score = score
						best = {"pos": Vector3(pos.x, h0, pos.z), "facing": facing}
	return best


func _create_npcs_v31() -> void:
	if cabin_spot_v31.is_empty() or inventory_v28 == null:
		return
	var cabin: Node3D = preload("res://scripts/pnj/cabane_v31.gd").new()
	add_child(cabin)
	var sea: Vector3 = cabin_spot_v31["pos"] - jungle_v29.CENTER
	cabin.build(self, cabin_spot_v31["pos"], cabin_spot_v31["facing"], inventory_v28, sea)
	await get_tree().physics_frame
	var spots: Dictionary = cabin.points.duplicate()
	spots["marche"] = cabin.stairs_foot
	var graph := {"interieur": ["porche", "table"], "table": ["interieur"], "porche": ["interieur", "marche"],
		"marche": ["porche", "feu"], "feu": ["marche", "rivage"], "rivage": ["feu"]}
	var npc: Node3D = preload("res://scripts/pnj/pnj_v31.gd").new()
	add_child(npc)
	npc.setup(self, preload("res://scripts/pnj/barnabe_v31.gd").DATA, spots, graph, "porche")
	var saved: Variant = pending_pnj_v31.get("barnabe", {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	npcs_v31.append(npc)
	print("ILE_MANGA_V31: cabane et habitant ", npc.display_name, " à ", npc.global_position)
	_create_rival_v33()


## V33 : le fromager et la cabane perchée d'Octave Taillefer, puis Octave lui-même.
func _create_rival_v33() -> void:
	if tree_spot_v33.is_empty() or inventory_v28 == null:
		_plant_v34()
		return
	treehouse_v33 = preload("res://scripts/pnj/cabane_arbre_v33.gd").new()
	add_child(treehouse_v33)
	var mesh: Mesh = flora_v30.giant_mesh(2, OS.has_feature("ile_manga_pc")) if flora_v30 != null else null
	treehouse_v33.build(self, tree_spot_v33["pos"], tree_spot_v33["facing"], inventory_v28, mesh)
	await get_tree().physics_frame
	var graph := {"comptoir": ["terrasse", "atelier"], "atelier": ["comptoir"], "terrasse": ["comptoir", "cote"],
		"cote": ["terrasse", "balcon"], "balcon": ["cote"]}
	var npc: Node3D = preload("res://scripts/pnj/pnj_v31.gd").new()
	add_child(npc)
	npc.setup(self, preload("res://scripts/pnj/octave_v33.gd").DATA, treehouse_v33.points.duplicate(), graph, "comptoir")
	var saved: Variant = pending_pnj_v31.get("octave", {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	npcs_v31.append(npc)
	print("ILE_MANGA_V33: cabane perchée et habitant ", npc.display_name, " à ", npc.global_position)
	_plant_v34()


## V34 : une fois les habitants installés : arbres à abattre, cachettes de trésors, et deux
## mannequins d'entraînement au pied de l'arbre d'Octave (pour essayer l'épée).
func _plant_v34() -> void:
	# V35 d'abord : le cercle de pierres et la tête de pierre réservent leur place.
	if donjon_v35 != null:
		donjon_v35.build(trap_jungle_spot_v35)
	# V41 : la clairière de Lyra, la fleur de lune, la source.
	if elfes_v41 != null and donjon_v35 != null:
		elfes_v41.build_quest()
	if nains_v46 != null and donjon_v35 != null:
		nains_v46.build_quest()
	if ciel_v54 != null and donjon_v35 != null:
		ciel_v54.build_quest()
	if mer_v55 != null and donjon_v35 != null:
		mer_v55.build_quest()
	if feerie_v58 != null and donjon_v35 != null:
		feerie_v58.build_quest()
	if bucheron_v34 != null:
		bucheron_v34.plant()
	if digging_v33 != null:
		digging_v33.plant_treasures()
	if treehouse_v33 != null and combat_v28 != null:
		var n: Vector3 = treehouse_v33.ladder_normal
		var side: Vector3 = n.cross(Vector3.UP)
		for k in range(2):
			var p: Vector3 = treehouse_v33.ladder_foot + n * 2.6 + side * (2.8 + k * 2.0)
			p.y = _height_at(p.x, p.z)
			combat_v28._make_dummy(20 + k, p)
			var d: Node3D = combat_v28.get_node("Mannequin_v28_%d" % (20 + k))
			d.rotation.y = atan2(-n.x, -n.z) + PI


## V33 : un endroit à peu près plat sur la côte est de la jungle (à l'opposé de la baie
## de Barnabé), loin des pitons et de la gorge ; l'échelle regarde vers la baie.
## V35 : à l'ouest de la gorge, entre la baie et le grand massif, un replat à l'écart.
func _trap_jungle_spot_v35() -> Vector3:
	var c: Vector3 = jungle_v29.CENTER
	var best := Vector3.INF
	var best_score: float = INF
	for xi in range(-44, -12, 2):
		for zi in range(-4, 52, 2):
			var l := Vector2(float(xi), float(zi))
			if jungle_v29.gorge_distance(l.x, l.y) < 12.0 or jungle_v29.coast_ratio(l.x, l.y) > 0.8:
				continue
			var near_tower: bool = false
			for tw in jungle_v29.TOWERS:
				if l.distance_to(tw[0]) < float(tw[1]) + 8.0:
					near_tower = true
			if near_tower:
				continue
			var p := Vector3(c.x + l.x, 0, c.z + l.y)
			var h0: float = jungle_v29.height(p.x, p.z)
			if h0 < 2.5:
				continue
			var lo: float = INF
			var hi: float = -INF
			for k in range(12):
				for rr in [2.0, 4.0]:
					var h: float = jungle_v29.height(p.x + cos(k * PI / 6.0) * rr, p.z + sin(k * PI / 6.0) * rr)
					lo = minf(lo, h)
					hi = maxf(hi, h)
			var score: float = (hi - lo) + l.distance_to(Vector2(-28, 24)) * 0.02
			if score < best_score:
				best_score = score
				best = Vector3(p.x, h0, p.z)
	return best


func _treasure_candidates_v34() -> void:
	treasure_jungle_v34.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5252
	var c: Vector3 = jungle_v29.CENTER
	var tries: int = 0
	while treasure_jungle_v34.size() < 20 and tries < 4000:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf_range(20.0 * 20.0, 100.0 * 100.0))
		var l := Vector2(cos(a) * r, sin(a) * r)
		if jungle_v29.coast_ratio(l.x, l.y) > 0.96 or jungle_v29.gorge_distance(l.x, l.y) < 5.0:
			continue
		var bad: bool = false
		for tw in jungle_v29.TOWERS:
			if l.distance_to(tw[0]) < float(tw[1]) + 3.0:
				bad = true
		var p := Vector3(c.x + l.x, jungle_v29.height(c.x + l.x, c.z + l.y), c.z + l.y)
		if bad or p.y < 0.3:
			continue
		var e: float = 0.8
		var gx: float = jungle_v29.height(p.x + e, p.z) - jungle_v29.height(p.x - e, p.z)
		var gz: float = jungle_v29.height(p.x, p.z + e) - jungle_v29.height(p.x, p.z - e)
		if sqrt(gx * gx + gz * gz) / (2.0 * e) > 0.35:
			continue
		for q in treasure_jungle_v34:
			if (q as Vector3).distance_to(p) < 12.0:
				bad = true
		if not bad:
			treasure_jungle_v34.append(p)
	# Coffre de la Mouette : côté mer, à une vingtaine de pas du fromager d'Octave.
	if not tree_spot_v33.is_empty():
		var t: Vector3 = tree_spot_v33["pos"]
		var out: Vector3 = t - c
		out.y = 0.0
		out = out.normalized()
		for d in [16.0, 14.0, 18.0, 12.0, 20.0]:
			var p2: Vector3 = t + out * d
			var h2: float = jungle_v29.height(p2.x, p2.z)
			if h2 > 0.5:
				mouette_spot_v34 = Vector3(p2.x, h2, p2.z)
				break


func _tree_spot_v33() -> Dictionary:
	if jungle_v29 == null:
		return {}
	var c: Vector3 = jungle_v29.CENTER
	var best: Dictionary = {}
	var best_score: float = INF
	for ti in range(-12, 19):
		var theta: float = deg_to_rad(ti * 2.0)
		for ri in range(52, 82, 2):
			var r: float = jungle_v29._coast_radius(theta) * ri / 100.0
			var lx: float = cos(theta) * r
			var lz: float = sin(theta) * r
			var near_tower: bool = false
			for tw in jungle_v29.TOWERS:
				if Vector2(lx - tw[0].x, lz - tw[0].y).length() < float(tw[1]) + 10.0:
					near_tower = true
			if near_tower or jungle_v29.gorge_distance(lx, lz) < 14.0:
				continue
			var wx: float = c.x + lx
			var wz: float = c.z + lz
			var h0: float = jungle_v29.height(wx, wz)
			if h0 < 2.0:
				continue
			var lo: float = INF
			var hi: float = -INF
			for a in range(12):
				for rr in [2.0, 4.0, 6.0]:
					var h: float = jungle_v29.height(wx + cos(a * PI / 6.0) * rr, wz + sin(a * PI / 6.0) * rr)
					lo = minf(lo, h)
					hi = maxf(hi, h)
			var score: float = (hi - lo) + absf(ti * 2.0 - 10.0) * 0.02
			if score < best_score:
				best_score = score
				var to_bay: Vector3 = jungle_v29.dock_start - Vector3(wx, 0, wz)
				to_bay.y = 0.0
				best = {"pos": Vector3(wx, h0, wz), "facing": to_bay.normalized(), "drop": hi - lo}
	print("ILE_MANGA_V33: fromager d'Octave ", best.get("pos", Vector3.ZERO), " dénivelé ", best.get("drop", 0.0))
	return best


func _nearest_npc_v31() -> Node3D:
	var p: Vector3 = _player_pos_v27()
	var best: Node3D = null
	var best_d: float = 2.8
	# V42 : au milieu de la foule elfe, on parle de préférence à celui qu'on regarde.
	var look: Vector3 = hero_v28.facing if hero_v28 != null else Vector3.ZERO
	for npc in npcs_v31:
		# V68 : pas à un habitant rentré chez lui, ni en pleine bagarre (ni étendu par terre)
		if not npc.visible or (npc.has_method("can_talk") and not npc.can_talk()):
			continue
		var off := Vector2(npc.global_position.x - p.x, npc.global_position.z - p.z)
		var d: float = off.length()
		if d >= 2.8 or absf(npc.global_position.y - p.y) >= 2.5:
			continue
		var score: float = d
		if d > 0.05:
			score -= 0.9 * maxf(Vector2(look.x, look.z).dot(off / d), 0.0)
		if score < best_d:
			best_d = score
			best = npc
	return best


## V72 : ce qu'on peut offrir en cadeau : ni les objets de quête, ni les outils, ni les armes, ni
## les pièces, ni ce qu'on tient en main (offrir un objet de quête bloquait sa quête pour toujours).
func _giftable_v72() -> Array:
	var out: Array = []
	if inventory_v28 == null:
		return out
	var c: Dictionary = inventory_v28.counts()
	for id in c:
		var it: Dictionary = inventory_v28.ITEMS.get(str(id), {})
		if it.is_empty() or int(c[id]) <= 0 or str(id) in ["piece", "piece_or"] or str(id) == str(inventory_v28.equipped):
			continue
		if str(it.get("kind", "")) in ["quete", "outil", "arme", "canne"]:
			continue
		out.append(str(id))
	out.sort()
	return out


## État du jeu que le personnage peut « voir » : objets portés, arme, vie, temps.
func _npc_ctx_v31() -> Dictionary:
	var noms := {}
	var arts := {}
	for id in inventory_v28.ITEMS:
		noms[id] = str(inventory_v28.ITEMS[id]["name"])
		arts[id] = str(inventory_v28.ITEMS[id].get("art", noms[id]))
	return {
		"now": game_menu.seconds if game_menu != null else 0.0,
		"objets": inventory_v28.counts() if inventory_v28 != null else {},
		"arme": inventory_v28.equipped if inventory_v28 != null else "",
		"vie": hero_v28.hp if hero_v28 != null else 10,
		"offrables": _giftable_v72(),
		"vie_max": hero_v28.HP_MAX if hero_v28 != null else 10,
		"noms": noms, "articles": arts,
		"peche": fishing_v32.serialize() if fishing_v32 != null else {},
		"vr": xr_active,
		"rencontres": _encounters_v33(),
		"trouvailles": {"mouette": 1 if digging_v33 != null and digging_v33.mouette_found else 0,
			"tresors": digging_v33.treasures_total if digging_v33 != null else 0,
			"arbres": bucheron_v34.total_cut if bucheron_v34 != null else 0,
			"trappe_village": int(donjon_v35.state["trappe_village"]) if donjon_v35 != null else 0,
			"trappe_jungle": int(donjon_v35.state["trappe_jungle"]) if donjon_v35 != null else 0,
			"temple": 1 if donjon_v35 != null and bool(donjon_v35.state["visite"]) else 0,
			"braseros": 1 if donjon_v35 != null and bool(donjon_v35.state["braseros"]) else 0,
			"fragment": 1 if donjon_v35 != null and bool(donjon_v35.state["coffre"]) else 0,
			"tunnel": 1 if donjon_v35 != null and bool(donjon_v35.state["eboulement"]) else 0,
			"grille": 1 if donjon_v35 != null and bool(donjon_v35.state["grille"]) else 0,
			"monstres": int(donjon_v35.state["victoires"]) if donjon_v35 != null else 0,
			"boss1": 1 if donjon_v35 != null and bool(donjon_v35.state["boss1"]) else 0,
			"serpents": 1 if donjon_v35 != null and bool(donjon_v35.state["enigme_serpents"]) else 0,
			"fragment3": 1 if donjon_v35 != null and bool(donjon_v35.state["fragment3"]) else 0,
			"porte_serpent": 1 if donjon_v35 != null and bool(donjon_v35.state["porte_serpent"]) else 0,
			"abysses": 1 if donjon_v35 != null and bool(donjon_v35.state["sceau"]) else 0,
			"lac": 1 if donjon_v35 != null and bool(donjon_v35.state["lac"]) else 0,
			"abime": 1 if donjon_v35 != null and bool(donjon_v35.state["abime_eveil"]) else 0,
			"naga": 1 if donjon_v35 != null and bool(donjon_v35.state["naga"]) else 0,
			"quete_elfe": 1 if elfes_v41 != null and elfes_v41.lyra != null and str(elfes_v41.lyra.brain.memoire["quete"]) != "" else 0,
			"arbre_sacre": 1 if elfes_v41 != null and bool(elfes_v41.state["arbre"]) else 0,
			"ile_elfes": 1 if elfes_v41 != null and bool(elfes_v41.state["visite"]) else 0,
			"bague_caelan": 1 if elfes_v41 != null and elfes_v41.village != null and elfes_v41.village.quest_state("caelan") == "finie" else 0,
			"esprits": elfes_v41.feerique.spirits_count() if elfes_v41 != null and elfes_v41.feerique != null else 0,
			"porte_racines": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["porte"]) else 0,
			"royaume": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["visite"]) else 0,
			"prismes": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["prismes"]) else 0,
			"clochettes": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["clochettes"]) else 0,
			"village_fees": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["village"]) else 0,
			"baguette": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["baguette"]) else 0,
			"baguette_rendue": 1 if _fee_quest_v44("pimprenelle") == "finie" else 0,
			"rosee_rendue": 1 if _fee_quest_v44("brindille") == "finie" else 0,
			"ronces": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["ronces"]) else 0,
			"reine": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["reine"]) else 0,
			"carte_naine": 1 if elfes_v41 != null and elfes_v41.feerique != null and bool(elfes_v41.feerique.state["carte"]) else 0,
			"ile_nains": 1 if nains_v46 != null and bool(nains_v46.state["visite"]) else 0,
			"porte_forgefer": 1 if nains_v46 != null and bool(nains_v46.state["ouverte"]) else 0,
			"ville_naine": 1 if nains_v46 != null and bool(nains_v46.state["ville"]) else 0,
			"nains_aides": nains_v46.helped_count() if nains_v46 != null else 0,
			"nains_aides_3": 1 if nains_v46 != null and nains_v46.helped_count() >= 3 else 0,
			"ventaile": 1 if ciel_v54 != null and ciel_v54.tamed() else 0,
			"citadelle": 1 if ciel_v54 != null and bool(ciel_v54.state["visite_ciel"]) else 0,
			"orage": 1 if ciel_v54 != null and bool(ciel_v54.state["boss"]) else 0,
			"masque": 1 if mer_v55 != null and mer_v55.has_mask() else 0,
			"atlantide": 1 if mer_v55 != null and bool(mer_v55.state["visite"]) else 0,
			"perles_1": 1 if mer_v55 != null and mer_v55.pearls_found() >= 1 else 0,
			"perles_3": 1 if mer_v55 != null and mer_v55.pearls_found() >= 3 else 0,
			"cristal": 1 if mer_v55 != null and bool(mer_v55.state["cristal"]) else 0,
			"palmes": 1 if mer_v55 != null and mer_v55.has_fins() else 0,
			"azur": 1 if azur_v56 != null and bool(azur_v56.state.get("visite", false)) else 0}.merged(feerie_v58.trouvailles() if feerie_v58 != null else {}).merged(grande_v59.trouvailles() if grande_v59 != null else {}).merged(arcanelle_v67.trouvailles() if arcanelle_v67 != null and arcanelle_v67.bourg != null else {}).merged(pirates_v68.trouvailles() if pirates_v68 != null and pirates_v68.port != null else {}).merged(soleils_v69.trouvailles() if soleils_v69 != null and soleils_v69.egypte != null else {}).merged(braise_v70.trouvailles() if braise_v70 != null and braise_v70.city != null else {}).merged(montjoie_v71.trouvailles() if montjoie_v71 != null and montjoie_v71.city != null else {}).merged(boucan_v75.trouvailles() if boucan_v75 != null and boucan_v75.city != null else {}).merged(astralys_v76.trouvailles() if astralys_v76 != null and astralys_v76.city != null else {}).merged(moai_v87.trouvailles() if moai_v87 != null and moai_v87.ile != null else {}).merged(compagnons_animaux_v76.trouvailles() if compagnons_animaux_v76 != null else {}).merged(aeronef_v76.trouvailles() if aeronef_v76 != null else {}).merged(atelier_ailes_v76.trouvailles() if atelier_ailes_v76 != null else {}).merged(chantier_v76.trouvailles() if chantier_v76 != null and chantier_v76.built else {}),
		"heure": temps_v56.hour if temps_v56 != null else 12.0,
		"q56": journal_v56.ctx_states() if journal_v56 != null else {},
		"rep": journal_v56.reputation if journal_v56 != null else 0,
		"place": {"pelle": inventory_v28.space_for("pelle"), "hache": inventory_v28.space_for("hache"), "epee": inventory_v28.space_for("epee")},
	}


## V44 : où en est la quête d'une fée du Royaume des Racines ("", "demandee", "finie").
func _fee_quest_v44(id: String) -> String:
	if elfes_v41 == null or elfes_v41.feerique == null or elfes_v41.feerique.royaume == null:
		return ""
	var fe: Node3D = elfes_v41.feerique.royaume.fairy(id)
	return str(fe.brain.memoire.get("quete", "")) if fe != null else ""


## V33 : qui le joueur a déjà rencontré (identifiant -> visites), pour que les habitants
## parlent les uns des autres.
func _encounters_v33() -> Dictionary:
	var out := {}
	for n in npcs_v31:
		out[str(n.profile["id"])] = int(n.brain.memoire["visites"])
	for id in pending_pnj_v31:
		if not out.has(id) and pending_pnj_v31[id] is Dictionary:
			var m: Variant = (pending_pnj_v31[id] as Dictionary).get("memoire", {})
			out[id] = int((m as Dictionary).get("visites", 0)) if m is Dictionary else 0
	return out


func _talk_v31(npc: Node3D) -> void:
	if dialogue_v31 == null or dialogue_v31.opened:
		return
	if inventory_v28 != null and inventory_v28.opened:
		inventory_v28.close()
	talking_npc_v31 = npc
	if fishing_v32 != null:
		fishing_v32.cancel("")
	npc.begin_talk()
	if hero_v28 != null and not xr_active:
		var to_npc: Vector3 = npc.global_position - pc_root.global_position
		to_npc.y = 0.0
		if to_npc.length() > 0.05:
			hero_v28.facing = to_npc.normalized()
	dialogue_v31.open(npc)
	sfx("ui_dialogue")
	_brain_reply_v48(npc, func(): return npc.brain.start(_npc_ctx_v31()))


func _on_dialogue_choice_v31(id: String) -> void:
	# V69 : une question posée par une statue (le Sphinx, Anubis…) : la réponse va à qui l'a posée
	if talking_npc_v31 == null and riddle_v69.is_valid():
		if id == "fermer":
			_close_dialogue_v31()
			return
		riddle_v69.call(id)
		return
	var npc: Node3D = talking_npc_v31
	if npc == null or id == "fermer":
		_close_dialogue_v31()
		return
	# V56 : les quêtes et services du carnet
	if id.begins_with("q56:") and journal_v56 != null:
		_brain_reply_v48(npc, func(): return journal_v56.choose(npc, id))
		return
	_brain_reply_v48(npc, func(): return npc.brain.choose(id, _npc_ctx_v31()))


## V48 : un échange avec un personnage est tout ou rien. Si ce qu'il donne ne tient pas
## dans le sac (récompense de quête, objet confié, vente, achat), on annule tout : sa mémoire
## revient à l'état d'avant (quête, fait « donné », gains), rien n'est pris ni donné, et il
## demande de revenir avec de la place.
func _brain_reply_v48(npc: Node3D, call: Callable) -> void:
	var snap: Dictionary = npc.brain.serialize()
	var jsnap: Dictionary = journal_v56.serialize() if journal_v56 != null else {}
	var ssnap: Dictionary = Societe_v65.serialize()
	var r: Dictionary = call.call()
	var gives: Array = r.get("donner", [])
	if not gives.is_empty() and inventory_v28 != null and not inventory_v28.can_accept(gives, r.get("prendre", [])):
		npc.brain.load_data(snap)
		Societe_v65.load_data(ssnap)
		if journal_v56 != null:
			journal_v56.load_data(jsnap)
		# V72 : toutes les actions spéciales de la réplique sont annulées (pas seulement une liste tenue à la main)
		for k in r.keys():
			if str(k).begins_with("_"):
				r.erase(k)
		var names: Array = []
		for g in gives:
			names.append(str(inventory_v28.ITEMS.get(str(g[0]), {"name": str(g[0])})["name"]).to_lower())
		sfx("ui_erreur")
		r = {"texte": "« Attends… ton sac est plein. Fais un peu de place pour %s, puis reviens me voir. »" % " et ".join(names),
			"geste": "parle", "choix": npc.brain.topics(_npc_ctx_v31())}
		_show_message_v28("Sac plein : rien n'a été échangé.")
	_apply_reply_v31(npc, r)
	# V56 : quête accomplie (récompenses, bonus), départ du bateau, nuit à l'hôtel
	if journal_v56 != null:
		journal_v56.commit_reply(r, npc)
	if azur_v56 != null:
		azur_v56.after_reply(r, npc)
	if grande_v59 != null:
		grande_v59.after_reply(r, npc)
	# V63 : la forge d'Ursule et de Borin
	if progression_v63 != null:
		progression_v63.after_reply(r, npc)
	# V66 : un verre au comptoir
	if objets_v66 != null:
		objets_v66.after_reply(r, npc)
	# V67 : Arcanelle (la chambre du Chaudron Fumant, un sort appris d'un maître)
	if arcanelle_v67 != null:
		arcanelle_v67.after_reply(r, npc)
	# V68 : la Balafre (la bagarre, la tournée, les dés, le hamac de Mama Grog, le Doc, le tatouage)
	if pirates_v68 != null and pirates_v68.port != null:
		pirates_v68.after_reply(r, npc)
	# V69 : les Trois Soleils (le Sphinx, les offrandes, les services des villages)
	if soleils_v69 != null and soleils_v69.egypte != null and soleils_v69.has_method("after_reply"):
		soleils_v69.after_reply(r, npc)
	# V70 : Pandémonia (le tournoi, la fête)
	if braise_v70 != null and braise_v70.city != null:
		braise_v70.after_reply(r, npc)
	# V71 : Montjoie (la Guilde, les compagnons, la Chaumière)
	if montjoie_v71 != null and montjoie_v71.city != null:
		montjoie_v71.after_reply(r, npc)
	# V75 : Port-Boucan (Sardine, la Gratuiterie…)
	if boucan_v75 != null and boucan_v75.city != null:
		boucan_v75.after_reply(r, npc)
	# V76 : Astralys
	if astralys_v76 != null and astralys_v76.city != null:
		astralys_v76.after_reply(r, npc)


func _apply_reply_v31(npc: Node3D, r: Dictionary) -> void:
	# V50 : un objet reçu d'un personnage (récompense, achat) : petit carillon ; sinon un clic.
	if not (r.get("donner", []) as Array).is_empty():
		sfx("ui_quete")
	elif not (r.get("prendre", []) as Array).is_empty():
		sfx("ramasse_pieces")
	else:
		sfx("ui_choix")
	for p in r.get("prendre", []):
		inventory_v28.remove(str(p[0]), int(p[1]))
	for g in r.get("donner", []):
		var got: int = inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			_show_message_v28("+ " + str(inventory_v28.ITEMS[str(g[0])]["name"]) + ("" if got == 1 else " ×%d" % got))
			# V32 : la canne reçue passe directement en main si elle est libre.
			if str(g[0]) == "canne_peche" and inventory_v28.equipped == "":
				inventory_v28.equip_item("canne_peche")
	npc.gesture(str(r.get("geste", "parle")))
	var choices: Array = r.get("choix", [])
	# V56 : après une réplique du carnet, on revient aux sujets habituels
	if choices.is_empty() and not bool(r.get("fin", false)) and str(r.get("texte", "")) != "":
		choices = npc.brain.topics(_npc_ctx_v31())
	# V56 : les sujets du carnet (quêtes, services) en tête de la liste
	if journal_v56 != null and not bool(r.get("fin", false)):
		var has_bye: bool = false
		for c in choices:
			if str(c.get("id", "")) == "au_revoir":
				has_bye = true
		if has_bye:
			choices = journal_v56.topics_for(npc) + choices
	if bool(r.get("fin", false)) or choices.is_empty():
		choices = [{"id": "fermer", "label": "(Partir)"}]
	dialogue_v31.show_line(npc.display_name, npc.brain.humeur_mot(), str(r.get("texte", "…")), choices)


## V69 : une question posée par une statue ou une inscription (le Sphinx, Anubis, les Seigneurs de
## Xibalba…) : le dialogue s'ouvre sur « speaker » (un repère posé sur la statue), les choix vont
## à cb(id). Le même dialogue sert pour toute la suite des questions.
var riddle_v69: Callable = Callable()

func ask_v69(speaker: Node3D, who: String, mood: String, text: String, choices: Array, cb: Callable) -> void:
	if dialogue_v31 == null:
		return
	if talking_npc_v31 != null:
		_close_dialogue_v31()
	if not dialogue_v31.opened:
		if inventory_v28 != null and inventory_v28.opened:
			inventory_v28.close()
		dialogue_v31.open(speaker)
		sfx("ui_dialogue")
	riddle_v69 = cb
	dialogue_v31.show_line(who, mood, text, choices)


func _close_dialogue_v31() -> void:
	riddle_v69 = Callable()
	if dialogue_v31 != null:
		dialogue_v31.close()
	if talking_npc_v31 != null:
		talking_npc_v31.end_talk()
	talking_npc_v31 = null


## V49 : les ambiances sonores (nappes, émetteurs, sons ponctuels).
var ambiance_v49: Node
## V50 : les bruitages d'action (sfx_v50.gd).
var decor_v53: Node3D                      # V53 : finitions du village
var ciel_v54: Node3D                       # V54 : Ventaile, l'île flottante, la Citadelle des Nuées
var mer_v55: Node3D                        # V55 : la nage, le fond marin, l'Atlantide
var temps_v56: Node                        # V56 : l'heure, le jour et la nuit
var azur_v56: Node3D                       # V56 : Port-Azur, la grande île touristique
var journal_v56: Node                      # V56 : le carnet de quêtes, les bonus, la réputation
var teuf_v57: Node3D                       # V57 : la teuf de la plage (DJ, teufeurs, sono)
var feerie_v58: Node3D                     # V58 : le royaume des fées, Yggdrasil et son donjon
var teleport_v58: Node                     # V58 : la magie de téléportation
var progression_v63: Node                  # V63 : niveaux, talents, forge, sceaux du héros
var pouvoirs_v63: Node3D                   # V63 : les pouvoirs des quatre sceaux
var sceaux_v63: Node3D                     # V63 : la grande enquête (sites des sceaux, la porte)
var coeur_v63: Node3D                      # V63 : le donjon du Cœur-de-Pierre
var grande_v59: Node3D                     # V59 : la grande île de l'est, le Léviathan et Carène
var bavardages_v65: Node                   # V65 : les habitants qui se connaissent bavardent entre eux
var objets_v66: Node                       # V66 : objets à casser, coffres cachés, boissons
var arcanelle_v67: Node3D                  # V67 : Arcanelle, l'île des sorciers et sa communauté
var sorts_v67: Node3D                      # V67 : les sorts appris des maîtres d'Arcanelle
var pirates_v68: Node3D                    # V68 : l'Île de la Balafre, Port-Coutelas et ses pirates
var soleils_v69: Node3D                    # V69 : l'Île des Trois Soleils (Égyptiens, Mayas, Aztèques) et ses donjons
var braise_v70: Node3D                     # V70 : l'Île de Braise, Pandémonia (la cité des démons), les Neuf Cercles
var manette_v74: Node                      # V74 : la manette sur PC (Xbox, PlayStation…)
var montjoie_v71: Node3D                   # V71 : l'Île de Montjoie, la ville des aventuriers, le Donjon des Mille Marches
var boucan_v75: Node3D                     # V75 : l'Île du Boucan, Port-Boucan (la ville libre des punks), l'Usine Grise
var astralys_v76: Node3D                   # V76 : Astralys, l'île flottante des Lumens
var moai_v87: Node3D                       # V87 : l'Île aux Moaïs
var compagnons_animaux_v76: Node           # V76 : les quatre compagnons animaux (le sifflet)
var vr_x_hold_v76: float = 0.0            # V76 : depuis quand X (VR) est maintenu
var aeronef_v76: Node3D                    # V76 : l'aéronef qui évolue (Alouette, Alouette à hélice, Albatros, Glisseur stellaire)
var testeur_v78: Node                      # V78 : le mode testeur (F8)
var maisons_v81: Node3D                    # V81 : les maisons décoratives qu'on visite
var chantier_v76: Node                     # V76 : le chantier naval de Port-Azur (le bateau qui évolue)
var atelier_ailes_v76: Node3D              # V76 : l'Atelier des Ailes de Philibert Vis, à Cliquetis
const Societe_v65 = preload("res://scripts/pnj/societe_v65.gd")
const FERRY_PIER_V56 := [Vector3(51.96, 1.0, 30.0), Vector3(77.94, 1.0, 45.0)]   # ponton de L'Hirondelle au village
var grotte_v52: Node3D                     # V52 : la grotte derrière la cascade
var foret_v52: Node                       # V52 : lumière sous les arbres
var music_v51: Node                       # V51 : la musique (musique_v51.gd)
var sfx_v50: Node

func _create_sfx_v50() -> void:
	sfx_v50 = preload("res://scripts/sfx_v50.gd").new()
	sfx_v50.name = "Bruitages_v50"
	add_child(sfx_v50)
	sfx_v50.setup(self)


## V56 : les quarante-deux habitants de Port-Azur arrivent une fois Barnabé et Octave en place
## (ils gardent leur rang en tête de la liste des habitants).
func _spawn_azur_v56() -> void:
	for i in 40:
		await get_tree().physics_frame
		var ready: int = 0
		for n in npcs_v31:
			if is_instance_valid(n) and str(n.profile.get("id", "")) in ["barnabe", "octave"]:
				ready += 1
		if ready >= 2:
			break
	if azur_v56 != null and azur_v56.port != null:
		azur_v56.spawn_npcs()
	# V57 : la teuf de la plage, sur l'île du village : DJ Mistral et les teufeurs
	if teuf_v57 == null:
		teuf_v57 = preload("res://scripts/teuf_v57.gd").new()
		teuf_v57.name = "Teuf_plage_v57"
		add_child(teuf_v57)
		teuf_v57.setup(self)
		teuf_v57.spawn_people()
		# V58 : Lulu et son champignon qui brille
		if journal_v56 != null:
			teuf_v57.register_services(journal_v56)
	# V58 : les fées du royaume d'Yggdrasil
	if feerie_v58 != null:
		feerie_v58.spawn_fairies()
	# V59 : les gens de Carène
	if grande_v59 != null and grande_v59.carene != null:
		grande_v59.spawn_npcs()
	# V67 : la communauté des sorciers d'Arcanelle
	if arcanelle_v67 != null and arcanelle_v67.bourg != null:
		arcanelle_v67.spawn_npcs()
	# V68 : les pirates et les gens de Port-Coutelas
	if pirates_v68 != null and pirates_v68.port != null:
		pirates_v68.spawn_npcs()
	# V69 : les gens de Per-Hâpy, de Yaxché et d'Aztlán
	if soleils_v69 != null and soleils_v69.egypte != null and soleils_v69.has_method("spawn_npcs"):
		soleils_v69.spawn_npcs()
	# V70 : les démons de Pandémonia
	if braise_v70 != null and braise_v70.city != null:
		braise_v70.spawn_npcs()
	# V71 : les habitants de Montjoie
	if montjoie_v71 != null and montjoie_v71.city != null:
		montjoie_v71.spawn_npcs()
	# V75 : les habitants de Port-Boucan
	if boucan_v75 != null and boucan_v75.city != null:
		boucan_v75.spawn_npcs()
	# V76 : les Lumens d'Astralys
	if astralys_v76 != null and astralys_v76.city != null:
		astralys_v76.spawn_npcs()


## V56 : après une nuit à l'hôtel : tous les cœurs, et on sauvegarde.
func _on_slept_v56() -> void:
	if hero_v28 != null:
		hero_v28.set_health(hero_v28.HP_MAX)
	_show_message_v28("Une bonne nuit de sommeil… Tous vos cœurs sont revenus.")
	if game_menu != null:
		_save_slot(game_menu.active_slot)


## V56 : l'heure qui passe (temps_v56.gd).
func _create_v56() -> void:
	temps_v56 = preload("res://scripts/temps_v56.gd").new()
	temps_v56.name = "Temps_v56"
	add_child(temps_v56)
	temps_v56.setup(self)
	journal_v56 = preload("res://scripts/journal_v56.gd").new()
	journal_v56.name = "Journal_v56"
	add_child(journal_v56)
	journal_v56.setup(self)
	if azur_v56 != null:
		azur_v56.build_town()
		azur_v56.build_ferry(FERRY_PIER_V56)
		azur_v56.register_services(journal_v56)
		journal_v56.lieux = azur_v56.port.objets.duplicate()
		journal_v56.lieux["fontaine"] = azur_v56.port.fountain
		journal_v56.lieux["phare_porte"] = azur_v56.port.spots["phare_porte"]["pos"]
		# V76 : le chantier naval de Port-Azur (les évolutions du bateau)
		chantier_v76 = preload("res://scripts/chantier_v76.gd").new()
		chantier_v76.name = "Chantier_v76"
		add_child(chantier_v76)
		chantier_v76.setup(self)
		chantier_v76.build()
		chantier_v76.register_services(journal_v56)
		if donjon_v35 != null:
			chantier_v76.register_interactions(donjon_v35)
		# la barque peut accoster au ponton des plaisanciers
		if boat_v29 != null:
			var ad: Array = azur_v56.dock()
			boat_v29._make_dock("Ponton_azur", ad[0], ad[1])


## V59 : Carène, ses habitants, la végétation de la grande île (après l'heure du jour) ;
## le ponton de la barque ; l'auberge de Pierrick.
func _create_v59() -> void:
	if grande_v59 == null:
		return
	grande_v59.build_town()
	if journal_v56 != null:
		grande_v59.register_services(journal_v56)
	if boat_v29 != null:
		var gd: Array = grande_v59.dock()
		if gd.size() == 2:
			boat_v29._make_dock("Ponton_carene", gd[0], gd[1])
		var td: Array = grande_v59.dock_tazira()
		if td.size() == 2:
			boat_v29._make_dock("Ponton_tazira", td[0], td[1])
		var cd: Array = grande_v59.dock_cliquetis()
		if cd.size() == 2:
			boat_v29._make_dock("Ponton_cliquetis", cd[0], cd[1])
		var rd: Array = grande_v59.dock_ramure()
		if rd.size() == 2:
			boat_v29._make_dock("Ponton_ramure", rd[0], rd[1])


## V66 : objets à casser, coffres cachés, boissons (après tout le reste : villes et souterrains
## sont là, le carnet aussi pour les services des tavernes).
func _create_v66() -> void:
	objets_v66 = preload("res://scripts/objets_v66.gd").new()
	objets_v66.name = "Objets_v66"
	add_child(objets_v66)
	objets_v66.setup(self)


## V67 : Arcanelle (l'Académie, le bourg, la communauté des sorciers, la végétation), les sorts
## (sorts_v67.gd) et leur écran ; le ponton est posé avec le relief (au démarrage).
func _create_v67() -> void:
	sorts_v67 = preload("res://scripts/sorts_v67.gd").new()
	sorts_v67.name = "Sorts_v67"
	add_child(sorts_v67)
	sorts_v67.setup(self)
	if hud_v28 != null and not xr_active:
		sorts_v67.make_hud(hud_v28)
	if arcanelle_v67 == null:
		return
	arcanelle_v67.build_town()
	if journal_v56 != null:
		arcanelle_v67.register_services(journal_v56)
	arcanelle_v67.register_targets(sorts_v67, pouvoirs_v63)


## V68 : l'Île de la Balafre (Port-Coutelas, ses navires, ses tripots, la jungle) ; le ponton est
## posé avec le relief (au démarrage).
func _create_v68() -> void:
	if pirates_v68 == null:
		return
	pirates_v68.build_town()
	if journal_v56 != null:
		pirates_v68.register_services(journal_v56)


## V69 : l'Île des Trois Soleils (Per-Hâpy, Yaxché, Aztlán, la végétation, les donjons) ; le
## ponton est posé avec le relief (au démarrage).
func _create_v69() -> void:
	if soleils_v69 == null:
		return
	soleils_v69.build_town()
	if journal_v56 != null and soleils_v69.has_method("register_services"):
		soleils_v69.register_services(journal_v56)


## V70 : l'Île de Braise (Pandémonia, ses grands lieux, son port, le dehors, la végétation, la
## lave, le donjon des Neuf Cercles, l'arène, la fête) ; le ponton est posé avec le relief.
func _create_v70() -> void:
	if braise_v70 == null:
		return
	braise_v70.build_town()
	if journal_v56 != null:
		braise_v70.register_services(journal_v56)


## V71 : l'Île de Montjoie (la ville sur la Butte, ses grands lieux, le dehors, la végétation, la
## Guilde, les compagnons, les événements, le Donjon des Mille Marches) ; le ponton est posé avec
## le relief.
func _create_v71() -> void:
	if montjoie_v71 == null:
		return
	montjoie_v71.build_town()
	if journal_v56 != null:
		montjoie_v71.register_services(journal_v56)


## V75 : l'Île du Boucan (Port-Boucan, ses grands lieux, le dehors, la végétation, les animaux,
## Sardine, les concerts et la vie de la ville, les champignons féeriques, l'Usine Grise) ; le
## ponton est posé avec le relief.
func _create_v75() -> void:
	if boucan_v75 == null:
		return
	boucan_v75.build_town()
	if journal_v56 != null:
		boucan_v75.register_services(journal_v56)


## V76 : Astralys (la cité de cristal, le Rayon d'accueil, les aurores, les Lumens) ; la bouée est
## posée avec le relief.
func _create_v76() -> void:
	testeur_v78 = preload("res://scripts/testeur_v78.gd").new()
	testeur_v78.name = "Testeur_v78"
	add_child(testeur_v78)
	testeur_v78.setup(self)
	# V81 : toutes les maisons décoratives se visitent (les portes sont récupérées une fois le
	# monde construit, au début de la partie)
	maisons_v81 = preload("res://scripts/maisons_v81.gd").new()
	add_child(maisons_v81)
	maisons_v81.setup(self)
	compagnons_animaux_v76 = preload("res://scripts/compagnons_animaux_v76.gd").new()
	compagnons_animaux_v76.name = "Compagnons_animaux_v76"
	add_child(compagnons_animaux_v76)
	compagnons_animaux_v76.setup(self)
	# l'aéronef, et l'Atelier des Ailes de Cliquetis où on le construit
	aeronef_v76 = preload("res://scripts/aeronef_v76.gd").new()
	aeronef_v76.name = "Aeronef_v76"
	add_child(aeronef_v76)
	aeronef_v76.setup(self)
	aeronef_v76.build()
	if grande_v59 != null and grande_v59.get("cliquetis") != null:
		atelier_ailes_v76 = preload("res://scripts/atelier_ailes_v76.gd").new()
		atelier_ailes_v76.name = "Atelier_ailes_v76"
		add_child(atelier_ailes_v76)
		atelier_ailes_v76.setup(self, aeronef_v76)
		atelier_ailes_v76.build()
		if donjon_v35 != null:
			atelier_ailes_v76.register_interactions(donjon_v35)
		if journal_v56 != null:
			atelier_ailes_v76.register_services(journal_v56)
	elif donjon_v35 != null:
		aeronef_v76.register_interactions(donjon_v35)
	if astralys_v76 == null:
		return
	astralys_v76.build_town()
	if journal_v56 != null:
		astralys_v76.register_services(journal_v56)


## V87 : l'Île aux Moaïs (les statues, la végétation, les portes des petits Moaïs, la grande
## porte) ; le ponton est posé avec le relief.
func _create_v87() -> void:
	if moai_v87 == null:
		return
	moai_v87.build_town()
	if journal_v56 != null:
		moai_v87.register_services(journal_v56)


## V63 : la progression du héros (niveaux, talents, forge), les pouvoirs des sceaux, la grande
## enquête des Quatre Sceaux dans les quatre villages, le donjon sous le Cœur-de-Pierre.
## V65 : les histoires des habitants (chargées une fois) et leurs bavardages.
func _create_v65() -> void:
	Societe_v65.charger()
	bavardages_v65 = preload("res://scripts/pnj/bavardages_v65.gd").new()
	bavardages_v65.name = "Bavardages_v65"
	add_child(bavardages_v65)
	bavardages_v65.setup(self)


func _create_v63() -> void:
	progression_v63 = preload("res://scripts/progression_v63.gd").new()
	progression_v63.name = "Progression_v63"
	add_child(progression_v63)
	progression_v63.setup(self)
	pouvoirs_v63 = preload("res://scripts/pouvoirs_v63.gd").new()
	pouvoirs_v63.name = "Pouvoirs_v63"
	add_child(pouvoirs_v63)
	pouvoirs_v63.setup(self)
	if journal_v56 != null:
		progression_v63.register_services(journal_v56)
	if hud_v28 != null and not xr_active:
		progression_v63.make_hud(hud_v28)
	if grande_v59 != null and grande_v59.ile != null:
		sceaux_v63 = preload("res://scripts/sceaux_v63.gd").new()
		sceaux_v63.name = "Sceaux_v63"
		add_child(sceaux_v63)
		sceaux_v63.setup(self)
		sceaux_v63.build()
		coeur_v63 = preload("res://scripts/coeur_v63.gd").new()
		coeur_v63.name = "Coeur_de_pierre_v63"
		add_child(coeur_v63)
		coeur_v63.setup(self)
	progression_v63.apply()
	print("ILE_MANGA_V63: progression, pouvoirs des sceaux, grande enquête, Cœur-de-Pierre")


## V58 : le royaume des fées (feerie_v58.gd) : l'île au-dessus des nuages, les fées,
## Yggdrasil et son donjon ; la magie de téléportation (teleport_v58.gd).
func _create_v58() -> void:
	feerie_v58 = preload("res://scripts/feerie_v58.gd").new()
	feerie_v58.name = "Royaume_des_fees_v58"
	add_child(feerie_v58)
	feerie_v58.setup(self)
	feerie_v58.build()
	teleport_v58 = preload("res://scripts/teleport_v58.gd").new()
	teleport_v58.name = "Teleportation_v58"
	add_child(teleport_v58)
	teleport_v58.setup(self)


## V58 : T (ou le carnet, onglet Carte) : se téléporter dans un lieu déjà visité.
## V74 : le stick gauche de la manette (zéro sans manette, en VR ou dans un menu).
func pad_move_v74() -> Vector2:
	return manette_v74.move() if manette_v74 != null else Vector2.ZERO


func _create_manette_v74() -> void:
	manette_v74 = preload("res://scripts/manette_v74.gd").new()
	manette_v74.name = "Manette_v74"
	add_child(manette_v74)
	manette_v74.setup(self)


func open_teleport_v58() -> void:
	if teleport_v58 == null or inventory_v28 == null:
		return
	if not teleport_v58.known():
		_show_message_v28("Tu ne connais pas encore la magie de téléportation. Les fées, peut-être, un jour…")
		return
	inventory_v28.open(2)
	if inventory_v28.carnet != null:
		inventory_v28.carnet.show_teleport(true)


## V54 : le ciel (ciel_v54.gd) : l'aigle géant, l'île flottante et son château.
## V55 : la mer (mer_v55.gd) : nager et plonger, le fond marin, la vie sous-marine, l'Atlantide.
func _create_v55() -> void:
	mer_v55 = preload("res://scripts/mer_v55.gd").new()
	mer_v55.name = "Mer_v55"
	add_child(mer_v55)
	mer_v55.setup(self)
	mer_v55.build()
	print("ILE_MANGA_V55: la mer, le fond marin et l'Atlantide (%s)" % str(mer_v55.atl.C))


func _create_v54() -> void:
	ciel_v54 = preload("res://scripts/ciel_v54.gd").new()
	ciel_v54.name = "Ciel_v54"
	add_child(ciel_v54)
	ciel_v54.setup(self)
	ciel_v54.build()


func _create_decor_v53() -> void:
	decor_v53 = preload("res://scripts/decor_v53.gd").new()
	decor_v53.name = "Decor_village_v53"
	add_child(decor_v53)
	decor_v53.build(self, OS.has_feature("ile_manga_pc"))


func _create_v52() -> void:
	grotte_v52 = preload("res://scripts/grotte_cascade_v52.gd").new()
	grotte_v52.name = "Grotte_cascade_v52"
	add_child(grotte_v52)
	grotte_v52.build(self)
	foret_v52 = preload("res://scripts/lumiere_foret_v52.gd").new()
	foret_v52.name = "Lumiere_foret_v52"
	add_child(foret_v52)
	foret_v52.setup(self)


func _create_music_v51() -> void:
	music_v51 = preload("res://scripts/musique_v51.gd").new()
	music_v51.name = "Musique_v51"
	add_child(music_v51)
	music_v51.setup(self)


## V51 : un jingle (« victoire », « decouverte ») par-dessus la musique.
func jingle(name: String) -> void:
	if music_v51 != null:
		music_v51.jingle(name)


## Joue un bruitage (at : position dans le monde ; null : son d'interface).
func sfx(name: String, at: Variant = null, db: float = 0.0) -> void:
	if sfx_v50 != null:
		sfx_v50.play(name, at, db)

func _create_ambiance_v49() -> void:
	ambiance_v49 = preload("res://scripts/ambiance_v49.gd").new()
	ambiance_v49.name = "Ambiance_v49"
	add_child(ambiance_v49)
	ambiance_v49.setup(self)


## V48 : le modèle du héros déclare un matériau transparent (alpha « blend ») alors que sa
## texture est opaque : on le rend opaque (tri, ombres et reflets corrects).
static func _opaque_materials_v48(root: Node) -> void:
	if root == null:
		return
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var src: Material = m.get_surface_override_material(s)
			if src == null:
				src = m.mesh.surface_get_material(s)
			if src is StandardMaterial3D and (src as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				var op: StandardMaterial3D = (src as StandardMaterial3D).duplicate()
				op.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				m.set_surface_override_material(s, op)


## V48 : carte des fonds pour l'océan VR (lagon clair et écume le long de chaque rivage).
## 512 × 512 pixels sur 1600 m ; on ne mesure le relief que dans le carré de chaque île
## (le reste est le grand large). Valeur = (hauteur + 12) / 14, entre 0 et 1.
const SHORE_RES_V48: int = 768
const SHORE_ORIGIN_V48 := Vector2(-1400.0, -1000.0)   # V69 : la carte s'étend jusqu'à l'Île des Trois Soleils
const SHORE_SIZE_V48: float = 3000.0
var shore_image_v48: Image

func _bake_shore_v48() -> void:
	if ocean_material == null or ocean_material.shader == null or not str(ocean_material.shader.resource_path).ends_with("water.gdshader"):
		return
	var t0: int = Time.get_ticks_msec()
	var img := Image.create(SHORE_RES_V48, SHORE_RES_V48, false, Image.FORMAT_RF)
	img.fill(Color(0, 0, 0))
	var boxes: Array = [[Vector2(0.0, 4.0), 140.0]]
	if jungle_v29 != null:
		boxes.append([Vector2(jungle_v29.CENTER.x, jungle_v29.CENTER.z), 225.0])
	if elfes_v41 != null and elfes_v41.ile != null:
		boxes.append([Vector2(elfes_v41.ile.CENTER.x, elfes_v41.ile.CENTER.z), 145.0])
	if nains_v46 != null and nains_v46.ile != null:
		boxes.append([Vector2(nains_v46.ile.CENTER.x, nains_v46.ile.CENTER.z), 145.0])
	if azur_v56 != null and azur_v56.ile != null:
		boxes.append([Vector2(azur_v56.ile.CENTER.x, azur_v56.ile.CENTER.z), 205.0])
	if grande_v59 != null and grande_v59.ile != null:
		boxes.append([Vector2(grande_v59.ile.GRID.x, grande_v59.ile.GRID.z), grande_v59.ile.HALF])
	if arcanelle_v67 != null and arcanelle_v67.ile != null:
		boxes.append([Vector2(arcanelle_v67.ile.CENTER.x, arcanelle_v67.ile.CENTER.z), arcanelle_v67.ile.HALF])
	if pirates_v68 != null and pirates_v68.ile != null:
		boxes.append([Vector2(pirates_v68.ile.CENTER.x, pirates_v68.ile.CENTER.z), pirates_v68.ile.HALF])
	if soleils_v69 != null and soleils_v69.ile != null:
		boxes.append([Vector2(soleils_v69.ile.CENTER.x, soleils_v69.ile.CENTER.z), soleils_v69.ile.HALF])
	if braise_v70 != null and braise_v70.ile != null:
		boxes.append([Vector2(braise_v70.ile.CENTER.x, braise_v70.ile.CENTER.z), braise_v70.ile.HALF])
	if montjoie_v71 != null and montjoie_v71.ile != null:
		boxes.append([Vector2(montjoie_v71.ile.CENTER.x, montjoie_v71.ile.CENTER.z), montjoie_v71.ile.HALF])
	if boucan_v75 != null and boucan_v75.ile != null:
		boxes.append([Vector2(boucan_v75.ile.CENTER.x, boucan_v75.ile.CENTER.z), boucan_v75.ile.HALF])
	if moai_v87 != null and moai_v87.ile != null:
		boxes.append([Vector2(moai_v87.ile.CENTER.x, moai_v87.ile.CENTER.z), moai_v87.ile.HALF])
	var px: float = SHORE_SIZE_V48 / SHORE_RES_V48
	var samples: int = 0
	for b in boxes:
		var c: Vector2 = b[0]
		var half: float = b[1]
		var x0: int = clampi(int((c.x - half - SHORE_ORIGIN_V48.x) / px), 0, SHORE_RES_V48 - 1)
		var x1: int = clampi(int((c.x + half - SHORE_ORIGIN_V48.x) / px) + 1, 0, SHORE_RES_V48 - 1)
		var z0: int = clampi(int((c.y - half - SHORE_ORIGIN_V48.y) / px), 0, SHORE_RES_V48 - 1)
		var z1: int = clampi(int((c.y + half - SHORE_ORIGIN_V48.y) / px) + 1, 0, SHORE_RES_V48 - 1)
		for zi in range(z0, z1 + 1):
			for xi in range(x0, x1 + 1):
				var wx: float = SHORE_ORIGIN_V48.x + (xi + 0.5) * px
				var wz: float = SHORE_ORIGIN_V48.y + (zi + 0.5) * px
				var h: float = _height_at(wx, wz)
				var v: float = clampf((h + 12.0) / 14.0, 0.0, 1.0)
				if v > img.get_pixel(xi, zi).r:
					img.set_pixel(xi, zi, Color(v, 0, 0))
				samples += 1
	shore_image_v48 = img
	ocean_material.set_shader_parameter("shore_map", ImageTexture.create_from_image(img))
	ocean_material.set_shader_parameter("shore_origin", SHORE_ORIGIN_V48)
	ocean_material.set_shader_parameter("shore_size", SHORE_SIZE_V48)
	ocean_material.set_shader_parameter("has_shore", true)
	print("ILE_MANGA_V48: carte des rivages ", samples, " mesures en ", Time.get_ticks_msec() - t0, " ms")


## V80 : sur un clavier AZERTY, la rangée des chiffres donne « & é " ' ( … » sans Maj ; pour les
## raccourcis 1 à 9 (carnet, pouvoirs, sorts), on lit la touche physique quand c'en est un chiffre.
func _digit_key_v80(event: InputEventKey) -> Key:
	var p: Key = event.physical_keycode
	if p >= KEY_0 and p <= KEY_9:
		return p
	return event.keycode

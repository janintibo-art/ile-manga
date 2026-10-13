extends Node3D
## V13: falaises et cascades décoratives ; V21 : piliers rocheux solides.
## Distantes du village. Aucun contrôle joueur ou relief de navigation modifié.
var elapsed: float = 0.0
var falling_water: Array[MeshInstance3D] = []

func build(height_func: Callable, pc_quality: bool) -> void:
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.46, 0.48, 0.51)
	rock.roughness = 0.96
	var strata := StandardMaterial3D.new()
	strata.albedo_color = Color(0.61, 0.57, 0.53)
	strata.roughness = 0.95
	var moss := StandardMaterial3D.new()
	moss.albedo_color = Color(0.31, 0.49, 0.31)
	moss.roughness = 1.0
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.57, 0.87, 0.98, 0.73)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	water.roughness = 0.25
	var mist := StandardMaterial3D.new()
	mist.albedo_color = Color(0.83, 0.96, 0.98, 0.45)
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Compositions éloignées des maisons et du point d'apparition.
	_make_cliff(Vector2(43.0, -33.0), 16.0, 20.0, height_func, rock, strata, moss, 1410, pc_quality)
	_make_cliff(Vector2(-45.0, -39.0), 18.0, 18.0, height_func, rock, strata, moss, 2610, pc_quality)
	_make_falls(Vector2(43.0, -33.0), 16.0, height_func, water, mist, pc_quality)
	_make_falls(Vector2(-45.0, -39.0), 18.0, height_func, water, mist, pc_quality)
	print("ILE_MANGA_V13: deux promontoires, deux cascades visuelles")

func _make_cliff(center: Vector2, radius: float, height: float, ground: Callable, rock: Material, strata: Material, moss: Material, seed_value: int, pc_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base_y: float = float(ground.call(center.x, center.y))
	var stacks: int = 24 if pc_quality else 13
	for i in range(stacks):
		var theta: float = TAU * float(i) / float(stacks)
		var distance: float = rng.randf_range(radius * 0.24, radius * 0.75)
		var x: float = center.x + cos(theta) * distance
		var z: float = center.y + sin(theta) * distance
		var h: float = height * rng.randf_range(0.53, 1.04)
		var stone := MeshInstance3D.new()
		stone.name = "Falaise_roche_v13"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = rng.randf_range(1.7, 3.7)
		cylinder.bottom_radius = rng.randf_range(3.4, 5.5)
		cylinder.height = h
		cylinder.radial_segments = 7
		stone.mesh = cylinder
		stone.material_override = strata if i % 4 == 0 else rock
		stone.position = Vector3(x, float(ground.call(x, z)) + h * 0.5 - 0.7, z)
		stone.rotation.y = rng.randf_range(-PI, PI)
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if pc_quality else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stone)
		_add_solid_v21(stone.position, (cylinder.top_radius + cylinder.bottom_radius) * 0.45, h)
		if i % 3 == 0:
			var cap := MeshInstance3D.new()
			cap.name = "Couronne_vegetale_v13"
			var cap_mesh := SphereMesh.new()
			cap_mesh.radius = cylinder.top_radius * 1.04
			cap_mesh.height = 0.55
			cap_mesh.radial_segments = 9
			cap_mesh.rings = 3
			cap.mesh = cap_mesh
			cap.material_override = moss
			cap.position = stone.position + Vector3(0, h * 0.48, 0)
			add_child(cap)
	# Éboulis : uniquement des maillages partagés et peu d'instances.
	var pebble_mesh := SphereMesh.new()
	pebble_mesh.radius = 0.75
	pebble_mesh.height = 0.55
	pebble_mesh.radial_segments = 7
	pebble_mesh.rings = 3
	var count: int = 44 if pc_quality else 18
	for j in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(radius * 0.64, radius * 1.05)
		var x: float = center.x + cos(angle) * dist
		var z: float = center.y + sin(angle) * dist
		var pebble := MeshInstance3D.new()
		pebble.name = "Eboulis_v13"
		pebble.mesh = pebble_mesh
		pebble.material_override = strata
		pebble.position = Vector3(x, float(ground.call(x, z)) + 0.18, z)
		pebble.scale = Vector3(rng.randf_range(0.6, 1.8), 1.0, rng.randf_range(0.7, 1.7))
		pebble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pebble)

func _make_falls(center: Vector2, height: float, ground: Callable, water: Material, mist: Material, pc_quality: bool) -> void:
	var x: float = center.x
	var z: float = center.y + 7.5
	var floor_y: float = float(ground.call(x, z))
	var lanes: int = 5 if pc_quality else 3
	for k in range(lanes):
		var curtain := MeshInstance3D.new()
		curtain.name = "Cascade_v13"
		var quad := QuadMesh.new()
		quad.size = Vector2(1.65, height * 0.86)
		curtain.mesh = quad
		curtain.material_override = water
		curtain.position = Vector3(x + (float(k) - float(lanes - 1) * 0.5) * 1.0, floor_y + height * 0.43, z + float(k % 2) * 0.18)
		curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(curtain)
		falling_water.append(curtain)
	for j in range(4 if pc_quality else 2):
		var spray := MeshInstance3D.new()
		spray.name = "Ecume_cascade_v13"
		var disk := SphereMesh.new()
		disk.radius = 1.2
		disk.height = 0.35
		disk.radial_segments = 12
		disk.rings = 3
		spray.mesh = disk
		spray.material_override = mist
		spray.position = Vector3(x + (float(j) - 1.5) * 1.25, floor_y + 0.24, z + 0.55)
		add_child(spray)

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(falling_water.size()):
		var curtain: MeshInstance3D = falling_water[i]
		if is_instance_valid(curtain):
			curtain.transparency = clampf(0.18 - sin(elapsed * 1.8 + float(i) * 0.65) * 0.12, 0.0, 1.0)


# V21 : collision cylindrique sur la couche 1, celle que le joueur heurte.
func _add_solid_v21(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Falaise_collision_v21"
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	add_child(body)

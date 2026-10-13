extends Node3D
## V16 : bosquets feeriques, champignons lumineux et fougeres.
## V21 : les troncs sont solides comme les arbres du village.

func build(terrain_height: Callable, pc_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 16102026
	var centers: Array[Vector2] = [Vector2(34.0, 29.0), Vector2(-37.0, 29.0), Vector2(52.0, 4.0)]
	var n: int = 68 if pc_quality else 28
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.45
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 7
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.0
	crown_mesh.height = 1.6
	crown_mesh.radial_segments = 10 if pc_quality else 7
	crown_mesh.rings = 6 if pc_quality else 4
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.40, 0.27, 0.20)
	wood_mat.roughness = 1.0
	trunk_mesh.material = wood_mat
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.31, 0.69, 0.41)
	leaf_mat.roughness = 0.94
	crown_mesh.material = leaf_mat
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.use_colors = true
	trunks.mesh = trunk_mesh
	trunks.instance_count = n
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	crowns.use_colors = true
	crowns.mesh = crown_mesh
	crowns.instance_count = n
	var count: int = 0
	for i in range(n * 16):
		if count >= n:
			break
		var center: Vector2 = centers[rng.randi_range(0, centers.size() - 1)]
		var x: float = center.x + rng.randf_range(-14.0, 14.0)
		var z: float = center.y + rng.randf_range(-13.0, 13.0)
		if Vector2(x, z - 4.0).length() < 23.0:
			continue
		if Vector2(x - 43.0, z + 33.0).length() < 19.0:
			continue
		var y: float = float(terrain_height.call(x, z))
		if y < 1.1 or y > 7.3:
			continue
		var h: float = rng.randf_range(4.5, 7.8)
		var crown_width: float = rng.randf_range(1.6, 2.65)
		var rot: float = rng.randf_range(-PI, PI)
		trunks.set_instance_transform(count, Transform3D(Basis(Vector3.UP, rot).scaled(Vector3(1.0, h, 1.0)), Vector3(x, y + h * 0.5, z)))
		trunks.set_instance_color(count, Color(rng.randf_range(0.88, 1.08), rng.randf_range(0.88, 1.05), 1.0))
		crowns.set_instance_transform(count, Transform3D(Basis(Vector3.UP, rot).scaled(Vector3(crown_width, rng.randf_range(1.7, 2.25), crown_width)), Vector3(x, y + h + 0.25, z)))
		crowns.set_instance_color(count, Color(rng.randf_range(0.72, 1.08), rng.randf_range(0.90, 1.11), rng.randf_range(0.81, 1.12)))
		_add_trunk_collision_v21(Vector3(x, y + h * 0.5, z), h)
		count += 1
	trunks.visible_instance_count = count
	crowns.visible_instance_count = count
	_add_batch("Foret_troncs_v16", trunks, pc_quality)
	_add_batch("Foret_canopes_v16", crowns, pc_quality)
	_create_undergrowth(terrain_height, centers, pc_quality, rng)
	print("ILE_MANGA_V16: forets feeriques instanciees = ", count)

func _add_batch(label: String, multimesh: MultiMesh, pc_quality: bool) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = multimesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = 105.0 if pc_quality else 65.0
	add_child(node)

func _create_undergrowth(terrain_height: Callable, centers: Array[Vector2], pc_quality: bool, rng: RandomNumberGenerator) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.42
	mesh.radial_segments = 7
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.66, 0.86, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.17, 0.42, 0.32)
	mat.emission_energy_multiplier = 0.8
	mesh.material = mat
	var total: int = 135 if pc_quality else 45
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = total
	var placed: int = 0
	for i in range(total * 10):
		if placed >= total:
			break
		var c: Vector2 = centers[rng.randi_range(0, centers.size() - 1)]
		var x: float = c.x + rng.randf_range(-13.0, 13.0)
		var z: float = c.y + rng.randf_range(-12.0, 12.0)
		var y: float = float(terrain_height.call(x, z))
		if y < 1.0 or y > 7.3:
			continue
		var scale_value: float = rng.randf_range(0.48, 1.28)
		mm.set_instance_transform(placed, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), Vector3(x, y + 0.12 * scale_value, z)))
		mm.set_instance_color(placed, Color(rng.randf_range(0.65, 1.1), rng.randf_range(0.87, 1.2), rng.randf_range(0.88, 1.16)))
		placed += 1
	mm.visible_instance_count = placed
	_add_batch("Sous_bois_feerique_v16", mm, pc_quality)


func _add_trunk_collision_v21(pos: Vector3, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Tronc_feerique_collision_v21"
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.42
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	add_child(body)

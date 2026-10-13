extends Node3D
## Ile Manga V15: decorations visuelles uniquement, sans collision ni commandes.
## Utilise MultiMesh pour reduire les appels de dessin sur Quest Link.

func build(height_func: Callable, pc_quality: bool) -> void:
	_add_flowerbeds(height_func, pc_quality)
	_add_coastal_reeds(height_func, pc_quality)
	_add_cliff_lichen(height_func, pc_quality)
	print("ILE_MANGA_V15: fleurs, roseaux et mousses, profil PC/VR")

func _make_batch(label: String, mesh: Mesh, count: int, color: Color) -> MultiMesh:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.98
	mesh.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = 95.0
	add_child(node)
	return mm

func _add_flowerbeds(ground: Callable, high: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 15152026
	var flower := SphereMesh.new()
	flower.radius = 0.19
	flower.height = 0.29
	flower.radial_segments = 6
	flower.rings = 3
	var total: int = 640 if high else 210
	var mm := _make_batch("Parterres_fantasy_v15", flower, total, Color.WHITE)
	var spots: Array[Vector2] = [Vector2(-18.0, 14.0), Vector2(-21.0, -4.0), Vector2(18.0, 12.0), Vector2(20.0, -7.0)]
	var palette: Array[Color] = [Color(1.0, 0.39, 0.63), Color(1.0, 0.86, 0.41), Color(0.69, 0.56, 1.0), Color(0.57, 0.83, 1.0), Color(0.96, 0.65, 0.85)]
	for i in range(total):
		var center: Vector2 = spots[i % spots.size()]
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = sqrt(rng.randf()) * rng.randf_range(2.5, 7.0)
		var x: float = center.x + cos(angle) * distance
		var z: float = center.y + sin(angle) * distance
		var y: float = float(ground.call(x, z))
		var scale_value: float = rng.randf_range(0.63, 1.35)
		var basis := Basis(Vector3.UP, angle).scaled(Vector3.ONE * scale_value)
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, y + 0.16 * scale_value, z)))
		mm.set_instance_color(i, palette[rng.randi_range(0, palette.size() - 1)])

func _add_coastal_reeds(ground: Callable, high: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 15022026
	var reed := CylinderMesh.new()
	reed.top_radius = 0.025
	reed.bottom_radius = 0.07
	reed.height = 0.95
	reed.radial_segments = 5
	var total: int = 430 if high else 120
	var mm := _make_batch("Roseaux_du_littoral_v15", reed, total, Color(0.52, 0.69, 0.35))
	for i in range(total):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(61.5, 68.5)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		var y: float = float(ground.call(x, z))
		var height_factor: float = rng.randf_range(0.56, 1.28)
		var basis := Basis(Vector3.UP, angle).scaled(Vector3(0.8, height_factor, 0.8))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, y + height_factor * 0.43, z)))
		mm.set_instance_color(i, Color(rng.randf_range(0.77, 1.0), rng.randf_range(0.92, 1.1), rng.randf_range(0.70, 0.96)))

func _add_cliff_lichen(ground: Callable, high: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 15032026
	var mat := SphereMesh.new()
	mat.radius = 0.63
	mat.height = 0.26
	mat.radial_segments = 7
	mat.rings = 3
	var total: int = 180 if high else 56
	var mm := _make_batch("Mousses_des_falaises_v15", mat, total, Color(0.49, 0.68, 0.39))
	var centers: Array[Vector2] = [Vector2(43.0, -33.0), Vector2(-45.0, -39.0)]
	for i in range(total):
		var center: Vector2 = centers[i % centers.size()]
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(8.0, 19.0)
		var x: float = center.x + cos(angle) * radius
		var z: float = center.y + sin(angle) * radius
		var y: float = float(ground.call(x, z))
		var size: float = rng.randf_range(0.5, 1.8)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, angle).scaled(Vector3(size, 1.0, size)), Vector3(x, y + 0.06, z)))
		mm.set_instance_color(i, Color(rng.randf_range(0.77, 1.0), rng.randf_range(0.88, 1.14), rng.randf_range(0.73, 0.95)))

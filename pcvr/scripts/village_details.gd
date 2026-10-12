extends Node3D
## V7 : détails graphiques non interactifs. Les pièces sont instanciées en lots.

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.9
	if glow:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 1.4
	return result


func _batch(name: String, mesh: Mesh, transforms: Array[Transform3D], material: Material, max_range: float) -> void:
	if transforms.is_empty():
		return
	mesh.material = material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = name
	node.multimesh = multi
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = max_range
	add_child(node)


func _placed(x: float, z: float, height_fn: Callable, scale: Vector3, yaw: float = 0.0, y_offset: float = 0.0) -> Transform3D:
	var terrain_y: float = height_fn.call(x, z)
	return Transform3D(Basis(Vector3.UP, yaw).scaled(scale), Vector3(x, terrain_y + y_offset, z))


func build(height_fn: Callable, pc_quality: bool) -> void:
	var visible_distance := 110.0 if pc_quality else 65.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7202610

	# Clôtures basses autour des deux maisons : une seule géométrie partagée.
	# L'entrée côté village reste libre ; les décorations n'ont pas de collisions.
	var posts: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	for center in [Vector2(9.0, 4.0), Vector2(-11.0, 9.0)]:
		for row in range(2):
			var z := center.y - 5.0 + float(row) * 10.0
			for i in range(9):
				var x := center.x - 5.0 + float(i) * 1.25
				if center.x > 0.0 and x < center.x - 2.0 and row == 0:
					continue
				posts.append(_placed(x, z, height_fn, Vector3(0.13, 1.2, 0.13), 0.0, 0.6))
				if i < 8:
					rails.append(_placed(x + 0.625, z, height_fn, Vector3(1.32, 0.10, 0.10), 0.0, 0.75))
	var post_mesh := BoxMesh.new()
	_batch("Clotures_piquets_v7", post_mesh, posts, _material(Color(0.43, 0.29, 0.19)), visible_distance)
	var rail_mesh := BoxMesh.new()
	_batch("Clotures_lisses_v7", rail_mesh, rails, _material(Color(0.55, 0.36, 0.21)), visible_distance)

	# Sentier secondaire vers la petite maison, avec pierres irrégulières.
	var stones: Array[Transform3D] = []
	for i in range(37):
		var t := float(i) / 36.0
		var x := lerpf(0.0, -11.0, t) + sin(t * TAU) * 0.8
		var z := lerpf(4.0, 9.0, t)
		stones.append(_placed(x, z, height_fn, Vector3(rng.randf_range(0.42, 0.76), 0.08, rng.randf_range(0.40, 0.70)), rng.randf_range(-0.5, 0.5), 0.04))
	var slab := CylinderMesh.new()
	slab.top_radius = 0.6
	slab.bottom_radius = 0.65
	slab.height = 1.0
	_batch("Sentier_secondaire_v7", slab, stones, _material(Color(0.73, 0.66, 0.53)), visible_distance)

	# Massifs de fleurs groupés près des sentiers : rouges / mauves / dorées.
	var palette := [Color(0.97, 0.39, 0.48), Color(0.75, 0.52, 0.94), Color(1.0, 0.85, 0.31)]
	var blossom := SphereMesh.new()
	blossom.radius = 0.10
	blossom.height = 0.20
	blossom.radial_segments = 6
	blossom.rings = 3
	for color_id in range(palette.size()):
		var flowers: Array[Transform3D] = []
		var count := 160 if pc_quality else 70
		for i in range(count):
			var angle := rng.randf_range(-PI, PI)
			var radius := rng.randf_range(4.0, 17.0)
			var x := cos(angle) * radius
			var z := 4.0 + sin(angle) * radius
			if Vector2(x - 9.0, z - 4.0).length() < 5.4 or Vector2(x + 11.0, z - 9.0).length() < 4.6:
				continue
			var h: float = height_fn.call(x, z)
			if h < 0.9:
				continue
			flowers.append(_placed(x, z, height_fn, Vector3.ONE * rng.randf_range(0.8, 1.6), 0.0, 0.28))
		_batch("Massifs_fleurs_v7_" + str(color_id), blossom.duplicate(), flowers, _material(palette[color_id]), visible_distance)

	# Petites bornes lumineuses, purement émissives en VR (sans lumières dynamiques).
	var markers: Array[Transform3D] = []
	for position in [Vector2(3.0, 1.0), Vector2(-4.0, 5.0), Vector2(-7.0, 7.0), Vector2(6.0, 5.0)]:
		markers.append(_placed(position.x, position.y, height_fn, Vector3(0.36, 0.46, 0.36), 0.0, 0.55))
	var orb := SphereMesh.new()
	orb.radius = 0.4
	orb.height = 0.8
	_batch("Balises_dorees_v7", orb, markers, _material(Color(1.0, 0.71, 0.32), true), visible_distance)
	print("ILE_MANGA_V7: village et chemins enrichis sans modifier la locomotion")

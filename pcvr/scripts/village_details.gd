extends Node3D
const Flora = preload("res://scripts/flora_v25.gd")
const Decor = preload("res://scripts/decor_v53.gd")
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
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = material
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
	if not (mesh is PrimitiveMesh):
		node.material_override = material
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
			var z: float = center.y - 5.0 + float(row) * 10.0
			for i in range(9):
				var x: float = center.x - 5.0 + float(i) * 1.25
				if center.x > 0.0 and x < center.x - 2.0 and row == 0:
					continue
				posts.append(_placed(x, z, height_fn, Vector3(0.13, 1.2, 0.13), 0.0, 0.6))
				if i < 8:
					rails.append(_placed(x + 0.625, z, height_fn, Vector3(1.32, 0.10, 0.07), rng.randf_range(-0.02, 0.02), 0.82))
					rails.append(_placed(x + 0.625, z, height_fn, Vector3(1.32, 0.09, 0.07), rng.randf_range(-0.02, 0.02), 0.42))
	# V23 : piquets, lisses et balises solides, en un seul corps statique.
	_solidify_v23("Clotures_collision_v23", posts + rails)
	# V53 : piquets de bois fendu (sept pans) et lisses en bois brut texturé.
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.42
	post_mesh.bottom_radius = 0.5
	post_mesh.height = 1.0
	post_mesh.radial_segments = 7
	post_mesh.rings = 1
	_batch("Clotures_piquets_v7", post_mesh, posts, Decor.wood(Color(0.62, 0.52, 0.42)), visible_distance)
	var rail_mesh := BoxMesh.new()
	_batch("Clotures_lisses_v7", rail_mesh, rails, Decor.wood(Color(0.7, 0.58, 0.46)), visible_distance)

	# V53 : le sentier vers la petite maison est dallé par decor_v53.gd.

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
			var x: float = cos(angle) * radius
			var z: float = 4.0 + sin(angle) * radius
			if Vector2(x - 9.0, z - 4.0).length() < 5.4 or Vector2(x + 11.0, z - 9.0).length() < 4.6:
				continue
			var h: float = height_fn.call(x, z)
			if h < 0.9:
				continue
			flowers.append(_placed(x, z, height_fn, Vector3.ONE * rng.randf_range(0.55, 0.9), rng.randf_range(-PI, PI), -0.02))
		# V25 : vraies touffes de fleurs, pétales teintés par massif.
		_batch("Massifs_fleurs_v7_" + str(color_id), Flora.flower_clump(), flowers, Flora.flower_material(palette[color_id]), visible_distance)

	print("ILE_MANGA_V7: village et chemins enrichis sans modifier la locomotion")


# V23 : une boîte de collision par élément, d'après la transformation du lot (maillage 1 x 1 x 1).
func _solidify_v23(label: String, transforms: Array[Transform3D]) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for t in transforms:
		var box := BoxShape3D.new()
		box.size = Vector3(maxf(t.basis.x.length(), 0.12), t.basis.y.length(), maxf(t.basis.z.length(), 0.12))
		var cs := CollisionShape3D.new()
		cs.shape = box
		cs.transform = Transform3D(t.basis.orthonormalized(), t.origin)
		body.add_child(cs)

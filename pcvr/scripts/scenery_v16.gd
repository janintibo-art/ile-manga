extends Node3D
const Flora = preload("res://scripts/flora_v25.gd")
## V16 : bosquets feeriques, champignons lumineux et fougeres.
## V21 : les troncs sont solides comme les arbres du village.

func build(terrain_height: Callable, pc_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 16102026
	var centers: Array[Vector2] = [Vector2(34.0, 29.0), Vector2(-37.0, 29.0), Vector2(52.0, 4.0)]
	var n: int = 68 if pc_quality else 28
	# V25 : deux variantes de grands feuillus, instanciées en lots.
	var leaves: int = 320 if pc_quality else 200
	var variants: Array[Mesh] = [Flora.tree(5200, 9.0, leaves), Flora.tree(5307, 10.0, leaves)]
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.use_colors = true
	trunks.mesh = variants[0]
	trunks.instance_count = n
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	crowns.use_colors = true
	crowns.mesh = variants[1]
	crowns.instance_count = n
	var placed_a: int = 0
	var placed_b: int = 0
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
		var s: float = (h + crown_width * 1.4) / 9.0
		var xf := Transform3D(Basis(Vector3.UP, rot).scaled(Vector3(s, s, s)), Vector3(x, y - 0.05, z))
		var tone := Color(rng.randf_range(0.86, 1.06), rng.randf_range(0.9, 1.08), rng.randf_range(0.85, 1.02))
		if count % 2 == 0:
			trunks.set_instance_transform(placed_a, xf)
			trunks.set_instance_color(placed_a, tone)
			placed_a += 1
		else:
			crowns.set_instance_transform(placed_b, xf)
			crowns.set_instance_color(placed_b, tone)
			placed_b += 1
		_add_trunk_collision_v21(Vector3(x, y + h * 0.5, z), h)
		count += 1
	trunks.visible_instance_count = placed_a
	crowns.visible_instance_count = placed_b
	_add_batch("Foret_troncs_v16", trunks, pc_quality)
	_add_batch("Foret_canopes_v16", crowns, pc_quality)
	_create_undergrowth(terrain_height, centers, pc_quality, rng)
	print("ILE_MANGA_V16: forets feeriques instanciees = ", count)

func _add_batch(label: String, multimesh: MultiMesh, pc_quality: bool) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = multimesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	node.visibility_range_end = 220.0 if pc_quality else 120.0
	add_child(node)

func _create_undergrowth(terrain_height: Callable, centers: Array[Vector2], pc_quality: bool, rng: RandomNumberGenerator) -> void:
	# V25 : fougères en rosette au lieu des boules lumineuses.
	var mesh: Mesh = Flora.fern_clump()
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
		var scale_value: float = rng.randf_range(0.7, 1.4)
		mm.set_instance_transform(placed, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_value), Vector3(x, y - 0.02, z)))
		mm.set_instance_color(placed, Color(rng.randf_range(0.8, 1.05), rng.randf_range(0.9, 1.1), rng.randf_range(0.8, 1.0)))
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

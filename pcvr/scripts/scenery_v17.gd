extends Node3D
const Flora = preload("res://scripts/flora_v25.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
## Île Manga V17 — sentiers de forêt, clairières, pierres et sous-bois.
## Décor uniquement, aucune collision ajoutée au terrain ou au joueur.

func build(ground: Callable, pc_quality: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17102026
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color(0.48, 0.36, 0.24)
	path_mat.roughness = 1.0
	var light_path := StandardMaterial3D.new()
	light_path.albedo_color = Color(0.68, 0.57, 0.39)
	light_path.roughness = 1.0
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.24, 0.43, 0.27)
	moss_mat.roughness = 1.0
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.55, 0.57, 0.55)
	stone_mat.roughness = 1.0
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.29, 0.54, 0.32)
	blade_mat.roughness = 1.0
	blade_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Ces chemins sont éloignés des maisons et des falaises V13.
	_draw_path(Vector2(17.0, 22.0), Vector2(34.0, 29.0), ground, rng, path_mat, light_path, pc_quality)
	_draw_path(Vector2(-19.0, 18.0), Vector2(-37.0, 29.0), ground, rng, path_mat, light_path, pc_quality)
	_draw_path(Vector2(23.0, -8.0), Vector2(52.0, 4.0), ground, rng, path_mat, light_path, pc_quality)
	var clearings: Array[Vector2] = [Vector2(34.0, 29.0), Vector2(-37.0, 29.0), Vector2(52.0, 4.0)]
	var pebble_mesh := SphereMesh.new()
	pebble_mesh.radius = 0.45
	pebble_mesh.height = 0.28
	pebble_mesh.radial_segments = 7
	pebble_mesh.rings = 3
	var tuft_mesh := QuadMesh.new()
	tuft_mesh.size = Vector2(0.28, 0.47)
	for center in clearings:
		var stones: int = 20 if pc_quality else 8
		for i in range(stones):
			var angle: float = rng.randf_range(0.0, TAU)
			var radius: float = rng.randf_range(5.0, 10.0)
			var x: float = center.x + cos(angle) * radius
			var z: float = center.y + sin(angle) * radius
			var pebble := MeshInstance3D.new()
			pebble.name = "Pierre_clairiere_v17"
			pebble.mesh = Rocks.pebble(1700 + i % 5)
			pebble.material_override = Rocks.material(Color(0.8, 0.8, 0.76), 0.15 if i % 3 == 0 else 0.75, 0.9)
			pebble.position = Vector3(x, float(ground.call(x, z)) + 0.08, z)
			pebble.scale = Vector3(rng.randf_range(0.65, 1.6), 1.0, rng.randf_range(0.7, 1.45))
			pebble.rotation.y = rng.randf() * TAU
			add_child(pebble)
		var grass_count: int = 420 if pc_quality else 140
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = Flora.grass_clump(14, 0.55, 0.05, 21)
		mm.instance_count = grass_count
		for i in range(grass_count):
			var a: float = rng.randf_range(0.0, TAU)
			var radius: float = rng.randf_range(5.0, 13.0)
			var x: float = center.x + cos(a) * radius
			var z: float = center.y + sin(a) * radius
			var size: float = rng.randf_range(0.55, 1.3)
			var basis := Basis(Vector3.UP, a).scaled(Vector3(size, size, size))
			mm.set_instance_transform(i, Transform3D(basis, Vector3(x, float(ground.call(x, z)) - 0.02, z)))
			mm.set_instance_color(i, Color(0.85 + 0.15 * rng.randf(), 0.9 + 0.1 * rng.randf(), 0.82 + 0.18 * rng.randf()))
		var tufts := MultiMeshInstance3D.new()
		tufts.name = "Sous_bois_v17"
		tufts.multimesh = mm
		tufts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tufts.visibility_range_end = 80.0 if pc_quality else 48.0
		add_child(tufts)
	print("ILE_MANGA_V17: sentiers et clairieres, qualite PC/VR")

func _draw_path(start: Vector2, destination: Vector2, ground: Callable, rng: RandomNumberGenerator, soil: Material, rim: Material, pc_quality: bool) -> void:
	var steps: int = 64 if pc_quality else 32
	var segment_mesh := PlaneMesh.new()
	segment_mesh.size = Vector2(2.25, 1.2)
	for i in range(steps):
		var t: float = (float(i) + 0.5) / float(steps)
		var direction: Vector2 = destination - start
		var axis: Vector2 = direction.normalized()
		var normal: Vector2 = Vector2(-axis.y, axis.x)
		var bend: float = sin(t * PI * 2.1) * 1.15
		var pos: Vector2 = start.lerp(destination, t) + normal * bend
		var piece := MeshInstance3D.new()
		piece.name = "Sentier_forestier_v17"
		piece.mesh = segment_mesh
		piece.material_override = soil if i % 6 != 0 else rim
		piece.position = Vector3(pos.x, float(ground.call(pos.x, pos.y)) + 0.035, pos.y)
		piece.rotation.y = -atan2(direction.x, direction.y)
		piece.scale = Vector3(rng.randf_range(0.86, 1.1), 1.0, direction.length() / float(steps) * 1.1)
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(piece)

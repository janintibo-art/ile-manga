extends Node3D
## V18: village ornamental improvements. No physics objects added.

func build(ground: Callable, pc_quality: bool) -> void:
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color(0.41, 0.26, 0.16)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.64, 0.59, 0.49)
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.24, 0.55, 0.31)
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(1.0, 0.80, 0.40)
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.emission_enabled = true
	light.emission = Color(1.0, 0.49, 0.14)
	light.emission_energy_multiplier = 1.25
	var colors: Array[Color] = [Color(0.96, 0.49, 0.61), Color(0.92, 0.79, 0.33), Color(0.58, 0.62, 0.98)]
	# Flower beds alongside (not across) existing house approaches.
	for pt in [Vector2(3.2, 3.0), Vector2(14.5, 4.0), Vector2(-15.4, 11.9), Vector2(-7.0, 11.9)]:
		var y: float = float(ground.call(pt.x, pt.y))
		_add_box("Jardiniere_v18", Vector3(pt.x, y + 0.25, pt.y), Vector3(1.6, 0.45, 0.62), timber)
		_add_box("Terre_v18", Vector3(pt.x, y + 0.49, pt.y), Vector3(1.42, 0.10, 0.50), stone)
		for j in range(5 if pc_quality else 3):
			var x: float = pt.x - 0.56 + float(j) * (1.12 / float(4 if pc_quality else 2))
			_add_orb("Fleur_v18", Vector3(x, y + 0.68 + 0.07 * sin(float(j)), pt.y), 0.16, _flower_material(colors[j % 3]))
	# Subtle village markers, leaving a wide path towards the campfire.
	for pt in [Vector2(16.0, 8.0), Vector2(-17.5, 8.0)]:
		var y: float = float(ground.call(pt.x, pt.y))
		_add_box("Borne_pierre_v18", Vector3(pt.x, y + 0.39, pt.y), Vector3(0.62, 0.78, 0.62), stone)
		_add_orb("Lueur_v18", Vector3(pt.x, y + 0.95, pt.y), 0.22, light)
	# Small grouped props behind the houses, without collision or shadows.
	for pt in [Vector2(15.0, 12.2), Vector2(-15.1, 14.8)]:
		var y: float = float(ground.call(pt.x, pt.y))
		for j in range(2 if pc_quality else 1):
			_add_box("Caisse_marche_v18", Vector3(pt.x + float(j) * 0.62, y + 0.3, pt.y), Vector3(0.55, 0.6, 0.55), timber)
	print("ILE_MANGA_V18: village amenage, decor sans collision")

var _flower_cache_v22: Dictionary = {}

func _flower_material(c: Color) -> StandardMaterial3D:
	var key: String = c.to_html()
	if _flower_cache_v22.has(key):
		return _flower_cache_v22[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 1.0
	_flower_cache_v22[key] = mat
	return mat

func _add_box(label: String, at: Vector3, size: Vector3, material: Material) -> void:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = material
	item.position = at
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(item)

func _add_orb(label: String, at: Vector3, radius: float, material: Material) -> void:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	item.mesh = mesh
	item.material_override = material
	item.position = at
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(item)

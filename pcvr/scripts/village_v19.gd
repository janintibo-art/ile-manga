extends Node3D
## V19 : silhouettes de toitures et habillage fantasy des maisons.
## V23 : encadrements et appuis de fenêtres solides.

func build(ground: Callable, pc_quality: bool) -> void:
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.52, 0.27, 0.22)
	roof.roughness = 0.89
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color(0.34, 0.22, 0.15)
	timber.roughness = 0.91
	var plaster := StandardMaterial3D.new()
	plaster.albedo_color = Color(0.91, 0.81, 0.63)
	plaster.roughness = 0.99
	var window_mat := StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.29, 0.63, 0.73)
	window_mat.roughness = 0.16
	window_mat.metallic = 0.08
	# Surélévations décoratives, positionnées sur les maisons existantes.
	# Les couvertures sont en surplomb ; leurs hauteurs pourront être ajustées
	# aux GLB après inspection du rendu sur PC et dans le casque.
	_make_house(Vector2(9.0, 4.0), 6.0, 3.0, ground, roof, timber, plaster, window_mat, pc_quality)
	_make_house(Vector2(-11.0, 9.0), 4.5, 2.3, ground, roof, timber, plaster, window_mat, pc_quality)
	print("ILE_MANGA_V19: couvertures et finitions fantasy, PC/VR")

func _box(label: String, pos: Vector3, size: Vector3, mat: Material, angle: float = 0.0) -> void:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = mat
	item.position = pos
	item.rotation.y = angle
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(item)

func _make_house(center: Vector2, width: float, lift: float, ground: Callable, roof: Material, timber: Material, plaster: Material, glass: Material, pc_quality: bool) -> void:
	var x: float = center.x
	var z: float = center.y
	var base: float = float(ground.call(x, z))
	# Bandeaux de façade et chevrons. Sans masquer portes et chemins.
	_box("Bandeau_toiture_v19", Vector3(x, base + lift + 0.32, z), Vector3(width + 0.35, 0.22, width * 0.75 + 0.35), timber)
	# Couverture à deux pans faiblement inclinés, légère en VR.
	for side in [-1.0, 1.0]:
		var slope := MeshInstance3D.new()
		slope.name = "Pan_de_toit_v19"
		var plane := BoxMesh.new()
		plane.size = Vector3(width * 0.56, 0.12, width * 0.86)
		slope.mesh = plane
		slope.material_override = roof
		slope.position = Vector3(x + side * width * 0.245, base + lift + 0.77, z)
		slope.rotation.z = side * 0.32
		slope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(slope)
	# Encadrements et fenêtres décoratives en façade avant.
	for side in [-1.0, 1.0]:
		var px: float = x + side * width * 0.31
		var pz: float = z + width * 0.39
		_box("Encadrement_fenetre_v19", Vector3(px, base + lift * 0.65, pz), Vector3(0.98, 1.06, 0.10), timber)
		_solid_v23(Vector3(px, base + lift * 0.65, pz + 0.07), Vector3(1.12, 1.06, 0.36))
		_box("Vitre_fantasy_v19", Vector3(px, base + lift * 0.65, pz + 0.065), Vector3(0.71, 0.78, 0.06), glass)
		if pc_quality:
			_box("Appui_pierre_v19", Vector3(px, base + lift * 0.43, pz + 0.13), Vector3(1.12, 0.12, 0.30), plaster)

# ILE_MANGA_V20_FINITION_2


func _solid_v23(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Fenetre_collision_v23"
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)

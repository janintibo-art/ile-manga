extends Node3D
## V34 : traînée lumineuse derrière la lame (épée, hache) quand on frappe vite.
## Elle suit le repère « Pointe » de l'arme tenue : au PC dans la main du héros, en VR dans
## la main droite. Un ruban qui s'efface en 0,18 s, plus vif pour l'épée d'acier.

const LIFE: float = 0.18
const MIN_SPEED: float = 3.2

var main: Node
var _mesh: ImmediateMesh
var _points: Array = []          # [pointe, base, âge]
var _prev_tip: Vector3 = Vector3.INF
var _mat: StandardMaterial3D


func setup(main_node: Node) -> void:
	main = main_node
	_mesh = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.name = "Trainee_lame"
	mi.mesh = _mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = false
	mi.material_override = _mat
	add_child(mi)


func _holder() -> Node3D:
	if main.inventory_v28 == null or not (main.inventory_v28.equipped in ["epee", "hache", "epee_bois", "epee_naine", "epee_nuees"]):
		return null
	if main.xr_active:
		return main.right_hand.get_node_or_null("Arme_VR_v28") as Node3D
	return main.hero_v28.sword_holder if main.hero_v28 != null else null


func _process(delta: float) -> void:
	if main == null:
		return
	for p in _points:
		p[2] = float(p[2]) + delta
	while not _points.is_empty() and float(_points[0][2]) > LIFE:
		_points.pop_front()
	var holder: Node3D = _holder()
	if holder != null and is_instance_valid(holder):
		var tip_node: Node3D = holder.find_child("Pointe", true, false) as Node3D
		if tip_node != null:
			var tip: Vector3 = tip_node.global_position
			var hand: Vector3 = holder.global_position
			var speed: float = 0.0 if _prev_tip == Vector3.INF else tip.distance_to(_prev_tip) / maxf(delta, 0.001)
			_prev_tip = tip
			var striking: bool = speed > MIN_SPEED and (main.xr_active or main.hero_v28.state == "attaque")
			if striking:
				_points.append([tip, hand.lerp(tip, 0.35), 0.0])
	else:
		_prev_tip = Vector3.INF
	_draw()


func _draw() -> void:
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	var steel: bool = main.inventory_v28.equipped in ["epee", "epee_naine", "epee_nuees"]
	var col: Color = Color(0.75, 0.9, 1.0) if steel else Color(1.0, 0.85, 0.6)
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in _points:
		var a: float = clampf(1.0 - float(p[2]) / LIFE, 0.0, 1.0) * (0.55 if steel else 0.35)
		_mesh.surface_set_color(Color(col.r, col.g, col.b, a))
		_mesh.surface_add_vertex(p[0])
		_mesh.surface_set_color(Color(col.r, col.g, col.b, 0.0))
		_mesh.surface_add_vertex(p[1])
	_mesh.surface_end()

extends Node3D
## V34 : traînée lumineuse derrière la lame (épée, hache) quand on frappe vite.
## Elle suit le repère « Pointe » de l'arme tenue : au PC dans la main du héros, en VR dans
## la main droite.
## V129 : la traînée prend la couleur de l'âme de l'arme (armes_v129.gd) : un voile coloré et
## un fil de lumière vive au bord, lissés en courbe ; elle couvre tout le fil (pas seulement le
## bout) ; toutes les armes en ont une, même le bâton et la Lame du Cœur.

const Armes := preload("res://scripts/armes_v129.gd")
const LIFE: float = 0.24
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


func _item() -> String:
	return str(main.inventory_v28.equipped) if main.inventory_v28 != null else ""


func _holder() -> Node3D:
	if main.inventory_v28 == null or not Armes.has(_item()):
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
			var model: Node3D = tip_node.get_parent() as Node3D
			var fil: Array = Armes.FILS.get(_item(), [0.1, 0.8, 0.0])
			var base: Vector3 = model.to_global(Vector3(float(fil[2]) * 0.1, float(fil[0]), 0.0)) if model != null else holder.global_position.lerp(tip, 0.35)
			var speed: float = 0.0 if _prev_tip == Vector3.INF else tip.distance_to(_prev_tip) / maxf(delta, 0.001)
			_prev_tip = tip
			var striking: bool = speed > MIN_SPEED and (main.xr_active or main.hero_v28.state == "attaque")
			if striking:
				_points.append([tip, base, 0.0])
	else:
		_prev_tip = Vector3.INF
	_draw()


## Points lissés (Catmull-Rom) entre les échantillons : la traînée suit un bel arc.
func _smooth() -> Array:
	var out: Array = []
	var n: int = _points.size()
	for i in range(n - 1):
		var p0: Array = _points[maxi(i - 1, 0)]
		var p1: Array = _points[i]
		var p2: Array = _points[i + 1]
		var p3: Array = _points[mini(i + 2, n - 1)]
		for k in range(3):
			var t: float = k / 3.0
			var tip: Vector3 = _cr(p0[0], p1[0], p2[0], p3[0], t)
			var base: Vector3 = _cr(p0[1], p1[1], p2[1], p3[1], t)
			out.append([tip, base, lerpf(float(p1[2]), float(p2[2]), t)])
	out.append(_points[n - 1])
	return out


func _cr(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 + (-a + 3.0 * b - 3.0 * c + d) * t3)


func _draw() -> void:
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	var a: Dictionary = Armes.ame(_item())
	var col: Color = a["c"]
	var core: Color = a["c2"]
	var pts: Array = _smooth()
	# le voile coloré, de la base au bout
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in pts:
		var f: float = clampf(1.0 - float(p[2]) / LIFE, 0.0, 1.0)
		_mesh.surface_set_color(Color(col.r, col.g, col.b, f * f * 0.6))
		_mesh.surface_add_vertex(p[0])
		_mesh.surface_set_color(Color(col.r, col.g, col.b, 0.0))
		_mesh.surface_add_vertex(p[1])
	_mesh.surface_end()
	# le fil de lumière vive, tout au bord
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in pts:
		var f2: float = clampf(1.0 - float(p[2]) / LIFE, 0.0, 1.0)
		var tip: Vector3 = p[0]
		var base: Vector3 = p[1]
		_mesh.surface_set_color(Color(core.r, core.g, core.b, f2 * f2 * 0.95))
		_mesh.surface_add_vertex(tip)
		_mesh.surface_set_color(Color(core.r, core.g, core.b, 0.0))
		_mesh.surface_add_vertex(tip.lerp(base, 0.16))
	_mesh.surface_end()

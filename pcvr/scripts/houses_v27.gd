extends Node3D
## V27 : portes qui s'ouvrent et intérieurs des deux maisons.
## Les maisons sont des modèles d'un seul tenant : la porte y est peinte. On découpe donc
## le mur à la forme exacte de la porte peinte (shader house_v27), on pose à la place
## un vrai battant en bois monté sur charnière, et on aménage une pièce derrière.
## Toutes les cotes sont dans le repère du modèle (avant mise à l'échelle) : elles suivent
## la maison si sa position ou sa taille change.

const OPEN_ANGLE: float = 1.75        # ~100°, vers l'intérieur
const SWING_SPEED: float = 2.2        # rad/s
const REACH: float = 2.3              # distance d'interaction (m)
const THICKNESS: float = 0.07

## Ouverture (repère modèle) et pièce intérieure (repère modèle) de chaque maison.
## Ces valeurs viennent des relevés de façade de la V27 (voir tools/bake_collisions_v24.gd).
const HOUSES := {
	"Maison_village": {
		"hole_x": Vector2(-0.0942, 0.0924), "hole_z": Vector2(0.144, 0.344),
		"bottom": -0.648, "spring": -0.3422, "apex": -0.2542,
		"door_z": 0.27, "leaves": [1],
		"room_x": Vector2(-0.70, 0.70), "room_z": Vector2(-0.50, 0.15), "floor": -0.7766, "height": 0.6,
		"kind": "maison",
	},
	"Petite_maison": {
		"hole_x": Vector2(-0.2967, 0.2967), "hole_z": Vector2(0.283, 0.583),
		"bottom": -0.643, "spring": -0.3047, "apex": -0.1947,
		"door_z": 0.40, "leaves": [1, -1],
		"room_x": Vector2(-0.38, 0.64), "room_z": Vector2(-0.60, 0.32), "floor": -0.733, "height": 0.58,
		"kind": "atelier",
	},
}

var doors: Array = []   # chaque porte : {pivot, base, target, angle, sign, center, label}
var pc_quality: bool = true
var _wood: StandardMaterial3D
var _beam: StandardMaterial3D
var _wall: StandardMaterial3D
var _floor: StandardMaterial3D
var _ceiling: StandardMaterial3D


static func hole_for(label: String) -> Dictionary:
	return HOUSES.get(label, {})


func build(houses: Array, high_quality: bool) -> void:
	pc_quality = high_quality
	_make_materials()
	for house in houses:
		if house == null or not HOUSES.has(str(house.name)):
			continue
		var cfg: Dictionary = HOUSES[str(house.name)]
		_cut_doorway(house, cfg)
		_make_doors(house, cfg)
		_make_room(house, cfg)
	print("ILE_MANGA_V27: ", doors.size(), " battants de porte, intérieurs aménagés")


# ------------------------------------------------------------------ ouverture dans le mur

func _cut_doorway(house: Node3D, cfg: Dictionary) -> void:
	var pending: Array[Node] = [house]
	while not pending.is_empty():
		var n: Node = pending.pop_back()
		for c in n.get_children():
			pending.append(c)
		if not (n is MeshInstance3D):
			continue
		var mi: MeshInstance3D = n
		var original: Material = mi.mesh.surface_get_material(0)
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/house_v27.gdshader")
		if original is StandardMaterial3D:
			var sm: StandardMaterial3D = original
			m.set_shader_parameter("albedo_tex", sm.albedo_texture)
			m.set_shader_parameter("normal_tex", sm.normal_texture)
			m.set_shader_parameter("orm_tex", sm.roughness_texture)
			m.set_shader_parameter("metallic_value", sm.metallic)
			m.set_shader_parameter("roughness_value", sm.roughness)
		m.set_shader_parameter("hole_x", cfg["hole_x"])
		m.set_shader_parameter("hole_z", cfg["hole_z"])
		m.set_shader_parameter("hole_bottom", cfg["bottom"])
		m.set_shader_parameter("hole_spring", cfg["spring"])
		m.set_shader_parameter("hole_apex", cfg["apex"])
		mi.material_override = m


# ------------------------------------------------------------------ battants

func _make_doors(house: Node3D, cfg: Dictionary) -> void:
	var xf: Transform3D = house.global_transform
	var rot: Basis = xf.basis.orthonormalized()
	var s: float = xf.basis.get_scale().x
	var hx: Vector2 = cfg["hole_x"]
	var total_w: float = (hx.y - hx.x) * s
	var leaves: Array = cfg["leaves"]
	var leaf_w: float = total_w / float(leaves.size())
	var spring_h: float = (float(cfg["spring"]) - float(cfg["bottom"])) * s
	var apex_h: float = (float(cfg["apex"]) - float(cfg["bottom"])) * s
	var inward: Vector3 = (rot * Vector3(0, 0, -1)).normalized()
	var center_local := Vector3((hx.x + hx.y) * 0.5, (float(cfg["bottom"]) + float(cfg["apex"])) * 0.5, float(cfg["door_z"]))
	var center_world: Vector3 = xf * center_local
	for hinge_side in leaves:
		var hinge_x: float = hx.y if int(hinge_side) > 0 else hx.x
		var hinge: Vector3 = xf * Vector3(hinge_x, float(cfg["bottom"]), float(cfg["door_z"]))
		var free_dir: Vector3 = (rot * Vector3(-float(hinge_side), 0, 0)).normalized()
		var z_axis: Vector3 = free_dir.cross(Vector3.UP)
		var base := Basis(free_dir, Vector3.UP, z_axis)
		var pivot := AnimatableBody3D.new()
		pivot.name = "Porte_" + str(house.name) + "_v27"
		pivot.collision_layer = 1
		pivot.collision_mask = 0
		pivot.sync_to_physics = true
		add_child(pivot)
		pivot.global_transform = Transform3D(base, hinge)
		var leaf := MeshInstance3D.new()
		leaf.name = "Battant"
		leaf.mesh = _leaf_mesh(leaf_w, total_w * 0.5, spring_h - 0.01, apex_h - 0.015)
		leaf.material_override = _door_material()
		pivot.add_child(leaf)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(leaf_w - 0.02, spring_h, THICKNESS)
		cs.shape = box
		cs.position = Vector3(leaf_w * 0.5, spring_h * 0.5, 0.0)
		pivot.add_child(cs)
		var sign_v: float = -1.0 if z_axis.dot(inward) > 0.0 else 1.0
		var label := Label3D.new()
		label.text = "Gâchette droite : ouvrir"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.pixel_size = 0.0022
		label.outline_size = 10
		label.position = center_world + Vector3.UP * (apex_h * 0.5 + 0.35) - inward * 0.6
		label.visible = false
		add_child(label)
		doors.append({"pivot": pivot, "base": Transform3D(base, hinge), "target": 0.0, "angle": 0.0, "sign": sign_v, "center": center_world, "label": label, "house": str(house.name)})


# Battant en bois : contour droit jusqu'à la naissance de l'arc, puis arc de la porte.
# u = 0 côté charnière ; arch_center = distance charnière -> axe de la porte.
func _leaf_mesh(width: float, arch_center: float, spring_h: float, apex_h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: int = 12
	var half_t: float = THICKNESS * 0.5
	var tops: Array[float] = []
	for i in range(cols + 1):
		var u: float = width * float(i) / float(cols)
		var k: float = (u - arch_center) / arch_center
		tops.append(spring_h + (apex_h - spring_h) * sqrt(maxf(0.0, 1.0 - k * k)))
	for side in [1.0, -1.0]:
		var n := Vector3(0, 0, side)
		for i in range(cols):
			var u0: float = width * float(i) / float(cols)
			var u1: float = width * float(i + 1) / float(cols)
			var q := [Vector3(u0, 0, side * half_t), Vector3(u1, 0, side * half_t), Vector3(u1, tops[i + 1], side * half_t), Vector3(u0, tops[i], side * half_t)]
			var order: Array = [0, 1, 2, 0, 2, 3] if side > 0.0 else [0, 2, 1, 0, 3, 2]
			for j in order:
				var p: Vector3 = q[j]
				st.set_normal(n)
				st.set_uv(Vector2(p.x / width, 1.0 - p.y / apex_h))
				st.add_vertex(p)
	# Chants (bords) du battant.
	var ring: Array = [Vector3(0, 0, 0), Vector3(width, 0, 0)]
	for i in range(cols, -1, -1):
		ring.append(Vector3(width * float(i) / float(cols), tops[i], 0))
	ring.append(Vector3(0, 0, 0))
	for i in range(ring.size() - 1):
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[i + 1]
		if a.distance_to(b) < 0.001:
			continue
		var n2: Vector3 = (b - a).cross(Vector3(0, 0, 1)).normalized()
		var quad := [a + Vector3(0, 0, half_t), b + Vector3(0, 0, half_t), b - Vector3(0, 0, half_t), a - Vector3(0, 0, half_t)]
		for j in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n2)
			st.set_uv(Vector2(0.02, 0.5))
			st.add_vertex(quad[j])
	return st.commit()


func _door_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/doors/door_wood.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/doors/door_wood_n.png")
	m.roughness = 0.82
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ------------------------------------------------------------------ interaction

## Porte la plus proche à portée, ou -1.
func nearest(player_pos: Vector3) -> int:
	var best: int = -1
	var best_d: float = REACH
	for i in range(doors.size()):
		var d: float = Vector2(player_pos.x - doors[i]["center"].x, player_pos.z - doors[i]["center"].z).length()
		if d < best_d:
			best_d = d
			best = i
	return best


## Ouvre ou ferme la porte la plus proche (et l'autre battant d'une double porte).
func interact(player_pos: Vector3) -> bool:
	var i: int = nearest(player_pos)
	if i < 0:
		return false
	var opening: bool = float(doors[i]["target"]) < 0.5
	for d in doors:
		if d["house"] == doors[i]["house"]:
			d["target"] = OPEN_ANGLE if opening else 0.0
	# V50 : grincement de la porte
	var m: Node = get_parent()
	if m != null and m.has_method("sfx"):
		m.sfx("porte_ouvre" if opening else "porte_ferme", player_pos + Vector3.UP * 1.2)
	return true


## Texte d'aide pour l'écran PC ; en VR, l'étiquette 3D au-dessus de la porte.
func prompt(player_pos: Vector3, vr: bool) -> String:
	var i: int = nearest(player_pos)
	for k in range(doors.size()):
		var lbl: Label3D = doors[k]["label"]
		var show: bool = vr and i >= 0 and doors[k]["house"] == doors[i]["house"]
		lbl.visible = show and k == _first_leaf(doors[k]["house"])
		if show:
			lbl.text = "Gâchette droite : " + ("fermer" if float(doors[k]["target"]) > 0.5 else "ouvrir")
	if i < 0:
		return ""
	return "E : " + ("fermer la porte" if float(doors[i]["target"]) > 0.5 else "ouvrir la porte")


func _first_leaf(house: String) -> int:
	for k in range(doors.size()):
		if doors[k]["house"] == house:
			return k
	return -1


func _physics_process(delta: float) -> void:
	for d in doors:
		var angle: float = d["angle"]
		var target: float = d["target"]
		if is_equal_approx(angle, target):
			continue
		angle = move_toward(angle, target, SWING_SPEED * delta)
		d["angle"] = angle
		var base: Transform3D = d["base"]
		(d["pivot"] as AnimatableBody3D).global_transform = Transform3D(base.basis.rotated(Vector3.UP, angle * float(d["sign"])), base.origin)


# ------------------------------------------------------------------ intérieurs

func _make_materials() -> void:
	_wood = _tiled("res://assets/textures/doors/wood_plain.png", 1.1, Color(1, 1, 1))
	_wood.roughness = 0.72
	_beam = _tiled("res://assets/textures/doors/wood_plain.png", 1.4, Color(0.55, 0.45, 0.38))
	# Enduit à la chaux, comme les façades à colombages de la maison.
	_wall = _tiled("res://assets/textures/doors/plaster.png", 0.45, Color(1, 1, 1))
	_wall.normal_enabled = true
	_wall.normal_texture = load("res://assets/textures/doors/plaster_n.png")
	_floor = _tiled("res://assets/textures/interior/floor.png", 0.7, Color(1, 1, 1))
	_ceiling = _tiled("res://assets/textures/interior/ceiling.png", 0.6, Color(1, 1, 1))


func _tiled(path: String, scale_value: float, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale_value
	m.roughness = 0.9
	return m


func _box(label: String, center: Vector3, size: Vector3, mat: Material, solid: bool, body: StaticBody3D = null) -> void:
	var mi := MeshInstance3D.new()
	mi.name = label
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	add_child(mi)
	if solid and body != null:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		cs.position = center
		body.add_child(cs)


func _color(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _make_room(house: Node3D, cfg: Dictionary) -> void:
	var xf: Transform3D = house.global_transform
	var rx: Vector2 = cfg["room_x"]
	var rz: Vector2 = cfg["room_z"]
	var fl: float = cfg["floor"]
	var hh: float = cfg["height"]
	# Boîte de la pièce en coordonnées monde (maisons tournées d'un quart de tour).
	var a: Vector3 = xf * Vector3(rx.x, fl, rz.x)
	var b: Vector3 = xf * Vector3(rx.y, fl + hh, rz.y)
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var size: Vector3 = hi - lo
	var mid: Vector3 = (lo + hi) * 0.5
	var t: float = 0.06
	# Côté de la porte : la face du modèle +z (locale) devient une face monde.
	var door_dir: Vector3 = (xf.basis.orthonormalized() * Vector3(0, 0, 1)).normalized()
	var door_on_x: bool = absf(door_dir.x) > 0.5
	var s: float = xf.basis.get_scale().x
	var hx: Vector2 = cfg["hole_x"]
	var door_c: Vector3 = xf * Vector3((hx.x + hx.y) * 0.5, 0, 0)
	var door_half: float = (hx.y - hx.x) * s * 0.5
	var door_top: float = xf.origin.y + float(cfg["apex"]) * s
	var body := StaticBody3D.new()
	body.name = "Interieur_" + str(house.name) + "_v27"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_box("Plancher_v27", Vector3(mid.x, lo.y - 0.03, mid.z), Vector3(size.x, 0.06, size.z), _floor, false)
	_box("Plafond_v27", Vector3(mid.x, hi.y + 0.03, mid.z), Vector3(size.x, 0.06, size.z), _ceiling, false)
	for side in [-1.0, 1.0]:
		# Murs perpendiculaires à x et à z.
		var wx := Vector3(mid.x + side * (size.x * 0.5 + t * 0.5), mid.y, mid.z)
		var wz := Vector3(mid.x, mid.y, mid.z + side * (size.z * 0.5 + t * 0.5))
		var is_door_x: bool = door_on_x and signf(door_dir.x) == side
		var is_door_z: bool = (not door_on_x) and signf(door_dir.z) == side
		if is_door_x:
			_wall_with_door(wx, size.z, size.y, door_c.z, door_half, door_top, lo.y, true)
		else:
			_box("Mur_v27", wx, Vector3(t, size.y, size.z), _wall, false)
		if is_door_z:
			_wall_with_door(wz, size.x, size.y, door_c.x, door_half, door_top, lo.y, false)
		else:
			_box("Mur_v27", wz, Vector3(size.x, size.y, t), _wall, false)
	# Colombages : poteaux d'angle, plinthes et poutres au plafond.
	for cx in [lo.x + 0.08, hi.x - 0.08]:
		for cz in [lo.z + 0.08, hi.z - 0.08]:
			_box("Poteau_v27", Vector3(cx, mid.y, cz), Vector3(0.16, size.y, 0.16), _beam, false)
	for side in [-1.0, 1.0]:
		_box("Plinthe_v27", Vector3(mid.x + side * (size.x * 0.5 - 0.02), lo.y + 0.07, mid.z), Vector3(0.04, 0.14, size.z), _beam, false)
		_box("Plinthe_v27", Vector3(mid.x, lo.y + 0.07, mid.z + side * (size.z * 0.5 - 0.02)), Vector3(size.x, 0.14, 0.04), _beam, false)
	var long_x: bool = size.x > size.z
	var beams: int = int((size.x if long_x else size.z) / 1.3)
	for k in range(1, beams + 1):
		var u: float = (lo.x if long_x else lo.z) + (size.x if long_x else size.z) * float(k) / float(beams + 1)
		var pos := Vector3(u, hi.y - 0.09, mid.z) if long_x else Vector3(mid.x, hi.y - 0.09, u)
		var sz := Vector3(0.16, 0.18, size.z) if long_x else Vector3(size.x, 0.18, 0.16)
		_box("Poutre_v27", pos, sz, _beam, false)
	# Marche intérieure sous le seuil quand il est haut (grande maison : 57 cm).
	var sill_y: float = xf.origin.y + float(cfg["bottom"]) * s
	var rise: float = sill_y - lo.y
	if rise > 0.3:
		var into: Vector3 = -door_dir
		var plane: Vector3 = xf * Vector3((hx.x + hx.y) * 0.5, 0, float(cfg["door_z"]))
		var step_c: Vector3 = Vector3(plane.x, lo.y + rise * 0.25, plane.z) + into * 0.32
		var along: Vector3 = Vector3(absf(into.z), 0, absf(into.x)) * (door_half * 2.0 + 0.3)
		var deep: Vector3 = Vector3(absf(into.x), 0, absf(into.z)) * 0.5
		_box("Marche_interieure_v27", step_c, along + deep + Vector3.UP * rise * 0.5, _wood, true, body)
	# Lumière chaude de l'intérieur.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.78, 0.52)
	lamp.light_energy = 1.4
	lamp.omni_range = maxf(size.x, size.z) * 0.9
	lamp.shadow_enabled = pc_quality
	lamp.position = Vector3(mid.x, hi.y - 0.35, mid.z)
	add_child(lamp)
	_furnish(str(cfg["kind"]), lo, hi, door_dir, door_c, body)


# Mur percé de la porte : deux pans et un linteau.
func _wall_with_door(center: Vector3, length: float, height: float, door_along: float, half: float, door_top: float, floor_y: float, along_z: bool) -> void:
	var t: float = 0.06
	var start: float = (center.z if along_z else center.x) - length * 0.5
	var stop: float = start + length
	var segs: Array = [[start, door_along - half], [door_along + half, stop]]
	for seg in segs:
		var l: float = float(seg[1]) - float(seg[0])
		if l <= 0.01:
			continue
		var c: float = (float(seg[0]) + float(seg[1])) * 0.5
		var pos := Vector3(center.x, center.y, c) if along_z else Vector3(c, center.y, center.z)
		var sz := Vector3(t, height, l) if along_z else Vector3(l, height, t)
		_box("Mur_v27", pos, sz, _wall, false)
	var top_h: float = floor_y + height - door_top
	if top_h > 0.02:
		var ly: float = door_top + top_h * 0.5
		var lpos := Vector3(center.x, ly, door_along) if along_z else Vector3(door_along, ly, center.z)
		var lsz := Vector3(t, top_h, half * 2.0) if along_z else Vector3(half * 2.0, top_h, t)
		_box("Linteau_v27", lpos, lsz, _wall, false)


# Mobilier simple, posé contre les murs opposés à la porte (passage dégagé).
func _furnish(kind: String, lo: Vector3, hi: Vector3, door_dir: Vector3, door_c: Vector3, body: StaticBody3D) -> void:
	var f: float = lo.y
	var mid: Vector3 = (lo + hi) * 0.5
	# Axe « profondeur » : de la porte vers le fond de la pièce.
	var into: Vector3 = -door_dir
	var across := Vector3(-into.z, 0, into.x)
	var depth: float = absf((hi - lo).dot(into))
	var width: float = absf((hi - lo).dot(across))
	var back: Vector3 = Vector3(mid.x, f, mid.z) + into * (depth * 0.5 - 0.5)
	var rug := _color(Color(0.55, 0.16, 0.12), 0.95)
	var linen := _color(Color(0.88, 0.85, 0.78), 0.95)
	var blanket := _color(Color(0.22, 0.35, 0.55), 0.95)
	var iron := _color(Color(0.18, 0.18, 0.2), 0.5)
	_box("Tapis_v27", Vector3(mid.x, f + 0.008, mid.z), Vector3(absf(across.x) * width * 0.55 + absf(into.x) * depth * 0.45, 0.012, absf(across.z) * width * 0.55 + absf(into.z) * depth * 0.45), rug, false)
	if kind == "maison":
		# Passage dégagé face à la porte ; coin repas d'un côté, lit de l'autre, étagère au fond.
		var dining: Vector3 = Vector3(mid.x, f, mid.z) + across * (width * 0.5 - 1.35)
		_box("Table_v27", dining + Vector3.UP * 0.74, _orient(Vector3(1.4, 0.06, 0.8), into), _wood, true, body)
		for sx in [-0.6, 0.6]:
			for sz in [-0.3, 0.3]:
				var leg: Vector3 = dining + across * sx + into * sz + Vector3.UP * 0.36
				_box("Pied_table_v27", leg, Vector3(0.07, 0.72, 0.07), _wood, false)
		for side in [-1.0, 1.0]:
			_box("Banc_v27", dining + into * side * 0.65 + Vector3.UP * 0.23, _orient(Vector3(1.3, 0.45, 0.3), into), _wood, true, body)
		var bed: Vector3 = Vector3(mid.x, f, mid.z) - across * (width * 0.5 - 1.15) + into * (depth * 0.5 - 0.55)
		_box("Lit_v27", bed + Vector3.UP * 0.22, _orient(Vector3(2.0, 0.44, 0.95), into), _wood, true, body)
		_box("Matelas_v27", bed + Vector3.UP * 0.5, _orient(Vector3(1.9, 0.14, 0.85), into), linen, false)
		_box("Couverture_v27", bed + Vector3.UP * 0.58 + across * 0.2, _orient(Vector3(1.35, 0.05, 0.88), into), blanket, false)
		var shelf: Vector3 = Vector3(mid.x, f, mid.z) + into * (depth * 0.5 - 0.2)
		_box("Etagere_dos_v27", shelf + into * 0.15 + Vector3.UP * 0.9, _orient(Vector3(1.2, 1.8, 0.03), into), _wood, true, body)
		for side in [-1.0, 1.0]:
			_box("Etagere_montant_v27", shelf + across * side * 0.58 + Vector3.UP * 0.9, _orient(Vector3(0.04, 1.8, 0.33), into), _wood, true, body)
		for hy in [0.05, 0.47, 0.89, 1.31, 1.75]:
			_box("Etagere_planche_v27", shelf + Vector3.UP * hy, _orient(Vector3(1.16, 0.03, 0.31), into), _wood, false)
		var palette := [Color(0.6, 0.2, 0.15), Color(0.2, 0.4, 0.25), Color(0.75, 0.6, 0.3), Color(0.25, 0.3, 0.5)]
		for k in range(8):
			var book: Vector3 = shelf - into * 0.02 + across * (-0.42 + (k % 4) * 0.26) + Vector3.UP * (1.06 if k < 4 else 0.64)
			_box("Livre_v27", book, _orient(Vector3(0.09, 0.3, 0.22), into), _color(palette[k % 4], 0.7), false)
	else:
		# Atelier : établi au fond, tonneaux et caisses dans un coin.
		var bench: Vector3 = back + into * 0.1
		_box("Etabli_v27", bench + Vector3.UP * 0.45, _orient(Vector3(2.0, 0.9, 0.7), into), _wood, true, body)
		_box("Etau_v27", bench + Vector3.UP * 0.98 + across * 0.6, Vector3(0.18, 0.16, 0.18), iron, false)
		for k in range(3):
			var barrel := MeshInstance3D.new()
			barrel.name = "Tonneau_v27"
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.3
			cyl.bottom_radius = 0.3
			cyl.height = 0.85
			barrel.mesh = cyl
			barrel.material_override = _wood
			barrel.position = Vector3(mid.x, f + 0.425, mid.z) + across * (width * 0.5 - 0.4) + into * (-0.3 + k * 0.7)
			add_child(barrel)
			var cs := CollisionShape3D.new()
			var shape := CylinderShape3D.new()
			shape.radius = 0.3
			shape.height = 0.85
			cs.shape = shape
			cs.position = barrel.position
			body.add_child(cs)
		for k in range(2):
			var crate: Vector3 = Vector3(mid.x, f, mid.z) - across * (width * 0.5 - 0.45) + into * (0.4 + k * 0.75)
			_box("Caisse_v27", crate + Vector3.UP * 0.3, Vector3(0.6, 0.6, 0.6), _wood, true, body)


# Dimensions (largeur, hauteur, profondeur) orientées : la largeur suit la direction « axis ».
func _orient(dims: Vector3, axis: Vector3) -> Vector3:
	if absf(axis.x) > 0.5:
		return Vector3(dims.z, dims.y, dims.x)
	return dims

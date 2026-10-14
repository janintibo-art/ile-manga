extends Node3D
## V33 : la cabane perchée d'Octave Taillefer, rival de Barnabé, sur la côte est de la jungle.
## Un fromager géant ; à 5 m du sol, une grande plate-forme de planches posée sur des
## jambes de force et quatre poteaux ; dessus, l'atelier-boutique (comptoir, établi, enclume,
## râtelier d'outils) et une terrasse avec garde-corps. Une seule façon de monter : l'échelle.
## Repère local : origine au pied du tronc ; +Z regarde vers l'échelle (côté d'où l'on vient).

const X0: float = -4.6
const X1: float = 4.6
const Z0: float = -2.6
const Z1: float = 5.4
const DECK_RISE: float = 5.0          # hauteur du plancher au-dessus du pied de l'échelle
const LADDER_X: float = -2.8
const ROOM_X0: float = 1.5
const ROOM_Z1: float = 1.8
const WALL_H: float = 2.3
const DOOR_X0: float = 2.5
const DOOR_X1: float = 3.6

var deck_y: float = 5.0               # dessus du plancher (local)
var points: Dictionary = {}           # repères monde pour Octave
var ladder_foot: Vector3              # pieds du joueur au bas de l'échelle (monde)
var ladder_top: Vector3               # sur la plate-forme, devant l'échelle (monde)
var ladder_hang: Vector3              # pieds du joueur accroché en haut de l'échelle (monde)
var ladder_normal: Vector3            # face de l'échelle, vers l'extérieur (monde)
var _main: Node
var _wood: StandardMaterial3D
var _dark: StandardMaterial3D
var _thatch: StandardMaterial3D
var _iron: StandardMaterial3D
var _body: StaticBody3D
var _vr_hint: Label3D


func build(main: Node, at: Vector3, facing: Vector3, inventory: Node, tree_mesh: Mesh) -> void:
	name = "Cabane_arbre_Octave_v33"
	_main = main
	global_position = at
	facing.y = 0.0
	rotation.y = atan2(facing.x, facing.z)
	_materials()
	_body = StaticBody3D.new()
	_body.name = "Cabane_arbre_collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	# Plancher : 5 m au-dessus du pied de l'échelle, et au moins 2,4 m au-dessus du sol partout.
	var foot_g: float = _ground_local(Vector3(LADDER_X, 0, Z1 + 0.6))
	var top: float = -INF
	for x in [X0, 0.0, X1]:
		for z in [Z0, 0.0, Z1]:
			top = maxf(top, _ground_local(Vector3(x, 0, z)))
	deck_y = maxf(foot_g + DECK_RISE, top + 2.4)
	_tree(tree_mesh)
	_deck()
	_supports()
	_railings()
	_ladder(foot_g)
	_room()
	_roof()
	_shop(inventory)
	_decor()
	_sign(foot_g)
	var d := deck_y
	points = {
		"comptoir": to_global(Vector3(2.9, d, 2.6)),
		"atelier": to_global(Vector3(3.1, d, -0.9)),
		"terrasse": to_global(Vector3(-0.6, d, 3.2)),
		"cote": to_global(Vector3(-3.0, d, 1.2)),
		"balcon": to_global(Vector3(-2.7, d, -1.7)),
	}
	ladder_normal = (to_global(Vector3(0, 0, 1)) - to_global(Vector3.ZERO)).normalized()
	ladder_foot = to_global(Vector3(LADDER_X, foot_g, Z1 + 0.55))
	ladder_foot.y = main._height_at(ladder_foot.x, ladder_foot.z)
	ladder_top = to_global(Vector3(LADDER_X, d, Z1 - 0.6))
	ladder_hang = to_global(Vector3(LADDER_X, d - 1.5, Z1 + 0.55))
	_vr_hint = Label3D.new()
	_vr_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_vr_hint.font_size = 40
	_vr_hint.pixel_size = 0.0024
	_vr_hint.outline_size = 10
	_vr_hint.no_depth_test = true
	_vr_hint.visible = false
	add_child(_vr_hint)


## Où en est le joueur par rapport à l'échelle : "bas", "haut" ou "".
func ladder_side(p: Vector3) -> String:
	if Vector2(p.x - ladder_foot.x, p.z - ladder_foot.z).length() < 1.5 and absf(p.y - ladder_foot.y) < 1.3:
		return "bas"
	if Vector2(p.x - ladder_top.x, p.z - ladder_top.z).length() < 1.3 and absf(p.y - ladder_top.y) < 1.0:
		return "haut"
	return ""


## VR : petite étiquette au pied ou en haut de l'échelle ("bas", "haut" ou "" pour cacher).
func show_vr_hint(side: String) -> void:
	if _vr_hint == null:
		return
	_vr_hint.visible = side != ""
	if side == "bas":
		_vr_hint.global_position = ladder_foot + Vector3.UP * 1.9
		_vr_hint.text = "Gâchette droite : monter à l'échelle"
	elif side == "haut":
		_vr_hint.global_position = ladder_top + Vector3.UP * 1.9
		_vr_hint.text = "Gâchette droite : descendre l'échelle"


# =================================================================== outils

func _materials() -> void:
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	_wood.uv1_triplanar = true
	_wood.uv1_scale = Vector3(1.3, 1.3, 1.3)
	_wood.albedo_color = Color(0.88, 0.76, 0.6)
	_wood.roughness = 0.88
	_dark = _wood.duplicate()
	_dark.albedo_color = Color(0.58, 0.46, 0.36)
	_thatch = StandardMaterial3D.new()
	_thatch.albedo_texture = load("res://assets/textures/jungle/thatch.png")
	_thatch.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_thatch.alpha_scissor_threshold = 0.45
	_thatch.cull_mode = BaseMaterial3D.CULL_DISABLED
	_thatch.roughness = 0.95
	_iron = StandardMaterial3D.new()
	_iron.albedo_color = Color(0.2, 0.2, 0.22)
	_iron.metallic = 0.7
	_iron.roughness = 0.45


func _box(size: Vector3, pos: Vector3, mat: Material, solid: bool, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	if solid:
		_solid(size, pos, rot)
	return mi


func _solid(size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO, parent: Node = null) -> void:
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	cs.shape = s
	cs.position = pos
	cs.rotation = rot
	(parent if parent != null else _body).add_child(cs)


func _cyl(r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, solid: bool = false, rot: Vector3 = Vector3.ZERO, seg: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var s := CylinderShape3D.new()
		s.radius = maxf(r_top, r_bot)
		s.height = h
		cs.shape = s
		cs.position = pos
		cs.rotation = rot
		_body.add_child(cs)
	return mi


## Poutre entre deux points locaux (boîte orientée).
func _beam(a: Vector3, b: Vector3, w: float, mat: Material) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var dir: Vector3 = b - a
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, w, dir.length())
	mi.mesh = bm
	mi.material_override = mat
	add_child(mi)
	mi.transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.RIGHT), mid)


func _ground_local(local: Vector3) -> float:
	var w: Vector3 = to_global(Vector3(local.x, 0, local.z))
	return _main._height_at(w.x, w.z) - global_position.y


# =================================================================== l'arbre

func _tree(tree_mesh: Mesh) -> void:
	if tree_mesh != null:
		var mi := MeshInstance3D.new()
		mi.name = "Fromager_Octave"
		mi.mesh = tree_mesh
		mi.position = Vector3(0, -0.3, 0)
		mi.rotation.y = 0.7
		add_child(mi)
	else:
		_cyl(0.75, 1.3, 26.0, Vector3(0, 13.0, 0), _dark, false, Vector3.ZERO, 16)
	# Le tronc arrête le joueur (cylindre : il ne s'escalade pas, il faut l'échelle).
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.2
	s.height = 24.0
	cs.shape = s
	cs.position = Vector3(0, 12.0, 0)
	_body.add_child(cs)


# =================================================================== plate-forme

func _deck() -> void:
	var y: float = deck_y
	var n: int = int((Z1 - Z0) / 0.2)
	for i in range(n):
		var z: float = Z0 + 0.1 + i * 0.2
		_box(Vector3(X1 - X0 + 0.1, 0.07, 0.185), Vector3((X0 + X1) * 0.5, y - 0.035, z), _wood if i % 4 else _dark, false)
	# Solives et poutres de rive sous le plancher
	for x in [X0 + 0.1, -1.6, 1.6, X1 - 0.1]:
		_box(Vector3(0.16, 0.24, Z1 - Z0), Vector3(x, y - 0.19, (Z0 + Z1) * 0.5), _dark, false)
	for z in [Z0 + 0.08, Z1 - 0.08]:
		_box(Vector3(X1 - X0 + 0.2, 0.26, 0.16), Vector3((X0 + X1) * 0.5, y - 0.2, z), _dark, false)
	_solid(Vector3(X1 - X0 + 0.1, 0.3, Z1 - Z0), Vector3((X0 + X1) * 0.5, y - 0.15, (Z0 + Z1) * 0.5))


func _supports() -> void:
	var y: float = deck_y - 0.3
	# Quatre poteaux d'angle plantés dans le sol
	for c in [Vector3(X0 + 0.2, 0, Z0 + 0.2), Vector3(X1 - 0.2, 0, Z0 + 0.2), Vector3(X0 + 0.2, 0, Z1 - 0.2), Vector3(X1 - 0.2, 0, Z1 - 0.2)]:
		var g: float = _ground_local(c) - 0.3
		_cyl(0.13, 0.16, y - g, Vector3(c.x, (y + g) * 0.5, c.z), _dark, true)
	# Jambes de force : du tronc vers les rives de la plate-forme
	var trunk_y: float = deck_y - 2.6
	for e in [Vector3(X0 + 0.3, 0, 0), Vector3(X1 - 0.3, 0, 0), Vector3(0, 0, Z1 - 0.3), Vector3(0, 0, Z0 + 0.3), Vector3(-2.6, 0, Z1 - 0.3), Vector3(-2.6, 0, Z0 + 0.3)]:
		var flat := Vector3(e.x, 0, e.z).normalized()
		_beam(flat * 1.05 + Vector3.UP * trunk_y, Vector3(e.x, y - 0.05, e.z), 0.14, _dark)
	# Cerclage de cordes autour du tronc, sous le plancher
	for k in range(3):
		_cyl(1.12 - k * 0.01, 1.12, 0.05, Vector3(0, deck_y - 0.5 - k * 0.12, 0), _iron if k == 1 else _dark, false, Vector3.ZERO, 18)


func _railings() -> void:
	var y: float = deck_y
	var gap0: float = LADDER_X - 0.55
	var gap1: float = LADDER_X + 0.55
	# [début, fin] le long de chaque rive (local), hors mur de l'atelier et passage de l'échelle
	var runs: Array = [
		[Vector3(X0, y, Z1), Vector3(gap0, y, Z1)],
		[Vector3(gap1, y, Z1), Vector3(X1, y, Z1)],
		[Vector3(X0, y, Z0), Vector3(X0, y, Z1)],
		[Vector3(X0, y, Z0), Vector3(ROOM_X0, y, Z0)],
		[Vector3(X1, y, ROOM_Z1), Vector3(X1, y, Z1)],
	]
	for r in runs:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var run_len: float = a.distance_to(b)
		var along: Vector3 = (b - a).normalized()
		var posts: int = maxi(1, int(ceil(run_len / 1.2)))
		for k in range(posts + 1):
			var p: Vector3 = a + along * run_len * float(k) / posts
			_box(Vector3(0.09, 1.05, 0.09), p + Vector3.UP * 0.52, _dark, false)
		for h in [0.5, 0.98]:
			var rail := _box(Vector3(0.06, 0.07, run_len), (a + b) * 0.5 + Vector3.UP * h, _wood, false)
			rail.rotation.y = atan2(along.x, along.z)
		# Une seule boîte de collision par rive, de la hauteur du garde-corps
		_solid(Vector3(0.1, 1.05, run_len), (a + b) * 0.5 + Vector3.UP * 0.52, Vector3(0, atan2(along.x, along.z), 0))
		# Croisillons sur les grandes rives
		if run_len > 2.0:
			_beam(a + Vector3.UP * 0.1 + along * 0.1, b + Vector3.UP * 0.95 - along * 0.1, 0.05, _dark)


# =================================================================== l'échelle

func _ladder(foot_g: float) -> void:
	var y_top: float = deck_y
	var bottom: float = foot_g - 0.25
	var h: float = y_top + 1.0 - bottom
	var zf: float = Z1 + 0.06
	for sx in [-0.26, 0.26]:
		_box(Vector3(0.075, h, 0.075), Vector3(LADDER_X + sx, bottom + h * 0.5, zf), _dark, false)
	var y: float = foot_g + 0.3
	while y < y_top + 0.85:
		_cyl(0.022, 0.022, 0.52, Vector3(LADDER_X, y, zf), _wood, false, Vector3(0, 0, PI * 0.5), 6)
		y += 0.3
	# Collision à part, dans le groupe « échelle » (le héros s'y fatigue peu).
	var lb := StaticBody3D.new()
	lb.name = "Echelle_v33"
	lb.collision_layer = 1
	lb.collision_mask = 0
	lb.add_to_group("echelle_v33")
	add_child(lb)
	var col_h: float = y_top - (foot_g + 0.05)
	_solid(Vector3(0.6, col_h, 0.1), Vector3(LADDER_X, foot_g + 0.05 + col_h * 0.5, Z1 + 0.05), Vector3.ZERO, lb)


# =================================================================== atelier

func _room() -> void:
	var y: float = deck_y
	var ym: float = y + WALL_H * 0.5
	var w: float = X1 - ROOM_X0
	var dz: float = ROOM_Z1 - Z0
	var xc: float = (ROOM_X0 + X1) * 0.5
	var zc: float = (ROOM_Z1 + Z0) * 0.5
	_box(Vector3(w, WALL_H, 0.08), Vector3(xc, ym, Z0 + 0.04), _wood, true)
	_box(Vector3(0.08, WALL_H, dz), Vector3(X1 - 0.04, ym, zc), _wood, true)
	_box(Vector3(0.08, WALL_H, dz), Vector3(ROOM_X0 + 0.04, ym, zc), _wood, true)
	# Façade : deux pans et le linteau au-dessus de la porte
	_box(Vector3(DOOR_X0 - ROOM_X0, WALL_H, 0.08), Vector3((ROOM_X0 + DOOR_X0) * 0.5, ym, ROOM_Z1), _wood, true)
	_box(Vector3(X1 - DOOR_X1, WALL_H, 0.08), Vector3((DOOR_X1 + X1) * 0.5, ym, ROOM_Z1), _wood, true)
	_box(Vector3(DOOR_X1 - DOOR_X0, 0.3, 0.1), Vector3((DOOR_X0 + DOOR_X1) * 0.5, y + WALL_H - 0.15, ROOM_Z1), _dark, false)
	# Poteaux d'angle et fenêtres (cadre sombre, volet entrouvert)
	for p in [Vector3(ROOM_X0, 0, Z0), Vector3(X1, 0, Z0), Vector3(ROOM_X0, 0, ROOM_Z1), Vector3(X1, 0, ROOM_Z1)]:
		_box(Vector3(0.15, WALL_H, 0.15), Vector3(p.x, ym, p.z), _dark, false)
	_box(Vector3(0.1, 0.75, 1.0), Vector3(X1 + 0.01, y + 1.4, zc), _dark, false)
	_box(Vector3(0.04, 0.75, 0.5), Vector3(X1 + 0.25, y + 1.4, zc + 0.75), _wood, false, Vector3(0, -0.6, 0))
	_box(Vector3(0.9, 0.7, 0.1), Vector3(xc, y + 1.45, Z0 - 0.01), _dark, false)


func _roof() -> void:
	# Toit à un pan, de la façade (haut) vers l'arrière (bas), couvert de palmes séchées.
	var y: float = deck_y
	var front_z: float = ROOM_Z1 + 0.7
	var back_z: float = Z0 - 0.5
	var hi: float = y + WALL_H + 0.75
	var lo: float = y + WALL_H - 0.05
	var span: float = front_z - back_z
	var slope_len: float = sqrt(span * span + pow(hi - lo, 2.0))
	var ang: float = atan2(hi - lo, span)
	var xc: float = (ROOM_X0 + X1) * 0.5
	var w: float = X1 - ROOM_X0 + 0.9
	_box(Vector3(w, 0.06, slope_len), Vector3(xc, (hi + lo) * 0.5, (front_z + back_z) * 0.5), _dark, false, Vector3(-ang, 0, 0))
	var rows: int = 7
	for r in range(rows):
		var u: float = (float(r) + 0.5) / rows
		var z: float = back_z + span * u
		var yy: float = lo + (hi - lo) * u + 0.06
		var x: float = ROOM_X0 - 0.4
		var k: int = 0
		while x < X1 + 0.45:
			var mi := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.55, 1.4)
			mi.mesh = q
			mi.material_override = _thatch
			add_child(mi)
			var b := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -PI * 0.5 + ang)
			b = b.rotated(Vector3.UP, (float(k % 3) - 1.0) * 0.08)
			mi.transform = Transform3D(b, Vector3(x + (0.12 if r % 2 else 0.0), yy, z - 0.2))
			x += 0.42
			k += 1
	# Pignons triangulaires sur les côtés
	for sx in [ROOM_X0, X1]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [Vector3(sx, lo, Z0), Vector3(sx, y + WALL_H, ROOM_Z1), Vector3(sx, hi - 0.05, ROOM_Z1)]:
			st.set_normal(Vector3(1 if sx > 0 else -1, 0, 0))
			st.add_vertex(v)
		var tri := MeshInstance3D.new()
		tri.mesh = st.commit()
		var two := _wood.duplicate()
		two.cull_mode = BaseMaterial3D.CULL_DISABLED
		tri.material_override = two
		add_child(tri)


# =================================================================== boutique

func _shop(inventory: Node) -> void:
	var y: float = deck_y
	# Comptoir en planches épaisses, devant la porte de l'atelier
	_box(Vector3(2.3, 1.0, 0.5), Vector3(2.45, y + 0.5, 3.35), _dark, true)
	_box(Vector3(2.5, 0.07, 0.62), Vector3(2.45, y + 1.03, 3.35), _wood, false)
	# Râtelier mural à côté de la porte : la marchandise est exposée
	_box(Vector3(0.95, 1.3, 0.05), Vector3(2.0, y + 1.25, ROOM_Z1 + 0.07), _wood, false)
	if inventory != null:
		var shown := [["pelle", Vector3(1.72, y + 0.62, ROOM_Z1 + 0.13), Vector3(0, 0, 0)],
			["hache", Vector3(2.02, y + 0.95, ROOM_Z1 + 0.13), Vector3(0, 0, 0)],
			["epee", Vector3(2.3, y + 0.85, ROOM_Z1 + 0.13), Vector3(0, 0, 0)]]
		for e in shown:
			var m: Node3D = inventory.make_model(str(e[0]))
			add_child(m)
			m.position = e[1]
			m.rotation = e[2]
		# Sur le comptoir : une épée posée à plat, une bourse et une balance
		var sword: Node3D = inventory.make_model("epee")
		add_child(sword)
		sword.position = Vector3(2.0, y + 1.075, 3.3)
		sword.rotation = Vector3(0, 0.35, PI * 0.5)
		for i in range(5):
			var coin: Node3D = inventory.make_model("piece")
			add_child(coin)
			coin.position = Vector3(3.05 + (i % 2) * 0.05, y + 1.07 + i * 0.009, 3.4)
	_cyl(0.008, 0.008, 0.35, Vector3(3.3, y + 1.24, 3.25), _iron)
	_box(Vector3(0.36, 0.015, 0.015), Vector3(3.3, y + 1.41, 3.25), _iron, false)
	for sx in [-0.17, 0.17]:
		_cyl(0.07, 0.05, 0.02, Vector3(3.3 + sx, y + 1.25, 3.25), _iron)


func _decor() -> void:
	var y: float = deck_y
	# Dans l'atelier : établi, enclume sur sa souche, tonneau d'eau, outils au mur
	_box(Vector3(1.6, 0.08, 0.7), Vector3(3.6, y + 0.9, Z0 + 0.5), _wood, true)
	for x in [2.9, 4.3]:
		for z in [Z0 + 0.25, Z0 + 0.75]:
			_box(Vector3(0.07, 0.9, 0.07), Vector3(x, y + 0.45, z), _dark, false)
	_cyl(0.28, 0.32, 0.55, Vector3(2.3, y + 0.275, -1.6), _dark, true)
	_box(Vector3(0.55, 0.16, 0.24), Vector3(2.3, y + 0.63, -1.6), _iron, false)
	_box(Vector3(0.3, 0.12, 0.16), Vector3(2.3, y + 0.77, -1.6), _iron, false)
	_cyl(0.0, 0.08, 0.2, Vector3(2.62, y + 0.77, -1.6), _iron, false, Vector3(0, 0, -PI * 0.5), 4)
	_cyl(0.27, 0.27, 0.8, Vector3(4.15, y + 0.4, 1.3), _dark, true)
	for i in range(4):
		_box(Vector3(0.04, 0.5, 0.04), Vector3(3.1 + i * 0.25, y + 1.6, Z0 + 0.1), _iron if i % 2 else _dark, false, Vector3(0, 0, 0.15 * (i - 1.5)))
	# Sur la terrasse : caisses, tonneau, un tabouret
	_box(Vector3(0.6, 0.5, 0.6), Vector3(-3.8, y + 0.25, -1.9), _wood, true)
	_box(Vector3(0.45, 0.4, 0.45), Vector3(-3.75, y + 0.7, -1.85), _dark, true, Vector3(0, 0.4, 0))
	_cyl(0.26, 0.28, 0.75, Vector3(-3.9, y + 0.375, 4.6), _dark, true)
	_cyl(0.18, 0.18, 0.05, Vector3(0.9, y + 0.55, 4.3), _wood)
	for a in range(3):
		var ang: float = TAU * a / 3.0
		_box(Vector3(0.04, 0.55, 0.04), Vector3(0.9 + cos(ang) * 0.13, y + 0.275, 4.3 + sin(ang) * 0.13), _dark, false)
	# Poulie et seau : une potence au-dessus du vide, la corde descend jusqu'au sol
	var arm_y: float = y + 2.4
	_box(Vector3(0.12, 2.4, 0.12), Vector3(X0 + 0.15, y + 1.2, 3.6), _dark, false)
	_box(Vector3(1.3, 0.12, 0.12), Vector3(X0 - 0.45, arm_y, 3.6), _dark, false)
	_cyl(0.09, 0.09, 0.05, Vector3(X0 - 0.95, arm_y - 0.12, 3.6), _iron, false, Vector3(PI * 0.5, 0, 0), 12)
	var g: float = _ground_local(Vector3(X0 - 0.95, 0, 3.6))
	var rope_len: float = arm_y - 0.2 - (g + 1.2)
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(0.72, 0.62, 0.42)
	rope.roughness = 1.0
	_cyl(0.012, 0.012, rope_len, Vector3(X0 - 0.95, g + 1.2 + rope_len * 0.5, 3.6), rope)
	_cyl(0.17, 0.13, 0.28, Vector3(X0 - 0.95, g + 1.05, 3.6), _dark)
	# Lanternes : une sur la terrasse, une dans l'atelier (lumière chaude)
	for lp in [Vector3(-0.2, y + 2.3, 4.9), Vector3(3.0, y + WALL_H - 0.3, -0.5)]:
		_cyl(0.005, 0.005, 0.3, lp + Vector3.UP * 0.25, _iron)
		var lamp := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.09
		lm.height = 0.2
		lamp.mesh = lm
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.8, 0.45)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.7, 0.35)
		glow.emission_energy_multiplier = 2.5
		lamp.material_override = glow
		lamp.position = lp
		add_child(lamp)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.74, 0.45)
		light.light_energy = 1.1
		light.omni_range = 6.5
		light.position = lp + Vector3.DOWN * 0.15
		add_child(light)
	# Le poteau de la terrasse qui tient la lanterne
	_box(Vector3(0.1, 2.5, 0.1), Vector3(-0.2, y + 1.25, Z1 - 0.15), _dark, false)
	_box(Vector3(0.1, 0.1, 0.5), Vector3(-0.2, y + 2.5, Z1 - 0.35), _dark, false)


func _sign(foot_g: float) -> void:
	# Pancarte au pied de l'échelle
	var p := Vector3(LADDER_X + 1.3, foot_g, Z1 + 1.1)
	p.y = _ground_local(p)
	_cyl(0.06, 0.07, 2.1, p + Vector3(0, 0.75, 0), _dark)
	_box(Vector3(1.5, 0.7, 0.05), p + Vector3(0, 1.55, 0.06), _wood, false)
	var lbl := Label3D.new()
	lbl.text = "OCTAVE TAILLEFER\nOutils & armes\nOn ne fait pas crédit !"
	lbl.font_size = 56
	lbl.pixel_size = 0.0026
	lbl.modulate = Color(0.22, 0.12, 0.06)
	lbl.outline_size = 0
	lbl.position = p + Vector3(0, 1.55, 0.095)
	add_child(lbl)
	# Petite enseigne au-dessus du comptoir
	var lbl2 := Label3D.new()
	lbl2.text = "BOUTIQUE"
	lbl2.font_size = 72
	lbl2.pixel_size = 0.003
	lbl2.modulate = Color(0.95, 0.85, 0.6)
	lbl2.outline_size = 10
	lbl2.outline_modulate = Color(0.2, 0.1, 0.05)
	lbl2.position = Vector3(3.05, deck_y + WALL_H - 0.12, ROOM_Z1 + 0.08)
	add_child(lbl2)

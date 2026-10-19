extends Node3D
## V31 : la cabane de Barnabé, sur la plage de la baie de la jungle.
## Pilotis, plancher et terrasse, murs de planches, toit à deux pans couvert de palmes,
## hamac, table à coquillages, lanterne, enseigne et feu de camp.
## Repère local : la façade (+Z) regarde la mer.

const W: float = 4.2         # largeur
const D: float = 3.4         # profondeur de la pièce
const PORCH: float = 1.6     # terrasse devant
const FLOOR_Y: float = 0.55
const WALL_H: float = 2.25

var points: Dictionary = {}   # repères monde : porche, interieur, feu, rivage, table
var stairs_foot: Vector3      # pied de l'escalier (monde)
var _main: Node
var _wood: StandardMaterial3D
var _dark: StandardMaterial3D
var _thatch: StandardMaterial3D
var _body: StaticBody3D


func build(main: Node, at: Vector3, facing: Vector3, inventory: Node, sea_dir: Vector3 = Vector3.ZERO) -> void:
	name = "Cabane_Barnabe_v31"
	_main = main
	global_position = at
	facing.y = 0.0
	rotation.y = atan2(facing.x, facing.z)
	# Case sur pilotis : le plancher passe 30 cm au-dessus du point le plus haut du sol
	# sous la cabane ; les pilotis et l'escalier rattrapent la pente.
	var top: float = -INF
	for corner in [Vector3(-W * 0.5, 0, -D * 0.5), Vector3(W * 0.5, 0, -D * 0.5), Vector3(-W * 0.5, 0, D * 0.5 + PORCH), Vector3(W * 0.5, 0, D * 0.5 + PORCH), Vector3.ZERO]:
		top = maxf(top, _ground_world(corner))
	global_position.y = top + 0.3 - FLOOR_Y
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	_wood.uv1_triplanar = true
	_wood.uv1_scale = Vector3(1.3, 1.3, 1.3)
	_wood.albedo_color = Color(0.92, 0.84, 0.72)
	_wood.roughness = 0.85
	_dark = _wood.duplicate()
	_dark.albedo_color = Color(0.55, 0.45, 0.36)
	_thatch = StandardMaterial3D.new()
	_thatch.albedo_texture = load("res://assets/textures/jungle/thatch.png")   # palmes séchées
	_thatch.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_thatch.alpha_scissor_threshold = 0.45
	_thatch.cull_mode = BaseMaterial3D.CULL_DISABLED
	_thatch.roughness = 0.95
	_body = StaticBody3D.new()
	_body.name = "Cabane_collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_structure()
	_roof()
	_furniture(inventory)
	_sign()
	var fire_local := Vector3(2.9, 0.0, D * 0.5 + PORCH + 2.6)
	var fire_world: Vector3 = to_global(fire_local)
	fire_world.y = main._height_at(fire_world.x, fire_world.z)
	_fire_ring(fire_world)
	main._create_fire_v24(fire_world + Vector3.UP * 0.15)
	var glow := OmniLight3D.new()
	glow.name = "Lueur_feu_Barnabe_v53"
	glow.light_color = Color(1.0, 0.55, 0.25)
	glow.light_energy = 1.2
	glow.omni_range = 6.0
	get_parent().add_child(glow)
	glow.global_position = fire_world + Vector3.UP * 0.7
	main._add_obstacle_cylinder_v11("Feu_Barnabe_collision", fire_world + Vector3.UP * 0.3, 0.75, 0.6)
	points = {
		"porche": to_global(Vector3(-0.6, FLOOR_Y, D * 0.5 + 0.7)),
		"interieur": to_global(Vector3(0.6, FLOOR_Y, -0.3)),
		"table": to_global(Vector3(-1.1, FLOOR_Y, -0.8)),
		"feu": fire_world + (to_global(Vector3(1.9, 0, D * 0.5 + PORCH + 2.2)) - fire_world).normalized() * 1.4,
		"rivage": to_global(Vector3(-1.5, 0, D * 0.5 + PORCH + 7.0)),
	}
	# Le rivage : on descend la plage depuis le pied de l'escalier jusqu'à 60 cm au-dessus
	# de l'eau (Barnabé ne marche pas dans la mer).
	var out: Vector3 = sea_dir if sea_dir.length() > 0.1 else (to_global(Vector3(0, 0, 1)) - to_global(Vector3.ZERO))
	out.y = 0.0
	out = out.normalized()
	var shore: Vector3 = stairs_foot
	for i in range(40):
		var nxt: Vector3 = shore + out * 0.5
		if main._height_at(nxt.x, nxt.z) < 0.6:
			break
		shore = nxt
	points["rivage"] = shore
	for k in ["feu", "rivage"]:
		var p: Vector3 = points[k]
		p.y = main._height_at(p.x, p.z)
		points[k] = p


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
		var cs := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		cs.shape = s
		cs.position = pos
		cs.rotation = rot
		_body.add_child(cs)
	return mi


## Hauteur du sol (monde) sous un point local de la cabane.
func _ground_world(local: Vector3) -> float:
	var w: Vector3 = to_global(Vector3(local.x, 0, local.z))
	return _main._height_at(w.x, w.z)


func _ground_local(local: Vector3) -> float:
	return _ground_world(local) - global_position.y


func _post(pos: Vector3, h: float, r: float = 0.09) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r * 1.1
	c.height = h
	c.radial_segments = 8
	mi.mesh = c
	mi.material_override = _dark
	mi.position = pos + Vector3.UP * h * 0.5
	add_child(mi)
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	cs.shape = s
	cs.position = mi.position
	_body.add_child(cs)


func _structure() -> void:
	var depth_all: float = D + PORCH
	var zc: float = PORCH * 0.5
	# Pilotis, plantés 30 cm dans le sable
	for x in [-W * 0.5 + 0.15, 0.0, W * 0.5 - 0.15]:
		for z in [-D * 0.5 + 0.15, D * 0.5, D * 0.5 + PORCH - 0.15]:
			var g: float = _ground_local(Vector3(x, 0, z)) - 0.3
			_post(Vector3(x, g, z), FLOOR_Y - g, 0.1)
	# Plancher en planches (petits jours entre elles)
	var n: int = int(depth_all / 0.2)
	for i in range(n):
		var z: float = -D * 0.5 + 0.1 + i * 0.2
		_box(Vector3(W + 0.2, 0.06, 0.18), Vector3(0, FLOOR_Y - 0.03, z), _wood if i % 3 else _dark, false)
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(W + 0.2, 0.2, depth_all)
	cs.shape = s
	cs.position = Vector3(0, FLOOR_Y - 0.1, zc)
	_body.add_child(cs)
	# Escalier de la terrasse jusqu'au sable (marches de 25 cm au plus).
	var z0: float = D * 0.5 + PORCH
	var zs: float = z0
	var ys: float = FLOOR_Y
	var k: int = 0
	while k < 14:
		var g2: float = _ground_local(Vector3(0, 0, zs + 0.3))
		if ys - g2 < 0.18:
			break
		var top_y: float = maxf(ys - 0.25, g2 + 0.02)
		zs += 0.3
		# Marche ajourée (planche) ; un poteau sous l'escalier toutes les trois marches.
		_box(Vector3(1.3, 0.07, 0.32), Vector3(0, top_y - 0.035, zs - 0.15), _wood, true)
		if k % 3 == 1 and top_y - g2 > 0.4:
			for px in [-0.62, 0.62]:
				_post(Vector3(px, g2 - 0.2, zs - 0.15), top_y - g2 + 0.15, 0.05)
		ys = top_y
		k += 1
	for sx in [-0.7, 0.7]:
		if k > 0:
			var seg_len: float = sqrt(pow(zs - z0, 2.0) + pow(FLOOR_Y - ys, 2.0)) + 0.3
			var ang: float = atan2(FLOOR_Y - ys, zs - z0)
			_box(Vector3(0.06, 0.18, seg_len), Vector3(sx, (FLOOR_Y + ys) * 0.5 + 0.05, (z0 + zs) * 0.5), _dark, false, Vector3(ang, 0, 0))
	var foot: Vector3 = to_global(Vector3(0, 0, zs + 0.6))
	foot.y = _main._height_at(foot.x, foot.z)
	stairs_foot = foot
	# Murs : fond, côtés, façade avec large ouverture
	var y_mid: float = FLOOR_Y + WALL_H * 0.5
	_box(Vector3(W, WALL_H, 0.08), Vector3(0, y_mid, -D * 0.5), _wood, true)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.08, WALL_H, D), Vector3(sx * W * 0.5, y_mid, 0), _wood, true)
		_box(Vector3(1.25, WALL_H, 0.08), Vector3(sx * (W * 0.5 - 0.625), y_mid, D * 0.5), _wood, true)
		# fenêtre sur le côté (encadrement sombre)
		_box(Vector3(0.1, 0.7, 0.9), Vector3(sx * (W * 0.5 + 0.01), FLOOR_Y + 1.35, -0.3), _dark, false)
	_box(Vector3(W - 2.5, 0.3, 0.1), Vector3(0, FLOOR_Y + WALL_H - 0.15, D * 0.5), _dark, false)
	# Poutres d'angle
	for sx in [-1.0, 1.0]:
		for z in [-D * 0.5, D * 0.5]:
			_box(Vector3(0.14, WALL_H, 0.14), Vector3(sx * W * 0.5, y_mid, z), _dark, false)
	# Garde-corps de la terrasse
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.06, 0.06, PORCH), Vector3(sx * (W * 0.5 + 0.05), FLOOR_Y + 0.85, D * 0.5 + PORCH * 0.5), _dark, true)
		_post(Vector3(sx * (W * 0.5 + 0.05), FLOOR_Y, D * 0.5 + PORCH - 0.1), 0.88, 0.05)


func _roof() -> void:
	var ridge_y: float = FLOOR_Y + WALL_H + 1.0
	var eave_y: float = FLOOR_Y + WALL_H - 0.05
	var half_span: float = (D + PORCH) * 0.5 + 0.5
	var zc: float = PORCH * 0.5
	var slope_len: float = sqrt(half_span * half_span + pow(ridge_y - eave_y, 2.0))
	var ang: float = atan2(ridge_y - eave_y, half_span)
	for sz in [-1.0, 1.0]:
		var center := Vector3(0, (ridge_y + eave_y) * 0.5, zc + sz * half_span * 0.5)
		_box(Vector3(W + 1.0, 0.06, slope_len), center, _dark, false, Vector3(ang * sz, 0, 0))
		_cam_block(Vector3(W + 1.0, 0.35, slope_len), center + Vector3.UP * 0.12, Vector3(ang * sz, 0, 0))
		# Couches de palmes séchées, du bas vers le faîte, qui se recouvrent.
		var rows: int = 6
		for r in range(rows):
			var u: float = (float(r) + 0.5) / rows
			var p: Vector3 = Vector3(0, eave_y + (ridge_y - eave_y) * u + 0.05, zc + sz * half_span * (1.0 - u))
			var k: int = 0
			var x: float = -W * 0.5 - 0.4
			while x < W * 0.5 + 0.5:
				var mi := MeshInstance3D.new()
				var q := QuadMesh.new()
				q.size = Vector2(0.55, 1.5)
				mi.mesh = q
				mi.material_override = _thatch
				add_child(mi)
				# La palme pend vers le bas de la pente ; légère irrégularité.
				var b := Basis(Vector3.RIGHT, -PI * 0.5 + ang * sz)
				if sz < 0.0:
					b = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -PI * 0.5 + ang)
				b = b.rotated(Vector3.UP, (float(k % 3) - 1.0) * 0.08)
				mi.transform = Transform3D(b, p + Vector3(x + (0.12 if r % 2 else 0.0), 0.0, sz * 0.25))
				x += 0.42
				k += 1
	# Faîtage
	_box(Vector3(W + 1.1, 0.16, 0.22), Vector3(0, ridge_y + 0.04, zc), _dark, false)
	# Pignons
	for sx in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var x: float = sx * W * 0.5
		var n := Vector3(sx, 0, 0)
		for v in [Vector3(x, eave_y, -D * 0.5), Vector3(x, ridge_y - 0.05, zc), Vector3(x, eave_y, D * 0.5)]:
			st.set_normal(n)
			st.add_vertex(v)
		var mi2 := MeshInstance3D.new()
		mi2.mesh = st.commit()
		mi2.material_override = _wood
		add_child(mi2)


func _furniture(inventory: Node) -> void:
	# Table et tabourets
	_box(Vector3(1.2, 0.06, 0.7), Vector3(-1.1, FLOOR_Y + 0.75, -0.8), _wood, true)
	for x in [-1.6, -0.6]:
		for z in [-1.1, -0.5]:
			_box(Vector3(0.06, 0.75, 0.06), Vector3(x, FLOOR_Y + 0.375, z), _dark, false)
	# La collection de coquillages, sur la table et sur une étagère.
	if inventory != null:
		for i in range(7):
			var shell: Node3D = inventory.make_model("coquillage")
			add_child(shell)
			shell.position = Vector3(-1.55 + i * 0.14, FLOOR_Y + 0.78, -0.75 + (0.12 if i % 2 else -0.1))
			shell.rotation.y = i * 0.9
		_box(Vector3(1.6, 0.04, 0.3), Vector3(1.1, FLOOR_Y + 1.4, -D * 0.5 + 0.2), _dark, false)
		for i in range(9):
			var s2: Node3D = inventory.make_model("coquillage" if i % 3 else "pomme")
			add_child(s2)
			s2.position = Vector3(0.45 + i * 0.16, FLOOR_Y + 1.42, -D * 0.5 + 0.22)
	# Bouteilles et cartes roulées
	for i in range(4):
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.025
		c.bottom_radius = 0.045
		c.height = 0.28
		mi.mesh = c
		var glass := StandardMaterial3D.new()
		glass.albedo_color = [Color(0.2, 0.45, 0.25, 0.8), Color(0.45, 0.3, 0.15, 0.8)][i % 2]
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = 0.1
		mi.material_override = glass
		mi.position = Vector3(-0.65 + i * 0.07, FLOOR_Y + 0.92, -1.0)
		add_child(mi)
	for i in range(3):
		var roll := MeshInstance3D.new()
		var c2 := CylinderMesh.new()
		c2.top_radius = 0.04
		c2.bottom_radius = 0.04
		c2.height = 0.6
		roll.mesh = c2
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color(0.9, 0.84, 0.66)
		roll.material_override = paper
		roll.rotation = Vector3(0, 0.3 * i, PI * 0.5)
		roll.position = Vector3(1.4, FLOOR_Y + 0.05 + i * 0.08, 0.6 + i * 0.05)
		add_child(roll)
	# Tonneau et caisse
	var barrel := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.28
	bc.bottom_radius = 0.28
	bc.height = 0.8
	barrel.mesh = bc
	barrel.material_override = _dark
	barrel.position = Vector3(W * 0.5 - 0.5, FLOOR_Y + 0.4, D * 0.5 + 0.8)
	add_child(barrel)
	_box(Vector3(0.55, 0.45, 0.55), Vector3(-W * 0.5 + 0.45, FLOOR_Y + 0.225, -D * 0.5 + 0.45), _wood, true)
	# Lanterne suspendue (lumière chaude)
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.09
	lm.height = 0.18
	lamp.mesh = lm
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.8, 0.45)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.72, 0.35)
	glow.emission_energy_multiplier = 2.5
	lamp.material_override = glow
	lamp.position = Vector3(0, FLOOR_Y + WALL_H - 0.25, D * 0.5 + 0.6)
	add_child(lamp)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.45)
	light.light_energy = 1.2
	light.omni_range = 6.0
	light.position = lamp.position + Vector3.DOWN * 0.15
	add_child(light)


func _hammock() -> void:
	# Hamac tendu sur la terrasse, entre le pilier de façade et le garde-corps.
	var a := Vector3(-W * 0.5 + 0.2, FLOOR_Y + 1.1, D * 0.5 + 0.1)
	var b := Vector3(-W * 0.5 + 0.2, FLOOR_Y + 1.1, D * 0.5 + PORCH - 0.15)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 10
	var width: float = 0.7
	for i in range(segs):
		var t0: float = float(i) / segs
		var t1: float = float(i + 1) / segs
		var p0: Vector3 = a.lerp(b, t0) + Vector3.DOWN * sin(t0 * PI) * 0.45 + Vector3.RIGHT * 0.45
		var p1: Vector3 = a.lerp(b, t1) + Vector3.DOWN * sin(t1 * PI) * 0.45 + Vector3.RIGHT * 0.45
		var w0: float = width * (0.3 + 0.7 * sin(t0 * PI))
		var w1: float = width * (0.3 + 0.7 * sin(t1 * PI))
		var q := [p0 + Vector3.LEFT * w0 * 0.5 + Vector3.UP * 0.06 * sin(t0 * PI), p0 + Vector3.RIGHT * w0 * 0.5 + Vector3.UP * 0.06 * sin(t0 * PI),
			p1 + Vector3.LEFT * w1 * 0.5 + Vector3.UP * 0.06 * sin(t1 * PI), p1 + Vector3.RIGHT * w1 * 0.5 + Vector3.UP * 0.06 * sin(t1 * PI)]
		for v in [q[0], q[2], q[1], q[1], q[2], q[3]]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z))
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.78, 0.32, 0.22)
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth.roughness = 0.95
	mi.material_override = cloth
	add_child(mi)


func _sign() -> void:
	var post_pos := Vector3(W * 0.5 + 0.8, 0.0, D * 0.5 + PORCH + 1.0)
	post_pos.y = _ground_local(post_pos)
	_post(post_pos + Vector3.DOWN * 0.3, 2.0, 0.06)
	_box(Vector3(1.3, 0.55, 0.05), post_pos + Vector3(0, 1.45, 0.06), _wood, false)
	var lbl := Label3D.new()
	lbl.text = "CHEZ BARNABÉ\nCoquillages & sagesse"
	# V53 : le texte tient dans la planche (1,3 m), sur les deux faces
	lbl.font_size = 64
	lbl.pixel_size = 0.0016
	lbl.shaded = true
	lbl.double_sided = false
	lbl.modulate = Color(0.25, 0.14, 0.07)
	lbl.outline_size = 0
	lbl.position = post_pos + Vector3(0, 1.45, 0.095)
	add_child(lbl)
	var back := lbl.duplicate() as Label3D
	back.position = post_pos + Vector3(0, 1.45, 0.025)
	back.rotation.y = PI
	add_child(back)


func _fire_ring(at: Vector3) -> void:
	var Rocks = preload("res://scripts/rocks_v26.gd")
	var root := Node3D.new()
	root.name = "Foyer_Barnabe"
	get_parent().add_child(root)
	root.global_position = at
	var stone_mat: Material = Rocks.material(Color(0.5, 0.48, 0.45), 0.2, 0.5)
	for i in range(11):
		var a: float = TAU * i / 11.0
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.pebble(4400 + i, stone_mat)
		mi.position = Vector3(cos(a) * 0.62, 0.02, sin(a) * 0.62)
		mi.scale = Vector3.ONE * 0.9
		mi.rotation.y = a
		root.add_child(mi)
	for i in range(3):
		var wood_log := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.06
		c.bottom_radius = 0.07
		c.height = 0.7
		wood_log.mesh = c
		wood_log.material_override = _dark
		wood_log.rotation = Vector3(PI * 0.5, TAU * i / 3.0, 0.25)
		wood_log.position = Vector3(0, 0.1, 0)
		root.add_child(wood_log)


## V53 : un bloc qui arrête seulement la caméra (calque 9), pour les toits.
func _cam_block(size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name = "Toit_camera_v53"
	body.collision_layer = 256
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	body.position = pos
	body.rotation = rot
	add_child(body)

extends Node3D
## V29 : barque à voile pour aller d'une île à l'autre, et un ponton sur chaque île.
## PC : E près du bateau pour monter, Z/S avancer/reculer, Q/D barrer, E pour débarquer
## (près d'un ponton ou d'une plage). VR : gâchette droite pour monter/descendre,
## stick gauche pour avancer et barrer.

const LENGTH: float = 4.6
const BEAM: float = 1.6
const DEPTH: float = 0.72
const DRAFT: float = 0.28              # partie de la coque sous l'eau
const MAX_SPEED: float = 8.0
const MAX_REVERSE: float = 2.2
const ACCEL: float = 2.4
const WATER: float = -0.42
const DECK_Y: float = 1.0              # hauteur du plancher des pontons
const BOARD_REACH: float = 3.4
const WORLD_RADIUS: float = 560.0      # la mer navigable, autour du milieu des deux îles
const WORLD_MID := Vector3(0.0, 0.0, -165.0)
const GrandeIle = preload("res://scripts/grande_ile_v59.gd")

var main: Node
var driving: bool = false
var speed: float = 0.0
var yaw: float = PI                    # cap (rotation Y) ; la proue regarde vers -Z local
var bob_clock: float = 0.0
var docks: Array = []                  # {start, end, axis, name}
var hull: Node3D
var seat_local := Vector3(0.0, 0.0, 0.0)
var _wood: StandardMaterial3D
var _paint: StandardMaterial3D
var _sail_mat: StandardMaterial3D
var _rope: StandardMaterial3D
var _vr_yaw_offset: float = 0.0
var _vr_trigger_ready: bool = true
var _blocked_clock: float = 0.0
var vr_label: Label3D


func build(main_node: Node, island_dock: Array, jungle_dock: Array) -> void:
	main = main_node
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	_wood.uv1_triplanar = true
	_wood.uv1_scale = Vector3(1.6, 1.6, 1.6)
	_wood.roughness = 0.75
	_wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint = StandardMaterial3D.new()
	_paint.albedo_color = Color(0.13, 0.32, 0.38)
	_paint.roughness = 0.55
	_sail_mat = StandardMaterial3D.new()
	_sail_mat.albedo_color = Color(0.92, 0.88, 0.78)
	_sail_mat.roughness = 0.95
	_sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sail_mat.backlight_enabled = true
	_sail_mat.backlight = Color(0.35, 0.32, 0.25)
	_rope = StandardMaterial3D.new()
	_rope.albedo_color = Color(0.55, 0.45, 0.3)
	_make_dock("Ponton_village", island_dock[0], island_dock[1])
	_make_dock("Ponton_jungle", jungle_dock[0], jungle_dock[1])
	_make_boat()
	moor(0)
	print("ILE_MANGA_V29: bateau et ", docks.size(), " pontons")


# =================================================================== pontons

func _make_dock(label: String, start: Vector3, end: Vector3) -> void:
	start.y = DECK_Y
	end.y = DECK_Y
	var axis: Vector3 = (end - start)
	axis.y = 0.0
	var length: float = axis.length()
	axis = axis.normalized()
	var side: Vector3 = axis.cross(Vector3.UP).normalized()
	var root := Node3D.new()
	root.name = label
	add_child(root)
	var basis := Basis(side, Vector3.UP, -axis)        # Z local = vers la plage
	var center: Vector3 = (start + end) * 0.5
	# Planches transversales avec de petits jours entre elles.
	var plank := BoxMesh.new()
	plank.size = Vector3(2.4, 0.07, 0.42)
	var k: int = 0
	var s: float = 0.25
	while s < length:
		var p: Vector3 = start + axis * s
		var mi := MeshInstance3D.new()
		mi.mesh = plank
		mi.material_override = _wood
		root.add_child(mi)
		mi.global_transform = Transform3D(basis.rotated(Vector3.UP, (float(k % 3) - 1.0) * 0.012), p + Vector3.DOWN * 0.035)
		s += 0.46
		k += 1
	# Longerons et pieux.
	var beam := BoxMesh.new()
	beam.size = Vector3(0.14, 0.18, length)
	for sd in [-1.0, 1.0]:
		var mb := MeshInstance3D.new()
		mb.mesh = beam
		mb.material_override = _wood
		root.add_child(mb)
		mb.global_transform = Transform3D(basis, center + side * sd * 1.05 + Vector3.DOWN * 0.16)
	var post := CylinderMesh.new()
	post.top_radius = 0.11
	post.bottom_radius = 0.13
	post.height = 8.0
	var t: float = 0.6
	while t <= length + 0.01:
		for sd in [-1.0, 1.0]:
			var mp := MeshInstance3D.new()
			mp.mesh = post
			mp.material_override = _wood
			root.add_child(mp)
			mp.global_position = start + axis * t + side * sd * 1.15 + Vector3.DOWN * 3.7
		t += 2.6
	# Bollard d'amarrage au bout.
	var bollard := CylinderMesh.new()
	bollard.top_radius = 0.12
	bollard.bottom_radius = 0.14
	bollard.height = 0.6
	var mbo := MeshInstance3D.new()
	mbo.mesh = bollard
	mbo.material_override = _wood
	root.add_child(mbo)
	mbo.global_position = end - axis * 0.4 + side * 0.85 + Vector3.UP * 0.3
	# Plancher solide pour marcher.
	var body := StaticBody3D.new()
	body.name = label + "_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 0.3, length + 0.4)
	cs.shape = box
	body.add_child(cs)
	root.add_child(body)
	body.global_transform = Transform3D(basis, center + Vector3.DOWN * 0.15)
	docks.append({"name": label, "start": start, "end": end, "axis": axis, "side": side, "length": length})


## Le joueur à pied est-il sur un ponton ? (la limite de l'île ne s'y applique pas)
func on_dock(p: Vector3) -> bool:
	for d in docks:
		var rel: Vector3 = p - d["start"]
		var along: float = rel.dot(d["axis"])
		var across: float = absf(rel.dot(d["side"]))
		if along > -1.0 and along < float(d["length"]) + 0.3 and across < 1.35 and p.y > DECK_Y - 1.5:
			return true
	return false


# =================================================================== barque

func _make_boat() -> void:
	hull = Node3D.new()
	hull.name = "Barque_v29"
	add_child(hull)
	var shell := MeshInstance3D.new()
	shell.name = "Coque"
	shell.mesh = _hull_mesh()
	shell.material_override = _wood
	hull.add_child(shell)
	var stripe := MeshInstance3D.new()
	stripe.name = "Liseré"
	stripe.mesh = _hull_mesh(0.82, 0.96, 1.012)
	stripe.material_override = _paint
	hull.add_child(stripe)
	# Bancs, plancher.
	for b in [[0.95, 0.38, 1.25], [-0.55, 0.4, 1.38]]:
		var bench := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(b[2]), 0.05, 0.32)
		bench.mesh = bm
		bench.material_override = _wood
		bench.position = Vector3(0, float(b[1]), float(b[0]))
		hull.add_child(bench)
	var floor_m := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.7, 0.03, 3.0)
	floor_m.mesh = fm
	floor_m.material_override = _wood
	floor_m.position = Vector3(0, 0.1, 0.1)
	hull.add_child(floor_m)
	# Mât, bôme, voile, gouvernail.
	var mast_z: float = -0.9
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.035
	mm.bottom_radius = 0.055
	mm.height = 3.7
	mast.mesh = mm
	mast.material_override = _wood
	mast.position = Vector3(0, 0.1 + 1.85, mast_z)
	hull.add_child(mast)
	var boom := MeshInstance3D.new()
	var bm2 := CylinderMesh.new()
	bm2.top_radius = 0.03
	bm2.bottom_radius = 0.03
	bm2.height = 2.3
	boom.mesh = bm2
	boom.material_override = _wood
	boom.rotation_degrees = Vector3(90, 0, 0)
	boom.position = Vector3(0, 1.05, mast_z + 1.15)
	hull.add_child(boom)
	var sail := MeshInstance3D.new()
	sail.name = "Voile"
	sail.mesh = _sail_mesh(Vector3(0, 3.65, mast_z), Vector3(0, 1.1, mast_z), Vector3(0, 1.1, mast_z + 2.25))
	sail.material_override = _sail_mat
	hull.add_child(sail)
	var stay := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.008
	sm.bottom_radius = 0.008
	var a := Vector3(0, 3.7, mast_z)
	var bow := Vector3(0, DEPTH + 0.15, -LENGTH * 0.5 + 0.1)
	sm.height = a.distance_to(bow)
	stay.mesh = sm
	stay.material_override = _rope
	hull.add_child(stay)
	stay.position = (a + bow) * 0.5
	stay.basis = Basis(Quaternion(Vector3.UP, (a - bow).normalized()))
	var rudder := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.05, 0.75, 0.32)
	rudder.mesh = rm
	rudder.material_override = _paint
	rudder.position = Vector3(0, 0.15, LENGTH * 0.5 + 0.12)
	hull.add_child(rudder)
	var tiller := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.04, 0.04, 0.8)
	tiller.mesh = tm
	tiller.material_override = _wood
	tiller.position = Vector3(0, 0.62, LENGTH * 0.5 - 0.3)
	hull.add_child(tiller)
	for c in hull.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	seat_local = Vector3(0, 0.405, 0.95)
	vr_label = Label3D.new()
	vr_label.text = "Gâchette droite : monter à bord"
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 44
	vr_label.pixel_size = 0.003
	vr_label.outline_size = 12
	vr_label.no_depth_test = true
	vr_label.position = Vector3(0, 2.2, 0)
	vr_label.visible = false
	hull.add_child(vr_label)


func update_vr_label(head: Vector3) -> void:
	if vr_label != null:
		vr_label.visible = not driving and can_board(head)


## Coque : sections le long de Z (poupe en +Z, proue en -Z), bordé qui remonte vers l'avant.
## a0..a1 : portion de la section (0 = quille, 1 = plat-bord) ; grow : léger gonflement (liseré).
func _hull_mesh(a0: float = 0.0, a1: float = 1.0, grow: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ns: int = 28
	var na: int = 10
	var rows: Array = []
	for i in range(ns + 1):
		var s: float = float(i) / ns                     # 0 = poupe, 1 = proue
		var z: float = LENGTH * 0.5 - s * LENGTH
		var w: float
		if s < 0.42:
			w = BEAM * 0.5 * (0.64 + 0.36 * sin(PI * 0.5 * s / 0.42))
		else:
			w = BEAM * 0.5 * pow(cos(PI * 0.5 * (s - 0.42) / 0.58), 0.75)
		w = maxf(w, 0.015) * grow
		var keel: float = 0.28 * pow(maxf(s - 0.72, 0.0) / 0.28, 2.0) + 0.05 * pow(maxf(0.15 - s, 0.0) / 0.15, 2.0)
		var top: float = DEPTH + 0.2 * pow(s, 3.0)
		var row: Array = []
		for j in range(na + 1):
			var a: float = lerpf(a0, a1, float(j) / na)
			var lat: float = w * pow(sin(a * PI * 0.5), 0.7)
			var y: float = keel + (top - keel) * (1.0 - cos(a * PI * 0.5))
			row.append(Vector3(lat, y, z))
		rows.append(row)
	for side in [1.0, -1.0]:
		for i in range(ns):
			for j in range(na):
				var p00: Vector3 = rows[i][j] * Vector3(side, 1, 1)
				var p01: Vector3 = rows[i][j + 1] * Vector3(side, 1, 1)
				var p10: Vector3 = rows[i + 1][j] * Vector3(side, 1, 1)
				var p11: Vector3 = rows[i + 1][j + 1] * Vector3(side, 1, 1)
				if side > 0.0:
					st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p10)
					st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p11)
				else:
					st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
					st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)
	# Tableau arrière (poupe plate).
	if a0 == 0.0:
		var back: Array = rows[0]
		for j in range(na):
			for side2 in [1.0, -1.0]:
				var q0: Vector3 = Vector3(0, back[j].y, back[j].z)
				var q1: Vector3 = back[j] * Vector3(side2, 1, 1)
				var q2: Vector3 = back[j + 1] * Vector3(side2, 1, 1)
				var q3: Vector3 = Vector3(0, back[j + 1].y, back[j + 1].z)
				st.add_vertex(q0); st.add_vertex(q1); st.add_vertex(q2)
				st.add_vertex(q0); st.add_vertex(q2); st.add_vertex(q3)
	st.generate_normals()
	return st.commit()


func _sail_mesh(head: Vector3, tack: Vector3, clew: Vector3) -> ArrayMesh:
	# Voile légèrement creusée par le vent (bombée vers +X).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 8
	var grid: Array = []
	for i in range(n + 1):
		var u: float = float(i) / n
		var row: Array = []
		for j in range(n + 1 - i):
			var v: float = float(j) / n
			var p: Vector3 = tack + (head - tack) * u + (clew - tack) * v
			p.x += sin(PI * u) * sin(PI * minf(v / maxf(1.0 - u, 0.001), 1.0)) * 0.22
			row.append(p)
		grid.append(row)
	for i in range(n):
		for j in range(n - i):
			st.add_vertex(grid[i][j]); st.add_vertex(grid[i + 1][j]); st.add_vertex(grid[i][j + 1])
			if j + 1 < grid[i + 1].size():
				st.add_vertex(grid[i + 1][j]); st.add_vertex(grid[i + 1][j + 1]); st.add_vertex(grid[i][j + 1])
	st.generate_normals()
	return st.commit()


## Amarre la barque le long du ponton n (0 = village, 1 = jungle), proue vers le large.
func moor(n: int) -> void:
	if n < 0 or n >= docks.size():
		return
	var d: Dictionary = docks[n]
	var pos: Vector3 = d["end"] - d["axis"] * 2.6 + d["side"] * 2.15
	hull.global_position = Vector3(pos.x, WATER - DRAFT, pos.z)
	var fwd: Vector3 = d["axis"]
	yaw = atan2(-fwd.x, -fwd.z)
	speed = 0.0
	hull.rotation = Vector3(0, yaw, 0)


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func seat_transform() -> Transform3D:
	return hull.global_transform * Transform3D(Basis.IDENTITY, seat_local)


# =================================================================== monter / descendre

func can_board(p: Vector3) -> bool:
	if driving or hull == null:
		return false
	var c: Vector3 = hull.global_position
	return Vector2(p.x - c.x, p.z - c.z).length() < BOARD_REACH and absf(p.y - c.y) < 3.5


func board() -> void:
	if main.has_method("sfx"):
		main.sfx("gros_plouf", hull.global_position, -6.0)
	driving = true
	speed = 0.0
	if main.xr_active:
		_vr_yaw_offset = main.xr_origin.rotation.y - yaw
		_vr_trigger_ready = false


## Où débarquer : au bout d'un ponton proche, sinon sur une plage à quelques mètres.
func landing_spot() -> Variant:
	var c: Vector3 = hull.global_position
	for d in docks:
		if Vector2(c.x - d["end"].x, c.z - d["end"].z).length() < 6.5:
			return d["end"] - d["axis"] * 1.6 + Vector3.UP * 0.05
	for r in [2.5, 3.5, 4.5, 5.5, 6.5]:
		for k in range(16):
			var a: float = TAU * k / 16.0
			var x: float = c.x + cos(a) * r
			var z: float = c.z + sin(a) * r
			var h: float = main._height_at(x, z)
			if h > WATER + 0.15 and h < WATER + 4.0:
				var slope: float = absf(main._height_at(x + 0.6, z) - h) + absf(main._height_at(x, z + 0.6) - h)
				if slope < 0.5:
					return Vector3(x, h + 0.05, z)
	return null


func leave() -> bool:
	var spot: Variant = landing_spot()
	if spot == null:
		return false
	if main.has_method("sfx"):
		main.sfx("pas_bois", hull.global_position + Vector3.UP * 0.5)
	driving = false
	speed = 0.0
	# Arrivé au bout d'un ponton : la barque s'y amarre proprement.
	for i in range(docks.size()):
		if Vector2(hull.global_position.x - docks[i]["end"].x, hull.global_position.z - docks[i]["end"].z).length() < 6.5:
			moor(i)
	return true


func prompt(p: Vector3) -> String:
	if driving:
		return "E : débarquer" if landing_spot() != null else "Z / S : avancer, reculer  •  Q / D : barrer  •  approchez un ponton ou une plage pour débarquer"
	if can_board(p):
		return "E : monter dans le bateau"
	return ""


# =================================================================== navigation

## throttle : -1..1 (avant > 0) ; steer : -1..1 (droite > 0).
func drive(delta: float, throttle: float, steer: float) -> void:
	if throttle > 0.05:
		speed = minf(speed + ACCEL * throttle * delta, MAX_SPEED)
	elif throttle < -0.05:
		speed = maxf(speed + ACCEL * 1.2 * throttle * delta, -MAX_REVERSE)
	else:
		speed = move_toward(speed, 0.0, 0.9 * delta)
	var grip: float = clampf(absf(speed) / 3.0, 0.25, 1.0)
	var turn: float = -steer * 0.85 * grip * (1.0 if speed >= -0.05 else -1.0)
	yaw += turn * delta
	var step: Vector3 = forward() * speed * delta
	var next: Vector3 = hull.global_position + step
	_blocked_clock = maxf(_blocked_clock - delta, 0.0)
	if _blocked(next):
		speed = -speed * 0.25
		_blocked_clock = 0.4
	else:
		hull.global_position = next
	_float_motion(delta, turn)


func _blocked(next: Vector3) -> bool:
	var fwd: Vector3 = forward() * signf(speed if absf(speed) > 0.01 else 1.0)
	var right: Vector3 = Vector3(-fwd.z, 0, fwd.x)
	for probe in [next + fwd * 2.3, next + fwd * 1.4 + right * 0.7, next + fwd * 1.4 - right * 0.7, next]:
		if main._height_at(probe.x, probe.z) > WATER - DRAFT - 0.25:
			return true
		for d in docks:
			var rel: Vector3 = (probe as Vector3) - d["start"]
			var along: float = rel.dot(d["axis"])
			if along > -0.5 and along < float(d["length"]) + 0.5 and absf(rel.dot(d["side"])) < 1.45:
				return true
	# V59 : la mer de l'est (la grande île) ; la barque ne passe pas à travers le Léviathan
	if not GrandeIle.sea_contains(next.x, next.z, Vector2(WORLD_MID.x, WORLD_MID.z), WORLD_RADIUS):
		return true
	var g59: Node = main.get("grande_v59")
	if g59 != null and g59.blocks_boat(next + fwd * 2.3):
		return true
	return false


## Tangage, roulis et gîte dans les virages.
func _float_motion(delta: float, turn: float) -> void:
	bob_clock += delta
	var heave: float = sin(bob_clock * 1.3) * 0.05 + sin(bob_clock * 2.1 + 1.0) * 0.025
	var pitch: float = sin(bob_clock * 1.1 + 0.4) * 0.025 + speed * 0.004
	var roll: float = sin(bob_clock * 0.9) * 0.035 + turn * clampf(absf(speed) / MAX_SPEED, 0.0, 1.0) * 0.12
	hull.global_position.y = WATER - DRAFT + heave
	hull.rotation = Vector3(pitch, yaw, roll)


## V52 : la mer ne se dessine pas à l'intérieur de la coque (shaders water*.gdshader).
func _process(_delta: float) -> void:
	if hull == null or main == null:
		return
	var m: ShaderMaterial = main.get("ocean_material")
	if m != null:
		m.set_shader_parameter("boat_inv", Projection(hull.global_transform.affine_inverse()))
		m.set_shader_parameter("boat_on", true)


## V52 : la barque revient s'amarrer au ponton du village (après un évanouissement loin
## d'elle). Vrai si elle a été déplacée.
func return_home() -> bool:
	if hull == null or docks.is_empty():
		return false
	driving = false
	var d: Dictionary = docks[0]
	if Vector2(hull.global_position.x - d["end"].x, hull.global_position.z - d["end"].z).length() < 12.0:
		return false
	moor(0)
	return true


func _physics_process(delta: float) -> void:
	# À l'amarre : la barque continue de bouger doucement sur l'eau.
	if not driving and hull != null:
		_float_motion(delta, 0.0)


# =================================================================== VR

## Stick gauche : avant/arrière et barre. Gâchette droite : débarquer.
func vr_tick(delta: float, stick: Vector2, trigger: float) -> void:
	drive(delta, stick.y if absf(stick.y) > 0.2 else 0.0, stick.x if absf(stick.x) > 0.2 else 0.0)
	var pressed: bool = trigger > 0.7
	if pressed and _vr_trigger_ready:
		main._leave_boat_v29()
	_vr_trigger_ready = not pressed


func serialize() -> Dictionary:
	return {"x": hull.global_position.x, "z": hull.global_position.z, "cap": yaw, "a_bord": driving}


func load_data(d: Dictionary) -> void:
	if d.is_empty():
		moor(0)
		return
	hull.global_position = Vector3(float(d.get("x", 0.0)), WATER - DRAFT, float(d.get("z", 0.0)))
	yaw = float(d.get("cap", PI))
	speed = 0.0
	hull.rotation = Vector3(0, yaw, 0)

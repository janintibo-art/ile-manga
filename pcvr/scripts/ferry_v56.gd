extends Node3D
## V56 : L'Hirondelle, le bateau de ligne entre l'île du village et Port-Azur. Un petit
## navire à passagers de 22 m : coque blanche à bande bleue, pont de teck, salon vitré,
## timonerie, cheminée, bouées. Il attend à quai (au ponton du village ou au môle de la
## gare maritime) ; le capitaine Léon propose la traversée (5 pièces, la première est
## offerte par la mairie). Pendant le voyage le joueur est passager, assis sur le pont :
## il regarde autour de lui. Une cloche sur chaque quai rappelle le bateau s'il est en face.
## Trajet : marche avant jusqu'au large, virage, marche arrière pour se mettre à quai.

const Kit = preload("res://scripts/azur_kit_v56.gd")
const LENGTH: float = 22.0
const BEAM: float = 6.2
const CRUISE: float = 9.0
const SLOW: float = 3.0
const TURN_RATE: float = 0.35          # rad/s
const WATER: float = -0.42

var main: Node
var azur: Node
var kit
var hull: Node3D
var body: AnimatableBody3D
var at: String = "village"             # "village", "azur", ou "" en mer
var riding: bool = false
var captain: Node3D
var first_trip: bool = true
var berth_v: Transform3D
var berth_a: Transform3D
var gangway_v: Vector3
var gangway_a: Vector3
var bell_v: Vector3
var bell_a: Vector3
var legs: Array = []
var leg_i: int = 0
var leg_t: float = 0.0
var pos: Vector3
var heading: float = 0.0               # rotation Y (l'avant regarde -Z local)
var speed: float = 0.0
var dest: String = ""
var _bob: float = 0.0
var _seat_local := Vector3(1.2, 1.55, 6.2)
var _wake: GPUParticles3D
var _nav_lights: Array = []
var _engine: AudioStreamPlayer3D


func setup(main_node: Node, azur_node: Node, village_pier: Array, azur_berth: Transform3D, azur_gangway: Vector3) -> void:
	main = main_node
	azur = azur_node
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56"))
	# poste au ponton du village : le long du ponton, côté large, l'avant vers la mer
	var s: Vector3 = village_pier[0]
	var e: Vector3 = village_pier[1]
	var axis: Vector3 = (e - s)
	axis.y = 0.0
	axis = axis.normalized()
	var side: Vector3 = axis.cross(Vector3.UP).normalized()
	var mid: Vector3 = s + axis * ((e - s).length() - LENGTH * 0.5 - 1.0)
	var c: Vector3 = mid + side * (1.2 + BEAM * 0.5 + 0.35)
	c.y = WATER
	berth_v = Transform3D(Basis(Vector3.UP, atan2(-axis.x, -axis.z)), c)
	gangway_v = mid + side * 1.0
	gangway_v.y = 1.0
	bell_v = s + axis * 1.5 - side * 1.6
	bell_v.y = main._height_at(bell_v.x, bell_v.z)
	berth_a = Transform3D(azur_berth.basis, Vector3(azur_berth.origin.x, WATER, azur_berth.origin.z))
	gangway_a = azur_gangway
	bell_a = azur.port.T(-73.0, -2.0)
	_build_ship()
	_build_village_pier_decor(s, axis, side)
	_build_bell(bell_a, azur.port.ile.TOWN_YAW)
	kit.commit()
	_dock_at("village")


# =================================================================== le navire

func _hull_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 22
	var segs := 14
	var depth: float = 2.6
	var sections: Array = []
	for i in range(rings + 1):
		var t: float = float(i) / rings          # 0 = arrière, 1 = avant
		var z: float = (0.5 - t) * LENGTH        # l'avant vers -Z
		var wf: float
		if t > 0.7:
			wf = sqrt(clampf(1.0 - pow((t - 0.7) / 0.3, 2.0), 0.0, 1.0)) * 0.97 + 0.03
		else:
			wf = 0.86 + 0.14 * sin(t / 0.7 * PI * 0.5)
		var sheer: float = 1.55 + 0.45 * pow(maxf(t - 0.6, 0.0) / 0.4, 2.0)
		var ring: Array = []
		for k in range(segs + 1):
			var a: float = PI * float(k) / segs
			var x: float = -cos(a) * BEAM * 0.5 * wf
			var y: float = sheer - sin(a) * depth * (0.7 + 0.3 * wf) - (1.0 - wf) * 0.3
			ring.append(Vector3(x, y, z))
		sections.append(ring)
	for i in range(rings):
		for k in range(segs):
			var a0: Vector3 = sections[i][k]
			var a1: Vector3 = sections[i][k + 1]
			var b0: Vector3 = sections[i + 1][k]
			var b1: Vector3 = sections[i + 1][k + 1]
			var c: Vector3 = (a0 + a1 + b0 + b1) * 0.25
			var n: Vector3 = (a1 - a0).cross(b0 - a0).normalized()
			if n.dot(Vector3(c.x, c.y - 0.5, 0.0)) < 0.0:
				n = -n
			var y: float = c.y
			var col: Color = Color(0.62, 0.12, 0.1) if y < 0.05 else (Color(0.12, 0.26, 0.55) if y < 0.55 else Color(0.97, 0.97, 0.96))
			for tri in [[a0, b0, a1], [a1, b0, b1]]:
				var tn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
				var order: Array = tri if tn.dot(n) < 0.0 else [tri[0], tri[2], tri[1]]
				for p in order:
					st.set_color(col)
					st.set_normal(n)
					st.set_uv(Vector2(p.z, p.y))
					st.add_vertex(p)
	# tableau arrière (la poupe plate)
	var back: Array = sections[0]
	for k in range(segs):
		var p0: Vector3 = back[k]
		var p1: Vector3 = back[k + 1]
		var top0 := Vector3(p0.x, 1.55, p0.z)
		var top1 := Vector3(p1.x, 1.55, p1.z)
		var nn := Vector3(0, 0, 1)
		for tri2 in [[p0, top0, p1], [p1, top0, top1]]:
			var tn2: Vector3 = (tri2[1] - tri2[0]).cross(tri2[2] - tri2[0])
			var order2: Array = tri2 if tn2.dot(nn) < 0.0 else [tri2[0], tri2[2], tri2[1]]
			for p2 in order2:
				st.set_color(Color(0.97, 0.97, 0.96) if p2.y > 0.55 else Color(0.12, 0.26, 0.55))
				st.set_normal(nn)
				st.set_uv(Vector2(p2.x, p2.y))
				st.add_vertex(p2)
	return st.commit()


func _build_ship() -> void:
	hull = Node3D.new()
	hull.name = "Hirondelle"
	add_child(hull)
	var hm := MeshInstance3D.new()
	hm.mesh = _hull_mesh()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	hm.material_override = m
	hull.add_child(hm)
	# le pont, le pavois, les rambardes
	var deck_y: float = 1.55
	var parts := Node3D.new()
	hull.add_child(parts)
	var k2 = Kit.new()
	k2.setup(parts, main.get("temps_v56"))
	k2.mats = kit.mats
	k2.box(Transform3D(Basis(), Vector3(0, deck_y - 0.04, 0.5)), Vector3(BEAM * 0.86, 0.08, LENGTH * 0.86), "planches", 2.0, 4)
	for sx in [-1.0, 1.0]:
		k2.box(Transform3D(Basis(), Vector3(sx * BEAM * 0.43, deck_y + 0.45, 0.8)), Vector3(0.12, 0.9, LENGTH * 0.8), "peinture_blanc", 1.0)
		k2.quad(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(sx * BEAM * 0.43, deck_y + 1.25, 0.8)), LENGTH * 0.8, 0.7, "balcon", Vector2(0, 0), Vector2(LENGTH * 0.8 / 1.6, 1.0), true)
	k2.box(Transform3D(Basis(), Vector3(0, deck_y + 0.45, LENGTH * 0.5 - 0.1)), Vector3(BEAM * 0.86, 0.9, 0.12), "peinture_blanc", 1.0)
	# le salon vitré au milieu, la timonerie au-dessus vers l'avant
	k2.box(Transform3D(Basis(), Vector3(0, deck_y + 1.2, -1.0)), Vector3(BEAM * 0.7, 2.4, 9.0), "peinture_blanc", 2.0)
	for sx2 in [-1.0, 1.0]:
		for k in range(4):
			k2.quad(Transform3D(Basis(Vector3.UP, -sx2 * PI / 2.0), Vector3(sx2 * (BEAM * 0.35 + 0.01), deck_y + 1.45, -4.4 + k * 2.2)), 1.7, 1.1, "vitrine_nuit")
	k2.box(Transform3D(Basis(), Vector3(0, deck_y + 2.45, -1.0)), Vector3(BEAM * 0.74, 0.1, 9.4), "peinture_bleu", 1.0)
	k2.box(Transform3D(Basis(), Vector3(0, deck_y + 3.5, -3.6)), Vector3(3.2, 2.0, 3.0), "peinture_blanc", 1.0)
	k2.quad(Transform3D(Basis(), Vector3(0, deck_y + 3.75, -5.11)), 2.8, 0.9, "fenetre_nuit")
	k2.box(Transform3D(Basis(), Vector3(0, deck_y + 4.55, -3.6)), Vector3(3.6, 0.12, 3.4), "peinture_bleu", 1.0)
	k2.cyl(Transform3D(Basis(), Vector3(0, deck_y + 4.6, -3.0)), 0.05, 0.04, 3.0, "chrome", 6)
	k2.quad(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0.45, deck_y + 7.2, -3.0)), 0.8, 0.5, "tissu_bleu", Vector2.ZERO, Vector2.ONE, true)
	# la cheminée
	k2.cyl(Transform3D(Basis(), Vector3(0, deck_y + 2.5, 1.6)), 0.55, 0.5, 2.0, "peinture_blanc", 14)
	k2.cyl(Transform3D(Basis(), Vector3(0, deck_y + 3.9, 1.6)), 0.52, 0.5, 0.45, "peinture_rouge", 14, false)
	k2.cyl(Transform3D(Basis(), Vector3(0, deck_y + 4.35, 1.6)), 0.5, 0.48, 0.18, "peinture_noir", 14)
	# bancs du pont arrière, bouées
	for z in [6.0, 7.6]:
		for sx3 in [-1.0, 1.0]:
			k2.bench(Transform3D(Basis(Vector3.UP, PI if sx3 > 0 else 0.0), Vector3(sx3 * 1.4, deck_y, z)))
	for sx4 in [-1.0, 1.0]:
		for z2 in [-3.0, 1.0]:
			k2.ring(Transform3D(Basis(Vector3.BACK, PI / 2.0 * sx4), Vector3(sx4 * (BEAM * 0.35 + 0.02), deck_y + 1.2, z2)), 0.22, 0.34, 0.12, "peinture_orange", 14)
	k2.commit()
	# le nom à la proue
	var nm := StandardMaterial3D.new()
	nm.albedo_texture = load("res://assets/textures/azur/enseigne_hirondelle.png") if ResourceLoader.exists("res://assets/textures/azur/enseigne_hirondelle.png") else null
	nm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	for sx5 in [-1.0, 1.0]:
		var q := QuadMesh.new()
		q.size = Vector2(3.4, 0.85)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = nm
		mi.position = Vector3(sx5 * (BEAM * 0.44), 1.15, -7.0)
		mi.rotation.y = sx5 * PI / 2.0
		hull.add_child(mi)
	# feux de navigation (vert à tribord, rouge à bâbord) et feu de mât
	for nl in [[Vector3(BEAM * 0.36, deck_y + 2.6, -5.0), Color(0.2, 1.0, 0.35)], [Vector3(-BEAM * 0.36, deck_y + 2.6, -5.0), Color(1.0, 0.2, 0.15)], [Vector3(0, deck_y + 7.6, -3.0), Color(1.0, 0.95, 0.8)]]:
		var l := OmniLight3D.new()
		l.light_color = nl[1]
		l.omni_range = 4.0
		l.position = nl[0]
		hull.add_child(l)
		if main.get("temps_v56") != null:
			main.temps_v56.register_lamp(l, 1.5)
		_nav_lights.append(l)
	# la collision : la coque et le salon (le bateau est solide, on ne le traverse pas)
	body = AnimatableBody3D.new()
	body.name = "Hirondelle_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	body.sync_to_physics = false
	for b in [[Vector3(0, deck_y - 1.2, 0.0), Vector3(BEAM * 0.9, 2.4, LENGTH * 0.92)], [Vector3(0, deck_y + 1.2, -1.0), Vector3(BEAM * 0.7, 2.4, 9.0)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = b[1]
		cs.shape = bs
		cs.position = b[0]
		body.add_child(cs)
	hull.add_child(body)
	# le sillage
	_wake = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.3, 1)
	pm.spread = 25.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.5
	pm.gravity = Vector3(0, -1.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(BEAM * 0.4, 0.1, 0.5)
	_wake.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.8, 0.8)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1, 1, 1, 0.6)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var tex: Texture2D = main._soft_dot_v24() if main.has_method("_soft_dot_v24") else null
	if tex != null:
		fm.albedo_texture = tex
	qm.material = fm
	_wake.draw_pass_1 = qm
	_wake.amount = 90
	_wake.lifetime = 2.2
	_wake.local_coords = false
	_wake.position = Vector3(0, 0.4, LENGTH * 0.5)
	_wake.emitting = false
	hull.add_child(_wake)
	_engine = AudioStreamPlayer3D.new()
	var snd: String = "res://assets/sons/sfx/moteur_bateau_1.ogg"
	if ResourceLoader.exists(snd):
		var st: AudioStream = load(snd)
		if st is AudioStreamOggVorbis:
			st = (st as AudioStreamOggVorbis).duplicate()
			(st as AudioStreamOggVorbis).loop = true
		_engine.stream = st
		_engine.unit_size = 10.0
		_engine.volume_db = -6.0
		_engine.max_distance = 90.0
		_engine.bus = "Bruitages" if AudioServer.get_bus_index("Bruitages") >= 0 else "Master"
	hull.add_child(_engine)


## Au village : l'affiche de Port-Azur et la cloche d'appel au pied du ponton.
func _build_village_pier_decor(s: Vector3, axis: Vector3, side: Vector3) -> void:
	var g: Vector3 = s - axis * 2.5 - side * 1.8
	g.y = main._height_at(g.x, g.z)
	var yaw: float = atan2(-axis.x, -axis.z) + PI
	var xf := Transform3D(Basis(Vector3.UP, yaw), g)
	for sx in [-0.7, 0.7]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx, 1.1, 0)), Vector3(0.1, 2.2, 0.1), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.55, 0)), Vector3(1.4, 1.9, 0.06), "bois", 1.0)
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = load("res://assets/textures/azur/affiche_ferry.png")
	pm.roughness = 0.7
	var q := QuadMesh.new()
	q.size = Vector2(1.15, 1.72)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = pm
	mi.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.55, -0.04))
	add_child(mi)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.1, 0)), Vector3(1.5, 2.2, 0.2))
	_build_bell(bell_v, yaw)


func _build_bell(p: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), p)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(0.14, 2.4, 0.14), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0.3, 2.3, 0)), Vector3(0.7, 0.1, 0.1), "bois_sombre", 1.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0.55, 1.85, 0)), 0.2, 0.08, 0.32, "laiton", 12)
	kit.col_cyl(p, 0.12, 2.4)


# =================================================================== à quai, en mer

func _berth(side: String) -> Transform3D:
	return berth_v if side == "village" else berth_a


func _dock_at(side: String) -> void:
	at = side
	var b: Transform3D = _berth(side)
	pos = b.origin
	heading = b.basis.get_euler().y
	speed = 0.0
	legs.clear()
	_apply()
	_wake.emitting = false
	place_captain()


func sailing() -> bool:
	return at == ""


func price() -> int:
	return 0 if first_trip else 5


## Le capitaine attend sur le quai où se trouve le bateau (il disparaît pendant la traversée).
func place_captain() -> void:
	if captain == null or not is_instance_valid(captain):
		return
	if at == "":
		captain.visible = false
		return
	captain.visible = true
	var g: Vector3 = gangway_v if at == "village" else gangway_a
	var b: Transform3D = _berth(at)
	var toward_ship: Vector3 = (b.origin - g)
	toward_ship.y = 0.0
	var p: Vector3 = g - toward_ship.normalized() * 1.2 + (b.basis * Vector3(0, 0, 1)) * 2.0
	captain.global_position = Vector3(p.x, g.y, p.z)
	captain.rotation.y = atan2(toward_ship.x, toward_ship.z) + PI * 0.5
	captain.points["quai_ferry"] = captain.global_position
	captain.at_point = "quai_ferry"
	captain.route.clear()
	captain.state = "repos"
	captain.idle_clock = 1e9


## Départ : avec le joueur à bord (passenger) ou à vide (on l'a appelé de l'autre côté).
func depart(with_player: bool) -> void:
	if at == "":
		return
	var from: String = at
	dest = "azur" if from == "village" else "village"
	var b0: Transform3D = _berth(from)
	var b1: Transform3D = _berth(dest)
	var out0: Vector3 = b0.origin + (b0.basis * Vector3(0, 0, -1)) * 45.0
	var out1: Vector3 = b1.origin + (b1.basis * Vector3(0, 0, -1)) * 45.0
	legs = [
		{"type": "move", "to": out0, "speed": CRUISE * 0.6, "rev": false},
		{"type": "move", "to": out1, "speed": CRUISE, "rev": false},
		{"type": "turn", "to": b1.basis.get_euler().y},
		{"type": "move", "to": b1.origin, "speed": SLOW, "rev": true},
	]
	leg_i = 0
	at = ""
	if with_player:
		riding = true
		if first_trip:
			first_trip = false
		if main.inventory_v28 != null and main.inventory_v28.opened:
			main.inventory_v28.close()
		if main.get("hero_v28") != null and not main.xr_active:
			main.hero_v28.cam_distance = maxf(main.hero_v28.cam_distance, 3.0)
	place_captain()
	main.sfx("corne_brume", pos + Vector3.UP * 6.0)
	_wake.emitting = true
	if _engine.stream != null:
		_engine.play()


func _physics_process(delta: float) -> void:
	if main == null:
		return
	_bob += delta
	if legs.is_empty():
		_apply()
		return
	var leg: Dictionary = legs[leg_i]
	match str(leg["type"]):
		"move":
			var to: Vector3 = leg["to"]
			var d: Vector3 = to - pos
			d.y = 0.0
			var dist: float = d.length()
			var target_speed: float = float(leg["speed"])
			if leg_i == legs.size() - 1:
				target_speed = minf(target_speed, maxf(dist * 0.4, 0.5))
			speed = move_toward(speed, target_speed, delta * 1.2)
			if dist < 0.4:
				leg_i += 1
			else:
				var want: float = atan2(-d.x, -d.z) + (PI if bool(leg["rev"]) else 0.0)
				heading = rotate_toward(heading, want, delta * TURN_RATE * (1.0 if not bool(leg["rev"]) else 2.0))
				pos += d.normalized() * minf(speed * delta, dist)
		"turn":
			speed = move_toward(speed, 0.0, delta * 2.0)
			var target: float = float(leg["to"])
			heading = rotate_toward(heading, target, delta * TURN_RATE)
			if absf(angle_difference(heading, target)) < 0.01:
				leg_i += 1
	if leg_i >= legs.size():
		_arrive()
	_apply()


func _apply() -> void:
	var bob: float = sin(_bob * 0.8) * 0.06
	hull.global_transform = Transform3D(Basis(Vector3.UP, heading).rotated(Basis(Vector3.UP, heading) * Vector3.RIGHT, sin(_bob * 0.6) * 0.012), Vector3(pos.x, WATER + bob, pos.z))
	if body != null:
		body.global_transform = hull.global_transform
	if riding:
		_carry_player()


func _arrive() -> void:
	var was_riding: bool = riding
	riding = false
	_engine.stop()
	_dock_at(dest)
	if was_riding:
		var g: Vector3 = gangway_v if at == "village" else gangway_a
		var b: Transform3D = _berth(at)
		var back: Vector3 = (g - b.origin)
		back.y = 0.0
		var spot: Vector3 = g + back.normalized() * 0.4 + Vector3.UP * 0.25
		if main.xr_active:
			main.xr_origin.position = spot
			main.vr_body.global_position = spot
			main.vr_body.velocity = Vector3.ZERO
		else:
			main.pc_root.position = spot
			main.pc_body.global_position = spot
			main.pc_body.velocity = Vector3.ZERO
			if main.get("hero_v28") != null:
				main.hero_v28.leave_ride()
				main.hero_v28.state = "sol"
				main.hero_v28.cam_distance = 1.0
		main.last_ok_v29.clear()
		main._show_message_v28("Arrivée à " + ("Port-Azur !" if at == "azur" else "l'île du village."))
		main.sfx("corne_brume", pos + Vector3.UP * 6.0)


## Le joueur passager, assis sur le banc du pont arrière.
func _carry_player() -> void:
	var seat: Transform3D = hull.global_transform * Transform3D(Basis(Vector3.UP, PI * 0.5), _seat_local)
	if main.xr_active:
		var cam_local: Vector3 = main.xr_camera.position
		var off: Vector3 = Basis(Vector3.UP, main.xr_origin.rotation.y) * Vector3(cam_local.x, 0.0, cam_local.z)
		main.xr_origin.position = Vector3(seat.origin.x - off.x, seat.origin.y - 0.3, seat.origin.z - off.z)
		main.vr_body.global_position = seat.origin + Vector3.UP * 0.4
		main.vr_body.velocity = Vector3.ZERO
	else:
		main.pc_root.position = seat.origin
		main.pc_body.global_position = seat.origin + Vector3.UP * 0.4
		main.pc_body.velocity = Vector3.ZERO
		if main.get("hero_v28") != null:
			main.hero_v28.ride(seat)


## La cloche du quai : rappelle le bateau s'il est de l'autre côté.
func bell_near(p: Vector3) -> String:
	if Vector2(p.x, p.z).distance_to(Vector2(bell_v.x, bell_v.z)) < 2.2:
		return "village"
	if Vector2(p.x, p.z).distance_to(Vector2(bell_a.x, bell_a.z)) < 2.2:
		return "azur"
	return ""


func ring_bell(side: String) -> void:
	main.sfx("cloche_bateau", bell_v if side == "village" else bell_a)
	if at != "" and at != side:
		main._show_message_v28("L'Hirondelle arrive ! Patientez sur le quai.")
		depart(false)
	elif at == side:
		main._show_message_v28("L'Hirondelle est à quai : parlez au capitaine Léon.")
	else:
		main._show_message_v28("L'Hirondelle est en route.")


func serialize() -> Dictionary:
	return {"quai": at if at != "" else dest, "premier": first_trip}


func load_data(d: Dictionary) -> void:
	riding = false
	first_trip = bool(d.get("premier", true))
	var side: String = str(d.get("quai", "village"))
	_dock_at(side if side in ["village", "azur"] else "village")

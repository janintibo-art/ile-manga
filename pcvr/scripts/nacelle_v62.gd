extends Node3D
## V62 : les deux manèges de Ramure.
##  - « ascenseur » : la nacelle d'osier du Chêne-Mère, qui monte du pied de l'arbre à la cime
##    (la Poste des chouettes) et redescend, tirée par une grande roue à cordes. Elle attend
##    à chaque étage, puis repart toute seule ;
##  - « tyrolienne » : la poulie et sa poignée, sur le câble qui descend de la plate-forme du
##    guet jusqu'à la Clairière des Jeux. On s'y accroche en haut (E), on dévale, on lâche
##    tout seul en bas ; la poulie remonte ensuite le câble, à vide.
## Pendant le trajet, le joueur est porté (même principe que le téléphérique de Cliquetis).

const LIFT_WAIT: float = 9.0
const LIFT_TRAVEL: float = 16.0
const ZIP_TIME: float = 6.5
const ZIP_BACK: float = 18.0

var main: Node
var mode: String = "ascenseur"
var low := Vector3.ZERO                 # ascenseur : le plancher en bas ; tyrolienne : l'arrivée (sol)
var high := Vector3.ZERO                # ascenseur : le plancher en haut ; tyrolienne : le départ (plancher)
var exit_low := Vector3.ZERO            # où l'on pose le joueur en descendant
var exit_high := Vector3.ZERO
var sag: float = 1.6
var riding: bool = false
var s: float = 0.0                      # 0 en bas, 1 en haut (ascenseur) ; 0 au départ, 1 à l'arrivée (tyrolienne)
var state: String = "attente"           # attente, monte, descend (ascenseur) ; pret, glisse, retour (tyrolienne)
var timer: float = 0.0
var at_top: bool = false
var car: Node3D
var _wheel: Node3D
var _sfx: AudioStreamPlayer3D
var _mats: Dictionary = {}
var rides: int = 0


func setup(main_node: Node, kind: String, a: Vector3, b: Vector3, out_low: Vector3, out_high: Vector3) -> void:
	main = main_node
	mode = kind
	low = a
	high = b
	exit_low = out_low
	exit_high = out_high
	car = _build_car()
	add_child(car)
	if mode == "ascenseur":
		_build_lift_frame()
		state = "attente"
		timer = LIFT_WAIT
		s = 0.0
	else:
		_build_cable()
		state = "pret"
		s = 0.0
	_sfx = AudioStreamPlayer3D.new()
	_sfx.unit_size = 6.0
	_sfx.max_distance = 45.0
	_sfx.volume_db = -6.0
	add_child(_sfx)
	_apply()


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"osier":
			m.albedo_color = Color(0.66, 0.5, 0.28)
			m.roughness = 0.95
		"bois":
			m.albedo_texture = load("res://assets/textures/ramure/planches.png")
			m.roughness = 0.85
		"corde":
			m.albedo_color = Color(0.62, 0.5, 0.32)
			m.roughness = 0.95
		"fer":
			m.albedo_color = Color(0.15, 0.14, 0.14)
			m.metallic = 0.7
			m.roughness = 0.45
		"rouge":
			m.albedo_color = Color(0.66, 0.1, 0.08)
			m.roughness = 0.4
	_mats[key] = m
	return m


func _piece(parent: Node3D, mesh: Mesh, key: String, at: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(key)
	mi.position = at
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cylm(r0: float, r1: float, h: float, seg: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r0
	c.bottom_radius = r1
	c.height = h
	c.radial_segments = seg
	return c


func _build_car() -> Node3D:
	var c := Node3D.new()
	c.name = "Nacelle_" + mode
	if mode == "ascenseur":
		# un grand panier d'osier, quatre cordes qui montent vers la roue
		_piece(c, _box(Vector3(1.7, 0.12, 1.7)), "bois", Vector3(0, 0.06, 0))
		var basket := _cylm(1.0, 0.92, 1.0, 16)
		var bm := _piece(c, basket, "osier", Vector3(0, 0.55, 0))
		bm.scale = Vector3(1.0, 1.0, 1.0)
		var top := TorusMesh.new()
		top.inner_radius = 0.96
		top.outer_radius = 1.06
		_piece(c, top, "corde", Vector3(0, 1.06, 0))
		for k in range(4):
			var a: float = PI * 0.5 * k + PI * 0.25
			var p := Vector3(cos(a) * 0.9, 1.05, sin(a) * 0.9)
			var rope := _cylm(0.025, 0.025, 2.4, 5)
			var mi := _piece(c, rope, "corde", p.lerp(Vector3(0, 3.3, 0), 0.5))
			var y: Vector3 = (Vector3(0, 3.3, 0) - p).normalized()
			var x: Vector3 = y.cross(Vector3.FORWARD).normalized()
			mi.transform = Transform3D(Basis(x, y, x.cross(y)).orthonormalized(), mi.position)
			(mi.mesh as CylinderMesh).height = p.distance_to(Vector3(0, 3.3, 0))
		_piece(c, _box(Vector3(0.5, 0.2, 0.5)), "fer", Vector3(0, 3.35, 0))
	else:
		# la poulie (sous le câble), sa chape et la poignée de bambou
		var pul := _cylm(0.12, 0.12, 0.06, 14)
		_piece(c, pul, "fer", Vector3(0, 0, 0), Vector3(0, 0, PI * 0.5))
		_piece(c, _box(Vector3(0.08, 0.5, 0.2)), "fer", Vector3(0, -0.3, 0))
		_piece(c, _cylm(0.02, 0.02, 0.9, 5), "corde", Vector3(0, -0.95, 0))
		_piece(c, _cylm(0.035, 0.035, 0.7, 8), "rouge", Vector3(0, -1.4, 0), Vector3(0, 0, PI * 0.5))
	return c


func _build_lift_frame() -> void:
	# deux mâts de bambou de part et d'autre, la grande roue en haut, le contrepoids
	var h: float = high.y - low.y + 4.5
	for sx in [-1.2, 1.2]:
		var mast := _cylm(0.11, 0.13, h, 8)
		var mi := _piece(self, mast, "bois", low + Vector3(sx, h * 0.5 - 0.2, 0))
		mi.name = "Mat"
	_wheel = Node3D.new()
	_wheel.position = high + Vector3.UP * 4.2
	add_child(_wheel)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.8
	rim.outer_radius = 0.92
	_piece(_wheel, rim, "bois", Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	for k in range(4):
		_piece(_wheel, _box(Vector3(0.08, 1.7, 0.08)), "bois", Vector3.ZERO, Vector3(0, 0, PI * 0.25 * k))
	_piece(self, _box(Vector3(2.8, 0.16, 0.3)), "bois", high + Vector3.UP * 4.2 + Vector3(0, 0, 0.3))


func _build_cable() -> void:
	for i in range(24):
		var a: Vector3 = cable_point(float(i) / 24.0)
		var b: Vector3 = cable_point(float(i + 1) / 24.0)
		var mi := MeshInstance3D.new()
		mi.mesh = _cylm(0.025, 0.025, a.distance_to(b), 4)
		mi.material_override = _mat("fer")
		var y: Vector3 = (b - a).normalized()
		var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
		mi.transform = Transform3D(Basis(x, y, x.cross(y)).orthonormalized(), (a + b) * 0.5)
		add_child(mi)
	# le poteau d'arrivée (le câble y est amarré), et sa botte de paille
	var post := _cylm(0.16, 0.2, 3.6, 8)
	_piece(self, post, "bois", low + Vector3(0, 1.6, 0) + (low - high) * Vector3(1, 0, 1) * 0.04)


## Tyrolienne : le point du câble à l'abscisse u (0 au départ, 1 à l'arrivée).
func cable_point(u: float) -> Vector3:
	var a: Vector3 = high + Vector3.UP * 2.3
	var b: Vector3 = low + Vector3.UP * 2.6
	return a.lerp(b, u) + Vector3.DOWN * sag * sin(u * PI)


## Le plancher de la nacelle (ascenseur), ou les pieds du joueur pendu (tyrolienne).
func car_floor() -> Vector3:
	if mode == "ascenseur":
		return low.lerp(high, s)
	return cable_point(s) + Vector3.DOWN * 2.2


func _apply() -> void:
	if mode == "ascenseur":
		car.global_position = car_floor()
		if _wheel != null:
			_wheel.rotation.z = s * 25.0
	else:
		car.global_position = cable_point(s)
		var d: Vector3 = (high - low) * Vector3(1, 0, 1)
		car.rotation.y = atan2(d.x, d.z)


func _physics_process(delta: float) -> void:
	if main == null:
		return
	if mode == "ascenseur":
		_tick_lift(delta)
	else:
		_tick_zip(delta)
	_apply()
	if riding:
		_carry()


func _tick_lift(delta: float) -> void:
	match state:
		"attente":
			timer -= delta
			if timer <= 0.0:
				state = "descend" if at_top else "monte"
				_play("ascenseur")
		"monte", "descend":
			var v: float = delta / LIFT_TRAVEL
			s = clampf(s + (v if state == "monte" else -v), 0.0, 1.0)
			if (state == "monte" and s >= 1.0) or (state == "descend" and s <= 0.0):
				at_top = state == "monte"
				state = "attente"
				timer = LIFT_WAIT
				if riding:
					_leave()


func _tick_zip(delta: float) -> void:
	match state:
		"pret":
			s = 0.0
		"depart":
			timer -= delta
			if timer <= 0.0:
				state = "glisse"
				_play("tyrolienne")
		"glisse":
			# ça accélère, puis le câble remonte un peu : on freine en arrivant
			var spd: float = lerpf(0.06, 0.24, smoothstep(0.0, 0.5, s)) * (1.0 - 0.6 * smoothstep(0.82, 1.0, s))
			s = minf(1.0, s + spd * delta * 6.5 / ZIP_TIME)
			if s >= 1.0:
				state = "retour"
				if riding:
					_leave()
		"retour":
			s = maxf(0.0, s - delta / ZIP_BACK)
			if s <= 0.0:
				state = "pret"


func _play(name: String) -> void:
	if main.get("sfx_v50") != null and main.sfx_v50 != null:
		main.sfx_v50.play(name, car.global_position)


## "bas", "haut" ou "" (en route). La tyrolienne n'est « haut » que quand la poulie attend.
func at_station() -> String:
	if mode == "ascenseur":
		if state != "attente":
			return ""
		return "haut" if at_top else "bas"
	return "haut" if state == "pret" else ""


func board() -> void:
	riding = true
	rides += 1
	if main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if mode == "ascenseur":
		main._show_message_v28("Dans la nacelle ! Départ dans %d s — %s." % [int(ceil(timer)), "vers le pied de l'arbre" if at_top else "vers la cime, la Poste des chouettes"])
	else:
		state = "depart"
		timer = 0.8
		main._show_message_v28("Accroché à la poignée… Attention au départ !")


func _leave() -> void:
	riding = false
	var top_exit: bool = (mode == "ascenseur" and at_top)
	var out: Vector3 = exit_high if top_exit else exit_low
	var from: Vector3 = car_floor()
	var away: Vector3 = (out - from) * Vector3(1, 0, 1)
	main.place_player_v35(out + Vector3.UP * 0.3, away.normalized() if away.length() > 0.1 else Vector3.FORWARD)
	if main.get("hero_v28") != null and not main.xr_active:
		main.hero_v28.leave_ride()
	main.last_ok_v29.clear()
	if mode == "ascenseur":
		main._show_message_v28("La cime du Chêne-Mère : la Poste des chouettes." if top_exit else "Le pied du Chêne-Mère.")
	else:
		main._show_message_v28("Youhouuu ! La Clairière des Jeux.")


func safe_pos() -> Vector3:
	return exit_low + Vector3.UP * 0.3


func _carry() -> void:
	var seat: Transform3D
	if mode == "ascenseur":
		seat = Transform3D(Basis(), car_floor() + Vector3(0, 0.2, 0))
	else:
		var d: Vector3 = (low - high) * Vector3(1, 0, 1)
		seat = Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), car_floor())
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

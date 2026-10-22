extends Node3D
## V61 : le Zéphyr, le dirigeable de ligne des ingénieurs de Cliquetis. Il fait le tour de la
## grande île sans s'arrêter de tourner : Cliquetis (au nord) -> Ramure (à l'est, V62) -> Tazira
## (au sud) -> Carène (à l'ouest) -> Cliquetis… À chaque escale, il descend se poser sur son aire, la nacelle au
## ras du sol, attend une quarantaine de secondes, puis remonte, passe au-dessus du
## Cœur-de-Pierre à 165 m et va se poser plus loin.
## On monte à bord à l'escale (E devant la porte de la nacelle) ; assis sur la banquette, on
## regarde l'île défiler ; à l'escale suivante, E pour descendre (ou on reste à bord).
## Le ballon : une enveloppe de toile sur une carcasse de laiton ; la nacelle de cuivre et de
## verre ; deux hélices ; des feux de position la nuit ; un panache de vapeur.

const LENGTH: float = 46.0
const RADIUS: float = 7.6
const GONDOLA_DROP: float = 11.2        # du centre de l'enveloppe au plancher de la nacelle
const CRUISE_Y: float = 168.0
const SPEED: float = 15.0
const CLIMB: float = 6.5
const WAIT: float = 40.0
const STOPS := [["cliquetis", "Cliquetis"], ["ramure", "Ramure"], ["tazira", "Tazira"], ["carene", "Carène"]]

var main: Node
var pads: Array = []                   # Vector3 : le sol de chaque aire (centre)
var stop_i: int = 0
var next_i: int = 1
var state: String = "quai"             # quai, monte, vol, descend
var timer: float = 0.0
var pos := Vector3.ZERO                # le centre de l'enveloppe
var heading: float = 0.0
var riding: bool = false
var docked: bool = true
var rig: Node3D
var _props: Array = []
var _lights: Array = []
var _steam: CPUParticles3D
var _hum: AudioStreamPlayer3D
var _clock: float = 0.0
var _seat_local := Vector3(-3.6, -GONDOLA_DROP + 0.55, 0.0)
var _door_local := Vector3(1.0, -GONDOLA_DROP, 2.3)
var _mats: Dictionary = {}
var height_fn: Callable                # le relief de l'île (x, z) -> y
var _leg_floor: PackedFloat32Array = PackedFloat32Array()   # l'altitude minimale, de 4 m en 4 m, en partant de l'arrivée
const LEG_STEP: float = 4.0
const CLEARANCE: float = 30.0          # sous la nacelle, au-dessus du relief


func setup(main_node: Node, pad_list: Array) -> void:
	main = main_node
	pads = pad_list
	_build()
	_dock(0)


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"toile":
			m.albedo_color = Color(0.88, 0.82, 0.7)
			m.roughness = 0.85
			m.albedo_texture = load("res://assets/textures/carene/voile.png") if ResourceLoader.exists("res://assets/textures/carene/voile.png") else null
			m.uv1_scale = Vector3(4, 2, 1)
		"cuivre":
			m.albedo_texture = load("res://assets/textures/cliquetis/cuivre.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/cliquetis/cuivre_n.png")
			m.metallic = 0.55
			m.roughness = 0.45
			m.uv1_scale = Vector3(0.6, 0.6, 1)
		"laiton":
			m.albedo_color = Color(0.82, 0.62, 0.3)
			m.metallic = 0.85
			m.roughness = 0.3
		"verre":
			m.albedo_color = Color(0.6, 0.75, 0.75, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"bois":
			m.albedo_texture = load("res://assets/textures/carene/pont.png")
			m.roughness = 0.8
		"rouge":
			m.albedo_color = Color(0.62, 0.12, 0.1)
			m.roughness = 0.7
		"noir":
			m.albedo_color = Color(0.08, 0.08, 0.09)
			m.metallic = 0.5
			m.roughness = 0.5
		"cuir":
			m.albedo_color = Color(0.45, 0.22, 0.12)
			m.roughness = 0.75
	_mats[key] = m
	return m


func _add(mesh: Mesh, key: String, xf: Transform3D, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(key)
	mi.transform = xf
	(parent if parent != null else rig).add_child(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r0: float, r1: float, h: float, seg: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r0
	c.height = h
	c.radial_segments = seg
	return c


## L'enveloppe : un fuseau (rayon en fonction de x), en anneaux, l'axe le long de X.
func _envelope() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 40
	var na: int = 28
	var prof := func(t: float) -> float:
		# t de 0 (poupe) à 1 (proue) : arrière effilé, avant arrondi
		var u: float = t * 2.0 - 1.0
		return RADIUS * sqrt(maxf(0.0, 1.0 - pow(absf(u), 2.4 if u > 0.0 else 1.7)))
	var pts: Array = []
	for i in range(nx + 1):
		var t: float = float(i) / nx
		var x: float = (t - 0.5) * LENGTH
		var r: float = prof.call(t)
		var ring: Array = []
		for j in range(na + 1):
			var a: float = TAU * j / na
			ring.append(Vector3(x, sin(a) * r, cos(a) * r))
		pts.append(ring)
	for i in range(nx):
		for j in range(na):
			var p0: Vector3 = pts[i][j]
			var p1: Vector3 = pts[i + 1][j]
			var p2: Vector3 = pts[i + 1][j + 1]
			var p3: Vector3 = pts[i][j + 1]
			var uv0 := Vector2(float(i) / nx, float(j) / na)
			var uv1 := Vector2(float(i + 1) / nx, float(j) / na)
			var uv2 := Vector2(float(i + 1) / nx, float(j + 1) / na)
			var uv3 := Vector2(float(i) / nx, float(j + 1) / na)
			for v in [[p0, uv0], [p2, uv2], [p1, uv1], [p0, uv0], [p3, uv3], [p2, uv2]]:
				st.set_uv(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	return st.commit()


func _build() -> void:
	rig = Node3D.new()
	rig.name = "Zephyr_rig"
	add_child(rig)
	var env := _add(_envelope(), "toile", Transform3D())
	env.name = "Enveloppe"
	# la carcasse : des cerceaux de laiton, une quille dessous
	for k in range(1, 9):
		var x: float = -LENGTH * 0.5 + LENGTH * k / 9.0
		var t: float = (x / LENGTH) + 0.5
		var u: float = t * 2.0 - 1.0
		var r: float = RADIUS * sqrt(maxf(0.0, 1.0 - pow(absf(u), 2.4 if u > 0.0 else 1.7))) + 0.06
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.07
		tm.outer_radius = r + 0.07
		tm.rings = 32
		tm.ring_segments = 6
		_add(tm, "laiton", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(x, 0, 0)))
	_add(_box(Vector3(LENGTH * 0.42, 0.35, 0.5)), "laiton", Transform3D(Basis(), Vector3(0, -RADIUS * 0.9, 0)))
	# les empennages
	for k2 in range(4):
		var a: float = PI * 0.5 * k2
		var fin := _add(_box(Vector3(7.0, 0.18, 4.6)), "rouge", Transform3D(Basis(Vector3(1, 0, 0), a), Vector3(-LENGTH * 0.5 + 4.5, 0, 0)) * Transform3D(Basis(), Vector3(0, 0, RADIUS * 0.55 + 1.6)))
		fin.name = "Empennage_%d" % k2
	# la nacelle
	var g := Node3D.new()
	g.name = "Nacelle"
	g.position = Vector3(0, -GONDOLA_DROP, 0)
	rig.add_child(g)
	_add(_box(Vector3(12.0, 0.3, 3.8)), "bois", Transform3D(Basis(), Vector3(0, 0.0, 0)), g)
	_add(_box(Vector3(12.4, 0.6, 4.0)), "cuivre", Transform3D(Basis(), Vector3(0, -0.4, 0)), g)
	_add(_cyl(0.0, 2.0, 3.0, 16), "cuivre", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(7.6, -0.3, 0)).scaled_local(Vector3(1, 1, 0.95)), g)
	for s in [-1.0, 1.0]:
		_add(_box(Vector3(12.0, 0.9, 0.12)), "cuivre", Transform3D(Basis(), Vector3(0, 0.6, s * 1.94)), g)
		_add(_box(Vector3(12.0, 1.2, 0.04)), "verre", Transform3D(Basis(), Vector3(0, 1.65, s * 1.94)), g)
		for k3 in range(7):
			_add(_box(Vector3(0.1, 1.3, 0.1)), "laiton", Transform3D(Basis(), Vector3(-6.0 + k3 * 2.0, 1.65, s * 1.94)), g)
	_add(_box(Vector3(12.4, 0.2, 4.2)), "cuivre", Transform3D(Basis(), Vector3(0, 2.35, 0)), g)
	_add(_box(Vector3(0.12, 2.3, 3.9)), "cuivre", Transform3D(Basis(), Vector3(-6.0, 1.15, 0)), g)
	_add(_box(Vector3(0.12, 2.3, 3.9)), "verre", Transform3D(Basis(), Vector3(6.0, 1.15, 0)), g)
	# la banquette des passagers, à l'arrière ; le pilote et sa barre à l'avant
	_add(_box(Vector3(1.0, 0.45, 3.2)), "cuir", Transform3D(Basis(), Vector3(-4.4, 0.4, 0)), g)
	_add(_box(Vector3(0.25, 0.9, 3.2)), "cuir", Transform3D(Basis(), Vector3(-4.95, 0.85, 0)), g)
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.38
	wheel.outer_radius = 0.45
	_add(wheel, "laiton", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(5.0, 1.3, 0)), g)
	var pilot := Node3D.new()
	pilot.position = Vector3(4.4, 0.15, 0)
	g.add_child(pilot)
	_add(_cyl(0.28, 0.24, 0.9), "rouge", Transform3D(Basis(), Vector3(0, 0.9, 0)), pilot)
	var head := SphereMesh.new()
	head.radius = 0.2
	head.height = 0.4
	_add(head, "cuir", Transform3D(Basis(), Vector3(0, 1.55, 0)), pilot)
	_add(_cyl(0.24, 0.22, 0.12), "noir", Transform3D(Basis(), Vector3(0, 1.72, 0)), pilot)
	# les suspentes, de la nacelle à la quille
	for sx in [-5.0, 0.0, 5.0]:
		for sz in [-1.8, 1.8]:
			var a: Vector3 = Vector3(sx, 2.4, sz)
			var b: Vector3 = Vector3(sx * 1.1, GONDOLA_DROP - RADIUS + 0.4, sz * 0.2)
			var mid: Vector3 = (a + b) * 0.5
			var len: float = a.distance_to(b)
			var dir: Vector3 = (b - a).normalized()
			var basis := Basis(dir.cross(Vector3.FORWARD).normalized(), dir, dir.cross(dir.cross(Vector3.FORWARD)).normalized())
			_add(_cyl(0.03, 0.03, len, 4), "noir", Transform3D(basis.orthonormalized(), mid), g)
	# les hélices
	for s2 in [-1.0, 1.0]:
		var hub := Node3D.new()
		hub.position = Vector3(-6.6, 1.2, s2 * 2.8)
		g.add_child(hub)
		_add(_cyl(0.32, 0.32, 1.6, 12), "cuivre", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.6, 0, 0)), hub)
		_add(_box(Vector3(0.6, 0.6, 0.5)), "noir", Transform3D(Basis(), Vector3(1.4, 0, -s2 * 0.6)), hub)
		var prop := Node3D.new()
		prop.position = Vector3(-0.3, 0, 0)
		hub.add_child(prop)
		for k4 in range(3):
			_add(_box(Vector3(0.08, 2.4, 0.32)), "bois", Transform3D(Basis(Vector3(1, 0, 0), TAU * k4 / 3.0), Vector3(0, 0, 0)) * Transform3D(Basis(), Vector3(0, 1.1, 0)), prop)
		_props.append(prop)
	# feux de position (vert à tribord, rouge à bâbord), un phare blanc
	for f in [[Vector3(0, 0, RADIUS + 0.1), Color(0.2, 1.0, 0.3)], [Vector3(0, 0, -RADIUS - 0.1), Color(1.0, 0.2, 0.15)], [Vector3(7.0, -GONDOLA_DROP - 0.6, 0), Color(1.0, 0.95, 0.85)]]:
		var l := OmniLight3D.new()
		l.light_color = f[1]
		l.omni_range = 9.0
		l.light_energy = 0.0
		l.position = f[0]
		rig.add_child(l)
		var bulb := SphereMesh.new()
		bulb.radius = 0.2
		bulb.height = 0.4
		var bm := StandardMaterial3D.new()
		bm.albedo_color = f[1]
		bm.emission_enabled = true
		bm.emission = f[1]
		bm.emission_energy_multiplier = 3.0
		var bmi := MeshInstance3D.new()
		bmi.mesh = bulb
		bmi.material_override = bm
		bmi.position = f[0]
		rig.add_child(bmi)
		_lights.append(l)
	# le panache de vapeur de la chaudière
	_steam = CPUParticles3D.new()
	_steam.amount = 20
	_steam.lifetime = 3.0
	_steam.direction = Vector3(-1, 0.6, 0)
	_steam.spread = 15.0
	_steam.initial_velocity_min = 1.5
	_steam.initial_velocity_max = 2.5
	_steam.gravity = Vector3(0, 0.4, 0)
	_steam.scale_amount_min = 0.8
	_steam.scale_amount_max = 2.2
	var qm := QuadMesh.new()
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.92, 0.92, 0.92, 0.3)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = gr
	sm.albedo_texture = tex
	qm.material = sm
	_steam.mesh = qm
	_steam.position = Vector3(-6.8, -GONDOLA_DROP + 2.6, 0)
	rig.add_child(_steam)
	_hum = AudioStreamPlayer3D.new()
	var hp := "res://assets/sons/sfx/moteur_bateau_1.ogg"
	if ResourceLoader.exists(hp):
		var s: AudioStream = load(hp)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_hum.stream = s
	_hum.unit_size = 12.0
	_hum.max_distance = 140.0
	_hum.pitch_scale = 0.7
	_hum.volume_db = -8.0
	_hum.position = Vector3(-6.0, -GONDOLA_DROP + 1.0, 0)
	rig.add_child(_hum)


# =================================================================== la ligne

func dock_y(i: int) -> float:
	return (pads[i] as Vector3).y + GONDOLA_DROP + 0.45


func _dock(i: int) -> void:
	stop_i = i
	next_i = (i + 1) % pads.size()
	var p: Vector3 = pads[i]
	pos = Vector3(p.x, dock_y(i), p.z)
	var nxt: Vector3 = pads[next_i]
	heading = atan2(-(nxt.z - p.z), nxt.x - p.x)
	state = "quai"
	docked = true
	timer = WAIT
	_apply()


func stop_name(i: int) -> String:
	return str(STOPS[i][1])


func at_stop() -> String:
	return str(STOPS[stop_i][0]) if docked else ""


func _physics_process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	match state:
		"quai":
			timer -= delta
			if timer <= 0.0:
				state = "monte"
				docked = false
				_plan_leg()
				if _hum.stream != null:
					_hum.play()
				if riding:
					main._show_message_v28("Le Zéphyr largue les amarres : prochaine escale, %s." % stop_name(next_i))
		"monte", "vol", "descend":
			var tgt: Vector3 = pads[next_i]
			var to := Vector2(tgt.x - pos.x, tgt.z - pos.z)
			var dist: float = to.length()
			var src: Vector3 = pads[stop_i]
			var want_y: float = CRUISE_Y
			var desc_len: float = (CRUISE_Y - dock_y(next_i)) / CLIMB * SPEED * 0.8
			if dist < desc_len:
				want_y = lerpf(dock_y(next_i), CRUISE_Y, smoothstep(0.0, desc_len, dist))
			if dist < 0.6:
				want_y = dock_y(next_i)
			var floor_y: float = 0.0
			if not _leg_floor.is_empty():
				floor_y = _leg_floor[clampi(int(dist / LEG_STEP), 0, _leg_floor.size() - 1)]
			if dist >= 0.6:
				want_y = maxf(want_y, floor_y)
			pos.y = move_toward(pos.y, want_y, CLIMB * delta)
			# on ne quitte l'aire qu'une fois assez haut pour passer la première crête
			var can_move: bool = (pos.y > src.y + GONDOLA_DROP + 18.0 and pos.y > floor_y - 6.0) or Vector2(pos.x - src.x, pos.z - src.z).length() > 30.0
			if can_move and dist > 0.05:
				var spd: float = SPEED * clampf(dist / 25.0, 0.15, 1.0)
				var step: float = minf(spd * delta, dist)
				pos.x += to.x / dist * step
				pos.z += to.y / dist * step
				if dist > 8.0:
					var want_h: float = atan2(-to.y, to.x)
					heading = rotate_toward(heading, want_h, delta * 0.35)
			if dist < 0.06 and absf(pos.y - dock_y(next_i)) < 0.05:
				_arrive()
	_apply()


## Le plancher du trajet : le relief sous la route (et un peu de part et d'autre), plus la
## marge sous la nacelle ; on le propage vers le départ pour que le Zéphyr ait le temps de
## monter (il grimpe moins vite qu'il n'avance). Les deux aires (35 m autour) sont exclues.
func _plan_leg() -> void:
	_leg_floor = PackedFloat32Array()
	if not height_fn.is_valid():
		return
	var a: Vector3 = pads[stop_i]
	var b: Vector3 = pads[next_i]
	var flat := Vector2(b.x - a.x, b.z - a.z)
	var total: float = flat.length()
	if total < 1.0:
		return
	var dir: Vector2 = flat / total
	var side := Vector2(-dir.y, dir.x)
	var n: int = int(total / LEG_STEP) + 2
	_leg_floor.resize(n)
	for k in n:
		var d: float = k * LEG_STEP           # distance restante jusqu'à l'arrivée
		var p := Vector2(b.x, b.z) - dir * d
		var need: float = 0.0
		if d > 35.0 and total - d > 35.0:
			for off in [-10.0, 0.0, 10.0]:
				var q: Vector2 = p + side * off
				need = maxf(need, float(height_fn.call(q.x, q.y)) + GONDOLA_DROP + CLEARANCE)
		_leg_floor[k] = need
	var slope: float = CLIMB / SPEED * 0.7
	# le Zéphyr part de l'indice n-1 et va vers 0 : il doit être assez haut AVANT chaque bosse
	var acc: float = 0.0
	for k in range(0, n):
		acc = maxf(_leg_floor[k], acc - slope * LEG_STEP)
		_leg_floor[k] = acc


func _arrive() -> void:
	_dock(next_i)
	_hum.stop()
	if riding:
		main._show_message_v28("Escale : %s. E pour descendre — ou restez à bord jusqu'à %s." % [stop_name(stop_i), stop_name(next_i)])


func _apply() -> void:
	var bob: float = sin(_clock * 0.5) * (0.15 if not docked else 0.05)
	var roll: float = sin(_clock * 0.37) * (0.02 if not docked else 0.0)
	rig.global_transform = Transform3D(Basis(Vector3.UP, heading) * Basis(Vector3(1, 0, 0), roll), pos + Vector3.UP * bob)
	for p in _props:
		(p as Node3D).rotation.x += (0.6 if docked else 14.0) * get_physics_process_delta_time()
	_steam.emitting = not docked or fmod(_clock, 8.0) < 2.0
	var night: bool = main.get("temps_v56") != null and main.temps_v56 != null and bool(main.temps_v56.lamps_on)
	for l in _lights:
		(l as OmniLight3D).light_energy = 1.5 if night else 0.0
	if riding:
		_carry_player()


# =================================================================== les passagers

func door_pos() -> Vector3:
	return rig.global_transform * (_door_local + Vector3(0, 0.0, 0.9))


func can_board(p: Vector3) -> bool:
	return docked and not riding and p.distance_to(door_pos()) < 3.2


func board() -> void:
	riding = true
	if main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if main.get("hero_v28") != null and not main.xr_active:
		main.hero_v28.cam_distance = maxf(main.hero_v28.cam_distance, 3.5)
	main._show_message_v28("À bord du Zéphyr ! Prochaine escale : %s (le dirigeable part dans %d s)." % [stop_name(next_i), int(ceil(timer))])
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("vapeur")


func leave() -> void:
	if not riding:
		return
	riding = false
	var spot: Vector3 = door_pos() + (rig.global_transform.basis * Vector3(0, 0, 1.6))
	spot.y = (pads[stop_i] as Vector3).y + 0.3
	main.place_player_v35(spot, rig.global_transform.basis * Vector3(0, 0, 1))
	if main.get("hero_v28") != null and not main.xr_active:
		main.hero_v28.leave_ride()
		main.hero_v28.cam_distance = 1.0
	main.last_ok_v29.clear()
	main._show_message_v28("Bienvenue à %s !" % stop_name(stop_i))


## Où l'on reprendra la partie si on la sauvegarde en plein vol : à la dernière escale.
func safe_pos() -> Vector3:
	var p: Vector3 = pads[stop_i]
	return p + Vector3(0, 0.4, 6.0)


func _carry_player() -> void:
	var seat: Transform3D = rig.global_transform * Transform3D(Basis(Vector3.UP, -PI * 0.5), _seat_local)
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


func serialize() -> Dictionary:
	return {"escale": stop_i, "escale_nom": str(STOPS[stop_i][0])}


func load_data(d: Dictionary) -> void:
	riding = false
	var i: int = int(d.get("escale", 0))
	if d.has("escale_nom"):
		for k in range(STOPS.size()):
			if str(STOPS[k][0]) == str(d["escale_nom"]):
				i = k
	elif i >= 1 and STOPS.size() == 4:
		i += 1      # une partie d'avant la V62 : Cliquetis, Tazira, Carène
	_dock(clampi(i, 0, pads.size() - 1))

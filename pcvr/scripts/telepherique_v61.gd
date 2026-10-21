extends Node3D
## V61 : le téléphérique de Cliquetis, du port (au pied des falaises) à la cité (en haut).
## Deux cabines de cuivre et de verre, en va-et-vient sur le câble : quand l'une monte,
## l'autre descend. Elles attendent en gare une douzaine de secondes, portes ouvertes.
## On monte (E devant la cabine) ; à l'arrivée, on descend tout seul sur le quai de la gare.

const TRAVEL: float = 34.0
const WAIT: float = 12.0
const HANG: float = 3.4                 # du câble au plancher de la cabine

var main: Node
var bottom := Vector3.ZERO              # le quai de la gare du bas (plancher de la cabine)
var top := Vector3.ZERO
var cabins: Array = []                  # {node, s (0 bas, 1 haut), dir}
var phase: float = 0.0                  # 0..2*(WAIT+TRAVEL) : le cycle
var riding: int = -1                    # la cabine où est le joueur (-1 : aucune)
var _wheels: Array = []
var _hum: AudioStreamPlayer3D
var _mats: Dictionary = {}


func setup(main_node: Node, low: Vector3, high: Vector3) -> void:
	main = main_node
	bottom = low
	top = high
	for k in range(2):
		var c := _cabin(k)
		add_child(c)
		cabins.append({"node": c, "s": float(k)})
	for p in [bottom, top]:
		var w := Node3D.new()
		w.position = p + Vector3.UP * (HANG + 0.4)
		add_child(w)
		var tm := TorusMesh.new()
		tm.inner_radius = 1.5
		tm.outer_radius = 1.7
		var mi := MeshInstance3D.new()
		mi.mesh = tm
		mi.material_override = _mat("laiton")
		mi.rotation.x = PI * 0.5
		w.add_child(mi)
		for k2 in range(4):
			var sp := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.08, 3.2, 0.08)
			sp.mesh = bm
			sp.material_override = _mat("fer")
			sp.rotation.z = PI * 0.25 * k2
			w.add_child(sp)
		_wheels.append(w)
	_cables()
	_hum = AudioStreamPlayer3D.new()
	var hp := "res://assets/sons/sfx/moteur_bateau_1.ogg"
	if ResourceLoader.exists(hp):
		_hum.stream = load(hp)
	_hum.pitch_scale = 1.6
	_hum.volume_db = -14.0
	_hum.unit_size = 6.0
	_hum.max_distance = 50.0
	_hum.position = top + Vector3.UP * 4.0
	add_child(_hum)
	_apply()


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"cuivre":
			m.albedo_texture = load("res://assets/textures/cliquetis/cuivre.png")
			m.metallic = 0.55
			m.roughness = 0.45
		"laiton":
			m.albedo_color = Color(0.82, 0.62, 0.3)
			m.metallic = 0.85
			m.roughness = 0.3
		"verre":
			m.albedo_color = Color(0.6, 0.76, 0.76, 0.3)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"fer":
			m.albedo_color = Color(0.09, 0.09, 0.1)
			m.metallic = 0.6
			m.roughness = 0.5
		"rouge":
			m.albedo_color = Color(0.6, 0.12, 0.1)
		"bois":
			m.albedo_texture = load("res://assets/textures/carene/pont.png")
	_mats[key] = m
	return m


func _piece(parent: Node3D, size: Vector3, key: String, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(key)
	mi.position = at
	parent.add_child(mi)


func _cabin(k: int) -> Node3D:
	var c := Node3D.new()
	c.name = "Cabine_%d" % k
	_piece(c, Vector3(2.6, 0.2, 2.0), "bois", Vector3(0, 0.1, 0))
	_piece(c, Vector3(2.8, 0.5, 2.2), "cuivre" if k == 0 else "rouge", Vector3(0, -0.15, 0))
	for s in [-1.0, 1.0]:
		_piece(c, Vector3(2.8, 0.8, 0.08), "cuivre", Vector3(0, 0.6, s * 1.06))
		_piece(c, Vector3(2.8, 1.0, 0.04), "verre", Vector3(0, 1.5, s * 1.06))
		_piece(c, Vector3(0.08, 2.0, 2.2), "cuivre", Vector3(s * 1.36, 1.1, 0))
	_piece(c, Vector3(3.0, 0.25, 2.4), "cuivre", Vector3(0, 2.15, 0))
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.2
	sm.height = 1.0
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.material_override = _mat("cuivre")
	dome.position = Vector3(0, 2.25, 0)
	c.add_child(dome)
	_piece(c, Vector3(0.12, HANG - 2.6, 0.12), "fer", Vector3(0, 2.6 + (HANG - 2.6) * 0.5, 0))
	_piece(c, Vector3(1.2, 0.3, 0.4), "fer", Vector3(0, HANG, 0))
	var bench := Vector3(0, 0.45, 0)
	_piece(c, Vector3(2.2, 0.4, 0.5), "bois", bench + Vector3(0, -0.1, 0.65))
	return c


func _cables() -> void:
	for side in [-0.35, 0.35]:
		var pts: Array = []
		for i in range(25):
			pts.append(_cable_point(float(i) / 24.0) + Vector3(side, 0, 0) * 0.0 + _side() * side)
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.035
			cm.bottom_radius = 0.035
			cm.height = a.distance_to(b)
			cm.radial_segments = 4
			mi.mesh = cm
			mi.material_override = _mat("fer")
			var y: Vector3 = (b - a).normalized()
			var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
			mi.transform = Transform3D(Basis(x, y, x.cross(y)).orthonormalized(), (a + b) * 0.5)
			add_child(mi)


func _side() -> Vector3:
	var d: Vector3 = top - bottom
	d.y = 0.0
	return d.normalized().cross(Vector3.UP).normalized()


## Le point du câble à l'abscisse s (avec le ventre du câble au milieu).
func _cable_point(s: float) -> Vector3:
	var p: Vector3 = bottom.lerp(top, s) + Vector3.UP * (HANG + 0.4)
	p.y -= sin(s * PI) * 2.2
	return p


func cabin_floor(k: int) -> Vector3:
	return _cable_point(float(cabins[k]["s"])) - Vector3.UP * (HANG + 0.4)


func _physics_process(delta: float) -> void:
	if main == null:
		return
	var cycle: float = 2.0 * (WAIT + TRAVEL)
	var was: Array = [at_station(0), at_station(1)]
	phase = fmod(phase + delta, cycle)
	_apply()
	for w in _wheels:
		(w as Node3D).rotation.z += delta * (2.0 if moving() else 0.0)
	if moving() and not _hum.playing and _hum.stream != null:
		_hum.play()
	elif not moving() and _hum.playing:
		_hum.stop()
	if riding >= 0:
		_carry(riding)
		if at_station(riding) != "" and was[riding] == "":
			_leave()


func moving() -> bool:
	var t: float = fmod(phase, WAIT + TRAVEL)
	return t >= WAIT


func _apply() -> void:
	var half: float = WAIT + TRAVEL
	var t: float = fmod(phase, half)
	var u: float = 0.0 if t < WAIT else smoothstep(0.0, 1.0, (t - WAIT) / TRAVEL)
	var up: bool = phase < half
	var s0: float = u if up else 1.0 - u
	cabins[0]["s"] = s0
	cabins[1]["s"] = 1.0 - s0
	var d: Vector3 = top - bottom
	var yaw: float = atan2(d.x, d.z)
	for k in range(2):
		var n: Node3D = cabins[k]["node"]
		var sway: float = sin(phase * 1.3 + k) * (0.03 if moving() else 0.0)
		n.global_transform = Transform3D(Basis(Vector3.UP, yaw + PI * 0.5) * Basis(Vector3(1, 0, 0), sway), cabin_floor(k))


## "bas", "haut" ou "" (en route).
func at_station(k: int) -> String:
	if moving():
		return ""
	var s: float = float(cabins[k]["s"])
	return "bas" if s < 0.01 else ("haut" if s > 0.99 else "")


func near_cabin(p: Vector3) -> int:
	for k in range(2):
		if at_station(k) != "" and p.distance_to(cabin_floor(k)) < 3.4:
			return k
	return -1


func board(k: int) -> void:
	riding = k
	if main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	var t: float = fmod(phase, WAIT + TRAVEL)
	main._show_message_v28("En cabine ! Départ dans %d s — %s." % [int(ceil(WAIT - t)), "vers la cité" if at_station(k) == "bas" else "vers le port"])


func _leave() -> void:
	var k: int = riding
	riding = -1
	var st: String = at_station(k)
	var out: Vector3 = (top if st == "haut" else bottom)
	var away: Vector3 = (top - bottom) * Vector3(1, 0, 1)
	away = away.normalized() * (3.2 if st == "haut" else -3.2)
	main.place_player_v35(out + away + Vector3.UP * 0.3, away.normalized())
	if main.get("hero_v28") != null and not main.xr_active:
		main.hero_v28.leave_ride()
	main.last_ok_v29.clear()
	main._show_message_v28("Terminus : %s." % ("Cliquetis, la cité" if st == "haut" else "le port de Cliquetis"))


func safe_pos() -> Vector3:
	return bottom + Vector3(0, 0.3, -3.0)


func _carry(k: int) -> void:
	var n: Node3D = cabins[k]["node"]
	var seat: Transform3D = n.global_transform * Transform3D(Basis(), Vector3(0, 0.5, 0.55))
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

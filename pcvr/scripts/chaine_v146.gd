extends Node3D
## V146 : la Grande Chaîne de l'Île Perchée. Du Ponton de la Chaîne (sur la mer, sous le bord sud-est
## de l'île) jusqu'à la Potence (une poutre de fer qui dépasse du bord, 270 m plus haut), deux chaînes
## énormes aux maillons gros comme des tonneaux ; à chacune, une cage de fer et de laiton. Quand l'une
## monte, l'autre descend (elles se font contrepoids). Elles attendent une dizaine de secondes, la grille
## ouverte. On monte (E devant la cage) ; à l'arrivée, on descend tout seul sur le quai.
## Là-haut, le treuil : deux grandes roues dentées qui tournent quand les cages bougent, et qui
## crachent de la vapeur.

const Kit = preload("res://scripts/perchee_kit_v146.gd")
const TRAVEL: float = 30.0
const WAIT: float = 11.0
const PAS: float = 0.86                  # le pas des maillons
const ECART: float = 2.7                 # chaque cage, de part et d'autre de l'axe

var main: Node
var bas := Vector3.ZERO                  # le plancher d'une cage en bas (sur l'axe)
var haut := Vector3.ZERO                 # le plancher d'une cage en haut (sur l'axe)
var dehors := Vector3.ZERO               # la direction vers le large (horizontale)
var cages: Array = []                    # {node, s (0 bas, 1 haut)}
var phase: float = 0.0
var riding: int = -1
var trajets: int = 0
var _chains: Array = []                  # les nœuds des chaînes (on les fait glisser)
var _roues: Array = []
var _vapeur: CPUParticles3D
var _hum: AudioStreamPlayer3D
var _side := Vector3.RIGHT


func setup(main_node: Node, low: Vector3, high: Vector3, out_dir: Vector3) -> void:
	main = main_node
	bas = low
	haut = high
	dehors = Vector3(out_dir.x, 0, out_dir.z).normalized()
	_side = dehors.cross(Vector3.UP).normalized()
	for k in range(2):
		var c := _cage(k)
		add_child(c)
		cages.append({"node": c, "s": float(k)})
	_chaines()
	_treuil()
	_hum = AudioStreamPlayer3D.new()
	var hp := "res://assets/sons/sfx/moteur_bateau_1.ogg"
	if ResourceLoader.exists(hp):
		_hum.stream = load(hp)
	_hum.pitch_scale = 0.7
	_hum.volume_db = -10.0
	_hum.unit_size = 8.0
	_hum.max_distance = 70.0
	add_child(_hum)
	_hum.global_position = haut + Vector3.UP * 6.0
	_apply()


func axe(k: int) -> Vector3:
	return _side * (ECART if k == 0 else -ECART)


func _cage(k: int) -> Node3D:
	var c := Node3D.new()
	c.name = "Cage_%d" % k
	var b := Kit.Lot.new()
	# le plancher de tôle rivetée, les montants, le toit en dôme de laiton
	b.box("rivets", Transform3D(Basis(), Vector3(0, -0.1, 0)), Vector3(2.6, 0.2, 2.6))
	b.box("fer", Transform3D(Basis(), Vector3(0, -0.32, 0)), Vector3(2.2, 0.3, 2.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box("fer", Transform3D(Basis(), Vector3(sx * 1.25, 1.25, sz * 1.25)), Vector3(0.12, 2.5, 0.12))
	for y in [0.05, 1.0, 2.5]:
		for s in [-1.0, 1.0]:
			b.box("laiton" if y > 2.0 else "fer", Transform3D(Basis(), Vector3(0, y, s * 1.25)), Vector3(2.6, 0.08, 0.08))
			b.box("laiton" if y > 2.0 else "fer", Transform3D(Basis(), Vector3(s * 1.25, y, 0)), Vector3(0.08, 0.08, 2.6))
	# les barreaux (trois côtés ; la grille est du côté de l'île : -X local)
	for k2 in range(9):
		var t: float = -1.15 + k2 * 0.2875
		b.box("fer", Transform3D(Basis(), Vector3(t, 1.25, 1.25)), Vector3(0.035, 2.4, 0.035))
		b.box("fer", Transform3D(Basis(), Vector3(t, 1.25, -1.25)), Vector3(0.035, 2.4, 0.035))
		b.box("fer", Transform3D(Basis(), Vector3(1.25, 1.25, t)), Vector3(0.035, 2.4, 0.035))
	b.cyl("laiton", Transform3D(Basis(), Vector3(0, 2.55, 0)), 1.7, 0.4, 0.8, 16)
	b.cyl("fer", Transform3D(Basis(), Vector3(0, 3.3, 0)), 0.3, 0.3, 0.6, 10)
	# la banquette, la lanterne, la plaque
	b.box("planches", Transform3D(Basis(), Vector3(0.7, 0.45, 0)), Vector3(0.5, 0.1, 2.0))
	b.box("fer", Transform3D(Basis(), Vector3(0.7, 0.22, 0)), Vector3(0.4, 0.44, 1.8))
	b.cyl("lampe", Transform3D(Basis(), Vector3(0, 2.25, 0)), 0.14, 0.16, 0.3, 8)
	b.commit(c, "Cage_maillage", true, 900.0)
	return c


## Les chaînes : des maillons (deux MultiMesh croisés par chaîne), du ponton à la potence.
func _chaines() -> void:
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.3
	tm.rings = 10
	tm.ring_segments = 6
	var m: Material = Kit.mat("fer_rouille")
	var hauteur: float = haut.y - bas.y + 8.0
	var n: int = int(hauteur / PAS) + 4
	for k in range(2):
		var holder := Node3D.new()
		holder.name = "Chaine_%d" % k
		add_child(holder)
		holder.global_position = Vector3(bas.x, bas.y - 2.0, bas.z) + axe(k)
		for parity in range(2):
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = tm
			var count: int = (n + 1 - parity) / 2
			mm.instance_count = count
			for i in range(count):
				var j: int = i * 2 + parity
				var bs := Basis(Vector3.BACK, PI * 0.5).scaled(Vector3(1.6, 1.0, 1.0))
				if parity == 1:
					bs = Basis(Vector3.UP, PI * 0.5) * bs
				mm.set_instance_transform(i, Transform3D(bs, Vector3(0, j * PAS, 0)))
			var mi := MultiMeshInstance3D.new()
			mi.multimesh = mm
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 1200.0
			holder.add_child(mi)
		_chains.append(holder)


## Le treuil, en haut : deux roues dentées de laiton sous un toit de tôle, sur la potence.
func _treuil() -> void:
	for k in range(2):
		var at: Vector3 = haut + axe(k) + Vector3.UP * 5.6
		var bs := Basis.looking_at(_side, Vector3.UP)
		var r := Kit.rouage(self, Transform3D(bs, at), 1.6, 16, 0.4, 0.0)
		_roues.append(r)
	_vapeur = CPUParticles3D.new()
	_vapeur.amount = 18
	_vapeur.lifetime = 2.6
	_vapeur.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_vapeur.emission_sphere_radius = 0.4
	_vapeur.direction = Vector3.UP
	_vapeur.spread = 18.0
	_vapeur.initial_velocity_min = 2.0
	_vapeur.initial_velocity_max = 3.5
	_vapeur.gravity = Vector3(0.3, 0.6, 0)
	_vapeur.scale_amount_min = 1.0
	_vapeur.scale_amount_max = 2.2
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(1, 1, 1, 0.35)
	if ResourceLoader.exists("res://assets/textures/ciel/nuage.png"):
		sm.albedo_texture = load("res://assets/textures/ciel/nuage.png")
	q.material = sm
	_vapeur.mesh = q
	_vapeur.emitting = false
	add_child(_vapeur)
	_vapeur.global_position = haut - dehors * 6.0 + Vector3.UP * 9.0


func cage_floor(k: int) -> Vector3:
	var s: float = float(cages[k]["s"])
	return bas.lerp(haut, s) + axe(k)


func _physics_process(delta: float) -> void:
	if main == null:
		return
	var cycle: float = 2.0 * (WAIT + TRAVEL)
	var was: Array = [at_station(0), at_station(1)]
	phase = fmod(phase + delta, cycle)
	_apply()
	var mv: bool = moving()
	var v: float = (haut.y - bas.y) / TRAVEL * 1.5
	for r in _roues:
		(r as Node3D).rotate_object_local(Vector3.BACK, delta * (v / 1.6 if mv else 0.0) * (1.0 if phase < WAIT + TRAVEL else -1.0))
	_vapeur.emitting = mv
	if mv and not _hum.playing and _hum.stream != null:
		_hum.play()
	elif not mv and _hum.playing:
		_hum.stop()
	if riding >= 0:
		_carry(riding)
		if at_station(riding) != "" and was[riding] == "":
			_leave()


func moving() -> bool:
	return fmod(phase, WAIT + TRAVEL) >= WAIT


func _apply() -> void:
	var half: float = WAIT + TRAVEL
	var t: float = fmod(phase, half)
	var u: float = 0.0 if t < WAIT else smoothstep(0.0, 1.0, (t - WAIT) / TRAVEL)
	var up: bool = phase < half
	var s0: float = u if up else 1.0 - u
	cages[0]["s"] = s0
	cages[1]["s"] = 1.0 - s0
	var yaw: float = atan2(dehors.x, dehors.z)
	for k in range(2):
		var n: Node3D = cages[k]["node"]
		var sway: float = sin(phase * 0.9 + k * 1.7) * (0.012 if moving() else 0.0)
		n.global_transform = Transform3D(Basis(Vector3.UP, yaw - PI * 0.5) * Basis(Vector3.BACK, sway), cage_floor(k))
		# la chaîne glisse avec la cage (le maillon d'en face reste à sa place)
		var ch: Node3D = _chains[k]
		var dy: float = fmod((haut.y - bas.y) * float(cages[k]["s"]), PAS)
		ch.global_position = Vector3(bas.x, bas.y - 2.0 + dy, bas.z) + axe(k)


## « bas », « haut » ou « » (en route).
func at_station(k: int) -> String:
	if moving():
		return ""
	var s: float = float(cages[k]["s"])
	return "bas" if s < 0.01 else ("haut" if s > 0.99 else "")


func near_cage(p: Vector3) -> int:
	for k in range(2):
		if at_station(k) != "" and p.distance_to(cage_floor(k)) < 3.4:
			return k
	return -1


func board(k: int) -> void:
	riding = k
	trajets += 1
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	var t: float = fmod(phase, WAIT + TRAVEL)
	var vers: String = "vers Pile-ou-Face, là-haut" if at_station(k) == "bas" else "vers le Ponton de la Chaîne, sur la mer"
	main._show_message_v28("Dans la cage de la Grande Chaîne ! Départ dans %d s — %s. Tenez-vous aux barreaux." % [int(ceil(maxf(WAIT - t, 0.0))), vers])
	if main.has_method("sfx"):
		main.sfx("cloche_chaine", cage_floor(k) + Vector3.UP * 2.0)


func _leave() -> void:
	var k: int = riding
	riding = -1
	var st: String = at_station(k)
	var out: Vector3
	var face: Vector3
	if st == "haut":
		out = cage_floor(k) - dehors * 3.4 + Vector3.UP * 0.3
		face = -dehors
	else:
		out = cage_floor(k) - dehors * 3.4 + Vector3.UP * 0.3
		face = -dehors
	main.place_player_v35(out, face)
	if main.get("hero_v28") != null and main.hero_v28 != null and not main.xr_active:
		main.hero_v28.leave_ride()
	if main.get("last_ok_v29") != null:
		main.last_ok_v29.clear()
	main._show_message_v28("Terminus : %s." % ("Pile-ou-Face, l'Île Perchée" if st == "haut" else "le Ponton de la Chaîne"))


func safe_pos() -> Vector3:
	return bas - dehors * 3.4 + Vector3.UP * 0.4


func _carry(k: int) -> void:
	var n: Node3D = cages[k]["node"]
	var seat: Transform3D = n.global_transform * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.7, 0.5, 0))
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
		if main.get("hero_v28") != null and main.hero_v28 != null:
			main.hero_v28.ride(seat)

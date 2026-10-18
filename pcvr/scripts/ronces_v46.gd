extends Node3D
## V46 : le Trône des Ronces — la fin du Royaume des Racines.
## Derrière le mur de ronces fané par la poussière de fée : un couloir, puis une grande salle
## envahie de ronces noires, de roses mortes et d'un trône d'épines. La Reine des Ronces
## (reine_v46.gd) s'y éveille. Des ronces repoussent derrière le joueur pendant le combat.
## En phase 3, elle s'entoure d'un bouclier d'épines : il faut réveiller les trois roses de
## lumière (E) pour le briser.
## Vaincue, la Reine redevient Églantine, la Reine des Fées : les roses refleurissent, la
## lumière revient, et elle confie la carte des Récifs de Feu (l'île des nains).

const ReineScript = preload("res://scripts/reine_v46.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const C := Vector3(-3.5, 0.0, -88.0)
const X0: float = -17.0
const X1: float = 10.0
const Z0: float = -102.0
const Z1: float = -74.0
const ROSE_ANGLES := [0.35, 2.45, 4.55]

var f: Node3D
var main: Node
var d: Node
var s: Node3D
var boss: Node3D
var fight: bool = false
var center_w: Vector3
var roses_active: bool = false
var _roses: Array = []                 # {root, petals, mat, light, lit, pos}
var _gate: Node3D
var _gate_cs: CollisionShape3D
var _dead_petals: Array = []           # matériaux des roses mortes (refleurissent)
var _light_red: Array = []
var _light_gold: Array = []
var _eglantine: Node3D
var _bar_vr: Label3D
var _thorn_mat: StandardMaterial3D
var _clock: float = 0.0
var _session: int = 0                  # V48 : change à chaque chargement (annule les suites de combat en cours)


func setup(feerique: Node3D) -> void:
	f = feerique
	main = f.main
	d = f.d
	s = f.s


func say(text: String, seconds: float = 4.0) -> void:
	d._say(text, seconds)


# =================================================================== construction

func build() -> void:
	center_w = s.to_global(C)
	f._room(X0, X1, Z0, Z1, 16.0, [["s", 0.0, 3.2, 4.2]])
	_thorn_mat = StandardMaterial3D.new()
	_thorn_mat.albedo_color = Color(0.16, 0.08, 0.13)
	_thorn_mat.roughness = 0.45
	_thorn_mat.metallic = 0.1
	_thorn_mat.normal_enabled = true
	_thorn_mat.normal_texture = load("res://assets/textures/flora/bark_n.png")
	_thorn_mat.normal_scale = 1.2
	_thorn_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_thorn_mat.vertex_color_use_as_albedo = true
	# Ronces noires sur les murs et au sol
	var rng := RandomNumberGenerator.new()
	rng.seed = 4600
	var curves: Array = []
	var spikes: Array = []
	for k in range(46):
		var side: int = k % 4
		var a: Vector3
		var b: Vector3
		var inward := Vector3.ZERO
		match side:
			0:
				a = Vector3(rng.randf_range(X0, X1), 0, Z0 + 0.6)
				b = a + Vector3(rng.randf_range(-8, 8), rng.randf_range(5, 14), 0.3)
				inward = Vector3(0, 0, 1)
			1:
				a = Vector3(X0 + 0.6, 0, rng.randf_range(Z0, Z1))
				b = a + Vector3(0.3, rng.randf_range(5, 14), rng.randf_range(-8, 8))
				inward = Vector3(1, 0, 0)
			2:
				a = Vector3(X1 - 0.6, 0, rng.randf_range(Z0, Z1))
				b = a + Vector3(-0.3, rng.randf_range(5, 14), rng.randf_range(-8, 8))
				inward = Vector3(-1, 0, 0)
			_:
				var ang: float = rng.randf() * TAU
				a = C + Vector3(cos(ang), 0, sin(ang)) * rng.randf_range(11.0, 13.0)
				b = C + Vector3(cos(ang + 0.6), 0, sin(ang + 0.6)) * rng.randf_range(11.5, 13.5)
		b.x = clampf(b.x, X0 + 0.5, X1 - 0.5)
		b.z = clampf(b.z, Z0 + 0.5, Z1 - 0.5)
		var bulge := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(0.5, 2.5), rng.randf_range(-3.0, 3.0)) + inward * rng.randf_range(1.0, 3.5)
		# Deux arcs enchaînés : la ronce ondule en S
		var mid: Vector3 = (a + b) * 0.5 + bulge
		var wob := Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(-0.6, 0.6), rng.randf_range(-1.6, 1.6))
		var c1: Vector3 = a.lerp(mid, 0.5) + wob
		var c2: Vector3 = mid.lerp(b, 0.5) - wob * 0.8
		var r0: float = rng.randf_range(0.08, 0.2)
		var rm: float = r0 * 0.7
		for arc in [[a, c1, mid, r0, rm], [mid, c2, b, rm, r0 * 0.35]]:
			var pa: Vector3 = arc[0]
			var pc: Vector3 = arc[1]
			var pb: Vector3 = arc[2]
			curves.append([pa, pc, pb, float(arc[3]), float(arc[4]), 8])
			for jj in range(1, 6):
				var t: float = jj / 6.0
				var q: Vector3 = pa.lerp(pc, t).lerp(pc.lerp(pb, t), t)
				spikes.append([q, rng.randf() * TAU, rng.randf_range(0.6, 1.6), lerpf(float(arc[3]), float(arc[4]), t)])
	var vines := MeshInstance3D.new()
	vines.name = "Ronces_noires"
	vines.mesh = f.gfx.roots_mesh(curves)
	vines.material_override = _thorn_mat
	s.add_child(vines)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = f._cyl(0.0, 1.0, 1.0, 5)
	mm.instance_count = spikes.size()
	for i in range(spikes.size()):
		var sp: Array = spikes[i]
		var r: float = float(sp[3])
		var bas := Basis.from_euler(Vector3(float(sp[2]), float(sp[1]), 0)).scaled(Vector3(r * 0.45, r * 2.4, r * 0.45))
		mm.set_instance_transform(i, Transform3D(bas, (sp[0] as Vector3) + bas.y * 0.5 + Vector3.UP * 0.0))
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = mm
	smi.material_override = _thorn_mat
	s.add_child(smi)
	# Le sol de l'arène : un cercle de dalles fendues, des roses mortes tout autour
	f._mesh(s, f._cyl(10.5, 10.5, 0.06, 48), f.gfx.rock("plafond"), C + Vector3.UP * 0.02)
	for k in range(16):
		var a2: float = TAU * k / 16.0
		_rose(C + Vector3(cos(a2) * 11.2, 0, sin(a2) * 11.2), 1.0 + 0.35 * (k % 3), k)
	# Le trône d'épines et la grande rose noire
	var throne := Node3D.new()
	throne.name = "Trone"
	s.add_child(throne)
	throne.position = Vector3(C.x, 0, Z0 + 3.0)
	f._box(throne, Vector3(3.2, 0.6, 2.4), Vector3(0, 0.3, 0), f.gfx.rock("mur"))
	f._mesh(throne, f._boxm(Vector3(2.4, 0.4, 1.6)), _thorn_mat, Vector3(0, 0.8, 0.1))
	f._mesh(throne, f._boxm(Vector3(2.4, 3.8, 0.4)), _thorn_mat, Vector3(0, 2.7, -0.6))
	for k in range(9):
		var x: float = -1.2 + k * 0.3
		f._mesh(throne, f._cyl(0.0, 0.1, 0.9 + (k % 3) * 0.5, 5), _thorn_mat, Vector3(x, 4.8 + (k % 3) * 0.25, -0.6), Vector3(0, 0, (x) * -0.35))
	_rose(Vector3(C.x, 6.5, Z0 + 1.2), 3.0, 99)
	# Les trois roses de lumière (phase 3)
	for i in range(ROSE_ANGLES.size()):
		var a3: float = float(ROSE_ANGLES[i])
		var p: Vector3 = C + Vector3(cos(a3), 0, sin(a3)) * 8.0
		_light_rose(i, p)
	# La herse de ronces qui repousse derrière le joueur
	_gate = Node3D.new()
	_gate.name = "Herse_de_ronces"
	s.add_child(_gate)
	_gate.position = Vector3(0, 0, Z1 + 0.4)
	var gcurves: Array = []
	for k in range(12):
		var x0: float = -1.6 + k * 0.29
		gcurves.append([Vector3(x0, -0.2, 0), Vector3(x0 + sin(k * 1.7) * 0.8, 2.0, sin(k) * 0.3), Vector3(-x0 * 0.7, 4.3, 0), 0.09, 0.04, 8])
	var gm := MeshInstance3D.new()
	gm.mesh = f.gfx.roots_mesh(gcurves)
	gm.material_override = _thorn_mat
	_gate.add_child(gm)
	f._box(s, Vector3(3.4, 4.3, 0.6), Vector3(0, 2.15, Z1 + 0.4), _thorn_mat, true).visible = false
	_gate_cs = f._last_cs
	# Lumières : rouge sombre pendant la malédiction, dorées après la victoire
	for k in range(3):
		var lp: Vector3 = C + Vector3(cos(k * 2.1) * 7.0, 9.0, sin(k * 2.1) * 7.0)
		_light_red.append(f._light(s, lp, Color(0.85, 0.2, 0.35), 1.6, 18.0))
		_light_gold.append(f._light(s, lp, Color(1.0, 0.85, 0.6), 0.0, 20.0))
	f._sparkles(s, C + Vector3(0, 5.0, 0), Vector3(10, 4, 10), 60, 0.12)
	# Églantine (après la victoire)
	_build_eglantine()
	d._interactions.append({"id": "eglantine", "pos": s.to_global(C + Vector3(0, 0, -3.0)), "radius": 2.6,
		"text": "E : parler à Églantine", "vr": "Gâchette : parler à Églantine", "call": _talk_eglantine,
		"when": func(): return bool(f.state["reine"])})


## Une rose (morte au départ) : tige, feuilles, pétales sombres qui refleuriront.
func _rose(at: Vector3, size: float, k: int) -> void:
	var stem: Material = f._glow(Color(0.12, 0.2, 0.1), 0.05)
	f._mesh(s, f._cyl(0.025 * size, 0.035 * size, size, 6), stem, at + Vector3.UP * size * 0.5, Vector3(sin(k) * 0.1, 0, cos(k) * 0.1))
	var head: Vector3 = at + Vector3.UP * size
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.22, 0.05, 0.1)
	pm.roughness = 0.55
	pm.emission_enabled = true
	pm.emission = Color(0.15, 0.02, 0.06)
	pm.emission_energy_multiplier = 0.4
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_dead_petals.append(pm)
	for j in range(9):
		var a: float = j * 2.4
		var ring: float = 0.04 + 0.025 * (j / 3)
		var pet: MeshInstance3D = f._mesh(s, f._sphere(0.09 * size, 10), pm, head + Vector3(cos(a) * ring * size, 0.02 * size * (j / 3), sin(a) * ring * size), Vector3.ZERO, Vector3(0.9, 0.55, 0.35))
		pet.rotation = Vector3(0.5 + 0.25 * (j / 3), -a + PI * 0.5, 0)


func _light_rose(i: int, p: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Rose_de_lumiere_%d" % i
	s.add_child(root)
	root.position = p
	f._mesh(root, Rocks.shape(4620 + i, Vector3(1.4, 0.5, 1.2), 0.7, 0.2), f.gfx.rock("mur"), Vector3.UP * 0.1)
	f._mesh(root, f._cyl(0.04, 0.06, 1.5, 6), f._glow(Color(0.2, 0.4, 0.2), 0.1), Vector3(0, 1.0, 0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.9)
	mat.emission_energy_multiplier = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var petals: Array = []
	for j in range(6):
		var a: float = TAU * j / 6.0
		var hinge := Node3D.new()
		hinge.position = Vector3(cos(a) * 0.05, 1.75, sin(a) * 0.05)
		hinge.rotation.y = -a + PI * 0.5
		root.add_child(hinge)
		f._mesh(hinge, f._sphere(0.16, 10), mat, Vector3(0, 0.15, 0), Vector3.ZERO, Vector3(0.7, 1.3, 0.3))
		petals.append(hinge)
	var l: OmniLight3D = f._light(root, Vector3(0, 2.0, 0), Color(1.0, 0.75, 0.9), 0.0, 8.0)
	var beam := MeshInstance3D.new()
	beam.mesh = f._cyl(0.08, 0.08, 1.0, 6)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(1.0, 0.8, 0.95, 0.75)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam.material_override = bm
	beam.visible = false
	s.add_child(beam)
	_roses.append({"root": root, "petals": petals, "mat": mat, "light": l, "lit": false, "pos": p, "beam": beam})
	d._interactions.append({"id": "rose_lumiere_%d" % i, "pos": s.to_global(p), "radius": 1.8,
		"text": "E : réveiller la rose de lumière", "vr": "Gâchette : réveiller la rose", "call": light_rose.bind(i),
		"when": func(): return roses_active and not bool(_roses[i]["lit"])})


func _build_eglantine() -> void:
	_eglantine = Node3D.new()
	_eglantine.name = "Eglantine"
	s.add_child(_eglantine)
	_eglantine.position = C + Vector3(0, 0, -3.0)
	_eglantine.visible = false


# =================================================================== combat

func _process(delta: float) -> void:
	if main == null or not main.game_started or not bool(f.in_zone):
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var off := Vector2(p.x - center_w.x, p.z - center_w.z)
	var in_arena: bool = absf(p.y - center_w.y) < 3.0 and s.to_local(p).z < Z1 - 1.0 and s.to_local(p).z > Z0 and s.to_local(p).x > X0 and s.to_local(p).x < X1
	if not fight and bool(f.state["ronces"]) and not bool(f.state["reine"]) and in_arena and off.length() < 10.0:
		_start_fight()
	elif fight and boss != null and boss.state != "mort" and not in_arena:
		_reset_fight()
	if _eglantine != null and _eglantine.visible:
		_eglantine.position.y = 0.35 + sin(_clock * 1.6) * 0.15
	# Rayons des roses vers la Reine
	for r in _roses:
		var beam: MeshInstance3D = r["beam"]
		if beam.visible and boss != null and is_instance_valid(boss):
			var a: Vector3 = (r["root"] as Node3D).global_position + Vector3.UP * 1.9
			var b: Vector3 = boss.global_position + Vector3.UP * 1.6
			beam.global_position = (a + b) * 0.5
			beam.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT)
			beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			beam.scale = Vector3(1, a.distance_to(b), 1)


func _start_fight() -> void:
	fight = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("boss_cri")
	boss = ReineScript.new()
	d.add_child(boss)
	boss.setup(self, center_w)
	boss.health_changed.connect(_on_health)
	boss.defeated.connect(_on_defeated)
	# La herse de ronces repousse
	_gate.visible = true
	_gate.scale = Vector3(1, 0.05, 1)
	create_tween().tween_property(_gate, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK)
	_gate_cs.set_deferred("disabled", false)
	d._bar_name = "La Reine des Ronces"
	d._bar_label.text = d._bar_name
	d._bar_layer.visible = not main.xr_active
	if main.xr_active:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.005
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(1.0, 0.6, 0.85)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, 3.6, 0)
		boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(boss.hp, boss.HP_MAX)
	activate_roses(false)
	say("Les ronces se referment derrière toi. Sur le trône, une silhouette se redresse… LA REINE DES RONCES ouvre ses ailes noires !", 6.0)


func _on_health(hp: int, hp_max: int) -> void:
	d._update_bar(hp, hp_max)


func _reset_fight() -> void:
	fight = false
	if boss != null:
		boss.queue_free()
		boss = null
	d._bar_vr = null
	_bar_vr = null
	d._bar_layer.visible = false
	activate_roses(false)
	apply_state()


func activate_roses(on: bool) -> void:
	roses_active = on
	for r in _roses:
		r["lit"] = false
		(r["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.6 if on else 0.0
		(r["light"] as OmniLight3D).light_energy = 0.5 if on else 0.0
		(r["beam"] as MeshInstance3D).visible = false
		for h in r["petals"]:
			(h as Node3D).rotation.x = 0.0


func light_rose(i: int) -> void:
	var r: Dictionary = _roses[i]
	if bool(r["lit"]) or not roses_active:
		return
	r["lit"] = true
	(r["mat"] as StandardMaterial3D).emission_energy_multiplier = 3.0
	create_tween().tween_property(r["light"], "light_energy", 2.4, 0.4)
	for h in r["petals"]:
		create_tween().tween_property(h, "rotation:x", -1.1, 0.6).set_trans(Tween.TRANS_BACK)
	(r["beam"] as MeshInstance3D).visible = true
	var n: int = 0
	for rr in _roses:
		if bool(rr["lit"]):
			n += 1
	if n < _roses.size():
		say("La rose de lumière s'ouvre et brûle la Reine de son rayon ! (%d / %d)" % [n, _roses.size()], 3.0)
		return
	if boss != null:
		boss.stun()
	await get_tree().create_timer(1.2).timeout
	for rr in _roses:
		(rr["beam"] as MeshInstance3D).visible = false


## V48 : chargement d'une partie : on arrête net le combat en cours (boss, roses, herse, barre).
func reset_session() -> void:
	_session += 1
	if boss != null and is_instance_valid(boss):
		boss.queue_free()
	boss = null
	fight = false
	d._bar_vr = null
	_bar_vr = null
	if d._bar_layer != null:
		d._bar_layer.visible = false
	if _gate != null:
		_gate.scale = Vector3.ONE
	activate_roses(false)


func _on_defeated() -> void:
	var s0: int = _session
	f.state["reine"] = true
	d.state["victoires"] = int(d.state["victoires"]) + 1
	activate_roses(false)
	say("La Reine des Ronces pousse un cri… Les épines tombent de sa robe comme des feuilles mortes. Une lumière rose l'enveloppe…", 6.0)
	await get_tree().create_timer(3.0).timeout
	if s0 != _session:
		return
	fight = false
	d._bar_layer.visible = false
	d._bar_vr = null
	if boss != null and is_instance_valid(boss):
		boss.purify()
	_bloom(false)
	await get_tree().create_timer(3.5).timeout
	if s0 != _session:
		return
	if boss != null and is_instance_valid(boss):
		boss.queue_free()
		boss = null
	_eglantine.visible = true
	_dress_eglantine()
	say("Les ronces se fanent, les roses refleurissent. Devant toi flotte une fée immense, douce et lumineuse : Églantine, la vraie Reine des Fées. Parle-lui.", 7.0)
	if f.lumi != null:
		f.lumi_say("Majesté ! C'est vous ! Vous êtes revenue !", 5.0)


## Les roses refleurissent, la herse de ronces se fane, la lumière devient dorée.
func _bloom(instant: bool) -> void:
	for pm in _dead_petals:
		var m: StandardMaterial3D = pm
		if instant:
			m.albedo_color = Color(1.0, 0.62, 0.72)
			m.emission = Color(1.0, 0.5, 0.65)
			m.emission_energy_multiplier = 0.6
		else:
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(m, "albedo_color", Color(1.0, 0.62, 0.72), 3.0)
			tw.tween_property(m, "emission", Color(1.0, 0.5, 0.65), 3.0)
			tw.tween_property(m, "emission_energy_multiplier", 0.6, 3.0)
	for l in _light_red:
		if instant:
			(l as OmniLight3D).light_energy = 0.0
		else:
			create_tween().tween_property(l, "light_energy", 0.0, 3.0)
	for l in _light_gold:
		if instant:
			(l as OmniLight3D).light_energy = 1.8
		else:
			create_tween().tween_property(l, "light_energy", 1.8, 3.0)
	_thorn_mat.albedo_color = Color(0.3, 0.22, 0.18) if instant else _thorn_mat.albedo_color
	if not instant:
		create_tween().tween_property(_thorn_mat, "albedo_color", Color(0.3, 0.22, 0.18), 3.0)
	if _gate != null:
		if instant:
			_gate.visible = false
		else:
			var tw2 := create_tween()
			tw2.tween_property(_gate, "scale", Vector3(1, 0.02, 1), 2.0)
			tw2.tween_callback(func(): _gate.visible = false)
		_gate_cs.set_deferred("disabled", true)


## Églantine : la Reine purifiée (même silhouette que le boss, en clair).
func _dress_eglantine() -> void:
	for c in _eglantine.get_children():
		c.queue_free()
	var look: Node3D = ReineScript.build_look(true, main._soft_dot_v24())
	_eglantine.add_child(look)
	var l: OmniLight3D = f._light(_eglantine, Vector3(0, 2.2, 0.8), Color(1.0, 0.8, 0.9), 1.6, 9.0)
	l.name = "Lueur"
	_eglantine.rotation.y = 0.0


func _talk_eglantine() -> void:
	if not bool(f.state["carte"]):
		# V48 : tout ou rien (avant, les pièces pouvaient être données plusieurs fois).
		if not main.inventory_v28.can_accept([["piece", 150], ["carte_naine", 1], ["nectar_fee", 3]]):
			say("« Tes bras sont chargés, humain… Fais un peu de place dans ton sac : j'ai une carte, des pièces et du nectar pour toi. »", 6.0)
			return
		f.state["carte"] = true
		var a: int = main.inventory_v28.add("piece", 150)
		var c: int = main.inventory_v28.add("carte_naine", 1)
		var n: int = main.inventory_v28.add("nectar_fee", 3)
		say("« Merci, humain. Cent ans, prisonnière de mes propres ronces… Tu m'as rendu mon cœur. Prends ceci : %d pièces, %d nectars… et cette carte. À l'ouest, derrière les Récifs de Feu, les nains de la Montagne de Feu forgent depuis mille ans. Leur île est cachée par la cendre ; la carte te montrera la passe. Ils te feront bon accueil… peut-être. »%s" % [a, n, "" if c > 0 else " (Ton sac est plein : reviens chercher la carte !)"], 11.0)
		if c <= 0:
			f.state["carte"] = false
		return
	var lines := ["« Le royaume refleurit. Les fées chantent à nouveau. Merci, humain. »",
		"« La passe des Récifs de Feu est à l'est de l'île des nains, face au soleil levant. Suis la carte. »",
		"« Les nains n'aiment pas les surprises. Frappe fort à leur porte, mais poliment. »"]
	say(lines[int(_clock) % lines.size()], 6.0)


func apply_state() -> void:
	if fight:
		return
	var won: bool = bool(f.state["reine"])
	if won:
		_bloom(true)
		_eglantine.visible = true
		if _eglantine.get_child_count() == 0:
			_dress_eglantine()
	else:
		_eglantine.visible = false
		for pm in _dead_petals:
			var m: StandardMaterial3D = pm
			m.albedo_color = Color(0.22, 0.05, 0.1)
			m.emission = Color(0.15, 0.02, 0.06)
			m.emission_energy_multiplier = 0.4
		for l in _light_red:
			(l as OmniLight3D).light_energy = 1.6
		for l in _light_gold:
			(l as OmniLight3D).light_energy = 0.0
		_thorn_mat.albedo_color = Color(0.16, 0.08, 0.13)
		_gate.visible = false
		_gate_cs.set_deferred("disabled", true)
	activate_roses(false)

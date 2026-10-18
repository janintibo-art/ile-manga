extends Node3D
## V40 : l'antre de Nâga, derrière la Porte de l'Abîme (au nord du Lac Noir).
## Un couloir, puis une immense caverne inondée : une plate-forme ronde de 22 m entourée
## d'un anneau d'eau noire où nage Nâga. Une herse retombe derrière le joueur quand il pose
## le pied sur la plate-forme. Trois Yeux de pierre (piliers) entourent la plate-forme : en
## phase 3, on les réveille avec l'Amulette du Serpent, et leurs rayons foudroient Nâga.
## Tomber à l'eau ramène au bord de la plate-forme. S'évanouir remet le combat à zéro.
## Victoire : la herse se relève, le coffre de Nâga remonte au centre, et la lumière revient.
## Repère : section « village » du temple.

const NagaScript = preload("res://scripts/naga_v40.gd")
const Y: float = -43.0                          # sol de la plate-forme
const C := Vector3(-1.0, -43.0, -177.3)         # centre de la plate-forme
const PLAT_R: float = 11.0
const X0: float = -21.0
const X1: float = 19.0
const Z0: float = -196.0
const Z1: float = -158.6
const EYE_ANGLES := [0.5236, 2.618, 4.712]      # 30°, 150°, 270°

var d: Node
var main: Node
var center_w: Vector3 = Vector3.INF             # centre (monde)
var boss: Node3D
var fight: bool = false
var eyes_active: bool = false
var _eyes: Array = []                           # {root, mat, beam, light, lit, pos}
var _herse: Node3D
var _chest: Node3D
var _victory_lights: Array = []
var _respawning: bool = false
var _bar_vr: Label3D


func setup(donjon: Node, main_node: Node) -> void:
	d = donjon
	main = main_node


func say(text: String, seconds: float = 4.0) -> void:
	d._say(text, seconds)


# =================================================================== construction

func build(s: Node3D) -> void:
	center_w = s.to_global(C)
	var ab: Node = d.abysses
	# Couloir derrière la Porte de l'Abîme
	d._room(s, -4.2, 2.2, -158.0, -152.6, Y, 9.0, "grotte", "sol", [["s", -1.0, 6.4, 9.0], ["n", -1.0, 6.4, 9.0]], "grotte")
	d._torch(s, Vector3(-4.15, Y + 3.0, -155.3), Vector3(1, 0, 0), 1.2)
	d._torch(s, Vector3(2.15, Y + 3.0, -155.3), Vector3(-1, 0, 0), 1.2)
	_herse = d._portcullis(s, Vector3(-1.0, Y, -157.9), 6.4, 9.0, 0.0)
	# La caverne : le sol est 4 m sous la plate-forme (l'eau), la voûte 20 m au-dessus
	var floor_y: float = Y - 4.0
	var top: float = Y + 20.0
	d._box(s, Vector3(X1 - X0 + 1.2, 0.5, Z1 - Z0 + 1.2), Vector3((X0 + X1) * 0.5, floor_y - 0.25, (Z0 + Z1) * 0.5), d._mat("grotte"))
	d._box(s, Vector3(X1 - X0 + 1.2, 0.6, Z1 - Z0 + 1.2), Vector3((X0 + X1) * 0.5, top + 0.3, (Z0 + Z1) * 0.5), d._mat("grotte"))
	ab._walls(s, X0, X1, Z0, Z1, floor_y, top - floor_y, "grotte", [["s", -1.0, 6.4, Y, Y + 9.0]])
	# Pont jusqu'à la plate-forme
	d._box(s, Vector3(4.0, 4.0, Z1 - (C.z + PLAT_R) + 1.2), Vector3(-1.0, Y - 2.0, (Z1 + C.z + PLAT_R) * 0.5 - 0.6), d._mat("sol"))
	# La plate-forme
	var plat := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = PLAT_R
	pc.bottom_radius = PLAT_R + 0.6
	pc.height = 4.0
	pc.radial_segments = 48
	plat.mesh = pc
	plat.material_override = d._mat("sol")
	plat.position = C + Vector3.DOWN * 2.0
	s.add_child(plat)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = PLAT_R
	cyl.height = 4.0
	cs.shape = cyl
	d._body.add_child(cs)
	cs.global_position = s.to_global(C + Vector3.DOWN * 2.0)
	for k in range(40):
		var a: float = TAU * k / 40.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.2:
			continue
		d._box(s, Vector3(1.6, 0.35, 0.5), C + Vector3(cos(a) * (PLAT_R - 0.3), 0.17, sin(a) * (PLAT_R - 0.3)), d._mat("mur"), false, Vector3(0, -a + PI * 0.5, 0))
	# Le grand cercle gravé au centre
	var glyph := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(6.0, 6.0)
	glyph.mesh = gq
	glyph.material_override = d._glyph_mat("serpent")
	glyph.rotation.x = -PI * 0.5
	glyph.position = C + Vector3.UP * 0.02
	s.add_child(glyph)
	# L'eau noire tout autour
	var w := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(X1 - X0, Z1 - Z0)
	w.mesh = wp
	w.material_override = ab._dark_water()
	w.position = Vector3((X0 + X1) * 0.5, Y - 0.6, (Z0 + Z1) * 0.5)
	s.add_child(w)
	# Lueurs bleu-vert au ras de l'eau (algues), pour voir la surface et les anneaux de Nâga
	for k in range(6):
		var a4: float = TAU * k / 6.0 + 0.3
		var wl := OmniLight3D.new()
		wl.light_color = Color(0.3, 0.85, 0.8)
		wl.light_energy = 1.2
		wl.omni_range = 9.0
		wl.position = C + Vector3(cos(a4) * 16.5, -0.2, sin(a4) * 15.5)
		s.add_child(wl)
		ab._crystals(s, C + Vector3(cos(a4) * 17.6, -1.0, sin(a4) * 16.6), Vector3(-cos(a4), 0, -sin(a4)), 4030 + k, 0.8)
	var rock: Material = load("res://scripts/rocks_v26.gd").material(Color(0.4, 0.4, 0.4), 0.1, 0.3)
	d._boulders(s, Vector3((X0 + X1) * 0.5, floor_y, (Z0 + Z1) * 0.5), Vector2((X1 - X0) * 0.5 - 0.5, (Z1 - Z0) * 0.5 - 0.5), 26, 4001, rock, 2.0, 4.0)
	d._stalactites(s, Vector3(C.x, Y, C.z), Vector2(17.0, 16.0), top, 40, 4002)
	# Trois Yeux de pierre
	for i in range(EYE_ANGLES.size()):
		var a2: float = EYE_ANGLES[i]
		_eye_pillar(s, i, C + Vector3(cos(a2) * 8.2, 0, sin(a2) * 8.2))
	# Lumières : cristaux sur les parois, torches au bord du pont, lumière d'appoint
	for p in [[Vector3(X0 + 0.3, Y + 1.0, -170.0), Vector3(1, 0, 0)], [Vector3(X1 - 0.3, Y + 2.0, -168.0), Vector3(-1, 0, 0)],
			[Vector3(X0 + 0.3, Y + 0.5, -186.0), Vector3(1, 0, 0)], [Vector3(X1 - 0.3, Y + 0.0, -188.0), Vector3(-1, 0, 0)],
			[Vector3(-8.0, Y + 1.5, Z0 + 0.3), Vector3(0, 0, 1)], [Vector3(7.0, Y + 0.5, Z0 + 0.3), Vector3(0, 0, 1)]]:
		ab._crystals(s, p[0], p[1], 4010 + int(p[0].x * 3.0 + p[0].z), 2.0)
	for sx in [-1.0, 1.0]:
		d._brazier_fixed(s, Vector3(-1.0 + sx * 2.6, Y, C.z + PLAT_R - 1.4))
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.5, 0.75, 0.7)
	fill.light_energy = 1.0
	fill.omni_range = 30.0
	fill.omni_attenuation = 0.6
	fill.light_specular = 0.2
	fill.position = C + Vector3.UP * 12.0
	s.add_child(fill)
	var ray := SpotLight3D.new()
	ray.light_color = Color(0.5, 0.85, 1.0)
	ray.light_energy = 3.0
	ray.spot_range = 26.0
	ray.spot_angle = 30.0
	ray.position = C + Vector3.UP * 19.5
	ray.rotation.x = -PI * 0.5
	s.add_child(ray)
	# Lumière chaude de la victoire (éteinte tant que Nâga vit)
	for k in range(4):
		var a3: float = TAU * k / 4.0 + 0.4
		var vl := OmniLight3D.new()
		vl.light_color = Color(1.0, 0.85, 0.6)
		vl.light_energy = 0.0
		vl.omni_range = 18.0
		vl.position = C + Vector3(cos(a3) * 7.0, 8.0, sin(a3) * 7.0)
		s.add_child(vl)
		_victory_lights.append(vl)
	# Le coffre de Nâga (il remonte du centre après la victoire)
	_chest = Node3D.new()
	_chest.name = "Coffre_Naga"
	s.add_child(_chest)
	_chest.position = C + Vector3(0, 0, 1.5)
	d._box(_chest, Vector3(1.4, 0.75, 0.9), Vector3(0, 0.375, 0), d._mat("bois"), false)
	for x in [-0.5, 0.5]:
		d._box(_chest, Vector3(0.08, 0.77, 0.92), Vector3(x, 0.375, 0), d._mat("bronze"), false)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.75, -0.45)
	_chest.add_child(hinge)
	d._box(hinge, Vector3(1.4, 0.24, 0.9), Vector3(0, 0.12, 0.45), d._mat("bois"), false)
	var gem := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.12
	gm.height = 0.2
	gem.mesh = gm
	gem.material_override = ab._crystal_mat()
	gem.position = Vector3(0, 0.12, 0.92)
	hinge.add_child(gem)
	d._interactions.append({"id": "coffre_naga", "pos": s.to_global(C + Vector3(0, 0, 1.5)), "radius": 2.2,
		"text": "E : ouvrir le coffre de Nâga", "vr": "Gâchette : ouvrir le coffre", "call": _open_chest,
		"when": func(): return bool(d.state["naga"]) and not bool(d.state["coffre_naga"]) and not fight})


func _eye_pillar(s: Node3D, i: int, p: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Oeil_de_pierre_%d" % i
	s.add_child(root)
	root.position = p
	d._box(root, Vector3(1.4, 0.5, 1.4), Vector3(0, 0.25, 0), d._mat("sol"))
	d._box(root, Vector3(0.9, 2.6, 0.9), Vector3(0, 1.8, 0), d._mat("mur"))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.5, 0.35)
	m.emission_enabled = true
	m.emission = Color(0.3, 1.0, 0.55)
	m.emission_energy_multiplier = 0.0
	var eye := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.38
	sm.height = 0.76
	eye.mesh = sm
	eye.material_override = m
	eye.position = Vector3(0, 3.35, 0)
	root.add_child(eye)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.36
	tm.outer_radius = 0.5
	ring.mesh = tm
	ring.material_override = d._mat("bronze")
	ring.position = Vector3(0, 3.35, 0)
	ring.rotation.x = PI * 0.5
	root.add_child(ring)
	var beam := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.25
	bc.bottom_radius = 0.25
	bc.height = 16.0
	beam.mesh = bc
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.albedo_color = Color(0.3, 1.0, 0.5, 0.45)
	beam.material_override = bmat
	beam.position = Vector3(0, 3.35 + 8.0, 0)
	beam.visible = false
	root.add_child(beam)
	var light := OmniLight3D.new()
	light.light_color = Color(0.35, 1.0, 0.6)
	light.light_energy = 0.0
	light.omni_range = 9.0
	light.position = Vector3(0, 3.6, 0)
	root.add_child(light)
	var e := {"root": root, "mat": m, "beam": beam, "light": light, "lit": false, "pos": p}
	_eyes.append(e)
	d._interactions.append({"id": "oeil_%d" % i, "pos": s.to_global(p), "radius": 1.9,
		"text": "E : réveiller l'Œil avec l'amulette", "vr": "Gâchette : réveiller l'Œil", "call": light_eye.bind(i),
		"when": func(): return fight and eyes_active and not bool(e["lit"])})


# =================================================================== les Yeux

func activate_eyes(on: bool) -> void:
	eyes_active = on
	for e in _eyes:
		e["lit"] = false
		(e["beam"] as Node3D).visible = false
		(e["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.8 if on else 0.0
		(e["light"] as OmniLight3D).light_energy = 0.6 if on else 0.0


func light_eye(i: int) -> void:
	if main.inventory_v28.count("amulette_serpent") <= 0:
		say("L'Œil reste éteint… Il faudrait l'Amulette du Serpent.", 3.0)
		return
	var e: Dictionary = _eyes[i]
	e["lit"] = true
	(e["beam"] as Node3D).visible = true
	(e["mat"] as StandardMaterial3D).emission_energy_multiplier = 5.0
	(e["light"] as OmniLight3D).light_energy = 3.0
	var n: int = 0
	for x in _eyes:
		if bool(x["lit"]):
			n += 1
	if n < _eyes.size():
		say("L'amulette brille : un Œil s'ouvre ! (%d sur 3)" % n, 2.5)
		return
	eyes_active = false
	if boss != null and is_instance_valid(boss):
		boss.stun()
	await get_tree().create_timer(1.5).timeout
	for x in _eyes:
		(x["beam"] as Node3D).visible = false
		(x["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.0
		(x["light"] as OmniLight3D).light_energy = 0.0


# =================================================================== combat

func _process(_delta: float) -> void:
	if d == null or main == null or not main.game_started or center_w == Vector3.INF or not bool(d.inside):
		return
	var p: Vector3 = main._player_pos_v27()
	var off := Vector2(p.x - center_w.x, p.z - center_w.z)
	# Tombé à l'eau dans l'antre : retour au bord de la plate-forme, côté pont
	if not _respawning and off.length() < 26.0 and p.y < center_w.y - 1.2 and p.y > center_w.y - 6.0:
		_fall_in()
		return
	if not fight and bool(d.state["porte_abime"]) and not bool(d.state["naga"]) and off.length() < PLAT_R - 2.0 and absf(p.y - center_w.y) < 2.5:
		_start_fight()
	elif fight and boss != null and boss.state != "mort" and (off.length() > 24.0 or absf(p.y - center_w.y) > 7.0):
		_reset_fight()


func _fall_in() -> void:
	_respawning = true
	var s: Node3D = d.sections["village"]
	if main.hero_v28 != null and not main.xr_active:
		main.hero_v28.fall_top = main.pc_body.position.y
	say("L'eau noire est glaciale… Tu te hisses sur le bord de la plate-forme.", 3.0)
	await d._travel(s.to_global(C + Vector3(0, 0.05, PLAT_R - 1.6)), s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO))
	_respawning = false


func _start_fight() -> void:
	fight = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("boss_cri")
	boss = NagaScript.new()
	d.add_child(boss)
	boss.setup(self, center_w, center_w.y - 0.6)
	boss.health_changed.connect(_on_health)
	boss.defeated.connect(_on_defeated)
	var hb: StaticBody3D = _herse.get_node("Grille_collision")
	hb.collision_layer = 1
	create_tween().tween_property(_herse, "position:y", Y, 0.6).set_trans(Tween.TRANS_QUAD)
	d._bar_name = "Nâga, le Serpent des Abysses"
	d._bar_label.text = d._bar_name
	d._bar_layer.visible = not main.xr_active
	if main.xr_active:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.005
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(0.6, 1.0, 0.7)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, 3.0, 0)
		boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(boss.hp, boss.HP_MAX)
	activate_eyes(false)
	say("La herse retombe. L'eau noire se soulève… NÂGA, LE SERPENT DES ABYSSES, sort des profondeurs !", 5.0)


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
	activate_eyes(false)
	apply_state()


func _on_defeated() -> void:
	main.jingle("victoire")
	d.state["naga"] = true
	d.state["victoires"] = int(d.state["victoires"]) + 1
	activate_eyes(false)
	say("Nâga pousse un dernier sifflement… et s'enfonce lentement dans les abysses. Le Serpent est vaincu !", 6.0)
	await get_tree().create_timer(3.0).timeout
	fight = false
	d._bar_layer.visible = false
	d._bar_vr = null
	var hb: StaticBody3D = _herse.get_node("Grille_collision")
	var tw := create_tween()
	tw.tween_property(_herse, "position:y", Y + 9.4, 2.5)
	tw.tween_callback(func(): hb.collision_layer = 0)
	for vl in _victory_lights:
		create_tween().tween_property(vl, "light_energy", 1.6, 4.0)
	_chest.visible = true
	var target_y: float = _chest.position.y
	_chest.position.y = target_y - 1.2
	create_tween().tween_property(_chest, "position:y", target_y, 2.0).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(2.5).timeout
	if boss != null and is_instance_valid(boss):
		boss.queue_free()
		boss = null
	say("Une lumière dorée descend de la voûte. Le Temple englouti est libéré… Au centre de la plate-forme, un coffre est remonté des profondeurs.", 7.0)


func _open_chest() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 200], ["piece_or", 5], ["rubis", 3], ["ecaille_naga", 1]]):
		say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	d.state["coffre_naga"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("coffre")
		main.jingle("decouverte")
	var hinge: Node3D = _chest.get_node("Charniere")
	create_tween().tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 200)
	var o: int = main.inventory_v28.add("piece_or", 5)
	var r: int = main.inventory_v28.add("rubis", 3)
	var e: int = main.inventory_v28.add("ecaille_naga", 1)
	say("Le trésor de Nâga : %d pièces, %d pièces d'or, %d rubis… et une ÉCAILLE DE NÂGA, verte et dure comme du jade.%s" % [a, o, r, "" if e > 0 else " (ton sac est plein !)"], 8.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(_chest.global_position + Vector3.UP * 0.9, Color(1.0, 0.85, 0.4))


func apply_state() -> void:
	if _herse != null and not fight:
		_herse.position.y = Y + 9.4
		(_herse.get_node("Grille_collision") as StaticBody3D).collision_layer = 0
	var won: bool = bool(d.state["naga"])
	if _chest != null:
		_chest.visible = won
		(_chest.get_node("Charniere") as Node3D).rotation.x = -1.8 if bool(d.state["coffre_naga"]) else 0.0
	for vl in _victory_lights:
		(vl as OmniLight3D).light_energy = 1.6 if won else 0.0


func on_load() -> void:
	if fight:
		_reset_fight()

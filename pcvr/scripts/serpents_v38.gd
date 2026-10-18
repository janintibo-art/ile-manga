extends Node3D
## V38 : Temple englouti, étape 4.
## Côté jungle : la Salle des Quatre Serpents. Quatre serpents de pierre doivent tous regarder
## l'autel central, mais aucun ne tourne seul : tourner un serpent fait aussi tourner son
## voisin (dans le sens des aiguilles d'une montre). Résolue, l'énigme ouvre l'autel et livre
## le troisième fragment de l'amulette… et réveille les deux gardiens de la salle.
## Côté village : la Porte du Serpent. Avec les trois fragments, elle s'ouvre ; les fragments
## se soudent en l'Amulette du Serpent, qui éclaire les ténèbres autour du joueur.
## Derrière : le Sanctuaire de l'Œil (grand serpent de bronze, fontaine qui soigne, coffre
## des offrandes ; le sceau du Puits des Abysses est construit par abysses_v39.gd).

const Rocks = preload("res://scripts/rocks_v26.gd")
const START_CODE: int = 45                 # orientations de départ [1, 3, 2, 0] (quarts de tour)
const CENTER := Vector3(16.0, 0.0, -12.0)  # autel (repère « jungle »)
const STATUES := [Vector3(12.5, 0, -15.5), Vector3(19.5, 0, -15.5), Vector3(19.5, 0, -8.5), Vector3(12.5, 0, -8.5)]
const WARDENS := [Vector3(23.2, 0, -16.8), Vector3(23.2, 0, -7.2)]
const SANCT_Y: float = -3.0                # sol du sanctuaire (repère « village »)
const SERPENT_C := Vector3(0.0, -3.0, -85.0)

var d: Node
var main: Node
var _heads: Array = []                     # pivots des têtes des quatre serpents
var _base_yaw: Array = []
var _channels: Array = []                  # matériaux des rigoles lumineuses
var _turning: bool = false
var _lid: Node3D
var _frag: Node3D
var _frag_light: OmniLight3D
var _wardens: Array = []                   # {root, shapes, pos}
var _door_l: Node3D
var _door_r: Node3D
var _lock: Node3D
var _eye_mat: StandardMaterial3D
var _slots: Array = []
var _amu_light: OmniLight3D
var _sanct_chest: Node3D
var _patina: StandardMaterial3D


func setup(donjon: Node, main_node: Node) -> void:
	d = donjon
	main = main_node


# =================================================================== état

func orient(i: int) -> int:
	return (int(d.state["serpents"]) >> (2 * i)) & 3


func _set_orient(i: int, o: int) -> void:
	var v: int = int(d.state["serpents"])
	v &= ~(3 << (2 * i))
	v |= (o & 3) << (2 * i)
	d.state["serpents"] = v


func facing_count() -> int:
	var n: int = 0
	for i in range(4):
		if orient(i) == 0:
			n += 1
	return n


func apply_state() -> void:
	for i in range(_heads.size()):
		(_heads[i] as Node3D).rotation.y = float(_base_yaw[i]) - orient(i) * PI * 0.5
	_refresh_channels()
	var solved: bool = bool(d.state["enigme_serpents"])
	var taken: bool = bool(d.state["fragment3"])
	if _lid != null:
		_lid.position = Vector3(CENTER.x + 1.25, 0.95, CENTER.z) if solved else Vector3(CENTER.x, 1.1, CENTER.z)
		_lid.rotation.z = -0.32 if solved else 0.0
	if _frag != null:
		_frag.visible = solved and not taken
		_frag.position = Vector3(CENTER.x, 1.55, CENTER.z) if solved else Vector3(CENTER.x, 0.8, CENTER.z)
		_frag_light.light_energy = 2.0 if solved and not taken else 0.0
	for w in _wardens:
		(w["root"] as Node3D).visible = not taken
		for cs in w["shapes"]:
			(cs as CollisionShape3D).disabled = taken
	var open: bool = bool(d.state["porte_serpent"])
	if _door_l != null:
		_door_l.position.x = -1.25 - (2.6 if open else 0.0)
		_door_r.position.x = 1.25 + (2.6 if open else 0.0)
		(_door_l.get_node("Corps") as StaticBody3D).collision_layer = 0 if open else 1
		(_door_r.get_node("Corps") as StaticBody3D).collision_layer = 0 if open else 1
		_lock.visible = not open
		_set_eye(open)
		for sl in _slots:
			(sl as Node3D).visible = open
	if _sanct_chest != null:
		(_sanct_chest.get_node("Charniere") as Node3D).rotation.x = -1.8 if bool(d.state["coffre_sanctuaire"]) else 0.0


func _set_eye(green: bool) -> void:
	if _eye_mat == null:
		return
	_eye_mat.albedo_color = Color(0.2, 0.85, 0.4) if green else Color(0.8, 0.1, 0.08)
	_eye_mat.emission = Color(0.3, 1.0, 0.5) if green else Color(1.0, 0.15, 0.08)
	_eye_mat.emission_energy_multiplier = 4.0 if green else 2.0


# =================================================================== matériaux

func _patina_mat() -> StandardMaterial3D:
	if _patina == null:
		_patina = StandardMaterial3D.new()
		# Bronze vert-de-gris : grain irrégulier de la roche, sans joints de maçonnerie.
		_patina.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
		_patina.normal_enabled = true
		_patina.normal_texture = load("res://assets/textures/jungle/jungle_rock_n.png")
		_patina.normal_scale = 0.7
		_patina.uv1_triplanar = true
		_patina.uv1_scale = Vector3(0.7, 0.7, 0.7)
		_patina.albedo_color = Color(0.42, 0.66, 0.54)
		# Peu métallique : sous terre, il n'y a pas de ciel à refléter.
		_patina.metallic = 0.15
		_patina.roughness = 0.55
	return _patina


func _jade_mat(energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.65, 0.45)
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = Color(0.25, 0.9, 0.5)
	m.emission_energy_multiplier = energy
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _sphere(r: float, segs: int = 16) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(segs / 2, 4)
	return sm


func _cone(r_top: float, r_bottom: float, h: float, segs: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = segs
	return c


## Un serpent dressé, construit le long de +Z (la tête regarde +Z) : anneaux, cou, capuchon,
## tête, yeux rouges et crochets.
func _snake(parent: Node3D, k: float, mat: Material, eye: Material) -> void:
	for r in range(3):
		var tm := TorusMesh.new()
		tm.inner_radius = 0.16 * k
		tm.outer_radius = (0.5 - r * 0.08) * k
		tm.rings = 20
		tm.ring_segments = 10
		_mesh(parent, tm, mat, Vector3(0, (0.12 + r * 0.17) * k, 0))
	for n in range(8):
		var t: float = float(n) / 7.0
		_mesh(parent, _sphere((0.17 - t * 0.04) * k, 12), mat, Vector3(0, (0.5 + t * 1.0) * k, (-0.1 + t * t * 0.55) * k))
	_mesh(parent, _sphere(0.34 * k), mat, Vector3(0, 1.42 * k, 0.36 * k), Vector3(-0.25, 0, 0), Vector3(1.35, 1.25, 0.22))
	_mesh(parent, _sphere(0.2 * k), mat, Vector3(0, 1.6 * k, 0.62 * k), Vector3(0.15, 0, 0), Vector3(1.0, 0.75, 1.7))
	for sx in [-1.0, 1.0]:
		_mesh(parent, _sphere(0.04 * k, 8), eye, Vector3(sx * 0.1 * k, 1.68 * k, 0.76 * k))
		var fang := _mesh(parent, _cone(0.0, 0.018 * k, 0.1 * k, 6), _bone_mat(), Vector3(sx * 0.06 * k, 1.5 * k, 0.88 * k))
		fang.rotation.x = PI


var _bone: StandardMaterial3D
func _bone_mat() -> StandardMaterial3D:
	if _bone == null:
		_bone = StandardMaterial3D.new()
		_bone.albedo_color = Color(0.92, 0.9, 0.82)
		_bone.roughness = 0.4
	return _bone


# =================================================================== côté jungle : la Salle des Quatre Serpents

func build_jungle(s: Node3D) -> void:
	# Couloir depuis la galerie de la jungle (ouverture à l'est, à mi-chemin)
	d._room(s, 2.2, 6.4, -13.5, -10.5, 0.0, 3.6, "mur", "sol", [["w", -12.0, 2.6, 3.2], ["e", -12.0, 2.6, 3.2]])
	d._torch(s, Vector3(4.3, 2.4, -13.45), Vector3(0, 0, 1), 1.1)
	d._room(s, 7.0, 25.0, -22.0, -2.0, 0.0, 9.0, "mur", "sol", [["w", -12.0, 2.6, 3.2]])
	for p in [Vector3(9.5, 0, -4.5), Vector3(22.5, 0, -4.5), Vector3(9.5, 0, -19.5), Vector3(22.5, 0, -19.5)]:
		d._box(s, Vector3(1.2, 9.0, 1.2), p + Vector3.UP * 4.5, d._mat("mur"))
		d._box(s, Vector3(1.6, 0.4, 1.6), p + Vector3.UP * 0.2, d._mat("sol"), false)
		d._box(s, Vector3(1.6, 0.4, 1.6), p + Vector3.UP * 8.8, d._mat("sol"), false)
	for p in [[Vector3(12.0, 3.2, -21.95), Vector3(0, 0, 1)], [Vector3(20.0, 3.2, -21.95), Vector3(0, 0, 1)], [Vector3(12.0, 3.2, -2.05), Vector3(0, 0, -1)], [Vector3(20.0, 3.2, -2.05), Vector3(0, 0, -1)]]:
		d._torch(s, p[0], p[1], 1.3)
	d._glow(s, Vector3(7.3, 2.0, -6.0), Vector3(1, 0, 0))
	d._glow(s, Vector3(7.3, 2.6, -18.0), Vector3(1, 0, 0))
	_fill(s, CENTER + Vector3.UP * 6.0, Color(0.8, 0.82, 0.75), 0.7, 17.0)
	# Grand serpent gravé sur le mur est, et l'inscription
	var relief := MeshInstance3D.new()
	var rq := QuadMesh.new()
	rq.size = Vector2(3.4, 3.4)
	relief.mesh = rq
	relief.material_override = d._glyph_mat("serpent")
	relief.position = Vector3(24.98, 5.2, -12.0)
	relief.rotation.y = -PI * 0.5
	s.add_child(relief)
	var txt := Label3D.new()
	txt.text = "« Que les quatre serpents contemplent l'Œil.\nMais aucun serpent ne tourne seul. »"
	txt.font_size = 40
	txt.pixel_size = 0.0028
	txt.modulate = Color(0.86, 0.78, 0.6)
	txt.outline_size = 0
	txt.position = Vector3(24.97, 2.7, -12.0)
	txt.rotation.y = -PI * 0.5
	s.add_child(txt)
	d._interactions.append({"id": "inscription_serpents", "pos": s.to_global(Vector3(23.4, 0, -12.0)), "radius": 1.6,
		"text": "E : lire l'inscription", "vr": "Gâchette : lire l'inscription", "call": func(): d._say("« Que les quatre serpents contemplent l'Œil. Mais aucun serpent ne tourne seul. » Les rigoles du sol mènent de chaque serpent à l'autel.", 6.0)})
	# Rai de lumière sur l'autel
	var ray := SpotLight3D.new()
	ray.light_color = Color(0.65, 0.8, 1.0)
	ray.light_energy = 2.6
	ray.spot_range = 12.0
	ray.spot_angle = 16.0
	ray.position = CENTER + Vector3.UP * 8.8
	ray.rotation.x = -PI * 0.5
	s.add_child(ray)
	# Autel : socle à deux degrés, couvercle gravé d'une lune, fragment caché dessous
	d._box(s, Vector3(2.6, 0.4, 2.6), CENTER + Vector3.UP * 0.2, d._mat("sol"))
	d._box(s, Vector3(1.7, 0.7, 1.7), CENTER + Vector3.UP * 0.75, d._mat("mur"))
	_lid = Node3D.new()
	_lid.name = "Couvercle_autel"
	s.add_child(_lid)
	d._box(_lid, Vector3(1.4, 0.16, 1.4), Vector3(0, 0.08, 0), d._mat("mur"), false)
	var lg := MeshInstance3D.new()
	var lq := QuadMesh.new()
	lq.size = Vector2(1.0, 1.0)
	lg.mesh = lq
	lg.material_override = d._glyph_mat("lune")
	lg.rotation.x = -PI * 0.5
	lg.position.y = 0.165
	_lid.add_child(lg)
	_frag = Node3D.new()
	_frag.name = "Troisieme_fragment"
	s.add_child(_frag)
	_mesh(_frag, _cone(0.16, 0.16, 0.035, 3), _jade_mat(1.6), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	_frag_light = OmniLight3D.new()
	_frag_light.light_color = Color(0.35, 1.0, 0.55)
	_frag_light.omni_range = 6.0
	_frag.add_child(_frag_light)
	d._interactions.append({"id": "fragment3", "pos": s.to_global(CENTER), "radius": 1.9,
		"text": "E : prendre le fragment", "vr": "Gâchette : prendre le fragment", "call": _take_fragment,
		"when": func(): return bool(d.state["enigme_serpents"]) and not bool(d.state["fragment3"])})
	# Les quatre serpents, et les rigoles qui les relient à l'autel
	var eye: Material = d._mat("oeil")
	for i in range(STATUES.size()):
		var p: Vector3 = STATUES[i]
		var to_c: Vector3 = (CENTER - p) * Vector3(1, 0, 1)
		var dir: Vector3 = to_c.normalized()
		var root := Node3D.new()
		root.name = "Serpent_%d" % i
		s.add_child(root)
		root.position = p
		d._box(root, Vector3(1.3, 0.8, 1.3), Vector3(0, 0.4, 0), d._mat("mur"))
		d._box(root, Vector3(1.0, 2.0, 1.0), Vector3(0, 1.8, 0), d._mat("mur"), true).visible = false
		d._box(root, Vector3(1.5, 0.12, 1.5), Vector3(0, 0.86, 0), d._mat("sol"), false)
		var pivot := Node3D.new()
		pivot.name = "Tete"
		pivot.position = Vector3(0, 0.92, 0)
		root.add_child(pivot)
		_snake(pivot, 1.0, _patina_mat(), eye)
		_heads.append(pivot)
		_base_yaw.append(atan2(dir.x, dir.z))
		var a: Vector3 = p + dir * 0.8
		var b: Vector3 = CENTER - dir * 1.35
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(0.08, 0.12, 0.1)
		cm.emission_enabled = true
		cm.emission = Color(0.3, 1.0, 0.55)
		cm.emission_energy_multiplier = 0.0
		var ch := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.16, 0.03, a.distance_to(b))
		ch.mesh = cb
		ch.material_override = cm
		ch.position = (a + b) * 0.5 + Vector3.UP * 0.012
		ch.rotation.y = atan2(dir.x, dir.z)
		s.add_child(ch)
		_channels.append(cm)
		d._interactions.append({"id": "serpent_%d" % i, "pos": s.to_global(p), "radius": 1.9,
			"text": "E : tourner le serpent", "vr": "Gâchette : tourner le serpent", "call": turn.bind(i),
			"when": func(): return not bool(d.state["enigme_serpents"])})
	# Deux gardiens de pierre… qui ne dorment que d'un œil
	for wp in WARDENS:
		var before: int = d._body.get_child_count()
		d._statue(s, wp, Vector3(-1, 0, 0))
		var shapes: Array = []
		for k in range(before, d._body.get_child_count()):
			shapes.append(d._body.get_child(k))
		_wardens.append({"root": s.get_child(s.get_child_count() - 1), "shapes": shapes, "pos": wp})


## Lumière d'appoint douce et sans ombre : la lumière des flammes renvoyée par la pierre.
func _fill(s: Node3D, pos: Vector3, col: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 0.6
	l.light_specular = 0.1
	l.shadow_enabled = false
	l.position = pos
	s.add_child(l)


func _refresh_channels() -> void:
	for i in range(_channels.size()):
		(_channels[i] as StandardMaterial3D).emission_energy_multiplier = 2.4 if orient(i) == 0 else 0.0


## Tourner un serpent d'un quart de tour : son voisin (sens des aiguilles d'une montre) suit.
func turn(i: int) -> void:
	if _turning or bool(d.state["enigme_serpents"]):
		return
	_turning = true
	var j: int = (i + 1) % 4
	_set_orient(i, orient(i) + 1)
	_set_orient(j, orient(j) + 1)
	var tw := create_tween().set_parallel(true)
	for k in [i, j]:
		var h: Node3D = _heads[k]
		tw.tween_property(h, "rotation:y", h.rotation.y - PI * 0.5, 0.8).set_trans(Tween.TRANS_SINE)
	if main.combat_v28 != null:
		main.combat_v28.puff((_heads[i] as Node3D).global_position, Color(0.6, 0.56, 0.5))
	await tw.finished
	_refresh_channels()
	_turning = false
	var n: int = facing_count()
	if n == 4:
		_solve()
	else:
		d._say("Pierre contre pierre : deux serpents pivotent. (%d sur 4 regardent l'autel)" % n, 3.0)


func _solve() -> void:
	d.state["enigme_serpents"] = true
	d._say("Les quatre serpents fixent l'autel. Leurs yeux s'embrasent… et le couvercle glisse dans un grondement !", 6.0)
	var tw := create_tween()
	tw.tween_property(_lid, "position", Vector3(CENTER.x + 1.25, 0.95, CENTER.z), 2.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_lid, "rotation:z", -0.32, 2.0)
	_frag.visible = true
	_frag.position = Vector3(CENTER.x, 0.8, CENTER.z)
	var tw2 := create_tween()
	tw2.tween_interval(1.4)
	tw2.tween_property(_frag, "position:y", 1.55, 2.0).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_property(_frag_light, "light_energy", 2.0, 2.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(_lid.global_position, Color(0.62, 0.58, 0.52))


func _take_fragment() -> void:
	var got: int = main.inventory_v28.add("fragment_amulette", 1)
	if got <= 0:
		d._say("Ton sac est plein ! Fais un peu de place pour le fragment.", 4.0)
		return
	d.state["fragment3"] = true
	_frag.visible = false
	_frag_light.light_energy = 0.0
	d._say("Le TROISIÈME fragment de l'amulette, gravé d'une lune ! Avec les deux autres, la Porte du Serpent t'attend, côté village…", 6.0)
	await get_tree().create_timer(2.4).timeout
	_ambush()


## Les deux statues de gardiens s'animent quand on prend le fragment.
func _ambush() -> void:
	var s: Node3D = d.sections["jungle"]
	for w in _wardens:
		var at: Vector3 = s.to_global(w["pos"]) + Vector3.UP * 0.05
		if main.combat_v28 != null:
			main.combat_v28.puff(at + Vector3.UP * 1.2, Color(0.6, 0.58, 0.52))
		if main.monstres_v36 != null:
			var m: Node3D = main.monstres_v36.spawn_extra("gardien", at)
			m.set_meta("salle", "serpents")
	apply_state()
	d._say("Les deux gardiens de pierre s'arrachent à leurs socles !", 4.0)


# =================================================================== côté village : la Porte du Serpent

func build_door(s: Node3D, p: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Porte_du_Serpent"
	s.add_child(root)
	root.position = p
	_door_l = _door_half(root, -1.0)
	_door_r = _door_half(root, 1.0)
	# Serpent de bronze enroulé autour de la serrure : chaque anneau suit son battant.
	for i in range(28):
		var t: float = float(i) / 27.0
		var a: float = t * TAU * 1.6
		var r: float = 1.75 - t * 0.7
		var pos := Vector3(cos(a) * r, 3.0 + sin(a) * r, 0.31)
		var half: Node3D = _door_l if pos.x < 0.0 else _door_r
		_mesh(half, _sphere(0.2 - t * 0.07, 12), d._mat("bronze"), pos - half.position)
	# La serrure : un médaillon avec l'œil et les trois empreintes
	_lock = Node3D.new()
	_lock.name = "Serrure"
	_lock.position = Vector3(0, 3.0, 0.3)
	root.add_child(_lock)
	_mesh(_lock, _cone(0.92, 0.92, 0.1, 32), d._mat("bronze"), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	_eye_mat = (d._mat("oeil") as StandardMaterial3D).duplicate()
	_mesh(_lock, _sphere(0.22), _eye_mat, Vector3(0, 0.22, 0.07), Vector3.ZERO, Vector3(1, 0.7, 0.6))
	for k in range(3):
		var x: float = -0.42 + k * 0.42
		_mesh(_lock, _cone(0.14, 0.14, 0.04, 16), d._mat("noir"), Vector3(x, -0.38, 0.05), Vector3(PI * 0.5, 0, 0))
		var jade := _mesh(_lock, _cone(0.12, 0.12, 0.05, 3), _jade_mat(1.2), Vector3(x, -0.38, 0.08), Vector3(PI * 0.5, 0, 0))
		jade.visible = false
		_slots.append(jade)
	d._interactions.append({"id": "porte_serpent", "pos": s.to_global(p + Vector3(0, 0, 1.2)), "radius": 2.6,
		"text": "E : examiner la Porte du Serpent", "vr": "Gâchette : examiner la porte", "call": _use_door,
		"when": func(): return not bool(d.state["porte_serpent"])})


func _door_half(root: Node3D, side: float) -> Node3D:
	var h := Node3D.new()
	h.name = "Battant_" + ("gauche" if side < 0.0 else "droit")
	h.position = Vector3(side * 1.25, 0, 0)
	root.add_child(h)
	d._box(h, Vector3(2.5, 6.0, 0.5), Vector3(0, 3.0, 0), d._mat("mur"), false)
	d._box(h, Vector3(0.05, 5.6, 0.52), Vector3(-side * 1.22, 3.0, 0), d._mat("noir"), false)
	var body := StaticBody3D.new()
	body.name = "Corps"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.5, 6.0, 0.5)
	cs.shape = bs
	cs.position = Vector3(0, 3.0, 0)
	body.add_child(cs)
	h.add_child(body)
	return h


func _use_door() -> void:
	var n: int = main.inventory_v28.count("fragment_amulette")
	if n < 3:
		d._say("La Porte du Serpent. Un serpent de bronze s'enroule autour d'un œil rouge. Trois empreintes creuses attendent les fragments d'une amulette. (%d sur 3)" % n, 6.0)
		return
	d._busy = true
	main.inventory_v28.remove("fragment_amulette", 3)
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("pierre_glisse")
	d._say("Tu poses les trois fragments dans les empreintes… Ils s'y enfoncent d'eux-mêmes.", 4.0)
	for k in range(_slots.size()):
		await get_tree().create_timer(0.45).timeout
		(_slots[k] as Node3D).visible = true
		if main.combat_v28 != null:
			main.combat_v28.puff((_slots[k] as Node3D).global_position, Color(0.4, 1.0, 0.6))
	await get_tree().create_timer(0.8).timeout
	_set_eye(true)
	d._say("L'œil du serpent passe du rouge au vert…", 3.0)
	var tw := create_tween()
	tw.tween_property(_lock, "rotation:z", TAU, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_lock, "position:z", -0.2, 0.6)
	await tw.finished
	_lock.visible = false
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(_door_l, "position:x", -1.25 - 2.6, 4.0).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_door_r, "position:x", 1.25 + 2.6, 4.0).set_trans(Tween.TRANS_SINE)
	if main.combat_v28 != null:
		for k in range(5):
			main.combat_v28.puff(_door_l.get_parent().global_position + (_door_l.get_parent() as Node3D).global_basis * Vector3(-2.0 + k, 0.3, 0.6), Color(0.62, 0.58, 0.52))
	await tw2.finished
	(_door_l.get_node("Corps") as StaticBody3D).collision_layer = 0
	(_door_r.get_node("Corps") as StaticBody3D).collision_layer = 0
	d.state["porte_serpent"] = true
	var got: int = main.inventory_v28.add("amulette_serpent", 1)
	if got <= 0:
		main.inventory_v28.spawn_pickup("amulette_serpent", "amulette_serpent", 1, main._player_pos_v27() + Vector3.UP * 0.05)
	d._busy = false
	d._say("La Porte du Serpent s'ouvre ! Les trois fragments se sont soudés : l'AMULETTE DU SERPENT. Son œil vert éclaire les ténèbres.", 7.0)


# =================================================================== le Sanctuaire de l'Œil

func build_sanctuary(s: Node3D) -> void:
	var y0: float = SANCT_Y
	d._room(s, -10.5, 10.5, -94.0, -73.6, y0, 12.0, "mur", "sol", [["s", 0.0, 5.0, 6.0], ["n", 0.0, 4.6, 4.8]])
	for x in [-7.0, 7.0]:
		for z in [-78.0, -84.0, -90.0]:
			var p := Vector3(x, y0, z)
			d._box(s, Vector3(1.3, 12.0, 1.3), p + Vector3.UP * 6.0, d._mat("mur"))
			d._box(s, Vector3(1.8, 0.45, 1.8), p + Vector3.UP * 0.22, d._mat("sol"), false)
			d._box(s, Vector3(1.8, 0.45, 1.8), p + Vector3.UP * 11.78, d._mat("sol"), false)
			if z != -84.0:
				d._torch(s, p + Vector3(-signf(x) * 0.7, 3.4, 0), Vector3(-signf(x), 0, 0), 1.4)
	_great_serpent(s)
	_fountain(s, Vector3(-9.6, y0, -80.0))
	_offering_chest(s, Vector3(8.4, y0, -80.0))
	for p in [Vector3(-4.0, y0, -76.5), Vector3(4.0, y0, -76.5), Vector3(-4.5, y0, -92.0), Vector3(4.5, y0, -92.0)]:
		d._brazier_fixed(s, p)
	d._glow(s, Vector3(-10.2, y0 + 3.0, -88.0), Vector3(1, 0, 0))
	d._glow(s, Vector3(10.2, y0 + 2.4, -88.0), Vector3(-1, 0, 0))
	d._drips(s, Vector3(0.0, y0 + 11.6, -85.0))
	_fill(s, Vector3(0.0, y0 + 7.0, -83.0), Color(0.75, 0.85, 0.7), 1.1, 24.0)


func _great_serpent(s: Node3D) -> void:
	var c: Vector3 = SERPENT_C
	var mat: Material = _patina_mat()
	# Bassin d'eau, margelle, rocher
	var pool := MeshInstance3D.new()
	var pm := _cone(3.7, 3.7, 0.02, 40)
	pool.mesh = pm
	pool.material_override = d._mat("eau")
	pool.position = c + Vector3.UP * 0.05
	s.add_child(pool)
	for k in range(22):
		var a: float = TAU * k / 22.0
		d._box(s, Vector3(1.15, 0.4, 0.45), c + Vector3(cos(a) * 3.9, 0.2, sin(a) * 3.9), d._mat("sol"), false, Vector3(0, -a + PI * 0.5, 0))
	var rock := MeshInstance3D.new()
	rock.mesh = Rocks.shape(3801, Vector3(3.6, 1.4, 3.6), 0.6, 0.15)
	rock.material_override = Rocks.material(Color(0.5, 0.5, 0.47), 0.1, 0.3)
	rock.position = c + Vector3.UP * 0.4
	s.add_child(rock)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 3.0
	cyl.height = 9.0
	cs.shape = cyl
	d._body.add_child(cs)
	cs.global_position = s.to_global(c + Vector3.UP * 4.5)
	# Le corps en spirale, puis le cou qui se dresse vers l'entrée
	var last := Vector3.ZERO
	for i in range(54):
		var t: float = float(i) / 53.0
		var a2: float = t * TAU * 2.3 + PI * 0.5
		var r: float = 2.4 - t * 1.6
		last = c + Vector3(cos(a2) * r, 1.0 + t * 4.4, sin(a2) * r)
		_mesh(s, _sphere(0.78 - t * 0.3, 18), mat, last)
	var head := c + Vector3(0, 8.6, 2.4)
	for i in range(1, 12):
		var t2: float = float(i) / 11.0
		var p: Vector3 = last.lerp(head + Vector3(0, -0.6, -0.9), t2) + Vector3(0, sin(t2 * PI) * 0.9, 0)
		_mesh(s, _sphere(0.48 - t2 * 0.08, 18), mat, p)
	_mesh(s, _sphere(1.5, 24), mat, head + Vector3(0, -0.9, -1.2), Vector3(-0.3, 0, 0), Vector3(1.4, 1.3, 0.32))
	_mesh(s, _sphere(0.85, 24), mat, head, Vector3(0.35, 0, 0), Vector3(1.0, 0.72, 1.75))
	var eyes := _jade_mat(5.0)
	for sx in [-1.0, 1.0]:
		_mesh(s, _sphere(0.15), eyes, head + Vector3(sx * 0.42, 0.28, 0.85))
		var fang := _mesh(s, _cone(0.0, 0.07, 0.42, 8), _bone_mat(), head + Vector3(sx * 0.25, -0.62, 1.15))
		fang.rotation.x = PI
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 1.0, 0.6)
	glow.light_energy = 2.6
	glow.omni_range = 15.0
	glow.position = head + Vector3(0, 0.3, 1.8)
	s.add_child(glow)
	# Reflets de l'eau du bassin sur les écailles
	for k in range(3):
		var a3: float = TAU * k / 3.0 + 0.5
		var wl := OmniLight3D.new()
		wl.light_color = Color(0.35, 0.75, 0.85)
		wl.light_energy = 1.2
		wl.omni_range = 6.0
		wl.position = c + Vector3(cos(a3) * 4.4, 0.6, sin(a3) * 4.4)
		s.add_child(wl)
	var ray := SpotLight3D.new()
	ray.light_color = Color(0.6, 0.78, 1.0)
	ray.light_energy = 4.0
	ray.spot_range = 16.0
	ray.spot_angle = 24.0
	ray.position = c + Vector3(0, 11.8, 0)
	ray.rotation.x = -PI * 0.5
	s.add_child(ray)


func _fountain(s: Node3D, p: Vector3) -> void:
	# Vasque contre le mur ouest, alimentée par une gueule de serpent
	d._box(s, Vector3(1.0, 0.7, 0.25), p + Vector3(0.5, 0.35, -1.1), d._mat("sol"))
	d._box(s, Vector3(1.0, 0.7, 0.25), p + Vector3(0.5, 0.35, 1.1), d._mat("sol"))
	d._box(s, Vector3(0.25, 0.7, 2.45), p + Vector3(1.0, 0.35, 0), d._mat("sol"))
	var water := MeshInstance3D.new()
	var wq := PlaneMesh.new()
	wq.size = Vector2(0.85, 1.95)
	water.mesh = wq
	water.material_override = d._mat("eau")
	water.position = p + Vector3(0.45, 0.6, 0)
	s.add_child(water)
	var spout := Node3D.new()
	spout.position = p + Vector3(0.05, 1.7, 0)
	spout.rotation.y = PI * 0.5
	s.add_child(spout)
	_mesh(spout, _sphere(0.22), _patina_mat(), Vector3.ZERO, Vector3(0.3, 0, 0), Vector3(1.0, 0.75, 1.6))
	for sx in [-1.0, 1.0]:
		_mesh(spout, _sphere(0.04, 8), _jade_mat(3.0), Vector3(sx * 0.11, 0.08, 0.14))
	var stream := CPUParticles3D.new()
	stream.amount = 40
	stream.lifetime = 0.6
	stream.direction = Vector3(1, -0.2, 0)
	stream.spread = 4.0
	stream.initial_velocity_min = 0.9
	stream.initial_velocity_max = 1.1
	stream.gravity = Vector3(0, -9.8, 0)
	var q := SphereMesh.new()
	q.radius = 0.025
	q.height = 0.05
	q.material = d._mat("eau")
	stream.mesh = q
	stream.position = p + Vector3(0.35, 1.6, 0)
	s.add_child(stream)
	var light := OmniLight3D.new()
	light.light_color = Color(0.45, 0.9, 1.0)
	light.light_energy = 1.0
	light.omni_range = 4.0
	light.position = p + Vector3(0.6, 1.0, 0)
	s.add_child(light)
	d._interactions.append({"id": "fontaine", "pos": s.to_global(p + Vector3(1.5, 0, 0)), "radius": 1.7,
		"text": "E : boire à la fontaine", "vr": "Gâchette : boire à la fontaine", "call": _drink})


func _drink() -> void:
	var hero: Node = main.hero_v28
	if hero != null:
		hero.hp = hero.HP_MAX
		hero.stamina = hero.STAMINA_MAX
		hero.health_changed.emit(hero.hp, hero.HP_MAX)
	d._say("L'eau est glacée et a un goût de pierre… Tes forces reviennent d'un coup. Tous tes cœurs sont pleins.", 4.0)


func _offering_chest(s: Node3D, p: Vector3) -> void:
	d._box(s, Vector3(1.6, 0.5, 1.4), p + Vector3.UP * 0.25, d._mat("sol"))
	_sanct_chest = Node3D.new()
	_sanct_chest.name = "Coffre_offrandes"
	s.add_child(_sanct_chest)
	_sanct_chest.position = p + Vector3.UP * 0.5
	_sanct_chest.rotation.y = -PI * 0.5
	d._box(_sanct_chest, Vector3(1.0, 0.55, 0.65), Vector3(0, 0.275, 0), d._mat("bois"), false)
	for x in [-0.36, 0.36]:
		d._box(_sanct_chest, Vector3(0.06, 0.57, 0.67), Vector3(x, 0.275, 0), d._mat("bronze"), false)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.55, -0.32)
	_sanct_chest.add_child(hinge)
	d._box(hinge, Vector3(1.0, 0.18, 0.65), Vector3(0, 0.09, 0.32), d._mat("bois"), false)
	d._interactions.append({"id": "coffre_sanctuaire", "pos": s.to_global(p), "radius": 2.0,
		"text": "E : ouvrir le coffre des offrandes", "vr": "Gâchette : ouvrir le coffre", "call": _open_offering,
		"when": func(): return not bool(d.state["coffre_sanctuaire"])})


func _open_offering() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 50], ["piece_or", 3], ["rubis", 1]]):
		d._say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	d.state["coffre_sanctuaire"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("coffre")
	var hinge: Node3D = _sanct_chest.get_node("Charniere")
	create_tween().tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 50)
	var o: int = main.inventory_v28.add("piece_or", 3)
	var r: int = main.inventory_v28.add("rubis", 1)
	d._say("Les offrandes des Anciens : %d pièces, %d pièces d'or%s." % [a, o, " et un rubis" if r > 0 else ""], 5.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(_sanct_chest.global_position + Vector3.UP * 0.8, Color(1.0, 0.85, 0.4))


# =================================================================== l'amulette éclaire les ténèbres

func _process(delta: float) -> void:
	if d == null or main == null or not main.game_started:
		return
	if _frag != null and _frag.visible:
		_frag.rotation.y += delta * 1.4
	var on: bool = bool(d.inside) and main.inventory_v28 != null and main.inventory_v28.count("amulette_serpent") > 0
	if on and _amu_light == null:
		_amu_light = OmniLight3D.new()
		_amu_light.name = "Lueur_amulette"
		_amu_light.light_color = Color(0.55, 1.0, 0.7)
		_amu_light.light_energy = 1.3
		_amu_light.omni_range = 7.5
		_amu_light.omni_attenuation = 1.2
		add_child(_amu_light)
	if _amu_light != null:
		_amu_light.visible = on
		if on:
			_amu_light.global_position = main._player_pos_v27() + Vector3.UP * 1.3

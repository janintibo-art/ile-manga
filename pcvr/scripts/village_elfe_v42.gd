extends Node3D
## V42 : la vie du village elfe (le Bois-Doré).
##  - Sept habitants nommés (herboriste, boulangère, garde, ancien, petite Nimiel, musicien,
##    tisserande), chacun dans son coin, avec sa boutique ou sa petite quête.
##  - Dix elfes de passage : sept flânent sur la place, trois vivent là-haut et vont d'une
##    plate-forme à l'autre par les passerelles.
##  - Le marché (herboristerie, boulangerie), la harpe de Caelan, le cercle des contes de
##    Faelar, le métier à tisser d'Ilyria, des guirlandes de lumière, des papillons, des
##    lucioles, et les elfes qui bavardent entre eux.
## Les déplacements suivent des points reliés en graphe : un anneau autour de la place
## (r 11, entre les bancs et les arbres-maisons), et au ciel les plates-formes et passerelles.

const Habitants = preload("res://scripts/pnj/elfes_habitants_v42.gd")
const PnjScript = preload("res://scripts/pnj/pnj_v31.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const RING_R: float = 11.0
const SLEEP_FAR: float = 95.0
const SKY_PASSANTS := [2, 3, 9]

var e: Node3D                       # elfes_v41
var G: Vector3
var villagers: Array = []
var by_id: Dictionary = {}
var ground: Dictionary = {}         # nom -> position monde
var ground_graph: Dictionary = {}
var sky: Dictionary = {}
var sky_graph: Dictionary = {}
var harp_pos: Vector3
var _butterflies: Array = []
var _clock: float = 0.0
var _chat_clock: float = 8.0
var _note_clock: float = 0.0
var _pending_reply: Array = []      # [npc, texte, délai]


func build(elfes: Node3D) -> void:
	e = elfes
	G = e.ile.glade_world()
	_make_ground_points()
	_make_sky_points()
	_build_stall("herboristerie", deg_to_rad(43.5))
	_build_stall("boulangerie", deg_to_rad(133.5))
	_build_harp()
	_build_story_circle()
	_build_loom()
	_build_garlands()
	_build_fireflies()
	_build_butterflies()
	_spawn_all()
	print("ILE_MANGA_V42: village elfe, ", villagers.size(), " habitants")


# =================================================================== points de passage

func _at(angle_deg: float, r: float) -> Vector3:
	var a: float = deg_to_rad(angle_deg)
	var p := Vector3(G.x + cos(a) * r, 0.0, G.z + sin(a) * r)
	p.y = e.ile.height(p.x, p.z)
	return p


func _link(graph: Dictionary, a: String, b: String) -> void:
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


func _make_ground_points() -> void:
	# Anneau autour de la place : 12 points, dans les allées entre bancs et massifs.
	for k in range(12):
		ground["r%d" % k] = _at(13.5 + 30.0 * k, RING_R)
	for k in range(12):
		_link(ground_graph, "r%d" % k, "r%d" % ((k + 1) % 12))
	# Sous l'Arbre-Mère (trois allées qui traversent la couronne de bancs)
	for pair in [["i0", 43.5, 1], ["i1", 163.5, 5], ["i2", 283.5, 9]]:
		ground[pair[0]] = _at(pair[1], 5.6)
		_link(ground_graph, pair[0], "r%d" % pair[2])
	# La Fontaine de lune (centre à 13,5 m au sud de l'Arbre)
	ground["fe"] = Vector3(G.x + 3.2, G.y, G.z + 13.5)
	ground["fo"] = Vector3(G.x - 3.2, G.y, G.z + 13.5)
	_link(ground_graph, "fe", "r2")
	_link(ground_graph, "fo", "r3")
	# Le marché, la harpe, les contes, la garde
	ground["herbo_front"] = _at(36.0, 12.6)
	ground["herbo_etal"] = _at(43.5, 15.4)
	ground["herbo_cote"] = _at(55.5, 14.2)
	_link(ground_graph, "herbo_front", "r1")
	_link(ground_graph, "herbo_etal", "herbo_cote")
	_link(ground_graph, "herbo_cote", "r1")
	ground["boul_front"] = _at(141.0, 12.6)
	ground["boul_etal"] = _at(133.5, 15.4)
	ground["boul_cote"] = _at(121.5, 14.2)
	_link(ground_graph, "boul_front", "r4")
	_link(ground_graph, "boul_etal", "boul_cote")
	_link(ground_graph, "boul_cote", "r4")
	ground["harpe"] = _at(73.5, 14.6)
	ground["harpe_ecoute"] = _at(62.0, 13.2)
	_link(ground_graph, "harpe", "r2")
	_link(ground_graph, "harpe_ecoute", "r2")
	ground["conte"] = _at(343.5, 14.6)
	ground["conte_bord"] = _at(334.0, 13.0)
	_link(ground_graph, "conte", "r11")
	_link(ground_graph, "conte_bord", "r11")
	ground["poste"] = _at(193.5, 14.5)
	ground["guet"] = _at(223.5, 14.5)
	_link(ground_graph, "poste", "r6")
	_link(ground_graph, "guet", "r7")


## Au ciel : sur chaque plate-forme, des points en arc (la maison est évitée), et le milieu
## de chaque passerelle.
func _make_sky_points() -> void:
	var n: int = e.tree_spots.size()
	for i in range(n):
		var t: Dictionary = e.tree_spots[i]
		var p: Vector3 = t["pos"]
		var a_out: float = float(t["angle"])
		var H: float = p.y + e.PLATFORM_H
		var pn: Vector3 = (e.tree_spots[(i + 1) % n] as Dictionary)["pos"]
		var pp: Vector3 = (e.tree_spots[(i + n - 1) % n] as Dictionary)["pos"]
		var rel := {
			"porte": [-0.455, 5.23],
			"o": [deg_to_rad(-55.0), 5.0],
			"p": [wrapf(atan2(pp.z - p.z, pp.x - p.x) - a_out, -PI, PI), 5.0],
			"in": [PI, 5.0],
			"n": [wrapf(atan2(pn.z - p.z, pn.x - p.x) - a_out, -PI, PI), 5.0],
			"e": [deg_to_rad(55.0), 5.0],
		}
		var order: Array = rel.keys()
		order.sort_custom(func(x, y): return fposmod(float(rel[x][0]), TAU) < fposmod(float(rel[y][0]), TAU))
		var prev_key: String = ""
		for key in order:
			var a: float = a_out + float(rel[key][0])
			var r: float = float(rel[key][1])
			var name_k: String = "t%d_%s" % [i, key]
			sky[name_k] = Vector3(p.x + cos(a) * r, H, p.z + sin(a) * r)
			if prev_key != "":
				_link(sky_graph, prev_key, name_k)
			prev_key = name_k
	for i in range(n):
		var pa: Vector3 = (e.tree_spots[i] as Dictionary)["pos"]
		var pb: Vector3 = (e.tree_spots[(i + 1) % n] as Dictionary)["pos"]
		var mid: Vector3 = (pa + pb) * 0.5
		mid.y = (pa.y + pb.y) * 0.5 + e.PLATFORM_H - 0.7
		sky["b%d" % i] = mid
		_link(sky_graph, "t%d_n" % i, "b%d" % i)
		_link(sky_graph, "b%d" % i, "t%d_p" % ((i + 1) % n))
	# Le métier à tisser d'Ilyria, sur la plate-forme de l'arbre 1 (derrière la fontaine)
	var t1: Dictionary = e.tree_spots[1]
	var p1: Vector3 = t1["pos"]
	var am: float = float(t1["angle"]) + deg_to_rad(90.0)
	sky["metier"] = Vector3(p1.x + cos(am) * 4.3, p1.y + e.PLATFORM_H, p1.z + sin(am) * 4.3)
	_link(sky_graph, "metier", "t1_e")
	_link(sky_graph, "metier", "t1_n")


## Sous-graphe limité à quelques points (et leurs liens entre eux).
func _sub(points: Dictionary, graph: Dictionary, keys: Array) -> Array:
	var pts := {}
	var g := {}
	for k in keys:
		pts[k] = points[k]
	for k in keys:
		g[k] = (graph.get(k, []) as Array).filter(func(x): return keys.has(x))
	return [pts, g]


# =================================================================== les habitants

func _spawn_all() -> void:
	var all_ground: Array = ground.keys().filter(func(k): return not str(k).ends_with("_etal") and k != "harpe" and k != "conte" and k != "poste")
	var homes := {
		"herboristerie": [["herbo_etal", "herbo_cote", "r1", "r2", "herbo_front"], "herbo_etal", ground, ground_graph],
		"boulangerie": [["boul_etal", "boul_cote", "r4", "r3", "boul_front"], "boul_etal", ground, ground_graph],
		"garde": [["poste", "guet", "r5", "r6", "r7", "r8"], "poste", ground, ground_graph],
		"ancien": [["conte", "conte_bord", "r11", "r0"], "conte", ground, ground_graph],
		"fontaine": [["fe", "fo", "r1", "r2", "r3", "r4", "i0", "harpe_ecoute"], "fe", ground, ground_graph],
		"musicien": [["harpe", "harpe_ecoute", "r2", "fe"], "harpe", ground, ground_graph],
		"tisserande": [["metier", "t1_e", "t1_n", "t1_in", "t1_p", "t1_o"], "metier", sky, sky_graph],
	}
	for entry in Habitants.NAMED:
		var h: Array = homes[str(entry["coin"])]
		var sub: Array = _sub(h[2], h[3], h[0])
		_spawn(Habitants.complete(entry["data"]), sub[0], sub[1], str(h[1]))
	var gi: int = 0
	var starts: Array = ["r0", "r3", "r5", "r8", "i1", "fo", "r10"]
	var sky_starts: Array = ["t0_in", "t2_e", "t4_o"]
	var si: int = 0
	for n in range(Habitants.PASSANTS.size()):
		var d: Dictionary = Habitants.passant(n)
		if SKY_PASSANTS.has(n):
			_spawn(d, sky.duplicate(), sky_graph.duplicate(true), str(sky_starts[si % sky_starts.size()]))
			si += 1
		else:
			var sub2: Array = _sub(ground, ground_graph, all_ground)
			_spawn(d, sub2[0], sub2[1], str(starts[gi % starts.size()]))
			gi += 1
	# Où regarder quand ils sont à leur poste
	_face("aelwen", "herbo_etal", G)
	_face("sylwen", "boul_etal", G)
	_face("caelan", "harpe", sky["t1_in"])
	_face("faelar", "conte", G)
	_face("thalion", "poste", e.ile.dock_start)
	_face("ilyria", "metier", _loom_pos())


func _spawn(data: Dictionary, pts: Dictionary, graph: Dictionary, start: String) -> void:
	var npc: Node3D = PnjScript.new()
	e.main.add_child(npc)
	npc.setup(e.main, data, pts, graph, start)
	npc.sleep_far = SLEEP_FAR
	npc.idle_clock = randf_range(2.0, 12.0)
	var saved: Variant = e.main.pending_pnj_v31.get(str(data["id"]), {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	e.main.npcs_v31.append(npc)
	villagers.append(npc)
	by_id[str(data["id"])] = npc


func _face(id: String, point: String, target: Vector3) -> void:
	if by_id.has(id):
		by_id[id].face_at[point] = target


func quest_state(id: String) -> String:
	if not by_id.has(id):
		return ""
	return str(by_id[id].brain.memoire.get("quete", ""))


# =================================================================== décor du village

func _box(size: Vector3) -> BoxMesh:
	return e._box_mesh(size)


func _cloth(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _shiny(c: Color, glow: float = 0.3, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = 0.15
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = glow
	return m


## Un étal de marché : comptoir, quatre poteaux, auvent rayé, enseigne et marchandises.
func _build_stall(kind: String, angle: float) -> void:
	var u := Vector3(cos(angle), 0, sin(angle))
	var c: Vector3 = G + u * 14.0
	c.y = e.ile.height(c.x, c.z)
	var root := Node3D.new()
	root.name = "Etal_" + kind
	add_child(root)
	root.global_position = c
	root.rotation.y = atan2(-u.x, -u.z)            # +Z local vers la place
	var xf: Transform3D = root.global_transform
	var herb: bool = kind == "herboristerie"
	var stripe_a: Color = Color(0.32, 0.55, 0.36) if herb else Color(0.85, 0.55, 0.22)
	var stripe_b: Color = Color(0.92, 0.9, 0.8)
	# Comptoir (solide) avec un plateau plus clair
	e._solid(Vector3(3.0, 0.95, 0.7), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.475, 0)), e._mat("bois"))
	e._mesh(root, _box(Vector3(3.15, 0.07, 0.85)), e._mat("bois"), Vector3(0, 0.98, 0.02))
	e._mesh(root, _box(Vector3(3.05, 0.2, 0.04)), _cloth(stripe_a), Vector3(0, 0.8, 0.37))
	# Poteaux et auvent rayé qui descend vers la place
	for sx in [-1.45, 1.45]:
		e._mesh(root, e._cyl(0.05, 0.06, 2.7, 8), e._mat("bois"), Vector3(sx, 1.35, 0.45))
		e._mesh(root, e._cyl(0.05, 0.06, 3.0, 8), e._mat("bois"), Vector3(sx, 1.5, -2.0))
	for k in range(6):
		var x: float = -1.5 + 0.25 + k * 0.5
		var stripe: MeshInstance3D = e._mesh(root, _box(Vector3(0.5, 0.03, 2.9)), _cloth(stripe_a if k % 2 == 0 else stripe_b), Vector3(x, 2.85, -0.72))
		stripe.rotation.x = -0.14
	for k in range(6):
		var x2: float = -1.5 + 0.25 + k * 0.5
		e._mesh(root, _box(Vector3(0.5, 0.26, 0.02)), _cloth(stripe_a if k % 2 == 0 else stripe_b), Vector3(x2, 2.66, 0.75))
		e._mesh(root, e._cyl(0.0, 0.07, 0.14, 3), _cloth(stripe_b if k % 2 == 0 else stripe_a), Vector3(x2, 2.47, 0.75), Vector3(PI, 0, 0), Vector3(1.0, 1.0, 0.25))
	# Étagère du fond
	e._mesh(root, _box(Vector3(2.7, 0.06, 0.4)), e._mat("bois"), Vector3(0, 1.4, -2.0))
	e._mesh(root, _box(Vector3(2.7, 0.06, 0.4)), e._mat("bois"), Vector3(0, 1.0, -2.0))
	# Enseigne
	var plaque := Label3D.new()
	plaque.text = "Herboristerie" if herb else "Boulangerie"
	plaque.font_size = 64
	plaque.pixel_size = 0.0045
	plaque.outline_size = 14
	plaque.modulate = Color(1.0, 0.92, 0.7)
	plaque.outline_modulate = Color(0.25, 0.16, 0.08)
	plaque.position = Vector3(0, 2.3, 0.78)
	root.add_child(plaque)
	e._mesh(root, _box(Vector3(1.9, 0.36, 0.05)), e._mat("bois"), Vector3(0, 2.3, 0.74))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4200 if herb else 4201
	if herb:
		# Fioles de couleur, pots d'herbes, bouquets séchés suspendus
		var cols := [Color(0.3, 0.8, 0.45), Color(0.6, 0.4, 0.85), Color(0.95, 0.65, 0.2), Color(0.4, 0.75, 0.95)]
		for k in range(9):
			var x3: float = -1.3 + k * 0.32
			var col: Color = cols[k % cols.size()]
			e._mesh(root, e._sphere(0.07, 10), _shiny(col, 0.6, 0.8), Vector3(x3, 1.09, 0.12 - (k % 2) * 0.18))
			e._mesh(root, e._cyl(0.02, 0.02, 0.08, 6), _shiny(Color(0.85, 0.92, 0.95), 0.1, 0.6), Vector3(x3, 1.19, 0.12 - (k % 2) * 0.18))
			e._mesh(root, e._cyl(0.024, 0.024, 0.03, 6), e._mat("bois"), Vector3(x3, 1.24, 0.12 - (k % 2) * 0.18))
		for k in range(5):
			var x4: float = -1.2 + k * 0.6
			e._mesh(root, e._cyl(0.09, 0.07, 0.16, 10), e._mat("pierre"), Vector3(x4, 1.11, -2.0))
			e._mesh(root, e._sphere(0.12, 8), e._flower_mat(Color(0.3, 0.55 + 0.08 * (k % 3), 0.3)), Vector3(x4, 1.26, -2.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
			e._mesh(root, e._sphere(0.07, 8), _shiny(cols[(k + 1) % cols.size()], 0.5, 0.85), Vector3(x4 + 0.15, 1.5, -2.0))
		for k in range(7):
			var x5: float = -1.3 + k * 0.43
			e._mesh(root, e._cyl(0.004, 0.004, 0.3, 4), e._mat("corde"), Vector3(x5, 2.38, 0.6))
			var bunch: MeshInstance3D = e._mesh(root, e._cyl(0.07, 0.015, 0.28, 6), e._flower_mat(Color(0.35 + 0.1 * (k % 2), 0.5, 0.25)), Vector3(x5, 2.1, 0.6))
			bunch.rotation.z = rng.randf_range(-0.15, 0.15)
			if k % 2 == 0:
				e._mesh(root, e._sphere(0.04, 6), e._flower_mat(Color(0.75, 0.55, 0.9)), Vector3(x5, 1.98, 0.6))
	else:
		# Pains dorés, pots de miel, une corbeille
		var crust := StandardMaterial3D.new()
		crust.albedo_color = Color(0.78, 0.5, 0.22)
		crust.roughness = 0.75
		for k in range(8):
			var x6: float = -1.3 + k * 0.37
			var loaf: MeshInstance3D = e._mesh(root, e._sphere(0.13, 10), crust, Vector3(x6, 1.07, 0.1 - (k % 2) * 0.2), Vector3.ZERO, Vector3(1.3, 0.55, 0.85))
			loaf.rotation.y = rng.randf_range(-0.4, 0.4)
			e._mesh(root, e._sphere(0.035, 6), _shiny(Color(0.98, 0.75, 0.2), 0.4), Vector3(x6, 1.14, 0.1 - (k % 2) * 0.2))
		for k in range(6):
			var x7: float = -1.2 + k * 0.48
			e._mesh(root, e._sphere(0.1, 10), _shiny(Color(0.95, 0.62, 0.12), 0.35, 0.85), Vector3(x7, 1.13, -2.0), Vector3.ZERO, Vector3(1.0, 1.1, 1.0))
			e._mesh(root, e._cyl(0.06, 0.06, 0.04, 10), _cloth(Color(0.9, 0.85, 0.7)), Vector3(x7, 1.24, -2.0))
			var bread: MeshInstance3D = e._mesh(root, e._sphere(0.12, 8), crust, Vector3(x7, 1.52, -2.0), Vector3.ZERO, Vector3(1.4, 0.5, 0.8))
			bread.rotation.y = 0.3 * k
		e._mesh(root, e._cyl(0.35, 0.25, 0.3, 14), e._mat("corde"), Vector3(1.9, 0.15, 0.4))
		for k in range(4):
			e._mesh(root, e._sphere(0.12, 8), crust, Vector3(1.8 + (k % 2) * 0.2, 0.36, 0.3 + (k / 2) * 0.2), Vector3.ZERO, Vector3(1.3, 0.55, 0.85))
	e._lantern(c + root.global_basis * Vector3(1.45, 2.45, 0.45), true, 1.0)


## La harpe de Caelan : colonne dorée, console courbe, table d'harmonie et cordes.
func _build_harp() -> void:
	var c: Vector3 = _at(73.5, 13.75)
	var root := Node3D.new()
	root.name = "Harpe_Caelan"
	add_child(root)
	root.global_position = c
	var to_g: Vector3 = (ground["harpe"] - c) * Vector3(1, 0, 1)
	root.rotation.y = atan2(to_g.x, to_g.z) + PI * 0.5
	harp_pos = c
	var gold: Material = e._mat("or")
	var wood: Material = e._mat("bois")
	e._mesh(root, _box(Vector3(0.22, 0.1, 0.9)), wood, Vector3(0, 0.05, 0.05))
	e._mesh(root, e._cyl(0.035, 0.045, 1.55, 10), gold, Vector3(0, 0.82, 0.45))
	e._mesh(root, e._sphere(0.06, 8), gold, Vector3(0, 1.62, 0.45))
	var s0 := Vector3(0, 0.12, 0.32)
	var s1 := Vector3(0, 1.32, -0.38)
	var sb: Vector3 = s1 - s0
	var board: MeshInstance3D = e._mesh(root, _box(Vector3(0.16, sb.length(), 0.09)), wood, (s0 + s1) * 0.5)
	board.rotation.x = atan2(sb.z, sb.y)
	var neck_pts: Array = []
	for k in range(9):
		var f: float = float(k) / 8.0
		var z: float = lerpf(-0.38, 0.45, f)
		var y: float = lerpf(1.32, 1.6, f) + sin(f * PI * 2.0) * 0.06
		neck_pts.append(Vector3(0, y, z))
	for k in range(8):
		var a: Vector3 = neck_pts[k]
		var b: Vector3 = neck_pts[k + 1]
		var seg: Vector3 = b - a
		var m: MeshInstance3D = e._mesh(root, e._cyl(0.03, 0.03, seg.length() + 0.02, 6), gold, (a + b) * 0.5)
		m.rotation.x = atan2(seg.z, seg.y)
	var string_mat := _shiny(Color(0.95, 0.92, 0.8), 0.5)
	for k in range(1, 8):
		var top: Vector3 = neck_pts[k]
		var bottom_y: float = lerpf(0.12, 1.32, clampf((0.32 - top.z) / 0.7, 0.0, 1.0))
		var h: float = top.y - bottom_y - 0.03
		if h < 0.1:
			continue
		e._mesh(root, e._cyl(0.004, 0.004, h, 4), string_mat, Vector3(0, bottom_y + h * 0.5, top.z))
	# Un tabouret pour le musicien
	var stool: Vector3 = c + (ground["harpe"] - c) * 0.5
	e._mesh(self, e._cyl(0.22, 0.2, 0.06, 12), wood, stool + Vector3.UP * 0.45 - global_position)


## Le cercle des contes : un cristal qui luit, entouré de tabourets-champignons.
func _build_story_circle() -> void:
	var c: Vector3 = _at(343.5, 16.6)
	e._mesh(e, Rocks.shape(4230, Vector3(0.9, 0.5, 0.8), 0.5, 0.06), e._mat("pierre"), c + Vector3.UP * 0.2 - e.global_position)
	e._mesh(e, e._cyl(0.0, 0.22, 0.9, 6), e._mat("cristal"), c + Vector3.UP * 0.85 - e.global_position)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 1.0, 0.85)
	l.light_energy = 1.2
	l.omni_range = 6.0
	add_child(l)
	l.global_position = c + Vector3.UP * 1.4
	var stem := StandardMaterial3D.new()
	stem.albedo_color = Color(0.92, 0.88, 0.8)
	var cap_cols := [Color(0.75, 0.25, 0.2), Color(0.85, 0.6, 0.3), Color(0.55, 0.35, 0.6)]
	var to_g: float = atan2(G.z - c.z, G.x - c.x)
	for k in range(7):
		var a: float = to_g + deg_to_rad(55.0 + k * 41.0)
		var q := Vector3(c.x + cos(a) * 2.5, 0, c.z + sin(a) * 2.5)
		q.y = e.ile.height(q.x, q.z)
		e._mesh(self, e._cyl(0.12, 0.16, 0.4, 10), stem, q + Vector3.UP * 0.2 - global_position)
		e._mesh(self, e._sphere(0.3, 12), e._flower_mat(cap_cols[k % 3]), q + Vector3.UP * 0.42 - global_position, Vector3.ZERO, Vector3(1.0, 0.38, 1.0))
		for d in range(3):
			var da: float = d * 2.1 + k
			e._mesh(self, e._sphere(0.035, 6), e._flower_mat(Color(0.98, 0.96, 0.9)), q + Vector3(cos(da) * 0.18, 0.5, sin(da) * 0.18) - global_position, Vector3.ZERO, Vector3(1, 0.4, 1))


func _loom_pos() -> Vector3:
	var t1: Dictionary = e.tree_spots[1]
	var p1: Vector3 = t1["pos"]
	var am: float = float(t1["angle"]) + deg_to_rad(90.0)
	return Vector3(p1.x + cos(am) * 3.0, p1.y + e.PLATFORM_H, p1.z + sin(am) * 3.0)


## Le métier à tisser d'Ilyria, et une toile aux couleurs de l'aube.
func _build_loom() -> void:
	var c: Vector3 = _loom_pos()
	var root := Node3D.new()
	root.name = "Metier_Ilyria"
	add_child(root)
	root.global_position = c
	var t1: Dictionary = e.tree_spots[1]
	var p1: Vector3 = t1["pos"]
	var out: Vector3 = (c - p1) * Vector3(1, 0, 1)
	root.rotation.y = atan2(out.x, out.z)
	var wood: Material = e._mat("bois")
	for sx in [-0.65, 0.65]:
		e._mesh(root, _box(Vector3(0.08, 1.6, 0.08)), wood, Vector3(sx, 0.8, 0.0))
		e._mesh(root, _box(Vector3(0.08, 0.08, 0.7)), wood, Vector3(sx, 0.05, 0.0))
	for y in [0.35, 1.55]:
		e._mesh(root, e._cyl(0.04, 0.04, 1.36, 8), wood, Vector3(0, y, 0), Vector3(0, 0, PI * 0.5))
	var cols := [Color(0.95, 0.75, 0.55), Color(0.9, 0.6, 0.65), Color(0.7, 0.65, 0.92), Color(0.6, 0.82, 0.95)]
	for k in range(4):
		e._mesh(root, _box(Vector3(1.2, 0.28, 0.01)), _cloth(cols[k]), Vector3(0, 0.55 + k * 0.28, 0))
	for k in range(13):
		e._mesh(root, e._cyl(0.003, 0.003, 1.2, 3), _cloth(Color(0.95, 0.93, 0.88)), Vector3(-0.6 + k * 0.1, 0.95, 0.01))
	# Une banquette et une corbeille de pelotes
	e._mesh(root, _box(Vector3(0.8, 0.08, 0.35)), wood, Vector3(0, 0.45, 0.75))
	for k in range(5):
		e._mesh(root, e._sphere(0.07, 8), _cloth(cols[k % 4]), Vector3(0.9 + (k % 2) * 0.12, 0.1, 0.3 + k * 0.08))


## Guirlandes de petites lumières, de l'Arbre-Mère vers chaque arbre-maison.
func _build_garlands() -> void:
	var bulbs := MultiMesh.new()
	bulbs.transform_format = MultiMesh.TRANSFORM_3D
	bulbs.use_colors = true
	bulbs.mesh = e._sphere(0.07, 8)
	var rope := MultiMesh.new()
	rope.transform_format = MultiMesh.TRANSFORM_3D
	rope.mesh = e._cyl(0.012, 0.012, 1.0, 4)
	var spans: Array = []
	for t in e.tree_spots:
		var p: Vector3 = t["pos"]
		var dir: Vector3 = ((p - G) * Vector3(1, 0, 1)).normalized()
		spans.append([G + dir * 3.7 + Vector3.UP * 7.2, p - dir * 2.4 + Vector3.UP * 6.4])
	var per: int = 22
	bulbs.instance_count = spans.size() * per
	rope.instance_count = spans.size() * per
	var cols := [Color(1.0, 0.85, 0.45), Color(1.0, 0.6, 0.7), Color(0.55, 1.0, 0.8), Color(0.75, 0.65, 1.0)]
	var n: int = 0
	for s in spans:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		for k in range(per):
			var f0: float = float(k) / per
			var f1: float = float(k + 1) / per
			var q0: Vector3 = a.lerp(b, f0) + Vector3.DOWN * 2.2 * sin(PI * f0)
			var q1: Vector3 = a.lerp(b, f1) + Vector3.DOWN * 2.2 * sin(PI * f1)
			bulbs.set_instance_transform(n, Transform3D(Basis.IDENTITY, q1 + Vector3.DOWN * 0.08 - global_position))
			bulbs.set_instance_color(n, cols[n % cols.size()])
			var seg: Vector3 = q1 - q0
			var y_axis: Vector3 = seg.normalized()
			var x_axis: Vector3 = y_axis.cross(Vector3.UP).normalized()
			if x_axis.length() < 0.1:
				x_axis = Vector3.RIGHT
			var z_axis: Vector3 = x_axis.cross(y_axis)
			rope.set_instance_transform(n, Transform3D(Basis(x_axis, y_axis * seg.length(), z_axis), (q0 + q1) * 0.5 - global_position))
			n += 1
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.vertex_color_use_as_albedo = true
	var bi := MultiMeshInstance3D.new()
	bi.name = "Guirlandes"
	bi.multimesh = bulbs
	bi.material_override = bm
	bi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bi)
	var ri := MultiMeshInstance3D.new()
	ri.multimesh = rope
	ri.material_override = e._mat("corde")
	add_child(ri)


func _build_fireflies() -> void:
	var ff := CPUParticles3D.new()
	ff.name = "Lucioles"
	ff.amount = 80
	ff.lifetime = 6.0
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(24, 2.0, 24)
	ff.direction = Vector3.UP
	ff.spread = 180.0
	ff.gravity = Vector3.ZERO
	ff.initial_velocity_min = 0.05
	ff.initial_velocity_max = 0.25
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(0.7, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	ff.scale_amount_curve = curve
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.85, 1.0, 0.55, 0.9)
	m.albedo_texture = e.main._soft_dot_v24()
	q.material = m
	ff.mesh = q
	add_child(ff)
	ff.global_position = G + Vector3.UP * 1.8


## Papillons : deux ailes qui battent, un vol en boucles autour des massifs de fleurs.
func _build_butterflies() -> void:
	var cols := [Color(0.95, 0.65, 0.2), Color(0.45, 0.65, 1.0), Color(0.95, 0.95, 0.85), Color(0.9, 0.45, 0.75), Color(1.0, 0.9, 0.3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for k in range(12):
		var b := Node3D.new()
		b.name = "Papillon_%d" % k
		add_child(b)
		var wm := StandardMaterial3D.new()
		wm.albedo_color = cols[k % cols.size()]
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		wm.emission_enabled = true
		wm.emission = cols[k % cols.size()]
		wm.emission_energy_multiplier = 0.3
		var wings: Array = []
		for sx in [-1.0, 1.0]:
			var hinge := Node3D.new()
			b.add_child(hinge)
			var w := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.07, 0.06)
			w.mesh = qm
			w.material_override = wm
			w.rotation.x = -PI * 0.5
			w.position = Vector3(sx * 0.037, 0, 0)
			hinge.add_child(w)
			wings.append(hinge)
		var body := MeshInstance3D.new()
		body.mesh = e._cyl(0.006, 0.006, 0.05, 4)
		body.rotation.x = PI * 0.5
		body.material_override = e._flower_mat(Color(0.1, 0.08, 0.06))
		b.add_child(body)
		var bed_a: float = TAU * (k % 6) / 6.0 + 0.5 + 0.52
		var center: Vector3 = G + Vector3(cos(bed_a) * 9.4, 0.0, sin(bed_a) * 9.4)
		if k >= 6:
			center = G + Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
		center.y = e.ile.height(center.x, center.z)
		_butterflies.append({"node": b, "wings": wings, "c": center, "ph": rng.randf() * TAU,
			"fx": rng.randf_range(0.25, 0.45), "fz": rng.randf_range(0.2, 0.4), "r": rng.randf_range(1.2, 2.8)})


# =================================================================== chaque image

const CHATTER := [
	["Tu as vu la lumière, ce matin ? L'Arbre-Mère était tout doré.", "Comme chaque matin depuis mille ans. Et je ne m'en lasse pas."],
	["L'humain est encore là. Il a l'air gentil.", "Lyra dit qu'il a sauvé l'Arbre sacré. Alors il est gentil."],
	["Sylwen a fait du pain de miel !", "Je sais. Tout le village le sent."],
	["Caelan joue encore la même chanson…", "Pour Ilyria. Toujours pour Ilyria."],
	["Il paraît que Faelar a raconté l'histoire de la première graine. Encore.", "Je l'ai entendue quatre cents fois. Elle est toujours belle."],
	["Ce soir, on danse sous l'Arbre-Mère ?", "Comme tous les soirs !"],
	["Thalion t'a encore demandé où tu allais ?", "Trois fois. Je n'allais nulle part."],
	["Tu as vu Nimiel ? Elle est encore montée sur la passerelle sans les mains.", "Ne le dis pas à Aëlwen."],
	["Les lucioles sont en avance, cette année.", "Elles ont senti la fête de l'Aube."],
	["La fontaine a chanté cette nuit. Tu l'as entendue ?", "Oui. Une chanson de la mer, très ancienne."],
	["Les abeilles de l'Arbre-Mère sont de bonne humeur.", "Alors Thalion reviendra sans piqûre, pour une fois."],
	["Belle journée.", "Toutes les journées sont belles, au Bois-Doré."],
	["J'ai trouvé une plume de héron doré !", "Montre-la à Ilyria, elle en fera une broderie."],
	["Les humains ont des oreilles rondes. C'est mignon.", "Chut ! Il pourrait t'entendre."],
]


func _process(delta: float) -> void:
	if e == null or e.main == null or not e.main.game_started:
		return
	_clock += delta
	var player: Vector3 = e.main._player_pos_v27()
	var near_village: bool = Vector2(player.x - G.x, player.z - G.z).length() < 80.0
	if near_village:
		for b in _butterflies:
			var t: float = _clock + float(b["ph"])
			var c: Vector3 = b["c"]
			var node: Node3D = b["node"]
			var r: float = float(b["r"])
			var pos := Vector3(c.x + sin(t * float(b["fx"])) * r, c.y + 0.7 + sin(t * 1.3) * 0.35 + sin(t * 3.1) * 0.08, c.z + cos(t * float(b["fz"])) * r)
			var vel: Vector3 = pos - node.global_position
			node.global_position = pos
			if vel.length() > 0.0005:
				node.rotation.y = atan2(vel.x, vel.z)
			var flap: float = sin(t * 16.0) * 0.9 + 0.3
			(b["wings"][0] as Node3D).rotation.z = flap
			(b["wings"][1] as Node3D).rotation.z = -flap
		_music(delta, player)
		_chatter(delta, player)


## Petites notes dorées qui s'envolent de la harpe quand Caelan est à sa place.
func _music(delta: float, player: Vector3) -> void:
	var caelan: Node3D = by_id.get("caelan")
	if caelan == null or caelan.at_point != "harpe" or caelan.state != "repos":
		return
	if player.distance_to(harp_pos) > 30.0:
		return
	_note_clock -= delta
	if _note_clock > 0.0:
		return
	_note_clock = randf_range(0.7, 1.4)
	var note := Node3D.new()
	add_child(note)
	note.global_position = harp_pos + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.3, 0.3))
	var m := _shiny(Color(1.0, 0.85, 0.4), 1.4, 1.0)
	e._mesh(note, e._sphere(0.045, 8), m, Vector3.ZERO, Vector3(0, 0, 0.4), Vector3(1.25, 0.85, 0.6))
	e._mesh(note, e._cyl(0.006, 0.006, 0.17, 4), m, Vector3(0.04, 0.085, 0))
	if randf() < 0.5:
		e._mesh(note, _box(Vector3(0.06, 0.02, 0.01)), m, Vector3(0.07, 0.16, 0), Vector3(0, 0, -0.5))
	var tw := note.create_tween()
	tw.set_parallel(true)
	tw.tween_property(note, "global_position", note.global_position + Vector3(randf_range(-0.8, 0.8), 2.2, randf_range(-0.8, 0.8)), 3.0)
	tw.tween_property(m, "albedo_color:a", 0.0, 3.0).set_delay(0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tw.chain().tween_callback(note.queue_free)


## De temps en temps, deux elfes proches échangent quelques mots (bulles).
func _chatter(delta: float, player: Vector3) -> void:
	for pr in _pending_reply.duplicate():
		pr[2] = float(pr[2]) - delta
		if float(pr[2]) <= 0.0:
			_pending_reply.erase(pr)
			var who: Node3D = pr[0]
			if is_instance_valid(who) and who.state != "parle":
				who.say_bubble(str(pr[1]), 4.5)
	_chat_clock -= delta
	if _chat_clock > 0.0:
		return
	_chat_clock = randf_range(7.0, 13.0)
	var cands: Array = villagers.filter(func(n): return n.state == "repos" and n.bubble_clock <= 0.0 and n.global_position.distance_to(player) < 30.0)
	cands.shuffle()
	for a in cands:
		for b in cands:
			if a == b:
				continue
			if a.global_position.distance_to(b.global_position) < 7.0:
				var pair: Array = CHATTER[randi() % CHATTER.size()]
				a.say_bubble(str(pair[0]), 4.5)
				_pending_reply.append([b, str(pair[1]), 3.0])
				var ab: Vector3 = b.global_position - a.global_position
				a.rotation.y = atan2(ab.x, ab.z)
				b.rotation.y = atan2(-ab.x, -ab.z)
				a.chat_hold = 9.0
				b.chat_hold = 9.0
				return

extends Node3D
## V69 : Yaxché, la cité maya de l'Île des Trois Soleils, sur sa grande esplanade stuquée au
## milieu de la jungle du nord :
##  - le Temple de Kukulkan : neuf gradins, quatre escaliers (celui du sud, vers la place, a
##    ses balustrades et ses deux têtes de serpent à plumes), le temple au sommet ; sa porte
##    est fermée par le calendrier sacré (voir xibalba_v69.gd) ;
##  - le palais (à l'est du temple), le petit Temple des Jaguars (à l'ouest), la plateforme de
##    Vénus au milieu de la place, trois stèles (dont celle de la date 4 Ahau) ;
##  - le jeu de balle (au sud-est), l'observatoire rond (au sud-ouest) ;
##  - les cases du peuple, le marché, les ruches de troncs ;
##  - le sacbé (la route blanche) jusqu'au Cénote sacré et son petit sanctuaire.

const R = preload("res://scripts/ile_soleils_v69.gd")
const Kit = preload("res://scripts/soleils_kit_v69.gd")

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}
var flora_avoid: Array = []
var fire_spots: Array = []
var smoke_spots: Array = []
var cenote_water: MeshInstance3D
var temple_top := Vector3.ZERO            # le milieu du sommet du Temple de Kukulkan
var temple_door := Vector3.ZERO           # devant la porte du temple du sommet
var temple_xf := Transform3D()            # le repère du temple du sommet (sa façade regarde +Z : le sud)
var ball_rings: Array = []                # les centres des anneaux du jeu de balle du village
var ball_center := Vector3.ZERO
var _rng := RandomNumberGenerator.new()

const Y := R.PLAZA_Y


func W(x: float, z: float, y: float) -> Vector3:
	return R.W(x, z, y)


func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func XZ(p: Vector3, dx: float, dz: float) -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3(-dx, 0.0, -dz).normalized(), Vector3.UP), p)


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _link(a: String, b: String) -> void:
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


func _chain(names: Array) -> void:
	for i in range(names.size() - 1):
		_link(str(names[i]), str(names[i + 1]))


func _pt(name: String, p: Vector3) -> String:
	points[name] = p
	return name


func _pp(name: String, x: float, z: float) -> String:
	return _pt(name, W(x, z, Y + 0.05))


func _avoid(x: float, z: float, r: float) -> void:
	var w: Vector3 = R.W(x, z)
	flora_avoid.append([Vector2(w.x, w.z), r])


func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6920
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6921
	_kukulkan()
	_palais()
	_jaguars()
	_place()
	_jeu_de_balle()
	_observatoire()
	_cases()
	_cenote()
	kit.commit()
	_graph()
	for f in kit.fires69:
		fire_spots.append(f)
	_avoid((R.PLAZA_M.position.x + R.PLAZA_M.end.x) * 0.5, (R.PLAZA_M.position.y + R.PLAZA_M.end.y) * 0.5, 0.0)
	print("ILE_MANGA_V69: Yaxché bâtie, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


# =================================================================== le Temple de Kukulkan

const TIERS: int = 9
const TIER_H: float = 2.4
const SHRINK: float = 2.6


func _kukulkan() -> void:
	var c: Vector3 = W(R.KUKULKAN.x, R.KUKULKAN.y, Y)
	var base: float = R.KUKULKAN_BASE
	temple_top = kit.step_pyramid(c, base, base, TIERS, TIER_H, SHRINK, "pmaya69", "dalles69_blanc", 2.5)
	_avoid(R.KUKULKAN.x, R.KUKULKAN.y, base * 0.72)
	var top_w: float = base - SHRINK * TIERS
	var top_y: float = temple_top.y
	# les quatre escaliers ; celui du sud (vers la place) a ses balustrades et ses serpents
	var run: float = (base - top_w) * 0.5 + 6.0
	for d in [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]:
		var foot: Vector3 = c + Vector3(d.x, 0, d.y) * (top_w * 0.5 + run)
		var head: Vector3 = c + Vector3(d.x, 0, d.y) * (top_w * 0.5) + Vector3.UP * top_y - Vector3.UP * c.y
		head.y = top_y
		kit.stair(foot, head, 8.6, "pmaya69", "pmaya69_sombre", 0.7, 0.7)
		if d == Vector2(0, 1):
			for s in [-1.0, 1.0]:
				kit.serpent_head(XZ(foot + Vector3(s * 4.65, 0, 0.6), 0.0, 1.0), 1.25)
	# le temple du sommet : sa porte regarde la place (le sud)
	temple_xf = XZ(temple_top + Vector3(0, 0, -1.5), 0.0, 1.0)
	kit.maya_building(temple_xf, 12.0, 9.0, 5.2, {"mur": "stucr69", "portes": 3, "socle": 0.4, "crete_h": 3.6})
	temple_door = temple_xf * Vector3(0, 0.45, 6.2)
	# deux braseros sur le sommet, deux en bas de l'escalier
	for s2 in [-1.0, 1.0]:
		var f: Vector3 = kit.brazier(temple_xf * Vector3(s2 * 6.5, 0.4, 7.5), 0.9)
		fire_spots.append([f, 0.45])
		var f2: Vector3 = kit.brazier(c + Vector3(s2 * 9.5, 0, top_w * 0.5 + run + 0.6), 1.0)
		fire_spots.append([f2, 0.5])
	smoke_spots.append(temple_xf * Vector3(5.0, 1.5, 7.5))


# =================================================================== le palais, le Temple des Jaguars, la place

func _palais() -> void:
	# une plateforme de 2,6 m, un grand escalier, un long édifice à cinq portes
	var c: Vector3 = W(36.0, -168.0, Y)
	kit.box(Transform3D(Basis(), c + Vector3(0, 1.3, 0)), Vector3(26.0, 2.6, 13.0), "pmaya69", 2.5)
	kit.col_box(Transform3D(Basis(), c + Vector3(0, 1.3, 0)), Vector3(26.0, 2.6, 13.0))
	kit.stair(c + Vector3(0, 0, 11.0), c + Vector3(0, 2.6, 6.5), 10.0, "pmaya69", "")
	var xf := XZ(c + Vector3(0, 2.6, -1.0), 0.0, 1.0)
	var front: Vector3 = kit.maya_building(xf, 22.0, 8.0, 4.6, {"mur": "stucr69_blanc", "portes": 5, "socle": 0.3, "crete": false})
	doors["porte_ixkanul"] = _pt("porte_ixkanul", Vector3(front.x - 4.4, c.y + 2.65, front.z - 0.4))
	_avoid(36.0, -168.0, 15.0)


func _jaguars() -> void:
	# le petit Temple des Jaguars : quatre gradins, un escalier vers l'est, un temple rouge
	var c: Vector3 = W(-58.0, -160.0, Y)
	var top: Vector3 = kit.step_pyramid(c, 16.0, 16.0, 4, 2.0, 2.4, "pmaya69", "dalles69_blanc", 2.5)
	kit.stair(c + Vector3(15.0, 0, 0), Vector3(c.x + 3.4, top.y, c.z), 5.0, "pmaya69", "pmaya69_sombre", 0.5, 0.5)
	kit.maya_building(XZ(top + Vector3(-0.8, 0, 0), 1.0, 0.0), 5.6, 5.0, 3.6, {"mur": "stucr69", "portes": 1, "socle": 0.2, "crete_h": 2.0})
	_avoid(-58.0, -160.0, 12.0)


func _place() -> void:
	# la plateforme de Vénus : un socle carré, quatre petits escaliers, des glyphes
	var v: Vector3 = W(-20.0, -130.0, Y)
	kit.box(Transform3D(Basis(), v + Vector3(0, 0.75, 0)), Vector3(9.0, 1.5, 9.0), "glyphm69", 2.0)
	kit.col_box(Transform3D(Basis(), v + Vector3(0, 0.75, 0)), Vector3(9.0, 1.5, 9.0))
	kit.box(Transform3D(Basis(), v + Vector3(0, 1.52, 0)), Vector3(9.4, 0.08, 9.4), "pmaya69", 2.0)
	for d in [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]:
		kit.stair(v + Vector3(d.x, 0, d.y) * 7.4, v + Vector3(d.x, 0, d.y) * 4.5 + Vector3.UP * 1.5, 2.6, "pmaya69", "")
	_spot("venus_1", v + Vector3(-1.2, 1.6, 0.8), Vector3(0, 0, 1), "danse", "venus")
	_spot("venus_2", v + Vector3(1.4, 1.6, -0.6), Vector3(0, 0, 1), "tambour", "venus")
	_avoid(-20.0, -130.0, 8.0)
	# les trois stèles, entre la plateforme et le marché ; celle du milieu porte la date de la création
	for st in [[-36.0, -119.0, "glyphm69"], [-20.0, -116.0, "stele69_4ahau"], [-4.0, -119.0, "glyphm69"]]:
		kit.stela(XZ(W(float(st[0]), float(st[1]), Y), 0.0, 1.0), 1.9, 3.8, str(st[2]))
		_avoid(float(st[0]), float(st[1]), 3.0)
	objets["stele_4ahau"] = W(-20.0, -113.0, Y + 1.0)
	_spot("stele", W(-17.5, -112.8, Y + 0.05), Vector3(-0.5, 0, -1), "debout", "c_stele")
	# le marché : des étals sous des toiles, des paniers de maïs, de cacao, de plumes
	for mk in [[-30.0, -106.0, "toile_rouge", "fruits", "marche_cacao"], [-18.0, -106.0, "toile", "caisses", "marche_mais"], [-6.0, -106.0, "toile_bleu", "fruits", "marche_plumes"]]:
		var xf: Transform3D = XZ(W(float(mk[0]), float(mk[1]), Y), 0.0, 1.0)
		kit.stall(xf, str(mk[2]), str(mk[3]))
		_spot(str(mk[4]), xf * Vector3(0, 0.05, -1.0), Vector3(0, 0, 1), "comptoir", "c_marche")
		_avoid(float(mk[0]), float(mk[1]), 2.2)
	# la pierre à moudre (le metate) devant une case
	kit.box(Transform3D(Basis(Vector3.RIGHT, 0.12), W(-36.5, -96.6, Y + 0.3)), Vector3(0.6, 0.18, 1.0), "roche69", 1.0)
	_spot("metate", W(-36.5, -95.6, Y + 0.05), Vector3(0, 0, -1), "moudre", "s_mw")
	for tp in [Vector2(-42.0, -112.0), Vector2(6.0, -112.0), Vector2(-42.0, -146.0), Vector2(6.0, -146.0)]:
		kit.torch_post(W(tp.x, tp.y, Y), 2.6)


func _jeu_de_balle() -> void:
	ball_center = W(R.BALLCOURT.x, R.BALLCOURT.y, Y)
	var xf := XZ(ball_center, 1.0, 0.0)
	ball_rings = kit.ball_court(xf, 34.0, 8.0, 6.0)
	# les deux petits temples aux bouts de l'allée
	for s in [-1.0, 1.0]:
		var e: Vector3 = ball_center + Vector3(s * 19.5, 0, 0)
		kit.box(Transform3D(Basis(), e + Vector3(0, 1.2, 0)), Vector3(3.0, 2.4, 9.0), "pmaya69", 2.0)
		kit.col_box(Transform3D(Basis(), e + Vector3(0, 1.2, 0)), Vector3(3.0, 2.4, 9.0))
	_avoid(R.BALLCOURT.x, R.BALLCOURT.y, 19.0)
	for k in range(3):
		_spot("balle_%d" % (k + 1), ball_center + Vector3(-10.0 + k * 10.0, 0.05, (k - 1) * 1.6), Vector3(1, 0, 0), "jouer", "jb_%d" % (k % 2))
	for k2 in range(3):
		spots["balle_%d" % (k2 + 1)]["pair"] = ["balle_1", "balle_2", "balle_3"]
	objets["balle_village"] = ball_center + Vector3(0, 0.4, 0)


func _observatoire() -> void:
	# l'observatoire : une plateforme carrée, un escalier à l'est, une tour ronde et sa coupole
	var c: Vector3 = W(R.OBSERVATORY.x, R.OBSERVATORY.y, Y)
	kit.box(Transform3D(Basis(), c + Vector3(0, 1.25, 0)), Vector3(14.0, 2.5, 14.0), "pmaya69", 2.5)
	kit.col_box(Transform3D(Basis(), c + Vector3(0, 1.25, 0)), Vector3(14.0, 2.5, 14.0))
	kit.stair(c + Vector3(11.0, 0, 0), c + Vector3(7.0, 2.5, 0), 4.0, "pmaya69", "")
	var t := Transform3D(Basis(), c + Vector3(-1.5, 2.5, 0))
	kit.cyl(t, 4.0, 4.0, 1.2, "pmaya69", 24)
	kit.cyl(t * Transform3D(Basis(), Vector3(0, 1.2, 0)), 3.2, 3.2, 4.2, "enduit69_blanc", 24, false)
	kit.cyl(t * Transform3D(Basis(), Vector3(0, 5.4, 0)), 3.4, 3.4, 0.3, "pmaya69", 24)
	kit.cyl(t * Transform3D(Basis(), Vector3(0, 5.7, 0)), 3.0, 0.6, 2.4, "enduit69_blanc", 24, true)
	kit.col_cyl(t.origin, 3.3, 8.0)
	for a in [0.4, 1.3, 2.6, 4.1]:
		kit.quadz(kit.round_face(t.origin, 3.22, a, t.origin.y + 6.9) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.5, 0.7, "noir69")
	kit.quadz(kit.round_face(t.origin, 3.22, 0.0, t.origin.y + 2.2) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 1.2, 2.0, "noir69")
	_spot("observatoire", c + Vector3(3.3, 2.55, 2.2), Vector3(0.3, 0, 1), "observer", "obs_haut")
	_avoid(R.OBSERVATORY.x, R.OBSERVATORY.y, 10.0)


# =================================================================== les cases

## [x, z, orientation de la porte (dx, dz), porte, largeur]
const CASES := [
	[-56.0, -93.0, Vector2(0, -1), "", 5.8],
	[-44.0, -93.0, Vector2(0, -1), "porte_ixchab", 6.4],
	[-32.0, -93.0, Vector2(0, -1), "porte_ixsak", 6.0],
	[-10.0, -93.0, Vector2(0, -1), "porte_kinich", 5.8],
	[2.0, -93.0, Vector2(0, -1), "", 5.6],
	[18.0, -93.0, Vector2(0, -1), "porte_balam", 6.2],
	[30.0, -93.0, Vector2(0, -1), "", 5.8],
	[42.0, -93.0, Vector2(0, -1), "porte_chak", 6.4],
	[54.0, -93.0, Vector2(0, -1), "porte_yumkab", 6.0],
	[-67.0, -126.0, Vector2(1, 0), "porte_ahkin", 6.2],
]


func _cases() -> void:
	for cs in CASES:
		var dirv: Vector2 = cs[2]
		var xf: Transform3D = XZ(W(float(cs[0]), float(cs[1]), Y), dirv.x, dirv.y)
		var w: float = float(cs[4])
		var front: Vector3 = kit.maya_hut(xf, w, w * 0.58, {"mur": "enduit69_blanc" if _rng.randf() < 0.6 else "enduit69_ocre"})
		_avoid(float(cs[0]), float(cs[1]), w * 0.7)
		if str(cs[3]) != "":
			doors[str(cs[3])] = _pt(str(cs[3]), Vector3(front.x, Y + 0.05, front.z))
		kit.porte_v81_dir(Vector3(front.x, Y + 0.05, front.z), Vector3(dirv.x, 0, dirv.y), w, w * 0.58, "maya", 1, str(cs[3]).trim_prefix("porte_"))
	# les ruches de Yum Kab, le métier à tisser d'Ix Sak, un feu de cuisine
	kit.beehive_logs(XZ(W(53.0, -107.0, Y), -1.0, 0.0), 6)
	_spot("ruches", W(51.2, -107.0, Y + 0.05), Vector3(1, 0, 0), "jardiner", "s_ee")
	_spot("metier_maya", W(-28.5, -97.6, Y + 0.05), Vector3(0, 0, -1), "tisser", "s_mw")
	_spot("chasseur", W(21.0, -97.6, Y + 0.05), Vector3(0, 0, -1), "bricoler", "s_me")
	var cf := W(-50.0, -97.0, Y)
	for k in range(3):
		var a: float = TAU * k / 3.0
		kit.box(Transform3D(Basis(Vector3.UP, a), cf + Vector3(cos(a) * 0.35, 0.1, sin(a) * 0.35)), Vector3(0.3, 0.2, 0.25), "roche69", 0.5)
	fire_spots.append([cf + Vector3(0, 0.15, 0), 0.3])
	smoke_spots.append(cf + Vector3(0, 0.6, 0))


# =================================================================== le Cénote sacré

func _cenote() -> void:
	var c: Vector3 = W(R.CENOTE.x, R.CENOTE.y, R.CENOTE_Y)
	cenote_water = MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = R.CENOTE_R + 0.6
	dm.bottom_radius = R.CENOTE_R + 0.6
	dm.height = 0.02
	dm.radial_segments = 40
	cenote_water.mesh = dm
	cenote_water.material_override = kit.mat("eau69_cenote")
	cenote_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cenote_water)
	cenote_water.global_position = c
	_cenote_walls(c)
	# le petit sanctuaire au bord, et la plateforme des offrandes qui avance au-dessus du vide
	var rim_y: float = ile.height(c.x + R.CENOTE_R + 4.0, c.z)
	var sx := XZ(W(R.CENOTE.x + R.CENOTE_R + 4.5, R.CENOTE.y + 3.0, rim_y), -1.0, 0.0)
	kit.maya_building(sx, 4.0, 3.6, 3.0, {"mur": "stucr69", "portes": 1, "socle": 0.3, "crete_h": 1.6})
	var plat := Transform3D(Basis(), W(R.CENOTE.x + R.CENOTE_R - 0.8, R.CENOTE.y - 2.0, rim_y + 0.15))
	kit.box(plat, Vector3(3.6, 0.3, 2.2), "pmaya69", 1.5)
	kit.col_box(plat, Vector3(3.6, 0.3, 2.2))
	kit.walk_boxes.append([plat.affine_inverse(), Vector3(1.8, 2.5, 1.1)])
	_spot("cenote_offrande", W(R.CENOTE.x + R.CENOTE_R - 1.4, R.CENOTE.y - 2.0, rim_y + 0.35), Vector3(-1, 0, 0), "prier", "cen_bord")
	objets["cenote"] = c
	# le sacbé, la route blanche : des dalles le long du chemin
	var sb: Array = ile.paths_world.get("cenote", [])
	for i in range(sb.size() - 1):
		var p0: Vector3 = sb[i]
		var p1: Vector3 = sb[i + 1]
		var mid: Vector3 = (p0 + p1) * 0.5
		var flat := Vector2(p1.x - p0.x, p1.z - p0.z)
		kit.box(Transform3D(Basis(Vector3.UP, atan2(flat.x, flat.y)), mid + Vector3(0, 0.12, 0)), Vector3(4.0, 0.3, flat.length() + 0.3), "dalles69_blanc", 2.0, 4 | 1 | 2)
	_avoid(R.CENOTE.x, R.CENOTE.y, R.CENOTE_R + 6.0)


## Les parois du Cénote : une falaise de calcaire à pic, bosselée, un rebord de pierre, des
## lianes qui pendent vers l'eau verte. Une brèche là où le sacbé descend jusqu'à l'eau.
func _cenote_walls(c: Vector3) -> void:
	var n: int = 72
	var levels: int = 7
	var r0: float = R.CENOTE_R - 0.45
	var r_out: float = R.CENOTE_R + 2.7
	var y_bot: float = R.CENOTE_Y - 0.9
	var sb: Array = ile.paths_world.get("cenote", [])
	var gap_a: float = 1000.0
	if not sb.is_empty():
		var pe: Vector3 = sb[-1]
		gap_a = atan2(pe.z - c.z, pe.x - c.x)
	var nz := FastNoiseLite.new()
	nz.seed = 6977
	nz.frequency = 0.08
	var rims: Array = []
	var cols: Array = []
	for i in range(n + 1):
		var a: float = TAU * float(i % n) / n
		var d := Vector3(cos(a), 0.0, sin(a))
		var rim: float = ile.height(c.x + d.x * (R.CENOTE_R + 2.4), c.z + d.z * (R.CENOTE_R + 2.4)) + 0.12
		rims.append(rim)
		var col: Array = []
		for j in range(levels + 1):
			var t: float = float(j) / levels
			var y: float = lerpf(y_bot, rim, t)
			# la roche bosselée ; le haut surplombe un peu (la voûte effondrée d'un puits)
			var bump: float = nz.get_noise_3d(cos(a) * 40.0, y * 3.0, sin(a) * 40.0) * 0.55
			var rr: float = r0 + bump - 0.35 * t * t
			if j == levels:
				rr = r0 - 0.35
			col.append(Vector3(c.x + d.x * rr, y, c.z + d.z * rr))
		cols.append(col)
	var in_gap := func(a: float) -> bool:
		return absf(wrapf(a - gap_a, -PI, PI)) < 0.24
	for i in range(n):
		var am: float = TAU * (float(i) + 0.5) / n
		if in_gap.call(am):
			continue
		var inward := Vector3(-cos(am), 0.0, -sin(am))
		var u0: float = float(i) / n * TAU * r0 / 3.0
		var u1: float = float(i + 1) / n * TAU * r0 / 3.0
		for j in range(levels):
			var p0: Vector3 = cols[i][j]
			var p1: Vector3 = cols[i + 1][j]
			var p2: Vector3 = cols[i + 1][j + 1]
			var p3: Vector3 = cols[i][j + 1]
			var nn: Vector3 = (p1 - p0).cross(p3 - p0).normalized()
			if nn.dot(inward) < 0.0:
				nn = -nn
			nn = (nn + inward).normalized()
			kit.quad4("roche69", p0, p1, p2, p3, nn, Vector2(u0, p0.y / 3.0), Vector2(u1, p1.y / 3.0), Vector2(u1, p2.y / 3.0), Vector2(u0, p3.y / 3.0))
		# le rebord : une dalle de roche entre le haut de la falaise et le pré
		var top0: Vector3 = cols[i][levels]
		var top1: Vector3 = cols[i + 1][levels]
		var a0: float = TAU * float(i) / n
		var a1: float = TAU * float(i + 1) / n
		var ro0: float = r_out + nz.get_noise_2d(cos(a0) * 60.0, sin(a0) * 60.0) * 1.6
		var ro1: float = r_out + nz.get_noise_2d(cos(a1) * 60.0, sin(a1) * 60.0) * 1.6
		var o0 := Vector3(c.x + cos(a0) * ro0, ile.height(c.x + cos(a0) * ro0, c.z + sin(a0) * ro0) + 0.06, c.z + sin(a0) * ro0)
		var o1 := Vector3(c.x + cos(a1) * ro1, ile.height(c.x + cos(a1) * ro1, c.z + sin(a1) * ro1) + 0.06, c.z + sin(a1) * ro1)
		kit.quad4("roche69", top0, top1, o1, o0, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		# on marche sur le rebord ; la falaise retient
		var mid_top: Vector3 = (top0 + top1 + o0 + o1) * 0.25
		var yaw: float = atan2(cos(am), sin(am))
		var seg_w: float = TAU * r_out / n + 0.2
		kit.col_box(Transform3D(Basis(Vector3.UP, yaw), Vector3(mid_top.x, mid_top.y - 0.3, mid_top.z)), Vector3(seg_w, 0.6, r_out - r0 + 0.3))
		var wall_c := Vector3(c.x + cos(am) * (r0 + 0.2), (y_bot + float(rims[i])) * 0.5, c.z + sin(am) * (r0 + 0.2))
		kit.col_box(Transform3D(Basis(Vector3.UP, yaw), wall_c), Vector3(TAU * r0 / n + 0.15, float(rims[i]) - y_bot, 0.4))
		# des lianes
		if _rng.randf() < 0.45:
			var top: Vector3 = (top0 + top1) * 0.5 + inward * 0.15
			var length: float = _rng.randf_range(1.6, minf(4.2, top.y - R.CENOTE_Y - 0.3))
			if length > 1.0:
				_vine(top, length, inward)
	# la brèche : des blocs éboulés de part et d'autre
	if gap_a < 100.0:
		var Rk = preload("res://scripts/rocks_v26.gd")
		var m: Material = kit.mat("roche69")
		for k in range(6):
			var side: float = -1.0 if k < 3 else 1.0
			var ak: float = gap_a + side * (0.17 + 0.03 * (k % 3))
			var rk: float = r0 + 0.3 + 0.8 * (k % 3)
			var pk := Vector3(c.x + cos(ak) * rk, 0.0, c.z + sin(ak) * rk)
			pk.y = ile.height(pk.x, pk.z)
			var s: float = _rng.randf_range(0.9, 1.6)
			var mi := MeshInstance3D.new()
			mi.mesh = Rk.shape(6970 + k, Vector3(s * 1.3, s * 0.9, s), 0.75, 0.18)
			mi.material_override = m
			add_child(mi)
			mi.global_position = pk + Vector3.UP * s * 0.2
			mi.rotation.y = _rng.randf() * TAU


## Une liane qui pend du rebord : une tige qui ondule, des feuilles de loin en loin.
func _vine(top: Vector3, length: float, inward: Vector3) -> void:
	var steps: int = int(length / 0.5) + 1
	var prev: Vector3 = top
	var side := Vector3(inward.z, 0.0, -inward.x)
	var ph: float = _rng.randf() * TAU
	for k in range(1, steps + 1):
		var t: float = float(k) / steps
		var p: Vector3 = top + Vector3.DOWN * length * t + side * sin(ph + t * 5.0) * 0.12 + inward * t * 0.25
		var mid: Vector3 = (prev + p) * 0.5
		var dv: Vector3 = p - prev
		var b := Basis.looking_at(dv.normalized(), side if absf(dv.normalized().dot(side)) < 0.9 else Vector3.FORWARD)
		kit.box(Transform3D(b, mid), Vector3(0.035, 0.035, dv.length() + 0.02), "feuillage", 1.0, 1 | 2 | 4 | 8)
		if k % 2 == 0:
			var lf := Transform3D(Basis(Vector3.UP, ph + k * 1.7) * Basis(Vector3.RIGHT, 0.5), p + side * 0.08)
			kit.quad(lf, 0.24, 0.16, "feuillage", Vector2(0, 0), Vector2(1, 1), true)
		prev = p


# =================================================================== le graphe

func _graph() -> void:
	_chain([_pp("s_w", -58.0, -99.0), _pp("s_mw", -42.0, -99.0), _pp("s_m", -16.0, -99.5), _pp("s_me", 6.0, -99.5), _pp("s_e", 30.0, -99.0), _pp("s_ee", 59.0, -102.0)])
	_chain([_pp("m_w", -60.0, -136.0), _pp("m_mw", -42.0, -140.0), _pp("m_m", -10.0, -140.0), _pp("m_e", 6.0, -140.0), _pp("m_ee", 59.0, -142.0)])
	_link("s_mw", "m_mw")
	_link("s_me", "m_e")
	_link("s_ee", "m_ee")
	_pp("c_marche", -18.0, -103.0)
	_chain(["s_mw", "c_marche", "s_me"])
	_link("c_marche", "s_m")
	_pp("c_stele", -14.0, -111.0)
	_link("c_stele", "c_marche")
	# l'observatoire
	_pp("obs_bas", -43.5, -104.0)
	_pt("obs_haut", W(R.OBSERVATORY.x + 4.5, R.OBSERVATORY.y, Y + 2.55))
	_chain(["s_mw", "obs_bas", "obs_haut"])
	# le temple : le pied de l'escalier, le sommet
	var top_w: float = R.KUKULKAN_BASE - SHRINK * TIERS
	var run: float = (R.KUKULKAN_BASE - top_w) * 0.5 + 6.0
	_pp("kuku_bas", R.KUKULKAN.x, R.KUKULKAN.y + top_w * 0.5 + run + 1.5)
	_pt("kuku_haut", W(R.KUKULKAN.x, R.KUKULKAN.y + top_w * 0.5 - 1.0, temple_top.y + 0.05))
	_chain(["m_mw", "kuku_bas", "m_m"])
	_link("kuku_bas", "kuku_haut")
	_spot("kuku_priere", temple_door + Vector3(0, -0.4, 1.4), Vector3(0, 0, -1), "prier", "kuku_haut")
	# la plateforme de Vénus (par son escalier nord)
	_pp("venus_bas", -20.0, -138.4)
	_pt("venus", W(-20.0, -131.5, Y + 1.6))
	_chain(["m_mw", "venus_bas", "m_m"])
	_link("venus_bas", "venus")
	# le palais
	_pp("pal", 30.0, -152.0)
	_chain(["m_e", "pal", "m_ee"])
	_pt("pal_haut", W(32.0, -163.0, Y + 2.65))
	_link("pal", "pal_haut")
	_link("pal_haut", "porte_ixkanul")
	# le jeu de balle (l'allée : on y entre par les bouts ouest et est)
	_pt("jb_0", ball_center + Vector3(-8.0, 0.05, 0))
	_pt("jb_1", ball_center + Vector3(8.0, 0.05, 0))
	_link("jb_0", "jb_1")
	_pp("jb_o", R.BALLCOURT.x - 22.5, R.BALLCOURT.y)
	_pp("jb_e", R.BALLCOURT.x + 23.0, R.BALLCOURT.y)
	_chain(["m_e", "jb_o", "jb_0"])
	_chain(["jb_1", "jb_e", "s_ee"])
	_link("jb_o", "s_me")
	# l'ouest et le nord-ouest, le Cénote
	_pp("w_n", -70.0, -150.0)
	_pp("w_nn", -69.0, -192.0)
	_chain(["s_w", "m_w", "w_n", "w_nn"])
	_link("m_w", "m_mw")
	_pt("cen_1", G(-72.0, -205.0, 0.05))
	_pt("cen_bord", W(R.CENOTE.x + R.CENOTE_R + 1.5, R.CENOTE.y - 2.0, points["cen_1"].y))
	_chain(["w_nn", "cen_1", "cen_bord"])
	# les sorties : vers Per-Hâpy (l'est) et vers Aztlán (l'ouest)
	_pp("sortie_e", 61.0, -106.0)
	_link("sortie_e", "s_ee")
	_pp("sortie_o", -71.0, -130.0)
	_link("sortie_o", "m_w")
	# les portes, reliées au point le plus proche
	for d in doors:
		if graph.has(str(doors[d])):
			continue
		var p: Vector3 = points[doors[d]]
		var best: String = ""
		var bd: float = INF
		for k2 in points:
			if str(k2).begins_with("porte"):
				continue
			var dd: float = (points[k2] as Vector3).distance_to(p)
			if dd < bd:
				bd = dd
				best = str(k2)
		_link(str(doors[d]), best)
	_spot("place_m1", W(-30.0, -137.0, Y + 0.05), Vector3(1, 0, 0), "debout", "m_mw")
	_spot("place_m2", W(2.0, -136.0, Y + 0.05), Vector3(-1, 0, 0), "debout", "m_e")
	_spot("place_m3", W(-8.0, -101.5, Y + 0.05), Vector3(0, 0, 1), "debout", "s_m")


func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	if l.distance_to(R.CENOTE) < R.CENOTE_R + 10.0:
		return "soleils_cenote"
	return ""

extends Node3D
## V69 : Per-Hâpy, le village égyptien de l'Île des Trois Soleils, sur la rive nord de
## l'Iterou ; et sur la rive sud, le plateau de Rê (la Pyramide de Rê, le Sphinx, le temple de
## la vallée, la chaussée montante, les mastabas, les pyramides des reines).
##  - le quai de grès le long du fleuve, l'escalier et le débarcadère des barques de papyrus,
##    le ponton de la barque du joueur, deux chadoufs ;
##  - la rue principale, la place du marché (pain, poisson, poteries, lin), les maisons de
##    briques crues à toit-terrasse ;
##  - le temple de Rê au nord : le pylône, deux obélisques, la cour à colonnes papyriformes,
##    l'autel, le naos ;
##  - derrière : la boulangerie-brasserie de Mérit (fours), la maison de la prêtresse et son
##    bassin aux lotus, la Maison de Vie (l'école des scribes), l'atelier du potier, les greniers ;
##  - le pont de bois sur l'Iterou, les champs de la rive sud.
## Les habitants (soleils_v69 / pnj_soleils_v69) vont de lieu en lieu par le graphe des points.

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
var objets: Dictionary = {}               # nom -> Vector3 (lieux des quêtes)
var flora_avoid: Array = []               # [Vector2 (monde), rayon]
var palms: Array = []                     # Vector3 : les palmiers-dattiers plantés dans le village
var fire_spots: Array = []                # [Vector3, taille]
var smoke_spots: Array = []
var lotus_water: MeshInstance3D
var sphinx_talk := Vector3.ZERO           # devant les pattes du Sphinx
var sphinx_face := Vector3.ZERO           # le visage du Sphinx (là où regarde la caméra du dialogue)
var pyramid_door := Vector3.ZERO          # l'entrée de la pyramide (sur la face nord)
var pyramid_top := Vector3.ZERO
var altar_pos := Vector3.ZERO             # l'autel de la cour du temple
var _rng := RandomNumberGenerator.new()

const Y := R.TOWN_E_Y


# =================================================================== repères

func W(x: float, z: float, y: float) -> Vector3:
	return R.W(x, z, y)


## Un point au sol (repère île), dy au-dessus du relief.
func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


## Un repère posé en p, son +Z local tourné vers la direction monde (dx, dz).
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


func _pg(name: String, x: float, z: float) -> String:
	return _pt(name, G(x, z, 0.05))


func _avoid(x: float, z: float, r: float) -> void:
	var w: Vector3 = R.W(x, z)
	flora_avoid.append([Vector2(w.x, w.z), r])


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6910
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6911
	_quai()
	_maisons()
	_marche()
	_temple()
	_quartier_nord()
	_pont()
	_plateau()
	kit.commit()
	_graph()
	for f in kit.fires69:
		fire_spots.append(f)
	print("ILE_MANGA_V69: Per-Hâpy bâti, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


# =================================================================== le quai et le fleuve

func _quai() -> void:
	# le mur du quai, en grès, du bord de la terrasse jusqu'au fond du fleuve
	var z: float = R.QUAY_E_Z
	for i in range(8):
		var x0: float = R.TOWN_E.position.x + i * 12.0
		var c: Vector3 = W(x0 + 6.0, z + 0.7, (Y + R.RIVER_FLOOR) * 0.5 - 0.3)
		kit.box(Transform3D(Basis(), c), Vector3(12.02, Y - R.RIVER_FLOOR + 0.6, 1.4), "gres69", 2.0)
		kit.col_box(Transform3D(Basis(), c), Vector3(12.02, Y - R.RIVER_FLOOR + 0.6, 1.4))
	kit.box(Transform3D(Basis(), W(196.0, z + 0.7, Y + 0.12)), Vector3(96.0, 0.24, 1.6), "gres69_ocre", 2.0)
	# la promenade dallée le long du quai
	kit.box(Transform3D(Basis(), W(196.0, 6.0, Y + 0.03)), Vector3(96.0, 0.06, 7.0), "dalles69_ocre", 3.0, 4)
	# l'escalier qui descend le long du mur, le débarcadère
	kit.stair(W(162.0, z + 2.2, Y), W(170.5, z + 2.2, 0.2), 1.8, "gres69", "")
	var land := Transform3D(Basis(), W(176.5, z + 3.0, 0.05))
	kit.box(land, Vector3(12.0, 0.3, 3.4), "gres69", 2.0)
	kit.col_box(land, Vector3(12.0, 0.3, 3.4))
	kit.walk_boxes.append([land.affine_inverse(), Vector3(6.0, 2.5, 1.7)])
	var st := Transform3D(Basis(), W(166.0, z + 2.2, 1.2))
	kit.walk_boxes.append([st.affine_inverse(), Vector3(5.0, 3.0, 1.0)])
	kit.box(Transform3D(Basis(), W(166.0, z + 2.2, (0.2 + R.RIVER_FLOOR) * 0.5)), Vector3(9.0, -R.RIVER_FLOOR + 0.2, 1.8), "gres69_sombre", 2.0, 1 | 2 | 16)
	for bx in [178.0, 186.0]:
		kit.papyrus_boat(XZ(W(bx, 15.5, -0.5), 1.0, 0.15), 5.6)
	for bp in [Vector3(172.0, 0.2, 12.2), Vector3(181.0, 0.2, 12.2)]:
		kit.cyl(Transform3D(Basis(), W(bp.x, bp.z, bp.y)), 0.12, 0.1, 0.8, "bois69", 6)
	_spot("quai_peche_1", W(179.0, 12.6, 0.25), Vector3(0, 0, 1), "pecher", "deb")
	_spot("quai_peche_2", W(173.5, 12.6, 0.25), Vector3(0, 0, 1), "pecher", "deb")
	# les chadoufs, au bord du quai
	for sx in [153.0, 240.0]:
		kit.shaduf(XZ(W(sx, 8.6, Y), 0.0, 1.0))
	_spot("chadouf_1", W(153.0, 7.0, Y + 0.05), Vector3(0, 0, 1), "jardiner", "q_152")
	_spot("chadouf_2", W(240.0, 7.0, Y + 0.05), Vector3(0, 0, 1), "jardiner", "q_238")
	# des jarres et des paniers le long du quai, deux torches
	for jp in [Vector2(158.0, 8.5), Vector2(159.0, 8.0), Vector2(204.0, 8.6), Vector2(213.0, 8.2), Vector2(214.0, 8.8), Vector2(232.0, 8.4)]:
		kit.jar(W(jp.x, jp.y, Y), _rng.randf_range(0.6, 0.9))
	for tp in [Vector2(190.0, 8.8), Vector2(202.0, 8.8), Vector2(226.0, 8.8)]:
		kit.torch_post(W(tp.x, tp.y, Y), 2.2)
	palms.append(W(146.0, 3.0, ile.height(R.W(146.0, 3.0).x, R.W(146.0, 3.0).z)))
	palms.append(G(246.0, 2.0))


# =================================================================== les maisons

## [x, z, largeur, profondeur, hauteur, orientation (+Z local vers…), nom de la porte, options]
const MAISONS := [
	# au sud de la rue (portes au nord, vers la rue)
	[154.0, -5.5, 11.0, 8.0, 3.4, "n", "porte_kheti", {"mur": "enduit69_ocre"}],
	[206.5, -5.5, 12.0, 8.0, 3.6, "n", "", {"mur": "enduit69_blanc", "escalier": true}],
	[223.0, -5.5, 8.0, 8.0, 3.2, "n", "", {"mur": "brique69"}],
	[232.0, -5.5, 8.0, 8.0, 3.4, "n", "", {"mur": "enduit69_ocre"}],
	# au nord de la rue (portes au sud)
	[153.5, -22.0, 9.0, 8.0, 3.4, "s", "porte_hapou", {"mur": "brique69"}],
	[165.5, -22.0, 9.0, 8.0, 3.6, "s", "", {"mur": "enduit69_ocre"}],
	[178.0, -22.0, 10.0, 8.0, 3.8, "s", "", {"mur": "enduit69_blanc"}],
	[212.5, -22.0, 9.0, 8.0, 3.4, "s", "", {"mur": "enduit69_ocre"}],
	[224.5, -22.0, 9.0, 8.0, 3.6, "s", "porte_tiyi", {"mur": "enduit69_blanc"}],
	[237.0, -22.0, 10.0, 8.0, 3.4, "s", "", {"mur": "brique69", "escalier": true}],
]


func _maisons() -> void:
	for m in MAISONS:
		var dir: Vector2 = Vector2(0, -1) if m[5] == "n" else Vector2(0, 1)
		var c: Vector3 = W(float(m[0]), float(m[1]), Y)
		var xf: Transform3D = XZ(c - Vector3(dir.x, 0, dir.y) * float(m[3]) * 0.0, dir.x, dir.y)
		var opts: Dictionary = (m[7] as Dictionary).duplicate()
		opts["escalier"] = bool(opts.get("escalier", false))
		var front: Vector3 = kit.mud_house(xf, float(m[2]), float(m[3]), float(m[4]), opts)
		_avoid(float(m[0]), float(m[1]), maxf(float(m[2]), float(m[3])) * 0.65)
		if str(m[6]) != "":
			doors[str(m[6])] = _pt(str(m[6]), Vector3(front.x, Y + 0.05, front.z))
	# des palmiers entre les maisons
	for pp in [Vector2(161.0, -9.0), Vector2(217.0, -9.5), Vector2(160.0, -24.0), Vector2(219.0, -26.0), Vector2(243.0, -12.0), Vector2(149.5, -14.0)]:
		palms.append(W(pp.x, pp.y, Y))


# =================================================================== la place du marché

func _marche() -> void:
	# les étals : pain et dattes (Mérit), poteries (Ptahmose), lin (Tiyi), poisson (Khéti)
	var stalls := [[171.0, -7.0, "toile_rouge", "fruits", "etal_pain"], [183.0, -7.0, "toile", "caisses", "etal_pots"], [171.0, 0.5, "toile_bleu", "caisses", "etal_lin"], [183.0, 0.5, "toile_sale", "poisson", "etal_poisson"]]
	for s in stalls:
		var face: float = 1.0 if float(s[1]) < -2.0 else -1.0
		var xf: Transform3D = XZ(W(float(s[0]), float(s[1]), Y), 0.0, face)
		kit.stall(xf, str(s[2]), str(s[3]))
		_spot(str(s[4]), xf * Vector3(0, 0.05, -1.0), Vector3(0, 0, face), "comptoir", "m_" + str(s[4]))
		_pt("m_" + str(s[4]), xf * Vector3(1.8, 0.05, -1.0))
		_avoid(float(s[0]), float(s[1]), 2.2)
	for jp in [Vector2(176.0, -9.0), Vector2(177.0, -8.4), Vector2(188.0, -9.0), Vector2(167.5, 2.0), Vector2(188.5, 1.8)]:
		kit.jar(W(jp.x, jp.y, Y), _rng.randf_range(0.55, 0.85))
	kit.awning69(Transform3D(Basis(), W(177.0, -3.2, Y)), 4.0, 2.6)
	_spot("place_1", W(176.0, -2.0, Y + 0.05), Vector3(1, 0, 0), "debout", "sq_c")
	_spot("place_2", W(186.0, -3.0, Y + 0.05), Vector3(-1, 0, 0), "debout", "sq_c")
	_spot("place_3", W(178.5, -3.2, Y + 0.05), Vector3(0, 0, 1), "assis", "sq_c")
	_spot("jeu_1", W(180.0, -1.0, Y + 0.05), Vector3(0, 0, 1), "jouer", "sq_c")
	_spot("jeu_2", W(196.0, -9.0, Y + 0.05), Vector3(0, 0, 1), "jouer", "r_196")
	_spot("jeu_3", W(188.0, 5.0, Y + 0.05), Vector3(0, 0, 1), "jouer", "q_188")
	for k in ["jeu_1", "jeu_2", "jeu_3"]:
		spots[k]["pair"] = ["jeu_1", "jeu_2", "jeu_3"]
	_spot("quai_flane", W(200.0, 7.0, Y + 0.05), Vector3(0, 0, 1), "debout", "q_196")


# =================================================================== le temple de Rê

func _temple() -> void:
	var gate := XZ(W(196.0, -28.0, Y), 0.0, 1.0)
	kit.pylon(gate, 22.0, 9.5, 4.0, 4.0)
	_avoid(196.0, -28.0, 12.0)
	for ox in [189.0, 203.0]:
		kit.obelisk(W(ox, -20.5, Y), 9.0)
	# la cour : murs d'enceinte (fresques à l'intérieur), colonnes papyriformes, l'autel
	for s in [-1.0, 1.0]:
		var wx: float = 196.0 + s * 10.2
		kit.box(Transform3D(Basis(), W(wx, -38.5, Y + 2.2)), Vector3(0.9, 4.4, 17.0), "gres69", 2.0)
		kit.col_box(Transform3D(Basis(), W(wx, -38.5, Y + 2.2)), Vector3(0.9, 4.4, 17.0))
		var inner: float = wx - s * 0.47
		kit.quad(Transform3D(Basis(Vector3.UP, s * PI * 0.5), W(inner, -36.0, Y + 2.3)), 7.0, 3.5, "fresque69_nil" if s < 0 else "fresque69_barque")
		kit.quad(Transform3D(Basis(Vector3.UP, s * PI * 0.5), W(inner, -43.2, Y + 2.3)), 5.0, 2.5, "fresque69_osiris" if s < 0 else "fresque69_pesee")
		for cz in [-33.5, -38.5, -43.5]:
			kit.papyrus_column(Transform3D(Basis(), W(196.0 + s * 7.6, cz, Y)), 0.55, 5.0)
	kit.box(Transform3D(Basis(), W(196.0, -47.3, Y + 2.2)), Vector3(21.3, 4.4, 0.9), "gres69", 2.0)
	kit.col_box(Transform3D(Basis(), W(196.0, -47.3, Y + 2.2)), Vector3(21.3, 4.4, 0.9))
	kit.box(Transform3D(Basis(), W(196.0, -38.5, Y + 0.04)), Vector3(19.5, 0.08, 17.0), "dalles69_ocre", 2.5, 4)
	# le naos : la petite chapelle du dieu, au fond
	var naos := XZ(W(196.0, -45.0, Y), 0.0, 1.0)
	kit.box(naos * Transform3D(Basis(), Vector3(0, 2.3, 0)), Vector3(6.0, 4.6, 3.2), "gres69", 2.0)
	kit.col_box(naos * Transform3D(Basis(), Vector3(0, 2.3, 0)), Vector3(6.0, 4.6, 3.2))
	kit.quadz(naos * Transform3D(Basis(), Vector3(0, 1.4, 1.62)), 1.6, 2.8, "noir69")
	kit.quadz(naos * Transform3D(Basis(), Vector3(0, 3.6, 1.62)), 3.0, 0.8, "sym69_soleil")
	kit.seated_statue(XZ(W(191.5, -43.6, Y), 0.0, 1.0), 1.25)
	kit.seated_statue(XZ(W(200.5, -43.6, Y), 0.0, 1.0), 1.25)
	# l'autel et ses offrandes
	altar_pos = W(196.0, -38.0, Y)
	kit.box(Transform3D(Basis(), W(196.0, -38.0, Y + 0.5)), Vector3(2.0, 1.0, 1.2), "calc69", 1.2)
	kit.col_box(Transform3D(Basis(), W(196.0, -38.0, Y + 0.5)), Vector3(2.0, 1.0, 1.2))
	for op in [Vector3(-0.6, 1.0, 0.1), Vector3(0.0, 1.0, -0.2), Vector3(0.55, 1.0, 0.15)]:
		kit.jar(W(196.0 + op.x, -38.0 + op.z, Y + op.y), 0.35)
	for bp in [Vector2(193.0, -36.0), Vector2(199.0, -36.0)]:
		var f: Vector3 = kit.brazier(W(bp.x, bp.y, Y), 1.0)
		fire_spots.append([f, 0.45])
	_spot("temple_autel", W(196.0, -36.2, Y + 0.05), Vector3(0, 0, -1), "prier", "t_cour")
	_spot("temple_cour_1", W(192.0, -40.0, Y + 0.05), Vector3(0, 0, -1), "prier", "t_cour")
	_spot("temple_cour_2", W(200.0, -33.0, Y + 0.05), Vector3(-1, 0, 0), "debout", "t_cour")
	_spot("temple_porte", W(193.0, -24.5, Y + 0.05), Vector3(0, 0, 1), "debout", "t_devant")
	smoke_spots.append(W(196.0, -45.0, Y + 4.8))


# =================================================================== derrière : la boulangerie, la Maison de Vie, le potier

func _quartier_nord() -> void:
	# la boulangerie-brasserie de Mérit : une maison, une cour, deux fours, des jarres de bière
	var bak := XZ(W(157.0, -41.0, Y), 0.0, 1.0)
	var bf: Vector3 = kit.mud_house(bak, 10.0, 7.0, 3.4, {"mur": "enduit69_ocre", "escalier": false})
	doors["porte_merit"] = _pt("porte_merit", Vector3(bf.x, Y + 0.05, bf.z))
	_avoid(157.0, -41.0, 6.0)
	for op in [Vector2(151.0, -33.0), Vector2(154.5, -33.0)]:
		kit.oven(XZ(W(op.x, op.y, Y), 0.0, 1.0))
		smoke_spots.append(W(op.x, op.y, Y + 1.4))
	for k in range(6):
		kit.jar(W(160.5 + (k % 3) * 0.7, -33.5 - (k / 3) * 0.7, Y), 0.85, "argile69_terre")
	_spot("four", W(153.0, -31.6, Y + 0.05), Vector3(0, 0, -1), "moudre", "l_152")
	_spot("biere_1", W(163.5, -31.0, Y + 0.05), Vector3(0, 0, -1), "boire", "l_166")
	_spot("biere_2", W(166.0, -32.4, Y + 0.05), Vector3(-1, 0, 0), "assis", "l_166")
	kit.box(Transform3D(Basis(), W(166.0, -33.2, Y + 0.22)), Vector3(1.6, 0.44, 0.45), "gres69", 1.0)
	# deux greniers à coupole
	for gp in [Vector2(150.5, -46.0), Vector2(170.0, -46.5)]:
		kit.granary(Transform3D(Basis(), W(gp.x, gp.y, Y)), 1.4, 3.0)
	# la maison de la prêtresse, son jardin, son bassin aux lotus
	var pr := XZ(W(178.0, -42.0, Y), 0.0, 1.0)
	var pf: Vector3 = kit.mud_house(pr, 9.0, 7.0, 4.0, {"mur": "enduit69_blanc", "escalier": false, "auvent": false})
	doors["porte_neferet"] = _pt("porte_neferet", Vector3(pf.x, Y + 0.05, pf.z))
	_avoid(178.0, -42.0, 6.0)
	var pond := W(176.0, -33.2, Y - 0.35)
	kit.box(Transform3D(Basis(), pond + Vector3(0, 0.25, 0)), Vector3(5.2, 0.5, 2.6), "calc69", 1.5, 1 | 2 | 16 | 32 | 4)
	lotus_water = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4.6, 2.0)
	lotus_water.mesh = pm
	lotus_water.material_override = kit.mat("eau69")
	add_child(lotus_water)
	lotus_water.global_position = pond + Vector3(0, 0.42, 0)
	kit.col_box(Transform3D(Basis(), pond + Vector3(0, 0.25, 0)), Vector3(5.2, 0.5, 2.6))
	objets["lotus"] = pond + Vector3(0, 0.45, 0)
	_spot("jardin_pretresse", W(180.0, -34.5, Y + 0.05), Vector3(-1, 0, 0), "assis", "l_180")
	# la Maison de Vie : l'école des scribes (un portique, des bancs, des étagères de rouleaux)
	var sch := XZ(W(223.0, -41.5, Y), 0.0, 1.0)
	var sf: Vector3 = kit.mud_house(sch, 15.0, 8.0, 4.2, {"mur": "enduit69_blanc", "escalier": false, "auvent": false, "porte_x": -3.0})
	doors["porte_ecole"] = _pt("porte_ecole", Vector3(sf.x, Y + 0.05, sf.z))
	_avoid(223.0, -41.5, 9.0)
	for cx in [-6.0, -2.0, 2.0, 6.0]:
		kit.papyrus_column(sch * Transform3D(Basis(), Vector3(cx, 0, 5.4)), 0.3, 3.4, "calc69", false)
	kit.box(sch * Transform3D(Basis(), Vector3(0, 3.65, 5.0)), Vector3(15.0, 0.3, 2.4), "gres69", 2.0)
	for bx in [-4.0, 1.0, 5.0]:
		kit.box(sch * Transform3D(Basis(), Vector3(bx, 0.22, 6.6)), Vector3(2.2, 0.44, 0.5), "gres69", 1.0)
	_spot("ecole_maitre", sch * Vector3(-5.5, 0.05, 5.5), Vector3(0, 0, 1), "lire", "l_226")
	_spot("ecole_banc_1", sch * Vector3(1.0, 0.05, 6.8), Vector3(0, 0, -1), "assis", "l_226")
	_spot("ecole_banc_2", sch * Vector3(5.0, 0.05, 6.8), Vector3(0, 0, -1), "scribe", "l_226")
	objets["ecole"] = sch * Vector3(0, 0.5, 5.0)
	# l'atelier du potier : un appentis, un tour, un four, des pots qui sèchent
	var pot := XZ(W(239.0, -39.0, Y), 0.0, 1.0)
	var ptf: Vector3 = kit.mud_house(pot, 7.0, 6.0, 3.0, {"mur": "brique69", "escalier": false, "auvent": false})
	doors["porte_ptahmose"] = _pt("porte_ptahmose", Vector3(ptf.x, Y + 0.05, ptf.z))
	kit.awning69(pot * Transform3D(Basis(), Vector3(0, 0, 5.0)), 6.0, 3.0)
	kit.oven(XZ(W(234.5, -32.5, Y), 0.0, 1.0))
	smoke_spots.append(W(234.5, -32.5, Y + 1.4))
	for k2 in range(8):
		kit.jar(pot * Vector3(-2.4 + (k2 % 4) * 1.3, 0.0, 4.2 + (k2 / 4) * 1.1), _rng.randf_range(0.4, 0.75))
	kit.cyl(pot * Transform3D(Basis(), Vector3(1.6, 0.0, 6.0)), 0.35, 0.35, 0.6, "bois69", 10)
	_spot("potier", pot * Vector3(1.6, 0.05, 6.8), Vector3(0, 0, -1), "potier", "l_240")
	# la rue de derrière : des palmiers, des chats
	for pp in [Vector2(186.5, -33.5), Vector2(208.0, -36.0), Vector2(230.0, -46.0), Vector2(146.0, -38.0)]:
		palms.append(W(pp.x, pp.y, Y) if R._rect_dist(pp.x, pp.y, R.TOWN_E) < 0.5 else G(pp.x, pp.y))
	_spot("metier", W(229.5, -16.0, Y + 0.05), Vector3(0, 0, 1), "tisser", "r_228")


# =================================================================== le pont

func _pont() -> void:
	var a: Vector2 = R.BRIDGE[0]
	var b: Vector2 = R.BRIDGE[1]
	var y: float = R.BRIDGE_Y
	var len: float = a.distance_to(b)
	var c: Vector3 = W((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, y)
	var xf := XZ(c, 0.0, 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, -0.1, 0)), Vector3(3.2, 0.2, len), "bois69", 1.2)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -0.1, 0)), Vector3(3.2, 0.2, len))
	kit.walk_boxes.append([xf.affine_inverse(), Vector3(1.7, 2.5, len * 0.5 + 0.3)])
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(), Vector3(s * 1.55, 0.55, 0)), Vector3(0.12, 0.1, len), "bois69", 1.0)
		kit.col_box(xf * Transform3D(Basis(), Vector3(s * 1.55, 0.5, 0)), Vector3(0.12, 1.0, len))
		var n: int = int(len / 3.0)
		for k in range(n + 1):
			kit.cyl(xf * Transform3D(Basis(), Vector3(s * 1.55, -0.1, -len * 0.5 + k * len / n)), 0.06, 0.06, 0.65, "bois69", 5)
	# les piles de pierre dans le fleuve
	for k2 in range(4):
		var pz: float = -len * 0.5 + 6.0 + k2 * (len - 12.0) / 3.0
		var pp: Vector3 = xf * Vector3(0, 0, pz)
		kit.box(Transform3D(xf.basis, Vector3(pp.x, (y - 0.2 + R.RIVER_FLOOR) * 0.5, pp.z)), Vector3(3.6, y - 0.2 - R.RIVER_FLOOR, 1.4), "gres69_sombre", 1.5)
	# les rampes aux deux bouts (du pont au sol)
	for e in [[a, Vector2(0, -1)], [b, Vector2(0, 1)]]:
		var ep: Vector2 = e[0]
		var dirv: Vector2 = e[1]
		var gnd: Vector3 = G(ep.x + dirv.x * 4.0, ep.y + dirv.y * 4.0)
		var top: Vector3 = W(ep.x, ep.y, y)
		if gnd.y < y - 0.1:
			kit.stair(gnd, top, 3.0, "bois69", "")
			var mid: Transform3D = XZ((gnd + top) * 0.5, dirv.x, dirv.y)
			kit.walk_boxes.append([mid.affine_inverse(), Vector3(1.7, 3.0, 2.6)])
	_avoid(134.0, 24.0, 22.0)


# =================================================================== le plateau de Rê

func _plateau() -> void:
	# la Pyramide de Rê
	var pc0: Vector3 = W(R.PYRAMID.x, R.PYRAMID.y, R.PLATEAU_Y - 0.4)
	kit.pyramid(pc0, R.PYRAMID_BASE, R.PYRAMID_H, "calc69_dore", "or69", 0.07)
	pyramid_top = pc0 + Vector3.UP * R.PYRAMID_H
	_avoid(R.PYRAMID.x, R.PYRAMID.y, R.PYRAMID_BASE * 0.75)
	# l'entrée sur la face nord, à 8 m de haut, et l'escalier qui y mène
	var half: float = R.PYRAMID_BASE * 0.5
	var ey: float = 8.0
	var ez: float = R.PYRAMID.y - half + ey * half / R.PYRAMID_H
	var dy: float = R.PLATEAU_Y - 0.4 + ey
	# le porche : son dos s'enfonce dans la face ; la porte sombre regarde le nord
	var porch := XZ(W(R.PYRAMID.x, ez - 0.4, dy), 0.0, -1.0)
	kit.box(porch * Transform3D(Basis(), Vector3(0, 1.5, 0)), Vector3(3.6, 3.0, 3.0), "calc69_ocre", 1.5)
	kit.frustum(porch * Transform3D(Basis(), Vector3(0, 3.0, 0)), 3.8, 3.0, 0.2, 3.0, 1.3, "calc69_ocre", 1.5, false)
	kit.quadz(porch * Transform3D(Basis(), Vector3(0, 1.2, 1.52)), 1.5, 2.2, "noir69")
	kit.quadz(porch * Transform3D(Basis(), Vector3(0, 2.75, 1.53)), 1.8, 0.5, "hiero69")
	# le palier devant la porte, l'escalier qui y monte depuis le plateau
	var land := Transform3D(Basis(), W(R.PYRAMID.x, ez - 2.8, dy - 0.15))
	kit.box(land, Vector3(4.2, 0.3, 1.8), "calc69", 1.5)
	kit.col_box(land, Vector3(4.2, 0.3, 1.8))
	pyramid_door = W(R.PYRAMID.x, ez - 2.8, dy + 0.05)
	kit.stair(W(R.PYRAMID.x, ez - 17.5, R.PLATEAU_Y - 0.1), W(R.PYRAMID.x, ez - 3.7, dy), 3.0, "calc69", "calc69_ocre", 0.5, 0.5)
	# le Sphinx, tourné vers le fleuve (le nord)
	var sp := XZ(G(R.SPHINX.x, R.SPHINX.y + 4.0), 0.0, -1.0)
	var front: Vector3 = kit.sphinx(sp, 0.95)
	sphinx_face = sp * Vector3(0, 8.7 * 0.95, 8.6 * 0.95)
	sphinx_talk = Vector3(front.x, ile.height(front.x, front.z) + 0.05, front.z) + Vector3(0, 0, -1.5)
	_avoid(R.SPHINX.x, R.SPHINX.y + 4.0, 15.0)
	# le temple de la vallée, au bord des champs, et ses deux obélisques
	var vt := XZ(G(R.VALLEY.x, R.VALLEY.y), 0.0, -1.0)
	kit.box(vt * Transform3D(Basis(), Vector3(0, 3.0, 0)), Vector3(16.0, 6.0, 11.0), "gres69_rose", 2.5)
	kit.col_box(vt * Transform3D(Basis(), Vector3(0, 3.0, 0)), Vector3(16.0, 6.0, 11.0))
	kit.box(vt * Transform3D(Basis(), Vector3(0, 6.2, 0)), Vector3(16.6, 0.4, 11.6), "gres69", 2.0)
	kit.quadz(vt * Transform3D(Basis(), Vector3(0, 1.6, 5.51)), 2.0, 3.2, "noir69")
	kit.quadz(vt * Transform3D(Basis(), Vector3(0, 4.3, 5.52)), 8.0, 1.6, "hiero69")
	for ox in [-5.0, 5.0]:
		kit.obelisk(vt * Vector3(ox, 0.0, 8.0), 7.0)
	_avoid(R.VALLEY.x, R.VALLEY.y, 11.0)
	_spot("vallee_priere", vt * Vector3(2.0, 0.05, 7.2), Vector3(0, 0, -1), "prier", "rs_4")
	# la chaussée montante : un ruban de calcaire entre deux parapets
	# (un ruban continu : la route et ses deux parapets suivent la pente sans à-coups)
	var cw: Array = ile.paths_world.get("chaussee", [])
	var run_u: float = 0.0
	for i in range(cw.size() - 1):
		var p0: Vector3 = (cw[i] as Vector3) + Vector3(0, 0.1, 0)
		var p1: Vector3 = (cw[i + 1] as Vector3) + Vector3(0, 0.1, 0)
		var mid: Vector3 = (p0 + p1) * 0.5
		var dz: float = p1.z - p0.z
		var slope: float = atan2(p1.y - p0.y, absf(dz))
		var bs := Basis(Vector3.RIGHT, -slope)
		var fwd: Vector3 = (p1 - p0).normalized()
		var side := Vector3(1, 0, 0)
		var seg: float = p0.distance_to(p1)
		var u0: float = run_u / 3.0
		var u1: float = (run_u + seg) / 3.0
		run_u += seg
		var up: Vector3 = side.cross(fwd).normalized()
		if up.y < 0.0:
			up = -up
		kit.quad4("calc69_dore", p0 - side * 2.98, p0 + side * 2.98, p1 + side * 2.98, p1 - side * 2.98, up, Vector2(0, u0), Vector2(2.0, u0), Vector2(2.0, u1), Vector2(0, u1))
		for s in [-1.0, 1.0]:
			var si: Vector3 = side * s
			var lo := Vector3(0, -0.7, 0)
			var hi := Vector3(0, 0.9, 0)
			# dehors, dedans, le dessus
			kit.quad4("calc69_ocre", p0 + si * 3.45 + lo, p1 + si * 3.45 + lo, p1 + si * 3.45 + hi, p0 + si * 3.45 + hi, si, Vector2(u0, 0.8), Vector2(u1, 0.8), Vector2(u1, 0.0), Vector2(u0, 0.0))
			kit.quad4("calc69_ocre", p0 + si * 2.98, p1 + si * 2.98, p1 + si * 2.98 + hi, p0 + si * 2.98 + hi, -si, Vector2(u0, 0.45), Vector2(u1, 0.45), Vector2(u1, 0.0), Vector2(u0, 0.0))
			kit.quad4("calc69_ocre", p0 + si * 2.98 + hi, p1 + si * 2.98 + hi, p1 + si * 3.45 + hi, p0 + si * 3.45 + hi, up, Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 0.2), Vector2(u0, 0.2))
			# les bouts des parapets
			if i == 0 or i == cw.size() - 2:
				var e: Vector3 = p0 if i == 0 else p1
				var en: Vector3 = -fwd if i == 0 else fwd
				kit.quad4("calc69_ocre", e + si * 2.98 + lo, e + si * 3.45 + lo, e + si * 3.45 + hi, e + si * 2.98 + hi, en, Vector2(0, 0.8), Vector2(0.2, 0.8), Vector2(0.2, 0), Vector2(0, 0))
			kit.col_box(Transform3D(bs, mid + Vector3(s * 3.2, 0.45, 0)), Vector3(0.45, 0.9, absf(dz) + 0.05))
	# les mastabas, les pyramides des reines
	for mb in [[152.0, 146.0, 11.0, 7.0], [152.0, 166.0, 10.0, 7.0], [248.0, 138.0, 11.0, 7.0], [250.0, 160.0, 9.0, 7.0]]:
		kit.mastaba(Transform3D(Basis(), G(float(mb[0]), float(mb[1]), -0.3)), float(mb[2]), float(mb[3]), 4.0)
		_avoid(float(mb[0]), float(mb[1]), 7.0)
	objets["mastaba_chat"] = G(152.0, 172.0, 0.1)
	for qp in [[166.0, 192.0, 13.0], [236.0, 190.0, 12.0]]:
		kit.pyramid(G(float(qp[0]), float(qp[1]), -0.4), float(qp[2]), float(qp[2]) * 0.62, "calc69_ocre", "calc69", 0.05)
		_avoid(float(qp[0]), float(qp[1]), float(qp[2]) * 0.8)


# =================================================================== le graphe des habitants

func _graph() -> void:
	var xs := [152.0, 164.0, 176.0, 188.0, 196.0, 206.0, 216.0, 228.0, 238.0]
	var quay: Array = []
	var street: Array = []
	for x in xs:
		quay.append(_pt("q_%d" % int(x), W(x, 5.0, Y + 0.05)))
		street.append(_pt("r_%d" % int(x), W(x, -14.0, Y + 0.05)))
	_chain(quay)
	_chain(street)
	for x2 in [164, 176, 188, 196, 216, 238]:
		_link("q_%d" % x2, "r_%d" % x2)
	# la place du marché
	_pt("sq_c", W(179.0, -3.0, Y + 0.05))
	for k in ["q_176", "q_188", "r_176", "r_188"]:
		_link("sq_c", k)
	for st in ["etal_pain", "etal_pots", "etal_lin", "etal_poisson"]:
		_link("m_" + st, "sq_c")
	# le débarcadère (par l'escalier)
	_pt("esc_haut", W(161.0, 8.0, Y + 0.05))
	_pt("esc_bas", W(171.5, 11.4, 0.25))
	_pt("deb", W(176.5, 12.0, 0.25))
	_chain(["q_164", "esc_haut", "esc_bas", "deb"])
	# vers le temple
	_pt("t_devant", W(196.0, -21.0, Y + 0.05))
	_pt("t_porte", W(196.0, -27.0, Y + 0.05))
	_pt("t_cour", W(196.0, -34.5, Y + 0.05))
	_chain(["r_196", "t_devant", "t_porte", "t_cour"])
	# la rue de derrière (par les ruelles)
	_pt("al_160", W(159.6, -21.0, Y + 0.05))
	_pt("al_171", W(171.6, -21.0, Y + 0.05))
	_pt("al_218", W(218.6, -21.0, Y + 0.05))
	_pt("al_230", W(230.6, -21.0, Y + 0.05))
	for xl in [152.0, 166.0, 180.0, 212.0, 226.0, 240.0]:
		_pt("l_%d" % int(xl), W(xl, -30.0, Y + 0.05))
	_chain(["l_152", "l_166", "l_180"])
	_chain(["l_212", "l_226", "l_240"])
	_link("r_164", "al_160")
	_link("al_160", "l_166")
	_link("r_176", "al_171")
	_link("al_171", "l_180")
	_link("r_216", "al_218")
	_link("al_218", "l_212")
	_link("r_228", "al_230")
	_link("al_230", "l_226")
	_link("l_180", "t_devant")
	_link("l_212", "t_devant")
	# les portes : chacune reliée au point le plus proche
	for d in doors:
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
	# vers le pont, la rive sud et les champs, le temple de la vallée
	_pt("v_ouest", W(147.0, -6.0, Y + 0.05))
	_link("v_ouest", "r_152")
	_link("v_ouest", "q_152")
	_pt("pont_n", G(134.0, 2.0, 0.05))
	_pt("pont_1", W(134.0, 12.0, R.BRIDGE_Y + 0.05))
	_pt("pont_2", W(134.0, 24.0, R.BRIDGE_Y + 0.05))
	_pt("pont_3", W(134.0, 36.0, R.BRIDGE_Y + 0.05))
	_pt("pont_s", G(134.0, 46.0, 0.05))
	_chain(["v_ouest", "pont_n", "pont_1", "pont_2", "pont_3", "pont_s"])
	_pg("rs_1", 146.0, 46.0)
	_pg("rs_2", 164.0, 55.0)
	_pg("rs_3", 184.0, 60.0)
	_pg("rs_4", 196.0, 71.0)
	_pg("rs_5", 222.0, 58.0)
	_pg("rs_6", 244.0, 62.0)
	_chain(["pont_s", "rs_1", "rs_2", "rs_3", "rs_4"])
	_chain(["rs_3", "rs_5", "rs_6"])
	_spot("champ_1", G(166.0, 62.0, 0.05), Vector3(0, 0, 1), "jardiner", "rs_2")
	_spot("champ_2", G(222.0, 64.0, 0.05), Vector3(1, 0, 0), "jardiner", "rs_5")
	_spot("champ_3", G(244.0, 68.0, 0.05), Vector3(-1, 0, 0), "jardiner", "rs_6")


func _nearest(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		var ks: String = str(k)
		if ks.begins_with("porte"):
			continue
		var d: float = (points[k] as Vector3).distance_to(p) + absf((points[k] as Vector3).y - p.y) * 3.0
		if d < bd:
			bd = d
			best = ks
	return best


# =================================================================== le monde autour

func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


## La barque du joueur ne passe pas sous le pont ni par-dessus le débarcadère.
func blocks_boat(p: Vector3) -> bool:
	var l: Vector2 = R.L(p.x, p.z)
	if absf(l.x - R.BRIDGE[0].x) < 3.0 and l.y > R.BRIDGE[0].y and l.y < R.BRIDGE[1].y:
		return true
	if l.x > 168.0 and l.x < 184.0 and l.y < R.QUAY_E_Z + 5.2 and l.y > R.QUAY_E_Z - 1.0:
		return true
	return false


func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	if l.x > 185.5 and l.x < 206.5 and l.y > -48.0 and l.y < -30.0:
		return "soleils_temple_re"
	return ""

extends Node3D
## V69 : Aztlán, la cité aztèque de l'Île des Trois Soleils, sur son île au milieu du Lac de la
## Lune, reliée au rivage par deux chaussées (au nord, vers Yaxché ; à l'est, vers Per-Hâpy) :
##  - le Grand Temple : quatre gradins, l'escalier double à l'ouest (rouge au sud, bleu au
##    nord), au sommet les deux sanctuaires de Tlaloc (bleu et blanc) et de Huitzilopochtli
##    (rouge) ; la porte du Cinquième Soleil s'ouvre entre eux (voir cinq_soleils_v69.gd) ;
##  - la grande place, le marché (le tianguis), le calmecac (l'école des prêtres), le palais ;
##  - des maisons d'adobe blanchies ;
##  - au sud du lac, les chinampas (les jardins flottants), leurs cases, leurs pirogues, et une
##    passerelle de bois qui les relie à la ville ;
##  - l'eau du lac.

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
var willows: Array = []                   # Vector3 : les saules (ahuejotes) au bord des chinampas
var lake_water: MeshInstance3D
var temple_top := Vector3.ZERO            # le milieu du sommet du Grand Temple
var shrine_tlaloc := Vector3.ZERO         # devant le sanctuaire de Tlaloc
var shrine_huitzi := Vector3.ZERO         # devant le sanctuaire de Huitzilopochtli
var temple_gate := Vector3.ZERO           # entre les deux : la dalle du Cinquième Soleil
var _rng := RandomNumberGenerator.new()

const Y := R.AZTLAN_Y
const TEMPLE := Vector2(-110.0, 104.0)
const T_BASE: float = 28.0
const T_TIERS: int = 4
const T_TH: float = 4.4
const T_SHRINK: float = 2.8
const FOOTBRIDGE := [Vector2(-125.0, 146.5), Vector2(-125.0, 161.0)]


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
	return _pt(name, G(x, z, 0.05))


func _avoid(x: float, z: float, r: float) -> void:
	var w: Vector3 = R.W(x, z)
	flora_avoid.append([Vector2(w.x, w.z), r])


func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6930
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6931
	_lac()
	_grand_temple()
	_place()
	_maisons()
	_chaussees()
	_chinampas()
	kit.commit()
	_graph()
	for f in kit.fires69:
		fire_spots.append(f)
	print("ILE_MANGA_V69: Aztlán bâtie, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


# =================================================================== le lac

func _lac() -> void:
	var c: Vector3 = W(R.LAKE.x, R.LAKE.y, R.LAKE_Y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 96
	var rings: int = 6
	for ri in range(rings):
		var r0: float = float(ri) / rings
		var r1: float = float(ri + 1) / rings
		for i in range(n):
			var a0: float = TAU * i / n
			var a1: float = TAU * (i + 1) / n
			var q: Array = []
			for pr in [[r0, a0], [r1, a0], [r1, a1], [r0, a1]]:
				var rr: float = float(pr[0]) * 1.06
				q.append(Vector3(cos(float(pr[1])) * R.LAKE_AX.x * rr, 0.0, sin(float(pr[1])) * R.LAKE_AX.y * rr))
			for v in [q[0], q[2], q[1], q[0], q[3], q[2]]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2((v as Vector3).x, (v as Vector3).z) * 0.1)
				st.add_vertex(v)
	lake_water = MeshInstance3D.new()
	lake_water.name = "Lac_de_la_Lune"
	lake_water.mesh = st.commit()
	lake_water.material_override = kit.mat("eau69")
	lake_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake_water)
	lake_water.global_position = c


# =================================================================== le Grand Temple

func _grand_temple() -> void:
	var c: Vector3 = W(TEMPLE.x, TEMPLE.y, Y)
	temple_top = kit.step_pyramid(c, T_BASE, T_BASE, T_TIERS, T_TH, T_SHRINK, "tezo69", "dalles69", 2.5)
	_avoid(TEMPLE.x, TEMPLE.y, T_BASE * 0.75)
	var top_w: float = T_BASE - T_SHRINK * T_TIERS
	# l'escalier double, à l'ouest : bleu au nord (Tlaloc), rouge au sud (Huitzilopochtli)
	var run: float = (T_BASE - top_w) * 0.5 + 5.0
	for s in [-1.0, 1.0]:
		var foot := c + Vector3(-(top_w * 0.5 + run), 0, s * 3.3)
		var head := Vector3(c.x - top_w * 0.5, temple_top.y, c.z + s * 3.3)
		kit.stair(foot, head, 5.6, "tezo69", "enduit69_rouge" if s > 0 else "enduit69_bleu", 0.8, 0.6)
		kit.serpent_head(XZ(foot + Vector3(-0.4, 0, s * 3.1), -1.0, 0.0), 1.0, "tezo69")
	# la pierre de Coyolxauhqui, au pied de l'escalier de Huitzilopochtli
	var coy: Vector3 = c + Vector3(-(top_w * 0.5 + run) - 4.0, 0.05, 4.5)
	kit.cyl(Transform3D(Basis(), coy), 2.2, 2.2, 0.35, "tezo69", 28)
	kit.disc(Transform3D(Basis(), coy + Vector3(0, 0.36, 0)), 2.1, "frise69", 28, 4.2)
	objets["coyolxauhqui"] = coy + Vector3(0, 0.4, 0)
	# les deux sanctuaires
	var tl := XZ(temple_top + Vector3(1.2, 0, -4.2), -1.0, 0.0)
	shrine_tlaloc = kit.shrine(tl, 6.6, 6.0, 4.4, "bleu")
	var hu := XZ(temple_top + Vector3(1.2, 0, 4.2), -1.0, 0.0)
	shrine_huitzi = kit.shrine(hu, 6.6, 6.0, 4.4, "rouge")
	temple_gate = temple_top + Vector3(-2.6, 0.05, 0.0)
	# entre les deux, une dalle ronde gravée (la porte du Cinquième Soleil)
	kit.disc(Transform3D(Basis(), temple_gate + Vector3(0, 0.02, 0)), 1.5, "frise69", 24, 3.0)
	# devant chaque sanctuaire, un brasero ; une pierre à offrandes (chacmool) devant Tlaloc
	for p in [shrine_tlaloc, shrine_huitzi]:
		var f: Vector3 = kit.brazier(p + Vector3(-0.8, 0, (1.6 if p == shrine_huitzi else -1.6)), 1.0)
		fire_spots.append([f, 0.5])
	smoke_spots.append(shrine_huitzi + Vector3(-0.8, 1.6, 1.6))
	var ch := XZ(shrine_tlaloc + Vector3(-1.8, 0, 0), -1.0, 0.0)
	kit.box(ch * Transform3D(Basis(), Vector3(0, 0.35, 0)), Vector3(0.9, 0.7, 1.8), "tezo69", 1.0)
	kit.box(ch * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.95, -0.55)), Vector3(0.5, 0.6, 0.45), "tezo69", 1.0)
	kit.cyl(ch * Transform3D(Basis(), Vector3(0, 0.72, 0.15)), 0.3, 0.32, 0.1, "turq69", 12)
	kit.col_box(ch * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(0.9, 1.0, 1.8))


# =================================================================== la place, le marché, le calmecac, le palais

func _place() -> void:
	# le dallage est dans le sol (la carte des sols) ; le marché, à l'ouest de la place
	var stalls := [[-152.0, 98.0, "toile_rouge", "fruits", "tianguis_cacao"], [-152.0, 108.0, "toile_bleu", "caisses", "tianguis_copal"], [-152.0, 118.0, "toile", "fruits", "tianguis_mais"], [-144.0, 124.0, "toile_sale", "caisses", "tianguis_pots"]]
	for s in stalls:
		var face := Vector2(1, 0) if float(s[0]) < -150.0 else Vector2(0, -1)
		var xf: Transform3D = XZ(W(float(s[0]), float(s[1]), Y), face.x, face.y)
		kit.stall(xf, str(s[2]), str(s[3]))
		_spot(str(s[4]), xf * Vector3(0, 0.05, -1.0), Vector3(face.x, 0, face.y), "comptoir", "pl_o")
		_avoid(float(s[0]), float(s[1]), 2.2)
	for jp in [Vector2(-149.0, 102.5), Vector2(-149.5, 113.0), Vector2(-140.0, 127.0)]:
		kit.jar(W(jp.x, jp.y, Y), 0.7, "argile69_rouge")
	_spot("place_a1", W(-138.0, 104.0, Y + 0.05), Vector3(1, 0, 0), "debout", "pl_c")
	_spot("place_a2", W(-140.0, 112.0, Y + 0.05), Vector3(0, 0, -1), "debout", "pl_c")
	_spot("musique", W(-136.0, 96.0, Y + 0.05), Vector3(1, 0, 0), "tambour", "pl_c")
	_spot("danse_a", W(-139.0, 94.5, Y + 0.05), Vector3(1, 0, 0), "danse", "pl_c")
	for tp in [Vector2(-134.0, 92.0), Vector2(-134.0, 116.0), Vector2(-146.0, 92.0), Vector2(-146.0, 116.0)]:
		kit.torch_post(W(tp.x, tp.y, Y), 2.6)
	# le calmecac : l'école des prêtres (deux portes), un portique peint
	var cx := XZ(W(-143.0, 86.0, Y), 0.0, 1.0)
	kit.aztec_house(cx * Transform3D(Basis(), Vector3(0, 0, 0)), 12.0, 7.0, 4.2, {"mur": "enduit69_blanc", "porte_x": -2.8, "rideau": "bleu"})
	kit.quadz(cx * Transform3D(Basis(), Vector3(2.8, 1.0, 0.012)), 1.0, 2.0, "noir69")
	kit.quadz(cx * Transform3D(Basis(), Vector3(2.8, 1.15, 0.03)), 1.0, 1.7, "lin69_rouge")
	doors["porte_cuauhtli"] = _pt("porte_cuauhtli", cx * Vector3(-2.8, 0.05, 1.3))
	doors["porte_citlali"] = _pt("porte_citlali", cx * Vector3(2.8, 0.05, 1.3))
	for px in [-5.0, -1.0, 1.0, 5.0]:
		kit.cyl(cx * Transform3D(Basis(), Vector3(px, 0, 2.4)), 0.22, 0.22, 3.2, "enduit69_rouge", 10)
	kit.box(cx * Transform3D(Basis(), Vector3(0, 3.3, 1.6)), Vector3(12.0, 0.2, 2.2), "frise69", 2.0)
	_spot("calmecac_cours", cx * Vector3(-1.0, 0.05, 3.4), Vector3(0, 0, 1), "enseigner", "pl_n")
	_spot("calmecac_codex", cx * Vector3(3.5, 0.05, 2.0), Vector3(0, 0, 1), "lire", "pl_n")
	objets["codex"] = cx * Vector3(3.5, 1.0, 1.0)
	_avoid(-143.0, 82.5, 8.0)
	# le palais : une maison plus grande, un patio
	var pa := XZ(W(-142.0, 133.0, Y), 0.0, -1.0)
	kit.aztec_house(pa, 13.0, 6.5, 4.6, {"mur": "enduit69_ocre", "rideau": "vert", "patio": false})
	doors["porte_mixtli"] = _pt("porte_mixtli", pa * Vector3(0, 0.05, 1.3))
	_spot("guerrier", pa * Vector3(3.5, 0.05, 3.0), Vector3(0, 0, -1), "bras_croises", "pl_s")
	_avoid(-142.0, 136.0, 8.0)


## [x, z, orientation (dx, dz), largeur, profondeur, porte]
const MAISONS := [
	[-104.0, 80.0, Vector2(0, 1), 8.0, 6.0, "porte_nenetl"],
	[-104.0, 130.0, Vector2(0, -1), 8.0, 6.0, "porte_tochtli"],
	[-92.0, 124.0, Vector2(-1, 0), 7.0, 5.5, "porte_coyotl"],
	[-92.0, 90.0, Vector2(-1, 0), 7.0, 5.5, ""],
	[-118.0, 136.0, Vector2(0, -1), 7.0, 5.5, ""],
	[-130.0, 76.0, Vector2(0, 1), 6.0, 5.0, ""],
]


## Les maisons sans habitant nommé : [x, z, orientation, largeur, profondeur]
const MAISONS_RUE := [
	[-158.0, 99.0, Vector2(1, 0), 7.0, 4.5],
	[-158.0, 108.5, Vector2(1, 0), 7.5, 4.5],
	[-158.0, 118.0, Vector2(1, 0), 7.0, 4.5],
	[-116.5, 80.0, Vector2(0, 1), 7.0, 5.0],
]


func _maisons() -> void:
	for m in MAISONS:
		var dirv: Vector2 = m[2]
		var xf: Transform3D = XZ(W(float(m[0]), float(m[1]), Y), dirv.x, dirv.y)
		var front: Vector3 = kit.aztec_house(xf, float(m[3]), float(m[4]), 3.4, {"mur": ["enduit69_blanc", "enduit69_ocre", "enduit69_rose"][_rng.randi() % 3], "rideau": ["rouge", "bleu", "jaune"][_rng.randi() % 3]})
		_avoid(float(m[0]), float(m[1]), 6.0)
		if str(m[5]) != "":
			doors[str(m[5])] = _pt(str(m[5]), Vector3(front.x, Y + 0.05, front.z))
	# l'atelier du potier : des jarres de Tlaloc qui sèchent au soleil
	for k in range(5):
		kit.jar(W(-96.5, 118.5 + k * 1.1, Y), 0.7, "argile69_bleu" if k % 2 == 0 else "argile69")
	_spot("potier_az", W(-96.0, 117.0, Y + 0.05), Vector3(0, 0, 1), "potier", "e_s")
	objets["atelier_potier"] = W(-96.5, 120.0, Y + 0.5)
	# derrière le marché, une rue de maisons d'adobe ; une autre au nord, près de la chaussée
	var r2 := RandomNumberGenerator.new()
	r2.seed = 6939
	for m2 in MAISONS_RUE:
		var d2: Vector2 = m2[2]
		var xf2: Transform3D = XZ(W(float(m2[0]), float(m2[1]), Y), d2.x, d2.y)
		kit.aztec_house(xf2, float(m2[3]), float(m2[4]), 3.2, {"mur": ["enduit69_blanc", "enduit69_ocre", "enduit69_rose"][r2.randi() % 3], "rideau": ["rouge", "bleu", "jaune", "vert"][r2.randi() % 4]})
		_avoid(float(m2[0]) - d2.x * 2.5, float(m2[1]) - d2.y * 2.5, 5.0)
		# sur le toit-terrasse, des pots de fleurs et de maïs
		for k3 in range(3):
			var tp: Vector3 = xf2 * Vector3(r2.randf_range(-2.4, 2.4), 3.55, -r2.randf_range(1.0, 3.4))
			kit.jar(tp, 0.45, "argile69")


# =================================================================== les chaussées

func _chaussees() -> void:
	for cw in R.CAUSEWAYS:
		var a: Vector2 = cw[0]
		var b: Vector2 = cw[1]
		var len: float = a.distance_to(b)
		var n: int = int(len / 9.0)
		for k in range(n + 1):
			var p: Vector2 = a.lerp(b, float(k) / n)
			var side := Vector2(-(b - a).y, (b - a).x).normalized()
			if k % 2 != 0:
				continue
			for s in [-1.0, 1.0]:
				var q: Vector2 = p + side * s * 2.9
				kit.torch_post(W(q.x, q.y, R.CAUSEWAY_Y), 2.0)
		# des parapets bas
		for s2 in [-1.0, 1.0]:
			var side2 := Vector2(-(b - a).y, (b - a).x).normalized()
			var m: Vector2 = (a + b) * 0.5 + side2 * s2 * 3.05
			var xf := XZ(W(m.x, m.y, R.CAUSEWAY_Y + 0.25), (b - a).x, (b - a).y)
			kit.box(xf, Vector3(0.3, 0.5, len), "tezo69", 2.0)
			kit.col_box(xf, Vector3(0.3, 0.5, len))


# =================================================================== les chinampas

func _chinampas() -> void:
	# la passerelle de bois de la ville aux jardins
	var a: Vector2 = FOOTBRIDGE[0]
	var b: Vector2 = FOOTBRIDGE[1]
	var c := W((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, R.LAKE_Y + 0.75)
	var xf := XZ(c, 0.0, 1.0)
	var len: float = a.distance_to(b)
	kit.box(xf, Vector3(2.2, 0.16, len + 1.0), "bois69", 1.0)
	kit.col_box(xf, Vector3(2.2, 0.16, len + 1.0))
	kit.walk_boxes.append([xf.affine_inverse(), Vector3(1.2, 2.5, len * 0.5 + 0.6)])
	for k in range(4):
		for s in [-1.0, 1.0]:
			kit.cyl(xf * Transform3D(Basis(), Vector3(s * 1.0, -1.6, -len * 0.5 + k * len / 3.0)), 0.08, 0.08, 1.6, "bois69", 5)
	# des cases sur les planches, des pirogues dans les canaux, des saules aux coins
	var huts := [[Vector2(-120.0, 170.0), "porte_xochitl"], [Vector2(-160.0, 152.0), "porte_pilli"], [Vector2(-190.0, 128.0), ""], [Vector2(-86.0, 176.0), ""]]
	for h in huts:
		var p: Vector2 = _plot_center(h[0])
		var hx := XZ(W(p.x, p.y, R.LAKE_Y + 0.42), 1.0, 0.0)
		var front: Vector3 = kit.maya_hut(hx, 3.8, 2.6, {"mur": "brique69", "h": 1.6, "toit_h": 2.4})
		if str(h[1]) != "":
			doors[str(h[1])] = _pt(str(h[1]), Vector3(front.x, R.LAKE_Y + 0.47, front.z))
		objets[str(h[1]) if str(h[1]) != "" else "case_%d" % huts.find(h)] = W(p.x, p.y, R.LAKE_Y + 0.5)
		_avoid(p.x, p.y, 3.5)
	for cp in [Vector2(-130.0, 168.0), Vector2(-152.0, 150.0), Vector2(-108.0, 178.0), Vector2(-176.0, 140.0)]:
		var cc: Vector2 = _canal_center(cp)
		kit.canoe(XZ(W(cc.x, cc.y, R.LAKE_Y - 0.12), 0.0, 1.0), 4.2)
	for k2 in range(28):
		var a2: float = deg_to_rad(_rng.randf_range(70.0, 214.0))
		var q2: float = _rng.randf_range(0.66, 0.96)
		var lx: float = R.LAKE.x + cos(a2) * R.LAKE_AX.x * q2
		var lz: float = R.LAKE.y + sin(a2) * R.LAKE_AX.y * q2
		var pc2: Vector2 = _plot_center(Vector2(lx, lz))
		# au bord de la planche (à 2 m du milieu, vers l'ouest)
		willows.append(W(pc2.x - 2.1, pc2.y + _rng.randf_range(-9.0, 9.0), R.LAKE_Y + 0.42))
	_spot("chinampa_1", W(_plot_center(Vector2(-128.0, 172.0)).x, _plot_center(Vector2(-128.0, 172.0)).y, R.LAKE_Y + 0.47), Vector3(0, 0, 1), "jardiner", "ch_1")
	_spot("chinampa_2", W(_plot_center(Vector2(-150.0, 160.0)).x, _plot_center(Vector2(-150.0, 160.0)).y, R.LAKE_Y + 0.47), Vector3(0, 0, 1), "jardiner", "ch_2")


## Le milieu de la planche de chinampa la plus proche (repère île).
func _plot_center(p: Vector2) -> Vector2:
	var ux: float = fposmod(p.x + 300.0, 7.2)
	var vz: float = fposmod(p.y + 300.0, 26.0)
	return Vector2(p.x - ux + 2.5, p.y - vz + 12.2)


## Le milieu du canal le plus proche (à l'est de la planche).
func _canal_center(p: Vector2) -> Vector2:
	var pc: Vector2 = _plot_center(p)
	return Vector2(pc.x + 3.6, pc.y)


# =================================================================== le graphe

func _graph() -> void:
	# la place, autour du temple
	_pp("pl_c", -140.0, 108.0)
	_pp("pl_n", -140.0, 92.0)
	_pp("pl_s", -140.0, 125.0)
	_pp("pl_o", -148.0, 108.0)
	_chain(["pl_n", "pl_c", "pl_s"])
	_link("pl_c", "pl_o")
	# le pied de l'escalier, le sommet (entre les deux sanctuaires)
	var top_w: float = T_BASE - T_SHRINK * T_TIERS
	var run: float = (T_BASE - top_w) * 0.5 + 5.0
	_pp("t_bas", TEMPLE.x - top_w * 0.5 - run - 1.5, TEMPLE.y + 3.3)
	_pt("t_haut", Vector3(temple_gate.x - 1.0, temple_top.y + 0.05, temple_gate.z + 3.3))
	_chain(["pl_c", "t_bas", "t_haut"])
	_spot("priere_tlaloc", shrine_tlaloc + Vector3(-0.6, 0.05, 0.0), Vector3(1, 0, 0), "prier", "t_haut")
	_spot("priere_huitzi", shrine_huitzi + Vector3(-0.6, 0.05, 0.0), Vector3(1, 0, 0), "prier", "t_haut")
	# le tour de l'île : au nord, à l'est, au sud du temple
	_pp("n_o", -128.0, 80.0)
	_pp("n_e", -110.0, 84.0)
	_pp("e_n", -92.0, 100.0)
	_pp("e_s", -95.0, 114.0)
	_pp("s_e", -108.0, 124.0)
	_pp("s_o", -126.0, 126.0)
	_chain(["pl_n", "n_o", "n_e", "e_n", "e_s", "s_e", "s_o", "pl_s"])
	# la chaussée du nord (vers le rivage), celle de l'est
	_pp("cn_1", -125.0, 64.0)
	_pp("cn_2", -125.0, 46.0)
	_pp("cn_rive", -125.0, 27.0)
	_chain(["n_o", "cn_1", "cn_2", "cn_rive"])
	_pp("ce_1", -80.0, 108.0)
	_pp("ce_2", -52.0, 108.0)
	_pp("ce_rive", -22.0, 108.0)
	_chain(["e_n", "ce_1", "ce_2", "ce_rive"])
	_link("e_s", "ce_1")
	# la passerelle et les chinampas
	_pp("pas_n", -125.0, 141.0)
	_pt("pas_m", W(-125.0, 154.0, R.LAKE_Y + 0.85))
	_pp("pas_s", -125.0, 163.0)
	_chain(["s_o", "pas_n", "pas_m", "pas_s"])
	var c1: Vector2 = _plot_center(Vector2(-128.0, 172.0))
	var c2: Vector2 = _plot_center(Vector2(-150.0, 160.0))
	_pt("ch_1", W(c1.x + 0.0, c1.y - 6.0, R.LAKE_Y + 0.47))
	_pt("ch_2", W(c2.x, c2.y - 6.0, R.LAKE_Y + 0.47))
	_chain(["pas_s", "ch_1", "ch_2"])
	# les portes
	for d in doors:
		var p: Vector3 = points[doors[d]]
		var best: String = ""
		var bd: float = INF
		for k2 in points:
			if str(k2).begins_with("porte"):
				continue
			var dd: float = (points[k2] as Vector3).distance_to(p) + absf((points[k2] as Vector3).y - p.y) * 4.0
			if dd < bd:
				bd = dd
				best = str(k2)
		_link(str(doors[d]), best)


func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	if l.distance_to(R.AZTLAN) < R.AZTLAN_R + 2.0:
		return "soleils_azteque"
	if R.chinampa(l.x, l.y) >= 0.0:
		return "soleils_chinampas"
	return ""

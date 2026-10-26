extends Node3D
## V68 : Port-Coutelas et ce qu'on a bâti sur l'Île de la Balafre (le relief : ile_pirate_v68.gd ;
## les pièces : pirate_kit_v68.gd ; les navires : navire_v68.gd).
##  - le quai de pierre, ses deux jetées, les pontons, les grues, les canons, la marchandise ;
##  - trois navires : Le Requin Borgne (galion, ponton ouest), La Veuve Écarlate (brick, ponton
##    est), La Morue Enragée (sloop, à l'ancre au milieu de la baie) ; Le Sans-Pitié couché sur
##    la grève de carénage, ses échafaudages, l'atelier de Gwen Calfat ;
##  - la Place de la Potence (la potence, le puits, l'étal des perroquets, la tente du tatoueur) ;
##  - deux tripots où l'on entre : Le Crâne Fendu (rhum, grog, dés, la scène du violoneux) et
##    La Dent du Requin (la grande table du croupier) ;
##  - le receleur, le chirurgien-barbier, la forge de Brutus, la tour du cartographe, la
##    résidence du Gouverneur, les cases des équipages ;
##  - dans l'île : le Fort Maudit, le Cimetière des Pirates, le camp abandonné, le Rocher du
##    Crâne au fond du Cirque (on entre dans le crâne : le trésor), la baleine de la Plage des Os.
## Il fournit aux habitants leurs lieux (spots), leurs points de passage (points, graph).

const R = preload("res://scripts/ile_pirate_v68.gd")
const Kit = preload("res://scripts/pirate_kit_v68.gd")
const Navire = preload("res://scripts/navire_v68.gd")

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var objets: Dictionary = {}               # nom -> Vector3 (objets de quête posés dans le monde)
var doors: Dictionary = {}                # maison -> point devant la porte
var interiors: Array = []                 # [nom, centre, demi-taille (Vector2 monde), hauteur du plancher]
var flora_avoid: Array = []               # [Vector2, rayon]
var ships: Dictionary = {}                # id -> navire_v68
var smoke_spots: Array = []
var fire_spots: Array = []                # [Vector3, échelle]
var dice_tables: Dictionary = {}          # nom -> {pos, sieges: [spots]}
var gallows_rope: Node3D
var well_pos := Vector3.ZERO
var skull_center := Vector3.ZERO          # le Rocher du Crâne (au sol, au milieu)
var skull_inside := Vector3.ZERO          # dedans, là où brille le trésor
var treasure_pos := Vector3.ZERO
var cirque_center := Vector3.ZERO
var perch_pos := Vector3.ZERO             # le perchoir du camp (le perroquet Amiral)
var fort_center := Vector3.ZERO
var crypt_pos := Vector3.ZERO             # le mausolée du cimetière
var torches: Array = []                   # Vector3 (les torches du Cirque, allumées la nuit)
var mud_water: MeshInstance3D
var extra_palms: Array = []               # Vector3 : des palmiers plantés entre les maisons (pour la flore)
var _rng := RandomNumberGenerator.new()


# =================================================================== repères

func W(x: float, z: float, y: float) -> Vector3:
	return R.W(x, z, y)


## Un point au sol (repère île), dy au-dessus du relief.
func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func TY(x: float, z: float) -> float:
	return R.town_y(x, z)


## Repère posé en p, la façade (-Z local) tournée vers la direction monde (dx, dz).
func XF(p: Vector3, dx: float, dz: float) -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3(dx, 0.0, dz).normalized(), Vector3.UP), p)


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String = "") -> void:
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


## Un point de passage au sol (repère île).
func _pg(name: String, x: float, z: float) -> String:
	return _pt(name, G(x, z, 0.05))


## La hauteur d'un plancher posé sur un rectangle (repère île) : le plus haut du sol dessous.
func _floor(x0: float, z0: float, x1: float, z1: float) -> float:
	var top: float = -99.0
	for i in range(5):
		for j in range(5):
			var x: float = lerpf(x0, x1, i / 4.0)
			var z: float = lerpf(z0, z1, j / 4.0)
			var w: Vector3 = R.W(x, z)
			top = maxf(top, ile.height(w.x, w.z))
	return top + 0.08


func _socle(xf: Transform3D, w: float, d: float, depth: float = 1.4) -> void:
	kit.box(xf * Transform3D(Basis(), Vector3(0, -depth * 0.5, d * 0.5)), Vector3(w + 0.3, depth, d + 0.3), "pierrefort_sombre", 2.0, 63 - 4 - 8)


## Le plancher des pontons (au ras de la margelle du quai).
func _pier_y() -> float:
	return TY(0.0, R.QUAY_Z) + 0.06


func _sign(xf: Transform3D, w: float, h: float, key: String) -> void:
	kit.box(xf, Vector3(w + 0.1, h + 0.1, 0.07), "poutre", 1.0)
	kit.quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.04)), w, h, "enseignep_" + key)


## Une affiche (avis de recherche) clouée sur un mur (xf : sur le mur, qui regarde -Z).
func _poster(xf: Transform3D, key: String, w: float = 0.48, h: float = 0.64) -> void:
	kit.quad(xf * Transform3D(Basis(Vector3.BACK, _rng.randf_range(-0.08, 0.08)), Vector3(0, 0, -0.02)), w, h, "affiche_" + key)


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6868
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6869
	_quai()
	_pontons()
	_place()
	_crane_fendu()
	_dent_requin()
	_boutiques()
	_residence()
	_cases()
	_carenage()
	_fort()
	_cimetiere()
	_camp()
	_cirque()
	_plage_os()
	_sentiers()
	kit.commit()
	_navires()
	_marais()
	_graph()
	_bric_a_brac()
	kit.commit()
	for l in find_children("*", "OmniLight3D", true, false):
		var ol: OmniLight3D = l
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 55.0
		ol.distance_fade_length = 15.0
		ol.shadow_enabled = false
	print("ILE_MANGA_V68: Port-Coutelas bâti, %d lieux, %d points, %d lumières, en %d ms" % [spots.size(), points.size(), kit.lamp_count, Time.get_ticks_msec() - t0])


# =================================================================== le quai

func _quai() -> void:
	var y: float = TY(0.0, R.QUAY_Z)
	# le mur du quai et les deux jetées qui ferment la darse
	kit.quay_wall(W(R.QUAY_X0 - 0.7, R.QUAY_Z + 0.0, 0), W(R.QUAY_X1 + 0.7, R.QUAY_Z + 0.0, 0), y, -9.8)
	kit.quay_wall(W(R.QUAY_X0 - 0.7, R.QUAY_Z, 0), W(R.QUAY_X0 - 0.7, R.BAY_RECT.end.y + 1.0, 0), y, -9.8, 2.6)
	kit.quay_wall(W(R.QUAY_X1 + 0.7, R.QUAY_Z, 0), W(R.QUAY_X1 + 0.7, R.BAY_RECT.end.y + 1.0, 0), y, -9.8, 2.6)
	for jx in [R.QUAY_X0 - 0.7, R.QUAY_X1 + 0.7]:
		var a: Vector3 = W(jx, R.QUAY_Z, y)
		var b: Vector3 = W(jx, R.BAY_RECT.end.y + 1.0, y)
		kit.walk_boxes.append([Transform3D(Basis(), (a + b) * 0.5).affine_inverse(), Vector3(1.6, 3.0, (b.z - a.z) * 0.5 + 0.3)])
		kit.lantern(W(jx, R.BAY_RECT.end.y + 0.2, y), 0.0, pc)
	# le dallage du quai
	var z0: float = 82.8
	var z1: float = R.QUAY_Z - 0.6
	var xa: float = R.QUAY_X0 - 1.0
	var xb: float = R.QUAY_X1 + 1.0
	kit.quad4("dalles", W(xa, z0, TY(xa, z0) + 0.05), W(xb, z0, TY(xb, z0) + 0.05), W(xb, z1, TY(xb, z1) + 0.05), W(xa, z1, TY(xa, z1) + 0.05), Vector3.UP,
		Vector2(0, 0), Vector2((xb - xa) / 2.4, 0), Vector2((xb - xa) / 2.4, (z1 - z0) / 2.4), Vector2(0, (z1 - z0) / 2.4))
	# bittes d'amarrage, cordages lovés
	var x: float = R.QUAY_X0 + 2.0
	while x < R.QUAY_X1 - 1.0:
		if absf(x + 25.0) > 2.0 and absf(x - 22.0) > 2.0 and absf(x - 55.0) > 2.0:
			kit.bollard(W(x, R.QUAY_Z - 0.9, y))
		x += 7.0
	for c in [Vector2(-30.0, 90.5), Vector2(16.0, 90.6), Vector2(47.0, 90.5)]:
		kit.cyl(Transform3D(Basis(), W(c.x, c.y, y)), 0.45, 0.45, 0.16, "cordage", 14)
		kit.cyl(Transform3D(Basis(), W(c.x, c.y, y + 0.16)), 0.36, 0.36, 0.14, "cordage", 14)
	# deux grues
	kit.crane(XF(W(-38.0, 90.0, y), 0.0, 1.0))
	kit.crane(XF(W(36.0, 90.0, y), 0.0, 1.0), 7.2)
	# la marchandise : caisses, tonneaux (ils se cassent), sacs
	for p in [Vector2(-42.0, 84.0), Vector2(-41.0, 82.6), Vector2(-33.0, 84.4), Vector2(-12.0, 85.0), Vector2(-10.6, 84.0), Vector2(8.0, 84.6),
			Vector2(30.0, 84.0), Vector2(31.2, 85.2), Vector2(44.0, 84.4), Vector2(58.0, 84.0)]:
		kit.crate(W(p.x, p.y, y + 0.04), _rng.randf_range(0, TAU), _rng.randf_range(0.6, 0.85))
	for p2 in [Vector2(-44.0, 85.6), Vector2(-14.0, 86.2), Vector2(9.6, 86.0), Vector2(28.4, 85.4), Vector2(42.4, 85.8), Vector2(57.0, 85.6)]:
		kit.barrel(W(p2.x, p2.y, y + 0.04))
	# des piles fixes (on s'y assoit)
	for p3 in [Vector2(-18.0, 84.2), Vector2(14.0, 84.6), Vector2(50.0, 84.6)]:
		kit.crate(W(p3.x, p3.y, y + 0.04), 0.0, 0.8, true)
		kit.crate(W(p3.x + 0.85, p3.y, y + 0.04), 0.1, 0.8, true)
	_spot("quai_caisse_1", W(-18.0, 85.1, y + 0.85), W(-18.0, 92.0, y), "assis")
	_spot("quai_caisse_2", W(14.0, 85.5, y + 0.85), W(14.0, 92.0, y), "assis")
	_spot("quai_caisse_3", W(50.0, 85.5, y + 0.85), W(50.0, 92.0, y), "assis")
	objets["fromage_affine_1"] = W(-17.15, 84.2, y + 0.86)      # V76 : sur la pile de caisses du quai
	# les canons au bout des jetées, tournés vers le large
	kit.cannon(XF(W(R.QUAY_X0 - 0.7, R.BAY_RECT.end.y - 1.6, y), 0.0, 1.0))
	kit.cannon(XF(W(R.QUAY_X1 + 0.7, R.BAY_RECT.end.y - 1.6, y), 0.0, 1.0))
	# lanternes du quai
	for lx in [-40.0, -10.0, 10.0, 40.0]:
		kit.lantern(W(lx, 83.4, y), PI, pc)
	# filets qui sèchent
	for fx in [-6.0, 0.0]:
		var fxf: Transform3D = XF(W(fx, 82.4, y), 0.0, 1.0)
		for s in [-1.0, 1.0]:
			kit.box(fxf * Transform3D(Basis(), Vector3(s * 2.0, 1.0, 0)), Vector3(0.1, 2.0, 0.1), "poutre", 1.0)
		kit.box(fxf * Transform3D(Basis(), Vector3(0, 1.95, 0)), Vector3(4.2, 0.08, 0.08), "poutre", 1.0)
		kit.quad(fxf * Transform3D(Basis(), Vector3(0, 1.2, 0)), 3.9, 1.5, "filet", Vector2(0, 0), Vector2(3, 1.2), true)
	_spot("quai_filets", W(-3.0, 83.6, y + 0.05), W(-3.0, 82.4, y), "bricoler")
	for k in range(6):
		var qx: float = [-44.0, -30.0, -8.0, 4.0, 34.0, 46.0][k]
		_spot("quai_%d" % (k + 1), W(qx, 89.8, y + 0.05), W(qx, 96.0, y), "bras_croises" if k % 2 == 0 else "debout")
	flora_avoid.append([Vector2(R.W(7.0, 86.0).x, R.W(7.0, 86.0).z), 60.0])


func _pontons() -> void:
	var y: float = TY(0.0, R.QUAY_Z)
	var py: float = _pier_y()
	for pr in [R.PIER_A, R.PIER_B]:
		var a: Vector2 = pr[0]
		var b: Vector2 = pr[1]
		kit.pier68(W(a.x, a.y - 0.6, 0), W(b.x, b.y, 0), 2.8, py)
		kit.lantern(W(b.x + 1.2, b.y - 0.6, py), 0.0, pc)
	# la rampe qui descend du quai au ponton de la barque
	var top: Vector3 = W(R.DOCK_A.x, R.QUAY_Z - 0.6, y + 0.02)
	var low: Vector3 = W(R.DOCK_A.x, R.DOCK_A.y + 0.4, 1.02)
	kit.gangplank(low, top, 1.5)
	# pêcheurs au bout des pontons
	var pa: Vector2 = R.PIER_A[1]
	var pb: Vector2 = R.PIER_B[1]
	_spot("ponton_peche_1", W(pa.x - 1.0, pa.y - 1.0, py + 0.08), W(pa.x - 6.0, pa.y + 2.0, 0.0), "pecher")
	_spot("ponton_peche_2", W(pb.x - 1.0, pb.y - 1.0, py + 0.08), W(pb.x - 6.0, pb.y + 2.0, 0.0), "pecher")
	objets["fromage_affine_2"] = W(R.PIER_B[0].lerp(pb, 0.8).x, R.PIER_B[0].lerp(pb, 0.8).y, py + 0.08)   # V76


# =================================================================== les navires

func _navires() -> void:
	# Le Requin Borgne : le galion, amarré à l'est du ponton ouest (proue vers le large)
	var req: Node3D = Navire.new()
	req.name = "Requin_Borgne_v68"
	req.setup68("requin", 1.0)
	add_child(req)
	req.place(W(R.PIER_A[0].x + 1.4 + 4.0 + 5.9, 121.0, -2.8), -PI * 0.5)
	req.build(pc)
	ships["requin"] = req
	# La Veuve Écarlate : le brick, à l'est du ponton est
	var veu: Node3D = Navire.new()
	veu.name = "Veuve_Ecarlate_v68"
	veu.setup68("veuve", 0.75)
	add_child(veu)
	veu.place(W(R.PIER_B[0].x + 1.4 + 3.0 + 5.9 * 0.75, 116.0, -2.8 * 0.75), -PI * 0.5)
	veu.build(pc)
	ships["veuve"] = veu
	# La Morue Enragée : le sloop, à l'ancre au milieu de la baie
	var mor: Node3D = Navire.new()
	mor.name = "Morue_Enragee_v68"
	mor.setup68("morue", 0.56)
	add_child(mor)
	mor.place(W(4.0, 160.0, -2.8 * 0.56), 0.25)
	mor.build(pc)
	ships["morue"] = mor
	# Le Sans-Pitié : un vieux sloop couché sur la grève de carénage, sans ses mâts
	var sp: Node3D = Navire.new()
	sp.name = "Sans_Pitie_v68"
	sp.setup68("sanspitie", 0.6, false)
	add_child(sp)
	var bas := Basis(Vector3.UP, -PI * 0.5 + 0.12) * Basis(Vector3.RIGHT, 0.5)
	sp.place_xf(Transform3D(bas, W(-62.5, 122.0, -1.7)))
	sp.build(pc)
	ships["sanspitie"] = sp
	# les passerelles, par-dessus le plat-bord (une rampe dehors, une rampe dedans)
	kit.rng.seed = 6870
	_passerelle(req, -2.0, 1.0, W(R.PIER_A[0].x + 1.3, 0.0, _pier_y() + 0.07), "requin")
	_passerelle(veu, -2.0, 1.0, W(R.PIER_B[0].x + 1.3, 0.0, _pier_y() + 0.07), "veuve")
	# V76 : Biscotte, le rat de cale du Requin Borgne, sort d'entre le ponton et la coque (quête pet_biscotte)
	objets["biscotte_attente"] = W(R.PIER_A[0].x + 0.9, 117.0, _pier_y() + 0.07)
	# l'échafaudage autour du Sans-Pitié
	for k in range(5):
		var z: float = 108.0 + k * 3.6
		var base: Vector3 = W(-57.0, z, 0.0)
		base.y = ile.height(base.x, base.z) - 0.2
		kit.cyl(Transform3D(Basis(), base), 0.1, 0.1, 4.6, "poutre", 6)
		kit.cyl(Transform3D(Basis(), base + Vector3(-1.6, 0, 0)), 0.1, 0.1, 4.6, "poutre", 6)
		kit.box(Transform3D(Basis(), base + Vector3(-0.8, 2.4, 0)), Vector3(2.0, 0.08, 0.4), "planchesp_sombre", 1.0)
		if k < 4:
			kit.beam(base + Vector3(0, 0.3, 0), base + Vector3(0, 4.2, 3.6), 0.08, "poutre")
	kit.commit()


## La passerelle d'un ponton au pont d'un navire : une rampe du ponton au plat-bord (x local,
## côté « side »), puis une rampe du plat-bord au pont. Ajoute les points de passage.
func _passerelle(ship: Node3D, x: float, side: float, low: Vector3, id: String) -> void:
	var rail: Vector3 = ship.rail_at(x, side)
	low.z = rail.z
	var deck: Vector3 = ship.deck_at(x, side * (ship.hb_in(x, ship.D) - 2.4))
	var out_dir: Vector3 = (rail - deck)
	out_dir.y = 0.0
	out_dir = out_dir.normalized()
	var top_out: Vector3 = rail + Vector3.UP * 0.12 + out_dir * 0.25
	var top_in: Vector3 = rail + Vector3.UP * 0.12 - out_dir * 0.25
	kit.gangplank(low, top_out, 1.3)
	kit.gangplank(deck + Vector3.UP * 0.02, top_in, 1.3)
	kit.box(Transform3D(Basis(), (top_out + top_in) * 0.5 + Vector3.DOWN * 0.06), Vector3(1.3, 0.12, 1.3), "planchesp_sombre", 1.0)
	kit.col_box(Transform3D(Basis(), (top_out + top_in) * 0.5 + Vector3.DOWN * 0.06), Vector3(1.3, 0.12, 1.3))
	kit.walk_boxes.append([Transform3D(Basis(), (top_out + top_in) * 0.5).affine_inverse(), Vector3(1.4, 3.0, 1.4)])
	_pt(id + "_bas", low + Vector3.UP * 0.05)
	_pt(id + "_plat", (top_out + top_in) * 0.5 + Vector3.UP * 0.05)
	_pt(id + "_pont", deck + Vector3.UP * 0.08)
	_chain([id + "_bas", id + "_plat", id + "_pont"])


# =================================================================== la place de la potence

func _place() -> void:
	# la potence (vide ; la corde se balance)
	var gp: Vector3 = W(2.0, 57.0, TY(2.0, 57.0))
	var top: Vector3 = kit.gallows(XF(gp, 0.0, 1.0))
	gallows_rope = Node3D.new()
	gallows_rope.name = "Corde_potence"
	add_child(gallows_rope)
	gallows_rope.global_position = top
	var rm := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.018
	cm.bottom_radius = 0.018
	cm.height = 1.5
	rm.mesh = cm
	rm.material_override = kit.mat("cordage")
	rm.position = Vector3(0, -0.75, 0)
	gallows_rope.add_child(rm)
	var loop := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.14
	tm.outer_radius = 0.17
	loop.mesh = tm
	loop.material_override = kit.mat("cordage")
	loop.position = Vector3(0, -1.6, 0)
	loop.rotation.x = PI * 0.5
	gallows_rope.add_child(loop)
	_spot("potence", W(2.0, 60.8, TY(2.0, 60.8) + 0.05), gp, "debout")
	# le puits
	well_pos = W(13.0, 66.0, TY(13.0, 66.0))
	kit.ring(Transform3D(Basis(), well_pos), 0.85, 1.2, 0.85, "pierrefort", 20)
	kit.disc(Transform3D(Basis(), well_pos + Vector3.UP * 0.2), 0.86, "goudron", 16)
	kit.col_cyl(well_pos, 1.2, 0.85)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(Basis(), well_pos + Vector3(s * 1.0, 1.4, 0)), Vector3(0.14, 1.9, 0.14), "poutre", 1.0)
	kit.box(Transform3D(Basis(), well_pos + Vector3(0, 2.3, 0)), Vector3(2.3, 0.14, 0.14), "poutre", 1.0)
	kit.roof_gable(Transform3D(Basis(), well_pos + Vector3(0, 2.4, 0)), 2.4, 1.6, 34.0, 0.25, "palmes", "poutre")
	kit.cyl(Transform3D(Basis(), well_pos + Vector3(0, 1.0, 0)), 0.18, 0.15, 0.32, "bois", 8)
	_spot("puits_1", well_pos + Vector3(1.9, 0.05, 0.3), well_pos, "debout")
	_spot("puits_2", well_pos + Vector3(-0.6, 0.05, 1.8), well_pos, "debout")
	objets["fromage_affine_3"] = well_pos + Vector3(-1.5, 0.05, -1.4)   # V76 : au pied du puits
	# l'étal des perroquets de Joe
	var jxf: Transform3D = XF(W(-8.0, 72.0, TY(-8.0, 72.0)), 0.0, -1.0)
	for sx in [-1.0, 1.0]:
		for fz in [0.0, 1.4]:
			kit.box(jxf * Transform3D(Basis(), Vector3(sx * 1.4, 1.2, fz)), Vector3(0.1, 2.4, 0.1), "poutre", 1.0)
	kit.box(jxf * Transform3D(Basis(), Vector3(0, 0.5, 0.3)), Vector3(2.8, 1.0, 0.6), "planchesp_vert", 1.2)
	kit.col_box(jxf * Transform3D(Basis(), Vector3(0, 0.5, 0.3)), Vector3(2.8, 1.0, 0.6))
	kit.box(jxf * Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3(0, 2.45, 0.7)), Vector3(3.3, 0.05, 2.0), "toile_rouge", 1.0)
	for c in range(3):
		kit.cage(jxf * Vector3(-0.9 + c * 0.9, 1.0, 0.3), 0.22, 0.45)
	for c2 in range(2):
		kit.cage(jxf * Vector3(-0.7 + c2 * 1.4, 1.65, 1.2), 0.2, 0.4)
		kit.cyl(Transform3D(Basis(), jxf * Vector3(-0.7 + c2 * 1.4, 2.05, 1.2)), 0.01, 0.01, 0.4, "fer", 4, false)
	_sign(jxf * Transform3D(Basis(), Vector3(0, 2.2, -0.05)), 1.8, 0.45, "perroquets")
	_spot("etal_joe", jxf * Vector3(0, 0.05, 1.1), jxf * Vector3(0, 0, -1.0), "comptoir")
	objets["cages_joe"] = jxf * Vector3(0, 1.0, 0.3)
	# la tente du tatoueur (Coralie)
	var txf: Transform3D = XF(W(16.0, 72.0, TY(16.0, 72.0)), 0.0, -1.0)
	kit.tent(txf * Transform3D(Basis(), Vector3(0, 0, 1.6)), 3.0, 3.2, 2.4, "toile_bleu")
	kit.box(txf * Transform3D(Basis(), Vector3(0.6, 0.25, 1.6)), Vector3(0.5, 0.5, 0.5), "planchesp_sombre", 1.0)
	_sign(txf * Transform3D(Basis(), Vector3(-1.9, 1.4, -0.2)), 1.6, 0.4, "tatoueur")
	kit.box(txf * Transform3D(Basis(), Vector3(-1.9, 0.6, -0.12)), Vector3(0.1, 1.2, 0.1), "poutre", 1.0)
	_spot("tente_coralie", txf * Vector3(-0.5, 0.05, 1.6), txf * Vector3(0.6, 0, 1.6), "assis")
	_spot("tente_client", txf * Vector3(0.6, 0.55, 1.6), txf * Vector3(-0.5, 0.5, 1.6), "assis")
	# des lanternes autour de la place
	for a in range(4):
		var ang: float = TAU * a / 4.0 + 0.6
		kit.lantern(G(2.0 + cos(ang) * 11.0, 64.0 + sin(ang) * 11.0), ang + PI * 0.5, pc)
	for k in range(3):
		var sa: float = TAU * k / 3.0
		var sp: Vector3 = W(2.0 + cos(sa) * 6.0, 64.5 + sin(sa) * 5.0, 0.0)
		sp.y = TY(2.0 + cos(sa) * 6.0, 64.5 + sin(sa) * 5.0) + 0.05
		_spot("place_%d" % (k + 1), sp, gp, "debout")
	# un banc de rondins face à la baie
	kit.box(Transform3D(Basis(), W(-2.0, 79.5, TY(-2.0, 79.5) + 0.25)), Vector3(3.0, 0.42, 0.6), "rondins", 1.0)
	kit.col_box(Transform3D(Basis(), W(-2.0, 79.5, TY(-2.0, 79.5) + 0.25)), Vector3(3.0, 0.42, 0.6))
	_spot("banc_baie_1", W(-3.0, 79.5, TY(-3.0, 79.5) + 0.5), W(-3.0, 92.0, 0.0), "assis")
	_spot("banc_baie_2", W(-1.0, 79.5, TY(-1.0, 79.5) + 0.5), W(-1.0, 92.0, 0.0), "assis")
	flora_avoid.append([Vector2(R.W(2.0, 64.0).x, R.W(2.0, 64.0).z), 16.0])


# =================================================================== Le Crâne Fendu

func _crane_fendu() -> void:
	var fy: float = _floor(-34.0, 52.0, -22.0, 68.0) + 0.3
	var xf: Transform3D = XF(W(-22.0, 60.0, fy), 1.0, 0.0)
	_socle(xf, 16.0, 12.0, 2.0)
	var hd: Dictionary = kit.wood_hall(xf, 16.0, 12.0, {"h": 4.2, "couleur": "rouge", "roof": "planches", "lights": 3, "energy": 1.6, "door_w": 2.2})
	doors["crane_fendu"] = hd["door"]
	_sign(xf * Transform3D(Basis(), Vector3(0, 3.35, -0.2)), 3.6, 0.9, "crane_fendu")
	# le perron
	kit.box(xf * Transform3D(Basis(), Vector3(0, -0.15, -1.0)), Vector3(4.0, 0.3, 2.0), "planchesp_sombre", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -0.15, -1.0)), Vector3(4.0, 0.3, 2.0))
	kit.lantern(xf * Vector3(2.4, 2.7, -0.05), PI, pc, true)
	kit.lantern(xf * Vector3(-2.4, 2.7, -0.05), PI, pc, true)
	_poster(xf * Transform3D(Basis(), Vector3(-4.6, 1.7, -0.01)), "avis_lestrange")
	_poster(xf * Transform3D(Basis(), Vector3(-5.4, 1.6, -0.01)), "avis_malaterre")
	# le comptoir de Mama Grog, au fond
	var ctr: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, 9.0))
	kit.bar_counter(ctr, 6.0)
	for k2 in range(3):
		kit.barrel(xf * Vector3(-7.0, 0.0, 6.0 + k2 * 0.9), true)
	_spot("grog_comptoir", ctr * Vector3(0, 0.05, -0.95), ctr * Vector3(0, 0, 1.0), "comptoir")
	for k3 in range(4):
		_spot("grog_bar_%d" % (k3 + 1), ctr * Vector3(-2.2 + k3 * 1.45, 0.05, 0.9), ctr * Vector3(-2.2 + k3 * 1.45, 0, 0), "boire")
	# la cheminée (côté gauche)
	var fp: Transform3D = xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-7.55, 0.0, 4.0))
	kit.box(fp * Transform3D(Basis(), Vector3(0, 1.0, 0.1)), Vector3(2.4, 2.0, 0.5), "pierrefort", 1.0)
	kit.box(fp * Transform3D(Basis(), Vector3(0, 0.6, -0.01)), Vector3(1.4, 1.2, 0.52), "goudron", 1.0, 32)
	kit.box(fp * Transform3D(Basis(), Vector3(0, 2.05, -0.05)), Vector3(2.7, 0.15, 0.6), "poutre", 1.0)
	kit.box(fp * Transform3D(Basis(), Vector3(0, 0.12, -0.25)), Vector3(0.9, 0.12, 0.3), "braise", 1.0)
	fire_spots.append([fp * Vector3(0, 0.15, -0.25), 0.7])
	smoke_spots.append(xf * Vector3(-7.4, 4.2 + 4.6, 4.0))
	kit.box(xf * Transform3D(Basis(), Vector3(-7.4, 4.2 + 3.0, 4.0)), Vector3(0.9, 3.2, 0.9), "pierrefort_sombre", 1.5)
	_spot("grog_cheminee", fp * Vector3(0.4, 0.05, -1.6), fp * Vector3(0, 0, 0), "debout")
	# la scène du violoneux (coin avant droit)
	var st: Transform3D = xf * Transform3D(Basis(), Vector3(5.6, 0.0, 2.2))
	kit.box(st * Transform3D(Basis(), Vector3(0, 0.15, 0)), Vector3(3.0, 0.3, 2.6), "planchesp_sombre", 1.0)
	kit.col_box(st * Transform3D(Basis(), Vector3(0, 0.15, 0)), Vector3(3.0, 0.3, 2.6))
	kit.barrel(st * Vector3(0.9, 0.3, 0.6), true)
	_spot("grog_scene", st * Vector3(-0.2, 0.32, 0.2), xf * Vector3(0, 0, 6.0), "violon")
	# les tables (et leurs tabourets)
	var tables := [Vector3(-3.6, 0, 3.4), Vector3(3.2, 0, 6.2), Vector3(-3.8, 0, 6.6), Vector3(0.0, 0, 4.8)]
	for i in range(tables.size()):
		var tp: Vector3 = xf * (tables[i] as Vector3)
		kit.cafe_table(tp, 0.0, 2, "")
		for ch in range(2):
			var ang: float = TAU * ch / 2.0 + 0.3
			_spot("grog_table_%d" % (i * 2 + ch + 1), tp + Vector3(cos(ang) * 0.62, 0.05, sin(ang) * 0.62), tp, "assis")
	# deux tables de dés (des tonneaux)
	var dts := [Vector3(5.0, 0, 6.2), Vector3(-6.0, 0, 9.0)]
	for d in range(dts.size()):
		var dp: Vector3 = xf * (dts[d] as Vector3)
		var top: Vector3 = kit.dice_table(dp, 0.4 * d, 0.55)
		var seats: Array = []
		for s in range(3):
			var a2: float = TAU * s / 3.0 + 0.5
			var nm: String = "grog_des_%d" % (d * 3 + s + 1)
			_spot(nm, dp + Vector3(cos(a2) * 0.95, 0.05, sin(a2) * 0.95), dp, "jouer_des")
			seats.append(nm)
		dice_tables["grog_%d" % (d + 1)] = {"pos": top, "sieges": seats}
	# des affiches, une carte au mur, un hamac dans le coin
	_poster(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(4.6, 2.2, 11.68)), "avis_anne_rose")
	kit.quad(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.68, 2.3, 9.0)), 1.6, 1.05, "affiche_carte_tresor")
	interiors.append(["crane_fendu", xf * Vector3(0, 0, 6.0), Vector2(6.0, 8.0), fy])
	_pt("cf_porte", xf * Vector3(0, 0.05, -2.4))
	_pt("cf_in", xf * Vector3(0, 0.05, 1.4))
	_pt("cf_mid", xf * Vector3(0, 0.05, 5.6))
	_pt("cf_bar", xf * Vector3(0, 0.05, 7.6))
	_pt("cf_gauche", xf * Vector3(-4.8, 0.05, 5.6))
	_pt("cf_droite", xf * Vector3(4.2, 0.05, 4.2))
	_pt("cf_fond", xf * Vector3(-5.0, 0.05, 9.6))
	_pt("porte_crane_fendu", xf * Vector3(5.6, 0.05, 10.4))
	_chain(["cf_porte", "cf_in", "cf_mid", "cf_bar"])
	_link("cf_mid", "cf_gauche")
	_link("cf_mid", "cf_droite")
	_link("cf_gauche", "cf_fond")
	_link("cf_bar", "porte_crane_fendu")
	_link("cf_in", "cf_droite")
	flora_avoid.append([Vector2((xf * Vector3(0, 0, 6)).x, (xf * Vector3(0, 0, 6)).z), 13.0])


# =================================================================== La Dent du Requin

func _dent_requin() -> void:
	var fy: float = _floor(30.0, 54.0, 41.0, 66.0) + 0.3
	var xf: Transform3D = XF(W(30.0, 60.0, fy), -1.0, 0.0)
	_socle(xf, 12.0, 11.0, 2.0)
	var hd: Dictionary = kit.wood_hall(xf, 12.0, 11.0, {"h": 4.0, "couleur": "bleu", "roof": "palmes", "lights": 2, "energy": 1.3, "light_color": Color(0.85, 0.95, 0.75)})
	doors["dent_requin"] = hd["door"]
	_sign(xf * Transform3D(Basis(), Vector3(0, 3.2, -0.2)), 3.4, 0.85, "dent_requin")
	kit.box(xf * Transform3D(Basis(), Vector3(0, -0.15, -1.0)), Vector3(3.6, 0.3, 2.0), "planchesp_sombre", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, -0.15, -1.0)), Vector3(3.6, 0.3, 2.0))
	kit.lantern(xf * Vector3(2.2, 2.6, -0.05), PI, pc, true)
	# la grande table du croupier
	var gt: Transform3D = xf * Transform3D(Basis(), Vector3(0.0, 0.0, 6.4))
	kit.box(gt * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(3.4, 0.8, 1.6), "planchesp_sombre", 1.0)
	kit.box(gt * Transform3D(Basis(), Vector3(0, 0.83, 0)), Vector3(3.6, 0.06, 1.8), "poutre", 1.0)
	kit.box(gt * Transform3D(Basis(), Vector3(0, 0.865, 0)), Vector3(3.2, 0.01, 1.4), "tapis", 1.0)
	kit.col_box(gt * Transform3D(Basis(), Vector3(0, 0.42, 0)), Vector3(3.6, 0.84, 1.8))
	for k in range(5):
		kit.box(Transform3D(gt.basis * Basis(Vector3.UP, k * 0.7), gt * Vector3(-0.6 + k * 0.28, 0.905, -0.1 + (k % 2) * 0.2)), Vector3(0.07, 0.07, 0.07), "de", 0.07)
	kit.coins(gt * Vector3(0.9, 0.87, 0.2), 9, 0.25)
	kit.coins(gt * Vector3(-1.1, 0.87, -0.3), 5, 0.18)
	kit.cyl(Transform3D(Basis(), gt * Vector3(0.0, 0.87, 0.55)), 0.07, 0.09, 0.16, "planchesp_sombre", 10)
	_spot("dent_croupier", gt * Vector3(0, 0.05, 1.45), gt * Vector3(0, 0, 0), "croupier")
	var seats: Array = []
	for s in range(4):
		var sx: float = -1.2 + s * 0.8
		var nm: String = "dent_grande_%d" % (s + 1)
		_spot(nm, gt * Vector3(sx, 0.05, -1.4), gt * Vector3(sx, 0, 0), "jouer_des")
		seats.append(nm)
	dice_tables["grande_table"] = {"pos": gt * Vector3(0, 0.88, 0), "sieges": seats}
	# un coffre d'or derrière le croupier
	var ch: Transform3D = xf * Transform3D(Basis(), Vector3(3.6, 0.0, 9.6))
	kit.box(ch * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.0, 0.6, 0.6), "poutre", 1.0)
	kit.box(ch * Transform3D(Basis(), Vector3(0, 0.62, 0)), Vector3(1.04, 0.06, 0.64), "fer", 1.0)
	kit.coins(ch * Vector3(0, 0.65, 0), 7, 0.2)
	kit.col_box(ch * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.0, 0.6, 0.6))
	# deux tables de dés (tonneaux) sur les côtés
	var dts := [Vector3(-3.6, 0, 3.0), Vector3(3.6, 0, 3.0)]
	for d in range(dts.size()):
		var dp: Vector3 = xf * (dts[d] as Vector3)
		var top: Vector3 = kit.dice_table(dp, 0.7 * d, 0.55)
		var ss: Array = []
		for s2 in range(3):
			var a2: float = TAU * s2 / 3.0 + 0.2
			var nm2: String = "dent_des_%d" % (d * 3 + s2 + 1)
			_spot(nm2, dp + Vector3(cos(a2) * 0.95, 0.05, sin(a2) * 0.95), dp, "jouer_des")
			ss.append(nm2)
		dice_tables["dent_%d" % (d + 1)] = {"pos": top, "sieges": ss}
	# un petit comptoir (le rhum de la maison)
	var ctr: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-4.8, 0.0, 8.4))
	kit.box(ctr * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(2.4, 1.1, 0.6), "planchesp_sombre", 1.0)
	kit.box(ctr * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(2.6, 0.07, 0.8), "poutre", 1.0)
	kit.col_box(ctr * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(2.4, 1.1, 0.6))
	for b in range(4):
		kit.cyl(ctr * Transform3D(Basis(), Vector3(-0.9 + b * 0.6, 1.17, 0.0)), 0.05, 0.035, 0.3, ["bouteille", "bouteille_brune"][b % 2], 8)
	_spot("dent_comptoir", ctr * Vector3(0.0, 0.05, -0.9), ctr * Vector3(0, 0, 0), "boire")
	_spot("dent_coin_1", xf * Vector3(-4.6, 0.05, 1.4), xf * Vector3(0, 0, 5.0), "bras_croises")
	_spot("dent_coin_2", xf * Vector3(4.8, 0.05, 6.4), xf * Vector3(0, 0, 6.4), "bras_croises")
	_poster(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-2.0, 2.0, 10.68)), "avis_malaterre")
	_poster(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(-1.2, 2.1, 10.68)), "avis_anne_rose")
	interiors.append(["dent_requin", xf * Vector3(0, 0, 5.5), Vector2(5.2, 5.6), fy])
	_pt("dr_porte", xf * Vector3(0, 0.05, -2.4))
	_pt("dr_in", xf * Vector3(0, 0.05, 1.4))
	_pt("dr_mid", xf * Vector3(0, 0.05, 4.4))
	_pt("dr_gauche", xf * Vector3(-3.6, 0.05, 5.6))
	_pt("dr_droite", xf * Vector3(3.6, 0.05, 5.6))
	_pt("dr_fond", xf * Vector3(2.2, 0.05, 8.6))
	_pt("porte_dent_requin", xf * Vector3(-3.0, 0.05, 10.0))
	_chain(["dr_porte", "dr_in", "dr_mid"])
	_link("dr_mid", "dr_gauche")
	_link("dr_mid", "dr_droite")
	_link("dr_droite", "dr_fond")
	_link("dr_gauche", "porte_dent_requin")
	flora_avoid.append([Vector2((xf * Vector3(0, 0, 5.5)).x, (xf * Vector3(0, 0, 5.5)).z), 10.0])


# =================================================================== les boutiques du port

func _boutiques() -> void:
	# --- Cinq-Doigts, le receleur : un comptoir sous l'auvent
	var ry: float = _floor(-55.0, 72.0, -49.0, 77.0) + 0.1
	var rxf: Transform3D = XF(W(-52.0, 72.0, ry), 0.0, 1.0)
	_socle(rxf, 6.0, 5.0, 1.4)
	doors["receleur"] = kit.shack(rxf, 6.0, 5.0, {"couleur": "sombre", "toit": "planches", "porch": 1.6, "door_x": 1.6})
	var cxf: Transform3D = rxf * Transform3D(Basis(), Vector3(-1.0, 0.0, -1.0))
	kit.box(cxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(2.4, 1.0, 0.5), "planchesp_sombre", 1.0)
	kit.col_box(cxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(2.4, 1.0, 0.5))
	kit.coins(cxf * Vector3(0.5, 1.02, 0.0), 6, 0.12)
	kit.box(Transform3D(cxf.basis, cxf * Vector3(-0.6, 1.1, 0.0)), Vector3(0.3, 0.16, 0.22), "orp", 1.0)
	_sign(rxf * Transform3D(Basis(), Vector3(0.0, 2.35, -0.02)), 2.6, 0.65, "receleur")
	_spot("receleur_comptoir", cxf * Vector3(0, 0.05, 0.75), cxf * Vector3(0, 0, -1.0), "comptoir")
	_pt("porte_receleur", rxf * Vector3(1.6, 0.05, 1.2))
	_pt("devant_receleur", G(-50.4, 75.4, 0.05))
	_link("devant_receleur", "porte_receleur")
	# --- Doc Saignée, le chirurgien-barbier : sa case et son fauteuil dehors
	var dy: float = _floor(-61.0, 51.0, -55.0, 57.0) + 0.1
	var dxf: Transform3D = XF(W(-55.0, 54.0, dy), 1.0, 0.0)
	_socle(dxf, 6.0, 6.0, 1.4)
	doors["doc"] = kit.shack(dxf, 6.0, 6.0, {"couleur": "clair", "toit": "palmes", "porch": 1.8})
	_sign(dxf * Transform3D(Basis(), Vector3(0.0, 2.4, -0.02)), 2.6, 0.65, "chirurgien")
	var chair: Transform3D = dxf * Transform3D(Basis(), Vector3(1.8, 0.0, -1.0))
	kit.box(chair * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.6, 0.5, 0.6), "poutre", 1.0)
	kit.box(chair * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 0.75, 0.3)), Vector3(0.6, 0.8, 0.08), "poutre", 1.0)
	kit.col_box(chair * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(0.6, 0.6, 0.6))
	_spot("doc_fauteuil", chair * Vector3(0, 0.5, -0.05), chair * Vector3(0, 0.5, -2.0), "assis")
	_spot("doc_porte", dxf * Vector3(0.6, 0.05, -1.0), dxf * Vector3(1.8, 0, -1.0), "debout")
	_pt("porte_doc", dxf * Vector3(0, 0.05, 1.2))
	_pt("devant_doc", G(-52.0, 54.0, 0.05))
	_link("devant_doc", "porte_doc")
	# --- La forge de Brutus : un toit sur des poteaux, le foyer, l'enclume, le râtelier
	var fy: float = _floor(48.0, 47.0, 56.0, 55.0)
	var fxf: Transform3D = XF(W(48.0, 51.0, fy), -1.0, 0.0)
	_socle(fxf, 8.0, 6.0, 1.2)
	kit.box(fxf * Transform3D(Basis(), Vector3(0, -0.04, 3.0)), Vector3(8.0, 0.1, 6.0), "dalles", 2.0, 4)
	kit.col_box(fxf * Transform3D(Basis(), Vector3(0, -0.12, 3.0)), Vector3(8.0, 0.26, 6.0))
	for sx in [-1.0, 1.0]:
		for sz in [0.2, 5.8]:
			kit.box(fxf * Transform3D(Basis(), Vector3(sx * 3.8, 1.6, sz)), Vector3(0.22, 3.2, 0.22), "poutre", 1.0)
			kit.col_box(fxf * Transform3D(Basis(), Vector3(sx * 3.8, 1.6, sz)), Vector3(0.22, 3.2, 0.22))
	kit.roof_gable(fxf * Transform3D(Basis(), Vector3(0, 3.2, 3.0)), 8.0, 6.0, 26.0, 0.5, "planchesp_noir", "poutre")
	kit.box(fxf * Transform3D(Basis(), Vector3(0, 1.3, 5.9)), Vector3(7.6, 2.6, 0.2), "planchesp_sombre", 2.0)
	kit.col_box(fxf * Transform3D(Basis(), Vector3(0, 1.3, 5.9)), Vector3(7.6, 2.6, 0.2))
	var hearth: Transform3D = fxf * Transform3D(Basis(), Vector3(-2.2, 0.0, 4.8))
	kit.box(hearth * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.8, 0.9, 1.4), "pierrefort", 1.0)
	kit.box(hearth * Transform3D(Basis(), Vector3(0, 0.93, 0)), Vector3(1.2, 0.08, 0.9), "braise", 1.0)
	kit.col_box(hearth * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.8, 0.9, 1.4))
	kit.box(hearth * Transform3D(Basis(), Vector3(0, 2.4, 0.3)), Vector3(0.8, 2.4, 0.8), "pierrefort_sombre", 1.0)
	fire_spots.append([hearth * Vector3(0, 1.0, 0), 0.6])
	smoke_spots.append(hearth * Vector3(0, 4.4, 0.3))
	kit.anvil(fxf * Vector3(0.4, 0.0, 3.0), 0.3)
	# le râtelier : des sabres d'abordage
	var rack: Transform3D = fxf * Transform3D(Basis(), Vector3(2.6, 0.0, 5.6))
	kit.box(rack * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(1.8, 0.08, 0.1), "poutre", 1.0)
	kit.box(rack * Transform3D(Basis(), Vector3(0, 1.8, 0)), Vector3(1.8, 0.08, 0.1), "poutre", 1.0)
	for k in range(5):
		kit.box(Transform3D(rack.basis * Basis(Vector3.BACK, 0.08), rack * Vector3(-0.7 + k * 0.35, 1.25, -0.1)), Vector3(0.05, 1.1, 0.01), "chrome", 1.0)
		kit.box(rack * Transform3D(Basis(), Vector3(-0.7 + k * 0.35, 0.66, -0.1)), Vector3(0.12, 0.05, 0.04), "laiton", 1.0)
	_sign(fxf * Transform3D(Basis(), Vector3(0.0, 3.0, 0.1)), 2.6, 0.65, "forge")
	_spot("forge_enclume", fxf * Vector3(0.4, 0.05, 2.2), fxf * Vector3(0.4, 0, 3.0), "forger")
	_spot("forge_feu", hearth * Vector3(0.0, 0.05, -1.3), hearth * Vector3(0, 0, 0), "debout")
	_pt("forge_in", fxf * Vector3(0.0, 0.05, 1.4))
	# la case de Brutus derrière la forge
	var by: float = _floor(58.0, 39.5, 63.0, 44.5) + 0.3
	var bxf: Transform3D = XF(W(58.0, 42.0, by), -1.0, 0.0)
	_socle(bxf, 5.0, 5.0, 1.6)
	doors["brutus"] = kit.shack(bxf, 5.0, 5.0, {"couleur": "sombre", "porch": 1.2})
	_pt("porte_brutus", bxf * Vector3(0, 0.05, 1.0))
	_pt("devant_brutus", G(55.4, 42.0, 0.05))
	_link("devant_brutus", "porte_brutus")
	# --- La Tour Lunette (le cartographe) : une tour de pierre, une longue-vue au sommet
	var tc: Vector3 = W(66.0, 76.0, TY(66.0, 76.0))
	kit.tower(tc, 3.2, 10.0, {"wall": "pierrefort", "band": false, "crenel": true, "roof": "flat", "seg": 18})
	kit.telescope(Transform3D(Basis(Vector3.UP, 2.4), tc + Vector3.UP * 10.3), 0.4)
	var door_a: float = PI
	var dfx: Transform3D = kit.round_face(tc, 3.2, door_a, 0.0)
	kit.box(dfx * Transform3D(Basis(), Vector3(0, 1.1, -0.06)), Vector3(1.2, 2.2, 0.1), "planchesp_sombre", 1.0)
	kit.box(dfx * Transform3D(Basis(), Vector3(0, 2.3, -0.1)), Vector3(1.5, 0.2, 0.2), "poutre", 1.0)
	_sign(dfx * Transform3D(Basis(), Vector3(0.0, 2.9, -0.16)), 2.2, 0.55, "cartographe")
	_spot("lunette_porte", dfx * Vector3(0.6, 0.05, -1.2), tc + Vector3(-12.0, 0, 0), "debout")
	_pt("porte_lunette", dfx * Vector3(0, 0.05, -0.9))
	for k2 in range(2):
		kit.small_window(kit.round_face(tc, 3.2, door_a + 1.2 + k2 * 2.4, 5.2 + k2 * 1.6), 0.6, 0.9)
	flora_avoid.append([Vector2(tc.x, tc.z), 6.0])


# =================================================================== la résidence du Gouverneur

func _residence() -> void:
	var pad: Array = R.PADS["residence"]
	var y: float = float(pad[3]) + 0.25
	var xf: Transform3D = XF(W(float(pad[0]), float(pad[1]) + 3.4, y), 0.0, 1.0)
	_socle(xf, 11.0, 8.0, 2.0)
	doors["residence"] = kit.shack(xf, 11.0, 8.0, {"h": 5.6, "couleur": "rouge", "toit": "planches", "porch": 2.4})
	for s in [-1.0, 1.0]:
		_dummy_window2(xf * Transform3D(Basis(), Vector3(s * 3.4, 4.2, -0.01)))
	_sign(xf * Transform3D(Basis(), Vector3(0, 4.9, -0.05)), 3.6, 0.9, "residence")
	kit.flag_pole(xf * Vector3(-6.4, 0, -2.0), 9.0, "balafre", Vector2(2.0, 1.25))
	# deux fauteuils sur la véranda
	for s2 in [-1.0, 1.0]:
		var c: Transform3D = xf * Transform3D(Basis(), Vector3(s2 * 3.0, 0.0, -1.2))
		kit.box(c * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.7, 0.5, 0.7), "planchesp_rouge", 1.0)
		kit.box(c * Transform3D(Basis(), Vector3(0, 0.7, 0.32)), Vector3(0.7, 0.8, 0.08), "planchesp_rouge", 1.0)
	_spot("gouv_veranda", xf * Vector3(-3.0, 0.5, -1.3), xf * Vector3(-3.0, 0.5, -10.0), "assis")
	_spot("gouv_perron", xf * Vector3(1.5, 0.05, -1.6), xf * Vector3(1.5, 0, -10.0), "bras_croises")
	_pt("porte_residence", xf * Vector3(0, 0.05, 1.0))
	_pt("res_perron", xf * Vector3(0, 0.05, -1.6))
	_pt("res_bas", xf * Vector3(0, 0, -4.8) + Vector3.UP * 0.05)
	points["res_bas"] = G(R.L(points["res_bas"].x, points["res_bas"].z).x, R.L(points["res_bas"].x, points["res_bas"].z).y, 0.05)
	flora_avoid.append([Vector2((xf * Vector3(0, 0, 3)).x, (xf * Vector3(0, 0, 3)).z), 10.0])


func _dummy_window2(xf: Transform3D) -> void:
	kit._shutter_window(xf, 0.8, 1.0)


# =================================================================== les cases

## [x, z, direction de la façade, largeur, profondeur, couleur, toit, nom]
const CASES := [
	[-68.0, 46.0, Vector2(1, 0), 5.0, 4.5, "", "palmes", "case_morue"],
	[-68.0, 60.0, Vector2(1, 0), 5.0, 4.5, "vert", "palmes", "case_crochet"],
	[-68.0, 74.0, Vector2(1, 0), 4.6, 4.2, "sombre", "palmes", "case_silas"],
	[-42.0, 44.0, Vector2(0, 1), 5.0, 4.5, "jaune", "palmes", "case_joe"],
	[18.0, 44.0, Vector2(0, 1), 5.0, 4.5, "bleu", "palmes", "case_coralie"],
	[36.0, 44.0, Vector2(0, 1), 5.4, 4.5, "", "planches", "case_tom"],
	[70.0, 60.0, Vector2(-1, 0), 5.0, 4.5, "rouge", "palmes", "case_ecarlates"],
	[-12.0, 46.0, Vector2(0, 1), 5.0, 4.5, "", "palmes", "case_requins"],
]


func _cases() -> void:
	for c in CASES:
		var dir: Vector2 = c[2]
		var w: float = float(c[3])
		var d: float = float(c[4])
		var x: float = float(c[0])
		var z: float = float(c[1])
		var back: Vector2 = Vector2(x, z) - dir * d
		var side := Vector2(-dir.y, dir.x) * w * 0.5
		var y: float = _floor(minf(x, back.x) - absf(side.x), minf(z, back.y) - absf(side.y), maxf(x, back.x) + absf(side.x), maxf(z, back.y) + absf(side.y)) + 0.35
		var xf: Transform3D = XF(W(x, z, y), dir.x, dir.y)
		_socle(xf, w, d, 1.8)
		var door: Vector3 = kit.shack(xf, w, d, {"couleur": str(c[5]), "toit": str(c[6]), "porch": 1.4, "pilotis": 0.0})
		doors[str(c[7])] = door
		_pt("porte_" + str(c[7]), xf * Vector3(0, 0.05, 1.0))
		_pt("devant_" + str(c[7]), G(R.L((xf * Vector3(0, 0, -2.6)).x, (xf * Vector3(0, 0, -2.6)).z).x, R.L((xf * Vector3(0, 0, -2.6)).x, (xf * Vector3(0, 0, -2.6)).z).y, 0.05))
		_link("devant_" + str(c[7]), "porte_" + str(c[7]))
		if _rng.randf() < 0.4:
			smoke_spots.append(xf * Vector3(w * 0.3, 2.7 + 2.6, d * 0.6))
		flora_avoid.append([Vector2((xf * Vector3(0, 0, d * 0.5)).x, (xf * Vector3(0, 0, d * 0.5)).z), maxf(w, d) * 0.8])
	# un hamac entre deux poteaux près des cases de l'ouest
	var ha: Vector3 = G(-64.6, 50.0, 1.4)
	var hb: Vector3 = G(-64.6, 53.8, 1.4)
	for p in [ha, hb]:
		kit.cyl(Transform3D(Basis(), p + Vector3.DOWN * 1.5), 0.1, 0.09, 2.0, "poutre", 6)
	kit.hammock(ha, hb)


# =================================================================== la grève de carénage

func _carenage() -> void:
	# l'atelier de Gwen Calfat : un appentis, des planches, la marmite de goudron
	var wy: float = _floor(-74.0, 84.0, -66.0, 90.0) + 0.1
	var wxf: Transform3D = XF(W(-70.0, 90.0, wy), 0.0, 1.0)
	for sx in [-1.0, 1.0]:
		kit.box(wxf * Transform3D(Basis(), Vector3(sx * 3.4, 1.4, 0.2)), Vector3(0.2, 2.8, 0.2), "poutre", 1.0)
		kit.box(wxf * Transform3D(Basis(), Vector3(sx * 3.4, 1.8, 4.6)), Vector3(0.2, 3.6, 0.2), "poutre", 1.0)
		kit.col_box(wxf * Transform3D(Basis(), Vector3(sx * 3.4, 1.4, 0.2)), Vector3(0.2, 2.8, 0.2))
	kit.box(wxf * Transform3D(Basis(Vector3.RIGHT, 0.16), Vector3(0, 3.25, 2.4)), Vector3(7.4, 0.08, 5.4), "planchesp_noir", 1.6)
	kit.box(wxf * Transform3D(Basis(), Vector3(0, 1.6, 4.8)), Vector3(7.0, 3.2, 0.15), "planchesp", 2.0)
	kit.col_box(wxf * Transform3D(Basis(), Vector3(0, 1.6, 4.8)), Vector3(7.0, 3.2, 0.15))
	doors["case_gwen"] = wxf * Vector3(0, 0, -1.0)
	_pt("porte_case_gwen", wxf * Vector3(2.0, 0.05, 3.8))
	_pt("devant_case_gwen", wxf * Vector3(1.6, 0.05, -1.6))
	_link("devant_case_gwen", "porte_case_gwen")
	for k in range(6):
		kit.box(wxf * Transform3D(Basis(Vector3.BACK, 0.03 * k), Vector3(-1.6, 0.08 + k * 0.09, 3.2)), Vector3(4.0, 0.08, 0.3), "planchesp", 1.0)
	kit.box(wxf * Transform3D(Basis(), Vector3(1.6, 0.45, 2.0)), Vector3(1.8, 0.1, 0.5), "poutre", 1.0)
	var pot: Vector3 = wxf * Vector3(2.6, 0.0, 0.0)
	kit.cyl(Transform3D(Basis(), pot), 0.45, 0.5, 0.6, "fer", 12)
	kit.disc(Transform3D(Basis(), pot + Vector3.UP * 0.52), 0.42, "goudron", 12)
	fire_spots.append([pot + Vector3(0, 0.05, 0), 0.5])
	smoke_spots.append(pot + Vector3.UP * 0.7)
	_spot("atelier_gwen", wxf * Vector3(1.6, 0.05, 1.3), wxf * Vector3(1.6, 0.45, 2.0), "bricoler")
	_spot("carenage_coque", G(-58.6, 116.0, 0.05), G(-62.5, 118.0, 1.0), "bricoler")
	_spot("carenage_echafaud", G(-57.8, 111.6, 2.45), G(-62.5, 112.0, 2.0), "bricoler")
	# un feu de camp sur la grève, des rondins pour s'asseoir
	var fc: Vector3 = G(-72.0, 104.0, 0.0)
	kit.ring(Transform3D(Basis(), fc), 0.55, 0.8, 0.22, "pierrefort_sombre", 12)
	fire_spots.append([fc + Vector3.UP * 0.1, 0.9])
	for k2 in range(3):
		var a: float = TAU * k2 / 3.0 + 0.4
		var lp: Vector3 = fc + Vector3(cos(a), 0, sin(a)) * 2.3
		lp.y = ile.height(lp.x, lp.z) + 0.22
		var lb: Basis = Basis(Vector3.UP, -a + PI * 0.5) * Basis(Vector3.BACK, PI * 0.5)
		kit.cyl(Transform3D(lb, lp - lb * Vector3.UP * 0.8), 0.22, 0.22, 1.6, "rondins", 8)
		_spot("feu_greve_%d" % (k2 + 1), lp + Vector3.UP * 0.25, fc, "assis")
	flora_avoid.append([Vector2(fc.x, fc.z), 6.0])
	flora_avoid.append([Vector2(R.W(-64.0, 118.0).x, R.W(-64.0, 118.0).z), 18.0])


# =================================================================== le Fort Maudit

func _fort() -> void:
	var pad: Array = R.PADS["fort"]
	var y: float = float(pad[3])
	var c: Vector3 = W(float(pad[0]), float(pad[1]), y)
	fort_center = c
	var hs: float = 13.0
	var wh: float = 4.6
	# les murailles, avec une porte à l'ouest et une brèche au sud
	var walls := [[Vector2(-hs, -hs), Vector2(hs, -hs)], [Vector2(hs, -hs), Vector2(hs, hs)], [Vector2(hs, hs), Vector2(2.0, hs)], [Vector2(-5.0, hs), Vector2(-hs, hs)],
		[Vector2(-hs, hs), Vector2(-hs, 1.8)], [Vector2(-hs, -1.8), Vector2(-hs, -hs)]]
	for wseg in walls:
		var a: Vector2 = wseg[0]
		var b: Vector2 = wseg[1]
		var pa: Vector3 = c + Vector3(a.x, 0, a.y)
		var pb: Vector3 = c + Vector3(b.x, 0, b.y)
		var d: Vector3 = pb - pa
		var len: float = d.length()
		var bas := Basis(Vector3.UP, atan2(d.x, d.z))
		var mid: Vector3 = (pa + pb) * 0.5
		var hh: float = wh * (0.75 if a.y > 0.0 and b.y > 0.0 else 1.0)
		kit.box(Transform3D(bas, mid + Vector3.UP * (hh * 0.5 - 0.8)), Vector3(1.5, hh + 1.6, len), "pierrefort", 2.2)
		kit.col_box(Transform3D(bas, mid + Vector3.UP * (hh * 0.5 - 0.8)), Vector3(1.5, hh + 1.6, len))
		var n: int = int(len / 1.2)
		for k in range(n):
			if k % 2 == 0 and fposmod(sin(k * 3.7 + a.x) * 43758.5, 1.0) > 0.25:
				kit.box(Transform3D(bas, pa.lerp(pb, (k + 0.5) / n) + Vector3.UP * (hh + 0.35)), Vector3(1.5, 0.7, 0.6), "pierrefort", 1.4)
	# les éboulis de la brèche
	for k2 in range(9):
		var rp: Vector3 = c + Vector3(-1.5 + _rng.randf_range(-2.5, 2.5), 0.2, hs + _rng.randf_range(-1.5, 2.5))
		kit.box(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.4, 0.4)), rp), Vector3(_rng.randf_range(0.6, 1.4), _rng.randf_range(0.4, 0.9), _rng.randf_range(0.6, 1.2)), "pierrefort", 1.0)
	# les bastions d'angle, ruinés
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			var tp: Vector3 = c + Vector3(cx * hs, -0.5, cz * hs)
			kit.tower(tp, 3.0, 5.5 + (1.5 if cx > 0 else 0.0) - (2.0 if cz > 0 and cx < 0 else 0.0), {"wall": "pierrefort", "band": false, "crenel": true, "roof": "none", "seg": 14})
	# le donjon, sans toit
	var keep: Vector3 = c + Vector3(5.0, -0.3, -2.0)
	kit.tower(keep, 4.0, 9.0, {"wall": "pierrefort", "band": false, "crenel": true, "roof": "none", "seg": 18})
	var kd: Transform3D = kit.round_face(keep, 4.0, PI, 0.3)
	kit.box(kd * Transform3D(Basis(), Vector3(0, 1.1, -0.05)), Vector3(1.3, 2.2, 0.1), "goudron", 1.0)
	objets["fort_donjon"] = kd * Vector3(0, 0.3, -1.2)
	# les canons, tournés vers le large (à l'est)
	for k3 in range(3):
		kit.cannon(XF(c + Vector3(hs - 2.4, 0.0, -7.0 + k3 * 6.0), 1.0, 0.0), k3 == 1)
	# la poudrière effondrée, des tonneaux de poudre
	for k4 in range(4):
		kit.barrel(c + Vector3(-8.0 + (k4 % 2) * 0.8, 0.0, -8.0 + (k4 / 2) * 0.8))
	kit.flag_pole(c + Vector3(-6.0, 0.0, 6.0), 8.0, "balafre", Vector2(1.6, 1.0))
	_pt("fort_porte", c + Vector3(-hs - 3.0, 0.05, 0.0))
	_pt("fort_cour", c + Vector3(-4.0, 0.05, 0.0))
	flora_avoid.append([Vector2(c.x, c.z), 22.0])


# =================================================================== le Cimetière des Pirates

func _cimetiere() -> void:
	var pad: Array = R.PADS["cimetiere"]
	var c: Vector3 = W(float(pad[0]), float(pad[1]), float(pad[3]))
	# un muret de pierres sèches (une entrée au sud-est)
	var n: int = 28
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		if absf(wrapf((a0 + a1) * 0.5 - 0.75, -PI, PI)) < 0.3:
			continue
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * 10.5
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * 10.5
		p0.y = ile.height(p0.x, p0.z)
		p1.y = ile.height(p1.x, p1.z)
		kit.low_wall(p0, p1, 0.75, 0.55, "pierrefort_sombre")
	# les tombes
	for row in range(4):
		for col in range(5):
			var gp: Vector3 = c + Vector3(-6.0 + col * 2.8 + (row % 2) * 0.6, 0.0, -6.0 + row * 2.9)
			if gp.distance_to(c + Vector3(4.0, 0, 3.5)) < 3.5:
				continue
			gp.y = ile.height(gp.x, gp.z)
			var tilt := Basis(Vector3.UP, _rng.randf_range(-0.15, 0.15)) * Basis(Vector3.RIGHT, _rng.randf_range(-0.12, 0.1)) * Basis(Vector3.BACK, _rng.randf_range(-0.1, 0.1))
			if (row + col) % 3 == 0:
				kit.grave_cross(Transform3D(tilt, gp))
			else:
				kit.tombstone(Transform3D(tilt, gp), _rng.randf_range(0.7, 1.05))
	# le mausolée de Barbe-Sanglante
	var mxf: Transform3D = XF(c + Vector3(4.0, 0.0, 3.5), -1.0, 0.0)
	kit.box(mxf * Transform3D(Basis(), Vector3(0, 1.4, 1.6)), Vector3(3.4, 2.8, 3.2), "pierrefort_sombre", 1.6)
	kit.col_box(mxf * Transform3D(Basis(), Vector3(0, 1.4, 1.6)), Vector3(3.4, 2.8, 3.2))
	kit.roof_gable(mxf * Transform3D(Basis(), Vector3(0, 2.8, 1.6)), 3.4, 3.2, 30.0, 0.2, "pierrefort", "pierrefort")
	kit.box(mxf * Transform3D(Basis(), Vector3(0, 1.0, -0.02)), Vector3(1.1, 2.0, 0.06), "fer", 1.0)
	crypt_pos = mxf * Vector3(0, 0.05, -1.0)
	objets["mausolee"] = mxf * Vector3(0, 1.0, -0.6)
	# un arbre mort, deux lanternes
	var tree: Vector3 = c + Vector3(-6.5, 0.0, 5.5)
	tree.y = ile.height(tree.x, tree.z)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.12), tree), 0.35, 0.18, 4.5, "rondins", 8)
	for k5 in range(4):
		var ba: float = TAU * k5 / 4.0 + 0.3
		kit.beam(tree + Vector3(0, 2.5 + k5 * 0.5, 0), tree + Vector3(cos(ba) * 2.0, 3.6 + k5 * 0.6, sin(ba) * 2.0), 0.12, "rondins")
	kit.lantern(c + Vector3(7.0, ile.height(c.x + 7.0, c.z + 7.5) - c.y, 7.5), 0.8, pc)
	_pt("cimetiere_entree", c + Vector3(7.2, 0.0, 7.0))
	points["cimetiere_entree"] = G(R.L(points["cimetiere_entree"].x, points["cimetiere_entree"].z).x, R.L(points["cimetiere_entree"].x, points["cimetiere_entree"].z).y, 0.05)
	flora_avoid.append([Vector2(c.x, c.z), 12.0])


# =================================================================== le camp abandonné

func _camp() -> void:
	var pad: Array = R.PADS["camp"]
	var c: Vector3 = W(float(pad[0]), float(pad[1]), float(pad[3]))
	kit.tent(XF(c + Vector3(-2.5, 0, -1.5), 0.6, 1.0), 2.6, 3.0, 2.0, "toile_sale")
	kit.tent(Transform3D(Basis(Vector3.UP, 1.2) * Basis(Vector3.BACK, 0.35), c + Vector3(2.8, -0.3, -2.0)), 2.4, 2.8, 1.8, "toile_rouge")
	kit.ring(Transform3D(Basis(), c + Vector3(0.5, 0, 1.5)), 0.5, 0.75, 0.2, "pierrefort_sombre", 12)
	kit.box(Transform3D(Basis(Vector3.UP, 0.6), c + Vector3(0.5, 0.06, 1.5)), Vector3(0.9, 0.1, 0.12), "goudron", 1.0)
	kit.box(Transform3D(Basis(Vector3.UP, -0.5), c + Vector3(0.5, 0.06, 1.5)), Vector3(0.9, 0.1, 0.12), "goudron", 1.0)
	for k in range(3):
		kit.box(Transform3D(Basis(Vector3.UP, k * 0.9) * Basis(Vector3.BACK, 0.4 + k * 0.3), c + Vector3(-3.0 + k * 1.1, 0.2, 2.8)), Vector3(0.7, 0.12, 0.7), "bois", 0.7)
	# le perchoir (le perroquet Amiral s'y pose)
	var pp: Vector3 = c + Vector3(3.2, 0.0, 2.6)
	kit.cyl(Transform3D(Basis(), pp), 0.07, 0.06, 2.2, "poutre", 6)
	kit.box(Transform3D(Basis(), pp + Vector3.UP * 2.2), Vector3(0.7, 0.06, 0.06), "poutre", 1.0)
	perch_pos = pp + Vector3.UP * 2.25
	objets["perchoir"] = perch_pos
	flora_avoid.append([Vector2(c.x, c.z), 9.0])


# =================================================================== le Cirque du Crâne

func _cirque() -> void:
	cirque_center = W(R.CIRQUE.x, R.CIRQUE.y, R.RAVINE_TOP)
	skull_center = W(R.SKULL.x, R.SKULL.y, R.RAVINE_TOP)
	_skull_rock(skull_center, 5.6)
	# des torches plantées autour du Cirque (elles brûlent la nuit)
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.3
		if absf(wrapf(a - PI, -PI, PI)) < 0.5:
			continue
		var tp: Vector3 = cirque_center + Vector3(cos(a), 0, sin(a)) * (R.CIRQUE_R - 2.0)
		tp.y = ile.height(tp.x, tp.z)
		kit.cyl(Transform3D(Basis(), tp), 0.06, 0.05, 1.8, "poutre", 6)
		kit.cyl(Transform3D(Basis(), tp + Vector3.UP * 1.8), 0.1, 0.12, 0.25, "goudron", 8)
		torches.append(tp + Vector3.UP * 2.05)
	# des ossements épars
	for k2 in range(14):
		var bp: Vector3 = cirque_center + Vector3(_rng.randf_range(-10, 10), 0, _rng.randf_range(-10, 10))
		bp.y = ile.height(bp.x, bp.z) + 0.05
		kit.cyl(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.BACK, PI * 0.5), bp), 0.04, 0.035, _rng.randf_range(0.3, 0.6), "osp", 6)
	flora_avoid.append([Vector2(cirque_center.x, cirque_center.z), R.CIRQUE_R + 2.0])
	flora_avoid.append([Vector2(skull_center.x, skull_center.z), 8.0])


## Le Rocher du Crâne : une coquille de roche en forme de crâne (on entre par la bouche,
## tournée vers l'est), deux orbites qui luisent la nuit, des dents de pierre ; le trésor dedans.
func _skull_rock(c: Vector3, r: float) -> void:
	var outer := SurfaceTool.new()
	outer.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := SurfaceTool.new()
	inner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var nu: int = 36
	var nv: int = 18
	var mouth := Vector3(1, -0.32, 0).normalized()
	var eyes := [Vector3(0.82, 0.32, -0.36).normalized(), Vector3(0.82, 0.32, 0.36).normalized()]
	var shape := func(dir: Vector3) -> float:
		# un crâne : plus haut que large, la mâchoire resserrée, des bosses
		var k: float = 1.0 + 0.08 * sin(dir.x * 7.0 + dir.z * 5.0) * cos(dir.y * 6.0)
		if dir.y < -0.2:
			k *= lerpf(1.0, 0.82, smoothstep(-0.2, -0.7, dir.y))
		return r * k
	var grid: Array = []
	for j in range(nv + 1):
		var row: Array = []
		var v: float = float(j) / nv
		var phi: float = lerpf(-0.42, PI * 0.5, v)
		for i in range(nu + 1):
			var th: float = TAU * float(i) / nu
			var dir := Vector3(cos(phi) * cos(th), sin(phi), cos(phi) * sin(th))
			var rad: float = shape.call(dir)
			var p: Vector3 = c + Vector3(dir.x * rad, (sin(phi) * rad * 1.15) + rad * 0.42, dir.z * rad)
			row.append([p, dir])
		grid.append(row)
	for j in range(nv):
		for i in range(nu):
			var a: Array = grid[j][i]
			var b: Array = grid[j][i + 1]
			var cc: Array = grid[j + 1][i + 1]
			var d: Array = grid[j + 1][i]
			var dm: Vector3 = ((a[1] as Vector3) + (cc[1] as Vector3)).normalized()
			if dm.dot(mouth) > 0.9:
				continue
			var hole: bool = false
			for e in eyes:
				if dm.dot(e) > 0.975:
					hole = true
			if hole:
				continue
			var uv0 := Vector2(float(i) / nu * 6.0, float(j) / nv * 3.0)
			var uv1 := Vector2(float(i + 1) / nu * 6.0, float(j + 1) / nv * 3.0)
			for tri in [[a, b, cc, Vector2(uv0.x, uv0.y), Vector2(uv1.x, uv0.y), Vector2(uv1.x, uv1.y)], [a, cc, d, Vector2(uv0.x, uv0.y), Vector2(uv1.x, uv1.y), Vector2(uv0.x, uv1.y)]]:
				var p0: Vector3 = tri[0][0]
				var p1: Vector3 = tri[1][0]
				var p2: Vector3 = tri[2][0]
				var n_out: Vector3 = (p0 - c).normalized()
				var nn: Vector3 = (p1 - p0).cross(p2 - p0)
				var order: Array = [[p0, tri[3]], [p1, tri[4]], [p2, tri[5]]] if nn.dot(n_out) < 0.0 else [[p0, tri[3]], [p2, tri[5]], [p1, tri[4]]]
				for v2 in order:
					outer.set_uv(v2[1])
					outer.add_vertex(v2[0])
					faces.append(v2[0])
				# dedans : la même coquille, un peu plus petite, retournée
				for v3 in [order[0], order[2], order[1]]:
					inner.set_uv(v3[1])
					inner.add_vertex(c + ((v3[0] as Vector3) - c) * 0.9 + Vector3.UP * 0.25)
	outer.generate_normals()
	outer.generate_tangents()
	inner.generate_normals()
	var rock: Material = load("res://scripts/rocks_v26.gd").material(Color(0.62, 0.6, 0.56), 0.35, 0.16)
	var mi := MeshInstance3D.new()
	mi.name = "Rocher_du_Crane"
	mi.mesh = outer.commit()
	mi.material_override = rock
	add_child(mi)
	var mi2 := MeshInstance3D.new()
	mi2.name = "Rocher_du_Crane_dedans"
	mi2.mesh = inner.commit()
	var dark := StandardMaterial3D.new()
	dark.albedo_texture = load(R.TEX + "basalte.png")
	dark.uv1_scale = Vector3(2, 2, 2)
	dark.albedo_color = Color(0.55, 0.52, 0.5)
	dark.roughness = 0.95
	mi2.material_override = dark
	add_child(mi2)
	var body := StaticBody3D.new()
	body.name = "Crane_collision"
	var shp := ConcavePolygonShape3D.new()
	shp.set_faces(faces)
	shp.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shp
	body.add_child(cs)
	add_child(body)
	# les dents de pierre au bord de la bouche
	var right: Vector3 = Vector3(0, 0, 1)
	for k in range(7):
		var t: float = (k - 3.0) / 3.0
		var tp: Vector3 = c + mouth * r * 0.96 + right * t * r * 0.36 + Vector3.UP * (r * 0.42 + r * 0.06)
		kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI), tp + Vector3.UP * 1.7), 0.28, 0.05, 0.9, "osp", 6)
	# le sol dedans, un peu de sable ; le coffre, des pièces d'or
	skull_inside = c + Vector3(-1.0, 0.0, 0.0)
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.06), r * 0.86, "sable", 20, 2.0)
	treasure_pos = c + Vector3(-2.4, 0.0, 0.0)
	kit.coins(treasure_pos + Vector3(0.9, 0.06, -1.2), 14, 0.6)
	kit.coins(treasure_pos + Vector3(0.6, 0.06, 1.3), 10, 0.5)
	objets["tresor_crane"] = treasure_pos + Vector3.UP * 0.5
	# deux lueurs dans les orbites (vertes, à peine visibles le jour)
	for e2 in eyes:
		var l := OmniLight3D.new()
		l.light_color = Color(0.5, 1.0, 0.55)
		l.light_energy = 0.0
		l.omni_range = 5.0
		l.position = c + (e2 as Vector3) * r * 0.7 + Vector3.UP * r * 0.55
		add_child(l)
		kit.lights68.append(l)
	_pt("crane_bouche", c + mouth.normalized() * (r + 2.0) + Vector3.UP * 0.05)
	_pt("crane_dedans", skull_inside + Vector3.UP * 0.08)


# =================================================================== la Plage des Os

func _plage_os() -> void:
	var c: Vector3 = G(R.BONES.x + 6.0, R.BONES.y + 4.0, 0.0)
	var axis := Vector3(cos(0.6), 0, sin(0.6))
	var side := axis.cross(Vector3.UP)
	# la colonne vertébrale (des vertèbres), du crâne à la queue
	for k in range(26):
		var t: float = float(k) / 25.0
		var p: Vector3 = c + axis * lerpf(-12.0, 13.0, t)
		p.y = ile.height(p.x, p.z) + 0.6 + sin(t * PI) * 0.8 - t * 0.4
		var s: float = lerpf(0.42, 0.14, t)
		kit.box(Transform3D(Basis.looking_at(axis, Vector3.UP), p), Vector3(s * 1.4, s * 1.2, s * 0.8), "osp", 0.6)
		kit.box(Transform3D(Basis.looking_at(axis, Vector3.UP), p + Vector3.UP * s * 0.9), Vector3(s * 0.3, s * 1.2, s * 0.3), "osp", 0.6)
	# les côtes
	for k2 in range(9):
		var t2: float = float(k2) / 8.0
		var base: Vector3 = c + axis * lerpf(-7.0, 4.0, t2)
		base.y = ile.height(base.x, base.z) + 1.1
		var span: float = lerpf(3.6, 2.4, t2)
		for s2 in [-1.0, 1.0]:
			var foot: Vector3 = base + side * s2 * span * 1.2
			foot.y = ile.height(foot.x, foot.z) - 0.2
			kit.rib_arc(base, foot, lerpf(2.4, 1.6, t2) * (1.0 if k2 != 5 or s2 > 0 else 0.6), 0.16)
	# le crâne de la baleine (une grosse mâchoire couchée)
	var sk: Vector3 = c + axis * -14.5
	sk.y = ile.height(sk.x, sk.z) + 0.4
	kit.box(Transform3D(Basis.looking_at(axis, Vector3.UP), sk), Vector3(2.4, 1.0, 3.6), "osp", 1.2)
	for s3 in [-1.0, 1.0]:
		kit.beam(sk + side * s3 * 0.9 - axis * 1.6, sk + side * s3 * 1.6 - axis * 6.0 + Vector3.DOWN * 0.3, 0.3, "osp")
	flora_avoid.append([Vector2(c.x, c.z), 18.0])
	objets["baleine"] = c + Vector3.UP * 1.0


# =================================================================== les sentiers

## Les sentiers de la jungle : de la terre battue (pas de dalles), des lanternes près du port.
func _sentiers() -> void:
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		for p in pts:
			flora_avoid.append([Vector2((p as Vector3).x, (p as Vector3).z), 2.4])


# =================================================================== le marais

## L'eau dormante du Marais des Noyés : un plan d'eau trouble au-dessus de la vase.
func _marais() -> void:
	var c: Vector3 = W(R.MARSH.x, R.MARSH.y, R.MARSH_Y)
	var pm := PlaneMesh.new()
	pm.size = Vector2((R.MARSH_R + 14.0) * 2.0, (R.MARSH_R + 14.0) * 2.0)
	mud_water = MeshInstance3D.new()
	mud_water.name = "Eau_marais_v68"
	mud_water.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.14, 0.17, 0.1, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/water/water_n.png")
	m.normal_scale = 0.25
	m.uv1_scale = Vector3(18, 18, 18)
	m.roughness = 0.08
	m.metallic_specular = 0.7
	mud_water.material_override = m
	mud_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mud_water)
	mud_water.global_position = c


# =================================================================== le bric-à-brac du port

## Ce qui traîne dans une ville de pirates : tonneaux, caisses, sacs, charrettes, étals, canons,
## linge qui sèche, planches, cordages, palmiers, braseros… posés au hasard (toujours le même)
## entre les maisons, jamais sur un chemin des habitants, devant une porte ou sur un lieu.
func _bric_a_brac() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6871
	var segs: Array = []
	for a in graph:
		if not points.has(a):
			continue
		for b in graph[a]:
			if points.has(b) and str(a) < str(b):
				segs.append([points[a], points[b]])
	var blocked := func(p: Vector3, r: float) -> bool:
		var l: Vector2 = R.L(p.x, p.z)
		if l.x < -74.0 or l.x > 74.0 or l.y < 41.0 or l.y > 81.0:
			return true
		if inside(p) != "":
			return true
		var p2 := Vector2(p.x, p.z)
		for sg in segs:
			var a2 := Vector2(sg[0].x, sg[0].z)
			var b2 := Vector2(sg[1].x, sg[1].z)
			if Geometry2D.get_closest_point_to_segment(p2, a2, b2).distance_to(p2) < r + 1.5:
				return true
		for k in spots:
			var sp: Vector3 = spots[k]["pos"]
			if Vector2(sp.x, sp.z).distance_to(p2) < r + 1.3:
				return true
		for k2 in doors:
			var dp: Vector3 = doors[k2]
			if Vector2(dp.x, dp.z).distance_to(p2) < r + 2.6:
				return true
		for fa in flora_avoid:
			if float(fa[1]) < 15.0 and (fa[0] as Vector2).distance_to(p2) < float(fa[1]) * 0.8 + r:
				return true
		var box := Rect2(p.x - r, p.z - r, r * 2.0, r * 2.0)
		for f in kit.foot:
			if (f as Rect2).grow(0.4).intersects(box):
				return true
		var h0: float = ile.height(p.x, p.z)
		for d in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
			if absf(ile.height(p.x + d.x, p.z + d.y) - h0) > 0.45:
				return true
		return h0 < 0.6
	var kinds := [["tonneaux", 3.0, 1.3], ["caisses", 3.0, 1.3], ["sacs", 2.0, 1.0], ["charrette", 1.4, 2.2], ["etal", 1.6, 2.2], ["canon", 0.6, 1.7],
		["linge", 1.0, 1.0], ["planches", 1.0, 1.3], ["cordages", 1.0, 0.8], ["palmier", 1.6, 1.6], ["brasero", 0.6, 1.2], ["cage", 0.5, 0.6]]
	var total: float = 0.0
	for kd in kinds:
		total += float(kd[1])
	var placed: int = 0
	for attempt in range(700):
		if placed >= 56:
			break
		var lx: float = rng.randf_range(-74.0, 74.0)
		var lz: float = rng.randf_range(41.0, 81.0)
		var pick: float = rng.randf() * total
		var kind: Array = kinds[0]
		for kd2 in kinds:
			pick -= float(kd2[1])
			if pick <= 0.0:
				kind = kd2
				break
		var r: float = float(kind[2])
		var p: Vector3 = W(lx, lz, 0.0)
		p.y = ile.height(p.x, p.z)
		if blocked.call(p, r):
			continue
		var yaw: float = rng.randf() * TAU
		match str(kind[0]):
			"tonneaux":
				var n: int = rng.randi_range(2, 4)
				for i in range(n):
					var off := Vector3(cos(i * 2.2) * 0.7, 0.0, sin(i * 2.2) * 0.7) if i > 0 else Vector3.ZERO
					var q: Vector3 = p + off
					q.y = ile.height(q.x, q.z)
					kit.barrel(q, i == 0)
			"caisses":
				kit.crate(p, yaw, 0.85, true)
				kit.crate(p + Vector3(cos(yaw), 0, sin(yaw)) * 0.9, yaw + 0.3, 0.7, true)
				kit.crate(p + Vector3.UP * 0.85, yaw + 0.5, 0.6)
			"sacs":
				for i2 in range(rng.randi_range(3, 5)):
					var a3: float = yaw + i2 * 1.1
					var q2: Vector3 = p + Vector3(cos(a3), 0, sin(a3)) * 0.45 * float(i2 > 0)
					kit.cyl(Transform3D(Basis(Vector3.UP, a3) * Basis(Vector3.BACK, PI * 0.5), q2 + Vector3.UP * 0.2), 0.22, 0.24, 0.62, "toile_sale", 8)
				kit.col_box(Transform3D(Basis(), p + Vector3.UP * 0.25), Vector3(1.2, 0.5, 1.2))
			"charrette":
				kit.cart(Transform3D(Basis(Vector3.UP, yaw), p), ["tonneaux", "sacs", "caisses", ""][rng.randi() % 4])
			"etal":
				var nearest := Vector3.ZERO
				var nd: float = INF
				for sg2 in segs:
					var c2: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(sg2[0].x, sg2[0].z), Vector2(sg2[1].x, sg2[1].z))
					var dd: float = c2.distance_to(Vector2(p.x, p.z))
					if dd < nd:
						nd = dd
						nearest = Vector3(c2.x - p.x, 0, c2.y - p.z)
				var xf_e: Transform3D = XF(p, nearest.x, nearest.z) if nearest.length() > 0.1 else Transform3D(Basis(Vector3.UP, yaw), p)
				kit.stall(xf_e, ["toile_rouge", "toile_bleu", "toile_sale", "toile"][rng.randi() % 4], ["poisson", "fruits", "bouteilles", ""][rng.randi() % 4])
			"canon":
				kit.cannon(Transform3D(Basis(Vector3.UP, yaw), p), rng.randf() < 0.6)
				kit.col_box(Transform3D(Basis(Vector3.UP, yaw), p + Vector3.UP * 0.5), Vector3(1.0, 1.0, 2.2))
			"linge":
				var dir := Vector3(cos(yaw), 0, sin(yaw))
				var a4: Vector3 = p - dir * 1.8
				var b4: Vector3 = p + dir * 1.8
				if blocked.call(a4, 0.3) or blocked.call(b4, 0.3):
					continue
				a4.y = ile.height(a4.x, a4.z)
				b4.y = ile.height(b4.x, b4.z)
				kit.laundry(a4, b4)
			"planches":
				for i3 in range(rng.randi_range(5, 9)):
					kit.box(Transform3D(Basis(Vector3.UP, yaw + rng.randf_range(-0.08, 0.08)), p + Vector3.UP * (0.05 + i3 * 0.07)), Vector3(3.0, 0.06, 0.28), "planchesp", 1.0)
				kit.col_box(Transform3D(Basis(Vector3.UP, yaw), p + Vector3.UP * 0.3), Vector3(3.0, 0.6, 0.6))
			"cordages":
				kit.cyl(Transform3D(Basis(), p), 0.45, 0.45, 0.16, "cordage", 14)
				kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.16), 0.36, 0.36, 0.14, "cordage", 14)
				kit.col_cyl(p, 0.45, 0.3)
			"palmier":
				extra_palms.append(p)
				flora_avoid.append([Vector2(p.x, p.z), 1.0])
			"brasero":
				kit.cyl(Transform3D(Basis(), p), 0.3, 0.38, 0.7, "fer", 10)
				kit.disc(Transform3D(Basis(), p + Vector3.UP * 0.71), 0.32, "braise", 10)
				fire_spots.append([p + Vector3.UP * 0.75, 0.5])
				kit.col_cyl(p, 0.4, 0.75)
			"cage":
				kit.cage(p + Vector3.UP * 0.3, 0.3, 0.6)
				kit.col_cyl(p, 0.32, 0.9)
		kit.foot.append(Rect2(p.x - r, p.z - r, r * 2.0, r * 2.0))
		placed += 1
	print("ILE_MANGA_V68: bric-à-brac du port : %d" % placed)


# =================================================================== le graphe des habitants

func _graph() -> void:
	var qy: float = TY(0.0, R.QUAY_Z) + 0.12
	# le quai
	var quay: Array = []
	for qx in [-46.0, -36.0, -25.0, -12.0, 0.0, 12.0, 22.0, 34.0, 46.0, 55.0, 60.0]:
		quay.append(_pt("q_%d" % int(qx + 100.0), W(qx, 88.6, qy)))
	_chain(quay)
	# les pontons et les navires
	var py: float = _pier_y() + 0.12
	_pt("pa_1", W(R.PIER_A[0].x, 96.0, py))
	_pt("pa_2", W(R.PIER_A[0].x, 106.0, py))
	_pt("pa_3", W(R.PIER_A[0].x, 117.0, py))
	_pt("pa_bout", W(R.PIER_A[0].x, 126.0, py))
	_chain(["q_75", "pa_1", "pa_2", "pa_3", "pa_bout"])
	_pt("pb_1", W(R.PIER_B[0].x, 96.0, py))
	_pt("pb_2", W(R.PIER_B[0].x, 104.0, py))
	_pt("pb_3", W(R.PIER_B[0].x, 112.0, py))
	_pt("pb_bout", W(R.PIER_B[0].x, 124.0, py))
	_chain(["q_122", "pb_1", "pb_2", "pb_3", "pb_bout"])
	_link("pa_3", "requin_bas")
	_link("pb_3", "veuve_bas")
	_ship_graph("requin")
	_ship_graph("veuve")
	_spot("ponton_peche_1", spots["ponton_peche_1"]["pos"], spots["ponton_peche_1"]["face"], "pecher", "pa_bout")
	_spot("ponton_peche_2", spots["ponton_peche_2"]["pos"], spots["ponton_peche_2"]["face"], "pecher", "pb_bout")
	# la rue du port et la place
	var street: Array = []
	for sx in [-62.0, -50.0, -38.0, -22.0, -8.0, 6.0, 20.0, 34.0, 48.0, 60.0]:
		street.append(_pg("r_%d" % int(sx + 100.0), sx, 80.0))
	_chain(street)
	for pair in [["q_54", "r_50"], ["q_88", "r_92"], ["q_112", "r_106"], ["q_146", "r_148"], ["q_160", "r_160"]]:
		_link(str(pair[0]), str(pair[1]))
	_pg("sq_c", 6.0, 66.0)
	_pg("sq_n", 2.0, 52.0)
	_pg("sq_w", -12.0, 62.0)
	_pg("sq_e", 20.0, 62.0)
	_pg("sq_s", 2.0, 74.0)
	_chain(["sq_s", "sq_c", "sq_e"])
	_chain(["sq_c", "sq_w"])
	_link("sq_w", "sq_n")
	_link("sq_e", "sq_n")
	_link("sq_s", "r_106")
	_link("sq_s", "r_92")
	_link("sq_w", "cf_porte")
	_link("sq_e", "dr_porte")
	# vers le nord : le sentier, la résidence
	_pg("n_ville", 0.0, 44.0)
	_link("sq_n", "n_ville")
	_link("n_ville", "res_bas")
	_chain(["res_bas", "res_perron", "porte_residence"])
	# l'ouest : le receleur, le chirurgien, les cases
	_pg("w_1", -46.0, 66.0)
	_pg("w_2", -60.0, 66.0)
	_pg("w_3", -60.0, 50.0)
	_pg("w_4", -44.0, 52.0)
	_chain(["r_62", "w_1", "w_2", "w_3", "w_4"])
	_link("w_1", "sq_w")
	_link("w_4", "sq_w")
	_link("r_50", "devant_receleur")
	_link("w_3", "devant_doc")
	_link("w_4", "devant_case_joe")
	_link("sq_n", "devant_case_requins")
	_link("w_2", "devant_case_crochet")
	_link("w_3", "devant_case_morue")
	_link("r_38", "devant_case_silas")
	# l'est : la forge, la tour, les cases
	_pg("e_1", 46.0, 64.0)
	_pg("e_2", 62.0, 66.0)
	_pg("e_3", 46.0, 46.0)
	_chain(["sq_e", "e_1", "e_2", "r_160"])
	_link("e_1", "e_3")
	_link("e_3", "forge_in")
	_link("e_3", "devant_brutus")
	_link("e_3", "devant_case_tom")
	_link("e_2", "devant_case_ecarlates")
	_link("r_160", "porte_lunette")
	_link("sq_n", "devant_case_coralie")
	_link("devant_case_coralie", "devant_case_tom")
	# la grève de carénage
	_pg("car_1", -63.0, 91.8)
	_pg("car_2", -68.0, 100.0)
	_pg("car_3", -62.0, 108.0)
	_chain(["r_38", "car_1", "car_2", "car_3"])
	_link("car_1", "devant_case_gwen")
	# rattacher chaque lieu à son point le plus proche
	for k in spots:
		var sp: Dictionary = spots[k]
		if str(sp.get("node", "")) != "" and points.has(str(sp["node"])):
			continue
		sp["node"] = _nearest(sp["pos"])
	print("ILE_MANGA_V68: graphe du port, %d points" % points.size())


## Les points sur le pont d'un navire (la passerelle, le grand mât, la dunette, le gaillard).
func _ship_graph(id: String) -> void:
	var s: Node3D = ships[id]
	_link(id + "_bas", id + "_plat")
	_link(id + "_plat", id + "_pont")
	_pt(id + "_milieu", s.deck_at(4.0, 0.0) + Vector3.UP * 0.08)
	_pt(id + "_avant", s.deck_at(12.0, 0.0) + Vector3.UP * 0.08)
	_pt(id + "_arriere", s.deck_at(-10.0, 0.0) + Vector3.UP * 0.08)
	_pt("porte_" + id, s.deck_at(s.CASTLE_X + 0.4, 0.0) + Vector3.UP * 0.08)
	_chain([id + "_pont", id + "_milieu", id + "_avant"])
	_chain([id + "_pont", id + "_arriere", "porte_" + id])
	_spot(id + "_pont_1", s.deck_at(6.0, 2.2) + Vector3.UP * 0.05, s.deck_at(6.0, 6.0), "bras_croises", id + "_milieu")
	_spot(id + "_pont_2", s.deck_at(-6.0, -2.0) + Vector3.UP * 0.05, s.deck_at(-6.0, -6.0), "debout", id + "_arriere")
	_spot(id + "_pont_3", s.deck_at(10.0, -1.6) + Vector3.UP * 0.05, s.deck_at(14.0, -1.6), "bricoler", id + "_avant")
	_spot(id + "_barre", s.deck_at(s.CASTLE_X + 1.2, 1.6) + Vector3.UP * 0.05, s.deck_at(20.0, 1.6), "bras_croises", "porte_" + id)
	_spot(id + "_proue", s.deck_at(13.0, 0.8) + Vector3.UP * 0.05, s.deck_at(30.0, 0.8), "debout", id + "_avant")


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


## Dans un intérieur (tripot), le point du graphe où l'on se trouve (sinon "").
func inside(p: Vector3) -> String:
	for it in interiors:
		var c: Vector3 = it[1]
		var half: Vector2 = it[2]
		if absf(p.x - c.x) < half.x + 0.4 and absf(p.z - c.z) < half.y + 0.4 and p.y > float(it[3]) - 1.0 and p.y < float(it[3]) + 4.0:
			return str(it[0])
	return ""


# =================================================================== le monde autour

func on_structure(p: Vector3) -> bool:
	for id in ships:
		if (ships[id] as Node3D).aboard(p):
			return true
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


func blocks_boat(p: Vector3) -> bool:
	for id in ships:
		if (ships[id] as Node3D).blocks_boat(p):
			return true
	var l: Vector2 = R.L(p.x, p.z)
	for pr in [R.PIER_A, R.PIER_B]:
		var a: Vector2 = pr[0]
		var b: Vector2 = pr[1]
		if absf(l.x - a.x) < 3.4 and l.y > a.y - 1.0 and l.y < b.y + 2.0:
			return true
	for jx in [R.QUAY_X0 - 0.7, R.QUAY_X1 + 0.7]:
		if absf(l.x - jx) < 3.0 and l.y > R.QUAY_Z - 1.0 and l.y < R.BAY_RECT.end.y + 2.0:
			return true
	return false


func zone_at(p: Vector3) -> String:
	var it: String = inside(p)
	if it != "":
		return "balafre_" + it
	for id in ships:
		if (ships[id] as Node3D).aboard(p):
			return "balafre_navire"
	return ""

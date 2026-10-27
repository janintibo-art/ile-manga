extends Node3D
## V60 : Tazira, le grand port de pêcheurs de la côte sud de la grande île (le désert).
## Un port berbère fortifié au bord des dunes :
##  - le port : un bassin abrité par deux jetées (un petit phare vert, un petit phare rouge),
##    le quai où l'on décharge, des dizaines de barques bleues au mouillage ou tirées sur la
##    plage ; à l'aube, la flotte sort ; vers dix heures, elle rentre et la criée commence ;
##  - la criée (le marché au poisson, sous une halle à arcades), les grilleurs de sardines,
##    les ramendeuses de filets, le chantier des barques ;
##  - la Skala : le bastion aux canons de bronze sur la pointe rocheuse, et sa tour de guet ;
##  - la ville : maisons cubiques blanchies à la chaux, portes bleues en fer à cheval,
##    terrasses crénelées, linge qui sèche ; remparts de pisé ocre, la porte du nord ;
##  - la place des Lanternes et sa fontaine de zellige : le soir, la fête (musiciens,
##    danseurs, braseros, guirlandes de lanternes, grillades) ;
##  - le souk couvert de claies de roseaux : épices, tapis, lanternes, poteries, babouches,
##    dattes, cuivres, tissus ;
##  - le Fondouk (l'auberge) ; et, près du quai où est amarré le galion pirate la Murène Noire,
##    la taverne des pirates : La Murène Ivre.
## Repère « ville » : voir tazira_relief_v60.gd (origine au milieu du quai, +Z vers les terres).

const R = preload("res://scripts/tazira_relief_v60.gd")
const Kit = preload("res://scripts/tazira_kit_v60.gd")
const NavireScript = preload("res://scripts/navire_v60.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const JungleFlora = preload("res://scripts/jungle_flora_v30.gd")
const SHIP_X: float = 63.0             # le galion, le long du quai (milieu, repère ville)
const SHIP_Z: float = -7.6
const JETTY_A := [Vector2(-87.0, 2.0), Vector2(-87.0, -96.0), Vector2(-42.0, -108.0)]
const JETTY_B := [Vector2(112.0, -72.0), Vector2(60.0, -108.0)]
const JETTY_Y: float = 2.3
const DOCK_X: float = -50.0                 # le ponton de la barque du joueur
const MURENE: Rect2 = R.MURENE                    # la taverne des pirates (x, z, largeur, profondeur)
const SQUARE := Rect2(-42.0, 20.0, 42.0, 24.0)
const SOUK_X0: float = -14.0
const SOUK_X1: float = -2.0
const SOUK_Z0: float = 46.0
const SOUK_Z1: float = 77.0

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var ship: Node3D
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var objets: Dictionary = {}            # objets de quête : nom -> Vector3 monde
var boat_dock: Array = []
var walk_boxes: Array = []             # [Transform3D inverse, demi-taille] : jetées, passerelle
var _moored: MultiMeshInstance3D
var _moored_xf: Array = []
var _fleet: Array = []                 # {node, mooring (Vector2 ville), dep, ret, path}
var _crates: Node3D                    # les caisses de poisson sur le quai (après le retour)
var _fete_nodes: Array = []            # ce qui ne s'allume que pendant la fête
var _fete_lights: Array = []
var _fires: Array = []                 # [OmniLight3D, MeshInstance3D]
var _smoke: Array = []                 # particules des grills
var _gulls: Array = []
var _cats: Array = []
var _music: AudioStreamPlayer3D
var fete_on: bool = false
var fete_heard: bool = false
var _clock: float = 0.0
var _boat_mesh: ArrayMesh
var _rng := RandomNumberGenerator.new()


# =================================================================== repères

func T(x: float, z: float, dy: float = 0.0) -> Vector3:
	return R.to_world(x, z, R.town_y(x, z) + dy)


func TF(x: float, z: float, rot: float = 0.0, dy: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI + deg_to_rad(rot)), T(x, z, dy))


func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.to_world(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func GF(x: float, z: float, rot: float = 0.0, dy: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI + deg_to_rad(rot)), G(x, z, dy))


func W(x: float, z: float, y: float) -> Vector3:
	return R.to_world(x, z, y)


func contains(p: Vector3) -> bool:
	var t: Vector2 = R.to_town(p.x, p.z)
	return t.x > -200.0 and t.x < 150.0 and t.y > -125.0 and t.y < 95.0 and p.y > -30.0


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6000
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6001
	_paving()
	_quay()
	_jetties()
	_skala()
	_criee()
	_quay_life()
	_square()
	_souk()
	_houses()
	_ramparts()
	_fondouk()
	_murene()
	kit.commit()
	ship = NavireScript.new()
	ship.name = "Murene_Noire_v60"
	add_child(ship)
	ship.place(W(SHIP_X, SHIP_Z, -2.8), 0.0)
	ship.build(pc)
	_gangplank()
	_boats()
	_palms()
	_make_gulls()
	_make_cats()
	_fete_build()
	_graph()
	# les lampes s'éteignent de loin (une rue de lanternes ne compte que quand on y est)
	for l in find_children("*", "OmniLight3D", true, false):
		var ol: OmniLight3D = l
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 55.0
		ol.distance_fade_length = 15.0
		ol.shadow_enabled = false
	print("ILE_MANGA_V60: Tazira, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


## Le pavage : dalles sur le quai, pavés dans la ville (des carreaux qui suivent la pente).
func _paving() -> void:
	var step: float = 4.0
	var x: float = -88.0
	while x < 83.0:
		var z: float = 0.2
		while z < 18.0:
			var x1: float = minf(x + step, 83.0)
			var z1: float = minf(z + step, 18.0)
			kit.quad4("dalles", W(x, z, 1.43), W(x1, z, 1.43), W(x1, z1, 1.43), W(x, z1, 1.43), Vector3.UP,
				Vector2(x, z) * 0.25, Vector2(x1, z) * 0.25, Vector2(x1, z1) * 0.25, Vector2(x, z1) * 0.25)
			z = z1
		x += step
	# les dalles de la Skala, posées sur la roche
	var sx: float = R.SKALA.position.x + 1.0
	while sx < R.SKALA.end.x - 1.0:
		var sz: float = R.SKALA.position.y + 1.5
		while sz < R.SKALA.end.y - 1.0:
			var sx1: float = minf(sx + 3.0, R.SKALA.end.x - 1.0)
			var sz1: float = minf(sz + 3.0, R.SKALA.end.y - 1.0)
			kit.quad4("dalles", G(sx, sz, 0.04), G(sx1, sz, 0.04), G(sx1, sz1, 0.04), G(sx, sz1, 0.04), Vector3.UP,
				Vector2(sx, sz) * 0.33, Vector2(sx1, sz) * 0.33, Vector2(sx1, sz1) * 0.33, Vector2(sx, sz1) * 0.33)
			sz = sz1
		sx += 3.0
	x = -103.0
	while x < 103.0:
		var z2: float = 18.0
		while z2 < 78.0:
			var xb: float = minf(x + step, 103.0)
			var zb: float = minf(z2 + step, 78.0)
			kit.quad4("paves", T(x, z2, 0.04), T(xb, z2, 0.04), T(xb, zb, 0.04), T(x, zb, 0.04), Vector3.UP,
				Vector2(x, z2) * 0.3, Vector2(xb, z2) * 0.3, Vector2(xb, zb) * 0.3, Vector2(x, zb) * 0.3)
			z2 = zb
		x += step


func _quay() -> void:
	# le mur du quai, vertical, de pierre
	kit.box(Transform3D(Basis(Vector3.UP, PI), W(2.0, -0.35, (R.BASIN_Y + R.QUAY_Y) * 0.5)), Vector3(180.0, R.QUAY_Y - R.BASIN_Y, 0.7), "moellons", 2.0, 63 - 8)
	kit.box(Transform3D(Basis(Vector3.UP, PI), W(2.0, 0.2, R.QUAY_Y + 0.05)), Vector3(180.0, 0.12, 0.8), "pierre", 1.5)
	# les bittes d'amarrage et les anneaux
	var x: float = -82.0
	while x < 82.0:
		kit.bollard(T(x, 0.9))
		x += 7.0
	# les échelles de fer dans le mur du quai
	for lx in [-60.0, -20.0, 20.0]:
		for k in range(7):
			kit.box(Transform3D(Basis(Vector3.UP, PI), W(lx, -0.75, R.QUAY_Y - 0.4 - k * 0.45)), Vector3(0.6, 0.04, 0.04), "fer", 0.5)
	boat_dock = [W(DOCK_X, -0.2, 1.0), W(DOCK_X, -15.0, 1.0)]


func _rubble(path: Array, top_w: float, label: String) -> void:
	var xfs: Array = []
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var L: float = a.distance_to(b)
		var dir: Vector2 = (b - a).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var s: float = 0.0
		while s < L:
			for side in [-1.0, 1.0]:
				for row in range(2):
					var p: Vector2 = a + dir * (s + _rng.randf_range(-0.8, 0.8)) + nrm * side * (top_w * 0.5 + 0.8 + row * 2.2 + _rng.randf_range(-0.4, 0.4))
					var w := W(p.x, p.y, JETTY_Y - 1.6 - row * 1.6)
					var sc: float = _rng.randf_range(1.6, 2.6)
					xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).rotated(Vector3.RIGHT, _rng.randf_range(-0.4, 0.4)).scaled(Vector3.ONE * sc), w))
			s += 2.4
	var mesh: ArrayMesh = Rocks.shape(6010 + label.length(), Vector3(1.4, 1.0, 1.2), 0.9, 0.12)
	mesh.surface_set_material(0, Rocks.material(Color(0.66, 0.62, 0.55), 0.0, 0.25))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Enrochement_" + label
	mmi.multimesh = mm
	add_child(mmi)


func _jetties() -> void:
	for jp in [[JETTY_A, "jetee_a"], [JETTY_B, "jetee_b"]]:
		var path: Array = jp[0]
		_rubble(path, 4.6, str(jp[1]))
		for i in range(path.size() - 1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var mid: Vector2 = (a + b) * 0.5
			var L: float = a.distance_to(b) + 4.6
			var wa: Vector3 = W(a.x, a.y, 0)
			var wb: Vector3 = W(b.x, b.y, 0)
			var f: Vector3 = (wb - wa).normalized()
			var bas := Basis(f.cross(Vector3.UP).normalized(), Vector3.UP, -f)
			var xf := Transform3D(bas, W(mid.x, mid.y, JETTY_Y - 1.4))
			kit.box(xf, Vector3(4.6, 2.8, L), "moellons", 2.0)
			kit.col_box(xf, Vector3(4.6, 2.8, L))
			walk_boxes.append([xf.affine_inverse(), Vector3(2.6, 4.0, L * 0.5)])
			# le parapet côté large
			var px := xf * Transform3D(Basis(), Vector3(2.0, 1.95, 0))
			kit.box(px, Vector3(0.6, 1.1, L), "moellons", 2.0)
			kit.col_box(px, Vector3(0.6, 1.1, L))
		# le petit phare au bout de la jetée
		var tip: Vector2 = path[path.size() - 1]
		var base: Vector3 = W(tip.x, tip.y, JETTY_Y)
		var green: bool = str(jp[1]) == "jetee_a"
		kit.cyl(Transform3D(Basis(), base), 1.3, 1.0, 6.5, "chaux_blanc", 16)
		kit.cyl(Transform3D(Basis(), base + Vector3.UP * 6.5), 1.2, 1.2, 0.3, "peinture_vert" if green else "peinture_rouge", 16)
		kit.cyl(Transform3D(Basis(), base + Vector3.UP * 6.8), 0.6, 0.6, 1.0, "lampe", 10, false)
		kit.cyl(Transform3D(Basis(), base + Vector3.UP * 7.8), 0.8, 0.05, 0.6, "peinture_vert" if green else "peinture_rouge", 10)
		kit.col_cyl(base, 1.3, 6.5)
		if kit.temps != null:
			var l := OmniLight3D.new()
			l.light_color = Color(0.3, 1.0, 0.4) if green else Color(1.0, 0.25, 0.2)
			l.omni_range = 14.0
			l.position = base + Vector3.UP * 7.2
			add_child(l)
			kit.temps.register_lamp(l, 2.5)


## La Skala : le bastion sur la pointe, ses merlons, ses canons de bronze, sa tour de guet.
func _skala() -> void:
	var y: float = R.SKALA_Y
	var r: Rect2 = R.SKALA
	# le parapet côté mer (le sud et l'ouest de la pointe)
	var segs := [[Vector2(r.position.x + 2.0, r.position.y + 1.0), Vector2(r.end.x - 1.0, r.position.y + 1.0)],
		[Vector2(r.end.x - 1.0, r.position.y + 1.0), Vector2(r.end.x - 1.0, r.end.y - 10.0)]]
	for sg in segs:
		var a: Vector2 = sg[0]
		var b: Vector2 = sg[1]
		var wa: Vector3 = W(a.x, a.y, y)
		var wb: Vector3 = W(b.x, b.y, y)
		var f: Vector3 = (wb - wa).normalized()
		var bas := Basis(f.cross(Vector3.UP).normalized(), Vector3.UP, -f)
		var L: float = wa.distance_to(wb)
		var xf := Transform3D(bas, (wa + wb) * 0.5 + Vector3.UP * 0.55)
		kit.box(xf, Vector3(1.2, 1.1 + 2.0, L), "pise", 2.0)
		kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(1.2, 2.4, L))
		# les embrasures et les canons
		var n: int = int(L / 9.0)
		for k in range(n):
			var t: float = (k + 0.5) / n
			var p: Vector3 = wa.lerp(wb, t)
			var out_dir: Vector3 = bas.x
			if out_dir.dot(Vector3(p.x, 0, p.z) - W(r.get_center().x, r.get_center().y, 0) * Vector3(1, 0, 1)) < 0.0:
				out_dir = -out_dir
			var cb := Basis.looking_at(out_dir, Vector3.UP)
			kit.cannon(Transform3D(cb, p - out_dir * 1.8))
			kit.box(Transform3D(bas, p + Vector3.UP * 2.25), Vector3(1.3, 0.6, 2.0), "pise", 2.0)
		kit.merlons(Transform3D(Basis(bas.z, Vector3.UP, -bas.x), (wa + wb) * 0.5 + Vector3.UP * 1.1), L, 1.0, 1.2, "pise")
	# le bastion : de hauts murs de moellons qui tombent dans la mer (côté port et côté large)
	for wl in [[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y - 6.0)], [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)]]:
		var a2: Vector2 = wl[0]
		var b2: Vector2 = wl[1]
		var wa2: Vector3 = W(a2.x, a2.y, 0.0)
		var wb2: Vector3 = W(b2.x, b2.y, 0.0)
		var f2: Vector3 = (wb2 - wa2).normalized()
		var bas2 := Basis(f2.cross(Vector3.UP).normalized(), Vector3.UP, -f2)
		var L2: float = wa2.distance_to(wb2) + 2.0
		var bxf := Transform3D(bas2, (wa2 + wb2) * 0.5 + Vector3.UP * (y - 9.0) * 0.5)
		kit.box(bxf, Vector3(2.4, y + 9.0, L2), "moellons", 2.5)
		kit.col_box(bxf, Vector3(2.4, y + 9.0, L2))
	# la tour de guet, carrée, à l'angle
	var tw: Vector3 = W(r.end.x - 6.0, r.position.y + 6.0, y)
	var txf := Transform3D(Basis(Vector3.UP, PI), tw)
	kit.box(txf * Transform3D(Basis(), Vector3(0, 5.5, 0)), Vector3(5.0, 11.0, 5.0), "pise", 3.0)
	kit.col_box(txf * Transform3D(Basis(), Vector3(0, 5.5, 0)), Vector3(5.0, 11.0, 5.0))
	kit.merlons(txf * Transform3D(Basis(), Vector3(0, 0, -2.4)), 5.0, 11.0, 0.3, "pise")
	kit.merlons(txf * Transform3D(Basis(), Vector3(0, 0, 2.4)), 5.0, 11.0, 0.3, "pise")
	kit.horseshoe_door(txf * Transform3D(Basis(), Vector3(0, 0, -2.52)), 1.2, 2.4, "porte_arc", "pise")
	kit.maroc_lantern(txf * Transform3D(Basis(), Vector3(0, 3.2, -2.9)), 1.2)
	# le drapeau de Tazira sur la tour (rouge, une barque blanche)
	kit.cyl(txf * Transform3D(Basis(), Vector3(0, 11.0, 0)), 0.06, 0.05, 4.0, "bois_sombre", 6)
	kit.quad(txf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.9, 14.3, 0)), 1.8, 1.1, "tissu_rouge", Vector2(0, 0), Vector2(1, 1), true)


func _criee() -> void:
	# une halle à arcades : piliers, arcs, toit-terrasse, ouverte sur le quai
	var x0: float = 0.0
	var x1: float = 36.0
	var z0: float = 3.0
	var z1: float = 15.0
	var h: float = 4.6
	var xc: float = (x0 + x1) * 0.5
	var zc: float = (z0 + z1) * 0.5
	var px: float = x0
	while px <= x1 + 0.01:
		for pz in [z0, z1]:
			kit.box(TF(px, pz, 0.0, h * 0.5), Vector3(0.7, h, 0.7), "chaux_blanc", 2.0)
			kit.col_box(TF(px, pz, 0.0, h * 0.5), Vector3(0.7, h, 0.7))
		px += 4.0
	for pz2 in [z0, (z0 + z1) * 0.5, z1]:
		kit.col_box(TF(x0, pz2, 0.0, h * 0.5), Vector3(0.7, h, 0.7))
	kit.box(TF(xc, zc, 0.0, h + 0.3), Vector3(x1 - x0 + 1.4, 0.6, z1 - z0 + 1.4), "chaux_blanc", 3.0)
	kit.box(TF(xc, z0, 0.0, h - 0.5), Vector3(x1 - x0 + 0.7, 0.8, 0.5), "chaux_bleu", 3.0)
	kit.box(TF(xc, z1, 0.0, h - 0.5), Vector3(x1 - x0 + 0.7, 0.8, 0.5), "chaux_bleu", 3.0)
	kit.merlons(TF(xc, z0, 0.0, 0.0), x1 - x0 + 1.4, h + 0.6, 0.3, "chaux_blanc")
	_sign(TF(xc, z0 - 0.3, 0.0, h - 0.5), 3.6, 1.8, "enseigne_criee")
	# les étals de poisson sur glace, les caisses, la balance
	for k in range(3):
		var tx: float = 6.0 + k * 12.0
		var txf: Transform3D = TF(tx, 10.0, 0.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(7.0, 0.9, 1.6), "zellige", 1.2)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.93, 0)), Vector3(6.8, 0.08, 1.4), "glace", 1.0)
		kit.col_box(txf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(7.0, 0.9, 1.6))
		for f in range(22):
			var fx: float = kit.rng.randf_range(-3.2, 3.2)
			var fz: float = kit.rng.randf_range(-0.6, 0.6)
			var s: float = kit.rng.randf_range(0.7, 1.4)
			kit.box(txf * Transform3D(Basis(Vector3.UP, kit.rng.randf() * PI), Vector3(fx, 1.0, fz)), Vector3(0.4 * s, 0.07 * s, 0.11 * s), "poisson", 0.5)
	# l'estrade du crieur
	kit.box(TF(18.0, 5.0, 0.0, 0.2), Vector3(1.6, 0.4, 1.4), "bois_sombre", 1.0)
	kit.col_box(TF(18.0, 5.0, 0.0, 0.2), Vector3(1.6, 0.4, 1.4))
	for k2 in range(8):
		kit.crate(T(33.0 + (k2 % 3) * 0.75, 13.0 - (k2 / 3) * 0.75), 0.0, 0.7)
	kit.maroc_lantern(TF(10.0, 9.0, 0.0, h - 0.1))
	kit.maroc_lantern(TF(26.0, 9.0, 0.0, h - 0.1))
	_spot("criee_crieur", 18.0, 5.0, 18.0, 0.0, "crier", "c_criee", 0.4)
	_spot("criee_table_1", 6.0, 11.5, 6.0, 9.0, "debout", "c_criee")
	_spot("criee_table_2", 18.0, 11.5, 18.0, 9.0, "debout", "c_criee")
	_spot("criee_table_3", 30.0, 11.5, 30.0, 9.0, "debout", "c_criee")
	for k3 in range(5):
		_spot("criee_acheteur_%d" % (k3 + 1), 4.0 + k3 * 6.0, 7.6, 4.0 + k3 * 6.0 + 1.0, 10.0, "comptoir", "c_criee")


## Une enseigne peinte de Tazira (texture du dossier tazira/).
func _sign(xf: Transform3D, w: float, h: float, file: String) -> void:
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.05)), Vector3(w * 0.96, h * 0.8, 0.06), "bois_sombre", 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/tazira/" + file + ".png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.roughness = 0.6
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.name = "Enseigne_" + file
	mi.mesh = qm
	mi.material_override = m
	mi.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.01))
	add_child(mi)


## Sur le quai : les grilleurs de sardines, les filets, le chantier des barques, les caisses.
func _quay_life() -> void:
	# trois grills de sardines, leurs fumées, des tables basses
	for k in range(3):
		var gx: float = -34.0 + k * 5.0
		var gxf: Transform3D = TF(gx, 13.0, 0.0)
		kit.box(gxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.8, 0.9, 0.8), "brique", 1.0)
		kit.box(gxf * Transform3D(Basis(), Vector3(0, 0.93, 0)), Vector3(1.6, 0.06, 0.6), "braise_feu", 1.0)
		for f in range(6):
			kit.box(gxf * Transform3D(Basis(), Vector3(-0.6 + f * 0.24, 1.0, 0)), Vector3(0.06, 0.04, 0.42), "poisson", 0.5)
		kit.col_box(gxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.8, 0.9, 0.8))
		var smoke := CPUParticles3D.new()
		smoke.amount = 16 if pc else 8
		smoke.lifetime = 4.0
		smoke.direction = Vector3(0, 1, 0)
		smoke.spread = 12.0
		smoke.initial_velocity_min = 0.6
		smoke.initial_velocity_max = 1.1
		smoke.gravity = Vector3(0.25, 0.15, 0)
		smoke.scale_amount_min = 0.8
		smoke.scale_amount_max = 1.8
		var qm := QuadMesh.new()
		qm.size = Vector2(1.0, 1.0)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.85, 0.85, 0.85, 0.22)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		var tex := GradientTexture2D.new()
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		tex.gradient = g
		sm.albedo_texture = tex
		qm.material = sm
		smoke.mesh = qm
		smoke.position = (gxf * Transform3D(Basis(), Vector3(0, 1.2, 0))).origin
		add_child(smoke)
		_smoke.append(smoke)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.2)
		light.light_energy = 0.6
		light.omni_range = 4.0
		light.position = smoke.position
		add_child(light)
	for k2 in range(4):
		var tx: float = -36.0 + k2 * 4.0
		var txf: Transform3D = TF(tx, 6.5, 0.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.6, 0.06, 0.8), "bois", 1.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.22, 0)), Vector3(0.12, 0.44, 0.12), "bois_sombre", 1.0)
		for s in [-1.0, 1.0]:
			kit.box(txf * Transform3D(Basis(), Vector3(0, 0.22, s * 0.85)), Vector3(1.6, 0.44, 0.34), "bois", 1.0)
		kit.col_box(txf * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(1.6, 0.6, 0.8))
	_spot("grill_1", -29.0, 14.2, -29.0, 12.0, "debout", "c_grill")
	for k3 in range(4):
		_spot("grill_table_%d" % (k3 + 1), -36.0 + k3 * 4.0, 5.65 if k3 % 2 == 0 else 7.35, -36.0 + k3 * 4.0, 6.5, "assis", "c_grill")
	# les tas de filets bleus et orange, les ramendeuses
	for k4 in range(5):
		var nx: float = -76.0 + k4 * 4.2
		var nxf: Transform3D = TF(nx, 12.0 + (k4 % 2) * 2.0, kit.rng.randf() * 360.0)
		kit.cyl(nxf, 1.2, 0.5, 0.7, "tissu_bleu" if k4 % 2 == 0 else "tissu_orange", 10)
		kit.quad(nxf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.72, 0)), 2.2, 2.2, "filet", Vector2(0, 0), Vector2(2, 2), true)
	_spot("quai_filets_1", -74.0, 9.6, -74.0, 12.0, "assis", "c_filets")
	_spot("quai_filets_2", -68.0, 9.4, -68.0, 12.0, "assis", "c_filets")
	_spot("quai_filets_3", -62.0, 9.6, -62.0, 12.0, "assis", "c_filets")
	for k5 in range(3):
		kit.box(TF(-74.0 + k5 * 6.0, 9.2, 0.0, 0.22), Vector3(0.5, 0.44, 0.5), "bois", 1.0)
	# les pêcheurs au travail près des barques, au bord du quai
	for k6 in range(4):
		_spot("quai_barque_%d" % (k6 + 1), -70.0 + k6 * 12.0, 1.6, -70.0 + k6 * 12.0, -4.0, "debout", "")
	_spot("en_mer", -30.0, 1.2, -30.0, -20.0, "en_mer", "")
	_spot("quai_peche_1", -6.0, 1.0, -6.0, -4.0, "assis", "")
	_spot("quai_peche_2", 40.0, 1.0, 40.0, -4.0, "assis", "")
	for k7 in range(4):
		_spot("quai_flane_%d" % (k7 + 1), -50.0 + k7 * 25.0, 6.0, -50.0 + k7 * 25.0, -10.0, "debout", "")
	# les caisses de poisson déchargées (visibles après le retour de la flotte)
	_crates = Node3D.new()
	_crates.name = "Caisses_peche"
	add_child(_crates)
	var cm := BoxMesh.new()
	cm.size = Vector3(0.7, 0.32, 0.5)
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	wood.albedo_color = Color(0.85, 0.7, 0.52)
	var fishm := StandardMaterial3D.new()
	fishm.albedo_color = Color(0.68, 0.74, 0.78)
	fishm.metallic = 0.5
	fishm.roughness = 0.3
	var fm := BoxMesh.new()
	fm.size = Vector3(0.62, 0.05, 0.42)
	for k8 in range(24):
		var cx: float = -60.0 + (k8 % 8) * 6.5 + kit.rng.randf_range(-1.0, 1.0)
		var cz: float = 2.5 + (k8 / 8) * 0.6
		var stack: int = 1 + k8 % 3
		for s2 in range(stack):
			var c := MeshInstance3D.new()
			c.mesh = cm
			c.material_override = wood
			c.position = T(cx, cz, 0.16 + s2 * 0.33)
			c.rotation.y = kit.rng.randf_range(-0.3, 0.3)
			_crates.add_child(c)
			if s2 == stack - 1:
				var f := MeshInstance3D.new()
				f.mesh = fm
				f.material_override = fishm
				f.position = c.position + Vector3.UP * 0.17
				f.rotation.y = c.rotation.y
				_crates.add_child(f)
	# le chantier : une barque sur ses tréteaux, des planches
	var cxf: Transform3D = GF(-110.0, 10.0, 20.0)
	for s3 in [-1.6, 1.6]:
		kit.box(cxf * Transform3D(Basis(), Vector3(s3, 0.5, 0)), Vector3(0.2, 1.0, 1.4), "bois_sombre", 1.0)
	_spot("chantier", -110.0, 8.0, -110.0, 10.0, "debout", "", 0.0, true)
	_spot("plage_barque_1", -128.0, -6.0, -130.0, -12.0, "debout", "", 0.0, true)
	_spot("plage_barque_2", -146.0, -2.0, -148.0, -8.0, "debout", "", 0.0, true)


func _square() -> void:
	var c := Vector2(-20.0, 32.0)
	# la fontaine de zellige : bassin octogonal, vasque, jet d'eau
	var fxf: Transform3D = TF(c.x, c.y, 0.0)
	kit.cyl(fxf, 3.0, 3.0, 0.75, "zellige", 8)
	kit.cyl(fxf * Transform3D(Basis(), Vector3(0, 0.75, 0)), 3.15, 3.15, 0.12, "chaux_blanc", 8)
	kit.disc(fxf * Transform3D(Basis(), Vector3(0, 0.62, 0)), 2.85, "eau", 8)
	kit.cyl(fxf, 0.35, 0.25, 1.6, "zellige", 8)
	kit.cyl(fxf * Transform3D(Basis(), Vector3(0, 1.6, 0)), 0.9, 0.4, 0.3, "chaux_blanc", 12)
	kit.col_cyl(fxf.origin, 3.1, 0.85)
	kit.col_cyl(fxf.origin, 0.9, 1.9)          # V77 : la colonne et la vasque sont solides
	var jet := CPUParticles3D.new()
	jet.amount = 24
	jet.lifetime = 0.9
	jet.direction = Vector3(0, 1, 0)
	jet.spread = 18.0
	jet.initial_velocity_min = 2.0
	jet.initial_velocity_max = 2.6
	jet.gravity = Vector3(0, -9.8, 0)
	jet.scale_amount_min = 0.05
	jet.scale_amount_max = 0.09
	var sp := SphereMesh.new()
	sp.radius = 0.5
	sp.height = 1.0
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.8, 0.9, 1.0, 0.6)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sp.material = wm
	jet.mesh = sp
	jet.position = fxf.origin + Vector3.UP * 1.9
	add_child(jet)
	# des bancs autour de la place, des poufs et des tables basses pour la fête
	for k in range(4):
		var a: float = k * PI * 0.5 + PI * 0.25
		var bp := Vector2(c.x + cos(a) * 7.0, c.y + sin(a) * 7.0)
		kit.bench(TF(bp.x, bp.y, rad_to_deg(-a) + 90.0))
	_spot("place_fontaine_1", c.x + 3.4, c.y, c.x, c.y, "debout", "")
	_spot("place_fontaine_2", c.x - 3.4, c.y + 0.5, c.x, c.y, "debout", "")
	_spot("place_fontaine_3", c.x, c.y - 3.5, c.x, c.y, "debout", "")
	_spot("place_banc_1", c.x + cos(PI * 0.25) * 7.0, c.y + sin(PI * 0.25) * 7.0, c.x, c.y, "assis", "")
	_spot("place_banc_2", c.x + cos(PI * 1.25) * 7.0, c.y + sin(PI * 1.25) * 7.0, c.x, c.y, "assis", "")
	_spot("place_enfants", c.x + 9.0, c.y - 6.0, c.x, c.y, "jouer", "")
	_spot("place_enfants_b", c.x - 9.0, c.y - 5.0, c.x, c.y, "jouer", "")
	# la halqa : le cercle du conteur, un tapis au sol
	kit.box(TF(-34.0, 24.0, 0.0, 0.02), Vector3(2.4, 0.03, 1.6), "tapis_3", 1.0, 4)
	_spot("conteur", -34.0, 24.0, -28.0, 28.0, "assis", "")
	for k2 in range(3):
		var a2: float = PI * 0.15 + k2 * 0.45
		_spot("halqa_%d" % (k2 + 1), -34.0 + cos(a2) * 3.0, 24.0 + sin(a2) * 3.0, -34.0, 24.0, "debout", "")
	# la scène des musiciens (un grand tapis, des poufs), la piste de danse
	kit.box(TF(-20.0, 41.5, 0.0, 0.02), Vector3(6.0, 0.03, 2.4), "tapis_1", 2.0, 4)
	for k3 in range(3):
		var mx: float = -22.2 + k3 * 2.2
		kit.cyl(TF(mx, 41.8, 0.0), 0.32, 0.3, 0.42, "cuir", 10)
		_spot("fete_musicien_%d" % (k3 + 1), mx, 41.8, mx, 34.0, "tambour" if k3 == 1 else "guitare", "")
	for k4 in range(8):
		var a3: float = TAU * k4 / 8.0
		_spot("fete_danse_%d" % (k4 + 1), -20.0 + cos(a3) * 2.4, 37.6 + sin(a3) * 1.6, -20.0, 41.0, "danse", "")
	for k5 in range(6):
		var tx: float = -38.0 + (k5 % 3) * 5.0 if k5 < 3 else -2.0 - (k5 % 3) * 5.0
		var tz: float = 30.0 + (k5 % 3) * 3.0
		var txf: Transform3D = TF(tx, tz, 0.0)
		kit.cyl(txf, 0.6, 0.6, 0.45, "cuivre", 14)
		kit.cyl(txf, 0.08, 0.1, 0.42, "bois_sombre", 8)
		kit.col_cyl(txf.origin, 0.6, 0.5)
		kit.cyl(TF(tx + 1.1, tz, 0.0), 0.3, 0.28, 0.4, "cuir", 10)
		kit.cyl(TF(tx - 1.1, tz, 0.0), 0.3, 0.28, 0.4, "tissu_rouge", 10)
		_spot("fete_table_%d" % (k5 + 1), tx + 1.1, tz, tx, tz, "assis", "")
	# les braseros (allumés le soir)
	for k6 in range(4):
		var bx: float = -36.0 + (k6 % 2) * 32.0
		var bz: float = 23.0 + (k6 / 2) * 18.0
		var bxf: Transform3D = TF(bx, bz, 0.0)
		kit.cyl(bxf, 0.25, 0.45, 0.8, "fer", 10)
		kit.cyl(bxf * Transform3D(Basis(), Vector3(0, 0.8, 0)), 0.45, 0.45, 0.06, "fer", 10)
		kit.col_cyl(bxf.origin, 0.45, 0.9)
		var flame := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.02
		fm.bottom_radius = 0.35
		fm.height = 0.8
		flame.mesh = fm
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(1.0, 0.55, 0.15, 0.9)
		fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fmat.emission_enabled = true
		fmat.emission = Color(1.0, 0.5, 0.15)
		fmat.emission_energy_multiplier = 3.0
		fmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		flame.material_override = fmat
		flame.position = bxf.origin + Vector3.UP * 1.25
		add_child(flame)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.22)
		l.omni_range = 9.0
		l.position = bxf.origin + Vector3.UP * 1.6
		add_child(l)
		_fires.append([l, flame])


func _souk() -> void:
	var xm: float = (SOUK_X0 + SOUK_X1) * 0.5
	# la charpente : des poutres en travers, et les claies de roseaux dessus
	var z: float = SOUK_Z0
	while z <= SOUK_Z1:
		for x in [SOUK_X0, SOUK_X1]:
			kit.box(TF(x, z, 0.0, 1.9), Vector3(0.22, 3.8, 0.22), "bois_sombre", 1.0)
		kit.box(TF(xm, z, 0.0, 3.85), Vector3(SOUK_X1 - SOUK_X0, 0.18, 0.18), "bois_sombre", 1.0)
		z += 3.0
	z = SOUK_Z0
	while z < SOUK_Z1:
		var zb: float = minf(z + 3.0, SOUK_Z1)
		kit.quad4("canisse", T(SOUK_X0, z, 3.95), T(SOUK_X1, z, 3.95), T(SOUK_X1, zb, 3.95), T(SOUK_X0, zb, 3.95), Vector3.UP,
			Vector2(0, 0), Vector2(1.5, 0), Vector2(1.5, 0.75), Vector2(0, 0.75))
		z = zb
	_sign(TF(xm, SOUK_Z0 - 0.2, 0.0, 3.2), 4.0, 2.0, "enseigne_souk")
	var goods := ["epices", "tapis", "lanternes", "poteries", "babouches", "dattes", "cuivre", "tissus"]
	for k in range(8):
		var west: bool = k % 2 == 0
		var sz: float = SOUK_Z0 + 3.5 + (k / 2) * 7.5
		var sx: float = (SOUK_X1 - 0.3) if west else (SOUK_X0 + 0.3)
		# l'étal regarde la ruelle (le client en -Z local) : à l'ouest il regarde vers l'est (x négatif)
		var xf: Transform3D = TF(sx, sz, 90.0 if west else -90.0)
		kit.souk_stall(xf * Transform3D(Basis(), Vector3(0, 0, -1.6)), 4.6, str(goods[k]))
		var seller := Vector2(sx + (0.4 if west else -0.4) * 0.0, sz)
		var face_x: float = xm
		_spot("souk_" + str(goods[k]), seller.x - (0.2 if west else -0.2), seller.y, face_x, sz, "crier", "")
	for k2 in range(5):
		_spot("souk_client_%d" % (k2 + 1), xm + (0.9 if k2 % 2 == 0 else -0.9), SOUK_Z0 + 4.0 + k2 * 6.5, (SOUK_X1 if k2 % 2 == 0 else SOUK_X0), SOUK_Z0 + 4.0 + k2 * 6.5, "debout", "")
	# des lanternes allumées sous les claies
	for k3 in range(6):
		kit.maroc_lantern(TF(xm, SOUK_Z0 + 3.0 + k3 * 5.4, 0.0, 3.8))
		if k3 % 2 == 0 and kit.temps != null:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.68, 0.35)
			l.omni_range = 8.0
			l.position = T(xm, SOUK_Z0 + 3.0 + k3 * 5.4, 2.9)
			add_child(l)
			kit.temps.register_lamp(l, 1.4)


## Les maisons, par îlots, entre les rues : z = 40 (rue des pêcheurs, rue de l'ouest) et
## z = 62 (rue haute), x = -60, x = 30, x = 70 (rues qui montent du quai).
const BLOCKS := [
	# x0, x1, z0, z1, rue (la façade regarde : "s" le quai, "n" la rue haute)
	[-100.0, -63.0, 20.0, 37.0, "s"], [-57.0, -45.0, 20.0, 37.0, "s"],
	[3.0, 27.0, 38.0, 59.0, "s"], [33.0, 67.0, 38.0, 59.0, "s"], [73.0, 100.0, 20.0, 37.0, "s"], [73.0, 100.0, 43.0, 59.0, "s"],
	[-100.0, -63.0, 43.0, 59.0, "s"], [-57.0, -17.0, 47.0, 59.0, "s"],
	[-100.0, -63.0, 65.0, 76.0, "s"], [-57.0, -17.0, 65.0, 76.0, "s"], [3.0, 27.0, 65.0, 76.0, "s"], [33.0, 67.0, 65.0, 76.0, "s"], [73.0, 100.0, 65.0, 76.0, "s"],
	[30.0, 40.0, 20.0, 34.0, "s"], [64.0, 70.0, 20.0, 34.0, "s"],
]


func _houses() -> void:
	var walls := ["chaux_blanc", "chaux_blanc", "chaux_blanc", "chaux_bleu", "chaux_rose", "chaux_ocre", "pise"]
	var doors := ["porte_arc", "porte_arc", "porte_arc", "porte_verte", "porte_brun"]
	var n: int = 0
	var roof_spot := Vector3.INF
	for b in BLOCKS:
		if float(b[0]) == -57.0 and float(b[2]) == 20.0:
			continue
		var x0: float = float(b[0])
		var x1: float = float(b[1])
		var z0: float = float(b[2])
		var z1: float = float(b[3])
		var depth: float = z1 - z0
		# une rangée de maisons sur la rue du bas de l'îlot, une autre dos à dos si l'îlot est profond
		var rows: Array = [[z0, minf(depth, 10.0)]]
		if depth > 14.0:
			rows.append([z0 + 10.5, depth - 10.5])
		for rw in rows:
			var fz: float = float(rw[0])
			var d: float = float(rw[1])
			var x: float = x0
			while x < x1 - 3.0:
				var w: float = minf(kit.rng.randf_range(5.5, 9.0), x1 - x)
				if x1 - (x + w) < 3.5:
					w = x1 - x
				var h: float = kit.rng.randf_range(4.2, 7.5)
				var cx: float = x + w * 0.5
				var xf: Transform3D = TF(cx, fz, 0.0)
				var wall: String = str(walls[kit.rng.randi() % walls.size()])
				var door_x: float = kit.rng.randf_range(-w * 0.25, w * 0.25)
				var door: Vector3 = kit.riad(xf, w - 0.1, d, h, wall, str(doors[kit.rng.randi() % doors.size()]), kit.rng.randf() < 0.3, kit.rng.randf() < 0.35, door_x)
				points["porte_maison_%d" % n] = door
				n += 1
				x += w
	roof_spot = _cat_house()
	objets["carte_tresor"] = roof_spot
	print("ILE_MANGA_V60: %d maisons à Tazira" % n)


## La maison du chat : un îlot entre le quai et la place, avec un escalier de pierre qui monte
## sur la terrasse (et des caisses empilées au pied : le chemin du chat).
func _cat_house() -> Vector3:
	var x0: float = -57.0
	var x1: float = -45.6
	var z0: float = 20.0
	var d: float = 11.0
	var h: float = 4.4
	var w: float = x1 - x0
	var xf: Transform3D = TF((x0 + x1) * 0.5, z0, 0.0)
	var door: Vector3 = kit.riad(xf, w, d, h, "chaux_blanc", "porte_arc", false, true, -2.0)
	points["porte_maison_chat"] = door
	# l'escalier extérieur, le long du mur qui donne sur la place (côté x1)
	var y0: float = R.town_y(x1, z0)
	var run: float = 7.6
	var n: int = 15
	for i in range(n):
		var zc: float = z0 + 1.6 + (i + 0.5) * run / n
		var top: float = (i + 1) * h / n
		var sxf := Transform3D(Basis(Vector3.UP, PI), W(x1 + 0.65, zc, y0 + top * 0.5))
		kit.box(sxf, Vector3(1.3, top, run / n + 0.02), "chaux_ocre", 1.5, 63 - 8)
	# la rampe invisible (on marche dessus), et le palier en haut
	var a: Vector3 = W(x1 + 0.65, z0 + 1.6, y0)
	var bb: Vector3 = W(x1 + 0.65, z0 + 1.6 + run, y0 + h)
	var f: Vector3 = (bb - a).normalized()
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(f).normalized()
	kit.col_box(Transform3D(Basis(side, up, -f), (a + bb) * 0.5 - up * 0.1), Vector3(1.3, 0.2, a.distance_to(bb)))
	var land := Transform3D(Basis(Vector3.UP, PI), W(x1 + 0.65, z0 + 1.6 + run + 0.6, y0 + h - 0.1))
	kit.box(land, Vector3(1.3, 0.2, 1.2), "chaux_ocre", 1.0)
	kit.col_box(land, Vector3(1.3, 0.2, 1.2))
	# des caisses de poisson vides au pied de l'escalier (le chat y saute)
	for k in range(4):
		kit.crate(T(x1 + 2.2 + (k % 2) * 0.8, z0 + 1.2 + (k / 2) * 0.8), 0.2 * k, 0.75, true)
	kit.crate(T(x1 + 2.6, z0 + 1.6, 0.75), 0.4, 0.7, true)
	return W(x0 + 2.5, z0 + d - 2.5, y0 + h + 0.15)


func _ramparts() -> void:
	var h: float = 7.5
	var t: float = 2.4
	var zn: float = 79.4
	var xs: float = 104.6
	# le rempart du nord, la porte (Bab el-Bahr) dans l'axe du souk
	var gate_x: float = (SOUK_X0 + SOUK_X1) * 0.5
	for sg in [[-xs, gate_x - 3.0], [gate_x + 3.0, xs]]:
		var a: float = float(sg[0])
		var b: float = float(sg[1])
		var xf: Transform3D = TF((a + b) * 0.5, zn, 0.0, h * 0.5 - 1.0)
		kit.box(xf, Vector3(b - a, h + 2.0, t), "pise", 4.0)
		kit.col_box(xf, Vector3(b - a, h + 2.0, t))
		kit.merlons(TF((a + b) * 0.5, zn - t * 0.4, 0.0, 0.0), b - a, h - 1.0 + R.town_y((a + b) * 0.5, zn) - R.town_y((a + b) * 0.5, zn), 0.5, "pise")
	var gxf: Transform3D = TF(gate_x, zn, 0.0, 0.0)
	kit.box(gxf * Transform3D(Basis(), Vector3(0, h - 1.5, 0)), Vector3(6.0, 3.0, t), "pise", 3.0)
	kit.col_box(gxf * Transform3D(Basis(), Vector3(0, h - 1.5, 0)), Vector3(6.0, 3.0, t))
	for s in [-1.0, 1.0]:
		kit.box(gxf * Transform3D(Basis(), Vector3(s * 4.5, h * 0.5 + 0.5, 0)), Vector3(3.2, h + 3.0, t + 1.2), "pise", 3.0)
		kit.col_box(gxf * Transform3D(Basis(), Vector3(s * 4.5, h * 0.5 + 0.5, 0)), Vector3(3.2, h + 3.0, t + 1.2))
	# l'arc de la porte, souligné de zellige
	for i in range(12):
		var ang: float = lerpf(-0.2, PI + 0.2, (i + 0.5) / 12.0)
		kit.box(gxf * Transform3D(Basis(Vector3(0, 0, 1), ang), Vector3(cos(ang) * 3.0, 4.6 + sin(ang) * 3.0, -t * 0.5 - 0.05)), Vector3(0.35, 0.9, 0.12), "zellige", 0.6)
	# les remparts est et ouest
	for side in [-1.0, 1.0]:
		var zg: float = 30.0
		for sg2 in [[14.0, zg - 2.5], [zg + 2.5, zn]]:
			var za: float = float(sg2[0])
			var zb: float = float(sg2[1])
			var xf2: Transform3D = TF(side * xs, (za + zb) * 0.5, 90.0, h * 0.5 - 1.0)
			kit.box(xf2, Vector3(zb - za, h + 2.0, t), "pise", 4.0)
			kit.col_box(xf2, Vector3(zb - za, h + 2.0, t))
		var lxf: Transform3D = TF(side * xs, zg, 90.0, 0.0)
		kit.box(lxf * Transform3D(Basis(), Vector3(0, h - 1.5, 0)), Vector3(5.0, 3.0, t), "pise", 3.0)
	# les tours carrées aux angles et de part et d'autre de la porte du nord
	for tp in [Vector2(-xs, zn), Vector2(xs, zn), Vector2(-xs, 14.0), Vector2(xs, 14.0), Vector2(-50.0, zn), Vector2(50.0, zn)]:
		var txf: Transform3D = TF(tp.x, tp.y, 0.0, 0.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, (h + 3.0) * 0.5 - 1.0, 0)), Vector3(6.0, h + 5.0, 6.0), "pise", 4.0)
		kit.col_box(txf * Transform3D(Basis(), Vector3(0, (h + 3.0) * 0.5 - 1.0, 0)), Vector3(6.0, h + 5.0, 6.0))
		kit.merlons(txf * Transform3D(Basis(), Vector3(0, 0, -2.9)), 6.0, h + 3.0, 0.3, "pise")


func _fondouk() -> void:
	var xf: Transform3D = TF(16.0, 21.0, 0.0)
	kit.riad(xf, 18.0, 14.0, 7.5, "chaux_ocre", "porte_verte", true, false, 0.0)
	_sign(xf * Transform3D(Basis(), Vector3(0, 3.5, -0.15)), 3.6, 1.8, "enseigne_fondouk")
	points["porte_fondouk"] = xf * Vector3(0, 0, -1.0)
	# la terrasse de thé devant : tables basses de cuivre, poufs
	for k in range(3):
		var tx: float = 9.0 + k * 7.0
		var txf: Transform3D = TF(tx, 18.6, 0.0)
		kit.cyl(txf, 0.5, 0.5, 0.42, "cuivre", 14)
		kit.col_cyl(txf.origin, 0.5, 0.45)
		kit.cyl(TF(tx + 0.9, 18.6, 0.0), 0.28, 0.26, 0.4, "cuir", 10)
		kit.cyl(TF(tx - 0.9, 18.6, 0.0), 0.28, 0.26, 0.4, "tissu_bleu", 10)
		kit.cyl(txf * Transform3D(Basis(), Vector3(0, 0.42, 0)), 0.08, 0.06, 0.18, "chrome", 8)
		_spot("fondouk_terrasse_%d" % (k + 1), tx + 0.9, 18.6, tx, 18.6, "assis", "")
	_spot("fondouk_porte", 19.0, 19.6, 19.0, 15.0, "debout", "")
	kit.maroc_lantern(xf * Transform3D(Basis(), Vector3(-2.2, 3.0, -0.4)))
	kit.maroc_lantern(xf * Transform3D(Basis(), Vector3(2.2, 3.0, -0.4)))


## La Murène Ivre : la taverne des pirates, où l'on entre (comptoir, tables, tonneaux).
func _murene() -> void:
	var r: Rect2 = MURENE
	var cx: float = r.position.x + r.size.x * 0.5
	var z0: float = r.position.y
	var d: float = r.size.y
	var w: float = r.size.x
	var h: float = 4.2
	var t: float = 0.4
	var y0: float = R.town_y(cx, z0)
	var b := Basis(Vector3.UP, PI)
	var o: Vector3 = W(cx, z0, y0)
	var xf := Transform3D(b, o)
	var door_w: float = 2.0
	# façade (deux pans et le linteau), côtés, fond
	for s in [-1.0, 1.0]:
		var pw: float = (w - door_w) * 0.5
		var c := Vector3(s * (door_w * 0.5 + pw * 0.5), h * 0.5, t * 0.5)
		kit.box(xf * Transform3D(Basis(), c), Vector3(pw, h, t), "pise_sombre", 3.0)
		kit.col_box(xf * Transform3D(Basis(), c), Vector3(pw, h, t))
		kit.box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d), "pise_sombre", 3.0)
		kit.col_box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - t * 0.5), h * 0.5, d * 0.5)), Vector3(t, h, d))
	kit.box(xf * Transform3D(Basis(), Vector3(0, h - 0.6, t * 0.5)), Vector3(door_w, 1.2, t), "pise_sombre", 3.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t), "pise_sombre", 3.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, d - t * 0.5)), Vector3(w, h, t))
	kit.box(xf * Transform3D(Basis(), Vector3(0, h + 0.15, d * 0.5)), Vector3(w + 0.4, 0.3, d + 0.4), "pise_sombre", 3.0)
	kit.merlons(xf * Transform3D(Basis(), Vector3(0, 0, 0.1)), w, h + 0.3, 0.3, "pise_sombre")
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.05, d * 0.5)), Vector3(w - 2 * t, 0.1, d - 2 * t), "planches", 2.0, 4)
	kit.box(xf * Transform3D(Basis(), Vector3(0, h - 0.05, d * 0.5)), Vector3(w - 2 * t, 0.1, d - 2 * t), "bois_sombre", 2.0, 8)
	for k in range(int(w / 2.5)):
		kit.box(xf * Transform3D(Basis(), Vector3(-w * 0.5 + 1.2 + k * 2.5, h - 0.25, d * 0.5)), Vector3(0.2, 0.25, d - 2 * t), "bois_sombre", 1.0)
	_sign(xf * Transform3D(Basis(), Vector3(0, h - 0.4, -0.12)), 3.2, 1.6, "enseigne_murene")
	# le comptoir au fond, les étagères, les tonneaux de rhum
	var bx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0, d - 3.0))
	kit.box(bx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(8.0, 1.1, 0.8), "bois_sombre", 1.2)
	kit.box(bx * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(8.2, 0.07, 0.95), "bois", 1.2)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(8.0, 1.1, 0.8))
	for k2 in range(2):
		kit.box(bx * Transform3D(Basis(), Vector3(0, 1.6 + k2 * 0.6, 2.2)), Vector3(7.0, 0.05, 0.35), "bois_sombre", 1.0)
		for j in range(12):
			kit.cyl(bx * Transform3D(Basis(), Vector3(-3.2 + j * 0.58, 1.63 + k2 * 0.6, 2.2)), 0.06, 0.05, 0.3, "bouteille", 8)
	for k3 in range(4):
		kit.barrel(xf * Vector3(-w * 0.5 + 1.0, 0.1, 2.0 + k3 * 1.0))
	# les tables, les bancs, une carte marine clouée au mur, des filets
	var tables := [Vector2(-5.0, 4.0), Vector2(5.0, 4.0), Vector2(-5.0, 8.0), Vector2(5.0, 8.0)]
	for i in range(tables.size()):
		var tp: Vector2 = tables[i]
		var txf: Transform3D = xf * Transform3D(Basis(), Vector3(tp.x, 0.1, tp.y))
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(2.4, 0.08, 1.0), "bois", 1.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.38, 0)), Vector3(0.14, 0.76, 0.14), "bois_sombre", 1.0)
		for s2 in [-1.0, 1.0]:
			kit.box(txf * Transform3D(Basis(), Vector3(0, 0.44, s2 * 0.85)), Vector3(2.2, 0.07, 0.34), "bois_sombre", 1.0)
		kit.col_box(txf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.4, 0.8, 1.0))
		kit.ship_lantern(txf * Transform3D(Basis(), Vector3(0, 3.0, 0)))
		_spot_w("murene_table_%d" % (i + 1), txf * Vector3(0.4, 0.0, -0.85), txf * Vector3(0.4, 0, 0), "assis", "m_in")
	kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2.4, d - t - 0.02)), 2.4, 1.6, "carte")
	kit.quad(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(w * 0.5 - t - 0.02, 2.4, d * 0.5)), 3.0, 1.6, "filet", Vector2(0, 0), Vector2(2, 1), true)
	for k4 in range(4):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.66, 0.36)
		l.light_energy = 1.8
		l.omni_range = 8.0
		l.position = xf * Vector3(-5.0 + (k4 % 2) * 10.0, h - 1.0, 3.5 + (k4 / 2) * 6.0)
		add_child(l)
	# l'ambiance intérieure (lumière chaude des lanternes, pas le ciel bleu du dehors)
	var pr := ReflectionProbe.new()
	pr.name = "Ambiance_murene"
	pr.size = Vector3(w - 0.6, h - 0.2, d - 0.6)
	pr.interior = true
	pr.update_mode = ReflectionProbe.UPDATE_ONCE
	pr.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	pr.ambient_color = Color(0.55, 0.38, 0.24)
	pr.ambient_color_energy = 0.55
	pr.intensity = 0.6
	pr.max_distance = 40.0
	pr.blend_distance = 1.0
	pr.transform = Transform3D(b, xf * Vector3(0, h * 0.5, d * 0.5))
	add_child(pr)
	points["m_porte"] = xf * Vector3(0, 0.05, -1.4)
	points["m_in"] = xf * Vector3(0, 0.1, 2.0)
	points["m_fond"] = xf * Vector3(0, 0.1, d - 5.0)
	_spot_w("murene_comptoir", xf * Vector3(0, 0.1, d - 2.0), xf * Vector3(0, 0.1, d - 5.0), "comptoir", "m_fond")
	_spot_w("murene_bar_1", xf * Vector3(-1.5, 0.1, d - 3.9), xf * Vector3(-1.5, 0.1, d - 3.0), "boire", "m_fond")
	_spot_w("murene_bar_2", xf * Vector3(1.5, 0.1, d - 3.9), xf * Vector3(1.5, 0.1, d - 3.0), "boire", "m_fond")
	points["porte_murene"] = xf * Vector3(w * 0.5 - 2.0, 0.1, d - 2.0)


## La passerelle du quai au pont du galion.
func _gangplank() -> void:
	var top: Vector3 = ship.W(Vector3(0.0, ship.deck_y(0.0), -4.6))
	var low: Vector3 = T(SHIP_X, 1.6)
	var dir: Vector3 = top - low
	var f: Vector3 = dir.normalized()
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(f).normalized()
	var gx := Transform3D(Basis(side, up, -f), (top + low) * 0.5)
	kit.box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(1.6, 0.1, dir.length() + 0.4), "pont", 1.0)
	kit.col_box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(1.6, 0.12, dir.length() + 0.4))
	for s in [-1.0, 1.0]:
		kit.box(gx * Transform3D(Basis(), Vector3(s * 0.8, 0.9, 0)), Vector3(0.05, 0.05, dir.length()), "corde", 1.0)
		kit.col_box(gx * Transform3D(Basis(), Vector3(s * 0.85, 0.5, 0)), Vector3(0.1, 1.0, dir.length()))
	walk_boxes.append([gx.affine_inverse(), Vector3(1.0, 3.0, dir.length() * 0.5 + 0.6)])
	points["n_quai"] = low
	points["n0"] = top + Vector3.UP * 0.05
	kit.commit()


# =================================================================== les barques

## Une barque de Tazira : coque fine, étrave haute, bleue, liston rouge, filet jaune.
func _barque_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L: float = 6.2
	var beam: float = 1.9
	var depth: float = 0.85
	var n: int = 14
	var rings: Array = []
	for i in range(n + 1):
		var t: float = float(i) / n
		var x: float = (t - 0.5) * L
		var w: float = beam * 0.5 * pow(maxf(0.0, 1.0 - pow(absf(t - 0.42) * 1.72, 2.2)), 0.55)
		var rise: float = pow(maxf(0.0, t - 0.75) / 0.25, 2.0) * 0.55 + pow(maxf(0.0, 0.12 - t) / 0.12, 2.0) * 0.2
		var ring: Array = []
		for k in range(9):
			var a: float = PI * float(k) / 8.0
			ring.append([Vector3(x, depth + rise - sin(a) * depth, cos(a) * w), float(k) / 8.0])
		rings.append(ring)
	for i in range(n):
		for k in range(8):
			var a0: Vector3 = rings[i][k][0]
			var a1: Vector3 = rings[i][k + 1][0]
			var b0: Vector3 = rings[i + 1][k][0]
			var b1: Vector3 = rings[i + 1][k + 1][0]
			var va: float = absf(float(rings[i][k][1]) - 0.5) * -2.0 + 1.0
			var vb: float = absf(float(rings[i][k + 1][1]) - 0.5) * -2.0 + 1.0
			var ua: float = float(i) / n * 2.0
			var ub: float = float(i + 1) / n * 2.0
			var nrm: Vector3 = Vector3(0, -sin(PI * (k + 0.5) / 8.0), cos(PI * (k + 0.5) / 8.0))
			var tri_pts := [[a0, Vector2(ua, va)], [b0, Vector2(ub, va)], [b1, Vector2(ub, vb)], [a0, Vector2(ua, va)], [b1, Vector2(ub, vb)], [a1, Vector2(ua, vb)]]
			if ((b0 - a0).cross(b1 - a0)).dot(nrm) < 0.0:
				tri_pts = [tri_pts[0], tri_pts[2], tri_pts[1], tri_pts[3], tri_pts[5], tri_pts[4]]
			for v in tri_pts:
				st.set_uv(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, kit.mat("barque"))
	# les bancs et le mât court (une seconde surface en bois)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for bx in [-1.4, 0.0, 1.4]:
		_boxst(st2, Vector3(bx, depth * 0.62, 0), Vector3(0.3, 0.06, beam * 0.8))
	_boxst(st2, Vector3(L * 0.5 - 0.15, depth + 0.85, 0), Vector3(0.12, 0.5, 0.12))
	_boxst(st2, Vector3(-0.6, depth + 0.3, 0), Vector3(0.1, 1.6, 0.1))
	st2.generate_normals()
	st2.commit(mesh)
	mesh.surface_set_material(1, kit.mat("bois_sombre"))
	return mesh


func _boxst(st: SurfaceTool, c: Vector3, s: Vector3) -> void:
	var h: Vector3 = s * 0.5
	var k := [c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z), c + Vector3(h.x, h.y, -h.z), c + Vector3(-h.x, h.y, -h.z),
		c + Vector3(-h.x, -h.y, h.z), c + Vector3(h.x, -h.y, h.z), c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)]
	for f in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 4, 7, 3], [1, 2, 6, 5], [3, 7, 6, 2], [0, 1, 5, 4]]:
		for idx in [f[0], f[1], f[2], f[0], f[2], f[3]]:
			st.set_uv(Vector2((k[idx] as Vector3).x, (k[idx] as Vector3).z))
			st.add_vertex(k[idx])


func _boats() -> void:
	_boat_mesh = _barque_mesh()
	# au mouillage : quatre rangées, l'étrave vers le quai
	for row in range(4):
		for col in range(8):
			var x: float = -78.0 + col * 7.0 + (row % 2) * 2.5
			var z: float = -5.0 - row * 9.0
			if x > 34.0 or absf(x - DOCK_X) < 5.0:
				continue
			_moored_xf.append([Vector2(x, z), _rng.randf_range(-0.12, 0.12), _rng.randf() * TAU])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _boat_mesh
	mm.instance_count = _moored_xf.size()
	_moored = MultiMeshInstance3D.new()
	_moored.name = "Barques_au_mouillage"
	_moored.multimesh = mm
	add_child(_moored)
	_update_moored(0.0)
	# sur la plage : tirées sur le sable, un peu penchées
	var beach := MultiMesh.new()
	beach.transform_format = MultiMesh.TRANSFORM_3D
	beach.mesh = _boat_mesh
	var bx: Array = []
	for k in range(11):
		var x: float = -118.0 - k * 6.2
		var z: float = -4.0 + (k % 3) * 4.0
		var w: Vector3 = G(x, z, -0.2)
		var b := Basis(Vector3.UP, PI * 0.5 + _rng.randf_range(-0.25, 0.25)).rotated(Vector3(0, 0, 1), 0.0)
		b = b * Basis(Vector3(1, 0, 0), _rng.randf_range(0.18, 0.3))
		bx.append(Transform3D(b, w))
	beach.instance_count = bx.size()
	for i in range(bx.size()):
		beach.set_instance_transform(i, bx[i])
	var bmi := MultiMeshInstance3D.new()
	bmi.name = "Barques_sur_la_plage"
	bmi.multimesh = beach
	add_child(bmi)
	# la flotte qui sort à l'aube : six barques, chacune son heure
	for i in range(6):
		var node := MeshInstance3D.new()
		node.name = "Barque_peche_%d" % i
		node.mesh = _boat_mesh
		add_child(node)
		var moor := Vector2(-70.0 + i * 13.0, -38.0 - (i % 2) * 5.0)
		var lane_x: float = 6.0 + (i - 2.5) * 3.0
		var path: Array = [moor, Vector2(lane_x, -60.0), Vector2(lane_x, -108.0), Vector2(lane_x + (i - 2.5) * 12.0, -170.0), Vector2(lane_x + (i - 2.5) * 30.0, -260.0)]
		_fleet.append({"node": node, "dep": 5.0 + i * 0.22, "ret": 9.6 + i * 0.25, "path": path, "ph": _rng.randf() * TAU})


func _update_moored(t: float) -> void:
	var mm: MultiMesh = _moored.multimesh
	for i in range(_moored_xf.size()):
		var e: Array = _moored_xf[i]
		var p: Vector2 = e[0]
		var ph: float = float(e[2])
		var w: Vector3 = W(p.x, p.y, -0.42 - 0.25 + sin(t * 0.9 + ph) * 0.06)
		var b := Basis(Vector3.UP, PI * 0.5 + float(e[1])) * Basis(Vector3(1, 0, 0), sin(t * 0.7 + ph) * 0.04)
		mm.set_instance_transform(i, Transform3D(b, w))


## Position d'une barque de la flotte selon l'heure : au mouillage, en mer, ou en route.
func _fleet_pose(f: Dictionary, h: float) -> Array:
	var path: Array = f["path"]
	var dep: float = float(f["dep"])
	var ret: float = float(f["ret"])
	var go_t: float = clampf((h - dep) / 1.4, 0.0, 1.0)
	var back_t: float = clampf((h - ret) / 1.2, 0.0, 1.0)
	var s: float = go_t
	var visible_: bool = true
	if h >= ret:
		s = 1.0 - back_t
	if h < dep or h > ret + 1.2:
		s = 0.0
	if s >= 0.999:
		visible_ = false
	# la distance le long du chemin
	var total: float = 0.0
	for i in range(path.size() - 1):
		total += (path[i] as Vector2).distance_to(path[i + 1])
	var want: float = total * s
	var acc: float = 0.0
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var L: float = a.distance_to(b)
		if acc + L >= want:
			var p: Vector2 = a.lerp(b, (want - acc) / maxf(L, 0.01))
			var dir: Vector2 = (b - a).normalized() * (1.0 if h < ret or h < dep else -1.0)
			return [p, dir, visible_]
		acc += L
	return [path[path.size() - 1], Vector2(0, -1), visible_]


func _palms() -> void:
	var jf = JungleFlora.new()
	var mesh: ArrayMesh = jf.palm_mesh(1, pc)
	jf.free()
	var xfs: Array = []
	for x in [-80.0, -56.0, -44.0, -8.0, 44.0, 84.0]:
		xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.05)), T(x, 16.6, -0.1)))
	for p in [Vector2(-40.0, 22.0), Vector2(-1.0, 22.0), Vector2(-40.0, 43.0), Vector2(-1.0, 43.0)]:
		xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.1)), T(p.x, p.y, -0.1)))
	for k in range(8):
		var bx: float = -100.0 - k * 9.0
		xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.1)), G(bx, 20.0 + (k % 2) * 6.0, -0.1)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Palmiers_Tazira"
	mmi.multimesh = mm
	add_child(mmi)


# =================================================================== la fête du soir

func _fete_build() -> void:
	# des guirlandes de lanternes en travers de la place, entre des mâts
	var poles := [Vector2(-41.0, 21.0), Vector2(-41.0, 43.0), Vector2(1.0, 21.0), Vector2(1.0, 43.0), Vector2(-20.0, 21.0), Vector2(-20.0, 45.0)]
	for p in poles:
		kit.box(TF(p.x, p.y, 0.0, 2.5), Vector3(0.14, 5.0, 0.14), "bois_sombre", 1.0)
	var strings := [[0, 3], [1, 2], [4, 5], [0, 2], [1, 3]]
	var bulbs: Array = []
	for s in strings:
		var a: Vector3 = T(poles[s[0]].x, poles[s[0]].y, 4.9)
		var b: Vector3 = T(poles[s[1]].x, poles[s[1]].y, 4.9)
		var n: int = int(a.distance_to(b) / 1.2)
		var prev := Vector3.INF
		for i in range(n + 1):
			var t: float = float(i) / n
			var q: Vector3 = a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * 1.4
			bulbs.append(q + Vector3.DOWN * 0.12)
			if prev != Vector3.INF:
				var f: Vector3 = (q - prev).normalized()
				var side: Vector3 = f.cross(Vector3.UP).normalized()
				kit.box(Transform3D(Basis(side, f.cross(side).normalized(), -f), (q + prev) * 0.5), Vector3(0.02, 0.02, prev.distance_to(q)), "fer", 0.3)
			prev = q
	kit.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.075
	sm.height = 0.19
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = bulbs.size()
	for i in range(bulbs.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), bulbs[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Guirlandes"
	mmi.multimesh = mm
	mmi.material_override = kit.mat("guirlande")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	for k in range(4 if pc else 2):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.4)
		l.omni_range = 14.0
		l.light_energy = 0.0
		l.position = T(-30.0 + k * 7.0, 32.0, 4.0)
		add_child(l)
		_fete_lights.append(l)
	# la musique de la fête, jouée sur la place (on l'entend en s'approchant)
	_music = AudioStreamPlayer3D.new()
	_music.name = "Musique_fete"
	var path := "res://assets/sons/musique/tazira_fete.ogg"
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_music.stream = stream
	_music.max_distance = 70.0
	_music.unit_size = 14.0
	_music.volume_db = -4.0
	_music.bus = "Musique" if AudioServer.get_bus_index("Musique") >= 0 else "Master"
	_music.position = T(-20.0, 41.5, 1.6)
	add_child(_music)


# =================================================================== les bêtes : mouettes et chats

func _make_gulls() -> void:
	var body_m := StandardMaterial3D.new()
	body_m.albedo_color = Color(0.96, 0.96, 0.95)
	var wing_m := StandardMaterial3D.new()
	wing_m.albedo_color = Color(0.8, 0.82, 0.84)
	wing_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(18 if pc else 10):
		var g := Node3D.new()
		g.name = "Mouette_tz_%d" % i
		var b := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		b.mesh = sm
		b.scale = Vector3(0.8, 0.8, 2.2)
		b.material_override = body_m
		g.add_child(b)
		var wings: Array = []
		for s in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(s * 0.08, 0.04, -0.04)
			g.add_child(pivot)
			var w := MeshInstance3D.new()
			var bx := BoxMesh.new()
			bx.size = Vector3(0.66, 0.015, 0.2)
			w.mesh = bx
			w.material_override = wing_m
			w.position = Vector3(s * 0.33, 0, 0)
			pivot.add_child(w)
			wings.append(pivot)
		add_child(g)
		var center: Vector3 = W(_rng.randf_range(-80.0, 60.0), _rng.randf_range(-60.0, 10.0), 0.0)
		_gulls.append({"node": g, "wings": wings, "c": center, "r": _rng.randf_range(8.0, 28.0), "h": _rng.randf_range(6.0, 20.0), "a": _rng.randf() * TAU,
			"w": _rng.randf_range(0.2, 0.4) * (1.0 if i % 2 == 0 else -1.0), "ph": _rng.randf() * TAU})


func _make_cats() -> void:
	var cols := [Color(0.9, 0.62, 0.3), Color(0.2, 0.18, 0.17), Color(0.85, 0.83, 0.8), Color(0.55, 0.5, 0.45), Color(0.9, 0.62, 0.3), Color(0.35, 0.3, 0.26), Color(0.95, 0.94, 0.92)]
	var homes := [Vector2(-30.0, 10.0), Vector2(-26.0, 12.0), Vector2(14.0, 9.0), Vector2(-20.0, 26.0), Vector2(-60.0, 12.0), Vector2(-8.0, 50.0), Vector2(50.0, 17.0)]
	for i in range(cols.size()):
		var m := StandardMaterial3D.new()
		m.albedo_color = cols[i]
		m.roughness = 0.9
		var cat := Node3D.new()
		cat.name = "Chat_%d" % i
		var body := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.11
		sm.height = 0.22
		body.mesh = sm
		body.scale = Vector3(1.0, 1.0, 2.0)
		body.position = Vector3(0, 0.2, 0)
		body.material_override = m
		cat.add_child(body)
		var head := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.08
		hs.height = 0.16
		head.mesh = hs
		head.position = Vector3(0, 0.3, -0.24)
		head.material_override = m
		cat.add_child(head)
		for s in [-1.0, 1.0]:
			var ear := MeshInstance3D.new()
			var em := CylinderMesh.new()
			em.top_radius = 0.0
			em.bottom_radius = 0.035
			em.height = 0.07
			ear.mesh = em
			ear.position = Vector3(s * 0.045, 0.38, -0.24)
			ear.material_override = m
			cat.add_child(ear)
		var tail := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.015
		tm.bottom_radius = 0.025
		tm.height = 0.3
		tail.mesh = tm
		tail.position = Vector3(0, 0.32, 0.26)
		tail.rotation.x = -0.7
		tail.material_override = m
		cat.add_child(tail)
		for lx in [-0.05, 0.05]:
			for lz in [-0.14, 0.14]:
				var leg := MeshInstance3D.new()
				var lm := CylinderMesh.new()
				lm.top_radius = 0.02
				lm.bottom_radius = 0.02
				lm.height = 0.16
				leg.mesh = lm
				leg.position = Vector3(lx, 0.08, lz)
				leg.material_override = m
				cat.add_child(leg)
		add_child(cat)
		var home: Vector2 = homes[i]
		cat.position = T(home.x, home.y)
		_cats.append({"node": cat, "home": home, "target": home, "wait": _rng.randf_range(1.0, 6.0), "tail": tail})


func _tick_cats(delta: float) -> void:
	for c in _cats:
		var n: Node3D = c["node"]
		var tgt: Vector2 = c["target"]
		var t: Vector2 = R.to_town(n.position.x, n.position.z)
		var to: Vector2 = tgt - t
		if to.length() < 0.2:
			c["wait"] = float(c["wait"]) - delta
			if float(c["wait"]) <= 0.0:
				var h: Vector2 = c["home"]
				c["target"] = h + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-4.0, 4.0))
				c["wait"] = _rng.randf_range(3.0, 12.0)
			(c["tail"] as Node3D).rotation.z = sin(_clock * 2.0 + n.position.x) * 0.4
			continue
		var step: Vector2 = to.normalized() * minf(to.length(), delta * 0.9)
		t += step
		var w: Vector3 = R.to_world(t.x, t.y)
		w.y = maxf(ile.height(w.x, w.z), R.QUAY_Y) if t.y > 0.0 else ile.height(w.x, w.z)
		n.position = w
		var wdir := Vector3(-to.x, 0, -to.y)
		if wdir.length() > 0.01:
			n.rotation.y = atan2(-wdir.x, -wdir.z)
		(c["tail"] as Node3D).rotation.z = sin(_clock * 6.0) * 0.25


# =================================================================== habitants : lieux et chemins

func _spot(name: String, x: float, z: float, fx: float, fz: float, pose: String, node: String, dy: float = 0.0, ground: bool = false) -> void:
	var pos: Vector3 = G(x, z, dy) if ground else T(x, z, dy)
	var face: Vector3 = G(fx, fz) if ground else T(fx, fz)
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _spot_w(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _p(name: String, x: float, z: float) -> void:
	points[name] = T(x, z)


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
		_link(names[i], names[i + 1])


func _street(prefix: String, a: Vector2, b: Vector2, step: float) -> Array:
	var names: Array = []
	var n: int = maxi(1, int(a.distance_to(b) / step))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / n)
		var nm: String = "%s%d" % [prefix, i]
		_p(nm, p.x, p.y)
		names.append(nm)
	_chain(names)
	return names


func _nearest(p: Vector3, prefixes: Array) -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		var ks: String = str(k)
		if ks.begins_with("@") or ks.begins_with("porte"):
			continue
		var ok: bool = prefixes.is_empty()
		for pf in prefixes:
			if ks.begins_with(str(pf)):
				ok = true
		if not ok:
			continue
		var d: float = (points[k] as Vector3).distance_to(p) + absf((points[k] as Vector3).y - p.y) * 4.0
		if d < bd:
			bd = d
			best = ks
	return best


func _graph() -> void:
	# le quai (deux lignes : le bord et le long des façades)
	var quai: Array = _street("q", Vector2(-84.0, 5.5), Vector2(90.0, 5.5), 8.0)
	var _quai_haut: Array = _street("qh", Vector2(-84.0, 16.4), Vector2(90.0, 16.4), 8.0)
	for i in range(0, quai.size(), 3):
		_link(str(quai[i]), _nearest(points[quai[i]], ["qh"]))
	# les rues de la ville
	var east: Array = _street("re", Vector2(-100.0, 40.5), Vector2(-17.0, 40.5), 8.0)
	# V77 : la rue de l'ouest passe entre les îlots (elle traversait les maisons de z 38 à 59)
	var west: Array = _street("rw", Vector2(0.0, 36.0), Vector2(70.5, 36.0), 8.0)
	var west2: Array = _street("rwb", Vector2(72.0, 40.0), Vector2(100.0, 40.0), 8.0)
	_link(str(west[west.size() - 1]), str(west2[0]))
	var high: Array = _street("rh", Vector2(-100.0, 62.0), Vector2(100.0, 62.0), 8.0)
	var x_rues := [-60.0, 30.0, 70.0]
	for xr in x_rues:
		var r: Array = _street("rx%d_" % int(xr), Vector2(xr, 17.0), Vector2(xr, 62.0), 7.0)
		_link(str(r[0]), _nearest(points[r[0]], ["qh"]))
		_link(str(r[r.size() - 1]), _nearest(points[r[r.size() - 1]], ["rh"]))
		var mid: Vector3 = T(xr, 40.0)
		_link(_nearest(mid, ["rx%d_" % int(xr)]), _nearest(mid, ["re", "rw"]))
	# la place
	_p("pl0", -20.0, 22.0); _p("pl1", -32.0, 26.0); _p("pl2", -8.0, 26.0); _p("pl3", -32.0, 38.0); _p("pl4", -8.0, 38.0); _p("pl5", -20.0, 44.5)
	_chain(["pl0", "pl1", "pl3", "pl5", "pl4", "pl2", "pl0"])
	_link("pl0", _nearest(T(-20.0, 16.4), ["qh"]))
	_link("pl5", _nearest(T(-20.0, 40.5), ["re"]))
	_link("pl4", _nearest(T(0.0, 40.0), ["rw"]))
	_link(str(east[east.size() - 1]), "pl3")
	# le souk (dans l'axe, jusqu'à la porte du nord)
	var souk: Array = _street("sk", Vector2(-8.0, 46.0), Vector2(-8.0, 76.5), 5.0)
	_link("pl5", str(souk[0]))
	_link(_nearest(T(-8.0, 62.0), ["sk"]), _nearest(T(-8.0, 62.0), ["rh"]))
	_p("bab", -8.0, 83.0)
	_link(str(souk[souk.size() - 1]), "bab")
	# la plage (par la porte de l'est) et le chantier
	points["pg0"] = G(-112.0, 30.0)
	points["pg1"] = G(-112.0, 12.0)
	points["pg2"] = G(-132.0, 0.0)
	points["pg3"] = G(-148.0, 4.0)
	_chain(["pg3", "pg2", "pg1", "pg0"])
	_link("pg0", _nearest(T(-100.0, 40.5), ["re"]))
	_link("pg1", _nearest(T(-84.0, 5.5), ["q"]))
	# la Skala (la rampe monte du bout du quai)
	points["sa0"] = G(98.0, 6.0)
	points["sa1"] = G(110.0, -10.0)
	points["sa2"] = G(124.0, -40.0)
	points["sa3"] = G(120.0, -62.0)
	_chain(["sa0", "sa1", "sa2", "sa3"])
	_link("sa0", _nearest(T(90.0, 5.5), ["q"]))
	_spot("skala_garde", 118.0, -60.0, 118.0, -90.0, "bras_croises", "sa3", 0.0, true)
	_spot("skala_vue_1", 132.0, -40.0, 160.0, -40.0, "comptoir", "sa2", 0.0, true)
	_spot("skala_vue_2", 104.0, -66.0, 104.0, -100.0, "comptoir", "sa3", 0.0, true)
	_spot("skala_peindre", 126.0, -30.0, 150.0, -60.0, "peindre", "sa2", 0.0, true)
	# la jetée de l'est (on y pêche à la ligne)
	points["ja0"] = W(-87.0, -8.0, JETTY_Y)
	points["ja1"] = W(-87.0, -50.0, JETTY_Y)
	points["ja2"] = W(-87.0, -92.0, JETTY_Y)
	_chain(["ja0", "ja1", "ja2"])
	_link("ja0", _nearest(T(-84.0, 5.5), ["q"]))
	_spot_w("jetee_peche_1", W(-85.6, -50.0, JETTY_Y), W(-60.0, -50.0, JETTY_Y), "assis", "ja1")
	_spot_w("jetee_peche_2", W(-85.6, -86.0, JETTY_Y), W(-60.0, -86.0, JETTY_Y), "assis", "ja2")
	# le galion : la passerelle et le pont
	_link("n_quai", _nearest(points["n_quai"], ["q"]))
	_link("n_quai", "n0")
	points["n1"] = ship.deck_at(-6.0, 0.0)
	points["n2"] = ship.deck_at(8.0, 0.0)
	points["n3"] = ship.deck_at(-9.5, 2.3)
	points["n4"] = ship.deck_at(-17.0, 0.0)
	points["n5"] = ship.deck_at(11.0, 0.0)
	points["n6"] = ship.deck_at(18.0, 0.0)
	_chain(["n0", "n1", "n3"])
	_chain(["n0", "n2", "n5", "n6"])
	_link("n3", "n4")
	points["porte_navire"] = ship.deck_at(-12.4, 0.0)
	_link("porte_navire", "n1")
	_spot_w("navire_capitaine", ship.deck_at(-18.5, -1.0), ship.deck_at(-30.0, -1.0), "bras_croises", "n4")
	_spot_w("navire_barre", ship.deck_at(-17.6, 0.0), ship.deck_at(-16.0, 0.0), "debout", "n4")
	_spot_w("navire_pont_1", ship.deck_at(2.0, 2.4), ship.deck_at(2.0, 5.0), "comptoir", "n2")
	_spot_w("navire_pont_2", ship.deck_at(-4.0, -2.5), ship.deck_at(-4.0, 0.0), "debout", "n1")
	_spot_w("navire_pont_3", ship.deck_at(6.4, -3.0), ship.deck_at(6.0, -3.6), "assis", "n2")
	_spot_w("navire_vigie", ship.deck_at(19.0, 0.0), ship.deck_at(40.0, 0.0), "bras_croises", "n6")
	# la taverne des pirates
	_link("m_porte", _nearest(points["m_porte"], ["qh"]))
	_chain(["m_porte", "m_in", "m_fond"])
	_link("porte_murene", "m_fond")
	# le Fondouk
	_link("porte_fondouk", _nearest(points["porte_fondouk"], ["qh"]))
	# des nœuds techniques pour les lieux du quai
	_p("c_criee", 18.0, 1.8)
	_link("c_criee", _nearest(points["c_criee"], ["q"]))
	_p("c_grill", -29.0, 9.6)
	_link("c_grill", _nearest(points["c_grill"], ["q"]))
	_p("c_filets", -68.0, 7.6)
	_link("c_filets", _nearest(points["c_filets"], ["q"]))
	# les portes des maisons : reliées à la rue la plus proche
	for k in points.keys():
		var ks: String = str(k)
		if ks.begins_with("porte_maison_"):
			_link(ks, _nearest(points[ks], ["q", "re", "rw", "rh", "rx", "pl", "sk"]))
	# chaque lieu d'activité a son point « @nom »
	for s in spots:
		var nm: String = "@" + str(s)
		points[nm] = spots[s]["pos"]
		var near: String = str(spots[s]["node"])
		if near == "" or not points.has(near):
			near = _nearest(spots[s]["pos"], [])
		_link(nm, near)
		spots[s]["node"] = nm


# =================================================================== la vie du port

func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var near: bool = Vector2(p.x - R.ORIGIN.x, p.z - R.ORIGIN.z).length() < 420.0
	var h: float = hour()
	if near:
		_update_moored(_clock)
		for f in _fleet:
			var pose: Array = _fleet_pose(f, h)
			var mi: MeshInstance3D = f["node"]
			var tp: Vector2 = pose[0]
			var dir: Vector2 = pose[1]
			mi.visible = bool(pose[2])
			var w: Vector3 = W(tp.x, tp.y, -0.67 + sin(_clock * 0.9 + float(f["ph"])) * 0.06)
			var wd := Vector3(-dir.x, 0, -dir.y)
			mi.global_transform = Transform3D(Basis(Vector3.UP, atan2(-wd.z, wd.x)) * Basis(Vector3(1, 0, 0), sin(_clock * 0.7 + float(f["ph"])) * 0.04), w)
		_tick_gulls(delta)
		_tick_cats(delta)
	# les caisses de poisson : sur le quai du retour de la flotte jusqu'à la fin de la criée
	_crates.visible = h >= 10.6 and h < 15.0
	# la fête : de 19 h à minuit et demi
	var on: bool = h >= 19.0 or h < 0.5
	if on != fete_on:
		fete_on = on
		for l in _fete_lights:
			(l as OmniLight3D).light_energy = 1.6 if on else 0.0
		if _music != null and _music.stream != null:
			if on:
				_music.play()
			else:
				_music.stop()
	var night: bool = main.get("temps_v56") != null and main.temps_v56 != null and bool(main.temps_v56.lamps_on)
	for fr in _fires:
		var l2: OmniLight3D = fr[0]
		l2.light_energy = (1.6 + 0.5 * sin(_clock * 9.0 + l2.position.x) * sin(_clock * 13.0)) if (night or on) else 0.0
		(fr[1] as MeshInstance3D).visible = night or on
	fete_heard = on and _music != null and _music.playing and p.distance_to(_music.global_position) < 60.0
	if fete_heard and p.distance_to(_music.global_position) < 25.0:
		state["fete"] = true
	if not bool(state["visite"]) and zone_at(p) != "" and R.to_town(p.x, p.z).y > -2.0:
		state["visite"] = true
		main._show_message_v28("Tazira, le port des sables — la criée, le souk, et la Murène Noire à quai")
	if ship != null:
		ship.set_night(night)


func _tick_gulls(delta: float) -> void:
	for g in _gulls:
		var n: Node3D = g["node"]
		g["a"] = float(g["a"]) + delta * float(g["w"])
		var a: float = float(g["a"])
		var c: Vector3 = g["c"]
		var pos := Vector3(c.x + cos(a) * float(g["r"]), float(g["h"]) + sin(a * 2.3 + float(g["ph"])) * 1.5, c.z + sin(a) * float(g["r"]))
		var nxt := Vector3(c.x + cos(a + 0.05 * signf(float(g["w"]))) * float(g["r"]), pos.y, c.z + sin(a + 0.05 * signf(float(g["w"]))) * float(g["r"]))
		n.global_position = pos
		n.look_at(nxt, Vector3.UP)
		var flap: float = sin(_clock * 6.0 + float(g["ph"])) * 0.5 if fmod(_clock + float(g["ph"]), 6.0) < 2.0 else 0.08
		(g["wings"][0] as Node3D).rotation.z = flap
		(g["wings"][1] as Node3D).rotation.z = -flap


## Le joueur est-il sur une construction de Tazira (jetées, passerelle) ou à bord du galion ?
func on_structure(p: Vector3) -> bool:
	if ship != null and ship.aboard(p):
		return true
	for wb in walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.0 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


func blocks_boat(p: Vector3) -> bool:
	if ship != null and ship.blocks_boat(p):
		return true
	var t: Vector2 = R.to_town(p.x, p.z)
	for jp in [JETTY_A, JETTY_B]:
		for i in range(jp.size() - 1):
			var a: Vector2 = jp[i]
			var b: Vector2 = jp[i + 1]
			var ab: Vector2 = b - a
			var q: Vector2 = a + ab * clampf((t - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			if t.distance_to(q) < 6.0:
				return true
	return false


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var t: Vector2 = R.to_town(p.x, p.z)
	if ship != null and ship.aboard(p):
		return "tazira_navire"
	if t.x > MURENE.position.x and t.x < MURENE.end.x and t.y > MURENE.position.y and t.y < MURENE.end.y and p.y < R.town_y(t.x, t.y) + 4.0:
		return "tazira_murene"
	if t.x > SOUK_X0 - 1.0 and t.x < SOUK_X1 + 1.0 and t.y > SOUK_Z0 and t.y < SOUK_Z1:
		return "tazira_souk"
	if t.x > SQUARE.position.x and t.x < SQUARE.end.x and t.y > SQUARE.position.y and t.y < SQUARE.end.y + 2.0:
		return "tazira_place"
	if t.y < 19.0 or t.x < -104.0 or t.x > 104.0:
		if ile.height(p.x, p.z) < -0.42 and not on_structure(p):
			return "" if t.y < -110.0 else "tazira_port"
		return "tazira_port"
	if t.y < 80.0:
		return "tazira_ville"
	return ""


# =================================================================== les habitants (agenda)

const Habitants = preload("res://scripts/pnj/tazira_habitants_v60.gd")
const PnjTazira = preload("res://scripts/pnj/pnj_tazira_v60.gd")

var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "nuits": 0, "fete": false}
var _claims: Dictionary = {}


func spot(name: String) -> Dictionary:
	return spots.get(name, {})


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty():
		return
	for data in Habitants.all_profiles():
		var start: String = "pl0"
		var home: String = str(data.get("maison", ""))
		if points.has(home):
			start = home
		var npc: Node3D = PnjTazira.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V60: %d habitants à Tazira" % habitants.size())


## La barque accoste au bout du quai, côté plage (devant les ramendeuses).
func dock() -> Array:
	return boat_dock


func respawn_point() -> Array:
	var at: Vector3 = T(-20.0, 16.0)
	return [at + Vector3.UP * 0.3, (T(-20.0, 30.0) - at).normalized()]


## Services : une chambre au Fondouk (Zineb) ; les objets de quête dans le monde.
func register_services(journal: Node) -> void:
	journal.add_service("zineb", Callable(self, "_inn_topics"), Callable(self, "_inn_choose"))
	for k in objets:
		journal.lieux[k] = objets[k]


func _inn_topics(_npc: Node) -> Array:
	var h: float = hour()
	var night: bool = h >= 18.0 or h < 6.0
	return [{"id": "q56:service:fondouk", "label": "☾ %s (8 pièces)" % ("Une chambre sur la terrasse pour la nuit" if night else "Une sieste au frais jusqu'au soir")}]


func _inn_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 8:
		return {"texte": "Huit pièces la chambre, thé du matin compris. Les caravaniers paient en dattes ; toi, tu n'as même pas de dattes.", "geste": "parle"}
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return {"texte": ("La chambre de la terrasse. Laisse la fenêtre ouverte : tu t'endormiras avec la fête, et tu te réveilleras avec les mouettes." if night else "Une sieste ? Les murs sont épais, il fait frais. Je te réveille pour le thé du soir."),
		"geste": "salut", "fin": true, "prendre": [["piece", 8]], "_fondouk": 7.0 if night else 18.5}


func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_fondouk"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_fondouk"]))


func trouvailles() -> Dictionary:
	return {"tazira": 1 if bool(state["visite"]) else 0, "tazira_fete": 1 if bool(state["fete"]) else 0}


func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "nuits": int(d.get("nuits", 0)), "fete": bool(d.get("fete", false))}
	_claims.clear()
	for n in habitants:
		n.slot = -2

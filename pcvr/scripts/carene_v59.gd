extends Node3D
## V59 : Carène, le port bâti dans l'épave du Léviathan.
##  - la cale : le Marché de la Cale (étals sous des toiles taillées dans les vieilles voiles),
##    on y entre de plain-pied par la brèche de la plage ; au-delà, la cale noyée est
##    devenue le bassin : pontons flottants, barques amarrées ;
##  - l'entrepont : les logis (cabines de planches), La Forge du Canon (un vieux canon
##    devenu foyer), l'atelier du calfat, l'infirmerie, les hamacs de l'auberge, les canons ;
##  - le pont : les cabanes, la voilerie, la cloche, la place devant la taverne, la proue
##    du guetteur ; à la poupe, La Dernière Bordée (dans le château) et la capitainerie
##    (au-dessus, sur la dunette) ;
##  - dehors : la passerelle de la brèche, la plage (la barque retournée de Fañch, les
##    filets qui sèchent, le feu de camp), le grand ponton le long du flanc nord et le
##    ponton de la barque du joueur.
## Tout ce qui est à bord est posé dans le repère du navire (epave_v59.gd) : x vers
## l'étrave, y vers le haut, z vers tribord (le sud).
## Les habitants : points du graphe (points, graph) et lieux d'activité (spots), comme à
## Port-Azur (pnj_azur_v56.gd).

const Kit = preload("res://scripts/carene_kit_v59.gd")
const PIER_Y: float = 1.0
const PIER_Z: float = -24.5           # le grand ponton, le long du flanc nord (repère du navire)
const PIER_X0: float = 24.0
const PIER_X1: float = -30.0
const DOCK_X1: float = -56.0          # le ponton de la barque, au bout
const PONT_Y: float = 0.3             # les pontons flottants du bassin (monde)

var main: Node
var E: Node3D                         # epave_v59.gd
var ile: Node3D                       # grande_ile_v59.gd
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var boat_dock: Array = []             # [début, fin] du ponton de la barque du joueur
var gangway: Array = []               # [haut (dans la cale), bas (sur la plage)] monde
var lights_inside: Array = []         # [OmniLight3D, énergie, scintillement]
var forge_light: OmniLight3D
var fire_light: OmniLight3D
var fire_mat: StandardMaterial3D
var boats: Array = []                 # [Node3D, phase, y]
var walk_boxes: Array = []            # [Transform3D inverse, demi-taille] : pontons, passerelle
var bell_pos := Vector3.ZERO
var _clock: float = 0.0


# =================================================================== repères

func L(x: float, y: float, z: float) -> Vector3:
	return E.W(Vector3(x, y, z))


func lv(level: String, x: float) -> float:
	match level:
		"H":
			return E.HOLD_Y
		"G":
			return E.GUN_Y
		"D":
			return E.deck_y(x) if x > E.CASTLE_X else E.D
		"T":
			return E.D
		"Q":
			return E.QD_Y
		"P":
			return E.PD_Y
	return 0.0


## Repère d'un objet à bord : rot en degrés autour de l'axe vertical du navire
## (0 : l'objet « regarde » -Z, vers bâbord / le nord ; 180 : vers tribord / le sud ;
## -90 : vers l'étrave ; 90 : vers la poupe).
func TF(x: float, level: String, z: float, rot: float = 0.0, dy: float = 0.0) -> Transform3D:
	return Transform3D(E.xf.basis * Basis(Vector3.UP, deg_to_rad(rot)), L(x, lv(level, x) + dy, z))


## Repère d'un objet à terre (vertical), à la hauteur du sol (ou à y si donné).
func TW(x: float, z: float, rot: float = 0.0, y: float = INF) -> Transform3D:
	var w: Vector3 = L(x, 0.0, z)
	w.y = ile.height(w.x, w.z) if y == INF else y
	return Transform3D(Basis(Vector3.UP, E.yaw + deg_to_rad(rot)), w)


func ground(x: float, z: float) -> Vector3:
	var w: Vector3 = L(x, 0.0, z)
	w.y = ile.height(w.x, w.z)
	return w


func pier(x: float, z: float = PIER_Z) -> Vector3:
	var w: Vector3 = L(x, 0.0, z)
	w.y = PIER_Y
	return w


func pontoon(x: float, z: float) -> Vector3:
	var w: Vector3 = L(x, 0.0, z)
	w.y = PONT_Y
	return w


# =================================================================== construction

func build(main_node: Node, wreck: Node3D, island: Node3D, high_quality: bool) -> void:
	main = main_node
	E = wreck
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 5990
	_hold_market()
	_basin()
	_gun_deck()
	_main_deck()
	_tavern()
	_capitainerie()
	_railings()
	_outside()
	_interior_probes()
	kit.commit()
	_graph()
	print("ILE_MANGA_V59: Carène, %d lieux, %d points, %d lumières à bord, en %d ms" % [spots.size(), points.size(), lights_inside.size(), Time.get_ticks_msec() - t0])


func _light(p: Vector3, color: Color, energy: float, rng_m: float, flicker: float = 0.0, only_pc: bool = false) -> OmniLight3D:
	if only_pc and not pc:
		return null
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	l.position = p
	add_child(l)
	lights_inside.append([l, energy, flicker])
	return l


## Une lanterne suspendue à bord, avec sa lumière (toujours allumée : il fait sombre dedans).
func _hang_lantern(x: float, level: String, z: float, drop: float, energy: float = 1.3, only_pc: bool = false) -> void:
	var top_y: float = lv(level, x)
	kit.ship_lantern(TF(x, level, z, 0.0, drop))
	var ceiling: float = 7.38 if drop > 0.0 else -0.12
	kit.cyl(TF(x, level, z, 0.0, drop), 0.012, 0.012, ceiling - drop, "corde", 4, false)
	_light(L(x, top_y + drop - 0.5, z), Color(1.0, 0.72, 0.42), energy * 1.4, 11.0, 0.08, only_pc)


# =================================================================== la cale : le marché

func _hold_market() -> void:
	# l'étal de Salomé, face à la brèche
	kit.stall(TF(36.0, "H", -1.2, 0.0), 3.2, "toile_rouge", "bric")
	kit.carene_sign(TF(36.0, "H", -1.0, 0.0, 3.0), 2.2, 0.85, "enseigne_cale", true)
	# les autres étals
	kit.stall(TF(24.0, "H", -7.2, 180.0), 2.8, "toile_bleue", "poisson")
	kit.stall(TF(16.5, "H", -6.6, 180.0), 2.4, "toile_rouge", "cordes")
	kit.stall(TF(45.0, "H", 3.0, 0.0), 2.2, "toile_bleue", "fruits")
	kit.stall(TF(24.0, "H", 3.4, 0.0), 2.6, "toile_rouge", "bric")
	# caisses, tonneaux, filets
	for p in [[30.0, -8.6], [31.2, -8.0], [12.0, 5.5], [12.4, 6.6], [48.0, -4.6], [40.0, 5.6]]:
		kit.crate(L(p[0], E.HOLD_Y, p[1]), kit.rng.randf() * 1.2, kit.rng.randf_range(0.6, 0.85))
	for p2 in [[29.0, 7.6], [33.5, -6.0], [11.8, -3.5], [12.4, -2.5], [50.0, 2.0]]:
		kit.barrel(L(p2[0], E.HOLD_Y, p2[1]))
	# lanternes
	for lp in [[22.0, 0.0], [36.0, -4.0], [46.0, 0.0], [14.0, 2.0]]:
		_hang_lantern(lp[0], "H", lp[1], 3.2, 1.6, lp[0] == 14.0)
	# le bord du quai, au-dessus du bassin
	for zq in [-6.0, -2.0, 2.0, 6.0]:
		kit.bollard(L(_quay_x(zq) + 0.6, E.HOLD_Y, zq))
	_spot("cale_comptoir", 36.0, "H", 0.35, 36.0, -3.0, "debout", "h1")
	_spot("cale_etal_poisson", 24.0, "H", -8.4, 24.0, -4.0, "debout", "h2")
	_spot("cale_flane_1", 30.0, "H", -2.5, 28.0, -7.0, "debout", "h2")
	_spot("cale_flane_2", 21.0, "H", 1.0, 24.0, 4.0, "debout", "h3")
	_spot("cale_flane_3", 42.5, "H", 0.6, 45.0, 3.0, "debout", "h5")


# =================================================================== le bassin

## Le bord du quai (le plancher sec de la cale) à cette distance de l'axe.
func _quay_x(z: float) -> float:
	var x: float = -40.0
	while x < 40.0 and E.hold_flooded(x, z):
		x += 0.25
	return x


func _basin() -> void:
	# le ponton flottant, le long du flanc nord, du quai jusqu'à la poupe
	var qx: float = _quay_x(-7.5)
	var x0: float = qx - 1.2
	var x1: float = -50.0
	var zc: float = -7.5
	var bas := Basis(Vector3.UP, E.yaw)
	var a: Vector3 = pontoon(x0, zc)
	var b: Vector3 = pontoon(x1, zc)
	var mid: Vector3 = (a + b) * 0.5
	var length: float = a.distance_to(b)
	var xf := Transform3D(bas * Basis(Vector3.UP, PI * 0.5), mid + Vector3.DOWN * 0.1)
	kit.box(xf, Vector3(2.2, 0.2, length), "pont", 1.2)
	kit.col_box(xf, Vector3(2.2, 0.2, length))
	walk_boxes.append([xf.affine_inverse(), Vector3(1.4, 2.5, length * 0.5 + 0.5)])
	var s: float = 0.0
	while s < length:
		var p: Vector3 = a.lerp(b, s / length)
		for side in [-1.0, 1.0]:
			kit.cyl(Transform3D(bas, p + bas * Vector3(0, 0, side * 1.0) + Vector3.DOWN * 0.55), 0.22, 0.22, 0.4, "goudron", 10)
		s += 3.0
	# deux pontons en travers
	for xc in [-14.0, -34.0]:
		var c0: Vector3 = pontoon(xc, zc + 1.1)
		var c1: Vector3 = pontoon(xc, 2.0)
		var cm: Vector3 = (c0 + c1) * 0.5
		var cl: float = c0.distance_to(c1)
		var xf2 := Transform3D(bas, cm + Vector3.DOWN * 0.1)
		kit.box(xf2, Vector3(1.6, 0.2, cl), "pont", 1.2)
		kit.col_box(xf2, Vector3(1.6, 0.2, cl))
		walk_boxes.append([xf2.affine_inverse(), Vector3(1.1, 2.5, cl * 0.5 + 0.3)])
	# du quai au ponton : une petite rampe
	var q: Vector3 = L(qx + 0.9, E.HOLD_Y, zc)
	var pq: Vector3 = pontoon(qx - 1.2, zc)
	var rm: Vector3 = (q + pq) * 0.5
	var dir: Vector3 = pq - q
	var f: Vector3 = dir.normalized()
	var side_v: Vector3 = f.cross(Vector3.UP).normalized()
	var up: Vector3 = side_v.cross(f).normalized()
	var xr := Transform3D(Basis(side_v, up, -f), rm + Vector3.DOWN * 0.08)
	kit.box(xr, Vector3(1.8, 0.14, dir.length() + 0.4), "pont", 1.0)
	kit.col_box(xr, Vector3(1.8, 0.14, dir.length() + 0.4))
	walk_boxes.append([xr.affine_inverse(), Vector3(1.2, 2.5, dir.length() * 0.5 + 0.6)])
	# les barques amarrées
	var spots_b := [[-6.0, -3.0, 0.2], [-22.0, -3.4, -0.15], [-40.0, -2.6, 0.1], [-26.0, 6.5, 3.0], [-44.0, 7.0, 3.3]]
	for i in range(spots_b.size()):
		var bp: Array = spots_b[i]
		var w: Vector3 = L(float(bp[0]), 0.0, float(bp[1]))
		w.y = -0.42 + 0.05
		var boat := _skiff(i)
		boat.position = w
		boat.rotation.y = E.yaw + PI * 0.5 + float(bp[2])
		add_child(boat)
		boats.append([boat, float(i) * 1.7, w.y])
	_hang_lantern(-10.0, "G", -6.0, -1.0, 1.4)
	_hang_lantern(-32.0, "G", -6.0, -1.0, 1.2, true)
	_spot_w("bassin_ponton_1", pontoon(-14.0, -0.6) + Vector3.UP * 0.0, pontoon(-14.0, 6.0), "assis", "b1")
	_spot_w("bassin_ponton_2", pontoon(-26.0, -6.6), pontoon(-26.0, -2.0), "debout", "b2")
	_spot_w("bassin_barque", pontoon(-38.0, -6.6), pontoon(-40.0, -2.6), "debout", "b3")
	# un banc pour s'asseoir au bout du ponton en travers
	kit.box(Transform3D(bas, pontoon(-14.0, -0.6) + Vector3.UP * 0.22), Vector3(1.2, 0.08, 0.4), "bois_sombre", 1.0)


## Une petite barque de pêche (coque bordée, bancs, avirons).
func _skiff(variant: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Barque_carene_%d" % variant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = 4.4 + (variant % 3) * 0.5
	var beam: float = 1.5
	var depth: float = 0.7
	var n: int = 12
	var rings: Array = []
	for i in range(n + 1):
		var t: float = float(i) / n
		var x: float = (t - 0.5) * length
		var w: float = beam * 0.5 * pow(maxf(0.0, 1.0 - pow(absf(t - 0.45) * 2.0, 2.4)), 0.6)
		var ring: Array = []
		for k in range(7):
			var a: float = PI * float(k) / 6.0
			ring.append(Vector3(x, depth * 0.55 - sin(a) * depth * 0.8 + (pow(absf(t - 0.5) * 2.0, 3.0) * 0.35), cos(a) * w))
		rings.append(ring)
	var paint: Array = [Color(0.15, 0.3, 0.45), Color(0.55, 0.15, 0.1), Color(0.2, 0.38, 0.25), Color(0.85, 0.8, 0.7), Color(0.25, 0.22, 0.2)]
	for i in range(n):
		for k in range(6):
			var a0: Vector3 = rings[i][k]
			var a1: Vector3 = rings[i][k + 1]
			var b0: Vector3 = rings[i + 1][k]
			var b1: Vector3 = rings[i + 1][k + 1]
			var nrm: Vector3 = Vector3(0, -sin(PI * (k + 0.5) / 6.0), cos(PI * (k + 0.5) / 6.0))
			for side in [1.0, -1.0]:
				var tri_pts := [a0, b0, b1, a0, b1, a1]
				var want: Vector3 = nrm
				var flip: bool = ((b0 - a0).cross(b1 - a0)).dot(want) > 0.0
				if flip:
					tri_pts = [a0, b1, b0, a0, a1, b1]
				for v in tri_pts:
					st.set_uv(Vector2((v as Vector3).x * 0.4, float(k) / 6.0))
					st.add_vertex(v)
				# le dedans (même géométrie, face vers l'intérieur)
				var inner := []
				for v2 in tri_pts:
					inner.append(v2)
				inner.reverse()
				for v3 in inner:
					st.set_uv(Vector2((v3 as Vector3).x * 0.4, float(k) / 6.0))
					st.add_vertex(v3)
				break
	st.generate_normals()
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/carene/bordage.png")
	m.albedo_color = paint[variant % paint.size()].lightened(0.2)
	m.roughness = 0.75
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	root.add_child(mi)
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/textures/carene/pont.png")
	wood.roughness = 0.85
	for bx in [-0.8, 0.5]:
		var seat := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.3, 0.05, beam * 0.85)
		seat.mesh = sm
		seat.material_override = wood
		seat.position = Vector3(bx, depth * 0.3, 0)
		root.add_child(seat)
	for s in [-1.0, 1.0]:
		var oar := MeshInstance3D.new()
		var om := BoxMesh.new()
		om.size = Vector3(2.6, 0.05, 0.1)
		oar.mesh = om
		oar.material_override = wood
		oar.position = Vector3(0.0, depth * 0.45, s * 0.3)
		oar.rotation.y = s * 0.12
		root.add_child(oar)
	return root


# =================================================================== l'entrepont

func _gun_deck() -> void:
	# les logis du nord (portes vers le milieu du navire)
	for i in range(3):
		var x: float = 19.0 + i * 7.0
		var door: Vector3 = kit.shack(TF(x, "G", -10.9, 180.0), 6.2, 3.2, 2.6, "cabane_sombre", 0.0, true)
		points["porte_logis_%d" % (i + 1)] = TF(x, "G", -10.9, 180.0) * door
	# les logis du sud
	for i in range(3):
		var x2: float = -26.0 + i * 7.0
		var door2: Vector3 = kit.shack(TF(x2, "G", 10.9, 0.0), 6.2, 3.2, 2.6, "cabane_sombre", 0.0, true)
		points["porte_logis_%d" % (i + 4)] = TF(x2, "G", 10.9, 0.0) * door2
	# La Forge du Canon : un vieux canon ouvert, rempli de briques et de braises
	var fx: Transform3D = TF(45.0, "G", -9.2, 0.0)
	kit.box(fx * Transform3D(Basis(), Vector3(0, 0.45, 0.0)), Vector3(2.6, 0.9, 1.6), "brique", 1.2)
	kit.col_box(fx * Transform3D(Basis(), Vector3(0, 0.5, 0.0)), Vector3(2.6, 1.0, 1.6))
	kit.cyl(fx * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(1.6, 1.15, 0.0)), 0.5, 0.36, 3.4, "canon", 16)
	kit.box(fx * Transform3D(Basis(), Vector3(0, 0.93, -0.1)), Vector3(1.6, 0.06, 0.9), "braise", 1.0)
	kit.cyl(fx * Transform3D(Basis(), Vector3(-0.6, 0.9, 0.3)), 0.32, 0.12, 1.5, "fer", 10)
	kit.cyl(fx * Transform3D(Basis(), Vector3(-0.6, 2.4, 0.3)), 0.14, 0.14, 5.0, "fer", 8)
	# l'enclume et le billot
	var ax: Transform3D = TF(43.6, "G", -6.4, 0.0)
	kit.cyl(ax, 0.32, 0.36, 0.65, "bois_sombre", 12)
	kit.box(ax * Transform3D(Basis(), Vector3(0, 0.78, 0)), Vector3(0.75, 0.26, 0.3), "canon", 0.6)
	kit.box(ax * Transform3D(Basis(), Vector3(0.48, 0.84, 0)), Vector3(0.3, 0.12, 0.16), "canon", 0.6)
	kit.col_cyl(ax.origin, 0.4, 0.9)
	kit.carene_sign(TF(45.0, "G", -5.5, 0.0, 3.1), 1.9, 0.75, "enseigne_forge", true)
	forge_light = _light(L(45.0, E.GUN_Y + 1.6, -8.0), Color(1.0, 0.5, 0.18), 2.4, 8.0, 0.35)
	_spot("forge", 44.6, "G", -5.6, 43.6, -6.4, "debout", "g2")
	# l'atelier du calfat : établi, planches, tonneaux de brai, chaudron
	var cx: Transform3D = TF(54.0, "G", 6.4, 180.0)
	kit.box(cx * Transform3D(Basis(), Vector3(0, 0.85, 0.5)), Vector3(2.6, 0.08, 0.8), "bois", 1.0)
	for sx in [-1.2, 1.2]:
		kit.box(cx * Transform3D(Basis(), Vector3(sx, 0.42, 0.5)), Vector3(0.1, 0.84, 0.7), "bois_sombre", 1.0)
	kit.col_box(cx * Transform3D(Basis(), Vector3(0, 0.45, 0.5)), Vector3(2.6, 0.9, 0.8))
	for k in range(5):
		kit.box(cx * Transform3D(Basis(Vector3(1, 0, 0), 0.25), Vector3(-1.0 + k * 0.4, 1.35, -0.6)), Vector3(0.3, 2.7, 0.04), "pont", 1.0)
	for bpos in [Vector3(2.1, 0, 0.6), Vector3(2.4, 0, -0.3)]:
		kit.barrel(cx * bpos, true)
		kit.disc(cx * Transform3D(Basis(), bpos + Vector3(0, 0.91, 0)), 0.3, "goudron", 12)
	kit.cyl(cx * Transform3D(Basis(), Vector3(-2.2, 0, -0.2)), 0.45, 0.5, 0.6, "fer", 14)
	kit.disc(cx * Transform3D(Basis(), Vector3(-2.2, 0.6, -0.2)), 0.42, "goudron", 14)
	_spot("calfat_atelier", 54.0, "G", 4.9, 54.0, 6.5, "debout", "g3")
	# l'infirmerie d'Anouk : un lit, une étagère de bocaux, des herbes qui sèchent
	var ix: Transform3D = TF(-36.0, "G", 11.0, 0.0)
	kit.box(ix * Transform3D(Basis(), Vector3(-1.2, 0.35, 1.2)), Vector3(1.0, 0.12, 2.1), "bois", 1.0)
	kit.box(ix * Transform3D(Basis(), Vector3(-1.2, 0.47, 1.2)), Vector3(0.92, 0.12, 2.0), "tissu_blanc", 1.0)
	kit.col_box(ix * Transform3D(Basis(), Vector3(-1.2, 0.3, 1.2)), Vector3(1.0, 0.6, 2.1))
	for k2 in range(3):
		kit.box(ix * Transform3D(Basis(), Vector3(1.4, 0.6 + k2 * 0.55, 2.0)), Vector3(1.8, 0.05, 0.4), "bois", 1.0)
		for j in range(5):
			kit.cyl(ix * Transform3D(Basis(), Vector3(0.7 + j * 0.33, 0.63 + k2 * 0.55, 2.0)), 0.07, 0.07, 0.2, "bouteille", 8)
	for k3 in range(6):
		kit.box(ix * Transform3D(Basis(), Vector3(-1.5 + k3 * 0.6, 2.6, 0.6)), Vector3(0.12, 0.5, 0.12), "herbes", 0.5)
	kit.box(ix * Transform3D(Basis(), Vector3(0.0, 2.9, 0.6)), Vector3(4.0, 0.04, 0.04), "corde", 1.0)
	_spot("infirmerie", -36.0, "G", 9.6, -35.0, 12.2, "debout", "g_s3")
	# les hamacs de l'auberge, à l'arrière de l'entrepont
	for k4 in range(6):
		var hx: float = -46.0 - k4 * 3.0
		for hz in [-6.0, 6.0]:
			var ya: float = E.GUN_Y + 2.6
			kit.hammock(L(hx, ya, hz - 2.0 * signf(hz)), L(hx, ya, hz + 2.0 * signf(hz)), 0.7, "toile_rouge" if (k4 + int(hz > 0)) % 2 == 0 else "toile_bleue")
	var tx: Transform3D = TF(-52.0, "G", 0.0, 0.0)
	kit.box(tx * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(2.4, 0.08, 1.1), "bois", 1.0)
	kit.cyl(tx, 0.08, 0.08, 0.72, "bois_sombre", 8)
	kit.col_box(tx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.4, 0.8, 1.1))
	for bz in [-1.0, 1.0]:
		kit.box(tx * Transform3D(Basis(), Vector3(0, 0.45, bz)), Vector3(2.4, 0.07, 0.35), "bois_sombre", 1.0)
	_spot("entrepont_banc_1", -51.5, "G", -1.0, -51.5, 0.0, "assis", "g_s4")
	_spot("entrepont_banc_2", -52.5, "G", 1.0, -52.5, 0.0, "assis", "g_s4")
	# les canons, le long des flancs, là où il n'y a ni logis ni atelier
	for cxp in [-60.0, -44.0, -2.0, 6.0, 40.0]:
		for side in [-1.0, 1.0]:
			if cxp == 40.0 and side < 0.0:
				continue
			var w: float = E.hb_in(cxp, E.GUN_Y) - 3.0
			kit.cannon(TF(cxp, "G", side * w, 0.0 if side < 0.0 else 180.0))
	# lanternes
	for lp in [[30.0, 0.0], [12.0, -7.0], [-10.0, 6.0], [-28.0, 0.0], [-50.0, -3.0], [52.0, 0.0]]:
		_hang_lantern(lp[0], "G", lp[1], 3.6, 1.3, lp[0] == 12.0 or lp[0] == -28.0)


# =================================================================== le pont

func _main_deck() -> void:
	# la voilerie de Nolwenn (ouverte devant, une voile en travail sur le pont)
	var vx: Transform3D = TF(24.0, "D", -8.6, 180.0)
	var door1: Vector3 = kit.shack(vx, 6.0, 2.8, 2.6, "toile_bleue", 1.6, false)
	points["porte_cabane_1"] = vx * door1
	kit.carene_sign(vx * Transform3D(Basis(), Vector3(-1.2, 2.9, -0.1)), 1.8, 0.7, "enseigne_voilerie")
	var sail_xf: Transform3D = TF(24.0, "D", -5.0, 0.0, 0.03)
	kit.quad4("voile", sail_xf * Vector3(-2.2, 0, -1.2), sail_xf * Vector3(2.2, 0, -1.2), sail_xf * Vector3(2.2, 0, 1.0), sail_xf * Vector3(-2.2, 0, 1.0),
		E.xf.basis * Vector3.UP, Vector2(0.1, 0.5), Vector2(0.6, 0.5), Vector2(0.6, 0.95), Vector2(0.1, 0.95))
	kit.box(TF(21.6, "D", -6.6, 0.0, 0.22), Vector3(0.45, 0.44, 0.45), "bois", 1.0)
	_spot("voilerie", 21.6, "D", -6.4, 23.0, -5.0, "assis", "d_n2")
	# les cabanes
	var c2: Transform3D = TF(38.0, "D", -7.6, 180.0)
	points["porte_cabane_2"] = c2 * kit.shack(c2, 5.0, 2.8, 2.5, "cabane_sombre", -0.8)
	var c3: Transform3D = TF(22.0, "D", 8.6, 0.0)
	points["porte_cabane_3"] = c3 * kit.shack(c3, 5.6, 3.0, 2.5, "toile_rouge", 1.0)
	var c4: Transform3D = TF(-13.0, "D", 10.4, 0.0)
	points["porte_cabane_4"] = c4 * kit.shack(c4, 6.0, 3.2, 2.6, "cabane_sombre", -1.2)
	var c5: Transform3D = TF(-4.0, "D", 10.6, 0.0)
	kit.shack(c5, 5.0, 3.0, 2.4, "toile_bleue", 0.8)
	var c6: Transform3D = TF(-37.0, "D", -12.2, 180.0)
	kit.shack(c6, 5.0, 2.2, 2.4, "toile_rouge", 0.0)
	# la cloche du bord, sur son portique
	var bx: Transform3D = TF(17.6, "D", 2.0, 90.0)
	for s in [-0.6, 0.6]:
		kit.box(bx * Transform3D(Basis(), Vector3(s, 1.2, 0)), Vector3(0.16, 2.4, 0.16), "bois_sombre", 1.0)
	kit.box(bx * Transform3D(Basis(), Vector3(0, 2.4, 0)), Vector3(1.5, 0.18, 0.2), "bois_sombre", 1.0)
	kit.cyl(bx * Transform3D(Basis(), Vector3(0, 1.75, 0)), 0.36, 0.2, 0.55, "bronze", 16)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(1.4, 2.4, 0.3))
	bell_pos = bx * Vector3(0, 1.8, 0)
	_spot("pont_cloche", 18.8, "D", 2.0, 17.6, 2.0, "debout", "d4")
	# la place devant la taverne : tables-tonneaux et bancs
	for tp in [[-33.0, -3.0], [-33.0, 4.0], [-27.0, 4.6]]:
		var tw: Vector3 = L(tp[0], E.D, tp[1])
		kit.barrel(tw, true)
		kit.disc(Transform3D(E.xf.basis, tw + E.xf.basis.y * 0.92), 0.5, "bois", 12)
	_bench(-30.0, "D", -13.4, 0.0)
	_bench(-30.0, "D", 13.4, 180.0)
	_spot("pont_banc_1", -30.4, "D", -13.1, -30.4, -10.0, "assis", "d_n0")
	_spot("pont_banc_2", -29.6, "D", 13.1, -29.6, 10.0, "assis", "d_qd")
	_spot("pont_place", -30.0, "D", 0.5, -40.0, 0.0, "debout", "d_place")
	_spot("bastingage_1", -22.0, "D", 14.2, -22.0, 18.0, "comptoir", "d2")
	_spot("bastingage_2", 31.0, "D", -12.4, 31.0, -15.0, "comptoir", "d6")
	_spot("bastingage_3", -16.0, "D", -14.2, -16.0, -18.0, "comptoir", "d_n1")
	# la proue du guetteur : un caillebotis surélevé, une longue-vue sur pied
	var px: Transform3D = TF(60.0, "D", 0.0, 90.0)
	kit.box(px * Transform3D(Basis(), Vector3(0, 0.12, 0.4)), Vector3(3.0, 0.24, 2.4), "bois", 1.2)
	kit.col_box(px * Transform3D(Basis(), Vector3(0, 0.12, 0.4)), Vector3(3.0, 0.24, 2.4))
	kit.cyl(px * Transform3D(Basis(), Vector3(0.9, 0.24, -0.4)), 0.03, 0.03, 1.2, "laiton", 6)
	kit.cyl(px * Transform3D(Basis(Vector3(1, 0, 0), -1.35), Vector3(0.9, 1.45, -0.4)), 0.05, 0.04, 0.8, "laiton", 10)
	_spot("proue", 60.6, "D", -0.4, 70.0, -0.4, "bras_croises", "d_proue")
	# lampadaires du pont (allumés la nuit)
	for lp in [[-36.0, -6.0], [-36.0, 6.0], [-12.0, -13.0], [10.0, 12.0], [30.0, -9.0], [48.0, 4.0]]:
		_deck_lamp(float(lp[0]), float(lp[1]))
	# tonneaux, caisses, cordages lovés, filets
	for p in [[-24.0, 13.6], [-22.8, 13.8], [8.0, -13.0], [44.0, -6.5], [52.0, 5.5]]:
		kit.barrel(L(p[0], lv("D", p[0]), p[1]))
	for p2 in [[-20.0, -13.6], [34.0, 6.0], [35.0, 6.8], [55.0, -4.0]]:
		kit.crate(L(p2[0], lv("D", p2[0]), p2[1]), kit.rng.randf(), 0.75)
	for p3 in [[0.0, -12.0], [26.0, 3.0], [-18.0, 5.0]]:
		kit.ring(TF(p3[0], "D", p3[1]), 0.15, 0.5, 0.18, "corde", 18)


func _bench(x: float, level: String, z: float, rot: float) -> void:
	var xf: Transform3D = TF(x, level, z, rot)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.43, 0)), Vector3(2.0, 0.07, 0.42), "bois", 1.0)
	for s in [-0.8, 0.8]:
		kit.box(xf * Transform3D(Basis(), Vector3(s, 0.2, 0)), Vector3(0.1, 0.4, 0.36), "bois_sombre", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(2.0, 0.5, 0.42))


func _deck_lamp(x: float, z: float) -> void:
	var xf: Transform3D = TF(x, "D", z)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.4, 0)), Vector3(0.14, 2.8, 0.14), "bois_sombre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0.3, 2.75, 0)), Vector3(0.7, 0.1, 0.1), "bois_sombre", 1.0)
	kit.ship_lantern(xf * Transform3D(Basis(), Vector3(0.55, 2.7, 0)))
	kit.col_cyl(xf.origin, 0.12, 2.8)
	if kit.temps != null:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.75, 0.45)
		l.omni_range = 9.0
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		l.position = xf * Vector3(0.55, 2.2, 0)
		add_child(l)
		kit.temps.register_lamp(l, 1.5)


# =================================================================== la taverne

func _tavern() -> void:
	var T := "T"
	# le comptoir, le long du flanc nord, et les étagères derrière
	var cx: Transform3D = TF(-55.0, T, -12.0, 0.0)
	kit.box(cx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(8.0, 1.1, 0.7), "vaigrage", 1.2)
	kit.box(cx * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(8.2, 0.07, 0.85), "bois", 1.2)
	kit.col_box(cx * Transform3D(Basis(), Vector3(0, 0.56, 0)), Vector3(8.0, 1.12, 0.7))
	for k in range(2):
		kit.box(cx * Transform3D(Basis(), Vector3(0, 1.5 + k * 0.6, -2.4)), Vector3(7.0, 0.05, 0.35), "bois_sombre", 1.0)
		for j in range(12):
			kit.cyl(cx * Transform3D(Basis(), Vector3(-3.2 + j * 0.58, 1.53 + k * 0.6, -2.4)), 0.06, 0.05, 0.3, "bouteille", 8)
	for bpos in [Vector3(-3.6, 0, -1.6), Vector3(-2.8, 0, -1.9), Vector3(3.6, 0, -1.6)]:
		kit.barrel(cx * bpos)
	# tabourets du comptoir
	for sx in [-1.0, 2.0]:
		var stx: Transform3D = cx * Transform3D(Basis(), Vector3(sx, 0, 0.95))
		kit.cyl(stx, 0.04, 0.04, 0.62, "bois_sombre", 6)
		kit.cyl(stx * Transform3D(Basis(), Vector3(0, 0.62, 0)), 0.2, 0.2, 0.06, "bois", 10)
	_spot("tav_comptoir", -55.0, T, -13.3, -55.0, -11.0, "comptoir", "t2")
	_spot("tav_bar_1", -56.0, T, -10.7, -56.0, -12.0, "boire", "t2")
	_spot("tav_bar_2", -53.0, T, -10.7, -53.0, -12.0, "boire", "t1")
	_spot("tav_service", -47.0, T, 0.0, -55.0, 0.0, "debout", "t1")
	# les tables et leurs bancs
	var tables := [[-50.0, 4.5], [-58.0, 4.5], [-63.0, -3.0], [-47.5, 10.0], [-55.0, 10.5], [-62.5, 11.0], [-49.0, -5.0], [-60.5, -6.2]]
	for i in range(tables.size()):
		var tp: Array = tables[i]
		var txf: Transform3D = TF(float(tp[0]), T, float(tp[1]), 0.0)
		kit.box(txf * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(2.6, 0.08, 1.0), "bois", 1.0)
		for sx in [-1.0, 1.0]:
			kit.box(txf * Transform3D(Basis(), Vector3(sx * 1.1, 0.37, 0)), Vector3(0.1, 0.74, 0.8), "bois_sombre", 1.0)
			kit.box(txf * Transform3D(Basis(), Vector3(0, 0.44, sx * 0.85)), Vector3(2.4, 0.07, 0.34), "bois_sombre", 1.0)
		kit.col_box(txf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.6, 0.8, 1.0))
		kit.ship_lantern(txf * Transform3D(Basis(), Vector3(0, 2.6, 0)))
		kit.cyl(txf * Transform3D(Basis(), Vector3(0.6, 0.8, 0.1)), 0.06, 0.05, 0.14, "fer", 8)
	_spot("tav_table_1", -50.4, T, 3.6, -50.4, 4.5, "assis", "t1")
	_spot("tav_table_2", -49.6, T, 5.4, -49.6, 4.5, "assis", "t1")
	_spot("tav_table_3", -58.0, T, 3.6, -58.0, 4.5, "assis", "t2")
	_spot("tav_table_4", -63.0, T, -2.1, -63.0, -3.0, "assis", "t3")
	# des tonneaux en perce, des filets et des bouées accrochés aux murs
	for bp in [[-44.0, 12.6], [-44.0, 11.6], [-68.5, -11.0], [-68.5, -10.0], [-44.0, -12.4]]:
		kit.barrel(L(bp[0], E.D, bp[1]))
	for side in [-1.0, 1.0]:
		for nx in [-47.0, -61.0]:
			var wz: float = side * (E.hb_in(nx, E.D + 1.0) - 0.12)
			kit.quad(TF(nx, T, wz, 0.0 if side < 0.0 else 180.0, 2.3), 3.2, 1.6, "filet", Vector2(0, 0), Vector2(2.4, 1.2), true)
			kit.ring(Transform3D(E.xf.basis * Basis(Vector3(1, 0, 0), PI * 0.5), L(nx + 3.0, E.D + 2.2, wz - side * 0.1)), 0.22, 0.4, 0.12, "peinture_rouge", 16)
	# le poêle de l'ancienne cuisine, son tuyau, et le fauteuil du conteur
	var sx2: Transform3D = TF(-67.0, T, 7.5, -90.0)
	kit.box(sx2 * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(1.4, 1.1, 1.0), "canon", 1.0)
	kit.box(sx2 * Transform3D(Basis(), Vector3(0, 0.45, -0.51)), Vector3(0.7, 0.4, 0.02), "braise", 1.0)
	kit.cyl(sx2 * Transform3D(Basis(), Vector3(0, 1.1, 0.2)), 0.14, 0.14, E.QD_Y - E.D - 1.1, "fer", 8)
	kit.col_box(sx2 * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(1.4, 1.1, 1.0))
	var arm: Transform3D = TF(-64.9, T, 6.8, -90.0)
	kit.box(arm * Transform3D(Basis(), Vector3(0, 0.22, 0)), Vector3(0.8, 0.44, 0.75), "tissu_bordeaux", 1.0)
	kit.box(arm * Transform3D(Basis(), Vector3(0, 0.75, 0.36)), Vector3(0.8, 0.8, 0.14), "tissu_bordeaux", 1.0)
	_spot("tav_poele", -64.6, T, 6.8, -60.0, 6.8, "assis", "t3")
	_light(L(-66.5, E.D + 0.7, 7.0), Color(1.0, 0.5, 0.2), 1.4, 6.0, 0.3)
	# le lustre : une roue de charrette et ses chandelles
	var lx: Transform3D = TF(-54.0, T, 0.0, 0.0, 3.0)
	kit.ring(lx, 0.8, 0.95, 0.1, "bois_sombre", 24)
	for k2 in range(8):
		var a: float = TAU * k2 / 8.0
		kit.cyl(lx * Transform3D(Basis(), Vector3(cos(a) * 0.88, 0.1, sin(a) * 0.88)), 0.03, 0.03, 0.16, "lanterne", 6, false)
	_light(L(-54.0, E.D + 2.7, 0.0), Color(1.0, 0.75, 0.45), 1.8, 11.0, 0.05)
	_light(L(-47.0, E.D + 2.8, 6.0), Color(1.0, 0.75, 0.45), 1.0, 8.0, 0.05, true)
	# la porte de la chambre de Gwenola et Pierrick, dans la cloison du fond
	var dx: Transform3D = TF(-66.0, T, -E.hb_in(-66.0, E.D + 1.0) + 0.06, 180.0)
	kit.quad(dx * Transform3D(Basis(), Vector3(0, 1.05, 0)), 1.0, 2.1, "porte_brun")
	points["porte_taverne_chambre"] = L(-66.0, E.D, -E.hb_in(-66.0, E.D + 1.0) + 1.0)
	# l'enseigne et deux lanternes sur la façade du château
	kit.carene_sign(TF(E.CASTLE_X + 0.08, T, 0.0, -90.0, 3.15), 2.6, 1.0, "enseigne_bordee")
	for s in [-2.0, 2.0]:
		kit.ship_lantern(TF(E.CASTLE_X + 0.4, T, s, 0.0, 2.9))
	_light(L(E.CASTLE_X + 1.5, E.D + 2.4, 0.0), Color(1.0, 0.74, 0.45), 1.0, 7.0, 0.06, true)


# =================================================================== la capitainerie

func _capitainerie() -> void:
	var Q := "Q"
	# le bureau de l'Amirale, face à la porte
	var bx: Transform3D = TF(-66.0, Q, 0.0, 90.0)
	kit.box(bx * Transform3D(Basis(), Vector3(0, 0.75, 0)), Vector3(2.2, 0.08, 1.0), "bois_sombre", 1.0)
	kit.box(bx * Transform3D(Basis(), Vector3(0, 0.37, 0.2)), Vector3(2.0, 0.74, 0.5), "vaigrage", 1.0)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.2, 0.8, 1.0))
	kit.cyl(bx * Transform3D(Basis(), Vector3(0.7, 0.79, 0.1)), 0.12, 0.12, 0.02, "laiton", 16)
	kit.cyl(bx * Transform3D(Basis(), Vector3(-0.7, 0.79, 0.1)), 0.05, 0.04, 0.16, "bouteille", 8)
	_spot("capitainerie_bureau", -67.0, Q, 0.0, -60.0, 0.0, "debout", "c1")
	# la table des cartes de Matthias (la carte de l'archipel dessus)
	var tx: Transform3D = TF(-61.5, Q, -4.6, 0.0)
	kit.box(tx * Transform3D(Basis(), Vector3(0, 0.88, 0)), Vector3(2.4, 0.08, 1.4), "bois", 1.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(tx * Transform3D(Basis(), Vector3(sx * 1.05, 0.44, sz * 0.58)), Vector3(0.1, 0.88, 0.1), "bois_sombre", 1.0)
	kit.col_box(tx * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.9, 1.4))
	var map_xf: Transform3D = tx * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.93, 0))
	kit.quad(map_xf, 1.9, 1.15, "carte")
	_spot("capitainerie_carte", -61.5, Q, -3.3, -61.5, -4.6, "comptoir", "c1")
	points["porte_capitainerie"] = L(-63.0, E.QD_Y, 3.8)
	_light(L(-62.0, E.QD_Y + 2.6, 0.0), Color(1.0, 0.78, 0.5), 1.4, 9.0, 0.04)
	kit.ship_lantern(TF(-62.0, Q, 0.0, 0.0, 3.2))
	# l'enseigne au-dessus de la porte
	kit.carene_sign(TF(E.CABIN_X + 0.08, Q, 0.0, -90.0, 2.85), 1.7, 0.66, "enseigne_capitainerie_carene")
	# sur la dunette
	_spot("dunette_1", -47.0, Q, 0.0, -30.0, 0.0, "bras_croises", "q1")
	_spot("dunette_2", -43.0, Q, -8.0, -38.0, -8.0, "comptoir", "q1")


## Dans la coque, le ciel n'éclaire pas : une lumière ambiante chaude et sombre (sondes
## de réflexion « intérieures »), en plus des lanternes.
func _interior_probes() -> void:
	for pr in [[Vector3(-5.0, 8.25, 0.0), Vector3(122.0, 7.4, 34.0), Color(0.36, 0.27, 0.18), 0.9],
			[Vector3(-2.5, 15.75, 0.0), Vector3(129.0, 7.4, 33.0), Color(0.36, 0.27, 0.18), 0.85],
			[Vector3(-56.0, 21.4, 0.0), Vector3(27.6, 3.7, 30.0), Color(0.48, 0.32, 0.18), 1.0],
			[Vector3(-63.5, 25.0, 0.0), Vector3(12.6, 3.3, 28.0), Color(0.42, 0.32, 0.2), 1.0]]:
		var p := ReflectionProbe.new()
		p.name = "Ambiance_interieure"
		p.size = pr[1]
		p.interior = true
		p.update_mode = ReflectionProbe.UPDATE_ONCE
		p.ambient_mode = ReflectionProbe.AMBIENT_COLOR
		p.ambient_color = pr[2]
		p.ambient_color_energy = float(pr[3])
		p.intensity = 0.6
		p.max_distance = 80.0
		p.blend_distance = 1.5
		var c: Vector3 = pr[0]
		p.transform = Transform3D(E.xf.basis, L(c.x, c.y, c.z))
		add_child(p)


# =================================================================== garde-corps

func _railings() -> void:
	var up: Vector3 = E.xf.basis.y
	# autour des écoutilles et des trémies d'escalier (entrepont et pont)
	for lvl in ["G", "D"]:
		var hatch := [-4.0, 14.0, -4.0, 4.0]
		var y0: float = lv(lvl, 5.0)
		kit.railing(L(hatch[0], y0, hatch[2]), L(hatch[1], y0, hatch[2]), up)
		kit.railing(L(hatch[0], y0, hatch[3]), L(hatch[1], y0, hatch[3]), up)
		kit.railing(L(hatch[0], y0, hatch[2]), L(hatch[0], y0, hatch[3]), up)
		kit.railing(L(hatch[1], y0, hatch[2]), L(hatch[1], y0, hatch[3]), up)
	var g: float = E.GUN_Y
	kit.railing(L(16.0, g, 6.6), L(31.0, g, 6.6), up)
	kit.railing(L(16.0, g, 10.4), L(31.0, g, 10.4), up)
	kit.railing(L(16.0, g, 6.6), L(16.0, g, 10.4), up)
	var d: float = E.D
	kit.railing(L(-21.0, d, -6.6), L(-6.0, d, -6.6), up)
	kit.railing(L(-21.0, d, -10.4), L(-6.0, d, -10.4), up)
	kit.railing(L(-6.0, d, -10.4), L(-6.0, d, -6.6), up)
	# les flancs de la dunette et du toit de la capitainerie (au-dessus de la muraille)
	for lvl2 in [[E.QD_Y, E.CABIN_X, E.CASTLE_X], [E.PD_Y, -69.4, E.CABIN_X]]:
		var yy: float = float(lvl2[0])
		var xa: float = float(lvl2[1])
		var xb: float = float(lvl2[2])
		for side in [-1.0, 1.0]:
			var x: float = xa
			while x < xb - 0.3:
				var xn: float = minf(x + 3.0, xb - 0.2)
				kit.railing(L(x, yy, side * (E.hb_in(x, E.D + 1.0) - 0.15)), L(xn, yy, side * (E.hb_in(xn, E.D + 1.0) - 0.15)), up)
				x = xn
	var w: float = E.hb_in(-69.4, E.D + 1.0) - 0.2
	kit.railing(L(-69.3, E.PD_Y, -w), L(-69.3, E.PD_Y, w), up)


# =================================================================== dehors

func _outside() -> void:
	var bas := Basis(Vector3.UP, E.yaw)
	# la passerelle de la brèche : de la cale jusqu'à la plage
	var top: Vector3 = L(42.0, E.HOLD_Y, -6.2)
	var low: Vector3 = ground(42.0, -21.0)
	var dir: Vector3 = low - top
	var f: Vector3 = dir.normalized()
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(f).normalized()
	var mid: Vector3 = (top + low) * 0.5
	var gx := Transform3D(Basis(side, up, -f), mid)
	kit.box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(3.2, 0.12, dir.length() + 0.6), "pont", 1.0)
	kit.col_box(gx * Transform3D(Basis(), Vector3(0, -0.06, 0)), Vector3(3.2, 0.12, dir.length() + 0.6))
	for s in [-1.0, 1.0]:
		kit.box(gx * Transform3D(Basis(), Vector3(s * 1.55, 0.9, 0)), Vector3(0.08, 0.08, dir.length()), "corde", 1.0)
		var n: int = int(dir.length() / 2.5)
		for i in range(n + 1):
			var pz: float = -dir.length() * 0.5 + dir.length() * float(i) / n
			kit.box(gx * Transform3D(Basis(), Vector3(s * 1.55, 0.45, pz)), Vector3(0.1, 0.9, 0.1), "bois_sombre", 1.0)
		kit.col_box(gx * Transform3D(Basis(), Vector3(s * 1.6, 0.5, 0)), Vector3(0.12, 1.0, dir.length()))
	walk_boxes.append([gx.affine_inverse(), Vector3(1.8, 3.0, dir.length() * 0.5 + 0.8)])
	gangway = [top, low]
	# le grand ponton, le long du flanc nord
	var a: Vector3 = pier(PIER_X0)
	var b: Vector3 = pier(PIER_X1)
	var pl: float = a.distance_to(b)
	var px := Transform3D(bas * Basis(Vector3.UP, PI * 0.5), (a + b) * 0.5 + Vector3.DOWN * 0.1)
	kit.box(px, Vector3(3.2, 0.2, pl), "pont", 1.2)
	kit.col_box(px, Vector3(3.2, 0.2, pl))
	walk_boxes.append([px.affine_inverse(), Vector3(2.0, 3.0, pl * 0.5 + 0.4)])
	var s2: float = 0.0
	while s2 <= pl:
		var p: Vector3 = a.lerp(b, s2 / pl)
		for sd in [-1.0, 1.0]:
			var post: Vector3 = p + bas * Vector3(0, 0, sd * 1.5)
			var gy: float = minf(ile.height(post.x, post.z), -0.5)
			kit.cyl(Transform3D(Basis(), Vector3(post.x, gy - 0.5, post.z)), 0.16, 0.18, PIER_Y + 0.4 - gy, "goudron", 8)
		s2 += 3.0
	# la rampe du ponton à la plage
	var beach: Vector3 = ground(PIER_X0 + 7.0, PIER_Z)
	var r0: Vector3 = a
	var rdir: Vector3 = beach - r0
	var rf: Vector3 = rdir.normalized()
	var rs: Vector3 = rf.cross(Vector3.UP).normalized()
	var ru: Vector3 = rs.cross(rf).normalized()
	var rx := Transform3D(Basis(rs, ru, -rf), (r0 + beach) * 0.5 + Vector3.DOWN * 0.1)
	kit.box(rx, Vector3(3.2, 0.2, rdir.length() + 0.4), "pont", 1.2)
	kit.col_box(rx, Vector3(3.2, 0.2, rdir.length() + 0.4))
	walk_boxes.append([rx.affine_inverse(), Vector3(2.0, 3.0, rdir.length() * 0.5 + 0.6)])
	# le ponton de la barque du joueur (fabriqué par boat_v29._make_dock)
	boat_dock = [pier(PIER_X1 + 0.4), pier(DOCK_X1)]
	_spot_w("ponton_peche", pier(0.0, PIER_Z - 1.3), pier(0.0, PIER_Z - 6.0), "assis", "pi1")
	_spot_w("ponton_coque", pier(-10.0, PIER_Z + 1.2), pier(-10.0, -10.0), "debout", "pi2")
	_spot_w("ponton_bout", pier(-28.0, PIER_Z - 1.0), pier(-34.0, PIER_Z - 8.0), "debout", "pi3")
	for lx in [16.0, -4.0, -24.0]:
		var lp: Vector3 = pier(lx, PIER_Z - 1.45)
		var lt := Transform3D(bas, lp)
		kit.box(lt * Transform3D(Basis(), Vector3(0, 1.3, 0)), Vector3(0.14, 2.6, 0.14), "bois_sombre", 1.0)
		kit.ship_lantern(lt * Transform3D(Basis(), Vector3(0, 2.75, 0)))
		if kit.temps != null:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.75, 0.45)
			l.omni_range = 8.0
			l.shadow_enabled = false
			l.position = lp + Vector3.UP * 2.3
			add_child(l)
			kit.temps.register_lamp(l, 1.4)
	# la plage : la barque retournée de Fañch
	var hx: Transform3D = TW(54.0, -44.0, 20.0)
	var hut := _skiff(4)
	hut.transform = Transform3D(hx.basis * Basis(Vector3(1, 0, 0), PI), hx.origin + Vector3.UP * 1.85)
	hut.scale = Vector3(1.9, 2.2, 2.0)
	add_child(hut)
	kit.box(hx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(7.6, 1.0, 2.5), "cabane_sombre", 1.4)
	kit.col_box(hx * Transform3D(Basis(), Vector3(0, 1.1, 0)), Vector3(8.2, 2.2, 2.9))
	kit.box(hx * Transform3D(Basis(), Vector3(3.85, 0.95, 0)), Vector3(0.12, 1.9, 1.0), "porte_brun", 1.0)
	kit.cyl(hx * Transform3D(Basis(), Vector3(-1.0, 1.6, 0.5)), 0.08, 0.08, 1.4, "fer", 8)
	points["porte_barque"] = hx * Vector3(4.7, 0.0, 0.0)
	# les filets qui sèchent
	for k in range(3):
		var nx: Transform3D = TW(24.0 + k * 5.5, -38.0 - k * 1.5, 10.0)
		for s3 in [-2.0, 2.0]:
			kit.box(nx * Transform3D(Basis(), Vector3(s3, 1.1, 0)), Vector3(0.12, 2.2, 0.12), "bois_sombre", 1.0)
		kit.box(nx * Transform3D(Basis(), Vector3(0, 2.15, 0)), Vector3(4.3, 0.08, 0.08), "bois_sombre", 1.0)
		kit.quad(nx * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(0, 1.3, 0)), 4.0, 1.7, "filet", Vector2(0, 0), Vector2(3, 1.5), true)
	_spot_w("plage_filets", TW(35.0, -38.4).origin, TW(35.0, -41.0).origin, "debout", "e_filets")
	# deux barques tirées sur le sable
	for i in range(2):
		var sk := _skiff(i + 1)
		var bt: Transform3D = TW(26.0 + i * 9.0, -33.0 - i * 6.0, 60.0 + i * 25.0)
		sk.transform = Transform3D(bt.basis * Basis(Vector3(1, 0, 0), 0.12 * (1 - 2 * i)), bt.origin + Vector3.UP * 0.25)
		add_child(sk)
	# le feu de camp, ses pierres et ses bûches-bancs
	var fc: Transform3D = TW(44.0, -54.0)
	for k2 in range(9):
		var a2: float = TAU * k2 / 9.0
		kit.box(fc * Transform3D(Basis(Vector3.UP, a2), Vector3(cos(a2) * 0.85, 0.12, sin(a2) * 0.85)), Vector3(0.36, 0.26, 0.3), "pierre_sombre", 0.6)
	for k3 in range(4):
		kit.cyl(fc * Transform3D(Basis(Vector3.UP, k3 * 0.8).rotated(Vector3.UP, 0.0) * Basis(Vector3(1, 0, 0), 1.2), Vector3(0, 0.15, 0)), 0.07, 0.07, 0.9, "bois_sombre", 6)
	fire_mat = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
	fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.5, 0.15)
	fire_mat.emission_energy_multiplier = 0.0
	fire_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var flame := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.02
	fm.bottom_radius = 0.42
	fm.height = 1.0
	fm.radial_segments = 8
	flame.mesh = fm
	flame.material_override = fire_mat
	flame.position = fc.origin + Vector3.UP * 0.55
	flame.name = "Feu_de_camp"
	add_child(flame)
	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.55, 0.22)
	fire_light.omni_range = 11.0
	fire_light.light_energy = 0.0
	fire_light.shadow_enabled = pc
	fire_light.position = fc.origin + Vector3.UP * 1.0
	add_child(fire_light)
	for k4 in range(3):
		var a3: float = TAU * k4 / 3.0 + 0.4
		var seat: Vector3 = fc * Vector3(cos(a3) * 2.4, 0.0, sin(a3) * 2.4)
		seat.y = ile.height(seat.x, seat.z)
		var lb := Basis(Vector3.UP, -a3 + PI * 0.5 + E.yaw)
		kit.cyl(Transform3D(lb * Basis(Vector3(0, 0, 1), PI * 0.5), seat + Vector3.UP * 0.22 + lb * Vector3(0.8, 0, 0)), 0.22, 0.22, 1.6, "bois_sombre", 10)
		var sp: Vector3 = fc * Vector3(cos(a3) * 2.6, 0.0, sin(a3) * 2.6)
		sp.y = ile.height(sp.x, sp.z)
		_spot_w("plage_feu_%d" % (k4 + 1), sp, fc.origin, "assis", "e_feu")
	# un mât de pavillon et une ancre sur la plage, à côté de la passerelle
	var an: Transform3D = TW(47.0, -26.0, 30.0)
	kit.box(an * Transform3D(Basis(), Vector3(0, 1.4, 0)), Vector3(0.2, 2.8, 0.2), "canon", 1.0)
	kit.box(an * Transform3D(Basis(), Vector3(0, 2.6, 0)), Vector3(1.2, 0.16, 0.16), "canon", 1.0)
	kit.box(an * Transform3D(Basis(Vector3(0, 0, 1), 0.5), Vector3(-0.7, 0.3, 0)), Vector3(1.3, 0.2, 0.2), "canon", 1.0)
	kit.box(an * Transform3D(Basis(Vector3(0, 0, 1), -0.5), Vector3(0.7, 0.3, 0)), Vector3(1.3, 0.2, 0.2), "canon", 1.0)
	kit.ring(an * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 3.0, 0)), 0.18, 0.28, 0.08, "canon", 14)
	kit.col_box(an * Transform3D(Basis(), Vector3(0, 1.3, 0)), Vector3(1.6, 2.6, 0.4))


# =================================================================== habitants : lieux et chemins

func _spot(name: String, x: float, level: String, z: float, fx: float, fz: float, pose: String, node: String) -> void:
	var y: float = lv(level, x)
	spots[name] = {"pos": L(x, y, z), "face": L(fx, y, fz), "pose": pose, "node": node}


func _spot_w(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _p(name: String, x: float, level: String, z: float) -> void:
	points[name] = L(x, lv(level, x), z)


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


func _graph() -> void:
	# la cale
	_p("h_breche", 42.0, "H", -5.0); _p("h1", 36.0, "H", -3.0); _p("h2", 26.0, "H", -3.2); _p("h3", 19.0, "H", -0.5)
	_p("h_esc", 15.0, "H", 8.5); _p("h4", 14.0, "H", 2.0); _p("h_quai", _quay_x(-7.5) + 1.2, "H", -7.5); _p("h5", 45.0, "H", -0.5)
	_chain(["h_breche", "h1", "h2", "h3", "h4", "h_esc"])
	_chain(["h1", "h5"])
	_chain(["h3", "h_quai"])
	# le bassin
	points["b0"] = pontoon(_quay_x(-7.5) - 2.2, -7.5)
	points["b1"] = pontoon(-14.0, -7.5)
	points["b2"] = pontoon(-26.0, -7.5)
	points["b3"] = pontoon(-38.0, -7.5)
	_chain(["h_quai", "b0", "b1", "b2", "b3"])
	# l'entrepont
	_p("g_esc_h", 32.0, "G", 8.5); _p("g1", 34.0, "G", 4.0); _p("g2", 44.0, "G", -4.0); _p("g3", 54.0, "G", 1.5)
	_p("g_n1", 24.0, "G", -6.4); _p("g_n2", 12.0, "G", -6.6); _p("g_w", -6.0, "G", -5.0); _p("g_esc_d", -5.0, "G", -8.5)
	_p("g_s0", -6.0, "G", 5.6); _p("g_s1", -12.0, "G", 6.4); _p("g_s2", -26.0, "G", 6.4); _p("g_s3", -35.0, "G", 6.4)
	_p("g_s4", -50.0, "G", 2.6); _p("g_s5", 10.0, "G", 5.6)
	_link("h_esc", "g_esc_h")
	_chain(["g_esc_h", "g1", "g2", "g3"])
	_chain(["g1", "g_n1", "g_n2", "g_w", "g_esc_d"])
	_chain(["g_w", "g_s0", "g_s1", "g_s2", "g_s3", "g_s4"])
	_chain(["g_s0", "g_s5", "g1"])
	# le pont
	_p("d_esc_g", -22.0, "D", -8.5); _p("d1", -26.0, "D", -4.0); _p("d_place", -30.0, "D", 1.0); _p("d_tav", -40.6, "D", 0.0)
	_p("d_qd", -29.5, "D", 10.6); _p("d2", -14.0, "D", 7.2); _p("d3", 0.0, "D", 7.0); _p("d4", 17.0, "D", 5.8)
	_p("d6", 28.0, "D", -1.0); _p("d7", 40.0, "D", -3.0); _p("d8", 52.0, "D", 0.0); _p("d_proue", 59.0, "D", 0.0)
	_p("d_n0", -25.0, "D", -12.0); _p("d_n1", -3.0, "D", -12.0); _p("d_n2", 18.0, "D", -6.0)
	_link("g_esc_d", "d_esc_g")
	_chain(["d_esc_g", "d1", "d_place", "d_tav"])
	_chain(["d_place", "d2", "d3", "d4", "d6", "d7", "d8", "d_proue"])
	_chain(["d1", "d_n0", "d_n1", "d_n2", "d6"])
	_chain(["d_place", "d_qd"])
	# la taverne
	_p("t_in", -44.0, "T", 0.0); _p("t1", -50.0, "T", 1.2); _p("t2", -56.0, "T", -6.4); _p("t3", -62.0, "T", 1.5)
	_chain(["d_tav", "t_in", "t1", "t2"])
	_chain(["t1", "t3"])
	# la dunette et la capitainerie
	_p("q_esc", -43.4, "Q", 10.6); _p("q1", -47.0, "Q", 4.0); _p("q_cap", -55.6, "Q", 0.0); _p("c_in", -59.0, "Q", 0.0); _p("c1", -63.0, "Q", 1.5)
	_p("q_pesc", -44.6, "Q", -5.6); _p("p_esc", -58.6, "P", -5.6); _p("p1", -64.0, "P", 0.0)
	_chain(["d_qd", "q_esc", "q1", "q_cap", "c_in", "c1"])
	_chain(["q1", "q_pesc", "p_esc", "p1"])
	# dehors : la passerelle, la plage, le ponton
	points["e_gang"] = gangway[1] if gangway.size() > 1 else ground(42.0, -21.0)
	points["e1"] = ground(36.0, -30.0)
	points["e_filets"] = ground(36.0, -35.0)
	points["e_feu"] = ground(42.0, -50.0)
	points["e_barque"] = ground(60.0, -41.0)
	points["e_pier"] = ground(PIER_X0 + 6.0, PIER_Z)
	points["pi0"] = pier(PIER_X0 - 1.0)
	points["pi1"] = pier(0.0)
	points["pi2"] = pier(-10.0)
	points["pi3"] = pier(-28.0)
	_chain(["h_breche", "e_gang", "e1", "e_filets", "e_feu"])
	_chain(["e_filets", "e_barque"])
	_chain(["e1", "e_pier", "pi0", "pi1", "pi2", "pi3"])
	# les portes des maisons, reliées au point le plus proche du même niveau
	var door_links := {
		"porte_logis_1": "g_n1", "porte_logis_2": "g_n1", "porte_logis_3": "g1", "porte_logis_4": "g_s2", "porte_logis_5": "g_s1", "porte_logis_6": "g_s1",
		"porte_cabane_1": "d_n2", "porte_cabane_2": "d7", "porte_cabane_3": "d4", "porte_cabane_4": "d2",
		"porte_capitainerie": "c1", "porte_taverne_chambre": "t3", "porte_barque": "e_barque",
	}
	for k in door_links:
		if points.has(k):
			_link(str(k), str(door_links[k]))
	# chaque lieu d'activité a son point « @nom », relié à son nœud
	for s in spots:
		var nm: String = "@" + str(s)
		points[nm] = spots[s]["pos"]
		_link(nm, str(spots[s]["node"]))
		spots[s]["node"] = nm


## Le point (monde) est-il sur une construction de Carène (ponton, passerelle) ?
func on_walkway(p: Vector3) -> bool:
	for wb in walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.0 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


# =================================================================== vie

func _process(delta: float) -> void:
	_clock += delta
	for b in boats:
		var n: Node3D = b[0]
		var ph: float = float(b[1])
		n.position.y = float(b[2]) + sin(_clock * 0.9 + ph) * 0.05
		n.rotation.z = sin(_clock * 0.7 + ph) * 0.03
	for li in lights_inside:
		var l: OmniLight3D = li[0]
		if l == null or float(li[2]) <= 0.0:
			continue
		var fl: float = float(li[2])
		l.light_energy = float(li[1]) * (1.0 - fl * 0.5 + fl * 0.5 * sin(_clock * 9.0 + l.position.x) * sin(_clock * 13.0 + l.position.z))
	var night: bool = false
	var t: Node = main.get("temps_v56") if main != null else null
	if t != null:
		night = bool(t.lamps_on)
	if fire_light != null:
		var on: bool = night
		fire_light.light_energy = (1.8 + 0.5 * sin(_clock * 11.0) * sin(_clock * 7.0)) if on else 0.0
		fire_mat.emission_energy_multiplier = 3.0 if on else 0.0
		fire_mat.albedo_color.a = 0.85 if on else 0.0
	if E != null:
		E.set_windows(night)
		if E.lantern_light != null:
			E.lantern_light.light_energy = 3.0 if night else 0.0
			E.lantern_mat.emission_energy_multiplier = 4.0 if night else 0.3

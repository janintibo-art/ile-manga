extends Node3D
## V61 : Cliquetis, la cité des ingénieurs fous, sur les hautes terres du nord de la grande île.
## Une cité rétrofuturiste de brique, de cuivre et de verre, au bord des falaises :
##  - la Grande-Place de la Foire des Inventions : la Machine Universelle (des engrenages
##    géants qui tournent, une chaudière qui fume, une cloche), six stands de démonstration
##    (le piano mécanique, la machine à bulles, le canon à confettis, Boulon le chien-robot,
##    l'automate joueur d'échecs, le moteur perpétuel) ;
##  - l'Académie des Ingénieurs et sa grande horloge (les aiguilles donnent la vraie heure) ;
##  - le Café de la Bielle (servi par un robot), le Bazar des Inutilités (des objets bizarres
##    qui ne servent à rien), l'Atelier du professeur Boum (ça explose régulièrement), le
##    laboratoire Volta et ses bobines de Tesla (des éclairs), l'observatoire, la fabrique
##    de robots, les maisons-ateliers et leurs cheminées qui fument ;
##  - le monorail qui tourne au-dessus de la place, l'aérodrome du Zéphyr (le dirigeable qui
##    relie Cliquetis, Tazira et Carène), le téléphérique qui descend au port ;
##  - la promenade des falaises, le Colosse qui y patrouille ; le port au pied des falaises,
##    sa grue, son remorqueur à vapeur, la route en lacet.
## Repère « cité » : voir cliquetis_relief_v61.gd (monde = ORIGIN + (x, y, z), -Z vers la mer).

const R = preload("res://scripts/cliquetis_relief_v61.gd")
const Kit = preload("res://scripts/cliquetis_kit_v61.gd")
const Zephyr = preload("res://scripts/dirigeable_v61.gd")
const Telepherique = preload("res://scripts/telepherique_v61.gd")
const Robots = preload("res://scripts/robots_v61.gd")
const Y: float = 30.0
const PY: float = 1.4
const RAIL_RX: float = 41.0
const RAIL_RZ: float = 31.0
const RAIL_H: float = 8.0
const TEL_BOTTOM := Vector2(-20.0, -90.0)
const TEL_TOP := Vector2(-20.0, -38.5)
const DOCK_X: float = -40.0

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var zephyr: Node3D
var tele: Node3D
var robots: Node3D
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var objets: Dictionary = {}
var boat_dock: Array = []
var walk_boxes: Array = []
var _spin: Array = []                  # [Node3D, axe local, vitesse rad/s]
var _steam_spots: Array = []
var _clock_hands: Array = []           # [aiguille des heures, des minutes]
var _train: Array = []
var _train_s: float = 0.0
var _rail_pts: Array = []
var _tesla_tops: Array = []
var _arc_mesh: ImmediateMesh
var _arc_mi: MeshInstance3D
var _arc_light: OmniLight3D
var _arc_t: float = 2.0
var _arc_on: float = 0.0
var _boum_t: float = 30.0
var _boum_fx: Array = []               # [lumière, particules x3]
var _boum_at := Vector3.ZERO
var _confetti: CPUParticles3D
var _confetti_t: float = 12.0
var _crane_jib: Node3D
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()


# =================================================================== repères

func T(x: float, z: float, dy: float = 0.0) -> Vector3:
	return R.to_world(x, z, Y + dy)


func TF(x: float, z: float, rot: float = 0.0, dy: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(rot)), T(x, z, dy))


func P(x: float, z: float, dy: float = 0.0) -> Vector3:
	return R.to_world(x, z, PY + dy)


func PF(x: float, z: float, rot: float = 0.0, dy: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(rot)), P(x, z, dy))


func contains(p: Vector3) -> bool:
	var t: Vector2 = R.to_city(p.x, p.z)
	return t.x > -125.0 and t.x < 165.0 and t.y > -135.0 and t.y < 70.0 and p.y > -20.0


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6100
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6101
	_paving()
	_promenade()
	_rempart()
	_place()
	_academie()
	_cafe()
	_bazar()
	_boum()
	_volta()
	_observatoire()
	_fabrique()
	_houses()
	_aerodrome()
	_port()
	_road()
	kit.commit()
	_monorail()
	_steam_all()
	tele = Telepherique.new()
	tele.name = "Telepherique_v61"
	add_child(tele)
	tele.setup(main, P(TEL_BOTTOM.x, TEL_BOTTOM.y), T(TEL_TOP.x, TEL_TOP.y))
	zephyr = Zephyr.new()
	zephyr.name = "Zephyr_v61"
	add_child(zephyr)
	var pads: Array = []
	for pd in R.PADS:
		pads.append(pd[0])
	zephyr.height_fn = func(x: float, z: float) -> float: return ile.height(x, z)
	zephyr.setup(main, pads)
	robots = Robots.new()
	robots.name = "Robots_v61"
	add_child(robots)
	robots.setup(main)
	_graph()
	_robots()
	for l in find_children("*", "OmniLight3D", true, false):
		var ol: OmniLight3D = l
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 60.0
		ol.distance_fade_length = 15.0
		ol.shadow_enabled = false
	print("ILE_MANGA_V61: Cliquetis, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


func _paving() -> void:
	var step: float = 4.0
	var x: float = -100.0
	while x < 100.0:
		var z: float = -41.0
		while z < 48.0:
			var x1: float = minf(x + step, 100.0)
			var z1: float = minf(z + step, 48.0)
			var key: String = "dalles_cq" if (absf(x) < 34.0 and absf(z) < 24.0) else "paves_cq"
			kit.quad4(key, T(x, z, 0.03), T(x1, z, 0.03), T(x1, z1, 0.03), T(x, z1, 0.03), Vector3.UP,
				Vector2(x, z) * 0.28, Vector2(x1, z) * 0.28, Vector2(x1, z1) * 0.28, Vector2(x, z1) * 0.28)
			z = z1
		x += step
	# sur la place : deux cercles de laiton autour de la Machine, comme un cadran
	for rr in [9.0, 15.0]:
		kit.ring(TF(0.0, 0.0, 0.0, 0.035), rr - 0.18, rr, 0.02, "laiton", 64)
	for k in range(8):
		var a: float = TAU * k / 8.0
		kit.box(Transform3D(Basis(Vector3.UP, -a), T(cos(a) * 12.0, sin(a) * 12.0, 0.045)), Vector3(6.0, 0.02, 0.16), "laiton", 1.0)
	# le port
	x = R.PORT.position.x
	while x < R.PORT.end.x:
		var zp: float = R.PORT.position.y + 0.2
		while zp < R.PORT.end.y:
			var xp1: float = minf(x + step, R.PORT.end.x)
			var zp1: float = minf(zp + step, R.PORT.end.y)
			kit.quad4("fonte" if zp < R.PORT.position.y + 4.0 else "paves_cq", P(x, zp, 0.03), P(xp1, zp, 0.03), P(xp1, zp1, 0.03), P(x, zp1, 0.03), Vector3.UP,
				Vector2(x, zp) * 0.25, Vector2(xp1, zp) * 0.25, Vector2(xp1, zp1) * 0.25, Vector2(x, zp1) * 0.25)
			zp = zp1
		x += step


## La promenade des falaises : balustrade, réverbères, bancs, la longue-vue.
func _promenade() -> void:
	var z: float = -41.3
	for seg in [[-99.0, -23.5], [-16.5, 99.0]]:
		kit.iron_rail(T(seg[0], z), T(seg[1], z))
	var x: float = -92.0
	while x < 96.0:
		kit.globe_lamp(T(x, -39.8))
		x += 18.0
	for bx in [-60.0, -40.0, 20.0, 46.0, 72.0]:
		kit.bench(TF(bx, -38.8, 180.0))
	# la longue-vue de laiton, sur son trépied
	var lxf: Transform3D = TF(5.0, -39.6, 180.0)
	for k in range(3):
		var a: float = TAU * k / 3.0
		kit.pipe(lxf * Vector3(cos(a) * 0.4, 0, sin(a) * 0.4), lxf * Vector3(0, 1.2, 0), 0.03, "laiton", false)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, -1.25) * Basis(), lxf * Vector3(0, 1.25, 0.35)).rotated_local(Vector3.UP, 0.0) * Transform3D(Basis(), Vector3(0, -0.4, 0)), 0.06, 0.1, 1.1, "laiton", 10)
	_spot("promenade_lunette", 5.0, -38.6, 5.0, -60.0, "observer", "")
	_spot("promenade_banc_1", -60.0, -38.4, -60.0, -60.0, "assis", "")
	_spot("promenade_banc_2", -40.0, -38.4, -40.0, -60.0, "assis", "")
	_spot("promenade_banc_3", 20.0, -38.4, 20.0, -60.0, "assis", "")
	_spot("promenade_banc_4", 46.0, -38.4, 46.0, -60.0, "assis", "")
	_spot("promenade_vue_1", -8.0, -40.4, -8.0, -60.0, "comptoir", "")
	_spot("promenade_vue_2", 32.0, -40.4, 32.0, -60.0, "comptoir", "")
	_spot("promenade_vue_3", 60.0, -40.4, 60.0, -60.0, "comptoir", "")


## Le rempart du nord : la cité est bâtie au bord de la falaise sur un grand mur de briques à
## contreforts, percé de hublots (la nuit, ils s'allument : ce sont les ateliers souterrains),
## d'où descendent vers le port les grosses conduites de cuivre de la Fabrique.
## On laisse une brèche sous le téléphérique (x -27..-13).
func _rempart() -> void:
	# le mur va de la balustrade (z -42.4) jusqu'au pied de l'à-pic (z -49) : il cache la falaise
	var zn: float = -42.4
	var zs: float = -49.0
	var zf: float = (zn + zs) * 0.5
	var th: float = zn - zs
	var x: float = -100.0
	while x < 100.0:
		var x1: float = minf(x + 4.0, 100.0)
		var xc: float = (x + x1) * 0.5
		if xc > -27.0 and xc < -13.0:
			# la brèche du téléphérique : pas de mur, mais le glacis depuis le bord
			_glacis(x, x1, zn)
			x = x1
			continue
		var base: float = Y - 2.0
		for sx in [x, xc, x1]:
			for sz in [zs, zs - 1.5]:
				var w: Vector3 = R.to_world(sx, sz)
				base = minf(base, ile.height(w.x, w.z) - 1.2)
		var top: float = Y + 0.6
		var hh: float = top - base
		var c: Vector3 = R.to_world(xc, zf, base + hh * 0.5)
		kit.box(Transform3D(Basis(), c), Vector3(x1 - x, hh, th), "brique", 2.5)
		kit.col_box(Transform3D(Basis(), c), Vector3(x1 - x, hh, th))
		# au pied du mur, un glacis de moellons recouvre l'à-pic jusqu'à ce que la pente s'adoucisse
		_glacis(x, x1, zs)
		# la corniche de pierre, côté mer
		kit.box(Transform3D(Basis(), R.to_world(xc, zs + 0.1, top + 0.15)), Vector3(x1 - x, 0.3, 0.8), "pierre", 1.5)
		# un hublot sur deux colonnes
		if int(roundf(x)) % 8 == 0 and hh > 7.0:
			var hx: Transform3D = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), R.to_world(xc, zs - 0.02, Y - 4.0))
			kit.cyl(hx, 0.75, 0.75, 0.08, "laiton", 16)
			kit.cyl(hx * Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.6, 0.6, 0.06, "vitre_lumiere", 16)
		x = x1
	# les contreforts
	for bx in [-92.0, -72.0, -52.0, -36.0, 0.0, 20.0, 40.0, 60.0, 80.0, 96.0]:
		var wb: Vector3 = R.to_world(bx, zs - 2.0)
		var gb: float = ile.height(wb.x, wb.z) - 1.5
		var h2: float = Y - 2.0 - gb
		if h2 < 3.0:
			continue
		kit.box(Transform3D(Basis(), R.to_world(bx, zs - 1.4, gb + h2 * 0.5)), Vector3(2.6, h2, 2.8), "brique_sombre", 2.5)
		kit.box(Transform3D(Basis(Vector3.RIGHT, -0.6), R.to_world(bx, zs - 0.8, Y - 1.2)), Vector3(2.6, 0.4, 3.4), "pierre", 1.5)
	# les conduites de la cité, qui descendent jusqu'au port
	for cx in [53.0, 56.0]:
		var prev: Vector3 = R.to_world(cx, zs - 1.0, Y - 3.0)
		kit.pipe(R.to_world(cx, zs + 0.2, Y + 0.9), R.to_world(cx, zs - 1.0, Y + 0.9), 0.45, "cuivre", true)
		kit.pipe(R.to_world(cx, zs - 1.0, Y + 0.9), prev, 0.45, "cuivre", false)
		var z: float = zs - 5.0
		while z > -84.0:
			var w2: Vector3 = R.to_world(cx, z)
			var q := Vector3(w2.x, maxf(ile.height(w2.x, w2.z) + 1.2, PY + 1.2), w2.z)
			kit.pipe(prev, q, 0.45, "cuivre", true)
			prev = q
			z -= 5.0
		kit.pipe(prev, P(cx, -85.5, 1.2), 0.45, "cuivre", true)
	_steam_at(P(54.5, -85.5, 2.0), true)


func _glacis(x: float, x1: float, zs: float) -> void:
	var gz: float = zs
	var steps: int = 0
	while steps < 24:
		var za: float = gz
		var zb: float = gz - 1.5
		var ha0: float = _hw(x, za)
		var hb0: float = _hw(x1, za)
		var ha1: float = _hw(x, zb)
		var hb1: float = _hw(x1, zb)
		var slope: float = ((ha0 + hb0) - (ha1 + hb1)) * 0.5 / 1.5
		if slope < 0.5 and steps > 1:
			break
		var A: Vector3 = R.to_world(x, za, ha0 + 0.3)
		var B: Vector3 = R.to_world(x1, za, hb0 + 0.3)
		var C: Vector3 = R.to_world(x1, zb, hb1 + 0.3)
		var D: Vector3 = R.to_world(x, zb, ha1 + 0.3)
		var n: Vector3 = (B - A).cross(D - A).normalized()
		if n.z > 0.0 or (n.z == 0.0 and n.y < 0.0):
			n = -n
		kit.quad4("talus_cq", A, B, C, D, n, Vector2(x, ha0) * 0.3, Vector2(x1, hb0) * 0.3, Vector2(x1, hb1) * 0.3, Vector2(x, ha1) * 0.3)
		gz = zb
		steps += 1


func _hw(x: float, z: float) -> float:
	var w: Vector3 = R.to_world(x, z)
	return ile.height(w.x, w.z)


func _steam_at(p: Vector3, big: bool = false) -> void:
	_steam_spots.append([p, big])


## La Grande-Place de la Foire : la Machine Universelle et les six stands.
func _place() -> void:
	# la Machine Universelle
	var c: Transform3D = TF(0.0, 0.0)
	kit.cyl(c, 4.6, 4.6, 0.5, "fonte", 24)
	kit.col_cyl(c.origin, 4.6, 0.5)
	kit.ring(c * Transform3D(Basis(), Vector3(0, 0.5, 0)), 4.2, 4.6, 0.4, "laiton", 32)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var px: Vector3 = Vector3(cos(a) * 3.2, 0.5, sin(a) * 3.2)
		kit.cyl(c * Transform3D(Basis(), px), 0.3, 0.26, 7.5, "fer_noir", 10)
		kit.col_cyl(c * px, 0.3, 7.5)
	kit.box(c * Transform3D(Basis(), Vector3(0, 8.1, 0)), Vector3(5.4, 0.4, 5.4), "fonte", 1.5)
	# la chaudière, sa cheminée, ses manomètres
	kit.cyl(c * Transform3D(Basis(), Vector3(0, 0.5, 1.3)), 1.3, 1.3, 2.4, "cuivre", 18)
	kit.dome(c * Transform3D(Basis(), Vector3(0, 2.9, 1.3)), 1.3, "cuivre", 0.6, 18, false)
	kit.cyl(c * Transform3D(Basis(), Vector3(0, 3.6, 1.3)), 0.3, 0.3, 6.5, "fer_noir", 10)
	_steam_at(c * Vector3(0, 10.2, 1.3), true)
	for k2 in range(3):
		kit.cyl(Transform3D(c.basis * Basis(Vector3.RIGHT, PI * 0.5), c * Vector3(-0.6 + k2 * 0.6, 1.9, -0.05)), 0.22, 0.22, 0.1, "laiton", 12)
	kit.pipe(c * Vector3(1.3, 1.2, 1.3), c * Vector3(2.6, 1.2, -1.2), 0.12)
	kit.pipe(c * Vector3(-1.3, 2.0, 1.3), c * Vector3(-2.4, 6.0, -0.5), 0.12)
	# la cloche, sous le plateau
	kit.cyl(c * Transform3D(Basis(), Vector3(0, 6.7, 0)), 0.75, 0.32, 1.0, "laiton", 16)
	# les engrenages géants (ils tournent, et s'entraînent)
	_gear_spin(c * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 5.0, -1.0)), 2.6, 0.35, 16, "laiton", 0.3)
	_gear_spin(c * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(2.55, 3.6, -1.0)), 1.45, 0.3, 9, "cuivre_poli", -0.3 * 16.0 / 9.0)
	_gear_spin(c * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-2.15, 6.6, -1.2)), 1.1, 0.3, 7, "acier", -0.3 * 16.0 / 7.0)
	_gear_spin(c * Transform3D(Basis(), Vector3(0, 8.35, 0)), 2.0, 0.25, 14, "laiton", 0.15)
	_spot("machine_1", -4.5, -6.0, 0.0, 0.0, "observer", "")
	_spot("machine_2", 5.5, -4.5, 0.0, 0.0, "debout", "")
	_spot("machine_3", 4.0, 6.5, 0.0, 0.0, "debout", "")
	# les stands
	var stands := [
		[-26.0, -10.0, -90.0, "piano", "tissu_rouge"], [-26.0, 10.0, -90.0, "bulles", "tissu_bleu"],
		[26.0, -10.0, 90.0, "confettis", "tissu_jaune"], [26.0, 10.0, 90.0, "chien", "tissu_vert"],
		[-12.0, 24.0, 0.0, "echecs", "tissu_bordeaux"], [12.0, 24.0, 0.0, "moteur", "tissu_turquoise"]]
	for i in range(stands.size()):
		var s: Array = stands[i]
		var xf: Transform3D = TF(float(s[0]), float(s[1]), float(s[2]))
		_stand(xf, str(s[3]), str(s[4]))
		var owner: Vector3 = xf * Vector3(0, 0, 1.3)
		var face: Vector3 = xf * Vector3(0, 0, -3.0)
		_spot_w("stand_%d" % (i + 1), owner, face, "crier", "")
		_spot_w("stand_client_%d" % (i + 1), xf * Vector3(0.6, 0, -2.2), xf * Vector3(0, 0, 0), "debout", "")
		_spot_w("stand_client_%db" % (i + 1), xf * Vector3(-1.2, 0, -2.6), xf * Vector3(0, 0, 0), "debout", "")
	# deux colonnes d'affiches, des bancs, des réverbères
	for cp in [Vector2(-18.0, -18.0), Vector2(18.0, -18.0)]:
		var cxf: Transform3D = TF(cp.x, cp.y)
		kit.cyl(cxf, 0.75, 0.75, 3.2, "pierre", 16)
		kit.dome(cxf * Transform3D(Basis(), Vector3(0, 3.2, 0)), 0.9, "cuivre", 0.8, 16)
		kit.col_cyl(cxf.origin, 0.75, 3.2)
		for k3 in range(3):
			var a3: float = TAU * k3 / 3.0
			kit.quad(Transform3D(Basis(Vector3.UP, -a3 + PI * 0.5), cxf * Vector3(cos(a3) * 0.77, 1.7, sin(a3) * 0.77)), 0.9, 1.3, "affiche_" + ["foire", "dirigeable", "telepherique"][k3])
	for bp in [Vector2(-10.0, -14.0), Vector2(10.0, -14.0)]:
		kit.bench(TF(bp.x, bp.y, 0.0))
	_spot("place_banc_1", -10.0, -14.4, -10.0, 0.0, "assis", "")
	_spot("place_banc_2", 10.0, -14.4, 10.0, 0.0, "assis", "")
	_spot("place_enfants_1", -8.0, 8.0, 0.0, 0.0, "jouer", "")
	_spot("place_enfants_2", 8.0, -8.0, 0.0, 0.0, "jouer", "")
	for lp in [Vector2(-30.0, -20.0), Vector2(30.0, -20.0), Vector2(-30.0, 20.0), Vector2(30.0, 20.0)]:
		kit.globe_lamp(T(lp.x, lp.y))


## Les affiches : une texture par affiche (le kit les traite comme des matériaux).
func _poster_mat(name: String) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/cliquetis/" + name + ".png")
	m.roughness = 0.8
	return m


func _stand(xf: Transform3D, kind: String, cloth: String) -> void:
	# le comptoir, les poteaux, la toile rayée
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0.4)), Vector3(3.4, 1.0, 0.9), "bois_sombre", 1.2)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.02, 0.4)), Vector3(3.5, 0.06, 1.0), "laiton", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.5, 0.4)), Vector3(3.4, 1.0, 0.9))
	for sx in [-1.7, 1.7]:
		for sz in [-0.1, 2.2]:
			kit.box(xf * Transform3D(Basis(), Vector3(sx, 1.4, sz)), Vector3(0.1, 2.8, 0.1), "fer_noir", 1.0)
	kit.awning(xf * Transform3D(Basis(), Vector3(0, 2.8, 2.2)), 3.6, 2.4, 0.4, cloth.substr(6))
	kit.box(xf * Transform3D(Basis(), Vector3(0, 2.85, 1.05)), Vector3(3.6, 0.06, 2.4), cloth, 1.0)
	var m: Transform3D = xf * Transform3D(Basis(), Vector3(0, 1.05, 0.4))
	match kind:
		"piano":
			kit.box(m * Transform3D(Basis(), Vector3(0, 0.45, 0.1)), Vector3(1.6, 0.9, 0.6), "bois_sombre", 1.0)
			kit.box(m * Transform3D(Basis(), Vector3(0, 0.92, -0.05)), Vector3(1.5, 0.05, 0.3), "pierre", 1.0)
			_gear_spin(m * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.95, 0.5, 0.1)), 0.35, 0.08, 10, "laiton", 1.0)
			var drum := Node3D.new()
			drum.transform = m * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0, 0.55, -0.3))
			add_child(drum)
			var cm := CylinderMesh.new()
			cm.top_radius = 0.18
			cm.bottom_radius = 0.18
			cm.height = 1.3
			var dmi := MeshInstance3D.new()
			dmi.mesh = cm
			dmi.material_override = kit.mat("laiton")
			drum.add_child(dmi)
			_spin.append([drum, Vector3.UP, 1.6])
		"bulles":
			kit.cyl(m * Transform3D(Basis(), Vector3(0, 0.0, 0.0)), 0.4, 0.35, 0.9, "cuivre", 14)
			kit.dome(m * Transform3D(Basis(), Vector3(0, 0.9, 0)), 0.4, "verriere", 1.0, 12, false)
			kit.pipe(m * Vector3(0, 1.2, 0), m * Vector3(0, 2.0, -0.6), 0.05)
			var bub := _particles("bulles", m * Vector3(0, 2.0, -0.6))
			bub.amount = 26
			bub.lifetime = 5.0
			bub.direction = Vector3(0, 1, -0.4)
			bub.spread = 40.0
			bub.initial_velocity_min = 0.4
			bub.initial_velocity_max = 1.2
			bub.gravity = Vector3(0.15, 0.25, 0)
			bub.scale_amount_min = 0.5
			bub.scale_amount_max = 1.4
		"confettis":
			kit.cyl(Transform3D(m.basis * Basis(Vector3.RIGHT, -0.9), m * Vector3(0, 0.1, 0)), 0.32, 0.26, 1.6, "laiton", 14)
			kit.cyl(m * Transform3D(Basis(), Vector3(0, -0.05, 0)), 0.5, 0.5, 0.18, "fer_noir", 12)
			_confetti = _particles("confettis", m * Vector3(0, 1.4, -1.1))
			_confetti.one_shot = true
			_confetti.emitting = false
			_confetti.amount = 120
			_confetti.lifetime = 4.0
			_confetti.explosiveness = 0.95
			_confetti.direction = (m.basis * Vector3(0, 1, -0.7)).normalized()
			_confetti.spread = 30.0
			_confetti.initial_velocity_min = 6.0
			_confetti.initial_velocity_max = 10.0
			_confetti.gravity = Vector3(0, -2.5, 0)
			_confetti.angular_velocity_min = -300.0
			_confetti.angular_velocity_max = 300.0
			_confetti.scale_amount_min = 0.6
			_confetti.scale_amount_max = 1.2
			_confetti.color_initial_ramp = _confetti_ramp()
		"chien":
			kit.box(m * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.9, 0.5, 0.6), "bois", 1.0)
			_spot_w("chien_niche", xf * Vector3(0, 0, -3.0), xf * Vector3(0, 0, 0), "debout", "")
		"echecs":
			kit.box(m * Transform3D(Basis(), Vector3(0, 0.03, 0)), Vector3(0.8, 0.05, 0.8), "pierre", 0.4)
			for k in range(8):
				for j in range(8):
					if (k + j) % 2 == 0:
						kit.box(m * Transform3D(Basis(), Vector3(-0.35 + k * 0.1, 0.06, -0.35 + j * 0.1)), Vector3(0.1, 0.01, 0.1), "fer_noir", 0.2)
			for k2 in range(10):
				var piece := m * Vector3(-0.35 + (k2 % 8) * 0.1, 0.06, -0.35 + (0.0 if k2 < 8 else 0.1) + (0.6 if k2 % 3 == 0 else 0.0))
				kit.cyl(Transform3D(Basis(), piece), 0.03, 0.02, 0.1, "laiton" if k2 % 2 == 0 else "fer_noir", 6)
			# l'automate : un buste de cuivre, une tête, un bras qui joue
			var auto := m * Transform3D(Basis(), Vector3(0, 0, 0.6))
			kit.cyl(auto, 0.28, 0.22, 0.8, "cuivre", 12)
			kit.dome(auto * Transform3D(Basis(), Vector3(0, 0.8, 0)), 0.22, "laiton", 1.3, 12, false)
			var arm := Node3D.new()
			arm.transform = auto * Transform3D(Basis(), Vector3(0.3, 0.6, 0))
			add_child(arm)
			var am := CylinderMesh.new()
			am.top_radius = 0.04
			am.bottom_radius = 0.04
			am.height = 0.6
			var ami := MeshInstance3D.new()
			ami.mesh = am
			ami.material_override = kit.mat("acier")
			ami.position = Vector3(0, -0.15, -0.25)
			ami.rotation.x = 1.0
			arm.add_child(ami)
			_spin.append([arm, Vector3.UP, -0.6, "oscille"])
		"moteur":
			# la roue à balourd (le moteur « perpétuel ») : elle tourne, et ne s'arrête jamais
			var wheel := Node3D.new()
			wheel.transform = m * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.1, 0.0))
			add_child(wheel)
			var gm: ArrayMesh = kit.gear_mesh(1.0, 0.1, 12, "laiton")
			var gmi := MeshInstance3D.new()
			gmi.mesh = gm
			wheel.add_child(gmi)
			for k3 in range(8):
				var a: float = TAU * k3 / 8.0
				var sm := SphereMesh.new()
				sm.radius = 0.1
				sm.height = 0.2
				var bmi := MeshInstance3D.new()
				bmi.mesh = sm
				bmi.material_override = kit.mat("acier")
				bmi.position = Vector3(cos(a) * 0.85, 0.1, sin(a) * 0.85)
				wheel.add_child(bmi)
			_spin.append([wheel, Vector3.UP, 0.9])
			for s2 in [-1.0, 1.0]:
				kit.box(m * Transform3D(Basis(), Vector3(s2 * 0.2, 0.55, 0)), Vector3(0.08, 1.1, 0.08), "fer_noir", 1.0)


func _confetti_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 0.2, 0.3), Color(1, 0.85, 0.2), Color(0.2, 0.7, 1), Color(0.4, 0.9, 0.4), Color(0.9, 0.4, 1), Color(1, 0.5, 0.1)])
	return g


## Des particules : vapeur (fumées), bulles (sphères irisées), confettis (petits carrés).
func _particles(kind: String, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	var mesh: Mesh
	var m := StandardMaterial3D.new()
	match kind:
		"bulles":
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			sm.radial_segments = 10
			sm.rings = 5
			m.albedo_color = Color(0.8, 0.9, 1.0, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.metallic_specular = 1.0
			m.roughness = 0.0
			m.rim_enabled = true
			m.rim = 1.0
			mesh = sm
		"confettis":
			var qm := QuadMesh.new()
			qm.size = Vector2(0.08, 0.05)
			m.vertex_color_use_as_albedo = true
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh = qm
		_:
			var qm2 := QuadMesh.new()
			m.albedo_color = Color(0.92, 0.92, 0.92, 0.32)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			var tex := GradientTexture2D.new()
			tex.fill = GradientTexture2D.FILL_RADIAL
			tex.fill_from = Vector2(0.5, 0.5)
			tex.fill_to = Vector2(0.5, 0.0)
			var g := Gradient.new()
			g.set_color(0, Color(1, 1, 1, 1))
			g.set_color(1, Color(1, 1, 1, 0))
			tex.gradient = g
			m.albedo_texture = tex
			m.vertex_color_use_as_albedo = kind == "fumee_couleur"
			mesh = qm2
	(mesh as PrimitiveMesh).material = m
	p.mesh = mesh
	add_child(p)
	return p


func _gear_spin(xf: Transform3D, r: float, thick: float, teeth: int, key: String, speed: float) -> void:
	var n := Node3D.new()
	n.transform = xf
	add_child(n)
	var mi := MeshInstance3D.new()
	mi.mesh = kit.gear_mesh(r, thick, teeth, key)
	n.add_child(mi)
	_spin.append([n, Vector3.UP, speed])


## L'Académie des Ingénieurs et sa grande horloge.
func _academie() -> void:
	var xf: Transform3D = TF(0.0, 34.0)
	kit.workshop(xf, 34.0, 13.0, 11.0, {"cheminee": false, "porte_x": 0.0, "mur": "brique", "toit": "ardoise"})
	_sign(xf * Transform3D(Basis(), Vector3(-9.0, 3.4, -0.12)), 3.6, 1.8, "enseigne_foire")
	# la tour de l'horloge, devant le milieu de la façade
	var txf: Transform3D = TF(0.0, 37.0)
	kit.box(txf * Transform3D(Basis(), Vector3(0, 11.0, 0)), Vector3(6.0, 22.0, 6.0), "brique", 3.0)
	kit.col_box(txf * Transform3D(Basis(), Vector3(0, 11.0, 0)), Vector3(6.0, 22.0, 6.0))
	kit.box(txf * Transform3D(Basis(), Vector3(0, 22.2, 0)), Vector3(6.6, 0.5, 6.6), "pierre", 1.5)
	kit.box(txf * Transform3D(Basis(), Vector3(0, 24.4, 0)), Vector3(5.0, 4.0, 5.0), "cuivre", 2.0)
	kit.dome(txf * Transform3D(Basis(), Vector3(0, 26.4, 0)), 2.7, "cuivre", 1.4, 20)
	for k in range(4):
		var a: float = PI * 0.5 * k
		var face := txf * Transform3D(Basis(Vector3.UP, a), Vector3(0, 18.0, -3.02))
		kit.quad(face, 4.6, 4.6, "cadran")
		var hands: Array = []
		for hl in [[1.35, 0.22], [2.0, 0.13]]:
			var piv := Node3D.new()
			piv.transform = face * Transform3D(Basis(), Vector3(0, 0, -0.06))
			add_child(piv)
			var hm := BoxMesh.new()
			hm.size = Vector3(float(hl[1]), float(hl[0]), 0.04)
			var hmi := MeshInstance3D.new()
			hmi.mesh = hm
			hmi.material_override = kit.mat("fer_noir")
			hmi.position = Vector3(0, float(hl[0]) * 0.42, 0)
			piv.add_child(hmi)
			hands.append(piv)
		_clock_hands.append(hands)
	# le grand engrenage décoratif sur la façade
	_gear_spin(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(10.0, 6.5, -0.3)), 2.4, 0.3, 16, "laiton", 0.12)
	_gear_spin(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(12.85, 4.2, -0.3)), 1.2, 0.3, 8, "cuivre_poli", -0.24)
	points["porte_academie"] = xf * Vector3(0, 0, -1.4)
	_spot("academie_porte", 3.0, 31.5, 3.0, 20.0, "bras_croises", "")
	_spot("horloge", -4.2, 33.0, -4.2, 37.0, "bricoler", "")


func _sign(xf: Transform3D, w: float, h: float, file: String) -> void:
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0, 0.05)), Vector3(w * 0.96, h * 0.9, 0.06), "laiton", 1.0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/cliquetis/" + file + ".png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.roughness = 0.5
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.name = "Enseigne_" + file
	mi.mesh = qm
	mi.material_override = m
	mi.transform = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.01))
	add_child(mi)


## Le Café de la Bielle : une terrasse, un comptoir sous l'auvent, des chambres à ressorts.
func _cafe() -> void:
	var xf: Transform3D = TF(-58.0, -6.0, -90.0)
	kit.workshop(xf, 15.0, 10.0, 7.5, {"porte_x": 3.0, "dome": true, "cheminee_h": 4.0})
	_sign(xf * Transform3D(Basis(), Vector3(-2.0, 3.9, -0.12)), 3.6, 1.8, "enseigne_bielle")
	kit.awning(xf * Transform3D(Basis(), Vector3(-2.5, 3.0, 0)), 9.0, 2.6, 0.6, "vert")
	# le comptoir en plein air, sous l'auvent
	var bx: Transform3D = xf * Transform3D(Basis(), Vector3(-3.5, 0, -1.3))
	kit.box(bx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(4.0, 1.1, 0.7), "laiton", 1.0)
	kit.box(bx * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(4.2, 0.06, 0.9), "bois_sombre", 1.0)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(4.0, 1.1, 0.7))
	# la machine à café : une chaudière de cuivre, trois becs, un manomètre
	var mc: Transform3D = bx * Transform3D(Basis(), Vector3(1.2, 1.16, 0.1))
	kit.cyl(mc, 0.32, 0.32, 0.8, "cuivre_poli", 14)
	kit.dome(mc * Transform3D(Basis(), Vector3(0, 0.8, 0)), 0.32, "laiton", 1.0, 12)
	_steam_at(mc * Vector3(0, 1.5, 0))
	_spot_w("cafe_comptoir", bx * Vector3(0, 0.0, 0.8), bx * Vector3(0, 0, -2.0), "comptoir", "")
	_spot_w("cafe_bar_1", bx * Vector3(-1.0, 0.0, -0.9), bx * Vector3(-1.0, 0, 0), "boire", "")
	_spot_w("cafe_bar_2", bx * Vector3(1.0, 0.0, -0.9), bx * Vector3(1.0, 0, 0), "boire", "")
	# la terrasse
	var tables := [Vector2(-50.0, -12.0), Vector2(-50.0, -4.0), Vector2(-50.0, 4.0), Vector2(-45.5, -8.0)]
	for i in range(tables.size()):
		var tp: Vector2 = tables[i]
		kit.cafe_table(T(tp.x, tp.y), 0.4 * i, 2, "")
		_spot("cafe_table_%d" % (i + 1), tp.x - 0.62 * cos(0.3 + 0.4 * i) * 0.0 - 0.6, tp.y, tp.x, tp.y, "assis", "")
	points["porte_cafe"] = xf * Vector3(3.0, 0, -1.2)
	_spot("cafe_majordome", -52.0, -6.0, -50.0, -6.0, "debout", "")


## Le Bazar des Inutilités, en face.
func _bazar() -> void:
	var xf: Transform3D = TF(58.0, -6.0, 90.0)
	kit.workshop(xf, 13.0, 10.0, 7.0, {"porte_x": -2.5, "dome": true, "cheminee": false, "mur": "brique_sombre"})
	_sign(xf * Transform3D(Basis(), Vector3(2.0, 3.8, -0.12)), 3.6, 1.8, "enseigne_bazar")
	kit.awning(xf * Transform3D(Basis(), Vector3(1.5, 3.0, 0)), 7.0, 2.2, 0.6, "bordeaux")
	# l'étal : des curiosités entassées
	var bx: Transform3D = xf * Transform3D(Basis(), Vector3(2.0, 0, -1.2))
	kit.box(bx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.6, 1.0, 0.8), "bois_sombre", 1.0)
	kit.col_box(bx * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.6, 1.0, 0.8))
	for k in range(14):
		var p: Vector3 = bx * Vector3(-1.6 + k * 0.24, 1.05, kit.rng.randf_range(-0.25, 0.25))
		match k % 4:
			0:
				kit.gear(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), p + Vector3.UP * 0.12), 0.12, 0.03, 8, "laiton")
			1:
				kit.cyl(Transform3D(Basis(), p), 0.07, 0.06, 0.16, "cuivre_poli", 8)
			2:
				kit.box(Transform3D(Basis(Vector3.UP, kit.rng.randf()), p + Vector3.UP * 0.07), Vector3(0.16, 0.14, 0.12), "bois", 0.5)
			3:
				kit.cyl(Transform3D(Basis(), p), 0.09, 0.02, 0.2, "tissu_rouge", 8)
	_spot_w("bazar_comptoir", bx * Vector3(0, 0, 0.9), bx * Vector3(0, 0, -2.0), "comptoir", "")
	_spot_w("bazar_client", bx * Vector3(0.6, 0, -1.4), bx * Vector3(0, 0, 0), "debout", "")
	points["porte_bazar"] = xf * Vector3(-2.5, 0, -1.2)


## L'Atelier du professeur Boum (ça explose), près des falaises.
func _boum() -> void:
	var xf: Transform3D = TF(-84.0, -24.0, -90.0)
	kit.workshop(xf, 12.0, 11.0, 6.5, {"porte_x": 2.5, "toit": "plat", "cheminee_h": 7.0})
	_sign(xf * Transform3D(Basis(), Vector3(-2.0, 3.5, -0.12)), 3.4, 1.7, "enseigne_boum")
	# des débris, des bidons, un panneau de danger
	for k in range(6):
		var p: Vector3 = xf * Vector3(kit.rng.randf_range(-5.0, 5.0), 0, kit.rng.randf_range(-4.0, -1.5))
		if k % 2 == 0:
			kit.barrel(p)
		else:
			kit.crate(p, kit.rng.randf() * TAU, 0.6)
	_boum_at = xf * Vector3(0, 7.2, 5.5)
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.6, 0.25)
	fl.omni_range = 26.0
	fl.light_energy = 0.0
	fl.position = _boum_at
	add_child(fl)
	_boum_fx = [fl]
	for c in [Color(0.95, 0.35, 0.9, 0.55), Color(0.3, 0.95, 0.4, 0.55), Color(1.0, 0.85, 0.2, 0.55)]:
		var pp := _particles("fumee", _boum_at)
		pp.one_shot = true
		pp.emitting = false
		pp.amount = 30
		pp.lifetime = 4.0
		pp.explosiveness = 0.9
		pp.direction = Vector3(0, 1, 0)
		pp.spread = 70.0
		pp.initial_velocity_min = 3.0
		pp.initial_velocity_max = 7.0
		pp.gravity = Vector3(0, -0.6, 0)
		pp.damping_min = 1.5
		pp.damping_max = 2.5
		pp.scale_amount_min = 1.5
		pp.scale_amount_max = 3.5
		pp.color = c
		var mm: StandardMaterial3D = (pp.mesh as PrimitiveMesh).material
		mm.vertex_color_use_as_albedo = true
		mm.albedo_color = Color(1, 1, 1, 0.6)
		_boum_fx.append(pp)
	_spot("boum_atelier", -77.0, -27.0, -70.0, -27.0, "bricoler", "")
	_spot("boum_debris", -76.0, -19.0, -84.0, -19.0, "bras_croises", "")
	points["porte_boum"] = xf * Vector3(2.5, 0, -1.2)


## Le laboratoire Volta et ses deux bobines de Tesla.
func _volta() -> void:
	var xf: Transform3D = TF(80.0, 20.0, 90.0)
	kit.workshop(xf, 14.0, 13.0, 8.0, {"porte_x": 0.0, "toit": "verriere", "cheminee": false})
	for cp in [Vector2(72.0, 38.0), Vector2(92.0, 38.0)]:
		_tesla_tops.append(kit.tesla_coil(TF(cp.x, cp.y), 11.0))
	_arc_mesh = ImmediateMesh.new()
	_arc_mi = MeshInstance3D.new()
	_arc_mi.mesh = _arc_mesh
	var am := StandardMaterial3D.new()
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	am.albedo_color = Color(0.75, 0.9, 1.0)
	am.emission_enabled = true
	am.emission = Color(0.6, 0.85, 1.0)
	am.emission_energy_multiplier = 4.0
	_arc_mi.material_override = am
	_arc_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_arc_mi)
	_arc_light = OmniLight3D.new()
	_arc_light.light_color = Color(0.55, 0.8, 1.0)
	_arc_light.omni_range = 30.0
	_arc_light.light_energy = 0.0
	_arc_light.position = (_tesla_tops[0] + _tesla_tops[1]) * 0.5
	add_child(_arc_light)
	# deux réverbères de part et d'autre des bobines (la nuit, on les voit)
	for lp in [Vector2(66.0, 34.0), Vector2(98.0, 34.0)]:
		kit.globe_lamp(T(lp.x, lp.y))
	_arc_light.light_energy = 0.0
	_spot("volta_1", 82.0, 33.0, 82.0, 38.0, "observer", "")
	_spot("volta_2", 76.0, 21.0, 70.0, 21.0, "bricoler", "")
	points["porte_volta"] = xf * Vector3(0, 0, -1.2)


func _observatoire() -> void:
	var xf: Transform3D = TF(84.0, -28.0)
	kit.round_tower(xf, 4.2, 9.0, "dome")
	# la lunette, qui sort de la fente de la coupole
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, -0.7), xf * Vector3(0, 13.0, -1.0)), 0.35, 0.28, 4.0, "laiton", 14)
	_spot("observatoire", 79.0, -30.0, 84.0, -40.0, "observer", "")
	points["porte_observatoire"] = xf * Vector3(0, 0, -5.4)


func _fabrique() -> void:
	var xf: Transform3D = TF(-40.0, 37.0)
	var o := {"porte_x": 0.0, "toit": "verriere", "cheminee_h": 8.0}
	kit.workshop(xf, 20.0, 11.0, 8.5, o)
	for s in o["_fumees"]:
		_steam_at(s, true)
	_gear_spin(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-6.0, 5.8, -0.3)), 1.8, 0.3, 12, "cuivre_poli", 0.4)
	# l'établi devant, un robot à moitié monté
	var bxf: Transform3D = xf * Transform3D(Basis(), Vector3(5.0, 0, -2.0))
	kit.box(bxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.9, 1.0), "bois_sombre", 1.0)
	kit.col_box(bxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.9, 1.0))
	kit.cyl(bxf * Transform3D(Basis(), Vector3(-0.5, 0.9, 0)), 0.25, 0.2, 0.6, "cuivre", 10)
	kit.dome(bxf * Transform3D(Basis(), Vector3(0.5, 0.9, 0)), 0.22, "laiton", 1.0, 10, false)
	_spot_w("fabrique_1", bxf * Vector3(0, 0, -0.9), bxf * Vector3(0, 0, 0), "bricoler", "")
	_spot_w("fabrique_2", bxf * Vector3(-1.6, 0, -0.4), bxf * Vector3(0, 0, 0), "bricoler", "")
	points["porte_fabrique"] = xf * Vector3(0, 0, -1.2)


## Les maisons-ateliers (chaque porte est un point « porte_maison_n »).
const HOUSES := [
	# x, z, rotation, largeur, profondeur, hauteur, options
	[-80.0, -4.0, -90.0, 13.0, 10.0, 7.0, {"citerne": true}],
	[-64.0, 38.0, 0.0, 11.0, 9.0, 7.5, {"dome": true}],
	[18.0, 36.0, 0.0, 10.0, 10.0, 6.5, {"porte_x": 2.0}],
	[34.0, 37.0, 0.0, 13.0, 10.0, 8.0, {"citerne": true}],
	[52.0, 37.0, 0.0, 11.0, 10.0, 7.0, {"dome": true, "porte_x": -2.0}],
	[-22.0, 37.0, 0.0, 9.0, 10.0, 6.5, {}],
	[80.0, -8.0, 90.0, 12.0, 10.0, 7.0, {"dome": true}],
	[-92.0, 30.0, -90.0, 12.0, 8.0, 7.0, {}],
	[40.0, -30.0, 0.0, 10.0, 8.0, 6.0, {"porte_x": 2.0, "dome": true}],
	[-56.0, -30.0, 0.0, 11.0, 8.0, 6.5, {"citerne": true}],
	[92.0, 6.0, 90.0, 9.0, 8.0, 6.0, {}],
	[-40.0, 22.0, 0.0, 8.0, 7.0, 5.5, {"cheminee": true}],
]


func _houses() -> void:
	for i in range(HOUSES.size()):
		var h: Array = HOUSES[i]
		var o: Dictionary = (h[6] as Dictionary).duplicate()
		o["porte_x"] = o.get("porte_x", 0.0)
		o["v81"] = true
		var door: Vector3 = kit.workshop(TF(float(h[0]), float(h[1]), float(h[2])), float(h[3]), float(h[4]), float(h[5]), o)
		points["porte_maison_%d" % i] = door
		for s in o.get("_fumees", []):
			_steam_at(s)
	# le château d'eau, sur ses pieds de fonte
	var wxf: Transform3D = TF(-46.0, 12.0)
	for s2 in [Vector3(-1.6, 0, -1.6), Vector3(1.6, 0, -1.6), Vector3(-1.6, 0, 1.6), Vector3(1.6, 0, 1.6)]:
		kit.box(wxf * Transform3D(Basis(), s2 + Vector3(0, 4.0, 0)), Vector3(0.24, 8.0, 0.24), "fer_noir", 1.0)
		kit.col_box(wxf * Transform3D(Basis(), s2 + Vector3(0, 4.0, 0)), Vector3(0.24, 8.0, 0.24))
	kit.cyl(wxf * Transform3D(Basis(), Vector3(0, 8.0, 0)), 2.6, 2.6, 3.6, "cuivre", 20)
	kit.dome(wxf * Transform3D(Basis(), Vector3(0, 11.6, 0)), 2.6, "cuivre", 0.45, 20)
	kit.pipe(wxf * Vector3(0, 0, 0), wxf * Vector3(0, 8.0, 0), 0.18, "cuivre_poli", false)


## L'aérodrome du Zéphyr : l'aire de fonte, le mât d'amarrage, l'enseigne, un banc.
func _aerodrome() -> void:
	var c: Vector3 = R.PADS[0][0]
	var cl: Vector2 = R.to_city(c.x, c.z)
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * 0.0), 12.0, 12.0, 0.08, "fonte", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.08), 11.0, 11.6, 0.02, "laiton", 48)
	var mxf: Transform3D = TF(cl.x - 15.0, cl.y)
	for s in [Vector3(-1.0, 0, -1.0), Vector3(1.0, 0, -1.0), Vector3(-1.0, 0, 1.0), Vector3(1.0, 0, 1.0)]:
		kit.pipe(mxf * s, mxf * Vector3(s.x * 0.25, 16.0, s.z * 0.25), 0.1, "fer_noir", false)
	kit.cyl(mxf * Transform3D(Basis(), Vector3(0, 16.0, 0)), 0.6, 0.4, 1.0, "cuivre", 12)
	kit.col_box(mxf * Transform3D(Basis(), Vector3(0, 8.0, 0)), Vector3(2.0, 16.0, 2.0))
	var sxf: Transform3D = TF(cl.x - 2.0, cl.y + 13.5, 0.0)
	kit.box(sxf * Transform3D(Basis(), Vector3(0, 1.5, 0)), Vector3(0.12, 3.0, 0.12), "fer_noir", 1.0)
	_sign(sxf * Transform3D(Basis(), Vector3(0, 3.2, -0.1)), 3.0, 1.5, "enseigne_aerodrome")
	kit.bench(TF(cl.x + 6.0, cl.y + 13.0, 180.0))
	_spot("aerodrome_1", cl.x - 4.0, cl.y + 12.5, cl.x, cl.y, "bras_croises", "")
	_spot("aerodrome_banc", cl.x + 6.0, cl.y + 13.4, cl.x + 6.0, cl.y - 20.0, "observer", "")


## Le port : le quai de fonte, l'entrepôt, la capitainerie, la grue, le remorqueur à vapeur,
## le ponton de la barque, la gare basse du téléphérique.
func _port() -> void:
	var r: Rect2 = R.PORT
	# le mur du quai
	kit.box(PF((r.position.x + r.end.x) * 0.5, r.position.y - 0.35, 0.0, -3.0), Vector3(r.size.x, 8.8, 0.7), "moellons", 2.0, 63 - 8)
	var x: float = r.position.x + 4.0
	while x < r.end.x - 2.0:
		kit.bollard(P(x, r.position.y + 0.8))
		x += 9.0
	# l'entrepôt des Brevets et la capitainerie, adossés à la falaise
	kit.workshop(PF(-44.0, -88.0, 0.0), 14.0, 4.5, 6.0, {"porte_x": 2.0, "toit": "plat", "cheminee": false})
	var o := {"porte_x": 0.0, "dome": true}
	kit.workshop(PF(42.0, -88.0, 0.0), 9.0, 4.5, 5.5, o)
	for s in o["_fumees"]:
		_steam_at(s)
	points["porte_capitainerie_port"] = P(42.0, -89.2)
	points["porte_entrepot"] = P(-42.0, -89.2)
	# la grue, sa flèche qui pivote lentement
	var gx: Transform3D = PF(8.0, -94.0)
	for s2 in [Vector3(-1.2, 0, -1.2), Vector3(1.2, 0, -1.2), Vector3(-1.2, 0, 1.2), Vector3(1.2, 0, 1.2)]:
		kit.pipe(gx * s2, gx * Vector3(s2.x * 0.4, 10.0, s2.z * 0.4), 0.12, "fer_noir", false)
	kit.col_box(gx * Transform3D(Basis(), Vector3(0, 5.0, 0)), Vector3(2.6, 10.0, 2.6))
	_crane_jib = Node3D.new()
	_crane_jib.position = gx * Vector3(0, 10.0, 0)
	add_child(_crane_jib)
	var parts := [[Vector3(0, 0.6, 0), Vector3(2.0, 1.2, 2.0), "cuivre"], [Vector3(0, 1.4, -6.0), Vector3(0.6, 0.6, 14.0), "fer_noir"], [Vector3(0, 1.1, 3.4), Vector3(1.4, 1.4, 1.6), "fonte"]]
	for pr in parts:
		var bm := BoxMesh.new()
		bm.size = pr[1]
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		mi.material_override = kit.mat(str(pr[2]))
		mi.position = pr[0]
		_crane_jib.add_child(mi)
	var hook := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.03
	hm.bottom_radius = 0.03
	hm.height = 7.0
	hook.mesh = hm
	hook.material_override = kit.mat("fer_noir")
	hook.position = Vector3(0, -2.0, -12.0)
	_crane_jib.add_child(hook)
	var crate := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(1.2, 0.9, 1.2)
	crate.mesh = cb
	crate.material_override = kit.mat("bois")
	crate.position = Vector3(0, -5.8, -12.0)
	_crane_jib.add_child(crate)
	_spot("port_grue", 10.5, -92.0, 8.0, -94.0, "bricoler", "")
	# le remorqueur à vapeur « le Petit Piston », amarré
	var tug: Transform3D = PF(52.0, -103.0, 90.0, -1.9)
	kit.box(tug * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(3.6, 1.8, 11.0), "peinture_rouge", 2.0)
	kit.box(tug * Transform3D(Basis(), Vector3(0, 1.55, 0)), Vector3(3.7, 0.12, 11.2), "bois", 2.0)
	kit.box(tug * Transform3D(Basis(), Vector3(0, 2.6, 1.5)), Vector3(2.6, 2.0, 3.6), "cuivre", 2.0)
	kit.cyl(tug * Transform3D(Basis(), Vector3(0, 3.6, -0.8)), 0.45, 0.45, 3.0, "fer_noir", 12)
	kit.cyl(tug * Transform3D(Basis(), Vector3(0, 6.6, -0.8)), 0.5, 0.5, 0.4, "peinture_rouge", 12)
	_steam_at(tug * Vector3(0, 7.2, -0.8))
	for s3 in [-1.0, 1.0]:
		kit.cyl(Transform3D(tug.basis * Basis(Vector3(0, 0, 1), PI * 0.5), tug * Vector3(s3 * 1.85, 0.6, -1.0)), 1.5, 1.5, 0.5 * s3, "bois_sombre", 14)
	kit.col_box(tug * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(3.6, 3.0, 11.0))
	# le ponton de la barque, la gare basse du téléphérique
	boat_dock = [P(DOCK_X, r.position.y - 0.2, -0.4), P(DOCK_X, r.position.y - 15.0, -0.4)]
	var bs: Vector3 = P(TEL_BOTTOM.x, TEL_BOTTOM.y)
	_station(bs, false)
	_station(T(TEL_TOP.x, TEL_TOP.y), true)
	kit.globe_lamp(P(-10.0, -86.5))
	kit.globe_lamp(P(26.0, -86.5))
	kit.globe_lamp(P(60.0, -86.5))
	for k in range(3):
		_spot("port_quai_%d" % (k + 1), -30.0 + k * 28.0, -93.0, -30.0 + k * 28.0, -110.0, "debout", "")
	_spot("port_peche_1", -50.0, -96.6, -50.0, -110.0, "assis", "")
	_spot("port_peche_2", 66.0, -96.6, 66.0, -110.0, "assis", "")
	_spot("telepherique_haut", TEL_TOP.x + 3.8, TEL_TOP.y + 1.5, TEL_TOP.x, TEL_TOP.y, "bras_croises", "")
	_spot("telepherique_bas", TEL_BOTTOM.x + 3.5, TEL_BOTTOM.y + 1.0, TEL_BOTTOM.x, TEL_BOTTOM.y, "bras_croises", "", PY - Y)
	objets["engrenage_or"] = P(13.0, -95.5, 0.12)


## Une gare de téléphérique : plate-forme de fonte, portique, toit de cuivre.
func _station(at: Vector3, high: bool) -> void:
	var xf := Transform3D(Basis(), at)
	kit.box(xf * Transform3D(Basis(), Vector3(0, -0.15, 0)), Vector3(6.0, 0.3, 5.0), "fonte", 1.5)
	for s in [Vector3(-2.8, 0, -2.3), Vector3(2.8, 0, -2.3), Vector3(-2.8, 0, 2.3), Vector3(2.8, 0, 2.3)]:
		kit.box(xf * Transform3D(Basis(), s + Vector3(0, 2.8, 0)), Vector3(0.22, 5.6, 0.22), "fer_noir", 1.0)
		kit.col_box(xf * Transform3D(Basis(), s + Vector3(0, 2.8, 0)), Vector3(0.22, 5.6, 0.22))
	kit.box(xf * Transform3D(Basis(), Vector3(0, 5.7, 0)), Vector3(6.4, 0.3, 5.4), "cuivre", 2.0)
	kit.dome(xf * Transform3D(Basis(), Vector3(0, 5.85, 0)), 2.0, "cuivre", 0.5, 16)
	if high:
		kit.box(xf * Transform3D(Basis(), Vector3(0, -2.0, 0)), Vector3(6.0, 4.0, 5.0), "brique", 2.0, 63 - 4)
		kit.col_box(xf * Transform3D(Basis(), Vector3(0, -2.0, 0)), Vector3(6.0, 4.0, 5.0))
	kit.globe_lamp(at + Vector3(2.4, 0, 2.0), 3.4)


## La route en lacet, du port à la cité : un parapet de pierre côté vide.
func _road() -> void:
	var pts: Array = R.ROAD
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n: int = int(Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) / 3.0)
		for k in range(n):
			var t0: float = float(k) / n
			var t1: float = float(k + 1) / n
			var p0: Vector3 = a.lerp(b, t0)
			var p1: Vector3 = a.lerp(b, t1)
			var d := Vector3(p1.x - p0.x, 0, p1.z - p0.z).normalized()
			var side: Vector3 = d.cross(Vector3.UP).normalized() * R.ROAD_W
			var w0: Vector3 = R.to_world(p0.x, p0.z, p0.y + 0.04)
			var w1: Vector3 = R.to_world(p1.x, p1.z, p1.y + 0.04)
			kit.quad4("paves", w0 - side, w0 + side, w1 + side, w1 - side, Vector3.UP, Vector2(0, t0 * 8.0), Vector2(1.6, t0 * 8.0), Vector2(1.6, t1 * 8.0), Vector2(0, t1 * 8.0))
		var wa: Vector3 = R.to_world(a.x, a.z, a.y)
		var wb: Vector3 = R.to_world(b.x, b.z, b.y)
		var dd := Vector3(wb.x - wa.x, 0, wb.z - wa.z).normalized()
		var off: Vector3 = dd.cross(Vector3.UP).normalized() * (R.ROAD_W + 0.3) * (1.0 if i == 0 else -1.0)
		kit.iron_rail(wa + off, wb + off, 1.0)


func _monorail() -> void:
	var n: int = 72
	for i in range(n):
		var a: float = TAU * i / n
		_rail_pts.append(T(cos(a) * RAIL_RX, sin(a) * RAIL_RZ, RAIL_H))
	for i in range(n):
		var p0: Vector3 = _rail_pts[i]
		var p1: Vector3 = _rail_pts[(i + 1) % n]
		var d: Vector3 = (p1 - p0)
		var bas := Basis.looking_at(d.normalized(), Vector3.UP)
		kit.box(Transform3D(bas, (p0 + p1) * 0.5), Vector3(0.6, 0.7, d.length() + 0.05), "fonte", 1.0)
		kit.box(Transform3D(bas, (p0 + p1) * 0.5 + Vector3.UP * 0.4), Vector3(0.2, 0.12, d.length() + 0.05), "laiton", 1.0)
		if i % 6 == 0:
			var g: Vector3 = p0 - Vector3.UP * RAIL_H
			kit.cyl(Transform3D(Basis(), g), 0.35, 0.28, RAIL_H - 0.35, "fer_noir", 10)
			kit.col_cyl(g, 0.35, RAIL_H)
			kit.box(Transform3D(bas, p0 - Vector3.UP * 0.5), Vector3(1.2, 0.3, 1.2), "laiton", 1.0)
	kit.commit()
	# le train : trois voitures de cuivre et de verre, suspendues sous le rail
	for k in range(3):
		var car := Node3D.new()
		car.name = "Monorail_%d" % k
		add_child(car)
		var body := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 1.0
		cm.height = 4.6
		body.mesh = cm
		body.rotation.x = PI * 0.5
		body.position = Vector3(0, -1.4, 0)
		body.material_override = kit.mat("cuivre")
		car.add_child(body)
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(2.06, 0.6, 3.2)
		win.mesh = wm
		win.position = Vector3(0, -1.2, 0)
		win.material_override = kit.mat("vitre_lumiere")
		car.add_child(win)
		var hang := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.3, 0.9, 1.4)
		hang.mesh = hm
		hang.position = Vector3(0, -0.2, 0)
		hang.material_override = kit.mat("fer_noir")
		car.add_child(hang)
		_train.append(car)


func _steam_all() -> void:
	for s in _steam_spots:
		var p := _particles("fumee", s[0])
		var big: bool = bool(s[1])
		p.amount = (18 if big else 10) if pc else 6
		p.lifetime = 5.0 if big else 3.5
		p.direction = Vector3(0, 1, 0)
		p.spread = 10.0
		p.initial_velocity_min = 0.8
		p.initial_velocity_max = 1.5
		p.gravity = Vector3(0.35, 0.18, 0.1)
		p.scale_amount_min = 1.0 if big else 0.6
		p.scale_amount_max = 3.0 if big else 1.8


# =================================================================== les gens : lieux et chemins

func _spot(name: String, x: float, z: float, fx: float, fz: float, pose: String, node: String, dy: float = 0.0) -> void:
	spots[name] = {"pos": T(x, z, dy), "face": T(fx, fz, dy), "pose": pose, "node": node}


func _spot_w(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
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


## V77 : les rues du milieu et du nord-sud se croisaient au centre de la Machine Universelle (les
## habitants traversaient sa chaudière) : les nœuds qui tombaient sur son socle passent sur un anneau
## autour d'elle, et l'on fait le tour.
func _detour_machine() -> void:
	var c: Vector3 = T(0.0, 0.0)
	var r_ring: float = 6.4
	var ring: Array = []
	for k in points.keys():
		var p: Vector3 = points[k]
		var d := Vector2(p.x - c.x, p.z - c.z)
		if d.length() < 5.9 and graph.has(k):
			var a: float = atan2(d.y, d.x) if d.length() > 0.1 else 0.0
			points[k] = Vector3(c.x + cos(a) * r_ring, c.y, c.z + sin(a) * r_ring)
			ring.append(k)
	for a2 in ring:
		for b2 in ring:
			if a2 != b2 and (graph[a2] as Array).has(b2):
				(graph[a2] as Array).erase(b2)
	for i in range(8):
		var an: float = TAU * i / 8.0 + PI / 8.0
		var nm: String = "machine_%d" % i
		points[nm] = Vector3(c.x + cos(an) * r_ring, c.y, c.z + sin(an) * r_ring)
		ring.append(nm)
	ring.sort_custom(func(x, y): return atan2((points[x] as Vector3).z - c.z, (points[x] as Vector3).x - c.x) < atan2((points[y] as Vector3).z - c.z, (points[y] as Vector3).x - c.x))
	for i in range(ring.size()):
		_link(str(ring[i]), str(ring[(i + 1) % ring.size()]))


func _chain(names: Array) -> void:
	for i in range(names.size() - 1):
		_link(names[i], names[i + 1])


func _street(prefix: String, a: Vector2, b: Vector2, step: float, y_port: bool = false) -> Array:
	var names: Array = []
	var n: int = maxi(1, int(a.distance_to(b) / step))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / n)
		var nm: String = "%s%d" % [prefix, i]
		points[nm] = P(p.x, p.y) if y_port else T(p.x, p.y)
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
	# la promenade, les rues autour de la place, les allées vers les bâtiments
	var prom: Array = _street("pr", Vector2(-96.0, -36.0), Vector2(96.0, -36.0), 8.0)
	var south: Array = _street("su", Vector2(-96.0, 28.0), Vector2(96.0, 28.0), 8.0)
	var west: Array = _street("we", Vector2(-44.0, -34.0), Vector2(-44.0, 28.0), 7.0)
	var east: Array = _street("ea", Vector2(44.0, -34.0), Vector2(44.0, 28.0), 7.0)
	var mid: Array = _street("mi", Vector2(-44.0, 0.0), Vector2(44.0, 0.0), 7.0)
	var nsx: Array = _street("ns", Vector2(0.0, -34.0), Vector2(0.0, 28.0), 6.0)
	var w2: Array = _street("wx", Vector2(-70.0, -34.0), Vector2(-70.0, 6.0), 7.0)
	var e2: Array = _street("ex", Vector2(70.0, -34.0), Vector2(70.0, 28.0), 7.0)
	for st in [west, east, nsx, w2, e2]:
		_link(str(st[0]), _nearest(points[st[0]], ["pr"]))
		_link(str(st[st.size() - 1]), _nearest(points[st[st.size() - 1]], ["su"]))
	_link(str(mid[0]), _nearest(points[mid[0]], ["we"]))
	_link(str(mid[mid.size() - 1]), _nearest(points[mid[mid.size() - 1]], ["ea"]))
	for k in range(1, mid.size() - 1):
		if absf((points[mid[k]] as Vector3).x - R.ORIGIN.x) < 4.0:
			_link(str(mid[k]), _nearest(points[mid[k]], ["ns"]))
	_link(_nearest(T(-70.0, 6.0), ["wx"]), _nearest(T(-70.0, 6.0), ["mi", "we"]))
	# la Machine : on n'y marche pas au travers (les nœuds du milieu évitent le socle)
	_detour_machine()
	# le téléphérique (gare haute, sur la promenade)
	points["tel_haut"] = T(TEL_TOP.x, TEL_TOP.y + 3.2)
	_link("tel_haut", _nearest(points["tel_haut"], ["pr"]))
	# la route en lacet jusqu'au port
	var rn: Array = []
	var pts: Array = R.ROAD
	var idx: int = 0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n: int = int(Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) / 8.0)
		for k2 in range(n + (1 if i == pts.size() - 2 else 0)):
			var q: Vector3 = a.lerp(b, float(k2) / n)
			var nm: String = "ro%d" % idx
			points[nm] = R.to_world(q.x, q.z, q.y)
			rn.append(nm)
			idx += 1
	_chain(rn)
	_link(str(rn[rn.size() - 1]), _nearest(points[rn[rn.size() - 1]], ["pr", "ex"]))
	# le port
	var quai: Array = _street("qp", Vector2(-50.0, -91.0), Vector2(68.0, -91.0), 8.0, true)
	_link(str(rn[0]), _nearest(points[rn[0]], ["qp"]))
	points["tel_bas"] = P(TEL_BOTTOM.x, TEL_BOTTOM.y + 3.2)
	_link("tel_bas", _nearest(points["tel_bas"], ["qp"]))
	# les portes : reliées à la rue la plus proche (même étage)
	for k3 in points.keys():
		var ks: String = str(k3)
		if ks.begins_with("porte"):
			var pp: Vector3 = points[ks]
			_link(ks, _nearest(pp, ["qp"] if pp.y < 10.0 else ["pr", "su", "we", "ea", "mi", "ns", "wx", "ex"]))
	# chaque lieu d'activité a son point « @nom »
	for s in spots:
		var nm2: String = "@" + str(s)
		points[nm2] = spots[s]["pos"]
		var near: String = str(spots[s]["node"])
		var sp: Vector3 = spots[s]["pos"]
		if near == "" or not points.has(near):
			near = _nearest(sp, ["qp", "tel_bas"] if sp.y < 10.0 else ["pr", "su", "we", "ea", "mi", "ns", "wx", "ex"])
		_link(nm2, near)
		spots[s]["node"] = nm2


## Les robots, l'homme volant.
func _robots() -> void:
	# les balayeurs, autour de la place
	for k in range(3):
		var path: Array = []
		for i in range(10):
			var a: float = TAU * (i + k * 3.3) / 10.0
			path.append(T(cos(a) * (14.0 + k * 3.0), sin(a) * (11.0 + k * 2.5)))
		robots.add_robot("balayeur", path, 0.8, 1.5)
	# les porteurs : de la fabrique à la foire ; sur le port, de l'entrepôt à la grue
	robots.add_robot("porteur", [T(-40.0, 30.0), T(-40.0, 22.0), T(-20.0, 18.0), T(10.0, 20.0), T(22.0, 30.0), T(-10.0, 30.0)], 1.0, 3.0)
	robots.add_robot("porteur", [T(70.0, 10.0), T(70.0, -20.0), T(50.0, -20.0), T(50.0, 10.0)], 0.9, 2.0)
	robots.add_robot("porteur", [P(-40.0, -91.0), P(5.0, -92.0), P(30.0, -91.0), P(-10.0, -90.5)], 1.0, 4.0)
	# le majordome du café, entre les tables et le comptoir
	robots.add_robot("majordome", [T(-52.0, -6.0), T(-49.0, -11.0), T(-47.0, -8.0), T(-49.0, 3.0), T(-52.0, -2.0)], 0.7, 2.5)
	# les drones de livraison
	for k2 in range(3 if pc else 2):
		var dp: Array = []
		for i2 in range(8):
			var a2: float = TAU * i2 / 8.0 + k2
			dp.append(T(cos(a2) * (30.0 + k2 * 18.0), sin(a2) * (22.0 + k2 * 6.0), 12.0 + k2 * 4.0))
		robots.add_robot("drone", dp, 4.0, 0.0)
	# Boulon, le chien-robot, autour de son stand
	var st: Vector3 = spots["chien_niche"]["pos"]
	robots.add_robot("chien", [st, st + Vector3(3.0, 0, 2.0), st + Vector3(-1.0, 0, 4.0), st + Vector3(-3.0, 0, 0.5)], 1.3, 2.0)
	# le Colosse, sur la promenade
	robots.add_robot("colosse", [T(-90.0, -37.5), T(90.0, -37.5)], 0.7, 6.0)
	robots.add_achille(T(0.0, 0.0), 70.0, 32.0, Y + 30.0)


# =================================================================== la vie

func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	if Vector2(p.x - R.ORIGIN.x, p.z - R.ORIGIN.z).length() > 450.0:
		return
	for s in _spin:
		var n: Node3D = s[0]
		if s.size() > 3:
			n.rotation.y = sin(_clock * 0.8) * 0.6
		else:
			n.rotate_object_local(s[1], float(s[2]) * delta)
	# l'horloge : la vraie heure
	var h: float = hour()
	for hands in _clock_hands:
		(hands[0] as Node3D).rotation.z = -TAU * fmod(h, 12.0) / 12.0
		(hands[1] as Node3D).rotation.z = -TAU * fmod(h, 1.0)
	# le monorail
	_train_s = fmod(_train_s + delta * 0.045, 1.0)
	for k in range(_train.size()):
		var s2: float = fmod(_train_s + k * 0.028, 1.0)
		var a: float = TAU * s2
		var pos: Vector3 = T(cos(a) * RAIL_RX, sin(a) * RAIL_RZ, RAIL_H)
		var ahead: Vector3 = T(cos(a + 0.02) * RAIL_RX, sin(a + 0.02) * RAIL_RZ, RAIL_H)
		var car: Node3D = _train[k]
		car.global_position = pos
		car.look_at(ahead, Vector3.UP)
	if _crane_jib != null:
		_crane_jib.rotation.y = sin(_clock * 0.05) * 1.2 + 0.6
	_tick_tesla(delta, p)
	_tick_boum(delta, p)
	_confetti_t -= delta
	if _confetti_t <= 0.0 and _confetti != null:
		_confetti_t = _rng.randf_range(18.0, 30.0)
		_confetti.restart()
		if main.get("sfx_v50") != null and p.distance_to(_confetti.global_position) < 60.0:
			main.sfx_v50.play("confettis", _confetti.global_position)


func _tick_tesla(delta: float, p: Vector3) -> void:
	_arc_t -= delta
	if _arc_on > 0.0:
		_arc_on -= delta
		_draw_arcs()
		_arc_light.light_energy = 4.0 * (0.6 + 0.4 * sin(_clock * 60.0))
		if _arc_on <= 0.0:
			_arc_mesh.clear_surfaces()
			_arc_light.light_energy = 0.0
	elif _arc_t <= 0.0:
		_arc_t = _rng.randf_range(3.0, 8.0)
		_arc_on = _rng.randf_range(0.3, 0.8)
		if main.get("sfx_v50") != null and p.distance_to(_arc_light.global_position) < 80.0:
			main.sfx_v50.play("tesla", _arc_light.global_position)


func _draw_arcs() -> void:
	_arc_mesh.clear_surfaces()
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var a: Vector3 = _tesla_tops[0]
	var b: Vector3 = _tesla_tops[1]
	var targets: Array = [[a, b]]
	for top in _tesla_tops:
		if _rng.randf() < 0.6:
			targets.append([top, top + Vector3(_rng.randf_range(-6.0, 6.0), -11.0, _rng.randf_range(-6.0, 6.0))])
	for tg in targets:
		var s: Vector3 = tg[0]
		var e: Vector3 = tg[1]
		for strand in range(2):
			var prev: Vector3 = s
			var n: int = 14
			for i in range(1, n + 1):
				var t: float = float(i) / n
				var q: Vector3 = s.lerp(e, t)
				if i < n:
					q += Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * 1.2 * sin(t * PI)
				_arc_mesh.surface_add_vertex(prev)
				_arc_mesh.surface_add_vertex(q)
				prev = q
	_arc_mesh.surface_end()


func _tick_boum(delta: float, p: Vector3) -> void:
	var fl: OmniLight3D = _boum_fx[0]
	if fl.light_energy > 0.0:
		fl.light_energy = maxf(0.0, fl.light_energy - delta * 14.0)
	_boum_t -= delta
	if _boum_t > 0.0:
		return
	_boum_t = _rng.randf_range(45.0, 80.0)
	fl.light_energy = 9.0
	for k in range(1, _boum_fx.size()):
		(_boum_fx[k] as CPUParticles3D).restart()
	if main.get("sfx_v50") != null and p.distance_to(_boum_at) < 140.0:
		main.sfx_v50.play("boum", _boum_at)
	# le professeur commente
	if by_id.has("boum"):
		var b: Node = by_id["boum"]
		if is_instance_valid(b) and not bool(b.get("hidden_home")) and b.global_position.distance_to(_boum_at) < 25.0:
			var lines := ["Parfait ! C'est exactement ce qui devait se passer !", "Hum. Il faudra un nouveau toit. Encore.", "EURÊKA ! … Non. Raté. Mais quel joli vert !", "Note pour moi-même : moins de poudre.", "Personne n'est blessé ? Parfait, on recommence."]
			b.say_bubble(lines[_rng.randi() % lines.size()], 4.0)


# =================================================================== la barque, les zones

func on_structure(p: Vector3) -> bool:
	if zephyr != null and zephyr.riding:
		return true
	if tele != null and tele.riding >= 0:
		return true
	var t: Vector2 = R.to_city(p.x, p.z)
	# les gares du téléphérique (plates-formes de fonte au-dessus du vide)
	for c in [TEL_BOTTOM, TEL_TOP]:
		if absf(t.x - c.x) < 3.2 and absf(t.y - c.y) < 2.8:
			return true
	return false


func blocks_boat(p: Vector3) -> bool:
	var t: Vector2 = R.to_city(p.x, p.z)
	return absf(t.x - 52.0) < 3.0 and absf(t.y + 103.0) < 7.0


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var t: Vector2 = R.to_city(p.x, p.z)
	if p.y < 14.0 and t.y < -60.0:
		if ile.height(p.x, p.z) < -0.42 and not on_structure(p):
			return "" if t.y < -130.0 else "cliquetis_port"
		return "cliquetis_port"
	if absf(t.x) < 34.0 and absf(t.y) < 25.0:
		return "cliquetis_foire"
	if t.y > -45.0 and t.y < 50.0 and absf(t.x) < 104.0 and p.y > Y - 4.0:
		return "cliquetis"
	return ""


# =================================================================== les habitants (agenda)

const Habitants = preload("res://scripts/pnj/cliquetis_habitants_v61.gd")
const PnjCliquetis = preload("res://scripts/pnj/pnj_cliquetis_v61.gd")

var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "zephyr": 0, "telepherique": 0, "nuits": 0, "boum": 0}
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
		var start: String = "mi0"
		var home: String = str(data.get("maison", ""))
		if points.has(home):
			start = home
		var npc: Node3D = PnjCliquetis.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V61: %d habitants à Cliquetis" % habitants.size())


func dock() -> Array:
	return boat_dock


func respawn_point() -> Array:
	var at: Vector3 = T(-8.0, -30.0)
	return [at + Vector3.UP * 0.3, Vector3(0, 0, 1)]


## Le Zéphyr et le téléphérique : monter, descendre, ce qu'on affiche.
func riding() -> bool:
	return (zephyr != null and zephyr.riding) or (tele != null and tele.riding >= 0)


func ride_prompt() -> String:
	if zephyr != null and zephyr.riding:
		return ("E : descendre à " + zephyr.stop_name(zephyr.stop_i)) if zephyr.docked else ""
	return ""


func ride_interact() -> void:
	if zephyr != null and zephyr.riding and zephyr.docked:
		zephyr.leave()


func ride_safe_pos() -> Vector3:
	if zephyr != null and zephyr.riding:
		return zephyr.safe_pos()
	if tele != null and tele.riding >= 0:
		return tele.safe_pos()
	return T(0.0, -30.0)


func register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var I: Array = d._interactions
	var zi := {"id": "zephyr_monter", "pos": Vector3.INF, "radius": 3.2, "text": "E : monter à bord du Zéphyr", "vr": "Gâchette : monter à bord du Zéphyr",
		"call": _board_zephyr, "when": func(): return zephyr != null and zephyr.docked and not zephyr.riding}
	I.append(zi)
	_zephyr_inter = zi
	for k in range(2):
		var ti := {"id": "telepherique_%d" % k, "pos": Vector3.INF, "radius": 2.8, "text": "E : monter dans la cabine du téléphérique", "vr": "Gâchette : monter dans la cabine",
			"call": func(): _board_tele(k), "when": func(): return tele != null and tele.riding < 0 and tele.at_station(k) != ""}
		I.append(ti)
		_tele_inters.append(ti)


var _zephyr_inter: Dictionary = {}
var _tele_inters: Array = []


func _physics_process(_delta: float) -> void:
	if not _zephyr_inter.is_empty() and zephyr != null:
		_zephyr_inter["pos"] = zephyr.door_pos()
	for k in range(_tele_inters.size()):
		(_tele_inters[k] as Dictionary)["pos"] = tele.cabin_floor(k) + Vector3.UP * 0.4


func _board_zephyr() -> void:
	zephyr.board()
	state["zephyr"] = int(state["zephyr"]) + 1


func _board_tele(k: int) -> void:
	tele.board(k)
	state["telepherique"] = int(state["telepherique"]) + 1


## Services : une chambre « à ressorts » au-dessus du Café de la Bielle (Gaston).
func register_services(journal: Node) -> void:
	journal.add_service("gaston", Callable(self, "_inn_topics"), Callable(self, "_inn_choose"))
	for k in objets:
		journal.lieux[k] = objets[k]
	register_interactions()


func _inn_topics(_npc: Node) -> Array:
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return [{"id": "q56:service:ressorts", "label": "☾ %s (7 pièces)" % ("Une chambre à ressorts pour la nuit" if night else "Une sieste sur un lit à ressorts")}]


func _inn_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 7:
		return {"texte": "Sept pièces, mon ami. Les ressorts, ça s'use. Les pièces aussi, mais moins vite.", "geste": "parle"}
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return {"texte": ("La chambre du dessus. Le lit est à ressorts : si vous rebondissez au plafond, c'est normal. Le réveil sonne à sept heures, il joue de la trompette." if night else "Une sieste ? Le lit à ressorts vous attend. Attention, il est d'humeur joueuse."),
		"geste": "salut", "fin": true, "prendre": [["piece", 7]], "_ressorts": 7.0 if night else 18.5}


func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_ressorts"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_ressorts"]))


func trouvailles() -> Dictionary:
	return {"cliquetis": 1 if bool(state["visite"]) else 0, "zephyr": int(state["zephyr"]), "telepherique": int(state["telepherique"])}


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate()
	if zephyr != null:
		d["zephyr_escale"] = zephyr.serialize()
	return d


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "zephyr": int(d.get("zephyr", 0)), "telepherique": int(d.get("telepherique", 0)), "nuits": int(d.get("nuits", 0)), "boum": int(d.get("boum", 0))}
	if zephyr != null:
		zephyr.load_data(d.get("zephyr_escale", {}) if d.get("zephyr_escale", {}) is Dictionary else {})
	if tele != null:
		tele.riding = -1
	_claims.clear()
	for n in habitants:
		n.slot = -2


func check_visit(p: Vector3) -> void:
	if not bool(state["visite"]) and zone_at(p).begins_with("cliquetis") and p.y > Y - 3.0:
		state["visite"] = true
		main._show_message_v28("Cliquetis, la cité des ingénieurs fous — la Foire des Inventions, le Zéphyr, le téléphérique")

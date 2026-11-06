extends Node3D
## V112 : la Grande Colonne de Hautefond, au milieu de la Place de la Colonne. Une tour de laiton doré
## et de verre, posée sur un socle octogonal de pierre blonde percé de quatre portails :
##  - le hall (au pied) : le guichet de la Confrérie des Liftiers, la cage de verre de l'ascenseur ;
##  - la CABINE : une cage dorée qu'on peut parcourir à pied ; elle monte au BELVÉDÈRE (60 m plus haut,
##    un balcon rond sous un auvent de cuivre, d'où l'on voit toute l'île) et redescend. On y entre,
##    on tire le levier (E / gâchette), les portes se ferment, ça monte ! Le joueur est porté par la
##    cabine (sa hauteur suit celle du plancher, au PC comme en VR) ;
##  - les trois cages extérieures : leurs cabines dorées montent et descendent sans fin (les lignes
##    des Nuées et des Strates, encore « en révision » : des panneaux le disent) ;
##  - au-dessus du Belvédère, la tour continue jusqu'à sa couronne de verre (une lanterne qui luit la
##    nuit) et sa flèche.
## Les points de la Colonne (repère monde) : foot (le centre au sol), top (le plancher du Belvédère).

const H_SOCLE: float = 11.0
const R_SOCLE: float = 15.5              # l'apothème de l'octogone du socle
const R_PUITS: float = 2.75              # la cage de verre de l'ascenseur
const R_CAB: float = 2.3                 # la cabine
const H_BELV: float = 70.0               # le plancher du Belvédère, au-dessus de la place
const R_BELV: float = 18.0
const DUREE: float = 16.0                # la montée (s)
const H_CAB: float = 3.0

var main: Node
var kit
var foot := Vector3.ZERO                 # le centre de la Colonne, au niveau de la place
var top := Vector3.ZERO                  # le centre, au niveau du plancher du Belvédère
var cabin: Node3D
var cabin_body: StaticBody3D
var door_l: Node3D
var door_r: Node3D
var door_col: CollisionShape3D
var gates: Array = []                    # [grille, collision, position fermée, en haut ?]
var cabin_light: OmniLight3D
var deco_cabins: Array = []              # [MeshInstance3D, y bas, y haut, phase]
var crown_glow: OmniLight3D
var guichet := Vector3.ZERO              # devant le guichet (le client)
var guichet_staff := Vector3.ZERO
var cabine_spot := Vector3.ZERO
var belv_spots: Array = []               # [Vector3, Vector3 (regard)]
var hall_points: Dictionary = {}         # nom -> Vector3 (les points de passage du hall)
var ylow: float = 0.0
var yhigh: float = 0.0
var t: float = 0.0                       # 0 : en bas ; 1 : en haut
var target: float = 0.0
var moving: bool = false
var doors_open: float = 1.0              # 0 : fermées, 1 : ouvertes
var rides: int = 0
var _carry_was: bool = false
var _msg_t: float = 0.0
var _clock: float = 0.0
var _last_y: float = 0.0
var _pc: bool = true


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Bâtit la Colonne (la géométrie fixe va dans le kit de la ville ; la cabine a son propre kit).
func build(main_node: Node, city_kit, center: Vector3, pc: bool) -> void:
	main = main_node
	kit = city_kit
	_pc = pc
	foot = center
	top = center + Vector3.UP * H_BELV
	ylow = foot.y + 0.02
	yhigh = top.y
	_socle()
	_puits()
	_corps()
	_belvedere()
	_couronne()
	_lignes()
	_cabine()
	_grille()
	_last_y = ylow


# =================================================================== le socle et le hall

func _socle() -> void:
	var c: Vector3 = foot
	var side: float = 2.0 * R_SOCLE * tan(PI / 8.0)
	for k in range(8):
		var a: float = TAU * k / 8.0
		var out := Vector3(cos(a), 0, sin(a))
		var xf := Transform3D(Basis.looking_at(-out, Vector3.UP), c + out * R_SOCLE)
		var portal: bool = k % 2 == 0
		var t0: float = 1.3
		if portal:
			var pw: float = 5.2
			var ph: float = 6.4
			for s in [-1.0, 1.0]:
				var w2: float = (side - pw) * 0.5
				var x: float = s * (pw * 0.5 + w2 * 0.5)
				kit.box(xf * T(x, H_SOCLE * 0.5, -t0 * 0.5), Vector3(w2 + 0.02, H_SOCLE, t0), "pierre112", 2.6, 63 - 8)
				kit.col_box(xf * T(x, H_SOCLE * 0.5, -t0 * 0.5), Vector3(w2, H_SOCLE, t0))
				# les pilastres du portail
				kit.box(xf * T(s * (pw * 0.5 + 0.3), ph * 0.5, 0.12), Vector3(0.6, ph, 0.3), "pierre112_clair", 1.4)
			kit.box(xf * T(0, (H_SOCLE + ph) * 0.5, -t0 * 0.5), Vector3(pw + 0.04, H_SOCLE - ph, t0), "pierre112", 2.6, 63 - 8)
			kit.col_box(xf * T(0, (H_SOCLE + ph) * 0.5, -t0 * 0.5), Vector3(pw, H_SOCLE - ph, t0))
			# l'arc du portail (en plein cintre), sa clé, l'inscription
			for i in range(9):
				var a0: float = PI * i / 9.0
				var a1: float = PI * (i + 1) / 9.0
				var am: float = (a0 + a1) * 0.5
				var rr: float = pw * 0.5 + 0.3
				kit.box(xf * Transform3D(Basis(Vector3.BACK, am - PI * 0.5), Vector3(cos(am) * rr, ph - 0.2 + sin(am) * rr * 0.5, 0.14)), Vector3(0.5, rr * (a1 - a0) * 0.9, 0.3), "pierre112_clair", 1.0)
			kit.box(xf * T(0, ph + pw * 0.25 + 0.15, 0.2), Vector3(0.7, 0.9, 0.36), "pierre112_clair", 1.0)
			if k == 2:
				kit.plaque112(xf * T(0, ph + 1.75, 0.0), "liftiers", 2.6)
		else:
			kit.box(xf * T(0, H_SOCLE * 0.5, -t0 * 0.5), Vector3(side + 0.04, H_SOCLE, t0), "pierre112", 2.6, 63 - 8)
			kit.col_box(xf * T(0, H_SOCLE * 0.5, -t0 * 0.5), Vector3(side, H_SOCLE, t0))
			# une grande horloge sur les pans en biais
			kit.clock112(xf * T(0, 5.2, 0.08), 1.6)
		# la corniche, la balustrade du toit-terrasse du socle
		kit.box(xf * T(0, H_SOCLE + 0.15, -t0 * 0.5), Vector3(side + 0.6, 0.3, t0 + 0.6), "pierre112_clair", 1.2)
		kit.box(xf * T(0, H_SOCLE + 0.7, 0.1), Vector3(side, 0.8, 0.35), "pierre112_clair", 1.2, 63 - 8)
		# les contreforts aux angles de l'octogone, coiffés d'un pinacle de laiton
		var ca: float = a + PI / 8.0
		var cp: Vector3 = c + Vector3(cos(ca), 0, sin(ca)) * (R_SOCLE / cos(PI / 8.0) + 0.2)
		kit.box(Transform3D(Basis(Vector3.UP, -ca), cp + Vector3.UP * (H_SOCLE * 0.5 + 0.4)), Vector3(1.4, H_SOCLE + 0.8, 1.4), "pierre112_clair", 1.6)
		kit.cyl(Transform3D(Basis(), cp + Vector3.UP * (H_SOCLE + 0.8)), 0.45, 0.0, 2.4, "laiton112", 8)
	# le hall : le dallage, le plafond (percé pour la cage), le lustre, le guichet
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.04), R_SOCLE - 0.6, "pave112", 32, 3.0)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (H_SOCLE - 0.9)), R_PUITS + 0.25, R_SOCLE - 0.4, 0.5, "pierre112_clair", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (H_SOCLE - 0.4)), R_PUITS + 0.25, R_SOCLE - 0.4, 0.4, "pierre112", 32)
	for k2 in range(8):
		var a2: float = TAU * (k2 + 0.5) / 8.0
		kit.box(Transform3D(Basis(Vector3.UP, -a2), c + Vector3(cos(a2), 0, sin(a2)) * ((R_PUITS + R_SOCLE) * 0.5) + Vector3.UP * (H_SOCLE - 1.1)), Vector3(R_SOCLE - R_PUITS - 1.0, 0.4, 0.4), "laiton112_vieux", 1.0)
	kit.chandelier(c + Vector3(6.5, H_SOCLE - 2.2, -2.0), 1.0, Color(1.0, 0.78, 0.5), 1.8, 12.0)
	kit.chandelier(c + Vector3(-6.5, H_SOCLE - 2.2, 2.0), 1.0, Color(1.0, 0.78, 0.5), 1.8, 12.0)
	# le guichet de la Confrérie : un comptoir de bois, juste à droite en entrant par le sud
	var gx := Transform3D(Basis(Vector3.UP, -PI * 0.5), c + Vector3(6.4, 0, 6.6))
	guichet_staff = kit.counter71(gx, 3.2, "planches71_clair")
	guichet = gx * Vector3(0, 0.05, 1.1)
	kit.box(gx * T(0, 2.6, -1.6), Vector3(3.6, 2.2, 0.15), "bois112", 1.0)
	kit.plaque112(gx * T(0, 2.9, -1.5), "liftiers", 2.4)
	kit.globe_lamp112(gx * Vector3(-2.1, 0, 0.4), 0.0, 2.6, true)
	cabine_spot = c + Vector3(-2.2, 0.05, R_PUITS + 1.4)
	hall_points["hall_sud"] = c + Vector3(0, 0.05, R_SOCLE + 2.5)
	hall_points["hall_porte"] = c + Vector3(0, 0.05, R_SOCLE - 1.0)
	hall_points["hall_milieu"] = c + Vector3(0, 0.05, R_PUITS + 2.4)
	hall_points["hall_guichet"] = guichet
	hall_points["hall_derriere"] = guichet_staff + Vector3(0.6, 0.05, -1.0)
	for k3 in range(4):
		var a3: float = TAU * k3 / 4.0
		hall_points["hall_portail_%d" % k3] = c + Vector3(cos(a3), 0, sin(a3)) * (R_SOCLE + 2.5) + Vector3.UP * 0.05
		hall_points["hall_dedans_%d" % k3] = c + Vector3(cos(a3), 0, sin(a3)) * (R_SOCLE - 2.0) + Vector3.UP * 0.05


# =================================================================== la cage de l'ascenseur

func _puits() -> void:
	var c: Vector3 = foot
	var h_total: float = H_BELV + 3.4
	for k in range(8):
		var a0: float = TAU * k / 8.0
		kit.cyl(Transform3D(Basis(), c + Vector3(cos(a0), 0, sin(a0)) * R_PUITS), 0.09, 0.09, h_total, "laiton112", 6, false)
	# le verre de la cage : un pan par huitième, sauf la porte (au sud) aux deux paliers
	for k in range(8):
		var a0: float = TAU * k / 8.0
		var a1: float = TAU * (k + 1) / 8.0
		var am: float = (a0 + a1) * 0.5
		var door: bool = absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.3
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * R_PUITS
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * R_PUITS
		var mid: Vector3 = (p0 + p1) * 0.5
		var wseg: float = p0.distance_to(p1)
		var bs := Basis.looking_at(-(mid - c).normalized(), Vector3.UP)
		var spans: Array = [[0.0, h_total]]
		if door:
			spans = [[H_CAB + 0.2, H_BELV], [H_BELV + H_CAB + 0.2, h_total]]
		for sp in spans:
			var y0: float = float(sp[0])
			var y1: float = float(sp[1])
			if y1 - y0 < 0.1:
				continue
			kit.quad(Transform3D(bs, mid + Vector3.UP * ((y0 + y1) * 0.5)) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), wseg, y1 - y0, "verre112", Vector2(0, 0), Vector2(1, 1), true)
		if not door:
			# la paroi des paliers (le hall et le Belvédère) : on ne tombe pas dans la cage
			for yb in [0.0, H_BELV]:
				kit.col_box(Transform3D(bs, mid + Vector3.UP * (yb + 1.6)), Vector3(wseg, 3.2, 0.12))
		# des bagues de laiton tous les dix mètres
	for y in range(0, int(h_total), 10):
		kit.ring(Transform3D(Basis(), c + Vector3.UP * float(y)), R_PUITS - 0.05, R_PUITS + 0.16, 0.18, "laiton112", 24)
	# le linteau des deux portes de palier
	for yb2 in [0.0, H_BELV]:
		var dp: Vector3 = c + Vector3(0, yb2 + H_CAB + 0.1, R_PUITS + 0.05)
		kit.box(Transform3D(Basis(), dp), Vector3(2.3, 0.3, 0.2), "laiton112", 1.0)


# =================================================================== le corps de la tour

func _corps() -> void:
	var c: Vector3 = foot
	var y0: float = H_SOCLE + 1.1
	var y1: float = H_BELV
	var r0: float = 10.6
	var r1: float = 9.0
	# le verre : un cône tronqué ouvert, par tranches (des bagues de laiton entre elles)
	var n: int = 5
	for i in range(n):
		var ya: float = lerpf(y0, y1, float(i) / n)
		var yb: float = lerpf(y0, y1, float(i + 1) / n)
		var ra: float = lerpf(r0, r1, float(i) / n)
		var rb: float = lerpf(r0, r1, float(i + 1) / n)
		kit.cyl(Transform3D(Basis(), c + Vector3.UP * ya), ra, rb, yb - ya, "verre112", 24, false, 4.0)
		kit.ring(Transform3D(Basis(), c + Vector3.UP * (yb - 0.25)), rb - 0.1, rb + 0.42, 0.5, "laiton112", 32)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (y0 - 0.3)), r0 - 0.4, r0 + 0.8, 0.6, "pierre112_clair", 32)
	# les huit nervures dorées, et de petites consoles
	for k in range(8):
		var a: float = TAU * (k + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.beam(c + d * (r0 + 0.2) + Vector3.UP * y0, c + d * (r1 + 0.2) + Vector3.UP * (y1 + 4.6), 0.55, "laiton112")
		kit.beam(c + d * (r0 + 0.5) + Vector3.UP * y0, c + d * (r1 + 0.5) + Vector3.UP * (y1 + 4.6), 0.2, "or112")
	# des engrenages géants sur la terrasse du socle (ils tournent)
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + PI / 4.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var gp: Vector3 = c + d2 * (r0 + 1.3) + Vector3.UP * (H_SOCLE + 3.2)
		kit.gear112(Transform3D(Basis.looking_at(-d2, Vector3.UP), gp), 2.2, 16, 0.3, "laiton112_vieux", true)
		kit.gear112(Transform3D(Basis.looking_at(-d2, Vector3.UP), gp + Vector3.UP * 2.6 + d2.cross(Vector3.UP) * 2.4), 1.2, 10, 0.26, "cuivre112", true)


# =================================================================== le Belvédère

func _belvedere() -> void:
	var c: Vector3 = top
	# le plancher : un anneau de dalles, porté par des consoles
	kit.arc_ring(c + Vector3.DOWN * 0.5, R_PUITS + 0.08, R_BELV, 0.5, 0.0, TAU, "pave112", 64, true, 15, 3.0)
	kit.arc_ring(c + Vector3.DOWN * 1.1, 8.6, R_BELV + 0.2, 0.6, 0.0, TAU, "pierre112_clair", 48, false, 2 | 4)
	for k in range(16):
		var a: float = TAU * k / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.beam(c + d * 9.0 + Vector3.DOWN * 6.0, c + d * (R_BELV - 0.6) + Vector3.DOWN * 0.9, 0.5, "pierre112_clair")
	# la balustrade
	for k2 in range(40):
		var a0: float = TAU * k2 / 40.0
		var a1: float = TAU * (k2 + 1) / 40.0
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * (R_BELV - 0.3)
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * (R_BELV - 0.3)
		kit.railing70(p0, p1, 1.15)
		kit.box(Transform3D(Basis(Vector3.UP, atan2(p1.x - p0.x, p1.z - p0.z)), (p0 + p1) * 0.5 + Vector3.UP * 1.18), Vector3(0.16, 0.07, p0.distance_to(p1) + 0.02), "laiton112", 1.0)
	# l'auvent de cuivre vert-de-gris, sur seize colonnettes
	var hr: float = 4.6
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * hr), R_BELV + 0.8, 8.7, 3.0, "verdigris112", 40, false, 2.0)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3.UP * (hr + 0.02)), R_BELV + 0.8, 0.0, 0.01, "bois112", 40, false)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * (hr - 0.25)), R_BELV + 0.5, R_BELV + 0.9, 0.3, "laiton112", 40)
	for k3 in range(16):
		var a3: float = TAU * (k3 + 0.5) / 16.0
		var p3: Vector3 = c + Vector3(cos(a3), 0, sin(a3)) * (R_BELV - 0.8)
		kit.cyl(Transform3D(Basis(), p3), 0.14, 0.12, hr, "laiton112", 8)
		kit.col_cyl(p3, 0.16, hr)
		if k3 % 4 == 1:
			kit.place("globe112", Transform3D(Basis(), p3 + Vector3.UP * (hr - 0.6) - Vector3(cos(a3), 0, sin(a3)) * 0.4))
	# au milieu du plancher, la cage : un mur bas de laiton (côté porte ouvert)
	# deux bancs, une longue-vue, des lampes
	for k4 in range(4):
		var a4: float = TAU * k4 / 4.0 + PI * 0.25
		var d4 := Vector3(cos(a4), 0, sin(a4))
		kit.bench112(Transform3D(Basis.looking_at(-d4, Vector3.UP), c + d4 * 13.6))
		belv_spots.append([c + d4 * 14.8 + Vector3.UP * 0.05, d4])
	var lv: Vector3 = c + Vector3(-1.0, 0, 1.0).normalized() * (R_BELV - 1.6)
	kit.cyl(Transform3D(Basis(), lv), 0.12, 0.08, 1.2, "laiton112", 8)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, -1.2) * Basis(Vector3.UP, 0.8), lv + Vector3.UP * 1.25), 0.12, 0.08, 0.9, "laiton112", 10)
	kit.col_cyl(lv, 0.2, 1.3)
	_light(c + Vector3.UP * 3.6, Color(1.0, 0.8, 0.55), 1.4, 16.0)


# =================================================================== la couronne et la flèche

func _couronne() -> void:
	var c: Vector3 = top
	var y0: float = 4.6
	var y1: float = 34.0
	var r0: float = 8.8
	var r1: float = 6.6
	var n: int = 3
	for i in range(n):
		var ya: float = lerpf(y0, y1, float(i) / n)
		var yb: float = lerpf(y0, y1, float(i + 1) / n)
		var ra: float = lerpf(r0, r1, float(i) / n)
		var rb: float = lerpf(r0, r1, float(i + 1) / n)
		kit.cyl(Transform3D(Basis(), c + Vector3.UP * ya), ra, rb, yb - ya, "verre112", 24, false, 4.0)
		kit.ring(Transform3D(Basis(), c + Vector3.UP * (yb - 0.25)), rb - 0.1, rb + 0.4, 0.5, "laiton112", 32)
	for k in range(8):
		var a: float = TAU * (k + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.beam(c + d * (r0 + 0.5) + Vector3.UP * y0, c + d * (r1 + 0.4) + Vector3.UP * y1, 0.45, "laiton112")
	# la cage continue au-dessus du Belvédère (la ligne des Nuées) jusqu'à la couronne
	kit.cyl(Transform3D(Basis(), c + Vector3.UP * (H_CAB + 0.4)), R_PUITS, R_PUITS, y1 - H_CAB - 0.4, "verre112", 16, false, 3.0)
	# la couronne : un anneau à créneaux, une lanterne de verre ambré, la flèche
	var cc: Vector3 = c + Vector3.UP * y1
	kit.ring(Transform3D(Basis(), cc), r1 - 0.5, r1 + 1.0, 0.8, "laiton112", 32)
	for k2 in range(16):
		var a2: float = TAU * k2 / 16.0
		kit.box(Transform3D(Basis(Vector3.UP, -a2), cc + Vector3(cos(a2), 0, sin(a2)) * (r1 + 0.6) + Vector3.UP * 1.2), Vector3(0.6, 0.9, 0.8), "or112", 1.0)
	kit.cyl(Transform3D(Basis(), cc + Vector3.UP * 0.8), 3.6, 3.2, 4.0, "lampe112", 24, false)
	kit.dome76(Transform3D(Basis(), cc + Vector3.UP * 4.8), 3.4, 3.0, "verdigris112", 24, 8)
	kit.cyl(Transform3D(Basis(), cc + Vector3.UP * 7.6), 0.6, 0.0, 12.0, "or112", 12)
	kit.ball(Transform3D(Basis(), cc + Vector3.UP * 19.0), 0.45, "or112", 10, 5)
	crown_glow = _light(cc + Vector3.UP * 2.8, Color(1.0, 0.8, 0.5), 0.0, 40.0)


# =================================================================== les trois lignes extérieures

func _lignes() -> void:
	var c: Vector3 = foot
	var names := ["nuees", "strates", "nuees"]
	for k in range(3):
		var a: float = TAU * k / 3.0 + PI / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var rr: float = 12.2
		var p: Vector3 = c + d * rr
		var y0: float = H_SOCLE + 1.0
		var y1: float = H_BELV - 1.0
		# les quatre rails de laiton, le verre
		var side: Vector3 = d.cross(Vector3.UP)
		for e in [[-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0], [1.0, 1.0]]:
			var q: Vector3 = p + side * float(e[0]) * 0.9 + d * float(e[1]) * 0.9
			kit.cyl(Transform3D(Basis(), q + Vector3.UP * y0), 0.08, 0.08, y1 - y0 + 2.0, "laiton112", 6, false)
		kit.cyl(Transform3D(Basis(Vector3.UP, a + PI / 4.0), p + Vector3.UP * y0), 1.25, 1.25, y1 - y0 + 2.0, "verre112", 4, false, 4.0)
		for y in range(int(y0), int(y1) + 2, 8):
			kit.box(Transform3D(Basis.looking_at(-d, Vector3.UP), p + Vector3.UP * float(y)), Vector3(2.2, 0.2, 2.2), "laiton112", 1.0)
			kit.beam(p - d * 0.9 + Vector3.UP * float(y), c + d * 10.0 + Vector3.UP * float(y), 0.2, "laiton112_vieux")
		# la cabine dorée : un maillage à part, qui monte et descend
		var cab := MeshInstance3D.new()
		cab.name = "Cabine_" + str(names[k])
		cab.mesh = _deco_cabin_mesh()
		add_child(cab)
		cab.global_position = p + Vector3.UP * y0
		cab.rotation.y = -a + PI * 0.5
		cab.visibility_range_end = 700.0
		deco_cabins.append([cab, foot.y + y0 + 0.2, foot.y + y1 - 1.0, float(k) * 0.37])


func _deco_cabin_mesh() -> ArrayMesh:
	var saved: Dictionary = kit.batch
	kit.batch = {}
	var I := Transform3D.IDENTITY
	kit.box(T(0, 0.08, 0), Vector3(1.6, 0.16, 1.6), "laiton112", 1.0)
	kit.box(T(0, 2.3, 0), Vector3(1.7, 0.2, 1.7), "laiton112", 1.0)
	kit.cyl(T(0, 2.4, 0), 0.7, 0.1, 0.5, "or112", 8)
	for e in [[-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0], [1.0, 1.0]]:
		kit.box(T(float(e[0]) * 0.75, 1.2, float(e[1]) * 0.75), Vector3(0.08, 2.2, 0.08), "or112", 1.0)
	for s in [-1.0, 1.0]:
		for k in range(6):
			kit.box(T(s * 0.78, 0.4 + k * 0.32, 0), Vector3(0.03, 0.03, 1.5), "laiton112", 1.0)
			kit.box(T(0, 0.4 + k * 0.32, s * 0.78), Vector3(1.5, 0.03, 0.03), "laiton112", 1.0)
	kit.ball(T(0, 1.9, 0), 0.16, "lampe112", 8, 4)
	var mesh := ArrayMesh.new()
	for k2 in kit.batch:
		var st: SurfaceTool = kit.batch[k2]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, kit.mat(str(k2)))
	kit.batch = saved
	return mesh


# =================================================================== la cabine (elle bouge)

func _cabine() -> void:
	cabin = Node3D.new()
	cabin.name = "Cabine_colonne"
	add_child(cabin)
	cabin.global_position = Vector3(foot.x, ylow, foot.z)
	var ck = load("res://scripts/hautefond_kit_v112.gd").new()
	ck.setup(cabin, main.get("temps_v56") if main != null else null)
	ck.main = main
	ck.pc = _pc
	cabin_body = ck.body
	var I := Transform3D.IDENTITY
	var r: float = R_CAB
	# le plancher de bois verni bordé de laiton, le plafond doré, la lampe
	ck.disc(T(0, 0.02, 0), r, "bois112", 16, 1.5)
	ck.cyl(T(0, -0.25, 0), r + 0.08, r + 0.08, 0.25, "laiton112", 16)
	ck.ring(T(0, 0.0, 0), r - 0.1, r + 0.08, 0.06, "laiton112", 16)
	ck.cyl(T(0, H_CAB, 0), r + 0.1, r + 0.1, 0.18, "laiton112", 16)
	ck.dome76(T(0, H_CAB + 0.18, 0), r + 0.1, 0.7, "or112", 16, 4)
	ck.cyl(T(0, H_CAB + 0.85, 0), 0.25, 0.0, 0.6, "or112", 8)
	ck.ball(T(0, H_CAB - 0.25, 0), 0.22, "lampe112", 10, 5)
	var body_col := CollisionShape3D.new()
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = r
	floor_shape.height = 0.3
	body_col.shape = floor_shape
	body_col.position = Vector3(0, -0.15, 0)
	cabin_body.add_child(body_col)
	var roof_col := CollisionShape3D.new()
	var roof_shape := CylinderShape3D.new()
	roof_shape.radius = r
	roof_shape.height = 0.2
	roof_col.shape = roof_shape
	roof_col.position = Vector3(0, H_CAB + 0.1, 0)
	cabin_body.add_child(roof_col)
	# les montants dorés, les vitres (la porte : au sud, +Z)
	for k in range(8):
		var a0: float = TAU * k / 8.0
		var a1: float = TAU * (k + 1) / 8.0
		var am: float = (a0 + a1) * 0.5
		ck.cyl(T(cos(a0) * r, 0, sin(a0) * r), 0.06, 0.06, H_CAB, "or112", 6, false)
		var door: bool = absf(wrapf(am - PI * 0.5, -PI, PI)) < 0.3
		if door:
			continue
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r
		var mid: Vector3 = (p0 + p1) * 0.5
		var w: float = p0.distance_to(p1)
		var bs := Basis.looking_at(-mid.normalized(), Vector3.UP)
		ck.quad(Transform3D(bs, mid + Vector3.UP * (H_CAB * 0.5 + 0.35)), w, H_CAB - 0.7, "verre112_cabine", Vector2(0, 0), Vector2(1, 1), true)
		# la main courante et le soubassement ajouré
		ck.box(Transform3D(bs, mid * 0.97 + Vector3.UP * 1.0), Vector3(w, 0.06, 0.06), "laiton112", 1.0)
		ck.box(Transform3D(bs, mid + Vector3.UP * 0.35), Vector3(w, 0.7, 0.04), "laiton112_vieux", 1.0)
		ck.col_box(Transform3D(bs, mid + Vector3.UP * (H_CAB * 0.5)), Vector3(w, H_CAB, 0.1))
	# le pupitre et son levier (au fond, au nord)
	var px := Transform3D(Basis(), Vector3(0, 0, -r + 0.45))
	ck.box(px * T(0, 0.55, 0), Vector3(0.6, 1.1, 0.3), "bois112", 1.0)
	ck.box(px * T(0, 1.12, 0.05), Vector3(0.7, 0.06, 0.42), "laiton112", 1.0)
	ck.cyl(Transform3D(Basis(Vector3.RIGHT, 0.5), px * Vector3(0.12, 1.15, 0.05)), 0.03, 0.025, 0.45, "acier112", 6)
	ck.ball(px * T(0.12 + 0.0, 1.55, 0.27), 0.06, "cuivre112", 8, 4)
	ck.clock112(px * T(0, 2.1, 0.17), 0.3)
	ck.commit()
	# les portes coulissantes (deux vantaux de verre et de laiton) et leur collision
	door_l = _door_leaf(-1.0)
	door_r = _door_leaf(1.0)
	door_col = CollisionShape3D.new()
	var dshape := BoxShape3D.new()
	dshape.size = Vector3(1.9, H_CAB, 0.12)
	door_col.shape = dshape
	door_col.position = Vector3(0, H_CAB * 0.5, r * cos(PI / 8.0))
	door_col.disabled = true
	cabin_body.add_child(door_col)
	cabin_light = OmniLight3D.new()
	cabin_light.light_color = Color(1.0, 0.82, 0.58)
	cabin_light.light_energy = 1.2
	cabin_light.omni_range = 5.0
	cabin_light.shadow_enabled = false
	cabin_light.distance_fade_enabled = true
	cabin_light.distance_fade_begin = 50.0
	cabin_light.distance_fade_length = 10.0
	cabin_light.position = Vector3(0, H_CAB - 0.5, 0)
	cabin.add_child(cabin_light)


func _door_leaf(s: float) -> Node3D:
	var n := MeshInstance3D.new()
	n.name = "Porte_cabine"
	var saved: Dictionary = kit.batch
	kit.batch = {}
	kit.quad(T(0, H_CAB * 0.5 + 0.35, 0), 0.95, H_CAB - 0.7, "verre112_cabine", Vector2(0, 0), Vector2(1, 1), true)
	kit.box(T(0, 0.35, 0), Vector3(0.95, 0.7, 0.04), "laiton112", 1.0)
	kit.box(T(0, H_CAB - 0.03, 0), Vector3(0.95, 0.06, 0.05), "laiton112", 1.0)
	for x in [-0.45, 0.45]:
		kit.box(T(x, H_CAB * 0.5, 0), Vector3(0.05, H_CAB, 0.05), "or112", 1.0)
	var mesh := ArrayMesh.new()
	for k in kit.batch:
		var st: SurfaceTool = kit.batch[k]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, kit.mat(str(k)))
	kit.batch = saved
	n.mesh = mesh
	cabin.add_child(n)
	n.set_meta("s", s)
	n.position = Vector3(s * 0.5, 0, R_CAB * cos(PI / 8.0))
	return n


## Les grilles des deux paliers : fermées quand la cabine n'est pas là (on ne tombe pas dans la cage,
## et la cabine ne descend pas sur quelqu'un).
func _grille() -> void:
	for lv in [[top, true], [Vector3(foot.x, ylow - 0.02, foot.z), false]]:
		var g := MeshInstance3D.new()
		g.name = "Grille_palier"
		var saved: Dictionary = kit.batch
		kit.batch = {}
		for k in range(12):
			kit.box(T(-1.1 + k * 0.2, 1.5, 0), Vector3(0.035, 3.0, 0.035), "laiton112", 1.0)
		for y in [0.1, 1.5, 2.9]:
			kit.box(T(0, y, 0), Vector3(2.3, 0.05, 0.05), "laiton112", 1.0)
		var mesh := ArrayMesh.new()
		for k2 in kit.batch:
			var st: SurfaceTool = kit.batch[k2]
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, kit.mat(str(k2)))
		kit.batch = saved
		g.mesh = mesh
		add_child(g)
		var at: Vector3 = (lv[0] as Vector3) + Vector3(0, 0, R_PUITS + 0.12)
		g.global_position = at
		var b := StaticBody3D.new()
		b.name = "Grille_palier_col"
		add_child(b)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.4, 3.2, 0.15)
		cs.shape = sh
		b.add_child(cs)
		b.global_position = at + Vector3.UP * 1.6
		gates.append([g, cs, at, bool(lv[1])])


func _light(at: Vector3, col: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 220.0
	l.distance_fade_length = 40.0
	add_child(l)
	l.global_position = at
	return l


# =================================================================== la conduite de la cabine

func cabin_y() -> float:
	return lerpf(ylow, yhigh, _ease(t))


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func at_top() -> bool:
	return not moving and t > 0.99


func at_bottom() -> bool:
	return not moving and t < 0.01


## Le joueur (ou un point) est-il dans la cabine ?
func inside(p: Vector3) -> bool:
	var cy: float = cabin_y()
	return Vector2(p.x - foot.x, p.z - foot.z).length() < R_CAB - 0.1 and p.y > cy - 0.6 and p.y < cy + H_CAB


## Dans la tour (la cage, le hall, le Belvédère) : pour savoir si l'on peut marcher ici.
func walkable(p: Vector3) -> bool:
	var d: float = Vector2(p.x - foot.x, p.z - foot.z).length()
	if inside(p):
		return true
	if d < R_BELV + 0.5 and absf(p.y - top.y) < 3.5:
		return true
	return d < R_SOCLE + 0.5 and p.y > foot.y - 1.0 and p.y < foot.y + H_SOCLE


## On tire le levier : la cabine part vers l'autre arrêt (ou on l'appelle d'un palier).
func go(to_top: bool) -> void:
	if moving:
		return
	target = 1.0 if to_top else 0.0
	if absf(target - t) < 0.01:
		return
	moving = true
	rides += 1
	if main != null and main.has_method("sfx"):
		main.sfx("porte", cabin.global_position + Vector3.UP * 1.5)
	var p: Vector3 = main._player_pos_v27() if main != null else Vector3.ZERO
	if main != null and inside(p):
		main._show_message_v28("Ça monte ! Prochain arrêt : le Belvédère, à soixante mètres." if to_top else "Tout le monde descend ! Prochain arrêt : la Place de la Colonne.")


func _physics_process(delta: float) -> void:
	if cabin == null:
		return
	_clock += delta
	# les portes : elles se ferment avant de partir, s'ouvrent à l'arrêt
	var want_open: float = 0.0 if moving else 1.0
	var before: float = doors_open
	doors_open = move_toward(doors_open, want_open, delta * 1.4)
	var p_player: Vector3 = main._player_pos_v27() if main != null else Vector3.ZERO
	var y_before: float = cabin_y()
	if moving and doors_open <= 0.0:
		var dir: float = signf(target - t)
		t = clampf(t + dir * delta / DUREE, 0.0, 1.0)
		if (dir > 0.0 and t >= target) or (dir < 0.0 and t <= target):
			t = target
			moving = false
			if main != null and inside(p_player):
				main._show_message_v28("Le Belvédère : toute l'île à vos pieds !" if t > 0.5 else "La Place de la Colonne. Merci d'avoir voyagé avec la Confrérie des Liftiers !")
	var y_now: float = cabin_y()
	cabin.global_position = Vector3(foot.x, y_now, foot.z)
	var dy: float = y_now - y_before
	if absf(dy) > 0.00001 and main != null and inside(Vector3(p_player.x, p_player.y - dy, p_player.z)):
		_carry(dy)
	for dl in [door_l, door_r]:
		if dl != null:
			var s: float = float(dl.get_meta("s"))
			dl.position.x = s * (0.5 + 0.85 * doors_open)
	if door_col != null:
		door_col.disabled = doors_open > 0.6
	for gt in gates:
		var opened: bool = at_top() if bool(gt[3]) else at_bottom()
		(gt[1] as CollisionShape3D).disabled = opened
		var gnode: Node3D = gt[0]
		var want: Vector3 = (gt[2] as Vector3) + Vector3(1.95 if opened else 0.0, 0, 0)
		gnode.global_position = gnode.global_position.move_toward(want, delta * 1.6)
	# les cabines dorées des lignes extérieures
	for e in deco_cabins:
		var m: Node3D = e[0]
		var k: float = 0.5 - 0.5 * cos((_clock * 0.035 + float(e[3])) * TAU)
		m.global_position.y = lerpf(float(e[1]), float(e[2]), k)


## Le joueur monte (ou descend) avec la cabine.
func _carry(dy: float) -> void:
	if main.get("xr_active") and main.xr_active:
		main.xr_origin.position.y += dy
		main.vr_body.global_position.y += dy
		if dy > 0.0:
			main.vr_body.velocity.y = maxf(main.vr_body.velocity.y, 0.0)
	else:
		main.pc_body.global_position.y += dy
		main.pc_root.position.y += dy
		if dy > 0.0:
			main.pc_body.velocity.y = maxf(main.pc_body.velocity.y, 0.0)
		if main.get("hero_v28") != null:
			main.hero_v28.fall_top = main.pc_body.global_position.y
	main.last_ok_v29.clear()


## La lueur de la couronne, la nuit.
func set_night(k: float) -> void:
	if crown_glow != null:
		crown_glow.light_energy = 3.0 * k


func spin_gears(delta: float) -> void:
	for g in kit.gears:
		if is_instance_valid(g):
			(g as Node3D).rotate_object_local(Vector3.BACK, delta * float(g.get_meta("vitesse", 0.5)))


# =================================================================== les interactions

func register(d: Node, owner_node: Node) -> void:
	var me = self
	var ia := func(it: Dictionary) -> void:
		d._interactions.append(it)
		if owner_node != null and owner_node.get("_interactions") != null:
			owner_node._interactions.append(it)
	ia.call({"id": "hf_cabine_monter", "pos": Vector3(foot.x, ylow + 1.0, foot.z), "radius": 2.2, "text": "E : tirer le levier (monter au Belvédère)",
		"vr": "Gâchette : tirer le levier (monter au Belvédère)", "call": func(): me.go(true), "when": func(): return me.at_bottom() and me.inside(me.main._player_pos_v27())})
	ia.call({"id": "hf_cabine_descendre", "pos": Vector3(foot.x, yhigh + 1.0, foot.z), "radius": 2.2, "text": "E : tirer le levier (descendre sur la Place)",
		"vr": "Gâchette : tirer le levier (descendre sur la Place)", "call": func(): me.go(false), "when": func(): return me.at_top() and me.inside(me.main._player_pos_v27())})
	ia.call({"id": "hf_appel_bas", "pos": foot + Vector3(0, 1.0, R_PUITS + 1.2), "radius": 2.0, "text": "E : appeler la cabine",
		"vr": "Gâchette : appeler la cabine", "call": func(): me.go(false), "when": func(): return not me.at_bottom() and not me.moving})
	ia.call({"id": "hf_appel_haut", "pos": top + Vector3(0, 1.0, R_PUITS + 1.2), "radius": 2.0, "text": "E : appeler la cabine",
		"vr": "Gâchette : appeler la cabine", "call": func(): me.go(true), "when": func(): return not me.at_top() and not me.moving})

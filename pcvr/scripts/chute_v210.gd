extends "res://scripts/manege_v210.gd"
## V210 : la Chute. Une tour de 80 m plantée au sommet de la Butte aux Frissons : la couronne de
## douze sièges monte lentement (on a le temps de voir toute l'île, et la mer tout autour), s'arrête
## tout en haut… et lâche, on ne sait jamais quand. 42 m de chute libre (trois secondes sans rien
## peser, 100 km/h), puis les freins écrasent tout le monde dans son siège.

const H_TOUR: float = 80.0
const Y_BAS: float = 1.15                 # l'assise, à l'arrêt
const Y_HAUT: float = 76.0
const Y_FREIN: float = 34.0               # les freins magnétiques commencent ici
const V_MONTE: float = 3.5
const FREIN: float = 17.5                 # m/s² (on pèse près de trois fois son poids)
const V_POSE: float = 2.2                 # la fin de la descente
const R_SIEGES: float = 2.95
const NB: int = 12
const NOTRE: int = 3                      # notre siège regarde vers +Z (le cœur de l'île)

var couronne: Node3D
var y: float = Y_BAS
var v: float = 0.0
var phase: String = "monte"               # monte, haut, chute, frein, pose
var pause: float = 3.0
var chute_s: float = 0.0                  # la durée de la chute libre (s)
var _rng := RandomNumberGenerator.new()
var _clic_t: float = 0.0


func _init() -> void:
	cle = "chute"
	titre = "La Chute"
	_rng.seed = 21007


func _construire() -> void:
	var b := Kit.Lot.new()
	var c: float = 1.15                    # le demi-côté de la tour
	# les quatre montants, les croisillons
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.tube("poutre", Vector3(sx * c, -1.0, sz * c), Vector3(sx * c, H_TOUR, sz * c), 0.2, 8)
	var etages: int = 20
	var he: float = H_TOUR / etages
	for k in range(etages):
		var y0: float = k * he
		var y1: float = y0 + he
		var coins: Array = [Vector3(-c, 0, -c), Vector3(c, 0, -c), Vector3(c, 0, c), Vector3(-c, 0, c)]
		for i in range(4):
			var p0: Vector3 = coins[i]
			var p1: Vector3 = coins[(i + 1) % 4]
			b.tube("poutre", p0 + Vector3.UP * y1, p1 + Vector3.UP * y1, 0.07, 5)
			if (k + i) % 2 == 0:
				b.tube("poutre", p0 + Vector3.UP * y0, p1 + Vector3.UP * y1, 0.06, 5)
			else:
				b.tube("poutre", p1 + Vector3.UP * y0, p0 + Vector3.UP * y1, 0.06, 5)
	# les quatre rails rouges où roule la couronne, leurs ampoules
	for i2 in range(4):
		var a: float = PI * 0.25 + PI * 0.5 * i2
		var r: float = c * 1.4142 + 0.22
		b.box("rail", Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * r, H_TOUR * 0.5, sin(a) * r)), Vector3(0.14, H_TOUR, 0.3))
		_ampoules(b, Vector3(cos(a) * (r + 0.2), 3.0, sin(a) * (r + 0.2)), Vector3(cos(a) * (r + 0.2), H_TOUR - 1.0, sin(a) * (r + 0.2)), 40, 0.1)
	# la tête de la tour : la plate-forme, le chapeau rayé, la boule, le mât
	b.cyl("bleu", Transform3D(Basis(), Vector3(0, H_TOUR, 0)), 2.6, 3.4, 1.2, 12)
	b.cyl("jaune", Transform3D(Basis(), Vector3(0, H_TOUR + 1.2, 0)), 3.5, 3.5, 0.25, 12)
	b.cyl("toile_rouge", Transform3D(Basis(), Vector3(0, H_TOUR + 1.45, 0)), 3.2, 0.2, 3.6, 12)
	b.blob("ampoule", Vector3(0, H_TOUR + 5.4, 0), Vector3(0.55, 0.55, 0.55), 8)
	b.tube("acier", Vector3(0, H_TOUR + 5.8, 0), Vector3(0, H_TOUR + 9.5, 0), 0.05, 5)
	b.tri("toile_jaune", [Vector3(0, H_TOUR + 9.5, 0), Vector3(0, H_TOUR + 8.5, 0), Vector3(1.8, H_TOUR + 9.0, 0)], [Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)], [Vector2(0, 0), Vector2(0, 1), Vector2(1, 0.5)])
	# le socle : une dalle ronde, la barrière (ouverte devant notre siège)
	b.cyl("dalles", Transform3D(Basis(), Vector3(0, -1.2, 0)), 7.0, 6.6, 1.3, 20)
	_cols.cyl(Vector3(0, -1.2, 0), 6.6, 1.3)
	_cols.cyl(Vector3(0, 0, 0), 1.9, H_TOUR)
	for k2 in range(20):
		var a0: float = TAU * k2 / 20.0
		var a1: float = TAU * (k2 + 1) / 20.0
		var p: Vector3 = Vector3(cos(a0) * 6.2, 0.1, sin(a0) * 6.2)
		var q: Vector3 = Vector3(cos(a1) * 6.2, 0.1, sin(a1) * 6.2)
		b.box("fer", Transform3D(Basis(), p + Vector3.UP * 0.5), Vector3(0.07, 1.0, 0.07))
		# l'ouverture : devant +Z
		if k2 == 4 or k2 == 5:
			continue
		for yy in [0.55, 1.0]:
			b.tube("jaune", p + Vector3.UP * yy, q + Vector3.UP * yy, 0.035, 5)
		var mil: Vector3 = (p + q) * 0.5
		_cols.box(Transform3D(Basis(Vector3.UP, atan2((q - p).x, (q - p).z)), mil + Vector3.UP * 0.6), Vector3(0.2, 1.4, (q - p).length()))
	b.commit(self, "Chute_tour_v210", true, 1400.0)
	# la couronne des sièges
	couronne = Node3D.new()
	couronne.name = "Chute_couronne_v210"
	add_child(couronne)
	var cb := Kit.Lot.new()
	# le chariot carré qui serre la tour, la jupe ronde, les sièges tournés vers le dehors
	for sx2 in [-1.0, 1.0]:
		cb.box("jaune", Transform3D(Basis(), Vector3(sx2 * 1.75, 0.5, 0.0)), Vector3(0.3, 1.6, 3.8))
		cb.box("jaune", Transform3D(Basis(), Vector3(0.0, 0.5, sx2 * 1.75)), Vector3(3.8, 1.6, 0.3))
	cb.cyl("rail", Transform3D(Basis(), Vector3(0, -0.2, 0)), 2.75, 2.75, 0.3, 24, false)
	cb.cyl("rail", Transform3D(Basis(), Vector3(0, 1.25, 0)), 2.75, 2.75, 0.16, 24, false)
	for k3 in range(NB):
		var a2: float = TAU * k3 / NB
		var dehors := Vector3(cos(a2), 0.0, sin(a2))
		var xf := Transform3D(Basis(Vector3.UP, atan2(dehors.x, dehors.z)), dehors * R_SIEGES)
		_siege(cb, xf)
		cb.tube("fer", dehors * 1.9 + Vector3.UP * 0.2, dehors * (R_SIEGES - 0.2) - Vector3.UP * 0.1, 0.06, 5)
		cb.blob("ampoule", dehors * 2.8 + Vector3.UP * 1.5, Vector3(0.1, 0.1, 0.1), 5)
	cb.commit(couronne, "Couronne", true, 1200.0)
	quai_pos = global_transform * Vector3(0.0, 0.35, 5.0)
	quai_face = (global_transform.basis * Vector3(0, 0, 1)).normalized()
	_enseigne(Vector3(6.5, 0.0, 9.5), Vector3(0, 0, 1), "LA CHUTE", "80 m · 42 m de chute libre · 100 km/h")


func _siege_local() -> Transform3D:
	var a: float = TAU * NOTRE / NB
	var dehors := Vector3(cos(a), 0.0, sin(a))
	return Transform3D(Basis(Vector3.UP, atan2(dehors.x, dehors.z)), dehors * R_SIEGES)


func _remise() -> void:
	y = Y_BAS
	v = 0.0
	phase = "monte"
	pause = _rng.randf_range(2.2, 6.5)
	chute_s = 0.0


func _poser(dt: float) -> void:
	if dt > 0.0:
		match phase:
			"monte":
				# on démarre et on arrive en douceur
				var cible: float = V_MONTE * minf(smoothstep(0.0, 2.0, t), smoothstep(0.0, 4.0, Y_HAUT - y) * 0.92 + 0.08)
				v = cible
				y += v * dt
				if y >= Y_HAUT:
					y = Y_HAUT
					v = 0.0
					phase = "haut"
			"haut":
				pause -= dt
				if pause <= 0.0:
					phase = "chute"
					if a_bord and main != null and main.has_method("sfx"):
						main.sfx("tourniquet", null, -2.0)
			"chute":
				v -= G * dt
				y += v * dt
				chute_s += dt
				if y <= Y_FREIN:
					phase = "frein"
			"frein":
				v = minf(v + FREIN * dt, -V_POSE)
				y += v * dt
				if v >= -V_POSE - 0.01:
					phase = "pose"
			"pose":
				v = -V_POSE * (smoothstep(0.0, 2.5, y - Y_BAS) * 0.9 + 0.1)
				y += v * dt
				if y <= Y_BAS + 0.01:
					y = Y_BAS
					v = 0.0
					fini = true
	couronne.position = Vector3(0.0, y, 0.0)


func _bruits(dt: float) -> void:
	if phase != "monte" or main == null or not main.has_method("sfx"):
		return
	_clic_t -= dt
	if _clic_t <= 0.0:
		_clic_t = 0.5
		main.sfx("cliquet_roue", couronne.global_position, -8.0)


func siege() -> Transform3D:
	return _yeux(couronne.global_transform * _siege_local())


func texte() -> String:
	if a_bord and not a_quai() and phase == "haut":
		return "%d m… ça va lâcher…" % int(round(y))
	return super.texte()


func bilan() -> String:
	return "La Chute : lâché de %d m, %.1f s sans rien peser, %d km/h, puis %.1f g dans les freins. Tour n° %d !" % [int(round(hmax_tour)), chute_s, int(round(vmax_tour * 3.6)), gmax_tour, tours]

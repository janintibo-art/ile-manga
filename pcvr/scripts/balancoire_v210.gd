extends "res://scripts/manege_v210.gd"
## V210 : la Grande Balançoire. Un portique de 31 m au bord de la mer, un bras de 30 m, deux rangs
## de six sièges dos à dos, les pieds dans le vide. Elle prend son élan peu à peu, jusqu'à monter
## plus haut que l'horizontale (115°) : au bout de l'aller, on est à 44 m au-dessus de la mer,
## couché sur le dos face au ciel ; au bout du retour, on pend face au sol, 44 m plus bas.

const H_AXE: float = 31.2
const L: float = 30.0                     # de l'axe à l'assise
const A_MAX: float = 2.0                  # l'angle le plus haut (rad)
const T_ELAN: float = 30.0
const T_PLEIN: float = 15.0
const T_CALME: float = 19.0
const W0: float = 0.572                   # racine de g / L : le rythme d'un pendule de 30 m
const NOTRE_X: float = -0.6

var bras: Node3D
var theta: float = 0.0
var ampli: float = 0.0
var psi: float = 0.0
var allers: int = 0


func _init() -> void:
	cle = "balancoire"
	titre = "La Grande Balançoire"


func duree() -> float:
	return T_ELAN + T_PLEIN + T_CALME


func _construire() -> void:
	var b := Kit.Lot.new()
	# le portique : deux A de chaque côté, l'axe tout en haut
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var haut := Vector3(sx * 5.6, H_AXE, sz * 0.5)
			var pied := Vector3(sx * 8.6, 0.0, sz * 13.0)
			b.tube("rail", pied, haut, 0.6, 10, 0.42)
			_semelle(b, pied, 1.4)
			for k in range(5):
				var f: float = (k + 0.5) / 12.0
				_cols.cyl(pied.lerp(haut, f) - Vector3.UP * 1.3, 0.75, 2.6)
			_ampoules(b, pied.lerp(haut, 0.03) + Vector3(sx * 0.65, 0, 0), haut + Vector3(sx * 0.5, -0.5, 0), 28, 0.1)
		# l'entretoise du A
		b.tube("rail", Vector3(sx * 7.1, H_AXE * 0.5, -6.75), Vector3(sx * 7.1, H_AXE * 0.5, 6.75), 0.26, 8)
	b.cyl("acier", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(-6.2, H_AXE, 0.0)), 0.5, 0.5, 12.4, 12)
	b.cyl("jaune", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(-1.1, H_AXE, 0.0)), 0.95, 0.95, 2.2, 14)
	# l'estrade d'embarquement, d'un côté (on monte par le flanc)
	b.box("planches", Transform3D(Basis(), Vector3(-5.3, 0.12, 0.0)), Vector3(3.0, 0.24, 6.0))
	_cols.box(Transform3D(Basis(), Vector3(-5.3, 0.12, 0.0)), Vector3(3.0, 0.24, 6.0))
	b.commit(self, "Balancoire_portique_v210", true, 1000.0)
	# le bras et sa nacelle
	bras = Node3D.new()
	bras.name = "Balancoire_bras_v210"
	add_child(bras)
	bras.position = Vector3(0, H_AXE, 0)
	var bb := Kit.Lot.new()
	bb.tube("jaune", Vector3(0, 0, 0), Vector3(0, -L + 1.3, 0), 0.42, 10, 0.3)
	for sz2 in [-1.0, 1.0]:
		_ampoules(bb, Vector3(0, -2.0, sz2 * 0.45), Vector3(0, -L + 2.0, sz2 * 0.4), 24, 0.1)
	# la poutre des sièges, les deux rangs dos à dos
	bb.box("rail", Transform3D(Basis(), Vector3(0, -L + 1.25, 0)), Vector3(7.4, 0.3, 0.5))
	bb.box("rail", Transform3D(Basis(), Vector3(0, -L + 0.55, 0)), Vector3(7.4, 1.3, 0.14))
	bb.box("fer", Transform3D(Basis(), Vector3(0, -L - 0.12, 0)), Vector3(7.4, 0.14, 0.3))
	for k2 in range(6):
		var x: float = -3.0 + k2 * 1.2
		_siege(bb, Transform3D(Basis(), Vector3(x, -L, 0.42)))
		_siege(bb, Transform3D(Basis(Vector3.UP, PI), Vector3(x, -L, -0.42)))
	for sx2 in [-3.7, 3.7]:
		bb.blob("ampoule", Vector3(sx2, -L + 1.25, 0), Vector3(0.2, 0.2, 0.2), 6)
	bb.commit(bras, "Bras", true, 1000.0)
	quai_pos = global_transform * Vector3(-5.3, 0.34, 0.0)
	quai_face = (global_transform.basis * Vector3(0, 0, 1)).normalized()
	_enseigne(Vector3(-13.0, 0.0, -16.0), Vector3(0, 0, -1), "LA GRANDE BALANÇOIRE", "44 m · 115° · face au vide")


func _remise() -> void:
	theta = 0.0
	ampli = 0.0
	psi = 0.0
	allers = 0


func _poser(dt: float) -> void:
	if dt > 0.0:
		if t < T_ELAN:
			ampli = A_MAX * smoothstep(0.0, T_ELAN, t)
		elif t < T_ELAN + T_PLEIN:
			ampli = A_MAX
		else:
			ampli = A_MAX * (1.0 - smoothstep(0.0, T_CALME, t - T_ELAN - T_PLEIN))
		# un grand pendule bat plus lentement qu'un petit
		var avant: float = psi
		psi += W0 / (1.0 + ampli * ampli / 16.0 + 11.0 * pow(ampli, 4.0) / 3072.0) * dt
		if int(psi / PI) != int(avant / PI):
			allers += 1
		theta = ampli * sin(psi)
		if t >= duree():
			theta = 0.0
			fini = true
	bras.rotation = Vector3(-theta, 0.0, 0.0)


func siege() -> Transform3D:
	return _yeux(bras.global_transform * Transform3D(Basis(), Vector3(NOTRE_X, -L, 0.42)))


func bilan() -> String:
	return "La Grande Balançoire : %d m au-dessus du vide, %d km/h au passage, %d allers et retours. Tour n° %d !" % [int(round(hmax_tour)), int(round(vmax_tour * 3.6)), allers / 2, tours]

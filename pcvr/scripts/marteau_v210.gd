extends "res://scripts/manege_v210.gd"
## V210 : le Marteau. Un bras de 56 m qui tourne autour d'un moyeu à 31 m du sol, une nacelle à
## chaque bout : on passe à 60 m, la tête en bas, et à 100 km/h en bas. Les nacelles pivotent librement sur
## leur axe : elles se balancent et se retournent selon ce qu'on leur fait subir (c'est un pendule,
## calculé pour de vrai). Le bras fait deux tours et demi, s'arrête — nous tout en haut —, puis
## repart en arrière.

const H_AXE: float = 31.0                 # le moyeu
const R: float = 28.0                     # du moyeu à l'axe d'une nacelle
const OMEGA: float = 0.9                  # la vitesse de rotation, lancé (rad/s)
const T_ACC: float = 9.0
const T_PLEIN: float = 9.453              # (4,5 + 9,453 + 3,5) x 0,9 = 5 pi : deux tours et demi
const T_FREIN: float = 7.0
const T_PAUSE: float = 3.6                # l'arrêt tout en haut
const PENDULE: float = 2.6                # la longueur du pendule de la nacelle
const AMORTI: float = 0.55
const ASSISE := Vector3(-0.8, -1.9, 0.42)  # le siège du joueur, dans la nacelle

var bras: Node3D
var nacelles: Array = []
var theta: float = 0.0
var omega: float = 0.0
var phi: Array = [0.0, 0.0]
var phi_v: Array = [0.0, 0.0]
var retournements: int = 0
var _phi_tour: float = 0.0


func _init() -> void:
	cle = "marteau"
	titre = "Le Marteau"


func demi() -> float:
	return T_ACC + T_PLEIN + T_FREIN + T_PAUSE


func duree() -> float:
	return demi() * 2.0


## La vitesse de rotation voulue à l'instant tt (l'aller, puis le même film à l'envers)
func consigne(tt: float) -> float:
	if tt > demi():
		return -consigne(2.0 * demi() - tt)
	if tt < T_ACC:
		return OMEGA * smoothstep(0.0, T_ACC, tt)
	if tt < T_ACC + T_PLEIN:
		return OMEGA
	if tt < T_ACC + T_PLEIN + T_FREIN:
		return OMEGA * (1.0 - smoothstep(0.0, T_FREIN, tt - T_ACC - T_PLEIN))
	return 0.0


func _construire() -> void:
	var b := Kit.Lot.new()
	# les quatre jambes, du moyeu au sol (elles s'écartent : les nacelles passent entre elles)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var haut := Vector3(sx * 1.3, H_AXE, sz * 0.6)
			var pied := Vector3(sx * 11.0, 0.0, sz * 6.0)
			b.tube("bleu", pied, haut, 0.55, 10, 0.4)
			_semelle(b, pied, 1.3)
			# la jambe se touche : une colonne de collision par tronçon
			for k in range(5):
				var f: float = (k + 0.5) / 12.0
				_cols.cyl(pied.lerp(haut, f) - Vector3.UP * 1.3, 0.7, 2.6)
		# les entretoises entre les deux jambes d'un même côté
		for f2 in [0.25, 0.5, 0.75]:
			var a := Vector3(sx * lerpf(11.0, 1.3, f2), H_AXE * f2, -lerpf(6.0, 0.6, f2))
			var c := Vector3(a.x, a.y, -a.z)
			b.tube("bleu", a, c, 0.22, 8)
		_ampoules(b, Vector3(sx * 11.0, 0.6, 6.0), Vector3(sx * 1.4, H_AXE - 0.6, 0.7), 26, 0.1)
	# le moyeu
	b.cyl("jaune", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(-1.9, H_AXE, 0.0)), 1.1, 1.1, 3.8, 14)
	b.cyl("acier", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(-2.1, H_AXE, 0.0)), 0.5, 0.5, 4.2, 10)
	# la plate-forme : un plancher bas de chaque côté de la nacelle du bas, la barrière autour
	for sx2 in [-1.0, 1.0]:
		b.box("planches", Transform3D(Basis(), Vector3(sx2 * 4.3, 0.12, 0.0)), Vector3(3.4, 0.24, 9.0))
		_cols.box(Transform3D(Basis(), Vector3(sx2 * 4.3, 0.12, 0.0)), Vector3(3.4, 0.24, 9.0))
		for sz2 in [-1.0, 1.0]:
			b.tube("jaune", Vector3(sx2 * 2.7, 1.05, sz2 * 4.5), Vector3(sx2 * 6.0, 1.05, sz2 * 4.5), 0.04, 6)
			b.tube("jaune", Vector3(sx2 * 2.7, 0.6, sz2 * 4.5), Vector3(sx2 * 6.0, 0.6, sz2 * 4.5), 0.03, 6)
			for xx in [2.7, 4.35, 6.0]:
				b.box("fer", Transform3D(Basis(), Vector3(sx2 * xx, 0.65, sz2 * 4.5)), Vector3(0.07, 0.9, 0.07))
			_cols.box(Transform3D(Basis(), Vector3(sx2 * 4.35, 0.7, sz2 * 4.5)), Vector3(3.4, 1.4, 0.2))
	b.commit(self, "Marteau_bati_v210", true, 900.0)
	# le bras
	bras = Node3D.new()
	bras.name = "Marteau_bras_v210"
	add_child(bras)
	bras.position = Vector3(0, H_AXE, 0)
	var bb := Kit.Lot.new()
	bb.box("rail", Transform3D(Basis(), Vector3.ZERO), Vector3(0.6, R * 2.0 + 1.4, 1.1))
	bb.box("jaune", Transform3D(Basis(), Vector3.ZERO), Vector3(0.9, 5.0, 1.6))
	for sg in [-1.0, 1.0]:
		bb.box("jaune", Transform3D(Basis(), Vector3(0, sg * R, 0)), Vector3(0.8, 1.6, 1.5))
		for sz3 in [-1.0, 1.0]:
			_ampoules(bb, Vector3(0.0, sg * 3.0, sz3 * 0.6), Vector3(0.0, sg * (R - 1.2), sz3 * 0.6), 22, 0.1)
	bb.commit(bras, "Bras", true, 900.0)
	# les deux nacelles
	for k2 in range(2):
		var nac := Node3D.new()
		nac.name = "Marteau_nacelle_%d_v210" % k2
		add_child(nac)
		var nb := Kit.Lot.new()
		nb.tube("acier", Vector3(-2.2, 0, 0), Vector3(2.2, 0, 0), 0.16, 10)
		for sx3 in [-1.0, 1.0]:
			# le flasque, la poutre qui porte les sièges
			nb.box("jaune", Transform3D(Basis(), Vector3(sx3 * 2.1, -1.0, 0.0)), Vector3(0.12, 2.3, 0.7))
			nb.box("fer", Transform3D(Basis(), Vector3(sx3 * 1.2, -2.05, 0.0)), Vector3(1.9, 0.16, 0.3))
			nb.box("jaune", Transform3D(Basis(), Vector3(sx3 * 0.38, -1.05, 0.0)), Vector3(0.1, 2.2, 0.5))
			for xs in [0.8, 1.5]:
				_siege(nb, Transform3D(Basis(), Vector3(sx3 * xs, ASSISE.y, 0.42)))
				_siege(nb, Transform3D(Basis(Vector3.UP, PI), Vector3(sx3 * xs, ASSISE.y, -0.42)))
		nb.commit(nac, "Nacelle", true, 700.0)
		nacelles.append(nac)
	quai_pos = global_transform * Vector3(4.3, 0.34, 2.0)
	quai_face = (global_transform.basis * Vector3(-1, 0, 0)).normalized()
	_enseigne(Vector3(15.5, 0.0, 9.5), Vector3(1, 0, 0), "LE MARTEAU", "60 m · 100 km/h · la tête en bas")


func _remise() -> void:
	theta = 0.0
	omega = 0.0
	phi = [0.0, 0.0]
	phi_v = [0.0, 0.0]
	retournements = 0
	_phi_tour = 0.0


func _poser(dt: float) -> void:
	if dt > 0.0:
		var pas: int = 3
		var h: float = dt / pas
		for i in range(pas):
			var tt: float = t - dt + h * (i + 1)
			var w: float = consigne(tt)
			var alpha: float = (w - omega) / h
			omega = w
			theta += omega * h
			for k in range(2):
				var th: float = theta + PI * k
				# l'accélération de l'axe de la nacelle (dans le plan : u horizontal, y vertical)
				var au: float = R * (alpha * cos(th) - omega * omega * sin(th))
				var ay: float = R * (alpha * sin(th) + omega * omega * cos(th))
				var acc: float = (-(G + ay) * sin(float(phi[k])) - au * cos(float(phi[k]))) / PENDULE - (AMORTI if tt < duree() - T_PAUSE - 2.0 else 2.6) * float(phi_v[k])
				phi_v[k] = float(phi_v[k]) + acc * h
				phi[k] = float(phi[k]) + float(phi_v[k]) * h
		# les tours complets de notre nacelle sur elle-même
		if absf(float(phi[0]) - _phi_tour) >= TAU:
			retournements += 1
			_phi_tour = float(phi[0])
		if t >= duree():
			fini = true
	bras.rotation = Vector3(-theta, 0.0, 0.0)
	for k2 in range(2):
		var th2: float = theta + PI * k2
		var nac: Node3D = nacelles[k2]
		nac.position = Vector3(0.0, H_AXE - R * cos(th2), R * sin(th2))
		nac.rotation = Vector3(-float(phi[k2]), 0.0, 0.0)


func siege() -> Transform3D:
	return _yeux((nacelles[0] as Node3D).global_transform * Transform3D(Basis(), ASSISE))


func bilan() -> String:
	return "Le Marteau : %d m de haut, %d km/h, jusqu'à %.1f g — et la tête en bas tout là-haut. Tour n° %d !" % [int(round(hmax_tour)), int(round(vmax_tour * 3.6)), gmax_tour, tours]

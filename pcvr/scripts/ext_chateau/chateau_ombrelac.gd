extends Node3D
## Extension « Le Château d'Ombrelac » : l'Académie, le château géant sur le Roc d'Ombrelac.
## Repère « château » : l'origine au centre du plateau, à sa hauteur (ROC_Y) ; x vers l'est, z vers
## le sud (comme le monde). Le plateau fait 82 m de rayon.
##   - l'enceinte : une courtine crénelée et ses tours rondes, tout autour du plateau ;
##   - la Porte du Viaduc (au sud) : deux grosses tours, la herse, et le grand viaduc de pierre qui
##     enjambe la gorge du Torrent jusqu'à la Colline du Guet ;
##   - la Cour d'Honneur, entre la porte et la Grande Salle ;
##   - la Grande Salle : une nef immense, ses contreforts, ses hautes baies et sa rose à l'est ;
##   - la Tour de l'Astrolabe (le donjon) : la plus haute, une tour carrée, puis octogonale, puis
##     une flèche d'ardoise : son épi monte à plus de 150 m au-dessus du lac ;
##   - la Tour de l'Horloge, ses quatre cadrans ;
##   - l'Aile des Dortoirs (au nord) et l'Aile des Études (à l'est), le Cloître entre elles ;
##   - la Tour des Sortilèges (au sud-ouest, au-dessus du lac) ;
##   - le Pont Couvert, qui file au-dessus du lac jusqu'à la Tour des Vents, sur l'Aiguille ;
##   - les Serres, sur la terrasse de l'est.

const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")
const Interieurs = preload("res://scripts/ext_chateau/interieurs_ombrelac.gd")
## La Grande Salle : l'épaisseur des murs, la porte (largeur, hauteur), la hauteur du lambris
const SALLE_T := 1.4
const SALLE_PORTE := Vector2(4.4, 8.0)
const SALLE_VOUTE := 11.0
const Bibliotheque = preload("res://scripts/ext_chateau/bibliotheque_ombrelac.gd")
## La Bibliothèque (l'Aile des Études) : l'épaisseur des murs, la porte, la hauteur du lambris
const BIBLIO_T := 1.2
const BIBLIO_PORTE := Vector2(3.0, 5.6)
const BIBLIO_VOUTE := 6.5
const Salles = preload("res://scripts/ext_chateau/salles_ombrelac.gd")
## Les salles d'étude (le rez-de-chaussée de l'Aile nord, repère de l'aile) : la hauteur sous
## plafond, les murs de refend (x), les portes sur le cloître (x)
const SALLES_RZ := 6.0
const SALLES_REFENDS := [-11.2, 11.2]
const SALLES_PORTES := [-19.6, 0.0, 19.6]
const SALLES_BOUT := 4.0          # les tours d'angle mordent de 3,5 m dans l'aile
const Dortoirs = preload("res://scripts/ext_chateau/dortoirs_ombrelac.gd")
## Les dortoirs (le premier étage de l'Aile nord) : le haut de l'étage (repère de l'aile), la tour
## de l'escalier (repère château), son rayon, l'épaisseur de son mur ; les portes de la tour
## (le numéro du pan de mur sur 28, la hauteur du seuil, le nombre de pans, la hauteur de la porte)
const DORTOIRS_HAUT := 11.6
const TOUR_ESC := Vector3(41.5, 0.0, -46.0)
const TOUR_ESC_R := 5.6
const TOUR_ESC_T := 1.2
const TOUR_ESC_PORTES := [[6, 0.0, 2, 2.8], [13, 6.25, 2, 2.6]]
const Astrolabe = preload("res://scripts/ext_chateau/astrolabe_ombrelac.gd")
## La Tour de l'Astrolabe (le donjon) : son centre, le demi-côté de la tour carrée, l'épaisseur de
## ses murs, le plafond de la salle du bas, le haut de la partie carrée (la terrasse), la hauteur de
## l'Observatoire (dans l'octogone) ; le puits de la Nacelle (son centre, repère du donjon ; son
## demi-côté)
const DONJON := Vector3(-44.0, 0.0, -26.0)
const DONJON_HS := 9.5
const DONJON_T := 1.6
const DONJON_HALL := 11.0
const DONJON_H1 := 54.0
const DONJON_OBS := 12.5
const DONJON_R2 := 7.2
const PUITS := Vector3(0.0, 0.0, -3.2)
const PUITS_HS := 1.7
const Horloge = preload("res://scripts/ext_chateau/horloge_ombrelac.gd")
## La Tour de l'Horloge : creuse ; la salle des poids en bas, l'escalier le long des murs, la
## chambre des rouages en haut, derrière les quatre cadrans de verre ; la cloche sous le toit
const HORLOGE := Vector3(36.0, 0.0, 34.0)
const HORLOGE_HS := 6.0
const HORLOGE_H := 40.0
const HORLOGE_T := 1.2
const HORLOGE_CADRAN_Y := 35.0
const HORLOGE_CADRAN_R := 3.7
const Sortileges = preload("res://scripts/ext_chateau/sortileges_ombrelac.gd")
## La Tour des Sortilèges : creuse jusqu'au plafond du Cabinet ; l'escalier de marches flottantes,
## le Cabinet des Sortilèges à 24 m et son balcon sur le lac. Portes : [premier pan, bas, pans, haut]
const SORT := Vector3(-52.0, 0.0, 34.0)
const SORT_R := 6.5
const SORT_T := 1.2
const SORT_H := 68.0
const SORT_CABINET := 24.0
const SORT_PLAFOND := 34.0
const SORT_PORTES := [[27, 0.0, 2, 3.4], [13, 24.0, 2, 3.2]]
const GrosseTour = preload("res://scripts/ext_chateau/grosse_tour_ombrelac.gd")
## La Grosse Tour (au nord-est, sur l'enceinte) : creuse ; la Salle du Conseil (au pied), le Bureau
## du Recteur (12 m), la Salle des Reliques (24 m), l'escalier à vis dans sa cage de pierre
const GROSSE := Vector3(62.0, 0.0, -40.0)
const GROSSE_R := 8.5
const GROSSE_T := 1.6
const GROSSE_H := 48.0
const GROSSE_E1 := 12.0
const GROSSE_E2 := 24.0
const GROSSE_PLAFOND := 35.5
const GROSSE_PORTES := [[10, 0.0, 2, 3.6]]
## Les baies : [angle (degrés), bas] ; celles sous le plafond ont leur verre vu du dedans
const GROSSE_BAIES := [[40.0, 3.6], [230.0, 3.6], [20.0, 15.0], [110.0, 15.0], [30.0, 27.0], [120.0, 27.0], [220.0, 27.0], [80.0, 39.0], [190.0, 39.0], [340.0, 39.0]]
const Ile = preload("res://scripts/ext_chateau/ile_ombrelac.gd")

var ile: Node3D
var origin: Vector3
## Les lieux du château (repère château) pour les autres scripts : nom → Vector3
var lieux: Dictionary = {}


func build(the_ile: Node3D) -> void:
	ile = the_ile
	origin = Ile.W(Ile.ROC.x, Ile.ROC.y, Ile.ROC_Y)
	position = origin
	var t0: int = Time.get_ticks_msec()
	_enceinte()
	_porte()
	_viaduc()
	_grande_salle()
	_donjon()
	_horloge()
	_aile_nord()
	_aile_est()
	_cloitre()
	_tour_sortileges()
	_grosse_tour()
	_pont_couvert()
	_serres()
	print("OMBRELAC: le château construit en ", Time.get_ticks_msec() - t0, " ms")


func _emit(k: RefCounted, nom: String, vis_end: float = 0.0) -> void:
	var mi: MeshInstance3D = k.commit(nom)
	if vis_end > 0.0:
		mi.visibility_range_end = vis_end
		mi.visibility_range_end_margin = 40.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body(nom + "_col"))


## La hauteur du sol (repère château) sous un point (repère château)
func sol(x: float, z: float) -> float:
	return ile.height(origin.x + x, origin.z + z) - origin.y


static func at(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))


## Une rangée de baies sur la face d'un mur : de a à b (au niveau du bas des baies), face tournée
## vers « out » ; n baies de w x h
func _baies(k: RefCounted, a: Vector3, b: Vector3, out: Vector3, n: int, w: float, h: float, verre: String = "vitre") -> void:
	var yaw: float = atan2(out.x, out.z)
	for i in range(n):
		var p: Vector3 = a.lerp(b, (i + 0.5) / n)
		k.window(Transform3D(Basis(Vector3.UP, yaw), p), w, h, verre)


## Une tour ronde complète : le fût (un peu de fruit à la base), le cordon, les baies, la couronne
## crénelée ou le toit en poivrière posé sur le mur.
func _tour_ronde(k: RefCounted, x: float, z: float, r: float, h: float, toit: float, baies: int = 3, crenelee: bool = false, base: float = -8.0) -> void:
	var y0: float = minf(base, sol(x, z) - 1.0)
	k.cyl("socle", at(x, y0, z), r * 1.12, r * 1.04, -y0 + 1.2, 28, false)
	k.cyl("pierre", at(x, 1.2, z), r * 1.04, r, h - 1.2, 28, false, true)
	# la collision du socle
	k.cyl("socle", at(x, y0, z), r * 1.12, r * 1.12, 0.01, 4, false, true)
	# les baies : en spirale autour du fût (l'escalier à vis)
	for i in range(baies):
		var a: float = 0.7 + i * 2.1
		var d := Vector3(cos(a), 0, sin(a))
		var y: float = 4.0 + (h - 10.0) * (i + 0.5) / baies
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * (r - 0.05) + Vector3(x, y, z)), 1.0, 2.4)
	if crenelee:
		k.crown(at(x, 0, z), r, h)
		if toit > 0.0:
			k.cyl("pierre", at(x, h, z), r * 0.7, r * 0.7, 3.0, 20, true)
			k.cone_roof(at(x, h + 3.0, z), r * 0.7, toit)
	else:
		k.cyl("pierre_claire", at(x, h - 0.4, z), r + 0.3, r + 0.3, 0.6, 28, false)
		k.cone_roof(at(x, h, z), r, toit)


# =================================================================== l'enceinte

const ENCEINTE := [[90.0, 75.0], [124.0, 74.0], [160.0, 73.0], [196.0, 74.0], [232.0, 71.0], [268.0, 73.0], [304.0, 72.0], [340.0, 74.0], [16.0, 74.0], [52.0, 75.0]]


func _enceinte_pts() -> Array:
	var pts: Array = []
	for e in ENCEINTE:
		var a: float = deg_to_rad(float(e[0]))
		pts.append(Vector3(cos(a), 0, sin(a)) * float(e[1]))
	return pts


func _enceinte() -> void:
	var k := Kit.new()
	var pts: Array = _enceinte_pts()
	var h: float = 11.0
	var ep: float = 3.2
	for i in range(pts.size()):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var dir: Vector3 = (b - a).normalized()
		# la porte (entre le premier point et le dernier, au sud) : la courtine s'arrête aux tours
		if i == 0:
			a = a + dir * 12.0
		if i == pts.size() - 1:
			b = b - dir * 12.0
		# (la courtine s'arrête dans le mur de la Grosse Tour, qui est creuse)
		for seg in _hors_grosse_tour(a, b):
			a = seg[0]
			b = seg[1]
			var len: float = a.distance_to(b)
			var mid: Vector3 = (a + b) * 0.5
			var yaw: float = atan2(dir.x, dir.z) + PI * 0.5
			var base: float = minf(sol(mid.x, mid.z), minf(sol(a.x, a.z), sol(b.x, b.z))) - 6.0
			var xf := Transform3D(Basis(Vector3.UP, yaw), mid)
			# le talus de la base (le mur s'élargit en descendant sur la falaise)
			k.box("socle", xf * Transform3D(Basis.IDENTITY, Vector3(0, base, 0)), Vector3(len, -base + 1.0, ep + 2.4))
			k.box("pierre", xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.0, 0)), Vector3(len, h - 1.0, ep), true)
			var out: Vector3 = mid.normalized() * Vector3(1, 0, 1)
			k.crenels(Transform3D.IDENTITY, a + Vector3(0, h + 1.0, 0) + out * (ep * 0.5 - 0.3), b + Vector3(0, h + 1.0, 0) + out * (ep * 0.5 - 0.3), 0.6)
			k.crenels(Transform3D.IDENTITY, a + Vector3(0, h + 0.4, 0) - out * (ep * 0.5 - 0.25), b + Vector3(0, h + 0.4, 0) - out * (ep * 0.5 - 0.25), 0.5)
			k.cordon(Transform3D.IDENTITY, a + Vector3(0, 1.2, 0) + out * ep * 0.5, b + Vector3(0, 1.2, 0) + out * ep * 0.5, out, 0.35)
			# les meurtrières
			var n: int = int(len / 9.0)
			for j in range(n):
				var p: Vector3 = a.lerp(b, (j + 0.5) / n) + out * (ep * 0.5 + 0.02) + Vector3(0, 5.0, 0)
				k.box("fer", Transform3D(Basis(Vector3.UP, yaw), p), Vector3(0.25, 2.2, 0.05))
	# les tours de l'enceinte (pas aux deux points de la porte : les tours de la porte y sont)
	for i in range(1, pts.size()):
		var p: Vector3 = pts[i]
		var tall: bool = i % 3 == 0
		_tour_ronde(k, p.x, p.z, 5.0 if not tall else 6.0, 19.0 if not tall else 25.0, 9.0 if not tall else 13.0, 2, tall, -10.0)
	# le sol du plateau : de grandes dalles dans toute l'enceinte (V197 : à 1,2 cm, sous le dallage des tours,
	# 2 cm : à 4 cm, il recouvrait le sol des salles du bas, le cercle de runes, la rose des vents, le tapis)
	var ctr := Vector3(0, 0.012, 0)
	for i in range(pts.size()):
		var a: Vector3 = pts[i] * 0.97 + Vector3(0, 0.012, 0)
		var b: Vector3 = pts[(i + 1) % pts.size()] * 0.97 + Vector3(0, 0.012, 0)
		k.tri("dalles", Transform3D.IDENTITY, ctr, a, b, Vector3.UP)
	_emit(k, "Ombrelac_enceinte")
	# l'esplanade (le sol du plateau près des murs : rien, le relief suffit)
	lieux["enceinte"] = Vector3.ZERO


## Les morceaux de [a, b] (une courtine) hors de la Grosse Tour : coupés à 6,75 m de part et d'autre
## du point le plus proche de son centre (les coins de la courtine restent dans l'épaisseur du mur)
func _hors_grosse_tour(a: Vector3, b: Vector3) -> Array:
	var g := Vector3(GROSSE.x, 0.0, GROSSE.z)
	var ab: Vector3 = b - a
	var L: float = ab.length()
	var d: Vector3 = ab / L
	var t: float = (g - a).dot(d)
	var dist: float = (a + d * t).distance_to(g)
	if dist > 6.0 or t < -7.0 or t > L + 7.0:
		return [[a, b]]
	var res: Array = []
	if t - 6.75 > 0.5:
		res.append([a, a + d * (t - 6.75)])
	if t + 6.75 < L - 0.5:
		res.append([a + d * (t + 6.75), b])
	return res


# =================================================================== la porte et le viaduc

func _porte() -> void:
	var k := Kit.new()
	var z: float = 74.0
	# les deux grosses tours
	for s in [-1.0, 1.0]:
		var x: float = s * 10.5
		k.cyl("socle", at(x, -14.0, z), 7.6, 7.0, 15.0, 28, false, true)
		k.cyl("pierre", at(x, 1.0, z), 7.0, 6.6, 24.0, 28, false, true)
		k.crown(at(x, 0, z), 6.6, 25.0)
		k.cyl("pierre", at(x, 25.0, z), 4.6, 4.6, 5.0, 20, true)
		k.cone_roof(at(x, 30.0, z), 4.6, 15.0)
		for i in range(3):
			var a: float = PI * 0.5 + s * (0.3 + i * 0.5)
			var d := Vector3(cos(a), 0, sin(a))
			k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * 6.75 + Vector3(x, 8.0 + i * 5.0, z)), 1.2, 2.8)
	# le châtelet entre les tours : la voûte du passage (ouvert), la chambre de la herse au-dessus
	var w: float = 7.0
	var hh: float = 10.0
	for s in [-1.0, 1.0]:
		k.box("pierre", at(s * (w * 0.5 + 1.5), 0.0, z), Vector3(3.0, hh, 14.0), true)
	k.box("pierre", at(0, hh, z), Vector3(w + 6.0, 12.0, 14.0), true)
	k.box("socle", at(0, -12.0, z + 3.0), Vector3(w + 6.0, 12.0, 8.0), true)
	# l'arc d'entrée (côté viaduc et côté cour) : un encadrement en ogive, la herse à moitié levée
	for e in [-1.0, 1.0]:
		var fx := Transform3D(Basis(Vector3.UP, 0.0 if e > 0 else PI), Vector3(0, 0, z + e * 7.0))
		var outl: PackedVector2Array = Kit.ogive(w, hh, 10)
		var outer: PackedVector2Array = Kit.ogive(w + 1.6, hh + 0.8, 10)
		for i in range(outl.size() - 1):
			var a: Vector2 = outl[i]
			var b: Vector2 = outl[i + 1]
			var oa: Vector2 = outer[i]
			var ob: Vector2 = outer[i + 1]
			k.quad("pierre_claire", fx, Vector3(a.x, a.y, 0.3), Vector3(b.x, b.y, 0.3), Vector3(ob.x, ob.y, 0.3), Vector3(oa.x, oa.y, 0.3), Vector3(0, 0, 1))
			k.quad("pierre_claire", fx, Vector3(oa.x, oa.y, 0.0), Vector3(ob.x, ob.y, 0.0), Vector3(ob.x, ob.y, 0.3), Vector3(oa.x, oa.y, 0.3), Vector3((oa.x + ob.x) * 0.5, (oa.y + ob.y) * 0.5 - hh * 0.5, 0))
			# le tympan au-dessus du passage : le mur plein jusqu'au haut de l'arc
			k.quad("pierre", fx, Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), Vector3(b.x, hh + 0.1, 0.0), Vector3(a.x, hh + 0.1, 0.0), Vector3(0, 0, 1))
		# le blason au-dessus de la porte : un écu doré
		k.box("or", fx * Transform3D(Basis.IDENTITY, Vector3(0, hh + 4.2, 0.1)), Vector3(2.2, 2.6, 0.3))
	# la herse (relevée : le bas des pointes à 6,5 m)
	for i in range(7):
		var x: float = -w * 0.5 + 0.5 + i * (w - 1.0) / 6.0
		k.box("fer", at(x, 6.5, z - 3.0), Vector3(0.18, hh - 6.5, 0.18))
	for j in range(3):
		k.box("fer", at(0, 7.0 + j * 1.2, z - 3.0), Vector3(w, 0.16, 0.16))
	# le sol du passage
	k.box("dalles", at(0, -0.6, z), Vector3(w, 0.62, 14.0), true)
	# les créneaux du châtelet
	k.crenels(Transform3D.IDENTITY, Vector3(-w * 0.5 - 3.0, hh + 13.0, z + 6.7), Vector3(w * 0.5 + 3.0, hh + 13.0, z + 6.7), 0.6)
	k.crenels(Transform3D.IDENTITY, Vector3(-w * 0.5 - 3.0, hh + 13.0, z - 6.7), Vector3(w * 0.5 + 3.0, hh + 13.0, z - 6.7), 0.6)
	_emit(k, "Ombrelac_porte")
	lieux["porte"] = Vector3(0, 0, z - 10.0)
	lieux["cour"] = Vector3(0, 0, 44.0)


func _viaduc() -> void:
	var k := Kit.new()
	var n_end := Vector3(0, 0, 81.0)
	var s_end := Vector3(Ile.VIADUC_S.x - Ile.ROC.x, Ile.VIADUC_S.y - Ile.ROC_Y, Ile.VIADUC_S.z - Ile.ROC.y)
	var length: float = Vector2(n_end.x, n_end.z).distance_to(Vector2(s_end.x, s_end.z))
	var spans: int = 7
	var span: float = length / spans
	var w: float = 7.0
	var ep: float = 1.4         # l'épaisseur du tablier
	for i in range(spans + 1):
		var t: float = float(i) / spans
		var p: Vector3 = n_end.lerp(s_end, t)
		var g: float = sol(p.x, p.z)
		# les piles : de gros piliers à avant-bec, de la gorge jusqu'au tablier
		if i > 0 and i < spans:
			var top: float = p.y - ep - span * 0.5
			var foot: float = minf(g, top) - 3.0
			k.box("socle", at(p.x, foot, p.z), Vector3(w + 1.4, top - foot, 4.2), true)
	# les arches : chaque travée, un mur percé d'un arc en plein cintre, des deux côtés
	for i in range(spans):
		var a: Vector3 = n_end.lerp(s_end, float(i) / spans)
		var b: Vector3 = n_end.lerp(s_end, float(i + 1) / spans)
		var mid: Vector3 = (a + b) * 0.5
		var dir: Vector3 = (b - a).normalized()
		var flat := Vector3(dir.x, 0, dir.z).normalized()
		var side: Vector3 = flat.cross(Vector3.UP).normalized()
		var seg: int = 12
		var r: float = span * 0.5 - 2.1
		for e in [-1.0, 1.0]:
			var off: Vector3 = side * e * (w * 0.5 + 0.7)
			for j in range(seg):
				var t0: float = float(j) / seg
				var t1: float = float(j + 1) / seg
				var c0: Vector3 = mid + flat * (-cos(PI * t0) * r)
				var c1: Vector3 = mid + flat * (-cos(PI * t1) * r)
				var y0: float = lerpf(a.y, b.y, (c0 - a).dot(flat) / maxf(span, 0.01)) - ep
				var y1: float = lerpf(a.y, b.y, (c1 - a).dot(flat) / maxf(span, 0.01)) - ep
				var top0: float = y0
				var top1: float = y1
				var bot0: float = top0 - span * 0.5 + sin(PI * t0) * r - 0.5
				var bot1: float = top1 - span * 0.5 + sin(PI * t1) * r - 0.5
				bot0 = minf(bot0, top0 - 0.8)
				bot1 = minf(bot1, top1 - 0.8)
				var p0 := Vector3(c0.x, bot0, c0.z) + off
				var p1 := Vector3(c1.x, bot1, c1.z) + off
				var q0 := Vector3(c0.x, top0, c0.z) + off
				var q1 := Vector3(c1.x, top1, c1.z) + off
				k.quad("pierre", Transform3D.IDENTITY, p0, p1, q1, q0, side * e)
				k.quad("pierre", Transform3D.IDENTITY, p0 - side * e * 1.4, p1 - side * e * 1.4, q1 - side * e * 1.4, q0 - side * e * 1.4, -side * e)
				# l'intrados (le dessous de l'arc)
				k.quad("pierre_claire", Transform3D.IDENTITY, p0, p1, p1 - side * e * 1.4, p0 - side * e * 1.4, Vector3(0, -1, 0))
		# le tablier : la chaussée dallée, le dessous, les parapets, une lanterne par pile
		var len: float = a.distance_to(b)
		var basis := Basis.looking_at(dir, Vector3.UP)
		var xf := Transform3D(basis, mid)
		k.box("dalles", xf * Transform3D(Basis.IDENTITY, Vector3(0, -0.25, 0)), Vector3(w, 0.25, len + 0.05))
		k.box("pierre", xf * Transform3D(Basis.IDENTITY, Vector3(0, -ep, 0)), Vector3(w + 1.4, ep - 0.25, len + 0.05), true)
		for e in [-1.0, 1.0]:
			k.box("pierre", xf * Transform3D(Basis.IDENTITY, Vector3(e * (w * 0.5 + 0.35), 0.0, 0)), Vector3(0.7, 1.15, len + 0.05), true)
			k.box("pierre_claire", xf * Transform3D(Basis.IDENTITY, Vector3(e * (w * 0.5 + 0.35), 1.15, 0)), Vector3(0.9, 0.2, len + 0.05))
		if i > 0:
			for e in [-1.0, 1.0]:
				var lp: Vector3 = a + side * e * (w * 0.5 + 0.35)
				k.cyl("fer", at(lp.x, lp.y + 1.3, lp.z), 0.09, 0.09, 3.2, 6, false)
				k.box("fer", at(lp.x, lp.y + 4.4, lp.z), Vector3(0.6, 0.08, 0.6))
				k.box("vitre", at(lp.x, lp.y + 3.8, lp.z), Vector3(0.45, 0.6, 0.45))
				k.cyl("fer", at(lp.x, lp.y + 4.45, lp.z), 0.42, 0.0, 0.4, 4, false)
	_emit(k, "Ombrelac_viaduc")
	lieux["viaduc_nord"] = n_end
	lieux["viaduc_sud"] = s_end


# =================================================================== la Grande Salle

func _grande_salle() -> void:
	var k := Kit.new()
	var c := Vector3(0, 0, 4.0)
	var L: float = 60.0
	var W: float = 21.0
	var H: float = 20.0
	var T: float = SALLE_T
	# le soubassement (le dessus juste sous le dallage de la salle), un bandeau de pierre au pied
	k.box("socle", at(c.x, -3.0, c.z), Vector3(L + 2.0, 2.95, W + 2.0), true)
	# les murs, épais et percés : les hautes baies des deux longs côtés, la porte au sud (derrière
	# le porche), la rose à l'est, la grande baie à l'ouest
	var n: int = 8
	var bx: Array = []
	for i in range(n):
		bx.append(-L * 0.5 + 0.7 + (i + 0.5) * (L - 1.4) / n)
	for s in [-1.0, 1.0]:
		var trous: Array = []
		var fen: Array = []
		for x in bx:
			if s > 0 and absf(x) < 6.0:
				continue
			fen.append(x)
		var xs: Array = fen.duplicate()
		if s > 0:
			xs.append(0.0)
			xs.sort()
		for x in xs:
			if s > 0 and x == 0.0:
				trous.append(Kit.trou_ogive(0.0, 0.0, SALLE_PORTE.x, SALLE_PORTE.y))
			else:
				# (le mur regardé du dehors : le côté nord est retourné, x change de signe)
				trous.append(Kit.trou_ogive(x * s, 6.0, 2.6, 11.0))
		trous.sort_custom(func(u, v): return u["xl"] < v["xl"])
		k.mur(Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(0, 0, c.z + s * W * 0.5)), L, H, T, trous)
		for x in fen:
			k.window(Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(x, 6.0, c.z + s * W * 0.5)), 2.6, 11.0, "vitrail")
		# le bandeau du pied, de part et d'autre de la porte
		for e in [-1.0, 1.0]:
			var xa: float = -L * 0.5 if e < 0 else (SALLE_PORTE.x * 0.5 if s > 0 else 0.0)
			var xb: float = (-SALLE_PORTE.x * 0.5 if s > 0 else 0.0) if e < 0 else L * 0.5
			k.box("socle", at((xa + xb) * 0.5, 0.0, c.z + s * (W * 0.5 + 0.15)), Vector3(xb - xa, 1.2, 0.3))
		k.cordon(Transform3D.IDENTITY, Vector3(-L * 0.5, H - 0.2, c.z + s * W * 0.5), Vector3(L * 0.5, H - 0.2, c.z + s * W * 0.5), Vector3(0, 0, s), 0.45)
		for i in range(n + 1):
			var x: float = -L * 0.5 + 0.7 + i * (L - 1.4) / n
			if s > 0 and absf(x) < 6.5:
				continue          # (derrière le porche)
			k.buttress(Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(x, 1.2, c.z + s * W * 0.5)), H - 3.0, 1.5, 3.0)
	# les pignons (entre les deux longs murs) : la rose à l'est, la grande baie à l'ouest
	var wi: float = W - 2.0 * T
	k.mur(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(L * 0.5, 0, c.z)), wi, H, T, [Kit.trou_rond(0.0, 13.0, 5.0)])
	k.rose(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(L * 0.5, 13.0, c.z)), 5.0)
	k.mur(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-L * 0.5, 0, c.z)), wi, H, T, [Kit.trou_ogive(0.0, 5.0, 5.0, 14.0)])
	k.window(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-L * 0.5, 5.0, c.z)), 5.0, 14.0, "vitrail")
	for e in [-1.0, 1.0]:
		k.box("socle", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(e * (L * 0.5 + 0.15), 0.0, c.z)), Vector3(W, 1.2, 0.3))
	k.gable_roof(at(c.x, H, c.z), L, W, 15.0)
	# les tourelles d'angle à l'est (deux fines tours à flèche)
	for s in [-1.0, 1.0]:
		var p := Vector3(L * 0.5 + 0.5, 0, c.z + s * (W * 0.5 + 0.5))
		k.cyl("pierre", at(p.x, 0.0, p.z), 2.3, 2.1, H + 9.0, 16, false, true)
		k.crown(at(p.x, 0, p.z), 2.1, H + 9.0, 12)
		k.cone_roof(at(p.x, H + 10.0, p.z), 1.8, 9.0, 16)
	# la flèche de la croisée : une fine lanterne ajourée, puis une aiguille d'ardoise
	k.prism("pierre_claire", at(0, H + 12.0, c.z), Kit.ngon(2.4, 8, PI / 8.0), 0.0, 7.0)
	for i in range(8):
		var a: float = TAU * i / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * 2.2 + Vector3(0, H + 13.5, c.z)), 0.8, 3.6, "vitre", 0.2)
	k.spire(at(0, H + 19.0, c.z), 2.6, 26.0)
	# le grand porche au sud : un massif de 6 m percé d'un passage voûté en ogive (on y passe)
	var pz: float = c.z + W * 0.5
	k.mur(Transform3D(Basis.IDENTITY, Vector3(0, 0, pz + 6.0)), 12.0, 13.0, 6.0, [Kit.trou_ogive(0.0, 0.0, 6.0, 10.0)], "pierre", "pierre")
	k.gable_roof(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 13.0, pz + 3.0)), 6.0, 12.0, 6.5)
	var fx := Transform3D(Basis.IDENTITY, Vector3(0, 0, pz + 6.0))
	var outl: PackedVector2Array = Kit.ogive(6.0, 10.0, 10)
	var outer: PackedVector2Array = Kit.ogive(8.4, 11.2, 10)
	for i in range(outl.size() - 1):
		var a: Vector2 = outl[i]
		var b: Vector2 = outl[i + 1]
		var oa: Vector2 = outer[i]
		var ob: Vector2 = outer[i + 1]
		k.quad("pierre_claire", fx, Vector3(a.x, a.y, 0.4), Vector3(b.x, b.y, 0.4), Vector3(ob.x, ob.y, 0.4), Vector3(oa.x, oa.y, 0.4), Vector3(0, 0, 1))
		k.quad("pierre_claire", fx, Vector3(oa.x, oa.y, 0.0), Vector3(ob.x, ob.y, 0.0), Vector3(ob.x, ob.y, 0.4), Vector3(oa.x, oa.y, 0.4), Vector3((oa.x + ob.x) * 0.5, (oa.y + ob.y) * 0.5 - 5.0, 0))
	# le tympan sculpté au-dessus du passage
	k.box("pierre_claire", at(0, 7.6, pz + 5.8), Vector3(6.0, 2.4, 0.3))
	# le dallage : le perron, le passage du porche, la salle
	k.box("dalles", at(0, -0.4, pz + 8.0), Vector3(10.0, 0.4, 4.0))
	k.box("dalles", at(0, -0.25, pz + 3.0), Vector3(6.2, 0.25, 6.0), true)
	k.box("dalles_int", at(c.x, -0.25, c.z), Vector3(L - 2.0 * T, 0.25, W - 2.0 * T), true)
	# le plafond : une charpente de bois sous le toit, lambrissée (on la voit du dedans)
	var hl: float = L * 0.5 - T
	var hw: float = W * 0.5 - T
	for s in [-1.0, 1.0]:
		k.quad("lambris", Transform3D.IDENTITY, Vector3(-hl, H, c.z + s * hw), Vector3(hl, H, c.z + s * hw), Vector3(hl, H + SALLE_VOUTE, c.z), Vector3(-hl, H + SALLE_VOUTE, c.z), Vector3(0, -1, -s))
	for e in [-1.0, 1.0]:
		k.tri("pierre_int", Transform3D.IDENTITY, Vector3(e * hl, H, c.z - hw), Vector3(e * hl, H, c.z + hw), Vector3(e * hl, H + SALLE_VOUTE, c.z), Vector3(-e, 0, 0))
	_emit(k, "Ombrelac_grande_salle")
	lieux["grande_salle_porte"] = Vector3(0, 0, pz + 9.0)
	lieux["grande_salle"] = c
	lieux["grande_salle_dedans"] = Vector3(0, 0, c.z + 2.0)
	# l'intérieur : les tables, la charpente, la cheminée, les lustres, les bannières
	var inter = Interieurs.new()
	inter.name = "Ombrelac_interieurs"
	add_child(inter)
	inter.grande_salle(c, L, W, H, T, SALLE_VOUTE, bx)


# =================================================================== la Tour de l'Astrolabe

func _donjon() -> void:
	var k := Kit.new()
	var p := DONJON
	var hs: float = DONJON_HS    # demi-côté de la tour carrée
	var h1: float = DONJON_H1    # le haut de la partie carrée
	var T: float = DONJON_T
	var HH: float = DONJON_HALL
	# le socle (le plancher de la salle du bas à 0), son bandeau tout autour, coupé devant la porte
	k.box("socle", at(p.x, -10.0, p.z), Vector3(hs * 2.0 + 2.0, 9.95, hs * 2.0 + 2.0), true)
	for f0 in range(4):
		var yw: float = f0 * PI * 0.5
		var o0 := Vector3(sin(yw), 0, cos(yw))
		var r0 := Vector3(cos(yw), 0, -sin(yw))
		if f0 == 1:
			for e0 in [-1.0, 1.0]:
				var lg: float = hs + 1.0 - 1.6
				k.box("socle", Transform3D(Basis(Vector3.UP, yw), p + o0 * (hs + 0.5) + r0 * e0 * (1.6 + lg * 0.5) + Vector3(0, -0.05, 0)), Vector3(lg, 1.45, 1.0), true)
		else:
			k.box("socle", Transform3D(Basis(Vector3.UP, yw), p + o0 * (hs + 0.5) + Vector3(0, -0.05, 0)), Vector3(hs * 2.0 + 2.0, 1.45, 1.0), true)
	# la salle du bas : quatre murs épais percés de leurs baies (et, à l'est, de la porte)
	for f1 in range(4):
		var yw1: float = f1 * PI * 0.5
		var o1 := Vector3(sin(yw1), 0, cos(yw1))
		var trous: Array = [Kit.trou_ogive(-3.6, 5.0, 1.5, 4.2), Kit.trou_ogive(3.6, 5.0, 1.5, 4.2)]
		if f1 == 1:
			trous.insert(1, Kit.trou_ogive(0.0, 0.0, 2.6, 4.6))
			_portail(k, Transform3D(Basis(Vector3.UP, yw1), p + o1 * hs), 2.6, 4.6)
		var lw: float = hs * 2.0 if f1 % 2 == 0 else hs * 2.0 - 2.0 * T
		k.mur(Transform3D(Basis(Vector3.UP, yw1), p + o1 * hs), lw, HH, T, trous)
	# au-dessus, la maçonnerie pleine jusqu'à la terrasse, percée du puits de la Nacelle
	var pz0: float = PUITS.z - PUITS_HS
	var pz1: float = PUITS.z + PUITS_HS
	var hp: float = h1 - HH
	k.box("pierre", at(p.x, HH, p.z + (pz1 + hs) * 0.5), Vector3(hs * 2.0, hp, hs - pz1), true)
	k.box("pierre", at(p.x, HH, p.z + (pz0 - hs) * 0.5), Vector3(hs * 2.0, hp, pz0 + hs), true)
	for e1 in [-1.0, 1.0]:
		k.box("pierre", at(p.x + e1 * (PUITS_HS + hs) * 0.5, HH, p.z + PUITS.z), Vector3(hs - PUITS_HS, hp, PUITS_HS * 2.0), true)
	# un perron devant la porte (à l'est)
	var ys0: float = sol(p.x + hs + 1.6, p.z)
	k.box("pierre_claire", at(p.x + hs + 1.4, minf(ys0, 0.0) - 1.0, p.z), Vector3(1.8, 1.0 - minf(ys0, 0.0), 3.6), true)
	# les contreforts d'angle, les cordons à chaque étage, les baies
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			for side in [0, 1]:
				var yaw: float = (0.0 if cz > 0 else PI) if side == 0 else (PI * 0.5 if cx > 0 else -PI * 0.5)
				var off := Vector3(cx * (hs - 0.8), 1.4, cz * hs) if side == 0 else Vector3(cx * hs, 1.4, cz * (hs - 0.8))
				k.buttress(Transform3D(Basis(Vector3.UP, yaw), p + off), h1 - 10.0, 1.6, 2.2)
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var face: Vector3 = p + out * hs
		for et in range(6):
			var y: float = 5.0 + et * 8.2
			k.cordon(Transform3D.IDENTITY, face - right * hs + Vector3(0, y - 1.2, 0), face + right * hs + Vector3(0, y - 1.2, 0), out, 0.3)
			for j in [-1.0, 1.0]:
				k.window(Transform3D(Basis(Vector3.UP, yaw), face + right * j * 3.6 + Vector3(0, y, 0)), 1.5, 4.2 if et < 5 else 5.2, "vitre")
	# les échauguettes (tourelles en encorbellement aux quatre coins, en haut de la partie carrée)
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			var q: Vector3 = p + Vector3(cx * hs, 0, cz * hs)
			k.cyl("pierre", at(q.x, h1 - 6.0, q.z), 0.4, 2.2, 3.0, 16, false)
			k.cyl("pierre", at(q.x, h1 - 3.0, q.z), 2.2, 2.2, 6.0, 16, false)
			k.cone_roof(at(q.x, h1 + 3.0, q.z), 2.2, 7.0, 16)
	# la plate-forme crénelée en haut de la partie carrée
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var face: Vector3 = p + out * (hs - 0.3)
		k.crenels(Transform3D.IDENTITY, face - right * (hs - 2.2) + Vector3(0, h1 + 1.0, 0), face + right * (hs - 2.2) + Vector3(0, h1 + 1.0, 0), 0.6)
	# le parapet de la terrasse (on ne tombe pas), les échauguettes (on ne les traverse pas)
	for f2 in range(4):
		var yw2: float = f2 * PI * 0.5
		var o2 := Vector3(sin(yw2), 0, cos(yw2))
		var col := BoxShape3D.new()
		col.size = Vector3(hs * 2.0, 1.7, 0.7)
		k.shapes.append([col, Transform3D(Basis(Vector3.UP, yw2), p + o2 * (hs - 0.3) + Vector3(0, h1 + 0.85, 0))])
	for cx2 in [-1.0, 1.0]:
		for cz2 in [-1.0, 1.0]:
			var ce := CylinderShape3D.new()
			ce.radius = 2.2
			ce.height = 6.0
			k.shapes.append([ce, at(p.x + cx2 * hs, h1, p.z + cz2 * hs)])
	# la partie octogonale : en bas, l'Observatoire (huit pans de mur, des portes sur la terrasse à
	# l'est, au sud, à l'ouest) ; au-dessus, plein
	var r2: float = DONJON_R2
	var h2: float = 30.0
	var OH: float = DONJON_OBS
	var apo: float = r2 * cos(PI / 8.0)
	var cote: float = 2.0 * r2 * sin(PI / 8.0)
	k.prism("pierre", at(p.x, h1 + OH, p.z), Kit.ngon(r2, 8, PI / 8.0), 0.0, h2 - OH)
	for i in range(8):
		var a: float = TAU * i / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var face: Vector3 = p + d * apo
		var bs := Basis(Vector3.UP, atan2(d.x, d.z))
		var porte: bool = i == 0 or i == 2 or i == 4
		var lb: float = 1.8 if porte else 1.6
		var colonne: Array = [Kit.trou_ogive(0.0, 4.0, lb, 7.0)]
		if porte:
			colonne.insert(0, Kit.trou_ogive(0.0, 0.0, lb, 3.4))
			_portail(k, Transform3D(bs, face + Vector3(0, h1, 0)), lb, 3.4)
		k.mur_col(Transform3D(bs, face + Vector3(0, h1, 0)), cote + 0.02, OH, 1.0, [colonne])
		k.window(Transform3D(bs, face + Vector3(0, h1 + 4.0, 0)), lb, 7.0, "vitre")
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), face + Vector3(0, h1 + 15.0, 0)), 1.6, 7.5, "vitre")
		# les pinacles aux angles de l'octogone
		var corner: Vector3 = p + Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * r2
		k.cyl("pierre_claire", at(corner.x, h1 + h2, corner.z), 0.7, 0.0, 4.5, 4, false)
	k.crown(at(p.x, h1, p.z), r2, h2, 16)
	# la flèche
	k.prism("pierre", at(p.x, h1 + h2, p.z), Kit.ngon(r2 * 0.8, 8, PI / 8.0), 0.0, 3.0)
	k.spire(at(p.x, h1 + h2 + 3.0, p.z), r2 * 0.85, 44.0)
	_emit(k, "Ombrelac_astrolabe")
	var astro = Astrolabe.new()
	astro.name = "Ombrelac_astrolabe_dedans"
	add_child(astro)
	astro.construire_astrolabe(p, hs, T, HH, h1, OH, apo - 1.0, PUITS, PUITS_HS)
	for key in astro.lieux:
		lieux[key] = astro.lieux[key]
	lieux["astrolabe"] = p + Vector3(0, 0, hs + 2.0)


# =================================================================== la Tour de l'Horloge

func _horloge() -> void:
	var k := Kit.new()
	var p := HORLOGE
	var hs: float = HORLOGE_HS
	var h: float = HORLOGE_H
	var T: float = HORLOGE_T
	var cy: float = HORLOGE_CADRAN_Y
	# le socle (le plancher de la salle des poids à 0), son bandeau tout autour, coupé devant la porte
	k.box("socle", at(p.x, -5.0, p.z), Vector3(hs * 2.0 + 1.2, 4.95, hs * 2.0 + 1.2), true)
	for f0 in range(4):
		var yw: float = f0 * PI * 0.5
		var o0 := Vector3(sin(yw), 0, cos(yw))
		var r0 := Vector3(cos(yw), 0, -sin(yw))
		if f0 == 3:
			for e0 in [-1.0, 1.0]:
				var lg: float = hs + 0.6 - 1.5
				k.box("socle", Transform3D(Basis(Vector3.UP, yw), p + o0 * (hs + 0.3) + r0 * e0 * (1.5 + lg * 0.5) + Vector3(0, -0.05, 0)), Vector3(lg, 1.25, 0.6), true)
		else:
			k.box("socle", Transform3D(Basis(Vector3.UP, yw), p + o0 * (hs + 0.3) + Vector3(0, -0.05, 0)), Vector3(hs * 2.0 + 1.2, 1.25, 0.6), true)
	# quatre murs épais : en bas la porte (à l'ouest, sur la cour), au milieu trois rangs de baies,
	# en haut le cadran (un oculus fermé d'un verre, voir horloge_ombrelac.gd)
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var face: Vector3 = p + out * hs
		var bs := Basis(Vector3.UP, yaw)
		var lw: float = hs * 2.0 if f % 2 == 0 else hs * 2.0 - 2.0 * T
		var bas: Array = []
		if f == 3:
			bas.append(Kit.trou_ogive(0.0, 0.0, 2.4, 4.2))
			_portail(k, Transform3D(bs, face), 2.4, 4.2)
		k.mur(Transform3D(bs, face), lw, 5.0, T, bas)
		var baies: Array = []
		for et in range(3):
			baies.append(Kit.trou_ogive(0.0, 1.0 + et * 8.0, 1.4, 4.0))
			k.window(Transform3D(bs, face + Vector3(0, 6.0 + et * 8.0, 0)), 1.4, 4.0)
			k.cordon(Transform3D.IDENTITY, face - right * hs + Vector3(0, 4.6 + et * 8.0, 0), face + right * hs + Vector3(0, 4.6 + et * 8.0, 0), out, 0.25)
		k.mur_col(Transform3D(bs, face + Vector3(0, 5.0, 0)), lw, 25.0, T, [baies])
		k.mur(Transform3D(bs, face + Vector3(0, 30.0, 0)), lw, h - 30.0, T, [Kit.trou_rond(0.0, cy - 30.0, HORLOGE_CADRAN_R)])
		# le verre du cadran arrête le héros
		var vc := BoxShape3D.new()
		vc.size = Vector3(HORLOGE_CADRAN_R * 2.0, HORLOGE_CADRAN_R * 2.0, 0.4)
		k.shapes.append([vc, Transform3D(bs, face + Vector3(0, cy, 0) - out * 0.4)])
		# les échauguettes d'angle
		var q: Vector3 = p + out * hs + right * hs
		k.cyl("pierre", at(q.x, h - 4.0, q.z), 0.3, 1.5, 2.0, 12, false)
		k.cyl("pierre", at(q.x, h - 2.0, q.z), 1.5, 1.5, 4.0, 12, false)
		k.cone_roof(at(q.x, h + 2.0, q.z), 1.5, 5.0, 12)
	k.cyl("pierre_claire", at(p.x, h - 0.3, p.z), hs * 1.45, hs * 1.45, 0.5, 4, false)
	k.hip_roof(Transform3D(Basis(Vector3.UP, 0.0), Vector3(p.x, h, p.z)), hs, hs, 10.0, false)
	# le lanternon
	k.box("pierre_claire", at(p.x, h + 8.0, p.z), Vector3(3.0, 4.0, 3.0))
	k.hip_roof(at(p.x, h + 12.0, p.z), 1.5, 1.5, 4.5)
	_emit(k, "Ombrelac_horloge")
	lieux["horloge"] = p + Vector3(0, 0, hs + 2.0)
	# le dedans : la salle des poids, l'escalier, la chambre des rouages, les cadrans, la cloche
	var horl = Horloge.new()
	horl.name = "Ombrelac_horloge_dedans"
	add_child(horl)
	horl.construire_horloge(p, hs, T, h, cy, HORLOGE_CADRAN_R)
	for key in horl.lieux:
		lieux[key] = horl.lieux[key]


# =================================================================== les ailes

## Une aile : un long bâtiment à deux pans ; c au milieu, à terre ; yaw : faîtage selon x tourné
## (rez > 0 : le rez-de-chaussée est laissé vide, jusqu'à la hauteur rez ; on y bâtit des salles)
func _aile(k: RefCounted, c: Vector3, yaw: float, L: float, W: float, H: float, et: int, rez: float = 0.0, etage: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	if rez > 0.0:
		var plein: float = etage if etage > 0.0 else rez
		k.box("socle", Transform3D(b, c + Vector3(0, -4.0, 0)), Vector3(L + 1.2, 3.95, W + 1.2), true)
		k.box("pierre", Transform3D(b, c + Vector3(0, plein, 0)), Vector3(L, H - plein, W), true)
	else:
		k.box("socle", Transform3D(b, c + Vector3(0, -4.0, 0)), Vector3(L + 1.2, 5.2, W + 1.2), true)
		k.box("pierre", Transform3D(b, c + Vector3(0, 1.2, 0)), Vector3(L, H - 1.2, W), true)
	k.gable_roof(Transform3D(b, c + Vector3(0, H, 0)), L, W, W * 0.7)
	var n: int = int(L / 5.5)
	for s in [-1.0, 1.0]:
		var out: Vector3 = b * Vector3(0, 0, s)
		for e in range(et):
			if rez > 0.0 and e == 0:
				continue
			if etage > 0.0 and e == 1:
				continue
			var y: float = 3.5 + e * (H - 4.0) / et
			var a: Vector3 = c + b * Vector3(-L * 0.5, y, s * W * 0.5)
			var bb: Vector3 = c + b * Vector3(L * 0.5, y, s * W * 0.5)
			_baies(k, a, bb, out, n, 1.4, (H - 4.0) / et - 2.6)
			k.cordon(Transform3D.IDENTITY, a - Vector3(0, 1.0, 0), bb - Vector3(0, 1.0, 0), out, 0.25)
		# les lucarnes sur le toit
		for i in range(n / 2):
			var x: float = -L * 0.5 + (i + 0.5) * L / (n / 2)
			var lx := Transform3D(b * Basis(Vector3.UP, 0.0 if s > 0 else PI), c + b * Vector3(x, H - 0.3, s * (W * 0.5 - 1.6)))
			k.box("pierre", lx, Vector3(2.2, 3.4, 2.4))
			k.window(lx * Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 1.2)), 1.1, 2.2)
			k.gable_roof(lx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 3.4, -0.2)), 2.8, 2.2, 1.8, false, true)
	# les cheminées
	for i in range(3):
		var x: float = -L * 0.35 + i * L * 0.35
		var cp: Vector3 = c + b * Vector3(x, H + W * 0.35, 0)
		k.box("pierre", Transform3D(b, cp), Vector3(1.6, W * 0.4 + 2.0, 3.0))
		k.box("pierre_claire", Transform3D(b, cp + Vector3(0, W * 0.4 + 2.0, 0)), Vector3(2.0, 0.4, 3.4))


func _aile_nord() -> void:
	# l'Aile des Dortoirs ; au rez-de-chaussée, côté cloître, les trois salles d'étude (la Salle des
	# Astres, la Salle des Élixirs, l'Amphithéâtre), chacune sa porte sous la galerie du cloître
	var k := Kit.new()
	var c := Vector3(12.0, 0, -46.0)
	var L: float = 56.0
	var W: float = 13.0
	var T: float = 1.2
	var rz: float = SALLES_RZ
	var E: float = DORTOIRS_HAUT
	_aile(k, c, 0.0, L, W, 18.0, 3, rz, E)
	var xf := Transform3D(Basis.IDENTITY, c)
	var n: int = 10
	var bay: float = L / n
	for s in [-1.0, 1.0]:
		var trous: Array = []
		var trous1: Array = []
		var portes: Array = SALLES_PORTES if s > 0 else []
		var rot := Basis(Vector3.UP, 0.0 if s > 0 else PI)
		for i in range(n):
			var x: float = -L * 0.5 + (i + 0.5) * bay
			# l'étage des dortoirs : une baie par travée
			trous1.append(Kit.trou_ogive(x * s, 1.5, 1.6, 3.2))
			k.window(xf * Transform3D(rot, Vector3(x, rz + 1.5, s * W * 0.5)), 1.6, 3.2)
			var gene: bool = false
			for px in portes:
				if absf(px - x) < 2.2:
					gene = true
			if gene:
				continue
			trous.append(Kit.trou_ogive(x * s, 1.1, 1.6, 3.4))
			k.window(xf * Transform3D(rot, Vector3(x, 1.1, s * W * 0.5)), 1.6, 3.4)
		for px2 in portes:
			trous.append(Kit.trou_ogive(px2, 0.0, 2.4, 4.4))
			_portail(k, xf * Transform3D(Basis.IDENTITY, Vector3(px2, 0, W * 0.5)), 2.4, 4.4)
		trous.sort_custom(func(u, v): return u["xl"] < v["xl"])
		trous1.sort_custom(func(u, v): return u["xl"] < v["xl"])
		k.mur(xf * Transform3D(rot, Vector3(0, 0, s * W * 0.5)), L, rz, T, trous)
		k.mur(xf * Transform3D(rot, Vector3(0, rz, s * W * 0.5)), L, E - rz, T, trous1)
		# le cordon qui marque le plancher de l'étage
		k.cordon(Transform3D.IDENTITY, c + Vector3(-L * 0.5, rz, s * W * 0.5), c + Vector3(L * 0.5, rz, s * W * 0.5), Vector3(0, 0, s), 0.25)
	# le pignon ouest (au pied de la tour ronde) ; à l'est, la tour de l'escalier
	k.mur(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-L * 0.5, 0, 0)), W - 2.0 * T, E, T, [])
	_bout_est(k, xf, L, W, T, rz, E)
	# les murs de refend entre les salles (et, à l'étage, entre les dortoirs et la salle commune)
	var dp: Vector2 = Dortoirs.PORTE_REFEND
	var F: float = rz + Dortoirs.PLANCHER
	var hw: float = W * 0.5 - T
	for xr in SALLES_REFENDS:
		k.box("pierre_int", xf * at(xr, 0.0, 0.0), Vector3(0.6, rz, W - 2.0 * T), true)
		k.box("pierre_int", xf * at(xr, rz, (-hw + dp.x) * 0.5), Vector3(0.6, E - rz, dp.x + hw), true)
		k.box("pierre_int", xf * at(xr, rz, (dp.y + hw) * 0.5), Vector3(0.6, E - rz, hw - dp.y), true)
		k.box("pierre_int", xf * at(xr, F + 2.6, (dp.x + dp.y) * 0.5), Vector3(0.6, E - F - 2.6, dp.y - dp.x), true)
	_tour_ronde(k, -17.5, -46.0, 5.6, 38.0, 16.0, 5)
	_tour_escalier(k, TOUR_ESC.x, TOUR_ESC.z, TOUR_ESC_R, 44.0, 17.0, 5)
	# (la Grosse Tour du nord-est : _grosse_tour)
	_emit(k, "Ombrelac_aile_nord")
	lieux["dortoirs"] = c + Vector3(0, 0, 8.5)
	var sl = Salles.new()
	sl.name = "Ombrelac_salles"
	add_child(sl)
	sl.construire_salles(xf, L, W, rz, T, SALLES_REFENDS, SALLES_PORTES, SALLES_BOUT, [true, false])
	for key in sl.lieux:
		lieux[key] = sl.lieux[key]
	var dt = Dortoirs.new()
	dt.name = "Ombrelac_dortoirs"
	add_child(dt)
	dt.construire_dortoirs(xf, L, W, rz, E, T, SALLES_REFENDS, SALLES_BOUT, TOUR_ESC - c, TOUR_ESC_R - TOUR_ESC_T, TOUR_ESC_PORTES)
	for key2 in dt.lieux:
		lieux[key2] = dt.lieux[key2]


## Le bout est de l'Aile nord, contre la tour de l'escalier : de la maçonnerie pleine (des
## tranches, qui s'arrêtent au mur rond du dedans de la tour) ; à l'étage, le passage de la tour
## vers le dortoir
func _bout_est(k: RefCounted, xf: Transform3D, L: float, W: float, T: float, rz: float, E: float) -> void:
	var tc: Vector3 = TOUR_ESC - xf.origin
	var ri: float = TOUR_ESC_R - TOUR_ESC_T
	var x0: float = L * 0.5 - T - SALLES_BOUT
	var hw: float = W * 0.5 - T
	var F: float = rz + Dortoirs.PLANCHER
	var pz: float = Dortoirs.PASSAGE_Z
	var bornes: Array = [-hw]
	var z: float = -hw
	while z < -pz - 0.01:
		z = minf(z + 0.5, -pz)
		bornes.append(z)
	bornes.append(pz)
	z = pz
	while z < hw - 0.01:
		z = minf(z + 0.5, hw)
		bornes.append(z)
	for i in range(bornes.size() - 1):
		var za: float = bornes[i]
		var zb: float = bornes[i + 1]
		var zp: float = minf(absf(za), absf(zb)) if za * zb > 0.0 else 0.0
		var x1: float = L * 0.5
		if zp < ri:
			x1 = minf(x1, tc.x - sqrt(ri * ri - zp * zp) - 0.02)
		if x1 <= x0:
			continue
		var t := Transform3D(Basis.IDENTITY, Vector3((x0 + x1) * 0.5, 0.0, (za + zb) * 0.5))
		if absf(za + zb) < 0.01:
			# le passage : la maçonnerie dessous (jusqu'au dallage), dessus (le linteau)
			k.box("pierre_int", xf * t, Vector3(x1 - x0, F - 0.1, zb - za), true)
			k.box("pierre_int", xf * t * Transform3D(Basis.IDENTITY, Vector3(0, F + 2.6, 0)), Vector3(x1 - x0, E - F - 2.6, zb - za), true)
		else:
			k.box("pierre_int", xf * t, Vector3(x1 - x0, E, zb - za), true)


## La tour de l'escalier (au bout est de l'Aile nord) : une tour ronde creuse, son mur épais monté
## pan par pan (le dehors, le dedans, la collision), percé de ses portes ; le haut comme les autres
func _tour_escalier(k: RefCounted, x: float, z: float, r: float, h: float, toit: float, baies: int) -> void:
	var sides: int = 28
	var ri: float = r - TOUR_ESC_T
	var y0: float = minf(-8.0, sol(x, z) - 1.0)
	var c := Vector3(x, 0, z)
	var slope: float = (r * 1.04 - r) / (h - 1.2)
	for i in range(sides):
		var a0: float = TAU * i / sides
		var a1: float = TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var dm: Vector3 = (d0 + d1).normalized()
		# les tranches de hauteur pleines de ce pan : [bas, haut], percées par les portes
		var pleins: Array = [[y0, h]]
		for po in TOUR_ESC_PORTES:
			var i0: int = int(po[0])
			if i < i0 or i >= i0 + int(po[2]):
				continue
			var yb: float = float(po[1])
			var yt: float = yb + float(po[3])
			var nv: Array = []
			for pl in pleins:
				if yt <= pl[0] or yb >= pl[1]:
					nv.append(pl)
				else:
					if yb > pl[0]:
						nv.append([pl[0], yb])
					if yt < pl[1]:
						nv.append([yt, pl[1]])
			pleins = nv
			# les ébrasements de la porte (sur les bords du groupe de pans), le linteau, le seuil
			if i == i0:
				k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * ri + Vector3(0, yb, 0), c + d0 * r * 1.04 + Vector3(0, yb, 0), c + d0 * r * 1.04 + Vector3(0, yt, 0), c + d0 * ri + Vector3(0, yt, 0), d0.cross(Vector3.UP))
			if i == i0 + int(po[2]) - 1:
				k.quad("pierre_claire", Transform3D.IDENTITY, c + d1 * r * 1.04 + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yt, 0), c + d1 * r * 1.04 + Vector3(0, yt, 0), Vector3.UP.cross(d1))
			k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * ri + Vector3(0, yt, 0), c + d1 * ri + Vector3(0, yt, 0), c + d1 * r * 1.04 + Vector3(0, yt, 0), c + d0 * r * 1.04 + Vector3(0, yt, 0), Vector3.DOWN)
			k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * r * 1.04 + Vector3(0, yb, 0), c + d1 * r * 1.04 + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yb, 0), c + d0 * ri + Vector3(0, yb, 0), Vector3.UP)
		for pl in pleins:
			var ya: float = float(pl[0])
			var yb2: float = float(pl[1])
			# le dehors : le socle (jusqu'à 1,2 m), puis le fût, un peu de fruit
			var ys: float = clampf(1.2, ya, yb2)
			if ys > ya:
				var rs0: float = lerpf(r * 1.12, r * 1.04, (ya - y0) / (1.2 - y0))
				var rs1: float = lerpf(r * 1.12, r * 1.04, (ys - y0) / (1.2 - y0))
				k.quad("socle", Transform3D.IDENTITY, c + d0 * rs0 + Vector3(0, ya, 0), c + d1 * rs0 + Vector3(0, ya, 0), c + d1 * rs1 + Vector3(0, ys, 0), c + d0 * rs1 + Vector3(0, ys, 0), dm)
				if ys >= 1.2 and absf(ys - 1.2) < 0.001:
					k.quad("socle", Transform3D.IDENTITY, c + d0 * r * 1.04 + Vector3(0, 1.2, 0), c + d1 * r * 1.04 + Vector3(0, 1.2, 0), c + d1 * r * 1.12 * 0.999 + Vector3(0, 1.2, 0), c + d0 * r * 1.12 * 0.999 + Vector3(0, 1.2, 0), Vector3.UP)
			if yb2 > ys:
				var ra: float = r * 1.04 - slope * (ys - 1.2)
				var rb: float = r * 1.04 - slope * (yb2 - 1.2)
				k.quad("pierre", Transform3D.IDENTITY, c + d0 * ra + Vector3(0, ys, 0), c + d1 * ra + Vector3(0, ys, 0), c + d1 * rb + Vector3(0, yb2, 0), c + d0 * rb + Vector3(0, yb2, 0), dm)
			# le dedans (au-dessus du sol de la tour, jusqu'au plafond de l'étage)
			var ia: float = maxf(ya, -0.3)
			var ib: float = minf(yb2, DORTOIRS_HAUT + 0.3)
			if ib > ia:
				k.quad("pierre_int", Transform3D.IDENTITY, c + d1 * ri + Vector3(0, ia, 0), c + d0 * ri + Vector3(0, ia, 0), c + d0 * ri + Vector3(0, ib, 0), c + d1 * ri + Vector3(0, ib, 0), -dm)
			# la collision : une boîte par pan et par tranche
			var cy0: float = maxf(ya, -2.0)
			if yb2 > cy0:
				var rm: float = (ri + r) * 0.5
				var bs := BoxShape3D.new()
				bs.size = Vector3((r + 0.1) * TAU / sides * 1.08, yb2 - cy0, r - ri + 0.1)
				var yaw: float = atan2(dm.x, dm.z)
				k.shapes.append([bs, Transform3D(Basis(Vector3.UP, yaw), c + dm * rm + Vector3(0, (cy0 + yb2) * 0.5, 0))])
	# les baies : en spirale autour du fût
	for i in range(baies):
		var a: float = 0.7 + i * 2.1
		var d := Vector3(cos(a), 0, sin(a))
		var y: float = 4.0 + (h - 10.0) * (i + 0.5) / baies
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * (r - 0.05) + Vector3(x, y, z)), 1.0, 2.4)
	k.cyl("pierre_claire", at(x, h - 0.4, z), r + 0.3, r + 0.3, 0.6, 28, false)
	k.cone_roof(at(x, h, z), r, toit)
	# le dessus du mur, au pied du toit (on ne voit pas dedans par les côtés du toit)
	k.cyl("pierre", at(x, h - 0.02, z), ri, ri, 0.02, 28, true)
	# un perron de trois marches devant la porte du bas
	var dp: float = TAU * (float(TOUR_ESC_PORTES[0][0]) + 0.5 * float(TOUR_ESC_PORTES[0][2])) / sides
	var dd := Vector3(cos(dp), 0, sin(dp))
	var pp: Vector3 = c + dd * (r * 1.12 + 0.6)
	var ys0: float = sol(pp.x, pp.z)
	k.box("pierre_claire", Transform3D(Basis(Vector3.UP, atan2(dd.x, dd.z)), pp + Vector3(0, minf(ys0, 0.0) - 1.0, 0)), Vector3(2.0, 1.0 - minf(ys0, 0.0), 1.4), true)
	# l'encadrement de la porte : les piédroits, le linteau, la clé
	var tg := Vector3(-dd.z, 0, dd.x)
	var bp := Basis(tg, Vector3.UP, dd)
	var hp: float = float(TOUR_ESC_PORTES[0][3])
	var dmi: float = r * 1.12 * 0.97
	var demi: float = r * 1.04 * sin(TAU / sides * float(TOUR_ESC_PORTES[0][2]) * 0.5)
	for e in [-1.0, 1.0]:
		k.box("pierre_claire", Transform3D(bp, c + dd * dmi + tg * e * (demi + 0.2)), Vector3(0.45, hp, 0.5))
	k.box("pierre_claire", Transform3D(bp, c + dd * dmi + Vector3(0, hp, 0)), Vector3(demi * 2.0 + 0.85, 0.5, 0.55))
	k.box("pierre_claire", Transform3D(bp, c + dd * (dmi + 0.08) + Vector3(0, hp - 0.12, 0)), Vector3(0.4, 0.72, 0.5))
	k.box("pierre", Transform3D(bp, c + dd * dmi + Vector3(0, hp + 0.5, 0)), Vector3(demi * 2.0 + 1.05, 0.12, 0.7))


## Un portail en ogive (l'encadrement de pierre claire), xf au milieu du bas, sur la face du mur
func _portail(k: RefCounted, fx: Transform3D, w: float, h: float) -> void:
	var outl: PackedVector2Array = Kit.ogive(w, h, 10)
	var outer: PackedVector2Array = Kit.ogive(w + 1.0, h + 0.5, 10)
	for i in range(outl.size() - 1):
		var a2: Vector2 = outl[i]
		var b2: Vector2 = outl[i + 1]
		var oa: Vector2 = outer[i]
		var ob: Vector2 = outer[i + 1]
		k.quad("pierre_claire", fx, Vector3(a2.x, a2.y, 0.3), Vector3(b2.x, b2.y, 0.3), Vector3(ob.x, ob.y, 0.3), Vector3(oa.x, oa.y, 0.3), Vector3(0, 0, 1))
		k.quad("pierre_claire", fx, Vector3(oa.x, oa.y, 0.0), Vector3(ob.x, ob.y, 0.0), Vector3(ob.x, ob.y, 0.3), Vector3(oa.x, oa.y, 0.3), Vector3((oa.x + ob.x) * 0.5, (oa.y + ob.y) * 0.5 - h * 0.5, 0))


func _aile_est() -> void:
	# l'Aile des Études : la Bibliothèque de l'Académie. Une seule grande salle sur toute la hauteur,
	# les murs épais percés de deux rangs de baies (les tables de lecture, la galerie), la porte sur
	# la cour à l'ouest, un plafond lambrissé sous le toit.
	var k := Kit.new()
	var c := Vector3(52.0, 0, -8.0)
	var L: float = 44.0
	var W: float = 13.0
	var H: float = 16.0
	var T: float = BIBLIO_T
	var b := Basis(Vector3.UP, PI * 0.5)
	var xf := Transform3D(b, c)
	k.box("socle", xf * at(0, -4.0, 0), Vector3(L + 1.2, 3.95, W + 1.2), true)
	var n: int = 8
	for s in [-1.0, 1.0]:
		var trous: Array = []
		for i in range(n):
			var x: float = -L * 0.5 + (i + 0.5) * L / n
			trous.append(Kit.trou_ogive(x * s, 1.2, 1.8, 3.6))
			trous.append(Kit.trou_ogive(x * s, 7.0, 1.8, 4.5))
		if s < 0:
			trous.append(Kit.trou_ogive(0.0, 0.0, BIBLIO_PORTE.x, BIBLIO_PORTE.y))
		# (un mur : les baies d'une même colonne, de bas en haut, ne se chevauchent pas en x ;
		# mur() les veut de gauche à droite : on les range par colonne, la porte entre deux)
		var cols: Array = _colonnes(trous)
		var wxf: Transform3D = xf * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(0, 0, s * W * 0.5))
		k.mur_col(wxf, L, H, T, cols)
		for i in range(n):
			var x: float = -L * 0.5 + (i + 0.5) * L / n
			var wx: Transform3D = xf * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(x, 0, s * W * 0.5))
			k.window(wx * at(0, 1.2, 0), 1.8, 3.6)
			k.window(wx * at(0, 7.0, 0), 1.8, 4.5)
		if s > 0:
			k.box("socle", xf * at(0, 0.0, s * (W * 0.5 + 0.15)), Vector3(L, 0.9, 0.3))
		else:
			for e5 in [-1.0, 1.0]:
				var xa5: float = e5 * (BIBLIO_PORTE.x * 0.5 + 0.5)
				var xb5: float = e5 * L * 0.5
				k.box("socle", xf * at((xa5 + xb5) * 0.5, 0.0, s * (W * 0.5 + 0.15)), Vector3(absf(xb5 - xa5), 0.9, 0.3))
		k.cordon(xf, Vector3(-L * 0.5, 6.2, s * W * 0.5), Vector3(L * 0.5, 6.2, s * W * 0.5), Vector3(0, 0, s), 0.25)
		k.cordon(xf, Vector3(-L * 0.5, H - 0.2, s * W * 0.5), Vector3(L * 0.5, H - 0.2, s * W * 0.5), Vector3(0, 0, s), 0.4)
		# les lucarnes sur le toit
		for i in range(4):
			var x2: float = -L * 0.5 + (i + 0.5) * L / 4.0
			var lx: Transform3D = xf * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(x2, H + 0.6, s * (W * 0.5 - 1.6)))
			k.box("pierre", lx, Vector3(2.2, 3.4, 2.4))
			k.window(lx * Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 1.2)), 1.1, 2.2)
			k.gable_roof(lx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 3.4, -0.2)), 2.8, 2.2, 1.8, false, true)
	# les pignons
	for e in [-1.0, 1.0]:
		k.mur(xf * Transform3D(Basis(Vector3.UP, e * PI * 0.5), Vector3(e * L * 0.5, 0, 0)), W - 2.0 * T, H, T, [])
	k.gable_roof(xf * at(0, H, 0), L, W, W * 0.7)
	# la porte : l'encadrement en ogive, sur la cour
	var px: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -W * 0.5))
	var outl: PackedVector2Array = Kit.ogive(BIBLIO_PORTE.x, BIBLIO_PORTE.y, 10)
	var outer: PackedVector2Array = Kit.ogive(BIBLIO_PORTE.x + 1.0, BIBLIO_PORTE.y + 0.5, 10)
	for i in range(outl.size() - 1):
		var a2: Vector2 = outl[i]
		var b2: Vector2 = outl[i + 1]
		var oa: Vector2 = outer[i]
		var ob: Vector2 = outer[i + 1]
		k.quad("pierre_claire", px, Vector3(a2.x, a2.y, 0.35), Vector3(b2.x, b2.y, 0.35), Vector3(ob.x, ob.y, 0.35), Vector3(oa.x, oa.y, 0.35), Vector3(0, 0, 1))
		k.quad("pierre_claire", px, Vector3(oa.x, oa.y, 0.0), Vector3(ob.x, ob.y, 0.0), Vector3(ob.x, ob.y, 0.35), Vector3(oa.x, oa.y, 0.35), Vector3((oa.x + ob.x) * 0.5, (oa.y + ob.y) * 0.5 - 3.0, 0))
	k.box("dalles", px * at(0, -0.3, 1.6), Vector3(5.0, 0.3, 3.2), true)
	# le plancher de chêne, le lambris peint
	var hl: float = L * 0.5 - T
	var hw: float = W * 0.5 - T
	k.box("parquet", xf * at(0, -0.2, 0), Vector3(hl * 2.0, 0.2, hw * 2.0), true)
	for s2 in [-1.0, 1.0]:
		k.quad("lambris", xf, Vector3(-hl, H, s2 * hw), Vector3(hl, H, s2 * hw), Vector3(hl, H + BIBLIO_VOUTE, 0), Vector3(-hl, H + BIBLIO_VOUTE, 0), Vector3(0, -1, -s2))
	for e2 in [-1.0, 1.0]:
		k.tri("pierre_int", xf, Vector3(e2 * hl, H, -hw), Vector3(e2 * hl, H, hw), Vector3(e2 * hl, H + BIBLIO_VOUTE, 0), Vector3(-e2, 0, 0))
	# les cheminées, la tour d'angle
	for i in range(3):
		var x3: float = -L * 0.35 + i * L * 0.35
		var cp: Vector3 = xf * Vector3(x3, H + W * 0.35, 0)
		k.box("pierre", Transform3D(b, cp), Vector3(1.6, W * 0.4 + 2.0, 3.0))
		k.box("pierre_claire", Transform3D(b, cp + Vector3(0, W * 0.4 + 2.0, 0)), Vector3(2.0, 0.4, 3.4))
	_tour_ronde(k, 52.0, -32.5, 4.4, 24.0, 11.0, 3)
	_emit(k, "Ombrelac_aile_est")
	lieux["etudes"] = xf * Vector3(0, 0, -W * 0.5 - 2.5)
	lieux["bibliotheque_porte"] = lieux["etudes"]
	lieux["bibliotheque"] = xf * Vector3(0.0, 0, -1.8)
	var bib = Bibliotheque.new()
	bib.name = "Ombrelac_bibliotheque"
	add_child(bib)
	bib.construire(xf, L, W, H, T, BIBLIO_VOUTE)
	lieux["bibliotheque_galerie"] = bib.lieux["galerie"]


## Les baies d'un mur rangées par colonnes (celles qui se chevauchent en x vont ensemble)
func _colonnes(trous: Array) -> Array:
	var t2: Array = trous.duplicate()
	t2.sort_custom(func(u, v): return u["xl"] < v["xl"])
	var cols: Array = []
	for tr in t2:
		if not cols.is_empty() and tr["xl"] < cols[-1][-1]["xr"] - 0.01:
			cols[-1].append(tr)
		else:
			cols.append([tr])
	for col in cols:
		col.sort_custom(func(u, v): return u["yb"] < v["yb"])
	return cols


func _cloitre() -> void:
	var k := Kit.new()
	# le préau : quatre galeries d'arcades autour d'un jardin, une fontaine au milieu
	var x0: float = -18.0
	var x1: float = 38.0
	var z0: float = -37.0
	var z1: float = -9.0
	var gw: float = 4.0
	var gh: float = 5.0
	var sides := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(0, 0, 1)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(-1, 0, 0)],
		[Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector3(0, 0, -1)], [Vector3(x0, 0, z1), Vector3(x0, 0, z0), Vector3(1, 0, 0)]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var b: Vector3 = sd[1]
		var inw: Vector3 = sd[2]
		var len: float = a.distance_to(b)
		var dir: Vector3 = (b - a) / len
		var n: int = int(len / 3.6)
		# les colonnettes et les arcs
		for i in range(n + 1):
			var p: Vector3 = a + dir * (len * i / n) + inw * gw
			k.cyl("pierre_claire", at(p.x, 0.0, p.z), 0.32, 0.28, gh - 1.2, 10, false, true)
			k.box("pierre_claire", at(p.x, gh - 1.2, p.z), Vector3(0.8, 0.3, 0.8))
		var yaw: float = atan2(inw.x, inw.z)
		for i in range(n):
			var p: Vector3 = a + dir * (len * (i + 0.5) / n) + inw * gw
			var w: float = len / n - 0.6
			var fx := Transform3D(Basis(Vector3.UP, yaw), p)
			var outl: PackedVector2Array = Kit.ogive(w, gh - 0.9, 8)
			for j in range(1, outl.size() - 2):
				var q0: Vector2 = outl[j]
				var q1: Vector2 = outl[j + 1]
				if q0.y < gh - 1.4 and q1.y < gh - 1.4:
					continue
				k.quad("pierre", fx, Vector3(q0.x, q0.y, 0.3), Vector3(q1.x, q1.y, 0.3), Vector3(q1.x, gh + 0.6, 0.3), Vector3(q0.x, gh + 0.6, 0.3), Vector3(0, 0, 1))
				k.quad("pierre", fx, Vector3(q0.x, q0.y, -0.3), Vector3(q1.x, q1.y, -0.3), Vector3(q1.x, gh + 0.6, -0.3), Vector3(q0.x, gh + 0.6, -0.3), Vector3(0, 0, -1))
				k.quad("pierre_claire", fx, Vector3(q0.x, q0.y, -0.3), Vector3(q1.x, q1.y, -0.3), Vector3(q1.x, q1.y, 0.3), Vector3(q0.x, q0.y, 0.3), Vector3(-(q0.x + q1.x), gh - q0.y, 0))
		# la frise au-dessus des arcs, le toit en appentis de la galerie
		var mid: Vector3 = (a + b) * 0.5 + inw * gw
		k.box("pierre", Transform3D(Basis(Vector3.UP, yaw), mid + Vector3(0, gh + 0.6, 0)), Vector3(len + 0.8, 1.2, 0.6))
		var r0: Vector3 = a + inw * (gw + 0.6) + Vector3(0, gh + 1.8, 0) - dir * 0.4
		var r1: Vector3 = b + inw * (gw + 0.6) + Vector3(0, gh + 1.8, 0) + dir * 0.4
		var r2: Vector3 = b + Vector3(0, gh + 4.2, 0) + dir * 0.4
		var r3: Vector3 = a + Vector3(0, gh + 4.2, 0) - dir * 0.4
		var sl: float = r1.distance_to(r2)
		k.quad("ardoise", Transform3D.IDENTITY, r0, r1, r2, r3, inw + Vector3(0, 1.6, 0), Vector2(0, 0), Vector2(len, 0), Vector2(len, sl), Vector2(0, sl))
		# le sol de la galerie
		k.box("dalles", Transform3D(Basis(Vector3.UP, yaw), (a + b) * 0.5 + inw * gw * 0.5 + Vector3(0, 0.0, 0)), Vector3(len, 0.2, gw))
	# le jardin : un gazon (le relief), des allées en croix, la fontaine
	var cc := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	k.box("gazon", at(cc.x, 0.0, cc.z), Vector3(x1 - x0 - gw * 2.0, 0.12, z1 - z0 - gw * 2.0))
	k.box("dalles", at(cc.x, 0.0, cc.z), Vector3(x1 - x0 - gw * 2.0, 0.16, 2.4))
	k.box("dalles", at(cc.x, 0.0, cc.z), Vector3(2.4, 0.16, z1 - z0 - gw * 2.0))
	k.cyl("pierre_claire", at(cc.x, -0.1, cc.z), 4.2, 4.2, 0.8, 24, true, true)
	k.cyl("pierre_claire", at(cc.x, 0.7, cc.z), 4.4, 4.4, 0.2, 24, true)
	k.cyl("pierre", at(cc.x, 0.0, cc.z), 0.8, 0.6, 2.8, 12)
	k.cyl("pierre_claire", at(cc.x, 2.8, cc.z), 0.3, 1.6, 0.6, 16)
	k.cyl("pierre_claire", at(cc.x, 3.4, cc.z), 0.3, 0.3, 1.2, 8)
	_emit(k, "Ombrelac_cloitre")
	lieux["cloitre"] = cc + Vector3(0, 0, 5.0)
	lieux["fontaine"] = cc


func _tour_sortileges() -> void:
	var k := Kit.new()
	_tour_creuse(k, SORT.x, SORT.z, SORT_R, SORT_H, SORT_T, SORT_PORTES, SORT_PLAFOND, -14.0)
	for i in range(7):
		var a: float = 0.7 + i * 2.1
		var d := Vector3(cos(a), 0, sin(a))
		var y: float = 4.0 + (SORT_H - 10.0) * (i + 0.5) / 7
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * (SORT_R - 0.05) + Vector3(SORT.x, y, SORT.z)), 1.0, 2.4)
	k.crown(at(SORT.x, 0, SORT.z), SORT_R, SORT_H)
	k.cyl("pierre", at(SORT.x, SORT_H, SORT.z), SORT_R * 0.7, SORT_R * 0.7, 3.0, 20, true)
	k.cone_roof(at(SORT.x, SORT_H + 3.0, SORT.z), SORT_R * 0.7, 26.0)
	# le plancher de la salle du bas, plein dessous
	k.cyl("socle", at(SORT.x, -1.2, SORT.z), SORT_R - SORT_T + 0.15, SORT_R - SORT_T + 0.15, 1.18, 28, true, true)
	# le perron de la porte (à l'est), l'encadrement ; le balcon (à l'ouest, sur le lac)
	_portes_tour_creuse(k, SORT.x, SORT.z, SORT_R, SORT_PORTES)
	_balcon_sortileges(k)
	# une galerie qui la relie à la Grande Salle
	k.box("pierre", at(-40.0, 0.0, 22.0), Vector3(16.0, 10.0, 6.0), true)
	k.gable_roof(at(-40.0, 10.0, 22.0), 16.0, 6.0, 4.0, false)
	_baies(k, Vector3(-48.0, 3.5, 25.0), Vector3(-32.0, 3.5, 25.0), Vector3(0, 0, 1), 3, 1.4, 4.0)
	_emit(k, "Ombrelac_sortileges")
	lieux["sortileges"] = Vector3(-52.0, 0, 42.0)
	var so = Sortileges.new()
	so.name = "Ombrelac_sortileges_dedans"
	add_child(so)
	so.construire_sortileges(SORT, SORT_R, SORT_T, SORT_CABINET, SORT_PLAFOND)
	for key in so.lieux:
		lieux[key] = so.lieux[key]


## Une tour ronde creuse, pan par pan (comme la Tour des Dortoirs) : le socle, le fût (un peu de
## fruit), le parement du dedans jusqu'à « ihaut », les portes (des pans ouverts, qui peuvent
## passer d'un bout à l'autre du cercle), la collision par pan et par tranche
func _tour_creuse(k: RefCounted, x: float, z: float, r: float, h: float, T: float, portes: Array, ihaut: float, base: float) -> void:
	var sides: int = 28
	var ri: float = r - T
	var y0: float = minf(base, sol(x, z) - 1.0)
	var c := Vector3(x, 0, z)
	var slope: float = (r * 1.04 - r) / (h - 1.2)
	for i in range(sides):
		var a0: float = TAU * i / sides
		var a1: float = TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var dm: Vector3 = (d0 + d1).normalized()
		var pleins: Array = [[y0, h]]
		for po in portes:
			var i0: int = int(po[0])
			var np: int = int(po[2])
			var rel: int = posmod(i - i0, sides)
			if rel >= np:
				continue
			var yb: float = float(po[1])
			var yt: float = yb + float(po[3])
			var nv: Array = []
			for pl in pleins:
				if yt <= pl[0] or yb >= pl[1]:
					nv.append(pl)
				else:
					if yb > pl[0]:
						nv.append([pl[0], yb])
					if yt < pl[1]:
						nv.append([yt, pl[1]])
			pleins = nv
			var ro: float = r * 1.04 - slope * maxf(yb - 1.2, 0.0)
			if yb < 1.2:
				ro = r * 1.12
			if rel == 0:
				k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * ri + Vector3(0, yb, 0), c + d0 * ro + Vector3(0, yb, 0), c + d0 * ro + Vector3(0, yt, 0), c + d0 * ri + Vector3(0, yt, 0), d0.cross(Vector3.UP))
			if rel == np - 1:
				k.quad("pierre_claire", Transform3D.IDENTITY, c + d1 * ro + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yt, 0), c + d1 * ro + Vector3(0, yt, 0), Vector3.UP.cross(d1))
			k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * ri + Vector3(0, yt, 0), c + d1 * ri + Vector3(0, yt, 0), c + d1 * ro + Vector3(0, yt, 0), c + d0 * ro + Vector3(0, yt, 0), Vector3.DOWN)
			k.quad("pierre_claire", Transform3D.IDENTITY, c + d0 * ro + Vector3(0, yb, 0), c + d1 * ro + Vector3(0, yb, 0), c + d1 * ri + Vector3(0, yb, 0), c + d0 * ri + Vector3(0, yb, 0), Vector3.UP)
		for pl in pleins:
			var ya: float = float(pl[0])
			var yb2: float = float(pl[1])
			var ys: float = clampf(1.2, ya, yb2)
			if ys > ya:
				var rs0: float = lerpf(r * 1.12, r * 1.04, (ya - y0) / (1.2 - y0))
				var rs1: float = lerpf(r * 1.12, r * 1.04, (ys - y0) / (1.2 - y0))
				k.quad("socle", Transform3D.IDENTITY, c + d0 * rs0 + Vector3(0, ya, 0), c + d1 * rs0 + Vector3(0, ya, 0), c + d1 * rs1 + Vector3(0, ys, 0), c + d0 * rs1 + Vector3(0, ys, 0), dm)
				if absf(ys - 1.2) < 0.001:
					k.quad("socle", Transform3D.IDENTITY, c + d0 * r * 1.04 + Vector3(0, 1.2, 0), c + d1 * r * 1.04 + Vector3(0, 1.2, 0), c + d1 * r * 1.12 * 0.999 + Vector3(0, 1.2, 0), c + d0 * r * 1.12 * 0.999 + Vector3(0, 1.2, 0), Vector3.UP)
			if yb2 > ys:
				var ra: float = r * 1.04 - slope * (ys - 1.2)
				var rb: float = r * 1.04 - slope * (yb2 - 1.2)
				k.quad("pierre", Transform3D.IDENTITY, c + d0 * ra + Vector3(0, ys, 0), c + d1 * ra + Vector3(0, ys, 0), c + d1 * rb + Vector3(0, yb2, 0), c + d0 * rb + Vector3(0, yb2, 0), dm)
			var ia: float = maxf(ya, -0.3)
			var ib: float = minf(yb2, ihaut + 0.3)
			if ib > ia:
				k.quad("pierre_int", Transform3D.IDENTITY, c + d1 * ri + Vector3(0, ia, 0), c + d0 * ri + Vector3(0, ia, 0), c + d0 * ri + Vector3(0, ib, 0), c + d1 * ri + Vector3(0, ib, 0), -dm)
			var cy0: float = maxf(ya, -2.0)
			if yb2 > cy0:
				var rm: float = (ri + r) * 0.5
				var bs := BoxShape3D.new()
				bs.size = Vector3((r + 0.1) * TAU / sides * 1.08, yb2 - cy0, r - ri + 0.1)
				var yaw: float = atan2(dm.x, dm.z)
				k.shapes.append([bs, Transform3D(Basis(Vector3.UP, yaw), c + dm * rm + Vector3(0, (cy0 + yb2) * 0.5, 0))])
	# le dessus du creux : un disque plein au plafond (on ne voit pas le ciel par les côtés)
	k.cyl("pierre", at(x, ihaut + 0.3, z), ri, ri, 0.02, 28, true)


## Les portes d'une tour creuse : l'encadrement (piédroits, linteau, clé), un perron devant celle
## du bas
func _portes_tour_creuse(k: RefCounted, x: float, z: float, r: float, portes: Array) -> void:
	var sides: int = 28
	var c := Vector3(x, 0, z)
	for po in portes:
		var dp: float = TAU * (float(po[0]) + 0.5 * float(po[2])) / sides
		var dd := Vector3(cos(dp), 0, sin(dp))
		var yb: float = float(po[1])
		var tg := Vector3(-dd.z, 0, dd.x)
		var bp := Basis(tg, Vector3.UP, dd)
		var hp: float = float(po[3])
		var dmi: float = (r * 1.12 if yb < 1.2 else r * 1.04) * 0.97
		var demi: float = r * 1.04 * sin(TAU / sides * float(po[2]) * 0.5)
		var b0 := Vector3(0, yb, 0)
		if yb < 1.2:
			var pp: Vector3 = c + dd * (r * 1.12 + 0.6)
			var ys0: float = sol(pp.x, pp.z)
			k.box("pierre_claire", Transform3D(Basis(Vector3.UP, atan2(dd.x, dd.z)), pp + Vector3(0, minf(ys0, 0.0) - 1.0, 0)), Vector3(demi * 2.0 + 0.8, 1.0 - minf(ys0, 0.0), 1.4), true)
		for e in [-1.0, 1.0]:
			k.box("pierre_claire", Transform3D(bp, c + dd * dmi + tg * e * (demi + 0.2) + b0), Vector3(0.45, hp, 0.5))
		k.box("pierre_claire", Transform3D(bp, c + dd * dmi + b0 + Vector3(0, hp, 0)), Vector3(demi * 2.0 + 0.85, 0.5, 0.55))
		k.box("pierre_claire", Transform3D(bp, c + dd * (dmi + 0.08) + b0 + Vector3(0, hp - 0.12, 0)), Vector3(0.4, 0.72, 0.5))


## Le balcon du Cabinet des Sortilèges, à l'ouest, au-dessus du lac : la dalle sur ses consoles, la
## balustrade (qui arrête le héros)
func _balcon_sortileges(k: RefCounted) -> void:
	var po: Array = SORT_PORTES[1]
	var dp: float = TAU * (float(po[0]) + 0.5 * float(po[2])) / 28.0
	var dd := Vector3(cos(dp), 0, sin(dp))
	var tg := Vector3(-dd.z, 0, dd.x)
	var bp := Basis(-tg, Vector3.UP, dd)
	var y: float = float(po[1])
	var r0: float = SORT_R * 0.98
	var prof: float = 2.4
	var lg: float = 3.6
	var cpl: Vector3 = SORT + dd * (r0 + prof * 0.5) + Vector3(0, y, 0)
	k.box("pierre_claire", Transform3D(bp, cpl - Vector3(0, 0.35, 0)), Vector3(lg, 0.35, prof + 0.4), true)
	k.box("dalles", Transform3D(bp, cpl - Vector3(0, 0.02, 0)), Vector3(lg - 0.1, 0.03, prof + 0.3))
	for e in [-1.2, 0.0, 1.2]:
		k.box("pierre", Transform3D(bp, SORT + dd * (r0 + 0.6) + tg * e + Vector3(0, y - 1.6, 0)), Vector3(0.45, 1.25, 1.2))
		k.box("pierre", Transform3D(bp, SORT + dd * (r0 + 1.4) + tg * e + Vector3(0, y - 0.95, 0)), Vector3(0.4, 0.6, 0.9))
	# la balustrade : trois côtés, des balustres, la main courante, la collision
	var bout: Vector3 = SORT + dd * (r0 + prof) + Vector3(0, y, 0)
	var cotes: Array = [[bout - tg * lg * 0.5, bout + tg * lg * 0.5]]
	for e2 in [-1.0, 1.0]:
		cotes.append([SORT + dd * r0 * 1.03 + tg * e2 * lg * 0.5 + Vector3(0, y, 0), bout + tg * e2 * lg * 0.5])
	for cc in cotes:
		var a: Vector3 = cc[0]
		var b: Vector3 = cc[1]
		var n: int = int(a.distance_to(b) / 0.32)
		for i in range(n + 1):
			var q: Vector3 = a.lerp(b, float(i) / n)
			k.cyl("pierre_claire", Transform3D(Basis.IDENTITY, q), 0.07, 0.1, 0.9, 6)
		var dir: Vector3 = (b - a).normalized()
		var bb := Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir)
		k.box("pierre_claire", Transform3D(bb, (a + b) * 0.5 + Vector3(0, 0.9, 0)), Vector3(0.24, 0.14, a.distance_to(b) + 0.24))
		var gs := BoxShape3D.new()
		gs.size = Vector3(0.3, 1.4, a.distance_to(b) + 0.2)
		k.shapes.append([gs, Transform3D(bb, (a + b) * 0.5 + Vector3(0, 0.7, 0))])


# =================================================================== la Grosse Tour

## La Grosse Tour du nord-est : massive, crénelée, un haut toit ; creuse : la porte sur la cour (au
## sud-ouest), le dedans (grosse_tour_ombrelac.gd)
func _grosse_tour() -> void:
	var k := Kit.new()
	var x: float = GROSSE.x
	var z: float = GROSSE.z
	var r: float = GROSSE_R
	_tour_creuse(k, x, z, r, GROSSE_H, GROSSE_T, GROSSE_PORTES, GROSSE_PLAFOND, -12.0)
	for b in GROSSE_BAIES:
		var d := Vector3(cos(deg_to_rad(float(b[0]))), 0, sin(deg_to_rad(float(b[0]))))
		var y: float = float(b[1])
		var rr: float = r * 1.04 - (r * 1.04 - r) * (y - 1.2) / (GROSSE_H - 1.2)
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * (rr - 0.05) + Vector3(x, y, z)), 1.1, 2.8)
	k.crown(at(x, 0, z), r, GROSSE_H)
	# le dessus du mur, sous le chemin de ronde (on ne voit pas dans le creux)
	k.cyl("pierre", at(x, GROSSE_H - 0.02, z), r - GROSSE_T + 0.05, r - GROSSE_T + 0.05, 0.02, 28, true)
	k.cyl("pierre", at(x, GROSSE_H, z), r * 0.7, r * 0.7, 3.0, 20, true)
	k.cone_roof(at(x, GROSSE_H + 3.0, z), r * 0.7, 22.0)
	# le plancher de la salle du bas, plein dessous
	k.cyl("socle", at(x, -1.2, z), r - GROSSE_T + 0.15, r - GROSSE_T + 0.15, 1.18, 28, true, true)
	_portes_tour_creuse(k, x, z, r, GROSSE_PORTES)
	_emit(k, "Ombrelac_grosse_tour")
	lieux["grosse_tour"] = GROSSE + Vector3(-9.0, 0.0, 7.0)
	var gt = GrosseTour.new()
	gt.name = "Ombrelac_grosse_tour_dedans"
	add_child(gt)
	var vb: Array = []
	for b2 in GROSSE_BAIES:
		if float(b2[1]) + 2.8 < GROSSE_PLAFOND:
			vb.append(b2)
	gt.construire_grosse_tour(GROSSE, r, GROSSE_T, GROSSE_E1, GROSSE_E2, GROSSE_PLAFOND, vb)
	for key in gt.lieux:
		lieux[key] = gt.lieux[key]


# =================================================================== le Pont Couvert et la Tour des Vents

func _pont_couvert() -> void:
	var k := Kit.new()
	var t := Vector3(Ile.AIGUILLE.x - Ile.ROC.x, Ile.AIGUILLE_Y - Ile.ROC_Y, Ile.AIGUILLE.y - Ile.ROC.y)
	var dir: Vector3 = Vector3(t.x, 0, t.z).normalized()
	var a: Vector3 = dir * 70.0
	var b: Vector3 = Vector3(t.x, 0, t.z) - dir * 6.5
	# la Tour des Vents, sur l'Aiguille
	k.cyl("socle", at(t.x, t.y - 6.0, t.z), 8.2, 7.4, 7.0, 28, false)
	k.cyl("pierre", at(t.x, t.y + 1.0, t.z), 7.4, 6.8, 30.0, 28, false, true)
	for i in range(6):
		var an: float = i * 1.3
		var d := Vector3(cos(an), 0, sin(an))
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * 6.95 + Vector3(t.x, t.y + 6.0 + i * 4.0, t.z)), 1.2, 3.0)
	k.crown(at(t.x, t.y, t.z), 6.8, 31.0)
	k.cyl("pierre", at(t.x, t.y + 31.0, t.z), 4.8, 4.8, 6.0, 20, false)
	for i in range(8):
		var an: float = TAU * i / 8.0
		var d := Vector3(cos(an), 0, sin(an))
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), d * 4.75 + Vector3(t.x, t.y + 32.0, t.z)), 0.9, 2.4)
	k.cone_roof(at(t.x, t.y + 37.0, t.z), 4.8, 20.0)
	# le pont : des piles dans le lac, un tablier, des arcades de bois, un toit d'ardoise
	var len: float = a.distance_to(b)
	var n: int = int(len / 11.0)
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	var yaw: float = atan2(dir.x, dir.z)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		var g: float = sol(p.x, p.z)
		if i > 0 and i < n:
			k.box("socle", Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, g - 4.0, p.z)), Vector3(5.0, -g + 2.5, 3.0), true)
		for e in [-1.0, 1.0]:
			var q: Vector3 = p + side * e * 2.3
			k.box("bois", Transform3D(Basis(Vector3.UP, yaw), q), Vector3(0.35, 4.2, 0.35))
			# les aisseliers
			k.box("bois", Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.7), q + Vector3(0, 3.4, 0.0)), Vector3(0.25, 1.6, 0.25))
	var mid: Vector3 = (a + b) * 0.5
	var bx := Transform3D(Basis(Vector3.UP, yaw), mid)
	k.box("dalles", bx * Transform3D(Basis.IDENTITY, Vector3(0, -0.3, 0)), Vector3(4.6, 0.3, len), true)
	k.box("pierre", bx * Transform3D(Basis.IDENTITY, Vector3(0, -1.6, 0)), Vector3(5.0, 1.3, len))
	for e in [-1.0, 1.0]:
		k.box("bois", bx * Transform3D(Basis.IDENTITY, Vector3(e * 2.3, 0.0, 0)), Vector3(0.3, 1.1, len), true)
		k.box("bois", bx * Transform3D(Basis.IDENTITY, Vector3(e * 2.3, 4.1, 0)), Vector3(0.4, 0.4, len))
	k.gable_roof(Transform3D(Basis(Vector3.UP, yaw - PI * 0.5), mid + Vector3(0, 4.4, 0)), len, 4.6, 2.6, false, false)
	# l'arrivée côté château : une petite porte dans l'enceinte
	k.box("pierre", Transform3D(Basis(Vector3.UP, yaw), a + Vector3(0, 0, 0)), Vector3(7.0, 8.0, 3.0))
	_emit(k, "Ombrelac_pont_couvert")
	lieux["pont_couvert"] = a - dir * 4.0
	lieux["pont_milieu"] = (a + b) * 0.5
	lieux["tour_vents"] = t


# =================================================================== les serres

func _serres() -> void:
	var k := Kit.new()
	for i in range(2):
		var c := Vector3(54.0, 0, 30.0 + i * 13.0)
		var L: float = 18.0
		var W: float = 8.0
		var H: float = 3.2
		k.box("socle", at(c.x, -0.5, c.z), Vector3(L, 1.3, W), true)
		# les parois et le toit de verre (des vitres claires), la charpente de fer
		for s in [-1.0, 1.0]:
			k.quad("vitre", Transform3D.IDENTITY, c + Vector3(-L * 0.5, 0.8, s * W * 0.5), c + Vector3(L * 0.5, 0.8, s * W * 0.5), c + Vector3(L * 0.5, H, s * W * 0.5), c + Vector3(-L * 0.5, H, s * W * 0.5), Vector3(0, 0, s))
			k.quad("vitre", Transform3D.IDENTITY, c + Vector3(-L * 0.5, H, s * W * 0.5), c + Vector3(L * 0.5, H, s * W * 0.5), c + Vector3(L * 0.5, H + 2.6, 0), c + Vector3(-L * 0.5, H + 2.6, 0), Vector3(0, 1.5, s))
		for e in [-1.0, 1.0]:
			k.quad("vitre", Transform3D.IDENTITY, c + Vector3(e * L * 0.5, 0.8, -W * 0.5), c + Vector3(e * L * 0.5, 0.8, W * 0.5), c + Vector3(e * L * 0.5, H, W * 0.5), c + Vector3(e * L * 0.5, H, -W * 0.5), Vector3(e, 0, 0))
			k.tri("vitre", Transform3D.IDENTITY, c + Vector3(e * L * 0.5, H, -W * 0.5), c + Vector3(e * L * 0.5, H, W * 0.5), c + Vector3(e * L * 0.5, H + 2.6, 0), Vector3(e, 0, 0))
		for j in range(7):
			var x: float = -L * 0.5 + j * L / 6.0
			for s in [-1.0, 1.0]:
				k.box("fer", at(c.x + x, 0.8, c.z + s * W * 0.5), Vector3(0.12, H - 0.8, 0.12))
				k.box("fer", Transform3D(Basis(Vector3.RIGHT, -s * atan2(W * 0.5, 2.6)), c + Vector3(x, H, s * W * 0.5)), Vector3(0.12, Vector2(W * 0.5, 2.6).length(), 0.12))
		k.box("fer", at(c.x, H + 2.55, c.z), Vector3(L, 0.15, 0.2))
		k.finial(at(c.x - L * 0.5, H + 2.6, c.z), 0.4)
		k.finial(at(c.x + L * 0.5, H + 2.6, c.z), 0.4)
	_emit(k, "Ombrelac_serres", 900.0)
	lieux["serres"] = Vector3(46.0, 0, 36.0)

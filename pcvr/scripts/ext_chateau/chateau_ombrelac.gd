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
const SALLES_PORTES := [-19.6, 0.0, 22.4]
const SALLES_BOUT := 4.0          # les tours d'angle mordent de 3,5 m dans l'aile
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
	# le sol du plateau : de grandes dalles dans toute l'enceinte
	var ctr := Vector3(0, 0.04, 0)
	for i in range(pts.size()):
		var a: Vector3 = pts[i] * 0.97 + Vector3(0, 0.04, 0)
		var b: Vector3 = pts[(i + 1) % pts.size()] * 0.97 + Vector3(0, 0.04, 0)
		k.tri("dalles", Transform3D.IDENTITY, ctr, a, b, Vector3.UP)
	_emit(k, "Ombrelac_enceinte")
	# l'esplanade (le sol du plateau près des murs : rien, le relief suffit)
	lieux["enceinte"] = Vector3.ZERO


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
	var p := Vector3(-44.0, 0, -26.0)
	var hs: float = 9.5          # demi-côté de la tour carrée
	var h1: float = 54.0         # le haut de la partie carrée
	k.box("socle", at(p.x, -10.0, p.z), Vector3(hs * 2.0 + 2.0, 11.4, hs * 2.0 + 2.0), true)
	k.box("pierre", at(p.x, 1.4, p.z), Vector3(hs * 2.0, h1 - 1.4, hs * 2.0), true)
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
	# la partie octogonale
	var r2: float = 7.2
	var h2: float = 30.0
	k.prism("pierre", at(p.x, h1, p.z), Kit.ngon(r2, 8, PI / 8.0), 0.0, h2)
	for i in range(8):
		var a: float = TAU * i / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var face: Vector3 = p + d * (r2 * cos(PI / 8.0))
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), face + Vector3(0, h1 + 4.0, 0)), 1.6, 7.0, "vitre")
		k.window(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), face + Vector3(0, h1 + 15.0, 0)), 1.6, 7.5, "vitre")
		# les pinacles aux angles de l'octogone
		var corner: Vector3 = p + Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * r2
		k.cyl("pierre_claire", at(corner.x, h1 + h2, corner.z), 0.7, 0.0, 4.5, 4, false)
	k.crown(at(p.x, h1, p.z), r2, h2, 16)
	# la flèche
	k.prism("pierre", at(p.x, h1 + h2, p.z), Kit.ngon(r2 * 0.8, 8, PI / 8.0), 0.0, 3.0)
	k.spire(at(p.x, h1 + h2 + 3.0, p.z), r2 * 0.85, 44.0)
	_emit(k, "Ombrelac_astrolabe")
	lieux["astrolabe"] = p + Vector3(0, 0, hs + 2.0)


# =================================================================== la Tour de l'Horloge

func _horloge() -> void:
	var k := Kit.new()
	var p := Vector3(36.0, 0, 34.0)
	var hs: float = 6.0
	var h: float = 40.0
	k.box("socle", at(p.x, -4.0, p.z), Vector3(hs * 2.0 + 1.2, 5.2, hs * 2.0 + 1.2), true)
	k.box("pierre", at(p.x, 1.2, p.z), Vector3(hs * 2.0, h - 1.2, hs * 2.0), true)
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var face: Vector3 = p + out * hs
		for et in range(3):
			k.window(Transform3D(Basis(Vector3.UP, yaw), face + Vector3(0, 6.0 + et * 8.0, 0)), 1.4, 4.0)
			k.cordon(Transform3D.IDENTITY, face - right * hs + Vector3(0, 4.6 + et * 8.0, 0), face + right * hs + Vector3(0, 4.6 + et * 8.0, 0), out, 0.25)
		# le cadran : un disque d'or, les heures en fer, les aiguilles
		var cx: Transform3D = Transform3D(Basis(Vector3.UP, yaw), face + Vector3(0, h - 5.0, 0))
		k.cyl("pierre_claire", cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 4.2, 4.2, 0.35, 32)
		k.cyl("or", cx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 3.6, 3.6, 0.42, 32)
		for hr in range(12):
			var a: float = TAU * hr / 12.0
			k.box("fer", cx * Transform3D(Basis(Vector3(0, 0, 1), -a), Vector3(sin(a) * 3.0, cos(a) * 3.0 - 0.35, 0.45)), Vector3(0.22, 0.7, 0.05))
		k.box("fer", cx * Transform3D(Basis(Vector3(0, 0, 1), -0.9), Vector3(0, 0, 0.5)), Vector3(0.25, 2.0, 0.05))
		k.box("fer", cx * Transform3D(Basis(Vector3(0, 0, 1), 2.3), Vector3(0, 0, 0.52)), Vector3(0.18, 3.0, 0.05))
		# les échauguettes d'angle
		var q: Vector3 = p + out * hs + right * hs
		k.cyl("pierre", at(q.x, h - 4.0, q.z), 0.3, 1.5, 2.0, 12, false)
		k.cyl("pierre", at(q.x, h - 2.0, q.z), 1.5, 1.5, 4.0, 12, false)
		k.cone_roof(at(q.x, h + 2.0, q.z), 1.5, 5.0, 12)
	k.cyl("pierre_claire", at(p.x, h - 0.3, p.z), hs * 1.45, hs * 1.45, 0.5, 4, false)
	k.hip_roof(Transform3D(Basis(Vector3.UP, 0.0), Vector3(p.x, h, p.z)), hs, hs, 10.0, false)
	# le lanternon de la cloche
	k.box("pierre_claire", at(p.x, h + 8.0, p.z), Vector3(3.0, 4.0, 3.0))
	k.hip_roof(at(p.x, h + 12.0, p.z), 1.5, 1.5, 4.5)
	_emit(k, "Ombrelac_horloge")
	lieux["horloge"] = p + Vector3(0, 0, hs + 2.0)


# =================================================================== les ailes

## Une aile : un long bâtiment à deux pans ; c au milieu, à terre ; yaw : faîtage selon x tourné
## (rez > 0 : le rez-de-chaussée est laissé vide, jusqu'à la hauteur rez ; on y bâtit des salles)
func _aile(k: RefCounted, c: Vector3, yaw: float, L: float, W: float, H: float, et: int, rez: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	if rez > 0.0:
		k.box("socle", Transform3D(b, c + Vector3(0, -4.0, 0)), Vector3(L + 1.2, 3.95, W + 1.2), true)
		k.box("pierre", Transform3D(b, c + Vector3(0, rez, 0)), Vector3(L, H - rez, W), true)
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
	_aile(k, c, 0.0, L, W, 18.0, 3, rz)
	var xf := Transform3D(Basis.IDENTITY, c)
	var n: int = 10
	var bay: float = L / n
	for s in [-1.0, 1.0]:
		var trous: Array = []
		var portes: Array = SALLES_PORTES if s > 0 else []
		for i in range(n):
			var x: float = -L * 0.5 + (i + 0.5) * bay
			var gene: bool = false
			for px in portes:
				if absf(px - x) < 2.2:
					gene = true
			if gene:
				continue
			trous.append(Kit.trou_ogive(x * s, 1.1, 1.6, 3.4))
			k.window(xf * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(x, 1.1, s * W * 0.5)), 1.6, 3.4)
		for px2 in portes:
			trous.append(Kit.trou_ogive(px2, 0.0, 2.4, 4.4))
			_portail(k, xf * Transform3D(Basis.IDENTITY, Vector3(px2, 0, W * 0.5)), 2.4, 4.4)
		trous.sort_custom(func(u, v): return u["xl"] < v["xl"])
		k.mur(xf * Transform3D(Basis(Vector3.UP, 0.0 if s > 0 else PI), Vector3(0, 0, s * W * 0.5)), L, rz, T, trous)
	for e in [-1.0, 1.0]:
		k.mur(xf * Transform3D(Basis(Vector3.UP, e * PI * 0.5), Vector3(e * L * 0.5, 0, 0)), W - 2.0 * T, rz, T, [])
	# les murs de refend entre les salles
	for xr in SALLES_REFENDS:
		k.box("pierre_int", xf * at(xr, 0.0, 0.0), Vector3(0.6, rz, W - 2.0 * T), true)
	_tour_ronde(k, -17.5, -46.0, 5.6, 38.0, 16.0, 5)
	_tour_ronde(k, 41.5, -46.0, 5.6, 44.0, 17.0, 5)
	# la Grosse Tour du nord-est : massive, crénelée, un haut toit
	_tour_ronde(k, 62.0, -40.0, 8.5, 48.0, 22.0, 6, true, -12.0)
	_emit(k, "Ombrelac_aile_nord")
	lieux["dortoirs"] = c + Vector3(0, 0, 8.5)
	var sl = Salles.new()
	sl.name = "Ombrelac_salles"
	add_child(sl)
	sl.construire_salles(xf, L, W, rz, T, SALLES_REFENDS, SALLES_PORTES, SALLES_BOUT)
	for key in sl.lieux:
		lieux[key] = sl.lieux[key]


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
	_tour_ronde(k, -52.0, 34.0, 6.5, 68.0, 26.0, 7, true, -14.0)
	# une galerie qui la relie à la Grande Salle
	k.box("pierre", at(-40.0, 0.0, 22.0), Vector3(16.0, 10.0, 6.0), true)
	k.gable_roof(at(-40.0, 10.0, 22.0), 16.0, 6.0, 4.0, false)
	_baies(k, Vector3(-48.0, 3.5, 25.0), Vector3(-32.0, 3.5, 25.0), Vector3(0, 0, 1), 3, 1.4, 4.0)
	_emit(k, "Ombrelac_sortileges")
	lieux["sortileges"] = Vector3(-52.0, 0, 42.0)


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

extends "res://scripts/ext_chateau/interieurs_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : la Bibliothèque de l'Académie (l'Aile des Études). Une seule
## grande salle sur toute la hauteur de l'aile :
##  - en bas, des épis de rayonnages perpendiculaires aux murs, une table de lecture et sa lampe à
##    abat-jour vert dans chaque alcôve, sous la baie ; une longue table dans l'allée ;
##  - une galerie de chêne tout autour, à 5,6 m, sa balustrade, ses rayonnages contre les murs ;
##  - le grand escalier droit qui y monte, au sud ; une échelle de bibliothèque ;
##  - au nord, la sphère armillaire de l'Académie sur son pied ;
##  - des lanternes pendues sous le lambris peint ; une sonde de reflets.
## Les livres : un shader (ombrelac_livres) sur un quad par rayon, pas de géométrie par livre.
## Repère : xf (celui de l'aile) : x le long de l'aile, z en travers (z < 0 : la cour, la porte),
## y = le plateau.

const GALERIE := 5.6          # le plancher de la galerie
const GAL_L := 1.7            # sa largeur
const EPI := 3.2              # la profondeur d'un épi de rayonnages
const EPI_H := 4.6            # sa hauteur

var xf: Transform3D
var _graine: int = 0


func _tr(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return xf * Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))


func _p(x: float, y: float, z: float) -> Vector3:
	return xf * Vector3(x, y, z)


## Une poutre en repère de l'aile
func _pl(k: RefCounted, m: String, a: Vector3, b: Vector3, s: float, large := Vector3.RIGHT) -> void:
	_poutre(k, m, xf * a, xf * b, s, xf.basis * large)


## Un meuble de rayonnages : tr au milieu du pied, x le long, z+ la face (et z- si « double »)
func _rayonnage(k: RefCounted, tr: Transform3D, lg: float, h: float, prof: float, double: bool) -> void:
	var m := "bois"
	k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)), Vector3(lg, 0.2, prof - 0.05), true)
	k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(0, h - 0.04, 0)), Vector3(lg + 0.16, 0.18, prof + 0.12))
	k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(0, h + 0.14, 0)), Vector3(lg + 0.06, 0.06, prof + 0.04))
	for e in [-1.0, 1.0]:
		k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(e * (lg * 0.5 - 0.03), 0, 0)), Vector3(0.07, h, prof))
	# le fond (ou la cloison du milieu)
	k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0 if double else -prof * 0.5 + 0.02)), Vector3(lg - 0.1, h - 0.24, 0.03))
	var n: int = int((h - 0.4) / 0.37)
	var pas: float = (h - 0.24) / n
	_graine += 1
	for i in range(n):
		var y0: float = 0.2 + i * pas
		var y1: float = y0 + pas - 0.03
		if i > 0:
			k.box(m, tr * Transform3D(Basis.IDENTITY, Vector3(0, y0 - 0.03, 0)), Vector3(lg - 0.1, 0.03, prof - 0.02))
		for s in ([-1.0, 1.0] if double else [1.0]):
			var z: float = s * (prof * 0.5 - 0.05)
			var a := Vector3(-lg * 0.5 + 0.06, y0, z)
			var b := Vector3(lg * 0.5 - 0.06, y0, z)
			var w: float = lg - 0.12
			if s > 0:
				k.quad("livres", tr, a, b, b + Vector3(0, y1 - y0, 0), a + Vector3(0, y1 - y0, 0), Vector3(0, 0, 1),
					Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1), Vector2(_graine * 0.37, i + s))
			else:
				k.quad("livres", tr, b, a, a + Vector3(0, y1 - y0, 0), b + Vector3(0, y1 - y0, 0), Vector3(0, 0, -1),
					Vector2(0, 0), Vector2(w, 0), Vector2(w, 1), Vector2(0, 1), Vector2(_graine * 0.37 + 5.0, i + s))


## Une lampe de lecture : un pied de laiton, un abat-jour de verre vert
func _lampe(k: RefCounted, p: Vector3) -> void:
	k.cyl("or", Transform3D(xf.basis, p), 0.09, 0.08, 0.03, 10)
	k.cyl("or", Transform3D(xf.basis, p + Vector3(0, 0.03, 0)), 0.014, 0.014, 0.36, 6)
	k.cyl("lampe", Transform3D(xf.basis, p + Vector3(0, 0.3, 0)), 0.15, 0.06, 0.13, 12)
	k.cyl("cire", Transform3D(xf.basis, p + Vector3(0, 0.28, 0)), 0.03, 0.03, 0.04, 6)


## Une chaise (repère de l'aile), le dossier du côté de yaw
func _chaise(k: RefCounted, x: float, z: float, yaw: float) -> void:
	k.box("bois", _tr(x, 0.0, z, yaw), Vector3(0.46, 0.46, 0.46))
	k.box("bois", _tr(x, 0.0, z, yaw) * Transform3D(Basis.IDENTITY, Vector3(0, 0.46, -0.21)), Vector3(0.46, 0.55, 0.05))


## Une table (repère de l'aile), le long de x
func _table_l(k: RefCounted, x: float, z: float, lg: float, lar: float) -> void:
	k.box("bois", _tr(x, 0.74, z), Vector3(lg, 0.06, lar), true)
	for ex in [-1.0, 1.0]:
		for ez in [-1.0, 1.0]:
			k.box("bois", _tr(x + ex * (lg * 0.5 - 0.12), 0.0, z + ez * (lar * 0.5 - 0.1)), Vector3(0.09, 0.74, 0.09))
	k.box("bois", _tr(x, 0.6, z), Vector3(lg - 0.3, 0.12, lar - 0.25))


## Une petite sphère (pour le globe), lissée
func _sphere(k: RefCounted, m: String, c: Vector3, r: float) -> void:
	var nl: int = 8
	var nm: int = 14
	for i in range(nl):
		var t0: float = PI * i / nl - PI * 0.5
		var t1: float = PI * (i + 1) / nl - PI * 0.5
		for j in range(nm):
			var p0: float = TAU * j / nm
			var p1: float = TAU * (j + 1) / nm
			var d := [Vector3(cos(t0) * cos(p0), sin(t0), cos(t0) * sin(p0)), Vector3(cos(t0) * cos(p1), sin(t0), cos(t0) * sin(p1)),
				Vector3(cos(t1) * cos(p1), sin(t1), cos(t1) * sin(p1)), Vector3(cos(t1) * cos(p0), sin(t1), cos(t1) * sin(p0))]
			k.quad_smooth(m, Transform3D(Basis.IDENTITY, c), d[0] * r, d[1] * r, d[2] * r, d[3] * r, d[0], d[1], d[2], d[3])


## Un anneau de laiton (centre c, axe n, rayon r), en segments
func _anneau(k: RefCounted, c: Vector3, n: Vector3, r: float, s: float = 0.035) -> void:
	var u: Vector3 = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var v: Vector3 = n.cross(u).normalized()
	var seg: int = 24
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		_poutre(k, "or", c + (u * cos(a0) + v * sin(a0)) * r, c + (u * cos(a1) + v * sin(a1)) * r, s, n)


# =================================================================== la salle

func construire(the_xf: Transform3D, L: float, W: float, H: float, T: float, voute: float) -> void:
	xf = the_xf
	var k := Kit.new()
	var hl: float = L * 0.5 - T
	var hw: float = W * 0.5 - T
	var n: int = 8
	var bay: float = L / n
	# --- les épis de rayonnages (aux limites des travées) et les alcôves de lecture
	for j in range(1, n):
		var x: float = -L * 0.5 + j * bay
		for s in [-1.0, 1.0]:
			if s < 0 and absf(x) < 0.1:
				continue                # (l'entrée)
			var zc: float = s * (hw - EPI * 0.5)
			_rayonnage(k, _tr(x, 0.0, zc, PI * 0.5), EPI, EPI_H, 0.62, true)
	for i in range(1, n - 1):
		var x: float = -L * 0.5 + (i + 0.5) * bay
		for s in [-1.0, 1.0]:
			_table_l(k, x, s * (hw - 1.15), 2.6, 0.95)
			_chaise(k, x - 0.7, s * (hw - 2.05), 0.0 if s > 0 else PI)
			_chaise(k, x + 0.7, s * (hw - 2.05), 0.0 if s > 0 else PI)
			_lampe(k, _p(x, 0.77, s * (hw - 0.9)))
			# des livres posés, un livre ouvert
			k.box("banniere_pourpre", _tr(x + 0.6, 0.77, s * (hw - 1.1), 0.2), Vector3(0.24, 0.06, 0.32))
			k.box("banniere_bleu", _tr(x + 0.62, 0.83, s * (hw - 1.1), 0.5), Vector3(0.22, 0.05, 0.3))
			k.box("cire", _tr(x - 0.35, 0.77, s * (hw - 1.3), 0.1), Vector3(0.5, 0.02, 0.34))
	# --- la longue table de l'allée (de part et d'autre de l'entrée)
	for seg in [[-7.8, -1.6], [1.6, 12.5]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		_table_l(k, (x0 + x1) * 0.5, 0.0, x1 - x0, 1.0)
		var nc: int = int((x1 - x0) / 1.2)
		for i in range(nc):
			var cx: float = x0 + 0.6 + i * (x1 - x0 - 1.2) / maxf(nc - 1, 1)
			_chaise(k, cx, -0.95, PI)
			_chaise(k, cx, 0.95, 0.0)
		var nl: int = int((x1 - x0) / 2.6)
		for i in range(nl):
			_lampe(k, _p(x0 + (i + 0.5) * (x1 - x0) / nl, 0.77, 0.0))
	# --- les rayonnages des pignons (au nord du sol au plafond de la galerie, au sud sous la galerie)
	_rayonnage(k, _tr(hl - 0.33, 0.0, 0.0, -PI * 0.5), hw * 2.0 - 0.1, GALERIE - 0.35, 0.6, false)
	_rayonnage(k, _tr(-hl + 0.33, 0.0, 0.0, PI * 0.5), hw * 2.0 - 0.1, GALERIE - 0.35, 0.6, false)
	# --- la galerie : le plancher, la balustrade, les poteaux, les rayonnages contre les murs
	var gz: float = hw - GAL_L
	for s in [-1.0, 1.0]:
		k.box("chene", _tr(0.0, GALERIE - 0.25, s * (hw - GAL_L * 0.5)), Vector3(hl * 2.0, 0.25, GAL_L), true)
		_balustrade(k, Vector3(-hl + 2.2, GALERIE, s * gz), Vector3(hl, GALERIE, s * gz), Vector3(0, 0, -s))
		for j in range(0, n + 1):
			var x: float = clampf(-L * 0.5 + j * bay, -hl + 0.15, hl - 0.15)
			if s < 0 and absf(x) < 0.1:
				continue                # (l'entrée)
			_pl(k, "chene", Vector3(x, 0.0, s * (gz + 0.12)), Vector3(x, GALERIE - 0.25, s * (gz + 0.12)), 0.24)
			# la console sous le plancher
			_pl(k, "chene", Vector3(x, GALERIE - 1.4, s * (gz + 0.12)), Vector3(x, GALERIE - 0.25, s * (gz + 0.9)), 0.16)
		for i in range(n):
			var x2: float = -L * 0.5 + (i + 0.5) * bay
			for e in [-1.0, 1.0]:
				var xa: float = x2 + e * 1.25
				var xb: float = x2 + e * (bay * 0.5 - 0.05)
				if absf(xb) > hl:
					xb = signf(xb) * (hl - 0.02)
				var lg: float = absf(xb - xa)
				if lg < 0.8:
					continue
				_rayonnage(k, _tr((xa + xb) * 0.5, GALERIE, s * (hw - 0.25), 0.0 if s < 0 else PI), lg, 6.0, 0.45, false)
	# la galerie du sud (au-dessus des rayonnages du pignon), où arrive l'escalier
	var xs: float = -hl + 2.2
	k.box("chene", _tr((-hl + xs) * 0.5, GALERIE - 0.25, 0.0), Vector3(2.2, 0.25, gz * 2.0), true)
	for e2 in [-1.0, 1.0]:
		_balustrade(k, Vector3(xs, GALERIE, e2 * 1.2), Vector3(xs, GALERIE, e2 * gz), Vector3(1, 0, 0))
	# --- l'escalier : trente et une marches de chêne, ses limons, sa rampe
	var x_bas: float = -9.2
	var nm: int = 31
	var mont: float = GALERIE / nm
	var giron: float = (x_bas - xs) / nm
	for i in range(nm):
		var xm: float = x_bas - (i + 0.5) * giron
		k.box("chene", _tr(xm, mont * (i + 1) - 0.06, 0.0), Vector3(giron + 0.03, 0.06, 2.2))
		k.box("bois", _tr(xm + giron * 0.45, mont * i, 0.0), Vector3(0.03, mont, 2.1))
	for e3 in [-1.0, 1.0]:
		var z3: float = e3 * 1.15
		_pl(k, "bois", Vector3(x_bas + 0.1, -0.1, z3), Vector3(xs, GALERIE - 0.15, z3), 0.14, Vector3(0, 0, 1))
		_pl(k, "or", Vector3(x_bas, 1.0, z3), Vector3(xs, GALERIE + 1.0, z3), 0.06, Vector3(0, 0, 1))
		for i in range(0, nm, 2):
			var xb2: float = x_bas - (i + 0.5) * giron
			_pl(k, "fer", Vector3(xb2, mont * (i + 1), z3), Vector3(xb2, mont * (i + 1) + 1.0 - 0.0, z3), 0.03)
		k.cyl("or", _tr(x_bas, 0.0, z3), 0.08, 0.06, 1.15, 8)
	# la collision de l'escalier : une rampe sous le nez des marches
	var a_b := Vector3(x_bas, 0.0, 0.0)
	var a_h := Vector3(xs, GALERIE, 0.0)
	var dirv: Vector3 = (a_h - a_b).normalized()
	var nrm: Vector3 = dirv.cross(Vector3(0, 0, 1)).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	var col := BoxShape3D.new()
	col.size = Vector3((a_h - a_b).length() + 0.6, 0.3, 2.2)
	var ang: float = atan2(dirv.y, dirv.x)
	k.shapes.append([col, xf * Transform3D(Basis(Vector3(0, 0, 1), ang), (a_b + a_h) * 0.5 - nrm * 0.15)])
	# --- l'échelle roulante contre le pignon nord
	var lx: float = hl - 0.75
	for e4 in [-1.0, 1.0]:
		_pl(k, "chene", Vector3(lx - 0.6, 0.0, 1.6 + e4 * 0.25), Vector3(lx - 0.05, GALERIE - 0.6, 1.6 + e4 * 0.25), 0.06)
	for i in range(13):
		var u: float = (i + 0.5) / 13.0
		var pr := Vector3(lerpf(lx - 0.6, lx - 0.05, u), lerpf(0.0, GALERIE - 0.6, u), 1.6)
		_pl(k, "chene", pr - Vector3(0, 0, 0.25), pr + Vector3(0, 0, 0.25), 0.035, Vector3.UP)
	# --- la sphère armillaire, au nord de l'allée
	var g: Vector3 = _p(hl - 4.0, 0.0, 0.0)
	k.cyl("chene", Transform3D(xf.basis, g), 0.45, 0.35, 0.18, 12, true, true)
	k.cyl("chene", Transform3D(xf.basis, g + Vector3(0, 0.18, 0)), 0.12, 0.09, 1.1, 10)
	k.cyl("or", Transform3D(xf.basis, g + Vector3(0, 1.28, 0)), 0.2, 0.06, 0.12, 10)
	var gc: Vector3 = g + Vector3(0, 2.15, 0)
	var axe: Vector3 = (Vector3.UP * cos(0.41) + xf.basis * Vector3(1, 0, 0) * sin(0.41)).normalized()
	_anneau(k, gc, Vector3.UP, 0.92, 0.05)
	_anneau(k, gc, xf.basis * Vector3(0, 0, 1), 0.92, 0.05)
	_anneau(k, gc, axe, 0.85)
	_anneau(k, gc, (axe.cross(Vector3.UP)).normalized(), 0.8)
	_anneau(k, gc, (axe + xf.basis * Vector3(0, 0, 1) * 0.8).normalized(), 0.82, 0.03)
	_poutre(k, "or", gc - axe * 1.1, gc + axe * 1.1, 0.03)
	_sphere(k, "lambris", gc, 0.26)
	_poutre(k, "or", g + Vector3(0, 1.3, 0), gc - Vector3(0, 0.92, 0), 0.05)
	# --- les lanternes, pendues sous le lambris
	for x5 in [-14.0, -4.0, 6.0, 15.5]:
		var lp: Vector3 = _p(x5, 9.6, 0.0)
		_lanterne(k, lp)
		_poutre(k, "fer", lp + Vector3(0, 0.75, 0), _p(x5, 16.0 + voute - 0.4, 0.0), 0.04)
		_lumiere(lp + Vector3(0, 0.2, 0), 15.0, 0.9, 2.0)
	_lumiere(_p(-4.0, 1.6, 0.0), 8.0, 0.35, 0.9)
	_lumiere(_p(7.0, 1.6, 0.0), 8.0, 0.35, 0.9)
	var mi: MeshInstance3D = k.commit("Ombrelac_biblio_meubles")
	mi.visibility_range_end = 140.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_biblio_meubles_col"))
	sonde = ReflectionProbe.new()
	sonde.name = "Ombrelac_biblio_sonde"
	sonde.position = _p(0.0, (H + voute) * 0.5 - 1.0, 0.0)
	sonde.rotation = xf.basis.get_euler()
	sonde.size = Vector3(hl * 2.0, H + voute + 3.0, hw * 2.0)
	sonde.interior = true
	sonde.box_projection = true
	sonde.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	sonde.ambient_color = AMBIANT_JOUR
	sonde.update_mode = ReflectionProbe.UPDATE_ONCE
	sonde.max_distance = 60.0
	sonde.blend_distance = 0.5
	add_child(sonde)
	lieux["galerie"] = _p(6.0, GALERIE, hw - 0.8)
	lieux["escalier_bas"] = _p(x_bas + 1.2, 0.0, 0.0)
	lieux["allee"] = _p(4.0, 0.0, -1.6)


## Une balustrade de a à b (repère de l'aile) : la main courante, les balustres, la lisse ; sa
## collision (on ne tombe pas de la galerie)
func _balustrade(k: RefCounted, a: Vector3, b: Vector3, dehors: Vector3) -> void:
	var lg: float = a.distance_to(b)
	var d: Vector3 = (b - a) / lg
	_pl(k, "chene", a + Vector3(0, 0.98, 0), b + Vector3(0, 0.98, 0), 0.1, Vector3.UP)
	_pl(k, "chene", a + Vector3(0, 0.08, 0), b + Vector3(0, 0.08, 0), 0.08, Vector3.UP)
	var nb: int = int(lg / 0.22)
	for i in range(nb + 1):
		var p: Vector3 = a + d * (lg * i / nb)
		_pl(k, "chene", p + Vector3(0, 0.12, 0), p + Vector3(0, 0.93, 0), 0.05)
	# la planche de rive (le bord du plancher, côté salle)
	_pl(k, "chene", a + dehors * 0.04 - Vector3(0, 0.3, 0), b + dehors * 0.04 - Vector3(0, 0.3, 0), 0.28, Vector3.UP)
	var s := BoxShape3D.new()
	s.size = Vector3(lg, 1.1, 0.12)
	var yaw: float = atan2(-d.z, d.x)
	k.shapes.append([s, xf * Transform3D(Basis(Vector3.UP, yaw), (a + b) * 0.5 + Vector3(0, 0.55, 0))])


## Une lanterne de fer à verres ambrés (c : le milieu)
func _lanterne(k: RefCounted, c: Vector3) -> void:
	var r: float = 0.32
	for i in range(6):
		var a0: float = TAU * i / 6.0
		var a1: float = TAU * (i + 1) / 6.0
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		k.quad("lanterne", Transform3D(Basis.IDENTITY, c), p0 - Vector3(0, 0.4, 0), p1 - Vector3(0, 0.4, 0), p1 + Vector3(0, 0.4, 0), p0 + Vector3(0, 0.4, 0), (p0 + p1) * 0.5)
		_poutre(k, "fer", c + p0 - Vector3(0, 0.45, 0), c + p0 + Vector3(0, 0.45, 0), 0.035)
	k.cyl("fer", Transform3D(Basis.IDENTITY, c + Vector3(0, 0.42, 0)), r + 0.06, 0.05, 0.32, 6)
	k.cyl("fer", Transform3D(Basis.IDENTITY, c - Vector3(0, 0.5, 0)), 0.05, r + 0.04, 0.1, 6)
	k.cyl("fer", Transform3D(Basis.IDENTITY, c - Vector3(0, 0.62, 0)), 0.0, 0.07, 0.12, 6)

extends "res://scripts/hautefond_kit_v112.gd"
## V113 : la boîte à outils de la Cité des Nuées (futuriste, réaliste et lumineuse). Tout ce que savent
## faire les kits d'avant, et ce qui fait la Cité des Nuées :
##  - tower113() : un immeuble de verre et de béton blanc (rez-de-chaussée en retrait, nez de dalle
##    blancs, mur-rideau, ailettes pare-soleil, balcons à garde-corps de verre et jardinières, toit
##    avec panneaux solaires, jardin et acrotère) ; round113() : une tour ronde ; terraces113() : un
##    immeuble en gradins couverts de jardins ;
##  - glass_rail113() : un garde-corps de verre (montants d'inox, main courante, collision) ;
##  - lamp113(), bench113(), planter113(), canopy113() (une toile tendue sur mâts fins),
##    dome113() (une serre en coupole de verre et sa résille blanche), turbine113() (une éolienne
##    verticale qui tourne), solar113() (une rangée de panneaux solaires), sign113() (une enseigne).
## Repères : une façade « xf » regarde +Z local (comme les autres kits).

const Mats113 = preload("res://scripts/nuees_mats_v113.gd")
const FH: float = 3.6                    # la hauteur d'un étage
const FAC_W: float = 6.0                 # la texture du mur-rideau couvre 6 m de large…
const FAC_H: float = 7.2                 # … et deux étages de haut

var tree_spots: Array = []               # Vector3 : des arbres à planter (les toits, les jardinières)
var spinners: Array = []                 # Node3D : les rotors des éoliennes (on les fait tourner)
var light_spots: Array = []              # [Vector3, Color] : des lampes qui méritent une vraie lumière


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats113.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


# =================================================================== le mur-rideau

## Un pan de mur-rideau (a : en bas à gauche vu de dehors, b : en bas à droite, h : la hauteur, out : la
## normale) ; v = 0 en haut (le nez de dalle de la texture tombe sur les planchers).
func facade_panel(a: Vector3, b: Vector3, h: float, out: Vector3, u0: float = 0.0) -> void:
	var w: float = a.distance_to(b)
	var uw: float = w / FAC_W
	var vh: float = h / FAC_H
	quad4("facade113", a, b, b + Vector3.UP * h, a + Vector3.UP * h, out, Vector2(u0, vh), Vector2(u0 + uw, vh), Vector2(u0 + uw, 0), Vector2(u0, 0))


## Une boîte de mur-rideau (les quatre côtés) : xf posé au milieu du bas.
func facade_box(xf: Transform3D, w: float, d: float, h: float) -> void:
	var hw: float = w * 0.5
	var hd: float = d * 0.5
	var b: Basis = xf.basis
	var c: Array = [xf * Vector3(-hw, 0, hd), xf * Vector3(hw, 0, hd), xf * Vector3(hw, 0, -hd), xf * Vector3(-hw, 0, -hd)]
	var outs: Array = [b * Vector3.BACK, b * Vector3.RIGHT, b * Vector3.FORWARD, b * Vector3.LEFT]
	for k in range(4):
		facade_panel(c[k], c[(k + 1) % 4], h, (outs[k] as Vector3).normalized(), float(k) * 0.37)


# =================================================================== les immeubles

## Un immeuble de verre et de béton blanc. xf : le milieu du pied de la façade avant (qui regarde +Z).
## opts : gf (hauteur du rez-de-chaussée), balcons (faces : "av", "ar", "g", "d"), ailettes (bool),
## toit ("solaire" | "jardin" | "mixte"), boutique (id d'enseigne), retrait (du rez-de-chaussée).
## Renvoie la porte (dehors, devant la façade avant).
func tower113(xf: Transform3D, w: float, d: float, floors: int, opts: Dictionary = {}) -> Vector3:
	var gf: float = float(opts.get("gf", 4.2))
	var inset: float = float(opts.get("retrait", 0.8))
	var top: float = gf + floors * FH
	var c: Transform3D = xf * T(0, 0, -d * 0.5)
	# le rez-de-chaussée : vitré, en retrait, sous les poteaux blancs
	facade_box(c, w - inset * 2.0, d - inset * 2.0, gf)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(c * T(sx * (w * 0.5 - 0.35), gf * 0.5, sz * (d * 0.5 - 0.35)), Vector3(0.5, gf, 0.5), "beton113", 2.4)
	var n_post: int = int(w / 6.0)
	for i in range(1, n_post):
		var px: float = -w * 0.5 + w * float(i) / n_post
		box(c * T(px, gf * 0.5, d * 0.5 - 0.35), Vector3(0.36, gf, 0.36), "beton113", 2.4)
	# les étages : le mur-rideau, les nez de dalle
	facade_box(c * T(0, gf, 0), w - 0.3, d - 0.3, floors * FH)
	for f in range(floors + 1):
		var y: float = gf + f * FH
		var over: float = 0.5 if f < floors else 0.7
		box(c * T(0, y - 0.18, 0), Vector3(w + over, 0.36, d + over), "beton113", 2.4)
	# les ailettes pare-soleil (verticales, blanches) sur l'avant et l'arrière
	if bool(opts.get("ailettes", false)):
		var nf: int = int(w / 1.5)
		for i2 in range(nf + 1):
			var fx: float = -w * 0.5 + 0.15 + (w - 0.3) * float(i2) / nf
			for sz2 in [-1.0, 1.0]:
				box(c * T(fx, gf + floors * FH * 0.5, sz2 * (d * 0.5 + 0.12)), Vector3(0.1, floors * FH - 0.4, 0.5), "beton113", 2.4, 63 - 4 - 8)
	# les balcons : une dalle en avancée, un garde-corps de verre, une jardinière
	for face in opts.get("balcons", []):
		var fx2: Transform3D
		var fw: float
		match str(face):
			"av":
				fx2 = c * T(0, 0, d * 0.5)
				fw = w
			"ar":
				fx2 = c * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d * 0.5))
				fw = w
			"g":
				fx2 = c * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-w * 0.5, 0, 0))
				fw = d
			_:
				fx2 = c * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(w * 0.5, 0, 0))
				fw = d
		for f2 in range(1, floors + 1):
			if (f2 + int(fw)) % 2 == 1 and not bool(opts.get("tous_balcons", false)):
				continue
			var y2: float = gf + (f2 - 1) * FH
			box(fx2 * T(0, y2 - 0.12, 0.8), Vector3(fw - 1.0, 0.24, 1.6), "beton113", 2.4)
			box(fx2 * T(0, y2 + 0.5, 1.48), Vector3(fw - 1.0, 0.03, 0.03), "acier113", 1.0)
			quad(fx2 * T(0, y2 + 0.5, 1.5), fw - 1.0, 0.98, "verre113", Vector2(0, 0), Vector2(1, 1), true)
			box(fx2 * T(0, y2 + 1.0, 1.5), Vector3(fw - 1.0, 0.05, 0.08), "acier113", 1.0)
			# la jardinière (des haies taillées et des fleurs) le long du garde-corps
			box(fx2 * T(0, y2 + 0.22, 1.25), Vector3(fw - 1.2, 0.44, 0.4), "beton113", 2.4)
			box(fx2 * T(0, y2 + 0.5, 1.25), Vector3(fw - 1.3, 0.3, 0.34), "haie113", 1.0, 63 - 8)
	# le toit : l'acrotère, des panneaux solaires ou un jardin
	var roof: String = str(opts.get("toit", "mixte"))
	var rt: Transform3D = c * T(0, top, 0)
	for e in [[0.0, d * 0.5, w, 0.25], [0.0, -d * 0.5, w, 0.25], [w * 0.5, 0.0, 0.25, d], [-w * 0.5, 0.0, 0.25, d]]:
		box(rt * T(float(e[0]), 0.4, float(e[1])), Vector3(float(e[2]) + 0.25, 0.8, float(e[3]) + 0.25), "beton113", 2.4)
	box(rt * T(0, 0.75, d * 0.5), Vector3(w - 0.4, 0.04, 0.04), "acier113", 1.0, 63 - 8)
	if roof == "solaire" or roof == "mixte":
		var sw: float = w - 2.0 if roof == "solaire" else (w - 2.0) * 0.5
		var x0: float = -w * 0.5 + 1.0 + sw * 0.5
		var rows: int = maxi(int((d - 2.0) / 2.4), 1)
		for r in range(rows):
			solar113(rt * T(x0, 0.1, -d * 0.5 + 1.6 + r * 2.4), sw, 1.6)
	if roof == "jardin" or roof == "mixte":
		var gw: float = w - 2.0 if roof == "jardin" else (w - 2.0) * 0.5
		var gx: float = w * 0.5 - 1.0 - gw * 0.5
		box(rt * T(gx, 0.2, 0), Vector3(gw, 0.4, d - 2.0), "gazon113", 3.0, 4)
		box(rt * T(gx, 0.2, 0), Vector3(gw, 0.4, d - 2.0), "beton113", 2.4, 63 - 4 - 8)
		var ntree: int = maxi(int(gw * (d - 2.0) / 60.0), 1)
		for k in range(ntree):
			tree_spots.append(rt * Vector3(gx + rng.randf_range(-gw * 0.3, gw * 0.3), 0.4, rng.randf_range(-(d - 2.0) * 0.3, (d - 2.0) * 0.3)))
	# un local technique blanc, une antenne fine
	box(rt * T(-w * 0.25, 1.4, -d * 0.25), Vector3(3.0, 2.8, 2.4), "beton113", 2.4)
	# la boutique : l'enseigne au-dessus de la porte
	if opts.has("boutique"):
		sign113(xf * T(0, gf - 0.9, 0.05), str(opts["boutique"]), 4.2, 2.1)
	col_box(c * T(0, top * 0.5, 0), Vector3(w, top, d))
	# la porte : deux vantaux vitrés, un auvent de verre
	box(xf * T(0, gf - 0.5, 0.9), Vector3(4.0, 0.12, 1.8), "acier113", 1.0)
	quad(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, gf - 0.43, 0.9)), 3.9, 1.7, "verre113_fume", Vector2(0, 0), Vector2(1, 1), true)
	return xf * Vector3(0, 0, 1.4)


## Une tour ronde (c : le centre au sol) : des anneaux de dalle, le mur-rideau, une couronne.
func round113(c: Vector3, r: float, floors: int, gf: float = 4.5, twist: float = 0.0) -> void:
	var seg: int = 28
	var top: float = gf + floors * FH
	# le rez-de-chaussée : vitré, en retrait
	_round_wall(c, r - 1.0, 0.0, gf, seg, 0.0)
	for k in range(8):
		var a: float = TAU * k / 8.0
		cyl(Transform3D(Basis(), c + Vector3(cos(a), 0, sin(a)) * (r - 0.4)), 0.3, 0.3, gf, "beton113", 10, false, 2.4)
	for f in range(floors):
		var y: float = gf + f * FH
		var a0: float = twist * float(f)
		_round_wall(c, r - 0.2, y, FH, seg, a0)
		var rr: float = r + 0.35 + 0.6 * (0.5 + 0.5 * sin(float(f) * 0.9))
		cyl(Transform3D(Basis(Vector3.UP, a0), c + Vector3.UP * (y - 0.2)), rr, rr, 0.36, "beton113", seg, true, 2.4)
		# un balcon qui tourne autour, d'étage en étage (la torsade)
		var ab: float = a0 * 3.0 + float(f) * 0.42
		var bp: Vector3 = c + Vector3(cos(ab), 0, sin(ab)) * (r + 1.2) + Vector3.UP * (y - 0.1)
		box(Transform3D(Basis(Vector3.UP, -ab + PI * 0.5), bp), Vector3(4.0, 0.24, 2.0), "beton113", 2.4)
		box(Transform3D(Basis(Vector3.UP, -ab + PI * 0.5), bp + Vector3.UP * 0.45 + Vector3(cos(ab), 0, sin(ab)) * 0.4), Vector3(3.6, 0.5, 0.9), "haie113", 1.0, 63 - 8)
	cyl(Transform3D(Basis(), c + Vector3.UP * (top - 0.2)), r + 0.6, r + 0.6, 0.4, "beton113", seg, true, 2.4)
	cyl(Transform3D(Basis(), c + Vector3.UP * top), r - 1.5, r - 3.0, 4.0, "verre113", seg, false)
	cyl(Transform3D(Basis(), c + Vector3.UP * top), r - 1.5, r - 1.5, 0.3, "acier113", seg, false)
	col_cyl(c, r, top)


func _round_wall(c: Vector3, r: float, y: float, h: float, seg: int, a0: float) -> void:
	for i in range(seg):
		var t0: float = a0 + TAU * i / seg
		var t1: float = a0 + TAU * (i + 1) / seg
		var p0: Vector3 = c + Vector3(cos(t0), 0, sin(t0)) * r + Vector3.UP * y
		var p1: Vector3 = c + Vector3(cos(t1), 0, sin(t1)) * r + Vector3.UP * y
		var tm: float = (t0 + t1) * 0.5
		facade_panel(p1, p0, h, Vector3(cos(tm), 0, sin(tm)), float(i) * p0.distance_to(p1) / FAC_W)


## Un immeuble en gradins (xf : le milieu du pied de la façade avant, qui regarde +Z) : chaque niveau
## recule de « step » ; chaque gradin porte un jardin (gazon, haie, arbres) bordé de verre.
func terraces113(xf: Transform3D, w: float, d: float, levels: int, step: float) -> Array:
	var doors: Array = []
	for lv in range(levels):
		var y: float = lv * FH
		var front: float = -lv * step
		var dd: float = d - lv * step
		var c: Transform3D = xf * T(0, y, front - dd * 0.5)
		facade_panel(xf * Vector3(-w * 0.5 + 0.2, y, front), xf * Vector3(w * 0.5 - 0.2, y, front), FH, xf.basis * Vector3.BACK, float(lv) * 0.31)
		for sx in [-1.0, 1.0]:
			box(c * T(sx * (w * 0.5 - 0.2), FH * 0.5, 0), Vector3(0.4, FH, dd), "beton113", 2.4, 63 - 4 - 8)
		box(c * T(0, FH * 0.5, -dd * 0.5 + 0.2), Vector3(w, FH, 0.4), "beton113", 2.4, 63 - 4 - 8)
		box(c * T(0, FH - 0.18, 0), Vector3(w + 0.4, 0.36, dd + 0.4), "beton113", 2.4)
		col_box(c * T(0, FH * 0.5, 0), Vector3(w, FH, dd))
		# le jardin du gradin (devant le niveau du dessus)
		if lv < levels - 1:
			var gz: float = front - step * 0.5
			var gp: Transform3D = xf * T(0, y + FH, gz)
			box(gp * T(0, 0.15, 0), Vector3(w - 1.2, 0.3, step - 1.0), "gazon113", 3.0, 4)
			box(gp * T(0, 0.35, step * 0.5 - 0.7), Vector3(w - 1.4, 0.6, 0.5), "haie113", 1.0, 63 - 8)
			glass_rail113(xf * Vector3(-w * 0.5 + 0.3, y + FH, front - 0.25), xf * Vector3(w * 0.5 - 0.3, y + FH, front - 0.25), 1.0, false)
			for k in range(int(w / 8.0)):
				tree_spots.append(gp * Vector3(-w * 0.5 + 4.0 + k * 8.0 + rng.randf_range(-1.0, 1.0), 0.3, rng.randf_range(-0.6, 0.2)))
		else:
			solar113(xf * T(0, y + FH + 0.1, front - dd * 0.5), w - 2.0, 1.6)
		if lv == 0:
			for k2 in range(maxi(int(w / 12.0), 1)):
				var dx: float = -w * 0.5 + 6.0 + k2 * 12.0
				doors.append(xf * Vector3(dx, 0, 0.9))
				box(xf * T(dx, 2.6, 0.7), Vector3(2.6, 0.1, 1.4), "acier113", 1.0)
	return doors


# =================================================================== les petits objets

## Un garde-corps de verre : des montants d'inox, le verre, la main courante (et sa collision).
func glass_rail113(a: Vector3, b: Vector3, h: float = 1.1, collide: bool = true) -> void:
	var d: Vector3 = b - a
	var len: float = Vector2(d.x, d.z).length()
	if len < 0.05:
		return
	var bs := Basis(Vector3.UP, atan2(d.x, d.z))
	var mid: Vector3 = (a + b) * 0.5
	box(Transform3D(bs, mid + Vector3.UP * h), Vector3(0.07, 0.06, len), "acier113", 1.0)
	quad(Transform3D(bs * Basis(Vector3.UP, PI * 0.5), mid + Vector3.UP * (h * 0.5 + 0.03)), len, h - 0.1, "verre113", Vector2(0, 0), Vector2(1, 1), true)
	var n: int = maxi(int(len / 1.6), 1)
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / n)
		box(Transform3D(bs, p + Vector3.UP * h * 0.5), Vector3(0.05, h, 0.05), "acier113", 1.0, 1 | 2 | 16 | 32)
	if collide:
		col_box(Transform3D(bs, mid + Vector3.UP * h * 0.5), Vector3(0.12, h, len))


## Un lampadaire fin (un mât blanc, une tête plate à diodes).
func lamp113(pos: Vector3, yaw: float = 0.0, h: float = 4.6, with_light: bool = false) -> void:
	var b := Basis(Vector3.UP, yaw)
	cyl(Transform3D(Basis(), pos), 0.1, 0.07, h, "composite113", 8, false)
	cyl(Transform3D(Basis(), pos), 0.18, 0.16, 0.3, "acier113", 8, true)
	box(Transform3D(b, pos + Vector3.UP * h + b * Vector3(0, 0, 0.45)), Vector3(0.24, 0.08, 1.1), "composite113", 1.0)
	box(Transform3D(b, pos + Vector3.UP * (h - 0.05) + b * Vector3(0, 0, 0.6)), Vector3(0.18, 0.02, 0.7), "led113", 1.0, 8)
	col_cyl(pos, 0.12, h)
	if with_light:
		light_spots.append([pos + Vector3.UP * (h - 0.3) + b * Vector3(0, 0, 0.6), Color(0.94, 0.97, 1.0)])


## Un banc : des lames de bois blond sur deux blocs de béton blanc.
func bench113(xf: Transform3D, w: float = 2.2) -> void:
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.3), 0.21, 0), Vector3(0.32, 0.42, 0.5), "beton113", 2.4)
	for k in range(4):
		box(xf * T(0, 0.45, -0.18 + k * 0.12), Vector3(w, 0.05, 0.1), "bois113", 1.0)
	col_box(xf * T(0, 0.25, 0), Vector3(w, 0.5, 0.5))


## Un bac de béton blanc, sa terre, une haie ou un arbre.
func planter113(xf: Transform3D, w: float, d: float, tree: bool = false, h: float = 0.6) -> void:
	box(xf * T(0, h * 0.5, 0), Vector3(w, h, d), "beton113", 2.4, 63 - 4 - 8)
	box(xf * T(0, h - 0.06, 0), Vector3(w - 0.2, 0.05, d - 0.2), "terre113", 1.0, 4)
	if tree:
		tree_spots.append(xf * Vector3(0, h - 0.05, 0))
	else:
		box(xf * T(0, h + 0.25, 0), Vector3(w - 0.3, 0.6, d - 0.3), "haie113", 1.0, 63 - 8)
	col_box(xf * T(0, h * 0.5, 0), Vector3(w, h, d))


## Une toile tendue (blanche, gauchie) sur quatre mâts fins : un abri léger (terrasses, quais).
func canopy113(xf: Transform3D, w: float, d: float, h: float, color: String = "toile113") -> void:
	var cs: Array = [Vector3(-w * 0.5, h + 0.6, -d * 0.5), Vector3(w * 0.5, h - 0.2, -d * 0.5), Vector3(w * 0.5, h + 0.6, d * 0.5), Vector3(-w * 0.5, h - 0.2, d * 0.5)]
	for p in cs:
		var q: Vector3 = xf * Vector3((p as Vector3).x, 0, (p as Vector3).z)
		cyl(Transform3D(Basis(), q), 0.08, 0.06, (p as Vector3).y, "acier113", 8, false)
		col_cyl(q, 0.1, (p as Vector3).y)
	var n: int = 6
	for i in range(n):
		for j in range(n):
			var u0: float = float(i) / n
			var u1: float = float(i + 1) / n
			var v0: float = float(j) / n
			var v1: float = float(j + 1) / n
			var pts: Array = []
			for uv in [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]:
				var top: Vector3 = (cs[0] as Vector3).lerp(cs[1], uv.x)
				var bot: Vector3 = (cs[3] as Vector3).lerp(cs[2], uv.x)
				var p2: Vector3 = top.lerp(bot, uv.y)
				p2.y -= 0.35 * sin(uv.x * PI) * sin(uv.y * PI)
				pts.append(xf * p2)
			quad4(color, pts[0], pts[1], pts[2], pts[3], xf.basis * Vector3.UP, Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
			quad4(color, pts[3], pts[2], pts[1], pts[0], xf.basis * Vector3.DOWN, Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0))


## Une serre en coupole : un socle de béton, la coupole de verre, sa résille blanche (méridiens et
## parallèles), une porte.
func dome113(c: Vector3, r: float, h: float, door_dir: Vector3) -> void:
	cyl(Transform3D(Basis(), c), r + 0.3, r + 0.3, 0.8, "beton113", 40, true, 2.4)
	dome76(Transform3D(Basis(), c + Vector3.UP * 0.8), r, h, "verre113", 40, 12)
	var mer: int = 20
	for k in range(mer):
		var a: float = TAU * k / mer
		var prev := Vector3.ZERO
		for i in range(13):
			var t: float = float(i) / 12.0 * PI * 0.5
			var p: Vector3 = c + Vector3.UP * 0.8 + Vector3(cos(a) * cos(t) * r, sin(t) * h, sin(a) * cos(t) * r)
			if i > 0:
				beam(prev, p, 0.09, "composite113")
			prev = p
	for j in range(1, 6):
		var t2: float = float(j) / 6.0 * PI * 0.5
		var rr: float = cos(t2) * r
		var y: float = 0.8 + sin(t2) * h
		var prev2 := Vector3.ZERO
		for k2 in range(41):
			var a2: float = TAU * k2 / 40.0
			var p2: Vector3 = c + Vector3(cos(a2) * rr, y, sin(a2) * rr)
			if k2 > 0:
				beam(prev2, p2, 0.07, "composite113")
			prev2 = p2
	# le sas d'entrée (un petit tunnel vitré)
	var dd: Vector3 = Vector3(door_dir.x, 0, door_dir.z).normalized()
	var bx := Basis.looking_at(-dd, Vector3.UP)
	var e: Vector3 = c + dd * (r + 1.0)
	box(Transform3D(bx, e + Vector3.UP * 1.4), Vector3(3.2, 2.8, 2.4), "verre113", 1.0, 4 | 1 | 2)
	box(Transform3D(bx, e + Vector3.UP * 2.85), Vector3(3.4, 0.14, 2.6), "composite113", 1.0)
	for s in [-1.0, 1.0]:
		box(Transform3D(bx, e + bx * Vector3(s * 1.6, 1.4, 0)), Vector3(0.1, 2.8, 2.4), "acier113", 1.0)


## Une éolienne verticale (un mât, trois pales hélicoïdales qui tournent).
func turbine113(pos: Vector3, h: float = 9.0) -> void:
	cyl(Transform3D(Basis(), pos), 0.35, 0.22, h, "composite113", 12, false)
	cyl(Transform3D(Basis(), pos), 0.6, 0.6, 0.5, "beton113", 12, true)
	col_cyl(pos, 0.4, h + 4.0)
	var rotor := MeshInstance3D.new()
	rotor.name = "Rotor"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rh: float = 4.6
	var rr: float = 1.3
	for b in range(3):
		var a0: float = TAU * b / 3.0
		var n: int = 16
		for i in range(n):
			var t0: float = float(i) / n
			var t1: float = float(i + 1) / n
			var ta: float = a0 + t0 * 2.2
			var tb: float = a0 + t1 * 2.2
			var p0 := Vector3(cos(ta) * rr, t0 * rh, sin(ta) * rr)
			var p1 := Vector3(cos(tb) * rr, t1 * rh, sin(tb) * rr)
			var off0 := Vector3(-sin(ta), 0, cos(ta)) * 0.32
			var off1 := Vector3(-sin(tb), 0, cos(tb)) * 0.32
			for v in [p0, p1, p1 + off1, p0, p1 + off1, p0 + off0, p0, p1 + off1, p1, p0, p0 + off0, p1 + off1]:
				st.add_vertex(v)
		# les bras qui tiennent la pale
		for yy in [0.1, rh - 0.1]:
			var ta2: float = a0 + yy / rh * 2.2
			var q := Vector3(cos(ta2) * rr, yy, sin(ta2) * rr)
			for v2 in [Vector3(0, yy - 0.05, 0), q + Vector3(0, -0.05, 0), q + Vector3(0, 0.05, 0), Vector3(0, yy - 0.05, 0), q + Vector3(0, 0.05, 0), Vector3(0, yy + 0.05, 0)]:
				st.add_vertex(v2)
	st.generate_normals()
	rotor.mesh = st.commit()
	rotor.material_override = mat("composite113")
	rotor.visibility_range_end = 600.0
	root.add_child(rotor)
	rotor.global_position = pos + Vector3.UP * h
	rotor.set_meta("vitesse", rng.randf_range(1.2, 1.8))
	spinners.append(rotor)


## Une rangée de panneaux solaires inclinés vers le sud (xf : le milieu, au sol ; w : la longueur).
func solar113(xf: Transform3D, w: float, depth: float) -> void:
	var tilt := Basis(Vector3.RIGHT, -0.4)
	var n: int = maxi(int(w / 1.1), 1)
	var pw: float = w / n
	for i in range(n):
		var x: float = -w * 0.5 + pw * (i + 0.5)
		var px: Transform3D = xf * Transform3D(tilt, Vector3(x, 0.6, 0))
		quad(px * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), pw - 0.06, depth, "solaire113")
		box(px * T(0, -0.04, 0), Vector3(pw - 0.04, 0.05, depth), "alu113", 1.0, 8 | 1 | 2 | 16 | 32)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.1), 0.35, 0), Vector3(0.06, 0.7, depth * 0.8), "alu113", 1.0)


## Une enseigne moderne (« enseigne113_<id> ») sur une plaque d'aluminium (xf : son centre, elle
## regarde +Z).
func sign113(xf: Transform3D, sign_id: String, w: float = 3.2, h: float = 1.6) -> void:
	box(xf * T(0, 0, -0.04), Vector3(w + 0.12, h + 0.12, 0.06), "alu113", 1.0)
	quadz(xf * T(0, 0, 0.0), w, h, "enseigne113_" + sign_id)


## Un totem d'orientation (un pilier blanc, une enseigne de chaque côté).
func totem113(pos: Vector3, yaw: float, sign_id: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	box(Transform3D(b, pos + Vector3.UP * 1.3), Vector3(1.8, 2.6, 0.3), "composite113", 1.0)
	sign113(Transform3D(b, pos + Vector3.UP * 1.7 + b * Vector3(0, 0, 0.17)), sign_id, 1.6, 0.8)
	sign113(Transform3D(b * Basis(Vector3.UP, PI), pos + Vector3.UP * 1.7 + b * Vector3(0, 0, -0.17)), sign_id, 1.6, 0.8)
	col_box(Transform3D(b, pos + Vector3.UP * 1.3), Vector3(1.8, 2.6, 0.3))

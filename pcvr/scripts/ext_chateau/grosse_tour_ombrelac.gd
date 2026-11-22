extends "res://scripts/ext_chateau/sortileges_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : le dedans de la Grosse Tour, la tour des maîtres :
##  - la Salle du Conseil, au pied : la grande table ronde de chêne (l'étoile d'or incrustée), les
##    hautes chaises des maîtres, le siège du Recteur, la couronne de fer et ses bougies, les
##    bannières de l'Académie, les lanternes de la porte ;
##  - l'escalier à vis, dans sa cage de pierre ronde contre le mur : deux fois trois tours, la main
##    courante de fer ; une porte à chaque étage ;
##  - le Bureau du Recteur (12 m) : le grand bureau et son fauteuil, la cheminée et son feu, les
##    bibliothèques, le globe, la galerie des portraits des anciens Recteurs (peints à l'huile) ;
##  - la Salle des Reliques (24 m) : la Couronne des Fondateurs qui tourne lentement dans sa colonne
##    de lumière, au-dessus du cercle de runes ; les vitrines et leurs reliques (l'épée, la coupe,
##    le cristal, le grimoire, la baguette, l'astrolabe de poche), les coffres ferrés, les écus.
## Repère : xf = le centre de la tour, au dallage de la salle du bas (y = le plateau).

const A_VIS := deg_to_rad(300.0)  # la cage de l'escalier, contre le mur (au nord-est, côté dehors)
const RV := 2.6                   # le dehors de la cage
const RV_T := 0.32                # l'épaisseur de son mur
const NOYAU := 0.3                # le noyau de la vis
const PALIER := deg_to_rad(30.0)  # la moitié d'un palier, de part et d'autre de la porte
const PAS_VIS := deg_to_rad(15.0)
const MARCHES_VIS := 68           # par volée (trois tours moins le palier)
const PANS_VIS := 28
const PORTE_VIS_H := 2.5

var base: Transform3D             # le repère de la tour, au dallage
var vis_c: Vector3                # le centre de la cage (repère tour)
var phi: float = 0.0              # l'angle des portes de la cage (vers le milieu de la tour)
var e1: float = 12.0
var e2: float = 24.0
var couronne: Node3D              # la Couronne des Fondateurs, qui tourne
var _y_couronne: float = 0.0


func construire_grosse_tour(p: Vector3, r: float, T: float, the_e1: float, the_e2: float, the_plafond: float, baies: Array) -> void:
	base = Transform3D(Basis.IDENTITY, p)
	xf = base
	xf_sol = base
	_puits = Vector3(1e6, 0, 1e6)
	_rng.seed = 4848
	ri = r - T
	e1 = the_e1
	e2 = the_e2
	plafond = the_plafond
	cab = e2
	vis_c = _dir(A_VIS) * (ri - RV)
	phi = A_VIS + PI
	var k := Kit.new()
	# --- les sols : le dallage du bas, les deux planchers (troués pour la cage), les solives
	_dallage(k, ri, 0.0, Vector3(1e6, 0, 1e6), 0.0, func(x: float, z: float) -> bool: return Vector2(x, z).length() < ri + 0.2)
	for y in [e1, e2]:
		_plancher(k, y)
	# --- l'escalier à vis et sa cage
	_cage_vis(k)
	_vis(k)
	# --- les fenêtres vues du dedans
	for b in baies:
		var d := _dir(deg_to_rad(float(b[0])))
		k.window(Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.z)), _p(0, float(b[1]), 0) + d * (ri + 0.02)), 1.1, 2.8, "vitre", 0.15)
	# --- les trois salles
	_conseil(k)
	_bureau(k)
	_reliques(k)
	xf = base
	var mi: MeshInstance3D = k.commit("Ombrelac_grosse_tour_meubles")
	mi.visibility_range_end = 150.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_grosse_tour_meubles_col"))
	for s in [[0.0, e1], [e1, e2], [e2, plafond]]:
		var y0: float = float(s[0])
		var y1: float = float(s[1])
		_sonde(Vector3(0.0, (y0 + y1) * 0.5, 0.0), Vector3(ri * 2.0 + 0.6, y1 - y0 + 0.4, ri * 2.0 + 0.6))
		(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	# les lieux
	var dporte := _dir(TAU * 11.0 / 28.0)
	lieux["grosse_porte"] = _p(0, 0, 0) + dporte * (r + 2.6)
	lieux["grosse_conseil"] = _p(0, 0, 0) + dporte * 4.4
	lieux["grosse_centre"] = _p(0, 0, 0)
	lieux["grosse_vis_c"] = _p(vis_c.x, 0.0, vis_c.z)
	lieux["grosse_vis_porte"] = _p(vis_c.x, 0.0, vis_c.z) + _dir(phi) * (RV + 0.9)
	lieux["grosse_vis_bas"] = _p(vis_c.x, 0.0, vis_c.z) + _dir(phi - deg_to_rad(10.0)) * 1.3
	var am: float = phi + PALIER + MARCHES_VIS * 0.5 * PAS_VIS
	lieux["grosse_vis_mi"] = _p(vis_c.x, e1 * 0.5, vis_c.z) + _dir(am) * 1.3
	lieux["grosse_vis_mi_dehors"] = _p(vis_c.x, e1 * 0.5, vis_c.z) + _dir(am) * (RV + 1.2)
	lieux["grosse_vis_e1"] = _p(vis_c.x, e1, vis_c.z) + _dir(phi) * 1.3
	lieux["grosse_bureau_porte"] = _p(vis_c.x, e1, vis_c.z) + _dir(phi) * (RV + 0.9)
	lieux["grosse_bureau"] = _p(-1.2, e1, -0.6)
	lieux["grosse_vis_e2"] = _p(vis_c.x, e2, vis_c.z) + _dir(phi) * 1.3
	lieux["grosse_vis_haut"] = _p(vis_c.x, e2, vis_c.z) + _dir(phi + deg_to_rad(60.0)) * 1.3
	lieux["grosse_vis_vide"] = _p(vis_c.x, e2, vis_c.z) + _dir(phi + deg_to_rad(200.0)) * 1.3
	lieux["grosse_reliques_porte"] = _p(vis_c.x, e2, vis_c.z) + _dir(phi) * (RV + 0.9)
	lieux["grosse_reliques"] = _p(-2.0, e2, 1.6)


## Le repère d'un étage : le centre de la tour, au niveau du plancher
func _etage(y: float) -> void:
	xf = base * Transform3D(Basis.IDENTITY, Vector3(0, y, 0))


# =================================================================== les planchers

## Un plancher (repère tour) : le disque du dedans, troué pour la cage de l'escalier ; le parquet
## dessus, les planches dessous, la collision ; les solives
func _plancher(k: RefCounted, y: float) -> void:
	var disque := PackedVector2Array()
	for i in range(48):
		var a: float = TAU * i / 48.0
		disque.append(Vector2(cos(a), sin(a)) * (ri + 0.05))
	var cage := PackedVector2Array()
	var cc := Vector2(vis_c.x, vis_c.z)
	for i in range(32):
		var a: float = TAU * i / 32.0
		cage.append(cc + Vector2(cos(a), sin(a)) * (RV - 0.12))
	# (une queue vers le mur : le trou touche le bord, le plancher reste d'un seul tenant)
	var dv := Vector2(cos(A_VIS), sin(A_VIS))
	var tv := Vector2(-dv.y, dv.x)
	var queue := PackedVector2Array([cc - tv * 0.5, cc + dv * (ri + 1.0) - tv * 0.5, cc + dv * (ri + 1.0) + tv * 0.5, cc + tv * 0.5])
	var trou: PackedVector2Array = Geometry2D.merge_polygons(cage, queue)[0]
	var reste: Array = Geometry2D.clip_polygons(disque, trou)
	var faces := PackedVector3Array()
	for poly in reste:
		var pp: PackedVector2Array = poly
		if Geometry2D.is_polygon_clockwise(pp) and reste.size() > 1:
			continue
		var idx: PackedInt32Array = Geometry2D.triangulate_polygon(pp)
		for t in range(0, idx.size(), 3):
			var a := Vector3(pp[idx[t]].x, y, pp[idx[t]].y)
			var b := Vector3(pp[idx[t + 1]].x, y, pp[idx[t + 1]].y)
			var c := Vector3(pp[idx[t + 2]].x, y, pp[idx[t + 2]].y)
			k.tri("parquet", base, a, b, c, Vector3.UP)
			k.tri("chene", base, a - Vector3(0, 0.4, 0), b - Vector3(0, 0.4, 0), c - Vector3(0, 0.4, 0), Vector3.DOWN)
			faces.append_array([a, b, c])
	var cs := ConcavePolygonShape3D.new()
	cs.backface_collision = true
	cs.set_faces(faces)
	k.shapes.append([cs, base])
	# les solives : le long de z, coupées par la cage
	var ys: float = y - 0.4
	var x: float = -ri + 0.9
	while x < ri - 0.5:
		var hz: float = sqrt(maxf(ri * ri - x * x, 0.0))
		var morceaux: Array = [[-hz, hz]]
		var dx: float = x - vis_c.x
		if absf(dx) < RV:
			var hc: float = sqrt(RV * RV - dx * dx)
			morceaux = [[-hz, vis_c.z - hc], [vis_c.z + hc, hz]]
		for m in morceaux:
			if float(m[1]) - float(m[0]) > 0.3:
				_poutre(k, "chene", _p(x, ys - 0.14, float(m[0])), _p(x, ys - 0.14, float(m[1])), 0.28, Vector3.UP)
		x += 1.5


# =================================================================== l'escalier à vis

## La cage de l'escalier : un mur rond (pierre claire dehors, la pierre du dedans dedans), percé d'une
## porte à chaque étage ; le noyau ; le plafond de la cage au-dessus du dernier palier
func _cage_vis(k: RefCounted) -> void:
	var rvi: float = RV - RV_T
	var dA: float = TAU / PANS_VIS
	var portes: Array = [0.0, e1, e2]
	var c: Vector3 = vis_c
	for i in range(PANS_VIS):
		var a0: float = phi - dA + i * dA
		var a1: float = a0 + dA
		var d0 := _dir(a0)
		var d1 := _dir(a1)
		var dm: Vector3 = (d0 + d1).normalized()
		var pleins: Array = [[0.0, plafond + 0.02]]
		if i < 2:
			for yb in portes:
				var yt: float = float(yb) + PORTE_VIS_H
				var nv: Array = []
				for pl in pleins:
					if yt <= pl[0] or float(yb) >= pl[1]:
						nv.append(pl)
					else:
						if float(yb) > pl[0]:
							nv.append([pl[0], float(yb)])
						if yt < pl[1]:
							nv.append([yt, pl[1]])
				pleins = nv
				var u := Vector3(0, yt, 0)
				var v := Vector3(0, float(yb), 0)
				# l'ébrasement (le bord de la porte), le dessous du linteau
				if i == 0:
					k.quad("pierre_claire", base, c + d0 * rvi + v, c + d0 * RV + v, c + d0 * RV + u, c + d0 * rvi + u, d0.cross(Vector3.UP))
				else:
					k.quad("pierre_claire", base, c + d1 * RV + v, c + d1 * rvi + v, c + d1 * rvi + u, c + d1 * RV + u, Vector3.UP.cross(d1))
				k.quad("pierre_claire", base, c + d0 * rvi + u, c + d1 * rvi + u, c + d1 * RV + u, c + d0 * RV + u, Vector3.DOWN)
				# le seuil (aux étages : la tranche du plancher)
				k.quad("pierre_claire", base, c + d0 * RV + v + Vector3(0, 0.02, 0), c + d1 * RV + v + Vector3(0, 0.02, 0), c + d1 * rvi + v + Vector3(0, 0.02, 0), c + d0 * rvi + v + Vector3(0, 0.02, 0), Vector3.UP)
		for pl in pleins:
			var ya := Vector3(0, float(pl[0]), 0)
			var yb2 := Vector3(0, float(pl[1]), 0)
			k.quad("pierre_claire", base, c + d0 * RV + ya, c + d1 * RV + ya, c + d1 * RV + yb2, c + d0 * RV + yb2, dm)
			k.quad("pierre_int", base, c + d1 * rvi + ya, c + d0 * rvi + ya, c + d0 * rvi + yb2, c + d1 * rvi + yb2, -dm)
			var bs := BoxShape3D.new()
			bs.size = Vector3(RV * dA * 1.08, float(pl[1]) - float(pl[0]), RV_T + 0.05)
			k.shapes.append([bs, base * Transform3D(Basis(Vector3.UP, atan2(dm.x, dm.z)), c + dm * (RV + rvi) * 0.5 + Vector3(0, (float(pl[0]) + float(pl[1])) * 0.5, 0))])
	# l'encadrement des portes, côté salle : les piédroits, le linteau (pierre claire)
	var dp := _dir(phi)
	var tg := Vector3(-dp.z, 0, dp.x)
	var bp := Basis(-tg, Vector3.UP, dp)
	var demi: float = RV * sin(dA)
	for yb3 in portes:
		var b0: Vector3 = c + dp * (RV - 0.02) + Vector3(0, float(yb3), 0)
		for e in [-1.0, 1.0]:
			k.box("pierre_claire", base * Transform3D(bp, b0 + tg * e * (demi + 0.14)), Vector3(0.26, PORTE_VIS_H, 0.2))
		k.box("pierre_claire", base * Transform3D(bp, b0 + Vector3(0, PORTE_VIS_H, 0)), Vector3(demi * 2.0 + 0.56, 0.3, 0.22))
		k.box("or", base * Transform3D(bp, b0 + dp * 0.08 + Vector3(0, PORTE_VIS_H + 0.08, 0)), Vector3(0.16, 0.16, 0.1))
	# le noyau, le plafond de la cage (au-dessus du dernier palier)
	var ytop: float = e2 + 3.0
	k.cyl("pierre_claire", Transform3D(Basis.IDENTITY, _p(c.x, 0.0, c.z)), NOYAU, NOYAU, ytop, 12, false, true)
	for i2 in range(PANS_VIS):
		var a2: float = TAU * i2 / PANS_VIS
		var a3: float = TAU * (i2 + 1) / PANS_VIS
		k.tri("chene", base, c + Vector3(0, ytop, 0), c + _dir(a2) * rvi + Vector3(0, ytop, 0), c + _dir(a3) * rvi + Vector3(0, ytop, 0), Vector3.DOWN)
	# deux lanternes dans la cage
	for lv in [[phi + PI, 8.7], [phi + PI * 0.5, 19.5]]:
		var dl := _dir(float(lv[0]))
		var lp: Vector3 = _p(c.x, float(lv[1]), c.z) + dl * (rvi - 0.42)
		_lanterne(k, lp)
		_poutre(k, "fer", lp + Vector3(0, 0.74, 0), lp + dl * 0.4 + Vector3(0, 0.74, 0), 0.04)
		_bougie(k, lp - Vector3(0, 0.35, 0), 0.18)
		_lumiere(lp - Vector3(0, 0.1, 0), 5.0, 0.7, 1.2)


## Les deux volées de la vis (chacune trois tours moins le palier), les paliers, la main courante,
## les rampes de collision
func _vis(k: RefCounted) -> void:
	var rvi: float = RV - RV_T
	var rm: float = (NOYAU + rvi) * 0.5
	var c: Vector3 = vis_c
	var da: float = PAS_VIS
	for f in range(2):
		var y0: float = 0.0 if f == 0 else e1
		var rise: float = (e1 if f == 0 else e2 - e1) / MARCHES_VIS
		for j in range(MARCHES_VIS):
			var a: float = phi + PALIER + (j + 0.5) * da
			var d := _dir(a)
			var t := _dir(a + PI * 0.5)
			var yt: float = y0 + (j + 1) * rise
			var ep: float = minf(yt - y0 + 0.05, 0.32) if f == 0 else 0.32
			var b := Basis(d, Vector3.UP, t)
			var w: float = 2.0 * rvi * sin(da * 0.5) + 0.08
			k.box("pierre_claire", base * Transform3D(b, c + d * (rm + 0.02) + Vector3(0, yt - ep, 0)), Vector3(rvi - NOYAU + 0.04, ep, w))
			# la collision : une rampe en hélice sous le nez des marches
			var pente: float = atan2(rise, rm * da)
			var bs := BoxShape3D.new()
			bs.size = Vector3(rvi - NOYAU, 0.3, rm * da / cos(pente) + 0.12)
			var yc: float = y0 + (j + 0.5) * rise
			var bt: Basis = b * Basis(Vector3.RIGHT, -pente)
			k.shapes.append([bs, base * Transform3D(bt, c + d * rm + Vector3(0, yc, 0) - bt.y * 0.15)])
			# la main courante de fer, contre le mur
			var d2 := _dir(a + da)
			var q0: Vector3 = _p(c.x, y0 + j * rise + 1.0, c.z) + d * (rvi - 0.12)
			var q1: Vector3 = _p(c.x, y0 + (j + 1) * rise + 1.0, c.z) + d2 * (rvi - 0.12)
			_poutre(k, "fer", q0, q1, 0.045, Vector3.UP)
			if j % 4 == 0:
				_poutre(k, "fer", _p(c.x, y0 + j * rise + 1.0, c.z) + d * (rvi - 0.01), q0, 0.03)
	# les paliers : autour de la porte (au premier) ; au dernier, jusqu'à la rambarde
	for pal in [[e1, -PALIER, PALIER], [e2, -PALIER, deg_to_rad(120.0)]]:
		var y: float = float(pal[0])
		var a0: float = phi + float(pal[1])
		var a1: float = phi + float(pal[2])
		var n: int = int(round((a1 - a0) / da))
		for j2 in range(n):
			var a: float = a0 + (j2 + 0.5) * da
			var d := _dir(a)
			var b := Basis(d, Vector3.UP, _dir(a + PI * 0.5))
			var w: float = 2.0 * rvi * sin(da * 0.5) + 0.08
			k.box("pierre_claire", base * Transform3D(b, c + d * (rm + 0.02) + Vector3(0, y - 0.32, 0)), Vector3(rvi - NOYAU + 0.04, 0.32, w), true)
	# la rambarde du dernier palier, au-dessus de la vis
	var ar: float = phi + deg_to_rad(120.0)
	_rambarde_droite(k, c + _dir(ar) * (NOYAU + 0.02) + Vector3(0, e2, 0), c + _dir(ar) * (rvi - 0.02) + Vector3(0, e2, 0))


# =================================================================== la Salle du Conseil

func _conseil(k: RefCounted) -> void:
	_etage(0.0)
	var h: float = e1 - 0.4
	var tc: Vector3 = -_dir(A_VIS) * 1.4
	# le tapis rond, la table ronde (le pied, le plateau, l'étoile d'or incrustée)
	k.cyl("velours_bleu", _tr(tc.x, 0.0, tc.z), 3.2, 3.2, 0.045, 40)
	k.cyl("or", _tr(tc.x, 0.0, tc.z), 3.3, 3.3, 0.038, 40)
	k.cyl("chene", _tr(tc.x, 0.0, tc.z), 0.75, 0.5, 0.12, 16)
	k.cyl("chene", _tr(tc.x, 0.12, tc.z), 0.36, 0.3, 0.6, 16)
	k.cyl("chene", _tr(tc.x, 0.72, tc.z), 1.85, 1.9, 0.08, 40, true, true)
	k.cyl("or", _tr(tc.x, 0.8, tc.z), 1.55, 1.55, 0.004, 40)
	k.cyl("chene", _tr(tc.x, 0.8, tc.z), 1.48, 1.48, 0.006, 40)
	for i in range(8):
		var a: float = TAU * i / 8.0
		var lg: float = 1.25 if i % 2 == 0 else 0.8
		var dd := _dir(a)
		k.box("or", Transform3D(xf.basis * Basis(Vector3.UP, atan2(dd.x, dd.z)), _p(tc.x, 0.806, tc.z) + dd * lg * 0.5), Vector3(0.07, 0.004, lg))
	k.cyl("or", _tr(tc.x, 0.806, tc.z), 0.2, 0.2, 0.005, 16)
	# les sièges des maîtres : tout autour, sauf du côté de la porte ; le siège du Recteur (au fond)
	var vers_porte: float = atan2(4.34 - tc.z, -5.36 - tc.x)
	for i2 in range(1, 10):
		var a2: float = vers_porte + TAU * i2 / 10.0
		var d2 := _dir(a2)
		var q: Vector3 = tc + d2 * 2.45
		_cathedre(k, q, d2, i2 == 5)
		if i2 % 2 == 1:
			_bougie(k, _p(tc.x, 0.8, tc.z) + d2 * 1.35, 0.22)
	# la couronne de fer et ses bougies, au-dessus de la table
	_couronne_fer(k, _p(tc.x, 6.5, tc.z), 1.6, 16, _p(tc.x, h, tc.z))
	_lumiere(_p(tc.x, 6.8, tc.z), 14.0, 1.2, 2.2)
	# les bannières de l'Académie, entre les baies
	var bn: Array = [[10.0, "banniere_bleu"], [95.0, "banniere_pourpre"], [185.0, "banniere_bleu"], [255.0, "banniere_pourpre"]]
	for bb in bn:
		var d3 := _dir(deg_to_rad(float(bb[0])))
		_banniere(k, str(bb[1]), _p(0, h - 1.2, 0) + d3 * (ri - 0.08), 1.4, 5.2, xf.basis * -d3)
	# les lanternes de part et d'autre de la porte
	var ap: float = TAU * 11.0 / 28.0
	for e in [-1.0, 1.0]:
		_lanterne_murale(k, ap + e * deg_to_rad(24.0), 2.6)
	_lumiere(_p(0, 4.0, 0) + _dir(ap) * 3.0, 9.0, 0.6, 1.0)


## Le haut siège d'un maître (q au sol, d : vers le dehors de la table) ; le Recteur a le sien,
## plus haut, de velours pourpre
func _cathedre(k: RefCounted, q: Vector3, d: Vector3, recteur: bool) -> void:
	var t: Transform3D = _tr(q.x, 0.0, q.z, atan2(-d.x, -d.z))
	var hd: float = 1.9 if recteur else 1.45
	var v: String = "velours_pourpre" if recteur else "velours_bleu"
	k.box("chene", t, Vector3(0.56, 0.44, 0.5), true)
	k.box(v, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.44, 0.02)), Vector3(0.5, 0.06, 0.44))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.44, -0.24)), Vector3(0.56, hd, 0.08))
	k.box(v, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.56, -0.19)), Vector3(0.42, hd - 0.3, 0.03))
	for e in [-1.0, 1.0]:
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(e * 0.26, 0.44, 0.0)), Vector3(0.06, 0.3, 0.46))
		k.cyl("or", t * Transform3D(Basis.IDENTITY, Vector3(e * 0.24, 0.44 + hd, -0.24)), 0.05, 0.0, 0.16, 8)
	if recteur:
		k.cyl("or", t * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.44 + hd - 0.3, -0.165)), 0.16, 0.16, 0.02, 14)


## Une couronne de lumière en fer : l'anneau, les bougies, les chaînes jusqu'au plafond
func _couronne_fer(k: RefCounted, p: Vector3, r: float, nb: int, haut: Vector3) -> void:
	for i in range(nb):
		var a0: float = TAU * i / nb
		var a1: float = TAU * (i + 1) / nb
		var q0: Vector3 = p + _dir(a0) * r
		var q1: Vector3 = p + _dir(a1) * r
		_poutre(k, "fer", q0, q1, 0.07, Vector3.UP)
		k.cyl("fer", Transform3D(Basis.IDENTITY, q0 + Vector3(0, 0.035, 0)), 0.06, 0.07, 0.03, 6)
		_bougie(k, q0 + Vector3(0, 0.065, 0), 0.24)
	for i2 in range(4):
		var a2: float = TAU * i2 / 4.0 + 0.4
		_poutre(k, "fer", p + _dir(a2) * r, p + Vector3(0, 2.6, 0), 0.035)
	_poutre(k, "fer", p + Vector3(0, 2.6, 0), haut, 0.06)
	k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, -0.45, 0)), 0.0, 0.16, 0.45, 8)


## Une lanterne sur sa potence, au mur (angle a, hauteur y : repère de l'étage)
func _lanterne_murale(k: RefCounted, a: float, y: float) -> void:
	var dl := _dir(a)
	var lp: Vector3 = _p(0, y, 0) + dl * (ri - 0.55)
	_lanterne(k, lp)
	_poutre(k, "fer", lp + Vector3(0, 0.74, 0), _p(0, y + 0.9, 0) + dl * (ri - 0.55), 0.03)
	_poutre(k, "fer", _p(0, y + 0.9, 0) + dl * (ri - 0.55), _p(0, y + 0.9, 0) + dl * ri, 0.04)
	_bougie(k, lp - Vector3(0, 0.35, 0), 0.18)
	_lumiere(lp - Vector3(0, 0.1, 0), 7.0, 0.7, 1.3)


# =================================================================== le Bureau du Recteur

func _bureau(k: RefCounted) -> void:
	var h: float = e2 - e1 - 0.4
	# la cheminée, contre le mur (au sud-ouest) : dans un repère tourné vers elle
	var af: float = deg_to_rad(200.0)
	xf = base * Transform3D(Basis(Vector3.UP, atan2(-cos(af), -sin(af))), Vector3(0, e1, 0))
	_cheminee_c(k, 0.0, -(ri - 0.22), h)
	_etage(e1)
	# le grand bureau (tourné vers le milieu), le fauteuil du Recteur, les deux fauteuils devant
	var ad: float = deg_to_rad(60.0)
	var dd := _dir(ad)
	var pd: Vector3 = dd * 3.6
	var t: Transform3D = _tr(pd.x, 0.0, pd.z, atan2(-dd.x, -dd.z))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.78, 0)), Vector3(2.4, 0.07, 1.1), true)
	for e in [-1.0, 1.0]:
		k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(e * 0.82, 0.0, 0.0)), Vector3(0.6, 0.78, 1.0), true)
		for j in range(3):
			k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(e * 0.82, 0.16 + j * 0.24, -0.505)), Vector3(0.12, 0.03, 0.02))
	k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0.42)), Vector3(1.1, 0.56, 0.04))
	k.box("velours_vert", t * Transform3D(Basis.IDENTITY, Vector3(0.1, 0.85, 0.05)), Vector3(1.3, 0.005, 0.7))
	# sur le bureau : les papiers, l'encrier et sa plume, le grimoire, le sablier, la bougie
	k.box("drap", t * Transform3D(Basis(Vector3.UP, 0.15), Vector3(-0.1, 0.855, 0.1)), Vector3(0.42, 0.01, 0.3))
	k.box("drap", t * Transform3D(Basis(Vector3.UP, -0.1), Vector3(0.2, 0.86, 0.15)), Vector3(0.42, 0.01, 0.3))
	k.cyl("fer", t * Transform3D(Basis.IDENTITY, Vector3(0.55, 0.855, 0.2)), 0.06, 0.05, 0.08, 10)
	_poutre(k, "drap", t * Vector3(0.55, 0.9, 0.2), t * Vector3(0.68, 1.15, 0.12), 0.012)
	k.box("velours_pourpre", t * Transform3D(Basis(Vector3.UP, 0.3), Vector3(-0.75, 0.855, 0.05)), Vector3(0.34, 0.08, 0.46))
	k.box("or", t * Transform3D(Basis(Vector3.UP, 0.3), Vector3(-0.75, 0.935, 0.05)), Vector3(0.1, 0.005, 0.1))
	_sablier(k, t * Vector3(-0.35, 0.855, -0.3))
	_bougie(k, t * Vector3(0.85, 0.855, -0.25), 0.22)
	_lumiere(t * Vector3(0.8, 1.4, 0.2), 5.0, 0.5, 1.0)
	var pf: Vector3 = dd * 4.6
	_canape(k, pf.x, pf.z, atan2(dd.x, dd.z), 0.8, "velours_pourpre")
	k.box("velours_pourpre", _tr(pf.x, 0.0, pf.z, atan2(dd.x, dd.z)) * Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0.32)), Vector3(0.9, 0.6, 0.2))
	var tg := _dir(ad + PI * 0.5)
	for e2 in [-1.0, 1.0]:
		var pv: Vector3 = dd * 2.1 + tg * e2 * 0.75
		_canape(k, pv.x, pv.z, atan2(-dd.x, -dd.z) - e2 * 0.25, 0.7, "velours_vert")
	# le tapis
	k.quad("tapis", xf, dd * 1.2 - tg * 1.6 + Vector3(0, 0.012, 0), dd * 1.2 + tg * 1.6 + Vector3(0, 0.012, 0), dd * 4.0 + tg * 1.6 + Vector3(0, 0.012, 0), dd * 4.0 - tg * 1.6 + Vector3(0, 0.012, 0), Vector3.UP)
	# le globe, les bibliothèques
	_globe(k, _dir(deg_to_rad(160.0)) * 4.9)
	for ab in [235.0, 262.0, 330.0, 348.0]:
		var d4 := _dir(deg_to_rad(ab))
		var pos: Vector3 = d4 * (ri - 0.3)
		_rayonnage(k, _tr(pos.x, 0.0, pos.z, atan2(-d4.x, -d4.z)), 2.0, 3.4, 0.45, false)
	# la galerie des portraits : les anciens Recteurs (deux rangs), au-dessus des bibliothèques
	var n: int = 0
	for pr in [[40.0, 2.2], [75.0, 2.2], [95.0, 2.2], [130.0, 2.2], [150.0, 2.2], [175.0, 2.2],
			[50.0, 4.6], [85.0, 4.6], [140.0, 4.6], [165.0, 4.6],
			[235.0, 4.1], [262.0, 4.1], [330.0, 4.1], [348.0, 4.1]]:
		_portrait(k, deg_to_rad(float(pr[0])), float(pr[1]), n)
		n += 1
	# la couronne de lumière
	_couronne_fer(k, _p(0.0, 6.6, 0.0), 1.2, 12, _p(0.0, h, 0.0))
	_lumiere(_p(0.0, 6.9, 0.0), 13.0, 1.1, 2.0)
	_lumiere(_p(0, 3.0, 0) + _dir(deg_to_rad(110.0)) * 4.0, 8.0, 0.5, 0.8)


## Un portrait (a : l'angle au mur, y : le bas, n : le numéro) : la toile peinte, le cadre doré
func _portrait(k: RefCounted, a: float, y: float, n: int) -> void:
	var d := _dir(a)
	var tg := _dir(a + PI * 0.5)
	var w: float = 1.0
	var h: float = 1.28
	var c: Vector3 = d * (ri - 0.08)
	var pa: Vector3 = c - tg * w * 0.5 + Vector3(0, y, 0)
	var pb: Vector3 = c + tg * w * 0.5 + Vector3(0, y, 0)
	# (vu de face, la gauche est du côté -tg : de pa à pb)
	k.quad("portrait", xf, pa, pb, pb + Vector3(0, h, 0), pa + Vector3(0, h, 0), -d,
		Vector2(n, 0), Vector2(n + 1, 0), Vector2(n + 1, 1), Vector2(n, 1))
	var o: Vector3 = -d * 0.03
	var up := Vector3(0, h, 0)
	for seg in [[pa, pb], [pa + up, pb + up], [pa, pa + up], [pb, pb + up]]:
		_pl(k, "or", seg[0] + o, seg[1] + o, 0.1, d)
	k.box("or", Transform3D(xf.basis * Basis(Vector3.UP, atan2(d.x, d.z)), _p(0, 0, 0) + c - d * 0.05 + Vector3(0, y + h + 0.06, 0)), Vector3(0.22, 0.12, 0.05))


## Le sablier du Recteur (p : le bas, repère château)
func _sablier(k: RefCounted, p: Vector3) -> void:
	k.cyl("chene", Transform3D(xf.basis, p), 0.1, 0.1, 0.03, 10)
	k.cyl("chene", Transform3D(xf.basis, p + Vector3(0, 0.33, 0)), 0.1, 0.1, 0.03, 10)
	for i in range(3):
		var a: float = TAU * i / 3.0
		_poutre(k, "chene", p + _dir(a) * 0.085, p + _dir(a) * 0.085 + Vector3(0, 0.33, 0), 0.02)
	k.cyl("cristal", Transform3D(xf.basis, p + Vector3(0, 0.03, 0)), 0.07, 0.01, 0.15, 10)
	k.cyl("cristal", Transform3D(xf.basis, p + Vector3(0, 0.18, 0)), 0.01, 0.07, 0.15, 10)
	k.cyl("potion_ambre", Transform3D(xf.basis, p + Vector3(0, 0.03, 0)), 0.05, 0.02, 0.06, 8)


# =================================================================== la Salle des Reliques

func _reliques(k: RefCounted) -> void:
	xf = base
	_plafond_etoile(k)
	_etage(e2)
	# le cercle de runes autour du socle de la Couronne
	_anneau_plat(k, "rune", 0.015, 1.3, 1.36)
	_anneau_plat(k, "rune_violet", 0.015, 1.9, 1.94)
	for i in range(12):
		var a: float = TAU * i / 12.0
		_trait(k, "rune" if i % 2 == 0 else "rune_violet", _dir(a) * 1.45 + Vector3(0, 0.016, 0), _dir(a) * 1.78 + Vector3(0, 0.016, 0), 0.05)
	# le socle, la colonne de lumière, la Couronne des Fondateurs (un nœud à part, qui tourne)
	k.cyl("pierre_claire", _tr(0, 0, 0), 0.75, 0.6, 0.25, 16, true, true)
	k.cyl("pierre_claire", _tr(0, 0.25, 0), 0.45, 0.4, 0.75, 16, true, true)
	k.cyl("or", _tr(0, 0.62, 0), 0.43, 0.43, 0.06, 16, false)
	k.cyl("pierre_claire", _tr(0, 1.0, 0), 0.55, 0.55, 0.1, 16)
	k.cyl("voile", _tr(0, 1.1, 0), 0.5, 0.42, 3.4, 20, false)
	_y_couronne = 2.15
	couronne = Node3D.new()
	couronne.name = "Couronne_fondateurs"
	couronne.position = _p(0, _y_couronne, 0)
	couronne.scale = Vector3.ONE * 1.35
	add_child(couronne)
	var kc := Kit.new()
	kc.cyl("or", Transform3D.IDENTITY, 0.3, 0.3, 0.1, 24, false)
	kc.cyl("or", Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), 0.29, 0.29, 0.1, 24, false)
	for i2 in range(8):
		var a2: float = TAU * i2 / 8.0
		var dc := _dir(a2)
		kc.cyl("or", Transform3D(Basis.IDENTITY, dc * 0.29 + Vector3(0, 0.1, 0)), 0.045, 0.0, 0.18 if i2 % 2 == 0 else 0.11, 6)
		_sphere(kc, "or", dc * 0.29 + Vector3(0, 0.3 if i2 % 2 == 0 else 0.22, 0), 0.022)
		kc.box("potion_rouge" if i2 % 2 == 0 else "potion_bleu", Transform3D(Basis(Vector3.UP, a2), dc * 0.305 + Vector3(0, 0.035, 0)), Vector3(0.04, 0.04, 0.03))
	couronne.add_child(kc.commit("Couronne_maillage"))
	_lueur(_p(0, 1.6, 0), Color(0.85, 0.8, 1.0), 7.0, 0.6, 1.3)
	# les vitrines et leurs reliques
	var vt: Array = [[0.0, 0], [60.0, 1], [110.0, 2], [160.0, 3], [210.0, 4], [250.0, 5]]
	for v in vt:
		var dv := _dir(deg_to_rad(float(v[0])))
		_vitrine(k, dv * 4.9, atan2(-dv.x, -dv.z), int(v[1]))
	_lueur(_p(0, 1.4, 0) + _dir(deg_to_rad(110.0)) * 4.9, Color(0.5, 0.9, 1.0), 3.5, 0.4, 0.9)
	# les coffres ferrés, contre le mur ; les écus et les épées croisées
	for ac in [135.0, 185.0]:
		var d5 := _dir(deg_to_rad(ac))
		_coffre(k, d5 * (ri - 0.55), atan2(-d5.x, -d5.z))
	for ae in [80.0, 95.0, 170.0, 190.0]:
		var d6 := _dir(deg_to_rad(ae))
		_ecu(k, d6 * (ri - 0.05), d6, 3.2, int(ae) % 3)
	# les lumières : la colonne, deux couronnes de fer
	for al in [70.0, 200.0]:
		var d7 := _dir(deg_to_rad(al))
		_couronne_fer(k, _p(0, 6.0, 0) + d7 * 3.4, 0.7, 8, _p(0, plafond - e2 - 0.3, 0) + d7 * 3.4)
		_lumiere(_p(0, 6.3, 0) + d7 * 3.4, 10.0, 0.8, 1.6)


## Une vitrine (q au sol, yaw : la face vers le milieu) : le meuble, la cage de verre au cadre doré, le
## coussin, la relique
func _vitrine(k: RefCounted, q: Vector3, yaw: float, n: int) -> void:
	var t: Transform3D = _tr(q.x, 0.0, q.z, yaw)
	k.box("chene", t, Vector3(0.9, 0.9, 0.8), true)
	k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.88, 0)), Vector3(0.96, 0.05, 0.86))
	k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.35, 0.405)), Vector3(0.5, 0.2, 0.01))
	var hv: float = 0.62
	var y0: float = 0.93
	var g := Vector3(0.42, 0, 0.37)
	k.box("vitrine", t * Transform3D(Basis.IDENTITY, Vector3(0, y0, 0)), Vector3(g.x * 2.0, hv, g.z * 2.0))
	var col := BoxShape3D.new()
	col.size = Vector3(g.x * 2.0, hv, g.z * 2.0)
	k.shapes.append([col, t * Transform3D(Basis.IDENTITY, Vector3(0, y0 + hv * 0.5, 0))])
	for ex in [-1.0, 1.0]:
		for ez in [-1.0, 1.0]:
			_poutre(k, "or", t * Vector3(ex * g.x, y0, ez * g.z), t * Vector3(ex * g.x, y0 + hv, ez * g.z), 0.03)
		_poutre(k, "or", t * Vector3(ex * g.x, y0 + hv, -g.z), t * Vector3(ex * g.x, y0 + hv, g.z), 0.03)
		_poutre(k, "or", t * Vector3(-g.x, y0 + hv, ex * g.z), t * Vector3(g.x, y0 + hv, ex * g.z), 0.03)
	k.box("velours_bleu" if n % 2 == 0 else "velours_pourpre", t * Transform3D(Basis.IDENTITY, Vector3(0, y0, 0)), Vector3(0.56, 0.07, 0.44))
	var r: Transform3D = t * Transform3D(Basis.IDENTITY, Vector3(0, y0 + 0.07, 0))
	match n:
		0:
			# l'épée du premier maître d'armes : la lame, la garde, la poignée, le pommeau
			var s: Transform3D = r * Transform3D(Basis(Vector3.UP, 0.6), Vector3.ZERO)
			k.box("fer", s * Transform3D(Basis.IDENTITY, Vector3(0, 0.005, -0.08)), Vector3(0.05, 0.015, 0.5))
			k.box("or", s * Transform3D(Basis.IDENTITY, Vector3(0, 0.0, 0.18)), Vector3(0.22, 0.03, 0.03))
			k.box("bois", s * Transform3D(Basis.IDENTITY, Vector3(0, 0.0, 0.25)), Vector3(0.03, 0.03, 0.11))
			_sphere(k, "or", s * Vector3(0, 0.015, 0.32), 0.025)
		1:
			# la coupe des fondateurs
			k.cyl("or", r, 0.1, 0.08, 0.02, 14)
			k.cyl("or", r * Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), 0.025, 0.025, 0.14, 8)
			k.cyl("or", r * Transform3D(Basis.IDENTITY, Vector3(0, 0.16, 0)), 0.03, 0.12, 0.13, 14, false)
			k.cyl("potion_rouge", r * Transform3D(Basis.IDENTITY, Vector3(0, 0.27, 0)), 0.105, 0.105, 0.005, 14)
			for e in [-1.0, 1.0]:
				k.box("potion_bleu", r * Transform3D(Basis.IDENTITY, Vector3(e * 0.07, 0.22, 0.0)), Vector3(0.03, 0.03, 0.03))
		2:
			# le cristal de la source : trois aiguilles qui luisent
			for i in range(3):
				var a: float = TAU * i / 3.0
				var inc := Basis(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5)), 0.25 if i > 0 else 0.0)
				k.cyl("cristal", r * Transform3D(inc, _dir(a) * (0.05 if i > 0 else 0.0)), 0.05, 0.0, 0.35 if i == 0 else 0.22, 6)
			k.cyl("rune", r * Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), 0.03, 0.0, 0.18, 6)
		3:
			# le premier grimoire de l'Académie, fermé, ses coins d'or
			var bk: Transform3D = r * Transform3D(Basis(Vector3.UP, -0.3), Vector3.ZERO)
			k.box("velours_pourpre", bk, Vector3(0.34, 0.09, 0.44))
			k.box("drap", bk * Transform3D(Basis.IDENTITY, Vector3(0.012, 0.01, 0)), Vector3(0.31, 0.07, 0.42))
			for ex2 in [-1.0, 1.0]:
				for ez2 in [-1.0, 1.0]:
					k.box("or", bk * Transform3D(Basis.IDENTITY, Vector3(ex2 * 0.15, 0.085, ez2 * 0.2)), Vector3(0.05, 0.01, 0.05))
			k.cyl("or", bk * Transform3D(Basis.IDENTITY, Vector3(0, 0.09, 0)), 0.06, 0.06, 0.005, 12)
		4:
			# la baguette de la fondatrice : le bois, le bout qui luit
			var wd: Transform3D = r * Transform3D(Basis(Vector3.UP, 1.1), Vector3(0, 0.02, 0))
			_poutre(k, "bois", wd * Vector3(0, 0, -0.2), wd * Vector3(0, 0, 0.18), 0.022)
			_poutre(k, "or", wd * Vector3(0, 0, 0.1), wd * Vector3(0, 0, 0.14), 0.03)
			_sphere(k, "rune_violet", wd * Vector3(0, 0, -0.21), 0.018)
		_:
			# l'astrolabe de poche : trois anneaux d'or autour d'une petite sphère bleue
			var cc: Vector3 = r * Vector3(0, 0.16, 0)
			_anneau(k, cc, Vector3.UP, 0.12, 0.012)
			_anneau(k, cc, Vector3(1, 0, 0.4).normalized(), 0.11, 0.012)
			_anneau(k, cc, Vector3(0.3, 0.5, 1).normalized(), 0.1, 0.012)
			_sphere(k, "velours_bleu", cc, 0.05)
			k.cyl("or", r, 0.05, 0.02, 0.06, 8)


## Un coffre ferré (q au sol, yaw : la face) : la caisse, le couvercle bombé, les bandes de fer, la serrure
func _coffre(k: RefCounted, q: Vector3, yaw: float) -> void:
	var t: Transform3D = _tr(q.x, 0.0, q.z, yaw)
	k.box("bois", t, Vector3(1.2, 0.55, 0.65), true)
	var couche := Basis(Vector3.BACK, -PI * 0.5)
	k.cyl("bois", t * Transform3D(couche, Vector3(-0.6, 0.55, 0)), 0.325, 0.325, 1.2, 14, true)
	for xb in [-0.42, 0.0, 0.42]:
		k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(xb, 0.0, 0.0)), Vector3(0.07, 0.56, 0.67))
		k.cyl("fer", t * Transform3D(couche, Vector3(xb - 0.035, 0.55, 0)), 0.335, 0.335, 0.07, 14, false)
	k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.38, 0.33)), Vector3(0.12, 0.16, 0.03))
	k.cyl("fer", t * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.44, 0.345)), 0.02, 0.02, 0.01, 6)


## Un écu au mur (p : au mur, d : vers le dehors ; y : le milieu ; v : la variante)
func _ecu(k: RefCounted, p: Vector3, d: Vector3, y: float, v: int) -> void:
	var c: Vector3 = _p(0, y, 0) + p - d * 0.08
	var b := Basis(Vector3.UP.cross(-d).normalized(), Vector3.UP, -d)
	k.cyl("bronze" if v == 0 else "or", Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), c), 0.42, 0.42, 0.05, 18)
	k.cyl(["velours_bleu", "velours_pourpre", "velours_vert"][v], Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), c - d * 0.052), 0.34, 0.34, 0.004, 18)
	k.cyl("or", Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), c - d * 0.058), 0.09, 0.05, 0.05, 10)
	# deux épées croisées derrière : la lame, la garde, le pommeau
	for e in [-1.0, 1.0]:
		var u: Vector3 = (b.x * e + Vector3.UP).normalized()
		var w: Vector3 = (b.x * -e + Vector3.UP).normalized()
		_poutre(k, "fer", c + d * 0.04 - u * 0.5, c + d * 0.04 + u * 0.8, 0.045, -d)
		_poutre(k, "or", c + d * 0.03 - u * 0.5 - w * 0.13, c + d * 0.03 - u * 0.5 + w * 0.13, 0.04, -d)
		_poutre(k, "bois", c + d * 0.03 - u * 0.5, c + d * 0.03 - u * 0.68, 0.035, -d)
		_sphere(k, "or", c + d * 0.03 - u * 0.71, 0.035)


func _process(delta: float) -> void:
	super._process(delta)
	if couronne != null:
		couronne.rotation.y = _tm * 0.35
		couronne.position = _p(0, e2 + _y_couronne + 0.06 * sin(_tm * 0.9), 0)

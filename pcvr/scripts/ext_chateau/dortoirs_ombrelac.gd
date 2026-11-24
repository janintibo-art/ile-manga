extends "res://scripts/ext_chateau/salles_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : les dortoirs, au premier étage de l'Aile nord (au-dessus
## des salles d'étude), et la tour de l'escalier qui y monte :
##  - la tour de l'escalier, au bout est de l'aile : sa porte sur le cloître, l'escalier à vis de
##    pierre autour de son noyau, la main courante de fer, le palier, les lanternes ;
##  - le Dortoir de l'Aube (à l'ouest, aux rideaux bleus) et le Dortoir du Crépuscule (à l'est, aux
##    rideaux pourpres) : six lits à baldaquin, leurs malles, leurs tables de chevet et leurs
##    bougies, le poêle de fonte au milieu, le tapis, les bannières ;
##  - la Salle Commune, entre les deux : la cheminée et son feu, le canapé et les fauteuils, le
##    tapis rond, la table basse, l'échiquier, la grande table d'étude, les bibliothèques, le lustre.
## Repère : xf (celui de l'aile, posé sur le plancher de l'étage) : x le long de l'aile, z en travers
## (z > 0 : le cloître) ; xf_sol : le même au niveau du plateau (pour la tour).

const PLANCHER := 0.25                   # l'épaisseur du plancher de l'étage
const PORTE_REFEND := Vector2(0.6, 2.0)  # les portes des murs de refend, à l'étage (z de .. à)
const PASSAGE_Z := 0.95                  # le passage de la tour au dortoir : de -z à z
const MARCHES := 31
const PAS_ANGLE := 13.5                  # degrés par marche

var xf_sol: Transform3D


func _t0(x: float, y: float, z: float, yaw: float = 0.0) -> Transform3D:
	return xf_sol * Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))


func construire_dortoirs(the_xf: Transform3D, L: float, W: float, rz: float, E: float, T: float, refends: Array, bout: float, tc: Vector3, ri: float, portes_tour: Array) -> void:
	xf_sol = the_xf
	var F: float = rz + PLANCHER
	xf = the_xf * Transform3D(Basis.IDENTITY, Vector3(0, F, 0))
	_rng.seed = 7313
	var k := Kit.new()
	var hw: float = W * 0.5 - T
	var hl: float = L * 0.5 - T - bout
	var H: float = E - F
	var xa0: float = -hl
	var xa1: float = float(refends[0]) - 0.3
	var xb0: float = float(refends[0]) + 0.3
	var xb1: float = float(refends[1]) - 0.3
	var xc0: float = float(refends[1]) + 0.3
	var xc1: float = hl
	# les planchers (dessous, le plafond des salles d'étude), les plafonds et leurs solives
	for r in [[xa0, xa1], [xb0, xb1], [xc0, xc1]]:
		k.box("parquet", _tr((r[0] + r[1]) * 0.5, -PLANCHER, 0.0), Vector3(r[1] - r[0], PLANCHER, hw * 2.0 + 0.8), true)
		_plafond(k, r[0], r[1], hw, H)
	for xr in refends:
		k.box("parquet", _tr(float(xr), -PLANCHER, (PORTE_REFEND.x + PORTE_REFEND.y) * 0.5), Vector3(0.62, PLANCHER, PORTE_REFEND.y - PORTE_REFEND.x), true)
	# le bout ouest, plein (la tour d'angle mord dans l'aile)
	k.box("pierre_int", _tr(-(L * 0.5 - T - bout * 0.5), -PLANCHER, 0.0), Vector3(bout, H + PLANCHER, hw * 2.0), true)
	# le passage vers la tour : son dallage
	var xe: float = tc.x - ri + 0.3
	k.box("dalles_int", _tr((hl + xe) * 0.5, -0.1, 0.0), Vector3(xe - hl, 0.1, PASSAGE_Z * 2.0), true)
	_dortoir(k, xa0, xa1, hw, H, "velours_bleu", "banniere_bleu")
	_commune(k, xb0, xb1, hw, H)
	_dortoir(k, xc0, xc1, hw, H, "velours_pourpre", "banniere_pourpre")
	_tour(k, tc, ri, F, E, portes_tour)
	var mi: MeshInstance3D = k.commit("Ombrelac_dortoirs_meubles")
	mi.visibility_range_end = 120.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_dortoirs_meubles_col"))
	for r2 in [[xa0, xa1], [xb0, xb1], [xc0, xc1]]:
		# (la sonde ne descend pas sous le plancher : en dessous, celles des salles d'étude)
		_sonde(Vector3((r2[0] + r2[1]) * 0.5, H * 0.5, 0.0), Vector3(r2[1] - r2[0] + 1.2, H + 0.5, hw * 2.0 + 1.2))
		(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	_sonde(Vector3(tc.x, E * 0.5 - F, tc.z), Vector3(ri * 2.0 + 1.2, E + 2.0, ri * 2.0 + 1.2))
	var xma: float = (xa0 + xa1) * 0.5
	var xmc: float = (xc0 + xc1) * 0.5
	lieux["dortoir_aube"] = _p(xma + 2.4, 0.0, 0.0)
	lieux["dortoir_crepuscule"] = _p(xmc + 2.4, 0.0, 0.0)
	lieux["salle_commune"] = _p(-6.0, 0.0, 1.3)
	lieux["salle_commune_est"] = _p(6.0, 0.0, 1.3)
	var zp: float = (PORTE_REFEND.x + PORTE_REFEND.y) * 0.5
	lieux["dortoirs_passage_o"] = _p(xa1 - 1.6, 0.0, zp)
	lieux["dortoirs_passage_e"] = _p(xc0 + 1.6, 0.0, zp)
	var ab: float = _angle_porte(portes_tour[0])
	var db := Vector3(cos(ab), 0, sin(ab))
	lieux["tour_dortoirs_bas"] = xf_sol * (tc + db * 2.9)
	lieux["tour_dortoirs_porte"] = xf_sol * (tc + db * (ri + 3.8))
	lieux["tour_dortoirs_haut"] = _p(tc.x - 2.2, 0.0, 0.0)
	lieux["tour_dortoirs_centre"] = xf_sol * tc


func _angle_porte(po: Array) -> float:
	return TAU * (float(po[0]) + 0.5 * float(po[2])) / 28.0


# =================================================================== les dortoirs

func _dortoir(k: RefCounted, x0: float, x1: float, hw: float, H: float, velours: String, banniere: String) -> void:
	var xm: float = (x0 + x1) * 0.5
	for s in [-1.0, 1.0]:
		for bx in [xm - 3.75, xm, xm + 3.75]:
			_lit(k, bx, s, hw, velours)
		# les tables de chevet et leurs bougies, entre les lits
		for cx in [xm - 1.875, xm + 1.875]:
			k.box("bois", _tr(cx, 0.0, s * (hw - 0.35)), Vector3(0.5, 0.62, 0.45), true)
			k.box("chene", _tr(cx, 0.62, s * (hw - 0.35)), Vector3(0.56, 0.04, 0.5))
			k.cyl("or", _tr(cx, 0.66, s * (hw - 0.35)), 0.07, 0.06, 0.02, 8)
			_bougie(k, _p(cx, 0.68, s * (hw - 0.35)), 0.16)
	# le poêle de fonte, au milieu, sur sa plaque de pierre ; le tapis de l'allée
	_poele(k, xm, 0.0, H)
	k.quad("tapis", xf, Vector3(x0 + 0.8, 0.012, -0.9), Vector3(x1 - 0.8, 0.012, -0.9), Vector3(x1 - 0.8, 0.012, 0.9), Vector3(x0 + 0.8, 0.012, 0.9), Vector3.UP,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	# les bannières sur les pignons
	for xe in [x0 + 0.06, x1 - 0.06]:
		var n: Vector3 = Vector3(1, 0, 0) if xe < xm else Vector3(-1, 0, 0)
		for zb in [-2.8, 2.8]:
			_banniere(k, banniere, _p(xe, H - 0.5, zb), 1.3, 2.7, xf.basis * n)
	# deux lanternes pendues, une lumière
	for lx in [xm - 2.6, xm + 2.6]:
		var lc: Vector3 = _p(lx, H - 1.3, 0.0)
		_lanterne(k, lc)
		_poutre(k, "fer", lc + Vector3(0, 0.74, 0), _p(lx, H - 0.6, 0.0), 0.03)
		_bougie(k, lc - Vector3(0, 0.35, 0), 0.18)
	_lumiere(_p(xm, H - 1.7, 0.0), 12.0, 0.7, 1.5)


## Un lit à baldaquin, la tête contre le mur (z = s * hw), les pieds vers l'allée
## (v11 : les colonnes tournées, la tête de lit à panneaux, le matelas, l'édredon qui retombe sur les
## côtés, les oreillers, les rideaux plissés noués par leurs embrasses, la frange d'or du ciel de lit,
## la malle cerclée de fer et ses poignées)
func _lit(k: RefCounted, x: float, s: float, hw: float, velours: String) -> void:
	var zt: float = s * (hw - 0.02)        # la tête
	var zp: float = s * (hw - 2.1)         # le pied
	var zc: float = (zt + zp) * 0.5
	# le bois de lit : les traverses, le sommier ; les colonnes tournées et leurs pommes de pin
	k.box("chene", _tr(x, 0.08, zc), Vector3(1.3, 0.3, 2.06), true)
	k.box("chene", _tr(x, 0.36, zc), Vector3(1.34, 0.04, 2.1))
	for ex in [-1.0, 1.0]:
		for zz in [zt - s * 0.05, zp + s * 0.05]:
			_colonne_tournee(k, "chene", _tr(x + ex * 0.62, 0.0, zz), 2.45, 0.05)
			k.cyl("or", _tr(x + ex * 0.62, 2.48, zz), 0.045, 0.0, 0.12, 8)
	# la tête de lit : le cadre, deux panneaux en relief, le fronton
	var zh: float = zt - s * 0.05
	k.box("chene", _tr(x, 0.0, zh), Vector3(1.24, 1.25, 0.06))
	for ex4 in [-0.29, 0.29]:
		k.box("bois", _tr(x + ex4, 0.5, zh - s * 0.035), Vector3(0.48, 0.6, 0.02))
		k.box("chene", _tr(x + ex4, 0.56, zh - s * 0.05), Vector3(0.38, 0.48, 0.02))
	k.box("chene", _tr(x, 1.25, zh), Vector3(1.3, 0.06, 0.1))
	k.cyl("or", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x, 1.06, zh - s * 0.05)), 0.05, 0.05, 0.015, 12)
	# le pied de lit : un bandeau bas
	k.box("chene", _tr(x, 0.36, zp + s * 0.05), Vector3(1.24, 0.3, 0.05))
	# le matelas (les bords arrondis), le drap
	k.box("drap", _tr(x, 0.4, zc), Vector3(1.14, 0.16, 1.94))
	for ex5 in [-1.0, 1.0]:
		k.cyl("drap", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x + ex5 * 0.57, 0.48, zc - 0.97)), 0.08, 0.08, 1.94, 8, false)
	# l'édredon : le dessus, les retombées sur les côtés et au pied, le revers du drap
	var ze: float = zp + s * 0.8
	k.box(velours, _tr(x, 0.56, ze), Vector3(1.28, 0.08, 1.5))
	for ex6 in [-1.0, 1.0]:
		k.box(velours, _tr(x + ex6 * 0.63, 0.3, ze), Vector3(0.04, 0.32, 1.5))
		k.cyl(velours, Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x + ex6 * 0.62, 0.6, ze - 0.75)), 0.045, 0.045, 1.5, 8, false)
	k.box(velours, _tr(x, 0.32, zp + s * 0.06), Vector3(1.3, 0.3, 0.04))
	k.cyl("drap", Transform3D(xf.basis * Basis(Vector3.BACK, -PI * 0.5), _p(x - 0.62, 0.62, zp + s * 1.58)), 0.06, 0.06, 1.24, 8, true)
	k.box("drap", _tr(x, 0.56, zp + s * 1.62), Vector3(1.22, 0.06, 0.18))
	# deux oreillers, ronds aux bouts
	for ex7 in [-0.27, 0.27]:
		var po: Vector3 = _p(x + ex7, 0.6, zt - s * 0.34)
		k.cyl("drap", Transform3D(xf.basis * Basis(Vector3.BACK, -PI * 0.5), po - xf.basis.x * 0.26), 0.08, 0.08, 0.52, 10, true)
	# le ciel de lit, sa frange, les pentes ; les rideaux plissés de la tête et des côtés, noués au pied
	k.box(velours, _tr(x, 2.42, zc), Vector3(1.42, 0.05, 2.2))
	k.box(velours, _tr(x, 2.12, zp), Vector3(1.42, 0.3, 0.03))
	k.box("or", _tr(x, 2.1, zp - s * 0.015), Vector3(1.44, 0.03, 0.01))
	for ex2 in [-1.0, 1.0]:
		k.box(velours, _tr(x + ex2 * 0.7, 2.12, zc), Vector3(0.03, 0.3, 2.2))
		k.box("or", _tr(x + ex2 * 0.715, 2.1, zc), Vector3(0.01, 0.03, 2.22))
		_rideau_noue(k, velours, _p(x + ex2 * 0.56, 0.0, zp + s * 0.14), 0.06, 1.05, 2.12, 0.15, 0.12)
		# les rideaux du côté de la tête, ouverts, plissés contre les colonnes
		_tenture(k, velours, _p(x + ex2 * 0.7, 2.12, zt - s * 0.1), xf.basis.z * -s, 0.35, 2.0, xf.basis.x * ex2)
	_tenture(k, velours, _p(x - 0.58, 2.12, zt - s * 0.1), xf.basis.x, 1.16, 0.9, xf.basis.z * -s)
	# la malle au pied du lit : le coffre, le couvercle, les cercles et les coins de fer, la serrure,
	# les poignées, les petits pieds
	var zm: float = zp - s * 0.32
	for ex8 in [-0.4, 0.4]:
		for ez8 in [-0.2, 0.2]:
			k.box("bois", _tr(x + ex8, 0.0, zm + ez8), Vector3(0.07, 0.04, 0.07))
	k.box("bois", _tr(x, 0.04, zm), Vector3(0.9, 0.4, 0.5), true)
	k.box("chene", _tr(x, 0.44, zm), Vector3(0.94, 0.06, 0.54))
	k.cyl("chene", Transform3D(xf.basis * Basis(Vector3.BACK, -PI * 0.5), _p(x - 0.47, 0.5, zm)), 0.2, 0.2, 0.94, 12, true)
	for ex3 in [-0.3, 0.0, 0.3]:
		k.box("fer", _tr(x + ex3, 0.035, zm), Vector3(0.045, 0.47, 0.525))
		k.cyl("fer", Transform3D(xf.basis * Basis(Vector3.BACK, -PI * 0.5), _p(x + ex3 - 0.0225, 0.5, zm)), 0.205, 0.205, 0.045, 12, false)
	for ex9 in [-1.0, 1.0]:
		for ez9 in [-1.0, 1.0]:
			k.box("fer", _tr(x + ex9 * 0.43, 0.035, zm + ez9 * 0.235), Vector3(0.06, 0.47, 0.06))
		k.box("fer", _tr(x + ex9 * 0.465, 0.26, zm), Vector3(0.02, 0.03, 0.18))
		k.box("fer", _tr(x + ex9 * 0.475, 0.23, zm - 0.07), Vector3(0.02, 0.06, 0.02))
		k.box("fer", _tr(x + ex9 * 0.475, 0.23, zm + 0.07), Vector3(0.02, 0.06, 0.02))
	k.box("or", _tr(x, 0.3, zm - s * 0.26), Vector3(0.12, 0.14, 0.015))
	k.box("suie", _tr(x, 0.33, zm - s * 0.268), Vector3(0.02, 0.05, 0.004))


## Le poêle de fonte : la plaque de pierre, les pieds, le corps, la porte rougeoyante, le tuyau
## (v11 : les pieds en griffes, le socle mouluré, les côtes de fonte, la porte à charnières et sa
## poignée de laiton, le cendrier, la plaque du dessus et sa galerie, la bouilloire de cuivre, les
## colliers du tuyau, le coude, le pare-feu)
func _poele(k: RefCounted, x: float, z: float, H: float) -> void:
	k.box("pierre_claire", _tr(x, 0.0, z), Vector3(1.4, 0.06, 1.4), true)
	k.box("pierre_claire", _tr(x, 0.0, z), Vector3(1.44, 0.03, 1.44))
	for i in range(4):
		var a: float = TAU * (i + 0.5) / 4.0
		var pp: Vector3 = _p(x + cos(a) * 0.3, 0.06, z + sin(a) * 0.3)
		k.cyl("fer", Transform3D(xf.basis, pp), 0.05, 0.03, 0.08, 8)
		k.cyl("fer", Transform3D(xf.basis, pp + Vector3(0, 0.08, 0)), 0.03, 0.045, 0.14, 8)
	# le socle, le corps et ses côtes, la ceinture, le dôme
	k.cyl("fer", _tr(x, 0.22, z), 0.46, 0.44, 0.06, 20)
	k.cyl("fer", _tr(x, 0.28, z), 0.42, 0.41, 0.86, 20, true, true)
	for c in range(12):
		var ac: float = TAU * c / 12.0 + 0.13
		if absf(wrapf(ac - PI * 0.5, -PI, PI)) < 0.55:
			continue
		k.box("fer", Transform3D(xf.basis * Basis(Vector3.UP, -ac), _p(x + cos(ac) * 0.415, 0.34, z + sin(ac) * 0.415)), Vector3(0.025, 0.74, 0.035))
	for yb in [0.34, 0.7, 1.08]:
		k.cyl("fer", _tr(x, yb, z), 0.44, 0.44, 0.03, 20, false)
	k.cyl("fer", _tr(x, 1.14, z), 0.43, 0.48, 0.04, 20)
	k.cyl("fer", _tr(x, 1.18, z), 0.48, 0.46, 0.04, 20)
	k.cyl("fer", _tr(x, 1.22, z), 0.42, 0.3, 0.1, 20)
	# la galerie du dessus : de petits balustres et leur anneau
	for g in range(16):
		var ag: float = TAU * g / 16.0
		k.cyl("fer", _tr(x + cos(ag) * 0.44, 1.22, z + sin(ag) * 0.44), 0.008, 0.008, 0.07, 4, false)
	k.cyl("fer", _tr(x, 1.29, z), 0.45, 0.45, 0.015, 20, false)
	# la bouilloire de cuivre : le corps, le couvercle et son bouton, le bec, l'anse
	var bk: Vector3 = _p(x + 0.15, 1.32, z - 0.1)
	k.cyl("cuivre_neuf", Transform3D(xf.basis, bk), 0.1, 0.13, 0.08, 14)
	k.cyl("cuivre_neuf", Transform3D(xf.basis, bk + Vector3(0, 0.08, 0)), 0.13, 0.08, 0.07, 14)
	k.cyl("cuivre_neuf", Transform3D(xf.basis, bk + Vector3(0, 0.15, 0)), 0.03, 0.01, 0.03, 8)
	_poutre(k, "cuivre_neuf", bk + xf.basis * Vector3(0.1, 0.05, 0), bk + xf.basis * Vector3(0.22, 0.13, 0), 0.025)
	_poutre(k, "fer", bk + xf.basis * Vector3(-0.07, 0.14, 0), bk + Vector3(0, 0.26, 0), 0.012)
	_poutre(k, "fer", bk + Vector3(0, 0.26, 0), bk + xf.basis * Vector3(0.07, 0.14, 0), 0.012)
	# la porte du foyer : le cadre, les vitres de mica qui rougeoient, les charnières, la poignée
	var zf: float = z + 0.4
	k.box("suie", _tr(x, 0.44, zf - 0.02), Vector3(0.36, 0.32, 0.06))
	_flamme(k, _p(x - 0.08, 0.46, zf + 0.02), 0.14, 0.24)
	_flamme(k, _p(x + 0.07, 0.46, zf + 0.02), 0.12, 0.2)
	for yb2 in [0.42, 0.76]:
		k.box("fer", _tr(x, yb2, zf + 0.02), Vector3(0.44, 0.035, 0.03))
	for xb in [-0.2, 0.0, 0.2]:
		k.box("fer", _tr(x + xb, 0.42, zf + 0.02), Vector3(0.03 if xb != 0.0 else 0.015, 0.37, 0.03))
	for yc in [0.48, 0.7]:
		k.cyl("fer", _tr(x - 0.22, yc, zf + 0.03), 0.018, 0.018, 0.05, 6)
	k.cyl("or", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x + 0.18, 0.6, zf + 0.03)), 0.012, 0.012, 0.06, 6)
	k._ball(Transform3D(xf.basis, _p(x + 0.18, 0.6, zf + 0.1)), 0.022)
	# le cendrier (un tiroir sous la porte) et sa poignée
	k.box("fer", _tr(x, 0.29, zf), Vector3(0.32, 0.08, 0.05))
	k.box("or", _tr(x, 0.32, zf + 0.03), Vector3(0.1, 0.015, 0.02))
	# le tuyau : la buse, les colliers, la porte de ramonage, le coude vers le plafond
	k.cyl("fer", _tr(x - 0.1, 1.3, z + 0.05), 0.12, 0.1, 0.08, 12)
	k.cyl("fer", _tr(x - 0.1, 1.38, z + 0.05), 0.1, 0.1, H - 1.38, 12)
	var yc2: float = 1.7
	while yc2 < H - 0.4:
		k.cyl("fer", _tr(x - 0.1, yc2, z + 0.05), 0.112, 0.112, 0.03, 12, false)
		yc2 += 0.6
	k.cyl("or", _tr(x - 0.1, 1.9, z + 0.05), 0.105, 0.105, 0.015, 12, false)
	k.cyl("fer", _tr(x - 0.1, H - 0.25, z + 0.05), 0.18, 0.18, 0.06, 12)
	k.cyl("fer", _tr(x - 0.1, H - 0.19, z + 0.05), 0.24, 0.18, 0.04, 12)
	# le pare-feu : une petite grille d'arceaux devant la porte
	for gx in range(7):
		var xg: float = -0.3 + gx * 0.1
		k.cyl("fer", _tr(x + xg, 0.06, zf + 0.22), 0.008, 0.008, 0.38, 4, false)
	k.box("fer", _tr(x, 0.42, zf + 0.22), Vector3(0.64, 0.025, 0.025))
	k.box("fer", _tr(x, 0.2, zf + 0.22), Vector3(0.64, 0.02, 0.02))


# =================================================================== la Salle Commune

func _commune(k: RefCounted, x0: float, x1: float, hw: float, H: float) -> void:
	_cheminee_c(k, 0.0, -hw, H)
	# le tapis rond, le canapé, les deux fauteuils, la table basse
	var zc: float = -hw + 3.5
	k.cyl("velours_pourpre", _tr(0.0, 0.0, zc), 2.1, 2.1, 0.02, 28)
	k.cyl("or", _tr(0.0, 0.0, zc), 2.2, 2.2, 0.012, 28)
	_canape(k, 0.0, zc + 1.9, 0.0, 2.4, "velours_pourpre")
	_canape(k, -2.1, zc, -PI * 0.5, 0.8, "velours_bleu")
	_canape(k, 2.1, zc, PI * 0.5, 0.8, "velours_vert")
	# (v11) la table basse : le plateau mouluré, la ceinture, les pieds tournés, l'entretoise
	k.box("bois", _tr(0.0, 0.4, zc), Vector3(1.2, 0.04, 0.7), true)
	k.box("chene", _tr(0.0, 0.385, zc), Vector3(1.16, 0.02, 0.66))
	k.box("chene", _tr(0.0, 0.3, zc), Vector3(1.0, 0.09, 0.5))
	for ex in [-0.5, 0.5]:
		for ez in [-0.25, 0.25]:
			_colonne_tournee(k, "chene", _tr(ex, 0.0, zc + ez), 0.39, 0.035)
	k.box("chene", _tr(0.0, 0.08, zc), Vector3(1.0, 0.03, 0.05))
	k.box("velours_bleu", _tr(-0.3, 0.44, zc + 0.1, 0.3), Vector3(0.26, 0.05, 0.34))
	k.box("velours_vert", _tr(-0.28, 0.49, zc + 0.08, 0.1), Vector3(0.24, 0.04, 0.32))
	_bougie(k, _p(0.35, 0.44, zc - 0.1), 0.2)
	# la grande table d'étude, ses chaises, ses lampes (au sud-ouest)
	_table_l(k, -7.0, 3.4, 3.8, 1.1)
	for cxs in [-8.3, -7.0, -5.7]:
		_chaise(k, cxs, 2.6, 0.0)
	for cxl in [-8.0, -6.0]:
		_lampe(k, _p(cxl, 0.8, 3.6))
	# l'échiquier, sur son guéridon (au sud-est)
	_echiquier(k, 6.5, 3.2)
	# les bibliothèques contre les murs de refend (au nord des portes)
	_rayonnage(k, _tr(x0 + 0.25, 0.0, -2.6, PI * 0.5), 4.8, 3.0, 0.45, false)
	_rayonnage(k, _tr(x1 - 0.25, 0.0, -2.6, -PI * 0.5), 4.8, 3.0, 0.45, false)
	# les bannières sur le mur du cloître, entre les baies
	_banniere(k, "banniere_bleu", _p(-5.6, H - 0.4, hw - 0.06), 1.4, 2.6, xf.basis * Vector3(0, 0, -1))
	_banniere(k, "banniere_pourpre", _p(5.6, H - 0.4, hw - 0.06), 1.4, 2.6, xf.basis * Vector3(0, 0, -1))
	# le lustre de fer à bougies
	var lc: Vector3 = _p(-4.0, H - 1.5, 0.8)
	for i in range(10):
		var a0: float = TAU * i / 10.0
		var a1: float = TAU * (i + 1) / 10.0
		var q0: Vector3 = lc + Vector3(cos(a0), 0, sin(a0)) * 0.9
		var q1: Vector3 = lc + Vector3(cos(a1), 0, sin(a1)) * 0.9
		_poutre(k, "fer", q0, q1, 0.05, Vector3.UP)
		_bougie(k, q0 + Vector3(0, 0.03, 0), 0.2)
	for i in range(3):
		var a2: float = TAU * i / 3.0
		_poutre(k, "fer", lc + Vector3(cos(a2), 0, sin(a2)) * 0.9, lc + Vector3(0, 0.8, 0), 0.025)
	_poutre(k, "fer", lc + Vector3(0, 0.8, 0), _p(-4.0, H - 0.3, 0.8), 0.035)
	_lumiere(lc - Vector3(0, 0.2, 0), 12.0, 0.7, 1.5)


## La cheminée de la Salle Commune, contre le mur nord (x au milieu, zw : la face du mur)
func _cheminee_c(k: RefCounted, x: float, zw: float, H: float) -> void:
	var d: float = 0.9                     # la saillie des jambages
	var lw: float = 3.4                    # la largeur du manteau
	for e in [-1.0, 1.0]:
		k.box("pierre_claire", _tr(x + e * (lw * 0.5 - 0.3), 0.0, zw + d * 0.5), Vector3(0.6, 1.45, d), true)
	k.box("pierre_claire", _tr(x, 1.45, zw + d * 0.5), Vector3(lw, 0.45, d + 0.1), true)
	k.box("pierre_claire", _tr(x, 1.9, zw + d * 0.5 + 0.05), Vector3(lw + 0.3, 0.1, d + 0.25))
	# la hotte, jusqu'au plafond
	var y0: float = 2.0
	var a0 := Vector3(x - lw * 0.5 + 0.1, y0, zw + d)
	var b0 := Vector3(x + lw * 0.5 - 0.1, y0, zw + d)
	var a1 := Vector3(x - 1.0, H, zw + 0.55)
	var b1 := Vector3(x + 1.0, H, zw + 0.55)
	k.quad("pierre_int", xf, a0, b0, b1, a1, Vector3(0, 0.3, 1))
	for e2 in [-1.0, 1.0]:
		var p0: Vector3 = a0 if e2 < 0 else b0
		var p1: Vector3 = a1 if e2 < 0 else b1
		k.quad("pierre_int", xf, p0, Vector3(p0.x, y0, zw), Vector3(p1.x, H, zw), p1, Vector3(e2, 0, 0))
	# le blason doré sur la hotte
	_blason(k, _tr(x, 3.1, zw + 0.78) * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3.ZERO))
	# (v11) sur le manteau : la pendule, deux chandeliers, deux vases de cuivre
	var zm: float = zw + 0.99
	k.box("chene", _tr(x, 2.0, zm), Vector3(0.34, 0.06, 0.14))
	k.box("chene", _tr(x, 2.06, zm), Vector3(0.28, 0.3, 0.12))
	k.cyl("chene", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x, 2.36, zm - 0.06)), 0.14, 0.14, 0.12, 16)
	k.cyl("or", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x, 2.25, zm + 0.055)), 0.1, 0.1, 0.012, 20)
	k.cyl("drap", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), _p(x, 2.25, zm + 0.06)), 0.085, 0.085, 0.012, 20)
	_poutre(k, "suie", _p(x, 2.25, zm + 0.075), _p(x + 0.03, 2.31, zm + 0.075), 0.008)
	_poutre(k, "suie", _p(x, 2.25, zm + 0.075), _p(x - 0.05, 2.22, zm + 0.075), 0.008)
	k._ball(Transform3D(xf.basis, _p(x, 2.52, zm)), 0.025)
	for e5 in [-1.0, 1.0]:
		var cp: Vector3 = _p(x + e5 * 1.25, 2.0, zm)
		k.cyl("or", Transform3D(xf.basis, cp), 0.06, 0.05, 0.02, 10)
		k.cyl("or", Transform3D(xf.basis, cp + Vector3(0, 0.02, 0)), 0.014, 0.012, 0.22, 8)
		k._ball(Transform3D(xf.basis, cp + Vector3(0, 0.12, 0)), 0.022)
		k.cyl("or", Transform3D(xf.basis, cp + Vector3(0, 0.24, 0)), 0.03, 0.045, 0.02, 10)
		_bougie(k, cp + Vector3(0, 0.26, 0), 0.18)
		var vp: Vector3 = _p(x + e5 * 0.7, 2.0, zm)
		k.cyl("cuivre_neuf", Transform3D(xf.basis, vp), 0.04, 0.08, 0.1, 14)
		k.cyl("cuivre_neuf", Transform3D(xf.basis, vp + Vector3(0, 0.1, 0)), 0.08, 0.035, 0.1, 14)
		k.cyl("cuivre_neuf", Transform3D(xf.basis, vp + Vector3(0, 0.2, 0)), 0.03, 0.045, 0.05, 14, false)
	# (v11) le serviteur de cheminée : le pied, la tige, le tisonnier, la pelle, la balayette
	var sp: Vector3 = _p(x + lw * 0.5 + 0.35, 0.08, zw + 1.25)
	k.cyl("fer", Transform3D(xf.basis, sp), 0.13, 0.11, 0.03, 12)
	k.cyl("fer", Transform3D(xf.basis, sp), 0.012, 0.012, 0.72, 6)
	k.cyl("or", Transform3D(xf.basis, sp + Vector3(0, 0.72, 0)), 0.025, 0.0, 0.05, 8)
	k.cyl("fer", Transform3D(xf.basis, sp + Vector3(0, 0.62, 0)), 0.09, 0.09, 0.012, 12, false)
	for o in range(3):
		var ao: float = TAU * o / 3.0
		var hp: Vector3 = sp + xf.basis * Vector3(cos(ao) * 0.085, 0.0, sin(ao) * 0.085)
		_poutre(k, "fer", hp + Vector3(0, 0.08, 0), hp + Vector3(0, 0.66, 0), 0.012)
		k._ball(Transform3D(xf.basis, hp + Vector3(0, 0.68, 0)), 0.018)
		if o == 0:
			k.box("fer", Transform3D(xf.basis, hp + Vector3(0, 0.04, 0)), Vector3(0.1, 0.1, 0.01))
		elif o == 1:
			k.cyl("suie", Transform3D(xf.basis, hp + Vector3(0, 0.03, 0)), 0.04, 0.03, 0.1, 8)
		else:
			_poutre(k, "fer", hp + Vector3(0, 0.08, 0), hp + xf.basis * Vector3(0.05, 0.03, 0), 0.012)
	# le foyer : le contrecœur, l'âtre, les chenets, les bûches, le feu
	k.box("suie", _tr(x, 0.0, zw + 0.04), Vector3(lw - 1.2, 1.45, 0.08))
	for e3 in [-1.0, 1.0]:
		k.box("suie", _tr(x + e3 * (lw * 0.5 - 0.61), 0.0, zw + d * 0.5), Vector3(0.02, 1.45, d))
	k.box("suie", _tr(x, 1.43, zw + d * 0.5), Vector3(lw - 1.2, 0.02, d))
	k.box("pierre_claire", _tr(x, 0.0, zw + 0.8), Vector3(lw + 0.6, 0.08, 1.6), true)
	for e4 in [-1.0, 1.0]:
		var cx: float = x + e4 * 0.55
		_pl(k, "fer", Vector3(cx, 0.08, zw + 0.25), Vector3(cx, 0.08, zw + 0.85), 0.05)
		_pl(k, "fer", Vector3(cx, 0.08, zw + 0.85), Vector3(cx, 0.45, zw + 0.85), 0.05)
		k.cyl("or", _tr(cx, 0.45, zw + 0.85), 0.06, 0.0, 0.1, 8)
	for j in range(3):
		var ly: float = 0.2 + (0.14 if j == 1 else 0.0)
		_pl(k, "bois", Vector3(x - 0.65, ly, zw + 0.4 + j * 0.12), Vector3(x + 0.65, ly, zw + 0.5 + j * 0.06), 0.15, Vector3.UP)
	for j2 in range(5):
		var fx: float = x + (j2 - 2) * 0.22
		_flamme(k, _p(fx, 0.25, zw + 0.5 + 0.05 * (j2 % 2)), 0.42, 0.75 - absf(j2 - 2) * 0.12)
	feu = _lumiere(_p(x, 0.9, zw + 1.6), 12.0, 1.4, 2.4)
	_ombres(feu)


## (v11) Le blason d'Ombrelac sur la hotte (le repère t : x en travers, y vers le haut, z vers la salle) :
## l'écu bleu bordé d'or, le croissant de lune, trois étoiles
func _blason(k: RefCounted, t: Transform3D) -> void:
	var pts: Array = [Vector2(-0.3, 0.4), Vector2(0.3, 0.4)]
	for i in range(9):
		var a: float = PI * 0.5 * i / 8.0
		pts.append(Vector2(0.3 * cos(a), -0.4 * sin(a)))
	for i2 in range(1, 9):
		var a2: float = PI * 0.5 + PI * 0.5 * i2 / 8.0
		pts.append(Vector2(0.3 * cos(a2), -0.4 * sin(a2)))
	for couche in [["or", 1.12, 0.015], ["velours_bleu", 1.0, 0.03]]:
		var sc: float = couche[1]
		var c := Vector3(0, 0.05, couche[2])
		for i3 in range(pts.size()):
			var p0: Vector2 = pts[i3] * sc
			var p1: Vector2 = pts[(i3 + 1) % pts.size()] * sc
			k.tri(couche[0], t, c, Vector3(p0.x, p0.y, couche[2]), Vector3(p1.x, p1.y, couche[2]), Vector3.BACK,
				Vector2(0.5, 0.5), Vector2(0.5 + p0.x, 0.5 + p0.y), Vector2(0.5 + p1.x, 0.5 + p1.y))
	var bz := Basis(Vector3.RIGHT, PI * 0.5)
	k.cyl("or", t * Transform3D(bz, Vector3(0, 0.0, 0.03)), 0.17, 0.17, 0.012, 24)
	k.cyl("velours_bleu", t * Transform3D(bz, Vector3(0.07, 0.05, 0.03)), 0.15, 0.15, 0.02, 24)
	for st in [Vector3(-0.17, 0.28, 0.035), Vector3(0.0, 0.3, 0.035), Vector3(0.17, 0.28, 0.035)]:
		k._ball(t * Transform3D(Basis.IDENTITY, st), 0.028)


## Un canapé (lg) ou un fauteuil (lg petit) : le dossier du côté z+ du repère tourné de yaw
## (v11 : les pieds tournés, les coussins de l'assise et leurs bords arrondis, le dossier capitonné
## et son boudin, les accoudoirs roulés et leurs volutes, le galon d'or)
func _canape(k: RefCounted, x: float, z: float, yaw: float, lg: float, m: String) -> void:
	var t: Transform3D = _tr(x, 0.0, z, yaw)
	var bx := Basis(Vector3.BACK, -PI * 0.5)      # y → x
	var bz := Basis(Vector3.RIGHT, PI * 0.5)      # y → z
	var W: float = lg + 0.3
	for ex in [-1.0, 1.0]:
		for ez in [-1.0, 1.0]:
			var fp := Vector3(ex * (W * 0.5 - 0.08), 0, ez * 0.34)
			k.cyl("chene", t * Transform3D(Basis.IDENTITY, fp), 0.035, 0.05, 0.06, 10)
			k.cyl("chene", t * Transform3D(Basis.IDENTITY, fp + Vector3(0, 0.06, 0)), 0.05, 0.045, 0.04, 10)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0)), Vector3(W, 0.1, 0.85), true)
	k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.19, -0.03)), Vector3(lg, 0.02, 0.8))
	# l'assise : un, deux ou trois coussins
	var n: int = 1 if lg < 1.0 else (2 if lg < 2.0 else 3)
	var cw: float = lg / n
	for i in range(n):
		var cx: float = -lg * 0.5 + cw * (i + 0.5)
		k.box(m, t * Transform3D(Basis.IDENTITY, Vector3(cx, 0.2, -0.02)), Vector3(cw - 0.02, 0.16, 0.56))
		k.cyl(m, t * Transform3D(bx, Vector3(cx - cw * 0.5 + 0.01, 0.28, -0.3)), 0.08, 0.08, cw - 0.02, 10, true)
	# le dossier capitonné, son boudin
	k.box(m, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0.32)), Vector3(W, 0.72, 0.22))
	k.cyl(m, t * Transform3D(bx, Vector3(-W * 0.5, 0.92, 0.32)), 0.11, 0.11, W, 12, true)
	var rangs: int = int(lg / 0.2)
	for r in range(3):
		for c in range(rangs + (r % 2)):
			var bxp: float = -lg * 0.5 + 0.1 + (c + (0.0 if r % 2 == 1 else 0.5)) * (lg - 0.2) / maxf(rangs, 1)
			if absf(bxp) > lg * 0.5 - 0.05:
				continue
			k.cyl("suie", t * Transform3D(bz, Vector3(bxp, 0.48 + r * 0.14, 0.198)), 0.012, 0.012, 0.008, 6)
	# les accoudoirs roulés, leurs volutes
	for e in [-1.0, 1.0]:
		var ax: float = e * (lg * 0.5 + 0.08)
		k.box(m, t * Transform3D(Basis.IDENTITY, Vector3(ax, 0.2, -0.02)), Vector3(0.16, 0.4, 0.8))
		k.cyl(m, t * Transform3D(bz, Vector3(ax + e * 0.02, 0.6, -0.42)), 0.1, 0.1, 0.72, 12, true)
		k.cyl("or", t * Transform3D(bz, Vector3(ax + e * 0.02, 0.6, -0.43)), 0.055, 0.055, 0.012, 12)
	k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.025, 0.32)), Vector3(W + 0.02, 0.012, 0.06))


## Le guéridon de l'échiquier, ses deux chaises
func _echiquier(k: RefCounted, x: float, z: float) -> void:
	k.cyl("bois", _tr(x, 0.0, z), 0.3, 0.2, 0.05, 12)
	k.cyl("bois", _tr(x, 0.05, z), 0.06, 0.06, 0.66, 8)
	k.cyl("chene", _tr(x, 0.71, z), 0.55, 0.55, 0.04, 20, true, true)
	var c: float = 0.06
	for i in range(8):
		for j in range(8):
			var m: String = "drap" if (i + j) % 2 == 0 else "suie"
			k.box(m, _tr(x + (i - 3.5) * c, 0.75, z + (j - 3.5) * c), Vector3(c, 0.006, c))
	# (v11) le cadre de l'échiquier ; les pièces : les pions, les tours, les cavaliers, les fous, les
	# rois et les dames (une partie en cours : quelques pièces avancées, d'autres prises, à côté)
	k.box("bois", _tr(x, 0.75, z - 4.15 * c), Vector3(8.6 * c, 0.012, 0.3 * c))
	k.box("bois", _tr(x, 0.75, z + 4.15 * c), Vector3(8.6 * c, 0.012, 0.3 * c))
	k.box("bois", _tr(x - 4.15 * c, 0.75, z), Vector3(0.3 * c, 0.012, 8.0 * c))
	k.box("bois", _tr(x + 4.15 * c, 0.75, z), Vector3(0.3 * c, 0.012, 8.0 * c))
	var places: Array = [
		["drap", 0, 1, 0], ["drap", 1, 1, 0], ["drap", 2, 2, 0], ["drap", 3, 3, 0], ["drap", 4, 3, 0], ["drap", 5, 1, 0], ["drap", 7, 1, 0],
		["drap", 0, 0, 1], ["drap", 5, 2, 2], ["drap", 2, 0, 3], ["drap", 3, 0, 4], ["drap", 4, 0, 5], ["drap", 7, 0, 1],
		["suie", 0, 6, 0], ["suie", 2, 6, 0], ["suie", 3, 4, 0], ["suie", 4, 5, 0], ["suie", 5, 6, 0], ["suie", 6, 6, 0], ["suie", 7, 5, 0],
		["suie", 0, 7, 1], ["suie", 2, 5, 2], ["suie", 5, 7, 3], ["suie", 3, 7, 4], ["suie", 4, 7, 5], ["suie", 7, 7, 1]]
	for pc in places:
		_piece(k, pc[0], _p(x + (pc[1] - 3.5) * c, 0.756, z + (pc[2] - 3.5) * c), pc[3])
	# les pièces prises, posées à côté du plateau
	_piece(k, "suie", _p(x + 0.33, 0.75, z - 0.3), 0)
	_piece(k, "suie", _p(x + 0.38, 0.75, z - 0.25), 2)
	_piece(k, "drap", _p(x - 0.34, 0.75, z + 0.3), 0)
	_chaise(k, x - 0.9, z, PI * 0.5)
	_chaise(k, x + 0.9, z, -PI * 0.5)

## (v11) Une pièce d'échecs posée en p : 0 le pion, 1 la tour, 2 le cavalier, 3 le fou, 4 la dame, 5 le roi
func _piece(k: RefCounted, m: String, p: Vector3, sorte: int) -> void:
	var h: float = [0.035, 0.045, 0.05, 0.055, 0.065, 0.07][sorte]
	k.cyl(m, Transform3D(xf.basis, p), 0.019, 0.017, 0.008, 10)
	k.cyl(m, Transform3D(xf.basis, p + Vector3(0, 0.008, 0)), 0.014, 0.008, h - 0.008, 10, false)
	var top: Vector3 = p + Vector3(0, h, 0)
	match sorte:
		0:
			k.cyl(m, Transform3D(xf.basis, top - Vector3(0, 0.004, 0)), 0.011, 0.011, 0.004, 8)
			k.cyl(m, Transform3D(xf.basis, top), 0.009, 0.003, 0.014, 8)
		1:
			k.cyl(m, Transform3D(xf.basis, top - Vector3(0, 0.01, 0)), 0.012, 0.014, 0.016, 8)
		2:
			k.box(m, Transform3D(xf.basis * Basis(Vector3.RIGHT, 0.5), top - Vector3(0, 0.008, 0)), Vector3(0.012, 0.028, 0.016))
		3:
			k.cyl(m, Transform3D(xf.basis, top - Vector3(0, 0.004, 0)), 0.006, 0.01, 0.01, 8)
			k.cyl(m, Transform3D(xf.basis, top + Vector3(0, 0.006, 0)), 0.01, 0.0, 0.014, 8)
		4:
			k.cyl(m, Transform3D(xf.basis, top - Vector3(0, 0.004, 0)), 0.009, 0.013, 0.01, 8)
			k.cyl(m, Transform3D(xf.basis, top + Vector3(0, 0.006, 0)), 0.006, 0.0, 0.008, 8)
		_:
			k.cyl(m, Transform3D(xf.basis, top - Vector3(0, 0.004, 0)), 0.009, 0.012, 0.01, 8)
			k.box(m, Transform3D(xf.basis, top + Vector3(0, 0.006, 0)), Vector3(0.004, 0.018, 0.004))
			k.box(m, Transform3D(xf.basis, top + Vector3(0, 0.014, 0)), Vector3(0.012, 0.004, 0.004))


# =================================================================== la tour de l'escalier

## Le dedans de la tour (repère xf_sol ; tc : son centre, ri : le rayon du dedans) : le dallage, le
## noyau, les marches de pierre en vis, la main courante, le palier de l'étage, le plafond, les
## lanternes
func _tour(k: RefCounted, tc: Vector3, ri: float, F: float, E: float, portes: Array) -> void:
	k.cyl("dalles_int", _t0(tc.x, -0.2, tc.z), ri + 0.05, ri + 0.05, 0.2, 28, true, true)
	k.cyl("pierre_claire", _t0(tc.x, 0.0, tc.z), 0.45, 0.45, E, 16, false, true)
	# le plafond (sous l'étage du dessus)
	for i in range(28):
		var a0: float = TAU * i / 28.0
		var a1: float = TAU * (i + 1) / 28.0
		k.tri("chene", xf_sol, tc + Vector3(0, E - 0.05, 0), tc + Vector3(cos(a0) * ri, E - 0.05, sin(a0) * ri), tc + Vector3(cos(a1) * ri, E - 0.05, sin(a1) * ri), Vector3.DOWN)
	var rise: float = F / MARCHES
	var da: float = deg_to_rad(PAS_ANGLE)
	var a_fin: float = _angle_porte(portes[1]) + TAU
	var a_deb: float = a_fin - MARCHES * da
	var r0: float = 0.45
	var rm: float = (r0 + ri) * 0.5
	for j in range(MARCHES):
		var a: float = a_deb + (j + 0.5) * da
		var d := Vector3(cos(a), 0, sin(a))
		var t := Vector3(-sin(a), 0, cos(a))
		var yt: float = (j + 1) * rise
		var ep: float = minf(yt, 0.3)
		var b := Basis(d, Vector3.UP, t)
		var w: float = 2.0 * ri * sin(da * 0.5) + 0.08
		k.box("pierre_claire", xf_sol * Transform3D(b, tc + d * (rm + 0.02) + Vector3(0, yt - ep, 0)), Vector3(ri - r0 + 0.04, ep, w))
		# la collision : une rampe en hélice sous le nez des marches
		var pente: float = atan2(rise, rm * da)
		var bs := BoxShape3D.new()
		bs.size = Vector3(ri - r0, 0.3, rm * da / cos(pente) + 0.12)
		var yc: float = (j + 0.5) * rise
		k.shapes.append([bs, xf_sol * Transform3D(b * Basis(Vector3.RIGHT, -pente), tc + d * rm + Vector3(0, yc, 0) - (b * Basis(Vector3.RIGHT, -pente)).y * 0.15)])
		# la main courante de fer, contre le mur
		var a2: float = a + da
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var q0: Vector3 = tc + d * (ri - 0.14) + Vector3(0, j * rise + 1.0, 0)
		var q1: Vector3 = tc + d2 * (ri - 0.14) + Vector3(0, (j + 1) * rise + 1.0, 0)
		_poutre(k, "fer", xf_sol * q0, xf_sol * q1, 0.045, xf_sol.basis * Vector3.UP)
		if j % 3 == 0:
			_poutre(k, "fer", xf_sol * (tc + d * (ri - 0.02) + Vector3(0, j * rise + 1.0, 0)), xf_sol * q0, 0.03)
	# le palier de l'étage, devant le passage
	k.box("pierre_claire", _t0(tc.x - (ri + r0) * 0.5, F - 0.3, tc.z), Vector3(ri - r0 + 0.1, 0.3, 2.0), true)
	# deux lanternes au mur
	for ld in [[deg_to_rad(30.0), 3.2], [deg_to_rad(250.0), F + 2.4]]:
		var dl := Vector3(cos(float(ld[0])), 0, sin(float(ld[0])))
		var lp: Vector3 = xf_sol * (tc + dl * (ri - 0.55) + Vector3(0, float(ld[1]), 0))
		_lanterne(k, lp)
		_poutre(k, "fer", lp + Vector3(0, 0.74, 0), xf_sol * (tc + dl * (ri - 0.55) + Vector3(0, float(ld[1]) + 0.9, 0)), 0.03)
		_poutre(k, "fer", xf_sol * (tc + dl * (ri - 0.55) + Vector3(0, float(ld[1]) + 0.9, 0)), xf_sol * (tc + dl * ri + Vector3(0, float(ld[1]) + 0.9, 0)), 0.04)
		_bougie(k, lp - Vector3(0, 0.35, 0), 0.18)
		_lumiere(lp - Vector3(0, 0.1, 0), 8.0, 0.8, 1.4)

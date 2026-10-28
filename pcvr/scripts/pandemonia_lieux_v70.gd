extends RefCounted
## V70 : les grands lieux de la Citadelle et de la Haute-Ville de Pandémonia (le reste :
## pandemonia_basse_v70.gd). Chacun bâti par le kit de la cité (braise_kit_v70), avec ses
## lieux pour les habitants (spots), ses points et ses liens dans le réseau des rues, ses
## objets (les comptoirs, les invites) :
##  - le Palais de l'Archiduchesse (la salle du trône, le perron, les tours, la grande flèche,
##    le jardin), sur la Citadelle, derrière son enceinte ;
##  - la Grand-Place des Lanternes (la fontaine de feu, la statue du Fondateur, le kiosque,
##    la mosaïque où l'on danse, les guirlandes de la fête) ;
##  - la Cathédrale-Forge du Brasier (la nef, ses forges, le Cœur-Brasier, la porte des Neuf
##    Cercles, la grande flèche, les arcs-boutants) ;
##  - la Bibliothèque des Âmes ; l'Académie Infernale (la cour, l'amphithéâtre, l'observatoire).

const R = preload("res://scripts/ile_braise_v70.gd")

var c                                    # pandemonia_v70
var kit
var coeur := {}                          # le Cœur-Brasier : {pos, fire, light, base}
var porte_cercles := Vector3.ZERO        # devant la porte des Neuf Cercles (dans la cathédrale)
var trone := Vector3.ZERO
var garlands: Array = []                 # Vector3 : les lanternes des guirlandes de la Grand-Place
var _zones: Array = []                   # [nom, Transform3D inverse, demi-taille] : les intérieurs


func setup(city) -> void:
	c = city
	kit = city.kit


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func _zone(name: String, xf: Transform3D, center: Vector3, half: Vector3) -> void:
	_zones.append([name, (xf * Transform3D(Basis(), center)).affine_inverse(), half])


## Une salle, une place : son nom si le point y est (pour la musique, les ambiances).
func zone_at(p: Vector3, _cp: Vector2) -> String:
	for z in _zones:
		var l: Vector3 = (z[1] as Transform3D) * p
		var h: Vector3 = z[2]
		if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
			return str(z[0])
	return ""


# =================================================================== le Palais

func palais() -> void:
	var y0: float = R.CIT_Y
	var py: float = 2.4
	var pf := Transform3D(Basis.looking_at(-c.radial(-45.0), Vector3.UP), c.PW(0.0, 0.0, y0))
	# le podium et son perron
	kit.box(pf * T(0, py * 0.5 - 0.3, -6.5), Vector3(32.0, py + 0.6, 37.0), "pgoth70_sombre", 2.0, 63 - 8)
	kit.col_box(pf * T(0, py * 0.5 - 0.3, -6.5), Vector3(32.0, py + 0.6, 37.0))
	kit.box(pf * T(0, py - 0.02, -6.5), Vector3(31.6, 0.06, 36.6), "palais70", 3.0, 4)
	kit.stair(pf * Vector3(0, 0.0, 19.0), pf * Vector3(0, py, 12.0), 10.0, "pgoth70", "pgoth70_sombre", 0.8, 0.5)
	for s in [-1.0, 1.0]:
		kit.parapet70(pf * Vector3(s * 16.0, py, 12.0), pf * Vector3(s * 5.6, py, 12.0), 0.9, 0.45, "mrouge70", "pgoth70_sombre")
		kit.parapet70(pf * Vector3(s * 15.8, py, 12.0), pf * Vector3(s * 15.8, py, -24.8), 0.9, 0.45, "mrouge70", "pgoth70_sombre")
		kit.lamp70(pf * Vector3(s * 6.4, 0.0, 20.0), 4.4, true, true, 0.0)
	kit.parapet70(pf * Vector3(-15.8, py, -24.8), pf * Vector3(-5.2, py, -24.8), 0.9, 0.45, "mrouge70", "pgoth70_sombre")
	kit.parapet70(pf * Vector3(5.2, py, -24.8), pf * Vector3(15.8, py, -24.8), 0.9, 0.45, "mrouge70", "pgoth70_sombre")
	# la salle du trône
	var hx: Transform3D = pf * T(0, py, 8.0)
	kit.hall70(hx, 20.0, 24.0, {"h": 13.0, "wall": "pgoth70", "inner": "mrouge70", "floor_key": "palais70", "door_w": 3.4, "door_h": 4.8,
		"roof": "cuivre70", "pitch": 50.0, "lights": 3, "energy": 2.2, "trim": "pgoth70_sombre", "light_color": Color(1.0, 0.6, 0.32)})
	kit.rose_window(hx * T(0, 10.2, 0.02), 2.0, "vitrail70_rosace", "pgoth70_sombre")
	kit.rose_window(Transform3D(hx.basis * Basis(Vector3.UP, PI), hx * Vector3(0, 10.2, -0.72)), 2.0, "vitrailin70_rosace", "mrouge70")
	_zone("braise_trone", hx, Vector3(0, 6.0, -12.0), Vector3(9.3, 6.5, 11.6))
	# dedans : le tapis, les colonnes, l'estrade, le trône
	kit.box(hx * T(0, 0.12, -9.5), Vector3(2.6, 0.04, 18.0), "tissu70_rouge", 1.0, 4 | 1 | 2 | 16 | 32)
	for s2 in [-1.0, 1.0]:
		for z in [-4.0, -10.0, -16.0]:
			kit.column(hx * T(s2 * 6.2, 0.1, z), 0.45, 12.6, "mnoir70", "or70")
		kit.banner70(Transform3D(hx.basis * Basis(Vector3.UP, -s2 * PI * 0.5), hx * Vector3(s2 * 9.27, 9.0, -7.0)), 1.2, 4.2)
		kit.banner70(Transform3D(hx.basis * Basis(Vector3.UP, -s2 * PI * 0.5), hx * Vector3(s2 * 9.27, 9.0, -17.0)), 1.2, 4.2)
	kit.box(hx * T(0, 0.35, -21.0), Vector3(9.0, 0.6, 4.4), "mrouge70", 1.4)
	kit.box(hx * T(0, 0.14, -18.5), Vector3(6.0, 0.2, 1.0), "mrouge70", 1.4)
	kit.col_box(hx * T(0, 0.35, -21.0), Vector3(9.0, 0.6, 4.4))
	var tx: Transform3D = hx * T(0, 0.65, -21.6)
	kit.box(tx * T(0, 0.25, 0), Vector3(1.5, 0.5, 1.1), "or70", 1.0)
	kit.box(tx * T(0, 0.55, 0.05), Vector3(1.3, 0.12, 0.95), "tissu70_rouge", 1.0)
	kit.box(tx * T(0, 1.75, -0.45), Vector3(1.6, 3.0, 0.24), "or70", 1.0)
	kit.box(tx * T(0, 1.6, -0.32), Vector3(1.2, 2.2, 0.04), "tissu70_rouge", 1.0)
	for s3 in [-1.0, 1.0]:
		kit.box(tx * T(s3 * 0.72, 0.85, 0.05), Vector3(0.14, 0.4, 1.0), "or70", 1.0)
		kit.horn(tx * Vector3(s3 * 0.55, 3.2, -0.45), hx.basis * Vector3(s3 * 0.6, 0.8, -0.1), 1.1, 0.12, 2.4, "or70", 6)
		kit.brazier70(tx * Vector3(s3 * 3.4, -0.65, 0.6), 1.2, "bronze70", "mnoir70", 0.55)
	kit.col_box(tx * T(0, 0.8, -0.2), Vector3(1.6, 1.6, 1.3))
	trone = tx * Vector3(0, 0.62, 0.15)
	c._spot("palais_trone", trone, hx.basis * Vector3(0, 0, 1), "assis", "pal_trone")
	c._pt("pal_trone", hx * Vector3(1.6, 0.05, -17.0))
	c._pt("pal_salle", hx * Vector3(0, 0.05, -6.0))
	c._pt("pal_entree", hx * Vector3(0, 0.05, -1.5))
	c._spot("palais_majordome", hx * Vector3(3.2, 0.05, -2.6), hx.basis * Vector3(-1, 0, 0.3), "bras_croises", "pal_entree")
	c.doors["porte_ignatia"] = c._pt("porte_ignatia", hx * Vector3(-6.0, 0.05, -19.5))
	c.doors["porte_asmodin"] = c._pt("porte_asmodin", hx * Vector3(6.0, 0.05, -19.5))
	# le perron (le « balcon » d'où l'Archiduchesse parle à sa ville)
	c._pt("pal_perron", pf * Vector3(0, py + 0.05, 10.0))
	c._spot("palais_balcon", pf * Vector3(2.0, py + 0.05, 11.2), pf.basis * Vector3(0, 0, 1), "observer", "pal_perron")
	c._pt("pal_pied", pf * Vector3(0, 0.05, 21.0))
	# les deux tours de la façade, la grande tour (le donjon) et sa flèche
	for s4 in [-1.0, 1.0]:
		var tp: Vector3 = kit.tower70(pf * Vector3(s4 * 12.6, py, 5.0), 3.2, 26.0, {"roof": "cone", "roof_key": "cuivre70", "roof_h": 13.0,
			"windows": [5.0, 10.0, 15.0, 20.0], "nwin": 3, "lit": 0.6, "wall": "pgoth70", "trim": "pgoth70_sombre"})
		kit.flag69(Transform3D(pf.basis * Basis(Vector3.UP, s4 * 0.5), tp + Vector3(0, 0.6, 0) + pf.basis * Vector3(s4 * 2.6, 0, 0)), "banniere70", Vector2(1.6, 3.2))
	var keep: Vector3 = kit.tower70(pf * Vector3(0, py, -20.4), 4.4, 34.0, {"roof": "spire", "roof_key": "cuivre70", "roof_h": 27.0,
		"windows": [8.0, 14.0, 20.0, 26.0], "nwin": 4, "lit": 0.7, "wall": "pgoth70", "trim": "pgoth70_sombre"})
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI / 4.0
		kit.gargoyle(Transform3D(Basis.looking_at(-Vector3(cos(a), 0, sin(a)), Vector3.UP), keep + Vector3(cos(a), 0, sin(a)) * 4.7 + Vector3.DOWN * 1.4), 1.2, "pgoth70_sombre")
	# l'esplanade : deux grands braseros, la statue de la première Archiduchesse
	for s5 in [-1.0, 1.0]:
		var bp: Vector3 = kit.brazier(pf * Vector3(s5 * 9.0, 0.0, 23.0), 1.4)
		kit.fires70.append([bp + Vector3.UP * 0.2, 0.7])
	for s6 in [-1.0, 1.0]:
		kit.demon_statue(Transform3D(pf.basis, pf * Vector3(s6 * 6.5, 0, 27.5)), 0.9, "obsid70")
	# l'enceinte de la Citadelle : un mur crénelé, des tours rondes, les quatre entrées ouvertes
	_enceinte()
	# le jardin du palais, derrière la grande tour
	var gx: Transform3D = pf * T(0, 0, -31.0)
	kit.ring(gx, 1.6, 2.0, 0.6, "mnoir70", 24)
	kit.disc(gx * T(0, 0.35, 0), 1.6, "lave70", 20, 1.0)
	kit.col_cyl(gx.origin, 2.0, 0.6)
	kit.fires70.append([gx * Vector3(0, 0.5, 0), 0.35])
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0
		c.tree_spots.append(gx * Vector3(cos(a2) * 7.5, 0, sin(a2) * 4.5))
	kit.bench70(Transform3D(pf.basis, gx * Vector3(0, 0, 3.2)) * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO))
	kit.bench70(Transform3D(pf.basis, gx * Vector3(-3.4, 0, -1.5)) * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO))
	c._pt("pal_jardin", gx * Vector3(1.6, 0.05, 1.8))
	c._spot("palais_jardin", gx * Vector3(0, 0.5, 3.0), pf.basis * Vector3(0, 0, -1), "assis", "pal_jardin")
	c._chain(["pal_trone", "pal_salle", "pal_entree", "pal_perron", "pal_pied"])
	c._link("porte_ignatia", "pal_trone")
	c._link("porte_asmodin", "pal_trone")
	c._avoid(c.PW(0, 0, 0), 38.0)


## L'enceinte de la Citadelle (r = 37) : un mur crénelé, quatre tours, deux tourelles et un
## grand arc à chaque entrée (le haut des escaliers des ponts).
func _enceinte() -> void:
	var y0: float = R.CIT_Y - 0.6
	var nseg: int = 64
	for k in range(nseg):
		var a0: float = 360.0 * k / nseg
		var a1: float = 360.0 * (k + 1) / nseg
		if c._near_avenue(a0, 37.0, 5.6) or c._near_avenue(a1, 37.0, 5.6):
			continue
		kit.wall_line(c.PW(a0, 37.0, y0), c.PW(a1, 37.0, y0), 5.8, 1.8, "pgoth70", true, 1.0)
	for a in [0.0, 90.0, 180.0, -90.0]:
		kit.tower70(c.PW(a, 37.4, y0), 3.0, 11.0, {"roof": "cone", "roof_h": 7.5, "windows": [5.0], "nwin": 3, "lit": 0.5})
	for av in R.AVENUES:
		var a2: float = float(av)
		for s in [-1.0, 1.0]:
			kit.tower70(c.PW(a2, 37.6, y0) + c.tangent(a2) * s * 5.6, 2.0, 10.0, {"roof": "cone", "roof_h": 6.0, "windows": [], "crown": false})
		kit.ogive_frame(c.PX(a2, 37.6, R.CIT_Y, "out"), 9.2, 10.0, 0.8, 1.6, "pgoth70", 6, true)
		kit.banner70(c.PX(a2, 37.6, R.CIT_Y + 9.2, "out") * T(0, 0, 0.9), 1.0, 2.6)
		c._pt("cit_%d" % int(a2), c.PW(a2, 33.0, R.CIT_Y + 0.05))
	c._spot("palais_porte", c.PW(-45.0, 34.6, R.CIT_Y + 0.05) + c.tangent(-45.0) * 2.8, c.radial(-45.0), "bras_croises", "cit_-45")


# =================================================================== la Grand-Place

func grand_place() -> void:
	var y: float = c.HY
	var ctr: Vector3 = c.PW(0.0, 94.0, y)
	var cx := Transform3D(Basis.looking_at(c.radial(0.0), Vector3.UP), ctr)        # +Z : vers la Citadelle
	kit.disc(Transform3D(Basis(), ctr + Vector3.UP * 0.035), 10.5, "mosaique70", 48, 7.0)
	kit.ring(Transform3D(Basis(), ctr), 10.5, 11.1, 0.07, "mnoir70", 48)
	var top: Vector3 = kit.fire_fountain(Transform3D(Basis(), ctr), 3.4)
	c.objets["fontaine_place"] = top
	# la statue du Fondateur, face à la Citadelle
	kit.demon_statue(c.PX(0.0, 110.0, y, "in"), 1.35, "bronze70", "pgoth70")
	# la Grande Lanterne de la place
	c.lanterns["place"] = kit.great_lantern(c.PW(6.0, 84.0, y))
	c._pt("pl_lanterne", c.PW(4.0, 82.0, y + 0.05))
	c._spot("place_lanterne", c.PW(4.4, 85.0, y + 0.05), (c.PW(6.0, 84.0, y) - c.PW(4.4, 85.0, y)), "observer", "pl_lanterne")
	# le kiosque à musique
	var kc: Vector3 = c.PW(-5.6, 106.0, y)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), kc), 3.4, 3.4, 0.9, "pgoth70", 8, true, 1.5)
	kit.col_cyl(kc, 3.4, 0.9)
	kit.stair(kc + c.radial(0.0) * -5.4 + Vector3.DOWN * 0.0, kc + c.radial(0.0) * -3.3 + Vector3.UP * 0.9, 2.2, "pgoth70")
	for k in range(8):
		var a: float = TAU * (k + 0.5) / 8.0
		var cp: Vector3 = kc + Vector3(cos(a) * 3.0, 0.9, sin(a) * 3.0)
		kit.cyl(Transform3D(Basis(), cp), 0.09, 0.07, 3.4, "fer70", 8)
		if absf(wrapf(a - atan2(-c.radial(0.0).z, -c.radial(0.0).x), -PI, PI)) > 0.5:
			kit.box(Transform3D(Basis(Vector3.UP, -a + PI * 0.5), kc + Vector3(cos(a + PI / 8.0) * 2.95, 1.45, sin(a + PI / 8.0) * 2.95)), Vector3(2.2, 0.06, 0.05), "fer70", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), kc + Vector3.UP * 4.3), 3.9, 0.0, 2.6, "ardoise70_pourpre", 8, false, 1.6)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), kc + Vector3.UP * 4.28), 3.9, 3.9, 0.02, "boisb70", 8, true)
	kit._finial(kc + Vector3.UP * 6.7, 0.8)
	c._pt("pl_kiosque", c.PW(-5.6, 99.6, y + 0.05))
	c._spot("place_musique", kc + Vector3.UP * 0.95 + c.radial(0.0) * 0.4, -c.radial(0.0), "violon", "pl_kiosque")
	# le fauteuil du conteur (Grand-père Ébène), au pied de la statue
	var cf: Transform3D = c.PX(6.6, 106.5, y, "in")
	kit.box(cf * T(0, 0.25, 0), Vector3(1.4, 0.5, 1.0), "pgoth70", 1.0)
	kit.box(cf * T(0, 1.0, -0.45), Vector3(1.5, 1.6, 0.25), "pgoth70", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(cf * T(s * 0.68, 0.7, -0.05), Vector3(0.2, 0.5, 0.9), "pgoth70", 1.0)
		kit.horn(cf * Vector3(s * 0.55, 1.8, -0.45), cf.basis * Vector3(s * 0.7, 0.8, 0), 0.5, 0.07, 2.0, "pgoth70", 4)
	kit.col_box(cf * T(0, 0.5, -0.1), Vector3(1.5, 1.0, 1.2))
	for k2 in range(5):
		var a2: float = -0.9 + k2 * 0.45
		kit.box(Transform3D(cf.basis, cf * Vector3(sin(a2) * 3.0, 0.22, cos(a2) * 3.0)), Vector3(0.7, 0.44, 0.7), "boisb70", 1.0)
	c._pt("pl_conteur", c.PW(5.4, 101.0, y + 0.05))
	c._spot("place_conteur", cf * Vector3(0, 0.55, 0.05), cf.basis * Vector3(0, 0, 1), "assis", "pl_conteur")
	# les bancs autour de la fontaine
	for s2 in [-1.0, 1.0]:
		var bx: Transform3D = c.XD(ctr + c.tangent(0.0) * s2 * 7.6, -c.tangent(0.0) * s2)
		kit.bench70(bx)
		c._spot("place_banc_%d" % (1 if s2 < 0 else 2), bx * Vector3(0, 0.5, 0.0), bx.basis * Vector3(0, 0, 1), "assis", "pl_n" if s2 < 0 else "pl_s")
	# les jeux des enfants (une marelle de mosaïque)
	var jx: Transform3D = c.XD(c.PW(-6.0, 86.0, y), c.tangent(0.0))
	for k3 in range(6):
		kit.box(jx * T(0, 0.04, -1.5 + k3 * 0.6), Vector3(0.55, 0.02, 0.55), "or70" if k3 % 2 == 0 else "mnoir70", 1.0, 4)
	c._pt("pl_jeux", c.PW(-4.0, 84.0, y + 0.05))
	c._spot("place_jeu_1", jx * Vector3(0, 0.05, -2.4), jx.basis * Vector3(0, 0, 1), "jouer", "pl_jeux")
	c._spot("place_jeu_2", jx * Vector3(0.4, 0.05, 2.2), jx.basis * Vector3(0, 0, -1), "jouer", "pl_jeux")
	# la piste de danse : la mosaïque
	for k4 in range(4):
		var a4: float = TAU * k4 / 4.0 + PI * 0.25
		var dp: Vector3 = ctr + Vector3(cos(a4) * 7.0, 0.05, sin(a4) * 7.0)
		c._spot("place_danse_%d" % (k4 + 1), dp, ctr - dp, "danse", "pl_n" if k4 < 2 else "pl_s")
	c._spot("place_fontaine", ctr + c.radial(0.0) * -4.3 + Vector3.UP * 0.05, c.radial(0.0), "debout", "pl_o")
	# les guirlandes de lanternes (la Nuit des Lanternes)
	var poles: Array = []
	for k5 in range(8):
		var a5: float = TAU * k5 / 8.0
		var pp: Vector3 = ctr + Vector3(cos(a5) * 15.0, 0, sin(a5) * 14.5)
		kit.cyl(Transform3D(Basis(), pp), 0.1, 0.07, 6.0, "fer70", 8)
		kit.col_cyl(pp, 0.12, 6.0)
		kit._finial(pp + Vector3.UP * 5.9, 0.6)
		poles.append(pp + Vector3.UP * 5.7)
	for k6 in range(8):
		_garland(poles[k6], poles[(k6 + 1) % 8], 0.9)
		if k6 % 2 == 0:
			_garland(poles[k6], ctr + Vector3.UP * 8.5, 0.6)
	# les maisons de la place : des deux côtés, des façades à arcades tournées vers la place
	for s3 in [-1.0, 1.0]:
		for k7 in range(4):
			var rr: float = 79.0 + k7 * 8.8 + 4.4
			var hx: Transform3D = c.PX(s3 * 9.8, rr, y, "ccw" if s3 > 0 else "cw")
			kit.house70(hx, 8.4, 6.0, {"floors": 4, "wall": ["erouge70", "pgoth70", "mrouge70", "bnoire70"][k7], "roof": "ardoise70", "gable": true,
				"shop": "", "lit": 0.7, "banner": k7 % 2 == 0, "balcony": 2, "door_x": 0.0, "gf": 4.0, "uf": 3.3, "chimney": k7 % 2 == 1, "sides": 0, "v81": true})
			kit.lamp70(hx * Vector3(4.2, 0, 1.6), 3.9, k7 % 2 == 0, false)
	# les points de la place : autour de la fontaine
	c._pt("pl_o", c.PW(0.0, 82.5, y + 0.05))
	c._pt("pl_e", c.PW(4.0, 105.0, y + 0.05))
	c._pt("pl_n", c.PW(-6.4, 94.0, y + 0.05))
	c._pt("pl_s", c.PW(6.4, 94.0, y + 0.05))
	c._chain(["pl_o", "pl_n", "pl_e", "pl_s", "pl_o"])
	c._link("pl_o", "pl_jeux")
	c._link("pl_n", "pl_kiosque")
	c._link("pl_s", "pl_conteur")
	c._link("pl_s", "pl_lanterne")
	c._link("pl_o", "pl_lanterne")
	_zone("braise_place", cx, Vector3.ZERO, Vector3(20.0, 8.0, 20.0))
	c._avoid(ctr, 22.0)


## Une guirlande de petites lanternes entre deux points (une chaînette qui pend).
func _garland(a: Vector3, b: Vector3, sag: float) -> void:
	var n: int = int(a.distance_to(b) / 1.3)
	var prev: Vector3 = a
	for i in range(1, n + 1):
		var t: float = float(i) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		kit.beam(prev, p, 0.012, "fer70")
		if i < n:
			kit.place("lanterne", Transform3D(Basis.from_scale(Vector3.ONE * 0.5), p + Vector3.DOWN * 0.35))
			garlands.append(p)
		prev = p


# =================================================================== la Cathédrale-Forge

func cathedrale() -> void:
	var y: float = c.HY
	var cf: Transform3D = c.PX(90.0, 79.0, y, "in")
	var d: float = 40.0
	var w: float = 18.0
	var h: float = 16.0
	kit.hall70(cf, w, d, {"h": h, "wall": "pgoth70", "inner": "pgoth70_clair", "floor_key": "palais70", "door_w": 4.2, "door_h": 5.8,
		"roof": "ardoise70", "pitch": 56.0, "lights": 4, "energy": 2.4, "buttresses": false, "trim": "pgoth70_sombre", "light_color": Color(1.0, 0.58, 0.3)})
	_zone("braise_cathedrale", cf, Vector3(0, h * 0.5, -d * 0.5), Vector3(w * 0.5 - 0.6, h * 0.5 + 0.5, d * 0.5 - 0.5))
	# la façade : la rose, deux tours à flèche, le parvis
	kit.rose_window(cf * T(0, 12.8, 0.02), 2.8)
	kit.rose_window(Transform3D(cf.basis * Basis(Vector3.UP, PI), cf * Vector3(0, 12.8, -0.72)), 2.8, "vitrailin70_rosace", "pgoth70")
	kit.rose_window(Transform3D(cf.basis * Basis(Vector3.UP, PI), cf * Vector3(0, 11.5, -d)), 3.0)
	kit.rose_window(cf * T(0, 11.5, -d + 0.72), 3.0, "vitrailin70_rosace", "pgoth70")
	for s in [-1.0, 1.0]:
		kit.tower70(cf * Vector3(s * 12.0, 0, -2.6), 3.7, 31.0, {"roof": "spire", "roof_key": "ardoise70", "roof_h": 25.0, "windows": [7.0, 13.0, 19.0, 25.0],
			"nwin": 3, "lit": 0.5, "wall": "pgoth70", "trim": "pgoth70_sombre"})
	# le transept (des volumes pleins, une rose au bout de chaque bras), la tour de la croisée
	for s2 in [-1.0, 1.0]:
		var tx: Transform3D = cf * Transform3D(Basis(Vector3.UP, s2 * PI * 0.5), Vector3(s2 * (w * 0.5 + 4.0), 0, -24.0))
		kit.box(tx * T(0, (h - 1.0) * 0.5, 0), Vector3(10.0, h - 1.0, 8.0), "pgoth70", 2.6, 63 - 8 - 4 - 32)
		kit.col_box(tx * T(0, (h - 1.0) * 0.5, 0), Vector3(10.0, h - 1.0, 8.0))
		kit.box(tx * T(0, h - 1.1, 0), Vector3(10.4, 0.3, 8.4), "pgoth70_sombre", 1.4)
		kit.roof_gable(tx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, h - 0.95, 0)), 8.0, 10.0, 56.0, 0.4, "ardoise70", "pgoth70")
		kit.rose_window(tx * T(0, 9.0, 4.02), 2.6)
		kit.gothic_door(tx * T(0, 0, 4.0), 2.0, 4.2, "boisb70", "pgoth70_sombre")
		for s3 in [-1.0, 1.0]:
			kit.pinnacle(tx * Vector3(s3 * 4.8, h - 1.0, 3.8), 1.0, "pgoth70")
		# la cheminée de la forge, sur chaque bras
		var chb: Vector3 = tx * Vector3(2.6, h + 2.0, -1.5)
		kit.box(Transform3D(tx.basis, chb + Vector3.UP * 5.0), Vector3(1.8, 12.0, 1.8), "bnoire70", 1.6)
		kit.box(Transform3D(tx.basis, chb + Vector3.UP * 11.1), Vector3(2.3, 0.3, 2.3), "pgoth70_sombre", 1.0)
		kit.box(Transform3D(tx.basis, chb + Vector3.UP * 11.27), Vector3(1.4, 0.04, 1.4), "braise70", 1.0, 4)
		c.smoke_spots.append(chb + Vector3.UP * 11.6)
	var cr: Vector3 = cf * Vector3(0, h + 0.2, -24.0)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), cr), 3.4, 3.4, 22.0, "pgoth70", 8, false, 2.0)
	for k in range(8):
		var a: float = TAU * (k + 0.5) / 8.0
		kit.gothic_window(Transform3D(Basis.looking_at(-Vector3(cos(a), 0, sin(a)), Vector3.UP), cr + Vector3(cos(a), 0, sin(a)) * 3.15 + Vector3.UP * 16.5), 0.9, 3.4, true, "pgoth70_sombre", true)
		kit.pinnacle(cr + Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * 3.5 + Vector3.UP * 22.0, 0.9, "pgoth70")
	kit.box(Transform3D(Basis(Vector3.UP, PI / 8.0), cr + Vector3.UP * 22.1), Vector3(6.4, 0.3, 6.4), "pgoth70_sombre", 1.4)
	kit.spire70(cr + Vector3.UP * 22.2, 3.2, 30.0, "ardoise70")
	# les arcs-boutants : des culées à pinacle, des arcs qui viennent épauler la nef
	for z in [-5.0, -11.0, -17.0, -31.0, -37.0]:
		for s4 in [-1.0, 1.0]:
			var pier: Vector3 = cf * Vector3(s4 * (w * 0.5 + 6.0), 0, z)
			kit.box(Transform3D(cf.basis, pier + Vector3.UP * 5.5), Vector3(1.4, 11.0, 1.8), "pgoth70", 2.0)
			kit.col_box(Transform3D(cf.basis, pier + Vector3.UP * 5.5), Vector3(1.4, 11.0, 1.8))
			kit.pinnacle(pier + Vector3.UP * 11.0, 1.2, "pgoth70")
			var a0: Vector3 = pier + Vector3.UP * 10.2 + cf.basis * Vector3(-s4 * 0.7, 0, 0)
			var a1: Vector3 = cf * Vector3(s4 * (w * 0.5 + 0.05), h - 1.8, z)
			_flyer(a0, a1, 1.6)
			kit.buttress(Transform3D(cf.basis * Basis(Vector3.UP, s4 * PI * 0.5), cf * Vector3(s4 * w * 0.5, 0, z)), 9.0, 1.2, 1.0, "pgoth70", false)
	# dedans : les colonnes, les arcades, les bancs
	for s5 in [-1.0, 1.0]:
		for k2 in range(7):
			var zc: float = -4.0 - k2 * 5.0
			kit.column(cf * T(s5 * 5.0, 0.1, zc), 0.55, 15.6, "pgoth70", "pgoth70_sombre")
			if k2 < 6:
				var axf: Transform3D = cf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(s5 * 5.0, 11.2, zc - 2.5))
				kit.ogive_frame(axf, 4.1, 4.2, 0.45, 0.9, "pgoth70_sombre", 4, true)
		for k3 in range(5):
			kit.bench70(Transform3D(cf.basis, cf * Vector3(s5 * 2.4, 0.1, -7.0 - k3 * 2.6)))
	# les forges des bas-côtés
	_forge(cf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.1, 0.1, -16.5)), "forge_enclume", "forge_soufflet")
	_forge(cf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-7.1, 0.1, -21.5)), "", "")
	# le Cœur-Brasier
	var hb: Transform3D = cf * T(0, 0.1, -30.0)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), hb.origin), 3.2, 3.0, 0.4, "pgoth70_sombre", 8)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), hb.origin + Vector3.UP * 0.4), 2.4, 2.2, 0.4, "pgoth70_sombre", 8)
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), hb.origin + Vector3.UP * 0.8), 1.2, 0.9, 1.3, "mnoir70", 8)
	kit.cyl(hb * T(0, 2.1, 0), 0.9, 2.7, 1.0, "bronze70", 24)
	kit.ring(hb * T(0, 3.05, 0), 2.6, 2.85, 0.12, "or70", 24)
	kit.col_cyl(hb.origin, 3.0, 3.1)
	for k4 in range(6):
		var a4: float = TAU * k4 / 6.0
		var o := Vector3(cos(a4), 0, sin(a4))
		kit.horn(hb * (o * 2.6 + Vector3.UP * 3.0), (o + Vector3.UP * 0.6).normalized(), 1.0, 0.1, 1.6, "or70", 5)
	coeur = {"pos": hb * Vector3(0, 3.2, 0), "base": hb.origin}
	c.objets["coeur_brasier"] = hb * Vector3(0, 3.2, 0)
	c._pt("cat_coeur", cf * Vector3(3.5, 0.15, -25.5))
	c._spot("forge_coeur", cf * Vector3(3.8, 0.15, -27.0), cf.basis * Vector3(-0.6, 0, -1), "observer", "cat_coeur")
	# la porte des Neuf Cercles, au fond de la nef : une porte de fer et son inscription
	var px: Transform3D = cf * T(0, 0.1, -d + 0.72)
	kit._door_geo(px, 3.4, 5.6, "fer70", "pgoth70_sombre", true)
	kit.panel(px * T(0, 7.1, 0.12), 4.4, 2.2, "fresque70_porte", "pgoth70_sombre")
	for s6 in [-1.0, 1.0]:
		kit.brazier70(px * Vector3(s6 * 2.9, 0, 1.2), 1.2, "bronze70", "pgoth70_sombre", 0.5)
	porte_cercles = px * Vector3(0, 0.05, 1.6)
	c.objets["porte_cercles"] = porte_cercles
	# le parvis et sa Grande Lanterne
	c.lanterns["forge"] = kit.great_lantern(cf * Vector3(-8.0, 0, 4.4))
	c._pt("cat_parvis", cf * Vector3(0, 0.05, 4.0))
	c._pt("cat_nef", cf * Vector3(0, 0.15, -10.0))
	c._spot("forge_parvis", cf * Vector3(4.2, 0.05, 4.4), cf.basis * Vector3(0, 0, 1), "debout", "cat_parvis")
	for s7 in [-1.0, 1.0]:
		kit.lamp70(cf * Vector3(s7 * 5.5, 0, 6.5), 4.2, true, true)
	c._chain(["cat_parvis", "cat_nef", "cat_coeur"])
	c._link("cat_nef", "cat_forge")
	c._avoid(cf * Vector3(0, 0, -d * 0.5), 32.0)


## Un arc-boutant : une volée de pierre, un peu cintrée, de la culée (a) au mur de la nef (b).
func _flyer(a: Vector3, b: Vector3, rise: float) -> void:
	var n: int = 5
	var prev: Vector3 = a
	for i in range(1, n + 1):
		var t: float = float(i) / n
		var p: Vector3 = a.lerp(b, t) + Vector3.UP * rise * sin(PI * t) * 0.5
		var m: Vector3 = (prev + p) * 0.5
		var dir: Vector3 = p - prev
		var xf := Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.RIGHT), m)
		kit.box(xf, Vector3(0.7, 0.55, dir.length() + 0.12), "pgoth70", 1.4)
		prev = p


## Une forge des bas-côtés : le foyer et sa hotte, l'enclume, le soufflet, les outils.
func _forge(xf: Transform3D, spot_anvil: String, spot_bellows: String) -> void:
	kit.box(xf * T(0, 0.5, -0.6), Vector3(2.4, 1.0, 1.4), "bnoire70", 1.2)
	kit.box(xf * T(0, 1.02, -0.6), Vector3(1.9, 0.04, 1.0), "braise70", 1.0, 4)
	kit.col_box(xf * T(0, 0.5, -0.6), Vector3(2.4, 1.0, 1.4))
	kit.frustum(xf * T(0, 2.6, -0.8), 2.8, 1.8, 0.8, 0.7, 2.0, "bnoire70", 1.2, false)
	kit.box(xf * T(0, 5.8, -0.9), Vector3(0.8, 4.4, 0.7), "bnoire70", 1.2)
	kit.fires70.append([xf * Vector3(0, 1.2, -0.6), 0.5])
	kit.anvil(xf * Vector3(0.2, 0, 1.4), xf.basis.get_euler().y + PI * 0.5)
	# le soufflet de cuir
	kit.box(Transform3D(xf.basis * Basis(Vector3.RIGHT, 0.2), xf * Vector3(-1.9, 0.75, -0.3)), Vector3(0.8, 0.3, 1.2), "cuir70", 1.0)
	kit.box(xf * T(-1.9, 0.3, -0.3), Vector3(0.1, 0.6, 0.1), "boisb70", 1.0)
	kit.beam(xf * Vector3(-1.9, 0.8, 0.3), xf * Vector3(-1.9, 1.3, 1.0), 0.05, "boisb70")
	# le râtelier d'outils
	kit.box(xf * T(1.9, 1.3, -1.2), Vector3(1.2, 0.08, 0.3), "boisb70", 1.0)
	for k in range(4):
		kit.box(xf * T(1.5 + k * 0.26, 1.0, -1.15), Vector3(0.04, 0.6, 0.04), "fer70", 1.0)
	if spot_anvil != "":
		c._pt("cat_forge", xf * Vector3(0.2, 0.05, 2.8))
		c._spot(spot_anvil, xf * Vector3(0.2, 0.05, 2.15), xf.basis * Vector3(0, 0, -1), "forger", "cat_forge")
		c._spot(spot_bellows, xf * Vector3(-1.9, 0.05, 1.45), xf.basis * Vector3(0, 0, -1), "bricoler", "cat_forge")


# =================================================================== la Bibliothèque des Âmes

func bibliotheque() -> void:
	var y: float = c.HY
	var bf: Transform3D = c.PX(180.0, 78.0, y, "in")
	var hd: Dictionary = kit.hall70(bf, 16.0, 26.0, {"h": 12.0, "wall": "bnoire70", "inner": "boisb70", "floor_key": "palais70", "door_w": 2.8, "door_h": 4.0,
		"roof": "ardoise70_pourpre", "pitch": 56.0, "lights": 3, "energy": 1.8, "trim": "pgoth70", "light_color": Color(1.0, 0.7, 0.42)})
	_zone("braise_bibliotheque", bf, Vector3(0, 6.0, -13.0), Vector3(7.4, 6.5, 12.4))
	kit.rose_window(bf * T(0, 8.6, 0.02), 1.8)
	kit.tower70(bf * Vector3(4.5, 0, -29.5), 3.4, 23.0, {"roof": "cone", "roof_h": 10.0, "windows": [6.0, 11.0, 16.0], "nwin": 3, "lit": 0.8, "wall": "bnoire70"})
	# les rayonnages le long des murs, du sol presque au plafond, et des échelles
	for s in [-1.0, 1.0]:
		for k in range(4):
			var z: float = -4.0 - k * 6.0
			var sx: Transform3D = bf * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * (8.0 - 0.7 - 0.42), 0.1, z))
			kit.bookshelf(sx * T(-1.6, 0, 0), 1.6, 5.2, 0.4)
			kit.bookshelf(sx * T(1.6, 0, 0), 1.6, 5.2, 0.4)
	for k2 in range(3):
		kit.bookshelf(bf * Transform3D(Basis(Vector3.UP, PI), Vector3(-4.0 + k2 * 4.0, 0.1, -24.8)), 3.6, 6.0, 0.45)
	# les tables de lecture et leurs lampes, le pupitre de la bibliothécaire
	for k3 in range(2):
		var tx: Transform3D = bf * T(0, 0.1, -9.0 - k3 * 7.0)
		kit.box(tx * T(0, 0.76, 0), Vector3(1.4, 0.08, 4.0), "boisb70", 1.0)
		kit.box(tx * T(0, 0.38, 0), Vector3(0.9, 0.74, 3.4), "boisb70", 1.0)
		kit.col_box(tx * T(0, 0.4, 0), Vector3(1.4, 0.8, 4.0))
		for s2 in [-1.0, 1.0]:
			kit.box(tx * T(s2 * 1.1, 0.24, 0), Vector3(0.4, 0.48, 3.6), "boisb70", 1.0)
		kit.place("lanterne", tx * T(0, 0.8, 0) * Transform3D(Basis.from_scale(Vector3.ONE * 0.6), Vector3.ZERO))
	var desk: Transform3D = bf * T(-4.2, 0.1, -20.5)
	kit.box(desk * T(0, 0.85, 0), Vector3(1.8, 0.08, 0.9), "boisb70", 1.0)
	kit.box(desk * T(0, 0.42, 0), Vector3(1.6, 0.84, 0.8), "boisb70", 1.0)
	kit.col_box(desk * T(0, 0.45, 0), Vector3(1.8, 0.9, 0.9))
	kit.box(desk * T(0.3, 0.95, 0.05), Vector3(0.5, 0.1, 0.36), "contrat70", 1.0)
	kit.box(desk * T(0, 0.22, -0.9), Vector3(0.5, 0.44, 0.5), "boisb70", 1.0)
	kit.box(desk * T(0, 0.75, -1.12), Vector3(0.5, 0.7, 0.06), "boisb70", 1.0)
	c._pt("bib_salle", bf * Vector3(0, 0.15, -6.0))
	c._pt("bib_fond", bf * Vector3(-1.8, 0.15, -18.0))
	c._spot("biblio_pupitre", desk * Vector3(0, 0.5, -0.85), desk.basis * Vector3(0, 0, 1), "lire", "bib_fond")
	c._spot("biblio_rayons", bf * Vector3(5.4, 0.15, -12.0), bf.basis * Vector3(1, 0, 0), "observer", "bib_salle")
	c._pt("bib_porte", bf * Vector3(0, 0.05, 2.5))
	c._chain(["bib_porte", "bib_salle", "bib_fond"])
	for s3 in [-1.0, 1.0]:
		kit.lamp70(bf * Vector3(s3 * 4.0, 0, 3.0), 3.9, true, false)
	c._avoid(bf * Vector3(0, 0, -14.0), 20.0)


# =================================================================== l'Académie Infernale

func academie() -> void:
	var y: float = c.HY
	var af: Transform3D = c.PX(-90.0, 76.5, y, "in")
	# le bâtiment d'entrée : un passage voûté entre deux ailes
	kit.arch_gate(af * T(0, 0, -3.0), 4.2, 5.4, 6.0, 9.8, "pgoth70")
	for s in [-1.0, 1.0]:
		kit.house70(af * T(s * 8.4, 0, 0), 9.0, 6.0, {"floors": 3, "wall": "erouge70", "roof": "ardoise70", "gable": false, "door": false, "lit": 0.7, "chimney": false, "back": true})
	kit.roof_gable(af * T(0, 9.8, -3.0), 4.8, 6.0, 50.0, 0.3, "ardoise70", "erouge70")
	kit.banner70(af * T(0, 9.4, 0.05), 1.2, 3.0)
	c.lanterns["academie"] = kit.great_lantern(af * Vector3(-7.0, 0, 4.2))
	# la cour : la fontaine, des bancs, deux arbres
	var cx: Transform3D = af * T(0, 0, -15.0)
	kit.ring(cx, 1.5, 1.9, 0.6, "mnoir70", 24)
	kit.disc(cx * T(0, 0.35, 0), 1.5, "lave70", 20, 1.0)
	kit.col_cyl(cx.origin, 1.9, 0.6)
	kit.fires70.append([cx * Vector3(0, 0.5, 0), 0.3])
	for s2 in [-1.0, 1.0]:
		kit.bench70(cx * Transform3D(Basis(Vector3.UP, s2 * PI * 0.5), Vector3(s2 * -5.0, 0, 0)))
		c.tree_spots.append(cx * Vector3(s2 * 6.5, 0, -5.5))
	c._pt("aca_porche", af * Vector3(0, 0.05, 2.5))
	c._pt("aca_passage", af * Vector3(0, 0.05, -3.0))
	c._pt("aca_cour", cx * Vector3(0, 0.05, 3.2))
	c._spot("aca_cour_1", cx * Vector3(-3.0, 0.05, 2.0), cx.basis * Vector3(1, 0, -0.4), "debout", "aca_cour")
	c._spot("aca_cour_2", cx * Vector3(5.0, 0.55, 0.0), cx.basis * Vector3(-1, 0, 0), "assis", "aca_cour")
	# les ailes de côté
	for s3 in [-1.0, 1.0]:
		kit.house70(af * Transform3D(Basis(Vector3.UP, -s3 * PI * 0.5), Vector3(s3 * 12.6, 0, -15.0)), 17.0, 5.0, {"floors": 3, "wall": "bnoire70", "roof": "ardoise70",
			"gable": false, "door_x": 0.0, "lit": 0.6, "chimney": true, "back": true})
	# l'amphithéâtre (la salle de cours), au fond de la cour
	var hx: Transform3D = af * T(0, 0, -24.0)
	kit.hall70(hx, 22.0, 12.0, {"h": 9.0, "wall": "erouge70", "inner": "boisb70", "floor_key": "boisb70", "door_w": 2.6, "door_h": 3.4,
		"roof": "ardoise70", "pitch": 54.0, "lights": 2, "energy": 1.6, "trim": "pgoth70"})
	_zone("braise_academie", hx, Vector3(0, 4.5, -6.0), Vector3(10.4, 5.0, 5.4))
	kit.box(hx * T(0, 3.2, -11.25), Vector3(7.0, 2.4, 0.08), "ardoise70", 1.0)
	kit.box(hx * T(0, 1.95, -11.2), Vector3(7.2, 0.1, 0.2), "boisb70", 1.0)
	var lect: Transform3D = hx * T(0, 0.1, -9.6)
	kit.box(lect * T(0, 0.55, 0), Vector3(0.7, 1.1, 0.5), "boisb70", 1.0)
	kit.box(Transform3D(lect.basis * Basis(Vector3.RIGHT, -0.4), lect * Vector3(0, 1.15, 0.05)), Vector3(0.8, 0.05, 0.6), "boisb70", 1.0)
	kit.col_box(lect * T(0, 0.55, 0), Vector3(0.7, 1.1, 0.5))
	for k in range(3):
		for s4 in [-1.0, 1.0]:
			var bx: Transform3D = hx * T(s4 * 3.6, 0.1, -3.0 - k * 2.0)
			kit.box(bx * T(0, 0.75, -0.45), Vector3(4.6, 0.06, 0.5), "boisb70", 1.0)
			kit.box(bx * T(0, 0.45, 0.1), Vector3(4.6, 0.08, 0.4), "boisb70", 1.0)
			kit.col_box(bx * T(0, 0.4, -0.2), Vector3(4.6, 0.8, 1.0))
	kit.bookshelf(hx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(10.3 - 0.42, 0.1, -9.0)), 3.0, 3.4, 0.4)
	kit.box(hx * T(8.4, 0.32, -8.4), Vector3(0.5, 0.44, 0.5), "boisb70", 1.0)
	c._pt("aca_salle", hx * Vector3(0, 0.15, -1.6))
	c._pt("aca_estrade", hx * Vector3(-2.0, 0.15, -8.8))
	c._spot("aca_chaire", lect * Vector3(0, 0.05, -0.7), lect.basis * Vector3(0, 0, 1), "enseigner", "aca_estrade")
	c._spot("aca_eleve_1", hx * Vector3(-3.0, 0.6, -2.6), hx.basis * Vector3(0, 0, -1), "assis", "aca_salle")
	c._spot("aca_eleve_2", hx * Vector3(3.8, 0.6, -4.6), hx.basis * Vector3(0, 0, -1), "assis", "aca_salle")
	c._spot("aca_biblio", hx * Vector3(8.4, 0.6, -8.4), hx.basis * Vector3(1, 0, 0), "lire", "aca_estrade")
	# l'observatoire
	var tp: Vector3 = af * Vector3(14.5, 0, -27.5)
	kit.tower70(tp, 3.3, 24.0, {"roof": "none", "windows": [6.0, 12.0, 18.0], "nwin": 3, "lit": 0.6, "wall": "pgoth70",
		"door_dir": (af.basis * Vector3(-1, 0, 1)).normalized()})
	kit.telescope(Transform3D(Basis(), tp + Vector3.UP * 24.92), 0.7)
	c._pt("aca_tour_pied", tp + (af.basis * Vector3(-1, 0, 1)).normalized() * 5.2 + Vector3.UP * 0.05)
	c._spot("aca_tour", tp + (af.basis * Vector3(-1, 0, 1)).normalized() * 4.4 + Vector3.UP * 0.05, (af.basis * Vector3(0.3, 0, -1)), "observer", "aca_tour_pied")
	c._chain(["aca_porche", "aca_passage", "aca_cour", "aca_salle", "aca_estrade"])
	c._link("aca_cour", "aca_tour_pied")
	c._avoid(af * Vector3(0, 0, -16.0), 24.0)


# =================================================================== le réseau

## Les grands lieux rejoignent les rues.
func link_graph() -> void:
	# le palais : le pied du perron rejoint l'entrée de la Citadelle (le haut de l'escalier du port)
	c._link("pal_pied", "cit_-45")
	for av in R.AVENUES:
		var nm: String = "av%d" % int(float(av))
		c._link("cit_%d" % int(float(av)), nm + "_cit")
		c._link("pal_pied", "cit_%d" % int(float(av)))
	c._link("pal_jardin", "cit_135")
	c._link("pal_jardin", "cit_-135")
	# la Grand-Place
	c._link("pl_o", c.nearest_ring("hi", 0.0))
	c._link("pl_e", c.nearest_ring("ho", 0.0))
	c._link("pl_n", c.nearest_ring("ho", -22.5))
	c._link("pl_s", c.nearest_ring("ho", 22.5))
	# la cathédrale, la bibliothèque, l'académie : leur porte sur le boulevard
	c._link("cat_parvis", c.nearest_ring("hi", 90.0))
	c._link("bib_porte", c.nearest_ring("hi", 180.0))
	c._link("aca_porche", c.nearest_ring("hi", -90.0))

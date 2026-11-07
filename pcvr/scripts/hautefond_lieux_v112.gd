extends RefCounted
## V112 : les grands lieux de Hautefond (posés par hautefond_ville_v112, avec son kit) :
##  - la Place de la Colonne : la fontaine de Dame Ysolde, la Première Liftière (sa statue de bronze
##    vert-de-gris lève une lanterne qui s'allume la nuit), les bancs, les réverbères ; le hall de la
##    Grande Colonne (hautefond_colonne_v112) et son guichet ;
##  - la Haute-Ville : l'Observatoire (une tour ronde, sa coupole fendue, la grande lunette sur la
##    terrasse), l'Hôtel de Ville (son beffroi et sa grande horloge), la Bibliothèque des Cartes ;
##  - la Ville-Moyenne : le Grand Marché (les étals sous leurs toiles, la fontaine aux engrenages), la
##    taverne « Le Piston Joyeux » (sa machine à chocolat qui siffle), le Mât des dirigeables (une
##    tour de fer, « l'Albatros » amarré à son sommet) ;
##  - la Basse-Ville : la Forge à vapeur (le marteau-pilon), le lavoir.
## Chaque lieu pose ses points (réseau des rues), ses spots (habitants) et ses zones (le carnet).

const R = preload("res://scripts/ile_hautefond_v112.gd")

var c                                    # hautefond_ville_v112
var kit
var statue_lantern := Vector3.ZERO       # la lanterne de Dame Ysolde (elle luit la nuit)
var airship: Node3D                      # l'Albatros, amarré au mât (il se balance)
var airship_base := Transform3D.IDENTITY
var steam_hammer: Node3D                 # le marteau-pilon de la forge (il frappe)
var hammer_base := Vector3.ZERO
var whistle_at := Vector3.ZERO           # la machine à chocolat (elle siffle)
var _zones: Array = []
var _links: Array = []


func setup(city) -> void:
	c = city
	kit = city.kit


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func _zone(name: String, xf: Transform3D, center: Vector3, half: Vector3) -> void:
	_zones.append([name, (xf * Transform3D(Basis(), center)).affine_inverse(), half])


func zone_at(p: Vector3) -> String:
	for i in range(_zones.size() - 1, -1, -1):
		var z: Array = _zones[i]
		var l: Vector3 = (z[1] as Transform3D) * p
		var h: Vector3 = z[2]
		if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
			return str(z[0])
	return ""


func _ring_link(pt: String, ring: String, deg: float) -> void:
	_links.append([pt, ring, deg])


func link_graph() -> void:
	for l in _links:
		var near: String = c.nearest_ring(str(l[1]), float(l[2]))
		if near != "":
			c._link(str(l[0]), near)


## Le haut d'une rampe de la Place : relié au point de la Place le plus proche.
func core_link(ramp_top: String, deg: float) -> void:
	var best: String = ""
	var bd: float = INF
	for k in range(12):
		var nm: String = "co_%d" % k
		if not c.points.has(nm):
			continue
		var d: float = absf(R._adiff(30.0 * k, deg))
		if d < bd:
			bd = d
			best = nm
	var inner: String = c._pt(ramp_top + "_place", c.PW(deg, R.CORE_R - 4.0, R.CORE_Y + 0.05))
	c._link(ramp_top, inner)
	if best != "":
		c._link(inner, best)


# =================================================================== la Place de la Colonne

func place_colonne() -> void:
	var y: float = R.CORE_Y
	var col = c.colonne
	# la fontaine de Dame Ysolde, au sud du socle
	var fc: Vector3 = c.PW(90.0, 26.5, y)
	_fontaine(fc)
	c._avoid(fc, 6.0)
	# le cercle des points de la Place (sauf devant la fontaine)
	for k in range(12):
		var a: float = 30.0 * k
		if absf(R._adiff(a, 90.0)) < 16.0:
			continue
		c._pt("co_%d" % k, c.PW(a, 26.0, y + 0.05))
	for k2 in range(12):
		c._link("co_%d" % k2, "co_%d" % ((k2 + 1) % 12))
	c._pt("co_fontaine_e", c.PW(68.0, 28.5, y + 0.05))
	c._pt("co_fontaine_o", c.PW(112.0, 28.5, y + 0.05))
	c._chain(["co_2", "co_fontaine_e", "co_fontaine_o", "co_4"])
	# le hall de la Colonne : ses portails, le guichet, la cabine
	for nm in col.hall_points:
		c._pt(str(nm), col.hall_points[nm])
	for k3 in range(4):
		var a3: float = 90.0 * k3
		var cok: String = "co_%d" % (int(round(a3 / 30.0)) % 12)
		if not c.points.has(cok):
			cok = "co_fontaine_e"
		c._chain([cok, "hall_portail_%d" % k3, "hall_dedans_%d" % k3, "hall_milieu"])
	c._chain(["hall_dedans_1", "hall_guichet", "hall_derriere"])
	c._link("hall_sud", "co_fontaine_e")
	c._link("hall_sud", "co_fontaine_o")
	c._link("hall_sud", "hall_portail_1")
	c._link("hall_porte", "hall_dedans_1")
	# la cabine (les habitants y montent : voir hautefond_v112._npc_lift)
	c._pt("cab_bas", col.foot + Vector3.UP * 0.07)
	c._pt("cab_haut", col.top + Vector3.UP * 0.05)
	c._pt("belv_porte", col.top + Vector3(0, 0.05, 4.4))
	c._chain(["hall_milieu", "cab_bas", "cab_haut", "belv_porte"])
	for i in range(col.belv_spots.size()):
		var bsp: Array = col.belv_spots[i]
		var bp: String = c._pt("belv_%d" % i, (bsp[0] as Vector3) - (bsp[1] as Vector3) * 1.6)
		c._chain(["belv_porte", bp])
		if i < 2:
			c._spot("belvedere_%d" % (i + 1), bsp[0], bsp[1], "observer", bp)
	c._spot("colonne_guichet", col.guichet_staff + Vector3.UP * 0.05, Vector3(-1, 0, 0), "comptoir", "hall_derriere")
	c._spot("colonne_cabine", col.cabine_spot, Vector3(0, 0, 1), "bras_croises", "hall_milieu")
	c.objets["guichet_liftiers"] = col.guichet
	c._spot("place_fontaine", fc + c.radial(75.0) * 0.0 + Vector3(0, 0.05, 0) + (c.PW(68.0, 28.5, y) - fc).normalized() * 6.2, (fc - c.PW(68.0, 28.5, y)).normalized(), "debout", "co_fontaine_e")
	# les bancs autour de la Place, face à la Colonne
	var benches := [20.0, 160.0, -40.0, -140.0]
	for i2 in range(benches.size()):
		var ab: float = float(benches[i2])
		var bx: Transform3D = c.PX(ab, 31.2, y, "in")
		kit.bench112(bx)
		c._spot("place_banc_%d" % (i2 + 1), bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "co_%d" % int(posmod(int(round(ab / 30.0)), 12)))
	# des réverbères, des arbres en bacs
	for k4 in range(16):
		var al: float = 22.5 * k4 + 11.25
		if absf(R._adiff(al, 70.0)) < 8.0 or absf(R._adiff(al, 110.0)) < 8.0 or absf(R._adiff(al, -160.0)) < 8.0 or absf(R._adiff(al, -20.0)) < 8.0:
			continue
		if k4 % 2 == 0:
			kit.globe_lamp112(c.PW(al, 33.0, y), deg_to_rad(-al), 4.2, true)
		else:
			_planter(c.PW(al, 32.6, y))
	# les panneaux des deux lignes fermées, devant les portails est et ouest
	for s in [1.0, -1.0]:
		var pp: Vector3 = col.foot + Vector3(s * (col.R_SOCLE + 3.2), 0, 1.6)
		var px := Transform3D(Basis(Vector3.UP, s * PI * 0.5), pp)
		for x in [-0.9, 0.9]:
			kit.box(px * T(x, 1.0, 0), Vector3(0.1, 2.0, 0.1), "acier112", 1.0)
		kit.plaque112(px * T(0, 1.6, 0), "liftiers", 1.8)
		kit.box(px * T(0, 1.05, 0.02), Vector3(1.9, 0.08, 0.1), "tissu112_rouge", 1.0)
		kit.col_box(px * T(0, 1.0, 0), Vector3(2.0, 2.0, 0.2))
	_zone("hf_colonne", Transform3D(Basis(), c.PW(0.0, 0.0, y)), Vector3(0, 3.0, 0), Vector3(R.CORE_R, 6.0, R.CORE_R))


## Un grand bac de pierre et son arbre (planté par la flore de la ville).
func _planter(p: Vector3) -> void:
	kit.box(Transform3D(Basis(), p + Vector3.UP * 0.35), Vector3(1.6, 0.7, 1.6), "pierre112_clair", 1.0)
	kit.box(Transform3D(Basis(), p + Vector3.UP * 0.66), Vector3(1.4, 0.06, 1.4), "terre71", 1.0)
	kit.col_box(Transform3D(Basis(), p + Vector3.UP * 0.35), Vector3(1.6, 0.7, 1.6))
	c.tree_spots.append(p + Vector3.UP * 0.66)


## La fontaine de Dame Ysolde : le bassin, l'eau, le piédestal à engrenages, la statue de bronze
## vert-de-gris (une femme en robe longue, la main gauche levant une lanterne).
func _fontaine(fc: Vector3) -> void:
	var xf := Transform3D(Basis(), fc)
	var r: float = 4.6
	kit.ring(xf, r - 0.45, r, 0.8, "pierre112_clair", 40)
	kit.ring(xf * T(0, 0.8, 0), r - 0.55, r + 0.1, 0.14, "pierre112", 40)
	kit.disc(xf * T(0, 0.58, 0), r - 0.45, "eau112", 40, 3.0)
	kit.disc(xf * T(0, 0.05, 0), r - 0.45, "pave112", 24, 2.0)
	kit.col_cyl(fc, r, 0.9)
	kit.col_cyl(fc, 1.3, 5.2)
	# le piédestal : un fût octogonal, des bagues de laiton, quatre engrenages, quatre becs d'eau
	kit.cyl(xf, 1.4, 1.2, 0.9, "pierre112_clair", 8)
	kit.cyl(xf * T(0, 0.9, 0), 1.0, 0.9, 2.2, "pierre112", 8)
	kit.cyl(xf * T(0, 3.1, 0), 1.25, 1.25, 0.25, "pierre112_clair", 8)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		kit.gear112(Transform3D(Basis.looking_at(-d, Vector3.UP), fc + d * 0.97 + Vector3.UP * 2.0), 0.42, 10, 0.08, "laiton112")
		kit.cyl(Transform3D(Basis.looking_at(-d, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5 - 0.3), fc + d * 0.95 + Vector3.UP * 1.2), 0.08, 0.06, 0.6, "laiton112", 6)
	# la statue (2,6 m), de bronze patiné : une femme en long manteau, capuche rabattue, qui s'appuie
	# sur un grand bâton de liftière (une lanterne pend à sa crosse) ; à ses pieds, la poulie et le
	# panier de la toute première cabine
	var sx: Transform3D = xf * T(0, 3.35, 0)
	var br: String = "bronze112"
	kit.cyl(sx, 0.62, 0.34, 1.45, br, 14)
	kit.cyl(sx * T(0, 1.45, 0), 0.34, 0.3, 0.6, br, 12)
	kit.cyl(sx * T(0, 2.05, 0), 0.3, 0.2, 0.18, br, 12)
	kit.ball(sx * T(0, 2.36, 0.03), 0.18, br, 12, 6)
	kit.cyl(sx * T(0, 2.18, -0.05), 0.27, 0.06, 0.55, br, 12)
	kit.box(sx * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 1.3, -0.33)), Vector3(0.8, 1.9, 0.08), br, 1.0)
	# le bras droit sur le bâton ; le bâton, sa crosse, la lanterne
	kit.beam(sx * Vector3(0.3, 1.95, 0.05), sx * Vector3(0.48, 1.5, 0.28), 0.1, br)
	kit.beam(sx * Vector3(0.52, -0.05, 0.32), sx * Vector3(0.52, 3.1, 0.32), 0.06, br)
	kit.beam(sx * Vector3(0.52, 3.1, 0.32), sx * Vector3(0.82, 3.25, 0.32), 0.05, br)
	kit.beam(sx * Vector3(0.82, 3.25, 0.32), sx * Vector3(0.86, 2.95, 0.32), 0.035, br)
	var lp: Vector3 = sx * Vector3(0.86, 2.72, 0.32)
	kit.cyl(Transform3D(Basis(), lp + Vector3.UP * 0.16), 0.13, 0.04, 0.1, "laiton112_vieux", 8)
	kit.ball(Transform3D(Basis(), lp), 0.12, "lampe112", 10, 6)
	kit.cyl(Transform3D(Basis(), lp + Vector3.DOWN * 0.17), 0.04, 0.09, 0.05, "laiton112_vieux", 8)
	statue_lantern = lp
	# le bras gauche tient la corde de la poulie ; la poulie et le panier, au pied
	kit.beam(sx * Vector3(-0.3, 1.95, 0.05), sx * Vector3(-0.46, 1.4, 0.22), 0.1, br)
	kit.gear112(sx * Transform3D(Basis(Vector3.UP, -0.6), Vector3(-0.62, 0.55, 0.25)), 0.36, 10, 0.08, br)
	kit.beam(sx * Vector3(-0.46, 1.4, 0.22), sx * Vector3(-0.62, 0.55, 0.25), 0.02, "laiton112_vieux")
	kit.cyl(sx * T(-0.35, -0.02, 0.48), 0.24, 0.3, 0.32, br, 10)
	# l'inscription, sur une plaque de laiton au pied
	kit.box(Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), fc + Vector3(0, 1.5, 1.42)), Vector3(1.0, 0.45, 0.04), "laiton112_vieux", 1.0)


# =================================================================== la Haute-Ville

## L'Observatoire : une tour ronde de pierre blonde, sa coupole de cuivre fendue d'où sort la grande
## lunette ; sur sa terrasse (côté rue), la lunette des visiteurs et le bureau du professeur.
func observatoire() -> void:
	var y: float = R.HAUTE_Y
	var a: float = -55.0
	var oc: Vector3 = c.PW(a, 60.0, y)
	var rr: float = 8.0
	kit.cyl(Transform3D(Basis(), oc + Vector3.DOWN * 0.5), rr + 0.3, rr + 0.2, 1.4, "pierre112_sombre", 32)
	kit.cyl(Transform3D(Basis(), oc), rr, rr, 9.0, "pierre112", 32, false, 3.0)
	kit.col_cyl(oc, rr, 9.0)
	for k in range(3):
		kit.ring(Transform3D(Basis(), oc + Vector3.UP * (3.0 + k * 3.0 - 0.1)), rr - 0.05, rr + 0.18, 0.22, "pierre112_clair", 32)
	kit.ring(Transform3D(Basis(), oc + Vector3.UP * 8.8), rr - 0.2, rr + 0.5, 0.4, "pierre112_clair", 32)
	# la coupole, sa fente, la lunette qui en sort
	kit.dome76(Transform3D(Basis(), oc + Vector3.UP * 9.2), rr + 0.2, rr * 0.9, "verdigris112", 32, 10)
	var slit_dir: Vector3 = c.radial(a + 180.0)
	for i in range(6):
		var t0: float = float(i) / 6.0
		var ang: float = t0 * PI * 0.45
		var p: Vector3 = oc + Vector3.UP * (9.2 + sin(ang) * rr * 0.9) + slit_dir * cos(ang) * (rr + 0.25)
		kit.box(Transform3D(Basis.looking_at(-slit_dir, Vector3.UP), p), Vector3(1.6, 1.2, 0.2), "acier112", 1.0)
	var tube_base: Vector3 = oc + Vector3.UP * 11.5
	var tube_dir: Vector3 = (slit_dir + Vector3.UP * 1.3).normalized()
	kit.cyl(Transform3D(Basis.looking_at(tube_dir, Vector3.FORWARD if absf(tube_dir.y) < 0.99 else Vector3.RIGHT) * Basis(Vector3.RIGHT, -PI * 0.5), tube_base), 0.7, 0.55, 9.0, "laiton112", 16)
	kit.ball(Transform3D(Basis(), oc + Vector3.UP * (9.2 + rr * 0.9)), 0.4, "laiton112", 8, 4)
	# les fenêtres en meurtrières allumées, la porte (face à la rue), l'enseigne
	var to_street: Vector3 = -c.radial(a)
	for k2 in range(10):
		var aw: float = TAU * k2 / 10.0
		var dw := Vector3(cos(aw), 0, sin(aw))
		if dw.dot(to_street) > 0.85:
			continue
		kit.window112(Transform3D(Basis.looking_at(-dw, Vector3.UP), oc + dw * (rr + 0.02) + Vector3.UP * 5.6), true, true)
	var dx := Transform3D(Basis.looking_at(-to_street, Vector3.UP), oc + to_street * (rr + 0.02))
	kit.door71(dx, "bois112")
	kit.box(dx * T(0, 2.75, 0.08), Vector3(1.9, 0.3, 0.16), "pierre112_clair", 1.0)
	kit.plaque112(dx * T(0, 4.2, 0.05), "observatoire", 2.8)
	# la terrasse : un dallage, la lunette des visiteurs sur trépied, le bureau sous un auvent
	var tp: Vector3 = oc + to_street * (rr + 4.0)
	var tx := Transform3D(Basis.looking_at(to_street, Vector3.UP), tp)
	var side: Vector3 = to_street.cross(Vector3.UP)
	var lun: Vector3 = tp + side * 3.0
	for k3 in range(3):
		var al: float = TAU * k3 / 3.0
		kit.beam(lun + Vector3(cos(al), 0, sin(al)) * 0.6, lun + Vector3.UP * 1.3, 0.05, "bois112")
	kit.cyl(Transform3D(Basis.looking_at((to_street + Vector3.UP * 1.6).normalized(), Vector3.FORWARD) * Basis(Vector3.RIGHT, -PI * 0.5), lun + Vector3.UP * 1.3 - (to_street + Vector3.UP * 1.6).normalized() * 0.7), 0.14, 0.1, 1.8, "laiton112", 12)
	kit.col_cyl(lun, 0.6, 1.6)
	var desk: Vector3 = tp - side * 3.2
	var dkx := Transform3D(Basis.looking_at(side, Vector3.UP), desk)
	kit.box(dkx * T(0, 0.75, 0), Vector3(1.8, 0.08, 0.9), "bois112", 1.0)
	for e in [[-0.8, -0.35], [0.8, -0.35], [-0.8, 0.35], [0.8, 0.35]]:
		kit.box(dkx * T(float(e[0]), 0.37, float(e[1])), Vector3(0.08, 0.74, 0.08), "bois112", 1.0)
	kit.col_box(dkx * T(0, 0.4, 0), Vector3(1.8, 0.8, 0.9))
	kit.ball(dkx * T(0.5, 1.05, 0), 0.22, "tissu112_bleu", 10, 6)
	kit.box(dkx * T(-0.3, 0.84, 0.1), Vector3(0.5, 0.1, 0.36), "tissu112_rouge", 1.0)
	kit.umbrella(Transform3D(Basis(), desk + Vector3.UP * 2.6), 1.8, 0.4, "bleu")
	c._pt("obs_terrasse", tp + Vector3.UP * 0.05)
	c._pt("obs_porte", oc + to_street * (rr + 1.5) + Vector3.UP * 0.05)
	c._chain(["obs_porte", "obs_terrasse"])
	_ring_link("obs_terrasse", "hi", a)
	c._spot("observatoire_lunette", lun - to_street * 0.9 + Vector3.UP * 0.05, to_street, "observer", "obs_terrasse")
	c._spot("observatoire_bureau", dkx * Vector3(0, 0.05, -1.0), side, "lire", "obs_terrasse")
	c.doors["porte_octave_obs"] = c._pt("porte_octave_obs", oc + to_street * (rr + 1.0) + Vector3.UP * 0.05)
	c._link("porte_octave_obs", "obs_porte")
	# V116 : on entre dans l'Observatoire (maisons_v81, lieux_hautefond_v116)
	c.portes116["hf_observatoire"] = [oc + to_street * (rr + 0.9) + Vector3.UP * 0.05, to_street]
	c._avoid(oc, rr + 5.0)
	_zone("hf_observatoire", Transform3D(Basis(), oc), Vector3(0, 5.0, 0), Vector3(rr + 6.0, 9.0, rr + 6.0))


## L'Hôtel de Ville : une grande salle de pierre blonde, son perron, son beffroi à horloge.
func mairie() -> void:
	var y: float = R.HAUTE_Y
	var a: float = 82.0
	var fx: Transform3D = c.PX(a, 54.0, y, "in")
	var w: float = 20.0
	var d: float = 14.0
	c.cadres116["mairie"] = fx
	var info: Dictionary = kit.hall71(fx, w, d, {"h": 8.0, "wall": "pierre112", "inner": "enduit71_creme", "floor_key": "pave112", "door_w": 2.6, "door_h": 3.6,
		"roof": "ardoise112", "pitch": 42.0, "lights": 3, "energy": 2.0, "front_windows": [-6.5, -3.5, 3.5, 6.5], "base": "pierre112_sombre", "timber": false})
	_zone("hf_mairie", fx, Vector3(0, 4.0, -d * 0.5), Vector3(w * 0.5 - 0.6, 4.2, d * 0.5 - 0.5))
	# la corniche, les pilastres, le perron, le fronton, le blason
	kit.box(fx * T(0, 8.25, -d * 0.5), Vector3(w + 0.6, 0.4, d + 0.6), "pierre112_clair", 1.2)
	for x in [-9.6, -5.0, 5.0, 9.6]:
		kit.box(fx * T(x, 4.0, 0.12), Vector3(0.7, 8.0, 0.25), "pierre112_clair", 1.2)
	kit.box(fx * T(0, 0.15, 1.2), Vector3(7.0, 0.3, 2.4), "pierre112_clair", 1.0)
	kit.box(fx * T(0, 0.08, 2.6), Vector3(8.0, 0.16, 1.0), "pierre112_clair", 1.0)
	kit.plaque112(fx * T(0, 5.4, 0.05), "mairie", 3.4)
	# le balcon d'honneur au-dessus de la porte
	kit.balcony70(fx * T(0, 4.6, 0.0), 5.0, 1.2)
	kit.window112(fx * T(0, 6.0, 0.0), true)
	# le beffroi : une tour carrée sur la façade, sa grande horloge, son campanile d'ardoise
	var bx: Transform3D = fx * T(0, 8.4, -3.0)
	kit.box(bx * T(0, 4.5, 0), Vector3(4.6, 9.0, 4.6), "pierre112", 2.4)
	kit.box(bx * T(0, 9.1, 0), Vector3(5.2, 0.4, 5.2), "pierre112_clair", 1.2)
	for k in range(4):
		var rot := Basis(Vector3.UP, PI * 0.5 * k)
		kit.clock112(Transform3D(bx.basis * rot, bx * (rot * Vector3(0, 6.2, 2.32))), 1.5)
	var cx: Transform3D = bx * T(0, 9.3, 0)
	for e in [[-1.8, -1.8], [1.8, -1.8], [-1.8, 1.8], [1.8, 1.8]]:
		kit.box(cx * T(float(e[0]), 1.6, float(e[1])), Vector3(0.5, 3.2, 0.5), "pierre112_clair", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI), cx * Vector3(0, 2.7, 0)), 0.5, 0.75, 0.9, "laiton112", 14)
	kit.roof_hip(cx * T(0, 3.2, 0), 4.6, 4.6, 64.0, 0.25, "ardoise112")
	kit.cyl(Transform3D(Basis(), cx * Vector3(0, 7.4, 0)), 0.08, 0.02, 2.2, "or112", 6)
	kit.flag69(cx * T(0, 8.4, 0) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), "banniere112", Vector2(2.4, 1.2))
	# dedans : le bureau du Bourgmestre (une grande table, un fauteuil), des bannières
	var dk: Transform3D = fx * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -d + 3.0))
	kit.box(dk * T(0, 0.8, 0), Vector3(3.2, 0.1, 1.4), "bois112", 1.0)
	for e2 in [[-1.4, -0.6], [1.4, -0.6], [-1.4, 0.6], [1.4, 0.6]]:
		kit.box(dk * T(float(e2[0]), 0.4, float(e2[1])), Vector3(0.12, 0.8, 0.12), "bois112", 1.0)
	kit.col_box(dk * T(0, 0.45, 0), Vector3(3.2, 0.9, 1.4))
	kit.box(dk * T(0, 0.55, -1.3), Vector3(0.9, 1.1, 0.8), "tissu112_rouge", 1.0)
	for s in [-1.0, 1.0]:
		kit.banner70(fx * Transform3D(Basis(Vector3.UP, PI), Vector3(s * 5.5, 6.2, -d + 0.65)), 1.4, 3.4, "banniere112")
	c._pt("mairie_dehors", fx * Vector3(0, 0.05, 4.0))
	c._pt("mairie_entree", fx * Vector3(0, 0.05, -1.5))
	c._pt("mairie_salle", fx * Vector3(0, 0.05, -d * 0.5))
	c._pt("mairie_bureau_pt", dk * Vector3(2.4, 0.05, -1.4))
	c._chain(["mairie_dehors", "mairie_entree", "mairie_salle", "mairie_bureau_pt"])
	_ring_link("mairie_dehors", "hi", a)
	c._spot("mairie_bureau", dk * Vector3(0, 0.05, -1.3), dk.basis * Vector3(0, 0, 1), "assis", "mairie_bureau_pt")
	c._spot("mairie_balcon", fx * Vector3(1.6, 0.35, 1.6), fx.basis * Vector3(0, 0, 1), "observer", "mairie_dehors")
	c.doors["porte_hector_mairie"] = c._pt("porte_hector_mairie", fx * Vector3(-7.0, 0.05, -d + 1.5))
	c._link("porte_hector_mairie", "mairie_salle")
	# V116 : au fond de la grande salle, la petite porte de l'escalier du beffroi (on y monte)
	kit.door71(fx * T(6.5, 0.1, -d + 0.62), "bois112")
	kit.box(fx * T(6.5, 2.95, -d + 0.66), Vector3(1.5, 0.14, 0.12), "pierre112_clair", 1.0)
	c.portes116["hf_beffroi"] = [fx * Vector3(6.5, 0.15, -d + 1.3), fx.basis * Vector3(0, 0, 1)]
	c._avoid(fx * Vector3(0, 0, -d * 0.5), 13.0)


## La Bibliothèque des Cartes : une grande salle aux hautes fenêtres, des rayonnages jusqu'au
## plafond, des tables de lecture, un grand globe ; le bureau de Mademoiselle Feuillet.
func bibliotheque() -> void:
	var y: float = R.HAUTE_Y
	var a: float = 140.0
	var fx: Transform3D = c.PX(a, 54.0, y, "in")
	var w: float = 16.0
	var d: float = 14.0
	c.cadres116["bibliotheque"] = fx
	kit.hall71(fx, w, d, {"h": 8.5, "wall": "pierre112_chaud", "inner": "enduit71_creme", "floor_key": "planches71", "door_w": 2.2, "door_h": 3.4,
		"roof": "ardoise112", "pitch": 46.0, "lights": 3, "energy": 1.7, "front_windows": [-5.0, 5.0], "base": "pierre112_sombre", "timber": false})
	_zone("hf_bibliotheque", fx, Vector3(0, 4.0, -d * 0.5), Vector3(w * 0.5 - 0.6, 4.4, d * 0.5 - 0.5))
	kit.box(fx * T(0, 8.75, -d * 0.5), Vector3(w + 0.6, 0.4, d + 0.6), "pierre112_clair", 1.2)
	kit.plaque112(fx * T(0, 5.0, 0.05), "bibliotheque", 3.2)
	for x in [-7.6, 7.6]:
		kit.box(fx * T(x, 4.25, 0.12), Vector3(0.7, 8.5, 0.25), "pierre112_clair", 1.2)
	# les rayonnages, le long des murs (des livres de toutes les couleurs)
	var cols := ["tissu112_rouge", "tissu112_bleu", "tissu112_vert", "tissu112_or", "tissu112_creme", "cuir71"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11288
	for s in [-1.0, 1.0]:
		var sx: Transform3D = fx * Transform3D(Basis(Vector3.UP, -s * PI * 0.5), Vector3(s * (w * 0.5 - 1.0), 0, -d * 0.5))
		for seg in range(3):
			var z0: float = -d * 0.5 + 2.4 + seg * 3.5
			kit.box(sx * T(z0, 3.0, -0.25), Vector3(3.2, 6.0, 0.5), "bois112", 1.0, 63 - 16)
			kit.col_box(sx * T(z0, 3.0, -0.25), Vector3(3.2, 6.0, 0.5))
			for sh in range(6):
				var yy: float = 0.4 + sh * 0.95
				kit.box(sx * T(z0, yy - 0.04, 0.0), Vector3(3.1, 0.05, 0.42), "bois112", 1.0)
				var x0: float = z0 - 1.5
				while x0 < z0 + 1.45:
					var bw: float = rng.randf_range(0.05, 0.12)
					var bh: float = rng.randf_range(0.5, 0.82)
					kit.box(sx * T(x0 + bw * 0.5, yy + bh * 0.5, -0.05), Vector3(bw, bh, 0.3), cols[rng.randi() % cols.size()], 1.0, 16 | 4)
					x0 += bw + 0.008
	# les tables de lecture, le grand globe, le bureau
	for k in range(2):
		var tx: Transform3D = fx * T(0, 0, -5.0 - k * 4.0)
		kit.box(tx * T(0, 0.78, 0), Vector3(3.6, 0.08, 1.2), "bois112", 1.0)
		for e in [[-1.6, -0.5], [1.6, -0.5], [-1.6, 0.5], [1.6, 0.5]]:
			kit.box(tx * T(float(e[0]), 0.39, float(e[1])), Vector3(0.1, 0.78, 0.1), "bois112", 1.0)
		kit.col_box(tx * T(0, 0.4, 0), Vector3(3.6, 0.85, 1.2))
		kit.globe_lamp112(tx * Vector3(1.2, 0.82, 0), 0.0, 0.5, k == 0)
	var gl: Vector3 = fx * Vector3(-4.0, 0, -11.5)
	kit.cyl(Transform3D(Basis(), gl), 0.3, 0.12, 0.9, "bois112", 8)
	kit.ball(Transform3D(Basis(), gl + Vector3.UP * 1.55), 0.65, "tissu112_bleu", 14, 8)
	kit.ring(Transform3D(Basis(Vector3.RIGHT, 0.4), gl + Vector3.UP * 1.55), 0.68, 0.74, 0.04, "laiton112", 24)
	kit.col_cyl(gl, 0.7, 2.2)
	var dk: Transform3D = fx * T(3.5, 0, -2.5)
	var keeper: Vector3 = kit.counter71(dk, 2.6, "bois112")
	c._pt("bib_dehors", fx * Vector3(0, 0.05, 3.5))
	c._pt("bib_entree", fx * Vector3(0, 0.05, -1.4))
	c._pt("bib_salle", fx * Vector3(0, 0.05, -8.5))
	c._pt("bib_derriere", dk * Vector3(1.8, 0.05, -1.4))
	c._pt("bib_rayon", fx * Vector3(-2.6, 0.05, -12.0))
	c._chain(["bib_dehors", "bib_entree", "bib_salle", "bib_rayon"])
	c._chain(["bib_entree", "bib_derriere"])
	_ring_link("bib_dehors", "hi", a)
	c._spot("bibliotheque_bureau", keeper + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "bib_derriere")
	c._spot("bibliotheque_rayons", fx * Vector3(-5.6, 0.05, -12.4), fx.basis * Vector3(-1, 0, 0), "lire", "bib_rayon")
	c.objets["comptoir_philippine"] = dk * Vector3(0, 0.05, 1.0)
	c._avoid(fx * Vector3(0, 0, -d * 0.5), 12.0)


# =================================================================== la Ville-Moyenne

## Le Grand Marché : une place, une fontaine aux engrenages, des étals sous des toiles de couleur.
func marche() -> void:
	var y: float = R.MOY_Y
	var fa: float = 126.0
	var fr: float = 105.0
	var fc: Vector3 = c.PW(fa, fr, y)
	# la fontaine : une vasque, un obélisque de laiton à engrenages
	var xf := Transform3D(Basis(), fc)
	kit.ring(xf, 2.6, 3.0, 0.7, "pierre112_clair", 32)
	kit.disc(xf * T(0, 0.5, 0), 2.6, "eau112", 32, 3.0)
	kit.disc(xf * T(0, 0.04, 0), 2.6, "pave112", 16, 2.0)
	kit.col_cyl(fc, 3.0, 0.8)
	kit.col_cyl(fc, 0.8, 4.5)
	kit.cyl(xf, 0.8, 0.6, 1.2, "pierre112", 8)
	kit.cyl(xf * T(0, 1.2, 0), 0.4, 0.12, 3.2, "laiton112_vieux", 8)
	kit.ball(xf * T(0, 4.5, 0), 0.25, "or112", 10, 5)
	for k in range(3):
		var ag: float = TAU * k / 3.0
		var dg := Vector3(cos(ag), 0, sin(ag))
		kit.gear112(Transform3D(Basis.looking_at(-dg, Vector3.UP), fc + dg * 0.45 + Vector3.UP * (1.8 + k * 0.5)), 0.32, 9, 0.06, "cuivre112")
	c._avoid(fc, 5.0)
	c._pt("ma_fontaine", fc + c.radial(fa) * 5.0 + Vector3.UP * 0.05)
	c._pt("ma_nord", c.PW(fa, fr - 11.0, y + 0.05))
	c._pt("ma_sud", c.PW(fa, fr + 11.0, y + 0.05))
	c._pt("ma_est", c.PW(fa - 9.0, fr, y + 0.05))
	c._pt("ma_ouest", c.PW(fa + 9.0, fr, y + 0.05))
	c._chain(["ma_ouest", "ma_nord", "ma_est", "ma_sud", "ma_ouest"])
	c._link("ma_fontaine", "ma_sud")
	c._link("ma_fontaine", "ma_ouest")
	_ring_link("ma_nord", "mi", fa)
	_ring_link("ma_sud", "mo", fa)
	_ring_link("ma_est", "mi", fa - 18.0)
	_ring_link("ma_ouest", "mo", fa + 18.0)
	c._spot("marche_fontaine", fc + c.radial(fa) * 3.6 + c.tangent(fa) * 1.0 + Vector3.UP * 0.05, -c.radial(fa), "debout", "ma_fontaine")
	# les étals, en arc autour de la fontaine
	var colors := ["rouge", "vert", "jaune", "bleu", "orange", "violet"]
	var stalls := [[fa - 11.0, fr - 6.0], [fa - 13.0, fr + 6.0], [fa - 3.0, fr + 13.0], [fa + 5.0, fr + 13.0], [fa + 13.0, fr + 5.0], [fa + 12.0, fr - 7.0]]
	for i in range(stalls.size()):
		var sa: float = float(stalls[i][0])
		var sr: float = float(stalls[i][1])
		var sp: Vector3 = c.PW(sa, sr, y)
		var sx: Transform3D = c.XD(sp, fc - sp)
		kit.stall71(sx, 2.8, 1.4, colors[i])
		c.cadres116["etal_%d" % i] = sx
		c._avoid(sx.origin, 3.2)
		var pt: String = c._pt("ma_etal_%d" % i, sx * Vector3(1.9, 0.05, -0.7))
		c._link(pt, ["ma_est", "ma_est", "ma_sud", "ma_sud", "ma_ouest", "ma_ouest"][i])
		if i < 4:
			c._spot("marche_etal_%d" % (i + 1), sx * Vector3(0, 0.05, -2.0), sx.basis * Vector3(0, 0, 1), "comptoir", pt)
		if i == 0:
			c.objets["etal_rosalie"] = sx * Vector3(0, 0.05, 1.2)
			kit.plaque112(sx * Transform3D(Basis(), Vector3(0, 2.9, 0.4)), "epices", 1.6)
		if i == 2:
			# l'étal d'Ysaé : des bijoux de boulons et de cristal (des points qui brillent)
			for j in range(8):
				kit.ball(sx * T(-1.0 + j * 0.28, 1.0, -0.4), 0.04, "cristal71" if j % 2 == 0 else "laiton112", 6, 3)
	# des bancs, des arbres
	for k2 in range(5):
		c.tree_spots.append(c.PW(fa - 18.0 + k2 * 9.0, 121.0, y))
	_zone("hf_marche", c.XD(fc, c.radial(fa)), Vector3(0, 4.0, 0), Vector3(22.0, 6.0, 17.0))
	c.cadres116["marche"] = c.XD(fc, c.radial(fa))


## La taverne « Le Piston Joyeux » : la salle, le comptoir, les tables, la cheminée, et la grande
## machine à chocolat de cuivre (sa chaudière, ses tuyaux, son sifflet).
func taverne() -> void:
	var y: float = R.MOY_Y
	var a: float = -91.0
	var fx: Transform3D = c.PX(a, 114.5, y, "out")
	var w: float = 15.0
	var d: float = 16.0
	c.cadres116["taverne"] = fx
	kit.hall71(fx, w, d, {"h": 6.6, "wall": "pierre112", "inner": "enduit71_ocre", "floor_key": "planches71", "door_w": 2.0, "door_h": 2.8,
		"roof": "ardoise112", "pitch": 50.0, "lights": 2, "energy": 1.8, "front_windows": [-4.5, 4.5], "base": "pierre112_sombre", "timber": false})
	_zone("hf_taverne", fx, Vector3(0, 3.2, -d * 0.5), Vector3(w * 0.5 - 0.6, 3.4, d * 0.5 - 0.5))
	kit.sign112(fx * T(-2.2, 3.7, 0.0), "piston", 1.5, 0.75)
	kit.awning71(fx * T(0, 3.2, 0.0), w - 1.0, 1.8, 0.8, "rouge")
	for k in range(3):
		kit.window112(fx * T(-5.0 + k * 5.0, 5.0, 0.0), true, true)
	# le comptoir, et derrière, la machine à chocolat
	var cx: Transform3D = fx * T(-3.0, 0, -12.0)
	var keeper: Vector3 = kit.counter71(cx, 4.4, "bois112")
	var mx: Transform3D = cx * T(0, 0, -3.0)
	kit.cyl(mx * T(0, 0.0, 0), 0.8, 0.8, 2.2, "cuivre112", 16)
	kit.dome76(mx * T(0, 2.2, 0), 0.8, 0.5, "cuivre112", 16, 4)
	kit.cyl(mx * T(0, 2.7, 0), 0.08, 0.08, 0.8, "laiton112", 8)
	for s in [-1.0, 1.0]:
		kit.cyl(Transform3D(Basis(Vector3.BACK, s * 1.2), mx * Vector3(s * 0.75, 1.4, 0)), 0.06, 0.06, 1.1, "laiton112", 6)
		kit.clock112(mx * Transform3D(Basis(Vector3.UP, s * 0.6), Vector3(s * 0.45, 1.6, 0.68)), 0.16)
	whistle_at = mx * Vector3(0, 3.55, 0)
	kit.col_cyl(mx.origin, 0.9, 3.0)
	c.steam_spots.append(whistle_at)
	var t1: Array = kit.tavern_table71(fx * T(2.5, 0, -4.5), 2.2)
	var t2: Array = kit.tavern_table71(fx * T(-3.0, 0, -5.0), 2.2)
	var t3: Array = kit.tavern_table71(fx * T(3.5, 0, -10.0), 2.2)
	# la cheminée
	var hx: Transform3D = fx * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(w * 0.5 - 0.65, 0, -8.0))
	kit.box(hx * T(0, 1.2, -0.3), Vector3(2.2, 2.4, 0.8), "pierre112_sombre", 1.0)
	kit.col_box(hx * T(0, 1.2, -0.3), Vector3(2.2, 2.4, 0.8))
	kit.fires70.append([hx * Vector3(0, 0.35, 0.2), 0.45])
	c._pt("ta_comptoir", cx * Vector3(0, 0.05, 1.8))
	c._pt("ta_derriere", cx * Vector3(2.8, 0.05, -1.3))
	c._pt("ta_salle", fx * Vector3(0, 0.05, -7.5))
	c._pt("ta_entree", fx * Vector3(0, 0.05, -1.4))
	c._pt("ta_dehors", fx * Vector3(0, 0.05, 3.0))
	c._chain(["ta_dehors", "ta_entree", "ta_salle", "ta_comptoir", "ta_derriere"])
	c._spot("taverne_comptoir", keeper + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "ta_derriere")
	c.objets["comptoir_firmin"] = cx * Vector3(0, 0.05, 1.1)
	c._spot("taverne_table_1", (t1[0] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, -1), "assis", "ta_salle")
	c._spot("taverne_table_2", (t2[0] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, -1), "assis", "ta_salle")
	c._spot("taverne_table_3", (t3[1] as Vector3) + Vector3.UP * 0.45, fx.basis * Vector3(0, 0, 1), "assis", "ta_salle")
	_ring_link("ta_dehors", "mo", a)
	c.doors["porte_firmin"] = c._pt("porte_firmin", fx * Vector3(-5.5, 0.05, -14.5))
	c._link("porte_firmin", "ta_derriere")
	c._avoid(fx * Vector3(0, 0, -d * 0.5), 11.0)


## Le Mât des dirigeables : une tour de fer à treillis, sa plate-forme, l'Albatros amarré au sommet ;
## au pied, le kiosque des billets, des caisses, des rouleaux de cordage.
func mat() -> void:
	var y: float = R.MOY_Y
	var a: float = -156.0
	var mp: Vector3 = c.PW(a, 106.0, y)
	var h: float = 26.0
	for e in [[-1.6, -1.6], [1.6, -1.6], [-1.6, 1.6], [1.6, 1.6]]:
		var b: Vector3 = mp + Vector3(float(e[0]), 0, float(e[1]))
		var t: Vector3 = mp + Vector3(float(e[0]) * 0.45, h, float(e[1]) * 0.45)
		kit.beam(b, t, 0.3, "acier112")
		kit.col_box(Transform3D(Basis(), b + Vector3.UP * 1.5), Vector3(0.4, 3.0, 0.4))
	for k in range(8):
		var y0: float = 2.0 + k * 3.0
		var s0: float = lerpf(1.6, 0.72, y0 / h)
		var s1: float = lerpf(1.6, 0.72, (y0 + 3.0) / h)
		for e2 in [[Vector3(-1, 0, -1), Vector3(1, 0, -1)], [Vector3(1, 0, -1), Vector3(1, 0, 1)], [Vector3(1, 0, 1), Vector3(-1, 0, 1)], [Vector3(-1, 0, 1), Vector3(-1, 0, -1)]]:
			kit.beam(mp + (e2[0] as Vector3) * s0 + Vector3.UP * y0, mp + (e2[1] as Vector3) * s1 + Vector3.UP * (y0 + 3.0), 0.1, "acier112")
			kit.beam(mp + (e2[0] as Vector3) * s0 + Vector3.UP * y0, mp + (e2[1] as Vector3) * s0 + Vector3.UP * y0, 0.12, "acier112")
	kit.box(Transform3D(Basis(), mp + Vector3.UP * h), Vector3(3.4, 0.25, 3.4), "bois112", 1.0)
	kit.cyl(Transform3D(Basis(), mp + Vector3.UP * (h + 0.1)), 0.35, 0.25, 3.0, "laiton112", 10)
	kit.ball(Transform3D(Basis(), mp + Vector3.UP * (h + 3.2)), 0.5, "laiton112", 10, 5)
	kit.place("globe112", Transform3D(Basis(), mp + Vector3.UP * (h + 1.4) + Vector3(0.6, 0, 0)))
	# l'Albatros : il a son propre nœud (il se balance doucement au bout de son amarre)
	var tang: Vector3 = c.tangent(a)
	var rad: Vector3 = c.radial(a)
	airship = Node3D.new()
	airship.name = "Albatros"
	c.add_child(airship)
	var saved_root: Node3D = kit.root
	var saved_batch: Dictionary = kit.batch
	var saved_inst: Dictionary = kit.inst
	kit.root = airship
	kit.batch = {}
	kit.inst = {}
	kit.airship112(Transform3D.IDENTITY, 30.0, "tissu112_creme")
	kit.commit()
	kit.root = saved_root
	kit.batch = saved_batch
	kit.inst = saved_inst
	var nose: Vector3 = mp + Vector3.UP * (h + 3.0)
	airship_base = Transform3D(Basis.looking_at(tang, Vector3.UP) * Basis(Vector3.UP, PI * 0.5), nose - tang * 15.5 + rad * 2.0 + Vector3.DOWN * 0.5)
	airship.transform = airship_base
	# le kiosque des billets, les caisses, les cordages
	var kx: Transform3D = c.XD(mp + rad * 6.0 + tang * 3.0, -rad)
	kit.box(kx * T(0, 1.2, -0.6), Vector3(2.4, 2.4, 1.6), "bois112", 1.0)
	kit.col_box(kx * T(0, 1.2, -0.6), Vector3(2.4, 2.4, 1.6))
	kit.box(kx * T(0, 1.15, 0.25), Vector3(2.2, 0.06, 0.4), "laiton112", 1.0)
	kit.roof_hip(kx * T(0, 2.45, -0.6), 2.7, 1.9, 35.0, 0.2, "verdigris112")
	kit.window112(kx * T(0, 1.75, 0.22), true, true)
	for k3 in range(4):
		kit.crate71(mp + tang * (-4.0 - k3 * 0.9) + rad * 3.0, deg_to_rad(a + k3 * 20.0), 0.8)
	for k4 in range(3):
		kit.cyl(Transform3D(Basis(), mp + tang * (4.0 + k4 * 1.1) + rad * 2.5), 0.45, 0.45, 0.35, "foin71", 12)
	c._pt("mat_pied_pt", mp + rad * 4.0 + Vector3.UP * 0.05)
	c._pt("mat_kiosque", kx * Vector3(0, 0.05, 1.5))
	c._chain(["mat_pied_pt", "mat_kiosque"])
	_ring_link("mat_pied_pt", "mo", a)
	_ring_link("mat_pied_pt", "mi", a)
	c._spot("mat_pied", mp + rad * 2.6 + Vector3.UP * 0.05, -rad, "observer", "mat_pied_pt")
	c._spot("mat_passerelle", kx * Vector3(0, 0.05, 0.9), kx.basis * Vector3(0, 0, 1), "comptoir", "mat_kiosque")
	c.doors["porte_heloise_mat"] = c._pt("porte_heloise_mat", kx * Vector3(0, 0.05, 2.4))
	# V116 : l'embarquement, au pied du mât (on monte à bord de l'Albatros), et son panneau
	var emb: Vector3 = mp + rad * 2.2 - tang * 2.4
	var pn: Vector3 = emb - tang * 1.0
	kit.cyl(Transform3D(Basis(), pn), 0.06, 0.06, 1.7, "bois112", 6)
	var sxf := Transform3D(Basis.looking_at(-rad, Vector3.UP), pn + Vector3.UP * 1.62)
	kit.box(sxf, Vector3(1.3, 0.34, 0.05), "bois112", 1.0)
	for s116 in [1.0, -1.0]:
		var lab := Label3D.new()
		lab.text = "Embarquement : l'Albatros"
		lab.font_size = 44
		lab.pixel_size = 0.0035
		lab.outline_size = 10
		lab.modulate = Color(1.0, 0.95, 0.82)
		lab.outline_modulate = Color(0.18, 0.11, 0.05)
		lab.double_sided = false
		c.add_child(lab)
		lab.global_transform = sxf * Transform3D(Basis(Vector3.UP, 0.0 if s116 > 0.0 else PI), Vector3(0, 0, 0.035 * s116))
	c.portes116["hf_albatros"] = [emb + Vector3.UP * 0.05, rad]
	c._avoid(mp, 8.0)
	_zone("hf_mat", Transform3D(Basis(), mp), Vector3(0, 10.0, 0), Vector3(10.0, 20.0, 10.0))


# =================================================================== la Basse-Ville

## La Forge à vapeur : un appentis de pierre et de fer, ouvert sur la rue ; le foyer, l'enclume, le
## marteau-pilon à vapeur (il frappe), la chaudière, le râtelier, le comptoir.
func forge() -> void:
	var y: float = R.BASSE_Y
	var a: float = 36.0
	var fx: Transform3D = c.PX(a, 140.0, y, "in")
	c.cadres116["forge"] = fx
	for sx in [-1.0, 1.0]:
		for sz in [0.0, -8.0]:
			kit.box(fx * T(sx * 5.4, 2.4, sz - 0.5), Vector3(0.5, 4.8, 0.5), "pierre112", 1.0)
			kit.col_box(fx * T(sx * 5.4, 2.4, sz - 0.5), Vector3(0.5, 4.8, 0.5))
	kit.roof_gable(fx * T(0, 4.8, -4.5), 11.8, 9.6, 28.0, 0.3, "ardoise112", "pierre112")
	kit.box(fx * T(0, 2.4, -9.2), Vector3(11.2, 4.8, 0.5), "pierre112_sombre", 1.6)
	kit.col_box(fx * T(0, 2.4, -9.2), Vector3(11.2, 4.8, 0.5))
	kit.box(fx * T(0, 0.04, -4.5), Vector3(11.0, 0.08, 9.0), "pave112", 2.0)
	kit.plaque112(fx * T(0, 4.3, 0.2), "forge_vapeur", 2.8)
	# le foyer, la chaudière et sa cheminée de briques
	var fo: Transform3D = fx * T(-3.2, 0, -7.6)
	kit.box(fo * T(0, 0.5, 0), Vector3(2.2, 1.0, 1.6), "pierre112_sombre", 1.0)
	kit.col_box(fo * T(0, 0.5, 0), Vector3(2.2, 1.0, 1.6))
	kit.cyl(fo * T(0, 1.05, -0.4), 0.7, 0.4, 4.5, "pierre112_sombre", 6)
	kit.fires70.append([fo * Vector3(0, 1.15, 0.1), 0.5])
	var ch: Transform3D = fx * T(3.6, 0, -7.4)
	kit.cyl(ch, 0.9, 0.9, 2.6, "cuivre112", 16)
	kit.dome76(ch * T(0, 2.6, 0), 0.9, 0.5, "cuivre112", 16, 4)
	kit.cyl(ch * T(0, 3.0, 0), 0.15, 0.15, 3.5, "acier112", 8)
	kit.col_cyl(ch.origin, 1.0, 3.0)
	c.steam_spots.append(ch * Vector3(0, 6.7, 0))
	kit.clock112(ch * Transform3D(Basis(), Vector3(0, 1.6, 0.92)), 0.22)
	# l'enclume, le marteau-pilon (son bâti, son mouton qui frappe)
	var an: Transform3D = fx * T(0.0, 0, -4.2)
	kit.cyl(an, 0.32, 0.28, 0.62, "bois112", 8)
	kit.box(an * T(0, 0.78, 0), Vector3(0.95, 0.32, 0.34), "acier112", 1.0)
	kit.col_box(an * T(0, 0.48, 0), Vector3(0.95, 0.95, 0.4))
	var ph: Transform3D = fx * T(1.6, 0, -5.4)
	for s in [-1.0, 1.0]:
		kit.box(ph * T(s * 0.7, 1.8, 0), Vector3(0.3, 3.6, 0.5), "acier112", 1.0)
	kit.box(ph * T(0, 3.7, 0), Vector3(1.8, 0.4, 0.6), "acier112", 1.0)
	kit.box(ph * T(0, 0.45, 0), Vector3(1.0, 0.9, 0.7), "acier112", 1.0)
	kit.col_box(ph * T(0, 1.8, 0), Vector3(1.8, 3.6, 0.7))
	kit.cyl(ph * T(0, 3.9, 0), 0.25, 0.25, 0.9, "laiton112", 10)
	steam_hammer = MeshInstance3D.new()
	steam_hammer.name = "Marteau_pilon"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.8, 0.5)
	(steam_hammer as MeshInstance3D).mesh = bm
	(steam_hammer as MeshInstance3D).material_override = kit.mat("acier112_clair")
	c.add_child(steam_hammer)
	hammer_base = ph * Vector3(0, 2.2, 0)
	steam_hammer.global_transform = Transform3D(ph.basis, hammer_base)
	# le râtelier d'armes et d'outils, le comptoir
	var rk: Transform3D = fx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-5.0, 0, -3.0))
	kit.box(rk * T(0, 1.0, 0), Vector3(2.4, 0.1, 0.3), "bois112", 1.0)
	kit.box(rk * T(0, 1.8, 0), Vector3(2.4, 0.1, 0.3), "bois112", 1.0)
	for k in range(5):
		kit.box(rk * T(-0.9 + k * 0.45, 1.5, 0.12), Vector3(0.06, 1.4, 0.04), "acier112_clair", 1.0)
	var keeper: Vector3 = kit.counter71(fx * T(-1.8, 0, -1.2), 2.4, "bois112")
	c._pt("fo_dehors", fx * Vector3(0, 0.05, 3.0))
	c._pt("fo_atelier", fx * Vector3(-1.0, 0.05, -3.0))
	c._pt("fo_derriere", fx * Vector3(-1.8, 0.05, -2.5))
	c._chain(["fo_dehors", "fo_atelier", "fo_derriere"])
	_ring_link("fo_dehors", "bi", a)
	c._spot("forge_enclume", an * Vector3(0, 0.05, -1.0), fx.basis * Vector3(0, 0, 1), "forger", "fo_atelier")
	c._spot("forge_comptoir", keeper + Vector3.UP * 0.05, fx.basis * Vector3(0, 0, 1), "comptoir", "fo_derriere")
	c.objets["comptoir_mathilde"] = fx * Vector3(-1.8, 0.05, 0.4)
	c.doors["porte_mathilde"] = c._pt("porte_mathilde", fx * Vector3(4.6, 0.05, -8.4))
	c._link("porte_mathilde", "fo_atelier")
	c._avoid(fx * Vector3(0, 0, -4.5), 9.0)
	_zone("hf_forge", fx, Vector3(0, 2.4, -4.5), Vector3(5.8, 3.0, 5.0))


## Le lavoir : un bassin de pierre sous un toit d'ardoise porté par des piliers.
func lavoir() -> void:
	var y: float = R.BASSE_Y
	var a: float = 158.0
	var lx: Transform3D = c.PX(a, 146.0, y, "in")
	c.cadres116["lavoir"] = lx
	kit.box(lx * T(0, 0.35, -2.0), Vector3(7.0, 0.7, 3.4), "pierre112_clair", 1.2, 63 - 4 - 8)
	kit.box(lx * T(0, 0.45, -2.0), Vector3(6.2, 0.04, 2.6), "eau112", 1.0, 4)
	kit.col_box(lx * T(0, 0.35, -2.0), Vector3(7.0, 0.7, 3.4))
	for e in [[-3.8, 0.0], [3.8, 0.0], [-3.8, -4.0], [3.8, -4.0]]:
		kit.box(lx * T(float(e[0]), 1.7, float(e[1])), Vector3(0.4, 3.4, 0.4), "pierre112", 1.0)
	kit.roof_gable(lx * T(0, 3.4, -2.0), 8.6, 5.4, 30.0, 0.3, "ardoise112", "pierre112")
	kit.cyl(Transform3D(lx.basis * Basis(Vector3.RIGHT, PI * 0.5), lx * Vector3(-2.6, 1.0, -3.6)), 0.06, 0.06, 0.6, "laiton112", 6)
	c._pt("la_bord", lx * Vector3(0, 0.05, 0.8))
	_ring_link("la_bord", "bi", a)
	c._spot("lavoir_1", lx * Vector3(-1.0, 0.05, -0.15), lx.basis * Vector3(0, 0, -1), "debout", "la_bord")
	c._avoid(lx * Vector3(0, 0, -2.0), 6.0)

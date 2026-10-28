extends RefCounted
## V70 : les grands lieux de la Basse-Ville et du port de Pandémonia (la Citadelle et la
## Haute-Ville : pandemonia_lieux_v70.gd) :
##  - le Grand Marché (ses étals, ses boutiques : l'armurier, l'apothicaire, le boulanger du
##    Four Éternel, les épices de Zébuline) ;
##  - la caserne de la Garde ;
##  - l'Arène des Cornes (le sable, le podium, les gradins, le grand mur à arcades, les deux
##    portes, le guichet) ;
##  - les Thermes de Soufre (le hall, la cour, le bassin d'eau jaune et fumante) ;
##  - les Jardins de Cendre (les massifs, la mare de lave et son petit pont) ;
##  - la placette des Artisans (la couturière, le polisseur de cornes, l'inventeur) ;
##  - le chenil des chiots d'enfer ;
##  - la Rade de Cendre : les quais, la taverne « Au Diable Repu », la capitainerie, la poste,
##    la poissonnerie, les entrepôts, la grue, les navires, la jetée et le phare.

const R = preload("res://scripts/ile_braise_v70.gd")
const Navire = preload("res://scripts/navire_braise_v70.gd")

var c                                    # pandemonia_v70
var kit
var arena := {}                          # l'Arène : {c (centre du sable), r, porte, arriere, xf, gradins}
var pool := {}                           # le bassin des Thermes : {c, size, xf}
var ships: Dictionary = {}
var vapeur: Array = []                   # Vector3 : la vapeur des Thermes
var garden_spots: Array = []             # Vector3 : les massifs (les fleurs de braise)
var puppies: Array = []                  # [Vector3, angle] : les chiots d'enfer du chenil
var phare_light: OmniLight3D
var phare_glass: MeshInstance3D
var _zones: Array = []
var _hcenter := Vector3.ZERO


func setup(city) -> void:
	c = city
	kit = city.kit
	_hcenter = R.W(R.HARBOR.x, R.HARBOR.y, R.QUAY_Y)


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func _zone(name: String, xf: Transform3D, center: Vector3, half: Vector3) -> void:
	_zones.append([name, (xf * Transform3D(Basis(), center)).affine_inverse(), half])


func zone_at(p: Vector3, _cp: Vector2) -> String:
	for z in _zones:
		var l: Vector3 = (z[1] as Transform3D) * p
		var h: Vector3 = z[2]
		if absf(l.x) < h.x and absf(l.y) < h.y and absf(l.z) < h.z:
			return str(z[0])
	if arena.has("c") and Vector2(p.x - arena["c"].x, p.z - arena["c"].z).length() < 22.5 and p.y > c.BY - 3.0:
		return "braise_arene"
	var l2: Vector2 = R.L(p.x, p.z)
	if l2.distance_to(R.HARBOR) < R.HARBOR_R + 40.0 and R.city_polar(l2.x, l2.y).y > c.WALL_R - 1.0:
		return "braise_port"
	return ""


## Un point de la rade : alpha (degrés, de x vers z autour du centre du bassin), rho (m).
func HP(alpha: float, rho: float, y: float = R.QUAY_Y) -> Vector3:
	var a: float = deg_to_rad(alpha)
	return Vector3(_hcenter.x + cos(a) * rho, y, _hcenter.z + sin(a) * rho)


## Un repère de la rade, son +Z vers le bassin (« in ») ou vers la terre (« out »).
func HX(alpha: float, rho: float, facing: String = "in", y: float = R.QUAY_Y) -> Transform3D:
	var a: float = deg_to_rad(alpha)
	var out := Vector3(cos(a), 0, sin(a))
	return Transform3D(Basis.looking_at(out if facing == "in" else -out, Vector3.UP), HP(alpha, rho, y))


# =================================================================== un étal

func stall70(xf: Transform3D, cloth: String, goods: String) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.box(xf * T(sx * 1.15, 1.2 + (0.15 if sz < 0 else 0.0), sz * 0.62), Vector3(0.09, 2.4 + (0.3 if sz < 0 else 0.0), 0.09), "boisb70", 1.0)
	kit.box(xf * T(0, 0.84, 0), Vector3(2.5, 0.08, 1.3), "boisb70", 1.0)
	kit.box(xf * T(0, 0.42, 0.6), Vector3(2.4, 0.84, 0.05), "boisb70", 1.0)
	kit.box(xf * Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 2.5, 0.0)), Vector3(2.8, 0.04, 1.9), cloth, 1.0)
	for k in range(5):
		kit.box(xf * T(-1.2 + k * 0.6, 2.22, 0.98), Vector3(0.5, 0.36, 0.02), cloth, 1.0)
	kit.col_box(xf * T(0, 0.45, 0), Vector3(2.5, 0.9, 1.3))
	var rr: RandomNumberGenerator = kit.rng
	match goods:
		"epices":
			var cols := ["tissu70_rouge", "tissu70_or", "tissu70_pourpre", "boue70", "soufre70", "tissu70_noir"]
			for k2 in range(6):
				var p: Vector3 = xf * Vector3(-1.0 + k2 * 0.4, 0.88, rr.randf_range(-0.25, 0.2))
				kit.cyl(Transform3D(Basis(), p), 0.17, 0.17, 0.12, "boisb70", 8)
				kit.cyl(Transform3D(Basis(), p + Vector3.UP * 0.12), 0.16, 0.0, 0.16, cols[k2], 8)
		"potions":
			var lc := ["lueur70_vert", "lueur70_bleu", "lueur70_pourpre", "lueur70_rouge", "lueur70_or"]
			for k3 in range(10):
				var p2: Vector3 = xf * Vector3(-1.05 + k3 * 0.23, 0.88, rr.randf_range(-0.3, 0.25))
				kit.cyl(Transform3D(Basis(), p2), 0.06, 0.05, 0.2, lc[k3 % lc.size()], 8)
				kit.cyl(Transform3D(Basis(), p2 + Vector3.UP * 0.2), 0.025, 0.02, 0.08, "vitre70", 6)
		"pain":
			for k4 in range(12):
				var p3: Vector3 = xf * Vector3(-1.0 + (k4 % 6) * 0.4, 0.92, -0.25 + (k4 / 6) * 0.4)
				kit.ball(Transform3D(Basis.from_scale(Vector3(1.3, 0.8, 1.0)), p3), 0.11, "boisb70" if k4 % 3 == 0 else "cuir70", 6, 3)
		"armes":
			for k5 in range(5):
				var p4: Vector3 = xf * Vector3(-0.9 + k5 * 0.45, 0.9, 0.0)
				kit.box(Transform3D(xf.basis * Basis(Vector3.UP, 0.3), p4), Vector3(0.08, 0.03, 0.9), "fer70", 1.0)
				kit.box(Transform3D(xf.basis * Basis(Vector3.UP, 0.3), p4 + xf.basis * Vector3(0, 0.02, 0.4)), Vector3(0.22, 0.04, 0.05), "bronze70", 1.0)
		"poisson":
			for k6 in range(8):
				var p5: Vector3 = xf * Vector3(-1.0 + k6 * 0.28, 0.9, rr.randf_range(-0.3, 0.3))
				kit.cyl(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.RIGHT, rr.randf_range(-0.3, 0.3)), p5), 0.06, 0.02, 0.4, "lueur70_rouge" if k6 % 3 == 0 else "fer70", 6)
		"lanternes":
			for k7 in range(5):
				kit.place("lanterne", Transform3D(Basis.from_scale(Vector3.ONE * 0.6), xf * Vector3(-1.0 + k7 * 0.5, 0.88, 0.0)))
		_:
			for k8 in range(4):
				kit.box(Transform3D(xf.basis * Basis(Vector3.UP, rr.randf_range(-0.4, 0.4)), xf * Vector3(-0.8 + k8 * 0.55, 1.03, rr.randf_range(-0.2, 0.2))), Vector3(0.35, 0.3, 0.3), "boisb70", 0.6)


## Un comptoir de boutique devant une porte (xf : au sol, le client vient de +Z).
func counter70(xf: Transform3D, w: float = 2.2) -> void:
	kit.box(xf * T(0, 0.52, 0), Vector3(w, 1.04, 0.6), "boisb70", 1.0)
	kit.box(xf * T(0, 1.07, 0.03), Vector3(w + 0.16, 0.06, 0.76), "mrouge70", 1.0)
	kit.col_box(xf * T(0, 0.52, 0), Vector3(w, 1.04, 0.6))


# =================================================================== le Grand Marché

func marche() -> void:
	var y: float = c.BY
	var mc: Vector3 = c.PW(-17.5, 156.0, y)
	c.lanterns["marche"] = kit.great_lantern(mc)
	# les boutiques des deux côtés : [côté, rayon, enseigne, lieu, marchandise]
	var shops := [
		[-1.0, 141.0, "armurier", "marche_armes", "armes"], [-1.0, 156.0, "apothicaire", "marche_potions", "potions"], [-1.0, 171.0, "", "", ""],
		[1.0, 141.0, "boulangerie", "marche_pain", "pain"], [1.0, 156.0, "epices", "marche_epices", "epices"], [1.0, 171.0, "", "", ""],
	]
	for si in range(shops.size()):
		var sh: Array = shops[si]
		var s: float = float(sh[0])
		var ang: float = -17.5 + s * 8.6
		var hx: Transform3D = c.PX(ang, float(sh[1]), y, "ccw" if s > 0 else "cw")
		var door: Vector3 = kit.house70(hx, 11.0, 6.0, {"floors": 3, "wall": ["erouge70", "bnoire70", "pgoth70"][int(float(sh[1])) % 3], "roof": "tuile70", "gable": false,
			"shop": str(sh[2]), "lit": 0.6, "door_x": -2.6, "chimney": str(sh[2]) == "boulangerie", "sides": 0, "back": true})
		if str(sh[3]) != "":
			# le comptoir dehors, sous un auvent : le marchand derrière, face à la place
			var cx: Transform3D = hx * T(1.8, 0, 2.2)
			counter70(cx, 2.6)
			kit.box(hx * Transform3D(Basis(Vector3.RIGHT, 0.32), Vector3(1.8, 3.35, 1.6)), Vector3(4.0, 0.05, 3.0), ["tissu70_rouge", "tissu70_pourpre", "tissu70_or", "tissu70_noir"][si % 4], 1.0)
			_goods_on_counter(cx, str(sh[4]))
			c._pt("ma_" + str(sh[3]), hx * Vector3(1.8, 0.05, 4.2))
			c._spot(str(sh[3]), cx * Vector3(0, 0.05, -0.75), hx.basis * Vector3(0, 0, 1), "comptoir", "ma_" + str(sh[3]))
			if str(sh[2]) == "boulangerie":
				# le Four Éternel : sa gueule de feu dans le mur
				kit.ogive_face(hx * T(-0.2, 0.9, 0.02), 1.4, 1.5, "braise70", 4)
				kit.ogive_frame(hx * T(-0.2, 0.9, 0.0), 1.4, 1.5, 0.3, 0.3, "bnoire70", 4)
				kit.fires70.append([hx * Vector3(-0.2, 1.3, 0.25), 0.4])
	# les étals du milieu
	var goods := ["fruits", "lanternes", "epices", "potions", "poisson", "", "lanternes", "pain"]
	var clothes := ["tissu70_rouge", "tissu70_noir", "tissu70_or", "tissu70_pourpre", "tissu70_vert", "tissu70_rouge", "tissu70_bleu", "tissu70_or"]
	var k: int = 0
	for r in [142.0, 148.5, 163.5, 170.0]:
		for s2 in [-1.0, 1.0]:
			var sx: Transform3D = c.PX(-17.5 + s2 * 3.6, r, y, "cw" if s2 < 0 else "ccw")
			stall70(sx, clothes[k % clothes.size()], goods[k % goods.size()])
			k += 1
	# l'arche d'entrée, sur la rue Basse
	var ax: Transform3D = c.PX(-17.5, 133.2, y, "in")
	for s3 in [-1.0, 1.0]:
		kit.box(ax * T(s3 * 4.4, 2.6, 0), Vector3(0.8, 5.2, 0.8), "pgoth70", 1.4)
		kit.col_box(ax * T(s3 * 4.4, 2.6, 0), Vector3(0.8, 5.2, 0.8))
		kit.pinnacle(ax * Vector3(s3 * 4.4, 5.2, 0), 0.7, "pgoth70")
	kit.ogive_frame(ax * T(0, 0, -0.4), 8.0, 6.4, 0.5, 0.8, "pgoth70_sombre", 5, true)
	kit.box(ax * T(0, 5.6, 0.1), Vector3(3.2, 1.0, 0.12), "boisb70", 1.0)
	kit.quadz(ax * T(0, 5.6, 0.17), 3.0, 1.0, "enseigne70_marche")
	for s4 in [-1.0, 1.0]:
		kit.lamp70(c.PW(-17.5 + s4 * 2.6, 152.0, y), 3.9, true, false)
	c._pt("ma_c", c.PW(-17.5, 150.5, y + 0.05))
	c._pt("ma_s", c.PW(-17.5, 161.0, y + 0.05))
	c._pt("ma_n", c.PW(-17.5, 136.0, y + 0.05))
	c._pt("ma_e", c.PW(-17.5, 176.0, y + 0.05))
	c._spot("marche_flane_1", c.PW(-19.0, 146.0, y + 0.05), c.tangent(-17.5) * -1.0, "observer", "ma_c")
	c._spot("marche_flane_2", c.PW(-15.6, 166.5, y + 0.05), c.tangent(-17.5), "observer", "ma_s")
	c._chain(["ma_n", "ma_c", "ma_s", "ma_e"])
	for nm in ["ma_marche_armes", "ma_marche_potions"]:
		c._link(nm, "ma_c" if nm == "ma_marche_armes" else "ma_s")
	for nm2 in ["ma_marche_pain", "ma_marche_epices"]:
		c._link(nm2, "ma_c" if nm2 == "ma_marche_pain" else "ma_s")
	c._avoid(mc, 26.0)


func _goods_on_counter(cx: Transform3D, goods: String) -> void:
	var rr: RandomNumberGenerator = kit.rng
	match goods:
		"armes":
			for k in range(4):
				kit.box(Transform3D(cx.basis * Basis(Vector3.UP, 0.25), cx * Vector3(-0.9 + k * 0.6, 1.13, 0.0)), Vector3(0.07, 0.03, 0.8), "fer70", 1.0)
		"potions":
			for k2 in range(8):
				kit.cyl(Transform3D(Basis(), cx * Vector3(-1.05 + k2 * 0.3, 1.1, rr.randf_range(-0.1, 0.15))), 0.055, 0.045, 0.22, ["lueur70_vert", "lueur70_bleu", "lueur70_pourpre", "lueur70_or"][k2 % 4], 8)
		"pain":
			for k3 in range(7):
				kit.ball(Transform3D(Basis.from_scale(Vector3(1.3, 0.8, 1.0)), cx * Vector3(-1.0 + k3 * 0.33, 1.17, 0.0)), 0.12, "cuir70", 6, 3)
		"epices":
			for k4 in range(6):
				var p: Vector3 = cx * Vector3(-1.0 + k4 * 0.4, 1.1, 0.0)
				kit.cyl(Transform3D(Basis(), p), 0.15, 0.0, 0.18, ["tissu70_rouge", "tissu70_or", "tissu70_pourpre", "soufre70", "boue70", "tissu70_noir"][k4], 8)


# =================================================================== la caserne

func caserne() -> void:
	var y: float = c.BY
	var hx: Transform3D = c.PX(-60.0, 132.5, y, "in")
	kit.house70(hx, 14.0, 9.0, {"floors": 3, "wall": "pgoth70_sombre", "base": "basalte70", "roof": "ardoise70", "gable": false, "lit": 0.5, "door_x": 0.0, "banner": true, "chimney": true})
	kit.banner70(hx * T(-4.6, 9.0, 0.35), 1.0, 2.6)
	kit.banner70(hx * T(4.6, 9.0, 0.35), 1.0, 2.6)
	kit.tower70(c.PW(-63.0, 150.0, y), 3.4, 17.0, {"roof": "cone", "roof_h": 8.0, "windows": [5.0, 10.0], "nwin": 3, "lit": 0.5})
	# la cour d'exercice : des mannequins de paille et de cuir
	for k in range(3):
		var p: Vector3 = c.PW(-57.5 + k * 2.2, 147.0, y)
		kit.cyl(Transform3D(Basis(), p), 0.07, 0.06, 1.9, "boisb70", 6)
		kit.box(Transform3D(Basis(), p + Vector3.UP * 1.6), Vector3(0.9, 0.08, 0.08), "boisb70", 1.0)
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * 1.0), 0.24, 0.26, 0.8, "cuir70", 8)
		kit.ball(Transform3D(Basis(), p + Vector3.UP * 2.0), 0.18, "cuir70", 8, 4)
		kit.col_cyl(p, 0.26, 2.2)
	kit.lamp70(c.PW(-55.5, 135.5, y), 3.9, true, false)


# =================================================================== l'Arène des Cornes

func arene() -> void:
	var y: float = c.BY
	var ac: Vector3 = c.PW(68.0, c.BM_R, y)
	var ax := Transform3D(Basis.looking_at(c.radial(68.0), Vector3.UP), ac)     # +Z : vers la ville (la grande porte)
	var main_a: float = atan2((ax.basis * Vector3(0, 0, 1)).z, (ax.basis * Vector3(0, 0, 1)).x)
	var back_a: float = main_a + PI
	var gate_half: float = 2.4
	arena = {"c": ac + Vector3.UP * 0.05, "r": 10.2, "xf": ax, "porte": ax * Vector3(0, 0.05, 21.0), "arriere": ax * Vector3(0, 0.05, -21.0), "gradins": []}
	# le sable
	kit.disc(Transform3D(Basis(), ac + Vector3.UP * 0.04), 10.6, "arene70", 40, 4.0)
	# le podium (le mur qui entoure le sable), interrompu aux deux portes
	var gp: float = gate_half / 10.6
	for seg in [[main_a + gp, back_a - gp], [back_a + gp, main_a + TAU - gp]]:
		kit.arc_ring(ac, 10.6, 11.6, 1.7, float(seg[0]), float(seg[1]), "pgoth70_sombre", 20)
	# les gradins
	for i in range(8):
		var r0: float = 11.6 + i * 1.0
		var top: float = 1.7 + (i + 1) * 0.5
		var gpi: float = (gate_half + 0.3) / r0
		for seg2 in [[main_a + gpi, back_a - gpi], [back_a + gpi, main_a + TAU - gpi]]:
			kit.arc_ring(ac, r0, r0 + 1.0, top, float(seg2[0]), float(seg2[1]), "pgoth70", 24, true, 1 | 4 | 8, 1.6)
	# le grand mur : trois rangs d'arcades dehors, une galerie dedans, des créneaux
	var wr0: float = 19.6
	var wr1: float = 22.0
	var wh: float = 11.0
	var gw: float = (gate_half + 0.4) / wr1
	for seg3 in [[main_a + gw, back_a - gw], [back_a + gw, main_a + TAU - gw]]:
		kit.arc_ring(ac, wr0, wr1, wh, float(seg3[0]), float(seg3[1]), "pgoth70", 28, true, 15, 2.6)
		var n_arch: int = 11
		for k in range(n_arch):
			var t: float = lerpf(float(seg3[0]), float(seg3[1]), (k + 0.5) / n_arch)
			var out := Vector3(cos(t), 0, sin(t))
			for lv in range(2):
				var axf := Transform3D(Basis.looking_at(-out, Vector3.UP), ac + out * (wr1 + 0.01) + Vector3.UP * (0.6 + lv * 5.0))
				kit.ogive_face(axf, 2.4, 4.0, "fenetrenoire70", 4)
				kit.ogive_frame(axf, 2.4, 4.0, 0.3, 0.28, "pgoth70_sombre", 4)
			var ixf := Transform3D(Basis.looking_at(out, Vector3.UP), ac + out * (wr0 - 0.01) + Vector3.UP * 6.4)
			kit.ogive_face(ixf, 2.0, 3.6, "fenetrenoire70", 4)
		for k2 in range(18):
			var t2: float = lerpf(float(seg3[0]), float(seg3[1]), (k2 + 0.5) / 18.0)
			var o2 := Vector3(cos(t2), 0, sin(t2))
			kit.place("merlon|pgoth70", Transform3D(Basis(Vector3.UP, -t2) * Basis.from_scale(Vector3(0.6, 1.0, 1.4)), ac + o2 * (wr1 - 0.3) + Vector3.UP * wh))
	# les deux portes : un arc, le mur au-dessus, une herse levée
	for g in [[main_a, 1.0], [back_a, -1.0]]:
		var ga: float = float(g[0])
		var go := Vector3(cos(ga), 0, sin(ga))
		var gxf := Transform3D(Basis.looking_at(-go, Vector3.UP), ac + go * (wr0 + wr1) * 0.5)
		kit.arch_gate(gxf, gate_half * 2.0 - 0.2, 6.2, wr1 - wr0 + 0.2, wh, "pgoth70")
		kit.banner70(gxf * T(0, wh - 0.6, (wr1 - wr0) * 0.5 + 0.1), 1.2, 3.0)
	# l'enseigne, les affiches du tournoi, le guichet, la Grande Lanterne de l'arène
	var front: Transform3D = ax * T(0, 0, wr1 + 0.02)
	kit.box(front * T(0, 7.6, 0.06), Vector3(3.6, 1.6, 0.1), "boisb70", 1.0)
	kit.quadz(front * T(0, 7.6, 0.12), 3.2, 1.6, "enseigne70_arene")
	for s in [-1.0, 1.0]:
		var pa: float = main_a + s * 0.36
		var po := Vector3(cos(pa), 0, sin(pa))
		kit.panel(Transform3D(Basis.looking_at(-po, Vector3.UP), ac + po * (wr1 + 0.02) + Vector3.UP * 2.4), 1.4, 2.1, "affiche70_tournoi", "boisb70")
	var bx: Transform3D = ax * T(5.4, 0, 24.2)
	kit.box(bx * T(0, 1.3, -0.8), Vector3(2.2, 2.6, 1.4), "boisb70", 1.2)
	kit.col_box(bx * T(0, 1.3, -0.8), Vector3(2.2, 2.6, 1.4))
	counter70(bx * T(0, 0, 0.2), 2.2)
	kit.box(bx * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(0, 2.9, 0.0)), Vector3(2.8, 0.05, 2.2), "tissu70_rouge", 1.0)
	c._pt("ar_guichet", bx * Vector3(0, 0.05, 1.6))
	c._spot("arene_guichet", bx * Vector3(0, 0.05, -0.45), ax.basis * Vector3(0, 0, 1), "comptoir", "ar_guichet")
	c.lanterns["arene"] = kit.great_lantern(ax * Vector3(-6.0, 0, 25.0))
	for s5 in [-1.0, 1.0]:
		kit.lamp70(ax * Vector3(s5 * 3.4, 0, 23.5), 4.4, true, true)
		kit.lamp70(ax * Vector3(s5 * 3.4, 0, -23.5), 4.2, true, false)
	# les points : dehors, la porte, le sable ; la porte de derrière (les combattants)
	c._pt("ar_dehors", ax * Vector3(0, 0.05, 25.5))
	c._pt("ar_porte", ax * Vector3(0, 0.05, 18.0))
	c._pt("ar_sable", ax * Vector3(0, 0.05, 6.0))
	c._pt("ar_arriere", ax * Vector3(0, 0.05, -18.0))
	c._pt("ar_derriere", ax * Vector3(0, 0.05, -25.0))
	c._chain(["ar_guichet", "ar_dehors", "ar_porte", "ar_sable", "ar_arriere", "ar_derriere"])
	c._spot("arene_entree", ax * Vector3(-2.0, 0.05, 20.2), ax.basis * Vector3(0, 0, 1), "bras_croises", "ar_porte")
	c._spot("arene_sable", ax * Vector3(0.0, 0.05, 1.0), ax.basis * Vector3(0, 0, 1), "bras_croises", "ar_sable")
	# les places sur les gradins (le tiers bas, à droite et à gauche de la grande porte)
	var seats := [[0.75, 2, "assis"], [0.95, 3, "assis"], [-0.8, 2, "assis"], [1.2, 4, "acclamer"], [-1.05, 4, "acclamer"], [-1.35, 5, "acclamer"]]
	for i2 in range(seats.size()):
		var sa: float = main_a + float(seats[i2][0])
		var tier: int = int(seats[i2][1])
		var so := Vector3(cos(sa), 0, sin(sa))
		var rr: float = 11.6 + tier * 1.0 + (0.3 if str(seats[i2][2]) == "assis" else 0.5)
		var sp: Vector3 = ac + so * rr + Vector3.UP * (1.7 + (tier + 1) * 0.5 + 0.05)
		c._spot("arene_gradin_%d" % (i2 + 1), sp, -so, str(seats[i2][2]), "ar_porte")
		(arena["gradins"] as Array).append(sp)
	_zone("braise_arene", ax, Vector3(0, 6.0, 0), Vector3(22.5, 9.0, 22.5))
	c._avoid(ac, 25.0)


# =================================================================== les Thermes de Soufre

func thermes() -> void:
	var y: float = c.BY
	var tf: Transform3D = c.PX(96.0, 133.0, y, "in")
	kit.hall70(tf, 22.0, 10.0, {"h": 8.0, "wall": "pgoth70_clair", "inner": "mrouge70", "floor_key": "mosaique70", "door_w": 2.8, "door_h": 3.6,
		"roof": "cuivre70", "pitch": 48.0, "lights": 2, "energy": 1.5, "back_door": true, "trim": "pgoth70", "buttresses": false})
	_zone("braise_thermes", tf, Vector3(0, 4.0, -5.0), Vector3(10.4, 4.5, 4.4))
	kit.shop_sign(tf * T(9.0, 4.4, 0.0), "enseigne70_thermes", 1.4, 0.7)
	# le comptoir de Bulle
	var cx: Transform3D = tf * T(-6.0, 0.1, -6.0)
	counter70(cx, 3.0)
	for k in range(5):
		kit.cyl(Transform3D(Basis(), cx * Vector3(-1.2 + k * 0.6, 1.1, 0.0)), 0.05, 0.04, 0.18, "lueur70_or" if k % 2 == 0 else "glace70", 8)
	c._pt("th_hall", tf * Vector3(0, 0.15, -4.0))
	c._spot("thermes_comptoir", cx * Vector3(0, 0.05, -0.75), tf.basis * Vector3(0, 0, 1), "comptoir", "th_hall")
	# la cour, le bassin d'eau soufrée
	var px: Transform3D = tf * T(0, 0, -25.0)
	var pw: float = 15.0
	var pd: float = 17.0
	for s in [-1.0, 1.0]:
		kit.box(px * T(s * (pw * 0.5 + 0.3), 0.35, 0), Vector3(0.6, 0.7, pd + 1.2), "mnoir70", 1.2)
		kit.col_box(px * T(s * (pw * 0.5 + 0.3), 0.35, 0), Vector3(0.6, 0.7, pd + 1.2))
		kit.box(px * T(0, 0.35, s * (pd * 0.5 + 0.3)), Vector3(pw, 0.7, 0.6), "mnoir70", 1.2)
		kit.col_box(px * T(0, 0.35, s * (pd * 0.5 + 0.3)), Vector3(pw, 0.7, 0.6))
	kit.box(px * T(0, 0.04, 0), Vector3(pw, 0.06, pd), "mosaique70", 3.0, 4)
	kit.quad(px * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.55, 0)), pw, pd, "eau70", Vector2(0, 0), Vector2(pw / 4.0, pd / 4.0))
	pool = {"c": px * Vector3(0, 0.55, 0), "size": Vector2(pw, pd), "xf": px}
	for k2 in range(6):
		vapeur.append(px * Vector3(-5.0 + (k2 % 3) * 5.0, 0.6, -4.0 + (k2 / 3) * 8.0))
	# les colonnades autour de la cour, un toit en appentis
	for s2 in [-1.0, 1.0]:
		for k3 in range(5):
			var z: float = -8.0 + k3 * 4.0
			kit.column(px * T(s2 * 11.0, 0, z), 0.32, 4.4, "pgoth70_clair", "pgoth70")
		kit.box(px * Transform3D(Basis(Vector3.BACK, s2 * 0.25), Vector3(s2 * 12.3, 4.7, 0)), Vector3(3.6, 0.12, 20.0), "tuile70", 2.0)
		kit.box(px * T(s2 * 14.0, 2.4, 0), Vector3(0.6, 4.8, 20.0), "pgoth70_clair", 2.4)
		kit.col_box(px * T(s2 * 14.0, 2.4, 0), Vector3(0.6, 4.8, 20.0))
	kit.box(px * T(0, 2.6, -10.3), Vector3(28.6, 5.2, 0.6), "pgoth70_clair", 2.4)
	kit.col_box(px * T(0, 2.6, -10.3), Vector3(28.6, 5.2, 0.6))
	# au fond, trois têtes de démon crachent de l'eau chaude
	for k4 in range(3):
		var hp: Vector3 = px * Vector3(-5.0 + k4 * 5.0, 2.2, -9.9)
		kit.ball(Transform3D(Basis(), hp), 0.42, "bronze70", 10, 5)
		for s3 in [-1.0, 1.0]:
			kit.horn(hp + px.basis * Vector3(s3 * 0.25, 0.3, 0.0), px.basis * Vector3(s3 * 0.6, 0.8, 0.2), 0.55, 0.08, 2.0, "bronze70", 4)
		kit.box(Transform3D(px.basis * Basis(Vector3.RIGHT, 0.9), hp + px.basis * Vector3(0, -0.5, 1.0)), Vector3(0.3, 0.04, 1.6), "eau70", 1.0)
		vapeur.append(hp + px.basis * Vector3(0, -0.8, 1.6))
	c._pt("th_cour", tf * Vector3(0, 0.05, -12.5))
	c._pt("th_bord", px * Vector3(-pw * 0.5 - 1.6, 0.05, 2.0))
	c._spot("thermes_bain_1", px * Vector3(2.0, 0.08, 1.5), px.basis * Vector3(0, 0, 1), "allonge", "th_bord")
	c._spot("thermes_bain_2", px * Vector3(-pw * 0.5 - 0.3, 0.75, -3.0), px.basis * Vector3(1, 0, 0), "assis", "th_bord")
	c._pt("th_porte", tf * Vector3(0, 0.05, 2.6))
	c._chain(["th_porte", "th_hall", "th_cour", "th_bord"])
	c.lanterns["thermes"] = kit.great_lantern(tf * Vector3(-7.5, 0, 4.0))
	for s4 in [-1.0, 1.0]:
		kit.lamp70(tf * Vector3(s4 * 3.6, 0, 3.0), 3.9, true, false)
	_zone("braise_thermes", px, Vector3(0, 3.0, 0), Vector3(14.0, 4.0, 10.5))
	c._avoid(tf * Vector3(0, 0, -20.0), 24.0)


# =================================================================== les Jardins de Cendre

func jardins() -> void:
	var y: float = c.BY
	var gc: Vector3 = R.W(R.GARDENS.x, R.GARDENS.y, y)
	var gx := Transform3D(Basis.looking_at(c.radial(118.0), Vector3.UP), gc)        # +Z : vers la ville
	var gr: float = R.GARDENS_R - 1.0
	# la grille, deux portails
	var n: int = 40
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var am: float = (a0 + a1) * 0.5
		var lz: Vector3 = Vector3(cos(am), 0, sin(am))
		if absf((gx.basis.inverse() * lz).x) < 0.12:
			continue
		kit.railing70(gc + Vector3(cos(a0), 0, sin(a0)) * gr, gc + Vector3(cos(a1), 0, sin(a1)) * gr, 1.2)
	for s in [-1.0, 1.0]:
		for s2 in [-1.0, 1.0]:
			var pp: Vector3 = gx * Vector3(s2 * 1.8, 0, s * gr)
			kit.box(Transform3D(gx.basis, pp + Vector3.UP * 1.3), Vector3(0.5, 2.6, 0.5), "pgoth70", 1.0)
			kit.col_box(Transform3D(gx.basis, pp + Vector3.UP * 1.3), Vector3(0.5, 2.6, 0.5))
			kit.place("lanterne", Transform3D(Basis(), pp + Vector3.UP * 2.6))
	# les allées (deux allées en croix), la mare de lave et son pont, les massifs
	kit.box(gx * T(0, 0.03, 0), Vector3(2.6, 0.05, gr * 2.0), "paves70", 2.0, 4)
	kit.box(gx * T(0, 0.03, 0), Vector3(gr * 2.0, 0.05, 2.6), "paves70", 2.0, 4)
	var pond: Vector3 = gx * Vector3(-8.5, 0, -6.0)
	kit.ring(Transform3D(Basis(), pond), 3.2, 3.8, 0.45, "pgoth70_sombre", 28)
	kit.disc(Transform3D(Basis(), pond + Vector3.UP * 0.25), 3.25, "lave70", 28, 1.0)
	kit.col_cyl(pond, 3.8, 0.45)
	kit.fires70.append([pond + Vector3.UP * 0.3, 0.3])
	var massifs := [Vector3(6.5, 0, 6.5), Vector3(-6.5, 0, 6.5), Vector3(7.0, 0, -6.8), Vector3(-3.5, 0, 12.5), Vector3(4.0, 0, -13.0), Vector3(13.0, 0, 0.5)]
	for m in massifs:
		var mp: Vector3 = gx * (m as Vector3)
		kit.ring(Transform3D(Basis(), mp), 2.0, 2.35, 0.35, "pgoth70", 20)
		kit.disc(Transform3D(Basis(), mp + Vector3.UP * 0.3), 2.0, "boue70", 20, 2.0)
		garden_spots.append(mp + Vector3.UP * 0.3)
	# un kiosque de fer (une pergola ronde), des bancs, des arbres
	var kp: Vector3 = gx * Vector3(-9.0, 0, 7.5)
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0
		kit.cyl(Transform3D(Basis(), kp + Vector3(cos(a2) * 2.4, 0, sin(a2) * 2.4)), 0.06, 0.06, 2.8, "fer70", 6)
		kit.beam(kp + Vector3(cos(a2) * 2.4, 2.8, sin(a2) * 2.4), kp + Vector3.UP * 3.8, 0.05, "fer70")
	kit.ring(Transform3D(Basis(), kp + Vector3.UP * 2.75), 2.35, 2.45, 0.08, "fer70", 18)
	kit.bench70(Transform3D(gx.basis * Basis(Vector3.UP, PI * 0.5), kp + gx.basis * Vector3(-1.0, 0, 0)))
	for s3 in [-1.0, 1.0]:
		c.tree_spots.append(gx * Vector3(s3 * 13.5, 0, -9.0))
		c.tree_spots.append(gx * Vector3(s3 * 4.0, 0, 16.5))
	c.tree_spots.append(gx * Vector3(12.0, 0, 11.0))
	var bench: Transform3D = Transform3D(gx.basis * Basis(Vector3.UP, PI), gx * Vector3(3.2, 0, 2.6))
	kit.bench70(bench)
	c._pt("ja_porte", gx * Vector3(0, 0.05, gr + 1.5))
	c._pt("ja_centre", gx * Vector3(1.6, 0.05, 1.6))
	c._pt("ja_fond", gx * Vector3(0, 0.05, -gr - 1.5))
	c._chain(["ja_porte", "ja_centre", "ja_fond"])
	c._spot("jardin_banc", bench * Vector3(0, 0.5, 0.0), bench.basis * Vector3(0, 0, 1), "assis", "ja_centre")
	c._spot("jardin_massif_1", gx * (massifs[0] as Vector3) + gx.basis * Vector3(-1.6, 0.05, -1.6), gx.basis * Vector3(1, 0, 1), "jardiner", "ja_centre")
	c._spot("jardin_massif_2", gx * (massifs[2] as Vector3) + gx.basis * Vector3(-1.6, 0.05, 1.6), gx.basis * Vector3(1, 0, -1), "jardiner", "ja_centre")
	c._avoid(gc, gr + 1.0)


# =================================================================== la placette des Artisans

func artisans() -> void:
	var y: float = c.BY
	var sq: Vector3 = c.PW(180.0, 146.0, y)
	# l'atelier de couture (Grisette), le polisseur de cornes (Tiburce), l'atelier de l'inventeur (Zigomar)
	var cou: Transform3D = c.PX(185.6, 146.0, y, "ccw")
	kit.house70(cou, 10.0, 7.0, {"floors": 3, "wall": "erouge70_pourpre", "roof": "ardoise70", "gable": true, "shop": "couture", "lit": 0.7, "door_x": -2.4, "balcony": 2})
	kit.box(cou * T(1.8, 0.03, 2.0), Vector3(2.4, 0.04, 1.8), "tissu70_rouge", 1.0, 4)
	kit.box(cou * T(3.3, 0.9, 1.6), Vector3(0.12, 1.8, 0.12), "boisb70", 1.0)
	kit.box(cou * T(3.3, 1.9, 1.6), Vector3(0.5, 0.6, 0.35), "tissu70_noir", 1.0)
	c._spot("atelier_couture", cou * Vector3(1.8, 0.05, 2.2), cou.basis * Vector3(0, 0, 1), "tisser", "art_c")
	var bar: Transform3D = c.PX(174.4, 146.0, y, "cw")
	kit.house70(bar, 9.0, 7.0, {"floors": 3, "wall": "bnoire70", "roof": "tuile70", "gable": true, "shop": "barbier", "lit": 0.6, "door_x": 2.2})
	var chair: Transform3D = bar * T(-1.6, 0, 2.2)
	kit.box(chair * T(0, 0.3, 0), Vector3(0.7, 0.6, 0.7), "fer70", 1.0)
	kit.box(chair * T(0, 0.65, 0), Vector3(0.75, 0.12, 0.75), "tissu70_rouge", 1.0)
	kit.box(chair * T(0, 1.2, -0.33), Vector3(0.75, 1.0, 0.1), "tissu70_rouge", 1.0)
	kit.col_box(chair * T(0, 0.6, 0), Vector3(0.75, 1.2, 0.75))
	kit.box(bar * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(-1.6, 3.2, 1.4)), Vector3(3.0, 0.05, 2.6), "tissu70_rouge", 1.0)
	c._spot("barbier", chair * Vector3(0.0, 0.05, -1.0), bar.basis * Vector3(0, 0, 1), "bricoler", "art_c")
	var inv: Transform3D = c.PX(180.0, 155.5, y, "in")
	kit.house70(inv, 12.0, 8.0, {"floors": 3, "wall": "pgoth70", "roof": "cuivre70", "gable": false, "shop": "inventeur", "lit": 0.8, "door_x": -3.0, "chimney": true})
	kit.tower70(inv * Vector3(4.8, 0, -3.5), 2.4, 14.5, {"roof": "none", "windows": [6.0, 10.0], "nwin": 2, "lit": 0.9, "crown": true, "wall": "bnoire70"})
	kit.telescope(Transform3D(Basis(), inv * Vector3(4.8, 15.4, -3.5)), 0.8)
	# l'établi de Zigomar, ses fusées, ses engrenages
	var wb: Transform3D = inv * T(-0.5, 0, 2.6)
	kit.box(wb * T(0, 0.85, 0), Vector3(2.4, 0.08, 0.9), "boisb70", 1.0)
	kit.box(wb * T(0, 0.42, 0), Vector3(2.2, 0.84, 0.8), "boisb70", 1.0)
	kit.col_box(wb * T(0, 0.45, 0), Vector3(2.4, 0.9, 0.9))
	for k in range(3):
		kit.cyl(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), wb * Vector3(-0.7 + k * 0.55, 1.05, 0.1)), 0.18 - k * 0.04, 0.18 - k * 0.04, 0.05, "bronze70", 10)
	for k2 in range(5):
		var rp: Vector3 = inv * Vector3(2.6 + k2 * 0.5, 0, 2.2)
		kit.cyl(Transform3D(Basis(), rp), 0.02, 0.02, 1.4, "boisb70", 4)
		kit.cyl(Transform3D(Basis(), rp + Vector3.UP * 1.4), 0.08, 0.08, 0.5, ["tissu70_rouge", "tissu70_or", "tissu70_bleu"][k2 % 3], 8)
		kit.cyl(Transform3D(Basis(), rp + Vector3.UP * 1.9), 0.08, 0.0, 0.22, "fer70", 8)
	c._spot("atelier_inventeur", wb * Vector3(0, 0.05, -0.8), inv.basis * Vector3(0, 0, 1), "bricoler", "art_c")
	# la placette : une grosse enclume de bronze sur un socle (le monument des Artisans), des bancs
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), sq), 1.2, 1.0, 1.0, "pgoth70", 8)
	kit.box(Transform3D(Basis(), sq + Vector3.UP * 1.35), Vector3(0.8, 0.7, 0.5), "bronze70", 1.0)
	kit.box(Transform3D(Basis(), sq + Vector3.UP * 1.85), Vector3(1.7, 0.3, 0.6), "bronze70", 1.0)
	kit.col_cyl(sq, 1.2, 2.0)
	kit.lamp70(sq + c.tangent(180.0) * 4.5, 3.9, true, false)
	c._pt("art_c", c.PW(180.0, 142.0, y + 0.05))
	c._avoid(sq, 12.0)


# =================================================================== le chenil

func chenil() -> void:
	var y: float = c.BY
	var cc: Vector3 = c.PW(-165.0, 170.5, y)
	var cx := Transform3D(Basis.looking_at(c.radial(-165.0), Vector3.UP), cc)      # +Z : vers la ville
	var hw: float = 5.2
	var hd: float = 7.0
	for e in [[Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd)], [Vector3(-hw, 0, -hd), Vector3(-hw, 0, hd)], [Vector3(hw, 0, -hd), Vector3(hw, 0, hd)],
			[Vector3(-hw, 0, hd), Vector3(-1.2, 0, hd)], [Vector3(1.2, 0, hd), Vector3(hw, 0, hd)]]:
		kit.railing70(cx * (e[0] as Vector3), cx * (e[1] as Vector3), 1.3)
	for k in range(3):
		var kx: Transform3D = cx * T(-3.0 + k * 3.0, 0, -5.2)
		kit.box(kx * T(0, 0.6, 0), Vector3(1.8, 1.2, 1.6), "boisb70", 1.0)
		kit.roof_gable(kx * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 1.2, 0)), 1.6, 1.8, 45.0, 0.15, "tuile70", "boisb70")
		kit.ogive_face(kx * T(0, 0.0, 0.81), 0.7, 0.9, "fenetrenoire70", 3)
		kit.col_box(kx * T(0, 0.8, 0), Vector3(1.8, 1.6, 1.6))
	# les écuelles, un os de cuir, une balle
	for k2 in range(3):
		kit.cyl(Transform3D(Basis(), cx * Vector3(-3.0 + k2 * 3.0, 0, -3.6)), 0.22, 0.18, 0.1, "fer70", 10)
	kit.ball(cx * T(2.0, 0.15, 2.0), 0.15, "tissu70_rouge", 8, 4)
	for k3 in range(3):
		puppies.append([cx * Vector3(-2.5 + k3 * 2.4, 0.0, -1.0 + (k3 % 2) * 2.0), -deg_to_rad(-165.0) + k3 * 1.3])
	kit.lamp70(cx * Vector3(-2.0, 0, hd + 1.0), 3.9, true, false)
	c._pt("chenil_porte", cx * Vector3(0, 0.05, hd + 1.8))
	c._pt("chenil_c", cx * Vector3(0, 0.05, 1.0))
	c._chain(["chenil_porte", "chenil_c"])
	c._spot("chenil", cx * Vector3(0.8, 0.05, -1.5), cx.basis * Vector3(-0.3, 0, -1), "jouer", "chenil_c")
	c._avoid(cc, 9.0)


# =================================================================== la Rade de Cendre

func port() -> void:
	# les murs des quais (le long du bassin, du côté de la terre), leurs bornes d'amarrage
	var a0: float = 66.0
	var a1: float = 204.0
	var n: int = 46
	for k in range(n):
		var t0: float = lerpf(a0, a1, float(k) / n)
		var t1: float = lerpf(a0, a1, float(k + 1) / n)
		var p0: Vector3 = HP(t0, R.HARBOR_R + 0.6)
		var p1: Vector3 = HP(t1, R.HARBOR_R + 0.6)
		var mid: Vector3 = (p0 + p1) * 0.5
		var bs := Basis(Vector3.UP, atan2((p1 - p0).x, (p1 - p0).z))
		kit.box(Transform3D(bs, Vector3(mid.x, (R.QUAY_Y - 8.0) * 0.5 + 0.0, mid.z)), Vector3(1.6, R.QUAY_Y + 8.0, p0.distance_to(p1) + 0.05), "basalte70", 2.0, 63 - 8)
		kit.box(Transform3D(bs, Vector3(mid.x, R.QUAY_Y + 0.08, mid.z)), Vector3(1.9, 0.18, p0.distance_to(p1) + 0.06), "pgoth70_sombre", 1.2)
		kit.col_box(Transform3D(bs, Vector3(mid.x, R.QUAY_Y - 4.0, mid.z)), Vector3(1.6, 8.0, p0.distance_to(p1)))
		if k % 3 == 1:
			var bp: Vector3 = HP((t0 + t1) * 0.5, R.HARBOR_R + 1.0, R.QUAY_Y + 0.15)
			kit.cyl(Transform3D(Basis(), bp), 0.2, 0.16, 0.6, "fer70", 10)
			kit.cyl(Transform3D(Basis(), bp + Vector3.UP * 0.6), 0.24, 0.24, 0.1, "fer70", 10)
			kit.col_cyl(bp, 0.22, 0.7)
		if k % 4 == 2:
			kit.lamp70(HP((t0 + t1) * 0.5, R.HARBOR_R + 2.6, R.QUAY_Y), 3.9, true, false)
	# la jetée du phare (un môle de basalte), le phare
	var j0: float = 64.0
	var j1: float = 47.0
	for k2 in range(6):
		var u0: float = lerpf(j0, j1, float(k2) / 6.0)
		var u1: float = lerpf(j0, j1, float(k2 + 1) / 6.0)
		var q0: Vector3 = HP(u0, R.HARBOR_R + 3.0, R.QUAY_Y)
		var q1: Vector3 = HP(u1, R.HARBOR_R + 3.0, R.QUAY_Y)
		var qm: Vector3 = (q0 + q1) * 0.5
		var qb := Basis(Vector3.UP, atan2((q1 - q0).x, (q1 - q0).z))
		kit.box(Transform3D(qb, Vector3(qm.x, (R.QUAY_Y - 8.4) * 0.5 - 0.05, qm.z)), Vector3(6.0, R.QUAY_Y + 8.4, q0.distance_to(q1) + 0.1), "basalte70", 2.0, 63 - 8)
		kit.box(Transform3D(qb, Vector3(qm.x, R.QUAY_Y - 0.02, qm.z)), Vector3(5.6, 0.06, q0.distance_to(q1) + 0.1), "paves70", 2.0, 4)
		kit.col_box(Transform3D(qb, Vector3(qm.x, (R.QUAY_Y - 8.4) * 0.5, qm.z)), Vector3(6.0, R.QUAY_Y + 8.4, q0.distance_to(q1)))
		var side: Vector3 = qb * Vector3(-3.0, 0, 0)
		kit.parapet70(Vector3(q0.x, R.QUAY_Y, q0.z) + side, Vector3(q1.x, R.QUAY_Y, q1.z) + side, 0.9, 0.5, "basalte70")
		if k2 % 2 == 1:
			kit.lamp70(Vector3(qm.x, R.QUAY_Y, qm.z) - side * 0.6, 3.9, true, false)
	var ph: Vector3 = R.W(292.0, -214.0, R.QUAY_Y)
	kit.tower70(ph, 3.4, 17.0, {"roof": "none", "windows": [4.0, 9.0, 13.0], "nwin": 2, "lit": 0.6, "wall": "pgoth70_clair", "crown": true,
		"door_dir": (_hcenter - ph).normalized()})
	var lr: Vector3 = ph + Vector3.UP * 17.95
	for k3 in range(6):
		var a3: float = TAU * k3 / 6.0
		kit.cyl(Transform3D(Basis(), lr + Vector3(cos(a3) * 1.6, 0, sin(a3) * 1.6)), 0.06, 0.06, 2.4, "fer70", 6)
	kit.cyl(Transform3D(Basis(), lr + Vector3.UP * 2.4), 2.1, 0.2, 1.6, "cuivre70", 12)
	kit._finial(lr + Vector3.UP * 3.9, 0.8)
	phare_glass = MeshInstance3D.new()
	phare_glass.name = "Phare_feu"
	var gm := CylinderMesh.new()
	gm.top_radius = 1.4
	gm.bottom_radius = 1.4
	gm.height = 2.2
	gm.radial_segments = 12
	phare_glass.mesh = gm
	phare_glass.material_override = kit.mat("lueur70_rouge")
	phare_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kit.root.add_child(phare_glass)
	phare_glass.position = lr + Vector3.UP * 1.15
	phare_light = OmniLight3D.new()
	phare_light.light_color = Color(1.0, 0.25, 0.12)
	phare_light.light_energy = 3.0
	phare_light.omni_range = 40.0
	phare_light.omni_attenuation = 1.0
	phare_light.shadow_enabled = false
	kit.root.add_child(phare_light)
	phare_light.position = lr + Vector3.UP * 1.2
	if kit.temps != null and kit.temps.has_method("register_lamp"):
		kit.temps.register_lamp(phare_light, 3.0)
	c._pt("po_jetee", HP(63.0, R.HARBOR_R + 3.0, R.QUAY_Y + 0.05))
	c._pt("po_phare", ph + (_hcenter - ph).normalized() * 5.2 + Vector3.UP * 0.05)
	c._spot("port_phare", ph + (_hcenter - ph).normalized() * 4.4 + Vector3.UP * 0.05, (_hcenter - ph), "observer", "po_phare")
	# la taverne « Au Diable Repu »
	var tx: Transform3D = HX(158.0, 60.5, "in")
	kit.hall70(tx, 16.0, 12.0, {"h": 6.4, "wall": "bnoire70", "inner": "boisb70", "floor_key": "boisb70", "door_w": 2.4, "door_h": 3.0,
		"roof": "tuile70", "pitch": 50.0, "lights": 2, "energy": 1.6, "trim": "pgoth70", "light_color": Color(1.0, 0.6, 0.3), "buttresses": false})
	_zone("braise_taverne", tx, Vector3(0, 3.0, -6.0), Vector3(7.4, 3.5, 5.4))
	kit.shop_sign(tx * T(-5.4, 4.0, 0.0), "enseigne70_taverne", 1.4, 0.7)
	kit.wall_lamp70(tx * T(3.2, 3.6, 0.02), true)
	var bar: Transform3D = tx * Transform3D(Basis(), Vector3(0, 0.1, -9.2))
	kit.bar_counter(bar, 6.0)
	c._pt("tav_porte", tx * Vector3(0, 0.05, 2.6))
	c._pt("tav_salle", tx * Vector3(0, 0.15, -4.0))
	c._spot("taverne_comptoir", bar * Vector3(0.0, 0.05, -0.9), tx.basis * Vector3(0, 0, 1), "comptoir", "tav_salle")
	c.objets["taverne_comptoir"] = bar * Vector3(0, 1.2, 0)
	for i in range(3):
		var tp: Vector3 = tx * Vector3(-4.6 + i * 4.6, 0.1, -4.4 + (i % 2) * 1.6)
		kit.dice_table(tp, 0.3 * i, 0.6)
		var sp: Vector3 = tp + tx.basis * Vector3(0.0, 0.0, 0.95)
		kit.box(Transform3D(tx.basis, sp + Vector3.UP * 0.22), Vector3(0.42, 0.44, 0.42), "boisb70", 1.0)
		c._spot("taverne_table_%d" % (i + 1), sp + Vector3.UP * 0.5, tx.basis * Vector3(0, 0, -1), "assis", "tav_salle")
	kit.fires70.append([tx * Vector3(7.0, 0.6, -10.6), 0.6])
	kit.box(tx * T(7.0, 1.2, -11.0), Vector3(2.4, 2.4, 1.0), "pgoth70_sombre", 1.2)
	kit.ogive_face(tx * T(7.0, 0.1, -10.48), 1.5, 1.6, "braise70", 4)
	c._chain(["tav_porte", "tav_salle"])
	# la capitainerie (Charbonnel), sa tour à signaux
	var cap: Transform3D = HX(112.0, 63.0, "in")
	kit.house70(cap, 9.0, 8.0, {"floors": 4, "wall": "pgoth70", "roof": "ardoise70", "gable": true, "shop": "capitainerie", "lit": 0.7, "door_x": -1.6, "banner": true})
	var ct: Vector3 = kit.tower70(cap * Vector3(5.6, 0, -2.0), 2.4, 15.0, {"roof": "cone", "roof_h": 5.0, "windows": [6.0, 11.0], "nwin": 3, "lit": 0.7})
	kit.flag69(Transform3D(Basis(), ct + Vector3.UP * 7.0), "banniere70", Vector2(1.2, 2.4))
	c._pt("po_capitainerie", cap * Vector3(-1.6, 0.05, 2.6))
	c._spot("port_capitainerie", cap * Vector3(0.6, 0.05, 1.8), cap.basis * Vector3(0, 0, 1), "observer", "po_capitainerie")
	# la poste ailée (Brindille) : un perchoir en haut d'un mât, le comptoir
	var pst: Transform3D = HX(178.0, 61.5, "in")
	kit.house70(pst, 9.0, 8.0, {"floors": 3, "wall": "erouge70", "roof": "tuile70", "gable": true, "shop": "poste", "lit": 0.7, "door_x": 2.2})
	var mast: Vector3 = pst * Vector3(-5.6, 0, 1.5)
	kit.cyl(Transform3D(Basis(), mast), 0.16, 0.12, 9.0, "boisb70", 8)
	kit.cyl(Transform3D(Basis(), mast + Vector3.UP * 9.0), 1.1, 1.1, 0.12, "boisb70", 10)
	kit.col_cyl(mast, 0.18, 9.0)
	var pc: Transform3D = pst * T(-1.4, 0, 2.0)
	counter70(pc, 2.2)
	kit.box(pc * T(0, 1.2, 0.0), Vector3(0.6, 0.12, 0.4), "contrat70", 1.0)
	c._pt("po_poste", pst * Vector3(-1.4, 0.05, 3.6))
	c._spot("poste", pc * Vector3(0, 0.05, -0.75), pst.basis * Vector3(0, 0, 1), "comptoir", "po_poste")
	# la poissonnerie (Moloka) : des étals sous un auvent, sur le quai
	var fx: Transform3D = HX(96.0, 58.0, "in")
	kit.house70(fx * T(0, 0, -4.0), 10.0, 6.0, {"floors": 2, "wall": "bnoire70", "roof": "tuile70", "gable": false, "shop": "poissonnerie", "lit": 0.6, "door_x": 3.0})
	stall70(fx * T(-2.0, 0, -1.2), "tissu70_bleu", "poisson")
	stall70(fx * T(1.4, 0, -1.2), "tissu70_rouge", "poisson")
	c._pt("po_poisson", fx * Vector3(-0.3, 0.05, 1.6))
	c._spot("port_poisson", fx * Vector3(-2.0, 0.05, -2.2), fx.basis * Vector3(0, 0, 1), "comptoir", "po_poisson")
	# des entrepôts, des caisses, des tonneaux, une grue
	for e in [[124.0, 76.0], [146.0, 80.0], [192.0, 70.0], [82.0, 72.0]]:
		var ex: Transform3D = HX(float(e[0]), float(e[1]), "in")
		kit.house70(ex, 13.0, 10.0, {"floors": 2, "wall": "bnoire70", "roof": "tuile70_sombre", "gable": true, "lit": 0.3, "door_x": 0.0, "chimney": false, "gf": 4.6, "v81": true})
	for k4 in range(14):
		var al: float = 100.0 + k4 * 7.0
		if absf(al - 135.0) < 6.0:
			continue
		var cp: Vector3 = HP(al, 54.5 + (k4 % 3) * 1.3)
		if k4 % 2 == 0:
			kit.crate(cp, k4 * 0.7, 0.8, true)
		else:
			kit.barrel(cp, true)
	kit.crane(Transform3D(Basis(Vector3.UP, deg_to_rad(-128.0)), HP(124.0, 52.4)), 7.0)
	# la Grande Lanterne du port, au pied de la rampe
	c.lanterns["port"] = kit.great_lantern(HP(141.0, 60.5))
	# les points des quais
	c._pt("po_rampe", HP(135.0, 57.5, R.QUAY_Y + 0.05))
	c._pt("po_quai_e", HP(112.0, 55.0, R.QUAY_Y + 0.05))
	c._pt("po_quai_e2", HP(90.0, 55.0, R.QUAY_Y + 0.05))
	c._pt("po_quai_w", HP(158.0, 55.0, R.QUAY_Y + 0.05))
	c._pt("po_quai_w2", HP(178.0, 55.0, R.QUAY_Y + 0.05))
	c._pt("po_quai_e3", HP(68.0, 55.5, R.QUAY_Y + 0.05))
	c._chain(["po_quai_w2", "po_quai_w", "po_rampe", "po_quai_e", "po_quai_e2", "po_quai_e3", "po_jetee", "po_phare"])
	c._link("po_quai_w", "tav_porte")
	c._link("po_quai_w2", "po_poste")
	c._link("po_quai_e", "po_capitainerie")
	c._link("po_quai_e2", "po_poisson")
	c._spot("port_quai_1", HP(150.0, 51.6, R.QUAY_Y + 0.05), HP(150.0, 40.0) - HP(150.0, 51.6), "pecher", "po_quai_w")
	c._spot("port_quai_2", HP(104.0, 52.6, R.QUAY_Y + 0.05), HP(104.0, 40.0) - HP(104.0, 52.6), "bras_croises", "po_quai_e")
	# les navires
	_navires()
	c._avoid(_hcenter, R.HARBOR_R + 32.0)


func _navires() -> void:
	var defs := [["braise", 1.0, 108.0, 40.5], ["fumeron", 0.62, 174.0, 42.0]]
	for d in defs:
		var sh: Node3D = Navire.new()
		sh.name = "Navire_%s_v70" % str(d[0])
		sh.setup68(str(d[0]), float(d[1]))
		kit.root.add_child(sh)
		var al: float = deg_to_rad(float(d[2]))
		var yaw: float = atan2(-cos(al), -sin(al))
		sh.place(HP(float(d[2]), float(d[3]), -2.8 * float(d[1])), yaw)
		sh.build(c.pc)
		ships[str(d[0])] = sh


# =================================================================== le réseau

func link_graph() -> void:
	# le marché : par la rue Basse et le chemin de ronde
	c._link("ma_n", c.nearest_ring("bi", -17.5))
	c._link("ma_e", c.nearest_ring("bo", -17.5))
	# l'arène : sa grande porte vers la rue Basse, sa porte de derrière vers le chemin de ronde
	c._link("ar_dehors", c.nearest_ring("bi", 68.0))
	c._link("ar_guichet", c.nearest_ring("bi", 68.0))
	c._link("ar_derriere", c.nearest_ring("bo", 68.0))
	# les thermes, les jardins
	c._link("th_porte", c.nearest_ring("bi", 96.0))
	c._link("ja_porte", c.nearest_ring("bi", 118.0))
	c._link("ja_fond", c.nearest_ring("bo", 118.0))
	# les artisans, le chenil
	c._link("art_c", c.nearest_ring("bi", 180.0))
	c._link("art_c", c.nearest_ring("bm", 168.75))
	c._link("chenil_porte", c.nearest_ring("bm", -165.0))
	c._link("chenil_porte", c.nearest_ring("bo", -165.0))
	# le port : la rampe de la porte du port jusqu'au quai
	c._pt("po_rampe_haut", c.PW(-45.0, R.PORT_RAMP.x + 0.5, c.BY + 0.05))
	c._chain(["av-45_porte", "po_rampe_haut", "po_rampe"])

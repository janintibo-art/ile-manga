extends Node3D
## V113 : la Cité des Nuées, posée sur l'île flottante (ile_nuees_v113). Une ville futuriste, réaliste
## et lumineuse : béton blanc, verre clair, bois blond, jardins partout, panneaux solaires, éoliennes.
##  - la GARE DES NUÉES (au sud-est) : la capsule de la Ligne des Nuées y arrive (nuees_ligne_v113),
##    sous une grande verrière blanche ; le guichet, les bancs ; et, au bout de l'allée, au bord de
##    l'île, le BELVÉDÈRE DE VERRE (un plancher de verre au-dessus du vide) ;
##  - l'ESPLANADE DU CIEL (au centre) : le miroir d'eau, la Plume de Séraphin (une sculpture d'acier
##    poli), les bancs, les arbres en bacs ; autour, le CAFÉ CUMULUS, l'ATELIER DES INVENTEURS, la
##    MAISON DU CONSEIL au pied de la TOUR DU ZÉNITH (une tour ronde et torsadée) ;
##  - les SERRES D'ALTITUDE (à l'est) : trois coupoles de verre ;
##  - l'INSTITUT DES VENTS (au nord) : son mât de mesure, ses éoliennes au bord de l'île, la SALLE DES
##    SUSTENTATEURS (un pavillon de verre et ses pupitres) ;
##  - le PORT DES NUÉES (à l'ouest) : un ponton dans le ciel, la capitainerie, « la Libellule » ;
##  - les RÉSIDENCES DES TERRASSES (au sud-ouest) : des immeubles en gradins couverts de jardins ;
##  - le PARC DES BRUMES (au nord-ouest) : les pelouses, l'étang, la Source (des capteurs de brume), le
##    ruisseau, et la CASCADE DES NUÉES qui tombe dans le vide ;
##  - la PROMENADE DU BORD (tout autour, le long d'un garde-corps de verre) et la NAVETTE CIRCULAIRE
##    (des cabines blanches suspendues à un rail, qui font le tour de la ville).
## Les points, le réseau et les lieux des habitants vont dans ceux de Hautefond (la ville d'en bas),
## pour que tout le monde puisse passer de l'un à l'autre par la capsule.

const R = preload("res://scripts/ile_nuees_v113.gd")
const Kit = preload("res://scripts/nuees_kit_v113.gd")
const NAV_PODS: int = 3

var main: Node
var ile: Node3D
var hf: Node3D                           # la ville de Hautefond (ses points, son réseau, ses lieux)
var kit
var pc: bool = true
var ligne: Node3D                        # nuees_ligne_v113
var objets: Dictionary = {}
var crowd_spots: Array = []
var serre_spots: Array = []
var flora_avoid: Array = []              # [Vector2 monde, rayon]
var doors: Dictionary = {}               # porte_<prénom> -> Vector3
var airship: Node3D
var airship_base := Transform3D.IDENTITY
var pods: Array = []                     # [Node3D, angle de départ]
var lights: Array = []                   # OmniLight3D (la nuit)
var fog_nets: Array = []
var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _gare := Vector3.ZERO
var _to_col := Vector3.ZERO
var _side := Vector3.ZERO


# =================================================================== repères

func G(lx: float, lz: float, dy: float = 0.0) -> Vector3:
	return R.W(lx, lz, float(ile.top_local(lx, lz)) + dy)


func PR(deg: float, r: float, dy: float = 0.0) -> Vector3:
	var l: Vector2 = R.polar(deg, r)
	return G(l.x, l.y, dy)


static func dirv(deg: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	return Vector3(cos(a), 0, sin(a))


## Un repère au sol, à l'angle deg et au rayon r, dont la façade (+Z) regarde le centre.
func XR(deg: float, r: float, dy: float = 0.0) -> Transform3D:
	return Transform3D(Basis.looking_at(dirv(deg), Vector3.UP), PR(deg, r, dy))


func rim(deg: float) -> float:
	return float(ile.coast_deg(deg))


func _pt(name: String, p: Vector3) -> String:
	return hf._pt(name, p)


func _link(a: String, b: String) -> void:
	hf._link(a, b)


func _chain(names: Array) -> void:
	hf._chain(names)


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	hf._spot(name, pos, face, pose, node)


func _avoid(p: Vector3, r: float) -> void:
	flora_avoid.append([Vector2(p.x, p.z), r])


# =================================================================== construction

func build(main_node: Node, island: Node3D, hf_city: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	hf = hf_city
	pc = high_quality
	_rng.seed = 11320
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	# la Ligne des Nuées (le quai du Belvédère, la cage, la capsule)
	ligne = load("res://scripts/nuees_ligne_v113.gd").new()
	ligne.name = "Ligne_des_Nuees_v113"
	add_child(ligne)
	ligne.build(main, kit, hf.colonne.top, ile, pc)
	_gare = ligne.top
	_to_col = ligne.to_col
	_side = _to_col.cross(Vector3.UP).normalized()
	_network()
	_gare_des_nuees()
	_belvedere_verre()
	_esplanade()
	_cafe()
	_atelier()
	_conseil()
	_serres()
	_institut()
	_port()
	_residences()
	_immeubles()
	_parc()
	_bord()
	_navette()
	_street_life()
	kit.commit()
	for ch in get_children():
		if ch is MeshInstance3D and (str(ch.name).contains("facade113") or str(ch.name).contains("beton113") or str(ch.name).contains("composite113") or str(ch.name).contains("solaire113")):
			(ch as GeometryInstance3D).visibility_range_end = 2600.0
	_lights()
	print("ILE_MANGA_V113: la Cité des Nuées est bâtie (%d ms, %d points)" % [Time.get_ticks_msec() - t0, hf.points.size()])


# =================================================================== le réseau des rues

const RG_R: float = 44.0
const ES_R: float = 13.0


func _network() -> void:
	# l'anneau de l'Esplanade, le boulevard, la Promenade du bord
	for k in range(8):
		_pt("nu_es_%d" % k, PR(45.0 * k, ES_R, 0.05))
	for k in range(8):
		_link("nu_es_%d" % k, "nu_es_%d" % ((k + 1) % 8))
	for k2 in range(16):
		_pt("nu_rg_%d" % k2, PR(22.5 * k2, RG_R, 0.05))
	for k2 in range(16):
		_link("nu_rg_%d" % k2, "nu_rg_%d" % ((k2 + 1) % 16))
	for k3 in range(24):
		var a: float = 15.0 * k3
		_pt("nu_pr_%d" % k3, PR(a, rim(a) - 8.5, 0.05))
	for k3 in range(24):
		_link("nu_pr_%d" % k3, "nu_pr_%d" % ((k3 + 1) % 24))
	# les allées : de l'Esplanade au boulevard (sauf vers le Conseil, au nord) ; du boulevard à la
	# Promenade (au sud, au sud-ouest, à l'ouest ; les autres passent par leurs lieux)
	for k4 in [0, 1, 2, 3, 4, 5, 7]:
		_link("nu_es_%d" % k4, "nu_rg_%d" % (k4 * 2))
	for k5 in [4, 6, 8]:
		_link("nu_rg_%d" % (k5), "nu_pr_%d" % (k5 / 2 * 3))


func _near_pt(p: Vector3, prefix: String = "nu_") -> String:
	var best: String = ""
	var bd: float = INF
	for k in hf.points:
		if not str(k).begins_with(prefix):
			continue
		var d: float = (hf.points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(k)
	return best


# =================================================================== la Gare des Nuées

func _gare_des_nuees() -> void:
	var g: Vector3 = _gare
	var tc: Vector3 = _to_col
	var sd: Vector3 = _side
	var bs := Basis.looking_at(-tc, Vector3.UP)      # +Z local : vers la Colonne (le sud-est)
	var c: Vector3 = g + tc * 6.0
	var xf := Transform3D(bs, c)
	# la verrière : un grand toit blanc mince sur six poteaux fins, trois bandes de verre
	var hroof: float = 7.6
	kit.box(xf * kit.T(0, hroof, 0), Vector3(22.0, 0.45, 17.0), "composite113", 2.0, 63 - 8)
	kit.box(xf * kit.T(0, hroof - 0.24, 0), Vector3(21.6, 0.04, 16.6), "bois113", 1.6, 8)
	for k in range(3):
		kit.box(xf * kit.T(-6.0 + k * 6.0, hroof + 0.26, 0), Vector3(3.0, 0.08, 14.0), "verre113", 1.0, 4 | 8)
	kit.box(xf * kit.T(0, hroof - 0.3, 8.6), Vector3(22.4, 0.3, 0.3), "acier113", 1.0)
	for sx in [-10.0, 10.0]:
		for sz in [-7.0, 0.5, 7.5]:
			kit.cyl(xf * kit.T(sx, 0, sz), 0.22, 0.16, hroof, "composite113", 10, false)
			kit.col_cyl(xf * Vector3(sx, 0, sz), 0.25, hroof)
	# le fond vitré (côté nord-ouest, derrière la cage), un mur bas de béton, l'enseigne
	kit.quad(xf * Transform3D(Basis(), Vector3(0, hroof * 0.5, -8.3)), 20.0, hroof - 0.5, "verre113", Vector2(0, 0), Vector2(1, 1), true)
	kit.box(xf * kit.T(0, 0.4, -8.3), Vector3(20.0, 0.8, 0.3), "beton113", 2.4)
	kit.col_box(xf * kit.T(0, hroof * 0.5, -8.3), Vector3(20.0, hroof, 0.3))
	kit.sign113(xf * kit.T(0, hroof - 1.4, 8.62), "gare", 5.0, 2.5)
	kit.sign113(Transform3D(bs * Basis(Vector3.UP, PI), c + bs * Vector3(0, hroof - 1.4, 8.5)), "ligne", 5.0, 2.5)
	kit.sign113(Transform3D(bs * Basis(Vector3.UP, PI), c + bs * Vector3(0, hroof - 1.4, -8.15)), "gare", 4.0, 2.0)
	# le guichet (un comptoir blanc, un écran), les bancs, des bacs
	var gx: Transform3D = xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(7.0, 0, -1.0))
	kit.box(gx * kit.T(0, 0.55, 0), Vector3(3.4, 1.1, 0.8), "composite113", 1.0)
	kit.box(gx * kit.T(0, 1.12, 0.05), Vector3(3.6, 0.05, 0.95), "bois113", 1.0)
	kit.box(gx * kit.T(0, 1.9, -0.25), Vector3(1.4, 0.8, 0.06), "acier113_sombre", 1.0)
	kit.col_box(gx * kit.T(0, 0.55, 0), Vector3(3.4, 1.1, 0.8))
	objets["gare_guichet"] = gx * Vector3(0, 0, 1.2)
	_pt("nu_g_guichet", gx * Vector3(0, 0.05, 1.4))
	_spot("gare_guichet", gx * Vector3(0, 0.05, -0.75), gx.basis * Vector3(0, 0, 1), "comptoir", "nu_g_guichet")
	for s in [-1.0, 1.0]:
		var bx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5 * s), Vector3(-7.0 * s if s < 0 else -7.0, 0, 3.0 + (s + 1.0) * 1.6))
		kit.bench113(bx, 2.4)
		if s < 0:
			_spot("gare_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_g_centre")
		else:
			crowd_spots.append(_crowd_spot("nu_gare_banc_2", bx, "nu_g_centre"))
	for s2 in [-1.0, 1.0]:
		kit.planter113(xf * kit.T(s2 * 9.0, 0, 7.8), 2.0, 2.0, true)
	# les points : le quai de la capsule, le milieu, la sortie (vers le Belvédère de Verre), les côtés
	_pt("nu_g_quai", ligne.quai_haut + Vector3.UP * 0.05)
	_pt("nu_g_centre", c + tc * 2.0 + Vector3.UP * 0.05)
	_pt("nu_g_sortie", c + tc * 9.5 + Vector3.UP * 0.05)
	_pt("nu_g_cote", g + sd * 4.6 + Vector3.UP * 0.05)
	_pt("nu_g_cote2", g - sd * 4.6 + Vector3.UP * 0.05)
	_chain(["nu_g_quai", "nu_g_centre", "nu_g_sortie"])
	_link("nu_g_centre", "nu_g_guichet")
	_chain(["nu_g_cote", "nu_g_quai", "nu_g_cote2"])
	_link("nu_g_cote", _near_pt(g + sd * 9.0))
	_link("nu_g_cote2", _near_pt(g - sd * 9.0))
	_link("nu_rg_2", "nu_g_cote")
	_link("nu_rg_2", "nu_g_cote2")
	_spot("gare_quai", ligne.quai_haut + sd * 2.4 + Vector3.UP * 0.05, -sd, "bras_croises", "nu_g_quai")
	objets["gare"] = c
	_avoid(c, 14.0)
	# la capsule : les points dedans (les habitants la prennent ; hautefond_v112._npc_lift)
	_pt("nu_cab_haut", ligne.top + Vector3.UP * 0.05)
	_pt("nu_cab_bas", ligne.foot + Vector3.UP * 0.05)
	_pt("nu_quai_bas", ligne.quai_bas + Vector3.UP * 0.05)
	_chain(["nu_g_quai", "nu_cab_haut", "nu_cab_bas", "nu_quai_bas"])
	if hf.points.has("belv_porte"):
		_pt("nu_belv_passage", hf.colonne.top + Vector3(_to_col.x, 0, _to_col.z) * -14.5 + Vector3.UP * 0.05)
		_chain(["nu_quai_bas", "nu_belv_passage", "belv_porte"])


func _crowd_spot(name: String, bx: Transform3D, node: String) -> String:
	_spot(name, bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", node)
	return name


# =================================================================== le Belvédère de Verre

func _belvedere_verre() -> void:
	var a: float = 45.0
	var rr: float = rim(a)
	var d: Vector3 = dirv(a)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	var r0: float = rr - 6.0
	var r1: float = rr + 13.0
	var y: float = R.Y0 + 0.08
	var mid: Vector3 = R.W(d.x * (r0 + r1) * 0.5, d.z * (r0 + r1) * 0.5, 0.0)
	mid.y = y
	var bs := Basis.looking_at(d, Vector3.UP)
	var len: float = r1 - r0
	# le plancher de verre (et son cadre d'acier), la sous-structure en porte-à-faux
	kit.box(Transform3D(bs, mid + Vector3.DOWN * 0.06), Vector3(9.6, 0.1, len), "sol113", 1.0)
	for s in [-1.0, 1.0]:
		kit.box(Transform3D(bs, mid + sd * s * 4.9 + Vector3.DOWN * 0.15), Vector3(0.3, 0.3, len), "acier113", 1.0)
	for k in range(int(len / 3.0) + 1):
		var p: Vector3 = R.W(d.x * (r0 + k * 3.0), d.z * (r0 + k * 3.0), 0.0)
		p.y = y - 0.15
		kit.box(Transform3D(bs, p), Vector3(9.8, 0.24, 0.18), "acier113", 1.0)
	for s2 in [-1.0, 1.0]:
		var a0: Vector3 = R.W(d.x * (rr + 1.0), d.z * (rr + 1.0), -6.0) + sd * s2 * 3.6
		var a1: Vector3 = R.W(d.x * (r1 - 1.0), d.z * (r1 - 1.0), -0.3) + sd * s2 * 3.6
		kit.beam(a0, a1, 0.45, "acier113")
	kit.col_box(Transform3D(bs, mid + Vector3.DOWN * 0.15), Vector3(9.8, 0.3, len))
	# les garde-corps de verre (les deux côtés, au bout)
	for s3 in [-1.0, 1.0]:
		kit.glass_rail113(R.W(d.x * (rr - 4.0), d.z * (rr - 4.0), 0) + Vector3.UP * (y - R.Y0) + sd * s3 * 4.9, R.W(d.x * r1, d.z * r1, 0) + Vector3.UP * (y - R.Y0) + sd * s3 * 4.9, 1.2)
	var e: Vector3 = R.W(d.x * r1, d.z * r1, 0) + Vector3.UP * (y - R.Y0)
	kit.glass_rail113(e + sd * 4.9, e - sd * 4.9, 1.2)
	# les points et les lieux
	_pt("nu_bv_bord", PR(a, rr - 8.5, 0.05))
	_pt("nu_bv_bout", R.W(d.x * (r1 - 3.0), d.z * (r1 - 3.0), 0) + Vector3.UP * (y - R.Y0 + 0.05))
	_chain(["nu_g_sortie", "nu_bv_bord", "nu_bv_bout"])
	_link("nu_bv_bord", "nu_pr_3")
	for s4 in [-1.0, 1.0]:
		var sp: Vector3 = R.W(d.x * (r1 - 1.4), d.z * (r1 - 1.4), 0) + Vector3.UP * (y - R.Y0 + 0.05) + sd * s4 * 2.4
		_spot("belvedere_verre_%d" % (1 if s4 < 0 else 2), sp, d, "observer", "nu_bv_bout")
	objets["belvedere_verre"] = mid
	_bv_gap = [a, 3.0]


var _bv_gap: Array = []


# =================================================================== l'Esplanade du Ciel

func _esplanade() -> void:
	var c: Vector3 = G(0, 0)
	# le miroir d'eau : un bassin bas de béton blanc, l'eau qui affleure
	var pr: float = 9.0
	kit.ring(Transform3D(Basis(), c), pr, pr + 0.7, 0.32, "beton113", 48)
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.04), pr, "beton113_gris", 48)
	for k in range(24):
		var a0: float = TAU * k / 24.0
		var a1: float = TAU * (k + 1) / 24.0
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * (pr + 0.35)
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * (pr + 0.35)
		kit.col_box(Transform3D(Basis(Vector3.UP, atan2(p1.x - p0.x, p1.z - p0.z)), (p0 + p1) * 0.5 + Vector3.UP * 0.16), Vector3(0.7, 0.32, p0.distance_to(p1) + 0.05))
	var wm := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = pr
	cm.bottom_radius = pr
	cm.height = 0.02
	cm.radial_segments = 48
	wm.mesh = cm
	wm.material_override = kit.mat("eau113")
	add_child(wm)
	wm.global_position = c + Vector3.UP * 0.25
	# la Plume de Séraphin : une plume d'acier poli, haute de douze mètres, penchée par le vent
	_plume(c + Vector3.UP * 0.2)
	kit.col_cyl(c, 0.6, 3.0)
	# les bancs face au bassin, des bacs avec des arbres, des lampadaires
	for i in range(4):
		var ab: float = 22.5 + 90.0 * i
		var bx: Transform3D = XR(ab, 16.0)
		kit.bench113(bx, 2.4)
		_spot("esplanade_banc_%d" % (i + 1), bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_es_%d" % (int(round(ab / 45.0)) % 8))
	for i2 in range(8):
		var ap: float = 22.5 + 45.0 * i2
		if i2 % 2 == 0:
			continue
		kit.planter113(XR(ap, 20.5), 2.2, 2.2, true, 0.55)
	for i3 in range(8):
		var al: float = 45.0 * i3 + 12.0
		kit.lamp113(PR(al, 23.5), deg_to_rad(-al - 90.0), 4.8, i3 % 2 == 0)
	_spot("esplanade_fontaine", PR(112.5, 10.6, 0.05), -dirv(112.5), "debout", "nu_es_2")
	objets["esplanade"] = c
	objets["plume"] = c
	_avoid(c, 26.0)


func _plume(base: Vector3) -> void:
	var n: int = 22
	var spine: Array = []
	for i in range(n + 1):
		var t: float = float(i) / n
		spine.append(base + Vector3(sin(t * 1.4) * 2.2, t * 12.0, sin(t * 2.0) * 0.6))
	for i2 in range(n):
		var a: Vector3 = spine[i2]
		var b: Vector3 = spine[i2 + 1]
		var t2: float = float(i2) / n
		kit.beam(a, b, lerpf(0.22, 0.05, t2), "miroir113")
		if t2 > 0.12:
			var w: float = sin((t2 - 0.12) / 0.88 * PI) * 1.4 + 0.15
			var tang: Vector3 = (b - a).normalized()
			var side: Vector3 = tang.cross(Vector3(0.3, 0, 1).normalized()).normalized()
			for s in [-1.0, 1.0]:
				var p0: Vector3 = a
				var p1: Vector3 = b
				var p2: Vector3 = b + side * s * w + Vector3.DOWN * w * 0.35
				var p3: Vector3 = a + side * s * w + Vector3.DOWN * w * 0.35
				var nm: Vector3 = (p1 - p0).cross(p3 - p0).normalized()
				kit.quad4("miroir113", p0, p1, p2, p3, nm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
				kit.quad4("miroir113", p0, p3, p2, p1, -nm, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0))


# =================================================================== le Café Cumulus

func _cafe() -> void:
	var a: float = 67.5
	var xf: Transform3D = XR(a, 30.0)
	var door: Vector3 = kit.tower113(xf, 14.0, 10.0, 1, {"gf": 4.4, "toit": "jardin", "boutique": "cumulus", "balcons": ["av"], "tous_balcons": true})
	doors["porte_gustave"] = door
	# la terrasse : une toile tendue, quatre tables, le comptoir (le kiosque, dehors)
	var tf: Transform3D = xf * kit.T(0, 0, 5.0)
	kit.canopy113(tf, 12.0, 6.5, 3.2, "toile113_bleu")
	var tables: Array = [Vector3(-3.6, 0, -0.8), Vector3(0.4, 0, 1.4), Vector3(3.8, 0, -0.6)]
	for i in range(tables.size()):
		var tp: Vector3 = tf * (tables[i] as Vector3)
		var yaw: float = float(i) * 0.7
		kit.cafe_table(tp, yaw, 2)
		var cp: Vector3 = tp + Basis(Vector3.UP, yaw) * Vector3(cos(0.3), 0, sin(0.3)) * 0.62
		_spot("cafe_table_%d" % (i + 1), cp + Vector3.UP * 0.45, (tp - cp).normalized(), "assis", "nu_cafe_terrasse")
	var kx: Transform3D = xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-6.0, 0, 2.2))
	kit.box(kx * kit.T(0, 0.55, 0), Vector3(3.2, 1.1, 0.8), "composite113", 1.0)
	kit.box(kx * kit.T(0, 1.12, 0.05), Vector3(3.4, 0.05, 0.95), "bois113", 1.0)
	kit.col_box(kx * kit.T(0, 0.55, 0), Vector3(3.2, 1.1, 0.8))
	_pt("nu_cafe_terrasse", tf * Vector3(0, 0.05, 3.6))
	_pt("nu_cafe_comptoir", kx * Vector3(0, 0.05, 1.4))
	_link("nu_cafe_terrasse", "nu_cafe_comptoir")
	_link("nu_cafe_terrasse", "nu_es_1")
	_link("nu_cafe_terrasse", "nu_es_2")
	_pt("porte_gustave", door + Vector3.UP * 0.05)
	_link("porte_gustave", "nu_cafe_terrasse")
	_spot("cafe_comptoir", kx * Vector3(0, 0.05, -0.8), kx.basis * Vector3(0, 0, 1), "comptoir", "nu_cafe_comptoir")
	objets["cafe_cumulus"] = kx * Vector3(0, 0, 1.2)
	_avoid(xf * Vector3(0, 0, 0), 14.0)


# =================================================================== l'Atelier des Inventeurs

func _atelier() -> void:
	var a: float = -22.5
	var xf: Transform3D = XR(a, 30.0)
	var door: Vector3 = kit.tower113(xf, 14.0, 10.0, 1, {"gf": 5.2, "toit": "solaire", "boutique": "atelier", "retrait": 0.6})
	doors["porte_mireille"] = door
	# l'établi dehors, sous un auvent : des outils, une hélice, un petit robot à moitié monté
	var ex: Transform3D = xf * Transform3D(Basis(), Vector3(3.8, 0, 2.6))
	kit.box(ex * kit.T(0, 0.85, 0), Vector3(2.8, 0.08, 1.0), "bois113", 1.0)
	for sx in [-1.2, 1.2]:
		kit.box(ex * kit.T(sx, 0.42, 0), Vector3(0.08, 0.84, 0.9), "acier113", 1.0)
	kit.col_box(ex * kit.T(0, 0.45, 0), Vector3(2.8, 0.9, 1.0))
	kit.gear112(ex * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(-0.8, 0.92, 0.1)), 0.28, 12, 0.06, "acier113")
	kit.cyl(ex * kit.T(0.6, 0.9, 0.0), 0.18, 0.15, 0.4, "composite113", 10)
	kit.ball(ex * kit.T(0.6, 1.42, 0.0), 0.16, "composite113", 10, 5)
	kit.ball(ex * kit.T(0.66, 1.46, 0.13), 0.03, "anneau113", 6, 3)
	kit.ball(ex * kit.T(0.54, 1.46, 0.13), 0.03, "anneau113", 6, 3)
	kit.canopy113(xf * kit.T(3.8, 0, 2.8), 4.0, 3.0, 2.9, "toile113_sable")
	var cx: Transform3D = xf * Transform3D(Basis(), Vector3(-3.4, 0, 2.2))
	kit.box(cx * kit.T(0, 0.55, 0), Vector3(3.0, 1.1, 0.8), "composite113", 1.0)
	kit.box(cx * kit.T(0, 1.12, 0.05), Vector3(3.2, 0.05, 0.95), "bois113", 1.0)
	kit.col_box(cx * kit.T(0, 0.55, 0), Vector3(3.0, 1.1, 0.8))
	_pt("nu_atelier", xf * Vector3(0, 0.05, 5.6))
	_link("nu_atelier", "nu_es_7")
	_link("nu_atelier", "nu_es_0")
	_pt("porte_mireille", door + Vector3.UP * 0.05)
	_link("porte_mireille", "nu_atelier")
	_spot("atelier_comptoir", cx * Vector3(0, 0.05, -0.8), cx.basis * Vector3(0, 0, 1), "comptoir", "nu_atelier")
	_spot("atelier_etabli", ex * Vector3(0, 0.05, -0.9), ex.basis * Vector3(0, 0, 1), "bricoler", "nu_atelier")
	objets["atelier_inventeurs"] = cx * Vector3(0, 0, 1.2)
	_avoid(xf * Vector3(0, 0, -5.0), 13.0)


# =================================================================== la Maison du Conseil, la Tour du Zénith

func _conseil() -> void:
	var a: float = -90.0
	var xf: Transform3D = XR(a, 30.0)
	kit.tower113(xf * kit.T(0, 0, -1.6), 22.0, 10.0, 1, {"gf": 5.0, "toit": "jardin", "ailettes": true})
	# la loggia : un grand auvent sur poteaux, le bureau dehors, l'enseigne
	kit.box(xf * kit.T(0, 5.0, 0.6), Vector3(22.0, 0.36, 4.4), "beton113", 2.4)
	for sx in [-10.6, -5.3, 0.0, 5.3, 10.6]:
		kit.cyl(xf * kit.T(sx, 0, 2.4), 0.2, 0.2, 5.0, "composite113", 10, false)
		kit.col_cyl(xf * Vector3(sx, 0, 2.4), 0.22, 5.0)
	kit.sign113(xf * kit.T(0, 5.9, 2.85), "conseil", 4.4, 2.2)
	var dk: Transform3D = xf * Transform3D(Basis(), Vector3(-5.0, 0, 0.0))
	kit.box(dk * kit.T(0, 0.38, 0), Vector3(2.2, 0.06, 1.0), "bois113", 1.0)
	kit.box(dk * kit.T(0, 0.2, 0), Vector3(2.0, 0.4, 0.8), "composite113", 1.0)
	kit.col_box(dk * kit.T(0, 0.25, 0), Vector3(2.2, 0.5, 1.0))
	_pt("nu_conseil", xf * Vector3(0, 0.05, 4.6))
	_link("nu_conseil", "nu_es_6")
	_link("nu_conseil", "nu_es_5")
	_link("nu_conseil", "nu_es_7")
	_spot("conseil_bureau", dk * Vector3(0, 0.05, -0.9), dk.basis * Vector3(0, 0, 1), "comptoir", "nu_conseil")
	# la terrasse du Conseil : des bacs, un banc, la vue sur l'Esplanade
	var tx: Transform3D = xf * Transform3D(Basis(), Vector3(7.0, 0, 5.5))
	kit.planter113(tx * kit.T(-1.6, 0, 0), 1.6, 1.6, true)
	kit.planter113(tx * kit.T(1.8, 0, 0), 1.6, 1.6, false)
	_spot("conseil_terrasse", tx * Vector3(0, 0.05, 1.2), tx.basis * Vector3(0, 0, 1), "observer", "nu_conseil")
	objets["conseil"] = xf * Vector3(0, 0, 4.0)
	_avoid(xf * Vector3(0, 0, -4.0), 14.0)
	# la Tour du Zénith : ronde, torsadée, ses jardins à chaque étage
	var zc: Vector3 = PR(a, 58.0)
	kit.round113(zc, 8.0, 14, 4.6, 0.11)
	_pt("nu_zenith", PR(a + 12.0, 49.0, 0.05))
	_link("nu_zenith", "nu_rg_12")
	_link("nu_zenith", "nu_rg_13")
	_spot("zenith_pied", PR(a + 8.0, 49.6, 0.05), -dirv(a + 8.0), "observer", "nu_zenith")
	objets["zenith"] = zc
	_avoid(zc, 11.0)


# =================================================================== les Serres d'Altitude

const DOMES := [[Vector2(72.0, -2.0), 11.0, 9.0], [Vector2(62.0, -24.0), 6.5, 5.5], [Vector2(63.0, 21.0), 6.5, 5.5]]


func _serres() -> void:
	for i in range(DOMES.size()):
		var dm: Array = DOMES[i]
		var c: Vector3 = G((dm[0] as Vector2).x, (dm[0] as Vector2).y)
		var r: float = float(dm[1])
		var to_center: Vector3 = (G(0, 0) - c)
		to_center.y = 0.0
		to_center = to_center.normalized()
		kit.dome113(c, r, float(dm[2]), to_center)
		# la paroi (des collisions autour, sauf au sas)
		var n: int = 28
		for k in range(n):
			var a0: float = TAU * k / n
			var a1: float = TAU * (k + 1) / n
			var am: float = (a0 + a1) * 0.5
			var dmid := Vector3(cos(am), 0, sin(am))
			if dmid.dot(to_center) > cos(deg_to_rad(16.0 if i == 0 else 24.0)):
				continue
			var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * r
			var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * r
			kit.col_box(Transform3D(Basis(Vector3.UP, atan2(p1.x - p0.x, p1.z - p0.z)), (p0 + p1) * 0.5 + Vector3.UP * 1.6), Vector3(0.3, 3.2, p0.distance_to(p1) + 0.1))
		# dedans : des massifs, des plantes (la végétation), une allée de bois
		for q in range(int(r * r * 0.35)):
			var aa: float = _rng.randf() * TAU
			var rr: float = sqrt(_rng.randf()) * (r - 1.4)
			var p: Vector3 = c + Vector3(cos(aa), 0, sin(aa)) * rr
			if (p - c).dot(to_center) > 0.0 and absf((p - c).cross(to_center).y) < 1.6:
				continue
			serre_spots.append(p + Vector3.UP * 0.8)
		kit.box(Transform3D(Basis.looking_at(to_center, Vector3.UP), c + to_center * (r * 0.5) + Vector3.UP * 0.82), Vector3(2.2, 0.06, r + 2.0), "bois113", 1.0, 4)
		kit.box(Transform3D(Basis(), c + Vector3.UP * 0.4), Vector3(r * 1.6, 0.8, r * 1.6), "terre113", 2.0, 4)
		_avoid(c, r + 1.5)
		var door_pt: String = _pt("nu_se_porte_%d" % i, c + to_center * (r + 2.8) + Vector3.UP * 0.05)
		_link(door_pt, _near_pt(c + to_center * (r + 12.0)))
		if i == 0:
			_pt("nu_se_dedans", c + to_center * (r * 0.45) + Vector3.UP * 0.85)
			_link(door_pt, "nu_se_dedans")
			_link(door_pt, "nu_rg_0")
			var side: Vector3 = to_center.cross(Vector3.UP)
			# le bassin aux nymphéas (au fond), un banc
			var bp: Vector3 = c - to_center * 3.6 + side * 2.4
			kit.ring(Transform3D(Basis(), bp + Vector3.UP * 0.8), 1.8, 2.2, 0.3, "beton113", 24)
			kit.disc(Transform3D(Basis(), bp + Vector3.UP * 1.02), 1.8, "eau113", 24)
			kit.col_cyl(bp + Vector3.UP * 0.8, 2.2, 0.3)
			_spot("serres_bassin", bp + side * -2.8 + Vector3.UP * 0.85, side, "jardiner", "nu_se_dedans")
			_spot("serres_allee", c + side * -1.2 + Vector3.UP * 0.85, -to_center, "jardiner", "nu_se_dedans")
			var bx := Transform3D(Basis.looking_at(-side, Vector3.UP), c - side * 6.0 - to_center * 1.0 + Vector3.UP * 0.82)
			kit.bench113(bx, 1.8)
			_spot("serres_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_se_dedans")
			kit.sign113(Transform3D(Basis.looking_at(-to_center, Vector3.UP), c + to_center * (r + 2.6) + Vector3.UP * 3.4), "serres", 3.2, 1.6)
			objets["serres"] = c + to_center * (r + 2.0)
	# le sol des serres est un peu plus haut (sur la terre des massifs)
	for i2 in range(DOMES.size()):
		var dm2: Array = DOMES[i2]
		var c2: Vector3 = G((dm2[0] as Vector2).x, (dm2[0] as Vector2).y)
		var b := StaticBody3D.new()
		b.name = "Sol_serre"
		add_child(b)
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = float(dm2[1]) - 0.2
		sh.height = 0.8
		cs.shape = sh
		b.add_child(cs)
		b.global_position = c2 + Vector3.UP * 0.4


# =================================================================== l'Institut des Vents

func _institut() -> void:
	var a: float = -90.0
	var xf: Transform3D = XR(a, 72.0)
	var door: Vector3 = kit.tower113(xf, 28.0, 12.0, 2, {"gf": 4.4, "toit": "solaire", "ailettes": true, "boutique": "institut"})
	_pt("nu_in_porte", door + Vector3.UP * 0.05)
	_pt("nu_in_ouest", G(-14.0, -66.0, 0.05))
	_pt("nu_in_est", G(14.0, -66.0, 0.05))
	_chain(["nu_rg_11", "nu_in_ouest", "nu_in_porte", "nu_in_est", "nu_rg_13"])
	var dk: Transform3D = xf * Transform3D(Basis(), Vector3(6.0, 0, 1.8))
	kit.box(dk * kit.T(0, 0.55, 0), Vector3(2.6, 1.1, 0.8), "composite113", 1.0)
	kit.col_box(dk * kit.T(0, 0.55, 0), Vector3(2.6, 1.1, 0.8))
	_spot("institut_bureau", dk * Vector3(0, 0.05, -0.8), dk.basis * Vector3(0, 0, 1), "comptoir", "nu_in_porte")
	objets["institut"] = door
	_avoid(xf * Vector3(0, 0, -6.0), 18.0)
	# le mât de mesure : un treillis d'acier blanc, ses anémomètres, sa girouette, son feu rouge
	var mp: Vector3 = G(-28.0, -74.0)
	var h: float = 34.0
	for k in range(3):
		var ak: float = TAU * k / 3.0
		var bot: Vector3 = mp + Vector3(cos(ak), 0, sin(ak)) * 1.6
		var tp: Vector3 = mp + Vector3(cos(ak), 0, sin(ak)) * 0.5 + Vector3.UP * h
		kit.beam(bot, tp, 0.12, "composite113")
	for y in range(2, int(h), 3):
		var t: float = float(y) / h
		var rr: float = lerpf(1.6, 0.5, t)
		for k2 in range(3):
			var a0: float = TAU * k2 / 3.0
			var a1: float = TAU * (k2 + 1) / 3.0
			kit.beam(mp + Vector3(cos(a0) * rr, y, sin(a0) * rr), mp + Vector3(cos(a1) * rr, y + 1.5, sin(a1) * rr), 0.05, "acier113")
	for yy in [h * 0.55, h * 0.8, h]:
		kit.box(Transform3D(Basis(), mp + Vector3.UP * yy), Vector3(2.4, 0.06, 0.06), "acier113", 1.0)
		for s in [-1.2, 1.2]:
			kit.cyl(kit.T(mp.x + s, mp.y + yy, mp.z), 0.03, 0.03, 0.3, "acier113", 6)
			kit.ball(kit.T(mp.x + s, mp.y + yy + 0.35, mp.z), 0.12, "composite113", 8, 4)
	kit.ball(kit.T(mp.x, mp.y + h + 0.5, mp.z), 0.18, "led113_chaud", 8, 4)
	kit.col_cyl(mp, 1.8, 4.0)
	_pt("nu_in_mat", G(-24.0, -70.0, 0.05))
	_link("nu_in_mat", "nu_in_ouest")
	_spot("institut_mat", G(-25.5, -72.0, 0.05), (mp - G(-25.5, -72.0)).normalized(), "observer", "nu_in_mat")
	objets["mat_mesure"] = mp
	_avoid(mp, 5.0)
	# les éoliennes verticales, au bord nord (derrière la balustrade)
	for k3 in range(8):
		var ad: float = -118.0 + k3 * 8.0
		var rr2: float = rim(ad) - 1.8
		var tp2: Vector3 = PR(ad, rr2)
		kit.turbine113(tp2, 9.0)
	_pt("nu_in_eol", PR(-100.0, rim(-100.0) - 8.5, 0.05))
	_link("nu_in_eol", _near_pt(PR(-100.0, rim(-100.0) - 8.5), "nu_pr_"))
	_spot("institut_eoliennes", PR(-100.0, rim(-100.0) - 6.0, 0.05), dirv(-100.0), "observer", "nu_in_eol")
	# la Salle des Sustentateurs : un pavillon de verre, ses pupitres qui veillent sur les moteurs
	var sc: Vector3 = G(28.0, -76.0)
	kit.cyl(Transform3D(Basis(), sc), 6.0, 6.0, 0.3, "dalle113", 32, true, 3.0)
	for k4 in range(8):
		var a4: float = TAU * k4 / 8.0
		kit.cyl(Transform3D(Basis(), sc + Vector3(cos(a4), 0, sin(a4)) * 5.6), 0.12, 0.12, 3.8, "composite113", 8, false)
		kit.col_cyl(sc + Vector3(cos(a4), 0, sin(a4)) * 5.6, 0.15, 3.8)
	kit.cyl(Transform3D(Basis(), sc + Vector3.UP * 3.8), 6.4, 6.4, 0.3, "composite113", 32, true)
	kit.dome76(Transform3D(Basis(), sc + Vector3.UP * 4.1), 5.6, 1.6, "verre113", 32, 5)
	var tc: Vector3 = (G(0, 0) - sc)
	tc.y = 0.0
	tc = tc.normalized()
	for k5 in range(4):
		var a5: float = atan2(tc.z, tc.x) + PI + (k5 - 1.5) * 0.55
		var pp: Vector3 = sc + Vector3(cos(a5), 0, sin(a5)) * 3.0
		var pb := Basis.looking_at(sc - pp, Vector3.UP)
		kit.box(Transform3D(pb * Basis(Vector3.RIGHT, -0.5), pp + Vector3.UP * 1.0), Vector3(1.2, 0.08, 0.7), "acier113_sombre", 1.0)
		kit.box(Transform3D(pb, pp + Vector3.UP * 0.48), Vector3(1.1, 0.9, 0.5), "composite113", 1.0)
		kit.ring(Transform3D(pb * Basis(Vector3.RIGHT, PI * 0.5 - 0.5), pp + Vector3.UP * 1.06 + pb * Vector3(0, 0, 0.05)), 0.16, 0.22, 0.02, "anneau113", 16)
		kit.col_box(Transform3D(pb, pp + Vector3.UP * 0.5), Vector3(1.1, 1.0, 0.5))
	kit.ring(Transform3D(Basis(), sc + Vector3.UP * 0.32), 1.0, 1.3, 0.04, "anneau113", 32)
	kit.disc(Transform3D(Basis(), sc + Vector3.UP * 0.31), 1.0, "verre113_fume", 32)
	_pt("nu_moteurs", sc + tc * 4.2 + Vector3.UP * 0.35)
	_link("nu_moteurs", "nu_in_est")
	_link("nu_moteurs", "nu_rg_13")
	_spot("moteurs_pupitre", sc + tc * 0.8 + Vector3.UP * 0.35, -tc, "holo", "nu_moteurs")
	objets["sustentateurs"] = sc
	_avoid(sc, 7.0)


# =================================================================== le Port des Nuées

func _port() -> void:
	var a: float = 180.0
	var rr: float = rim(a)
	var d: Vector3 = dirv(a)
	var sd: Vector3 = d.cross(Vector3.UP).normalized()
	var r0: float = rr - 8.0
	var r1: float = rr + 22.0
	var y: float = R.Y0 + 0.12
	var bs := Basis.looking_at(d, Vector3.UP)
	var mid: Vector3 = R.W(d.x * (r0 + r1) * 0.5, d.z * (r0 + r1) * 0.5, 0.0)
	mid.y = y
	var len: float = r1 - r0
	# le ponton : un platelage de bois blond sur deux poutres d'acier, des garde-corps de verre
	kit.box(Transform3D(bs, mid + Vector3.DOWN * 0.1), Vector3(8.0, 0.2, len), "bois113", 1.4, 4 | 16 | 32 | 1 | 2)
	kit.box(Transform3D(bs, mid + Vector3.DOWN * 0.45), Vector3(7.4, 0.5, len), "acier113", 1.0, 63 - 4)
	kit.col_box(Transform3D(bs, mid + Vector3.DOWN * 0.15), Vector3(8.0, 0.3, len))
	for s in [-1.0, 1.0]:
		var a0: Vector3 = R.W(d.x * (rr + 0.5), d.z * (rr + 0.5), -7.0) + sd * s * 3.0
		var a1: Vector3 = R.W(d.x * (r1 - 2.0), d.z * (r1 - 2.0), -0.5) + sd * s * 3.0
		kit.beam(a0, a1, 0.5, "acier113")
		kit.glass_rail113(R.W(d.x * (rr - 4.0), d.z * (rr - 4.0), 0) + Vector3.UP * (y - R.Y0) + sd * s * 4.0, R.W(d.x * r1, d.z * r1, 0) + Vector3.UP * (y - R.Y0) + sd * s * 4.0, 1.15)
	var e: Vector3 = R.W(d.x * r1, d.z * r1, 0) + Vector3.UP * (y - R.Y0)
	kit.glass_rail113(e + sd * 4.0, e + sd * 1.2, 1.15)
	kit.glass_rail113(e - sd * 4.0, e - sd * 1.2, 1.15)
	# le mât d'amarrage au bout, la Libellule (un dirigeable blanc) amarrée à son nez
	var mp: Vector3 = e - d * 1.6 + Vector3.UP * 0.0
	kit.cyl(Transform3D(Basis(), mp), 0.35, 0.22, 11.0, "composite113", 12, false)
	kit.col_cyl(mp, 0.4, 11.0)
	kit.ring(Transform3D(Basis(), mp + Vector3.UP * 10.6), 0.3, 0.6, 0.3, "acier113", 16)
	kit.ball(Transform3D(Basis(), mp + Vector3.UP * 11.2), 0.2, "led113_chaud", 8, 4)
	airship = Node3D.new()
	airship.name = "La_Libellule"
	add_child(airship)
	var ak = Kit.new()
	ak.setup(airship, null)
	ak.airship112(Transform3D.IDENTITY, 24.0, "toile113")
	ak.commit()
	airship_base = Transform3D(Basis.looking_at(-d, Vector3.UP) * Basis(Vector3.UP, PI * 0.5), mp + d * 13.6 + Vector3.UP * 10.0)
	airship.transform = airship_base
	for ch in airship.get_children():
		if ch is GeometryInstance3D:
			(ch as GeometryInstance3D).visibility_range_end = 2400.0
	# les points, les lieux
	_pt("nu_port_racine", PR(a, rr - 9.0, 0.05))
	_pt("nu_port_milieu", R.W(d.x * (rr + 5.0), d.z * (rr + 5.0), 0) + Vector3.UP * (y - R.Y0 + 0.05))
	_pt("nu_port_bout", R.W(d.x * (r1 - 4.0), d.z * (r1 - 4.0), 0) + Vector3.UP * (y - R.Y0 + 0.05))
	_chain(["nu_rg_8", "nu_port_racine", "nu_port_milieu", "nu_port_bout"])
	_link("nu_port_racine", "nu_pr_12")
	_spot("port_ponton", R.W(d.x * (r1 - 2.6), d.z * (r1 - 2.6), 0) + Vector3.UP * (y - R.Y0 + 0.05) + sd * 2.2, d, "observer", "nu_port_bout")
	var bx := Transform3D(Basis.looking_at(-sd, Vector3.UP), R.W(d.x * (rr + 4.0), d.z * (rr + 4.0), 0) + Vector3.UP * (y - R.Y0) - sd * 3.2)
	kit.bench113(bx, 2.2)
	_spot("ponton_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_port_milieu")
	objets["port_nuees"] = mid
	_port_gap = [a, 2.6]
	# la capitainerie (au nord du ponton) et son bureau dehors
	var cx: Transform3D = XR(193.0, 84.0)
	var door: Vector3 = kit.tower113(cx, 10.0, 8.0, 1, {"gf": 4.0, "toit": "jardin", "boutique": "port"})
	doors["porte_zephyrine"] = door
	_pt("porte_zephyrine", door + Vector3.UP * 0.05)
	_link("porte_zephyrine", "nu_port_racine")
	_pt("nu_capitainerie", cx * Vector3(-3.0, 0.05, 2.6))
	_link("nu_capitainerie", "porte_zephyrine")
	var dk: Transform3D = cx * Transform3D(Basis(), Vector3(-3.0, 0, 1.2))
	kit.box(dk * kit.T(0, 0.55, 0), Vector3(2.2, 1.1, 0.7), "composite113", 1.0)
	kit.col_box(dk * kit.T(0, 0.55, 0), Vector3(2.2, 1.1, 0.7))
	_spot("port_bureau", dk * Vector3(0, 0.05, -0.7), dk.basis * Vector3(0, 0, 1), "comptoir", "nu_capitainerie")
	_avoid(cx * Vector3(0, 0, -4.0), 9.0)


var _port_gap: Array = []


# =================================================================== les Résidences des Terrasses

func _residences() -> void:
	var specs := [[112.5, 52.0, 26.0, 22.0, 5, 3.8], [157.5, 52.0, 26.0, 20.0, 4, 4.2]]
	var all_doors: Array = []
	for i in range(specs.size()):
		var s: Array = specs[i]
		var xf: Transform3D = XR(float(s[0]), float(s[1]))
		var dl: Array = kit.terraces113(xf, float(s[2]), float(s[3]), int(s[4]), float(s[5]))
		for dp in dl:
			all_doors.append(dp)
		kit.sign113(xf * kit.T(0, 2.3, 0.25), "residences", 3.6, 1.8)
		# le jardin devant : des bacs, des bancs
		for sx in [-8.0, 8.0]:
			kit.planter113(xf * kit.T(sx, 0, 3.6), 3.0, 1.6, sx > 0.0)
		var bx: Transform3D = xf * Transform3D(Basis(), Vector3(0, 0, 4.4))
		kit.bench113(bx, 2.4)
		if i == 0:
			_pt("nu_res_jardin", xf * Vector3(0, 0.05, 6.4))
			_spot("residences_jardin", xf * Vector3(-5.0, 0.05, 2.6), xf.basis * Vector3(0, 0, -1), "jardiner", "nu_res_jardin")
			_spot("residences_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_res_jardin")
			_link("nu_res_jardin", "nu_rg_5")
			objets["residences"] = xf * Vector3(0, 0, 4.0)
		else:
			_pt("nu_res2_jardin", xf * Vector3(0, 0.05, 6.4))
			_link("nu_res2_jardin", "nu_rg_7")
			crowd_spots.append(_crowd_spot("nu_res2_banc", bx, "nu_res2_jardin"))
		_avoid(xf * Vector3(0, 0, -float(s[3]) * 0.5), float(s[2]) * 0.6)
	var names := ["porte_celeste", "porte_pascal", "porte_ombeline", "porte_icare"]
	for k in range(mini(names.size(), all_doors.size())):
		var p: Vector3 = all_doors[k]
		doors[names[k]] = p
		_pt(names[k], p + Vector3.UP * 0.05)
		_link(names[k], "nu_res_jardin" if k < 2 else "nu_res2_jardin")
	# la famille Altaïr partage la même porte (Céleste, Lili, Séverin)
	if doors.has("porte_celeste"):
		var pc0: Vector3 = doors["porte_celeste"]
		for e in [["porte_lili", 0.9], ["porte_severin", -0.9]]:
			var p2: Vector3 = pc0 + _offset_along(pc0, float(e[1]))
			doors[str(e[0])] = p2
			_pt(str(e[0]), p2 + Vector3.UP * 0.05)
			_link(str(e[0]), "nu_res_jardin")


func _offset_along(p: Vector3, k: float) -> Vector3:
	var l: Vector2 = R.L(p.x, p.z)
	var t := Vector3(-l.y, 0, l.x).normalized()
	return t * k


# =================================================================== les autres immeubles

func _immeubles() -> void:
	# [angle, rayon de la façade, largeur, profondeur, étages, options, porte]
	var specs := [
		[22.5, 30.0, 12.0, 9.0, 3, {"toit": "mixte", "balcons": ["av"], "boutique": "gare"}, "porte_theo"],
		[112.5, 30.0, 12.0, 9.0, 4, {"toit": "jardin", "balcons": ["av", "g"]}, ""],
		[157.5, 30.0, 12.0, 9.0, 2, {"toit": "solaire", "ailettes": true}, ""],
		[202.5, 30.0, 12.0, 9.0, 3, {"toit": "jardin", "balcons": ["av"]}, "porte_plumeau"],
		[67.5, 58.0, 22.0, 15.0, 6, {"toit": "mixte", "balcons": ["av", "ar"], "ailettes": false}, "porte_flora"],
		[292.5, 56.0, 18.0, 13.0, 7, {"toit": "solaire", "ailettes": true, "balcons": ["g", "d"]}, "porte_nova"],
	]
	for s in specs:
		var xf: Transform3D = XR(float(s[0]), float(s[1]))
		var opts: Dictionary = s[5]
		if str(s[6]) == "porte_theo":
			opts.erase("boutique")
		var door: Vector3 = kit.tower113(xf, float(s[2]), float(s[3]), int(s[4]), opts)
		_avoid(xf * Vector3(0, 0, -float(s[3]) * 0.5), maxf(float(s[2]), float(s[3])) * 0.6)
		if str(s[6]) != "":
			doors[str(s[6])] = door
			_pt(str(s[6]), door + Vector3.UP * 0.05)
			_link(str(s[6]), _near_pt(door + (G(0, 0) - door).normalized() * 3.0, "nu_rg_") if float(s[1]) > 40.0 else _near_pt(door, "nu_es_"))
	# la tour ronde du nord-ouest (Aurèle y habite)
	var dc: Vector3 = PR(247.5, 66.0)
	kit.round113(dc, 7.0, 9, 4.4, 0.0)
	_avoid(dc, 9.0)
	var dd: Vector3 = PR(247.5, 58.2)
	doors["porte_aurele"] = dd
	_pt("porte_aurele", dd + Vector3.UP * 0.05)
	_link("porte_aurele", "nu_rg_11")
	# l'auvent de la porte de la tour ronde
	kit.box(Transform3D(Basis.looking_at(dirv(247.5), Vector3.UP), PR(247.5, 58.6, 3.0)), Vector3(3.0, 0.14, 1.6), "composite113", 1.0)


# =================================================================== le Parc des Brumes

func _parc() -> void:
	# l'étang (une eau calme dans sa cuvette), sa margelle de pierre claire
	var pc: Vector3 = R.W(R.POND.x, R.POND.y, R.POND_Y)
	var wm := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = R.POND_R - 0.6
	cm.bottom_radius = R.POND_R - 0.6
	cm.height = 0.02
	cm.radial_segments = 48
	wm.mesh = cm
	wm.material_override = kit.mat("eau113")
	add_child(wm)
	wm.global_position = pc
	_avoid(pc, R.POND_R + 2.0)
	# le ruisseau (un ruban d'eau dans son lit) jusqu'à la grille, avant la Promenade
	var lip: Vector2 = R.polar(R.CASCADE_DEG, rim(R.CASCADE_DEG) - 10.0)
	var from: Vector2 = R.POND + (lip - R.POND).normalized() * (R.POND_R - 2.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 14
	var dir2: Vector2 = (lip - from).normalized()
	var side2 := Vector2(-dir2.y, dir2.x)
	for i in range(n):
		var t0: float = float(i) / n
		var t1: float = float(i + 1) / n
		var a0: Vector2 = from.lerp(lip, t0)
		var a1: Vector2 = from.lerp(lip, t1)
		var ya: float = -0.42
		var vs: Array = [R.W(a0.x - side2.x * 0.9, a0.y - side2.y * 0.9, ya), R.W(a1.x - side2.x * 0.9, a1.y - side2.y * 0.9, ya), R.W(a1.x + side2.x * 0.9, a1.y + side2.y * 0.9, ya), R.W(a0.x + side2.x * 0.9, a0.y + side2.y * 0.9, ya)]
		for idx in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2((vs[idx] as Vector3).x, (vs[idx] as Vector3).z) * 0.2)
			st.add_vertex(vs[idx])
	var br := MeshInstance3D.new()
	br.mesh = st.commit()
	br.material_override = kit.mat("eau113")
	br.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(br)
	# la grille où l'eau s'en va (vers le bec de la cascade, sous la Promenade)
	var gp: Vector3 = R.W(lip.x, lip.y, -0.35)
	var gb := Basis.looking_at(Vector3(dir2.x, 0, dir2.y), Vector3.UP)
	kit.box(Transform3D(gb, gp), Vector3(2.4, 0.06, 1.2), "acier113_sombre", 1.0)
	for k in range(9):
		kit.box(Transform3D(gb, gp + gb * Vector3(-1.1 + k * 0.275, 0.05, 0)), Vector3(0.05, 0.06, 1.2), "acier113", 1.0)
	# deux petits ponts de bois sur le ruisseau
	for tb in [0.3, 0.7]:
		var bp2: Vector2 = from.lerp(lip, tb)
		var bw: Vector3 = R.W(bp2.x, bp2.y, 0.12)
		kit.box(Transform3D(Basis.looking_at(Vector3(side2.x, 0, side2.y), Vector3.UP), bw), Vector3(2.0, 0.16, 3.6), "bois113", 1.2)
		kit.col_box(Transform3D(Basis.looking_at(Vector3(side2.x, 0, side2.y), Vector3.UP), bw), Vector3(2.0, 0.16, 3.6))
	# la Source : trois capteurs de brume (de grands filets tendus sur des cadres) au-dessus d'un bassin
	var sc: Vector3 = G(-40.0, -58.0)
	kit.ring(Transform3D(Basis(), sc), 2.6, 3.2, 0.5, "beton113", 32)
	kit.disc(Transform3D(Basis(), sc + Vector3.UP * 0.42), 2.6, "eau113", 32)
	kit.col_cyl(sc, 3.2, 0.5)
	for k2 in range(3):
		var ak: float = TAU * k2 / 3.0 + 0.4
		var fp: Vector3 = sc + Vector3(cos(ak), 0, sin(ak)) * 5.0
		var fb := Basis(Vector3.UP, -ak + PI * 0.5)
		for sx in [-1.6, 1.6]:
			kit.cyl(Transform3D(Basis(), fp + fb * Vector3(sx, 0, 0)), 0.07, 0.06, 4.2, "acier113", 8, false)
			kit.col_cyl(fp + fb * Vector3(sx, 0, 0), 0.1, 4.2)
		kit.box(Transform3D(fb, fp + Vector3.UP * 4.15), Vector3(3.3, 0.06, 0.06), "acier113", 1.0)
		kit.quad(Transform3D(fb, fp + Vector3.UP * 2.9), 3.1, 2.4, "filet113", Vector2(0, 0), Vector2(3, 2.4), true)
		kit.box(Transform3D(fb, fp + Vector3.UP * 1.6), Vector3(3.3, 0.1, 0.16), "acier113", 1.0)
	_pt("nu_source", sc + (G(-54.0, -46.0) - sc).normalized() * 0.0 + Vector3(0, 0.05, 0) + (G(-30.0, -48.0) - sc).normalized() * 4.4)
	_spot("parc_source", sc + (G(-30.0, -48.0) - sc).normalized() * 3.6 + Vector3.UP * 0.05, (sc - G(-30.0, -48.0)).normalized(), "mediter", "nu_source")
	objets["source"] = sc
	_avoid(sc, 7.5)
	# les chemins du parc
	_pt("nu_pk_entree", PR(225.0, 52.0, 0.05))
	_pt("nu_pk_ouest", PR(198.0, 72.0, 0.05))
	_pt("nu_pk_nord", PR(250.0, 74.0, 0.05))
	_pt("nu_pk_bord", PR(228.0, rim(228.0) - 8.5, 0.05))
	_chain(["nu_rg_10", "nu_pk_entree", "nu_pk_ouest", "nu_pk_bord"])
	_chain(["nu_pk_entree", "nu_source", "nu_pk_nord", "nu_pk_bord"])
	_link("nu_pk_bord", _near_pt(PR(228.0, rim(228.0) - 8.5), "nu_pr_"))
	_link("nu_pk_ouest", "nu_rg_9")
	_link("nu_pk_nord", "nu_rg_11")
	# les bancs, la pelouse, le bord de la cascade
	var bx: Transform3D = XR(212.0, 52.0)
	bx = Transform3D(Basis.looking_at(R.W(R.POND.x, 0, R.POND.y) - R.W(R.polar(212.0, 52.0).x, 0, R.polar(212.0, 52.0).y), Vector3.UP).rotated(Vector3.UP, PI), bx.origin)
	kit.bench113(bx, 2.4)
	_spot("parc_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "nu_pk_entree")
	var bx2: Transform3D = Transform3D(Basis.looking_at(R.W(R.POND.x, 0, R.POND.y) - PR(240.0, 70.0), Vector3.UP).rotated(Vector3.UP, PI), PR(240.0, 70.0))
	kit.bench113(bx2, 2.4)
	crowd_spots.append(_crowd_spot("nu_parc_banc_2", bx2, "nu_pk_nord"))
	_spot("parc_pelouse", PR(205.0, 82.0, 0.05), -dirv(205.0), "jardiner", "nu_pk_ouest")
	_pt("nu_cascade", PR(R.CASCADE_DEG + 3.0, rim(R.CASCADE_DEG) - 7.0, 0.05))
	_link("nu_cascade", "nu_pk_bord")
	_spot("cascade_bord", PR(R.CASCADE_DEG + 3.0, rim(R.CASCADE_DEG) - 5.4, 0.05), dirv(R.CASCADE_DEG), "observer", "nu_cascade")
	objets["parc"] = G(R.PARC.x, R.PARC.y)
	objets["cascade"] = PR(R.CASCADE_DEG, rim(R.CASCADE_DEG) - 6.0)


# =================================================================== la Promenade du bord

func _bord() -> void:
	var n: int = 120
	for k in range(n):
		var a0: float = 360.0 * k / n
		var a1: float = 360.0 * (k + 1) / n
		var am: float = (a0 + a1) * 0.5
		var skip: bool = false
		for gap in [_bv_gap, _port_gap]:
			if not gap.is_empty() and absf(wrapf(am - float(gap[0]), -180.0, 180.0)) < float(gap[1]):
				skip = true
		if skip:
			continue
		var p0: Vector3 = PR(a0, rim(a0) - 4.0)
		var p1: Vector3 = PR(a1, rim(a1) - 4.0)
		kit.glass_rail113(p0, p1, 1.15)
	# des bancs et des lampadaires le long de la Promenade
	var n_spot: int = 0
	for k2 in range(12):
		var ab: float = 30.0 * k2 + 8.0
		if absf(wrapf(ab - 45.0, -180.0, 180.0)) < 9.0 or absf(wrapf(ab - 180.0, -180.0, 180.0)) < 9.0:
			ab += 14.0
		var bx: Transform3D = Transform3D(Basis.looking_at(-dirv(ab), Vector3.UP), PR(ab, rim(ab) - 5.6))
		kit.bench113(bx, 2.4)
		if n_spot < 6 and k2 % 2 == 0 or n_spot < 6 and k2 >= 10:
			n_spot += 1
			_spot("promenade_%d" % n_spot, bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", _near_pt(bx.origin, "nu_pr_"))
		else:
			crowd_spots.append(_crowd_spot("nu_prom_banc_%d" % k2, bx, _near_pt(bx.origin, "nu_pr_")))
	for k3 in range(24):
		var al: float = 15.0 * k3 + 7.5
		kit.lamp113(PR(al, rim(al) - 11.0), deg_to_rad(-al + 90.0), 4.4, k3 % 4 == 0)


# =================================================================== la Navette circulaire

func _navette() -> void:
	var r: float = R.NAVETTE_R + 6.0
	var y: float = R.NAVETTE_Y
	var n: int = 96
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var p0 := Vector3(R.CENTER.x + cos(a0) * r, R.Y0 + y, R.CENTER.z + sin(a0) * r)
		var p1 := Vector3(R.CENTER.x + cos(a1) * r, R.Y0 + y, R.CENTER.z + sin(a1) * r)
		kit.beam(p0, p1, 0.55, "composite113")
		kit.beam(p0 + Vector3.DOWN * 0.42, p1 + Vector3.DOWN * 0.42, 0.12, "acier113")
	# les pylônes (en col de cygne), pas sur les allées
	for k2 in range(30):
		var ad: float = 12.0 * k2 + 6.0
		var bad: bool = false
		for s in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0, R.CASCADE_DEG]:
			if absf(wrapf(ad - s, -180.0, 180.0)) < 5.0:
				bad = true
		if bad:
			continue
		var foot: Vector3 = PR(ad, r + 2.2)
		var topp := Vector3(R.CENTER.x + cos(deg_to_rad(ad)) * r, R.Y0 + y + 0.3, R.CENTER.z + sin(deg_to_rad(ad)) * r)
		var knee: Vector3 = Vector3(foot.x, R.Y0 + y + 1.4, foot.z)
		kit.beam(foot, knee, 0.42, "composite113")
		kit.beam(knee, topp, 0.32, "composite113")
		kit.col_cyl(foot, 0.3, 3.0)
	for i in range(NAV_PODS):
		var pod := MeshInstance3D.new()
		pod.name = "Navette"
		pod.mesh = _pod_mesh()
		add_child(pod)
		pod.visibility_range_end = 1600.0
		pods.append([pod, TAU * i / NAV_PODS])
	_navette_tick()


func _pod_mesh() -> ArrayMesh:
	var pk = Kit.new()
	var tmp := Node3D.new()
	pk.setup(tmp, null)
	var b: Dictionary = pk.batch
	pk.box(pk.T(0, -1.55, 0), Vector3(1.9, 1.6, 3.6), "composite113", 1.0)
	pk.box(pk.T(0, -1.35, 0), Vector3(1.94, 0.7, 3.2), "verre113_fume", 1.0, 1 | 2 | 16 | 32)
	pk.ball(pk.T(0, -1.55, 1.8), 0.95, "composite113", 12, 6)
	pk.ball(pk.T(0, -1.55, -1.8), 0.95, "composite113", 12, 6)
	pk.box(pk.T(0, -0.5, 0), Vector3(0.3, 0.6, 1.2), "acier113", 1.0)
	pk.box(pk.T(0, -2.28, 0), Vector3(1.6, 0.04, 3.0), "led113", 1.0, 8)
	var mesh := ArrayMesh.new()
	for k in pk.batch:
		var st: SurfaceTool = pk.batch[k]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, pk.mat(str(k)))
	tmp.free()
	return mesh


func _navette_tick() -> void:
	var r: float = R.NAVETTE_R + 6.0
	for e in pods:
		var a: float = float(e[1]) + _clock * 0.045
		var p := Vector3(R.CENTER.x + cos(a) * r, R.Y0 + R.NAVETTE_Y - 0.3, R.CENTER.z + sin(a) * r)
		var tang := Vector3(-sin(a), 0, cos(a))
		(e[0] as Node3D).global_transform = Transform3D(Basis.looking_at(tang, Vector3.UP), p)


# =================================================================== la vie des rues

func _street_life() -> void:
	# des lampadaires le long du boulevard, des bacs
	for k in range(16):
		var a: float = 22.5 * k + 11.25
		kit.lamp113(PR(a, RG_R + 3.2), deg_to_rad(-a - 90.0), 4.6, k % 4 == 1)
	# des totems d'orientation aux carrefours
	kit.totem113(PR(36.0, RG_R + 2.0), deg_to_rad(-36.0 + 90.0), "gare")
	kit.totem113(PR(200.0, RG_R - 2.5), deg_to_rad(-200.0 + 90.0), "port")
	# les passants : des bancs du boulevard
	for k2 in range(8):
		var ab: float = 45.0 * k2 + 30.0
		if k2 in [1, 6]:
			continue
		var bx: Transform3D = Transform3D(Basis.looking_at(dirv(ab), Vector3.UP), PR(ab, RG_R - 3.4))
		kit.bench113(bx, 2.2)
		crowd_spots.append(_crowd_spot("nu_rg_banc_%d" % k2, bx, _near_pt(bx.origin, "nu_rg_")))


func _lights() -> void:
	var max_l: int = 18 if pc else 8
	for e in kit.light_spots:
		if lights.size() >= max_l:
			break
		var l := OmniLight3D.new()
		l.light_color = e[1]
		l.light_energy = 0.0
		l.omni_range = 10.0
		l.shadow_enabled = false
		l.distance_fade_enabled = true
		l.distance_fade_begin = 120.0
		l.distance_fade_length = 20.0
		add_child(l)
		l.global_position = e[0]
		lights.append(l)


# =================================================================== repères pour les autres

func on_structure(p: Vector3) -> bool:
	if ligne != null and ligne.walkable(p):
		return true
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


## Le quartier de la Cité des Nuées (pour la musique, les ambiances, le carnet), ou "".
func zone_at(p: Vector3) -> String:
	if ligne != null and ligne.inside(p) and p.y > ligne.foot.y + 6.0:
		return "nu_capsule"
	if p.y < R.Y0 - 12.0:
		return ""
	var l: Vector2 = R.L(p.x, p.z)
	if l.length() > rim(rad_to_deg(atan2(l.y, l.x))) + 26.0:
		return ""
	var near := func(key: String, r: float) -> bool:
		return objets.has(key) and Vector2((objets[key] as Vector3).x - p.x, (objets[key] as Vector3).z - p.z).length() < r
	if near.call("belvedere_verre", 13.0):
		return "nu_belvedere"
	if near.call("gare", 13.0):
		return "nu_gare"
	if near.call("port_nuees", 20.0):
		return "nu_port"
	if near.call("cafe_cumulus", 9.0):
		return "nu_cafe"
	if near.call("atelier_inventeurs", 9.0):
		return "nu_atelier"
	if near.call("conseil", 12.0) or near.call("zenith", 12.0):
		return "nu_conseil"
	if l.length() < 27.0:
		return "nu_esplanade"
	for dm in DOMES:
		if l.distance_to(dm[0]) < float(dm[1]) + 3.0:
			return "nu_serres"
	if near.call("institut", 16.0) or near.call("sustentateurs", 8.0) or near.call("mat_mesure", 8.0):
		return "nu_institut"
	if l.distance_to(R.PARC) < 34.0:
		return "nu_parc"
	if near.call("residences", 22.0):
		return "nu_residences"
	if l.length() > rim(rad_to_deg(atan2(l.y, l.x))) - 13.0:
		return "nu_promenade"
	return "nu_ville"


func tick(delta: float, night: float, near: bool) -> void:
	_clock += delta
	if not near:
		return
	_navette_tick()
	for sp in kit.spinners:
		if is_instance_valid(sp):
			(sp as Node3D).rotate_y(delta * float(sp.get_meta("vitesse", 1.4)))
	if airship != null:
		airship.transform = airship_base * Transform3D(Basis(Vector3.UP, sin(_clock * 0.15) * 0.08) * Basis(Vector3.RIGHT, sin(_clock * 0.27) * 0.02), Vector3(0, sin(_clock * 0.35) * 0.3, 0))
	for l in lights:
		(l as OmniLight3D).light_energy = 1.4 * night

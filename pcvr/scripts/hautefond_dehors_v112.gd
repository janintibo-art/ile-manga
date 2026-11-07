extends Node3D
## V112 : le dehors de l'Île de Hautefond (hors de la ville) :
##  - le Port des Cordages (au nord-est) : le quai de pierre blonde, la capitainerie, la grue à vapeur,
##    des caisses, des tonneaux, des barques ; le ponton du bateau de ligne et celui du joueur ;
##  - le Phare de la Pointe (au nord, sur son cap) : une tour blanche et sa lanterne qui tourne ;
##  - le Moulin des Quatre Vents (sur la colline de l'ouest) ;
##  - les Vergers en terrasses (au sud) : des rangées d'arbres fruitiers sur leurs murets ;
##  - la Plage des Galets Blonds (à l'est) ;
##  - les Falaises (au sud et à l'ouest) : le belvédère des falaises, deux Arches de pierre plantées
##    dans la mer, la Cascade des Falaises qui tombe dans la mer ;
##  - des poteaux indicateurs aux carrefours.
## Ses lieux (spots) et ses points s'ajoutent au réseau des rues de la ville (hautefond_ville_v112).

const R = preload("res://scripts/ile_hautefond_v112.gd")
const CHUTE := "res://shaders/waterfall_v26.gdshader"

var main: Node
var manager: Node                        # hautefond_v112
var ile: Node3D
var city: Node3D
var kit
var objets: Dictionary = {}
var portes116: Dictionary = {}           # V116 : les grands lieux qu'on visite : lieu -> [porte, dehors]
var cadres116: Dictionary = {}           # V116 : les repères des lieux ouverts (hautefond_activite_v116)
var fire_spots: Array = []
var flora_avoid: Array = []
var orchard_spots: Array = []            # Vector3 : les arbres fruitiers des vergers
var phare_beam: Node3D                   # le faisceau du phare (il tourne)
var phare_light: OmniLight3D
var crane_arm: Node3D                    # la flèche de la grue (elle pivote doucement)
var cascade_top := Vector3.ZERO
var cascade_foot := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Un point au sol (repère île).
func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func GX(x: float, z: float, toward: Vector3) -> Transform3D:
	var p: Vector3 = G(x, z)
	var d := Vector3(toward.x - p.x, 0, toward.z - p.z).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


func build(owner: Node) -> void:
	manager = owner
	main = owner.main
	ile = owner.ile
	city = owner.city
	kit = load("res://scripts/hautefond_kit_v112.gd").new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = owner.pc
	kit.rng.seed = 11281
	kit.light_every = 1
	_rng.seed = 11282
	_port()
	_phare()
	_moulin()
	_vergers()
	_plage()
	_falaises()
	_panneaux()
	kit.commit()
	for f in kit.fires70:
		fire_spots.append(f)
	_graph()


# =================================================================== le Port des Cordages

func _port() -> void:
	var hc: Vector3 = R.W(R.HARBOR.x, R.HARBOR.y, R.QUAY_Y)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var to_town: Vector3 = Vector3(town.x - hc.x, 0, town.z - hc.z).normalized()
	var side: Vector3 = Vector3(-to_town.z, 0, to_town.x)
	var a_town: float = atan2(to_town.z, to_town.x)
	# le quai : un anneau de pierre blonde autour du bassin, du côté de la terre, des bittes d'amarrage
	kit.arc_ring(Vector3(hc.x, -6.0, hc.z), R.HARBOR_R - 0.2, R.HARBOR_R + 1.2, R.QUAY_Y + 6.0, a_town - 1.5, a_town + 1.5, "pierre112", 44, true, 15, 3.0)
	kit.arc_ring(Vector3(hc.x, R.QUAY_Y - 0.06, hc.z), R.HARBOR_R - 0.3, R.HARBOR_R + 1.3, 0.16, a_town - 1.5, a_town + 1.5, "pierre112_clair", 44, false, 1 | 2 | 4)
	for k in range(30):
		var a: float = a_town - 1.45 + 2.9 * k / 29.0
		var p: Vector3 = hc + Vector3(cos(a), 0, sin(a)) * (R.HARBOR_R + 0.5)
		if k % 3 == 0:
			kit.cyl(Transform3D(Basis(), p), 0.18, 0.14, 0.6, "acier112", 8)
			kit.ball(Transform3D(Basis(), p + Vector3.UP * 0.62), 0.16, "acier112", 8, 4)
	# la capitainerie : une maison de pierre blonde et sa tourelle d'horloge
	var cp: Vector3 = ile.pads_world["capitainerie"]
	var cl: Vector2 = R.L(cp.x, cp.z)
	var cap: Transform3D = GX(cl.x, cl.y, hc)
	var door: Vector3 = kit.house112(cap, 9.0, 7.5, {"floors": 2, "roof": "mansarde", "lit": 0.7, "balcons": false, "chimney": true})
	kit.clock112(cap * T(0, 6.0, 0.15), 0.6)
	kit.plaque112(cap * T(2.4, 2.9, 0.05), "liftiers", 1.4)
	objets["capitainerie"] = door
	portes116["hf_capitainerie"] = [door + Vector3.UP * 0.05, cap.basis * Vector3(0, 0, 1)]
	city._pt("port_cap", cap * Vector3(2.4, 0.05, 3.0))
	city._spot("port_capitainerie", cap * Vector3(2.6, 0.05, 1.6), cap.basis * Vector3(0, 0, 1), "bras_croises", "port_cap")
	# la grue à vapeur (sa flèche pivote doucement)
	var gq: Vector3 = hc + to_town * (R.HARBOR_R + 4.0) + side * 10.0
	gq.y = R.QUAY_Y
	kit.box(Transform3D(Basis(), gq + Vector3.UP * 0.6), Vector3(2.6, 1.2, 2.6), "pierre112_sombre", 1.0)
	kit.col_box(Transform3D(Basis(), gq + Vector3.UP * 0.6), Vector3(2.6, 1.2, 2.6))
	kit.cyl(Transform3D(Basis(), gq + Vector3.UP * 1.2), 0.9, 0.9, 1.8, "cuivre112", 12)
	kit.cyl(Transform3D(Basis(), gq + Vector3.UP * 3.0), 0.12, 0.12, 1.4, "acier112", 8)
	kit.steam_spots.append(gq + Vector3.UP * 4.5)
	crane_arm = Node3D.new()
	crane_arm.name = "Fleche_grue"
	add_child(crane_arm)
	crane_arm.global_position = gq + Vector3.UP * 3.0
	var saved_root: Node3D = kit.root
	var saved_batch: Dictionary = kit.batch
	var saved_inst: Dictionary = kit.inst
	kit.root = crane_arm
	kit.batch = {}
	kit.inst = {}
	kit.beam(Vector3(0, 0, 0), Vector3(9.0, 4.5, 0), 0.35, "acier112")
	kit.beam(Vector3(-2.0, 0, 0), Vector3(9.0, 4.5, 0), 0.12, "acier112")
	kit.box(T(-1.6, 0.3, 0), Vector3(1.4, 1.0, 1.4), "acier112", 1.0)
	kit.beam(Vector3(8.9, 4.4, 0), Vector3(8.9, 0.6, 0), 0.03, "fer71")
	kit.box(T(8.9, 0.3, 0), Vector3(1.2, 0.8, 1.2), "planches71", 1.0)
	kit.commit()
	kit.root = saved_root
	kit.batch = saved_batch
	kit.inst = saved_inst
	crane_arm.rotation.y = -a_town + PI * 0.5
	# des caisses, des tonneaux, des rouleaux de cordage, sur le quai
	for k2 in range(8):
		var q: Vector3 = hc + to_town * (R.HARBOR_R + 4.0) + side * (-14.0 + k2 * 3.0)
		q.y = R.QUAY_Y
		if k2 % 3 == 0:
			kit.barrel71(q)
		elif k2 % 3 == 1:
			kit.crate71(q, k2 * 0.7)
		else:
			kit.cyl(Transform3D(Basis(), q), 0.5, 0.5, 0.4, "foin71", 12)
	city._pt("port_q1", hc + to_town * (R.HARBOR_R + 2.5) - side * 6.0 + Vector3.UP * 0.05)
	city._pt("port_q2", hc + to_town * (R.HARBOR_R + 2.5) + side * 6.0 + Vector3.UP * 0.05)
	city._pt("port_q3", hc + to_town * (R.HARBOR_R + 7.0) + Vector3.UP * 0.05)
	city._spot("port_q1", (city.points["port_q1"] as Vector3) - to_town * 1.4, -to_town, "pecher", "port_q1")
	city._spot("port_q2", (city.points["port_q2"] as Vector3) - to_town * 1.4, -to_town, "observer", "port_q2")
	city._chain(["port_q1", "port_q3", "port_q2", "port_cap"])
	city._link("port_q1", "port_cap")
	# un banc sous un réverbère, face au bassin
	var bx: Transform3D = Transform3D(Basis.looking_at(to_town, Vector3.UP), hc + to_town * (R.HARBOR_R + 8.5) - side * 12.0)
	kit.bench112(bx)
	kit.globe_lamp112(bx * Vector3(1.4, 0, -0.5), 0.0, 3.8, true)
	city._spot("port_banc", bx * Vector3(0, 0.45, 0.15), bx.basis * Vector3(0, 0, 1), "assis", "port_q3")
	for k3 in range(4):
		var gl: Vector3 = hc + to_town * (R.HARBOR_R + 3.0) + side * (-15.0 + k3 * 10.0)
		gl.y = R.QUAY_Y
		kit.globe_lamp112(gl, 0.0, 4.0, k3 % 2 == 0)
	objets["port"] = hc + to_town * (R.HARBOR_R + 4.0)
	# V116 : le repère du quai (+Z vers la ville, X le long du quai), pour les dockers
	var qo: Vector3 = hc + to_town * R.HARBOR_R
	qo.y = R.QUAY_Y
	cadres116["port"] = Transform3D(Basis.looking_at(-to_town, Vector3.UP), qo)
	# des barques amarrées
	for k4 in range(3):
		var a4: float = a_town + PI + (k4 - 1) * 0.55
		var bp: Vector3 = hc + Vector3(cos(a4), 0, sin(a4)) * (R.HARBOR_R * 0.62)
		_rowboat(Transform3D(Basis(Vector3.UP, a4 + 0.4), Vector3(bp.x, R.WATER + 0.05, bp.z)))
	flora_avoid.append([Vector2(hc.x, hc.z), R.HARBOR_R + 16.0])


func _rowboat(xf: Transform3D) -> void:
	for s in [-1.0, 1.0]:
		kit.box(xf * Transform3D(Basis(Vector3.BACK, s * 0.25), Vector3(s * 0.62, 0.3, 0)), Vector3(0.08, 0.55, 3.6), "planches71", 1.0)
	kit.box(xf * T(0, 0.08, 0), Vector3(1.1, 0.08, 3.4), "planches71_sombre", 1.0)
	kit.box(xf * T(0, 0.35, 0.3), Vector3(1.2, 0.06, 0.3), "planches71", 1.0)
	kit.box(xf * T(0, 0.3, 1.75), Vector3(0.7, 0.5, 0.1), "planches71", 1.0)


# =================================================================== le phare

func _phare() -> void:
	var ph: Vector3 = ile.pads_world["phare"]
	var hc: Vector3 = R.W(R.HARBOR.x, R.HARBOR.y, R.QUAY_Y)
	var to_h: Vector3 = Vector3(hc.x - ph.x, 0, hc.z - ph.z).normalized()
	kit.cyl(Transform3D(Basis(), ph + Vector3.DOWN * 0.4), 4.0, 3.6, 1.2, "pierre112_sombre", 20)
	kit.cyl(Transform3D(Basis(), ph + Vector3.UP * 0.8), 2.9, 2.0, 17.0, "enduit71_blanc", 20, false, 3.0)
	for k in range(3):
		kit.ring(Transform3D(Basis(), ph + Vector3.UP * (5.0 + k * 5.0)), lerpf(2.9, 2.0, (4.2 + k * 5.0) / 17.0) - 0.05, lerpf(2.9, 2.0, (4.2 + k * 5.0) / 17.0) + 0.06, 1.0, "tissu112_rouge", 20)
	kit.col_cyl(ph, 3.0, 18.0)
	var top: Vector3 = ph + Vector3.UP * 17.8
	kit.cyl(Transform3D(Basis(), top), 2.8, 2.8, 0.3, "acier112", 20)
	for k2 in range(20):
		var a: float = TAU * k2 / 20.0
		kit.box(Transform3D(Basis(Vector3.UP, -a), top + Vector3(cos(a), 0, sin(a)) * 2.6 + Vector3.UP * 0.7), Vector3(0.04, 1.0, 0.04), "acier112", 1.0)
	kit.cyl(Transform3D(Basis(), top + Vector3.UP * 0.3), 1.4, 1.4, 2.2, "verre112", 12, false)
	kit.cyl(Transform3D(Basis(), top + Vector3.UP * 0.8), 0.5, 0.5, 1.0, "phare112", 12)
	kit.dome76(Transform3D(Basis(), top + Vector3.UP * 2.5), 1.6, 1.4, "tissu112_rouge", 16, 6)
	kit.ball(Transform3D(Basis(), top + Vector3.UP * 4.0), 0.25, "laiton112", 8, 4)
	# la porte (côté port), la petite maison de la gardienne
	var dx := Transform3D(Basis.looking_at(-to_h, Vector3.UP), ph + to_h * 2.85 + Vector3.UP * 0.8)
	kit.door71(dx, "bois112")
	var hx := Transform3D(Basis.looking_at(-to_h, Vector3.UP), ph + to_h * 6.5 + to_h.cross(Vector3.UP) * 5.5)
	hx.origin.y = ile.height(hx.origin.x, hx.origin.z)
	var door2: Vector3 = kit.house112(hx, 6.0, 5.0, {"floors": 1, "roof": "pignon", "wall": "pierre112_clair", "lit": 0.8, "chimney": true, "balcons": false})
	city.doors["porte_margot"] = city._pt("porte_margot", door2)
	city._pt("phare_pt", ph + to_h * 4.5 + Vector3.UP * 0.85)
	city._link("porte_margot", "phare_pt")
	city._spot("phare_porte", ph + to_h * 3.6 + Vector3.UP * 0.85, to_h, "bras_croises", "phare_pt")
	# V116 : on entre dans le phare, et chez Margot
	portes116["hf_phare"] = [ph + to_h * 3.15 + Vector3.UP * 0.85, to_h]
	portes116["maison_margot"] = [door2 + Vector3.UP * 0.05, hx.basis * Vector3(0, 0, 1)]
	var rock: Vector3 = ph - to_h * 6.0
	rock.y = ile.height(rock.x, rock.z)
	city._pt("phare_rochers_pt", rock + to_h * 1.0 + Vector3.UP * 0.05)
	city._link("phare_rochers_pt", "phare_pt")
	city._spot("phare_rochers", rock + Vector3.UP * 0.05, -to_h, "observer", "phare_rochers_pt")
	# le faisceau qui tourne : deux cônes de lumière, et une vraie lumière
	phare_beam = Node3D.new()
	phare_beam.name = "Faisceau_phare"
	add_child(phare_beam)
	phare_beam.global_position = top + Vector3.UP * 1.3
	for s in [-1.0, 1.0]:
		var bm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.4
		cm.bottom_radius = 5.0
		cm.height = 46.0
		cm.radial_segments = 12
		cm.cap_top = false
		cm.cap_bottom = false
		bm.mesh = cm
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(1.0, 0.95, 0.75, 0.07)
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		bmat.no_depth_test = false
		bm.material_override = bmat
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bm.rotation = Vector3(0, 0, s * PI * 0.5)
		bm.position = Vector3(s * 23.0, 0, 0)
		phare_beam.add_child(bm)
	phare_light = OmniLight3D.new()
	phare_light.light_color = Color(1.0, 0.9, 0.62)
	phare_light.light_energy = 0.0
	phare_light.omni_range = 30.0
	phare_light.shadow_enabled = false
	add_child(phare_light)
	phare_light.global_position = top + Vector3.UP * 1.3
	objets["phare"] = ph
	flora_avoid.append([Vector2(ph.x, ph.z), 12.0])


# =================================================================== le moulin

func _moulin() -> void:
	var mp: Vector3 = ile.pads_world["moulin"]
	var ml: Vector2 = R.L(mp.x, mp.z)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var mx: Transform3D = GX(ml.x, ml.y, town)
	kit.windmill71(mx)
	var door: Vector3 = mx * Vector3(0, 0.25, -3.6)
	city.doors["porte_augustin"] = city._pt("porte_augustin", door)
	portes116["hf_moulin"] = [door, mx.basis * Vector3(0, 0, -1)]
	city._pt("moulin_pt", mx * Vector3(3.4, 0.05, -3.0))
	city._link("porte_augustin", "moulin_pt")
	city._spot("moulin_porte", mx * Vector3(2.2, 0.05, -4.2), mx.basis * Vector3(0, 0, -1), "bricoler", "moulin_pt")
	for k in range(3):
		kit.crate71(mx * Vector3(-3.6 - k * 0.6, 0, -2.0 + k * 0.4), k * 0.4, 0.6)
	for k2 in range(3):
		kit.cyl(Transform3D(Basis(), mx * Vector3(3.0 + k2 * 0.8, 0, 1.4)), 0.35, 0.3, 0.8, "foin71", 10)
	var ch: Vector3 = G(ml.x - 14.0, ml.y + 10.0, 0.05)
	city._pt("moulin_champ_pt", ch + Vector3(1.0, 0, 0))
	city._link("moulin_champ_pt", "moulin_pt")
	city._spot("moulin_champ", ch, Vector3(-1, 0, 0), "jardiner", "moulin_champ_pt")
	objets["moulin"] = mx.origin
	flora_avoid.append([Vector2(mp.x, mp.z), 10.0])


# =================================================================== les vergers

## Des rangées d'arbres fruitiers sur chaque terrasse (plantés par la flore), des murets de pierre
## au bord des marches, un abri de jardinier.
func _vergers() -> void:
	var a0: float = R.ORCH_A.x + 8.0
	var a1: float = R.ORCH_A.y - 8.0
	for step in range(5):
		var rr: float = R.ORCH_R0 + 4.2 + step * 9.0
		var n: int = int(deg_to_rad(a1 - a0) * rr / 6.5)
		for i in range(n):
			var a: float = lerpf(a0, a1, (i + 0.5) / n)
			var lp: Vector2 = R.polar(a, rr)
			if R.coast_q(lp.x, lp.y) > 0.9:
				continue
			orchard_spots.append(G(lp.x, lp.y))
		# le muret de la marche
		var rw: float = R.ORCH_R0 + 8.7 + step * 9.0
		var m: int = int(deg_to_rad(a1 - a0) * rw / 4.0)
		for j in range(m):
			var b0: float = lerpf(a0, a1, float(j) / m)
			var b1: float = lerpf(a0, a1, float(j + 1) / m)
			var p0v: Vector2 = R.polar(b0, rw)
			var p1v: Vector2 = R.polar(b1, rw)
			if R.coast_q(p0v.x, p0v.y) > 0.9 or R.coast_q(p1v.x, p1v.y) > 0.9:
				continue
			var p0: Vector3 = G(p0v.x, p0v.y)
			var p1: Vector3 = G(p1v.x, p1v.y)
			var yb: float = minf(p0.y, p1.y)
			var mid: Vector3 = (p0 + p1) * 0.5
			var d: Vector3 = p1 - p0
			kit.box(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), Vector3(mid.x, yb - 0.4, mid.z)), Vector3(0.6, 1.8, Vector2(d.x, d.z).length() + 0.05), "pierre112_sombre", 1.6)
	# l'abri du jardinier (au bout du chemin des vergers)
	var vp: Array = ile.paths_world.get("verger", [])
	var at: Vector3 = (vp[-1] as Vector3) if not vp.is_empty() else G(-26.0, 228.0)
	var town: Vector3 = R.W(R.TOWN.x, R.TOWN.y)
	var sx: Transform3D = Transform3D(Basis.looking_at(-(Vector3(town.x - at.x, 0, town.z - at.z).normalized()), Vector3.UP), at + Vector3(4.0, 0, 3.0))
	sx.origin.y = ile.height(sx.origin.x, sx.origin.z)
	kit.box(sx * T(0, 1.2, -1.5), Vector3(3.2, 2.4, 3.0), "planches71", 1.0)
	kit.col_box(sx * T(0, 1.2, -1.5), Vector3(3.2, 2.4, 3.0))
	kit.roof_gable(sx * T(0, 2.4, -1.5), 3.6, 3.4, 30.0, 0.25, "ardoise112", "planches71")
	kit.door71(sx * T(0.6, 0, 0.0), "planches71_sombre")
	for k in range(4):
		kit.crate71(sx * Vector3(-1.2 + k * 0.7, 0, 0.7), k * 0.3, 0.55)
	city._pt("verger_abri", sx * Vector3(0, 0.05, 1.6))
	portes116["hf_abri"] = [sx * Vector3(0.6, 0.05, 1.25), sx.basis * Vector3(0, 0, 1)]
	var v1: Vector3 = G(R.polar(78.0, R.ORCH_R0 + 7.0).x, R.polar(78.0, R.ORCH_R0 + 7.0).y, 0.05)
	var v2: Vector3 = G(R.polar(105.0, R.ORCH_R0 + 16.0).x, R.polar(105.0, R.ORCH_R0 + 16.0).y, 0.05)
	city._pt("verger_1_pt", v1 + Vector3(0.8, 0, 0))
	city._pt("verger_2_pt", v2 + Vector3(0.8, 0, 0))
	city._chain(["verger_abri", "verger_1_pt"])
	city._chain(["verger_abri", "verger_2_pt"])
	city._spot("verger_1", v1, Vector3(0, 0, 1), "jardiner", "verger_1_pt")
	city._spot("verger_2", v2, Vector3(-1, 0, 0), "jardiner", "verger_2_pt")
	objets["vergers"] = v1


# =================================================================== la plage

func _plage() -> void:
	var pp: Array = ile.paths_world.get("plage", [])
	var at: Vector3 = (pp[-1] as Vector3) if not pp.is_empty() else G(228.0, 48.0)
	var sea: Vector3 = R.W(300.0, 60.0)
	var out: Vector3 = Vector3(sea.x - at.x, 0, sea.z - at.z).normalized()
	var p: Vector3 = at + out * 6.0
	p.y = ile.height(p.x, p.z)
	city._pt("plage_pt", p + Vector3.UP * 0.05)
	city._spot("plage_1", p + out * 1.0 + Vector3.UP * 0.05, out, "observer", "plage_pt")
	# des cabines de bain rayées, un parasol
	for k in range(3):
		var cx: Vector3 = at - out * 2.0 + out.cross(Vector3.UP) * (-6.0 + k * 3.0)
		cx.y = ile.height(cx.x, cx.z)
		var bx := Transform3D(Basis.looking_at(-out, Vector3.UP), cx)
		kit.box(bx * T(0, 1.2, 0), Vector3(1.6, 2.4, 1.6), "planches71_clair", 1.0)
		kit.box(bx * T(0, 1.2, 0.81), Vector3(1.6, 2.4, 0.02), ["tissu112_bleu", "tissu112_rouge", "tissu112_vert"][k], 1.0, 16)
		kit.roof_gable(bx * T(0, 2.4, 0), 1.9, 1.9, 35.0, 0.1, "verdigris112", "planches71_clair")
		kit.col_box(bx * T(0, 1.2, 0), Vector3(1.6, 2.4, 1.6))
	kit.umbrella(Transform3D(Basis(), p + out * 3.0 + Vector3.UP * 2.3), 1.6, 0.35, "rouge")
	objets["plage"] = p


# =================================================================== les falaises

## Le belvédère des falaises (un garde-corps, un banc), les deux Arches de pierre dans la mer, la
## Cascade des Falaises (du haut de la falaise jusqu'à la mer, l'écume et la brume à son pied).
func _falaises() -> void:
	var bp: Vector3 = ile.pads_world["belvedere_falaise"]
	var sea_dir: Vector3 = Vector3(bp.x - R.CENTER.x, 0, bp.z - R.CENTER.z).normalized()
	var side: Vector3 = sea_dir.cross(Vector3.UP)
	for k in range(5):
		var a: Vector3 = bp + sea_dir * 5.5 + side * (-5.0 + k * 2.5)
		var b: Vector3 = bp + sea_dir * 5.5 + side * (-2.5 + k * 2.5)
		a.y = bp.y
		b.y = bp.y
		if k < 4:
			kit.railing70(a, b, 1.1)
	var bx := Transform3D(Basis.looking_at(-sea_dir, Vector3.UP), bp + sea_dir * 2.5)
	kit.bench112(bx)
	city._pt("falaise_pt", bp + Vector3.UP * 0.05)
	city._spot("falaise_1", bp + sea_dir * 4.4 + side * 2.0 + Vector3.UP * 0.05, sea_dir, "observer", "falaise_pt")
	objets["falaises"] = bp
	# les Arches : deux grandes arches de roche, les pieds dans la mer
	for e in [[128.0, 266.0, 0.0], [206.0, 262.0, 1.0]]:
		var ac: Vector2 = R.polar(float(e[0]), float(e[1]))
		var w: Vector3 = R.W(ac.x, ac.y, -6.0)
		var rad: Vector3 = Vector3(ac.x, 0, ac.y).normalized()
		_arche(w, rad.cross(Vector3.UP), 26.0 + float(e[2]) * 6.0, 22.0 + float(e[2]) * 4.0)
	# la Cascade des Falaises
	var ca: float = R.CASCADE_DEG
	var lip_l: Vector2 = Vector2.ZERO
	for i in range(80):
		var r: float = 200.0 + i * 0.6
		var pl: Vector2 = R.polar(ca, r)
		if R.coast_q(pl.x, pl.y) > 0.985:
			break
		lip_l = pl
	var lip: Vector3 = G(lip_l.x, lip_l.y)
	var out: Vector3 = Vector3(lip_l.x, 0, lip_l.y).normalized()
	cascade_top = lip + Vector3.UP * 0.4
	cascade_foot = Vector3(lip.x + out.x * 5.0, R.WATER, lip.z + out.z * 5.0)
	var fall: Array = []
	for k2 in range(18):
		var t: float = float(k2) / 17.0
		fall.append(cascade_top + out * (0.3 + 4.4 * sqrt(t)) - Vector3.UP * (cascade_top.y - R.WATER + 0.3) * t)
	var cas: MeshInstance3D = _ribbon("Cascade_des_falaises", fall, 5.0)
	var wm := ShaderMaterial.new()
	wm.shader = load(CHUTE)
	wm.set_shader_parameter("fall_length", cascade_top.y - R.WATER)
	wm.set_shader_parameter("water_color", Color(0.62, 0.78, 0.82))
	cas.material_override = wm
	# le ruisseau qui y mène (un ruban d'eau posé sur le plateau)
	var brook: Array = []
	for k3 in range(10):
		var rr: float = 186.0 + k3 * (Vector2(lip_l).length() - 186.0) / 9.0
		var pb: Vector2 = R.polar(ca + sin(k3 * 0.9) * 1.6, rr)
		brook.append(G(pb.x, pb.y, 0.12))
	var br: MeshInstance3D = _ribbon_flat("Ruisseau_des_falaises", brook, 2.0)
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.3, 0.5, 0.56, 0.75)
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em.roughness = 0.05
	br.material_override = em
	_foam(cascade_foot)


## Une arche de roche : deux piles irrégulières et un linteau courbe (c : le milieu, au fond ; along :
## la direction du passage sous l'arche ; span : l'écart des piles ; h : la hauteur).
func _arche(c: Vector3, along: Vector3, span: float, h: float) -> void:
	var side: Vector3 = along.cross(Vector3.UP).normalized()
	var n: int = 12
	var prev: Vector3 = Vector3.INF
	for i in range(n + 1):
		var t: float = float(i) / n
		var ang: float = PI * t
		var p: Vector3 = c + side * (-cos(ang) * span * 0.5) + Vector3.UP * (sin(ang) * h + 6.0 * (1.0 - sin(ang)) * 0.0)
		if prev != Vector3.INF:
			var thick: float = lerpf(7.0, 4.2, sin(ang))
			kit.beam(prev, p, thick, "roche71", 2.5)
		prev = p
	for s in [-1.0, 1.0]:
		var foot: Vector3 = c + side * s * span * 0.5
		kit.cyl(Transform3D(Basis(), foot + Vector3.DOWN * 2.0), 6.0, 4.4, 10.0, "roche71", 9, true, 3.0)
		kit.col_cyl(foot + Vector3.DOWN * 2.0, 5.0, 12.0)
	flora_avoid.append([Vector2(c.x, c.z), span])


func _ribbon(label: String, pts: Array, wid: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for i in range(pts.size()):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var c: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t: Vector3 = (c - a).normalized()
		var side: Vector3 = Vector3(t.x, 0, t.z).cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		var n: Vector3 = side.cross(t).normalized()
		var w: float = wid * lerpf(0.8, 1.25, float(i) / (pts.size() - 1))
		var p: Vector3 = pts[i]
		rows.append([p - side * w * 0.5, p + side * w * 0.5, n, float(i) / (pts.size() - 1)])
	for i in range(rows.size() - 1):
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var quad: Array = [[r0[0], Vector2(0, r0[3]), r0[2]], [r0[1], Vector2(1, r0[3]), r0[2]], [r1[1], Vector2(1, r1[3]), r1[2]], [r1[0], Vector2(0, r1[3]), r1[2]]]
		var face: Vector3 = ((quad[1][0] as Vector3) - (quad[0][0] as Vector3)).cross((quad[2][0] as Vector3) - (quad[0][0] as Vector3))
		var order: Array = [0, 2, 1, 0, 3, 2] if face.dot(r0[2]) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_uv(quad[k][1])
			st.set_normal(quad[k][2])
			st.add_vertex(quad[k][0])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _ribbon_flat(label: String, pts: Array, wid: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = (b - a)
		var side: Vector3 = Vector3(d.x, 0, d.z).cross(Vector3.UP).normalized() * wid * 0.5
		for v in [a - side, b - side, b + side, a - side, b + side, a + side]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2((v as Vector3).x, (v as Vector3).z) * 0.2)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _foam(at: Vector3) -> void:
	var sp := CPUParticles3D.new()
	sp.name = "Ecume_de_la_cascade"
	sp.amount = 60
	sp.lifetime = 1.4
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(2.4, 0.2, 1.4)
	sp.direction = Vector3.UP
	sp.spread = 40.0
	sp.initial_velocity_min = 2.0
	sp.initial_velocity_max = 4.5
	sp.gravity = Vector3(0, -9.8, 0)
	sp.scale_amount_min = 0.6
	sp.scale_amount_max = 1.4
	var dm := SphereMesh.new()
	dm.radius = 0.14
	dm.height = 0.28
	dm.radial_segments = 6
	dm.rings = 3
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.97, 0.97, 0.96)
	fm.roughness = 0.4
	dm.material = fm
	sp.mesh = dm
	sp.visibility_range_end = 300.0
	add_child(sp)
	sp.global_position = at + Vector3.UP * 0.1


# =================================================================== les poteaux indicateurs

func _panneaux() -> void:
	for g in ["port", "verger", "moulin", "est"]:
		var a: float = float(R.GATES[g])
		var lp: Vector2 = R.polar(a + 6.0, R.TOWN_R + 12.0)
		var p: Vector3 = G(lp.x, lp.y)
		kit.box(Transform3D(Basis(), p + Vector3.UP * 1.3), Vector3(0.14, 2.6, 0.14), "acier112", 1.0)
		for k in range(3):
			var ya: float = k * 2.1 + a * 0.02
			kit.box(Transform3D(Basis(Vector3.UP, ya), p + Vector3.UP * (2.25 - k * 0.34)), Vector3(1.1, 0.22, 0.05), "laiton112_vieux", 1.0)
		kit.ball(Transform3D(Basis(), p + Vector3.UP * 2.7), 0.1, "laiton112", 6, 3)
		kit.col_box(Transform3D(Basis(), p + Vector3.UP * 1.3), Vector3(0.3, 2.6, 0.3))


# =================================================================== le réseau

func _graph() -> void:
	var starts := {"port": "dehors_port", "phare": "", "plage": "dehors_est", "moulin": "dehors_moulin", "verger": "dehors_verger", "falaise": "dehors_verger"}
	var ends := {"port": "port_cap", "phare": "phare_pt", "plage": "plage_pt", "moulin": "moulin_pt", "verger": "verger_abri", "falaise": "falaise_pt"}
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		if pts.size() < 2:
			continue
		var prev: String = ""
		var acc: float = 0.0
		for i in range(pts.size()):
			if i > 0:
				acc += (pts[i] as Vector3).distance_to(pts[i - 1])
			if i == 0 or i == pts.size() - 1 or acc > 11.0:
				acc = 0.0
				var nm: String = city._pt("ch_%s_%d" % [str(k), i], (pts[i] as Vector3) + Vector3.UP * 0.05)
				if prev != "":
					city._link(prev, nm)
				elif str(starts.get(k, "")) != "" and city.points.has(str(starts[k])):
					city._link(str(starts[k]), nm)
				else:
					city._link(city._nearest_point(pts[i] as Vector3, "ch_" + str(k)), nm)
				prev = nm
		if ends.has(k) and city.points.has(str(ends[k])):
			city._link(prev, str(ends[k]))
	# le chemin du phare part du port
	if city.points.has("ch_phare_0"):
		city._link("ch_phare_0", "port_q1")


## La vie du dehors : le faisceau du phare tourne ; la grue pivote ; le phare s'allume la nuit.
func tick(delta: float, clock: float, night_k: float) -> void:
	if phare_beam != null:
		phare_beam.rotate_y(delta * 0.6)
		phare_beam.visible = night_k > 0.2
	if phare_light != null:
		phare_light.light_energy = 4.0 * night_k
	if crane_arm != null:
		crane_arm.rotation.y += sin(clock * 0.07) * delta * 0.05

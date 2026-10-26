extends Node3D
## V76 : Astralys, la cité de cristal et de lumière des Lumens, posée sur l'île flottante
## (ile_astrale_v76). Un plan rayonnant : la Flèche de Cristal au centre (et la Salle du Conseil à
## son pied), un anneau de dalles autour du dais, huit avenues de sable stellaire vers le bord, une
## avenue circulaire ; l'Agora des Étoiles et sa fontaine holographique au sud, le Café Nébuleuse et
## le Bazar galactique de part et d'autre ; le Musée des Mondes et l'Académie des Sciences ;
## l'Observatoire sur son îlot (au nord) ; le Spatioport (à l'est-sud-est) ; les Jardins suspendus
## (au sud-ouest) et l'îlot du Jardin des Apesanteurs ; la Serre des Espèces ; le Portail d'accueil
## et le belvédère du Rayon (au sud-est) ; les quartiers des bulles (les maisons des Lumens).
## Pour les habitants : des points (un graphe), des lieux (« spots »), les portes des maisons.

const R = preload("res://scripts/ile_astrale_v76.gd")
const Kit = preload("res://scripts/astrale_kit_v76.gd")
const Mats = preload("res://scripts/astrale_mats_v76.gd")

## Les grands lieux (repère local) : [nom, centre, rayon] (rien d'autre n'y pousse).
const AGORA := Vector2(0.0, 52.0)
const CAFE := Vector2(-32.0, 38.0)
const BAZAR := Vector2(32.0, 38.0)
const MUSEE := Vector2(-62.0, -26.0)
const ACADEMIE := Vector2(62.0, -26.0)
const SPATIOPORT := Vector2(108.0, 58.0)
const JARDINS := Vector2(-92.0, 58.0)
const SERRE := Vector2(126.0, -26.0)
const PORTAIL := Vector2(130.0, 130.0)
const RESERVED := [[Vector2(0.0, 0.0), 44.0], [AGORA, 22.0], [CAFE, 12.0], [BAZAR, 12.0], [MUSEE, 17.0], [ACADEMIE, 17.0],
	[SPATIOPORT, 34.0], [JARDINS, 34.0], [SERRE, 18.0], [PORTAIL, 16.0], [Vector2(0.0, -180.0), 12.0], [Vector2(-150.0, 106.0), 12.0]]
## Les 26 Lumens (leurs maisons-bulles).
const HABITANTS := ["astree", "orbe", "quasar", "ionie", "comete", "gloubi", "nebula", "photon", "zenith", "halo", "pixel", "quark", "glorb",
	"lyre", "aurore", "vibrato", "nova", "volt", "prisme", "sextant", "bulle", "murmure", "ecliptique", "hologuide", "tempo", "solenne"]

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}              # nom -> Vector3 (les comptoirs, les lieux des quêtes)
var flora_avoid: Array = []
var tree_spots: Array = []
var houses: Array = []                   # {door, x, z, owner}
var bridges: Array = []                  # [a, b] : les ponts de lumière (le gestionnaire les allume)
var holo_planets: Array = []             # les planètes de la fontaine (MeshInstance3D)
var fountain_top := Vector3.ZERO
var heart := Vector3.ZERO                # le Cœur de la Flèche (monde)
var heart_light: OmniLight3D
var hoops: Array = []                    # les anneaux du parcours des apesanteurs (monde)
var rayon_top := Vector3.ZERO            # le belvédère du Rayon (monde, au sol)
var portail_point := Vector3.ZERO
var council := Vector3.ZERO
var stage := Vector3.ZERO                # la petite scène de l'Agora (les spectacles du soir)
var telescope := Vector3.ZERO
var hangar := Vector3.ZERO
var creatures_at: Array = []             # [Vector3, rayon] : là où les méduses de ciel flottent (la Serre)
var _zones: Array = []                   # [nom, centre local, rayon]
var _rng := RandomNumberGenerator.new()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Un point au sol de la cité (repère local x, z), dy au-dessus.
func G(x: float, z: float, dy: float = 0.05) -> Vector3:
	return R.W(x, z, ile.top_local(x, z) + dy)


func GV(l: Vector2, dy: float = 0.05) -> Vector3:
	return G(l.x, l.y, dy)


## Un repère au sol en (x, z) dont le +Z regarde la direction (dx, dz).
func XF(x: float, z: float, dx: float, dz: float, dy: float = 0.0) -> Transform3D:
	var d := Vector3(dx, 0.0, dz).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), G(x, z, dy))


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String = "") -> void:
	spots[name] = {"pos": pos, "face": face.normalized() if face.length() > 0.01 else Vector3(0, 0, 1), "pose": pose, "node": node}


func _pt(name: String, p: Vector3) -> String:
	points[name] = p
	return name


func _link(a: String, b: String) -> void:
	if a == b or not points.has(a) or not points.has(b):
		return
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


func _chain(names: Array) -> void:
	for i in range(names.size() - 1):
		_link(str(names[i]), str(names[i + 1]))


func _avoid(l: Vector2, r: float) -> void:
	var w: Vector3 = R.W(l.x, l.y)
	flora_avoid.append([Vector2(w.x, w.z), r])


func _zone(name: String, c: Vector2, r: float) -> void:
	_zones.append([name, c, r])


func nearest(p: Vector3, prefix: String = "") -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		if prefix != "" and not str(k).begins_with(prefix):
			continue
		var d: float = (points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(k)
	return best


func _free(l: Vector2, r: float) -> bool:
	for rs in RESERVED:
		if l.distance_to(rs[0]) < float(rs[1]) + r:
			return false
	return true


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 7671
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 7672
	kit.light_every = 4
	_streets()
	_fleche()
	_agora()
	_cafe_bazar()
	_musee_academie()
	_observatoire()
	_spatioport()
	_jardins()
	_apesanteur()
	_serre()
	_portail()
	_bulles()
	_wild()
	_lamps()
	kit.commit()
	_planets()
	_street_spots()
	print("ILE_MANGA_V76: Astralys bâtie, %d maisons, %d lieux, %d points, en %d ms" % [houses.size(), spots.size(), points.size(), Time.get_ticks_msec() - t0])


# =================================================================== les avenues

func _streets() -> void:
	# l'anneau du dais (r = 38), seize points
	var inner: Array = []
	for k in range(16):
		var a: float = TAU * k / 16.0
		inner.append(_pt("in_%d" % k, G(cos(a) * 38.0, sin(a) * 38.0)))
	inner.append(inner[0])
	_chain(inner)
	# l'avenue circulaire (r = 112)
	var ring_names: Array = []
	for k2 in range(56):
		var a2: float = TAU * k2 / 56.0
		ring_names.append(_pt("an_%d" % k2, G(cos(a2) * 112.0, sin(a2) * 112.0)))
	ring_names.append(ring_names[0])
	_chain(ring_names)
	# les huit avenues (de l'anneau du dais jusqu'au bord, r = 150)
	for s in range(8):
		var a3: float = TAU * s / 8.0
		var d := Vector2(cos(a3), sin(a3))
		var names: Array = ["in_%d" % (s * 2)]
		var r0: float = 50.0 if s != 2 else 66.0
		var r: float = r0
		while r <= 150.0:
			if absf(r - 112.0) < 6.0:
				names.append("an_%d" % (s * 7))
			else:
				names.append(_pt("av_%d_%d" % [s, int(r)], GV(d * r)))
			r += 12.0
		_chain(names)


func _street_spots() -> void:
	var rues := [["rue_1", 0.0, 112.0], ["rue_2", 90.0, 112.0], ["rue_3", 180.0, 112.0], ["rue_4", 270.0, 112.0], ["rue_5", 45.0, 86.0], ["rue_6", 225.0, 86.0]]
	for rr in rues:
		var a: float = deg_to_rad(float(rr[1]) + 6.0)
		var l := Vector2(cos(a), sin(a)) * float(rr[2])
		var p: Vector3 = GV(l)
		_spot(str(rr[0]), p, -Vector3(l.x, 0, l.y), "debout", nearest(p, "an_") if float(rr[2]) > 100.0 else nearest(p, "av_"))


# =================================================================== la Flèche de Cristal

func _fleche() -> void:
	var c: Vector3 = G(0.0, 0.0, 0.0)
	var f: Dictionary = kit.spire76(c)
	heart = f["heart"]
	council = f["council"]
	# la table ronde du Conseil (dans la salle), ses sièges
	kit.cyl(Transform3D(Basis(), council + Vector3(0, 0, -2.0)), 1.6, 1.6, 0.8, "nacre76_or", 24)
	kit.disc(Transform3D(Basis(), council + Vector3(0, 0.82, -2.0)), 1.55, "cristal76_or", 24)
	kit.col_cyl(council + Vector3(0, 0, -2.0), 1.6, 0.9)
	_pt("fl_porte", f["hall_door"])
	_pt("fl_dedans", c + Vector3(0, 0.05, 9.0))
	_pt("fl_conseil", council + Vector3(0, 0, 1.5))
	_chain(["in_4", "fl_porte", "fl_dedans", "fl_conseil"])
	_spot("conseil_doyenne", council + Vector3(0, 0, -4.2), Vector3(0, 0, 1), "assis", "fl_conseil")
	_spot("conseil_1", council + Vector3(-2.6, 0, -1.6), Vector3(1, 0, 0), "assis", "fl_conseil")
	_spot("conseil_2", council + Vector3(2.6, 0, -1.6), Vector3(-1, 0, 0), "assis", "fl_conseil")
	_spot("fleche_base", f["hall_door"] + Vector3(2.5, 0, 1.0), Vector3(0, 0, 1), "bras_croises", "fl_porte")
	objets["conseil"] = council
	objets["fleche_coeur"] = heart
	# le Cœur : une boule de lumière, une vraie lumière (le gestionnaire la fait battre)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 3.0
	sm.height = 6.0
	mi.mesh = sm
	mi.material_override = Mats.make("lumiere76_blanc")
	add_child(mi)
	mi.global_position = heart
	mi.name = "Coeur_de_la_Fleche"
	heart_light = OmniLight3D.new()
	heart_light.light_color = Color(0.75, 0.85, 1.0)
	heart_light.light_energy = 3.0
	heart_light.omni_range = 60.0
	heart_light.shadow_enabled = false
	add_child(heart_light)
	heart_light.global_position = heart
	_zone("as_fleche", Vector2.ZERO, 16.0)


# =================================================================== l'Agora des Étoiles

func _agora() -> void:
	fountain_top = kit.fountain76(GV(AGORA, 0.0), 6.5)
	objets["fontaine"] = GV(AGORA + Vector2(0, -8.0))
	objets["meteorite_1"] = GV(AGORA + Vector2(10.5, 7.0), 0.05)
	_pt("ag_nord", GV(AGORA + Vector2(0, -10.0)))
	_pt("ag_est", GV(AGORA + Vector2(10.0, 0)))
	_pt("ag_ouest", GV(AGORA + Vector2(-10.0, 0)))
	_pt("ag_sud", GV(AGORA + Vector2(0, 11.0)))
	_chain(["in_4", "ag_nord", "ag_est", "ag_sud", "ag_ouest", "ag_nord"])
	_link("ag_sud", "av_2_66")
	_link("ag_est", "in_3")
	_link("ag_ouest", "in_5")
	_spot("agora_fontaine", GV(AGORA + Vector2(6.0, -6.0)), Vector3(-1, 0, 1), "debout", "ag_nord")
	# trois bancs qui flottent, tournés vers la fontaine
	var bancs := [[Vector2(-11.0, 6.0), "agora_banc_1"], [Vector2(11.0, 6.0), "agora_banc_2"], [Vector2(0.0, -12.5), "agora_banc_3"]]
	for b in bancs:
		var l: Vector2 = AGORA + (b[0] as Vector2)
		var to_c: Vector2 = (AGORA - l).normalized()
		var seat: Vector3 = kit.bench76(XF(l.x, l.y, to_c.x, to_c.y))
		_spot(str(b[1]), seat - Vector3(0, 0.45, 0), Vector3(to_c.x, 0, to_c.y), "assis", "ag_sud" if l.y > AGORA.y else "ag_nord")
	# la petite scène ronde des spectacles du soir (Prisme y danse)
	var sc: Vector2 = AGORA + Vector2(-15.0, 14.0)
	kit.cyl(Transform3D(Basis(), GV(sc, 0.0)), 4.0, 4.0, 0.4, "nacre76_lavande", 28)
	kit.glow_ring76(Transform3D(Basis(), GV(sc, 0.42)), 3.8, 0.12, "violet", 28)
	kit.col_cyl(GV(sc, 0.0), 4.0, 0.4)
	stage = GV(sc, 0.42)
	_pt("ag_scene", GV(sc + Vector2(5.0, -4.0)))
	_link("ag_scene", "ag_ouest")
	_link("ag_scene", "ag_sud")
	_spot("agora_holo", stage, Vector3(1, 0, -1), "danse", "ag_scene")
	# des hologrammes autour de l'Agora
	kit.holo76(XF(AGORA.x + 16.0, AGORA.y - 2.0, -1.0, 0.0, 3.2), 2.4, 1.6, 1)
	kit.holo76(XF(AGORA.x - 4.0, AGORA.y + 18.0, 0.0, -1.0, 3.2), 2.4, 1.6, 2)
	_zone("as_agora", AGORA, 22.0)


# =================================================================== le Café Nébuleuse et le Bazar galactique

func _cafe_bazar() -> void:
	# le Café (porte vers l'est, vers l'Agora)
	var cf: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(CAFE, 0.0)), 9.0, 5.0, {"door_dir": Vector3(1, 0, 0.35), "glow": "violet"})
	var ci: Vector3 = cf["inside"]
	kit.quadz(Transform3D(Basis(Vector3.UP, PI * 0.5 - 0.34), (cf["door"] as Vector3) + Vector3(-0.5, 5.6, -0.2)), 4.0, 2.0, "enseigne76_cafe")
	# le comptoir (un arc de nacre), les tables rondes
	var cc: Vector3 = ci + Vector3(-5.0, 0, 0)
	kit.box(Transform3D(Basis(), cc + Vector3(0, 0.55, 0)), Vector3(0.8, 1.1, 5.0), "nacre76_lavande", 1.0)
	kit.box(Transform3D(Basis(), cc + Vector3(0, 1.12, 0)), Vector3(0.95, 0.06, 5.2), "cristal76_violet", 1.0)
	kit.col_box(Transform3D(Basis(), cc + Vector3(0, 0.55, 0)), Vector3(0.8, 1.1, 5.0))
	_pt("ca_porte", cf["door"])
	_pt("ca_dedans", ci + Vector3(2.0, 0, 0))
	_pt("ca_derriere", cc + Vector3(-1.3, 0, 0))
	_chain(["ca_porte", "ca_dedans"])
	_link("ca_dedans", "ca_derriere")
	_link("ca_porte", "ag_ouest")
	_link("ca_porte", "in_6")
	_spot("cafe_comptoir", cc + Vector3(-1.1, 0, 0), Vector3(1, 0, 0), "comptoir", "ca_derriere")
	objets["cafe_comptoir"] = cc + Vector3(1.0, 0, 0)
	var tabs := [Vector2(1.5, -4.0), Vector2(1.5, 3.5), Vector2(4.5, -0.5)]
	for i in range(tabs.size()):
		var tp: Vector3 = ci + Vector3(tabs[i].x, 0, tabs[i].y)
		kit.cyl(Transform3D(Basis(), tp), 0.1, 0.1, 0.75, "metal76_", 8)
		kit.cyl(Transform3D(Basis(), tp + Vector3(0, 0.75, 0)), 0.6, 0.6, 0.05, "nacre76_", 16)
		kit.col_cyl(tp, 0.6, 0.8)
		_spot("cafe_table_%d" % (i + 1), tp + Vector3(-1.0, 0, 0), Vector3(1, 0, 0), "assis", "ca_dedans")
	# la terrasse, dehors
	var tq: Vector3 = (cf["door"] as Vector3) + Vector3(2.5, 0, -4.0)
	kit.cyl(Transform3D(Basis(), tq), 0.1, 0.1, 0.75, "metal76_", 8)
	kit.cyl(Transform3D(Basis(), tq + Vector3(0, 0.75, 0)), 0.6, 0.6, 0.05, "nacre76_", 16)
	kit.col_cyl(tq, 0.6, 0.8)
	_spot("cafe_table_4", tq + Vector3(0, 0, 1.0), Vector3(0, 0, -1), "assis", "ca_porte")
	_zone("as_cafe", CAFE, 9.0)
	# le Bazar (porte vers l'ouest, vers l'Agora)
	var bz: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(BAZAR, 0.0)), 9.0, 5.0, {"door_dir": Vector3(-1, 0, 0.35), "glow": "or"})
	var bi: Vector3 = bz["inside"]
	kit.quadz(Transform3D(Basis(Vector3.UP, -PI * 0.5 + 0.34), (bz["door"] as Vector3) + Vector3(0.5, 5.6, -0.2)), 4.0, 2.0, "enseigne76_bazar")
	var bc: Vector3 = bi + Vector3(5.0, 0, 0)
	kit.box(Transform3D(Basis(), bc + Vector3(0, 0.55, 0)), Vector3(0.8, 1.1, 5.0), "nacre76_or", 1.0)
	kit.box(Transform3D(Basis(), bc + Vector3(0, 1.12, 0)), Vector3(0.95, 0.06, 5.2), "cristal76_or", 1.0)
	kit.col_box(Transform3D(Basis(), bc + Vector3(0, 0.55, 0)), Vector3(0.8, 1.1, 5.0))
	# des étals : des vitrines de cristal avec des objets de toute la galaxie (des cristaux, des boules)
	for k in range(2):
		var ep: Vector3 = bi + Vector3(-1.5, 0, -3.5 + k * 7.0)
		kit.box(Transform3D(Basis(), ep + Vector3(0, 0.45, 0)), Vector3(2.2, 0.9, 1.0), "metal76_", 1.0)
		kit.box(Transform3D(Basis(), ep + Vector3(0, 1.2, 0)), Vector3(2.2, 0.6, 1.0), "verre76", 1.0)
		for q in range(4):
			kit.place("cristal76|" + ["bleu", "rose", "violet", "turquoise"][q], Transform3D(Basis().scaled(Vector3.ONE * 0.25), ep + Vector3(-0.8 + q * 0.5, 0.92, 0)))
		kit.col_box(Transform3D(Basis(), ep + Vector3(0, 0.75, 0)), Vector3(2.2, 1.5, 1.0))
		_spot("bazar_etal_%d" % (k + 1), ep + Vector3(-1.2, 0, 0), Vector3(1, 0, 0), "observer", "bz_dedans")
	_pt("bz_porte", bz["door"])
	_pt("bz_dedans", bi + Vector3(-2.0, 0, 0))
	_pt("bz_derriere", bc + Vector3(1.3, 0, 0))
	_chain(["bz_porte", "bz_dedans", "bz_derriere"])
	_link("bz_porte", "ag_est")
	_link("bz_porte", "in_2")
	_spot("bazar_comptoir", bc + Vector3(1.1, 0, 0), Vector3(-1, 0, 0), "comptoir", "bz_derriere")
	objets["bazar_comptoir"] = bc + Vector3(-1.0, 0, 0)
	_zone("as_bazar", BAZAR, 9.0)


# =================================================================== le Musée des Mondes, l'Académie des Sciences

func _musee_academie() -> void:
	# le Musée (porte au sud, vers l'avenue de l'ouest)
	var mu: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(MUSEE, 0.0)), 13.0, 7.0, {"door_dir": Vector3(0.4, 0, 1), "glow": "or"})
	var mi: Vector3 = mu["inside"]
	kit.quadz(Transform3D(Basis(Vector3.UP, 0.38), (mu["door"] as Vector3) + Vector3(-0.6, 7.6, -1.5)), 5.0, 2.5, "enseigne76_musee")
	# les vitrines : des objets de toutes les îles (des formes simples, sous des cloches de verre)
	var pieces := ["metal76_or", "cristal76_rose", "nacre76_", "metal76_bleu", "cristal76_turquoise", "metal76_sombre"]
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.5
		var vp: Vector3 = mi + Vector3(cos(a) * 7.5, 0, sin(a) * 7.5)
		kit.cyl(Transform3D(Basis(), vp), 0.5, 0.5, 1.0, "nacre76_", 12)
		kit.ball(Transform3D(Basis(), vp + Vector3(0, 1.25, 0)), 0.22, pieces[k], 8, 5)
		kit.cyl(Transform3D(Basis(), vp + Vector3(0, 1.0, 0)), 0.45, 0.45, 0.7, "verre76", 12, true)
		kit.col_cyl(vp, 0.55, 1.8)
	kit.holo76(Transform3D(Basis(), mi + Vector3(0, 3.0, 0)), 3.0, 2.0, 3)
	kit.quadz(Transform3D(Basis(Vector3.UP, PI), mi + Vector3(0, 3.6, 11.9)), 9.0, 4.5, "fresque76_2")
	_pt("mu_porte", mu["door"])
	_pt("mu_dedans", mi + Vector3(0, 0, 4.0))
	_pt("mu_fond", mi + Vector3(0, 0, -4.0))
	_spot("cache_musee", mi + Vector3(-4.5, 0, -4.0), Vector3(1, 0, 0), "assis", "mu_fond")
	_chain(["mu_porte", "mu_dedans", "mu_fond"])
	_link("mu_porte", nearest(mu["door"], "av_"))
	_link("mu_porte", nearest(mu["door"], "in_"))
	_spot("musee_accueil", mi + Vector3(3.0, 0, 6.5), Vector3(0, 0, 1), "comptoir", "mu_dedans")
	_spot("musee_salle_1", mi + Vector3(-3.5, 0, -2.0), Vector3(-1, 0, -0.4), "observer", "mu_fond")
	_spot("musee_salle_2", mi + Vector3(3.5, 0, -3.0), Vector3(1, 0, -0.4), "observer", "mu_fond")
	objets["musee"] = mi + Vector3(3.0, 0, 8.0)
	_zone("as_musee", MUSEE, 13.0)
	# l'Académie (porte au sud)
	var ac: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(ACADEMIE, 0.0)), 13.0, 7.0, {"door_dir": Vector3(-0.4, 0, 1), "glow": "bleu"})
	var ai: Vector3 = ac["inside"]
	kit.quadz(Transform3D(Basis(Vector3.UP, -0.38), (ac["door"] as Vector3) + Vector3(0.6, 7.6, -1.5)), 5.0, 2.5, "enseigne76_academie")
	# le tableau d'équations (un grand hologramme), les bancs des élèves, deux paillasses
	kit.holo76(Transform3D(Basis(), ai + Vector3(0, 2.8, -7.0)), 6.0, 3.0, 4)
	for k2 in range(2):
		var bp: Vector3 = ai + Vector3(-2.5 + k2 * 5.0, 0, 1.0)
		kit.box(Transform3D(Basis(), bp + Vector3(0, 0.45, 0)), Vector3(3.0, 0.08, 0.7), "nacre76_bleu", 1.0)
		kit.col_box(Transform3D(Basis(), bp + Vector3(0, 0.25, 0)), Vector3(3.0, 0.5, 0.7))
		_spot("academie_eleve_%d" % (k2 + 1), bp + Vector3(0, 0, 0.8), Vector3(0, 0, -1), "assis", "ac_dedans")
	for k3 in range(2):
		var lp: Vector3 = ai + Vector3(-8.0 + k3 * 16.0, 0, -2.0)
		kit.box(Transform3D(Basis(), lp + Vector3(0, 0.5, 0)), Vector3(1.0, 1.0, 3.0), "metal76_", 1.0)
		kit.ball(Transform3D(Basis(), lp + Vector3(0, 1.3, 0.6)), 0.25, "lumiere76_vert", 8, 5)
		kit.cyl(Transform3D(Basis(), lp + Vector3(0, 1.0, -0.6)), 0.15, 0.04, 0.5, "verre76", 8)
		kit.col_box(Transform3D(Basis(), lp + Vector3(0, 0.5, 0)), Vector3(1.0, 1.0, 3.0))
		if k3 == 0:
			objets["puce_holo_1"] = lp + Vector3(0, 1.02, 0.9)
		_spot("academie_labo_%d" % (k3 + 1), lp + Vector3(1.0 if k3 == 0 else -1.0, 0, 0), Vector3(-1 if k3 == 0 else 1, 0, 0), "bricoler", "ac_dedans")
	_pt("ac_porte", ac["door"])
	_pt("ac_dedans", ai + Vector3(0, 0, 4.0))
	_pt("ac_fond", ai + Vector3(0, 0, -4.5))
	_chain(["ac_porte", "ac_dedans", "ac_fond"])
	_link("ac_porte", nearest(ac["door"], "av_"))
	_link("ac_porte", nearest(ac["door"], "in_"))
	_spot("academie_tableau", ai + Vector3(0, 0, -5.2), Vector3(0, 0, 1), "holo", "ac_fond")
	objets["academie"] = ai + Vector3(0, 0, 6.0)
	_zone("as_academie", ACADEMIE, 13.0)


# =================================================================== l'Observatoire (sur son îlot)

func _observatoire() -> void:
	var top: Vector3 = ile.islet_tops["observatoire"]
	var lt: Vector2 = R.L(top.x, top.z)
	# le pont de lumière, du bord nord du plateau jusqu'à l'îlot
	var a: Vector3 = G(0.0, -184.0, 0.1)
	var b: Vector3 = Vector3(top.x, top.y + 0.1, top.z + 18.0)
	kit.bridge76(a, b, 3.2, "bleu")
	bridges.append([a, b])
	var ob: Dictionary = kit.pavilion76(Transform3D(Basis(), top + Vector3(0, 0, -2.0)), 9.0, 6.0, {"door_dir": Vector3(0, 0, 1), "glow": "bleu", "roof": "none"})
	# la coupole ouverte : un demi-dôme, une fente ; le télescope
	kit.dome76(Transform3D(Basis(), top + Vector3(0, 6.0, -2.0)), 9.3, 5.0, "metal76_bleu", 30, 6, 0)
	telescope = top + Vector3(0, 0.05, -2.0)
	kit.telescope76(Transform3D(Basis(), telescope))
	kit.quadz(Transform3D(Basis(), (ob["door"] as Vector3) + Vector3(0, 6.4, -1.4)), 4.0, 2.0, "enseigne76_observatoire")
	_pt("ob_pont_haut", a)
	_pt("ob_pont_bas", b)
	_pt("ob_porte", ob["door"])
	_pt("ob_dedans", telescope + Vector3(0, 0, 4.0))
	_chain(["av_6_146", "ob_pont_haut", "ob_pont_bas", "ob_porte", "ob_dedans"])
	_spot("observatoire_telescope", telescope + Vector3(2.0, 0, 2.6), Vector3(-0.4, 0, -1), "observer", "ob_dedans")
	_spot("observatoire_pont", b + Vector3(2.0, 0, 2.0), Vector3(0, 0, 1), "observer", "ob_pont_bas")
	objets["telescope"] = telescope + Vector3(0, 0, 3.0)
	objets["coeur_fleche_1"] = b + Vector3(-2.2, 0.0, -1.5)
	_zone("as_observatoire", lt, 22.0)


# =================================================================== le Spatioport

func _spatioport() -> void:
	var c: Vector2 = SPATIOPORT
	# le hangar : un grand pavillon ouvert à l'ouest (deux portes : on le traverse)
	var hg: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(c + Vector2(6.0, -8.0), 0.0)), 14.0, 9.0, {"door_dir": Vector3(-1, 0, 0.2), "glow": "turquoise", "doors": 2})
	hangar = hg["inside"]
	kit.saucer76(Transform3D(Basis(Vector3.UP, 0.4), hangar + Vector3(2.0, 0, -2.0)), 4.5)
	kit.quadz(Transform3D(Basis(Vector3.UP, -PI * 0.5 + 0.2), (hg["door"] as Vector3) + Vector3(0.4, 9.6, 0)), 5.0, 2.5, "enseigne76_spatioport")
	# l'établi d'Ionie (des outils de lumière)
	var et: Vector3 = hangar + Vector3(-6.0, 0, 5.0)
	kit.box(Transform3D(Basis(), et + Vector3(0, 0.5, 0)), Vector3(3.0, 1.0, 1.0), "metal76_", 1.0)
	kit.ball(Transform3D(Basis(), et + Vector3(0.8, 1.15, 0)), 0.14, "lumiere76_turquoise", 8, 4)
	kit.col_box(Transform3D(Basis(), et + Vector3(0, 0.5, 0)), Vector3(3.0, 1.0, 1.0))
	# les aires : trois disques, deux soucoupes posées
	var pads := [c + Vector2(20.0, 18.0), c + Vector2(-8.0, 24.0), c + Vector2(26.0, -16.0)]
	for i in range(pads.size()):
		kit.pad76(GV(pads[i], 0.02), 8.0)
		if i > 0:
			kit.saucer76(Transform3D(Basis(Vector3.UP, i * 1.3), GV(pads[i], 0.12)), 4.0)
	objets["aire_envol"] = GV(pads[0], 0.2)
	objets["meteorite_3"] = GV(pads[2] + Vector2(-2.0, 10.5), 0.05)
	# la tour de contrôle
	var tw: Vector2 = c + Vector2(-16.0, -10.0)
	kit.cyl(Transform3D(Basis(), GV(tw, 0.0)), 2.2, 1.6, 14.0, "nacre76_", 16)
	kit.cyl(Transform3D(Basis(), GV(tw, 14.0)), 3.6, 3.6, 3.0, "verre76", 16)
	kit.dome76(Transform3D(Basis(), GV(tw, 17.0)), 3.7, 1.6, "metal76_", 16, 5)
	kit.ball(Transform3D(Basis(), GV(tw, 19.0)), 0.4, "lumiere76_rose", 8, 5)
	kit.col_cyl(GV(tw, 0.0), 2.3, 17.0)
	_pt("sp_porte_o", hg["door"])
	_pt("sp_dedans", hangar + Vector3(-3.0, 0, 3.0))
	_pt("sp_est", hangar + Vector3(18.0, 0, 3.0))
	_pt("sp_tour", GV(tw + Vector2(3.0, 3.0)))
	_pt("sp_aire", GV(pads[0] + Vector2(-9.0, 0.0)))
	_chain(["sp_porte_o", "sp_dedans", "sp_est", "sp_aire"])
	_link("sp_porte_o", "sp_tour")
	_link("sp_porte_o", nearest(GV(c + Vector2(-24.0, 0)), "av_"))
	_link("sp_tour", nearest(GV(tw), "an_"))
	_spot("spatioport_hangar", et + Vector3(0, 0, 1.0), Vector3(0, 0, -1), "bricoler", "sp_dedans")
	_spot("spatioport_tour", GV(tw + Vector2(2.6, 2.6)), Vector3(1, 0, 1), "observer", "sp_tour")
	_spot("cache_spatioport", GV(tw + Vector2(-3.4, -3.0)), Vector3(-1, 0, -1), "assis", "sp_tour")
	_spot("spatioport_aire_1", GV(pads[0] + Vector2(-8.5, 1.0)), Vector3(1, 0, 0), "debout", "sp_aire")
	_spot("spatioport_aire_2", GV(pads[1] + Vector2(0, -9.0)), Vector3(0, 0, 1), "debout", "sp_dedans")
	objets["spatioport"] = et + Vector3(0, 0, 2.0)
	_zone("as_spatioport", c, 32.0)


# =================================================================== les Jardins suspendus

func _jardins() -> void:
	var c: Vector2 = JARDINS
	var pond: Vector3 = GV(c, 0.0)
	kit.disc(Transform3D(Basis(), pond + Vector3(0, -0.15, 0)), 9.0, "eau76", 36)
	kit.ring(Transform3D(Basis(), pond + Vector3(0, -0.4, 0)), 9.0, 9.6, 0.45, "nacre76_", 36)
	# des fleurs géantes et des arbres de cristal, tout autour
	for k in range(26):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(11.0, 28.0)
		var l: Vector2 = c + Vector2(cos(a), sin(a)) * d
		if l.distance_to(Vector2.ZERO) > 175.0:
			continue
		var h: float = _rng.randf_range(2.5, 7.5)
		var col: String = ["rose", "bleu", "violet", "or", "turquoise"][_rng.randi() % 5]
		if k % 4 == 0:
			kit.place("arbrecristal76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * h), GV(l, 0.0)))
		else:
			kit.place("fleur76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.1, 0.1)).scaled(Vector3.ONE * h), GV(l, 0.0)))
		kit.col_cyl(GV(l, 0.0), 0.12 * h * 0.5 + 0.1, h * 0.6)
	for k2 in range(40):
		var a2: float = _rng.randf() * TAU
		var l2: Vector2 = c + Vector2(cos(a2), sin(a2)) * _rng.randf_range(10.0, 30.0)
		kit.place("buisson76|" + ["rose", "bleu", "or"][k2 % 3], Transform3D(Basis(Vector3.UP, a2).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.6)), GV(l2, 0.0)))
	_pt("ja_nord", GV(c + Vector2(0, -13.0)))
	_pt("ja_est", GV(c + Vector2(13.0, 0)))
	_pt("ja_sud", GV(c + Vector2(0, 13.0)))
	_pt("ja_ouest", GV(c + Vector2(-13.0, 0)))
	_chain(["ja_nord", "ja_est", "ja_sud", "ja_ouest", "ja_nord"])
	_link("ja_est", nearest(GV(c + Vector2(20.0, -10.0)), "av_"))
	_link("ja_nord", nearest(GV(c + Vector2(0, -30.0)), "an_"))
	_spot("jardins_1", GV(c + Vector2(12.0, -6.0)), Vector3(1, 0, 0), "jardiner", "ja_est")
	_spot("jardins_2", GV(c + Vector2(-11.0, 8.0)), Vector3(-1, 0, 0.4), "jardiner", "ja_ouest")
	_spot("jardins_bassin", GV(c + Vector2(0, 11.0)), Vector3(0, 0, -1), "mediter", "ja_sud")
	_spot("cache_jardin", GV(c + Vector2(-21.0, 6.0)), Vector3(1, 0, 0), "assis", "ja_ouest")   # cache-cache (as_cache_cache)
	objets["jardins"] = GV(c + Vector2(10.0, -10.0))
	objets["meteorite_2"] = GV(c + Vector2(-15.0, -12.0), 0.05)
	for k3 in range(5):
		objets["graine_%d" % (k3 + 1)] = GV(c + Vector2(cos(k3 * 1.25) * 17.0, sin(k3 * 1.25) * 17.0))
	_avoid(c, 30.0)
	_zone("as_jardins", c, 30.0)


# =================================================================== le Jardin des Apesanteurs (sur son îlot)

func _apesanteur() -> void:
	var top: Vector3 = ile.islet_tops["apesanteur"]
	var lt: Vector2 = R.L(top.x, top.z)
	var to_c: Vector2 = (-lt).normalized()
	var th: float = atan2(lt.y, lt.x)
	var edge: Vector2 = Vector2(cos(th), sin(th)) * (ile.coast_radius(th) - 5.0)
	var a: Vector3 = GV(edge, 0.1)
	var b: Vector3 = Vector3(top.x, top.y + 0.1, top.z) + Vector3(to_c.x, 0, to_c.y) * 21.0
	kit.bridge76(a, b, 3.0, "violet")
	bridges.append([a, b])
	# le sol de l'îlot : des dalles de cristal, des fleurs, et l'arche d'entrée
	kit.disc(Transform3D(Basis(), top + Vector3(0, 0.03, 0)), 9.0, "cristalsol76", 32)
	kit.glow_ring76(Transform3D(Basis(), top + Vector3(0, 0.05, 0)), 9.0, 0.2, "violet", 32)
	kit.arch76(Transform3D(Basis.looking_at(-Vector3(to_c.x, 0, to_c.y), Vector3.UP), b + Vector3(-to_c.x, 0, -to_c.y) * 1.5), 4.0, 4.5, "violet")
	# les anneaux lumineux du parcours (on saute de l'un à l'autre en apesanteur)
	for k in range(7):
		var ang: float = TAU * k / 7.0
		var p: Vector3 = top + Vector3(cos(ang) * 11.0, 3.0 + k * 1.6, sin(ang) * 11.0)
		var mi := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0
		tm.outer_radius = 1.2
		mi.mesh = tm
		mi.material_override = Mats.make("lumiere76_" + ["violet", "rose", "turquoise", "or"][k % 4])
		add_child(mi)
		mi.global_position = p
		mi.rotation = Vector3(PI * 0.5, ang, 0)
		hoops.append(mi)
	for k2 in range(10):
		var a2: float = _rng.randf() * TAU
		var l2: Vector2 = Vector2(cos(a2), sin(a2)) * _rng.randf_range(12.0, 19.0)
		kit.place("fleur76|" + ["violet", "rose"][k2 % 2], Transform3D(Basis(Vector3.UP, a2).scaled(Vector3.ONE * _rng.randf_range(2.0, 4.0)), top + Vector3(l2.x, -0.1, l2.y)))
	_pt("ap_pont_haut", a)
	_pt("ap_pont_bas", b)
	_pt("ap_centre", top + Vector3(0, 0.05, 0))
	_chain([nearest(a, "av_"), "ap_pont_haut", "ap_pont_bas", "ap_centre"])
	_spot("apesanteur_1", top + Vector3(3.0, 0.05, 2.0), Vector3(-1, 0, 0), "jouer", "ap_centre")
	_spot("apesanteur_2", top + Vector3(-3.0, 0.05, -2.0), Vector3(1, 0, 0), "leviter", "ap_centre")
	objets["apesanteur"] = top + Vector3(0, 0.1, 0)
	# les graines lumineuses flottent en l'air : on les attrape en sautant (on saute très haut ici)
	for k4 in range(3):
		var ga: float = 0.6 + k4 * TAU / 3.0
		objets["graine_lumineuse_%d" % (k4 + 1)] = top + Vector3(cos(ga) * 6.0, 2.6 + k4 * 0.5, sin(ga) * 6.0)
	objets["coeur_fleche_3"] = top + Vector3(0, 3.8, 0)
	_zone("as_apesanteur", lt, 26.0)


# =================================================================== la Serre des Espèces

func _serre() -> void:
	var c: Vector2 = SERRE
	var sr: Dictionary = kit.pavilion76(Transform3D(Basis(), GV(c, 0.0)), 14.0, 4.0, {"door_dir": Vector3(-0.3, 0, 1), "glow": "vert", "roof": "none"})
	kit.dome76(Transform3D(Basis(), GV(c, 4.0)), 14.3, 10.0, "verre76", 36, 8)
	kit.quadz(Transform3D(Basis(Vector3.UP, -0.29), (sr["door"] as Vector3) + Vector3(0.3, 4.6, -1.2)), 4.0, 2.0, "enseigne76_serre")
	var si: Vector3 = sr["inside"]
	for k in range(14):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(3.0, 11.0)
		var h: float = _rng.randf_range(2.0, 5.5)
		kit.place("fleur76|" + ["vert", "turquoise", "bleu"][k % 3], Transform3D(Basis(Vector3.UP, a).scaled(Vector3.ONE * h), si + Vector3(cos(a) * d, 0, sin(a) * d)))
	creatures_at.append([si + Vector3(0, 4.0, 0), 9.0])
	_pt("se_porte", sr["door"])
	_pt("se_dedans", si + Vector3(0, 0, 3.0))
	_chain(["se_porte", "se_dedans"])
	_link("se_porte", nearest(sr["door"], "av_"))
	_spot("serre_1", si + Vector3(4.0, 0, 0), Vector3(-1, 0, 0), "observer", "se_dedans")
	_spot("serre_2", si + Vector3(-4.0, 0, 3.0), Vector3(1, 0, 0), "jardiner", "se_dedans")
	_spot("cache_serre", si + Vector3(7.5, 0, -4.0), Vector3(-1, 0, 0.3), "assis", "se_dedans")
	objets["serre"] = si + Vector3(0, 0, 5.0)
	objets["coeur_fleche_2"] = si + Vector3(-6.0, 0.05, -4.0)
	_zone("as_serre", c, 14.0)


# =================================================================== le Portail d'accueil, le belvédère du Rayon

func _portail() -> void:
	var c: Vector2 = PORTAIL
	var d := Vector2(1, 1).normalized()
	var xf: Transform3D = XF(c.x, c.y, d.x, d.y)
	kit.arch76(xf, 7.0, 8.0, "or")
	portail_point = GV(c - d * 3.0)
	# le pont jusqu'au belvédère, au-delà du bord
	var rp: Vector2 = R.RAYON
	var plat_y: float = 0.1
	rayon_top = R.W(rp.x, rp.y, plat_y)
	var a: Vector3 = GV(c + d * 4.0, 0.1)
	var b: Vector3 = rayon_top - Vector3(d.x, 0, d.y) * 6.5
	kit.bridge76(a, b, 3.0, "or")
	bridges.append([a, b])
	kit.cyl(Transform3D(Basis(), rayon_top - Vector3(0, 0.5, 0)), 7.0, 7.0, 0.5, "nacre76_", 32)
	kit.cyl(Transform3D(Basis(), rayon_top - Vector3(0, 3.5, 0)), 2.0, 7.0, 3.0, "metal76_", 32, false)
	kit.glow_ring76(Transform3D(Basis(), rayon_top + Vector3(0, 0.02, 0)), 3.0, 0.3, "or", 32)
	kit.glow_ring76(Transform3D(Basis(), rayon_top + Vector3(0, 0.02, 0)), 6.6, 0.15, "or", 32)
	kit.col_cyl(rayon_top - Vector3(0, 0.5, 0), 7.0, 0.5)
	for k in range(10):
		var ang: float = TAU * k / 10.0
		if absf(wrapf(ang - atan2(-d.y, -d.x), -PI, PI)) < 0.4:
			continue
		kit.box(Transform3D(Basis(Vector3.UP, -ang), rayon_top + Vector3(cos(ang) * 6.8, 0.55, sin(ang) * 6.8)), Vector3(0.08, 1.1, 4.3), "metal76_or", 1.0)
		kit.col_box(Transform3D(Basis(Vector3.UP, -ang), rayon_top + Vector3(cos(ang) * 6.8, 0.6, sin(ang) * 6.8)), Vector3(0.15, 1.2, 4.3))
	_pt("po_arche", portail_point)
	_pt("po_pont", a)
	_pt("po_belvedere", rayon_top + Vector3(-d.x * 3.5, 0.05, -d.y * 3.5))
	_chain([nearest(portail_point, "av_"), "po_arche", "po_pont", "po_belvedere"])
	_spot("portail_accueil", portail_point + Vector3(-d.y * 3.0, 0, d.x * 3.0), Vector3(d.x, 0, d.y) * -1.0, "bras_croises", "po_arche")
	_spot("portail_belvedere", rayon_top + Vector3(-d.x * 4.5 + d.y * 3.0, 0.05, -d.y * 4.5 - d.x * 3.0), Vector3(d.x, 0, d.y), "observer", "po_belvedere")
	objets["portail"] = portail_point
	objets["rayon_haut"] = rayon_top + Vector3(0, 0.1, 0)
	_zone("as_portail", c + d * 14.0, 24.0)


# =================================================================== les maisons-bulles

## Les maisons des Lumens : des bulles dans deux quartiers (au nord-ouest, au nord-est), et
## quelques-unes de plus ailleurs ; une par habitant (la porte « porte_<id> »), d'autres pour le
## décor.
func _bulles() -> void:
	var places: Array = []
	for ring_r in [74.0, 92.0, 132.0, 148.0]:
		var n: int = int(TAU * ring_r / 15.0)
		for k in range(n):
			var a: float = TAU * (k + 0.5 * (int(ring_r) % 2)) / n + _rng.randf_range(-0.04, 0.04)
			# loin des avenues
			var off: float = absf(wrapf(a * 8.0 / TAU, -0.5, 0.5)) * ring_r * TAU / 8.0
			if off < 9.0:
				continue
			var l: Vector2 = Vector2(cos(a), sin(a)) * (ring_r + _rng.randf_range(-2.0, 2.0))
			if l.length() > ile.coast_radius(a) - 14.0:
				continue
			if not _free(l, 6.0):
				continue
			places.append(l)
	# les quartiers du nord d'abord (les maisons des habitants), puis les autres
	places.sort_custom(func(p, q): return p.y < q.y)
	var homes: Array = places.slice(0, HABITANTS.size())
	var rest: Array = places.slice(HABITANTS.size())
	for i in range(rest.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp: Vector2 = rest[i]
		rest[i] = rest[j]
		rest[j] = tmp
	places = homes + rest.slice(0, 44 if pc else 24)
	var hi: int = 0
	for l in places:
		var r: float = _rng.randf_range(3.6, 5.0)
		var to_road: Vector2 = -l.normalized()
		var color: String = ["bleu", "violet", "rose", "turquoise", "or"][_rng.randi() % 5]
		var door: Vector3 = kit.bubble76(XF(l.x, l.y, to_road.x, to_road.y), r, color)
		_avoid(l, r + 2.0)
		var owner: String = ""
		if hi < HABITANTS.size():
			owner = str(HABITANTS[hi])
			hi += 1
			doors["porte_" + owner] = _pt("porte_" + owner, door)
			_link("porte_" + owner, nearest(door, "an_") if l.length() > 100.0 else nearest(door, "av_"))
			if not graph.has("porte_" + owner) or (graph["porte_" + owner] as Array).is_empty():
				_link("porte_" + owner, nearest(door, "in_"))
		houses.append({"door": door, "x": l.x, "z": l.y, "owner": owner})
	# les lieux des quartiers
	var no := Vector2(-80.0, -64.0)
	var ne := Vector2(80.0, -64.0)
	_spot("bulles_no_1", GV(no), Vector3(1, 0, 0), "debout", nearest(GV(no), "av_"))
	_spot("bulles_no_2", GV(no + Vector2(-6.0, 6.0)), Vector3(0, 0, 1), "leviter", nearest(GV(no), "av_"))
	_spot("bulles_ne_1", GV(ne), Vector3(-1, 0, 0), "debout", nearest(GV(ne), "av_"))
	_spot("bulles_ne_2", GV(ne + Vector2(6.0, 6.0)), Vector3(0, 0, 1), "mediter", nearest(GV(ne), "av_"))
	_zone("as_bulles_no", no, 40.0)
	_zone("as_bulles_ne", ne, 40.0)


# =================================================================== les bords sauvages

## Entre la cité et le bord : de l'herbe argentée, des buissons lumineux, des fleurs géantes, des
## arbres de cristal, des cristaux qui sortent du sol.
func _wild() -> void:
	var n: int = 0
	var tries: int = 0
	while n < (260 if pc else 140) and tries < 2000:
		tries += 1
		var a: float = _rng.randf() * TAU
		var rr: float = ile.coast_radius(a)
		var r: float = _rng.randf_range(146.0, rr - 6.0)
		var l := Vector2(cos(a), sin(a)) * r
		if not _free(l, 3.0):
			continue
		var off: float = absf(wrapf(a * 8.0 / TAU, -0.5, 0.5)) * r * TAU / 8.0
		if off < 4.5:
			continue
		var roll: float = _rng.randf()
		var col: String = ["bleu", "violet", "rose", "turquoise", "or"][_rng.randi() % 5]
		var p: Vector3 = GV(l, -0.05)
		if roll < 0.55:
			kit.place("buisson76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 2.0)), p))
		elif roll < 0.75:
			var h: float = _rng.randf_range(2.0, 5.0)
			kit.place("fleur76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * h), p))
		elif roll < 0.9:
			var h2: float = _rng.randf_range(3.0, 7.0)
			kit.place("arbrecristal76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * h2), p))
			kit.col_cyl(p, 0.3, h2 * 0.6)
		else:
			var h3: float = _rng.randf_range(1.0, 3.5)
			kit.place("cristal76|" + col, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * h3), p - Vector3(0, 0.2, 0)))
			kit.col_cyl(p, 0.2 * h3, h3)
		n += 1


# =================================================================== l'éclairage

func _lamps() -> void:
	var n: int = 0
	for s in range(8):
		var a: float = TAU * s / 8.0
		var d := Vector2(cos(a), sin(a))
		var side := Vector2(-d.y, d.x)
		var r: float = 56.0
		while r < 150.0:
			for sg in [-1.0, 1.0]:
				var l: Vector2 = d * r + side * 4.2 * sg
				if _free(l, 1.0):
					kit.lamp76(GV(l, 0.0), ["blanc", "bleu", "violet", "turquoise"][s % 4], n % 3 == 0)
					n += 1
			r += 16.0
	for k in range(16):
		var a2: float = TAU * (k + 0.5) / 16.0
		var l2 := Vector2(cos(a2), sin(a2)) * 45.0
		kit.lamp76(GV(l2, 0.0), "or", k % 4 == 0)


## Les planètes de la fontaine holographique : des boules lumineuses qui tournent (le gestionnaire
## les anime).
func _planets() -> void:
	var cols := ["lumiere76_ambre", "lumiere76_bleu", "lumiere76_rose", "lumiere76_vert", "lumiere76_violet"]
	for k in range(5):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.25 + 0.12 * (k % 3)
		sm.height = sm.radius * 2.0
		sm.radial_segments = 16
		sm.rings = 8
		mi.mesh = sm
		mi.material_override = Mats.make(cols[k])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.global_position = fountain_top
		holo_planets.append(mi)


# =================================================================== les repères des autres

## Sur une construction (les ponts, le belvédère, les marches des pavillons) ?
func on_structure(p: Vector3) -> bool:
	for br in bridges:
		var a: Vector3 = br[0]
		var b: Vector3 = br[1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t: float = clampf((Vector2(p.x - a.x, p.z - a.z)).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		var q: Vector3 = a.lerp(b, t)
		if Vector2(p.x - q.x, p.z - q.z).length() < 2.2 and absf(p.y - q.y) < 3.0:
			return true
	return Vector2(p.x - rayon_top.x, p.z - rayon_top.z).length() < 7.5 and absf(p.y - rayon_top.y) < 3.0


func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	for z in _zones:
		if l.distance_to(z[1]) < float(z[2]):
			return str(z[0])
	if on_structure(p):
		return "as_pont"
	if l.length() < 150.0:
		return "as_ville"
	return ""

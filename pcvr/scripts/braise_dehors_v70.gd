extends Node3D
## V70 : l'Île de Braise hors de la cité :
##  - les Ruines de l'Ancien Pandémonium, sur le promontoire du nord-ouest : la nef effondrée
##    d'une vieille cathédrale, des arcs qui tiennent encore debout, une tour écroulée, des
##    colonnes brisées, des blocs tombés (les gargouilles y ont leur repaire) ;
##  - les sources de soufre, au pied du volcan : trois vasques d'eau jaune et chaude, leurs
##    margelles, un banc, un petit abri ; les cristaux de soufre (la quête de Zigomar) ;
##  - le belvédère sur le chemin du volcan : une terrasse ronde, une longue-vue ;
##  - le Bois de Cendre : la cachette de Pépin (la quête de Zébuline) ;
##  - les fleurs de braise des pentes du Grand Brasier (la quête de Mère Brasille) ;
##  - des panneaux de danger au bord des coulées et du champ de lave.
## Les lieux des quêtes vont dans « objets » (journal_v56.lieux : les objets à ramasser y
## apparaissent quand la quête le demande).

const R = preload("res://scripts/ile_braise_v70.gd")
const Kit = preload("res://scripts/braise_kit_v70.gd")

var main: Node
var braise: Node                         # braise_v70
var ile: Node3D
var kit
var objets: Dictionary = {}
var fire_spots: Array = []
var flora_avoid: Array = []
var pepin_hide := Vector3.ZERO           # la cachette de Pépin, dans le Bois de Cendre
var _rng := RandomNumberGenerator.new()


func T(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func build(manager: Node) -> void:
	braise = manager
	main = manager.main
	ile = manager.ile
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 7075
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = manager.pc
	kit.rng.seed = 7076
	_ruines()
	_sources()
	_belvedere()
	_bois()
	_fleurs()
	_panneaux()
	kit.commit()
	for f in kit.fires70:
		fire_spots.append(f)
	print("ILE_MANGA_V70: le dehors de l'Île de Braise (ruines, sources, belvédère) en %d ms" % (Time.get_ticks_msec() - t0))


# =================================================================== les Ruines

func _ruines() -> void:
	var c: Vector3 = ile.pads_world["ruines"]
	var y: float = c.y
	# la vieille nef : deux rangs de murs troués, des contreforts, des arcs sans toit
	var nx := Transform3D(Basis(Vector3.UP, 0.55), c + Vector3(-4.0, 0, 2.0))
	for s in [-1.0, 1.0]:
		for k in range(6):
			var z: float = -12.0 + k * 5.0
			var h: float = [9.0, 6.5, 11.0, 3.5, 8.0, 5.0][(k + (2 if s > 0 else 0)) % 6]
			if (k + int(s)) % 4 == 3:
				continue
			kit.solid(nx * T(s * 7.0, h * 0.5, z), Vector3(1.0, h, 4.2), "pgoth70_sombre", 2.4)
			kit.buttress(nx * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 7.5, 0, z + 2.5)), minf(h, 8.0), 1.4, 0.9, "pgoth70_sombre", false)
			if h > 6.0:
				kit.ogive_face(nx * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 7.52, 2.2, z)), 1.4, 3.4, "fenetrenoire70", 4)
		# les colonnes de la nef, la plupart brisées
		for k2 in range(5):
			var ch: float = [7.5, 2.0, 4.5, 1.2, 6.0][(k2 + (1 if s > 0 else 3)) % 5]
			kit.column(nx * T(s * 3.4, 0, -10.0 + k2 * 5.0), 0.45, ch, "pgoth70_sombre", "pgoth70")
	# la façade : un grand arc debout, seul
	kit.ogive_frame(nx * T(0, 0, 14.0), 6.0, 10.0, 1.1, 1.4, "pgoth70_sombre", 6, true)
	for s2 in [-1.0, 1.0]:
		kit.solid(nx * T(s2 * 5.0, 5.5, 14.0), Vector3(3.0, 11.0, 1.4), "pgoth70_sombre", 2.4)
	# la tour écroulée
	kit.tower70(c + Vector3(16.0, 0, -12.0), 4.2, 11.0, {"roof": "none", "crown": false, "windows": [4.0], "nwin": 3, "lit": 0.0, "wall": "pgoth70_sombre"})
	# des blocs tombés, des statues de gargouilles sur des piliers
	var pts: Array = []
	for k3 in range(26):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(4.0, 30.0)
		var p: Vector3 = c + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = ile.height(p.x, p.z)
		pts.append(p)
	var Rk = preload("res://scripts/rocks_v26.gd")
	var rm: Material = kit.mat("pgoth70_sombre")
	for k5 in range(pts.size()):
		var sz: float = _rng.randf_range(0.5, 1.5)
		var mi := MeshInstance3D.new()
		mi.mesh = Rk.shape(7077 * 7 + k5, Vector3(sz * _rng.randf_range(1.0, 1.6), sz * _rng.randf_range(0.6, 1.0), sz), 0.55, 0.12)
		mi.material_override = rm
		add_child(mi)
		mi.position = (pts[k5] as Vector3) + Vector3.UP * sz * 0.2
		mi.rotation.y = _rng.randf() * TAU
		kit.col_box(Transform3D(Basis(), mi.position), Vector3(sz * 1.2, sz * 0.7, sz))
	for k4 in range(4):
		var a2: float = TAU * k4 / 4.0 + 0.4
		var pp: Vector3 = c + Vector3(cos(a2) * 24.0, 0, sin(a2) * 24.0)
		pp.y = ile.height(pp.x, pp.z)
		kit.solid(Transform3D(Basis(), pp + Vector3.UP * 1.4), Vector3(1.2, 2.8, 1.2), "pgoth70_sombre", 1.2)
		kit.gargoyle(Transform3D(Basis.looking_at(-Vector3(cos(a2), 0, sin(a2)), Vector3.UP), pp + Vector3.UP * 2.8), 1.4, "pgoth70_sombre")
	objets["ruines"] = c + Vector3.UP * 1.0
	flora_avoid.append([Vector2(c.x, c.z), 30.0])


# =================================================================== les sources de soufre

func _sources() -> void:
	var i: int = 0
	for sp in R.SPRINGS:
		var w: Vector3 = R.W(sp.x, sp.y, R.SPRING_Y - 0.55)
		kit.ring(Transform3D(Basis(), Vector3(w.x, R.SPRING_Y - 1.2, w.z)), R.SPRING_R - 0.4, R.SPRING_R + 0.3, 1.0, "basalte70", 32)
		kit.disc(Transform3D(Basis(), w), R.SPRING_R - 0.35, "eau70", 32, 2.0)
		# les cristaux de la quête de Zigomar : un sur chaque margelle
		var a: float = [0.6, 2.4, 4.2][i]
		objets["cristal_soufre_%d" % (i + 1)] = Vector3(w.x + cos(a) * (R.SPRING_R + 0.9), R.SPRING_Y + 0.1, w.z + sin(a) * (R.SPRING_R + 0.9))
		i += 1
	# un banc, un petit abri de bois brûlé pour les baigneurs
	var pc: Vector3 = ile.pads_world["sources"]
	var sx := Transform3D(Basis(), pc + Vector3(0.0, 0.0, -14.0))
	for sxx in [-2.0, 2.0]:
		for szz in [-1.5, 1.5]:
			kit.cyl(sx * T(sxx, 0, szz), 0.1, 0.09, 2.6, "boisb70", 6)
	kit.box(sx * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 2.7, 0)), Vector3(5.0, 0.1, 3.8), "tuile70", 1.6)
	kit.bench70(sx * T(0, 0, 0.4))
	objets["sources"] = pc + Vector3.UP * 0.5


# =================================================================== le belvédère

func _belvedere() -> void:
	var c: Vector3 = ile.pads_world["belvedere"]
	kit.cyl(Transform3D(Basis(Vector3.UP, PI / 8.0), c + Vector3.DOWN * 0.6), 5.6, 5.4, 0.8, "pgoth70", 8)
	kit.col_cyl(c + Vector3.DOWN * 0.6, 5.5, 0.8)
	for k in range(8):
		var a0: float = TAU * k / 8.0
		var a1: float = TAU * (k + 1) / 8.0
		var p0: Vector3 = c + Vector3(cos(a0) * 5.2, 0.2, sin(a0) * 5.2)
		var p1: Vector3 = c + Vector3(cos(a1) * 5.2, 0.2, sin(a1) * 5.2)
		var toward: Vector3 = (R.W(R.VOLCANO.x, R.VOLCANO.y) - c)
		var mid_a: float = (a0 + a1) * 0.5
		if Vector3(cos(mid_a), 0, sin(mid_a)).dot(Vector3(toward.x, 0, toward.z).normalized()) < -0.7:
			continue
		kit.railing70(p0, p1, 1.0)
	var to_v: Vector3 = (R.W(R.VOLCANO.x, R.VOLCANO.y) - c)
	to_v.y = 0.0
	kit.telescope(Transform3D(Basis.looking_at(-to_v.normalized(), Vector3.UP), c + to_v.normalized() * 3.2 + Vector3.UP * 0.2), 0.5)
	kit.bench70(Transform3D(Basis.looking_at(-to_v.normalized(), Vector3.UP), c - to_v.normalized() * 1.5 + Vector3.UP * 0.2))
	objets["belvedere"] = c + Vector3.UP * 0.5


# =================================================================== le Bois de Cendre

func _bois() -> void:
	pepin_hide = G(146.0, 226.0)
	# un tronc couché, la lanterne de Pépin posée dans la cendre
	var t := Transform3D(Basis(Vector3.UP, 0.7), pepin_hide + Vector3(1.6, 0.25, -0.6))
	kit.cyl(Transform3D(t.basis * Basis(Vector3.BACK, PI * 0.5), t.origin + t.basis * Vector3(-2.0, 0, 0)), 0.32, 0.26, 4.0, "boisb70", 8)
	kit.col_box(t * T(0, 0.1, 0), Vector3(4.0, 0.6, 0.6))
	kit.place("lanterne", Transform3D(Basis.from_scale(Vector3.ONE * 0.6), pepin_hide + Vector3(-0.6, 0.0, 0.4)))
	objets["bois_pepin"] = pepin_hide
	flora_avoid.append([Vector2(pepin_hide.x, pepin_hide.z), 4.0])
	# deux ruches d'abeilles de feu (des troncs creux sur des piquets) : le miel de la quête de
	# Bobor (les gâteaux de Cerbère)
	var hives := [G(186.0, 202.0), G(158.0, 246.0)]
	for i in range(hives.size()):
		var hp: Vector3 = hives[i]
		for sx in [-0.5, 0.5]:
			kit.cyl(Transform3D(Basis(), hp + Vector3(sx, 0, 0)), 0.07, 0.06, 0.9, "boisb70", 6)
		kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), hp + Vector3(0.7, 1.15, 0)), 0.34, 0.34, 1.4, "boisb70", 10)
		kit.disc(Transform3D(Basis(Vector3.BACK, PI * 0.5), hp + Vector3(-0.71, 1.15, 0)), 0.3, "cuir70", 10)
		kit.col_box(Transform3D(Basis(), hp + Vector3(0, 0.7, 0)), Vector3(1.5, 1.4, 0.7))
		objets["miel_braise_%d" % (i + 1)] = hp + Vector3(0, 0.3, 0.9)
		flora_avoid.append([Vector2(hp.x, hp.z), 2.5])
	# le lieu où Pépin attend (tant qu'on ne l'a pas retrouvé) : relié au chemin du bois
	var c: Node = braise.city
	if c != null:
		var nm: String = c._pt("bois_pepin_n", pepin_hide + Vector3(-1.2, 0.05, 1.6))
		c._link(nm, c._nearest_point(pepin_hide, "bois_pepin"))
		c._spot("bois_pepin", pepin_hide + Vector3(-0.3, 0.55, 0.2), Vector3(0.3, 0, 1), "assis", nm)


# =================================================================== les fleurs de braise

## Cinq fleurs de braise sur les pentes basses du Grand Brasier (là où l'on peut marcher).
func _fleurs() -> void:
	var found: int = 0
	var tries: int = 0
	var angles := [70.0, 20.0, -20.0, 110.0, 160.0]
	while found < 5 and tries < 400:
		tries += 1
		var a: float = deg_to_rad(float(angles[found]) + _rng.randf_range(-14.0, 14.0))
		var d: float = _rng.randf_range(78.0, 104.0)
		var l: Vector2 = R.VOLCANO + Vector2(cos(a), sin(a)) * d
		var w: Vector3 = R.W(l.x, l.y)
		w.y = ile.height(w.x, w.z)
		if w.y < 6.0 or w.y > 52.0 or ile.lava_at(w.x, w.z) > -1e9:
			continue
		var fd: Vector2 = R.flow_dist(l.x, l.y)
		if fd.x < fd.y + 6.0:
			continue
		var e: float = 1.5
		var sxl: float = absf(ile.height(w.x + e, w.z) - ile.height(w.x - e, w.z)) / (2.0 * e)
		var szl: float = absf(ile.height(w.x, w.z + e) - ile.height(w.x, w.z - e)) / (2.0 * e)
		if maxf(sxl, szl) > 0.62:
			continue
		objets["fleur_braise_%d" % (found + 1)] = w + Vector3.UP * 0.3
		flora_avoid.append([Vector2(w.x, w.z), 1.5])
		found += 1


# =================================================================== les panneaux de danger

func _panneaux() -> void:
	var where := [Vector2(-40.0, 190.0), Vector2(-88.0, 176.0), Vector2(-200.0, 200.0), Vector2(-226.0, 150.0)]
	for p in where:
		var w: Vector3 = G((p as Vector2).x, (p as Vector2).y)
		if ile.lava_at(w.x, w.z) > -1e9:
			continue
		kit.cyl(Transform3D(Basis(), w), 0.06, 0.05, 1.8, "boisb70", 6)
		kit.col_cyl(w, 0.08, 1.8)
		var bx := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), w + Vector3.UP * 1.5)
		kit.box(bx, Vector3(0.8, 0.5, 0.05), "boisb70", 1.0)
		kit.quadz(bx * T(0, 0, 0.03), 0.4, 0.4, "sym70_flamme_sym")
		kit.quad(bx * T(0, 0, -0.03), 0.4, 0.4, "sym70_flamme_sym")


# =================================================================== les invites

func register_interactions(d: Node, manager: Node) -> void:
	var me = self
	var it := {"id": "braise_pepin", "pos": pepin_hide + Vector3.UP * 0.5, "radius": 3.0, "text": "E : appeler Pépin", "vr": "Gâchette : appeler Pépin",
		"call": func(): me._found_pepin(), "when": func(): return me._pepin_lost()}
	d._interactions.append(it)


func _pepin_lost() -> bool:
	var j: Node = main.get("journal_v56")
	return j != null and str(j.state("br_pepin")) == "en_cours" and not bool(braise.state.get("pepin", false))


func _found_pepin() -> void:
	braise.state["pepin"] = true
	if main.has_method("sfx"):
		main.sfx("demon_rire", pepin_hide + Vector3.UP)
	main._show_message_v28("« Pépin ! » … Une petite voix répond derrière le tronc : « J'suis là ! J'voulais voir les champignons qui brillent… et après il faisait tout noir. » Pépin rentre en courant chez sa maman, au Grand Marché.")
	braise.release_pepin()


func trouvailles() -> Dictionary:
	return {}


func apply_state() -> void:
	pass

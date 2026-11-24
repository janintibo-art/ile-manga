extends "res://scripts/grande_flore_v59.gd"
## Extension « Le Château d'Ombrelac » : la végétation de l'île (avec les outils de la grande île :
## les épicéas, les pins tordus, la bruyère, l'herbe, les fougères, les roseaux, les rochers).
##  - les Monts Gris : des forêts d'épicéas sombres, serrées sur les pentes, de gros blocs gris ;
##  - la lande : la bruyère mauve et l'herbe rase sur les hauteurs découvertes ;
##  - la rive du lac : des roseaux, des feuillus penchés sur l'eau, des rochers moussus ;
##  - la côte : des pins tordus par le vent du nord.
## Rien sur le plateau du château, sur la route, dans le lit du torrent ni sous le viaduc.

const IleO = preload("res://scripts/ext_chateau/ile_ombrelac.gd")
const FalaisesO = preload("res://scripts/ext_chateau/falaises_ombrelac.gd")


## Un point au hasard sur l'île d'Ombrelac, entre deux hauteurs, pas trop pentu, hors des lieux bâtis
func _point_o(min_h: float, max_h: float, max_slope: float) -> Vector3:
	for _t in range(12):
		var x: float = _rng.randf_range(-IleO.RS, IleO.RS)
		var z: float = _rng.randf_range(-IleO.RS, IleO.RS)
		if not _libre(x, z):
			continue
		var w: Vector3 = IleO.W(x, z)
		var h: float = ile.height(w.x, w.z)
		if h < min_h or h > max_h:
			continue
		var sx: float = ile.height(w.x + 1.5, w.z) - ile.height(w.x - 1.5, w.z)
		var sz: float = ile.height(w.x, w.z + 1.5) - ile.height(w.x, w.z - 1.5)
		if Vector2(sx, sz).length() / 3.0 > max_slope:
			continue
		return Vector3(w.x, h, w.z)
	return Vector3.INF


func _libre(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	if p.distance_to(IleO.ROC) < IleO.ROC_R1 + 4.0:
		return false
	if p.distance_to(IleO.AIGUILLE) < IleO.AIGUILLE_R + 6.0:
		return false
	if IleO.lac_q(x, z) < 1.04:
		return false
	if IleO.route_at(x, z).x < IleO.ROUTE_W + 3.0:
		return false
	if IleO.sentier_at(x, z).x < 3.0:
		return false
	if IleO.gorge_at(x, z).x < IleO.GORGE_W + 4.0:
		return false
	# sous le viaduc et autour de la Colline du Guet (le belvédère)
	if absf(x - IleO.ROC.x) < 14.0 and z > IleO.VIADUC_N.z - 4.0 and z < IleO.VIADUC_S.z + 6.0:
		return false
	if p.distance_to(IleO.GUET) < IleO.GUET_R0 + 6.0:
		return false
	if p.distance_to(IleO.DOCK_A) < 26.0:
		return false
	return true


func plant(island: Node3D, high_quality: bool) -> void:
	ile = island
	_rng.seed = 18810
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	var lists := {"epicea": [[], [], []], "pin": [[], []], "feuillu": [[], []], "bruyere": [[]], "prairie": [[]],
		"fougere": [[]], "roseau": [[]], "fleurs": [[]]}
	var rocks := {"gris": [], "mousse": []}
	# les forêts d'épicéas : là où la carte des sols dit « sous-bois », plus serrées en bas des monts
	for i in range(int(2600 * q)):
		var p: Vector3 = _point_o(3.0, 90.0, 0.85)
		if p == Vector3.INF:
			continue
		var b: Color = ile.biome_at(p.x, p.z)
		if b.b < 0.25 and _rng.randf() > 0.06:
			continue
		lists["epicea"][i % 3].append(_xf(p, _rng.randf_range(0.75, 1.35), 0.2))
		if _rng.randf() < 0.35:
			var f: Vector3 = p + Vector3(_rng.randf_range(-4, 4), 0, _rng.randf_range(-4, 4))
			f.y = ile.height(f.x, f.z)
			lists["fougere"][0].append(_xf(f, _rng.randf_range(0.8, 1.3), 0.05))
	# la lande : la bruyère et l'herbe sur les hauteurs découvertes
	for i in range(int(14000 * q)):  # (v10 : 5200 → 14000, une lande plus fournie)
		var p2: Vector3 = _point_o(2.5, 110.0, 0.7)
		if p2 == Vector3.INF:
			continue
		var b2: Color = ile.biome_at(p2.x, p2.z)
		if b2.b > 0.4:
			continue
		if _rng.randf() < 0.55:
			lists["bruyere"][0].append(_xf(p2, _rng.randf_range(0.8, 1.6), 0.03))
		else:
			lists["prairie"][0].append(_xf(p2, _rng.randf_range(0.8, 1.4), 0.03))
	# des fleurs dans l'herbe, au pied du Guet et près du débarcadère
	for i in range(int(1200 * q)):
		var p3: Vector3 = _point_o(2.0, 50.0, 0.5)
		if p3 != Vector3.INF and IleO.L(p3.x, p3.z).y > 120.0:
			lists["fleurs"][0].append(_xf(p3, _rng.randf_range(0.8, 1.2), 0.02))
	# la rive du lac : les roseaux, quelques feuillus
	for i in range(int(1400 * q)):
		var a: float = _rng.randf() * TAU
		var rq: float = _rng.randf_range(0.99, 1.12)
		var x: float = IleO.LAC.x + cos(a) * IleO.LAC_AX.x * rq
		var z: float = IleO.LAC.y + sin(a) * IleO.LAC_AX.y * rq
		if Vector2(x, z).distance_to(IleO.ROC) < IleO.ROC_R1 + 20.0:
			continue
		var w: Vector3 = IleO.W(x, z)
		var h: float = ile.height(w.x, w.z)
		if h < IleO.LAC_Y - 0.6 or h > IleO.LAC_Y + 2.5:
			continue
		lists["roseau"][0].append(_xf(Vector3(w.x, h, w.z), _rng.randf_range(0.9, 1.4), 0.05))
	for i in range(int(90 * q)):
		var a2: float = _rng.randf() * TAU
		var x2: float = IleO.LAC.x + cos(a2) * IleO.LAC_AX.x * _rng.randf_range(1.12, 1.35)
		var z2: float = IleO.LAC.y + sin(a2) * IleO.LAC_AX.y * _rng.randf_range(1.12, 1.35)
		if not _libre(x2, z2):
			continue
		var w2: Vector3 = IleO.W(x2, z2)
		lists["feuillu"][i % 2].append(_xf(Vector3(w2.x, ile.height(w2.x, w2.z), w2.z), _rng.randf_range(0.8, 1.2), 0.2))
	# la côte : les pins tordus
	for i in range(int(260 * q)):
		var p4: Vector3 = _point_o(1.5, 12.0, 0.6)
		if p4 != Vector3.INF and IleO.L(p4.x, p4.z).length() > IleO.RS * 0.72:
			lists["pin"][i % 2].append(_xf(p4, _rng.randf_range(0.8, 1.2), 0.15))
	# les rochers : des blocs gris sur les monts, des rochers moussus dans les forêts
	for i in range(int(260 * q)):
		var p5: Vector3 = _point_o(4.0, 120.0, 1.6)
		if p5 == Vector3.INF:
			continue
		var tr := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 2.6)), p5 - Vector3.UP * 0.5)
		if ile.biome_at(p5.x, p5.z).b > 0.4:
			rocks["mousse"].append(tr)
		else:
			rocks["gris"].append(tr)
	# les éboulis au pied des falaises du Roc et de l'Aiguille : des blocs anguleux, à demi enfouis
	var fal: Array = []
	for i in range(int(260 * q)):
		var a3: float = _rng.randf() * TAU
		var on_aig: bool = i % 6 == 0
		var c3: Vector2 = IleO.AIGUILLE if on_aig else IleO.ROC
		var rr: float = (IleO.AIGUILLE_R + _rng.randf_range(4.0, 14.0)) if on_aig else _rng.randf_range(IleO.ROC_R1 + 4.0, IleO.ROC_R1 + 48.0)
		var lp: Vector2 = c3 + Vector2(cos(a3), sin(a3)) * rr
		if not on_aig and (lp.y > IleO.ROC.y + 60.0 or IleO.gorge_at(lp.x, lp.y).x < IleO.GORGE_W + 2.0):
			continue
		var w3: Vector3 = IleO.W(lp.x, lp.y)
		var h3: float = ile.height(w3.x, w3.z)
		if h3 < IleO.LAC_Y - 3.0 or h3 > IleO.ROC_Y - 20.0:
			continue
		var sc: float = _rng.randf_range(1.2, 3.6)
		fal.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc * _rng.randf_range(0.6, 1.1), sc)), Vector3(w3.x, h3 - sc * 0.3, w3.z)))
	_eboulis(fal)
	_v13_flore(q)
	for v in range(3):
		_emit("o_epicea_%d" % v, fir_mesh(v), lists["epicea"][v], 900.0)
	for v2 in range(2):
		_emit("o_pin_%d" % v2, pine_mesh(v2 + 4), lists["pin"][v2], 700.0)
		_emit("o_feuillu_%d" % v2, Flora.tree(18820 + v2, 11.0 + v2 * 2.0, 300), lists["feuillu"][v2], 700.0)
	_emit("o_bruyere", heather_mesh(), lists["bruyere"][0], 90.0, false)
	_emit("o_prairie", meadow_mesh(), lists["prairie"][0], 80.0, false)
	_emit("o_fleurs", Flora.flower_clump(), lists["fleurs"][0], 70.0, false)
	_emit("o_fougere", _ground("fougere"), lists["fougere"][0], 90.0, false)
	_emit("o_roseau", Flora.reed_clump(), lists["roseau"][0], 140.0, false)
	_rock_mm("o_roc_gris", Color(0.56, 0.57, 0.6), 0.2, rocks["gris"], 3, Vector3(2.6, 1.8, 2.2), true)
	_rock_mm("o_roc_mousse", Color(0.5, 0.52, 0.48), 0.85, rocks["mousse"], 2, Vector3(2.2, 1.4, 2.0), true)
	_jardin_cloitre(q)
	if _jf != null:
		_jf.free()
		_jf = null
	print("OMBRELAC: la végétation ", placed, " en ", Time.get_ticks_msec() - t0, " ms")


## (v10) Le jardin du cloître : un gazon ras, des fleurs le long des haies de buis, un arbre au milieu
## de chaque carré, un cyprès à chaque coin du jardin. Repère du château : le jardin va de x -14 à 34,
## de z -33 à -13 ; les allées en croix (2,4 m) passent par la fontaine (10, -23).
func _jardin_cloitre(q: float) -> void:
	var o: Vector3 = IleO.W(IleO.ROC.x, IleO.ROC.y, IleO.ROC_Y + 0.12)
	var carres := [[-13.4, 8.4, -32.4, -24.6], [11.6, 33.4, -32.4, -24.6], [-13.4, 8.4, -21.4, -13.6], [11.6, 33.4, -21.4, -13.6]]
	var gazon: Array = []
	var fleurs: Array = [[], [], [], []]
	var arbres: Array = []
	var cypres: Array = []
	for c in carres:
		var x0: float = c[0]
		var x1: float = c[1]
		var z0: float = c[2]
		var z1: float = c[3]
		# le gazon (en dedans des haies)
		for i in range(int((x1 - x0) * (z1 - z0) * 5.0 * q)):
			var p := Vector3(_rng.randf_range(x0 + 0.7, x1 - 0.7), 0.0, _rng.randf_range(z0 + 0.7, z1 - 0.7))
			if Vector2(p.x - 10.0, p.z + 23.0).length() < 5.6:
				continue
			var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.35, 0.55), 1.0) * _rng.randf_range(0.8, 1.2)), o + p - Vector3.UP * 0.02)
			gazon.append(t)
		# les fleurs : une bordure le long des haies
		var per: float = 2.0 * ((x1 - x0) + (z1 - z0))
		for j in range(int(per / 0.55)):
			var u: float = _rng.randf() * per
			var p2: Vector3
			if u < x1 - x0:
				p2 = Vector3(x0 + u, 0.0, z0 + 0.95)
			elif u < 2.0 * (x1 - x0):
				p2 = Vector3(x0 + u - (x1 - x0), 0.0, z1 - 0.95)
			elif u < 2.0 * (x1 - x0) + (z1 - z0):
				p2 = Vector3(x0 + 0.95, 0.0, z0 + u - 2.0 * (x1 - x0))
			else:
				p2 = Vector3(x1 - 0.95, 0.0, z0 + u - 2.0 * (x1 - x0) - (z1 - z0))
			p2 += Vector3(_rng.randf_range(-0.2, 0.2), 0.0, _rng.randf_range(-0.2, 0.2))
			if Vector2(p2.x - 10.0, p2.z + 23.0).length() < 5.6:
				continue
			fleurs[int(u / 3.0) % 4].append(_xf(o + p2, _rng.randf_range(0.7, 1.0), 0.02))
		# l'arbre au milieu du carré
		arbres.append(_xf(o + Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5), _rng.randf_range(0.55, 0.65), 0.05))
	# les cyprès aux quatre coins du jardin
	for cz in [-32.0, -14.4]:
		for cx in [-12.6, 32.6]:
			cypres.append(_xf(o + Vector3(cx, 0.0, cz), _rng.randf_range(0.55, 0.65), 0.05))
	var lawn: ArrayMesh = Flora.grass_clump(16, 0.32, 0.035, 63).duplicate()
	lawn.surface_set_material(0, _plain("gazon_cloitre", Color(0.12, 0.22, 0.06), Color(0.42, 0.58, 0.22), 0.05))
	_emit("o_cloitre_gazon", lawn, gazon, 70.0, false)
	# les fleurs par massifs de couleur : blanches, mauves, jaunes, rouges
	var teintes := [Color(1, 1, 1), Color(0.72, 0.45, 0.9), Color(1.0, 0.82, 0.3), Color(0.9, 0.25, 0.22)]
	for c2 in range(4):
		var fm: ArrayMesh = Flora.flower_clump().duplicate()
		fm.surface_set_material(0, Flora.flower_material(teintes[c2]))
		_emit("o_cloitre_fleurs_%d" % c2, fm, fleurs[c2], 70.0, false)
	_emit("o_cloitre_arbre", Flora.tree(18840, 6.5, 300), arbres, 400.0)
	_emit("o_cloitre_cypres", cypress_mesh(1), cypres, 400.0)


## (v10) Les éboulis : des blocs anguleux, de la même roche que les falaises (avant : des rochers
## ronds et lisses)
func _eboulis(xfs: Array) -> void:
	if xfs.is_empty():
		return
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/ext_chateau/ombrelac_roche.gdshader")
	m.set_shader_parameter("avec_couleur", 0.0)
	m.set_shader_parameter("pied", IleO.LAC_Y)
	var body := StaticBody3D.new()
	body.name = "Rochers_o_eboulis"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var seeds: int = 5
	var per: int = int(ceil(float(xfs.size()) / seeds))
	for v in range(seeds):
		var part: Array = xfs.slice(v * per, mini((v + 1) * per, xfs.size()))
		if part.is_empty():
			continue
		var mesh: ArrayMesh = FalaisesO.bloc_mesh(18850 + v * 13)
		mesh.surface_set_material(0, m)
		var big: Array = []
		for xf in part:
			var t: Transform3D = xf
			big.append(Transform3D(t.basis.scaled(Vector3(1.1, 1.1, 1.1)), t.origin))
		_emit("o_eboulis_%d" % v, mesh, big, 700.0)
		for xf2 in big:
			body.add_child(Rocks.collision_for(mesh, xf2))


## (v13) Une végétation plus riche et plus variée :
##  - des bosquets de feuillus sur les basses pentes, en lisière des forêts d'épicéas ;
##  - des buissons en lisière et le long de la rive ;
##  - l'herbe haute autour du lac, qui ondule au vent ;
##  - des fleurs mauves et jaunes dans l'herbe du Guet (avant : toutes blanches) ;
##  - des nénuphars sur l'eau peu profonde du lac, quelques-uns en fleur.
func _v13_flore(q: float) -> void:
	var bosquets: Array = [[], [], []]
	var buissons: Array = [[], []]
	var herbe: Array = []
	var fleurs: Array = [[], []]
	# les bosquets : quelques centres, les arbres serrés autour
	for i in range(int(46 * q) + 6):
		var c: Vector3 = _point_o(3.5, 34.0, 0.5)
		if c == Vector3.INF:
			continue
		var n: int = _rng.randi_range(4, 11)
		for j in range(n):
			var l2: Vector2 = IleO.L(c.x, c.z) + Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-14, 14))
			if not _libre(l2.x, l2.y):
				continue
			var w: Vector3 = IleO.W(l2.x, l2.y)
			var h: float = ile.height(w.x, w.z)
			if h < 3.2 or h > 40.0:
				continue
			bosquets[(i + j) % 3].append(_xf(Vector3(w.x, h, w.z), _rng.randf_range(0.7, 1.25), 0.2))
			if _rng.randf() < 0.5:
				var b: Vector2 = l2 + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4))
				if _libre(b.x, b.y):
					var wb: Vector3 = IleO.W(b.x, b.y)
					buissons[j % 2].append(_xf(Vector3(wb.x, ile.height(wb.x, wb.z), wb.z), _rng.randf_range(0.9, 1.8), 0.1))
	# les buissons de la rive et des lisières
	for i in range(int(520 * q)):
		var p: Vector3 = _point_o(3.2, 60.0, 0.6)
		if p == Vector3.INF:
			continue
		var l3: Vector2 = IleO.L(p.x, p.z)
		var pres_lac: bool = IleO.lac_q(l3.x, l3.y) < 1.4
		var b2: float = ile.biome_at(p.x, p.z).b
		if pres_lac or (b2 > 0.2 and b2 < 0.55):
			buissons[i % 2].append(_xf(p, _rng.randf_range(0.8, 1.7), 0.1))
	# l'herbe haute autour du lac
	for i in range(int(9000 * q)):
		var a: float = _rng.randf() * TAU
		var rq: float = _rng.randf_range(1.05, 1.75)
		var x: float = IleO.LAC.x + cos(a) * IleO.LAC_AX.x * rq
		var z: float = IleO.LAC.y + sin(a) * IleO.LAC_AX.y * rq
		if not _libre(x, z):
			continue
		var w4: Vector3 = IleO.W(x, z)
		var h4: float = ile.height(w4.x, w4.z)
		if h4 < IleO.LAC_Y or h4 > 30.0:
			continue
		herbe.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.7, 1.4), 1.0) * _rng.randf_range(0.8, 1.3)), Vector3(w4.x, h4 - 0.04, w4.z)))
	# des fleurs de couleur, par taches
	for i in range(int(90 * q)):
		var c5: Vector3 = _point_o(2.5, 60.0, 0.5)
		if c5 == Vector3.INF:
			continue
		var k: int = i % 2
		for j in range(_rng.randi_range(5, 14)):
			var l5: Vector2 = IleO.L(c5.x, c5.z) + Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3))
			if not _libre(l5.x, l5.y):
				continue
			var w5: Vector3 = IleO.W(l5.x, l5.y)
			fleurs[k].append(_xf(Vector3(w5.x, ile.height(w5.x, w5.z), w5.z), _rng.randf_range(0.7, 1.1), 0.02))
	_emit("o_bosquet_0", Flora.tree(18861, 9.0, 280), bosquets[0], 700.0)
	_emit("o_bosquet_1", Flora.tree(18862, 12.0, 320), bosquets[1], 700.0)
	_emit("o_bosquet_2", Flora.tree(18863, 7.5, 240), bosquets[2], 700.0)
	_emit("o_buisson_0", Flora.bush(18871), buissons[0], 160.0)
	_emit("o_buisson_1", Flora.bush(18872), buissons[1], 160.0)
	var hh: ArrayMesh = Flora.grass_clump(14, 0.85, 0.04, 71).duplicate()
	hh.surface_set_material(0, _plain("herbe_haute_o", Color(0.14, 0.2, 0.07), Color(0.55, 0.6, 0.3), 0.35))
	_emit("o_herbe_haute", hh, herbe, 90.0, false)
	var teintes := [Color(0.7, 0.45, 0.88), Color(1.0, 0.84, 0.32)]
	for c6 in range(2):
		var fm: ArrayMesh = Flora.flower_clump().duplicate()
		fm.surface_set_material(0, Flora.flower_material(teintes[c6]))
		_emit("o_fleurs_%d" % c6, fm, fleurs[c6], 70.0, false)
	_nenuphars(q)


## (v13) Les nénuphars : des feuilles rondes fendues, à plat sur l'eau peu profonde du lac, par
## colonies ; une sur sept porte une fleur blanche ou rose.
func _nenuphars(q: float) -> void:
	var feuilles: Array = []
	var fleurs: Array = [[], []]
	for i in range(int(140 * q) + 10):
		var a: float = _rng.randf() * TAU
		var rq: float = _rng.randf_range(0.6, 0.97)
		var cx: float = IleO.LAC.x + cos(a) * IleO.LAC_AX.x * rq
		var cz: float = IleO.LAC.y + sin(a) * IleO.LAC_AX.y * rq
		for j in range(_rng.randi_range(6, 22)):
			var x: float = cx + _rng.randf_range(-5, 5)
			var z: float = cz + _rng.randf_range(-5, 5)
			var w: Vector3 = IleO.W(x, z)
			if not IleO.in_lac_water(w.x, w.z):
				continue
			if Vector2(x, z).distance_to(IleO.ROC) < IleO.ROC_R1 + 6.0:
				continue
			var h: float = ile.height(w.x, w.z)
			if h > IleO.LAC_Y - 0.3 or h < IleO.LAC_Y - 4.5:
				continue
			var y: float = IleO.LAC_Y + 0.02 + _rng.randf() * 0.01
			var s: float = _rng.randf_range(0.6, 1.4)
			feuilles.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, 1.0, s)), Vector3(w.x, y, w.z)))
			if _rng.randf() < 0.14:
				fleurs[j % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.2)), Vector3(w.x + 0.05, y, w.z + 0.05)))
	_emit("o_nenuphar", _feuille_nenuphar(), feuilles, 160.0, false)
	_emit("o_nenuphar_fleur_0", _fleur_nenuphar(Color(0.95, 0.94, 0.88)), fleurs[0], 120.0, false)
	_emit("o_nenuphar_fleur_1", _fleur_nenuphar(Color(0.95, 0.62, 0.72)), fleurs[1], 120.0, false)


func _feuille_nenuphar() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 16
	var fente: float = 0.42
	var r: float = 0.34
	for i in range(n):
		var a0: float = fente * 0.5 + (TAU - fente) * float(i) / n
		var a1: float = fente * 0.5 + (TAU - fente) * float(i + 1) / n
		var p0 := Vector3(cos(a0) * r, 0.012, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0.012, sin(a1) * r)
		# (la feuille se teinte de rouge vers le bord, plus claire au centre)
		for v in [[Vector3(0, 0, 0), Color(0.3, 0.42, 0.14)], [p1, Color(0.16, 0.24, 0.07)], [p0, Color(0.16, 0.24, 0.07)]]:
			st.set_normal(Vector3.UP)
			st.set_color(v[1])
			st.add_vertex(v[0])
		# le bord retroussé, rougeâtre
		var q0: Vector3 = p0 * 1.04 + Vector3(0, 0.025, 0)
		var q1: Vector3 = p1 * 1.04 + Vector3(0, 0.025, 0)
		for v2 in [[p0, Color(0.2, 0.18, 0.07)], [p1, Color(0.2, 0.18, 0.07)], [q1, Color(0.35, 0.14, 0.08)], [p0, Color(0.2, 0.18, 0.07)], [q1, Color(0.35, 0.14, 0.08)], [q0, Color(0.35, 0.14, 0.08)]]:
			st.set_normal((v2[0] as Vector3).normalized() * 0.4 + Vector3.UP)
			st.set_color(v2[1])
			st.add_vertex(v2[0])
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.38
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, m)
	return mesh


func _fleur_nenuphar(c: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# deux couronnes de pétales pointus, ouvertes en coupe, le cœur jaune
	for couronne in range(2):
		var np: int = 8
		var lg: float = 0.16 - couronne * 0.04
		var lev: float = 0.5 + couronne * 0.45
		for i in range(np):
			var a: float = TAU * (float(i) + couronne * 0.5) / np
			var d := Vector3(cos(a), 0, sin(a))
			var t := Vector3(-sin(a), 0, cos(a))
			var base := Vector3(0, 0.03, 0)
			var pointe: Vector3 = base + (d * cos(lev) + Vector3.UP * sin(lev)) * lg
			var mil: Vector3 = base + (d * cos(lev * 0.8) + Vector3.UP * sin(lev * 0.8)) * lg * 0.55
			var nrm: Vector3 = (Vector3.UP * cos(lev) - d * sin(lev)).normalized()
			var cc: Color = c.lerp(Color(1, 1, 1), 0.15 * couronne)
			for v in [base, mil + t * 0.035, pointe, base, pointe, mil - t * 0.035]:
				st.set_normal(nrm)
				st.set_color(cc)
				st.add_vertex(v)
	for i in range(6):
		var a0: float = TAU * float(i) / 6.0
		var a1: float = TAU * float(i + 1) / 6.0
		for v in [Vector3(0, 0.07, 0), Vector3(cos(a1) * 0.03, 0.04, sin(a1) * 0.03), Vector3(cos(a0) * 0.03, 0.04, sin(a0) * 0.03)]:
			st.set_normal(Vector3.UP)
			st.set_color(Color(0.95, 0.75, 0.2))
			st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.backlight_enabled = true
	m.backlight = Color(0.3, 0.28, 0.25)
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, m)
	return mesh

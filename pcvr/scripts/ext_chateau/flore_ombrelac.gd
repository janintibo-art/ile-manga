extends "res://scripts/grande_flore_v59.gd"
## Extension « Le Château d'Ombrelac » : la végétation de l'île (avec les outils de la grande île :
## les épicéas, les pins tordus, la bruyère, l'herbe, les fougères, les roseaux, les rochers).
##  - les Monts Gris : des forêts d'épicéas sombres, serrées sur les pentes, de gros blocs gris ;
##  - la lande : la bruyère mauve et l'herbe rase sur les hauteurs découvertes ;
##  - la rive du lac : des roseaux, des feuillus penchés sur l'eau, des rochers moussus ;
##  - la côte : des pins tordus par le vent du nord.
## Rien sur le plateau du château, sur la route, dans le lit du torrent ni sous le viaduc.

const IleO = preload("res://scripts/ext_chateau/ile_ombrelac.gd")


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
	for i in range(int(5200 * q)):
		var p2: Vector3 = _point_o(6.0, 110.0, 0.7)
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
	for i in range(int(500 * q)):
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
	_rock_mm("o_eboulis", Color(0.64, 0.62, 0.6), 0.3, fal, 4, Vector3(2.6, 1.6, 2.2), true)
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
	if _jf != null:
		_jf.free()
		_jf = null
	print("OMBRELAC: la végétation ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

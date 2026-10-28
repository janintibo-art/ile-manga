extends Node3D
## V67 : Arcanelle, ce qu'on y a bâti (le relief : ile_arcane_v67.gd ; les pièces :
## arcane_kit_v67.gd). Construit l'Académie (la Tour d'Astrelune, la Salle des Cours où l'on
## entre, le dortoir des apprentis, la cour du Grand Cristal, la porte et le muret), la
## Bibliothèque (on y entre), l'Observatoire, le Cercle des Pierres-Lunes, la Crypte aux Runes
## (on y entre, il y fait noir), le Jardin des simples et sa serre, l'Aire des Duels et ses
## cinq braseros, le Lac Miroir et son îlot, la Tour Penchée et sa cloche, le bourg (Le
## Chaudron Fumant où l'on entre, L'Alambic, les maisons, la fontaine du Fondateur), les
## maisons des maîtres, la roulotte d'Agathe dans le Bois Tors, les chemins dallés.
## Il fournit aux habitants leurs lieux (spots), leurs points de passage (points, graph),
## au carnet ses objets de quête (objets), et à l'île ses objets animés (cristal, feux…).

const R = preload("res://scripts/ile_arcane_v67.gd")
const Kit = preload("res://scripts/arcane_kit_v67.gd")

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var objets: Dictionary = {}               # nom -> Vector3 (objets de quête posés dans le monde)
var doors: Dictionary = {}                # maison -> point devant la porte
var interiors: Array = []                 # [nom, centre, demi-taille (Vector2, repère monde), hauteur du plancher]
var flora_avoid: Array = []               # [Vector2, rayon]
var big_crystal: Node3D
var braziers: Array = []                  # {pos, lit, node, light}
var dummies: Array = []                   # {node, pos, burn}
var bell: Node3D
var bell_pos := Vector3.ZERO
var crypt_runes: Array = []               # {node, mat, pos, lit}
var islet_crystal: Node3D
var islet_pos := Vector3.ZERO
var owl_pos := Vector3.ZERO
var owl: Node3D
var smoke_spots: Array = []
var fire_spots: Array = []                # [Vector3, échelle]
var books_high: Dictionary = {}           # nom -> Vector3 (livres envolés, hors de portée)
var circle_center := Vector3.ZERO
var garden_beds: Array = []              # centres des carrés du jardin (les simples y poussent)
var big_trees: Array = []                 # [Vector3, échelle] : les chênes tordus plantés exprès
var lake_water: MeshInstance3D
var statue_orb := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


# =================================================================== repères

func W(x: float, z: float, y: float) -> Vector3:
	return R.W(x, z, y)


func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.W(x, z)
	w.y = ile.height(w.x, w.z) + dy
	return w


func PY(pad: String) -> float:
	return float(R.PADS[pad][3])


func TY(x: float, z: float) -> float:
	return R.town_y(x, z)


## Repère posé en p, la façade (-Z local) tournée vers la direction monde (dx, dz).
func XF(p: Vector3, dx: float, dz: float) -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3(dx, 0.0, dz).normalized(), Vector3.UP), p)


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String = "") -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _link(a: String, b: String) -> void:
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


func _pt(name: String, p: Vector3) -> String:
	points[name] = p
	return name


func _nearest(p: Vector3, prefixes: Array, exclude: String = "") -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		var ks: String = str(k)
		if ks == exclude or ks.begins_with("@") or ks.begins_with("porte"):
			continue
		var ok: bool = prefixes.is_empty()
		for pf in prefixes:
			if ks.begins_with(str(pf)):
				ok = true
		if not ok:
			continue
		var d: float = (points[k] as Vector3).distance_to(p) + absf((points[k] as Vector3).y - p.y) * 3.0
		if d < bd:
			bd = d
			best = ks
	return best


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6767
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6768
	_chemins()
	_academie()
	_bibliotheque()
	_observatoire()
	_cercle()
	_crypte()
	_jardin()
	_aire()
	_lac()
	_tour_penchee()
	_bourg()
	_maisons_maitres()
	_bois_tors()
	_quete_objets()
	kit.commit()
	_animated()
	_graph()
	for l in find_children("*", "OmniLight3D", true, false):
		var ol: OmniLight3D = l
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 55.0
		ol.distance_fade_length = 15.0
		ol.shadow_enabled = false
	print("ILE_MANGA_V67: Arcanelle bâtie, %d lieux, %d points, %d lumières, en %d ms" % [spots.size(), points.size(), kit.lamp_count, Time.get_ticks_msec() - t0])


# =================================================================== les chemins dallés

## Un ruban de dalles qui suit un chemin (points monde, hauteur comprise).
func _ribbon(pts: Array, w: float, key: String) -> void:
	if pts.size() < 2:
		return
	var acc: float = 0.0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = b - a
		var flat := Vector3(d.x, 0, d.z)
		if flat.length() < 0.01:
			continue
		var side: Vector3 = flat.normalized().cross(Vector3.UP) * (w * 0.5)
		var a0: Vector3 = a - side + Vector3.UP * 0.05
		var a1: Vector3 = a + side + Vector3.UP * 0.05
		var b0: Vector3 = b - side + Vector3.UP * 0.05
		var b1: Vector3 = b + side + Vector3.UP * 0.05
		a0.y = maxf(a0.y, ile.height(a0.x, a0.z) + 0.04)
		a1.y = maxf(a1.y, ile.height(a1.x, a1.z) + 0.04)
		b0.y = maxf(b0.y, ile.height(b0.x, b0.z) + 0.04)
		b1.y = maxf(b1.y, ile.height(b1.x, b1.z) + 0.04)
		var l: float = flat.length()
		kit.quad4(key, a0, a1, b1, b0, Vector3.UP, Vector2(0, acc / 2.4), Vector2(w / 2.4, acc / 2.4), Vector2(w / 2.4, (acc + l) / 2.4), Vector2(0, (acc + l) / 2.4))
		acc += l


func _chemins() -> void:
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		var thin: Array = []
		for i in range(0, pts.size(), 2):
			thin.append(pts[i])
		if (pts.size() - 1) % 2 != 0:
			thin.append(pts[-1])
		_ribbon(thin, 2.3, "dallesarc")
		for p in pts:
			flora_avoid.append([Vector2((p as Vector3).x, (p as Vector3).z), 2.6])
		# des réverbères le long des chemins (un tous les 16 m environ)
		var acc: float = 0.0
		for i2 in range(1, pts.size()):
			acc += (pts[i2] as Vector3).distance_to(pts[i2 - 1])
			if acc > 16.0 and i2 < pts.size() - 4:
				acc = 0.0
				var a: Vector3 = pts[i2 - 1]
				var b: Vector3 = pts[i2]
				var side: Vector3 = (b - a).cross(Vector3.UP).normalized() * 1.8 * (1.0 if i2 % 2 == 0 else -1.0)
				var lp: Vector3 = b + side
				lp.y = ile.height(lp.x, lp.z)
				kit.orb_lamp(lp, 3.2, "", pc)
	# le pavage du bourg : la place ronde et les rues
	var sq := Vector2(46.0, 44.0)
	var n: int = 40
	for i3 in range(n):
		var a0: float = TAU * i3 / n
		var a1: float = TAU * (i3 + 1) / n
		var r: float = 9.5
		var c: Vector3 = W(sq.x, sq.y, TY(sq.x, sq.y) + 0.06)
		var p0: Vector3 = W(sq.x + cos(a0) * r, sq.y + sin(a0) * r, 0.0)
		var p1: Vector3 = W(sq.x + cos(a1) * r, sq.y + sin(a1) * r, 0.0)
		p0.y = TY(sq.x + cos(a0) * r, sq.y + sin(a0) * r) + 0.06
		p1.y = TY(sq.x + cos(a1) * r, sq.y + sin(a1) * r) + 0.06
		kit.tri("dallesarc", c, p0, p1, Vector3.UP, Vector2(c.x, c.z) / 2.4, Vector2(p0.x, p0.z) / 2.4, Vector2(p1.x, p1.z) / 2.4)
	for st in [[Vector2(41.5, 39.5), Vector2(36.0, 34.0), Vector2(30.0, 31.0), Vector2(28.0, 30.0)], [Vector2(40.0, 44.0), Vector2(33.0, 44.5), Vector2(30.0, 47.0)],
			[Vector2(50.5, 39.5), Vector2(55.0, 37.0), Vector2(59.0, 32.0), Vector2(60.0, 27.0)], [Vector2(50.5, 48.5), Vector2(55.0, 56.0), Vector2(63.0, 61.0), Vector2(70.0, 62.0)]]:
		var tp: Array = []
		for q in st:
			var v: Vector2 = q
			tp.append(W(v.x, v.y, TY(v.x, v.y) + 0.02))
		_ribbon(tp, 3.2, "dallesarc")
		for q2 in st:
			var v2: Vector2 = q2
			var wv: Vector3 = R.W(v2.x, v2.y)
			flora_avoid.append([Vector2(wv.x, wv.z), 4.0])
	var tw: Vector3 = R.W(47.0, 44.0)
	flora_avoid.append([Vector2(tw.x, tw.z), 32.0])


# =================================================================== l'Académie

func _academie() -> void:
	var y: float = PY("academie")
	var A := Vector2(-10.0, -10.0)
	var aw: Vector3 = R.W(A.x, A.y)
	flora_avoid.append([Vector2(aw.x, aw.z), 19.0])
	# --- la Tour d'Astrelune
	var tc: Vector3 = W(-14.0, -20.0, y)
	var tdir := Vector3(0.45, 0, 0.89).normalized()
	kit.tower(tc, 5.0, 22.0, {"roof_h": 10.5, "windows": [6.0, 11.0, 16.0, 19.5], "nwin": 4, "door_dir": tdir, "roof_key": "ecailles_violet", "over": 0.7})
	doors["tour"] = tc + tdir * 6.2
	# un balcon de pierre et des bannières côté cour
	kit.cyl(Transform3D(Basis(), tc + Vector3.UP * 14.0), 5.9, 5.9, 0.25, "pierrearc_clair", 24, true, 2.0)
	for k in range(24):
		var a: float = TAU * k / 24.0
		kit.cyl(Transform3D(Basis(), tc + Vector3(cos(a) * 5.75, 14.25, sin(a) * 5.75)), 0.06, 0.06, 0.9, "fer", 5, false)
	kit.ring(Transform3D(Basis(), tc + Vector3.UP * 15.1), 5.7, 5.85, 0.06, "fer", 32)
	for s in [-1.0, 1.0]:
		var ba: float = atan2(tdir.z, tdir.x) + s * 0.42
		var bf: Transform3D = kit.round_face(tc, 5.05, ba, 7.0)
		kit.quad(bf * Transform3D(Basis(), Vector3(0, 2.6, -0.06)), 1.3, 5.2, "banniere", Vector2(0, 0), Vector2(1, 1), true)
		kit.box(bf * Transform3D(Basis(), Vector3(0, 5.25, -0.25)), Vector3(1.6, 0.08, 0.08), "laiton", 1.0)
	# --- la Salle des Cours (on y entre)
	var hxf: Transform3D = XF(W(-3.0, -13.0, y), 0.0, 1.0)
	var hd: Dictionary = kit.hall(hxf, 10.0, 7.0, {"h": 6.4, "roof_key": "ecailles_violet", "floor_key": "dallesarc", "lights": 2, "energy": 1.4, "pitch": 46.0})
	doors["salle"] = hd["door"]
	kit.quad(hxf * Transform3D(Basis(), Vector3(0, 4.6, -0.05)), 2.2, 2.2, "rosace")
	kit.ring(hxf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 4.6, -0.04)), 1.08, 1.25, 0.12, "pierrearc_clair", 28)
	_sign(hxf * Transform3D(Basis(), Vector3(0, 3.25, -0.12)), 2.6, 0.65, "academie")
	# à l'intérieur : des bancs, un pupitre, un tableau, des étagères
	for row in range(3):
		kit.bench(hxf * Transform3D(Basis(Vector3.UP, PI), Vector3(-2.0, 0.0, 2.0 + row * 1.4)))
		kit.bench(hxf * Transform3D(Basis(Vector3.UP, PI), Vector3(2.0, 0.0, 2.0 + row * 1.4)))
	kit.box(hxf * Transform3D(Basis(), Vector3(0, 0.6, 5.9)), Vector3(0.8, 1.2, 0.6), "poutre", 1.0)
	kit.box(hxf * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(0, 1.25, 5.85)), Vector3(0.9, 0.05, 0.6), "poutre_clair", 1.0)
	kit.box(hxf * Transform3D(Basis(), Vector3(0, 2.6, 6.5)), Vector3(3.2, 1.6, 0.06), "pierrearc_sombre", 1.0)
	kit.quad(hxf * Transform3D(Basis(), Vector3(0, 2.6, 6.46)), 1.4, 1.4, "runes_pale", Vector2(0.15, 0.15), Vector2(0.85, 0.85))
	kit.bookshelf(hxf * Transform3D(Basis(), Vector3(-3.4, 0.0, 6.15)), 2.2, 2.6)
	kit.bookshelf(hxf * Transform3D(Basis(), Vector3(3.4, 0.0, 6.15)), 2.2, 2.6)
	interiors.append(["salle", (hxf * Vector3(0, 0, 3.5)), Vector2(4.6, 3.3), y])
	_spot("salle_pupitre", hxf * Vector3(0, 0.05, 5.2), hxf * Vector3(0, 0, 1.0), "enseigner")
	# --- le dortoir des apprentis
	var dxf: Transform3D = XF(W(-19.5, -9.0, y), 1.0, 0.0)
	doors["dortoir"] = kit.timber_house(dxf, 7.0, 5.0, {"toit": "violet", "enduit": "", "lucarne": true})
	# --- la cour du Grand Cristal
	var cc: Vector3 = W(-6.0, -4.0, y)
	kit.disc(Transform3D(Basis(), cc + Vector3.UP * 0.04), 8.5, "dallesarc", 40, 3.0)
	kit.ring(Transform3D(Basis(), cc), 1.5, 1.85, 0.7, "pierrearc_clair", 28)
	kit.disc(Transform3D(Basis(), cc + Vector3.UP * 0.55), 1.52, "eaulac", 24)
	kit.col_cyl(cc, 1.85, 0.7)
	kit.quad(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), cc + Vector3.UP * 0.07), 7.0, 7.0, "runes_violet", Vector2(0, 0), Vector2(1, 1))
	big_crystal = Node3D.new()
	big_crystal.name = "Grand_cristal"
	add_child(big_crystal)
	big_crystal.position = cc + Vector3.UP * 3.0
	_crystal_node(big_crystal, 1.0, "cristal")
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.72, 0.55, 1.0)
	gl.light_energy = 1.6
	gl.omni_range = 12.0
	gl.position = Vector3(0, 0.6, 0)
	big_crystal.add_child(gl)
	# le pupitre de l'archimage, les bancs des apprentis
	var lp: Vector3 = W(-9.0, -9.5, y)
	kit.box(XF(lp, 0.5, 1.0) * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.7, 1.1, 0.5), "poutre", 1.0)
	kit.box(XF(lp, 0.5, 1.0) * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, 1.15, 0.05)), Vector3(0.8, 0.05, 0.6), "poutre_clair", 1.0)
	kit.col_box(XF(lp, 0.5, 1.0) * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(0.7, 1.1, 0.5))
	_spot("cour_pupitre", lp + Vector3(-0.3, 0.05, -0.65).rotated(Vector3.UP, 0.0), cc, "enseigner")
	_spot("cour_cristal", cc + Vector3(-2.6, 0.05, -1.2), cc, "observer")
	for i in range(4):
		var ang: float = deg_to_rad(50.0 + i * 28.0)
		var bp: Vector3 = cc + Vector3(cos(ang), 0, sin(ang)) * 5.6
		bp.y = y
		var bxf: Transform3D = XF(bp, cos(ang), sin(ang))
		kit.bench(bxf)
		_spot("cour_banc_%d" % (i + 1), bxf * Vector3(0.35 * (1 if i % 2 == 0 else -1), 0.05, 0.05), cc, "assis")
	# la porte de l'Académie : deux tourelles, un arc, des bannières
	for s2 in [-1.0, 1.0]:
		kit.tower(W(5.0, -6.0 + s2 * 3.3, y), 1.35, 6.2, {"roof_h": 3.2, "windows": [3.4], "nwin": 2, "roof_key": "ecailles_violet", "band": false, "over": 0.35})
	var gxf: Transform3D = XF(W(5.0, -6.0, y), 1.0, 0.0)
	kit.box(gxf * Transform3D(Basis(), Vector3(0, 4.6, 0)), Vector3(4.2, 0.8, 0.8), "pierrearc", 1.5)
	kit.box(gxf * Transform3D(Basis(), Vector3(0, 5.15, 0)), Vector3(4.4, 0.3, 1.0), "pierrearc_clair", 1.5)
	_sign(gxf * Transform3D(Basis(), Vector3(0, 4.6, -0.42)), 2.8, 0.7, "academie")
	kit.orb_lamp(W(7.5, -9.6, y), 3.0, "violet", pc)
	kit.orb_lamp(W(7.5, -2.4, y), 3.0, "violet", pc)
	# le muret autour du plateau, ouvert vers les chemins
	var gaps: Array = [15.0, 147.0, 219.0]
	var wr: float = 16.4
	var step: float = 6.0
	var ang0: float = 0.0
	while ang0 < 360.0:
		var a1: float = ang0 + step
		var blocked: bool = false
		for gpa in gaps:
			var dd: float = absf(fposmod(ang0 + step * 0.5 - float(gpa) + 180.0, 360.0) - 180.0)
			if dd < 11.0:
				blocked = true
		if not blocked:
			var p0: Vector3 = W(A.x + cos(deg_to_rad(ang0)) * wr, A.y + sin(deg_to_rad(ang0)) * wr, y)
			var p1: Vector3 = W(A.x + cos(deg_to_rad(a1)) * wr, A.y + sin(deg_to_rad(a1)) * wr, y)
			kit.low_wall(p0, p1, 0.9, 0.55)
		ang0 = a1
	for k2 in range(4):
		var la: float = deg_to_rad(20.0 + k2 * 60.0)
		kit.orb_lamp(cc + Vector3(cos(la), 0, sin(la)) * 8.0, 3.3, "violet", pc and k2 % 2 == 0)


func _crystal_node(parent: Node3D, s: float, key: String) -> void:
	var m: Material = kit.mat(key)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.55 * s
	cm.height = 1.4 * s
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = Vector3(0, 0.7 * s, 0)
	parent.add_child(mi)
	var mi2 := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.55 * s
	cm2.bottom_radius = 0.0
	cm2.height = 1.0 * s
	cm2.radial_segments = 6
	cm2.rings = 1
	mi2.mesh = cm2
	mi2.material_override = m
	mi2.position = Vector3(0, -0.5 * s, 0)
	parent.add_child(mi2)


# =================================================================== la Bibliothèque

func _bibliotheque() -> void:
	var y: float = PY("bibliotheque")
	var bxf: Transform3D = XF(W(11.0, 12.0, y), 1.0, 0.0)
	var hd: Dictionary = kit.hall(bxf, 11.0, 8.0, {"h": 5.6, "roof_key": "ecailles", "floor_key": "planches", "inner": "poutre_clair", "lights": 3, "energy": 1.2, "pitch": 48.0})
	doors["bibliotheque"] = hd["door"]
	_sign(bxf * Transform3D(Basis(), Vector3(0, 3.35, -0.12)), 2.6, 0.65, "bibliotheque")
	# les rayonnages tout autour, deux tables de lecture, le bureau de Théophraste
	for k in range(4):
		kit.bookshelf(bxf * Transform3D(Basis(), Vector3(-3.9 + k * 2.6, 0.0, 7.15)), 2.4, 3.6)
	for s in [-1.0, 1.0]:
		for k2 in range(2):
			kit.bookshelf(bxf * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 4.65, 0.0, 2.6 + k2 * 3.0)), 2.6, 3.2)
	for k3 in range(2):
		var tp: Vector3 = bxf * Vector3(-2.2 + k3 * 4.4, 0.0, 4.2)
		kit.box(XF(tp, 1.0, 0.0) * Transform3D(Basis(), Vector3(0, 0.76, 0)), Vector3(2.2, 0.08, 1.0), "poutre_clair", 1.0)
		for lx in [-0.9, 0.9]:
			kit.box(XF(tp, 1.0, 0.0) * Transform3D(Basis(), Vector3(lx, 0.38, 0)), Vector3(0.1, 0.76, 0.8), "poutre", 1.0)
		kit.col_box(XF(tp, 1.0, 0.0) * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.2, 0.8, 1.0))
		_spot("bib_table_%d" % (k3 * 2 + 1), tp + (bxf.basis * Vector3(0.0, 0.05, -0.85)), tp, "lire")
		_spot("bib_table_%d" % (k3 * 2 + 2), tp + (bxf.basis * Vector3(0.0, 0.05, 0.85)), tp, "lire")
		kit.box(XF(tp, 1.0, 0.0) * Transform3D(Basis(), Vector3(0.6, 0.86, 0.1)), Vector3(0.36, 0.1, 0.26), "livres", 1.0)
	var dp: Vector3 = bxf * Vector3(0.0, 0.0, 6.2)
	kit.box(XF(dp, 1.0, 0.0) * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.0, 0.9, 1.8), "poutre", 1.0)
	kit.col_box(XF(dp, 1.0, 0.0) * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.0, 0.9, 1.8))
	_spot("bib_bureau", bxf * Vector3(0.0, 0.05, 6.95), dp, "lire")
	interiors.append(["bibliotheque", bxf * Vector3(0, 0, 4.0), Vector2(3.6, 5.0), y])   # (le bâtiment regarde l'est : demi-largeurs en x et z du monde)
	var bi: Vector3 = bxf * Vector3(0, 0, 1.6)
	_pt("bib_in", Vector3(bi.x, y + 0.05, bi.z))
	# un livre envolé est resté coincé sur le faîte du toit
	var ridge: Vector3 = bxf * Vector3(2.4, 0.0, 4.0)
	ridge.y = y + 5.6 + (4.0 + 0.5) * tan(deg_to_rad(48.0)) + 0.35
	books_high["livre_toit"] = ridge
	var lw: Vector3 = R.W(12.0, 12.0)
	flora_avoid.append([Vector2(lw.x, lw.z), 12.0])


# =================================================================== l'Observatoire

func _observatoire() -> void:
	var y: float = PY("observatoire")
	var c: Vector3 = W(-34.0, -47.0, y)
	var dir := Vector3(0.45, 0, 0.89)
	kit.tower(c, 3.4, 8.0, {"roof": "none", "windows": [4.0], "nwin": 3, "door_dir": dir, "band": true})
	doors["observatoire"] = c + dir * 4.6
	# la coupole de cuivre vert, la fente, la lunette
	var rings: int = 8
	for k in range(rings):
		var a0: float = PI * 0.5 * k / rings
		var a1: float = PI * 0.5 * (k + 1) / rings
		kit.cyl(Transform3D(Basis(), c + Vector3.UP * (8.0 + sin(a0) * 3.6)), cos(a0) * 3.6, cos(a1) * 3.6, (sin(a1) - sin(a0)) * 3.6, "cuivrevert", 24, k == rings - 1)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 7.9), 3.3, 3.75, 0.25, "pierrearc_clair", 32)
	var slit: Transform3D = Transform3D(Basis.looking_at(Vector3(-0.6, 0, 0.8).normalized(), Vector3.UP), c + Vector3.UP * 8.0)
	kit.box(slit * Transform3D(Basis(Vector3.RIGHT, -0.75), Vector3(0, 2.2, -2.2)), Vector3(0.9, 3.0, 0.4), "fer", 1.0)
	kit.cyl(slit * Transform3D(Basis(Vector3.RIGHT, -0.95), Vector3(0, 2.3, -1.4)), 0.22, 0.3, 3.4, "laiton", 14)
	kit.col_cyl(c + Vector3.UP * 7.5, 3.6, 3.8)
	# dehors : la lunette de Lumen, la carte du ciel sur son chevalet
	var tp: Vector3 = W(-29.5, -49.5, y)
	kit.telescope(XF(tp, -0.4, -1.0), 0.75)
	_spot("obs_lunette", tp + Vector3(0.6, 0.05, 0.7), tp + Vector3(-0.6, 0, -1.4), "observer")
	var ep: Vector3 = W(-30.0, -43.5, y)
	var exf: Transform3D = XF(ep, 0.6, 0.8)
	for s in [-1.0, 1.0]:
		kit.box(exf * Transform3D(Basis(Vector3.BACK, s * 0.12), Vector3(s * 0.5, 0.85, 0.1)), Vector3(0.06, 1.8, 0.06), "poutre", 1.0)
	kit.quad(exf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 1.25, -0.02)), 1.2, 1.2, "carteciel")
	_spot("obs_carte", exf * Vector3(0, 0.05, -1.1), ep, "debout")
	var ow: Vector3 = R.W(-34.0, -46.0)
	flora_avoid.append([Vector2(ow.x, ow.z), 10.0])


# =================================================================== le Cercle des Pierres-Lunes

func _cercle() -> void:
	var y: float = PY("cercle")
	var c: Vector3 = W(-64.0, -4.0, y)
	circle_center = c
	kit.quad(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), c + Vector3.UP * 0.06), 11.0, 11.0, "runes", Vector2(0, 0), Vector2(1, 1))
	for k in range(9):
		var a: float = TAU * k / 9.0 + 0.2
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 8.0
		p.y = ile.height(p.x, p.z) - 0.1
		var h: float = 3.4 + float((k * 7) % 5) * 0.45
		if k == 4:
			h = 6.2
		kit.menhir(XF(p, -cos(a), -sin(a)), h, 1.1, 0.7)
		if k == 4:
			books_high["livre_menhir"] = p + Vector3.UP * (h + 0.1)
	# l'autel au milieu
	kit.box(Transform3D(Basis(Vector3.UP, 0.3), c + Vector3.UP * 0.45), Vector3(2.4, 0.9, 1.2), "pierrelune", 1.2)
	kit.col_box(Transform3D(Basis(Vector3.UP, 0.3), c + Vector3.UP * 0.45), Vector3(2.4, 0.9, 1.2))
	kit.crystal(Transform3D(Basis(), c + Vector3(0.3, 0.9, 0.1)), 0.35, "cristal_bleu")
	_spot("cercle_autel", c + Vector3(0.0, 0.05, 1.6), c, "observer")
	_spot("cercle_garde", c + Vector3(5.0, 0.05, 3.0), c, "debout")
	_spot("cercle_pierre", c + Vector3(-3.8, 0.05, -4.6), c, "lire")
	var cw: Vector3 = R.W(-64.0, -4.0)
	flora_avoid.append([Vector2(cw.x, cw.z), 12.0])


# =================================================================== la Crypte aux Runes

func _crypte() -> void:
	var y: float = PY("crypte")
	var dir := Vector2(14.0, 8.0).normalized()
	var front: Vector3 = W(-36.0 + dir.x * 2.8, 24.0 + dir.y * 2.8, y)
	var cxf: Transform3D = XF(front, dir.x, dir.y)
	var hd: Dictionary = kit.hall(cxf, 5.2, 6.0, {"h": 3.6, "roof_key": "ecailles", "wall": "pierrearc_mousse", "inner": "pierrearc_sombre", "floor_key": "dallesarc", "lights": 0, "windows": false, "pitch": 50.0, "door_w": 1.5})
	doors["crypte"] = hd["door"]
	kit.box(cxf * Transform3D(Basis(), Vector3(0, 4.9, -0.1)), Vector3(0.3, 1.2, 0.3), "pierrearc", 1.0)
	kit.box(cxf * Transform3D(Basis(), Vector3(0, 5.3, -0.1)), Vector3(0.9, 0.25, 0.3), "pierrearc", 1.0)
	# trois pierres gravées de runes, sur les murs du fond et des côtés : elles luisent sous la lumière
	var plaques := [[Vector3(0.0, 1.6, 5.5), 0.0], [Vector3(-2.15, 1.6, 3.2), -PI * 0.5], [Vector3(2.15, 1.6, 3.2), PI * 0.5]]
	for i in range(3):
		var pl: Array = plaques[i]
		var pxf: Transform3D = cxf * Transform3D(Basis(Vector3.UP, float(pl[1])), pl[0])
		kit.box(pxf * Transform3D(Basis(), Vector3(0, 0, 0.06)), Vector3(1.1, 1.1, 0.12), "pierrelune", 1.0)
		var m := StandardMaterial3D.new()
		m.albedo_texture = load(Kit.AR + "runes.png")
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.4, 0.42, 0.48, 0.5)
		var qm := QuadMesh.new()
		qm.size = Vector2(0.9, 0.9)
		var mi := MeshInstance3D.new()
		mi.name = "Rune_crypte_%d" % i
		mi.mesh = qm
		mi.material_override = m
		add_child(mi)
		mi.global_transform = pxf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -0.005))
		crypt_runes.append({"node": mi, "mat": m, "pos": pxf.origin, "lit": false})
	interiors.append(["crypte", cxf * Vector3(0, 0, 3.0), Vector2(2.2, 2.6), y])
	_spot("crypte_porte", hd["door"] + Vector3(0, 0.05, 0) + Vector3(dir.x, 0, dir.y) * 0.6, hd["door"] + Vector3(dir.x, 0, dir.y) * 4.0, "debout")
	var cw: Vector3 = R.W(-36.0, 24.0)
	flora_avoid.append([Vector2(cw.x, cw.z), 8.0])


# =================================================================== le Jardin des simples

func _jardin() -> void:
	var y: float = PY("jardin")
	var c: Vector3 = W(0.0, 46.0, y)
	# les carrés de simples
	for row in range(3):
		for col in range(2):
			var bp: Vector3 = W(-5.0 + col * 7.0, 42.0 + row * 4.2, y)
			var bxf := Transform3D(Basis(), bp)
			garden_beds.append(bp)
			kit.box(bxf * Transform3D(Basis(), Vector3(0, 0.22, 0)), Vector3(3.4, 0.44, 1.5), "poutre_clair", 1.0, 63 - 4)
			kit.box(bxf * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(3.2, 0.06, 1.3), "terrearc", 1.5)
			kit.col_box(bxf * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(3.4, 0.4, 1.5))
	_spot("jardin_carres", W(-1.5, 44.1, y + 0.05), W(-5.0, 44.1, y), "jardiner")
	# la serre de verre et de fer
	var sxf: Transform3D = XF(W(6.5, 38.0, y), 0.0, 1.0)
	var sw: float = 5.0
	var sd: float = 3.6
	for ix in range(6):
		var px: float = -sw * 0.5 + sw * ix / 5.0
		for zz in [0.0, sd]:
			kit.box(sxf * Transform3D(Basis(), Vector3(px, 1.1, zz)), Vector3(0.06, 2.2, 0.06), "fer", 1.0)
	for zz2 in [0.0, sd]:
		kit.box(sxf * Transform3D(Basis(), Vector3(0, 2.2, zz2)), Vector3(sw, 0.06, 0.06), "fer", 1.0)
	kit.quad(sxf * Transform3D(Basis(), Vector3(0, 1.1, 0.0)), sw, 2.2, "verre", Vector2(0, 0), Vector2(1, 1), true)
	kit.quad(sxf * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.1, sd)), sw, 2.2, "verre", Vector2(0, 0), Vector2(1, 1), true)
	for s in [-1.0, 1.0]:
		kit.quad(sxf * Transform3D(Basis(Vector3.UP, -s * PI * 0.5), Vector3(s * sw * 0.5, 1.1, sd * 0.5)), sd, 2.2, "verre", Vector2(0, 0), Vector2(1, 1), true)
	for ze in [0.0, sd]:
		var a0: Vector3 = sxf * Vector3(-sw * 0.5, 2.2, ze)
		var a1: Vector3 = sxf * Vector3(sw * 0.5, 2.2, ze)
		var b1: Vector3 = sxf * Vector3(sw * 0.5, 3.4, sd * 0.5)
		var b0: Vector3 = sxf * Vector3(-sw * 0.5, 3.4, sd * 0.5)
		var nn: Vector3 = (a1 - a0).cross(b0 - a0).normalized()
		kit.quad4("verre", a0, a1, b1, b0, nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		kit.quad4("verre", a0, a1, b1, b0, -nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		for ix2 in range(6):
			var px2: float = -sw * 0.5 + sw * ix2 / 5.0
			kit.beam(sxf * Vector3(px2, 2.2, ze), sxf * Vector3(px2, 3.4, sd * 0.5), 0.05, "fer")
	kit.box(sxf * Transform3D(Basis(), Vector3(0, 3.4, sd * 0.5)), Vector3(sw, 0.06, 0.08), "fer", 1.0)
	kit.col_box(sxf * Transform3D(Basis(), Vector3(0, 1.4, sd * 0.5)), Vector3(sw, 2.8, sd))
	_spot("jardin_serre", sxf * Vector3(0.6, 0.05, -0.8), sxf * Vector3(0.6, 0, 1.0), "jardiner")
	# le puits
	var wp: Vector3 = W(-6.0, 51.5, y)
	kit.ring(Transform3D(Basis(), wp), 0.75, 1.05, 0.85, "pierrearc", 20)
	kit.disc(Transform3D(Basis(), wp + Vector3.UP * 0.3), 0.76, "eaulac", 16)
	for s2 in [-1.0, 1.0]:
		kit.box(Transform3D(Basis(), wp + Vector3(s2 * 0.95, 1.4, 0)), Vector3(0.14, 2.0, 0.14), "poutre", 1.0)
	kit.cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), wp + Vector3(1.0, 1.9, 0)), 0.08, 0.08, 2.0, "poutre_clair", 8)
	kit.roof_gable(Transform3D(Basis(Vector3.UP, PI * 0.5), wp + Vector3.UP * 2.35), 1.4, 2.3, 40.0, 0.15, "ecailles", "poutre")
	kit.col_cyl(wp, 1.05, 0.9)
	# les ruches de paille et leur banc
	var hp: Vector3 = W(-8.0, 44.0, y)
	kit.box(Transform3D(Basis(Vector3.UP, 1.2), hp + Vector3.UP * 0.4), Vector3(2.6, 0.08, 0.6), "poutre", 1.0)
	for k in range(3):
		var sk: Vector3 = hp + Vector3(-0.8 + k * 0.8, 0.44, 0).rotated(Vector3.UP, 1.2)
		kit.cyl(Transform3D(Basis(), sk), 0.3, 0.05, 0.62, "paille", 12)
	kit.col_box(Transform3D(Basis(Vector3.UP, 1.2), hp + Vector3.UP * 0.4), Vector3(2.6, 0.8, 0.6))
	_spot("jardin_ruches", hp + Vector3(1.2, 0.05, 0.6), hp, "observer")
	# l'épouvantail au chapeau pointu
	var ep: Vector3 = W(3.5, 50.0, y)
	kit.cyl(Transform3D(Basis(), ep), 0.05, 0.05, 1.9, "poutre", 6)
	kit.box(Transform3D(Basis(), ep + Vector3.UP * 1.45), Vector3(1.4, 0.06, 0.06), "poutre", 1.0)
	kit.cyl(Transform3D(Basis(), ep + Vector3.UP * 0.9), 0.25, 0.18, 0.75, "tissu_bordeaux", 10)
	kit.cyl(Transform3D(Basis(), ep + Vector3.UP * 1.72), 0.16, 0.14, 0.3, "paille", 10)
	kit.cyl(Transform3D(Basis(), ep + Vector3.UP * 1.98), 0.38, 0.0, 0.08, "tissu_noir", 14)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.15), ep + Vector3.UP * 2.0), 0.16, 0.0, 0.62, "tissu_noir", 12)
	# le banc du jardin, le muret
	var bxf: Transform3D = XF(W(-3.5, 53.0, y), 0.0, -1.0)
	kit.bench(bxf)
	_spot("jardin_banc", bxf * Vector3(0.3, 0.05, 0.05), bxf * Vector3(0, 0, -2.0), "assis")
	var gaps: Array = [0.0, 37.0, 101.0, 216.0]
	var A := Vector2(0.0, 46.0)
	var ang0: float = 0.0
	while ang0 < 360.0:
		var a1: float = ang0 + 8.0
		var blocked: bool = false
		for gpa in gaps:
			if absf(fposmod(ang0 + 4.0 - float(gpa) + 180.0, 360.0) - 180.0) < 13.0:
				blocked = true
		if not blocked:
			kit.low_wall(G(A.x + cos(deg_to_rad(ang0)) * 11.5, A.y + sin(deg_to_rad(ang0)) * 11.5), G(A.x + cos(deg_to_rad(a1)) * 11.5, A.y + sin(deg_to_rad(a1)) * 11.5), 0.7, 0.45)
		ang0 = a1
	var jw: Vector3 = R.W(0.0, 46.0)
	flora_avoid.append([Vector2(jw.x, jw.z), 12.5])


# =================================================================== l'Aire des Duels

func _aire() -> void:
	var y: float = PY("aire")
	var c: Vector3 = W(58.0, 0.0, y)
	kit.disc(Transform3D(Basis(), c + Vector3.UP * 0.04), 10.2, "dallesarc", 40, 3.0)
	kit.quad(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), c + Vector3.UP * 0.07), 8.0, 8.0, "runes_or", Vector2(0, 0), Vector2(1, 1))
	var gaps: Array = [90.0, 219.0]
	var ang0: float = 0.0
	while ang0 < 360.0:
		var a1: float = ang0 + 7.5
		var blocked: bool = false
		for gpa in gaps:
			if absf(fposmod(ang0 + 3.75 - float(gpa) + 180.0, 360.0) - 180.0) < 12.0:
				blocked = true
		if not blocked:
			kit.low_wall(c + Vector3(cos(deg_to_rad(ang0)), 0, sin(deg_to_rad(ang0))) * 10.8, c + Vector3(cos(deg_to_rad(a1)), 0, sin(deg_to_rad(a1))) * 10.8, 0.75, 0.5, "pierrearc")
		ang0 = a1
	# les cinq braseros (éteints : on les allume d'un sort de feu)
	for k in range(5):
		var a: float = deg_to_rad([270.0, 335.0, 35.0, 145.0, 190.0][k])
		var bp: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 8.6
		var fire: Vector3 = kit.brazier(bp, 1.05)
		braziers.append({"pos": fire, "lit": false, "node": null, "light": null})
	# les mannequins de paille (cibles des apprentis)
	for k2 in range(3):
		var dp: Vector3 = c + Vector3(-3.5 + k2 * 3.5, 0.0, -4.0 - (1.0 if k2 == 1 else 0.0))
		var dn := Node3D.new()
		dn.name = "Mannequin_%d" % k2
		add_child(dn)
		dn.position = dp
		_dummy(dn)
		dummies.append({"node": dn, "pos": dp + Vector3.UP * 1.2, "burn": 0.0})
		kit.col_cyl(dp, 0.3, 1.9)
	_spot("aire_centre", c + Vector3(0.0, 0.05, 2.2), c + Vector3(0, 0, -4.0), "lancer_sort")
	_spot("aire_braseros", c + Vector3(-5.0, 0.05, -5.0), c + Vector3(-7.0, 0, -7.0), "debout")
	var bxf: Transform3D = XF(c + Vector3(6.5, 0.0, 12.6), -0.3, -1.0)
	bxf.origin.y = ile.height(bxf.origin.x, bxf.origin.z)
	kit.bench(bxf)
	_spot("aire_banc", bxf * Vector3(0.3, 0.05, 0.05), c, "assis")
	# le râtelier des baguettes
	var rp: Vector3 = c + Vector3(7.8, 0.0, -5.6)
	var rxf: Transform3D = XF(rp, -1.0, 0.6)
	kit.box(rxf * Transform3D(Basis(), Vector3(0, 0.9, 0)), Vector3(1.6, 0.08, 0.2), "poutre", 1.0)
	kit.box(rxf * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(1.6, 0.08, 0.3), "poutre", 1.0)
	for k3 in range(6):
		kit.cyl(rxf * Transform3D(Basis(Vector3.BACK, 0.1), Vector3(-0.65 + k3 * 0.26, 0.2, 0)), 0.02, 0.012, 1.1, "poutre_clair", 5)
	var aw: Vector3 = R.W(58.0, 0.0)
	flora_avoid.append([Vector2(aw.x, aw.z), 14.0])


func _dummy(dn: Node3D) -> void:
	var straw: Material = kit.mat("paille")
	var wood: Material = kit.mat("poutre")
	var parts := [[CylinderMesh.new(), wood, Vector3(0, 0.9, 0), Vector3(0.05, 1.8, 0.05)], [CylinderMesh.new(), straw, Vector3(0, 1.15, 0), Vector3(0.28, 0.8, 0.24)],
		[SphereMesh.new(), straw, Vector3(0, 1.75, 0), Vector3(0.2, 0.22, 0.2)], [CylinderMesh.new(), straw, Vector3(0, 1.4, 0), Vector3(0.07, 1.2, 0.07)]]
	for i in range(parts.size()):
		var pr: Array = parts[i]
		var mi := MeshInstance3D.new()
		var mesh: PrimitiveMesh = pr[0]
		if mesh is CylinderMesh:
			(mesh as CylinderMesh).top_radius = 1.0
			(mesh as CylinderMesh).bottom_radius = 1.0
			(mesh as CylinderMesh).height = 1.0
		else:
			(mesh as SphereMesh).radius = 1.0
			(mesh as SphereMesh).height = 2.0
		mi.mesh = mesh
		mi.material_override = pr[1]
		mi.position = pr[2]
		mi.scale = pr[3]
		if i == 3:
			mi.rotation = Vector3(0, 0, PI * 0.5)
		dn.add_child(mi)


# =================================================================== le Lac Miroir

func _lac() -> void:
	var c: Vector3 = W(R.LAKE.x, R.LAKE.y, R.LAKE_Y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 64
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var r0: float = R.LAKE_R + 0.9 + sin(a0 * 5.0) * 0.6
		var r1: float = R.LAKE_R + 0.9 + sin(a1 * 5.0) * 0.6
		for v in [[Vector3.ZERO, Vector2(c.x, c.z)], [Vector3(cos(a1) * r1, 0, sin(a1) * r1), Vector2(c.x + cos(a1) * r1, c.z + sin(a1) * r1)], [Vector3(cos(a0) * r0, 0, sin(a0) * r0), Vector2(c.x + cos(a0) * r0, c.z + sin(a0) * r0)]]:
			st.set_normal(Vector3.UP)
			st.set_uv((v[1] as Vector2) * 0.5)
			st.add_vertex(v[0])
	st.generate_tangents()
	lake_water = MeshInstance3D.new()
	lake_water.name = "Lac_Miroir"
	lake_water.mesh = st.commit()
	lake_water.material_override = kit.mat("eaulac")
	lake_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake_water)
	lake_water.position = c
	# l'îlot : un socle de pierre-lune, le Cristal de Givre dessus
	var ip: Vector3 = W(R.ISLET.x, R.ISLET.y, R.ISLET_Y)
	islet_pos = ip
	kit.cyl(Transform3D(Basis(), ip), 0.6, 0.5, 1.1, "pierrelune", 8)
	kit.cyl(Transform3D(Basis(), ip + Vector3.UP * 1.1), 0.7, 0.7, 0.12, "pierrelune", 8)
	kit.col_cyl(ip, 0.6, 1.2)
	kit.quad(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), ip + Vector3.UP * 0.04), 4.6, 4.6, "runes_pale", Vector2(0, 0), Vector2(1, 1))
	islet_crystal = Node3D.new()
	islet_crystal.name = "Cristal_de_givre"
	add_child(islet_crystal)
	islet_crystal.position = ip + Vector3.UP * 1.9
	_crystal_node(islet_crystal, 0.45, "cristal_givre")
	# la rive de Borée, au bout du chemin du lac
	var rp: Vector3 = G(32.0, -35.5, 0.05)
	_spot("lac_rive", rp, c + Vector3(0, 0, 0), "lancer_sort")
	var lw: Vector3 = R.W(R.LAKE.x, R.LAKE.y)
	flora_avoid.append([Vector2(lw.x, lw.z), R.LAKE_R + 1.2])


# =================================================================== la Tour Penchée

func _tour_penchee() -> void:
	var y: float = PY("tour")
	var base: Vector3 = W(-20.0, 85.0, y - 0.4)
	var lean := Basis(Vector3.RIGHT, 0.13) * Basis(Vector3.FORWARD, 0.05)
	var xf := Transform3D(lean, base)
	var r: float = 3.0
	var h: float = 15.0
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, -0.8, 0)), r + 0.3, r + 0.2, 1.4, "pierrearc_sombre", 18, false, 3.0)
	kit.cyl(xf, r, r, h, "pierrearc_mousse", 18, false, 3.0)
	kit.cyl(xf * Transform3D(Basis(), Vector3(0, h - 0.02, 0)), r, r, 0.04, "dallesarc", 18, true, 2.0)
	for yy in [4.5, 9.0, 13.2]:
		kit.cyl(xf * Transform3D(Basis(), Vector3(0, yy, 0)), r + 0.08, r + 0.08, 0.2, "pierrearc_clair", 18, false, 2.0)
	# les créneaux ébréchés
	for k in range(18):
		if k in [3, 4, 9, 14]:
			continue
		var a: float = TAU * k / 18.0
		var mh: float = 0.6 + float((k * 5) % 3) * 0.25
		kit.box(xf * Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * (r - 0.2), h + mh * 0.5, sin(a) * (r - 0.2))), Vector3(0.45, mh, 0.9), "pierrearc_mousse", 1.5)
	# fenêtres, porte murée
	for k2 in range(3):
		var wa: float = TAU * k2 / 3.0 + 0.5
		var wxf: Transform3D = xf * Transform3D(Basis.looking_at(Vector3(cos(wa), 0, sin(wa)), Vector3.UP), Vector3(cos(wa) * r, 6.0 + k2 * 3.0, sin(wa) * r))
		kit.lancet(wxf, 0.55, 1.5, "pierrearc_mousse")
	var dxf: Transform3D = xf * Transform3D(Basis.looking_at(Vector3(0.3, 0, -1).normalized(), Vector3.UP), Vector3(0.3, 0, -1).normalized() * r)
	kit.arch_door(dxf, 1.2, 2.6)
	# la collision : un cylindre penché ; le dessus est un palier où l'on peut se poser
	var cs := CollisionShape3D.new()
	var shp := CylinderShape3D.new()
	shp.radius = r
	shp.height = h
	cs.shape = shp
	cs.transform = xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0))
	kit.body.add_child(cs)
	# la cloche, sous son portique, au sommet
	var top: Transform3D = xf * Transform3D(Basis(), Vector3(0, h, 0))
	bell = kit.bell_frame(top * Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.6, 0, 0.4)), 0.45)
	bell_pos = bell.global_position if bell.is_inside_tree() else bell.transform.origin
	# un livre envolé posé sur le rebord d'une fenêtre, à mi-hauteur
	var bw: float = TAU * 1.0 / 3.0 + 0.5
	books_high["livre_tour"] = (xf * Transform3D(Basis(), Vector3(cos(bw) * (r + 0.35), 9.0 - 0.7, sin(bw) * (r + 0.35)))).origin
	_spot("tour_pied", G(-14.5, 78.5, 0.05), W(-20.0, 85.0, y + 8.0), "observer")
	var tw: Vector3 = R.W(-20.0, 85.0)
	flora_avoid.append([Vector2(tw.x, tw.z), 6.5])


# =================================================================== le bourg

func _floor(x0: float, z0: float, x1: float, z1: float) -> float:
	return maxf(maxf(TY(x0, z0), TY(x1, z0)), maxf(TY(x0, z1), TY(x1, z1)))


func _socle(xf: Transform3D, w: float, d: float, depth: float = 1.2) -> void:
	kit.box(xf * Transform3D(Basis(), Vector3(0, -depth * 0.5, d * 0.5)), Vector3(w + 0.2, depth, d + 0.2), "pierrearc_sombre", 2.0, 63 - 4 - 8)


func _bourg() -> void:
	# --- Le Chaudron Fumant (on y entre)
	var fy: float = TY(46.0, 35.0) + 0.06
	var txf: Transform3D = XF(W(46.0, 35.0, fy), 0.0, 1.0)
	_socle(txf, 12.0, 10.0)
	var hd: Dictionary = kit.hall(txf, 12.0, 10.0, {"h": 4.4, "roof_key": "ecailles_rouge", "floor_key": "planches", "inner": "colombage_ocre", "lights": 3, "energy": 1.5, "pitch": 44.0})
	doors["chaudron"] = hd["door"]
	_sign(txf * Transform3D(Basis(), Vector3(0, 3.45, -0.14)), 2.8, 0.7, "chaudron")
	kit.box(txf * Transform3D(Basis(), Vector3(0, -0.05, -0.75)), Vector3(2.4, 0.22, 1.1), "pierrearc_clair", 1.0)
	kit.col_box(txf * Transform3D(Basis(), Vector3(0, -0.05, -0.75)), Vector3(2.4, 0.22, 1.1))
	# le comptoir de Berthe, côté ouest
	var ctr: Transform3D = txf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(3.6, 0.0, 5.0))
	kit.box(ctr * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(5.0, 1.1, 0.6), "poutre", 1.0)
	kit.box(ctr * Transform3D(Basis(), Vector3(0, 1.13, 0)), Vector3(5.2, 0.07, 0.8), "poutre_clair", 1.0)
	kit.col_box(ctr * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(5.0, 1.1, 0.6))
	for k in range(4):
		kit.barrel(ctr * Vector3(-1.8 + k * 1.2, 0.0, 1.9), true)
	for k2 in range(4):
		var shelf: Transform3D = txf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(5.33, 1.6 + k2 * 0.5, 5.0))
		kit.box(shelf, Vector3(3.0, 0.05, 0.3), "poutre", 1.0)
		for b in range(6):
			kit.cyl(shelf * Transform3D(Basis(), Vector3(-1.2 + b * 0.48, 0.02, 0)), 0.06, 0.05, 0.28, ["flacon_rouge", "flacon_vert", "flacon_or", "flacon", "flacon_violet", "flacon_rose"][(b + k2) % 6], 8)
	_spot("chaudron_comptoir", ctr * Vector3(0, 0.05, 0.95), ctr * Vector3(0, 0, -1.0), "comptoir")
	for k3 in range(4):
		_spot("chaudron_bar_%d" % (k3 + 1), ctr * Vector3(-1.8 + k3 * 1.2, 0.05, -0.85), ctr * Vector3(-1.8 + k3 * 1.2, 0, 0), "boire")
	# la cheminée et son chaudron
	var fp: Transform3D = txf * Transform3D(Basis(), Vector3(0.0, 0.0, 9.3))
	kit.box(fp * Transform3D(Basis(), Vector3(0, 1.0, 0.0)), Vector3(2.4, 2.0, 0.5), "pierrearc", 1.0)
	kit.box(fp * Transform3D(Basis(), Vector3(0, 0.75, -0.01)), Vector3(1.5, 1.5, 0.52), "fer", 1.0, 32)
	kit.box(fp * Transform3D(Basis(), Vector3(0, 2.05, -0.05)), Vector3(2.7, 0.15, 0.6), "poutre", 1.0)
	var cpt: Vector3 = kit.cauldron(fp * Transform3D(Basis(), Vector3(0, 0.05, -0.75)), 0.45, "liquide_or")
	fire_spots.append([fp * Vector3(0, 0.1, -0.2), 0.8])
	smoke_spots.append(cpt + Vector3.UP * 0.2)
	smoke_spots.append(txf * Vector3(3.0, 4.4 + 4.5, 7.5))
	kit.box(txf * Transform3D(Basis(), Vector3(0.0, 4.4 + 3.2, 9.0)), Vector3(1.0, 3.0, 0.8), "pierrearc_sombre", 1.5)
	# les tables
	var tables := [Vector3(-1.0, 0, 3.0), Vector3(-3.6, 0, 3.0), Vector3(-1.0, 0, 6.6), Vector3(-3.6, 0, 6.6)]
	for i in range(4):
		var tp: Vector3 = txf * (tables[i] as Vector3)
		kit.cafe_table(tp, 0.0, 2, "")
		for ch in range(2):
			var ang: float = TAU * ch / 2.0 + 0.3
			var cp: Vector3 = tp + Vector3(cos(ang) * 0.62, 0.05, sin(ang) * 0.62)
			_spot("chaudron_table_%d" % (i * 2 + ch + 1), cp, tp, "assis")
	interiors.append(["chaudron", txf * Vector3(0, 0, 5.0), Vector2(5.6, 4.6), fy])
	_pt("chau_in", Vector3((txf * Vector3(0, 0, 1.4)).x, fy, (txf * Vector3(0, 0, 1.4)).z))
	# --- L'Alambic : la boutique de potions de Gustave (comptoir dehors, sous l'auvent)
	var ay: float = _floor(58.0, 40.0, 65.0, 48.0)
	var axf: Transform3D = XF(W(58.0, 44.0, ay), -1.0, 0.0)
	_socle(axf, 8.0, 7.0)
	doors["alambic"] = kit.timber_house(axf, 8.0, 7.0, {"toit": "violet", "enduit": "rose", "door_x": 2.6, "lucarne": true})
	kit.awning(axf * Transform3D(Basis(), Vector3(-1.2, 2.9, 0)), 4.6, 1.8, 0.7, "bordeaux")
	_sign(axf * Transform3D(Basis(), Vector3(-1.2, 3.25, -0.12)), 2.2, 0.55, "alambic")
	var sxf: Transform3D = axf * Transform3D(Basis(), Vector3(-1.2, 0, -1.5))
	sxf.origin.y = TY(R.L(sxf.origin.x, sxf.origin.z).x, R.L(sxf.origin.x, sxf.origin.z).y)
	kit.box(sxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.2, 1.0, 0.6), "poutre", 1.0)
	kit.box(sxf * Transform3D(Basis(), Vector3(0, 1.03, 0)), Vector3(3.4, 0.06, 0.8), "poutre_clair", 1.0)
	kit.col_box(sxf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(3.2, 1.0, 0.6))
	for b2 in range(9):
		var bb: Vector3 = Vector3(-1.4 + b2 * 0.35, 1.06, -0.1 + (b2 % 2) * 0.18)
		kit.cyl(sxf * Transform3D(Basis(), bb), 0.07 + (b2 % 3) * 0.02, 0.05, 0.22 + (b2 % 3) * 0.06, ["flacon_rouge", "flacon_vert", "flacon_or", "flacon", "flacon_violet", "flacon_rose"][b2 % 6], 8)
	kit.cauldron(sxf * Transform3D(Basis(), Vector3(2.3, 0.0, 0.3)), 0.45, "liquide_violet")
	smoke_spots.append(sxf * Vector3(2.3, 0.6, 0.3))
	_spot("alambic_comptoir", sxf * Vector3(0.0, 0.05, 0.75), sxf * Vector3(0.0, 0.0, -1.5), "comptoir")
	# --- la fontaine du Fondateur
	var fc: Vector3 = W(46.0, 44.0, TY(46.0, 44.0))
	kit.ring(Transform3D(Basis(), fc), 2.3, 2.75, 0.6, "pierrearc_clair", 32)
	kit.disc(Transform3D(Basis(), fc + Vector3.UP * 0.45), 2.32, "eaulac", 28)
	kit.col_cyl(fc, 2.75, 0.6)
	kit.cyl(Transform3D(Basis(), fc), 0.7, 0.55, 1.6, "pierrearc", 10)
	kit.cyl(Transform3D(Basis(), fc + Vector3.UP * 1.6), 0.4, 0.45, 1.5, "pierrelune", 10)
	kit.cyl(Transform3D(Basis(), fc + Vector3.UP * 3.1), 0.22, 0.2, 0.3, "pierrelune", 10)
	kit.cyl(Transform3D(Basis(), fc + Vector3.UP * 3.25), 0.16, 0.16, 0.3, "pierrelune", 10)
	kit.cyl(Transform3D(Basis(Vector3.BACK, 0.12), fc + Vector3(0.0, 3.5, 0.0)), 0.42, 0.0, 0.95, "pierrelune", 12)
	kit.cyl(Transform3D(Basis(), fc + Vector3(0.0, 3.48, 0.0)), 0.5, 0.5, 0.05, "pierrelune", 14)
	kit.cyl(Transform3D(Basis(Vector3.BACK, -0.35), fc + Vector3(0.35, 2.5, 0.0)), 0.05, 0.04, 2.4, "pierrelune", 6)
	statue_orb = fc + Vector3(1.15, 4.75, 0.0)
	kit.col_cyl(fc, 0.7, 3.2)
	for s in range(3):
		var sa: float = TAU * s / 3.0 + 0.6
		_spot("place_fontaine_%d" % (s + 1), fc + Vector3(cos(sa), 0, sin(sa)) * 3.3 + Vector3.UP * 0.05, fc, "debout")
	_spot("place_jeu_1", W(42.0, 46.5, TY(42.0, 46.5) + 0.05), fc, "jouer")
	_spot("place_jeu_2", W(49.0, 48.5, TY(49.0, 48.5) + 0.05), fc, "jouer")
	for la in range(4):
		var aa: float = TAU * la / 4.0 + 0.78
		var lp: Vector3 = W(46.0 + cos(aa) * 8.8, 44.0 + sin(aa) * 8.8, 0.0)
		lp.y = TY(46.0 + cos(aa) * 8.8, 44.0 + sin(aa) * 8.8)
		kit.orb_lamp(lp, 3.4, "or", pc)
	# --- l'étal de Mirabelle (les potions ratées des apprentis)
	var mxf: Transform3D = XF(W(39.5, 47.0, TY(39.5, 47.0)), 1.0, -0.3)
	for s3 in [-1.0, 1.0]:
		for f in [0.0, 1.0]:
			kit.box(mxf * Transform3D(Basis(), Vector3(s3 * 1.1, 1.1, f * 1.2)), Vector3(0.08, 2.2, 0.08), "poutre", 1.0)
	kit.box(mxf * Transform3D(Basis(), Vector3(0, 0.45, 0.2)), Vector3(2.2, 0.9, 0.7), "poutre_clair", 1.0)
	kit.col_box(mxf * Transform3D(Basis(), Vector3(0, 0.45, 0.2)), Vector3(2.2, 0.9, 0.7))
	kit.box(mxf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 2.25, 0.55)), Vector3(2.6, 0.05, 1.7), "tissu_bleu", 1.0)
	for b3 in range(6):
		kit.cyl(mxf * Transform3D(Basis(), Vector3(-0.8 + b3 * 0.32, 0.9, 0.15)), 0.07, 0.05, 0.2, ["flacon_rose", "flacon_vert", "flacon", "flacon_or", "flacon_rouge", "flacon_violet"][b3], 8)
	_spot("etal_mirabelle", mxf * Vector3(0, 0.05, 0.95), mxf * Vector3(0, 0, -1.0), "comptoir")
	# --- les maisons du bourg
	var houses := [[Vector2(34.0, 39.0), Vector2(1, 0), 6.0, 6.0, "h1", "", ""], [Vector2(34.0, 53.0), Vector2(1, 0), 6.0, 6.0, "h2", "bleu", "bleu"],
		[Vector2(41.0, 55.0), Vector2(0, -1), 7.0, 6.0, "h3", "ocre", ""], [Vector2(60.0, 52.0), Vector2(-1, 0), 6.0, 6.0, "h4", "", "vert"],
		[Vector2(66.0, 30.0), Vector2(-1, 0), 6.0, 6.0, "h5", "rose", "rouge"]]
	for hs in houses:
		var hp: Vector2 = hs[0]
		var hdir: Vector2 = hs[1]
		var hw: float = float(hs[2])
		var hdd: float = float(hs[3])
		var back: Vector2 = hp - hdir * hdd
		var side := Vector2(-hdir.y, hdir.x) * hw * 0.5
		var yy: float = _floor(minf(hp.x, back.x) - absf(side.x), minf(hp.y, back.y) - absf(side.y), maxf(hp.x, back.x) + absf(side.x), maxf(hp.y, back.y) + absf(side.y))
		var hxf: Transform3D = XF(W(hp.x, hp.y, yy), hdir.x, hdir.y)
		_socle(hxf, hw, hdd)
		var opts := {"lucarne": hw > 6.5}
		if str(hs[5]) != "":
			opts["enduit"] = str(hs[5])
		if str(hs[6]) != "":
			opts["toit"] = str(hs[6])
		doors[str(hs[4])] = kit.timber_house(hxf, hw, hdd, opts)
		kit.porte_v81(hxf, Vector3(float(opts.get("door_x", 0.0)), 0, -1.0), hw, hdd, "arcanelle", 2, "")
		smoke_spots.append(hxf * Vector3(hw * 0.3, 3.0 + 2.8 + 4.6, hdd * 0.68))
	# --- le cabanon de Gaspard, le passeur, au bord de la grève
	var gy: float = ile.height(R.W(76.0, 61.0).x, R.W(76.0, 61.0).z)
	var gxf: Transform3D = XF(W(76.0, 61.0, gy + 0.1), 0.0, 1.0)
	_socle(gxf, 4.0, 3.6, 1.6)
	doors["mathurin"] = kit.timber_house(gxf, 4.0, 3.6, {"gf": 2.6, "uf": 1.6, "lucarne": false, "toit": "bleu", "chem_x": -0.8})
	kit.porte_v81(gxf, Vector3(0, 0, -1.0), 4.0, 3.6, "arcanelle", 1, "mathurin")
	for k4 in range(3):
		kit.barrel(gxf * Vector3(-2.6, 0.0, 0.6 + k4 * 0.9), true)
	_spot("quai_peche", _dock_point(0.8) + (R.W(R.DOCK_B.x, R.DOCK_B.y) - R.W(R.DOCK_A.x, R.DOCK_A.y)).normalized().cross(Vector3.UP) * 0.7, _dock_point(0.8) + (R.W(R.DOCK_B.x, R.DOCK_B.y) - R.W(R.DOCK_A.x, R.DOCK_A.y)).normalized().cross(Vector3.UP) * 3.0, "pecher")
	_spot("quai_bout", _dock_point(0.95), _dock_point(1.5), "debout")


func _dock_point(t: float) -> Vector3:
	var a: Vector3 = R.W(R.DOCK_A.x, R.DOCK_A.y, 0.0)
	var b: Vector3 = R.W(R.DOCK_B.x, R.DOCK_B.y, 0.0)
	var p: Vector3 = a.lerp(b, t)
	var bt: Node = main.get("boat_v29") if main != null else null
	p.y = (float(bt.DECK_Y) if bt != null else 0.6) + 0.04
	return p


## Une enseigne d'Arcanelle (texture du dossier arcanelle) : un panneau de bois, l'image devant.
func _sign(xf: Transform3D, w: float, h: float, key: String) -> void:
	kit.box(xf, Vector3(w + 0.08, h + 0.08, 0.06), "poutre", 1.0)
	kit.quad(xf * Transform3D(Basis(), Vector3(0, 0, -0.035)), w, h, "enseignearc_" + key)


# =================================================================== les maisons des maîtres

func _maisons_maitres() -> void:
	# Mère Sauge : une chaumière à côté du jardin
	var sp: Vector3 = W(12.0, 55.0, PY("sauge"))
	var sxf: Transform3D = XF(sp, -1.0, -0.4)
	doors["sauge"] = kit.timber_house(sxf, 6.0, 5.0, {"toit": "vert", "enduit": "ocre", "lucarne": false})
	kit.porte_v81(sxf, Vector3(0, 0, -1.0), 6.0, 5.0, "arcanelle", 1, "sauge")
	var sb: Transform3D = XF(sxf * Vector3(2.2, 0, -1.6), -1.0, -0.4)
	kit.bench(sb)
	_spot("maison_sauge_banc", sb * Vector3(0.3, 0.05, 0.05), sb * Vector3(0, 0, -2.0), "assis")
	# Borée : la maison du lac
	var bp: Vector3 = W(2.0, -34.0, PY("boree"))
	var bxf: Transform3D = XF(bp, 0.83, -0.55)
	doors["boree"] = kit.timber_house(bxf, 6.0, 5.0, {"toit": "bleu", "enduit": "bleu", "lucarne": false})
	kit.porte_v81(bxf, Vector3(0, 0, -1.0), 6.0, 5.0, "arcanelle", 1, "boree")
	var bb: Transform3D = XF(bxf * Vector3(-2.0, 0, -1.8), 0.83, -0.55)
	kit.bench(bb)
	_spot("maison_boree_banc", bb * Vector3(0.3, 0.05, 0.05), bb * Vector3(0, 0, -3.0), "assis")
	# Zéphyrine : la petite maison au pied de la Tour Penchée, une girouette
	var zp: Vector3 = W(-6.0, 70.0, PY("zephyrine"))
	var zxf: Transform3D = XF(zp, 0.2, -1.0)
	doors["zephyrine"] = kit.timber_house(zxf, 5.0, 4.5, {"toit": "", "enduit": "", "lucarne": false})
	kit.porte_v81(zxf, Vector3(0, 0, -1.0), 5.0, 4.5, "arcanelle", 1, "zephyrine")
	var vane: Vector3 = zxf * Vector3(-0.8, 3.0 + 2.8 + 3.4, 2.25)
	kit.cyl(Transform3D(Basis(), vane), 0.03, 0.03, 1.2, "fer", 6)
	kit.box(Transform3D(Basis(Vector3.UP, 0.7), vane + Vector3.UP * 1.1), Vector3(0.9, 0.18, 0.02), "fer", 1.0)
	_spot("falaise_vent", G(-92.0, -22.0, 0.05), G(-130.0, -30.0), "observer")
	# Pyra : une tour au toit rouge, près de l'Aire des Duels
	var pc2: Vector3 = W(72.0, 14.0, PY("pyra"))
	var pdir := Vector3(-0.86, 0, -0.5)
	kit.tower(pc2, 2.7, 9.0, {"roof_h": 5.0, "windows": [3.5, 6.5], "nwin": 3, "door_dir": pdir, "roof_key": "ecailles_rouge", "over": 0.45})
	doors["pyra"] = pc2 + pdir * 3.9
	# Ysolde : une maison de pierre qui regarde le Cercle
	var yp: Vector3 = W(-54.0, 14.0, PY("ysolde"))
	var yxf: Transform3D = XF(yp, -0.45, -0.89)
	doors["ysolde"] = kit.timber_house(yxf, 5.5, 5.0, {"toit": "violet", "enduit": "bleu", "lucarne": false})
	kit.porte_v81(yxf, Vector3(0, 0, -1.0), 5.5, 5.0, "arcanelle", 1, "ysolde")
	var yb: Transform3D = XF(yxf * Vector3(2.0, 0, -1.7), -0.45, -0.89)
	kit.bench(yb)
	_spot("maison_ysolde_banc", yb * Vector3(0.3, 0.05, 0.05), yb * Vector3(0, 0, -3.0), "assis")
	# Agathe : la roulotte, dans le Bois Tors
	var ap: Vector3 = W(-44.0, 52.0, PY("agathe"))
	var axf: Transform3D = XF(ap, 1.0, 0.2)
	_roulotte(axf)
	doors["roulotte"] = axf * Vector3(1.2, 0, -1.6)
	var tt: Vector3 = axf * Vector3(-0.5, 0.0, -3.2)
	kit.cafe_table(tt, 0.0, 0, "")
	kit.crystal(Transform3D(Basis(), tt + Vector3.UP * 0.76), 0.18, "cristal_rose")
	_spot("roulotte_table", tt + (axf.basis * Vector3(0.0, 0.05, 0.75)), tt, "assis")
	fire_spots.append([axf * Vector3(2.6, 0.05, -4.2), 0.6])
	for pad in ["sauge", "boree", "zephyrine", "pyra", "ysolde", "agathe"]:
		var pw: Vector3 = R.W(float(R.PADS[pad][0]), float(R.PADS[pad][1]))
		flora_avoid.append([Vector2(pw.x, pw.z), float(R.PADS[pad][2]) + 1.5])


func _roulotte(xf: Transform3D) -> void:
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.75, 1.2)), Vector3(2.3, 1.9, 4.0), "tissu_bordeaux", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.75, 1.2)), Vector3(2.0, 0.15, 4.2), "poutre", 1.0)
	for k in range(9):
		var a0: float = PI * k / 9.0
		var a1: float = PI * (k + 1) / 9.0
		var p0 := Vector3(cos(a0) * 1.3, 2.7 + sin(a0) * 0.75, 0)
		var p1 := Vector3(cos(a1) * 1.3, 2.7 + sin(a1) * 0.75, 0)
		var n: Vector3 = (xf.basis * Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0)).normalized()
		kit.quad4("ecailles_vert", xf * (p0 + Vector3(0, 0, -0.95)), xf * (p1 + Vector3(0, 0, -0.95)), xf * (p1 + Vector3(0, 0, 3.35)), xf * (p0 + Vector3(0, 0, 3.35)), n, Vector2(0, 0), Vector2(0.4, 0), Vector2(0.4, 2.0), Vector2(0, 2.0))
	for s in [-1.0, 1.0]:
		for zz in [0.0, 2.6]:
			kit.cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * 1.25, 0.6, zz)), 0.55, 0.55, 0.1, "poutre_clair", 12)
	kit.small_window(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(1.16, 1.9, 1.6)), 0.6, 0.6)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 1.4, -0.82)), Vector3(0.9, 1.6, 0.06), "poutre_clair", 1.0)
	for k2 in range(3):
		kit.box(xf * Transform3D(Basis(), Vector3(0, 0.2 + k2 * 0.22, -1.0 - (2 - k2) * 0.2)), Vector3(0.8, 0.06, 0.22), "poutre", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 1.5, 1.2)), Vector3(2.4, 3.0, 4.2))
	kit.orb_lamp(xf * Vector3(1.6, 0.0, -1.2), 2.4, "vert", pc)


# =================================================================== le Bois Tors (la flore le plante ; ici, ses champignons qui luisent)

func _bois_tors() -> void:
	for k in range(26):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * 24.0
		var p: Vector3 = G(-62.0 + cos(a) * r, 46.0 + sin(a) * r)
		if p.y < 1.0:
			continue
		var hh: float = _rng.randf_range(0.15, 0.45)
		kit.cyl(Transform3D(Basis(), p), hh * 0.25, hh * 0.18, hh, "champi_pied" if kit.mats.has("champi_pied") else "pierrearc_clair", 6)
		kit.cyl(Transform3D(Basis(), p + Vector3.UP * hh), hh * 0.7, 0.0, hh * 0.45, "cristal_vert" if k % 3 != 0 else "cristal_bleu", 10, true)


# =================================================================== les objets de quête

func _quete_objets() -> void:
	# les éclats de lune (sort de lumière)
	objets["eclat_lune_1"] = circle_center + Vector3(1.6, 1.0, -0.9)
	objets["eclat_lune_2"] = G(-68.0, 56.0, 0.1)
	objets["eclat_lune_3"] = G(-98.0, 14.0, 0.1)
	# les flocons de givre éternel (sort de gel), sur les falaises du nord
	objets["flocon_1"] = G(-28.0, -86.0, 0.1)
	objets["flocon_2"] = G(6.0, -92.0, 0.1)
	objets["flocon_3"] = G(46.0, -80.0, 0.1)
	# les plumes du vent (sort de lévitation), aux endroits où souffle le vent
	objets["plume_vent_1"] = G(-80.0, -32.0, 0.1)
	objets["plume_vent_2"] = G(-50.0, -76.0, 0.1)
	objets["plume_vent_3"] = G(84.0, -28.0, 0.1)
	# les livres envolés (sort de télékinésie) : hors de portée de la main
	objets["livre_toit"] = books_high.get("livre_toit", G(8.0, 12.0, 8.0))
	objets["livre_menhir"] = books_high.get("livre_menhir", circle_center + Vector3.UP * 6.3)
	objets["livre_tour"] = books_high.get("livre_tour", G(-20.0, 85.0, 9.0))
	var tree: Vector3 = G(-70.0, 40.0)
	big_trees.append([tree, 1.45])
	objets["livre_arbre"] = tree + Vector3(0.4, 6.2, 0.3)
	# la chouette blessée (sort de soin), dans le Bois Tors
	owl_pos = G(-58.0, 54.0, 0.0)
	# le chemin de glace : la pointe du chemin du lac, et le socle de l'îlot
	objets["socle_givre"] = islet_pos


func _animated() -> void:
	# la chouette blessée : un petit oiseau gris posé au pied d'une souche
	owl = Node3D.new()
	owl.name = "Chouette_blessee"
	add_child(owl)
	owl.position = owl_pos
	var st: Material = kit.mat("poutre")
	kit.cyl(Transform3D(Basis(), owl_pos + Vector3(0.6, 0.0, 0.3)), 0.35, 0.3, 0.5, "poutre", 10)
	var body_m := StandardMaterial3D.new()
	body_m.albedo_color = Color(0.55, 0.48, 0.4)
	body_m.roughness = 0.95
	var face_m := StandardMaterial3D.new()
	face_m.albedo_color = Color(0.86, 0.8, 0.7)
	var eye_m := StandardMaterial3D.new()
	eye_m.albedo_color = Color(0.95, 0.75, 0.2)
	eye_m.emission_enabled = true
	eye_m.emission = Color(0.6, 0.45, 0.1)
	var parts := [[0.16, Vector3(0, 0.18, 0), Vector3(1.0, 1.25, 0.95), body_m], [0.12, Vector3(0, 0.38, 0.02), Vector3(1.0, 0.95, 0.95), body_m],
		[0.08, Vector3(0, 0.37, 0.09), Vector3(1.2, 1.0, 0.4), face_m], [0.025, Vector3(-0.04, 0.39, 0.12), Vector3.ONE, eye_m], [0.025, Vector3(0.04, 0.39, 0.12), Vector3.ONE, eye_m]]
	for pr in parts:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = float(pr[0])
		sm.height = float(pr[0]) * 2.0
		mi.mesh = sm
		mi.position = pr[1]
		mi.scale = pr[2]
		mi.material_override = pr[3]
		owl.add_child(mi)
	var wing := MeshInstance3D.new()
	var wm := SphereMesh.new()
	wm.radius = 0.14
	wm.height = 0.28
	wing.mesh = wm
	wing.material_override = body_m
	wing.position = Vector3(0.17, 0.12, -0.02)
	wing.scale = Vector3(0.35, 0.8, 1.5)
	wing.rotation = Vector3(0, 0, 1.0)
	wing.name = "Aile"
	owl.add_child(wing)
	owl.rotation.y = 0.6


# =================================================================== le graphe des habitants

func _graph() -> void:
	# les chemins : une chaîne de points tous les 5 m environ
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		var names: Array = []
		var step: int = 5
		var i: int = 0
		while i < pts.size():
			names.append(_pt("c_%s_%d" % [k, i], (pts[i] as Vector3) + Vector3.UP * 0.05))
			if i == pts.size() - 1:
				break
			i = mini(i + step, pts.size() - 1)
		_chain(names)
	# l'Académie : la cour autour du Grand Cristal
	var y: float = PY("academie")
	var ring: Array = [_pt("a_n", W(-6.0, -10.5, y)), _pt("a_ne", W(-0.5, -8.5, y)), _pt("a_e", W(1.0, -4.0, y)), _pt("a_se", W(-1.5, 1.5, y)),
		_pt("a_s", W(-6.0, 3.0, y)), _pt("a_sw", W(-11.0, 1.0, y)), _pt("a_w", W(-13.0, -4.0, y)), _pt("a_nw", W(-11.0, -9.0, y))]
	_chain(ring)
	_link(ring[-1], ring[0])
	_link("a_e", _nearest(W(2.0, -6.0, y), ["c_academie_"]))
	_link("a_w", _nearest(W(-24.0, -1.0, y), ["c_cercle_"]))
	_link("a_nw", _nearest(W(-22.0, -20.0, y), ["c_observatoire_"]))
	# le bourg : la place, les rues
	var sq: Array = [["b_pn", 46.0, 38.5], ["b_pne", 50.5, 39.5], ["b_pe", 52.0, 44.0], ["b_pse", 50.5, 48.5], ["b_ps", 46.0, 50.0], ["b_psw", 41.5, 48.5], ["b_pw", 40.0, 44.0], ["b_pnw", 41.5, 39.5]]
	var sqn: Array = []
	for e in sq:
		sqn.append(_pt(str(e[0]), W(float(e[1]), float(e[2]), TY(float(e[1]), float(e[2])) + 0.05)))
	_chain(sqn)
	_link(sqn[-1], sqn[0])
	var streets := [["b_pnw", [["b_n1", 36.0, 34.0], ["b_n2", 31.0, 31.0]], "c_montee_"], ["b_pw", [["b_w1", 33.0, 44.5], ["b_w2", 30.5, 46.5]], "c_jardin_"],
		["b_pne", [["b_e1", 55.0, 37.5], ["b_e2", 59.0, 32.0]], "c_aire_"], ["b_pse", [["b_se1", 55.0, 56.0], ["b_se2", 63.0, 61.0]], "c_quai_"]]
	for stt in streets:
		var chain: Array = [str(stt[0])]
		for e2 in stt[1]:
			chain.append(_pt(str(e2[0]), W(float(e2[1]), float(e2[2]), TY(float(e2[1]), float(e2[2])) + 0.05)))
		_chain(chain)
		_link(str(chain[-1]), _nearest(points[chain[-1]], [str(stt[2])]))
	# les chemins qui partent d'un autre chemin
	_link(_nearest(W(14.0, -6.0, 0.0) + Vector3.UP * 15.0, ["c_boree_"]), _nearest(W(14.0, -6.0, 0.0) + Vector3.UP * 15.0, ["c_academie_"]))
	_link(_nearest(G(14.0, 12.0), ["c_montee_"]), _nearest(G(14.0, 12.0), ["c_academie_"]))
	_link(_nearest(G(-40.0, 30.0), ["c_bois_"]), _nearest(G(-40.0, 30.0), ["c_crypte_"]))
	_link(_nearest(G(-48.0, 40.0), ["c_agathe_"]), _nearest(G(-48.0, 40.0), ["c_bois_"]))
	_link(_nearest(G(-48.0, -2.0), ["c_ysolde_"]), _nearest(G(-48.0, -2.0), ["c_cercle_"]))
	_link(_nearest(G(-8.0, 64.0), ["c_zephyrine_"]), _nearest(G(-8.0, 64.0), ["c_tour_"]))
	_link(_nearest(G(64.0, 8.0), ["c_pyra_"]), _nearest(G(64.0, 8.0), ["c_aire_"]))
	_link(_nearest(G(48.0, -8.0), ["c_lac_"]), _nearest(G(48.0, -8.0), ["c_aire_"]))
	# le jardin : un carrefour au milieu, où arrivent les chemins du bourg, de la crypte, de la tour, de Sauge
	var jy: float = PY("jardin")
	_pt("j_c", W(1.0, 47.0, jy + 0.05))
	for pf in ["c_jardin_", "c_crypte_", "c_tour_", "c_sauge_"]:
		_link("j_c", _nearest(W(1.0, 47.0, jy), [pf]))
	# l'Aire des Duels : un point au milieu
	_pt("aire_c", W(58.0, 3.0, PY("aire") + 0.05))
	_link("aire_c", _nearest(W(58.0, 10.0, PY("aire")), ["c_aire_"]))
	_link("aire_c", _nearest(W(48.0, -8.0, PY("aire")), ["c_lac_"]))
	# le Cercle
	_pt("cercle_c", circle_center + Vector3(2.0, 0.05, 2.5))
	_link("cercle_c", _nearest(circle_center, ["c_cercle_"]))
	# l'observatoire
	_pt("obs_c", W(-31.0, -45.0, PY("observatoire") + 0.05))
	_link("obs_c", _nearest(points["obs_c"], ["c_observatoire_"]))
	# les intérieurs
	_link("bib_in", _nearest(G(14.0, 12.0), ["c_montee_", "c_academie_"]))
	_link("chau_in", "b_pn")
	# les portes : reliées au point le plus proche (portes des intérieurs : à leur point intérieur)
	for d in doors:
		var dn: String = "porte_" + str(d)
		var dp: Vector3 = doors[d]
		dp.y = ile.height(dp.x, dp.z) + 0.05
		if str(d) == "chaudron":
			dp.y = TY(46.0, 36.2) + 0.05
		points[dn] = dp
		_link(dn, _nearest(dp, []))
	# chaque lieu d'activité a son point « @nom »
	for s in spots:
		var nm: String = "@" + str(s)
		points[nm] = spots[s]["pos"]
		var near: String = str(spots[s]["node"])
		var sp: Vector3 = spots[s]["pos"]
		if near == "" or not points.has(near):
			near = _inside_node(sp)
			if near == "":
				near = _nearest(sp, [])
		_link(nm, near)
		spots[s]["node"] = nm
	# la Salle des Cours : on y entre par sa porte
	if points.has("salle_in") and points.has("porte_salle"):
		_link("salle_in", "porte_salle")


## Un lieu dans une salle : on y va par le point intérieur de la salle.
func _inside_node(p: Vector3) -> String:
	for it in interiors:
		var c: Vector3 = it[1]
		var half: Vector2 = it[2]
		if absf(p.x - c.x) < half.x + 2.5 and absf(p.z - c.z) < half.y + 2.5 and absf(p.y - float(it[3])) < 2.0:
			match str(it[0]):
				"bibliotheque":
					return "bib_in"
				"chaudron":
					return "chau_in"
				"salle":
					return _pt("salle_in", Vector3((doors["salle"] as Vector3).x, float(it[3]), (doors["salle"] as Vector3).z) + (c - doors["salle"]).normalized() * 3.0 * Vector3(1, 0, 1))
	return ""

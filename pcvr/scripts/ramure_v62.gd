extends Node3D
## V62 : Ramure, le village des oreilles, dans la forêt des brumes à l'est de la grande île.
## Ses habitants ont des oreilles et une queue d'animal (renards, lapins, chats, loups, ours,
## tanukis, chouettes, écureuils, biches) ; chaque espèce a son métier. Ils vivent perchés dans
## six arbres géants, sur des plates-formes reliées par des ponts de corde :
##  - le Chêne-Mère : le Marché aux trocs (en bas), l'échoppe des Simples des renards et la
##    maison de Mère-Lune (au milieu), la Poste des chouettes (à la cime) ; un escalier en
##    colimaçon autour du tronc, et la nacelle d'osier de Bourru l'ours qui monte à la cime ;
##  - l'arbre du Guet (les loups veillent en haut) et sa tyrolienne jusqu'à la Clairière des
##    Jeux ; les arbres d'habitation (ouest, sud, des mares, nord) ;
##  - au sol : le Cercle de la Lune (chaque nuit : le feu, les tambours, les danses — à Ramure,
##    la lune est toujours pleine), la boulangerie des lapins et leur potager, la forge des
##    ours, la pêcherie des chats sur la grande mare, la Clairière des Jeux (départ de la Grande
##    Course : une boucle de lanternes autour du village), l'aire du Zéphyr, le ponton.
## Repère : ramure_relief_v62.gd.

const R = preload("res://scripts/ramure_relief_v62.gd")
const Kit = preload("res://scripts/ramure_kit_v62.gd")
const Nacelle = preload("res://scripts/nacelle_v62.gd")
const Flora = preload("res://scripts/flora_v25.gd")
const LIFT_A: float = 100.0              # l'angle de la nacelle autour du Chêne-Mère
const ZIP_A: float = 246.0               # l'angle du départ de la tyrolienne (arbre du Guet)
const ZIP_END := Vector2(22.0, -30.0)
const LANDING: float = 35.0              # le palier entre deux volées d'escalier (°)
const PAD := Vector3(1130.0, 10.0, -240.0)

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var objets: Dictionary = {}
var boat_dock: Array = []
var trees: Dictionary = {}             # id -> {c, base, decks: [{y, ri, ro, gaps, open, ring}], spiral: [[points]]}
var lift: Node3D
var zip: Node3D
var _fire_at := Vector3.ZERO
var _fire_light: OmniLight3D
var _fire_fx: Array = []
var _fireflies: Array = []
var _mist: Array = []
var _fete_lights: Array = []
var _music: AudioStreamPlayer3D
var fete_on: bool = false
var fete_heard: bool = false
var _forge_light: OmniLight3D
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _checkpoints: Array = []           # monde (le sol) : les arches de la course


# =================================================================== repères

func G(x: float, z: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.to_world(x, z)
	return Vector3(w.x, ile.height(w.x, w.z) + dy, w.z)


func contains(p: Vector3) -> bool:
	var t: Vector2 = R.to_local(p.x, p.z)
	return t.x > -48.0 and t.x < 110.0 and t.y > -118.0 and t.y < 92.0 and p.y > -10.0


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 6200
	kit = Kit.new()
	kit.pc_quality = pc
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.rng.seed = 6201
	for td in R.TREES:
		_tree(td)
	_bridges()
	_chantier()
	_market()
	_upper_decks()
	_cercle()
	_boulangerie()
	_forge()
	_pecherie()
	_jeux()
	_aire()
	_ponton()
	_paths_lanterns()
	_undergrowth()
	kit.commit()
	_rides()
	_fx()
	_graph()
	for l in find_children("*", "OmniLight3D", true, false):
		var ol: OmniLight3D = l
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 55.0
		ol.distance_fade_length = 15.0
		ol.shadow_enabled = false
	print("ILE_MANGA_V62: Ramure, %d lieux, %d points, en %d ms" % [spots.size(), points.size(), Time.get_ticks_msec() - t0])


## Un arbre géant, ses plates-formes, son escalier en colimaçon : une volée par étage, et entre
## deux volées un palier de LANDING degrés (on sort sur le plancher, on reprend l'escalier
## plus loin).
func _tree(td: Dictionary) -> void:
	var id: String = str(td["id"])
	var x: float = float(td["x"])
	var z: float = float(td["z"])
	var base: Vector3 = G(x, z)
	var info := {"c": Vector2(x, z), "base": base, "decks": [], "spiral": [], "td": td}
	trees[id] = info
	var a0: float = float(td["spiral"])
	var has_stairs: bool = a0 != INF
	kit.giant_tree(td, base, [a0] if has_stairs else [], 6200 + absi(hash(id)) % 1000)
	var decks: Array = td["decks"]
	var stair_decks: int = 0
	if has_stairs:
		stair_decks = decks.size() if id in ["mere", "guet"] else 1
	var a: float = a0
	var y_prev: float = base.y
	if has_stairs:
		var r0: float = float(td["r"]) + 0.9
		y_prev = G(x + cos(deg_to_rad(a0)) * r0, z + sin(deg_to_rad(a0)) * r0).y
	for i in range(decks.size()):
		var dy: float = float(decks[i][0])
		var ri: float = R.trunk_r(td, dy)
		var opening: Array = []
		if i < stair_decks:
			if i > 0:
				a += LANDING
			var res: Array = kit.spiral(td, base, y_prev, base.y + dy, a)
			a = float(res[0])
			opening = [a - 58.0, a + 1.0]
			(info["spiral"] as Array).append(res[1])
			y_prev = base.y + dy
		(info["decks"] as Array).append({"y": base.y + dy, "ri": ri, "ro": ri + float(decks[i][1]), "gaps": [], "open": opening, "ring": []})


func _decks() -> void:
	for id in trees:
		var info: Dictionary = trees[id]
		var base: Vector3 = info["base"]
		for i in range(info["decks"].size()):
			var d: Dictionary = info["decks"][i]
			var c := Vector3(base.x, float(d["y"]), base.z)
			kit.deck(c, float(d["ri"]), float(d["ro"]), d["open"], 1.7, d["gaps"])
			# le chemin de ronde des gens : 12 points autour du tronc
			var ring: Array = []
			for k in range(12):
				var nm: String = "%s_d%d_%d" % [id, i, k]
				points[nm] = Kit.ring_pt(c, float(d["ri"]) + 2.6, k * 30.0, c.y)
				ring.append(nm)
			for k2 in range(12):
				_link(ring[k2], ring[(k2 + 1) % 12])
			d["ring"] = ring


func _deck_node(id: String, i: int, a: float) -> String:
	var ring: Array = trees[id]["decks"][i]["ring"]
	var k: int = int(roundf(wrapf(a, 0.0, 360.0) / 30.0)) % 12
	return str(ring[k])


func _bridges() -> void:
	var made: Array = []
	for br in R.BRIDGES:
		var A: Dictionary = trees[str(br[0])]
		var B: Dictionary = trees[str(br[1])]
		var ca: Vector3 = A["base"]
		var cb: Vector3 = B["base"]
		var ang_ab: float = rad_to_deg(atan2(cb.z - ca.z, cb.x - ca.x))
		var ang_ba: float = ang_ab + 180.0
		var da: Dictionary = A["decks"][0]
		var db: Dictionary = B["decks"][0]
		(da["gaps"] as Array).append([ang_ab, 1.0])
		(db["gaps"] as Array).append([ang_ba, 1.0])
		var pa: Vector3 = Kit.ring_pt(ca, float(da["ro"]) - 0.3, ang_ab, float(da["y"]))
		var pb: Vector3 = Kit.ring_pt(cb, float(db["ro"]) - 0.3, ang_ba, float(db["y"]))
		made.append([str(br[0]), str(br[1]), pa, pb, ang_ab, ang_ba])
	# l'ascenseur arrive à la cime du Chêne-Mère ; la tyrolienne part du haut du Guet
	(trees["mere"]["decks"][2]["gaps"] as Array).append([LIFT_A, 0.9])
	(trees["guet"]["decks"][1]["gaps"] as Array).append([ZIP_A, 0.8])
	_decks()
	for m in made:
		var span: float = (m[2] as Vector3).distance_to(m[3])
		var sag: float = clampf(span * 0.055, 0.4, 1.4)
		var pts: Array = kit.rope_bridge(m[2], m[3], sag)
		var names: Array = []
		for k in range(pts.size()):
			var nm: String = "%s_%s_%d" % [m[0], m[1], k]
			points[nm] = pts[k]
			names.append(nm)
		_chain(names)
		_link(names[0], _deck_node(m[0], 0, m[4]))
		_link(names[names.size() - 1], _deck_node(m[1], 0, m[5]))
		# des lanternes sur les mains courantes
		var nl: int = maxi(2, int(span / 5.0))
		for k2 in range(nl):
			var tt: float = (k2 + 0.5) / nl
			var rp: Vector3 = Kit.bridge_rail_point(m[2], m[3], sag, tt, -1.0 if k2 % 2 == 0 else 1.0)
			kit.paper_lantern(rp + Vector3.DOWN * 0.45, 0.65, "papier" if k2 % 3 else "papier_rouge")
	# les escaliers : reliés aux plates-formes et au sol
	for id in trees:
		var info: Dictionary = trees[id]
		var sp: Array = info["spiral"]
		for i in range(sp.size()):
			var nodes: Array = sp[i]
			var names2: Array = []
			for k3 in range(nodes.size()):
				var nm2: String = "%s_s%d_%d" % [id, i, k3]
				points[nm2] = nodes[k3]
				names2.append(nm2)
			_chain(names2)
			var top: Vector3 = nodes[nodes.size() - 1]
			var c2: Vector3 = info["base"]
			var a_top: float = rad_to_deg(atan2(top.z - c2.z, top.x - c2.x))
			_link(names2[names2.size() - 1], _deck_node(id, i, a_top + 15.0))
			info["stair_%d" % i] = names2
	# les cabanes d'habitation
	_hut("ouest", 0, 150.0, "porte_ouest_1")
	_hut("ouest", 0, 250.0, "porte_ouest_2")
	_hut("guet", 0, 330.0, "porte_guet_1")
	_hut("guet", 0, 45.0, "porte_guet_2")
	_hut("sud", 0, 30.0, "porte_sud_1")
	_hut("sud", 0, 230.0, "porte_sud_2")
	_hut("mares", 0, 120.0, "porte_mares_1")
	_hut("mares", 0, 220.0, "porte_mares_2")
	_hut("nord", 0, 220.0, "porte_nord_1")
	_hut("nord", 0, 20.0, "porte_nord_2")


## Une cabane ronde sur une plate-forme, la porte vers le tronc ; son point de porte.
## opts : r (rayon), h (hauteur des murs), rc (distance du centre au tronc), noren, lanterne.
func _hut(id: String, i: int, a: float, door: String, opts: Dictionary = {}) -> Vector3:
	var info: Dictionary = trees[id]
	var d: Dictionary = info["decks"][i]
	var base: Vector3 = info["base"]
	var r: float = float(opts.get("r", 2.0))
	var c: Vector3 = Kit.ring_pt(base, float(d["ri"]) + float(opts.get("rc", 5.7)), a, float(d["y"]))
	var to_trunk: Vector3 = (Vector3(base.x, c.y, base.z) - c).normalized()
	var dp: Vector3 = kit.round_hut(c, r, float(opts.get("h", 2.4)), to_trunk, opts)
	points[door] = dp
	_link(door, _deck_node(id, i, a))
	return dp


## Les chantiers de Pomme-de-Pin, la charpentière : une pile de planches et un chevalet sur la
## plate-forme de l'arbre de l'ouest, et au sol, près de la grande mare.
func _chantier() -> void:
	var o: Dictionary = trees["ouest"]
	var od: Dictionary = o["decks"][0]
	var ob: Vector3 = o["base"]
	var pxf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - 200.0)), Kit.ring_pt(ob, float(od["ri"]) + 5.4, 200.0, float(od["y"])))
	_planks(pxf)
	_spot_w("charpente_1", pxf * Vector3(0, 0, -1.3), pxf * Vector3(0, 0.5, 0), "bricoler", _deck_node("ouest", 0, 200.0))
	var gxf := Transform3D(Basis(Vector3.UP, PI * 0.5), G(-16.0, 4.0))
	_planks(gxf)
	_spot_l("charpente_2", -14.6, 4.0, -16.0, 4.0, "bricoler", "")


func _planks(xf: Transform3D) -> void:
	for k in range(5):
		kit.box(xf * Transform3D(Basis(Vector3.UP, (k % 2) * 0.06 - 0.03), Vector3(0, 0.07 + k * 0.1, 0.45)), Vector3(2.2, 0.08, 0.3), "planches_r", 1.0)
	for sx in [-0.7, 0.7]:
		kit.box(xf * Transform3D(Basis(), Vector3(sx, 0.35, -0.5)), Vector3(0.08, 0.7, 0.5), "poutre", 1.0)
	kit.box(xf * Transform3D(Basis(), Vector3(0, 0.72, -0.5)), Vector3(1.7, 0.1, 0.12), "rondins", 1.0)
	kit.col_box(xf * Transform3D(Basis(), Vector3(0, 0.38, 0.1)), Vector3(2.2, 0.76, 1.3))


# =================================================================== le Chêne-Mère

## Le Marché aux trocs, autour du tronc, sur la plate-forme du bas : quatre étals, des poteaux
## à lanternes le long du garde-corps.
func _market() -> void:
	var stalls := [[340.0, "toile_rouge", "bric", "troc"], [70.0, "toile_bleue", "fruits", "fruits"], [175.0, "toile_bleue", "poisson", "poisson"], [285.0, "toile_rouge", "cordes", "plumes"]]
	var info: Dictionary = trees["mere"]
	var base: Vector3 = info["base"]
	var d: Dictionary = info["decks"][0]
	var ri: float = float(d["ri"])
	var y: float = float(d["y"])
	var w: float = 3.0
	for k in range(stalls.size()):
		var st: Array = stalls[k]
		var a: float = float(st[0])
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - a)), Kit.ring_pt(base, ri + 4.0, a, y))
		kit.stall(xf, w, str(st[1]), str(st[2]))
		if str(st[3]) == "troc":
			kit.quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0.95, 1.45, -0.42)), 0.8, 0.8, "noren_troc", Vector2(0, 0), Vector2(1, 1), true)
		# le marchand passe par le côté de l'étal (pas à travers le comptoir)
		var ring: String = _deck_node("mere", 0, a)
		var side_a: String = "marche_%d_a" % k
		var side_b: String = "marche_%d_b" % k
		points[side_a] = xf * Vector3(w * 0.5 + 0.6, 0.0, -0.85)
		points[side_b] = xf * Vector3(w * 0.5 + 0.6, 0.0, 1.08)
		_link(ring, side_a)
		_link(side_a, side_b)
		_spot_w("marche_" + str(st[3]), xf * Vector3(0, 0.0, 1.08), xf * Vector3(0, 0, -2.0), "comptoir", side_b)
		_spot_w("marche_client_%d" % (k + 1), xf * Vector3(0.6, 0.0, -0.85), xf * Vector3(0.6, 0, 1.0), "debout", ring)
	for a2 in [10.0, 120.0, 210.0, 250.0]:
		var pp: Vector3 = Kit.ring_pt(base, ri + 7.2, a2, y)
		kit.lantern_post(pp, deg_to_rad(90.0 - a2) + PI, "papier_rouge" if int(a2) % 20 == 10 else "papier")
		kit.col_cyl(pp, 0.1, 2.6)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.72, 0.42)
	l.omni_range = 14.0
	l.light_energy = 0.0
	l.position = Kit.ring_pt(base, ri + 3.0, 0.0, y + 3.0)
	add_child(l)
	if main.get("temps_v56") != null and main.temps_v56 != null:
		main.temps_v56.register_lamp(l, 1.4)


## Le milieu du Chêne-Mère (l'échoppe des Simples, la maison de Mère-Lune), la cime (la Poste
## des chouettes), le haut du Guet (la vigie des loups, le départ de la tyrolienne).
func _upper_decks() -> void:
	var info: Dictionary = trees["mere"]
	var base: Vector3 = info["base"]
	var d1: Dictionary = info["decks"][1]
	var y1: float = float(d1["y"])
	var ri1: float = float(d1["ri"])
	_hut("mere", 1, 200.0, "porte_simples", {"noren": "noren_simples", "r": 2.2})
	_hut("mere", 1, 60.0, "porte_mere_lune", {"r": 2.1, "h": 2.6})
	# à côté de la porte des Simples : une table de bocaux, des bouquets d'herbes qui sèchent
	var txf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - 220.0)), Kit.ring_pt(base, ri1 + 3.3, 220.0, y1))
	kit.box(txf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.4, 0.9, 0.7), "planches_r", 1.0)
	kit.col_box(txf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.4, 0.9, 0.7))
	for sx in [-0.68, 0.68]:
		kit.box(txf * Transform3D(Basis(), Vector3(sx, 1.2, 0.3)), Vector3(0.07, 2.4, 0.07), "poutre", 1.0)
	kit.beam(txf * Vector3(-0.72, 2.3, 0.3), txf * Vector3(0.72, 2.3, 0.3), 0.06, "bambou")
	for j in range(4):
		kit.cyl(txf * Transform3D(Basis(), Vector3(-0.5 + j * 0.33, 0.9, -0.05)), 0.08, 0.07, 0.2, "verre", 8)
		kit.beam(txf * Vector3(-0.5 + j * 0.33, 2.28, 0.3), txf * Vector3(-0.5 + j * 0.33, 1.8, 0.3), 0.12, "fanes")
	points["simples_cote"] = Kit.ring_pt(base, ri1 + 3.9, 230.0, y1)
	_link("simples_cote", _deck_node("mere", 1, 235.0))
	_spot_w("simples_porte", txf * Vector3(0, 0, 0.85), txf * Vector3(0, 0, -2.0), "bricoler", "simples_cote")
	_spot_w("simples_client", txf * Vector3(0.3, 0, -0.95), txf * Vector3(0, 0, 1.0), "debout", _deck_node("mere", 1, 220.0))
	_spot_w("mere_lune_porte", Kit.ring_pt(base, ri1 + 3.0, 48.0, y1), Kit.ring_pt(base, ri1 + 8.0, 48.0, y1), "bras_croises", _deck_node("mere", 1, 48.0))
	# la cime : la Poste des chouettes, le pigeonnier, des lanternes, la vue
	var d2: Dictionary = info["decks"][2]
	var y2: float = float(d2["y"])
	var ri2: float = float(d2["ri"])
	_hut("mere", 2, 300.0, "porte_poste", {"noren": "noren_poste", "r": 1.8, "h": 2.2})
	var pxf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - 335.0)), Kit.ring_pt(base, ri2 + 4.3, 335.0, y2))
	kit.box(pxf * Transform3D(Basis(), Vector3(0, 0.55, 0)), Vector3(1.4, 1.1, 0.6), "planches_r", 1.0)
	kit.col_box(pxf * Transform3D(Basis(), Vector3(0, 0.95, 0)), Vector3(1.4, 1.9, 0.6))
	for row in range(3):
		for col in range(4):
			kit.box(pxf * Transform3D(Basis(), Vector3(-0.5 + col * 0.33, 1.25 + row * 0.3, 0.0)), Vector3(0.3, 0.28, 0.5), "rondins", 0.5)
	_spot_w("poste_guichet", pxf * Vector3(0, 0, -0.9), pxf * Vector3(0, 0, 2.0), "comptoir", _deck_node("mere", 2, 335.0))
	_spot_w("poste_vue", Kit.ring_pt(base, ri2 + 4.2, 160.0, y2), Kit.ring_pt(base, 40.0, 160.0, y2), "observer", _deck_node("mere", 2, 160.0))
	var la: Vector3 = Kit.ring_pt(base, ri2 + 4.6, 10.0, y2)
	var lb: Vector3 = Kit.ring_pt(base, ri2 + 4.6, 80.0, y2)
	for lp in [la, lb]:
		kit.cyl(Transform3D(Basis(), lp), 0.07, 0.06, 2.8, "bambou", 6)
		kit.col_cyl(lp, 0.1, 2.8)
	kit.lantern_string(la + Vector3.UP * 2.7, lb + Vector3.UP * 2.7, 0.5, 3, ["papier_bleu", "papier"])
	# le Guet : la vigie des loups, deux postes de veille, la plate-forme de la tyrolienne
	var g: Dictionary = trees["guet"]
	var gd: Dictionary = g["decks"][1]
	var gb: Vector3 = g["base"]
	var gy: float = float(gd["y"])
	_hut("guet", 1, 60.0, "porte_vigie", {"r": 1.6, "h": 2.1, "rc": 5.0})
	_spot_w("guet_vigie", Kit.ring_pt(gb, float(gd["ri"]) + 3.4, 150.0, gy), Kit.ring_pt(gb, 60.0, 150.0, gy), "observer", _deck_node("guet", 1, 150.0))
	_spot_w("guet_2", Kit.ring_pt(gb, float(gd["ri"]) + 3.4, 300.0, gy), Kit.ring_pt(gb, 60.0, 300.0, gy), "observer", _deck_node("guet", 1, 300.0))
	# la plate-forme de départ de la tyrolienne (avancée hors du plancher, fermée au bout)
	var z0: Vector3 = Kit.ring_pt(gb, float(gd["ro"]) - 0.3, ZIP_A, gy)
	var z1: Vector3 = Kit.ring_pt(gb, float(gd["ro"]) + 1.9, ZIP_A, gy)
	var zxf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - ZIP_A)), (z0 + z1) * 0.5)
	kit.box(zxf * Transform3D(Basis(), Vector3(0, -0.14, 0)), Vector3(1.8, 0.28, 2.2), "planches_r", 1.0)
	kit.col_box(zxf * Transform3D(Basis(), Vector3(0, -0.14, 0)), Vector3(1.8, 0.28, 2.2))
	for sx in [-0.9, 0.9]:
		for sz in [-1.05, 0.0, 1.05]:
			kit.box(zxf * Transform3D(Basis(), Vector3(sx, 0.5, sz)), Vector3(0.1, 1.0, 0.1), "poutre", 1.0)
		kit.beam(zxf * Vector3(sx, 1.0, -1.1), zxf * Vector3(sx, 1.0, 1.1), 0.08, "poutre")
		kit.col_box(zxf * Transform3D(Basis(), Vector3(sx, 0.6, 0.0)), Vector3(0.12, 1.2, 2.2))
	kit.beam(zxf * Vector3(-0.9, 1.0, 1.05), zxf * Vector3(0.9, 1.0, 1.05), 0.08, "poutre")
	kit.col_box(zxf * Transform3D(Basis(), Vector3(0, 0.6, 1.05)), Vector3(1.8, 1.2, 0.12))
	g["zip_start"] = zxf * Vector3(0, 0, 0.45)


# =================================================================== le sol du village

func _spot_l(name: String, x: float, z: float, fx: float, fz: float, pose: String, node: String, dy: float = 0.0) -> void:
	spots[name] = {"pos": G(x, z, dy), "face": G(fx, fz, dy), "pose": pose, "node": node}


func _spot_w(name: String, pos: Vector3, face: Vector3, pose: String, node: String) -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


## Le Cercle de la Lune : le feu, huit bancs de rondin, deux grands tambours (taiko), le siège
## de mousse de Mère-Lune, quatre mâts de bambou, leurs bannières et leurs guirlandes.
func _cercle() -> void:
	var c: Vector2 = R.CERCLE
	var cg: Vector3 = G(c.x, c.y)
	var at := func(r: float, a: float) -> Vector3: return G(c.x + cos(deg_to_rad(a)) * r, c.y + sin(deg_to_rad(a)) * r)
	_fire_at = kit.bonfire(cg)
	# huit points de passage à l'intérieur du cercle, dans les trouées entre les bancs (les
	# quatre des points cardinaux mènent aux allées) : on va s'asseoir sans enjamber les bancs
	for h in range(8):
		points["cercle_h%d" % h] = at.call(7.0, h * 45.0)
	for h2 in range(8):
		_link("cercle_h%d" % h2, "cercle_h%d" % ((h2 + 1) % 8))
	_link("cercle_h0", "g_cercle_e")
	_link("cercle_h2", "g_cercle_s")
	_link("cercle_h4", "g_cercle_w")
	_link("cercle_h6", "g_cercle_n")
	for k in range(8):
		var a: float = 22.5 + k * 45.0
		kit.log_bench(Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - a)), at.call(8.2, a)), 2.6)
	for k2 in range(8):
		var a2: float = 22.5 + (k2 % 4) * 90.0 + (45.0 if k2 >= 4 else 0.0)
		_spot_w("cercle_banc_%d" % (k2 + 1), at.call(7.85, a2), cg, "assis", "cercle_h%d" % (int(roundf((a2 + 22.5) / 45.0)) % 8))
	# les tambours au nord du cercle (on en joue debout), la flûte assise sur un billot
	for j in range(2):
		var a3: float = -100.0 + j * 22.0
		var txf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - a3)), at.call(5.6, a3))
		kit.taiko(txf, 0.5 + j * 0.08)
		_spot_w("cercle_tambour_%d" % (j + 1), at.call(6.55, a3), at.call(5.0, a3), "taiko", "cercle_h6")
	var fl: Vector3 = at.call(5.2, -60.0)
	kit.cyl(Transform3D(Basis(), fl + Vector3.DOWN * 0.05), 0.24, 0.27, 0.47, "poutre", 8)
	_spot_w("cercle_flute", fl, cg, "flute", "cercle_h7")
	# le siège de mousse de Mère-Lune, à l'ouest
	var ms: Vector3 = at.call(5.7, 175.0)
	kit.cyl(Transform3D(Basis(), ms + Vector3.DOWN * 0.05), 0.7, 0.8, 0.5, "mousse", 12)
	kit.col_cyl(ms, 0.75, 0.45)
	_spot_w("cercle_mere", at.call(4.85, 175.0), cg, "assis", "cercle_h3")
	var dance_hub := [0, 2, 3, 4, 5, 7]
	for k4 in range(6):
		var a4: float = k4 * 60.0 + 15.0
		_spot_w("cercle_danse_%d" % (k4 + 1), at.call(3.8, a4), cg, "danse", "cercle_h%d" % dance_hub[k4])
	_spot_l("cercle_enfants_1", c.x + 11.5, c.y - 6.0, c.x, c.y, "jouer", "")
	_spot_l("cercle_enfants_2", c.x + 12.0, c.y + 5.0, c.x, c.y, "jouer", "")
	# quatre mâts de bambou (en diagonale, loin des allées et de la course), deux bannières,
	# des guirlandes de lanternes d'un mât à l'autre et en croix au-dessus du feu
	var tops: Array = []
	for m in range(4):
		var am: float = 45.0 + m * 90.0
		var mp: Vector3 = at.call(11.0, am)
		kit.cyl(Transform3D(Basis(), mp + Vector3.DOWN * 0.3), 0.13, 0.09, 6.6, "bambou", 8)
		kit.col_cyl(mp, 0.15, 6.0)
		tops.append(mp + Vector3.UP * 6.0)
		if m % 2 == 0:
			var out := Vector3(cos(deg_to_rad(am)), 0, sin(deg_to_rad(am)))
			kit.quad(Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - am)), mp + Vector3.UP * 3.6 + out * 0.16), 1.0, 2.5, "banniere_lune", Vector2(0, 0), Vector2(1, 1), true)
	for m2 in range(4):
		kit.lantern_string(tops[m2], tops[(m2 + 1) % 4], 1.0, 3, ["papier_rouge", "papier"])
	kit.lantern_string(tops[0], tops[2], 1.6, 6, ["papier", "papier_rouge", "papier_bleu"])
	kit.lantern_string(tops[1], tops[3], 1.6, 6, ["papier_bleu", "papier", "papier_rouge"])
	# la lumière du feu, les lumières de la fête
	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.58, 0.25)
	_fire_light.omni_range = 18.0
	_fire_light.light_energy = 0.0
	_fire_light.position = _fire_at + Vector3.UP * 1.2
	add_child(_fire_light)
	for q in range(2):
		var fl2 := OmniLight3D.new()
		fl2.light_color = Color(1.0, 0.75, 0.5)
		fl2.omni_range = 16.0
		fl2.light_energy = 0.0
		fl2.position = G(c.x + (q * 2 - 1) * 6.0, c.y) + Vector3.UP * 5.5
		add_child(fl2)
		_fete_lights.append(fl2)
	# la musique de la fête (les tambours et la flûte jouent pour de vrai)
	_music = AudioStreamPlayer3D.new()
	_music.name = "Musique_fete_lune"
	var path: String = "res://assets/sons/musique/ramure_fete.ogg"
	if ResourceLoader.exists(path):
		var stream: Variant = load(path)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_music.stream = stream
	_music.max_distance = 75.0
	_music.unit_size = 14.0
	_music.volume_db = -4.0
	_music.bus = "Musique" if AudioServer.get_bus_index("Musique") >= 0 else "Master"
	_music.position = at.call(5.5, -90.0) + Vector3.UP * 1.6
	add_child(_music)


## La boulangerie des lapins (cabane ronde, four à pain, comptoir) et leur potager.
func _boulangerie() -> void:
	var c: Vector3 = G(-8.0, -34.0)
	var door: Vector3 = kit.round_hut(c, 3.0, 2.6, Vector3(1, 0, 0), {"noren": "noren_boulangerie", "toit_h": 3.2})
	points["porte_boulangerie"] = door
	# le four (une coupole de pierre) et sa cheminée qui fume
	var ov: Vector3 = G(-8.0, -27.0)
	kit.cyl(Transform3D(Basis(), ov), 1.3, 1.3, 0.6, "brique", 14)
	kit.cyl(Transform3D(Basis(), ov + Vector3.UP * 0.6), 1.3, 0.4, 1.3, "brique", 14)
	kit.box(Transform3D(Basis(), ov + Vector3(1.15, 0.7, 0)), Vector3(0.3, 0.6, 0.7), "cendre", 1.0)
	kit.col_cyl(ov, 1.35, 1.9)
	_steam(ov + Vector3.UP * 2.0, false)
	_spot_l("boul_four", -5.8, -27.0, -8.0, -27.0, "bricoler", "")
	# le comptoir au nord de la porte (des pains, des gâteaux de lune) : la boulangère côté
	# cabane, les clients côté allée
	var cxf := Transform3D(Basis(Vector3.UP, PI * 0.5), G(-2.5, -36.4))
	kit.box(cxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.2, 0.9, 0.7), "planches_r", 1.0)
	kit.col_box(cxf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.2, 0.9, 0.7))
	for j in range(5):
		kit.cyl(cxf * Transform3D(Basis(), Vector3(-0.8 + j * 0.4, 0.9, 0)), 0.14, 0.1, 0.12, "carotte" if j % 2 else "bois", 10)
	_spot_l("boul_comptoir", -3.3, -36.4, -1.0, -36.4, "comptoir", "porte_boulangerie")
	_spot_l("boul_client", -1.6, -36.1, -4.0, -36.4, "debout", "g_boul")
	# le potager : six rangs de carottes
	for r in range(6):
		kit.carrot_row(G(-17.0, -26.0 + r * 1.0, 0.0), G(-11.0, -26.0 + r * 1.0, 0.0))
	_spot_l("jardin_1", -14.0, -27.2, -14.0, -24.0, "bricoler", "g_boul")
	_spot_l("jardin_2", -10.2, -22.0, -14.0, -22.0, "bricoler", "")


func _forge() -> void:
	var c: Vector3 = G(50.0, 40.0)
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(-60.0)), c)
	for sx in [-2.6, 2.6]:
		for sz in [-2.0, 2.0]:
			kit.cyl(xf * Transform3D(Basis(), Vector3(sx, 0, sz)), 0.18, 0.18, 3.2, "poutre", 8)
			kit.col_cyl(xf * Vector3(sx, 0, sz), 0.2, 3.2)
	kit.roof_gable(xf * Transform3D(Basis(), Vector3(0, 3.2, 0)), 6.0, 5.0, 28.0, 0.5, "chaume_r", "rondins")
	var hearth: Vector3 = xf * Vector3(-1.2, 0, 1.0)
	kit.box(Transform3D(xf.basis, hearth + Vector3.UP * 0.5), Vector3(1.6, 1.0, 1.2), "pierre", 1.0)
	kit.col_box(Transform3D(xf.basis, hearth + Vector3.UP * 0.5), Vector3(1.6, 1.0, 1.2))
	kit.box(Transform3D(xf.basis, hearth + Vector3.UP * 1.02), Vector3(1.0, 0.06, 0.7), "feu", 1.0)
	_steam(hearth + Vector3.UP * 3.6, true)
	var anvil: Vector3 = xf * Vector3(1.0, 0, 0.2)
	kit.cyl(Transform3D(Basis(), anvil), 0.35, 0.4, 0.6, "poutre", 10)
	kit.box(Transform3D(xf.basis, anvil + Vector3.UP * 0.75), Vector3(0.7, 0.3, 0.3), "fer_r", 1.0)
	kit.col_cyl(anvil, 0.45, 0.9)
	_spot_w("forge_enclume", xf * Vector3(1.0, 0, -0.8), anvil, "bricoler", "")
	_spot_w("forge_soufflet", xf * Vector3(-1.2, 0, -0.4), hearth, "bricoler", "")
	_spot_w("forge_client", xf * Vector3(0.0, 0, -3.4), xf * Vector3(0, 0, 0), "debout", "")
	kit.quad(Transform3D(xf.basis, xf * Vector3(2.65, 2.2, -2.1)) * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO), 1.2, 1.2, "noren_forge", Vector2(0, 0), Vector2(1, 1), true)
	_forge_light = OmniLight3D.new()
	_forge_light.light_color = Color(1.0, 0.5, 0.2)
	_forge_light.omni_range = 9.0
	_forge_light.light_energy = 1.2
	_forge_light.position = hearth + Vector3.UP * 1.4
	add_child(_forge_light)


## La pêcherie des chats : un ponton sur la grande mare, leur cabane, l'étal de poissons.
func _pecherie() -> void:
	var a: Vector3 = G(-5.0, 24.0)
	var b: Vector3 = R.to_world(-15.5, 24.0)
	var y: float = a.y + 0.1
	var mid := Vector3((a.x + b.x) * 0.5, y, (a.z + b.z) * 0.5)
	kit.box(Transform3D(Basis(), mid + Vector3.DOWN * 0.1), Vector3(a.distance_to(Vector3(b.x, a.y, b.z)), 0.2, 1.8), "planches_r", 1.0)
	kit.col_box(Transform3D(Basis(), mid + Vector3.DOWN * 0.1), Vector3(a.distance_to(Vector3(b.x, a.y, b.z)), 0.2, 1.8))
	for k in range(5):
		var px: float = lerpf(a.x, b.x, float(k) / 4.0)
		for sz in [-0.8, 0.8]:
			kit.cyl(Transform3D(Basis(), Vector3(px, y - 2.0, a.z + sz)), 0.1, 0.1, 2.0, "poutre", 6)
	points["ponton_peche"] = Vector3(lerpf(a.x, b.x, 0.5), y, a.z)
	points["ponton_peche_bout"] = Vector3(lerpf(a.x, b.x, 0.9), y, a.z)
	_spot_w("peche_1", Vector3(lerpf(a.x, b.x, 0.95), y, a.z - 0.55), Vector3(b.x - 6.0, y, a.z - 0.5), "pecher", "ponton_peche_bout")
	_spot_w("peche_2", Vector3(lerpf(a.x, b.x, 0.7), y, a.z + 0.6), Vector3(lerpf(a.x, b.x, 0.7), y, a.z + 6.0), "pecher", "ponton_peche")
	# la cabane des chats et son étal
	var hc: Vector3 = G(-12.0, 38.0)
	var door: Vector3 = kit.round_hut(hc, 2.4, 2.4, Vector3(1, 0, 0), {"noren": "noren_peche"})
	points["porte_pecherie"] = door
	var sxf := Transform3D(Basis(Vector3.UP, PI * 0.5), door + Vector3(0.8, 0, -2.4))
	kit.stall(sxf, 2.4, "toile_bleue", "poisson")
	points["peche_etal_b"] = sxf * Vector3(0, 0, 2.8)
	_link("peche_etal_b", "g_chat")
	_spot_w("peche_etal", sxf * Vector3(0, 0, 1.1), sxf * Vector3(0, 0, -2.0), "comptoir", "peche_etal_b")
	_spot_w("peche_client", sxf * Vector3(0.4, 0, -0.9), sxf * Vector3(0, 0, 1.0), "debout", "")


## La Clairière des Jeux : l'arche du départ, le tableau des records, des bancs ; les arches
## de lanternes de la Grande Course.
func _jeux() -> void:
	var n: int = R.COURSE.size()
	for i in range(n):
		var p: Vector2 = R.COURSE[i]
		var prev: Vector2 = R.COURSE[(i - 1 + n) % n]
		var nxt: Vector2 = R.COURSE[(i + 1) % n]
		var dir: Vector2 = (nxt - prev).normalized()
		var g: Vector3 = G(p.x, p.y)
		kit.race_arch(g, atan2(dir.x, dir.y) + PI * 0.5, 5.2 if i == 0 else 4.4)
		_checkpoints.append(g)
	var j: Vector2 = R.JEUX
	var arch: Vector3 = G(j.x, j.y)
	var facing := func(px: float, pz: float) -> Transform3D:
		var gp: Vector3 = G(px, pz)
		var d: Vector3 = arch - gp
		return Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), gp)
	# le tableau des records, tourné vers la clairière
	var rxf: Transform3D = facing.call(22.0, -43.0)
	for sx in [-1.1, 1.1]:
		kit.cyl(rxf * Transform3D(Basis(), Vector3(sx, 0, 0)), 0.1, 0.1, 2.6, "poutre", 6)
	kit.quad(rxf * Transform3D(Basis(), Vector3(0, 1.9, 0.07)), 2.4, 1.8, "records", Vector2(0, 0), Vector2(1, 1), true)
	kit.col_box(rxf * Transform3D(Basis(), Vector3(0, 1.3, 0)), Vector3(2.4, 2.6, 0.2))
	_spot_w("jeux_records", rxf * Vector3(0, 0, 1.6), rxf * Vector3(0, 1.0, 0), "observer", "")
	for k in range(2):
		var bxf: Transform3D = facing.call(16.5 + k * 3.3, -40.5 + k * 1.3)
		kit.log_bench(bxf, 2.4)
		_spot_w("jeux_banc_%d" % (k + 1), bxf * Vector3(0, 0, 0.12), arch, "assis", "")
	_spot_l("jeux_depart", 19.5, -35.5, j.x, j.y, "crier", "")
	_spot_l("jeux_enfants_1", 9.0, -30.0, 8.0, -36.0, "jouer", "")
	_spot_l("jeux_enfants_2", 8.0, -36.0, 9.0, -30.0, "jouer", "")
	for k2 in range(3):
		_spot_l("jeux_echauffement_%d" % (k2 + 1), 12.0 + k2 * 2.0, -28.5 + k2 * 1.0, j.x, j.y, "bras_croises" if k2 != 1 else "debout", "")
	# l'arrivée de la tyrolienne : une botte de paille au pied
	var zs: Vector3 = G(ZIP_END.x, ZIP_END.y)
	kit.cyl(Transform3D(Basis(), zs + Vector3(0.9, 0, 0.9)), 0.5, 0.5, 0.9, "chaume_r", 10)


## L'aire du Zéphyr : un plancher rond, le mât d'amarrage et ses lanternes.
func _aire() -> void:
	var c: Vector3 = Vector3(PAD.x, ile.height(PAD.x, PAD.z), PAD.z)
	kit.cyl(Transform3D(Basis(), c + Vector3.DOWN * 0.3), 11.5, 11.5, 0.42, "planches_r", 32)
	kit.col_cyl(c + Vector3.DOWN * 0.3, 11.5, 0.42)
	kit.ring(Transform3D(Basis(), c + Vector3.UP * 0.12), 10.8, 11.5, 0.06, "laque_rouge", 48)
	var mp: Vector3 = c + Vector3(-15.0, 0, 0)
	mp.y = ile.height(mp.x, mp.z)
	kit.cyl(Transform3D(Basis(), mp), 0.35, 0.25, 15.0, "bambou", 10)
	kit.col_cyl(mp, 0.4, 15.0)
	for k in range(4):
		kit.paper_lantern(mp + Vector3(0, 4.0 + k * 3.0, 0.5), 0.9, "papier_rouge" if k % 2 else "papier")
	var loc: Vector2 = R.to_local(c.x, c.z)
	_spot_l("aire_zephyr", loc.x + 3.0, loc.y + 13.5, loc.x, loc.y, "bras_croises", "")


func _ponton() -> void:
	boat_dock = [R.to_world(R.DOCK.x, R.DOCK.y, -0.2), R.to_world(R.DOCK.x + 15.0, R.DOCK.y, -0.2)]
	_spot_l("ponton_1", R.DOCK.x - 4.0, R.DOCK.y + 1.5, R.DOCK.x + 10.0, R.DOCK.y, "observer", "")


## Des lanternes sur poteaux le long des allées (à 1,7 m du bord du chemin, d'un côté puis de
## l'autre).
const LANTERN_EDGES := [["g_mere_n", "g_jeux", 0.5, 1.0], ["g_jeux", "g_est1", 0.35, -1.0], ["g_est1", "g_guet_sp", 0.5, 1.0], ["g_est2", "g_dock1", 0.5, 1.0],
	["g_dock1", "g_dock2", 0.5, -1.0], ["g_dock2", "g_dock", 0.6, 1.0], ["g_est2", "g_forge", 0.55, -1.0], ["g_cercle_n", "g_lift", 0.45, 1.0],
	["g_cercle_w", "g_ouest", 0.55, -1.0], ["g_cercle_s", "g_chat", 0.5, -1.0], ["g_jardin", "g_boul", 0.4, 1.0], ["g_ouest", "g_jardin", 0.5, -1.0],
	["g_nord", "g_nord_w", 0.5, 1.0], ["g_nord_w", "g_pad", 0.5, -1.0], ["g_jeux", "g_nord", 0.75, -1.0], ["g_cercle_e", "g_forge", 0.5, 1.0],
	["g_mere_n", "g_boul", 0.5, -1.0], ["g_mere_e", "g_cercle_n", 0.5, 1.0]]


func _paths_lanterns() -> void:
	for i in range(LANTERN_EDGES.size()):
		var e: Array = LANTERN_EDGES[i]
		var a: Vector2 = GROUND[e[0]]
		var b: Vector2 = GROUND[e[1]]
		var d: Vector2 = (b - a).normalized()
		var side := Vector2(-d.y, d.x) * float(e[3])
		var q: Vector2 = a.lerp(b, float(e[2])) + side * 1.7
		var pp: Vector3 = G(q.x, q.y)
		kit.lantern_post(pp, atan2(-side.x, -side.y), "papier" if i % 3 else "papier_rouge")
		kit.col_cyl(pp, 0.08, 2.6)


func _undergrowth() -> void:
	var ferns := MultiMesh.new()
	ferns.transform_format = MultiMesh.TRANSFORM_3D
	ferns.mesh = Flora.fern_clump()
	var xfs: Array = []
	var tries: int = 0
	while xfs.size() < (720 if pc else 280) and tries < 9000:
		tries += 1
		var x: float = _rng.randf_range(-42.0, 58.0)
		var z: float = _rng.randf_range(-110.0, 70.0)
		if not _clear(x, z, 1.6):
			continue
		var g: Vector3 = G(x, z)
		xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.6)), g + Vector3.DOWN * 0.05))
	ferns.instance_count = xfs.size()
	for i in range(xfs.size()):
		ferns.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Fougeres_ramure"
	mmi.multimesh = ferns
	mmi.visibility_range_end = 160.0
	add_child(mmi)
	# l'herbe haute et la mousse entre les allées
	var grass := MultiMesh.new()
	grass.transform_format = MultiMesh.TRANSFORM_3D
	grass.mesh = Flora.grass_clump(14, 0.45, 0.05, 62)
	var gx: Array = []
	tries = 0
	while gx.size() < (1600 if pc else 600) and tries < 16000:
		tries += 1
		var x3: float = _rng.randf_range(-42.0, 60.0)
		var z3: float = _rng.randf_range(-110.0, 70.0)
		if not _clear(x3, z3, 1.1):
			continue
		gx.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.5)), G(x3, z3, -0.03)))
	grass.instance_count = gx.size()
	for i4 in range(gx.size()):
		grass.set_instance_transform(i4, gx[i4])
	var gmi := MultiMeshInstance3D.new()
	gmi.name = "Herbes_ramure"
	gmi.multimesh = grass
	gmi.visibility_range_end = 90.0
	gmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(gmi)
	# des feuillus de la forêt entre les grands arbres (loin des plates-formes, des ponts, des
	# allées, de la course, de la tyrolienne et de l'aire du Zéphyr)
	var tree_xf: Array = [[], [], []]
	var want: int = 46 if pc else 24
	var placed: int = 0
	tries = 0
	while placed < want and tries < 3000:
		tries += 1
		var x2: float = _rng.randf_range(-40.0, 58.0)
		var z2: float = _rng.randf_range(-108.0, 70.0)
		if not _clear(x2, z2, 3.5) or not _clear_forest(x2, z2):
			continue
		var g2: Vector3 = G(x2, z2)
		tree_xf[placed % 3].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.3)), g2 + Vector3.DOWN * 0.2))
		placed += 1
	for v in range(3):
		if (tree_xf[v] as Array).is_empty():
			continue
		var tm := MultiMesh.new()
		tm.transform_format = MultiMesh.TRANSFORM_3D
		tm.mesh = Flora.tree(5960 + v, 12.0 + v * 2.0, 320)
		tm.instance_count = (tree_xf[v] as Array).size()
		for i3 in range(tm.instance_count):
			tm.set_instance_transform(i3, tree_xf[v][i3])
		var tmi := MultiMeshInstance3D.new()
		tmi.name = "Feuillus_ramure_%d" % v
		tmi.multimesh = tm
		tmi.visibility_range_end = 700.0
		add_child(tmi)
	# les champignons géants : rouges le long des allées, « lune » au bord des mares
	var m := [[-30.0, -8.0, true], [-36.0, 36.0, true], [24.0, -46.0, true], [-10.0, 66.0, true], [-28.0, -70.0, true],
		[40.0, -50.0, false], [-36.0, -46.0, false], [34.0, 54.0, false], [-12.0, 56.0, false], [52.0, 22.0, false]]
	for mu in m:
		var g2: Vector3 = G(float(mu[0]), float(mu[1]))
		kit.big_mushroom(g2, _rng.randf_range(0.9, 1.6), _rng.randf_range(0.5, 0.9), bool(mu[2]))
		kit.col_cyl(g2, 0.25, 1.0)
	# les champignons de lune de la quête de Mère-Lune (à ramasser), au bord des mares
	var champis := [[-20.0, 37.5], [36.0, -46.5], [-40.0, -7.0], [2.0, 64.5], [-14.0, -69.5]]
	for i2 in range(champis.size()):
		var cp: Array = champis[i2]
		objets["champi_lune_%d" % (i2 + 1)] = G(float(cp[0]), float(cp[1]), 0.1)


## Une allée, un banc, un arbre… : le point (x, z) du village est-il libre (fougères) ?
func _clear(x: float, z: float, margin: float) -> bool:
	var p := Vector2(x, z)
	for pd in R.PONDS:
		if p.distance_to(Vector2(float(pd[0]), float(pd[1]))) < float(pd[2]) + 0.5:
			return false
	for t in R.TREES:
		if p.distance_to(Vector2(float(t["x"]), float(t["z"]))) < float(t["r"]) + 3.5:
			return false
	if p.distance_to(R.CERCLE) < R.CERCLE_R + 3.0 or p.distance_to(R.JEUX) < 12.0:
		return false
	for f in [Vector2(-8.0, -34.0), Vector2(-14.0, -24.0), Vector2(50.0, 40.0), Vector2(-12.0, 38.0), Vector2(-8.0, -27.0)]:
		if p.distance_to(f) < 6.0:
			return false
	# les allées (les arêtes du graphe au sol) et la course
	var n: int = R.COURSE.size()
	for i in range(n):
		if _seg_dist(p, R.COURSE[i], R.COURSE[(i + 1) % n]) < margin + 1.5:
			return false
	for e in GROUND_EDGES:
		var a: Vector2 = GROUND[e[0]]
		var b: Vector2 = GROUND[e[1]]
		if _seg_dist(p, a, b) < margin:
			return false
	return true


## Un feuillu peut-il pousser là ? (sa couronne ne touche ni les plates-formes, ni les ponts,
## ni la tyrolienne, ni l'aire du Zéphyr)
func _clear_forest(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	for t in R.TREES:
		if p.distance_to(Vector2(float(t["x"]), float(t["z"]))) < float(t["r"]) + 15.0:
			return false
	for br in R.BRIDGES:
		var a: Dictionary = R.tree(str(br[0]))
		var b: Dictionary = R.tree(str(br[1]))
		if _seg_dist(p, Vector2(float(a["x"]), float(a["z"])), Vector2(float(b["x"]), float(b["z"]))) < 7.0:
			return false
	var gt: Dictionary = R.tree("guet")
	var zs := Vector2(float(gt["x"]), float(gt["z"]))
	if _seg_dist(p, zs, ZIP_END) < 6.0:
		return false
	var pad: Vector2 = R.to_local(PAD.x, PAD.z)
	if p.distance_to(pad) < 19.0 or p.distance_to(Vector2(pad.x - 15.0, pad.y)) < 5.0:
		return false
	if p.distance_to(Vector2(-16.0, 4.0)) < 4.0:
		return false
	return true


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# =================================================================== la nacelle, la tyrolienne

func _rides() -> void:
	var info: Dictionary = trees["mere"]
	var base: Vector3 = info["base"]
	var d2: Dictionary = info["decks"][2]
	var shaft_r: float = float(info["decks"][0]["ro"]) + 1.25
	var low: Vector3 = Kit.ring_pt(base, shaft_r, LIFT_A, 0.0)
	low.y = ile.height(low.x, low.z) + 0.05
	var high: Vector3 = Kit.ring_pt(base, shaft_r, LIFT_A, float(d2["y"]))
	# le palier de la cime, du plancher jusqu'à la nacelle
	var l0: Vector3 = Kit.ring_pt(base, float(d2["ro"]) - 0.3, LIFT_A, float(d2["y"]))
	var l1: Vector3 = Kit.ring_pt(base, shaft_r - 0.95, LIFT_A, float(d2["y"]))
	var lxf := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - LIFT_A)), (l0 + l1) * 0.5 + Vector3.DOWN * 0.14)
	var ll: float = l0.distance_to(l1) + 0.2
	kit.box(lxf, Vector3(1.8, 0.28, ll), "planches_r", 1.0)
	for sx in [-0.95, 0.95]:
		kit.col_box(Transform3D(lxf.basis, lxf * Vector3(sx, 0.7, 0)), Vector3(0.12, 1.2, ll))
		kit.beam(lxf * Vector3(sx, 0.1, -ll * 0.5), lxf * Vector3(sx, 1.1, -ll * 0.5), 0.08, "poutre")
	kit.col_box(lxf, Vector3(1.8, 0.28, ll))
	kit.commit()
	lift = Nacelle.new()
	lift.name = "Nacelle_chene_mere"
	add_child(lift)
	var out_low: Vector3 = Kit.ring_pt(base, shaft_r + 2.4, LIFT_A, 0.0)
	out_low.y = ile.height(out_low.x, out_low.z)
	lift.setup(main, "ascenseur", low, high, out_low, Kit.ring_pt(base, float(d2["ri"]) + 2.6, LIFT_A, float(d2["y"])))
	points["nacelle_bas"] = out_low
	points["nacelle_haut"] = Kit.ring_pt(base, float(d2["ri"]) + 2.6, LIFT_A, float(d2["y"]))
	_link("nacelle_haut", _deck_node("mere", 2, LIFT_A))
	var bo: Vector3 = Kit.ring_pt(base, shaft_r + 3.4, LIFT_A - 18.0, 0.0)
	_spot_l("ascenseur", R.to_local(bo.x, bo.z).x, R.to_local(bo.x, bo.z).y, R.to_local(low.x, low.z).x, R.to_local(low.x, low.z).y, "bras_croises", "nacelle_bas")
	# la tyrolienne
	zip = Nacelle.new()
	zip.name = "Tyrolienne_guet"
	add_child(zip)
	var zstart: Vector3 = trees["guet"]["zip_start"]
	var zend: Vector3 = G(ZIP_END.x, ZIP_END.y)
	var away: Vector3 = (zend - zstart) * Vector3(1, 0, 1)
	var g: Dictionary = trees["guet"]
	var gd: Dictionary = g["decks"][1]
	zip.setup(main, "tyrolienne", zend, zstart, zend + away.normalized() * 2.5, Kit.ring_pt(g["base"], float(gd["ri"]) + 2.6, ZIP_A, float(gd["y"])))


# =================================================================== feu, lucioles, brume

func _particles(kind: String, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	var qm := QuadMesh.new()
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	m.albedo_texture = tex
	match kind:
		"flamme":
			m.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			qm.size = Vector2(0.7, 0.9)
		"luciole":
			m.albedo_color = Color(0.85, 1.0, 0.45, 1.0)
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			qm.size = Vector2(0.09, 0.09)
		"brume":
			m.albedo_color = Color(0.86, 0.9, 0.92, 0.12)
			qm.size = Vector2(9.0, 4.0)
		_:
			m.albedo_color = Color(0.85, 0.85, 0.85, 0.3)
			qm.size = Vector2(1.0, 1.0)
	qm.material = m
	p.mesh = qm
	add_child(p)
	return p


func _steam(at: Vector3, big: bool) -> void:
	var p := _particles("fumee", at)
	p.amount = (14 if big else 9) if pc else 5
	p.lifetime = 5.0
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.0
	p.gravity = Vector3(0.25, 0.12, 0.1)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.6


func _fx() -> void:
	# le feu du Cercle (allumé la nuit) : flammes, étincelles
	var f := _particles("flamme", _fire_at)
	f.amount = 26 if pc else 14
	f.lifetime = 0.9
	f.direction = Vector3.UP
	f.spread = 18.0
	f.initial_velocity_min = 1.2
	f.initial_velocity_max = 2.4
	f.gravity = Vector3(0, 0.6, 0)
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.45
	f.scale_amount_min = 0.6
	f.scale_amount_max = 1.4
	f.emitting = false
	var sp := _particles("luciole", _fire_at + Vector3.UP * 0.6)
	sp.amount = 18
	sp.lifetime = 2.0
	sp.direction = Vector3.UP
	sp.spread = 25.0
	sp.initial_velocity_min = 2.0
	sp.initial_velocity_max = 4.0
	sp.gravity = Vector3(0, -0.4, 0)
	(sp.mesh as QuadMesh).material = (sp.mesh as QuadMesh).material.duplicate()
	((sp.mesh as QuadMesh).material as StandardMaterial3D).albedo_color = Color(1.0, 0.55, 0.2)
	sp.emitting = false
	_fire_fx = [f, sp]
	# les lucioles : au-dessus des mares, la nuit
	var spots_ff: Array = []
	for pd in R.PONDS:
		spots_ff.append(Vector2(float(pd[0]), float(pd[1])))
	for c in spots_ff:
		var w: Vector3 = R.to_world(c.x, c.y)
		var gy: float = ile.height(w.x, w.z)
		var ff := _particles("luciole", Vector3(w.x, maxf(gy, 1.0) + 1.4, w.z))
		ff.amount = 40 if pc else 18
		ff.lifetime = 6.0
		ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		ff.emission_box_extents = Vector3(10.0, 1.2, 10.0)
		ff.direction = Vector3.UP
		ff.spread = 180.0
		ff.initial_velocity_min = 0.1
		ff.initial_velocity_max = 0.4
		ff.gravity = Vector3.ZERO
		ff.emitting = false
		_fireflies.append(ff)
	# la brume au ras du sol (le matin surtout)
	for k in range(6 if pc else 3):
		var mx: float = _rng.randf_range(-30.0, 45.0)
		var mz: float = _rng.randf_range(-70.0, 60.0)
		var mw: Vector3 = R.to_world(mx, mz)
		var mi := _particles("brume", Vector3(mw.x, ile.height(mw.x, mw.z) + 1.0, mw.z))
		mi.amount = 8 if pc else 4
		mi.lifetime = 16.0
		mi.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		mi.emission_box_extents = Vector3(14.0, 0.4, 14.0)
		mi.direction = Vector3(1, 0, 0.3)
		mi.spread = 40.0
		mi.initial_velocity_min = 0.2
		mi.initial_velocity_max = 0.5
		mi.gravity = Vector3.ZERO
		_mist.append(mi)


# =================================================================== les gens : lieux et chemins

func _link(a: String, b: String) -> void:
	if a == "" or b == "" or a == b:
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
		_link(names[i], names[i + 1])


## Les allées au sol (repère village) : elles évitent les mares, les racines et les bancs.
const GROUND := {
	"g_mere_n": Vector2(6.0, -22.0), "g_mere_sp": Vector2(4.6, -15.0), "g_mere_e": Vector2(18.0, -6.0),
	"g_jeux": Vector2(13.0, -25.0), "g_nord": Vector2(11.0, -50.0), "g_nord_sp": Vector2(18.7, -58.1), "g_nord_w": Vector2(6.0, -66.0), "g_pad": Vector2(20.0, -86.0),
	"g_est1": Vector2(36.0, -16.0), "g_guet_sp": Vector2(39.9, 5.25), "g_est2": Vector2(46.0, 6.0),
	"g_dock1": Vector2(60.0, 4.0), "g_dock2": Vector2(76.0, 3.0), "g_dock": Vector2(84.0, 2.0),
	"g_forge": Vector2(44.0, 34.0), "g_lift": Vector2(1.0, 7.5),
	"g_cercle_n": Vector2(8.0, 7.0), "g_cercle_e": Vector2(21.0, 20.0), "g_cercle_s": Vector2(8.0, 33.0), "g_cercle_w": Vector2(-5.0, 20.0),
	"g_peche": Vector2(-4.5, 24.0), "g_chat": Vector2(-6.0, 39.0), "g_sud_sp": Vector2(8.4, 38.65),
	"g_ouest": Vector2(-6.0, 2.0), "g_jardin": Vector2(-12.0, -14.0), "g_boul": Vector2(-1.5, -32.0),
}
const GROUND_EDGES := [["g_mere_n", "g_mere_sp"], ["g_mere_n", "g_jeux"], ["g_mere_n", "g_boul"], ["g_mere_n", "g_mere_e"],
	["g_jeux", "g_nord"], ["g_jeux", "g_est1"], ["g_nord", "g_nord_sp"], ["g_nord", "g_nord_w"], ["g_nord_w", "g_pad"], ["g_est1", "g_mere_e"], ["g_est1", "g_guet_sp"],
	["g_guet_sp", "g_est2"], ["g_est2", "g_dock1"], ["g_dock1", "g_dock2"], ["g_dock2", "g_dock"], ["g_est2", "g_forge"],
	["g_cercle_e", "g_forge"], ["g_cercle_n", "g_lift"], ["g_cercle_n", "g_mere_e"], ["g_cercle_n", "g_cercle_e"], ["g_cercle_e", "g_cercle_s"],
	["g_cercle_s", "g_cercle_w"], ["g_cercle_w", "g_cercle_n"], ["g_cercle_w", "g_peche"], ["g_cercle_s", "g_chat"], ["g_cercle_s", "g_sud_sp"],
	["g_cercle_w", "g_ouest"], ["g_ouest", "g_jardin"], ["g_jardin", "g_boul"], ["g_lift", "g_ouest"]]


func _graph() -> void:
	for k in GROUND:
		var v: Vector2 = GROUND[k]
		points[k] = G(v.x, v.y)
	for e in GROUND_EDGES:
		_link(str(e[0]), str(e[1]))
	# les pieds des escaliers
	_link("g_mere_sp", str(trees["mere"]["stair_0"][0]))
	_link("g_guet_sp", str(trees["guet"]["stair_0"][0]))
	_link("g_sud_sp", str(trees["sud"]["stair_0"][0]))
	_link("g_nord_sp", str(trees["nord"]["stair_0"][0]))
	# les étages du Chêne-Mère et du Guet : le haut d'une volée, le bas de la suivante
	for id in ["mere", "guet"]:
		var info: Dictionary = trees[id]
		for i in range(1, (info["spiral"] as Array).size()):
			_link(str(info["stair_%d" % (i - 1)][(info["stair_%d" % (i - 1)] as Array).size() - 1]), str(info["stair_%d" % i][0]))
	# la nacelle (en bas), la pêcherie, la boulangerie, la cabane des chats
	_link("nacelle_bas", "g_lift")
	_link("ponton_peche", "g_peche")
	_link("ponton_peche_bout", "ponton_peche")
	_link("porte_boulangerie", "g_boul")
	_link("porte_pecherie", "g_chat")
	# chaque lieu d'activité a son point « @nom »
	for s in spots:
		var nm: String = "@" + str(s)
		points[nm] = spots[s]["pos"]
		var near: String = str(spots[s]["node"])
		if near == "" or not points.has(near):
			near = _nearest_ground(spots[s]["pos"])
		_link(nm, near)
		spots[s]["node"] = nm


func _nearest_ground(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for k in GROUND:
		var d: float = (points[k] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = k
	for k2 in ["ponton_peche", "porte_boulangerie", "porte_pecherie", "nacelle_bas"]:
		var d2: float = (points[k2] as Vector3).distance_to(p)
		if d2 < bd:
			bd = d2
			best = k2
	return best


# =================================================================== la vie

func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var near: bool = Vector2(p.x - R.ORIGIN.x, p.z - R.ORIGIN.z).length() < 420.0
	var h: float = hour()
	# la fête de la lune : de 20 h à 1 h, chaque nuit (à Ramure, la lune est toujours pleine)
	var on: bool = h >= 20.0 or h < 1.0
	if on != fete_on:
		fete_on = on
		for l in _fete_lights:
			(l as OmniLight3D).light_energy = 1.4 if on else 0.0
		for fx in _fire_fx:
			(fx as CPUParticles3D).emitting = on
		if _music != null and _music.stream != null:
			if on:
				_music.play()
			else:
				_music.stop()
	if on and _fire_light != null:
		_fire_light.light_energy = 2.2 + 0.6 * sin(_clock * 9.0) * sin(_clock * 13.0)
	elif _fire_light != null:
		_fire_light.light_energy = 0.0
	_race_tick(delta, p)
	if not near:
		fete_heard = false
		return
	fete_heard = on and _music != null and _music.playing and p.distance_to(_music.global_position) < 60.0
	if fete_heard and p.distance_to(_music.global_position) < 22.0:
		state["fete"] = true
	var night: bool = h >= 19.5 or h < 5.5
	for ff in _fireflies:
		(ff as CPUParticles3D).emitting = night
	var misty: bool = h >= 4.5 and h < 10.5
	for mi in _mist:
		(mi as CPUParticles3D).emitting = misty
	if _forge_light != null:
		_forge_light.light_energy = (1.0 + 0.4 * sin(_clock * 7.0)) if h >= 7.0 and h < 18.0 else 0.0


# =================================================================== la Grande Course

const RACERS := [["bondi", 3.0, 30.0], ["grisou", 2.95, 10.0], ["eclair", 2.85, 20.0]]
const LANES := [-1.4, 0.0, 1.4]
var race := {"etat": "", "t": 0.0, "next": 1, "places": [], "joueur": -1.0}
var _race_count: float = 0.0


## Le parcours d'un coureur : les arches dans l'ordre, puis l'arrivée (avec un petit décalage
## de couloir pour ne pas courir les uns dans les autres).
func _race_path(lane: float) -> Array:
	var out: Array = []
	var n: int = R.COURSE.size()
	for i in range(n + 1):
		var c: Vector2 = R.COURSE[i % n]
		var nxt: Vector2 = R.COURSE[(i + 1) % n]
		var prev: Vector2 = R.COURSE[(i - 1 + n) % n]
		var dir: Vector2 = (nxt - prev).normalized()
		var side := Vector2(-dir.y, dir.x)
		var q: Vector2 = c + side * lane
		out.append(G(q.x, q.y))
	return out


func race_can_start() -> bool:
	return str(race["etat"]) == ""


func start_race() -> void:
	if not race_can_start():
		return
	race = {"etat": "compte", "t": 0.0, "next": 1, "places": [], "joueur": -1.0}
	_race_count = 3.6
	# les coureurs se mettent sur la ligne (chacun son couloir) et attendent le départ
	for i in range(RACERS.size()):
		var id: String = str(RACERS[i][0])
		if by_id.has(id):
			by_id[id].start_race(_race_path(float(LANES[i])), 0.0, 0.0, Callable())
	state["courses"] = int(state.get("courses", 0)) + 1
	main._show_message_v28("La Grande Course ! Passe sous les dix arches de lanternes, dans l'ordre, et reviens ici. Prêts ?")
	if main.get("sfx_v50") != null:
		main.sfx_v50.play("course_depart", _checkpoints[0])


func _race_tick(delta: float, p: Vector3) -> void:
	var et: String = str(race["etat"])
	if et == "":
		return
	var n: int = R.COURSE.size()
	# trop loin de la course : abandon
	if Vector2(p.x - _checkpoints[0].x, p.z - _checkpoints[0].z).length() > 170.0:
		_race_end("Tu as quitté la Grande Course… Les coureurs rentrent à la Clairière des Jeux.")
		return
	if et == "compte":
		var before: int = int(ceil(_race_count))
		_race_count -= delta
		var now_i: int = int(ceil(_race_count))
		if now_i != before and now_i > 0 and now_i <= 3:
			main._show_message_v28("%d…" % now_i)
		if _race_count <= 0.0:
			race["etat"] = "course"
			race["t"] = 0.0
			main._show_message_v28("Partez !")
			for i in range(RACERS.size()):
				var id: String = str(RACERS[i][0])
				if by_id.has(id) and bool(by_id[id].racing):
					by_id[id].race_go(float(RACERS[i][1]), float(RACERS[i][2]), Callable(self, "_racer_done"))
		return
	if et != "course":
		return
	race["t"] = float(race["t"]) + delta
	var i_next: int = int(race["next"])
	var goal: Vector3 = _checkpoints[i_next % n]
	if Vector2(p.x - goal.x, p.z - goal.z).length() < 4.5 and absf(p.y - goal.y) < 6.0:
		if i_next >= n:
			_player_finished()
			return
		race["next"] = i_next + 1
		if main.get("sfx_v50") != null:
			main.sfx_v50.here("clochette")
		main._show_message_v28(("Arche %d sur %d — %d s" % [i_next, n - 1, int(race["t"])]) if i_next < n - 1 else ("Dernière arche ! Vite, l'arrivée — %d s" % int(race["t"])))
	if float(race["t"]) > 420.0:
		_race_end("Trop long… La Grande Course est finie sans toi. Reviens à la Clairière des Jeux pour une revanche.")


func _racer_done(npc: Node) -> void:
	(race["places"] as Array).append(str(npc.profile.get("id", "")))
	if str(race["etat"]) == "course" and (race["places"] as Array).size() == 1:
		npc.say_bubble("Premier ! Hop hop hop !" if str(npc.profile.get("id", "")) == "bondi" else "Arrivé !", 3.0)


func _player_finished() -> void:
	var t: float = float(race["t"])
	var rank: int = (race["places"] as Array).size() + 1
	race["joueur"] = t
	var best: float = float(state.get("record", 0.0))
	if best <= 0.0 or t < best:
		state["record"] = t
	if rank == 1:
		state["victoires"] = int(state.get("victoires", 0)) + 1
		_race_end("VICTOIRE ! Premier en %d s ! Toute la Clairière applaudit. Va voir Pépin." % int(t))
	else:
		_race_end("Arrivé %s en %d s. %s" % ["deuxième" if rank == 2 else ("troisième" if rank == 3 else "quatrième"), int(t), "Presque ! Une revanche ?" if rank == 2 else "Les pattes de Ramure sont rapides… Une revanche ?"])
	if main.get("sfx_v50") != null:
		main.sfx_v50.play("course_arrivee", _checkpoints[0])


func _race_end(msg: String) -> void:
	race["etat"] = ""
	if msg != "":
		main._show_message_v28(msg)
	for r in RACERS:
		var id: String = str(r[0])
		if by_id.has(id) and bool(by_id[id].racing):
			by_id[id].stop_race()


# =================================================================== la barque, les zones

func on_structure(p: Vector3) -> bool:
	if riding():
		return true
	var t: Vector2 = R.to_local(p.x, p.z)
	# sur une plate-forme, un pont ou un escalier (au-dessus du sol)
	var g: float = ile.height(p.x, p.z)
	if p.y > g + 1.6 and t.x > -42.0 and t.x < 60.0 and t.y > -80.0 and t.y < 66.0:
		return true
	# le ponton de pêche
	return absf(t.y - 24.0) < 1.2 and t.x < -4.0 and t.x > -16.5


func blocks_boat(_p: Vector3) -> bool:
	return false


## Le haut des arbres géants (pour le Zéphyr, qui passe au-dessus) : la cime de la couronne
## au-dessus de (x, z), -INF ailleurs.
func obstacle_height(wx: float, wz: float) -> float:
	var best: float = -INF
	for id in trees:
		var t: Dictionary = trees[id]
		var b: Vector3 = t["base"]
		var H: float = float(t["td"]["h"])
		if Vector2(wx - b.x, wz - b.z).length() < H * 0.34 + 6.0:
			best = maxf(best, b.y + H * 1.05)
	return best


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var t: Vector2 = R.to_local(p.x, p.z)
	if t.x > 70.0:
		return "ramure_ponton" if ile.height(p.x, p.z) > -0.42 or on_structure(p) else ""
	if t.distance_to(R.CERCLE) < R.CERCLE_R + 6.0 and p.y < ile.height(p.x, p.z) + 3.0:
		return "ramure_cercle"
	if p.y > ile.height(p.x, p.z) + 5.0:
		return "ramure_arbres"
	return "ramure"


# =================================================================== les habitants (agenda)

const Habitants = preload("res://scripts/pnj/ramure_habitants_v62.gd")
const PnjRamure = preload("res://scripts/pnj/pnj_ramure_v62.gd")

var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "fete": false, "trocs": 0, "courses": 0, "victoires": 0, "record": 0.0, "nacelle": 0, "tyrolienne": 0}
var _claims: Dictionary = {}


func spot(name: String) -> Dictionary:
	return spots.get(name, {})


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty():
		return
	for data in Habitants.all_profiles():
		var start: String = "g_cercle_n"
		var home: String = str(data.get("maison", ""))
		if points.has(home):
			start = home
		var npc: Node3D = PnjRamure.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V62: %d habitants à Ramure" % habitants.size())


func dock() -> Array:
	return boat_dock


func respawn_point() -> Array:
	var at: Vector3 = G(R.CERCLE.x + 12.5, R.CERCLE.y - 2.0, 0.3)
	return [at, (G(R.CERCLE.x, R.CERCLE.y) - at).normalized()]


## La nacelle et la tyrolienne : monter, descendre.
func riding() -> bool:
	return (lift != null and lift.riding) or (zip != null and zip.riding)


func ride_prompt() -> String:
	return ""


func ride_interact() -> void:
	pass


func ride_safe_pos() -> Vector3:
	if lift != null and lift.riding:
		return lift.safe_pos()
	if zip != null and zip.riding:
		return zip.safe_pos()
	return G(R.CERCLE.x + 12.5, R.CERCLE.y)


var _lift_inter: Dictionary = {}


func register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var I: Array = d._interactions
	_lift_inter = {"id": "nacelle_monter", "pos": Vector3.INF, "radius": 2.6, "text": "E : monter dans la nacelle d'osier", "vr": "Gâchette : monter dans la nacelle",
		"call": _board_lift, "when": func(): return lift != null and not riding() and lift.at_station() != ""}
	I.append(_lift_inter)
	I.append({"id": "tyrolienne", "pos": trees["guet"].get("zip_start", Vector3.INF), "radius": 2.0, "text": "E : s'accrocher à la tyrolienne", "vr": "Gâchette : s'accrocher à la tyrolienne",
		"call": _board_zip, "when": func(): return zip != null and not riding() and zip.at_station() == "haut"})
	I.append({"id": "grande_course", "pos": _checkpoints[0] if not _checkpoints.is_empty() else Vector3.INF, "radius": 3.2, "text": "E : prendre le départ de la Grande Course", "vr": "Gâchette : prendre le départ",
		"call": start_race, "when": func(): return race_can_start() and not riding()})


func _physics_process(_delta: float) -> void:
	if not _lift_inter.is_empty() and lift != null:
		_lift_inter["pos"] = lift.car_floor() + Vector3.UP * 0.4


func _board_lift() -> void:
	lift.board()
	state["nacelle"] = int(state["nacelle"]) + 1


func _board_zip() -> void:
	zip.board()
	state["tyrolienne"] = int(state["tyrolienne"]) + 1


## Services : le Grand Troc de Bedaine le tanuki (des échanges, objet contre objet).
const TROCS := [
	{"id": "baies", "prend": [["baies", 3]], "donne": [["miel", 1]], "label": "3 baies sauvages contre un miel sauvage"},
	{"id": "pommes", "prend": [["pomme", 4]], "donne": [["pain_carotte", 1]], "label": "4 pommes contre un pain de carotte"},
	{"id": "champis", "prend": [["champignon", 2]], "donne": [["tisane_brume", 1]], "label": "2 champignons des bois contre une tisane de brume"},
	{"id": "sardines", "prend": [["sardine", 2]], "donne": [["gateau_lune", 1]], "label": "2 sardines contre un gâteau de lune"},
	{"id": "botte", "prend": [["vieille_botte", 1]], "donne": [["caillou_chantant", 1]], "label": "une vieille botte contre un caillou-qui-chante"},
	{"id": "plume", "prend": [["plume_corbeau", 1]], "donne": [["plume_lune", 1]], "label": "une plume de corbeau contre une plume de lune"},
]


func register_services(journal: Node) -> void:
	journal.add_service("bedaine", Callable(self, "_troc_topics"), Callable(self, "_troc_choose"))
	for k in objets:
		journal.lieux[k] = objets[k]
	register_interactions()


func _troc_topics(_npc: Node) -> Array:
	var out: Array = [{"id": "q56:service:troc_liste", "label": "⇄ Qu'est-ce qu'on peut troquer ?"}]
	for t in TROCS:
		var ok: bool = true
		for pr in t["prend"]:
			if main.inventory_v28.count(str(pr[0])) < int(pr[1]):
				ok = false
		if ok:
			out.append({"id": "q56:service:troc_" + str(t["id"]), "label": "⇄ Troquer " + str(t["label"])})
	return out


func _troc_choose(_npc: Node, choice: String) -> Dictionary:
	var what: String = choice.get_slice(":", 2)
	if what == "troc_liste":
		var lines: Array = []
		for t in TROCS:
			lines.append("• " + str(t["label"]))
		return {"texte": "Le Grand Troc ! Ici, pas de pièces : on échange. Une chose contre une autre, et tout le monde repart content. Aujourd'hui, je prends :\n" + "\n".join(lines), "geste": "parle"}
	for t2 in TROCS:
		if "troc_" + str(t2["id"]) == what:
			for pr in t2["prend"]:
				if main.inventory_v28.count(str(pr[0])) < int(pr[1]):
					return {"texte": "Hé hé, il te manque quelque chose ! Reviens quand tu as tout.", "geste": "parle"}
			return {"texte": "Marché conclu ! Tope là, de la patte. Qu'est-ce qu'on troque ensuite ?", "geste": "salut", "prendre": t2["prend"], "donner": t2["donne"], "_troc": 1}
	return {}


func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_troc"):
		state["trocs"] = int(state["trocs"]) + 1


func trouvailles() -> Dictionary:
	return {"ramure": 1 if bool(state["visite"]) else 0, "fete_lune": 1 if bool(state["fete"]) else 0,
		"course_ramure": int(state["victoires"]), "trocs": int(state["trocs"]), "nacelle": int(state["nacelle"]), "tyrolienne": int(state["tyrolienne"])}


func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "fete": bool(d.get("fete", false)), "trocs": int(d.get("trocs", 0)), "courses": int(d.get("courses", 0)),
		"victoires": int(d.get("victoires", 0)), "record": float(d.get("record", 0.0)), "nacelle": int(d.get("nacelle", 0)), "tyrolienne": int(d.get("tyrolienne", 0))}
	if lift != null:
		lift.riding = false
	if zip != null:
		zip.riding = false
	if str(race["etat"]) != "":
		_race_end("")
	_claims.clear()
	for n in habitants:
		n.slot = -2


func check_visit(p: Vector3) -> void:
	if not bool(state["visite"]) and zone_at(p).begins_with("ramure"):
		state["visite"] = true
		main._show_message_v28("Ramure, le village des oreilles — les arbres géants, le Marché aux trocs, le Cercle de la Lune")

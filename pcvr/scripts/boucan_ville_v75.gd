extends Node3D
## V75 : Port-Boucan, la ville-friche des punks (ile_boucan_v75.gd donne le relief : les remblais
## plats de la ville, le Vieux Bassin, la cale sèche, la plage du cargo). Ici, tout ce qui est bâti :
##  - le réseau des rues (en grille : le Quai, la rue des Sardines, la rue de la Filature, l'avenue
##    Centrale, les rues Ouest et Est) ; des dizaines de maisons ouvrières de briques et d'entrepôts le
##    long des rues (boucan_kit_v75 les dessine), des lampadaires, des graffitis ;
##  - les grands lieux (la Halle Hurlante, la Conserverie, la Filature, la Place des Palettes, le
##    cargo échoué, le skatepark de la cale sèche, le Mur d'Expression, les Boîtes, les Jardins
##    Partagés, le château d'eau, le bureau de vente de Lisse & Fils, le port et ses grues) :
##    boucan_lieux_v75.gd ;
##  - les points et liens des rues pour les habitants, leurs lieux (spots), leurs portes.

const R = preload("res://scripts/ile_boucan_v75.gd")
const Kit = preload("res://scripts/boucan_kit_v75.gd")
const Lieux = preload("res://scripts/boucan_lieux_v75.gd")

const Y: float = R.TOWN_Y
## Les rues : nom -> points (repère île) ; un point des rues tous les ~12 m.
const STREETS := {
	"quai": [Vector2(-112.0, -150.0), Vector2(162.0, -150.0)],
	"sardines": [Vector2(-140.0, -96.0), Vector2(162.0, -96.0)],
	"filature": [Vector2(-140.0, -36.0), Vector2(104.0, -36.0)],
	"centrale": [Vector2(-4.0, -150.0), Vector2(-4.0, -8.0)],
	"ouest": [Vector2(-96.0, -150.0), Vector2(-96.0, -36.0)],
	"est": [Vector2(92.0, -150.0), Vector2(92.0, -36.0)],
	"bout_est": [Vector2(162.0, -150.0), Vector2(162.0, -60.0)],
	"cargo": [Vector2(-112.0, -150.0), Vector2(-124.0, -156.0)],
	"jardins": [Vector2(104.0, -36.0), Vector2(132.0, -36.0), Vector2(162.0, -60.0)],
}
## Les grands lieux (pas de maisons) : [nom, Rect2 (repère île)].
const RESERVED := [
	["conserverie", Rect2(-84.0, -124.0, 44.0, 30.0)],
	["halle", Rect2(26.0, -132.0, 54.0, 38.0)],
	["place", Rect2(-32.0, -98.0, 54.0, 34.0)],
	["filature", Rect2(-56.0, -70.0, 66.0, 36.0)],
	["cheminee", Rect2(4.0, -60.0, 20.0, 20.0)],
	["bureau", Rect2(-74.0, -34.0, 30.0, 22.0)],
	["mur", Rect2(-128.0, -92.0, 26.0, 48.0)],
	["chateau_eau", Rect2(102.0, -78.0, 32.0, 32.0)],
	["boites", Rect2(58.0, -34.0, 48.0, 32.0)],
	["jardins", Rect2(108.0, -34.0, 56.0, 34.0)],
	["rails", Rect2(18.0, -150.0, 12.0, 56.0)],
	["cargo", Rect2(-200.0, -214.0, 88.0, 90.0)],
	["bassin", Rect2(-42.0, -214.0, 104.0, 60.0)],
	["cale", Rect2(82.0, -214.0, 52.0, 56.0)],
]
## Où habitent ceux qui n'ont pas leur porte dans un grand lieu : id -> [x, z] (la maison libre la
## plus proche de ce point).
const HOMES := {
	"boulon": [10.0, -140.0],
}

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var lieux                                # boucan_lieux_v75
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}              # nom -> Vector3 (les comptoirs, les invites, les lieux des quêtes)
var flora_avoid: Array = []
var fire_spots: Array = []               # [Vector3, taille]
var smoke_spots: Array = []
var tree_spots: Array = []               # Vector3 : les arbres plantés dans la ville
var houses: Array = []                   # {door, x, z, owner}
var walls_paint: Array = []              # [Transform3D, w, h] : des murs où l'on peut peindre (graffitis)
var animals: Array = []                  # [espèce, Vector3, rayon] : les animaux de la ville (faune_v75)
var districts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _store: Dictionary = {}
var _cur: String = ""
var _street_nodes: Dictionary = {}       # rue -> [noms des points, dans l'ordre]


# =================================================================== repères

func G(x: float, z: float, dy: float = 0.05) -> Vector3:
	return R.W(x, z, Y + dy)


## Un repère au point (x, z) de la ville, au sol de la ville, dont le +Z regarde la direction (dx, dz).
func XF(x: float, z: float, dx: float, dz: float, y: float = Y) -> Transform3D:
	var d := Vector3(dx, 0.0, dz).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), R.W(x, z, y))


static func XD(p: Vector3, dir: Vector3) -> Transform3D:
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


static func reserved(x: float, z: float) -> String:
	for r in RESERVED:
		if (r[1] as Rect2).has_point(Vector2(x, z)):
			return str(r[0])
	return ""


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String = "") -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


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


func _pt(name: String, p: Vector3) -> String:
	points[name] = p
	return name


func _avoid(p: Vector3, r: float) -> void:
	flora_avoid.append([Vector2(p.x, p.z), r])


func _district(name: String) -> void:
	if _cur == name:
		return
	if _cur != "":
		_store[_cur] = [kit.batch, kit.inst]
	var n: Node3D = districts.get(name, null)
	if n == null:
		n = Node3D.new()
		n.name = "Quartier_" + name
		add_child(n)
		districts[name] = n
	kit.root = n
	var st: Variant = _store.get(name, null)
	if st == null:
		kit.batch = {}
		kit.inst = {}
	else:
		kit.batch = st[0]
		kit.inst = st[1]
	_cur = name


func _commit_all() -> void:
	if _cur != "":
		_store[_cur] = [kit.batch, kit.inst]
	for name in _store:
		kit.root = districts[name]
		kit.batch = _store[name][0]
		kit.inst = _store[name][1]
		kit.commit()
	_store.clear()
	_cur = ""


## Le quartier d'un point (une grille de 60 m : un maillage par case).
func _district_at(x: float, z: float) -> String:
	return "q_%d_%d" % [int(floor((x + 200.0) / 60.0)), int(floor((z + 220.0) / 60.0))]


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 7571
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 7572
	kit.light_every = 3
	lieux = Lieux.new()
	lieux.setup(self)
	_streets()
	_district("halle")
	lieux.halle()
	_district("conserverie")
	lieux.conserverie()
	_district("filature")
	lieux.filature()
	lieux.cheminee()
	_district("place")
	lieux.place()
	_district("port")
	lieux.port()
	_district("cargo")
	lieux.cargo()
	_district("cale")
	lieux.bassin_sec()
	_district("mur")
	lieux.mur()
	_district("est")
	lieux.chateau_eau()
	lieux.boites()
	lieux.jardins()
	_district("bureau")
	lieux.bureau()
	lieux.rails()
	var t1: int = Time.get_ticks_msec()
	_fill_houses()
	_lamps()
	var t2: int = Time.get_ticks_msec()
	_commit_all()
	_homes()
	_graph()
	for f in kit.fires70:
		fire_spots.append(f)
	for c in kit.chimneys70:
		if _rng.randf() < 0.35:
			smoke_spots.append(c)
	print("ILE_MANGA_V75: Port-Boucan bâtie, %d maisons, %d lieux, %d points, %d pièces répétées, %d lampadaires, en %d ms (maisons %d ms)" % [houses.size(), spots.size(), points.size(), kit.inst_count, kit.lamps70.size(), Time.get_ticks_msec() - t0, t2 - t1])


# =================================================================== les rues

func _node_name(p: Vector2) -> String:
	return "st_%d_%d" % [int(round(p.x)), int(round(p.y))]


func _streets() -> void:
	for s in STREETS:
		var pts: Array = STREETS[s]
		var names: Array = []
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var n: int = maxi(int(round(a.distance_to(b) / 12.0)), 1)
			for k in range(n + (1 if i == pts.size() - 2 else 0)):
				var p: Vector2 = a.lerp(b, float(k) / n)
				# les croisements tombent sur un point existant (à moins de 6 m)
				var nm: String = _node_name(p)
				for other in points:
					if str(other).begins_with("st_") and Vector2((points[other] as Vector3).x - R.CENTER.x, (points[other] as Vector3).z - R.CENTER.z).distance_to(p) < 6.0:
						nm = str(other)
						break
				if not points.has(nm):
					_pt(nm, G(p.x, p.y))
				if names.is_empty() or names[-1] != nm:
					names.append(nm)
		_street_nodes[s] = names


func _graph() -> void:
	for s in _street_nodes:
		_chain(_street_nodes[s])
	lieux.link_graph()
	# les portes des maisons : au point de rue le plus proche
	for d in doors:
		if graph.has(str(doors[d])):
			continue
		_link(str(doors[d]), nearest_street(points[doors[d]]))
	_street_spots()


func nearest_street(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		if not str(k).begins_with("st_"):
			continue
		var q: Vector3 = points[k]
		var d: float = q.distance_to(p)
		if d < bd:
			bd = d
			best = str(k)
	return best


func _nearest_point(p: Vector3, exclu: String = "") -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		if exclu != "" and str(k).begins_with(exclu):
			continue
		var q: Vector3 = points[k]
		var d: float = q.distance_to(p) + absf(q.y - p.y) * 3.0
		if d < bd:
			bd = d
			best = str(k)
	return best


## Les lieux des rues : des coins où l'on bavarde.
func _street_spots() -> void:
	var rues := [["rue_1", -60.0, -96.0, 0.0, 3.2, "debout"], ["rue_2", 120.0, -96.0, 0.0, -3.2, "bras_croises"],
		["rue_3", -96.0, -70.0, 3.0, 0.0, "debout"], ["rue_4", 60.0, -36.0, 0.0, 3.0, "observer"],
		["rue_5", -120.0, -36.0, 0.0, -3.0, "debout"], ["rue_6", 92.0, -120.0, -3.0, 0.0, "observer"]]
	for rr in rues:
		var p: Vector3 = G(float(rr[1]) + float(rr[3]), float(rr[2]) + float(rr[4]))
		var node: String = nearest_street(p)
		_spot(str(rr[0]), p, Vector3(-float(rr[3]), 0, -float(rr[4])) if str(rr[5]) != "observer" else Vector3(float(rr[3]), 0, float(rr[4])), str(rr[5]), node)


# =================================================================== les maisons des rues

## Le long de chaque rue, des deux côtés : des maisons ouvrières et des entrepôts, sauf dans les
## grands lieux, la façade à 5 m du milieu de la rue.
func _fill_houses() -> void:
	var walls := ["brique75", "brique75", "brique75_sombre", "briquep75_blanc", "briquep75_jaune", "briquep75_bleu", "brique75_suie", "briquep75_rose", "briquep75_vert", "brique75"]
	var doors_c := ["rouge", "vert", "bleu", "jaune", "noir", "violet", "orange", "turquoise"]
	for s in ["quai", "sardines", "filature", "ouest", "est", "centrale"]:
		var pts: Array = STREETS[s]
		var a: Vector2 = pts[0]
		var b: Vector2 = pts[-1]
		var dir: Vector2 = (b - a).normalized()
		var side_n := Vector2(-dir.y, dir.x)
		var len: float = a.distance_to(b)
		for side in [-1.0, 1.0]:
			if s == "quai" and side * side_n.y < 0.0:
				continue
			var t: float = 8.0
			while t < len - 8.0:
				var w: float = 6.0 + _rng.randf() * 4.0
				var d: float = 8.5 + _rng.randf() * 3.0
				var c: Vector2 = a + dir * (t + w * 0.5) + side_n * side * 5.0
				var back: Vector2 = c + side_n * side * d
				var ok: bool = reserved(c.x, c.y) == "" and reserved(back.x, back.y) == "" and _clear_of_streets(c, side_n * side, w, d, s)
				ok = ok and R.in_town(c.x, c.y) and R.in_town(back.x, back.y) and not R.in_basin(c.x, c.y)
				if ok:
					_district(_district_at(c.x, c.y))
					var face := Vector3(-side_n.x * side, 0, -side_n.y * side)
					var xf: Transform3D = XD(R.W(c.x, c.y, Y), face)
					var big: bool = _rng.randf() < 0.22
					if big:
						# un entrepôt (tôle, un rideau de garage tagué, une fresque parfois)
						var ew: float = w + 3.0
						var res: Dictionary = kit.usine75(xf, ew, d + 3.0, {"h": 6.5, "wall": "tole75" if _rng.randf() < 0.5 else "brique75", "roof": "gable", "pitch": 14.0,
							"rows": 1, "lit": 0.1, "bay": 4.0, "pilasters": false, "cornice": false})
						kit.place("rideau75|" + ["gris", "rouge", "bleu", "vert"][_rng.randi() % 4], xf * Transform3D(Basis(), Vector3(0, 0, 0.05)))
						if _rng.randf() < 0.6:
							kit.quadz(xf * Transform3D(Basis(), Vector3(-ew * 0.25, 2.2, 0.08)), 3.6, 1.8, "graffiti75_" + str(1 + _rng.randi() % 12))
						walls_paint.append([xf * Transform3D(Basis(), Vector3(ew * 0.3, 2.0, 0.08)), 3.0, 1.6])
						houses.append({"door": res["door"], "x": c.x, "z": c.y, "big": true})
						t += ew + 1.0
						continue
					var door: Vector3 = kit.maison75(xf, w, d, {"floors": 2 if _rng.randf() < 0.6 else 3, "wall": walls[_rng.randi() % walls.size()],
						"roof": "tole75" if _rng.randf() < 0.45 else ("tuiles71_rouge" if _rng.randf() < 0.6 else "tuiles71_ardoise"),
						"door": doors_c[_rng.randi() % doors_c.size()], "volet": doors_c[_rng.randi() % doors_c.size()] if _rng.randf() < 0.3 else "",
						"graffiti": 1 + _rng.randi() % 12} if _rng.randf() < 0.35 else {"floors": 2, "wall": walls[_rng.randi() % walls.size()],
						"roof": "tole75", "door": doors_c[_rng.randi() % doors_c.size()]})
					houses.append({"door": door, "x": c.x, "z": c.y})
					# un petit bric-à-brac devant : des plantes, un vélo de palettes, un banc
					if _rng.randf() < 0.3:
						kit.place("plante75|" + ["rouge", "bleu", "jaune", "vert"][_rng.randi() % 4], Transform3D(Basis(), xf * Vector3(w * 0.35, 0.0, 0.7)))
					if _rng.randf() < 0.15:
						kit.baril75(xf * Vector3(-w * 0.4, 0.0, 0.9))
					t += w + 0.4
				else:
					t += 3.0


## Une maison ne mord sur aucune autre rue (sa profondeur, ses côtés).
func _clear_of_streets(c: Vector2, n: Vector2, w: float, d: float, own: String) -> bool:
	var pts := [c, c + n * d, c + Vector2(-n.y, n.x) * w * 0.5, c - Vector2(-n.y, n.x) * w * 0.5, c + n * d + Vector2(-n.y, n.x) * w * 0.5, c + n * d - Vector2(-n.y, n.x) * w * 0.5]
	for s in STREETS:
		if s == own:
			continue
		var sp: Array = STREETS[s]
		for i in range(sp.size() - 1):
			for p in pts:
				if R._seg_dist2(p, sp[i], sp[i + 1]) < 4.5:
					return false
	return true


func _homes() -> void:
	var taken: Dictionary = {}
	for i0 in range(houses.size()):
		if (houses[i0] as Dictionary).has("owner") or bool(houses[i0].get("big", false)):
			taken[i0] = true
	for id in HOMES:
		var want: Array = HOMES[id]
		var best: int = -1
		var bd: float = INF
		for i in range(houses.size()):
			if taken.has(i):
				continue
			var h: Dictionary = houses[i]
			var d: float = Vector2(float(h["x"]), float(h["z"])).distance_to(Vector2(float(want[0]), float(want[1])))
			if d < bd:
				bd = d
				best = i
		if best < 0:
			continue
		taken[best] = true
		doors["porte_" + str(id)] = _pt("porte_" + str(id), (houses[best]["door"] as Vector3) + Vector3.UP * 0.05)
		houses[best]["owner"] = str(id)


## Les lampadaires des rues (tous les ~28 m, un côté sur deux).
func _lamps() -> void:
	for s in ["quai", "sardines", "filature", "ouest", "est", "centrale", "bout_est"]:
		var pts: Array = STREETS[s]
		var a: Vector2 = pts[0]
		var b: Vector2 = pts[-1]
		var dir: Vector2 = (b - a).normalized()
		var side_n := Vector2(-dir.y, dir.x)
		var len: float = a.distance_to(b)
		var t: float = 10.0
		var k: int = 0
		while t < len - 4.0:
			var side: float = 1.0 if k % 2 == 0 else -1.0
			if s == "quai":
				side = -1.0 if side_n.y < 0.0 else 1.0
			var c: Vector2 = a + dir * t + side_n * side * 3.4
			if reserved(c.x, c.y) in ["", "rails"] and R.in_town(c.x, c.y) and not R.in_basin(c.x, c.y):
				_district(_district_at(c.x, c.y))
				kit.lampadaire75(R.W(c.x, c.y, Y), atan2(-side_n.x * side, -side_n.y * side) - PI * 0.5)
			t += 28.0
			k += 1


# =================================================================== où est-on ?

func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


## Le lieu de la ville (pour la musique, les ambiances, le carnet), ou "".
func zone_at(p: Vector3) -> String:
	var lz: String = lieux.zone_at(p) if lieux != null else ""
	if lz != "":
		return lz
	var l: Vector2 = R.L(p.x, p.z)
	if not R.TOWN.grow(4.0).has_point(l):
		return ""
	var rz: String = reserved(l.x, l.y)
	match rz:
		"place":
			return "bo_place"
		"bassin", "rails":
			return "bo_port"
		"cale":
			return "bo_skate"
		"cargo":
			return "bo_cargo" if p.y > 3.0 else ""
		"mur":
			return "bo_mur"
		"jardins":
			return "bo_jardins"
		"boites":
			return "bo_boites"
	if l.y < -142.0:
		return "bo_port"
	return "bo_ville"

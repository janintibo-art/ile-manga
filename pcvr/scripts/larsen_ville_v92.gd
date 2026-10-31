extends Node3D
## V92 : la vie de l'Île de Larsen. Les rues (un graphe de points le long des chemins, autour du feu
## du Camp des Fleurs, dans la rue de Rainville, sur la Prairie du Festival), les portes des yourtes
## (« porte_y_<yourte> », et « porte_<habitant> » pour celles des habitants qu'on connaît), les lieux
## où l'on s'installe (les bancs du feu, les djembés, les jardins, les bus, la mare, le garage des
## Gouttières, la terrasse du Café Feedback, le Disquaire, la rampe, la régie…), et les habitants
## (pnj/larsen_habitants_v92.gd, pnj/pnj_larsen_v92.gd), qui vivent selon l'heure.
## Le gestionnaire des lieux (hour, spot, spot_free, claim_spot, release_spot) : comme les villes des
## autres îles.

const IleScript = preload("res://scripts/ile_larsen_v91.gd")
const Kit = preload("res://scripts/larsen_kit_v91.gd")
const HABITANTS := "res://scripts/pnj/larsen_habitants_v92.gd"
const PNJ := "res://scripts/pnj/pnj_larsen_v92.gd"

var main: Node
var L: Node3D                             # larsen_v91 (l'île, les yourtes)
var points: Dictionary = {}               # nom -> Vector3 (monde)
var graph: Dictionary = {}                # nom -> [voisins]
var spots: Dictionary = {}                # nom -> {pos, face, pose, node}
var habitants: Array = []
var by_id: Dictionary = {}
var door_of: Dictionary = {}              # nom de yourte -> point de sa porte
var _claims: Dictionary = {}
var _streets: Array = []                  # noms des points de rue


func setup(main_node: Node, larsen: Node3D) -> void:
	main = main_node
	L = larsen
	name = "Larsen_ville_v92"


func G(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = L.ile.height(w.x, w.z)
	return w


# =================================================================== construction

func build() -> void:
	var t0: int = Time.get_ticks_msec()
	_rues()
	_portes()
	_lieux()
	_decor()
	print("ILE_MANGA_V92: Île de Larsen : %d points, %d lieux, %d portes (%d ms)" % [points.size(), spots.size(), door_of.size(), Time.get_ticks_msec() - t0])


func _pt(nm: String, p: Vector3) -> String:
	points[nm] = p
	if nm.begins_with("st_"):
		_streets.append(nm)
	return nm


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


## Une rue : des points tous les ~8 m le long d'une ligne brisée (repère île) ; les points proches
## d'un point existant (< 3 m) se confondent avec lui (les croisements).
func _rue(id: String, pts: Array, step: float = 8.0) -> Array:
	var names: Array = []
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n: int = maxi(int(round(a.distance_to(b) / step)), 1)
		for k in range(n + (1 if i == pts.size() - 2 else 0)):
			var p: Vector2 = a.lerp(b, float(k) / n)
			var nm: String = ""
			for other in _streets:
				var q: Vector3 = points[other]
				if IleScript.L(q.x, q.z).distance_to(p) < 3.0:
					nm = str(other)
					break
			if nm == "":
				nm = _pt("st_%s_%d" % [id, names.size()], G(p.x, p.y))
			if names.is_empty() or names[-1] != nm:
				names.append(nm)
	for j in range(names.size() - 1):
		_link(names[j], names[j + 1])
	return names


func _rues() -> void:
	var c := Vector2(float(IleScript.PADS["fleurs"][0]), float(IleScript.PADS["fleurs"][1]))
	# --- les chemins de l'île (ceux du relief)
	for k in IleScript.PATHS:
		_rue("ch_" + str(k), IleScript.PATHS[k], 9.0)
	# --- le Camp des Fleurs : un grand rond entre les deux ronds de yourtes, des rayons vers le feu
	var ring_a: Array = [4.0, 44.0, 62.5, 76.0, 119.0, 163.0, 172.5, 193.0, 217.5, 223.0, 255.0, 284.0, 345.0]
	var ring: Array = []
	for a in ring_a:
		var ra: float = deg_to_rad(float(a))
		ring.append(c + Vector2(cos(ra), sin(ra)) * 19.0)
	ring.append(ring[0])
	_rue("rond", ring, 30.0)
	var inner: Array = []
	for k2 in range(8):
		var a2: float = TAU * (k2 + 0.5) / 8.0
		inner.append(c + Vector2(cos(a2), sin(a2)) * 7.0)
	inner.append(inner[0])
	_rue("feu", inner, 30.0)
	for a3 in [2.5, 62.5, 117.5, 172.5, 217.5, 282.5]:
		var r3: float = deg_to_rad(a3)
		_rue("rayon_%d" % int(a3), [c + Vector2(cos(r3), sin(r3)) * 19.0, c + Vector2(cos(r3), sin(r3)) * 7.0], 30.0)
	# vers les bus, les jardins, la mare, l'entrée
	for a4 in [4.0, 76.0, 119.0, 163.0, 193.0, 255.0, 284.0]:
		var r4: float = deg_to_rad(a4)
		_rue("dehors_%d" % int(a4), [c + Vector2(cos(r4), sin(r4)) * 19.0, c + Vector2(cos(r4), sin(r4)) * 30.0], 30.0)
	# --- le Hameau du Gué, jusqu'à la prairie
	_rue("hameau", [c + Vector2(cos(deg_to_rad(76.0)), sin(deg_to_rad(76.0))) * 30.0, Vector2(-46, 44), Vector2(-33, 46), Vector2(-20, 46), Vector2(-10, 40), Vector2(2, 38)], 9.0)
	# --- Rainville : la grande rue, la rue de traverse, la ruelle de l'ouest, le devant des garages
	_rue("grande_rue", [Vector2(60, -24), Vector2(60, 26)], 7.0)
	_rue("traverse", [Vector2(30, 2), Vector2(36, 0), Vector2(44, 0), Vector2(47, 3.5), Vector2(60, 3.5), Vector2(77, 3.5)], 7.0)
	_rue("ruelle", [Vector2(44, -26), Vector2(44, 24)], 8.0)
	_rue("garages", [Vector2(76, -24), Vector2(76, 16)], 7.0)
	_rue("rampe", [Vector2(44, 24), Vector2(42, 22), Vector2(46, 26)], 4.0)
	# --- la Prairie du Festival
	_rue("prairie", [Vector2(2, 38), Vector2(0, 24), Vector2(0, 12), Vector2(-2, 0), Vector2(0, -12)], 9.0)
	_rue("prairie_o", [Vector2(-30, 8), Vector2(-15, 6), Vector2(-2, 0)], 9.0)
	_rue("prairie_e", [Vector2(30, 2), Vector2(15, 4), Vector2(-2, 0)], 9.0)
	_rue("prairie_n", [Vector2(0, -12), Vector2(-14, -14), Vector2(-10, -26), Vector2(0, -26)], 9.0)
	_rue("roadies", [Vector2(4, -50), Vector2(21, -50.5), Vector2(34, -52)], 8.0)
	_rue("plage_e", [Vector2(16, 106), Vector2(-10, 98), Vector2(-30, 94)], 9.0)
	# les chemins de la Corderie et des coquelicots, reliés au reste
	var r284: float = deg_to_rad(284.0)
	_rue("lien_corderie", [c + Vector2(cos(r284), sin(r284)) * 19.0, Vector2(-52, -12)], 30.0)
	_rue("lien_coquelicots", [Vector2(4, 62), Vector2(12, 62)], 30.0)


## Les portes : une par yourte, reliée au point de rue le plus proche qu'on rejoint sans traverser
## une autre yourte.
func _portes() -> void:
	for y in L.yourtes:
		var nm: String = "porte_y_" + str(y["nom"])
		_pt(nm, y["door"])
		door_of[str(y["nom"])] = nm
		var best: String = ""
		var bd: float = INF
		for s in _streets:
			var q: Vector3 = points[s]
			var d: float = q.distance_to(y["door"])
			if d < bd and d < 40.0 and not crosses(y["door"], q, str(y["nom"])):
				bd = d
				best = str(s)
		if best != "":
			_link(nm, best)


## Le segment a-b passe-t-il dans une yourte (sauf celle qu'on quitte) ?
func crosses(a: Vector3, b: Vector3, sauf: String = "") -> bool:
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	for y in L.yourtes:
		if str(y["nom"]) == sauf:
			continue
		var c := Vector2((y["at"] as Vector3).x, (y["at"] as Vector3).z)
		var r: float = (Kit.R + 0.5) * float(y["s"])
		var ab: Vector2 = b2 - a2
		var t: float = clampf((c - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if (a2 + ab * t).distance_to(c) < r:
			return true
	return false


## Les rues qui traversent une yourte (pour les tests).
func bad_links() -> Array:
	var out: Array = []
	for a in graph:
		for b in graph[a]:
			if str(a) < str(b):
				var sauf: String = ""
				for y in L.yourtes:
					var dp: Vector3 = y["door"]
					if dp.distance_to(points[a]) < 0.1 or dp.distance_to(points[b]) < 0.1:
						sauf = str(y["nom"])
				if crosses(points[a], points[b], sauf):
					out.append([a, b])
	return out


func nearest_street(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for s in _streets:
		var d: float = (points[s] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(s)
	return best


## Un lieu : x, z (repère île), vers où l'on regarde, la pose ; y : hauteur au-dessus du sol (assis
## sur un banc, sur un tabouret…) ou -1 (au sol).
func _spot(nm: String, x: float, z: float, face: Vector3, pose: String, dy: float = 0.0) -> void:
	var p: Vector3 = G(x, z) + Vector3.UP * dy
	var f: Vector3 = Vector3(face.x, 0, face.z).normalized() if face.length() > 0.01 else Vector3(0, 0, 1)
	spots[nm] = {"pos": p, "face": f, "pose": pose, "node": nearest_street(p)}


func _lieux() -> void:
	var c := Vector2(float(IleScript.PADS["fleurs"][0]), float(IleScript.PADS["fleurs"][1]))
	# --- le feu du Camp des Fleurs : les bancs de rondins (assis), les djembés (sur un tabouret)
	for k in range(6):
		var a2: float = TAU * k / 6.0 + 0.25
		var d := Vector2(cos(a2), sin(a2))
		var p: Vector2 = c + d * 4.75
		_spot("feu_%d" % (k + 1), p.x, p.y, Vector3(-d.x, 0, -d.y), "assis", 0.0)
	for k2 in range(3):
		var a3: float = TAU * (k2 * 2) / 6.0 + 0.25 + 0.45
		var d2 := Vector2(cos(a3), sin(a3))
		var p2: Vector2 = c + d2 * 3.95
		_spot("djembe_%d" % (k2 + 1), p2.x, p2.y, Vector3(-d2.x, 0, -d2.y), "batterie", 0.0)
	# --- les jardins de tournesols, l'arbre à rubans, le grand rond
	var jd: Array = L.jardins
	for j in range(mini(jd.size(), 2)):
		var gw: Vector3 = jd[j][0]
		var lc: Vector2 = IleScript.L(gw.x, gw.z)
		var out: Vector2 = (lc - c).normalized()
		var sp: Vector2 = lc - out * (float(jd[j][2]) + 1.2)
		_spot("jardin_%d" % (j + 1), sp.x, sp.y, Vector3(out.x, 0, out.y), "peindre")
	var ar: Vector2 = IleScript.L(L._arbre_at.x, L._arbre_at.z)
	_spot("arbre_rubans", ar.x - 2.2, ar.y + 2.0, Vector3(1, 0, -0.9), "debout")
	for k3 in [[1, 44.0], [2, 172.5], [3, 255.0]]:
		var r3: float = deg_to_rad(float(k3[1]) + 6.0)
		var p3: Vector2 = c + Vector2(cos(r3), sin(r3)) * 19.0
		_spot("camp_%d" % int(k3[0]), p3.x, p3.y, Vector3(-cos(r3), 0, -sin(r3)), "bras_croises" if int(k3[0]) == 2 else "debout")
	# --- les bus (on les peint, côté extérieur)
	var bi: int = 1
	for bu in [80.0, 200.0, 250.0]:
		var a4: float = deg_to_rad(bu)
		var o := Vector2(cos(a4), sin(a4))
		var p4: Vector2 = c + o * (33.0 + 3.2) + Vector2(-o.y, o.x) * 1.5
		_spot("bus_%d" % bi, p4.x, p4.y, Vector3(-o.x, 0, -o.y), "peindre")
		bi += 1
	# --- la mare, le métier à tisser de Lune, la Corderie, les coquelicots
	_spot("mare_1", -67.5, 40.0, Vector3(-1, 0, 0.6), "mediter")
	_spot("mare_2", -73.0, 34.5, Vector3(-0.4, 0, 1), "mediter")
	var lune: Dictionary = _yourte("fleurs_2")
	if not lune.is_empty():
		var lp: Vector3 = (lune["door"] as Vector3) + (lune["face"] as Vector3).cross(Vector3.UP) * 2.2
		var ll: Vector2 = IleScript.L(lp.x, lp.z)
		_spot("tissage", ll.x, ll.y, lune["face"], "tisser")
	_spot("corderie_1", -32.0, -36.4, Vector3(0, 0, -1), "debout")
	_spot("corderie_2", -24.0, -36.4, Vector3(0, 0, -1), "peindre")
	_spot("coquelicots_1", 34.0, 54.0, Vector3(1, 0, 0.3), "observer")
	# --- Rainville : le garage des Gouttières (on répète devant), les canapés, la rue
	_spot("garage_chant", 77.6, -18.0, Vector3(-1, 0, 0), "chanter")
	_spot("garage_guitare", 78.4, -21.4, Vector3(-1, 0, 0.3), "guitare")
	_spot("garage_basse", 78.4, -14.6, Vector3(-1, 0, -0.3), "basse")
	_spot("garage_batterie", 80.6, -18.0, Vector3(-1, 0, 0), "batterie")
	_spot("garage_public", 72.0, -17.0, Vector3(1, 0, 0), "observer")
	_spot("canape_1", 79.0, -2.5, Vector3(-1, 0, -0.15), "assis")
	_spot("canape_2", 79.0, 11.5, Vector3(-1, 0, -0.15), "assis")
	_spot("canape_3", 45.0, -28.0, Vector3(1, 0, 0), "assis")
	_spot("rue_1", 55.5, -18.0, Vector3(1, 0, 0), "bras_croises")
	_spot("rue_2", 65.0, 5.0, Vector3(-1, 0, 0), "debout")
	_spot("rue_3", 55.0, 13.0, Vector3(1, 0, 0), "debout")
	_spot("rue_4", 64.5, -9.0, Vector3(-1, 0, 0), "bras_croises")
	_spot("rampe", 40.0, 23.5, Vector3(0.7, 0, 0.7), "skate")
	# --- le Café Feedback : le comptoir dehors, la terrasse
	_spot("cafe_comptoir", 57.6, -25.9, Vector3(0, 0, 1), "comptoir")
	_spot("cafe_terrasse_1", 55.5, -21.9, Vector3(0, 0, -1), "assis")
	_spot("cafe_terrasse_2", 64.5, -21.9, Vector3(0, 0, -1), "assis")
	_spot("cafe_terrasse_3", 64.5, -24.1, Vector3(0, 0, 1), "assis")
	# --- le Disquaire (les caisses de disques devant la porte)
	_spot("disquaire_1", 64.4, -4.6, Vector3(1, 0, 0.2), "lire")
	_spot("disquaire_2", 64.4, 0.9, Vector3(1, 0, 0), "debout")
	# --- la Prairie du Festival, la régie, la scène, les roadies
	_spot("pelouse_1", -8.0, 10.0, Vector3(0.2, 0, -1), "debout")
	_spot("regie", 0.0, 15.15, Vector3(0, 0, -1), "comptoir")
	_spot("scene_1", -6.0, -12.5, Vector3(0, 0, -1), "observer")
	_spot("scene_2", 6.0, -12.5, Vector3(0, 0, -1), "bras_croises")
	_spot("scene_3", 13.5, -22.0, Vector3(-1, 0, 0), "debout")
	_spot("roadies_1", 12.0, -36.0, Vector3(-0.5, 0, 1), "debout")
	_spot("roadies_2", 18.0, -50.0, Vector3(-1, 0, 0), "bras_croises")
	# --- la plage, la colline
	_spot("plage_1", -6.0, 99.0, Vector3(0, 0, 1), "observer")
	_spot("plage_2", 8.0, 100.0, Vector3(0.2, 0, 1), "observer")
	_spot("colline_banc", 8.0, -81.6, Vector3(0, 0, 1), "assis")
	# les lieux qu'on ne rejoint pas par une rue proche (à plus de 12 m) : un petit chemin
	for nm in spots:
		var sp2: Dictionary = spots[nm]
		var node: String = str(sp2["node"])
		if (points[node] as Vector3).distance_to(sp2["pos"]) > 12.0:
			var np: String = _pt("lieu_" + str(nm), sp2["pos"])
			_link(np, node)
			sp2["node"] = np


func _yourte(nom: String) -> Dictionary:
	for y in L.yourtes:
		if str(y["nom"]) == nom:
			return y
	return {}


## Les petits meubles des lieux : les tabourets des djembés, le métier à tisser de Lune, la batterie
## et les tapis du garage, le comptoir et la terrasse du Café Feedback, un canapé de plus.
func _decor() -> void:
	var b := Kit.Batch.new()
	for k in range(3):
		var sp: Dictionary = spots["djembe_%d" % (k + 1)]
		b.cyl("bois", Transform3D(Basis(), (sp["pos"] as Vector3) - (sp["face"] as Vector3) * 0.05), 0.17, 0.2, 0.42, 10, true)
	if spots.has("tissage"):
		var t: Dictionary = spots["tissage"]
		var f: Vector3 = t["face"]
		var at: Vector3 = (t["pos"] as Vector3) + f * 0.7
		var bs := Basis(Vector3.UP, atan2(f.x, f.z))
		var xf := Transform3D(bs, at)
		for sx in [-0.65, 0.65]:
			b.box("bois_peint", xf * Transform3D(Basis(), Vector3(sx, 0.75, 0)), Vector3(0.07, 1.5, 0.07))
		b.box("bois_peint", xf * Transform3D(Basis(), Vector3(0, 1.45, 0)), Vector3(1.4, 0.07, 0.07))
		b.box("bois_peint", xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), Vector3(1.4, 0.07, 0.07))
		b.box("toile_rayee", xf * Transform3D(Basis(), Vector3(0, 0.9, 0)), Vector3(1.2, 0.8, 0.01))
		b.box("bois", xf * Transform3D(Basis(), Vector3(0, 0.75, -0.18)), Vector3(1.3, 0.05, 0.08))
		b.cyl("bois", Transform3D(Basis(), (t["pos"] as Vector3) - f * 0.05), 0.16, 0.18, 0.44, 10, true)
	# la batterie des Gouttières, et le tapis du garage
	var dk: Vector3 = (spots["garage_batterie"]["pos"] as Vector3)
	_drum_kit(b, Transform3D(Basis(Vector3.UP, -PI * 0.5), dk))
	var rug: Vector3 = G(79.0, -18.0)
	b.box("toile_rayee", Transform3D(Basis(), rug + Vector3.UP * 0.02), Vector3(3.6, 0.02, 7.5))
	# le comptoir du Café Feedback, la terrasse (deux tables rondes, des chaises)
	var cc: Vector3 = G(57.6, -25.0)
	b.box("planches_gris", Transform3D(Basis(), cc + Vector3.UP * 0.52), Vector3(1.6, 1.04, 0.55))
	b.box("bois", Transform3D(Basis(), cc + Vector3.UP * 1.07), Vector3(1.75, 0.06, 0.7))
	for k2 in range(3):
		b.cyl("chrome", Transform3D(Basis(), cc + Vector3(-0.5 + k2 * 0.5, 1.1, 0.05)), 0.04, 0.035, 0.1, 8, true)
	for tb in [Vector2(55.5, -23.0), Vector2(64.5, -23.0)]:
		var tp: Vector3 = G(tb.x, tb.y)
		b.cyl("fer", Transform3D(Basis(), tp), 0.05, 0.05, 0.72, 8, false)
		b.cyl("bois", Transform3D(Basis(), tp + Vector3.UP * 0.72), 0.45, 0.45, 0.04, 16, true)
		b.box("toile_rayee", Transform3D(Basis(), tp + Vector3.UP * 2.2), Vector3(2.2, 0.03, 2.2))
		b.tube("fer", tp + Vector3.UP * 0.72, tp + Vector3.UP * 2.2, 0.025, 6)
	for nm in ["cafe_terrasse_1", "cafe_terrasse_2", "cafe_terrasse_3"]:
		var sp3: Dictionary = spots[nm]
		var cp: Vector3 = sp3["pos"]
		var fc: Vector3 = sp3["face"]
		b.box("bois", Transform3D(Basis(Vector3.UP, atan2(fc.x, fc.z)), cp + Vector3.UP * 0.44), Vector3(0.45, 0.04, 0.42))
		b.box("bois", Transform3D(Basis(Vector3.UP, atan2(fc.x, fc.z)), cp + Vector3.UP * 0.72 - fc * 0.2), Vector3(0.45, 0.55, 0.04))
		for sx in [-0.19, 0.19]:
			for sz in [-0.17, 0.17]:
				b.tube("fer", cp + Basis(Vector3.UP, atan2(fc.x, fc.z)) * Vector3(sx, 0, sz), cp + Basis(Vector3.UP, atan2(fc.x, fc.z)) * Vector3(sx, 0.43, sz), 0.015, 4)
	Kit.couch(b, Transform3D(Basis(Vector3.UP, PI * 0.5), G(45.0, -28.0)), "toile_canape_2")
	b.commit(self, "Larsen_vie_decor")


## Une batterie (la grosse caisse, la caisse claire, deux toms, le tom basse, le charleston, deux
## cymbales, le tabouret) ; xf : le tabouret, le batteur regarde vers +z local.
func _drum_kit(b: Kit.Batch, xf: Transform3D) -> void:
	b.cyl("bois", xf * Transform3D(Basis(), Vector3(0, 0, 0)), 0.17, 0.2, 0.44, 10, true)
	b.cyl("bus_2", xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, 0.5)), 0.28, 0.28, 0.4, 18, true)
	b.cyl("peau", xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.3, 0.91)), 0.27, 0.27, 0.01, 18, true)
	b.cyl("bus_2", xf * Transform3D(Basis(), Vector3(-0.32, 0.55, 0.38)), 0.17, 0.17, 0.14, 14, true)
	b.cyl("bus_2", xf * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(-0.14, 0.72, 0.52)), 0.13, 0.13, 0.16, 14, true)
	b.cyl("bus_2", xf * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(0.16, 0.72, 0.52)), 0.14, 0.14, 0.17, 14, true)
	b.cyl("bus_2", xf * Transform3D(Basis(), Vector3(0.42, 0.1, 0.3)), 0.2, 0.2, 0.42, 14, true)
	for cy in [[-0.55, 0.95, 0.3, 0.17], [-0.38, 1.25, 0.72, 0.22], [0.48, 1.3, 0.75, 0.24]]:
		var cp := Vector3(float(cy[0]), 0, float(cy[2]))
		b.tube("chrome", xf * cp, xf * (cp + Vector3.UP * float(cy[1])), 0.012, 6)
		b.cyl("chrome", xf * Transform3D(Basis(Vector3.RIGHT, -0.15), cp + Vector3.UP * float(cy[1])), float(cy[3]), float(cy[3]) * 0.96, 0.008, 18, true)


# =================================================================== les habitants

## Les habitants : chacun rentre chez lui (sa porte : celle de sa yourte), et sort selon l'heure.
func spawn_npcs() -> void:
	if not habitants.is_empty() or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var yn: String = str(data.get("yourte", ""))
		var home: String = str(data.get("maison", ""))
		if door_of.has(yn):
			_pt(home, points[door_of[yn]])
			_link(home, door_of[yn])
			for nb in graph.get(door_of[yn], []):
				_link(home, str(nb))
		var start: String = home if points.has(home) else str(_streets[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V92: %d habitants sur l'Île de Larsen" % habitants.size())
	# les maisons des habitants : on recompte les propriétaires (maisons_v81)
	var mv: Node = main.get("maisons_v81")
	if mv != null and not bool(mv.get("inside")):
		mv.collect()


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func spot(nm: String) -> Dictionary:
	return spots.get(nm, {})


func spot_free(nm: String, who: Node) -> bool:
	var c: Variant = _claims.get(nm, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(nm: String, who: Node) -> void:
	_claims[nm] = who


func release_spot(nm: String, who: Node) -> void:
	if _claims.get(nm, null) == who:
		_claims.erase(nm)

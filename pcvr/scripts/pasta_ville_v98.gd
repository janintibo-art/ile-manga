extends Node3D
## V98 : la vie de l'Île Al Dente. Le Borgo des Coquillettes (six maisons de village, crépies de
## couleurs, de part et d'autre du chemin du temple ; la piazzetta, sa Grande Tablée sous la treille,
## son four à pain), la Barque-Maison du Capitaine Rigatoni (une grande barque retournée sur la plage,
## son mât, son drapeau, son trésor enterré), les rues (un graphe de points le long des chemins de
## l'île, du chemin en spirale du volcan, du ponton, du parvis et de la nef du temple), les lieux où
## l'on s'installe (l'autel, le pupitre, le chœur, les bancs du temple ; le Couvercle, la fontaine,
## les bannières ; la Grande Tablée, le four ; le séchoir, les champs, la Tomateraie, l'Oliveraie, le
## lac ; le belvédère et la louche de la Marmite ; la plage, le ponton…), les adeptes
## (pnj/pasta_habitants_v98.gd, pnj/pnj_pasta_v98.gd), qui vivent selon l'heure, et les passants.
## La quête « Le Grand Spaghetti boude » (journal_v56) : quand on pose le Plat de la Grande
## Réconciliation sur l'autel, le Grand Spaghetti se réveille et danse, une pluie de farfalle tombe
## dans le temple, et tous les adeptes crient « Ramen ! ».
## Le gestionnaire des lieux (hour, spot, spot_free, claim_spot, release_spot) : comme les autres villes.

const IleScript = preload("res://scripts/ile_pasta_v97.gd")
const Kit = preload("res://scripts/pasta_kit_v97.gd")
const AzurKit = preload("res://scripts/azur_kit_v56.gd")
const HABITANTS := "res://scripts/pnj/pasta_habitants_v98.gd"
const PNJ := "res://scripts/pnj/pnj_pasta_v98.gd"
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const QUETE := "pa_plat_sacre"

## Les maisons du Borgo : nom -> [x, z, largeur (façade), profondeur, couleur, volets, étages, toit]
## (repère île) ; la façade regarde le chemin du temple, la porte est au milieu.
const MAISONS := {
	"presbytere": [-30.8, 50.8, 7.0, 6.0, "creme", "bordeaux", [3.4, 2.8], "hip"],
	"soeurs": [-22.8, 55.8, 6.0, 5.5, "bleu", "blanc", [3.2, 2.6], "gable"],
	"ravioli": [-12.7, 62.3, 6.0, 5.0, "rose", "vert", [3.3], "gable"],
	"fusilli": [-4.7, 67.3, 5.6, 5.6, "jaune", "turquoise", [3.2, 2.7], "flat"],
	"famille": [-21.3, 75.7, 8.0, 6.0, "ocre", "vert", [3.4, 2.8], "gable"],
	"gardiens": [-31.2, 69.4, 6.0, 5.0, "saumon", "brun", [3.3], "gable"],
}
## La piazzetta du Borgo (la Grande Tablée, la treille, le four)
const PIAZZA := Vector2(-18.0, 88.0)
## La Barque-Maison du Capitaine : le centre, l'angle de la quille (radians)
const BARQUE := Vector2(52.0, 121.0)
const BARQUE_YAW: float = 0.55

var main: Node
var P: Node3D                             # pasta_v97 (l'île, le temple, le volcan)
var points: Dictionary = {}               # nom -> Vector3 (monde)
var graph: Dictionary = {}                # nom -> [voisins]
var spots: Dictionary = {}                # nom -> {pos, face, pose, node}
var habitants: Array = []
var by_id: Dictionary = {}
var crowd: Array = []                     # [figurant, heure de début, heure de fin, position]
var maisons: Dictionary = {}              # nom -> {at, face, door, w, d}
var tresor := Vector3.ZERO                # là où le Capitaine a enterré la Râpe d'Or
var _claims: Dictionary = {}
var _streets: Array = []
var _crowd_t: float = 0.0
var _crowd_spawned: bool = false
var _tick: float = 0.0
# la Grande Réconciliation
var fete: float = 0.0                     # secondes de fête qui restent
var _confettis: Array = []
var _cheer_i: int = 0
var _cheer_t: float = 0.0
var _plat: Node3D


func setup(main_node: Node, pasta: Node3D) -> void:
	main = main_node
	P = pasta
	name = "Pasta_ville_v98"


func G(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = P.ile.height(w.x, w.z)
	return w


func door_dir() -> Vector3:
	return Vector3(IleScript.PORTE_DIR.x, 0, IleScript.PORTE_DIR.y).normalized()


# =================================================================== construction

func build() -> void:
	var t0: int = Time.get_ticks_msec()
	_plan_maisons()
	_rues()
	_portes()
	_lieux()
	_decor()
	print("ILE_MANGA_V98: Île Al Dente : %d points, %d lieux, %d maisons (%d ms)" % [points.size(), spots.size(), maisons.size(), Time.get_ticks_msec() - t0])


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


## Une rue : des points tous les ~step m le long d'une ligne brisée (repère île) ; un point proche
## d'un point existant (< 3 m) se confond avec lui (les croisements).
func _rue(id: String, pts: Array, step: float = 8.0, y_fixe: float = -1000.0) -> Array:
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
				var w: Vector3 = G(p.x, p.y)
				if y_fixe > -999.0:
					w.y = y_fixe
				nm = _pt("st_%s_%d" % [id, names.size()], w)
			if names.is_empty() or names[-1] != nm:
				names.append(nm)
	for j in range(names.size() - 1):
		_link(names[j], names[j + 1])
	return names


## Les deux bouts d'une rue rejoignent le point de rue le plus proche d'une autre rue (s'il n'y est
## pas déjà confondu), à moins de 14 m.
func _join(names: Array) -> void:
	for end in [names[0], names[-1]]:
		var best: String = ""
		var bd: float = 14.0
		for s in _streets:
			if names.has(s):
				continue
			var d: float = (points[s] as Vector3).distance_to(points[end])
			if d < bd:
				bd = d
				best = str(s)
		if best != "":
			_link(str(end), best)


func nearest_street(p: Vector3, prefix: String = "") -> String:
	var best: String = ""
	var bd: float = INF
	for s in _streets:
		if prefix != "" and not str(s).begins_with(prefix):
			continue
		var d: float = (points[s] as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = str(s)
	return best


## Le point du chemin du temple le plus proche (repère île), pour tourner les façades vers lui.
static func _closest_on(lane: Array, p: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var bd: float = INF
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var q: Vector2 = a + ab * t
		if q.distance_to(p) < bd:
			bd = q.distance_to(p)
			best = q
	return best


func _plan_maisons() -> void:
	var lane: Array = IleScript.PATHS["temple"]
	for nm in MAISONS:
		var e: Array = MAISONS[nm]
		var c := Vector2(float(e[0]), float(e[1]))
		var q: Vector2 = _closest_on(lane, c)
		var f: Vector2 = (q - c).normalized()
		var d: float = float(e[3])
		var front: Vector2 = c + f * d * 0.5
		# le pied de la maison : le plus bas du terrain sous elle (le reste s'enterre)
		var y: float = INF
		for sx in [-0.5, 0.0, 0.5]:
			for sz in [-0.5, 0.0, 0.5]:
				var side := Vector2(-f.y, f.x)
				var s: Vector2 = c + side * float(e[2]) * sx + f * d * sz
				y = minf(y, P.ile.height(IleScript.W(s.x, s.y).x, IleScript.W(s.x, s.y).z))
		var at: Vector3 = IleScript.W(front.x, front.y, y)
		var door: Vector3 = IleScript.W(front.x + f.x * 1.0, front.y + f.y * 1.0)
		door.y = P.ile.height(door.x, door.z)
		maisons[nm] = {"at": at, "face": Vector3(f.x, 0, f.y), "door": door, "w": float(e[2]), "d": d, "c": c}


func _rues() -> void:
	# --- les chemins de l'île
	var lanes: Array = []
	for k in IleScript.PATHS:
		lanes.append(_rue("ch_" + str(k), IleScript.PATHS[k], 8.0))
	# le carrefour : les chemins y arrivent chacun de son côté ; on relie leurs bouts
	for ln in lanes:
		_join(ln)
	# --- le chemin en spirale, jusqu'au belvédère
	var sp: Array = IleScript.spiral_lane()
	sp.insert(0, (IleScript.PATHS["volcan"] as Array)[-1])
	_rue("spirale", sp, 10.0)
	var be: Vector3 = P.ile.spiral_end
	_pt("belvedere_c", be)
	_link("belvedere_c", nearest_street(be, "st_spirale"))
	# --- le parvis : de l'entrée (entre la fourchette et la cuillère) à la porte du temple
	var door: Vector3 = door_dir()
	var side: Vector3 = door.cross(Vector3.UP)
	var R: float = IleScript.PASSOIRE_R
	var tc: Vector3 = P.temple_c
	var y: float = float(IleScript.PADS["temple"][3])
	var p0: Vector3 = tc + door * (R + 3.8)
	var pv := {"parvis_porte": tc + door * (R + 3.4), "parvis_a": p0 + door * 4.0, "parvis_g": p0 + door * 10.0 - side * 4.3,
		"parvis_d": p0 + door * 10.0 + side * 4.3, "parvis_b": p0 + door * 16.0, "parvis_entree": p0 + door * 22.5}
	for k2 in pv:
		var w: Vector3 = pv[k2]
		w.y = y
		_pt("st_" + str(k2), w)
	_link("st_parvis_porte", "st_parvis_a")
	_link("st_parvis_a", "st_parvis_g")
	_link("st_parvis_a", "st_parvis_d")
	_link("st_parvis_g", "st_parvis_b")
	_link("st_parvis_d", "st_parvis_b")
	_link("st_parvis_b", "st_parvis_entree")
	var tend: Vector2 = (IleScript.PATHS["temple"] as Array)[-1]
	_link("st_parvis_entree", nearest_street(G(tend.x, tend.y), "st_ch_temple"))
	# --- la nef : du seuil à l'autel, par l'allée du milieu (le sol du temple)
	var au: Vector3 = P._autel_at
	var fy: float = P.temple_floor
	var nef: Array = [["nef_seuil", 22.2], ["nef_1", 17.0], ["nef_2", 12.0], ["nef_rang_3", 7.4], ["nef_rang_2", 5.5], ["nef_rang_1", 3.6], ["nef_choeur", 1.9]]
	var prev: String = "st_parvis_porte"
	for e in nef:
		var q: Vector3 = au + door * float(e[1])
		q.y = fy
		_pt("st_" + str(e[0]), q)
		_link(prev, "st_" + str(e[0]))
		prev = "st_" + str(e[0])
	# --- le Borgo : un tour de la piazzetta (la Grande Tablée au milieu), relié aux chemins
	var pz: Vector2 = PIAZZA
	var ring: Array = []
	for k3 in range(10):
		var a: float = TAU * k3 / 10.0
		ring.append(pz + Vector2(cos(a) * 6.8, sin(a) * 4.0))
	ring.append(ring[0])
	_rue("piazza", ring, 30.0)
	_join(_rue("borgo_nord", [pz + Vector2(2.0, -4.0), Vector2(-14.0, 72.0)], 6.0))
	_join(_rue("borgo_est", [pz + Vector2(6.8, 0.0), Vector2(-3.0, 92.0)], 6.0))
	# --- la plage : le long du sable, jusqu'à la Barque-Maison ; le ponton
	_join(_rue("plage", [Vector2(22.0, 149.0), Vector2(8.0, 144.0), Vector2(-4.0, 140.0)], 7.0))
	_rue("plage_est", [Vector2(22.0, 149.0), Vector2(34.0, 140.0), Vector2(46.0, 131.0), Vector2(BARQUE.x + 3.0, BARQUE.y + 5.5)], 7.0)
	var dy: float = 1.0
	var bt: Node = main.get("boat_v29")
	if bt != null and bt.get("DECK_Y") != null:
		dy = float(bt.DECK_Y)
	_rue("ponton", [Vector2(22.0, 153.0), Vector2(22.0, 160.0), Vector2(22.0, 166.0), Vector2(22.0, 171.0)], 6.0, dy)
	_link("st_ponton_0", nearest_street(G(22.0, 149.0), "st_ch_plage"))
	# --- les champs, l'Oliveraie, le lac
	_join(_rue("champs", [Vector2(-28.0, 104.0), Vector2(-44.0, 101.0), Vector2(-58.0, 99.0), Vector2(-68.0, 104.0)], 8.0))
	_join(_rue("oliveraie", [Vector2(58.0, 30.0), Vector2(62.0, 46.0), Vector2(64.0, 56.0)], 8.0))


## Les portes : celle de chaque maison du Borgo et celle de la Barque-Maison.
func _portes() -> void:
	for nm in maisons:
		var m: Dictionary = maisons[nm]
		var pn: String = _pt("porte_" + str(nm), m["door"])
		_link(pn, nearest_street(m["door"]))
	var bd: Vector3 = _barque_door()
	_pt("porte_barque", bd)
	_link("porte_barque", nearest_street(bd, "st_plage_est"))


func _barque_door() -> Vector3:
	var ax := Vector2(cos(BARQUE_YAW), sin(BARQUE_YAW))
	var nrm := Vector2(-ax.y, ax.x)
	var q: Vector2 = BARQUE + nrm * 2.6
	return G(q.x, q.y)


## Un lieu (repère monde) : vers où l'on regarde, la pose ; via : le point par lequel on y arrive
## (sinon le point de rue le plus proche, en ligne droite).
func _spot_w(nm: String, p: Vector3, face: Vector3, pose: String, via: String = "") -> void:
	var f: Vector3 = Vector3(face.x, 0, face.z).normalized() if Vector2(face.x, face.z).length() > 0.01 else Vector3(0, 0, 1)
	var node: String = via if via != "" else nearest_street(p)
	if (points[node] as Vector3).distance_to(p) > 1.5:
		var np: String = _pt("lieu_" + nm, p)
		_link(np, node)
		node = np
	spots[nm] = {"pos": p, "face": f, "pose": pose, "node": node}


func _spot(nm: String, x: float, z: float, face: Vector3, pose: String, via: String = "") -> void:
	_spot_w(nm, G(x, z), face, pose, via)


func _lieux() -> void:
	var door: Vector3 = door_dir()
	var side: Vector3 = door.cross(Vector3.UP)
	var R: float = IleScript.PASSOIRE_R
	var tc: Vector3 = P.temple_c
	var au: Vector3 = P._autel_at
	var fy: float = P.temple_floor
	var y: float = float(IleScript.PADS["temple"][3])
	var p0: Vector3 = tc + door * (R + 3.8)
	p0.y = y
	# --- le temple : l'autel, le pupitre, le chœur, les bancs (en trois arcs face à l'autel)
	var at := func(v: Vector3) -> Vector3: return Vector3(v.x, fy, v.z)
	_spot_w("autel", at.call(au + door * 1.45), -door, "prier", "st_nef_choeur")
	_spot_w("pupitre", at.call(au + side * 2.9 + door * 1.6), door, "enseigner", "st_nef_choeur")
	_spot_w("choeur_1", at.call(au + door * 2.4 - side * 2.3), door, "acclamer", "st_nef_choeur")
	_spot_w("choeur_2", at.call(au + door * 2.4 + side * 2.6), door, "acclamer", "st_nef_choeur")
	var n: int = 1
	for row in range(3):
		var rr: float = 4.2 + row * 1.9
		for k in [-1, 1, -2, 2]:
			var dirb: Vector3 = door.rotated(Vector3.UP, k * 0.36).normalized()
			var bp: Vector3 = at.call(au + dirb * rr)
			var tang: Vector3 = Vector3.UP.cross(dirb).normalized()
			var seat: Vector3 = bp + tang * (0.45 if k < 0 else -0.45)
			var front: Vector3 = seat - dirb * 0.65
			var nm: String = _pt("lieu_banc_%d_avant" % n, front)
			_link(nm, "st_nef_rang_%d" % (row + 1))
			spots["banc_%d" % n] = {"pos": seat, "face": -dirb, "pose": "assis", "node": nm}
			n += 1
	# --- le parvis : le Couvercle (Macaroni), le balai, la fontaine, les bannières, la statue
	var g: Vector3 = P._gong_at
	_spot_w("gong", Vector3(g.x, y, g.z) + door * 1.2 + side * 3.0, door, "bras_croises", "st_parvis_porte")
	_spot_w("parvis_balai", p0 + door * 6.5 - side * 2.6, side, "peindre", "st_parvis_a")
	var fo: Vector3 = Vector3(P._fontaine_at.x, y, P._fontaine_at.z)
	_spot_w("fontaine_1", fo + side * 3.3 - door * 0.6, -side, "observer", "st_parvis_d")
	_spot_w("fontaine_2", fo - side * 3.3 + door * 0.8, side, "observer", "st_parvis_g")
	_spot_w("fontaine_3", fo + door * 3.3, -door, "observer", "st_parvis_b")
	var bn: Vector3 = p0 + door * 5.0 - side * 7.2
	_spot_w("banniere", Vector3(bn.x, y, bn.z) + side * 1.5, -side, "peindre", "st_parvis_a")
	_spot_w("statue", p0 + door * 14.8, door, "enseigner", "st_parvis_b")
	_spot_w("statue_2", p0 + door * 19.5 + side * 3.6, side, "observer", "st_parvis_b")
	_spot_w("effigie_mesure", p0 + door * 4.5 + side * 2.4, -door, "observer", "st_parvis_a")
	_spot_w("parvis_1", p0 + door * 12.5 - side * 2.0, door, "debout", "st_parvis_g")
	_spot_w("parvis_2", p0 + door * 18.0 - side * 2.4, -door, "observer", "st_parvis_b")
	# --- le Borgo : la Grande Tablée (douze places), le four, les bancs, la musique du soir
	var pz: Vector2 = PIAZZA
	var xs: Array = [-3.3, -2.0, -0.7, 0.7, 2.0, 3.3]
	var t: int = 1
	for sz in [-1.0, 1.0]:
		for x in xs:
			var sp: Vector2 = pz + Vector2(float(x), sz * 0.95)
			var via: String = nearest_street(G(pz.x + float(x), pz.y + sz * 4.0), "st_piazza")
			var front2: Vector3 = G(pz.x + float(x), pz.y + sz * 1.7)
			var nm2: String = _pt("lieu_tablee_%d_dos" % t, front2)
			_link(nm2, via)
			spots["tablee_%d" % t] = {"pos": G(sp.x, sp.y), "face": Vector3(0, 0, -sz), "pose": "assis", "node": nm2}
			t += 1
	_spot("four", pz.x - 7.05, pz.y + 0.2, Vector3(-1, 0, 0), "cuisiner")
	_spot("piazza_banc_1", pz.x + 2.5, pz.y - 6.3, Vector3(0, 0, 1), "assis")
	_spot("piazza_banc_2", pz.x - 2.5, pz.y - 6.3, Vector3(0, 0, 1), "assis")
	_spot("piazza_banc_3", pz.x + 1.0, pz.y + 6.4, Vector3(0, 0, -1), "assis")
	_spot("piazza_banc_4", pz.x - 3.0, pz.y + 6.4, Vector3(0, 0, -1), "assis")
	_spot("piazza_violon", pz.x + 5.6, pz.y - 1.2, Vector3(-1, 0, 0.2), "violon")
	_spot("piazza_tambour", pz.x + 5.7, pz.y + 1.3, Vector3(-1, 0, -0.2), "tambour")
	_spot("piazza_danse_1", pz.x + 4.0, pz.y + 3.6, Vector3(-0.2, 0, -1), "danse")
	_spot("piazza_danse_2", pz.x + 3.2, pz.y - 3.8, Vector3(0.2, 0, 1), "danse")
	# --- le séchoir à pâtes : la table des nids de tagliatelles, l'allée entre les séchoirs
	var sc: Array = IleScript.PADS["sechoir"]
	var scb := Basis(Vector3.UP, 0.25)
	var tb: Vector2 = Vector2(float(sc[0]) + 0.5, float(sc[1]) + 6.5)
	var stand: Vector3 = scb * Vector3(0, 0, -1.05)
	_spot("sechoir_1", tb.x + stand.x, tb.y + stand.z, scb * Vector3(0, 0, 1), "cuisiner")
	_spot("sechoir_2", float(sc[0]) - 4.5, float(sc[1]) - 0.2, scb * Vector3(0, 0, -1), "peindre")
	_spot("sechoir_3", float(sc[0]) + 4.5, float(sc[1]) - 0.2, scb * Vector3(0, 0, -1), "peindre")
	# --- les champs, l'Oliveraie, la Tomateraie, le lac
	_spot("champ_1", -60.0, 99.0, Vector3(-1, 0, 0.2), "jardiner")
	_spot("champ_2", -68.0, 106.0, Vector3(-1, 0, -0.3), "jardiner")
	_spot("champ_3", -64.0, 94.0, Vector3(-1, 0, 0.1), "jardiner")
	_spot("oliviers", 65.0, 58.0, Vector3(0.6, 0, 0.8), "jardiner")
	var tm: Array = IleScript.PADS["tomateraie"]
	_spot("tomates_1", float(tm[0]) - 3.0, float(tm[1]) + 1.5, Vector3(1, 0, 0.3), "jardiner")
	_spot("tomates_2", float(tm[0]) + 3.5, float(tm[1]) - 2.5, Vector3(-0.5, 0, 1), "jardiner")
	_spot("tomates_3", float(tm[0]) + 1.0, float(tm[1]) + 4.0, Vector3(0, 0, -1), "jardiner")
	_spot("lac_rive", 89.0, 23.5, Vector3(0.75, 0, -0.65), "observer")
	# --- la Marmite : le belvédère, la louche géante
	var be: Vector3 = P.ile.spiral_end
	var cc: Vector3 = P.cratere_c
	var to_c: Vector3 = Vector3(cc.x - be.x, 0, cc.z - be.z).normalized()
	var vside: Vector3 = to_c.cross(Vector3.UP)
	var bv: Vector3 = be + to_c * 1.5 - vside * 1.2
	bv.y = P.ile.height(bv.x, bv.z)
	_spot_w("belvedere", bv, to_c, "bras_croises", "belvedere_c")
	var lo: Vector3 = P._louche_at - vside * 1.4 - to_c * 0.7
	lo.y = P.ile.height(lo.x, lo.z)
	_spot_w("louche_geante", lo, (P._louche_at - lo), "cuisiner", "belvedere_c")
	# --- la plage : la Barque-Maison, la sieste, le château de sable, le bord de l'eau, le ponton
	var bd: Vector3 = _barque_door()
	var ax := Vector3(cos(BARQUE_YAW), 0, sin(BARQUE_YAW))
	var nrm := Vector3(-ax.z, 0, ax.x)
	var bs: Vector3 = bd + ax * 2.0 + nrm * 0.4
	bs.y = P.ile.height(bs.x, bs.z)
	_spot_w("barque", bs, nrm, "assis", "porte_barque")
	var bs2: Vector3 = bd + ax * 3.4 + nrm * 0.9
	bs2.y = P.ile.height(bs2.x, bs2.z)
	_spot_w("barque_2", bs2, (bs - bs2).normalized() + nrm, "assis", "porte_barque")
	_spot("plage_sieste", -2.0, 142.6, Vector3(0, 0, 1), "allonge")
	_spot("plage_chateau", 6.0, 140.0, Vector3(0.3, 0, 1), "jardiner")
	_spot("plage_bord", 13.0, 145.5, Vector3(0, 0, 1), "observer")
	_spot("plage_bord_2", 30.0, 142.0, Vector3(0.2, 0, 1), "observer")
	var dyk: float = (points["st_ponton_3"] as Vector3).y
	_spot_w("ponton_peche", IleScript.W(22.85, 170.5, dyk), Vector3(1, 0, 0), "pecher", "st_ponton_3")
	_spot_w("ponton_2", IleScript.W(21.2, 165.0, dyk), Vector3(-1, 0, 0.3), "observer", "st_ponton_2")
	# la Râpe d'Or : « là où l'ombre du mât touche la mer à midi », entre la barque et l'eau
	var mast: Vector2 = BARQUE + Vector2(nrm.x, nrm.z) * 4.6 + Vector2(ax.x, ax.z) * 3.0
	var dir := Vector2(0.25, 1.0).normalized()
	var q: Vector2 = mast
	for k2 in range(60):
		var nq: Vector2 = q + dir * 0.5
		if P.ile.height(IleScript.W(nq.x, nq.y).x, IleScript.W(nq.x, nq.y).z) < 0.9:
			break
		q = nq
	tresor = G(q.x, q.y)
	P.objets["tresor"] = tresor
	P.objets["borgo"] = G(pz.x, pz.y)
	P.objets["barque"] = bd
	P.objets["mamma"] = (spots["sechoir_1"]["pos"] as Vector3)


# =================================================================== le décor

func _decor() -> void:
	var az := AzurKit.new()
	az.setup(self, main.get("temps_v56"))
	az.rng.seed = 9898
	# --- les maisons du Borgo (crépi de couleur, volets, tuiles ; pas de visite : pas_v81)
	for nm in maisons:
		var m: Dictionary = maisons[nm]
		var f: Vector3 = m["face"]
		var e: Array = MAISONS[nm]
		var xf := Transform3D(Basis(Vector3.UP, atan2(-f.x, -f.z)), m["at"])
		az.building(xf, {"w": float(e[2]), "d": float(e[3]), "floors": e[6], "color": str(e[4]), "volets": str(e[5]),
			"roof": str(e[7]), "lit": 0.6, "pas_v81": true})
		# des fenêtres au dos et sur les côtés (on voit les maisons de partout : du chemin, de la piazzetta)
		var w2: float = float(e[2])
		var d2: float = float(e[3])
		var nb: int = maxi(1, int((w2 - 1.0) / 2.6))
		for k5 in range(nb):
			var bx: float = -w2 / 2 + (k5 + 0.5) * w2 / nb
			az.window(xf * Transform3D(Basis(Vector3.UP, PI), Vector3(bx, 1.75, d2 + 0.0)), 0.85, 1.25, str(e[5]), az.rng.randf() < 0.5, az.rng.randf() < 0.3)
		for sx2 in [-1.0, 1.0]:
			az.window(xf * Transform3D(Basis(Vector3.UP, -sx2 * PI * 0.5), Vector3(sx2 * w2 / 2, 1.75, d2 * 0.5)), 0.8, 1.2, str(e[5]), az.rng.randf() < 0.5, az.rng.randf() < 0.4)
		# un pot de basilic de chaque côté de la porte
		for sx in [-1.0, 1.0]:
			var pp: Vector3 = xf * Vector3(sx * 1.25, 0, -0.45)
			pp.y = P.ile.height(pp.x, pp.z)
			az.planter(pp, 0.28)
		P._avoid.append([Vector2((m["at"] as Vector3).x - f.x * float(e[3]) * 0.5, (m["at"] as Vector3).z - f.z * float(e[3]) * 0.5), maxf(float(e[2]), float(e[3])) * 0.75 + 1.0])
	# le petit observatoire de la Professeure Fusilli, sur son toit plat
	var fu: Dictionary = maisons["fusilli"]
	var fh: float = 3.2 + 2.7
	var fc: Vector3 = (fu["at"] as Vector3) - (fu["face"] as Vector3) * float(fu["d"]) * 0.5 + Vector3.UP * (fh + 0.08)
	var b := Kit.Batch.new()
	b.cyl("calcaire", Transform3D(Basis(), fc), 1.3, 1.3, 1.2, 24, true)
	b.sphere("cuivre", fc + Vector3.UP * 1.2, 1.32, 1.0, 10, 24)
	b.tube("fer", fc + Vector3(0.3, 1.9, 0.2), fc + Vector3(1.4, 2.8, 0.9), 0.12, 10)
	# --- la piazzetta : la Grande Tablée, la nappe à carreaux, les bancs, la treille, le four
	_tablee(b, az)
	# --- la Barque-Maison du Capitaine Rigatoni
	_barque(b)
	b.commit(self, "Borgo_et_barque")
	az.commit()


func _tablee(b: Kit.Batch, az: AzurKit) -> void:
	var pz: Vector2 = PIAZZA
	var c: Vector3 = G(pz.x, pz.y)
	# le sol de la piazzetta : des dalles, posées sur le terrain
	b.box("dalles", Transform3D(Basis(), c + Vector3.UP * 0.01), Vector3(13.0, 0.08, 7.6))
	# la longue table, sa nappe à carreaux, ses deux bancs
	b.box("bois", Transform3D(Basis(), c + Vector3.UP * 0.74), Vector3(8.4, 0.07, 1.15))
	b.box("nappe", Transform3D(Basis(), c + Vector3.UP * 0.785), Vector3(8.6, 0.02, 1.35))
	for sx in [-1.0, 1.0]:
		b.box("nappe", Transform3D(Basis(), c + Vector3(sx * 4.3, 0.62, 0)), Vector3(0.02, 0.3, 1.35))
		for sz in [-1.0, 1.0]:
			b.box("nappe", Transform3D(Basis(), c + Vector3(0, 0.62, sz * 0.675)), Vector3(8.6, 0.3, 0.02))
	for lx in [-3.9, 0.0, 3.9]:
		for lz in [-0.45, 0.45]:
			b.box("bois", Transform3D(Basis(), c + Vector3(lx, 0.37, lz)), Vector3(0.09, 0.74, 0.09))
	for sz2 in [-1.0, 1.0]:
		b.box("bois", Transform3D(Basis(), c + Vector3(0, 0.44, sz2 * 0.95)), Vector3(8.0, 0.06, 0.34))
		for lx2 in [-3.7, 0.0, 3.7]:
			b.box("bois", Transform3D(Basis(), c + Vector3(lx2, 0.21, sz2 * 0.95)), Vector3(0.08, 0.42, 0.3))
	P._col(Transform3D(Basis(), c + Vector3.UP * 0.4), Vector3(8.4, 0.8, 1.2))
	# sur la table : des plats de pâtes, des corbeilles de pain, des carafes d'eau
	var rng := RandomNumberGenerator.new()
	rng.seed = 9811
	for k in range(5):
		var pp: Vector3 = c + Vector3(-3.4 + k * 1.7, 0.8, rng.randf_range(-0.15, 0.15))
		b.cyl("calcaire", Transform3D(Basis(), pp), 0.24, 0.2, 0.04, 18, true)
		for j in range(14):
			var pts: Array = []
			var a0: float = rng.randf() * TAU
			var r0: float = rng.randf_range(0.03, 0.18)
			for s in range(8):
				var tt: float = float(s) / 7.0
				var aa: float = a0 + tt * TAU * 1.2
				var rr: float = r0 * (1.0 - tt * 0.5) + 0.02
				pts.append(pp + Vector3(cos(aa) * rr, 0.03 + tt * 0.1 * (1.0 - rr * 3.0), sin(aa) * rr))
			b.noodle("pates", pts, 0.006, [], 4)
		b.sphere("boulette", pp + Vector3(0.03, 0.12, 0.02), 0.05, 0.9, 5, 8)
		if k % 2 == 0:
			var bq: Vector3 = pp + Vector3(0.8, 0.0, 0.3 * (1.0 if k % 4 == 0 else -1.0))
			b.cyl("bois_clair", Transform3D(Basis(), bq), 0.16, 0.13, 0.09, 12, true)
			for j2 in range(3):
				b.sphere("pates_seches", bq + Vector3(-0.06 + j2 * 0.06, 0.1, 0), 0.06, 0.6, 5, 8, Basis(Vector3.UP, j2))
	# la treille : six poteaux, des poutres, un lattis couvert de feuilles, des guirlandes de lampions
	var posts: Array = []
	for px in [-4.8, 0.0, 4.8]:
		for pz2 in [-2.7, 2.7]:
			var pp2: Vector3 = c + Vector3(px, 0, pz2)
			pp2.y = P.ile.height(pp2.x, pp2.z)
			b.cyl("bois", Transform3D(Basis(), pp2), 0.09, 0.1, 2.9, 8, true)
			P._col_cyl(pp2, 0.12, 2.9)
			posts.append(pp2)
	var top: float = c.y + 2.9
	# les ceps de la treille (des tomates grimpantes) qui s'enroulent autour des poteaux
	for pp3 in posts:
		var cane: Array = []
		for s3 in range(14):
			var t3: float = float(s3) / 13.0
			cane.append((pp3 as Vector3) + Vector3(cos(t3 * 9.0) * 0.13, t3 * 2.95, sin(t3 * 9.0) * 0.13))
		b.noodle("cep", cane, 0.03, [], 5)
	for pz3 in [-2.7, 2.7]:
		b.box("bois", Transform3D(Basis(), Vector3(c.x, top, c.z + pz3)), Vector3(10.0, 0.16, 0.16))
	for k2 in range(9):
		var lx3: float = -4.8 + k2 * 1.2
		b.box("bois", Transform3D(Basis(), Vector3(c.x + lx3, top + 0.12, c.z)), Vector3(0.08, 0.08, 6.0))
	# les feuilles de la treille (des petits losanges verts, par grappes)
	for k3 in range(900):
		var edge: bool = k3 % 5 == 0
		var lp := Vector3(c.x + rng.randf_range(-5.1, 5.1), top + 0.16 + rng.randf_range(-0.08, 0.16), c.z + rng.randf_range(-3.0, 3.0))
		if edge:
			# des feuilles qui retombent le long des poutres
			lp = Vector3(c.x + rng.randf_range(-5.0, 5.0), top - rng.randf_range(0.0, 0.7), c.z + (2.75 if k3 % 2 == 0 else -2.75) + rng.randf_range(-0.15, 0.15))
		var s: float = rng.randf_range(0.2, 0.36)
		var ang: float = rng.randf() * TAU
		var u := Vector3(cos(ang), 0, sin(ang)) * s
		var v := Vector3(-sin(ang), rng.randf_range(-0.3, 0.3), cos(ang)) * s * 0.7
		if edge:
			u = Vector3(cos(ang) * s, 0, 0)
			v = Vector3(0, s * 0.8, rng.randf_range(-0.1, 0.1))
		var lv: float = rng.randf_range(0.7, 1.0)
		var col: Color = Color(lv, lv * rng.randf_range(0.95, 1.05), lv)
		b.tri("feuille", [lp - u, lp + v, lp + u], [Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0, 0.5), Vector2(0.5, 0), Vector2(1, 0.5)], [col, col, col])
		b.tri("feuille", [lp - u, lp + u, lp - v], [Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0.5, 1)], [col, col, col])
	# des grappes de tomates-cerises qui pendent (la treille est une tomate grimpante !)
	for k4 in range(26):
		var gp := Vector3(c.x + rng.randf_range(-4.6, 4.6), top - 0.05, c.z + rng.randf_range(-2.6, 2.6))
		for j3 in range(4):
			b.sphere("tomate", gp + Vector3(rng.randf_range(-0.06, 0.06), -0.06 - j3 * 0.06, rng.randf_range(-0.06, 0.06)), 0.035, 1.0, 5, 8)
	# les lampions, en guirlande d'un poteau à l'autre
	for k5 in range(posts.size()):
		var a: Vector3 = (posts[k5] as Vector3) + Vector3.UP * 2.7
		for k6 in range(k5 + 1, posts.size()):
			var bb: Vector3 = (posts[k6] as Vector3) + Vector3.UP * 2.7
			if a.distance_to(bb) > 5.0:
				continue
			for j4 in range(5):
				var tt2: float = (j4 + 0.5) / 5.0
				var lp2: Vector3 = a.lerp(bb, tt2) - Vector3.UP * sin(tt2 * PI) * 0.35
				b.sphere("lampe", lp2, 0.07, 1.1, 5, 8)
	P._light(c + Vector3.UP * 2.4, Color(1.0, 0.75, 0.45), 2.2, 11.0, true)
	P._light(c + Vector3(-3.5, 2.4, 0), Color(1.0, 0.72, 0.42), 1.2, 7.0, true)
	P._light(c + Vector3(3.5, 2.4, 0), Color(1.0, 0.72, 0.42), 1.2, 7.0, true)
	# le four à pain : un socle de pierre, une coupole de briques, une bouche, une cheminée
	var ov: Vector3 = G(pz.x - 8.6, pz.y + 0.2)
	b.box("moellons", Transform3D(Basis(), ov + Vector3.UP * 0.5), Vector3(2.6, 1.0, 2.6))
	b.sphere("terre_cuite", ov + Vector3.UP * 1.0, 1.15, 0.85, 8, 18)
	b.box("terre_cuite", Transform3D(Basis(), ov + Vector3(0.95, 1.35, 0)), Vector3(0.5, 0.75, 0.9))
	b.box("suie", Transform3D(Basis(), ov + Vector3(1.21, 1.32, 0)), Vector3(0.02, 0.5, 0.6))
	b.cyl("terre_cuite", Transform3D(Basis(), ov + Vector3(-0.45, 1.6, 0)), 0.16, 0.2, 1.4, 10, true)
	P._col(Transform3D(Basis(), ov + Vector3.UP * 1.0), Vector3(2.6, 2.0, 2.6))
	var fl: CPUParticles3D = P._fire(ov + Vector3(0.95, 1.12, 0), 0.18, 22)
	fl.name = "Four_du_Borgo"
	P._light(ov + Vector3(1.4, 1.4, 0), Color(1.0, 0.55, 0.25), 1.6, 6.0, false)
	P._avoid.append([Vector2(c.x, c.z), 9.0])
	P._avoid.append([Vector2(ov.x, ov.z), 2.5])
	# les bancs autour de la piazzetta
	for e in [[2.5, -6.3, 1.0], [-2.5, -6.3, 1.0], [1.0, 6.4, -1.0], [-3.0, 6.4, -1.0]]:
		var bp: Vector3 = G(pz.x + float(e[0]), pz.y + float(e[1]))
		var fz: float = float(e[2])
		az.bench(Transform3D(Basis(Vector3.UP, 0.0 if fz > 0.0 else PI), bp))
	# un réverbère à chaque coin de la piazzetta
	for e2 in [[-6.6, -4.2], [6.6, -4.2], [6.6, 4.2], [-6.6, 4.2]]:
		az.lamppost(G(pz.x + float(e2[0]), pz.y + float(e2[1])), 0.0, true, 3.2)


## La Barque-Maison : une grande barque retournée, la coque en planches goudronnées, une porte sur le
## côté, deux hublots, une cheminée de fer ; le mât, son drapeau (une fourchette et une cuillère
## croisées), un hamac, des casiers, des filets.
func _barque(b: Kit.Batch) -> void:
	var c: Vector3 = G(BARQUE.x, BARQUE.y)
	var low: float = c.y
	for k in range(9):
		var a: float = TAU * k / 9.0
		var q: Vector2 = BARQUE + Vector2(cos(a), sin(a)) * 3.5
		low = minf(low, P.ile.height(IleScript.W(q.x, q.y).x, IleScript.W(q.x, q.y).z))
	var base := Vector3(c.x, low - 0.2, c.z)
	var ax := Vector3(cos(BARQUE_YAW), 0, sin(BARQUE_YAW))
	var nrm := Vector3(-ax.z, 0, ax.x)
	var yaw: float = atan2(ax.x, ax.z)
	var L: float = 10.0
	var W: float = 4.4
	var H: float = 3.0
	# la coque : des bordages (des bandes de planches) qui suivent la forme d'une barque à l'envers
	var n_u: int = 26
	var n_v: int = 10
	var pt := func(u: float, v: float) -> Vector3:
		# u : de la proue (-1) à la poupe (+1) ; v : d'un bord (-1) à l'autre (+1), en passant par la quille
		var taper: float = sqrt(maxf(1.0 - pow(absf(u), 2.4), 0.0))
		var half: float = W * 0.5 * maxf(taper, 0.08)
		var x: float = v * half
		var y: float = (1.0 - v * v) * H * (0.55 + 0.45 * taper) + 0.2
		var z: float = u * L * 0.5
		return base + ax * z + nrm * x + Vector3.UP * y
	for i in range(n_u):
		for j in range(n_v):
			var u0: float = lerpf(-1.0, 1.0, float(i) / n_u)
			var u1: float = lerpf(-1.0, 1.0, float(i + 1) / n_u)
			var v0: float = lerpf(-1.0, 1.0, float(j) / n_v)
			var v1: float = lerpf(-1.0, 1.0, float(j + 1) / n_v)
			var p00: Vector3 = pt.call(u0, v0)
			var p10: Vector3 = pt.call(u1, v0)
			var p11: Vector3 = pt.call(u1, v1)
			var p01: Vector3 = pt.call(u0, v1)
			var nn: Vector3 = (p10 - p00).cross(p01 - p00).normalized()
			var mid: Vector3 = (p00 + p11) * 0.5
			if nn.dot(mid - (base + Vector3.UP * 0.8)) < 0.0:
				nn = -nn
			var key: String = "coque" if j % 2 == 0 else "coque_b"
			b.quad_n(key, [p00, p10, p11, p01], [nn, nn, nn, nn], [Vector2(u0 * 5.0, v0), Vector2(u1 * 5.0, v0), Vector2(u1 * 5.0, v1), Vector2(u0 * 5.0, v1)])
	# la quille et l'étrave
	for i2 in range(n_u):
		var q0: Vector3 = pt.call(lerpf(-1.0, 1.0, float(i2) / n_u), 0.0)
		var q1: Vector3 = pt.call(lerpf(-1.0, 1.0, float(i2 + 1) / n_u), 0.0)
		b.tube("bois", q0 + Vector3.UP * 0.06, q1 + Vector3.UP * 0.06, 0.09, 5)
	# les deux pignons (on ferme la proue et la poupe par des planches)
	for su in [-1.0, 1.0]:
		var e0: Vector3 = base + ax * su * (L * 0.5 - 0.35)
		b.box("planches", Transform3D(Basis(Vector3.UP, yaw), e0 + Vector3.UP * 1.0), Vector3(1.6, 2.0, 0.08))
	# la porte (sur le flanc, face à la mer) et son encadrement, deux hublots, un banc devant
	var dp: Vector3 = _barque_door()
	var side_in: Vector3 = -nrm
	var dxf := Transform3D(Basis(Vector3.UP, atan2(nrm.x, nrm.z)), dp + side_in * 1.15 + Vector3.UP * 1.05)
	b.box("planches", dxf, Vector3(1.05, 2.0, 0.08))
	b.box("bois", dxf * Transform3D(Basis(), Vector3(0, 1.06, 0.03)), Vector3(1.25, 0.12, 0.12))
	for sx2 in [-1.0, 1.0]:
		b.box("bois", dxf * Transform3D(Basis(), Vector3(sx2 * 0.6, 0, 0.03)), Vector3(0.1, 2.12, 0.12))
	b.sphere("cuivre", dxf * Vector3(0.38, -0.05, 0.08), 0.05, 1.0, 5, 8)
	for sx3 in [-2.6, 2.4]:
		var hp: Vector3 = pt.call(sx3 / (L * 0.5), 0.72) + Vector3.UP * 0.15
		var tm := Transform3D(Basis(Vector3.UP, atan2(nrm.x, nrm.z)) * Basis(Vector3.RIGHT, -0.5), hp)
		b.cyl("cuivre", tm * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.26, 0.26, 0.08, 16, true)
		b.cyl("verre", tm * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.0)), 0.2, 0.2, 0.1, 16, true)
	var bench: Vector3 = dp + ax * 2.0 + nrm * 0.1
	bench.y = P.ile.height(bench.x, bench.z)
	b.box("bois", Transform3D(Basis(Vector3.UP, yaw), bench + Vector3.UP * 0.42 - nrm * 0.25), Vector3(0.5, 0.06, 2.4))
	for sz in [-1.0, 1.0]:
		b.box("bois", Transform3D(Basis(Vector3.UP, yaw), bench + Vector3.UP * 0.2 - nrm * 0.25 + ax * sz * 1.0), Vector3(0.4, 0.4, 0.08))
	# la cheminée de fer (le poêle du Capitaine)
	var ch: Vector3 = pt.call(0.25, -0.35)
	b.tube("fer", ch - Vector3.UP * 0.3, ch + Vector3.UP * 1.1, 0.1, 8)
	b.cyl("fer", Transform3D(Basis(), ch + Vector3.UP * 1.1), 0.18, 0.12, 0.12, 8, true)
	# le mât, la vergue, le drapeau ; des casiers, un filet, une ancre
	var mast: Vector3 = base + nrm * 4.6 + ax * 3.0
	mast.y = P.ile.height(mast.x, mast.z)
	b.cyl("bois", Transform3D(Basis(), mast), 0.12, 0.15, 7.0, 10, true)
	b.tube("bois", mast + Vector3.UP * 5.6 - nrm * 1.2, mast + Vector3.UP * 5.6 + nrm * 1.2, 0.05, 6)
	P._col_cyl(mast, 0.16, 7.0)
	var flag_c: Vector3 = mast + Vector3.UP * 6.5 + ax * 0.75
	b.box("drapeau", Transform3D(Basis(Vector3.UP, atan2(nrm.x, nrm.z)), flag_c), Vector3(1.4, 0.9, 0.02))
	var fx := Basis(Vector3.UP, atan2(nrm.x, nrm.z))
	for sg in [-1.0, 1.0]:
		var xb: Basis = fx * Basis(Vector3.FORWARD, sg * 0.75)
		b.box("toile_blanche", Transform3D(xb, flag_c + fx * Vector3(0, 0, 0.02)), Vector3(0.07, 0.75, 0.01))
		b.box("toile_blanche", Transform3D(xb, flag_c + fx * Vector3(0, 0, 0.02) + xb * Vector3(0, 0.38, 0)), Vector3(0.16, 0.12, 0.01))
	for k2 in range(3):
		var cp: Vector3 = base + nrm * 2.6 - ax * (3.2 + k2 * 0.6)
		cp.y = P.ile.height(cp.x, cp.z)
		b.box("planches", Transform3D(Basis(Vector3.UP, yaw + k2 * 0.3), cp + Vector3.UP * 0.25), Vector3(0.6, 0.5, 0.45))
	P._avoid.append([Vector2(c.x, c.z), 7.5])
	P._avoid.append([Vector2(mast.x, mast.z), 1.5])
	P._col(Transform3D(Basis(Vector3.UP, yaw), base + Vector3.UP * 1.6), Vector3(W * 0.85, 3.0, L * 0.92))
	P._light(dp + nrm * 0.6 + Vector3.UP * 2.3, Color(1.0, 0.72, 0.42), 1.3, 6.0, true)
	# le hamac entre le mât et un piquet
	var pq: Vector3 = mast + ax * 3.4
	pq.y = P.ile.height(pq.x, pq.z)
	b.cyl("bois", Transform3D(Basis(), pq), 0.07, 0.09, 1.8, 8, true)
	var ha: Vector3 = mast + Vector3.UP * 1.5
	var hb: Vector3 = pq + Vector3.UP * 1.5
	var pts: Array = []
	for k3 in range(9):
		var t: float = float(k3) / 8.0
		pts.append(ha.lerp(hb, t) - Vector3.UP * sin(t * PI) * 0.6)
	for side in [-0.3, -0.1, 0.1, 0.3]:
		var pts2: Array = []
		for p in pts:
			pts2.append((p as Vector3) + nrm * side * sin(PI * float(pts2.size()) / 8.0))
		b.noodle("toile_rouge", pts2, 0.04, [], 4)


# =================================================================== les habitants

func spawn_npcs() -> void:
	if not habitants.is_empty() or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var Pn = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if points.has(home) else str(_streets[0])
		var npc: Node3D = Pn.new()
		main.add_child(npc)
		npc.setup(main, data, points, graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V98: %d adeptes sur l'Île Al Dente" % habitants.size())


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


# =================================================================== les passants (des adeptes)

## [rôle, lieu, pose, début, fin, phrases]
const PASSANTS := [
	["femme", "banc_4", "assis", 7.0, 12.0, ["(Elle chuchote.) Ô Grand Spaghetti, fais que mes pâtes ne collent jamais. Ramen.", "Chut. Je prie. Enfin, je pense aux pâtes. C'est pareil."]],
	["vieux", "banc_6", "assis", 9.0, 18.0, ["Je viens ici tous les jours depuis trente ans. Le banc a pris ma forme.", "Hm ? Ah, c'est toi, le voyageur ? Assieds-toi. Ici, le silence a un goût de basilic."]],
	["homme", "banc_8", "assis", 14.0, 19.0, ["Il paraît qu'on peut voir le Grand Spaghetti à travers les trous du plafond. Je cherche le bon trou.", "J'ai mis ma plus belle passoire, aujourd'hui. Celle du dimanche."]],
	["garcon", "fontaine_3", "pointer", 9.0, 18.0, ["La fontaine, elle coule de la sauce ! De la VRAIE sauce !", "Maman dit qu'on n'a pas le droit d'y tremper son pain. Mais elle ne dit rien pour les doigts."]],
	["femme", "parvis_2", "mains_dos", 10.0, 19.0, ["Regarde là-haut. Il a bougé une nouille. Si, si, je te jure.", "Je suis venue en pèlerinage de Port-Azur. Trois jours de bateau, et ça valait le coup."]],
	["homme", "tablee_10", "manger", 12.0, 14.0, ["Mamma Lasagna a encore fait trop de pâtes. Comme tous les jours. Heureusement.", "Passe-moi le parmesan, s'il te plaît. Merci. Ramen."]],
	["vieille", "tablee_12", "manger", 12.0, 14.0, ["À mon âge, je mange lentement. Ça me laisse le temps de reprendre une deuxième assiette.", "La Grande Tablée, c'est la meilleure invention depuis la fourchette."]],
	["fille", "piazza_danse_1", "danse", 19.5, 23.0, ["Plus vite, Tagliatelle ! Plus vite !", "La tarentelle, ça fait tourner la tête et les pieds en même temps !"]],
	["homme", "piazza_danse_2", "danse", 19.5, 23.0, ["Tralala-lalala ! Hop !", "Je danse comme un spaghetti dans l'eau bouillante. C'est la bonne technique."]],
	["femme", "tablee_11", "manger", 19.0, 22.0, ["Le soir, sous la treille, avec les lampions… C'est mon moment préféré.", "Tu entends le violon ? Ça veut dire que le dessert arrive."]],
	["homme", "champ_3", "bricoler", 7.0, 12.0, ["Le blé est bien haut cette année. Nonno dit que c'est grâce au volcan.", "Encore trois rangs, et je vais déjeuner."]],
	["femme", "sechoir_3", "peindre", 9.0, 17.0, ["Je suspends les spaghettis un par un. Ça me prend la journée. J'adore ça.", "Ne les casse pas ! Recommandation numéro trois !"]],
	["vieux", "plage_bord_2", "mains_dos", 8.0, 19.0, ["Je regarde la mer. Elle est rouge, là-bas, près de la cascade. On s'habitue.", "Le Capitaine Rigatoni m'a promis de m'apprendre à pêcher. Ça fait douze ans."]],
	["fille", "tomates_3", "bricoler", 9.0, 12.0, ["Signorina Ravioli m'a appris à chanter pour les tomates. Elles préfèrent les comptines.", "Celle-là, je l'appelle Petite Sauce."]],
	["homme", "ponton_2", "mains_dos", 7.0, 18.0, ["J'attends le bateau. Il est en retard. Ou alors c'est moi qui suis en avance. Ou il n'y a pas de bateau.", "Arrr ! … Non, je ne suis pas pirate. Je m'entraîne."]],
]


func _spawn_crowd() -> void:
	_crowd_spawned = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 98000
	var n: int = PASSANTS.size() if bool(P.get("pc")) else 9
	for i in range(n):
		var e: Array = PASSANTS[i]
		var sp: Dictionary = spots.get(str(e[1]), {})
		if sp.is_empty():
			continue
		var prof: Dictionary = Gens.pick("pasta", str(e[0]), rng)
		if prof.is_empty():
			continue
		prof["nom"] = Gens.prenom("pasta", str(e[0]), rng)
		var f: Node = Figurant.spawn(self, main, prof, sp["pos"], sp["face"], str(e[2]))
		if f == null:
			continue
		f.set("lines", e[5])
		claim_spot(str(e[1]), f)
		crowd.append([f, float(e[3]), float(e[4]), sp["pos"]])
	_crowd_vis(true)


static func _in_hours(h: float, a: float, b: float) -> bool:
	return (a <= b and h >= a and h < b) or (a > b and (h >= a or h < b))


func _crowd_vis(force: bool = false) -> void:
	var p: Vector3 = main._player_pos_v27()
	var h: float = hour()
	for c in crowd:
		var f: Node = c[0]
		if not is_instance_valid(f):
			continue
		var npc: Node3D = f.get("npc")
		if npc == null:
			continue
		var want: bool = _in_hours(h, float(c[1]), float(c[2])) and (c[3] as Vector3).distance_to(p) < 240.0
		if want != npc.visible or force:
			npc.visible = want
			f.process_mode = Node.PROCESS_MODE_INHERIT if want else Node.PROCESS_MODE_DISABLED
			for k in npc.get_children():
				if k is PhysicsBody3D:
					for cs in k.get_children():
						if cs is CollisionShape3D:
							(cs as CollisionShape3D).disabled = not want


func crowd_visible() -> int:
	var n: int = 0
	for c in crowd:
		if is_instance_valid(c[0]) and (c[0] as Node).get("npc") != null and ((c[0] as Node).get("npc") as Node3D).visible:
			n += 1
	return n


# =================================================================== la Grande Réconciliation

func _journal() -> Node:
	return main.get("journal_v56")


## Le Grand Spaghetti boude tant que la quête n'est pas finie (ses nouilles pendent, ses yeux sont
## mi-clos) ; il se réveille quand on pose le Plat sur l'autel.
func reconcilie() -> bool:
	var j: Node = _journal()
	return bool(P.state.get("offrande", false)) or (j != null and str(j.state(QUETE)) == "finie")


func offrande_possible() -> bool:
	var j: Node = _journal()
	if j == null or str(j.state(QUETE)) != "en_cours" or bool(P.state.get("offrande", false)):
		return false
	var inv: Node = main.get("inventory_v28")
	return inv != null and int(inv.count("plat_sacre")) > 0


func register_interactions(d: Node) -> void:
	var door: Vector3 = door_dir()
	d._interactions.append({"id": "pasta_offrande", "pos": P._autel_at + door * 1.9, "radius": 2.4,
		"text": "E : poser le Plat de la Grande Réconciliation sur l'autel", "vr": "Gâchette : poser le Plat sur l'autel",
		"call": offrande, "when": offrande_possible})


func offrande() -> void:
	if not offrande_possible():
		return
	var inv: Node = main.get("inventory_v28")
	inv.remove("plat_sacre", 1)
	P.state["offrande"] = true
	_poser_plat()
	start_fete()
	P.say("Tu poses le Plat de la Grande Réconciliation sur l'autel, à côté de l'assiette éternelle. Une odeur de tomate, de basilic et de parmesan monte jusqu'au sommet de la passoire… Là-haut, quelque chose bouge.", 8.0)


func _poser_plat() -> void:
	if _plat != null:
		return
	_plat = Node3D.new()
	_plat.name = "Plat_de_la_Reconciliation"
	add_child(_plat)
	var door: Vector3 = door_dir()
	var side: Vector3 = door.cross(Vector3.UP)
	var at: Vector3 = P._autel_at + Vector3.UP * 1.2 + side * 1.25
	var b := Kit.Batch.new()
	b.cyl("or", Transform3D(Basis(), at), 0.3, 0.26, 0.04, 22, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9812
	for j in range(22):
		var pts: Array = []
		var a0: float = rng.randf() * TAU
		var r0: float = rng.randf_range(0.03, 0.22)
		for s in range(9):
			var tt: float = float(s) / 8.0
			var aa: float = a0 + tt * TAU * 1.3
			var rr: float = r0 * (1.0 - tt * 0.5) + 0.02
			pts.append(at + Vector3(cos(aa) * rr, 0.04 + tt * 0.14 * (1.0 - rr * 2.5), sin(aa) * rr))
		b.noodle("pates", pts, 0.007, [], 4)
	b.sphere("sauce", at + Vector3.UP * 0.15, 0.12, 0.35, 5, 12)
	for k in range(3):
		b.sphere("boulette", at + Vector3(cos(k * 2.1) * 0.08, 0.2, sin(k * 2.1) * 0.08), 0.045, 0.9, 5, 8)
	b.sphere("parmesan", at + Vector3.UP * 0.24, 0.08, 0.25, 4, 10)
	b.commit(_plat, "Plat_sacre")


## La fête : le Spaghetti danse, la pluie de farfalle, le Couvercle sonne deux fois, et les adeptes
## crient « Ramen ! » l'un après l'autre.
func start_fete() -> void:
	fete = 26.0
	_cheer_i = 0
	_cheer_t = 1.5
	P._wiggle = 2.5
	P._blink = 0.0
	if _confettis.is_empty():
		var door: Vector3 = door_dir()
		_confettis.append(_make_confettis(P.temple_c + Vector3.UP * 10.0, Vector3(9.0, 0.5, 9.0), 220))
		_confettis.append(_make_confettis(P._fontaine_at + Vector3.UP * 14.0 - door * 4.0, Vector3(8.0, 0.5, 12.0), 160))
	for c in _confettis:
		(c as CPUParticles3D).emitting = true
	P.sfx("couvercle", P._gong_at)
	if main.has_method("jingle"):
		main.jingle("victoire")


## Une pluie de farfalle tricolores (des petits nœuds papillon de pâte : jaune, vert, rouge), qui
## tombent en tournoyant.
func _make_confettis(at: Vector3, box: Vector3, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Pluie_de_farfalle"
	add_child(p)
	p.global_position = at
	p.amount = amount
	p.lifetime = 7.0
	p.emitting = false
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = box
	p.direction = Vector3.DOWN
	p.spread = 25.0
	p.gravity = Vector3(0, -1.2, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 1.0
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.damping_min = 0.4
	p.damping_max = 0.9
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.33, 0.34, 0.66, 0.67, 1.0])
	ramp.colors = PackedColorArray([Color(0.98, 0.84, 0.42), Color(0.98, 0.84, 0.42), Color(0.25, 0.6, 0.25), Color(0.25, 0.6, 0.25), Color(0.85, 0.2, 0.15), Color(0.85, 0.2, 0.15)])
	p.color_initial_ramp = ramp
	var q := QuadMesh.new()
	q.size = Vector2(0.2, 0.12)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _farfalle_tex()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.roughness = 0.6
	q.material = m
	p.mesh = q
	p.visibility_aabb = AABB(Vector3(-20, -30, -20), Vector3(40, 40, 40))
	return p


## Le dessin d'une farfalle : deux ailes en éventail (bords crantés), un nœud pincé au milieu.
static func _farfalle_tex() -> ImageTexture:
	var w: int = 64
	var h: int = 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in range(h):
		for x in range(w):
			var u: float = (float(x) + 0.5) / w * 2.0 - 1.0
			var v: float = (float(y) + 0.5) / h * 2.0 - 1.0
			var half: float = 0.22 + 0.78 * pow(absf(u), 0.8)
			var edge: float = 0.93 + 0.07 * sin(v * 18.0)
			if absf(v) < half and absf(u) < edge:
				var shade: float = 0.82 + 0.18 * absf(u)
				if absf(u) < 0.12:
					shade = 0.7
				img.set_pixel(x, y, Color(shade, shade, shade, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _tick_fete(delta: float) -> void:
	if fete <= 0.0:
		return
	fete -= delta
	P._wiggle = maxf(P._wiggle, 2.2 if fete > 4.0 else fete * 0.5)
	_cheer_t -= delta
	if _cheer_t <= 0.0:
		_cheer_t = 0.9
		var p: Vector3 = main._player_pos_v27()
		var lines: Array = ["Ramen !", "RAMEN !", "Ramen, ramen !", "Il danse ! Il danse !", "Par Ses Nouilles !", "Ramen ! Ramen !"]
		var n: int = 0
		for npc in habitants:
			if not is_instance_valid(npc) or not (npc as Node3D).visible:
				continue
			if (npc as Node3D).global_position.distance_to(p) > 90.0:
				continue
			if n == _cheer_i % maxi(habitants.size(), 1):
				npc.cheer(4.0, str(lines[(_cheer_i + n) % lines.size()]))
			n += 1
		for c in crowd:
			var f: Node = c[0]
			if is_instance_valid(f) and f.has_method("say") and (c[3] as Vector3).distance_to(p) < 90.0 and (_cheer_i + crowd.find(c)) % 4 == 0:
				f.say(str(lines[_cheer_i % lines.size()]), 3.0)
		_cheer_i += 1
		if _cheer_i == 3:
			P.sfx("couvercle", P._gong_at)
	if fete <= 0.0:
		for c2 in _confettis:
			(c2 as CPUParticles3D).emitting = false
		P.say("Le Grand Spaghetti Volant redescend doucement… Une longue nouille se tend vers toi et te touche l'épaule, tout doucement. Tu viens d'être Touché par Son Appendice Nouilleux. (Ça chatouille, et ça sent bon.) Va voir le Révérend Père Farfalle !", 9.0)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or P == null:
		return
	_tick_fete(delta)
	P.fete_k = clampf(fete / 6.0, 0.0, 1.0) if fete > 0.0 else 0.0
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 1.0
	P.humeur_effigie = 1.0 if reconcilie() else 0.0
	var p: Vector3 = main._player_pos_v27()
	if not _crowd_spawned:
		if Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length() < 330.0 and bool(main.get("game_started")):
			_spawn_crowd()
		return
	_crowd_vis()

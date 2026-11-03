extends Node3D
## V101 : la vie du Village des Arbres-Maisons (l'Île Crayonnée) et la quête des couleurs.
##  - Les habitants (pnj/crayon_habitants_v101.gd, pnj/pnj_crayon_v101.gd) vivent selon l'heure : les
##    rues (un graphe de points le long des chemins de l'île, autour de la Palette, dans les escaliers
##    qui tournent autour des troncs, sur les plates-formes, jusqu'au Belvédère), les lieux où l'on
##    s'installe (la Palette, les bancs, la balançoire, les terrasses, la longue-vue ; la rive de
##    l'étang, la lisière du bois, les prés, la plage, le pied de la cascade).
##  - Les neuf pots de couleur de la Palette, emportés par la Grande Averse : six sont des quêtes de
##    couleur (un habitant sait où le sien est tombé), trois se trouvent en cherchant (le panier de la
##    poulie, l'embouchure du Ruisseau Pointillé, une passerelle). Versé dans son godet, un pot rend
##    ses couleurs à une partie de l'île : une vague de couleur (crayon_vague, un paramètre partagé des
##    matériaux au crayon) s'étale depuis le centre de la région, puis la carte des couleurs est
##    peinte pour de bon, quelques rangées par image (pas d'à-coup, même en VR).
##  - Le Pinceau de l'île (donné par Grand-Mère Aquarelle) : en main, E (gâchette en VR) pose une
##    tache de couleur devant soi ; il se recharge à la Palette (20 coups), dès qu'une couleur y est.
##  - Les neuf pots en place : la fête des couleurs (toute l'île reprend ses couleurs d'un coup, les
##    habitants lèvent les bras, des confettis de toutes les couleurs au-dessus de la Palette).
## Les décors des cachettes (le nénuphar géant, la Souche Creuse, Monsieur Paille l'épouvantail, le
## château de sable de Lili, le cairn du sommet) passent au rendu coloriage avec le reste de l'île.

const IleScript = preload("res://scripts/ile_crayon_v99.gd")
const Kit = preload("res://scripts/pasta_kit_v97.gd")
const Village = preload("res://scripts/village_crayon_v100.gd")
const HABITANTS := "res://scripts/pnj/crayon_habitants_v101.gd"
const PNJ := "res://scripts/pnj/pnj_crayon_v101.gd"
const QUETE := "cr_couleurs"
const PINCEAU_MAX: int = 20

## Les neuf pots : couleur -> [numéro du godet, nom, couleur, région (repère île : x, z, rayon), où]
const POTS := {
	"bleu": [1, "le bleu", Color(0.16, 0.38, 0.78), [40.0, -24.0, 30.0], "l'Étang Gommé"],
	"vert": [2, "le vert", Color(0.2, 0.55, 0.22), [-100.0, 45.0, 54.0], "le Bois des Hachures"],
	"rouge": [3, "le rouge", Color(0.84, 0.13, 0.11), [78.0, 80.0, 50.0], "les Prés Blancs"],
	"jaune": [4, "le jaune", Color(0.98, 0.82, 0.18), [4.0, 128.0, 40.0], "la Grève Blanche"],
	"brun": [5, "le brun", Color(0.5, 0.31, 0.16), [-40.0, 34.0, 46.0], "la Clairière des Géants"],
	"violet": [6, "le violet", Color(0.5, 0.27, 0.66), [-6.0, -90.0, 56.0], "le Mont Fusain"],
	"orange": [7, "l'orange", Color(0.97, 0.52, 0.12), [22.0, -56.0, 24.0], "la Cascade d'Encre"],
	"turquoise": [8, "le turquoise", Color(0.14, 0.68, 0.68), [112.0, 12.0, 44.0], "le Ruisseau Pointillé"],
	"rose": [9, "le rose", Color(0.95, 0.5, 0.66), [-78.0, 102.0, 46.0], "les prairies du sud-ouest"],
}
const ORDRE := ["bleu", "vert", "rouge", "jaune", "brun", "violet", "orange", "turquoise", "rose"]
## Les pots qu'on trouve sans quête (le brun est dans le panier de la poulie)
const LIBRES := ["turquoise", "rose"]

var main: Node
var cr: Node3D                            # crayon_v99.gd
var village: Node3D
var ile: Node3D
var points: Dictionary = {}               # nom -> Vector3 (monde)
var graph: Dictionary = {}                # nom -> [voisins]
var spots: Dictionary = {}                # nom -> {pos, face, pose, node}
var habitants: Array = []
var by_id: Dictionary = {}
var cachettes: Dictionary = {}            # couleur -> Vector3 : là où le pot est tombé
var poulie_haut := Vector3.ZERO
var poulie_bas := Vector3.ZERO
var longue_vue := Vector3.ZERO
var _claims: Dictionary = {}
var _streets: Array = []
var _godet_nodes: Dictionary = {}
var _it_pinceau: Dictionary = {}
var _registered: bool = false
# la vague de couleur en cours, celles qui attendent, la région en train d'être peinte pour de bon
var _vague: Dictionary = {}
var _vagues: Array = []
var _bake: Dictionary = {}
# la fête
var fete: float = 0.0
var _cheer_t: float = 0.0
var _cheer_i: int = 0
var _confettis: CPUParticles3D


func setup(main_node: Node, crayon: Node3D) -> void:
	main = main_node
	cr = crayon
	village = crayon.village
	ile = crayon.ile
	name = "Crayon_vie_v101"


func G(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func Gw(p: Vector3) -> Vector3:
	return Vector3(p.x, ile.height(p.x, p.z), p.z)


static func dir(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, sin(a))


# =================================================================== construction

## Avant le passage au rendu coloriage (les décors des cachettes sont dessinés comme le reste).
func build() -> void:
	var t0: int = Time.get_ticks_msec()
	_materials()
	_rues()
	_village_chemins()
	_lieux()
	_cachettes()
	_reperes()
	print("ILE_MANGA_V101: Île Crayonnée : %d points, %d lieux (%d ms)" % [points.size(), spots.size(), Time.get_ticks_msec() - t0])


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


## Une rue au sol : des points tous les ~step m le long d'une ligne brisée (repère île) ; un point
## proche d'un point de rue existant (< 3 m) se confond avec lui.
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


## Le centre de la clairière (au sol) et un point autour, à l'angle a, à r mètres.
func _autour(a: float, r: float) -> Vector3:
	var c: Vector3 = village.centre
	return Gw(c + dir(a) * r)


func _rues() -> void:
	# --- les chemins de l'île (repère île)
	var lanes: Dictionary = {}
	for k in IleScript.PATHS:
		lanes[k] = _rue("ch_" + str(k), IleScript.PATHS[k], 8.0)
	# le carrefour : les chemins de la plage, de la clairière, de l'étang, des prés s'y rejoignent
	for k2 in ["clairiere", "etang", "pres"]:
		_link(str((lanes[k2] as Array)[0]), nearest_street(G(2.0, 98.0), "st_ch_plage"))
	# --- autour de la Palette : un anneau de 12 points (entre les bancs et les lampadaires)
	var ring: Array = []
	for k3 in range(12):
		ring.append(_pt("st_anneau_%d" % k3, _autour(TAU * k3 / 12.0, 11.0)))
	for k4 in range(12):
		_link(ring[k4], ring[(k4 + 1) % 12])
	# --- les trois sorties de la clairière (entre les géants) jusqu'aux chemins
	for e in [["sortie_sud", 67.0, "st_ch_clairiere_"], ["sortie_ouest", 176.0, "st_ch_bois_"], ["sortie_nord", 251.0, "st_ch_mont_"]]:
		var a: float = deg_to_rad(float(e[1]))
		var p0: String = _pt("st_%s_0" % str(e[0]), _autour(a, 20.0))
		var p1: String = _pt("st_%s_1" % str(e[0]), _autour(a, 30.0))
		_link(p0, p1)
		_link(p0, str(ring[int(round(a / (TAU / 12.0))) % 12]))
		_link(p1, nearest_street(points[p1], str(e[2])))
	# --- la grève : du bout du chemin de la plage vers l'ouest (le château de sable de Lili)
	_rue("greve", [Vector2(8.0, 140.0), Vector2(-6.0, 136.0), Vector2(-20.0, 129.0)], 7.0)
	_link("st_greve_0", nearest_street(G(8.0, 140.0), "st_ch_plage"))
	# --- le bord de l'étang, jusqu'au pied de la cascade
	var et: Array = (IleScript.PATHS["etang"] as Array)
	_rue("etang_bord", [et[-1], Vector2(20.0, -24.0), Vector2(20.0, -33.0)], 6.0)
	_link("st_etang_bord_0", str((lanes["etang"] as Array)[-1]))
	# --- l'embouchure du Ruisseau Pointillé (par le bord nord du ruisseau)
	_rue("ruisseau", [et[-1], Vector2(40.0, -14.0), Vector2(70.0, 2.0), Vector2(104.0, 18.0), Vector2(136.0, 28.0)], 9.0)
	_link("st_ruisseau_0", str((lanes["etang"] as Array)[-1]))


# ------------------------------------------------------------------- les escaliers et les plates-formes

func _arbre(id: String) -> Dictionary:
	for t in village.arbres:
		if str(t["id"]) == id:
			return t
	return {}


## Un point sur la plate-forme d'un arbre (angle, rayon depuis l'axe du tronc, hauteur au-dessus du sol de l'arbre).
func _sur(t: Dictionary, a: float, r: float, y: float) -> Vector3:
	var c: Vector3 = t["c"]
	return Vector3(c.x, c.y + y, c.z) + dir(a) * r


func _village_chemins() -> void:
	for t2 in village.arbres:
		var t: Dictionary = t2
		var id: String = str(t["id"])
		var c: Vector3 = t["c"]
		var top: float = t["pont"]
		var a_end: float = t["a_end"]
		var span: float = float(t["turns"]) * TAU
		var a0: float = a_end - span
		# --- le pied de l'escalier : on y entre par le bout (la main courante ferme le côté vide), en
		# passant entre le panneau (plus loin du tronc) et les tonneaux
		var foot_r: float = village.r_stairs(t, 0.3)
		var loin: String = _pt("st_%s_abord_loin" % id, Gw(c + dir(a0 - 0.3) * (foot_r + 3.0)))
		var app: String = _pt("st_%s_abord" % id, Gw(c + dir(a0 - 0.4) * (foot_r - 0.05)))
		var pied: String = _pt("%s_esc_0" % id, Gw(c + dir(a0 + 0.08) * (foot_r - 0.05)))
		_link(loin, app)
		_link(app, pied)
		_link(loin, nearest_street(points[loin], "st_anneau_"))
		# --- l'escalier : un point tous les 30° (le pied des habitants suit les marches, _snap_to_floor)
		var prev: String = pied
		var steps: int = maxi(int(ceil(span / deg_to_rad(30.0))), 2)
		for k in range(1, steps + 1):
			var f: float = float(k) / float(steps)
			var y: float = top * f
			var a: float = a0 + span * f
			var nm: String = _pt("%s_esc_%d" % [id, k], _sur(t, a, village.r_stairs(t, y) - 0.05, y + 0.05))
			_link(prev, nm)
			prev = nm
		# --- la plate-forme : l'anneau (dans le sens des angles croissants : la trappe est derrière)
		# jusqu'à la porte, et les deux terrasses, de part et d'autre de la maison
		var grand: bool = id == "grand"
		var r_in: float = village.r_max(t, top) + 0.02
		var porte: Vector3 = t["porte"]
		var ap: float = atan2(porte.z - c.z, porte.x - c.x)
		var phi: float = t["phi"]
		var hd: float = ((t["maison_c"] as Vector3) - c).length()
		var hs: float = asin(clampf((float(t["rm"]) + 0.15) / hd, 0.0, 1.0))
		var a_ter: float = phi - (hs + (0.95 if grand else 0.42))
		var a_ter2: float = phi + hs + 0.42
		var r_out: float = t["r_out"]
		var start: String = prev
		var haut_esc: String = prev
		if grand:
			# au Grand-Chêne, l'escalier du Belvédère part de l'anneau : on passe d'abord au large
			start = _pt("%s_pont_sortie" % id, _sur(t, a_end + 0.08, r_in + Village.RING + 0.4, top + 0.05))
			_link(prev, start)
		var a_stop: float = 0.0
		for aa0 in [ap, a_ter, a_ter2]:
			a_stop = maxf(a_stop, wrapf(float(aa0) - a_end, 0.0, TAU))
		var ring_names: Array = []
		var na: int = int(ceil(a_stop / 0.3))
		var from: String = start
		for k2 in range(1, na + 1):
			var s: float = a_stop * float(k2) / float(na)
			var rr: float = r_in + Village.RING * 0.5
			if grand and s < 1.9:
				rr = r_in + Village.RING + 0.4
			var rn: String = _pt("%s_pont_%d" % [id, k2], _sur(t, a_end + s, rr, top + 0.05))
			_link(from, rn)
			ring_names.append([a_end + s, rn])
			from = rn
		var door: String = _pt("porte_%s" % id, porte + Vector3.UP * 0.05)
		_link(_ring_near(ring_names, ap), door)
		for e in [["terrasse", a_ter], ["terrasse_2", a_ter2]]:
			var aa: float = float(e[1])
			var sp: Vector3 = _sur(t, aa, r_out - 0.95, top + 0.05)
			var nm2: String = _pt("lieu_%s_%s" % [id, str(e[0])], sp)
			_link(_ring_near(ring_names, aa), nm2)
			spots["%s_%s" % [id, str(e[0])]] = {"pos": sp, "face": dir(aa), "pose": "observer", "node": nm2}
		if grand:
			_belvedere(t, haut_esc)


func _ring_near(ring_names: Array, a: float) -> String:
	var best: String = ""
	var bd: float = INF
	for e in ring_names:
		var d: float = Village.angdist(float(e[0]), a)
		if d < bd:
			bd = d
			best = str(e[1])
	return best


## Le Grand-Chêne : le deuxième escalier (de la plate-forme du Conseil au Belvédère), le Belvédère.
func _belvedere(t: Dictionary, pont_sortie: String) -> void:
	var top: float = t["pont"]
	var hb: float = Village.BELVEDERE_H
	var a1: float = float(t["a_end"]) + TAU / Village.SECTORS
	var span: float = TAU
	var phi: float = t["phi"]
	var prev: String = _pt("grand_haut_0", _sur(t, a1 + 0.12, village.r_stairs(t, top + 0.2) - 0.05, top + 0.25))
	_link(pont_sortie, prev)
	for k in range(1, 13):
		var f: float = float(k) / 12.0
		var y: float = top + (hb - top) * f
		var nm: String = _pt("grand_haut_%d" % k, _sur(t, a1 + span * f, village.r_stairs(t, y) - 0.05, y + 0.05))
		_link(prev, nm)
		prev = nm
	var a_end2: float = a1 + span
	var r_in: float = village.r_max(t, hb) + 0.02
	var r_ring: float = r_in + Village.RING * 0.5
	var r_out: float = float(t.get("belv_r", r_in + Village.RING + 1.7))
	var a_banc: float = phi + 0.9
	var a_stop: float = wrapf(a_banc - a_end2, 0.0, TAU)
	var ring_names: Array = []
	var na: int = int(ceil(a_stop / 0.3))
	for k2 in range(1, na + 1):
		var a2: float = a_end2 + a_stop * float(k2) / float(na)
		var rn: String = _pt("belv_%d" % k2, _sur(t, a2, r_ring, hb + 0.05))
		_link(prev if k2 == 1 else str(ring_names[-1][1]), rn)
		ring_names.append([a2, rn])
	var vue: Vector3 = _sur(t, phi + 0.22, r_out - 1.15, hb + 0.05)
	var nv: String = _pt("lieu_belvedere_vue", vue)
	_link(_ring_near(ring_names, phi + 0.22), nv)
	spots["belvedere_vue"] = {"pos": vue, "face": dir(phi - 0.25), "pose": "observer", "node": nv}
	var bn: Vector3 = _sur(t, a_banc, r_out - 0.75, hb)
	var front: Vector3 = _sur(t, a_banc, r_out - 1.5, hb + 0.05)
	var nb: String = _pt("lieu_belvedere_banc", front)
	_link(_ring_near(ring_names, a_banc), nb)
	spots["belvedere_banc"] = {"pos": bn, "face": -dir(a_banc), "pose": "assis", "node": nb}


# ------------------------------------------------------------------- les lieux

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
	var c: Vector3 = village.centre
	# --- la Palette : Grand-Mère Aquarelle, devant les godets
	var pa: float = deg_to_rad(80.0)
	_spot_w("palette_1", _autour(pa, 4.9), -dir(pa), "bras_croises", nearest_street(_autour(pa, 11.0), "st_anneau_"))
	_spot_w("palette_2", _autour(pa + 0.9, 4.9), -dir(pa + 0.9), "observer", nearest_street(_autour(pa + 0.9, 11.0), "st_anneau_"))
	# --- les quatre bancs autour de la Palette (village_crayon_v100 : à 7,6 m, tournés vers elle)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var seat: Vector3 = _autour(a, 7.6)
		var front: String = _pt("lieu_palette_banc_%d_devant" % (k + 1), _autour(a, 6.7))
		_link(front, nearest_street(_autour(a, 11.0), "st_anneau_"))
		# on arrive par-devant (du côté de la Palette), en contournant le banc
		spots["palette_banc_%d" % (k + 1)] = {"pos": seat, "face": -dir(a), "pose": "assis", "node": front}
	# --- la balançoire, sous la plate-forme du Chêne-Gomme
	var tg: Dictionary = _arbre("gomme")
	if not tg.is_empty():
		var sa: float = float(tg["phi"]) + PI * 0.5
		var sw: Vector3 = Gw((tg["c"] as Vector3) + dir(sa) * (float(tg["r_out"]) - 0.7))
		var via: String = _pt("st_balancoire", Gw(sw + dir(sa) * 2.2))
		_link(via, nearest_street(points[via], "st_anneau_"))
		spots["balancoire"] = {"pos": sw, "face": dir(sa), "pose": "assis", "node": via}
		spots["balancoire_pousse"] = {"pos": Gw(sw + dir(sa) * 1.25), "face": -dir(sa), "pose": "debout", "node": via}
	# --- dehors : la rive de l'étang, le pied de la cascade, la lisière du bois, les prés, la plage
	var ec := Vector2(float(IleScript.ETANG[0]), float(IleScript.ETANG[1]))
	_spot("etang_rive", 24.5, -19.5, Vector3(ec.x - 24.5, 0, ec.y + 19.5), "peindre", "st_etang_bord_1")
	_spot("cascade_rocher", 21.0, -34.5, (ile.pied - G(21.0, -34.5)), "lire", "st_etang_bord_2")
	_spot("bois_lisiere", -114.0, 57.0, Vector3(-1, 0, 0.3), "jardiner")
	_spot("pres_fleurs", 82.0, 84.0, Vector3(0.6, 0, -0.8), "jardiner")
	_spot("plage_chateau", -21.0, 126.0, Vector3(-1, 0, 0.4), "jardiner", "st_greve_2")
	_spot("plage_bord", -4.0, 141.0, Vector3(0, 0, 1), "observer", "st_greve_1")
	# Lili construit son château à côté de celui de l'Averse (la cachette du jaune, un peu plus à l'ouest)


# ------------------------------------------------------------------- les cachettes des pots

## Les matières des cachettes (leur vraie couleur, celle qu'on verra quand l'île l'aura retrouvée).
static func _materials() -> void:
	var cache: Dictionary = Kit.Batch._mcache
	if cache.has("sable_chateau"):
		return
	for e in [["feuille_nenuphar", Color(0.2, 0.42, 0.16), 0.45, 2], ["paille", Color(0.86, 0.72, 0.4), 0.95, 0],
			["toile_epouvantail", Color(0.55, 0.36, 0.26), 0.95, 0], ["sable_chateau", Color(0.88, 0.78, 0.58), 1.0, 0], ["fleur_nenuphar", Color(0.96, 0.7, 0.8), 0.6, 6]]:
		var m := StandardMaterial3D.new()
		m.albedo_color = e[1]
		m.roughness = float(e[2])
		m.set_meta("crayon", int(e[3]))
		cache[str(e[0])] = m


func _cachettes() -> void:
	var b := Kit.Batch.new()
	# le bleu : sur un nénuphar géant, loin du bord de l'étang
	var en: Vector3 = IleScript.W(float(IleScript.ETANG[0]) + 3.5, float(IleScript.ETANG[1]) + 2.5, ile.etang_level + 0.02)
	# une feuille ronde, échancrée jusqu'au milieu, une fleur à côté
	var nf: int = 28
	for k0 in range(nf):
		var a0: float = 0.22 + (TAU - 0.44) * float(k0) / float(nf)
		var a1: float = 0.22 + (TAU - 0.44) * float(k0 + 1) / float(nf)
		var p0: Vector3 = en + dir(a0) * 1.25 * (1.0 + 0.04 * sin(a0 * 5.0)) + Vector3.UP * 0.04
		var p1: Vector3 = en + dir(a1) * 1.25 * (1.0 + 0.04 * sin(a1 * 5.0)) + Vector3.UP * 0.04
		b.tri("feuille_nenuphar", [en + Vector3.UP * 0.025, p1, p0], [Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0.5, 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5)])
	var fl: Vector3 = en + dir(PI * 0.9) * 2.0
	b.cyl("feuille_nenuphar", Transform3D(Basis(), fl), 0.45, 0.45, 0.02, 14)
	for k1 in range(8):
		var a5: float = TAU * k1 / 8.0
		b.sphere("fleur_nenuphar", fl + dir(a5) * 0.11 + Vector3.UP * 0.1, 0.09, 0.55, 4, 6)
	cachettes["bleu"] = en + Vector3.UP * 0.05
	# le vert : dans la Souche Creuse, au fond du Bois des Hachures
	var so: Vector3 = G(-112.0, 66.0)
	b.cyl("bois", Transform3D(Basis(), so - Vector3.UP * 0.3), 1.7, 1.35, 1.4, 18, true)
	b.cyl("planches", Transform3D(Basis(), so + Vector3.UP * 1.1), 1.25, 1.25, 0.015, 18)
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.3
		b.tube("bois", so + dir(a) * 1.4 + Vector3.UP * 0.4, so + dir(a) * 2.5 - Vector3.UP * 0.25, 0.18, 6)
	_col_cyl(so, 1.6, 1.1, true)
	# le pot a roulé contre la souche, au creux entre deux racines
	cachettes["vert"] = Gw(so + dir(TAU * 2.5 / 6.0 + 0.3) * 1.95)
	# le rouge : au pied de Monsieur Paille, l'épouvantail des Prés Blancs
	var ep: Vector3 = G(90.0, 76.0)
	b.tube("bois", ep, ep + Vector3.UP * 2.3, 0.06, 7)
	b.tube("bois", ep + Vector3.UP * 1.75 - Vector3.RIGHT * 0.9, ep + Vector3.UP * 1.75 + Vector3.RIGHT * 0.9, 0.05, 6)
	b.sphere("paille", ep + Vector3.UP * 2.35, 0.24, 1.15, 6, 10)
	b.cyl("paille", Transform3D(Basis(), ep + Vector3.UP * 2.52), 0.42, 0.42, 0.04, 16)
	b.cyl("paille", Transform3D(Basis(), ep + Vector3.UP * 2.56), 0.2, 0.18, 0.2, 12)
	b.box("toile_epouvantail", Transform3D(Basis(), ep + Vector3.UP * 1.5), Vector3(0.62, 0.8, 0.22))
	_col_cyl(ep, 0.15, 2.3, true)
	cachettes["rouge"] = ep + Vector3(0.55, 0.0, 0.35)
	cachettes["rouge"].y = ile.height(cachettes["rouge"].x, cachettes["rouge"].z)
	# le jaune : dans le grand château de sable de l'Averse, au bout de la grève
	var ch: Vector3 = G(-27.0, 128.0)
	b.cyl("sable_chateau", Transform3D(Basis(), ch - Vector3.UP * 0.1), 1.6, 1.3, 0.6, 18)
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + 0.4
		b.cyl("sable_chateau", Transform3D(Basis(), ch + dir(a2) * 1.05 + Vector3.UP * 0.3), 0.36, 0.3, 0.75, 10)
		b.cyl("sable_chateau", Transform3D(Basis(), ch + dir(a2) * 1.05 + Vector3.UP * 1.05), 0.34, 0.0, 0.32, 10)
	b.cyl("sable_chateau", Transform3D(Basis(), ch + Vector3.UP * 0.45), 0.65, 0.55, 0.7, 14)
	b.cyl("sable_chateau", Transform3D(Basis(), ch + Vector3.UP * 1.15), 0.6, 0.0, 0.45, 14)
	cachettes["jaune"] = Gw(ch + dir(1.2) * 1.9)
	# le violet : au pied du cairn du sommet du Mont Fusain
	var sm: Vector3 = ile.pads_world["sommet"]
	var ca: Vector3 = Gw(sm + Vector3(2.4, 0, 1.6))
	var hh: float = 0.0
	for k3 in range(5):
		var r3: float = 0.62 - k3 * 0.11
		b.sphere("pierre", ca + Vector3.UP * (hh + r3 * 0.55), r3, 0.62, 6, 10)
		hh += r3 * 0.7
	_col_cyl(ca, 0.6, hh, true)
	cachettes["violet"] = Gw(ca + Vector3(0.9, 0, -0.5))
	# l'orange : en haut de la cascade, sur la Lèvre, au bord de l'eau
	var lv: Vector3 = ile.levre
	var out: Vector3 = Vector3(ile.pied.x - lv.x, 0, ile.pied.z - lv.z).normalized()
	var sd: Vector3 = out.cross(Vector3.UP).normalized()
	cachettes["orange"] = Gw(lv + sd * 3.4 - out * 3.0)
	# le turquoise : à l'embouchure du Ruisseau Pointillé, sur la berge nord
	cachettes["turquoise"] = G(141.0, 27.0)
	# le rose : coincé entre deux planches de la dernière passerelle (au-dessus de l'entrée du village)
	if village.ponts.size() > 0:
		cachettes["rose"] = (village.ponts[village.ponts.size() - 1]["mid"] as Vector3) + Vector3.UP * 0.06
	b.commit(self, "Cachettes_v101")


func _col_cyl(at: Vector3, r: float, h: float, ground: bool = false) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	body.add_child(cs)
	cs.global_position = at + Vector3.UP * (h * 0.5 if ground else 0.0)


## La poulie et la longue-vue (village_crayon_v100 en garde la place).
func _reperes() -> void:
	var t: Dictionary = _arbre("grand")
	if t.is_empty():
		return
	var phi: float = t["phi"]
	var top: float = t["pont"]
	var pa: float = phi - 0.75
	var r_main: float = t["r_out"]
	poulie_haut = _sur(t, pa, r_main - 0.9, top + 0.05)
	poulie_bas = Gw((t["c"] as Vector3) + dir(pa) * (r_main + 1.0))
	var r_out: float = float(t.get("belv_r", 8.0))
	longue_vue = _sur(t, phi, r_out - 1.0, Village.BELVEDERE_H + 0.05)


# =================================================================== les habitants

func spawn_npcs() -> void:
	if not habitants.is_empty() or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var Pn = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if points.has(home) else "st_anneau_0"
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
	print("ILE_MANGA_V101: %d habitants au Village des Arbres-Maisons" % habitants.size())


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


# =================================================================== les pots, la Palette, le pinceau

func _inv() -> Node:
	return main.get("inventory_v28") if main != null else null


func _journal() -> Node:
	return main.get("journal_v56") if main != null else null


func poured() -> Dictionary:
	return cr.state.get("pots", {})


func nb_pots() -> int:
	return poured().size()


func pots_en_poche() -> Array:
	var out: Array = []
	var inv: Node = _inv()
	if inv == null:
		return out
	for c in ORDRE:
		if inv.count("pot_" + str(c)) > 0 and not poured().has(c):
			out.append(c)
	return out


func a_le_pinceau() -> bool:
	var inv: Node = _inv()
	return inv != null and inv.count("pinceau") > 0


## Les lieux des quêtes (journal_v56 : « ramasser ») et les pots qu'on trouve sans quête.
func register_services(journal: Node) -> void:
	for c in cachettes:
		journal.lieux["crayon_pot_" + str(c)] = cachettes[c]
	journal.lieux["crayon_poulie"] = poulie_haut
	journal.lieux["crayon_longue_vue"] = longue_vue
	spawn_free_pots()
	# une seconde plus tard (les collisions toutes neuves sont alors dans l'espace physique) : chaque
	# pot posé sur la vraie surface
	if is_inside_tree():
		get_tree().create_timer(1.0).timeout.connect(_poser_cachettes.bind(journal))


## Les pots posés sur la vraie surface (la collision du relief, une plate-forme), pas sur height().
func _poser_cachettes(journal: Node) -> void:
	if not is_inside_tree():
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var inv: Node = _inv()
	for c in cachettes:
		if str(c) == "bleu":
			continue
		var p: Vector3 = cachettes[c]
		var h: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 1.5, 1))
		if h.is_empty():
			continue
		var np: Vector3 = h["position"]
		cachettes[c] = np
		journal.lieux["crayon_pot_" + str(c)] = np
		if inv == null:
			continue
		# un pot déjà posé (libre, ou d'une quête en cours) suit
		for pk in inv.pickups:
			if str(pk["uid"]).ends_with("crayon_pot_" + str(c)) and is_instance_valid(pk["node"]):
				pk["pos"] = np
				(pk["node"] as Node3D).global_position = np


func spawn_free_pots() -> void:
	var inv: Node = _inv()
	if inv == null:
		return
	for c in LIBRES:
		if not cachettes.has(c) or poured().has(c) or inv.taken.has("crayon_pot_" + str(c)):
			continue
		inv.spawn_pickup("crayon_pot_" + str(c), "pot_" + str(c), 1, cachettes[c])


func register_interactions(d: Node) -> void:
	if _registered:
		return
	_registered = true
	var pal: Vector3 = cr.palette_at
	d._interactions.append({"id": "crayon_palette_verser", "pos": pal, "radius": 5.0,
		"text": "E : verser les pots de couleur dans la Palette", "vr": "Gâchette : verser les pots dans la Palette",
		"call": verser, "when": func(): return not pots_en_poche().is_empty()})
	d._interactions.append({"id": "crayon_palette_tremper", "pos": pal, "radius": 5.0,
		"text": "E : tremper le pinceau dans la Palette", "vr": "Gâchette : tremper le pinceau",
		"call": tremper, "when": func(): return pots_en_poche().is_empty() and a_le_pinceau() and nb_pots() > 0 and int(cr.state.get("peinture", 0)) < PINCEAU_MAX})
	d._interactions.append({"id": "crayon_poulie", "pos": poulie_haut, "radius": 1.9,
		"text": "E : hisser le panier de la poulie", "vr": "Gâchette : hisser le panier",
		"call": hisser, "when": func(): return not bool(cr.state.get("panier", false))})
	d._interactions.append({"id": "crayon_panier", "pos": poulie_bas, "radius": 1.6,
		"text": "E : regarder dans le panier", "vr": "Gâchette : regarder dans le panier",
		"call": hisser, "when": func(): return not bool(cr.state.get("panier", false))})
	d._interactions.append({"id": "crayon_longue_vue", "pos": longue_vue, "radius": 1.8,
		"text": "E : regarder dans la longue-vue", "vr": "Gâchette : regarder dans la longue-vue", "call": regarder_longue_vue})
	_it_pinceau = {"id": "crayon_pinceau", "pos": Vector3(0, -1000, 0), "radius": 1.4,
		"text": "E : donner un coup de pinceau", "vr": "Gâchette : donner un coup de pinceau",
		"call": coup_de_pinceau, "when": _pinceau_possible}
	d._interactions.append(_it_pinceau)


## Le panier de la poulie (sous la terrasse du Conseil) : le pot de brun y est tombé la nuit de l'Averse.
func hisser() -> void:
	if bool(cr.state.get("panier", false)):
		return
	var inv: Node = _inv()
	if inv == null or inv.add("pot_brun", 1) <= 0:
		cr.say("Ton sac est plein : fais-y un peu de place pour le pot de couleur.", 5.0)
		return
	cr.state["panier"] = true
	main.sfx("ramasse", poulie_haut)
	cr.say("Le panier remonte en grinçant… Au fond, un petit pot de peinture, tout cabossé, une étiquette : « 5 ». + Pot de brun (n° 5). À verser dans son godet de la Palette de pierre !", 9.0)


func regarder_longue_vue() -> void:
	cr.state["longue_vue"] = true
	var reste: Array = []
	var inv: Node = _inv()
	for c in ORDRE:
		if poured().has(c) or (inv != null and inv.count("pot_" + str(c)) > 0):
			continue
		reste.append(c)
	var txt: String = "Dans la longue-vue, toute l'île, en noir et blanc…"
	if reste.has("violet"):
		txt += " Tout là-haut, au sommet du Mont Fusain, à côté du cairn : un petit éclat qui brille. Violet. Un pot !"
	elif reste.is_empty():
		txt += " Plus un seul pot à chercher : ils sont tous retrouvés !"
	else:
		var noms: Array = []
		for c2 in reste:
			noms.append("%s (%s)" % [str(POTS[c2][1]), str(POTS[c2][4])])
		txt += " Il manque encore " + ", ".join(noms) + "."
	cr.say(txt, 9.0)


func verser() -> void:
	var inv: Node = _inv()
	var list: Array = pots_en_poche()
	if inv == null or list.is_empty():
		return
	var pots: Dictionary = cr.state["pots"]
	var noms: Array = []
	for c in list:
		inv.remove("pot_" + str(c), 1)
		pots[c] = true
		noms.append("n° %d, %s" % [int(POTS[c][0]), str(POTS[c][1])])
		_godet(str(c))
		var rg: Array = POTS[c][3]
		(cr.state["taches"] as Array).append([float(rg[0]), float(rg[1]), float(rg[2])])
		_vagues.append({"l": Vector2(float(rg[0]), float(rg[1])), "r": float(rg[2]), "dur": 6.0 + float(rg[2]) * 0.08})
	main.sfx("verser", cr.palette_at)
	var n: int = pots.size()
	if n >= ORDRE.size():
		_vagues.clear()
		cr.say("Le dernier pot (%s) retrouve son godet… Les neuf couleurs sont à leur place ! Toute la Palette brille." % ", ".join(noms), 8.0)
		start_fete()
	else:
		cr.say("%s retrouve son godet : la couleur coule dans la pierre, et l'île reprend ses couleurs, là-bas, dans %s ! (%d pots sur 9)" % [
			("Le pot " + str(noms[0])) if noms.size() == 1 else "Les pots " + ", ".join(noms), str(POTS[list[-1]][4]), n], 9.0)
		if main.has_method("jingle"):
			main.jingle("decouverte")


func tremper() -> void:
	cr.state["peinture"] = PINCEAU_MAX
	main.sfx("verser", cr.palette_at, -6.0)
	var inv: Node = _inv()
	var en_main: bool = inv != null and str(inv.equipped) == "pinceau"
	cr.say("Le Pinceau de l'île boit la couleur de la Palette : %d coups de pinceau.%s" % [PINCEAU_MAX, "" if en_main else " (Prends-le en main dans ton sac, puis E devant ce que tu veux peindre.)"], 7.0)


func _pinceau_possible() -> bool:
	var inv: Node = _inv()
	if inv == null or str(inv.equipped) != "pinceau":
		return false
	var p: Vector3 = main._player_pos_v27()
	if not cr.contains(p):
		return false
	if inv.nearest_pickup(p) >= 0:
		return false
	var d: Node = main.get("donjon_v35")
	if d == null:
		return false
	for it in d._interactions:
		if it == _it_pinceau:
			continue
		if it.has("when") and not bool((it["when"] as Callable).call()):
			continue
		var q: Vector3 = it["pos"]
		if Vector2(q.x - p.x, q.z - p.z).length() < float(it["radius"]) and absf(q.y - p.y) < 2.5:
			return false
	return true


func coup_de_pinceau() -> void:
	if int(cr.state.get("peinture", 0)) <= 0:
		cr.say("Le pinceau est sec. Trempe-le dans la Palette de pierre, au milieu de la clairière (il faut qu'une couleur y soit revenue).", 6.0)
		return
	var at: Vector3 = main._drop_point_v28()
	var fwd: Vector3 = at - main._player_pos_v27()
	fwd.y = 0.0
	if fwd.length() > 0.01:
		at += fwd.normalized() * 0.9
	cr.colorier(at, 3.0, 1.4)
	cr.state["peinture"] = int(cr.state["peinture"]) - 1
	cr.state["coups"] = int(cr.state.get("coups", 0)) + 1
	main.sfx("verser", at, -8.0)
	var hero: Node = main.get("hero_v28")
	if hero != null and hero.has_method("play_action"):
		hero.play_action("pickup", at)
	if int(cr.state["coups"]) == 1:
		cr.say("Un coup de pinceau… et la couleur s'étale sur la page ! (Il reste %d coups ; on recharge à la Palette.)" % int(cr.state["peinture"]), 6.0)


## Le godet n de la Palette se remplit de sa couleur (pas de rendu coloriage : la peinture brille).
func _godet(c: String) -> void:
	if _godet_nodes.has(c) or cr.godets.size() < 9:
		return
	var i: int = int(POTS[c][0]) - 1
	var mi := MeshInstance3D.new()
	mi.name = "Godet_%d_%s" % [i + 1, c]
	var cm := CylinderMesh.new()
	cm.top_radius = 0.245
	cm.bottom_radius = 0.245
	cm.height = 0.03
	cm.radial_segments = 20
	cm.rings = 1
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = POTS[c][2]
	m.roughness = 0.12
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (cr.godets[i] as Vector3) + Vector3.UP * 0.045
	_godet_nodes[c] = mi


func refresh_godets() -> void:
	for c in _godet_nodes.keys():
		if not poured().has(c):
			(_godet_nodes[c] as Node).queue_free()
			_godet_nodes.erase(c)
	for c2 in poured():
		_godet(str(c2))


# =================================================================== la vague de couleur

func _set_vague(v: Vector4) -> void:
	RenderingServer.global_shader_parameter_set("crayon_vague", v)


func reset_vagues() -> void:
	_vague = {}
	_vagues.clear()
	_bake = {}
	_set_vague(Vector4(0, 0, -10.0, 4.0))


func _tick_vagues(delta: float) -> void:
	if not _bake.is_empty():
		# la région, peinte pour de bon dans la carte des couleurs : 24 rangées par image
		var z0: int = int(_bake["z"])
		var z1: int = mini(z0 + 24, int(_bake["z_end"]))
		cr.paint_rows(_bake["l"], float(_bake["r"]), z0, z1)
		_bake["z"] = z1
		if z1 >= int(_bake["z_end"]):
			cr.flush_mask()
			_bake = {}
			_set_vague(Vector4(0, 0, -10.0, 4.0))
		return
	if _vague.is_empty():
		if _vagues.is_empty():
			return
		_vague = _vagues.pop_front()
		_vague["t"] = 0.0
	_vague["t"] = float(_vague["t"]) + delta
	var k: float = clampf(float(_vague["t"]) / float(_vague["dur"]), 0.0, 1.0)
	var r: float = float(_vague["r"]) * (1.0 - pow(1.0 - k, 2.0))
	var w: Vector3 = IleScript.W(_vague["l"].x, _vague["l"].y)
	_set_vague(Vector4(w.x, w.z, maxf(r, 0.01), 4.0))
	if k >= 1.0:
		if bool(_vague.get("tout", false)):
			cr.fill_mask()
			_set_vague(Vector4(0, 0, -10.0, 4.0))
		else:
			var rows: Vector2i = cr.rows_for(_vague["l"], float(_vague["r"]))
			_bake = {"l": _vague["l"], "r": float(_vague["r"]), "z": rows.x, "z_end": rows.y}
		_vague = {}


# =================================================================== la fête des couleurs

func start_fete() -> void:
	cr.state["fete"] = true
	_vagues.append({"l": Vector2.ZERO, "r": IleScript.HALF * 1.45, "dur": 14.0, "tout": true})
	fete = 40.0
	_cheer_t = 0.0
	if main.has_method("jingle"):
		main.jingle("victoire")
	main.sfx("confettis", cr.palette_at)
	main._show_message_v28("Les neuf couleurs sont revenues ! Toute l'Île Crayonnée retrouve ses couleurs, d'un coup, comme une aquarelle qui s'étale…")
	if _confettis == null:
		_confettis = _make_confettis()
	_confettis.emitting = true
	for npc in habitants:
		if is_instance_valid(npc) and npc.has_method("cheer"):
			npc.cheer(8.0, "Nos couleurs !")


func _make_confettis() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Confettis_des_couleurs"
	p.amount = 160
	p.lifetime = 5.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(8.0, 0.5, 8.0)
	p.direction = Vector3.DOWN
	p.spread = 25.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, -1.2, 0)
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.06)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.6
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875])
	var cols := PackedColorArray()
	for c in ORDRE:
		if cols.size() < 8:
			cols.append(POTS[c][2])
	g.colors = cols
	p.color_initial_ramp = g
	p.emitting = false
	add_child(p)
	p.global_position = cr.palette_at + Vector3.UP * 9.0
	return p


func _tick_fete(delta: float) -> void:
	if fete <= 0.0:
		return
	fete -= delta
	_cheer_t -= delta
	if _cheer_t <= 0.0 and not habitants.is_empty():
		_cheer_t = 2.2
		var lines: Array = ["Nos couleurs !", "Hourra !", "Que c'est beau !", "Merci !", "Toutes les couleurs !", "Vive la Palette !"]
		var npc: Node = habitants[_cheer_i % habitants.size()]
		_cheer_i += 1
		if is_instance_valid(npc) and npc.has_method("cheer"):
			npc.cheer(4.0, str(lines[_cheer_i % lines.size()]))
	if fete <= 0.0 and _confettis != null:
		_confettis.emitting = false


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or cr == null:
		return
	_tick_vagues(delta)
	_tick_fete(delta)
	if not _it_pinceau.is_empty():
		var p: Vector3 = main._player_pos_v27()
		if cr.contains(p):
			var at: Vector3 = main._drop_point_v28() if main.has_method("_drop_point_v28") else p
			var f: Vector3 = at - p
			f.y = 0.0
			_it_pinceau["pos"] = p + (f.normalized() * 0.6 if f.length() > 0.01 else Vector3.ZERO)
			var n: int = int(cr.state.get("peinture", 0))
			_it_pinceau["text"] = ("E : donner un coup de pinceau (%d)" % n) if n > 0 else "E : le pinceau est sec"
			_it_pinceau["vr"] = ("Gâchette : coup de pinceau (%d)" % n) if n > 0 else "Pinceau sec : trempe-le dans la Palette"
		else:
			_it_pinceau["pos"] = Vector3(0, -1000, 0)


# =================================================================== sauvegarde

func on_load() -> void:
	reset_vagues()
	refresh_godets()
	spawn_free_pots()


func trouvailles() -> Dictionary:
	return {"crayon_panier": 1 if bool(cr.state.get("panier", false)) else 0,
		"crayon_longue_vue": 1 if bool(cr.state.get("longue_vue", false)) else 0,
		"crayon_pots_1": 1 if nb_pots() >= 1 else 0,
		"crayon_pots_9": 1 if nb_pots() >= 9 else 0,
		"crayon_pinceau": 1 if int(cr.state.get("coups", 0)) > 0 else 0,
		"crayon_couleurs": 1 if bool(cr.state.get("fete", false)) else 0}

extends Node3D
## V71 : Montjoie, la ville fortifiée des aventuriers, bâtie en terrasses sur sa butte
## (ile_montjoie_v71.gd donne le relief : le Château, la Haute-Ville, la Ville-Moyenne, la
## Basse-Ville, le rempart, les rampes en lacets). Ici, tout ce qui est bâti :
##  - les murs de soutènement des terrasses et leurs parapets ; les rampes en lacets qui montent le
##    long de ces murs, leurs murets ; le rempart, ses tours rondes, ses trois portes ;
##  - des centaines de maisons à pans de bois, rangées le long des rues en anneau (montjoie_kit_v71
##    les dessine) ; les boutiques ; des réverbères, des bancs, des arbres ;
##  - les grands lieux (le Château, le Temple de l'Aube, la Grand-Place, la Guilde des Aventuriers,
##    l'auberge, la forge, la Chaumière des Glycines, le lavoir, la caserne, l'écurie) :
##    montjoie_lieux_v71.gd ;
##  - le réseau des rues (points, liens) pour les habitants, leurs lieux (spots), leurs portes.
## Le repère : polaire autour du centre de la ville (R.TOWN), en degrés (0 = est, 90 = sud).

const R = preload("res://scripts/ile_montjoie_v71.gd")
const Kit = preload("res://scripts/montjoie_kit_v71.gd")
const Lieux = preload("res://scripts/montjoie_lieux_v71.gd")

const HY: float = R.HAUTE_Y
const MY: float = R.MOY_Y
const BY: float = R.BASSE_Y
const WALL_R: float = 160.0             # le milieu du rempart
## Les rues en anneau : nom -> [rayon, hauteur, nombre de points]
const RINGS := {"hi": [47.0, R.HAUTE_Y + 0.05, 16], "ho": [69.0, R.HAUTE_Y + 0.05, 16], "mi": [84.5, R.MOY_Y + 0.05, 24],
	"mo": [112.5, R.MOY_Y + 0.05, 24], "bi": [128.0, R.BASSE_Y + 0.05, 32], "bo": [154.0, R.BASSE_Y + 0.05, 32]}
## Les grands lieux (pas de maisons) : [nom, angle min, angle max, r min, r max].
const RESERVED := [
	["temple", 52.0, 90.0, 49.0, 74.0],
	["chaumiere", 136.0, 162.0, 49.0, 74.0],
	["belvedere", 100.0, 122.0, 60.0, 74.0],
	["place", 18.0, 60.0, 76.0, 117.0],
	["auberge", 84.0, 104.0, 87.0, 117.0],
	["forge", -32.0, -19.0, 98.0, 117.0],
	["porte_sud", 83.0, 97.0, 129.0, 163.0],
	["porte_nord", -137.0, -123.0, 129.0, 163.0],
	["porte_est", 3.0, 17.0, 129.0, 163.0],
	["lavoir", 140.0, 156.0, 130.0, 153.0],
	["ecurie", -122.0, -104.0, 131.0, 153.0],
	["caserne", 101.0, 117.0, 131.0, 153.0],
	["puits", -64.0, -56.0, 131.0, 141.0],
]
## Les rangées de maisons : [rayon de la façade, sens (-1 : la façade regarde le centre, +1 :
## dehors), profondeur, sol, étages min, étages max, rue (anneau des points), quartier].
const ROWS := [
	[50.5, -1, 10.0, R.HAUTE_Y, 2, 3, "hi", "haute"],
	[88.5, -1, 9.5, R.MOY_Y, 2, 4, "mi", "moyenne"],
	[108.0, 1, 8.5, R.MOY_Y, 2, 3, "mo", "moyenne"],
	[132.0, -1, 9.0, R.BASSE_Y, 2, 3, "bi", "basse"],
	[150.0, 1, 7.5, R.BASSE_Y, 1, 3, "bo", "basse"],
]
## Les boutiques (des maisons de la rue, avec une vitrine et une enseigne) : id -> [angle, rangée,
## enseigne, store].
const SHOPS := {
	"olga": [67.0, 2, "magie", "violet"], "aubin": [76.0, 2, "apothicaire", "vert"],
	"honorine": [13.0, 1, "boulangerie", "jaune"], "colombe": [-7.0, 1, "couture", "rouge"],
	"prosper": [-72.0, 0, "agence", "bleu"], "brunehaut": [-37.0, 2, "forge", ""],
}
const SHOP_SPOTS := {"olga": "magie_comptoir", "aubin": "apothicaire_comptoir", "honorine": "boulangerie_comptoir", "colombe": "couture_comptoir", "prosper": "agence_bureau"}
## Où habitent les autres (la maison libre la plus proche de l'angle, dans la rangée) ; ceux qui
## vivent dans un grand lieu ont leur porte posée par montjoie_lieux_v71 (ou le dehors).
const HOMES := {
	"eglantine": [5.0, 1], "violette": [-95.0, 0], "tancrede": [-95.0, 3], "hilaire": [176.0, 4], "lison": [-160.0, 3],
	"rodrigue": [-165.0, 4], "bertrand": [-150.0, 1], "gilles": [-145.0, 4], "melusine": [-20.0, 1], "babette": [125.0, 3],
	"philomene": [125.0, 0], "petronille": [44.0, 0],
}

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var lieux                                # montjoie_lieux_v71
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}              # nom -> Vector3 (les comptoirs, les invites, les lieux des quêtes)
var flora_avoid: Array = []
var fire_spots: Array = []               # [Vector3, taille]
var smoke_spots: Array = []
var tree_spots: Array = []               # Vector3 : les arbres plantés dans la ville
var houses: Array = []                   # {deg, r, row, door, w, street, owner}
var districts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _store: Dictionary = {}
var _cur: String = ""
var _shop_done: Dictionary = {}


# =================================================================== repère polaire

func PW(deg: float, r: float, y: float) -> Vector3:
	return R.PW(deg, r, y)


## Un point au sol (la hauteur du relief).
func PG(deg: float, r: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.PW(deg, r, 0.0)
	w.y = ile.height(w.x, w.z) + dy
	return w


static func radial(deg: float) -> Vector3:
	return Vector3(cos(deg_to_rad(deg)), 0.0, sin(deg_to_rad(deg)))


static func tangent(deg: float) -> Vector3:
	return Vector3(-sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg)))


## Un repère au point polaire (deg, r, y) dont le +Z regarde « in » (le centre), « out », « cw »
## (vers les angles croissants) ou « ccw ».
func PX(deg: float, r: float, y: float, facing: String) -> Transform3D:
	var f: Vector3
	match facing:
		"in":
			f = -radial(deg)
		"out":
			f = radial(deg)
		"cw":
			f = tangent(deg)
		_:
			f = -tangent(deg)
	return Transform3D(Basis.looking_at(-f, Vector3.UP), PW(deg, r, y))


static func XD(p: Vector3, dir: Vector3) -> Transform3D:
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


static func in_arc(a: float, a0: float, a1: float) -> bool:
	return wrapf(a - a0, 0.0, 360.0) <= wrapf(a1 - a0, 0.0, 360.0)


static func reserved(deg: float, r: float) -> String:
	for z in RESERVED:
		if r >= float(z[3]) and r <= float(z[4]) and in_arc(deg, float(z[1]), float(z[2])):
			return str(z[0])
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


## Le quartier d'un angle (huit secteurs par terrasse : un maillage par secteur).
func _district_of(zone: String, deg: float) -> String:
	var a: float = wrapf(deg, -180.0, 180.0)
	var oct: int = int(floor((a + 180.0) / 45.0)) % 8
	return "%s_%d" % [zone, oct]


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 7171
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 7172
	kit.light_every = 2
	lieux = Lieux.new()
	lieux.setup(self)
	_district("chateau")
	lieux.chateau()
	_district("murs")
	_terrace_walls()
	_ramps()
	_district("rempart")
	_rempart()
	_district("haute_3")
	lieux.temple()
	_district("haute_6")
	lieux.chaumiere()
	lieux.belvedere()
	_district("moyenne_4")
	lieux.grand_place()
	lieux.guilde()
	_district("moyenne_5")
	lieux.auberge()
	_district("moyenne_3")
	lieux.forge()
	_district("basse_7")
	lieux.lavoir()
	_district("basse_5")
	lieux.caserne()
	_district("basse_1")
	lieux.ecurie()
	lieux.puits()
	var t1: int = Time.get_ticks_msec()
	for i in range(ROWS.size()):
		_fill_row(i)
	var t2: int = Time.get_ticks_msec()
	_streets()
	_commit_all()
	_homes()
	_graph()
	for f in kit.fires70:
		fire_spots.append(f)
	for c in kit.chimneys70:
		if _rng.randf() < 0.3:
			smoke_spots.append(c)
	# les trois pages du grimoire de Madame Olga, envolées : la Grand-Place, la Haute-Ville
	# (au belvédère), la Basse-Ville (au lavoir)
	for pg in [["page_grimoire_1", "place_banc_2", Vector3(1.2, 0.0, 0.8)], ["page_grimoire_2", "haute_belvedere", Vector3(-1.4, 0.0, 0.6)], ["page_grimoire_3", "lavoir_2", Vector3(1.0, 0.0, -1.2)]]:
		if spots.has(str(pg[1])):
			objets[str(pg[0])] = (spots[str(pg[1])]["pos"] as Vector3) + (pg[2] as Vector3)
	print("ILE_MANGA_V71: Montjoie bâtie, %d maisons, %d lieux, %d points, %d pièces répétées, %d réverbères, en %d ms (maisons %d ms)" % [houses.size(), spots.size(), points.size(), kit.inst_count, kit.lamps70.size(), Time.get_ticks_msec() - t0, t2 - t1])


# =================================================================== murs de soutènement, rampes

## Le haut d'une rampe (ses angles) : on y arrive sur la terrasse d'en haut, pas de parapet.
func _ramp_top_near(deg: float, r_drop: float, margin: float) -> bool:
	for k in R.RAMPS:
		var rp: Array = R.RAMPS[k]
		if absf(float(rp[0]) - r_drop) > 0.5:
			continue
		if absf(R._adiff(deg, float(rp[3]))) * PI / 180.0 * r_drop < margin:
			return true
	return false


## Les murs de soutènement des trois terrasses (le Château a son enceinte : montjoie_lieux).
func _terrace_walls() -> void:
	for spec in [[R.CAST_R, R.CAST_Y, HY, 72], [R.HAUTE_R, HY, MY, 144], [R.MOY_R, MY, BY, 192]]:
		var rd: float = float(spec[0])
		var top: float = float(spec[1])
		var low: float = float(spec[2])
		var n: int = int(spec[3])
		var rm: float = rd - 1.65              # le mur couvre de rd - 3,4 à rd + 0,1 (la marche du relief est dessous)
		for k in range(n):
			var a0: float = 360.0 * k / n
			var a1: float = 360.0 * (k + 1) / n
			var am: float = (a0 + a1) * 0.5
			_district(_district_of("murs", am))
			var len: float = deg_to_rad(a1 - a0) * rd + 0.06
			var bs := Basis(Vector3.UP, -deg_to_rad(am))
			kit.box(Transform3D(bs, PW(am, rm, (top + low) * 0.5 - 0.5)), Vector3(3.5, top - low + 1.0, len), "rempart71", 2.6, 63 - 8)
			kit.col_box(Transform3D(bs, PW(am, rm, (top + low) * 0.5 - 0.5)), Vector3(3.5, top - low + 1.0, len))
			kit.box(Transform3D(bs, PW(am, rd + 0.05, top - 0.12)), Vector3(0.5, 0.24, len), "dalles71_clair", 1.4)
			# le parapet (sauf en haut des rampes)
			if rd > R.CAST_R + 1.0 and not _ramp_top_near(am, rd, 4.5):
				kit.box(Transform3D(bs, PW(am, rd - 0.3, top + 0.45)), Vector3(0.45, 0.9, len), "rempart71_clair", 1.6)
				kit.col_box(Transform3D(bs, PW(am, rd - 0.3, top + 0.55)), Vector3(0.45, 1.1, len))
			# des contreforts, de temps en temps
			if k % 8 == 3:
				kit.box(Transform3D(bs, PW(am, rd + 0.6, low + (top - low) * 0.4)), Vector3(1.4, (top - low) * 0.8, 1.2), "rempart71_sombre", 1.6)


## Les rampes en lacets : leur muret extérieur (qui suit la pente), le mur du bout, des lanternes.
func _ramps() -> void:
	for k in R.RAMPS:
		var rp: Array = R.RAMPS[k]
		var r0: float = float(rp[0])
		var w: float = float(rp[1])
		var a_lo: float = float(rp[2])
		var a_hi: float = float(rp[3])
		var y_lo: float = float(rp[4])
		var y_hi: float = float(rp[5])
		var span: float = R._adiff(a_hi, a_lo)
		var n: int = maxi(int(absf(span) * PI / 180.0 * (r0 + w) / 2.0), 6)
		_district(_district_of("murs", a_lo + span * 0.5))
		for i in range(n):
			var t0: float = float(i) / n
			var t1: float = float(i + 1) / n
			var am: float = a_lo + span * (t0 + t1) * 0.5
			var ym: float = lerpf(y_lo, y_hi, (t0 + t1) * 0.5)
			var len: float = absf(deg_to_rad(span / n)) * (r0 + w) + 0.08
			var bs := Basis(Vector3.UP, -deg_to_rad(am))
			var hh: float = ym - y_lo + 1.0
			if ym - y_lo < 1.2:
				continue
			kit.box(Transform3D(bs, PW(am, r0 + w + 0.35, y_lo - 0.5 + hh * 0.5 + 0.25)), Vector3(0.7, hh + 0.5, len), "rempart71", 2.0, 63 - 8)
			kit.col_box(Transform3D(bs, PW(am, r0 + w + 0.35, y_lo - 0.5 + (hh + 0.5) * 0.5 + 0.25)), Vector3(0.7, hh + 0.5, len))
			kit.box(Transform3D(bs, PW(am, r0 + w + 0.35, ym + 1.05)), Vector3(0.8, 0.12, len), "dalles71_clair", 1.0)
			if i % 4 == 2:
				kit.lamp70(PW(am, r0 + w - 0.6, ym), 3.6, true, false)
		# le mur du bout, en haut : la rampe s'arrête au ras de la terrasse
		var ae: float = a_hi + signf(span) * rad_to_deg(0.4 / (r0 + w * 0.5))
		var be := Basis(Vector3.UP, -deg_to_rad(ae) + PI * 0.5)
		kit.box(Transform3D(be, PW(ae, r0 + w * 0.5, (y_hi + y_lo) * 0.5 + 0.5)), Vector3(0.7, y_hi - y_lo + 2.0, w + 1.2), "rempart71", 2.0, 63 - 8)
		kit.col_box(Transform3D(be, PW(ae, r0 + w * 0.5, (y_hi + y_lo) * 0.5 + 0.5)), Vector3(0.7, y_hi - y_lo + 2.0, w + 1.2))
		_avoid(PW(a_lo + span * 0.5, r0 + w * 0.5, 0.0), absf(deg_to_rad(span)) * r0 * 0.5)


# =================================================================== le rempart

func _rempart() -> void:
	var nseg: int = 96
	for k in range(nseg):
		var a0: float = 360.0 * k / nseg
		var a1: float = 360.0 * (k + 1) / nseg
		if _near_gate((a0 + a1) * 0.5, 9.0):
			continue
		_district(_district_of("rempart", (a0 + a1) * 0.5))
		var g0: Vector3 = PG(a0, WALL_R + 3.0)
		var g1: Vector3 = PG(a1, WALL_R + 3.0)
		var y0: float = minf(minf(g0.y, g1.y), BY) - 0.6
		kit.wall_line(PW(a0, WALL_R, y0), PW(a1, WALL_R, y0), BY + 7.5 - y0, 3.2, "rempart71", true, 1.0, "dalles71")
	# les tours rondes, tous les 20°
	for k2 in range(18):
		var a: float = 360.0 * k2 / 18.0 + 10.0
		if _near_gate(a, 16.0):
			continue
		_district(_district_of("rempart", a))
		var gy: float = minf(PG(a, WALL_R + 4.0).y, BY)
		kit.tower70(PW(a, WALL_R + 1.0, gy - 0.5), 3.8, BY + 11.0 - gy, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 7.5,
			"windows": [BY + 4.5 - gy], "nwin": 3, "lit": 0.4, "wall": "rempart71", "trim": "rempart71_sombre"})
		_avoid(PW(a, WALL_R + 1.0, 0.0), 6.0)
	# les trois portes : un porche entre deux tours, la bannière de la ville
	for gname in R.GATES:
		var a2: float = float(R.GATES[gname])
		_district(_district_of("rempart", a2))
		var gx: Transform3D = PX(a2, WALL_R, BY, "out")
		kit.arch_gate(gx, 5.6, 6.4, 4.0, 10.0, "rempart71")
		kit.crenels(gx * Vector3(-5.2, 10.0, 1.6), gx * Vector3(5.2, 10.0, 1.6), 0.5, "rempart71")
		kit.flag69(gx * kit.T(-0.7, 9.4, 2.1) * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3.ZERO), "banniere71", Vector2(3.0, 1.4))
		for s in [-1.0, 1.0]:
			var tp: Vector3 = gx * Vector3(s * 6.8, 0, 0.4)
			var gy2: float = minf(PG(a2, WALL_R + 5.0).y, BY)
			kit.tower70(Vector3(tp.x, gy2 - 0.5, tp.z), 4.2, BY + 13.0 - gy2, {"roof": "cone", "roof_key": "tuiles71_ardoise", "roof_h": 9.0,
				"windows": [BY + 5.0 - gy2, BY + 9.0 - gy2], "nwin": 3, "lit": 0.5, "wall": "rempart71", "trim": "rempart71_sombre"})
			kit.lamp70(gx * Vector3(s * 3.8, 0, -3.0), 4.0, true, false)
			kit.lamp70(PG(a2, WALL_R + 5.5) + tangent(a2) * s * 3.8, 4.0, true, false)
		_avoid(PW(a2, WALL_R, 0.0), 14.0)


static func _near_gate(deg: float, deg_margin: float) -> bool:
	for g in R.GATES:
		if absf(R._adiff(deg, float(R.GATES[g]))) < deg_margin * 0.5 + 2.0:
			return true
	return false


# =================================================================== les maisons

## Les ruelles rayonnantes d'un quartier : [angle, demi-largeur].
func _radials(zone: String) -> Array:
	var out: Array = []
	var n: int = {"haute": 16, "moyenne": 24, "basse": 32}[zone]
	for k in range(n):
		var a: float = -180.0 + 360.0 * k / n + (5.0 if zone == "moyenne" else 0.0)
		var hw: float = 2.0 if k % 2 == 1 else 2.8
		out.append([a, hw])
	return out


func _fill_row(ri: int) -> void:
	var row: Array = ROWS[ri]
	var r: float = float(row[0])
	var sens: int = int(row[1])
	var depth: float = float(row[2])
	var zone: String = str(row[7])
	var rads: Array = _radials(zone)
	var n: int = rads.size()
	for i in range(n):
		var a0: float = float(rads[i][0])
		var a1: float = float(rads[(i + 1) % n][0])
		if a1 <= a0:
			a1 += 360.0
		var start: float = a0 + rad_to_deg((float(rads[i][1]) + 0.4) / r)
		var stop: float = a1 - rad_to_deg((float(rads[(i + 1) % n][1]) + 0.4) / r)
		_district(_district_of(zone, (a0 + a1) * 0.5))
		var cur: float = start
		var limit: int = 0
		while cur < stop and limit < 40:
			limit += 1
			var w: float = _rng.randf_range(6.8, 9.0) if zone == "haute" else _rng.randf_range(5.4, 8.2)
			var aw: float = rad_to_deg(w / r)
			if cur + aw > stop:
				var rem: float = deg_to_rad(stop - cur) * r
				if rem < 4.6:
					break
				w = rem
				aw = stop - cur
			var mid: float = cur + aw * 0.5
			if not _footprint_free(mid, r, w, depth, sens):
				cur += rad_to_deg(1.5 / r)
				continue
			_house(ri, mid, r, w, depth, sens)
			cur += aw + rad_to_deg(_rng.randf_range(0.0, 0.2) / r)


func _footprint_free(mid: float, r: float, w: float, depth: float, sens: int) -> bool:
	var half: float = rad_to_deg(w * 0.5 / r)
	var rb: float = r - sens * depth
	for p in [[mid - half, r], [mid + half, r], [mid - half, rb], [mid + half, rb], [mid, (r + rb) * 0.5]]:
		if reserved(float(p[0]), float(p[1])) != "":
			return false
	return true


func _house(ri: int, deg: float, r: float, w: float, depth: float, sens: int) -> void:
	var row: Array = ROWS[ri]
	var y: float = float(row[3])
	var zone: String = str(row[7])
	var xf: Transform3D = PX(deg, r, y, "in" if sens < 0 else "out")
	var floors: int = _rng.randi_range(int(row[4]), int(row[5]))
	var shop_id: String = ""
	for sid in SHOPS:
		var sp: Array = SHOPS[sid]
		if int(sp[1]) == ri and not _shop_done.has(sid) and absf(R._adiff(deg, float(sp[0]))) < rad_to_deg(w * 0.5 / r):
			shop_id = str(sid)
	var dx: float = _rng.randf_range(-w * 0.2, w * 0.2)
	var opts := {
		"floors": floors, "lit": 0.55 if zone != "basse" else 0.45, "door_x": dx, "gable": _rng.randf() < 0.7,
		"base": "moellons71" if _rng.randf() < 0.55 else "enduit71_" + Kit.ENDUIT_V[_rng.randi() % Kit.ENDUIT_V.size()],
		"gf": 3.2, "uf": 2.9, "jet": _rng.randf_range(0.2, 0.45), "sides": 0,
	}
	if zone == "haute":
		opts["gf"] = 3.5
		opts["uf"] = 3.1
		opts["flowers"] = true
	if shop_id != "":
		var spd: Array = SHOPS[shop_id]
		opts["shop"] = str(spd[2])
		opts["awning"] = str(spd[3])
		opts["door_x"] = -w * 0.25
		opts["floors"] = maxi(floors, 2)
		_shop_done[shop_id] = true
	var door: Vector3 = kit.house71(xf, w, depth, opts)
	door.y = y + 0.05
	var h := {"deg": deg, "r": r, "row": ri, "door": door, "w": w, "street": str(row[6]), "xf": xf}
	if shop_id != "":
		h["owner"] = shop_id
		h["shop"] = str(SHOPS[shop_id][2])
		doors["porte_" + shop_id] = _pt("porte_" + shop_id, door)
		# le comptoir de la boutique : une table devant la vitrine, sous le store ; le marchand
		# derrière, le client devant
		var cx: float = w * 0.22
		kit.counter71(xf * kit.T(cx, 0, 2.2), 1.8, "planches71_clair")
		objets["comptoir_" + shop_id] = xf * Vector3(cx, 0.05, 3.3)
		var sname: String = str(SHOP_SPOTS.get(shop_id, ""))
		if sname != "":
			var node: String = _pt("pt_" + sname, xf * Vector3(cx + 1.7, y + 0.05 - xf.origin.y, 1.3))
			_spot(sname, xf * Vector3(cx, y + 0.05 - xf.origin.y, 0.95), xf.basis * Vector3(0, 0, 1), "comptoir", node)
	houses.append(h)
	_avoid(xf * Vector3(0, 0, -depth * 0.5), maxf(w, depth) * 0.6)


## Les portes des habitants : la maison libre la plus proche de l'angle voulu, dans la rangée.
func _homes() -> void:
	var taken: Dictionary = {}
	for i0 in range(houses.size()):
		if (houses[i0] as Dictionary).has("owner"):
			taken[i0] = true
	for id in HOMES:
		var want: Array = HOMES[id]
		var best: int = -1
		var bd: float = INF
		for i in range(houses.size()):
			var h: Dictionary = houses[i]
			if int(h["row"]) != int(want[1]) or taken.has(i):
				continue
			var d: float = absf(R._adiff(float(h["deg"]), float(want[0])))
			if d < bd:
				bd = d
				best = i
		if best < 0:
			continue
		taken[best] = true
		var hh: Dictionary = houses[best]
		doors["porte_" + str(id)] = _pt("porte_" + str(id), hh["door"])
		hh["owner"] = str(id)
	# les familles : Noisette chez sa mère, Titouan chez la sienne
	if doors.has("porte_honorine"):
		doors["porte_noisette"] = _pt("porte_noisette", points["porte_honorine"])
	if doors.has("porte_brunehaut"):
		doors["porte_titouan"] = _pt("porte_titouan", points["porte_brunehaut"])


# =================================================================== les rues

func _streets() -> void:
	# la rue de la Haute-Ville : des réverbères, des tilleuls, des bancs
	for k in range(32):
		var a: float = 360.0 * (k + 0.5) / 32.0
		if reserved(a, 47.0) != "":
			continue
		_district(_district_of("haute", a))
		kit.lamp70(PW(a, 44.6 if R.ramp_at(PW(a, 44.6, 0).x - R.CENTER.x, PW(a, 44.6, 0).z - R.CENTER.z) == "" else 49.5, HY), 3.8, true, false)
	# la promenade (le bord de la Haute-Ville) : des arbres, des bancs face au paysage
	for k2 in range(36):
		var a2: float = 360.0 * (k2 + 0.5) / 36.0
		if reserved(a2, 69.0) == "temple" or reserved(a2, 69.0) == "chaumiere":
			continue
		if R.ramp_at(PW(a2, 72.0, 0).x - R.CENTER.x, PW(a2, 72.0, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("haute", a2))
		if k2 % 3 == 0:
			tree_spots.append(PW(a2, 64.0, HY))
		elif k2 % 3 == 1:
			kit.bench71(PX(a2, 71.8, HY, "out") * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO))
		else:
			kit.lamp70(PW(a2, 72.4, HY), 3.6, true, false)
	# la Ville-Moyenne : des lanternes contre les maisons, des réverbères au bord du mur
	for k3 in range(48):
		var a3: float = 360.0 * (k3 + 0.5) / 48.0
		if reserved(a3, 113.0) != "" or _ramp_top_near(a3, R.MOY_R, 6.0):
			continue
		_district(_district_of("moyenne", a3))
		kit.lamp70(PW(a3, 115.6, MY), 3.8, true, false)
		if k3 % 4 == 1:
			kit.bench71(PX(a3 + 1.5, 115.4, MY, "in"))
	for k4 in range(40):
		var a4: float = 360.0 * (k4 + 0.5) / 40.0
		if reserved(a4, 84.5) != "" or R.ramp_at(PW(a4, 80.0, 0).x - R.CENTER.x, PW(a4, 80.0, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("moyenne", a4))
		kit.lamp70(PW(a4, 80.6, MY), 3.8, true, false)
	# la Basse-Ville : des réverbères le long des deux rues, des lanternes au rempart
	for k5 in range(56):
		var a5: float = 360.0 * (k5 + 0.5) / 56.0
		var rr: float = 128.0 + (2.6 if k5 % 2 == 0 else -2.4)
		if reserved(a5, rr) != "" or R.ramp_at(PW(a5, rr, 0).x - R.CENTER.x, PW(a5, rr, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("basse", a5))
		kit.lamp70(PW(a5, rr, BY), 3.8, true, false)
	for k6 in range(64):
		var a6: float = 360.0 * (k6 + 0.5) / 64.0
		if _near_gate(a6, 10.0) or reserved(a6, 156.0) != "":
			continue
		_district(_district_of("basse", a6))
		kit.wall_lamp70(PX(a6, WALL_R - 1.65, BY + 3.2, "in"), k6 % 2 == 0)
		if k6 % 6 == 3:
			kit.barrel71(PW(a6, 157.0, BY))
		elif k6 % 6 == 0:
			kit.crate71(PW(a6 + 0.8, 156.6, BY), deg_to_rad(a6))


# =================================================================== le réseau des rues

func ring_node(ring: String, k: int) -> String:
	return "%s_%d" % [ring, k]


func ring_angle(ring: String, k: int) -> float:
	var n: int = int(RINGS[ring][2])
	return -180.0 + 360.0 * k / n + (5.0 if ring in ["mi", "mo"] else 0.0)


func nearest_ring(ring: String, deg: float) -> String:
	var n: int = int(RINGS[ring][2])
	var best: String = ""
	var bd: float = INF
	for k in range(n):
		var nm: String = ring_node(ring, k)
		if not points.has(nm):
			continue
		var d: float = absf(R._adiff(ring_angle(ring, k), deg))
		if d < bd:
			bd = d
			best = nm
	return best


## Un point d'une rampe : t de 0 (en bas) à 1 (en haut), au milieu de la chaussée.
func ramp_point(key: String, t: float) -> Vector3:
	var rp: Array = R.RAMPS[key]
	var a: float = float(rp[2]) + R._adiff(float(rp[3]), float(rp[2])) * t
	return PW(a, float(rp[0]) + float(rp[1]) * 0.5, lerpf(float(rp[4]), float(rp[5]), t) + 0.05)


func _graph() -> void:
	for ring in RINGS:
		var spec: Array = RINGS[ring]
		var n: int = int(spec[2])
		for k in range(n):
			var a: float = ring_angle(ring, k)
			if reserved(a, float(spec[0])) != "":
				continue
			_pt(ring_node(ring, k), PW(a, float(spec[0]), float(spec[1])))
		for k2 in range(n):
			var a0: float = ring_angle(ring, k2)
			if reserved(a0 + 180.0 / n, float(spec[0])) != "":
				continue
			_link(ring_node(ring, k2), ring_node(ring, (k2 + 1) % n))
	# les ruelles : de la rue du haut à celle du bas, à travers les rangées (pas dans les grands lieux)
	for pair in [["hi", "ho", 16], ["mi", "mo", 24], ["bi", "bo", 32]]:
		for k3 in range(int(pair[2])):
			var a3: float = ring_angle(str(pair[0]), k3)
			var rm: float = (float(RINGS[str(pair[0])][0]) + float(RINGS[str(pair[1])][0])) * 0.5
			if reserved(a3, rm) == "" and reserved(a3, float(RINGS[str(pair[0])][0]) + 4.0) == "":
				_link(ring_node(str(pair[0]), k3), ring_node(str(pair[1]), k3))
	# les rampes : du bas (la rue du bas) au haut (la rue de la terrasse d'en haut)
	var ends := {"r1": ["bi", "mo"], "r1b": ["bi", "mo"], "r2": ["mi", "ho"], "r3": ["hi", ""]}
	for k4 in R.RAMPS:
		var names: Array = []
		for i in range(5):
			names.append(_pt("rampe_%s_%d" % [k4, i], ramp_point(str(k4), float(i) / 4.0)))
		var rp: Array = R.RAMPS[k4]
		var lo: String = nearest_ring(str(ends[k4][0]), float(rp[2]))
		_link(lo, names[0])
		_chain(names)
		if str(ends[k4][1]) != "":
			var up: String = nearest_ring(str(ends[k4][1]), float(rp[3]))
			var top_in: String = _pt("rampe_%s_haut" % k4, PW(float(rp[3]), float(rp[0]) - 3.5, float(rp[5]) + 0.05))
			_chain([names[4], top_in, up])
		else:
			lieux.castle_link(names[4])
	# les portes de la ville : de la rue du rempart au dehors
	for g in R.GATES:
		var a5: float = float(R.GATES[g])
		var gp: String = _pt("porte_ville_" + str(g), PW(a5, WALL_R, BY + 0.05))
		var out: String = _pt("dehors_" + str(g), PG(a5, WALL_R + 16.0, 0.05))
		var inner: String = _pt("avenue_" + str(g), PW(a5, 142.0, BY + 0.05))
		_chain([nearest_ring("bi", a5), inner, nearest_ring("bo", a5), gp, out])
		_link(inner, nearest_ring("bo", a5))
	lieux.link_graph()
	for sid in SHOP_SPOTS:
		var nm: String = "pt_" + str(SHOP_SPOTS[sid])
		if points.has(nm):
			_link(nm, _nearest_ring_point(points[nm]))
	_street_spots()
	# les portes des maisons : au point de leur rue le plus proche
	for d in doors:
		var p: Vector3 = points[doors[d]]
		var l: Vector2 = R.L(p.x, p.z)
		var cp: Vector2 = R.town_polar(l.x, l.y)
		var street: String = ""
		for h in houses:
			if (h["door"] as Vector3).distance_to(p) < 0.2:
				street = str(h["street"])
		var best: String = ""
		if street != "":
			best = nearest_ring(street, cp.x)
		if best == "" or (points[best] as Vector3).distance_to(p) > 30.0:
			best = _nearest_point(p, "porte")
		_link(str(doors[d]), best)


## Les lieux des rues : des coins où l'on bavarde, les gardes des portes, le rempart.
func _street_spots() -> void:
	var rues := [["rue_1", "bi", -40.0, 2.4, "debout"], ["rue_2", "bo", 60.0, -2.2, "bras_croises"], ["rue_3", "mi", -80.0, -2.0, "debout"],
		["rue_4", "mo", 140.0, 2.2, "observer"], ["rue_5", "bi", 170.0, -2.4, "debout"], ["rue_6", "hi", -40.0, 2.0, "observer"]]
	for rr in rues:
		var node: String = nearest_ring(str(rr[1]), float(rr[2]))
		var p: Vector3 = points[node]
		var cp: Vector2 = R.town_polar(R.L(p.x, p.z).x, R.L(p.x, p.z).y)
		var off: Vector3 = radial(cp.x) * float(rr[3])
		_spot(str(rr[0]), p + off, -off if str(rr[4]) != "observer" else off, str(rr[4]), node)
	# les gardes des portes : dedans, à côté du porche
	for g in R.GATES:
		var a: float = float(R.GATES[g])
		var p2: Vector3 = PW(a, WALL_R - 4.2, BY + 0.05) + tangent(a) * 3.6
		_spot("porte_" + str(g), p2, radial(a) * -1.0 + tangent(a) * -0.4, "bras_croises", "porte_ville_" + str(g))
	# le chemin de ronde (au pied du rempart, on regarde dehors par une archère)
	_spot("rempart_1", PW(-60.0, 156.2, BY + 0.05), radial(-60.0), "observer", nearest_ring("bo", -60.0))
	_spot("rempart_2", PW(150.0, 156.2, BY + 0.05), radial(150.0), "observer", nearest_ring("bo", 150.0))


## Le point d'une rue en anneau le plus proche (même terrasse).
func _nearest_ring_point(p: Vector3) -> String:
	var best: String = ""
	var bd: float = INF
	for ring in RINGS:
		var n: int = int(RINGS[ring][2])
		for k in range(n):
			var nm: String = ring_node(str(ring), k)
			if not points.has(nm):
				continue
			var q: Vector3 = points[nm]
			var d: float = q.distance_to(p) + absf(q.y - p.y) * 6.0
			if d < bd:
				bd = d
				best = nm
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


# =================================================================== où est-on ?

func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


## Le quartier de la ville (pour la musique, les ambiances, le carnet), ou "".
func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	var cp: Vector2 = R.town_polar(l.x, l.y)
	var lz: String = lieux.zone_at(p) if lieux != null else ""
	if lz != "":
		return lz
	if cp.y > WALL_R + 3.0:
		return ""
	if cp.y < R.CAST_R and p.y > R.CAST_Y - 5.0:
		return "mj_chateau"
	if cp.y < R.HAUTE_R and p.y > R.HAUTE_Y - 5.0:
		return "mj_haute"
	if cp.y < R.MOY_R and p.y > R.MOY_Y - 5.0:
		return "mj_place" if reserved(cp.x, cp.y) == "place" else "mj_moyenne"
	return "mj_basse"

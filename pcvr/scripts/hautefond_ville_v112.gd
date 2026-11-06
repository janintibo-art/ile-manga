extends Node3D
## V112 : Hautefond, la cité-colonne, bâtie en terrasses rondes sur sa butte autour de la Grande
## Colonne (ile_hautefond_v112.gd donne le relief : la Place de la Colonne, la Haute-Ville, la
## Ville-Moyenne, la Basse-Ville, les rampes en lacets). Ici, tout ce qui est bâti :
##  - les murs de soutènement des terrasses (pierre blonde) et leurs balustrades ; les rampes en
##    lacets, leurs murets ; le bord de la Basse-Ville (un parapet, quatre sorties) ;
##  - des centaines de maisons de pierre blonde à toits d'ardoise (hautefond_kit_v112), rangées le
##    long des rues en anneau ; la boutique de l'horloger ; des réverbères à globes, des bancs, des
##    arbres ;
##  - les grands lieux (la Grande Colonne, la Place et la fontaine de Dame Ysolde, l'Observatoire,
##    l'Hôtel de Ville, la Bibliothèque des Cartes, le Grand Marché, la taverne « Le Piston Joyeux »,
##    le Mât des dirigeables, la Forge à vapeur, le lavoir) : hautefond_lieux_v112.gd ;
##  - le réseau des rues (points, liens) pour les habitants, leurs lieux (spots), leurs portes.
## Le repère : polaire autour du centre de la ville (R.TOWN), en degrés (0 = est, 90 = sud).

const R = preload("res://scripts/ile_hautefond_v112.gd")
const Kit = preload("res://scripts/hautefond_kit_v112.gd")
const Lieux = preload("res://scripts/hautefond_lieux_v112.gd")

const CY: float = R.CORE_Y
const HY: float = R.HAUTE_Y
const MY: float = R.MOY_Y
const BY: float = R.BASSE_Y
## Les rues en anneau : nom -> [rayon, hauteur, nombre de points]
const RINGS := {"hi": [49.0, R.HAUTE_Y + 0.05, 16], "ho": [72.5, R.HAUTE_Y + 0.05, 16], "mi": [89.0, R.MOY_Y + 0.05, 24],
	"mo": [118.5, R.MOY_Y + 0.05, 24], "bi": [135.5, R.BASSE_Y + 0.05, 32], "bo": [165.0, R.BASSE_Y + 0.05, 32]}
## Les grands lieux (pas de maisons) : [nom, angle min, angle max, r min, r max].
const RESERVED := [
	["observatoire", -75.0, -35.0, 44.0, 69.0],
	["mairie", 62.0, 102.0, 44.0, 69.0],
	["bibliotheque", 122.0, 158.0, 44.0, 69.0],
	["marche", 100.0, 152.0, 86.0, 124.0],
	["taverne", -102.0, -80.0, 88.0, 124.0],
	["mat", -172.0, -140.0, 88.0, 124.0],
	["forge", 26.0, 46.0, 137.0, 171.0],
	["lavoir", 150.0, 166.0, 137.0, 160.0],
	["porte_port", -51.0, -39.0, 137.0, 176.0],
	["porte_est", 4.0, 16.0, 137.0, 176.0],
	["porte_verger", 89.0, 101.0, 137.0, 176.0],
	["porte_moulin", 174.0, 186.0, 137.0, 176.0],
]
## Les rangées de maisons : [rayon de la façade, sens (-1 : la façade regarde le centre, +1 :
## dehors), profondeur, sol, étages min, étages max, rue (anneau des points), quartier].
const ROWS := [
	[52.5, -1, 10.0, R.HAUTE_Y, 3, 5, "hi", "haute"],
	[92.5, -1, 9.5, R.MOY_Y, 3, 5, "mi", "moyenne"],
	[114.5, 1, 8.5, R.MOY_Y, 3, 4, "mo", "moyenne"],
	[139.0, -1, 9.0, R.BASSE_Y, 2, 4, "bi", "basse"],
	[161.0, 1, 7.5, R.BASSE_Y, 2, 3, "bo", "basse"],
]
## Les boutiques (des maisons de la rue, avec une vitrine et une enseigne) : id -> [angle, rangée,
## enseigne, store].
const SHOPS := {"gaspard": [-34.0, 1, "horloger", "vert"]}
const SHOP_SPOTS := {"gaspard": "horloger_comptoir"}
## Où habitent les autres (la maison libre la plus proche de l'angle, dans la rangée).
const HOMES := {
	"capucine": [50.0, 0], "barnabe": [-120.0, 3], "octave": [-82.0, 0], "philippine": [168.0, 0], "hector": [108.0, 0],
	"rosalie": [96.0, 2], "heloise": [-176.0, 2], "leon": [-60.0, 4], "bastien": [110.0, 4], "ysae": [-130.0, 4],
}

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var lieux                                # hautefond_lieux_v112
var colonne: Node3D                      # hautefond_colonne_v112
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}              # nom -> Vector3 (les comptoirs, les lieux)
var flora_avoid: Array = []
var fire_spots: Array = []               # [Vector3, taille]
var smoke_spots: Array = []
var steam_spots: Array = []
var tree_spots: Array = []               # Vector3 : les arbres plantés dans la ville
var houses: Array = []                   # {deg, r, row, door, w, street, owner}
var crowd_spots: Array = []              # les lieux des passants (des bancs, des coins de rue)
var districts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _store: Dictionary = {}
var _cur: String = ""
var _shop_done: Dictionary = {}


# =================================================================== repère polaire

func PW(deg: float, r: float, y: float) -> Vector3:
	return R.PW(deg, r, y)


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
	_rng.seed = 11271
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 11272
	kit.light_every = 2
	lieux = Lieux.new()
	lieux.setup(self)
	_district("colonne")
	colonne = load("res://scripts/hautefond_colonne_v112.gd").new()
	colonne.name = "Grande_Colonne_v112"
	add_child(colonne)
	colonne.build(main, kit, PW(0.0, 0.0, CY), pc)
	lieux.place_colonne()
	_district("murs")
	_terrace_walls()
	_ramps()
	_bord()
	_district("haute_1")
	lieux.observatoire()
	_district("haute_5")
	lieux.mairie()
	_district("haute_6")
	lieux.bibliotheque()
	_district("moyenne_6")
	lieux.marche()
	_district("moyenne_2")
	lieux.taverne()
	_district("moyenne_0")
	lieux.mat()
	_district("basse_4")
	lieux.forge()
	_district("basse_7")
	lieux.lavoir()
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
		if _rng.randf() < 0.25:
			smoke_spots.append(c)
	for s in kit.steam_spots:
		steam_spots.append(s)
	print("ILE_MANGA_V112: Hautefond bâtie, %d maisons, %d lieux, %d points, %d pièces répétées, %d réverbères, en %d ms (maisons %d ms)" % [houses.size(), spots.size(), points.size(), kit.inst_count, kit.lamps70.size(), Time.get_ticks_msec() - t0, t2 - t1])


# =================================================================== murs de soutènement, rampes

func _ramp_top_near(deg: float, r_drop: float, margin: float) -> bool:
	for k in R.RAMPS:
		var rp: Array = R.RAMPS[k]
		if absf(float(rp[0]) - r_drop) > 0.5:
			continue
		if absf(R._adiff(deg, float(rp[3]))) * PI / 180.0 * r_drop < margin:
			return true
	return false


## Les murs de soutènement des trois terrasses : de la pierre blonde, une balustrade claire.
func _terrace_walls() -> void:
	for spec in [[R.CORE_R, CY, HY, 72], [R.HAUTE_R, HY, MY, 144], [R.MOY_R, MY, BY, 192]]:
		var rd: float = float(spec[0])
		var top: float = float(spec[1])
		var low: float = float(spec[2])
		var n: int = int(spec[3])
		var rm: float = rd - 1.65
		for k in range(n):
			var a0: float = 360.0 * k / n
			var a1: float = 360.0 * (k + 1) / n
			var am: float = (a0 + a1) * 0.5
			_district(_district_of("murs", am))
			var len: float = deg_to_rad(a1 - a0) * rd + 0.06
			var bs := Basis(Vector3.UP, -deg_to_rad(am))
			kit.box(Transform3D(bs, PW(am, rm, (top + low) * 0.5 - 0.5)), Vector3(3.5, top - low + 1.0, len), "pierre112", 3.0, 63 - 8)
			kit.col_box(Transform3D(bs, PW(am, rm, (top + low) * 0.5 - 0.5)), Vector3(3.5, top - low + 1.0, len))
			kit.box(Transform3D(bs, PW(am, rd + 0.05, top - 0.12)), Vector3(0.5, 0.24, len), "pierre112_clair", 1.4)
			# un bandeau à mi-hauteur
			kit.box(Transform3D(bs, PW(am, rd + 0.1, low + (top - low) * 0.55)), Vector3(0.24, 0.3, len), "pierre112_clair", 1.4)
			if not _ramp_top_near(am, rd, 4.5):
				kit.box(Transform3D(bs, PW(am, rd - 0.3, top + 0.45)), Vector3(0.45, 0.9, len), "pierre112_clair", 1.6)
				kit.col_box(Transform3D(bs, PW(am, rd - 0.3, top + 0.55)), Vector3(0.45, 1.1, len))
			if k % 8 == 3:
				kit.box(Transform3D(bs, PW(am, rd + 0.6, low + (top - low) * 0.4)), Vector3(1.4, (top - low) * 0.8, 1.2), "pierre112_sombre", 1.6)
			if k % 12 == 6 and spec[0] != R.CORE_R:
				kit.wall_lamp70(Transform3D(Basis(Vector3.UP, -deg_to_rad(am) + PI * 0.5), PW(am, rd + 0.15, low + 3.4)), k % 24 == 6)


func _ramps() -> void:
	for k in R.RAMPS:
		var rp: Array = R.RAMPS[k]
		var r0: float = float(rp[0])
		var w: float = float(rp[1])
		var a_lo: float = float(rp[2])
		var a_hi: float = float(rp[3])
		var y_lo: float = float(rp[4])
		var y_hi: float = float(rp[5])
		var span: float = R.ramp_span(str(k))
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
			kit.box(Transform3D(bs, PW(am, r0 + w + 0.35, y_lo - 0.5 + hh * 0.5 + 0.25)), Vector3(0.7, hh + 0.5, len), "pierre112", 2.0, 63 - 8)
			kit.col_box(Transform3D(bs, PW(am, r0 + w + 0.35, y_lo - 0.5 + (hh + 0.5) * 0.5 + 0.25)), Vector3(0.7, hh + 0.5, len))
			kit.box(Transform3D(bs, PW(am, r0 + w + 0.35, ym + 1.05)), Vector3(0.8, 0.12, len), "pierre112_clair", 1.0)
			if i % 5 == 2:
				kit.globe_lamp112(PW(am, r0 + w - 0.6, ym), 0.0, 3.8, true)
		var ae: float = a_hi + signf(span) * rad_to_deg(0.4 / (r0 + w * 0.5))
		var be := Basis(Vector3.UP, -deg_to_rad(ae) + PI * 0.5)
		kit.box(Transform3D(be, PW(ae, r0 + w * 0.5, (y_hi + y_lo) * 0.5 + 0.5)), Vector3(0.7, y_hi - y_lo + 2.0, w + 1.2), "pierre112", 2.0, 63 - 8)
		kit.col_box(Transform3D(be, PW(ae, r0 + w * 0.5, (y_hi + y_lo) * 0.5 + 0.5)), Vector3(0.7, y_hi - y_lo + 2.0, w + 1.2))
		_avoid(PW(a_lo + span * 0.5, r0 + w * 0.5, 0.0), absf(deg_to_rad(span)) * r0 * 0.5)


## Le bord de la Basse-Ville : un parapet bas sur la pente, coupé aux quatre sorties ; des bornes,
## une grande lanterne à chaque sortie.
func _bord() -> void:
	var nseg: int = 128
	for k in range(nseg):
		var a0: float = 360.0 * k / nseg
		var a1: float = 360.0 * (k + 1) / nseg
		var am: float = (a0 + a1) * 0.5
		if _near_gate(am, 10.0):
			continue
		_district(_district_of("basse", am))
		kit.parapet70(PW(a0, R.TOWN_R - 1.6, BY), PW(a1, R.TOWN_R - 1.6, BY), 0.85, 0.45, "pierre112", "pierre112_clair")
	for g in R.GATES:
		var a2: float = float(R.GATES[g])
		_district(_district_of("basse", a2))
		for s in [-1.0, 1.0]:
			var p: Vector3 = PW(a2, R.TOWN_R - 1.6, BY) + tangent(a2) * s * 5.6
			kit.box(Transform3D(Basis(Vector3.UP, -deg_to_rad(a2)), p + Vector3.UP * 1.2), Vector3(1.0, 2.4, 1.0), "pierre112_clair", 1.2)
			kit.col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(a2)), p + Vector3.UP * 1.2), Vector3(1.0, 2.4, 1.0))
			kit.globe_lamp112(p + Vector3.UP * 2.4, deg_to_rad(-a2), 1.4, s > 0.0)
		_avoid(PW(a2, R.TOWN_R, 0.0), 10.0)


static func _near_gate(deg: float, deg_margin: float) -> bool:
	for g in R.GATES:
		if absf(R._adiff(deg, float(R.GATES[g]))) < deg_margin * 0.5 + 2.0:
			return true
	return false


# =================================================================== les maisons

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
			var w: float = _rng.randf_range(7.0, 9.4) if zone == "haute" else _rng.randf_range(5.8, 8.4)
			var aw: float = rad_to_deg(w / r)
			if cur + aw > stop:
				var rem: float = deg_to_rad(stop - cur) * r
				if rem < 4.8:
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
	var opts := {"floors": floors, "lit": 0.55 if zone != "basse" else 0.45, "door_x": dx, "v81": true, "gf": 3.6, "uf": 3.1}
	if zone == "haute":
		opts["gf"] = 4.0
		opts["uf"] = 3.3
		opts["balcons"] = true
	elif zone == "basse":
		opts["gf"] = 3.4
		opts["uf"] = 2.9
	if shop_id != "":
		var spd: Array = SHOPS[shop_id]
		opts["shop"] = str(spd[2])
		opts["awning"] = str(spd[3])
		opts["door_x"] = -w * 0.25
		opts["floors"] = maxi(floors, 3)
		_shop_done[shop_id] = true
	var door: Vector3 = kit.house112(xf, w, depth, opts)
	door.y = y + 0.05
	var h := {"deg": deg, "r": r, "row": ri, "door": door, "w": w, "street": str(row[6]), "xf": xf}
	if shop_id != "":
		h["owner"] = shop_id
		h["shop"] = str(SHOPS[shop_id][2])
		doors["porte_" + shop_id] = _pt("porte_" + shop_id, door)
		var cx: float = w * 0.22
		kit.counter71(xf * kit.T(cx, 0, 2.2), 1.8, "planches71_clair")
		objets["comptoir_" + shop_id] = xf * Vector3(cx, 0.05, 3.3)
		var sname: String = str(SHOP_SPOTS.get(shop_id, ""))
		if sname != "":
			var node: String = _pt("pt_" + sname, xf * Vector3(cx + 1.7, y + 0.05 - xf.origin.y, 1.3))
			_spot(sname, xf * Vector3(cx, y + 0.05 - xf.origin.y, 0.95), xf.basis * Vector3(0, 0, 1), "comptoir", node)
		if shop_id == "gaspard":
			# l'établi de l'horloger, devant la vitrine : des engrenages, une horloge démontée
			var ex: Transform3D = xf * kit.T(-w * 0.32, 0, 1.6)
			kit.box(ex * kit.T(0, 0.45, 0), Vector3(1.6, 0.9, 0.7), "bois112", 1.0)
			kit.box(ex * kit.T(0, 0.92, 0), Vector3(1.7, 0.06, 0.8), "planches71_clair", 1.0)
			kit.col_box(ex * kit.T(0, 0.45, 0), Vector3(1.6, 0.9, 0.7))
			kit.gear112(ex * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(-0.3, 0.97, 0.0)), 0.2, 12, 0.03)
			kit.gear112(ex * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.15, 0.97, 0.1)), 0.13, 9, 0.03, "cuivre112")
			kit.clock112(ex * Transform3D(Basis(Vector3.RIGHT, -1.2), Vector3(0.45, 1.05, -0.1)), 0.18)
			var en: String = _pt("pt_horloger_etabli", ex * Vector3(0, y + 0.05 - ex.origin.y, 1.1))
			_spot("horloger_etabli", ex * Vector3(0, y + 0.05 - ex.origin.y, -0.75), ex.basis * Vector3(0, 0, 1), "bricoler", en)
	houses.append(h)
	_avoid(xf * Vector3(0, 0, -depth * 0.5), maxf(w, depth) * 0.6)


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
	# Pimprenelle habite avec sa mère, à la forge
	if doors.has("porte_mathilde"):
		doors["porte_pimprenelle"] = _pt("porte_pimprenelle", points["porte_mathilde"])


# =================================================================== les rues

func _streets() -> void:
	# la rue de la Haute-Ville : des réverbères à globes
	for k in range(32):
		var a: float = 360.0 * (k + 0.5) / 32.0
		if reserved(a, 49.0) != "":
			continue
		_district(_district_of("haute", a))
		var rr: float = 45.6 if R.ramp_at(PW(a, 45.6, 0).x - R.CENTER.x, PW(a, 45.6, 0).z - R.CENTER.z) == "" else 49.8
		kit.globe_lamp112(PW(a, rr, HY), deg_to_rad(-a), 4.0, k % 2 == 0)
	# la promenade (le bord de la Haute-Ville) : des arbres, des bancs face à la mer
	for k2 in range(40):
		var a2: float = 360.0 * (k2 + 0.5) / 40.0
		var rz: String = reserved(a2, 70.0)
		if rz != "":
			continue
		if R.ramp_at(PW(a2, 75.0, 0).x - R.CENTER.x, PW(a2, 75.0, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("haute", a2))
		if k2 % 3 == 0:
			tree_spots.append(PW(a2, 66.0, HY))
		elif k2 % 3 == 1:
			var bxh: Transform3D = PX(a2, 75.6, HY, "out") * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
			kit.bench112(bxh)
			crowd_spots.append("banc_haute_%d" % k2)
			_spot("banc_haute_%d" % k2, bxh * Vector3(0, 0.45, 0.15), bxh.basis * Vector3(0, 0, 1), "assis", "")
		else:
			kit.globe_lamp112(PW(a2, 76.4, HY), deg_to_rad(-a2), 4.0, true)
	# la Ville-Moyenne : des réverbères au bord du mur, et le long de la rue du haut
	for k3 in range(48):
		var a3: float = 360.0 * (k3 + 0.5) / 48.0
		if reserved(a3, 113.0) != "" or _ramp_top_near(a3, R.MOY_R, 6.0):
			continue
		_district(_district_of("moyenne", a3))
		kit.globe_lamp112(PW(a3, 121.6, MY), deg_to_rad(-a3), 4.0, k3 % 2 == 0)
		if k3 % 4 == 1:
			var bxm: Transform3D = PX(a3 + 1.5, 121.4, MY, "in")
			kit.bench112(bxm)
			crowd_spots.append("banc_moy_%d" % k3)
			_spot("banc_moy_%d" % k3, bxm * Vector3(0, 0.45, 0.15), bxm.basis * Vector3(0, 0, 1), "assis", "")
	for k4 in range(40):
		var a4: float = 360.0 * (k4 + 0.5) / 40.0
		if reserved(a4, 89.0) != "" or R.ramp_at(PW(a4, 84.0, 0).x - R.CENTER.x, PW(a4, 84.0, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("moyenne", a4))
		kit.globe_lamp112(PW(a4, 86.8, MY), deg_to_rad(-a4), 4.0, k4 % 2 == 0)
	# la Basse-Ville : des réverbères le long des deux rues, des tonneaux, des caisses
	for k5 in range(56):
		var a5: float = 360.0 * (k5 + 0.5) / 56.0
		var rr5: float = 135.5 + (2.4 if k5 % 2 == 0 else -2.2)
		if reserved(a5, rr5) != "" or R.ramp_at(PW(a5, rr5, 0).x - R.CENTER.x, PW(a5, rr5, 0).z - R.CENTER.z) != "":
			continue
		_district(_district_of("basse", a5))
		kit.globe_lamp112(PW(a5, rr5, BY), deg_to_rad(-a5), 4.0, k5 % 2 == 0)
	for k6 in range(48):
		var a6: float = 360.0 * (k6 + 0.5) / 48.0
		if _near_gate(a6, 10.0) or reserved(a6, 166.0) != "":
			continue
		_district(_district_of("basse", a6))
		if k6 % 6 == 3:
			kit.barrel71(PW(a6, 168.2, BY))
		elif k6 % 6 == 0:
			kit.crate71(PW(a6 + 0.8, 168.0, BY), deg_to_rad(a6))
		elif k6 % 3 == 1:
			tree_spots.append(PW(a6, 168.6, BY))


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


func ramp_point(key: String, t: float) -> Vector3:
	var rp: Array = R.RAMPS[key]
	var a: float = float(rp[2]) + R.ramp_span(key) * t
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
	# les ruelles : de la rue du haut à celle du bas, à travers les rangées
	for pair in [["hi", "ho", 16], ["mi", "mo", 24], ["bi", "bo", 32]]:
		for k3 in range(int(pair[2])):
			var a3: float = ring_angle(str(pair[0]), k3)
			var rm: float = (float(RINGS[str(pair[0])][0]) + float(RINGS[str(pair[1])][0])) * 0.5
			if reserved(a3, rm) == "" and reserved(a3, float(RINGS[str(pair[0])][0]) + 4.0) == "":
				_link(ring_node(str(pair[0]), k3), ring_node(str(pair[1]), k3))
	# les rampes : du bas (la rue du bas) au haut (la rue de la terrasse d'en haut)
	var ends := {"r1": ["bi", "mo"], "r1b": ["bi", "mo"], "r2": ["mi", "ho"], "r2b": ["mi", "ho"], "r3": ["hi", ""], "r3b": ["hi", ""]}
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
			lieux.core_link(str(names[4]), float(rp[3]))
	# les sorties de la ville : de la rue du bord au dehors
	for g in R.GATES:
		var a5: float = float(R.GATES[g])
		var gp: String = _pt("sortie_" + str(g), PW(a5, R.TOWN_R - 1.0, BY + 0.05))
		var out: String = _pt("dehors_" + str(g), PG(a5, R.TOWN_R + 16.0, 0.05))
		var inner: String = _pt("avenue_" + str(g), PW(a5, 150.0, BY + 0.05))
		_chain([nearest_ring("bi", a5), inner, nearest_ring("bo", a5), gp, out])
		_link(inner, nearest_ring("bo", a5))
	lieux.link_graph()
	for sid in SHOP_SPOTS:
		var nm: String = "pt_" + str(SHOP_SPOTS[sid])
		if points.has(nm):
			_link(nm, _nearest_ring_point(points[nm]))
	if points.has("pt_horloger_etabli"):
		_link("pt_horloger_etabli", _nearest_ring_point(points["pt_horloger_etabli"]))
	_street_spots()
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
		if (graph.get(doors[d], []) as Array).is_empty():
			_link(str(doors[d]), best)


## Les lieux des rues : des coins où l'on bavarde.
func _street_spots() -> void:
	var rues := [["rue_1", "bi", -70.0, 2.4, "debout"], ["rue_2", "bo", -10.0, -2.2, "bras_croises"], ["rue_3", "mi", -130.0, -2.0, "debout"],
		["rue_4", "mo", 60.0, 2.2, "observer"], ["rue_5", "bi", 120.0, -2.4, "debout"], ["rue_6", "hi", -110.0, 2.0, "observer"]]
	for rr in rues:
		var node: String = nearest_ring(str(rr[1]), float(rr[2]))
		var p: Vector3 = points[node]
		var cp: Vector2 = R.town_polar(R.L(p.x, p.z).x, R.L(p.x, p.z).y)
		var off: Vector3 = radial(cp.x) * float(rr[3])
		_spot(str(rr[0]), p + off, -off if str(rr[4]) != "observer" else off, str(rr[4]), node)
	# la promenade de la Haute-Ville : deux bancs face à la mer
	for e in [["haute_banc_1", -20.0], ["haute_banc_2", 170.0]]:
		var a: float = float(e[1])
		var bp: Vector3 = PW(a, 74.4, HY + 0.05)
		_spot(str(e[0]), bp, radial(a), "assis", _nearest_ring_point(bp))


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
	if colonne != null and colonne.walkable(p):
		return true
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
	if colonne != null:
		if cp.y < 16.0 and p.y > colonne.top.y - 3.0:
			return "hf_belvedere"
		if colonne.inside(p) and p.y > CY + 3.0:
			return "hf_cabine"
	var lz: String = lieux.zone_at(p) if lieux != null else ""
	if lz != "":
		return lz
	if cp.y > R.TOWN_R + 3.0:
		return ""
	if cp.y < R.CORE_R and p.y > CY - 5.0:
		return "hf_colonne"
	if cp.y < R.HAUTE_R and p.y > HY - 5.0:
		return "hf_haute"
	if cp.y < R.MOY_R and p.y > MY - 5.0:
		return "hf_marche" if reserved(cp.x, cp.y) == "marche" else "hf_moyenne"
	return "hf_basse"

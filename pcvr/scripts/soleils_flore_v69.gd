extends "res://scripts/pirate_flore_v68.gd"
## V69 : la végétation de l'Île des Trois Soleils (mêmes outils que les autres îles : maillages
## fabriqués ici ou empruntés aux îles précédentes, instanciés par espèce dans des MultiMesh).
##  - l'Iterou : des papyrus serrés sur les berges, des palmiers-dattiers, des sycomores dans le
##    village ; les champs de blé de la rive sud ; des lotus dans les eaux calmes ;
##  - la jungle maya du nord : grands arbres de canopée, fromagers géants (les ceibas sacrés),
##    palmiers, bananiers, fougères arborescentes, sous-bois ;
##  - les prairies du centre et du sud-est : herbe grasse, fleurs, bosquets ;
##  - le Lac de la Lune : roseaux, lotus, et sur les chinampas du maïs, des œillets d'Inde
##    (cempasúchil), des saules (ahuejotes) ; des agaves (maguey) et des nopals sur les collines ;
##  - le Mont Fumant : pins sur les flancs, bruyère, blocs de lave ; le sommet nu ;
##  - les grèves : cocotiers penchés vers le large, herbe des dunes.

const R69 = preload("res://scripts/ile_soleils_v69.gd")
const AzurFlore = preload("res://scripts/azur_flore_v56.gd")

var _ile69: Node3D
var _azf: Node3D
var _blocked: Dictionary = {}          # cellules de 2 m (repère île) où rien ne pousse : chemins


# =================================================================== maillages

## Un bouquet de papyrus : de hautes tiges vertes, coiffées chacune d'une ombelle en éventail.
func papyrus_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6940 + variant
	var stems := _st()
	var heads := _st()
	for i in range(rng.randi_range(9, 14)):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.0, 0.45)
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var h: float = rng.randf_range(1.8, 3.2)
		var lean := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.1, 0.45)
		var top: Vector3 = base + lean + Vector3.UP * h
		Flora._tube(stems, [base, base + lean * 0.4 + Vector3.UP * h * 0.5, top] as Array[Vector3], [0.025, 0.02, 0.012] as Array[float], [0.0, 0.3, 0.8] as Array[float], 4)
		# l'ombelle : des rayons fins qui s'ouvrent comme un feu d'artifice
		for k in range(14):
			var b: float = TAU * k / 14.0 + rng.randf_range(-0.1, 0.1)
			var dir := Vector3(cos(b), rng.randf_range(0.25, 0.7), sin(b)).normalized()
			var tip: Vector3 = top + dir * rng.randf_range(0.28, 0.42)
			var side := Vector3(-sin(b), 0, cos(b)) * 0.012
			for v in [[top - side, 0.0], [top + side, 0.0], [tip, 1.0]]:
				Flora._vertex(heads, v[0], Vector3.UP, Vector2(0.5, 1.0 - float(v[1])), 0.9, 1.0)
	return _finish([[stems, _plain("papyrus_tige", Color(0.25, 0.42, 0.12), Color(0.45, 0.6, 0.22), 0.08)], [heads, _plain("papyrus_tete", Color(0.32, 0.5, 0.16), Color(0.62, 0.72, 0.3), 0.12)]])


## Des feuilles de lotus posées sur l'eau, deux ou trois fleurs roses (ou bleues).
func lotus_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6945 + variant
	var pads := _st()
	var flowers := _st()
	for i in range(rng.randi_range(4, 7)):
		var a: float = rng.randf() * TAU
		var c := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.2, 1.3)
		var r: float = rng.randf_range(0.22, 0.4)
		var n: int = 10
		var notch: float = rng.randf() * TAU
		for k in range(n):
			var a0: float = notch + 0.3 + (TAU - 0.4) * k / n
			var a1: float = notch + 0.3 + (TAU - 0.4) * (k + 1) / n
			for v in [c, c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r]:
				Flora._vertex(pads, v + Vector3.UP * 0.02, Vector3.UP, Vector2((v - c).x / r * 0.5 + 0.5, (v - c).z / r * 0.5 + 0.5), 0.0, 0.5)
	for f in range(rng.randi_range(1, 3)):
		var a2: float = rng.randf() * TAU
		var fc := Vector3(cos(a2), 0, sin(a2)) * rng.randf_range(0.2, 1.0) + Vector3.UP * rng.randf_range(0.12, 0.4)
		for k2 in range(8):
			var b: float = TAU * k2 / 8.0
			var tip: Vector3 = fc + Vector3(cos(b) * 0.12, 0.16, sin(b) * 0.12)
			var side := Vector3(-sin(b), 0, cos(b)) * 0.045
			for v2 in [[fc - side, 0.0], [fc + side, 0.0], [tip, 1.0]]:
				Flora._vertex(flowers, v2[0], (Vector3(cos(b), 0.6, sin(b))).normalized(), Vector2(0.5, 1.0 - float(v2[1])), 0.0, 1.0)
	var pink: bool = variant % 2 == 0
	return _finish([[pads, _plain("lotus_feuille", Color(0.12, 0.3, 0.12), Color(0.24, 0.45, 0.18), 0.0)],
		[flowers, _plain("lotus_fleur" if pink else "lotus_bleu", Color(0.95, 0.7, 0.78) if pink else Color(0.55, 0.62, 0.95), Color(1.0, 0.88, 0.92) if pink else Color(0.8, 0.86, 1.0), 0.0)]])


## Un pied de maïs : la tige, de longues feuilles qui retombent, l'épi, la panicule.
func maize_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6950 + variant
	var stalk := _st()
	var leaves := _st()
	var ears := _st()
	for p in range(3):
		var base := Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
		var h: float = rng.randf_range(1.7, 2.4)
		Flora._tube(stalk, [base, base + Vector3.UP * h * 0.5, base + Vector3.UP * h] as Array[Vector3], [0.03, 0.025, 0.012] as Array[float], [0.0, 0.2, 0.6] as Array[float], 5)
		for k in range(8):
			var y: float = h * (0.15 + k * 0.09)
			var a: float = rng.randf() * TAU
			var out := Vector3(cos(a), 0, sin(a))
			var side := Vector3(-sin(a), 0, cos(a)) * 0.05
			var p0: Vector3 = base + Vector3.UP * y
			var p1: Vector3 = p0 + out * 0.35 + Vector3.UP * 0.25
			var p2: Vector3 = p0 + out * 0.75 + Vector3.DOWN * 0.15
			for tri in [[p0 - side, p0 + side, p1 + side], [p0 - side, p1 + side, p1 - side], [p1 - side, p1 + side, p2]]:
				for v in tri:
					Flora._vertex(leaves, v, Vector3.UP, Vector2(0.5, 0.5), 0.5, 0.8)
		var ear: Vector3 = base + Vector3.UP * h * 0.55
		Flora._tube(ears, [ear, ear + Vector3(0.06, 0.12, 0.0), ear + Vector3(0.1, 0.26, 0.0)] as Array[Vector3], [0.04, 0.045, 0.02] as Array[float], [0.0, 0.0, 0.0] as Array[float], 6)
	return _finish([[stalk, _plain("mais_tige", Color(0.35, 0.45, 0.16), Color(0.55, 0.6, 0.25), 0.05)], [leaves, _plain("mais_feuille", Color(0.25, 0.42, 0.12), Color(0.5, 0.62, 0.22), 0.14)],
		[ears, _plain("mais_epi", Color(0.75, 0.62, 0.28), Color(0.95, 0.85, 0.5), 0.0)]])


## Une touffe de blé mûr (les champs de la rive sud).
func wheat_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(28, 0.95, 0.03, 6955).duplicate()
	m.surface_set_material(0, _plain("ble", Color(0.55, 0.48, 0.2), Color(0.95, 0.82, 0.45), 0.2))
	return m


## Une touffe d'herbe grasse (les prairies).
func lush_grass_mesh() -> Mesh:
	var m: ArrayMesh = Flora.grass_clump(16, 0.6, 0.05, 6956).duplicate()
	m.surface_set_material(0, _plain("herbe_grasse", Color(0.12, 0.28, 0.06), Color(0.45, 0.66, 0.2), 0.14))
	return m


## Des fleurs : œillets d'Inde orangés (cempasúchil), ou fleurs des prés.
func flowers_mesh(kind: String) -> Mesh:
	var m: ArrayMesh = Flora.flower_clump().duplicate()
	var c: Color = {"cempasuchil": Color(1.0, 0.52, 0.06), "pre": Color(0.95, 0.85, 0.35), "rose": Color(0.95, 0.45, 0.6)}.get(kind, Color(1, 1, 1))
	m.surface_set_material(0, Flora.flower_material(c))
	return m


## Un nopal (figuier de Barbarie) : des raquettes ovales empilées, quelques fruits rouges.
func nopal_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6960 + variant
	var pads := _st()
	var fruits := _st()
	var frontier: Array = [[Vector3.ZERO, 0.0, 0]]
	var count: int = 0
	while not frontier.is_empty() and count < 16:
		var f: Array = frontier.pop_front()
		var base: Vector3 = f[0]
		var yaw: float = float(f[1])
		var depth: int = int(f[2])
		var tilt: float = rng.randf_range(-0.5, 0.5)
		var up := Vector3(sin(tilt) * cos(yaw), cos(tilt), sin(tilt) * sin(yaw)).normalized()
		var side := Vector3(-sin(yaw + PI * 0.5), 0, cos(yaw + PI * 0.5))
		var h: float = rng.randf_range(0.32, 0.45)
		var w: float = h * 0.62
		var c: Vector3 = base + up * h * 0.5
		var n: int = 10
		var nrm: Vector3 = side.cross(up).normalized()
		for k in range(n):
			var a0: float = TAU * k / n
			var a1: float = TAU * (k + 1) / n
			var p0: Vector3 = c + side * cos(a0) * w * 0.5 + up * sin(a0) * h * 0.5
			var p1: Vector3 = c + side * cos(a1) * w * 0.5 + up * sin(a1) * h * 0.5
			for v in [c + nrm * 0.03, p0, p1, c - nrm * 0.03, p1, p0]:
				Flora._vertex(pads, v, nrm if (v - c).dot(nrm) >= 0.0 else -nrm, Vector2(0.5, 0.5), 0.0, 0.5)
		count += 1
		if depth < 3:
			for b in range(rng.randi_range(1, 2)):
				frontier.append([c + up * h * 0.45 + side * rng.randf_range(-0.1, 0.1), yaw + rng.randf_range(-1.2, 1.2), depth + 1])
		elif rng.randf() < 0.6:
			var top: Vector3 = c + up * h * 0.5
			Flora._tube(fruits, [top, top + Vector3.UP * 0.07] as Array[Vector3], [0.035, 0.03] as Array[float], [0.0, 0.0] as Array[float], 6)
	return _finish([[pads, _plain("nopal", Color(0.24, 0.42, 0.22), Color(0.4, 0.56, 0.3), 0.0)], [fruits, _plain("tuna", Color(0.7, 0.12, 0.2), Color(0.85, 0.3, 0.3), 0.0)]])


# =================================================================== où planter

func _cell(l: Vector2) -> Vector2i:
	return Vector2i(int(floor(l.x / 2.0)), int(floor(l.y / 2.0)))


func _block_paths() -> void:
	for k in _ile69.paths_world:
		for p in _ile69.paths_world[k]:
			var l: Vector2 = R69.L((p as Vector3).x, (p as Vector3).z)
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					_blocked[_cell(l + Vector2(dx, dz) * 1.2)] = true


## Un point au hasard sur l'île (repère monde) qui convient : hauteur, pente, hors des lieux
## bâtis, des chemins, des dallages, du désert, de l'eau du lac. want : "", "jungle", "berge",
## "champs", "lac", "volcan", "greve", "prairie".
func _s_point(want: String, min_h: float, max_slope: float, max_h: float = 200.0) -> Vector3:
	for attempt in range(30):
		var l: Vector2
		match want:
			"jungle":
				l = Vector2(_rng.randf_range(-300.0, 300.0), _rng.randf_range(-300.0, -50.0))
			"champs":
				l = Vector2(_rng.randf_range(R69.FIELDS.position.x, R69.FIELDS.end.x), _rng.randf_range(R69.FIELDS.position.y, R69.FIELDS.end.y))
			"berge":
				var i: int = _rng.randi() % (R69.RIVER.size() - 1)
				var t: float = _rng.randf()
				var c: Vector2 = (R69.RIVER[i] as Vector2).lerp(R69.RIVER[i + 1], t)
				var w: float = lerpf(float(R69.RIVER_W[i]), float(R69.RIVER_W[i + 1]), t)
				l = c + Vector2(0, 1 if _rng.randf() < 0.5 else -1) * (w + _rng.randf_range(-1.5, 5.0)) + Vector2(_rng.randf_range(-3.0, 3.0), 0)
			"lac":
				var a: float = _rng.randf() * TAU
				var q: float = _rng.randf_range(0.6, 1.12)
				l = R69.LAKE + Vector2(cos(a) * R69.LAKE_AX.x, sin(a) * R69.LAKE_AX.y) * q
			"volcan":
				var a2: float = _rng.randf() * TAU
				l = R69.VOLCANO + Vector2(cos(a2), sin(a2)) * sqrt(_rng.randf()) * 120.0
			_:
				l = Vector2(_rng.randf_range(-310.0, 310.0), _rng.randf_range(-300.0, 300.0))
		if absf(l.x) > R69.HALF - 2.0 or absf(l.y) > R69.HALF - 2.0:
			continue
		if _blocked.has(_cell(l)):
			continue
		if R69._rect_dist(l.x, l.y, R69.TOWN_E) < 3.0:
			continue
		var w3: Vector3 = R69.W(l.x, l.y)
		w3.y = _ile69.height(w3.x, w3.z)
		var b: Color = _ile69.biome_at(w3.x, w3.z)
		if b.a > 0.25:
			continue
		if want != "lac" and _ile69.in_lake_water(w3.x, w3.z):
			continue
		if l.distance_to(R69.CENOTE) < R69.CENOTE_R + 3.0:
			continue
		if _ok_spot(w3, max_slope, min_h, max_h):
			return w3
	return Vector3.INF


func _desert(w: Vector3) -> bool:
	return _ile69.biome_at(w.x, w.z).r > 0.45


func _jungly(w: Vector3) -> bool:
	return _ile69.biome_at(w.x, w.z).g > 0.4


func _xfr(p: Vector3, smin: float, smax: float, sink: float = 0.05) -> Transform3D:
	return _xf(p, _rng.randf_range(smin, smax), sink)


func build_soleils(island: Node3D, high_quality: bool, extra: Dictionary) -> void:
	_ile69 = island
	ile = island
	_rng.seed = 6900
	var t0: int = Time.get_ticks_msec()
	var q: float = 1.0 if high_quality else 0.55
	_azf = AzurFlore.new()
	_block_paths()
	_trunk_body = StaticBody3D.new()
	_trunk_body.name = "Troncs_soleils_v69"
	_trunk_body.collision_layer = 1
	_trunk_body.collision_mask = 0
	add_child(_trunk_body)
	var L := {"canopee": [[], [], []], "geant": [[], []], "palmier": [[], [], []], "bananier": [[], []], "fougere_arbre": [[], []],
		"arbuste": [[]], "fougere": [[]], "oreille": [[]], "herbe": [[]], "herbe_grasse": [[]], "papyrus": [[], []], "lotus": [[], []],
		"ble": [[]], "mais": [[], []], "fleurs": [[]], "cempasuchil": [[]], "roseau": [[]], "saule": [[], []], "pin": [[], []],
		"agave": [[], []], "nopal": [[], []], "bruyere": [[]], "herbe_dune": [[]], "sycomore": [[]], "olivier": [[]]}
	var rocks := {"lave": [], "mousse": []}
	# ---------------------------------------------------------------- les grèves
	for i in range(int(380 * q)):
		var p: Vector3 = _s_point("", 0.0, 0.35, 4.2)
		if p == Vector3.INF:
			continue
		var l: Vector2 = R69.L(p.x, p.z)
		if island.coast_q(l.x, l.y) < 0.82 or _desert(p):
			continue
		var out: float = atan2(l.y, l.x)
		L["palmier"][i % 3].append(Transform3D(Basis(Vector3.UP, -out + _rng.randf_range(-0.6, 0.6)).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.15)), p - Vector3.UP * 0.1))
		_trunk(p, 0.25, 3.0)
	for i2 in range(int(800 * q)):
		var pg: Vector3 = _s_point("", 0.1, 0.4, 2.4)
		if pg != Vector3.INF and island.coast_q(R69.L(pg.x, pg.z).x, R69.L(pg.x, pg.z).y) > 0.8:
			L["herbe_dune"][0].append(_xfr(pg, 0.8, 1.4, 0.02))
	# ---------------------------------------------------------------- l'Iterou et les champs
	for i3 in range(int(1300 * q)):
		var pb: Vector3 = _s_point("berge", -0.45, 0.6, 1.6)
		if pb != Vector3.INF:
			L["papyrus"][i3 % 2].append(_xfr(pb, 0.8, 1.25, 0.15))
	for i4 in range(int(240 * q)):
		var pp: Vector3 = _s_point("berge", 0.3, 0.4, 4.0)
		if pp != Vector3.INF and not _desert(pp):
			L["palmier"][i4 % 3].append(_xfr(pp, 0.75, 1.05, 0.1))
			_trunk(pp, 0.25, 3.0)
	for i5 in range(int(3800 * q)):
		var pf: Vector3 = _s_point("champs", 0.2, 0.3, 3.0)
		if pf != Vector3.INF and Vector2(pf.x, pf.z).distance_to(Vector2(R69.W(R69.VALLEY.x, 0).x, R69.W(0, R69.VALLEY.y).z)) > 13.0:
			L["ble"][0].append(_xfr(pf, 0.85, 1.2, 0.02))
	for i6 in range(int(160 * q)):
		var pl: Vector3 = _s_point("berge", -0.6, 0.6, -0.1)
		if pl != Vector3.INF and pl.y < R69.WATER - 0.2:
			L["lotus"][i6 % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(pl.x, R69.WATER, pl.z)))
	for tp in extra.get("palmiers", []):
		L["palmier"][0].append(_xf(tp, _rng.randf_range(0.85, 1.05), 0.1))
		_trunk(tp, 0.25, 3.0)
	for sp in extra.get("sycomores", []):
		L["sycomore"][0].append(_xf(sp, _rng.randf_range(0.8, 1.0), 0.1))
		_trunk(sp, 0.4, 3.5)
	# ---------------------------------------------------------------- la jungle du nord
	for i7 in range(int(1000 * q)):
		var pj: Vector3 = _s_point("jungle", 2.0, 0.62, 60.0)
		if pj == Vector3.INF or not _jungly(pj):
			continue
		L["canopee"][i7 % 3].append(_xfr(pj, 0.75, 1.2, 0.15))
		_trunk(pj, 0.45, 4.0)
	for i8 in range(int(48 * q)):
		var pg2: Vector3 = _s_point("jungle", 4.0, 0.4, 50.0)
		if pg2 != Vector3.INF and _jungly(pg2):
			L["geant"][i8 % 2].append(_xfr(pg2, 0.8, 1.0, 0.2))
			_trunk(pg2, 1.4, 6.0)
	for i9 in range(int(200 * q)):
		var ppa: Vector3 = _s_point("jungle", 2.0, 0.55, 40.0)
		if ppa != Vector3.INF and _jungly(ppa):
			L["palmier"][i9 % 3].append(_xfr(ppa, 0.7, 1.0, 0.1))
	for i10 in range(int(600 * q)):
		var pba: Vector3 = _s_point("jungle", 1.6, 0.7, 45.0)
		if pba != Vector3.INF and _jungly(pba):
			L["bananier"][i10 % 2].append(_xfr(pba, 0.8, 1.2, 0.05))
	for i11 in range(int(280 * q)):
		var pfa: Vector3 = _s_point("jungle", 2.0, 0.8, 60.0)
		if pfa != Vector3.INF and _jungly(pfa):
			L["fougere_arbre"][i11 % 2].append(_xfr(pfa, 0.8, 1.3, 0.05))
	for i12 in range(int(2400 * q)):
		var pfo: Vector3 = _s_point("jungle", 1.2, 0.9)
		if pfo != Vector3.INF and _jungly(pfo):
			L["fougere"][0].append(_xfr(pfo, 0.8, 1.5, 0.03))
	for i13 in range(int(1300 * q)):
		var po: Vector3 = _s_point("jungle", 1.2, 0.8)
		if po != Vector3.INF and _jungly(po):
			L["oreille"][0].append(_xfr(po, 0.8, 1.6, 0.03))
	for i14 in range(int(3600 * q)):
		var ph: Vector3 = _s_point("jungle", 1.6, 0.9)
		if ph != Vector3.INF and _jungly(ph):
			L["herbe"][0].append(_xfr(ph, 0.8, 1.4, 0.02))
	# ---------------------------------------------------------------- les prairies, les bosquets
	for i15 in range(int(900 * q)):
		var pa: Vector3 = _s_point("", 1.4, 0.8, 70.0)
		if pa != Vector3.INF and not _desert(pa) and not _jungly(pa):
			L["arbuste"][0].append(_xfr(pa, 0.8, 1.5, 0.1))
	for i16 in range(int(320 * q)):
		var pc: Vector3 = _s_point("", 2.0, 0.55, 60.0)
		if pc != Vector3.INF and not _desert(pc) and not _jungly(pc) and R69.L(pc.x, pc.z).distance_to(R69.VOLCANO) > 90.0:
			L["canopee"][i16 % 3].append(_xfr(pc, 0.6, 0.95, 0.15))
			_trunk(pc, 0.4, 4.0)
	for i17 in range(int(5200 * q)):
		var pm: Vector3 = _s_point("", 1.0, 0.8, 75.0)
		if pm != Vector3.INF and not _desert(pm) and not _jungly(pm):
			L["herbe_grasse"][0].append(_xfr(pm, 0.8, 1.4, 0.02))
	for i18 in range(int(1300 * q)):
		var pfl: Vector3 = _s_point("", 1.0, 0.6, 50.0)
		if pfl != Vector3.INF and not _desert(pfl) and not _jungly(pfl):
			L["fleurs"][0].append(_xfr(pfl, 0.7, 1.2, 0.02))
	# ---------------------------------------------------------------- le Lac de la Lune et les chinampas
	for i19 in range(int(900 * q)):
		var pr: Vector3 = _s_point("lac", R69.LAKE_Y - 0.6, 0.6, R69.LAKE_Y + 0.9)
		if pr == Vector3.INF:
			continue
		var lr: Vector2 = R69.L(pr.x, pr.z)
		if R69.chinampa(lr.x, lr.y) >= 0.0 or R69.lake_q(lr.x, lr.y) < 0.95:
			continue
		L["roseau"][0].append(_xfr(pr, 0.8, 1.5, 0.05))
	for i20 in range(int(180 * q)):
		var plo: Vector3 = _s_point("lac", R69.LAKE_Y - 3.0, 2.0, R69.LAKE_Y - 0.25)
		if plo != Vector3.INF:
			var ll: Vector2 = R69.L(plo.x, plo.z)
			if R69.lake_q(ll.x, ll.y) > 0.82 and R69.chinampa(ll.x, ll.y) < 0.0:
				L["lotus"][i20 % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(plo.x, R69.LAKE_Y + 0.01, plo.z)))
	for i21 in range(int(2600 * q)):
		var pch: Vector3 = _s_point("lac", R69.LAKE_Y + 0.3, 0.4, R69.LAKE_Y + 0.6)
		if pch == Vector3.INF:
			continue
		var lc: Vector2 = R69.L(pch.x, pch.z)
		if R69.chinampa(lc.x, lc.y) < 0.5:
			continue
		if i21 % 5 == 0:
			L["cempasuchil"][0].append(_xfr(pch, 0.8, 1.2, 0.02))
		else:
			L["mais"][i21 % 2].append(_xfr(pch, 0.85, 1.15, 0.03))
	for wp in extra.get("saules", []):
		L["saule"][int((wp as Vector3).x) % 2].append(_xf(wp, _rng.randf_range(0.8, 1.1), 0.1))
		_trunk(wp, 0.3, 3.0)
	for i22 in range(int(200 * q)):
		var pag: Vector3 = _s_point("", R69.LAKE_Y + 0.8, 0.5, 40.0)
		if pag == Vector3.INF:
			continue
		var lag: Vector2 = R69.L(pag.x, pag.z)
		if R69.lake_q(lag.x, lag.y) > 2.0 or _jungly(pag):
			continue
		if i22 % 3 == 0:
			L["nopal"][i22 % 2].append(_xfr(pag, 0.9, 1.4, 0.05))
		else:
			L["agave"][i22 % 2].append(_xfr(pag, 0.9, 1.5, 0.05))
	# ---------------------------------------------------------------- le Mont Fumant
	for i23 in range(int(300 * q)):
		var pv: Vector3 = _s_point("volcan", 8.0, 0.75, 62.0)
		if pv != Vector3.INF and not _jungly(pv):
			L["pin"][i23 % 2].append(_xfr(pv, 0.75, 1.15, 0.15))
			_trunk(pv, 0.3, 3.5)
	for i24 in range(int(900 * q)):
		var pbr: Vector3 = _s_point("volcan", 10.0, 0.9, 75.0)
		if pbr != Vector3.INF:
			L["bruyere"][0].append(_xfr(pbr, 0.8, 1.4, 0.02))
	for i25 in range(int(160 * q)):
		var plv: Vector3 = _s_point("volcan", 6.0, 2.0)
		if plv != Vector3.INF:
			rocks["lave"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.6, 2.6)), plv - Vector3.UP * 0.4))
	for i26 in range(int(70 * q)):
		var pmo: Vector3 = _s_point("jungle", 2.0, 1.0)
		if pmo != Vector3.INF and _jungly(pmo):
			rocks["mousse"].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.5, 1.6)), pmo - Vector3.UP * 0.35))
	# ---------------------------------------------------------------- les maillages
	for v in range(3):
		_emit("canopee_sol_%d" % v, _jungle("canopee", v), L["canopee"][v], 260.0)
		_emit("palmier_sol_%d" % v, _jungle("palmier", v), L["palmier"][v], 320.0)
	for v2 in range(2):
		_emit("geant_sol_%d" % v2, _jungle("geant", v2), L["geant"][v2], 520.0)
		_emit("bananier_sol_%d" % v2, _jungle("bananier", v2), L["bananier"][v2], 110.0)
		_emit("fougere_arbre_sol_%d" % v2, _tree_fern(v2), L["fougere_arbre"][v2], 110.0)
		_emit("papyrus_%d" % v2, papyrus_mesh(v2), L["papyrus"][v2], 140.0, false)
		_emit("lotus_%d" % v2, lotus_mesh(v2), L["lotus"][v2], 90.0, false)
		_emit("mais_%d" % v2, maize_mesh(v2), L["mais"][v2], 110.0, false)
		_emit("saule_%d" % v2, _azf.cypress_mesh(v2 + 3), L["saule"][v2], 300.0)
		_emit("pin_sol_%d" % v2, _azf.pine_mesh(v2 + 3), L["pin"][v2], 340.0)
		_emit("agave_sol_%d" % v2, _azf.agave_mesh(v2 + 3), L["agave"][v2], 120.0)
		_emit("nopal_%d" % v2, nopal_mesh(v2), L["nopal"][v2], 120.0)
	_emit("sycomore", _azf.plane_mesh(2), L["sycomore"][0], 300.0)
	_emit("arbuste_sol", _jungle("arbuste", 0), L["arbuste"][0], 85.0)
	_emit("fougere_sol", _jungle("fougere", 0), L["fougere"][0], 70.0, false)
	_emit("oreille_sol", _jungle("oreille", 0), L["oreille"][0], 75.0, false)
	_emit("herbe_sol", _jungle("herbe", 0), L["herbe"][0], 60.0, false)
	_emit("herbe_grasse", lush_grass_mesh(), L["herbe_grasse"][0], 65.0, false)
	_emit("ble", wheat_mesh(), L["ble"][0], 110.0, false)
	_emit("fleurs_pre", flowers_mesh("pre"), L["fleurs"][0], 60.0, false)
	_emit("cempasuchil", flowers_mesh("cempasuchil"), L["cempasuchil"][0], 70.0, false)
	_emit("roseau_sol", Flora.reed_clump(), L["roseau"][0], 110.0, false)
	_emit("bruyere_sol", heather_mesh(), L["bruyere"][0], 70.0, false)
	_emit("herbe_dune_sol", beach_grass_mesh(), L["herbe_dune"][0], 70.0, false)
	_rock_mm("lave_sol", Color(0.22, 0.2, 0.2), 0.15, rocks["lave"], 3, Vector3(2.4, 1.6, 2.0), true)
	_rock_mm("roc_mousse_sol", Color(0.42, 0.44, 0.4), 0.9, rocks["mousse"], 2, Vector3(2.0, 1.3, 1.8), true)
	if _jf != null:
		_jf.free()
		_jf = null
	if _azf != null:
		if _azf.get("_jf") != null:
			_azf._jf.free()
		_azf.free()
		_azf = null
	print("ILE_MANGA_V69: végétation des Trois Soleils ", placed, " en ", Time.get_ticks_msec() - t0, " ms")

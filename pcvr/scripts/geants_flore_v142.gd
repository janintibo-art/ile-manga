extends Node3D
## V142 : la végétation de l'Île des Géants, à leur échelle (sept fois et demie la nôtre). Tout est
## fabriqué ici (maillages procéduraux, le shader de feuillage V25 pour le vent et la lumière qui
## traverse les feuilles) et instancié par espèce dans des MultiMesh :
##  - le potager : choux et laitues, poireaux et carottes, citrouilles (et la « Géante » de l'oncle
##    Théophile), tomates sur leurs tuteurs et haricots grimpants ; les tournesols le long de la clôture ;
##  - le verger : des pommiers (des pommes grosses comme des ballons) ;
##  - le champ de blé : des épis plus hauts qu'une maison ;
##  - les prés : de l'herbe jusqu'aux genoux, des marguerites, des coquelicots, des pissenlits (en fleur
##    ou en boule), des trèfles ; quelques grands chênes ;
##  - la mare : des nénuphars (on peut sauter de l'un à l'autre) et des massettes.

const Ile = preload("res://scripts/ile_geants_v142.gd")
const Flora = preload("res://scripts/flora_v25.gd")
const LEAF_SHADER := "res://shaders/foliage_v25.gdshader"
const TX := "res://assets/textures/geants/"
const FL := "res://assets/textures/flora/"
const HERBE_CELL: float = 24.0

var ile: Node3D
var pc: bool = true
var avoid: Array = []                     # [Vector2 (île), rayon] : rien n'y pousse
var pommes_sol: Array = []                # Vector3 : les pommes tombées (on peut les ramasser)
var nenuphars: Array = []                 # Vector3 : le milieu des feuilles de nénuphar
var tournesols: Array = []                # Vector3 : le pied des tournesols
var counts: Dictionary = {}               # espèce -> nombre
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}
var _lists: Dictionary = {}               # espèce -> Array[Transform3D]
var _cols: StaticBody3D


func build(island: Node3D, high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	ile = island
	pc = high_quality
	_rng.seed = 14242
	_cols = StaticBody3D.new()
	_cols.name = "Flore_geants_collisions"
	_cols.collision_layer = 1
	_cols.collision_mask = 0
	add_child(_cols)
	_potager()
	_tournesols()
	_verger()
	_ble()
	_mare()
	_chenes()
	_fleurs()
	_flush()
	_herbe()
	print("ILE_MANGA_V142: la végétation des géants (%d ms) %s" % [Time.get_ticks_msec() - t0, str(counts)])


# =================================================================== matières

func _leaf(key: String, tex: String, normal: String, wind: float, transl: float, rough: float = 0.6, speed: float = 0.8) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(LEAF_SHADER)
	if ResourceLoader.exists(tex):
		m.set_shader_parameter("albedo_tex", load(tex))
	else:
		m.set_shader_parameter("use_texture", false)
	if normal != "" and ResourceLoader.exists(normal):
		m.set_shader_parameter("normal_tex", load(normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("wind_speed", speed)
	m.set_shader_parameter("translucency", transl)
	m.set_shader_parameter("roughness_value", rough)
	_mats[key] = m
	return m


func _plain(key: String, base: Color, tip: Color, wind: float, transl: float = 0.35, rough: float = 0.7, speed: float = 0.8) -> ShaderMaterial:
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load(LEAF_SHADER)
	m.set_shader_parameter("use_texture", false)
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("tip_color", tip)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("wind_speed", speed)
	m.set_shader_parameter("translucency", transl)
	m.set_shader_parameter("roughness_value", rough)
	_mats[key] = m
	return m


func _std(key: String, c: Color, rough: float, tex: String = "", normal: String = "") -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if tex != "" and ResourceLoader.exists(tex):
		m.albedo_texture = load(tex)
	if normal != "" and ResourceLoader.exists(normal):
		m.normal_enabled = true
		m.normal_texture = load(normal)
	_mats[key] = m
	return m


# =================================================================== outils de maillage

func _v(st: SurfaceTool, pos: Vector3, n: Vector3, uv: Vector2, flex: float, outer: float, col: Color = Color.WHITE) -> void:
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(uv)
	st.set_uv2(Vector2(flex, outer))
	st.add_vertex(pos)


func _new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _finish(parts: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for p in parts:
		var st: SurfaceTool = p[0]
		st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, p[1])
	return mesh


## Un tube le long d'un chemin (rayons, souplesse par point)
func _tube(st: SurfaceTool, path: Array, radii: Array, flex: Array, sides: int, col: Color = Color.WHITE, uv_k: float = 0.5) -> void:
	var rings: Array = []
	var along: float = 0.0
	for i in range(path.size()):
		var fwd: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var side: Vector3 = fwd.cross(Vector3(0.31, 0.0, 0.95))
		if side.length() < 0.1:
			side = fwd.cross(Vector3.RIGHT)
		side = side.normalized()
		var up: Vector3 = side.cross(fwd).normalized()
		if i > 0:
			along += (path[i] as Vector3).distance_to(path[i - 1])
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / sides
			var n: Vector3 = side * cos(a) + up * sin(a)
			ring.append([(path[i] as Vector3) + n * float(radii[i]), n, Vector2(float(s) / sides, along * uv_k), float(flex[i])])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a0: Array = rings[i][s]
			var b0: Array = rings[i][s + 1]
			var c0: Array = rings[i + 1][s]
			var d0: Array = rings[i + 1][s + 1]
			for q in [a0, b0, c0, b0, d0, c0]:
				_v(st, q[0], q[1], q[2], q[3], 0.7, col)


## Une feuille longue (bande courbée, pliée en V) ; dir : direction horizontale
func _blade(st: SurfaceTool, base: Vector3, dir: Vector3, length: float, width: float, rise: float, droop: float, fold: float, segs: int, flex0: float = 0.1, col: Color = Color.WHITE, ruffle: float = 0.0) -> void:
	dir = Vector3(dir.x, 0, dir.z).normalized()
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	var rows: Array = []
	for k in range(segs + 1):
		var s: float = float(k) / segs
		var center: Vector3 = base + dir * length * s * (1.0 - 0.15 * s) + Vector3.UP * length * (rise * s - droop * s * s)
		var w: float = width * 0.5 * pow(sin(PI * clampf(s * 1.02 + 0.04, 0.0, 1.0)), 0.6)
		var nrm: Vector3 = Vector3.UP
		if k > 0:
			nrm = side.cross(center - (rows[k - 1][1] as Vector3)).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
		var mid: Vector3 = center + nrm * fold * w
		var wob: float = sin(s * 23.0) * ruffle * w
		rows.append([center - side * w + nrm * wob, mid, center + side * w - nrm * wob, nrm, s])
	for k in range(segs):
		var r0: Array = rows[k]
		var r1: Array = rows[k + 1]
		var v0: float = 1.0 - float(r0[4])
		var v1: float = 1.0 - float(r1[4])
		var f0: float = flex0 + (1.0 - flex0) * float(r0[4])
		var f1: float = flex0 + (1.0 - flex0) * float(r1[4])
		for tr in [[r0[0], Vector2(0, v0), f0, r0[3]], [r1[0], Vector2(0, v1), f1, r1[3]], [r0[1], Vector2(0.5, v0), f0, r0[3]],
				[r0[1], Vector2(0.5, v0), f0, r0[3]], [r1[0], Vector2(0, v1), f1, r1[3]], [r1[1], Vector2(0.5, v1), f1, r1[3]],
				[r0[1], Vector2(0.5, v0), f0, r0[3]], [r1[1], Vector2(0.5, v1), f1, r1[3]], [r0[2], Vector2(1, v0), f0, r0[3]],
				[r0[2], Vector2(1, v0), f0, r0[3]], [r1[1], Vector2(0.5, v1), f1, r1[3]], [r1[2], Vector2(1, v1), f1, r1[3]]]:
			_v(st, tr[0], tr[3], tr[1], tr[2], 0.4 + 0.6 * float(tr[2]), col)


## Une feuille en coupe (le chou, la laitue) : s le long (0 au pied), t en travers (-1..1)
func _cup_leaf(st: SurfaceTool, base: Vector3, out: Vector3, length: float, width: float, lift: float, curl: float, cup: float, ruffle: float, col: Color = Color.WHITE) -> void:
	out = Vector3(out.x, 0, out.z).normalized()
	var side: Vector3 = out.cross(Vector3.UP).normalized()
	var ns: int = 6
	var nt: int = 5
	var grid: Array = []
	for i in range(ns + 1):
		var s: float = float(i) / ns
		var center: Vector3 = base + out * length * s + Vector3.UP * length * (lift * s - curl * s * s)
		var w: float = width * 0.5 * pow(sin(PI * clampf(0.12 + 0.88 * s, 0.0, 1.0)), 0.55)
		var row: Array = []
		for j in range(nt + 1):
			var t: float = float(j) / nt * 2.0 - 1.0
			var p: Vector3 = center + side * t * w + Vector3.UP * (t * t) * cup * w
			p += Vector3.UP * sin(t * 9.0 + s * 7.0) * ruffle * w * s
			row.append(p)
		grid.append(row)
	for i2 in range(ns):
		for j2 in range(nt):
			var q := [[i2, j2], [i2, j2 + 1], [i2 + 1, j2 + 1], [i2 + 1, j2]]
			var pa: Vector3 = grid[i2][j2]
			var pb: Vector3 = grid[i2][j2 + 1]
			var pc2: Vector3 = grid[i2 + 1][j2]
			var n: Vector3 = (pb - pa).cross(pc2 - pa).normalized()
			if n.y < 0.0:
				n = -n
			for idx in [0, 1, 2, 0, 2, 3]:
				var cc: Array = q[idx]
				var s2: float = float(cc[0]) / ns
				_v(st, grid[cc[0]][cc[1]], n, Vector2(float(cc[1]) / nt, 1.0 - s2), s2 * s2 * 0.8 + 0.05, 0.4 + 0.6 * s2, col)


## Une carte (un quad texturé) : centre, axes, souplesse
func _card(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, flex: float, col: Color = Color.WHITE, outer: float = 0.8) -> void:
	var n: Vector3 = ax.cross(ay).normalized()
	if n.y < 0.0:
		n = -n
	var p := [c - ax - ay, c + ax - ay, c + ax + ay, c - ax + ay]
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in [0, 1, 2, 0, 2, 3]:
		_v(st, p[i], n, uv[i], flex, outer, col)


## Une sphère (ou un ellipsoïde)
func _ball(st: SurfaceTool, c: Vector3, r: Vector3, seg: int, flex: float, col: Color = Color.WHITE) -> void:
	var half: int = int(seg / 2.0)
	for j in range(half):
		for i in range(seg):
			var pts := []
			for tc in [[j, i], [j, i + 1], [j + 1, i + 1], [j + 1, i]]:
				var th: float = PI * float(tc[0]) / half
				var ph: float = TAU * float(tc[1]) / seg
				var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				pts.append([c + d * r, (d / r).normalized(), Vector2(float(tc[1]) / seg, float(tc[0]) / half)])
			for idx in [0, 2, 1, 0, 3, 2]:
				var e: Array = pts[idx]
				_v(st, e[0], e[1], e[2], flex, 0.9, col)


# =================================================================== les légumes

## Un chou pommé : la pomme serrée au milieu, neuf grandes feuilles bleutées qui s'ouvrent
func _m_chou(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + variant
	var st := _new_st()
	var n: int = 9
	for k in range(n):
		var a: float = TAU * k / n + rng.randf_range(-0.2, 0.2)
		var out := Vector3(cos(a), 0, sin(a))
		_cup_leaf(st, out * 0.35 + Vector3.UP * 0.25, out, rng.randf_range(1.8, 2.3), rng.randf_range(1.5, 1.9), 0.75, 0.75, 0.5, 0.06)
	# la pomme : des feuilles serrées, fermées en boule
	for k2 in range(7):
		var a2: float = TAU * k2 / 7.0 + 0.4
		var out2 := Vector3(cos(a2), 0, sin(a2))
		_cup_leaf(st, out2 * 0.2 + Vector3.UP * 0.2, out2, 1.05, 1.5, 1.35, 1.6, 0.9, 0.0)
	_ball(st, Vector3(0, 0.95, 0), Vector3(0.78, 0.7, 0.78), 12, 0.0)
	return _finish([[st, _leaf("chou", TX + "chou.png", TX + "chou_n.png", 0.05, 0.25, 0.55, 0.7)]])


## Une laitue : une rosette de feuilles froissées, d'un vert tendre
func _m_laitue(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 950 + variant
	var st := _new_st()
	for ring in range(3):
		var n: int = [9, 7, 5][ring]
		for k in range(n):
			var a: float = TAU * k / n + ring * 0.6 + rng.randf_range(-0.15, 0.15)
			var out := Vector3(cos(a), 0, sin(a))
			var l: float = [1.15, 0.9, 0.65][ring]
			_cup_leaf(st, out * 0.1 + Vector3.UP * (0.1 + ring * 0.1), out, l, l * 0.95, [0.55, 0.9, 1.3][ring], [0.5, 0.6, 0.9][ring], 0.25, 0.22)
	var lm := _leaf("laitue", TX + "chou.png", TX + "chou_n.png", 0.06, 0.45, 0.6, 0.7)
	lm.set_shader_parameter("tint", Color(1.25, 1.35, 0.62))
	return _finish([[st, lm]])


## Un poireau : le fût blanc, l'éventail de feuilles bleu-vert
func _m_poireau(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 980 + variant
	var stem := _new_st()
	_tube(stem, [Vector3(0, -0.2, 0), Vector3(0, 1.0, 0), Vector3(0, 2.0, 0)], [0.34, 0.3, 0.28], [0.0, 0.0, 0.05], 10, Color(1, 1, 1))
	var lv := _new_st()
	var face: float = rng.randf() * PI
	for k in range(7):
		var a: float = face + (PI if k % 2 == 0 else 0.0) + rng.randf_range(-0.25, 0.25)
		var dir := Vector3(cos(a), 0, sin(a))
		_blade(lv, Vector3(0, 1.6 + k * 0.22, 0) + dir * 0.1, dir, rng.randf_range(2.6, 3.6), 0.55, 1.15 - k * 0.04, 0.55, 0.35, 6, 0.1)
	return _finish([[stem, _plain("poireau_fut", Color(0.92, 0.94, 0.86), Color(0.7, 0.82, 0.62), 0.02, 0.3, 0.5)],
		[lv, _plain("poireau_feuille", Color(0.3, 0.45, 0.36), Color(0.36, 0.52, 0.46), 0.12, 0.3, 0.55)]])


## Une carotte : le haut orange qui dépasse de la terre, les fanes en plumeau
func _m_carotte(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1010 + variant
	var root := _new_st()
	_tube(root, [Vector3(0, -0.6, 0), Vector3(0, 0.1, 0), Vector3(0, 0.22, 0)], [0.32, 0.3, 0.12], [0.0, 0.0, 0.0], 10)
	var fr := _new_st()
	for k in range(7):
		var a: float = TAU * k / 7.0 + rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), 0, sin(a))
		var top: Vector3 = Vector3(0, 0.2, 0) + dir * rng.randf_range(0.6, 1.0) + Vector3.UP * rng.randf_range(1.8, 2.4)
		_tube(fr, [Vector3(0, 0.2, 0), Vector3(0, 0.2, 0).lerp(top, 0.5) + Vector3.UP * 0.2, top], [0.05, 0.04, 0.02], [0.05, 0.5, 1.0], 4)
		for j in range(3):
			var c: Vector3 = Vector3(0, 0.2, 0).lerp(top, 0.45 + j * 0.25)
			var s: float = 0.55 - j * 0.12
			_card(fr, c + Vector3.UP * s * 0.5, dir.cross(Vector3.UP).normalized() * s, (Vector3.UP * 0.8 + dir * 0.6).normalized() * s, 0.5 + j * 0.2)
	return _finish([[root, _plain("carotte", Color(0.9, 0.42, 0.08), Color(0.95, 0.5, 0.12), 0.0, 0.1, 0.55)],
		[fr, _leaf("fanes", FL + "fern.png", "", 0.12, 0.45, 0.6)]])


## Une citrouille côtelée (dix côtes), sa queue tordue ; r : le rayon
func _m_citrouille(r: float, variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1040 + variant
	var st := _new_st()
	var nu: int = 40
	var nv: int = 18
	var grid: Array = []
	for j in range(nv + 1):
		var th: float = PI * float(j) / nv
		var row: Array = []
		for i in range(nu + 1):
			var ph: float = TAU * float(i) / nu
			var rib: float = 1.0 - 0.07 * (0.5 - 0.5 * cos(ph * 10.0))
			var squash: float = 0.78 - 0.1 * pow(cos(th), 2.0)
			var d := Vector3(sin(th) * cos(ph) * rib, cos(th) * squash, sin(th) * sin(ph) * rib)
			# le creux autour de la queue et dessous
			d.y -= 0.12 * pow(maxf(cos(th), 0.0), 8.0) - 0.06 * pow(maxf(-cos(th), 0.0), 8.0)
			row.append(d * r + Vector3.UP * r * 0.74)
		grid.append(row)
	for j2 in range(nv):
		for i2 in range(nu):
			var q := [[i2, j2], [i2 + 1, j2], [i2 + 1, j2 + 1], [i2, j2 + 1]]
			var pa: Vector3 = grid[j2][i2]
			var pb: Vector3 = grid[j2][i2 + 1]
			var pd: Vector3 = grid[j2 + 1][i2]
			var nrm: Vector3 = (pd - pa).cross(pb - pa).normalized()
			var center: Vector3 = Vector3.UP * r * 0.74
			if nrm.dot(pa - center) < 0.0:
				nrm = -nrm
			for idx in [0, 2, 1, 0, 3, 2]:
				var cc: Array = q[idx]
				var p: Vector3 = grid[cc[1]][cc[0]]
				var nn: Vector3 = (p - center).normalized().lerp(nrm, 0.5).normalized()
				_v(st, p, nn, Vector2(float(cc[0]) / nu, float(cc[1]) / nv), 0.0, 1.0)
	var stem := _new_st()
	var top: Vector3 = Vector3.UP * r * 1.38
	_tube(stem, [top - Vector3.UP * 0.2, top + Vector3(0.1, 0.5, 0) * r * 0.5, top + Vector3(0.45, 0.75, 0.1) * r * 0.5], [0.22 * r, 0.16 * r, 0.12 * r], [0.0, 0.0, 0.0], 7)
	return _finish([[st, _std("citrouille", Color(1, 1, 1), 0.5, TX + "citrouille.png", TX + "citrouille_n.png")],
		[stem, _plain("tige_citrouille", Color(0.36, 0.36, 0.16), Color(0.5, 0.46, 0.22), 0.0, 0.1, 0.8)]])


## Une grande feuille de citrouille, posée presque à plat, sur sa tige
func _m_feuille_citrouille(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1080 + variant
	var st := _new_st()
	var lf := _new_st()
	var s: float = rng.randf_range(1.4, 1.9)
	var tilt: float = rng.randf_range(0.15, 0.45)
	var c: Vector3 = Vector3(0, 1.2 + tilt * 0.8, 0)
	_tube(st, [Vector3(0, 0, 0), Vector3(0, 0.7, 0.1), c], [0.09, 0.08, 0.07], [0.0, 0.3, 0.6], 5)
	_card(lf, c + Vector3(0, 0.0, 0.0), Vector3(s, 0, 0), Vector3(0, sin(tilt), cos(tilt)) * s, 0.6)
	return _finish([[st, _plain("tige_verte", Color(0.3, 0.42, 0.14), Color(0.4, 0.55, 0.2), 0.04)],
		[lf, _leaf("feuille_citrouille", TX + "feuille_citrouille.png", "", 0.08, 0.45, 0.65)]])


## Une tomate sur son tuteur : le tuteur de bois, la tige, des feuilles, des tomates rouges et vertes
func _m_tomate(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1120 + variant
	var bois := _new_st()
	_tube(bois, [Vector3(0, -0.5, 0), Vector3(0, 11.5, 0)], [0.2, 0.17], [0.0, 0.0], 6)
	var tige := _new_st()
	var path: Array = []
	var radii: Array = []
	var flex: Array = []
	for k in range(9):
		var t: float = float(k) / 8.0
		path.append(Vector3(cos(t * 9.0) * 0.45, t * 10.0, sin(t * 9.0) * 0.45))
		radii.append(lerpf(0.13, 0.06, t))
		flex.append(t * 0.3)
	_tube(tige, path, radii, flex, 5)
	var lv := _new_st()
	var fruits := _new_st()
	var vert := _new_st()
	for k2 in range(16):
		var y: float = rng.randf_range(1.0, 10.5)
		var a: float = rng.randf() * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var c: Vector3 = Vector3(0, y, 0) + dir * rng.randf_range(0.8, 1.6)
		var s: float = rng.randf_range(0.9, 1.3)
		_card(lv, c, dir.cross(Vector3.UP).normalized() * s, (dir * 0.7 + Vector3.UP * 0.5).normalized() * s, 0.5 + y / 22.0)
	for k3 in range(4):
		var y2: float = rng.randf_range(2.0, 8.5)
		var a2: float = rng.randf() * TAU
		for m in range(rng.randi_range(2, 4)):
			var tp: Vector3 = Vector3(cos(a2) * 0.9, y2 - m * 0.45, sin(a2) * 0.9) + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
			var rr: float = rng.randf_range(0.3, 0.42)
			if rng.randf() < 0.7:
				_ball(fruits, tp, Vector3(rr, rr * 0.88, rr), 10, 0.3)
			else:
				_ball(vert, tp, Vector3(rr, rr * 0.88, rr) * 0.85, 10, 0.3)
	return _finish([[bois, _std("tuteur", Color(0.62, 0.48, 0.32), 0.85)], [tige, _plain("tige_tomate", Color(0.26, 0.4, 0.12), Color(0.34, 0.5, 0.16), 0.05)],
		[lv, _leaf("feuille_tomate", FL + "leaves.png", FL + "leaves_n.png", 0.1, 0.45, 0.6)],
		[fruits, _std("tomate", Color(0.86, 0.1, 0.06), 0.22)], [vert, _std("tomate_verte", Color(0.45, 0.62, 0.2), 0.3)]])


## Les haricots : trois perches en tipi, des lianes de feuilles, des gousses qui pendent
func _m_haricots(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1160 + variant
	var bois := _new_st()
	var top := Vector3(0, 15.0, 0)
	var feet: Array = []
	for k in range(3):
		var a: float = TAU * k / 3.0 + 0.4
		var f := Vector3(cos(a), 0, sin(a)) * 2.6
		feet.append(f)
		_tube(bois, [f + Vector3(0, -0.4, 0), top + Vector3(cos(a), 0, sin(a)) * 0.3 + Vector3.UP * 1.2], [0.2, 0.15], [0.0, 0.0], 6)
	var lv := _new_st()
	var gousses := _new_st()
	for f2 in feet:
		for k2 in range(9):
			var t: float = float(k2) / 9.0 + rng.randf_range(0.0, 0.08)
			var p: Vector3 = (f2 as Vector3).lerp(top, t) + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
			var dir: Vector3 = ((f2 as Vector3) + Vector3(0.01, 0, 0)).normalized()
			var s: float = rng.randf_range(0.7, 1.0)
			_card(lv, p + dir * 0.4, dir.cross(Vector3.UP).normalized() * s, (dir * 0.5 + Vector3.UP * 0.8).normalized() * s, 0.5 + t * 0.4)
			if k2 % 2 == 1:
				_tube(gousses, [p + dir * 0.5, p + dir * 0.6 + Vector3.DOWN * 1.1], [0.09, 0.06], [0.5, 0.8], 5)
	return _finish([[bois, _std("perche", Color(0.58, 0.46, 0.3), 0.88)], [lv, _leaf("feuille_haricot", FL + "leaves.png", FL + "leaves_n.png", 0.1, 0.45, 0.6)],
		[gousses, _plain("gousse", Color(0.36, 0.56, 0.18), Color(0.46, 0.66, 0.22), 0.1)]])


## Un tournesol : la tige, de grandes feuilles en cœur, la fleur (le cœur à graines, les pétales)
func _m_tournesol(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1200 + variant
	var h: float = rng.randf_range(12.5, 15.5)
	var tige := _new_st()
	var path: Array = []
	var radii: Array = []
	var flex: Array = []
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	for k in range(7):
		var t: float = float(k) / 6.0
		path.append(Vector3.UP * h * t + lean * t * t)
		radii.append(lerpf(0.3, 0.17, t))
		flex.append(t * t * 0.9)
	_tube(tige, path, radii, flex, 8)
	var lv := _new_st()
	for k2 in range(8):
		var t2: float = 0.18 + k2 * 0.085
		var a: float = k2 * 2.4 + rng.randf()
		var dir := Vector3(cos(a), 0, sin(a))
		_blade(lv, Vector3.UP * h * t2 + lean * t2 * t2, dir, rng.randf_range(1.8, 2.4), 1.6, 0.25, 0.55, 0.12, 5, t2 * t2 * 0.9)
	# la fleur : un disque légèrement bombé, tourné vers le sud-est et un peu vers le bas
	var head_c: Vector3 = Vector3.UP * h + lean
	var face: Vector3 = Vector3(0.55, -0.42, 0.72).normalized()
	var ax: Vector3 = face.cross(Vector3.UP).normalized()
	var ay: Vector3 = ax.cross(face).normalized()
	var R: float = rng.randf_range(1.05, 1.3)
	var disc := _new_st()
	var nseg: int = 24
	for i in range(nseg):
		var a0: float = TAU * i / nseg
		var a1: float = TAU * (i + 1) / nseg
		var p0: Vector3 = head_c + face * 0.35
		var p1: Vector3 = head_c + (ax * cos(a0) + ay * sin(a0)) * R + face * 0.15
		var p2: Vector3 = head_c + (ax * cos(a1) + ay * sin(a1)) * R + face * 0.15
		for e in [[p0, Vector2(0.5, 0.5)], [p1, Vector2(0.5 + 0.5 * cos(a0), 0.5 - 0.5 * sin(a0))], [p2, Vector2(0.5 + 0.5 * cos(a1), 0.5 - 0.5 * sin(a1))]]:
			_v(disc, e[0], face, e[1], 1.0, 1.0)
	# le dos de la fleur : un calice vert, en cône peu profond derrière le disque
	var back := _new_st()
	var apex: Vector3 = head_c - face * 0.55
	for i2 in range(nseg):
		var b0: float = TAU * i2 / nseg
		var b1: float = TAU * (i2 + 1) / nseg
		var q0: Vector3 = head_c + (ax * cos(b0) + ay * sin(b0)) * R * 1.02 + face * 0.12
		var q1: Vector3 = head_c + (ax * cos(b1) + ay * sin(b1)) * R * 1.02 + face * 0.12
		var nb: Vector3 = ((q0 + q1) * 0.5 - head_c).normalized().lerp(-face, 0.5).normalized()
		for e2 in [[apex, Vector2(0.5, 0.0)], [q1, Vector2(1.0, 1.0)], [q0, Vector2(0.0, 1.0)]]:
			_v(back, e2[0], nb, e2[1], 1.0, 1.0)
	var petals := _new_st()
	var np: int = 26
	for k3 in range(np):
		var a3: float = TAU * k3 / np + (0.12 if k3 % 2 == 0 else 0.0)
		var rd: Vector3 = ax * cos(a3) + ay * sin(a3)
		var base: Vector3 = head_c + rd * R * 0.92 + face * (0.18 if k3 % 2 == 0 else 0.1)
		var pl: float = rng.randf_range(0.85, 1.1)
		var pw: float = 0.34
		var side: Vector3 = rd.cross(face).normalized()
		var tip: Vector3 = base + rd * pl + face * 0.12
		var q := [base - side * pw * 0.3, base + side * pw * 0.3, base + rd * pl * 0.5 + side * pw * 0.55 + face * 0.08, tip, base + rd * pl * 0.5 - side * pw * 0.55 + face * 0.08]
		for idx in [0, 1, 2, 0, 2, 4, 4, 2, 3]:
			_v(petals, q[idx], face, Vector2(0.5, 1.0 - float(idx) / 4.0), 1.0, 1.0)
	return _finish([[tige, _plain("tige_tournesol", Color(0.3, 0.44, 0.14), Color(0.42, 0.56, 0.2), 0.45, 0.3, 0.7, 0.55)],
		[lv, _plain("feuille_tournesol", Color(0.22, 0.4, 0.1), Color(0.34, 0.52, 0.16), 0.45, 0.45, 0.65, 0.55)],
		[disc, _leaf("tournesol_coeur", TX + "tournesol.png", "", 0.45, 0.1, 0.8, 0.55)],
		[back, _plain("tournesol_dos", Color(0.25, 0.4, 0.12), Color(0.28, 0.44, 0.14), 0.45, 0.2, 0.7, 0.55)],
		[petals, _plain("petale", Color(0.98, 0.72, 0.06), Color(1.0, 0.84, 0.18), 0.45, 0.7, 0.6, 0.55)]])


# =================================================================== les prés

## Une touffe d'herbe à l'échelle des géants (des brins aussi hauts que nos genoux)
func _m_herbe(variant: int, h: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1300 + variant
	var st := _new_st()
	for b in range(9):
		var a: float = rng.randf() * TAU
		var root := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.55)
		var lean := Vector3(cos(a + rng.randf_range(-0.6, 0.6)), 0, sin(a + rng.randf_range(-0.6, 0.6)))
		var hh: float = h * rng.randf_range(0.6, 1.2)
		var bend: float = rng.randf_range(0.15, 0.45)
		var face: float = rng.randf() * TAU
		var side := Vector3(cos(face), 0, sin(face)) * rng.randf_range(0.06, 0.11)
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for s in range(4):
			var t: float = float(s) / 3.0
			var center: Vector3 = root + Vector3.UP * hh * t + lean * bend * hh * t * t
			var half: Vector3 = side * 0.5 * (1.0 - t * 0.92)
			var l: Vector3 = center - half
			var r: Vector3 = center + half
			var n: Vector3 = (Vector3.UP * 0.7 + lean * 0.3).normalized()
			if s > 0:
				var t0: float = float(s - 1) / 3.0
				_v(st, prev_l, n, Vector2(0, t0), t0 * t0, t0)
				_v(st, l, n, Vector2(0, t), t * t, t)
				_v(st, prev_r, n, Vector2(1, t0), t0 * t0, t0)
				_v(st, prev_r, n, Vector2(1, t0), t0 * t0, t0)
				_v(st, l, n, Vector2(0, t), t * t, t)
				_v(st, r, n, Vector2(1, t), t * t, t)
			prev_l = l
			prev_r = r
	return _finish([[st, _plain("herbe", Color(0.17, 0.32, 0.07), Color(0.6, 0.72, 0.3), 0.22, 0.4, 0.75, 1.0)]])


## Une marguerite : la tige, quelques feuilles, le cœur jaune, les pétales blancs
func _m_marguerite(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1400 + variant
	var h: float = rng.randf_range(2.6, 3.4)
	var tige := _new_st()
	var lean := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
	_tube(tige, [Vector3.ZERO, Vector3.UP * h * 0.5 + lean * 0.25, Vector3.UP * h + lean], [0.07, 0.06, 0.05], [0.0, 0.3, 1.0], 5)
	for k in range(4):
		var a: float = rng.randf() * TAU
		_blade(tige, Vector3.UP * rng.randf_range(0.0, h * 0.4), Vector3(cos(a), 0, sin(a)), rng.randf_range(0.6, 0.9), 0.18, 0.5, 0.4, 0.1, 3, 0.1)
	var c: Vector3 = Vector3.UP * h + lean
	var face: Vector3 = (Vector3.UP + lean * 0.8 + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))).normalized()
	var ax: Vector3 = face.cross(Vector3.RIGHT).normalized()
	var ay: Vector3 = face.cross(ax).normalized()
	var coeur := _new_st()
	_ball(coeur, c + face * 0.05, Vector3(0.17, 0.08, 0.17), 8, 1.0)
	var pet := _new_st()
	for k2 in range(20):
		var a2: float = TAU * k2 / 20.0
		var rd: Vector3 = ax * cos(a2) + ay * sin(a2)
		var side: Vector3 = rd.cross(face).normalized() * 0.055
		var b0: Vector3 = c + rd * 0.14
		var b1: Vector3 = c + rd * 0.55 - face * 0.05
		for e in [[b0 - side, Vector2(0, 1)], [b0 + side, Vector2(1, 1)], [b1 + side, Vector2(1, 0)], [b0 - side, Vector2(0, 1)], [b1 + side, Vector2(1, 0)], [b1 - side, Vector2(0, 0)]]:
			_v(pet, e[0], face, e[1], 1.0, 1.0)
	return _finish([[tige, _plain("tige_fleur", Color(0.24, 0.42, 0.12), Color(0.34, 0.52, 0.16), 0.15)],
		[coeur, _plain("coeur_jaune", Color(0.95, 0.72, 0.08), Color(0.98, 0.8, 0.12), 0.15, 0.3, 0.8)],
		[pet, _plain("petale_blanc", Color(0.96, 0.96, 0.92), Color(1.0, 1.0, 0.97), 0.15, 0.7, 0.6)]])


## Un coquelicot : une tige souple, quatre grands pétales rouges en coupe, le cœur noir
func _m_coquelicot(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1450 + variant
	var h: float = rng.randf_range(3.0, 3.8)
	var tige := _new_st()
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	_tube(tige, [Vector3.ZERO, Vector3.UP * h * 0.6 + lean * 0.3, Vector3.UP * h + lean], [0.06, 0.05, 0.045], [0.0, 0.4, 1.0], 5)
	for k in range(3):
		var a: float = rng.randf() * TAU
		_blade(tige, Vector3.UP * rng.randf_range(0.0, 0.5), Vector3(cos(a), 0, sin(a)), rng.randf_range(0.7, 1.0), 0.3, 0.4, 0.4, 0.1, 3, 0.1, Color.WHITE, 0.4)
	var c: Vector3 = Vector3.UP * h + lean
	var pet := _new_st()
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + rng.randf() * 0.3
		var out := Vector3(cos(a2), 0, sin(a2))
		_cup_leaf(pet, c + out * 0.05, out, 0.58, 0.95, 1.1, 0.5, 0.5, 0.06)
	var coeur := _new_st()
	_ball(coeur, c + Vector3.UP * 0.18, Vector3(0.14, 0.17, 0.14), 8, 1.0)
	return _finish([[tige, _plain("tige_fleur", Color(0.24, 0.42, 0.12), Color(0.34, 0.52, 0.16), 0.15)],
		[pet, _plain("petale_rouge", Color(0.78, 0.06, 0.04), Color(0.95, 0.14, 0.08), 0.15, 0.8, 0.55)],
		[coeur, _plain("coeur_noir", Color(0.08, 0.08, 0.06), Color(0.2, 0.22, 0.12), 0.15, 0.1, 0.8)]])


## Un pissenlit : la rosette de feuilles dentées, une tige creuse, la fleur jaune… ou la boule de graines
func _m_pissenlit(variant: int, boule: bool) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1500 + variant
	var h: float = rng.randf_range(2.0, 2.8)
	var lv := _new_st()
	for k in range(7):
		var a: float = TAU * k / 7.0 + rng.randf() * 0.4
		_blade(lv, Vector3.ZERO, Vector3(cos(a), 0, sin(a)), rng.randf_range(1.0, 1.4), 0.32, 0.18, 0.2, 0.05, 5, 0.05, Color.WHITE, 0.9)
	_tube(lv, [Vector3.ZERO, Vector3.UP * h * 0.5, Vector3.UP * h], [0.06, 0.055, 0.05], [0.0, 0.4, 1.0], 5)
	var head := _new_st()
	var c: Vector3 = Vector3.UP * h
	if boule:
		_ball(head, c, Vector3(0.46, 0.46, 0.46), 12, 1.0)
		return _finish([[lv, _plain("feuille_pissenlit", Color(0.22, 0.4, 0.1), Color(0.3, 0.5, 0.14), 0.12)],
			[head, _plain("aigrettes", Color(0.94, 0.94, 0.9), Color(1.0, 1.0, 0.98), 0.12, 0.9, 0.95)]])
	for k2 in range(36):
		var a2: float = TAU * k2 / 36.0
		var rd := Vector3(cos(a2), 0.25, sin(a2)).normalized()
		var side: Vector3 = rd.cross(Vector3.UP).normalized() * 0.035
		var b1: Vector3 = c + rd * 0.32
		for e in [[c - side, Vector2(0, 1)], [c + side, Vector2(1, 1)], [b1 + side, Vector2(1, 0)], [c - side, Vector2(0, 1)], [b1 + side, Vector2(1, 0)], [b1 - side, Vector2(0, 0)]]:
			_v(head, e[0], Vector3.UP, e[1], 1.0, 1.0)
	_ball(head, c, Vector3(0.18, 0.12, 0.18), 8, 1.0)
	return _finish([[lv, _plain("feuille_pissenlit", Color(0.22, 0.4, 0.1), Color(0.3, 0.5, 0.14), 0.12)],
		[head, _plain("fleur_pissenlit", Color(0.98, 0.76, 0.05), Color(1.0, 0.86, 0.15), 0.12, 0.6, 0.6)]])


## Une touffe de trèfle : des feuilles à trois folioles, deux fleurs roses en pompon
func _m_trefle(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1550 + variant
	var st := _new_st()
	var fl := _new_st()
	for k in range(12):
		var a: float = rng.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.8)
		var top: Vector3 = base + Vector3.UP * rng.randf_range(0.4, 0.8)
		_tube(st, [base, top], [0.025, 0.02], [0.0, 0.6], 3)
		for j in range(3):
			var aj: float = a + TAU * j / 3.0
			var d := Vector3(cos(aj), 0.15, sin(aj)).normalized()
			_card(st, top + d * 0.17, d.cross(Vector3.UP).normalized() * 0.14, d * 0.17, 0.6)
	for k2 in range(2):
		var a2: float = rng.randf() * TAU
		var b2 := Vector3(cos(a2), 0, sin(a2)) * 0.4
		_tube(st, [b2, b2 + Vector3.UP * 1.0], [0.03, 0.025], [0.0, 0.8], 3)
		_ball(fl, b2 + Vector3.UP * 1.1, Vector3(0.17, 0.2, 0.17), 8, 0.8)
	return _finish([[st, _plain("trefle", Color(0.18, 0.4, 0.12), Color(0.3, 0.52, 0.18), 0.1, 0.4, 0.7)],
		[fl, _plain("trefle_fleur", Color(0.85, 0.48, 0.62), Color(0.95, 0.66, 0.78), 0.1, 0.5, 0.8)]])


## Une touffe de blé : cinq tiges, cinq épis penchés (cartes croisées)
func _m_ble(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1600 + variant
	var tiges := _new_st()
	var epis := _new_st()
	for k in range(5):
		var a: float = rng.randf() * TAU
		var root := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.6)
		var h: float = rng.randf_range(6.2, 7.4)
		var lean := Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
		var top: Vector3 = root + Vector3.UP * h + lean
		_tube(tiges, [root, root + Vector3.UP * h * 0.5 + lean * 0.25, top], [0.06, 0.05, 0.04], [0.0, 0.35, 1.0], 4)
		for j in range(2):
			var aj: float = a + PI * 0.5 * j
			var side := Vector3(cos(aj), 0, sin(aj)) * 0.22
			var nod: Vector3 = (Vector3.UP + lean * 0.9 + Vector3(0.25, 0, 0.1)).normalized()
			_card(epis, top + nod * 0.8, side, nod * 0.85, 1.0)
		var lf: float = rng.randf() * TAU
		_blade(tiges, root + Vector3.UP * h * 0.3, Vector3(cos(lf), 0, sin(lf)), 1.6, 0.18, 0.4, 0.7, 0.1, 3, 0.3)
	return _finish([[tiges, _plain("tige_ble", Color(0.72, 0.62, 0.3), Color(0.86, 0.76, 0.42), 0.35, 0.4, 0.8, 0.7)],
		[epis, _leaf("epi", TX + "ble.png", "", 0.35, 0.5, 0.8, 0.7)]])


## Une massette (au bord de la mare) : de longues feuilles, deux tiges et leurs « cigares » bruns
func _m_massette(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1650 + variant
	var lv := _new_st()
	var cig := _new_st()
	for k in range(7):
		var a: float = rng.randf() * TAU
		_blade(lv, Vector3(cos(a), 0, sin(a)) * 0.3, Vector3(cos(a), 0, sin(a)), rng.randf_range(8.0, 11.0), 0.45, 1.4, 0.35, 0.15, 6, 0.0)
	for k2 in range(2):
		var b := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		var h: float = rng.randf_range(9.0, 11.5)
		_tube(lv, [b, b + Vector3.UP * h], [0.09, 0.06], [0.0, 0.7], 5)
		_tube(cig, [b + Vector3.UP * (h - 2.4), b + Vector3.UP * (h - 2.3), b + Vector3.UP * (h - 0.7), b + Vector3.UP * (h - 0.6)], [0.05, 0.3, 0.3, 0.05], [0.6, 0.65, 0.7, 0.7], 8)
	return _finish([[lv, _plain("massette", Color(0.24, 0.4, 0.14), Color(0.48, 0.6, 0.26), 0.3, 0.4, 0.7, 0.7)],
		[cig, _plain("cigare", Color(0.36, 0.22, 0.1), Color(0.42, 0.27, 0.13), 0.3, 0.1, 0.9, 0.7)]])


## Une feuille de nénuphar (posée sur l'eau) ; parfois une fleur
func _m_nenuphar(fleur: bool) -> ArrayMesh:
	var st := _new_st()
	_card(st, Vector3(0, 0.02, 0), Vector3(1.4, 0, 0), Vector3(0, 0, 1.4), 0.0, Color.WHITE, 1.0)
	var parts: Array = [[st, _leaf("nenuphar", TX + "nenuphar.png", "", 0.0, 0.3, 0.45)]]
	if fleur:
		var pf := _new_st()
		for ring in range(2):
			for k in range(8):
				var a: float = TAU * k / 8.0 + ring * 0.4
				var out := Vector3(cos(a), 0, sin(a))
				_cup_leaf(pf, Vector3(0.3, 0.05, 0.2) + out * 0.05, out, 0.55 - ring * 0.12, 0.32, 1.3 + ring * 0.8, 0.4, 0.5, 0.0)
		parts.append([pf, _plain("nenuphar_fleur", Color(0.98, 0.82, 0.88), Color(1.0, 0.95, 0.97), 0.0, 0.6, 0.5)])
	return _finish(parts)


# =================================================================== les arbres

## Un pommier de géant (ou un chêne) : l'arbre de Flora V25, à l'échelle, avec ses propres matières
## (le vent plus lent et plus ample, comme pour un grand arbre)
func _m_arbre(seed_value: int, h: float, leaves: int, key: String, tint: Color) -> ArrayMesh:
	var m: ArrayMesh = Flora.tree(seed_value, h, leaves).duplicate()
	var bark := _leaf("ecorce_" + key, FL + "bark.png", FL + "bark_n.png", 0.02, 0.0, 0.93, 0.5)
	var lf := _leaf("feuilles_" + key, FL + "leaves.png", FL + "leaves_n.png", 0.06, 0.5, 0.55, 0.5)
	lf.set_shader_parameter("tint", tint)
	m.surface_set_material(0, bark)
	m.surface_set_material(1, lf)
	return m


# =================================================================== placement

func _add(species: String, xf: Transform3D) -> void:
	if not _lists.has(species):
		_lists[species] = []
	(_lists[species] as Array).append(xf)
	counts[species] = int(counts.get(species, 0)) + 1


func _at(x: float, z: float, sink: float = 0.0) -> Vector3:
	return Ile.W(x, z, ile.height_l(x, z) - sink)


func _xf(pos: Vector3, s: float, yaw: float = INF) -> Transform3D:
	var y: float = yaw if not is_inf(yaw) else _rng.randf() * TAU
	return Transform3D(Basis(Vector3.UP, y).scaled(Vector3.ONE * s), pos)


func _col_cyl(at: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	cs.shape = c
	cs.position = at + Vector3.UP * h * 0.5
	_cols.add_child(cs)


func _blocked(x: float, z: float, m: float = 0.0) -> bool:
	if Ile.in_maison(x, z, 6.0 + m) or Ile.in_grange(x, z, 6.0 + m) or Ile.in_rect(Ile.COUR, x, z, 3.0 + m):
		return true
	if Ile.in_rect(Ile.POTAGER, x, z, 3.0 + m) or Ile.in_rect(Ile.BLE, x, z, 1.0 + m):
		return true
	var ch: Vector2 = Ile.chemin_at(x, z)
	if ch.x < ch.y + 2.0 + m:
		return true
	if Ile.mare_q(x, z) < 1.25:
		return true
	if Vector2(x, z).distance_to(Ile.MOULIN) < 26.0 + m or Vector2(x, z).distance_to(Ile.PUITS) < 8.0 + m:
		return true
	for a in avoid:
		if Vector2(x, z).distance_to(a[0]) < float(a[1]) + m:
			return true
	return false


func _land_ok(x: float, z: float, min_h: float = 2.2) -> bool:
	return ile.coast_q(x, z) < 0.93 and ile.height_l(x, z) > min_h


## Le potager : chaque planche, ses rangs (sur le haut des buttes)
func _potager() -> void:
	var mc: Array = [_m_chou(0), _m_chou(1)]
	var ml: Array = [_m_laitue(0), _m_laitue(1)]
	var mp: Array = [_m_poireau(0), _m_poireau(1)]
	var mk: Array = [_m_carotte(0), _m_carotte(1)]
	var mt: Array = [_m_tomate(0), _m_tomate(1), _m_tomate(2)]
	var mh: Array = [_m_haricots(0), _m_haricots(1)]
	_mesh_of["chou_0"] = mc[0]
	_mesh_of["chou_1"] = mc[1]
	_mesh_of["laitue_0"] = ml[0]
	_mesh_of["laitue_1"] = ml[1]
	_mesh_of["poireau_0"] = mp[0]
	_mesh_of["poireau_1"] = mp[1]
	_mesh_of["carotte_0"] = mk[0]
	_mesh_of["carotte_1"] = mk[1]
	for i in range(3):
		_mesh_of["tomate_%d" % i] = mt[i]
	_mesh_of["haricots_0"] = mh[0]
	_mesh_of["haricots_1"] = mh[1]
	for key in Ile.PLANCHES:
		var r: Array = Ile.PLANCHES[key]
		var k: int = 0
		var x: float = float(r[0]) + Ile.SILLON * 0.5
		while x < float(r[2]) - 1.0:
			var z: float = float(r[1]) + 2.6
			var step: float = 4.6
			match str(key):
				"choux":
					step = 4.8 if k % 2 == 0 else 3.4
				"poireaux":
					step = 2.6 if k % 2 == 0 else 2.2
				"tomates":
					step = 4.4 if k % 2 == 0 else 9.0
			var j: int = 0
			while z < float(r[3]) - 2.0:
				var p: Vector3 = _at(x + _rng.randf_range(-0.25, 0.25), z + _rng.randf_range(-0.3, 0.3))
				match str(key):
					"choux":
						if k % 2 == 0:
							_add("chou_%d" % (j % 2), _xf(p, _rng.randf_range(0.9, 1.12)))
							_col_cyl(p, 0.75, 1.5)
						else:
							_add("laitue_%d" % (j % 2), _xf(p, _rng.randf_range(0.9, 1.1)))
					"poireaux":
						if k % 2 == 0:
							_add("poireau_%d" % (j % 2), _xf(p, _rng.randf_range(0.9, 1.1)))
							_col_cyl(p, 0.32, 2.2)
						else:
							_add("carotte_%d" % (j % 2), _xf(p, _rng.randf_range(0.85, 1.1)))
					"tomates":
						if k % 2 == 0:
							_add("tomate_%d" % (j % 3), _xf(p, _rng.randf_range(0.92, 1.08)))
							_col_cyl(p, 0.3, 11.5)
						else:
							_add("haricots_%d" % (j % 2), _xf(p, _rng.randf_range(0.92, 1.05)))
							_col_cyl(p, 2.6, 0.5)
					"citrouilles":
						pass
				z += step
				j += 1
			x += Ile.SILLON
			k += 1
	# les citrouilles : six belles, et la Géante de l'oncle Théophile (au milieu de la planche)
	var r2: Array = Ile.PLANCHES["citrouilles"]
	var mid := Vector2((float(r2[0]) + float(r2[2])) * 0.5, (float(r2[1]) + float(r2[3])) * 0.5)
	_mesh_of["citrouille_geante"] = _m_citrouille(3.4, 9)
	_add("citrouille_geante", _xf(_at(mid.x, mid.y, 0.4), 1.0))
	_col_cyl(_at(mid.x, mid.y), 3.3, 5.2)
	avoid.append([mid, 5.0])
	for v in range(3):
		_mesh_of["citrouille_%d" % v] = _m_citrouille(1.5 + v * 0.25, v)
	var spots := [Vector2(-11, -12), Vector2(10, -13), Vector2(-12, 11), Vector2(12, 12), Vector2(0, -16), Vector2(-1, 16)]
	for i2 in range(spots.size()):
		var q: Vector2 = mid + spots[i2] + Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-1.5, 1.5))
		var rr: float = 1.5 + (i2 % 3) * 0.25
		_add("citrouille_%d" % (i2 % 3), _xf(_at(q.x, q.y, 0.25), 1.0))
		_col_cyl(_at(q.x, q.y), rr, rr * 1.5)
	for v2 in range(3):
		_mesh_of["feuille_citrouille_%d" % v2] = _m_feuille_citrouille(v2)
	for k3 in range(70):
		var q2 := Vector2(_rng.randf_range(float(r2[0]) + 1.0, float(r2[2]) - 1.0), _rng.randf_range(float(r2[1]) + 1.0, float(r2[3]) - 1.0))
		if q2.distance_to(mid) < 4.5:
			continue
		_add("feuille_citrouille_%d" % (k3 % 3), _xf(_at(q2.x, q2.y), _rng.randf_range(0.85, 1.2)))


var _mesh_of: Dictionary = {}


func _tournesols() -> void:
	for v in range(3):
		_mesh_of["tournesol_%d" % v] = _m_tournesol(v)
	var r: Array = Ile.POTAGER
	var k: int = 0
	var x: float = float(r[0]) + 4.0
	while x < float(r[2]) - 3.0:
		var p: Vector3 = _at(x + _rng.randf_range(-0.6, 0.6), float(r[1]) + 3.0 + _rng.randf_range(-0.6, 0.6))
		_add("tournesol_%d" % (k % 3), _xf(p, _rng.randf_range(0.9, 1.08), _rng.randf_range(-0.3, 0.3)))
		_col_cyl(p, 0.32, 12.0)
		tournesols.append(p)
		x += 4.4
		k += 1
	var z: float = float(r[1]) + 9.0
	while z < float(r[3]) - 3.0:
		var p2: Vector3 = _at(float(r[2]) - 3.0 + _rng.randf_range(-0.6, 0.6), z + _rng.randf_range(-0.6, 0.6))
		_add("tournesol_%d" % (k % 3), _xf(p2, _rng.randf_range(0.9, 1.08), _rng.randf_range(-0.3, 0.3)))
		_col_cyl(p2, 0.32, 12.0)
		tournesols.append(p2)
		z += 4.6
		k += 1


## Le verger : des pommiers (l'arbre V25, haut de 4,8 m, à l'échelle : 36 m), des pommes dedans et dessous
func _verger() -> void:
	for v in range(3):
		_mesh_of["pommier_%d" % v] = _m_arbre(14200 + v, 4.8, 340, "pommier", Color(0.92, 1.08, 0.8))
	var pm := _new_st()
	_ball(pm, Vector3.ZERO, Vector3(0.36, 0.33, 0.36), 10, 0.3)
	_mesh_of["pomme"] = _finish([[pm, _std("pomme", Color(0.78, 0.12, 0.08), 0.35)]])
	var pts: Array = []
	for attempt in range(400):
		if pts.size() >= 15:
			break
		var a: float = _rng.randf() * TAU
		var d: float = sqrt(_rng.randf()) * Ile.VERGER_R
		var q := Ile.VERGER + Vector2(cos(a), sin(a)) * d
		var ok: bool = _land_ok(q.x, q.y, 3.0) and not _blocked(q.x, q.y, 2.0)
		for o in pts:
			if (o as Vector2).distance_to(q) < 17.0:
				ok = false
		if ok:
			pts.append(q)
	for i in range(pts.size()):
		var q2: Vector2 = pts[i]
		var p: Vector3 = _at(q2.x, q2.y, 0.3)
		var s: float = Ile.G * _rng.randf_range(0.88, 1.1)
		var yaw: float = _rng.randf() * TAU
		_add("pommier_%d" % (i % 3), Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), p))
		_col_cyl(p, 0.3 * s, 2.6 * s)
		avoid.append([q2, 4.0])
		# les pommes dans la couronne, et quelques-unes tombées
		var crown: Vector3 = p + Vector3.UP * 4.8 * 0.68 * s
		for k in range(26):
			var dd := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.6, 0.8), _rng.randf_range(-1, 1)).normalized()
			_add("pomme", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), crown + dd * 4.8 * 0.36 * s * _rng.randf_range(0.75, 1.0)))
		for k2 in range(2):
			var a2: float = _rng.randf() * TAU
			var g: Vector2 = q2 + Vector2(cos(a2), sin(a2)) * _rng.randf_range(5.0, 11.0)
			if not _blocked(g.x, g.y):
				var gp: Vector3 = _at(g.x, g.y) + Vector3.UP * 0.3
				_add("pomme", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), gp))
				pommes_sol.append(gp)


func _ble() -> void:
	for v in range(3):
		_mesh_of["ble_%d" % v] = _m_ble(v)
	var r: Array = Ile.BLE
	var x: float = float(r[0]) + 0.8
	var k: int = 0
	while x < float(r[2]) - 0.6:
		var z: float = float(r[1]) + 0.8
		while z < float(r[3]) - 0.6:
			var q := Vector2(x + _rng.randf_range(-0.6, 0.6), z + _rng.randf_range(-0.6, 0.6))
			# une petite clairière au milieu (la cachette préférée de Pâquerette)
			var mid := Vector2((float(r[0]) + float(r[2])) * 0.5 + 6.0, (float(r[1]) + float(r[3])) * 0.5)
			if q.distance_to(mid) > 6.5:
				_add("ble_%d" % (k % 3), _xf(_at(q.x, q.y), _rng.randf_range(0.9, 1.1)))
			z += 1.75
			k += 1
		x += 1.75


func _mare() -> void:
	_mesh_of["nenuphar"] = _m_nenuphar(false)
	_mesh_of["nenuphar_fleur"] = _m_nenuphar(true)
	for v in range(2):
		_mesh_of["massette_%d" % v] = _m_massette(v)
	var pts: Array = []
	for attempt in range(500):
		if pts.size() >= 26:
			break
		var a: float = _rng.randf() * TAU
		var d: float = sqrt(_rng.randf()) * 0.82
		var q := Ile.MARE + Vector2(cos(a) * Ile.MARE_AX.x, sin(a) * Ile.MARE_AX.y) * d
		var ok: bool = true
		for o in pts:
			if (o as Vector2).distance_to(q) < 3.4:
				ok = false
		if ok:
			pts.append(q)
	for i in range(pts.size()):
		var q2: Vector2 = pts[i]
		var p := Ile.W(q2.x, q2.y, Ile.MARE_Y + 0.02)
		_add("nenuphar_fleur" if i % 5 == 0 else "nenuphar", _xf(p, _rng.randf_range(0.85, 1.2)))
		nenuphars.append(p)
	for k in range(34):
		var a2: float = TAU * k / 34.0 + _rng.randf_range(-0.05, 0.05)
		var f: float = _rng.randf_range(0.97, 1.16)
		var q3 := Ile.MARE + Vector2(cos(a2) * Ile.MARE_AX.x, sin(a2) * Ile.MARE_AX.y) * f
		if Ile.chemin_at(q3.x, q3.y).x < 6.0:
			continue
		_add("massette_%d" % (k % 2), _xf(_at(q3.x, q3.y), _rng.randf_range(0.85, 1.15)))


func _chenes() -> void:
	for v in range(2):
		_mesh_of["chene_%d" % v] = _m_arbre(14300 + v, 6.2, 520, "chene", Color(0.86, 1.0, 0.72))
	var spots := [Vector2(-70, -168), Vector2(140, -150), Vector2(196, 40), Vector2(-196, 110), Vector2(-40, 196), Vector2(-196, -60)]
	for i in range(spots.size()):
		var q: Vector2 = spots[i]
		if not _land_ok(q.x, q.y, 2.5):
			continue
		var p: Vector3 = _at(q.x, q.y, 0.4)
		var s: float = Ile.G * _rng.randf_range(0.95, 1.1)
		_add("chene_%d" % (i % 2), Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s), p))
		_col_cyl(p, 0.36 * s, 3.0 * s)
		avoid.append([q, 6.0])


## Les fleurs des prés, par massifs (marguerites, coquelicots, pissenlits, trèfles)
func _fleurs() -> void:
	for v in range(3):
		_mesh_of["marguerite_%d" % v] = _m_marguerite(v)
		_mesh_of["coquelicot_%d" % v] = _m_coquelicot(v)
	for v2 in range(2):
		_mesh_of["pissenlit_%d" % v2] = _m_pissenlit(v2, false)
		_mesh_of["trefle_%d" % v2] = _m_trefle(v2)
	_mesh_of["pissenlit_boule"] = _m_pissenlit(7, true)
	var kinds := ["marguerite", "marguerite", "coquelicot", "pissenlit", "trefle", "marguerite", "coquelicot"]
	var n_patch: int = 70 if pc else 40
	for i in range(n_patch):
		var c := Vector2.ZERO
		var found: bool = false
		for attempt in range(30):
			var a: float = _rng.randf() * TAU
			var d: float = sqrt(_rng.randf()) * (Ile.RS - 20.0)
			c = Vector2(cos(a), sin(a)) * d
			if _land_ok(c.x, c.y, 2.6) and not _blocked(c.x, c.y, 4.0):
				found = true
				break
		if not found:
			continue
		var kind: String = kinds[i % kinds.size()]
		var n: int = _rng.randi_range(6, 14)
		for k in range(n):
			var q: Vector2 = c + Vector2(_rng.randf_range(-9.0, 9.0), _rng.randf_range(-9.0, 9.0))
			if not _land_ok(q.x, q.y, 2.4) or _blocked(q.x, q.y):
				continue
			var sp: String
			match kind:
				"pissenlit":
					sp = "pissenlit_boule" if _rng.randf() < 0.3 else "pissenlit_%d" % (k % 2)
				"trefle":
					sp = "trefle_%d" % (k % 2)
				_:
					sp = "%s_%d" % [kind, k % 3]
			_add(sp, _xf(_at(q.x, q.y), _rng.randf_range(0.85, 1.15)))


## Les MultiMesh, espèce par espèce (les petites choses disparaissent de loin)
func _flush() -> void:
	for sp in _lists:
		var mesh: Mesh = _mesh_of.get(sp)
		if mesh == null:
			continue
		var xfs: Array = _lists[sp]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i in range(xfs.size()):
			mm.set_instance_transform(i, xfs[i])
		var mi := MultiMeshInstance3D.new()
		mi.name = "Flore_" + str(sp)
		mi.multimesh = mm
		var far: float = 0.0
		var base: String = str(sp).split("_")[0]
		match base:
			"pommier", "chene", "tournesol":
				far = 0.0
			"ble":
				far = 240.0
			"marguerite", "coquelicot", "pissenlit", "trefle", "laitue", "carotte", "feuille":
				far = 130.0
			"pomme":
				far = 220.0
			_:
				far = 200.0
		if far > 0.0:
			mi.visibility_range_end = far
			mi.visibility_range_end_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if base in ["trefle", "pissenlit", "carotte", "laitue", "feuille", "nenuphar"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_lists.clear()


## L'herbe : des touffes par carrés de 24 m, visibles de près seulement ; plus courte autour de la
## maison (la pelouse), haute dans les prés.
func _herbe() -> void:
	var meshes: Array = [_m_herbe(0, 1.1), _m_herbe(1, 1.4), _m_herbe(2, 0.7)]
	var density: float = 0.42 if pc else 0.22
	var n_cells: int = int(ceil(Ile.HALF * 2.0 / HERBE_CELL))
	var total: int = 0
	for cz in range(n_cells):
		for cx in range(n_cells):
			var x0: float = -Ile.HALF + cx * HERBE_CELL
			var z0: float = -Ile.HALF + cz * HERBE_CELL
			var mid := Vector2(x0 + HERBE_CELL * 0.5, z0 + HERBE_CELL * 0.5)
			if mid.length() > Ile.RS + 30.0:
				continue
			var lists: Array = [[], [], []]
			var n: int = int(HERBE_CELL * HERBE_CELL * density)
			for k in range(n):
				var q := Vector2(x0 + _rng.randf() * HERBE_CELL, z0 + _rng.randf() * HERBE_CELL)
				if not _land_ok(q.x, q.y, 1.8):
					continue
				if Ile.in_maison(q.x, q.y, 2.0) or Ile.in_grange(q.x, q.y, 1.0) or Ile.mare_q(q.x, q.y) < 1.05:
					continue
				if q.distance_to(Ile.CHATEAU_SABLE) < 26.0:
					continue
				var bio: Color = ile.biome_at(Ile.CENTER.x + q.x, Ile.CENTER.z + q.y)
				if bio.r > 0.35 or bio.g > 0.3 or bio.a > 0.3:
					continue
				var lawn: bool = Vector2(q.x, q.y).distance_to(Ile.PLATEAU) < Ile.PLATEAU_R0 - 10.0
				var which: int = 2 if lawn else (k % 2)
				lists[which].append(_xf(_at(q.x, q.y), _rng.randf_range(0.8, 1.2)))
			for w in range(3):
				var xfs: Array = lists[w]
				if xfs.is_empty():
					continue
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = meshes[w]
				mm.instance_count = xfs.size()
				for i in range(xfs.size()):
					mm.set_instance_transform(i, xfs[i])
				var mi := MultiMeshInstance3D.new()
				mi.name = "Herbe_%d_%d_%d" % [cx, cz, w]
				mi.multimesh = mm
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.visibility_range_end = 75.0 if pc else 50.0
				mi.visibility_range_end_margin = 15.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				add_child(mi)
				total += xfs.size()
	counts["herbe"] = total

extends Node3D
## V115 : la Fosse d'Azur, au fond de la mer, sous les falaises du sud de Hautefond (le maillage taillé
## par tools/generate_fosse_v115.py) : le fond de sable, les falaises de basalte bleu-gris, le canyon du
## Funiculaire et son tunnel, les rochers, la cheminée hydrothermale (shaders/fosse_v115.gdshader) ;
## et ce qui vit sur le fond : les éponges de verre, les anémones qui luisent, les lys de mer, les
## gorgones, les vers géants de la cheminée, des cailloux ; la fumée noire de la cheminée.
## Pas de collision : on ne sort pas des dômes (on ne voit la Fosse qu'à travers le verre).
## Repère local (celui du générateur) : le nœud est posé en O (le centre du Grand Dôme, au sol).

const BIN := "res://assets/models/dome115/fosse.bin"
const SHADER := "res://shaders/fosse_v115.gdshader"
const Corps = preload("res://scripts/pnj/corps_v64.gd")
const O := Vector3(-1110.0, -140.0, 1700.0)

## (gardés en accord avec tools/generate_fosse_v115.py)
const DOMES := [[Vector2(0.0, 0.0), 70.0], [Vector2(-128.0, -16.0), 32.0], [Vector2(124.0, 22.0), 32.0]]
const LDEG: float = -66.0
const L_FLAT: float = 92.0
const L_PORTAL: float = 200.0
const L_END: float = 219.0
const AXE_BAS: float = 2.5
const AXE_HAUT: float = 39.5
const R_TUBE: float = 3.4
const VENT := Vector2(172.0, 54.0)
const VENT_H: float = 15.0

var pc: bool = true
var data: Dictionary = {}
var rock_mat: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var smoke: Array = []
var soft_tex: Texture2D                  # un point doux (main._soft_dot_v24), pour la fumée


static func W(lx: float, lz: float, dy: float = 0.0) -> Vector3:
	return Vector3(O.x + lx, O.y + dy, O.z + lz)


static func L(p: Vector3) -> Vector3:
	return Vector3(p.x - O.x, p.y - O.y, p.z - O.z)


## Est-on dans le Dôme d'Azur (sa fosse, ses dômes, le tube et le tunnel du Funiculaire) ? Au nord, le
## sud des Strates (les Jardins des Champignons) est juste au-dessus du bout du tunnel : là, on ne compte
## que le couloir du tube (neuf mètres autour de son axe, quatre en hauteur), pas le reste.
static func contains(p: Vector3) -> bool:
	var l: Vector3 = L(p)
	if p.y > -40.0 or l.y < -20.0 or l.x < -232.0 or l.x > 232.0 or l.z > 132.0 or l.z < -226.0:
		return false
	if l.z > -140.0:
		return true
	var d: Vector3 = ldir()
	var ax: Vector3 = tube_axis(clampf(l.x * d.x + l.z * d.z, 0.0, L_END + 2.0))
	return Vector2(l.x - ax.x, l.z - ax.z).length() < 9.0 and absf(l.y - ax.y) < 4.0


static func ldir() -> Vector3:
	return Vector3(cos(deg_to_rad(LDEG)), 0.0, sin(deg_to_rad(LDEG)))


## L'axe du tube du Funiculaire à la distance r du centre (le long de la ligne), en local.
static func tube_axis(r: float) -> Vector3:
	var y: float = AXE_BAS if r < L_FLAT else (AXE_BAS + (r - L_FLAT) * (AXE_HAUT - AXE_BAS) / (L_PORTAL - L_FLAT) if r < L_PORTAL else AXE_HAUT)
	var d: Vector3 = ldir()
	return Vector3(d.x * r, y, d.z * r)


func build(high_quality: bool, soft: Texture2D = null) -> void:
	pc = high_quality
	soft_tex = soft
	_rng.seed = 11500
	var t0: int = Time.get_ticks_msec()
	position = O
	data = Corps.read_bin(BIN)
	if data.is_empty():
		push_warning("V115 : la roche de la Fosse manque (" + BIN + ")")
		return
	_rock()
	_eponges()
	_anemones()
	_lys()
	_gorgones()
	_cailloux()
	_vers()
	_lueurs()
	_cheminee()
	print("ILE_MANGA_V115: la Fosse d'Azur est creusée (%d ms, %d morceaux)" % [Time.get_ticks_msec() - t0, (data.get("parts", []) as Array).size()])


func _rock() -> void:
	rock_mat = ShaderMaterial.new()
	rock_mat.shader = load(SHADER)
	rock_mat.set_shader_parameter("roche_tex", load("res://assets/textures/terrain/rock.jpg"))
	rock_mat.set_shader_parameter("roche_n", load("res://assets/textures/terrain/rock_n.png"))
	if ResourceLoader.exists("res://assets/textures/mer/sable_fond.png"):
		rock_mat.set_shader_parameter("sable_tex", load("res://assets/textures/mer/sable_fond.png"))
		rock_mat.set_shader_parameter("sable_n", load("res://assets/textures/mer/sable_fond_n.png"))
	var k: int = 0
	for part in data.get("parts", []):
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = part["v"]
		arr[Mesh.ARRAY_NORMAL] = part["n"]
		arr[Mesh.ARRAY_COLOR] = part["c"]
		arr[Mesh.ARRAY_INDEX] = part["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.name = "Fosse_%d" % k
		mi.mesh = am
		mi.material_override = rock_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		k += 1


# =================================================================== la vie du fond

func _mm(name: String, mesh: Mesh, xfs: Array, mat: Material = null) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name
	mmi.multimesh = mm
	if mat != null:
		mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _m(key: String) -> Material:
	return load("res://scripts/dome_mats_v115.gd").make(key)


## Un corps de révolution (profil : [[hauteur, rayon], …]), ouvert ou non en haut.
static func _lathe(st: SurfaceTool, prof: Array, seg: int, base := Vector3.ZERO) -> void:
	for i in range(prof.size() - 1):
		var y0: float = prof[i][0]
		var r0: float = prof[i][1]
		var y1: float = prof[i + 1][0]
		var r1: float = prof[i + 1][1]
		for j in range(seg):
			var a0: float = TAU * j / seg
			var a1: float = TAU * (j + 1) / seg
			var p00: Vector3 = base + Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p10: Vector3 = base + Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p11: Vector3 = base + Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var p01: Vector3 = base + Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var n0 := Vector3(cos(a0), (r0 - r1) / maxf(y1 - y0, 0.01), sin(a0)).normalized()
			var n1 := Vector3(cos(a1), (r0 - r1) / maxf(y1 - y0, 0.01), sin(a1)).normalized()
			for v in [[p00, n0, Vector2(0, y0)], [p10, n1, Vector2(1, y0)], [p11, n1, Vector2(1, y1)], [p00, n0, Vector2(0, y0)], [p11, n1, Vector2(1, y1)], [p01, n0, Vector2(0, y1)]]:
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


func _on_floor(p: Vector3, s: float, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), p)


## Un corps de révolution aux UV continus (u : le tour, répété « ru » fois ; v : la hauteur, « rv » par
## mètre), pour les textures (le treillis des éponges de verre, le relief des éponges-tonneaux).
static func _lathe_uv(st: SurfaceTool, prof: Array, seg: int, ru: float, rv: float) -> void:
	for i in range(prof.size() - 1):
		var y0: float = prof[i][0]
		var r0: float = prof[i][1]
		var y1: float = prof[i + 1][0]
		var r1: float = prof[i + 1][1]
		# la normale du profil : (dy, -dr), dehors pour une paroi qui monte, dedans pour une paroi qui
		# redescend (l'intérieur d'un tonneau)
		var n2 := Vector2(y1 - y0, r0 - r1).normalized()
		for j in range(seg):
			var a0: float = TAU * j / seg
			var a1: float = TAU * (j + 1) / seg
			var u0: float = float(j) / seg * ru
			var u1: float = float(j + 1) / seg * ru
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p10 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var p01 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var n0 := Vector3(cos(a0) * n2.x, n2.y, sin(a0) * n2.x).normalized()
			var n1 := Vector3(cos(a1) * n2.x, n2.y, sin(a1) * n2.x).normalized()
			for v in [[p00, n0, Vector2(u0, y0 * rv)], [p10, n1, Vector2(u1, y0 * rv)], [p11, n1, Vector2(u1, y1 * rv)], [p00, n0, Vector2(u0, y0 * rv)], [p11, n1, Vector2(u1, y1 * rv)], [p01, n0, Vector2(u0, y1 * rv)]]:
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


## Les éponges : des corbeilles de verre (de hauts vases ajourés, un treillis de silice d'un blanc
## crème, fermés en haut par un tamis) et des éponges-tonneaux (épaisses, ocre ou jaunes, creuses).
func _eponges() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof: Array = [[0.0, 0.05], [0.12, 0.1], [0.45, 0.16], [0.9, 0.2], [1.3, 0.235], [1.62, 0.275], [1.74, 0.3]]
	_lathe_uv(st, prof, 14, 2.0, 1.15)
	# le tamis du haut
	for j in range(14):
		var a0: float = TAU * j / 14.0
		var a1: float = TAU * (j + 1) / 14.0
		for v in [Vector3.ZERO, Vector3(cos(a0), 0, sin(a0)) * 0.3, Vector3(cos(a1), 0, sin(a1)) * 0.3]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z) * 2.0)
			st.add_vertex(v + Vector3.UP * 1.72)
	var vase: ArrayMesh = st.commit()
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lathe_uv(st2, [[0.0, 0.16], [0.1, 0.3], [0.38, 0.43], [0.72, 0.46], [0.92, 0.41], [0.97, 0.34], [0.93, 0.27], [0.5, 0.22], [0.42, 0.0]], 16, 3.0, 2.0)
	var baril: ArrayMesh = st2.commit()
	var xv: Array = []
	var xb: Array = [[], []]
	for p in data.get("eponges", PackedVector3Array()):
		if _rng.randf() < 0.6:
			var s: float = _rng.randf_range(0.55, 1.35)
			xv.append(_on_floor(p + Vector3.DOWN * 0.1, s, _rng.randf() * TAU))
			if _rng.randf() < 0.5:
				xv.append(_on_floor(p + Vector3(_rng.randf_range(-0.9, 0.9), -0.1, _rng.randf_range(-0.9, 0.9)), s * 0.6, _rng.randf() * TAU))
		else:
			var s2: float = _rng.randf_range(0.6, 1.5)
			var bxf: Transform3D = Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s2, s2 * _rng.randf_range(0.8, 1.3), s2)), p + Vector3.DOWN * 0.12)
			(xb[int(_rng.randf() < 0.35)] as Array).append(bxf)
	_mm("Eponges_de_verre", vase, xv, _m("eponge115"))
	_mm("Eponges_tonneaux", baril, xb[0], _m("eponge115_baril"))
	_mm("Eponges_tonneaux_jaunes", baril, xb[1], _m("eponge115_jaune"))


## Les anémones : un pied court, une couronne de tentacules qui luisent (trois couleurs).
func _anemones() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lathe(st, [[0.0, 0.14], [0.22, 0.12], [0.3, 0.16]], 8)
	for k in range(14):
		var a: float = TAU * k / 14.0
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = Vector3(0, 0.28, 0) + d * 0.12
		var tip: Vector3 = b + d * 0.32 + Vector3.UP * 0.22
		var sd: Vector3 = d.cross(Vector3.UP).normalized() * 0.035
		for v in [b - sd, b + sd, tip, tip, b + sd, b - sd]:
			st.set_normal((d + Vector3.UP).normalized())
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	var by_col: Dictionary = {"violet": [], "rose": [], "cyan": [], "orange": []}
	var cols: Array = by_col.keys()
	for p in data.get("anemones", PackedVector3Array()):
		var c: String = cols[_rng.randi() % cols.size()]
		var n: int = 1 + int(_rng.randf() < 0.5) + int(_rng.randf() < 0.3)
		for i in range(n):
			var o := Vector3(_rng.randf_range(-0.5, 0.5), -0.05, _rng.randf_range(-0.5, 0.5)) if i > 0 else Vector3(0, -0.05, 0)
			(by_col[c] as Array).append(_on_floor(p + o, _rng.randf_range(0.7, 1.5), _rng.randf() * TAU))
	for c2 in by_col:
		if not (by_col[c2] as Array).is_empty():
			_mm("Anemones_" + str(c2), mesh, by_col[c2], _m("anemone115_" + str(c2)))


## Les lys de mer : une longue tige, une couronne de cinq bras plumeux.
func _lys() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lathe(st, [[0.0, 0.04], [1.6, 0.025], [1.7, 0.06]], 5)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var sd: Vector3 = d.cross(Vector3.UP).normalized()
		var p0 := Vector3(0, 1.7, 0)
		var steps: int = 6
		for i in range(steps):
			var t0: float = float(i) / steps
			var t1: float = float(i + 1) / steps
			var q0: Vector3 = p0 + d * (0.55 * t0) + Vector3.UP * (0.35 * sin(t0 * 2.4))
			var q1: Vector3 = p0 + d * (0.55 * t1) + Vector3.UP * (0.35 * sin(t1 * 2.4))
			var w0: float = 0.09 * (1.0 - t0 * 0.6)
			var w1: float = 0.09 * (1.0 - t1 * 0.6)
			for v in [q0 - sd * w0, q0 + sd * w0, q1 + sd * w1, q0 - sd * w0, q1 + sd * w1, q1 - sd * w1]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(0, 0))
				st.add_vertex(v)
	var mesh: ArrayMesh = st.commit()
	var xfs: Array = []
	var xfs2: Array = []
	for p in data.get("lys", PackedVector3Array()):
		var xf: Transform3D = _on_floor(p + Vector3.DOWN * 0.05, _rng.randf_range(0.7, 1.3), _rng.randf() * TAU)
		if _rng.randf() < 0.3:
			xfs2.append(xf)
		else:
			xfs.append(xf)
	_mm("Lys", mesh, xfs, _m("lys115"))
	_mm("Lys_rouges", mesh, xfs2, _m("lys115_rouge"))


## Les gorgones : des éventails de mer (un tronc court, un grand éventail de rameaux en filet, à peine
## bombé), plantés de côté sur les rochers et le bas des parois, face au courant ; violets, jaunes,
## rouges ou orangés.
func _gorgones() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 8
	var ny: int = 4
	var vb: float = 506.0 / 512.0
	var grid: Array = []
	for j in range(ny + 1):
		var row: Array = []
		for i in range(nx + 1):
			var x: float = -1.0 + 2.0 * i / nx
			var y: float = float(j) / ny
			var z: float = 0.12 * x * x + 0.05 * sin(x * 3.0) * y
			row.append([Vector3(x, y, z), Vector2(float(i) / nx, vb * (1.0 - y))])
		grid.append(row)
	for j2 in range(ny):
		for i2 in range(nx):
			var q00: Array = grid[j2][i2]
			var q10: Array = grid[j2][i2 + 1]
			var q11: Array = grid[j2 + 1][i2 + 1]
			var q01: Array = grid[j2 + 1][i2]
			var nrm: Vector3 = ((q01[0] as Vector3) - (q00[0] as Vector3)).cross((q10[0] as Vector3) - (q00[0] as Vector3)).normalized()
			for v in [q00, q10, q11, q00, q11, q01]:
				st.set_normal(nrm)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	# le tronc (une pointe de bois corné, au bas de l'éventail)
	for k in range(6):
		var a0: float = TAU * k / 6.0
		var a1: float = TAU * (k + 1) / 6.0
		var b0 := Vector3(cos(a0) * 0.03, -0.1, sin(a0) * 0.03)
		var b1 := Vector3(cos(a1) * 0.03, -0.1, sin(a1) * 0.03)
		var t0 := Vector3(cos(a0) * 0.016, 0.06, sin(a0) * 0.016)
		var t1 := Vector3(cos(a1) * 0.016, 0.06, sin(a1) * 0.016)
		for v2 in [b0, b1, t1, b0, t1, t0]:
			st.set_normal(Vector3(v2.x, 0, v2.z).normalized())
			st.set_uv(Vector2(0.5, 0.97))
			st.add_vertex(v2)
	var mesh: ArrayMesh = st.commit()
	var pts: PackedVector3Array = data.get("gorgones", PackedVector3Array())
	var nrms: PackedVector3Array = data.get("gorgones_n", PackedVector3Array())
	var by_col: Dictionary = {"": [], "jaune": [], "rouge": [], "orange": []}
	var cols: Array = by_col.keys()
	for i in range(mini(pts.size(), nrms.size())):
		var n: Vector3 = nrms[i]
		var flat := Vector3(n.x, 0, n.z)
		if flat.length() < 0.05:
			flat = Vector3.FORWARD
		flat = flat.normalized()
		# l'éventail pousse droit (un peu penché vers le large), son plan perpendiculaire à la paroi
		var bs := Basis.looking_at(flat.cross(Vector3.UP), Vector3.UP).rotated(flat, _rng.randf_range(-0.2, 0.2))
		var s2: float = _rng.randf_range(0.7, 1.7)
		var xf := Transform3D(bs.scaled(Vector3(s2, s2 * _rng.randf_range(0.85, 1.15), s2)), pts[i] - n * 0.05 + flat * 0.15 * s2)
		(by_col[cols[_rng.randi() % cols.size()]] as Array).append(xf)
	for c in by_col:
		if not (by_col[c] as Array).is_empty():
			_mm("Gorgones_" + str(c), mesh, by_col[c], _m("gorgone115" + ("" if str(c) == "" else "_" + str(c))))


## Des cailloux (gris-bleu) sur le sable.
func _cailloux() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 0.62
	sm.radial_segments = 8
	sm.rings = 4
	var arrs: Array = sm.get_mesh_arrays()
	var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	var r := RandomNumberGenerator.new()
	r.seed = 1158
	for i in range(vs.size()):
		vs[i] = vs[i] * (1.0 + r.randf_range(-0.22, 0.18))
	arrs[Mesh.ARRAY_VERTEX] = vs
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrs)
	var xfs: Array = []
	for p in data.get("cailloux", PackedVector3Array()):
		var s: float = _rng.randf_range(0.12, 0.75)
		var b := Basis(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf() * TAU)
		xfs.append(Transform3D(b.scaled(Vector3(s, s * _rng.randf_range(0.5, 0.9), s)), p + Vector3.DOWN * s * 0.15))
	_mm("Cailloux", am, xfs, _m("roche115"))


## Les vers géants de la cheminée : des tubes blancs, un panache rouge.
func _vers() -> void:
	var tube := SurfaceTool.new()
	tube.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lathe(tube, [[0.0, 0.07], [1.6, 0.06], [1.62, 0.075]], 6)
	var plume := SurfaceTool.new()
	plume.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lathe(plume, [[1.58, 0.05], [1.75, 0.12], [1.95, 0.08], [2.05, 0.0]], 8)
	var am: ArrayMesh = tube.commit()
	plume.commit(am)
	am.surface_set_material(0, _m("ver115"))
	am.surface_set_material(1, _m("ver115_rouge"))
	var xfs: Array = []
	for p in data.get("vers", PackedVector3Array()):
		var n: int = 4 + _rng.randi() % 6
		for i in range(n):
			var o := Vector3(_rng.randf_range(-0.6, 0.6), -0.05, _rng.randf_range(-0.6, 0.6))
			var s: float = _rng.randf_range(0.5, 1.2)
			var lean := Basis(Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(0.0, 0.18))
			xfs.append(Transform3D(lean.scaled(Vector3(1.0, s, 1.0)), p + o))
	_mm("Vers_geants", am, xfs)


## Les lueurs : sur les parois, dans la Faille, aux flancs des rochers, des grappes de petites bêtes qui
## luisent (bioluminescence : bleu, aigue-marine, violet, vert) ; dans le noir de l'eau, on les voit de
## loin, comme des étoiles qui descendent dans la Fosse.
func _lueurs() -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 5
	sm.rings = 2
	var pts: PackedVector3Array = data.get("lueurs", PackedVector3Array())
	var nrms: PackedVector3Array = data.get("lueurs_n", PackedVector3Array())
	var by_col: Dictionary = {"bleu": [], "cyan": [], "violet": [], "vert": []}
	var cols: Array = by_col.keys()
	for i in range(mini(pts.size(), nrms.size())):
		if not pc and i % 2 == 1:
			continue
		var n: Vector3 = nrms[i]
		var c: String = cols[_rng.randi() % cols.size()]
		var tan: Vector3 = n.cross(Vector3.UP)
		if tan.length() < 0.1:
			tan = Vector3.RIGHT
		tan = tan.normalized()
		var bit: Vector3 = n.cross(tan).normalized()
		var nb: int = (2 + _rng.randi() % 5) if pc else (1 + _rng.randi() % 3)
		for k in range(nb):
			var o: Vector3 = tan * _rng.randf_range(-0.7, 0.7) + bit * _rng.randf_range(-0.7, 0.7) + n * 0.08
			(by_col[c] as Array).append(Transform3D(Basis().scaled(Vector3.ONE * _rng.randf_range(0.4, 1.3)), pts[i] + o))
	for c2 in by_col:
		if not (by_col[c2] as Array).is_empty():
			_mm("Lueurs_" + str(c2), sm, by_col[c2], _m("lueur115_" + str(c2)))


## La cheminée hydrothermale : la fumée noire qui monte de ses évents (dessinée après le verre, déjà
## noyée de bleu), une lueur de rouille au pied.
func _cheminee() -> void:
	var top := Vector3(VENT.x, VENT_H - 1.0, VENT.y)
	for ev in [[top, 1.0], [Vector3(VENT.x + 5.0, 6.0, VENT.y + 2.0), 0.6], [Vector3(VENT.x - 3.5, 8.5, VENT.y + 4.0), 0.7]]:
		var p := CPUParticles3D.new()
		p.name = "Fumee_noire"
		p.amount = 26 if pc else 12
		p.lifetime = 7.0
		p.direction = Vector3.UP
		p.spread = 8.0
		p.initial_velocity_min = 1.0
		p.initial_velocity_max = 1.8
		p.gravity = Vector3(0.15, 0.25, 0.05)
		p.scale_amount_min = 0.8 * float(ev[1])
		p.scale_amount_max = 1.8 * float(ev[1])
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 0.4))
		curve.add_point(Vector2(1.0, 2.6))
		p.scale_amount_curve = curve
		var grad := Gradient.new()
		grad.set_color(0, Color(0.05, 0.06, 0.07, 0.6))
		grad.set_color(1, Color(0.03, 0.08, 0.12, 0.0))
		p.color_ramp = grad
		var qm := QuadMesh.new()
		qm.size = Vector2(1.2, 1.2)
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
		m.vertex_color_use_as_albedo = true
		m.render_priority = 2
		m.albedo_texture = soft_tex
		qm.material = m
		p.mesh = qm
		p.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 28, 12))
		add_child(p)
		p.position = ev[0]
		smoke.append(p)
	var l := OmniLight3D.new()
	l.name = "Lueur_cheminee"
	l.light_color = Color(1.0, 0.45, 0.2)
	l.light_energy = 1.4
	l.omni_range = 12.0
	l.shadow_enabled = false
	add_child(l)
	l.position = Vector3(VENT.x, 1.0, VENT.y + 5.0)

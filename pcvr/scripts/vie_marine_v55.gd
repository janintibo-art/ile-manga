extends Node3D
## V55 : la vie sous-marine.
##  - des bancs de poissons (sardines, chirurgiens, demoiselles, poissons-anges, mérous,
##    poissons-perroquets, rougets, poissons-clowns) qui tournent autour des récifs et
##    s'écartent quand on passe au milieu (MultiMesh : un seul appel de dessin par banc) ;
##  - des tortues de mer, deux raies mantas, un groupe de dauphins qui sautent près du
##    village, et une baleine à bosse qui fait le tour de la mer en chantant ;
##  - le danger : les requins du Jardin de corail et de l'épave (ils tournent, s'approchent,
##    foncent et mordent ; on les frappe au dernier moment) et les méduses de la fosse (elles
##    piquent si on les frôle).
## Les requins et les méduses ne s'en prennent qu'au nageur (jamais sous le dôme).

const Fond = preload("res://scripts/fond_marin_v55.gd")
const CibleScript = preload("res://scripts/cible_v54.gd")
const SEA_Y: float = -0.42
const NEAR: float = 85.0              # au-delà, les bancs et les bêtes ne bougent plus
const ATL := Vector3(-220.0, -30.0, 260.0)

var main: Node
var mer: Node                         # mer_v55.gd
var schools: Array = []               # {mmi, anchor, n, offsets, species, radius, speed, t, sizes, depth}
var turtles: Array = []
var mantas: Array = []
var dolphins: Array = []
var whale: Dictionary = {}
var sharks: Array = []
var jellies: Array = []
var _fish_mesh: ArrayMesh
var _fish_mat: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _sting_cool: float = 0.0
var kills: int = 0                    # requins vaincus (pour les tests et les dialogues)
var stings: int = 0
var bites: int = 0


func build(main_node: Node, mer_node: Node) -> void:
	main = main_node
	mer = mer_node
	name = "Vie_marine_v55"
	_rng.seed = 5503
	var t0: int = Time.get_ticks_msec()
	_fish_mesh = _make_fish_mesh()
	_fish_mat = ShaderMaterial.new()
	_fish_mat.shader = load("res://shaders/poisson_v55.gdshader")
	if ResourceLoader.exists("res://assets/textures/mer/poissons.png"):
		_fish_mat.set_shader_parameter("atlas", load("res://assets/textures/mer/poissons.png"))
	_build_schools()
	_build_turtles()
	_build_mantas()
	_build_dolphins()
	_build_whale()
	_build_sharks()
	_build_jellies()
	print("ILE_MANGA_V55: vie marine (%d bancs, %d requins, %d méduses) en %d ms" % [schools.size(), sharks.size(), jellies.size(), Time.get_ticks_msec() - t0])


# =================================================================== maillages

## Poisson : une carte de profil (la silhouette et les nageoires viennent de l'alpha) et un
## corps en lentille. Longueur 1 (museau en -Z), UV de la case de l'atlas.
func _make_fish_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var H: float = 0.6
	var uv_of := func(z: float, y: float) -> Vector2:
		return Vector2(0.02 + (0.5 + z) * 0.83, 0.5 - y / H)
	# la carte (un seul plan, vu des deux côtés)
	var quad := [Vector3(0, H * 0.5, 0.5), Vector3(0, H * 0.5, -0.5), Vector3(0, -H * 0.5, 0.5), Vector3(0, -H * 0.5, -0.5)]
	for k in [0, 1, 2, 2, 1, 3]:
		st.set_normal(Vector3.RIGHT)
		st.set_uv(uv_of.call(quad[k].z, quad[k].y))
		st.add_vertex(quad[k])
	# le corps : lentille entre la queue (z = 0.4) et le museau (z = -0.4)
	var rows: int = 10
	var segs: int = 10
	for i in range(rows):
		for j in range(segs):
			var pts: Array = []
			for di in [0, 1]:
				for dj in [0, 1]:
					var t: float = float(i + di) / rows
					var z: float = lerpf(0.36, -0.42, t)
					var prof: float = sin(PI * clampf(t, 0.0, 1.0)) * 0.9 + 0.1 * (1.0 - t)
					var a: float = TAU * float(j + dj) / segs
					var y: float = cos(a) * 0.105 * prof
					var x: float = sin(a) * 0.045 * prof
					pts.append([Vector3(x, y, z), Vector3(sin(a), cos(a) * 0.6, 0).normalized()])
			for k in [0, 2, 1, 1, 2, 3]:
				st.set_normal(pts[k][1])
				st.set_uv(uv_of.call(pts[k][0].z, pts[k][0].y))
				st.add_vertex(pts[k][0])
	return st.commit()


## Corps de révolution (museau en -Z). profile : [[t (0 museau .. 1 queue), rayon_y, rayon_x], …]
func _body_mesh(length: float, profile: Array, top: Color, belly: Color, segs: int = 16) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for p in profile:
		var ring: Array = []
		var z: float = (float(p[0]) - 0.5) * length
		for j in range(segs + 1):
			var a: float = TAU * j / segs
			var nrm := Vector3(sin(a) * float(p[1]) / maxf(float(p[2]), 0.001), cos(a), 0.0).normalized()
			var pos := Vector3(sin(a) * float(p[2]), cos(a) * float(p[1]), z)
			var k: float = smoothstep(-0.35, 0.25, cos(a))
			ring.append([pos, nrm, belly.lerp(top, k)])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for j in range(segs):
			var q := [rings[i][j], rings[i][j + 1], rings[i + 1][j], rings[i + 1][j + 1]]
			for k2 in [0, 2, 1, 1, 2, 3]:
				st.set_normal(q[k2][1])
				st.set_color(q[k2][2])
				st.add_vertex(q[k2][0])
	return st


## Nageoire plate (les deux faces), triangle ou quadrilatère.
func _fin(st: SurfaceTool, pts: Array, col: Color) -> void:
	var n: Vector3 = (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()
	var tris: Array = [[0, 1, 2]]
	if pts.size() == 4:
		tris.append([0, 2, 3])
	for t in tris:
		for side in [1.0, -1.0]:
			var order: Array = t if side > 0 else [t[0], t[2], t[1]]
			for k in order:
				st.set_normal(n * side)
				st.set_color(col)
				st.add_vertex(pts[k])


func _swimmer_mat(len_m: float, axis: float, amp: float, freq: float, rough: float = 0.45) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/nageur_v55.gdshader")
	m.set_shader_parameter("length_m", len_m)
	m.set_shader_parameter("axis", axis)
	m.set_shader_parameter("amplitude", amp)
	m.set_shader_parameter("freq", freq)
	m.set_shader_parameter("phase", _rng.randf() * TAU)
	m.set_shader_parameter("roughness_v", rough)
	return m


func _eyes(parent: Node3D, z: float, x: float, y: float, r: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.04)
	m.roughness = 0.1
	for sx in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		e.mesh = sm
		e.material_override = m
		e.position = Vector3(sx * x, y, z)
		parent.add_child(e)


func _shark_mesh() -> ArrayMesh:
	var L: float = 2.6
	var top := Color(0.36, 0.4, 0.45)
	var belly := Color(0.88, 0.88, 0.86)
	var st := _body_mesh(L, [[0.0, 0.02, 0.02], [0.04, 0.1, 0.09], [0.12, 0.19, 0.17], [0.25, 0.25, 0.22], [0.4, 0.26, 0.22],
		[0.55, 0.21, 0.17], [0.7, 0.13, 0.1], [0.85, 0.07, 0.05], [0.95, 0.05, 0.035], [1.0, 0.03, 0.02]], top, belly, 14)
	var z := func(t: float) -> float: return (t - 0.5) * L
	# aileron dorsal
	_fin(st, [Vector3(0, 0.22, z.call(0.33)), Vector3(0, 0.68, z.call(0.47)), Vector3(0, 0.2, z.call(0.52))], top)
	# pectorales
	for sx in [-1.0, 1.0]:
		_fin(st, [Vector3(sx * 0.18, -0.08, z.call(0.25)), Vector3(sx * 0.75, -0.3, z.call(0.42)), Vector3(sx * 0.16, -0.1, z.call(0.36))], top.darkened(0.1))
	# petit dorsal et anal
	_fin(st, [Vector3(0, 0.09, z.call(0.78)), Vector3(0, 0.22, z.call(0.83)), Vector3(0, 0.07, z.call(0.86))], top)
	_fin(st, [Vector3(0, -0.08, z.call(0.76)), Vector3(0, -0.2, z.call(0.82)), Vector3(0, -0.06, z.call(0.85))], belly)
	# la queue en croissant (lobe du haut plus long)
	_fin(st, [Vector3(0, 0.02, z.call(0.96)), Vector3(0, 0.62, z.call(1.14)), Vector3(0, 0.45, z.call(1.08)), Vector3(0, 0.0, z.call(1.0))], top)
	_fin(st, [Vector3(0, -0.02, z.call(0.96)), Vector3(0, -0.36, z.call(1.08)), Vector3(0, 0.0, z.call(1.02))], top)
	return st.commit()


func _dolphin_mesh() -> ArrayMesh:
	var L: float = 2.3
	var top := Color(0.42, 0.47, 0.53)
	var belly := Color(0.84, 0.86, 0.88)
	var st := _body_mesh(L, [[0.0, 0.03, 0.03], [0.05, 0.05, 0.05], [0.09, 0.06, 0.06], [0.12, 0.14, 0.13], [0.2, 0.2, 0.18], [0.35, 0.24, 0.21],
		[0.5, 0.22, 0.19], [0.65, 0.16, 0.13], [0.8, 0.09, 0.07], [0.93, 0.05, 0.04], [1.0, 0.03, 0.03]], top, belly, 14)
	var z := func(t: float) -> float: return (t - 0.5) * L
	_fin(st, [Vector3(0, 0.22, z.call(0.4)), Vector3(0, 0.5, z.call(0.55)), Vector3(0, 0.18, z.call(0.58))], top)
	for sx in [-1.0, 1.0]:
		_fin(st, [Vector3(sx * 0.15, -0.1, z.call(0.25)), Vector3(sx * 0.42, -0.25, z.call(0.38)), Vector3(sx * 0.13, -0.12, z.call(0.33))], top)
		# nageoire caudale horizontale
		_fin(st, [Vector3(0, 0, z.call(0.96)), Vector3(sx * 0.42, 0.0, z.call(1.1)), Vector3(sx * 0.3, 0.0, z.call(1.13)), Vector3(0, 0, z.call(1.04))], top)
	return st.commit()


func _whale_mesh() -> ArrayMesh:
	var L: float = 14.0
	var top := Color(0.13, 0.15, 0.19)
	var belly := Color(0.78, 0.8, 0.8)
	var st := _body_mesh(L, [[0.0, 0.25, 0.5], [0.04, 0.7, 0.9], [0.1, 1.15, 1.2], [0.2, 1.45, 1.35], [0.35, 1.5, 1.35], [0.5, 1.3, 1.15],
		[0.65, 0.95, 0.8], [0.8, 0.55, 0.45], [0.92, 0.3, 0.24], [1.0, 0.18, 0.14]], top, belly, 18)
	var z := func(t: float) -> float: return (t - 0.5) * L
	# longues pectorales blanches (baleine à bosse)
	for sx in [-1.0, 1.0]:
		_fin(st, [Vector3(sx * 1.1, -0.6, z.call(0.24)), Vector3(sx * 4.6, -1.6, z.call(0.42)), Vector3(sx * 4.4, -1.7, z.call(0.47)), Vector3(sx * 1.0, -0.7, z.call(0.33))], Color(0.85, 0.86, 0.86))
		_fin(st, [Vector3(0, 0, z.call(0.97)), Vector3(sx * 2.4, 0.2, z.call(1.08)), Vector3(sx * 2.0, 0.1, z.call(1.13)), Vector3(0, 0, z.call(1.04))], top)
	_fin(st, [Vector3(0, 1.0, z.call(0.62)), Vector3(0, 1.4, z.call(0.68)), Vector3(0, 0.9, z.call(0.7))], top)
	return st.commit()


# =================================================================== bancs

func _add_school(anchor: Vector3, species: int, n: int, radius: float, size: float, roam: float = 14.0, speed: float = 1.0) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _fish_mesh
	mm.instance_count = n
	var offsets: Array = []
	var sizes: Array = []
	for i in range(n):
		var o := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-1, 1)).normalized() * pow(_rng.randf(), 0.5) * radius
		offsets.append(o)
		sizes.append(size * _rng.randf_range(0.8, 1.2))
		mm.set_instance_custom_data(i, Color(_rng.randf(), (species + 0.0) / 8.0, _rng.randf_range(0.6, 1.1), 0.0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size), anchor + o))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Banc_%d" % schools.size()
	mmi.multimesh = mm
	mmi.material_override = _fish_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# Ne jamais sortir de l'eau ni passer sous le fond
	var floor_y: float = Fond.height(anchor.x, anchor.z)
	anchor.y = clampf(anchor.y, floor_y + radius * 0.6 + 1.0, SEA_Y - radius * 0.6 - 1.0)
	schools.append({"mmi": mmi, "anchor": anchor, "n": n, "offsets": offsets, "sizes": sizes, "radius": radius, "roam": roam,
		"speed": speed, "t": _rng.randf() * 100.0, "w1": _rng.randf_range(0.04, 0.08) * speed, "w2": _rng.randf_range(0.05, 0.11),
		"species": species, "pos": anchor, "scatter": PackedVector3Array(), "awake": true})
	var sc: PackedVector3Array = schools[-1]["scatter"]
	sc.resize(n)
	schools[-1]["scatter"] = sc


func _build_schools() -> void:
	var R: Vector3 = Vector3(-150.0, -17.0, 205.0)
	_add_school(Vector3(-45, -6, 88), 3, 60, 4.0, 0.22, 16.0, 1.2)
	_add_school(Vector3(72, -7, 70), 1, 20, 3.0, 0.3, 10.0)
	_add_school(Vector3(-92, -6, 40), 2, 24, 2.6, 0.18, 8.0)
	_add_school(Vector3(38, -8, -128), 4, 14, 2.4, 0.32, 10.0)
	_add_school(Vector3(-120, -6, -235), 6, 15, 2.6, 0.35, 12.0)
	_add_school(Vector3(110, -7, -205), 3, 45, 3.6, 0.22, 16.0, 1.2)
	_add_school(Vector3(0, -6, -520), 2, 20, 2.4, 0.18, 8.0)
	_add_school(Vector3(450, -7, -205), 1, 18, 2.8, 0.3, 10.0)
	_add_school(Vector3(-450, -7, -120), 7, 16, 2.6, 0.26, 10.0)
	# Le Jardin de corail
	_add_school(R + Vector3(6, 2, -4), 2, 30, 3.0, 0.18, 10.0)
	_add_school(R + Vector3(-10, 0, 8), 4, 12, 2.4, 0.32, 9.0)
	_add_school(R + Vector3(4, 1, 14), 1, 18, 2.8, 0.3, 10.0)
	_add_school(R + Vector3(-4, -6, -14), 5, 3, 1.6, 0.9, 6.0, 0.5)
	for k in range(6):
		var a: float = TAU * k / 6.0
		var p: Vector3 = R + Vector3(cos(a) * _rng.randf_range(6.0, 16.0), 0, sin(a) * _rng.randf_range(6.0, 16.0))
		p.y = Fond.height(p.x, p.z) + 0.9
		_add_school(p, 0, 2, 0.4, 0.14, 0.6, 0.8)
	# Autour de l'Atlantide, de l'épave, sous les chutes de l'île flottante
	_add_school(ATL + Vector3(0, 12, 70), 3, 60, 5.0, 0.22, 20.0, 1.3)
	_add_school(ATL + Vector3(60, 8, -30), 6, 12, 2.6, 0.35, 12.0)
	_add_school(ATL + Vector3(-70, 6, 20), 7, 14, 2.4, 0.26, 10.0)
	_add_school(Vector3(-300, -25, 330), 5, 3, 1.6, 0.9, 6.0, 0.5)
	_add_school(Vector3(-292, -24, 340), 7, 12, 2.2, 0.26, 8.0)
	_add_school(Vector3(40, -6, 400), 3, 30, 3.2, 0.22, 14.0, 1.2)


func _tick_schools(delta: float, eye: Vector3, player: Vector3) -> void:
	for s in schools:
		var anchor: Vector3 = s["anchor"]
		var far: bool = eye.distance_to(anchor) > NEAR + float(s["roam"])
		var mmi: MultiMeshInstance3D = s["mmi"]
		mmi.visible = not far
		if far:
			continue
		s["t"] = float(s["t"]) + delta
		var t: float = s["t"]
		var roam: float = s["roam"]
		var w1: float = s["w1"]
		var w2: float = s["w2"]
		var c: Vector3 = anchor + Vector3(sin(t * w1 * TAU) * roam, sin(t * w2 * TAU) * roam * 0.12, cos(t * w1 * TAU * 0.8) * roam * 0.7)
		var vel := Vector3(cos(t * w1 * TAU) * roam * w1 * TAU, cos(t * w2 * TAU) * roam * 0.12 * w2 * TAU, -sin(t * w1 * TAU * 0.8) * roam * 0.7 * w1 * TAU * 0.8)
		var heading: Vector3 = vel.normalized() if vel.length() > 0.01 else Vector3.FORWARD
		var turn := Basis.looking_at(heading, Vector3.UP)
		var mm: MultiMesh = mmi.multimesh
		var offs: Array = s["offsets"]
		var sizes: Array = s["sizes"]
		var sc: PackedVector3Array = s["scatter"]
		var floor_y: float = Fond.height(c.x, c.z)
		for i in range(int(s["n"])):
			var o: Vector3 = offs[i]
			var wob := Vector3(sin(t * 0.7 + i) * 0.3, sin(t * 0.9 + i * 1.7) * 0.2, cos(t * 0.6 + i * 0.5) * 0.3)
			var p: Vector3 = c + turn * (o + wob)
			# fuite : le banc s'ouvre autour du nageur
			var away: Vector3 = p - player
			var d: float = away.length()
			var push: Vector3 = sc[i]
			if d < 3.5 and d > 0.01:
				push = push.lerp(away / d * (3.5 - d) * 1.6, clampf(delta * 6.0, 0.0, 1.0))
			else:
				push = push.lerp(Vector3.ZERO, clampf(delta * 0.8, 0.0, 1.0))
			sc[i] = push
			p += push
			p.y = clampf(p.y, floor_y + 0.4, SEA_Y - 0.5)
			var dir: Vector3 = (heading + push * 0.25).normalized()
			mm.set_instance_transform(i, Transform3D(Basis.looking_at(dir, Vector3.UP).scaled(Vector3.ONE * float(sizes[i])), p))
		s["scatter"] = sc
		s["pos"] = c


# =================================================================== tortues, raies, dauphins, baleine

func _build_turtles() -> void:
	var shell_m := StandardMaterial3D.new()
	if ResourceLoader.exists("res://assets/textures/mer/carapace.png"):
		shell_m.albedo_texture = load("res://assets/textures/mer/carapace.png")
	shell_m.roughness = 0.5
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.45, 0.5, 0.36)
	skin.roughness = 0.75
	var plast := StandardMaterial3D.new()
	plast.albedo_color = Color(0.82, 0.76, 0.55)
	for c in [Vector3(-70, -7, 120), Vector3(-160, -14, 190), Vector3(90, -8, -60), Vector3(-260, -18, 230)]:
		var root := Node3D.new()
		root.name = "Tortue_v55"
		add_child(root)
		var body := Node3D.new()
		root.add_child(body)
		var sm := SphereMesh.new()
		sm.radius = 0.55
		sm.height = 1.1
		var shell := MeshInstance3D.new()
		shell.mesh = sm
		shell.material_override = shell_m
		shell.scale = Vector3(1.0, 0.38, 1.25)
		body.add_child(shell)
		var under := MeshInstance3D.new()
		under.mesh = sm
		under.material_override = plast
		under.scale = Vector3(0.92, 0.22, 1.15)
		under.position.y = -0.06
		body.add_child(under)
		var head := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.14
		hs.height = 0.28
		head.mesh = hs
		head.material_override = skin
		head.scale = Vector3(1.0, 0.85, 1.4)
		head.position = Vector3(0, 0.02, -0.78)
		body.add_child(head)
		_eyes(body, -0.86, 0.09, 0.07, 0.025)
		var flippers: Array = []
		for f in [[-1.0, -0.38, 0.75], [1.0, -0.38, 0.75], [-1.0, 0.5, 0.35], [1.0, 0.5, 0.35]]:
			var pivot := Node3D.new()
			pivot.position = Vector3(float(f[0]) * 0.45, -0.02, float(f[1]))
			body.add_child(pivot)
			var fl := MeshInstance3D.new()
			var fs := SphereMesh.new()
			fs.radius = 0.5
			fs.height = 1.0
			fl.mesh = fs
			fl.material_override = skin
			fl.scale = Vector3(float(f[2]), 0.05, float(f[2]) * 0.38)
			fl.position = Vector3(float(f[0]) * float(f[2]) * 0.45, 0, 0.08)
			fl.rotation.y = float(f[0]) * -0.35
			pivot.add_child(fl)
			flippers.append([pivot, float(f[0]), float(f[1]) < 0.0])
		var y: float = clampf(c.y, Fond.height(c.x, c.z) + 2.0, SEA_Y - 1.5)
		turtles.append({"node": root, "body": body, "center": Vector3(c.x, y, c.z), "r": _rng.randf_range(10.0, 22.0), "t": _rng.randf() * 100.0, "w": _rng.randf_range(0.012, 0.02), "flippers": flippers})


func _tick_turtles(delta: float, eye: Vector3) -> void:
	for tt in turtles:
		var node: Node3D = tt["node"]
		var cpos: Vector3 = tt["center"]
		node.visible = eye.distance_to(cpos) < NEAR + 30.0
		if not node.visible:
			continue
		tt["t"] = float(tt["t"]) + delta
		var t: float = tt["t"]
		var a: float = t * float(tt["w"]) * TAU
		var r: float = tt["r"]
		var p := cpos + Vector3(cos(a) * r, sin(t * 0.13) * 1.5, sin(a) * r)
		p.y = clampf(maxf(p.y, Fond.height(p.x, p.z) + 1.6), -40.0, SEA_Y - 1.2)
		var dir := Vector3(-sin(a), 0.02, cos(a))
		node.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), p)
		var body: Node3D = tt["body"]
		body.rotation.z = sin(t * 0.8) * 0.06
		for f in tt["flippers"]:
			var pv: Node3D = f[0]
			var side: float = f[1]
			var front: bool = f[2]
			var beat: float = sin(t * (1.3 if front else 1.3) + (0.0 if front else 1.2))
			pv.rotation.z = side * beat * (0.55 if front else 0.25)
			pv.rotation.x = beat * (0.25 if front else 0.1)


func _manta_mat() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float half_span = 2.0;
void vertex() {
	float k = clamp(abs(VERTEX.x) / half_span, 0.0, 1.0);
	VERTEX.y += sin(TIME * 1.25 - k * 1.6) * pow(k, 1.4) * 0.75;
	VERTEX.y += sin(TIME * 1.25 - VERTEX.z * 0.8) * 0.06;
}
void fragment() {
	vec3 top = vec3(0.08, 0.09, 0.12);
	vec3 belly = vec3(0.85, 0.86, 0.84);
	ALBEDO = FRONT_FACING ? top : belly;
	EMISSION = FRONT_FACING ? vec3(0.0) : vec3(0.32, 0.36, 0.38);
	ROUGHNESS = 0.5;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _manta_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span: float = 2.0
	var cols: int = 16
	var rows: int = 8
	var grid: Array = []
	for i in range(rows + 1):
		var row: Array = []
		var z: float = lerpf(-0.9, 1.0, float(i) / rows)
		for j in range(cols + 1):
			var u: float = lerpf(-1.0, 1.0, float(j) / cols)
			# contour en losange arrondi, ailes pointues vers l'arrière
			var half: float = span * (1.0 - pow(absf(z - 0.05) / 0.98, 1.6)) * (0.55 + 0.45 * (1.0 - absf(z + 0.2)))
			var x: float = u * maxf(half, 0.12)
			var y: float = 0.12 * (1.0 - absf(u)) * (1.0 - absf(z))
			row.append(Vector3(x, y, z))
		grid.append(row)
	for i in range(rows):
		for j in range(cols):
			var q := [grid[i][j], grid[i][j + 1], grid[i + 1][j], grid[i + 1][j + 1]]
			for k in [0, 1, 2, 2, 1, 3]:
				st.set_normal(Vector3.UP)
				st.add_vertex(q[k])
	# queue
	for p in [Vector3(-0.03, 0, 1.0), Vector3(0.03, 0, 1.0), Vector3(0, 0, 2.6)]:
		st.set_normal(Vector3.UP)
		st.add_vertex(p)
	# lobes céphaliques
	for sx in [-1.0, 1.0]:
		for p2 in [Vector3(sx * 0.3, 0.02, -0.85), Vector3(sx * 0.42, 0.0, -1.2), Vector3(sx * 0.5, 0.0, -0.8)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(p2)
	return st.commit()


func _build_mantas() -> void:
	var mesh := _manta_mesh()
	var mat := _manta_mat()
	for c in [Vector3(-120, -10, 150), Vector3(-230, -16, 300)]:
		var mi := MeshInstance3D.new()
		mi.name = "Raie_manta_v55"
		mi.mesh = mesh
		mi.material_override = mat
		mi.scale = Vector3.ONE * 1.6
		add_child(mi)
		mantas.append({"node": mi, "center": c, "r": _rng.randf_range(25.0, 40.0), "t": _rng.randf() * 100.0, "w": 0.01})


func _tick_mantas(delta: float, eye: Vector3) -> void:
	for m in mantas:
		var node: Node3D = m["node"]
		var c: Vector3 = m["center"]
		node.visible = eye.distance_to(c) < NEAR + 45.0
		if not node.visible:
			continue
		m["t"] = float(m["t"]) + delta
		var t: float = m["t"]
		var a: float = t * float(m["w"]) * TAU
		var r: float = m["r"]
		var p := c + Vector3(cos(a) * r, sin(t * 0.1) * 2.0, sin(a * 1.3) * r * 0.8)
		p.y = clampf(maxf(p.y, Fond.height(p.x, p.z) + 3.0), -40.0, SEA_Y - 1.5)
		var dir := Vector3(-sin(a) * r, cos(t * 0.1) * 0.2, cos(a * 1.3) * r * 1.3 * 0.8).normalized()
		var b := Basis.looking_at(dir, Vector3.UP)
		b = b.rotated(dir, sin(t * 0.3) * 0.15)
		node.global_transform = Transform3D(b.scaled(Vector3.ONE * 1.6), p)


func _build_dolphins() -> void:
	var mesh := _dolphin_mesh()
	for k in range(3):
		var mi := MeshInstance3D.new()
		mi.name = "Dauphin_v55_%d" % k
		mi.mesh = mesh
		mi.material_override = _swimmer_mat(2.3, 1.0, 0.07, 1.6, 0.3)
		add_child(mi)
		_eyes(mi, -0.85, 0.11, 0.06, 0.02)
		dolphins.append({"node": mi, "lane": Vector3(k * 2.4 - 2.4, 0, k * 1.6), "t": k * 0.7, "leap": -1.0, "next": _rng.randf_range(4.0, 9.0), "speed": 6.0})


func _tick_dolphins(delta: float, eye: Vector3) -> void:
	var center := Vector3(0, 0, 30)
	var R: float = 140.0
	for d in dolphins:
		var node: Node3D = d["node"]
		d["t"] = float(d["t"]) + delta
		var t: float = d["t"]
		var a: float = t * 6.0 / R
		var lane: Vector3 = d["lane"]
		var path := center + Vector3(cos(a) * (R + lane.x), 0, sin(a) * (R + lane.x) * 0.9)
		var dir := Vector3(-sin(a), 0, cos(a) * 0.9).normalized()
		var y: float = SEA_Y - 1.6 + sin(t * 0.9 + lane.z) * 0.6
		# bond hors de l'eau, de temps en temps
		d["next"] = float(d["next"]) - delta
		var leap: float = d["leap"]
		if leap < 0.0 and float(d["next"]) <= 0.0 and eye.distance_to(path) < 160.0:
			leap = 0.0
			d["next"] = _rng.randf_range(5.0, 12.0)
			if eye.distance_to(path) < 60.0 and main.has_method("sfx"):
				main.sfx("dauphin", path + Vector3.UP, -4.0)
		var pitch: float = 0.0
		if leap >= 0.0:
			leap += delta / 1.5
			var arc: float = sin(leap * PI)
			y = SEA_Y - 1.0 + arc * 3.2
			pitch = cos(leap * PI) * 0.8
			if leap >= 1.0:
				leap = -1.0
				if mer != null and mer.has_method("splash"):
					mer.splash(Vector3(path.x, SEA_Y, path.z), 1.0)
		d["leap"] = leap
		node.visible = eye.distance_to(path) < 200.0
		if not node.visible:
			continue
		var b := Basis.looking_at(dir, Vector3.UP)
		b = b.rotated(b.x, pitch)
		node.global_transform = Transform3D(b, Vector3(path.x, y, path.z))


func _build_whale() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Baleine_v55"
	mi.mesh = _whale_mesh()
	mi.material_override = _swimmer_mat(14.0, 1.0, 0.04, 0.22, 0.5)
	add_child(mi)
	_eyes(mi, -4.8, 1.05, -0.3, 0.09)
	var song := AudioStreamPlayer3D.new()
	song.name = "Chant_baleine"
	song.bus = "Bruitages"
	song.unit_size = 60.0
	song.max_distance = 320.0
	song.max_db = 0.0
	mi.add_child(song)
	whale = {"node": mi, "song": song, "t": 0.0, "next_song": 8.0, "center": Vector3(-60, -16, 160), "R": 230.0}


func _tick_whale(delta: float, eye: Vector3, underwater: bool) -> void:
	if whale.is_empty():
		return
	var node: Node3D = whale["node"]
	whale["t"] = float(whale["t"]) + delta
	var t: float = whale["t"]
	var R: float = whale["R"]
	var a: float = t * 2.2 / R
	var c: Vector3 = whale["center"]
	var p := c + Vector3(cos(a) * R, sin(t * 0.03) * 4.0, sin(a) * R * 0.75)
	p.y = minf(p.y, SEA_Y - 3.0)
	p.y = maxf(p.y, Fond.height(p.x, p.z) + 3.5)
	var dir := Vector3(-sin(a), 0.0, cos(a) * 0.75).normalized()
	node.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), p)
	node.visible = eye.distance_to(p) < 260.0
	whale["next_song"] = float(whale["next_song"]) - delta
	if float(whale["next_song"]) <= 0.0:
		whale["next_song"] = _rng.randf_range(22.0, 40.0)
		if underwater and eye.distance_to(p) < 300.0:
			var song: AudioStreamPlayer3D = whale["song"]
			var k: int = 1 + _rng.randi() % 2
			var path: String = "res://assets/sons/sfx/baleine_%d.ogg" % k
			if ResourceLoader.exists(path):
				song.stream = load(path)
				song.play()


# =================================================================== requins

func _build_sharks() -> void:
	var mesh := _shark_mesh()
	var homes := [[Vector3(-150, -18, 205), 22.0], [Vector3(-145, -16, 200), 15.0], [Vector3(-300, -24, 330), 16.0], [Vector3(-130, -20, 250), 26.0]]
	for h in homes:
		var root := Node3D.new()
		root.name = "Requin_v55"
		add_child(root)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _swimmer_mat(2.6, 0.0, 0.1, 1.1, 0.5)
		root.add_child(mi)
		_eyes(mi, -1.05, 0.17, 0.06, 0.025)
		var target: Node3D = CibleScript.new()
		target.name = "Cible_requin"
		target.hit_radius = 1.1
		target.hit_height = 0.55
		target.position = Vector3(0, -0.55, 0)
		root.add_child(target)
		var s := {"node": root, "mesh": mi, "target": target, "home": h[0], "r": h[1], "t": _rng.randf() * 50.0, "state": "ronde",
			"timer": 0.0, "hp": 20, "dir": Vector3.FORWARD, "speed": 3.0, "pos": h[0], "bite_cd": 0.0, "dead_t": 0.0}
		target.touched.connect(func(dmg: int, from: Vector3): _shark_hit(s, dmg, from))
		root.global_position = h[0]
		sharks.append(s)


func _shark_hit(s: Dictionary, dmg: int, from: Vector3) -> void:
	if str(s["state"]) == "mort":
		return
	s["hp"] = int(s["hp"]) - dmg
	var node: Node3D = s["node"]
	if main.get("combat_v28") != null and main.combat_v28 != null:
		main.combat_v28.damage_number(node.global_position + Vector3.UP * 0.6, dmg)
	if int(s["hp"]) <= 0:
		s["state"] = "mort"
		s["timer"] = 0.0
		(s["target"] as Node3D).set("active", false)
		kills += 1
		main.sfx("requin_mort", node.global_position)
		if main.inventory_v28 != null and main.inventory_v28.can_accept([["dent_requin", 1]]):
			main.inventory_v28.add("dent_requin", 1)
			main._show_message_v28("Le requin s'enfuit dans les profondeurs… Il a perdu une dent de requin (récupérée).")
			main.message_clock_v28 = 4.0
		return
	# touché : il fait demi-tour et file
	s["state"] = "fuite"
	s["timer"] = 2.6
	var away: Vector3 = node.global_position - from
	away.y = 0.0
	s["dir"] = away.normalized() if away.length() > 0.1 else -(s["dir"] as Vector3)
	main.sfx("touche_chair", node.global_position)


func _tick_sharks(delta: float, player: Vector3, swimmer: bool) -> void:
	for s in sharks:
		var node: Node3D = s["node"]
		var home: Vector3 = s["home"]
		var pos: Vector3 = s["pos"]
		s["t"] = float(s["t"]) + delta
		s["bite_cd"] = maxf(float(s["bite_cd"]) - delta, 0.0)
		var st: String = s["state"]
		var dist: float = pos.distance_to(player)
		var far: bool = pos.distance_to(player) > NEAR + 40.0
		node.visible = not far
		var want: Vector3 = s["dir"]
		var speed: float = 3.0
		match st:
			"ronde":
				var a: float = float(s["t"]) * 3.0 / float(s["r"])
				var target: Vector3 = home + Vector3(cos(a) * float(s["r"]), sin(float(s["t"]) * 0.2) * 1.5, sin(a) * float(s["r"]))
				want = (target - pos).normalized()
				speed = 3.0
				if swimmer and dist < 16.0 and not _in_dome(player) and player.distance_to(home) < float(s["r"]) + 30.0:
					s["state"] = "approche"
					s["timer"] = _rng.randf_range(3.0, 5.0)
					main.sfx("requin_menace", pos)
			"approche":
				# il tourne autour du nageur en se rapprochant
				var to: Vector3 = player - pos
				var side: Vector3 = to.cross(Vector3.UP).normalized()
				want = (to.normalized() * 0.45 + side * 0.9).normalized()
				speed = 3.6
				s["timer"] = float(s["timer"]) - delta
				if float(s["timer"]) <= 0.0:
					s["state"] = "charge"
					s["timer"] = 2.5
				if not swimmer or dist > 30.0:
					s["state"] = "ronde"
			"charge":
				want = (player + Vector3.UP * 0.9 - pos).normalized()
				speed = 8.5
				if dist < 5.0:
					s["dir"] = want            # les derniers mètres : droit sur la proie
				s["timer"] = float(s["timer"]) - delta
				if dist < 2.0 and float(s["bite_cd"]) <= 0.0:
					s["bite_cd"] = 2.0
					bites += 1
					main.sfx("requin_morsure", player + Vector3.UP)
					if main.get("monstres_v36") != null and main.monstres_v36 != null:
						main.monstres_v36.hurt_player(2, pos)
					s["state"] = "fuite"
					s["timer"] = 3.0
					want = -want
				elif float(s["timer"]) <= 0.0 or not swimmer:
					s["state"] = "approche" if swimmer else "ronde"
					s["timer"] = _rng.randf_range(2.5, 4.0)
			"fuite":
				speed = 6.0
				s["timer"] = float(s["timer"]) - delta
				if float(s["timer"]) <= 0.0:
					s["state"] = "approche" if swimmer and dist < 22.0 else "ronde"
					s["timer"] = _rng.randf_range(2.5, 4.0)
			"mort":
				s["timer"] = float(s["timer"]) + delta
				var tm: float = s["timer"]
				node.visible = tm < 3.0
				pos += Vector3.DOWN * delta * 1.2
				node.rotation.z = minf(tm * 1.2, PI * 0.9)
				s["pos"] = pos
				node.global_position = pos
				if tm > 120.0:
					s["state"] = "ronde"
					s["hp"] = 20
					s["pos"] = home + Vector3(0, 0, float(s["r"]))
					(s["target"] as Node3D).set("active", true)
					node.rotation = Vector3.ZERO
					node.visible = true
				continue
		# virage progressif, pas à travers le fond, jamais sous le dôme ni hors de l'eau
		var cur: Vector3 = s["dir"]
		cur = cur.slerp(want, clampf(delta * (3.5 if st == "charge" else 1.6), 0.0, 1.0))
		cur.y = clampf(cur.y, -0.6, 0.6)
		cur = cur.normalized()
		pos += cur * speed * delta
		var floor_y: float = Fond.height(pos.x, pos.z)
		pos.y = clampf(pos.y, floor_y + 1.2, SEA_Y - 1.0)
		var off := Vector2(pos.x - ATL.x, pos.z - ATL.z)
		if off.length() < 52.0:
			var push: Vector2 = off.normalized() * 52.0
			pos.x = ATL.x + push.x
			pos.z = ATL.z + push.y
		s["dir"] = cur
		s["pos"] = pos
		if far:
			continue
		var b := Basis.looking_at(cur, Vector3.UP)
		b = b.rotated(cur, -clampf(cur.cross(want).y * 2.0, -0.5, 0.5))
		node.global_transform = Transform3D(b, pos)
		(s["mesh"] as Node3D).material_override.set_shader_parameter("freq", 2.2 if st == "charge" else 1.1)


func _in_dome(p: Vector3) -> bool:
	return mer != null and mer.atl != null and mer.atl.in_dome(p)


# =================================================================== méduses

func _build_jellies() -> void:
	var sh: Shader = load("res://shaders/meduse_v55.gdshader")
	var bell := SphereMesh.new()
	bell.radius = 0.5
	bell.height = 0.6
	bell.is_hemisphere = true
	bell.radial_segments = 20
	bell.rings = 8
	var tent := _tentacle_mesh()
	var spots: Array = []
	var A: Vector2 = Fond.TRENCH_A
	var B: Vector2 = Fond.TRENCH_B
	for k in range(18):
		var p: Vector2 = A.lerp(B, _rng.randf())
		p += Vector2(_rng.randf_range(-5, 5), _rng.randf_range(-5, 5))
		var floor_y: float = Fond.height(p.x, p.y)
		spots.append(Vector3(p.x, floor_y + _rng.randf_range(2.5, 14.0), p.y))
	for k2 in range(6):
		var a: float = _rng.randf() * TAU
		var q := Vector3(-150 + cos(a) * 30.0, 0, 205 + sin(a) * 30.0)
		q.y = Fond.height(q.x, q.z) + _rng.randf_range(4.0, 9.0)
		spots.append(q)
	var tints := [Color(0.95, 0.45, 0.85), Color(0.45, 0.75, 1.0), Color(0.75, 0.55, 1.0), Color(1.0, 0.65, 0.45)]
	for p3 in spots:
		var root := Node3D.new()
		root.name = "Meduse_v55"
		add_child(root)
		root.global_position = p3
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("tint", tints[_rng.randi() % tints.size()])
		m.set_shader_parameter("seed", _rng.randf() * 10.0)
		var bi := MeshInstance3D.new()
		bi.mesh = bell
		bi.material_override = m
		root.add_child(bi)
		var tm: ShaderMaterial = m.duplicate()
		tm.set_shader_parameter("tentacle", 1.0)
		var ti := MeshInstance3D.new()
		ti.mesh = tent
		ti.material_override = tm
		root.add_child(ti)
		var glow := OmniLight3D.new()
		glow.light_color = (m.get_shader_parameter("tint") as Color)
		glow.light_energy = 0.35
		glow.omni_range = 3.0
		glow.shadow_enabled = false
		root.add_child(glow)
		var target: Node3D = CibleScript.new()
		target.hit_radius = 0.6
		target.hit_height = 0.4
		target.position = Vector3(0, -0.4, 0)
		root.add_child(target)
		var j := {"node": root, "mat": m, "home": p3, "t": _rng.randf() * 10.0, "alive": true, "timer": 0.0, "target": target}
		target.touched.connect(func(_d: int, _f: Vector3): _jelly_hit(j))
		jellies.append(j)


func _tentacle_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(10):
		var a: float = TAU * k / 10.0
		var r: float = 0.32 + (k % 2) * 0.1
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var len: float = 1.2 + (k % 3) * 0.35
		var side := Vector3(-sin(a), 0, cos(a)) * 0.025
		var segs: int = 6
		for s in range(segs):
			var y0: float = -len * s / segs
			var y1: float = -len * (s + 1) / segs
			var q := [base + side + Vector3(0, y0, 0), base - side + Vector3(0, y0, 0), base + side + Vector3(0, y1, 0), base - side + Vector3(0, y1, 0)]
			for i in [0, 1, 2, 2, 1, 3]:
				st.set_normal(Vector3(cos(a), 0, sin(a)))
				st.add_vertex(q[i])
	# bras buccaux, plus épais, au centre
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + 0.4
		var side2 := Vector3(-sin(a2), 0, cos(a2)) * 0.07
		var base2 := Vector3(cos(a2) * 0.06, 0.0, sin(a2) * 0.06)
		var q2 := [base2 + side2, base2 - side2, base2 + side2 * 0.4 + Vector3(0, -0.9, 0), base2 - side2 * 0.4 + Vector3(0, -0.9, 0)]
		for i2 in [0, 1, 2, 2, 1, 3]:
			st.set_normal(Vector3(cos(a2), 0, sin(a2)))
			st.add_vertex(q2[i2])
	return st.commit()


func _jelly_hit(j: Dictionary) -> void:
	if not bool(j["alive"]):
		return
	j["alive"] = false
	j["timer"] = 0.0
	(j["target"] as Node3D).set("active", false)
	if main.get("combat_v28") != null and main.combat_v28 != null:
		main.combat_v28.puff((j["node"] as Node3D).global_position, Color(0.8, 0.6, 1.0))


func _tick_jellies(delta: float, eye: Vector3, player: Vector3, swimmer: bool) -> void:
	_sting_cool = maxf(_sting_cool - delta, 0.0)
	for j in jellies:
		var node: Node3D = j["node"]
		var home: Vector3 = j["home"]
		var near: bool = eye.distance_to(home) < NEAR
		node.visible = near and bool(j["alive"]) and mer != null and bool(mer.under)
		if not bool(j["alive"]):
			j["timer"] = float(j["timer"]) + delta
			if float(j["timer"]) > 60.0:
				j["alive"] = true
				(j["target"] as Node3D).set("active", true)
			continue
		if not near:
			continue
		j["t"] = float(j["t"]) + delta
		var t: float = j["t"]
		var pulse: float = pow(maxf(sin(t * 1.6), 0.0), 3.0)
		(j["mat"] as ShaderMaterial).set_shader_parameter("pulse", pulse)
		var p: Vector3 = home + Vector3(sin(t * 0.13) * 1.5, sin(t * 0.21) * 1.2 + pulse * 0.15, cos(t * 0.11) * 1.5)
		node.global_position = p
		# la piqûre : cloche ou tentacules (jusqu'à 1,6 m sous la cloche)
		if swimmer and _sting_cool <= 0.0:
			var rel: Vector3 = player + Vector3.UP * 0.9 - p
			var horiz: float = Vector2(rel.x, rel.z).length()
			if horiz < 0.9 and rel.y < 0.8 and rel.y > -2.2:
				_sting_cool = 1.4
				stings += 1
				main.sfx("meduse_pique", p)
				if main.get("monstres_v36") != null and main.monstres_v36 != null:
					main.monstres_v36.hurt_player(1, p)
				if mer != null and mer.has_method("push_player"):
					mer.push_player(Vector3(rel.x, 0.3, rel.z).normalized() * 3.0)


# =================================================================== boucle

func _process(delta: float) -> void:
	if main == null or not main.game_started:
		return
	_clock += delta
	var eye: Vector3 = main._player_pos_v27()
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		eye = cam.global_position
	var player: Vector3 = main._player_pos_v27()
	var swimmer: bool = mer != null and bool(mer.swimming)
	var underwater: bool = mer != null and bool(mer.under)
	_tick_schools(delta, eye, player + Vector3.UP * 0.9)
	_tick_turtles(delta, eye)
	_tick_mantas(delta, eye)
	_tick_dolphins(delta, eye)
	_tick_whale(delta, eye, underwater)
	_tick_sharks(delta, player, swimmer)
	_tick_jellies(delta, eye, player, swimmer)


## Y a-t-il un requin qui charge ou tourne autour du nageur ? (musique, tests)
func danger() -> bool:
	for s in sharks:
		if str(s["state"]) in ["approche", "charge"]:
			return true
	return false

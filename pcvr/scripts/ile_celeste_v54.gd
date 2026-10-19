extends Node3D
## V54 : l'île flottante, à 150 m au-dessus de l'océan, au sud du village.
##  - Le dessus : une prairie d'altitude (herbe, fleurs, arbres, rochers), avec le plateau du
##    château au nord, l'Aire des Vents au sud (où Ventaile se pose) et le chemin entre les deux.
##  - Trois sources dont les ruisseaux filent jusqu'au bord… et tombent de 150 m dans l'océan :
##    nappe d'eau vitreuse en haut, qui s'effiloche en voiles et finit en brume ; brume et écume
##    sur la mer en bas.
##  - Le dessous : une montagne renversée de roche feuilletée, veinée de cristaux bleus qui
##    luisent, des racines qui pendent dans le vide, des rochers suspendus. Des nuages autour.
## Le relief se calcule à la demande (height) et sert aussi de sol physique.

const Flora = preload("res://scripts/flora_v25.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const CENTER := Vector3(40.0, 0.0, 400.0)
const Y0: float = 150.0
const R0: float = 66.0
const NR: int = 56
const NS: int = 240
const DEPTH: float = 82.0
## Le plateau du château (repère local de l'île, +Z vers le sud), l'Aire des Vents, le chemin.
const CASTLE := Vector2(0.0, -12.0)
const CASTLE_HALF: float = 24.0
const PLATEAU_H: float = 2.0
const ESPLANADE := Vector2(0.0, 34.0)
const ESPLANADE_R: float = 10.5
## Les trois sources : [source (local), angle du déversoir]
const SPRINGS := [[Vector2(36.0, 12.0), 0.22], [Vector2(-37.0, 6.0), PI - 0.12], [Vector2(26.0, -44.0), -1.05]]

var pc: bool = true
var streams: Array = []                 # {pts: [Vector2], rim: Vector2, dir: Vector2, angle}
var falls: Array = []                   # pieds des chutes (monde) : pour la brume et les sons
var _noise := FastNoiseLite.new()
var _coast := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _body: StaticBody3D
var _rng := RandomNumberGenerator.new()


func build(high_quality: bool) -> void:
	pc = high_quality
	_rng.seed = 5454
	_noise.seed = 541
	_noise.frequency = 0.022
	_noise.fractal_octaves = 4
	_coast.seed = 542
	_coast.frequency = 0.9
	_coast.fractal_octaves = 3
	_under.seed = 543
	_under.frequency = 0.06
	_under.fractal_octaves = 4
	_body = StaticBody3D.new()
	_body.name = "Ciel_sol"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_plan_streams()
	_build_top()
	_build_under()
	_build_water()
	_build_clouds()
	_build_flora()
	_build_rocks()
	_build_underside_details()


# =================================================================== forme

func coast_radius(theta: float) -> float:
	var n: float = _coast.get_noise_2d(cos(theta) * 1.6, sin(theta) * 1.6)
	return R0 + n * 9.0 + sin(theta * 3.0 + 0.6) * 3.0


func _plan_streams() -> void:
	streams.clear()
	for sp in SPRINGS:
		var s: Vector2 = sp[0]
		var ang: float = float(sp[1])
		var dir := Vector2(cos(ang), sin(ang))
		var rim: Vector2 = dir * coast_radius(ang)
		var mid: Vector2 = s.lerp(rim, 0.5) + Vector2(-dir.y, dir.x) * 4.0
		var pts: Array = []
		for k in range(19):
			var t: float = float(k) / 18.0
			pts.append(s.lerp(mid, t).lerp(mid.lerp(rim, t), t))
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in pts:
			lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
			hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
		streams.append({"pts": pts, "rim": rim, "dir": dir, "angle": ang, "spring": s, "lo": lo - Vector2(5, 5), "hi": hi + Vector2(5, 5)})


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Array:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return [p.distance_to(a + ab * t), t]


## Distance au ruisseau le plus proche : [distance, avancement 0..1 de la source au bord].
func stream_dist(l: Vector2) -> Array:
	var best: float = INF
	var prog: float = 0.0
	for s in streams:
		var lo: Vector2 = s["lo"]
		var hi: Vector2 = s["hi"]
		if l.x < lo.x or l.y < lo.y or l.x > hi.x or l.y > hi.y:
			continue
		var pts: Array = s["pts"]
		for k in range(pts.size() - 1):
			var r: Array = _seg_dist(l, pts[k], pts[k + 1])
			if float(r[0]) < best:
				best = float(r[0])
				prog = (k + float(r[1])) / float(pts.size() - 1)
	return [best, prog]


func _rect_weight(l: Vector2, c: Vector2, half: float, blend: float) -> float:
	var d := Vector2(maxf(absf(l.x - c.x) - half, 0.0), maxf(absf(l.y - c.y) - half, 0.0)).length()
	return 1.0 - smoothstep(0.0, blend, d)


## Hauteur du dessus, en repère local (par rapport à Y0).
func top_local(lx: float, lz: float) -> float:
	var l := Vector2(lx, lz)
	var r: float = l.length()
	var theta: float = atan2(lz, lx)
	var rr: float = coast_radius(theta)
	var hills: float = _noise.get_noise_2d(lx, lz) * 3.2 + _noise.get_noise_2d(lx * 2.3 + 40.0, lz * 2.3) * 0.8
	var h: float = 1.6 + hills * smoothstep(8.0, 30.0, r)
	# Une légère butte au sud-ouest, un vallon au nord-est
	h += 3.0 * exp(-pow(Vector2(lx + 32.0, lz - 26.0).length() / 14.0, 2.0))
	# Plateau du château, Aire des Vents, chemin
	h = lerpf(h, PLATEAU_H, _rect_weight(l, CASTLE, CASTLE_HALF + 3.0, 7.0))
	h = lerpf(h, PLATEAU_H, 1.0 - smoothstep(ESPLANADE_R, ESPLANADE_R + 6.0, l.distance_to(ESPLANADE)))
	var on_path: float = 1.0 - smoothstep(2.6, 5.0, absf(lx)) if lz > CASTLE.y + CASTLE_HALF - 1.0 and lz < ESPLANADE.y else 0.0
	h = lerpf(h, PLATEAU_H, on_path)
	# Les ruisseaux creusent leur lit
	var sd: Array = stream_dist(l)
	var cut: float = 1.0 - smoothstep(1.3, 3.4, float(sd[0]))
	h -= cut * (0.9 + 0.5 * float(sd[1]))
	# Bord arrondi : la prairie bascule dans le vide
	h -= 3.0 * pow(smoothstep(rr - 7.0, rr, r), 1.6)
	return h


## Hauteur du sol (monde), ou -INF hors de l'île.
func height(wx: float, wz: float) -> float:
	var lx: float = wx - CENTER.x
	var lz: float = wz - CENTER.z
	if lx * lx + lz * lz > 90.0 * 90.0:
		return -INF
	if Vector2(lx, lz).length() > coast_radius(atan2(lz, lx)):
		return -INF
	return Y0 + top_local(lx, lz)


## On peut marcher là (un peu en retrait du bord) ?
func walkable(wx: float, wz: float) -> bool:
	var lx: float = wx - CENTER.x
	var lz: float = wz - CENTER.z
	if lx * lx + lz * lz > 90.0 * 90.0:
		return false
	return Vector2(lx, lz).length() < coast_radius(atan2(lz, lx)) - 1.4


## Le joueur est-il là-haut (au-dessus de l'île, ou tout près) ?
func near(p: Vector3, margin: float = 20.0) -> bool:
	var lx: float = p.x - CENTER.x
	var lz: float = p.z - CENTER.z
	return lx * lx + lz * lz < (R0 + 14.0 + margin) * (R0 + 14.0 + margin) and p.y > Y0 - 40.0


func world(l: Vector2, dy: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + l.x, Y0 + top_local(l.x, l.y) + dy, CENTER.z + l.y)


# =================================================================== le dessus

func _ring_point(i: int, j: int) -> Vector3:
	var theta: float = TAU * float(j) / NS
	var rr: float = coast_radius(theta)
	var r: float = rr * pow(float(i) / NR, 0.8)
	var lx: float = cos(theta) * r
	var lz: float = sin(theta) * r
	return Vector3(lx, top_local(lx, lz), lz)


func _build_top() -> void:
	var pts: Array = []
	for i in range(NR + 1):
		var row: Array = []
		for j in range(NS):
			row.append(_ring_point(i, j) if i > 0 else Vector3(0, top_local(0, 0), 0))
		pts.append(row)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var faces := PackedVector3Array()
	var nrm: Array = []
	for i in range(NR + 1):
		var nrow: Array = []
		for j in range(NS):
			if i == 0:
				nrow.append(Vector3.UP)
				continue
			var p: Vector3 = pts[i][j]
			var pin: Vector3 = pts[i - 1][j] if i > 1 else pts[0][0]
			var pout: Vector3 = pts[mini(i + 1, NR)][j]
			var pl: Vector3 = pts[i][(j + NS - 1) % NS]
			var pr: Vector3 = pts[i][(j + 1) % NS]
			var n: Vector3 = (pout - pin).cross(pr - pl).normalized()
			if n.y < 0.0:
				n = -n
			nrow.append(n)
		nrm.append(nrow)
	var flip: bool = false
	var a0: Vector3 = pts[1][0]
	var b0: Vector3 = pts[2][0]
	var c0: Vector3 = pts[1][1]
	if (b0 - a0).cross(c0 - a0).y > 0.0:
		flip = true
	for i in range(NR):
		for j in range(NS):
			var j2: int = (j + 1) % NS
			var quad: Array = [[i, j], [i + 1, j], [i, j2], [i + 1, j], [i + 1, j2], [i, j2]]
			if i == 0:
				quad = [[0, j], [1, j], [1, j2]]
			for t in range(0, quad.size(), 3):
				var tri: Array = [quad[t], quad[t + 1], quad[t + 2]]
				if i == 0:
					var pa: Vector3 = pts[0][0]
					var pb: Vector3 = pts[1][j]
					var pc2: Vector3 = pts[1][j2]
					if (pb - pa).cross(pc2 - pa).y > 0.0:
						tri = [quad[0], quad[2], quad[1]]
				elif flip:
					tri = [tri[0], tri[2], tri[1]]
				for v in tri:
					var p2: Vector3 = pts[v[0]][v[1]]
					var world_p := Vector3(CENTER.x + p2.x, Y0 + p2.y, CENTER.z + p2.z)
					verts.append(world_p)
					normals.append(nrm[v[0]][v[1]])
					faces.append(world_p)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/jungle_terrain_v29.gdshader")
	var base := "res://assets/textures/"
	mat.set_shader_parameter("sand_tex", load(base + "terrain/sand.jpg"))
	mat.set_shader_parameter("sand_n", load(base + "terrain/sand_n.png"))
	mat.set_shader_parameter("moss_tex", load(base + "terrain/grass.jpg"))
	mat.set_shader_parameter("moss_n", load(base + "terrain/grass_n.png"))
	# Alpage : de l'herbe partout (la terre de la jungle ne va pas là-haut)
	mat.set_shader_parameter("soil_tex", load(base + "terrain/grass.jpg"))
	mat.set_shader_parameter("soil_n", load(base + "terrain/grass_n.png"))
	mat.set_shader_parameter("rock_tex", load(base + "ciel/roche_ciel.png"))
	mat.set_shader_parameter("rock_n", load(base + "ciel/roche_ciel_n.png"))
	mat.set_shader_parameter("extra_detail", pc)
	var mi := MeshInstance3D.new()
	mi.name = "Ciel_prairie"
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_body.add_child(cs)


# =================================================================== le dessous

func _rock_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/ciel/roche_ciel.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/ciel/roche_ciel_n.png")
	m.normal_scale = 1.2
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 3.0
	m.uv1_scale = Vector3(0.045, 0.045, 0.045)
	m.roughness = 0.92
	m.albedo_color = Color(1.25, 1.12, 0.98)
	return m


func _build_under() -> void:
	var nk: int = 34
	var tip := Vector2(6.0, -4.0)
	var rings: Array = []
	for k in range(nk + 1):
		var t: float = float(k) / nk
		var row: Array = []
		for j in range(NS + 1):
			var theta: float = TAU * float(j % NS) / NS
			var rr: float = coast_radius(theta)
			var y: float
			var rad: float
			if k == 0:
				var edge: Vector3 = _ring_point(NR, j % NS)
				row.append(Vector3(edge.x, edge.y, edge.z))
				continue
			elif k == 1:
				rad = rr * 1.015
				y = top_local(cos(theta) * rr * 0.98, sin(theta) * rr * 0.98) - 2.5
			else:
				var tt: float = (t - 1.0 / nk) / (1.0 - 1.0 / nk)
				# Profil : un ventre de roche, puis une longue pointe ; des corniches par endroits
				var prof: float = pow(1.0 - tt, 0.75) * (1.0 - 0.12 * sin(tt * PI))
				var nz: float = _under.get_noise_3d(cos(theta) * 30.0, tt * 60.0, sin(theta) * 30.0)
				var crag: float = _under.get_noise_3d(cos(theta) * 90.0, tt * 160.0, sin(theta) * 90.0)
				var ledge: float = 0.07 * smoothstep(0.1, 0.4, _under.get_noise_2d(theta * 8.0, tt * 18.0))
				rad = rr * clampf(prof * (0.92 + 0.24 * nz + 0.06 * crag) - ledge, 0.0, 1.05)
				y = -4.0 - tt * DEPTH
			var cx: float = tip.x * t * t
			var cz: float = tip.y * t * t
			row.append(Vector3(cx + cos(theta) * rad, y, cz + sin(theta) * rad))
		rings.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(nk):
		for j in range(NS):
			var a: Vector3 = rings[k][j]
			var b: Vector3 = rings[k + 1][j]
			var c: Vector3 = rings[k][j + 1]
			var d: Vector3 = rings[k + 1][j + 1]
			# face visible vers l'extérieur
			var out := Vector3(a.x + c.x, 0, a.z + c.z).normalized()
			var tri1: Array = [a, b, c]
			var tri2: Array = [b, d, c]
			if (b - a).cross(c - a).dot(out) > 0.0:
				tri1 = [a, c, b]
				tri2 = [b, c, d]
			for tri in [tri1, tri2]:
				for p in tri:
					st.add_vertex(Vector3(CENTER.x + p.x, Y0 + p.y, CENTER.z + p.z))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Ciel_dessous"
	mi.mesh = st.commit()
	mi.material_override = _rock_material()
	add_child(mi)


func _build_underside_details() -> void:
	var rock_m: StandardMaterial3D = _rock_material()
	# Rochers suspendus, comme détachés de l'île (ils flottent un peu plus bas)
	for k in range(7 if pc else 4):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(78.0, 96.0)
		var s: float = _rng.randf_range(4.0, 9.0)
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.shape(5460 + k, Vector3(s * 1.3, s * 1.8, s * 1.2), 0.6, 0.3, 0.55, 22)
		mi.material_override = rock_m
		mi.position = Vector3(CENTER.x + cos(a) * r, Y0 - _rng.randf_range(8.0, 30.0), CENTER.z + sin(a) * r)
		mi.rotation = Vector3(PI, _rng.randf() * TAU, 0)
		add_child(mi)
		# Un peu d'herbe sur le dessus de ces îlots
		var cap := MeshInstance3D.new()
		cap.mesh = Rocks.shape(5470 + k, Vector3(s * 1.25, s * 0.35, s * 1.15), 0.8, 0.2, 0.3, 18)
		cap.material_override = Rocks.material(Color(0.55, 0.65, 0.42), 0.95, 0.18)
		cap.position = mi.position + Vector3.UP * s * 0.75
		add_child(cap)
	# Cristaux bleus qui luisent sous l'île
	var crys := StandardMaterial3D.new()
	crys.albedo_color = Color(0.55, 0.8, 1.0, 0.85)
	crys.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crys.emission_enabled = true
	crys.emission = Color(0.35, 0.65, 1.0)
	crys.emission_energy_multiplier = 2.2
	crys.roughness = 0.1
	var prism := CylinderMesh.new()
	prism.top_radius = 0.0
	prism.bottom_radius = 0.6
	prism.height = 3.2
	prism.radial_segments = 6
	prism.rings = 1
	for k in range(26 if pc else 14):
		var a2: float = _rng.randf() * TAU
		var t2: float = _rng.randf_range(0.15, 0.7)
		var rr: float = coast_radius(a2) * pow(1.0 - t2, 0.75) * 0.95
		var at := Vector3(CENTER.x + cos(a2) * rr, Y0 - 4.0 - t2 * DEPTH, CENTER.z + sin(a2) * rr)
		var cluster := Node3D.new()
		cluster.position = at
		cluster.rotation = Vector3(0, a2, 0)
		add_child(cluster)
		for c in range(_rng.randi_range(3, 6)):
			var p := MeshInstance3D.new()
			p.mesh = prism
			p.material_override = crys
			var sc: float = _rng.randf_range(0.5, 1.6)
			p.scale = Vector3(sc, sc * _rng.randf_range(0.8, 1.6), sc)
			p.rotation = Vector3(PI + _rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.6, 0.6) + 0.7)
			p.position = Vector3(_rng.randf_range(-1.0, 1.0), -sc, _rng.randf_range(-1.0, 1.0))
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cluster.add_child(p)
		if pc and k % 3 == 0:
			var l := OmniLight3D.new()
			l.light_color = Color(0.45, 0.7, 1.0)
			l.light_energy = 1.4
			l.omni_range = 14.0
			l.position = Vector3(0, -2.0, 0)
			cluster.add_child(l)
	# Racines qui pendent dans le vide, depuis le bord
	var root_m := StandardMaterial3D.new()
	root_m.albedo_texture = load("res://assets/textures/flora/bark.png")
	root_m.albedo_color = Color(0.45, 0.36, 0.28)
	root_m.roughness = 0.95
	for k in range(46 if pc else 24):
		var a3: float = _rng.randf() * TAU
		var rr3: float = coast_radius(a3) * _rng.randf_range(0.9, 1.0)
		var length: float = _rng.randf_range(5.0, 18.0)
		var top := Vector3(CENTER.x + cos(a3) * rr3, Y0 - _rng.randf_range(1.5, 4.0), CENTER.z + sin(a3) * rr3)
		var cyl := CylinderMesh.new()
		cyl.top_radius = _rng.randf_range(0.12, 0.35)
		cyl.bottom_radius = 0.02
		cyl.height = length
		cyl.radial_segments = 6
		cyl.rings = 2
		var r_mi := MeshInstance3D.new()
		r_mi.mesh = cyl
		r_mi.material_override = root_m
		r_mi.position = top + Vector3.DOWN * length * 0.5
		r_mi.rotation = Vector3(_rng.randf_range(-0.15, 0.15), 0, _rng.randf_range(-0.15, 0.15))
		r_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(r_mi)


# =================================================================== l'eau

func _build_water() -> void:
	var flow := load("res://shaders/waterfall_v26.gdshader")
	var veil := load("res://shaders/chute_ciel_v54.gdshader")
	for s in streams:
		var pts: Array = s["pts"]
		# Le ruisseau : une bande d'eau qui suit son lit jusqu'au bord
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows: Array = []
		var n: int = pts.size()
		for k in range(n):
			var p: Vector2 = pts[k]
			var tan: Vector2 = ((pts[mini(k + 1, n - 1)] as Vector2) - (pts[maxi(k - 1, 0)] as Vector2)).normalized()
			var side := Vector2(-tan.y, tan.x)
			var w: float = lerpf(1.3, 2.0, float(k) / (n - 1))
			var bed: float = top_local(p.x, p.y)
			var row: Array = []
			for a in [-1.0, 0.0, 1.0]:
				var q: Vector2 = p + side * w * a
				row.append([Vector3(CENTER.x + q.x, Y0 + bed + 0.38, CENTER.z + q.y), Vector2((a + 1.0) * 0.5, float(k) / (n - 1))])
			rows.append(row)
		for k in range(n - 1):
			for i in range(2):
				for idx in [[k, i], [k, i + 1], [k + 1, i], [k, i + 1], [k + 1, i + 1], [k + 1, i]]:
					var v: Array = rows[idx[0]][idx[1]]
					st.set_normal(Vector3.UP)
					st.set_uv(v[1])
					st.add_vertex(v[0])
		var brook := MeshInstance3D.new()
		brook.name = "Ruisseau_ciel"
		brook.mesh = st.commit()
		var m := ShaderMaterial.new()
		m.shader = flow
		m.set_shader_parameter("fall_length", 40.0)
		m.set_shader_parameter("flow_speed", 1.4)
		brook.material_override = m
		brook.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(brook)
		# La source : un petit bassin cerclé de rochers moussus
		var spring: Vector2 = s["spring"]
		var pool := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 2.4
		disc.bottom_radius = 2.4
		disc.height = 0.05
		disc.radial_segments = 24
		pool.mesh = disc
		var pm := ShaderMaterial.new()
		pm.shader = flow
		pm.set_shader_parameter("fall_length", 3.0)
		pm.set_shader_parameter("flow_speed", 0.3)
		pool.material_override = pm
		pool.position = Vector3(CENTER.x + spring.x, Y0 + top_local(spring.x, spring.y) + 0.36, CENTER.z + spring.y)
		add_child(pool)
		var rm: Material = Rocks.material(Color(0.7, 0.7, 0.66), 0.7, 0.15)
		for k2 in range(7):
			var a2: float = TAU * k2 / 7.0 + 0.4
			if Vector2(cos(a2), sin(a2)).dot((s["dir"] as Vector2)) > 0.75:
				continue
			var sz: float = _rng.randf_range(0.8, 1.5)
			var rock := MeshInstance3D.new()
			rock.mesh = Rocks.shape(5480 + k2, Vector3(sz * 1.3, sz, sz * 1.2), 0.7, 0.24, 0.6, 16)
			rock.material_override = rm
			rock.position = pool.position + Vector3(cos(a2) * 2.9, sz * 0.15, sin(a2) * 2.9)
			rock.rotation.y = _rng.randf() * TAU
			add_child(rock)
		# La chute : du bord de l'île jusqu'à la mer
		_make_fall(s)


func _make_fall(s: Dictionary) -> void:
	var rim: Vector2 = s["rim"]
	var d2: Vector2 = s["dir"]
	var dir := Vector3(d2.x, 0, d2.y)
	var side := Vector3(-d2.y, 0, d2.x)
	var top_y: float = Y0 + top_local(rim.x * 0.97, rim.y * 0.97) + 0.38
	var lip := Vector3(CENTER.x + rim.x * 0.97, top_y, CENTER.z + rim.y * 0.97)
	var drop: float = top_y + 0.4
	var rows: int = 46 if pc else 30
	var cols: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for j in range(rows + 1):
		var t: float = float(j) / rows
		# Elle bascule par-dessus le bord (parabole), puis tombe presque à la verticale
		var fall_t: float = t * t * 0.0 + t
		var out: float = 1.5 * sqrt(t * 3.0) + 7.0 * t
		var y: float = top_y - drop * pow(fall_t, 1.15)
		var width: float = lerpf(3.4, 17.0, pow(t, 0.8))
		var row: Array = []
		for i in range(cols + 1):
			var a: float = float(i) / cols
			var across: float = (a - 0.5) * width
			var bulge: float = (1.0 - pow((a - 0.5) * 2.0, 2.0)) * (0.3 + 2.0 * t)
			row.append([lip + dir * (out + bulge) + side * across + Vector3(0, y - top_y, 0), Vector2(a, t)])
		grid.append(row)
	for j in range(rows):
		for i in range(cols):
			for idx in [[j, i], [j + 1, i], [j, i + 1], [j, i + 1], [j + 1, i], [j + 1, i + 1]]:
				var v: Array = grid[idx[0]][idx[1]]
				st.set_normal(dir)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	var fall := MeshInstance3D.new()
	fall.name = "Chute_ciel_v54_%d" % falls.size()
	fall.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/chute_ciel_v54.gdshader")
	m.set_shader_parameter("fall_length", drop)
	fall.material_override = m
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fall.extra_cull_margin = 20.0
	add_child(fall)
	var foot: Vector3 = lip + dir * 10.0
	foot.y = 0.0
	falls.append(foot)
	# Brume au pied (sur la mer) et embruns à mi-hauteur
	_mist("Brume_mer_ciel", foot + Vector3.UP * 3.0, Vector3(9, 2, 9), 60 if pc else 26, 7.0, 16.0, Color(0.93, 0.95, 0.97, 0.3), 2.5)
	_mist("Embruns_ciel", lip + dir * 8.0 + Vector3.DOWN * drop * 0.55, Vector3(6, 20, 6), 34 if pc else 14, 6.0, 11.0, Color(0.95, 0.97, 1.0, 0.16), 1.0)
	# Écume qui bouillonne sur la mer, au pied de la chute
	_mist("Ecume_ciel", foot + Vector3.UP * 0.4, Vector3(7, 0.3, 7), 50 if pc else 22, 2.5, 5.0, Color(1.0, 1.0, 1.0, 0.55), 3.5)


func _mist(label: String, at: Vector3, box: Vector3, amount: int, lifetime: float, size: float, color: Color, rise: float) -> void:
	var parts := GPUParticles3D.new()
	parts.name = label
	parts.amount = amount
	parts.lifetime = lifetime
	parts.position = at
	parts.preprocess = lifetime
	parts.visibility_aabb = AABB(Vector3(-30, -30, -30), Vector3(60, 60, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = rise * 0.5
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0.4, 0.15, 0)
	pm.damping_min = 0.2
	pm.damping_max = 0.5
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.25, color)
	fade.set_color(fade.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	parts.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load("res://assets/textures/ciel/nuage.png")
	mat.disable_receive_shadows = true
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(parts)


# =================================================================== nuages

func _build_clouds() -> void:
	var tex: Texture2D = load("res://assets/textures/ciel/nuage.png")
	for k in range(12 if pc else 7):
		var a: float = TAU * k / (12.0 if pc else 7.0) + _rng.randf_range(-0.2, 0.2)
		var r: float = _rng.randf_range(55.0, 105.0)
		var y: float = Y0 - _rng.randf_range(14.0, 60.0)
		var s: float = _rng.randf_range(32.0, 62.0)
		var q := MeshInstance3D.new()
		q.name = "Nuage_ciel"
		var qm := QuadMesh.new()
		qm.size = Vector2(s, s * 0.6)
		q.mesh = qm
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.albedo_color = Color(0.96, 0.97, 1.0, 0.85)
		m.proximity_fade_enabled = true
		m.proximity_fade_distance = 12.0
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 8.0
		m.distance_fade_max_distance = 40.0
		q.material_override = m
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(CENTER.x + cos(a) * r, y, CENTER.z + sin(a) * r)
		add_child(q)


# =================================================================== végétation et rochers

func _free_spot(l: Vector2, margin: float) -> bool:
	if _rect_weight(l, CASTLE, CASTLE_HALF + margin, 0.01) > 0.5:
		return false
	if l.distance_to(ESPLANADE) < ESPLANADE_R + margin:
		return false
	if l.y > CASTLE.y + CASTLE_HALF - 1.0 and l.y < ESPLANADE.y and absf(l.x) < 3.5 + margin:
		return false
	if float(stream_dist(l)[0]) < 3.0 + margin * 0.5:
		return false
	for s in streams:
		if l.distance_to(s["spring"]) < 4.5 + margin:
			return false
	return l.length() < coast_radius(atan2(l.y, l.x)) - 6.0 - margin


func _random_free(margin: float) -> Vector2:
	for attempt in range(40):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * R0
		var l := Vector2(cos(a) * r, sin(a) * r)
		if _free_spot(l, margin):
			return l
	return Vector2.INF


func _build_flora() -> void:
	# Arbres : des feuillus clairsemés, comme sur un alpage
	var trees: Array = []
	for v in range(3):
		trees.append(Flora.tree(5490 + v, _rng.randf_range(7.0, 10.0), 300 if pc else 180))
	var placed: Array = []
	for k in range(26 if pc else 16):
		var l: Vector2 = _random_free(3.0)
		if l == Vector2.INF:
			continue
		var close: bool = false
		for q in placed:
			if l.distance_to(q) < 9.0:
				close = true
		if close:
			continue
		placed.append(l)
		var mi := MeshInstance3D.new()
		mi.name = "Arbre_ciel"
		mi.mesh = trees[k % trees.size()]
		mi.position = world(l, -0.15)
		mi.rotation.y = _rng.randf() * TAU
		mi.scale = Vector3.ONE * _rng.randf_range(0.85, 1.25)
		add_child(mi)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.35
		cyl.height = 4.0
		cs.shape = cyl
		cs.position = mi.position + Vector3.UP * 2.0
		_body.add_child(cs)
	# Herbe, fleurs, buissons (instances groupées)
	_scatter("Herbe_ciel", Flora.grass_clump(11, 0.55, 0.05, 541), Flora.grass_material(), 3400 if pc else 1500, 0.0, Vector2(0.7, 1.4))
	_scatter("Fleurs_ciel_bleues", Flora.flower_clump(), Flora.flower_material(Color(0.55, 0.65, 1.0)), 260 if pc else 120, 0.5, Vector2(0.7, 1.2))
	_scatter("Fleurs_ciel_blanches", Flora.flower_clump(), Flora.flower_material(Color(1.0, 0.98, 0.92)), 260 if pc else 120, 0.5, Vector2(0.7, 1.2))
	_scatter("Buissons_ciel", Flora.bush(546), null, 60 if pc else 30, 1.5, Vector2(0.8, 1.5))


func _scatter(label: String, mesh: Mesh, mat: Material, count: int, margin: float, size: Vector2) -> void:
	var xfs: Array = []
	for k in range(count):
		var l: Vector2 = _random_free(margin)
		if l == Vector2.INF:
			continue
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(size.x, size.y))
		xfs.append(Transform3D(b, world(l, -0.03)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = label
	inst.multimesh = mm
	if mat != null:
		inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.visibility_range_end = 220.0 if pc else 140.0
	add_child(inst)


func _build_rocks() -> void:
	var mat: Material = Rocks.material(Color(0.78, 0.76, 0.72), 0.55, 0.2)
	for k in range(22 if pc else 12):
		var l: Vector2 = _random_free(2.0)
		if l == Vector2.INF:
			continue
		var s: float = _rng.randf_range(0.7, 2.4)
		var mi := MeshInstance3D.new()
		mi.name = "Rocher_ciel"
		mi.mesh = Rocks.shape(5500 + k, Vector3(s * 1.4, s, s * 1.2), 0.7, 0.22, 0.5, 18)
		mi.material_override = mat
		mi.position = world(l, s * 0.2 - 0.3)
		mi.rotation.y = _rng.randf() * TAU
		add_child(mi)
		if s > 1.2:
			_body.add_child(Rocks.collision_for(mi.mesh, mi.transform))

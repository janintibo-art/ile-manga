extends Node3D
## V58 : Yggdrasil, l'Arbre-Monde, au cœur du royaume des fées.
##  - Dehors : un tronc de trente mètres de tour, cannelé, à l'écorce argentée et moussue, de
##    grandes racines qui courent sur la prairie, huit charpentières qui montent vers une
##    immense couronne d'or et de vert, des fruits de lumière, des lucioles. La porte aux
##    runes apparaît dans le tronc quand les fées confient leur quête.
##  - Dedans : le tronc est creux. Trois salles l'une au-dessus de l'autre, reliées par des
##    escaliers de racines (fermés par des racines tant que l'énigme de la salle n'est pas
##    résolue), puis la Couronne, à ciel ouvert, au sommet du tronc :
##      0. la Salle des Lucioles (cinq pierres-runes, le bassin des lucioles) ;
##      1. la Salle de la Sève (la source de sève, trois fleurs-miroirs, le cœur de bois) ;
##      2. la Salle des Saisons (quatre fleurs, une stèle) ;
##      3. la Couronne (la Mère-Ronce, l'esprit de l'arbre, le cercle de retour).
## Ce nœud ne fait que le décor et ses mouvements ; les règles sont dans feerie_v58.gd.

const Gfx = preload("res://scripts/feerique_gfx_v45.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const RI: float = 11.0                           # rayon intérieur du tronc creux
const FLOORS := [0.15, 9.6, 19.2]                # dessus des planchers des trois salles
const CROWN: float = 30.0                        # dessus de la Couronne
const DOOR_ANGLE: float = PI * 0.5               # la porte regarde le sud (+Z), vers la clairière
## Escaliers : [angle du pied, sens de montée]
const STAIRS := [[-PI * 0.5, 1.0], [PI * 0.75, -1.0], [-PI * 0.25, -1.0]]
const STAIR_SPAN: float = 1.4
const STONE_COLORS := [Color(0.45, 1.0, 0.55), Color(1.0, 0.82, 0.3), Color(0.4, 0.75, 1.0), Color(1.0, 0.5, 0.8), Color(0.75, 0.55, 1.0)]
const STONE_NAMES := ["de la Feuille", "du Soleil", "de l'Eau", "de la Fleur", "de la Nuit"]
const SEASON_COLORS := [Color(1.0, 0.62, 0.82), Color(1.0, 0.85, 0.3), Color(0.9, 0.45, 0.15), Color(0.88, 0.95, 1.0)]

var pc: bool = true
var points: Dictionary = {}                      # repères (locaux) des salles
var stones: Array = []                           # {node, mat, light}
var mirrors: Array = []                          # {pos, head, light}
var pedestals: Array = []                        # {pos, petals: [mat], light}
var gates: Array = []                            # nœuds des grilles de racines (une par salle)
var door: Node3D
var door_leaves: Array = []
var door_runes: StandardMaterial3D
var spirit: Node3D
var circle: Node3D
var basin_light: OmniLight3D
var firefly: Node3D
var beam_root: Node3D
var heart_mat: StandardMaterial3D
var heart_light: OmniLight3D
var source_pos: Vector3
var heart_pos: Vector3
var mirror_targets: Dictionary = {}              # nom -> position locale (murs, cœur, fleurs)
var _gfx
var _body: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _n := FastNoiseLite.new()
var _bark: StandardMaterial3D
var _bark_in: StandardMaterial3D
var _bark_2s: StandardMaterial3D
var _wood: StandardMaterial3D
var _clock: float = 0.0
var _beam_mat: StandardMaterial3D
var _spirit_mats: Array = []


func build(high_quality: bool) -> void:
	pc = high_quality
	_gfx = Gfx.new()
	_rng.seed = 9558
	_n.seed = 958
	_n.frequency = 1.0
	_n.fractal_octaves = 3
	_body = StaticBody3D.new()
	_body.name = "Yggdrasil_sol"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_make_materials()
	_build_trunk()
	_build_roots()
	_build_crown_platform()
	_build_branches()
	_build_interior()
	_build_door()
	_build_lucioles_room()
	_build_seve_room()
	_build_saisons_room()
	_build_spirit()
	_build_circle()


# =================================================================== matériaux

func _make_materials() -> void:
	_bark = StandardMaterial3D.new()
	_bark.albedo_texture = load("res://assets/textures/fees/ecorce_ygg.png")
	_bark.normal_enabled = true
	_bark.normal_texture = load("res://assets/textures/fees/ecorce_ygg_n.png")
	_bark.normal_scale = 1.4
	_bark.roughness = 0.94
	_bark.albedo_color = Color(1.0, 0.96, 0.92)
	_bark_2s = _bark.duplicate()
	_bark_2s.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bark_in = _bark.duplicate()
	_bark_in.albedo_color = Color(0.62, 0.52, 0.44)
	_bark_in.emission_enabled = true
	_bark_in.emission = Color(0.05, 0.08, 0.03)
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/fees/cernes.png")
	_wood.normal_enabled = true
	_wood.normal_texture = load("res://assets/textures/fees/cernes_n.png")
	_wood.roughness = 0.82


func _glow_mat(c: Color, energy: float = 2.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.4
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


# =================================================================== le tronc

func trunk_r(theta: float, y: float) -> float:
	# autour de la porte, le tronc est lisse et droit (pas de contrefort)
	var m: float = exp(-pow(wrapf(theta - DOOR_ANGLE, -PI, PI) / 0.34, 2.0))
	var base: float = lerpf(15.2, 13.2, clampf(y / CROWN, 0.0, 1.0)) + 4.0 * exp(-maxf(y, 0.0) / 3.2) * (1.0 - m)
	var flute: float = 0.6 * sin(theta * 7.0 + y * 0.05) + 0.3 * sin(theta * 13.0 - y * 0.08)
	var n: float = _n.get_noise_2d(cos(theta) * 6.0 + y * 0.12, sin(theta) * 6.0) * 0.8
	return base + (flute * (0.6 + 0.5 * exp(-maxf(y, 0.0) / 8.0)) + n) * (1.0 - 0.85 * m)


func _build_trunk() -> void:
	var nth: int = 84 if pc else 48
	var ys: Array = []
	for k in range(27):
		ys.append(lerpf(-1.5, CROWN, pow(float(k) / 26.0, 0.9)))
	# au sommet, l'écorce s'arrondit en un rebord (un petit parapet autour de la Couronne)
	var lip := [[CROWN + 0.55, 1.0], [CROWN + 0.95, 0.985], [CROWN + 1.1, 0.955], [CROWN + 0.9, 0.925], [CROWN + 0.2, 0.91]]
	for e in lip:
		ys.append(float(e[0]))
	var grid: Array = []
	for k in range(ys.size()):
		var row: Array = []
		var shrink: float = 1.0 if k < 27 else float(lip[k - 27][1])
		for j in range(nth + 1):
			var th: float = TAU * float(j % nth) / nth
			var r: float = trunk_r(th, minf(ys[k], CROWN)) * shrink
			row.append([Vector3(cos(th) * r, ys[k], sin(th) * r), Vector2(float(j) / nth * 10.0, (-float(ys[k]) / 8.5) if k < 27 else (-(CROWN + (k - 26) * 0.4) / 8.5))])
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for k in range(ys.size() - 1):
		for j in range(nth):
			var a: Array = grid[k][j]
			var b: Array = grid[k + 1][j]
			var c: Array = grid[k][j + 1]
			var d: Array = grid[k + 1][j + 1]
			var out := Vector3((a[0] as Vector3).x, 0, (a[0] as Vector3).z).normalized()
			# le rebord redescend vers l'intérieur : là, la face visible regarde la Couronne
			if float(ys[k + 1]) < float(ys[k]):
				out = -out
			var t1: Array = [a, b, c]
			var t2: Array = [b, d, c]
			if ((b[0] as Vector3) - (a[0] as Vector3)).cross((c[0] as Vector3) - (a[0] as Vector3)).dot(out) > 0.0:
				t1 = [a, c, b]
				t2 = [b, c, d]
			for tri in [t1, t2]:
				for v in tri:
					st.set_uv(v[1])
					st.add_vertex(v[0])
					faces.append(v[0])
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Tronc_Yggdrasil"
	mi.mesh = st.commit()
	mi.material_override = _bark
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_body.add_child(cs)


## Les grandes racines qui courent sur la prairie (la porte reste dégagée).
func _build_roots() -> void:
	var curves: Array = []
	var n: int = 11
	for k in range(n):
		var a: float = TAU * k / n + 0.17
		if absf(wrapf(a - DOOR_ANGLE, -PI, PI)) < 0.42:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var r0: float = trunk_r(a, 2.0)
		var start: Vector3 = d * (r0 - 1.8) + Vector3.UP * 3.2
		var reach: float = _rng.randf_range(24.0, 32.0)
		var end: Vector3 = d * reach + side * _rng.randf_range(-5.0, 5.0) + Vector3.DOWN * 1.8
		var ctrl: Vector3 = d * (r0 + 5.0) + side * _rng.randf_range(-3.0, 3.0) + Vector3.UP * 1.6
		curves.append([start, ctrl, end, _rng.randf_range(2.4, 3.2), 0.35, 9])
		# une racine secondaire qui part de la grande
		var mid: Vector3 = start.lerp(ctrl, 0.5).lerp(ctrl.lerp(end, 0.5), 0.5)
		var a2: float = a + _rng.randf_range(0.25, 0.5) * (1.0 if k % 2 == 0 else -1.0)
		var end2: Vector3 = Vector3(cos(a2), 0, sin(a2)) * (reach * 0.75) + Vector3.DOWN * 1.2
		curves.append([mid + Vector3.UP * 0.4, mid.lerp(end2, 0.5) + Vector3.UP * 1.0, end2, 1.1, 0.2, 6])
	var mesh: ArrayMesh = _gfx.roots_mesh(curves)
	var mi := MeshInstance3D.new()
	mi.name = "Racines_Yggdrasil"
	mi.mesh = mesh
	var rm: StandardMaterial3D = _bark.duplicate()
	rm.uv1_scale = Vector3(0.8, 0.8, 1.0)
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = rm
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_body.add_child(cs)


# =================================================================== planchers (cernes du bois)

## Un disque de bois (cernes en coordonnées polaires) : dessus, dessous et chant.
func _disc(name_s: String, radius: float, y_top: float, thick: float, top_mat: Material, bottom_mat: Material, solid: bool = true) -> MeshInstance3D:
	var segs: int = 72 if pc else 40
	var rings: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sb := SurfaceTool.new()
	sb.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings):
		var r0: float = radius * float(i) / rings
		var r1: float = radius * float(i + 1) / rings
		for j in range(segs):
			var a0: float = TAU * j / segs
			var a1: float = TAU * (j + 1) / segs
			var q: Array = [[r0, a0], [r1, a0], [r1, a1], [r0, a0], [r1, a1], [r0, a1]]
			# dessus : face vers le haut
			for v in q:
				var rr: float = v[0]
				var aa: float = v[1]
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(0.5 + cos(aa) * rr / radius * 0.48, 0.5 + sin(aa) * rr / radius * 0.48))
				st.add_vertex(Vector3(cos(aa) * rr, y_top, sin(aa) * rr))
			# dessous
			for v in [q[0], q[2], q[1], q[3], q[5], q[4]]:
				var rr2: float = v[0]
				var aa2: float = v[1]
				sb.set_normal(Vector3.DOWN)
				sb.set_uv(Vector2(0.5 + cos(aa2) * rr2 / radius * 0.48, 0.5 + sin(aa2) * rr2 / radius * 0.48))
				sb.add_vertex(Vector3(cos(aa2) * rr2, y_top - thick, sin(aa2) * rr2))
	for j in range(segs):
		var a0: float = TAU * j / segs
		var a1: float = TAU * (j + 1) / segs
		var p0 := Vector3(cos(a0) * radius, y_top, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, y_top, sin(a1) * radius)
		var p2: Vector3 = p0 + Vector3.DOWN * thick
		var p3: Vector3 = p1 + Vector3.DOWN * thick
		var nrm := Vector3(cos(a0), 0, sin(a0))
		for v in [p0, p2, p1, p1, p2, p3]:
			sb.set_normal(nrm)
			sb.set_uv(Vector2(float(j) / segs * 6.0, (v as Vector3).y))
			sb.add_vertex(v)
	var mesh := ArrayMesh.new()
	st.generate_tangents()
	sb.generate_tangents()
	st.commit(mesh)
	sb.commit(mesh)
	mesh.surface_set_material(0, top_mat)
	mesh.surface_set_material(1, bottom_mat)
	var mi := MeshInstance3D.new()
	mi.name = name_s
	mi.mesh = mesh
	add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = thick
		cs.shape = cyl
		cs.position = Vector3(0, y_top - thick * 0.5, 0)
		_body.add_child(cs)
	return mi


func _build_crown_platform() -> void:
	var r: float = 999.0
	for j in range(36):
		r = minf(r, trunk_r(TAU * j / 36.0, CROWN))
	var under: StandardMaterial3D = _bark_in
	_disc("Couronne_plancher", r + 0.4, CROWN, 1.0, _wood, under)
	points["crown_r"] = r


# =================================================================== branches et couronne

## Tube le long d'un chemin (anneaux transportés), faces vers l'extérieur.
func _tube(st: SurfaceTool, path: Array, radii: Array, sides: int, uv_k: float) -> void:
	var rings: Array = []
	var along: float = 0.0
	var prev_side := Vector3.ZERO
	for i in range(path.size()):
		var fwd: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var side: Vector3 = fwd.cross(Vector3.UP if absf(fwd.y) < 0.95 else Vector3.RIGHT).normalized()
		if prev_side != Vector3.ZERO and side.dot(prev_side) < 0.0:
			side = -side
		prev_side = side
		var up: Vector3 = side.cross(fwd).normalized()
		if i > 0:
			along += (path[i] as Vector3).distance_to(path[i - 1])
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / sides
			var nrm: Vector3 = side * cos(a) + up * sin(a)
			ring.append([(path[i] as Vector3) + nrm * float(radii[i]), Vector2(float(s) / sides * maxf(1.0, float(radii[i]) * 1.2), -along * uv_k * 0.12)])
		rings.append([ring, path[i]])
	for i in range(rings.size() - 1):
		var r0: Array = rings[i][0]
		var r1: Array = rings[i + 1][0]
		var c0: Vector3 = rings[i][1]
		for s in range(sides):
			var a: Array = r0[s]
			var b: Array = r0[s + 1]
			var c: Array = r1[s]
			var d: Array = r1[s + 1]
			var out: Vector3 = ((a[0] as Vector3) - c0).normalized()
			var t1: Array = [a, c, b]
			var t2: Array = [b, c, d]
			if ((c[0] as Vector3) - (a[0] as Vector3)).cross((b[0] as Vector3) - (a[0] as Vector3)).dot(out) > 0.0:
				t1 = [a, b, c]
				t2 = [b, d, c]
			for tri in [t1, t2]:
				for v in tri:
					st.set_uv(v[1])
					st.add_vertex(v[0])


func _leaf_card(st: SurfaceTool, center: Vector3, size: float, crown: Vector3, crown_r: float) -> void:
	var a: float = _rng.randf() * TAU
	var u := Vector3(cos(a), 0, sin(a))
	var perp := Vector3(-u.z, 0, u.x)
	var tilt: float = _rng.randf_range(0.0, 0.8)
	var v: Vector3 = (perp * cos(tilt) + Vector3.UP * sin(tilt) * (1.0 if _rng.randf() < 0.5 else -1.0)).normalized()
	var hx: Vector3 = u * size * 0.5
	var hy: Vector3 = v * size * 0.5
	var out_dir: Vector3 = (center - crown + Vector3.UP * crown_r * 0.6).normalized()
	var outer: float = clampf(center.distance_to(crown) / maxf(crown_r, 0.01), 0.0, 1.0)
	var p := [center - hx - hy, center + hx - hy, center + hx + hy, center - hx + hy]
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	var flex: float = 0.3 + 0.4 * _rng.randf()
	for i in [0, 1, 2, 0, 2, 3]:
		var n: Vector3 = (out_dir * 0.8 + ((p[i] as Vector3) - center).normalized() * 0.2).normalized()
		st.set_color(Color.WHITE)
		st.set_normal(n)
		st.set_uv(uv[i])
		st.set_uv2(Vector2(flex, outer))
		st.add_vertex(p[i])


func _build_branches() -> void:
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold := SurfaceTool.new()
	gold.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := SurfaceTool.new()
	green.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bloom := SurfaceTool.new()
	bloom.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crown := Vector3(0, CROWN + 58.0, 0)
	var crown_r: float = 58.0
	var ends: Array = []
	var nb: int = 8
	var cr: float = float(points["crown_r"])
	# Huit charpentières montent de la fourche, autour de la Couronne, puis s'ouvrent
	for b in range(nb):
		var a: float = TAU * b / nb + 0.2 + _rng.randf_range(-0.12, 0.12)
		var d := Vector3(cos(a), 0, sin(a))
		var start: Vector3 = d * (cr + 1.0) + Vector3.UP * (CROWN - 4.0)
		var path: Array = [start]
		var radii: Array = []
		var segs: int = 10
		var length: float = _rng.randf_range(64.0, 76.0)
		var dir: Vector3 = (d * 0.3 + Vector3.UP * 0.95).normalized()
		for s in range(1, segs + 1):
			dir = (dir + d * 0.11 + Vector3(_rng.randf_range(-0.06, 0.06), -0.015, _rng.randf_range(-0.06, 0.06))).normalized()
			path.append((path[s - 1] as Vector3) + dir * length / segs)
		for s in range(path.size()):
			radii.append(lerpf(3.8, 0.5, pow(float(s) / segs, 0.75)))
		_tube(wood, path, radii, 16 if pc else 9, 1.0)
		# collision du pied de la branche (on ne traverse pas le bois)
		for s2 in range(2):
			var cs := CollisionShape3D.new()
			var cap := CapsuleShape3D.new()
			cap.radius = float(radii[s2]) * 0.9
			cap.height = maxf((path[s2 + 1] as Vector3).distance_to(path[s2]) + cap.radius * 2.0, cap.radius * 2.1)
			cs.shape = cap
			var mid: Vector3 = ((path[s2] as Vector3) + (path[s2 + 1] as Vector3)) * 0.5
			var up: Vector3 = ((path[s2 + 1] as Vector3) - (path[s2] as Vector3)).normalized()
			var side: Vector3 = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
			cs.transform = Transform3D(Basis(side, up, side.cross(up)), mid)
			_body.add_child(cs)
		ends.append(path[segs])
		ends.append(path[segs - 1])
		ends.append(path[segs - 3])
		# rameaux : de grandes branches presque horizontales qui portent le feuillage
		for k in range(7):
			var si: int = _rng.randi_range(4, segs - 1)
			var o: Vector3 = path[si]
			var a2: float = a + _rng.randf_range(-1.3, 1.3)
			var d2: Vector3 = (Vector3(cos(a2), _rng.randf_range(0.05, 0.45), sin(a2))).normalized()
			var sp: Array = [o]
			var sr: Array = []
			var sl: float = _rng.randf_range(16.0, 28.0)
			for s3 in range(1, 7):
				d2 = (d2 + Vector3(0, -0.04, 0)).normalized()
				sp.append((sp[s3 - 1] as Vector3) + d2 * sl / 6.0)
			for s3 in range(sp.size()):
				sr.append(lerpf(float(radii[si]) * 0.45, 0.12, float(s3) / 6.0))
			_tube(wood, sp, sr, 8 if pc else 5, 1.0)
			ends.append(sp[6])
			ends.append(sp[4])
			ends.append(sp[2])
	var cards: int = 2600 if pc else 900
	for c in range(cards):
		var e: Vector3 = ends[_rng.randi() % ends.size()]
		var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.45, 0.6), _rng.randf_range(-1, 1)) * _rng.randf_range(1.0, 10.0)
		var size: float = _rng.randf_range(6.0, 9.5) * (1.0 if pc else 1.45)
		var pick: int = c % 20
		_leaf_card(gold if pick < 5 else (bloom if pick < 8 else green), e + off, size, crown, crown_r)
	wood.generate_normals()
	wood.generate_tangents()
	var mesh := ArrayMesh.new()
	wood.commit(mesh)
	gold.commit(mesh)
	green.commit(mesh)
	bloom.commit(mesh)
	mesh.surface_set_material(0, _bark)
	var leaf := ShaderMaterial.new()
	leaf.shader = load("res://shaders/foliage_v25.gdshader")
	leaf.set_shader_parameter("albedo_tex", load("res://assets/textures/jungle/canopy_leaves.png"))
	leaf.set_shader_parameter("normal_tex", load("res://assets/textures/jungle/canopy_leaves_n.png"))
	leaf.set_shader_parameter("use_normal", true)
	leaf.set_shader_parameter("wind_strength", 0.16)
	leaf.set_shader_parameter("translucency", 0.65)
	leaf.set_shader_parameter("roughness_value", 0.45)
	var leaf_gold: ShaderMaterial = leaf.duplicate()
	leaf_gold.set_shader_parameter("tint", Color(1.9, 1.35, 0.32))
	var leaf_green: ShaderMaterial = leaf.duplicate()
	leaf_green.set_shader_parameter("tint", Color(0.98, 1.1, 0.7))
	var leaf_bloom := ShaderMaterial.new()
	leaf_bloom.shader = load("res://shaders/foliage_v25.gdshader")
	leaf_bloom.set_shader_parameter("albedo_tex", load("res://assets/textures/fees/fleurs_arbre.png"))
	leaf_bloom.set_shader_parameter("wind_strength", 0.16)
	leaf_bloom.set_shader_parameter("translucency", 0.6)
	leaf_bloom.set_shader_parameter("roughness_value", 0.6)
	mesh.surface_set_material(1, leaf_gold)
	mesh.surface_set_material(2, leaf_green)
	mesh.surface_set_material(3, leaf_bloom)
	var mi := MeshInstance3D.new()
	mi.name = "Couronne_Yggdrasil"
	mi.mesh = mesh
	add_child(mi)
	# Les fruits de lumière qui pendent sous la couronne
	var fruit_m: StandardMaterial3D = _glow_mat(Color(1.0, 0.86, 0.5), 3.0)
	var sph := SphereMesh.new()
	sph.radius = 0.35
	sph.height = 0.7
	var cord_m := StandardMaterial3D.new()
	cord_m.albedo_color = Color(0.3, 0.25, 0.18)
	var n_lights: int = 0
	for k in range(40 if pc else 18):
		var e2: Vector3 = ends[_rng.randi() % ends.size()]
		var at: Vector3 = e2 + Vector3(_rng.randf_range(-4, 4), -_rng.randf_range(3.0, 7.0), _rng.randf_range(-4, 4))
		var f := MeshInstance3D.new()
		f.mesh = sph
		f.material_override = fruit_m
		f.position = at
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(f)
		var cord := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.03
		cm.height = 2.0
		cord.mesh = cm
		cord.material_override = cord_m
		cord.position = at + Vector3.UP * 1.2
		add_child(cord)
		if pc and k % 6 == 0 and n_lights < 6:
			var ol := OmniLight3D.new()
			ol.light_color = Color(1.0, 0.85, 0.55)
			ol.light_energy = 1.6
			ol.omni_range = 14.0
			ol.position = at
			add_child(ol)
			n_lights += 1
	# Des lucioles dans la couronne
	_motes("Lucioles_couronne", Vector3(0, CROWN + 40.0, 0), Vector3(50, 24, 50), 260 if pc else 90, Color(1.0, 0.92, 0.55), 0.18)


# =================================================================== l'intérieur (trois salles)

func _build_interior() -> void:
	# Paroi intérieure : un cylindre vu de dedans, écorce sombre
	var nth: int = 64 if pc else 36
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var ys: Array = []
	for k in range(13):
		ys.append(lerpf(0.0, CROWN - 0.9, float(k) / 12.0))
	for k in range(ys.size() - 1):
		for j in range(nth):
			var a0: float = TAU * j / nth
			var a1: float = TAU * (j + 1) / nth
			var r0: float = RI + _n.get_noise_2d(cos(a0) * 5.0, float(ys[k]) * 0.3) * 0.35
			var r1: float = RI + _n.get_noise_2d(cos(a1) * 5.0, float(ys[k]) * 0.3) * 0.35
			var r2: float = RI + _n.get_noise_2d(cos(a0) * 5.0, float(ys[k + 1]) * 0.3) * 0.35
			var r3: float = RI + _n.get_noise_2d(cos(a1) * 5.0, float(ys[k + 1]) * 0.3) * 0.35
			var p0 := Vector3(cos(a0) * r0, ys[k], sin(a0) * r0)
			var p1 := Vector3(cos(a1) * r1, ys[k], sin(a1) * r1)
			var p2 := Vector3(cos(a0) * r2, ys[k + 1], sin(a0) * r2)
			var p3 := Vector3(cos(a1) * r3, ys[k + 1], sin(a1) * r3)
			var uv0 := Vector2(float(j) / nth * 8.0, -float(ys[k]) / 8.0)
			var uv1 := Vector2(float(j + 1) / nth * 8.0, -float(ys[k]) / 8.0)
			var uv2 := Vector2(float(j) / nth * 8.0, -float(ys[k + 1]) / 8.0)
			var uv3 := Vector2(float(j + 1) / nth * 8.0, -float(ys[k + 1]) / 8.0)
			var inward: Vector3 = -Vector3(p0.x, 0, p0.z).normalized()
			var t1: Array = [[p0, uv0], [p2, uv2], [p1, uv1]]
			var t2: Array = [[p1, uv1], [p2, uv2], [p3, uv3]]
			if (p2 - p0).cross(p1 - p0).dot(inward) > 0.0:
				t1 = [[p0, uv0], [p1, uv1], [p2, uv2]]
				t2 = [[p1, uv1], [p3, uv3], [p2, uv2]]
			for tri in [t1, t2]:
				for v in tri:
					st.set_uv(v[1])
					st.add_vertex(v[0])
					faces.append(v[0])
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Yggdrasil_paroi"
	mi.mesh = st.commit()
	mi.material_override = _bark_in
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_body.add_child(cs)
	# Planchers : le dessous de chaque plancher fait le plafond de la salle d'en dessous
	var floor_top: StandardMaterial3D = _wood.duplicate()
	floor_top.albedo_color = Color(0.85, 0.8, 0.75)
	for i in range(FLOORS.size()):
		_disc("Plancher_%d" % i, RI + 0.5, FLOORS[i], 0.6 if i > 0 else 0.4, floor_top, _bark_in)
	# Escaliers de racines, grilles, trous
	for i in range(STAIRS.size()):
		_build_stairs(i)
	# Champignons-étagères lumineux sur la paroi, racines qui pendent, lucioles
	var shelf_cols := [Color(0.5, 0.9, 1.0), Color(0.75, 0.6, 1.0), Color(0.6, 1.0, 0.6)]
	for i in range(3):
		var y0: float = FLOORS[i]
		var top: float = (FLOORS[i + 1] if i < 2 else CROWN) - 0.7
		for k in range(10 if pc else 6):
			var a: float = _rng.randf() * TAU
			var y: float = _rng.randf_range(y0 + 1.6, top - 1.2)
			var root := Node3D.new()
			root.position = Vector3(cos(a) * (RI - 0.15), y, sin(a) * (RI - 0.15))
			root.rotation.y = -a + PI * 0.5
			add_child(root)
			for s in range(_rng.randi_range(2, 4)):
				# un polypore en console : un demi-chapeau qui sort de l'écorce
				var cap := MeshInstance3D.new()
				var r: float = _rng.randf_range(0.35, 0.8)
				cap.mesh = _gfx.cap_mesh(r, 0.3)
				cap.material_override = _gfx.cap_mat(shelf_cols[(k + i) % 3], false, 0.55)
				cap.position = Vector3(_rng.randf_range(-0.5, 0.5), s * 0.45, 0)
				cap.scale = Vector3(1.0, 0.45, 1.0)
				cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(cap)
		# racines qui pendent du plafond
		var curves: Array = []
		for k in range(14 if pc else 8):
			var a2: float = _rng.randf() * TAU
			var r2: float = _rng.randf_range(2.0, RI - 1.5)
			var p := Vector3(cos(a2) * r2, top + 0.6, sin(a2) * r2)
			var l: float = _rng.randf_range(1.5, 4.0)
			curves.append([p, p + Vector3(_rng.randf_range(-0.5, 0.5), -l * 0.5, _rng.randf_range(-0.5, 0.5)), p + Vector3(_rng.randf_range(-0.6, 0.6), -l, _rng.randf_range(-0.6, 0.6)), 0.14, 0.03, 4])
		var hm := MeshInstance3D.new()
		hm.mesh = _gfx.roots_mesh(curves)
		hm.material_override = _gfx.bark()
		hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(hm)
		_motes("Lucioles_salle_%d" % i, Vector3(0, (y0 + top) * 0.5, 0), Vector3(RI - 2.0, (top - y0) * 0.4, RI - 2.0), 70 if pc else 30, Color(0.7, 1.0, 0.6), 0.08)
		if pc:
			for k2 in range(3):
				var a3: float = TAU * k2 / 3.0 + i
				var ol := OmniLight3D.new()
				ol.light_color = [Color(0.6, 1.0, 0.7), Color(1.0, 0.85, 0.5), Color(0.8, 0.7, 1.0)][i]
				ol.light_energy = 1.1
				ol.omni_range = 11.0
				ol.position = Vector3(cos(a3) * 6.0, top - 1.5, sin(a3) * 6.0)
				add_child(ol)
		else:
			var ol2 := OmniLight3D.new()
			ol2.light_color = Color(0.85, 0.95, 0.8)
			ol2.light_energy = 1.4
			ol2.omni_range = 16.0
			ol2.position = Vector3(0, top - 2.0, 0)
			add_child(ol2)
	points["entree"] = Vector3(0, FLOORS[0], RI - 2.4)
	points["sortie"] = Vector3(0, FLOORS[0], RI - 1.0)


func _stair_point(i: int, t: float, r: float) -> Vector3:
	var a: float = float(STAIRS[i][0]) + float(STAIRS[i][1]) * STAIR_SPAN * t
	var top: float = FLOORS[i + 1] if i < 2 else CROWN
	return Vector3(cos(a) * r, lerpf(FLOORS[i], top, t), sin(a) * r)


func _build_stairs(i: int) -> void:
	var steps: int = 16
	var step_m: StandardMaterial3D = _wood.duplicate()
	step_m.uv1_triplanar = true
	step_m.uv1_scale = Vector3(0.12, 0.12, 0.12)
	step_m.albedo_color = Color(0.7, 0.6, 0.5)
	for s in range(steps):
		var t: float = (float(s) + 0.5) / steps
		var p: Vector3 = _stair_point(i, t, RI - 1.1)
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.0, 0.42, 0.95)
		box.mesh = bm
		box.material_override = step_m
		box.position = p - Vector3.UP * 0.21
		var tang: Vector3 = (_stair_point(i, t + 0.02, RI - 1.1) - _stair_point(i, t - 0.02, RI - 1.1)) * Vector3(1, 0, 1)
		box.basis = Basis.looking_at(tang.normalized(), Vector3.UP)
		add_child(box)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bm.size
		cs.shape = bs
		cs.transform = box.transform
		_body.add_child(cs)
	# le limon : une grosse racine qui porte les marches, contre la paroi
	var lim: Array = []
	var lr: Array = []
	for k in range(13):
		var t2: float = float(k) / 12.0
		lim.append(_stair_point(i, t2, RI - 0.55) + Vector3.DOWN * 0.45)
		lr.append(0.42 - 0.12 * t2)
	var lst := SurfaceTool.new()
	lst.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(lst, lim, lr, 10, 1.0)
	lst.generate_normals()
	lst.generate_tangents()
	var lmi := MeshInstance3D.new()
	lmi.mesh = lst.commit()
	lmi.material_override = _bark
	add_child(lmi)
	# Le trou dans le plafond (en haut de l'escalier) et, à l'étage, son bord de racines
	var hole_top: Vector3 = _stair_point(i, 1.0, RI - 2.6)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0, 0, 0)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var under := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 1.5
	dm.bottom_radius = 1.5
	dm.height = 0.02
	under.mesh = dm
	under.material_override = dark
	var ceil_y: float = (FLOORS[i + 1] - 0.6) if i < 2 else (CROWN - 1.0)
	under.position = Vector3(hole_top.x, ceil_y - 0.02, hole_top.z)
	add_child(under)
	var over := MeshInstance3D.new()
	over.mesh = dm
	over.material_override = dark
	over.position = Vector3(hole_top.x, hole_top.y + 0.02, hole_top.z)
	add_child(over)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.45
	tm.outer_radius = 1.95
	tm.rings = 24
	tm.ring_segments = 8
	rim.mesh = tm
	rim.material_override = _bark
	rim.scale = Vector3(1, 0.6, 1)
	rim.position = over.position + Vector3.UP * 0.08
	add_child(rim)
	points["trou_%d" % (i + 1)] = Vector3(hole_top.x, hole_top.y, hole_top.z)
	var arr_dir: Vector3 = -Vector3(hole_top.x, 0, hole_top.z).normalized()
	points["arrivee_%d" % (i + 1)] = Vector3(hole_top.x, hole_top.y, hole_top.z) + arr_dir * 2.4
	points["escalier_%d" % i] = _stair_point(i, 0.0, RI - 3.2)
	# La grille de racines qui ferme le pied de l'escalier
	var gate := Node3D.new()
	gate.name = "Grille_racines_%d" % i
	var foot: Vector3 = _stair_point(i, 0.06, RI - 1.1)
	gate.position = foot
	add_child(gate)
	var curves: Array = []
	var tang2: Vector3 = (_stair_point(i, 0.1, RI - 1.1) - _stair_point(i, 0.0, RI - 1.1)).normalized()
	var across: Vector3 = Vector3(foot.x, 0, foot.z).normalized()
	for k in range(9):
		var off: Vector3 = across * lerpf(-1.4, 1.4, float(k) / 8.0)
		var a := off + Vector3.DOWN * 0.3
		var b := off + Vector3.UP * 3.6 + tang2 * 0.3
		var c := a.lerp(b, 0.5) + tang2 * _rng.randf_range(-0.6, 0.6) + across * _rng.randf_range(-0.4, 0.4)
		curves.append([a, c, b, 0.16, 0.07, 4])
	for k2 in range(4):
		var y: float = 0.6 + k2 * 0.85
		var a2: Vector3 = -across * 1.6 + Vector3.UP * y
		var b2: Vector3 = across * 1.6 + Vector3.UP * (y + _rng.randf_range(-0.3, 0.3))
		curves.append([a2, (a2 + b2) * 0.5 + tang2 * 0.35, b2, 0.12, 0.08, 4])
	var gm := MeshInstance3D.new()
	gm.mesh = _gfx.roots_mesh(curves)
	gm.material_override = _gfx.bark()
	gate.add_child(gm)
	var gcs := CollisionShape3D.new()
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(3.4, 4.0, 0.6)
	gcs.shape = gbs
	gcs.transform = Transform3D(Basis.looking_at(tang2 * Vector3(1, 0, 1) if absf(tang2.y) < 0.99 else Vector3.FORWARD, Vector3.UP), foot + Vector3.UP * 1.8)
	_body.add_child(gcs)
	gate.set_meta("shape", gcs)
	gates.append(gate)


func open_gate(i: int, instant: bool) -> void:
	if i < 0 or i >= gates.size():
		return
	var g: Node3D = gates[i]
	var cs: CollisionShape3D = g.get_meta("shape")
	cs.disabled = true
	if instant:
		g.visible = false
		return
	var tw := create_tween()
	tw.tween_property(g, "scale", Vector3(1.0, 0.02, 1.0), 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): g.visible = false)


func close_gate(i: int) -> void:
	if i < 0 or i >= gates.size():
		return
	var g: Node3D = gates[i]
	(g.get_meta("shape") as CollisionShape3D).disabled = false
	g.visible = true
	g.scale = Vector3.ONE


# =================================================================== la porte aux runes

func _build_door() -> void:
	var r: float = trunk_r(DOOR_ANGLE, 0.0)
	var r_top: float = trunk_r(DOOR_ANGLE, 6.6)
	door = Node3D.new()
	door.name = "Porte_Yggdrasil"
	door.position = Vector3(0, 0, r + 0.14)
	door.rotation.x = -atan2(r - r_top, 6.6)
	add_child(door)
	var w: float = 3.4
	var h: float = 6.6
	# le passage sombre derrière les vantaux
	var dark := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	dark.mesh = qm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_texture = load("res://assets/textures/fees/runes_porte.png")
	dmat.albedo_color = Color(0.0, 0.0, 0.0)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	dmat.alpha_scissor_threshold = 0.5
	dmat.emission_enabled = true
	dmat.emission = Color(0.1, 0.22, 0.12)
	dmat.emission_energy_multiplier = 0.15
	dark.material_override = dmat
	dark.position = Vector3(0, h * 0.5, -0.04)
	door.add_child(dark)
	door_runes = StandardMaterial3D.new()
	door_runes.albedo_texture = load("res://assets/textures/fees/runes_porte.png")
	door_runes.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	door_runes.alpha_scissor_threshold = 0.5
	door_runes.emission_enabled = true
	door_runes.emission_texture = load("res://assets/textures/fees/runes_porte_lueur.png")
	door_runes.emission_energy_multiplier = 2.5
	door_runes.roughness = 0.9
	door_runes.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "Vantail_%s" % ("g" if side < 0 else "d")
		hinge.position = Vector3(side * w * 0.5, 0, 0)
		door.add_child(hinge)
		var leaf := MeshInstance3D.new()
		var lm := QuadMesh.new()
		lm.size = Vector2(w * 0.5, h)
		lm.center_offset = Vector3(-side * w * 0.25, h * 0.5, 0)
		leaf.mesh = lm
		var mat: StandardMaterial3D = door_runes.duplicate()
		mat.uv1_scale = Vector3(0.5, 1.0, 1.0)
		mat.uv1_offset = Vector3(0.0 if side < 0 else 0.5, 0.0, 0.0)
		leaf.material_override = mat
		hinge.add_child(leaf)
		door_leaves.append([hinge, side, mat])
	# l'encadrement : des racines en arc autour de la porte
	var curves: Array = []
	for side2 in [-1.0, 1.0]:
		curves.append([Vector3(side2 * (w * 0.5 + 0.3), -0.4, 0.1), Vector3(side2 * (w * 0.5 + 0.55), h * 0.55, 0.3), Vector3(side2 * 0.2, h + 0.3, 0.2), 0.62, 0.32, 7])
		curves.append([Vector3(side2 * (w * 0.5 + 1.2), -0.4, -0.2), Vector3(side2 * (w * 0.5 + 1.2), h * 0.4, 0.2), Vector3(side2 * (w * 0.5 + 0.4), h * 0.85, 0.1), 0.3, 0.1, 6])
	var fm := MeshInstance3D.new()
	fm.mesh = _gfx.roots_mesh(curves)
	fm.material_override = _bark_2s
	door.add_child(fm)
	var gl := OmniLight3D.new()
	gl.name = "Lueur_porte"
	gl.light_color = Color(0.55, 1.0, 0.75)
	gl.light_energy = 1.4
	gl.omni_range = 9.0
	gl.position = Vector3(0, 3.0, 1.5)
	door.add_child(gl)
	points["porte"] = Vector3(0, 0, r + 1.6)
	points["porte_dehors"] = Vector3(0, 0, r + 3.2)
	door.visible = false


func show_door(on: bool, animate: bool) -> void:
	if door == null:
		return
	if not on:
		door.visible = false
		return
	if door.visible:
		return
	door.visible = true
	if animate:
		door.scale = Vector3(0.05, 0.05, 0.05)
		create_tween().tween_property(door, "scale", Vector3.ONE, 3.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for l in door_leaves:
			var m: StandardMaterial3D = l[2]
			m.emission_energy_multiplier = 12.0
			create_tween().tween_property(m, "emission_energy_multiplier", 2.5, 4.0)
	else:
		door.scale = Vector3.ONE


func open_door(open: bool, animate: bool) -> void:
	for l in door_leaves:
		var hinge: Node3D = l[0]
		var goal: float = (float(l[1]) * 1.75) if open else 0.0
		if animate:
			create_tween().tween_property(hinge, "rotation:y", goal, 1.4).set_trans(Tween.TRANS_SINE)
		else:
			hinge.rotation.y = goal


# =================================================================== salle 0 : les lucioles

func _build_lucioles_room() -> void:
	var y: float = FLOORS[0]
	# le bassin des lucioles, au centre
	var basin := Node3D.new()
	basin.name = "Bassin_lucioles"
	basin.position = Vector3(0, y, 0)
	add_child(basin)
	var stone: Material = Rocks.material(Color(0.7, 0.72, 0.68), 0.6, 0.25)
	var bm := MeshInstance3D.new()
	bm.mesh = _gfx.stem_mesh(0.55, 0.9, false)
	bm.material_override = stone
	basin.add_child(bm)
	var bowl := MeshInstance3D.new()
	bowl.mesh = _gfx.cap_mesh(1.2, 0.35)
	bowl.material_override = stone
	bowl.rotation.x = PI
	bowl.position = Vector3(0, 1.25, 0)
	basin.add_child(bowl)
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 1.05
	wm.bottom_radius = 1.05
	wm.height = 0.02
	water.mesh = wm
	water.material_override = _glow_mat(Color(0.5, 1.0, 0.75), 1.2, 0.8)
	water.position = Vector3(0, 1.18, 0)
	basin.add_child(water)
	basin_light = OmniLight3D.new()
	basin_light.light_color = Color(0.6, 1.0, 0.75)
	basin_light.light_energy = 1.5
	basin_light.omni_range = 8.0
	basin_light.position = Vector3(0, 1.8, 0)
	basin.add_child(basin_light)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 1.3
	cs.shape = cyl
	cs.position = Vector3(0, y + 0.65, 0)
	_body.add_child(cs)
	points["bassin"] = Vector3(0, y, 0)
	# la luciole-guide
	firefly = Node3D.new()
	firefly.name = "Luciole_guide"
	var fm := MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = 0.12
	fs.height = 0.24
	fm.mesh = fs
	fm.material_override = _glow_mat(Color(1.0, 0.95, 0.6), 6.0)
	firefly.add_child(fm)
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.92, 0.6)
	fl.light_energy = 2.0
	fl.omni_range = 4.0
	firefly.add_child(fl)
	firefly.position = Vector3(0, y + 1.6, 0)
	firefly.visible = false
	add_child(firefly)
	# les cinq pierres-runes
	var rune_mesh := TorusMesh.new()
	rune_mesh.inner_radius = 0.32
	rune_mesh.outer_radius = 0.42
	rune_mesh.rings = 24
	rune_mesh.ring_segments = 6
	for k in range(5):
		var a: float = TAU * k / 5.0 + 0.3
		var p := Vector3(cos(a) * 6.0, y, sin(a) * 6.0)
		var node := Node3D.new()
		node.name = "Pierre_rune_%d" % k
		node.position = p
		add_child(node)
		var slab := MeshInstance3D.new()
		slab.mesh = Rocks.shape(9580 + k, Vector3(1.6, 0.35, 1.5), 0.85, 0.12, 2.5, 18)
		slab.material_override = stone
		slab.position = Vector3(0, 0.08, 0)
		node.add_child(slab)
		var mat: StandardMaterial3D = _glow_mat(STONE_COLORS[k], 0.35)
		var ring := MeshInstance3D.new()
		ring.mesh = rune_mesh
		ring.material_override = mat
		ring.scale = Vector3(1, 0.3, 1)
		ring.position = Vector3(0, 0.3, 0)
		node.add_child(ring)
		# un petit signe au centre (une rune en relief)
		var sig := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(0.08, 0.04, 0.42)
		sig.mesh = sb
		sig.material_override = mat
		sig.position = Vector3(0, 0.3, 0)
		sig.rotation.y = a
		node.add_child(sig)
		var sig2 := MeshInstance3D.new()
		var sb2 := BoxMesh.new()
		sb2.size = Vector3(0.3, 0.04, 0.08)
		sig2.mesh = sb2
		sig2.material_override = mat
		sig2.position = Vector3(0.05 * (k - 2), 0.3, 0.06 * (k % 3 - 1))
		sig2.rotation.y = a + 0.5 * k
		node.add_child(sig2)
		var ol := OmniLight3D.new()
		ol.light_color = STONE_COLORS[k]
		ol.light_energy = 0.0
		ol.omni_range = 4.5
		ol.position = Vector3(0, 0.8, 0)
		node.add_child(ol)
		stones.append({"node": node, "mat": mat, "light": ol, "pos": p})


func stone_glow(i: int, amount: float) -> void:
	var s: Dictionary = stones[i]
	(s["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.35 + amount * 5.0
	(s["light"] as OmniLight3D).light_energy = amount * 2.2


func stones_flash(c: Color) -> void:
	for s in stones:
		var m: StandardMaterial3D = s["mat"]
		var keep: Color = m.emission
		m.emission = c
		m.emission_energy_multiplier = 4.0
		var tw := create_tween()
		tw.tween_property(m, "emission_energy_multiplier", 0.35, 0.9)
		tw.tween_callback(func(): m.emission = keep)


# =================================================================== salle 1 : la sève

func _build_seve_room() -> void:
	var y: float = FLOORS[1]
	var h: float = 1.5
	source_pos = Vector3(-RI + 0.5, y + h, 0)
	var w_angle: float = 0.5
	heart_pos = Vector3(cos(w_angle) * (RI - 0.6), y + h, sin(w_angle) * (RI - 0.6))
	# la source de sève : un nœud du bois d'où coule une lumière d'ambre
	var src := MeshInstance3D.new()
	src.mesh = _gfx.cap_mesh(0.9, 0.6)
	src.material_override = _glow_mat(Color(1.0, 0.7, 0.25), 3.0)
	src.position = source_pos + Vector3(-0.2, 0, 0)
	src.rotation.z = -PI * 0.5
	add_child(src)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.75, 0.35)
	sl.light_energy = 1.8
	sl.omni_range = 6.0
	sl.position = source_pos + Vector3(0.8, 0, 0)
	add_child(sl)
	# le cœur de bois : une loupe noueuse dans la paroi, éteinte tant que la lumière n'y arrive pas
	var heart := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.9
	hs.height = 1.6
	heart.mesh = hs
	heart_mat = StandardMaterial3D.new()
	heart_mat.albedo_texture = load("res://assets/textures/fees/ecorce_ygg.png")
	heart_mat.albedo_color = Color(0.8, 0.62, 0.45)
	heart_mat.emission_enabled = true
	heart_mat.emission = Color(1.0, 0.75, 0.3)
	heart_mat.emission_energy_multiplier = 0.0
	heart.material_override = heart_mat
	heart.position = heart_pos + Vector3(cos(w_angle), 0, sin(w_angle)) * 0.3
	add_child(heart)
	heart_light = OmniLight3D.new()
	heart_light.light_color = Color(1.0, 0.8, 0.4)
	heart_light.light_energy = 0.0
	heart_light.omni_range = 9.0
	heart_light.position = heart_pos - Vector3(cos(w_angle), 0, sin(w_angle)) * 1.0
	add_child(heart_light)
	# les trois fleurs-miroirs
	var mpos := [Vector3(-4.0, y + h, 0.0), Vector3(2.5, y + h, -5.5), Vector3(4.5, y + h, 4.5)]
	var stem_m := StandardMaterial3D.new()
	stem_m.albedo_color = Color(0.3, 0.5, 0.22)
	stem_m.roughness = 0.6
	var petal_m := StandardMaterial3D.new()
	petal_m.albedo_color = Color(0.95, 0.95, 1.0)
	petal_m.metallic = 0.9
	petal_m.roughness = 0.08
	var rim_m: StandardMaterial3D = _glow_mat(Color(0.9, 0.8, 1.0), 0.6)
	for k in range(3):
		var p: Vector3 = mpos[k]
		var root := Node3D.new()
		root.name = "Fleur_miroir_%d" % k
		root.position = Vector3(p.x, y, p.z)
		add_child(root)
		var stem := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.12
		cm.height = h
		stem.mesh = cm
		stem.material_override = stem_m
		stem.position = Vector3(0, h * 0.5, 0)
		root.add_child(stem)
		for lf in range(3):
			var leaf := MeshInstance3D.new()
			var ls := SphereMesh.new()
			ls.radius = 0.35
			ls.height = 0.7
			leaf.mesh = ls
			leaf.material_override = stem_m
			leaf.scale = Vector3(1.0, 0.1, 0.4)
			var la: float = TAU * lf / 3.0
			leaf.position = Vector3(cos(la) * 0.35, 0.15 + lf * 0.1, sin(la) * 0.35)
			leaf.rotation.y = -la
			root.add_child(leaf)
		var head := Node3D.new()
		head.position = Vector3(0, h, 0)
		root.add_child(head)
		# le miroir : un disque d'argent poli, cerné de pétales
		var mirror := MeshInstance3D.new()
		var mm := CylinderMesh.new()
		mm.top_radius = 0.42
		mm.bottom_radius = 0.42
		mm.height = 0.05
		mirror.mesh = mm
		mirror.material_override = petal_m
		mirror.rotation.x = PI * 0.5
		head.add_child(mirror)
		for pt in range(8):
			var pa: float = TAU * pt / 8.0
			var petal := MeshInstance3D.new()
			var ps := SphereMesh.new()
			ps.radius = 0.22
			ps.height = 0.44
			petal.mesh = ps
			petal.material_override = rim_m
			petal.scale = Vector3(0.5, 1.0, 0.15)
			petal.position = Vector3(cos(pa) * 0.55, sin(pa) * 0.55, -0.02)
			petal.rotation.z = pa - PI * 0.5
			head.add_child(petal)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.3
		cyl.height = h
		cs.shape = cyl
		cs.position = Vector3(p.x, y + h * 0.5, p.z)
		_body.add_child(cs)
		mirrors.append({"pos": p, "head": head, "root": root})
	# Les cibles possibles d'une fleur (murs, fleurs, cœur)
	mirror_targets = {
		"M0": mpos[0], "M1": mpos[1], "M2": mpos[2], "H": heart_pos,
		"mur_n": Vector3(-2.0, y + h, -RI + 0.6), "mur_s": Vector3(-3.0, y + h, RI - 0.7),
		"mur_e": Vector3(RI - 0.6, y + h, -3.0), "mur_o": Vector3(-RI + 0.7, y + h, 5.0),
		"mur_ne": Vector3(6.5, y + h, -8.5), "mur_se": Vector3(1.5, y + h, RI - 0.6),
	}
	beam_root = Node3D.new()
	beam_root.name = "Rayon_seve"
	add_child(beam_root)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.albedo_color = Color(1.0, 0.8, 0.35, 0.75)
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	points["seve_source"] = source_pos


## Le rayon de sève : une suite de segments ; strength (1..4) l'élargit et l'éclaire.
func set_beam(path: Array, strength: int) -> void:
	for c in beam_root.get_children():
		c.queue_free()
	for k in range(path.size() - 1):
		var a: Vector3 = path[k]
		var b: Vector3 = path[k + 1]
		var w: float = 0.05 + 0.03 * mini(k, 3)
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = w
		cm.bottom_radius = w
		cm.height = a.distance_to(b)
		cm.radial_segments = 8
		cm.rings = 1
		seg.mesh = cm
		var m: StandardMaterial3D = _beam_mat.duplicate()
		m.albedo_color = Color(1.0, 0.8 + 0.05 * k, 0.35 + 0.1 * k, 0.45 + 0.15 * mini(k, 3))
		seg.material_override = m
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dir: Vector3 = (b - a).normalized()
		var side: Vector3 = dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
		seg.transform = Transform3D(Basis(side, dir, side.cross(dir)), (a + b) * 0.5)
		beam_root.add_child(seg)
	var lit: bool = strength >= 4
	heart_mat.emission_energy_multiplier = 3.0 if lit else (0.6 if strength > 0 else 0.0)
	heart_light.light_energy = 2.5 if lit else (0.4 if strength > 0 else 0.0)


## Oriente la tête d'une fleur-miroir entre le rayon qui arrive et celui qui repart.
func aim_mirror(i: int, from: Vector3, to: Vector3) -> void:
	var head: Node3D = mirrors[i]["head"]
	var p: Vector3 = mirrors[i]["pos"]
	var a: Vector3 = (from - p).normalized()
	var b: Vector3 = (to - p).normalized()
	var n: Vector3 = (a + b)
	if n.length() < 0.05:
		n = a
	n = n.normalized()
	var goal: Quaternion = Basis.looking_at(-n, Vector3.UP).get_rotation_quaternion()
	var tw := create_tween()
	tw.tween_property(head, "quaternion", goal, 0.35).set_trans(Tween.TRANS_SINE)


# =================================================================== salle 2 : les saisons

func _build_saisons_room() -> void:
	var y: float = FLOORS[2]
	var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]   # N, E, S, O
	var stone: Material = Rocks.material(Color(0.78, 0.76, 0.72), 0.5, 0.25)
	for k in range(4):
		var p: Vector3 = dirs[k] * 6.0 + Vector3(0, y, 0)
		var root := Node3D.new()
		root.name = "Fleur_saison_%d" % k
		root.position = p
		add_child(root)
		var ped := MeshInstance3D.new()
		ped.mesh = _gfx.stem_mesh(0.45, 1.0, false)
		ped.material_override = stone
		root.add_child(ped)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.6
		cyl.height = 1.0
		cs.shape = cyl
		cs.position = p + Vector3.UP * 0.5
		_body.add_child(cs)
		var bloom := Node3D.new()
		bloom.position = Vector3(0, 1.05, 0)
		root.add_child(bloom)
		var mats: Array = []
		for pt in range(7):
			var pa: float = TAU * pt / 7.0
			var petal := MeshInstance3D.new()
			var ps := SphereMesh.new()
			ps.radius = 0.32
			ps.height = 0.64
			petal.mesh = ps
			var m: StandardMaterial3D = _glow_mat(SEASON_COLORS[0], 0.8)
			petal.material_override = m
			mats.append(m)
			petal.scale = Vector3(0.45, 0.12, 1.0)
			petal.position = Vector3(cos(pa) * 0.32, 0.12, sin(pa) * 0.32)
			petal.rotation = Vector3(0.0, -pa + PI * 0.5, 0.0)
			petal.rotate_object_local(Vector3.RIGHT, -0.5)
			bloom.add_child(petal)
		var heart := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.14
		hs.height = 0.28
		heart.mesh = hs
		heart.material_override = _glow_mat(Color(1.0, 0.9, 0.5), 2.0)
		heart.position = Vector3(0, 0.18, 0)
		bloom.add_child(heart)
		var ol := OmniLight3D.new()
		ol.light_color = SEASON_COLORS[0]
		ol.light_energy = 1.0
		ol.omni_range = 4.0
		ol.position = Vector3(0, 1.7, 0)
		root.add_child(ol)
		pedestals.append({"pos": p, "mats": mats, "light": ol, "bloom": bloom})
	# la stèle de l'énigme, près de l'arrivée
	var a2: float = 1.3
	var sp := Vector3(cos(a2) * (RI - 1.6), y, sin(a2) * (RI - 1.6))
	var stele := MeshInstance3D.new()
	stele.mesh = Rocks.shape(9590, Vector3(1.3, 2.2, 0.45), 0.9, 0.06, 2.5, 16)
	stele.material_override = stone
	stele.position = sp + Vector3.UP * 1.0
	stele.rotation.y = -a2 + PI * 0.5
	add_child(stele)
	var txt := Label3D.new()
	txt.text = "Il naît : tout s'éveille.\nIl règne : tout flamboie.\nIl meurt : tout s'effeuille.\nOù il ne va jamais, tout dort."
	txt.font_size = 40
	txt.pixel_size = 0.0032
	txt.width = 380
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.modulate = Color(0.75, 1.0, 0.8)
	txt.outline_size = 0
	var nrm: Vector3 = -Vector3(sp.x, 0, sp.z).normalized()
	txt.position = sp + Vector3.UP * 1.5 + nrm * 0.3
	txt.basis = Basis.looking_at(-nrm, Vector3.UP)
	add_child(txt)
	var scs := CollisionShape3D.new()
	var sbs := BoxShape3D.new()
	sbs.size = Vector3(1.2, 2.2, 0.5)
	scs.shape = sbs
	scs.transform = Transform3D(stele.basis, stele.position)
	_body.add_child(scs)
	points["stele"] = sp + nrm * 0.9


func set_season(i: int, s: int, animate: bool) -> void:
	var p: Dictionary = pedestals[i]
	var c: Color = SEASON_COLORS[s]
	for m in p["mats"]:
		(m as StandardMaterial3D).albedo_color = c
		(m as StandardMaterial3D).emission = c
	(p["light"] as OmniLight3D).light_color = c
	var bloom: Node3D = p["bloom"]
	# printemps : bouton serré ; été : grand ouvert ; automne : penché ; hiver : refermé, givré
	var open_k: float = [0.6, 1.25, 1.0, 0.45][s]
	var tilt: float = [0.0, 0.0, 0.35, 0.0][s]
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(bloom, "scale", Vector3(open_k, 1.0, open_k), 0.5).set_trans(Tween.TRANS_BACK)
		tw.tween_property(bloom, "rotation:x", tilt, 0.5)
	else:
		bloom.scale = Vector3(open_k, 1.0, open_k)
		bloom.rotation.x = tilt


func seasons_glow(on: bool) -> void:
	for p in pedestals:
		(p["light"] as OmniLight3D).light_energy = 2.4 if on else 1.0
		for m in p["mats"]:
			(m as StandardMaterial3D).emission_energy_multiplier = 2.5 if on else 0.8


# =================================================================== l'esprit de l'arbre

func _build_spirit() -> void:
	spirit = Node3D.new()
	spirit.name = "Esprit_Yggdrasil"
	spirit.position = Vector3(0, CROWN + 0.4, 0)
	add_child(spirit)
	var body := Node3D.new()
	body.name = "Corps"
	spirit.add_child(body)
	var robe: StandardMaterial3D = _glow_mat(Color(0.45, 0.85, 0.5), 0.9, 0.3)
	# le visage : un masque d'écorce clair, doucement lumineux
	var light_m := StandardMaterial3D.new()
	light_m.albedo_texture = load("res://assets/textures/fees/ecorce_ygg.png")
	light_m.albedo_color = Color(1.0, 0.95, 0.85)
	light_m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	light_m.emission_enabled = true
	light_m.emission = Color(0.4, 0.6, 0.35)
	light_m.emission_energy_multiplier = 0.5
	light_m.roughness = 0.8
	var wood_m: StandardMaterial3D = _glow_mat(Color(0.75, 0.6, 0.35), 0.8, 0.85)
	_spirit_mats = [robe, light_m, wood_m]
	# une longue robe de feuilles et de lumière
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 1.2
	cm.height = 2.4
	cm.radial_segments = 24
	cone.mesh = cm
	cone.material_override = robe
	cone.position = Vector3(0, 1.2, 0)
	body.add_child(cone)
	var chest := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.45
	cs.height = 1.1
	chest.mesh = cs
	chest.material_override = robe
	chest.position = Vector3(0, 2.5, 0)
	body.add_child(chest)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.3
	hs.height = 0.66
	head.mesh = hs
	head.material_override = light_m
	head.position = Vector3(0, 3.2, 0)
	body.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.065
		es.height = 0.11
		eye.mesh = es
		eye.material_override = _glow_mat(Color(0.25, 1.0, 0.55), 7.0)
		eye.position = Vector3(sx * 0.11, 3.24, 0.26)
		body.add_child(eye)
		# des bras comme des branches souples
		var arm_path: Array = [Vector3(sx * 0.35, 2.7, 0), Vector3(sx * 0.8, 2.3, 0.2), Vector3(sx * 1.0, 1.8, 0.45), Vector3(sx * 0.9, 1.5, 0.6)]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tube(st, arm_path, [0.11, 0.09, 0.07, 0.04], 8, 1.0)
		st.generate_normals()
		var am := MeshInstance3D.new()
		am.mesh = st.commit()
		am.material_override = wood_m
		body.add_child(am)
	# une couronne de bois de cerf, en branches
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx2 in [-1.0, 1.0]:
		var p0 := Vector3(sx2 * 0.18, 3.42, 0)
		var p1: Vector3 = p0 + Vector3(sx2 * 0.35, 0.45, -0.05)
		var p2: Vector3 = p1 + Vector3(sx2 * 0.25, 0.45, 0.0)
		_tube(st2, [p0, p1, p2], [0.05, 0.04, 0.015], 6, 1.0)
		_tube(st2, [p1, p1 + Vector3(sx2 * -0.05, 0.4, 0.1)], [0.035, 0.012], 6, 1.0)
		_tube(st2, [p0.lerp(p1, 0.5), p0.lerp(p1, 0.5) + Vector3(sx2 * 0.3, 0.12, 0.05)], [0.03, 0.01], 6, 1.0)
	st2.generate_normals()
	var antl := MeshInstance3D.new()
	antl.mesh = st2.commit()
	antl.material_override = wood_m
	body.add_child(antl)
	var leaf_m := StandardMaterial3D.new()
	leaf_m.albedo_texture = load("res://assets/textures/jungle/canopy_leaves.png")
	leaf_m.albedo_color = Color(0.75, 1.0, 0.7)
	leaf_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaf_m.alpha_scissor_threshold = 0.5
	leaf_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_m.emission_enabled = true
	leaf_m.emission = Color(0.35, 0.8, 0.4)
	leaf_m.emission_energy_multiplier = 0.9
	_spirit_mats.append(leaf_m)
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 1.05)
	# la cape : des feuilles posées en écailles, du cou jusqu'au sol
	for row in range(4):
		var y: float = 2.45 - row * 0.55
		var rad: float = 0.42 + row * 0.2
		var n_l: int = 7 + row * 2
		for k in range(n_l):
			var a: float = TAU * k / n_l + row * 0.3
			var lf := MeshInstance3D.new()
			lf.mesh = q
			lf.material_override = leaf_m
			lf.position = Vector3(cos(a) * rad, y, sin(a) * rad)
			lf.rotation = Vector3(0.0, -a + PI * 0.5, 0.0)
			lf.rotate_object_local(Vector3.RIGHT, -0.45)
			lf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			body.add_child(lf)
	# la chevelure : des lianes fleuries qui tombent dans le dos
	var st3 := SurfaceTool.new()
	st3.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k2 in range(9):
		var a2: float = PI * 0.5 + (float(k2) / 8.0 - 0.5) * 2.2
		var top := Vector3(cos(a2) * 0.22, 3.35, -absf(sin(a2)) * 0.2 - 0.05)
		var vp: Array = []
		var vr: Array = []
		for s4 in range(6):
			var t4: float = float(s4) / 5.0
			vp.append(top + Vector3(cos(a2) * 0.25 * t4, -1.6 * t4, -0.25 - 0.2 * t4 + sin(t4 * 6.0 + k2) * 0.05))
			vr.append(0.035 - 0.02 * t4)
		_tube(st3, vp, vr, 5, 1.0)
	st3.generate_normals()
	var hair := MeshInstance3D.new()
	hair.mesh = st3.commit()
	hair.material_override = wood_m
	body.add_child(hair)
	var halo := OmniLight3D.new()
	halo.light_color = Color(0.75, 1.0, 0.8)
	halo.light_energy = 3.0
	halo.omni_range = 12.0
	halo.position = Vector3(0, 2.6, 0)
	spirit.add_child(halo)
	_motes_on(spirit, "Feuilles_esprit", Vector3(0, 1.6, 0), Vector3(1.6, 1.8, 1.6), 60 if pc else 26, Color(0.75, 1.0, 0.65), 0.1)
	spirit.visible = false


func show_spirit(on: bool, animate: bool) -> void:
	if on == spirit.visible:
		return
	spirit.visible = on
	if on and animate:
		spirit.scale = Vector3(0.05, 0.05, 0.05)
		create_tween().tween_property(spirit, "scale", Vector3.ONE, 2.5).set_trans(Tween.TRANS_SINE)


# =================================================================== le cercle de retour

func _build_circle() -> void:
	circle = Node3D.new()
	circle.name = "Cercle_retour"
	var c := Vector3(-5.0, CROWN + 0.03, 5.0)
	circle.position = c
	add_child(circle)
	var gm: StandardMaterial3D = _glow_mat(Color(0.65, 1.0, 0.85), 3.0, 0.6)
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in range(3):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0 + k * 0.45
		tm.outer_radius = 1.12 + k * 0.45
		tm.rings = 48
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = gm
		ring.scale = Vector3(1, 0.1, 1)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.name = "Anneau_%d" % k
		circle.add_child(ring)
	var col := OmniLight3D.new()
	col.light_color = Color(0.65, 1.0, 0.85)
	col.light_energy = 2.0
	col.omni_range = 7.0
	col.position = Vector3(0, 1.2, 0)
	circle.add_child(col)
	_motes_on(circle, "Colonne_lueurs", Vector3(0, 1.6, 0), Vector3(1.2, 1.6, 1.2), 70 if pc else 30, Color(0.7, 1.0, 0.85), 0.12)
	points["cercle"] = c
	circle.visible = false


func _process(delta: float) -> void:
	_clock += delta
	if spirit != null and spirit.visible:
		var b: Node3D = spirit.get_node("Corps")
		b.position.y = sin(_clock * 1.2) * 0.12
		b.rotation.y = sin(_clock * 0.4) * 0.25
	if circle != null and circle.visible:
		for k in range(3):
			(circle.get_node("Anneau_%d" % k) as Node3D).rotation.y = _clock * (0.6 - k * 0.25)


# =================================================================== lueurs

func _motes(label: String, at: Vector3, box: Vector3, amount: int, color: Color, size: float) -> void:
	_motes_on(self, label, at, box, amount, color, size)


func _motes_on(parent: Node3D, label: String, at: Vector3, box: Vector3, amount: int, color: Color, size: float) -> void:
	var p := GPUParticles3D.new()
	p.name = label
	p.amount = amount
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.position = at
	p.visibility_aabb = AABB(-box - Vector3(4, 4, 4), box * 2.0 + Vector3(8, 8, 8))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.4
	pm.gravity = Vector3(0, 0.05, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.2, color)
	fade.add_point(0.8, color)
	fade.set_color(fade.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.25, Color(1, 1, 1, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	m.albedo_texture = t
	quad.material = m
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


func at(key: String) -> Vector3:
	return to_global(points[key])

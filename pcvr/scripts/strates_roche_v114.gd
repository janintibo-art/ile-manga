extends Node3D
## V114 : la roche des Strates et de la Fronde, sous Hautefond (le maillage taillé par
## tools/generate_strates_v114.py : la Grande Strate, ses deux Galeries, les Mines et la Grotte aux
## Cristaux, les Jardins des Champignons, le Gouffre, la Fronde) : la roche en grès à couches
## (shaders/strates_v114.gdshader) et sa collision ; les stalactites ; les grappes de cristaux bleus et
## violets de la Grotte ; la mousse et les vers luisants des Jardins et de la Fronde.
## Repère local : x vers l'est, z vers le sud, depuis le centre de la Grande Colonne ; y absolu.
## Tout ce qui se marche ici est sous y = -40 (main._in_dungeon_v35 : pas de limites à pied, pas de
## nage ; donjon_v35.update_inside : la lumière d'intérieur).

const BIN := "res://assets/models/strates114/roche.bin"
const SHADER := "res://shaders/strates_v114.gdshader"
const Corps = preload("res://scripts/pnj/corps_v64.gd")
const O := Vector3(-980.0, 0.0, 1420.0)

## (gardés en accord avec tools/generate_strates_v114.py)
const F0: float = -96.0
const GS_A: float = 86.0
const GS_B: float = 70.0
const GS_H: float = 48.0
const G1_Y: float = -84.0
const G2_Y: float = -72.0
const MINE_C := Vector3(-148.0, -100.0, -16.0)
const MINE_T := [Vector3(-80.0, -96.0, -8.0), Vector3(-104.0, -98.0, -11.0), Vector3(-128.0, -100.0, -14.0)]
const JA_C := Vector3(6.0, -99.0, 98.0)
const JA_T := [Vector3(2.0, -96.0, 58.0), Vector3(6.0, -99.0, 78.0)]
const ETANG := Vector2(16.0, 104.0)
const ETANG_R: float = 9.0
const FR_C := Vector3(152.0, -98.0, 26.0)
const FR_R := Vector3(46.0, 30.0, 38.0)
const FR_T := [Vector3(80.0, -96.0, 10.0), Vector3(94.0, -97.0, 16.5), Vector3(108.0, -98.0, 22.0)]
const GOUFFRE_X0: float = 93.0
const GOUFFRE_X1: float = 99.5
const RIVIERE_Y: float = -146.0

var pc: bool = true
var rock_mat: ShaderMaterial
var data: Dictionary = {}
var _crystal_mats: Array = []
var _clock: float = 0.0
var _floors: Dictionary = {}             # (cellule d'un mètre) -> [hauteurs des sols de la roche]


static func W(lx: float, lz: float, y: float) -> Vector3:
	return Vector3(O.x + lx, y, O.z + lz)


static func L(p: Vector3) -> Vector3:
	return Vector3(p.x - O.x, p.y, p.z - O.z)


## Est-on dans les Strates (ou la Fronde) ?
static func contains(p: Vector3) -> bool:
	var l: Vector3 = L(p)
	return l.y < -40.0 and l.y > -160.0 and l.x > -178.0 and l.x < 206.0 and l.z > -86.0 and l.z < 132.0


## L'ovale de la Grande Strate (1 au pied de la paroi).
static func e_gs(lx: float, lz: float) -> float:
	return sqrt(pow(lx / GS_A, 2.0) + pow(lz / GS_B, 2.0))


static func _seg_floor(lx: float, lz: float, pts: Array) -> Vector2:
	## (distance au tracé, hauteur du sol)
	var best: float = INF
	var fy: float = F0
	for k in range(pts.size() - 1):
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t: float = clampf((Vector2(lx - a.x, lz - a.z)).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q := Vector2(a.x, a.z) + ab * t
		var d: float = Vector2(lx, lz).distance_to(q)
		if d < best:
			best = d
			fy = lerpf(a.y, b.y, t)
	return Vector2(best, fy)


## La hauteur du sol (là où l'on marche) : la Grande Strate, ses tunnels, les grottes. Les Galeries
## (plus haut) ne comptent pas ici : on les donne à part (G1_Y, G2_Y).
static func floor_y(lx: float, lz: float) -> float:
	if e_gs(lx, lz) < 0.98:
		return F0
	var m: Vector2 = _seg_floor(lx, lz, MINE_T)
	if m.x < 4.0:
		return m.y
	if Vector2(lx - MINE_C.x, lz - MINE_C.z).length() < 24.0:
		return MINE_C.y
	var j: Vector2 = _seg_floor(lx, lz, JA_T)
	if j.x < 9.0 and lz < 80.0:
		return j.y
	if lz > 70.0:
		var re: float = Vector2(lx - ETANG.x, lz - ETANG.y).length()
		return JA_C.y - 0.9 * pow(clampf((ETANG_R + 1.5 - re) / 2.0, 0.0, 1.0), 1.0)
	var f: Vector2 = _seg_floor(lx, lz, FR_T)
	if f.x < 5.0 and lx < 110.0:
		return f.y
	if lx > 100.0:
		return FR_C.y
	return F0


func build(high_quality: bool) -> void:
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	data = Corps.read_bin(BIN)
	if data.is_empty():
		push_warning("V114 : la roche des Strates manque (" + BIN + ")")
		return
	_rock()
	_floor_grid()
	_stalactites()
	_cristaux()
	_lueurs()
	print("ILE_MANGA_V114: la roche des Strates est taillée (%d ms, %d morceaux)" % [Time.get_ticks_msec() - t0, (data.get("parts", []) as Array).size()])


func _rock() -> void:
	rock_mat = ShaderMaterial.new()
	rock_mat.shader = load(SHADER)
	rock_mat.set_shader_parameter("roche_tex", load("res://assets/textures/terrain/rock.jpg"))
	rock_mat.set_shader_parameter("roche_n", load("res://assets/textures/terrain/rock_n.png"))
	rock_mat.set_shader_parameter("sable_tex", load("res://assets/textures/terrain/sand.jpg"))
	rock_mat.set_shader_parameter("sable_n", load("res://assets/textures/terrain/sand_n.png"))
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_CELLULAR
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fn.frequency = 0.012
	fn.seed = 114
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.generate_mipmaps = true
	nt.noise = fn
	rock_mat.set_shader_parameter("fissures", nt)
	rock_mat.set_shader_parameter("origine", O)
	var sb := StaticBody3D.new()
	sb.name = "Roche_collision"
	sb.collision_layer = 1
	sb.collision_mask = 0
	add_child(sb)
	var k: int = 0
	for part in data.get("parts", []):
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		var v: PackedVector3Array = part["v"]
		var vw := PackedVector3Array()
		vw.resize(v.size())
		for i in range(v.size()):
			vw[i] = Vector3(v[i].x + O.x, v[i].y, v[i].z + O.z)
		arr[Mesh.ARRAY_VERTEX] = vw
		arr[Mesh.ARRAY_NORMAL] = part["n"]
		arr[Mesh.ARRAY_COLOR] = part["c"]
		arr[Mesh.ARRAY_INDEX] = part["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.name = "Roche_%d" % k
		mi.mesh = am
		mi.material_override = rock_mat
		add_child(mi)
		var cs := CollisionShape3D.new()
		var shape: ConcavePolygonShape3D = am.create_trimesh_shape()
		shape.backface_collision = true
		cs.shape = shape
		sb.add_child(cs)
		k += 1


## La grille des sols : pour chaque mètre carré, les hauteurs des sols (les sommets de la roche tournés
## vers le haut) ; floor_at() y cherche le sol le plus proche d'une hauteur donnée.
func _floor_grid() -> void:
	for part in data.get("parts", []):
		var v: PackedVector3Array = part["v"]
		var n: PackedVector3Array = part["n"]
		for i in range(v.size()):
			if n[i].y < 0.8:
				continue
			var key: int = int(floor(v[i].x)) * 4096 + int(floor(v[i].z))
			if not _floors.has(key):
				_floors[key] = [v[i].y]
			else:
				var lst: Array = _floors[key]
				var dup: bool = false
				for y in lst:
					if absf(float(y) - v[i].y) < 0.6:
						dup = true
						break
				if not dup:
					lst.append(v[i].y)


## Le sol de la roche sous (lx, lz) (repère local), le plus proche de la hauteur « near_y » (les cellules
## voisines aussi) ; floor_y() si on ne trouve rien.
func floor_at(lx: float, lz: float, near_y: float = F0) -> float:
	var best: float = INF
	var by: float = floor_y(lx, lz)
	for dx in [0, -1, 1]:
		for dz in [0, -1, 1]:
			var key: int = int(floor(lx)) + dx
			key = key * 4096 + int(floor(lz)) + dz
			for y in _floors.get(key, []):
				var d: float = absf(float(y) - near_y) + (0.0 if dx == 0 and dz == 0 else 0.05)
				if d < best:
					best = d
					by = float(y)
	return by


## Les stalactites : des cônes de grès qui pendent de la voûte (un seul maillage, en MultiMesh).
func _stalactites() -> void:
	var st: PackedFloat32Array = data.get("stalac", PackedFloat32Array())
	var n: int = st.size() / 4
	if n == 0:
		return
	var cone := CylinderMesh.new()
	cone.top_radius = 0.42
	cone.bottom_radius = 0.02
	cone.height = 1.0
	cone.radial_segments = 7
	cone.rings = 3
	var m := StandardMaterial3D.new()
	var tex: Texture2D = load("res://assets/textures/terrain/rock.jpg")
	m.albedo_texture = tex
	m.albedo_color = Color(0.86, 0.72, 0.56)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)
	m.roughness = 0.88
	cone.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = 1140
	for i in range(n):
		var p := Vector3(st[i * 4] + O.x, st[i * 4 + 1], st[i * 4 + 2] + O.z)
		var ln: float = st[i * 4 + 3]
		var w: float = 0.6 + ln * 0.25
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(w, ln, w))
		mm.set_instance_transform(i, Transform3D(b, p + Vector3.DOWN * (ln * 0.5 - 0.3)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Stalactites"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Une grappe de cristaux : cinq prismes hexagonaux pointus, un grand au milieu.
static func cluster_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var specs := [[Vector3.ZERO, Vector3(0, 1, 0), 0.3, 1.3], [Vector3(0.3, 0, 0.05), Vector3(0.5, 0.85, 0.1), 0.22, 0.85],
		[Vector3(-0.28, 0, 0.1), Vector3(-0.45, 0.9, 0.2), 0.22, 0.95], [Vector3(0.05, 0, -0.3), Vector3(0.1, 0.8, -0.55), 0.18, 0.7],
		[Vector3(-0.12, 0, -0.22), Vector3(-0.3, 0.92, -0.3), 0.16, 0.6], [Vector3(0.18, 0, 0.26), Vector3(0.25, 0.9, 0.5), 0.15, 0.55]]
	for sp in specs:
		var base: Vector3 = sp[0]
		var ax: Vector3 = (sp[1] as Vector3).normalized()
		var r: float = sp[2]
		var h: float = sp[3]
		var u: Vector3 = ax.cross(Vector3(0.3, 0.1, 1.0)).normalized()
		var v: Vector3 = ax.cross(u).normalized()
		var ring0: Array = []
		var ring1: Array = []
		for k in range(6):
			var a: float = TAU * k / 6.0
			var d: Vector3 = u * cos(a) + v * sin(a)
			ring0.append(base + d * r - ax * 0.15)
			ring1.append(base + d * r * 0.92 + ax * h * 0.78)
		var tip: Vector3 = base + ax * h
		for k in range(6):
			var k2: int = (k + 1) % 6
			var nf: Vector3 = ((ring0[k] + ring0[k2]) * 0.5 - base).normalized()
			st.set_normal(nf)
			st.add_vertex(ring0[k])
			st.add_vertex(ring1[k])
			st.add_vertex(ring1[k2])
			st.add_vertex(ring0[k])
			st.add_vertex(ring1[k2])
			st.add_vertex(ring0[k2])
			var nt: Vector3 = (nf + ax * 0.6).normalized()
			st.set_normal(nt)
			st.add_vertex(ring1[k])
			st.add_vertex(tip)
			st.add_vertex(ring1[k2])
	st.set_material(mat)
	return st.commit()


static func crystal_mat(c: Color, energy: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/cristal_v114.gdshader")
	m.set_shader_parameter("couleur", c)
	m.set_shader_parameter("force", energy)
	return m


## Les cristaux de la Grotte (et du tunnel des Mines) : bleus, quelques-uns violets.
func _cristaux() -> void:
	var pts: PackedVector3Array = data.get("cristaux", PackedVector3Array())
	var nrm: PackedVector3Array = data.get("cristaux_n", PackedVector3Array())
	if pts.is_empty():
		return
	var blue := crystal_mat(Color(0.3, 0.62, 1.0), 1.0)
	var viol := crystal_mat(Color(0.62, 0.38, 1.0), 0.9)
	_crystal_mats = [blue, viol]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1141
	for which in range(2):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = cluster_mesh(blue if which == 0 else viol)
		var xfs: Array = []
		for i in range(pts.size()):
			if (i % 5 == 0) != (which == 1):
				continue
			var up: Vector3 = (nrm[i] + Vector3.UP * 0.35).normalized()
			var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
			var b := Basis(side, up, side.cross(up)).rotated(up, rng.randf() * TAU)
			var s: float = rng.randf_range(0.6, 1.6) * (1.3 if pts[i].x < -124.0 else 0.7)
			xfs.append(Transform3D(b.scaled(Vector3.ONE * s), Vector3(pts[i].x + O.x, pts[i].y, pts[i].z + O.z) - nrm[i] * 0.4))
		mm.instance_count = xfs.size()
		for j in range(xfs.size()):
			mm.set_instance_transform(j, xfs[j])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Cristaux_%d" % which
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


## La mousse qui luit (Jardins) et les vers luisants (voûtes des Jardins et de la Fronde).
func _lueurs() -> void:
	for spec in [["mousse", Color(0.35, 1.0, 0.75), 0.14, 1.1], ["vers", Color(0.45, 0.85, 1.0), 0.05, 4.0]]:
		var pts: PackedVector3Array = data.get(str(spec[0]), PackedVector3Array())
		var nrm: PackedVector3Array = data.get(str(spec[0]) + "_n", PackedVector3Array())
		if pts.is_empty():
			continue
		var sph := SphereMesh.new()
		sph.radius = float(spec[2])
		sph.height = float(spec[2]) * (0.7 if spec[0] == "mousse" else 2.0)
		sph.radial_segments = 6
		sph.rings = 3
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = spec[1]
		m.emission_enabled = true
		m.emission = spec[1]
		m.emission_energy_multiplier = float(spec[3])
		sph.material = m
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sph
		mm.instance_count = pts.size()
		var rng := RandomNumberGenerator.new()
		rng.seed = 1142
		for i in range(pts.size()):
			var s: float = rng.randf_range(0.6, 1.6)
			var up: Vector3 = nrm[i]
			var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
			mm.set_instance_transform(i, Transform3D(Basis(side, up, side.cross(up)).scaled(Vector3(s * 1.6, s, s * 1.6)), Vector3(pts[i].x + O.x, pts[i].y, pts[i].z + O.z) + nrm[i] * 0.05))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Lueurs_" + str(spec[0])
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


func tick(delta: float) -> void:
	_clock += delta
	pass

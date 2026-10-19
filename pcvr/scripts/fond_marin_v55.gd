extends Node3D
## V55 : le fond de la mer.
##  - Le relief : à ~11 m sous la surface au pied des îles, il descend vers ~32 m au large.
##    Au sud-ouest du village : le plateau de l'Atlantide (30 m), le Jardin de corail (un
##    récif qui monte à 14 m), l'épave de « La Sirène Noire » et la Fosse aux Méduses (35 m).
##  - Le maillage (sable ridé, roche de récif sur les pentes, caustiques qui dansent) en
##    10 x 10 morceaux, chacun avec sa collision.
##  - Le décor : forêts de laminaires qui ondulent, herbiers, rochers, coraux (branchus,
##    cerveaux, tables, gorgones, éponges), anémones, étoiles de mer, oursins, coquillages,
##    l'épave, le bénitier géant et l'autel de la fosse (les trois Perles de Lumière).
## Tout est construit ici (pas de modèle externe). Rien ne dépasse de la surface.

const Rocks = preload("res://scripts/rocks_v26.gd")
const SEA_Y: float = -0.42
const X0: float = -680.0
const Z0: float = -720.0
const SIZE: float = 1280.0
const CELL: float = 4.0
const CHUNKS: int = 10
const ATL := Vector3(-220.0, -30.0, 260.0)        # centre de l'Atlantide (sol de la place)
const ATL_FLAT: float = 64.0
const REEF := Vector3(-150.0, -14.0, 205.0)       # sommet du Jardin de corail
const REEF_R: float = 58.0
const WRECK := Vector3(-300.0, -29.5, 330.0)      # La Sirène Noire
const TRENCH_A := Vector2(-190.0, 336.0)          # Fosse aux Méduses : axe A -> B
const TRENCH_B := Vector2(-118.0, 384.0)
const TRENCH_FLOOR: float = -37.5
## Îles : [centre, rayon du plateau côtier]
const ISLANDS := [[Vector2(0, 0), 92.0], [Vector2(0, -330), 172.0], [Vector2(330, -165), 146.0], [Vector2(-330, -160), 146.0]]

var main: Node
var points: Dictionary = {}           # repères pour la quête (bénitier, coffre, autel…)
var clam_top: Node3D                  # la valve supérieure du bénitier (s'ouvre)
var clam_pearl: Node3D
var wreck_lid: Node3D
var wreck_pearl: Node3D
var altar_pearl: Node3D
var sway_mat: ShaderMaterial          # algues, herbiers, anémones
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}
var floor_mat: ShaderMaterial


# =================================================================== relief

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Hauteur du fond (m) — sans les îles (main._height_at prend le plus haut des deux).
static func height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var e: float = INF
	for isl in ISLANDS:
		e = minf(e, p.distance_to(isl[0]) - float(isl[1]))
	e = maxf(e, 0.0)
	var t: float = smoothstep(0.0, 170.0, e)
	var h: float = -10.5 - 21.5 * t
	h += (sin(x * 0.031) * cos(z * 0.027) * 2.2 + sin(x * 0.083 + 1.7) * sin(z * 0.071) * 0.9
		+ sin(x * 0.19 + z * 0.13) * 0.35) * (0.4 + 0.6 * t)
	# Le plateau de l'Atlantide
	var da: float = p.distance_to(Vector2(ATL.x, ATL.z))
	if da < 130.0:
		h = lerpf(h, ATL.y + sin(x * 0.11) * cos(z * 0.09) * 0.25 * smoothstep(ATL_FLAT - 10.0, ATL_FLAT, da), 1.0 - smoothstep(ATL_FLAT, 125.0, da))
	# Le Jardin de corail : un récif en dôme, bosselé
	var dr: float = p.distance_to(Vector2(REEF.x, REEF.z))
	if dr < REEF_R:
		var f: float = dr / REEF_R
		var reef: float = REEF.y - pow(f, 1.7) * 15.0 + (sin(x * 0.4) * cos(z * 0.37) + sin(x * 0.9 + z * 0.7) * 0.5) * 1.2 * (1.0 - f)
		h = maxf(h, reef)
	# Le lit de l'épave
	var dw: float = p.distance_to(Vector2(WRECK.x, WRECK.z))
	if dw < 40.0:
		h = lerpf(h, WRECK.y, 1.0 - smoothstep(16.0, 40.0, dw))
	# La Fosse aux Méduses : un canyon aux parois raides
	var ds: float = _seg_dist(p, TRENCH_A, TRENCH_B)
	if ds < 26.0:
		var wall: float = smoothstep(7.0, 22.0, ds + sin(x * 0.3 + z * 0.2) * 1.5)
		h = minf(h, lerpf(TRENCH_FLOOR + sin(x * 0.5) * 0.3, h, wall))
	return maxf(h, -38.0)


## Couleur du fond : r = roche (0..1), g = lumière (creux plus sombres)
func _floor_color(x: float, z: float, slope: float) -> Color:
	var n: float = sin(x * 0.07 + 1.3) * cos(z * 0.061) * 0.5 + 0.5
	var rock: float = clampf((slope - 0.22) * 3.5, 0.0, 1.0)
	rock = clampf(rock + (n - 0.75) * 1.2, 0.0, 1.0)
	var dr: float = Vector2(x, z).distance_to(Vector2(REEF.x, REEF.z))
	if dr < REEF_R * 0.9:
		rock = maxf(rock, 1.0 - smoothstep(REEF_R * 0.5, REEF_R * 0.9, dr) + 0.25 * sin(x * 0.3) * cos(z * 0.27))
	var ds: float = _seg_dist(Vector2(x, z), TRENCH_A, TRENCH_B)
	var light: float = 1.0 - (1.0 - smoothstep(6.0, 24.0, ds)) * 0.55
	return Color(rock, light, n, 1.0)


# =================================================================== construction

func build(main_node: Node) -> void:
	main = main_node
	_rng.seed = 5501
	name = "Fond_marin_v55"
	var t0: int = Time.get_ticks_msec()
	_make_materials()
	_build_floor()
	var t1: int = Time.get_ticks_msec()
	_build_kelp()
	_build_seagrass()
	_build_rocks()
	_build_reef()
	_build_small_life()
	_build_wreck()
	_build_trench()
	print("ILE_MANGA_V55: fond marin en %d ms (relief %d ms)" % [Time.get_ticks_msec() - t0, t1 - t0])


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _make_materials() -> void:
	floor_mat = ShaderMaterial.new()
	floor_mat.shader = load("res://shaders/fond_marin_v55.gdshader")
	floor_mat.set_shader_parameter("sand_tex", _tex("res://assets/textures/mer/sable_fond.png"))
	floor_mat.set_shader_parameter("sand_n", _tex("res://assets/textures/mer/sable_fond_n.png"))
	floor_mat.set_shader_parameter("rock_tex", _tex("res://assets/textures/mer/roche_recif.png"))
	floor_mat.set_shader_parameter("rock_n", _tex("res://assets/textures/mer/roche_recif_n.png"))
	floor_mat.set_shader_parameter("caustic_tex", _tex("res://assets/textures/mer/caustiques.png"))
	sway_mat = ShaderMaterial.new()
	sway_mat.shader = load("res://shaders/algue_v55.gdshader")
	sway_mat.set_shader_parameter("leaf_tex", _tex("res://assets/textures/mer/algue.png"))
	sway_mat.set_shader_parameter("caustic_tex", _tex("res://assets/textures/mer/caustiques.png"))


func mat(key: String, c: Color, rough: float = 0.8, emit: float = 0.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.vertex_color_use_as_albedo = true
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


func _build_floor() -> void:
	var n: int = int(SIZE / CELL) + 1
	var hs := PackedFloat32Array()
	hs.resize(n * n)
	for j in range(n):
		var z: float = Z0 + j * CELL
		for i in range(n):
			hs[j * n + i] = height(X0 + i * CELL, z)
	# Ce que cachent les îles (le fond est plus bas que leur relief) n'est pas dessiné.
	var covered := PackedByteArray()
	covered.resize(n * n)
	var has_land: bool = main != null and main.has_method("_height_land_v55")
	for j in range(n):
		var z2: float = Z0 + j * CELL
		for i in range(n):
			var land: float = main._height_land_v55(X0 + i * CELL, z2) if has_land else -999.0
			covered[j * n + i] = 1 if land > hs[j * n + i] + 1.5 else 0
	var per: int = (n - 1) / CHUNKS
	for cj in range(CHUNKS):
		for ci in range(CHUNKS):
			var verts := PackedVector3Array()
			var norms := PackedVector3Array()
			var tans := PackedFloat32Array()
			var uvs := PackedVector2Array()
			var cols := PackedColorArray()
			var idx := PackedInt32Array()
			var m: int = per + 1
			for jj in range(m):
				var j2: int = cj * per + jj
				for ii in range(m):
					var i2: int = ci * per + ii
					var x: float = X0 + i2 * CELL
					var z3: float = Z0 + j2 * CELL
					var h: float = hs[j2 * n + i2]
					var hx: float = hs[j2 * n + mini(i2 + 1, n - 1)] - hs[j2 * n + maxi(i2 - 1, 0)]
					var hz: float = hs[mini(j2 + 1, n - 1) * n + i2] - hs[maxi(j2 - 1, 0) * n + i2]
					var nrm := Vector3(-hx, 2.0 * CELL, -hz).normalized()
					var tan := Vector3(2.0 * CELL, hx, 0.0).normalized()
					verts.append(Vector3(x, h, z3))
					norms.append(nrm)
					tans.append_array([tan.x, tan.y, tan.z, 1.0])
					uvs.append(Vector2(x, z3) / 6.0)
					cols.append(_floor_color(x, z3, 1.0 - nrm.y))
			for jj in range(per):
				for ii in range(per):
					var g: int = (cj * per + jj) * n + ci * per + ii
					if covered[g] == 1 and covered[g + 1] == 1 and covered[g + n] == 1 and covered[g + n + 1] == 1:
						continue
					var a: int = jj * m + ii
					idx.append_array([a, a + 1, a + m, a + 1, a + m + 1, a + m])
			if idx.is_empty():
				continue
			var arr: Array = []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = verts
			arr[Mesh.ARRAY_NORMAL] = norms
			arr[Mesh.ARRAY_TANGENT] = tans
			arr[Mesh.ARRAY_TEX_UV] = uvs
			arr[Mesh.ARRAY_COLOR] = cols
			arr[Mesh.ARRAY_INDEX] = idx
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mi := MeshInstance3D.new()
			mi.name = "Fond_%d_%d" % [ci, cj]
			mi.mesh = mesh
			mi.material_override = floor_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			var body := StaticBody3D.new()
			body.name = "Fond_marin_collision_%d_%d" % [ci, cj]
			body.collision_layer = 1
			body.collision_mask = 0
			var cs := CollisionShape3D.new()
			cs.shape = mesh.create_trimesh_shape()
			body.add_child(cs)
			add_child(body)


## Position au fond, au hasard dans un disque (évite les îles : fond visible seulement).
func _spot_in(center: Vector2, r_min: float, r_max: float, h_min: float, h_max: float, tries: int = 12) -> Variant:
	for _t in range(tries):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf_range(r_min * r_min, r_max * r_max))
		var x: float = center.x + cos(a) * r
		var z: float = center.y + sin(a) * r
		var h: float = height(x, z)
		if h < h_min or h > h_max:
			continue
		# rien sous le dôme de l'Atlantide (ni dans son entrée)
		if Vector2(x - ATL.x, z - ATL.z).length() < 49.0:
			continue
		var clear: bool = true
		for kc in _keep_clear:
			if Vector2(x, z).distance_to(kc[0]) < float(kc[1]):
				clear = false
		if not clear:
			continue
		if main != null and main.has_method("_height_land_v55") and main._height_land_v55(x, z) > h - 0.2:
			continue
		return Vector3(x, h, z)
	return null


func _normal_at(x: float, z: float) -> Vector3:
	var hx: float = height(x + 0.8, z) - height(x - 0.8, z)
	var hz: float = height(x, z + 0.8) - height(x, z - 0.8)
	return Vector3(-hx, 1.6, -hz).normalized()


func _mm(mesh: Mesh, xforms: Array, material: Material, label: String, vis_end: float = 0.0, colors: Array = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis_end > 0.0:
		mmi.visibility_range_end = vis_end
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mmi)
	return mmi


# =================================================================== algues et herbiers

## Une lame de laminaire : deux rubans croisés, h mètres, UV v = 0 en haut.
func _kelp_mesh(h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 10
	for side in range(2):
		var dir := Vector3(1, 0, 0) if side == 0 else Vector3(0, 0, 1)
		for s in range(segs):
			var y0: float = h * s / segs
			var y1: float = h * (s + 1) / segs
			var w0: float = 0.45
			var w1: float = 0.45
			var tw0: float = s * 0.35
			var tw1: float = (s + 1) * 0.35
			var d0: Vector3 = dir.rotated(Vector3.UP, tw0) * w0
			var d1: Vector3 = dir.rotated(Vector3.UP, tw1) * w1
			var v0: float = 1.0 - float(s) / segs
			var v1: float = 1.0 - float(s + 1) / segs
			var quad := [[Vector3(0, y0, 0) - d0, Vector2(0, v0)], [Vector3(0, y0, 0) + d0, Vector2(1, v0)],
				[Vector3(0, y1, 0) - d1, Vector2(0, v1)], [Vector3(0, y1, 0) + d1, Vector2(1, v1)]]
			var nrm: Vector3 = d0.cross(Vector3.UP).normalized()
			for k in [0, 2, 1, 1, 2, 3]:
				st.set_normal(nrm)
				st.set_uv(quad[k][1])
				st.set_color(Color(1, 1, 1, quad[k][0].y / h))
				st.add_vertex(quad[k][0])
	return st.commit()


func _build_kelp() -> void:
	var spots: Array = []
	# La forêt de laminaires autour de l'Atlantide (une couronne, ouverte devant la porte)
	for _i in range(520):
		var s: Variant = _spot_in(Vector2(ATL.x, ATL.z), 58.0, 115.0, -34.0, -18.0)
		if s == null:
			continue
		var v: Vector3 = s
		var ang: float = atan2(v.z - ATL.z, v.x - ATL.x)
		if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.32:
			continue                # l'allée de la Porte des Marées (au sud)
		spots.append(v)
	# Quelques bosquets au pied des îles
	for c in [Vector2(-70, 80), Vector2(90, 40), Vector2(-120, -230), Vector2(150, -420), Vector2(-260, -40), Vector2(260, -40)]:
		for _j in range(60):
			var s2: Variant = _spot_in(c, 0.0, 28.0, -32.0, -11.5)
			if s2 != null:
				spots.append(s2)
	var meshes := [_kelp_mesh(1.0)]
	var xf: Array = []
	var cols: Array = []
	for v2 in spots:
		var depth: float = SEA_Y - v2.y
		var h: float = clampf(_rng.randf_range(0.45, 0.8) * depth, 4.0, depth - 2.0)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(_rng.randf_range(0.8, 1.3), h, _rng.randf_range(0.8, 1.3)))
		xf.append(Transform3D(b, v2 + Vector3.DOWN * 0.1))
		cols.append(Color(_rng.randf_range(0.85, 1.15), _rng.randf_range(0.85, 1.1), 1.0, _rng.randf()))
	var kelp_mat: ShaderMaterial = sway_mat.duplicate()
	kelp_mat.set_shader_parameter("sway", 1.4)
	kelp_mat.set_shader_parameter("use_tex", true)
	_mm(meshes[0], xf, kelp_mat, "Laminaires_v55", 160.0, cols)


func _grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(3):
		var d: Vector3 = Vector3(0.6, 0, 0).rotated(Vector3.UP, k * PI / 3.0)
		var nrm: Vector3 = d.cross(Vector3.UP).normalized()
		var q := [[-d, Vector2(0, 1)], [d, Vector2(1, 1)], [-d + Vector3.UP, Vector2(0, 0)], [d + Vector3.UP, Vector2(1, 0)]]
		for i in [0, 2, 1, 1, 2, 3]:
			st.set_normal(nrm)
			st.set_uv(q[i][1])
			st.set_color(Color(1, 1, 1, q[i][0].y))
			st.add_vertex(q[i][0])
	return st.commit()


func _build_seagrass() -> void:
	var xf: Array = []
	var cols: Array = []
	var centers := [Vector2(-60, 95), Vector2(70, 75), Vector2(100, -40), Vector2(-100, -20), Vector2(-90, -200), Vector2(110, -200),
		Vector2(200, -380), Vector2(-180, -420), Vector2(-260, -60), Vector2(420, -90), Vector2(-420, -230), Vector2(-150, 205), Vector2(-200, 180)]
	for c in centers:
		for _i in range(260):
			var s: Variant = _spot_in(c, 0.0, 40.0, -30.0, -10.5, 6)
			if s == null:
				continue
			var v: Vector3 = s
			var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.4))
			xf.append(Transform3D(b, v))
			cols.append(Color(1, 1, 1, _rng.randf()))
	var gm: ShaderMaterial = sway_mat.duplicate()
	gm.set_shader_parameter("leaf_tex", _tex("res://assets/textures/mer/herbier.png"))
	gm.set_shader_parameter("sway", 0.35)
	gm.set_shader_parameter("use_tex", true)
	_mm(_grass_mesh(), xf, gm, "Herbiers_v55", 70.0, cols)


# =================================================================== rochers

func _build_rocks() -> void:
	var rock_mat: Material = Rocks.material(Color(0.5, 0.47, 0.42), 0.7, 0.18)
	var variants: Array = []
	for k in range(5):
		variants.append(Rocks.shape(5500 + k, Vector3(1.0, 0.7, 1.0), 0.55, 0.22, 1.5, 20))
	var groups: Array = [[], [], [], [], []]
	var areas := [[Vector2(ATL.x, ATL.z), 66.0, 125.0, 70], [Vector2(REEF.x, REEF.z), 20.0, 70.0, 50], [Vector2(WRECK.x, WRECK.z), 10.0, 50.0, 25],
		[Vector2(-40, 140), 0.0, 90.0, 40], [Vector2(150, -120), 0.0, 90.0, 30], [Vector2(-150, -110), 0.0, 90.0, 30], [Vector2(40, 330), 40.0, 110.0, 30]]
	for area in areas:
		for _i in range(int(area[3])):
			var s: Variant = _spot_in(area[0], area[1], area[2], -36.0, -10.5)
			if s == null:
				continue
			var v: Vector3 = s
			var sc: float = _rng.randf_range(0.8, 3.8)
			var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc * _rng.randf_range(0.5, 0.9), sc * _rng.randf_range(0.8, 1.2)))
			groups[_rng.randi() % 5].append(Transform3D(b, v + Vector3.DOWN * sc * 0.25))
	for k in range(5):
		if groups[k].is_empty():
			continue
		_mm(variants[k], groups[k], rock_mat, "Rochers_mer_v55_%d" % k, 220.0)
		# Les gros rochers arrêtent le nageur
		for xfm in groups[k]:
			var t: Transform3D = xfm
			if t.basis.get_scale().x > 2.2:
				var body := StaticBody3D.new()
				body.name = "Rocher_mer_collision"
				body.collision_layer = 1
				body.collision_mask = 0
				body.add_child(Rocks.collision_for(variants[k], t))
				add_child(body)


# =================================================================== coraux

var _tb: Array = []
var _keep_clear: Array = [[Vector2(REEF.x + 3.0, REEF.z - 2.0), 3.5]]   # autour du bénitier


## Un sommet de triangle ; par trois, l'ordre est corrigé pour que la face avant regarde
## du côté de la normale (règle de Godot : sens horaire vu de face).
func _v(st: SurfaceTool, p: Vector3, n: Vector3, c: Color) -> void:
	_tb.append([p, n, c])
	if _tb.size() < 3:
		return
	var face: Vector3 = (_tb[1][0] - _tb[0][0]).cross(_tb[2][0] - _tb[0][0])
	var avg: Vector3 = _tb[0][1] + _tb[1][1] + _tb[2][1]
	var order: Array = [0, 1, 2] if face.dot(avg) <= 0.0 else [0, 2, 1]
	for k in order:
		st.set_normal(_tb[k][1])
		st.set_color(_tb[k][2])
		st.add_vertex(_tb[k][0])
	_tb.clear()


func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, col: Color, col_tip: Color, seg: int = 6) -> void:
	var axis: Vector3 = (b - a).normalized()
	var side: Vector3 = axis.cross(Vector3.UP if absf(axis.y) < 0.95 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(axis).normalized()
	for s in range(seg):
		var a0: float = TAU * s / seg
		var a1: float = TAU * (s + 1) / seg
		var n0: Vector3 = side * cos(a0) + up * sin(a0)
		var n1: Vector3 = side * cos(a1) + up * sin(a1)
		var quad := [[a + n0 * r0, n0, col], [a + n1 * r0, n1, col], [b + n0 * r1, n0, col_tip], [b + n1 * r1, n1, col_tip]]
		for k in [0, 1, 2, 2, 1, 3]:
			_v(st, quad[k][0], quad[k][1], quad[k][2])
	# bout arrondi
	var tip: Vector3 = b + axis * r1 * 0.8
	for s2 in range(seg):
		var b0: float = TAU * s2 / seg
		var b1: float = TAU * (s2 + 1) / seg
		var m0: Vector3 = side * cos(b0) + up * sin(b0)
		var m1: Vector3 = side * cos(b1) + up * sin(b1)
		for p in [[b + m0 * r1, m0], [b + m1 * r1, m1], [tip, axis]]:
			_v(st, p[0], p[1], col_tip)


func _branch(st: SurfaceTool, at: Vector3, dir: Vector3, length: float, r: float, depth: int, col: Color, tip: Color) -> void:
	var end: Vector3 = at + dir * length
	_tube(st, at, end, r, r * 0.72, col.lerp(tip, 0.3 * (3 - depth) / 3.0), col.lerp(tip, 1.0 if depth == 0 else 0.35))
	if depth <= 0:
		return
	var kids: int = 2 if _rng.randf() < 0.6 else 3
	for k in range(kids):
		var nd: Vector3 = (dir + Vector3(_rng.randf_range(-0.7, 0.7), _rng.randf_range(0.1, 0.6), _rng.randf_range(-0.7, 0.7))).normalized()
		_branch(st, end, nd, length * _rng.randf_range(0.6, 0.85), r * 0.72, depth - 1, col, tip)


func _staghorn(col: Color, tip: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(4):
		var d: Vector3 = Vector3(_rng.randf_range(-0.5, 0.5), 1.0, _rng.randf_range(-0.5, 0.5)).normalized()
		_branch(st, Vector3(_rng.randf_range(-0.1, 0.1), 0, _rng.randf_range(-0.1, 0.1)), d, 0.42, 0.055, 2, col, tip)
	return st.commit()


func _brain(col: Color, groove: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 12
	var segs: int = 24
	var pts: Array = []
	for i in range(rings + 1):
		var row: Array = []
		var th: float = PI * 0.5 * i / rings
		for j in range(segs + 1):
			var ph: float = TAU * j / segs
			var d := Vector3(cos(ph) * sin(th), cos(th), sin(ph) * sin(th))
			var g: float = absf(sin(ph * 7.0 + th * 9.0 + sin(ph * 3.0) * 2.0))
			var r: float = 0.5 * (1.0 - 0.06 * (1.0 - g))
			row.append([d * r * Vector3(1.0, 0.7, 1.0), d, col.lerp(groove, 1.0 - g)])
		pts.append(row)
	for i in range(rings):
		for j in range(segs):
			for k in [[i, j], [i + 1, j], [i, j + 1], [i, j + 1], [i + 1, j], [i + 1, j + 1]]:
				var p: Array = pts[k[0]][k[1]]
				_v(st, p[0], p[1], p[2])
	return st.commit()


func _table(col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, Vector3.ZERO, Vector3(0, 0.45, 0), 0.08, 0.06, col.darkened(0.3), col)
	var segs: int = 18
	for s in range(segs):
		var a0: float = TAU * s / segs
		var a1: float = TAU * (s + 1) / segs
		var r0: float = 0.75 + 0.08 * sin(a0 * 5.0)
		var r1: float = 0.75 + 0.08 * sin(a1 * 5.0)
		for face in [1.0, -1.0]:
			var y: float = 0.5 if face > 0 else 0.46
			var tri := [Vector3(0, y + 0.03 * face, 0), Vector3(cos(a0) * r0, y - 0.04, sin(a0) * r0), Vector3(cos(a1) * r1, y - 0.04, sin(a1) * r1)]
			var order := [0, 1, 2] if face < 0 else [0, 2, 1]
			for k in order:
				_v(st, tri[k], Vector3(0, face, 0), col if face > 0 else col.darkened(0.4))
	return st.commit()


func _fan(col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# gorgone : un éventail de rameaux dans un plan, avec des barreaux
	var tips: Array = []
	for k in range(9):
		var a: float = lerpf(-1.1, 1.1, k / 8.0)
		var end := Vector3(sin(a) * 0.9, cos(a) * 1.1 + 0.1, _rng.randf_range(-0.04, 0.04))
		_tube(st, Vector3(0, 0.1, 0), end, 0.025, 0.012, col.darkened(0.2), col, 4)
		tips.append(end)
	for r in [0.4, 0.7]:
		for k in range(8):
			var p0: Vector3 = Vector3(0, 0.1, 0).lerp(tips[k], r)
			var p1: Vector3 = Vector3(0, 0.1, 0).lerp(tips[k + 1], r)
			_tube(st, p0, p1, 0.01, 0.01, col, col, 3)
	_tube(st, Vector3.ZERO, Vector3(0, 0.12, 0), 0.04, 0.03, col.darkened(0.3), col.darkened(0.2), 5)
	return st.commit()


func _sponge(col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(3):
		var off := Vector3(_rng.randf_range(-0.15, 0.15), 0, _rng.randf_range(-0.15, 0.15))
		var h: float = _rng.randf_range(0.4, 0.9)
		_tube(st, off, off + Vector3(_rng.randf_range(-0.1, 0.1), h, _rng.randf_range(-0.1, 0.1)), 0.12, 0.15, col.darkened(0.25), col, 9)
	return st.commit()


func _anemone(col: Color, tip: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, Vector3.ZERO, Vector3(0, 0.12, 0), 0.16, 0.18, col.darkened(0.4), col.darkened(0.2), 10)
	for k in range(46):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * 0.17
		var base := Vector3(cos(a) * r, 0.14, sin(a) * r)
		var d := (Vector3(cos(a) * (0.4 + r * 2.5), 1.0, sin(a) * (0.4 + r * 2.5))).normalized()
		_tube(st, base, base + d * _rng.randf_range(0.22, 0.32), 0.016, 0.008, col, tip, 4)
	return st.commit()


func _coral_colors() -> Array:
	return [
		[Color(0.72, 0.36, 0.62), Color(0.95, 0.75, 0.9)],     # violet, pointes roses
		[Color(0.9, 0.5, 0.22), Color(1.0, 0.85, 0.55)],        # orange
		[Color(0.85, 0.75, 0.3), Color(0.95, 0.95, 0.7)],       # jaune
		[Color(0.35, 0.55, 0.85), Color(0.75, 0.9, 1.0)],       # bleu
		[Color(0.9, 0.45, 0.5), Color(1.0, 0.8, 0.75)],         # rose
		[Color(0.55, 0.7, 0.4), Color(0.85, 0.95, 0.6)],        # vert pâle
	]


## Coraux autour d'un centre : liste de [Transform3D] par maillage.
func _scatter_corals(center: Vector2, r_max: float, h_min: float, h_max: float, count: int, label: String, vis: float) -> void:
	var palette: Array = _coral_colors()
	var kinds: Array = []
	for k in range(4):
		var c: Array = palette[_rng.randi() % palette.size()]
		kinds.append(_staghorn(c[0], c[1]))
	kinds.append(_brain(Color(0.86, 0.74, 0.42), Color(0.5, 0.4, 0.22)))
	kinds.append(_brain(Color(0.62, 0.8, 0.55), Color(0.34, 0.48, 0.3)))
	kinds.append(_table(Color(0.55, 0.62, 0.48)))
	kinds.append(_table(Color(0.75, 0.55, 0.45)))
	kinds.append(_fan(Color(0.75, 0.2, 0.35)))
	kinds.append(_fan(Color(0.9, 0.6, 0.2)))
	kinds.append(_sponge(Color(0.85, 0.45, 0.15)))
	kinds.append(_sponge(Color(0.55, 0.3, 0.6)))
	var a1: Array = palette[0]
	var a2: Array = palette[4]
	kinds.append(_anemone(Color(0.85, 0.55, 0.7), Color(0.6, 0.95, 0.5)))
	kinds.append(_anemone(Color(0.95, 0.85, 0.6), Color(0.95, 0.6, 0.85)))
	var sway_kind := {12: true, 13: true}
	var groups: Array = []
	for k in range(kinds.size()):
		groups.append([])
	# Des « patates » de corail : un rocher couvert, et les coraux serrés autour
	var heads: Array = []
	for _c in range(maxi(count / 22, 3)):
		var hs: Variant = _spot_in(center, 0.0, r_max, h_min, h_max, 8)
		if hs != null:
			heads.append(hs)
	_reef_rocks(heads)
	for _i in range(count):
		var s: Variant = null
		if not heads.is_empty() and _rng.randf() < 0.85:
			var hc: Vector3 = heads[_rng.randi() % heads.size()]
			s = _spot_in(Vector2(hc.x, hc.z), 0.0, 4.5, h_min, h_max, 4)
		else:
			s = _spot_in(center, 0.0, r_max, h_min, h_max, 6)
		if s == null:
			continue
		var v: Vector3 = s
		var k2: int = _rng.randi() % kinds.size()
		var sc: float = _rng.randf_range(0.8, 2.0)
		if k2 >= 4 and k2 <= 5:
			sc *= 1.6
		var up: Vector3 = _normal_at(v.x, v.z).lerp(Vector3.UP, 0.6).normalized()
		var right: Vector3 = up.cross(Vector3.FORWARD).normalized()
		var fwd: Vector3 = right.cross(up).normalized()
		var b := Basis(right, up, -fwd).rotated(up, _rng.randf() * TAU).scaled(Vector3.ONE * sc)
		groups[k2].append(Transform3D(b, v - up * 0.05))
	var coral_mat: Material = _coral_material()
	var an_mat: ShaderMaterial = sway_mat.duplicate()
	an_mat.set_shader_parameter("use_tex", false)
	an_mat.set_shader_parameter("sway", 0.06)
	an_mat.set_shader_parameter("speed", 1.6)
	an_mat.set_shader_parameter("height_ref", 0.45)
	for k3 in range(kinds.size()):
		if groups[k3].is_empty():
			continue
		_mm(kinds[k3], groups[k3], an_mat if sway_kind.has(k3) else coral_mat, "%s_%d" % [label, k3], vis)


var _reef_rock_mesh: Array = []
var _reef_rock_mat: Material


## Les rochers des récifs : roche encroûtée (algues calcaires roses, éponges).
func _reef_rocks(heads: Array) -> void:
	if heads.is_empty():
		return
	if _reef_rock_mesh.is_empty():
		for k in range(3):
			_reef_rock_mesh.append(Rocks.shape(5580 + k, Vector3(1.0, 0.75, 1.0), 0.45, 0.3, 1.4, 20))
		_reef_rock_mat = Rocks.material(Color(0.66, 0.52, 0.54), 0.3, 0.3)
	var groups: Array = [[], [], []]
	for h in heads:
		var v: Vector3 = h
		var sc: float = _rng.randf_range(1.6, 3.4)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc * _rng.randf_range(1.0, 1.6), sc * 0.7, sc))
		groups[_rng.randi() % 3].append(Transform3D(b, v + Vector3.DOWN * sc * 0.25))
	for k2 in range(3):
		if not groups[k2].is_empty():
			_mm(_reef_rock_mesh[k2], groups[k2], _reef_rock_mat, "Recif_rochers_v55_%d" % k2, 150.0)


var _coral_mat: ShaderMaterial


## Les coraux : couleur des sommets, une pointe de lumière propre (sous l'eau, la lumière
## arrive de partout, diffusée) et un peu de transluminescence sur les fines branches.
func _coral_material() -> ShaderMaterial:
	if _coral_mat != null:
		return _coral_mat
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	EMISSION = COLOR.rgb * 0.14;
	BACKLIGHT = COLOR.rgb * 0.3;
}
"""
	_coral_mat = ShaderMaterial.new()
	_coral_mat.shader = sh
	return _coral_mat


func _build_reef() -> void:
	_scatter_corals(Vector2(REEF.x, REEF.z), REEF_R * 0.95, -32.0, -12.0, 900, "Corail_jardin_v55", 120.0)
	# Petits récifs au pied des îles, là où l'eau est claire
	for c in [Vector2(-40, 110), Vector2(85, 85), Vector2(-120, 60), Vector2(30, -175), Vector2(-60, -500), Vector2(450, -200), Vector2(-450, -120)]:
		_scatter_corals(c, 30.0, -24.0, -10.5, 200, "Corail_ile_v55", 90.0)
	# Les jardins de corail de l'Atlantide (hors du dôme)
	_scatter_corals(Vector2(ATL.x, ATL.z), 64.0, -34.0, -20.0, 260, "Corail_atlantide_v55", 120.0)
	# Le bénitier géant, au cœur du récif : la Perle du Jardin
	var top := Vector3(REEF.x + 3.0, 0, REEF.z - 2.0)
	top.y = height(top.x, top.z)
	_giant_clam(top)


## Une valve de bénitier géant : coquille épaisse à grosses côtes rayonnantes, lèvre en
## zigzag (les deux valves s'emboîtent), sable clair et sillons sombres. up = 1 ou -1.
func _clam_valve(up: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 12
	var segs: int = 48
	var grid: Array = []
	for i in range(rings + 1):
		var th: float = PI * 0.5 * i / rings
		var row: Array = []
		for j in range(segs + 1):
			var ph: float = TAU * j / segs
			var rib: float = pow(absf(sin(ph * 3.0)), 0.6)
			var k: float = 1.0 + 0.17 * rib * sin(th)
			var x: float = cos(ph) * sin(th) * 1.35 * k
			var z: float = sin(ph) * sin(th) * 0.85 * k
			var y: float = cos(th) * 0.55 * up * (0.85 + 0.15 * k)
			y += 0.11 * sin(ph * 6.0) * pow(sin(th), 10.0)
			var col := Color(0.42, 0.4, 0.36).lerp(Color(0.74, 0.7, 0.62), rib)
			if i == rings:
				col = Color(0.85, 0.82, 0.72)
			row.append([Vector3(x, y, z), Vector3(x / 1.35, y / 0.55, z / 0.85).normalized(), col])
		grid.append(row)
	for i in range(rings):
		for j in range(segs):
			for kk in [[i, j], [i + 1, j], [i, j + 1], [i, j + 1], [i + 1, j], [i + 1, j + 1]]:
				var p: Array = grid[kk[0]][kk[1]]
				_v(st, p[0], p[1], p[2])
	return st.commit()


func _giant_clam(at: Vector3) -> void:
	var clam := Node3D.new()
	clam.name = "Benitier_v55"
	add_child(clam)
	clam.global_position = at + Vector3.UP * 0.35
	clam.scale = Vector3.ONE * 1.25
	clam.rotation.y = 0.6
	var shell_mat := StandardMaterial3D.new()
	shell_mat.vertex_color_use_as_albedo = true
	shell_mat.roughness = 0.75
	shell_mat.normal_enabled = true
	shell_mat.normal_texture = _tex("res://assets/textures/mer/roche_recif_n.png")
	shell_mat.uv1_triplanar = true
	shell_mat.uv1_scale = Vector3.ONE * 0.8
	var lower := MeshInstance3D.new()
	lower.mesh = _clam_valve(-1.0)
	lower.material_override = shell_mat
	clam.add_child(lower)
	# La valve supérieure, articulée à l'arrière (charnière en z = -0.85)
	clam_top = Node3D.new()
	clam_top.name = "Valve"
	clam_top.position = Vector3(0, 0.02, -0.85)
	clam.add_child(clam_top)
	var upper := MeshInstance3D.new()
	upper.mesh = _clam_valve(1.0)
	upper.material_override = shell_mat
	upper.position = Vector3(0, 0, 0.85)
	clam_top.add_child(upper)
	clam_top.rotation.x = 0.06
	# Le manteau : bleu profond semé de points turquoise, qui luit un peu
	var mantle := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 1.0
	mm.height = 2.0
	mantle.mesh = mm
	mantle.scale = Vector3(1.25, 0.16, 0.72)
	mantle.position.y = 0.05
	mantle.material_override = mat("manteau_benitier", Color(0.1, 0.3, 0.75), 0.35, 0.5)
	clam.add_child(mantle)
	var dots := mat("points_manteau", Color(0.3, 0.95, 0.9), 0.3, 1.4)
	for k in range(26):
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * 0.9
		var dm := MeshInstance3D.new()
		var ds := SphereMesh.new()
		ds.radius = 0.035
		ds.height = 0.05
		ds.radial_segments = 6
		ds.rings = 3
		dm.mesh = ds
		dm.material_override = dots
		dm.position = Vector3(cos(a) * r * 1.2, 0.13, sin(a) * r * 0.62)
		clam.add_child(dm)
	clam_pearl = _pearl()
	clam_pearl.position = Vector3(0, 0.26, 0.1)
	clam.add_child(clam_pearl)
	points["benitier"] = clam.global_position + Vector3.UP * 0.4
	var body := StaticBody3D.new()
	body.name = "Benitier_collision"
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.3
	cyl.height = 0.7
	cs.shape = cyl
	body.add_child(cs)
	clam.add_child(body)


## Une Perle de Lumière : nacre qui luit, halo et petite lumière.
func _pearl() -> Node3D:
	var p := Node3D.new()
	p.name = "Perle_lumiere"
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.97, 1.0)
	m.metallic = 0.3
	m.roughness = 0.1
	m.emission_enabled = true
	m.emission = Color(0.6, 0.95, 1.0)
	m.emission_energy_multiplier = 2.2
	mi.material_override = m
	p.add_child(mi)
	var halo := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.4, 1.4)
	halo.mesh = qm
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.albedo_texture = _soft_dot()
	hm.albedo_color = Color(0.5, 0.9, 1.0, 0.8)
	hm.no_depth_test = false
	halo.material_override = hm
	halo.add_to_group("sous_eau_v55")
	p.add_child(halo)
	var light := OmniLight3D.new()
	light.light_color = Color(0.6, 0.95, 1.0)
	light.light_energy = 1.2
	light.omni_range = 5.0
	light.shadow_enabled = false
	p.add_child(light)
	return p


var _dot_tex: GradientTexture2D


func _soft_dot() -> GradientTexture2D:
	if _dot_tex != null:
		return _dot_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	_dot_tex = GradientTexture2D.new()
	_dot_tex.gradient = g
	_dot_tex.fill = GradientTexture2D.FILL_RADIAL
	_dot_tex.fill_from = Vector2(0.5, 0.5)
	_dot_tex.fill_to = Vector2(0.5, 0.0)
	_dot_tex.width = 64
	_dot_tex.height = 64
	return _dot_tex


# =================================================================== petite vie fixée

func _star_mesh(col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var b0: float = a - 0.35
		var b1: float = a + 0.35
		var tip := Vector3(cos(a) * 0.22, 0.01, sin(a) * 0.22)
		var l := Vector3(cos(b0) * 0.06, 0.025, sin(b0) * 0.06)
		var r := Vector3(cos(b1) * 0.06, 0.025, sin(b1) * 0.06)
		for p in [[Vector3(0, 0.04, 0), col.lightened(0.15)], [r, col], [tip, col.darkened(0.15)], [Vector3(0, 0.04, 0), col.lightened(0.15)], [tip, col.darkened(0.15)], [l, col]]:
			_v(st, p[0], Vector3.UP, p[1])
	return st.commit()


func _urchin_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color(0.12, 0.08, 0.14)
	for k in range(40):
		var d := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.0, 1), _rng.randf_range(-1, 1)).normalized()
		_tube(st, d * 0.06, d * 0.22, 0.012, 0.002, dark, dark, 3)
	_tube(st, Vector3.ZERO, Vector3(0, 0.1, 0), 0.08, 0.06, dark, dark, 8)
	return st.commit()


func _shell_mesh(col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 10
	for s in range(segs):
		var a0: float = PI * (0.1 + 0.8 * s / segs)
		var a1: float = PI * (0.1 + 0.8 * (s + 1) / segs)
		var rib: Color = col if s % 2 == 0 else col.darkened(0.2)
		for p in [Vector3(0, 0.0, -0.05), Vector3(cos(a0) * 0.12, 0.03, sin(a0) * 0.12 - 0.05), Vector3(cos(a1) * 0.12, 0.03, sin(a1) * 0.12 - 0.05)]:
			_v(st, p, Vector3.UP, rib)
	return st.commit()


func _build_small_life() -> void:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.7
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var kinds := [_star_mesh(Color(0.9, 0.35, 0.15)), _star_mesh(Color(0.75, 0.2, 0.3)), _star_mesh(Color(0.25, 0.4, 0.85)),
		_urchin_mesh(), _shell_mesh(Color(0.92, 0.82, 0.7)), _shell_mesh(Color(0.85, 0.6, 0.5))]
	var groups: Array = [[], [], [], [], [], []]
	var areas := [Vector2(REEF.x, REEF.z), Vector2(ATL.x, ATL.z), Vector2(-40, 110), Vector2(85, 85), Vector2(WRECK.x, WRECK.z), Vector2(-120, 60)]
	for c in areas:
		for _i in range(160):
			var s: Variant = _spot_in(c, 0.0, 70.0, -35.0, -10.5, 4)
			if s == null:
				continue
			var v: Vector3 = s
			var up: Vector3 = _normal_at(v.x, v.z)
			var right: Vector3 = up.cross(Vector3.FORWARD).normalized()
			var b := Basis(right, up, right.cross(up)).rotated(up, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.6))
			groups[_rng.randi() % kinds.size()].append(Transform3D(b, v))
	for k in range(kinds.size()):
		if not groups[k].is_empty():
			_mm(kinds[k], groups[k], m, "Petite_vie_v55_%d" % k, 45.0)


# =================================================================== l'épave

## Coque : sections elliptiques le long de z (de -L/2 à L/2), ouverte au milieu (brisée).
func _hull_mesh(length: float, beam: float, depth: float, gap: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: int = 24
	var segs: int = 14
	for i in range(rows):
		var z0: float = lerpf(-length * 0.5, length * 0.5, float(i) / rows)
		var z1: float = lerpf(-length * 0.5, length * 0.5, float(i + 1) / rows)
		if z0 > gap.x and z1 < gap.y:
			continue
		for j in range(segs):
			var a0: float = PI * j / segs
			var a1: float = PI * (j + 1) / segs
			# brèche irrégulière à bâbord dans la zone du trou
			var quad: Array = []
			for zz in [z0, z1]:
				var t: float = absf(zz) / (length * 0.5)
				var w: float = beam * 0.5 * sqrt(maxf(1.0 - pow(t, 3.0), 0.05))
				var d: float = depth * sqrt(maxf(1.0 - pow(t, 4.0), 0.1))
				for aa in [a0, a1]:
					quad.append(Vector3(cos(aa) * w, -sin(aa) * d + depth, zz))
			var n0: Vector3 = (quad[1] - quad[0]).cross(quad[2] - quad[0]).normalized()
			for k in [0, 2, 1, 1, 2, 3]:
				st.set_normal(-n0)
				st.set_uv(Vector2(quad[k].z / 3.0, (quad[k].y + quad[k].x) / 3.0))
				st.add_vertex(quad[k])
	st.generate_tangents()
	return st.commit()


func _build_wreck() -> void:
	var w := Node3D.new()
	w.name = "Epave_Sirene_Noire_v55"
	add_child(w)
	w.global_position = WRECK + Vector3(0, -1.5, 0)
	w.rotation = Vector3(0.05, 0.6, 0.26)        # couchée sur le flanc, à moitié ensablée
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = _tex("res://assets/textures/mer/epave_bois.png")
	wood.normal_enabled = true
	wood.normal_texture = _tex("res://assets/textures/mer/epave_bois_n.png")
	wood.roughness = 0.95
	wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	wood.uv1_triplanar = false
	var hull := MeshInstance3D.new()
	hull.name = "Coque"
	hull.mesh = _hull_mesh(22.0, 7.0, 4.2, Vector2(-1.5, 3.0))
	hull.material_override = wood
	w.add_child(hull)
	var body := StaticBody3D.new()
	body.name = "Epave_collision"
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var shape: ConcavePolygonShape3D = hull.mesh.create_trimesh_shape()
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	w.add_child(body)
	# Pont arrière, mât brisé couché, vergue, canons, tonneaux
	var deck := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(6.4, 0.2, 7.0)
	deck.mesh = bm
	deck.material_override = wood
	deck.position = Vector3(0, 4.0, -7.0)
	w.add_child(deck)
	var mast := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.3
	cm.height = 14.0
	mast.mesh = cm
	mast.material_override = wood
	mast.position = Vector3(5.5, 1.0, 1.0)
	mast.rotation = Vector3(0.1, 0.0, 1.45)
	w.add_child(mast)
	var stump := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.28
	cm2.bottom_radius = 0.32
	cm2.height = 3.0
	stump.mesh = cm2
	stump.material_override = wood
	stump.position = Vector3(0, 5.0, 4.0)
	w.add_child(stump)
	var iron := mat("fer_rouille", Color(0.28, 0.22, 0.18), 0.8)
	for k in range(3):
		var cannon := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.14
		cc.bottom_radius = 0.2
		cc.height = 1.8
		cannon.mesh = cc
		cannon.material_override = iron
		cannon.position = Vector3(2.6, 3.4, -4.0 + k * 3.5)
		cannon.rotation = Vector3(0, 0, PI * 0.5)
		w.add_child(cannon)
	for k in range(4):
		var barrel := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.38
		bc.bottom_radius = 0.38
		bc.height = 1.0
		barrel.mesh = bc
		barrel.material_override = wood
		barrel.position = Vector3(-2.0 + k * 0.9, 0.8, 1.5 + (k % 2) * 1.2)
		barrel.rotation = Vector3(PI * 0.5 * (k % 2), k, 0)
		w.add_child(barrel)
	# Le coffre du capitaine, dans la brèche : la Perle de l'Épave
	var chest := Node3D.new()
	chest.name = "Coffre_epave"
	w.add_child(chest)
	chest.position = Vector3(-0.6, 0.9, 0.8)
	var box := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(1.0, 0.6, 0.65)
	box.mesh = bx
	box.material_override = wood
	box.position.y = 0.3
	chest.add_child(box)
	wreck_lid = Node3D.new()
	wreck_lid.name = "Couvercle"
	wreck_lid.position = Vector3(0, 0.6, -0.32)
	chest.add_child(wreck_lid)
	var lid := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(1.04, 0.18, 0.68)
	lid.mesh = lb
	lid.material_override = wood
	lid.position = Vector3(0, 0.09, 0.33)
	wreck_lid.add_child(lid)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.06, 0.06, 0.7)
	band.mesh = bb
	band.material_override = mat("laiton_terni", Color(0.55, 0.45, 0.25), 0.5)
	band.position = Vector3(0, 0.45, 0)
	chest.add_child(band)
	wreck_pearl = _pearl()
	wreck_pearl.position = Vector3(0, 0.62, 0)
	chest.add_child(wreck_pearl)
	wreck_pearl.visible = false
	# Le coffre et les tonneaux reposent sur le sable, dans la brèche
	var cg: Vector3 = chest.global_position
	chest.global_transform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(cg.x, height(cg.x, cg.z) + 0.02, cg.z))
	for b in w.get_children():
		if b is MeshInstance3D and (b as MeshInstance3D).mesh is CylinderMesh and ((b as MeshInstance3D).mesh as CylinderMesh).top_radius > 0.35:
			var bg: Vector3 = (b as Node3D).global_position
			(b as Node3D).global_position = Vector3(bg.x, height(bg.x, bg.z) + 0.3, bg.z)
	points["coffre_epave"] = chest.global_position + Vector3.UP * 0.6
	# Une ancre et sa chaîne, à côté
	var anchor := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.25, 2.2, 0.25)
	anchor.mesh = am
	anchor.material_override = iron
	add_child(anchor)
	anchor.global_position = WRECK + Vector3(9.0, 0.6, -6.0)
	anchor.rotation = Vector3(0.0, 0.4, 1.2)


# =================================================================== la fosse

func _build_trench() -> void:
	# Des rochers sombres le long des parois
	var rock_mat: Material = Rocks.material(Color(0.5, 0.5, 0.54), 0.25, 0.2)
	var meshes: Array = []
	for k in range(3):
		meshes.append(Rocks.shape(5560 + k, Vector3(1.0, 0.8, 1.0), 0.5, 0.26, 1.2, 18))
	var groups: Array = [[], [], []]
	for k2 in range(70):
		var t: float = _rng.randf()
		var p: Vector2 = TRENCH_A.lerp(TRENCH_B, t)
		var dirv: Vector2 = (TRENCH_B - TRENCH_A).normalized()
		var side: Vector2 = Vector2(-dirv.y, dirv.x) * (1.0 if k2 % 2 == 0 else -1.0)
		var q: Vector2 = p + side * _rng.randf_range(8.0, 14.0)
		var y: float = height(q.x, q.y)
		var sc: float = _rng.randf_range(1.5, 4.0)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc * 1.4, sc))
		groups[k2 % 3].append(Transform3D(b, Vector3(q.x, y - sc * 0.15, q.y)))
	for k3 in range(3):
		_mm(meshes[k3], groups[k3], rock_mat, "Fosse_rochers_v55_%d" % k3, 160.0)
	# L'autel, au fond : la Perle de la Fosse
	var mid: Vector2 = TRENCH_A.lerp(TRENCH_B, 0.62)
	var y0: float = height(mid.x, mid.y)
	var altar := Node3D.new()
	altar.name = "Autel_fosse_v55"
	add_child(altar)
	altar.global_position = Vector3(mid.x, y0, mid.y)
	var stone := mat("pierre_autel", Color(0.55, 0.6, 0.62), 0.8)
	var ped := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.55
	pc.bottom_radius = 0.75
	pc.height = 1.2
	ped.mesh = pc
	ped.material_override = stone
	ped.position.y = 0.6
	altar.add_child(ped)
	for sx in [-1.0, 1.0]:
		var col := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.25
		cc.bottom_radius = 0.3
		cc.height = 4.0
		col.mesh = cc
		col.material_override = stone
		col.position = Vector3(sx * 2.0, 2.0, 0)
		altar.add_child(col)
	var lintel := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(5.0, 0.5, 0.7)
	lintel.mesh = lb
	lintel.material_override = stone
	lintel.position = Vector3(0, 4.2, 0)
	lintel.rotation.z = 0.08
	altar.add_child(lintel)
	altar_pearl = _pearl()
	altar_pearl.position = Vector3(0, 1.4, 0)
	altar.add_child(altar_pearl)
	points["autel_fosse"] = altar.global_position + Vector3.UP * 1.2
	points["fosse"] = Vector3(mid.x, y0 + 6.0, mid.y)
	var body := StaticBody3D.new()
	body.name = "Autel_collision"
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.75
	cyl.height = 1.2
	cs.shape = cyl
	cs.position.y = 0.6
	body.add_child(cs)
	altar.add_child(body)


# =================================================================== quête

func open_clam(instant: bool = false) -> void:
	if clam_top == null:
		return
	if instant:
		clam_top.rotation.x = -0.6
	else:
		create_tween().tween_property(clam_top, "rotation:x", -0.6, 1.6).set_trans(Tween.TRANS_SINE)


func open_wreck_chest(instant: bool = false) -> void:
	if wreck_lid == null:
		return
	wreck_pearl.visible = true
	if instant:
		wreck_lid.rotation.x = -1.7
	else:
		create_tween().tween_property(wreck_lid, "rotation:x", -1.7, 0.9).set_trans(Tween.TRANS_BACK)

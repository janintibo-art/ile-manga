extends RefCounted
## V26 : fabrique de roches réalistes (blocs de falaise, rochers, galets, pierres plates).
## Une sphère est déformée par un bruit 3D, rendue plus ou moins anguleuse et striée
## de couches horizontales. Chaque forme n'est calculée qu'une fois (cache statique).

const ROCK_SHADER := "res://shaders/rock_v26.gdshader"

static var _cache: Dictionary = {}


static func material(tint: Color = Color(0.72, 0.7, 0.66), moss: float = 0.45, texture_scale: float = 0.22) -> ShaderMaterial:
	var key := "mat_%s_%d_%d" % [tint.to_html(), int(moss * 100.0), int(texture_scale * 100.0)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = load(ROCK_SHADER)
	m.set_shader_parameter("stone_tex", load("res://assets/textures/terrain/rock.jpg"))
	m.set_shader_parameter("stone_n", load("res://assets/textures/terrain/rock_n.png"))
	m.set_shader_parameter("moss_tex", load("res://assets/textures/terrain/grass.jpg"))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("moss_amount", moss)
	m.set_shader_parameter("texture_scale", texture_scale)
	_cache[key] = m
	return m


## Forme de roche. boxiness < 1 : faces plus droites (falaise) ; 1 : galet arrondi.
## size : dimensions finales (m), intégrées au maillage pour des collisions exactes.
## flatten_top : au-dessus de cette hauteur relative (-1..1), le sommet est aplani.
static func shape(seed_value: int, size: Vector3, boxiness: float = 0.8, bumpiness: float = 0.16, flatten_top: float = 2.0, segments: int = 24) -> ArrayMesh:
	var key := "rock_%d_%s_%d_%d_%d_%d" % [seed_value, str(size), int(boxiness * 100.0), int(bumpiness * 100.0), int(flatten_top * 100.0), segments]
	if _cache.has(key):
		return _cache[key]
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	var arrays: Array = sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.9
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	var strata_noise := FastNoiseLite.new()
	strata_noise.seed = seed_value + 7
	strata_noise.frequency = 1.6
	for i in range(verts.size()):
		var v: Vector3 = verts[i]
		# Sphère -> superellipsoïde : faces plus planes quand boxiness < 1.
		var b := Vector3(signf(v.x) * pow(absf(v.x), boxiness), signf(v.y) * pow(absf(v.y), boxiness), signf(v.z) * pow(absf(v.z), boxiness))
		# Grosses bosses (silhouette irrégulière) + détail fin.
		var bump: float = noise.get_noise_3dv(v * 0.55) * bumpiness * 1.3 + noise.get_noise_3dv(v * 1.9) * bumpiness * 0.6
		var strata: float = sin(v.y * 15.0 + strata_noise.get_noise_3d(v.x, v.y, v.z) * 4.0) * 0.022
		var p: Vector3 = b * (1.0 + bump + strata)
		if p.y > flatten_top:
			p.y = flatten_top + (p.y - flatten_top) * 0.12
		verts[i] = p * size * 0.5
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = null
	arrays[Mesh.ARRAY_TANGENT] = null
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(raw, 0)
	st.generate_normals()
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Galet de plage ou rocher posé : ~0,85 m de large, 0,32 m de haut à l'échelle 1.
static func pebble(seed_value: int, material_override: Material = null) -> ArrayMesh:
	var key := "pebble_%d" % seed_value
	if _cache.has(key):
		return _cache[key]
	var mesh: ArrayMesh = shape(seed_value, Vector3(0.84, 0.32, 0.7), 0.85, 0.22, 2.0, 14).duplicate()
	mesh.surface_set_material(0, material_override if material_override != null else material(Color.WHITE, 0.1, 0.9))
	_cache[key] = mesh
	return mesh


## Pierre plate (pas japonais, dallage du village).
static func flat_stone(seed_value: int) -> ArrayMesh:
	var key := "flat_%d" % seed_value
	if _cache.has(key):
		return _cache[key]
	var mesh: ArrayMesh = shape(seed_value, Vector3(0.48, 0.12, 0.44), 0.6, 0.12, 0.4, 12).duplicate()
	mesh.surface_set_material(0, material(Color.WHITE, 0.15, 0.9))
	_cache[key] = mesh
	return mesh


## Collision exacte d'une roche placée avec une base (rotation + échelle) : on intègre
## la base aux sommets, les formes concaves ne supportant pas les échelles.
static func collision_for(mesh: Mesh, xf: Transform3D) -> CollisionShape3D:
	var faces := mesh.get_faces()
	for i in range(faces.size()):
		faces[i] = xf.basis * faces[i]
	var shape_res := ConcavePolygonShape3D.new()
	shape_res.set_faces(faces)
	shape_res.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape_res
	cs.position = xf.origin
	return cs

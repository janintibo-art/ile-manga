extends RefCounted
## V25 : fabrique de végétation réaliste, partagée par tous les scripts de décor.
## Chaque maillage et chaque matériau n'est construit qu'une fois (cache statique).
## Convention des maillages : UV2.x = souplesse au vent, UV2.y = 0 au cœur / 1 à l'extérieur.

const FOLIAGE_SHADER := "res://shaders/foliage_v25.gdshader"
const FLORA_DIR := "res://assets/textures/flora/"

static var _cache: Dictionary = {}


static func _cached(key: String) -> Variant:
	return _cache.get(key, null)


static func _store(key: String, value: Variant) -> Variant:
	_cache[key] = value
	return value


# ---------------------------------------------------------------- matériaux

static func _foliage(key: String, tex: String, normal: String, wind: float, translucency: float) -> ShaderMaterial:
	var hit: Variant = _cached("mat_" + key)
	if hit != null:
		return hit
	var m := ShaderMaterial.new()
	m.shader = load(FOLIAGE_SHADER)
	if tex != "":
		m.set_shader_parameter("albedo_tex", load(FLORA_DIR + tex))
	else:
		m.set_shader_parameter("use_texture", false)
	if normal != "":
		m.set_shader_parameter("normal_tex", load(FLORA_DIR + normal))
		m.set_shader_parameter("use_normal", true)
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("translucency", translucency)
	return _store("mat_" + key, m)


static func leaf_material() -> ShaderMaterial:
	return _foliage("leaves", "leaves.png", "leaves_n.png", 0.16, 0.45)


static func bark_material() -> ShaderMaterial:
	var m := _foliage("bark", "bark.png", "bark_n.png", 0.05, 0.0)
	m.set_shader_parameter("roughness_value", 0.92)
	return m


static func grass_material() -> ShaderMaterial:
	return _foliage("grass", "", "", 0.11, 0.35)


static func reed_material() -> ShaderMaterial:
	var hit: Variant = _cached("mat_reed")
	if hit != null:
		return hit
	var m := _foliage("reed_base", "", "", 0.14, 0.3).duplicate()
	m.set_shader_parameter("base_color", Color(0.22, 0.3, 0.12))
	m.set_shader_parameter("tip_color", Color(0.7, 0.66, 0.38))
	return _store("mat_reed", m)


static func flower_material(color: Color = Color.WHITE) -> ShaderMaterial:
	var key := "mat_flower_" + color.to_html()
	var hit: Variant = _cached(key)
	if hit != null:
		return hit
	var m := _foliage("flower_base", "flowers.png", "", 0.09, 0.3).duplicate()
	m.set_shader_parameter("tint_petals", true)
	m.set_shader_parameter("tint", color)
	return _store(key, m)


static func fern_material() -> ShaderMaterial:
	return _foliage("fern", "fern.png", "", 0.1, 0.4)


# ---------------------------------------------------------------- outils de maillage

static func _vertex(st: SurfaceTool, pos: Vector3, normal: Vector3, uv: Vector2, flex: float, outer: float) -> void:
	st.set_color(Color.WHITE)
	st.set_normal(normal)
	st.set_uv(uv)
	st.set_uv2(Vector2(flex, outer))
	st.add_vertex(pos)


# Tube (tronc ou branche) le long d'un chemin, avec écorce répétée.
static func _tube(st: SurfaceTool, path: Array[Vector3], radii: Array[float], flex: Array[float], sides: int) -> void:
	var length_along: float = 0.0
	var rings: Array = []
	for i in range(path.size()):
		var forward: Vector3
		if i < path.size() - 1:
			forward = (path[i + 1] - path[i]).normalized()
		else:
			forward = (path[i] - path[i - 1]).normalized()
		var side := forward.cross(Vector3(0.31, 0.0, 0.95)).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		var up := side.cross(forward).normalized()
		if i > 0:
			length_along += path[i].distance_to(path[i - 1])
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / float(sides)
			var n: Vector3 = (side * cos(a) + up * sin(a)).normalized()
			ring.append([path[i] + n * radii[i], n, Vector2(float(s) / float(sides) * 2.0, length_along * 0.7), flex[i]])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a: Array = rings[i][s]
			var b: Array = rings[i][s + 1]
			var c: Array = rings[i + 1][s]
			var d: Array = rings[i + 1][s + 1]
			for v in [a, c, b, b, c, d]:
				_vertex(st, v[0], v[1], v[2], v[3], 0.6)


# Carte de feuillage : un carré orienté au hasard, normale « sphérique » vers l'extérieur
# de la couronne (le feuillage s'éclaire comme un volume, pas comme des plaques).
static func _card(st: SurfaceTool, center: Vector3, size: float, basis: Basis, crown_center: Vector3, crown_radius: float, flex: float) -> void:
	var half_x: Vector3 = basis.x * size * 0.5
	var half_y: Vector3 = basis.y * size * 0.5
	var out_dir: Vector3 = (center - crown_center + Vector3.UP * crown_radius * 0.35).normalized()
	var outer: float = clampf(center.distance_to(crown_center) / maxf(crown_radius, 0.01), 0.0, 1.0)
	var p := [center - half_x - half_y, center + half_x - half_y, center + half_x + half_y, center - half_x + half_y]
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in [0, 1, 2, 0, 2, 3]:
		var corner: Vector3 = p[i]
		var n: Vector3 = (out_dir * 0.8 + (corner - center).normalized() * 0.2).normalized()
		_vertex(st, corner, n, uv[i], flex, outer)


static func _random_basis(rng: RandomNumberGenerator) -> Basis:
	var b := Basis(Vector3.UP, rng.randf() * TAU)
	b = b.rotated(b.x, rng.randf_range(-1.2, 1.2))
	return b.rotated(b.z, rng.randf_range(-0.8, 0.8)).orthonormalized()


# ---------------------------------------------------------------- arbres et buissons

## Feuillu réaliste : tronc légèrement penché, charpentières, rameaux et grappes de feuilles.
## height = hauteur totale approximative (m). Variantes stables grâce à seed.
static func tree(seed_value: int, height: float = 7.0, leaf_count: int = 260) -> ArrayMesh:
	var key := "tree_%d_%d_%d" % [seed_value, int(height * 10.0), leaf_count]
	var hit: Variant = _cached(key)
	if hit != null:
		return hit
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bark_st := SurfaceTool.new()
	bark_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaf_st := SurfaceTool.new()
	leaf_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk_h: float = height * rng.randf_range(0.5, 0.6)
	var lean := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
	var trunk: Array[Vector3] = []
	var radii: Array[float] = []
	var flex: Array[float] = []
	for i in range(7):
		var t: float = float(i) / 6.0
		trunk.append(Vector3.UP * trunk_h * t + lean * t * t + Vector3(rng.randf_range(-0.05, 0.05), 0, rng.randf_range(-0.05, 0.05)) * t)
		radii.append(lerpf(0.32, 0.13, t) * (1.18 if i == 0 else 1.0))
		flex.append(t * t * 0.15)
	_tube(bark_st, trunk, radii, flex, 9)
	var crown_center := Vector3.UP * height * 0.68 + lean
	var crown_radius: float = height * 0.36
	var leaf_budget: int = leaf_count
	var branches: int = rng.randi_range(7, 10)
	for b in range(branches):
		var t0: float = rng.randf_range(0.45, 1.0)
		var start: Vector3 = trunk[int(t0 * 6.0)]
		var a: float = TAU * float(b) / float(branches) + rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), rng.randf_range(0.55, 1.15), sin(a)).normalized()
		var blen: float = crown_radius * rng.randf_range(0.8, 1.15) * (1.15 - t0 * 0.35)
		var path: Array[Vector3] = [start]
		var br_r: Array[float] = []
		var br_f: Array[float] = []
		for s in range(1, 5):
			var p: Vector3 = path[s - 1] + dir * blen / 4.0
			p += Vector3(rng.randf_range(-0.12, 0.12), 0.08 * s, rng.randf_range(-0.12, 0.12))
			path.append(p)
		for s in range(path.size()):
			br_r.append(lerpf(0.12 * (1.2 - t0 * 0.4), 0.025, float(s) / 4.0))
			br_f.append(0.2 + 0.5 * float(s) / 4.0)
		_tube(bark_st, path, br_r, br_f, 6)
		# Grappes de feuilles sur la moitié extérieure de la branche et sur ses rameaux.
		var cards: int = leaf_budget / branches
		for c in range(cards):
			var along: float = rng.randf_range(0.35, 1.0)
			var seg: float = along * 4.0
			var i0: int = mini(int(seg), 3)
			var base: Vector3 = path[i0].lerp(path[i0 + 1], seg - float(i0))
			var offset := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1.0), rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.2, 0.9)
			_card(leaf_st, base + offset, rng.randf_range(1.0, 1.55), _random_basis(rng), crown_center, crown_radius, 0.6 + 0.4 * along)
	# Couronne sommitale : quelques grappes pour fermer le haut de l'arbre.
	for c in range(leaf_budget / 8):
		var p: Vector3 = trunk[6] + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.0), rng.randf_range(-1, 1)) * crown_radius * 0.55
		_card(leaf_st, p, rng.randf_range(1.0, 1.4), _random_basis(rng), crown_center, crown_radius, 0.8)
	var mesh := ArrayMesh.new()
	bark_st.commit(mesh)
	leaf_st.commit(mesh)
	mesh.surface_set_material(0, bark_material())
	mesh.surface_set_material(1, leaf_material())
	return _store(key, mesh)


## Buisson : quelques tiges courtes et un volume de feuillage ellipsoïdal (1,6 m x 1,05 m).
static func bush(seed_value: int = 7) -> ArrayMesh:
	var key := "bush_%d" % seed_value
	var hit: Variant = _cached(key)
	if hit != null:
		return hit
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stems := SurfaceTool.new()
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in range(5):
		var a: float = rng.randf() * TAU
		var tip := Vector3(cos(a) * 0.4, 0.75, sin(a) * 0.4)
		_tube(stems, [Vector3.ZERO, tip * 0.5 + Vector3.UP * 0.1, tip] as Array[Vector3], [0.04, 0.03, 0.012] as Array[float], [0.0, 0.3, 0.6] as Array[float], 5)
	var center := Vector3(0, 0.55, 0)
	for c in range(46):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 1), rng.randf_range(-1, 1)).normalized()
		var p: Vector3 = center + Vector3(d.x * 0.62, d.y * 0.38, d.z * 0.62) * rng.randf_range(0.45, 1.0)
		_card(leaves, p, rng.randf_range(0.6, 0.85), _random_basis(rng), center, 0.7, 0.4 + 0.5 * clampf(p.y / 1.0, 0.0, 1.0))
	var mesh := ArrayMesh.new()
	stems.commit(mesh)
	leaves.commit(mesh)
	mesh.surface_set_material(0, bark_material())
	mesh.surface_set_material(1, leaf_material())
	return _store(key, mesh)


# ---------------------------------------------------------------- herbe, roseaux, fleurs, fougères

## Touffe d'herbe : brins effilés et courbés (géométrie réelle, pas de texture).
static func grass_clump(blades: int = 11, height: float = 0.5, width: float = 0.05, seed_value: int = 3) -> ArrayMesh:
	var key := "grass_%d_%d_%d_%d" % [blades, int(height * 100.0), int(width * 1000.0), seed_value]
	var hit: Variant = _cached(key)
	if hit != null:
		return hit
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in range(blades):
		var a: float = rng.randf() * TAU
		var root := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.11)
		var lean := Vector3(cos(a + rng.randf_range(-0.6, 0.6)), 0, sin(a + rng.randf_range(-0.6, 0.6)))
		var h: float = height * rng.randf_range(0.6, 1.15)
		var bend: float = rng.randf_range(0.12, 0.42)
		var face: float = rng.randf() * TAU
		var side := Vector3(cos(face), 0, sin(face)) * width * rng.randf_range(0.7, 1.25)
		var n: Vector3 = (Vector3.UP * 0.75 + lean * 0.25).normalized()
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for s in range(5):
			var t: float = float(s) / 4.0
			var center: Vector3 = root + Vector3.UP * h * t + lean * bend * h * t * t
			var half: Vector3 = side * 0.5 * (1.0 - t * 0.92)
			var l: Vector3 = center - half
			var r: Vector3 = center + half
			if s > 0:
				var t0: float = float(s - 1) / 4.0
				_vertex(st, prev_l, n, Vector2(0, t0), t0 * t0, t0)
				_vertex(st, l, n, Vector2(0, t), t * t, t)
				_vertex(st, prev_r, n, Vector2(1, t0), t0 * t0, t0)
				_vertex(st, prev_r, n, Vector2(1, t0), t0 * t0, t0)
				_vertex(st, l, n, Vector2(0, t), t * t, t)
				_vertex(st, r, n, Vector2(1, t), t * t, t)
			prev_l = l
			prev_r = r
	var mesh := st.commit()
	mesh.surface_set_material(0, grass_material())
	return _store(key, mesh)


static func reed_clump() -> ArrayMesh:
	var hit: Variant = _cached("reed_mesh")
	if hit != null:
		return hit
	var mesh: ArrayMesh = grass_clump(8, 1.0, 0.035, 11).duplicate()
	mesh.surface_set_material(0, reed_material())
	return _store("reed_mesh", mesh)


# Cartes verticales croisées portant une texture détourée (fleurs, fougères).
static func _crossed(st: SurfaceTool, w: float, h: float, planes: int, rot0: float) -> void:
	for p in range(planes):
		var a: float = rot0 + PI * float(p) / float(planes)
		var side := Vector3(cos(a), 0, sin(a)) * w * 0.5
		var corners := [-side, side, side + Vector3.UP * h, -side + Vector3.UP * h]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in [0, 1, 2, 0, 2, 3]:
			var c: Vector3 = corners[i]
			var t: float = c.y / h
			_vertex(st, c, (Vector3.UP * 0.7 + side.normalized().cross(Vector3.UP) * 0.3).normalized(), uvs[i], t * t, 0.35 + 0.65 * t)


static func flower_clump() -> ArrayMesh:
	var hit: Variant = _cached("flower_mesh")
	if hit != null:
		return hit
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_crossed(st, 0.55, 0.55, 3, 0.4)
	var mesh := st.commit()
	mesh.surface_set_material(0, flower_material())
	return _store("flower_mesh", mesh)


## Fougère : frondes inclinées vers l'extérieur en rosette.
static func fern_clump() -> ArrayMesh:
	var hit: Variant = _cached("fern_mesh")
	if hit != null:
		return hit
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in range(7):
		var a: float = TAU * float(f) / 7.0 + 0.3 * sin(float(f) * 3.1)
		var out := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-sin(a), 0, cos(a)) * 0.2
		var tilt: float = 0.75 + 0.25 * sin(float(f) * 1.7)
		var up_axis: Vector3 = (Vector3.UP * cos(tilt) + out * sin(tilt)).normalized() * 0.85
		var corners := [-side, side, side + up_axis, -side + up_axis]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		var n: Vector3 = (Vector3.UP + out * 0.4).normalized()
		for i in [0, 1, 2, 0, 2, 3]:
			var t: float = 1.0 if i in [2, 3] else 0.0
			_vertex(st, corners[i], n, uvs[i], t * 0.8, 0.4 + 0.6 * t)
	var mesh := st.commit()
	mesh.surface_set_material(0, fern_material())
	return _store("fern_mesh", mesh)

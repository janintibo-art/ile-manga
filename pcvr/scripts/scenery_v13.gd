extends Node3D
## V26 : deux chutes d'eau réalistes. Chaque site : un massif de roche sculptée,
## une chute qui tombe de la lèvre du rocher, un bassin creusé au pied (voir carve),
## de la brume et des éclaboussures. Les roches sont solides ; l'eau se traverse.
## (Fichier historique de la V13 : les anciens piliers cylindriques sont remplacés.)

const Rocks = preload("res://scripts/rocks_v26.gd")

## Sites : centre du massif, hauteur, graine. La chute regarde vers le centre de l'île.
const SITES := [
	[Vector2(43.0, -33.0), 20.0, 1410],
	[Vector2(-45.0, -39.0), 18.0, 2610],
]
const FRONT: float = 5.5        # demi-profondeur du bloc central (m)
const POOL_DIST: float = 9.2     # distance centre du massif -> centre du bassin
const POOL_RADIUS: float = 5.6
const BOWL_OUTER: float = 2.4    # le creux déborde du bassin : le bord de l'eau reste sous le sol


static var _pools: Array[Vector2] = []


## Vrai si (x, z) est assez près d'un bassin pour que le relief y soit modifié (test rapide).
static func near_pool(x: float, z: float) -> bool:
	if _pools.is_empty():
		for site in SITES:
			_pools.append(pool_center(site[0]))
	var reach: float = POOL_RADIUS + BOWL_OUTER + 2.5
	for p in _pools:
		if absf(x - p.x) < reach and absf(z - p.y) < reach:
			return true
	return false


static func facing(center: Vector2) -> Vector3:
	return Vector3(-center.x, 0.0, -center.y).normalized()


static func pool_center(center: Vector2) -> Vector2:
	var f := facing(center)
	return center + Vector2(f.x, f.z) * POOL_DIST


## Bassins creusés au pied des chutes (appelé par main._height_at) : niveau d'eau plat,
## fond 1,3 m plus bas, et un petit talus qui retient l'eau du côté de la pente.
## base_height = relief sans bassin ; land = relief en (x, z).
static func carve(x: float, z: float, land: float, base_height: Callable) -> float:
	for site in SITES:
		var p: Vector2 = pool_center(site[0])
		var d: float = Vector2(x, z).distance_to(p)
		if d > POOL_RADIUS + BOWL_OUTER + 2.5:
			continue
		var water: float = water_level(p, base_height)
		var ring: float = smoothstep(POOL_RADIUS + BOWL_OUTER + 2.5, POOL_RADIUS + 0.5, d)
		var shaped: float = maxf(land, lerpf(land, water + 0.25, ring))
		var bowl: float = smoothstep(POOL_RADIUS + 0.6, POOL_RADIUS - 1.2, d)
		return lerpf(shaped, water - 1.3, bowl)
	return land


static func water_level(pool: Vector2, base_height: Callable) -> float:
	return float(base_height.call(pool.x, pool.y)) - 0.3


## Zone occupée par un massif et son bassin (pour ne pas y semer d'herbe ou d'arbres).
static func occupied(x: float, z: float, margin: float = 0.0) -> bool:
	for site in SITES:
		var c: Vector2 = site[0]
		if Vector2(x, z).distance_to(c) < 11.0 + margin or Vector2(x, z).distance_to(pool_center(c)) < POOL_RADIUS + 1.0 + margin:
			return true
	return false


func build(height_func: Callable, pc_quality: bool) -> void:
	for site in SITES:
		_make_site(site[0], site[1], site[2], height_func, pc_quality)
	print("ILE_MANGA_V26: deux massifs rocheux, deux chutes d'eau et leurs bassins")


func _make_site(center: Vector2, height: float, seed_value: int, ground: Callable, pc: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var f := facing(center)
	var r := Vector3(f.z, 0.0, -f.x)
	var yaw: float = atan2(f.x, f.z)
	var c3 := Vector3(center.x, float(ground.call(center.x, center.y)), center.y)
	var top_h: float = height * 0.62
	var body := StaticBody3D.new()
	body.name = "Falaise_collision_v26"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	# Lèvre de la chute : juste sous le sommet aplani du bloc central.
	# (l'arête du bloc est arrondie : l'eau sort de la face, 1 m sous le plateau)
	var lip_y: float = c3.y + (top_h * 0.5 - 1.6) + 0.8 * (top_h + 3.2) * 0.5 - 1.0
	var rock_mat: ShaderMaterial = Rocks.material(Color(0.7, 0.68, 0.64), 0.5, 0.12).duplicate()
	rock_mat.set_shader_parameter("wet_zone", Vector4(c3.x + f.x * FRONT, lip_y - 4.0, c3.z + f.z * FRONT, 8.0))

	# Bloc central, face avant presque verticale : la chute part de son rebord.
	_rock(body, rock_mat, seed_value, c3 + Vector3.UP * (top_h * 0.5 - 1.6), Vector3(13.0, top_h + 3.2, FRONT * 2.0), yaw, 0.6, 0.12, 0.8, pc)
	# Deux épaulements qui encadrent la lèvre (effet de gorge).
	for side in [-1.0, 1.0]:
		var pos: Vector3 = c3 + r * side * 6.2 + f * 1.2 + Vector3.UP * (top_h * 0.55)
		_rock(body, rock_mat, seed_value + int(side * 31.0), pos, Vector3(6.5, top_h + 5.0, 9.0), yaw + side * 0.25, 0.7, 0.2, 0.7, pc)
		# Contrefort bas devant l'épaulement : casse la verticale du massif.
		var low: Vector3 = c3 + r * side * 7.5 + f * 4.5 + Vector3.UP * 1.8
		_rock(body, rock_mat, seed_value + int(side * 57.0), low, Vector3(5.5, 6.0, 5.0), yaw + side * 0.6, 0.75, 0.22, 0.6, pc)
	# Arrière du massif : blocs plus hauts qui donnent la silhouette de falaise.
	for i in range(5):
		var a: float = lerpf(-1.1, 1.1, float(i) / 4.0)
		var back: Vector3 = c3 - f * rng.randf_range(5.5, 8.0) + r * sin(a) * 8.5 - f * (1.0 - cos(a)) * 3.0
		var h: float = height * rng.randf_range(0.75, 1.0)
		_rock(body, rock_mat, seed_value + 100 + i, back + Vector3.UP * (h * 0.5 - 1.5), Vector3(rng.randf_range(6.0, 9.0), h + 3.0, rng.randf_range(6.0, 8.5)), yaw + rng.randf_range(-0.5, 0.5), 0.68, 0.22, 0.75, pc)
	# Rochers tombés au pied, de part et d'autre du bassin.
	for i in range(7 if pc else 4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var p2: Vector3 = c3 + f * rng.randf_range(3.0, 12.0) + r * side * rng.randf_range(6.5, 10.0)
		var s: float = rng.randf_range(1.2, 2.8)
		p2.y = float(ground.call(p2.x, p2.z)) + s * 0.25
		_rock(body, rock_mat, seed_value + 300 + i, p2, Vector3(s * 1.3, s, s * 1.1), rng.randf() * TAU, 0.75, 0.2, 2.0, pc)

	# Bassin : niveau d'eau juste sous le bord le plus bas.
	var pool := pool_center(center)
	# Le fond du bassin est exactement 1,3 m sous le niveau de l'eau (voir carve).
	var water_y: float = float(ground.call(pool.x, pool.y)) + 1.3
	_make_pool(Vector3(pool.x, water_y, pool.y), pc)
	_make_fall(c3, f, r, lip_y, water_y, pc)


func _rock(body: StaticBody3D, mat: Material, seed_value: int, pos: Vector3, size: Vector3, yaw: float, boxiness: float, bump: float, flatten: float, pc: bool) -> void:
	var mesh: ArrayMesh = Rocks.shape(seed_value, size, boxiness, bump, flatten, 56 if pc else 36)
	var item := MeshInstance3D.new()
	item.name = "Roche_falaise_v26"
	item.mesh = mesh
	item.material_override = mat
	item.rotation.y = yaw
	item.position = pos
	add_child(item)
	body.add_child(Rocks.collision_for(mesh, Transform3D(Basis(Vector3.UP, yaw), pos)))


# Nappe d'eau : déversoir sur le plateau, puis chute parabolique jusqu'au bassin.
func _make_fall(c3: Vector3, f: Vector3, r: Vector3, lip_y: float, water_y: float, pc: bool) -> void:
	var drop: float = lip_y - water_y
	var rows: int = 28 if pc else 18
	var cols: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for j in range(rows + 1):
		var t: float = float(j) / float(rows)
		var out: float
		var y: float
		if t < 0.12:
			var u: float = t / 0.12
			out = lerpf(-0.9, 0.0, u) + FRONT + 0.7
			y = lip_y + 0.12 - 0.12 * u * u
		else:
			var u2: float = (t - 0.12) / 0.88
			out = FRONT + 0.7 + 1.6 * sqrt(u2) + 0.3 * u2
			y = lip_y - drop * u2
		var width: float = lerpf(4.2, 6.0, clampf((t - 0.12) / 0.88, 0.0, 1.0))
		var row: Array = []
		for i in range(cols + 1):
			var a: float = float(i) / float(cols)
			var across: float = (a - 0.5) * width
			var bulge: float = (1.0 - pow((a - 0.5) * 2.0, 2.0)) * 0.25
			var p: Vector3 = c3 + f * (out + bulge) + r * across
			p.y = y
			row.append([p, Vector2(a, t)])
		grid.append(row)
	for j in range(rows):
		for i in range(cols):
			for idx in [[j, i], [j + 1, i], [j, i + 1], [j, i + 1], [j + 1, i], [j + 1, i + 1]]:
				var v: Array = grid[idx[0]][idx[1]]
				st.set_normal(f)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	var fall := MeshInstance3D.new()
	fall.name = "Chute_eau_v26"
	fall.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/waterfall_v26.gdshader")
	mat.set_shader_parameter("fall_length", drop)
	fall.material_override = mat
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fall)
	# Brume et éclaboussures au point d'impact.
	var impact: Vector3 = c3 + f * (FRONT + 2.6)
	impact.y = water_y + 0.3
	_spray("Brume_cascade_v26", impact, r, 70 if pc else 30, 3.2, 2.6, Color(0.92, 0.95, 0.97, 0.22), Vector2(0.4, 1.2), 0.0)
	_spray("Eclaboussures_v26", impact, r, 90 if pc else 40, 1.1, 0.18, Color(0.95, 0.97, 1.0, 0.7), Vector2(2.0, 4.5), -9.0)


func _spray(label: String, at: Vector3, r: Vector3, amount: int, lifetime: float, size: float, color: Color, speed: Vector2, gravity: float) -> void:
	var parts := GPUParticles3D.new()
	parts.name = label
	parts.amount = amount
	parts.lifetime = lifetime
	parts.position = at
	parts.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 10, 16))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(absf(r.x) * 1.8 + 0.4, 0.2, absf(r.z) * 1.8 + 0.4)
	pm.direction = Vector3.UP
	pm.spread = 55.0
	pm.initial_velocity_min = speed.x
	pm.initial_velocity_max = speed.y
	pm.gravity = Vector3(0, gravity, 0)
	pm.damping_min = 0.3
	pm.damping_max = 0.8
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.2, color)
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
	var dot := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = g
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	mat.albedo_texture = dot
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(parts)


func _make_pool(at: Vector3, pc: bool) -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = POOL_RADIUS + 1.0
	disc.bottom_radius = POOL_RADIUS + 1.0
	disc.height = 0.02
	disc.radial_segments = 48
	disc.rings = 1
	disc.cap_bottom = false
	var pool := MeshInstance3D.new()
	pool.name = "Bassin_cascade_v26"
	pool.mesh = disc
	var mat := ShaderMaterial.new()
	if pc:
		mat.shader = load("res://shaders/water_hd.gdshader")
		mat.set_shader_parameter("wave_strength", 0.04)
		mat.set_shader_parameter("absorption", 0.9)
		mat.set_shader_parameter("shallow_color", Color(0.2, 0.55, 0.5))
		mat.set_shader_parameter("deep_color", Color(0.05, 0.2, 0.22))
	else:
		mat.shader = load("res://shaders/water.gdshader")
		mat.set_shader_parameter("water_tex", load("res://assets/textures/water/water.jpg"))
		mat.set_shader_parameter("wave_strength", 0.05)
	mat.set_shader_parameter("ripple_n", load("res://assets/textures/water/water_n.png"))
	pool.material_override = mat
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool.position = at
	add_child(pool)

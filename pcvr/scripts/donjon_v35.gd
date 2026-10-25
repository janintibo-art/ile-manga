extends Node3D
## V35 : le Temple englouti — étape 1 du grand souterrain qui reliera les deux îles.
## Deux trappes de pierre, enterrées : une au centre du cercle de pierres levées au nord du
## village, une près de la tête de pierre à moitié enfouie dans la jungle (à l'ouest de la
## gorge). On les trouve à la pelle (Barnabé et Octave donnent les indices), on les ouvre,
## et l'on descend à 70 m sous terre.
## Côté village (premier niveau) :
##   grotte d'arrivée -> couloir de la fresque (et un mur fissuré qui cache une niche) ->
##   salle des braseros (énigme : allumer les quatre symboles dans le bon ordre) ->
##   escalier -> salle du gardien (coffre, statues) et la Porte du Serpent, scellée.
## Côté jungle : grotte d'arrivée et galerie, bloquée par un éboulement (étape suivante).
## Les monstres et les boss viendront aux étapes suivantes ; la Porte du Serpent s'ouvrira
## avec les trois fragments de l'amulette.

const Y: float = -70.0                  # profondeur du souterrain
const Rocks = preload("res://scripts/rocks_v26.gd")
const ORDER := ["lune", "vague", "soleil", "serpent"]
const TEX := "res://assets/textures/temple/"

var main: Node
var inside: bool = false
var village_trap: Vector3 = Vector3.INF          # surface
var jungle_trap: Vector3 = Vector3.INF
var state := {"trappe_village": 0, "trappe_jungle": 0, "braseros": false, "mur": false, "niche": false, "coffre": false, "visite": false, "passage": false, "grille": false, "eboulement": false, "victoires": 0, "boss1": false, "coffre_boss1": false, "serpents": 45, "enigme_serpents": false, "fragment3": false, "porte_serpent": false, "coffre_sanctuaire": false, "sceau": false, "abysses_bas": false, "lac": false, "coffre_abysses": false, "abime_eveil": false, "porte_abime": false, "naga": false, "coffre_naga": false, "grotte_cascade": false}
var sections: Dictionary = {}                    # "village"/"jungle" -> Node3D (repère local)
var spawn: Dictionary = {}                       # "village"/"jungle" -> [position, regard]
var _interactions: Array = []                    # {id, pos, radius, text, vr, call, when}
var _braziers: Array = []                        # {symbol, node, fire, light, lit}
var _lit: Array = []
var _door: Node3D
var _wall_target: Node3D
var _wall_hp: int = 3
var _wall_node: Node3D
var _traps: Dictionary = {}                      # id -> {root, slab, hole, ladder, pos}
var _body: StaticBody3D
var _mats: Dictionary = {}
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_sphere: MeshInstance3D
var _vr_hint: Label3D
var _env_saved: Dictionary = {}
var _busy: bool = false
# V36 : galerie sous la mer
var tunnel_length: float = 0.0                  # distance entre les deux trappes (m)
var _passage: Node3D
var _grille: Node3D
var _rubble: Node3D
var _rubble_body: CollisionShape3D
# V37 : l'antre de Karkinos, le Crabe-Roi
const BossScript = preload("res://scripts/boss_crabe_v37.gd")
var arena_center: Vector3 = Vector3.INF          # monde
var boss: Node3D
var fight: bool = false
var _grille_est: Node3D
var _herse: Node3D
var _boss_chest: Node3D
var _summoned: Array = []
var _bar_layer: CanvasLayer
var _bar_fill: ColorRect
var _bar_label: Label
var _bar_vr: Label3D
# V38 : la Salle des Quatre Serpents, la Porte du Serpent et le Sanctuaire
const SerpentsScript = preload("res://scripts/serpents_v38.gd")
var serpents: Node3D
# V39 : le Puits des Abysses et le Lac Noir
const AbyssesScript = preload("res://scripts/abysses_v39.gd")
var abysses: Node3D
# V40 : l'antre de Nâga, le combat final
const AntreScript = preload("res://scripts/antre_v40.gd")
var antre: Node3D
var _bar_name: String = "Karkinos, le Crabe-Roi"


func setup(main_node: Node) -> void:
	main = main_node
	_body = StaticBody3D.new()
	_body.name = "Donjon_collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_fade()
	serpents = SerpentsScript.new()
	serpents.name = "Serpents_v38"
	add_child(serpents)
	serpents.setup(self, main)
	abysses = AbyssesScript.new()
	abysses.name = "Abysses_v39"
	add_child(abysses)
	abysses.setup(self, main)
	antre = AntreScript.new()
	antre.name = "Antre_v40"
	add_child(antre)
	antre.setup(self, main)
	_vr_hint = Label3D.new()
	_vr_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_vr_hint.font_size = 40
	_vr_hint.pixel_size = 0.0024
	_vr_hint.outline_size = 10
	_vr_hint.no_depth_test = true
	_vr_hint.visible = false
	add_child(_vr_hint)


# =================================================================== construction

## Appelé une fois le monde en place (physique prête, habitants installés).
func build(jungle_spot: Vector3) -> void:
	village_trap = _find_village_spot()
	jungle_trap = jungle_spot
	if village_trap != Vector3.INF:
		_stone_circle(village_trap)
	if jungle_trap != Vector3.INF:
		_stone_head(jungle_trap)
	if village_trap != Vector3.INF and jungle_trap != Vector3.INF:
		var f: Vector3 = jungle_trap - village_trap
		f.y = 0.0
		f = f.normalized()
		tunnel_length = Vector2(jungle_trap.x - village_trap.x, jungle_trap.z - village_trap.z).length()
		_build_village_section(village_trap, f)
		_build_jungle_section(jungle_trap, -f)
		_build_tunnel(sections["village"], tunnel_length)
		_make_trap("village", village_trap)
		_make_trap("jungle", jungle_trap)
	_apply_state()
	print("ILE_MANGA_V35: trappes ", village_trap, " / ", jungle_trap)


func _find_village_spot() -> Vector3:
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var best := Vector3.INF
	var best_score: float = INF
	for ai in range(-14, 15):
		var a: float = -PI * 0.5 + ai * 0.07
		for r in [30.0, 33.0, 36.0, 39.0, 42.0, 45.0]:
			var p := Vector3(cos(a) * r, 0.0, 4.0 + sin(a) * r)
			var h: float = main._height_at(p.x, p.z)
			if h < 1.2 or h > 14.0:
				continue
			var lo: float = INF
			var hi: float = -INF
			for k in range(12):
				for rr in [2.0, 4.0]:
					var q: float = main._height_at(p.x + cos(k * PI / 6.0) * rr, p.z + sin(k * PI / 6.0) * rr)
					lo = minf(lo, q)
					hi = maxf(hi, q)
			if hi - lo > 1.4:
				continue
			var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, h + 15.0, p.z), Vector3(p.x, h - 2.0, p.z), 1))
			if hit.is_empty() or str(hit.collider.name) != "Sol_collision_v11":
				continue
			var qs := PhysicsShapeQueryParameters3D.new()
			var sph := SphereShape3D.new()
			sph.radius = 4.2
			qs.shape = sph
			qs.collision_mask = 1
			qs.transform = Transform3D(Basis.IDENTITY, hit.position + Vector3.UP * 4.6)
			if not space.intersect_shape(qs, 1).is_empty():
				continue
			var score: float = (hi - lo) + absf(ai) * 0.03
			if score < best_score:
				best_score = score
				best = hit.position
	return best


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	m.uv1_triplanar = true
	match key:
		"mur":
			m.albedo_texture = load(TEX + "temple_wall.png")
			m.normal_enabled = true
			m.normal_texture = load(TEX + "temple_wall_n.png")
			m.normal_scale = 1.3
			m.uv1_scale = Vector3(0.28, 0.28, 0.28)
			m.albedo_color = Color(0.9, 0.86, 0.78)
		"sol":
			m.albedo_texture = load(TEX + "temple_floor.png")
			m.normal_enabled = true
			m.normal_texture = load(TEX + "temple_floor_n.png")
			m.uv1_scale = Vector3(0.2, 0.2, 0.2)
			m.albedo_color = Color(0.82, 0.8, 0.74)
		"plafond":
			m.albedo_texture = load(TEX + "temple_wall.png")
			m.uv1_scale = Vector3(0.2, 0.2, 0.2)
			m.albedo_color = Color(0.5, 0.48, 0.44)
		"grotte":
			m.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/jungle/jungle_rock_n.png")
			m.uv1_scale = Vector3(0.18, 0.18, 0.18)
			m.albedo_color = Color(0.62, 0.6, 0.56)
		"bois":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.uv1_scale = Vector3(1.2, 1.2, 1.2)
			m.albedo_color = Color(0.55, 0.42, 0.3)
		"bronze":
			m.uv1_triplanar = false
			m.albedo_color = Color(0.55, 0.42, 0.22)
			m.metallic = 0.8
			m.roughness = 0.35
		"eau":
			m.uv1_triplanar = false
			m.albedo_color = Color(0.12, 0.3, 0.32, 0.72)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic = 0.2
		"noir":
			m.uv1_triplanar = false
			m.albedo_color = Color(0.0, 0.0, 0.0)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"oeil":
			m.uv1_triplanar = false
			m.albedo_color = Color(0.8, 0.1, 0.08)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.15, 0.08)
			m.emission_energy_multiplier = 2.0
	_mats[key] = m
	return m


func _glyph_mat(symbol: String) -> Material:
	var key: String = "glyphe_" + symbol
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load(TEX + "glyph_" + symbol + ".png")
		m.roughness = 0.85
		_mats[key] = m
	return _mats[key]


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, solid: bool = true, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		cs.shape = s
		_body.add_child(cs)
		cs.global_transform = mi.global_transform
	return mi


## Salle rectangulaire (repère local de la section) : sol, plafond, quatre murs avec
## des ouvertures [côté ("n" = -Z, "s" = +Z, "e" = +X, "w" = -X), centre, largeur, hauteur].
func _room(parent: Node3D, x0: float, x1: float, z0: float, z1: float, y0: float, h: float, wall: String, floor_m: String, openings: Array = [], ceiling: String = "plafond") -> void:
	var t: float = 0.6
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	_box(parent, Vector3(x1 - x0 + 2 * t, 0.5, z1 - z0 + 2 * t), Vector3(cx, y0 - 0.25, cz), _mat(floor_m))
	_box(parent, Vector3(x1 - x0 + 2 * t, 0.6, z1 - z0 + 2 * t), Vector3(cx, y0 + h + 0.3, cz), _mat(ceiling))
	for side in ["n", "s", "e", "w"]:
		var along_x: bool = side in ["n", "s"]
		var a0: float = x0 - t if along_x else z0
		var a1: float = x1 + t if along_x else z1
		var fixed: float = (z0 - t * 0.5) if side == "n" else ((z1 + t * 0.5) if side == "s" else ((x1 + t * 0.5) if side == "e" else (x0 - t * 0.5)))
		var gaps: Array = []
		for o in openings:
			if str(o[0]) == side:
				gaps.append([float(o[1]) - float(o[2]) * 0.5, float(o[1]) + float(o[2]) * 0.5, float(o[3])])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		var cur: float = a0
		for g in gaps:
			if g[0] > cur:
				_wall_piece(parent, along_x, fixed, cur, g[0], y0, h, t, wall)
			# Linteau au-dessus de l'ouverture
			if float(g[2]) < h:
				_wall_piece(parent, along_x, fixed, g[0], g[1], y0 + float(g[2]), h - float(g[2]), t, wall)
			cur = g[1]
		if cur < a1:
			_wall_piece(parent, along_x, fixed, cur, a1, y0, h, t, wall)


func _wall_piece(parent: Node3D, along_x: bool, fixed: float, a: float, b: float, y0: float, h: float, t: float, wall: String) -> void:
	var mid: float = (a + b) * 0.5
	if along_x:
		_box(parent, Vector3(b - a, h, t), Vector3(mid, y0 + h * 0.5, fixed), _mat(wall))
	else:
		_box(parent, Vector3(t, h, b - a), Vector3(fixed, y0 + h * 0.5, mid), _mat(wall))


func _section(name_s: String, at: Vector3, forward: Vector3) -> Node3D:
	var s := Node3D.new()
	s.name = "Temple_" + name_s
	add_child(s)
	s.global_position = Vector3(at.x, Y, at.z)
	# Repère local : -Z regarde vers l'autre île.
	s.rotation.y = atan2(-forward.x, -forward.z)
	sections[name_s] = s
	return s


func _torch(parent: Node3D, pos: Vector3, facing: Vector3, energy: float = 1.6) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = pos
	root.rotation.y = atan2(facing.x, facing.z)
	# V53 : support de fer scellé au mur, manche de bois, tête de tissu goudronné et une
	# flamme toujours visible (les particules seules disparaissaient de loin).
	var D = preload("res://scripts/decor_v53.gd")
	var fe: Material = D.forged_iron()
	D.box(root, Vector3(0.16, 0.26, 0.03), Vector3(0, -0.02, 0.0), fe)
	D.box(root, Vector3(0.04, 0.04, 0.2), Vector3(0, -0.06, 0.1), fe)
	D.cyl(root, 0.055, 0.055, 0.04, Vector3(0, -0.04, 0.2), fe, 10)
	var handle: MeshInstance3D = D.cyl(root, 0.045, 0.03, 0.5, Vector3(0, 0.06, 0.2), _mat("bois"), 8)
	handle.rotation.x = 0.3
	var tar := StandardMaterial3D.new()
	tar.albedo_color = Color(0.12, 0.08, 0.05)
	tar.roughness = 0.9
	var head: MeshInstance3D = D.cyl(root, 0.06, 0.05, 0.14, Vector3(0, 0.3, 0.27), tar, 8)
	head.rotation.x = 0.3
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.055
	cs.height = 0.2
	core.mesh = cs
	core.material_override = D.flame_core()
	core.position = Vector3(0, 0.43, 0.3)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	_fire(root, Vector3(0, 0.42, 0.3), 0.08, 18)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.3)
	light.light_energy = energy
	light.omni_range = 9.0
	light.omni_attenuation = 1.4
	light.position = Vector3(0, 0.45, 0.35)
	root.add_child(light)


## Flammes en particules (additives) et étincelles.
func _fire(parent: Node3D, pos: Vector3, radius: float, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.0
	p.gravity = Vector3(0, 1.2, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.3) * (radius / 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.disable_receive_shadows = true
	m.albedo_color = Color(1.0, 0.55, 0.18, 0.8)
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	p.position = pos
	parent.add_child(p)
	return p


func _boulders(parent: Node3D, center: Vector3, half: Vector2, n: int, seed_v: int, mat: Material, size_min: float = 1.2, size_max: float = 2.6) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in range(n):
		var side: int = i % 4
		var p: Vector3 = center
		match side:
			0: p += Vector3(rng.randf_range(-half.x, half.x), 0, -half.y)
			1: p += Vector3(rng.randf_range(-half.x, half.x), 0, half.y)
			2: p += Vector3(-half.x, 0, rng.randf_range(-half.y, half.y))
			3: p += Vector3(half.x, 0, rng.randf_range(-half.y, half.y))
		var sz: float = rng.randf_range(size_min, size_max)
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.shape(seed_v * 10 + i, Vector3(sz, sz * rng.randf_range(0.8, 1.6), sz), 0.7, 0.2)
		mi.material_override = mat
		mi.position = p + Vector3.UP * sz * 0.3
		mi.rotation.y = rng.randf() * TAU
		parent.add_child(mi)


func _stalactites(parent: Node3D, center: Vector3, half: Vector2, top: float, n: int, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in range(n):
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		var l: float = rng.randf_range(0.5, 1.6)
		c.top_radius = rng.randf_range(0.12, 0.3)
		c.bottom_radius = 0.0
		c.height = l
		c.radial_segments = 7
		mi.mesh = c
		mi.material_override = _mat("grotte")
		mi.position = center + Vector3(rng.randf_range(-half.x, half.x), top - l * 0.5, rng.randf_range(-half.y, half.y))
		parent.add_child(mi)


## Grotte d'arrivée (commune aux deux trappes) : l'échelle descend du puits, au fond.
func _arrival(s: Node3D, id: String) -> void:
	_room(s, -5, 5, -4, 6, 0, 6, "grotte", "grotte", [["n", 0, 3.0, 3.6]], "grotte")
	var rock: Material = Rocks.material(Color(0.6, 0.58, 0.55), 0.12, 0.3)
	_boulders(s, Vector3(0, 0, 1), Vector2(4.6, 4.6), 14, 3500 + (0 if id == "village" else 50), rock)
	_stalactites(s, Vector3(0, 0, 1), Vector2(4.2, 4.2), 6.0, 16, 3600 + (0 if id == "village" else 50))
	# Puits et échelle
	_box(s, Vector3(2.0, 6.0, 0.4), Vector3(0, 9.0, 6.2), _mat("grotte"), false)
	_box(s, Vector3(0.4, 6.0, 2.0), Vector3(-1.2, 9.0, 5.2), _mat("grotte"), false)
	_box(s, Vector3(0.4, 6.0, 2.0), Vector3(1.2, 9.0, 5.2), _mat("grotte"), false)
	for sx in [-0.28, 0.28]:
		_box(s, Vector3(0.07, 10.0, 0.07), Vector3(sx, 5.0, 5.85), _mat("bois"), false)
	var y: float = 0.3
	while y < 10.0:
		var rung := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.022
		c.bottom_radius = 0.022
		c.height = 0.56
		c.radial_segments = 6
		rung.mesh = c
		rung.material_override = _mat("bois")
		rung.position = Vector3(0, y, 5.85)
		rung.rotation.z = PI * 0.5
		s.add_child(rung)
		y += 0.3
	# Lumière du jour qui tombe du puits, un brasero au pied de l'échelle
	var shaft := SpotLight3D.new()
	shaft.light_color = Color(0.7, 0.8, 1.0)
	shaft.light_energy = 2.0
	shaft.spot_range = 14.0
	shaft.spot_angle = 28.0
	shaft.position = Vector3(0, 11.0, 5.0)
	shaft.rotation.x = -PI * 0.5
	s.add_child(shaft)
	_torch(s, Vector3(-4.9, 2.4, 1.5), Vector3(1, 0, 0), 1.6)
	_torch(s, Vector3(4.9, 2.4, -1.5), Vector3(-1, 0, 0), 1.6)
	spawn[id] = [s.to_global(Vector3(0, 0.05, 4.4)), s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO)]
	_interactions.append({"id": "remonter_" + id, "pos": s.to_global(Vector3(0, 0, 5.0)), "radius": 1.6,
		"text": "E : remonter à la surface", "vr": "Gâchette : remonter à la surface", "call": _climb_out.bind(id)})


# =================================================================== côté village (premier niveau)

func _build_village_section(at: Vector3, forward: Vector3) -> void:
	var s: Node3D = _section("village", at, forward)
	_arrival(s, "village")
	# Couloir de la fresque, avec la niche derrière le mur fissuré (côté ouest)
	_room(s, -1.6, 1.6, -22, -4, 0, 4, "mur", "sol", [["s", 0, 3.0, 3.6], ["n", 0, 3.0, 3.6], ["w", -18, 2.0, 2.8]])
	for z in [-7.0, -13.0, -19.0]:
		_torch(s, Vector3(-1.55 if int(z) % 2 == 0 else 1.55, 2.5, z), Vector3(1 if int(z) % 2 == 0 else -1, 0, 0), 1.3)
	var fresco := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(5.0, 1.56)
	fresco.mesh = q
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = load(TEX + "fresque.png")
	fm.roughness = 0.85
	fresco.material_override = fm
	fresco.position = Vector3(1.58, 2.0, -12.0)
	fresco.rotation.y = -PI * 0.5
	s.add_child(fresco)
	var riddle := Label3D.new()
	riddle.text = "« Quand la nuit soulève la mer, le jour se lève,\net le gardien s'éveille. »"
	riddle.font_size = 40
	riddle.pixel_size = 0.0026
	riddle.modulate = Color(0.86, 0.78, 0.6)
	riddle.outline_size = 0
	riddle.position = Vector3(1.57, 0.95, -12.0)
	riddle.rotation.y = -PI * 0.5
	s.add_child(riddle)
	_interactions.append({"id": "fresque", "pos": s.to_global(Vector3(1.0, 0, -12.0)), "radius": 2.0,
		"text": "E : lire la fresque", "vr": "Gâchette : lire la fresque", "call": _read_fresco})
	# Mur fissuré (on le brise à la hache, à l'épée ou à la pelle) et niche
	_wall_node = Node3D.new()
	_wall_node.name = "Mur_fissure"
	s.add_child(_wall_node)
	_wall_node.position = Vector3(-1.9, 0, -18)
	var cracked: MeshInstance3D = _box(_wall_node, Vector3(0.5, 2.8, 2.0), Vector3(0, 1.4, 0), _mat("mur"), false)
	cracked.name = "Pierre"
	# V53 : de vraies fissures, brisées et ramifiées (et non des barres noires droites).
	var crack_m := StandardMaterial3D.new()
	crack_m.albedo_color = Color(0.11, 0.09, 0.08)
	crack_m.roughness = 1.0
	var crng := RandomNumberGenerator.new()
	crng.seed = 3518
	for k in range(4):
		var p := Vector2(-0.6 + k * 0.38, 2.3 - (k % 2) * 0.4)        # (z, y) sur la face du mur
		var ang: float = PI * 0.5 + crng.randf_range(-0.4, 0.4)
		var width: float = 0.03
		for seg in range(9):
			var ln: float = crng.randf_range(0.1, 0.2)
			ang += crng.randf_range(-0.7, 0.7)
			ang = clampf(ang, PI * 0.15, PI * 0.85)
			var d := Vector2(cos(ang), -sin(ang)) * ln
			var mid: Vector2 = p + d * 0.5
			var line := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.015, ln + 0.01, width)
			line.mesh = lb
			line.material_override = crack_m
			line.position = Vector3(0.255, mid.y, mid.x)
			line.rotation.x = atan2(d.x, -d.y) * -1.0
			_wall_node.add_child(line)
			p += d
			width = maxf(0.008, width * 0.85)
			if seg == 3 and k % 2 == 0:
				# une ramification
				var bd := Vector2(cos(ang + 0.9), -sin(ang + 0.9)) * 0.18
				var br := MeshInstance3D.new()
				var bb := BoxMesh.new()
				bb.size = Vector3(0.015, 0.18, width * 0.7)
				br.mesh = bb
				br.material_override = crack_m
				br.position = Vector3(0.255, p.y + bd.y * 0.5, p.x + bd.x * 0.5)
				br.rotation.x = atan2(bd.x, -bd.y) * -1.0
				_wall_node.add_child(br)
	var wall_body := StaticBody3D.new()
	wall_body.name = "Mur_fissure_collision"
	wall_body.collision_layer = 1
	var wcs := CollisionShape3D.new()
	var wbs := BoxShape3D.new()
	wbs.size = Vector3(0.5, 2.8, 2.0)
	wcs.shape = wbs
	wcs.position = Vector3(0, 1.4, 0)
	wall_body.add_child(wcs)
	_wall_node.add_child(wall_body)
	_wall_target = Node3D.new()
	_wall_target.set_script(preload("res://scripts/arbre_v34.gd"))
	_wall_node.add_child(_wall_target)
	_wall_target.position = Vector3(0.1, 0, 0)
	_wall_target.manager = self
	_wall_target.index = 0
	_wall_target.hit_radius = 0.6
	_wall_target.hit_height = 1.0
	_wall_target.add_to_group("cibles_v28")
	_room(s, -4.6, -2.2, -19.6, -16.4, 0, 3, "mur", "sol", [["e", -18, 2.0, 2.8]])
	var urn := MeshInstance3D.new()
	var um := SphereMesh.new()
	um.radius = 0.3
	um.height = 0.7
	urn.mesh = um
	var terra := StandardMaterial3D.new()
	terra.albedo_color = Color(0.55, 0.32, 0.2)
	terra.roughness = 0.8
	urn.material_override = terra
	urn.position = Vector3(-3.8, 0.35, -18.0)
	urn.name = "Urne"
	s.add_child(urn)
	_interactions.append({"id": "niche", "pos": s.to_global(Vector3(-3.4, 0, -18.0)), "radius": 1.5,
		"text": "E : fouiller l'urne", "vr": "Gâchette : fouiller l'urne", "call": _search_urn, "when": func(): return bool(state["mur"]) and not bool(state["niche"])})
	# Salle des braseros
	_room(s, -8, 8, -40, -22, 0, 7, "mur", "sol", [["s", 0, 3.0, 3.6], ["n", 0, 3.4, 4.2]])
	for p in [Vector3(-4.5, 0, -27), Vector3(4.5, 0, -27), Vector3(-4.5, 0, -35), Vector3(4.5, 0, -35)]:
		_box(s, Vector3(1.1, 7.0, 1.1), p + Vector3.UP * 3.5, _mat("mur"))
		_box(s, Vector3(1.5, 0.4, 1.5), p + Vector3.UP * 0.2, _mat("sol"), false)
		_box(s, Vector3(1.5, 0.4, 1.5), p + Vector3.UP * 6.8, _mat("sol"), false)
	# Bassin d'eau le long du mur est, bordé d'une margelle (l'eau suinte du plafond)
	_box(s, Vector3(0.35, 0.32, 16.0), Vector3(6.0, 0.16, -31.0), _mat("sol"))
	for z in [-23.2, -38.8]:
		_box(s, Vector3(2.0, 0.32, 0.35), Vector3(7.0, 0.16, z), _mat("sol"))
	var water := MeshInstance3D.new()
	var wq := PlaneMesh.new()
	wq.size = Vector2(1.8, 15.3)
	water.mesh = wq
	water.material_override = _mat("eau")
	water.position = Vector3(7.05, 0.22, -31.0)
	s.add_child(water)
	# Les quatre braseros (symboles mélangés) et les torches
	var layout := [["soleil", Vector3(-5.6, 0, -24.6)], ["vague", Vector3(4.0, 0, -24.6)], ["serpent", Vector3(-5.6, 0, -37.4)], ["lune", Vector3(4.0, 0, -37.4)]]
	for e in layout:
		_brazier(s, str(e[0]), e[1])
	for z in [-24.0, -38.0]:
		_torch(s, Vector3(-7.95, 3.2, z), Vector3(1, 0, 0), 1.4)
	_torch(s, Vector3(-2.2, 3.2, -39.95), Vector3(0, 0, 1), 1.2)
	_torch(s, Vector3(2.2, 3.2, -39.95), Vector3(0, 0, 1), 1.2)
	# La porte de pierre qui s'abaisse quand l'énigme est résolue
	_door = Node3D.new()
	_door.name = "Porte_braseros"
	s.add_child(_door)
	_door.position = Vector3(0, 0, -40.3)
	var slab := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(3.4, 4.2, 0.5)
	slab.mesh = sb
	slab.material_override = _mat("mur")
	slab.position = Vector3(0, 2.1, 0)
	_door.add_child(slab)
	var door_glyph := MeshInstance3D.new()
	var dq := QuadMesh.new()
	dq.size = Vector2(1.2, 1.2)
	door_glyph.mesh = dq
	door_glyph.material_override = _glyph_mat("serpent")
	door_glyph.position = Vector3(0, 2.4, 0.26)
	_door.add_child(door_glyph)
	var db := StaticBody3D.new()
	db.name = "Porte_collision"
	var dcs := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(3.4, 4.2, 0.5)
	dcs.shape = dbs
	dcs.position = Vector3(0, 2.1, 0)
	db.add_child(dcs)
	_door.add_child(db)
	_interactions.append({"id": "porte_braseros", "pos": s.to_global(Vector3(0, 0, -39.0)), "radius": 1.8,
		"text": "E : examiner la porte", "vr": "Gâchette : examiner la porte", "call": _examine_door, "when": func(): return not bool(state["braseros"])})
	# Escalier qui descend vers la salle du gardien (rampe de pierre)
	var drop: float = 3.0
	var run: float = 12.0
	var ang: float = atan2(drop, run)
	var ramp_len: float = sqrt(run * run + drop * drop)
	_box(s, Vector3(3.6, 0.4, ramp_len), Vector3(0, -drop * 0.5 - 0.2, -40.6 - run * 0.5), _mat("sol"), true, Vector3(-ang, 0, 0))
	for sx in [-1.0, 1.0]:
		_box(s, Vector3(0.6, 8.0, run), Vector3(sx * 2.1, 0.5, -40.6 - run * 0.5), _mat("mur"))
	_box(s, Vector3(4.8, 0.6, ramp_len), Vector3(0, 4.3 - drop * 0.5, -40.6 - run * 0.5), _mat("plafond"), false, Vector3(-ang, 0, 0))
	_torch(s, Vector3(-1.75, 1.8, -46.6), Vector3(1, 0, 0), 1.1)
	# Salle du gardien : coffre sur l'estrade, statues, Porte du Serpent
	var y0: float = -drop
	_room(s, -9, 9, -73, -52.6, y0, 9, "mur", "sol", [["s", 0, 3.6, 4.0], ["n", 0, 5.0, 6.0], ["e", -62.5, 3.0, 3.6]])
	# V36 : dalle qui ferme le passage est, jusqu'à ce qu'on ouvre le coffre
	_passage = Node3D.new()
	_passage.name = "Passage_est"
	s.add_child(_passage)
	_passage.position = Vector3(9.3, y0, -62.5)
	_box(_passage, Vector3(0.6, 3.6, 3.0), Vector3(0, 1.8, 0), _mat("mur"), false)
	var pglyph := MeshInstance3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(0.9, 0.9)
	pglyph.mesh = pq
	pglyph.material_override = _glyph_mat("vague")
	pglyph.position = Vector3(-0.31, 2.0, 0)
	pglyph.rotation.y = -PI * 0.5
	_passage.add_child(pglyph)
	var pb := StaticBody3D.new()
	pb.name = "Passage_collision"
	var pcs := CollisionShape3D.new()
	var pbs := BoxShape3D.new()
	pbs.size = Vector3(0.6, 3.6, 3.0)
	pcs.shape = pbs
	pcs.position = Vector3(0, 1.8, 0)
	pb.add_child(pcs)
	_passage.add_child(pb)
	_box(s, Vector3(3.4, 0.4, 3.4), Vector3(0, y0 + 0.2, -62.5), _mat("sol"))
	_box(s, Vector3(2.4, 0.4, 2.4), Vector3(0, y0 + 0.6, -62.5), _mat("sol"))
	_chest(s, Vector3(0, y0 + 0.8, -62.5))
	# Un rai de lumière tombe d'une fissure du plafond sur le coffre.
	var ray := SpotLight3D.new()
	ray.light_color = Color(0.65, 0.78, 1.0)
	ray.light_energy = 3.0
	ray.spot_range = 12.0
	ray.spot_angle = 14.0
	ray.position = Vector3(0, y0 + 8.8, -62.5)
	ray.rotation.x = -PI * 0.5
	s.add_child(ray)
	for p in [Vector3(-6.5, y0, -56.5), Vector3(6.5, y0, -56.5), Vector3(-6.5, y0, -69), Vector3(6.5, y0, -69)]:
		_statue(s, p, Vector3(0, 0, -62.5) - Vector3(p.x, 0, p.z))
	for p in [Vector3(-3.6, y0, -71.5), Vector3(3.6, y0, -71.5)]:
		_brazier_fixed(s, p)
	_torch(s, Vector3(-8.95, y0 + 3.5, -60), Vector3(1, 0, 0), 1.3)
	_torch(s, Vector3(8.95, y0 + 3.5, -60), Vector3(-1, 0, 0), 1.3)
	serpents.build_door(s, Vector3(0, y0, -73.3))
	serpents.build_sanctuary(s)
	abysses.build(s)
	antre.build(s)


func _brazier(s: Node3D, symbol: String, p: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Brasero_" + symbol
	s.add_child(root)
	root.position = p
	_box(root, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0), _mat("mur"))
	var bowl := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.6
	c.bottom_radius = 0.3
	c.height = 0.35
	bowl.mesh = c
	bowl.material_override = _mat("bronze")
	bowl.position = Vector3(0, 1.07, 0)
	root.add_child(bowl)
	var coals := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.5
	cc.bottom_radius = 0.5
	cc.height = 0.05
	coals.mesh = cc
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.1, 0.08, 0.07)
	coals.material_override = cm
	coals.position = Vector3(0, 1.22, 0)
	root.add_child(coals)
	# Plaque gravée sur les quatre faces du socle
	for k in range(4):
		var plate := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.62, 0.62)
		plate.mesh = q
		plate.material_override = _glyph_mat(symbol)
		var a: float = k * PI * 0.5
		plate.position = Vector3(sin(a) * 0.46, 0.48, cos(a) * 0.46)
		plate.rotation.y = a
		root.add_child(plate)
	var fire: CPUParticles3D = _fire(root, Vector3(0, 1.35, 0), 0.32, 34)
	fire.emitting = false
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = 0.0
	light.omni_range = 10.0
	light.position = Vector3(0, 1.9, 0)
	root.add_child(light)
	var b := {"symbol": symbol, "node": root, "fire": fire, "light": light, "lit": false}
	_braziers.append(b)
	_interactions.append({"id": "brasero_" + symbol, "pos": s.to_global(p), "radius": 1.6,
		"text": "E : allumer le brasero", "vr": "Gâchette : allumer le brasero", "call": _light.bind(_braziers.size() - 1),
		"when": func(): return not bool(state["braseros"]) and not bool(b["lit"])})


func _brazier_fixed(s: Node3D, p: Vector3) -> void:
	var root := Node3D.new()
	s.add_child(root)
	root.position = p
	_box(root, Vector3(0.8, 1.1, 0.8), Vector3(0, 0.55, 0), _mat("mur"))
	var bowl := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.55
	c.bottom_radius = 0.28
	c.height = 0.3
	bowl.mesh = c
	bowl.material_override = _mat("bronze")
	bowl.position = Vector3(0, 1.25, 0)
	root.add_child(bowl)
	_fire(root, Vector3(0, 1.5, 0), 0.3, 30)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = 2.2
	light.omni_range = 11.0
	light.position = Vector3(0, 2.1, 0)
	root.add_child(light)


## Gardien de pierre : socle, corps massif, tête coiffée, lance.
func _statue(s: Node3D, p: Vector3, look: Vector3) -> void:
	var root := Node3D.new()
	s.add_child(root)
	root.position = p
	root.rotation.y = atan2(look.x, look.z)
	var stone: Material = Rocks.material(Color(0.62, 0.6, 0.55), 0.25, 0.4)
	_box(root, Vector3(1.4, 0.6, 1.4), Vector3(0, 0.3, 0), _mat("sol"))
	var body := MeshInstance3D.new()
	body.mesh = Rocks.shape(9100 + int(p.x * 7.0 + p.z), Vector3(1.0, 2.6, 0.75), 0.45, 0.06)
	body.material_override = stone
	body.position = Vector3(0, 1.9, 0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	head.mesh = Rocks.shape(9200 + int(p.z), Vector3(0.6, 0.7, 0.6), 0.5, 0.05)
	head.material_override = stone
	head.position = Vector3(0, 3.55, 0.05)
	root.add_child(head)
	_box(root, Vector3(0.9, 0.2, 0.8), Vector3(0, 3.95, 0), _mat("mur"), false)
	for sx in [-0.14, 0.14]:
		_box(root, Vector3(0.1, 0.06, 0.04), Vector3(sx, 3.6, 0.36), _mat("noir"), false)
	_box(root, Vector3(0.08, 4.2, 0.08), Vector3(0.62, 2.1, 0.25), _mat("bois"), false)
	var tip := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 0.0
	tc.bottom_radius = 0.09
	tc.height = 0.4
	tip.mesh = tc
	tip.material_override = _mat("bronze")
	tip.position = Vector3(0.62, 4.4, 0.25)
	root.add_child(tip)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.4, 4.2, 1.4)
	cs.shape = bs
	_body.add_child(cs)
	cs.global_position = root.global_position + Vector3.UP * 2.1


func _chest(s: Node3D, p: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Coffre_gardien"
	s.add_child(root)
	root.position = p
	var wood: Material = _mat("bois")
	_box(root, Vector3(1.0, 0.55, 0.65), Vector3(0, 0.275, 0), wood)
	for x in [-0.36, 0.36]:
		_box(root, Vector3(0.06, 0.57, 0.67), Vector3(x, 0.275, 0), _mat("bronze"), false)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.55, -0.32)
	root.add_child(hinge)
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.0, 0.18, 0.65)
	lid.mesh = lm
	lid.material_override = wood
	lid.position = Vector3(0, 0.09, 0.32)
	hinge.add_child(lid)
	_interactions.append({"id": "coffre", "pos": s.to_global(p), "radius": 3.0,
		"text": "E : ouvrir le coffre", "vr": "Gâchette : ouvrir le coffre", "call": _open_chest, "when": func(): return not bool(state["coffre"])})


# =================================================================== côté jungle

func _build_jungle_section(at: Vector3, forward: Vector3) -> void:
	var s: Node3D = _section("jungle", at, forward)
	_arrival(s, "jungle")
	_room(s, -1.6, 1.6, -20, -4, 0, 4, "mur", "sol", [["s", 0, 3.0, 3.6], ["n", 0, 3.0, 3.6], ["e", -12.0, 2.6, 3.2]])
	_torch(s, Vector3(1.55, 2.5, -7), Vector3(-1, 0, 0), 1.3)
	serpents.build_jungle(s)
	var rock: Material = Rocks.material(Color(0.58, 0.56, 0.52), 0.1, 0.3)
	_rubble = Node3D.new()
	_rubble.name = "Eboulement"
	s.add_child(_rubble)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3577
	for i in range(9):
		var mi := MeshInstance3D.new()
		var sz: float = rng.randf_range(0.8, 1.8)
		mi.mesh = Rocks.shape(3570 + i, Vector3(sz * 1.2, sz, sz), 0.7, 0.2)
		mi.material_override = rock
		mi.position = Vector3(rng.randf_range(-1.3, 1.3), sz * 0.35 + (i / 3) * 0.7, -19.4 + rng.randf_range(-0.6, 0.6))
		mi.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
		_rubble.add_child(mi)
	_box(s, Vector3(3.2, 4.0, 1.4), Vector3(0, 2.0, -19.4), _mat("grotte"), true).visible = false
	_rubble_body = _body.get_child(_body.get_child_count() - 1)
	_interactions.append({"id": "eboulement", "pos": s.to_global(Vector3(0, 0, -17.4)), "radius": 1.9,
		"text": "E : dégager l'éboulement", "vr": "Gâchette : dégager l'éboulement", "call": _clear_rubble, "when": func(): return not bool(state["eboulement"])})


# =================================================================== V36 : galerie sous la mer

## La galerie relie la salle du gardien (village) à l'éboulement (jungle), en contournant la
## Porte du Serpent par l'est. Repère : section « village » ; d = distance entre les trappes.
## Passage est -> galerie des racines -> grotte des crabes -> galerie inondée (algues
## lumineuses) -> salle aux colonnes (deux gardiens, grille) -> montée -> galerie de retour.
func _build_tunnel(s: Node3D, d: float) -> void:
	var y: float = -3.0
	var rock: Material = Rocks.material(Color(0.5, 0.5, 0.48), 0.15, 0.3)
	_room(s, 9.6, 12.0, -64.0, -61.0, y, 3.6, "mur", "sol", [["w", -62.5, 3.0, 3.4], ["e", -62.5, 3.0, 3.4]])
	# Galerie des racines (grotte)
	_room(s, 12.0, 19.0, -96.0, -58.0, y, 5.0, "grotte", "grotte", [["w", -62.5, 3.0, 3.4], ["n", 15.5, 4.0, 4.5]], "grotte")
	_boulders(s, Vector3(15.5, y, -77), Vector2(3.2, 18.5), 16, 3601, rock, 0.9, 1.9)
	_stalactites(s, Vector3(15.5, y, -77), Vector2(3.0, 17.0), y + 5.0, 18, 3602)
	_glow(s, Vector3(12.3, y + 1.6, -72), Vector3(1, 0, 0))
	_glow(s, Vector3(18.7, y + 2.2, -86), Vector3(-1, 0, 0))
	_torch(s, Vector3(12.05, y + 2.4, -61.0), Vector3(1, 0, 0), 1.2)
	# Grotte des crabes
	_room(s, 8.0, 24.0, -122.0, -96.0, y, 8.0, "grotte", "grotte", [["s", 15.5, 4.0, 4.5], ["n", 15.5, 4.0, 4.5]], "grotte")
	_boulders(s, Vector3(16, y, -109), Vector2(7.6, 12.5), 22, 3611, rock, 1.2, 2.8)
	_stalactites(s, Vector3(16, y, -109), Vector2(7.0, 12.0), y + 8.0, 26, 3612)
	for k in range(5):
		var pool := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 1.0 + k * 0.25
		pm.bottom_radius = pm.top_radius
		pm.height = 0.02
		pool.mesh = pm
		pool.material_override = _mat("eau")
		pool.position = Vector3(10.5 + k * 3.0, y + 0.02, -100.0 - k * 4.4 + (k % 2) * 3.0)
		s.add_child(pool)
	_glow(s, Vector3(8.3, y + 2.0, -104), Vector3(1, 0, 0))
	_glow(s, Vector3(23.7, y + 3.0, -114), Vector3(-1, 0, 0))
	_glow(s, Vector3(23.7, y + 1.8, -101), Vector3(-1, 0, 0))
	_glow(s, Vector3(8.3, y + 2.6, -117), Vector3(1, 0, 0))
	_torch(s, Vector3(8.05, y + 2.8, -110.0), Vector3(1, 0, 0), 1.4)
	_torch(s, Vector3(23.95, y + 2.8, -108.0), Vector3(-1, 0, 0), 1.4)
	_torch(s, Vector3(13.0, y + 2.6, -121.95), Vector3(0, 0, 1), 1.4)
	_torch(s, Vector3(18.0, y + 2.6, -121.95), Vector3(0, 0, 1), 1.4)
	# Galerie inondée : de l'eau de part et d'autre d'une chaussée de dalles
	_room(s, 12.5, 18.5, -168.0, -122.0, y, 5.0, "grotte", "grotte", [["s", 15.5, 4.0, 4.5], ["n", 15.5, 4.0, 4.5]], "grotte")
	for sx in [13.4, 17.6]:
		var water := MeshInstance3D.new()
		var wq := PlaneMesh.new()
		wq.size = Vector2(1.8, 46.0)
		water.mesh = wq
		water.material_override = _mat("eau")
		water.position = Vector3(sx, y + 0.06, -145.0)
		s.add_child(water)
	_box(s, Vector3(2.4, 0.12, 46.0), Vector3(15.5, y + 0.06, -145.0), _mat("sol"), false)
	for z in [-130.0, -142.0, -154.0, -164.0]:
		_glow(s, Vector3(12.8 if int(z) % 4 == 0 else 18.2, y + 1.2 + fmod(absf(z), 3.0) * 0.4, z), Vector3(1 if int(z) % 4 == 0 else -1, 0, 0))
	_drips(s, Vector3(15.5, y + 4.9, -138.0))
	_drips(s, Vector3(14.5, y + 4.9, -158.0))
	# Salle aux colonnes : deux gardiens de corail, la grille au nord
	_room(s, 7.0, 24.0, -194.0, -168.0, y, 9.0, "mur", "sol", [["s", 15.5, 4.0, 4.5], ["n", 15.5, 4.0, 4.5], ["e", -181.0, 3.4, 4.2]])
	_build_boss_arena(s, y)
	for p in [Vector3(10.5, y, -174), Vector3(20.5, y, -174), Vector3(10.5, y, -188), Vector3(20.5, y, -188)]:
		_box(s, Vector3(1.2, 9.0, 1.2), p + Vector3.UP * 4.5, _mat("mur"))
		_box(s, Vector3(1.6, 0.4, 1.6), p + Vector3.UP * 0.2, _mat("sol"), false)
	for p in [Vector3(7.05, y + 3.2, -178.0), Vector3(7.05, y + 3.2, -186.0)]:
		_torch(s, p, Vector3(1, 0, 0), 1.4)
	for p in [Vector3(23.95, y + 3.2, -178.0), Vector3(23.95, y + 3.2, -186.0)]:
		_torch(s, p, Vector3(-1, 0, 0), 1.4)
	for p in [Vector3(12.5, y, -170.5), Vector3(18.5, y, -170.5)]:
		_statue(s, p, Vector3(0, 0, -1))
	_grille = _portcullis(s, Vector3(15.5, y, -194.3), 4.0, 4.5, 0.0)
	_interactions.append({"id": "grille", "pos": s.to_global(Vector3(15.5, y, -192.8)), "radius": 2.2,
		"text": "E : examiner la grille", "vr": "Gâchette : examiner la grille", "call": func(): _say("Une lourde grille de bronze. Pas de serrure… Les deux gardiens de corail semblent la garder.", 4.0),
		"when": func(): return not bool(state["grille"])})
	# Montée vers la jungle (rampe), puis galerie de retour vers l'axe des trappes
	var run: float = 14.0
	var ang: float = atan2(3.0, run)
	var rl: float = sqrt(run * run + 9.0)
	_box(s, Vector3(6.0, 0.4, rl), Vector3(15.5, y + 1.5 - 0.2, -194.6 - run * 0.5), _mat("grotte"), true, Vector3(ang, 0, 0))
	for sx in [12.2, 18.8]:
		_box(s, Vector3(0.6, 9.0, run), Vector3(sx, y + 3.0, -194.6 - run * 0.5), _mat("grotte"))
	_box(s, Vector3(7.2, 0.6, rl), Vector3(15.5, y + 6.3, -194.6 - run * 0.5), _mat("grotte"), false, Vector3(ang, 0, 0))
	_glow(s, Vector3(12.6, y + 2.8, -201.0), Vector3(1, 0, 0))
	var zc: float = -(d - 27.5)
	var z_end: float = zc - 1.5
	_room(s, 12.5, 18.5, z_end, -208.6, 0.0, 4.5, "grotte", "grotte", [["s", 15.5, 6.0, 4.4], ["w", zc, 3.0, 3.6]], "grotte")
	_boulders(s, Vector3(15.5, 0.0, (z_end - 208.6) * 0.5), Vector2(2.8, absf(z_end + 208.6) * 0.5), 10, 3621, rock, 0.8, 1.6)
	_glow(s, Vector3(18.2, 2.0, -218.0), Vector3(-1, 0, 0))
	_glow(s, Vector3(12.8, 1.6, -232.0), Vector3(1, 0, 0))
	_room(s, 1.6, 12.5, zc - 1.5, zc + 1.5, 0.0, 3.8, "mur", "sol", [["e", zc, 3.0, 3.6], ["w", zc, 3.0, 3.6]])
	_torch(s, Vector3(7.0, 2.5, zc - 1.45), Vector3(0, 0, 1), 1.3)
	_room(s, -1.6, 1.6, -(d - 20.6), zc + 1.5, 0.0, 4.0, "mur", "sol", [["n", 0.0, 3.0, 3.6], ["e", zc, 3.0, 3.6]])
	_torch(s, Vector3(-1.55, 2.5, zc), Vector3(1, 0, 0), 1.2)
	_interactions.append({"id": "eboulement_sud", "pos": s.to_global(Vector3(0, 0, -(d - 22.4))), "radius": 1.9,
		"text": "E : dégager l'éboulement", "vr": "Gâchette : dégager l'éboulement", "call": _clear_rubble, "when": func(): return not bool(state["eboulement"])})


## Herse de bronze (barreaux, traverses, collision) ; « yaw » pour la tourner.
func _portcullis(s: Node3D, pos: Vector3, width: float, height: float, yaw: float) -> Node3D:
	var g := Node3D.new()
	g.name = "Herse"
	s.add_child(g)
	g.position = pos
	g.rotation.y = yaw
	var n: int = int(width / 0.46) + 1
	for k in range(n):
		var bar := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.045
		bc.bottom_radius = 0.045
		bc.height = height
		bc.radial_segments = 6
		bar.mesh = bc
		bar.material_override = _mat("bronze")
		bar.position = Vector3(-width * 0.5 + 0.15 + k * (width - 0.3) / float(n - 1), height * 0.5, 0)
		g.add_child(bar)
	for h in [0.6, height * 0.5, height - 0.6]:
		_box(g, Vector3(width, 0.08, 0.1), Vector3(0, h, 0), _mat("bronze"), false)
	var gb := StaticBody3D.new()
	gb.name = "Grille_collision"
	var gcs := CollisionShape3D.new()
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(width, height, 0.3)
	gcs.shape = gbs
	gcs.position = Vector3(0, height * 0.5, 0)
	gb.add_child(gcs)
	g.add_child(gb)
	return g


# =================================================================== V37 : l'antre du Crabe-Roi

## À l'est de la salle aux colonnes : un couloir (fermé par une herse tant que les gardiens
## veillent), puis une grande grotte ronde avec un puits d'eau noire au centre.
func _build_boss_arena(s: Node3D, y: float) -> void:
	_grille_est = _portcullis(s, Vector3(24.3, y, -181.0), 3.4, 4.2, PI * 0.5)
	_room(s, 24.6, 32.0, -182.7, -179.3, y, 4.2, "mur", "sol", [["w", -181.0, 3.4, 4.2], ["e", -181.0, 3.4, 4.2]])
	_torch(s, Vector3(28.0, y + 2.6, -182.65), Vector3(0, 0, 1), 1.2)
	_room(s, 32.0, 58.0, -194.0, -168.0, y, 12.0, "grotte", "grotte", [["w", -181.0, 3.4, 4.2]], "grotte")
	_herse = _portcullis(s, Vector3(31.7, y, -181.0), 3.4, 4.2, PI * 0.5)
	arena_center = s.to_global(Vector3(45.0, y, -181.0))
	var rock: Material = Rocks.material(Color(0.48, 0.46, 0.44), 0.12, 0.3)
	# Coins arrondis par de gros blocs, stalactites, ossements et vieilles armures
	var rng := RandomNumberGenerator.new()
	rng.seed = 3707
	for k in range(28):
		var a: float = TAU * k / 28.0
		var r: float = rng.randf_range(13.2, 15.5)
		var p := Vector3(45.0 + cos(a) * r, y, -181.0 + sin(a) * r)
		if absf(p.z + 181.0) < 3.0 and p.x < 40.0:
			continue
		var sz: float = rng.randf_range(2.0, 4.0)
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.shape(3710 + k, Vector3(sz, sz * rng.randf_range(1.0, 2.2), sz), 0.7, 0.22)
		mi.material_override = rock
		mi.position = p + Vector3.UP * sz * 0.4
		mi.rotation.y = rng.randf() * TAU
		s.add_child(mi)
	_stalactites(s, Vector3(45.0, y, -181.0), Vector2(11.0, 11.0), y + 12.0, 30, 3720)
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.85, 0.82, 0.72)
	bone.roughness = 0.8
	for k in range(10):
		var b := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.04
		bm.bottom_radius = 0.05
		bm.height = rng.randf_range(0.4, 0.9)
		b.mesh = bm
		b.material_override = bone
		var a2: float = rng.randf() * TAU
		b.position = Vector3(45.0 + cos(a2) * rng.randf_range(6.0, 10.5), y + 0.05, -181.0 + sin(a2) * rng.randf_range(6.0, 10.5))
		b.rotation = Vector3(PI * 0.5, rng.randf() * TAU, 0)
		s.add_child(b)
	for k in range(3):
		var helm := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 0.2
		hm.height = 0.2
		hm.is_hemisphere = true
		helm.mesh = hm
		helm.material_override = _mat("bronze")
		helm.position = Vector3(38.0 + k * 6.5, y + 0.02, -172.0 - (k % 2) * 17.0)
		helm.rotation.z = 0.3 * k
		s.add_child(helm)
	# Le puits d'eau noire d'où sort le Crabe-Roi
	var well := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 3.4
	wm.bottom_radius = 3.4
	wm.height = 0.02
	wm.radial_segments = 32
	well.mesh = wm
	var dark_water := StandardMaterial3D.new()
	dark_water.albedo_color = Color(0.02, 0.06, 0.07, 0.92)
	dark_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark_water.roughness = 0.02
	dark_water.metallic = 0.3
	well.material_override = dark_water
	well.position = Vector3(45.0, y + 0.03, -181.0)
	s.add_child(well)
	for k in range(16):
		var a3: float = TAU * k / 16.0
		_box(s, Vector3(1.4, 0.25, 0.5), Vector3(45.0 + cos(a3) * 3.7, y + 0.12, -181.0 + sin(a3) * 3.7), _mat("sol"), false, Vector3(0, -a3, 0))
	# Lumières : quatre grands braseros, des algues, un rai de lumière bleue sur le puits
	for p2 in [Vector3(36.0, y, -172.0), Vector3(54.0, y, -172.0), Vector3(36.0, y, -190.0), Vector3(54.0, y, -190.0)]:
		_brazier_fixed(s, p2)
	for g in [[Vector3(32.3, y + 3.0, -174.0), Vector3(1, 0, 0)], [Vector3(57.7, y + 2.5, -178.0), Vector3(-1, 0, 0)], [Vector3(57.7, y + 3.4, -188.0), Vector3(-1, 0, 0)], [Vector3(32.3, y + 2.2, -189.0), Vector3(1, 0, 0)]]:
		_glow(s, g[0], g[1])
	var ray := SpotLight3D.new()
	ray.light_color = Color(0.55, 0.75, 1.0)
	ray.light_energy = 4.0
	ray.spot_range = 16.0
	ray.spot_angle = 22.0
	ray.position = Vector3(45.0, y + 11.8, -181.0)
	ray.rotation.x = -PI * 0.5
	s.add_child(ray)
	# Le coffre de la victoire (caché tant que le Crabe-Roi vit)
	_boss_chest = Node3D.new()
	_boss_chest.name = "Coffre_Karkinos"
	s.add_child(_boss_chest)
	_boss_chest.position = Vector3(45.0, y, -186.0)
	_box(_boss_chest, Vector3(1.1, 0.6, 0.7), Vector3(0, 0.3, 0), _mat("bois"), false)
	for x in [-0.4, 0.4]:
		_box(_boss_chest, Vector3(0.06, 0.62, 0.72), Vector3(x, 0.3, 0), _mat("bronze"), false)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.6, -0.35)
	_boss_chest.add_child(hinge)
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.1, 0.2, 0.7)
	lid.mesh = lm
	lid.material_override = _mat("bois")
	lid.position = Vector3(0, 0.1, 0.35)
	hinge.add_child(lid)
	_interactions.append({"id": "coffre_boss1", "pos": s.to_global(Vector3(45.0, y, -186.0)), "radius": 2.0,
		"text": "E : ouvrir le coffre du Crabe-Roi", "vr": "Gâchette : ouvrir le coffre", "call": _open_boss_chest,
		"when": func(): return bool(state["boss1"]) and not bool(state["coffre_boss1"]) and not fight})
	_build_boss_bar()


func _build_boss_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.layer = 12
	_bar_layer.visible = false
	add_child(_bar_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_bar_layer.add_child(root)
	_bar_label = Label.new()
	_bar_label.text = "Karkinos, le Crabe-Roi"
	_bar_label.position = Vector2(-300, 22)
	_bar_label.size = Vector2(600, 30)
	_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar_label.add_theme_font_size_override("font_size", 22)
	_bar_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.6))
	_bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_bar_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_bar_label)
	var back := ColorRect.new()
	back.color = Color(0.05, 0.02, 0.02, 0.8)
	back.position = Vector2(-300, 56)
	back.size = Vector2(600, 18)
	root.add_child(back)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.85, 0.18, 0.1)
	_bar_fill.position = Vector2(2, 2)
	_bar_fill.size = Vector2(596, 14)
	back.add_child(_bar_fill)


func _update_bar(hp: int, hp_max: int) -> void:
	var r: float = float(hp) / float(hp_max)
	if _bar_fill != null:
		_bar_fill.size.x = 596.0 * r
		_bar_fill.color = Color(0.85, 0.18, 0.1) if r > 0.5 else Color(1.0, 0.45, 0.05)
	if _bar_vr != null:
		var n: int = int(round(r * 20.0))
		_bar_vr.text = _bar_name + "\n" + "█".repeat(n) + "░".repeat(20 - n)


func _in_arena(p: Vector3) -> bool:
	if arena_center == Vector3.INF:
		return false
	return Vector2(p.x - arena_center.x, p.z - arena_center.z).length() < 11.0 and absf(p.y - arena_center.y) < 4.0


## Le combat commence quand on s'avance dans l'antre : la herse retombe derrière soi.
func _boss_tick() -> void:
	if arena_center == Vector3.INF or not inside:
		return
	var p: Vector3 = main._player_pos_v27()
	if not fight and not bool(state["boss1"]) and _in_arena(p) and Vector2(p.x - arena_center.x, p.z - arena_center.z).length() < 9.0:
		_start_fight()
	elif fight and boss != null and boss.state != "mort" and (Vector2(p.x - arena_center.x, p.z - arena_center.z).length() > 14.5 or absf(p.y - arena_center.y) > 4.0):
		_reset_fight()


func _start_fight() -> void:
	fight = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("boss_cri")
	var s: Node3D = sections["village"]
	var face: Vector3 = s.to_global(Vector3(-1, 0, 0)) - s.to_global(Vector3.ZERO)
	boss = BossScript.new()
	add_child(boss)
	boss.setup(self, arena_center, face)
	boss.health_changed.connect(_update_bar)
	boss.defeated.connect(_on_boss_defeated)
	var hb: StaticBody3D = _herse.get_node("Grille_collision")
	hb.collision_layer = 1
	create_tween().tween_property(_herse, "position:y", -3.0, 0.5).set_trans(Tween.TRANS_QUAD)
	_bar_name = "Karkinos, le Crabe-Roi"
	_bar_label.text = _bar_name
	_bar_layer.visible = not main.xr_active
	if main.xr_active:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.004
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(1.0, 0.6, 0.45)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, 3.6, 0)
		boss.add_child(_bar_vr)
	_update_bar(boss.hp, boss.HP_MAX)
	_say("La herse retombe derrière toi… L'eau du puits bouillonne. KARKINOS, LE CRABE-ROI, surgit des profondeurs !", 5.0)


## On a quitté l'antre (évanoui, ou sorti) : tout reprend à zéro.
func _reset_fight() -> void:
	fight = false
	if boss != null:
		boss.queue_free()
		boss = null
	_bar_vr = null
	_bar_layer.visible = false
	for m in _summoned:
		if is_instance_valid(m):
			m.queue_free()
	_summoned.clear()
	_apply_state()


func summon_crabs(n: int) -> void:
	var alive: int = 0
	for m in _summoned:
		if is_instance_valid(m) and m.state != "mort":
			alive += 1
	for k in range(mini(n, 3 - alive)):
		var a: float = randf() * TAU
		var at: Vector3 = arena_center + Vector3(cos(a) * 2.4, 0.1, sin(a) * 2.4)
		var m: Node3D = main.monstres_v36.spawn_extra("crabe", at)
		_summoned.append(m)
		if main.combat_v28 != null:
			main.combat_v28.puff(at + Vector3.UP * 0.2, Color(0.5, 0.7, 0.75))
	if n > 0:
		_say("Des crabes sortent du puits !", 2.0)


func _on_boss_defeated() -> void:
	main.jingle("victoire")
	state["boss1"] = true
	state["victoires"] = int(state["victoires"]) + 1
	_say("Karkinos s'effondre dans un fracas de carapace ! La herse se relève… et un coffre remonte du puits.", 6.0)
	await get_tree().create_timer(2.5).timeout
	fight = false
	_bar_layer.visible = false
	for m in _summoned:
		if is_instance_valid(m) and m.state != "mort":
			m.take_hit(99, m.global_position + Vector3.UP)
	_summoned.clear()
	var hb: StaticBody3D = _herse.get_node("Grille_collision")
	var tw := create_tween()
	tw.tween_property(_herse, "position:y", -3.0 + 4.4, 2.5)
	tw.tween_callback(func(): hb.collision_layer = 0)
	_boss_chest.visible = true
	var target_y: float = _boss_chest.position.y
	_boss_chest.position.y = target_y - 1.0
	create_tween().tween_property(_boss_chest, "position:y", target_y, 2.0).set_trans(Tween.TRANS_BACK)


func _open_boss_chest() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 60], ["rubis", 1], ["fragment_amulette", 1]]):
		_say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	state["coffre_boss1"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("coffre")
		main.jingle("decouverte")
	var hinge: Node3D = _boss_chest.get_node("Charniere")
	create_tween().tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 60)
	var r: int = main.inventory_v28.add("rubis", 1)
	var f: int = main.inventory_v28.add("fragment_amulette", 1)
	_say("Le trésor du Crabe-Roi : %d pièces, %s… et le DEUXIÈME fragment de l'amulette, gravé d'une vague !%s" % [a, "un rubis" if r > 0 else "", "" if f > 0 else " (ton sac est plein !)"], 7.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(_boss_chest.global_position + Vector3.UP * 0.8, Color(1.0, 0.85, 0.4))


## Algues lumineuses : une tache bleu-vert sur la paroi et sa lueur.
func _glow(s: Node3D, pos: Vector3, normal: Vector3) -> void:
	if not _mats.has("algue"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.25, 0.9, 0.8)
		m.emission_enabled = true
		m.emission = Color(0.2, 0.95, 0.85)
		m.emission_energy_multiplier = 2.5
		m.roughness = 0.6
		_mats["algue"] = m
	var root := Node3D.new()
	s.add_child(root)
	root.position = pos
	root.rotation.y = atan2(normal.x, normal.z)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(pos.z) * 13.0 + pos.x)
	for k in range(9):
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.06, 0.16)
		sm.height = sm.radius * 1.2
		sm.radial_segments = 8
		sm.rings = 4
		blob.mesh = sm
		blob.material_override = _mats["algue"]
		blob.position = Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.5, 0.6), 0.02)
		root.add_child(blob)
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.95, 0.85)
	light.light_energy = 1.6
	light.omni_range = 8.5
	light.position = Vector3(0, 0, 0.5)
	root.add_child(light)


## Gouttes qui tombent du plafond.
func _drips(s: Node3D, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 6
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.5, 0.05, 3.0)
	p.direction = Vector3.DOWN
	p.spread = 0.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 0.8
	p.gravity = Vector3(0, -9.8, 0)
	var q := SphereMesh.new()
	q.radius = 0.012
	q.height = 0.03
	q.material = _mat("eau")
	p.mesh = q
	p.position = pos
	s.add_child(p)


# =================================================================== repères en surface et trappes

func _stone_circle(c: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Cercle_de_pierres_levees"
	add_child(root)
	root.global_position = c
	var mat: Material = Rocks.material(Color(0.66, 0.64, 0.6), 0.55, 0.3)
	for i in range(7):
		var a: float = TAU * i / 7.0 + 0.2
		var p := Vector3(cos(a) * 3.6, 0, sin(a) * 3.6)
		var gy: float = main._height_at(c.x + p.x, c.z + p.z) - c.y
		var h: float = 1.8 + (i % 3) * 0.5
		var mi := MeshInstance3D.new()
		mi.mesh = Rocks.shape(4700 + i, Vector3(0.8, h, 0.55), 0.55, 0.1)
		mi.material_override = mat
		mi.position = p + Vector3(0, gy + h * 0.42, 0)
		mi.rotation = Vector3(0.05 * (i % 2), -a, 0.04)
		root.add_child(mi)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.35
		cyl.height = h
		cs.shape = cyl
		_body.add_child(cs)
		cs.global_position = root.global_position + mi.position
	# Au centre, une dalle à peine visible sous le sable : le sol y sonne creux.
	var hint := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.9
	hm.bottom_radius = 0.9
	hm.height = 0.04
	hm.radial_segments = 8
	hint.mesh = hm
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.62, 0.56, 0.42)
	sand.roughness = 1.0
	hint.material_override = sand
	hint.position.y = 0.01
	root.add_child(hint)


func _stone_head(c: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Tete_de_pierre"
	add_child(root)
	root.global_position = c + Vector3(3.0, -0.25, 1.0)
	root.scale = Vector3.ONE * 1.6
	# Elle regarde la trappe, comme si elle la gardait.
	root.rotation.y = atan2(-3.0, -1.0)
	var mat: Material = Rocks.material(Color(0.6, 0.6, 0.55), 0.85, 0.3)
	var head := MeshInstance3D.new()
	head.mesh = Rocks.shape(5100, Vector3(2.0, 2.2, 1.8), 0.6, 0.07)
	head.material_override = mat
	head.position = Vector3(0, 0.55, 0)
	head.rotation = Vector3(0.12, 0.0, 0.08)
	root.add_child(head)
	# Le visage : arcades, yeux creux, nez large, bouche
	var face := Node3D.new()
	face.position = Vector3(0, 0.75, 0)
	face.rotation = head.rotation
	root.add_child(face)
	for sx in [-0.38, 0.38]:
		_box(face, Vector3(0.36, 0.12, 0.2), Vector3(sx, 0.38, 0.86), mat, false)
		_box(face, Vector3(0.24, 0.12, 0.08), Vector3(sx, 0.22, 0.88), _mat("noir"), false)
	_box(face, Vector3(0.34, 0.42, 0.28), Vector3(0, 0.0, 0.92), mat, false)
	_box(face, Vector3(0.6, 0.1, 0.12), Vector3(0, -0.4, 0.86), _mat("noir"), false)
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.6
	cs.shape = sph
	_body.add_child(cs)
	cs.global_position = root.global_position + Vector3.UP * 0.9
	# Deux tambours de colonne renversés
	for k in range(2):
		var col := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.45
		cm.bottom_radius = 0.45
		cm.height = 0.9
		col.mesh = cm
		col.material_override = mat
		col.position = Vector3(-4.2 + k * 0.8, 0.3, -1.6 - k * 1.1)
		col.rotation = Vector3(PI * 0.5, 0.4 + k, 0)
		root.add_child(col)


## Trappe enterrée : invisible tant qu'on n'a pas creusé dessus.
func _make_trap(id: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Trappe_" + id
	add_child(root)
	root.global_position = at
	var pit := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 1.0
	pm.bottom_radius = 0.9
	pm.height = 0.05
	pm.radial_segments = 16
	pit.mesh = pm
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color(0.32, 0.24, 0.16)
	dirt.roughness = 1.0
	pit.material_override = dirt
	pit.position.y = 0.01
	root.add_child(pit)
	var hole := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(1.0, 0.02, 1.0)
	hole.mesh = hm
	hole.material_override = _mat("noir")
	hole.position.y = 0.03
	root.add_child(hole)
	var slab := Node3D.new()
	slab.name = "Dalle"
	root.add_child(slab)
	_box(slab, Vector3(1.15, 0.1, 1.15), Vector3(0, 0.06, 0), _mat("mur"), false)
	var glyph := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(0.8, 0.8)
	glyph.mesh = gq
	glyph.material_override = _glyph_mat("serpent")
	glyph.rotation.x = -PI * 0.5
	glyph.position.y = 0.115
	slab.add_child(glyph)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.07
	tm.outer_radius = 0.1
	ring.mesh = tm
	ring.material_override = _mat("bronze")
	ring.position = Vector3(0, 0.12, 0.42)
	slab.add_child(ring)
	var ladder := Node3D.new()
	ladder.name = "Echelle"
	root.add_child(ladder)
	for sx in [-0.28, 0.28]:
		_box(ladder, Vector3(0.06, 1.4, 0.06), Vector3(sx, 0.2, -0.4), _mat("bois"), false)
	_traps[id] = {"root": root, "slab": slab, "pit": pit, "hole": hole, "ladder": ladder, "pos": at}
	_interactions.append({"id": "trappe_ouvrir_" + id, "pos": at, "radius": 1.8, "text": "E : soulever la trappe", "vr": "Gâchette : soulever la trappe",
		"call": _open_trap.bind(id), "when": func(): return int(state["trappe_" + id]) == 1})
	_interactions.append({"id": "trappe_descendre_" + id, "pos": at, "radius": 1.8, "text": "E : descendre dans le souterrain", "vr": "Gâchette : descendre",
		"call": _descend.bind(id), "when": func(): return int(state["trappe_" + id]) == 2})


func _apply_state() -> void:
	if serpents != null:
		serpents.apply_state()
	if abysses != null:
		abysses.apply_state()
	if antre != null:
		antre.apply_state()
	if _passage != null:
		_passage.position.y = (-3.0 - 3.8) if bool(state["passage"]) else -3.0
		(_passage.get_node("Passage_collision") as StaticBody3D).collision_layer = 0 if bool(state["passage"]) else 1
	if _grille != null:
		_grille.position.y = (-3.0 + 4.6) if bool(state["grille"]) else -3.0
		(_grille.get_node("Grille_collision") as StaticBody3D).collision_layer = 0 if bool(state["grille"]) else 1
	if _grille_est != null:
		_grille_est.position.y = (-3.0 + 4.4) if bool(state["grille"]) else -3.0
		(_grille_est.get_node("Grille_collision") as StaticBody3D).collision_layer = 0 if bool(state["grille"]) else 1
	if _herse != null and not fight:
		_herse.position.y = -3.0 + 4.4
		(_herse.get_node("Grille_collision") as StaticBody3D).collision_layer = 0
	if _boss_chest != null:
		_boss_chest.visible = bool(state["boss1"])
		(_boss_chest.get_node("Charniere") as Node3D).rotation.x = -1.8 if bool(state["coffre_boss1"]) else 0.0
	if _rubble != null:
		_rubble.visible = not bool(state["eboulement"])
		_rubble_body.disabled = bool(state["eboulement"])
	for id in _traps:
		var t: Dictionary = _traps[id]
		var st: int = int(state["trappe_" + id])
		(t["pit"] as Node3D).visible = st >= 1
		(t["slab"] as Node3D).visible = st >= 1
		(t["hole"] as Node3D).visible = st >= 2
		(t["ladder"] as Node3D).visible = st >= 2
		var slab: Node3D = t["slab"]
		slab.position = Vector3(1.1, 0.0, 0.0) if st >= 2 else Vector3.ZERO
		slab.rotation.z = -0.08 if st >= 2 else 0.0
	for b in _braziers:
		var on: bool = bool(state["braseros"]) or bool(b["lit"])
		(b["fire"] as CPUParticles3D).emitting = on
		(b["light"] as OmniLight3D).light_energy = 2.0 if on else 0.0
	if _door != null:
		_door.position.y = -4.4 if bool(state["braseros"]) else 0.0
		var db: StaticBody3D = _door.get_node("Porte_collision")
		db.collision_layer = 0 if bool(state["braseros"]) else 1
	if _wall_node != null:
		_wall_node.visible = not bool(state["mur"])
		var wb: StaticBody3D = _wall_node.get_node("Mur_fissure_collision")
		wb.collision_layer = 0 if bool(state["mur"]) else 1
	if sections.has("village"):
		var urn: Node3D = (sections["village"] as Node3D).get_node_or_null("Urne")
		if urn != null:
			urn.scale = Vector3(1, 0.55, 1) if bool(state["niche"]) else Vector3.ONE
		var chest: Node3D = (sections["village"] as Node3D).get_node_or_null("Coffre_gardien")
		if chest != null:
			(chest.get_node("Charniere") as Node3D).rotation.x = -1.8 if bool(state["coffre"]) else 0.0


# =================================================================== pelle : trouver les trappes

## Une trappe encore enterrée tout près ? (renvoie "village", "jungle" ou "")
func buried_trap_near(p: Vector3) -> String:
	for id in _traps:
		if int(state["trappe_" + id]) != 0:
			continue
		var q: Vector3 = _traps[id]["pos"]
		if Vector2(q.x - p.x, q.z - p.z).length() < 1.6 and absf(q.y - p.y) < 1.5:
			return id
	return ""


func reveal_trap(id: String) -> void:
	state["trappe_" + id] = 1
	_apply_state()
	var at: Vector3 = _traps[id]["pos"]
	if main.combat_v28 != null:
		main.combat_v28.puff(at + Vector3.UP * 0.2, Color(0.7, 0.6, 0.45))
	_say("Ta pelle heurte de la pierre… Une trappe gravée d'un serpent, avec un anneau de bronze !")


func _open_trap(id: String) -> void:
	var t: Dictionary = _traps[id]
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("pierre_glisse")
	var slab: Node3D = t["slab"]
	var tw := create_tween()
	tw.tween_property(slab, "position", Vector3(1.1, 0.0, 0.0), 1.2).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(slab, "rotation:z", -0.08, 1.2)
	state["trappe_" + id] = 2
	(t["hole"] as Node3D).visible = true
	(t["ladder"] as Node3D).visible = true
	_say("La dalle glisse dans un raclement. Une échelle s'enfonce dans le noir… et un souffle frais remonte.")


# =================================================================== interactions

func _say(text: String, seconds: float = 4.0) -> void:
	main._show_message_v28(text)
	if main.message_clock_v28 < seconds:
		main.message_clock_v28 = seconds
	if main.xr_active and main.combat_v28 != null:
		var head: Vector3 = main.xr_camera.global_position
		var f: Vector3 = -main.xr_camera.global_basis.z
		main.combat_v28.float_text(head + f * 1.2 + Vector3.DOWN * 0.15, text, Color(1, 0.95, 0.8))


func _current(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = INF
	for it in _interactions:
		if it.has("when") and not bool((it["when"] as Callable).call()):
			continue
		var q: Vector3 = it["pos"]
		var d: float = Vector2(q.x - p.x, q.z - p.z).length()
		if d < float(it["radius"]) and absf(q.y - p.y) < 2.5 and d < best_d:
			best_d = d
			best = it
	return best


func prompt(p: Vector3) -> String:
	if _busy:
		return ""
	var it: Dictionary = _current(p)
	return str(it.get("text", ""))


## VR : petite étiquette au-dessus de l'objet ("" pour cacher).
func show_vr_hint(p: Vector3, on: bool) -> void:
	var it: Dictionary = _current(p) if on and not _busy else {}
	_vr_hint.visible = not it.is_empty()
	if not it.is_empty():
		_vr_hint.text = str(it["vr"])
		_vr_hint.global_position = (it["pos"] as Vector3) + Vector3.UP * 1.9


func interact(p: Vector3) -> bool:
	if _busy:
		return true
	var it: Dictionary = _current(p)
	if it.is_empty():
		return false
	(it["call"] as Callable).call()
	return true


func _read_fresco() -> void:
	_say("Quatre symboles gravés, dans l'ordre : I, II, III, IIII. Et dessous : « Quand la nuit soulève la mer, le jour se lève, et le gardien s'éveille. »", 6.0)


func _examine_door() -> void:
	_say("Une porte de pierre sans poignée, marquée d'un serpent. Les quatre braseros de la salle doivent y être pour quelque chose…", 5.0)


## V36 : la grille de la salle aux colonnes se lève quand ses deux gardiens sont tombés.
func open_grille() -> void:
	if bool(state["grille"]):
		return
	state["grille"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("grille")
	_say("Les deux gardiens sont tombés. Dans un cliquetis de chaînes, la grille se lève !", 5.0)
	var gb: StaticBody3D = _grille.get_node("Grille_collision")
	var tw := create_tween()
	tw.tween_property(_grille, "position:y", -3.0 + 4.6, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): gb.collision_layer = 0)


## V36 : à la pelle, on dégage l'éboulement (des deux côtés) : les deux îles sont reliées.
func _clear_rubble() -> void:
	if main.inventory_v28.count("pelle") <= 0:
		_say("Des blocs et des gravats jusqu'au plafond. À mains nues, impossible… Avec une pelle, peut-être.", 5.0)
		return
	_busy = true
	_say("Tu dégages les gravats à la pelle, pierre après pierre…", 3.0)
	if main.combat_v28 != null:
		for k in range(4):
			main.combat_v28.puff(_rubble.global_position + _rubble.global_basis * Vector3(-1.0 + k * 0.7, 0.6 + k * 0.3, -19.0), Color(0.62, 0.58, 0.52))
	await _fade_to(0.85, 0.5)
	await get_tree().create_timer(0.8).timeout
	state["eboulement"] = true
	_apply_state()
	await _fade_to(0.0, 0.5)
	_busy = false
	_say("Le passage est libre ! La galerie sous la mer relie maintenant les deux îles.", 5.0)


func _examine_rubble() -> void:
	_say("Un éboulement bloque la galerie. Au-delà, on entend de l'eau couler… Il faudra trouver un autre chemin. (Suite du chantier !)", 5.0)


func _light(i: int) -> void:
	var b: Dictionary = _braziers[i]
	b["lit"] = true
	(b["fire"] as CPUParticles3D).emitting = true
	var light: OmniLight3D = b["light"]
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 2.0, 0.6)
	_lit.append(str(b["symbol"]))
	var good: bool = true
	for k in range(_lit.size()):
		if _lit[k] != ORDER[k]:
			good = false
	if not good:
		_say("Les flammes vacillent… puis toutes s'éteignent d'un coup. Ce n'était pas le bon ordre.")
		_lit.clear()
		await get_tree().create_timer(1.2).timeout
		for bb in _braziers:
			bb["lit"] = false
			(bb["fire"] as CPUParticles3D).emitting = false
			var tw2 := create_tween()
			tw2.tween_property(bb["light"], "light_energy", 0.0, 0.5)
		return
	if _lit.size() < ORDER.size():
		_say(["La flamme prend. Rien d'autre ne se passe… pour l'instant.", "Une deuxième flamme. On dirait que la salle retient son souffle.", "Trois flammes. Le sol vibre très légèrement."][_lit.size() - 1])
		return
	state["braseros"] = true
	_say("Les quatre flammes rugissent ensemble ! Dans un grondement, la porte de pierre s'enfonce dans le sol.", 5.0)
	var s: Node3D = sections["village"]
	var db: StaticBody3D = _door.get_node("Porte_collision")
	var tw3 := create_tween()
	tw3.tween_property(_door, "position:y", -4.4, 3.5).set_trans(Tween.TRANS_SINE)
	tw3.tween_callback(func(): db.collision_layer = 0)
	if main.combat_v28 != null:
		for k in range(4):
			main.combat_v28.puff(s.to_global(Vector3(-1.2 + k * 0.8, 0.2, -39.6)), Color(0.6, 0.55, 0.48))


func _search_urn() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 15]]):
		_say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	state["niche"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("pierre_glisse")
	_apply_state()
	var got: int = main.inventory_v28.add("piece", 15)
	_say("Dans l'urne : %d pièces, et un parchemin roulé : « Trois gardiens veillent sur l'Œil du Serpent. Qui réunira l'amulette ouvrira la porte. »" % got, 7.0)


func _open_chest() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 30], ["fragment_amulette", 1]]):
		_say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	state["coffre"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("coffre")
		main.jingle("decouverte")
	var chest: Node3D = (sections["village"] as Node3D).get_node("Coffre_gardien")
	var hinge: Node3D = chest.get_node("Charniere")
	var tw := create_tween()
	tw.tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 30)
	var b: int = main.inventory_v28.add("fragment_amulette", 1)
	_say("Le coffre du gardien : %d pièces… et un fragment d'amulette en jade, gravé d'un œil. Le premier des trois ?%s\nUn grondement : à l'est, une dalle s'enfonce dans le sol…" % [a, "" if b > 0 else " (ton sac est plein !)"], 7.0)
	state["passage"] = true
	var pb: StaticBody3D = _passage.get_node("Passage_collision")
	var tw2 := create_tween()
	tw2.tween_interval(1.0)
	tw2.tween_property(_passage, "position:y", _passage.position.y - 3.8, 3.0).set_trans(Tween.TRANS_SINE)
	tw2.tween_callback(func(): pb.collision_layer = 0)
	if main.combat_v28 != null:
		main.combat_v28.puff(chest.global_position + Vector3.UP * 0.8, Color(1.0, 0.85, 0.4))


## Le mur fissuré : arbre_v34.gd lui sert de cible (même règle que les arbres).
func standing(_i: int) -> bool:
	return not bool(state["mur"])


func hit(_i: int, damage: int, _from_pos: Vector3) -> void:
	if bool(state["mur"]):
		return
	var at: Vector3 = _wall_node.global_position + Vector3.UP * 1.3
	if damage < 3:
		if main.combat_v28 != null:
			main.combat_v28.float_text(at + Vector3.UP * 0.6, "Aïe ! Il faut un outil.", Color(1, 0.9, 0.8))
		return
	_wall_hp -= 1
	if main.combat_v28 != null:
		main.combat_v28.puff(at, Color(0.7, 0.66, 0.6))
		main.combat_v28.float_text(at + Vector3.UP * 0.6, "Crac !" if _wall_hp > 0 else "Le mur s'effondre !", Color(1.0, 0.9, 0.7))
	if _wall_hp <= 0:
		state["mur"] = true
		_apply_state()
		for k in range(3):
			main.combat_v28.puff(at + Vector3(0, -0.6 + k * 0.4, 0), Color(0.62, 0.58, 0.52))
		_say("Derrière le mur fissuré, une petite niche… avec une urne.")


# =================================================================== descendre / remonter

func _fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 30
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func _fade_to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	if main.xr_active:
		if _fade_sphere == null:
			_fade_sphere = MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.25
			sm.height = 0.5
			sm.flip_faces = true
			_fade_sphere.mesh = sm
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.no_depth_test = true
			m.render_priority = 100
			m.albedo_color = Color(0, 0, 0, 0)
			_fade_sphere.material_override = m
			main.xr_camera.add_child(_fade_sphere)
		var mat: StandardMaterial3D = _fade_sphere.material_override
		tw.tween_property(mat, "albedo_color:a", alpha, seconds)
	else:
		tw.tween_property(_fade_rect, "color:a", alpha, seconds)
	await tw.finished


func _descend(id: String) -> void:
	if not spawn.has(id):
		return
	_say("Tu descends l'échelle… longtemps.", 2.5)
	await _travel(spawn[id][0], spawn[id][1])
	if not bool(state["visite"]):
		state["visite"] = true
		_say("Le Temple englouti. Des siècles de silence… et quelque part, de l'eau qui goutte.", 5.0)


func _climb_out(id: String) -> void:
	var at: Vector3 = _traps[id]["pos"]
	var out := Vector3(at.x - 1.3, main._height_at(at.x - 1.3, at.z - 0.9) + 0.05, at.z - 0.9)
	await _travel(out, Vector3(1, 0, 0.7).normalized())
	_say("De retour à la lumière.", 2.5)


func _travel(target: Vector3, facing: Vector3) -> void:
	_busy = true
	if main.fishing_v32 != null:
		main.fishing_v32.cancel("")
	await _fade_to(1.0, 0.45)
	main.place_player_v35(target, facing)
	update_inside(true)
	await get_tree().create_timer(0.25).timeout
	await _fade_to(0.0, 0.6)
	_busy = false


# =================================================================== ambiance sous terre

func is_inside(p: Vector3) -> bool:
	return p.y < Y + 30.0


## Sous terre : plus de soleil ni de ciel, une pénombre bleutée ; on rétablit en sortant.
func update_inside(force: bool = false) -> void:
	var now: bool = is_inside(main._player_pos_v27())
	if now == inside and not force:
		return
	inside = now
	var sun: DirectionalLight3D = main.get_node_or_null("Soleil_v24")
	var world: WorldEnvironment = null
	for c in main.get_children():
		if c is WorldEnvironment:
			world = c
			break
	if world == null:
		return
	var env: Environment = world.environment
	if inside:
		if _env_saved.is_empty():
			_env_saved = {"bg": env.background_mode, "amb": env.ambient_light_source, "amb_c": env.ambient_light_color, "amb_e": env.ambient_light_energy,
				"refl": env.reflected_light_source, "fog_c": env.fog_light_color, "fog_d": env.fog_density, "fog_sky": env.fog_sky_affect,
				"vol_d": env.volumetric_fog_density, "vol_a": env.volumetric_fog_albedo, "exp": env.tonemap_exposure, "sun": sun.visible if sun != null else true}
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0, 0, 0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.32, 0.36, 0.42)
		env.ambient_light_energy = 0.4
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		env.fog_light_color = Color(0.02, 0.025, 0.03)
		env.fog_density = 0.035
		env.fog_sky_affect = 0.0
		env.volumetric_fog_density = 0.025
		env.volumetric_fog_albedo = Color(0.6, 0.55, 0.5)
		env.tonemap_exposure = 1.25
		# V70 : les Neuf Cercles sont taillés dans la pierre noire des volcans : une lueur de braise
		# partout (sinon on n'y voit rien), un brouillard plus léger
		var brz: Node = main.get("braise_v70")
		if brz != null and brz.get("dungeon") != null and brz.dungeon != null and brz.dungeon.contains(main._player_pos_v27()):
			env.ambient_light_color = Color(0.62, 0.46, 0.38)
			env.ambient_light_energy = 1.5
			env.fog_light_color = Color(0.06, 0.035, 0.03)
			env.fog_density = 0.012
			env.tonemap_exposure = 1.45
		# V71 : le Donjon des Mille Marches : de la pierre humide, des torches ; une pénombre où l'on voit
		var mjd: Node = main.get("montjoie_v71")
		if mjd != null and mjd.get("dungeon") != null and mjd.dungeon != null and mjd.dungeon.contains(main._player_pos_v27()):
			env.ambient_light_color = Color(0.5, 0.48, 0.42)
			env.ambient_light_energy = 1.1
			env.fog_light_color = Color(0.03, 0.035, 0.03)
			env.fog_density = 0.014
			env.tonemap_exposure = 1.35
		if sun != null:
			sun.visible = false
	elif not _env_saved.is_empty():
		env.background_mode = _env_saved["bg"]
		env.ambient_light_source = _env_saved["amb"]
		env.ambient_light_color = _env_saved["amb_c"]
		env.ambient_light_energy = _env_saved["amb_e"]
		env.reflected_light_source = _env_saved["refl"]
		env.fog_light_color = _env_saved["fog_c"]
		env.fog_density = _env_saved["fog_d"]
		env.fog_sky_affect = _env_saved["fog_sky"]
		env.volumetric_fog_density = _env_saved["vol_d"]
		env.volumetric_fog_albedo = _env_saved["vol_a"]
		env.tonemap_exposure = _env_saved["exp"]
		if sun != null:
			sun.visible = bool(_env_saved["sun"])
		_env_saved = {}


func _process(_delta: float) -> void:
	if main != null and main.game_started:
		update_inside()
		_boss_tick()


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"trappe_village": 0, "trappe_jungle": 0, "braseros": false, "mur": false, "niche": false, "coffre": false, "visite": false, "passage": false, "grille": false, "eboulement": false, "victoires": 0, "boss1": false, "coffre_boss1": false, "serpents": 45, "enigme_serpents": false, "fragment3": false, "porte_serpent": false, "coffre_sanctuaire": false, "sceau": false, "abysses_bas": false, "lac": false, "coffre_abysses": false, "abime_eveil": false, "porte_abime": false, "naga": false, "coffre_naga": false, "grotte_cascade": false}
	for k in state:
		if d.has(k):
			state[k] = int(d[k]) if (k.begins_with("trappe") or k == "victoires" or k == "serpents") else bool(d[k])
	# Sauvegardes de la V35 : le coffre déjà ouvert a révélé le passage.
	if bool(state["coffre"]):
		state["passage"] = true
	_lit.clear()
	for b in _braziers:
		b["lit"] = false
	_wall_hp = 3
	if fight:
		_reset_fight()
	if antre != null:
		antre.on_load()
	_apply_state()

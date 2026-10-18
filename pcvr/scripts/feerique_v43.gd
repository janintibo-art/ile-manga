extends Node3D
## V43 : le Royaume des Racines — étape 1 du donjon féerique, sous l'Arbre-Mère.
##  - Faelar l'Ancien raconte la légende de la porte et confie une lanterne de fée.
##  - Cinq esprits-lucioles dansent dans la forêt du Bois-Doré, au-dessus de cercles de
##    champignons blancs. On les accueille dans la lanterne.
##  - Devant la porte sculptée dans le tronc de l'Arbre-Mère, les esprits regagnent leurs
##    cinq niches : la porte s'ouvre et l'on descend dans les racines.
##  - En bas : le Cœur de l'Arbre (Lumi, une petite fée, sert de guide), le couloir des
##    racines, la Salle des Prismes (tourner les cristaux pour amener le rayon de soleil
##    jusqu'à la Fleur-Porte) et le Jardin des Fées (un coffre, et le mur de ronces de la
##    suite).

const Y: float = -70.0
const Rocks = preload("res://scripts/rocks_v26.gd")
const N_SPIRITS: int = 5
const DOOR_ANGLE: float = 159.0 * PI / 180.0      # entre deux contreforts de l'Arbre-Mère
const BEAM_Y: float = 1.45
# Directions des cristaux : 0 nord (-Z), 1 est (+X), 2 sud (+Z), 3 ouest (-X).
const DIRS := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const CRYSTALS := [[Vector2(4, -26), 3], [Vector2(4, -37), 2], [Vector2(0, -37), 1], [Vector2(-5, -26), 0]]
const SOLUTION := [0, 3, 0]
const HALL := [-10.0, 10.0, -43.0, -21.0]         # x0, x1, z0, z1 de la Salle des Prismes

var main: Node
var el: Node3D
var d: Node
var state := {"esprits": 0, "porte": false, "visite": false, "prismes": false, "coffre": false, "rosee": 0, "baguette": false, "clochettes": false, "village": false, "ronces": false, "reine": false, "carte": false}
var royaume: Node3D                 # V44 : grotte, clochettes, Village des Fées
var G: Vector3
var s: Node3D
var spirit_spots: Array = []
var spawn_pos: Vector3
var door_front: Vector3
var _spirits: Array = []
var _door: Node3D
var _leaves: Array = []
var _niches: Array = []
var _body: StaticBody3D
var _mats: Dictionary = {}
var _root_xf: Array = []           # V45 : courbes des racines [a, ctrl, b, r0, r1, segments]
var gfx                            # V45 : rendu réaliste (feerique_gfx_v45.gd)
var _last_cs: CollisionShape3D
var thorns_node: Node3D            # V46 : le mur de ronces (il se fane avec la poussière de fée)
var thorns_cs: CollisionShape3D
var ronces: Node3D                 # V46 : le Trône des Ronces et sa Reine (ronces_v46.gd)
var _crystals: Array = []
var _beam_root: Node3D
var _beam_mat: StandardMaterial3D
var _bud: Node3D
var _petals: Array = []
var _bud_body: CollisionShape3D
var _chest_lid: Node3D
var _chest_pos: Vector3
var lumi: Node3D
var _lumi_wings: Array = []
var _lumi_bubble: Label3D
var _lumi_clock: float = 0.0
var _lumi_line: int = 0
var _lumi_greeted: bool = false
var in_zone: bool = false
var _clock: float = 0.0


func setup(elfes: Node3D) -> void:
	el = elfes
	gfx = preload("res://scripts/feerique_gfx_v45.gd").new()
	main = el.main
	d = main.donjon_v35
	G = el.ile.glade_world()
	_body = StaticBody3D.new()
	_body.name = "Royaume_collision_v43"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)


func build() -> void:
	_find_spirit_spots()
	for i in range(spirit_spots.size()):
		_spirits.append(_make_spirit(i, spirit_spots[i]))
	_build_door()
	_build_dungeon()
	apply_state()
	print("ILE_MANGA_V43: Royaume des Racines, porte à ", door_front, ", esprits ", spirit_spots)


# =================================================================== matériaux et formes

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	match key:
		"ecorce":
			m.albedo_texture = load("res://assets/textures/flora/bark.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/flora/bark_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.6, 0.6, 0.6)
			m.albedo_color = Color(0.95, 0.82, 0.68)
		"terre":
			m.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/jungle/jungle_rock_n.png")
			m.normal_scale = 1.3
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.18, 0.18, 0.18)
			m.albedo_color = Color(0.82, 0.72, 0.68)
		"mousse":
			m.albedo_texture = load("res://assets/textures/jungle/jungle_moss.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/jungle/jungle_moss_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.25, 0.25, 0.25)
			m.albedo_color = Color(0.7, 0.85, 0.75)
		"pierre":
			m.albedo_texture = load("res://assets/textures/temple/temple_floor.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.3, 0.3, 0.3)
			m.albedo_color = Color(0.85, 0.85, 0.92)
		"or":
			m.albedo_color = Color(0.92, 0.76, 0.4)
			m.metallic = 0.8
			m.roughness = 0.3
		"noir":
			m.albedo_color = Color(0, 0, 0)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"pied":
			m.albedo_color = Color(0.92, 0.9, 0.84)
			m.roughness = 0.7
		"ronce":
			m.albedo_color = Color(0.12, 0.08, 0.1)
			m.roughness = 0.6
	_mats[key] = m
	return m


func _glow(c: Color, energy: float = 2.0, alpha: float = 1.0) -> StandardMaterial3D:
	var key: String = "glow_%s_%.2f_%.2f" % [c.to_html(), energy, alpha]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.2
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _cyl(r_top: float, r_bot: float, h: float, segs: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	return c


func _sphere(r: float, segs: int = 12) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(segs / 2, 4)
	return sm


func _boxm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _light(parent: Node3D, pos: Vector3, c: Color, energy: float, reach: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = reach
	l.omni_attenuation = 1.2
	l.position = pos
	parent.add_child(l)
	return l


func _dot_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	m.albedo_texture = main._soft_dot_v24()
	return m


## Poussière de fée : points lumineux qui flottent (couleurs mêlées).
func _sparkles(parent: Node3D, pos: Vector3, extents: Vector3, amount: int, size: float = 0.1) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 5.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3(0, 0.05, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(0.75, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.7, 0.95, 1.0))
	grad.add_point(0.5, Color(0.6, 1.0, 0.95, 1.0))
	grad.set_color(grad.get_point_count() - 1, Color(1.0, 0.92, 0.6, 1.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _dot_mat(Color(1, 1, 1, 0.9))
	p.mesh = q
	p.position = pos
	parent.add_child(p)
	return p


## Boîte visible et solide, dans le repère de « parent ».
func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
	var mi := _mesh(parent, _boxm(size), mat, pos)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		_body.add_child(cs)
		cs.global_transform = mi.global_transform
		_last_cs = cs
	return mi


## Salle : sol, plafond et quatre murs, avec des ouvertures [côté, centre, largeur, hauteur].
## V45 : les boîtes ne servent plus qu'aux collisions (et de fond) ; ce qu'on voit, ce sont
## des parois de roche irrégulières, un sol moussu bosselé et un plafond hérissé.
func _room(x0: float, x1: float, z0: float, z1: float, h: float, openings: Array) -> void:
	var t: float = 0.6
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	# Lueur douce sous le plafond (mousses lumineuses), pour qu'on voie les racines
	var n_l: int = clampi(int((x1 - x0) * (z1 - z0) / 110.0), 1, 6)
	for k in range(n_l):
		var f: float = (k + 0.5) / n_l
		var lp := Vector3(lerpf(x0 + 1.0, x1 - 1.0, 0.5 + 0.3 * sin(k * 2.3)), h - 0.6 - minf(h * 0.12, 1.4), lerpf(z0, z1, f))
		var l: OmniLight3D = _light(s, lp, Color(0.75, 0.6, 1.0) if k % 2 == 0 else Color(0.55, 0.85, 1.0), 1.2, maxf(h * 1.6, 9.0))
		if k == 0 and el.pc:
			l.shadow_enabled = true
	_box(s, Vector3(x1 - x0 + 2 * t, 0.5, z1 - z0 + 2 * t), Vector3(cx, -0.25, cz), gfx.rock("sol")).visible = false
	_box(s, Vector3(x1 - x0 + 2 * t, 0.6, z1 - z0 + 2 * t), Vector3(cx, h + 0.3, cz), gfx.rock("plafond")).visible = false
	var cell: float = clampf(maxf(x1 - x0, z1 - z0) / 40.0, 0.35, 0.6)
	# Sol : mousse et roche, à peine bosselé (on ne flotte pas au-dessus)
	_mesh(s, gfx.rock_face(Vector3(cx, 0.0, cz), Vector3.RIGHT, Vector3.BACK, x1 - x0 + 0.6, z1 - z0 + 0.6, Vector3.DOWN, 0.1, cell, [false, false, false, false], false, Vector3.UP), gfx.rock("sol"), Vector3.ZERO)
	# Plafond : roche qui pend, en crêtes
	_mesh(s, gfx.rock_face(Vector3(cx, h, cz), Vector3.RIGHT, Vector3.BACK, x1 - x0 + 0.6, z1 - z0 + 0.6, Vector3.DOWN, minf(h * 0.14, 1.6), cell, [false, false, false, false], true), gfx.rock("plafond"), Vector3.ZERO)
	for side in ["n", "s", "e", "w"]:
		var along_x: bool = side in ["n", "s"]
		var a0: float = x0 - t if along_x else z0
		var a1: float = x1 + t if along_x else z1
		var fixed: float = (z0 - t * 0.5) if side == "n" else ((z1 + t * 0.5) if side == "s" else ((x1 + t * 0.5) if side == "e" else (x0 - t * 0.5)))
		var inward: Vector3 = Vector3(0, 0, 1) if side == "n" else (Vector3(0, 0, -1) if side == "s" else (Vector3(-1, 0, 0) if side == "e" else Vector3(1, 0, 0)))
		var gaps: Array = []
		for o in openings:
			if str(o[0]) == side:
				gaps.append([float(o[1]) - float(o[2]) * 0.5, float(o[1]) + float(o[2]) * 0.5, float(o[3])])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		# Des blocs de roche autour des ouvertures : plus de porte « découpée au carré »
		for g2 in gaps:
			for e in [0, 1]:
				var u2: float = float(g2[e])
				var out: float = -1.0 if e == 0 else 1.0
				for k2 in range(3):
					var hy: float = float(g2[2]) * (0.15 + 0.35 * k2)
					var bp: Vector3 = (Vector3(u2 + out * 0.15, hy, fixed) if along_x else Vector3(fixed, hy, u2 + out * 0.15)) + inward * 0.45
					var sz: float = 1.2 + 0.35 * ((k2 + e) % 2)
					_mesh(s, Rocks.shape(4700 + k2 + e * 3, Vector3(sz, sz * 1.2, sz), 0.7, 0.22), gfx.rock("mur"), bp, Vector3(0, k2 * 1.3, 0))
			for k3 in range(3):
				var lu: float = lerpf(float(g2[0]), float(g2[1]), (k3 + 0.5) / 3.0)
				var lpos: Vector3 = (Vector3(lu, float(g2[2]) + 0.2, fixed) if along_x else Vector3(fixed, float(g2[2]) + 0.2, lu)) + inward * 0.4
				_mesh(s, Rocks.shape(4710 + k3, Vector3(1.5, 0.8, 1.1), 0.7, 0.22), gfx.rock("mur"), lpos, Vector3(0, k3 * 2.1, 0))
		var cur: float = a0
		var after_gap: bool = false
		for g in gaps:
			if g[0] > cur:
				_wall(along_x, fixed, cur, g[0], 0.0, h, t, inward, [after_gap, true, false, false])
			if float(g[2]) < h:
				_wall(along_x, fixed, g[0], g[1], float(g[2]), h - float(g[2]), t, inward, [true, true, true, false])
			cur = g[1]
			after_gap = true
		if cur < a1:
			_wall(along_x, fixed, cur, a1, 0.0, h, t, inward, [after_gap, false, false, false])
	# Racines qui tapissent les murs (un seul maillage plus tard)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(x0 * 13.0 + z0 * 7.0)) + 4300
	var pebbles: Array = []
	for side in ["n", "s", "e", "w"]:
		var along: bool = side in ["n", "s"]
		var lo: float = x0 if along else z0
		var hi: float = x1 if along else z1
		var w: float = (z0 + 0.15) if side == "n" else ((z1 - 0.15) if side == "s" else ((x1 - 0.15) if side == "e" else (x0 + 0.15)))
		var inward2: Vector3 = Vector3(0, 0, 1) if side == "n" else (Vector3(0, 0, -1) if side == "s" else (Vector3(-1, 0, 0) if side == "e" else Vector3(1, 0, 0)))
		var u: float = lo + rng.randf_range(0.3, 0.9)
		while u < hi - 0.3:
			var blocked: bool = false
			for o in openings:
				if str(o[0]) == side and absf(u - float(o[1])) < float(o[2]) * 0.5 + 0.35:
					blocked = true
			if not blocked:
				var base: Vector3 = Vector3(u, 0.0, w) if along else Vector3(w, 0.0, u)
				var lean: Vector3 = (Vector3(rng.randf_range(-2.2, 2.2), 0, 0) if along else Vector3(0, 0, rng.randf_range(-2.2, 2.2)))
				var top: Vector3 = base + lean + Vector3.UP * h
				var bulge: Vector3 = inward2 * rng.randf_range(0.6, 1.3) + Vector3.UP * rng.randf_range(-0.8, 0.8)
				_root(base + inward2 * 0.45 - Vector3.UP * 0.1, top + inward2 * 0.3, bulge * 1.6, rng.randf_range(0.16, 0.42), rng.randf_range(0.07, 0.18))
				# Une racine sur deux s'étale aussi au sol
				if rng.randf() < 0.5:
					var spread: Vector3 = base + inward2 * rng.randf_range(1.2, 2.4) + (Vector3(rng.randf_range(-1, 1), 0, 0) if along else Vector3(0, 0, rng.randf_range(-1, 1)))
					_root(base + inward2 * 0.45 + Vector3.UP * 0.4, spread - Vector3.UP * 0.12, Vector3.UP * 0.35, rng.randf_range(0.12, 0.25), 0.04, 6)
			for k in range(2):
				pebbles.append(Vector3(u + rng.randf_range(-0.6, 0.6), 0.0, w) if along else Vector3(w, 0.0, u + rng.randf_range(-0.6, 0.6)))
				pebbles[-1] += inward2 * rng.randf_range(0.4, 1.4)
			u += rng.randf_range(1.3, 2.4)
	# Cailloux le long des parois
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Rocks.shape(4560, Vector3(0.5, 0.32, 0.42), 0.85, 0.2)
	mm.instance_count = pebbles.size()
	for k in range(pebbles.size()):
		var sc: float = rng.randf_range(0.35, 1.3)
		mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * rng.randf_range(0.6, 1.0), sc)), pebbles[k] + Vector3.UP * 0.05))
		mm.set_instance_color(k, Color(1, 1, 1) * rng.randf_range(0.75, 1.05))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = gfx.rock("mur")
	s.add_child(mmi)


func _wall(along_x: bool, fixed: float, a: float, b: float, y0: float, h: float, t: float, inward: Vector3 = Vector3.ZERO, taper: Array = [false, false, false, false]) -> void:
	var mid: float = (a + b) * 0.5
	if along_x:
		_box(s, Vector3(b - a, h, t), Vector3(mid, y0 + h * 0.5, fixed), gfx.rock("mur"))
	else:
		_box(s, Vector3(t, h, b - a), Vector3(fixed, y0 + h * 0.5, mid), gfx.rock("mur"))
	if inward == Vector3.ZERO:
		return
	# La paroi rocheuse, posée sur la face intérieure du mur
	var face_c: Vector3 = (Vector3(mid, y0 + h * 0.5, fixed) if along_x else Vector3(fixed, y0 + h * 0.5, mid)) + inward * (t * 0.5 + 0.01)
	var u_axis: Vector3 = Vector3.RIGHT if along_x else Vector3.BACK
	var cell: float = clampf(h / 22.0, 0.35, 0.6)
	var amp: float = clampf(h * 0.12, 0.6, 1.6)
	_mesh(s, gfx.rock_face(face_c, u_axis, Vector3.UP, b - a, h, inward, amp, cell, taper), gfx.rock("mur"), Vector3.ZERO)


## Une racine courbe (courbe de Bézier) : on mémorise la courbe, et toutes les racines
## deviennent un seul maillage de tubes (V45 : continus, écorce en relief).
func _root(a: Vector3, b: Vector3, bulge: Vector3, r0: float, r1: float, segs: int = 8) -> void:
	_root_xf.append([a, (a + b) * 0.5 + bulge, b, r0, r1, segs])


## Eau sombre et luisante (étangs, bassins) : reflets, et une lueur qui vient du fond.
func _water_mat() -> StandardMaterial3D:
	if _mats.has("eau_fee"):
		return _mats["eau_fee"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.22, 0.26, 0.82)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.03
	m.metallic = 0.4
	m.metallic_specular = 1.0
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/water/water_n.png")
	m.normal_scale = 0.6
	m.uv1_scale = Vector3(1.5, 1.5, 1.5)
	m.emission_enabled = true
	m.emission = Color(0.25, 0.75, 0.8)
	m.emission_energy_multiplier = 0.55
	_mats["eau_fee"] = m
	return m


func _flush_roots() -> void:
	if _root_xf.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "Racines"
	mi.mesh = gfx.roots_mesh(_root_xf)
	mi.material_override = gfx.bark()
	s.add_child(mi)
	_root_xf.clear()


## Champignon géant lumineux (V45 : chapeau bombé à bord recourbé, taches, lamelles
## lumineuses dessous, pied fibreux avec un anneau).
func _mushroom(pos: Vector3, h: float, r: float, c: Color, with_light: bool) -> void:
	var lean := Vector3(sin(pos.x * 3.1) * 0.08, 0, cos(pos.z * 2.7) * 0.08)
	_mesh(s, gfx.stem_mesh(r * 0.24, h), gfx.stem_mat(), pos, lean)
	var cap_p: Vector3 = pos + Vector3.UP * h + Vector3(lean.z, 0, -lean.x) * h * 0.5
	var cap := _mesh(s, gfx.cap_mesh(r, 0.4 + fposmod(pos.x * 0.37, 0.2)), gfx.cap_mat(c, int(absf(pos.x * 7.0 + pos.z * 3.0)) % 2 == 0, 1.0), cap_p, Vector3(lean.x * 0.6, pos.z, lean.z * 0.6))
	cap.rotation.y = pos.z
	if with_light:
		_light(s, cap_p - Vector3.UP * r * 0.4, c, 2.0, 8.0 + r * 3.0)


## Grappe de cristaux qui luit (V45 : prismes hexagonaux à pointe).
func _crystal_cluster(pos: Vector3, c: Color, n: int, seed_v: int, size: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in range(n):
		var h: float = rng.randf_range(0.5, 1.5) * size
		var m := _mesh(s, gfx.crystal_mesh(rng.randf_range(0.07, 0.17) * size, h), gfx.crystal_mat(c), pos + Vector3(rng.randf_range(-0.45, 0.45) * size, -0.05, rng.randf_range(-0.45, 0.45) * size))
		m.rotation = Vector3(rng.randf_range(-0.55, 0.55), rng.randf() * TAU, rng.randf_range(-0.55, 0.55))
	_mesh(s, Rocks.shape(seed_v, Vector3(0.9, 0.35, 0.8) * size, 0.8, 0.2), gfx.rock("mur"), pos + Vector3.UP * 0.05)


# =================================================================== les esprits-lucioles

func _find_spirit_spots() -> void:
	spirit_spots = spots_for(el.ile)


## Les cinq cercles de champignons, tout autour du village (aussi appelé avant la forêt,
## pour que les arbres leur laissent une petite clairière).
static func spots_for(ile: Node3D) -> Array:
	var out: Array = []
	var C: Vector3 = ile.CENTER
	var glade: Vector2 = ile.GLADE
	for k in range(N_SPIRITS):
		var base_a: float = 0.95 + TAU * k / N_SPIRITS
		var found := Vector3.INF
		for r in [70.0, 64.0, 58.0, 52.0, 46.0]:
			for da in [0.0, 0.15, -0.15, 0.3, -0.3]:
				var a: float = base_a + da
				var lp := Vector2(cos(a) * r, sin(a) * r)
				if lp.distance_to(glade) < 42.0 or ile.coast_ratio(lp.x, lp.y) > 0.8:
					continue
				var h: float = ile.height(C.x + lp.x, C.z + lp.y)
				if h < 1.5:
					continue
				found = Vector3(C.x + lp.x, h, C.z + lp.y)
				break
			if found != Vector3.INF:
				break
		if found != Vector3.INF:
			out.append(found)
	return out


func _make_spirit(i: int, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Esprit_luciole_%d" % i
	add_child(root)
	root.global_position = at
	# Cercle de champignons blancs
	for k in range(12):
		var a: float = TAU * k / 12.0
		var q := Vector3(cos(a) * 1.5, 0, sin(a) * 1.5)
		var gy: float = el.ile.height(at.x + q.x, at.z + q.z) - at.y
		var hh: float = 0.1 + 0.05 * (k % 3)
		_mesh(root, _cyl(0.02, 0.028, hh, 6), _mat("pied"), q + Vector3.UP * (gy + hh * 0.5))
		_mesh(root, _sphere(0.07, 8), _glow(Color(0.95, 0.95, 0.88), 0.4), q + Vector3.UP * (gy + hh), Vector3.ZERO, Vector3(1, 0.5, 1))
	var wisp := Node3D.new()
	wisp.name = "Lueur"
	wisp.position = Vector3.UP * 1.3
	root.add_child(wisp)
	var core := StandardMaterial3D.new()
	core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.albedo_color = Color(1.0, 0.97, 0.75)
	_mesh(wisp, _sphere(0.08, 10), core, Vector3.ZERO)
	var halo := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(1.1, 1.1)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(0.8, 1.0, 0.6, 0.7)
	hm.albedo_texture = main._soft_dot_v24()
	q2.material = hm
	halo.mesh = q2
	wisp.add_child(halo)
	_light(wisp, Vector3.ZERO, Color(0.8, 1.0, 0.65), 1.6, 7.0)
	var sp := _sparkles(wisp, Vector3.ZERO, Vector3(0.3, 0.3, 0.3), 14, 0.06)
	sp.lifetime = 1.6
	d._interactions.append({"id": "esprit_%d" % i, "pos": at, "radius": 2.3,
		"text": "E : accueillir l'esprit-luciole", "vr": "Gâchette : accueillir l'esprit",
		"call": _catch.bind(i), "when": func(): return not caught(i) and not bool(state["porte"])})
	return root


func caught(i: int) -> bool:
	return ((int(state["esprits"]) >> i) & 1) == 1


func spirits_count() -> int:
	var n: int = 0
	for i in range(N_SPIRITS):
		if caught(i):
			n += 1
	return n


func _catch(i: int) -> void:
	if main.inventory_v28.count("lanterne_fee") <= 0:
		d._say("La petite lumière recule dès que tu tends la main, puis revient danser au-dessus des champignons. Il lui faudrait un abri… Faelar, l'Ancien du village, saurait peut-être.", 6.0)
		return
	state["esprits"] = int(state["esprits"]) | (1 << i)
	var wisp: Node3D = (_spirits[i] as Node3D).get_node("Lueur")
	var tw := create_tween()
	tw.tween_property(wisp, "global_position", main._player_pos_v27() + Vector3.UP * 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): apply_state())
	var n: int = spirits_count()
	if n < N_SPIRITS:
		d._say("L'esprit-luciole se glisse dans la lanterne de fée en tintant comme une clochette. (%d / %d)" % [n, N_SPIRITS], 4.0)
	else:
		d._say("Le cinquième esprit ! La lanterne brille comme une petite étoile. Ils veulent rentrer chez eux : à la porte de l'Arbre-Mère. (%d / %d)" % [n, N_SPIRITS], 6.0)


# =================================================================== la porte de l'Arbre-Mère

func _build_door() -> void:
	var dir := Vector3(cos(DOOR_ANGLE), 0, sin(DOOR_ANGLE))
	var base: Vector3 = G + dir * 3.08
	_door = Node3D.new()
	_door.name = "Porte_Arbre_Mere"
	add_child(_door)
	_door.global_position = base
	_door.rotation.y = atan2(dir.x, dir.z)               # +Z local vers l'extérieur
	door_front = G + dir * 4.4
	var bark: Material = _mat("ecorce")
	var gold: Material = _mat("or")
	# L'ombre de l'intérieur, derrière les battants
	_mesh(_door, _boxm(Vector3(2.0, 2.4, 0.4)), _mat("noir"), Vector3(0, 1.2, -0.25))
	_mesh(_door, _cyl(1.0, 1.0, 0.4, 20), _mat("noir"), Vector3(0, 2.4, -0.25), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.5))
	# Encadrement : deux montants et un arc de bois doré
	for sx in [-1.08, 1.08]:
		_mesh(_door, _cyl(0.1, 0.13, 2.4, 10), bark, Vector3(sx, 1.2, 0.05))
	for k in range(10):
		var a0: float = PI * k / 10.0
		var a1: float = PI * (k + 1) / 10.0
		var p0 := Vector3(cos(a0) * 1.08, 2.4 + sin(a0) * 1.08, 0.05)
		var p1 := Vector3(cos(a1) * 1.08, 2.4 + sin(a1) * 1.08, 0.05)
		var seg: Vector3 = p1 - p0
		_mesh(_door, _cyl(0.1, 0.1, seg.length() + 0.05, 8), bark, (p0 + p1) * 0.5, Vector3(0, 0, -atan2(seg.x, seg.y)))
		_mesh(_door, _cyl(0.025, 0.025, seg.length() + 0.02, 6), gold, (p0 + p1) * 0.5 + Vector3(0, 0, 0.1), Vector3(0, 0, -atan2(seg.x, seg.y)))
	# Les deux battants, sculptés de veines dorées
	for sx in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(sx * 1.0, 0, 0.0)
		_door.add_child(hinge)
		_mesh(hinge, _boxm(Vector3(0.98, 2.38, 0.1)), bark, Vector3(-sx * 0.49, 1.2, 0))
		for v in range(3):
			_mesh(hinge, _boxm(Vector3(0.03, 1.9, 0.03)), _glow(Color(1.0, 0.85, 0.45), 1.2), Vector3(-sx * (0.2 + v * 0.25), 1.2, 0.06), Vector3(0, 0, sx * (0.15 - v * 0.12)))
		_mesh(hinge, _sphere(0.06, 8), gold, Vector3(-sx * 0.86, 1.15, 0.08))
		_leaves.append(hinge)
	# Le tympan : un arbre de lumière gravé
	for k in range(8):
		var y0: float = 0.98 * k / 8.0
		var y1: float = 0.98 * (k + 1) / 8.0
		var half: float = sqrt(maxf(0.98 * 0.98 - y1 * y1, 0.0)) * 0.5 + sqrt(maxf(0.98 * 0.98 - y0 * y0, 0.0)) * 0.5
		_mesh(_door, _boxm(Vector3(half * 2.0, y1 - y0 + 0.01, 0.1)), bark, Vector3(0, 2.4 + (y0 + y1) * 0.5, 0.0))
	_mesh(_door, _boxm(Vector3(0.05, 0.8, 0.03)), _glow(Color(1.0, 0.85, 0.45), 1.6), Vector3(0, 2.75, 0.07))
	for k in range(5):
		var a2: float = PI * (0.15 + 0.175 * k)
		_mesh(_door, _boxm(Vector3(0.04, 0.45, 0.03)), _glow(Color(1.0, 0.85, 0.45), 1.6), Vector3(cos(a2) * 0.22, 3.1 + sin(a2) * 0.18, 0.07), Vector3(0, 0, a2 - PI * 0.5))
	# Cinq niches pour les esprits, en couronne au-dessus de la porte
	for k in range(N_SPIRITS):
		var a3: float = PI * (0.1 + 0.2 * k)
		var np := Vector3(cos(a3) * 1.55, 2.4 + sin(a3) * 1.55, 0.12)
		_mesh(_door, _cyl(0.11, 0.06, 0.12, 10), gold, np)
		var orb := _mesh(_door, _sphere(0.07, 10), _glow(Color(0.85, 1.0, 0.65), 4.0), np + Vector3.UP * 0.1)
		var l := _light(_door, np + Vector3(0, 0.15, 0.2), Color(0.8, 1.0, 0.65), 0.9, 4.5)
		_niches.append([orb, l])
	_light(_door, Vector3(0, 1.4, -0.2), Color(1.0, 0.85, 0.5), 0.0, 6.0).name = "Lueur_dedans"
	d._interactions.append({"id": "porte_racines", "pos": door_front, "radius": 1.9,
		"text": "E : examiner la porte sculptée", "vr": "Gâchette : examiner la porte", "call": _door_use})


func _door_use() -> void:
	if bool(state["porte"]):
		_enter()
		return
	if main.inventory_v28.count("lanterne_fee") <= 0:
		d._say("Une porte sculptée dans l'écorce de l'Arbre-Mère, sans poignée ni serrure. Au-dessus, cinq petites niches vides. Faelar, l'Ancien, en sait sûrement plus.", 6.0)
		return
	var n: int = spirits_count()
	if n < N_SPIRITS:
		d._say("Cinq niches vides au-dessus de la porte. Ta lanterne de fée abrite %d esprit%s sur %d. Ils dansent dans la forêt, au-dessus des cercles de champignons blancs." % [n, "s" if n > 1 else "", N_SPIRITS], 6.0)
		return
	state["porte"] = true
	d._say("Tu ouvres la lanterne. Un à un, les esprits-lucioles s'envolent et se posent dans les niches… L'écorce frémit, et la porte de l'Arbre-Mère s'ouvre !", 7.0)
	for k in range(N_SPIRITS):
		var orb: MeshInstance3D = _niches[k][0]
		var l: OmniLight3D = _niches[k][1]
		var tw := create_tween()
		tw.tween_interval(0.4 + k * 0.45)
		tw.tween_callback(func(): orb.visible = true)
		tw.tween_property(l, "light_energy", 0.9, 0.4)
	var tw2 := create_tween()
	tw2.tween_interval(2.8)
	tw2.set_parallel(true)
	tw2.tween_property(_leaves[0], "rotation:y", deg_to_rad(-105.0), 2.2).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_leaves[1], "rotation:y", deg_to_rad(105.0), 2.2).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_door.get_node("Lueur_dedans"), "light_energy", 1.4, 2.2)
	if main.combat_v28 != null:
		main.combat_v28.puff(_door.global_position + Vector3.UP * 3.0, Color(0.85, 1.0, 0.65))


func _enter() -> void:
	await d._travel(spawn_pos, Vector3(0, 0, -1))
	if not bool(state["visite"]):
		state["visite"] = true
		d._say("Le Royaume des Racines. L'air sent la terre et le miel ; partout, des racines grosses comme des troncs, et des lumières qui dansent…", 6.0)


func _leave() -> void:
	var dir := Vector3(cos(DOOR_ANGLE), 0, sin(DOOR_ANGLE))
	var out: Vector3 = G + dir * 4.6
	out.y = el.ile.height(out.x, out.z) + 0.05
	await d._travel(out, dir)
	d._say("Tu ressors de l'Arbre-Mère, ébloui par la lumière dorée du Bois-Doré.", 3.0)


# =================================================================== le Royaume des Racines

func _build_dungeon() -> void:
	s = Node3D.new()
	s.name = "Royaume_des_Racines"
	add_child(s)
	s.global_position = Vector3(G.x, Y, G.z)
	_build_heart()
	_build_corridor()
	_build_prisms()
	_build_garden()
	royaume = preload("res://scripts/royaume_v44.gd").new()
	royaume.name = "Royaume_v44"
	add_child(royaume)
	royaume.setup(self)
	royaume.build_rooms()
	ronces = preload("res://scripts/ronces_v46.gd").new()
	ronces.name = "Trone_des_Ronces_v46"
	add_child(ronces)
	ronces.setup(self)
	ronces.build()
	_flush_roots()
	_build_lumi()
	royaume.spawn_fairies()
	d.spawn["racines"] = [spawn_pos, s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO)]


## Le Cœur de l'Arbre : la racine maîtresse descend du plafond, un escalier de racines
## remonte vers la porte.
func _build_heart() -> void:
	_room(-6, 6, -5, 6, 8.0, [["n", 0.0, 3.0, 3.6]])
	# Racine maîtresse : un faisceau de grosses racines torsadées qui descend du plafond
	# et s'étale au sol, avec des mousses lumineuses dans les creux.
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.05
	cyl.height = 8.0
	cs.shape = cyl
	_body.add_child(cs)
	cs.global_position = s.to_global(Vector3(0, 4.0, -0.6))
	var c0 := Vector3(0, 0, -0.6)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var off := Vector3(cos(a), 0, sin(a))
		var off2 := Vector3(cos(a + 1.2), 0, sin(a + 1.2))
		_root(c0 + off2 * 0.9 + Vector3.UP * 8.3, c0 + off * 0.55 + Vector3.UP * 1.2, off * 0.3 + Vector3.UP * 0.5, 0.72, 0.6, 12)
		_root(c0 + off * 0.55 + Vector3.UP * 1.4, c0 + off * 2.9 - Vector3.UP * 0.15, off * 0.4 + Vector3.UP * 0.9, 0.62, 0.14, 8)
	_root(c0 + Vector3.UP * 8.3, c0 + Vector3.UP * 0.2, Vector3(0.2, 0, 0.1), 0.85, 0.75, 10)
	for k in range(14):
		var a3: float = k * 2.4
		var y3: float = 0.8 + fposmod(k * 1.37, 6.0)
		_mesh(s, _sphere(0.09, 8), _glow(Color(0.6, 1.0, 0.75) if k % 2 == 0 else Color(1.0, 0.85, 0.5), 2.0), c0 + Vector3(cos(a3) * 1.15, y3, sin(a3) * 1.15), Vector3.ZERO, Vector3(1.4, 0.6, 1.4))
	# Escalier de racines (décor) qui monte vers la lumière, au sud
	for k in range(9):
		var a2: float = PI * 0.15 + k * 0.17
		var p := Vector3(cos(a2) * 4.6, 0.4 + k * 0.7, 2.0 + sin(a2) * 3.0)
		_mesh(s, Rocks.shape(4600 + k, Vector3(1.4, 0.22, 0.75), 0.7, 0.12), gfx.rock("mur"), p, Vector3(0, -a2, 0))
	var shaft := SpotLight3D.new()
	shaft.light_color = Color(1.0, 0.9, 0.6)
	shaft.light_energy = 2.2
	shaft.spot_range = 12.0
	shaft.spot_angle = 30.0
	shaft.position = Vector3(0, 7.8, 4.6)
	shaft.rotation.x = -PI * 0.5
	s.add_child(shaft)
	_mesh(s, _cyl(0.8, 0.8, 0.1, 16), _glow(Color(1.0, 0.9, 0.6), 2.5), Vector3(0, 7.97, 4.6))
	_mushroom(Vector3(-4.6, 0, -3.4), 1.6, 0.9, Color(0.55, 0.85, 1.0), true)
	_mushroom(Vector3(4.5, 0, -3.6), 1.2, 0.7, Color(0.95, 0.55, 0.9), true)
	_mushroom(Vector3(-5.0, 0, 3.0), 0.8, 0.5, Color(0.7, 1.0, 0.75), false)
	_crystal_cluster(Vector3(5.2, 0, 0.5), Color(0.75, 0.6, 1.0), 6, 4310)
	_sparkles(s, Vector3(0, 3.5, 0.5), Vector3(5, 3, 5), 40)
	spawn_pos = s.to_global(Vector3(0, 0.05, 3.6))
	d._interactions.append({"id": "remonter_racines", "pos": s.to_global(Vector3(0, 0, 4.8)), "radius": 1.5,
		"text": "E : remonter dans l'Arbre-Mère", "vr": "Gâchette : remonter", "call": _leave})


func _build_corridor() -> void:
	_room(-1.8, 1.8, -21, -5, 4.5, [["s", 0.0, 3.0, 3.6], ["n", 0.0, 3.0, 3.6]])
	# Racines en arche au-dessus du couloir
	for k in range(7):
		var z: float = -6.5 - k * 2.2
		_root(Vector3(-1.75, 0.0, z), Vector3(1.75, 0.0, z + 0.4), Vector3(0, 5.2, 0), 0.2, 0.2, 10)
	var cols := [Color(0.55, 0.85, 1.0), Color(0.95, 0.55, 0.9), Color(0.7, 1.0, 0.75)]
	for k in range(6):
		var z2: float = -7.0 - k * 2.4
		var sx: float = -1.3 if k % 2 == 0 else 1.3
		_mushroom(Vector3(sx, 0, z2), 0.35 + 0.1 * (k % 3), 0.25, cols[k % 3], k % 2 == 0)
	_sparkles(s, Vector3(0, 2.0, -13), Vector3(1.4, 1.5, 7.5), 24)


## La Salle des Prismes : un rayon de soleil tombe par une fissure sur un cristal source ;
## des cristaux tournants le renvoient (chacun dans la direction où il pointe).
func _build_prisms() -> void:
	_room(HALL[0], HALL[1], HALL[2], HALL[3], 9.0, [["s", 0.0, 3.0, 3.6], ["n", 0.0, 3.2, 4.2]])
	# La fissure et le cristal source, sur le mur est
	var src := Vector3(9.4, BEAM_Y, -26.0)
	_crystal_cluster(src - Vector3(0.1, BEAM_Y, 0), Color(1.0, 0.9, 0.6), 7, 4320, 1.3)
	_mesh(s, _boxm(Vector3(0.3, 9.0, 0.5)), _glow(Color(1.0, 0.92, 0.65), 2.5, 0.25), Vector3(9.5, 4.6, -26.0))
	var sun := SpotLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.6)
	sun.light_energy = 3.0
	sun.spot_range = 11.0
	sun.spot_angle = 18.0
	sun.position = Vector3(9.2, 8.8, -26.0)
	sun.rotation.x = -PI * 0.5
	s.add_child(sun)
	# Les cristaux tournants sur leurs piédestaux de racines
	for i in range(CRYSTALS.size()):
		var c: Array = CRYSTALS[i]
		var p2: Vector2 = c[0]
		var ped := Node3D.new()
		s.add_child(ped)
		ped.position = Vector3(p2.x, 0, p2.y)
		_mesh(ped, _cyl(0.32, 0.45, 1.0, 12), _mat("pierre"), Vector3(0, 0.5, 0))
		for k in range(4):
			var a: float = TAU * k / 4.0 + 0.4
			_root(Vector3(p2.x + cos(a) * 0.3, 1.0, p2.y + sin(a) * 0.3), Vector3(p2.x + cos(a) * 1.1, 0.0, p2.y + sin(a) * 1.1), Vector3(cos(a) * 0.2, 0.3, sin(a) * 0.2), 0.09, 0.05, 5)
		var spin := Node3D.new()
		spin.position = Vector3(0, BEAM_Y, 0)
		ped.add_child(spin)
		var cm: StandardMaterial3D = _glow(Color(0.75, 0.9, 1.0), 1.0, 0.85).duplicate() as StandardMaterial3D
		_mesh(spin, _cyl(0.0, 0.16, 0.55, 6), cm, Vector3(0, 0, 0.27), Vector3(PI * 0.5, 0, 0))
		_mesh(spin, _cyl(0.16, 0.0, 0.3, 6), cm, Vector3(0, 0, -0.15), Vector3(PI * 0.5, 0, 0))
		var dirn: int = int(c[1])
		spin.rotation.y = _yaw(dirn)
		_crystals.append({"pos": p2, "dir": dirn, "spin": spin, "mat": cm, "node": ped})
		d._interactions.append({"id": "cristal_%d" % i, "pos": s.to_global(Vector3(p2.x, 0, p2.y)), "radius": 1.6,
			"text": "E : tourner le cristal", "vr": "Gâchette : tourner le cristal", "call": rotate_crystal.bind(i),
			"when": func(): return not bool(state["prismes"])})
	# La Fleur-Porte : un bouton géant dans l'ouverture nord
	_bud = Node3D.new()
	_bud.name = "Fleur_Porte"
	s.add_child(_bud)
	_bud.position = Vector3(0, 0, HALL[2] - 0.2)
	_mesh(_bud, _cyl(0.5, 0.7, 0.5, 12), _mat("mousse"), Vector3(0, 0.25, 0))
	for k in range(6):
		var a2: float = TAU * k / 6.0
		var hinge := Node3D.new()
		hinge.position = Vector3(cos(a2) * 0.45, 0.4, sin(a2) * 0.3)
		hinge.rotation.y = -a2 + PI * 0.5
		_bud.add_child(hinge)
		_mesh(hinge, _sphere(0.75, 14), _glow(Color(0.95, 0.6, 0.85), 0.5), Vector3(0, 1.7, 0), Vector3(-0.12, 0, 0), Vector3(0.75, 2.3, 0.35))
		_petals.append(hinge)
	_mesh(_bud, _sphere(0.35, 12), _glow(Color(1.0, 0.92, 0.6), 2.0), Vector3(0, 1.45, 0)).name = "Coeur"
	_bud_body = CollisionShape3D.new()
	var bb := BoxShape3D.new()
	bb.size = Vector3(3.2, 4.2, 0.8)
	_bud_body.shape = bb
	_body.add_child(_bud_body)
	_bud_body.global_position = s.to_global(Vector3(0, 2.1, HALL[2] - 0.2))
	# Décor : champignons, cristaux, poussière de fée
	_mushroom(Vector3(-8.5, 0, -23.0), 2.2, 1.3, Color(0.55, 0.85, 1.0), true)
	_mushroom(Vector3(-8.0, 0, -40.5), 1.8, 1.1, Color(0.95, 0.55, 0.9), true)
	_mushroom(Vector3(8.4, 0, -41.0), 2.6, 1.5, Color(0.7, 1.0, 0.75), true)
	_mushroom(Vector3(-2.5, 0, -22.4), 0.6, 0.4, Color(0.95, 0.55, 0.9), false)
	_mushroom(Vector3(7.0, 0, -32.0), 0.9, 0.55, Color(0.55, 0.85, 1.0), false)
	_crystal_cluster(Vector3(-9.2, 0, -31.0), Color(0.75, 0.6, 1.0), 8, 4330, 1.4)
	_crystal_cluster(Vector3(2.5, 0, -42.3), Color(0.6, 1.0, 0.9), 5, 4331)
	_sparkles(s, Vector3(0, 4.0, -32), Vector3(9, 4, 10), 70)
	_light(s, Vector3(0, 7.5, -32), Color(0.7, 0.55, 0.95), 1.2, 16.0)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.albedo_color = Color(1.0, 0.95, 0.7)
	_beam_root = Node3D.new()
	_beam_root.name = "Rayon"
	s.add_child(_beam_root)


func _yaw(dirn: int) -> float:
	var v: Vector2 = DIRS[dirn]
	return atan2(v.x, v.y)


func rotate_crystal(i: int) -> void:
	var c: Dictionary = _crystals[i]
	c["dir"] = (int(c["dir"]) + 1) % 4
	var spin: Node3D = c["spin"]
	var target: float = _yaw(int(c["dir"]))
	var cur: float = spin.rotation.y
	create_tween().tween_property(spin, "rotation:y", cur + wrapf(target - cur, -PI, PI), 0.35).set_trans(Tween.TRANS_SINE)
	trace_beam()


## Le trajet du rayon (repère du donjon, à plat) : du cristal source vers l'ouest, puis de
## cristal en cristal, jusqu'à un mur. Renvoie vrai si la Fleur-Porte est touchée.
func trace_beam() -> bool:
	for c in _beam_root.get_children():
		c.queue_free()
	var pos := Vector2(9.3, -26.0)
	var dirv: Vector2 = DIRS[3]
	var visited: Dictionary = {}
	var hit_target: bool = false
	for c in _crystals:
		(c["mat"] as StandardMaterial3D).emission_energy_multiplier = 1.0
	for step in range(10):
		var best: int = -1
		var best_t: float = INF
		for i in range(_crystals.size()):
			var v: Vector2 = (_crystals[i]["pos"] as Vector2) - pos
			var t: float = v.dot(dirv)
			if t > 0.2 and absf(v.x * dirv.y - v.y * dirv.x) < 0.3 and t < best_t:
				best_t = t
				best = i
		if best >= 0:
			var cp: Vector2 = _crystals[best]["pos"]
			_beam_segment(pos, cp)
			(_crystals[best]["mat"] as StandardMaterial3D).emission_energy_multiplier = 3.5
			var nd: Vector2 = DIRS[int(_crystals[best]["dir"])]
			if nd.dot(dirv) < -0.5 or visited.has(best):
				break
			visited[best] = true
			pos = cp
			dirv = nd
			continue
		# Jusqu'au mur
		var t_wall: float = INF
		if dirv.x > 0.5:
			t_wall = HALL[1] - pos.x
		elif dirv.x < -0.5:
			t_wall = pos.x - HALL[0]
		elif dirv.y > 0.5:
			t_wall = HALL[3] - pos.y
		else:
			t_wall = pos.y - HALL[2]
		var end: Vector2 = pos + dirv * maxf(t_wall - 0.2, 0.0)
		_beam_segment(pos, end)
		var spot := _mesh(_beam_root, _sphere(0.18, 10), _beam_mat, Vector3(end.x, BEAM_Y, end.y))
		spot.scale = Vector3.ONE
		if dirv.y < -0.5 and absf(end.x) < 0.8:
			hit_target = true
		break
	if hit_target and not bool(state["prismes"]):
		_solve()
	return hit_target


func _beam_segment(a: Vector2, b: Vector2) -> void:
	var a3 := Vector3(a.x, BEAM_Y, a.y)
	var b3 := Vector3(b.x, BEAM_Y, b.y)
	var seg: Vector3 = b3 - a3
	if seg.length() < 0.05:
		return
	var m := _mesh(_beam_root, _cyl(0.035, 0.035, seg.length(), 6), _beam_mat, (a3 + b3) * 0.5)
	m.look_at_from_position((a3 + b3) * 0.5 + s.global_position, b3 + s.global_position, Vector3.UP if absf(seg.normalized().y) < 0.9 else Vector3.RIGHT)
	m.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var g := _mesh(_beam_root, _cyl(0.11, 0.11, seg.length(), 8), _glow(Color(1.0, 0.9, 0.55), 2.0, 0.22), (a3 + b3) * 0.5)
	g.global_transform = m.global_transform


func _solve() -> void:
	state["prismes"] = true
	d._say("Le rayon de soleil frappe la Fleur-Porte ! Ses pétales frémissent… et s'ouvrent lentement, comme au premier matin du monde.", 6.0)
	_open_bud(false)
	if main.combat_v28 != null:
		main.combat_v28.puff(s.to_global(Vector3(0, 2.0, HALL[2])), Color(1.0, 0.7, 0.9))


func _open_bud(instant: bool) -> void:
	for k in range(_petals.size()):
		var hinge: Node3D = _petals[k]
		if instant:
			hinge.rotation.x = -1.35
		else:
			var tw := create_tween()
			tw.tween_interval(0.15 * k)
			tw.tween_property(hinge, "rotation:x", -1.35, 2.5).set_trans(Tween.TRANS_SINE)
	_bud_body.set_deferred("disabled", true)


## Le Jardin des Fées : un étang qui luit, un cercle de fées, le coffre ; au nord, le mur de
## ronces noires (la suite de l'aventure).
func _build_garden() -> void:
	_room(-8, 8, -60, -43, 8.0, [["s", 0.0, 3.2, 4.2], ["n", 0.0, 3.2, 4.2], ["w", -51.5, 3.0, 3.6], ["e", -51.5, 3.0, 3.6]])
	# Étang lumineux et nénuphars
	_mesh(s, _cyl(2.25, 2.25, 0.04, 28), _water_mat(), Vector3(-4.6, 0.03, -49.0))
	var rim := TorusMesh.new()
	rim.inner_radius = 2.2
	rim.outer_radius = 2.6
	rim.rings = 32
	_mesh(s, rim, _mat("pierre"), Vector3(-4.6, 0.04, -49.0), Vector3.ZERO, Vector3(1, 0.5, 1))
	for k in range(5):
		var a: float = k * 1.25
		_mesh(s, _cyl(0.32, 0.32, 0.02, 12), _glow(Color(0.4, 0.75, 0.4), 0.3), Vector3(-4.6 + cos(a) * 1.3, 0.07, -49.0 + sin(a) * 1.2))
		if k % 2 == 0:
			_mesh(s, _sphere(0.1, 8), _glow(Color(1.0, 0.7, 0.9), 1.5), Vector3(-4.6 + cos(a) * 1.3, 0.14, -49.0 + sin(a) * 1.2), Vector3.ZERO, Vector3(1, 0.6, 1))
	_light(s, Vector3(-4.6, 0.8, -49.0), Color(0.4, 0.95, 0.9), 1.3, 7.0)
	# Le dais de mousse, le cercle de fées, le coffre
	_chest_pos = Vector3(0, 0.3, -55.0)
	_mesh(s, _cyl(2.0, 2.3, 0.3, 24), _mat("mousse"), Vector3(0, 0.15, -55.0))
	var dais := CollisionShape3D.new()
	var dc := CylinderShape3D.new()
	dc.radius = 2.3
	dc.height = 0.3
	dais.shape = dc
	_body.add_child(dais)
	dais.global_position = s.to_global(Vector3(0, 0.15, -55.0))
	for k in range(10):
		var a2: float = TAU * k / 10.0
		var mp := Vector3(cos(a2) * 1.7, 0.3, -55.0 + sin(a2) * 1.7)
		_mesh(s, _cyl(0.025, 0.035, 0.18, 6), _mat("pied"), mp + Vector3.UP * 0.09)
		_mesh(s, _sphere(0.08, 8), _glow(Color(0.95, 0.75, 1.0), 1.2), mp + Vector3.UP * 0.19, Vector3.ZERO, Vector3(1, 0.5, 1))
	var chest := Node3D.new()
	chest.name = "Coffre_des_fees"
	s.add_child(chest)
	chest.position = _chest_pos
	_mesh(chest, _boxm(Vector3(0.9, 0.5, 0.6)), _mat("ecorce"), Vector3(0, 0.25, 0))
	for sx in [-0.38, 0.38]:
		_mesh(chest, _boxm(Vector3(0.06, 0.52, 0.62)), _mat("or"), Vector3(sx, 0.25, 0))
	_chest_lid = Node3D.new()
	_chest_lid.position = Vector3(0, 0.5, -0.3)
	chest.add_child(_chest_lid)
	_mesh(_chest_lid, _cyl(0.3, 0.3, 0.9, 16), _mat("ecorce"), Vector3(0, 0, 0.3), Vector3(0, 0, PI * 0.5), Vector3(1, 1, 1)).scale = Vector3(1, 1, 1)
	_mesh(_chest_lid, _sphere(0.07, 8), _glow(Color(1.0, 0.7, 0.95), 2.5), Vector3(0, 0.3, 0.6))
	var cs := CollisionShape3D.new()
	var cb := BoxShape3D.new()
	cb.size = Vector3(0.9, 0.8, 0.6)
	cs.shape = cb
	_body.add_child(cs)
	cs.global_position = s.to_global(_chest_pos + Vector3.UP * 0.4)
	d._interactions.append({"id": "coffre_fees", "pos": s.to_global(_chest_pos + Vector3(0, 0, 1.0)), "radius": 1.5,
		"text": "E : ouvrir le coffre des fées", "vr": "Gâchette : ouvrir le coffre", "call": _open_chest,
		"when": func(): return not bool(state["coffre"])})
	# Le mur de ronces noires, et derrière, un passage sombre qui s'enfonce (la suite)
	_room(-1.8, 1.8, -74, -60, 4.6, [["s", 0.0, 3.2, 4.2], ["n", 0.0, 3.2, 4.2]])
	_light(s, Vector3(0, 1.5, -64.5), Color(0.8, 0.25, 0.45), 1.2, 6.0)
	var thorns := Node3D.new()
	thorns_node = thorns
	thorns.name = "Ronces"
	s.add_child(thorns)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4340
	for k in range(14):
		var x0: float = rng.randf_range(-1.6, 1.6)
		var a3 := Vector3(x0, 0.0, -60.2)
		var b3 := Vector3(-x0 * 0.6 + rng.randf_range(-0.4, 0.4), 4.2, -60.2 + rng.randf_range(-0.2, 0.2))
		var ctrl: Vector3 = (a3 + b3) * 0.5 + Vector3(rng.randf_range(-1.2, 1.2), 0, 0.3)
		var prev: Vector3 = a3
		for j in range(1, 9):
			var t: float = float(j) / 8.0
			var q: Vector3 = a3.lerp(ctrl, t).lerp(ctrl.lerp(b3, t), t)
			var seg: Vector3 = q - prev
			var m := _mesh(thorns, _cyl(0.06, 0.08, seg.length() + 0.05, 6), _mat("ronce"), (prev + q) * 0.5)
			m.look_at_from_position((prev + q) * 0.5 + s.global_position, q + s.global_position, Vector3.FORWARD if absf(seg.normalized().y) > 0.9 else Vector3.UP)
			m.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			if j % 2 == 0:
				var sp := _mesh(thorns, _cyl(0.0, 0.035, 0.22, 4), _mat("ronce"), q + Vector3(0, 0, 0.08))
				sp.rotation = Vector3(rng.randf_range(0.6, 1.4), rng.randf() * TAU, 0)
			prev = q
	_box(s, Vector3(3.2, 4.2, 0.6), Vector3(0, 2.1, -60.3), _mat("ronce"), true).visible = false
	thorns_cs = _last_cs
	_light(s, Vector3(0, 2.0, -58.8), Color(0.75, 0.3, 0.55), 0.8, 5.0)
	d._interactions.append({"id": "ronces", "pos": s.to_global(Vector3(0, 0, -58.6)), "radius": 1.8,
		"text": "E : examiner les ronces", "vr": "Gâchette : examiner les ronces", "call": _thorns,
		"when": func(): return not bool(state["ronces"])})
	_mushroom(Vector3(6.0, 0, -45.5), 1.9, 1.2, Color(0.95, 0.55, 0.9), true)
	_mushroom(Vector3(5.8, 0, -57.5), 2.4, 1.4, Color(0.55, 0.85, 1.0), true)
	_mushroom(Vector3(-6.2, 0, -57.6), 1.4, 0.9, Color(0.7, 1.0, 0.75), true)
	_crystal_cluster(Vector3(7.0, 0, -51.0), Color(1.0, 0.6, 0.85), 7, 4341, 1.2)
	_sparkles(s, Vector3(0, 3.0, -51.5), Vector3(7, 3, 8), 80, 0.12)
	_light(s, _chest_pos + Vector3(0, 2.2, 1.2), Color(1.0, 0.8, 0.95), 1.6, 7.0)


func _wither_thorns(instant: bool) -> void:
	if thorns_node == null:
		return
	if instant:
		thorns_node.visible = false
	else:
		var tw := create_tween()
		tw.tween_property(thorns_node, "scale", Vector3(1.0, 0.02, 1.0), 2.5).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): thorns_node.visible = false)
		if main.combat_v28 != null:
			for k in range(3):
				main.combat_v28.puff(s.to_global(Vector3(-0.8 + k * 0.8, 1.0 + k * 0.6, -60.2)), Color(1.0, 0.75, 0.95))
	thorns_cs.set_deferred("disabled", true)


func _open_chest() -> void:
	# V48 : on n'ouvre que si tout le contenu tient dans le sac (rien ne se perd).
	if not main.inventory_v28.can_accept([["piece", 60], ["poussiere_fee", 1]]):
		d._say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	state["coffre"] = true
	create_tween().tween_property(_chest_lid, "rotation:x", -1.9, 0.9).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 60)
	var b: int = main.inventory_v28.add("poussiere_fee", 1)
	d._say("Le coffre des fées : %d pièces, et une bourse de poussière de fée qui scintille entre tes doigts.%s Lumi bat des ailes : « Garde-la bien ! »" % [a, "" if b > 0 else " (Ton sac est plein !)"], 7.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(s.to_global(_chest_pos + Vector3.UP * 0.8), Color(1.0, 0.75, 0.95))


func _thorns() -> void:
	var n: int = main.inventory_v28.count("poussiere_fee")
	if n >= 5:
		main.inventory_v28.remove("poussiere_fee", 5)
		state["ronces"] = true
		d._say("Tu ouvres les cinq bourses et souffles la poussière de fée sur les ronces. Elle scintille… et les ronces noires se fanent, se recroquevillent, tombent en poussière. Le passage vers le Trône des Ronces est ouvert.", 8.0)
		lumi_say("Tu as réussi ! Mais attention… la Reine des Ronces nous attend au bout de ce couloir. Je reste près de toi.", 7.0)
		_wither_thorns(false)
		return
	d._say("Un mur de ronces noires, dures comme du fer, qui frémissent quand tu approches. Lumi se cache derrière ton épaule : « Le domaine de la Reine des Ronces… Il nous faudra cinq pincées de poussière de fée pour passer. » (Tu en as %d. La suite au prochain chapitre !)" % n, 8.0)


# =================================================================== Lumi, la petite fée

func _build_lumi() -> void:
	lumi = Node3D.new()
	lumi.name = "Lumi"
	add_child(lumi)
	lumi.global_position = s.to_global(Vector3(1.2, 1.8, 2.0))
	var body := StandardMaterial3D.new()
	body.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body.albedo_color = Color(1.0, 0.85, 0.95)
	_mesh(lumi, _sphere(0.045, 10), body, Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 1.3, 0.8))
	_mesh(lumi, _sphere(0.032, 10), body, Vector3(0, 0.075, 0))
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	wm.albedo_color = Color(0.6, 0.9, 1.0, 0.6)
	for sx in [-1.0, 1.0]:
		for up in [1.0, -1.0]:
			var hinge := Node3D.new()
			lumi.add_child(hinge)
			var w := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.12, 0.09 if up > 0 else 0.07)
			w.mesh = q
			w.material_override = wm
			w.position = Vector3(sx * 0.065, up * 0.04, -0.01)
			w.rotation.z = up * sx * 0.4
			hinge.add_child(w)
			_lumi_wings.append([hinge, sx])
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.45, 0.45)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(1.0, 0.7, 0.95, 0.6)
	hm.albedo_texture = main._soft_dot_v24()
	hq.material = hm
	halo.mesh = hq
	lumi.add_child(halo)
	_light(lumi, Vector3.ZERO, Color(1.0, 0.75, 0.95), 0.9, 5.0)
	var trail := _sparkles(lumi, Vector3.ZERO, Vector3(0.05, 0.05, 0.05), 20, 0.05)
	trail.lifetime = 1.2
	trail.local_coords = false
	trail.gravity = Vector3(0, -0.3, 0)
	_lumi_bubble = Label3D.new()
	_lumi_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lumi_bubble.font_size = 34
	_lumi_bubble.pixel_size = 0.0026
	_lumi_bubble.outline_size = 10
	_lumi_bubble.width = 560
	_lumi_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lumi_bubble.modulate = Color(1.0, 0.9, 1.0)
	_lumi_bubble.position = Vector3(0, 0.35, 0)
	_lumi_bubble.no_depth_test = true
	_lumi_bubble.visible = false
	lumi.add_child(_lumi_bubble)
	var it := {"id": "lumi", "pos": lumi.global_position, "radius": 2.4,
		"text": "E : parler à Lumi", "vr": "Gâchette : parler à Lumi", "call": talk_lumi}
	it["when"] = func(): return in_zone and _nothing_else_near()
	d._interactions.append(it)
	lumi.set_meta("interaction", it)


## Lumi vole toujours à côté du joueur : on ne lui parle que si rien d'autre n'est à portée
## (un cristal, le coffre, les ronces…).
func _nothing_else_near() -> bool:
	var p: Vector3 = main._player_pos_v27()
	for it in d._interactions:
		if str(it["id"]) == "lumi":
			continue
		var q: Vector3 = it["pos"]
		if Vector2(q.x - p.x, q.z - p.z).length() < float(it["radius"]) and absf(q.y - p.y) < 2.5:
			if not it.has("when") or bool((it["when"] as Callable).call()):
				return false
	return true


func lumi_say(text: String, seconds: float = 6.0) -> void:
	_lumi_bubble.text = text
	_lumi_bubble.visible = true
	_lumi_bubble.modulate.a = 1.0
	_lumi_clock = seconds


func talk_lumi() -> void:
	var lines: Array
	if not bool(state["prismes"]):
		lines = ["La Salle des Prismes est au bout du couloir. Le soleil y descend par une fissure… mais il ne va plus jusqu'à la Fleur-Porte.",
			"Tourne les cristaux ! Chacun renvoie la lumière dans la direction où il pointe.",
			"Suis le rayon du regard : là où il touche le mur, c'est qu'il s'est perdu !",
			"La Fleur-Porte ne s'ouvre qu'au soleil. Elle est très coquette."]
	elif not bool(state["coffre"]):
		lines = ["La Fleur-Porte s'est ouverte ! Le Jardin des Fées est juste derrière.",
			"Il y a un coffre sur le dais de mousse… Moi je n'ai pas le droit d'y toucher. Toi, si !"]
	elif not bool(state["clochettes"]):
		lines = ["Mon village est à l'est, derrière la Salle des Clochettes ! Écoute la mélodie au pupitre, puis rejoue-la sur les clochettes.",
			"À l'ouest, c'est la Grotte des Champignons Sauteurs. Les gros champignons roses font rebondir. Hiiii !",
			"Attention aux feux follets : quand ils brillent très fort, ils foncent. Écarte-toi !",
			"Les araignées de cristal laissent des éclats. Grommelot les adore. Chut, c'est un secret."]
	elif bool(state["reine"]):
		lines = ["Églantine est redevenue notre reine ! Le royaume refleurit, grâce à toi.",
			"La carte d'Églantine montre la passe entre les Récifs de Feu, à l'ouest. Les nains de la Montagne de Feu vivent là-bas.",
			"Les nains sont bourrus, mais ce sont les meilleurs forgerons du monde. Grommelot dit que c'est faux. Grommelot est jaloux."]
	elif bool(state["ronces"]):
		lines = ["La Reine des Ronces vole hors de portée. Quand elle se pose, épuisée, c'est le moment de frapper !",
			"Les cercles rouges au sol : des ronces vont jaillir ! Sors du cercle, vite !",
			"Quand elle s'entoure d'un bouclier d'épines, réveille les trois roses de lumière. Leur lumière la brûle !",
			"Avant, elle s'appelait Églantine. C'était notre reine… Les ronces lui ont pris son cœur."]
	else:
		lines = ["Les ronces au nord du jardin… c'est le domaine de la Reine des Ronces. Il nous faudra cinq pincées de poussière de fée pour passer.",
			"Les fées du village ont toutes un service à te demander. En échange, elles donnent de la poussière de fée !",
			"Brindille a perdu ses gouttes de rosée partout. Il y en a même tout en haut de la grotte !",
			"Merci d'avoir ramené les esprits-lucioles. L'Arbre-Mère chante depuis que tu es là."]
	lumi_say(str(lines[_lumi_line % lines.size()]))
	_lumi_line += 1


# =================================================================== état, ambiance, chaque image

func apply_state() -> void:
	var open: bool = bool(state["porte"])
	for i in range(_spirits.size()):
		(_spirits[i] as Node3D).get_node("Lueur").visible = not caught(i) and not open
		if not caught(i):
			((_spirits[i] as Node3D).get_node("Lueur") as Node3D).position = Vector3.UP * 1.3
	for k in range(_niches.size()):
		(_niches[k][0] as Node3D).visible = open
		(_niches[k][1] as OmniLight3D).light_energy = 0.9 if open else 0.0
	if _leaves.size() == 2:
		(_leaves[0] as Node3D).rotation.y = deg_to_rad(-105.0) if open else 0.0
		(_leaves[1] as Node3D).rotation.y = deg_to_rad(105.0) if open else 0.0
		(_door.get_node("Lueur_dedans") as OmniLight3D).light_energy = 1.4 if open else 0.0
	if bool(state["prismes"]):
		for i in range(SOLUTION.size()):
			var c: Dictionary = _crystals[i]
			c["dir"] = SOLUTION[i]
			(c["spin"] as Node3D).rotation.y = _yaw(int(SOLUTION[i]))
		_open_bud(true)
	else:
		for i in range(_crystals.size()):
			var c2: Dictionary = _crystals[i]
			c2["dir"] = int(CRYSTALS[i][1])
			(c2["spin"] as Node3D).rotation.y = _yaw(int(c2["dir"]))
		for hinge in _petals:
			(hinge as Node3D).rotation.x = 0.0
		if _bud_body != null:
			_bud_body.set_deferred("disabled", false)
	if _chest_lid != null:
		_chest_lid.rotation.x = -1.9 if bool(state["coffre"]) else 0.0
	if royaume != null:
		royaume.apply_state()
	if thorns_node != null:
		if bool(state["ronces"]):
			_wither_thorns(true)
		else:
			thorns_node.visible = true
			thorns_node.scale = Vector3.ONE
			thorns_cs.set_deferred("disabled", false)
	if ronces != null:
		ronces.apply_state()
	if _beam_root != null:
		trace_beam()


func _env() -> Environment:
	for c in main.get_children():
		if c is WorldEnvironment:
			return (c as WorldEnvironment).environment
	return null


func _set_ambiance(fairy: bool) -> void:
	var env: Environment = _env()
	if env == null:
		return
	if fairy:
		env.ambient_light_color = Color(0.58, 0.48, 0.75)
		env.ambient_light_energy = 1.1
		env.fog_light_color = Color(0.24, 0.15, 0.32)
		env.fog_density = 0.012
		env.volumetric_fog_albedo = Color(0.85, 0.65, 1.0)
	else:
		env.ambient_light_color = Color(0.32, 0.36, 0.42)
		env.ambient_light_energy = 0.4
		env.fog_light_color = Color(0.02, 0.025, 0.03)
		env.fog_density = 0.035
		env.volumetric_fog_albedo = Color(0.6, 0.55, 0.5)


func _process(delta: float) -> void:
	if main == null or not main.game_started or s == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var lp: Vector3 = s.to_local(p)
	var now: bool = lp.x > -38.0 and lp.x < 52.0 and lp.z > -104.0 and lp.z < 8.0 and lp.y > -6.0 and lp.y < 20.0
	if now != in_zone:
		in_zone = now
		if now:
			_set_ambiance(true)
		elif bool(d.inside):
			_set_ambiance(false)
	elif now and bool(d.inside) and _env() != null and _env().fog_density > 0.03:
		_set_ambiance(true)           # le temple vient de remettre son ambiance (retour d'un voyage)
	# Les esprits-lucioles dansent (seulement près du Bois-Doré)
	if Vector2(p.x - G.x, p.z - G.z).length() < 160.0 and p.y > -20.0:
		for i in range(_spirits.size()):
			var w: Node3D = (_spirits[i] as Node3D).get_node("Lueur")
			if w.visible and not caught(i):
				var t: float = _clock * 1.3 + i * 1.7
				w.position = Vector3(sin(t) * 0.5, 1.3 + sin(t * 2.1) * 0.25, cos(t * 0.8) * 0.5)
	if in_zone:
		_lumi_tick(delta, p)


func _lumi_tick(delta: float, p: Vector3) -> void:
	var look: Vector3 = Vector3(0, 0, -1)
	if main.hero_v28 != null and not main.xr_active:
		look = main.hero_v28.facing
	elif main.xr_active:
		look = -main.xr_camera.global_basis.z
	look.y = 0.0
	look = look.normalized() if look.length() > 0.01 else Vector3(0, 0, -1)
	var right := Vector3(-look.z, 0, look.x)
	var goal: Vector3 = p + right * 0.9 + look * 0.6 + Vector3.UP * (1.75 + sin(_clock * 2.0) * 0.12)
	lumi.global_position = lumi.global_position.lerp(goal, clampf(delta * 1.8, 0.0, 1.0))
	var to_p: Vector3 = (p - lumi.global_position) * Vector3(1, 0, 1)
	if to_p.length() > 0.05:
		lumi.rotation.y = atan2(to_p.x, to_p.z)
	for wg in _lumi_wings:
		(wg[0] as Node3D).rotation.y = float(wg[1]) * (0.3 + sin(_clock * 28.0) * 0.6)
	var it: Dictionary = lumi.get_meta("interaction")
	it["pos"] = Vector3(lumi.global_position.x, p.y, lumi.global_position.z)
	if _lumi_clock > 0.0:
		_lumi_clock -= delta
		_lumi_bubble.modulate.a = clampf(_lumi_clock, 0.0, 1.0)
		if _lumi_clock <= 0.0:
			_lumi_bubble.visible = false
	if not _lumi_greeted and bool(state["visite"]):
		_lumi_greeted = true
		lumi.global_position = p + Vector3.UP * 1.8 + look * 1.5
		lumi_say("Oh ! Un humain, au Royaume des Racines ! Je suis Lumi, une fée des racines. Les esprits t'ont ouvert la porte… alors je te guide !", 7.0)


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return state.duplicate()


func load_data(dd: Dictionary) -> void:
	if ronces != null:
		ronces.reset_session()
	state = {"esprits": 0, "porte": false, "visite": false, "prismes": false, "coffre": false, "rosee": 0, "baguette": false, "clochettes": false, "village": false, "ronces": false, "reine": false, "carte": false}
	for k in state:
		if dd.has(k):
			state[k] = int(dd[k]) if k in ["esprits", "rosee"] else bool(dd[k])
	_lumi_greeted = false
	_lumi_line = 0
	apply_state()

extends Node3D
## V54 : la Citadelle des Nuées, sur l'île flottante.
## Le bâti (ce script) : remparts crénelés, quatre tours rondes coiffées d'ardoise, la porterie,
## la cour d'honneur (fontaine à l'aigle, bancs, bannières, torches), la bibliothèque (à l'est),
## la salle d'armes (à l'ouest), le grand donjon au nord (salle du trône, piliers, lustres,
## vitraux, tapis) et, au-dessus, la Tour des Tempêtes avec sa plate-forme ouverte sur le ciel.
## Le beffroi (tour nord-est) porte quatre cloches. Tout est en dur (collisions).
## Les énigmes, les combats et les coffres sont gérés par ciel_v54.gd ; ce script expose les
## points utiles dans « points ».
## Repère : origine au sol de la cour, au centre ; +Z vers le sud (la porte), -Z vers le donjon.

const Decor = preload("res://scripts/decor_v53.gd")
const Cassable = preload("res://scripts/cassable_v66.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const T := "res://assets/textures/"
const HALF: float = 24.0
const WALL_T: float = 2.4
const WALL_H: float = 11.0
const KEEP_Z0: float = -21.6
const KEEP_Z1: float = -7.0
const KEEP_X: float = 16.0
const KEEP_H: float = 16.0
const TOWER_C := Vector2(0.0, -14.3)
const TOWER_R: float = 7.0
const ARENA_Y: float = 40.0
const ARENA_R: float = 9.2
const BELFRY_C := Vector2(24.0, -24.0)
const BELFRY_R: float = 6.5
const BELFRY_Y: float = 17.0
const BELLS := ["vague", "soleil", "lune", "vent"]

var main: Node
var pc: bool = true
var points: Dictionary = {}
var bells: Dictionary = {}               # nom -> Node3D (la cloche, qui se balance)
var keep_doors: Array = []               # battants de la grande porte du donjon
var seal_sockets: Array = []             # les deux logements du Sceau des Vents
var _body: StaticBody3D
var _mats: Dictionary = {}
var _merlons: Array = []                 # transformations des merlons (une seule instance groupée)
var _rng := RandomNumberGenerator.new()


func build(main_node: Node, high_quality: bool) -> void:
	main = main_node
	pc = high_quality
	_rng.seed = 5455
	_body = StaticBody3D.new()
	_body.name = "Ciel_chateau"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_build_walls()
	_build_towers()
	_build_gatehouse()
	_build_courtyard()
	_build_library()
	_build_armory()
	_build_keep()
	_build_storm_tower()
	_build_belfry()
	_flush_merlons()
	_merge_static()


# =================================================================== matériaux

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"pierre":
			m.albedo_texture = load(T + "chateau/pierre_chateau.png")
			m.normal_enabled = true
			m.normal_texture = load(T + "chateau/pierre_chateau_n.png")
			m.normal_scale = 1.1
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_triplanar_sharpness = 6.0
			m.uv1_scale = Vector3.ONE / 3.2
			m.albedo_color = Color(0.86, 0.83, 0.78)
			m.roughness = 0.9
			m.metallic_specular = 0.35
		"pierre_sombre":
			m = (_mat("pierre") as StandardMaterial3D).duplicate()
			m.albedo_color = Color(0.72, 0.7, 0.68)
		"dalles":
			m.albedo_texture = load(T + "chateau/dalles_chateau.png")
			m.normal_enabled = true
			m.normal_texture = load(T + "chateau/dalles_chateau_n.png")
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 4.0
			m.albedo_color = Color(0.8, 0.76, 0.7)
			m.roughness = 1.0
			m.metallic_specular = 0.0
		"ardoise":
			m.albedo_texture = load(T + "chateau/ardoise.png")
			m.normal_enabled = true
			m.normal_texture = load(T + "chateau/ardoise_n.png")
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 2.6
			m.albedo_color = Color(0.72, 0.74, 0.78)
			m.roughness = 0.7
			m.metallic_specular = 0.45
		"bois":
			m.albedo_texture = load(T + "doors/wood_plain.png")
			m.albedo_color = Color(0.62, 0.46, 0.32)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 1.4
			m.roughness = 0.8
		"porte":
			m.albedo_texture = load(T + "doors/door_wood.png")
			m.normal_enabled = true
			m.normal_texture = load(T + "doors/door_wood_n.png")
			m.albedo_color = Color(0.8, 0.66, 0.52)
			m.roughness = 0.75
		"plancher":
			m.albedo_texture = load(T + "interior/floor.png")
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 2.0
			m.roughness = 0.7
		"tapis":
			m.albedo_texture = load(T + "chateau/tapis.png")
			m.roughness = 0.95
		"banniere":
			m.albedo_texture = load(T + "chateau/banniere.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.9
		"vitrail":
			m.albedo_texture = load(T + "chateau/vitrail.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.emission_enabled = true
			m.emission_texture = load(T + "chateau/vitrail.png")
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 0.55
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"or":
			m.albedo_color = Color(0.92, 0.72, 0.32)
			m.metallic = 0.95
			m.roughness = 0.28
		"bronze":
			m.albedo_color = Color(0.5, 0.33, 0.17)
			m.metallic = 0.65
			m.roughness = 0.42
		"fer":
			return Decor.forged_iron()
		"bleu":
			m.albedo_color = Color(0.12, 0.18, 0.42)
			m.roughness = 0.85
		"noir":
			m.albedo_color = Color(0.03, 0.03, 0.035)
			m.roughness = 1.0
		"eau":
			var sm := ShaderMaterial.new()
			sm.shader = load("res://shaders/waterfall_v26.gdshader")
			sm.set_shader_parameter("fall_length", 2.0)
			sm.set_shader_parameter("flow_speed", 0.25)
			_mats[key] = sm
			return sm
		"cristal_or", "cristal_bleu":
			m.albedo_color = Color(1.0, 0.75, 0.35, 0.9) if key == "cristal_or" else Color(0.45, 0.65, 1.0, 0.9)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = m.albedo_color
			m.emission_energy_multiplier = 3.0
			m.roughness = 0.1
		"rune":
			m.albedo_color = Color(0.5, 0.8, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.4, 0.75, 1.0)
			m.emission_energy_multiplier = 2.2
	_mats[key] = m
	return m


# =================================================================== petites briques

func box(size: Vector3, pos: Vector3, mat_key: String, solid: bool = true, rot_y: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(mat_key)
	mi.position = pos
	mi.rotation.y = rot_y
	(parent if parent != null else self).add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.transform = (parent.transform if parent != null else Transform3D.IDENTITY) * Transform3D(Basis(Vector3.UP, rot_y), pos)
		_body.add_child(cs)
	return mi


func cyl(r_top: float, r_bot: float, h: float, pos: Vector3, mat_key: String, solid: bool = true, sides: int = 24) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _mat(mat_key)
	mi.position = pos
	add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = maxf(r_top, r_bot)
		sh.height = h
		cs.shape = sh
		cs.position = pos
		_body.add_child(cs)
	return mi


func quad(size: Vector2, pos: Vector3, rot_y: float, mat_key: String, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = _mat(mat_key)
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else self).add_child(mi)
	return mi


## Un mur droit de a à b (au sol), épaisseur t, hauteur h, avec des ouvertures [centre le long
## du mur (m), largeur, hauteur]. Merlons le long du sommet si crenel.
func wall(a: Vector2, b: Vector2, t: float, h: float, mat_key: String, openings: Array = [], crenel: bool = false, y0: float = 0.0) -> void:
	var d: Vector2 = b - a
	var length: float = d.length()
	var dir: Vector2 = d / length
	var ang: float = atan2(-dir.y, dir.x)
	var cuts: Array = []
	for o in openings:
		cuts.append([float(o[0]) - float(o[1]) * 0.5, float(o[0]) + float(o[1]) * 0.5, float(o[2])])
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var s: float = 0.0
	for c in cuts:
		if float(c[0]) > s:
			_wall_piece(a, dir, ang, s, float(c[0]), t, 0.0, h, mat_key, y0)
		# linteau au-dessus de l'ouverture
		_wall_piece(a, dir, ang, float(c[0]), float(c[1]), t, float(c[2]), h, mat_key, y0)
		s = float(c[1])
	if s < length:
		_wall_piece(a, dir, ang, s, length, t, 0.0, h, mat_key, y0)
	if crenel:
		var n: int = int(length / 2.0)
		for k in range(n):
			var u: float = (k + 0.5) * length / n
			var p: Vector2 = a + dir * u
			var off := Vector2(-dir.y, dir.x) * (t * 0.5 - 0.35)
			for sd in [-1.0, 1.0]:
				var q: Vector2 = p + off * sd
				_merlons.append(Transform3D(Basis(Vector3.UP, ang), Vector3(q.x, y0 + h + 0.65, q.y)))


func _wall_piece(a: Vector2, dir: Vector2, ang: float, u0: float, u1: float, t: float, z0: float, z1: float, mat_key: String, y0: float) -> void:
	if u1 - u0 < 0.01 or z1 - z0 < 0.01:
		return
	var mid: Vector2 = a + dir * ((u0 + u1) * 0.5)
	box(Vector3(u1 - u0, z1 - z0, t), Vector3(mid.x, y0 + (z0 + z1) * 0.5, mid.y), mat_key, true, ang)


func _flush_merlons() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.3, 0.7)
	mm.mesh = bm
	mm.instance_count = _merlons.size()
	for i in range(_merlons.size()):
		mm.set_instance_transform(i, _merlons[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "Merlons"
	inst.multimesh = mm
	inst.material_override = _mat("pierre")
	add_child(inst)


## Une tour ronde : fût, cordon de pierre, archères, toit conique d'ardoise.
func round_tower(c: Vector2, r: float, h: float, roof: bool = true, slits: int = 6) -> void:
	cyl(r, r * 1.06, h, Vector3(c.x, h * 0.5, c.y), "pierre", true, 28)
	cyl(r * 1.08, r * 1.08, 0.5, Vector3(c.x, h - 1.2, c.y), "pierre_sombre", false, 28)
	cyl(r * 1.12, r * 1.12, 0.8, Vector3(c.x, 0.4, c.y), "pierre_sombre", false, 28)
	for k in range(slits):
		var a: float = TAU * k / slits + 0.3
		for lvl in [0.38, 0.68]:
			var p := Vector3(c.x + cos(a) * (r + 0.02), h * lvl, c.y + sin(a) * (r + 0.02))
			box(Vector3(0.18, 1.3, 0.25), p, "noir", false, -a + PI * 0.5)
	if roof:
		var cone := cyl(0.0, r * 1.22, r * 1.6, Vector3(c.x, h + r * 0.8, c.y), "ardoise", false, 28)
		cone.name = "Toit_tour"
		# épi de faîtage doré
		cyl(0.06, 0.06, 1.6, Vector3(c.x, h + r * 1.6 + 0.8, c.y), "or", false, 8)
		var ball := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.22
		sp.height = 0.44
		ball.mesh = sp
		ball.material_override = _mat("or")
		ball.position = Vector3(c.x, h + r * 1.6 + 0.5, c.y)
		add_child(ball)
	else:
		var n: int = int(TAU * r / 2.0)
		for k in range(n):
			var a2: float = TAU * k / n
			_merlons.append(Transform3D(Basis(Vector3.UP, -a2 + PI * 0.5), Vector3(c.x + cos(a2) * (r - 0.35), h + 0.65, c.y + sin(a2) * (r - 0.35))))


# =================================================================== remparts et tours

func _build_walls() -> void:
	var o: float = HALF - WALL_T * 0.5
	wall(Vector2(-HALF, -o), Vector2(HALF, -o), WALL_T, WALL_H, "pierre", [], true)
	wall(Vector2(o, -HALF), Vector2(o, HALF), WALL_T, WALL_H, "pierre", [], true)
	wall(Vector2(-o, HALF), Vector2(-o, -HALF), WALL_T, WALL_H, "pierre", [], true)
	# Le mur sud, percé de la grande porte (6 m de large, 7 m de haut)
	wall(Vector2(-HALF, o), Vector2(HALF, o), WALL_T, WALL_H, "pierre", [[HALF, 6.0, 7.0]], true)
	# Contreforts extérieurs
	for k in range(-2, 3):
		if k == 0:
			continue
		for side in [[Vector2(k * 9.0, -HALF - 0.6), 0.0], [Vector2(HALF + 0.6, k * 9.0), PI * 0.5], [Vector2(-HALF - 0.6, k * 9.0), PI * 0.5], [Vector2(k * 9.0, HALF + 0.6), 0.0]]:
			var c: Vector2 = side[0]
			if absf(c.x) < 9.5 and c.y > HALF:
				continue
			box(Vector3(1.6, 6.0, 1.2), Vector3(c.x, 3.0, c.y), "pierre_sombre", true, float(side[1]))
	points["porte"] = Vector3(0, 0, HALF + 3.0)
	points["cour"] = Vector3(0, 0, 8.0)


func _build_towers() -> void:
	round_tower(Vector2(-HALF, HALF), 5.0, 17.0)
	round_tower(Vector2(HALF, HALF), 5.0, 17.0)
	round_tower(Vector2(-HALF, -HALF), 5.4, 20.0)
	# La tour nord-est (le beffroi) est construite à part (_build_belfry).


func _build_gatehouse() -> void:
	# Deux tours carrées encadrent la porte, crénelées, avec un arc de pierre
	for sx in [-1.0, 1.0]:
		var c := Vector2(sx * 5.6, HALF + 0.4)
		box(Vector3(5.2, 15.0, 6.0), Vector3(c.x, 7.5, c.y), "pierre", true)
		for k in range(3):
			for e in [[Vector2(-1.9 + k * 1.9, 3.1), 0.0], [Vector2(-1.9 + k * 1.9, -3.1), 0.0]]:
				var q: Vector2 = c + e[0]
				_merlons.append(Transform3D(Basis.IDENTITY, Vector3(q.x, 15.65, q.y)))
		box(Vector3(0.25, 1.6, 0.2), Vector3(c.x, 10.0, c.y + 3.05), "noir", false)
	# Arc : claveaux en éventail au-dessus de l'ouverture
	for k in range(9):
		var a: float = PI * (k + 0.5) / 9.0
		var p := Vector3(cos(a) * 3.2, 7.0 + sin(a) * 0.9 - 0.9, HALF + 1.3)
		var cl := box(Vector3(0.95, 0.6, 0.6), p, "pierre_sombre", false, 0.0)
		cl.rotation.z = a - PI * 0.5
	# Herse relevée (on voit ses pointes sous l'arc) et deux battants de bois ouverts
	var herse := Node3D.new()
	herse.name = "Herse"
	herse.position = Vector3(0, 6.6, HALF - 0.6)
	add_child(herse)
	for k in range(7):
		box(Vector3(0.12, 1.6, 0.12), Vector3(-2.7 + k * 0.9, 0.0, 0), "fer", false, 0.0, herse)
	for k in range(2):
		box(Vector3(5.8, 0.12, 0.12), Vector3(0, -0.5 + k * 0.8, 0), "fer", false, 0.0, herse)
	for sx in [-1.0, 1.0]:
		var leaf := box(Vector3(2.9, 6.2, 0.25), Vector3(sx * 4.3, 3.1, HALF - 1.4), "porte", false, sx * -1.35)
		leaf.name = "Battant_porte"
	# Lanternes de part et d'autre de la porte
	for sx in [-1.0, 1.0]:
		Decor.lantern(self, Vector3(sx * 3.4, 5.2, HALF + 1.4), 1.6)


# =================================================================== la cour d'honneur

func _build_courtyard() -> void:
	var inner: float = HALF - WALL_T
	var floor_mi := box(Vector3(inner * 2.0, 0.2, inner * 2.0), Vector3(0, -0.08, 0), "dalles", false)
	floor_mi.name = "Cour_dallage"
	# Fontaine : bassin octogonal, eau, colonne, l'aigle de pierre au sommet
	var fc := Vector3(0, 0, 5.0)
	points["fontaine"] = fc
	for k in range(8):
		var a: float = TAU * k / 8.0
		box(Vector3(2.6, 0.7, 0.45), fc + Vector3(cos(a) * 3.3, 0.35, sin(a) * 3.3), "pierre", true, -a + PI * 0.5)
	var water := MeshInstance3D.new()
	var wd := CylinderMesh.new()
	wd.top_radius = 3.2
	wd.bottom_radius = 3.2
	wd.height = 0.05
	wd.radial_segments = 8
	water.mesh = wd
	water.material_override = _mat("eau")
	water.position = fc + Vector3.UP * 0.5
	water.rotation.y = PI / 8.0
	add_child(water)
	cyl(0.55, 0.7, 2.6, fc + Vector3.UP * 1.3, "pierre", true, 12)
	cyl(1.1, 0.8, 0.35, fc + Vector3.UP * 2.7, "pierre_sombre", false, 12)
	_stone_eagle(fc + Vector3.UP * 2.85, 0.0, 0.42)
	# Filets d'eau qui retombent de la vasque
	for k in range(4):
		var a2: float = TAU * k / 4.0 + PI * 0.25
		var jet := MeshInstance3D.new()
		var jm := CylinderMesh.new()
		jm.top_radius = 0.05
		jm.bottom_radius = 0.09
		jm.height = 2.2
		jm.radial_segments = 6
		jet.mesh = jm
		jet.material_override = _mat("eau")
		jet.position = fc + Vector3(cos(a2) * 1.05, 1.6, sin(a2) * 1.05)
		add_child(jet)
	# Bancs de pierre, jardinières, tonneaux et caisses
	for p in [Vector3(-7, 0, 5), Vector3(7, 0, 5), Vector3(0, 0, 12), Vector3(0, 0, -2)]:
		var rot: float = PI * 0.5 if absf(p.x) > 1.0 else 0.0
		box(Vector3(2.4, 0.12, 0.6), p + Vector3.UP * 0.5, "pierre", false, rot)
		for e in [-0.9, 0.9]:
			var off := Vector3(e, 0, 0) if rot == 0.0 else Vector3(0, 0, e)
			box(Vector3(0.3, 0.45, 0.5), p + off + Vector3.UP * 0.22, "pierre_sombre", true, rot)
	for p2 in [Vector3(-11.5, 0, 15.0), Vector3(-11.0, 0, 17.0), Vector3(11.0, 0, 15.5)]:
		Cassable.spawn(self, "tonneau", p2, _rng.randf() * TAU, Vector3(0.42 / 0.34, 1.05 / 0.9, 0.42 / 0.34))
	# V66 : on peut les casser (et la petite caisse posée sur la grande tombe quand celle-ci cède)
	Cassable.spawn(self, "caisse", Vector3(12.0, 0.0, 17.0), 0.3, Vector3(1.0, 0.9, 1.0))
	Cassable.spawn(self, "caisse", Vector3(12.2, 0.9, 17.1), 0.8, Vector3(0.8, 0.7, 0.8))
	# Bannières sur les remparts (côté cour) et torches
	var inner_f: float = inner - 0.02
	for x in [-14.0, -6.0, 6.0, 14.0]:
		quad(Vector2(2.2, 4.4), Vector3(x, 7.0, inner_f), PI, "banniere")
	for z in [-2.0, 14.0]:
		quad(Vector2(2.2, 4.4), Vector3(inner_f, 7.0, z), -PI * 0.5, "banniere")
		quad(Vector2(2.2, 4.4), Vector3(-inner_f, 7.0, z), PI * 0.5, "banniere")
	var torches: Array = [[Vector3(-3.4, 3.2, inner - 0.15), Vector3(0, 0, -1)], [Vector3(3.4, 3.2, inner - 0.15), Vector3(0, 0, -1)],
		[Vector3(-inner + 0.15, 3.2, 6.0), Vector3(1, 0, 0)], [Vector3(inner - 0.15, 3.2, 6.0), Vector3(-1, 0, 0)],
		[Vector3(-3.6, 3.4, KEEP_Z1 + 0.15), Vector3(0, 0, 1)], [Vector3(3.6, 3.4, KEEP_Z1 + 0.15), Vector3(0, 0, 1)]]
	if pc:
		torches.append([Vector3(-inner + 0.15, 3.2, 17.0), Vector3(1, 0, 0)])
		torches.append([Vector3(inner - 0.15, 3.2, 17.0), Vector3(-1, 0, 0)])
	points["torches"] = torches
	# Gargouilles de pierre sur les angles des remparts (certaines s'éveilleront…)
	var perches: Array = []
	for c in [Vector2(-inner + 0.8, inner - 0.8), Vector2(inner - 0.8, inner - 0.8), Vector2(-inner + 0.8, -2.0), Vector2(inner - 0.8, -2.0)]:
		perches.append(Vector3(c.x, WALL_H + 0.1, c.y))
	points["perchoirs"] = perches


## Un aigle de pierre (statue), à la hauteur « at », regard vers yaw, échelle s.
func _stone_eagle(at: Vector3, yaw: float, s: float) -> Node3D:
	var A = load("res://scripts/aigle_v54.gd")
	var st: Node3D = A.new()
	add_child(st)
	st.setup(main)
	st.perch_at(Vector3.ZERO, yaw)
	st.position = at
	st.scale = Vector3.ONE * s
	st.set_physics_process(false)
	st.name = "Statue_aigle"
	var stone: Material = _mat("pierre")
	for mi in st.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = stone
	return st


# =================================================================== bibliothèque et salle d'armes

## Un bâtiment adossé au rempart : murs de 0,6 m, porte, toit d'ardoise à deux pans.
func _hall(x0: float, x1: float, z0: float, z1: float, h: float, door_x: float, door_z: float, label: String) -> void:
	var t: float = 0.6
	var door_w: float = 2.4
	var door_h: float = 3.4
	# murs côté cour (x = door_x), nord et sud ; le rempart fait le fond
	var face_x: float = x0 if door_x == x0 else x1
	wall(Vector2(face_x, z0), Vector2(face_x, z1), t, h, "pierre", [[door_z - z0, door_w, door_h]])
	wall(Vector2(x0, z0), Vector2(x1, z0), t, h, "pierre", [[(x1 - x0) * 0.5, 1.6, 4.2]] if false else [])
	wall(Vector2(x0, z1), Vector2(x1, z1), t, h, "pierre")
	# Sol de planches et toit
	box(Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) * 0.5, 0.06, (z0 + z1) * 0.5), "plancher", false)
	var w: float = x1 - x0
	var slope: float = atan2(3.0, w * 0.5)
	var plen: float = sqrt(9.0 + w * w * 0.25) + 0.6
	for sd in [-1.0, 1.0]:
		var pan := box(Vector3(plen, 0.25, z1 - z0 + 1.0), Vector3((x0 + x1) * 0.5 + sd * w * 0.25, h + 1.5, (z0 + z1) * 0.5), "ardoise", false)
		pan.rotation.z = -sd * slope
	# pignons
	for zz in [z0, z1]:
		var gable := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(w, 3.0, 0.6)
		gable.mesh = pm
		gable.material_override = _mat("pierre")
		gable.position = Vector3((x0 + x1) * 0.5, h + 1.5, zz)
		add_child(gable)
	# plafond intérieur (poutres)
	box(Vector3(w - 1.2, 0.2, z1 - z0 - 1.2), Vector3((x0 + x1) * 0.5, h - 0.1, (z0 + z1) * 0.5), "bois", false)
	for k in range(4):
		box(Vector3(w - 1.2, 0.35, 0.3), Vector3((x0 + x1) * 0.5, h - 0.35, z0 + (k + 1) * (z1 - z0) / 5.0), "bois", false)
	# la porte (ouverte) et son encadrement
	var out: float = -1.0 if door_x == x0 else 1.0
	var leaf := box(Vector3(0.15, door_h - 0.1, door_w * 0.95), Vector3(face_x + out * 0.6, (door_h - 0.1) * 0.5, door_z - door_w * 0.5 - 0.5), "porte", false)
	leaf.rotation.y = out * 1.1
	box(Vector3(0.8, 0.4, door_w + 0.8), Vector3(face_x, door_h + 0.2, door_z), "pierre_sombre", false)
	quad(Vector2(1.6, 0.5), Vector3(face_x + out * 0.42, door_h + 0.75, door_z), out * PI * 0.5, "bleu")
	points[label + "_porte"] = Vector3(face_x + out * 1.2, 0, door_z)
	points[label + "_centre"] = Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	# Lumière intérieure
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.5)
	l.light_energy = 1.6
	l.omni_range = 11.0
	l.position = Vector3((x0 + x1) * 0.5, h - 1.6, (z0 + z1) * 0.5)
	add_child(l)


func _build_library() -> void:
	var x0: float = HALF - WALL_T - 8.0
	var x1: float = HALF - WALL_T
	_hall(x0, x1, -5.0, 11.0, 7.0, x0, 3.0, "bibliotheque")
	# Rayonnages de livres le long des murs
	var books: Array = []
	for z in range(-4, 11, 2):
		if absf(z - 3.0) < 2.0:
			continue
		var sx: float = x1 - 0.45
		box(Vector3(0.6, 3.6, 1.9), Vector3(sx, 1.8, z + 0.0), "bois", true)
		for shelf in range(5):
			for b in range(9):
				var bh: float = _rng.randf_range(0.42, 0.62)
				books.append([Transform3D(Basis(Vector3.UP, 0.0).rotated(Vector3.FORWARD, _rng.randf_range(-0.08, 0.08)).scaled(Vector3(0.36, bh, 0.16)), Vector3(sx - 0.33, 0.35 + shelf * 0.7 + bh * 0.5, z - 0.8 + b * 0.2)), Color.from_hsv(_rng.randf_range(0.0, 0.12) if _rng.randf() < 0.7 else _rng.randf_range(0.55, 0.7), _rng.randf_range(0.4, 0.75), _rng.randf_range(0.25, 0.6))])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = books.size()
	for i in range(books.size()):
		mm.set_instance_transform(i, books[i][0])
		mm.set_instance_color(i, books[i][1])
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.roughness = 0.75
	var inst := MultiMeshInstance3D.new()
	inst.name = "Livres"
	inst.multimesh = mm
	inst.material_override = bm
	add_child(inst)
	# Le lutrin et le grand livre ouvert (la clé de l'énigme des cloches)
	var lc := Vector3(x0 + 4.0, 0, 6.5)
	box(Vector3(0.5, 1.1, 0.5), lc + Vector3.UP * 0.55, "bois", true)
	var top := box(Vector3(0.9, 0.06, 0.7), lc + Vector3.UP * 1.18, "bois", false)
	top.rotation.x = -0.35
	var page := box(Vector3(0.8, 0.03, 0.56), lc + Vector3(0, 1.23, 0.02), "or", false)
	page.material_override = _paper()
	page.rotation.x = -0.35
	points["lutrin"] = lc
	# Une table et des chandelles
	box(Vector3(2.4, 0.1, 1.2), Vector3(x0 + 3.5, 0.85, -2.0), "bois", true)


func _paper() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.88, 0.74)
	m.roughness = 0.95
	return m


func _build_armory() -> void:
	var x0: float = -HALF + WALL_T
	var x1: float = x0 + 8.0
	_hall(x0, x1, -5.0, 11.0, 7.0, x1, 3.0, "armurerie")
	# Râteliers d'armes le long du rempart
	for z in [-3.5, -1.0, 7.5, 9.8]:
		box(Vector3(0.3, 2.2, 1.8), Vector3(x0 + 0.3, 1.1, z), "bois", true)
		for k in range(4):
			var spear := box(Vector3(0.06, 2.6, 0.06), Vector3(x0 + 0.55, 1.4, z - 0.6 + k * 0.4), "bois", false)
			spear.rotation.z = 0.12
			box(Vector3(0.1, 0.35, 0.03), Vector3(x0 + 0.72, 2.8, z - 0.6 + k * 0.4), "fer", false)
	# Trois socles d'armure (les armures s'éveilleront)
	var stands: Array = []
	for k in range(3):
		var p := Vector3(x0 + 2.2, 0, -1.0 + k * 4.2)
		box(Vector3(1.0, 0.25, 1.0), p + Vector3.UP * 0.13, "pierre_sombre", true)
		stands.append(p + Vector3(0.6, 0.3, 0))
	points["armures"] = stands
	points["coffre_couchant"] = Vector3(x0 + 4.0, 0, -3.6)
	# Mannequin d'entraînement, bouclier au mur
	cyl(0.12, 0.12, 1.8, Vector3(x1 - 1.5, 0.9, 8.5), "bois", true, 8)
	box(Vector3(1.1, 0.12, 0.12), Vector3(x1 - 1.5, 1.5, 8.5), "bois", false)


# =================================================================== le grand donjon

func _build_keep() -> void:
	var t: float = 1.2
	# Façade percée de la grande porte (4,4 m x 5,6 m) et de deux hautes fenêtres
	wall(Vector2(-KEEP_X, KEEP_Z1), Vector2(KEEP_X, KEEP_Z1), t, KEEP_H, "pierre", [[KEEP_X, 4.4, 5.6]], true)
	wall(Vector2(-KEEP_X, KEEP_Z0), Vector2(-KEEP_X, KEEP_Z1), t, KEEP_H, "pierre", [], true)
	wall(Vector2(KEEP_X, KEEP_Z0), Vector2(KEEP_X, KEEP_Z1), t, KEEP_H, "pierre", [], true)
	# Le fond s'appuie sur le rempart nord, qu'on surélève
	box(Vector3(KEEP_X * 2.0, KEEP_H - WALL_H, WALL_T), Vector3(0, WALL_H + (KEEP_H - WALL_H) * 0.5, -HALF + WALL_T * 0.5), "pierre", true)
	# Toit plat (terrasse) et plafond à caissons
	box(Vector3(KEEP_X * 2.0 + 1.2, 0.8, KEEP_Z1 - KEEP_Z0 + 2.4), Vector3(0, KEEP_H + 0.4, (KEEP_Z0 + KEEP_Z1) * 0.5 - 0.6), "pierre", true)
	box(Vector3(KEEP_X * 2.0 - 1.2, 0.3, KEEP_Z1 - KEEP_Z0 - 0.6), Vector3(0, 12.0, (KEEP_Z0 + KEEP_Z1) * 0.5), "bois", false)
	for k in range(7):
		box(Vector3(0.45, 0.6, KEEP_Z1 - KEEP_Z0 - 0.6), Vector3(-12.0 + k * 4.0, 11.6, (KEEP_Z0 + KEEP_Z1) * 0.5), "bois", false)
	# Sol de dalles, tapis rouge et or jusqu'au trône
	box(Vector3(KEEP_X * 2.0 - 1.2, 0.1, KEEP_Z1 - KEEP_Z0 - 0.6), Vector3(0, 0.05, (KEEP_Z0 + KEEP_Z1) * 0.5), "dalles", false)
	var carpet := MeshInstance3D.new()
	var cm := PlaneMesh.new()
	cm.size = Vector2(3.2, 11.5)
	carpet.mesh = cm
	carpet.material_override = _mat("tapis")
	carpet.position = Vector3(0, 0.12, -13.5)
	add_child(carpet)
	# Piliers et bannières
	for x in [-7.0, 7.0]:
		for z in [-10.5, -14.5, -18.5]:
			cyl(0.75, 0.85, 11.4, Vector3(x, 5.7, z), "pierre", true, 16)
			cyl(1.05, 0.8, 0.6, Vector3(x, 11.1, z), "pierre_sombre", false, 16)
			cyl(1.0, 1.0, 0.5, Vector3(x, 0.25, z), "pierre_sombre", false, 16)
			quad(Vector2(1.4, 3.0), Vector3(x + (0.9 if x > 0 else -0.9), 7.0, z), PI * 0.5 if x > 0 else -PI * 0.5, "banniere")
	# Vitraux sur les murs latéraux et au fond
	for sx in [-1.0, 1.0]:
		for z in [-12.5, -17.0]:
			quad(Vector2(2.4, 4.8), Vector3(sx * (KEEP_X - 0.62), 6.5, z), sx * -PI * 0.5, "vitrail")
	for x2 in [-5.0, 5.0]:
		quad(Vector2(2.4, 4.8), Vector3(x2, 7.0, KEEP_Z0 + 0.03), 0.0, "vitrail")
	# L'estrade et le trône des Rois-Ciel
	box(Vector3(7.0, 0.5, 3.0), Vector3(0, 0.25, KEEP_Z0 + 2.0), "pierre_sombre", true)
	box(Vector3(5.0, 0.3, 2.0), Vector3(0, 0.62, KEEP_Z0 + 1.8), "pierre_sombre", true)
	box(Vector3(1.6, 0.6, 1.1), Vector3(0, 1.07, KEEP_Z0 + 1.6), "bleu", true)
	box(Vector3(1.8, 3.4, 0.3), Vector3(0, 2.4, KEEP_Z0 + 1.0), "or", false)
	for sx in [-1.0, 1.0]:
		box(Vector3(0.25, 1.0, 1.1), Vector3(sx * 0.9, 1.4, KEEP_Z0 + 1.6), "or", false)
	_stone_eagle(Vector3(0, 4.1, KEEP_Z0 + 1.0), 0.0, 0.27)
	points["trone"] = Vector3(0, 0.8, KEEP_Z0 + 3.5)
	# Lustres de fer (bougies) et leurs lumières
	for z in [-10.5, -14.5, -18.5]:
		var ch := Node3D.new()
		ch.position = Vector3(0, 9.0, z)
		add_child(ch)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0
		tm.outer_radius = 1.12
		tm.rings = 24
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = _mat("fer")
		ch.add_child(ring)
		for k in range(8):
			var a: float = TAU * k / 8.0
			var flame := MeshInstance3D.new()
			var fs := SphereMesh.new()
			fs.radius = 0.06
			fs.height = 0.16
			flame.mesh = fs
			flame.material_override = Decor.flame_core()
			flame.position = Vector3(cos(a) * 1.06, 0.2, sin(a) * 1.06)
			ch.add_child(flame)
		box(Vector3(0.05, 2.8, 0.05), Vector3(0, 1.4, 0), "fer", false, 0.0, ch)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.76, 0.48)
		l.light_energy = 2.6
		l.omni_range = 13.0
		l.position = Vector3(0, -0.5, 0)
		ch.add_child(l)
	# La grande porte du donjon : deux battants de chêne bardés de fer (fermés)
	for sx in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "Gond_donjon"
		hinge.position = Vector3(sx * 2.2, 0, KEEP_Z1 + 0.1)
		add_child(hinge)
		var leaf := box(Vector3(2.2, 5.5, 0.3), Vector3(-sx * 1.1, 2.75, 0), "porte", false, 0.0, hinge)
		leaf.name = "Battant"
		for k in range(3):
			box(Vector3(2.0, 0.12, 0.05), Vector3(-sx * 1.1, 0.8 + k * 1.9, 0.18), "fer", false, 0.0, hinge)
		hinge.set_meta("cote", sx)
		keep_doors.append(hinge)
	# Collision des battants (retirée à l'ouverture)
	var door_body := StaticBody3D.new()
	door_body.name = "Porte_donjon_collision"
	door_body.collision_layer = 1
	door_body.collision_mask = 0
	var dcs := CollisionShape3D.new()
	var dsh := BoxShape3D.new()
	dsh.size = Vector3(4.4, 5.6, 0.6)
	dcs.shape = dsh
	dcs.position = Vector3(0, 2.8, KEEP_Z1)
	door_body.add_child(dcs)
	add_child(door_body)
	points["porte_donjon_corps"] = door_body
	points["porte_donjon"] = Vector3(0, 0, KEEP_Z1 + 2.4)
	points["salle"] = Vector3(0, 0, -12.0)
	points["salle_monstres"] = [Vector3(-4.0, 0.2, -16.0), Vector3(4.0, 0.2, -16.0)]
	# Le Sceau des Vents : une stèle à deux logements, à gauche de la porte
	var sc := Vector3(-4.6, 0, KEEP_Z1 + 1.4)
	box(Vector3(1.4, 1.5, 0.8), sc + Vector3.UP * 0.75, "pierre_sombre", true)
	quad(Vector2(1.2, 0.5), sc + Vector3(0, 1.25, 0.41), 0.0, "rune")
	for k in range(2):
		var sock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.32
		sock.mesh = sm
		sock.material_override = _mat("noir")
		sock.position = sc + Vector3(-0.35 + k * 0.7, 1.58, 0.0)
		add_child(sock)
		seal_sockets.append(sock)
	points["sceau"] = sc
	# La porte de l'escalier de la Tour des Tempêtes (au fond, à droite du trône)
	var sd := Vector3(10.5, 0, KEEP_Z0 + 0.15)
	box(Vector3(2.0, 3.6, 0.2), sd + Vector3.UP * 1.8, "porte", false)
	box(Vector3(2.6, 0.4, 0.4), sd + Vector3(0, 3.8, 0.1), "pierre_sombre", false)
	points["escalier_tour"] = sd + Vector3(0, 0, 1.6)


# =================================================================== la Tour des Tempêtes

func _build_storm_tower() -> void:
	var c := Vector3(TOWER_C.x, 0, TOWER_C.y)
	var h: float = ARENA_Y - KEEP_H
	cyl(TOWER_R, TOWER_R * 1.05, h, c + Vector3.UP * (KEEP_H + h * 0.5), "pierre", true, 32)
	for lvl in [0.3, 0.6]:
		for k in range(6):
			var a: float = TAU * k / 6.0
			box(Vector3(0.22, 1.8, 0.3), c + Vector3(cos(a) * (TOWER_R + 0.03), KEEP_H + h * lvl, sin(a) * (TOWER_R + 0.03)), "noir", false, -a + PI * 0.5)
	# Mâchicoulis : la plate-forme déborde, portée par des consoles
	for k in range(24):
		var a2: float = TAU * k / 24.0
		box(Vector3(0.5, 1.4, 1.6), c + Vector3(cos(a2) * (TOWER_R + 0.6), ARENA_Y - 1.4, sin(a2) * (TOWER_R + 0.6)), "pierre_sombre", false, -a2 + PI * 0.5)
	# Le sol de l'arène et son parapet crénelé
	cyl(ARENA_R + 0.6, ARENA_R + 0.6, 1.0, c + Vector3.UP * (ARENA_Y - 0.5), "dalles", true, 40)
	var n: int = 30
	for k in range(n):
		var a3: float = TAU * k / n
		var p := c + Vector3(cos(a3) * (ARENA_R + 0.3), ARENA_Y + 0.55, sin(a3) * (ARENA_R + 0.3))
		box(Vector3(2.05, 1.1, 0.6), p, "pierre", true, -a3 + PI * 0.5)
		if k % 2 == 0:
			_merlons.append(Transform3D(Basis(Vector3.UP, -a3 + PI * 0.5), p + Vector3.UP * 1.2))
		# barrière invisible plus haute : on ne tombe pas de la tour
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.1, 4.0, 0.4)
		cs.shape = sh
		cs.transform = Transform3D(Basis(Vector3.UP, -a3 + PI * 0.5), p + Vector3.UP * 2.0)
		_body.add_child(cs)
	# Un cercle de runes au sol (l'arène de Sire Orage) et l'arrivée de l'escalier
	var rune := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 5.0
	tm.outer_radius = 5.25
	tm.rings = 48
	tm.ring_segments = 4
	rune.mesh = tm
	rune.material_override = _mat("rune")
	rune.scale = Vector3(1, 0.05, 1)
	rune.position = c + Vector3.UP * (ARENA_Y + 0.02)
	add_child(rune)
	points["arene"] = c + Vector3.UP * ARENA_Y
	points["arene_arrivee"] = c + Vector3(0, ARENA_Y, ARENA_R - 2.0)
	# La trappe de l'escalier, au bord sud de la plate-forme
	box(Vector3(1.6, 0.1, 1.6), c + Vector3(0, ARENA_Y + 0.05, ARENA_R - 0.9), "bois", false)


# =================================================================== le beffroi (tour nord-est)

func _build_belfry() -> void:
	var c := Vector3(BELFRY_C.x, 0, BELFRY_C.y)
	cyl(BELFRY_R, BELFRY_R * 1.05, BELFRY_Y, c + Vector3.UP * BELFRY_Y * 0.5, "pierre", true, 32)
	cyl(BELFRY_R * 1.12, BELFRY_R * 1.12, 0.8, c + Vector3.UP * 0.4, "pierre_sombre", false, 32)
	# L'étage des cloches : six piliers, un parapet, une flèche d'ardoise
	cyl(BELFRY_R + 0.2, BELFRY_R + 0.2, 0.6, c + Vector3.UP * (BELFRY_Y - 0.3), "dalles", true, 32)
	for k in range(6):
		var a: float = TAU * k / 6.0
		var p := c + Vector3(cos(a) * (BELFRY_R - 0.4), BELFRY_Y + 3.0, sin(a) * (BELFRY_R - 0.4))
		box(Vector3(0.9, 6.0, 0.9), p, "pierre", true, -a)
	for k in range(24):
		var a2: float = TAU * k / 24.0
		var p2 := c + Vector3(cos(a2) * (BELFRY_R - 0.3), BELFRY_Y + 0.55, sin(a2) * (BELFRY_R - 0.3))
		box(Vector3(1.75, 1.1, 0.4), p2, "pierre", true, -a2 + PI * 0.5)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.8, 3.0, 0.3)
		cs.shape = sh
		cs.transform = Transform3D(Basis(Vector3.UP, -a2 + PI * 0.5), p2 + Vector3.UP * 1.5)
		_body.add_child(cs)
	cyl(BELFRY_R + 0.5, BELFRY_R + 0.5, 0.6, c + Vector3.UP * (BELFRY_Y + 6.3), "pierre_sombre", false, 32)
	cyl(0.0, BELFRY_R * 1.25, 10.0, c + Vector3.UP * (BELFRY_Y + 11.6), "ardoise", false, 32)
	cyl(0.06, 0.06, 2.2, c + Vector3.UP * (BELFRY_Y + 17.6), "or", false, 8)
	# Charpente et cloches
	box(Vector3(BELFRY_R * 1.8, 0.4, 0.4), c + Vector3.UP * (BELFRY_Y + 5.2), "bois", false, PI * 0.25)
	box(Vector3(BELFRY_R * 1.8, 0.4, 0.4), c + Vector3.UP * (BELFRY_Y + 5.2), "bois", false, -PI * 0.25)
	var glyphs := {"vague": "glyph_vague", "soleil": "glyph_soleil", "lune": "glyph_lune", "vent": ""}
	for k in range(4):
		var a3: float = TAU * k / 4.0 + PI * 0.25
		var at := c + Vector3(cos(a3) * 2.6, BELFRY_Y + 5.0, sin(a3) * 2.6)
		var bell: Node3D = _bell(at, BELLS[k], str(glyphs[BELLS[k]]))
		bells[BELLS[k]] = bell
		points["cloche_" + BELLS[k]] = Vector3(at.x, BELFRY_Y, at.z) + (Vector3(c.x, 0, c.z) - Vector3(at.x, 0, at.z)).normalized() * 1.2
	points["beffroi_porte"] = c + Vector3(-BELFRY_R - 1.6, 0, BELFRY_R + 1.6) * 0.72
	points["beffroi_haut"] = c + Vector3(-2.2, BELFRY_Y, 2.2)
	points["coffre_levant"] = c + Vector3(0, BELFRY_Y, 0)
	# La porte du beffroi, côté cour
	var dir := Vector3(-1, 0, 1).normalized()
	var door_at := c + dir * (BELFRY_R + 0.05)
	box(Vector3(1.8, 3.2, 0.2), door_at + Vector3.UP * 1.6, "porte", false, -PI * 0.25)


## Une cloche de bronze (profil tourné), son battant et une plaque gravée.
func _bell(at: Vector3, name_id: String, glyph: String) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Cloche_" + name_id
	pivot.position = at
	add_child(pivot)
	var prof: Array = [[0.0, 0.0], [0.28, -0.05], [0.42, -0.3], [0.48, -0.75], [0.62, -1.05], [0.72, -1.2], [0.7, -1.26]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 24
	for i in range(prof.size() - 1):
		for j in range(segs):
			var a0: float = TAU * j / segs
			var a1: float = TAU * (j + 1) / segs
			var r0: float = prof[i][0]
			var r1: float = prof[i + 1][0]
			var y0: float = prof[i][1]
			var y1: float = prof[i + 1][1]
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			for tri in [[p00, p01, p10], [p01, p11, p10]]:
				for v in tri:
					st.add_vertex(v)
	st.generate_normals()
	var bell := MeshInstance3D.new()
	bell.mesh = st.commit()
	var bm: StandardMaterial3D = (_mat("bronze") as StandardMaterial3D).duplicate()
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bell.material_override = bm
	pivot.add_child(bell)
	var clapper := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.12
	cs.height = 0.24
	clapper.mesh = cs
	clapper.material_override = _mat("fer")
	clapper.position = Vector3(0, -1.05, 0)
	pivot.add_child(clapper)
	box(Vector3(0.06, 0.5, 0.06), Vector3(0, 0.25, 0), "fer", false, 0.0, pivot)
	# Plaque gravée (le symbole de la cloche) sur un poteau, côté intérieur
	var plaque := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.55, 0.55)
	plaque.mesh = qm
	var pm := StandardMaterial3D.new()
	if glyph != "":
		pm.albedo_texture = load(T + "temple/" + glyph + ".png")
	else:
		pm.albedo_color = Color(0.85, 0.82, 0.74)
	pm.roughness = 0.85
	plaque.material_override = pm
	plaque.position = Vector3(0, -1.75, 0)
	plaque.rotation.y = atan2(-(at.x - (BELFRY_C.x)), -(at.z - BELFRY_C.y)) + PI
	pivot.add_child(plaque)
	if glyph == "":
		# le Vent : trois traits ondulés peints
		for k in range(3):
			var stroke := MeshInstance3D.new()
			var sq := QuadMesh.new()
			sq.size = Vector2(0.4, 0.04)
			stroke.mesh = sq
			stroke.material_override = _mat("noir")
			stroke.position = Vector3(0, 0.12 - k * 0.12, 0.005)
			plaque.add_child(stroke)
	return pivot


## Fait sonner une cloche : elle se balance (le son est joué par ciel_v54.gd).
func ring(name_id: String) -> void:
	var b: Node3D = bells.get(name_id)
	if b == null:
		return
	var tw := create_tween()
	tw.tween_property(b, "rotation:z", 0.45, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "rotation:z", -0.32, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "rotation:z", 0.18, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "rotation:z", 0.0, 0.4).set_trans(Tween.TRANS_SINE)


## Les battants du donjon s'ouvrent (instant : sans animation).
func open_keep(instant: bool) -> void:
	for h in keep_doors:
		var hinge: Node3D = h
		var target: float = float(hinge.get_meta("cote")) * -1.5
		if instant:
			hinge.rotation.y = target
		else:
			create_tween().tween_property(hinge, "rotation:y", target, 3.0).set_trans(Tween.TRANS_SINE)
	var body: StaticBody3D = points["porte_donjon_corps"]
	body.collision_layer = 0


func close_keep() -> void:
	for h in keep_doors:
		(h as Node3D).rotation.y = 0.0
	(points["porte_donjon_corps"] as StaticBody3D).collision_layer = 1


## Les cristaux posés dans le sceau s'allument.
func show_seal(levant: bool, couchant: bool) -> void:
	(seal_sockets[0] as MeshInstance3D).material_override = _mat("cristal_or") if levant else _mat("noir")
	(seal_sockets[1] as MeshInstance3D).material_override = _mat("cristal_bleu") if couchant else _mat("noir")


## Fusionne les blocs immobiles de même matériau en quelques maillages : beaucoup moins
## d'appels de rendu (important en VR). Les pièces mobiles (battants, cloches, logements du
## sceau…) ne sont pas des enfants directs ou sont exclues.
var merged_count: int = 0

func _merge_static() -> void:
	var groups: Dictionary = {}
	var shadows: Dictionary = {}
	var removed: Array = []
	for c in get_children():
		if not (c is MeshInstance3D):
			continue
		var mi: MeshInstance3D = c
		if mi.get_child_count() > 0 or mi.material_override == null or not (mi.mesh is PrimitiveMesh):
			continue
		if mi in seal_sockets:
			continue
		var mat: Material = mi.material_override
		if not groups.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[mat] = st
			shadows[mat] = false
		(groups[mat] as SurfaceTool).append_from(mi.mesh, 0, mi.transform)
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadows[mat] = true
		removed.append(mi)
	for mi in removed:
		remove_child(mi)
		mi.queue_free()
	for mat in groups:
		var m := MeshInstance3D.new()
		m.name = "Bati_%d" % get_child_count()
		m.mesh = (groups[mat] as SurfaceTool).commit()
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(shadows[mat]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
	merged_count = removed.size()


## Un point du château en coordonnées du monde.
func at(key: String) -> Vector3:
	return to_global(points[key])

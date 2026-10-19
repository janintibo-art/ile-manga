extends Node3D
## V55 : l'Atlantide, la cité engloutie, à 30 m sous la mer au sud-ouest du village.
## Une bulle d'air (le dôme, un demi-ellipsoïde de 92 m de large et 24 m de haut) entretenue
## par le Grand Cristal, au sommet de la tour centrale. Dedans, on marche et on respire ;
## on entre et on sort en traversant la paroi (la « membrane »), n'importe où.
##  - le canal circulaire et ses quatre ponts, la place pavée de mosaïque, la tour du cristal ;
##  - le palais de la reine Néréa (nord), l'atelier de Coralin (est), les archives d'Abyssos
##    (ouest), l'étal de Marée, les maisons rondes aux dômes de cuivre, les jardins de corail
##    lumineux, les lampes de cristal, la statue du roi Atlas ;
##  - la Porte des Marées (sud), son avenue de colonnes et l'obélisque dont la pointe sort
##    de l'eau (le phare de la cité, visible depuis la plage du village) ;
##  - les habitants (pnj/atlantes_habitants_v55.gd).
## Angles : 0° = nord (-Z), 90° = est (+X), 180° = sud (+Z, la porte).

const PnjScript = preload("res://scripts/pnj/pnj_v31.gd")
const Habitants = preload("res://scripts/pnj/atlantes_habitants_v55.gd")
const HeroLib = preload("res://scripts/hero_v28.gd")
const C := Vector3(-220.0, -30.0, 260.0)
const DOME_R: float = 46.0
const DOME_H: float = 24.0
const SLEEP_FAR: float = 80.0

var main: Node
var villagers: Array = []
var by_id: Dictionary = {}
var points: Dictionary = {}
var graph: Dictionary = {}
var crystal_mesh: MeshInstance3D
var crystal_mat: StandardMaterial3D
var crystal_light: OmniLight3D
var dome_mat: ShaderMaterial
var lamp_lights: Array = []
var lamp_mats: Array = []
var lit: bool = false                       # le Grand Cristal brille (quête finie)
var obelisk_tip: Vector3
var _mats: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _bodies: Array = []


func at(angle_deg: float, r: float, y: float = 0.0) -> Vector3:
	var a: float = deg_to_rad(angle_deg)
	return C + Vector3(sin(a) * r, y, -cos(a) * r)


## Dans la bulle d'air ?
func in_dome(p: Vector3) -> bool:
	var dy: float = p.y - C.y
	if dy < -2.0:
		return false
	var dx: float = p.x - C.x
	var dz: float = p.z - C.z
	return (dx * dx + dz * dz) / (DOME_R * DOME_R) + (dy * dy) / (DOME_H * DOME_H) < 1.0


## Hauteur intérieure du dôme à une distance r du centre (sol = 0).
func dome_height(r: float) -> float:
	return DOME_H * sqrt(maxf(1.0 - (r * r) / (DOME_R * DOME_R), 0.0))


func near(p: Vector3, extra: float = 30.0) -> bool:
	return Vector2(p.x - C.x, p.z - C.z).length() < DOME_R + extra


# =================================================================== matériaux

func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func mat(key: String) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"marbre":
			m.albedo_texture = _tex("res://assets/textures/atlantide/marbre.png")
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/atlantide/marbre_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.22
			m.roughness = 0.35
			m.albedo_color = Color(0.96, 0.97, 0.98)
		"marbre_bleu":
			m.albedo_texture = _tex("res://assets/textures/atlantide/marbre.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.22
			m.roughness = 0.35
			m.albedo_color = Color(0.62, 0.8, 0.86)
		"mosaique":
			m.albedo_texture = _tex("res://assets/textures/atlantide/mosaique.png")
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/atlantide/mosaique_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.12
			m.roughness = 0.4
			m.albedo_color = Color(0.8, 0.84, 0.86)
		"cuivre":
			m.albedo_texture = _tex("res://assets/textures/atlantide/cuivre_vert.png")
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/atlantide/cuivre_vert_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.3
			m.metallic = 0.45
			m.roughness = 0.5
		"or":
			m.albedo_color = Color(0.92, 0.74, 0.34)
			m.metallic = 0.95
			m.roughness = 0.28
		"frise":
			m.albedo_texture = _tex("res://assets/textures/atlantide/frise.png")
			m.uv1_scale = Vector3(8.0, 1.0, 1.0)
			m.roughness = 0.5
		"eau_canal":
			m.albedo_color = Color(0.12, 0.45, 0.55, 0.78)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic = 0.2
			m.normal_enabled = true
			m.normal_texture = _tex("res://assets/textures/water/water_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.25
		"fresque":
			m.albedo_texture = _tex("res://assets/textures/atlantide/fresque.png")
			m.roughness = 0.8
		"bois":
			m.albedo_color = Color(0.42, 0.3, 0.2)
			m.roughness = 0.8
		"algue_seche":
			m.albedo_color = Color(0.32, 0.4, 0.16)
			m.roughness = 0.9
		"tissu":
			m.albedo_color = Color(0.2, 0.55, 0.6)
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"parchemin":
			m.albedo_color = Color(0.88, 0.82, 0.66)
			m.roughness = 0.9
		_:
			m.albedo_color = Color(0.8, 0.8, 0.8)
	_mats[key] = m
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.15
	return m


# =================================================================== petites briques

func _mesh(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(top: float, bottom: float, h: float, seg: int = 24) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	return c


func _dome_cap(r: float, h: float, seg: int = 24) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h * 2.0
	s.is_hemisphere = true
	s.radial_segments = seg
	s.rings = 10
	return s


func _solid_box(name_s: String, center: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	var b := StaticBody3D.new()
	b.name = name_s
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	add_child(b)
	b.global_transform = Transform3D(Basis(Vector3.UP, yaw), center)


func _solid_cyl(name_s: String, center: Vector3, r: float, h: float) -> void:
	var b := StaticBody3D.new()
	b.name = name_s
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	b.add_child(cs)
	add_child(b)
	b.global_position = center


## Une colonne cannelée : base, fût, chapiteau doré.
func _column(parent: Node3D, pos: Vector3, h: float, r: float = 0.42) -> void:
	_mesh(parent, _cyl(r * 1.35, r * 1.45, 0.35, 16), mat("marbre"), pos + Vector3(0, 0.175, 0))
	_mesh(parent, _cyl(r * 0.92, r, h - 0.85, 16), mat("marbre"), pos + Vector3(0, 0.35 + (h - 0.85) * 0.5, 0))
	_mesh(parent, _cyl(r * 1.45, r * 1.0, 0.3, 16), mat("or"), pos + Vector3(0, h - 0.35, 0))
	_mesh(parent, _box(Vector3(r * 3.1, 0.2, r * 3.1)), mat("marbre"), pos + Vector3(0, h - 0.1, 0))


# =================================================================== construction

func build(main_node: Node) -> void:
	main = main_node
	name = "Atlantide_v55"
	_rng.seed = 5502
	var t0: int = Time.get_ticks_msec()
	_build_floor_and_canal()
	_build_tower()
	_build_palace()
	_build_workshop()
	_build_archives()
	_build_market()
	_build_houses()
	_build_gardens_and_lamps()
	_build_statue()
	_build_gate_and_obelisk()
	_build_dome()
	set_lit(false, true)
	print("ILE_MANGA_V55: Atlantide construite en %d ms" % (Time.get_ticks_msec() - t0))


func _build_floor_and_canal() -> void:
	var root := Node3D.new()
	root.name = "Atlantide_place"
	add_child(root)
	root.global_position = C
	# La place : un grand disque de mosaïque (et sa bordure de marbre)
	_mesh(root, _cyl(44.0, 44.0, 0.3, 64), mat("mosaique"), Vector3(0, 0.0, 0))
	_mesh(root, _cyl(44.6, 45.2, 0.5, 64), mat("marbre"), Vector3(0, -0.12, 0))
	_solid_cyl("Atlantide_sol", C + Vector3(0, 0.0, 0), 44.0, 0.3)
	# Le canal circulaire : eau entre deux margelles, ouverte par quatre ponts
	_mesh(root, _cyl(9.0, 9.0, 0.06, 64), mat("eau_canal"), Vector3(0, 0.12, 0))
	for k in range(48):
		var a: float = TAU * k / 48.0
		var deg: float = rad_to_deg(a)
		var on_bridge: bool = false
		for b in [0.0, 90.0, 180.0, 270.0]:
			if absf(wrapf(deg - b, -180.0, 180.0)) < 10.0:
				on_bridge = true
		if on_bridge:
			continue
		for rr in [6.0, 9.0]:
			var p := Vector3(sin(a) * rr, 0.42, -cos(a) * rr)
			_mesh(root, _box(Vector3(1.25, 0.55, 0.35)), mat("marbre"), p, Vector3(0, -a, 0))
		_solid_box("Canal_margelle", C + Vector3(sin(a) * 9.0, 0.42, -cos(a) * 9.0), Vector3(1.3, 0.6, 0.4), -a)
	# Les quatre ponts (marbre, garde-corps dorés)
	for b2 in [0.0, 90.0, 180.0, 270.0]:
		var a2: float = deg_to_rad(b2)
		var mid := Vector3(sin(a2) * 7.5, 0.35, -cos(a2) * 7.5)
		_mesh(root, _box(Vector3(3.2, 0.25, 3.6)), mat("marbre"), mid, Vector3(0, -a2, 0))
		for sx in [-1.0, 1.0]:
			var side: Vector3 = Vector3(cos(a2), 0, sin(a2)) * 1.55 * sx
			_mesh(root, _box(Vector3(0.12, 0.6, 3.4)), mat("or"), mid + side + Vector3(0, 0.4, 0), Vector3(0, -a2, 0))
		_solid_box("Pont_canal", C + mid, Vector3(3.2, 0.25, 3.6), -a2)
	# L'eau ne doit pas arrêter le joueur : sous les ponts, rien ; dans le canal, un muret invisible
	for k2 in range(24):
		var a3: float = TAU * (k2 + 0.5) / 24.0
		var deg3: float = rad_to_deg(a3)
		var bridge: bool = false
		for b3 in [0.0, 90.0, 180.0, 270.0]:
			if absf(wrapf(deg3 - b3, -180.0, 180.0)) < 14.0:
				bridge = true
		if not bridge:
			_solid_box("Canal_eau", C + Vector3(sin(a3) * 7.5, 0.6, -cos(a3) * 7.5), Vector3(2.4, 1.2, 2.6), -a3)


func _build_tower() -> void:
	var root := Node3D.new()
	root.name = "Tour_du_cristal"
	add_child(root)
	root.global_position = C
	_mesh(root, _cyl(5.6, 6.0, 0.5, 48), mat("marbre"), Vector3(0, 0.25, 0))
	_mesh(root, _cyl(2.4, 3.2, 1.2, 32), mat("marbre"), Vector3(0, 1.1, 0))
	# Le fût qui s'affine, cerclé d'or, et les quatre arcs-boutants
	_mesh(root, _cyl(1.0, 2.2, 13.0, 24), mat("marbre"), Vector3(0, 8.2, 0))
	for y in [3.0, 6.5, 10.0, 13.5]:
		_mesh(root, _cyl(2.22 - (y - 1.7) * 0.093 + 0.05, 2.24 - (y - 1.7) * 0.093 + 0.05, 0.25, 24), mat("or"), Vector3(0, y, 0))
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var d := Vector3(sin(a), 0, -cos(a))
		_mesh(root, _box(Vector3(0.45, 3.0, 0.8)), mat("marbre"), d * 3.6 + Vector3(0, 1.5, 0), Vector3(0, -a, 0.0))
		var strut := _mesh(root, _box(Vector3(0.4, 6.0, 0.6)), mat("marbre"), d * 2.6 + Vector3(0, 5.5, 0))
		strut.look_at_from_position(strut.global_position, root.global_position + Vector3(0, 13.0, 0), Vector3.UP)
		strut.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	# La couronne dorée et le Grand Cristal
	_mesh(root, _cyl(1.6, 1.0, 0.6, 24), mat("or"), Vector3(0, 14.9, 0))
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0
		_mesh(root, _cyl(0.0, 0.18, 1.6, 6), mat("or"), Vector3(sin(a2) * 1.3, 15.9, -cos(a2) * 1.3), Vector3(cos(a2) * 0.35, 0, sin(a2) * 0.35))
	crystal_mat = _glow(Color(0.55, 0.95, 1.0), 1.0)
	crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_mat.albedo_color.a = 0.85
	crystal_mat.metallic = 0.2
	var cm := _cyl(0.0, 1.3, 2.6, 8)
	crystal_mesh = _mesh(root, cm, crystal_mat, Vector3(0, 17.3, 0))
	_mesh(root, _cyl(1.3, 0.0, 1.4, 8), crystal_mat, Vector3(0, 15.3, 0))
	crystal_light = OmniLight3D.new()
	crystal_light.name = "Lumiere_grand_cristal"
	crystal_light.light_color = Color(0.6, 0.95, 1.0)
	crystal_light.omni_range = 62.0
	crystal_light.omni_attenuation = 0.9
	crystal_light.shadow_enabled = false
	crystal_light.position = Vector3(0, 16.5, 0)
	root.add_child(crystal_light)
	_solid_cyl("Tour_cristal_collision", C + Vector3(0, 6.0, 0), 2.6, 12.0)
	_solid_cyl("Tour_cristal_socle", C + Vector3(0, 0.25, 0), 6.0, 0.5)
	points["cristal"] = C + Vector3(0, 16.5, 0)


func _build_palace() -> void:
	var root := Node3D.new()
	root.name = "Palais_de_Nerea"
	add_child(root)
	root.global_position = at(0.0, 31.0)
	var podium_h: float = 1.2
	_mesh(root, _box(Vector3(20.0, podium_h, 13.0)), mat("marbre"), Vector3(0, podium_h * 0.5, 0))
	_solid_box("Palais_podium", root.global_position + Vector3(0, podium_h * 0.5, 0), Vector3(20.0, podium_h, 13.0))
	# Les marches (côté sud, vers la place)
	for s in range(4):
		var hh: float = podium_h * (s + 1) / 5.0
		var z: float = 6.5 + (4 - s) * 0.45
		_mesh(root, _box(Vector3(12.0, hh, 0.5)), mat("marbre"), Vector3(0, hh * 0.5, z))
		_solid_box("Palais_marche", root.global_position + Vector3(0, hh * 0.5, z), Vector3(12.0, hh, 0.5))
	# Colonnade (8 colonnes de façade, 3 de chaque côté), mur du fond avec la fresque
	var col_h: float = 7.5
	for k in range(8):
		_column(root, Vector3(-8.75 + k * 2.5, podium_h, 5.6), col_h)
	for k2 in range(3):
		for sx in [-1.0, 1.0]:
			_column(root, Vector3(sx * 8.75, podium_h, 2.6 - k2 * 3.4), col_h)
	_mesh(root, _box(Vector3(18.5, col_h, 0.8)), mat("marbre_bleu"), Vector3(0, podium_h + col_h * 0.5, -5.8))
	_solid_box("Palais_mur", root.global_position + Vector3(0, podium_h + col_h * 0.5, -5.8), Vector3(18.5, col_h, 0.8))
	# Entablement, frise, fronton et dôme de cuivre
	_mesh(root, _box(Vector3(20.0, 1.0, 13.0)), mat("marbre"), Vector3(0, podium_h + col_h + 0.5, 0))
	var frieze := _mesh(root, _box(Vector3(20.1, 0.6, 13.1)), mat("frise"), Vector3(0, podium_h + col_h + 0.45, 0))
	frieze.material_override = mat("frise")
	_mesh(root, _dome_cap(5.5, 4.0, 32), mat("cuivre"), Vector3(0, podium_h + col_h + 1.0, -0.5))
	_mesh(root, _cyl(0.2, 0.35, 1.2, 12), mat("or"), Vector3(0, podium_h + col_h + 5.5, -0.5))
	# Toit : il arrête la caméra, pas le joueur (calque 256)
	var roof := StaticBody3D.new()
	roof.name = "Palais_toit"
	roof.collision_layer = 256
	var rcs := CollisionShape3D.new()
	var rsh := BoxShape3D.new()
	rsh.size = Vector3(20.0, 1.0, 13.0)
	rcs.shape = rsh
	roof.add_child(rcs)
	root.add_child(roof)
	roof.position = Vector3(0, podium_h + col_h + 0.5, 0)
	# Le trône de nacre, la fresque, deux vasques de lumière
	var throne := Node3D.new()
	root.add_child(throne)
	throne.position = Vector3(0, podium_h, -4.2)
	_mesh(throne, _box(Vector3(2.0, 0.5, 1.6)), mat("marbre"), Vector3(0, 0.25, 0))
	_mesh(throne, _box(Vector3(1.4, 0.6, 1.2)), mat("tissu"), Vector3(0, 0.75, 0.1))
	_mesh(throne, _box(Vector3(1.6, 2.8, 0.3)), mat("marbre_bleu"), Vector3(0, 1.9, -0.65))
	_mesh(throne, _cyl(0.0, 0.9, 0.9, 5), mat("or"), Vector3(0, 3.7, -0.65), Vector3(PI * 0.5, 0, 0), Vector3(1.0, 0.4, 1.0))
	var fresco := _mesh(root, QuadMesh.new(), mat("fresque"), Vector3(0, podium_h + 4.0, -5.38))
	(fresco.mesh as QuadMesh).size = Vector2(10.0, 5.0)
	_solid_box("Palais_trone", throne.global_position + Vector3(0, 0.8, -0.2), Vector3(2.0, 1.6, 1.6))
	for sx2 in [-1.0, 1.0]:
		var bowl := Vector3(sx2 * 5.0, podium_h, -3.5)
		_mesh(root, _cyl(0.25, 0.35, 1.2, 12), mat("or"), bowl + Vector3(0, 0.6, 0))
		_mesh(root, _cyl(0.7, 0.3, 0.35, 16), mat("or"), bowl + Vector3(0, 1.35, 0))
		_mesh(root, _cyl(0.0, 0.45, 0.6, 7), _glow(Color(0.5, 0.95, 1.0), 3.0), bowl + Vector3(0, 1.75, 0))
	var pl := OmniLight3D.new()
	pl.light_color = Color(0.65, 0.95, 1.0)
	pl.light_energy = 1.2
	pl.omni_range = 12.0
	pl.position = Vector3(0, podium_h + 4.5, -1.0)
	root.add_child(pl)
	lamp_lights.append(pl)
	points["palais"] = root.global_position + Vector3(0, podium_h, -2.2)
	points["palais_devant"] = root.global_position + Vector3(0, podium_h, 3.5)
	points["palais_marches"] = root.global_position + Vector3(0, 0, 9.2)


func _build_workshop() -> void:
	var root := Node3D.new()
	root.name = "Atelier_de_Coralin"
	add_child(root)
	root.global_position = at(90.0, 31.0)
	root.rotation.y = PI * 0.5         # mur à l'est, ouvert vers la place (à l'ouest)
	_mesh(root, _box(Vector3(9.0, 0.3, 7.0)), mat("marbre"), Vector3(0, 0.15, 0))
	for p in [Vector3(-4.0, 0.3, -3.0), Vector3(4.0, 0.3, -3.0), Vector3(-4.0, 0.3, 3.0), Vector3(4.0, 0.3, 3.0)]:
		_column(root, p, 4.6, 0.3)
	_mesh(root, _box(Vector3(9.4, 0.4, 7.4)), mat("cuivre"), Vector3(0, 5.0, 0))
	_mesh(root, _box(Vector3(9.0, 4.6, 0.4)), mat("marbre_bleu"), Vector3(0, 2.6, 3.3))
	_solid_box("Atelier_mur", root.to_global(Vector3(0, 2.6, 3.3)), Vector3(9.0, 4.6, 0.6), root.rotation.y)
	# L'enclume de corail qui rougeoie, l'établi, les tridents
	_mesh(root, _box(Vector3(1.4, 0.8, 0.8)), mat("marbre_bleu"), Vector3(1.5, 0.7, 0.5))
	_mesh(root, _box(Vector3(1.0, 0.25, 0.6)), _glow(Color(1.0, 0.45, 0.35), 1.6), Vector3(1.5, 1.2, 0.5))
	_mesh(root, _box(Vector3(3.0, 0.15, 1.0)), mat("bois"), Vector3(-2.0, 1.0, 2.2))
	for lx in [-3.2, -0.8]:
		_mesh(root, _box(Vector3(0.12, 1.0, 0.8)), mat("bois"), Vector3(lx, 0.5, 2.2))
	for k in range(4):
		var tri := Node3D.new()
		root.add_child(tri)
		tri.position = Vector3(-3.5 + k * 0.5, 0.3, 3.0)
		_mesh(tri, _cyl(0.03, 0.03, 2.4, 6), mat("or"), Vector3(0, 1.2, 0))
		for t in [-1.0, 0.0, 1.0]:
			_mesh(tri, _cyl(0.0, 0.03, 0.4, 6), mat("or"), Vector3(t * 0.12, 2.55, 0))
	# Sculptures de corail rouge (sur des socles)
	for k2 in range(3):
		var base := Vector3(3.5, 0.3, -2.0 + k2 * 1.6)
		_mesh(root, _cyl(0.3, 0.35, 0.8, 12), mat("marbre"), base + Vector3(0, 0.4, 0))
		_mesh(root, _cyl(0.0, 0.25, 0.9, 6), _glow(Color(0.95, 0.35, 0.3), 0.6), base + Vector3(0, 1.25, 0))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.45)
	light.light_energy = 1.0
	light.omni_range = 7.0
	light.position = Vector3(1.5, 2.0, 0.5)
	root.add_child(light)
	lamp_lights.append(light)
	points["atelier"] = root.to_global(Vector3(0.2, 0.3, 0.3))
	points["atelier_devant"] = at(90.0, 25.5)


func _build_archives() -> void:
	var root := Node3D.new()
	root.name = "Archives_d_Abyssos"
	add_child(root)
	root.global_position = at(270.0, 31.0)
	root.rotation.y = -PI * 0.5        # mur à l'ouest, ouvert vers la place (à l'est)
	_mesh(root, _box(Vector3(10.0, 0.3, 8.0)), mat("marbre"), Vector3(0, 0.15, 0))
	_mesh(root, _box(Vector3(10.0, 6.0, 0.5)), mat("marbre_bleu"), Vector3(0, 3.2, 3.8))
	for sx in [-1.0, 1.0]:
		_mesh(root, _box(Vector3(0.5, 6.0, 8.0)), mat("marbre_bleu"), Vector3(sx * 4.8, 3.2, 0))
		_solid_box("Archives_mur", root.to_global(Vector3(sx * 4.8, 3.2, 0)), Vector3(0.6, 6.0, 8.0), root.rotation.y)
	_solid_box("Archives_fond", root.to_global(Vector3(0, 3.2, 3.8)), Vector3(10.0, 6.0, 0.6), root.rotation.y)
	_mesh(root, _box(Vector3(10.6, 0.5, 8.6)), mat("marbre"), Vector3(0, 6.4, 0))
	_mesh(root, _dome_cap(3.8, 2.6, 24), mat("cuivre"), Vector3(0, 6.6, 0.5))
	for k in range(4):
		_column(root, Vector3(-3.6 + k * 2.4, 0.3, -3.8), 5.9, 0.32)
	# Étagères de rouleaux le long des murs
	for sx2 in [-1.0, 1.0]:
		for k2 in range(3):
			var shelf := Vector3(sx2 * 4.3, 0.3, -1.8 + k2 * 1.9)
			_mesh(root, _box(Vector3(0.5, 3.6, 1.7)), mat("bois"), shelf + Vector3(0, 1.8, 0))
			for row in range(4):
				for c in range(5):
					_mesh(root, _cyl(0.06, 0.06, 0.42, 8), mat("parchemin"), shelf + Vector3(-sx2 * 0.05, 0.45 + row * 0.85, -0.65 + c * 0.32), Vector3(0, 0, PI * 0.5))
	# La table de lecture et la fresque de l'histoire
	_mesh(root, _box(Vector3(2.4, 0.12, 1.2)), mat("bois"), Vector3(0, 1.0, 1.4))
	_mesh(root, _box(Vector3(0.12, 1.0, 1.0)), mat("bois"), Vector3(-1.0, 0.5, 1.4))
	_mesh(root, _box(Vector3(0.12, 1.0, 1.0)), mat("bois"), Vector3(1.0, 0.5, 1.4))
	var fresco := _mesh(root, QuadMesh.new(), mat("fresque"), Vector3(0, 3.4, 3.52), Vector3(0, PI, 0))
	(fresco.mesh as QuadMesh).size = Vector2(7.0, 3.5)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.9, 1.0)
	light.light_energy = 0.9
	light.omni_range = 8.0
	light.position = Vector3(0, 4.0, 0.5)
	root.add_child(light)
	lamp_lights.append(light)
	points["archives"] = root.to_global(Vector3(0, 0.3, 0.3))
	points["archives_devant"] = at(270.0, 25.5)


func _build_market() -> void:
	var root := Node3D.new()
	root.name = "Etal_de_Maree"
	add_child(root)
	root.global_position = at(150.0, 19.5)
	root.look_at(C, Vector3.UP)
	_mesh(root, _box(Vector3(3.4, 1.0, 1.0)), mat("bois"), Vector3(0, 0.5, 0))
	for sx in [-1.0, 1.0]:
		_mesh(root, _cyl(0.06, 0.06, 2.6, 8), mat("bois"), Vector3(sx * 1.6, 1.3, 0.6))
		_mesh(root, _cyl(0.06, 0.06, 2.6, 8), mat("bois"), Vector3(sx * 1.6, 1.3, -0.6))
	var awning := _mesh(root, _box(Vector3(3.8, 0.06, 2.0)), mat("tissu"), Vector3(0, 2.6, 0), Vector3(0.18, 0, 0))
	awning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in range(5):
		_mesh(root, _cyl(0.3, 0.25, 0.3, 12), mat("algue_seche"), Vector3(-1.3 + k * 0.65, 1.15, 0))
	_solid_box("Etal_collision", root.global_position + Vector3(0, 0.5, 0), Vector3(3.4, 1.0, 1.0), root.rotation.y)
	points["marche"] = root.to_global(Vector3(0, 0, 1.2))


func _build_houses() -> void:
	var angles := [40.0, 62.0, 118.0, 138.0, 222.0, 242.0, 298.0, 320.0]
	for k in range(angles.size()):
		var a: float = angles[k]
		var r: float = 33.0 + (k % 2) * 3.0
		var root := Node3D.new()
		root.name = "Maison_atlante_%d" % k
		add_child(root)
		root.global_position = at(a, r)
		root.look_at(C, Vector3.UP)
		var rad: float = 3.3 + (k % 3) * 0.4
		var wall_h: float = 4.4 + (k % 2) * 0.8
		_mesh(root, _cyl(rad, rad + 0.1, wall_h, 32), mat("marbre"), Vector3(0, wall_h * 0.5, 0))
		_mesh(root, _cyl(rad + 0.12, rad + 0.12, 0.5, 32), mat("frise"), Vector3(0, wall_h - 0.3, 0))
		_mesh(root, _dome_cap(rad + 0.3, rad * 0.8, 32), mat("cuivre"), Vector3(0, wall_h, 0))
		_mesh(root, _cyl(0.1, 0.2, 0.8, 10), mat("or"), Vector3(0, wall_h + rad * 0.8 + 0.3, 0))
		# Porte en arc et fenêtres rondes, qui luisent
		_mesh(root, _box(Vector3(1.4, 2.4, 0.3)), _glow(Color(0.35, 0.7, 0.8), 0.5), Vector3(0, 1.2, -rad - 0.02))
		_mesh(root, _cyl(0.7, 0.7, 0.3, 16), _glow(Color(0.35, 0.7, 0.8), 0.5), Vector3(0, 2.4, -rad - 0.02), Vector3(PI * 0.5, 0, 0))
		for sx in [-1.0, 1.0]:
			var wa: float = sx * 0.85
			_mesh(root, _cyl(0.38, 0.38, 0.2, 14), _glow(Color(0.95, 0.85, 0.55), 0.9), Vector3(sin(wa) * rad, 2.8, -cos(wa) * rad), Vector3(PI * 0.5, 0, -wa))
		_solid_cyl("Maison_atlante_collision", root.global_position + Vector3(0, wall_h * 0.5, 0), rad + 0.1, wall_h)


func _build_gardens_and_lamps() -> void:
	# Lampes de cristal autour de la place
	for k in range(8):
		var a: float = 22.5 + 45.0 * k
		var p: Vector3 = at(a, 21.5)
		var root := Node3D.new()
		root.name = "Lampe_cristal_%d" % k
		add_child(root)
		root.global_position = p
		_mesh(root, _cyl(0.12, 0.18, 3.0, 10), mat("marbre"), Vector3(0, 1.5, 0))
		_mesh(root, _cyl(0.3, 0.12, 0.3, 10), mat("or"), Vector3(0, 3.1, 0))
		var gm := _glow(Color(0.55, 0.95, 1.0), 2.0)
		lamp_mats.append(gm)
		_mesh(root, _cyl(0.0, 0.25, 0.7, 6), gm, Vector3(0, 3.6, 0))
		_mesh(root, _cyl(0.25, 0.0, 0.35, 6), gm, Vector3(0, 3.07, 0))
		_solid_cyl("Lampe_cristal_collision", p + Vector3(0, 1.5, 0), 0.2, 3.0)
		if k % 2 == 0:
			var l := OmniLight3D.new()
			l.light_color = Color(0.6, 0.95, 1.0)
			l.light_energy = 1.0
			l.omni_range = 11.0
			l.shadow_enabled = false
			l.position = Vector3(0, 3.6, 0)
			root.add_child(l)
			lamp_lights.append(l)
	# Jardins de corail lumineux, dans des vasques, entre les maisons
	var palette := [Color(0.95, 0.45, 0.7), Color(0.45, 0.95, 0.8), Color(0.65, 0.55, 1.0), Color(1.0, 0.7, 0.35)]
	for k2 in range(10):
		var a2: float = 10.0 + k2 * 36.0
		if absf(wrapf(a2 - 180.0, -180.0, 180.0)) < 14.0:
			continue
		var p2: Vector3 = at(a2, 40.0)
		var root2 := Node3D.new()
		root2.name = "Jardin_corail_%d" % k2
		add_child(root2)
		root2.global_position = p2
		_mesh(root2, _cyl(1.5, 1.3, 0.6, 24), mat("marbre"), Vector3(0, 0.3, 0))
		for j in range(7):
			var c: Color = palette[(k2 + j) % palette.size()]
			var off := Vector3(_rng.randf_range(-0.9, 0.9), 0.6, _rng.randf_range(-0.9, 0.9))
			var h: float = _rng.randf_range(0.5, 1.4)
			_mesh(root2, _cyl(0.03, 0.08, h, 6), _glow(c, 1.2), off + Vector3(0, h * 0.5, 0), Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4)))
			var bulb := SphereMesh.new()
			bulb.radius = 0.1
			bulb.height = 0.2
			_mesh(root2, bulb, _glow(c.lightened(0.3), 2.5), off + Vector3(0, h, 0))
		_solid_cyl("Jardin_corail_collision", p2 + Vector3(0, 0.3, 0), 1.5, 0.6)
	# Les cultures d'algues sur des claies, au bord du dôme
	for k3 in range(6):
		var a3: float = 200.0 + k3 * 30.0
		if a3 > 340.0:
			break
		var p3: Vector3 = at(a3, 43.0)
		var rack := Node3D.new()
		add_child(rack)
		rack.global_position = p3
		rack.look_at(C, Vector3.UP)
		_mesh(rack, _box(Vector3(2.4, 0.08, 0.8)), mat("bois"), Vector3(0, 1.2, 0))
		for j2 in range(5):
			_mesh(rack, _box(Vector3(0.08, 0.9, 0.05)), mat("algue_seche"), Vector3(-1.0 + j2 * 0.5, 0.7, 0))


func _build_statue() -> void:
	var root := Node3D.new()
	root.name = "Statue_roi_Atlas"
	add_child(root)
	root.global_position = at(325.0, 16.5)
	_mesh(root, _box(Vector3(2.6, 1.6, 2.6)), mat("marbre_bleu"), Vector3(0, 0.8, 0))
	_mesh(root, _box(Vector3(2.9, 0.25, 2.9)), mat("or"), Vector3(0, 1.62, 0))
	_solid_box("Statue_socle", root.global_position + Vector3(0, 0.8, 0), Vector3(2.6, 1.6, 2.6))
	var packed: PackedScene = load("res://assets/models/characters/hero.glb") if ResourceLoader.exists("res://assets/models/characters/hero.glb") else null
	if packed == null:
		return
	var model: Node3D = packed.instantiate()
	root.add_child(model)
	model.position = Vector3(0, 1.75, 0)
	model.scale = Vector3.ONE * 2.2
	model.look_at(Vector3(C.x, model.global_position.y, C.z), Vector3.UP)
	model.rotate_y(PI)
	var marble: StandardMaterial3D = mat("marbre").duplicate()
	marble.albedo_color = Color(0.9, 0.92, 0.95)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = marble
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var found := model.find_children("*", "Skeleton3D", true, false)
	if anim != null and found.size() > 0:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = anim
		lib.skel = found[0]
		lib._build_animations()
		lib.free()
		if anim.has_animation("v28/slash3"):
			anim.play("v28/slash3")
			anim.seek(0.16, true)
			anim.pause()
		# Le trident de marbre dans la main droite
		var skel: Skeleton3D = found[0]
		var b: int = skel.find_bone("RightHand")
		if b >= 0:
			var att := BoneAttachment3D.new()
			att.bone_name = "RightHand"
			skel.add_child(att)
			var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
			var holder := Node3D.new()
			holder.transform = Transform3D(rest.inverse() * Basis.from_scale(Vector3.ONE * 100.0), Vector3.ZERO)
			att.add_child(holder)
			var tri := Node3D.new()
			holder.add_child(tri)
			_mesh(tri, _cyl(0.025, 0.025, 1.6, 8), marble, Vector3(0, 0.3, 0))
			for t in [-1.0, 0.0, 1.0]:
				_mesh(tri, _cyl(0.0, 0.03, 0.35, 6), marble, Vector3(t * 0.1, 1.25, 0))
			_mesh(tri, _box(Vector3(0.28, 0.04, 0.04)), marble, Vector3(0, 1.08, 0))


func _build_gate_and_obelisk() -> void:
	var root := Node3D.new()
	root.name = "Porte_des_Marees"
	add_child(root)
	root.global_position = at(180.0, 40.0)
	# Deux piliers, un arc, des marches
	for sx in [-1.0, 1.0]:
		_mesh(root, _box(Vector3(1.4, 6.0, 1.4)), mat("marbre"), Vector3(sx * 3.2, 3.0, 0))
		_mesh(root, _box(Vector3(1.7, 0.4, 1.7)), mat("or"), Vector3(sx * 3.2, 6.2, 0))
		_solid_box("Porte_pilier", root.global_position + Vector3(sx * 3.2, 3.0, 0), Vector3(1.4, 6.0, 1.4))
	# L'arc en plein cintre : des voussoirs posés sur le demi-cercle, la clé dorée au sommet
	for k in range(11):
		var a: float = PI * (k + 0.5) / 11.0
		var vp := Vector3(cos(a) * 3.2, 6.4 + sin(a) * 3.2, 0)
		var vm: Material = mat("or") if k == 5 else mat("marbre")
		_mesh(root, _box(Vector3(1.3, 0.95, 1.4)), vm, vp, Vector3(0, 0, a - PI * 0.5))
	_mesh(root, _cyl(0.0, 0.5, 1.0, 6), _glow(Color(0.55, 0.95, 1.0), 2.5), Vector3(0, 10.5, 0))
	points["porte"] = at(176.0, 36.0)
	points["porte_dehors"] = at(180.0, 50.0) + Vector3(0, 1.5, 0)
	# L'avenue : colonnes (certaines brisées) jusqu'à l'obélisque
	for k in range(4):
		for sx2 in [-1.0, 1.0]:
			var p: Vector3 = at(180.0 + sx2 * 6.5, 49.0 + k * 4.0)
			var h: float = 5.0 if (k + int(sx2)) % 3 != 0 else 2.2
			var col := Node3D.new()
			add_child(col)
			col.global_position = p
			_column(col, Vector3.ZERO, h, 0.38)
	# L'obélisque : du fond (30 m) jusqu'au-dessus de la surface
	var ob := Node3D.new()
	ob.name = "Obelisque_des_Marees"
	add_child(ob)
	ob.global_position = at(180.0, 66.0)
	var total: float = 31.0
	_mesh(ob, _box(Vector3(4.0, 1.5, 4.0)), mat("marbre_bleu"), Vector3(0, 0.75, 0))
	var shaft := BoxMesh.new()
	shaft.size = Vector3(2.2, total, 2.2)
	var sm := _mesh(ob, shaft, mat("marbre"), Vector3(0, 1.5 + total * 0.5, 0))
	sm.scale = Vector3(1.0, 1.0, 1.0)
	for y in [6.0, 14.0, 22.0, 30.0]:
		_mesh(ob, _box(Vector3(2.35, 0.4, 2.35)), mat("or"), Vector3(0, 1.5 + y, 0))
	_mesh(ob, _cyl(0.0, 1.55, 2.4, 4), mat("or"), Vector3(0, 1.5 + total + 1.2, 0), Vector3(0, PI * 0.25, 0))
	var tip_mat := _glow(Color(0.55, 0.95, 1.0), 3.5)
	_mesh(ob, _cyl(0.0, 0.5, 1.4, 6), tip_mat, Vector3(0, 1.5 + total + 2.9, 0))
	obelisk_tip = ob.global_position + Vector3(0, 1.5 + total + 2.9, 0)
	var tl := OmniLight3D.new()
	tl.name = "Phare_obelisque"
	tl.light_color = Color(0.6, 0.95, 1.0)
	tl.light_energy = 1.6
	tl.omni_range = 18.0
	tl.position = Vector3(0, 1.5 + total + 3.4, 0)
	ob.add_child(tl)
	_solid_box("Obelisque_collision", ob.global_position + Vector3(0, (1.5 + total) * 0.5, 0), Vector3(2.4, 1.5 + total, 2.4))
	points["obelisque"] = ob.global_position


func _build_dome() -> void:
	dome_mat = ShaderMaterial.new()
	dome_mat.shader = load("res://shaders/dome_v55.gdshader")
	dome_mat.set_shader_parameter("caustic_tex", _tex("res://assets/textures/mer/caustiques.png"))
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.is_hemisphere = true
	sm.radial_segments = 96
	sm.rings = 32
	var mi := MeshInstance3D.new()
	mi.name = "Dome_atlantide"
	mi.mesh = sm
	mi.material_override = dome_mat
	mi.scale = Vector3(DOME_R, DOME_H, DOME_R)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.add_to_group("sous_eau_v55")
	add_child(mi)
	mi.global_position = C
	# L'anneau de bronze qui tient le dôme
	var ring := TorusMesh.new()
	ring.inner_radius = DOME_R - 0.6
	ring.outer_radius = DOME_R + 0.4
	ring.rings = 96
	ring.ring_segments = 8
	var rm := MeshInstance3D.new()
	rm.mesh = ring
	rm.material_override = mat("or")
	rm.scale = Vector3(1.0, 0.8, 1.0)
	add_child(rm)
	rm.global_position = C + Vector3(0, 0.1, 0)


# =================================================================== le Grand Cristal

func set_lit(on: bool, instant: bool = false) -> void:
	lit = on
	var target_e: float = 5.0 if on else 0.9
	var target_l: float = 2.6 if on else 0.7
	var lamp_e: float = 2.4 if on else 0.6
	if instant:
		crystal_mat.emission_energy_multiplier = target_e
		crystal_light.light_energy = target_l
		for m in lamp_mats:
			(m as StandardMaterial3D).emission_energy_multiplier = lamp_e
		for l in lamp_lights:
			(l as OmniLight3D).light_energy = 1.1 if on else 0.4
		if dome_mat != null:
			dome_mat.set_shader_parameter("glow", 1.0 if on else 0.35)
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(crystal_mat, "emission_energy_multiplier", target_e, 4.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(crystal_light, "light_energy", target_l, 4.0).set_trans(Tween.TRANS_SINE)
	for m2 in lamp_mats:
		tw.tween_property(m2, "emission_energy_multiplier", lamp_e, 3.0).set_delay(1.5)
	for l2 in lamp_lights:
		tw.tween_property(l2, "light_energy", 1.1 if on else 0.4, 3.0).set_delay(1.5)
	if dome_mat != null:
		tw.tween_method(func(v: float): dome_mat.set_shader_parameter("glow", v), 0.35, 1.0 if on else 0.35, 5.0)


func _process(delta: float) -> void:
	if crystal_mesh != null and crystal_mesh.is_visible_in_tree():
		crystal_mesh.rotation.y += delta * (0.6 if lit else 0.15)


# =================================================================== habitants

func _link(a: String, b: String) -> void:
	for pair in [[a, b], [b, a]]:
		if not graph.has(pair[0]):
			graph[pair[0]] = []
		if not (graph[pair[0]] as Array).has(pair[1]):
			graph[pair[0]].append(pair[1])


func _make_points() -> void:
	# L'anneau de la place (12 points), les ponts, le centre, et les lieux de chacun
	var ring: Dictionary = {}
	for k in range(12):
		ring["r%d" % k] = at(k * 30.0 + 15.0, 14.0)
	for k2 in range(12):
		_link("r%d" % k2, "r%d" % ((k2 + 1) % 12))
	var pts: Dictionary = ring.duplicate()
	for b in [[0.0, "pont_n", 0], [90.0, "pont_e", 3], [180.0, "pont_s", 6], [270.0, "pont_o", 9]]:
		pts[b[1]] = at(b[0], 10.6)
		_link(b[1], "r%d" % b[2])
		_link(b[1], "r%d" % ((int(b[2]) + 11) % 12))
	pts["palais_marches"] = points["palais_marches"]
	pts["palais_devant"] = points["palais_devant"]
	pts["palais"] = points["palais"]
	_link("palais_marches", "r0")
	_link("palais_marches", "r11")
	_link("palais_marches", "palais_devant")
	_link("palais_devant", "palais")
	pts["atelier_devant"] = points["atelier_devant"]
	pts["atelier"] = points["atelier"]
	_link("atelier_devant", "r2")
	_link("atelier_devant", "r3")
	_link("atelier_devant", "atelier")
	pts["archives_devant"] = points["archives_devant"]
	pts["archives"] = points["archives"]
	_link("archives_devant", "r8")
	_link("archives_devant", "r9")
	_link("archives_devant", "archives")
	pts["marche"] = points["marche"]
	_link("marche", "r4")
	_link("marche", "r5")
	pts["porte"] = points["porte"]
	pts["avenue"] = at(180.0, 30.0)
	_link("avenue", "r5")
	_link("avenue", "r6")
	_link("avenue", "porte")
	pts["canal"] = at(205.0, 11.0)
	_link("canal", "r6")
	_link("canal", "r7")
	points["graph_points"] = pts


func spawn_npcs() -> void:
	if not villagers.is_empty():
		return
	_make_points()
	var pts: Dictionary = points["graph_points"]
	var homes := {
		"palais": [["palais", "palais_devant", "palais_marches"], "palais"],
		"atelier": [["atelier", "atelier_devant", "r2", "r3"], "atelier"],
		"canal": [["canal", "r6", "r7", "pont_s", "r5", "r8", "marche"], "canal"],
		"archives": [["archives", "archives_devant", "r8", "r9"], "archives"],
		"porte": [["porte", "avenue"], "porte"],
		"marche": [["marche", "r4", "r5"], "marche"],
	}
	for entry in Habitants.NAMED:
		var h: Array = homes[str(entry["coin"])]
		var sub: Array = _sub(pts, h[0])
		_spawn(Habitants.complete(entry["data"]), sub[0], sub[1], str(h[1]))
	var ring_keys: Array = []
	for k in pts:
		if str(k).begins_with("r") or str(k).begins_with("pont"):
			ring_keys.append(k)
	var starts := ["r1", "r4", "r7", "r10", "pont_e", "pont_o"]
	for n in range(Habitants.PASSANTS.size()):
		var sub2: Array = _sub(pts, ring_keys)
		_spawn(Habitants.passant(n), sub2[0], sub2[1], str(starts[n % starts.size()]))
	_face("nerea", "palais", at(0.0, 10.0))
	_face("coralin", "atelier", at(90.0, 34.0))
	_face("abyssos", "archives", at(270.0, 34.0))
	_face("triton", "porte", at(0.0, 0.0))
	_face("maree", "marche", C)
	_face("ondine", "canal", C)


func _sub(pts: Dictionary, keys: Array) -> Array:
	var p: Dictionary = {}
	var g: Dictionary = {}
	for k in keys:
		p[k] = pts[k]
		g[k] = (graph.get(k, []) as Array).filter(func(x): return keys.has(x))
	return [p, g]


func _spawn(data: Dictionary, pts: Dictionary, g: Dictionary, start: String) -> void:
	var npc: Node3D = PnjScript.new()
	main.add_child(npc)
	npc.setup(main, data, pts, g, start)
	npc.sleep_far = SLEEP_FAR
	npc.idle_clock = _rng.randf_range(2.0, 12.0)
	var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	main.npcs_v31.append(npc)
	villagers.append(npc)
	by_id[str(data["id"])] = npc


func _face(id: String, point: String, target: Vector3) -> void:
	if by_id.has(id):
		by_id[id].face_at[point] = target


func quest_state(id: String) -> String:
	if not by_id.has(id):
		return ""
	return str(by_id[id].brain.memoire.get("quete", ""))


## Où se réveiller après un évanouissement près de la cité : devant le palais.
func respawn_point() -> Array:
	return [at(0.0, 14.0, 0.3), (C - at(0.0, 14.0)).normalized()]

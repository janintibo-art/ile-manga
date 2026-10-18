extends Node3D
## V46 : l'île des nains — la Montagne de Feu, à l'ouest, derrière les Récifs de Feu.
##  - Sans la carte d'Églantine, une fumée de cendres et des récifs noirs entourent l'île :
##    le bateau tourne en rond et ressort. Avec la carte, la passe apparaît.
##  - Un volcan fume au centre (lac de lave dans le cratère, braises, colonne de fumée).
##  - Sur son flanc est : la terrasse de Forgefer, la cité naine. Une porte monumentale
##    taillée dans la montagne, gardée par deux statues de rois nains, des forges qui
##    fument, des enclumes, des rails de mine, des braseros. (Les nains ouvriront leur
##    porte au prochain chapitre.)

const IleScript = preload("res://scripts/ile_nains_v46.gd")
const Habitants = preload("res://scripts/pnj/nains_habitants_v47.gd")
const PnjScript = preload("res://scripts/pnj/pnj_v31.gd")
const ForgeferScript = preload("res://scripts/forgefer_v47.gd")
const FauneScript = preload("res://scripts/faune_nains_v47.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const ASH_R: float = 185.0

var main: Node
var ile: Node3D
var pc: bool = true
var state := {"visite": false, "porte": false, "ouverte": false, "ville": false}
var gate_front: Vector3
var _fog: FogVolume
var _reefs: Node3D
var _clock: float = 0.0
var _mist_clock: float = 0.0
var _mats: Dictionary = {}
var _body: StaticBody3D
var _lava_mat: ShaderMaterial
var _smokes: Array = []
var forge_root: Node3D                  # V47 : la terrasse de Forgefer (repère local, +Z vers la mer)
var forges: Array = []
var mine_node: Node3D
var doors: Array = []
var door_dark: MeshInstance3D
var door_light: OmniLight3D
var habitants: Array = []
var by_id: Dictionary = {}
var forgefer: Node3D                    # V47 : la cité sous la montagne (forgefer_v47.gd)
var faune: Node3D                       # V47 : chèvres, salamandres, corbeaux, crabes de lave
var fumaroles: Array = []               # V47 : positions des fumerolles du sentier (monde)
var perches: Array = []                 # V47 : rochers où se posent les corbeaux (monde)
var veins: Array = []                   # V47 : rochers de minerai (monde)
var _hostiles: Array = []
var _lava_clock: float = 0.0
var _pending_fires: Array = []         # flammes créées quand donjon_v35 (qui sait les faire) existe


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_body = StaticBody3D.new()
	_body.name = "Nains_collision_v46"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)


func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_nains_v46"
	add_child(ile)
	ile.build(pc)
	_build_volcano()
	_build_landscape()
	_build_forgefer()
	_build_trail_decor()
	_build_reefs()
	_build_ash()


## Appelé quand le temple (donjon_v35, qui gère les interactions E) existe.
func build_quest() -> void:
	main.donjon_v35._interactions.append({"id": "porte_forgefer", "pos": gate_front, "radius": 2.6,
		"text": "E : frapper à la grande porte", "vr": "Gâchette : frapper à la porte", "call": _knock,
		"when": func(): return not bool(state["ouverte"])})
	main.donjon_v35._interactions.append({"id": "entrer_forgefer", "pos": gate_front, "radius": 2.6,
		"text": "E : entrer dans Forgefer", "vr": "Gâchette : entrer dans Forgefer", "call": enter_city,
		"when": func(): return bool(state["ouverte"])})
	# V47 : les nains de la terrasse, la cité sous la montagne, la faune
	_spawn_dwarves()
	forgefer = ForgeferScript.new()
	forgefer.name = "Forgefer_v47"
	add_child(forgefer)
	forgefer.setup(self)
	forgefer.build()
	faune = FauneScript.new()
	faune.name = "Faune_nains_v47"
	add_child(faune)
	faune.setup(self)
	faune.build()
	for fr in _pending_fires:
		main.donjon_v35._fire(fr[0], fr[1], float(fr[2]), int(fr[3]))
	_pending_fires.clear()
	apply_state()


func dock() -> Array:
	return [ile.dock_start, ile.dock_end]


func has_map() -> bool:
	return main.inventory_v28 != null and main.inventory_v28.count("carte_naine") > 0


# =================================================================== matériaux et formes

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.85
	match key:
		"pierre":
			m.albedo_texture = load("res://assets/textures/temple/temple_wall.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/temple/temple_wall_n.png")
			m.normal_scale = 1.4
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.22, 0.22, 0.22)
			m.albedo_color = Color(0.62, 0.58, 0.56)
		"dalle":
			m.albedo_texture = load("res://assets/textures/temple/temple_floor.png")
			m.normal_enabled = true
			m.normal_texture = load("res://assets/textures/temple/temple_floor_n.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.18, 0.18, 0.18)
			m.albedo_color = Color(0.55, 0.52, 0.5)
		"fer":
			m.albedo_color = Color(0.28, 0.27, 0.28)
			m.metallic = 0.85
			m.roughness = 0.45
		"bronze":
			m.albedo_color = Color(0.62, 0.42, 0.22)
			m.metallic = 0.85
			m.roughness = 0.35
		"or":
			m.albedo_color = Color(0.95, 0.75, 0.35)
			m.metallic = 0.9
			m.roughness = 0.25
		"bois":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.9, 0.9, 0.9)
			m.albedo_color = Color(0.55, 0.42, 0.3)
		"charbon":
			m.albedo_color = Color(0.08, 0.07, 0.07)
			m.roughness = 0.95
		"braise":
			m.albedo_color = Color(1.0, 0.45, 0.1)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.4, 0.08)
			m.emission_energy_multiplier = 3.0
		"rune":
			m.albedo_color = Color(1.0, 0.55, 0.2)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.5, 0.15)
			m.emission_energy_multiplier = 2.2
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


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r_top: float, r_bot: float, h: float, segs: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	return c


func _sphere(r: float, segs: int = 14) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 4)
	return s


## Boîte visible et solide (repère local de « parent »).
func _solid(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := _mesh(parent, _box_mesh(size), mat, pos, rot)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	_body.add_child(cs)
	cs.global_transform = mi.global_transform
	return mi


func _light(parent: Node3D, pos: Vector3, c: Color, energy: float, reach: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = reach
	l.omni_attenuation = 1.2
	l.position = pos
	parent.add_child(l)
	return l


func _ground(x: float, z: float) -> float:
	return ile.height(x, z)


## Fumée grise qui monte (cheminées, cratère).
func _smoke(parent: Node3D, pos: Vector3, size: float, amount: int, spread: float, rise: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = clampf(size * 1.3, 4.0, 13.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread
	p.direction = Vector3.UP
	p.spread = 14.0
	p.gravity = Vector3(0.6, 0.1, 0.25)
	p.initial_velocity_min = rise * 1.4
	p.initial_velocity_max = rise * 2.4
	p.damping_min = 0.05
	p.damping_max = 0.15
	p.scale_amount_min = 0.9
	p.scale_amount_max = 1.5
	p.angle_min = -180.0
	p.angle_max = 180.0
	var curve := Curve.new()
	curve.max_value = 3.0
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(1.0, 2.2))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.3, 0.28, 0.27, 0.6))
	grad.set_color(1, Color(0.5, 0.48, 0.47, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.position = pos
	parent.add_child(p)
	_smokes.append(p)
	return p


func _embers(parent: Node3D, pos: Vector3, extents: Vector3, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3.UP
	p.spread = 25.0
	p.gravity = Vector3(0, 1.5, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.55, 0.15, 0.9)
	m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.position = pos
	parent.add_child(p)


# =================================================================== le volcan

func _build_volcano() -> void:
	var top: Vector3 = ile.peak_world()
	# Lac de lave : un disque qui bouillonne (couleurs qui coulent, croûte sombre)
	_lava_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 a = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(a), h(a + vec2(1, 0)), f.x), mix(h(a + vec2(0, 1)), h(a + vec2(1, 1)), f.x), f.y); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz * 0.35;
	float t = TIME * 0.12;
	float a = n(p + vec2(t, -t * 0.7)) * 0.6 + n(p * 2.3 - vec2(t * 1.3, t)) * 0.4;
	float crust = smoothstep(0.45, 0.62, a);
	vec3 hot = mix(vec3(1.0, 0.85, 0.3), vec3(1.0, 0.3, 0.05), a);
	ALBEDO = mix(hot * 0.3, vec3(0.06, 0.04, 0.04), crust);
	EMISSION = hot * (1.0 - crust) * 3.5;
	ROUGHNESS = mix(0.3, 0.9, crust);
}
"""
	_lava_mat.shader = sh
	var lava := MeshInstance3D.new()
	lava.name = "Lac_de_lave"
	var pm := CylinderMesh.new()
	pm.top_radius = ile.CRATER_R * 0.86
	pm.bottom_radius = ile.CRATER_R * 0.86
	pm.height = 0.2
	pm.radial_segments = 40
	lava.mesh = pm
	lava.material_override = _lava_mat
	add_child(lava)
	lava.global_position = top + Vector3.UP * 0.7
	_light(self, Vector3.ZERO, Color(1.0, 0.45, 0.15), 4.0, 45.0).global_position = top + Vector3.UP * 6.0
	_smoke(self, top + Vector3.UP * 4.0, 9.0 if pc else 6.0, 60 if pc else 30, 6.0, 1.4).global_position = top + Vector3.UP * 4.0
	_embers(self, top + Vector3.UP * 2.0, Vector3(8, 1, 8), 70)


# =================================================================== le paysage

func _build_landscape() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4640
	var C: Vector3 = ile.CENTER
	var rock_mat: Material = Rocks.material(Color(0.42, 0.4, 0.42), 0.08, 0.22)
	var gate_dir := Vector2(cos(ile.BAY_ANGLE), sin(ile.BAY_ANGLE))
	# Rochers et blocs de lave refroidie
	for k in range(70):
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(25.0, 100.0)
		var lx: float = cos(a) * r
		var lz: float = sin(a) * r
		if _near_settlement(C.x + lx, C.z + lz, 24.0) or _near_road(C.x + lx, C.z + lz, 5.0) or _near_trail(C.x + lx, C.z + lz, 6.0):
			continue
		var h: float = _ground(C.x + lx, C.z + lz)
		if h < 0.4:
			continue
		var sz: float = rng.randf_range(0.8, 3.2)
		var mi := _mesh(self, Rocks.shape(4650 + k % 12, Vector3(sz, sz * rng.randf_range(0.6, 1.1), sz * 1.1), 0.8, 0.2), rock_mat, Vector3(C.x + lx, h + sz * 0.15, C.z + lz), Vector3(0, rng.randf() * TAU, 0))
		mi.name = "Roche_%d" % k
	# Orgues de basalte : colonnes hexagonales serrées
	for g in range(7):
		var a2: float = rng.randf() * TAU
		var r2: float = rng.randf_range(55.0, 90.0)
		var gx: float = C.x + cos(a2) * r2
		var gz: float = C.z + sin(a2) * r2
		if _near_settlement(gx, gz, 26.0) or _near_road(gx, gz, 8.0) or _near_trail(gx, gz, 8.0):
			continue
		for c in range(14):
			var ox: float = rng.randf_range(-2.5, 2.5)
			var oz: float = rng.randf_range(-2.5, 2.5)
			var hh: float = rng.randf_range(1.0, 5.0)
			var y: float = _ground(gx + ox, gz + oz)
			if y < 0.3:
				continue
			_mesh(self, _cyl(0.42, 0.45, hh, 6), rock_mat, Vector3(gx + ox, y + hh * 0.5 - 0.3, gz + oz), Vector3(0, rng.randf() * 0.5, 0))
	# Arbres calcinés
	var char_m: Material = _mat("charbon")
	for k in range(26):
		var a3: float = rng.randf() * TAU
		var r3: float = rng.randf_range(30.0, 95.0)
		var tx: float = C.x + cos(a3) * r3
		var tz: float = C.z + sin(a3) * r3
		if _near_settlement(tx, tz, 22.0) or _near_road(tx, tz, 4.0) or _near_trail(tx, tz, 4.5):
			continue
		var y2: float = _ground(tx, tz)
		if y2 < 0.6:
			continue
		var th: float = rng.randf_range(3.0, 6.5)
		var lean := Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
		var tree := Node3D.new()
		add_child(tree)
		tree.position = Vector3(tx, y2, tz)
		tree.rotation = lean
		_mesh(tree, _cyl(0.1, 0.24, th, 8), char_m, Vector3(0, th * 0.5, 0))
		for b in range(3):
			var ba: float = rng.randf() * TAU
			var bh: float = th * rng.randf_range(0.5, 0.9)
			_mesh(tree, _cyl(0.03, 0.08, th * 0.4, 6), char_m, Vector3(cos(ba) * 0.3, bh, sin(ba) * 0.3), Vector3(cos(ba) * 0.9, 0, -sin(ba) * 0.9).rotated(Vector3.UP, 0.0))
	# Fumerolles : petites fumées blanches qui sortent du sol
	for k in range(6):
		var a4: float = rng.randf() * TAU
		var r4: float = rng.randf_range(25.0, 60.0)
		var fx: float = C.x + ile.PEAK.x + cos(a4) * r4
		var fz: float = C.z + ile.PEAK.y + sin(a4) * r4
		if _near_settlement(fx, fz, 20.0):
			continue
		var sm := _smoke(self, Vector3(fx, _ground(fx, fz) + 0.2, fz), 2.0, 14, 0.4, 0.5)
		sm.global_position = Vector3(fx, _ground(fx, fz) + 0.2, fz)
	gate_dir = gate_dir


func _near_settlement(x: float, z: float, r: float) -> bool:
	return Vector2(x - ile.terrace.x, z - ile.terrace.z).length() < r + ile.TERRACE_SIZE


func _near_road(x: float, z: float, r: float) -> bool:
	var a := Vector2(ile.dock_start.x, ile.dock_start.z)
	var b := Vector2(ile.terrace.x, ile.terrace.z)
	var p := Vector2(x, z)
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t) < r


# =================================================================== Forgefer, la cité naine

func _build_forgefer() -> void:
	var T: Vector3 = ile.terrace
	var to_sea := Vector3(cos(ile.BAY_ANGLE), 0, sin(ile.BAY_ANGLE))
	var side := Vector3(-to_sea.z, 0, to_sea.x)
	var root := Node3D.new()
	root.name = "Forgefer"
	add_child(root)
	root.global_position = T
	root.rotation.y = atan2(to_sea.x, to_sea.z)        # +Z local vers la mer
	forge_root = root
	var stone: Material = _mat("pierre")
	# Dallage de la terrasse
	_mesh(root, _cyl(ile.TERRACE_SIZE - 1.0, ile.TERRACE_SIZE - 0.6, 0.3, 40), _mat("dalle"), Vector3(0, 0.0, 0))
	# La porte monumentale, adossée à la montagne (au fond de la terrasse, -Z local)
	var gz: float = -ile.TERRACE_SIZE + 2.5
	var facade := Node3D.new()
	facade.name = "Grande_porte"
	root.add_child(facade)
	facade.position = Vector3(0, 0, gz)
	_solid(facade, Vector3(22.0, 18.0, 3.0), Vector3(0, 9.0, -1.8), stone)
	_solid(facade, Vector3(26.0, 3.0, 4.5), Vector3(0, 18.5, -1.4), stone)
	# La façade est taillée dans une falaise de basalte : de gros blocs l'enchâssent dans la montagne
	var cliff: Material = Rocks.material(Color(0.22, 0.2, 0.21), 0.0, 0.25)
	for sx in [-1.0, 1.0]:
		_mesh(facade, Rocks.shape(4710 + int(sx), Vector3(12.0, 24.0, 14.0), 0.7, 0.25), cliff, Vector3(sx * 16.5, 8.0, -6.0), Vector3(0, sx * 0.4, 0))
		_mesh(facade, Rocks.shape(4713 + int(sx), Vector3(9.0, 14.0, 10.0), 0.7, 0.25), cliff, Vector3(sx * 23.0, 3.0, -2.0), Vector3(0, sx * 1.1, 0))
	_mesh(facade, Rocks.shape(4716, Vector3(34.0, 14.0, 16.0), 0.7, 0.25), cliff, Vector3(0, 24.0, -8.0))
	# Encadrement en arc, marches, linteau gravé de runes
	for k in range(3):
		_solid(facade, Vector3(10.0 - k * 1.2, 0.35, 1.2), Vector3(0, 0.17 + k * 0.35, 0.9 - k * 0.6), _mat("dalle"))
	for sx in [-1.0, 1.0]:
		_solid(facade, Vector3(1.6, 10.0, 1.6), Vector3(sx * 4.2, 5.0, -0.1), stone)
		_mesh(facade, _box_mesh(Vector3(0.12, 7.0, 0.05)), _mat("rune"), Vector3(sx * 4.2, 5.0, 0.72))
	_solid(facade, Vector3(10.0, 1.6, 1.6), Vector3(0, 10.6, -0.1), stone)
	for k in range(7):
		_mesh(facade, _box_mesh(Vector3(0.6, 0.6, 0.05)), _mat("rune"), Vector3(-3.0 + k, 10.6, 0.72), Vector3(0, 0, 0.785 if k % 2 == 0 else 0.0))
	# Les deux battants de la porte (fer et bronze, rivets)
	doors.clear()
	for sx in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(sx * 3.4, 0, -0.4)
		leaf.set_meta("cote", sx)
		doors.append(leaf)
		facade.add_child(leaf)
		_mesh(leaf, _box_mesh(Vector3(3.4, 9.8, 0.4)), _mat("fer"), Vector3(-sx * 1.7, 4.9, 0))
		for row in range(5):
			_mesh(leaf, _box_mesh(Vector3(3.3, 0.18, 0.08)), _mat("bronze"), Vector3(-sx * 1.7, 1.0 + row * 2.0, 0.22))
			for c in range(5):
				_mesh(leaf, _sphere(0.07, 6), _mat("bronze"), Vector3(-sx * (0.3 + c * 0.7), 1.0 + row * 2.0, 0.28))
		_mesh(leaf, _cyl(0.35, 0.35, 0.1, 16), _mat("or"), Vector3(-sx * 0.55, 5.0, 0.26), Vector3(PI * 0.5, 0, 0))
	_solid(facade, Vector3(6.8, 9.8, 0.4), Vector3(0, 4.9, -0.4), _mat("fer")).visible = false
	# V47 : derrière les battants ouverts, l'ombre du couloir et la lueur des forges
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.03, 0.02, 0.02)
	dm.emission_enabled = true
	dm.emission = Color(0.35, 0.12, 0.03)
	dm.emission_energy_multiplier = 0.6
	door_dark = _mesh(facade, _box_mesh(Vector3(6.8, 9.8, 0.05)), dm, Vector3(0, 4.9, -0.28))
	door_dark.visible = false
	door_light = _light(facade, Vector3(0, 2.5, 1.2), Color(1.0, 0.55, 0.25), 2.5, 12.0)
	door_light.visible = false
	# Les deux statues de rois nains, haches posées devant eux
	for sx in [-1.0, 1.0]:
		_statue(facade, Vector3(sx * 8.0, 0, 0.8))
	gate_front = facade.to_global(Vector3(0, 0, 3.2))
	# Braseros le long de l'allée
	for k in range(4):
		for sx in [-1.0, 1.0]:
			var bp := Vector3(sx * 5.5, 0, gz + 5.0 + k * 5.5)
			_brazier(root, bp)
	# Deux forges : murets de pierre, foyer rougeoyant, cheminée qui fume, enclume
	forges.clear()
	for sx in [-1.0, 1.0]:
		forges.append(_forge(root, Vector3(sx * 11.0, 0, -3.0), sx))
	# Rails de mine et wagonnet vers une galerie, sur le côté
	mine_node = _mine(root, Vector3(-13.0, 0, 7.0))
	# V47 : la cuisine de Dagna et l'enclos des chèvres de Hilda
	_kitchen(root, Vector3(7.0, 0, 9.5))
	_pen(root, Vector3(12.5, 0, 2.5))
	# Tonneaux et caisses
	var rng := RandomNumberGenerator.new()
	rng.seed = 4660
	for k in range(10):
		var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(4, 13))
		if absf(p.x) < 4.0 or p.distance_to(Vector3(7.0, 0, 9.5)) < 3.5 or p.distance_to(Vector3(12.5, 0, 2.5)) < 4.5:
			continue
		if k % 2 == 0:
			_mesh(root, _cyl(0.45, 0.45, 1.1, 14), _mat("bois"), p + Vector3.UP * 0.55)
			for y in [0.2, 0.9]:
				_mesh(root, _cyl(0.47, 0.47, 0.06, 14), _mat("fer"), p + Vector3.UP * y)
		else:
			_mesh(root, _box_mesh(Vector3(0.9, 0.9, 0.9)), _mat("bois"), p + Vector3.UP * 0.45, Vector3(0, rng.randf() * 1.5, 0))
	# Un sentier de dalles et des lanternes de fer du ponton à la terrasse
	var a := Vector3(ile.dock_start.x, 0, ile.dock_start.z)
	var b: Vector3 = Vector3(T.x, 0, T.z) + to_sea * (ile.TERRACE_SIZE - 1.0)
	var length: float = a.distance_to(b)
	var dir: Vector3 = (b - a).normalized()
	var pside := Vector3(-dir.z, 0, dir.x)
	var stones := MultiMesh.new()
	stones.transform_format = MultiMesh.TRANSFORM_3D
	stones.mesh = Rocks.shape(4670, Vector3(1.0, 0.2, 0.8), 0.5, 0.05)
	var n: int = int(length / 1.1)
	stones.instance_count = n
	for k in range(n):
		var q: Vector3 = a + dir * (0.5 + k * 1.1) + pside * rng.randf_range(-0.4, 0.4)
		q.y = _ground(q.x, q.z) + 0.03
		stones.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), q))
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = stones
	smi.material_override = _mat("dalle")
	add_child(smi)
	for k in range(1, int(length / 12.0) + 1):
		var sgn: float = 1.0 if k % 2 == 0 else -1.0
		var lp: Vector3 = a + dir * (k * 12.0) + pside * sgn * 1.8
		lp.y = _ground(lp.x, lp.z)
		_mesh(self, _cyl(0.07, 0.09, 2.6, 8), _mat("fer"), lp + Vector3.UP * 1.3)
		_mesh(self, _box_mesh(Vector3(0.3, 0.38, 0.3)), _mat("fer"), lp + Vector3.UP * 2.75)
		_mesh(self, _sphere(0.11, 8), _mat("braise"), lp + Vector3.UP * 2.75)
		_light(self, Vector3.ZERO, Color(1.0, 0.6, 0.3), 1.1, 9.0).global_position = lp + Vector3.UP * 2.7


func _statue(parent: Node3D, at: Vector3) -> void:
	var s := Node3D.new()
	parent.add_child(s)
	s.position = at
	var st: Material = _mat("pierre")
	_solid(s, Vector3(3.2, 1.6, 3.2), Vector3(0, 0.8, 0), st)
	_mesh(s, _box_mesh(Vector3(0.9, 2.2, 1.0)), st, Vector3(-0.6, 2.7, 0))
	_mesh(s, _box_mesh(Vector3(0.9, 2.2, 1.0)), st, Vector3(0.6, 2.7, 0))
	_mesh(s, _cyl(1.5, 1.7, 3.6, 10), st, Vector3(0, 5.4, 0))
	_mesh(s, _cyl(0.6, 0.6, 0.5, 10), _mat("bronze"), Vector3(0, 4.0, 0))
	for sx in [-1.0, 1.0]:
		_mesh(s, _cyl(0.4, 0.45, 2.6, 8), st, Vector3(sx * 1.6, 5.6, 0.4), Vector3(0.5, 0, sx * 0.25))
	_mesh(s, _sphere(0.95, 12), st, Vector3(0, 8.1, 0), Vector3.ZERO, Vector3(1.0, 1.05, 1.0))
	_mesh(s, _cyl(0.0, 1.1, 2.6, 10), st, Vector3(0, 6.6, 0.7), Vector3(-0.15, 0, 0))
	_mesh(s, _cyl(1.05, 1.15, 0.35, 12), _mat("bronze"), Vector3(0, 8.7, 0))
	_mesh(s, _cyl(0.0, 1.05, 1.0, 12), _mat("bronze"), Vector3(0, 9.3, 0))
	for sx in [-1.0, 1.0]:
		_mesh(s, _sphere(0.12, 6), _mat("rune"), Vector3(sx * 0.35, 8.25, 0.85))
	# La hache, tête posée au sol devant le roi
	_mesh(s, _cyl(0.12, 0.12, 4.8, 8), _mat("bois"), Vector3(0, 3.4, 1.9))
	_mesh(s, _box_mesh(Vector3(2.0, 1.4, 0.2)), _mat("fer"), Vector3(0, 1.3, 1.9))


func _brazier(parent: Node3D, at: Vector3) -> void:
	_mesh(parent, _cyl(0.15, 0.25, 1.1, 8), _mat("fer"), at + Vector3.UP * 0.55)
	_mesh(parent, _cyl(0.5, 0.3, 0.4, 12), _mat("fer"), at + Vector3.UP * 1.25)
	_mesh(parent, _sphere(0.32, 10), _mat("braise"), at + Vector3.UP * 1.38, Vector3.ZERO, Vector3(1, 0.4, 1))
	_pending_fires.append([parent, at + Vector3.UP * 1.5, 0.22, 20])
	_light(parent, at + Vector3.UP * 1.9, Color(1.0, 0.55, 0.25), 1.6, 9.0)


func _forge(parent: Node3D, at: Vector3, sx: float) -> Node3D:
	var f := Node3D.new()
	parent.add_child(f)
	f.position = at
	f.rotation.y = -sx * 0.5
	var st: Material = _mat("pierre")
	_solid(f, Vector3(5.0, 2.4, 0.6), Vector3(0, 1.2, -2.2), st)
	_solid(f, Vector3(0.6, 2.4, 4.0), Vector3(-2.2, 1.2, -0.4), st)
	_solid(f, Vector3(0.6, 2.4, 4.0), Vector3(2.2, 1.2, -0.4), st)
	_mesh(f, _box_mesh(Vector3(5.6, 0.3, 4.8)), _mat("bois"), Vector3(0, 3.6, -0.4), Vector3(0.12, 0, 0))
	for px in [-2.4, 2.4]:
		_mesh(f, _cyl(0.12, 0.12, 3.4, 8), _mat("bois"), Vector3(px, 1.7, 1.8))
	# Le foyer et sa cheminée
	_solid(f, Vector3(2.0, 1.1, 1.4), Vector3(0, 0.55, -1.2), st)
	_mesh(f, _box_mesh(Vector3(1.4, 0.15, 0.9)), _mat("braise"), Vector3(0, 1.12, -1.2))
	_pending_fires.append([f, Vector3(0, 1.25, -1.2), 0.35, 26])
	_mesh(f, _cyl(0.55, 0.75, 6.0, 10), st, Vector3(0, 4.2, -1.6))
	var sm := _smoke(f, Vector3(0, 7.4, -1.6), 2.6, 24, 0.4, 1.1)
	sm.position = Vector3(0, 7.4, -1.6)
	_light(f, Vector3(0, 1.8, -0.4), Color(1.0, 0.5, 0.2), 2.4, 10.0)
	# L'enclume, le marteau, l'auge
	_mesh(f, _box_mesh(Vector3(0.5, 0.6, 0.5)), _mat("fer"), Vector3(0, 0.3, 0.8))
	_mesh(f, _box_mesh(Vector3(1.0, 0.28, 0.42)), _mat("fer"), Vector3(0, 0.74, 0.8))
	_mesh(f, _cyl(0.0, 0.14, 0.4, 8), _mat("fer"), Vector3(0.62, 0.74, 0.8), Vector3(0, 0, -PI * 0.5))
	_mesh(f, _cyl(0.025, 0.025, 0.55, 6), _mat("bois"), Vector3(-0.25, 0.92, 0.95), Vector3(0, 0, 1.3))
	_mesh(f, _box_mesh(Vector3(0.18, 0.14, 0.14)), _mat("fer"), Vector3(-0.47, 0.98, 0.95))
	_mesh(f, _box_mesh(Vector3(1.2, 0.5, 0.6)), _mat("bois"), Vector3(1.4, 0.25, 0.9))
	_embers(f, Vector3(0, 1.3, -1.2), Vector3(0.5, 0.1, 0.3), 16)
	return f


func _mine(parent: Node3D, at: Vector3) -> Node3D:
	var m := Node3D.new()
	parent.add_child(m)
	m.position = at
	m.rotation.y = 0.7
	for k in range(12):
		_mesh(m, _box_mesh(Vector3(1.4, 0.1, 0.22)), _mat("bois"), Vector3(0, 0.05, -k * 0.8))
	for sx in [-0.5, 0.5]:
		_mesh(m, _box_mesh(Vector3(0.07, 0.1, 9.6)), _mat("fer"), Vector3(sx, 0.14, -4.4))
	var cart := Node3D.new()
	m.add_child(cart)
	cart.position = Vector3(0, 0.25, -2.0)
	_mesh(cart, _box_mesh(Vector3(1.1, 0.7, 1.5)), _mat("fer"), Vector3(0, 0.55, 0))
	_mesh(cart, _box_mesh(Vector3(0.95, 0.25, 1.35)), _mat("charbon"), Vector3(0, 0.95, 0))
	for wx in [-0.55, 0.55]:
		for wz in [-0.5, 0.5]:
			_mesh(cart, _cyl(0.2, 0.2, 0.08, 12), _mat("fer"), Vector3(wx, 0.2, wz), Vector3(0, 0, PI * 0.5))
	# Entrée de galerie étayée
	var st: Material = _mat("pierre")
	_solid(m, Vector3(0.5, 3.0, 0.5), Vector3(-1.3, 1.5, -9.4), _mat("bois"))
	_solid(m, Vector3(0.5, 3.0, 0.5), Vector3(1.3, 1.5, -9.4), _mat("bois"))
	_mesh(m, _box_mesh(Vector3(3.3, 0.45, 0.5)), _mat("bois"), Vector3(0, 3.1, -9.4))
	_mesh(m, _box_mesh(Vector3(2.4, 2.8, 0.2)), _mat("charbon"), Vector3(0, 1.4, -9.8))
	_solid(m, Vector3(7.0, 6.0, 3.0), Vector3(0, 3.0, -11.4), st)
	return m


func _knock() -> void:
	if not bool(state["porte"]):
		state["porte"] = true
		main.donjon_v35._say("BOUM. BOUM. BOUM. Tes coups résonnent dans la montagne… Une grosse voix derrière toi : « Inutile de frapper, le grand. Personne n'entre à Forgefer sans y être invité. » C'est Bramm, le garde. Parle-lui.", 8.0)
	else:
		main.donjon_v35._say("La Grande Porte ne bouge pas. Bramm, le garde, te regarde de travers. C'est lui qu'il faut convaincre.", 4.5)


## V47 : la Grande Porte s'ouvre (quête de Bramm terminée).
func open_gate(instant: bool) -> void:
	state["ouverte"] = true
	for d in doors:
		var leaf: Node3D = d
		var target: float = float(leaf.get_meta("cote", 1.0)) * 1.45
		if instant:
			leaf.rotation.y = target
		else:
			var tw := create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(leaf, "rotation:y", target, 3.0).set_trans(Tween.TRANS_SINE)
	door_dark.visible = true
	door_light.visible = true
	if not instant and main.get("sfx_v50") != null:
		main.sfx_v50.play("grille", gate_front + Vector3.UP * 3.0, 4.0)
		main.jingle("decouverte")
	if not instant:
		main.donjon_v35._say("BRAMM : « OUVREZ LA GRANDE PORTE ! » Un grondement, des chaînes qui grincent… et les deux battants de fer s'ouvrent lentement sur la lueur des forges de Forgefer.", 7.0)


func _close_gate() -> void:
	for d in doors:
		(d as Node3D).rotation.y = 0.0
	door_dark.visible = false
	door_light.visible = false


func enter_city() -> void:
	if forgefer == null:
		return
	await main.donjon_v35._travel(forgefer.entry_point(), forgefer.entry_facing())
	if not bool(state["ville"]):
		state["ville"] = true
		main.donjon_v35._say("Forgefer. Une halle immense taillée dans la montagne : des piliers gravés de runes, des rigoles de lave qui éclairent tout d'orange, l'odeur du charbon et de la bière… Au fond, sur son trône, le roi Thorgal.", 8.0)


func apply_state() -> void:
	if doors.is_empty():
		return
	if bool(state["ouverte"]):
		open_gate(true)
	else:
		_close_gate()


# =================================================================== les Récifs de Feu et la cendre

func _build_reefs() -> void:
	_reefs = Node3D.new()
	_reefs.name = "Recifs_de_feu"
	add_child(_reefs)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4680
	var mat: Material = Rocks.material(Color(0.25, 0.23, 0.25), 0.0, 0.25)
	var C: Vector3 = ile.CENTER
	for k in range(64):
		var a: float = TAU * k / 64.0 + rng.randf_range(-0.03, 0.03)
		# La passe : un trou dans les récifs, face au village (à l'est)
		if absf(wrapf(a - ile.BAY_ANGLE, -PI, PI)) < 0.16:
			continue
		var r: float = 150.0 + rng.randf_range(-8.0, 8.0)
		var sz: float = rng.randf_range(2.0, 5.5)
		_mesh(_reefs, Rocks.shape(4690 + k % 10, Vector3(sz, sz * rng.randf_range(0.8, 1.8), sz), 0.6, 0.3), mat, Vector3(C.x + cos(a) * r, -0.8 + sz * 0.3, C.z + sin(a) * r), Vector3(0, rng.randf() * TAU, 0))
		if k % 5 == 0:
			_embers(_reefs, Vector3(C.x + cos(a) * r, 0.3, C.z + sin(a) * r), Vector3(1, 0.2, 1), 6)


func _build_ash() -> void:
	if not pc:
		return
	_fog = FogVolume.new()
	_fog.name = "Cendres_des_recifs"
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(ASH_R * 2.1, 110.0, ASH_R * 2.1)
	var m := FogMaterial.new()
	m.density = 0.11
	m.albedo = Color(0.35, 0.32, 0.3)
	m.edge_fade = 0.25
	_fog.material = m
	add_child(_fog)
	_fog.global_position = ile.CENTER + Vector3.UP * 15.0


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not main.game_started or ile == null:
		return
	_clock += delta
	_mist_clock = maxf(_mist_clock - delta, 0.0)
	var ok: bool = has_map()
	if _fog != null:
		_fog.visible = not ok
	var boat: Node = main.boat_v29
	if boat != null and boat.driving and not ok:
		var h: Vector3 = boat.hull.global_position
		var off := Vector2(h.x - ile.CENTER.x, h.z - ile.CENTER.z)
		if off.length() < ASH_R:
			var out: Vector2 = off.normalized()
			boat.hull.global_position = Vector3(ile.CENTER.x + out.x * (ASH_R + 0.5), h.y, ile.CENTER.z + out.y * (ASH_R + 0.5))
			boat.yaw = atan2(-out.x, -out.y) + PI
			boat.speed = 1.5
			if _mist_clock <= 0.0:
				_mist_clock = 5.0
				main.donjon_v35._say("Une fumée âcre, des récifs noirs qui fument dans les vagues… Impossible de trouver un passage. Sans carte, mieux vaut faire demi-tour.", 5.0)
	var p: Vector3 = main._player_pos_v27()
	_tick_v47(delta, p)
	if not bool(state["visite"]) and Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() < 115.0 and ile.height(p.x, p.z) > -0.2 and (boat == null or not boat.driving):
		state["visite"] = true
		main.donjon_v35._say("La Montagne de Feu. Le sable est noir, l'air sent le soufre et le charbon… Au-dessus de la plage, des braseros et des fumées de forge : Forgefer, la cité des nains.", 7.0)


func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"visite": false, "porte": false, "ouverte": false, "ville": false}
	for k in state:
		if d.has(k):
			state[k] = bool(d[k])
	_despawn_hostiles()
	apply_state()


# =================================================================== V47 : la vie de l'île

## Les cinq nains de la terrasse et quatre nains de passage.
func _spawn_dwarves() -> void:
	var pts: Dictionary = _terrace_points()
	var homes := {
		"porte": [["porte_g", "porte_d", "allee"], "porte_g"],
		"forge": [["forge_d", "forge_d2", "allee"], "forge_d"],
		"cuisine": [["cuisine", "cuisine2", "allee2"], "cuisine"],
		"mine": [["mine", "mine2", "allee2"], "mine"],
		"chevres": [["chevres", "chevres2", "bord"], "chevres"],
	}
	for entry in Habitants.DEHORS:
		var h: Array = homes[str(entry["coin"])]
		var sub: Dictionary = {}
		for k in h[0]:
			sub[k] = pts[k]
		_spawn_one(Habitants.complete(entry["data"]), sub, str(h[1]))
	var starts: Array = ["allee", "allee2", "bord", "forge_g"]
	for n in range(4):
		_spawn_one(Habitants.passant(n), pts.duplicate(), str(starts[n]))
	# Où regarder à leur poste
	_face_at("bramm", "porte_g", forge_root.to_global(Vector3(-3.2, 0, 10.0)))
	_face_at("bramm", "porte_d", forge_root.to_global(Vector3(3.2, 0, 10.0)))
	_face_at("borin", "forge_d", (forges[1] as Node3D).to_global(Vector3(0, 0, 0.8)))
	_face_at("dagna", "cuisine", forge_root.to_global(Vector3(7.0, 0, 9.5)))
	_face_at("grimli", "mine", mine_node.to_global(Vector3(0, 0, -6.0)))
	_face_at("hilda", "chevres", forge_root.to_global(Vector3(12.5, 0, 2.5)))


func _spawn_one(data: Dictionary, pts: Dictionary, start: String) -> Node3D:
	var graph := {}
	for k in pts:
		graph[k] = pts.keys().filter(func(x): return x != k)
	var npc: Node3D = PnjScript.new()
	main.add_child(npc)
	npc.setup(main, data, pts, graph, start)
	npc.sleep_far = 70.0
	npc.idle_clock = randf_range(2.0, 12.0)
	var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		npc.load_data(saved)
	main.npcs_v31.append(npc)
	habitants.append(npc)
	by_id[str(data["id"])] = npc
	return npc


func _face_at(id: String, point: String, target: Vector3) -> void:
	if by_id.has(id):
		by_id[id].face_at[point] = target


func _terrace_points() -> Dictionary:
	var R: Node3D = forge_root
	var f_l: Node3D = forges[0]
	var f_r: Node3D = forges[1]
	return {
		"porte_g": R.to_global(Vector3(-3.4, 0, -9.6)), "porte_d": R.to_global(Vector3(3.4, 0, -9.6)),
		"allee": R.to_global(Vector3(0.8, 0, -2.0)), "allee2": R.to_global(Vector3(-1.0, 0, 7.0)),
		"forge_d": f_r.to_global(Vector3(0.0, 0, 1.8)), "forge_d2": f_r.to_global(Vector3(1.6, 0, 0.4)),
		"forge_g": f_l.to_global(Vector3(0.0, 0, 1.8)),
		"cuisine": R.to_global(Vector3(7.0, 0, 11.0)), "cuisine2": R.to_global(Vector3(9.0, 0, 8.6)),
		"mine": mine_node.to_global(Vector3(0.9, 0, -1.0)), "mine2": mine_node.to_global(Vector3(-1.4, 0, -6.5)),
		"chevres": R.to_global(Vector3(12.0, 0, 6.6)), "chevres2": R.to_global(Vector3(9.0, 0, 3.0)),
		"bord": R.to_global(Vector3(3.0, 0, 13.0)),
	}


## Quête d'un nain ("", "demandee", "finie").
func quest_state(id: String) -> String:
	if by_id.has(id):
		return str(by_id[id].brain.memoire.get("quete", ""))
	if forgefer != null and forgefer.by_id.has(id):
		return str(forgefer.by_id[id].brain.memoire.get("quete", ""))
	return ""


## Nombre de nains aidés (quêtes terminées).
func helped_count() -> int:
	var n: int = 0
	for id in ["bramm", "borin", "dagna", "grimli", "hilda", "ulfa", "nori"]:
		if quest_state(id) == "finie":
			n += 1
	return n


# ------------------------------------------------------------------- décor du sentier

func _near_trail(x: float, z: float, r: float) -> bool:
	for k in range(0, ile.trail.size(), 3):
		var q: Vector3 = ile.trail[k]
		if Vector2(x - q.x, z - q.z).length() < r:
			return true
	return false


func _trail_side(t: float, off: float) -> Vector3:
	var a: Vector3 = ile.trail_at(maxf(t - 0.01, 0.0))
	var b: Vector3 = ile.trail_at(minf(t + 0.01, 1.0))
	var dir: Vector3 = (b - a) * Vector3(1, 0, 1)
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	var side := Vector3(-dir.z, 0, dir.x)
	var p: Vector3 = ile.trail_at(t) + side * off
	p.y = _ground(p.x, p.z)
	return p


## Bornes et lanternes le long du Sentier des Golems, fumerolles, rochers de minerai et
## perchoirs des corbeaux ; un belvédère au bord du cratère.
func _build_trail_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4700
	var stone: Material = _mat("pierre")
	# Bornes runiques tous les ~25 m, lanterne une sur deux
	var n: int = 14
	for k in range(1, n):
		var t: float = float(k) / n
		var bp: Vector3 = _trail_side(t, 2.6 if k % 2 == 0 else -2.6)
		_mesh(self, _box_mesh(Vector3(0.5, 1.4, 0.4)), stone, bp + Vector3.UP * 0.6, Vector3(0, rng.randf() * TAU, 0))
		_mesh(self, _box_mesh(Vector3(0.08, 0.5, 0.42)), _mat("rune"), bp + Vector3.UP * 0.8)
		if k % 2 == 0:
			_mesh(self, _cyl(0.06, 0.08, 2.4, 8), _mat("fer"), bp + Vector3(0, 1.2, 0) + Vector3(0.4, 0, 0))
			_mesh(self, _sphere(0.12, 8), _mat("braise"), bp + Vector3(0.4, 2.5, 0))
			_light(self, Vector3.ZERO, Color(1.0, 0.6, 0.3), 1.0, 8.0).global_position = bp + Vector3(0.4, 2.4, 0)
	# Le belvédère : un muret en arc face au cratère, deux braseros
	var e: Vector3 = ile.trail_end
	var peak: Vector3 = ile.peak_world()
	var to_c: Vector3 = ((peak - e) * Vector3(1, 0, 1)).normalized()
	for k in range(9):
		var a: float = lerpf(-0.9, 0.9, k / 8.0)
		var wp: Vector3 = e + to_c.rotated(Vector3.UP, a) * 4.6
		wp.y = _ground(wp.x, wp.z)
		_mesh(self, _box_mesh(Vector3(1.4, 0.9, 0.6)), stone, wp + Vector3.UP * 0.35, Vector3(0, atan2(to_c.x, to_c.z) + a, 0))
	for sx in [-1.0, 1.0]:
		var bz: Vector3 = e + to_c.rotated(Vector3.UP, sx * 1.3) * 3.6
		bz.y = _ground(bz.x, bz.z)
		_brazier(self, bz)
	# Fumerolles près du sentier (les champignons de braise poussent autour)
	fumaroles.clear()
	for t2 in [0.12, 0.27, 0.46, 0.63, 0.8]:
		var fp: Vector3 = _trail_side(t2, -4.2 if int(t2 * 100) % 2 == 0 else 4.2)
		fumaroles.append(fp)
		var sm := _smoke(self, fp + Vector3.UP * 0.2, 2.2, 16, 0.4, 0.55)
		sm.global_position = fp + Vector3.UP * 0.2
		_mesh(self, Rocks.shape(4720 + fumaroles.size(), Vector3(1.6, 0.4, 1.4), 0.6, 0.2), Rocks.material(Color(0.6, 0.55, 0.3), 0.0, 0.25), fp + Vector3.UP * 0.05)
	# Deux fumerolles en bas, près de la plage
	for k in range(2):
		var a5: float = ile.BAY_ANGLE + (0.7 if k == 0 else -0.8)
		var r5: float = 82.0
		var lp := Vector3(ile.CENTER.x + cos(a5) * r5, 0, ile.CENTER.z + sin(a5) * r5)
		lp.y = _ground(lp.x, lp.z)
		if lp.y < 0.5:
			lp = lp.lerp(Vector3(ile.CENTER.x, lp.y, ile.CENTER.z), 0.12)
			lp.y = _ground(lp.x, lp.z)
		fumaroles.append(lp)
		var sm2 := _smoke(self, lp + Vector3.UP * 0.2, 2.0, 14, 0.4, 0.5)
		sm2.global_position = lp + Vector3.UP * 0.2
	# Rochers de minerai de fer (roche rouillée)
	veins.clear()
	var ore_mat: Material = Rocks.material(Color(0.62, 0.32, 0.2), 0.0, 0.3)
	for t3 in [0.06, 0.18, 0.33, 0.52]:
		var vp: Vector3 = _trail_side(t3, 4.4 if int(t3 * 100) % 2 == 0 else -4.4)
		veins.append(vp)
		_mesh(self, Rocks.shape(4730 + veins.size(), Vector3(2.2, 1.6, 1.9), 0.7, 0.3), ore_mat, vp + Vector3.UP * 0.4, Vector3(0, rng.randf() * TAU, 0))
	for k in range(3):
		var a6: float = ile.BAY_ANGLE + 1.4 + k * 1.1
		var vp2 := Vector3(ile.CENTER.x + ile.PEAK.x + cos(a6) * 72.0, 0, ile.CENTER.z + ile.PEAK.y + sin(a6) * 72.0)
		vp2.y = _ground(vp2.x, vp2.z)
		if vp2.y < 1.0:
			continue
		veins.append(vp2)
		_mesh(self, Rocks.shape(4740 + k, Vector3(2.4, 1.7, 2.0), 0.7, 0.3), ore_mat, vp2 + Vector3.UP * 0.4, Vector3(0, rng.randf() * TAU, 0))
	# Perchoirs des corbeaux : grands rochers isolés
	perches.clear()
	var perch_mat: Material = Rocks.material(Color(0.3, 0.28, 0.3), 0.0, 0.25)
	for k in range(5):
		var a7: float = ile.BAY_ANGLE + 0.9 + k * 1.25
		var r7: float = 68.0 + (k % 2) * 10.0
		var pp := Vector3(ile.CENTER.x + ile.PEAK.x + cos(a7) * r7, 0, ile.CENTER.z + ile.PEAK.y + sin(a7) * r7)
		pp.y = _ground(pp.x, pp.z)
		if pp.y < 0.8 or _near_settlement(pp.x, pp.z, 6.0):
			continue
		_mesh(self, Rocks.shape(4750 + k, Vector3(2.0, 3.6, 2.0), 0.6, 0.25), perch_mat, pp + Vector3.UP * 1.2, Vector3(0, rng.randf() * TAU, 0))
		perches.append(pp + Vector3.UP * 3.0)


## Les objets à ramasser de l'île (lus par l'inventaire, qui retient ce qui est pris).
func pickup_plan() -> Array:
	var out: Array = []
	if ile == null or ile.trail.is_empty():
		return out
	var k: int = 0
	for t in [0.04, 0.1, 0.16, 0.23, 0.3, 0.37, 0.44, 0.5, 0.58]:
		out.append({"uid": "nains_fer_%d" % k, "id": "minerai_fer", "pos": _trail_side(t, 1.7 if k % 2 == 0 else -1.7) + Vector3.UP * 0.02})
		k += 1
	for v in veins:
		out.append({"uid": "nains_fer_%d" % k, "id": "minerai_fer", "pos": Vector3(v.x + 1.6, _ground(v.x + 1.6, v.z + 0.4) + 0.02, v.z + 0.4)})
		k += 1
	k = 0
	for t2 in [0.78, 0.84, 0.9, 0.95]:
		out.append({"uid": "nains_obs_%d" % k, "id": "obsidienne", "pos": _trail_side(t2, 1.5 if k % 2 == 0 else -1.5) + Vector3.UP * 0.02})
		k += 1
	var e: Vector3 = ile.trail_end
	for a in [0.5, 2.2, 3.9, 5.2]:
		var q := Vector3(e.x + cos(a) * 3.0, 0, e.z + sin(a) * 3.0)
		out.append({"uid": "nains_obs_%d" % k, "id": "obsidienne", "pos": Vector3(q.x, _ground(q.x, q.z) + 0.02, q.z)})
		k += 1
	k = 0
	for fp in fumaroles:
		for j in range(2 if k < 6 else 1):
			var ang: float = 0.9 + j * 2.6 + k
			var q2 := Vector3(fp.x + cos(ang) * 1.7, 0, fp.z + sin(ang) * 1.7)
			out.append({"uid": "nains_champi_%d_%d" % [k, j], "id": "champignon_braise", "pos": Vector3(q2.x, _ground(q2.x, q2.z) + 0.02, q2.z)})
		k += 1
	k = 0
	for pp in perches:
		for j in range(2):
			var ang2: float = 0.4 + j * 3.0 + k
			var q3 := Vector3(pp.x + cos(ang2) * 2.0, 0, pp.z + sin(ang2) * 2.0)
			out.append({"uid": "nains_plume_%d_%d" % [k, j], "id": "plume_corbeau", "pos": Vector3(q3.x, _ground(q3.x, q3.z) + 0.02, q3.z)})
		k += 1
	return out


# ------------------------------------------------------------------- la cuisine, l'enclos

func _kitchen(parent: Node3D, at: Vector3) -> void:
	var k := Node3D.new()
	k.name = "Cuisine_Dagna"
	parent.add_child(k)
	k.position = at
	var st: Material = _mat("pierre")
	# Foyer de pierres, chaudron sur trépied, fumée
	for j in range(8):
		var a: float = TAU * j / 8.0
		_mesh(k, Rocks.shape(4760 + j, Vector3(0.45, 0.3, 0.4), 0.6, 0.2), st, Vector3(cos(a) * 0.75, 0.12, sin(a) * 0.75))
	_mesh(k, _sphere(0.35, 10), _mat("braise"), Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1, 0.3, 1))
	_pending_fires.append([k, Vector3(0, 0.25, 0), 0.3, 18])
	for j in range(3):
		var a2: float = TAU * j / 3.0
		_mesh(k, _cyl(0.025, 0.025, 1.6, 6), _mat("fer"), Vector3(cos(a2) * 0.5, 0.75, sin(a2) * 0.5), Vector3(sin(a2) * 0.3, 0, -cos(a2) * 0.3))
	var pot := Node3D.new()
	k.add_child(pot)
	pot.position = Vector3(0, 0.78, 0)
	_mesh(pot, _sphere(0.48, 14), _mat("fer"), Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.8, 1))
	var stew := StandardMaterial3D.new()
	stew.albedo_color = Color(0.55, 0.28, 0.12)
	stew.roughness = 0.35
	stew.emission_enabled = true
	stew.emission = Color(0.4, 0.15, 0.05)
	stew.emission_energy_multiplier = 0.5
	_mesh(pot, _cyl(0.42, 0.42, 0.04, 16), stew, Vector3(0, 0.22, 0))
	var sm := _smoke(k, Vector3(0, 1.2, 0), 1.0, 12, 0.2, 0.6)
	sm.position = Vector3(0, 1.2, 0)
	_light(k, Vector3(0, 0.9, 0.6), Color(1.0, 0.55, 0.25), 1.4, 7.0)
	# Table, bancs, bols
	_mesh(k, _box_mesh(Vector3(2.4, 0.12, 0.9)), _mat("bois"), Vector3(-2.6, 0.85, 0.4))
	for px in [-3.6, -1.6]:
		_mesh(k, _box_mesh(Vector3(0.12, 0.8, 0.7)), _mat("bois"), Vector3(px, 0.4, 0.4))
	for bz in [-0.35, 1.15]:
		_mesh(k, _box_mesh(Vector3(2.2, 0.1, 0.35)), _mat("bois"), Vector3(-2.6, 0.48, bz))
	for j in range(4):
		_mesh(k, _cyl(0.1, 0.07, 0.07, 10), _mat("bois"), Vector3(-3.4 + j * 0.55, 0.95, 0.4))
	# Sacs et tonneau de bière
	_mesh(k, _cyl(0.4, 0.4, 0.9, 12), _mat("bois"), Vector3(1.8, 0.45, -0.9))
	_mesh(k, _sphere(0.35, 10), _cloth_mat(Color(0.75, 0.66, 0.5)), Vector3(2.2, 0.3, 0.6), Vector3.ZERO, Vector3(1, 0.9, 0.8))


func _pen(parent: Node3D, at: Vector3) -> void:
	var p := Node3D.new()
	p.name = "Enclos_chevres"
	parent.add_child(p)
	p.position = at
	var wood: Material = _mat("bois")
	# Palissade en demi-cercle (ouverte côté terrasse)
	for j in range(11):
		var a: float = lerpf(-1.9, 1.9, j / 10.0)
		var q := Vector3(sin(a) * 3.6, 0, cos(a) * 3.6 * 0.8)
		_mesh(p, _cyl(0.06, 0.07, 1.3, 6), wood, q + Vector3.UP * 0.65)
		if j < 10:
			var a2: float = lerpf(-1.9, 1.9, (j + 1) / 10.0)
			var q2 := Vector3(sin(a2) * 3.6, 0, cos(a2) * 3.6 * 0.8)
			var mid: Vector3 = (q + q2) * 0.5
			var seg: Vector3 = q2 - q
			for y in [0.45, 0.95]:
				_mesh(p, _box_mesh(Vector3(seg.length() + 0.1, 0.08, 0.05)), wood, mid + Vector3.UP * y, Vector3(0, -atan2(seg.z, seg.x), 0))
	# Mangeoire et foin
	_mesh(p, _box_mesh(Vector3(1.6, 0.4, 0.6)), wood, Vector3(0, 0.3, 1.6))
	_mesh(p, _box_mesh(Vector3(1.4, 0.18, 0.5)), _cloth_mat(Color(0.75, 0.62, 0.3)), Vector3(0, 0.55, 1.6))
	# Le perchoir à corbeaux de Hilda
	_mesh(p, _cyl(0.06, 0.08, 2.6, 8), wood, Vector3(-2.0, 1.3, -1.6))
	_mesh(p, _cyl(0.04, 0.04, 1.2, 6), wood, Vector3(-2.0, 2.5, -1.6), Vector3(0, 0, PI * 0.5))


func _cloth_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m


# ------------------------------------------------------------------- créatures hostiles

## Golems et élémentaires de magma ne s'éveillent que sur les hauteurs du volcan.
func hostile_zone(p: Vector3) -> bool:
	if ile == null:
		return false
	var pk: Vector3 = ile.peak_world()
	return Vector2(p.x - pk.x, p.z - pk.z).length() < 52.0 and p.y > ile.terrace.y + 4.0 and p.y > -20.0


func _spawn_hostiles() -> void:
	var mo: Node = main.monstres_v36
	if mo == null:
		return
	var spots: Array = []
	for t in [0.42, 0.56, 0.7]:
		spots.append(["golem", ile.trail_at(t)])
	spots.append(["magma", ile.trail_at(0.88)])
	var e: Vector3 = ile.trail_end
	for a in [0.0, 1.6, 3.2, 4.8]:
		var q := Vector3(e.x + cos(a) * 3.2, 0, e.z + sin(a) * 3.2)
		q.y = _ground(q.x, q.z)
		spots.append(["magma", q])
	for sp in spots:
		var at: Vector3 = sp[1]
		at.y = _ground(at.x, at.z) + 0.1
		var m: Node3D = mo.spawn_extra(str(sp[0]), at)
		m.state = "veille"
		m.home = at
		_hostiles.append(m)


func _despawn_hostiles() -> void:
	var mo: Node = main.monstres_v36 if main != null else null
	for m in _hostiles:
		if is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			m.queue_free()
	_hostiles.clear()


func _tick_v47(delta: float, p: Vector3) -> void:
	# La Grande Porte s'ouvre quand Bramm est satisfait
	if not bool(state["ouverte"]) and quest_state("bramm") == "finie":
		open_gate(false)
	# Les créatures des hauteurs : elles s'éveillent quand on monte, disparaissent quand on part
	var pk: Vector3 = ile.peak_world()
	var dist: float = Vector2(p.x - pk.x, p.z - pk.z).length()
	if hostile_zone(p) and _hostiles.is_empty():
		_spawn_hostiles()
	elif dist > 120.0 and not _hostiles.is_empty():
		_despawn_hostiles()
	# Le lac de lave brûle
	_lava_clock = maxf(_lava_clock - delta, 0.0)
	if dist < ile.CRATER_R * 0.9 and p.y < ile.crater_floor + 1.6 and p.y > -20.0 and _lava_clock <= 0.0:
		_lava_clock = 1.0
		if main.monstres_v36 != null and main.hero_v28 != null:
			main.hero_v28.hurt_cooldown = 0.0
			main.monstres_v36.hurt_player(3, p + Vector3.DOWN)
		main.donjon_v35._say("AÏE ! La lave ! Tu bondis hors du cratère en te tenant les fesses.", 3.0)
		var back: Vector3 = ile.trail_end + Vector3.UP * 0.1
		main.place_player_v35(back, ((pk - back) * Vector3(1, 0, 1)).normalized())


## Où se réveiller après un évanouissement sur l'île : sur la terrasse, face à la mer.
func respawn_point() -> Array:
	var at: Vector3 = forge_root.to_global(Vector3(-2.0, 0, 4.0))
	at.y = _ground(at.x, at.z) + 0.1
	var face: Vector3 = (forge_root.to_global(Vector3(0, 0, 1)) - forge_root.global_position).normalized()
	return [at, face]

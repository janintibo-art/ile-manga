extends "res://scripts/monstre_v69.gd"
## V70 : les monstres de l'Île de Braise, de l'Arène des Cornes et des Neuf Cercles. Même règle
## que les autres (groupe « cibles_v28 », take_hit, butin, conseil à la première rencontre) :
##  - le diablotin (le Bois de Cendre la nuit, l'arène) : un petit diable rouge qui voltige sur
##    ses ailes de chauve-souris, une fourche à la main ; il ricane, puis fonce ;
##  - le chien d'enfer (le champ de lave, l'arène) : noir, une crinière de flammes, des yeux de
##    braise ; il crache une gerbe de feu et bondit ;
##  - Gorgoth le Cornu (la dernière manche du tournoi) : le champion de l'arène, en personne ; il
##    ne tombe jamais : à bout de forces, il pose un genou à terre et s'avoue vaincu ;
##  - l'ombre (les Limbes) : une silhouette de fumée aux yeux pâles, qui glisse sans bruit ;
##  - la Furie (la porte de Dité) : ailes de plumes noires, une chevelure de flammes ; elle
##    plane, puis pique ;
##  - Cerbère (le Troisième Cercle) : le chien à trois têtes ; trois gueules qui crachent le feu…
##    mais trois gâteaux de miel l'endorment ;
##  - le spectre de givre (le Cocyte) : une robe de glace qui flotte, des éclats qui tournent ;
##  - le Titan de Givre (au fond du Cocyte) : un géant de glace bleue, la couronne de cristaux ;
##    il frappe le sol, souffle le givre, appelle les spectres.
## (Les gargouilles des Ruines et les automates de l'arène sont ceux de la V54 et de la V63.)

const PB = preload("res://scripts/pnj/pnj_braise_v70.gd")
const SPECS70 := {
	"diablotin": {"pv": 10, "vitesse": 3.0, "degats": 1, "portee": 1.8, "armer": 0.45, "repos": 1.3, "vue": 12.0, "laisse": 16.0,
		"rayon": 0.35, "haut": 0.5, "nom": "Diablotin", "bond": 6.5},
	"chien_enfer": {"pv": 16, "vitesse": 3.4, "degats": 1, "portee": 2.6, "armer": 0.6, "repos": 1.4, "vue": 13.0, "laisse": 18.0,
		"rayon": 0.5, "haut": 0.5, "nom": "Chien d'enfer", "bond": 8.0},
	"gorgoth": {"pv": 120, "vitesse": 2.1, "degats": 2, "portee": 2.2, "armer": 0.8, "repos": 1.5, "vue": 40.0, "laisse": 60.0,
		"rayon": 0.55, "haut": 1.1, "nom": "Gorgoth le Cornu", "boss": true},
	"ombre": {"pv": 12, "vitesse": 2.0, "degats": 1, "portee": 2.0, "armer": 0.7, "repos": 1.5, "vue": 11.0, "laisse": 16.0,
		"rayon": 0.4, "haut": 1.0, "nom": "Ombre des Limbes"},
	"furie": {"pv": 26, "vitesse": 2.8, "degats": 1, "portee": 2.8, "armer": 0.7, "repos": 1.5, "vue": 16.0, "laisse": 22.0,
		"rayon": 0.45, "haut": 1.2, "nom": "Furie", "bond": 9.0},
	"cerbere": {"pv": 90, "vitesse": 2.4, "degats": 2, "portee": 4.4, "armer": 0.8, "repos": 1.4, "vue": 24.0, "laisse": 30.0,
		"rayon": 1.6, "haut": 1.4, "nom": "Cerbère", "boss": true, "bond": 9.0},
	"spectre_givre": {"pv": 16, "vitesse": 2.3, "degats": 1, "portee": 2.4, "armer": 0.7, "repos": 1.5, "vue": 13.0, "laisse": 18.0,
		"rayon": 0.45, "haut": 1.1, "nom": "Spectre de givre", "bond": 7.0},
	"titan_givre": {"pv": 240, "vitesse": 1.5, "degats": 2, "portee": 4.4, "armer": 1.0, "repos": 1.5, "vue": 34.0, "laisse": 70.0,
		"rayon": 1.6, "haut": 3.1, "nom": "le Titan de Givre", "boss": true},
}
const SOUNDS70 := {"diablotin": ["diablotin_cri", "diablotin_mort"], "chien_enfer": ["chien_enfer_aboi", "chien_enfer_mort"],
	"gorgoth": ["gorgoth_cri", "gorgoth_cri"], "ombre": ["ombre_murmure", "spectre_mort"], "furie": ["furie_cri", "furie_cri"],
	"cerbere": ["cerbere_aboi", "boss_coeur_cri"], "spectre_givre": ["spectre_givre_cri", "spectre_mort"], "titan_givre": ["titan_rugit", "boss_coeur_cri"]}
const LEAPERS70 := ["diablotin", "chien_enfer", "furie", "cerbere", "spectre_givre"]

var _fly: float = 0.0                    # hauteur de vol de la silhouette (diablotin, Furie, spectres)
var _breaths: Array = []                 # les gerbes de feu (ou de givre) des gueules
var _heads: Array = []                   # les têtes de Cerbère (elles bougent chacune à son rythme)
var _shards: Node3D
var _npc_vis: Node3D                     # Gorgoth : le vrai Gorgoth (son corps, ses cornes)
var _step_t: float = 0.0
var _phase70: int = 0
var _breath_t: float = 0.0
var asleep: bool = false                 # Cerbère endormi par les gâteaux de miel
var yielded: bool = false                # Gorgoth s'avoue vaincu
var _zzz: CPUParticles3D


func _v63() -> bool:
	return SPECS70.has(kind) or super._v63()


func _leaper() -> bool:
	return kind in LEAPERS70 or super._leaper()


func _sound_pair() -> Array:
	return SOUNDS70.get(kind, super._sound_pair())


func _armer_anim() -> void:
	match kind:
		"gorgoth":
			_play("v28/slash3", 0.1, 0.6)
		"ombre", "furie", "titan_givre":
			_play("v28/slash2", 0.1, 0.5 if kind == "titan_givre" else 0.7)
		_:
			super._armer_anim()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS70.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS70[k]
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	match k:
		"chien_enfer", "cerbere":
			var s: float = 1.0 if k == "chien_enfer" else 2.0
			cap.radius = 0.3 * s
			cap.height = 1.6 * s
			cs.rotation.x = PI * 0.5
			cs.position = Vector3(0, 0.5 * s, 0)
		"diablotin":
			cap.radius = 0.28
			cap.height = 0.9
			cs.position.y = 0.45
		"titan_givre":
			cap.radius = 0.75
			cap.height = 4.2
			cs.position.y = 2.1
		"gorgoth":
			cap.radius = 0.38
			cap.height = 2.1
			cs.position.y = 1.05
		_:
			cap.radius = 0.32
			cap.height = 1.8
			cs.position.y = 0.9
	cs.shape = cap
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"diablotin":
			_build_diablotin()
		"chien_enfer":
			_build_dog(1.0, false)
		"cerbere":
			_build_dog(3.0, true)
		"gorgoth":
			_build_gorgoth()
		"ombre":
			_build_ombre()
		"furie":
			_build_furie()
		"spectre_givre":
			_build_spectre_givre()
		"titan_givre":
			_build_titan()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


# =================================================================== les morceaux

## Une aile de chauve-souris (membrane festonnée tendue entre quatre doigts), côté +x ou -x.
func _bat_wing(parent: Node3D, side: float, size: float, mem: Material, bone: Material) -> void:
	var W := Vector3(0.3 * side, 0.18, -0.05) * size
	var tips := [Vector3(0.2 * side, 0.55, -0.08) * size, Vector3(0.62 * side, 0.42, -0.1) * size, Vector3(0.8 * side, 0.12, -0.08) * size, Vector3(0.62 * side, -0.14, -0.04) * size]
	var B := Vector3(0.12 * side, -0.12, 0.0) * size
	var rim: Array = [Vector3.ZERO]
	var edges := [[Vector3.ZERO, tips[0], 0.0], [tips[0], tips[1], 0.22], [tips[1], tips[2], 0.25], [tips[2], tips[3], 0.25], [tips[3], B, 0.2], [B, Vector3.ZERO, 0.05]]
	for e in edges:
		for i in range(1, 6):
			var t: float = float(i) / 5.0
			rim.append(((e[0] as Vector3).lerp(e[1], t)).lerp(W, float(e[2]) * sin(t * PI)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i2 in range(rim.size() - 1):
		var p1: Vector3 = rim[i2]
		var p2: Vector3 = rim[i2 + 1]
		var n: Vector3 = (p2 - W).cross(p1 - W).normalized()
		for v in [W, p1, p2]:
			st.set_normal(n)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mem
	parent.add_child(mi)
	_stick(parent, Vector3.ZERO, W, 0.018 * size, bone)
	for t2 in tips:
		_stick(parent, W, t2, 0.008 * size, bone)


## Un bâton (cylindre) de a à b.
func _stick(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl(r * 0.7, r, a.distance_to(b))
	mi.material_override = mat
	mi.basis = PB._basis_y((b - a).normalized())
	mi.position = (a + b) * 0.5
	parent.add_child(mi)
	return mi


## Des cornes (un tube effilé courbe), posées en « at », pointées vers le haut et l'extérieur.
func _horns(parent: Node3D, at: Vector3, spread: float, size: float, c: Color) -> void:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.4
	_flash_mats.append(m)
	for sx in [-1.0, 1.0]:
		var ctrl := [Vector3.ZERO, Vector3(0.03 * sx, 0.05, -0.01), Vector3(0.06 * sx, 0.1, -0.03), Vector3(0.06 * sx, 0.15, 0.0), Vector3(0.045 * sx, 0.18, 0.025)]
		var pts: Array = []
		for p in ctrl:
			pts.append((p as Vector3) * size)
		var path: PackedVector3Array = PB.smooth_path(pts, 14)
		var radii := PackedFloat32Array()
		for i in range(path.size()):
			radii.append(lerpf(0.022, 0.002, float(i) / float(path.size() - 1)) * size)
		var mi := MeshInstance3D.new()
		mi.mesh = PB.tube_mesh(path, radii, 10, 0.0, 0.0, c * 0.6 + Color(0, 0, 0, 0.4), c.lightened(0.25))
		mi.material_override = m
		mi.position = at + Vector3(sx * spread, 0, 0)
		parent.add_child(mi)


## Une gerbe de feu (ou de givre) qui sort d'une gueule, vers l'avant (+Z).
func _breath(parent: Node3D, at: Vector3, s: float, ice: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 40
	p.lifetime = 0.55
	p.local_coords = false
	p.direction = Vector3(0, 0, 1)
	p.spread = 14.0
	p.initial_velocity_min = 4.5 * s
	p.initial_velocity_max = 7.0 * s
	p.gravity = Vector3(0, 1.5, 0) if not ice else Vector3(0, -1.0, 0)
	p.scale_amount_min = 0.6 * s
	p.scale_amount_max = 1.6 * s
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	if ice:
		grad.set_color(0, Color(0.85, 0.95, 1.0, 0.9))
		grad.set_color(1, Color(0.5, 0.75, 1.0, 0.0))
	else:
		grad.set_color(0, Color(1.0, 0.85, 0.35, 1.0))
		grad.set_color(1, Color(0.9, 0.15, 0.04, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.3)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	if manager != null and manager.main != null and manager.main.has_method("_soft_dot_v24"):
		m.albedo_texture = manager.main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.position = at
	parent.add_child(p)
	_breaths.append(p)
	return p


# =================================================================== le diablotin

func _build_diablotin() -> void:
	var skin := _mat(Color(0.72, 0.12, 0.1), 0.55)
	var belly := _mat(Color(0.9, 0.42, 0.3), 0.6)
	var dark := _mat(Color(0.08, 0.04, 0.04), 0.8)
	var eye := _mat(Color(1.0, 0.85, 0.2), 0.2, 4.0)
	var teeth := _mat(Color(0.97, 0.94, 0.86), 0.4)
	var iron := _mat(Color(0.25, 0.24, 0.25), 0.4)
	iron.metallic = 0.8
	var wingm := _mat(Color(0.45, 0.08, 0.08), 0.8)
	wingm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := Node3D.new()
	body.name = "Vol"
	body.position = Vector3(0, 0.5, 0)
	_visual.add_child(body)
	_body_node = body
	_mesh(body, _sphere(0.15), skin, Vector3(0, 0.0, 0), Vector3(1.0, 1.15, 0.9))
	_mesh(body, _sphere(0.11), belly, Vector3(0, -0.02, 0.06), Vector3(1.0, 1.1, 0.7))
	var head := Node3D.new()
	head.position = Vector3(0, 0.27, 0.02)
	body.add_child(head)
	_mesh(head, _sphere(0.13), skin, Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	for sx in [-1.0, 1.0]:
		_mesh(head, _cyl(0.0, 0.04, 0.13), skin, Vector3(sx * 0.15, 0.03, -0.01), Vector3(1.0, 1.0, 0.5), _r(Vector3(0, 0, -sx * 70.0)))
		_mesh(head, _sphere(0.032), eye, Vector3(sx * 0.05, 0.03, 0.11), Vector3(1.0, 1.15, 0.6))
		_mesh(head, _sphere(0.012), dark, Vector3(sx * 0.05, 0.03, 0.13), Vector3(0.5, 1.4, 0.4))
	_mesh(head, _box_mesh_g(Vector3(0.1, 0.02, 0.02)), dark, Vector3(0, -0.05, 0.12), Vector3.ONE, _r(Vector3(0, 0, 0)))
	for k in range(4):
		_mesh(head, _cyl(0.0, 0.006, 0.018), teeth, Vector3(-0.03 + k * 0.02, -0.04, 0.125), Vector3.ONE, _r(Vector3(180, 0, 0)))
	_horns(head, Vector3(0, 0.08, 0.02), 0.05, 0.55, Color(0.2, 0.12, 0.1))
	# les bras, les jambes
	for sx2 in [-1.0, 1.0]:
		_stick(body, Vector3(sx2 * 0.12, 0.08, 0), Vector3(sx2 * 0.2, -0.08, 0.1), 0.03, skin)
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.07, -0.14, 0)
		body.add_child(leg)
		_stick(leg, Vector3.ZERO, Vector3(0, -0.2, 0.03), 0.035, skin)
		_mesh(leg, _sphere(0.035), dark, Vector3(0, -0.22, 0.05), Vector3(1.0, 0.6, 1.5))
		_legs.append([leg, sx2, 0.0])
		var w := Node3D.new()
		w.position = Vector3(sx2 * 0.06, 0.1, -0.1)
		body.add_child(w)
		_bat_wing(w, sx2, 0.42, wingm, dark)
		_wings.append([w, sx2])
	# la fourche, dans la main droite
	var fork := Node3D.new()
	fork.position = Vector3(-0.2, -0.08, 0.12)
	body.add_child(fork)
	_mesh(fork, _cyl(0.008, 0.008, 0.6), dark, Vector3(0, 0.1, 0))
	_mesh(fork, _box_mesh_g(Vector3(0.08, 0.012, 0.012)), iron, Vector3(0, 0.4, 0))
	for fx in [-0.035, 0.0, 0.035]:
		_mesh(fork, _cyl(0.0, 0.006, 0.08), iron, Vector3(fx, 0.45, 0))
	# la queue en flèche
	var tail := Node3D.new()
	tail.position = Vector3(0, -0.1, -0.12)
	body.add_child(tail)
	var tp: PackedVector3Array = PB.smooth_path([Vector3.ZERO, Vector3(0, -0.06, -0.12), Vector3(0.05, -0.04, -0.26), Vector3(0.08, 0.06, -0.34)], 14)
	var tr := PackedFloat32Array()
	for i in range(tp.size()):
		tr.append(lerpf(0.016, 0.006, float(i) / 13.0))
	_mesh(tail, PB.tube_mesh(tp, tr, 8, 0.0, 0.0, Color(0.72, 0.12, 0.1), Color(0.55, 0.08, 0.06)), skin, Vector3.ZERO)
	var spade := MeshInstance3D.new()
	spade.mesh = PB._spade_mesh(0.05, 0.07, 0.01)
	spade.material_override = skin
	spade.position = tp[tp.size() - 1]
	spade.basis = PB._basis_y((tp[tp.size() - 1] - tp[tp.size() - 3]).normalized())
	tail.add_child(spade)
	_tail.append([tail, 0.0])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.2)
	l.light_energy = 0.5
	l.omni_range = 2.5
	l.position = Vector3(0, 0.3, 0.3)
	body.add_child(l)


# =================================================================== les chiens d'enfer, Cerbère

func _build_dog(s: float, three: bool) -> void:
	var fur := _mat(Color(0.07, 0.055, 0.055), 0.85)
	var belly := _mat(Color(0.16, 0.1, 0.09), 0.9)
	var ember := _mat(Color(1.0, 0.42, 0.1), 0.4, 3.2)
	var eye := _mat(Color(1.0, 0.75, 0.2), 0.2, 5.0)
	var gold := _mat(Color(0.9, 0.65, 0.25), 0.3)
	gold.metallic = 0.85
	var leather := _mat(Color(0.35, 0.08, 0.06), 0.6)
	var teeth := _mat(Color(0.95, 0.92, 0.84), 0.4)
	_cat_body = Node3D.new()
	_cat_body.position = Vector3(0, 0.55 * s, 0)
	_cat_body.scale = Vector3.ONE * s
	_visual.add_child(_cat_body)
	_mesh(_cat_body, _sphere(0.27), fur, Vector3(0, 0, -0.02), Vector3(0.9, 0.85, 1.9))
	_mesh(_cat_body, _sphere(0.3), fur, Vector3(0, 0.06, 0.32), Vector3(1.0, 1.0, 1.0))
	_mesh(_cat_body, _sphere(0.22), belly, Vector3(0, -0.1, 0.1), Vector3(0.8, 0.6, 1.6))
	# la crinière de flammes, le long du cou et du dos
	for k in range(9):
		var z: float = 0.48 - k * 0.1
		_mesh(_cat_body, _cyl(0.0, 0.05, 0.16 - k * 0.008), ember, Vector3(0, 0.27 - k * 0.006, z), Vector3(1.0, 1.0, 0.5), _r(Vector3(-35, 0, 0)))
	var heads: Array = [0.0] if not three else [-0.25, 0.0, 0.25]
	for hx in heads:
		var neck := Node3D.new()
		neck.position = Vector3(float(hx), 0.16, 0.42)
		neck.rotation.y = -float(hx) * 0.8
		_cat_body.add_child(neck)
		_mesh(neck, _cyl(0.09, 0.12, 0.3), fur, Vector3(0, 0.08, 0.1), Vector3.ONE, _r(Vector3(50, 0, 0)))
		var head := Node3D.new()
		head.position = Vector3(0, 0.2, 0.25)
		neck.add_child(head)
		_mesh(head, _sphere(0.15), fur, Vector3.ZERO, Vector3(1.0, 0.92, 1.1))
		_mesh(head, _box_mesh_g(Vector3(0.13, 0.09, 0.2)), fur, Vector3(0, -0.03, 0.17))
		_mesh(head, _sphere(0.03), _mat(Color(0.02, 0.02, 0.02), 0.3), Vector3(0, 0.0, 0.27))
		for sx in [-1.0, 1.0]:
			_mesh(head, _cyl(0.0, 0.05, 0.13), fur, Vector3(sx * 0.09, 0.15, -0.03), Vector3(1.0, 1.0, 0.45), _r(Vector3(-10, 0, -sx * 18.0)))
			_mesh(head, _sphere(0.026), eye, Vector3(sx * 0.07, 0.04, 0.12), Vector3(1.0, 0.7, 0.6))
		_horns(head, Vector3(0, 0.1, 0.02), 0.05, 0.42, Color(0.75, 0.68, 0.55))
		var jaw := Node3D.new()
		jaw.position = Vector3(0, -0.08, 0.08)
		head.add_child(jaw)
		_mesh(jaw, _box_mesh_g(Vector3(0.12, 0.04, 0.18)), belly, Vector3(0, -0.01, 0.09))
		for t in range(3):
			for sx2 in [-0.04, 0.04]:
				_mesh(jaw, _cyl(0.0, 0.008, 0.025), teeth, Vector3(sx2, 0.02, 0.12 + t * 0.025))
		if three:
			# un collier de cuir clouté d'or
			var collar := TorusMesh.new()
			collar.inner_radius = 0.1
			collar.outer_radius = 0.14
			_mesh(neck, collar, leather, Vector3(0, 0.12, 0.13), Vector3.ONE, _r(Vector3(50, 0, 0)))
			for c in range(6):
				var a: float = TAU * c / 6.0
				_mesh(neck, _cyl(0.0, 0.015, 0.05), gold, Vector3(cos(a) * 0.14, 0.12 + sin(a) * 0.09, 0.13 + sin(a) * 0.08))
		_heads.append([head, jaw, float(hx)])
		if _jaw_low == null:
			_jaw_low = jaw
		_breath(head, Vector3(0, -0.03, 0.3), s, false)
	# la queue
	var prev: Node3D = _cat_body
	var zz: float = -0.5
	for t2 in range(5):
		var seg := Node3D.new()
		seg.position = Vector3(0, 0.1 if t2 == 0 else 0.0, zz)
		prev.add_child(seg)
		_mesh(seg, _cyl(0.025 - t2 * 0.003, 0.035 - t2 * 0.004, 0.18), fur if t2 < 4 else ember, Vector3(0, 0, -0.09), Vector3.ONE, _r(Vector3(90, 0, 0)))
		_tail.append([seg, 0.3])
		prev = seg
		zz = -0.18
	# les pattes (plus hautes que celles des félins)
	for side in [-1.0, 1.0]:
		for fz in [0.38, -0.36]:
			var hip := Node3D.new()
			hip.position = Vector3(side * 0.16, -0.05, fz)
			_cat_body.add_child(hip)
			_mesh(hip, _cyl(0.045, 0.06, 0.48), fur, Vector3(0, -0.24, 0))
			_mesh(hip, _sphere(0.055), fur, Vector3(0, -0.49, 0.03), Vector3(1.0, 0.6, 1.4))
			for cl in [-0.025, 0.0, 0.025]:
				_mesh(hip, _cyl(0.0, 0.008, 0.03), teeth, Vector3(cl, -0.5, 0.09), Vector3.ONE, _r(Vector3(90, 0, 0)))
			_legs.append([hip, side, fz])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.light_energy = 0.8 if not three else 1.6
	l.omni_range = 3.5 * s
	l.position = Vector3(0, 0.9 * s, 0.3 * s)
	_visual.add_child(l)


# =================================================================== Gorgoth le Cornu

## Le vrai Gorgoth (son corps V64, ses cornes de bélier, sa queue en touffe) prête son corps au
## combattant de l'arène.
func _build_gorgoth() -> void:
	var H = load("res://scripts/pnj/braise_habitants_v70.gd")
	var prof: Dictionary = {}
	for d in H.all_profiles():
		if str(d["id"]) == "gorgoth":
			prof = d
	var npc: Node3D = PB.new()
	npc.set("profile", prof)
	npc.set("display_name", "Gorgoth")
	_visual.add_child(npc)
	npc.call("_build_body")
	npc.call("body64_build")
	npc.call("demon_parts", prof.get("demon", {}))
	npc.set_process(false)
	npc.set_physics_process(false)
	var bd: Node = npc.get("_body")
	if bd != null:
		for c in bd.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		(bd as CollisionObject3D).collision_layer = 0
	var lb: Node = npc.get("bubble")
	if lb != null:
		lb.visible = false
	_npc_vis = npc
	_anim = npc.get("anim")
	# ses poings de bronze (des gantelets) : il se bat à mains nues
	var skel: Skeleton3D = npc.get("skel")
	if skel != null:
		var bronze := _mat(Color(0.75, 0.5, 0.25), 0.35)
		bronze.metallic = 0.85
		for hand in ["LeftHand", "RightHand"]:
			var g := Node3D.new()
			_mesh(g, _sphere(0.065), bronze, Vector3(0, 0.05, 0.0), Vector3(1.1, 1.0, 1.2))
			npc.call("_attach", hand, Vector3(0, -6, 2), g)
	_play("v28/idle")


## À bout de forces, Gorgoth ne tombe pas : il pose un genou à terre et lève la main.
func _yield_gorgoth() -> void:
	yielded = true
	state = "rendu"
	timer = 0.0
	collision_layer = 0
	remove_from_group("cibles_v28")
	_play("v28/sit", 0.4)
	_sound63("menace")
	died.emit(self)


# =================================================================== l'ombre, la Furie

func _humanoid(s: float) -> Skeleton3D:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * s
	_visual.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = found[0] if found.size() > 0 else null
	if _anim != null and skel != null:
		var lib = HeroLib68.new()
		lib.hero = model
		lib.anim = _anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	return skel


func _limbs(skel: Skeleton3D, mat: Material, mat2: Material, thick_k: float) -> void:
	for pair in [["Hips", "Spine"], ["Spine", "Spine01"], ["Spine01", "Spine02"], ["Spine02", "neck"], ["neck", "Head"],
			["LeftArm", "LeftForeArm"], ["LeftForeArm", "LeftHand"], ["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"],
			["LeftUpLeg", "LeftLeg"], ["LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg"], ["RightLeg", "RightFoot"],
			["Spine02", "LeftArm"], ["Spine02", "RightArm"], ["Hips", "LeftUpLeg"], ["Hips", "RightUpLeg"]]:
		var thick: float = 0.06 if str(pair[0]).contains("Arm") or str(pair[0]).contains("Leg") else 0.12
		if str(pair[0]) in ["Spine01", "Spine02", "Hips"]:
			thick = 0.15
		_bone_stick(skel, str(pair[0]), str(pair[1]), thick * thick_k, mat if randf() < 0.6 else mat2)


func _build_ombre() -> void:
	var skel: Skeleton3D = _humanoid(1.0)
	if skel == null:
		return
	var smoke := _mat(Color(0.05, 0.03, 0.08), 0.95)
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.albedo_color = Color(0.05, 0.03, 0.08, 0.8)
	var smoke2 := _mat(Color(0.12, 0.08, 0.16), 0.95)
	smoke2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke2.albedo_color = Color(0.12, 0.08, 0.16, 0.65)
	_limbs(skel, smoke, smoke2, 1.0)
	# la robe de fumée qui traîne, le capuchon, deux yeux pâles
	var robe := Node3D.new()
	_mesh(robe, _cyl(0.16, 0.42, 1.0), smoke2, Vector3(0, -0.45, 0))
	_attach(skel, "Hips", Vector3(0, 0, 0), robe)
	var head := Node3D.new()
	_mesh(head, _sphere(0.15), smoke, Vector3(0, 0.03, -0.02), Vector3(1.0, 1.2, 1.1))
	var eye := _mat(Color(0.8, 0.75, 1.0), 0.2, 5.0)
	for sx in [-0.045, 0.045]:
		_mesh(head, _sphere(0.02), eye, Vector3(sx, 0.03, 0.12), Vector3(1.2, 0.6, 0.5))
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	_mist_trail(_visual, Color(0.2, 0.12, 0.3, 0.35))
	_play("v28/idle")


func _build_furie() -> void:
	var skel: Skeleton3D = _humanoid(1.05)
	if skel == null:
		return
	var robe := _mat(Color(0.28, 0.04, 0.06), 0.8)
	var robe2 := _mat(Color(0.12, 0.03, 0.05), 0.85)
	var skin := _mat(Color(0.55, 0.42, 0.5), 0.6)
	_limbs(skel, robe, robe2, 1.05)
	var skirt := Node3D.new()
	var sm := _mat(Color(0.2, 0.03, 0.05), 0.8)
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(skirt, _cyl(0.17, 0.4, 0.8), sm, Vector3(0, -0.38, 0))
	_attach(skel, "Hips", Vector3(0, 2, 0), skirt)
	var head := Node3D.new()
	_mesh(head, _sphere(0.12), skin, Vector3(0, 0.03, 0), Vector3(0.95, 1.1, 1.0))
	var eye := _mat(Color(1.0, 0.3, 0.15), 0.2, 5.0)
	for sx in [-0.04, 0.04]:
		_mesh(head, _sphere(0.017), eye, Vector3(sx, 0.04, 0.105), Vector3(1.2, 0.7, 0.5))
	# la chevelure de flammes
	var fl := _mat(Color(1.0, 0.45, 0.12), 0.3, 3.5)
	for k in range(11):
		var a: float = TAU * k / 11.0
		_mesh(head, _cyl(0.0, 0.035, 0.22), fl, Vector3(cos(a) * 0.08, 0.14, sin(a) * 0.08 - 0.03), Vector3.ONE, _r(Vector3(sin(a) * 25.0 - 20.0, 0, -cos(a) * 25.0)))
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	# les ailes de plumes noires
	var fm := _mat(Color(0.08, 0.07, 0.08), 0.7)
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	for sx2 in [-1.0, 1.0]:
		var w := Node3D.new()
		for f in range(9):
			var t: float = float(f) / 8.0
			var L: float = lerpf(0.55, 0.95, sin(t * PI * 0.9))
			var feather := _mesh(w, _box_mesh_g(Vector3(0.12, L, 0.01)), fm, Vector3(sx2 * (0.12 + t * 0.6), 0.25 - t * 0.12 + L * 0.3, -0.05 - t * 0.05), Vector3.ONE, _r(Vector3(0, 0, -sx2 * lerpf(10.0, 75.0, t))))
			feather.name = "Plume"
		_attach(skel, "Spine02", Vector3(sx2 * 8.0, 12.0, -12.0), w)
		_wings.append([w, sx2])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.light_energy = 0.7
	l.omni_range = 4.0
	l.position = Vector3(0, 2.0, 0.3)
	_visual.add_child(l)
	_play("v28/idle")


# =================================================================== le givre

func _ice_mat(base: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = 0.08
	m.metallic_specular = 0.9
	m.rim_enabled = true
	m.rim = 0.6
	m.rim_tint = 0.3
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(0.45, 0.75, 1.0)
		m.emission_energy_multiplier = emit
	_flash_mats.append(m)
	return m


func _build_spectre_givre() -> void:
	var body := Node3D.new()
	body.name = "Vol"
	_visual.add_child(body)
	_body_node = body
	var robe := _ice_mat(Color(0.7, 0.85, 1.0, 0.55), 0.6)
	robe.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh(body, _cyl(0.14, 0.46, 1.4), robe, Vector3(0, 0.95, 0))
	_mesh(body, _sphere(0.22), robe, Vector3(0, 1.72, -0.02), Vector3(1.0, 1.15, 1.1))
	for sx in [-1.0, 1.0]:
		_mesh(body, _cyl(0.04, 0.12, 0.7), robe, Vector3(sx * 0.3, 1.25, 0.16), Vector3.ONE, Vector3(-0.9, 0, sx * 0.35))
	var hole := _mat(Color(0.02, 0.04, 0.08), 1.0)
	_mesh(body, _sphere(0.14), hole, Vector3(0, 1.7, 0.11), Vector3(1.0, 1.2, 0.6))
	_eyes_mat = _mat(Color(0.55, 0.95, 1.0), 0.2, 6.0)
	for sx2 in [-1.0, 1.0]:
		_mesh(body, _sphere(0.026), _eyes_mat, Vector3(sx2 * 0.055, 1.72, 0.18), Vector3(1.0, 0.6, 0.5))
	# les éclats de glace qui tournent autour
	_shards = Node3D.new()
	_shards.position = Vector3(0, 1.2, 0)
	body.add_child(_shards)
	var shard := _ice_mat(Color(0.8, 0.92, 1.0), 1.2)
	for k in range(5):
		var a: float = TAU * k / 5.0
		_mesh(_shards, _cyl(0.0, 0.05, 0.22), shard, Vector3(cos(a) * 0.55, sin(a * 2.0) * 0.15, sin(a) * 0.55), Vector3.ONE, Vector3(0.3, a, 0.4))
	var l := OmniLight3D.new()
	l.light_color = Color(0.55, 0.8, 1.0)
	l.light_energy = 0.8
	l.omni_range = 4.0
	l.position = Vector3(0, 1.5, 0.3)
	body.add_child(l)
	_mist_trail(body, Color(0.75, 0.9, 1.0, 0.3))
	_breath(body, Vector3(0, 1.68, 0.25), 0.8, true)


func _build_titan() -> void:
	var skel: Skeleton3D = _humanoid(2.8)
	if skel == null:
		return
	var ice := _ice_mat(Color(0.62, 0.8, 0.95), 0.25)
	var ice2 := _ice_mat(Color(0.82, 0.92, 1.0), 0.15)
	_limbs(skel, ice, ice2, 1.35)
	var crystal := _ice_mat(Color(0.7, 0.9, 1.0), 1.6)
	# des pics de cristal sur les épaules, le dos, et la couronne
	for b in [["LeftShoulder", 1.0], ["RightShoulder", -1.0]]:
		var sp := Node3D.new()
		for k in range(4):
			_mesh(sp, _cyl(0.0, 0.05, 0.3 - k * 0.04), crystal, Vector3(float(b[1]) * 0.04 * k, 0.1 + k * 0.03, -0.03 * k), Vector3.ONE, _r(Vector3(-15 * k, 0, float(b[1]) * (20 + k * 12))))
		_attach(skel, str(b[0]), Vector3(0, 6, 0), sp)
	var back := Node3D.new()
	for k2 in range(6):
		_mesh(back, _cyl(0.0, 0.06, 0.35 - k2 * 0.03), crystal, Vector3(((k2 % 2) * 2 - 1) * 0.07, 0.2 - k2 * 0.12, -0.14), Vector3.ONE, _r(Vector3(-60, 0, 0)))
	_attach(skel, "Spine02", Vector3(0, 6, -6), back)
	var head := Node3D.new()
	_mesh(head, _sphere(0.15), ice, Vector3(0, 0.03, 0), Vector3(1.0, 1.15, 1.05))
	_mesh(head, _box_mesh_g(Vector3(0.2, 0.06, 0.12)), ice2, Vector3(0, -0.08, 0.06))
	var eye := _mat(Color(0.5, 0.95, 1.0), 0.2, 7.0)
	for sx in [-0.05, 0.05]:
		_mesh(head, _sphere(0.022), eye, Vector3(sx, 0.04, 0.13), Vector3(1.3, 0.6, 0.5))
	for k3 in range(7):
		var a: float = deg_to_rad(-90.0 + k3 * 30.0)
		_mesh(head, _cyl(0.0, 0.03, 0.2 if k3 == 3 else 0.14), crystal, Vector3(sin(a) * 0.12, 0.17, cos(a) * 0.1), Vector3.ONE, _r(Vector3(cos(a) * 18.0, 0, -sin(a) * 18.0)))
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	# la massue : un grand éclat de glace dans la main droite
	var club := Node3D.new()
	_mesh(club, _cyl(0.03, 0.04, 0.5), ice2, Vector3(0, -0.05, 0))
	_mesh(club, _cyl(0.0, 0.14, 0.7), crystal, Vector3(0, 0.55, 0))
	_mesh(club, _cyl(0.14, 0.0, 0.2), crystal, Vector3(0, 0.1, 0))
	_attach(skel, "RightHand", Vector3(0, -8, 3), club)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.8, 1.0)
	l.light_energy = 2.5
	l.omni_range = 9.0
	l.position = Vector3(0, 4.2, 1.0)
	_visual.add_child(l)
	_breath(_visual, Vector3(0, 4.7, 0.8), 2.2, true)
	_play("v28/idle")


# =================================================================== comportement

func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS70.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state in ["mort", "rendu"] or asleep:
		return
	var cb: Node = manager.main.combat_v28
	hp -= damage
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	_knock = away * (3.0 if kind in ["diablotin", "ombre", "spectre_givre", "chien_enfer"] else (1.0 if kind == "furie" else 0.3))
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (hit_height * 2.0 + 0.3)
		if bool(cb.get("critical")):
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, _puff_color())
	if kind == "gorgoth" and hp <= int(int(spec["pv"]) * 0.12):
		hp = maxi(hp, 1)
		_yield_gorgoth()
		return
	if hp <= 0:
		_die63()
		return
	if is_boss():
		return
	state = "recul"
	timer = 0.25


## Cerbère mange les trois gâteaux de miel… et s'endort (on passe sans combattre).
func endormir() -> void:
	asleep = true
	state = "dort"
	timer = 0.0
	remove_from_group("cibles_v28")
	for b in _breaths:
		(b as CPUParticles3D).emitting = false
	_zzz = CPUParticles3D.new()
	_zzz.amount = 6
	_zzz.lifetime = 2.5
	_zzz.direction = Vector3(0.3, 1, 0)
	_zzz.spread = 10.0
	_zzz.initial_velocity_min = 0.4
	_zzz.initial_velocity_max = 0.6
	_zzz.gravity = Vector3.ZERO
	var tm := TextMesh.new()
	tm.text = "Z"
	tm.font_size = 64
	tm.depth = 0.02
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.9, 1.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tm.material = m
	_zzz.mesh = tm
	_zzz.position = Vector3(0, 2.6, 0.8)
	add_child(_zzz)


func is_hittable() -> bool:
	if SPECS70.has(kind):
		return not (state in ["mort", "rendu"]) and not asleep
	return super.is_hittable()


func _physics_process(delta: float) -> void:
	if not SPECS70.has(kind):
		super._physics_process(delta)
		return
	if state == "rendu":
		_clock += delta
		timer += delta
		_play("v28/sit", 0.4)
		return
	if asleep:
		_clock += delta
		_animate63(delta, 0.0)
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 3.2
			if manager.main.has_method("sfx") and global_position.distance_to(_player()) < 20.0:
				manager.main.sfx("cerbere_ronfle", global_position + Vector3.UP)
		return
	super._physics_process(delta)


func _boss_tick(delta: float, dist: float) -> void:
	if not SPECS70.has(kind):
		super._boss_tick(delta, dist)
		return
	_special_t += delta
	var pv: int = int(spec["pv"])
	match kind:
		"cerbere":
			# les trois gueules crachent le feu devant elles
			if _special_t > 6.0 and dist < 7.5:
				_special_t = 0.0
				_fire_cone(6.5, 0.55)
				_hint70("Cerbère crache le feu de ses trois gueules !")
		"gorgoth":
			if _special_t > 7.0 and dist > 3.5 and dist < 11.0:
				_special_t = 0.0
				_knock = facing * 9.0
				_hint70("Gorgoth baisse les cornes… et charge !")
			if _phase70 == 0 and hp < pv / 2:
				_phase70 = 1
				_hint70("« Pas mal, petit ! Mais Gorgoth n'a pas encore sorti ses plus belles cornes ! »")
		"titan_givre":
			if _special_t > 7.0 and dist < 7.0:
				_special_t = 0.0
				_shockwave(global_position + facing * 2.0)
				_hint70("Le Titan frappe la glace de sa massue : le lac tremble !")
			elif _special_t > 4.0 and _special_t < 4.05 and dist < 9.0:
				_fire_cone(8.0, 0.6)
				_hint70("Le Titan souffle un vent de givre !")
			if (_phase70 == 0 and hp < pv * 2 / 3) or (_phase70 == 1 and hp < pv / 3):
				_phase70 += 1
				for k in range(2):
					var a: float = TAU * k / 2.0 + randf()
					var m: Node3D = manager.spawn_extra("spectre_givre", global_position + Vector3(cos(a) * 5.0, 0.1, sin(a) * 5.0))
					m.home = m.global_position
				_hint70("Le Titan rugit : des spectres de givre se lèvent du lac !")


## Une gerbe (feu ou givre) devant la bête : touché si l'on est dans le cône.
func _fire_cone(reach: float, cosmin: float) -> void:
	for b in _breaths:
		(b as CPUParticles3D).restart()
		(b as CPUParticles3D).emitting = true
	if manager.main.has_method("sfx"):
		manager.main.sfx("feu_souffle" if kind != "titan_givre" else "souffle_givre", global_position + Vector3.UP * hit_height * 2.0)
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	var to: Vector3 = p - global_position
	to.y = 0.0
	if to.length() < reach and to.normalized().dot(facing) > cosmin:
		manager.hurt_player(1, global_position)


func _hint70(t: String) -> void:
	if _clock - _last_hint < 3.0:
		return
	_last_hint = _clock
	if manager != null and manager.donjon != null:
		manager.donjon._say(t, 3.5)


func _puff_color() -> Color:
	match kind:
		"diablotin":
			return Color(0.9, 0.3, 0.15)
		"chien_enfer", "cerbere":
			return Color(1.0, 0.5, 0.15)
		"gorgoth":
			return Color(0.9, 0.75, 0.5)
		"ombre":
			return Color(0.25, 0.15, 0.35)
		"furie":
			return Color(0.6, 0.15, 0.15)
		"spectre_givre", "titan_givre":
			return Color(0.75, 0.9, 1.0)
	return super._puff_color()


func _death_tick(delta: float) -> void:
	if not SPECS70.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	match kind:
		"chien_enfer", "cerbere":
			_visual.rotation.z = minf(timer * 3.0, PI * 0.5)
		"diablotin", "spectre_givre":
			if _body_node != null:
				_body_node.position.y = maxf(_body_node.position.y - delta * 2.0, 0.1)
		"titan_givre":
			# il se fige, se fendille, et vole en éclats
			if timer > 1.2 and not has_meta("brise"):
				set_meta("brise", true)
				if manager.main.combat_v28 != null:
					for k in range(10):
						manager.main.combat_v28.puff(global_position + Vector3(randf_range(-1, 1), randf_range(0.5, 4.0), randf_range(-1, 1)), Color(0.8, 0.95, 1.0))
				if manager.main.has_method("sfx"):
					manager.main.sfx("glace_craque", global_position + Vector3.UP * 2.0)
	if timer > 2.0:
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 2.0) / 0.8, 0.01, 1.0)
	if timer > 2.8:
		visible = false
		set_physics_process(false)


func _animate63(delta: float, speed: float) -> void:
	if not SPECS70.has(kind):
		super._animate63(delta, speed)
		return
	var moving: bool = speed > 0.2
	var dive: float = 0.0
	if state == "armer":
		dive = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	elif state == "frappe":
		dive = 1.0
	match kind:
		"diablotin":
			if _body_node != null:
				_body_node.position.y = lerpf(_body_node.position.y, 0.55 + sin(_clock * 6.0) * 0.08 + (0.25 if moving else 0.0) - dive * 0.3, clampf(delta * 6.0, 0.0, 1.0))
				_body_node.rotation.x = lerpf(_body_node.rotation.x, 0.35 if moving else 0.0, clampf(delta * 5.0, 0.0, 1.0))
			for w in _wings:
				(w[0] as Node3D).rotation.y = float(w[1]) * sin(_clock * 22.0) * 0.6
			for l in _legs:
				(l[0] as Node3D).rotation.x = sin(_clock * 10.0 + float(l[1]) * 1.5) * 0.3
			for t in _tail:
				(t[0] as Node3D).rotation.y = sin(_clock * 3.0) * 0.4
		"chien_enfer", "cerbere":
			var walk: float = _clock * (8.0 + speed * 3.0)
			for l2 in _legs:
				var leg: Node3D = l2[0]
				var ph: float = (0.0 if float(l2[1]) > 0.0 else PI) + (0.0 if float(l2[2]) > 0.0 else PI * 0.5)
				leg.rotation.x = sin(walk + ph) * (0.6 if moving else 0.04)
			for i in range(_tail.size()):
				var seg: Node3D = _tail[i][0]
				seg.rotation.x = 0.35 + sin(_clock * 2.0 - i * 0.5) * 0.1
				seg.rotation.y = sin(_clock * (6.0 if moving else 1.5) - i * 0.6) * (0.3 if not asleep else 0.05)
			var s: float = 1.0 if kind == "chien_enfer" else 2.0
			if _cat_body != null:
				var low: float = 0.25 if asleep else dive * 0.12
				_cat_body.position.y = lerpf(_cat_body.position.y, (0.55 - low) * s, clampf(delta * 6.0, 0.0, 1.0))
			for i2 in range(_heads.size()):
				var h: Array = _heads[i2]
				var head: Node3D = h[0]
				var jaw: Node3D = h[1]
				head.rotation.y = sin(_clock * 0.9 + i2 * 2.1) * (0.25 if not asleep else 0.05)
				head.rotation.x = 0.35 if asleep else sin(_clock * 1.3 + i2) * 0.08
				var open: float = 0.05
				if asleep:
					open = 0.08 + 0.05 * sin(_clock * 1.5 + i2)
				elif state in ["armer", "frappe"]:
					open = 0.5
				jaw.rotation.x = lerpf(jaw.rotation.x, open, clampf(delta * 12.0, 0.0, 1.0))
			if kind == "chien_enfer" and state == "armer" and dive > 0.6:
				for b in _breaths:
					if not (b as CPUParticles3D).emitting:
						(b as CPUParticles3D).restart()
						(b as CPUParticles3D).emitting = true
		"gorgoth", "ombre", "furie", "titan_givre":
			if _anim != null and not (state in ["armer", "frappe", "mort", "recul", "rendu"]):
				if moving:
					_play("Walking", 0.2, maxf(speed / (1.1 if kind != "titan_givre" else 2.4), 0.5))
				else:
					_play("v28/idle", 0.3)
			if kind == "furie":
				_visual.position.y = lerpf(_visual.position.y, 0.9 + sin(_clock * 2.5) * 0.15 - dive * 0.8, clampf(delta * 5.0, 0.0, 1.0))
				for w2 in _wings:
					(w2[0] as Node3D).rotation.y = float(w2[1]) * (0.2 + sin(_clock * (9.0 if dive > 0.0 else 3.0)) * 0.35)
			elif kind == "ombre":
				_visual.position.y = 0.12 + sin(_clock * 1.4) * 0.06
			elif kind == "titan_givre" and moving:
				_step_t -= delta
				if _step_t <= 0.0:
					_step_t = 0.9
					if manager.main.has_method("sfx"):
						manager.main.sfx("titan_pas", global_position)
		"spectre_givre":
			if _body_node != null:
				_body_node.position.y = lerpf(_body_node.position.y, 0.25 + sin(_clock * 1.7) * 0.12 - dive * 0.15, clampf(delta * 5.0, 0.0, 1.0))
			if _shards != null:
				_shards.rotation.y += delta * 1.6
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


## Le butin (monstres_v36._on_died).
func loot(rng: RandomNumberGenerator) -> Array:
	match kind:
		"diablotin":
			var g: Array = [["piece", rng.randi_range(1, 4)]]
			if rng.randf() < 0.25:
				g.append(["piment_infernal", 1])
			return g
		"chien_enfer":
			var g2: Array = [["piece", rng.randi_range(2, 5)]]
			if rng.randf() < 0.3:
				g2.append(["croc_cerbere", 1])
			return g2
		"gorgoth":
			return [["piece", rng.randi_range(30, 40)]]
		"ombre":
			return [["piece", rng.randi_range(1, 3)]]
		"furie":
			return [["piece", rng.randi_range(3, 6)], ["plume_furie", 1]]
		"spectre_givre":
			var g3: Array = [["piece", rng.randi_range(2, 4)]]
			if rng.randf() < 0.35:
				g3.append(["eclat_givre", 1])
			return g3
		"cerbere":
			return [["piece", rng.randi_range(25, 35)], ["croc_cerbere", 1]]
		"titan_givre":
			return [["piece", rng.randi_range(50, 70)], ["piece_or", 3], ["eclat_givre", 3]]
	return super.loot(rng)


func alert_text() -> String:
	match kind:
		"diablotin":
			return "Des diablotins ! Ils ricanent, voltigent… et foncent la fourche en avant. Écarte-toi quand ils se ramassent, puis frappe-les."
		"chien_enfer":
			return "Des chiens d'enfer ! Quand la gueule s'ouvre et rougeoie, ils vont cracher le feu et bondir : écarte-toi, puis frappe."
		"gorgoth":
			return "GORGOTH LE CORNU, le champion de l'arène ! Il charge cornes baissées : écarte-toi au dernier moment, frappe-le dans le dos. La foule hurle !"
		"ombre":
			return "Des ombres… Elles glissent sans bruit dans la pénombre des Limbes. Elles ne sont pas bien solides : frappe-les quand elles tendent les bras."
		"furie":
			return "Les Furies ! Elles planent au-dessus de la porte de Dité, puis piquent sur toi. Écarte-toi quand elles plongent, frappe quand elles remontent."
		"cerbere":
			return "CERBÈRE ! Trois têtes, trois gueules de feu. On dit qu'il ne résiste pas aux gâteaux de miel… un par tête."
		"spectre_givre":
			return "Des spectres de givre ! Leur souffle gèle : quand ils se penchent vers toi, écarte-toi, puis frappe-les."
		"titan_givre":
			return "LE TITAN DE GIVRE ! Il garde la Flamme Éternelle au fond du Cocyte. Méfie-toi de sa massue et de son souffle glacé ; frappe-le quand il se relève."
	return super.alert_text()

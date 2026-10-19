extends CharacterBody3D
## V36 : un monstre du Temple englouti. Il suit la règle des cibles de combat
## (groupe « cibles_v28 », hit_radius, hit_height, is_hittable, take_hit).
## Deux espèces pour commencer :
##  - le crabe de roche : bas, rapide, pinces levées avant de frapper (1/2 cœur) ;
##  - le gardien de corail : un ancien soldat du temple pétrifié, lent, frappe fort (1 cœur)
##    avec sa lance après l'avoir levée ;
##  - V39 : la vipère des abysses : longue, noire, striée de vert ; elle se love, relève la
##    tête… puis bondit droit devant (1/2 cœur). On l'évite en s'écartant de sa trajectoire.
##  - V44 : le feu follet (Royaume des Racines) : une flamme bleue qui flotte, ricane, se met
##    à briller très fort… puis fonce droit sur le joueur (1/2 cœur) ;
##  - V44 : l'araignée de cristal : rapide, huit pattes de verre, mord quand elle se dresse.
##  - V54 : l'armure animée (Citadelle des Nuées) : une armure de chevalier vide, épée et écu,
##    une lueur bleue dans le heaume ; elle lève l'épée avant de frapper (1 cœur) ;
##  - V54 : la gargouille : une statue de pierre ailée qui plane, ricane, puis pique droit sur
##    le joueur (1/2 cœur).
## Comportement : il veille près de son poste, repère le joueur à quelques mètres, le
## poursuit sans trop s'éloigner, prépare son coup (le signal pour esquiver ou parer), frappe,
## souffle un instant. Touché, il recule et clignote ; à zéro, il s'effondre et laisse du butin.

const HeroLib = preload("res://scripts/hero_v28.gd")

const SPECS := {
	"crabe": {"pv": 8, "vitesse": 2.3, "degats": 1, "portee": 1.15, "armer": 0.55, "repos": 1.3, "vue": 9.0, "laisse": 12.0,
		"rayon": 0.5, "haut": 0.3, "nom": "Crabe de roche"},
	"gardien": {"pv": 22, "vitesse": 1.5, "degats": 2, "portee": 1.9, "armer": 0.85, "repos": 1.6, "vue": 11.0, "laisse": 13.0,
		"rayon": 0.38, "haut": 1.0, "nom": "Gardien de corail"},
	"vipere": {"pv": 12, "vitesse": 2.7, "degats": 1, "portee": 2.1, "armer": 0.6, "repos": 1.4, "vue": 9.0, "laisse": 12.0,
		"rayon": 0.6, "haut": 0.3, "nom": "Vipère des abysses"},
	# V44 : les créatures du Royaume des Racines
	"follet": {"pv": 6, "vitesse": 2.4, "degats": 1, "portee": 2.4, "armer": 0.75, "repos": 1.7, "vue": 10.0, "laisse": 14.0,
		"rayon": 0.4, "haut": 1.3, "nom": "Feu follet"},
	"araignee": {"pv": 10, "vitesse": 2.9, "degats": 1, "portee": 1.2, "armer": 0.5, "repos": 1.1, "vue": 9.0, "laisse": 12.0,
		"rayon": 0.55, "haut": 0.35, "nom": "Araignée de cristal"},
	# V47 : les créatures de la Montagne de Feu
	"golem": {"pv": 34, "vitesse": 1.2, "degats": 2, "portee": 2.2, "armer": 1.0, "repos": 2.0, "vue": 12.0, "laisse": 9.0,
		"rayon": 0.7, "haut": 1.2, "nom": "Golem des hauteurs"},
	"magma": {"pv": 14, "vitesse": 2.0, "degats": 2, "portee": 2.2, "armer": 0.7, "repos": 1.5, "vue": 10.0, "laisse": 10.0,
		"rayon": 0.5, "haut": 0.6, "nom": "Élémentaire de magma"},
	# V54 : les gardiens de la Citadelle des Nuées
	"armure": {"pv": 30, "vitesse": 1.7, "degats": 2, "portee": 2.0, "armer": 0.8, "repos": 1.5, "vue": 12.0, "laisse": 14.0,
		"rayon": 0.42, "haut": 1.0, "nom": "Armure animée"},
	"gargouille": {"pv": 12, "vitesse": 2.6, "degats": 1, "portee": 2.6, "armer": 0.8, "repos": 1.7, "vue": 13.0, "laisse": 16.0,
		"rayon": 0.55, "haut": 1.6, "nom": "Gargouille"},
}

signal died(monster: Node3D)

var manager: Node
var kind: String = "crabe"
var spec: Dictionary
var home: Vector3
var hp: int = 8
var state: String = "veille"        # veille, chasse, armer, frappe, souffle, recul, mort
var timer: float = 0.0
var hit_radius: float = 0.5
var hit_height: float = 0.3
var facing: Vector3 = Vector3.FORWARD
var _visual: Node3D
var _claws: Array = []
var _legs: Array = []
var _spear: Node3D
var _anim: AnimationPlayer
var _flash: float = 0.0
var _flash_mats: Array = []
var _clock: float = 0.0
var _knock: Vector3 = Vector3.ZERO
var _segments: Array = []               # V39 : anneaux du corps de la vipère (de la tête à la queue)
var _arms: Array = []                   # V47 : bras du golem
var _magma_core: StandardMaterial3D
var _magma_light: OmniLight3D


func setup(m: Node, k: String, at: Vector3) -> void:
	manager = m
	kind = k
	spec = SPECS[k]
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	if kind == "follet" or kind == "gargouille":
		var sph := SphereShape3D.new()
		sph.radius = 0.32 if kind == "follet" else 0.5
		cs.shape = sph
		cs.position.y = 1.3 if kind == "follet" else 1.6
	elif kind == "crabe" or kind == "araignee":
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, 0.5, 0.7)
		cs.shape = box
		cs.position.y = 0.3
	elif kind == "golem":
		var gc := CapsuleShape3D.new()
		gc.radius = 0.62
		gc.height = 2.5
		cs.shape = gc
		cs.position.y = 1.25
	elif kind == "magma":
		var ms := SphereShape3D.new()
		ms.radius = 0.45
		cs.shape = ms
		cs.position.y = 0.5
	elif kind == "vipere":
		var vb := BoxShape3D.new()
		vb.size = Vector3(0.5, 0.36, 1.3)
		cs.shape = vb
		cs.position = Vector3(0, 0.2, 0.1)
	else:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.32
		cap.height = 1.75
		cs.shape = cap
		cs.position.y = 0.88
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	if kind == "crabe":
		_build_crab()
	elif kind == "follet":
		_build_wisp()
	elif kind == "araignee":
		_build_spider()
	elif kind == "vipere":
		_build_viper()
	elif kind == "golem":
		_build_golem()
	elif kind == "magma":
		_build_magma()
	elif kind == "gargouille":
		_build_gargoyle()
	elif kind == "armure":
		_build_armor()
	else:
		_build_guardian()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


func _mat(c: Color, rough: float = 0.6, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_flash_mats.append(m)
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _cyl(a: float, b: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = 8
	return c


## Crabe de roche : carapace bosselée couleur de pierre et de rouille, six pattes, deux pinces.
func _build_crab() -> void:
	var shell := _mat(Color(0.66, 0.34, 0.2), 0.5)
	var belly := _mat(Color(0.7, 0.55, 0.42), 0.7)
	var rock := _mat(Color(0.45, 0.43, 0.4), 0.9)
	_mesh(_visual, _sphere(0.45), shell, Vector3(0, 0.38, 0), Vector3(1.0, 0.42, 0.78))
	_mesh(_visual, _sphere(0.4), belly, Vector3(0, 0.3, 0), Vector3(0.95, 0.3, 0.72))
	for k in range(5):
		_mesh(_visual, _sphere(0.09), rock, Vector3(-0.25 + k * 0.13, 0.52, -0.05 + (k % 2) * 0.12), Vector3(1, 0.6, 1))
	for sx in [-1.0, 1.0]:
		var stalk := _mesh(_visual, _cyl(0.02, 0.025, 0.16), shell, Vector3(sx * 0.1, 0.55, 0.28))
		stalk.rotation.x = 0.3
		_mesh(_visual, _sphere(0.04), _mat(Color(0.05, 0.05, 0.05), 0.2, 0.0), Vector3(sx * 0.1, 0.64, 0.31))
		for k in range(3):
			var leg := Node3D.new()
			leg.position = Vector3(sx * 0.38, 0.32, 0.18 - k * 0.2)
			_visual.add_child(leg)
			# Patte : vers l'extérieur et vers le bas, jusqu'au sol.
			var seg := _mesh(leg, _cyl(0.025, 0.04, 0.46), shell, Vector3(sx * 0.19, -0.11, 0))
			seg.rotation.z = -sx * 2.04
			_legs.append([leg, sx, k])
		var arm := Node3D.new()
		arm.position = Vector3(sx * 0.3, 0.42, 0.3)
		_visual.add_child(arm)
		_mesh(arm, _cyl(0.045, 0.05, 0.3), shell, Vector3(0, 0.0, 0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(arm, _sphere(0.13), shell, Vector3(0, 0.02, 0.36), Vector3(0.8, 0.7, 1.3))
		_mesh(arm, _cyl(0.0, 0.06, 0.2), shell, Vector3(sx * 0.04, 0.07, 0.5), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_claws.append(arm)


## V39 : vipère des abysses : 22 anneaux qui s'affinent, tête en losange, yeux verts,
## stries luisantes sur le dos.
func _build_viper() -> void:
	var skin := _mat(Color(0.05, 0.06, 0.055), 0.28)
	var stripe := _mat(Color(0.2, 0.8, 0.42), 0.3, 1.1)
	var eye := _mat(Color(0.5, 1.0, 0.6), 0.2, 4.0)
	for k in range(22):
		var t: float = float(k) / 21.0
		var seg := Node3D.new()
		seg.position = Vector3(0, 0.12, 0.55 - k * 0.1)
		_visual.add_child(seg)
		var r: float = 0.12 - t * 0.085 + (0.015 if k < 3 else 0.0)
		_mesh(seg, _sphere(r), skin, Vector3.ZERO, Vector3(1.0, 0.8, 1.4))
		if k % 3 == 1 and k < 18:
			_mesh(seg, _sphere(r * 0.35), stripe, Vector3(0, r * 0.75, 0), Vector3(1.6, 0.4, 0.8))
		_segments.append(seg)
	var head: Node3D = _segments[0]
	_mesh(head, _sphere(0.15), skin, Vector3(0, 0.03, 0.14), Vector3(1.05, 0.55, 1.35))
	for sx in [-1.0, 1.0]:
		_mesh(head, _sphere(0.032), eye, Vector3(sx * 0.08, 0.08, 0.2))
	var tongue := _mat(Color(0.75, 0.1, 0.15), 0.4)
	_mesh(head, _cyl(0.004, 0.008, 0.12), tongue, Vector3(0, 0.0, 0.36), Vector3.ONE, Vector3(PI * 0.5, 0, 0))


## V44 : feu follet : un cœur de flamme bleue, un halo, deux yeux rieurs, des étincelles.
var _wisp_light: OmniLight3D
var _wisp_core: StandardMaterial3D
func _build_wisp() -> void:
	var body := Node3D.new()
	body.name = "Flamme"
	body.position = Vector3(0, 1.3, 0)
	_visual.add_child(body)
	_wisp_core = _mat(Color(0.45, 0.85, 1.0), 0.2, 3.0)
	_mesh(body, _sphere(0.16), _wisp_core, Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
	_mesh(body, _cyl(0.0, 0.12, 0.3), _wisp_core, Vector3(0, 0.22, -0.02), Vector3.ONE, Vector3(-0.3, 0, 0))
	var eye := _mat(Color(0.02, 0.05, 0.12), 0.3)
	for sx in [-1.0, 1.0]:
		_mesh(body, _sphere(0.03), eye, Vector3(sx * 0.06, 0.03, 0.14), Vector3(1.0, 1.3, 0.6))
	var halo := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(0.4, 0.8, 1.0, 0.55)
	hm.albedo_texture = manager.main._soft_dot_v24()
	q.material = hm
	halo.mesh = q
	body.add_child(halo)
	_wisp_light = OmniLight3D.new()
	_wisp_light.light_color = Color(0.45, 0.85, 1.0)
	_wisp_light.light_energy = 1.2
	_wisp_light.omni_range = 5.0
	body.add_child(_wisp_light)
	var sp := CPUParticles3D.new()
	sp.amount = 14
	sp.lifetime = 0.9
	sp.local_coords = false
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.12
	sp.gravity = Vector3(0, 0.8, 0)
	sp.initial_velocity_min = 0.1
	sp.initial_velocity_max = 0.4
	var pq := QuadMesh.new()
	pq.size = Vector2(0.06, 0.06)
	var pm := hm.duplicate() as StandardMaterial3D
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pm.albedo_color = Color(0.6, 0.9, 1.0, 0.9)
	pq.material = pm
	sp.mesh = pq
	body.add_child(sp)


## V44 : araignée de cristal : abdomen et tête en verre rose, huit pattes à genoux hauts.
func _build_spider() -> void:
	var glass := _mat(Color(0.85, 0.5, 0.9), 0.15, 0.9)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.85
	var dark := _mat(Color(0.25, 0.12, 0.3), 0.3)
	var eye := _mat(Color(1.0, 0.3, 0.5), 0.2, 3.0)
	var abd := SphereMesh.new()
	abd.radius = 0.24
	abd.height = 0.48
	abd.radial_segments = 6
	abd.rings = 4
	_mesh(_visual, abd, glass, Vector3(0, 0.36, -0.22), Vector3(1.0, 0.85, 1.25))
	_mesh(_visual, _sphere(0.13), glass, Vector3(0, 0.33, 0.14), Vector3(1.0, 0.8, 1.0))
	for k in range(4):
		_mesh(_visual, _sphere(0.025), eye, Vector3((k % 2 - 0.5) * 0.08, 0.4 + (k / 2) * 0.04, 0.25))
	for k in range(4):
		_mesh(_visual, _cyl(0.0, 0.05, 0.16), glass, Vector3((k - 1.5) * 0.08, 0.6, -0.25), Vector3.ONE, Vector3(0, 0, (k - 1.5) * 0.3))
	for sx in [-1.0, 1.0]:
		for k in range(4):
			var leg := Node3D.new()
			leg.position = Vector3(sx * 0.1, 0.34, 0.12 - k * 0.1)
			leg.rotation.y = sx * (0.3 - k * 0.35)
			_visual.add_child(leg)
			_mesh(leg, _cyl(0.018, 0.022, 0.32), dark, Vector3(sx * 0.15, 0.08, 0), Vector3.ONE, Vector3(0, 0, sx * -1.1))
			_mesh(leg, _cyl(0.008, 0.018, 0.42), glass, Vector3(sx * 0.36, -0.1, 0), Vector3.ONE, Vector3(0, 0, sx * 0.55))
			_legs.append([leg, sx, k])


## V47 : golem des hauteurs — un amas de blocs de basalte, une rune bleue sur le torse, des
## yeux bleus ; il lève ses deux poings au-dessus de la tête avant d'écraser le sol.
func _build_golem() -> void:
	var rock: StandardMaterial3D = _mat(Color(0.62, 0.58, 0.56), 0.95)
	rock.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
	rock.uv1_triplanar = true
	rock.uv1_scale = Vector3(0.8, 0.8, 0.8)
	var moss := _mat(Color(0.25, 0.22, 0.18), 0.95)
	var rune := _mat(Color(0.35, 0.8, 1.0), 0.2, 3.0)
	var Rk = load("res://scripts/rocks_v26.gd")
	_mesh(_visual, Rk.shape(4800, Vector3(1.4, 1.3, 1.0), 0.7, 0.18), rock, Vector3(0, 1.75, 0))
	_mesh(_visual, Rk.shape(4801, Vector3(1.0, 0.7, 0.8), 0.7, 0.18), rock, Vector3(0, 1.05, 0.02))
	_mesh(_visual, Rk.shape(4802, Vector3(0.6, 0.55, 0.55), 0.7, 0.15), rock, Vector3(0, 2.62, 0.08))
	_mesh(_visual, _sphere(0.25), moss, Vector3(0.3, 2.35, -0.3), Vector3(1.4, 0.4, 1.0))
	for sx in [-1.0, 1.0]:
		_mesh(_visual, _sphere(0.055), rune, Vector3(sx * 0.13, 2.66, 0.33), Vector3(1.3, 0.8, 0.5))
	_mesh(_visual, _cyl(0.05, 0.05, 0.5), rune, Vector3(0, 1.85, 0.52), Vector3.ONE, Vector3(0, 0, 0))
	_mesh(_visual, _cyl(0.04, 0.04, 0.35), rune, Vector3(0, 1.95, 0.52), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	# Des fissures de lave entre les blocs, devant et derrière
	var crack := _mat(Color(1.0, 0.42, 0.1), 0.4, 2.5)
	for k in range(6):
		var fz: float = 0.5 if k < 3 else -0.5
		_mesh(_visual, _box_mesh_g(Vector3(0.05, 0.4 + 0.15 * (k % 3), 0.04)), crack, Vector3(-0.35 + (k % 3) * 0.35, 1.5 + (k % 2) * 0.35, fz), Vector3.ONE, Vector3(0, 0, 0.4 * ((k % 3) - 1)))
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx * 0.32, 0.8, 0)
		_visual.add_child(leg)
		_mesh(leg, Rk.shape(4803, Vector3(0.45, 0.85, 0.5), 0.8, 0.15), rock, Vector3(0, -0.38, 0))
		_legs.append([leg, sx, 0])
		var arm := Node3D.new()
		arm.position = Vector3(sx * 0.82, 2.1, 0)
		_visual.add_child(arm)
		_mesh(arm, Rk.shape(4805, Vector3(0.42, 0.9, 0.42), 0.8, 0.15), rock, Vector3(sx * 0.05, -0.45, 0))
		_mesh(arm, Rk.shape(4806, Vector3(0.6, 0.55, 0.6), 0.75, 0.18), rock, Vector3(sx * 0.06, -1.05, 0.05))
		_arms.append([arm, sx])
	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 0.8, 1.0)
	l.light_energy = 0.8
	l.omni_range = 4.0
	l.position = Vector3(0, 2.0, 0.8)
	_visual.add_child(l)


static var _magma_sh: Shader


static func _magma_shader() -> Shader:
	if _magma_sh != null:
		return _magma_sh
	_magma_sh = Shader.new()
	_magma_sh.code = """shader_type spatial;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { lp = VERTEX; }
void fragment() {
	float t = TIME * 0.6;
	vec3 q = lp * 7.0 + vec3(0.0, -t, t * 0.4);
	float a = n3(q) * 0.65 + n3(q * 2.1 + 3.0) * 0.35;
	float crust = smoothstep(0.42, 0.6, a);
	vec3 hot = mix(vec3(1.0, 0.75, 0.2), vec3(0.9, 0.22, 0.02), smoothstep(0.2, 0.45, a));
	ALBEDO = mix(hot * 0.25, vec3(0.05, 0.035, 0.03), crust);
	EMISSION = hot * (1.0 - crust) * 1.6;
	ROUGHNESS = mix(0.35, 0.9, crust);
}
"""
	return _magma_sh


## V50 : le cri de chaque espèce (menace avant l'attaque, mort).
const SOUNDS := {
	"crabe": ["crabe_menace", "crabe_mort"], "araignee": ["insecte_menace", "insecte_mort"],
	"vipere": ["serpent_menace", "monstre_mort"], "follet": ["follet_menace", "follet_mort"],
	"golem": ["golem_menace", "golem_mort"], "magma": ["magma_menace", "magma_mort"],
	"armure": ["armure_menace", "armure_mort"], "gargouille": ["gargouille_menace", "gargouille_mort"],
}

func _sound(what: String) -> void:
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS.get(kind, ["monstre_menace", "monstre_mort"])
	manager.main.sfx(str(pair[0] if what == "menace" else pair[1]), global_position + Vector3.UP * hit_height)


func _box_mesh_g(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## V47 : élémentaire de magma — une boule de lave qui bouillonne, une croûte noire qui
## flotte autour, deux yeux blancs ; il se gonfle, puis bondit sur sa proie.
func _build_magma() -> void:
	_magma_core = _mat(Color(0.55, 0.1, 0.01), 0.35, 0.9)
	_magma_core.emission = Color(1.0, 0.32, 0.03)
	_magma_core.emission_enabled = true
	# La surface qui bouillonne : un shader de lave (croûte sombre, veines incandescentes)
	var lava_sm := ShaderMaterial.new()
	lava_sm.shader = _magma_shader()
	var crust := _mat(Color(0.12, 0.08, 0.07), 0.8)
	var body := Node3D.new()
	body.name = "Flamme"
	body.position = Vector3(0, 0.55, 0)
	_visual.add_child(body)
	_mesh(body, _sphere(0.42), lava_sm, Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
	# Plaques de croûte noire, irrégulières, sauf sur le visage
	var rngp := RandomNumberGenerator.new()
	rngp.seed = 4810 + get_instance_id() % 97
	for k in range(13):
		var yk: float = 1.0 - (k + 0.5) / 13.0 * 2.0 + rngp.randf_range(-0.08, 0.08)
		var rk: float = sqrt(maxf(1.0 - yk * yk, 0.0))
		var a: float = k * 2.39996 + rngp.randf_range(-0.3, 0.3)
		var dirk := Vector3(cos(a) * rk, yk, sin(a) * rk).normalized()
		if dirk.z > 0.55 and absf(dirk.y) < 0.6:
			continue
		var sz: float = rngp.randf_range(0.1, 0.19)
		var plate := _mesh(body, _sphere(sz), crust, dirk * 0.38)
		plate.transform = Transform3D(Basis.looking_at(dirk, Vector3.UP if absf(dirk.y) < 0.95 else Vector3.RIGHT) * Basis.from_euler(Vector3(0, 0, rngp.randf() * TAU)) * Basis.from_scale(Vector3(1.0, rngp.randf_range(0.6, 1.0), 0.35)), dirk * 0.38)
	var eye := _mat(Color(1.0, 1.0, 0.85), 0.2, 4.0)
	for sx in [-1.0, 1.0]:
		_mesh(body, _sphere(0.06), eye, Vector3(sx * 0.13, 0.1, 0.38), Vector3(1.0, 0.6, 0.5))
	_magma_light = OmniLight3D.new()
	_magma_light.light_color = Color(1.0, 0.5, 0.15)
	_magma_light.light_energy = 1.6
	_magma_light.omni_range = 5.0
	body.add_child(_magma_light)
	var sp := CPUParticles3D.new()
	sp.amount = 16
	sp.lifetime = 0.8
	sp.local_coords = false
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.35
	sp.gravity = Vector3(0, 1.5, 0)
	sp.initial_velocity_min = 0.2
	sp.initial_velocity_max = 0.6
	var pq := QuadMesh.new()
	pq.size = Vector2(0.09, 0.09)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
	pm.albedo_texture = manager.main._soft_dot_v24()
	pq.material = pm
	sp.mesh = pq
	body.add_child(sp)


## Gardien de corail : le corps du héros, couleur pierre bleutée, coraux et lance, yeux luisants.
func _build_guardian() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	_visual.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = found[0] if found.size() > 0 else null
	if _anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = _anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in range(m.mesh.get_surface_count()):
			var src: Material = m.mesh.surface_get_material(s)
			if src is StandardMaterial3D:
				# Pétrifié : toute la silhouette du soldat devient pierre bleutée.
				var stone := StandardMaterial3D.new()
				stone.albedo_color = Color(0.74, 0.78, 0.8)
				stone.roughness = 0.92
				# Une très légère lueur : on devine sa silhouette dans la pénombre.
				stone.emission_enabled = true
				stone.emission = Color(0.16, 0.22, 0.24)
				stone.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
				stone.uv1_scale = Vector3(3, 3, 3)
				m.set_surface_override_material(s, stone)
				_flash_mats.append(stone)
	var coral := _mat(Color(0.95, 0.45, 0.42), 0.7, 0.25)
	var eye := _mat(Color(0.4, 1.0, 0.95), 0.2, 4.0)
	if skel != null:
		_attach(skel, "Head", Vector3(0, 30, 10), _coral_tuft(coral))
		_attach(skel, "LeftShoulder", Vector3(14, 8, 0), _coral_tuft(coral))
		var eyes := Node3D.new()
		for sx in [-0.07, 0.07]:
			_mesh(eyes, _sphere(0.03), eye, Vector3(sx, 0, 0))
		_attach(skel, "Head", Vector3(0, 19, 19), eyes)
		_spear = Node3D.new()
		_mesh(_spear, _cyl(0.025, 0.025, 2.0), _mat(Color(0.35, 0.3, 0.25), 0.8), Vector3(0, 0.3, 0))
		_mesh(_spear, _cyl(0.0, 0.06, 0.3), _mat(Color(0.55, 0.45, 0.3), 0.3), Vector3(0, 1.45, 0))
		var att := BoneAttachment3D.new()
		att.bone_name = "RightHand"
		skel.add_child(att)
		var hold := Node3D.new()
		hold.position = Vector3(0, 8.5, 2.5)
		hold.rotation_degrees = Vector3(90, 0, 0)
		hold.scale = Vector3.ONE * 100.0
		att.add_child(hold)
		hold.add_child(_spear)
	_play("v28/idle")


## V54 : armure animée — la silhouette du héros en acier poli, heaume à cimier bleu, une lueur
## bleue derrière la visière, épée longue et écu à l'aigle d'argent.
func _build_armor() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.08
	_visual.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = found[0] if found.size() > 0 else null
	if _anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = _anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.62, 0.64, 0.68)
	steel.metallic = 0.85
	steel.roughness = 0.32
	steel.albedo_texture = load("res://assets/textures/terrain/rock.jpg")
	steel.uv1_scale = Vector3(4, 4, 4)
	_flash_mats.append(steel)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for k in range(m.mesh.get_surface_count()):
			m.set_surface_override_material(k, steel)
	var blue := _mat(Color(0.15, 0.25, 0.6), 0.8)
	var glow := _mat(Color(0.5, 0.8, 1.0), 0.2, 4.0)
	var dark := _mat(Color(0.05, 0.05, 0.06), 0.6)
	if skel != null:
		# Heaume : calotte, visière fendue, cimier
		var helm := Node3D.new()
		_mesh(helm, _sphere(0.17), steel, Vector3(0, 0.02, 0), Vector3(1.0, 1.15, 1.05))
		_mesh(helm, _box_mesh_g(Vector3(0.22, 0.03, 0.04)), dark, Vector3(0, 0.02, 0.17))
		for sx in [-0.05, 0.05]:
			_mesh(helm, _sphere(0.018), glow, Vector3(sx, 0.02, 0.16))
		_mesh(helm, _box_mesh_g(Vector3(0.03, 0.12, 0.3)), blue, Vector3(0, 0.2, -0.02))
		_attach(skel, "Head", Vector3(0, 12, 2), helm)
		# Épaulières
		for side in [["LeftShoulder", -1.0], ["RightShoulder", 1.0]]:
			var pad := Node3D.new()
			_mesh(pad, _sphere(0.11), steel, Vector3.ZERO, Vector3(1.3, 0.7, 1.2))
			_attach(skel, str(side[0]), Vector3(float(side[1]) * 10.0, 6, 0), pad)
		# L'épée longue
		_spear = Node3D.new()
		_mesh(_spear, _box_mesh_g(Vector3(0.07, 1.25, 0.018)), steel, Vector3(0, 0.78, 0))
		_mesh(_spear, _box_mesh_g(Vector3(0.36, 0.05, 0.06)), dark, Vector3(0, 0.14, 0))
		_mesh(_spear, _cyl(0.025, 0.025, 0.25), blue, Vector3(0, 0.0, 0))
		var att := BoneAttachment3D.new()
		att.bone_name = "RightHand"
		skel.add_child(att)
		var hold := Node3D.new()
		hold.position = Vector3(0, 8.5, 2.5)
		hold.rotation_degrees = Vector3(90, 0, 0)
		hold.scale = Vector3.ONE * 100.0
		att.add_child(hold)
		hold.add_child(_spear)
		# L'écu, à l'aigle d'argent sur fond bleu
		var shield := Node3D.new()
		_mesh(shield, _box_mesh_g(Vector3(0.42, 0.55, 0.05)), blue, Vector3.ZERO)
		_mesh(shield, _box_mesh_g(Vector3(0.46, 0.04, 0.06)), steel, Vector3(0, 0.27, 0))
		_mesh(shield, _sphere(0.08), steel, Vector3(0, 0.02, 0.04), Vector3(1.6, 1.0, 0.4))
		_attach(skel, "LeftForeArm", Vector3(0, 12, 6), shield)
	_play("v28/idle")


## V54 : gargouille — statue de pierre grise : corps trapu, cornes, ailes de chauve-souris,
## yeux qui rougeoient ; elle plane à hauteur d'homme.
func _build_gargoyle() -> void:
	var body := Node3D.new()
	body.name = "Corps"
	body.position = Vector3(0, 1.75, 0)
	_visual.add_child(body)
	var stone := _mat(Color(0.55, 0.55, 0.53), 0.95)
	stone.albedo_texture = load("res://assets/textures/chateau/pierre_chateau.png")
	stone.uv1_scale = Vector3(1.5, 1.5, 1.5)
	_flash_mats.append(stone)
	var eye := _mat(Color(1.0, 0.35, 0.1), 0.2, 4.0)
	var Rk = load("res://scripts/rocks_v26.gd")
	_mesh(body, Rk.shape(5520, Vector3(0.62, 0.55, 0.75), 0.75, 0.12), stone, Vector3(0, 0, 0))
	_mesh(body, Rk.shape(5521, Vector3(0.42, 0.38, 0.42), 0.8, 0.1), stone, Vector3(0, 0.3, 0.38))
	for sx in [-1.0, 1.0]:
		_mesh(body, _cyl(0.0, 0.05, 0.28), stone, Vector3(sx * 0.13, 0.55, 0.32), Vector3.ONE, Vector3(-0.5, 0, sx * -0.5))
		_mesh(body, _sphere(0.035), eye, Vector3(sx * 0.08, 0.33, 0.58))
		# bras griffus
		_mesh(body, _cyl(0.04, 0.07, 0.4), stone, Vector3(sx * 0.25, -0.2, 0.25), Vector3.ONE, Vector3(0.6, 0, sx * 0.2))
		# ailes membraneuses
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.22, 0.18, -0.1)
		body.add_child(wing)
		var wm := _mat(Color(0.42, 0.42, 0.41), 0.95)
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_flash_mats.append(wm)
		var prism := PrismMesh.new()
		prism.size = Vector3(1.1, 0.9, 0.04)
		var pmi := _mesh(wing, prism, wm, Vector3(sx * 0.55, 0.1, -0.15), Vector3.ONE, Vector3(0, 0, sx * -1.2))
		pmi.rotation.y = sx * 0.3
		_mesh(wing, _cyl(0.025, 0.04, 1.1), stone, Vector3(sx * 0.5, 0.35, -0.1), Vector3.ONE, Vector3(0, 0, sx * -1.1))
		_arms.append([wing, sx])
	_mesh(body, _cyl(0.0, 0.06, 0.7), stone, Vector3(0, -0.15, -0.55), Vector3.ONE, Vector3(-1.2, 0, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.4, 0.15)
	l.light_energy = 0.6
	l.omni_range = 3.0
	l.position = Vector3(0, 0.33, 0.7)
	body.add_child(l)


func _coral_tuft(mat: Material) -> Node3D:
	var n := Node3D.new()
	for k in range(4):
		var c := _mesh(n, _cyl(0.015, 0.03, 0.16 + k * 0.03), mat, Vector3(-0.05 + k * 0.035, 0.07, 0.0))
		c.rotation.z = -0.5 + k * 0.33
		_mesh(n, _sphere(0.03), mat, c.position + Vector3(sin(-c.rotation.z) * 0.1, 0.08 + k * 0.015, 0))
	return n


func _attach(skel: Skeleton3D, bone_name: String, offset_cm: Vector3, node: Node3D) -> void:
	var b: int = skel.find_bone(bone_name)
	if b < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone_name
	skel.add_child(att)
	var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
	var holder := Node3D.new()
	holder.transform = Transform3D(rest.inverse() * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * offset_cm)
	att.add_child(holder)
	holder.add_child(node)


func _play(anim_name: String, blend: float = 0.2, speed: float = 1.0) -> void:
	if _anim != null and _anim.has_animation(anim_name) and (_anim.current_animation != anim_name or not _anim.is_playing()):
		_anim.play(anim_name, blend, speed)


# =================================================================== règle des cibles

func is_hittable() -> bool:
	return state != "mort"


func take_hit(damage: int, from_pos: Vector3) -> void:
	if state == "mort":
		return
	hp -= damage
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	_knock = away * (3.2 if kind in ["crabe", "araignee", "follet", "magma", "gargouille"] else (2.6 if kind == "vipere" else (0.5 if kind == "golem" else (1.0 if kind == "armure" else 1.6))))
	var cb: Node = manager.main.combat_v28
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (2.1 if kind in ["gardien", "armure", "gargouille"] else (3.0 if kind == "golem" else 0.9))
		if bool(cb.get("critical")):
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, Color(0.8, 0.5, 0.4) if kind == "crabe" else (Color(0.3, 0.6, 0.4) if kind == "vipere" else (Color(0.5, 0.85, 1.0) if kind == "follet" else (Color(0.9, 0.6, 0.95) if kind == "araignee" else Color(0.7, 0.75, 0.78)))))
	if hp <= 0:
		_die()
		return
	# V47 : le golem est trop lourd : un coup n'interrompt pas son attaque.
	if kind == "golem" and state in ["armer", "frappe"]:
		return
	# Un coup interrompt la préparation de l'attaque (on peut « couper » l'élan).
	state = "recul"
	timer = 0.22 if kind in ["gardien", "armure"] else 0.3
	if kind == "gardien" or kind == "armure":
		_play("v28/hurt", 0.05)


func _die() -> void:
	_sound("mort")
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	if kind == "gardien" or kind == "armure":
		_play("Knock_Down", 0.1)
	died.emit(self)


# =================================================================== comportement

func _player() -> Vector3:
	return manager.main._player_pos_v27()


func _physics_process(delta: float) -> void:
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	if state == "mort":
		timer += delta
		if kind == "crabe" or kind == "araignee":
			_visual.rotation.z = minf(timer * 6.0, PI)
			_visual.position.y = sin(minf(timer * 6.0, PI)) * 0.4
		elif kind == "gargouille":
			# Elle retombe, pierre inerte, et se brise
			var g: Node3D = _visual.get_node("Corps")
			g.position.y = maxf(0.35, 1.75 - timer * timer * 4.0)
			g.rotation.z = minf(timer * 2.5, 1.4)
		elif kind == "follet":
			_visual.scale = Vector3.ONE * clampf(1.0 - timer * 1.5, 0.01, 1.0)
			if _wisp_light != null:
				_wisp_light.light_energy = maxf(1.2 - timer * 2.0, 0.0)
		elif kind == "vipere":
			_visual.rotation.z = minf(timer * 5.0, PI * 0.9)
		elif kind == "golem":
			# Les blocs s'affaissent et s'enfoncent
			_visual.rotation.x = minf(timer * 1.2, 0.5)
			_visual.position.y = -minf(timer * 0.8, 1.4)
			for a in _arms:
				(a[0] as Node3D).rotation.z = float(a[1]) * minf(timer * 2.0, 1.3)
		elif kind == "magma":
			_visual.scale = Vector3.ONE * clampf(1.0 - timer * 1.2, 0.01, 1.0)
			if _magma_light != null:
				_magma_light.light_energy = maxf(1.6 - timer * 2.0, 0.0)
		if timer > 1.6:
			_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 1.6) / 0.8, 0.01, 1.0)
		if timer > 2.4:
			visible = false
			set_physics_process(false)
		return
	if not manager.active:
		return
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if dist < float(spec["vue"]) and dy < 3.0:
				state = "chasse"
				manager.alert(self)
			elif from_home > 1.0:
				var back: Vector3 = home - global_position
				back.y = 0.0
				move = back.normalized() * float(spec["vitesse"]) * 0.5
				facing = facing.lerp(back.normalized(), delta * 4.0).normalized()
		"chasse":
			if dist > float(spec["vue"]) * 1.6 or from_home > float(spec["laisse"]) or dy > 3.0:
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				_sound("menace")
				timer = float(spec["armer"])
				if kind == "gardien" or kind == "armure":
					_play("v28/slash3", 0.1, 0.55)
			else:
				move = dir_p * float(spec["vitesse"])
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.18
				if kind == "vipere" or kind == "follet" or kind == "magma" or kind == "gargouille":
					# Le bond : droit devant, sans corriger sa trajectoire.
					timer = 0.32
					_knock = facing * (7.5 if kind == "vipere" else (8.0 if kind == "gargouille" else 6.5))
				else:
					_strike(dist, dir_p)
		"frappe" when kind == "vipere" or kind == "follet" or kind == "magma" or kind == "gargouille":
			if timer > 0.1 and dist < (1.45 if kind in ["magma", "gargouille"] else 1.25) and not has_meta("mordu"):
				set_meta("mordu", true)
				manager.hurt_player(int(spec["degats"]), global_position)
			if timer <= 0.0:
				if has_meta("mordu"):
					remove_meta("mordu")
				state = "souffle"
				timer = float(spec["repos"])
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle":
			if timer <= 0.0:
				state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	if kind == "follet" or kind == "gargouille":
		velocity.y = (home.y - global_position.y) * 4.0
	else:
		velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate(delta, move.length())


func _strike(dist: float, dir_p: Vector3) -> void:
	if dist <= float(spec["portee"]) + 0.35 and facing.dot(dir_p) > 0.35:
		manager.hurt_player(int(spec["degats"]), global_position)
	if manager.main.combat_v28 != null:
		manager.main.combat_v28.puff(global_position + facing * float(spec["portee"]) * 0.8 + Vector3.UP * (0.4 if kind in ["crabe", "araignee"] else (0.2 if kind == "golem" else 1.2)), Color(0.5, 0.45, 0.42) if kind == "golem" else Color(0.85, 0.85, 0.8))


func _animate(delta: float, speed: float) -> void:
	if kind == "gargouille":
		var g: Node3D = _visual.get_node("Corps")
		var charge3: float = 0.0
		if state == "armer":
			charge3 = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		var dive: bool = state == "frappe"
		g.position.y = lerpf(g.position.y, (1.0 if dive else 1.75 + sin(_clock * 2.2) * 0.18 + charge3 * 0.4), clampf(delta * 6.0, 0.0, 1.0))
		g.rotation.x = lerpf(g.rotation.x, (0.6 if dive else -0.25 * charge3), clampf(delta * 8.0, 0.0, 1.0))
		var beat: float = sin(_clock * (14.0 if dive or charge3 > 0.0 else 7.0))
		for w in _arms:
			var wing: Node3D = w[0]
			wing.rotation.z = float(w[1]) * (0.35 + beat * 0.55 * (0.4 if dive else 1.0))
		return
	if kind == "golem":
		var walk_g: float = clampf(speed / 1.2, 0.0, 1.0)
		for l in _legs:
			(l[0] as Node3D).rotation.x = sin(_clock * 5.0 + (0.0 if float(l[1]) > 0 else PI)) * 0.35 * walk_g
		var lift: float = 0.0
		if state == "armer":
			lift = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		var slam: bool = state == "frappe"
		for a in _arms:
			var arm: Node3D = a[0]
			var goal: float = -2.8 * lift if not slam else -0.3
			if state in ["chasse", "veille"]:
				goal = sin(_clock * 5.0 + (PI if float(a[1]) > 0 else 0.0)) * 0.3 * walk_g
			arm.rotation.x = lerpf(arm.rotation.x, goal, clampf(delta * (18.0 if slam else 6.0), 0.0, 1.0))
		_visual.position.y = absf(sin(_clock * 5.0)) * 0.04 * walk_g
		return
	if kind == "magma":
		var fl2: Node3D = _visual.get_node("Flamme")
		var charge2: float = 0.0
		if state == "armer":
			charge2 = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		fl2.scale = Vector3.ONE * (1.0 + charge2 * 0.35 + sin(_clock * 9.0) * 0.04)
		fl2.position.y = 0.55 + absf(sin(_clock * 6.0)) * 0.12 * clampf(speed / 2.0, 0.0, 1.0)
		if _magma_light != null:
			_magma_light.light_energy = 1.6 + charge2 * 2.0 + sin(_clock * 13.0) * 0.2
		if _magma_core != null and _flash <= 0.0:
			_magma_core.emission_energy_multiplier = 2.4 + charge2 * 3.0
		return
	if kind == "vipere":
		var slither: float = clampf(speed / 2.7, 0.0, 1.0)
		var coil: float = 0.0
		if state == "armer":
			coil = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		for k in range(_segments.size()):
			var seg: Node3D = _segments[k]
			var wave: float = sin(_clock * 9.0 - k * 0.45) * (0.05 + k * 0.008) * maxf(slither, 0.25)
			var z0: float = 0.55 - k * 0.1
			# Lovée : le corps se replie en S et la tête se dresse.
			seg.position.x = lerpf(wave, sin(k * 0.55) * 0.22, coil)
			seg.position.z = lerpf(z0, z0 * 0.6 - 0.1, coil)
			seg.position.y = 0.12 + (maxf(0.0, 5.0 - k) * 0.075 * coil)
		return
	if kind == "follet":
		var fl: Node3D = _visual.get_node("Flamme")
		var charge: float = 0.0
		if state == "armer":
			charge = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		fl.position = Vector3(sin(_clock * 7.0) * 0.03 * charge * 3.0, 1.3 + sin(_clock * 2.4) * 0.12, 0)
		fl.scale = Vector3.ONE * (1.0 + charge * 0.5 + sin(_clock * 11.0) * 0.04)
		if _wisp_light != null:
			_wisp_light.light_energy = 1.2 + charge * 2.5 + sin(_clock * 17.0) * 0.15
		if _wisp_core != null and _flash <= 0.0:
			_wisp_core.emission_energy_multiplier = 3.0 + charge * 4.0
		return
	if kind == "crabe" or kind == "araignee":
		var walk: float = clampf(speed / 2.3, 0.0, 1.0)
		for l in _legs:
			var leg: Node3D = l[0]
			leg.rotation.x = sin(_clock * 14.0 + float(l[2]) * 2.1 + (0.0 if float(l[1]) > 0 else PI)) * 0.45 * walk
		var raise: float = 0.0
		if state == "armer":
			raise = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		var snap: bool = state == "frappe"
		for c in _claws:
			(c as Node3D).rotation.x = lerpf((c as Node3D).rotation.x, (-0.9 * raise) if not snap else 0.5, clampf(delta * 12.0, 0.0, 1.0))
		_visual.position.y = absf(sin(_clock * 14.0)) * 0.03 * walk
	else:
		match state:
			"chasse", "veille":
				if speed > 0.2:
					_play("Walking", 0.25, 0.75)
				else:
					_play("v28/idle", 0.3)
			"souffle":
				_play("v28/idle", 0.3, 0.6)


func _apply_flash() -> void:
	var on: bool = _flash > 0.0
	for m in _flash_mats:
		var sm: StandardMaterial3D = m
		if on:
			if not sm.has_meta("e0"):
				sm.set_meta("e0", [sm.emission_enabled, sm.emission, sm.emission_energy_multiplier])
			sm.emission_enabled = true
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 1.4
		elif sm.has_meta("e0"):
			var e: Array = sm.get_meta("e0")
			sm.emission_enabled = e[0]
			sm.emission = e[1]
			sm.emission_energy_multiplier = e[2]
			sm.remove_meta("e0")

extends "res://scripts/monstre_v68.gd"
## V69 : les monstres de l'Île des Trois Soleils et de ses trois grands donjons. Même règle que
## les autres (groupe « cibles_v28 », take_hit, butin, conseil à la première rencontre) :
##  - la momie (la Pyramide de Rê) : un corps emmailloté de bandelettes, des yeux qui luisent ;
##    lente, solide, elle tend les bras avant de frapper ;
##  - le jaguar (la jungle, le Mont Fumant, la Maison des Jaguars) : il se tapit, puis bondit ;
##    le jaguar de pierre (le Soleil des Jaguars, sous le Grand Temple) : le même, en pierre ;
##  - la chauve-souris (le Cénote la nuit, la Maison des Chauves-souris) : elle vole à hauteur de
##    tête et pique sur le joueur ;
##  - Ammit la Dévoreuse (la Salle des Deux Vérités) : tête de crocodile, avant de lion, arrière
##    d'hippopotame ; elle surgit quand un cœur ment ;
##  - Apophis, le serpent du chaos (la Douat) : un serpent géant, il siffle, crache, balaie tout ;
##  - Camazotz, la chauve-souris de la mort (Xibalba) : grandes ailes, il plonge, il hurle, il
##    appelle ses chauves-souris ;
##  - Cipactli, le monstre de la Terre (sous le Grand Temple) : un crocodile géant aux épines,
##    il disparaît sous l'eau et resurgit ailleurs.

const SPECS69 := {
	"momie": {"pv": 22, "vitesse": 1.35, "degats": 1, "portee": 1.9, "armer": 0.85, "repos": 1.5, "vue": 11.0, "laisse": 16.0,
		"rayon": 0.42, "haut": 1.0, "nom": "Momie"},
	"jaguar": {"pv": 18, "vitesse": 3.3, "degats": 1, "portee": 2.6, "armer": 0.55, "repos": 1.3, "vue": 13.0, "laisse": 18.0,
		"rayon": 0.5, "haut": 0.5, "nom": "Jaguar", "bond": 8.5},
	"jaguar_pierre": {"pv": 24, "vitesse": 2.8, "degats": 1, "portee": 2.6, "armer": 0.65, "repos": 1.4, "vue": 14.0, "laisse": 20.0,
		"rayon": 0.55, "haut": 0.55, "nom": "Jaguar de pierre", "bond": 8.0},
	"chauve_souris": {"pv": 6, "vitesse": 3.2, "degats": 1, "portee": 2.2, "armer": 0.5, "repos": 1.6, "vue": 12.0, "laisse": 16.0,
		"rayon": 0.35, "haut": 1.4, "nom": "Chauve-souris", "bond": 6.5},
	"ammit": {"pv": 70, "vitesse": 2.2, "degats": 2, "portee": 3.2, "armer": 0.8, "repos": 1.4, "vue": 22.0, "laisse": 40.0,
		"rayon": 1.1, "haut": 0.8, "nom": "Ammit la Dévoreuse", "boss": true, "bond": 9.0},
	"apophis": {"pv": 150, "vitesse": 2.4, "degats": 2, "portee": 4.2, "armer": 0.9, "repos": 1.3, "vue": 30.0, "laisse": 60.0,
		"rayon": 1.3, "haut": 1.4, "nom": "Apophis, le serpent du chaos", "boss": true},
	"camazotz": {"pv": 150, "vitesse": 2.6, "degats": 2, "portee": 3.0, "armer": 0.8, "repos": 1.3, "vue": 30.0, "laisse": 60.0,
		"rayon": 0.9, "haut": 2.0, "nom": "Camazotz, la chauve-souris de la mort", "boss": true, "bond": 11.0},
	"cipactli": {"pv": 170, "vitesse": 2.0, "degats": 3, "portee": 4.4, "armer": 0.95, "repos": 1.5, "vue": 30.0, "laisse": 60.0,
		"rayon": 1.6, "haut": 0.9, "nom": "Cipactli, le monstre de la Terre", "boss": true, "bond": 10.0},
}
const SOUNDS69 := {"momie": ["momie_menace", "momie_mort"], "jaguar": ["jaguar_menace", "jaguar_mort"], "jaguar_pierre": ["jaguar_menace", "os_choc"],
	"chauve_souris": ["chauve_souris_cri", "chauve_souris_cri"], "ammit": ["ammit_cri", "boss_coeur_cri"], "apophis": ["apophis_cri", "boss_coeur_cri"],
	"camazotz": ["camazotz_cri", "boss_coeur_cri"], "cipactli": ["cipactli_cri", "boss_coeur_cri"]}
const LEAPERS69 := ["jaguar", "jaguar_pierre", "chauve_souris", "ammit", "camazotz", "cipactli"]

var _cat_body: Node3D                    # le corps des félins (jaguar, Ammit)
var _wings: Array = []                   # [Node3D, côté] (chauves-souris, Camazotz)
var _hover: float = 0.0
var _trail: Array = []                   # Apophis : les positions passées de la tête
var _coils: Array = []                   # Apophis : les anneaux (placés le long de la trace)
var _apo_head: Node3D
var _apo_jaw: Node3D
var _phase69: int = 0
var _dive_t: float = 0.0


func _v63() -> bool:
	return SPECS69.has(kind) or super._v63()


func _leaper() -> bool:
	return kind in LEAPERS69 or super._leaper()


func _sound_pair() -> Array:
	return SOUNDS69.get(kind, super._sound_pair())


func _armer_anim() -> void:
	match kind:
		"momie":
			_play("v28/slash2", 0.1, 0.55)
		"camazotz":
			_play("v28/slash3", 0.1, 0.6)
		_:
			super._armer_anim()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS69.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS69[k]
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
		"momie", "camazotz":
			var s: float = 1.0 if k == "momie" else 1.45
			cap.radius = 0.32 * s
			cap.height = 1.8 * s
			cs.position.y = 0.9 * s
		"jaguar", "jaguar_pierre", "ammit":
			var s2: float = 1.6 if k == "ammit" else 1.0
			cap.radius = 0.3 * s2
			cap.height = 1.7 * s2
			cs.rotation.x = PI * 0.5
			cs.position = Vector3(0, 0.45 * s2, 0)
		"chauve_souris":
			cap.radius = 0.3
			cap.height = 1.6
			cs.position.y = 0.8
		"apophis":
			cap.radius = 0.9
			cap.height = 3.2
			cs.position.y = 1.65
		"cipactli":
			cap.radius = 0.8
			cap.height = 5.5
			cs.rotation.x = PI * 0.5
			cs.position = Vector3(0, 0.8, -0.4)
	cs.shape = cap
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"momie":
			_build_momie()
		"jaguar":
			_build_felin(1.0, false, false)
		"jaguar_pierre":
			_build_felin(1.05, true, false)
		"ammit":
			_build_felin(1.6, false, true)
		"chauve_souris":
			_build_bat(1.0)
		"camazotz":
			_build_camazotz()
		"apophis":
			_build_apophis()
		"cipactli":
			_build_croco(2.7)
			_cipactli_spikes()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


# =================================================================== la momie

func _linen_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/pirates/toile.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/pirates/toile_n.png")
	m.normal_scale = 1.6
	m.albedo_color = c
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(5, 5, 5)
	_flash_mats.append(m)
	return m


## La momie : la silhouette du héros (pour les mouvements), mais emmaillotée : des bandelettes
## épaisses sur chaque membre, des bouts qui pendent, deux yeux verts dans l'ombre du visage.
func _build_momie() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
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
	if skel == null:
		return
	var linen := _linen_mat(Color(0.72, 0.66, 0.52))
	var dark := _linen_mat(Color(0.42, 0.37, 0.28))
	for pair in [["Hips", "Spine"], ["Spine", "Spine01"], ["Spine01", "Spine02"], ["Spine02", "neck"], ["neck", "Head"],
			["LeftArm", "LeftForeArm"], ["LeftForeArm", "LeftHand"], ["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"],
			["LeftUpLeg", "LeftLeg"], ["LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg"], ["RightLeg", "RightFoot"],
			["Spine02", "LeftArm"], ["Spine02", "RightArm"], ["Hips", "LeftUpLeg"], ["Hips", "RightUpLeg"]]:
		var thick: float = 0.065 if str(pair[0]).contains("Arm") or str(pair[0]).contains("Leg") else 0.11
		if str(pair[0]) in ["Spine01", "Spine02", "Hips"]:
			thick = 0.15
		_bone_stick(skel, str(pair[0]), str(pair[1]), thick, linen if randf() < 0.7 else dark)
	var head := Node3D.new()
	_mesh(head, _sphere(0.12), linen, Vector3(0, 0.02, 0), Vector3(0.95, 1.1, 1.05))
	for k in range(4):
		_mesh(head, _cyl(0.125, 0.125, 0.025), dark if k % 2 == 0 else linen, Vector3(0, -0.06 + k * 0.05, 0), Vector3(1.0, 1.0, 1.08), _r(Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))))
	var glow := _mat(Color(0.5, 1.0, 0.55), 0.2, 4.5)
	for sx in [-0.04, 0.04]:
		_mesh(head, _sphere(0.018), glow, Vector3(sx, 0.03, 0.11))
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	# des bandelettes qui pendent
	for b in [["LeftForeArm", -1.0], ["RightForeArm", 1.0], ["Spine02", 0.0], ["LeftLeg", -1.0]]:
		var strip := Node3D.new()
		var sm := _linen_mat(Color(0.66, 0.6, 0.47))
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh(strip, _box_mesh_g(Vector3(0.05, 0.32, 0.006)), sm, Vector3(float(b[1]) * 0.03, -0.18, -0.05), Vector3.ONE, _r(Vector3(10, 0, float(b[1]) * 12.0)))
		_attach(skel, str(b[0]), Vector3(0, 6, 0), strip)
	_play("v28/idle")


# =================================================================== les félins

func _fur_mat(stone: bool, ammit: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if stone:
		m.albedo_texture = load("res://assets/textures/soleils/tezontle.png") if ResourceLoader.exists("res://assets/textures/soleils/tezontle.png") else null
		m.albedo_color = Color(0.62, 0.58, 0.52)
		m.roughness = 0.95
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(2, 2, 2)
	else:
		m.albedo_color = Color(0.86, 0.6, 0.22) if not ammit else Color(0.72, 0.56, 0.32)
		m.roughness = 0.9
	_flash_mats.append(m)
	return m


## Un félin (jaguar ; Ammit : un avant de lion et une tête de crocodile). Il regarde vers +Z.
func _build_felin(s: float, stone: bool, ammit: bool) -> void:
	var fur := _fur_mat(stone, ammit)
	var spot := _mat(Color(0.1, 0.07, 0.05) if not stone else Color(0.3, 0.12, 0.1), 0.9)
	var belly := _mat(Color(0.95, 0.88, 0.72) if not stone else Color(0.55, 0.5, 0.45), 0.9)
	var eye := _mat(Color(0.95, 0.85, 0.2) if not stone else Color(1.0, 0.4, 0.15), 0.2, 3.0)
	_cat_body = Node3D.new()
	_cat_body.position = Vector3(0, 0.48 * s, 0)
	_cat_body.scale = Vector3.ONE * s
	_visual.add_child(_cat_body)
	_mesh(_cat_body, _sphere(0.3), fur, Vector3(0, 0, 0.1), Vector3(0.95, 0.9, 1.8))
	_mesh(_cat_body, _sphere(0.26), belly, Vector3(0, -0.1, 0.1), Vector3(0.85, 0.6, 1.6))
	if ammit:
		# l'arrière d'hippopotame : lourd, gris, rond
		var hippo := _mat(Color(0.48, 0.44, 0.46), 0.8)
		_flash_mats.append(hippo)
		_mesh(_cat_body, _sphere(0.36), hippo, Vector3(0, 0.02, -0.35), Vector3(1.15, 1.0, 1.1))
		# la crinière de lion
		var mane := _mat(Color(0.55, 0.32, 0.12), 0.95)
		_flash_mats.append(mane)
		_mesh(_cat_body, _sphere(0.3), mane, Vector3(0, 0.1, 0.5), Vector3(1.15, 1.1, 0.8))
	if not ammit:
		for k in range(14):
			var a: float = randf() * TAU
			_mesh(_cat_body, _sphere(0.045), spot, Vector3(cos(a) * 0.26, absf(sin(a)) * 0.2 + 0.05, randf_range(-0.35, 0.5)), Vector3(1.0, 0.35, 1.0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.16, 0.62)
	_cat_body.add_child(head)
	if ammit:
		var croc := _croc_mat()
		_mesh(head, _sphere(0.2), croc, Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
		_jaw_up = Node3D.new()
		_jaw_up.position = Vector3(0, 0.02, 0.1)
		head.add_child(_jaw_up)
		_mesh(_jaw_up, _box_mesh_g(Vector3(0.24, 0.09, 0.55)), croc, Vector3(0, 0.02, 0.27))
		_jaw_low = Node3D.new()
		_jaw_low.position = Vector3(0, -0.06, 0.1)
		head.add_child(_jaw_low)
		_mesh(_jaw_low, _box_mesh_g(Vector3(0.22, 0.06, 0.5)), belly, Vector3(0, -0.02, 0.25))
		var teeth := _mat(Color(0.95, 0.92, 0.82), 0.4)
		for k2 in range(5):
			for sx in [-0.1, 0.1]:
				_mesh(_jaw_up, _cyl(0.0, 0.02, 0.06), teeth, Vector3(sx, -0.05, 0.1 + k2 * 0.09), Vector3.ONE, _r(Vector3(180, 0, 0)))
		for sx2 in [-0.1, 0.1]:
			_mesh(head, _sphere(0.045), eye, Vector3(sx2, 0.12, 0.05))
	else:
		_mesh(head, _sphere(0.17), fur, Vector3.ZERO, Vector3(1.05, 0.9, 1.0))
		_mesh(head, _sphere(0.09), belly, Vector3(0, -0.04, 0.13), Vector3(1.0, 0.75, 0.9))
		_mesh(head, _sphere(0.03), spot, Vector3(0, 0.0, 0.21))
		for sx3 in [-1.0, 1.0]:
			_mesh(head, _cyl(0.0, 0.05, 0.08), fur, Vector3(sx3 * 0.11, 0.15, -0.02))
			_mesh(head, _sphere(0.028), eye, Vector3(sx3 * 0.07, 0.05, 0.14))
		_jaw_low = Node3D.new()
		_jaw_low.position = Vector3(0, -0.08, 0.08)
		head.add_child(_jaw_low)
		_mesh(_jaw_low, _box_mesh_g(Vector3(0.12, 0.04, 0.1)), belly, Vector3(0, 0, 0.04))
	# la queue
	var prev: Node3D = _cat_body
	var z: float = -0.48
	for t in range(5):
		var seg := Node3D.new()
		seg.position = Vector3(0, 0.08 if t == 0 else 0.0, z)
		prev.add_child(seg)
		_mesh(seg, _cyl(0.035 - t * 0.004, 0.04 - t * 0.004, 0.18), fur if t < 4 or stone else spot, Vector3(0, 0, -0.09), Vector3.ONE, _r(Vector3(90, 0, 0)))
		_tail.append([seg, 0.3])
		prev = seg
		z = -0.18
	# les pattes
	for side in [-1.0, 1.0]:
		for fz in [0.42, -0.32]:
			var hip := Node3D.new()
			hip.position = Vector3(side * 0.17, -0.08, fz)
			_cat_body.add_child(hip)
			_mesh(hip, _cyl(0.05, 0.065, 0.42), fur, Vector3(0, -0.2, 0))
			_mesh(hip, _sphere(0.06), belly if not stone else fur, Vector3(0, -0.42, 0.03), Vector3(1.0, 0.6, 1.3))
			_legs.append([hip, side, fz])


# =================================================================== les chauves-souris

func _build_bat(s: float) -> void:
	var skin := _mat(Color(0.16, 0.12, 0.11), 0.85)
	var wingm := _mat(Color(0.22, 0.15, 0.14), 0.9)
	wingm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var eye := _mat(Color(1.0, 0.25, 0.15), 0.2, 4.0)
	var body := Node3D.new()
	body.name = "Vol"
	body.position = Vector3(0, 1.4, 0)
	body.scale = Vector3.ONE * s
	_visual.add_child(body)
	_body_node = body
	_mesh(body, _sphere(0.11), skin, Vector3.ZERO, Vector3(1.0, 1.0, 1.4))
	_mesh(body, _sphere(0.08), skin, Vector3(0, 0.05, 0.14))
	for sx in [-1.0, 1.0]:
		_mesh(body, _cyl(0.0, 0.035, 0.08), skin, Vector3(sx * 0.04, 0.12, 0.12))
		_mesh(body, _sphere(0.014), eye, Vector3(sx * 0.03, 0.07, 0.21))
		var w := Node3D.new()
		w.position = Vector3(sx * 0.08, 0.02, 0)
		body.add_child(w)
		_mesh(w, _box_mesh_g(Vector3(0.42, 0.01, 0.26)), wingm, Vector3(sx * 0.22, 0, -0.02))
		_mesh(w, _box_mesh_g(Vector3(0.22, 0.01, 0.18)), wingm, Vector3(sx * 0.48, 0, -0.06), Vector3.ONE, _r(Vector3(0, sx * 20.0, 0)))
		_wings.append([w, sx])


## Camazotz : un grand corps d'homme (la silhouette du héros), une tête de chauve-souris aux
## grandes oreilles et au museau plissé, deux immenses ailes de cuir.
func _build_camazotz() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 1.45
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
	if skel == null:
		return
	var skin := _mat(Color(0.14, 0.1, 0.1), 0.8)
	var fur := _mat(Color(0.22, 0.16, 0.14), 0.95)
	_flash_mats.append(skin)
	_flash_mats.append(fur)
	for pair in [["Hips", "Spine"], ["Spine", "Spine01"], ["Spine01", "Spine02"], ["Spine02", "neck"], ["neck", "Head"],
			["LeftArm", "LeftForeArm"], ["LeftForeArm", "LeftHand"], ["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"],
			["LeftUpLeg", "LeftLeg"], ["LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg"], ["RightLeg", "RightFoot"],
			["Spine02", "LeftArm"], ["Spine02", "RightArm"], ["Hips", "LeftUpLeg"], ["Hips", "RightUpLeg"]]:
		var thick: float = 0.06 if str(pair[0]).contains("Arm") or str(pair[0]).contains("Leg") else 0.12
		if str(pair[0]) in ["Spine01", "Spine02", "Hips"]:
			thick = 0.16
		_bone_stick(skel, str(pair[0]), str(pair[1]), thick, fur if str(pair[0]).begins_with("Spine") else skin)
	var head := Node3D.new()
	_mesh(head, _sphere(0.14), fur, Vector3(0, 0.02, 0), Vector3(1.0, 0.95, 1.0))
	_mesh(head, _sphere(0.08), skin, Vector3(0, -0.02, 0.12), Vector3(1.1, 0.8, 0.9))
	var eye := _mat(Color(1.0, 0.25, 0.1), 0.2, 5.0)
	var fang := _mat(Color(0.95, 0.92, 0.85), 0.4)
	for sx in [-1.0, 1.0]:
		_mesh(head, _cyl(0.0, 0.08, 0.22), skin, Vector3(sx * 0.1, 0.2, -0.02), Vector3(1.0, 1.0, 0.5), _r(Vector3(0, 0, -sx * 18.0)))
		_mesh(head, _sphere(0.022), eye, Vector3(sx * 0.05, 0.05, 0.12))
		_mesh(head, _cyl(0.0, 0.012, 0.05), fang, Vector3(sx * 0.03, -0.08, 0.16), Vector3.ONE, _r(Vector3(180, 0, 0)))
	_attach(skel, "Head", Vector3(0, 9, 1), head)
	# les ailes, accrochées au dos, qui s'ouvrent quand il plonge
	var wingm := _mat(Color(0.2, 0.13, 0.12), 0.9)
	wingm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flash_mats.append(wingm)
	for sx2 in [-1.0, 1.0]:
		var w := Node3D.new()
		_mesh(w, _box_mesh_g(Vector3(0.9, 0.012, 0.75)), wingm, Vector3(sx2 * 0.5, 0.0, -0.1))
		_mesh(w, _box_mesh_g(Vector3(0.7, 0.012, 0.5)), wingm, Vector3(sx2 * 1.1, -0.05, -0.2), Vector3.ONE, _r(Vector3(0, sx2 * 15.0, sx2 * 10.0)))
		for r in range(3):
			_mesh(w, _cyl(0.012, 0.018, 1.2), skin, Vector3(sx2 * (0.35 + r * 0.32), 0.0, -0.05 - r * 0.08), Vector3.ONE, _r(Vector3(0, 0, 90)))
		_attach(skel, "Spine02", Vector3(sx2 * 10.0, 18.0, -12.0), w)
		_wings.append([w, sx2])
	var lg := OmniLight3D.new()
	lg.light_color = Color(1.0, 0.3, 0.2)
	lg.light_energy = 1.0
	lg.omni_range = 5.0
	lg.position = Vector3(0, 2.8, 0.5)
	_visual.add_child(lg)
	_play("v28/idle")


# =================================================================== Apophis

## Apophis : un serpent géant. La tête (une gueule aux crochets, des yeux rouges) mène ; vingt-
## huit anneaux suivent sa trace sur le sol.
func _build_apophis() -> void:
	var skin := _mat(Color(0.12, 0.1, 0.16), 0.3)
	skin.metallic_specular = 0.8
	var scale_m := _mat(Color(0.42, 0.18, 0.5), 0.35, 0.6)
	var eye := _mat(Color(1.0, 0.15, 0.1), 0.2, 6.0)
	var fang := _mat(Color(0.95, 0.92, 0.85), 0.4)
	_flash_mats.append(skin)
	_apo_head = Node3D.new()
	_apo_head.position = Vector3(0, 1.4, 0)
	_visual.add_child(_apo_head)
	_mesh(_apo_head, _sphere(0.75), skin, Vector3(0, 0, 0.2), Vector3(1.0, 0.62, 1.4))
	_mesh(_apo_head, _sphere(0.5), scale_m, Vector3(0, 0.3, 0.1), Vector3(1.0, 0.4, 1.3))
	for sx in [-1.0, 1.0]:
		_mesh(_apo_head, _sphere(0.12), eye, Vector3(sx * 0.42, 0.25, 0.65))
	_apo_jaw = Node3D.new()
	_apo_jaw.position = Vector3(0, -0.25, 0.3)
	_apo_head.add_child(_apo_jaw)
	_mesh(_apo_jaw, _box_mesh_g(Vector3(0.9, 0.18, 1.1)), skin, Vector3(0, -0.05, 0.45))
	for sx2 in [-0.3, 0.3]:
		_mesh(_apo_head, _cyl(0.0, 0.08, 0.4), fang, Vector3(sx2, -0.3, 1.05), Vector3.ONE, _r(Vector3(180, 0, 0)))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.9, 0.3, 1.0)
	glow.light_energy = 1.5
	glow.omni_range = 7.0
	glow.position = Vector3(0, 0.8, 0.8)
	_apo_head.add_child(glow)
	for k in range(28):
		var seg := Node3D.new()
		seg.top_level = true
		add_child(seg)
		var r: float = 0.85 * (1.0 - float(k) / 34.0)
		_mesh(seg, _sphere(r), skin, Vector3(0, r * 0.75, 0), Vector3(1.0, 0.75, 1.3))
		if k % 2 == 0:
			_mesh(seg, _sphere(r * 0.45), scale_m, Vector3(0, r * 1.25, 0), Vector3(1.4, 0.3, 1.0))
		_coils.append(seg)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if kind == "apophis" and _coils.size() > 0:
		# la trace de la tête ; les anneaux se posent dessus tous les 0,9 m
		var hp_pos: Vector3 = global_position
		if _trail.is_empty() or (_trail[0] as Vector3).distance_to(hp_pos) > 0.3:
			_trail.push_front(hp_pos)
			if _trail.size() > 120:
				_trail.pop_back()
		var dist_acc: float = 0.0
		var ti: int = 0
		# au-delà de la trace (au repos, à la naissance) : le reste du corps s'enroule en spirale
		var p_end: Vector3 = _trail[_trail.size() - 1] if not _trail.is_empty() else hp_pos
		var back: Vector3 = Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)
		var c_sp: Vector3 = p_end + back * 2.2
		var th0: float = atan2(p_end.z - c_sp.z, p_end.x - c_sp.x)
		for i in range(_coils.size()):
			var want: float = 1.4 + i * 0.9
			while ti < _trail.size() - 1 and dist_acc + (_trail[ti] as Vector3).distance_to(_trail[ti + 1]) < want:
				dist_acc += (_trail[ti] as Vector3).distance_to(_trail[ti + 1])
				ti += 1
			var p: Vector3 = _trail[mini(ti, _trail.size() - 1)] if not _trail.is_empty() else hp_pos
			if ti >= _trail.size() - 1 and dist_acc < want:
				var sp: float = want - dist_acc
				var rr: float = maxf(2.2 - sp * 0.07, 0.8)
				var th: float = th0 + sp / rr
				p = c_sp + Vector3(cos(th), 0.0, sin(th)) * rr + Vector3.UP * minf(sp * 0.02, 0.5)
			var wob: float = sin(_clock * 3.0 - i * 0.5) * 0.25
			(_coils[i] as Node3D).global_position = p + Vector3(wob, 0, 0).rotated(Vector3.UP, rotation.y)
			(_coils[i] as Node3D).visible = state != "mort" or timer < 2.0


# =================================================================== Cipactli

func _cipactli_spikes() -> void:
	if _croco_body == null:
		return
	var spike := _mat(Color(0.32, 0.36, 0.22), 0.6)
	var red := _mat(Color(0.7, 0.12, 0.08), 0.5, 0.8)
	for k in range(12):
		_mesh(_croco_body, _cyl(0.0, 0.07, 0.3), spike if k % 3 else red, Vector3(0, 0.32, -0.7 + k * 0.13), Vector3.ONE, _r(Vector3(-12, 0, 0)))
	# des bouches à chaque articulation (des gueules rouges sur les flancs)
	for side in [-1.0, 1.0]:
		for z in [-0.3, 0.3]:
			_mesh(_croco_body, _sphere(0.06), red, Vector3(side * 0.42, 0.0, z), Vector3(0.6, 0.6, 1.0))
	var eye := _mat(Color(1.0, 0.5, 0.1), 0.2, 4.0)
	var lg := OmniLight3D.new()
	lg.light_color = Color(1.0, 0.55, 0.2)
	lg.light_energy = 1.2
	lg.omni_range = 6.0
	lg.position = Vector3(0, 1.2, 2.0)
	_visual.add_child(lg)


# =================================================================== comportement

func _boss_tick(delta: float, dist: float) -> void:
	if not SPECS69.has(kind):
		super._boss_tick(delta, dist)
		return
	_special_t += delta
	var pv: int = int(spec["pv"])
	match kind:
		"ammit":
			if _special_t > 6.0 and dist > 4.0 and dist < 12.0:
				_special_t = 0.0
				_knock = facing * 10.0
				_hint69("Ammit se ramasse… et se jette sur toi, gueule ouverte !")
		"apophis":
			# il siffle et crache son venin (une onde devant lui), il balaie de la queue
			if _special_t > 7.0 and dist < 9.0:
				_special_t = 0.0
				_shockwave(global_position + facing * 3.5)
				_hint69("Apophis crache un nuage de venin noir !")
			if (_phase69 == 0 and hp < pv * 2 / 3) or (_phase69 == 1 and hp < pv / 3):
				_phase69 += 1
				for k in range(3):
					var a: float = TAU * k / 3.0
					var m: Node3D = manager.spawn_extra("scorpion", global_position + Vector3(cos(a) * 4.0, 0.1, sin(a) * 4.0))
					m.home = m.global_position
				_hint69("Apophis siffle : des scorpions sortent des ténèbres !")
		"camazotz":
			if (_phase69 == 0 and hp < pv * 2 / 3) or (_phase69 == 1 and hp < pv / 3):
				_phase69 += 1
				for k2 in range(3):
					var a2: float = TAU * k2 / 3.0
					var m2: Node3D = manager.spawn_extra("chauve_souris", global_position + Vector3(cos(a2) * 3.0, 0.1, sin(a2) * 3.0))
					m2.home = m2.global_position
				_hint69("Camazotz hurle : une nuée de chauves-souris se lève !")
			if _special_t > 8.0 and dist < 5.0:
				_special_t = 0.0
				_shockwave(global_position)
				_hint69("Camazotz pousse un cri à vous percer les tympans !")
		"cipactli":
			if _special_t > 9.0:
				_special_t = 0.0
				# il plonge et resurgit ailleurs, près du joueur
				var p: Vector3 = _player()
				var a3: float = randf() * TAU
				var to: Vector3 = Vector3(p.x + cos(a3) * 7.0, global_position.y, p.z + sin(a3) * 7.0)
				if to.distance_to(home) < float(spec["laisse"]):
					global_position = to
					_hint69("Cipactli plonge… et resurgit ailleurs !")
					if manager.main.has_method("sfx"):
						manager.main.sfx("plouf", to + Vector3.UP)
			elif _special_t > 4.5 and _special_t < 4.6 and dist < 5.5:
				_shockwave(global_position)
				_hint69("Cipactli balaie tout de sa queue !")


func _hint69(t: String) -> void:
	if _clock - _last_hint < 3.0:
		return
	_last_hint = _clock
	if manager != null and manager.donjon != null:
		manager.donjon._say(t, 3.5)


func take_hit(damage: int, from_pos: Vector3) -> void:
	super.take_hit(damage, from_pos)
	if SPECS69.has(kind) and kind in ["momie", "camazotz"] and state == "recul" and _anim != null:
		_play("v28/hurt", 0.05)


func _die63() -> void:
	super._die63()
	if kind in ["momie", "camazotz"]:
		_play("Knock_Down", 0.1)


func _puff_color() -> Color:
	match kind:
		"momie":
			return Color(0.75, 0.7, 0.58)
		"jaguar", "ammit":
			return Color(0.85, 0.65, 0.3)
		"jaguar_pierre":
			return Color(0.6, 0.55, 0.5)
		"chauve_souris", "camazotz":
			return Color(0.3, 0.22, 0.2)
		"apophis":
			return Color(0.45, 0.2, 0.55)
		"cipactli":
			return Color(0.45, 0.5, 0.3)
	return super._puff_color()


func _death_tick(delta: float) -> void:
	if not SPECS69.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	match kind:
		"jaguar", "jaguar_pierre", "ammit", "cipactli":
			_visual.rotation.z = minf(timer * 3.0, PI * 0.5)
		"chauve_souris":
			if _body_node != null:
				_body_node.position.y = maxf(_body_node.position.y - delta * 3.0, 0.15)
		"apophis":
			if _apo_head != null:
				_apo_head.position.y = maxf(1.4 - timer, 0.3)
	if timer > 2.0:
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 2.0) / 0.8, 0.01, 1.0)
		for c in _coils:
			(c as Node3D).scale = _visual.scale
	if timer > 2.8:
		visible = false
		for c2 in _coils:
			(c2 as Node3D).visible = false
		set_physics_process(false)


func _exit_tree() -> void:
	for c in _coils:
		if is_instance_valid(c):
			(c as Node3D).queue_free()


func _animate63(delta: float, speed: float) -> void:
	if not SPECS69.has(kind):
		super._animate63(delta, speed)
		return
	var moving: bool = speed > 0.2
	match kind:
		"momie", "camazotz":
			if _anim != null and not (state in ["armer", "frappe", "mort", "recul"]):
				if moving:
					_play("Walking", 0.2, maxf(speed / (1.1 if kind == "momie" else 1.9), 0.5))
				else:
					_play("v28/idle", 0.3)
			for w in _wings:
				var open: float = 0.9 if state in ["armer", "frappe"] else 0.25
				(w[0] as Node3D).rotation.z = float(w[1]) * (open * 0.4 + sin(_clock * (8.0 if state == "frappe" else 2.0)) * 0.12)
		"jaguar", "jaguar_pierre", "ammit":
			var walk: float = _clock * (8.0 + speed * 3.0)
			var crouch: float = 0.0
			if state == "armer":
				crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
			for l in _legs:
				var leg: Node3D = l[0]
				var ph: float = (0.0 if float(l[1]) > 0.0 else PI) + (0.0 if float(l[2]) > 0.0 else PI * 0.5)
				leg.rotation.x = sin(walk + ph) * (0.6 if moving else 0.04)
			for i in range(_tail.size()):
				var seg: Node3D = _tail[i][0]
				seg.rotation.x = 0.25 + sin(_clock * 2.0 - i * 0.5) * 0.12
				seg.rotation.y = sin(_clock * (4.0 if moving else 1.2) - i * 0.6) * 0.25
			var s: float = 1.6 if kind == "ammit" else (1.05 if kind == "jaguar_pierre" else 1.0)
			if _cat_body != null:
				_cat_body.position.y = lerpf(_cat_body.position.y, (0.48 - crouch * 0.16) * s, clampf(delta * 8.0, 0.0, 1.0))
			if _jaw_low != null:
				var open2: float = 0.5 * crouch if state == "armer" else (0.3 if state == "frappe" else 0.05)
				_jaw_low.rotation.x = lerpf(_jaw_low.rotation.x, open2, clampf(delta * 12.0, 0.0, 1.0))
				if _jaw_up != null:
					_jaw_up.rotation.x = lerpf(_jaw_up.rotation.x, -open2 * 0.6, clampf(delta * 12.0, 0.0, 1.0))
		"chauve_souris":
			if _body_node != null:
				var dive: float = 0.0
				if state in ["armer"]:
					dive = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
				elif state == "frappe":
					dive = 1.0
				_body_node.position.y = lerpf(_body_node.position.y, 1.45 + sin(_clock * 3.0) * 0.18 - dive * 0.55, clampf(delta * 6.0, 0.0, 1.0))
			for w2 in _wings:
				(w2[0] as Node3D).rotation.z = float(w2[1]) * sin(_clock * 18.0) * 0.7
		"apophis":
			if _apo_head != null:
				var rise: float = 0.0
				if state == "armer":
					rise = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
				_apo_head.position.y = lerpf(_apo_head.position.y, 1.4 + rise * 1.2 + sin(_clock * 1.6) * 0.15, clampf(delta * 5.0, 0.0, 1.0))
				_apo_head.rotation.x = -rise * 0.4
			if _apo_jaw != null:
				_apo_jaw.rotation.x = lerpf(_apo_jaw.rotation.x, 0.6 if state in ["armer", "frappe"] else 0.08, clampf(delta * 10.0, 0.0, 1.0))
		"cipactli":
			var walk2: float = _clock * (6.0 + speed * 2.0)
			var open3: float = 0.05 + 0.05 * sin(_clock * 0.7)
			var crouch2: float = 0.0
			if state == "armer":
				var k: float = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
				open3 = 0.15 + 0.55 * k
				crouch2 = k
			elif state == "frappe":
				open3 = 0.02
			if _jaw_up != null:
				_jaw_up.rotation.x = lerpf(_jaw_up.rotation.x, -open3 * 0.7, clampf(delta * 14.0, 0.0, 1.0))
				_jaw_low.rotation.x = lerpf(_jaw_low.rotation.x, open3 * 0.5, clampf(delta * 14.0, 0.0, 1.0))
			for l2 in _legs:
				var leg2: Node3D = l2[0]
				var ph2: float = (0.0 if float(l2[1]) > 0.0 else PI) + (0.0 if float(l2[2]) > 0.0 else PI)
				leg2.rotation.x = sin(walk2 + ph2) * (0.5 if moving else 0.03)
			for i2 in range(_tail.size()):
				var seg2: Node3D = _tail[i2][0]
				seg2.rotation.y = sin(_clock * (4.0 if moving else 1.2) - i2 * 0.6) * (0.22 if moving else 0.08) * (1.0 + i2 * 0.15)
			if _croco_body != null:
				_croco_body.position.y = lerpf(_croco_body.position.y, (0.34 - crouch2 * 0.12) * 2.7, clampf(delta * 8.0, 0.0, 1.0))
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


## Le butin (monstres_v36._on_died).
func loot(rng: RandomNumberGenerator) -> Array:
	match kind:
		"momie":
			var g: Array = [["piece", rng.randi_range(2, 6)]]
			if rng.randf() < 0.2:
				g.append(["scarabee", 1])
			return g
		"jaguar":
			var g2: Array = [["piece", rng.randi_range(1, 4)]]
			if rng.randf() < 0.5:
				g2.append(["os_jaguar", 1])
			return g2
		"jaguar_pierre":
			return [["piece", rng.randi_range(2, 5)], ["obsidienne", 1]] if rng.randf() < 0.3 else [["piece", rng.randi_range(2, 5)]]
		"chauve_souris":
			return [["piece", rng.randi_range(0, 2)]]
		"ammit":
			return [["piece", rng.randi_range(4, 8)]]
		"apophis", "camazotz", "cipactli":
			return [["piece", rng.randi_range(40, 60)], ["piece_or", 2]]
	return super.loot(rng)


func alert_text() -> String:
	match kind:
		"momie":
			return "Une momie ! Lente, mais solide. Quand elle tend les bras, écarte-toi (ou roule, Ctrl), puis frappe-la. Les bandelettes, ça s'effiloche."
		"jaguar", "jaguar_pierre":
			return "Un jaguar ! Quand il se tapit, il va bondir : écarte-toi au dernier moment, puis frappe-le pendant qu'il se reprend."
		"chauve_souris":
			return "Des chauves-souris ! Elles volent à hauteur de tête et piquent sur toi : frappe-les quand elles plongent."
		"ammit":
			return "AMMIT LA DÉVOREUSE ! La mangeuse de cœurs : tête de crocodile, corps de lion et d'hippopotame. Esquive ses charges, frappe quand elle se reprend."
		"apophis":
			return "APOPHIS, LE SERPENT DU CHAOS ! L'ennemi de Rê, qui veut avaler le soleil chaque nuit. Recule quand il dresse la tête, frappe-le quand il retombe."
		"camazotz":
			return "CAMAZOTZ, LA CHAUVE-SOURIS DE LA MORT ! Il a tranché la tête de Hunahpu, dit le Popol Vuh. Esquive ses plongeons, frappe-le quand il se pose."
		"cipactli":
			return "CIPACTLI, LE MONSTRE DE LA TERRE ! Les dieux ont fait le monde de son corps. Il plonge et resurgit : reste en mouvement, frappe-le quand il se lance."
	return super.alert_text()

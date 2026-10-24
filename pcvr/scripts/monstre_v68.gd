extends "res://scripts/monstre_v63.gd"
## V68 : les monstres de l'Île de la Balafre. Même règle que les autres (groupe « cibles_v28 »,
## take_hit, butin, conseil à la première rencontre) :
##  - le crocodile du Marais des Noyés : il ouvre grand la gueule, s'aplatit… et se jette en
##    avant en refermant les mâchoires (un bond, comme la vipère) ;
##  - Vieille-Dent, le crocodile géant du marais (le chef des crocodiles) ;
##  - le squelette de pirate (le Fort Maudit, le cimetière la nuit, le Cirque du Crâne) : des os
##    qui tiennent ensemble on ne sait comment, un coutelas rouillé ; il sort de terre ;
##  - le Capitaine Sans-Chair, l'ancien capitaine de Barbe-Sanglante, qui garde le trésor du
##    Rocher du Crâne : un grand squelette en tricorne et manteau rouge, un sabre énorme ; il
##    rappelle ses hommes d'outre-tombe, et fait tournoyer son sabre tout autour de lui.

const HeroLib68 = preload("res://scripts/hero_v28.gd")
const SPECS68 := {
	"crocodile": {"pv": 18, "vitesse": 2.1, "degats": 1, "portee": 2.5, "armer": 0.6, "repos": 1.5, "vue": 11.0, "laisse": 16.0,
		"rayon": 0.55, "haut": 0.35, "nom": "Crocodile du marais", "bond": 7.5},
	"vieille_dent": {"pv": 70, "vitesse": 2.0, "degats": 2, "portee": 3.8, "armer": 0.75, "repos": 1.6, "vue": 18.0, "laisse": 26.0,
		"rayon": 1.0, "haut": 0.6, "nom": "Vieille-Dent", "bond": 9.0, "chef": true},
	"squelette": {"pv": 16, "vitesse": 1.9, "degats": 1, "portee": 1.9, "armer": 0.65, "repos": 1.4, "vue": 12.0, "laisse": 18.0,
		"rayon": 0.4, "haut": 1.0, "nom": "Squelette de pirate"},
	"capitaine_os": {"pv": 140, "vitesse": 1.8, "degats": 2, "portee": 2.9, "armer": 0.9, "repos": 1.3, "vue": 22.0, "laisse": 34.0,
		"rayon": 0.7, "haut": 1.6, "nom": "le Capitaine Sans-Chair", "chef": true},
}
const SOUNDS68 := {"crocodile": ["croco_menace", "croco_mort"], "vieille_dent": ["croco_menace", "croco_mort"],
	"squelette": ["squelette_menace", "squelette_mort"], "capitaine_os": ["squelette_menace", "boss_coeur_cri"]}

var _jaw_up: Node3D
var _jaw_low: Node3D
var _croco_body: Node3D
var _emerge: float = 0.0
var _cutlass: Node3D
var _summons: int = 0
var _eye_light: OmniLight3D


func _v63() -> bool:
	return SPECS68.has(kind) or super._v63()


func _leaper() -> bool:
	return kind in ["crocodile", "vieille_dent"] or super._leaper()


func _sound_pair() -> Array:
	return SOUNDS68.get(kind, super._sound_pair())


func _armer_anim() -> void:
	if kind in ["squelette", "capitaine_os"]:
		_play("v28/slash3", 0.1, 0.6 if kind == "squelette" else 0.48)
	else:
		super._armer_anim()


func is_chef() -> bool:
	return bool(spec.get("chef", false))


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS68.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS68[k]
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	match k:
		"crocodile", "vieille_dent":
			var s: float = 1.0 if k == "crocodile" else 1.8
			var cap := CapsuleShape3D.new()
			cap.radius = 0.34 * s
			cap.height = 2.6 * s
			cs.shape = cap
			cs.rotation.x = PI * 0.5
			cs.position = Vector3(0, 0.34 * s, -0.2 * s)
		"squelette", "capitaine_os":
			var s2: float = 1.0 if k == "squelette" else 1.55
			var cap2 := CapsuleShape3D.new()
			cap2.radius = 0.32 * s2
			cap2.height = 1.8 * s2
			cs.shape = cap2
			cs.position.y = 0.9 * s2
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"crocodile":
			_build_croco(1.0)
		"vieille_dent":
			_build_croco(1.8)
		"squelette":
			_build_squelette(1.0, false)
		"capitaine_os":
			_build_squelette(1.55, true)
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


## Sortir de terre (les squelettes du cimetière, la nuit ; le Capitaine Sans-Chair).
func emerge(t: float = 1.6) -> void:
	_emerge = t
	_visual.position.y = -1.9 * (1.55 if kind == "capitaine_os" else 1.0)
	state = "veille"


# =================================================================== le crocodile

func _croc_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/pirates/croco.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/pirates/croco_n.png")
	m.normal_scale = 1.4
	m.roughness = 0.55
	m.metallic_specular = 0.5
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(1.6, 1.6, 1.6)
	if kind == "vieille_dent":
		m.albedo_color = Color(0.72, 0.74, 0.62)
	_flash_mats.append(m)
	return m


## Le crocodile : une tête plate aux deux mâchoires, un corps bas, une longue queue qui ondule,
## quatre pattes écartées. Il regarde vers +Z.
func _build_croco(s: float) -> void:
	var skin := _croc_mat()
	var belly := _mat(Color(0.62, 0.6, 0.44), 0.7)
	_flash_mats.append(belly)
	var teeth := _mat(Color(0.95, 0.92, 0.82), 0.4)
	var eye := _mat(Color(0.95, 0.75, 0.15), 0.2, 1.5)
	_croco_body = Node3D.new()
	_croco_body.name = "Corps"
	_croco_body.position = Vector3(0, 0.34 * s, 0)
	_croco_body.scale = Vector3.ONE * s
	_visual.add_child(_croco_body)
	# le tronc
	_mesh(_croco_body, _sphere(0.42), skin, Vector3(0, 0.0, 0.0), Vector3(1.05, 0.62, 1.9))
	_mesh(_croco_body, _sphere(0.36), belly, Vector3(0, -0.12, 0.0), Vector3(1.0, 0.4, 1.8))
	for k in range(6):
		_mesh(_croco_body, _box_mesh_g(Vector3(0.1, 0.08, 0.14)), skin, Vector3((k % 2) * 0.16 - 0.08, 0.25, -0.6 + k * 0.24))
	# la tête et les mâchoires
	var head := Node3D.new()
	head.position = Vector3(0, 0.04, 0.78)
	_croco_body.add_child(head)
	_mesh(head, _sphere(0.24), skin, Vector3(0, 0.0, 0.0), Vector3(1.0, 0.7, 1.0))
	for sx in [-0.12, 0.12]:
		_mesh(head, _sphere(0.055), eye, Vector3(sx, 0.15, 0.04))
	_jaw_up = Node3D.new()
	_jaw_up.position = Vector3(0, 0.02, 0.12)
	head.add_child(_jaw_up)
	_mesh(_jaw_up, _box_mesh_g(Vector3(0.3, 0.1, 0.7)), skin, Vector3(0, 0.02, 0.35), Vector3(1, 1, 1))
	_mesh(_jaw_up, _sphere(0.08), skin, Vector3(0, 0.05, 0.68), Vector3(1.4, 0.7, 1.0))
	_jaw_low = Node3D.new()
	_jaw_low.position = Vector3(0, -0.06, 0.12)
	head.add_child(_jaw_low)
	_mesh(_jaw_low, _box_mesh_g(Vector3(0.27, 0.07, 0.66)), belly, Vector3(0, -0.02, 0.33))
	for k2 in range(7):
		for sx2 in [-0.12, 0.12]:
			_mesh(_jaw_up, _cyl(0.0, 0.022, 0.07), teeth, Vector3(sx2, -0.06, 0.12 + k2 * 0.09), Vector3.ONE, _r(Vector3(180, 0, 0)))
			_mesh(_jaw_low, _cyl(0.0, 0.02, 0.06), teeth, Vector3(sx2 * 0.92, 0.04, 0.15 + k2 * 0.08))
	# la queue : des segments emboîtés qui ondulent
	var prev: Node3D = _croco_body
	var z: float = -0.75
	for t in range(6):
		var seg := Node3D.new()
		seg.position = Vector3(0, -0.02, z)
		prev.add_child(seg)
		var r: float = 0.3 * (1.0 - t * 0.14)
		_mesh(seg, _sphere(r), skin, Vector3(0, 0, -r * 0.9), Vector3(0.95, 0.65, 1.5))
		_mesh(seg, _box_mesh_g(Vector3(0.05, 0.1, r * 1.2)), skin, Vector3(0, r * 0.6, -r * 0.9))
		_tail.append([seg, 0.0])
		prev = seg
		z = -r * 1.8
	# les pattes
	for side in [-1.0, 1.0]:
		for fz in [0.45, -0.45]:
			var hip := Node3D.new()
			hip.position = Vector3(side * 0.36, -0.06, fz)
			_croco_body.add_child(hip)
			_mesh(hip, _cyl(0.07, 0.09, 0.32), skin, Vector3(side * 0.14, -0.04, 0), Vector3.ONE, _r(Vector3(0, 0, -side * 75)))
			_mesh(hip, _cyl(0.05, 0.07, 0.26), skin, Vector3(side * 0.3, -0.18, 0.02), Vector3.ONE, _r(Vector3(0, 0, -side * 15)))
			_mesh(hip, _sphere(0.08), skin, Vector3(side * 0.33, -0.3, 0.06), Vector3(1.2, 0.4, 1.4))
			_legs.append([hip, side, fz])


# =================================================================== les squelettes

func _bone_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/pirates/os.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/pirates/os_n.png")
	m.roughness = 0.72
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(3, 3, 3)
	_flash_mats.append(m)
	return m


## Un os (un bâton arrondi) dans l'attache de l'os « bone_name », jusqu'à l'os enfant « child ».
func _bone_stick(skel: Skeleton3D, bone_name: String, child: String, r: float, mat: Material) -> void:
	var b: int = skel.find_bone(bone_name)
	var c: int = skel.find_bone(child)
	if b < 0 or c < 0:
		return
	var v: Vector3 = skel.get_bone_global_rest(c).origin - skel.get_bone_global_rest(b).origin
	var len_m: float = v.length() * 0.01
	if len_m < 0.01:
		return
	var holder := Node3D.new()
	var dir: Vector3 = v.normalized()
	var xb: Vector3 = dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var zb: Vector3 = xb.cross(dir).normalized()
	holder.transform = Transform3D(Basis(xb, dir, zb), dir * len_m * 0.5)
	_mesh(holder, _cyl(r * 0.8, r, len_m * 0.92), mat, Vector3.ZERO)
	_mesh(holder, _sphere(r * 1.25), mat, Vector3(0, len_m * 0.46, 0))
	_mesh(holder, _sphere(r * 1.25), mat, Vector3(0, -len_m * 0.46, 0))
	_attach(skel, bone_name, Vector3.ZERO, holder)


## Le squelette de pirate : la silhouette du héros (pour les mouvements), mais rien que les os ;
## un crâne aux orbites qui luisent, une cage thoracique, un foulard rouge, un coutelas rouillé.
## Le Capitaine : plus grand, tricorne, manteau rouge en lambeaux, un sabre énorme.
func _build_squelette(s: float, captain: bool) -> void:
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
	if skel == null:
		return
	var bone := _bone_mat()
	var dark := _mat(Color(0.03, 0.03, 0.03), 0.9)
	var glow := _mat(Color(0.45, 1.0, 0.5), 0.2, 5.0)
	# la colonne, les membres
	for pair in [["Hips", "Spine"], ["Spine", "Spine01"], ["Spine01", "Spine02"], ["Spine02", "neck"], ["neck", "Head"],
			["LeftShoulder", "LeftArm"], ["LeftArm", "LeftForeArm"], ["LeftForeArm", "LeftHand"],
			["RightShoulder", "RightArm"], ["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"],
			["LeftUpLeg", "LeftLeg"], ["LeftLeg", "LeftFoot"], ["LeftFoot", "LeftToeBase"],
			["RightUpLeg", "RightLeg"], ["RightLeg", "RightFoot"], ["RightFoot", "RightToeBase"],
			["Spine02", "LeftShoulder"], ["Spine02", "RightShoulder"], ["Hips", "LeftUpLeg"], ["Hips", "RightUpLeg"]]:
		var thick: float = 0.035 if str(pair[0]).contains("Arm") or str(pair[0]).contains("Leg") else 0.028
		if str(pair[0]).begins_with("Spine") or pair[0] == "Hips" or pair[0] == "neck":
			thick = 0.03
		_bone_stick(skel, str(pair[0]), str(pair[1]), thick, bone)
	# la cage thoracique : des côtes (des anneaux aplatis)
	var ribs := Node3D.new()
	for k in range(5):
		var tm := TorusMesh.new()
		tm.inner_radius = 0.1 - k * 0.006
		tm.outer_radius = 0.125 - k * 0.006
		tm.rings = 12
		tm.ring_segments = 5
		var r := MeshInstance3D.new()
		r.mesh = tm
		r.material_override = bone
		r.position = Vector3(0, 0.06 - k * 0.055, 0.02)
		r.scale = Vector3(1.1, 1.0, 0.75)
		ribs.add_child(r)
	_attach(skel, "Spine02", Vector3(0, 4, 0), ribs)
	# le bassin
	var pelvis := Node3D.new()
	_mesh(pelvis, _sphere(0.11), bone, Vector3(0, 0, 0), Vector3(1.3, 0.55, 0.8))
	_attach(skel, "Hips", Vector3(0, 2, 0), pelvis)
	# les mains et les pieds (des os plats)
	for hb in ["LeftHand", "RightHand"]:
		var hn := Node3D.new()
		_mesh(hn, _box_mesh_g(Vector3(0.07, 0.1, 0.03)), bone, Vector3(0, -0.05, 0))
		_attach(skel, hb, Vector3(0, -2, 0), hn)
	# le crâne
	var skull := Node3D.new()
	_mesh(skull, _sphere(0.11), bone, Vector3(0, 0.02, 0), Vector3(0.9, 1.0, 1.05))
	_mesh(skull, _box_mesh_g(Vector3(0.12, 0.06, 0.1)), bone, Vector3(0, -0.08, 0.04))
	for sx in [-0.04, 0.04]:
		_mesh(skull, _sphere(0.032), dark, Vector3(sx, 0.02, 0.085))
		_mesh(skull, _sphere(0.014), glow, Vector3(sx, 0.02, 0.1))
	_mesh(skull, _box_mesh_g(Vector3(0.02, 0.03, 0.02)), dark, Vector3(0, -0.02, 0.105))
	for t in range(5):
		_mesh(skull, _box_mesh_g(Vector3(0.012, 0.022, 0.01)), dark, Vector3(-0.036 + t * 0.018, -0.075, 0.095))
	_attach(skel, "Head", Vector3(0, 9, 1), skull)
	# le foulard ou le tricorne, le manteau
	var cloth := _mat(Color(0.58, 0.1, 0.08) if not captain else Color(0.45, 0.05, 0.05), 0.95)
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flash_mats.append(cloth)
	if captain:
		var hat := Node3D.new()
		var hm := _mat(Color(0.06, 0.05, 0.05), 0.85)
		_mesh(hat, _cyl(0.2, 0.22, 0.04), hm, Vector3(0, 0.0, 0))
		_mesh(hat, _cyl(0.09, 0.11, 0.12), hm, Vector3(0, 0.06, 0))
		for k2 in range(3):
			var a: float = TAU * k2 / 3.0 + PI / 6.0
			_mesh(hat, _box_mesh_g(Vector3(0.24, 0.1, 0.02)), hm, Vector3(cos(a) * 0.14, 0.06, sin(a) * 0.14), Vector3.ONE, _r(Vector3(0, -rad_to_deg(a) + 90.0, -12)))
		_mesh(hat, _box_mesh_g(Vector3(0.08, 0.04, 0.01)), _mat(Color(0.9, 0.75, 0.3), 0.3), Vector3(0, 0.07, 0.15))
		_attach(skel, "Head", Vector3(0, 19, 0), hat)
		var coat := Node3D.new()
		_mesh(coat, _box_mesh_np68(Vector3(0.44, 0.75, 0.02)), cloth, Vector3(0, -0.42, -0.14))
		for sx2 in [-1.0, 1.0]:
			_mesh(coat, _box_mesh_np68(Vector3(0.14, 0.7, 0.02)), cloth, Vector3(sx2 * 0.2, -0.4, 0.06), Vector3.ONE, _r(Vector3(0, sx2 * 25.0, 0)))
		_attach(skel, "Spine02", Vector3(0, 8.0, 0.0), coat)
		var ep := _mat(Color(0.85, 0.68, 0.25), 0.3)
		for side in [["LeftShoulder", -1.0], ["RightShoulder", 1.0]]:
			var e := Node3D.new()
			_mesh(e, _sphere(0.07), ep, Vector3.ZERO, Vector3(1.5, 0.4, 1.2))
			_attach(skel, str(side[0]), Vector3(float(side[1]) * 9.0, 5, 0), e)
		_eye_light = OmniLight3D.new()
		_eye_light.light_color = Color(0.45, 1.0, 0.5)
		_eye_light.light_energy = 1.2
		_eye_light.omni_range = 5.0
		_eye_light.position = Vector3(0, 2.7, 0.4)
		_visual.add_child(_eye_light)
	else:
		var band := Node3D.new()
		_mesh(band, _cyl(0.12, 0.12, 0.05), cloth, Vector3(0, 0, 0), Vector3(1.0, 1.0, 1.1))
		_mesh(band, _box_mesh_np68(Vector3(0.05, 0.16, 0.02)), cloth, Vector3(0.0, -0.08, -0.12), Vector3.ONE, _r(Vector3(20, 0, 0)))
		_attach(skel, "Head", Vector3(0, 13, -0.5), band)
		var sash := Node3D.new()
		_mesh(sash, _box_mesh_np68(Vector3(0.3, 0.06, 0.2)), cloth, Vector3.ZERO)
		_attach(skel, "Hips", Vector3(0, 8, 0), sash)
	# le coutelas (le sabre du Capitaine)
	var rust := _mat(Color(0.5, 0.36, 0.26) if not captain else Color(0.72, 0.74, 0.76), 0.5)
	rust.metallic = 0.6
	_cutlass = Node3D.new()
	var bl: float = 0.75 if not captain else 1.05
	_mesh(_cutlass, _box_mesh_g(Vector3(0.05, bl, 0.012)), rust, Vector3(0.012, bl * 0.5 + 0.1, 0), Vector3.ONE, _r(Vector3(0, 0, -4)))
	_mesh(_cutlass, _box_mesh_g(Vector3(0.16, 0.03, 0.05)), _mat(Color(0.5, 0.4, 0.2), 0.4), Vector3(0, 0.08, 0))
	_mesh(_cutlass, _cyl(0.022, 0.022, 0.13), _mat(Color(0.2, 0.12, 0.08), 0.8), Vector3(0, -0.03, 0))
	var att := BoneAttachment3D.new()
	att.bone_name = "RightHand"
	skel.add_child(att)
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	hold.rotation_degrees = Vector3(90, 0, 0)
	hold.scale = Vector3.ONE * 100.0
	att.add_child(hold)
	hold.add_child(_cutlass)
	_play("v28/idle")


func _r(d: Vector3) -> Vector3:
	return d * (PI / 180.0)


func _box_mesh_np68(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


# =================================================================== comportement

func take_hit(damage: int, from_pos: Vector3) -> void:
	if SPECS68.has(kind) and _emerge > 0.0:
		return
	super.take_hit(damage, from_pos)
	if SPECS68.has(kind) and kind in ["squelette", "capitaine_os"] and state == "recul" and _anim != null:
		_play("v28/hurt", 0.05)
	if SPECS68.has(kind) and manager != null and manager.main.has_method("sfx") and kind in ["squelette", "capitaine_os"] and state != "mort":
		manager.main.sfx("os_choc", global_position + Vector3.UP * hit_height)


func _die63() -> void:
	super._die63()
	if kind in ["squelette", "capitaine_os"]:
		_play("Knock_Down", 0.1)
		if _eye_light != null:
			_eye_light.light_energy = 0.0


func _physics_process(delta: float) -> void:
	if _emerge > 0.0:
		_emerge -= delta
		var hmax: float = 1.9 * (1.55 if kind == "capitaine_os" else 1.0)
		_visual.position.y = -hmax * clampf(_emerge / 1.6, 0.0, 1.0)
		_clock += delta
		if _anim != null:
			_play("v28/idle", 0.2)
		return
	super._physics_process(delta)


func _boss_tick(delta: float, dist: float) -> void:
	if kind != "capitaine_os":
		super._boss_tick(delta, dist)
		return
	_special_t += delta
	# il rappelle ses hommes à deux tiers et à un tiers de ses forces
	var pv: int = int(spec["pv"])
	if (_summons == 0 and hp < pv * 2 / 3) or (_summons == 1 and hp < pv / 3):
		_summons += 1
		for k in range(2):
			var a: float = TAU * k / 2.0 + randf() * 0.5
			var at: Vector3 = global_position + Vector3(cos(a) * 3.5, 0.1, sin(a) * 3.5)
			var m: Node3D = manager.spawn_extra("squelette", at)
			m.home = at
			if m.has_method("emerge"):
				m.emerge()
		_hint68("Le Capitaine Sans-Chair lève son sabre : « Debout, mes gars ! » Des squelettes sortent de terre !")
		if manager.main.has_method("sfx"):
			manager.main.sfx("squelette_menace", global_position + Vector3.UP * 2.0)
	# le sabre qui tournoie : une onde tout autour (recule !)
	if _special_t > 8.0 and dist < 5.0 and state == "chasse":
		_special_t = 0.0
		state = "souffle"
		timer = 1.0
		_play("v28/slash3", 0.05, 0.9)
		_shockwave(global_position)
		_hint68("Le Capitaine fait tournoyer son sabre tout autour de lui !")


func _hint68(t: String) -> void:
	if _clock - _last_hint < 3.0:
		return
	_last_hint = _clock
	var p: Node = manager.main.get("pirates_v68") if manager != null else null
	if p != null and p.has_method("say"):
		p.say(t, 4.0)
	elif manager != null and manager.donjon != null:
		manager.donjon._say(t, 3.5)


func _puff_color() -> Color:
	match kind:
		"crocodile", "vieille_dent":
			return Color(0.5, 0.55, 0.35)
		"squelette", "capitaine_os":
			return Color(0.92, 0.9, 0.82)
	return super._puff_color()


func _death_tick(delta: float) -> void:
	if not SPECS68.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	if kind in ["crocodile", "vieille_dent"]:
		_visual.rotation.z = minf(timer * 3.0, PI)
		_visual.position.y = sin(minf(timer * 3.0, PI)) * 0.3
	if timer > 2.0:
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - 2.0) / 0.8, 0.01, 1.0)
	if timer > 2.8:
		visible = false
		set_physics_process(false)


func _animate63(delta: float, speed: float) -> void:
	if not SPECS68.has(kind):
		super._animate63(delta, speed)
		return
	var moving: bool = speed > 0.2
	match kind:
		"crocodile", "vieille_dent":
			var walk: float = _clock * (7.0 + speed * 3.0)
			var open: float = 0.05 + 0.05 * sin(_clock * 0.7)
			var crouch: float = 0.0
			if state == "armer":
				var k: float = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
				open = 0.15 + 0.55 * k
				crouch = k
			elif state == "frappe":
				open = 0.02
			elif state == "souffle":
				open = 0.08
			if _jaw_up != null:
				_jaw_up.rotation.x = lerpf(_jaw_up.rotation.x, -open * 0.7, clampf(delta * 14.0, 0.0, 1.0))
				_jaw_low.rotation.x = lerpf(_jaw_low.rotation.x, open * 0.5, clampf(delta * 14.0, 0.0, 1.0))
			for l in _legs:
				var leg: Node3D = l[0]
				var ph: float = (0.0 if float(l[1]) > 0.0 else PI) + (0.0 if float(l[2]) > 0.0 else PI)
				leg.rotation.x = sin(walk + ph) * (0.5 if moving else 0.03)
			for i in range(_tail.size()):
				var seg: Node3D = _tail[i][0]
				seg.rotation.y = sin(_clock * (5.0 if moving else 1.4) - i * 0.6) * (0.22 if moving else 0.08) * (1.0 + i * 0.15)
			if _croco_body != null:
				_croco_body.position.y = lerpf(_croco_body.position.y, (0.34 - crouch * 0.12) * (1.0 if kind == "crocodile" else 1.8), clampf(delta * 8.0, 0.0, 1.0))
				_croco_body.rotation.y = sin(_clock * 5.0) * 0.06 if moving else 0.0
		"squelette", "capitaine_os":
			if _anim != null and not (state in ["armer", "frappe", "mort", "recul"]):
				if state == "etourdi":
					_anim.pause()
				elif moving:
					_play("Walking", 0.2, maxf(speed / (1.2 if kind == "squelette" else 1.6), 0.6))
				else:
					_play("v28/idle", 0.3)
			if _eye_light != null:
				_eye_light.light_energy = 1.0 + sin(_clock * 3.0) * 0.3
	if _stars != null and _stars.visible:
		_stars.rotation.y += delta * 4.0


## Le butin (monstres_v36._on_died).
func loot(rng: RandomNumberGenerator) -> Array:
	match kind:
		"crocodile":
			var g: Array = [["piece", rng.randi_range(1, 4)]]
			if rng.randf() < 0.6:
				g.append(["dent_croco", 1])
			return g
		"vieille_dent":
			return [["piece", rng.randi_range(15, 25)], ["dent_croco", 3], ["croc_geant", 1]]
		"squelette":
			var g2: Array = [["piece", rng.randi_range(2, 6)]]
			if rng.randf() < 0.18:
				g2.append(["piece_or", 1])
			return g2
		"capitaine_os":
			return [["piece", rng.randi_range(40, 60)], ["piece_or", 3]]
	return super.loot(rng)


func alert_text() -> String:
	match kind:
		"crocodile":
			return "Un crocodile ! Quand il ouvre grand la gueule et s'aplatit, il va se jeter sur toi : écarte-toi (ou roule, Ctrl), puis frappe-le pendant qu'il se remet."
		"vieille_dent":
			return "VIEILLE-DENT ! Le roi des crocodiles du marais, long comme une barque. Sa gueule porte loin : attends qu'il se jette dans le vide, puis frappe."
		"squelette":
			return "Un squelette de pirate ! Il lève son coutelas avant de frapper : pare (F) ou roule (Ctrl), puis frappe. Les os, ça se casse."
		"capitaine_os":
			return "LE CAPITAINE SANS-CHAIR ! L'ancien second de Barbe-Sanglante garde encore le trésor. Recule quand il fait tournoyer son sabre, et méfie-toi : il appelle ses hommes d'outre-tombe."
	return super.alert_text()

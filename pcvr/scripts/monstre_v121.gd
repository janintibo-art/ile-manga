extends "res://scripts/monstre_v90.gd"
## V121 : les morts-vivants de Sombreval, la ville morte. Ce sont les anciens habitants de la ville :
## de vrais corps (les mêmes que ceux des habitants, corps_v64), la peau grise et marbrée, les yeux
## creusés, les habits sales et déchirés. Ils ne parlent pas : ils grognent (des sons en 3D). Le
## comte Dracula les tient sous son pouvoir depuis son château, en haut de la Butte du Comte.
##  - le mort-vivant (« zombie ») : il traîne la jambe, les bras tendus, la tête penchée ; il ne
##    s'arrête jamais. Quand il lève les bras, il va t'agripper : recule, ou frappe avant ;
##  - le mort-vivant enragé (« zombie_coureur ») : il hurle quand il te voit… et il COURT ;
##  - le colosse (« zombie_lourd ») : énorme, lent, il frappe fort et encaisse beaucoup ;
##  - certains sont couchés par terre, comme morts… jusqu'à ce que tu passes à côté.
## Vaincus : en « Tout public », ils tombent en poussière dans un peu de lumière ; en « Public
## averti », ils saignent (des gouttes à chaque coup) et restent un moment à terre, dans une flaque.
## Même règle que les autres monstres (groupe « cibles_v28 », take_hit, butin, un conseil à la
## première rencontre).

const Corps121 = preload("res://scripts/pnj/corps_v64.gd")
const Public121 = preload("res://scripts/public_v111.gd")
const HeroLib121 = preload("res://scripts/hero_v28.gd")

const SPECS121 := {
	"zombie": {"pv": 16, "vitesse": 1.25, "degats": 1, "portee": 1.7, "armer": 0.62, "repos": 1.3, "vue": 20.0, "laisse": 80.0,
		"rayon": 0.42, "haut": 0.9, "nom": "Mort-vivant"},
	"zombie_coureur": {"pv": 12, "vitesse": 4.3, "degats": 1, "portee": 1.9, "armer": 0.42, "repos": 1.1, "vue": 30.0, "laisse": 110.0,
		"rayon": 0.42, "haut": 0.9, "nom": "Mort-vivant enragé"},
	"zombie_lourd": {"pv": 46, "vitesse": 0.95, "degats": 2, "portee": 2.1, "armer": 0.95, "repos": 1.7, "vue": 18.0, "laisse": 70.0,
		"rayon": 0.6, "haut": 1.0, "nom": "Colosse mort-vivant", "chef": true},
}
const SOUNDS121 := {"zombie": ["zombie_grogne", "zombie_mort"], "zombie_coureur": ["zombie_cri", "zombie_mort"], "zombie_lourd": ["zombie_grogne", "zombie_mort"]}
## Les corps des anciens habitants (des corps d'adultes ; on saute ceux qui manquent)
const CORPS := ["abdellah", "adele", "agathe", "ambroise", "anselme", "aristide", "aubin", "augustin", "babette", "bastien", "bernard", "berthe",
	"bertrand", "bruno", "brutus", "anne_rose", "barthelemy", "brahim", "amine", "anouk"]
const CORPS_LOURDS := ["brutus", "bertrand", "bruno", "bernard"]
## Des habits ternis, salis (couleur, couleur 2)
const SALES := [[0.24, 0.22, 0.2], [0.3, 0.27, 0.22], [0.2, 0.22, 0.24], [0.33, 0.3, 0.26], [0.26, 0.2, 0.18], [0.18, 0.2, 0.17], [0.36, 0.34, 0.3]]

static var _cache: Dictionary = {}        # id -> {"d": données du corps, "pieces": [[nom, maillage, peau (Skin), matière, ombre, portée]]}
static var _zlib: AnimationLibrary = null

var _skel121: Skeleton3D
var _anim121: AnimationPlayer
var _model121: Node3D
var _skin_mats121: Array = []
var _cur121: String = ""
var _groan121: float = 3.0
var _wall121: float = 0.0
var _side121: float = 1.0
var _wobble121: float = 0.0
var _hit121: bool = false
var _corps121: String = ""
var _coup121: float = 0.0
var _dust121: bool = false
var _pool121: MeshInstance3D
var _seen121: bool = false
var gisant: bool = false                  # couché par terre au départ (il se relève quand on approche)


# =================================================================== aiguillage

func _v63() -> bool:
	return SPECS121.has(kind) or super._v63()


func _leaper() -> bool:
	return false if SPECS121.has(kind) else super._leaper()


func _sound_pair() -> Array:
	return SOUNDS121.get(kind, super._sound_pair())


func is_boss() -> bool:
	return false if SPECS121.has(kind) else super.is_boss()


func is_chef() -> bool:
	if SPECS121.has(kind):
		return bool(spec.get("chef", false))
	return super.is_chef()


func is_hittable() -> bool:
	if SPECS121.has(kind):
		return state != "mort"
	return super.is_hittable()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS121.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = (SPECS121[k] as Dictionary).duplicate()
	_base_speed = float(spec["vitesse"]) * randf_range(0.88, 1.12)
	spec["vitesse"] = _base_speed
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.34 if k != "zombie_lourd" else 0.48
	c.height = 1.75 if k != "zombie_lourd" else 2.1
	cs.shape = c
	cs.position.y = c.height * 0.5
	add_child(cs)
	_cs71 = cs
	_visual = Node3D.new()
	add_child(_visual)
	_build_body121()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	rotation.y = atan2(facing.x, facing.z)
	_say_next = 1e9
	_side121 = 1.0 if randf() < 0.5 else -1.0
	_groan121 = randf_range(1.0, 6.0)
	_wobble121 = randf() * TAU
	if gisant:
		lie_down()


## Couché par terre, comme mort (avant que le joueur n'approche)
func lie_down() -> void:
	gisant = true
	state = "gisant"
	_play121("zb/gisant", 0.0)


# =================================================================== le corps

func _build_body121() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	_model121 = packed.instantiate()
	_visual.add_child(_model121)
	_anim121 = _model121.find_child("AnimationPlayer", true, false)
	var found := _model121.find_children("*", "Skeleton3D", true, false)
	_skel121 = found[0] if found.size() > 0 else null
	if _skel121 == null or _anim121 == null:
		return
	if _zlib == null:
		_zlib = _make_library(_model121, _anim121, _skel121)
	if not _anim121.has_animation_library("zb"):
		_anim121.add_animation_library("zb", _zlib)
	# le corps : un ancien habitant
	var ids: Array = (CORPS_LOURDS if kind == "zombie_lourd" else CORPS).duplicate()
	ids.shuffle()
	var built: bool = false
	for id in ids:
		if Corps121.has_body(str(id)):
			built = _dress121(str(id))
			if built:
				break
	if not built:
		# pas de corps (données absentes) : l'ancien modèle, grisé
		for mi in _model121.find_children("*", "MeshInstance3D", true, false):
			var mm: MeshInstance3D = mi
			for s in range(mm.mesh.get_surface_count()):
				var sm := StandardMaterial3D.new()
				sm.albedo_color = Color(0.42, 0.46, 0.4)
				sm.roughness = 0.9
				mm.set_surface_override_material(s, sm)
	if kind == "zombie_lourd":
		_model121.scale *= 1.22
	_play121("zb/attente", 0.0)
	_anim121.seek(randf() * 2.0, true)


func _dress121(id: String) -> bool:
	if not _cache.has(id):
		var d: Dictionary = Corps121.read_bin(Corps121.DIR + id + ".bin")
		if d.is_empty() or float(d.get("scale", 1.0)) < 0.93:
			return false
		var tenue: Array = _tenue121(id)
		for mi0 in _model121.find_children("*", "MeshInstance3D", true, false):
			mi0.get_parent().remove_child(mi0)
			mi0.queue_free()
		var parts: Dictionary = Corps121.build_full(_model121, _skel121, _anim121, id, {"tenue": tenue, "sans_barbe": false})
		if parts.is_empty():
			return false
		_zombify_parts(parts)
		var pieces: Array = []
		for c in _skel121.get_children():
			if c is MeshInstance3D:
				var mi: MeshInstance3D = c
				pieces.append([str(mi.name), mi.mesh, mi.skin, mi.material_override, mi.cast_shadow, mi.visibility_range_end])
		_cache[id] = {"d": d, "pieces": pieces}
		_corps121 = id
		_model121.scale = Vector3.ONE * float(d.get("scale", 1.0))
		# la peau de ce zombie-ci (pour l'éclair des coups) : sa propre copie
		for c2 in _skel121.get_children():
			if c2 is MeshInstance3D and str(c2.name) in ["Corps64_peau", "Corps64_visage"]:
				var own: ShaderMaterial = ((c2 as MeshInstance3D).material_override as ShaderMaterial).duplicate()
				(c2 as MeshInstance3D).material_override = own
				_skin_mats121.append(own)
		_shared_skin121()
		return true
	var e: Dictionary = _cache[id]
	for mi1 in _model121.find_children("*", "MeshInstance3D", true, false):
		mi1.get_parent().remove_child(mi1)
		mi1.queue_free()
	Corps121.setup_skeleton(_skel121, _anim121, e["d"])
	if _skel121.get_node_or_null("Epaules64") == null:
		var ep = Corps121.Epaules.new()
		ep.name = "Epaules64"
		ep.setup(_skel121)
		_skel121.add_child(ep)
	var skin_mat: ShaderMaterial = null
	for p in e["pieces"]:
		var mi2 := MeshInstance3D.new()
		mi2.name = str(p[0])
		mi2.mesh = p[1]
		mi2.skin = p[2]
		var mat: Material = p[3]
		if str(p[0]) in ["Corps64_peau", "Corps64_visage"] and mat is ShaderMaterial:
			if skin_mat == null:
				skin_mat = (mat as ShaderMaterial).duplicate()
				_skin_mats121.append(skin_mat)
			mat = skin_mat
		mi2.material_override = mat
		mi2.cast_shadow = p[4]
		mi2.visibility_range_end = float(p[5])
		_skel121.add_child(mi2)
		mi2.skeleton = mi2.get_path_to(_skel121)
	_corps121 = id
	_model121.scale = Vector3.ONE * float((e["d"] as Dictionary).get("scale", 1.0))
	_shared_skin121()
	return true


## Le sang dépend du public choisi (on peut le changer en cours de partie)
func _shared_skin121() -> void:
	for m in _skin_mats121:
		(m as ShaderMaterial).set_shader_parameter("sang", 0.85 if Public121.averti() else 0.0)


func _tenue121(id: String) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash(id) + 121
	var c1: Array = SALES[r.randi() % SALES.size()]
	var c2: Array = SALES[r.randi() % SALES.size()]
	var c3: Array = SALES[r.randi() % SALES.size()]
	var haut: String = ["chemise_longue", "pull", "tshirt", "chemise_courte", "veste", "tunique_haut"][r.randi() % 6]
	var bas: String = ["pantalon", "pantalon", "jupe_longue", "pantacourt"][r.randi() % 4]
	var t: Array = [{"v": haut, "c": c1, "c2": c2, "tissu": "coton" if haut != "pull" else "laine"}, {"v": bas, "c": c2, "c2": c3, "tissu": "jean" if bas == "pantalon" else "coton"}]
	if r.randf() < 0.6:
		t.append({"v": "chaussures", "c": [0.12, 0.1, 0.09]})
	if haut in ["chemise_longue", "tshirt"] and r.randf() < 0.4:
		t.append({"v": "gilet", "c": c3})
	return t


## Les matières d'un corps de mort-vivant (partagées par tous ceux qui ont ce corps)
func _zombify_parts(parts: Dictionary) -> void:
	for k in ["peau", "visage"]:
		var mi: MeshInstance3D = parts.get(k)
		if mi != null and mi.material_override is ShaderMaterial:
			var sm: ShaderMaterial = mi.material_override
			sm.set_shader_parameter("mort_vivant", 1.0)
			sm.set_shader_parameter("rose", 0.0)
			sm.set_shader_parameter("levres_force", 0.35)
			sm.set_shader_parameter("age", 0.9)
			sm.set_shader_parameter("diffusion", 0.12)
	var ey: MeshInstance3D = parts.get("yeux")
	if ey != null and ey.material_override is ShaderMaterial:
		var em: ShaderMaterial = ey.material_override
		em.set_shader_parameter("iris", Color(0.78, 0.76, 0.6))
		em.set_shader_parameter("iris_lueur", 0.35)
	for sh in parts.get("shells", []) + parts.get("amples", []):
		var cm: Material = (sh[0] as MeshInstance3D).material_override
		if cm is ShaderMaterial:
			var c0: Variant = (cm as ShaderMaterial).get_shader_parameter("couleur")
			if c0 is Color:
				(cm as ShaderMaterial).set_shader_parameter("couleur", (c0 as Color).darkened(0.25).lerp(Color(0.25, 0.22, 0.17), 0.35))
			(cm as ShaderMaterial).set_shader_parameter("coutures", Vector3(0.3, 0.0, 0.0))
	for k2 in ["cheveux", "barbe"]:
		var mh: MeshInstance3D = parts.get(k2)
		if mh != null and mh.material_override is ShaderMaterial:
			var hm: ShaderMaterial = (mh.material_override as ShaderMaterial)
			for pn in ["couleur", "cheveux", "teinte"]:
				var hv: Variant = hm.get_shader_parameter(pn)
				if hv is Color:
					hm.set_shader_parameter(pn, (hv as Color).lerp(Color(0.32, 0.31, 0.29), 0.55))


## Les mouvements des morts-vivants (construits une fois pour toutes, sur le squelette du héros)
static func _make_library(model: Node3D, anim: AnimationPlayer, skel: Skeleton3D) -> AnimationLibrary:
	var lib = HeroLib121.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var z := AnimationLibrary.new()
	var bras := {"LeftArm": Vector3(-72, 0, 12), "RightArm": Vector3(-80, 0, -6), "LeftForeArm": Vector3(-14, 0, 0), "RightForeArm": Vector3(-22, 0, 0),
		"Spine02": Vector3(14, 0, 6), "Spine01": Vector3(6, 0, 0), "Head": Vector3(14, 12, 20), "neck": Vector3(-6, 0, 0)}
	# la marche : il traîne la jambe droite
	var m0 := _m121(bras, {"LeftUpLeg": Vector3(-24, 0, 0), "LeftLeg": Vector3(8, 0, 0), "RightUpLeg": Vector3(14, 0, 4), "RightLeg": Vector3(18, 0, 0), "RightFoot": Vector3(12, 0, 0),
		"LeftArm": Vector3(-68, 0, 14), "RightArm": Vector3(-84, 0, -8)})
	var m1 := _m121(bras, {"LeftUpLeg": Vector3(-6, 0, 0), "LeftLeg": Vector3(6, 0, 0), "RightUpLeg": Vector3(-12, 0, 6), "RightLeg": Vector3(34, 0, 0), "RightFoot": Vector3(25, 0, 0),
		"Spine02": Vector3(16, 0, 2)})
	var m2 := _m121(bras, {"RightUpLeg": Vector3(-12, 0, 6), "RightLeg": Vector3(10, 0, 0), "LeftUpLeg": Vector3(16, 0, 0), "LeftLeg": Vector3(16, 0, 0),
		"LeftArm": Vector3(-78, 0, 10), "RightArm": Vector3(-74, 0, -10), "Spine02": Vector3(15, 0, -2), "Head": Vector3(16, 6, 26)})
	var m3 := _m121(bras, {"RightUpLeg": Vector3(4, 0, 6), "RightLeg": Vector3(12, 0, 0), "LeftUpLeg": Vector3(-26, 0, 0), "LeftLeg": Vector3(52, 0, 0), "Spine02": Vector3(13, 0, 8)})
	z.add_animation("marche", lib._clip(1.6, true, [[0.0, m0, Vector3(0, -4, 0)], [0.4, m1, Vector3(0, -2, 0)], [0.8, m2, Vector3(1.5, -7, 0)], [1.2, m3, Vector3(1.0, -3, 0)], [1.6, m0, Vector3(0, -4, 0)]]))
	# la course de l'enragé : penché en avant, les bras qui battent devant lui
	var c0 := {"LeftArm": Vector3(-55, 0, 18), "RightArm": Vector3(-95, 0, -12), "LeftForeArm": Vector3(-30, 0, 0), "RightForeArm": Vector3(-20, 0, 0),
		"Spine02": Vector3(24, 0, 0), "Spine01": Vector3(10, 0, 0), "Head": Vector3(-14, 0, 8), "neck": Vector3(-8, 0, 0),
		"LeftUpLeg": Vector3(-55, 0, 0), "LeftLeg": Vector3(35, 0, 0), "RightUpLeg": Vector3(28, 0, 0), "RightLeg": Vector3(70, 0, 0)}
	var c1 := _m121(c0, {"LeftArm": Vector3(-95, 0, 12), "RightArm": Vector3(-55, 0, -18), "LeftUpLeg": Vector3(28, 0, 0), "LeftLeg": Vector3(70, 0, 0),
		"RightUpLeg": Vector3(-55, 0, 0), "RightLeg": Vector3(35, 0, 0), "Head": Vector3(-14, 0, -6)})
	z.add_animation("course", lib._clip(0.66, true, [[0.0, c0, Vector3(0, -8, 0)], [0.165, _m121(c0, {"LeftUpLeg": Vector3(-15, 0, 0), "RightUpLeg": Vector3(-10, 0, 0), "RightLeg": Vector3(95, 0, 0)}), Vector3(0, -2, 0)],
		[0.33, c1, Vector3(0, -8, 0)], [0.495, _m121(c1, {"LeftUpLeg": Vector3(-10, 0, 0), "RightUpLeg": Vector3(-15, 0, 0), "LeftLeg": Vector3(95, 0, 0)}), Vector3(0, -2, 0)], [0.66, c0, Vector3(0, -8, 0)]]))
	# l'attente : il se balance, la tête penchée, les bras ballants
	var a0 := {"LeftArm": Vector3(-18, 0, 10), "RightArm": Vector3(-26, 0, -8), "LeftForeArm": Vector3(-12, 0, 0), "RightForeArm": Vector3(-18, 0, 0),
		"Spine02": Vector3(20, 0, 5), "Head": Vector3(24, 14, 28), "neck": Vector3(-4, 0, 0), "LeftUpLeg": Vector3(-8, 0, 2), "LeftLeg": Vector3(12, 0, 0), "RightUpLeg": Vector3(-4, 0, -4), "RightLeg": Vector3(8, 0, 0)}
	var a1 := _m121(a0, {"Spine02": Vector3(18, 0, -4), "Head": Vector3(20, -10, -18), "LeftArm": Vector3(-24, 0, 6), "RightArm": Vector3(-18, 0, -12)})
	z.add_animation("attente", lib._clip(3.4, true, [[0.0, a0, Vector3(1.5, -3, 0)], [1.7, a1, Vector3(-1.5, -3, 0)], [3.4, a0, Vector3(1.5, -3, 0)]]))
	# l'attaque : il lève les bras… et se jette en avant pour agripper
	var t1 := _m121(bras, {"LeftArm": Vector3(-135, 0, 28), "RightArm": Vector3(-140, 0, -26), "LeftForeArm": Vector3(-30, 0, 0), "RightForeArm": Vector3(-30, 0, 0),
		"Spine02": Vector3(-6, 0, 0), "Head": Vector3(-18, 0, 0), "neck": Vector3(-10, 0, 0)})
	var t2 := _m121(bras, {"LeftArm": Vector3(-88, 0, 6), "RightArm": Vector3(-90, 0, -6), "LeftForeArm": Vector3(-8, 0, 0), "RightForeArm": Vector3(-8, 0, 0),
		"Spine02": Vector3(34, 0, 0), "Spine01": Vector3(10, 0, 0), "Head": Vector3(-20, 0, 0), "LeftUpLeg": Vector3(-30, 0, 0), "LeftLeg": Vector3(30, 0, 0), "RightUpLeg": Vector3(15, 0, 0)})
	z.add_animation("attaque", lib._clip(1.0, false, [[0.0, bras, Vector3.ZERO], [0.42, t1, Vector3(0, 2, -6)], [0.6, t2, Vector3(0, -10, 14)], [1.0, bras, Vector3.ZERO]]))
	# touché : il recule le buste
	var h1 := _m121(bras, {"Spine02": Vector3(-16, 18, 0), "Head": Vector3(-26, -20, 0), "LeftArm": Vector3(-40, 0, 40), "RightArm": Vector3(-30, 0, -48)})
	z.add_animation("touche", lib._clip(0.4, false, [[0.0, bras, Vector3.ZERO], [0.12, h1, Vector3(0, -2, -8)], [0.4, bras, Vector3.ZERO]]))
	# il tombe en avant, face contre terre
	var f1 := _m121(bras, {"LeftUpLeg": Vector3(-45, 0, 0), "RightUpLeg": Vector3(-40, 0, 0), "LeftLeg": Vector3(85, 0, 0), "RightLeg": Vector3(80, 0, 0), "Spine02": Vector3(30, 0, 0),
		"LeftArm": Vector3(-40, 0, 30), "RightArm": Vector3(-35, 0, -30)})
	var f2 := {"Hips": Vector3(84, 0, 0), "LeftArm": Vector3(-150, 0, 40), "RightArm": Vector3(-160, 0, -30), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-10, 0, 0),
		"Head": Vector3(-30, 50, 0), "LeftUpLeg": Vector3(-4, 0, 8), "RightUpLeg": Vector3(-2, 0, -10), "RightLeg": Vector3(20, 0, 0)}
	z.add_animation("tombe", lib._clip(1.1, false, [[0.0, bras, Vector3.ZERO], [0.38, f1, Vector3(0, -42, 8)], [1.1, f2, Vector3(0, -84, 40)]]))
	# couché sur le dos, comme mort
	var g0 := {"Hips": Vector3(-88, 0, 0), "LeftArm": Vector3(0, 0, 62), "RightArm": Vector3(-10, 0, -55), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-40, 0, 0),
		"Head": Vector3(10, 45, 0), "LeftUpLeg": Vector3(0, 0, 8), "RightUpLeg": Vector3(-14, 0, -6), "RightLeg": Vector3(26, 0, 0)}
	z.add_animation("gisant", lib._clip(1.0, true, [[0.0, g0, Vector3(0, -84, 0)], [1.0, g0, Vector3(0, -84, 0)]]))
	# il se relève : il s'assied, se met à genoux… et se dresse
	var r1 := {"Hips": Vector3(-35, 0, 0), "Spine02": Vector3(40, 0, 0), "Spine01": Vector3(15, 0, 0), "Head": Vector3(10, 25, 15), "LeftUpLeg": Vector3(-70, 0, 10), "LeftLeg": Vector3(100, 0, 0),
		"RightUpLeg": Vector3(-30, 0, -10), "RightLeg": Vector3(40, 0, 0), "LeftArm": Vector3(10, 0, 45), "RightArm": Vector3(-30, 0, -30)}
	var r2 := {"Spine02": Vector3(38, 0, 0), "Head": Vector3(20, 10, 20), "LeftUpLeg": Vector3(-75, 0, 4), "LeftLeg": Vector3(110, 0, 0), "RightUpLeg": Vector3(-10, 0, -4), "RightLeg": Vector3(100, 0, 0),
		"RightFoot": Vector3(-30, 0, 0), "LeftArm": Vector3(-20, 0, 25), "RightArm": Vector3(-40, 0, -20)}
	z.add_animation("releve", lib._clip(2.2, false, [[0.0, g0, Vector3(0, -84, 0)], [0.8, r1, Vector3(0, -72, -10)], [1.5, r2, Vector3(0, -48, 0)], [2.2, bras, Vector3.ZERO]]))
	lib.free()
	return z


static func _m121(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = b[k]
	return out


func _play121(n: String, blend: float = 0.25, speed: float = 1.0) -> void:
	if _anim121 == null:
		return
	if n == _cur121:
		_anim121.speed_scale = speed
		return
	_cur121 = n
	if _anim121.has_animation(n):
		_anim121.play(n, blend)
		_anim121.speed_scale = speed


# =================================================================== la vie

func _physics_process(delta: float) -> void:
	if not SPECS121.has(kind):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _coup121 > 0.0:
		_coup121 = maxf(0.0, _coup121 - delta * 6.0)
		for m in _skin_mats121:
			(m as ShaderMaterial).set_shader_parameter("coup", _coup121)
	_push_tick(delta)
	if state == "mort":
		_death_tick121(delta)
		return
	if not _active75():
		if state != "gisant":
			_play121("zb/attente")
		return
	var tp: Array = _to_player()
	var dist: float = tp[2]
	var dir_p: Vector3 = tp[1]
	# les grognements (de plus en plus souvent quand il chasse)
	_groan121 -= delta
	if _groan121 <= 0.0 and state != "gisant" and dist < 45.0:
		_groan121 = randf_range(2.2, 5.5) if state in ["chasse", "armer"] else randf_range(5.0, 11.0)
		_sfx71("zombie_cri" if kind == "zombie_coureur" and state == "chasse" and randf() < 0.3 else "zombie_grogne", global_position + Vector3.UP * 1.6, 2.0 if kind == "zombie_lourd" else 0.0)
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"gisant":
			if dist < (6.0 if kind != "zombie_coureur" else 9.0) and float(tp[3]) < 3.0:
				state = "releve"
				timer = 2.2
				_play121("zb/releve", 0.1)
				_sfx71("zombie_grogne", global_position + Vector3.UP * 0.5, 4.0)
				manager.alert(self)
			_move121(Vector3.ZERO, delta, false)
			return
		"releve":
			if timer <= 0.0:
				state = "chasse"
				gisant = false
			_move121(Vector3.ZERO, delta, false)
			return
		"veille":
			if dist < float(spec["vue"]) and float(tp[3]) < 5.0:
				_spot121()
			else:
				# il erre, lentement
				var back: Vector3 = home - global_position
				back.y = 0.0
				if back.length() > 12.0:
					facing = facing.lerp(back.normalized(), 0.03).normalized()
				else:
					facing = facing.rotated(Vector3.UP, sin(_clock * 0.3 + _wobble121) * delta * 0.4).normalized()
				move = facing * float(spec["vitesse"]) * 0.35
		"chasse":
			var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
			if dist > float(spec["vue"]) * 2.2 or from_home > float(spec["laisse"]):
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_hit121 = false
				_play121("zb/attaque", 0.12, 1.0 / maxf(float(spec["armer"]) / 0.6, 0.3))
				_sfx71("zombie_attaque", global_position + Vector3.UP * 1.6)
			else:
				var want: Vector3 = dir_p
				# il titube : la direction ondule un peu
				if kind != "zombie_coureur":
					want = want.rotated(Vector3.UP, sin(_clock * 1.3 + _wobble121) * 0.22)
				# s'il bute contre un mur : il le longe
				if _wall121 > 0.0:
					_wall121 -= delta
					want = want.rotated(Vector3.UP, 1.2 * _side121)
				want += _separation121()
				want.y = 0.0
				if want.length() > 0.01:
					facing = facing.lerp(want.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
				move = facing * float(spec["vitesse"])
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if timer <= 0.0 and not _hit121:
				_hit121 = true
				state = "frappe"
				timer = 0.25
				move = facing * 2.5
				if _hit_player(float(spec["portee"]) + 0.5, 0.3, int(spec["degats"]), 2.0 if kind == "zombie_lourd" else 0.8):
					_on_grab121()
		"frappe":
			move = facing * 1.2
			if timer <= 0.0:
				state = "repos"
				timer = float(spec["repos"])
		"repos":
			facing = facing.lerp(dir_p, clampf(delta * 2.0, 0.0, 1.0)).normalized()
			move = -facing * 0.3
			if timer <= 0.0:
				state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
	_move121(move, delta)


func _spot121() -> void:
	state = "chasse"
	manager.alert(self)
	if not _seen121:
		_seen121 = true
		_sfx71("zombie_cri" if kind == "zombie_coureur" else "zombie_grogne", global_position + Vector3.UP * 1.6, 3.0)


## Les zombies ne se marchent pas dessus
func _separation121() -> Vector3:
	var push := Vector3.ZERO
	for m in get_tree().get_nodes_in_group("monstres_v36"):
		if m == self or not (m is Node3D) or not is_instance_valid(m):
			continue
		var d: Vector3 = global_position - (m as Node3D).global_position
		d.y = 0.0
		var l: float = d.length()
		if l > 0.01 and l < 1.2:
			push += d / l * (1.2 - l) * 1.5
	return push


## Il t'a agrippé : le cœur s'emballe (et en réalité virtuelle, les manettes tremblent)
func _on_grab121() -> void:
	var mn: Node = _m71()
	var sv: Node = mn.get("sombreval_v121") if mn != null else null
	if sv != null and sv.has_method("haptique"):
		sv.haptique(0.9, 0.35)
	_sfx71("zombie_attaque", global_position + Vector3.UP * 1.6, 3.0)


func _move121(move: Vector3, delta: float, turn: bool = true) -> void:
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 10.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -24.0)
	move_and_slide()
	if is_on_wall() and state == "chasse" and _wall121 <= 0.0:
		_wall121 = 0.8
		_side121 = -_side121 if randf() < 0.3 else _side121
	if turn:
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.z), clampf(delta * 6.0, 0.0, 1.0))
	var sp: float = Vector2(velocity.x, velocity.z).length()
	match state:
		"chasse", "veille":
			if sp < 0.15:
				_play121("zb/attente")
			elif kind == "zombie_coureur" and sp > 2.0:
				_play121("zb/course", 0.2, clampf(sp / 4.6, 0.6, 1.4))
			else:
				_play121("zb/marche", 0.3, clampf(sp / 0.72, 0.4, 2.2))
		"repos":
			_play121("zb/attente", 0.3)


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS121.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	if kind == "zombie_lourd":
		damage = maxi(1, int(round(damage * 0.8)))
	hp -= damage
	_coup121 = 0.5
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * 1.9
		if cb.get("critical") == true:
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
	_impact121(global_position + Vector3.UP * 1.3 - away * 0.2, away)
	_sfx71("touche_chair", global_position + Vector3.UP * 1.2, -2.0)
	if hp <= 0:
		_die63()
		return
	if state in ["gisant", "releve"]:
		state = "releve" if state == "gisant" else state
		if _cur121 != "zb/releve":
			_play121("zb/releve", 0.1)
			timer = 2.2
		return
	if kind != "zombie_lourd":
		_knock = away * 2.2
		state = "recul"
		timer = 0.35
		_cur121 = ""
		_play121("zb/touche", 0.05)
	elif state == "veille":
		_spot121()
	if state == "veille":
		_spot121()


## Un coup : de la poussière grise (Tout public) ou des gouttes de sang (Public averti)
func _impact121(at: Vector3, dir: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 26 if Public121.averti() else 18
	p.lifetime = 0.9
	p.explosiveness = 0.95
	p.direction = dir + Vector3.UP * 0.4
	p.spread = 35.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -9.0, 0) if Public121.averti() else Vector3(0, 0.4, 0)
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.09
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	if Public121.averti():
		mat.albedo_color = Color(0.35, 0.02, 0.02)
		mat.roughness = 0.3
	else:
		mat.albedo_color = Color(0.55, 0.53, 0.5, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 1.0
		p.scale_amount_min = 0.08
		p.scale_amount_max = 0.18
	p.material_override = mat
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func _die63() -> void:
	if not SPECS121.has(kind):
		super._die63()
		return
	_sfx71("zombie_mort", global_position + Vector3.UP * 1.4)
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	_cur121 = ""
	_play121("zb/tombe", 0.1)
	died.emit(self)


## Vaincu : en poussière (Tout public), ou à terre dans une flaque (Public averti)
func _death_tick121(delta: float) -> void:
	timer += delta
	velocity = Vector3.ZERO
	if Public121.averti():
		if timer > 1.0 and _pool121 == null:
			_pool121 = MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.6
			cm.bottom_radius = 0.6
			cm.height = 0.02
			_pool121.mesh = cm
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.22, 0.01, 0.01)
			pm.roughness = 0.12
			pm.metallic_specular = 0.8
			_pool121.material_override = pm
			add_child(_pool121)
			_pool121.position = Vector3(0, 0.03, 0.6)
			_pool121.scale = Vector3(0.1, 1.0, 0.1)
		if _pool121 != null:
			var k: float = clampf((timer - 1.0) / 3.0, 0.1, 1.0)
			_pool121.scale = Vector3(k * 1.3, 1.0, k)
		if timer > 12.0:
			_visual.position.y -= delta * 0.4
		if timer > 15.0:
			queue_free()
		return
	# Tout public : il s'effondre et part en poussière, dans un peu de lumière
	if timer > 0.55 and not _dust121:
		_dust121 = true
		_poussiere121()
	if timer > 0.55:
		var k2: float = clampf(1.0 - (timer - 0.55) / 0.5, 0.01, 1.0)
		_visual.scale = Vector3(1.0, k2, 1.0)
		for m in _skin_mats121:
			(m as ShaderMaterial).set_shader_parameter("coup", (1.0 - k2) * 1.5)
	if timer > 1.1:
		visible = false
	if timer > 3.0:
		queue_free()


func _poussiere121() -> void:
	var at: Vector3 = global_position + Vector3.UP * 0.9
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 70
	p.lifetime = 2.2
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.3, 0.8, 0.3)
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 1.4
	p.gravity = Vector3(0, 0.25, 0)
	p.damping_min = 0.6
	p.damping_max = 1.2
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.2
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	p.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.82, 0.78, 0.45)
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 0.95, 0.9))
	g.set_color(1, Color(0.6, 0.62, 0.6, 0.0))
	p.color_ramp = g
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(0.85, 0.92, 1.0)
	l.light_energy = 2.5
	l.omni_range = 4.0
	l.shadow_enabled = false
	get_parent().add_child(l)
	l.global_position = at
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, 1.2)
	tw.tween_callback(l.queue_free)
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)


func _animate63(delta: float, speed: float) -> void:
	if not SPECS121.has(kind):
		super._animate63(delta, speed)


func _animate75(delta: float, speed: float) -> void:
	if not SPECS121.has(kind):
		super._animate75(delta, speed)


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS121.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"zombie":
			if rng.randf() < 0.35:
				g.append(["piece", rng.randi_range(1, 3)])
		"zombie_coureur":
			g.append(["piece", rng.randi_range(1, 4)])
		"zombie_lourd":
			g.append(["piece", rng.randi_range(6, 12)])
			if rng.randf() < 0.3:
				g.append(["piece_or", 1])
	for e in get_meta("butin_extra", []):
		g.append(e)
	return g


func alert_text() -> String:
	match kind:
		"zombie":
			return "Des morts-vivants ! Ils sont lents… mais ils ne s'arrêtent jamais. Quand l'un lève les bras, il va t'agripper : recule, ou frappe-le avant. Et écoute bien : quand ça grogne dans ton dos… retourne-toi."
		"zombie_coureur":
			return "Un mort-vivant enragé ! Celui-là hurle quand il te voit… et il COURT. Ne lui tourne pas le dos : fais-lui face, et frappe quand il se jette sur toi."
		"zombie_lourd":
			return "Un colosse mort-vivant ! Énorme et lent, il frappe très fort et encaisse beaucoup. Garde tes distances, et frappe juste après son coup."
	return super.alert_text()

extends "res://scripts/monstre_v121.gd"
## V124 : les vampires du château du comte, à Sombreval. Les « enfants » du comte Dracula : de vrais
## corps (corps_v64), la peau blanche comme de la cire, les lèvres sombres, les yeux rouges qui
## luisent dans le noir ; des habits de bal d'un autre siècle (redingotes noires, gilets bordeaux,
## longues robes, capes doublées de rouge).
##  - le vampire (« vampire ») : il glisse sans bruit, plus vite que tu ne cours ; quand il est
##    loin, il se dissout dans une brume pleine de chauves-souris… et réapparaît à côté de toi,
##    souvent dans ton dos. Il siffle avant de frapper : c'est le moment de parer ou de reculer ;
##  - le garde vampire (« vampire_garde ») : un soldat du comte, une cuirasse noire, une épée ; lent
##    et dur à abattre ;
##  - les trois enfants du comte, qui parlent avant de se battre : la comtesse Ilona (« ilona »),
##    le baron Sigismund (« sigismund ») et le chevalier Radu (« radu », invulnérable dans l'ombre :
##    il faut allumer les braseros de la salle d'armes) ;
##  - Mortimer, le vieux majordome (« mortimer ») : il ne se bat pas ; il parle.
## L'état « parle » : immobile, il te regarde ; on ne peut pas le frapper (le donjon le réveille).
## Vaincus : en « Tout public », ils partent en poussière dans un peu de lumière ; en « Public
## averti », en cendres et en braises (les coups font couler un peu de sang). Toujours, une nuée
## de chauves-souris s'échappe de leur cape.

const SPECS124 := {
	"vampire": {"pv": 22, "vitesse": 3.1, "degats": 1, "portee": 1.8, "armer": 0.5, "repos": 1.0, "vue": 22.0, "laisse": 60.0,
		"rayon": 0.42, "haut": 0.95, "nom": "Vampire", "brume": 9.0},
	"vampire_garde": {"pv": 42, "vitesse": 2.0, "degats": 2, "portee": 2.2, "armer": 0.75, "repos": 1.4, "vue": 18.0, "laisse": 50.0,
		"rayon": 0.5, "haut": 1.0, "nom": "Garde vampire", "chef": true},
	"ilona": {"pv": 80, "vitesse": 3.6, "degats": 1, "portee": 1.9, "armer": 0.45, "repos": 0.9, "vue": 40.0, "laisse": 200.0,
		"rayon": 0.42, "haut": 0.95, "nom": "Comtesse Ilona", "brume": 6.0, "boss": true},
	"sigismund": {"pv": 70, "vitesse": 2.8, "degats": 1, "portee": 1.9, "armer": 0.5, "repos": 1.0, "vue": 40.0, "laisse": 200.0,
		"rayon": 0.42, "haut": 0.95, "nom": "Baron Sigismund", "brume": 7.0, "boss": true},
	"radu": {"pv": 110, "vitesse": 2.6, "degats": 2, "portee": 2.4, "armer": 0.7, "repos": 1.1, "vue": 40.0, "laisse": 200.0,
		"rayon": 0.5, "haut": 1.05, "nom": "Chevalier Radu", "boss": true},
	"mortimer": {"pv": 999, "vitesse": 0.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 0.0, "laisse": 0.0,
		"rayon": 0.42, "haut": 0.95, "nom": "Mortimer", "pacifique": true},
}
const SOUNDS124 := {"vampire": ["vampire_siffle", "vampire_mort"], "vampire_garde": ["vampire_siffle", "vampire_mort"],
	"ilona": ["vampire_siffle", "vampire_mort"], "sigismund": ["vampire_siffle", "vampire_mort"], "radu": ["vampire_siffle", "vampire_mort"],
	"mortimer": ["vampire_rire", "vampire_mort"]}
## Les corps (des visages qu'on ne croise pas ailleurs) : [id, femme]
const CORPS_V := [["f81_arcanelle_0", false], ["f81_azur_0", false], ["f81_neo_6", false], ["f81_cliquetis_0", false],
	["f81_montjoie_7", true], ["f81_cliquetis_1", true], ["f81_neo_9", true], ["f81_tazira_7", true], ["f81_carene_1", true]]
const CORPS_GARDE := ["f81_tazira_0", "f81_pirate_0", "f81_boucan_6", "f81_pasta_0"]
const NOMMES := {"ilona": "f81_montjoie_7", "sigismund": "f81_tazira_2", "radu": "f81_montjoie_0", "mortimer": "f81_boucan_2"}

static var _vlib: AnimationLibrary = null

var _brume124: float = 4.0
var _hiss124: float = 2.0
var _vanish124: Vector3 = Vector3.ZERO
var _float124: float = 0.0
var _femme124: bool = false
var _parle124: bool = false                 # il est en train de parler (le geste)
var _ash124: bool = false
var invuln: bool = false                    # Radu, dans l'ombre : les coups ne le touchent pas
var _clang124: float = 0.0
var on_invuln_hit: Callable = Callable()    # le donjon dit pourquoi (une seule fois)
var on_hit: Callable = Callable()           # l'état « danse » : le donjon décide (le bal de la comtesse)
var dance_anim: String = "vp/valse"         # l'état « danse » : ce qu'il joue (le donjon le déplace)


# =================================================================== aiguillage

func _v63() -> bool:
	return SPECS124.has(kind) or super._v63()


func _sound_pair() -> Array:
	return SOUNDS124.get(kind, super._sound_pair())


func is_boss() -> bool:
	if SPECS124.has(kind):
		return bool(spec.get("boss", false))
	return super.is_boss()


func is_chef() -> bool:
	if SPECS124.has(kind):
		return bool(spec.get("chef", false))
	return super.is_chef()


func is_hittable() -> bool:
	if SPECS124.has(kind):
		return state != "mort" and state != "parle" and state != "brume" and not bool(spec.get("pacifique", false))
	return super.is_hittable()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS124.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = (SPECS124[k] as Dictionary).duplicate()
	_base_speed = float(spec["vitesse"]) * randf_range(0.94, 1.06)
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
	c.radius = 0.34 if k not in ["vampire_garde", "radu"] else 0.42
	c.height = 1.8
	cs.shape = c
	cs.position.y = c.height * 0.5
	add_child(cs)
	_cs71 = cs
	_visual = Node3D.new()
	add_child(_visual)
	_build_body124()
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(0, 0, 1)
	rotation.y = 0.0
	_say_next = 1e9
	_side121 = 1.0 if randf() < 0.5 else -1.0
	_wobble121 = randf() * TAU
	_brume124 = randf_range(3.0, 6.0)
	if bool(spec.get("pacifique", false)):
		state = "parle"


## Face au joueur, immobile : il parle (on ne peut pas le frapper). Le donjon le réveillera.
func talk() -> void:
	state = "parle"
	velocity = Vector3.ZERO


func wake() -> void:
	if state in ["parle", "veille", "danse"]:
		state = "chasse"
		_hiss124 = 0.0
		_sfx71("vampire_siffle", global_position + Vector3.UP * 1.6, 2.0)


func set_speaking(on: bool) -> void:
	_parle124 = on


## Il n'a pas de reflet (la comtesse, au bal) : ses maillages passent sur une couche que la caméra
## du miroir ne voit pas
func sans_reflet(layer: int) -> void:
	if _visual == null:
		return
	for vi in _visual.find_children("*", "VisualInstance3D", true, false):
		(vi as VisualInstance3D).layers = layer


# =================================================================== le corps

func _build_body124() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	_model121 = packed.instantiate()
	_visual.add_child(_model121)
	_anim121 = _model121.find_child("AnimationPlayer", true, false)
	var found := _model121.find_children("*", "Skeleton3D", true, false)
	_skel121 = found[0] if found.size() > 0 else null
	if _skel121 == null or _anim121 == null:
		return
	if _vlib == null:
		_vlib = _make_vlib(_model121, _anim121, _skel121)
	if not _anim121.has_animation_library("vp"):
		_anim121.add_animation_library("vp", _vlib)
	var ids: Array = []
	if NOMMES.has(kind):
		ids = [NOMMES[kind]]
	elif kind == "vampire_garde":
		ids = CORPS_GARDE.duplicate()
		ids.shuffle()
	else:
		var pool: Array = CORPS_V.duplicate()
		pool.shuffle()
		for e in pool:
			ids.append(e[0])
	var built: bool = false
	for id in ids:
		if Corps121.has_body(str(id)):
			_femme124 = _is_femme(str(id))
			built = _dress121(str(id))
			if built:
				break
	if not built:
		for mi in _model121.find_children("*", "MeshInstance3D", true, false):
			var mm: MeshInstance3D = mi
			for s in range(mm.mesh.get_surface_count()):
				var sm := StandardMaterial3D.new()
				sm.albedo_color = Color(0.08, 0.06, 0.07)
				sm.roughness = 0.8
				mm.set_surface_override_material(s, sm)
	if kind in ["vampire_garde", "radu"]:
		_model121.scale *= 1.06
		_armure124()
	if kind == "mortimer":
		_chandelier124()
	_play121("vp/attente", 0.0)
	_anim121.seek(randf() * 2.0, true)


static func _is_femme(id: String) -> bool:
	if id == NOMMES["ilona"]:
		return true
	for e in CORPS_V:
		if str(e[0]) == id:
			return bool(e[1])
	return false


## Les habits : on garde le cache des corps de monstre_v121 (une tenue par corps : les vampires ont
## leurs propres corps, jamais ceux des morts-vivants)
func _tenue121(id: String) -> Array:
	if not SPECS124.has(kind):
		return super._tenue121(id)
	var noir := [0.035, 0.03, 0.035]
	var rouge := [0.36, 0.02, 0.05]
	var blanc := [0.8, 0.78, 0.72]
	match kind:
		"mortimer":
			return [{"v": "chemise_longue", "c": blanc, "c2": blanc, "tissu": "coton"}, {"v": "gilet", "c": [0.06, 0.05, 0.05], "c2": noir},
				{"v": "veste", "c": noir, "c2": noir, "tissu": "laine"}, {"v": "pantalon", "c": noir, "c2": noir, "tissu": "laine"},
				{"v": "chaussures", "c": [0.02, 0.02, 0.02]}, {"v": "col", "c": blanc}]
		"ilona":
			return [{"v": "corsage_long", "c": [0.42, 0.02, 0.06], "c2": noir, "tissu": "soie"}, {"v": "jupe_longue", "c": [0.1, 0.01, 0.025], "c2": rouge, "tissu": "soie"},
				{"v": "cape", "c": noir, "c2": rouge}, {"v": "col", "c": noir}, {"v": "chaussures", "c": noir}]
		"sigismund":
			return [{"v": "chemise_longue", "c": blanc, "c2": blanc, "tissu": "coton"}, {"v": "gilet", "c": [0.05, 0.12, 0.08], "c2": [0.6, 0.45, 0.15]},
				{"v": "veste", "c": [0.1, 0.07, 0.05], "c2": noir, "tissu": "laine"}, {"v": "pantalon", "c": noir, "c2": noir, "tissu": "laine"},
				{"v": "chaussures", "c": [0.05, 0.03, 0.02]}, {"v": "echarpe", "c": [0.3, 0.02, 0.04]}]
		"radu", "vampire_garde":
			return [{"v": "tunique_haut", "c": [0.1, 0.1, 0.11], "c2": noir, "tissu": "laine"}, {"v": "pantalon", "c": noir, "c2": noir, "tissu": "cuir"},
				{"v": "bottes_hautes", "c": [0.04, 0.03, 0.03]}, {"v": "ceinture", "c": [0.08, 0.05, 0.03]},
				{"v": "cape", "c": [0.22, 0.015, 0.03] if kind == "radu" else noir, "c2": rouge}]
	var r := RandomNumberGenerator.new()
	r.seed = hash(id) + 124
	if _is_femme(id):
		var robe: Array = [[0.3, 0.02, 0.05], [0.05, 0.04, 0.06], [0.16, 0.03, 0.14], [0.04, 0.05, 0.12]][r.randi() % 4]
		return [{"v": "corsage_long", "c": robe, "c2": noir, "tissu": "soie"}, {"v": "jupe_longue", "c": robe, "c2": noir, "tissu": "soie"},
			{"v": "cape", "c": noir, "c2": rouge}, {"v": "chaussures", "c": noir}]
	var gil: Array = [[0.32, 0.03, 0.05], [0.08, 0.02, 0.03], [0.12, 0.1, 0.08], [0.25, 0.2, 0.08]][r.randi() % 4]
	return [{"v": "chemise_longue", "c": blanc, "c2": blanc, "tissu": "coton"}, {"v": "gilet", "c": gil, "c2": [0.55, 0.42, 0.15]},
		{"v": "veste", "c": noir, "c2": noir, "tissu": "laine"}, {"v": "pantalon", "c": noir, "c2": noir, "tissu": "laine"},
		{"v": "bottes_hautes", "c": [0.03, 0.025, 0.025]}, {"v": "cape", "c": noir, "c2": rouge}]


## Les matières d'un corps de vampire : la peau de cire, les lèvres sombres, les yeux rouges
func _zombify_parts(parts: Dictionary) -> void:
	if not SPECS124.has(kind):
		super._zombify_parts(parts)
		return
	for k in ["peau", "visage"]:
		var mi: MeshInstance3D = parts.get(k)
		if mi != null and mi.material_override is ShaderMaterial:
			var sm: ShaderMaterial = mi.material_override
			sm.set_shader_parameter("peau", Color(0.84, 0.82, 0.84))
			sm.set_shader_parameter("rose", 0.0)
			sm.set_shader_parameter("mort_vivant", 0.12)
			sm.set_shader_parameter("diffusion", 0.55)
			sm.set_shader_parameter("levres", Color(0.3, 0.03, 0.06))
			sm.set_shader_parameter("levres_force", 0.95)
			sm.set_shader_parameter("fard", Color(0.18, 0.08, 0.14))
			sm.set_shader_parameter("fard_force", 0.35)
			sm.set_shader_parameter("age", 0.25 if kind != "mortimer" else 0.9)
	var ey: MeshInstance3D = parts.get("yeux")
	if ey != null and ey.material_override is ShaderMaterial:
		var em: ShaderMaterial = ey.material_override
		em.set_shader_parameter("iris", Color(0.85, 0.04, 0.03))
		em.set_shader_parameter("iris_lueur", 0.9 if kind != "mortimer" else 0.45)
	for k2 in ["cheveux", "barbe"]:
		var mh: MeshInstance3D = parts.get(k2)
		if mh != null and mh.material_override is ShaderMaterial:
			var hm: ShaderMaterial = (mh.material_override as ShaderMaterial)
			for pn in ["couleur", "cheveux", "teinte"]:
				var hv: Variant = hm.get_shader_parameter(pn)
				if hv is Color:
					var tgt: Color = Color(0.04, 0.035, 0.04) if kind != "mortimer" else Color(0.72, 0.72, 0.72)
					hm.set_shader_parameter(pn, (hv as Color).lerp(tgt, 0.75))


## Pas de taches de sang sur la peau des vampires (celles des morts-vivants, en Public averti)
func _shared_skin121() -> void:
	if not SPECS124.has(kind):
		super._shared_skin121()
		return
	for m in _skin_mats121:
		(m as ShaderMaterial).set_shader_parameter("sang", 0.0)


## Le chevalier et les gardes : une cuirasse d'acier noir, des épaulières, une épée
func _armure124() -> void:
	if _skel121 == null:
		return
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.1, 0.1, 0.11)
	steel.metallic = 0.85
	steel.roughness = 0.36
	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color(0.5, 0.42, 0.25)
	edge.metallic = 0.9
	edge.roughness = 0.35
	var chest := BoneAttachment3D.new()
	chest.bone_name = "Spine02"
	_skel121.add_child(chest)
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.2
	pm.bottom_radius = 0.17
	pm.height = 0.36
	pm.radial_segments = 14
	plate.mesh = pm
	plate.material_override = steel
	plate.scale = Vector3(1.05, 1.0, 0.78)
	plate.position = Vector3(0, 0.02, 0.015)
	chest.add_child(plate)
	var trim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.2
	trim.mesh = tm
	trim.material_override = edge
	trim.scale = Vector3(1.05, 0.5, 0.78)
	trim.position = Vector3(0, 0.2, 0.015)
	chest.add_child(trim)
	for side in [["LeftShoulder", 1.0], ["RightShoulder", -1.0]]:
		var sh := BoneAttachment3D.new()
		sh.bone_name = str(side[0])
		_skel121.add_child(sh)
		var pau := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.12
		sp.height = 0.14
		sp.is_hemisphere = true
		pau.mesh = sp
		pau.material_override = steel
		pau.position = Vector3(0, 0.12, 0)
		pau.scale = Vector3(1.0, 1.0, 1.15)
		sh.add_child(pau)
	var hand := BoneAttachment3D.new()
	hand.bone_name = "RightHand"
	_skel121.add_child(hand)
	var sword := Node3D.new()
	sword.position = Vector3(0, 0.08, 0.02)
	sword.rotation_degrees = Vector3(0, 0, 0)
	hand.add_child(sword)
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.95, 0.012)
	blade.mesh = bm
	var bl := StandardMaterial3D.new()
	bl.albedo_color = Color(0.62, 0.63, 0.66)
	bl.metallic = 0.95
	bl.roughness = 0.18
	blade.material_override = bl
	blade.position = Vector3(0, 0.6, 0)
	sword.add_child(blade)
	var guard := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.24, 0.035, 0.04)
	guard.mesh = gm
	guard.material_override = edge
	guard.position = Vector3(0, 0.12, 0)
	sword.add_child(guard)
	var grip := MeshInstance3D.new()
	var gr := CylinderMesh.new()
	gr.top_radius = 0.018
	gr.bottom_radius = 0.018
	gr.height = 0.18
	grip.mesh = gr
	grip.material_override = steel
	grip.position = Vector3(0, 0.02, 0)
	sword.add_child(grip)


## Mortimer tient un chandelier : trois bougies, une petite lumière qui tremble
func _chandelier124() -> void:
	if _skel121 == null:
		return
	var hand := BoneAttachment3D.new()
	hand.bone_name = "LeftHand"
	_skel121.add_child(hand)
	var h := Node3D.new()
	h.name = "Chandelier"
	h.position = Vector3(0, 0.07, 0.03)
	hand.add_child(h)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.62, 0.45, 0.2)
	brass.metallic = 0.9
	brass.roughness = 0.35
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.86, 0.82, 0.72)
	wax.roughness = 0.5
	var flame := StandardMaterial3D.new()
	flame.albedo_color = Color(1.0, 0.75, 0.35)
	flame.emission_enabled = true
	flame.emission = Color(1.0, 0.65, 0.25)
	flame.emission_energy_multiplier = 4.0
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.012
	sm.bottom_radius = 0.03
	sm.height = 0.22
	stem.mesh = sm
	stem.material_override = brass
	stem.position = Vector3(0, 0.08, 0)
	h.add_child(stem)
	for dx in [-0.09, 0.0, 0.09]:
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.1 if dx != 0.0 else 0.02, 0.012, 0.012)
		arm.mesh = am
		arm.material_override = brass
		arm.position = Vector3(dx * 0.5, 0.19, 0)
		h.add_child(arm)
		var cdl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.011
		cm.bottom_radius = 0.012
		cm.height = 0.11
		cdl.mesh = cm
		cdl.material_override = wax
		cdl.position = Vector3(dx, 0.255 + (0.03 if dx == 0.0 else 0.0), 0)
		h.add_child(cdl)
		var fl := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 0.008
		fm.height = 0.028
		fl.mesh = fm
		fl.material_override = flame
		fl.position = cdl.position + Vector3(0, 0.07, 0)
		h.add_child(fl)
	var l := OmniLight3D.new()
	l.name = "Lueur"
	l.light_color = Color(1.0, 0.7, 0.4)
	l.light_energy = 1.3
	l.omni_range = 5.5
	l.shadow_enabled = false
	l.position = Vector3(0, 0.36, 0)
	h.add_child(l)


## Les mouvements des vampires (sur le squelette du héros) : l'attente altière, la marche lente,
## la glissade (penché en avant, la cape en arrière), les griffes levées, le geste de celui qui
## parle, la valse, la mort (cambré, les bras ouverts)
static func _make_vlib(model: Node3D, anim: AnimationPlayer, skel: Skeleton3D) -> AnimationLibrary:
	var lib = HeroLib121.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var z := AnimationLibrary.new()
	var a0 := {"Spine02": Vector3(-5, 0, 0), "Spine01": Vector3(-2, 0, 0), "neck": Vector3(-4, 0, 0), "Head": Vector3(-6, 0, 0),
		"LeftArm": Vector3(4, 0, 7), "RightArm": Vector3(4, 0, -7), "LeftForeArm": Vector3(-16, 0, 0), "RightForeArm": Vector3(-16, 0, 0),
		"LeftUpLeg": Vector3(0, 0, 3), "RightUpLeg": Vector3(0, 0, -3)}
	var a1 := _m121(a0, {"Head": Vector3(-4, 14, 2), "Spine02": Vector3(-4, 5, 0), "RightForeArm": Vector3(-22, 0, 0)})
	var a2 := _m121(a0, {"Head": Vector3(-7, -12, -2), "Spine02": Vector3(-5, -4, 0), "LeftForeArm": Vector3(-22, 0, 0)})
	z.add_animation("attente", lib._clip(6.0, true, [[0.0, a0, Vector3.ZERO], [2.0, a1, Vector3(0, 0, 0)], [4.0, a2, Vector3(0, 0, 0)], [6.0, a0, Vector3.ZERO]]))
	# la marche : lente, droite, élégante
	var w0 := _m121(a0, {"LeftUpLeg": Vector3(-22, 0, 2), "LeftLeg": Vector3(8, 0, 0), "RightUpLeg": Vector3(16, 0, -2), "RightLeg": Vector3(12, 0, 0),
		"LeftArm": Vector3(10, 0, 7), "RightArm": Vector3(-10, 0, -7)})
	var w1 := _m121(a0, {"LeftUpLeg": Vector3(-4, 0, 2), "LeftLeg": Vector3(4, 0, 0), "RightUpLeg": Vector3(-6, 0, -2), "RightLeg": Vector3(40, 0, 0)})
	var w2 := _m121(a0, {"RightUpLeg": Vector3(-22, 0, -2), "RightLeg": Vector3(8, 0, 0), "LeftUpLeg": Vector3(16, 0, 2), "LeftLeg": Vector3(12, 0, 0),
		"RightArm": Vector3(10, 0, -7), "LeftArm": Vector3(-10, 0, 7)})
	var w3 := _m121(a0, {"RightUpLeg": Vector3(-4, 0, -2), "RightLeg": Vector3(4, 0, 0), "LeftUpLeg": Vector3(-6, 0, 2), "LeftLeg": Vector3(40, 0, 0)})
	z.add_animation("marche", lib._clip(1.3, true, [[0.0, w0, Vector3(0, -2, 0)], [0.325, w1, Vector3(0, 0, 0)], [0.65, w2, Vector3(0, -2, 0)],
		[0.975, w3, Vector3(0, 0, 0)], [1.3, w0, Vector3(0, -2, 0)]]))
	# la glissade : il ne marche plus, il flotte vers toi
	var g0 := {"Spine02": Vector3(16, 0, 0), "Spine01": Vector3(6, 0, 0), "neck": Vector3(-8, 0, 0), "Head": Vector3(-20, 0, 0),
		"LeftArm": Vector3(32, 0, 30), "RightArm": Vector3(32, 0, -30), "LeftForeArm": Vector3(-12, 0, 0), "RightForeArm": Vector3(-12, 0, 0),
		"LeftUpLeg": Vector3(8, 0, 2), "LeftLeg": Vector3(22, 0, 0), "RightUpLeg": Vector3(12, 0, -2), "RightLeg": Vector3(30, 0, 0),
		"LeftFoot": Vector3(30, 0, 0), "RightFoot": Vector3(34, 0, 0)}
	var g1 := _m121(g0, {"LeftArm": Vector3(38, 0, 36), "RightArm": Vector3(38, 0, -36), "Spine02": Vector3(18, 0, 0)})
	z.add_animation("glisse", lib._clip(1.2, true, [[0.0, g0, Vector3(0, -3, 0)], [0.6, g1, Vector3(0, -1, 0)], [1.2, g0, Vector3(0, -3, 0)]]))
	# l'attaque : les griffes levées (il siffle)… et il fond sur toi
	var t1 := _m121(a0, {"LeftArm": Vector3(-150, 0, 42), "RightArm": Vector3(-150, 0, -42), "LeftForeArm": Vector3(-38, 0, 0), "RightForeArm": Vector3(-38, 0, 0),
		"Spine02": Vector3(-12, 0, 0), "Head": Vector3(-22, 0, 0), "LeftUpLeg": Vector3(8, 0, 4), "RightUpLeg": Vector3(-6, 0, -4)})
	var t2 := _m121(a0, {"LeftArm": Vector3(-58, 0, -12), "RightArm": Vector3(-58, 0, 12), "LeftForeArm": Vector3(-8, 0, 0), "RightForeArm": Vector3(-8, 0, 0),
		"Spine02": Vector3(32, 0, 0), "Spine01": Vector3(8, 0, 0), "Head": Vector3(-12, 0, 0), "LeftUpLeg": Vector3(-38, 0, 0), "LeftLeg": Vector3(32, 0, 0),
		"RightUpLeg": Vector3(16, 0, 0), "RightLeg": Vector3(10, 0, 0)})
	z.add_animation("attaque", lib._clip(1.0, false, [[0.0, a0, Vector3.ZERO], [0.42, t1, Vector3(0, 3, -6)], [0.6, t2, Vector3(0, -8, 16)], [1.0, a0, Vector3.ZERO]]))
	# l'épée (Radu, les gardes) : levée au-dessus de l'épaule, puis le grand revers
	var s1 := _m121(a0, {"RightArm": Vector3(-160, 0, -30), "RightForeArm": Vector3(-50, 0, 0), "LeftArm": Vector3(-30, 0, 20), "Spine02": Vector3(-6, 24, 0),
		"Head": Vector3(-8, -14, 0), "LeftUpLeg": Vector3(-14, 0, 6), "RightUpLeg": Vector3(10, 0, -6)})
	var s2 := _m121(a0, {"RightArm": Vector3(-55, 0, 25), "RightForeArm": Vector3(-6, 0, 0), "LeftArm": Vector3(10, 0, 30), "Spine02": Vector3(26, -26, 0),
		"Head": Vector3(-10, 10, 0), "LeftUpLeg": Vector3(-34, 0, 0), "LeftLeg": Vector3(30, 0, 0), "RightUpLeg": Vector3(14, 0, 0)})
	z.add_animation("epee", lib._clip(1.1, false, [[0.0, a0, Vector3.ZERO], [0.5, s1, Vector3(0, 0, -4)], [0.7, s2, Vector3(0, -8, 14)], [1.1, a0, Vector3.ZERO]]))
	# touché : il recule le buste, les bras écartés
	var h1 := _m121(a0, {"Spine02": Vector3(-18, 14, 0), "Head": Vector3(-26, -18, 0), "LeftArm": Vector3(-30, 0, 38), "RightArm": Vector3(-26, 0, -42)})
	z.add_animation("touche", lib._clip(0.4, false, [[0.0, a0, Vector3.ZERO], [0.12, h1, Vector3(0, -2, -8)], [0.4, a0, Vector3.ZERO]]))
	# la mort : cambré, la tête rejetée en arrière, les bras grands ouverts… il se soulève un peu
	var d1 := _m121(a0, {"Spine02": Vector3(-30, 0, 0), "Spine01": Vector3(-12, 0, 0), "neck": Vector3(-14, 0, 0), "Head": Vector3(-40, 0, 0),
		"LeftArm": Vector3(-105, 0, 72), "RightArm": Vector3(-105, 0, -72), "LeftForeArm": Vector3(-10, 0, 0), "RightForeArm": Vector3(-10, 0, 0),
		"LeftUpLeg": Vector3(-6, 0, 4), "LeftLeg": Vector3(26, 0, 0), "RightUpLeg": Vector3(-4, 0, -4), "RightLeg": Vector3(30, 0, 0),
		"LeftFoot": Vector3(40, 0, 0), "RightFoot": Vector3(42, 0, 0)})
	z.add_animation("mort", lib._clip(1.4, false, [[0.0, a0, Vector3.ZERO], [0.35, d1, Vector3(0, 4, -4)], [1.4, _m121(d1, {"Head": Vector3(-46, 0, 0)}), Vector3(0, 10, -4)]]))
	# il parle : la main droite qui accompagne les mots, la tête qui penche
	var p0 := _m121(a0, {"RightArm": Vector3(-34, 0, -12), "RightForeArm": Vector3(-62, 0, 0), "Head": Vector3(-5, 6, 4)})
	var p1 := _m121(a0, {"RightArm": Vector3(-46, 0, -28), "RightForeArm": Vector3(-38, 0, 0), "Head": Vector3(-3, -6, -3), "Spine02": Vector3(-3, -4, 0)})
	var p2 := _m121(a0, {"RightArm": Vector3(-24, 0, -8), "RightForeArm": Vector3(-70, 0, 0), "LeftForeArm": Vector3(-30, 0, 0), "Head": Vector3(-8, 2, 0)})
	z.add_animation("parle", lib._clip(3.6, true, [[0.0, p0, Vector3.ZERO], [1.2, p1, Vector3.ZERO], [2.4, p2, Vector3.ZERO], [3.6, p0, Vector3.ZERO]]))
	# la valse (les danseurs du bal) : la main levée, l'autre à la taille du cavalier, trois temps
	var v0 := _m121(a0, {"LeftArm": Vector3(-72, 0, 48), "LeftForeArm": Vector3(-62, 0, 0), "RightArm": Vector3(-46, 0, -18), "RightForeArm": Vector3(-64, 0, 0),
		"Spine02": Vector3(-6, 0, 0), "Head": Vector3(-10, 24, 0)})
	var v1 := _m121(v0, {"LeftUpLeg": Vector3(-20, 0, 6), "LeftLeg": Vector3(14, 0, 0), "RightUpLeg": Vector3(8, 0, -4), "Spine02": Vector3(-6, 6, 2)})
	var v2 := _m121(v0, {"RightUpLeg": Vector3(-14, 0, -8), "RightLeg": Vector3(10, 0, 0), "LeftUpLeg": Vector3(6, 0, 4), "Spine02": Vector3(-6, -6, -2)})
	z.add_animation("valse", lib._clip(1.8, true, [[0.0, v0, Vector3(0, 0, 0)], [0.6, v1, Vector3(0, 2, 0)], [1.2, v2, Vector3(0, 2, 0)], [1.8, v0, Vector3(0, 0, 0)]]))
	# l'appel (la comtesse appelle ses chauves-souris) : les bras levés, la tête en arrière
	var c1 := _m121(a0, {"LeftArm": Vector3(-120, 0, 60), "RightArm": Vector3(-120, 0, -60), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0),
		"Head": Vector3(-30, 0, 0), "Spine02": Vector3(-14, 0, 0)})
	z.add_animation("appel", lib._clip(1.6, true, [[0.0, c1, Vector3(0, 2, 0)], [0.8, _m121(c1, {"LeftArm": Vector3(-132, 0, 66), "RightArm": Vector3(-132, 0, -66)}), Vector3(0, 4, 0)], [1.6, c1, Vector3(0, 2, 0)]]))
	lib.free()
	return z


# =================================================================== la vie

func _physics_process(delta: float) -> void:
	if not SPECS124.has(kind):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _coup121 > 0.0:
		_coup121 = maxf(0.0, _coup121 - delta * 6.0)
		for m in _skin_mats121:
			(m as ShaderMaterial).set_shader_parameter("coup", _coup121)
	_clang124 = maxf(0.0, _clang124 - delta)
	_push_tick(delta)
	if state == "mort":
		_death_tick124(delta)
		return
	if state == "danse":
		velocity = Vector3.ZERO
		_play121(dance_anim, 0.3)
		return
	var tp: Array = _to_player()
	var dist: float = tp[2]
	var dir_p: Vector3 = tp[1]
	if state == "parle":
		# il te regarde ; il parle (le geste) quand le dialogue est ouvert
		var mn: Node = _m71()
		var talking: bool = mn != null and mn.get("dialogue_v31") != null and mn.dialogue_v31 != null and bool(mn.dialogue_v31.opened)
		if dist < 14.0:
			facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
		_play121("vp/parle" if (talking and dist < 6.0) or _parle124 else "vp/attente", 0.4)
		_move124(Vector3.ZERO, delta)
		return
	if not _active75():
		_play121("vp/attente")
		return
	if state == "brume":
		_brume_tick(delta)
		return
	var move := Vector3.ZERO
	timer -= delta
	_brume124 -= delta
	match state:
		"veille":
			if dist < float(spec["vue"]) and float(tp[3]) < 4.0:
				wake()
				manager.alert(self)
			else:
				facing = facing.rotated(Vector3.UP, sin(_clock * 0.25 + _wobble121) * delta * 0.3).normalized()
		"chasse":
			var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
			if dist > float(spec["vue"]) * 2.5 or from_home > float(spec["laisse"]):
				state = "veille"
			elif spec.has("brume") and _brume124 <= 0.0 and dist > 4.5 and dist < 30.0:
				_start_brume(tp[0], dir_p)
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_hit121 = false
				var sword: bool = kind in ["vampire_garde", "radu"]
				_play121("vp/epee" if sword else "vp/attaque", 0.1, 1.0 / maxf(float(spec["armer"]) / (0.5 if sword else 0.42), 0.3))
				_sfx71("vampire_siffle", global_position + Vector3.UP * 1.6, 1.0)
			else:
				var want: Vector3 = dir_p
				# il tourne un peu autour de toi en approchant (jamais en ligne droite)
				var side: Vector3 = dir_p.cross(Vector3.UP) * _side121
				want = (want + side * (0.35 if dist > 3.0 else 0.0)).normalized()
				if _wall121 > 0.0:
					_wall121 -= delta
					want = want.rotated(Vector3.UP, 1.2 * _side121)
				want += _separation121()
				want.y = 0.0
				if want.length() > 0.01:
					facing = facing.lerp(want.normalized(), clampf(delta * 6.0, 0.0, 1.0)).normalized()
				move = facing * float(spec["vitesse"])
				_hiss124 -= delta
				if _hiss124 <= 0.0 and dist < 12.0:
					_hiss124 = randf_range(3.5, 7.0)
					_sfx71("vampire_siffle", global_position + Vector3.UP * 1.6, -3.0)
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 7.0, 0.0, 1.0)).normalized()
			if timer <= 0.0 and not _hit121:
				_hit121 = true
				state = "frappe"
				timer = 0.22
				move = facing * 6.0
				_sfx71("vampire_attaque", global_position + Vector3.UP * 1.5)
				if _hit_player(float(spec["portee"]) + 0.6, 0.25, int(spec["degats"]), 1.6 if kind in ["radu", "vampire_garde"] else 1.0):
					_on_grab121()
		"frappe":
			move = facing * 3.0
			if timer <= 0.0:
				state = "repos"
				timer = float(spec["repos"])
		"repos":
			facing = facing.lerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
			move = -facing * 0.6
			if timer <= 0.0:
				state = "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
				# souvent, touché, il disparaît… pour revenir ailleurs
				if spec.has("brume") and randf() < 0.35:
					_brume124 = 0.0
	_move124(move, delta)


func _move124(move: Vector3, delta: float) -> void:
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 10.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -24.0)
	move_and_slide()
	if is_on_wall() and state == "chasse" and _wall121 <= 0.0:
		_wall121 = 0.7
		_side121 = -_side121 if randf() < 0.4 else _side121
	rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.z), clampf(delta * 7.0, 0.0, 1.0))
	var sp: float = Vector2(velocity.x, velocity.z).length()
	# il flotte : à pleine vitesse, ses pieds ne touchent plus le sol
	_float124 = move_toward(_float124, 0.08 if sp > 2.2 else 0.0, delta * 0.3)
	if _visual != null:
		_visual.position.y = _float124 + (sin(_clock * 2.2 + _wobble121) * 0.02 if _float124 > 0.01 else 0.0)
	match state:
		"chasse", "veille":
			if sp < 0.15:
				_play121("vp/attente", 0.35)
			elif sp > 2.2:
				_play121("vp/glisse", 0.3)
			else:
				_play121("vp/marche", 0.3, clampf(sp / 1.2, 0.5, 1.8))
		"repos":
			_play121("vp/attente", 0.3)


# ------------------------------------------------------------------- la brume

## Il se dissout dans la brume (des chauves-souris s'envolent) et réapparaît près de toi
func _start_brume(player: Vector3, dir_p: Vector3) -> void:
	var spot: Vector3 = _brume_spot(player, dir_p)
	if spot == Vector3.INF:
		_brume124 = 2.0
		return
	_vanish124 = spot
	state = "brume"
	timer = 0.0
	_brume124 = float(spec["brume"]) * randf_range(0.8, 1.3)
	_sfx71("vampire_brume", global_position + Vector3.UP * 1.2)
	_mist124(global_position + Vector3.UP * 1.0)
	bats_burst(global_position + Vector3.UP * 1.3, 7)
	collision_layer = 0


func _brume_spot(player: Vector3, dir_p: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var cam_fwd: Vector3 = -dir_p
	var mn: Node = _m71()
	if mn != null:
		var cam: Node3D = mn.get("xr_camera") if bool(mn.get("xr_active")) else mn.get("pc_camera")
		if cam != null:
			cam_fwd = -cam.global_basis.z
			cam_fwd.y = 0.0
			cam_fwd = cam_fwd.normalized() if cam_fwd.length() > 0.01 else -dir_p
	# de préférence dans ton dos, ou sur le côté
	for a in [PI, PI * 0.75, -PI * 0.75, PI * 0.5, -PI * 0.5, 0.0]:
		var d: Vector3 = cam_fwd.rotated(Vector3.UP, a + randf_range(-0.2, 0.2))
		var r: float = randf_range(2.4, 3.2)
		var at: Vector3 = player + d * r
		var q := PhysicsRayQueryParameters3D.create(player + Vector3.UP * 1.0, at + Vector3.UP * 1.0)
		q.collision_mask = 1
		q.exclude = [get_rid()]
		if not space.intersect_ray(q).is_empty():
			continue
		var q2 := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.2, at + Vector3.DOWN * 2.0)
		q2.collision_mask = 1
		q2.exclude = [get_rid()]
		var hit: Dictionary = space.intersect_ray(q2)
		if hit.is_empty() or absf((hit["position"] as Vector3).y - player.y) > 0.8:
			continue
		return hit["position"]
	return Vector3.INF


func _brume_tick(delta: float) -> void:
	timer += delta
	velocity = Vector3.ZERO
	if timer < 0.35:
		var k: float = 1.0 - timer / 0.35
		_visual.scale = Vector3(k, 1.0, k)
		return
	if timer < 0.7:
		if visible and _visual.scale.x < 0.05 and global_position.distance_to(_vanish124) > 0.1:
			global_position = _vanish124
			_mist124(global_position + Vector3.UP * 1.0)
			_sfx71("vampire_brume", global_position + Vector3.UP * 1.2, -2.0)
		_visual.scale = Vector3.ONE * 0.01
		return
	var k2: float = clampf((timer - 0.7) / 0.3, 0.0, 1.0)
	_visual.scale = Vector3(k2, 1.0, k2)
	var tp: Array = _to_player()
	facing = tp[1]
	rotation.y = atan2(facing.x, facing.z)
	if k2 >= 1.0:
		collision_layer = 1
		_visual.scale = Vector3.ONE
		# tout près : il frappe (on l'entend siffler juste avant)
		state = "armer" if float(tp[2]) < float(spec["portee"]) + 1.2 else "chasse"
		if state == "armer":
			timer = float(spec["armer"]) + 0.15
			_hit121 = false
			_play121("vp/attaque", 0.1, 1.0 / maxf(float(spec["armer"]) / 0.42, 0.3))
			_sfx71("vampire_siffle", global_position + Vector3.UP * 1.6, 4.0)
			var sv: Node = _m71().get("sombreval_v121") if _m71() != null else null
			if sv != null and sv.has_method("haptique"):
				sv.haptique(0.4, 0.15)


func _mist124(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 40
	p.lifetime = 1.6
	p.explosiveness = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.35, 0.9, 0.35)
	p.direction = Vector3.UP
	p.spread = 90.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, 0.15, 0)
	p.damping_min = 0.5
	p.damping_max = 1.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	p.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _puff124()
	p.material_override = mat
	var g := Gradient.new()
	g.set_color(0, Color(0.3, 0.06, 0.1, 0.55))
	g.set_color(1, Color(0.08, 0.06, 0.08, 0.0))
	p.color_ramp = g
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


static var _puff_tex124: Texture2D


static func _puff124() -> Texture2D:
	if _puff_tex124 != null:
		return _puff_tex124
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var d: float = Vector2(x - 15.5, y - 15.5).length() / 15.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2))
	_puff_tex124 = ImageTexture.create_from_image(img)
	return _puff_tex124


## Une nuée de chauves-souris qui s'échappe (elles s'envolent dans tous les sens et disparaissent)
func bats_burst(at: Vector3, n: int) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	_bats_burst_static(parent, at, n)
	if n >= 6:
		_sfx71("nuee_chauves_souris", at, -4.0)


static func _bats_burst_static(parent: Node, at: Vector3, n: int) -> void:
	var body := BoxMesh.new()
	body.size = Vector3(0.07, 0.05, 0.13)
	var wing := BoxMesh.new()
	wing.size = Vector3(0.2, 0.008, 0.1)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.03, 0.025, 0.03)
	mt.roughness = 0.8
	for k in range(n):
		var b := Node3D.new()
		var bm := MeshInstance3D.new()
		bm.mesh = body
		bm.material_override = mt
		b.add_child(bm)
		var wl := MeshInstance3D.new()
		wl.mesh = wing
		wl.material_override = mt
		wl.position = Vector3(-0.11, 0, 0)
		b.add_child(wl)
		var wr := MeshInstance3D.new()
		wr.mesh = wing
		wr.material_override = mt
		wr.position = Vector3(0.11, 0, 0)
		b.add_child(wr)
		parent.add_child(b)
		b.global_position = at + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		var dir := Vector3(randf_range(-1, 1), randf_range(0.2, 1.0), randf_range(-1, 1)).normalized()
		b.look_at(b.global_position + dir, Vector3.UP)
		var dur: float = randf_range(1.0, 1.8)
		var tw := b.create_tween()
		tw.set_parallel(true)
		tw.tween_property(b, "global_position", b.global_position + dir * randf_range(4.0, 8.0), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(b, "scale", Vector3.ONE * 0.3, dur).set_delay(dur * 0.5)
		var flap := b.create_tween().set_loops(int(dur * 9.0))
		flap.tween_property(wl, "rotation:z", 1.0, 0.055)
		flap.tween_property(wl, "rotation:z", -0.7, 0.055)
		var flap2 := b.create_tween().set_loops(int(dur * 9.0))
		flap2.tween_property(wr, "rotation:z", -1.0, 0.055)
		flap2.tween_property(wr, "rotation:z", 0.7, 0.055)
		b.get_tree().create_timer(dur + 0.05).timeout.connect(b.queue_free)


# =================================================================== les coups

func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS124.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state in ["mort", "parle", "brume"] or bool(spec.get("pacifique", false)):
		return
	if state == "danse":
		if on_hit.is_valid():
			on_hit.call(self)
		return
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	if invuln:
		# dans l'ombre, la lame traverse une fumée noire
		if _clang124 <= 0.0:
			_clang124 = 0.5
			_sfx71("armure_bloque", global_position + Vector3.UP * 1.3)
			_mist124(global_position + Vector3.UP * 1.1)
			if cb != null:
				cb.damage_number_color(global_position + Vector3.UP * 2.0, 0, Color(0.6, 0.6, 0.7), "")
			if on_invuln_hit.is_valid():
				on_invuln_hit.call()
		if state == "veille":
			wake()
		return
	if kind in ["vampire_garde", "radu"]:
		damage = maxi(1, int(round(damage * 0.85)))
	hp -= damage
	_coup121 = 0.6
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * 2.0
		if cb.get("critical") == true:
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
	_impact121(global_position + Vector3.UP * 1.3 - away * 0.2, away)
	_sfx71("touche_chair", global_position + Vector3.UP * 1.2, -2.0)
	if hp <= 0:
		_die63()
		return
	if state == "veille":
		wake()
	if kind not in ["vampire_garde", "radu"] or randf() < 0.3:
		_knock = away * 2.4
		state = "recul"
		timer = 0.3
		_cur121 = ""
		_play121("vp/touche", 0.05)
		if randf() < 0.3:
			_sfx71("vampire_siffle", global_position + Vector3.UP * 1.6, 0.0)


func _die63() -> void:
	if not SPECS124.has(kind):
		super._die63()
		return
	_sfx71("vampire_mort", global_position + Vector3.UP * 1.5)
	state = "mort"
	timer = 0.0
	collision_layer = 0
	collision_mask = 0
	_cur121 = ""
	_visual.scale = Vector3.ONE
	_play121("vp/mort", 0.1)
	died.emit(self)


## Vaincu : cambré, les bras ouverts… puis en poussière et en lumière (Tout public), ou en cendres
## et en braises (Public averti) ; une nuée de chauves-souris s'échappe
func _death_tick124(delta: float) -> void:
	timer += delta
	velocity = Vector3.ZERO
	_visual.position.y = minf(_visual.position.y + delta * 0.25, 0.3)
	if timer > 0.9 and not _dust121:
		_dust121 = true
		if Public121.averti():
			_cendres124()
		else:
			_poussiere121()
		bats_burst(global_position + Vector3.UP * 1.3, 10 if is_boss() else 6)
	if timer > 0.9:
		var k: float = clampf(1.0 - (timer - 0.9) / 0.6, 0.01, 1.0)
		_visual.scale = Vector3(k, k * 0.6 + 0.4 * k * k, k)
		for m in _skin_mats121:
			(m as ShaderMaterial).set_shader_parameter("coup", (1.0 - k) * 1.5)
	if timer > 1.5:
		visible = false
	if timer > 3.5:
		queue_free()


func _cendres124() -> void:
	var at: Vector3 = global_position + Vector3.UP * 0.9
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 90
	p.lifetime = 2.4
	p.explosiveness = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.3, 0.85, 0.3)
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, -0.6, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.09
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	p.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.42, 0.12, 1.0))
	g.add_point(0.3, Color(0.25, 0.2, 0.18, 0.9))
	g.set_color(g.get_point_count() - 1, Color(0.1, 0.09, 0.09, 0.0))
	p.color_ramp = g
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS124.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"vampire":
			g.append(["piece", rng.randi_range(2, 6)])
			if rng.randf() < 0.15:
				g.append(["piece_or", 1])
		"vampire_garde":
			g.append(["piece", rng.randi_range(6, 12)])
			if rng.randf() < 0.35:
				g.append(["piece_or", 1])
		"ilona", "sigismund", "radu":
			g.append(["piece", rng.randi_range(25, 40)])
			g.append(["piece_or", 2])
	for e in get_meta("butin_extra", []):
		g.append(e)
	return g


func alert_text() -> String:
	match kind:
		"vampire":
			return "Un vampire ! Il glisse plus vite que tu ne cours, et il disparaît dans la brume… pour réapparaître à côté de toi, souvent dans ton dos. Écoute : il siffle juste avant de frapper. Pare (F) ou recule, puis frappe."
		"vampire_garde":
			return "Un garde vampire, en cuirasse noire ! Il lève son épée au-dessus de l'épaule avant le grand revers : recule ou roule (Ctrl), et frappe juste après."
	return super.alert_text()

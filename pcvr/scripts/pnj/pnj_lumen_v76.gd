extends "res://scripts/pnj/pnj_boucan_v75.gd"
## V76 : un Lumen d'Astralys (l'île flottante). Même vie réglée par l'heure que les autres (et
## toutes les postures des îles d'avant), avec en plus :
##  - leviter : assis en tailleur, à 40 cm du sol, on flotte doucement de haut en bas ;
##  - holo : debout, on manipule un hologramme à deux mains (une petite image qui tourne entre
##    les paumes) ;
##  - mediter : assis, les mains sur les genoux, on respire lentement (un léger halo).
## Et ce qui fait un Lumen (fiche « lumen ») : le bijou de lumière (un halo qui flotte au-dessus de
## la tête, un diadème, un collier) et l'objet à la main (une tablette holographique, un bâton de
## lumière, un thérémine, un télescope de poche, un plateau, l'holo-photo de Glorb, un livre).
## Deux habitants à part : Glorb (un touriste gélatineux et vert : son corps est de gelée) et
## l'Hologuide (un hologramme : transparent, lumineux, qui grésille).

const HOLD_LU := ["leviter", "holo", "mediter"]
const LUEURS := {"bleu_pale": Color(0.55, 0.8, 1.0), "lavande": Color(0.75, 0.6, 1.0), "argent": Color(0.85, 0.9, 1.0),
	"turquoise": Color(0.4, 1.0, 0.9), "rose_nacre": Color(1.0, 0.7, 0.9), "or_pale": Color(1.0, 0.86, 0.55)}

var _lumen: Dictionary = {}
var _halo: Node3D
var _holo_ball: Node3D
var _lu_clock: float = 0.0
var _float_y: float = 0.0
var _special: String = ""


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_lu_poses()
	lumen_props(data.get("lumen", {}))
	_lu_clock = _rng2.randf() * 10.0


func _lu_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	return m


## Les objets de la fiche « lumen » (la peau, la tenue et la crête sont dans le corps, V64).
func lumen_props(lu: Dictionary) -> void:
	if skel == null or lu.is_empty() or not _lumen.is_empty():
		return
	_lumen = lu
	var glow: Color = LUEURS.get(str(lu.get("peau", "bleu_pale")), Color(0.6, 0.8, 1.0))
	_special = str(lu.get("special", ""))
	match str(lu.get("bijou", "")):
		"halo":
			_halo = Node3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.13
			tm.outer_radius = 0.15
			_part(_halo, tm, _lu_glow(glow.lerp(Color(1, 0.95, 0.8), 0.5), 2.2), Vector3.ZERO)
			_attach("Head", Vector3(0, 30, 0), _halo)
		"diademe":
			var dm := Node3D.new()
			var tm2 := TorusMesh.new()
			tm2.inner_radius = 0.085
			tm2.outer_radius = 0.095
			_part(dm, tm2, _m(Color(0.92, 0.9, 0.95), 0.2, 0.9), Vector3.ZERO, Vector3(1.0, 1.0, 1.15))
			_part(dm, _sphere(0.018), _lu_glow(glow, 2.5), Vector3(0, 0.02, 0.1))
			_attach("Head", Vector3(0, 12, 1), dm, Vector3(-12, 0, 0))
		"collier":
			var cl := Node3D.new()
			var tm3 := TorusMesh.new()
			tm3.inner_radius = 0.075
			tm3.outer_radius = 0.085
			_part(cl, tm3, _m(Color(0.95, 0.85, 0.6), 0.25, 0.9), Vector3.ZERO, Vector3(1.0, 1.0, 1.2))
			_part(cl, _sphere(0.022), _lu_glow(glow, 2.5), Vector3(0, -0.02, 0.1))
			_attach("Neck", Vector3(0, -2, 1), cl, Vector3(-30, 0, 0))
	match str(lu.get("objet", "")):
		"tablette_holo":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _box_mesh_np(Vector3(0.16, 0.22, 0.008)), _lu_glow(Color(0.5, 0.8, 1.0), 0.8), Vector3.ZERO)
			_attach("LeftHand", Vector3(0, -6, 6), _hand_prop, Vector3(-60, 0, 0))
		"baton_lumiere":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.012, 0.016, 1.3), _m(Color(0.9, 0.9, 0.95), 0.2, 0.9), Vector3(0, 0.2, 0))
			_part(_hand_prop, _sphere(0.05), _lu_glow(glow, 3.0), Vector3(0, 0.88, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))
		"theremine":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _box_mesh_np(Vector3(0.3, 0.08, 0.14)), _m(Color(0.35, 0.22, 0.14), 0.4), Vector3.ZERO)
			_part(_hand_prop, _cyl(0.004, 0.004, 0.32), _m(Color(0.85, 0.85, 0.9), 0.2, 0.9), Vector3(0.12, 0.2, 0))
			_attach("LeftHand", Vector3(0, -6, 6), _hand_prop, Vector3(-80, 0, 0))
		"telescope_portable":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.025, 0.035, 0.32), _m(Color(0.85, 0.7, 0.35), 0.3, 0.9), Vector3(0, 0.1, 0))
			_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))
		"plateau":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _cyl(0.2, 0.2, 0.015), _m(Color(0.9, 0.9, 0.95), 0.2, 0.8), Vector3.ZERO)
			_part(_hand_prop, _cyl(0.035, 0.03, 0.08), _lu_glow(Color(0.5, 0.4, 1.0), 1.0), Vector3(0.06, 0.05, 0))
			_attach("RightHand", Vector3(0, -2, 8), _hand_prop, Vector3(-90, 0, 0))
		"appareil_holo":
			_hand_prop = Node3D.new()
			_part(_hand_prop, _box_mesh_np(Vector3(0.12, 0.08, 0.07)), _m(Color(0.2, 0.7, 0.3), 0.3), Vector3.ZERO)
			_part(_hand_prop, _cyl(0.025, 0.025, 0.05), _lu_glow(Color(0.6, 1.0, 0.7), 1.5), Vector3(0, 0, 0.05), Vector3.ONE, Vector3(90, 0, 0))
			_attach("Neck", Vector3(0, -14, 10), _hand_prop)
		"livre":
			_mj_object("livre", "")
		"arrosoir":
			punk_props({"objet": "arrosoir"})
	match _special:
		"glorb":
			_jelly(Color(0.35, 0.85, 0.35, 0.82))
		"hologramme":
			_hologram()


## Glorb : tout son corps est de gelée verte, un peu transparente, qui tremble.
func _jelly(c: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.roughness = 0.08
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.rim = 0.8
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.6
	m.emission_enabled = true
	m.emission = Color(0.2, 0.6, 0.2)
	m.emission_energy_multiplier = 0.15
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if (mi as Node).get_parent() == _hand_prop:
			continue
		(mi as MeshInstance3D).material_override = m
	model.scale = Vector3(1.15, 0.92, 1.15)


## L'Hologuide : un hologramme bleu, transparent, qui grésille.
func _hologram() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 0.75, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# =================================================================== postures

func _build_lu_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("lu"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	# assis en tailleur (pour leviter et méditer)
	var tailleur := {"LeftUpLeg": Vector3(-85, -40, 20), "RightUpLeg": Vector3(-85, 40, -20), "LeftLeg": Vector3(120, 0, 0), "RightLeg": Vector3(120, 0, 0),
		"LeftFoot": Vector3(20, 0, 30), "RightFoot": Vector3(20, 0, -30)}
	var lev_a := lib._merge(tailleur, {"LeftArm": Vector3(-20, 0, -50), "RightArm": Vector3(-20, 0, 50), "LeftForeArm": Vector3(-30, 0, 0), "RightForeArm": Vector3(-30, 0, 0), "Head": Vector3(-6, 0, 0)})
	var lev_b := lib._merge(lev_a, {"LeftArm": Vector3(-26, 0, -56), "RightArm": Vector3(-26, 0, 56), "Head": Vector3(4, 0, 0), "Spine02": Vector3(-4, 0, 0)})
	poses.add_animation("leviter", lib._clip(4.0, true, [[0.0, lev_a, Vector3(0, -40, 0)], [2.0, lev_b, Vector3(0, -34, 0)], [4.0, lev_a, Vector3(0, -40, 0)]]))
	var med_a := lib._merge(tailleur, {"LeftArm": Vector3(-10, 0, -20), "RightArm": Vector3(-10, 0, 20), "LeftForeArm": Vector3(-50, 0, 0), "RightForeArm": Vector3(-50, 0, 0), "Head": Vector3(12, 0, 0), "Spine02": Vector3(2, 0, 0)})
	var med_b := lib._merge(med_a, {"Spine02": Vector3(-4, 0, 0), "Head": Vector3(6, 0, 0)})
	poses.add_animation("mediter", lib._clip(6.0, true, [[0.0, med_a, Vector3(0, -82, 0)], [3.0, med_b, Vector3(0, -81, 0)], [6.0, med_a, Vector3(0, -82, 0)]]))
	# holo : les deux mains levées devant soi, qui tournent un hologramme
	var h_a := {"LeftArm": Vector3(-60, 20, -20), "RightArm": Vector3(-60, -20, 20), "LeftForeArm": Vector3(-70, 0, 0), "RightForeArm": Vector3(-70, 0, 0), "Head": Vector3(14, 0, 0)}
	var h_b := lib._merge(h_a, {"LeftArm": Vector3(-70, 40, -10), "RightArm": Vector3(-50, -5, 30), "Head": Vector3(14, 10, 0)})
	var h_c := lib._merge(h_a, {"LeftArm": Vector3(-50, 5, -30), "RightArm": Vector3(-70, -40, 10), "Head": Vector3(14, -10, 0)})
	poses.add_animation("holo", lib._clip(3.0, true, [[0.0, h_a, Vector3.ZERO], [0.8, h_b, Vector3.ZERO], [1.6, h_a, Vector3.ZERO], [2.3, h_c, Vector3.ZERO], [3.0, h_a, Vector3.ZERO]]))
	anim.add_animation_library("lu", poses)
	lib.free()


func _arrive() -> void:
	super._arrive()
	if hidden_home or not pose in HOLD_LU:
		return
	var sp: Dictionary = azur.spot(target_spot)
	if sp.is_empty():
		return
	global_position = sp["pos"]
	var f: Vector3 = _spot_face(sp)
	f.y = 0.0
	if f.length() > 0.01:
		rotation.y = atan2(f.x, f.z)
	_float_y = global_position.y
	if _body != null:
		_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	_lu_clock += delta
	if _special == "hologramme" and model != null:
		# l'hologramme grésille de temps en temps
		model.visible = not (fmod(_lu_clock, 5.3) < 0.08 or fmod(_lu_clock + 1.7, 7.9) < 0.05)
	if _halo != null:
		_halo.rotate_y(delta * 0.8)
	if not pose in HOLD_LU:
		_show_holo(false)
		super._activity(delta, dist, to_player)
		return
	match pose:
		"leviter":
			_show_holo(false)
			_play("lu/leviter", 0.4)
			if model != null:
				model.position.y = 0.4 + sin(_lu_clock * 1.3) * 0.08
		"mediter":
			_show_holo(false)
			_play("lu/mediter", 0.5)
		"holo":
			_play("lu/holo", 0.3)
			_show_holo(true)


## La petite image qui tourne entre les mains (pour la posture holo).
func _show_holo(on: bool) -> void:
	if not on:
		if _holo_ball != null:
			_holo_ball.visible = false
		if model != null and pose != "leviter" and absf(model.position.y) > 0.001:
			model.position.y = 0.0
		return
	if _holo_ball == null:
		_holo_ball = Node3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.1
		sm.height = 0.2
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.5, 0.85, 1.0, 0.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = m
		_holo_ball.add_child(mi)
		add_child(_holo_ball)
		_holo_ball.position = Vector3(0, 1.25, 0.35)
	_holo_ball.visible = true
	_holo_ball.rotate_y(0.03)

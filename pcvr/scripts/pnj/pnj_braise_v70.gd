extends "res://scripts/pnj/pnj_soleils_v69.gd"
## V70 : un démon de Pandémonia (l'Île de Braise). Même vie réglée par l'heure que les autres
## habitants (pnj_azur_v56.gd, et toutes les postures d'Arcanelle, de Cliquetis, de Tazira et
## des Trois Soleils), avec en plus :
##  - violon : la violoniste de la Grand-Place ;
##  - forger : le marteau tombe sur l'enclume de la Grande Forge, les étincelles jaillissent ;
##  - danse : une gigue endiablée (la Nuit des Lanternes) ;
##  - acclamer : sur les gradins de l'Arène des Cornes, on hurle, on applaudit, on lève les bras.
## Et ce qui fait un démon (fiche « demon ») : les cornes (bélier, droites, courbes, petites,
## couronne), la queue qui ondule (pointe en flèche ou en touffe), les ailes de chauve-souris
## (repliées dans le dos, elles frémissent), les yeux qui luisent (plus fort la nuit) ; et les
## objets : la lanterne, le livre, le marteau, le violon, le bâton (la fourche du garde, la
## flamme du prêtre, l'orbe du savant, la canne des anciens).

const EyeShader = preload("res://shaders/oeil_demon_v70.gdshader")
const HOLD_POSES := ["assis", "lire", "allonge", "comptoir", "danse", "violon", "forger", "tisser", "bricoler", "jardiner", "pecher",
	"scribe", "prier", "moudre", "potier", "acclamer", "boire", "lancer_sort"]
const SNAP_POSES := ["violon", "forger", "danse", "acclamer"]

var _dem: Dictionary = {}
var _lueur := Color(1.0, 0.55, 0.18)
var _horns: Array = []
var _tail_root: Node3D
var _tail_joints: Array = []           # Node3D en chaîne : la queue ondule de la base à la pointe
var _tail_amp_d: float = 0.22
var _wings: Array = []                 # [pivot, côté]
var _dem_clock: float = 0.0
var _eye_mat: ShaderMaterial
var _eye_glow: float = 0.5
var _eye_target: float = 0.5
var _night_check: float = 0.0
var _lantern: Node3D
var _lantern_glass: StandardMaterial3D
var _lantern_light: OmniLight3D
var _book: Node3D
var _staff_b: Node3D
var _violin_b: Node3D
var _bow_b: Node3D
var _hammer_b: Node3D
var _sparks_b: CPUParticles3D
var _forge_hit_b: float = -1.0
var _cheer_t: float = 0.0
var _cheering: bool = false
var _sway_y: float = 0.0
static var _mesh_cache: Dictionary = {}


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	_build_br_poses()
	demon_parts(data.get("demon", {}))
	_dem_clock = _rng2.randf() * 10.0
	_cheer_t = _rng2.randf_range(1.0, 6.0)


# =================================================================== postures

func _build_br_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("br"):
		return
	var lib = HeroLib.new()
	lib.hero = model
	lib.anim = anim
	lib.skel = skel
	var ac: Animation = anim.get_animation("Motivational_Cheer")
	if ac != null:
		ac.loop_mode = Animation.LOOP_LINEAR
	var poses := AnimationLibrary.new()
	# le violon : le bras gauche tient le manche, la tête penchée sur la mentonnière, l'archet va
	# et vient ; le corps se balance en mesure
	var v_a := {"LeftArm": Vector3(-74, 0, 26), "LeftForeArm": Vector3(-62, 0, 0), "Head": Vector3(12, 18, 0), "Spine02": Vector3(2, 6, 0),
		"RightArm": Vector3(-52, 0, 30), "RightForeArm": Vector3(-74, 0, 0)}
	var v_b := lib._merge(v_a, {"RightArm": Vector3(-46, 0, 8), "RightForeArm": Vector3(-24, 0, 0), "Spine02": Vector3(2, 2, 0), "Head": Vector3(10, 14, 0)})
	var v_c := lib._merge(v_a, {"Spine02": Vector3(-2, 10, -4), "Head": Vector3(6, 22, -4)})
	poses.add_animation("violon", lib._clip(4.0, true, [[0.0, v_a, Vector3(-1, 0, 0)], [0.5, v_b, Vector3(1, -1, 0)], [1.0, v_a, Vector3(-1, 0, 0)],
		[1.5, v_b, Vector3(1, -1, 0)], [2.0, v_c, Vector3(-1, 0, 0)], [2.5, v_b, Vector3(1, -1, 0)], [3.0, v_c, Vector3(-1, 0, 0)], [3.5, v_b, Vector3(1, -1, 0)], [4.0, v_a, Vector3(-1, 0, 0)]]))
	# forger : le marteau monte au-dessus de l'épaule, tombe sur l'enclume (la pince dans l'autre main)
	var f_up := {"Spine02": Vector3(6, 0, 0), "Head": Vector3(16, 0, 0), "RightArm": Vector3(-148, 0, 8), "RightForeArm": Vector3(-46, 0, 0),
		"LeftArm": Vector3(-42, 0, -12), "LeftForeArm": Vector3(-62, 0, 0), "LeftUpLeg": Vector3(-10, 0, 0), "LeftLeg": Vector3(12, 0, 0), "RightUpLeg": Vector3(4, 0, 0), "RightLeg": Vector3(8, 0, 0)}
	var f_hit := lib._merge(f_up, {"RightArm": Vector3(-58, 0, 14), "RightForeArm": Vector3(-28, 0, 0), "Spine02": Vector3(20, 0, 0), "Head": Vector3(22, 0, 0)})
	poses.add_animation("forger", lib._clip(1.4, true, [[0.0, f_up, Vector3.ZERO], [0.4, f_up, Vector3.ZERO], [0.62, f_hit, Vector3(0, -3, 0)], [0.85, f_hit, Vector3(0, -3, 0)], [1.4, f_up, Vector3.ZERO]]))
	# la gigue : un genou qui monte, l'autre, les bras qui battent la mesure, de petits sauts
	var d_l := {"LeftUpLeg": Vector3(-58, 0, -4), "LeftLeg": Vector3(74, 0, 0), "RightUpLeg": Vector3(-6, 0, 3), "RightLeg": Vector3(10, 0, 0),
		"RightArm": Vector3(-150, 0, 24), "RightForeArm": Vector3(-30, 0, 0), "LeftArm": Vector3(-50, 0, -46), "LeftForeArm": Vector3(-40, 0, 0),
		"Spine02": Vector3(-4, 0, -7), "Head": Vector3(-6, -8, 6)}
	var d_m := {"LeftUpLeg": Vector3(-16, 0, -5), "LeftLeg": Vector3(26, 0, 0), "RightUpLeg": Vector3(-16, 0, 5), "RightLeg": Vector3(26, 0, 0),
		"RightArm": Vector3(-96, 0, 34), "RightForeArm": Vector3(-70, 0, 0), "LeftArm": Vector3(-96, 0, -34), "LeftForeArm": Vector3(-70, 0, 0),
		"Spine02": Vector3(8, 0, 0), "Head": Vector3(4, 0, 0)}
	var d_r := {"RightUpLeg": Vector3(-58, 0, 4), "RightLeg": Vector3(74, 0, 0), "LeftUpLeg": Vector3(-6, 0, -3), "LeftLeg": Vector3(10, 0, 0),
		"LeftArm": Vector3(-150, 0, -24), "LeftForeArm": Vector3(-30, 0, 0), "RightArm": Vector3(-50, 0, 46), "RightForeArm": Vector3(-40, 0, 0),
		"Spine02": Vector3(-4, 0, 7), "Head": Vector3(-6, 8, -6)}
	poses.add_animation("danse", lib._clip(1.2, true, [[0.0, d_l, Vector3(0, 3, 0)], [0.3, d_m, Vector3(0, -5, 0)], [0.6, d_r, Vector3(0, 3, 0)], [0.9, d_m, Vector3(0, -5, 0)], [1.2, d_l, Vector3(0, 3, 0)]]))
	anim.add_animation_library("br", poses)
	lib.free()


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	match pose:
		"violon":
			_br_props("violon")
			_play("br/violon", 0.4)
		"forger":
			_br_props("marteau")
			if dist < 2.2:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
			else:
				_play("br/forger", 0.4)
				_forge_tick_b()
		"danse":
			_br_props("")
			_play("br/danse", 0.3, 1.0 + 0.1 * sin(_dem_clock * 0.3))
			# on danse face au centre, en se tournant un peu à droite, à gauche
			var sway: float = sin(_dem_clock * 0.9) * 0.35
			rotation.y += sway - _sway_y
			_sway_y = sway
		"acclamer":
			_br_props("")
			var fight: bool = _arena_fighting()
			if dist < 2.2 and not fight:
				_face(to_player, delta, 3.0)
				_play("v28/idle", 0.4)
				return
			_cheer_t -= delta
			if _cheer_t <= 0.0:
				_cheering = not _cheering
				_cheer_t = _rng2.randf_range(3.0, 5.5) if _cheering else _rng2.randf_range(5.0, 11.0)
			if fight or _cheering:
				_play("Motivational_Cheer", 0.4, 0.9 if not fight else 1.1)
			else:
				_play("v28/idle", 0.5)
		_:
			_br_props("")
			super._activity(delta, dist, to_player)
	if pose != "danse" and absf(_sway_y) > 0.001:
		_sway_y = 0.0


func _arena_fighting() -> bool:
	if azur == null:
		return false
	var ar: Variant = azur.get("arena")
	return ar != null and is_instance_valid(ar) and (ar as Node).has_method("is_fighting") and bool((ar as Node).call("is_fighting"))


## Les étincelles et le bruit quand le marteau tombe sur l'enclume.
func _forge_tick_b() -> void:
	if anim == null or anim.current_animation != "br/forger":
		return
	var t: float = anim.current_animation_position
	if t >= 0.62 and _forge_hit_b < 0.62:
		if _sparks_b != null and _hammer_b != null:
			_sparks_b.global_position = _hammer_b.global_transform * Vector3(0, 0.36, 0)
			_sparks_b.restart()
			_sparks_b.emitting = true
		if main != null and main.has_method("sfx") and global_position.distance_to(main._player_pos_v27()) < 18.0:
			main.sfx("forge", global_position + Vector3.UP)
	_forge_hit_b = t


func _arrive() -> void:
	super._arrive()
	if hidden_home:
		return
	_sway_y = 0.0
	if pose in SNAP_POSES:
		var sp: Dictionary = azur.spot(target_spot)
		if not sp.is_empty():
			global_position = sp["pos"]
			var f: Vector3 = _spot_face(sp)
			f.y = 0.0
			if f.length() > 0.01:
				rotation.y = atan2(f.x, f.z)
			if _body != null:
				_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)
	_br_props({"violon": "violon", "forger": "marteau"}.get(pose, ""))


func end_talk() -> void:
	super.end_talk()
	if pose in ["violon", "forger", "danse", "acclamer"]:
		current_anim = ""


## Les objets en main selon ce qu'on fait : le violon et le marteau seulement pour jouer et
## forger ; le bâton et la lanterne quand on a les mains libres ; le livre pour lire, enseigner.
func _br_props(which: String) -> void:
	var busy: bool = pose in HOLD_POSES
	if _violin_b != null:
		_violin_b.visible = which == "violon"
		_bow_b.visible = which == "violon"
	if _hammer_b != null:
		_hammer_b.visible = which == "marteau"
	if _staff_b != null:
		_staff_b.visible = not busy
	if _lantern != null:
		_lantern.visible = not busy
	if _book != null:
		_book.visible = pose in ["lire", "enseigner", "debout", "observer"] or state == "marche"


# =================================================================== chaque image

func _process(delta: float) -> void:
	super._process(delta)
	_tick_demon(delta)


func _tick_demon(delta: float) -> void:
	if hidden_home or _asleep:
		return
	_dem_clock += delta
	var excited: float = 1.0
	if state == "parle":
		excited = 1.8
	elif pose in ["danse", "acclamer"] and state != "marche":
		excited = 2.6
	elif state == "marche":
		excited = 1.4
	# la queue : une onde qui court de la base à la pointe
	if not _tail_joints.is_empty():
		var w: float = 1.5 * (1.0 + 0.4 * (excited - 1.0))
		for i in range(_tail_joints.size()):
			var j: Node3D = _tail_joints[i]
			var ph: float = _dem_clock * w - i * 0.9
			j.rotation.y = sin(ph) * _tail_amp_d * (0.6 + 0.35 * i) * minf(excited, 1.8)
			j.rotation.x = sin(ph * 0.5 + 1.0) * 0.06 * (1.0 + i * 0.3)
	# les ailes : repliées, elles respirent ; elles battent quand on danse ou qu'on acclame
	for wg in _wings:
		var pv: Node3D = wg[0]
		var side: float = wg[1]
		var base: Vector3 = wg[2]
		var amp: float = 0.05 if excited < 2.0 else 0.32
		var spd: float = 0.7 if excited < 2.0 else 5.5
		var a: float = (0.5 + 0.5 * sin(_dem_clock * spd + side * 0.2)) * amp
		pv.rotation = base + Vector3(0, -side * a * 0.6, side * a)
	# les yeux luisent plus fort la nuit
	_night_check -= delta
	if _night_check <= 0.0:
		_night_check = 1.0
		var h: float = float(azur.hour()) if azur != null else 12.0
		var night: bool = h >= 19.5 or h < 5.5
		_eye_target = 2.4 if night else 0.55
		if _lantern_glass != null:
			_lantern_glass.emission_energy_multiplier = 3.2 if night else 1.2
		if _lantern_light != null:
			_lantern_light.visible = night and _lantern != null and _lantern.visible
	if absf(_eye_glow - _eye_target) > 0.01:
		_eye_glow = move_toward(_eye_glow, _eye_target, delta * 0.8)
		if _eye_mat != null:
			_eye_mat.set_shader_parameter("lueur", _eye_glow)


## V64 : le corps vient d'être construit (le joueur approche) : les yeux de braise.
func body64_build() -> void:
	super.body64_build()
	_demon_eyes()


func _demon_eyes() -> void:
	if not v64.has("yeux") or _dem.is_empty():
		return
	var mi: MeshInstance3D = v64["yeux"]
	if mi == null or not is_instance_valid(mi):
		return
	if _eye_mat == null:
		_eye_mat = ShaderMaterial.new()
		_eye_mat.shader = EyeShader
		_eye_mat.set_shader_parameter("tex", Corps64._tex("yeux.png"))
		_eye_mat.set_shader_parameter("iris", Color(_lueur.r * 0.62, _lueur.g * 0.62, _lueur.b * 0.62))
	_eye_mat.set_shader_parameter("lueur", _eye_glow)
	mi.material_override = _eye_mat


# =================================================================== ce qui fait un démon

## Fiche « demon » : cornes {forme, c, taille}, queue {c, pointe, long}, ailes {c, envergure},
## lueur [r,g,b], tenue, objet.
func demon_parts(d: Dictionary) -> void:
	_dem = d
	if skel == null or d.is_empty():
		return
	var lu: Array = d.get("lueur", [1.0, 0.55, 0.18])
	_lueur = Color(float(lu[0]), float(lu[1]), float(lu[2]))
	# la lueur du sort (les réverbères qu'allume Nox) prend la couleur de ses yeux
	if _glow_mat != null:
		_glow_mat.albedo_color = _lueur
		_glow_mat.emission = _lueur
	if d.has("cornes"):
		_make_horns(d["cornes"])
	if d.has("queue"):
		_make_tail(d["queue"])
	if d.has("ailes"):
		_make_wings(d["ailes"])
	_make_object(str(d.get("objet", "")), str(d.get("tenue", "")))
	_demon_eyes()


## Les repères de la tête (m, repère de l'os « Head » au repos) : ceux du vrai corps (V64), ou
## ceux de la grosse tête de l'ancien modèle.
func _head_box() -> Dictionary:
	if not _tete64.is_empty():
		var ey: Array = _tete64.get("yeux", [0.0, 0.04, 0.07])
		return {"haut": float(_tete64.get("haut", 0.14)), "cote": float(_tete64.get("cote", 0.075)), "avant": float(_tete64.get("avant", 0.1)),
			"arriere": float(_tete64.get("arriere", -0.09)), "k": 1.0}
	return {"haut": 0.4, "cote": 0.22, "avant": 0.24, "arriere": -0.21, "k": 2.6}


static func _c(v: Variant, dflt: Color) -> Color:
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return dflt


func _horn_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = 0.36
	m.metallic_specular = 0.6
	return m


func _make_horns(h: Dictionary) -> void:
	var forme: String = str(h.get("forme", "courbes"))
	var c: Color = _c(h.get("c"), Color(0.2, 0.15, 0.14))
	var s: float = clampf(float(h.get("taille", 1.0)), 0.4, 1.8)
	var hb: Dictionary = _head_box()
	var k: float = float(hb["k"])
	var top: float = float(hb["haut"])
	var side: float = float(hb["cote"])
	var zf: float = float(hb["avant"])
	var zb: float = float(hb["arriere"])
	var mat := _horn_mat(c)
	var c0: Color = c * 0.6
	c0.a = 1.0
	var c1: Color = Color(minf(c.r * 1.2 + 0.08, 1.0), minf(c.g * 1.2 + 0.07, 1.0), minf(c.b * 1.15 + 0.06, 1.0))
	var holder := Node3D.new()
	holder.name = "Cornes"
	if forme == "couronne":
		# une couronne de cornes : la plus grande au milieu du front, les autres de plus en plus
		# petites vers l'arrière, toutes un peu penchées vers l'extérieur
		var zc: float = (zf + zb) * 0.5 + 0.004 * k
		var ra: float = side * 0.78
		var rb: float = (zf - zb) * 0.5 * 0.8
		var angs := [0.0, 34.0, -34.0, 68.0, -68.0, 104.0, -104.0]
		var lens := [1.0, 0.82, 0.82, 0.66, 0.66, 0.52, 0.52]
		for i in range(angs.size()):
			var a: float = deg_to_rad(float(angs[i]))
			var base := Vector3(sin(a) * ra, top - 0.016 * k, zc + cos(a) * rb)
			var out := Vector3(sin(a), 0.0, cos(a) * 0.6).normalized()
			var L: float = 0.085 * float(lens[i]) * s * k
			var ctrl := [Vector3.ZERO, out * 0.012 * k + Vector3.UP * L * 0.35, out * 0.03 * k + Vector3.UP * L * 0.72, out * 0.036 * k + Vector3.UP * L + Vector3(0, 0, 0.006 * k)]
			var mesh: ArrayMesh = _tube_cached("cou_%d_%.2f_%.2f" % [i, s, k], ctrl, 0.0095 * sqrt(s) * k * (0.75 + 0.25 * float(lens[i])), 0.0009 * k, 10, 9, 0.0, 0.0, c0, c1)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			mi.position = base
			holder.add_child(mi)
		_attach_raw_head(holder)
		_horns.append(holder)
		return
	var ctrl2: Array = []
	var r0: float = 0.016
	var r1: float = 0.0012
	var ridge: float = 0.0
	var ridge_p: float = 0.02
	var nring: int = 16
	var bx: float = side * 0.5
	var by: float = top - 0.022 * k
	var bz: float = zb + (zf - zb) * 0.62
	match forme:
		"droites":
			ctrl2 = [Vector3.ZERO, Vector3(0.01, 0.06, -0.016), Vector3(0.022, 0.12, -0.038), Vector3(0.032, 0.18, -0.066)]
			r0 = 0.014
			ridge = 0.1
			ridge_p = 0.016
			nring = 26
		"petites":
			ctrl2 = [Vector3.ZERO, Vector3(0.006, 0.034, 0.004), Vector3(0.011, 0.066, 0.014)]
			r0 = 0.013
			nring = 9
			bx = side * 0.42
			by = top + 0.008 * k
			s = maxf(s, 0.95)
			bz = zb + (zf - zb) * 0.72
		"belier":
			# la spirale du bélier : elle part vers le haut et l'arrière, s'enroule derrière
			# l'oreille et revient vers l'avant, le long de la joue, en s'écartant de la tête
			var a0: float = deg_to_rad(40.0)
			var R0: float = 0.055
			var cz: float = -R0 * cos(a0)
			var cy: float = -R0 * sin(a0)
			for i in range(9):
				var t: float = float(i) / 8.0
				var a: float = a0 + t * deg_to_rad(305.0)
				var R: float = R0 * (1.0 - 0.4 * t)
				ctrl2.append(Vector3(0.048 * t + 0.022 * t * t, cy + R * sin(a), cz + R * cos(a)))
			r0 = 0.022
			r1 = 0.004
			ridge = 0.13
			ridge_p = 0.013
			nring = 60
			bx = side * 0.74
			by = top - 0.03 * k
			bz = zb + (zf - zb) * 0.55
		_:
			# courbes : elles montent en s'écartant, se redressent, la pointe revient vers l'avant
			ctrl2 = [Vector3.ZERO, Vector3(0.018, 0.035, -0.004), Vector3(0.045, 0.07, -0.012), Vector3(0.062, 0.11, -0.012), Vector3(0.062, 0.145, 0.0), Vector3(0.05, 0.172, 0.018)]
			r0 = 0.017
			nring = 24
	var sk: float = s * k
	var scaled: Array = []
	for p in ctrl2:
		scaled.append((p as Vector3) * sk)
	for sx in [1.0, -1.0]:
		var path: Array = []
		for p2 in scaled:
			path.append(Vector3((p2 as Vector3).x * sx, (p2 as Vector3).y, (p2 as Vector3).z))
		var mesh2: ArrayMesh = _tube_cached("%s_%s_%.2f_%.2f" % [forme, "g" if sx > 0.0 else "d", s, k], path, r0 * sqrt(s) * k, r1 * k, 12, nring, ridge, ridge_p * sk, c0, c1)
		var mi2 := MeshInstance3D.new()
		mi2.mesh = mesh2
		mi2.material_override = mat
		# le pied de la corne s'enfonce un peu dans le crâne
		mi2.position = Vector3(sx * bx, by, bz) - ((path[1] as Vector3) - (path[0] as Vector3)).normalized() * 0.006 * k
		holder.add_child(mi2)
	_attach_raw_head(holder)
	_horns.append(holder)


## Les cornes sont placées d'après les vrais repères de la tête (m) : accrochées telles quelles.
func _attach_raw_head(node: Node3D) -> void:
	_attach("Head", Vector3.ZERO, node, Vector3.ZERO, true)


func _tube_cached(key: String, ctrl: Array, r0: float, r1: float, sides: int, n: int, ridge: float, ridge_p: float, c0: Color, c1: Color) -> ArrayMesh:
	var full: String = "%s|%.4f|%.4f|%s|%s" % [key, r0, r1, c0.to_html(false), c1.to_html(false)]
	if _mesh_cache.has(full):
		return _mesh_cache[full]
	var path: PackedVector3Array = smooth_path(ctrl, n)
	var radii := PackedFloat32Array()
	for i in range(path.size()):
		var t: float = float(i) / float(path.size() - 1)
		radii.append(lerpf(r0, r1, pow(t, 0.85)))
	var m: ArrayMesh = tube_mesh(path, radii, sides, ridge, ridge_p, c0, c1)
	_mesh_cache[full] = m
	return m


## Une courbe lisse (Catmull-Rom) qui passe par les points de contrôle, échantillonnée en n points.
static func smooth_path(ctrl: Array, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var m: int = ctrl.size()
	if m < 2:
		return out
	for i in range(n):
		var u: float = float(i) / float(n - 1) * float(m - 1)
		var seg: int = mini(int(floor(u)), m - 2)
		var t: float = u - float(seg)
		var p0: Vector3 = ctrl[maxi(seg - 1, 0)]
		var p1: Vector3 = ctrl[seg]
		var p2: Vector3 = ctrl[seg + 1]
		var p3: Vector3 = ctrl[mini(seg + 2, m - 1)]
		if seg == 0:
			p0 = p1 * 2.0 - p2
		if seg + 2 > m - 1:
			p3 = p2 * 2.0 - p1
		var t2: float = t * t
		var t3: float = t2 * t
		out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


## Un tube effilé le long d'un chemin (cornes, queue) : un anneau de `sides` sommets à chaque
## point, de rayon radii[i] (creusé de sillons tous les `ridge_p` mètres pour le bélier et les
## cornes droites), la couleur passe de c0 (le pied) à c1 (la pointe). Faces vers l'extérieur.
static func tube_mesh(path: PackedVector3Array, radii: PackedFloat32Array, sides: int, ridge: float, ridge_p: float, c0: Color, c1: Color) -> ArrayMesh:
	var n: int = path.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acc := PackedFloat32Array()
	acc.append(0.0)
	for i in range(1, n):
		acc.append(acc[i - 1] + path[i].distance_to(path[i - 1]))
	var total: float = maxf(acc[n - 1], 1e-5)
	var t_prev: Vector3 = (path[1] - path[0]).normalized()
	var ref: Vector3 = Vector3.UP if absf(t_prev.dot(Vector3.UP)) < 0.85 else Vector3.RIGHT
	var n1: Vector3 = t_prev.cross(ref).normalized()
	var t_last: Vector3 = t_prev
	for i in range(n):
		var t: Vector3
		if i == 0:
			t = (path[1] - path[0]).normalized()
		elif i == n - 1:
			t = (path[n - 1] - path[n - 2]).normalized()
		else:
			t = (path[i + 1] - path[i - 1]).normalized()
		var ax: Vector3 = t_prev.cross(t)
		if ax.length() > 1e-6:
			n1 = n1.rotated(ax.normalized(), t_prev.angle_to(t))
		n1 = (n1 - t * n1.dot(t)).normalized()
		var n2: Vector3 = t.cross(n1)
		t_prev = t
		t_last = t
		var u: float = acc[i] / total
		var r: float = radii[i]
		if ridge > 0.0 and ridge_p > 0.0 and u < 0.92:
			r *= 1.0 - ridge * pow(0.5 + 0.5 * sin(acc[i] / ridge_p * TAU), 6.0)
		var col: Color = c0.lerp(c1, smoothstep(0.0, 1.0, u))
		# la pente du rayon penche la normale vers la pointe
		var dr: float = 0.0
		if i < n - 1:
			dr = (radii[i] - radii[i + 1]) / maxf(path[i + 1].distance_to(path[i]), 1e-5)
		for kk in range(sides + 1):
			var a: float = TAU * float(kk) / float(sides)
			var d: Vector3 = n1 * cos(a) + n2 * sin(a)
			st.set_color(col)
			st.set_uv(Vector2(float(kk) / float(sides), u))
			st.set_normal((d + t * dr).normalized())
			st.add_vertex(path[i] + d * r)
	var tip_i: int = n * (sides + 1)
	st.set_color(c1)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_normal(t_last)
	st.add_vertex(path[n - 1] + t_last * maxf(radii[n - 1], 0.0005) * 1.6)
	for i2 in range(n - 1):
		for kk2 in range(sides):
			var a0: int = i2 * (sides + 1) + kk2
			var a1: int = a0 + 1
			var b0: int = a0 + sides + 1
			var b1: int = b0 + 1
			st.add_index(a0)
			st.add_index(b0)
			st.add_index(a1)
			st.add_index(a1)
			st.add_index(b0)
			st.add_index(b1)
	var last: int = (n - 1) * (sides + 1)
	for kk3 in range(sides):
		st.add_index(last + kk3)
		st.add_index(tip_i)
		st.add_index(last + kk3 + 1)
	return st.commit()


## La queue : elle sort du bas du dos, retombe, et sa pointe remonte ; en trois morceaux
## articulés (elle ondule de la base à la pointe). Pointe en flèche (le pique de cœur des
## diables), ou en touffe (comme la queue d'un lion).
func _make_tail(q: Dictionary) -> void:
	var c: Color = _c(q.get("c"), Color(0.5, 0.12, 0.12))
	var L: float = clampf(float(q.get("long", 1.0)), 0.5, 1.5)
	var pointe: String = str(q.get("pointe", "fleche"))
	var k: float = 1.0 if not _tete64.is_empty() else 1.0
	var ctrl := [Vector3(0, 0, 0), Vector3(0, -0.04, -0.1), Vector3(0, -0.16, -0.22), Vector3(0.02, -0.32, -0.3), Vector3(0.05, -0.44, -0.36), Vector3(0.08, -0.48, -0.46), Vector3(0.1, -0.44, -0.56)]
	var pts: Array = []
	for p in ctrl:
		pts.append((p as Vector3) * L * k)
	var path: PackedVector3Array = smooth_path(pts, 30)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = 0.62
	var cd: Color = c * 0.78
	cd.a = 1.0
	# trois morceaux : [0..10], [10..20], [20..29] ; chaque articulation au début de son morceau
	var cuts := [0, 10, 20, 29]
	_tail_root = Node3D.new()
	_tail_root.name = "Queue_demon"
	var parent: Node3D = _tail_root
	var prev_origin := Vector3.ZERO
	for s in range(3):
		var j := Node3D.new()
		j.position = path[cuts[s]] - prev_origin
		prev_origin = path[cuts[s]]
		parent.add_child(j)
		_tail_joints.append(j)
		var seg := PackedVector3Array()
		var radii := PackedFloat32Array()
		for i in range(cuts[s], cuts[s + 1] + 1):
			seg.append(path[i] - path[cuts[s]])
			var t: float = float(i) / 29.0
			radii.append(lerpf(0.028, 0.009, t) * sqrt(L) * k)
		var mi := MeshInstance3D.new()
		mi.mesh = tube_mesh(seg, radii, 10, 0.0, 0.0, c.lerp(cd, float(s) / 3.0), c.lerp(cd, float(s + 1) / 3.0))
		mi.material_override = m
		j.add_child(mi)
		parent = j
	# la pointe, au bout du dernier morceau, dans l'axe de la queue
	var tip_at: Vector3 = path[29] - path[cuts[2]]
	var dir: Vector3 = (path[29] - path[27]).normalized()
	var tip := Node3D.new()
	tip.position = tip_at
	tip.basis = _basis_y(dir)
	parent.add_child(tip)
	var tm := StandardMaterial3D.new()
	tm.albedo_color = cd
	tm.roughness = 0.5
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	if pointe == "touffe":
		tm.roughness = 0.9
		var core := MeshInstance3D.new()
		core.mesh = _sphere(0.026 * sqrt(L) * k)
		core.material_override = tm
		core.position = Vector3(0, 0.02 * k, 0)
		core.scale = Vector3(1.0, 1.4, 1.0)
		tip.add_child(core)
		for i3 in range(9):
			var a: float = TAU * float(i3) / 9.0
			var tilt: float = 26.0 if i3 % 2 == 0 else 40.0
			var tuft := MeshInstance3D.new()
			tuft.mesh = _cyl(0.0, 0.013 * k, 0.075 * sqrt(L) * k)
			tuft.material_override = tm
			var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
			tuft.basis = b
			tuft.position = Vector3(0, 0.03 * k, 0) + b * Vector3(0, 0.035 * sqrt(L) * k, 0)
			tip.add_child(tuft)
	else:
		var spade := MeshInstance3D.new()
		spade.mesh = _spade_mesh(0.06 * sqrt(L) * k, 0.1 * sqrt(L) * k, 0.012 * k)
		spade.material_override = tm
		tip.add_child(spade)
	_attach("Hips", Vector3(0, 2.0, -11.0), _tail_root)
	_tail_amp_d = 0.22 if pointe == "fleche" else 0.18


## Une base dont l'axe Y suit `dir`.
static func _basis_y(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## La pointe en pique (un cœur à l'envers, pointu) : une plaque épaisse, chanfreinée, dans le
## plan XY local, l'axe Y vers la pointe.
static func _spade_mesh(w: float, h: float, th: float) -> ArrayMesh:
	var outline: Array = []
	var nseg: int = 22
	for i in range(nseg + 1):
		var t: float = float(i) / float(nseg)
		# de la base (t = 0, au milieu) au lobe, puis à la pointe : un côté
		var y: float = t * h
		var x: float
		if t < 0.12:
			x = lerpf(0.12, 0.5, t / 0.12)
		elif t < 0.45:
			x = 0.5 + 0.5 * sin((t - 0.12) / 0.33 * PI * 0.5)
		else:
			x = pow(1.0 - (t - 0.45) / 0.55, 1.3)
		outline.append(Vector2(x * w * 0.5, y))
	var poly: Array = []
	for p in outline:
		poly.append(p)
	for i2 in range(outline.size() - 2, 0, -1):
		poly.append(Vector2(-(outline[i2] as Vector2).x, (outline[i2] as Vector2).y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(0, h * 0.42, 0)
	var np: int = poly.size()
	for s in [1.0, -1.0]:
		var z: float = s * th * 0.5
		var nrm := Vector3(0, 0, s)
		for i3 in range(np):
			var a: Vector2 = poly[i3]
			var b: Vector2 = poly[(i3 + 1) % np]
			var ca := c + Vector3(0, 0, z * 1.6)
			var pa := Vector3(a.x, a.y, z)
			var pb := Vector3(b.x, b.y, z)
			st.set_normal(nrm)
			if s > 0.0:
				st.add_vertex(ca)
				st.add_vertex(pb)
				st.add_vertex(pa)
			else:
				st.add_vertex(ca)
				st.add_vertex(pa)
				st.add_vertex(pb)
	# le pourtour
	for i4 in range(np):
		var a2: Vector2 = poly[i4]
		var b2: Vector2 = poly[(i4 + 1) % np]
		var e := Vector3(b2.x - a2.x, b2.y - a2.y, 0)
		var nrm2 := Vector3(e.y, -e.x, 0).normalized()
		var q0 := Vector3(a2.x, a2.y, th * 0.5)
		var q1 := Vector3(b2.x, b2.y, th * 0.5)
		var q2 := Vector3(b2.x, b2.y, -th * 0.5)
		var q3 := Vector3(a2.x, a2.y, -th * 0.5)
		st.set_normal(nrm2)
		for v in [q0, q1, q2, q0, q2, q3]:
			st.add_vertex(v)
	return st.commit()


## Les ailes : des ailes de chauve-souris repliées dans le dos (un bras, quatre doigts, la
## membrane tendue entre eux, festonnée), qui respirent doucement.
func _make_wings(w: Dictionary) -> void:
	var c: Color = _c(w.get("c"), Color(0.25, 0.08, 0.1))
	var E: float = clampf(float(w.get("envergure", 1.0)), 0.5, 1.7) * 0.68
	var mem := StandardMaterial3D.new()
	mem.albedo_color = c
	mem.roughness = 0.72
	mem.cull_mode = BaseMaterial3D.CULL_DISABLED
	mem.backlight_enabled = true
	mem.backlight = Color(minf(c.r * 1.6 + 0.12, 1.0), minf(c.g * 1.3 + 0.03, 1.0), minf(c.b * 1.3 + 0.03, 1.0))
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(c.r * 0.55, c.g * 0.5, c.b * 0.5)
	bone.roughness = 0.5
	var claw := StandardMaterial3D.new()
	claw.albedo_color = Color(0.85, 0.8, 0.7)
	claw.roughness = 0.35
	for side in [1.0, -1.0]:
		var pivot := Node3D.new()
		pivot.name = "Aile_demon"
		var R := Vector3.ZERO
		var W := Vector3(0.14 * side, 0.3, -0.12) * E
		var F := [Vector3(0.07 * side, 0.54, -0.2) * E, Vector3(0.27 * side, 0.45, -0.2) * E, Vector3(0.37 * side, 0.22, -0.16) * E, Vector3(0.3 * side, -0.03, -0.12) * E]
		var B := Vector3(0.07 * side, -0.15, -0.06) * E
		# la membrane : un éventail depuis le poignet, les bords festonnés entre les doigts
		var rim: Array = [R]
		var edges := [[R, F[0], 0.0], [F[0], F[1], 0.2], [F[1], F[2], 0.24], [F[2], F[3], 0.24], [F[3], B, 0.2], [B, R, 0.1]]
		for e in edges:
			var a: Vector3 = e[0]
			var b: Vector3 = e[1]
			var sag: float = e[2]
			for i in range(1, 6):
				var t: float = float(i) / 5.0
				var p: Vector3 = a.lerp(b, t)
				p = p.lerp(W, sag * sin(t * PI))
				p.z -= 0.025 * E * sin(t * PI) * (1.0 if sag > 0.05 else 0.3)
				rim.append(p)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i2 in range(rim.size() - 1):
			var p0: Vector3 = W
			var p1: Vector3 = rim[i2]
			var p2: Vector3 = rim[i2 + 1]
			# la normale de la face avant (sens horaire, vue de face) ; l'autre face la retourne
			var nrm: Vector3 = (p2 - p0).cross(p1 - p0).normalized()
			for v in [p0, p1, p2]:
				st.set_normal(nrm)
				st.add_vertex(v)
		var mm := MeshInstance3D.new()
		mm.mesh = st.commit()
		mm.material_override = mem
		pivot.add_child(mm)
		# les os : le bras, les doigts ; la griffe du pouce
		_bone_cyl(pivot, R, W, 0.013 * E, 0.009 * E, bone)
		for f in F:
			_bone_cyl(pivot, W, f, 0.007 * E, 0.0028 * E, bone)
		var cl := MeshInstance3D.new()
		cl.mesh = _cyl(0.0, 0.007 * E, 0.035 * E)
		cl.material_override = claw
		cl.basis = _basis_y((F[0] - W).normalized())
		cl.position = F[0] + (F[0] - W).normalized() * 0.016 * E
		pivot.add_child(cl)
		var base_rot := Vector3(0.0, 0.0, 0.0)
		_wings.append([pivot, side, base_rot])
		_attach("Spine02", Vector3(side * 6.0, 4.0, -12.0), pivot)


func _bone_cyl(parent: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl(r1, r0, a.distance_to(b))
	mi.material_override = mat
	mi.basis = _basis_y((b - a).normalized())
	mi.position = (a + b) * 0.5
	parent.add_child(mi)


## L'objet de la fiche : lanterne, livre, marteau, violon, bâton (selon la tenue).
func _make_object(obj: String, tenue: String) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.3, 0.19, 0.11)
	wood.roughness = 0.75
	var dark_wood := StandardMaterial3D.new()
	dark_wood.albedo_color = Color(0.17, 0.1, 0.06)
	dark_wood.roughness = 0.6
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.2, 0.19, 0.2)
	iron.metallic = 0.85
	iron.roughness = 0.42
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.92, 0.66, 0.26)
	gold.metallic = 0.9
	gold.roughness = 0.3
	match obj:
		"lanterne":
			_lantern = Node3D.new()
			_lantern.name = "Lanterne_demon"
			_part(_lantern, _cyl(0.004, 0.004, 0.12), iron, Vector3(0, -0.06, 0))
			var cage := Node3D.new()
			cage.position = Vector3(0, -0.22, 0)
			_lantern.add_child(cage)
			_part(cage, _cyl(0.045, 0.06, 0.03), iron, Vector3(0, 0.1, 0))
			_part(cage, _cyl(0.06, 0.06, 0.015), iron, Vector3(0, -0.085, 0))
			for kk in range(4):
				var a: float = TAU * kk / 4.0 + PI * 0.25
				_part(cage, _box_mesh_np(Vector3(0.008, 0.17, 0.008)), iron, Vector3(cos(a) * 0.052, 0.0, sin(a) * 0.052))
			_lantern_glass = StandardMaterial3D.new()
			_lantern_glass.albedo_color = Color(1.0, 0.7, 0.35)
			_lantern_glass.emission_enabled = true
			_lantern_glass.emission = Color(_lueur.r, _lueur.g * 0.85, _lueur.b * 0.7).lerp(Color(1.0, 0.6, 0.25), 0.5)
			_lantern_glass.emission_energy_multiplier = 1.2
			_lantern_glass.roughness = 0.2
			_part(cage, _cyl(0.046, 0.046, 0.16), _lantern_glass, Vector3.ZERO)
			_lantern_light = OmniLight3D.new()
			_lantern_light.light_color = Color(1.0, 0.62, 0.3)
			_lantern_light.light_energy = 1.1
			_lantern_light.omni_range = 6.0
			_lantern_light.shadow_enabled = false
			_lantern_light.distance_fade_enabled = true
			_lantern_light.distance_fade_begin = 40.0
			_lantern_light.distance_fade_length = 10.0
			_lantern_light.visible = false
			cage.add_child(_lantern_light)
			_attach("LeftHand", Vector3(0, -7, 2), _lantern)
		"livre":
			_book = Node3D.new()
			var cover := StandardMaterial3D.new()
			cover.albedo_color = Color(0.36, 0.06, 0.08)
			cover.roughness = 0.6
			var pages := StandardMaterial3D.new()
			pages.albedo_color = Color(0.92, 0.86, 0.72)
			pages.roughness = 0.9
			_part(_book, _box_mesh_np(Vector3(0.17, 0.034, 0.23)), cover, Vector3.ZERO)
			_part(_book, _box_mesh_np(Vector3(0.158, 0.028, 0.222)), pages, Vector3(0.008, 0.0, 0.0))
			_part(_book, _box_mesh_np(Vector3(0.03, 0.036, 0.06)), gold, Vector3(-0.07, 0.0, 0.0))
			_attach("RightHand", Vector3(0, -6, 4), _book, Vector3(60, 0, 0))
		"marteau":
			_hammer_b = Node3D.new()
			_part(_hammer_b, _cyl(0.016, 0.02, 0.42), wood, Vector3(0, 0.12, 0))
			_part(_hammer_b, _box_mesh_np(Vector3(0.16, 0.07, 0.07)), iron, Vector3(0, 0.36, 0))
			_hammer_b.visible = false
			_attach("RightHand", Vector3(0, -8, 3), _hammer_b, Vector3(90, 0, 0))
			_sparks_b = CPUParticles3D.new()
			_sparks_b.emitting = false
			_sparks_b.one_shot = true
			_sparks_b.amount = 26
			_sparks_b.lifetime = 0.6
			_sparks_b.explosiveness = 0.95
			_sparks_b.direction = Vector3.UP
			_sparks_b.spread = 70.0
			_sparks_b.initial_velocity_min = 1.5
			_sparks_b.initial_velocity_max = 3.5
			_sparks_b.gravity = Vector3(0, -9.0, 0)
			_sparks_b.scale_amount_min = 0.5
			_sparks_b.scale_amount_max = 1.0
			var sq := QuadMesh.new()
			sq.size = Vector2(0.03, 0.03)
			var sm := StandardMaterial3D.new()
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			sm.albedo_color = Color(1.0, 0.7, 0.3)
			sq.material = sm
			_sparks_b.mesh = sq
			add_child(_sparks_b)
		"violon":
			_violin_b = Node3D.new()
			var vm := StandardMaterial3D.new()
			vm.albedo_color = Color(0.5, 0.17, 0.06)
			vm.roughness = 0.28
			_part(_violin_b, _sphere(0.1), vm, Vector3(0, 0, 0.0), Vector3(0.9, 0.3, 1.0))
			_part(_violin_b, _sphere(0.08), vm, Vector3(0, 0, 0.13), Vector3(0.85, 0.3, 0.9))
			_part(_violin_b, _box_mesh_np(Vector3(0.025, 0.02, 0.26)), dark_wood, Vector3(0, 0.025, 0.3))
			_part(_violin_b, _sphere(0.025), dark_wood, Vector3(0, 0.03, 0.44))
			_violin_b.visible = false
			_attach("Spine02", Vector3(8, 26, 14), _violin_b, Vector3(0, 40, -30))
			_bow_b = Node3D.new()
			_part(_bow_b, _cyl(0.004, 0.006, 0.7), dark_wood, Vector3(0, 0.3, 0))
			var hair := StandardMaterial3D.new()
			hair.albedo_color = Color(0.92, 0.9, 0.84)
			_part(_bow_b, _box_mesh_np(Vector3(0.002, 0.66, 0.01)), hair, Vector3(0, 0.3, 0.014))
			_bow_b.visible = false
			_attach("RightHand", Vector3(0, -7, 3), _bow_b, Vector3(0, 0, 90))
		"baton":
			_staff_b = Node3D.new()
			match tenue:
				"garde":
					# la fourche du capitaine de la Garde (un trident d'acier noirci)
					_part(_staff_b, _cyl(0.016, 0.018, 1.75), dark_wood, Vector3(0, 0.25, 0))
					_part(_staff_b, _box_mesh_np(Vector3(0.2, 0.025, 0.025)), iron, Vector3(0, 1.13, 0))
					for sx in [-1.0, 0.0, 1.0]:
						_part(_staff_b, _cyl(0.0, 0.012, 0.2 if sx == 0.0 else 0.16), iron, Vector3(sx * 0.09, 1.24 + (0.02 if sx == 0.0 else 0.0), 0))
				"pretre":
					# le bâton du gardien du Cœur-Brasier : une petite flamme dans une coupe d'or
					_part(_staff_b, _cyl(0.017, 0.022, 1.6), wood, Vector3(0, 0.2, 0))
					_part(_staff_b, _cyl(0.05, 0.02, 0.06), gold, Vector3(0, 1.02, 0))
					var fl := StandardMaterial3D.new()
					fl.albedo_color = Color(1.0, 0.6, 0.2)
					fl.emission_enabled = true
					fl.emission = Color(1.0, 0.55, 0.15)
					fl.emission_energy_multiplier = 3.0
					fl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					_part(_staff_b, _cyl(0.0, 0.032, 0.11), fl, Vector3(0, 1.1, 0))
				"savant":
					# l'orbe du savant, qui luit de la couleur de ses yeux
					_part(_staff_b, _cyl(0.014, 0.019, 1.55), dark_wood, Vector3(0, 0.2, 0))
					for kk2 in range(3):
						var a2: float = TAU * kk2 / 3.0
						_part(_staff_b, _cyl(0.004, 0.006, 0.12), gold, Vector3(cos(a2) * 0.03, 1.02, sin(a2) * 0.03), Vector3.ONE, Vector3(cos(a2) * 14.0, 0, sin(a2) * 14.0))
					var orb := StandardMaterial3D.new()
					orb.albedo_color = _lueur
					orb.emission_enabled = true
					orb.emission = _lueur
					orb.emission_energy_multiplier = 2.2
					orb.roughness = 0.1
					_part(_staff_b, _sphere(0.045), orb, Vector3(0, 1.06, 0))
				_:
					# la canne noueuse des anciens
					_part(_staff_b, _cyl(0.016, 0.02, 1.25), wood, Vector3(0, -0.2, 0))
					_part(_staff_b, _sphere(0.03), wood, Vector3(0, 0.43, 0.0), Vector3(1.3, 0.9, 1.3))
			_attach("LeftHand", Vector3(0, -8, 3), _staff_b)
			staff_node = _staff_b

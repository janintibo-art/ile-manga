extends Node3D
## V71 : un compagnon d'aventure (Sœur Pétronille, Violette, Sire Tancrède de Tournevent).
## Il prête son VRAI corps d'habitant (comme Gorgoth dans l'arène, monstre_v70._build_gorgoth) :
## le script du corps est pnj/pnj_montjoie_v71.gd s'il existe (sinon pnj/pnj_azur_v56.gd), sans
## cerveau ni agenda ; c'est ce script-ci qui le fait marcher, courir, se battre et parler.
##  - Il suit le joueur (chacun sa place : à gauche, à droite, derrière), court pour le rattraper,
##    réapparaît à côté de lui s'il est à plus de 35 m (téléportation, donjon, débarquement) ;
##    il attend sur la rive quand le joueur prend la barque, et ne va jamais dans l'eau profonde.
##  - Il se bat contre les monstres proches du joueur (monstres_v36.monsters) ; les monstres, eux,
##    ne s'en prennent qu'au joueur : un compagnon ne meurt jamais. À bout de souffle, il s'assoit.
##  - Pétronille : petits coups de masse, soigne un cœur toutes les ~12 s, la Bénédiction (+1 de
##    force pendant 8 s), prie très fort quand un monstre approche, trébuche sur rien.
##  - Violette : un grand éclair (dégâts en zone) toutes les ~15 s ; une fois sur cinq, la foudre
##    la frappe aussi (cheveux dressés, fumée, elle s'assoit deux secondes).
##  - Tancrède : charge le plus gros monstre en criant son nom, frappe fort, mais une fois sur
##    trois il se prend les pieds dans sa cape.
## Les répliques : pnj/compagnons_textes_v71.gd, const TEXTES[id][clé] (repli intégré sinon).

const BODY_V71 := "res://scripts/pnj/pnj_montjoie_v71.gd"
const BODY_FALLBACK := "res://scripts/pnj/pnj_azur_v56.gd"
const TEXTES_PATH := "res://scripts/pnj/compagnons_textes_v71.gd"
const HeroLib = preload("res://scripts/hero_v28.gd")
const PB = preload("res://scripts/pnj/pnj_braise_v70.gd")
const PnjV31 = preload("res://scripts/pnj/pnj_v31.gd")
const SEA_Y: float = -0.42
const TELEPORT_DIST: float = 35.0
const WALK: float = 3.0
const RUN: float = 5.4
## Les places autour du joueur : [côté (m, + = à sa droite), en arrière (m)]
const SLOTS := [[-1.3, 1.5], [1.3, 1.5], [0.0, 2.6]]
## Délai minimal entre deux fois la même réplique (s)
const KEY_CD := {"combat": 25.0, "soin": 18.0, "benediction": 28.0, "eclair": 16.0, "eclair_rate": 0.0, "charge": 12.0, "rate": 14.0,
	"fatigue": 0.0, "relance": 0.0, "victoire": 18.0, "avale": 0.0, "donjon": 60.0, "lac": 150.0, "foret": 150.0, "ville": 150.0,
	"nuit": 200.0, "entre_eux": 0.0, "recruter": 0.0, "deja": 3.0, "congedier": 0.0}
## Les répliques de secours (si compagnons_textes_v71.gd n'existe pas encore).
const FALLBACK := {
	"petronille": {
		"recruter": ["Je viens ! Enfin… je viens si on ne va pas trop loin. Ni trop près des monstres. Je viens !"],
		"deja": ["Mais… je suis déjà là, juste derrière toi ! Depuis tout à l'heure !"],
		"congedier": ["D'accord, je rentre au Temple. Que l'Aube veille sur toi… et sur tes chaussettes."],
		"combat": ["Ô Aube bienveillante, protège-nous, protège-moi, surtout moi, enfin nous tous !", "Un monstre ! Je prie, je prie très fort !"],
		"soin": ["Ne bouge pas, je te soigne ! Voilà, comme neuf. Presque.", "Un peu de lumière de l'Aube, et hop !"],
		"benediction": ["Bénédiction de l'Aube ! Frappe, maintenant, frappe !"],
		"rate": ["Aïe ! Qui a mis ce caillou ici ?", "Je… je n'ai rien. C'est le sol qui a bougé."],
		"fatigue": ["Pouf… je souffle une minute. Une petite minute."],
		"relance": ["Ça va mieux ! On y retourne… doucement."],
		"victoire": ["On a gagné ? On a gagné ! Merci, ô Aube !"],
		"avale": ["La grenouille l'a mangé ! Rends-le-nous, vilaine grenouille !"],
		"donjon": ["Il fait noir… Tu entends ce bruit ? C'était mon ventre. Je crois."],
		"lac": ["J'espère que les grenouilles dorment, à cette heure-ci."],
		"foret": ["Les gobelins… ils mordent, les gobelins ?"],
		"ville": ["Montjoie est si jolie d'ici. On rentre bientôt ?"],
		"nuit": ["Il fait nuit. Je reste tout près de toi, si ça ne te dérange pas."],
		"entre_eux": ["Sire Tancrède, votre cape traîne encore dans la boue…"],
	},
	"violette": {
		"recruter": ["Je… je veux bien venir. Je ne sais lancer que la foudre, mais je la lance très bien. En général."],
		"deja": ["Je suis là… Je suis juste un peu discrète."],
		"congedier": ["D'accord. Je retourne à mes livres. Merci de m'avoir emmenée…"],
		"combat": ["Je prépare un éclair… Reculez un peu, par prudence."],
		"eclair": ["Foudre !", "Éclair céleste… s'il vous plaît !"],
		"eclair_rate": ["… Ça arrive.", "Bzzz… Je vais bien. Mes cheveux, un peu moins."],
		"fatigue": ["Je m'assois un instant. La foudre, ça fatigue."],
		"relance": ["Je suis rechargée. Littéralement."],
		"victoire": ["On a réussi… Je peux reprendre ma lecture ?"],
		"avale": ["Oh non ! Je ne peux pas foudroyer la grenouille… enfin, si, mais doucement !"],
		"donjon": ["Les donjons ont une acoustique formidable pour le tonnerre."],
		"lac": ["L'eau et la foudre… Je vais faire très attention."],
		"foret": ["Les chênes attirent la foudre. Je dis ça… pour rien."],
		"ville": ["La bibliothèque de Montjoie est par là. Juste pour information."],
		"nuit": ["La nuit, mes éclairs se voient de très loin. C'est joli."],
		"entre_eux": ["Sœur Pétronille, vous voulez que je vous lise quelque chose ?"],
	},
	"tancrede": {
		"recruter": ["Moi, Sire Tancrède de Tournevent, je t'accompagne ! L'aventure nous attend, et le dîner aussi !"],
		"deja": ["Je suis déjà à tes côtés, compagnon ! Toujours ! Fièrement !"],
		"congedier": ["Je rentre à la Guilde raconter nos exploits. Je les embellirai à peine."],
		"combat": ["En garde, créature ! Tu ne sais pas à qui tu as affaire !"],
		"charge": ["Moi, Sire Tancrède de Tournevent, je te défie ! À l'assaaaaut !", "Place ! Place au chevalier de Tournevent !"],
		"rate": ["Ma cape ! Encore ma cape !", "C'était… une feinte. Une feinte très avancée."],
		"fatigue": ["Un chevalier ne se fatigue jamais. Il… se repose stratégiquement."],
		"relance": ["Tournevent est de retour !"],
		"victoire": ["Victoire ! Encore un exploit pour ma légende ! Et toi aussi, un peu."],
		"avale": ["Lâche mon compagnon, batracien ! Tu vas goûter à mon épée !"],
		"donjon": ["Un donjon ! J'en ai vaincu cent. Enfin, trois. Enfin, j'en ai vu un."],
		"lac": ["On dit que les cuisses de grenouille sont délicieuses. Je dis ça pour la science."],
		"foret": ["Des gobelins ? Qu'ils viennent ! Je les attends ! De préférence un par un."],
		"ville": ["Montjoie ! Ses tavernes, ses tourtes, ses tavernes…"],
		"nuit": ["La nuit, un chevalier veille. Et grignote un peu."],
		"entre_eux": ["Violette, si tu pouvais éviter de me foudroyer aujourd'hui, j'apprécierais."],
	},
}

static var _textes_cache: Dictionary = {}
static var _textes_loaded: bool = false

signal spoke(ally_id: String, text: String)

var main: Node
var mgr: Node
var id: String = ""
var profile: Dictionary = {}
var npc: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var slot: int = 0
var state: String = "suit"          # suit, attend, combat, charge, sort, prie, assis, chute, fete, depart
var target: Node3D
var priority_target: Node3D
var bubble: Label3D
var _t: float = 0.0
var _atk_cd: float = 0.0
var _heal_cd: float = 4.0
var _bless_cd: float = 10.0
var _bolt_cd: float = 2.5
var _charge_cd: float = 0.0
var _trip_cd: float = 30.0
var _say_cd: float = 0.0
var _key_cd: Dictionary = {}
var _bubble_t: float = 0.0
var _pick_t: float = 0.0
var _excl_t: float = 0.0
var _excl: Array[RID] = []
var _stuck_t: float = 0.0
var _in_fight: bool = false
var _calm_t: float = 99.0
var _kills: int = 0
var _endurance: int = 8
var _pending: Dictionary = {}         # coup en cours : {"t": instant, "dmg": dégâts, "target": cible, "what": …}
var _bolt_at: Vector3 = Vector3.ZERO
var _self_zap: bool = false
var _hair_up: Node3D
var _hair_t: float = 0.0
var _smoke: CPUParticles3D
var _cur_anim: String = ""
var _speed: float = 0.0
var _rng := RandomNumberGenerator.new()
var _last_target: Node3D
var _attack_i: int = 0


func setup(main_node: Node, manager: Node, ally_id: String, prof: Dictionary, slot_i: int = 0) -> void:
	main = main_node
	mgr = manager
	id = ally_id
	profile = prof
	slot = slot_i
	_rng.randomize()
	name = "Compagnon_" + id
	_endurance = _endurance_max()
	_build_body()


func display_name() -> String:
	return str(profile.get("nom", id.capitalize()))


func _endurance_max() -> int:
	match id:
		"tancrede":
			return 9
		"violette":
			return 4
	return 8


# =================================================================== le corps

func _build_body() -> void:
	var path: String = BODY_V71 if ResourceLoader.exists(BODY_V71) else BODY_FALLBACK
	var scr: Script = load(path)
	npc = scr.new()
	npc.set("profile", profile)
	npc.set("display_name", display_name())
	add_child(npc)
	npc.call("_build_body")
	npc.call("body64_build")
	var has_props: bool = npc.has_method("mj_props")
	if has_props:
		# la masse et l'épée, on les tient à la main (pas au côté) : ce sont nos armes
		var mj: Dictionary = (profile.get("mj", {}) as Dictionary).duplicate()
		if id in ["petronille", "tancrede"]:
			mj.erase("objet")
		npc.call("mj_props", mj)
	npc.set_process(false)
	npc.set_physics_process(false)
	var bd: Node = npc.get("_body")
	if bd != null:
		for c in bd.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		(bd as CollisionObject3D).collision_layer = 0
		bd.process_mode = Node.PROCESS_MODE_DISABLED
	bubble = npc.get("bubble")
	if bubble == null:
		bubble = Label3D.new()
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.font_size = 38
		bubble.pixel_size = 0.0028
		bubble.outline_size = 12
		bubble.width = 620
		bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble.position = Vector3(0, 2.35, 0)
		bubble.no_depth_test = true
		add_child(bubble)
	bubble.visible = false
	var vl: Node = npc.get("vr_label")
	if vl != null:
		(vl as Node3D).visible = false
	anim = npc.get("anim")
	skel = npc.get("skel")
	_build_poses()
	_fallback_props(has_props)
	_play("v28/idle")


## Les postures du compagnon : prier (mains jointes), lancer un sort (bras levés), s'asseoir par terre.
func _build_poses() -> void:
	if anim == null or skel == null or anim.has_animation_library("al71"):
		return
	var lib = HeroLib.new()
	lib.hero = npc.get("model")
	lib.anim = anim
	lib.skel = skel
	var poses := AnimationLibrary.new()
	var pray := {"LeftArm": Vector3(-30, -42, 0), "RightArm": Vector3(-30, 42, 0), "LeftForeArm": Vector3(-92, 0, 0), "RightForeArm": Vector3(-92, 0, 0),
		"Head": Vector3(22, 0, 0), "Spine02": Vector3(10, 0, 0), "LeftUpLeg": Vector3(-14, 0, 0), "RightUpLeg": Vector3(-14, 0, 0),
		"LeftLeg": Vector3(26, 0, 0), "RightLeg": Vector3(26, 0, 0)}
	var pray_b := pray.duplicate()
	pray_b["Head"] = Vector3(12, 0, 0)
	pray_b["Spine02"] = Vector3(4, 0, 0)
	poses.add_animation("prier", lib._clip(1.2, true, [[0.0, pray, Vector3(0, -6, 0)], [0.6, pray_b, Vector3(0, -5, 0)], [1.2, pray, Vector3(0, -6, 0)]]))
	var cast := {"LeftArm": Vector3(-150, 0, -18), "RightArm": Vector3(-150, 0, 18), "LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0),
		"Head": Vector3(-14, 0, 0), "Spine02": Vector3(-8, 0, 0)}
	var cast_b := cast.duplicate()
	cast_b["LeftArm"] = Vector3(-165, 0, -10)
	cast_b["RightArm"] = Vector3(-165, 0, 10)
	poses.add_animation("sort", lib._clip(0.5, true, [[0.0, cast, Vector3.ZERO], [0.25, cast_b, Vector3(0, 2, 0)], [0.5, cast, Vector3.ZERO]]))
	var sit := {"LeftUpLeg": Vector3(-86, 0, 10), "RightUpLeg": Vector3(-86, 0, -10), "LeftLeg": Vector3(8, 0, 0), "RightLeg": Vector3(8, 0, 0),
		"LeftFoot": Vector3(-20, 0, 0), "RightFoot": Vector3(-20, 0, 0), "Spine02": Vector3(-12, 0, 0), "Spine01": Vector3(-6, 0, 0),
		"LeftArm": Vector3(28, 0, -22), "RightArm": Vector3(28, 0, 22), "LeftForeArm": Vector3(-10, 0, 0), "RightForeArm": Vector3(-10, 0, 0), "Head": Vector3(8, 0, 0)}
	var sit_b := sit.duplicate()
	sit_b["Head"] = Vector3(14, 8, 0)
	sit_b["Spine02"] = Vector3(-6, 0, 0)
	poses.add_animation("assis_sol", lib._clip(3.0, true, [[0.0, sit, Vector3(0, -80, -6)], [1.5, sit_b, Vector3(0, -81, -6)], [3.0, sit, Vector3(0, -80, -6)]]))
	anim.add_animation_library("al71", poses)
	lib.free()


func _hold(bone: String) -> Node3D:
	if skel == null:
		return null
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skel.add_child(att)
	var hold := Node3D.new()
	hold.position = Vector3(0, 8.5, 2.5)
	# la poignée traverse le poing, l'arme part vers l'avant (os de main des corps V64)
	hold.rotation_degrees = Vector3(-90, 0, 0)
	hold.scale = Vector3.ONE * 100.0
	att.add_child(hold)
	return hold


func _m(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _cylm(a: float, b: float, h: float, seg: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = seg
	return c


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


## Les armes en main (la masse de Pétronille, l'épée de Tancrède) ; sans pnj_montjoie_v71.gd (qui
## pose les chapeaux), le chapeau pointu de Violette.
func _fallback_props(has_props: bool) -> void:
	var wood := _m(Color(0.36, 0.24, 0.13), 0.7)
	var steel := _m(Color(0.78, 0.8, 0.84), 0.25, 0.9)
	var gold := _m(Color(1.0, 0.78, 0.32), 0.25, 1.0)
	var leather := _m(Color(0.28, 0.16, 0.09), 0.75)
	match id:
		"petronille":
			var h: Node3D = _hold("RightHand")
			if h != null:
				_part(h, _cylm(0.016, 0.018, 0.5), wood, Vector3(0, 0.12, 0))
				_part(h, _sph(0.075), gold, Vector3(0, 0.4, 0))
				for k in range(6):
					var a: float = TAU * k / 6.0
					_part(h, _cylm(0.0, 0.02, 0.06), gold, Vector3(cos(a) * 0.075, 0.4, sin(a) * 0.075), Vector3.ONE, Vector3(0, -a, -PI * 0.5))
				_part(h, _sph(0.02), gold, Vector3(0, -0.14, 0))
		"tancrede":
			var h2: Node3D = _hold("RightHand")
			if h2 != null:
				_part(h2, _cylm(0.018, 0.018, 0.16), leather, Vector3(0, 0.0, 0))
				_part(h2, _sph(0.025), gold, Vector3(0, -0.09, 0))
				var guard := BoxMesh.new()
				guard.size = Vector3(0.2, 0.025, 0.035)
				_part(h2, guard, gold, Vector3(0, 0.09, 0))
				var blade := BoxMesh.new()
				blade.size = Vector3(0.05, 0.82, 0.01)
				_part(h2, blade, steel, Vector3(0, 0.51, 0))
				_part(h2, _cylm(0.0, 0.025, 0.08, 4), steel, Vector3(0, 0.96, 0), Vector3(1.0, 1.0, 0.2))
		"violette":
			if not has_props and npc.has_method("_attach"):
				var hat := Node3D.new()
				var felt := _m(Color(0.12, 0.1, 0.3), 0.85)
				_part(hat, _cylm(0.2, 0.2, 0.012, 24), felt, Vector3.ZERO)
				_part(hat, _cylm(0.0, 0.1, 0.32, 16), felt, Vector3(0.01, 0.16, -0.01), Vector3.ONE, Vector3(-0.15, 0, -0.12))
				_part(hat, _cylm(0.102, 0.102, 0.03, 16), _m(Color(0.75, 0.6, 0.2), 0.4, 0.5), Vector3(0, 0.02, 0))
				npc.call("_attach", "Head", Vector3(0, 17, -1), hat)


func _play(nm: String, blend: float = 0.2, speed: float = 1.0) -> void:
	if anim == null or not anim.has_animation(nm):
		return
	if nm != _cur_anim or not anim.is_playing():
		anim.play(nm, blend, speed)
		_cur_anim = nm
	else:
		anim.speed_scale = 1.0
		if absf(anim.get_playing_speed() - speed) > 0.05:
			anim.play(nm, blend, speed)


# =================================================================== le joueur

func _player_feet() -> Vector3:
	if main.xr_active:
		if main.get("vr_body") != null and main.vr_body != null:
			return main.vr_body.global_position
		return main._player_pos_v27() + Vector3.DOWN * 1.6
	return main.pc_root.global_position


func _player_forward() -> Vector3:
	var f := Vector3.FORWARD
	if main.xr_active:
		f = -main.xr_camera.global_basis.z
	elif main.get("hero_v28") != null and main.hero_v28 != null:
		f = main.hero_v28.facing
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func _player_riding() -> bool:
	if main.get("boat_v29") != null and main.boat_v29 != null and bool(main.boat_v29.get("driving")):
		return true
	if main.get("ciel_v54") != null and main.ciel_v54 != null and bool(main.ciel_v54.get("riding")):
		return true
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ferry") != null and az.ferry != null and bool(az.ferry.get("riding")):
		return true
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.has_method("riding") and bool(gr.riding()):
		return true
	var hero: Node = main.get("hero_v28")
	if hero != null and str(hero.get("state")) == "nage":
		return true
	return false


# =================================================================== chaque image

func _physics_process(delta: float) -> void:
	if main == null or npc == null:
		return
	_tick_timers(delta)
	_bubble_tick(delta)
	if _hair_t > 0.0:
		_hair_t -= delta
		if _hair_t <= 0.0 and _hair_up != null:
			_hair_up.visible = false
	if not main.game_started or (main.game_menu != null and main.game_menu.opened):
		return
	if state == "depart":
		_t -= delta
		_walk_dir(-(_player_feet() - global_position).normalized(), WALK, delta)
		if _t <= 0.0:
			queue_free()
		return
	var pp: Vector3 = _player_feet()
	var to_p: Vector3 = pp - global_position
	var flat_p: float = Vector2(to_p.x, to_p.z).length()
	if _player_riding():
		# il attend sur la rive (ou sur le quai) que le joueur revienne
		if state in ["suit", "combat", "charge"]:
			state = "attend"
		if state == "attend":
			_face(to_p, delta, 2.0)
			_play("v28/idle", 0.3)
		else:
			_timed_state(delta)
		return
	if state == "attend":
		state = "suit"
	if flat_p > TELEPORT_DIST or absf(to_p.y) > 12.0:
		teleport_near_player()
		return
	if state in ["sort", "prie", "assis", "chute", "fete"]:
		_timed_state(delta)
		return
	_pick_t -= delta
	if _pick_t <= 0.0:
		_pick_t = 0.35
		_pick_target(pp)
	if target != null:
		_fight(delta, pp)
	else:
		_follow(delta, pp)
	_resolve_pending()


func _tick_timers(delta: float) -> void:
	for k in _key_cd.keys():
		_key_cd[k] = float(_key_cd[k]) - delta
	_say_cd = maxf(_say_cd - delta, 0.0)
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	_heal_cd = maxf(_heal_cd - delta, 0.0)
	_bless_cd = maxf(_bless_cd - delta, 0.0)
	_bolt_cd = maxf(_bolt_cd - delta, 0.0)
	_charge_cd = maxf(_charge_cd - delta, 0.0)
	_trip_cd = maxf(_trip_cd - delta, 0.0)
	if not _pending.is_empty():
		_pending["t"] = float(_pending["t"]) - delta
	# Pétronille soigne le joueur blessé, où qu'on soit (sauf assise ou par terre)
	if id == "petronille" and _heal_cd <= 0.0 and not (state in ["assis", "chute", "attend", "depart"]):
		var hero: Node = main.get("hero_v28")
		if hero != null and int(hero.hp) > 0 and int(hero.hp) < int(hero.HP_MAX) and _player_feet().distance_to(global_position) < 16.0:
			_heal()


func _timed_state(delta: float) -> void:
	_t -= delta
	match state:
		"sort":
			_play("al71/sort", 0.15)
			if target != null and is_instance_valid(target):
				_face(target.global_position - global_position, delta, 6.0)
			if id == "violette" and _t <= 0.3 and not _pending.has("bolt_done"):
				_pending = {"t": 0.0, "bolt_done": true}
				_cast_bolt()
			elif id == "petronille" and _t <= 0.3 and not _pending.has("bless_done"):
				_pending = {"t": 0.0, "bless_done": true}
				_bless()
		"prie":
			_play("al71/prier", 0.2)
		"assis":
			_play("al71/assis_sol", 0.3)
		"chute":
			_play("Knock_Down", 0.08, 1.2)
		"fete":
			_play("Motivational_Cheer", 0.2, 1.1)
	_snap_ground()
	if _t <= 0.0:
		var was: String = state
		state = "suit"
		_pending.clear()
		if was == "assis" and _endurance <= 0:
			_endurance = _endurance_max()
			say("relance", true)
		elif was == "assis" and _self_zap:
			_self_zap = false


# =================================================================== suivre

func _follow(delta: float, pp: Vector3) -> void:
	if _in_fight:
		_calm_t += delta
		if _calm_t > 2.5:
			_in_fight = false
			if _kills > 0 and _rng.randf() < 0.75:
				if say("victoire"):
					state = "fete"
					_t = 2.2
			_kills = 0
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var sl: Array = SLOTS[slot % SLOTS.size()]
	var goal: Vector3 = pp + right * float(sl[0]) - f * float(sl[1])
	var to_g: Vector3 = goal - global_position
	to_g.y = 0.0
	var d: float = to_g.length()
	if d > 0.5:
		var sp: float = WALK if d < 4.0 else (RUN if d < 12.0 else RUN * 1.3)
		var ok: bool = _walk_dir(to_g / d, sp, delta)
		_stuck(delta, ok, d)
		# Pétronille trébuche sur rien
		if id == "petronille" and sp >= RUN and _trip_cd <= 0.0 and _rng.randf() < delta * 0.08:
			_trip("atterrissage")
	else:
		_speed = 0.0
		_stuck_t = 0.0
		_face(pp - global_position if (pp - global_position).length() < 5.0 else f, delta, 3.0)
		_play("v28/idle", 0.3)
		_snap_ground()


func _stuck(delta: float, moved: bool, d: float) -> void:
	if moved:
		_stuck_t = maxf(_stuck_t - delta, 0.0)
		return
	_stuck_t += delta
	_play("v28/idle", 0.3)
	if _stuck_t > 4.0 and d > 6.0:
		_stuck_t = 0.0
		teleport_near_player()


## Un pas dans une direction (contourne un mur, ne monte pas les murs, ne va pas dans l'eau).
func _walk_dir(dir: Vector3, sp: float, delta: float) -> bool:
	dir.y = 0.0
	if dir.length() < 0.01:
		return false
	dir = dir.normalized()
	for turn in [0.0, 0.7, -0.7, 1.3, -1.3]:
		var dd: Vector3 = dir.rotated(Vector3.UP, turn)
		if _try_step(dd, sp * (1.0 if turn == 0.0 else 0.8), delta):
			_speed = sp
			_face(dd, delta, 8.0)
			if sp > WALK + 0.5:
				_play("Running", 0.2, clampf(sp / 5.0, 0.8, 1.5))
			else:
				_play("Walking", 0.2, clampf(sp / 1.15, 0.8, 2.6))
			return true
	_speed = 0.0
	return false


func _try_step(dir: Vector3, sp: float, delta: float) -> bool:
	var from: Vector3 = global_position
	var to: Vector3 = from + dir * sp * delta
	var space := get_world_3d().direct_space_state
	_refresh_excl()
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.55, from + Vector3.UP * 0.55 + dir * 0.45, 1, _excl)
	if not space.intersect_ray(q).is_empty():
		return false
	var gy: float = _ground_y(to, from.y)
	if gy < -1e8:
		return false
	if gy - from.y > 0.7 or from.y - gy > 3.0:
		return false
	if _deep_water(Vector3(to.x, gy, to.z)):
		return false
	global_position = Vector3(to.x, gy, to.z)
	return true


func _ground_y(at: Vector3, ref_y: float) -> float:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, ref_y + 1.2, at.z), Vector3(at.x, ref_y - 3.5, at.z), 1, _excl)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	if ref_y > -40.0 and main.has_method("_height_at"):
		var g: float = float(main._height_at(at.x, at.z))
		if absf(g - ref_y) < 1.5:
			return g
	return -1e9


func _deep_water(p: Vector3) -> bool:
	if p.y < -40.0:
		return false
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("atl") != null and mer.atl != null and mer.atl.has_method("in_dome") and mer.atl.in_dome(p + Vector3.UP):
		return false
	return SEA_Y - p.y > 0.75


func _snap_ground() -> void:
	_refresh_excl()
	var gy: float = _ground_y(global_position, global_position.y)
	if gy > -1e8 and absf(gy - global_position.y) < 1.2:
		global_position.y = gy


func _refresh_excl() -> void:
	_excl_t -= get_physics_process_delta_time()
	if _excl_t > 0.0 and not _excl.is_empty():
		return
	_excl_t = 0.5
	_excl.clear()
	for b in [main.get("pc_body"), main.get("vr_body")]:
		if b != null and is_instance_valid(b):
			_excl.append((b as CollisionObject3D).get_rid())
	for r in PnjV31._npc_bodies:
		_excl.append(r)
	var ms: Node = main.get("monstres_v36")
	if ms != null:
		for m in ms.monsters:
			if is_instance_valid(m) and (m as Node3D).global_position.distance_to(global_position) < 12.0:
				_excl.append((m as CollisionObject3D).get_rid())


func _face(dir: Vector3, delta: float, speed: float = 6.0) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), clampf(delta * speed, 0.0, 1.0))


## Réapparaît à côté du joueur (sur la terre ferme, à sa place si possible).
func teleport_near_player() -> void:
	if main == null:
		return
	var pp: Vector3 = _player_feet()
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var sl: Array = SLOTS[slot % SLOTS.size()]
	var cands: Array = [pp + right * float(sl[0]) - f * float(sl[1]), pp - f * 1.6, pp + right * 1.4, pp - right * 1.4, pp + f * 1.5, pp - f * 0.8 + right * 0.6]
	_excl_t = 0.0
	_refresh_excl()
	var placed: bool = false
	for c in cands:
		var cv: Vector3 = c
		var gy: float = _ground_y(cv, pp.y + 0.5)
		if gy > -1e8 and absf(gy - pp.y) < 1.6 and not _deep_water(Vector3(cv.x, gy, cv.z)):
			global_position = Vector3(cv.x, gy, cv.z)
			placed = true
			break
	if not placed:
		global_position = pp - f * 0.7
	rotation.y = atan2(f.x, f.z)
	_stuck_t = 0.0
	target = null
	if state in ["attend", "combat", "charge"]:
		state = "suit"
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.puff(global_position + Vector3.UP * 0.6, Color(0.95, 0.95, 1.0))


# =================================================================== combattre

func _valid_monster(m: Variant) -> bool:
	if m == null or not is_instance_valid(m):
		return false
	var n: Node3D = m as Node3D
	if n == null or not n.is_inside_tree() or not n.visible:
		return false
	if str(n.get("state")) in ["mort", "rendu", "dort"] or str(n.get("kind")) == "navet" or bool(n.get("asleep")):
		return false
	if n.has_method("is_hittable") and not bool(n.is_hittable()):
		return false
	return true


func _pick_target(pp: Vector3) -> void:
	if target != null and not _valid_monster(target):
		if is_instance_valid(target) and str(target.get("state")) == "mort":
			_kills += 1
		target = null
	if priority_target != null:
		if _valid_monster(priority_target):
			target = priority_target
			return
		priority_target = null
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		target = null
		return
	var best: Node3D = null
	var best_s: float = INF
	for m in ms.monsters:
		if not _valid_monster(m):
			continue
		var n: Node3D = m
		var dp: Vector3 = n.global_position - pp
		if Vector2(dp.x, dp.z).length() > 14.0 or absf(dp.y) > 5.0:
			continue
		var dm: float = n.global_position.distance_to(global_position)
		if dm > 26.0:
			continue
		var sc: float = Vector2(dp.x, dp.z).length()
		if id == "tancrede":
			var sp: Dictionary = n.get("spec") if n.get("spec") != null else {}
			sc = -float(sp.get("pv", 1)) * 10.0 + dm * 0.5
		if sc < best_s:
			best_s = sc
			best = n
	if best != null and target == null and not _in_fight:
		_start_fight(best)
	target = best


func _start_fight(m: Node3D) -> void:
	_in_fight = true
	_calm_t = 0.0
	match id:
		"petronille":
			if _rng.randf() < 0.8 and state == "suit":
				state = "prie"
				_t = 1.8
				say("combat")
		"violette":
			_bolt_cd = minf(_bolt_cd, 2.0)
			say("combat")
		"tancrede":
			_charge_cd = 0.0
			if _rng.randf() < 0.4:
				say("combat")


func _fight(delta: float, pp: Vector3) -> void:
	_calm_t = 0.0
	if not _in_fight:
		_start_fight(target)
		if state != "suit":
			return
	var tp: Vector3 = target.global_position
	var to_t: Vector3 = tp - global_position
	to_t.y = 0.0
	var d: float = to_t.length()
	var reach: float = float(target.get("hit_radius")) + 1.05
	match id:
		"violette":
			# elle garde ses distances, et foudroie
			if _bolt_cd <= 0.0 and d < 13.0:
				_bolt_at = tp
				state = "sort"
				_t = 1.05
				_bolt_cd = 15.0
				_pending.clear()
				return
			var want: float = 6.0
			if d < want - 1.5:
				_walk_dir(-to_t, WALK, delta)
			elif d > want + 4.0:
				_walk_dir(to_t, RUN, delta)
			else:
				_face(to_t, delta, 6.0)
				_play("v28/idle", 0.3)
				_snap_ground()
			return
		"petronille":
			# la Bénédiction, de temps en temps, pendant un combat
			if _bless_cd <= 0.0:
				state = "sort"
				_t = 1.0
				_bless_cd = 30.0
				_pending.clear()
				return
			# craintive : elle ne s'éloigne pas du joueur
			var tp_from_player: float = Vector2(tp.x - pp.x, tp.z - pp.z).length()
			if tp_from_player > 6.0 and d > reach:
				_follow(delta, pp)
				return
		"tancrede":
			if state == "charge":
				_t -= delta
				if d <= reach + 0.2 or _t <= 0.0:
					state = "suit"
					_charge_hit()
				else:
					_walk_dir(to_t, 7.4, delta)
					_play("Running", 0.15, 1.5)
				return
			if _charge_cd <= 0.0 and d > 3.0:
				state = "charge"
				_t = 3.0
				_charge_cd = 14.0
				say("charge", true)
				_sfx("charge_chevalier", global_position + Vector3.UP * 1.5)
				return
	if d > reach:
		var ok: bool = _walk_dir(to_t, RUN if d > 4.0 else WALK, delta)
		_stuck(delta, ok, Vector2(pp.x - global_position.x, pp.z - global_position.z).length())
		return
	_face(to_t, delta, 8.0)
	_snap_ground()
	if _atk_cd <= 0.0 and _pending.is_empty():
		_melee()
	elif _pending.is_empty() and _atk_cd > 0.4:
		_play("v28/idle", 0.25)


func _melee() -> void:
	_attack_i += 1
	var cd: float = 1.8 if id == "petronille" else 1.4
	_atk_cd = cd
	var slashes: Array = ["v28/slash1", "v28/slash2", "v28/slash3"]
	_play(slashes[_attack_i % 3] if id == "tancrede" else "v28/slash1", 0.08, 1.0 if id == "tancrede" else 0.85)
	_cur_anim = ""
	var dmg: int = 1 if id == "petronille" else 3
	var miss: bool = id == "tancrede" and _rng.randf() < 1.0 / 3.0
	_pending = {"t": 0.3, "dmg": 0 if miss else dmg, "target": target, "miss": miss}
	_spend()


func _resolve_pending() -> void:
	if _pending.is_empty() or not _pending.has("dmg") or float(_pending["t"]) > 0.0:
		return
	var m: Variant = _pending.get("target")
	var dmg: int = int(_pending["dmg"])
	var miss: bool = bool(_pending.get("miss", false))
	_pending.clear()
	if miss:
		# Tancrède : l'épée part dans le vide, il titube
		_play("v28/hurt", 0.05, 0.8)
		_cur_anim = ""
		_sfx("fendre_air", global_position + Vector3.UP * 1.2)
		say("rate")
		return
	if not _valid_monster(m):
		return
	var mn: Node3D = m
	if mn.global_position.distance_to(global_position) > float(mn.get("hit_radius")) + 2.2:
		return
	mn.take_hit(dmg, global_position)
	_sfx("touche_lourd" if dmg >= 4 else "touche_chair", mn.global_position + Vector3.UP * 0.8)


func _spend() -> void:
	_endurance -= 1
	if _endurance <= 0:
		_pending.clear()
		state = "assis"
		_t = 3.5
		say("fatigue", true)


## Tancrède arrive au bout de sa charge : un grand coup… ou les pieds dans la cape.
func _charge_hit() -> void:
	if _rng.randf() < 1.0 / 3.0:
		_trip("chute_armure")
		return
	_play("v28/slash3", 0.08, 1.1)
	_cur_anim = ""
	_atk_cd = 1.4
	_pending = {"t": 0.25, "dmg": 5, "target": target, "miss": false}
	_spend()


func _trip(snd: String) -> void:
	_trip_cd = _rng.randf_range(40.0, 70.0)
	state = "chute"
	_t = 1.9
	_pending.clear()
	_cur_anim = ""
	_sfx(snd, global_position + Vector3.UP * 0.5)
	say("rate", true)
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.puff(global_position + Vector3.UP * 0.2 + global_basis.z * 0.8, Color(0.75, 0.68, 0.55))


# --------------------------------------------------------------- Pétronille

func _heal() -> void:
	var hero: Node = main.get("hero_v28")
	if hero == null:
		return
	_heal_cd = 12.0
	hero.hp = mini(int(hero.hp) + 2, int(hero.HP_MAX))
	hero.health_changed.emit(hero.hp, hero.HP_MAX)
	var pp: Vector3 = _player_feet()
	_sfx("soin", pp + Vector3.UP)
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(pp + Vector3.UP * 2.1, "+1 ♥", Color(1.0, 0.55, 0.6))
	_sparkles(pp, Color(1.0, 0.85, 0.5), 1.2)
	say("soin")


func _bless() -> void:
	if mgr != null and mgr.has_method("bless"):
		mgr.bless(8.0)
	say("benediction", true)
	_sparkles(_player_feet(), Color(1.0, 0.9, 0.4), 2.0)
	_sfx("benediction", _player_feet() + Vector3.UP)


## Des paillettes de lumière qui montent autour du joueur.
func _sparkles(at: Vector3, c: Color, secs: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.0
	p.one_shot = false
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.6
	p.emission_ring_inner_radius = 0.4
	p.emission_ring_height = 0.1
	p.direction = Vector3.UP
	p.spread = 15.0
	p.gravity = Vector3(0, 1.0, 0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.4
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.1)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = c
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	main.add_child(p)
	p.global_position = at + Vector3.UP * 0.1
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.2
	l.omni_range = 3.0
	p.add_child(l)
	l.position = Vector3.UP * 1.0
	get_tree().create_timer(secs).timeout.connect(func(): if is_instance_valid(p): p.emitting = false)
	get_tree().create_timer(secs + 1.2).timeout.connect(func(): if is_instance_valid(p): p.queue_free())


# --------------------------------------------------------------- Violette

func _cast_bolt() -> void:
	var at: Vector3 = _bolt_at
	if target != null and is_instance_valid(target):
		at = target.global_position
	_bolt(at, true)
	var ms: Node = main.get("monstres_v36")
	if ms != null:
		for m in ms.monsters.duplicate():
			if not is_instance_valid(m) or str(m.get("state")) in ["mort", "rendu"]:
				continue
			var n: Node3D = m
			if Vector2(n.global_position.x - at.x, n.global_position.z - at.z).length() < 3.5 + float(n.get("hit_radius")) and absf(n.global_position.y - at.y) < 3.0:
				n.take_hit(6, at + Vector3(0.01, 0, 0.01))
	_spend()
	if _rng.randf() < 0.2:
		# une fois sur cinq, la foudre la frappe aussi
		_self_zap = true
		get_tree().create_timer(0.3).timeout.connect(_zap_self)
	else:
		say("eclair")


func _zap_self() -> void:
	if not is_instance_valid(self) or npc == null:
		return
	_bolt(global_position, false)
	_sfx("eclair_rate", global_position + Vector3.UP * 1.5)
	state = "assis"
	_t = 2.2
	_pending.clear()
	_cur_anim = ""
	_hair_spikes()
	_puff_smoke()
	say("eclair_rate", true)


## L'éclair : une ligne brisée qui tombe du ciel, deux branches, un flash de lumière bleue.
func _bolt(at: Vector3, big: bool) -> void:
	var root := Node3D.new()
	main.add_child(root)
	root.global_position = Vector3.ZERO
	var top: Vector3 = at + Vector3(_rng.randf_range(-3, 3), 24.0 if big else 14.0, _rng.randf_range(-3, 3))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.75, 0.85, 1.0, 1.0)
	m.vertex_color_use_as_albedo = false
	var glow := m.duplicate() as StandardMaterial3D
	glow.albedo_color = Color(0.35, 0.5, 1.0, 0.35)
	var main_path: Array = _jag(top, at, 16, 1.4)
	_bolt_mesh(root, main_path, 0.06 if big else 0.04, m)
	_bolt_mesh(root, main_path, 0.3 if big else 0.18, glow)
	for b in range(2 if big else 1):
		var from: Vector3 = main_path[_rng.randi_range(4, 9)]
		var to: Vector3 = from + Vector3(_rng.randf_range(-4, 4), -_rng.randf_range(4, 8), _rng.randf_range(-4, 4))
		_bolt_mesh(root, _jag(from, to, 8, 0.8), 0.025, m)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.8, 1.0)
	l.light_energy = 10.0 if big else 5.0
	l.omni_range = 18.0 if big else 8.0
	l.shadow_enabled = false
	root.add_child(l)
	l.global_position = at + Vector3.UP * 3.0
	var tw := root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "light_energy", 0.0, 0.35)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.3).set_delay(0.08)
	tw.tween_property(glow, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(root.queue_free)
	if big:
		_sfx("eclair", at + Vector3.UP * 2.0)
	var cb: Node = main.get("combat_v28")
	if cb != null:
		for k in range(6 if big else 3):
			var a: float = TAU * k / 6.0
			cb.puff(at + Vector3(cos(a) * 1.2, 0.2, sin(a) * 1.2), Color(0.8, 0.88, 1.0))


func _jag(a: Vector3, b: Vector3, n: int, amp: float) -> Array:
	var pts: Array = []
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var p: Vector3 = a.lerp(b, t)
		if i > 0 and i < n:
			var k: float = amp * sin(t * PI)
			p += Vector3(_rng.randf_range(-k, k), _rng.randf_range(-k, k) * 0.3, _rng.randf_range(-k, k))
		pts.append(p)
	return pts


func _bolt_mesh(parent: Node3D, pts: Array, r: float, mat: Material) -> void:
	var path := PackedVector3Array()
	for p in pts:
		path.append(p)
	var radii := PackedFloat32Array()
	for i in range(path.size()):
		radii.append(r * lerpf(0.6, 1.0, float(i) / float(path.size() - 1)))
	var mi := MeshInstance3D.new()
	mi.mesh = PB.tube_mesh(path, radii, 5, 0.0, 0.0, Color(1, 1, 1), Color(1, 1, 1))
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Les cheveux dressés sur la tête (après un éclair de travers).
func _hair_spikes() -> void:
	if _hair_up == null and npc.has_method("_attach"):
		_hair_up = Node3D.new()
		var c := Color(0.24, 0.12, 0.34)
		var az: Dictionary = profile.get("azur", {})
		if az.has("cheveux"):
			var hc: Array = az["cheveux"]
			c = Color(float(hc[0]), float(hc[1]), float(hc[2]))
		var hm := _m(c, 0.6)
		for k in range(14):
			var a: float = TAU * k / 14.0
			var tilt: float = 0.45 + 0.2 * (k % 2)
			_part(_hair_up, _cylm(0.0, 0.03, 0.22 + 0.06 * (k % 3), 6), hm, Vector3(cos(a) * 0.06, 0.1, sin(a) * 0.06), Vector3.ONE, Vector3(sin(a) * tilt, 0, -cos(a) * tilt))
		var spark := _m(Color(0.7, 0.85, 1.0), 0.2)
		spark.emission_enabled = true
		spark.emission = Color(0.6, 0.8, 1.0)
		spark.emission_energy_multiplier = 4.0
		for s in range(4):
			_part(_hair_up, _sph(0.012), spark, Vector3(_rng.randf_range(-0.1, 0.1), 0.3, _rng.randf_range(-0.1, 0.1)))
		npc.call("_attach", "Head", Vector3(0, 14, -1), _hair_up)
	if _hair_up != null:
		_hair_up.visible = true
		_hair_t = 4.0


func _puff_smoke() -> void:
	if _smoke == null:
		_smoke = CPUParticles3D.new()
		_smoke.amount = 24
		_smoke.lifetime = 1.6
		_smoke.one_shot = true
		_smoke.explosiveness = 0.6
		_smoke.local_coords = false
		_smoke.direction = Vector3.UP
		_smoke.spread = 25.0
		_smoke.gravity = Vector3(0, 0.8, 0)
		_smoke.initial_velocity_min = 0.3
		_smoke.initial_velocity_max = 0.9
		_smoke.scale_amount_min = 1.0
		_smoke.scale_amount_max = 2.5
		var q := QuadMesh.new()
		q.size = Vector2(0.3, 0.3)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.35, 0.35, 0.38, 0.55)
		if main.has_method("_soft_dot_v24"):
			m.albedo_texture = main._soft_dot_v24()
		q.material = m
		_smoke.mesh = q
		add_child(_smoke)
		_smoke.position = Vector3(0, 1.5, 0)
	_smoke.restart()
	_smoke.emitting = true


# =================================================================== réactions

## La grenouille a avalé le joueur : on s'indigne, et on tape la grenouille.
func on_player_swallowed(frog: Node3D) -> void:
	priority_target = frog
	target = frog
	if state in ["suit", "combat"]:
		_charge_cd = 0.0
	say("avale", true)


func on_enter_dungeon() -> void:
	say("donjon")


func is_busy() -> bool:
	return state in ["sort", "prie", "assis", "chute", "charge"]


## Au revoir : une dernière réplique, il s'éloigne quelques pas, puis disparaît.
func leave() -> void:
	say("congedier", true)
	state = "depart"
	_t = 2.6
	target = null


# =================================================================== paroles

static func _all_texts() -> Dictionary:
	if _textes_loaded:
		return _textes_cache
	_textes_loaded = true
	if ResourceLoader.exists(TEXTES_PATH):
		var scr: Script = load(TEXTES_PATH)
		if scr != null:
			var cm: Dictionary = scr.get_script_constant_map()
			if cm.has("TEXTES") and cm["TEXTES"] is Dictionary:
				_textes_cache = cm["TEXTES"]
	return _textes_cache


## Les répliques d'une clé (tableau de chaînes, ou de petits échanges [qui, texte]).
func lines(key: String) -> Array:
	var all: Dictionary = _all_texts()
	var mine: Variant = all.get(id, {})
	if mine is Dictionary and (mine as Dictionary).has(key):
		var v: Variant = (mine as Dictionary)[key]
		if v is Array and not (v as Array).is_empty():
			return v
		if v is String and str(v) != "":
			return [v]
	var fb: Dictionary = FALLBACK.get(id, {})
	return fb.get(key, [])


## Dit une réplique de la clé (bulle au-dessus de la tête), si ce n'est pas trop tôt.
func say(key: String, force: bool = false) -> bool:
	if not force:
		if _say_cd > 0.0 or float(_key_cd.get(key, 0.0)) > 0.0:
			return false
		if mgr != null and mgr.has_method("can_speak") and not bool(mgr.can_speak()):
			return false
	var arr: Array = lines(key)
	if arr.is_empty():
		return false
	var e: Variant = arr[_rng.randi() % arr.size()]
	var text: String = ""
	if e is String:
		text = e
	elif e is Array and not (e as Array).is_empty():
		var ea: Array = e
		if ea.size() >= 2 and ea[0] is String and ea[1] is String:
			text = ea[1]                      # [qui, réplique]
		else:
			var first: Variant = ea[0]
			text = str(first[1]) if first is Array and (first as Array).size() > 1 else str(first)
	elif e is Dictionary:
		text = str((e as Dictionary).get("texte", (e as Dictionary).get("text", "")))
	if text == "":
		return false
	_key_cd[key] = float(KEY_CD.get(key, 12.0))
	say_text(text)
	return true


func say_text(text: String, seconds: float = -1.0) -> void:
	if bubble == null:
		return
	text = text.replace("{joueur}", "toi")
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	_bubble_t = seconds if seconds > 0.0 else clampf(1.8 + text.length() * 0.055, 3.0, 8.0)
	_say_cd = 5.0
	if mgr != null and mgr.has_method("note_spoke"):
		mgr.note_spoke()
	spoke.emit(id, text)


func _bubble_tick(delta: float) -> void:
	if _bubble_t > 0.0 and bubble != null:
		_bubble_t -= delta
		bubble.modulate.a = clampf(_bubble_t, 0.0, 1.0)
		if _bubble_t <= 0.0:
			bubble.visible = false


func _sfx(snd: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(snd, at)

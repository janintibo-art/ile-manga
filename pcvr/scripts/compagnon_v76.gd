extends Node3D
## V76 : UN compagnon animal (créé et piloté par compagnons_animaux_v76.gd). Généralise Sardine,
## le chien de la V75 (chien_v75.gd) à quatre espèces :
##  - SARDINE, le chien : il suit, mord les robots et les champignards, aboie aux monstres,
##    rapporte parfois une pièce (comme en V75) ;
##  - BRIOCHE, la chatte : très digne ; « flair du trésor » (un coffre caché ou une cachette à
##    creuser à moins de ~40 m : elle s'arrête, fixe la direction et miaule) ; elle chasse les
##    papillons ;
##  - BISCOTTE, le rat : sur l'épaule du héros quand il ne court pas, au sol quand il court ;
##    de temps en temps il file dans un trou et rapporte un petit trésor ;
##  - TRUFFE, le cochon : dans l'herbe et les bois, il renifle, creuse et déterre des truffes
##    (et parfois un objet enfoui).
## Tous : ils se téléportent près du joueur quand il est loin, attendent au bord de l'eau (en
## bateau, ils montent DEDANS, assis à l'avant ; le rat reste sur l'épaule), dorment quand le
## joueur se repose, réagissent aux animaux de la ville, parlent avec le Babillard.
##
## Compatibilité V75 (boucan_v75.chien, evenements_v75, main.gd) : chaque compagnon garde l'API
## de chien_v75 — spawn_near_player(), despawn(), is_active(), on_faint(), set_babil(on),
## serialize() / load_data(d) (format V75 : {actif, pieces, prochaine_piece}) — qui passe par
## le gestionnaire.

const A = preload("res://scripts/animaux_v75.gd")
const PnjV31 = preload("res://scripts/pnj/pnj_v31.gd")
const SEA_Y: float = -0.42
const TELEPORT_DIST: float = 35.0
const BITE_KINDS := ["robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse", "champignard", "champignard_roi"]
const METAL_KINDS := ["robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse"]

var mgr: Node
var main: Node
var id: String = ""
var spec: Dictionary = {}
var espece: String = "chien"
var active: bool = false
var babil: bool = false
var state: String = "suit"               # suit, assis, couche, dort, attend, bateau, combat, recule, aboie,
										 # rapporte, flair, chasse, tresor, truffe, epaule, peur
var model: Node3D
var bubble: Label3D
var target: Node3D
var held: Node3D                         # ce qu'il porte dans la gueule (pièce, truffe, trésor)
var coins_given: int = 0                 # Sardine (V75)
var found_n: int = 0                     # trésors rapportés (Biscotte), truffes (Truffe), flairs (Brioche)
var on_shoulder: bool = false
var in_boat: bool = false
var leaving_t: float = -1.0              # rentre à la maison : s'éloigne, puis disparaît
var _t: float = 0.0
var _clock: float = 0.0
var _speed: float = 0.0
var _wag: float = 0.3
var _pose: String = ""
var _still_t: float = 0.0
var _last_pp: Vector3 = Vector3.INF
var _pspeed: float = 0.0                 # vitesse du joueur (lissée, m/s)
var _player_moving: bool = false
var _pick_t: float = 0.0
var _bite_cd: float = 0.0
var _bark_cd: float = 0.0
var _yelp_cd: float = 0.0
var _say_cd: float = 8.0
var _bubble_t: float = 0.0
var _ability_t: float = 180.0            # prochaine trouvaille (pièce, trésor, truffe)
var _phase: int = 0
var _goal: Vector3
var _faint_t: float = 0.0
var _load_wait: float = -1.0
var _stuck_t: float = 0.0
var _excl: Array[RID] = []
var _excl_t: float = 0.0
var _bite_anim: float = 0.0
var _narr_cd: float = 60.0
var _happy_t: float = 0.0
var _scan_t: float = 1.0
var _flair_dir: Vector3 = Vector3.ZERO
var _fly: Node3D                         # le papillon (Brioche)
var _fly_t: float = 90.0
var _fly_v: Vector3
var _hop: Dictionary = {}                # {from, to, t, T, h, end}
var _shoulder_ok_t: float = 0.0
var _animal_cd: float = 0.0
var _fear_cd: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(manager: Node, main_node: Node, pet_id: String, pet_spec: Dictionary) -> void:
	mgr = manager
	main = main_node
	id = pet_id
	spec = pet_spec
	espece = str(spec.get("espece", "chien"))
	name = str(spec.get("noeud", "Compagnon_" + id))
	_rng.randomize()
	model = A.build(espece, spec.get("variante", {}))
	add_child(model)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 32
	bubble.pixel_size = 0.0025
	bubble.outline_size = 10
	bubble.width = 560
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.no_depth_test = true
	bubble.modulate = Color(1.0, 0.93, 0.78)
	bubble.outline_modulate = Color(0.15, 0.08, 0.04)
	bubble.position = Vector3(0, float(spec.get("bulle_y", 1.0)), 0)
	bubble.visible = false
	add_child(bubble)
	held = _make_held()
	visible = false
	_ability_t = _next_ability()
	_fly_t = _rng.randf_range(60.0, 120.0)


# =================================================================== API V75 (Sardine) → gestionnaire

func is_active() -> bool:
	return active


## V75 : Sardine arrive (trouvé à la Casse, ramené à Tornade) : le gestionnaire l'adopte ou l'appelle.
func spawn_near_player() -> void:
	if mgr != null and mgr.has_method("_compat_spawn"):
		mgr._compat_spawn(id)
	else:
		_activate(true)


func despawn() -> void:
	if mgr != null and mgr.has_method("active_id") and str(mgr.active_id()) == id:
		mgr.dismiss(true)
	else:
		_deactivate(false)


func on_faint() -> void:
	if mgr != null and mgr.has_method("on_faint"):
		mgr.on_faint()
	else:
		_pet_faint()


func set_babil(on: bool) -> void:
	if mgr != null and mgr.has_method("set_babil"):
		mgr.set_babil(on)
	else:
		_set_babil(on)


## Format V75 (boucan_v75 le range sous « sardine ») : le vrai état est dans compagnons_animaux_v76.
func serialize() -> Dictionary:
	return {"actif": active, "pieces": coins_given, "prochaine_piece": _ability_t}


func load_data(d: Dictionary) -> void:
	if mgr != null and mgr.has_method("_compat_load_v75"):
		mgr._compat_load_v75(id, d)
	else:
		_restore({"pieces": d.get("pieces", 0), "t": d.get("prochaine_piece", 200.0)})
		if bool(d.get("actif", false)):
			_activate(false, true)


# =================================================================== pour le gestionnaire

func _set_babil(on: bool) -> void:
	babil = on
	if on:
		_say_cd = minf(_say_cd, 2.0)


## Le compagnon arrive à côté du joueur (adopté, appelé au sifflet, partie chargée).
func _activate(announce: bool, after_load: bool = false) -> void:
	active = true
	leaving_t = -1.0
	state = "suit"
	target = null
	_end_carry()
	_remove_fly()
	if after_load:
		visible = false
		_load_wait = 0.0
		return
	visible = true
	_load_wait = -1.0
	teleport_near_player()
	if announce:
		_happy_t = 2.0
		_cry(false)


## Rentre « à la maison » : s'éloigne en trottinant, puis disparaît (leave = false : tout de suite).
func _deactivate(leave: bool) -> void:
	active = false
	target = null
	if in_boat or state == "bateau" or not _hop.is_empty():
		# dans le bateau (ou en plein saut) : il disparaît tout de suite, dans un petit nuage
		leave = false
		var cb: Node = main.get("combat_v28") if main != null else null
		if cb != null and visible and cb.has_method("puff"):
			cb.puff(global_position + Vector3.UP * 0.3, Color(0.95, 0.92, 0.85))
	in_boat = false
	_end_carry()
	_remove_fly()
	_load_wait = -1.0
	if leave and visible and is_inside_tree():
		if on_shoulder:
			on_shoulder = false
			_hop_to(_ground_near(_player_feet() + _player_right() * 0.8), 0.4, 0.4)
		leaving_t = 3.2
		state = "rentre"
		var away: Vector3 = global_position - _player_feet()
		away.y = 0.0
		_goal = global_position + (away.normalized() if away.length() > 0.1 else -_player_forward()) * 12.0
		return
	on_shoulder = false
	_hop.clear()
	visible = false
	leaving_t = -1.0
	state = "suit"


func _pet_faint() -> void:
	if active:
		_faint_t = 1.2


func _save() -> Dictionary:
	return {"t": _ability_t, "pieces": coins_given, "trouves": found_n}


func _restore(d: Dictionary) -> void:
	coins_given = int(d.get("pieces", 0))
	found_n = int(d.get("trouves", 0))
	var t: float = float(d.get("t", _next_ability()))
	_ability_t = clampf(t, 30.0, 400.0)


func _next_ability() -> float:
	match espece:
		"rat":
			return _rng.randf_range(180.0, 360.0)          # toutes les 3 à 6 minutes
		"cochon":
			return _rng.randf_range(120.0, 240.0)          # toutes les 2 à 4 minutes
		"chien":
			return _rng.randf_range(150.0, 280.0)
	return 9999.0


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


func _player_right() -> Vector3:
	return _player_forward().cross(Vector3.UP).normalized()


func _hero_state() -> String:
	var hero: Node = main.get("hero_v28")
	if hero == null or main.xr_active:
		return "sol"
	return str(hero.get("state"))


## Le joueur est porté par autre chose que ses pieds (aigle, ferry, nage…) : on l'attend. Le bateau
## est à part (on monte dedans).
func _player_riding() -> bool:
	if main.get("ciel_v54") != null and main.ciel_v54 != null and bool(main.ciel_v54.get("riding")):
		return true
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ferry") != null and az.ferry != null and bool(az.ferry.get("riding")):
		return true
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.has_method("riding") and bool(gr.riding()):
		return true
	if _hero_state() == "nage":
		return true
	if mgr != null and mgr.has_method("player_flying") and bool(mgr.player_flying()):
		return true
	return false


func _player_sleeping() -> bool:
	var tp: Node = main.get("temps_v56")
	return tp != null and bool(tp.get("_sleeping"))


func _busy_dialogue() -> bool:
	return main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened)


# =================================================================== chaque image

func _process(delta: float) -> void:
	# le placement « collé » (épaule, bateau, saut) se fait à chaque image, après le joueur
	if main == null or not visible:
		return
	if not _hop.is_empty():
		_hop_tick(delta)
		return
	if on_shoulder:
		var xf: Transform3D = _shoulder_xf()
		global_position = xf.origin
		rotation = Vector3(0, atan2(xf.basis.z.x, xf.basis.z.z), 0)
	elif in_boat:
		var bx: Transform3D = _boat_xf()
		global_transform = bx


func _physics_process(delta: float) -> void:
	if main == null:
		return
	if not bool(main.game_started) or (main.get("game_menu") != null and main.game_menu != null and bool(main.game_menu.opened)):
		return
	_bubble_tick(delta)
	if leaving_t >= 0.0:
		_leave_tick(delta)
		return
	if not active:
		return
	var pp: Vector3 = _player_feet()
	if _load_wait >= 0.0:
		_load_wait += delta
		if _load_wait > 2.5:
			_load_wait = -1.0
			visible = true
			if mgr != null and mgr.has_method("boat_driving") and bool(mgr.boat_driving()):
				on_board_boat()
			else:
				teleport_near_player()
		return
	if _faint_t > 0.0:
		_faint_t -= delta
		if _faint_t <= 0.0:
			in_boat = false
			teleport_near_player()
	_clock += delta
	_bite_cd = maxf(_bite_cd - delta, 0.0)
	_bark_cd = maxf(_bark_cd - delta, 0.0)
	_yelp_cd = maxf(_yelp_cd - delta, 0.0)
	_say_cd = maxf(_say_cd - delta, 0.0)
	_bite_anim = maxf(_bite_anim - delta, 0.0)
	_narr_cd = maxf(_narr_cd - delta, 0.0)
	_happy_t = maxf(_happy_t - delta, 0.0)
	_animal_cd = maxf(_animal_cd - delta, 0.0)
	_fear_cd = maxf(_fear_cd - delta, 0.0)
	if _last_pp != Vector3.INF:
		var mv: float = Vector2(pp.x - _last_pp.x, pp.z - _last_pp.z).length() / maxf(delta, 0.001)
		if mv > 30.0:
			mv = 0.0                     # une téléportation, pas une course
		_pspeed = lerpf(_pspeed, mv, clampf(delta * 6.0, 0.0, 1.0))
		_player_moving = _pspeed > 0.4
	_last_pp = pp
	_still_t = 0.0 if _player_moving else _still_t + delta
	_fly_tick(delta)
	if not _hop.is_empty():
		_animate(delta)
		return
	# en bateau : assis à l'avant (le rat, lui, reste sur l'épaule)
	if in_boat:
		_speed = 0.0
		_pose = "assis" if not _player_sleeping() else "dort"
		if babil and _say_cd <= 0.0:
			say(_line("babil"))
			_say_cd = _rng.randf_range(16.0, 28.0)
		_animate(delta)
		return
	# le rat sur l'épaule
	if espece == "rat" and _shoulder_tick(delta, pp):
		_animate(delta)
		return
	var to_p: Vector3 = pp - global_position
	var flat_p: float = Vector2(to_p.x, to_p.z).length()
	if _player_riding():
		if state != "attend":
			_end_carry()
			state = "attend"
			target = null
		_face(to_p, delta, 2.0)
		_speed = 0.0
		_pose = "assis"
		_animate(delta)
		return
	if state == "attend":
		state = "suit"
	if flat_p > TELEPORT_DIST or absf(to_p.y) > 12.0:
		teleport_near_player()
		return
	_pick_t -= delta
	if _pick_t <= 0.0:
		_pick_t = 0.4
		_pick_target(pp)
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = 1.5
		_scan(pp)
	match state:
		"recule":
			_t -= delta
			var away: Vector3 = global_position - (target.global_position if _valid(target) else pp)
			_walk_dir(away, _sp("trot"), delta)
			_pose = ""
			if _t <= 0.0:
				state = "suit"
		"aboie":
			_t -= delta
			_speed = 0.0
			_pose = "aboie" if espece == "chien" else ("affut" if espece == "chat" else "")
			if _valid(target):
				_face(target.global_position - global_position, delta, 6.0)
			if _t <= 0.0:
				state = "suit"
		"regarde":
			_t -= delta
			_speed = 0.0
			_pose = "assis" if espece != "chien" else "aboie"
			if _flair_dir != Vector3.ZERO:
				_face(_flair_dir, delta, 5.0)
			if _t <= 0.0:
				state = "suit"
		"flair":
			_flair_tick(delta)
		"chasse":
			_hunt_tick(delta)
		"rapporte", "tresor", "truffe":
			_carry_tick(delta, pp)
		"peur":
			_t -= delta
			_follow(delta, pp, true)
			if _t <= 0.0:
				state = "suit"
		_:
			if target != null and _valid(target):
				_fight(delta, pp)
			else:
				target = null
				if state == "combat":
					state = "suit"
				_follow(delta, pp)
				_ability_tick(delta, pp)
				if babil and _say_cd <= 0.0 and flat_p < 8.0:
					say(_line("babil"))
					_say_cd = _rng.randf_range(14.0, 24.0)
	_animate(delta)


func _sp(kind: String) -> float:
	var v: Array = spec.get("vitesses", [1.5, 3.4, 6.2])
	match kind:
		"pas":
			return float(v[0])
		"trot":
			return float(v[1])
	return float(v[2])


func _animate(delta: float) -> void:
	var wag_goal: float = 0.35
	if state in ["combat", "aboie"]:
		wag_goal = 0.5
	elif state in ["recule", "peur"]:
		wag_goal = 0.0
	elif _happy_t > 0.0:
		wag_goal = 1.0
	elif _speed < 0.2 and global_position.distance_to(_player_feet()) < 3.0:
		wag_goal = 0.9
	elif _pose in ["couche", "dort"]:
		wag_goal = 0.15
	_wag = lerpf(_wag, wag_goal, clampf(delta * 3.0, 0.0, 1.0))
	var pose: String = _pose
	if _happy_t > 0.0 and _speed < 0.2 and pose in ["", "assis"] and espece != "chat":
		pose = "content"
	if on_shoulder:
		pose = "epaule" if not _player_sleeping() else "dort"
	A.animate(model, _clock, _speed, pose, _wag, delta)
	if _bite_anim > 0.0:
		var rig: Dictionary = model.get_meta("rig", {})
		var jaw: Node3D = rig.get("jaw")
		if jaw != null:
			jaw.rotation.x = 0.5 * sin((0.35 - _bite_anim) / 0.35 * PI)


# =================================================================== suivre

func _follow(delta: float, pp: Vector3, close: bool = false) -> void:
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var off: Array = spec.get("place", [1.1, 1.3])
	var goal: Vector3 = pp + right * float(off[0]) - f * float(off[1])
	if close:
		goal = pp - f * 0.9 + right * 0.3
	var to_g: Vector3 = goal - global_position
	to_g.y = 0.0
	var d: float = to_g.length()
	if d > 0.6:
		var sp: float = _sp("pas") if d < 2.5 else (_sp("trot") if d < 8.0 else _sp("course"))
		if _player_moving and d > 1.5:
			sp = maxf(sp, _sp("trot"))
		if _pspeed > _sp("trot") and d > 3.0:
			sp = _sp("course")
		var ok: bool = _walk_dir(to_g / d, sp, delta)
		_stuck(delta, ok, d)
		_pose = ""
		if state in ["assis", "couche", "dort"]:
			state = "suit"
	else:
		_speed = 0.0
		_stuck_t = 0.0
		_face(pp - global_position if (pp - global_position).length() < 5.0 else f, delta, 3.0)
		_snap_ground()
		var lie_t: float = float(spec.get("couche_apres", 20.0))
		if _player_sleeping() or _still_t > 70.0:
			state = "dort"
			_pose = "dort"
		elif _still_t > lie_t:
			state = "couche"
			_pose = "couche"
			if _still_t > lie_t + 6.0 and _narr_cd <= 0.0:
				_narrate("content")
		elif _still_t > 2.5:
			state = "assis"
			_pose = "assis"
		else:
			_pose = ""
		if state == "dort" and babil and _say_cd <= 0.0:
			say("Zzz… " + _line("dort"))
			_say_cd = _rng.randf_range(20.0, 35.0)


func _stuck(delta: float, moved: bool, d: float) -> void:
	if moved:
		_stuck_t = maxf(_stuck_t - delta, 0.0)
		return
	_stuck_t += delta
	if _stuck_t > 3.0 and d > 5.0:
		_stuck_t = 0.0
		teleport_near_player()


## Un pas (contourne un mur, ne monte pas les murs, ne va pas dans l'eau profonde).
func _walk_dir(dir: Vector3, sp: float, delta: float) -> bool:
	dir.y = 0.0
	if dir.length() < 0.01:
		return false
	dir = dir.normalized()
	for turn in [0.0, 0.7, -0.7, 1.3, -1.3]:
		var dd: Vector3 = dir.rotated(Vector3.UP, turn)
		if _try_step(dd, sp * (1.0 if turn == 0.0 else 0.8), delta):
			_speed = sp
			_face(dd, delta, 9.0)
			return true
	_speed = 0.0
	return false


func _try_step(dir: Vector3, sp: float, delta: float) -> bool:
	var from: Vector3 = global_position
	var to: Vector3 = from + dir * sp * delta
	var space := get_world_3d().direct_space_state
	_refresh_excl()
	var h: float = float(spec.get("hauteur_rayon", 0.35))
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * h, from + Vector3.UP * h + dir * 0.5, 1, _excl)
	if not space.intersect_ray(q).is_empty():
		return false
	var gy: float = _ground_y(to, from.y)
	if gy < -1e8:
		return false
	if gy - from.y > 0.55 or from.y - gy > 2.5:
		return false
	if _deep_water(Vector3(to.x, gy, to.z)):
		return false
	global_position = Vector3(to.x, gy, to.z)
	return true


func _ground_hit(at: Vector3, ref_y: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, ref_y + 1.0, at.z), Vector3(at.x, ref_y - 3.5, at.z), 1, _excl)
	return space.intersect_ray(q)


func _ground_y(at: Vector3, ref_y: float) -> float:
	var hit := _ground_hit(at, ref_y)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	if ref_y > -40.0 and main.has_method("_height_at"):
		var g: float = float(main._height_at(at.x, at.z))
		if absf(g - ref_y) < 1.5:
			return g
	return -1e9


func _ground_near(p: Vector3) -> Vector3:
	var gy: float = _ground_y(p, p.y + 0.5) if is_inside_tree() else p.y
	return Vector3(p.x, gy if gy > -1e8 else p.y, p.z)


func _deep_water(p: Vector3) -> bool:
	if p.y < -40.0:
		return false
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("atl") != null and mer.atl != null and mer.atl.has_method("in_dome") and mer.atl.in_dome(p + Vector3.UP):
		return false
	return SEA_Y - p.y > 0.4


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
		if b != null and is_instance_valid(b) and b is CollisionObject3D:
			_excl.append((b as CollisionObject3D).get_rid())
	for r in PnjV31._npc_bodies:
		_excl.append(r)
	var ms: Node = main.get("monstres_v36")
	if ms != null:
		for m in ms.monsters:
			if is_instance_valid(m) and m is CollisionObject3D and (m as Node3D).global_position.distance_to(global_position) < 12.0:
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
	_hop.clear()
	var pp: Vector3 = _player_feet()
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var off: Array = spec.get("place", [1.1, 1.3])
	var cands: Array = [pp + right * float(off[0]) - f * float(off[1]), pp - f * 1.5, pp + right * 1.3, pp - right * 1.3, pp + f * 1.4, pp - f * 0.8 + right * 0.6]
	_excl_t = 0.0
	if is_inside_tree():
		_refresh_excl()
	var placed: bool = false
	for c in cands:
		var cv: Vector3 = c
		var gy: float = _ground_y(cv, pp.y + 0.5) if is_inside_tree() else pp.y
		if gy > -1e8 and absf(gy - pp.y) < 1.6 and not _deep_water(Vector3(cv.x, gy, cv.z)):
			global_position = Vector3(cv.x, gy, cv.z)
			placed = true
			break
	if not placed:
		global_position = pp - f * 0.7
	rotation = Vector3(0, atan2(f.x, f.z), 0)
	_stuck_t = 0.0
	target = null
	if state in ["attend", "combat", "recule", "aboie", "regarde", "flair", "chasse", "peur", "bateau", "epaule"]:
		state = "suit"
	on_shoulder = false
	if state in ["rapporte", "tresor", "truffe"]:
		# il avait trouvé quelque chose : il le rapporte quand même
		_finish_carry(_phase >= 2)
	_remove_fly()
	var cb: Node = main.get("combat_v28")
	if cb != null and visible and cb.has_method("puff"):
		cb.puff(global_position + Vector3.UP * 0.3, Color(0.95, 0.92, 0.85))


# =================================================================== le bateau

## Monte dans le bateau (assis à l'avant ; le rat reste sur l'épaule).
func on_board_boat() -> void:
	if not active:
		return
	_end_carry()
	_remove_fly()
	target = null
	if espece == "rat" and on_shoulder:
		return
	on_shoulder = false
	var bx: Transform3D = _boat_xf()
	if visible and global_position.distance_to(bx.origin) < 25.0 and is_inside_tree():
		_hop_to(bx.origin, 0.55, 0.9, "bateau")
	else:
		in_boat = true
		global_transform = bx
		visible = true
	state = "bateau"
	_cry(false)


## Débarque : saute sur la rive à côté du joueur.
func on_leave_boat() -> void:
	if not in_boat and state != "bateau":
		return
	in_boat = false
	state = "suit"
	if not active or not visible:
		return
	var from: Vector3 = global_position
	teleport_near_player()
	var to: Vector3 = global_position
	global_position = from
	_hop_to(to, 0.55, 0.9)


func _boat_xf() -> Transform3D:
	var b: Node = main.get("boat_v29")
	if b == null or b.get("hull") == null:
		return global_transform
	var hull: Node3D = b.hull
	var local: Vector3 = spec.get("bateau", Vector3(0, 0.13, -1.35))
	# un bateau amélioré (chantier naval) peut dire où s'assoit le compagnon
	if b.has_method("pet_seat_local"):
		var v: Variant = b.pet_seat_local(espece)
		if v is Vector3:
			local = v
	var xf: Transform3D = hull.global_transform * Transform3D(Basis(Vector3.UP, PI), local)
	# on garde l'animal droit (le bateau tangue, lui s'agrippe)
	var yaw: float = atan2(xf.basis.z.x, xf.basis.z.z)
	return Transform3D(Basis(Vector3.UP, yaw), xf.origin)


# =================================================================== les sauts (bateau, épaule)

func _hop_to(to: Vector3, dur: float, h: float, end_state: String = "") -> void:
	_hop = {"from": global_position, "to": to, "t": 0.0, "T": dur, "h": h, "end": end_state, "to_shoulder": false}


func _hop_tick(delta: float) -> void:
	_hop["t"] = float(_hop["t"]) + delta
	var u: float = clampf(float(_hop["t"]) / float(_hop["T"]), 0.0, 1.0)
	var to: Vector3 = _hop["to"]
	if bool(_hop["to_shoulder"]):
		to = _shoulder_xf().origin
	elif str(_hop["end"]) == "bateau":
		to = _boat_xf().origin
	var p: Vector3 = (_hop["from"] as Vector3).lerp(to, u)
	p.y += sin(u * PI) * float(_hop["h"])
	var d: Vector3 = to - (_hop["from"] as Vector3)
	global_position = p
	_face(d, delta, 12.0)
	_speed = 2.0
	if u >= 1.0:
		var end: String = str(_hop["end"])
		var sh: bool = bool(_hop["to_shoulder"])
		_hop.clear()
		_speed = 0.0
		if end == "bateau":
			in_boat = true
			state = "bateau"
		if sh:
			on_shoulder = true
			state = "epaule"


# =================================================================== le rat sur l'épaule

## Vrai si le rat est (ou monte) sur l'épaule : le reste de la logique au sol est sauté.
func _shoulder_tick(delta: float, pp: Vector3) -> bool:
	if state in ["tresor"]:
		return false
	var hs: String = _hero_state()
	var running: bool = _pspeed > 3.9 or hs in ["roulade", "escalade", "hisser", "ko", "nage"]
	var calm: bool = _pspeed < 3.5 and hs in ["sol", "attaque", "action", "air"]
	if on_shoulder:
		var boat: bool = mgr != null and mgr.has_method("boat_driving") and bool(mgr.boat_driving())
		if running or (_player_riding() and not boat):
			# il saute à terre et court à côté
			on_shoulder = false
			_shoulder_ok_t = 0.0
			state = "suit"
			var f: Vector3 = _player_forward()
			var to: Vector3 = _ground_near(pp + _player_right() * 0.6 - f * 0.4)
			_hop_to(to, 0.3, 0.3)
			return true
		_speed = 0.0
		_pose = "epaule"
		_ability_tick(delta, pp)
		if babil and _say_cd <= 0.0:
			say(_line("babil"))
			_say_cd = _rng.randf_range(14.0, 24.0)
		return true
	if state in ["suit", "assis", "couche", "dort"] and calm:
		_shoulder_ok_t += delta
		var near: bool = global_position.distance_to(pp) < 3.0
		if _shoulder_ok_t > 0.8 and near:
			# hop : il grimpe sur l'épaule
			_hop = {"from": global_position, "to": pp, "t": 0.0, "T": 0.45, "h": 0.5, "end": "", "to_shoulder": true}
			state = "epaule"
			return true
	else:
		_shoulder_ok_t = 0.0
	return false


## L'épaule gauche du héros (PC : l'os du squelette ; VR : sous la caméra, à gauche).
func _shoulder_xf() -> Transform3D:
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var yaw_b := Basis(Vector3.UP, atan2(f.x, f.z))
	if main.xr_active:
		var cam: Node3D = main.get("xr_camera")
		if cam != null:
			return Transform3D(yaw_b, cam.global_position - right * 0.2 + Vector3.DOWN * 0.24 - f * 0.04)
	var hero: Node = main.get("hero_v28")
	if hero != null and hero.get("skel") != null:
		var sk: Skeleton3D = hero.skel
		var b1: int = sk.find_bone("LeftShoulder")
		var b2: int = sk.find_bone("LeftArm")
		if b1 >= 0 and b2 >= 0:
			var p1: Vector3 = sk.global_transform * sk.get_bone_global_pose(b1).origin
			var p2: Vector3 = sk.global_transform * sk.get_bone_global_pose(b2).origin
			# sur le haut de l'épaule, côté bras (la tête du héros est grosse)
			var out: Vector3 = p2 - p1
			out.y = 0.0
			var top: Vector3 = p2 + (out.normalized() * 0.03 if out.length() > 0.001 else Vector3.ZERO)
			return Transform3D(yaw_b, top + Vector3.UP * float(spec.get("epaule_h", 0.06)) - f * 0.02)
	return Transform3D(yaw_b, _player_feet() + Vector3.UP * 1.42 - right * 0.17)


# =================================================================== rentrer à la maison

func _leave_tick(delta: float) -> void:
	leaving_t -= delta
	_clock += delta
	if _hop.is_empty():
		var to: Vector3 = _goal - global_position
		to.y = 0.0
		if to.length() > 0.5:
			_walk_dir(to, _sp("trot"), delta)
		else:
			_speed = 0.0
		_pose = ""
	A.animate(model, _clock, _speed, "", 0.6, delta)
	if leaving_t <= 0.0:
		leaving_t = -1.0
		var cb: Node = main.get("combat_v28")
		if cb != null and visible and cb.has_method("puff"):
			cb.puff(global_position + Vector3.UP * 0.3, Color(0.95, 0.92, 0.85))
		visible = false
		state = "suit"


# =================================================================== les monstres

func _valid(m: Variant) -> bool:
	if m == null or not is_instance_valid(m):
		return false
	var n: Node3D = m as Node3D
	if n == null or not n.is_inside_tree() or not n.visible:
		return false
	if str(n.get("state")) in ["mort", "rendu", "dort"] or str(n.get("kind")) == "navet" or n.get("asleep") == true:
		return false
	if n.has_method("is_hittable") and not bool(n.is_hittable()):
		return false
	return true


func _pick_target(pp: Vector3) -> void:
	if state in ["rapporte", "tresor", "truffe", "recule", "flair", "chasse", "regarde"]:
		return
	if target != null and not _valid(target):
		target = null
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		target = null
		return
	var best: Node3D = null
	var best_d: float = INF
	for m in ms.monsters:
		if not _valid(m):
			continue
		var n: Node3D = m
		var dp: Vector3 = n.global_position - pp
		if Vector2(dp.x, dp.z).length() > 10.0 or absf(dp.y) > 4.0:
			continue
		var dm: float = n.global_position.distance_to(global_position)
		if dm > 18.0:
			continue
		if dm < best_d:
			best_d = dm
			best = n
	if espece != "chien":
		# les autres ne se battent pas : le chat feule, le cochon couine et se cache derrière toi
		if best != null and _fear_cd <= 0.0 and best_d < 9.0:
			_fear_cd = 12.0
			var cb: Node = main.get("combat_v28")
			match espece:
				"chat":
					if cb != null:
						cb.float_text(global_position + Vector3.UP * 0.6, "Fffft !", Color(1.0, 0.85, 0.6))
					_sfx("miaou", -2.0)
					state = "aboie"
					target = best
					_t = 1.4
				"cochon":
					if cb != null:
						cb.float_text(global_position + Vector3.UP * 0.8, "Grouiiik !", Color(1.0, 0.75, 0.75))
					_sfx("grouik", 0.0)
					state = "peur"
					_t = 5.0
				"rat":
					if not on_shoulder:
						_sfx("couinement_rat", -3.0)
						state = "peur"
						_t = 4.0
		if state != "aboie":
			target = null
		return
	if best != null and target == null:
		_bark(true)
		if _narr_cd <= 0.0 and str(best.get("kind")) in BITE_KINDS:
			_narrate("aboie_robot")
		if babil and _rng.randf() < 0.5:
			say(["Un robot ! Je le mords ? JE LE MORDS.", "Grrr… Ça sent le boulon par ici.", "Attention ! Un truc pas net !"][_rng.randi() % 3])
	target = best
	if target != null and state in ["suit", "assis", "couche", "dort"]:
		state = "combat"


func _fight(delta: float, pp: Vector3) -> void:
	var kd: String = str(target.get("kind"))
	var tp: Vector3 = target.global_position
	var to_t: Vector3 = tp - global_position
	to_t.y = 0.0
	var d: float = to_t.length()
	_pose = ""
	var armored: bool = kd == "grande_pelleteuse" and target.has_method("weak_open") and not bool(target.weak_open())
	if not (kd in BITE_KINDS) or armored:
		# les autres monstres (et la Grande Pelleteuse blindée) : il aboie, sans quitter le joueur
		if _bark_cd <= 0.0:
			_bark(true)
			state = "aboie"
			_t = 1.0
			return
		_follow(delta, pp)
		return
	# il recule si le monstre frappe (un coup : il glapit)
	var mst: String = str(target.get("state"))
	var sp: Variant = target.get("spec")
	var reach_m: float = float((sp as Dictionary).get("portee", 1.5)) if sp is Dictionary else 1.5
	if mst in ["frappe", "balaie", "vapeur"] and d < reach_m + float(target.get("hit_radius")) + 0.4 and _yelp_cd <= 0.0:
		_yelp(kd in ["champignard", "champignard_roi"])
		return
	var reach: float = float(target.get("hit_radius")) + 0.55
	var dy: float = (tp.y + float(target.get("hit_height"))) - global_position.y
	if d > reach:
		var ok: bool = _walk_dir(to_t, _sp("course") if d > 3.0 else _sp("trot"), delta)
		_stuck(delta, ok, Vector2(pp.x - global_position.x, pp.z - global_position.z).length())
		return
	_speed = 0.0
	_face(to_t, delta, 9.0)
	_snap_ground()
	if dy > 1.4:
		# trop haut (le drone) : il aboie en dessous
		if _bark_cd <= 0.0:
			_bark(true)
		_pose = "aboie"
		return
	if _bite_cd <= 0.0:
		_bite_cd = 1.3
		_bite_anim = 0.35
		target.take_hit(2, global_position)
		if main.has_method("sfx"):
			main.sfx("touche_carapace" if kd in METAL_KINDS else "touche_chair", tp + Vector3.UP * 0.5, -6.0)
			if _rng.randf() < 0.35:
				main.sfx("aboiement", global_position + Vector3.UP * 0.5, -6.0)
		var cb: Node = main.get("combat_v28")
		if cb != null and _rng.randf() < 0.3:
			cb.float_text(global_position + Vector3.UP * 1.0, ["Grrr !", "Ouaf !", "Croc !"][_rng.randi() % 3], Color(1.0, 0.85, 0.6))


func _yelp(sneeze: bool) -> void:
	_yelp_cd = 3.0
	state = "recule"
	_t = 1.2
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(global_position + Vector3.UP * 1.0, "Atchii !" if sneeze else "Kaï !", Color(1.0, 0.9, 0.7))
	_sfx("aboiement_petit", 0.0)


func _bark(loud: bool) -> void:
	if _bark_cd > 0.0:
		return
	_bark_cd = _rng.randf_range(2.5, 4.0)
	_sfx("aboiement", 0.0 if loud else -5.0)


## Le cri de l'espèce (aboiement, miaou, couinement, groin).
func _cry(loud: bool) -> void:
	var c: Array = spec.get("cris", ["aboiement"])
	if c.is_empty():
		return
	_sfx(str(c[_rng.randi() % c.size()]), 0.0 if loud else -4.0)


func _sfx(nm: String, db: float = 0.0) -> void:
	if main != null and main.has_method("sfx") and nm != "":
		main.sfx(nm, global_position + Vector3.UP * 0.4, db)


# =================================================================== les autres animaux, le flair

## Toutes les 1,5 s : le flair du trésor (Brioche), les animaux de la ville (réactions).
func _scan(pp: Vector3) -> void:
	if not (state in ["suit", "assis", "couche"]):
		return
	if _busy_dialogue():
		return
	if espece == "chat" and mgr != null and mgr.has_method("nearest_treasure"):
		var tr: Dictionary = mgr.nearest_treasure(global_position, 40.0)
		if not tr.is_empty():
			_start_flair(tr)
			return
	if _animal_cd <= 0.0 and mgr != null and mgr.has_method("nearby_animal"):
		var an: Dictionary = mgr.nearby_animal(global_position, 6.0, espece)
		if not an.is_empty():
			_animal_cd = _rng.randf_range(25.0, 45.0)
			_react_animal(an)


func _react_animal(an: Dictionary) -> void:
	var at: Vector3 = an.get("pos", global_position)
	var esp: String = str(an.get("esp", ""))
	_flair_dir = at - global_position
	match espece:
		"chien":
			if esp == "chat":
				_bark(false)
				state = "regarde"
				_t = 1.6
				if babil:
					say(["Un CHAT ! Je fais semblant de ne pas l'avoir vu.", "Le chat me regarde. Je regarde ailleurs. C'est lui qui a commencé."][_rng.randi() % 2])
			elif esp == "chien":
				_happy_t = 1.6
				_cry(false)
		"chat":
			if esp in ["pigeon", "mouette", "rat"]:
				state = "aboie"           # à l'affût, le derrière qui frétille
				target = null
				_t = 2.0
				if babil:
					say(["Ne bouge pas, petit pigeon. Je ne fais que… regarder.", "Hmm. Un en-cas à plumes."][_rng.randi() % 2])
			elif esp == "chien":
				_sfx("miaou", -4.0)
				state = "regarde"
				_t = 1.5
				if babil:
					say("Un chien. Je l'ignore avec une grande dignité.")
		"cochon":
			_sfx("groin", -4.0)
			state = "regarde"
			_t = 1.5
			if babil and esp == "chien":
				say("Salut, le chien ! Tu as des miettes ?")
		"rat":
			if esp == "rat" and babil:
				say("Hé, cousin ! Belle moustache !")
			_sfx("couinement_rat", -6.0)


## Brioche flaire un trésor : elle s'arrête net, fixe la direction, miaule.
func _start_flair(tr: Dictionary) -> void:
	var at: Vector3 = tr.get("pos", global_position)
	_flair_dir = at - global_position
	state = "flair"
	_phase = 0
	_t = 4.0
	if mgr != null and mgr.has_method("mark_flair"):
		mgr.mark_flair(str(tr.get("key", "")))
	found_n += 1
	var dist: float = Vector2(_flair_dir.x, _flair_dir.z).length()
	var t: String = _line("flair")
	if t != "" and not ("{dir}" in t):
		t += " (Vers {le_dir}, {dist}.)"
	var dn: String = _dir_name(_flair_dir)
	t = t.replace("{le_dir}", ("l'" if dn == "ouest" else "le ") + dn).replace("{dir}", dn).replace("{dist}", _dist_text(dist)).replace("{quoi}", str(tr.get("quoi", "un trésor")))
	if t != "" and main.has_method("_show_message_v28"):
		main._show_message_v28(t)
	if mgr != null and mgr.has_method("note_flair"):
		mgr.note_flair(at, t)


func _flair_tick(delta: float) -> void:
	_t -= delta
	_speed = 0.0
	_face(_flair_dir, delta, 5.0)
	if _phase == 0 and _t < 3.2:
		_phase = 1
		_sfx("miaou", 0.0)
	if _phase == 1 and _t < 1.6:
		_phase = 2
		_sfx("miaou", -3.0)
	_pose = "miaule" if _phase == 1 else "assis"
	if _t <= 0.0:
		state = "suit"


static func _dir_name(d: Vector3) -> String:
	# -Z = le nord, +X = l'est
	var a: float = rad_to_deg(atan2(d.x, -d.z))
	var names := ["nord", "nord-est", "est", "sud-est", "sud", "sud-ouest", "ouest", "nord-ouest"]
	var i: int = int(round(fposmod(a, 360.0) / 45.0)) % 8
	return names[i]


static func _dist_text(d: float) -> String:
	if d < 12.0:
		return "tout près"
	if d < 22.0:
		return "à une quinzaine de pas"
	if d < 32.0:
		return "à une vingtaine de mètres"
	return "à une trentaine de mètres"


# =================================================================== Brioche et les papillons

func _fly_tick(delta: float) -> void:
	if espece != "chat":
		return
	if _fly != null:
		_fly_v.y += delta * 0.4
		_fly.global_position += _fly_v * delta + Vector3(sin(_clock * 7.0), sin(_clock * 11.0) * 0.6, cos(_clock * 5.0)) * delta * 0.8
		var rig: Array = _fly.get_meta("ailes", [])
		for w in rig:
			(w[0] as Node3D).rotation.z = float(w[1]) * (0.3 + absf(sin(_clock * 22.0)) * 1.1)
		_fly.rotation.y = atan2(_fly_v.x, _fly_v.z)
		if state != "chasse":
			if _fly.global_position.distance_to(global_position) > 18.0 or _fly.global_position.y - global_position.y > 6.0:
				_remove_fly()
		return
	if state != "suit" or _speed > 0.3 or _busy_dialogue() or in_boat:
		return
	_fly_t -= delta
	if _fly_t > 0.0:
		return
	_fly_t = _rng.randf_range(70.0, 150.0)
	# seulement dehors, de jour, sur l'herbe
	var tp: Node = main.get("temps_v56")
	if tp != null and tp.has_method("is_night") and bool(tp.is_night()):
		return
	if not _natural_ground(global_position):
		return
	var f: Vector3 = Vector3(sin(rotation.y), 0, cos(rotation.y))
	_spawn_fly(global_position + f * 2.2 + Vector3.UP * 0.45)
	state = "chasse"
	_phase = 0
	_t = 1.8


func _spawn_fly(at: Vector3) -> void:
	_fly = Node3D.new()
	_fly.name = "Papillon"
	var cols := [Color(1.0, 0.78, 0.15), Color(0.95, 0.95, 0.9), Color(0.45, 0.65, 1.0), Color(1.0, 0.5, 0.2)]
	var m := StandardMaterial3D.new()
	m.albedo_color = cols[_rng.randi() % cols.size()]
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.6
	var ailes: Array = []
	for sx in [-1.0, 1.0]:
		var hinge := Node3D.new()
		_fly.add_child(hinge)
		var w := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.03)
		w.mesh = q
		w.material_override = m
		w.rotation.x = -PI * 0.5
		w.position = Vector3(sx * 0.018, 0, 0)
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(w)
		ailes.append([hinge, sx])
	_fly.set_meta("ailes", ailes)
	main.add_child(_fly)
	_fly.global_position = at
	_fly_v = Vector3(_rng.randf_range(-0.3, 0.3), 0.0, _rng.randf_range(-0.3, 0.3))


func _remove_fly() -> void:
	if _fly != null and is_instance_valid(_fly):
		_fly.queue_free()
	_fly = null


func _hunt_tick(delta: float) -> void:
	_t -= delta
	if _fly == null:
		state = "suit"
		return
	var to: Vector3 = _fly.global_position - global_position
	match _phase:
		0:
			# à l'affût, le derrière qui frétille
			_speed = 0.0
			_pose = "affut"
			_face(to, delta, 5.0)
			_fly_v = Vector3(sin(_clock) * 0.15, 0.0, cos(_clock * 0.7) * 0.15)
			if _t <= 0.0:
				_phase = 1
				_t = 0.7
				if babil:
					say(["Il est à moi.", "Ne bouge pas… ne bouge… HOP !"][_rng.randi() % 2])
		1:
			# le bond !
			_pose = ""
			to.y = 0.0
			if to.length() > 0.3:
				_walk_dir(to, _sp("course"), delta)
			if _t <= 0.0:
				_phase = 2
				_t = 2.5
				_fly_v = Vector3(_rng.randf_range(-1.0, 1.0), 1.6, _rng.randf_range(-1.0, 1.0))
				_sfx("miaou", -6.0)
		2:
			# raté : elle s'assoit et fait comme si de rien n'était
			_speed = 0.0
			_pose = "assis"
			_face(to, delta, 3.0)
			if _t <= 0.0:
				if _narr_cd <= 0.0:
					_narrate("papillon")
				state = "suit"


# =================================================================== trouvailles (pièce, trésor, truffe)

func _ability_tick(delta: float, pp: Vector3) -> void:
	if espece == "chat":
		return
	_ability_t -= delta
	if _ability_t > 0.0:
		return
	if _busy_dialogue() or _player_sleeping():
		_ability_t = 20.0
		return
	match espece:
		"chien":
			_start_carry("rapporte", pp)
		"rat":
			if _pspeed > 3.5:
				_ability_t = 15.0
				return
			if on_shoulder:
				on_shoulder = false
				_hop_to(_ground_near(pp + _player_right() * 0.6), 0.3, 0.3)
			_start_carry("tresor", pp)
		"cochon":
			if not _natural_ground(global_position):
				_ability_t = 30.0
				return
			_start_carry("truffe", pp)


func _start_carry(kind: String, _pp: Vector3) -> void:
	var ang: float = _rng.randf() * TAU
	var r: float = 4.5 if kind != "tresor" else 3.0
	_goal = global_position + Vector3(cos(ang), 0, sin(ang)) * r
	state = kind
	_phase = 0
	_t = 6.0
	if kind == "truffe":
		_sfx("groin", -3.0)


func _carry_tick(delta: float, pp: Vector3) -> void:
	_t -= delta
	match _phase:
		0:
			# il va vers l'endroit (le rat file vers un trou)
			var to: Vector3 = _goal - global_position
			to.y = 0.0
			var sp: float = _sp("trot") if espece != "rat" else _sp("course") * 0.7
			if to.length() < 0.4 or _t <= 0.0 or not _walk_dir(to, sp, delta):
				_phase = 1
				_speed = 0.0
				match state:
					"rapporte":
						_t = 1.6
					"tresor":
						_t = _rng.randf_range(3.0, 5.0)
						# il disparaît dans un trou
						_puff(Color(0.45, 0.36, 0.26))
						model.visible = false
						_sfx("couinement_rat", -4.0)
					"truffe":
						_t = 2.2
			_pose = ""
		1:
			# il renifle (le chien, le cochon) ; le rat est au fond de son trou
			_speed = 0.0
			_pose = "" if state == "tresor" else "renifle"
			if _t <= 0.0:
				if state == "truffe":
					# puis le cochon creuse avec le groin
					_phase = 15
					_t = 3.0
					_sfx("creuse_cochon", 0.0)
					return
				_found()
		15:
			_speed = 0.0
			_pose = "creuse"
			if fmod(_t, 0.6) < delta:
				_puff(Color(0.4, 0.3, 0.2))
			if _t <= 0.0:
				_found()
		2:
			var to2: Vector3 = pp - global_position
			to2.y = 0.0
			_pose = ""
			if to2.length() < 1.1 or _t <= 0.0:
				_finish_carry(true)
			else:
				_walk_dir(to2, _sp("trot"), delta)


func _found() -> void:
	_phase = 2
	_t = 9.0
	held.visible = true
	_set_held_look()
	if state == "tresor":
		model.visible = true
		_puff(Color(0.45, 0.36, 0.26))
		_sfx("couinement_rat", -2.0)
	elif state == "truffe":
		_sfx("grouik", -2.0)
		_happy_t = 1.5


## Donne la trouvaille au joueur (give = false : rien, il a été interrompu tôt).
func _finish_carry(give: bool) -> void:
	var kind: String = state
	_end_carry()
	state = "suit"
	_ability_t = _next_ability()
	if not give:
		return
	if mgr != null and mgr.has_method("give_find"):
		mgr.give_find(self, kind)
	_happy_t = 2.0


func _end_carry() -> void:
	if held != null:
		held.visible = false
	if model != null:
		model.visible = true


func _make_held() -> Node3D:
	var n := MeshInstance3D.new()
	n.name = "Trouvaille"
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rig: Dictionary = model.get_meta("rig", {})
	var at: Node3D = rig.get("jaw")
	if at == null:
		at = rig.get("head")
	var off: Vector3 = Vector3(0, 0.0, 0.08)
	match espece:
		"chat":
			off = Vector3(0, -0.02, 0.06)
		"rat":
			off = Vector3(0, -0.006, 0.05)
		"cochon":
			off = Vector3(0, -0.085, 0.17)
	if at != null:
		at.add_child(n)
	else:
		add_child(n)
	n.position = off
	n.visible = false
	return n


func _set_held_look() -> void:
	var mi: MeshInstance3D = held as MeshInstance3D
	if mi == null:
		return
	var m := StandardMaterial3D.new()
	match state:
		"truffe":
			# une truffe noire, bosselée
			var sm := SphereMesh.new()
			sm.radius = 0.028
			sm.height = 0.05
			sm.radial_segments = 10
			sm.rings = 6
			mi.mesh = sm
			m.albedo_color = Color(0.16, 0.12, 0.1)
			m.roughness = 0.95
			m.normal_enabled = false
		_:
			var cm := CylinderMesh.new()
			var r: float = 0.022 if espece != "rat" else 0.012
			cm.top_radius = r
			cm.bottom_radius = r
			cm.height = 0.005
			cm.radial_segments = 14
			mi.mesh = cm
			m.albedo_color = Color(0.85, 0.55, 0.3) if espece == "chien" else Color(0.95, 0.78, 0.3)
			m.metallic = 1.0
			m.roughness = 0.25
			mi.rotation = Vector3(PI * 0.5, 0, 0)
	mi.material_override = m


func _puff(c: Color) -> void:
	var cb: Node = main.get("combat_v28")
	if cb != null and cb.has_method("puff"):
		cb.puff(global_position + Vector3.UP * 0.1 + Vector3(sin(rotation.y), 0, cos(rotation.y)) * 0.25 * float(spec.get("taille_m", 0.5)), c)


## Le sol naturel (l'herbe, les bois) : le terrain d'une île (« Sol_… »), pas la plage ni la ville.
func _natural_ground(p: Vector3) -> bool:
	if not is_inside_tree():
		return false
	_refresh_excl()
	var hit := _ground_hit(p, p.y + 0.5)
	if hit.is_empty():
		return false
	if (hit.normal as Vector3).y < 0.8:
		return false
	var c: Object = hit.get("collider")
	if c == null or not (c is Node) or not str((c as Node).name).begins_with("Sol_"):
		return false
	if float((hit.position as Vector3).y) < SEA_Y + 1.4:
		return false                      # la plage
	if mgr != null and mgr.has_method("in_town") and bool(mgr.in_town(p)):
		return false
	return true


# =================================================================== paroles

func _line(key: String) -> String:
	if mgr != null and mgr.has_method("line"):
		return str(mgr.line(id, key))
	return ""


## Une phrase de narration (le message en bas de l'écran).
func _narrate(key: String) -> void:
	_narr_cd = 150.0
	var t: String = _line(key)
	if t != "" and main.has_method("_show_message_v28"):
		main._show_message_v28(t)


func say(text: String, seconds: float = -1.0) -> void:
	if bubble == null or text == "":
		return
	bubble.text = text.replace("{joueur}", "toi")
	bubble.position = Vector3(0, float(spec.get("bulle_y", 1.0)) * (0.55 if _pose in ["couche", "dort"] else 1.0), 0)
	bubble.visible = true
	bubble.modulate.a = 1.0
	_bubble_t = seconds if seconds > 0.0 else clampf(1.8 + text.length() * 0.055, 3.0, 7.0)


func _bubble_tick(delta: float) -> void:
	if _bubble_t > 0.0:
		_bubble_t -= delta
		bubble.modulate.a = clampf(_bubble_t, 0.0, 1.0)
		if _bubble_t <= 0.0:
			bubble.visible = false

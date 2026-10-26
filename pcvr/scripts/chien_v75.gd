extends Node3D
## V75 : SARDINE, le chien compagnon (après la quête « Où est Sardine ? »). Un bâtard joyeux,
## taille moyenne, poil hirsute brun clair à taches blanches, un bandana rouge, une oreille
## dressée et l'autre qui tombe. Il suit le joueur partout (comme les compagnons de Montjoie) :
## au pas, au trot, au galop ; il réapparaît à côté du joueur quand celui-ci est trop loin
## (35 m), change d'étage, se téléporte ; il attend sur la rive quand le joueur prend la barque.
## Il aboie aux monstres et MORD les robots et les champignards près du joueur (il ne meurt
## jamais : un coup, et il glapit et recule). De temps en temps, il « rapporte une pièce ».
## Il s'assoit quand le joueur ne bouge plus, se couche s'il attend longtemps, remue la queue.
## Avec le Babillard, il parle (boucan_textes_v75.gd : ANIMAUX["sardine"]).
##
## API :
##   setup(main_node)  spawn_near_player()  despawn()  is_active() -> bool  set_babil(on)
##   on_faint()        serialize() -> Dictionary      load_data(d)
##   static build_model(variant := {}) -> Node3D      (le modèle de Sardine, animaux_v75.gd)

const A = preload("res://scripts/animaux_v75.gd")
const PnjV31 = preload("res://scripts/pnj/pnj_v31.gd")
const TEXTES_PATH := "res://scripts/pnj/boucan_textes_v75.gd"
const SEA_Y: float = -0.42
const TELEPORT_DIST: float = 35.0
const WALK: float = 1.5
const TROT: float = 3.4
const RUN: float = 6.2
const BITE_KINDS := ["robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse", "champignard", "champignard_roi"]
const SARDINE := {"taille": 0.95, "base": Color(0.6, 0.43, 0.26), "tache": Color(0.93, 0.9, 0.84), "taches": 0.3, "taches_f": 4.5,
	"ventre": Color(0.93, 0.9, 0.84), "museau_c": Color(0.93, 0.9, 0.84), "museau_k": 0.75, "oreilles": "mixte", "queue": "courbe",
	"hirsute": 0.7, "bandana": Color(0.8, 0.08, 0.06), "museau": 1.0, "pattes": 0.95, "seed": 21}
const FALLBACK := {
	"sardine": ["Tu es mon humain préféré. Enfin, après Tornade. Et après le vendeur de saucisses.", "On court ? On court ! ON COURT !",
		"Ce robot sent le boulon. Je peux le mordre ? Dis oui.", "J'ai trouvé un bâton. Il est à toi. Non, à moi. Non, à toi.",
		"Je garde. Je garde tout. Même toi.", "Les champignards, ça me fait éternuer. Atchii !"],
	"rapporte": ["Sardine revient en trottinant, une pièce dans la gueule, très fier de lui.", "Sardine a déterré quelque chose… Une pièce ! Il la dépose à tes pieds.",
		"Sardine pose une pièce un peu baveuse à tes pieds et attend des compliments."],
}

static var _textes: Dictionary = {}
static var _textes_loaded: bool = false

var main: Node
var active: bool = false
var babil: bool = false
var state: String = "suit"               # suit, assis, couche, attend, combat, recule, rapporte, aboie, renifle
var model: Node3D
var bubble: Label3D
var target: Node3D
var coins_given: int = 0
var _t: float = 0.0
var _clock: float = 0.0
var _speed: float = 0.0
var _wag: float = 0.3
var _still_t: float = 0.0
var _last_pp: Vector3 = Vector3.INF
var _player_moving: bool = false
var _pick_t: float = 0.0
var _bite_cd: float = 0.0
var _bark_cd: float = 0.0
var _yelp_cd: float = 0.0
var _say_cd: float = 8.0
var _bubble_t: float = 0.0
var _coin_t: float = 180.0
var _coin_phase: int = 0
var _coin_goal: Vector3
var _coin_node: Node3D
var _faint_t: float = 0.0
var _load_wait: float = -1.0
var _stuck_t: float = 0.0
var _excl: Array[RID] = []
var _excl_t: float = 0.0
var _pose: String = ""
var _bite_anim: float = 0.0
var _narr_cd: float = 60.0
var _rng := RandomNumberGenerator.new()


## Le modèle de Sardine (ou d'un autre chien, en passant une variante).
static func build_model(variant: Dictionary = {}) -> Node3D:
	var v: Dictionary = SARDINE.duplicate()
	for k in variant:
		v[k] = variant[k]
	return A.build("chien", v)


func setup(main_node: Node) -> void:
	main = main_node
	name = "Sardine_v75"
	_rng.randomize()
	model = build_model()
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
	bubble.position = Vector3(0, 1.05, 0)
	bubble.visible = false
	add_child(bubble)
	# la pièce dans la gueule (quand il rapporte)
	_coin_node = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.022
	cm.height = 0.005
	cm.radial_segments = 14
	(_coin_node as MeshInstance3D).mesh = cm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.55, 0.3)
	gm.metallic = 1.0
	gm.roughness = 0.25
	(_coin_node as MeshInstance3D).material_override = gm
	var rig: Dictionary = model.get_meta("rig", {})
	var jaw: Node3D = rig.get("jaw")
	if jaw != null:
		jaw.add_child(_coin_node)
		_coin_node.position = Vector3(0, 0.0, 0.08)
		_coin_node.rotation = Vector3(PI * 0.5, 0, 0)
	_coin_node.visible = false
	visible = false
	_coin_t = _rng.randf_range(150.0, 260.0)


func is_active() -> bool:
	return active


func set_babil(on: bool) -> void:
	babil = on
	if on:
		_say_cd = minf(_say_cd, 2.0)


## Sardine arrive (fin de la quête, ou partie chargée) : à côté du joueur.
func spawn_near_player() -> void:
	active = true
	visible = true
	state = "suit"
	target = null
	teleport_near_player()
	_bark(false)


func despawn() -> void:
	active = false
	visible = false
	target = null
	state = "suit"


## Le joueur s'est évanoui : Sardine le retrouve à son réveil.
func on_faint() -> void:
	if active:
		_faint_t = 1.2


func serialize() -> Dictionary:
	return {"actif": active, "pieces": coins_given, "prochaine_piece": _coin_t}


func load_data(d: Dictionary) -> void:
	coins_given = int(d.get("pieces", 0))
	_coin_t = clampf(float(d.get("prochaine_piece", 200.0)), 30.0, 400.0)
	if bool(d.get("actif", false)):
		active = true
		visible = false
		_load_wait = 0.0
	else:
		despawn()


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
	if main == null or not active:
		return
	if not bool(main.game_started) or (main.get("game_menu") != null and main.game_menu != null and bool(main.game_menu.opened)):
		return
	var pp: Vector3 = _player_feet()
	# une partie chargée, un réveil après évanouissement : on réapparaît près du joueur
	if _load_wait >= 0.0:
		_load_wait += delta
		if _load_wait > 2.5:
			_load_wait = -1.0
			spawn_near_player()
		return
	if _faint_t > 0.0:
		_faint_t -= delta
		if _faint_t <= 0.0:
			teleport_near_player()
	_clock += delta
	_bite_cd = maxf(_bite_cd - delta, 0.0)
	_bark_cd = maxf(_bark_cd - delta, 0.0)
	_yelp_cd = maxf(_yelp_cd - delta, 0.0)
	_say_cd = maxf(_say_cd - delta, 0.0)
	_bite_anim = maxf(_bite_anim - delta, 0.0)
	_narr_cd = maxf(_narr_cd - delta, 0.0)
	_bubble_tick(delta)
	if _last_pp != Vector3.INF:
		var mv: float = Vector2(pp.x - _last_pp.x, pp.z - _last_pp.z).length() / maxf(delta, 0.001)
		_player_moving = mv > 0.4
	_last_pp = pp
	_still_t = 0.0 if _player_moving else _still_t + delta
	var to_p: Vector3 = pp - global_position
	var flat_p: float = Vector2(to_p.x, to_p.z).length()
	if _player_riding():
		# il attend sur la rive (assis, la tête tournée vers le joueur)
		if not (state in ["attend"]):
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
	match state:
		"recule":
			_t -= delta
			var away: Vector3 = global_position - (target.global_position if _valid(target) else pp)
			_walk_dir(away, TROT, delta)
			_pose = ""
			if _t <= 0.0:
				state = "suit"
		"rapporte":
			_coin_tick(delta, pp)
		"aboie":
			_t -= delta
			_speed = 0.0
			_pose = "aboie"
			if _valid(target):
				_face(target.global_position - global_position, delta, 6.0)
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
				_coin_t -= delta
				if _coin_t <= 0.0 and state == "suit":
					_start_coin(pp)
				if babil and _say_cd <= 0.0 and flat_p < 8.0:
					say(_line("sardine"))
					_say_cd = _rng.randf_range(14.0, 24.0)
	_animate(delta)


func _animate(delta: float) -> void:
	var wag_goal: float = 0.35
	if state in ["combat", "aboie"]:
		wag_goal = 0.5
	elif state == "recule":
		wag_goal = 0.0
	elif _speed < 0.2 and global_position.distance_to(_player_feet()) < 3.0:
		wag_goal = 0.9
	elif _pose == "couche":
		wag_goal = 0.15
	_wag = lerpf(_wag, wag_goal, clampf(delta * 3.0, 0.0, 1.0))
	A.animate(model, _clock, _speed, _pose, _wag, delta)
	if _bite_anim > 0.0:
		var rig: Dictionary = model.get_meta("rig", {})
		var jaw: Node3D = rig.get("jaw")
		if jaw != null:
			jaw.rotation.x = 0.5 * sin((0.35 - _bite_anim) / 0.35 * PI)


# =================================================================== suivre

func _follow(delta: float, pp: Vector3) -> void:
	var f: Vector3 = _player_forward()
	var right: Vector3 = f.cross(Vector3.UP).normalized()
	var goal: Vector3 = pp + right * 1.1 - f * 1.3
	var to_g: Vector3 = goal - global_position
	to_g.y = 0.0
	var d: float = to_g.length()
	if d > 0.6:
		var sp: float = WALK if d < 2.5 else (TROT if d < 8.0 else RUN)
		if _player_moving and d > 1.5:
			sp = maxf(sp, TROT)
		var ok: bool = _walk_dir(to_g / d, sp, delta)
		_stuck(delta, ok, d)
		_pose = ""
		if state in ["assis", "couche"]:
			state = "suit"
	else:
		_speed = 0.0
		_stuck_t = 0.0
		_face(pp - global_position if (pp - global_position).length() < 5.0 else f, delta, 3.0)
		_snap_ground()
		# il s'assoit quand le joueur ne bouge plus, se couche s'il attend longtemps
		if _still_t > 20.0:
			state = "couche"
			_pose = "couche"
			if _still_t > 26.0 and _narr_cd <= 0.0:
				_narrate("content")
		elif _still_t > 2.5:
			state = "assis"
			_pose = "assis"
		else:
			_pose = ""


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
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.35, from + Vector3.UP * 0.35 + dir * 0.5, 1, _excl)
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


func _ground_y(at: Vector3, ref_y: float) -> float:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, ref_y + 1.0, at.z), Vector3(at.x, ref_y - 3.5, at.z), 1, _excl)
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
	var cands: Array = [pp + right * 1.1 - f * 1.3, pp - f * 1.5, pp + right * 1.3, pp - right * 1.3, pp + f * 1.4, pp - f * 0.8 + right * 0.6]
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
	rotation.y = atan2(f.x, f.z)
	_stuck_t = 0.0
	target = null
	if state in ["attend", "combat", "recule", "aboie"]:
		state = "suit"
	if state == "rapporte":
		_end_coin(false)
	var cb: Node = main.get("combat_v28")
	if cb != null and visible:
		cb.puff(global_position + Vector3.UP * 0.4, Color(0.95, 0.92, 0.85))


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
	if state in ["rapporte", "recule"]:
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
	if best != null and target == null:
		_bark(true)
		if _narr_cd <= 0.0 and str(best.get("kind")) in BITE_KINDS:
			_narrate("aboie_robot")
		if babil and _rng.randf() < 0.5:
			say(["Un robot ! Je le mords ? JE LE MORDS.", "Grrr… Ça sent le boulon par ici.", "Attention ! Un truc pas net !"][_rng.randi() % 3])
	target = best
	if target != null and state in ["suit", "assis", "couche"]:
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
	# un robot volant : il saute en aboyant, ne mord que s'il descend
	var reach: float = float(target.get("hit_radius")) + 0.55
	var dy: float = (tp.y + float(target.get("hit_height"))) - global_position.y
	if d > reach:
		var ok: bool = _walk_dir(to_t, RUN if d > 3.0 else TROT, delta)
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
			main.sfx("touche_carapace" if kd in ["robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse"] else "touche_chair", tp + Vector3.UP * 0.5, -6.0)
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
	if main.has_method("sfx"):
		main.sfx("aboiement_petit", global_position + Vector3.UP * 0.5, 0.0)


func _bark(loud: bool) -> void:
	if _bark_cd > 0.0:
		return
	_bark_cd = _rng.randf_range(2.5, 4.0)
	if main.has_method("sfx"):
		main.sfx("aboiement", global_position + Vector3.UP * 0.5, 0.0 if loud else -5.0)


# =================================================================== rapporter une pièce

func _start_coin(_pp: Vector3) -> void:
	var dlg: bool = main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened)
	if dlg:
		_coin_t = 20.0
		return
	var ang: float = _rng.randf() * TAU
	_coin_goal = global_position + Vector3(cos(ang), 0, sin(ang)) * 4.5
	state = "rapporte"
	_coin_phase = 0
	_t = 6.0


func _coin_tick(delta: float, pp: Vector3) -> void:
	_t -= delta
	match _coin_phase:
		0:
			var to: Vector3 = _coin_goal - global_position
			to.y = 0.0
			if to.length() < 0.4 or _t <= 0.0 or not _walk_dir(to, TROT, delta):
				_coin_phase = 1
				_t = 1.6
				_speed = 0.0
			_pose = ""
		1:
			# il renifle, il gratte…
			_speed = 0.0
			_pose = "renifle"
			if _t <= 0.0:
				_coin_phase = 2
				_t = 8.0
				_coin_node.visible = true
		2:
			var to2: Vector3 = pp - global_position
			to2.y = 0.0
			_pose = ""
			if to2.length() < 1.1 or _t <= 0.0:
				_end_coin(true)
			else:
				_walk_dir(to2, TROT, delta)


func _end_coin(give: bool) -> void:
	_coin_node.visible = false
	state = "suit"
	_coin_t = _rng.randf_range(150.0, 280.0)
	if not give:
		return
	var n: int = _rng.randi_range(1, 3)
	var inv: Node = main.get("inventory_v28")
	var got: int = 0
	if inv != null:
		got = int(inv.add("piece", n))
	coins_given += got
	var t: String = _line("rapporte")
	if main.has_method("_show_message_v28") and t != "":
		main._show_message_v28(t.replace("{n}", str(n)))
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(_player_feet() + Vector3.UP * 1.8, "+%d Pièce%s de cuivre" % [n, "s" if n > 1 else ""], Color(1.0, 0.9, 0.5))
	if main.has_method("sfx"):
		main.sfx("ramasse_pieces", global_position + Vector3.UP * 0.4)
	_bark(false)


# =================================================================== paroles

static func _all_texts() -> Dictionary:
	if _textes_loaded:
		return _textes
	_textes_loaded = true
	if ResourceLoader.exists(TEXTES_PATH):
		var scr: Script = load(TEXTES_PATH)
		if scr != null:
			_textes = scr.get_script_constant_map()
	return _textes


## Une réplique : « sardine » (ANIMAUX["sardine"]) ou « rapporte » (SARDINE["rapporte"]).
func _line(key: String) -> String:
	var all: Dictionary = _all_texts()
	var arr: Array = []
	var src: Variant = all.get("ANIMAUX", {}) if key == "sardine" else all.get("SARDINE", {})
	if src is Dictionary and (src as Dictionary).has(key):
		var v: Variant = (src as Dictionary)[key]
		if v is Array:
			arr = v
		elif v is String:
			arr = [v]
	if arr.is_empty():
		arr = FALLBACK.get(key, [])
	if arr.is_empty():
		return ""
	var e: Variant = arr[_rng.randi() % arr.size()]
	if e is Dictionary:
		return str((e as Dictionary).get("texte", (e as Dictionary).get("text", "")))
	if e is Array and not (e as Array).is_empty():
		return str((e as Array)[(e as Array).size() - 1])
	return str(e)


## Une phrase de narration (le message en bas de l'écran) : SARDINE["aboie_robot"], ["content"]…
func _narrate(key: String) -> void:
	_narr_cd = 150.0
	var t: String = _line(key)
	if t != "" and main.has_method("_show_message_v28"):
		main._show_message_v28(t)


func say(text: String, seconds: float = -1.0) -> void:
	if bubble == null or text == "":
		return
	bubble.text = text.replace("{joueur}", "toi")
	bubble.visible = true
	bubble.modulate.a = 1.0
	_bubble_t = seconds if seconds > 0.0 else clampf(1.8 + text.length() * 0.055, 3.0, 7.0)


func _bubble_tick(delta: float) -> void:
	if _bubble_t > 0.0:
		_bubble_t -= delta
		bubble.modulate.a = clampf(_bubble_t, 0.0, 1.0)
		if _bubble_t <= 0.0:
			bubble.visible = false

extends Node
## V71 : les compagnons d'aventure (trois au plus) : Sœur Pétronille, Violette, Sire Tancrède.
##  - recruit(id) : l'habitant (island.by_id[id]) quitte sa vie (caché, son agenda en pause) et
##    un compagnon (allie_v71.gd) prend sa place, avec son vrai corps ; si une conversation est
##    ouverte, on attend qu'elle se ferme (le compagnon apparaît là où était l'habitant).
##  - dismiss(id) : le compagnon dit au revoir et s'éloigne ; l'habitant reprend son agenda.
##  - sauvegarde : serialize() / load_data() (les compagnons reviennent à côté du joueur).
##  - on_faint() : après un évanouissement, ils réapparaissent à côté du joueur.
##  - on_player_swallowed(grenouille) : ils s'indignent et tapent la grenouille.
##  - bless(s) : la Bénédiction de Pétronille (+1 de force pendant s secondes, hero.temp_force).
## Le gestionnaire règle aussi les bavardages : une réplique de lieu (lac, forêt, ville, nuit,
## donjon) de temps en temps, des échanges entre compagnons, jamais deux bulles à la fois.

const AllieScript = preload("res://scripts/allie_v71.gd")
const MAX: int = 3
## L'Île de Montjoie : centre, et quelques lieux (repère local : W(lx, lz) = C + (lx, 0, lz)).
const C := Vector3(790, 0, 620)
const LIEUX := {"lac": [Vector2(215, 55), 75.0], "foret": [Vector2(170, -200), 95.0], "ville": [Vector2(0, -30), 165.0]}

signal recruited(id: String)
signal dismissed(id: String)

var main: Node
var island: Node
var allies: Dictionary = {}          # id -> allie_v71
var order: Array = []                # ordre de recrutement (places autour du joueur)
var _wait_spawn: Array = []          # ids recrutés en pleine conversation : on attend qu'elle se ferme
var _pending_load: Array = []
var _load_wait: float = 0.0
var _speak_t: float = 0.0
var _amb_t: float = 40.0
var _banter_t: float = 150.0
var _banter_q: Array = []            # [[id, texte], ...] : un échange en cours
var _banter_next: float = 0.0
var _bless_left: float = 0.0
var _bless_fx: CPUParticles3D
var _check_t: float = 0.0
var _was_deep: bool = false
var _faint_t: float = -1.0
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, island_node: Node) -> void:
	main = main_node
	island = island_node
	name = "Compagnons_v71"
	_rng.randomize()
	add_to_group("compagnons_v71")
	var hero: Node = main.get("hero_v28")
	if hero != null and hero.has_signal("fainted") and not hero.fainted.is_connected(on_faint):
		hero.fainted.connect(on_faint)


# =================================================================== recruter, congédier

func is_active(id: String) -> bool:
	return order.has(id)


func active_ids() -> Array:
	return order.duplicate()


func get_ally(id: String) -> Node3D:
	var a: Variant = allies.get(id, null)
	return a if a != null and is_instance_valid(a) else null


## Le compagnon le plus proche du joueur (pour lui parler), "" s'il n'y en a pas à moins de r m.
func nearest_ally(r: float = 3.0) -> String:
	var best: String = ""
	var best_d: float = r
	var pp: Vector3 = _player_feet()
	for id in order:
		var a: Node3D = get_ally(id)
		if a != null:
			var d: float = a.global_position.distance_to(pp)
			if d < best_d:
				best_d = d
				best = id
	return best


func recruit(id: String) -> bool:
	if is_active(id):
		var a: Node3D = get_ally(id)
		if a != null:
			a.say("deja", true)
		return false
	if order.size() >= MAX:
		return false
	order.append(id)
	if _dialogue_open():
		_wait_spawn.append(id)
	else:
		_spawn(id, true, true)
	recruited.emit(id)
	return true


func dismiss(id: String) -> void:
	if not is_active(id):
		return
	order.erase(id)
	_wait_spawn.erase(id)
	var a: Node3D = get_ally(id)
	allies.erase(id)
	if a != null:
		a.leave()
		get_tree().create_timer(2.7).timeout.connect(func(): _release_npc(id))
	else:
		_release_npc(id)
	_reslot()
	dismissed.emit(id)


func _npc_of(id: String) -> Node3D:
	if island == null:
		return null
	var by: Variant = island.get("by_id")
	if by is Dictionary:
		var n: Variant = (by as Dictionary).get(id, null)
		if n != null and is_instance_valid(n):
			return n
	return null


func _profile_of(id: String) -> Dictionary:
	var n: Node3D = _npc_of(id)
	if n != null and n.get("profile") is Dictionary:
		return n.get("profile")
	if island != null and island.has_method("profile_of"):
		var p: Variant = island.call("profile_of", id)
		if p is Dictionary and not (p as Dictionary).is_empty():
			return p
	return {"id": id, "nom": id.capitalize()}


func _hide_npc(n: Node3D) -> void:
	if n == null:
		return
	if n.has_method("_free_spot"):
		n.call("_free_spot")
	if n.has_method("_set_hidden"):
		n.call("_set_hidden", true)
	else:
		n.visible = false
	n.set_process(false)
	var bub: Variant = n.get("bubble")
	if bub != null:
		(bub as Node3D).visible = false


func _release_npc(id: String) -> void:
	if is_active(id):
		return
	var n: Node3D = _npc_of(id)
	if n == null:
		return
	n.set_process(true)
	if n.get("slot") != null:
		# l'agenda reprend : au prochain contrôle, il rejoint sa place (la Guilde, le Temple…)
		n.set("slot", -2)
		n.set("hidden_home", true)
		if n.has_method("_set_hidden"):
			n.call("_set_hidden", false)
	else:
		n.visible = true


func _spawn(id: String, from_npc: bool, greet: bool) -> void:
	var prof: Dictionary = _profile_of(id)
	var a: Node3D = AllieScript.new()
	add_child(a)
	a.setup(main, self, id, prof, order.find(id))
	allies[id] = a
	var n: Node3D = _npc_of(id)
	if from_npc and n != null and n.visible and n.global_position.distance_to(_player_feet()) < 30.0:
		a.global_position = n.global_position
		a.rotation.y = n.rotation.y
	else:
		a.teleport_near_player()
	_hide_npc(n)
	if greet:
		a.say("recruter", true)


func _reslot() -> void:
	for i in range(order.size()):
		var a: Node3D = get_ally(order[i])
		if a != null:
			a.slot = i


func _dialogue_open() -> bool:
	return main != null and main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened)


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return {"actifs": order.duplicate()}


func load_data(d: Dictionary) -> void:
	for id in order.duplicate():
		var a: Node3D = get_ally(id)
		if a != null:
			a.queue_free()
	allies.clear()
	var old: Array = order.duplicate()
	order.clear()
	_wait_spawn.clear()
	for id in old:
		_release_npc(id)
	_pending_load = []
	for id in d.get("actifs", []):
		if not _pending_load.has(str(id)) and _pending_load.size() < MAX:
			_pending_load.append(str(id))
	_load_wait = 0.0


## Le joueur s'est évanoui : ses compagnons le retrouvent à son réveil.
func on_faint() -> void:
	_faint_t = 0.8


func on_player_swallowed(frog: Node3D) -> void:
	var k: int = 0
	for id in order:
		var a: Node3D = get_ally(id)
		if a != null:
			if k == 0:
				a.on_player_swallowed(frog)
			else:
				get_tree().create_timer(0.9 * k).timeout.connect(func(): if is_instance_valid(a) and is_instance_valid(frog): a.on_player_swallowed(frog))
			k += 1


func on_enter_dungeon() -> void:
	var ids: Array = order.duplicate()
	if ids.is_empty():
		return
	var a: Node3D = get_ally(ids[_rng.randi() % ids.size()])
	if a != null:
		get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(a): a.on_enter_dungeon())


## La Bénédiction : +1 de force pendant « s » secondes (pas cumulable : on prolonge).
func bless(s: float) -> void:
	var hero: Node = main.get("hero_v28")
	if hero == null:
		return
	if _bless_left <= 0.0:
		hero.temp_force = int(hero.temp_force) + 1
	_bless_left = s
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(_player_feet() + Vector3.UP * 2.2, "Bénédiction : +1 de force !", Color(1.0, 0.9, 0.45))
	_bless_glow(true)


func _bless_glow(on: bool) -> void:
	var holder: Node3D = main.get("vr_body") if main.xr_active else main.get("pc_root")
	if on and _bless_fx == null and holder != null:
		_bless_fx = CPUParticles3D.new()
		_bless_fx.amount = 16
		_bless_fx.lifetime = 1.2
		_bless_fx.local_coords = false
		_bless_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_bless_fx.emission_sphere_radius = 0.45
		_bless_fx.gravity = Vector3(0, 0.6, 0)
		_bless_fx.initial_velocity_min = 0.1
		_bless_fx.initial_velocity_max = 0.3
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.07)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(1.0, 0.88, 0.45)
		if main.has_method("_soft_dot_v24"):
			m.albedo_texture = main._soft_dot_v24()
		q.material = m
		_bless_fx.mesh = q
		holder.add_child(_bless_fx)
		_bless_fx.position = Vector3(0, 1.0, 0)
	if not on and _bless_fx != null:
		if is_instance_valid(_bless_fx):
			_bless_fx.queue_free()
		_bless_fx = null


# =================================================================== bavardages

func can_speak() -> bool:
	return _speak_t <= 0.0


func note_spoke() -> void:
	_speak_t = 1.8


# =================================================================== chaque image

func _player_feet() -> Vector3:
	if main == null:
		return Vector3.ZERO
	if main.xr_active:
		if main.get("vr_body") != null and main.vr_body != null:
			return main.vr_body.global_position
		return main._player_pos_v27() + Vector3.DOWN * 1.6
	return main.pc_root.global_position


func _process(delta: float) -> void:
	if main == null:
		return
	_speak_t = maxf(_speak_t - delta, 0.0)
	if _bless_left > 0.0:
		_bless_left -= delta
		if _bless_left <= 0.0:
			var hero: Node = main.get("hero_v28")
			if hero != null:
				hero.temp_force = maxi(int(hero.temp_force) - 1, 0)
			_bless_glow(false)
	if not main.game_started:
		return
	# recrutés pendant une conversation : ils arrivent quand elle se ferme
	if not _wait_spawn.is_empty() and not _dialogue_open():
		for id in _wait_spawn.duplicate():
			_wait_spawn.erase(id)
			if is_active(id) and get_ally(id) == null:
				_spawn(id, true, true)
	# une partie chargée : ils reviennent à côté du joueur
	if not _pending_load.is_empty():
		_load_wait += delta
		var ready: bool = _load_wait > 4.0
		if island != null and island.get("by_id") is Dictionary and not (island.get("by_id") as Dictionary).is_empty():
			ready = _load_wait > 0.5
		if ready:
			for id in _pending_load:
				if not is_active(id) and order.size() < MAX:
					order.append(id)
					_spawn(id, false, false)
			_pending_load.clear()
			_reslot()
	if _faint_t > 0.0:
		_faint_t -= delta
		if _faint_t <= 0.0:
			for id in order:
				var a: Node3D = get_ally(id)
				if a != null:
					a.state = "suit"
					a.target = null
					a.teleport_near_player()
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 1.0
		for id in order.duplicate():
			if _wait_spawn.has(id):
				continue
			if get_ally(id) == null:
				_spawn(id, false, false)
				_reslot()
			# l'habitant reste caché tant qu'il nous accompagne (même si l'heure tourne)
			var n: Node3D = _npc_of(id)
			if n != null and (n.visible or n.is_processing()):
				_hide_npc(n)
		_dungeon_check()
	_chatter(delta)


func _dungeon_check() -> void:
	var p: Vector3 = _player_feet()
	var deep: bool = p.y < -40.0
	if island != null and island.has_method("in_dungeon"):
		deep = deep or bool(island.call("in_dungeon", p))
	if deep and not _was_deep:
		on_enter_dungeon()
	_was_deep = deep


func _fighting() -> bool:
	for id in order:
		var a: Node3D = get_ally(id)
		if a != null and (a.target != null or bool(a.get("_in_fight"))):
			return true
	return false


func _chatter(delta: float) -> void:
	if order.is_empty():
		return
	# un échange en cours entre compagnons
	if not _banter_q.is_empty():
		_banter_next -= delta
		if _banter_next <= 0.0:
			var e: Array = _banter_q.pop_front()
			var a: Node3D = get_ally(str(e[0]))
			if a != null:
				a.say_text(str(e[1]))
			_banter_next = clampf(1.5 + str(e[1]).length() * 0.05, 2.8, 6.0)
		return
	if _fighting() or _dialogue_open():
		return
	_amb_t -= delta
	_banter_t -= delta
	if _banter_t <= 0.0 and order.size() >= 2:
		_banter_t = _rng.randf_range(140.0, 220.0)
		_start_banter()
		return
	if _amb_t <= 0.0:
		_amb_t = _rng.randf_range(45.0, 80.0)
		var key: String = _place_key()
		if key != "":
			var a2: Node3D = get_ally(order[_rng.randi() % order.size()])
			if a2 != null:
				a2.say(key)


func _place_key() -> String:
	var p: Vector3 = _player_feet()
	var keys: Array = []
	if p.y < -40.0 or (island != null and island.has_method("in_dungeon") and bool(island.call("in_dungeon", p))):
		keys.append("donjon")
	else:
		var on_isle: bool = Vector2(p.x - C.x, p.z - C.z).length() < 380.0
		if island != null and island.has_method("contains"):
			on_isle = bool(island.call("contains", p))
		if on_isle:
			for k in LIEUX:
				var e: Array = LIEUX[k]
				var w: Vector2 = Vector2(C.x, C.z) + (e[0] as Vector2)
				if Vector2(p.x, p.z).distance_to(w) < float(e[1]):
					keys.append(k)
		var tm: Node = main.get("temps_v56")
		if tm != null and tm.has_method("is_night") and bool(tm.is_night()):
			keys.append("nuit")
	if keys.is_empty():
		return ""
	return keys[_rng.randi() % keys.size()]


## Un échange entre compagnons : « entre_eux » est une liste de [qui, réplique] ; deux entrées qui
## se suivent (0-1, 2-3…) forment un petit échange (on le joue si les deux sont là). On accepte
## aussi une simple phrase, ou une liste d'échanges [[qui, texte], …].
func _start_banter() -> void:
	var ids: Array = order.duplicate()
	ids.shuffle()
	_banter_q.clear()
	for sid in ids:
		var a: Node3D = get_ally(sid)
		if a == null:
			continue
		var arr: Array = a.lines("entre_eux")
		if arr.is_empty():
			continue
		var options: Array = []
		var pairs: bool = arr[0] is Array and (arr[0] as Array).size() >= 2 and (arr[0] as Array)[0] is String
		if pairs:
			var i: int = 0
			while i < arr.size():
				var ex: Array = []
				for j in [i, i + 1]:
					if j < arr.size() and arr[j] is Array and (arr[j] as Array).size() >= 2:
						ex.append([str(arr[j][0]), str(arr[j][1])])
				var ok: bool = not ex.is_empty()
				for e2 in ex:
					if not is_active(str(e2[0])):
						ok = false
				if ok:
					options.append(ex)
				i += 2
		else:
			for e in arr:
				if e is String:
					options.append([[sid, e]])
				elif e is Array:
					var ex2: Array = []
					for line in e:
						if line is Array and (line as Array).size() >= 2 and is_active(str(line[0])):
							ex2.append([str(line[0]), str(line[1])])
					if not ex2.is_empty():
						options.append(ex2)
		if not options.is_empty():
			_banter_q = (options[_rng.randi() % options.size()] as Array).duplicate()
			break
	_banter_next = 0.0

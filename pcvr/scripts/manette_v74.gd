extends Node
## V74 : la manette sur PC (Xbox, PlayStation, Switch Pro, 8BitDo, Steam Deck… tout ce que SDL connaît).
##
## Principe : la manette « parle clavier-souris ». Chaque bouton envoie la touche que le jeu attend
## déjà (Espace, E, Ctrl, clic…), si bien que tout le jeu — combats, nage, vol, barque, pêche,
## sorts, sceaux — marche à la manette sans toucher à chaque module. Le stick gauche, lui, est
## analogique (main.pad_move_v74()), le stick droit tourne la caméra.
##
## Dans les menus (menu du jeu, carnet, dialogues, téléportation) : un curseur doré.
## Croix directionnelle = sauter de bouton en bouton ; stick gauche = curseur libre ;
## A = cliquer ; B = retour ; stick droit = faire défiler ; LB / RB = onglets du carnet.
##
##   EN JEU                         A  sauter / monter (nage, vol)     B  roulade / descendre
##   X  frapper (maintenir : coup chargé)   Y  parler, ouvrir, ramasser
##   LB parer   RB courir (ou clic du stick gauche)   LT pouvoir du sceau   RT sort
##   Croix : haut = aigle (maintenue : l'aéronef), bas = téléportation, gauche = pouvoir suivant, droite = sort suivant
##   Start = menu   Select/View = carnet   clic du stick droit = carte

const DEAD: float = 0.22                 # zone morte des sticks
const TRIG: float = 0.45                 # gâchettes : appuyées au-delà
const CAM_SPEED: float = 2.8             # rad/s, stick droit à fond
const SYNTH_DEVICE: int = 74             # les évènements fabriqués ici (pour les reconnaître)

var main: Node
var device: int = -1                     # la manette suivie (-1 : aucune)
var active: bool = false                 # la dernière entrée venait-elle de la manette ?
var cursor_pos: Vector2 = Vector2(640, 360)
var ui_mode: bool = false

var _prev: Dictionary = {}               # bouton -> était appuyé
var _held_keys: Dictionary = {}          # Key -> true (touches maintenues par la manette)
var _mouse_held: bool = false            # clic gauche maintenu (X en jeu, A dans les menus)
var _repeat_t: float = 0.0               # répétition de la croix dans les menus
var _repeat_dir: Vector2 = Vector2.ZERO
var _scroll_t: float = 0.0
var _layer: CanvasLayer
var _cursor: Control
var _last_hp: int = -1
var _help_pad: bool = false              # le bandeau d'aide montre-t-il les boutons ?
var _help_kb: String = ""
var _sig: int = -1                       # nombre de boutons à l'écran (pour se reposer dessus)
var _sig_t: float = 0.0
var _warp_ms: int = -10000               # V77 : le dernier warp_mouse (sa propre trace est ignorée)
var _mouse_acc: float = 0.0              # V77 : la souris qui bouge pendant que la manette mène
var _up_t: float = 0.0                   # V76 : depuis quand la croix haute est maintenue
var _up_long: bool = false
var _flash: float = 0.0                  # le curseur grossit un instant quand on appuie

const BTN_A := JOY_BUTTON_A
const BTN_B := JOY_BUTTON_B
const BTN_X := JOY_BUTTON_X
const BTN_Y := JOY_BUTTON_Y


func setup(main_node: Node) -> void:
	main = main_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100               # après main : les invites « E : » sont déjà écrites
	_strip_builtin_pad_ui()
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)
	_cursor = _CursorDraw.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.visible = false
	_layer.add_child(_cursor)
	Input.joy_connection_changed.connect(_on_joy)
	_pick_device()


## Godot ajoute la manette aux actions ui_* (A = valider…) : nos boutons de menu seraient alors
## cliqués deux fois. Ici, c'est ce module seul qui traduit la manette.
func _strip_builtin_pad_ui() -> void:
	for action in InputMap.get_actions():
		if not str(action).begins_with("ui_"):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				InputMap.action_erase_event(action, ev)


func _pick_device() -> void:
	var pads: Array = Input.get_connected_joypads()
	device = int(pads[0]) if not pads.is_empty() else -1


func _on_joy(dev: int, connected: bool) -> void:
	var before: int = device
	_pick_device()
	if main == null or not main.has_method("_show_message_v28"):
		return
	if connected and dev == device and before != device:
		main._show_message_v28("Manette connectée : %s. Start : menu  •  Select : carnet" % Input.get_joy_name(dev))
	elif not connected and dev == before:
		_release_all()
		main._show_message_v28("Manette déconnectée.")


func _input(event: InputEvent) -> void:
	# Le clavier ou la souris reprend la main : le curseur doré s'efface.
	if (event is InputEventKey or event is InputEventMouseButton) and event.device != SYNTH_DEVICE and active:
		active = false
	elif event is InputEventMouseMotion and event.device != SYNTH_DEVICE:
		# V77 : le mouvement provoqué par notre propre warp_mouse ne compte pas (il arrive un peu
		# après, et en pixels de fenêtre : il ne tombe pas pile sur le curseur doré) ; quand la
		# manette mène, il faut vraiment bouger la souris (pas un frémissement) pour reprendre la main.
		if Time.get_ticks_msec() - _warp_ms < 250 or event.position.distance_to(cursor_pos) < 3.0:
			return
		if active:
			_mouse_acc += event.relative.length()
			if _mouse_acc < 40.0:
				return
			active = false
		_mouse_acc = 0.0
		cursor_pos = event.position


# =================================================================== lecture

func _btn(b: JoyButton) -> bool:
	return device >= 0 and Input.is_joy_button_pressed(device, b)


func _axis(a: JoyAxis) -> float:
	return Input.get_joy_axis(device, a) if device >= 0 else 0.0


func _stick(ax: JoyAxis, ay: JoyAxis) -> Vector2:
	var v := Vector2(_axis(ax), _axis(ay))
	var l: float = v.length()
	if l < DEAD:
		return Vector2.ZERO
	return v / l * minf((l - DEAD) / (1.0 - DEAD), 1.0)


## Les boutons « logiques » de cette image (gâchettes comprises).
func _state() -> Dictionary:
	var s := {}
	for b in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_BACK, JOY_BUTTON_START,
			JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		s[int(b)] = _btn(b)
	s["lt"] = _axis(JOY_AXIS_TRIGGER_LEFT) > TRIG
	s["rt"] = _axis(JOY_AXIS_TRIGGER_RIGHT) > TRIG
	return s


## Le déplacement analogique (stick gauche), pour le héros, la barque et l'aigle.
func move() -> Vector2:
	if device < 0 or ui_mode or main == null or main.xr_active:
		return Vector2.ZERO
	return _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)


# =================================================================== boucle

func _process(delta: float) -> void:
	if main == null:
		return
	if main.xr_active or device < 0:
		_release_all()
		_cursor.visible = false
		return
	var s: Dictionary = _state()
	var pressed: Dictionary = {}
	var any: bool = false
	for k in s:
		pressed[k] = bool(s[k]) and not bool(_prev.get(k, false))
		any = any or bool(s[k])
	var sticks: bool = _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y) != Vector2.ZERO or _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y) != Vector2.ZERO
	if any or sticks:
		active = true
	var was_ui: bool = ui_mode
	ui_mode = _ui_open()
	if ui_mode != was_ui:
		_release_all()
		if ui_mode and active:
			_snap_first()
	if ui_mode:
		_ui_tick(delta, s, pressed)
	else:
		_game_tick(delta, s, pressed)
	_prev = s
	_cursor.visible = active and ui_mode
	_cursor.position = cursor_pos
	_flash = maxf(_flash - delta, 0.0)
	_cursor.scale = Vector2.ONE * (1.0 + _flash * 3.0)
	_relabel()
	_rumble()


func _ui_open() -> bool:
	if main.game_menu != null and main.game_menu.opened:
		return true
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		return true
	if main.get("dialogue_v31") != null and main.dialogue_v31 != null and main.dialogue_v31.opened:
		return true
	return false


# =================================================================== en jeu

func _game_tick(delta: float, s: Dictionary, p: Dictionary) -> void:
	# boutons maintenus
	_hold_key(KEY_SPACE, s[int(BTN_A)])
	_hold_key(KEY_CTRL, s[int(BTN_B)])
	_hold_key(KEY_F, s[int(JOY_BUTTON_LEFT_SHOULDER)])
	_hold_key(KEY_SHIFT, s[int(JOY_BUTTON_RIGHT_SHOULDER)] or s[int(JOY_BUTTON_LEFT_STICK)])
	_hold_mouse(s[int(BTN_X)], main.get_viewport().get_visible_rect().size * 0.5)
	# appuis
	if p[int(BTN_Y)]:
		_tap(KEY_E)
	if p[int(JOY_BUTTON_START)]:
		_tap(KEY_ESCAPE)
	if p[int(JOY_BUTTON_BACK)]:
		_tap(KEY_I)
	if p[int(JOY_BUTTON_RIGHT_STICK)]:
		_tap(KEY_M)
	if p["lt"]:
		_tap(KEY_X)
	if p["rt"]:
		_tap(KEY_V)
	# V76 : croix haute brève = l'aigle (au relâchement) ; maintenue une demi-seconde = l'aéronef
	if s[int(JOY_BUTTON_DPAD_UP)]:
		_up_t += delta
		if _up_t >= 0.5 and not _up_long:
			_up_long = true
			_tap(KEY_N)
	else:
		if _up_t > 0.0 and not _up_long:
			_tap(KEY_G)
		_up_t = 0.0
		_up_long = false
	if p[int(JOY_BUTTON_DPAD_DOWN)]:
		_tap(KEY_T)
	if p[int(JOY_BUTTON_DPAD_LEFT)]:
		_next_power()
	if p[int(JOY_BUTTON_DPAD_RIGHT)]:
		_tap(KEY_B)
	# la caméra : stick droit (gauche-droite : tourner ; haut-bas : rapprocher, éloigner)
	var r: Vector2 = _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
	if r != Vector2.ZERO and main.game_started:
		main.pc_root.rotate_y(-r.x * absf(r.x) * CAM_SPEED * delta)
		var h: Node = main.get("hero_v28")
		if h != null and absf(r.y) > 0.3:
			h.cam_distance = clampf(float(h.cam_distance) + r.y * delta * 0.9, 0.45, 1.6)


## Croix gauche : le pouvoir de sceau suivant (parmi ceux qu'on possède).
func _next_power() -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null or not pr.has_method("power_owned"):
		return
	var order: Array = pr.POWER_ORDER
	var cur: int = order.find(str(pr.get("power"))) if pr.get("power") != null else -1
	for i in range(1, order.size() + 1):
		var j: int = (cur + i) % order.size()
		if pr.power_owned(str(order[j])):
			pr.handle_key([KEY_1, KEY_2, KEY_3, KEY_4][j])
			return
	main._show_message_v28("Tu n'as encore aucun pouvoir de sceau.")


# =================================================================== menus : le curseur doré

func _ui_tick(delta: float, s: Dictionary, p: Dictionary) -> void:
	var vp: Vector2 = main.get_viewport().get_visible_rect().size
	# stick gauche : curseur libre
	var l: Vector2 = _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
	if l != Vector2.ZERO:
		cursor_pos += l * pow(l.length(), 0.6) * 1050.0 * (vp.y / 720.0) * delta
		cursor_pos = cursor_pos.clamp(Vector2.ZERO, vp - Vector2.ONE)
		_motion()
	# croix : de bouton en bouton (avec répétition si on la maintient)
	var d := Vector2.ZERO
	if s[int(JOY_BUTTON_DPAD_UP)]:
		d = Vector2.UP
	elif s[int(JOY_BUTTON_DPAD_DOWN)]:
		d = Vector2.DOWN
	elif s[int(JOY_BUTTON_DPAD_LEFT)]:
		d = Vector2.LEFT
	elif s[int(JOY_BUTTON_DPAD_RIGHT)]:
		d = Vector2.RIGHT
	if d != _repeat_dir:
		_repeat_dir = d
		_repeat_t = 0.0
		if d != Vector2.ZERO:
			_snap(d)
			_repeat_t = 0.35
	elif d != Vector2.ZERO:
		_repeat_t -= delta
		if _repeat_t <= 0.0:
			_snap(d)
			_repeat_t = 0.12
	# de nouveaux boutons (les réponses d'un dialogue, une autre page) : on s'y pose
	_sig_t -= delta
	if _sig_t <= 0.0:
		_sig_t = 0.15
		var sig: int = buttons().size()
		var under: BaseButton = _button_at(cursor_pos)
		if sig != _sig and under == null:
			_snap_first()
		_sig = sig
	# A : appuyer sur le bouton visé (ailleurs : clic maintenu, pour glisser la carte)
	if p[int(BTN_A)]:
		var target: BaseButton = _button_at(cursor_pos)
		if target != null:
			target.pressed.emit()
			_flash = 0.15
		elif main.dialogue_v31 != null and main.dialogue_v31.opened:
			_tap(KEY_SPACE)          # pas de bouton visé : finir la phrase / l'unique réponse
		else:
			_hold_mouse(true, cursor_pos)
	elif not s[int(BTN_A)] and _mouse_held:
		_hold_mouse(false, cursor_pos)
	# B : retour
	if p[int(BTN_B)]:
		_back()
	if p[int(JOY_BUTTON_START)]:
		_tap(KEY_ESCAPE)
	if p[int(JOY_BUTTON_BACK)] and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	# LB / RB : onglets du carnet
	var cn: Node = main.inventory_v28.carnet if main.inventory_v28 != null and main.inventory_v28.opened else null
	if cn != null:
		if p[int(JOY_BUTTON_LEFT_SHOULDER)]:
			cn.open_tab(posmod(int(cn.current) - 1, cn.TABS.size()))
		if p[int(JOY_BUTTON_RIGHT_SHOULDER)]:
			cn.open_tab(posmod(int(cn.current) + 1, cn.TABS.size()))
	# stick droit : faire défiler
	var r: Vector2 = _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
	_scroll_t -= delta
	if absf(r.y) > 0.3 and _scroll_t <= 0.0:
		_scroll_t = lerpf(0.16, 0.04, absf(r.y))
		for down in [true, false]:
			var w := InputEventMouseButton.new()
			w.device = SYNTH_DEVICE
			w.button_index = MOUSE_BUTTON_WHEEL_DOWN if r.y > 0.0 else MOUSE_BUTTON_WHEEL_UP
			w.pressed = down
			w.position = cursor_pos
			w.global_position = cursor_pos
			Input.parse_input_event(w)


func _back() -> void:
	var gm: Node = main.game_menu
	if gm != null and gm.opened:
		if str(gm.view) != "home":
			gm._show_view("home")
			_snap_first()
		elif bool(main.game_started):
			gm._close()
		return
	_tap(KEY_ESCAPE)


## La fenêtre ouverte au premier plan (le curseur ne vise que ses boutons).
func _scope() -> Node:
	if main.game_menu != null and main.game_menu.opened:
		return main.game_menu
	if main.get("dialogue_v31") != null and main.dialogue_v31 != null and main.dialogue_v31.opened:
		return main.dialogue_v31
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		return main.inventory_v28
	return main.get_tree().root


## Les boutons visibles et cliquables de la fenêtre ouverte (menu, carnet, dialogue…).
func buttons() -> Array:
	var out: Array = []
	var vr := Rect2(Vector2.ZERO, main.get_viewport().get_visible_rect().size)
	for n in _scope().find_children("*", "BaseButton", true, false):
		var b: BaseButton = n
		if b.disabled or not b.is_visible_in_tree() or b.get_viewport() != main.get_viewport():
			continue
		if b.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		var cl: CanvasLayer = _layer_of(b)
		if cl != null and not cl.visible:
			continue
		var r: Rect2 = b.get_global_rect()
		if r.size.x < 4.0 or r.size.y < 4.0 or not vr.has_point(r.get_center()):
			continue
		out.append(b)
	return out


func _layer_of(n: Node) -> CanvasLayer:
	var p: Node = n.get_parent()
	while p != null:
		if p is CanvasLayer:
			return p
		p = p.get_parent()
	return null


func _button_at(pos: Vector2) -> BaseButton:
	for b in buttons():
		if (b as Control).get_global_rect().has_point(pos):
			return b
	return null


## Le premier bouton (en haut à gauche ; dans un dialogue : la première réponse).
func _snap_first() -> void:
	await get_tree().process_frame
	var list: Array = buttons()
	if list.is_empty():
		return
	var best: Control = null
	if main.dialogue_v31 != null and main.dialogue_v31.opened:
		for b in list:
			if main.dialogue_v31.is_ancestor_of(b) and (best == null or b.get_global_rect().position.y < best.get_global_rect().position.y):
				best = b
	if best == null and main.game_menu != null and main.game_menu.opened:
		for b in list:
			if main.game_menu.is_ancestor_of(b) and (best == null or b.get_global_rect().position.y < best.get_global_rect().position.y):
				best = b
	if best == null:
		for b in list:
			var r: Rect2 = b.get_global_rect()
			if best == null or roundf(r.position.y / 40.0) < roundf(best.get_global_rect().position.y / 40.0) or (roundf(r.position.y / 40.0) == roundf(best.get_global_rect().position.y / 40.0) and r.position.x < best.get_global_rect().position.x):
				best = b
	cursor_pos = best.get_global_rect().get_center()
	_motion()


## Le bouton le plus proche dans la direction de la croix.
func _snap(d: Vector2) -> void:
	var here: Vector2 = cursor_pos
	var best: Control = null
	var best_score: float = INF
	for b in buttons():
		var c: Vector2 = (b as Control).get_global_rect().get_center()
		var v: Vector2 = c - here
		var along: float = v.dot(d)
		if along < 8.0:
			continue
		var across: float = absf(v.dot(Vector2(-d.y, d.x)))
		var score: float = along + across * 2.2
		if score < best_score:
			best_score = score
			best = b
	if best == null:
		if _button_at(here) == null:
			_snap_first()
		return
	cursor_pos = best.get_global_rect().get_center()
	_motion()


# =================================================================== évènements fabriqués

func _motion() -> void:
	var m := InputEventMouseMotion.new()
	m.device = SYNTH_DEVICE
	m.position = cursor_pos
	m.global_position = cursor_pos
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if _mouse_held else 0
	Input.parse_input_event(m)
	# la vraie souris suit : les boutons s'éclairent au survol, et le clic tombe dans la fenêtre
	if active and DisplayServer.get_name() != "headless":
		# V77 : warp_mouse attend des pixels de fenêtre, le curseur est en pixels de la vue
		# (étirée) : on convertit, sinon la vraie souris se pose ailleurs et ramène le curseur.
		Input.warp_mouse(main.get_viewport().get_screen_transform() * cursor_pos)
		_warp_ms = Time.get_ticks_msec()
		_mouse_acc = 0.0


func _tap(k: Key) -> void:
	_send_key(k, true)
	_send_key(k, false)


func _hold_key(k: Key, down: bool) -> void:
	if down == _held_keys.has(k):
		return
	if down:
		_held_keys[k] = true
	else:
		_held_keys.erase(k)
	_send_key(k, down)


func _send_key(k: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.device = SYNTH_DEVICE
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = down
	Input.parse_input_event(ev)


func _hold_mouse(down: bool, at: Vector2) -> void:
	if down == _mouse_held:
		return
	_mouse_held = down
	var mb := InputEventMouseButton.new()
	mb.device = SYNTH_DEVICE
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = down
	mb.position = at
	mb.global_position = at
	mb.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(mb)


func _release_all() -> void:
	for k in _held_keys.keys():
		_send_key(k, false)
	_held_keys.clear()
	if _mouse_held:
		_hold_mouse(false, cursor_pos)


# =================================================================== affichage

## À la manette, les invites et l'aide parlent de ses boutons (« Y : ouvrir » au lieu de « E : ouvrir »).
func _relabel() -> void:
	var pr: Label = main.get("door_prompt_v27")
	if pr != null and active and str(pr.text).begins_with("E :"):
		pr.text = "Y :" + str(pr.text).substr(3)
	var inf: Label = main.get("info")
	if inf == null:
		return
	if active and not _help_pad:
		_help_kb = inf.text
		inf.text = help_text()
		_help_pad = true
	elif not active and _help_pad:
		if inf.text == help_text():
			inf.text = _help_kb
		_help_pad = false


func help_text() -> String:
	return "LES MONDES DE TRAVERS PC  |  MANETTE : stick gauche : marcher  •  stick droit : caméra  •  A : sauter  •  B : roulade  •  X : frapper  •  Y : parler / ouvrir\nLB : parer  •  RB : courir  •  LT : pouvoir  •  RT : sort  •  croix : aigle, téléportation, pouvoir, sort  •  Start : menu  •  Select : carnet"


## Un petit coup de vibration quand on est touché.
func _rumble() -> void:
	var h: Node = main.get("hero_v28")
	if h == null:
		return
	var hp: int = int(h.hp)
	if _last_hp >= 0 and hp < _last_hp and active and device >= 0:
		Input.start_joy_vibration(device, 0.35, 0.6, 0.18)
	_last_hp = hp


## Le curseur doré (un anneau avec une pointe), dessiné par-dessus tout.
class _CursorDraw extends Control:
	func _draw() -> void:
		var gold := Color(1.0, 0.82, 0.38)
		draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.25))
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 32, gold, 3.0, true)
		draw_circle(Vector2.ZERO, 3.0, gold)
		draw_colored_polygon(PackedVector2Array([Vector2(8, 8), Vector2(20, 13), Vector2(13, 20)]), gold)

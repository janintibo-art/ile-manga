extends Node3D
## V31 : fenêtre de dialogue, la même pour tous les personnages.
## PC : panneau en bas d'écran, texte qui s'écrit, choix à la souris ou aux touches 1 à 9 (et 0),
## Espace / E pour finir d'afficher le texte, Échap pour prendre congé.
## VR : panneau flottant près du personnage, stick droit pour choisir, gâchette pour répondre,
## bouton B pour prendre congé.

signal chosen(id: String)

const TYPE_SPEED: float = 55.0          # lettres par seconde

var opened: bool = false
var xr_mode: bool = false
var choices: Array = []
var selection: int = 0
var _layer: CanvasLayer
var _name: Label
var _mood: Label
var _text: Label
var _box: GridContainer
var _buttons: Array = []
var _typing: float = 0.0
var _vr_panel: Node3D
var _vr_text: Label3D
var _vr_neutral: bool = true
var _vr_trigger_ready: bool = false
var _vr_b_ready: bool = false
var _npc: Node3D


func setup(use_xr: bool) -> void:
	xr_mode = use_xr
	if xr_mode:
		_build_vr()
	else:
		_build_pc()


func _style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(10)
	return s


func _build_pc() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10
	_layer.visible = false
	add_child(_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -470
	panel.offset_right = 470
	panel.offset_top = -330
	panel.offset_bottom = -24
	# V33 : avec beaucoup de choix (boutique), le panneau grandit vers le haut.
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var ps := _style(Color(0.025, 0.08, 0.12, 0.93), Color(0.98, 0.76, 0.32), 16, 2)
	ps.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", ps)
	_layer.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 22)
	_name.add_theme_color_override("font_color", Color(1.0, 0.82, 0.47))
	head.add_child(_name)
	_mood = Label.new()
	_mood.add_theme_font_size_override("font_size", 15)
	_mood.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_mood)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(900, 96)
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color(0.94, 0.95, 0.92))
	col.add_child(_text)
	_box = GridContainer.new()
	_box.columns = 1
	_box.add_theme_constant_override("h_separation", 8)
	_box.add_theme_constant_override("v_separation", 4)
	col.add_child(_box)


func _build_vr() -> void:
	_vr_panel = Node3D.new()
	_vr_panel.name = "Dialogue_VR"
	_vr_panel.visible = false
	add_child(_vr_panel)
	var back := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 0.72)
	back.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.025, 0.08, 0.12, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	_vr_panel.add_child(back)
	_vr_text = Label3D.new()
	_vr_text.font_size = 32
	_vr_text.pixel_size = 0.0011
	_vr_text.width = 860
	_vr_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vr_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vr_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_vr_text.offset = Vector2(-430, 300)
	_vr_text.position = Vector3(0, 0, 0.005)
	_vr_text.no_depth_test = true
	_vr_panel.add_child(_vr_text)


func open(npc: Node3D) -> void:
	_npc = npc
	opened = true
	_vr_trigger_ready = false
	_vr_b_ready = false
	if _layer != null:
		_layer.visible = true
	if _vr_panel != null:
		_vr_panel.visible = true


func close() -> void:
	opened = false
	if _layer != null:
		_layer.visible = false
	if _vr_panel != null:
		_vr_panel.visible = false


func _mood_color(word: String) -> Color:
	if word.begins_with("rayonnant") or word.begins_with("de bonne"):
		return Color(0.55, 0.95, 0.55)
	if word.begins_with("bougon"):
		return Color(1.0, 0.65, 0.35)
	if word.begins_with("furieux"):
		return Color(1.0, 0.4, 0.35)
	return Color(0.75, 0.85, 0.95)


## Affiche une réplique et ses choix (liste de {id, label}).
func show_line(who: String, mood_word: String, text: String, new_choices: Array) -> void:
	choices = new_choices
	selection = 0
	if _layer != null:
		_name.text = who
		_mood.text = "— " + mood_word
		_mood.add_theme_color_override("font_color", _mood_color(mood_word))
		_text.text = text
		_text.visible_characters = 0
		_typing = 0.0
		for b in _buttons:
			b.queue_free()
		_buttons.clear()
		# V33 : au-delà de 5 choix, deux colonnes.
		_box.columns = 2 if choices.size() > 5 else 1
		for i in range(choices.size()):
			var b := Button.new()
			b.text = "%d.  %s" % [(i + 1) % 10, choices[i]["label"]]
			b.custom_minimum_size = Vector2(446 if _box.columns == 2 else 900, 0)
			b.clip_text = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 16)
			b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.16, 0.22, 0.9), Color(0.3, 0.42, 0.52), 8, 1))
			b.add_theme_stylebox_override("hover", _style(Color(0.1, 0.24, 0.32, 0.95), Color(1.0, 0.85, 0.45), 8, 2))
			b.pressed.connect(_pick.bind(i))
			b.visible = false
			_box.add_child(b)
			_buttons.append(b)
	if _vr_panel != null:
		_vr_text.set_meta("entete", who + "  — " + mood_word)
		_vr_text.set_meta("texte", text)
		_refresh_vr()
		_place_vr()


func _pick(i: int) -> void:
	if i < 0 or i >= choices.size():
		return
	chosen.emit(str(choices[i]["id"]))


func _process(delta: float) -> void:
	if not opened or _layer == null:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count():
		_typing += delta * TYPE_SPEED
		_text.visible_characters = int(_typing)
	else:
		_text.visible_characters = -1
		for b in _buttons:
			b.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not opened or _layer == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_SPACE or k == KEY_E or k == KEY_ENTER:
			if _text.visible_characters != -1:
				_text.visible_characters = -1
			elif choices.size() == 1:
				_pick(0)
			get_viewport().set_input_as_handled()
		elif (k >= KEY_1 and k <= KEY_9) or k == KEY_0:
			# Pas besoin d'attendre la fin du texte pour répondre (0 = dixième choix).
			_text.visible_characters = -1
			_pick(9 if k == KEY_0 else k - KEY_1)
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			chosen.emit("au_revoir" if _has_choice("au_revoir") else "fermer")
			get_viewport().set_input_as_handled()


func _has_choice(id: String) -> bool:
	for c in choices:
		if str(c["id"]) == id:
			return true
	return false


# =================================================================== VR

func _place_vr() -> void:
	var main: Node = get_parent()
	if _npc == null or main == null or main.get("xr_camera") == null:
		return
	var head: Vector3 = main.xr_camera.global_position
	var to_head: Vector3 = head - _npc.global_position
	to_head.y = 0.0
	to_head = to_head.normalized() if to_head.length() > 0.01 else Vector3.FORWARD
	var side: Vector3 = to_head.cross(Vector3.UP).normalized()
	_vr_panel.global_position = _npc.global_position + to_head * 0.9 + side * 0.75 + Vector3.UP * 1.45
	_vr_panel.look_at(head, Vector3.UP)
	_vr_panel.rotate_object_local(Vector3.UP, PI)


func _refresh_vr() -> void:
	var lines: Array = [str(_vr_text.get_meta("entete", "")), "", str(_vr_text.get_meta("texte", "")), ""]
	for i in range(choices.size()):
		lines.append(("> " if i == selection else "   ") + str(choices[i]["label"]))
	lines.append("")
	lines.append("Stick droit : choisir   Gâchette : répondre   B : partir")
	_vr_text.text = "\n".join(lines)


func vr_tick(stick_y: float, trigger: float, b_button: bool) -> void:
	if not opened or _vr_panel == null:
		return
	if absf(stick_y) < 0.3:
		_vr_neutral = true
	elif _vr_neutral and not choices.is_empty():
		selection = wrapi(selection + (1 if stick_y < 0.0 else -1), 0, choices.size())
		_vr_neutral = false
		_refresh_vr()
	var pressed: bool = trigger > 0.7
	if pressed and _vr_trigger_ready and not choices.is_empty():
		_pick(selection)
	_vr_trigger_ready = not pressed
	if b_button and _vr_b_ready:
		chosen.emit("au_revoir" if _has_choice("au_revoir") else "fermer")
	_vr_b_ready = not b_button

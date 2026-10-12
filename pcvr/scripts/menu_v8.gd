extends Node
## Menu PC + panneau 3D en VR ; manette droite pour selection, gachette pour valider.
signal start_slot(slot: int, new_game: bool)
signal save_requested(slot: int)
signal delete_requested(slot: int)
signal resume_requested

const Saves = preload("res://scripts/save_manager.gd")
var opened: bool = true
var playing: bool = false
var pc_layer: CanvasLayer
var frame: Control
var list_box: VBoxContainer
var heading: Label
var vr_panel: Node3D
var vr_text: Label3D
var vr_help: Label3D
var right_hand: XRController3D
var xr_camera: XRCamera3D
var xr_mode: bool = false
var selection: int = 0
var neutral: bool = true
var trigger_ready: bool = true
var options: Array[String] = []
var view: String = "home"
var seconds: float = 0.0
var active_slot: int = 1

func setup(use_xr: bool, camera: XRCamera3D, controller: XRController3D) -> void:
	xr_mode = use_xr
	xr_camera = camera
	right_hand = controller
	if xr_mode:
		_make_vr_panel()
	else:
		_make_pc_panel()
	_show_view("home")

func _make_pc_panel() -> void:
	pc_layer = CanvasLayer.new()
	pc_layer.layer = 12
	add_child(pc_layer)
	frame = ColorRect.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.color = Color(0.035, 0.08, 0.15, 0.94)
	pc_layer.add_child(frame)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(650, 510)
	# ILE_MANGA_MENU_V9 : panneau aux couleurs de l'aventure.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.11, 0.16, 0.98)
	style.border_color = Color(0.89, 0.71, 0.36)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 16
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 13)
	card.add_child(inner)
	heading = Label.new()
	heading.text = "✦  ÎLE MANGA  ✦"
	heading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.47))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	inner.add_child(heading)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	inner.add_child(list_box)

func _make_vr_panel() -> void:
	vr_panel = Node3D.new()
	vr_panel.name = "Menu_VR_3D"
	xr_camera.add_child(vr_panel)
	vr_panel.position = Vector3(0.0, -0.04, -2.0)
	var background := MeshInstance3D.new()
	var rect := QuadMesh.new()
	rect.size = Vector2(1.9, 1.45)
	background.mesh = rect
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.045, 0.095, 0.17, 0.97)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	background.material_override = material
	background.position.z = -0.03
	vr_panel.add_child(background)
	vr_text = Label3D.new()
	vr_text.font_size = 56
	vr_text.pixel_size = 0.0015
	vr_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vr_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vr_text.position = Vector3(0, 0.06, 0.0)
	vr_panel.add_child(vr_text)
	vr_help = Label3D.new()
	vr_help.text = "Joystick droit : choisir | Gâchette droite : valider"
	vr_help.font_size = 38
	vr_help.pixel_size = 0.001
	vr_help.position = Vector3(0, -0.61, 0.01)
	vr_panel.add_child(vr_help)

func _show_view(which: String) -> void:
	view = which
	selection = 0
	options.clear()
	if view == "home":
		if playing:
			options.append("Reprendre")
		if Saves.latest_slot() >= 0:
			options.append("Continuer")
		options.append_array(["Nouvelle partie", "Charger / sauvegarder", "Effacer une sauvegarde", "Paramètres", "Quitter"])
	elif view == "load" or view == "new" or view == "save" or view == "delete":
		for i in range(1, 7):
			var data: Dictionary = Saves.read_slot(i)
			var info: String = "vide"
			if not data.is_empty():
				info = "%s  •  %s  •  %d min" % [str(data.get("zone", "Île Manga")), str(data.get("saved_at", "date inconnue")), int(float(data.get("play_seconds", 0.0)) / 60.0)]
			options.append("Partie %d : %s" % [i, info])
		options.append("Retour")
	elif view == "settings":
		options = ["Graphismes : PC/VR automatiques", "Retour"]
	_redraw()

func _redraw() -> void:
	if not opened:
		return
	if xr_mode:
		var lines: PackedStringArray = PackedStringArray(["ÎLE MANGA  •  V9", "", "Saves: 6 emplacements", ""])
		for i in range(options.size()):
			lines.append(("➤ " if i == selection else "   ") + options[i])
		vr_text.text = "\n".join(lines)
	else:
		for n in list_box.get_children():
			n.queue_free()
		heading.text = "ÎLE MANGA  •  " + view.to_upper()
		for i in range(options.size()):
			var choice: String = options[i]
			var button := Button.new()
			button.text = choice
			button.custom_minimum_size.y = 45
			button.add_theme_font_size_override("font_size", 17)
			var normal := StyleBoxFlat.new()
			normal.bg_color = Color(0.12, 0.25, 0.32)
			normal.border_color = Color(0.43, 0.47, 0.37)
			normal.set_border_width_all(1)
			normal.set_corner_radius_all(9)
			button.add_theme_stylebox_override("normal", normal)
			var hover := normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color(0.24, 0.43, 0.43)
			hover.border_color = Color(0.99, 0.76, 0.32)
			button.add_theme_stylebox_override("hover", hover)
			button.add_theme_stylebox_override("focus", hover)
			button.pressed.connect(_activate.bind(i))
			list_box.add_child(button)
		if (view == "load" or view == "save") and playing:
			var note := Label.new()
			note.text = "La sauvegarde automatique est mise à jour régulièrement."
			list_box.add_child(note)

func _activate(index: int) -> void:
	if index < 0 or index >= options.size():
		return
	selection = index
	var action: String = options[index]
	if view == "home":
		match action:
			"Reprendre":
				_close()
				resume_requested.emit()
			"Continuer":
				var recent: int = Saves.latest_slot()
				if recent >= 0:
					_load_or_create(recent, false)
			"Nouvelle partie":
				_show_view("new")
			"Charger / sauvegarder":
				_show_view("save" if playing else "load")
			"Effacer une sauvegarde":
				_show_view("delete")
			"Paramètres":
				_show_view("settings")
			"Quitter":
				get_tree().quit()
	elif view == "settings":
		_show_view("home")
	elif index == 6:
		_show_view("home")
	elif view == "new":
		_load_or_create(index + 1, true)
	elif view == "load":
		if not Saves.read_slot(index + 1).is_empty():
			_load_or_create(index + 1, false)
	elif view == "delete":
		if not Saves.read_slot(index + 1).is_empty():
			delete_requested.emit(index + 1)
		_show_view("delete")
	elif view == "save":
		active_slot = index + 1
		save_requested.emit(active_slot)
		_show_view("home")

func _load_or_create(slot: int, new_game: bool) -> void:
	active_slot = slot
	playing = true
	start_slot.emit(slot, new_game)
	_close()

func _close() -> void:
	opened = false
	if xr_mode:
		vr_panel.visible = false
	else:
		frame.visible = false

func open_menu() -> void:
	opened = true
	if xr_mode:
		vr_panel.visible = true
	else:
		frame.visible = true
	_show_view("home")

func _process(delta: float) -> void:
	if playing and not opened:
		seconds += delta
	if not opened or not xr_mode or right_hand == null:
		return
	var stick: Vector2 = right_hand.get_vector2("primary")
	if absf(stick.y) < 0.25:
		neutral = true
	elif neutral and absf(stick.y) > 0.65:
		selection = posmod(selection + (1 if stick.y > 0.0 else -1), options.size())
		neutral = false
		_redraw()
	var pressed: bool = right_hand.get_float("trigger") > 0.65
	if pressed and trigger_ready:
		trigger_ready = false
		_activate(selection)
	elif not pressed:
		trigger_ready = true

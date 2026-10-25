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
var menu_glow_time: float = 0.0
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
## V72 : une confirmation avant d'écraser, d'effacer ou de quitter : [action, emplacement]
var _confirm: Array = []
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
	frame.color = Color(0.018, 0.047, 0.085, 0.42)
	pc_layer.add_child(frame)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(690, 540)
	# ILE_MANGA_MENU_V9 : panneau aux couleurs de l'aventure.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.095, 0.145, 0.93)
	style.border_color = Color(0.98, 0.76, 0.32)
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
	var top_line := Label.new()
	top_line.text = "✦  LES ÎLES DE L'AVENTURE  ✦"
	top_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_line.add_theme_color_override("font_color", Color(0.74, 0.92, 1.0))
	top_line.add_theme_font_size_override("font_size", 15)
	inner.add_child(top_line)
	# V53 : l'illustration du titre seule (l'icône du jeu contient de faux boutons)
	var logo_file := load("res://assets/textures/ui/ile_manga_logo.png") as Texture2D
	if logo_file != null:
		var logo := TextureRect.new()
		logo.texture = logo_file
		logo.custom_minimum_size = Vector2(0, 150)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		inner.add_child(logo)
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
	vr_help.text = "Joystick droit : choisir | Gâchette droite : valider | Bouton ≡ gauche : menu"
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
		options.append("Nouvelle partie")
		if playing:
			options.append("Sauvegarder")
		options.append_array(["Charger une partie", "Effacer une sauvegarde", "Paramètres", "Quitter"])
	elif view == "load" or view == "new" or view == "save" or view == "delete":
		for i in range(1, 7):
			var data: Dictionary = Saves.read_slot(i)
			var info: String = "vide"
			if not data.is_empty():
				info = "%s  •  %s  •  %d min" % [str(data.get("zone", "Île Manga")), str(data.get("saved_at", "date inconnue")), int(float(data.get("play_seconds", 0.0)) / 60.0)]
			options.append("Partie %d : %s" % [i, info])
		options.append("Retour")
	elif view == "settings":
		# V51 : volumes de la musique, des bruitages et des ambiances
		var mu: Node = _music()
		if mu != null:
			options = [mu.volume_label("musique"), mu.volume_label("bruitages"), mu.volume_label("ambiances")]
		options.append_array(["Graphismes : PC/VR automatiques", "Retour"])
	_redraw()

func _redraw() -> void:
	if not opened:
		return
	if xr_mode:
		var lines: PackedStringArray = PackedStringArray(["ÎLE MANGA  •  " + _version_v21(), "", "6 emplacements de sauvegarde", ""])
		for i in range(options.size()):
			lines.append(("➤ " if i == selection else "   ") + options[i])
		vr_text.text = "\n".join(lines)
	else:
		for n in list_box.get_children():
			n.queue_free()
		heading.text = {"home": "✦  ÎLE MANGA  ✦", "new": "✦  NOUVELLE PARTIE  ✦", "load": "✦  CHARGER UNE PARTIE  ✦",
			"save": "✦  SAUVEGARDER  ✦", "delete": "✦  EFFACER UNE SAUVEGARDE  ✦", "settings": "✦  PARAMÈTRES  ✦", "confirm": "✦  ÊTES-VOUS SÛR ?  ✦"}.get(view, "✦  ÎLE MANGA  ✦")
		frame.modulate.a = 0.84
		for i in range(options.size()):
			var choice: String = options[i]
			var button := Button.new()
			button.text = ("✧  " if view == "home" else "▸  ") + choice
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
		if view in ["load", "save", "new", "delete"]:
			var footer := Label.new()
			footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			footer.text = "6 emplacements  •  Sauvegardes compatibles V8 / V9"
			footer.add_theme_color_override("font_color", Color(0.82, 0.79, 0.64))
			list_box.add_child(footer)
		if view == "load" and playing:
			var warn := Label.new()
			warn.text = "Charger remplace la partie en cours : pense à sauvegarder avant."
			warn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
			list_box.add_child(warn)
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
			"Sauvegarder":
				_show_view("save")
			"Charger une partie":
				_show_view("load")
			"Effacer une sauvegarde":
				_show_view("delete")
			"Paramètres":
				_show_view("settings")
			"Quitter":
				_ask_confirm("quit", 0)
	elif view == "settings":
		var mu: Node = _music()
		var keys := ["musique", "bruitages", "ambiances"]
		if mu != null and index < 3:
			mu.cycle_volume(keys[index])
			_show_view("settings")
			selection = index
			_redraw()
		elif action == "Retour":
			_show_view("home")
	elif view == "confirm":
		var what: String = str(_confirm[0]) if not _confirm.is_empty() else ""
		var slot: int = int(_confirm[1]) if not _confirm.is_empty() else 0
		_confirm = []
		if index != 0:
			_show_view("home")
			return
		match what:
			"new":
				_load_or_create(slot, true)
			"delete":
				delete_requested.emit(slot)
				_show_view("delete")
			"save":
				active_slot = slot
				save_requested.emit(active_slot)
				_show_view("home")
			"quit":
				get_tree().quit()
	elif index == 6:
		_show_view("home")
	elif view == "new":
		if not Saves.read_slot(index + 1).is_empty():
			_ask_confirm("new", index + 1)
		else:
			_load_or_create(index + 1, true)
	elif view == "load":
		if not Saves.read_slot(index + 1).is_empty():
			_load_or_create(index + 1, false)
	elif view == "delete":
		if not Saves.read_slot(index + 1).is_empty():
			_ask_confirm("delete", index + 1)
		else:
			_show_view("delete")
	elif view == "save":
		if index + 1 != active_slot and not Saves.read_slot(index + 1).is_empty():
			_ask_confirm("save", index + 1)
		else:
			active_slot = index + 1
			save_requested.emit(active_slot)
			_show_view("home")


## V72 : « Êtes-vous sûr ? » avant d'écraser une partie, de l'effacer ou de quitter.
func _ask_confirm(what: String, slot: int) -> void:
	_confirm = [what, slot]
	view = "confirm"
	selection = 1
	options.clear()
	match what:
		"new":
			options.append("Oui, recommencer à zéro (la partie %d sera remplacée)" % slot)
		"delete":
			options.append("Oui, effacer la partie %d pour toujours" % slot)
		"save":
			options.append("Oui, écrire par-dessus la partie %d" % slot)
		"quit":
			options.append("Oui, quitter le jeu" + (" (la dernière sauvegarde automatique sera gardée)" if playing else ""))
	options.append("Non, revenir")
	_redraw()

func _music() -> Node:
	var p: Node = get_parent()
	return p.get("music_v51") if p != null else null


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
	if opened and not xr_mode and frame != null:
		frame.modulate.a = move_toward(frame.modulate.a, 1.0, delta * 2.3)
		menu_glow_time += delta
		if heading != null:
			heading.modulate.a = 0.91 + 0.09 * sin(menu_glow_time * 1.45)
	if playing and not opened:
		seconds += delta
	if not opened or not xr_mode or right_hand == null:
		return
	var stick: Vector2 = right_hand.get_vector2("primary")
	if absf(stick.y) < 0.25:
		neutral = true
	elif neutral and absf(stick.y) > 0.65:
		# V72 : le joystick vers le haut remonte dans la liste (comme le dialogue et le carnet)
		selection = posmod(selection + (1 if stick.y < 0.0 else -1), options.size())
		neutral = false
		_redraw()
	var pressed: bool = right_hand.get_float("trigger") > 0.65
	if pressed and trigger_ready:
		trigger_ready = false
		_activate(selection)
	elif not pressed:
		trigger_ready = true


func _version_v21() -> String:
	var parts: PackedStringArray = str(ProjectSettings.get_setting("application/config/name", "")).split(" ")
	return parts[parts.size() - 1] if parts.size() > 0 else ""

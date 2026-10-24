extends Node
## V56 : le carnet de voyage — le menu du jeu, en cinq onglets :
##   Inventaire (le sac, les objets en main), Quêtes (en cours, à faire, accomplies),
##   Carte (l'archipel et le plan de Port-Azur, avec le joueur, les lieux découverts et les
##   objectifs), Personnages (tous ceux qu'on a rencontrés : portrait, amitié, humeur,
##   souvenirs, où les trouver), Héros (cœurs, endurance, souffle, force, réputation,
##   titres, réductions, statistiques).
## Sur PC, une grande fenêtre par-dessus le jeu ; en VR, la même fenêtre dessinée dans un
## panneau flottant que l'on vise avec un laser (gâchette pour cliquer, stick pour faire
## défiler). Touches : I / Tab (sac), J (quêtes), M (carte), P (personnages), 1 à 5.

const SYMBOLS := "res://assets/fonts/DejaVuSans.ttf"
const GOLD := Color(0.98, 0.76, 0.32)
const INK := Color(0.94, 0.95, 0.92)
const DIM := Color(0.7, 0.8, 0.88)
const BG := Color(0.025, 0.08, 0.125, 0.96)
const PANEL := Color(0.04, 0.12, 0.17, 0.95)
const TABS := ["🎒  Inventaire", "📜  Quêtes", "🗺  Carte", "👥  Personnages", "⭐  Héros"]
const UI_W: int = 1600
const UI_H: int = 960
const REGIONS := ["Tous", "Île du village", "Jungle", "Elfes", "Nains", "Ciel", "Atlantide", "Port-Azur", "Fées", "Carène", "Tazira", "Cliquetis", "Ramure", "Arcanelle", "Balafre", "Trois Soleils", "Braise"]

var main: Node
var inv: Node
var xr: bool = false
var opened: bool = false
var current: int = 0
var root: Control
var layer: CanvasLayer
var viewport: SubViewport
var panel3d: MeshInstance3D
var laser: MeshInstance3D
var cursor: MeshInstance3D
var _tab_buttons: Array = []
var _pages: Array = []
var _clock_label: Label
var _coins_label: Label
var _fonts: Dictionary = {}
# quêtes
var _q_filter: String = "en_cours"
var _q_filter_buttons: Dictionary = {}
var _q_list: VBoxContainer
var _q_detail: RichTextLabel
var _q_selected: String = ""
var _q_summary: Label
var _q_entries: Dictionary = {}
# carte
var _map
var _map_mode: String = "archipel"
var _map_buttons: Dictionary = {}
var _map_info: Label
var _tp_button: Button                  # V58 : la magie de téléportation
var _tp_panel: VBoxContainer
var _tp_list: HFlowContainer
var _tp_open: bool = false
# personnages
var _p_region: String = "Tous"
var _p_grid: GridContainer
var _p_detail_portrait: TextureRect
var _p_detail_text: RichTextLabel
var _p_selected: String = ""
var _p_region_buttons: Dictionary = {}
var _p_count: Label
var _portraits: Dictionary = {}
# héros
var _h_text: RichTextLabel
# VR
var _vr_trigger_down: bool = false
var _vr_last: Vector2 = Vector2(-1, -1)
var _vr_scroll_acc: float = 0.0


func build(main_node: Node, inventory: Node, use_xr: bool) -> void:
	main = main_node
	inv = inventory
	xr = use_xr
	_load_fonts()
	root = Control.new()
	root.name = "Carnet_v56"
	root.size = Vector2(UI_W, UI_H)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	if xr:
		viewport = SubViewport.new()
		viewport.size = Vector2i(UI_W, UI_H)
		viewport.transparent_bg = true
		viewport.gui_embed_subwindows = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		viewport.add_child(root)
		_build_vr_panel()
	else:
		layer = CanvasLayer.new()
		layer.layer = 11
		layer.visible = false
		add_child(layer)
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.02, 0.05, 0.55)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(dim)
		var holder := Control.new()
		holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(holder)
		holder.add_child(root)
		holder.resized.connect(_fit_pc.bind(holder))
		_fit_pc.call_deferred(holder)
	_build_ui()


func _fit_pc(holder: Control) -> void:
	var s: Vector2 = holder.size
	if s.x < 10.0:
		return
	var k: float = minf((s.x - 40.0) / UI_W, (s.y - 40.0) / UI_H)
	k = clampf(k, 0.45, 1.4)
	root.scale = Vector2(k, k)
	root.position = (s - Vector2(UI_W, UI_H) * k) * 0.5


func _load_fonts() -> void:
	# DejaVu Sans prête ses symboles (★ ⚓ ♥ ✓ ▶…) à Lora et à la police par défaut du jeu
	var sym: Font = load(SYMBOLS) if ResourceLoader.exists(SYMBOLS) else null
	for k in ["Regular", "Bold", "Italic", "BoldItalic"]:
		var p: String = "res://assets/fonts/Lora-%s.ttf" % k
		if ResourceLoader.exists(p):
			var f: Font = load(p)
			if sym != null and not f.fallbacks.has(sym):
				f.fallbacks = f.fallbacks + [sym]
			_fonts[k] = f
	var def: Font = ThemeDB.fallback_font
	if sym != null and def != null and not def.fallbacks.has(sym):
		def.fallbacks = def.fallbacks + [sym]


func _font(kind: String) -> Font:
	return _fonts.get(kind, null)


func _style(bg: Color, border: Color, radius: int = 12, width: int = 2, margin: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


func _label(text: String, size: int, color: Color = INK, font: String = "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font != "" and _font(font) != null:
		l.add_theme_font_override("font", _font(font))
	return l


func _button(text: String, size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.17, 0.24, 0.95), Color(0.75, 0.6, 0.3), 9, 1, 8))
	b.add_theme_stylebox_override("hover", _style(Color(0.1, 0.25, 0.33, 0.98), GOLD, 9, 2, 8))
	b.add_theme_stylebox_override("pressed", _style(Color(0.16, 0.3, 0.36, 1.0), GOLD, 9, 2, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
	return b


func _rich(size: int = 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = false
	r.scroll_active = true
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", INK)
	if _font("Regular") != null:
		r.add_theme_font_override("normal_font", _font("Regular"))
	if _font("Bold") != null:
		r.add_theme_font_override("bold_font", _font("Bold"))
	if _font("Italic") != null:
		r.add_theme_font_override("italics_font", _font("Italic"))
	return r


# =================================================================== la fenêtre

func _build_ui() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(BG, GOLD, 20, 2, 18))
	root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	# en-tête : titre, l'heure et la bourse
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	col.add_child(head)
	var title := _label("Carnet de voyage", 34, Color(1.0, 0.84, 0.5), "BoldItalic")
	head.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_clock_label = _label("", 19, DIM, "Italic")
	_clock_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_clock_label)
	_coins_label = _label("", 19, GOLD, "Bold")
	_coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_coins_label)
	var close := _button("✕", 20)
	close.custom_minimum_size = Vector2(44, 40)
	close.pressed.connect(func(): inv.close())
	head.add_child(close)
	# les onglets
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	for i in range(TABS.size()):
		var b := _button(TABS[i], 19)
		b.custom_minimum_size = Vector2(250, 46)
		b.pressed.connect(open_tab.bind(i))
		tabs.add_child(b)
		_tab_buttons.append(b)
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.custom_minimum_size = Vector2(UI_W - 40, UI_H - 200)
	col.add_child(pages)
	for i in range(TABS.size()):
		var pg := PanelContainer.new()
		pg.add_theme_stylebox_override("panel", _style(PANEL, Color(0.3, 0.4, 0.48), 14, 1, 14))
		pg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pg.visible = false
		pages.add_child(pg)
		_pages.append(pg)
	_build_inventory(_pages[0])
	_build_quests(_pages[1])
	_build_map(_pages[2])
	_build_people(_pages[3])
	_build_hero(_pages[4])
	var help := _label("I / Tab : sac   •   J : quêtes   •   M : carte   •   P : personnages   •   H : héros   •   1-5 : onglets   •   Échap : fermer" if not xr else "Visez avec la main droite, gâchette pour cliquer, stick pour faire défiler   •   Y : fermer", 15, DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(help)


func open_tab(i: int) -> void:
	current = clampi(i, 0, TABS.size() - 1)
	for k in range(_pages.size()):
		(_pages[k] as Control).visible = k == current
		var b: Button = _tab_buttons[k]
		var on: bool = k == current
		b.add_theme_stylebox_override("normal", _style(Color(0.16, 0.3, 0.38, 1.0) if on else Color(0.06, 0.17, 0.24, 0.95), GOLD if on else Color(0.75, 0.6, 0.3), 9, 2 if on else 1, 8))
	refresh()


func show_menu(tab: int) -> void:
	opened = true
	if layer != null:
		layer.visible = true
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_place_vr()
		panel3d.visible = true
		laser.visible = true
		cursor.visible = true
	open_tab(tab)


func hide_menu() -> void:
	opened = false
	if _tp_open:
		show_teleport(false)
	if layer != null:
		layer.visible = false
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		panel3d.visible = false
		laser.visible = false
		cursor.visible = false


func refresh() -> void:
	if not opened:
		return
	var t: Node = main.get("temps_v56")
	if t != null:
		_clock_label.text = "Jour %d  —  %s  (%s)" % [int(t.day_count), str(t.hour_text()), str(t.period())]
	_coins_label.text = "◉ %d pièces" % inv.count("piece") + ("   ✦ %d or" % inv.count("piece_or") if inv.count("piece_or") > 0 else "")
	match current:
		0:
			inv._refresh_pc()
		1:
			_refresh_quests()
		2:
			_refresh_map()
		3:
			_refresh_people()
		4:
			_refresh_hero()


func _process(delta: float) -> void:
	if not opened:
		return
	if current == 2 and _map != null:
		_map.queue_redraw()
	if xr:
		_vr_pointer(delta)


func handle_key(k: Key) -> bool:
	if not opened:
		return false
	match k:
		KEY_1, KEY_KP_1:
			open_tab(0)
		KEY_2, KEY_KP_2:
			open_tab(1)
		KEY_3, KEY_KP_3:
			open_tab(2)
		KEY_4, KEY_KP_4:
			open_tab(3)
		KEY_5, KEY_KP_5:
			open_tab(4)
		_:
			return false
	return true


# =================================================================== inventaire

func _build_inventory(pg: Control) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	pg.add_child(col)
	inv._build_inventory_page(col)


# =================================================================== quêtes

func _build_quests(pg: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	pg.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 6)
	left.add_child(seg)
	for f in [["en_cours", "En cours"], ["a_faire", "À faire"], ["accomplies", "Accomplies"]]:
		var b := _button(f[1], 17)
		b.custom_minimum_size = Vector2(178, 40)
		b.pressed.connect(_set_q_filter.bind(str(f[0])))
		seg.add_child(b)
		_q_filter_buttons[f[0]] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_q_list = VBoxContainer.new()
	_q_list.add_theme_constant_override("separation", 6)
	_q_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_q_list)
	_q_summary = _label("", 15, DIM, "Italic")
	_q_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_q_summary.custom_minimum_size = Vector2(540, 0)
	left.add_child(_q_summary)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _style(Color(0.06, 0.15, 0.2, 0.9), Color(0.55, 0.45, 0.25), 12, 1, 18))
	row.add_child(right)
	var rc := VBoxContainer.new()
	right.add_child(rc)
	_q_detail = _rich(18)
	_q_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rc.add_child(_q_detail)
	var mb := _button("🗺  Voir sur la carte", 17)
	mb.pressed.connect(_quest_on_map)
	rc.add_child(mb)


var _map_focus_quest: String = ""


func _refresh_quests() -> void:
	var j: Node = main.get("journal_v56")
	if j == null:
		return
	var data: Dictionary = j.listing()
	for f in _q_filter_buttons:
		var b: Button = _q_filter_buttons[f]
		var n: int = (data[f] as Array).size()
		b.text = {"en_cours": "En cours", "a_faire": "À faire", "accomplies": "Accomplies"}[f] + "  (%d)" % n
		var on: bool = f == _q_filter
		b.add_theme_stylebox_override("normal", _style(Color(0.16, 0.3, 0.38, 1.0) if on else Color(0.06, 0.17, 0.24, 0.95), GOLD if on else Color(0.75, 0.6, 0.3), 9, 2 if on else 1, 8))
	for c in _q_list.get_children():
		c.queue_free()
	_q_entries.clear()
	var list: Array = data[_q_filter]
	if list.is_empty():
		var l := _label({"en_cours": "Aucune quête en cours. Parlez aux habitants : beaucoup ont besoin d'aide.", "a_faire": "Rien en vue pour l'instant. Explorez, rencontrez du monde !", "accomplies": "Aucune quête accomplie… pour l'instant."}[_q_filter], 16, DIM, "Italic")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(520, 0)
		_q_list.add_child(l)
	for e in list:
		var icon: String = {"Port-Azur": "★", "Habitants": "●", "Aventure": "⚔", "Royaume des fées": "✦", "Arcanelle": "✧", "Balafre": "☠", "Trois Soleils": "☀", "Île de Braise": "✹"}.get(str(e["sorte"]), "•")
		var b := _button("%s  %s\n     %s" % [icon, str(e["titre"]), str(e["lieu"])], 16)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(530, 58)
		var sel: bool = str(e["id"]) == _q_selected
		if sel:
			b.add_theme_stylebox_override("normal", _style(Color(0.18, 0.32, 0.4, 1.0), GOLD, 9, 2, 8))
		b.pressed.connect(_select_quest.bind(str(e["id"])))
		_q_list.add_child(b)
		_q_entries[str(e["id"])] = e
	if _q_selected == "" and not list.is_empty():
		_q_selected = str(list[0]["id"])
	var cur: Dictionary = _q_entries.get(_q_selected, {})
	if cur.is_empty():
		_q_detail.text = ""
	else:
		var s: String = "[font_size=28][color=#ffd27a][b]%s[/b][/color][/font_size]\n" % str(cur["titre"])
		s += "[color=#b4cbe0][i]%s  ·  %s  ·  %s[/i][/color]\n\n" % [str(cur["lieu"]), str(cur["qui"]), str(cur["sorte"])]
		s += "%s\n\n" % str(cur["texte"])
		s += "[color=#ffd27a][b]Objectif :[/b][/color] %s\n\n" % str(cur.get("objectif", ""))
		if cur.has("etapes"):
			s += "[b]Étapes[/b]\n"
			for st in cur["etapes"]:
				var mark: String = "[color=#7fe08a]✓[/color]" if bool(st[1]) else ("[color=#ffd27a]▶[/color]" if bool(st[2]) else "[color=#7d8a94]○[/color]")
				var txt: String = str(st[0])
				if bool(st[1]):
					txt = "[color=#9aa7b0][s]%s[/s][/color]" % txt
				s += "  %s  %s\n" % [mark, txt]
			s += "\n"
		s += "[b]Récompense :[/b] [color=#e8d9a8]%s[/color]" % str(cur.get("recompense", ""))
		_q_detail.text = s
	var bonus: Dictionary = j.bonus
	_q_summary.text = "Quêtes de Port-Azur accomplies : %d / %d   •   Bonus gagnés : %s" % [j.finished_count(), j.QUETES.size(),
		"+%d cœur(s), +%d endurance, +%d souffle, +%d force" % [int(bonus["coeur"]), int(bonus["endurance"]), int(bonus["souffle"]), int(bonus["force"])]]


# =================================================================== carte

func _build_map(pg: Control) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	pg.add_child(col)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	col.add_child(bar)
	for m in [["archipel", "L'archipel"], ["azur", "Port-Azur"]]:
		var b := _button(m[1], 17)
		b.custom_minimum_size = Vector2(160, 38)
		b.pressed.connect(_set_map_mode.bind(str(m[0])))
		bar.add_child(b)
		_map_buttons[m[0]] = b
	var zin := _button("+", 20)
	zin.custom_minimum_size = Vector2(44, 38)
	zin.pressed.connect(func(): _map.zoom_by(1.4))
	bar.add_child(zin)
	var zout := _button("−", 20)
	zout.custom_minimum_size = Vector2(44, 38)
	zout.pressed.connect(func(): _map.zoom_by(1.0 / 1.4))
	bar.add_child(zout)
	var me := _button("⌖  Où suis-je ?", 17)
	me.pressed.connect(func(): _map.center_on_player())
	bar.add_child(me)
	# V58 : se téléporter (cadeau des fées)
	_tp_button = _button("✦  Se téléporter", 17)
	_tp_button.pressed.connect(func(): show_teleport(not _tp_open))
	_tp_button.visible = false
	bar.add_child(_tp_button)
	_map_info = _label("", 15, DIM, "Italic")
	_map_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(_map_info)
	_map = preload("res://scripts/carte_v56.gd").new()
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.clip_contents = true
	col.add_child(_map)
	_map.setup(main, self)
	_tp_panel = VBoxContainer.new()
	_tp_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tp_panel.add_theme_constant_override("separation", 14)
	_tp_panel.visible = false
	col.add_child(_tp_panel)
	_tp_panel.add_child(_label("✦  La magie de téléportation", 30, GOLD, "BoldItalic"))
	_tp_panel.add_child(_label("Pense très fort à un lieu que tu as déjà vu… et tu y seras. Choisis ta destination :", 19, DIM, "Italic"))
	_tp_list = HFlowContainer.new()
	_tp_list.add_theme_constant_override("h_separation", 14)
	_tp_list.add_theme_constant_override("v_separation", 14)
	_tp_panel.add_child(_tp_list)
	var back := _button("Fermer", 18)
	back.custom_minimum_size = Vector2(180, 48)
	back.pressed.connect(func(): show_teleport(false))
	_tp_panel.add_child(back)


## V58 : la liste des lieux où se téléporter (à la place de la carte).
func show_teleport(on: bool) -> void:
	var tp: Node = main.get("teleport_v58")
	_tp_open = on and tp != null and bool(tp.known())
	if _tp_panel == null:
		return
	_tp_panel.visible = _tp_open
	_map.visible = not _tp_open
	if not _tp_open:
		return
	for c in _tp_list.get_children():
		c.queue_free()
	var dests: Array = tp.destinations()
	if dests.is_empty():
		_tp_list.add_child(_label("Aucun autre lieu visité pour l'instant.", 19, DIM, "Italic"))
	for d in dests:
		var id: String = str(d[0])
		var b := _button("✦  " + str(d[1]), 21)
		b.custom_minimum_size = Vector2(340, 64)
		b.pressed.connect(func():
			show_teleport(false)
			tp.go(id))
		_tp_list.add_child(b)


func _refresh_map() -> void:
	var tp: Node = main.get("teleport_v58")
	if _tp_button != null:
		_tp_button.visible = tp != null and bool(tp.known())
	for m in _map_buttons:
		var b: Button = _map_buttons[m]
		var on: bool = m == _map_mode
		b.add_theme_stylebox_override("normal", _style(Color(0.16, 0.3, 0.38, 1.0) if on else Color(0.06, 0.17, 0.24, 0.95), GOLD if on else Color(0.75, 0.6, 0.3), 9, 2 if on else 1, 8))
	if _map_focus_quest != "":
		_map.focus_quest(_map_focus_quest)
		_map_focus_quest = ""
	_map_info.text = "Faites glisser pour déplacer, molette pour zoomer.  ▲ vous  ★ objectif  ⚓ bateau de ligne"


# =================================================================== personnages

func _build_people(pg: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	pg.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(880, 0)
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 6)
	bar.add_theme_constant_override("v_separation", 6)
	left.add_child(bar)
	for r in REGIONS:
		var b := _button(r, 15)
		b.custom_minimum_size = Vector2(0, 34)
		b.pressed.connect(_set_region.bind(str(r)))
		bar.add_child(b)
		_p_region_buttons[r] = b
	_p_count = _label("", 15, DIM, "Italic")
	left.add_child(_p_count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_p_grid = GridContainer.new()
	_p_grid.columns = 7
	_p_grid.add_theme_constant_override("h_separation", 8)
	_p_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_p_grid)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _style(Color(0.06, 0.15, 0.2, 0.9), Color(0.55, 0.45, 0.25), 12, 1, 16))
	row.add_child(right)
	var rc := VBoxContainer.new()
	rc.add_theme_constant_override("separation", 10)
	right.add_child(rc)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.3), GOLD, 10, 2, 3))
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rc.add_child(frame)
	_p_detail_portrait = TextureRect.new()
	_p_detail_portrait.custom_minimum_size = Vector2(200, 200)
	_p_detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_p_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_p_detail_portrait)
	_p_detail_text = _rich(17)
	_p_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rc.add_child(_p_detail_text)
	var mb := _button("🗺  Où le trouver ?", 17)
	mb.pressed.connect(_person_on_map)
	rc.add_child(mb)


func _portrait(id: String) -> Texture2D:
	if _portraits.has(id):
		return _portraits[id]
	var p: String = "res://assets/textures/portraits/%s.png" % id
	var t: Texture2D = load(p) if ResourceLoader.exists(p) else null
	if t == null:
		var p2: String = "res://assets/textures/portraits/inconnu.png"
		t = load(p2) if ResourceLoader.exists(p2) else null
	_portraits[id] = t
	return t


func _region_of(n: Node) -> String:
	var j: Node = main.get("journal_v56")
	var place: String = j.place_name(n.global_position) if j != null else ""
	if place.begins_with("Port-Azur"):
		return "Port-Azur"
	if place.begins_with("Le royaume des fées"):
		return "Fées"
	if place.begins_with("Tazira"):
		return "Tazira"
	if place.begins_with("Cliquetis"):
		return "Cliquetis"
	if place.begins_with("Ramure"):
		return "Ramure"
	if place.begins_with("Arcanelle"):
		return "Arcanelle"
	if place.begins_with("La Balafre") or place.begins_with("L'Île de la Balafre"):
		return "Balafre"
	if place.begins_with("Trois Soleils"):
		return "Trois Soleils"
	if place.begins_with("Île de Braise") or place.begins_with("L'Île de Braise"):
		return "Braise"
	if place.begins_with("Carène") or place.begins_with("La grande île") or place.begins_with("Les hautes") or place.begins_with("La forêt des brumes") or place.begins_with("Le désert") or place.begins_with("Le Cœur"):
		return "Carène"
	if place.begins_with("L'Atlantide"):
		return "Atlantide"
	if place.begins_with("L'île flottante"):
		return "Ciel"
	if place.begins_with("Forgefer") or place.begins_with("La Montagne"):
		return "Nains"
	if place.begins_with("Le Bois-Doré") or place.begins_with("Le Royaume"):
		return "Elfes"
	if place.begins_with("L'île de la jungle"):
		return "Jungle"
	return "Île du village"


func _met_list() -> Array:
	var out: Array = []
	for n in main.npcs_v31:
		if not is_instance_valid(n):
			continue
		if int(n.brain.memoire.get("visites", 0)) <= 0:
			continue
		var reg: String = str(n.get_meta("region_v56", ""))
		if reg == "":
			reg = _region_of(n)
			if str(n.profile.get("groupe", "")) == "azur":
				reg = "Port-Azur"
			if str(n.profile.get("groupe", "")) == "carene":
				reg = "Carène"
			if str(n.profile.get("groupe", "")) == "tazira":
				reg = "Tazira"
			if str(n.profile.get("groupe", "")) == "cliquetis":
				reg = "Cliquetis"
			if str(n.profile.get("groupe", "")) == "ramure":
				reg = "Ramure"
			if str(n.profile.get("groupe", "")) == "arcanelle":
				reg = "Arcanelle"
			if str(n.profile.get("groupe", "")) == "balafre":
				reg = "Balafre"
			if str(n.profile.get("groupe", "")) == "soleils":
				reg = "Trois Soleils"
			if str(n.profile.get("groupe", "")) == "braise":
				reg = "Braise"
			n.set_meta("region_v56", reg)
		out.append([n, reg])
	return out


func _refresh_people() -> void:
	for r in _p_region_buttons:
		var b: Button = _p_region_buttons[r]
		var on: bool = r == _p_region
		b.add_theme_stylebox_override("normal", _style(Color(0.16, 0.3, 0.38, 1.0) if on else Color(0.06, 0.17, 0.24, 0.95), GOLD if on else Color(0.75, 0.6, 0.3), 9, 2 if on else 1, 6))
	for c in _p_grid.get_children():
		c.queue_free()
	var all: Array = _met_list()
	var total: int = 0
	for n0 in main.npcs_v31:
		if is_instance_valid(n0) and not str(n0.profile.get("id", "")).begins_with("passant"):
			total += 1
	_p_count.text = "Personnages rencontrés : %d" % all.size() + ("  sur %d habitants nommés" % total if total > 0 else "")
	var shown: Array = all.filter(func(e): return _p_region == "Tous" or str(e[1]) == _p_region)
	if shown.is_empty():
		var l := _label("Personne ici… pour l'instant. Allez saluer les habitants !", 16, DIM, "Italic")
		_p_grid.add_child(l)
	for e in shown:
		var n: Node = e[0]
		var id: String = str(n.profile.get("id", ""))
		var cardb := Button.new()
		cardb.focus_mode = Control.FOCUS_NONE
		cardb.custom_minimum_size = Vector2(116, 150)
		var sel: bool = id == _p_selected
		cardb.add_theme_stylebox_override("normal", _style(Color(0.18, 0.32, 0.4, 1.0) if sel else Color(0.06, 0.17, 0.24, 0.95), GOLD if sel else Color(0.4, 0.45, 0.5), 9, 2 if sel else 1, 4))
		cardb.add_theme_stylebox_override("hover", _style(Color(0.1, 0.25, 0.33, 0.98), GOLD, 9, 2, 4))
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 4
		v.offset_right = -4
		v.offset_top = 4
		cardb.add_child(v)
		var tr := TextureRect.new()
		tr.texture = _portrait(id)
		tr.custom_minimum_size = Vector2(104, 104)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
		var nm := _label(str(n.display_name).split(" ")[0] if str(n.display_name).length() > 14 else str(n.display_name), 13, INK, "Bold")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.custom_minimum_size = Vector2(108, 0)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nm)
		cardb.pressed.connect(_select_person.bind(id))
		_p_grid.add_child(cardb)
	if _p_selected == "" and not shown.is_empty():
		_p_selected = str(shown[0][0].profile.get("id", ""))
	var cur: Node = null
	for e2 in all:
		if str(e2[0].profile.get("id", "")) == _p_selected:
			cur = e2[0]
	if cur == null:
		_p_detail_text.text = ""
		_p_detail_portrait.texture = null
		return
	_p_detail_portrait.texture = _portrait(_p_selected)
	var b: Object = cur.brain
	var aff: float = float(b.affinite)
	var hearts: String = ""
	for k in range(5):
		hearts += "♥" if aff >= (k + 1) * 20.0 - 10.0 else "♡"
	var s: String = "[font_size=26][color=#ffd27a][b]%s[/b][/color][/font_size]\n" % str(cur.display_name)
	var titre: String = str(cur.profile.get("titre", ""))
	if titre != "":
		titre = titre.left(1).to_upper() + titre.substr(1)
	s += "[i][color=#b4cbe0]%s[/color][/i]\n" % titre
	s += "[color=#b4cbe0]%s[/color]\n\n" % str(cur.get_meta("region_v56", ""))
	s += "[b]Amitié :[/b] [color=#ff8a8a]%s[/color]   ([i]vous appelle « %s »[/i])\n" % [hearts, str(b.surnom())]
	s += "[b]Humeur :[/b] %s\n" % str(b.humeur_mot())
	s += "[b]Rencontres :[/b] %d\n" % int(b.memoire.get("visites", 0))
	var where: String = _where_now(cur)
	if where != "":
		s += "[b]En ce moment :[/b] %s\n" % where
	var likes: Array = []
	for item in b.memoire.get("cadeaux", {}):
		if (cur.profile.get("aime", {}) as Dictionary).has(item):
			likes.append(str(inv.ITEMS.get(str(item), {"name": str(item)})["name"]).to_lower())
	if not likes.is_empty():
		s += "[b]Aime :[/b] %s\n" % ", ".join(likes)
	var q: Dictionary = cur.profile.get("quete", {})
	if not q.is_empty():
		var st: String = str(b.memoire.get("quete", ""))
		s += "[b]Sa demande :[/b] %s\n" % {"": "on ne sait pas encore", "demandee": "en cours", "finie": "accomplie ✓"}.get(st, st)
	var mem: Array = b.memoire.get("journal", [])
	if not mem.is_empty():
		s += "\n[b]Souvenirs[/b]\n"
		for k2 in range(maxi(0, mem.size() - 4), mem.size()):
			s += "  [i]· %s[/i]\n" % str(mem[k2][1])
	_p_detail_text.text = s


func _where_now(n: Node) -> String:
	if n.get("hidden_home") != null and bool(n.get("hidden_home")):
		return "chez lui / chez elle"
	var j: Node = main.get("journal_v56")
	var place: String = j.place_name(n.global_position) if j != null else ""
	if str(n.get("target_spot")) != "" and n.get("azur") != null:
		var sp: String = str(n.get("target_spot"))
		var label := {"tav_": "au Perroquet Bleu", "cafe_": "au Café de la Place", "paulo": "Chez Paulo", "plage": "à la plage", "hotel": "au Grand Hôtel", "promenade": "sur la promenade",
			"banc": "sur la place", "petanque": "à la pétanque", "belvedere": "au belvédère", "paillote": "à la paillote", "quai": "sur le quai", "phare": "au phare", "jetee": "sur la jetée",
			"fontaine": "près de la fontaine", "chateau": "à la plage", "secours": "au poste de secours", "glacier": "au kiosque à glaces", "rita": "sous sa tente"}
		for k in label:
			if sp.begins_with(k):
				return "%s, %s" % [label[k], place]
	return place


# =================================================================== héros

var _hero_pg: Control
var _hero_v63: bool = false


func _build_hero(pg: Control) -> void:
	_hero_pg = pg
	_h_text = _rich(19)
	pg.add_child(_h_text)


func _refresh_hero() -> void:
	# V63 : la page du héros de la progression (niveau, talents, équipement, sceaux)
	var pr: Node = main.get("progression_v63")
	if pr != null:
		if not _hero_v63:
			_hero_v63 = true
			_h_text.queue_free()
			_h_text = null
			pr.build_page(_hero_pg, self)
		pr.refresh_page()
		return
	_h_text.text = _hero_stats_text(true)


## Le texte des bonus, de la réputation, des titres et des statistiques.
func _hero_stats_text(title: bool = false) -> String:
	var j: Node = main.get("journal_v56")
	var hero: Node = main.get("hero_v28")
	var s: String = "[font_size=30][color=#ffd27a][b]Le héros[/b][/color][/font_size]\n\n" if title else "[font_size=24][color=#ffd27a][b]Bonus des quêtes[/b][/color][/font_size]\n"
	if j != null:
		var bo: Dictionary = j.bonus
		var hp_max: int = 10 + 2 * int(bo["coeur"])
		s += "[b]Cœurs :[/b] %d  [color=#9aa7b0](dont +%d gagnés en aidant les gens)[/color]\n" % [hp_max / 2, int(bo["coeur"])]
		s += "[b]Endurance :[/b] %d  [color=#9aa7b0](+%d)[/color]\n" % [10 + 3 * int(bo["endurance"]), int(bo["endurance"])]
		s += "[b]Souffle sous l'eau sans masque :[/b] %d secondes  [color=#9aa7b0](+%d)[/color]\n" % [18 + 7 * int(bo["souffle"]), int(bo["souffle"])]
		s += "[b]Force :[/b] +%d aux dégâts\n\n" % int(bo["force"])
		var lvl: Array = j.rep_level()
		var nxt: int = j.rep_next()
		s += "[font_size=24][color=#ffd27a][b]Réputation à Port-Azur[/b][/color][/font_size]\n"
		s += "%s  —  %d points%s\n" % [str(lvl[1]), int(j.reputation), ("  (prochain niveau à %d)" % nxt) if nxt > 0 else ""]
		var bar_n: int = clampi(int(float(j.reputation) / 140.0 * 30.0), 0, 30)
		s += "[color=#ffd27a]%s[/color][color=#3a4a55]%s[/color]\n\n" % ["█".repeat(bar_n), "█".repeat(30 - bar_n)]
		s += "[b]Réductions :[/b]\n%s\n\n" % str(j.discount_text())
		s += "[font_size=24][color=#ffd27a][b]Titres[/b][/color][/font_size]\n"
		if j.titres.is_empty():
			s += "[i]Aucun pour l'instant. Rendez service, et les gens s'en souviendront.[/i]\n"
		for t in j.titres:
			s += "  ✦ %s\n" % str(t)
	s += "\n[font_size=24][color=#ffd27a][b]Statistiques[/b][/color][/font_size]\n"
	var ctx: Dictionary = main._npc_ctx_v31()
	var tr: Dictionary = ctx.get("trouvailles", {})
	var t2: Node = main.get("temps_v56")
	var met: int = _met_list().size()
	s += "Jours passés : %d   •   Personnages rencontrés : %d\n" % [int(t2.day_count) if t2 != null else 1, met]
	s += "Poissons pêchés : %d   •   Trésors déterrés : %d   •   Arbres abattus : %d\n" % [int((ctx.get("peche", {}) as Dictionary).get("total", 0)), int(tr.get("tresors", 0)), int(tr.get("arbres", 0))]
	if j != null:
		var l2: Dictionary = j.listing()
		s += "Quêtes accomplies : %d   •   en cours : %d\n" % [(l2["accomplies"] as Array).size(), (l2["en_cours"] as Array).size()]
	if main.game_menu != null:
		var secs: int = int(main.game_menu.seconds)
		s += "Temps de jeu : %d h %02d min\n" % [secs / 3600, (secs / 60) % 60]
	return s


# =================================================================== VR : panneau et laser

func _build_vr_panel() -> void:
	panel3d = MeshInstance3D.new()
	panel3d.name = "Carnet_VR"
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 0.96)
	panel3d.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = viewport.get_texture()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	panel3d.material_override = m
	panel3d.visible = false
	add_child(panel3d)
	laser = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.002
	cm.bottom_radius = 0.004
	cm.height = 1.0
	laser.mesh = cm
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1.0, 0.85, 0.4, 0.8)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laser.material_override = lm
	laser.visible = false
	add_child(laser)
	cursor = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	cursor.mesh = sm
	cursor.material_override = lm
	cursor.visible = false
	add_child(cursor)


func _place_vr() -> void:
	if main == null or main.xr_camera == null or panel3d == null:
		return
	var head: Transform3D = main.xr_camera.global_transform
	var fwd: Vector3 = -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	panel3d.global_position = head.origin + fwd * 1.05 + Vector3.DOWN * 0.1
	panel3d.look_at(head.origin, Vector3.UP)
	panel3d.rotate_object_local(Vector3.UP, PI)


## Laser de la main droite : on vise le panneau, la gâchette clique, le stick fait défiler.
func _vr_pointer(delta: float) -> void:
	var hand: Node3D = main.right_hand
	if hand == null or panel3d == null:
		return
	var o: Vector3 = hand.global_position
	var d: Vector3 = -hand.global_basis.z
	var plane_n: Vector3 = panel3d.global_basis.z
	var denom: float = d.dot(plane_n)
	var hit: Vector3 = Vector3.INF
	if absf(denom) > 0.0001:
		var t: float = (panel3d.global_position - o).dot(plane_n) / denom
		if t > 0.0 and t < 4.0:
			hit = o + d * t
	var length: float = 1.5
	var uv := Vector2(-1, -1)
	if hit != Vector3.INF:
		var local: Vector3 = panel3d.global_transform.affine_inverse() * hit
		uv = Vector2(local.x / 1.6 + 0.5, 0.5 - local.y / 0.96)
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			length = o.distance_to(hit)
			cursor.global_position = hit
			cursor.visible = true
		else:
			uv = Vector2(-1, -1)
			cursor.visible = false
	else:
		cursor.visible = false
	laser.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP) * Basis(Vector3.RIGHT, -PI / 2.0), o + d * length * 0.5)
	laser.scale = Vector3(1, length, 1)
	if uv.x < 0.0:
		return
	var px := Vector2(uv.x * UI_W, uv.y * UI_H)
	if px.distance_to(_vr_last) > 0.5:
		var mm := InputEventMouseMotion.new()
		mm.position = px
		mm.global_position = px
		mm.relative = px - _vr_last if _vr_last.x >= 0.0 else Vector2.ZERO
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT if _vr_trigger_down else 0
		viewport.push_input(mm)
		_vr_last = px
	var trig: bool = main.right_hand.get_float("trigger") > 0.7
	if trig != _vr_trigger_down:
		_vr_trigger_down = trig
		var mb := InputEventMouseButton.new()
		mb.position = px
		mb.global_position = px
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = trig
		mb.button_mask = MOUSE_BUTTON_MASK_LEFT if trig else 0
		viewport.push_input(mb)
	var sy: float = main.right_hand.get_vector2("primary").y
	if absf(sy) > 0.4:
		_vr_scroll_acc += delta * absf(sy) * 8.0
		if _vr_scroll_acc >= 1.0:
			_vr_scroll_acc = 0.0
			for pressed in [true, false]:
				var w := InputEventMouseButton.new()
				w.position = px
				w.global_position = px
				w.button_index = MOUSE_BUTTON_WHEEL_UP if sy > 0.0 else MOUSE_BUTTON_WHEEL_DOWN
				w.pressed = pressed
				viewport.push_input(w)
	else:
		_vr_scroll_acc = 0.0


# =================================================================== actions des boutons

func _set_q_filter(f: String) -> void:
	_q_filter = f
	_q_selected = ""
	_refresh_quests()


func _select_quest(id: String) -> void:
	_q_selected = id
	_refresh_quests()


func _quest_on_map() -> void:
	_map_focus_quest = _q_selected
	open_tab(2)


func _set_map_mode(m: String) -> void:
	_map_mode = m
	_map.set_mode(m)
	_refresh_map()


func _set_region(r: String) -> void:
	_p_region = r
	_refresh_people()


func _select_person(id: String) -> void:
	_p_selected = id
	_refresh_people()


func _person_on_map() -> void:
	if _p_selected != "":
		_map.focus_npc(_p_selected)
		open_tab(2)

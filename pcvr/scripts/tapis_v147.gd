extends Node3D
## V147 : le tapis de jeu, la fenêtre des tables de Pile-ou-Face (la même pour tous les jeux).
## Un titre, quelques lignes (la mise, les dés, ce qui vient de se passer), puis des lignes à choisir :
## des boutons (« Lancer ! », « Menteur ! », « Se lever ») et des réglages (la mise, la quantité, la face)
## qu'on fait varier.
## PC : un panneau à droite de l'écran ; la souris (les flèches ◂ ▸, les boutons), ou le clavier :
## ↑ ↓ (ou Z/W, S) pour choisir, ← → (ou Q/A, D) pour régler, Entrée / Espace / E pour valider,
## les chiffres 1 à 9 pour un bouton, Échap pour se lever.
## VR : un panneau au-dessus de la table ; le stick droit (haut, bas : choisir ; gauche, droite : régler),
## la gâchette pour valider, le bouton B pour se lever.
## Les textes passent par langue_v104 (les phrases et les motifs avec leurs nombres).

signal choisi(id: String, valeurs: Dictionary)

const Langue = preload("res://scripts/langue_v104.gd")
const VERT := Color(0.09, 0.22, 0.14, 0.94)
const OR := Color(0.98, 0.84, 0.48)

var opened: bool = false
var xr_mode: bool = false
var titre: String = ""
var lignes: Array = []
var rangs: Array = []              # {id, label, kind ("bouton", "valeur"), value, min, max, step, noms}
var sel: int = 0
var _layer: CanvasLayer
var _panel: PanelContainer
var _vbox: VBoxContainer
var _vr: Node3D
var _vr_text: Label3D
var _vr_fond: MeshInstance3D
var _stick_ready: bool = true
var _trig_ready: bool = false
var _b_ready: bool = false
var _mouse_avant: int = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 22
	_layer.visible = false
	add_child(_layer)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = VERT
	sb.border_color = Color(0.55, 0.38, 0.18)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -560
	_panel.offset_right = -24
	_panel.offset_top = -260
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_layer.add_child(_panel)
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(_vbox)
	_vr = Node3D.new()
	_vr.visible = false
	add_child(_vr)
	_vr_fond = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.7)
	_vr_fond.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = VERT
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_vr_fond.material_override = m
	_vr.add_child(_vr_fond)
	_vr_text = Label3D.new()
	_vr_text.pixel_size = 0.0011
	_vr_text.font_size = 40
	_vr_text.outline_size = 6
	_vr_text.width = 780
	_vr_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vr_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vr_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_vr_text.no_depth_test = true
	_vr_text.position = Vector3(0, 0, 0.005)
	_vr.add_child(_vr_text)


func ouvrir(t: String, vr: bool) -> void:
	titre = t
	xr_mode = vr
	if not opened:
		_mouse_avant = Input.mouse_mode
	opened = true
	sel = 0
	_layer.visible = not vr
	_vr.visible = vr
	if not vr:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_trig_ready = false
	_b_ready = false


func fermer() -> void:
	if not opened:
		return
	opened = false
	_layer.visible = false
	_vr.visible = false
	if not xr_mode:
		Input.mouse_mode = _mouse_avant as Input.MouseMode


## Le panneau VR : face au joueur, au-dessus de la table.
func placer_vr(at: Vector3, regard: Vector3) -> void:
	var d := Vector3(regard.x, 0, regard.z).normalized()
	if d.length() < 0.1:
		d = Vector3(0, 0, -1)
	_vr.global_transform = Transform3D(Basis.looking_at(-d, Vector3.UP), at)


## Le contenu : les lignes (texte), les rangs (à choisir). On garde la sélection si possible.
func montrer(l: Array, r: Array) -> void:
	var ancien: String = str(rangs[sel]["id"]) if sel < rangs.size() else ""
	lignes = l
	rangs = r
	sel = 0
	for i in range(rangs.size()):
		if str(rangs[i]["id"]) == ancien:
			sel = i
	_refaire()


func valeurs() -> Dictionary:
	var v := {}
	for r in rangs:
		if str(r.get("kind", "bouton")) == "valeur":
			v[str(r["id"])] = int(r["value"])
	return v


func _t(s: String) -> String:
	return Langue.t(s)


func _val_txt(r: Dictionary) -> String:
	var v: int = int(r["value"])
	var noms: Array = r.get("noms", [])
	if not noms.is_empty():
		return _t(str(noms[clampi(v - int(r.get("min", 0)), 0, noms.size() - 1)]))
	return str(v)


func _refaire() -> void:
	# le panneau de l'écran
	for c in _vbox.get_children():
		c.queue_free()
	var tl := Label.new()
	tl.text = _t(titre)
	tl.add_theme_font_size_override("font_size", 28)
	tl.add_theme_color_override("font_color", OR)
	tl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_vbox.add_child(tl)
	for s in lignes:
		var l := Label.new()
		l.text = _t(str(s))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(500, 0)
		l.add_theme_font_size_override("font_size", 19)
		l.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_vbox.add_child(l)
	var sep := HSeparator.new()
	_vbox.add_child(sep)
	var nb: int = 0
	for i in range(rangs.size()):
		var r: Dictionary = rangs[i]
		var on: bool = i == sel
		if str(r.get("kind", "bouton")) == "valeur":
			var h := HBoxContainer.new()
			var moins := Button.new()
			moins.text = "◂"
			moins.custom_minimum_size = Vector2(44, 36)
			moins.pressed.connect(func(): sel = i; regler(-1))
			var lab := Label.new()
			lab.text = "%s : %s" % [_t(str(r["label"])), _val_txt(r)]
			lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lab.add_theme_font_size_override("font_size", 21)
			lab.add_theme_color_override("font_color", OR if on else Color(0.9, 0.9, 0.85))
			lab.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			var plus := Button.new()
			plus.text = "▸"
			plus.custom_minimum_size = Vector2(44, 36)
			plus.pressed.connect(func(): sel = i; regler(1))
			h.add_child(moins)
			h.add_child(lab)
			h.add_child(plus)
			_vbox.add_child(h)
		else:
			nb += 1
			var b := Button.new()
			b.text = "%d. %s" % [nb, _t(str(r["label"]))] if nb <= 9 else _t(str(r["label"]))
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.custom_minimum_size = Vector2(0, 38)
			b.add_theme_font_size_override("font_size", 20)
			if on:
				b.add_theme_color_override("font_color", OR)
				b.add_theme_color_override("font_hover_color", OR)
			b.disabled = bool(r.get("off", false))
			b.pressed.connect(func(): sel = i; valider())
			_vbox.add_child(b)
	# le panneau VR (un seul texte)
	var t := "[ " + _t(titre) + " ]\n"
	for s2 in lignes:
		t += _t(str(s2)) + "\n"
	t += "\n"
	for j in range(rangs.size()):
		var r2: Dictionary = rangs[j]
		var mark: String = "▶ " if j == sel else "   "
		if str(r2.get("kind", "bouton")) == "valeur":
			t += "%s%s : ◂ %s ▸\n" % [mark, _t(str(r2["label"])), _val_txt(r2)]
		else:
			t += mark + _t(str(r2["label"])) + ("" if not bool(r2.get("off", false)) else " (—)") + "\n"
	_vr_text.text = t
	var nl: int = t.count("\n") + 2
	(_vr_fond.mesh as QuadMesh).size = Vector2(0.92, maxf(0.3, nl * 0.052 + 0.08))
	_vr_text.position = Vector3(-0.43, (_vr_fond.mesh as QuadMesh).size.y * 0.5 - 0.04, 0.005)


func choisir(d: int) -> void:
	if rangs.is_empty():
		return
	sel = (sel + d + rangs.size()) % rangs.size()
	_refaire()


func regler(d: int) -> void:
	if sel >= rangs.size():
		return
	var r: Dictionary = rangs[sel]
	if str(r.get("kind", "bouton")) != "valeur":
		return
	var step: int = int(r.get("step", 1))
	var v: int = clampi(int(r["value"]) + d * step, int(r.get("min", 0)), int(r.get("max", 99)))
	if v == int(r["value"]):
		return
	r["value"] = v
	if r.has("change"):
		(r["change"] as Callable).call(v)
	else:
		_refaire()


func valider() -> void:
	if sel >= rangs.size():
		return
	var r: Dictionary = rangs[sel]
	if str(r.get("kind", "bouton")) == "valeur" or bool(r.get("off", false)):
		return
	choisi.emit(str(r["id"]), valeurs())


## Le clavier (PC). Rend true si la touche a servi.
func touche(e: InputEventKey) -> bool:
	if not opened or not e.pressed:
		return false
	match e.keycode:
		KEY_UP, KEY_W, KEY_Z:
			choisir(-1)
		KEY_DOWN, KEY_S:
			choisir(1)
		KEY_LEFT, KEY_A, KEY_Q:
			regler(-1)
		KEY_RIGHT, KEY_D:
			regler(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
			valider()
		KEY_ESCAPE:
			choisi.emit("lever", valeurs())
		_:
			var n: int = e.keycode - KEY_1 + 1
			if e.keycode >= KEY_KP_1 and e.keycode <= KEY_KP_9:
				n = e.keycode - KEY_KP_1 + 1
			if n >= 1 and n <= 9:
				var k: int = 0
				for i in range(rangs.size()):
					if str(rangs[i].get("kind", "bouton")) != "valeur":
						k += 1
						if k == n:
							sel = i
							valider()
							return true
			return false
	return true


## La VR : le stick droit, la gâchette, le bouton B.
func vr_tick(stick: Vector2, trig: float, b: bool) -> void:
	if not opened:
		return
	if stick.length() < 0.35:
		_stick_ready = true
	elif _stick_ready:
		_stick_ready = false
		if absf(stick.y) > absf(stick.x):
			choisir(-1 if stick.y > 0.0 else 1)
		else:
			regler(1 if stick.x > 0.0 else -1)
	if trig < 0.3:
		_trig_ready = true
	elif trig > 0.8 and _trig_ready:
		_trig_ready = false
		valider()
	if not b:
		_b_ready = true
	elif _b_ready:
		_b_ready = false
		choisi.emit("lever", valeurs())

extends Node
## V96 : le « Turbo-Aventure 3000 » de Monsieur Fil, le marchand de programmes des Ruelles de Néopolis.
## Si on le lui achète, il le copie dans le carnet de voyage… et c'est un virus (un faux, bien sûr :
## il fait partie du jeu). L'installation déraille, tout l'écran devient bleu comme un vieil
## ordinateur en panne (aucun nom ni logo de vraie marque), puis, au bout de quelques secondes, une
## carte du jeu rassure : ce n'est pas un vrai virus, l'ordinateur (ou le casque) va très bien.
## Pour s'en débarrasser, trois verrous, sur un faux bureau où Grigri, le virus, fait le malin :
##  1. les fenêtres surprises : en fermer huit avec leur petite croix (le gros bouton qui brille en
##     fait apparaître deux autres) ;
##  2. la combinaison de couleurs : répéter les séquences du virus (3, 4 puis 5 couleurs) ;
##  3. les circuits : tourner les tuiles pour relier la pile à l'antivirus.
## Glitch, la hackeuse des Arcades, entre dans le système et aide par une fenêtre de discussion.
## Le virus vaincu, on revient au jeu (neo_v94.state["virus"] = 2 : l'étape « etat » virus_neo de la
## quête ne_virus_fil). Une fois la carte lue, Échap (VR : Y ou B ; manette : B) met en pause : Glitch
## rouvre le système là où on en était (neo_v94.state["virus_pas"]).
## PC : une couche plein écran ; VR : un grand panneau devant les yeux, visé au laser de la main droite.

const UI_W: int = 1600
const UI_H: int = 960
const VR_W: float = 2.0
const VR_H: float = 1.2
const VR_DIST: float = 1.2
const SYMBOLS := "res://assets/fonts/DejaVuSans.ttf"
const BLEU := Color(0.07, 0.33, 0.68)
const NUIT := Color(0.035, 0.04, 0.09)
const OR := Color(0.98, 0.76, 0.32)
const INK := Color(0.94, 0.95, 0.92)
const DIM := Color(0.7, 0.8, 0.88)
const CARTE := Color(0.025, 0.08, 0.125, 0.97)
const ROSE := Color(1.0, 0.3, 0.8)
const VERT := Color(0.35, 1.0, 0.45)
const CHAT := Rect2(1096, 628, 486, 262)
const OBJECTIF_POP: int = 8
const SIMON_LONGUEURS := [3, 4, 5]
const SIMON_C := [Color(0.1, 0.8, 1.0), Color(1.0, 0.25, 0.7), Color(1.0, 0.82, 0.12), Color(0.3, 0.95, 0.35)]
const SIMON_NOMS := ["bleu", "rose", "jaune", "vert"]
const SIMON_F := [392.0, 523.25, 659.25, 783.99]
const PCOLS: int = 6
const PROWS: int = 4
const TUILE: float = 100.0
const POP_COULEURS := [Color(1.0, 0.2, 0.55), Color(1.0, 0.55, 0.0), Color(0.55, 0.2, 1.0), Color(0.0, 0.7, 0.45), Color(0.95, 0.1, 0.1), Color(0.1, 0.5, 1.0)]

const POPUPS := [
	["FÉLICITATIONS !!!", "Tu es le 1 000 000e visiteur de ton propre carnet !", "MON CADEAU !"],
	["TON CARNET EST LENT", "Ton carnet est très, très lent. Clique ici pour l'accélérer (promis).", "ACCÉLÉRER !"],
	["GAGNANT !", "Tu as gagné un poney en chocolat. Il fond vite : dépêche-toi !", "JE LE VEUX !"],
	["NOUVEAU MESSAGE", "Mamie Kiku t'a envoyé un message ! (Non. Mais clique quand même.)", "LIRE !"],
	["PLUS DE MÉMOIRE", "Télécharge plus de mémoire pour ton carnet. Gratuit* !  *pas gratuit", "TÉLÉCHARGER !"],
	["ALERTE !", "Ton sac est plein de virus ! (Ça, c'est vrai. C'est moi.)", "RÉPARER !"],
	["SUPER AFFAIRE", "Un frigo qui chante l'opéra, livré ce soir par drone !", "COMMANDER !"],
	["MISE À JOUR", "Ton chat a besoin d'une mise à jour. Tu n'as pas de chat ? Il en a besoin quand même.", "METTRE À JOUR !"],
	["OFFRE EXCLUSIVE", "Achète un virus, le deuxième est OFFERT !", "J'EN VEUX DEUX !"],
	["TU AS GAGNÉ !", "Une île entière ! Avec des palmiers ! Et des moustiques !", "OUI, OUI, OUI !"],
	["SONDAGE", "Aimes-tu les fenêtres surprises ? Clique « oui » pour en avoir plus.", "OUI !"],
	["DERNIÈRE CHANCE", "Cette fenêtre va disparaître dans 3… 2… (non, elle reste).", "NE PAS RATER !"],
]

const GLITCH := {
	"bonjour": "Psst ! C'est Glitch, des Arcades. J'ai vu le « programme » de Monsieur Fil sauter dans ton carnet. Je suis entrée dans le système pour t'aider. Ce virus est protégé par trois verrous : on les casse un par un !",
	"reprise": "Re-salut ! Je t'ai rouvert le système. Le virus n'a pas bougé : il boude dans son coin. On reprend là où tu t'étais arrêté !",
	"pop": "Premier verrou : ses fenêtres surprises. Ferme-les avec la petite croix ✕, en haut à droite de chaque fenêtre. Il en faut huit !",
	"pop_piege": "Non ! Pas le gros bouton qui brille ! C'est toujours un piège : il fait apparaître d'autres fenêtres. Seulement la petite croix ✕.",
	"simon": "Deuxième verrou : sa combinaison de couleurs. Regarde dans quel ordre les carrés s'allument, puis clique dessus dans le même ordre.",
	"simon_aide": "Astuce : dis les couleurs à voix haute pendant qu'elles s'allument. « Bleu, rose, jaune… » Ça se retient tout seul !",
	"tuyaux": "Dernier verrou ! Le virus a débranché l'antivirus. Clique sur les tuiles pour les tourner, et refais le chemin entre la pile ⚡ et l'antivirus ✚.",
	"tuyaux_aide": "Les tuyaux qui s'allument en bleu sont déjà reliés à la pile. Pars de la pile, à gauche, et avance une tuile à la fois.",
	"bravo_0": "Un verrou de moins ! Regarde-le, il commence à transpirer.",
	"bravo_1": "Et de deux ! Plus qu'un, et on le met à la corbeille.",
	"fin": "C'est fini ! Je l'ai poussé dans la corbeille, et j'ai vidé la corbeille. Viens me voir, j'ai deux mots à dire à Monsieur Fil…",
}

const TAUNTS := {
	"bonjour": ["Bonjour ! Je suis Grigri, le virus le moins cher du monde !"],
	"pop": ["Des cadeaux ! Des cadeaux pour tout le monde !", "Regarde toutes ces belles fenêtres !"],
	"piege": ["Hi hi hi ! Encore des fenêtres !", "Merci d'avoir cliqué !", "Tu as gagné… deux fenêtres de plus !"],
	"verrou": ["Hé ! Rends-moi mes fenêtres !", "Mes couleurs ! Tu as volé mes couleurs !"],
	"simon": ["Tu ne retiendras jamais ma combinaison !", "Bleu ? Rose ? Hi hi, devine !"],
	"rate": ["Raté ! Hi hi !", "Même pas pareil !", "Perdu ! Je reste !"],
	"tuyaux": ["Mes tuyaux ! Ne touche pas à mes tuyaux !", "Je les ai bien emmêlés, hein ?"],
	"idle": ["Tu ne m'attraperas jamais !", "Je suis le meilleur programme de Monsieur Fil. Le seul, en fait.", "J'adore ton carnet. Je vais m'installer dans le sac.", "Bip ! Je fais comme Zéro. Bip !"],
	"fin": ["Non ! Non ! Pas la corbeille !"],
}

var main: Node
var neo: Node
var xr: bool = false
var built: bool = false
var opened: bool = false
var phase: String = ""                     # install, bsod, bureau, fini
var pas: int = 0                           # le verrou en cours (0, 1, 2 ; 3 : fini)
var can_pause: bool = false
var layer: CanvasLayer
var viewport: SubViewport
var bg: ColorRect
var holder: Control
var root: Control
var panel3d: MeshInstance3D
var laser: MeshInstance3D
var cursor: MeshInstance3D
var _players: Array = []
var _pi: int = 0
var _sounds: Dictionary = {}
var _fonts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0
var _gen: int = 0                          # chaque écran a son numéro (les minuteries d'un écran fermé s'éteignent)
var _vr_last := Vector2(-1, -1)
var _vr_trigger_down: bool = false
var _vr_back: bool = true
# l'installation et l'écran bleu
var _inst_label: Label
var _inst_fill: ColorRect
var _inst_pct: Label
var _flicker: Array = []
var _glitched: bool = false
var _bsod_pct: Label
var _card: Control
# le bureau
var _zone: Control
var _virus: Grigri
var _bulle: PanelContainer
var _bulle_txt: Label
var _bulle_t: float = 0.0
var _idle_t: float = 9.0
var _chat_log: RichTextLabel
var _locks: Array = []
var _counter: Label
var _clock_lbl: Label
var _corbeille := Vector2.ZERO
# 1 : les fenêtres surprises
var _pops: Array = []
var _pop_closed: int = 0
var _pop_t: float = 0.0
var _pop_traps: int = 0
var _pop_seen: Array = []
# 2 : la combinaison de couleurs
var _pads: Array = []                      # [Button, StyleBoxFlat]
var _pad_flash: Array = [0.0, 0.0, 0.0, 0.0]
var _simon_seq: Array = []
var _simon_round: int = 0
var _simon_in: int = 0
var _simon_err: int = 0
var _simon_listen: bool = false
var _simon_queue: Array = []
var _simon_idx: int = 0
var _simon_play_t: float = -1.0
var _simon_status: Label
var _simon_manche: Label
# 3 : les circuits
var _masks: Array = []
var _tiles: Array = []                     # Tuile
var _r0: int = 0
var _r1: int = 0
var _tuyaux_t: float = 0.0
var _tuyaux_aide: bool = false
var _tuyaux_ok: bool = false


# =================================================================== petites pièces de dessin

## Une tuile de circuit : les tuyaux partent du centre vers les côtés ouverts (N=1, E=2, S=4, O=8).
class Tuile extends Control:
	var m: int = 0
	var lit: bool = false

	func _draw() -> void:
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(0.07, 0.09, 0.15), true)
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(0.2, 0.25, 0.4), false, 2.0)
		var c: Vector2 = size * 0.5
		var col: Color = Color(0.2, 0.92, 1.0) if lit else Color(0.42, 0.45, 0.52)
		var w: float = 20.0
		for e in [[1, Vector2(0, -1)], [2, Vector2(1, 0)], [4, Vector2(0, 1)], [8, Vector2(-1, 0)]]:
			if m & int(e[0]):
				draw_line(c, c + (e[1] as Vector2) * size.x * 0.5, col, w)
				if lit:
					draw_line(c, c + (e[1] as Vector2) * size.x * 0.5, Color(0.85, 1.0, 1.0), 6.0)
		draw_circle(c, w * 0.5 + 3.0, col)
		if lit:
			draw_circle(c, 5.0, Color(0.85, 1.0, 1.0))


## Grigri, le virus : une boule verte à antennes, qui sautille, fait le malin… et a peur à la fin.
class Grigri extends Control:
	var t: float = 0.0
	var peur: bool = false

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.55 + sin(t * (9.0 if peur else 3.0)) * (3.0 if peur else 6.0))
		var vert := Color(0.45, 0.95, 0.3)
		var fonce := Color(0.18, 0.55, 0.15)
		for i in range(6):
			var a: float = PI * (0.15 + 0.14 * i)
			var p0: Vector2 = c + Vector2(cos(a), sin(a)) * 40.0
			draw_line(p0, p0 + Vector2(cos(a), sin(a)) * 18.0 + Vector2(0, sin(t * 8.0 + i) * 3.0), fonce, 6.0)
		for sx in [-1.0, 1.0]:
			var base: Vector2 = c + Vector2(sx * 18.0, -38.0)
			var tip: Vector2 = base + Vector2(sx * 14.0 + sin(t * 4.0) * 4.0, -30.0)
			draw_line(base, tip, fonce, 4.0)
			draw_circle(tip, 7.0, Color(1.0, 0.35, 0.75))
		draw_circle(c, 46.0, vert)
		draw_circle(c + Vector2(-20, 18), 7.0, fonce)
		draw_circle(c + Vector2(24, 22), 5.0, fonce)
		draw_circle(c + Vector2(28, -24), 4.0, fonce)
		for sx2 in [-1.0, 1.0]:
			var e: Vector2 = c + Vector2(sx2 * 16.0, -10.0)
			draw_circle(e, 12.0 if peur else 11.0, Color.WHITE)
			var look := Vector2(sin(t * 1.3) * 3.0, 2.0) if not peur else Vector2(0, -2)
			draw_circle(e + look, 5.5, Color(0.05, 0.05, 0.08))
		if peur:
			draw_circle(c + Vector2(0, 20), 10.0, Color(0.1, 0.05, 0.05))
		else:
			draw_arc(c + Vector2(0, 8), 20.0, 0.25, PI - 0.25, 16, Color(0.1, 0.05, 0.05), 5.0)
			draw_rect(Rect2(c + Vector2(-6, 26), Vector2(6, 7)), Color.WHITE, true)


## Le petit dessin en pixels de l'écran bleu (à la place d'un code) : la tête de Grigri.
class Pixels extends Control:
	const P := ["..X...X..", "...X.X...", "..XXXXX..", ".XX.X.XX.", "XXXXXXXXX", "X.XXXXX.X", "X.X...X.X", "...XX.XX.", "........."]

	func _draw() -> void:
		var k: float = size.x / 9.0
		for j in range(P.size()):
			var row: String = P[j]
			for i in range(row.length()):
				if row[i] == "X":
					draw_rect(Rect2(Vector2(i, j) * k, Vector2(k, k) * 0.92), Color.WHITE, true)


# =================================================================== mise en place

func setup(main_node: Node, neo_node: Node) -> void:
	main = main_node
	neo = neo_node
	_rng.randomize()


func _ensure_built() -> void:
	if built:
		return
	built = true
	xr = bool(main.get("xr_active")) if main != null and main.get("xr_active") != null else false
	var sym: Font = load(SYMBOLS) if ResourceLoader.exists(SYMBOLS) else null
	for k in ["Regular", "Bold", "Italic"]:
		var p: String = "res://assets/fonts/Lora-%s.ttf" % k
		if ResourceLoader.exists(p):
			var f: Font = load(p)
			if sym != null and not f.fallbacks.has(sym):
				f.fallbacks = f.fallbacks + [sym]
			_fonts[k] = f
	var def: Font = ThemeDB.fallback_font
	if sym != null and def != null and not def.fallbacks.has(sym):
		def.fallbacks = def.fallbacks + [sym]
	root = Control.new()
	root.name = "Virus_v96"
	root.size = Vector2(UI_W, UI_H)
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	if xr:
		viewport = SubViewport.new()
		viewport.size = Vector2i(UI_W, UI_H)
		viewport.transparent_bg = false
		viewport.gui_embed_subwindows = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		viewport.add_child(root)
		_build_vr_panel()
	else:
		layer = CanvasLayer.new()
		layer.layer = 20
		layer.visible = false
		add_child(layer)
		bg = ColorRect.new()
		bg.color = NUIT
		bg.mouse_filter = Control.MOUSE_FILTER_STOP
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(bg)
		holder = Control.new()
		holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(holder)
		holder.add_child(root)
		holder.resized.connect(_fit_pc)
		_fit_pc.call_deferred()
	for i in range(4):
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -7.0
		add_child(ap)
		_players.append(ap)
	_make_sounds()


func _fit_pc() -> void:
	if holder == null:
		return
	var s: Vector2 = holder.size
	if s.x < 10.0:
		return
	var k: float = minf(s.x / UI_W, s.y / UI_H)
	root.scale = Vector2(k, k)
	root.position = (s - Vector2(UI_W, UI_H) * k) * 0.5


func _set_bg(c: Color) -> void:
	if bg != null:
		bg.color = c
	var r := ColorRect.new()
	r.color = c
	r.size = Vector2(UI_W, UI_H)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(r)


# =================================================================== ouvrir, fermer

## mode : "start" (juste après l'achat) ou "resume" (Glitch rouvre le système).
func begin(mode: String = "start") -> void:
	if opened or main == null:
		return
	_ensure_built()
	pas = clampi(int(neo.state.get("virus_pas", 0)) if neo != null else 0, 0, 2)
	opened = true
	_vr_back = true
	_vr_trigger_down = false
	_vr_last = Vector2(-1, -1)
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if xr:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		panel3d.visible = true
		laser.visible = true
		_place_vr()
	else:
		layer.visible = true
		_fit_pc()
	if mode == "resume":
		_phase_bureau(true)
	else:
		_phase_install()


func _close() -> void:
	opened = false
	phase = ""
	can_pause = false
	_clear()
	if xr and viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		panel3d.visible = false
		laser.visible = false
		cursor.visible = false
	elif layer != null:
		layer.visible = false


## Échap, B ou Y : une pause (après la carte qui rassure ; pas pendant la victoire).
func pause() -> void:
	if not opened or not can_pause or phase != "bureau":
		return
	if neo != null:
		neo.state["virus_pas"] = pas
	_close()
	main.sfx("ui_fermer")
	main._show_message_v28("Pause : le virus attend dans ton carnet. Glitch (près de la Station des Arcades le matin et le soir, dans la salle d'arcade l'après-midi) t'aidera à reprendre.")


## Fermé sans rien changer (une partie chargée, un nouveau départ).
func reset() -> void:
	if opened:
		_close()


func _finish() -> void:
	if neo != null:
		neo.state["virus"] = 2
		neo.state["virus_pas"] = 3
	_close()
	main.sfx("ui_quete")
	main._show_message_v28("Le virus est parti ! Glitch t'attend (près de la Station des Arcades, ou dans la salle d'arcade l'après-midi).")


func _clear() -> void:
	_gen += 1
	if root != null:
		for c in root.get_children():
			c.queue_free()
	_card = null
	_zone = null
	_virus = null
	_bulle = null
	_chat_log = null
	_pops.clear()
	_pads.clear()
	_tiles.clear()
	_flicker.clear()
	_locks.clear()
	_simon_play_t = -1.0
	_simon_listen = false


## Une action plus tard, si l'écran n'a pas changé entre-temps.
func _later(sec: float, cb: Callable) -> void:
	var g: int = _gen
	get_tree().create_timer(sec).timeout.connect(func():
		if opened and g == _gen:
			cb.call())


func _input(event: InputEvent) -> void:
	if not opened:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			pause()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not opened:
		return
	_t += delta
	if xr:
		_vr_pointer()
		var back: bool = main.left_hand.is_button_pressed("by_button") or main.right_hand.is_button_pressed("by_button")
		if back and not _vr_back:
			pause()
		_vr_back = back
		_follow_head(delta)
	match phase:
		"install":
			_install_tick()
		"bsod":
			_bsod_tick()
		"bureau":
			_bureau_tick(delta)


# =================================================================== petits outils d'interface

func _box(bgc: Color, border: Color, radius: int = 10, width: int = 2, margin: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bgc
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


func _lbl(parent: Control, text: String, size: int, color: Color, pos: Vector2, width: float = 0.0, font: String = "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font != "" and _fonts.has(font):
		l.add_theme_font_override("font", _fonts[font])
	l.position = pos
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
		l.size = Vector2(width, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _btn(parent: Control, text: String, size: int, pos: Vector2, dim: Vector2, bgc: Color, border: Color, fg: Color, cb: Callable, font: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos
	b.size = dim
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _box(bgc, border, 10, 2, 6))
	b.add_theme_stylebox_override("hover", _box(bgc.lightened(0.15), border.lightened(0.3), 10, 3, 6))
	b.add_theme_stylebox_override("pressed", _box(bgc.darkened(0.15), border, 10, 3, 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg.lightened(0.2))
	b.add_theme_color_override("font_pressed_color", fg)
	if font != "" and _fonts.has(font):
		b.add_theme_font_override("font", _fonts[font])
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Une fenêtre du faux système : un cadre, une barre de titre.
func _window(parent: Control, dim: Vector2, pos: Vector2, title: String, body: Color, bar: Color) -> Panel:
	var w := Panel.new()
	w.position = pos
	w.size = dim
	w.add_theme_stylebox_override("panel", _box(body, bar, 6, 2, 0))
	w.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(w)
	var t := ColorRect.new()
	t.color = bar
	t.position = Vector2(2, 2)
	t.size = Vector2(dim.x - 4, 38)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(t)
	_lbl(w, title, 19, Color.WHITE, Vector2(14, 9))
	return w


func _card_style() -> StyleBoxFlat:
	var s := _box(CARTE, OR, 16, 3, 22)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 18
	return s


func _sfx(n: String) -> void:
	var s: AudioStream = _sounds.get(n, null)
	if s == null or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_pi]
	_pi = (_pi + 1) % _players.size()
	p.stream = s
	p.play()


func _pick(group: String) -> String:
	var a: Array = TAUNTS.get(group, [""])
	return str(a[_rng.randi() % a.size()])


# =================================================================== 1. l'installation

func _phase_install() -> void:
	_clear()
	phase = "install"
	_t = 0.0
	can_pause = false
	_glitched = false
	_set_bg(NUIT)
	var w := _window(root, Vector2(780, 330), Vector2((UI_W - 780) * 0.5, 290), "Turbo-Aventure 3000 — installation", Color(0.13, 0.14, 0.18), Color(0.55, 0.12, 0.45))
	_lbl(w, "Turbo-Aventure 3000", 34, Color(1.0, 0.85, 1.0), Vector2(40, 64))
	_lbl(w, "« Il range ton sac, il trouve les trésors, il fait même tes devoirs. » — M. Fil", 17, DIM, Vector2(40, 112), 700)
	_inst_label = _lbl(w, "Préparation…", 22, INK, Vector2(40, 170))
	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.08)
	back.position = Vector2(40, 214)
	back.size = Vector2(700, 30)
	w.add_child(back)
	_inst_fill = ColorRect.new()
	_inst_fill.color = Color(0.85, 0.3, 0.9)
	_inst_fill.position = Vector2(42, 216)
	_inst_fill.size = Vector2(0, 26)
	w.add_child(_inst_fill)
	_inst_pct = _lbl(w, "0 %", 20, INK, Vector2(40, 262))
	_sfx("installe")


func _install_tick() -> void:
	var p: float = clampf(_t / 3.4, 0.0, 1.0)
	if _inst_fill != null and is_instance_valid(_inst_fill):
		_inst_fill.size.x = 696.0 * p
		_inst_pct.text = "%d %%" % int(p * 100.0)
		var steps := ["Copie des trésors…", "Ajout de paillettes…", "Désactivation de la prudence…", "Installation d'un tout petit virus de rien du tout…"]
		_inst_label.text = steps[mini(int(p * 4.0), 3)]
	if _t > 3.5 and not _glitched:
		_glitched = true
		_sfx("glitch")
		# des bandes qui glissent (sans clignoter : rien de dur pour les yeux)
		for i in range(14):
			var r := ColorRect.new()
			r.color = [Color(0.85, 0.2, 0.6), Color(0.2, 0.75, 0.85), Color(0.85, 0.8, 0.25), BLEU, Color(0.85, 0.85, 0.9)][i % 5]
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.position = Vector2(_rng.randf_range(-200, UI_W - 200), _rng.randf_range(0, UI_H))
			r.size = Vector2(_rng.randf_range(120, 600), _rng.randf_range(8, 50))
			r.set_meta("v", _rng.randf_range(-260.0, 260.0))
			root.add_child(r)
			_flicker.append(r)
	if _glitched:
		for r2 in _flicker:
			if is_instance_valid(r2):
				(r2 as ColorRect).position.x += float(r2.get_meta("v")) * get_process_delta_time()
	if _t > 4.3:
		_phase_bsod()


# =================================================================== 2. l'écran bleu, puis la carte qui rassure

func _phase_bsod() -> void:
	_clear()
	phase = "bsod"
	_t = 0.0
	_set_bg(BLEU)
	_lbl(root, ":(", 200, Color.WHITE, Vector2(150, 70))
	_lbl(root, "Ton carnet de voyage a rencontré un problème.\nUn programme « pas cher » a tout mis sens dessus dessous.", 40, Color.WHITE, Vector2(150, 340), 1300)
	_bsod_pct = _lbl(root, "0 % effectué", 38, Color.WHITE, Vector2(150, 500))
	var px := Pixels.new()
	px.position = Vector2(150, 620)
	px.size = Vector2(170, 170)
	px.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(px)
	_lbl(root, "Pour en savoir plus sur ce problème : il ne fallait pas l'acheter.\n\nSi tu appelles un réparateur, donne-lui ces informations :\nCode d'arrêt : PROGRAMME_PAS_CHER_DU_TOUT\nCe qui a échoué : turbo_aventure_3000.prg", 22, Color(0.92, 0.95, 1.0), Vector2(360, 620), 1100)
	_sfx("erreur")


func _bsod_tick() -> void:
	if _bsod_pct != null and is_instance_valid(_bsod_pct):
		_bsod_pct.text = "%d %% effectué" % mini(int(_t * 4.0), 13)
	if _t > 4.0 and _card == null:
		_rassure()


func _rassure() -> void:
	can_pause = true
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _card_style())
	c.position = Vector2(250, 470)
	c.custom_minimum_size = Vector2(1100, 0)
	c.size = Vector2(1100, 0)
	root.add_child(c)
	_card = c
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	c.add_child(v)
	var t := Label.new()
	t.text = "✦  Pas de panique !"
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_color", OR)
	if _fonts.has("Bold"):
		t.add_theme_font_override("font", _fonts["Bold"])
	v.add_child(t)
	var x := Label.new()
	x.text = ("Ce virus est un faux : il fait partie du jeu, c'est la farce du « programme pas cher » de Monsieur Fil. %s va très bien : rien n'a été installé et rien n'est cassé.\nPour débarrasser ton carnet de voyage de ce virus, il suffit de casser ses trois verrous." %
		("Ton vrai casque" if xr else "Ton vrai ordinateur"))
	x.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	x.custom_minimum_size = Vector2(1050, 0)
	x.add_theme_font_size_override("font_size", 27)
	x.add_theme_color_override("font_color", INK)
	if _fonts.has("Regular"):
		x.add_theme_font_override("font", _fonts["Regular"])
	v.add_child(x)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	var b := Button.new()
	b.text = "▶  Chasser le virus"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(340, 60)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _box(Color(0.06, 0.17, 0.24), Color(0.75, 0.6, 0.3), 10, 2, 8))
	b.add_theme_stylebox_override("hover", _box(Color(0.1, 0.25, 0.33), OR, 10, 3, 8))
	b.add_theme_stylebox_override("pressed", _box(Color(0.16, 0.3, 0.36), OR, 10, 3, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	b.pressed.connect(func(): _phase_bureau(false))
	h.add_child(b)
	var hint := Label.new()
	hint.text = "Y ou B : faire une pause" if xr else "Échap (manette : B) : faire une pause"
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_color", DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(hint)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 1.0, 0.5)
	main.sfx("ui_dialogue")


# =================================================================== 3. le bureau et les verrous

func _phase_bureau(resume: bool) -> void:
	_clear()
	phase = "bureau"
	_t = 0.0
	can_pause = true
	_set_bg(NUIT)
	var wall := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.08, 0.2))
	g.set_color(1, Color(0.3, 0.08, 0.32))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0.4, 1)
	gt.width = 64
	gt.height = 64
	wall.texture = gt
	wall.stretch_mode = TextureRect.STRETCH_SCALE
	wall.size = Vector2(UI_W, UI_H)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wall)
	_lbl(root, "NÉOPOLIS", 150, Color(1, 1, 1, 0.05), Vector2(400, 330))
	# les icônes du bureau
	var icons := [["Carnet de voyage", Color(0.6, 0.38, 0.2), "✎"], ["Corbeille", Color(0.55, 0.58, 0.62), "▢"], ["Turbo-Aventure 3000", Color(0.4, 0.85, 0.3), "!"]]
	for i in range(icons.size()):
		var at := Vector2(34, 80 + i * 130)
		var sq := Panel.new()
		sq.position = at + Vector2(22, 0)
		sq.size = Vector2(64, 64)
		sq.add_theme_stylebox_override("panel", _box(icons[i][1], Color(1, 1, 1, 0.6), 10, 2, 0))
		sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(sq)
		_lbl(sq, str(icons[i][2]), 34, Color.WHITE, Vector2(20, 8))
		_lbl(root, str(icons[i][0]), 16, Color.WHITE, at + Vector2(-6, 70), 120).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == 1:
			_corbeille = at + Vector2(54, 32)
	# la barre des tâches
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.06, 0.09, 0.96)
	bar.position = Vector2(0, UI_H - 54)
	bar.size = Vector2(UI_W, 54)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	_lbl(bar, "◈  Menu", 20, INK, Vector2(20, 14))
	_lbl(bar, "▣  Turbo-Aventure 3000 (ne répond pas)", 18, Color(1.0, 0.6, 0.6), Vector2(170, 15))
	_lbl(bar, "Y ou B : pause" if xr else "Échap (manette : B) : pause", 17, DIM, Vector2(1080, 16))
	_clock_lbl = _lbl(bar, "", 20, INK, Vector2(1500, 14))
	# les verrous
	var lk := HBoxContainer.new()
	lk.position = Vector2(560, 16)
	lk.add_theme_constant_override("separation", 14)
	lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lk)
	var tl := Label.new()
	tl.text = "Verrous du virus :"
	tl.add_theme_font_size_override("font_size", 22)
	tl.add_theme_color_override("font_color", INK)
	lk.add_child(tl)
	for i2 in range(3):
		var p := PanelContainer.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 20)
		p.add_child(l)
		lk.add_child(p)
		_locks.append(p)
	_update_locks()
	_counter = _lbl(root, "", 22, OR, Vector2(560, 62), 600)
	# la zone des énigmes (sous Grigri et sous la discussion)
	_zone = Control.new()
	_zone.size = Vector2(UI_W, UI_H)
	_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_zone)
	# Grigri et sa bulle
	_virus = Grigri.new()
	_virus.position = Vector2(1420, 70)
	_virus.size = Vector2(150, 150)
	_virus.pivot_offset = Vector2(75, 80)
	_virus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_virus)
	_bulle = PanelContainer.new()
	_bulle.add_theme_stylebox_override("panel", _box(Color(1, 1, 0.95), Color(0.2, 0.6, 0.15), 14, 3, 12))
	_bulle.position = Vector2(1050, 84)
	_bulle.custom_minimum_size = Vector2(360, 0)
	_bulle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bulle)
	_bulle_txt = Label.new()
	_bulle_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bulle_txt.custom_minimum_size = Vector2(336, 0)
	_bulle_txt.add_theme_font_size_override("font_size", 19)
	_bulle_txt.add_theme_color_override("font_color", Color(0.1, 0.15, 0.08))
	_bulle.add_child(_bulle_txt)
	_bulle.visible = false
	# la discussion avec Glitch
	var chat := _window(root, CHAT.size, CHAT.position, "●  Glitch — discussion privée", Color(0.06, 0.05, 0.1, 0.97), Color(0.75, 0.15, 0.6))
	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.scroll_following = true
	_chat_log.position = Vector2(14, 48)
	_chat_log.size = Vector2(CHAT.size.x - 28, CHAT.size.y - 60)
	_chat_log.add_theme_font_size_override("normal_font_size", 18)
	_chat_log.add_theme_font_size_override("bold_font_size", 18)
	_chat_log.add_theme_color_override("default_color", INK)
	_chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat.add_child(_chat_log)
	_taunt(_pick("bonjour") if not resume else _pick("idle"))
	_glitch(GLITCH["reprise"] if resume else GLITCH["bonjour"])
	_later(1.6 if not resume else 0.8, func(): _start_puzzle(pas))


func _update_locks() -> void:
	for i in range(_locks.size()):
		var p: PanelContainer = _locks[i]
		var ok: bool = i < pas
		p.add_theme_stylebox_override("panel", _box(Color(0.1, 0.45, 0.2) if ok else Color(0.5, 0.08, 0.1), VERT if ok else Color(1, 0.35, 0.35), 8, 2, 8))
		var l: Label = p.get_child(0)
		l.text = ("%d  ✓" % (i + 1)) if ok else ("%d  ✕" % (i + 1))
		l.add_theme_color_override("font_color", Color.WHITE)


func _taunt(text: String) -> void:
	if _bulle == null or not is_instance_valid(_bulle):
		return
	_bulle_txt.text = "Grigri : " + text
	_bulle.visible = true
	_bulle_t = 4.5
	_idle_t = _rng.randf_range(9.0, 14.0)


func _glitch(text: String) -> void:
	if _chat_log == null or not is_instance_valid(_chat_log):
		return
	_chat_log.append_text("[color=#ff70d8][b]Glitch :[/b][/color] " + text + "\n\n")
	_sfx("message")


func _bureau_tick(delta: float) -> void:
	if _clock_lbl != null and is_instance_valid(_clock_lbl):
		var tp: Node = main.get("temps_v56")
		var h: float = float(tp.hour) if tp != null else 12.0
		_clock_lbl.text = "%02d:%02d" % [int(h) % 24, int(fmod(h, 1.0) * 60.0)]
	if _bulle != null and is_instance_valid(_bulle) and _bulle.visible:
		_bulle_t -= delta
		if _bulle_t <= 0.0:
			_bulle.visible = false
	_idle_t -= delta
	if _idle_t <= 0.0:
		_taunt(_pick("idle"))
	if _virus != null and is_instance_valid(_virus) and not _virus.peur:
		_virus.position.x = 1420.0 + sin(_t * 0.7) * 24.0
	match pas:
		0:
			_pop_tick(delta)
		1:
			_simon_tick(delta)
		2:
			_tuyaux_tick(delta)


func _start_puzzle(i: int) -> void:
	if not opened or phase != "bureau":
		return
	_gen += 1
	for c in _zone.get_children():
		c.queue_free()
	_pops.clear()
	_pads.clear()
	_tiles.clear()
	match i:
		0:
			_start_pop()
		1:
			_start_simon()
		2:
			_start_tuyaux()
		_:
			_phase_fini()


func _lock_done(i: int) -> void:
	if pas != i:
		return
	pas = i + 1
	if neo != null:
		neo.state["virus_pas"] = pas
	_update_locks()
	_sfx("verrou")
	if _counter != null:
		_counter.text = ""
	if pas >= 3:
		_later(1.0, _phase_fini)
		return
	_taunt(_pick("verrou"))
	_glitch(GLITCH["bravo_%d" % i])
	_later(1.8, func(): _start_puzzle(pas))


# ------------------------------------------------------------------- verrou 1 : les fenêtres surprises

func _start_pop() -> void:
	_pop_closed = 0
	_pop_traps = 0
	_pop_t = 0.3
	_pop_seen.clear()
	_counter.text = "Fenêtres fermées : 0 / %d" % OBJECTIF_POP
	_glitch(GLITCH["pop"])
	_taunt(_pick("pop"))


func _pop_tick(delta: float) -> void:
	_pops = _pops.filter(func(p): return is_instance_valid(p))
	_pop_t -= delta
	if _pop_t <= 0.0 and _pops.size() < 6 and _pop_closed < OBJECTIF_POP:
		_spawn_pop()
		_pop_t = 1.1
	var k: float = 0.75 + 0.25 * sin(_t * 7.0)
	for p in _pops:
		var big: Button = (p as Control).get_meta("big")
		big.modulate = Color(1.0, 1.0, k + 0.25)


func _spawn_pop() -> void:
	if _zone == null:
		return
	var dim := Vector2(390, 236)
	var at := Vector2.ZERO
	for _i in range(16):
		at = Vector2(_rng.randf_range(160, UI_W - dim.x - 20), _rng.randf_range(110, UI_H - 54 - dim.y - 10))
		if not Rect2(at, dim).intersects(CHAT.grow(8)) and not Rect2(at, dim).intersects(Rect2(1400, 60, 200, 180)):
			break
	if _pop_seen.size() >= POPUPS.size():
		_pop_seen.clear()
	var k: int = _rng.randi() % POPUPS.size()
	while _pop_seen.has(k):
		k = (k + 1) % POPUPS.size()
	_pop_seen.append(k)
	var e: Array = POPUPS[k]
	var col: Color = POP_COULEURS[_rng.randi() % POP_COULEURS.size()]
	var w := _window(_zone, dim, at, "!!! " + str(e[0]) + " !!!", Color(0.97, 0.97, 1.0), col)
	_lbl(w, str(e[1]), 21, Color(0.12, 0.12, 0.18), Vector2(18, 54), dim.x - 36)
	var close := _btn(w, "✕", 22, Vector2(dim.x - 50, 4), Vector2(46, 34), Color(0.7, 0.1, 0.15), Color(1, 1, 1, 0.7), Color.WHITE, func(): _pop_close(w))
	close.name = "Fermer"
	var big := _btn(w, str(e[2]), 24, Vector2(55, 158), Vector2(280, 60), Color(1.0, 0.78, 0.1), Color(1.0, 0.4, 0.0), Color(0.35, 0.1, 0.0), func(): _pop_trap(w))
	big.name = "Gros_bouton"
	w.set_meta("big", big)
	_pops.append(w)
	_sfx("pop")


func _pop_close(w: Control) -> void:
	if not is_instance_valid(w) or w.is_queued_for_deletion():
		return
	w.queue_free()
	_pops.erase(w)
	_pop_closed += 1
	_sfx("clic")
	_counter.text = "Fenêtres fermées : %d / %d" % [mini(_pop_closed, OBJECTIF_POP), OBJECTIF_POP]
	if _pop_closed >= OBJECTIF_POP:
		for p in _pops:
			if is_instance_valid(p):
				p.queue_free()
		_pops.clear()
		_lock_done(0)


func _pop_trap(w: Control) -> void:
	if not is_instance_valid(w):
		return
	_pop_traps += 1
	_sfx("piege")
	_taunt(_pick("piege"))
	if _pop_traps == 1:
		_glitch(GLITCH["pop_piege"])
	for _i in range(2):
		if _pops.size() < 10:
			_spawn_pop()


# ------------------------------------------------------------------- verrou 2 : la combinaison de couleurs

func _start_simon() -> void:
	var w := _window(_zone, Vector2(760, 620), Vector2(240, 108), "Verrou n°2 — la combinaison de couleurs", Color(0.08, 0.08, 0.13, 0.98), Color(0.25, 0.3, 0.75))
	_simon_manche = _lbl(w, "", 22, OR, Vector2(30, 54))
	_simon_status = _lbl(w, "", 22, INK, Vector2(30, 86), 700)
	for i in range(4):
		var sb := _box(SIMON_C[i].darkened(0.6), SIMON_C[i].darkened(0.2), 18, 3, 0)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(60 + (i % 2) * 330, 140 + (i / 2) * 230)
		b.size = Vector2(310, 210)
		b.text = SIMON_NOMS[i]
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.name = "Couleur_%d" % i
		b.pressed.connect(_simon_press.bind(i))
		w.add_child(b)
		_pads.append([b, sb])
	_simon_seq.clear()
	for _j in range(5):
		_simon_seq.append(_rng.randi() % 4)
	_simon_round = 0
	_simon_err = 0
	_glitch(GLITCH["simon"])
	_taunt(_pick("simon"))
	_later(1.4, _simon_play)


func _simon_play() -> void:
	_simon_listen = false
	_simon_in = 0
	_simon_queue = _simon_seq.slice(0, SIMON_LONGUEURS[_simon_round])
	_simon_idx = 0
	_simon_play_t = 0.5
	_simon_manche.text = "Manche %d / %d" % [_simon_round + 1, SIMON_LONGUEURS.size()]
	_simon_status.text = "Regarde bien la séquence du virus…"


func _simon_flash(i: int, sec: float) -> void:
	_pad_flash[i] = sec
	_sfx("note_%d" % i)


func _simon_tick(delta: float) -> void:
	for i in range(mini(4, _pads.size())):
		_pad_flash[i] = maxf(0.0, _pad_flash[i] - delta)
		var sb: StyleBoxFlat = _pads[i][1]
		sb.bg_color = SIMON_C[i] if _pad_flash[i] > 0.0 else SIMON_C[i].darkened(0.6)
		sb.border_color = Color.WHITE if _pad_flash[i] > 0.0 else SIMON_C[i].darkened(0.2)
		(_pads[i][0] as Button).queue_redraw()
	if _simon_play_t >= 0.0:
		_simon_play_t -= delta
		if _simon_play_t < 0.0:
			if _simon_idx < _simon_queue.size():
				_simon_flash(int(_simon_queue[_simon_idx]), 0.45)
				_simon_idx += 1
				_simon_play_t = 0.7
			else:
				_simon_play_t = -1.0
				_simon_listen = true
				_simon_status.text = "À toi ! Clique sur les couleurs dans le même ordre (%d couleurs)." % _simon_queue.size()


func _simon_press(i: int) -> void:
	if not _simon_listen:
		return
	_simon_flash(i, 0.25)
	if i == int(_simon_queue[_simon_in]):
		_simon_in += 1
		if _simon_in >= _simon_queue.size():
			_simon_listen = false
			_simon_round += 1
			if _simon_round >= SIMON_LONGUEURS.size():
				_simon_status.text = "Combinaison trouvée !"
				_lock_done(1)
			else:
				_simon_status.text = "Bravo ! Manche suivante…"
				_later(1.1, _simon_play)
	else:
		_simon_listen = false
		_simon_err += 1
		_sfx("rate")
		_simon_status.text = "Raté ! Le virus ricane… On revoit la séquence."
		_taunt(_pick("rate"))
		if _simon_err == 2:
			_glitch(GLITCH["simon_aide"])
		_later(1.5, _simon_play)


# ------------------------------------------------------------------- verrou 3 : les circuits

func _start_tuyaux() -> void:
	var w := _window(_zone, Vector2(880, 610), Vector2(196, 98), "Verrou n°3 — rebrancher l'antivirus", Color(0.05, 0.07, 0.11, 0.98), Color(0.1, 0.55, 0.6))
	_lbl(w, "Clique sur les tuiles pour les tourner : relie la pile ⚡ à l'antivirus ✚.", 21, INK, Vector2(30, 56), 820)
	var origin := Vector2(128, 130)
	_generate_tuyaux()
	for y in range(PROWS):
		for x in range(PCOLS):
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.flat = true
			b.position = origin + Vector2(x, y) * (TUILE + 4.0)
			b.size = Vector2(TUILE, TUILE)
			b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.06), Color(0.4, 0.9, 1.0), 6, 2, 0))
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			b.name = "Tuile_%d_%d" % [x, y]
			b.pressed.connect(_tourne.bind(x, y))
			w.add_child(b)
			var t := Tuile.new()
			t.size = Vector2(TUILE, TUILE)
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.m = int(_masks[y * PCOLS + x])
			b.add_child(t)
			_tiles.append(t)
	var src := Panel.new()
	src.position = origin + Vector2(-96, _r0 * (TUILE + 4.0) + 20)
	src.size = Vector2(80, 60)
	src.add_theme_stylebox_override("panel", _box(Color(0.9, 0.7, 0.1), Color.WHITE, 8, 2, 0))
	src.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(src)
	_lbl(src, "⚡", 34, Color(0.2, 0.1, 0.0), Vector2(24, 6))
	var dst := Panel.new()
	dst.position = origin + Vector2(PCOLS * (TUILE + 4.0) + 12, _r1 * (TUILE + 4.0) + 14)
	dst.size = Vector2(96, 72)
	dst.add_theme_stylebox_override("panel", _box(Color(0.1, 0.6, 0.3), Color.WHITE, 8, 2, 0))
	dst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(dst)
	_lbl(dst, "✚", 30, Color.WHITE, Vector2(34, 2))
	_lbl(dst, "antivirus", 14, Color.WHITE, Vector2(14, 44))
	_tuyaux_t = 0.0
	_tuyaux_aide = false
	_tuyaux_ok = false
	_lit()
	_glitch(GLITCH["tuyaux"])
	_taunt(_pick("tuyaux"))


static func _rot(m: int) -> int:
	return ((m << 1) | (m >> 3)) & 15


static func _bit(d: Vector2i) -> int:
	if d == Vector2i(0, -1):
		return 1
	if d == Vector2i(1, 0):
		return 2
	if d == Vector2i(0, 1):
		return 4
	return 8


## Un chemin au hasard de la pile à l'antivirus (une descente en profondeur), puis les autres tuiles
## au hasard, puis tout est tourné au hasard (jamais déjà résolu).
func _generate_tuyaux() -> void:
	_r0 = _rng.randi() % PROWS
	_r1 = _rng.randi() % PROWS
	var path: Array = []
	_walk(Vector2i(0, _r0), Vector2i(PCOLS - 1, _r1), {}, path)
	_masks.clear()
	_masks.resize(PCOLS * PROWS)
	for i in range(_masks.size()):
		_masks[i] = [5, 3, 3, 7][_rng.randi() % 4]
	for i2 in range(path.size()):
		var c: Vector2i = path[i2]
		var m: int = 0
		m |= 8 if i2 == 0 else _bit(path[i2 - 1] - c)
		m |= 2 if i2 == path.size() - 1 else _bit(path[i2 + 1] - c)
		_masks[c.y * PCOLS + c.x] = m
	for _k in range(20):
		for j in range(_masks.size()):
			for _r in range(_rng.randi() % 4):
				_masks[j] = _rot(int(_masks[j]))
		if not _solved():
			return
	_masks[_r0 * PCOLS] = _rot(int(_masks[_r0 * PCOLS]))
	if _solved():
		_masks[_r0 * PCOLS] = _rot(int(_masks[_r0 * PCOLS]))


func _walk(c: Vector2i, goal: Vector2i, seen: Dictionary, path: Array) -> bool:
	path.append(c)
	seen[c] = true
	if c == goal:
		return true
	var dirs: Array = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0)]
	for i in range(dirs.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp: Vector2i = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp
	for d in dirs:
		var n: Vector2i = c + d
		if n.x < 0 or n.y < 0 or n.x >= PCOLS or n.y >= PROWS or seen.has(n):
			continue
		if _walk(n, goal, seen, path):
			return true
	path.pop_back()
	return false


## Les tuiles reliées à la pile.
func _reach() -> Dictionary:
	var lit := {}
	var start := Vector2i(0, _r0)
	if not (int(_masks[_r0 * PCOLS]) & 8):
		return lit
	var todo: Array = [start]
	lit[start] = true
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		var m: int = int(_masks[c.y * PCOLS + c.x])
		for e in [[1, Vector2i(0, -1), 4], [2, Vector2i(1, 0), 8], [4, Vector2i(0, 1), 1], [8, Vector2i(-1, 0), 2]]:
			if not (m & int(e[0])):
				continue
			var n: Vector2i = c + (e[1] as Vector2i)
			if n.x < 0 or n.y < 0 or n.x >= PCOLS or n.y >= PROWS or lit.has(n):
				continue
			if int(_masks[n.y * PCOLS + n.x]) & int(e[2]):
				lit[n] = true
				todo.append(n)
	return lit


func _solved() -> bool:
	var lit: Dictionary = _reach()
	var end := Vector2i(PCOLS - 1, _r1)
	return lit.has(end) and (int(_masks[_r1 * PCOLS + PCOLS - 1]) & 2) != 0


func _lit() -> void:
	var lit: Dictionary = _reach()
	for y in range(PROWS):
		for x in range(PCOLS):
			var i: int = y * PCOLS + x
			if i < _tiles.size():
				var t: Tuile = _tiles[i]
				t.m = int(_masks[i])
				t.lit = lit.has(Vector2i(x, y))
				t.queue_redraw()


func _tourne(x: int, y: int) -> void:
	if _tuyaux_ok:
		return
	var i: int = y * PCOLS + x
	_masks[i] = _rot(int(_masks[i]))
	_sfx("clic")
	_lit()
	if _solved():
		_tuyaux_ok = true
		_sfx("courant")
		_later(0.9, func(): _lock_done(2))


func _tuyaux_tick(delta: float) -> void:
	_tuyaux_t += delta
	if _tuyaux_t > 25.0 and not _tuyaux_aide and not _tuyaux_ok:
		_tuyaux_aide = true
		_glitch(GLITCH["tuyaux_aide"])


# =================================================================== 4. la victoire

func _phase_fini() -> void:
	if not opened:
		return
	phase = "fini"
	can_pause = false
	for c in _zone.get_children():
		c.queue_free()
	_taunt(_pick("fin"))
	_glitch(GLITCH["fin"])
	if _virus != null and is_instance_valid(_virus):
		_virus.peur = true
		var tw := _virus.create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(_virus, "position", _corbeille - Vector2(75, 80), 1.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_virus, "scale", Vector2(0.08, 0.08), 1.3).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if is_instance_valid(_virus):
				_virus.visible = false)
	_later(1.0, func(): _sfx("aspire"))
	_later(2.6, _victoire)


func _victoire() -> void:
	if _bulle != null and is_instance_valid(_bulle):
		_bulle.visible = false
	_sfx("victoire")
	var w := _window(_zone, Vector2(780, 230), Vector2(410, 150), "Sécurité du carnet", Color(0.06, 0.16, 0.1, 0.98), Color(0.15, 0.6, 0.3))
	_lbl(w, "✓  Ton carnet est guéri !", 36, VERT, Vector2(36, 60))
	_lbl(w, "Turbo-Aventure 3000 a été supprimé. Grigri est parti à la corbeille, et la corbeille a été vidée.", 21, INK, Vector2(36, 120), 710)
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _card_style())
	c.position = Vector2(300, 420)
	c.custom_minimum_size = Vector2(760, 0)
	_zone.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	c.add_child(v)
	var t := Label.new()
	t.text = "✦  Le conseil de Glitch"
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", OR)
	if _fonts.has("Bold"):
		t.add_theme_font_override("font", _fonts["Bold"])
	v.add_child(t)
	var x := Label.new()
	x.text = "N'installe jamais un programme qui vient d'un inconnu, même s'il n'est pas cher. Et ne clique jamais sur les gros boutons qui brillent : ferme les fenêtres avec la petite croix !"
	x.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	x.custom_minimum_size = Vector2(710, 0)
	x.add_theme_font_size_override("font_size", 24)
	x.add_theme_color_override("font_color", INK)
	if _fonts.has("Regular"):
		x.add_theme_font_override("font", _fonts["Regular"])
	v.add_child(x)
	var b := Button.new()
	b.name = "Revenir"
	b.text = "▶  Revenir au jeu"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(320, 58)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 25)
	b.add_theme_stylebox_override("normal", _box(Color(0.06, 0.17, 0.24), Color(0.75, 0.6, 0.3), 10, 2, 8))
	b.add_theme_stylebox_override("hover", _box(Color(0.1, 0.25, 0.33), OR, 10, 3, 8))
	b.add_theme_stylebox_override("pressed", _box(Color(0.16, 0.3, 0.36), OR, 10, 3, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	b.pressed.connect(_finish)
	v.add_child(b)


# =================================================================== pour les tests

## Casse le verrou en cours comme si on l'avait résolu à la main.
func debug_solve() -> void:
	if not opened or phase != "bureau":
		return
	match pas:
		0:
			while _pop_closed < OBJECTIF_POP and opened:
				if _pops.is_empty():
					_spawn_pop()
				_pop_close(_pops[0])
		1:
			_simon_round = SIMON_LONGUEURS.size() - 1
			_simon_queue = _simon_seq.slice(0, SIMON_LONGUEURS[_simon_round])
			_simon_listen = true
			_simon_in = 0
			for c in _simon_queue:
				_simon_press(int(c))
		2:
			var path: Array = []
			_walk(Vector2i(0, _r0), Vector2i(PCOLS - 1, _r1), {}, path)
			for i in range(path.size()):
				var c2: Vector2i = path[i]
				var want: int = (8 if i == 0 else _bit(path[i - 1] - c2)) | (2 if i == path.size() - 1 else _bit(path[i + 1] - c2))
				var k: int = c2.y * PCOLS + c2.x
				var guard: int = 0
				while (int(_masks[k]) & want) != want and guard < 4:
					_masks[k] = _rot(int(_masks[k]))
					guard += 1
				if (int(_masks[k]) & want) != want:
					_masks[k] = want
			_tourne_force()


func _tourne_force() -> void:
	_lit()
	if _solved() and not _tuyaux_ok:
		_tuyaux_ok = true
		_later(0.2, func(): _lock_done(2))


# =================================================================== les sons (fabriqués ici)

func _wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in range(s.size()):
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050
	w.stereo = false
	w.data = data
	return w


## Une suite de notes : [fréquence de départ, fréquence d'arrivée, durée, forme] ; forme : sin, car, bruit.
func _notes(list: Array, vol: float = 0.6) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var ph: float = 0.0
	for n in list:
		var f0: float = float(n[0])
		var f1: float = float(n[1])
		var dur: float = float(n[2])
		var kind: String = str(n[3])
		var count: int = int(dur * 22050.0)
		for i in range(count):
			var u: float = float(i) / float(maxi(count, 1))
			var f: float = lerpf(f0, f1, u)
			ph += f / 22050.0
			var v: float
			match kind:
				"car":
					v = 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
					v *= 0.5
				"bruit":
					v = _rng.randf_range(-1.0, 1.0) * 0.6
				_:
					v = sin(ph * TAU)
			var env: float = minf(1.0, u * 40.0) * (1.0 - u) * (1.0 - u * 0.3)
			out.append(v * env * vol)
	return _wav(out)


func _make_sounds() -> void:
	_sounds["erreur"] = _notes([[220, 220, 0.28, "car"], [0, 0, 0.06, "sin"], [165, 160, 0.4, "car"]], 0.55)
	_sounds["glitch"] = _notes([[0, 0, 0.18, "bruit"], [900, 200, 0.12, "car"], [0, 0, 0.25, "bruit"], [60, 40, 0.2, "car"]], 0.5)
	_sounds["installe"] = _notes([[660, 660, 0.08, "sin"], [990, 990, 0.12, "sin"]], 0.35)
	_sounds["clic"] = _notes([[1400, 900, 0.045, "sin"]], 0.45)
	_sounds["pop"] = _notes([[500, 1100, 0.09, "sin"]], 0.35)
	_sounds["piege"] = _notes([[300, 900, 0.18, "car"], [900, 400, 0.18, "car"]], 0.4)
	_sounds["message"] = _notes([[880, 880, 0.07, "sin"], [1320, 1320, 0.1, "sin"]], 0.35)
	_sounds["rate"] = _notes([[180, 150, 0.35, "car"]], 0.45)
	_sounds["verrou"] = _notes([[523, 523, 0.1, "sin"], [659, 659, 0.1, "sin"], [784, 784, 0.1, "sin"], [1047, 1047, 0.25, "sin"]], 0.45)
	_sounds["courant"] = _notes([[200, 1200, 0.45, "sin"]], 0.4)
	_sounds["aspire"] = _notes([[1200, 90, 1.0, "sin"]], 0.45)
	_sounds["victoire"] = _notes([[523, 523, 0.12, "sin"], [659, 659, 0.12, "sin"], [784, 784, 0.12, "sin"], [1047, 1047, 0.12, "sin"], [784, 784, 0.1, "sin"], [1047, 1047, 0.4, "sin"]], 0.45)
	for i in range(4):
		_sounds["note_%d" % i] = _notes([[SIMON_F[i], SIMON_F[i], 0.4, "sin"]], 0.5)


# =================================================================== la VR : le grand panneau et le laser

func _build_vr_panel() -> void:
	panel3d = MeshInstance3D.new()
	panel3d.name = "Virus_VR"
	var q := QuadMesh.new()
	q.size = Vector2(VR_W, VR_H)
	panel3d.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.render_priority = 20
	m.albedo_texture = viewport.get_texture()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	panel3d.material_override = m
	panel3d.visible = false
	add_child(panel3d)
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1.0, 0.4, 0.85, 0.85)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.no_depth_test = true
	lm.render_priority = 21
	laser = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.002
	cm.bottom_radius = 0.004
	cm.height = 1.0
	laser.mesh = cm
	laser.material_override = lm
	laser.visible = false
	add_child(laser)
	cursor = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.01
	sm.height = 0.02
	cursor.mesh = sm
	cursor.material_override = lm
	cursor.visible = false
	add_child(cursor)


func _place_vr() -> void:
	if main == null or main.get("xr_camera") == null or panel3d == null:
		return
	var head: Transform3D = main.xr_camera.global_transform
	var fwd: Vector3 = -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	panel3d.global_position = head.origin + fwd * VR_DIST + Vector3.DOWN * 0.05
	panel3d.look_at(head.origin, Vector3.UP)
	panel3d.rotate_object_local(Vector3.UP, PI)


## Si l'on tourne franchement la tête (ou le corps), le panneau revient devant les yeux.
func _follow_head(_delta: float) -> void:
	if main.get("xr_camera") == null or panel3d == null:
		return
	var head: Transform3D = main.xr_camera.global_transform
	var to_panel: Vector3 = panel3d.global_position - head.origin
	to_panel.y = 0.0
	var fwd: Vector3 = -head.basis.z
	fwd.y = 0.0
	if to_panel.length() < 0.01 or fwd.length() < 0.01:
		return
	if to_panel.normalized().dot(fwd.normalized()) < 0.55 or absf(to_panel.length() - VR_DIST) > 0.6:
		_place_vr()


func _vr_pointer() -> void:
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
		if t > 0.0 and t < 5.0:
			hit = o + d * t
	var length: float = 1.5
	var uv := Vector2(-1, -1)
	if hit != Vector3.INF:
		var local: Vector3 = panel3d.global_transform.affine_inverse() * hit
		uv = Vector2(local.x / VR_W + 0.5, 0.5 - local.y / VR_H)
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
	var trig: bool = hand.get_float("trigger") > 0.7
	if trig != _vr_trigger_down:
		_vr_trigger_down = trig
		var mb := InputEventMouseButton.new()
		mb.position = px
		mb.global_position = px
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = trig
		mb.button_mask = MOUSE_BUTTON_MASK_LEFT if trig else 0
		viewport.push_input(mb)

extends Node3D
## V145 : la roue des sorts et les gestes de la magie.
##  - les icônes des sept sorts (dessinées ici, une fois) : un soleil, une flamme, un flocon, une
##    flèche qui s'élève, un objet attiré, un cœur, un éclair ; elles servent à la roue et à la
##    rangée des sorts de l'écran ;
##  - PC : B tapé = le sort suivant (comme avant) ; B maintenu = la roue des sorts au milieu de
##    l'écran, le temps ralentit ; la souris désigne un sort, on relâche B (ou clic gauche) pour le
##    prendre ; Échap pour refermer sans rien changer ;
##  - VR : gâchette gauche tapée = lancer le sort choisi (comme avant) ; gâchette gauche maintenue
##    = la roue s'ouvre autour de la main gauche ; on pousse la main vers un sort (la manette
##    vibre à chaque sort survolé) et on relâche pour le prendre ;
##    les gestes, gâchette gauche tenue :
##      * le lancer : un geste vif de la main vers l'avant : le sort choisi part dans la
##        direction du geste ;
##      * la main levée vite au-dessus de soi : la Lévitation ;
##      * la main posée sur le cœur un instant : le Soin ;
##    gâchette tenue, la main gauche ne donne plus de coups de poing (elle fait de la magie).

const RAYON_VR: float = 0.12
const SEUIL_VR: float = 0.045         # la main doit s'écarter de 4,5 cm du centre pour désigner un sort
const RAYON_PC: float = 150.0
const SEUIL_PC: float = 34.0
const TENIR: float = 0.25             # au-delà, la gâchette (ou B) tenue ouvre la roue
const LANCER_VITESSE: float = 2.4     # m/s
const LEVER_VITESSE: float = 2.2
const COEUR_TEMPS: float = 0.5
const RALENTI: float = 0.3

var main: Node
var ouverte: bool = false
var survol: int = -1
var test_mode: bool = false            # les tests appellent pc_tick et geste_tick eux-mêmes
var gestes: Dictionary = {}            # tests : geste -> nombre
var dernier_geste: String = ""
var choix_faits: int = 0
# PC
var _b_t: float = -1.0
var _souris := Vector2.ZERO
var _hud: Control
var _ralenti: bool = false
var _ouvert_ms: int = 0
# VR
var _trig_t: float = -1.0
var _ancre := Vector3.ZERO             # dans le repère du joueur VR (xr_origin)
var _plan := Basis()                   # le repère de la roue (son +Z regarde la tête)
var _hist: Array = []                  # [instant, position locale de la main]
var _mode: String = ""                 # "", "roue", "coeur", "fait"
var _coeur_t: float = 0.0
var _clock: float = 0.0
var _roue3d: Node3D
var _slots3d: Array = []
var _label3d: Label3D

static var _icones: Dictionary = {}
static var _pastille: ImageTexture


func setup(main_node: Node) -> void:
	main = main_node


func _sorts() -> Node:
	return main.get("sorts_v67") if main != null else null


func _ordre() -> Array:
	var so: Node = _sorts()
	return so.ORDRE if so != null else []


# =================================================================== les icônes

## Les formes de l'icône d'un sort, dans un carré de -1 à 1 (y vers le haut) :
## ["poly", points] (rempli), ["trait", points, épaisseur], ["rond", centre, rayon],
## ["trou_poly", points] et ["trou_trait", points, épaisseur] (ils effacent).
static func formes(id: String) -> Array:
	var f: Array = []
	match id:
		"lumiere":
			f.append(["rond", Vector2.ZERO, 0.34])
			for k in range(8):
				var a: float = TAU * k / 8.0
				var d := Vector2(cos(a), sin(a))
				f.append(["trait", PackedVector2Array([d * 0.5, d * (0.86 if k % 2 == 0 else 0.74)]), 0.11])
		"feu":
			f.append(["poly", PackedVector2Array([Vector2(0.02, 0.96), Vector2(0.24, 0.56), Vector2(0.47, 0.26), Vector2(0.57, -0.14), Vector2(0.47, -0.55),
				Vector2(0.22, -0.8), Vector2(0.0, -0.86), Vector2(-0.22, -0.8), Vector2(-0.47, -0.55), Vector2(-0.57, -0.16), Vector2(-0.45, 0.22),
				Vector2(-0.3, 0.02), Vector2(-0.22, 0.38), Vector2(-0.08, 0.62)])])
			f.append(["trou_poly", PackedVector2Array([Vector2(0.0, 0.2), Vector2(0.17, -0.16), Vector2(0.14, -0.48), Vector2(0.0, -0.6), Vector2(-0.14, -0.48),
				Vector2(-0.17, -0.16)])])
		"gel":
			for k in range(6):
				var a2: float = PI * 0.5 + TAU * k / 6.0
				var d2 := Vector2(cos(a2), sin(a2))
				f.append(["trait", PackedVector2Array([Vector2.ZERO, d2 * 0.88]), 0.11])
				for s in [-1.0, 1.0]:
					var b: Vector2 = d2.rotated(s * 0.75)
					f.append(["trait", PackedVector2Array([d2 * 0.5, d2 * 0.5 + b * 0.26]), 0.09])
		"levitation":
			f.append(["poly", PackedVector2Array([Vector2(0, 0.92), Vector2(0.44, 0.4), Vector2(0.16, 0.4), Vector2(0.16, -0.18), Vector2(-0.16, -0.18),
				Vector2(-0.16, 0.4), Vector2(-0.44, 0.4)])])
			for y in [-0.45, -0.74]:
				var w := PackedVector2Array()
				for i in range(13):
					var x: float = -0.7 + 1.4 * i / 12.0
					w.append(Vector2(x, y + sin(x * 6.0) * 0.07))
				f.append(["trait", w, 0.09])
		"telekinesie":
			f.append(["rond", Vector2(0.42, 0.42), 0.24])
			for r in [0.5, 0.78, 1.06]:
				var arc := PackedVector2Array()
				for i in range(11):
					var a3: float = PI * 1.08 + (PI * 0.34) * i / 10.0
					arc.append(Vector2(0.42, 0.42) + Vector2(cos(a3), sin(a3)) * r)
				f.append(["trait", arc, 0.1])
		"soin":
			var h := PackedVector2Array()
			for i in range(40):
				var t: float = TAU * i / 40.0
				var x2: float = 16.0 * pow(sin(t), 3)
				var y2: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				h.append(Vector2(x2, y2 + 2.5) / 17.5)
			f.append(["poly", h])
			f.append(["trou_trait", PackedVector2Array([Vector2(0, -0.32), Vector2(0, 0.36)]), 0.16])
			f.append(["trou_trait", PackedVector2Array([Vector2(-0.34, 0.02), Vector2(0.34, 0.02)]), 0.16])
		"foudre":
			f.append(["poly", PackedVector2Array([Vector2(0.2, 0.96), Vector2(-0.42, 0.0), Vector2(-0.02, 0.0), Vector2(-0.26, -0.96), Vector2(0.46, 0.14),
				Vector2(0.06, 0.14), Vector2(0.36, 0.96)])])
	return f


static func _dans(p: Vector2, poly: PackedVector2Array) -> bool:
	var dedans: bool = false
	var n: int = poly.size()
	var j: int = n - 1
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[j]
		if (a.y > p.y) != (b.y > p.y) and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
			dedans = not dedans
		j = i
	return dedans


static func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _dist_ligne(p: Vector2, pts: PackedVector2Array, ferme: bool) -> float:
	var d: float = INF
	var n: int = pts.size()
	for i in range(n - 1 + (1 if ferme else 0)):
		d = minf(d, _dist_seg(p, pts[i], pts[(i + 1) % n]))
	return d


## La couverture (0 à 1) des formes au point p (px : la taille d'un pixel, pour adoucir les bords).
static func _couvre(f: Array, p: Vector2, px: float) -> float:
	var a: float = 0.0
	for s in f:
		var k: String = str(s[0])
		var c: float = 0.0
		match k:
			"poly", "trou_poly":
				var d: float = _dist_ligne(p, s[1], true)
				c = clampf(0.5 + (d if _dans(p, s[1]) else -d) / px, 0.0, 1.0)
			"trait", "trou_trait":
				c = clampf(0.5 + (float(s[2]) * 0.5 - _dist_ligne(p, s[1], false)) / px, 0.0, 1.0)
			"rond":
				c = clampf(0.5 + (float(s[2]) - p.distance_to(s[1])) / px, 0.0, 1.0)
		if k.begins_with("trou"):
			a *= 1.0 - c
		else:
			a = maxf(a, c)
	return a


## L'icône d'un sort : blanche sur fond transparent (on la teinte à l'affichage).
static func icone(id: String) -> Texture2D:
	if _icones.has(id):
		return _icones[id]
	var n: int = 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var f: Array = formes(id)
	var px: float = 2.0 / n
	for y in range(n):
		for x in range(n):
			var p := Vector2((x + 0.5) / n * 2.0 - 1.0, 1.0 - (y + 0.5) / n * 2.0) * 1.08
			img.set_pixel(x, y, Color(1, 1, 1, _couvre(f, p, px * 1.08)))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_icones[id] = tex
	return tex


## La pastille d'un sort dans la roue VR : un disque doux et un liseré.
static func pastille() -> Texture2D:
	if _pastille != null:
		return _pastille
	var n: int = 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var d: float = Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var disque: float = clampf((0.97 - d) * 20.0, 0.0, 1.0)
			var lisere: float = clampf(1.0 - absf(d - 0.9) / 0.06, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, maxf(disque * 0.42, lisere)))
	img.generate_mipmaps()
	_pastille = ImageTexture.create_from_image(img)
	return _pastille


# =================================================================== la roue : les places

## La direction d'un sort dans la roue (0 en haut, puis dans le sens des aiguilles d'une montre).
func angle_de(i: int) -> float:
	var n: int = maxi(_ordre().size(), 1)
	return PI * 0.5 - TAU * float(i) / float(n)


## L'écran : la direction d'un sort depuis le centre (l'axe y de l'écran descend).
func dir_pc(i: int) -> Vector2:
	var a: float = angle_de(i)
	return Vector2(cos(a), -sin(a))


## VR : la direction d'un sort dans le plan de la roue (x à droite, y en haut).
func dir_vr(i: int) -> Vector2:
	var a: float = angle_de(i)
	return Vector2(cos(a), sin(a))


## Le sort le plus proche d'une direction (x à droite, y en haut).
func _place(v: Vector2) -> int:
	var n: int = _ordre().size()
	if n == 0:
		return -1
	var a: float = atan2(v.y, v.x)
	var best: int = 0
	var bd: float = INF
	for i in range(n):
		var d: float = absf(wrapf(a - angle_de(i), -PI, PI))
		if d < bd:
			bd = d
			best = i
	return best


func _connu(i: int) -> bool:
	var so: Node = _sorts()
	var o: Array = _ordre()
	return so != null and i >= 0 and i < o.size() and bool(so.knows(str(o[i])))


func _survoler(i: int) -> void:
	if i == survol:
		return
	survol = i
	if i >= 0:
		main.sfx("roue_tic")
		_vibre(0.18, 0.03)


## On prend le sort survolé (s'il est appris).
func _prendre() -> void:
	var so: Node = _sorts()
	if so == null or survol < 0:
		return
	var id: String = str(_ordre()[survol])
	if not so.knows(id):
		main.sfx("ui_erreur")
		main._show_message_v28("%s : ce sort ne s'apprend qu'à Arcanelle." % str(so.INFO[id]["nom"]))
		return
	if so.select(id):
		choix_faits += 1
		main._show_message_v28("Sort choisi : %s (%d de magie)" % [str(so.INFO[id]["nom"]), int(so.cost(id))])


func _vibre(amp: float, dur: float) -> void:
	if main == null or not bool(main.get("xr_active")) or main.get("left_hand") == null:
		return
	if main.left_hand.has_method("trigger_haptic_pulse"):
		main.left_hand.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)


# =================================================================== PC

## B appuyé (sorts_v67.handle_key) : tapé, le sort suivant ; maintenu, la roue.
func pc_appui_b() -> void:
	if _b_t < 0.0:
		_b_t = 0.0


func pc_tick(delta: float, b_tenu: bool) -> void:
	if _b_t < 0.0:
		return
	if b_tenu:
		_b_t += delta
		if not ouverte and _b_t >= TENIR:
			_ouvrir_pc()
		return
	_b_t = -1.0
	if ouverte:
		_fermer(true)
	elif _sorts() != null:
		_sorts().next_spell()


## La souris a bougé (roue ouverte).
func pc_souris(rel: Vector2) -> void:
	_souris += rel
	if _souris.length() > 140.0:
		_souris = _souris.normalized() * 140.0
	_survoler(_place(Vector2(_souris.x, -_souris.y)) if _souris.length() > SEUIL_PC else -1)


func _ouvrir_pc() -> void:
	ouverte = true
	_souris = Vector2.ZERO
	survol = -1
	_ouvert_ms = Time.get_ticks_msec()
	main.sfx("roue_ouvre")
	if is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = RALENTI
		_ralenti = true
	if _hud != null:
		_hud.visible = true
		_hud.queue_redraw()


## Fermer la roue : « prendre » le sort survolé, ou refermer sans rien changer.
func _fermer(prendre: bool) -> void:
	if not ouverte:
		return
	if prendre:
		_prendre()
	ouverte = false
	survol = -1
	if _ralenti:
		_ralenti = false
		var fx: Node = main.get("combat_fx_v129")
		if fx == null or int(fx.get("_hs_until")) <= 0:
			Engine.time_scale = 1.0
	if _hud != null:
		_hud.visible = false
	if _roue3d != null:
		_roue3d.visible = false


func _input(event: InputEvent) -> void:
	if not ouverte or main == null or bool(main.get("xr_active")):
		return
	if event is InputEventMouseMotion:
		pc_souris((event as InputEventMouseMotion).relative)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_b_t = -1.0
		_fermer(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_b_t = -1.0
		_fermer(false)
		get_viewport().set_input_as_handled()


func make_hud(layer: CanvasLayer) -> void:
	if layer == null:
		return
	_hud = Control.new()
	_hud.name = "Roue_des_sorts_v145"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.draw.connect(_draw_pc)
	_hud.visible = false
	layer.add_child(_hud)


func _arc(c: Vector2, r0: float, r1: float, a0: float, a1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var n: int = maxi(6, int(absf(a1 - a0) / TAU * 96.0))
	for i in range(n + 1):
		var a: float = lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a), -sin(a)) * r1)
	for i in range(n, -1, -1):
		var a2: float = lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a2), -sin(a2)) * r0)
	_hud.draw_colored_polygon(pts, col)


func _draw_pc() -> void:
	var so: Node = _sorts()
	if so == null:
		return
	var sz: Vector2 = _hud.size
	var c: Vector2 = sz * 0.5
	var k: float = clampf((Time.get_ticks_msec() - _ouvert_ms) / 120.0, 0.0, 1.0)
	var e: float = 1.0 - pow(1.0 - k, 3.0)
	var o: Array = _ordre()
	var n: int = o.size()
	var font: Font = ThemeDB.fallback_font
	# le voile, l'anneau
	_hud.draw_circle(c, (RAYON_PC + 120.0) * e, Color(0.02, 0.03, 0.06, 0.45))
	_hud.draw_arc(c, RAYON_PC, 0.0, TAU, 96, Color(0.08, 0.1, 0.16, 0.55), 104.0 * e, true)
	var demi: float = PI / float(n)
	for i in range(n):
		var id: String = str(o[i])
		var inf: Dictionary = so.INFO[id]
		var col: Color = inf["couleur"]
		var connu: bool = so.knows(id)
		var a: float = angle_de(i)
		var sur: bool = i == survol
		if sur:
			_arc(c, RAYON_PC - 56.0, RAYON_PC + 60.0, a - demi + 0.02, a + demi - 0.02, Color(col.r, col.g, col.b, 0.32 if connu else 0.12))
		var p: Vector2 = c + dir_pc(i) * RAYON_PC * e
		var r: float = (38.0 if sur else 30.0) * e
		var fond: Color = col.darkened(0.55) if connu else Color(0.16, 0.17, 0.2)
		_hud.draw_circle(p, r + 3.0, Color(0, 0, 0, 0.7))
		_hud.draw_circle(p, r, fond)
		_hud.draw_arc(p, r, 0.0, TAU, 40, col if connu else Color(0.35, 0.36, 0.4), 2.5 if sur else 1.5, true)
		var ic: Texture2D = icone(id)
		var tcol: Color = col.lightened(0.45) if connu else Color(0.38, 0.39, 0.43)
		if connu and int(so.mana) < int(so.cost(id)):
			tcol = tcol.darkened(0.45)
		_hud.draw_texture_rect(ic, Rect2(p - Vector2(r, r) * 0.72, Vector2(r, r) * 1.44), false, tcol)
		if not connu:
			_hud.draw_string(font, p + Vector2(-5, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.85, 0.9, 0.9))
		_hud.draw_string(font, p + Vector2(r * 0.55, r * 0.95), str(inf["touche"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.7))
	# au centre : le sort survolé (ou le sort choisi), son coût, la magie
	var i2: int = survol if survol >= 0 else o.find(so.choisi)
	var titre: String = "Roue des sorts"
	var sous: String = "La souris vers un sort, puis relâche B"
	var col2: Color = Color(1, 1, 1)
	if i2 >= 0:
		var id2: String = str(o[i2])
		var inf2: Dictionary = so.INFO[id2]
		col2 = (inf2["couleur"] as Color).lightened(0.3)
		if so.knows(id2):
			titre = str(inf2["nom"])
			sous = "%d de magie (tu en as %d)" % [int(so.cost(id2)), int(so.mana)]
		else:
			titre = "Sort inconnu"
			sous = "À apprendre à Arcanelle"
			col2 = Color(0.7, 0.72, 0.78)
	_hud.draw_circle(c, 62.0 * e, Color(0.03, 0.04, 0.08, 0.85))
	_hud.draw_arc(c, 62.0 * e, 0.0, TAU, 48, col2, 1.5, true)
	_hud.draw_string(font, c + Vector2(-110, -4), titre, HORIZONTAL_ALIGNMENT_CENTER, 220, 19, col2)
	_hud.draw_string(font, c + Vector2(-110, 18), sous, HORIZONTAL_ALIGNMENT_CENTER, 220, 11, Color(0.85, 0.88, 0.95, 0.9))
	# en dessous : ce que fait le sort survolé
	if survol >= 0 and so.knows(str(o[survol])):
		_hud.draw_multiline_string(font, c + Vector2(-230, RAYON_PC + 88.0), str(so.INFO[str(o[survol])]["desc"]), HORIZONTAL_ALIGNMENT_CENTER, 460, 14, 3, Color(0.92, 0.94, 1.0, 0.95))
	# le petit point de la souris
	if _souris.length() > 2.0:
		_hud.draw_circle(c + _souris, 5.0, Color(1, 1, 1, 0.85))


# =================================================================== VR : la roue autour de la main gauche

## Gâchette gauche tenue : la main gauche fait de la magie (pas de coup de poing).
func main_gauche_occupee() -> bool:
	return _trig_t >= 0.0


func _ouvrir_vr(tete: Vector3) -> void:
	ouverte = true
	survol = -1
	_mode = "roue"
	main.sfx("roue_ouvre")
	_vibre(0.3, 0.05)
	var vers_tete: Vector3 = tete - _ancre
	if vers_tete.length() < 0.05:
		vers_tete = Vector3.BACK
	_plan = Basis.looking_at(-vers_tete.normalized(), Vector3.UP)
	var parent: Node3D = main.get("xr_origin")
	if _roue3d == null:
		_roue3d = Node3D.new()
		_roue3d.name = "Roue_des_sorts_v145"
		(parent if parent != null else self).add_child(_roue3d)
		_construire_3d()
	_roue3d.transform = Transform3D(_plan, _ancre)
	_roue3d.scale = Vector3.ONE * 0.2
	_roue3d.visible = true
	_maj_3d(0.0)


func _quad(parent: Node3D, tex: Texture2D, taille: float, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(taille, taille)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.no_depth_test = true
	m.render_priority = prio
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _construire_3d() -> void:
	_slots3d.clear()
	var o: Array = _ordre()
	for i in range(o.size()):
		var slot := Node3D.new()
		_roue3d.add_child(slot)
		var d: Vector2 = dir_vr(i)
		slot.position = Vector3(d.x, d.y, 0.0) * RAYON_VR
		var fond: MeshInstance3D = _quad(slot, pastille(), 0.07, 20)
		var ic: MeshInstance3D = _quad(slot, icone(str(o[i])), 0.048, 21)
		ic.position.z = 0.002
		_slots3d.append({"node": slot, "fond": fond, "icone": ic})
	_label3d = Label3D.new()
	_label3d.font_size = 40
	_label3d.pixel_size = 0.0006
	_label3d.outline_size = 10
	_label3d.no_depth_test = true
	_label3d.render_priority = 22
	_label3d.outline_render_priority = 21
	_roue3d.add_child(_label3d)


func _maj_3d(delta: float) -> void:
	if _roue3d == null or not _roue3d.visible:
		return
	var so: Node = _sorts()
	_roue3d.scale = _roue3d.scale.lerp(Vector3.ONE, clampf(delta * 14.0, 0.0, 1.0)) if delta > 0.0 else _roue3d.scale
	var o: Array = _ordre()
	for i in range(_slots3d.size()):
		var s: Dictionary = _slots3d[i]
		var id: String = str(o[i])
		var col: Color = so.INFO[id]["couleur"]
		var connu: bool = so.knows(id)
		var sur: bool = i == survol
		(s["node"] as Node3D).scale = Vector3.ONE * (1.3 if sur else 1.0)
		var fm: StandardMaterial3D = ((s["fond"] as MeshInstance3D).mesh as QuadMesh).material
		fm.albedo_color = (col.darkened(0.35) if connu else Color(0.3, 0.31, 0.35)) * Color(1, 1, 1, 1.0 if sur else 0.85)
		var im: StandardMaterial3D = ((s["icone"] as MeshInstance3D).mesh as QuadMesh).material
		im.albedo_color = col.lightened(0.55) if connu else Color(0.45, 0.46, 0.5)
		if connu and int(so.mana) < int(so.cost(id)):
			im.albedo_color = im.albedo_color.darkened(0.45)
	var i2: int = survol if survol >= 0 else o.find(so.choisi)
	if i2 >= 0:
		var id2: String = str(o[i2])
		if so.knows(id2):
			_label3d.text = "%s\n%d / %d" % [str(so.INFO[id2]["nom"]), int(so.cost(id2)), int(so.mana)]
			_label3d.modulate = (so.INFO[id2]["couleur"] as Color).lightened(0.3)
		else:
			_label3d.text = "?"
			_label3d.modulate = Color(0.8, 0.8, 0.85)
	else:
		_label3d.text = ""


## VR, à chaque image : la gâchette gauche, la main gauche, la tête (dans le repère du joueur).
func vr_tick(delta: float) -> void:
	if main == null or test_mode:
		return
	var trig: bool = main.left_hand.get_float("trigger") > 0.7
	var cam: Node3D = main.xr_camera
	var fwd: Vector3 = -cam.transform.basis.z
	geste_tick(delta, trig, main.left_hand.position, cam.position, fwd)


## Le cœur des gestes (les tests l'appellent avec des mouvements fabriqués).
func geste_tick(delta: float, trig: bool, main_l: Vector3, tete: Vector3, regard: Vector3) -> void:
	_clock += delta
	_hist.append([_clock, main_l])
	while _hist.size() > 2 and _clock - float(_hist[0][0]) > 0.1:
		_hist.pop_front()
	var vit := Vector3.ZERO
	if _hist.size() >= 2:
		var dt: float = float(_hist[_hist.size() - 1][0]) - float(_hist[0][0])
		if dt > 0.001:
			vit = ((_hist[_hist.size() - 1][1] as Vector3) - (_hist[0][1] as Vector3)) / dt
	var plat := Vector3(regard.x, 0, regard.z)
	plat = plat.normalized() if plat.length() > 0.01 else Vector3.FORWARD
	var coeur: Vector3 = tete + Vector3.DOWN * 0.38 + plat * 0.12
	var so: Node = _sorts()
	if trig:
		if _trig_t < 0.0:
			_trig_t = 0.0
			_ancre = main_l
			_mode = ""
			_coeur_t = 0.0
			if main_l.distance_to(coeur) < 0.2 and so != null and so.knows("soin"):
				_mode = "coeur"
		else:
			_trig_t += delta
		match _mode:
			"coeur":
				if main_l.distance_to(coeur) < 0.24:
					_coeur_t += delta
					if _coeur_t >= COEUR_TEMPS:
						_mode = "fait"
						_geste("coeur", "soin", Vector3.ZERO, main_l)
				else:
					_mode = ""
			"", "roue":
				var v: float = vit.length()
				var horiz: float = Vector2(vit.x, vit.z).length()
				var loin: bool = vit.dot(main_l - tete) > 0.0
				if v > LANCER_VITESSE and loin and plat.dot(Vector3(vit.x, 0, vit.z).normalized()) > 0.45 and vit.y < v * 0.8:
					var id: String = so.choisi if so != null else ""
					if _mode == "roue" and survol >= 0 and _connu(survol):
						id = str(_ordre()[survol])
					_fermer_vr()
					_mode = "fait"
					_geste("lancer", id, vit.normalized(), main_l)
				elif vit.y > LEVER_VITESSE and vit.y > horiz * 1.4 and main_l.y > tete.y - 0.3 and so != null and so.knows("levitation"):
					_fermer_vr()
					_mode = "fait"
					_geste("lever", "levitation", Vector3.ZERO, main_l)
				elif _mode == "" and _trig_t >= TENIR:
					_ouvrir_vr(tete)
				if _mode == "roue":
					var off: Vector3 = _plan.inverse() * (main_l - _ancre)
					var v2 := Vector2(off.x, off.y)
					_survoler(_place(v2) if v2.length() > SEUIL_VR else -1)
					_maj_3d(delta)
		return
	if _trig_t < 0.0:
		return
	if _mode == "roue":
		_prendre()
		_fermer_vr()
	elif (_mode == "" or _mode == "coeur") and _trig_t < TENIR and so != null:
		so.cast()
	_trig_t = -1.0
	_mode = ""


func _fermer_vr() -> void:
	ouverte = false
	survol = -1
	if _roue3d != null:
		_roue3d.visible = false


## Un geste reconnu : le sort part (dans la direction du geste pour le lancer).
func _geste(nom: String, id: String, dir_locale: Vector3, main_l: Vector3) -> void:
	var so: Node = _sorts()
	if so == null or id == "" or not so.knows(id):
		return
	gestes[nom] = int(gestes.get(nom, 0)) + 1
	dernier_geste = nom
	var xo: Node3D = main.get("xr_origin")
	var o: Vector3 = xo.to_global(main_l) if xo != null else main_l
	var ok: bool
	if dir_locale != Vector3.ZERO:
		var d: Vector3 = (xo.global_basis * dir_locale).normalized() if xo != null else dir_locale
		ok = so.cast_vers(id, o, d)
	else:
		ok = so.cast(id)
	if ok:
		_vibre(0.6, 0.08)
		main.sfx("geste_magie", o)
		var fx: Node = main.get("combat_fx_v129")
		if fx != null:
			var col: Color = so.INFO[id]["couleur"]
			fx._burst(o, {"amount": 18, "life": 0.5, "v0": 0.8, "v1": 2.4, "grav": Vector3.ZERO, "size": 0.05, "mesh": "streak", "damping": 3.0,
				"cols": [Color(1, 1, 1), col, Color(col.r, col.g, col.b, 0.0)]})


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	var bloque: bool = not bool(main.get("game_started")) or (main.get("game_menu") != null and bool(main.game_menu.opened)) \
		or (main.get("dialogue_v31") != null and main.dialogue_v31 != null and bool(main.dialogue_v31.opened))
	if ouverte and bloque:
		_b_t = -1.0
		_trig_t = -1.0
		_mode = ""
		_fermer(false)
		_fermer_vr()
	# (la roue de l'écran s'ouvre en grandissant : on la redessine à chaque image)
	if ouverte and _hud != null and _hud.visible:
		_hud.queue_redraw()
	if test_mode:
		return
	if not bool(main.get("xr_active")):
		pc_tick(delta, Input.is_physical_key_pressed(KEY_B) or Input.is_key_pressed(KEY_B))
	if ouverte and _ralenti:
		var fx: Node = main.get("combat_fx_v129")
		if (fx == null or int(fx.get("_hs_until")) <= 0) and Engine.time_scale > RALENTI + 0.01:
			Engine.time_scale = RALENTI


func _exit_tree() -> void:
	if _ralenti:
		Engine.time_scale = 1.0
		_ralenti = false


func reset() -> void:
	_b_t = -1.0
	_trig_t = -1.0
	_mode = ""
	_fermer(false)
	_fermer_vr()

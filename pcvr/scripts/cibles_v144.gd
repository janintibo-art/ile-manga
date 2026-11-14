extends Node3D
## V144 : la lisibilité du combat et le ciblage.
##  - la cible : l'ennemi que le prochain coup ou le prochain sort touchera porte un anneau au sol
##    (au PC : celui qui est devant le héros ; en VR : celui que la main droite désigne) ;
##  - le verrouillage (PC : touche C ou clic de la molette) : l'anneau devient rouge, le héros
##    frappe et lance ses sorts vers cet ennemi, la caméra tourne doucement pour le garder en
##    vue ; C de nouveau : l'ennemi suivant ; après le dernier, on relâche ;
##  - la barre de vie : au-dessus de chaque ennemi blessé (et de la cible), avec son nom, la
##    part de vie qu'il vient de perdre (en clair, qui se vide après coup), son état (en feu,
##    gelé, trempé) et sa faiblesse (« Craint : ? » tant qu'on ne l'a pas découverte) ;
##  - l'alerte : un « ! » rouge au-dessus de l'ennemi qui arme son coup ; au PC, une flèche rouge
##    au bord de l'écran s'il est hors du champ.

## les états d'un ennemi qui en a après le héros (il devient la cible si on l'a devant soi)
const AGRESSIFS := ["chasse", "armer", "frappe", "souffle", "charge", "pique", "saut", "saut_roi", "rugir", "rugit", "balaie", "balaie_armer", "coup",
	"approche", "surgit", "recul", "etourdi", "queue", "brume", "emporte", "fouet_armer", "fouet", "fonce", "coq_fonce", "ruade", "ruade_fin", "cabre",
	"langue", "grogne", "menace", "leve", "avale"]
## les états où il arme son coup : le « ! » chaque fois qu'il y entre (« souffle » n'en est pas : c'est
## l'ennemi qui reprend haleine après avoir frappé)
const ARME := ["armer", "balaie_armer", "fouet_armer", "cabre", "leve"]
## les attaques qui partent sans prévenir : le « ! » aussi, sauf si l'ennemi vient d'armer (il a déjà prévenu)
const ELAN := ["charge", "pique", "saut", "saut_roi", "fonce", "coq_fonce", "ruade", "langue"]
const PORTEE: float = 30.0
const ALERTE_PORTEE: float = 26.0        # (un sanglier arme sa charge de loin : on veut le savoir)
const BARRE_TEMPS: float = 6.0
const ETATS := {"brule": ["En feu", Color(1.0, 0.6, 0.25)], "gele": ["Gelé", Color(0.65, 0.88, 1.0)], "trempe": ["Trempé", Color(0.4, 0.8, 1.0)]}
const ELEMENTS := {"feu": ["le feu", Color(1.0, 0.6, 0.25)], "glace": ["la glace", Color(0.65, 0.88, 1.0)], "foudre": ["la foudre", Color(0.8, 0.82, 1.0)],
	"eau": ["l'eau", Color(0.4, 0.8, 1.0)]}

var main: Node
var cible: Node3D = null
var verrou: bool = false
var alertes: int = 0                    # tests : nombre de « ! » montrés
var barres_vues: int = 0                # tests : nombre de barres créées
var _suivi: Dictionary = {}             # id -> {node, max, hp, t, ghost, bar…}
var _scan: float = 0.0
var _proches: Array = []
var _anneau: MeshInstance3D
var _anneau_mat: StandardMaterial3D
var _hud: Control
var _fleches: Array = []                # {dir: Vector2, t}
var _clock: float = 0.0
var _dit: bool = false


func setup(main_node: Node) -> void:
	main = main_node


func _vivant(m: Variant) -> bool:
	return m != null and is_instance_valid(m) and (m as Node).is_inside_tree() and str((m as Node).get("state")) != "mort"


func _centre(m: Node3D) -> Vector3:
	return m.global_position + Vector3.UP * maxf(float(m.get("hit_height")), 0.3)


func _joueur() -> Vector3:
	return main._player_pos_v27()


func _nom(m: Node) -> String:
	var sp: Variant = m.get("spec")
	if sp is Dictionary and (sp as Dictionary).has("nom"):
		return str((sp as Dictionary)["nom"])
	return ""


func agressif(m: Node) -> bool:
	return str(m.get("state")) in AGRESSIFS


# =================================================================== la cible

func _ennemis() -> Array:
	var out: Array = []
	var p: Vector3 = _joueur()
	for g in ["monstres_v36", "faune_v132"]:
		for m in get_tree().get_nodes_in_group(g):
			if _vivant(m) and not out.has(m) and (m as Node3D).global_position.distance_to(p) < PORTEE:
				if m.has_method("is_hittable") and not bool(m.is_hittable()):
					continue
				out.append(m)
	return out


## D'où l'on vise, et vers où (PC : le héros et son regard ; VR : la main droite).
func _visee() -> Array:
	if main.xr_active and main.get("right_hand") != null:
		return [main.right_hand.global_position, (-main.right_hand.global_basis.z).normalized(), true]
	var h: Node = main.get("hero_v28")
	var f: Vector3 = h.facing if h != null else Vector3.FORWARD
	return [_joueur() + Vector3.UP * 1.0, f.normalized(), false]


## L'ennemi que l'on a devant soi (le mieux placé dans le cône). « tous » : même les paisibles.
func devant(tous: bool = false, sauf: Array = [], demi_angle: float = -1.0, portee: float = 16.0) -> Node3D:
	var v: Array = _visee()
	var o: Vector3 = v[0]
	var dir: Vector3 = v[1]
	var vr: bool = v[2]
	if demi_angle < 0.0:
		demi_angle = 20.0 if vr else 38.0
	var best: Node3D = null
	var bs: float = INF
	for m in _proches:
		if not _vivant(m) or sauf.has(m):
			continue
		var s: Dictionary = _suivi.get((m as Node).get_instance_id(), {})
		if not tous and not agressif(m) and int(m.get("hp")) >= int(s.get("max", 0)):
			continue
		var off: Vector3 = _centre(m) - o
		var dflat: Vector3 = off
		var d2: Vector3 = dir
		if not vr:
			dflat.y = 0.0
			d2.y = 0.0
			if absf(off.y) > 5.0:
				continue
		var d: float = dflat.length()
		if d > portee:
			continue
		var ang: float = rad_to_deg(d2.angle_to(dflat)) if d > 0.9 and d2.length() > 0.01 else 0.0
		if ang > demi_angle:
			continue
		var sc: float = d + ang * 0.3
		if sc < bs:
			bs = sc
			best = m
	return best


## C (ou le clic de la molette) : verrouiller l'ennemi devant soi ; de nouveau : le suivant ;
## après le dernier : relâcher.
func basculer() -> void:
	_rafraichir()
	if not verrou:
		# d'abord un ennemi (qui en a après le héros, ou déjà blessé) ; sinon n'importe quelle bête
		var m: Node3D = devant(false, [], 70.0, 22.0)
		if m == null:
			m = devant(true, [], 70.0, 22.0)
		if m == null:
			main._show_message_v28("Aucun ennemi à verrouiller devant toi.")
			return
		cible = m
		verrou = true
		main.sfx("ui_clic")
		return
	var liste: Array = []
	for m2 in _proches:
		if _vivant(m2) and (agressif(m2) or m2 == cible) and (m2 as Node3D).global_position.distance_to(_joueur()) < 22.0:
			liste.append(m2)
	var p: Vector3 = _joueur()
	liste.sort_custom(func(a, b): return (a as Node3D).global_position.distance_squared_to(p) < (b as Node3D).global_position.distance_squared_to(p))
	var i: int = liste.find(cible)
	if i < 0 or i + 1 >= liste.size():
		relacher()
		return
	cible = liste[i + 1]
	main.sfx("ui_clic")


func relacher() -> void:
	if verrou:
		main.sfx("ui_clic")
	verrou = false


## La direction du coup ou du sort (PC, cible verrouillée) : Vector3.ZERO s'il n'y en a pas.
func direction(o: Vector3, flat: bool = true) -> Vector3:
	if not verrou or not _vivant(cible) or main.xr_active:
		return Vector3.ZERO
	var d: Vector3 = _centre(cible) - o
	if flat:
		d.y = 0.0
	return d.normalized() if d.length() > 0.05 else Vector3.ZERO


## PC : une touche ou un clic pour le verrouillage ? (appelé par main)
func handle_input(event: InputEvent) -> bool:
	if main.xr_active or not bool(main.get("game_started")):
		return false
	var m: Node = main.get("mer_v55")
	if m != null and bool(m.get("swimming")):
		return false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		basculer()
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		basculer()
		return true
	return false


# =================================================================== chaque image

func _rafraichir() -> void:
	_proches = _ennemis()
	for m in _proches:
		var id: int = (m as Node).get_instance_id()
		if not _suivi.has(id):
			var sp: Variant = m.get("spec")
			var pv: int = int((sp as Dictionary).get("pv", (sp as Dictionary).get("hp", 0))) if sp is Dictionary else 0
			_suivi[id] = {"node": m, "max": maxi(maxi(int(m.get("hp")), pv), 1), "hp": int(m.get("hp")), "t": -99.0, "ghost": clampf(float(int(m.get("hp"))) / float(maxi(maxi(int(m.get("hp")), pv), 1)), 0.0, 1.0), "etat": "", "bar": null}


func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		return
	_clock += delta
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.12
		_rafraichir()
		if verrou and (not _vivant(cible) or cible.global_position.distance_to(_joueur()) > PORTEE):
			verrou = false
			cible = null
		if not verrou:
			cible = devant()
	var el: Node = main.get("elements_v143")
	# le conseil, une seule fois par partie (retenu avec ceux des éléments), quand aucun autre message n'est affiché
	var mc: Variant = main.get("message_clock_v28")
	if cible != null and not _dit and (mc == null or float(mc) <= 0.0):
		_dit = true
		if el == null or not (el.vus as Dictionary).has("cible"):
			if el != null:
				el.vus["cible"] = true
			if main.xr_active:
				main._show_message_v28("L'anneau au sol montre l'ennemi que ta main droite désigne.")
			else:
				main._show_message_v28("L'anneau au sol montre l'ennemi que tu vises. C (ou clic de la molette) : le verrouiller.")
	for id in _suivi.keys():
		var s: Dictionary = _suivi[id]
		var m: Variant = s["node"]
		if not _vivant(m):
			if s["bar"] != null and is_instance_valid(s["bar"]):
				(s["bar"] as Node).queue_free()
			_suivi.erase(id)
			continue
		var n3: Node3D = m
		var hp: int = int(n3.get("hp"))
		if hp > int(s["max"]):
			s["max"] = hp
		if hp != int(s["hp"]):
			if hp < int(s["hp"]):
				s["t"] = _clock
			s["hp"] = hp
		# l'alerte : il arme son coup
		var st: String = str(n3.get("state"))
		if st != str(s["etat"]):
			if (st in ARME or (st in ELAN and not (str(s["etat"]) in ARME) and not (str(s["etat"]) in ELAN))) \
					and _clock - float(s.get("alerte", -9.0)) > 0.4 and n3.global_position.distance_to(_joueur()) < ALERTE_PORTEE:
				s["alerte"] = _clock
				_alerte(n3)
			s["etat"] = st
		var montre: bool = n3 == cible or _clock - float(s["t"]) < BARRE_TEMPS or (el != null and str(el.etat(n3)) != "")
		if montre:
			_barre(s, n3, el, delta)
		elif s["bar"] != null and is_instance_valid(s["bar"]):
			(s["bar"] as Node3D).visible = false
	_tick_anneau(delta)
	_tick_camera(delta)
	if _hud != null:
		_hud.visible = not main.xr_active and not _fleches.is_empty()
		for i in range(_fleches.size() - 1, -1, -1):
			_fleches[i]["t"] = float(_fleches[i]["t"]) - delta
			if float(_fleches[i]["t"]) <= 0.0:
				_fleches.remove_at(i)
		if _hud.visible:
			_hud.queue_redraw()


# =================================================================== la barre de vie

func _mat(col: Color, prio: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.albedo_color = col
	m.render_priority = prio
	m.disable_receive_shadows = true
	return m


func _quad(parent: Node3D, col: Color, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.material = _mat(col, prio)
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _label(parent: Node3D, size: int, y: float) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.0028
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 12
	l.outline_render_priority = 11
	l.position = Vector3(0, y, 0)
	parent.add_child(l)
	return l


func _barre(s: Dictionary, m: Node3D, el: Node, delta: float) -> void:
	var w: float = clampf(float(m.get("hit_radius")) * 2.4, 0.7, 2.6)
	var h: float = 0.075
	if s["bar"] == null or not is_instance_valid(s["bar"]):
		var root := Node3D.new()
		root.name = "Barre_v144"
		add_child(root)
		var fond: MeshInstance3D = _quad(root, Color(0.03, 0.03, 0.04, 0.72), 8)
		(fond.mesh as QuadMesh).size = Vector2(w + 0.04, h + 0.04)
		s["ghost_q"] = _quad(root, Color(1.0, 0.92, 0.7, 0.95), 9)
		s["fill_q"] = _quad(root, Color(0.85, 0.2, 0.12), 10)
		s["nom"] = _label(root, 44, h * 0.5 + 0.12)
		(s["nom"] as Label3D).text = _nom(m)
		s["info"] = _label(root, 38, -h * 0.5 - 0.11)
		s["bar"] = root
		barres_vues += 1
	var root2: Node3D = s["bar"]
	root2.visible = true
	root2.global_position = m.global_position + Vector3.UP * _haut(m)
	var r: float = clampf(float(int(s["hp"])) / float(s["max"]), 0.0, 1.0)
	# la part perdue reste claire un instant, puis se vide
	if float(s["ghost"]) > r:
		if _clock - float(s["t"]) > 0.45:
			s["ghost"] = maxf(r, float(s["ghost"]) - delta * 0.9)
	else:
		s["ghost"] = r
	_remplir(s["fill_q"], r, w, h)
	_remplir(s["ghost_q"], float(s["ghost"]), w, h)
	var fm: StandardMaterial3D = ((s["fill_q"] as MeshInstance3D).mesh as QuadMesh).material
	fm.albedo_color = Color(0.85, 0.2, 0.12) if r > 0.5 else (Color(1.0, 0.5, 0.08) if r > 0.25 else Color(1.0, 0.82, 0.1))
	# l'état, la faiblesse
	var info: Label3D = s["info"]
	var e: String = str(el.etat(m)) if el != null else ""
	var nom_l: Label3D = s["nom"]
	nom_l.modulate = Color(1.0, 0.86, 0.8) if (m == cible and verrou) else Color(1, 1, 1, 0.92)
	if ETATS.has(e):
		info.text = str(ETATS[e][0])
		info.modulate = ETATS[e][1]
	elif m == cible and el != null and str(el.faiblesse(m)) != "":
		var f: String = str(el.faiblesse(m))
		if el.has_method("connue") and bool(el.connue(m)):
			info.text = "Craint %s" % str(ELEMENTS[f][0])
			info.modulate = ELEMENTS[f][1]
		else:
			info.text = "Craint : ?"
			info.modulate = Color(0.8, 0.8, 0.8, 0.85)
	else:
		info.text = ""


## La hauteur de la barre au-dessus des pieds de l'ennemi.
func _haut(m: Node3D) -> float:
	return float(m.get("hit_height")) * 1.3 + 0.55


func _remplir(q: MeshInstance3D, r: float, w: float, h: float) -> void:
	var mesh: QuadMesh = q.mesh
	q.visible = r > 0.001
	mesh.size = Vector2(maxf(w * r, 0.001), h)
	mesh.center_offset = Vector3(-w * 0.5 + w * r * 0.5, 0, 0)


# =================================================================== l'anneau de la cible

func _tick_anneau(delta: float) -> void:
	if _anneau == null:
		_anneau = MeshInstance3D.new()
		_anneau.name = "Anneau_cible_v144"
		var q := QuadMesh.new()
		q.size = Vector2(1, 1)
		_anneau_mat = StandardMaterial3D.new()
		_anneau_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_anneau_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_anneau_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_anneau_mat.albedo_texture = _tex_anneau()
		_anneau_mat.disable_receive_shadows = true
		q.material = _anneau_mat
		_anneau.mesh = q
		_anneau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_anneau.rotation.x = -PI * 0.5
		add_child(_anneau)
	if not _vivant(cible):
		_anneau.visible = false
		return
	_anneau.visible = true
	var r: float = maxf(float(cible.get("hit_radius")), 0.3) * 2.6 + 0.5
	var pulse: float = 1.0 + sin(_clock * 5.0) * (0.05 if verrou else 0.03)
	_anneau.scale = Vector3(r * pulse, r * pulse, 1.0)
	_anneau.global_position = cible.global_position + Vector3.UP * 0.07
	_anneau.rotate_object_local(Vector3(0, 0, 1), delta * (1.6 if verrou else 0.7))
	_anneau_mat.albedo_color = Color(1.0, 0.16, 0.1, 1.0) if verrou else Color(1.0, 0.9, 0.5, 0.8)


static var _anneau_tex: ImageTexture


## L'anneau : un cercle fin, quatre encoches (dessiné une fois).
static func _tex_anneau() -> Texture2D:
	if _anneau_tex != null:
		return _anneau_tex
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var p := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5) / (n * 0.5)
			var d: float = p.length()
			var a: float = clampf(1.0 - absf(d - 0.84) / 0.05, 0.0, 1.0)
			var ang: float = fposmod(atan2(p.y, p.x), PI * 0.5)
			# quatre encoches vers l'intérieur
			if absf(ang - PI * 0.25) < 0.09 and d > 0.62 and d < 0.86:
				a = maxf(a, clampf(1.0 - absf(ang - PI * 0.25) / 0.09, 0.0, 1.0))
			# quatre vides dans le cercle
			if ang < 0.12 or ang > PI * 0.5 - 0.12:
				a *= 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_anneau_tex = ImageTexture.create_from_image(img)
	return _anneau_tex


## Verrouillé : la caméra tourne doucement pour garder l'ennemi devant (sauf si la souris la tient).
func _tick_camera(delta: float) -> void:
	if not verrou or main.xr_active or not _vivant(cible) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	var pr: Node3D = main.get("pc_root")
	if pr == null or main.get("talking_npc_v31") != null:
		return
	var off: Vector3 = cible.global_position - pr.global_position
	off.y = 0.0
	if off.length() < 1.6:
		return
	var fwd: Vector3 = -pr.global_basis.z
	fwd.y = 0.0
	var ang: float = fwd.signed_angle_to(off, Vector3.UP)
	# une zone morte : on ne corrige que si l'ennemi sort du milieu de l'image
	if absf(ang) < 0.3:
		return
	pr.rotate_y(clampf(ang - signf(ang) * 0.3, -1.0, 1.0) * minf(delta * 2.2, 1.0))


# =================================================================== l'alerte

func _alerte(m: Node3D) -> void:
	alertes += 1
	var cb: Node = main.get("combat_v28")
	if cb != null:
		cb.float_text(m.global_position + Vector3.UP * (_haut(m) + 0.45), "!", Color(1.0, 0.2, 0.12))
		# (un grand « ! », qu'on voit de loin)
		var fl: Array = cb.get("_floaters")
		if fl != null and not fl.is_empty() and fl[fl.size() - 1]["node"] is Label3D:
			var lb: Label3D = fl[fl.size() - 1]["node"]
			lb.font_size = 110
			lb.outline_size = 22
			lb.pixel_size = 0.005
	if main.xr_active:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var c: Vector3 = _centre(m)
	var hors: bool = cam.is_position_behind(c)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if not hors:
		var sp: Vector2 = cam.unproject_position(c)
		hors = sp.x < 0.0 or sp.y < 0.0 or sp.x > vp.x or sp.y > vp.y
	if not hors:
		return
	var loc: Vector3 = cam.global_transform.affine_inverse() * c
	var d := Vector2(loc.x, -loc.y)
	if loc.z > 0.0 and d.length() < 0.01:
		d = Vector2(0, 1)
	_fleches.append({"dir": d.normalized() if d.length() > 0.001 else Vector2(0, 1), "t": 0.9})


func make_hud(layer: CanvasLayer) -> void:
	if layer == null:
		return
	_hud = Control.new()
	_hud.name = "Alertes_v144"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.draw.connect(_draw_hud)
	_hud.visible = false
	layer.add_child(_hud)


func _draw_hud() -> void:
	var sz: Vector2 = _hud.size
	var c: Vector2 = sz * 0.5
	for f in _fleches:
		var d: Vector2 = f["dir"]
		var a: float = clampf(float(f["t"]) / 0.3, 0.0, 1.0)
		var k: float = minf((sz.x * 0.5 - 60.0) / maxf(absf(d.x), 0.001), (sz.y * 0.5 - 60.0) / maxf(absf(d.y), 0.001))
		var p: Vector2 = c + d * k
		var n := Vector2(-d.y, d.x)
		_hud.draw_colored_polygon(PackedVector2Array([p + d * 26.0, p - d * 14.0 + n * 20.0, p - d * 4.0, p - d * 14.0 - n * 20.0]), Color(1.0, 0.18, 0.1, 0.85 * a))


func reset() -> void:
	verrou = false
	cible = null
	_dit = false
	for id in _suivi.keys():
		var b: Variant = _suivi[id]["bar"]
		if b != null and is_instance_valid(b):
			(b as Node).queue_free()
	_suivi.clear()
	_fleches.clear()

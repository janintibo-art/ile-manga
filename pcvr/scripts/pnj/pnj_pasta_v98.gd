extends "res://scripts/pnj/pnj_lumen_v76.gd"
## V98 : un adepte de l'Église du Grand Spaghetti Volant (l'Île Al Dente). Même vie réglée par l'heure
## que les autres habitants (et toutes les postures des îles d'avant : prier, enseigner, jardiner,
## pêcher, le violon, le tambourin, danser…), avec en plus ce qui fait un adepte (fiche « pasta ») :
##  - la passoire sur la tête (repères V64) : en inox percé de vrais trous (une texture découpée),
##    un rebord roulé, deux anses ; dorée pour le grand prêtre ; « grande » pour le novice et pour
##    Gnocchi (trop grande : elle tombe un peu sur les yeux, de travers) ;
##  - le cache-œil et Pesto, le perroquet vert du Capitaine Rigatoni ;
##  - les objets : le balai en spaghettis secs, la fourche, la canne à pêche, la louche, le violon…
## Le reste (les robes, les tabliers à carreaux, le tricorne, la capeline) est cousu dans le corps (V64).

static var _hole_tex: ImageTexture
static var _pass_mats: Dictionary = {}

var _pasta: Dictionary = {}
var passoire: Node3D
var _cheer: float = 0.0                  # V98 : « Ramen ! » pendant la Grande Réconciliation
var _cheer_line: String = ""
var _tamb: Node3D


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	pasta_props(data.get("pasta", {}))


## La texture des trous de la passoire : des rangées de petits trous ronds en quinconce (alpha 0),
## une bande pleine en haut (le fond de la passoire, posé sur la tête) et en bas (le rebord).
static func hole_texture() -> ImageTexture:
	if _hole_tex != null:
		return _hole_tex
	var w: int = 256
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var cols: int = 28
	var rows: int = 5
	for r in range(rows):
		var v: float = lerpf(0.3, 0.84, float(r) / float(rows - 1))
		var off: float = 0.5 if r % 2 == 1 else 0.0
		for c in range(cols):
			var u: float = (float(c) + off) / float(cols)
			var cx: float = u * w
			var cy: float = v * h
			var rad: float = 2.6 + (1.0 - absf(v - 0.57)) * 0.8
			for y in range(int(cy - rad - 1), int(cy + rad + 2)):
				for x in range(int(cx - rad - 1), int(cx + rad + 2)):
					var xx: int = posmod(x, w)
					if y < 0 or y >= h:
						continue
					var d: float = Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy).length()
					if d < rad:
						img.set_pixel(xx, y, Color(1, 1, 1, 0))
	img.generate_mipmaps()
	_hole_tex = ImageTexture.create_from_image(img)
	return _hole_tex


static func passoire_mat(kind: String) -> StandardMaterial3D:
	if _pass_mats.has(kind):
		return _pass_mats[kind]
	var m := StandardMaterial3D.new()
	m.albedo_texture = hole_texture()
	m.albedo_color = Color(0.95, 0.76, 0.36) if kind == "doree" else Color(0.82, 0.83, 0.86)
	m.metallic = 0.95
	m.roughness = 0.22 if kind == "doree" else 0.3
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.anisotropy_enabled = true
	m.anisotropy = 0.5
	_pass_mats[kind] = m
	return m


## La tête du vrai corps : centre (entre l'avant et l'arrière), hauteur des yeux, demi-largeur.
func _pa_head() -> Dictionary:
	var t: Dictionary = _tete64
	var ey: Array = t.get("yeux", [0.0, 0.07, 0.08])
	var zc: float = (float(t.get("avant", 0.1)) + float(t.get("arriere", -0.09))) * 0.5
	return {"ey": Vector3(float(ey[0]), float(ey[1]), float(ey[2])), "dx": float(t.get("yeux_dx", 0.031)), "zc": zc,
		"cote": float(t.get("cote", 0.075)), "haut": float(t.get("haut", 0.14)), "avant": float(t.get("avant", 0.1)),
		"arriere": float(t.get("arriere", -0.09))}


func _pa_attach_head(node: Node3D, at: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	if not v64.is_empty():
		_attach("Head", at * 100.0, node, rot, true)
	else:
		_attach("Head", Vector3(0, 18.0, 1.0), node, rot)


func pasta_props(pa: Dictionary) -> void:
	if skel == null or pa.is_empty() or not _pasta.is_empty():
		return
	_pasta = pa
	var kind: String = str(pa.get("passoire", ""))
	if kind != "":
		_make_passoire(kind)
	for p in pa.get("props", []):
		match str(p):
			"cache_oeil":
				_make_eyepatch()
			"perroquet":
				_make_pesto()
	var obj: String = str(pa.get("objet", ""))
	match obj:
		"balai":
			_make_broom()
		"fourche":
			_make_fork()
		"canne_peche":
			_rod = Node3D.new()
			_part(_rod, _cyl(0.008, 0.016, 2.2), _mat(Color(0.32, 0.2, 0.1), 0.6), Vector3(0, 1.0, 0))
			_part(_rod, _cyl(0.022, 0.022, 0.035), _m(Color(0.7, 0.71, 0.74), 0.25, 0.9), Vector3(0, -0.02, 0.03), Vector3.ONE, Vector3(0, 0, 90))
			_rod.visible = false
			_attach("RightHand", Vector3(0, -6, 2), _rod, Vector3(-60, 0, 0))
		"louche", "panier", "cloche", "plateau":
			_mj_object(obj, "")
		"arrosoir":
			punk_props({"objet": "arrosoir"})
		"telescope_portable":
			lumen_props({"objet": obj})
		"violon":
			_make_object("violon", "")
		"":
			pass
	if bool(pa.get("violon", false)):
		_make_object("violon", "")
	if bool(pa.get("tambourin", false)):
		_make_tambourin()


## La passoire : une demi-sphère percée, le rebord roulé, le pied (un anneau, en haut puisqu'elle est
## retournée), deux anses sur les côtés.
func _make_passoire(kind: String) -> void:
	var hf: Dictionary = _pa_head()
	var hw: float = maxf(float(hf["cote"]), (float(hf["avant"]) - float(hf["arriere"])) * 0.5)
	var big: bool = kind == "grande"
	var r: float = hw * (1.42 if big else 1.2)
	var h: float = r * 0.78
	passoire = Node3D.new()
	passoire.name = "Passoire"
	var mat: StandardMaterial3D = passoire_mat(kind)
	var solid := _m(mat.albedo_color, mat.roughness, 0.95)
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r
	sm.is_hemisphere = true
	sm.radial_segments = 40
	sm.rings = 12
	_part(passoire, sm, mat, Vector3.ZERO, Vector3(1.0, h / r, 1.0))
	var rim := TorusMesh.new()
	rim.inner_radius = r - 0.006
	rim.outer_radius = r + 0.006
	rim.rings = 40
	rim.ring_segments = 8
	_part(passoire, rim, solid, Vector3(0, 0.002, 0))
	var foot := TorusMesh.new()
	foot.inner_radius = r * 0.42
	foot.outer_radius = r * 0.42 + 0.01
	foot.rings = 32
	foot.ring_segments = 6
	_part(passoire, foot, solid, Vector3(0, h * 0.97, 0), Vector3(1.0, 1.6, 1.0))
	for sx in [-1.0, 1.0]:
		var hd := TorusMesh.new()
		hd.inner_radius = 0.016
		hd.outer_radius = 0.024
		hd.rings = 16
		hd.ring_segments = 6
		_part(passoire, hd, solid, Vector3(sx * (r + 0.016), 0.012, 0), Vector3.ONE, Vector3(90, 0, 0))
	var y: float = float(hf["haut"]) - h * (0.62 if big else 0.42)
	var rot := Vector3(-12, 0, 9) if big else Vector3(-6, 0, 0)
	if kind == "doree":
		y += 0.005
	_pa_attach_head(passoire, Vector3(0, y, float(hf["zc"]) + (0.012 if big else 0.0)), rot)


## Le cache-œil (sur l'œil droit du personnage) et son cordon noir qui fait le tour de la tête.
func _make_eyepatch() -> void:
	var hf: Dictionary = _pa_head()
	var ey: Vector3 = hf["ey"]
	var dx: float = float(hf["dx"])
	var cote: float = float(hf["cote"])
	var zc: float = float(hf["zc"])
	var n := Node3D.new()
	n.name = "Cache_oeil"
	var black := _m(Color(0.04, 0.035, 0.035), 0.55)
	_part(n, _sphere(0.021), black, Vector3(dx, ey.y, ey.z + 0.012), Vector3(1.0, 0.85, 0.32))
	var band := TorusMesh.new()
	band.inner_radius = 0.997
	band.outer_radius = 1.0
	band.rings = 32
	band.ring_segments = 4
	var hd: float = (float(hf["avant"]) - float(hf["arriere"])) * 0.5 + 0.004
	var bn := Node3D.new()
	bn.position = Vector3(0, ey.y + 0.012, zc)
	bn.rotation_degrees = Vector3(0, 0, -16)
	n.add_child(bn)
	_part(bn, band, black, Vector3.ZERO, Vector3(cote + 0.004, 3.0, hd))
	_pa_attach_head(n, Vector3.ZERO)


## Pesto, le perroquet vert du Capitaine (sur l'épaule gauche : il tourne la tête, comme Gaston).
func _make_pesto() -> void:
	parrot = Node3D.new()
	parrot.name = "Pesto"
	var green := _mat(Color(0.18, 0.58, 0.16), 0.55)
	var lime := _mat(Color(0.62, 0.85, 0.2), 0.55)
	var red := _mat(Color(0.85, 0.15, 0.08), 0.5)
	var beak := _mat(Color(0.93, 0.8, 0.45), 0.4)
	_part(parrot, _sphere(0.065), green, Vector3(0, 0.1, 0), Vector3(0.95, 1.35, 1.0))
	_part(parrot, _sphere(0.05), lime, Vector3(0, 0.07, 0.03), Vector3(0.8, 1.2, 0.6))
	for sx in [-1.0, 1.0]:
		_part(parrot, _sphere(0.05), green, Vector3(sx * 0.05, 0.1, -0.01), Vector3(0.45, 1.3, 1.05), Vector3(0, 0, sx * 10))
		_part(parrot, _sphere(0.03), red, Vector3(sx * 0.052, 0.05, -0.03), Vector3(0.4, 1.1, 1.0), Vector3(0, 0, sx * 10))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.19, 0.015)
	parrot.add_child(head)
	_part(head, _sphere(0.046), green, Vector3.ZERO)
	_part(head, _sphere(0.02), red, Vector3(0, 0.035, -0.01), Vector3(1.0, 0.6, 1.4))
	_part(head, _cyl(0.0, 0.019, 0.05), beak, Vector3(0, -0.012, 0.05), Vector3.ONE, Vector3(105, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.011), _mat(Color(0.97, 0.97, 0.92), 0.3), Vector3(sx * 0.032, 0.012, 0.028))
		_part(head, _sphere(0.005), _mat(Color(0.03, 0.03, 0.03), 0.2), Vector3(sx * 0.036, 0.012, 0.035))
	_part(parrot, _cyl(0.032, 0.008, 0.2), green, Vector3(0, -0.02, -0.07), Vector3.ONE, Vector3(-30, 0, 0))
	_part(parrot, _cyl(0.012, 0.004, 0.16), red, Vector3(0, -0.06, -0.1), Vector3.ONE, Vector3(-34, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(parrot, _cyl(0.007, 0.007, 0.05), _mat(Color(0.35, 0.3, 0.3)), Vector3(sx * 0.02, 0.0, 0.01))
	_attach("LeftShoulder", Vector3(13.0, 9.0, -1.0), parrot)


## Le balai du novice : un manche, et une grosse botte de spaghettis secs liée par une ficelle.
func _make_broom() -> void:
	_hand_prop = Node3D.new()
	_hand_prop.name = "Balai"
	var wood := _m(Color(0.5, 0.34, 0.18), 0.7)
	var pasta := _m(Color(0.93, 0.8, 0.45), 0.55)
	_part(_hand_prop, _cyl(0.014, 0.016, 1.25), wood, Vector3(0, 0.1, 0))
	var base := Vector3(0, -0.55, 0)
	for k in range(26):
		var a: float = TAU * float(k) / 26.0
		var rr: float = 0.02 + 0.035 * fmod(float(k) * 0.618, 1.0)
		_part(_hand_prop, _cyl(0.003, 0.003, 0.34), pasta, base + Vector3(cos(a) * rr, -0.12, sin(a) * rr * 0.5), Vector3.ONE, Vector3(sin(a) * 6.0, 0, cos(a) * 6.0))
	_part(_hand_prop, _cyl(0.04, 0.04, 0.03), _m(Color(0.75, 0.15, 0.1), 0.7), base + Vector3(0, 0.02, 0), Vector3(1.0, 1.0, 0.55))
	_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))


## La fourche du paysan (trois dents).
func _make_fork() -> void:
	_hand_prop = Node3D.new()
	_hand_prop.name = "Fourche"
	var wood := _m(Color(0.52, 0.38, 0.22), 0.75)
	var iron := _m(Color(0.32, 0.31, 0.3), 0.45, 0.8)
	_part(_hand_prop, _cyl(0.016, 0.018, 1.35), wood, Vector3(0, 0.25, 0))
	_part(_hand_prop, _box_mesh_np(Vector3(0.16, 0.025, 0.02)), iron, Vector3(0, 0.94, 0))
	for sx in [-0.07, 0.0, 0.07]:
		_part(_hand_prop, _cyl(0.004, 0.007, 0.24), iron, Vector3(sx, 1.07, 0))
	_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(0, 0, 0))


## Le tambourin de Macaroni (on ne le voit que le soir, quand il joue la tarentelle).
func _make_tambourin() -> void:
	_tamb = Node3D.new()
	_tamb.name = "Tambourin"
	var wood := _m(Color(0.62, 0.42, 0.22), 0.6)
	var skin := _m(Color(0.93, 0.88, 0.76), 0.85)
	var brass := _m(Color(0.88, 0.7, 0.32), 0.3, 0.9)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.13
	tm.outer_radius = 0.155
	tm.rings = 28
	tm.ring_segments = 6
	_part(_tamb, tm, wood, Vector3.ZERO, Vector3(1.0, 2.2, 1.0))
	_part(_tamb, _cyl(0.135, 0.135, 0.004), skin, Vector3(0, 0.02, 0))
	for k in range(6):
		var a: float = TAU * k / 6.0
		_part(_tamb, _cyl(0.018, 0.018, 0.006), brass, Vector3(cos(a) * 0.143, 0.0, sin(a) * 0.143), Vector3.ONE, Vector3(0, 0, 90))
	_tamb.visible = false
	_attach("LeftHand", Vector3(0, -6, 6), _tamb, Vector3(0, 0, 90))


## V98 : pendant la Grande Réconciliation, les adeptes lèvent les bras et crient « Ramen ! ».
func cheer(seconds: float, line: String) -> void:
	_cheer = seconds
	_cheer_line = line
	if bubble != null:
		say_bubble(line, minf(seconds, 4.0))
	gesture("rire")


func _activity(delta: float, dist: float, to_player: Vector3) -> void:
	if _tamb != null:
		_tamb.visible = pose == "tambour"
	if _cheer > 0.0:
		_cheer -= delta
		if gesture_clock <= 0.0:
			gesture("rire")
		return
	super._activity(delta, dist, to_player)

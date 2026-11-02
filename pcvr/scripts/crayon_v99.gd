extends Node3D
## V99 : l'Île Crayonnée, au sud-est de l'archipel : une île toute en noir et blanc, comme une page
## de cahier de coloriage oubliée. Les couleurs ont disparu ; le but sera de les lui rendre (V100 : le
## village des arbres-maisons de la Clairière des Géants ; V101 : les habitants, les pots de couleur
## numérotés, le pinceau et la quête des couleurs).
## Le rendu : chaque matériau de l'île passe par crayon_mat_v99.gd (le papier, l'encre, les hachures,
## les contours) ; une carte des couleurs (« masque », vue de dessus, 512 x 512 sur toute l'île)
## dit où l'île a retrouvé ses couleurs. colorier() y pose une tache qui s'étale doucement (le
## liseré d'aquarelle avance) ; les taches sont gardées dans la sauvegarde.
## Aujourd'hui, une seule tache : au bout du ponton, là où l'on accoste (les couleurs du bateau ont
## un peu coulé sur le sable).

const IleScript = preload("res://scripts/ile_crayon_v99.gd")
const CrayonMat = preload("res://scripts/crayon_mat_v99.gd")
const Kit = preload("res://scripts/pasta_kit_v97.gd")
const FLORE := "res://scripts/crayon_flore_v99.gd"
const EAU := "res://shaders/eau_douce_v69.gdshader"
const CHUTE := "res://shaders/waterfall_v26.gdshader"
const MASK_RES: int = 512

const PLACES := {"plage": "la Grève Blanche", "clairiere": "la Clairière des Géants", "bois": "le Bois des Hachures",
	"mont": "le Mont Fusain", "sommet": "le sommet du Mont Fusain", "cascade": "la Cascade d'Encre", "etang": "l'Étang Gommé",
	"ruisseau": "le Ruisseau Pointillé", "pres": "les Prés Blancs", "prairie": "la prairie"}
## Les panneaux : [id, x, z, vers où ils regardent (repère île), texte]
const PANNEAUX := [
	["accueil", -3.0, 132.0, Vector2(0.25, 1.0), "L'Île Crayonnée\nIci, tout attend ses couleurs."],
	["clairiere", -14.0, 62.0, Vector2(0.6, 0.8), "La Clairière des Géants"],
	["etang", 22.0, -10.0, Vector2(-0.3, 1.0), "L'Étang Gommé\n(ne pas effacer les canards)"],
	["mont", -50.0, 4.0, Vector2(0.4, 1.0), "Le Mont Fusain\npar ici, le sentier du sommet"],
]

var main: Node
var ile: Node3D
var flore: Node3D
var pc: bool = true
var state: Dictionary = {}
var objets: Dictionary = {}               # lieux pour le carnet (nom -> Vector3 monde)
var panneaux: Array = []
var _avoid: Array = []
var _cols: StaticBody3D
var _registered: bool = false
var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _zone_t: float = 0.0
var _glob_t: float = 0.0

var masque: Image
var masque_tex: ImageTexture
var _taches: Array = []                   # les taches en train de s'étaler : {"at": Vector2 (repère île), "r", "t", "dur"}
var _mask_dirty: bool = false
var _mask_t: float = 0.0

var palette_at := Vector3.ZERO
var cascade_top := Vector3.ZERO
var _cascade_sound_t: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 9990
	state = _fresh_state()
	masque = Image.create(MASK_RES, MASK_RES, false, Image.FORMAT_R8)
	masque.fill(Color(0, 0, 0))
	masque_tex = ImageTexture.create_from_image(masque)
	_set_globals()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "panneaux": {}, "palette": false, "sommet": false, "cascade": false,
		"etang": false, "taches": []}


## Les paramètres partagés par tous les matériaux au crayon (déclarés dans project.godot,
## [shader_globals]) : la carte des couleurs et le carré de l'île qu'elle couvre.
func _set_globals() -> void:
	var rect := Vector4(IleScript.CENTER.x - IleScript.HALF, IleScript.CENTER.z - IleScript.HALF, IleScript.HALF * 2.0, IleScript.HALF * 2.0)
	RenderingServer.global_shader_parameter_set("crayon_masque", masque_tex)
	RenderingServer.global_shader_parameter_set("crayon_rect", rect)


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_crayonnee_v99"
	add_child(ile)
	ile.build(pc)


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


## Après le relief et l'heure du jour : l'eau (l'étang, les ruisseaux, la cascade), la palette de
## pierre, les panneaux, la végétation ; puis tout passe au rendu coloriage.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	for k in [["pierre", 4], ["calcaire", 4], ["moellons", 4], ["planches", 5], ["bois", 3]]:
		Kit.mat(str(k[0])).set_meta("crayon", int(k[1]))
	_eau()
	_palette()
	_panneaux()
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_crayonnee_v99"
		add_child(flore)
		for a in _avoid:
			flore.avoid.append(a)
		flore.build_crayon(ile, pc)
	CrayonMat.convert_tree(self)
	objets["plage"] = _ground(4.0, 140.0)
	objets["clairiere"] = palette_at
	objets["etang"] = _ground(22.0, -16.0)
	objets["cascade"] = cascade_top
	objets["sommet"] = ile.pads_world["sommet"]
	objets["bois"] = _ground(-110.0, 50.0)
	objets["pres"] = _ground(80.0, 80.0)
	# là où l'on accoste, les couleurs du bateau ont coulé sur le sable
	_tache_depart()
	print("ILE_MANGA_V99: l'Île Crayonnée est prête (%d ms, %d matériaux au crayon)" % [Time.get_ticks_msec() - t0, CrayonMat.converted])


func _ground(x: float, z: float) -> Vector3:
	var w: Vector3 = IleScript.W(x, z)
	w.y = ile.height(w.x, w.z)
	return w


func _col_cyl(at: Vector3, r: float, h: float) -> void:
	if _cols == null:
		_cols = StaticBody3D.new()
		_cols.name = "Crayonnee_collisions_v99"
		_cols.collision_layer = 1
		_cols.collision_mask = 0
		add_child(_cols)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	_cols.add_child(cs)
	cs.global_position = at + Vector3.UP * h * 0.5


# ------------------------------------------------------------------- l'eau

func _eau() -> void:
	var n: Texture2D = load("res://assets/textures/water/water_n.png")
	var em := ShaderMaterial.new()
	em.shader = load(EAU)
	em.set_shader_parameter("ripple_n", n)
	em.set_shader_parameter("deep", Color(0.04, 0.16, 0.22))
	em.set_shader_parameter("shallow", Color(0.2, 0.44, 0.46))
	# l'Étang Gommé
	var et := MeshInstance3D.new()
	et.name = "Etang_gomme"
	var cm := CylinderMesh.new()
	var er: float = float(IleScript.ETANG[2]) + 1.8
	cm.top_radius = er
	cm.bottom_radius = er
	cm.height = 0.02
	cm.radial_segments = 48
	cm.rings = 1
	et.mesh = cm
	et.material_override = em
	et.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	et.set_meta("crayon", 1)
	add_child(et)
	et.global_position = IleScript.W(float(IleScript.ETANG[0]), float(IleScript.ETANG[1]), ile.etang_level)
	# les deux ruisseaux
	for f in ile.flows_world:
		var mi: MeshInstance3D = _ribbon("Ruisseau_%s" % f, ile.flows_world[f], 2.6 if str(f) == "haut" else 3.4, false)
		mi.material_override = em
		mi.set_meta("crayon", 1)
	# la Cascade d'Encre : du bord de la falaise jusqu'à l'étang
	var top: Vector3 = ile.levre
	var bot: Vector3 = ile.pied
	var out: Vector3 = Vector3(bot.x - top.x, 0, bot.z - top.z).normalized()
	var fall: Array = []
	for k in range(16):
		var t: float = float(k) / 15.0
		fall.append(top + out * (0.2 + 2.6 * sqrt(t)) - Vector3.UP * (top.y - bot.y + 0.2) * t)
	var cas: MeshInstance3D = _ribbon("Cascade_d_encre", fall, 4.4, true)
	var wm := ShaderMaterial.new()
	wm.shader = load(CHUTE)
	wm.set_shader_parameter("fall_length", top.y - bot.y)
	wm.set_shader_parameter("water_color", Color(0.55, 0.74, 0.78))
	cas.material_override = wm
	cas.set_meta("crayon", 7)
	cascade_top = top
	# l'écume au pied de la cascade
	var sp := CPUParticles3D.new()
	sp.name = "Ecume_de_la_cascade"
	sp.amount = 50
	sp.lifetime = 1.2
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(1.4, 0.15, 0.9)
	sp.direction = Vector3.UP
	sp.spread = 40.0
	sp.initial_velocity_min = 1.5
	sp.initial_velocity_max = 3.5
	sp.gravity = Vector3(0, -9.8, 0)
	sp.scale_amount_min = 0.5
	sp.scale_amount_max = 1.1
	var dm := SphereMesh.new()
	dm.radius = 0.1
	dm.height = 0.2
	dm.radial_segments = 6
	dm.rings = 3
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.97, 0.97, 0.96)
	fm.roughness = 0.4
	dm.material = fm
	sp.mesh = dm
	add_child(sp)
	sp.global_position = bot + out * 0.3 + Vector3.UP * 0.1


## Un ruban le long d'une suite de points (UV.x : en travers, de 0 à 1 ; UV.y : le long, de 0 à 1).
## vertical : une nappe qui tombe (la cascade) ; sinon, posée à plat (un ruisseau).
func _ribbon(label: String, pts: Array, wid: float, vertical: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for i in range(pts.size()):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var c: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t: Vector3 = (c - a).normalized()
		var side: Vector3 = Vector3(t.x, 0, t.z).cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		var n: Vector3 = side.cross(t).normalized() if vertical else Vector3.UP
		if not vertical and n.y < 0.0:
			n = -n
		var w: float = wid * (lerpf(0.8, 1.2, float(i) / (pts.size() - 1)) if vertical else 1.0)
		var p: Vector3 = pts[i]
		rows.append([p - side * w * 0.5, p + side * w * 0.5, n, float(i) / (pts.size() - 1)])
	for i in range(rows.size() - 1):
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var quad: Array = [[r0[0], Vector2(0, r0[3]), r0[2]], [r0[1], Vector2(1, r0[3]), r0[2]], [r1[1], Vector2(1, r1[3]), r1[2]], [r1[0], Vector2(0, r1[3]), r1[2]]]
		var face: Vector3 = ((quad[1][0] as Vector3) - (quad[0][0] as Vector3)).cross((quad[2][0] as Vector3) - (quad[0][0] as Vector3))
		var order: Array = [0, 2, 1, 0, 3, 2] if face.dot(r0[2]) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_uv(quad[k][1])
			st.set_normal(quad[k][2])
			st.add_vertex(quad[k][0])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


# ------------------------------------------------------------------- la Palette de pierre

## Au milieu de la Clairière des Géants : une palette de peintre géante, taillée dans la pierre, avec
## ses neuf godets numérotés (tous vides et secs) et le trou pour le pouce.
func _palette() -> void:
	var cl: Vector3 = ile.pads_world["clairiere"]
	palette_at = cl
	var b := Kit.Batch.new()
	var base := Transform3D(Basis(Vector3.UP, 0.35), cl)
	# le socle, puis le plateau (une ellipse un peu échancrée, en dalles)
	b.cyl("pierre", base, 1.6, 1.9, 0.5, 18)
	var top_y: float = 0.95
	var pts: Array = []
	for k in range(40):
		var a: float = TAU * k / 40.0
		var r: float = 3.2 * (1.0 + 0.18 * cos(a * 2.0) - 0.22 * exp(-pow(wrapf(a - 0.2, -PI, PI) / 0.35, 2.0)))
		pts.append(Vector3(cos(a) * r * 1.25, 0, sin(a) * r * 0.85))
	for k2 in range(40):
		var a2: Vector3 = pts[k2]
		var c2: Vector3 = pts[(k2 + 1) % 40]
		var up := Vector3.UP * top_y
		var lo := Vector3.UP * (top_y - 0.35)
		b.tri("calcaire", [base * up, base * (c2 + up), base * (a2 + up)], [Vector3.UP, Vector3.UP, Vector3.UP], [Vector2(0.5, 0.5), Vector2(c2.x, c2.z) * 0.2, Vector2(a2.x, a2.z) * 0.2])
		var out: Vector3 = base.basis * ((a2 + c2) * 0.5).normalized()
		b.quad("calcaire", base * (a2 + up), base * (c2 + up), base * (c2 + lo), base * (a2 + lo), out, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.35), Vector2(0, 0.35))
	b.cyl("pierre", base * Transform3D(Basis(), Vector3.UP * 0.45), 1.2, 1.5, 0.2, 18)
	# le trou du pouce : un anneau de pierre sombre
	var pouce: Vector3 = base * Vector3(2.3, top_y + 0.01, -0.5)
	b.cyl("pierre", Transform3D(Basis(), pouce - Vector3.UP * 0.02), 0.42, 0.42, 0.05, 16)
	# les neuf godets, en arc ; leurs numéros sont gravés à côté
	for i in range(9):
		var a3: float = lerpf(-2.5, 2.0, float(i) / 8.0) + PI
		var gp: Vector3 = base * Vector3(cos(a3) * 2.7, top_y, sin(a3) * 1.75)
		b.cyl("moellons", Transform3D(Basis(), gp), 0.34, 0.3, 0.16, 14)
		b.cyl("pierre", Transform3D(Basis(), gp + Vector3.UP * 0.12), 0.24, 0.24, 0.05, 14)
		var toward: Vector3 = (base.origin - gp)
		toward.y = 0.0
		toward = toward.normalized()
		var lb: Label3D = Kit.label(self, str(i + 1), gp + toward * 0.55 + Vector3.UP * 0.02, Vector3.UP, 0.006, Color(0.08, 0.07, 0.06))
		lb.font_size = 72
		lb.global_rotation = Vector3(-PI * 0.5, atan2(-toward.x, -toward.z), 0)
	b.commit(self, "Palette_de_pierre_v99")
	_col_cyl(cl, 3.4, top_y)
	_avoid.append([Vector2(cl.x, cl.z), 6.0])


# ------------------------------------------------------------------- les panneaux

func _panneaux() -> void:
	var b := Kit.Batch.new()
	for e in PANNEAUX:
		var at: Vector3 = _ground(float(e[1]), float(e[2]))
		var f2: Vector2 = (e[3] as Vector2).normalized()
		var face := Vector3(f2.x, 0, f2.y)
		var xf := Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
		Kit.sign_board(b, xf, 2.4, 1.35)
		var lb: Label3D = Kit.label(self, str(e[4]), at + Vector3.UP * 2.08 + face * 0.1, face, 0.003, Color(0.07, 0.065, 0.06))
		lb.font_size = 40
		lb.width = 640.0
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panneaux.append({"id": str(e[0]), "at": at + face * 1.0, "texte": str(e[4]).replace("\n", " ")})
		_avoid.append([Vector2(at.x, at.z), 1.8])
	b.commit(self, "Panneaux_crayonnee")


# =================================================================== la carte des couleurs

## Pose une tache de couleur (centre en coordonnées monde, rayon en mètres), qui s'étale en « dur »
## secondes ; elle est gardée dans la sauvegarde.
func colorier(at: Vector3, radius: float, dur: float = 4.0) -> void:
	var l: Vector2 = IleScript.L(at.x, at.z)
	(state["taches"] as Array).append([snappedf(l.x, 0.1), snappedf(l.y, 0.1), snappedf(radius, 0.1)])
	if dur <= 0.0:
		_paint(l, radius, 1.0)
		_mask_dirty = true
	else:
		_taches.append({"at": l, "r": radius, "t": 0.0, "dur": dur})


## Peint la tache jusqu'à la fraction k de son rayon (bord adouci sur 2 m).
func _paint(l: Vector2, radius: float, k: float) -> void:
	var px: float = IleScript.HALF * 2.0 / MASK_RES
	var r: float = radius * k
	var edge: float = 2.0
	var cx: float = (l.x + IleScript.HALF) / px
	var cz: float = (l.y + IleScript.HALF) / px
	var reach: int = int(ceil((r + edge) / px)) + 1
	for zi in range(maxi(0, int(cz) - reach), mini(MASK_RES, int(cz) + reach + 1)):
		for xi in range(maxi(0, int(cx) - reach), mini(MASK_RES, int(cx) + reach + 1)):
			var d: float = Vector2((xi + 0.5 - cx) * px, (zi + 0.5 - cz) * px).length()
			if d > r + edge:
				continue
			var v: float = 1.0 - smoothstep(r - edge * 0.5, r + edge * 0.5, d)
			if v <= 0.0:
				continue
			var old: float = masque.get_pixel(xi, zi).r
			if v > old:
				masque.set_pixel(xi, zi, Color(v, 0, 0))


## La part de couleur retrouvée en ce point (0 : page blanche, 1 : en couleurs).
func couleur_at(p: Vector3) -> float:
	if not contains(p):
		return 1.0
	var l: Vector2 = IleScript.L(p.x, p.z)
	var px: float = IleScript.HALF * 2.0 / MASK_RES
	return masque.get_pixel(clampi(int((l.x + IleScript.HALF) / px), 0, MASK_RES - 1), clampi(int((l.y + IleScript.HALF) / px), 0, MASK_RES - 1)).r


func _repaint_all() -> void:
	masque.fill(Color(0, 0, 0))
	for t in state["taches"]:
		_paint(Vector2(float(t[0]), float(t[1])), float(t[2]), 1.0)
	_taches.clear()
	_mask_dirty = true


func _tache_depart() -> void:
	if (state["taches"] as Array).is_empty():
		var d: Vector3 = IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y - 2.0)
		colorier(d, 7.0, 0.0)
	_repaint_all()
	masque_tex.update(masque)


func _update_mask(delta: float) -> void:
	if not _taches.is_empty():
		_mask_t -= delta
		for t in _taches:
			t["t"] = float(t["t"]) + delta
		if _mask_t <= 0.0:
			_mask_t = 0.08
			var keep: Array = []
			for t2 in _taches:
				var k: float = clampf(float(t2["t"]) / float(t2["dur"]), 0.0, 1.0)
				_paint(t2["at"], float(t2["r"]), 1.0 - pow(1.0 - k, 2.0))
				if k < 1.0:
					keep.append(t2)
			_taches = keep
			_mask_dirty = true
	if _mask_dirty:
		_mask_dirty = false
		masque_tex.update(masque)


# =================================================================== les interactions

func register_services(journal: Node) -> void:
	for k in objets:
		journal.lieux["crayon_" + str(k)] = objets[k]
	journal.lieux["crayon"] = respawn_point()[0]
	_register_interactions()


func _register_interactions() -> void:
	if _registered:
		return
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	_registered = true
	for j in range(panneaux.size()):
		var pn: Dictionary = panneaux[j]
		d._interactions.append({"id": "crayon_panneau_%s" % str(pn["id"]), "pos": pn["at"], "radius": 2.2,
			"text": "E : lire le panneau", "vr": "Gâchette : lire le panneau", "call": _lire.bind(j)})
	d._interactions.append({"id": "crayon_palette", "pos": palette_at, "radius": 5.0,
		"text": "E : regarder la Palette de pierre", "vr": "Gâchette : regarder la Palette de pierre", "call": _regarder_palette})


func _lire(j: int) -> void:
	var pn: Dictionary = panneaux[j]
	(state["panneaux"] as Dictionary)[str(pn["id"])] = true
	say("« " + str(pn["texte"]) + " »", 7.0)


func _regarder_palette() -> void:
	state["palette"] = true
	say("La Palette de pierre : neuf godets numérotés, de 1 à 9, tous vides et secs. Au fond du premier, une toute petite trace de bleu… Qui a pris les couleurs de l'île ?", 9.0)


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


# =================================================================== services du jeu

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func owns_point(p: Vector3) -> bool:
	return contains(p)


func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	var l: Vector2 = IleScript.L(p.x, p.z)
	var md: float = IleScript.mont_d(l.x, l.y)
	var sm: Array = IleScript.PADS["sommet"]
	if l.distance_to(Vector2(float(sm[0]), float(sm[1]))) < float(sm[2]) + 8.0:
		return "sommet"
	if cascade_top != Vector3.ZERO and Vector2(p.x - cascade_top.x, p.z - cascade_top.z).length() < 9.0:
		return "cascade"
	if l.distance_to(Vector2(float(IleScript.ETANG[0]), float(IleScript.ETANG[1]))) < float(IleScript.ETANG[2]) + 7.0:
		return "etang"
	var cl: Array = IleScript.PADS["clairiere"]
	if l.distance_to(Vector2(float(cl[0]), float(cl[1]))) < float(cl[2]) + 2.0:
		return "clairiere"
	if md < float(IleScript.MONT[2]) * 0.8 and IleScript.falaise_k(l.x, l.y) < 0.5:
		return "mont"
	for f in ile.flows_world:
		for i in range(0, (ile.flows_world[f] as Array).size(), 3):
			var fp: Vector3 = ile.flows_world[f][i]
			if Vector2(fp.x - p.x, fp.z - p.z).length() < 4.0:
				return "ruisseau"
	if IleScript.beach_k(l.x, l.y) > 0.4 and IleScript.coast_q(l.x, l.y) > 0.82:
		return "plage"
	var b2: Color = ile.biome2_at(p.x, p.z)
	if b2.r > 0.5:
		return "bois"
	if b2.g > 0.4:
		return "pres"
	return "prairie"


func place_name(p: Vector3) -> String:
	return "L'Île Crayonnée, " + str(PLACES.get(zone_at(p), "l'île"))


## Pour la téléportation : on arrive sur la Grève Blanche, au bout du ponton, face à l'île.
func village_point(_id: String) -> Array:
	return respawn_point()


func respawn_point() -> Array:
	var p: Vector3 = _ground(10.0, 143.0) + Vector3.UP * 0.3
	return [p, Vector3(0, 0, -1)]


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])


func hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _sun() -> DirectionalLight3D:
	var t: Node = main.get("temps_v56")
	if t != null and t.get("sun") != null:
		return t.sun
	for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		return n
	return null


func _update_globals() -> void:
	var s: DirectionalLight3D = _sun()
	if s != null:
		RenderingServer.global_shader_parameter_set("crayon_soleil", s.global_transform.basis.z.normalized())
	var h: float = hour()
	# le papier s'éclaire un peu le jour (une page blanche reste blanche), pas la nuit
	var jour: float = clampf(smoothstep(5.5, 8.0, h) * (1.0 - smoothstep(18.5, 21.0, h)), 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("crayon_jour", jour)


func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	_update_mask(delta)
	var p: Vector3 = main._player_pos_v27()
	var dist: float = Vector2(p.x - IleScript.CENTER.x, p.z - IleScript.CENTER.z).length()
	_glob_t -= delta
	if _glob_t <= 0.0 and dist < 1500.0:
		_glob_t = 1.0
		_update_globals()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and ile.height(p.x, p.z) > -0.2 and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île Crayonnée — ici, tout est en noir et blanc, comme une page de coloriage oubliée… Qui a pris les couleurs de l'île ?")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 1.0
	var z: String = zone_at(p)
	var vis: Dictionary = state["visites"]
	if z == "sommet":
		state["sommet"] = true
	if z == "cascade":
		state["cascade"] = true
	if z == "etang":
		state["etang"] = true
	if z in ["clairiere", "bois", "mont", "sommet", "cascade", "etang", "ruisseau", "pres"] and not bool(vis.get(z, false)):
		vis[z] = true
		match z:
			"clairiere":
				main._show_message_v28("La Clairière des Géants — un grand cercle d'herbe rase, de vieux chênes tout autour, et au milieu… une palette de peintre en pierre")
			"bois":
				main._show_message_v28("Le Bois des Hachures — des chênes et des bouleaux dessinés à la plume, trait par trait")
			"mont":
				main._show_message_v28("Le Mont Fusain — une grosse colline ronde ; le sentier monte jusqu'au sommet")
			"sommet":
				main._show_message_v28("Le sommet du Mont Fusain — toute l'île, en noir et blanc, comme un dessin posé sur la mer bleue")
			"cascade":
				main._show_message_v28("La Cascade d'Encre — le ruisseau tombe de la falaise dans l'étang, en longs traits de plume")
			"etang":
				main._show_message_v28("L'Étang Gommé — une eau calme, des nénuphars dessinés au crayon")
			"ruisseau":
				main._show_message_v28("Le Ruisseau Pointillé — il file vers la mer en petites vagues tracées à l'encre")
			"pres":
				main._show_message_v28("Les Prés Blancs — des milliers de fleurs… toutes blanches, en attendant leurs couleurs")
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))


func trouvailles() -> Dictionary:
	var vis: Dictionary = state.get("visites", {})
	return {"crayon": 1 if bool(state.get("visite", false)) else 0,
		"crayon_clairiere": 1 if bool(vis.get("clairiere", false)) else 0,
		"crayon_palette": 1 if bool(state.get("palette", false)) else 0,
		"crayon_sommet": 1 if bool(state.get("sommet", false)) else 0,
		"crayon_cascade": 1 if bool(state.get("cascade", false)) else 0,
		"crayon_etang": 1 if bool(state.get("etang", false)) else 0,
		"crayon_bois": 1 if bool(vis.get("bois", false)) else 0,
		"crayon_pres": 1 if bool(vis.get("pres", false)) else 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary or d[k] is Array) else d[k].duplicate(true)
	if ile != null and masque != null:
		_tache_depart()

extends Node3D
## V141 : les sensations des coups.
##  - chaque coup qui porte fait réagir l'ennemi : le choc le repousse d'un pas, son corps plie sous
##    le coup puis se redresse ; en VR, il se fige un instant (le poids du coup, sans bouger la vue) ;
##  - les coups lourds (le coup chargé, la riposte, l'attaque tournoyante, les coups critiques, le
##    dernier coup d'un enchaînement de poings) le font tituber : il perd l'équilibre une demi-seconde
##    et son attaque est coupée ;
##  - le coup final d'un enchaînement à la lame, le coup chargé et le coup plongeant mettent à terre
##    les petits et moyens ennemis : ils tombent à la renverse dans un nuage de poussière, restent au
##    sol un instant, puis se relèvent ;
##  - les gros ennemis reculent à peine et ne tombent pas ; les boss ne font que plier ;
##  - le coup plongeant (au PC : frapper en plein saut ; en VR : frapper vers le bas en l'air) et le
##    coup frappé au sol (VR) : une onde de choc, un anneau de poussière, des éclats de pierre, et le
##    sol fendu un moment ;
##  - en « Public averti » seulement, les bêtes de chair saignent un peu sous les coups.

const Public = preload("res://scripts/public_v111.gd")

## Les bêtes qui saignent (en « Public averti » seulement) : des animaux de chair et de sang.
const CHAIR := ["sanglier", "loup_bois", "loup_plaine", "loup", "ours_lande", "aurochs", "bouc", "chacal", "coyote", "jaguar_sauvage",
	"crocodile", "varan", "singe_hurleur", "lynx", "blaireau", "molosse_cendre", "lapin_garenne", "cheval_sauvage", "gobelin",
	"gobelin_chef", "rat", "chauve_souris_mont", "crapaud_vase", "serpent_sable", "vipere", "hyene", "requin"]

var main: Node
var count: Dictionary = {}               # tests : sorte de réaction -> nombre
var _reac: Dictionary = {}               # id de l'ennemi -> sa réaction en cours
static var _fente: Texture2D


func setup(main_node: Node) -> void:
	main = main_node
	name = "Coups_v141"


func _n(k: String) -> void:
	count[k] = int(count.get(k, 0)) + 1


func _fx() -> Node:
	return main.get("combat_fx_v129") if main != null else null


func _vr() -> bool:
	return main != null and bool(main.get("xr_active"))


# =================================================================== le poids d'un ennemi

## 0 : un boss (il ne fait que plier) ; 1 : gros ; 2 : moyen ; 3 : petit.
func poids(t: Node) -> int:
	var path: String = str(t.get_script().resource_path) if t.get_script() != null else ""
	if path.contains("boss"):
		return 0
	var sp: Dictionary = t.get("spec") if t.get("spec") is Dictionary else {}
	var pv: int = int(sp.get("pv", t.get("hp") if t.get("hp") != null else 10))
	if pv >= 50:
		return 0
	var r: float = float(t.get("hit_radius")) if t.get("hit_radius") != null else 0.5
	if pv > 30 or r > 1.1:
		return 1
	if pv > 12 or r > 0.65:
		return 2
	return 3


## Une bête de chair (pour le sang, en « Public averti »).
func chair(t: Node) -> bool:
	return str(t.get("kind")) in CHAIR


# =================================================================== réagir à un coup

## L'ennemi « t » vient de prendre un coup venu de « from ». force : 1 coup simple, 2 coup lourd
## (il titube), 3 coup qui met à terre.
func reagir(t: Node3D, from: Vector3, force: int) -> void:
	if not is_instance_valid(t) or not ("_knock" in t) or not ("spec" in t):
		return
	if str(t.get("state")) == "mort":
		_n("tue")
		_sang(t, from, 2)
		return
	var w: int = poids(t)
	var dir: Vector3 = t.global_position - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else -Vector3(t.get("facing")) if t.get("facing") != null else Vector3.FORWARD
	# le recul (le coup repousse), selon le poids
	var kb: float = [0.0, 0.5, 1.0, 1.35][w] * (1.2 if force <= 1 else (3.2 if force == 2 else 3.0))
	var id: int = t.get_instance_id()
	var r: Dictionary = _reac.get(id, {})
	var en_cours: String = str(r.get("genre", ""))
	# déjà à terre : il y reste (le coup ne fait que le secouer)
	if en_cours == "terre":
		r["coup"] = 0.0
		_sang(t, from, 1)
		return
	var genre: String = "plie"
	if force >= 3 and w >= 2:
		genre = "terre"
	elif force >= 2 and w >= 1:
		genre = "titube"
	var angle: float = deg_to_rad(9.0 if genre == "plie" else 20.0) * (0.45 if w == 0 else (0.65 if w == 1 else 1.0))
	if r.is_empty():
		r = {"node": t, "x0": t.rotation.x, "z0": t.rotation.z, "phys": t.is_physics_processing()}
		var v: Node3D = t.get("_visual")
		if v != null:
			r["s0"] = v.scale
	r["genre"] = genre
	r["t"] = 0.0
	r["dir"] = dir
	r["angle"] = angle
	r["coup"] = 0.0
	r.erase("lat")
	if genre == "terre":
		# un quadrupède roule sur le flanc ; un bipède tombe à la renverse
		r["y0"] = t.global_position.y
		var bipede: bool = float(t.get("hit_height")) > float(t.get("hit_radius")) * 1.3
		if bipede:
			r["lift"] = 0.12
			r["full"] = deg_to_rad(78.0)
		else:
			var local0: Vector3 = Basis(Vector3.UP, t.rotation.y).inverse() * dir
			var side: float = signf(local0.x) if absf(local0.x) > 0.25 else (1.0 if randf() < 0.5 else -1.0)
			r["lat"] = Vector3(side, 0.0, 0.0)
			r["lift"] = float(t.get("hit_radius")) * 0.55
			r["full"] = deg_to_rad(86.0)
	# le temps où il ne bouge plus (titube, à terre ; en VR, un instant à chaque coup)
	var pause: float = 0.0
	match genre:
		"titube":
			pause = [0.0, 0.25, 0.35, 0.45][w]
		"terre":
			pause = 1.75
		_:
			pause = 0.07 if _vr() else 0.0
	r["pause"] = pause
	_reac[id] = r
	_n(genre)
	# immobile (une bête qu'on a figée) : il ne fait que plier, sans bouger
	if bool(r["phys"]):
		if pause > 0.0:
			# figé, il glisse quand même sous le choc (sans élan retardé à la reprise)
			t.set_physics_process(false)
			r["glisse"] = dir * kb
			t.set("_knock", Vector3.ZERO)
		elif kb > 0.0:
			t.set("_knock", Vector3(t.get("_knock")) + dir * kb)
	# l'élan de l'ennemi est coupé
	if genre != "plie" and str(t.get("state")) in ["armer", "frappe", "charge", "fonce", "saut"]:
		t.set("state", "recul")
		t.set("timer", 0.3)
	if genre == "terre":
		_texte(t, "À terre !", Color(1.0, 0.85, 0.5))
	_sang(t, from, 1 if force <= 1 else 2)


func _texte(t: Node3D, s: String, col: Color) -> void:
	var cb: Node = main.get("combat_v28") if main != null else null
	if cb != null and cb.has_method("float_text"):
		cb.float_text(t.global_position + Vector3.UP * (float(t.get("hit_height")) * 2.0 + 0.9), s, col)


## Un peu de sang (en « Public averti » seulement, sur les bêtes de chair).
func _sang(t: Node3D, from: Vector3, n: int) -> void:
	if not Public.averti() or not chair(t):
		return
	var fx: Node = _fx()
	if fx == null:
		return
	_n("sang")
	var at: Vector3 = t.global_position + Vector3.UP * float(t.get("hit_height"))
	var d: Vector3 = at - from
	d.y = 0.3
	d = d.normalized() if d.length() > 0.01 else Vector3.UP
	fx._burst(at, {"amount": 8 * n, "life": 0.55, "v0": 1.5, "v1": 3.5, "dir": d, "spread": 40.0, "grav": Vector3(0, -9.8, 0), "size": 0.05,
		"add": false, "mesh": "box", "cols": [Color(0.45, 0.02, 0.02), Color(0.3, 0.01, 0.01, 0.9)]})


func _process(delta: float) -> void:
	for id in _reac.keys():
		var r: Dictionary = _reac[id]
		var obj: Variant = r["node"]
		if not is_instance_valid(obj):
			_reac.erase(id)
			continue
		var t: Node3D = obj
		var mort: bool = str(t.get("state")) == "mort"
		r["t"] = float(r["t"]) + delta
		r["coup"] = float(r["coup"]) + delta
		var tt: float = float(r["t"])
		var genre: String = str(r["genre"])
		var a: float = 0.0
		var sq: float = 0.0
		var fini: bool = false
		match genre:
			"plie", "titube":
				var dur: float = 0.35 if genre == "plie" else 0.3 + float(r["pause"])
				var k: float = tt / 0.06 if tt < 0.06 else exp(-(tt - 0.06) * (12.0 if genre == "plie" else 6.0)) * cos((tt - 0.06) * (18.0 if genre == "plie" else 11.0))
				a = float(r["angle"]) * k
				sq = maxf(0.0, k) * (0.6 if genre == "plie" else 1.0)
				fini = tt >= dur
			"terre":
				# il bascule (0,28 s), reste au sol, puis se relève (0,45 s)
				var full: float = float(r.get("full", deg_to_rad(78.0)))
				if tt < 0.28:
					a = full * smoothstep(0.0, 1.0, tt / 0.28)
				elif tt < 1.3:
					a = full + sin(minf(float(r["coup"]), 0.3) / 0.3 * PI) * deg_to_rad(4.0)
					if not bool(r.get("poussiere", false)):
						r["poussiere"] = true
						_tombe(t, r)
				elif tt < 1.75:
					a = full * (1.0 - smoothstep(0.0, 1.0, (tt - 1.3) / 0.45))
				else:
					fini = true
		if mort:
			fini = true
		# figé, il glisse sous le choc
		if r.has("glisse") and not t.is_physics_processing():
			var g: Vector3 = r["glisse"]
			if g.length() > 0.05:
				var ahead: Vector3 = t.global_position + g * delta
				if _libre(t, t.global_position, ahead + g.normalized() * 0.35):
					t.global_position = ahead
					r["glisse"] = g.move_toward(Vector3.ZERO, delta * 14.0)
				else:
					r["glisse"] = Vector3.ZERO
		# la pause s'achève : il reprend vie (et sa mort, s'il est tombé sous les coups)
		if bool(r["phys"]) and not t.is_physics_processing() and (tt >= float(r["pause"]) or mort):
			t.set_physics_process(true)
		if fini:
			if not mort:
				t.rotation.x = float(r["x0"])
				t.rotation.z = float(r["z0"])
				if r.has("y0"):
					t.global_position.y = float(r["y0"])
				var v0: Node3D = t.get("_visual")
				if v0 != null and r.has("s0"):
					v0.scale = r["s0"]
			if bool(r["phys"]) and not t.is_physics_processing():
				t.set_physics_process(true)
			_reac.erase(id)
			continue
		# le corps penche à l'opposé du coup (dans le repère de l'ennemi, tourné seulement autour de y) ;
		# à terre, un quadrupède roule sur le flanc
		var local: Vector3 = r["lat"] if r.has("lat") else Basis(Vector3.UP, t.rotation.y).inverse() * (r["dir"] as Vector3)
		if genre == "terre" and r.has("y0") and not mort:
			var full2: float = float(r.get("full", deg_to_rad(78.0)))
			t.global_position.y = float(r["y0"]) + float(r.get("lift", 0.0)) * sin(clampf(a / full2, 0.0, 1.0) * PI * 0.5)
		t.rotation.x = float(r["x0"]) + a * local.z
		t.rotation.z = float(r["z0"]) - a * local.x
		var v: Node3D = t.get("_visual")
		if v != null and r.has("s0"):
			var s0: Vector3 = r["s0"]
			v.scale = Vector3(s0.x * (1.0 + 0.06 * sq), s0.y * (1.0 - 0.1 * sq), s0.z * (1.0 + 0.06 * sq))


## Rien entre a et b (un mur, un rocher, un tronc) ?
func _libre(t: Node3D, a: Vector3, b: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var q := PhysicsRayQueryParameters3D.create(a + Vector3.UP * 0.45, b + Vector3.UP * 0.45, 1)
	var ex: Array = []
	if t is CollisionObject3D:
		ex.append((t as CollisionObject3D).get_rid())
	for body in [main.get("pc_body"), main.get("vr_body")]:
		if body != null and is_instance_valid(body) and body.has_method("get_rid"):
			ex.append(body.get_rid())
	q.exclude = ex
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Il touche le sol : un nuage de poussière (là où son corps retombe), un bruit sourd.
func _tombe(t: Node3D, r: Dictionary) -> void:
	_n("tombe")
	var fx: Node = _fx()
	var cote: Vector3 = t.global_basis.x * float((r["lat"] as Vector3).x) if r.has("lat") else (r["dir"] as Vector3)
	cote.y = 0.0
	var at: Vector3 = t.global_position + cote.normalized() * float(t.get("hit_height")) * 1.4
	if fx != null:
		fx._puffs(at + Vector3.UP * 0.12, 12, Color(0.62, 0.56, 0.46, 0.6), 0.4, 1.5, 1.2, 0.4, 1.5, 0.12, 0.5)
	if main != null and main.has_method("sfx"):
		main.sfx("chute_corps", at)


## Est-il à terre (ou en train de tomber, ou de se relever) ?
func a_terre(t: Node) -> bool:
	if not is_instance_valid(t):
		return false
	return str(_reac.get(t.get_instance_id(), {}).get("genre", "")) == "terre"


# =================================================================== l'onde de choc au sol

## Le sol frappé de toute sa force (coup plongeant, coup frappé au sol) : l'onde, la poussière,
## les éclats de pierre, la fente qui s'efface.
func onde_sol(at: Vector3, rayon: float) -> void:
	_n("onde")
	var fx: Node = _fx()
	if fx == null:
		return
	var gy: float = float(fx._ground_y(at + Vector3.UP * 0.5, at.y))
	var c := Vector3(at.x, gy, at.z)
	var rg: MeshInstance3D = fx._flat(c + Vector3.UP * 0.06, Vector3.UP, fx.ring_tex(), Color(1.0, 0.9, 0.7), 1.0)
	fx._add(rg, 0.42, Color(1.0, 0.9, 0.7), rg.get_meta("mat"), 0.4, rayon * 2.3)
	var rg2: MeshInstance3D = fx._flat(c + Vector3.UP * 0.05, Vector3.UP, fx.ring_tex(), Color(0.85, 0.7, 0.45), 1.0)
	fx._add(rg2, 0.7, Color(0.85, 0.7, 0.45), rg2.get_meta("mat"), 0.3, rayon * 1.5)
	# l'anneau de poussière qui roule vers l'extérieur
	for k in range(22):
		var ang: float = TAU * float(k) / 22.0 + randf_range(-0.1, 0.1)
		var d := Vector3(cos(ang), 0.0, sin(ang))
		var q: MeshInstance3D = fx._quad(c + d * 0.5 + Vector3.UP * 0.3, preload("res://scripts/armes_v129.gd").dot(), Color(0.64, 0.58, 0.48, 0.75), 1.0, true, false)
		fx._add(q, randf_range(0.9, 1.4), Color(0.64, 0.58, 0.48, 0.75), q.get_meta("mat"), 0.6, 2.1, "pop", {"vel": d * randf_range(3.5, 5.5) + Vector3.UP * 0.5})
	# les éclats de pierre et les mottes de terre
	fx._burst(c + Vector3.UP * 0.1, {"amount": 22, "life": 0.9, "v0": 3.0, "v1": 6.5, "dir": Vector3.UP, "spread": 60.0, "grav": Vector3(0, -14.0, 0),
		"size": 0.09, "mesh": "box", "add": false, "cols": [Color(0.42, 0.38, 0.32), Color(0.3, 0.27, 0.22)]})
	fx._light(c + Vector3.UP * 0.4, Color(1.0, 0.85, 0.6), 3.0, 5.0, 0.18)
	_fente_au_sol(c, rayon)
	fx.shake(0.16)
	fx.haptic(0.9, 0.22)
	if main != null and main.has_method("sfx"):
		main.sfx("frappe_sol", c + Vector3.UP * 0.3)


## Le coup final d'un enchaînement : une onde rasante devant soi, la poussière qui se soulève.
func coup_final(at: Vector3, dir: Vector3, touche: bool = true) -> void:
	_n("final")
	var fx: Node = _fx()
	if fx == null:
		return
	var gy: float = float(fx._ground_y(at + Vector3.UP * 0.5, at.y - 1.0))
	var c := Vector3(at.x, gy, at.z)
	var rg: MeshInstance3D = fx._flat(c + Vector3.UP * 0.05, Vector3.UP, fx.ring_tex(), Color(1.0, 0.95, 0.85), 1.0)
	fx._add(rg, 0.32, Color(1.0, 0.95, 0.85), rg.get_meta("mat"), 0.3, 2.6)
	fx._puffs(c + Vector3.UP * 0.2 + dir * 0.3, 7, Color(0.66, 0.6, 0.5, 0.45), 0.3, 1.1, 0.8, 0.6, 1.8, 0.1, 0.35)
	if touche:
		fx.hitstop(0.05)
		fx.shake(0.07)
		fx.haptic(0.7, 0.14)
	if main != null and main.has_method("sfx"):
		main.sfx("coup_final", at)


## La fente dans le sol : posée à plat sur le terrain (selon sa pente), elle s'efface au bout de
## quelques secondes.
func _fente_au_sol(c: Vector3, rayon: float) -> void:
	var n := Vector3.UP
	if is_inside_tree():
		var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 1.0, c + Vector3.DOWN * 1.5, 1)
		var ex: Array = []
		for body in [main.get("pc_body"), main.get("vr_body")]:
			if body != null and is_instance_valid(body) and body.has_method("get_rid"):
				ex.append(body.get_rid())
		q.exclude = ex
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			n = (hit.normal as Vector3).normalized()
			c = hit.position
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(rayon * 1.7, rayon * 1.7)
	qm.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _fente_tex()
	m.albedo_color = Color(0.13, 0.1, 0.07, 0.92)
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = m
	mi.mesh = qm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var x_axis: Vector3 = n.cross(Vector3.FORWARD).normalized() if absf(n.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var z_axis: Vector3 = x_axis.cross(n).normalized()
	mi.global_transform = Transform3D(Basis(x_axis, n, z_axis) * Basis(Vector3.UP, randf() * TAU), c + n * 0.03)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(m, "albedo_color:a", 0.0, 2.0)
	tw.tween_callback(mi.queue_free)


static func _fente_tex() -> Texture2D:
	if _fente != null:
		return _fente
	var n: int = 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1411
	# des fentes qui partent du centre et se ramifient
	var branches: Array = []
	for k in range(9):
		branches.append([Vector2(n * 0.5, n * 0.5), TAU * float(k) / 9.0 + rng.randf_range(-0.25, 0.25), 3.2, 0])
	while not branches.is_empty():
		var b: Array = branches.pop_back()
		var p: Vector2 = b[0]
		var ang: float = b[1]
		var w: float = b[2]
		var gen: int = b[3]
		var steps: int = rng.randi_range(14, 26) if gen == 0 else rng.randi_range(6, 14)
		for s in range(steps):
			ang += rng.randf_range(-0.35, 0.35)
			p += Vector2(cos(ang), sin(ang)) * 4.0
			var rr: float = maxf(0.6, w * (1.0 - float(s) / float(steps) * 0.6))
			for yy in range(int(p.y - rr - 1), int(p.y + rr + 2)):
				for xx in range(int(p.x - rr - 1), int(p.x + rr + 2)):
					if xx < 0 or yy < 0 or xx >= n or yy >= n:
						continue
					var d: float = Vector2(xx, yy).distance_to(p)
					if d <= rr:
						var al: float = clampf(1.0 - d / (rr + 0.01) * 0.5, 0.0, 1.0)
						var old: Color = img.get_pixel(xx, yy)
						img.set_pixel(xx, yy, Color(1, 1, 1, maxf(old.a, al)))
			if gen < 2 and rng.randf() < 0.12:
				branches.append([p, ang + rng.randf_range(-0.9, 0.9), w * 0.55, gen + 1])
	img.generate_mipmaps()
	_fente = ImageTexture.create_from_image(img)
	return _fente

extends Node3D
## V129 : le spectacle du combat et de la magie.
##  - chaque coup qui porte : un éclair blanc, une onde, des étincelles qui filent, une lueur, et
##    l'effet de l'âme de l'arme (braises de forge, arcs d'orage, gouttes de marée, éclats de
##    cristal rouge, paillettes d'or, runes violettes, copeaux de bois) ;
##  - le « coup qui pèse » : un arrêt sur image d'un vingtième de seconde au PC (un peu plus long
##    pour un critique) et une secousse de caméra ; en VR, la manette vibre à la place (pas de
##    ralenti ni de secousse en VR, pour le confort) ;
##  - coup chargé : un croissant d'énergie part devant la lame ; tournoyante : un anneau-comète ;
##  - les sorts : un cercle de runes s'ouvre au sol et devant les mains (dans la couleur du
##    sort) ; la boule de feu a un cœur blanc, des flammèches et de la fumée, et explose en
##    boule de flammes avec une onde au sol ; le gel fait jaillir des pics de glace qui
##    éclatent ; le soin, trois feux-follets verts qui montent en spirale autour du héros ; la
##    lévitation, un tourbillon de vent sous les pieds ; la télékinésie, un halo violet sur
##    l'objet qui vole.
## Tout est fait d'objets éphémères animés ici (_fx) et de particules qui se détruisent seules.

const Armes := preload("res://scripts/armes_v129.gd")

const POUVOIRS := {
	"vent": Color(0.7, 0.95, 1.0), "flamme": Color(1.0, 0.5, 0.15), "rouage": Color(1.0, 0.78, 0.35), "lune": Color(0.75, 0.82, 1.0),
}

var main: Node
var count: Dictionary = {}               # tests : genre d'effet -> nombre
var last_genre: String = ""
var _fx: Array = []
var _hs_until: int = 0
var _shake: float = 0.0
var _last_ms: int = 0
var hitstop_enabled: bool = true

static var _ring_tex: Texture2D
static var _circle_tex: Texture2D
static var _streak: ArrayMesh
static var _crescent: ArrayMesh
static var _comet: ArrayMesh
static var _ice: ArrayMesh
static var _ice_mat: StandardMaterial3D


func setup(main_node: Node) -> void:
	main = main_node
	_last_ms = Time.get_ticks_msec()
	# le cercle de runes est dessiné une fois pour toutes, dès le début (≈ 0,15 s)
	circle_tex.call_deferred()


func _exit_tree() -> void:
	if _hs_until > 0:
		Engine.time_scale = 1.0
		_hs_until = 0


func _n(kind: String) -> void:
	count[kind] = int(count.get(kind, 0)) + 1


# =================================================================== textures et maillages

static func ring_tex() -> Texture2D:
	if _ring_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.add_point(0.76, Color(1, 1, 1, 0.0))
		g.add_point(0.9, Color(1, 1, 1, 1.0))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_ring_tex = t
	return _ring_tex


## Le cercle de runes (blanc ; la couleur vient du matériau) : deux anneaux, des runes entre
## eux, une étoile à six branches et un petit anneau au centre. Calculé une fois (256 × 256).
static func circle_tex() -> Texture2D:
	if _circle_tex != null:
		return _circle_tex
	var N: int = 256
	var img := Image.create(N, N, false, Image.FORMAT_LA8)
	var c := Vector2(N * 0.5, N * 0.5)
	var R: float = N * 0.5
	# segments de l'étoile (deux triangles) et des runes
	var segs: Array = []
	for tri in [0.0, PI / 3.0]:
		for k in range(3):
			var a0: float = tri + TAU * k / 3.0 - PI * 0.5
			var a1: float = tri + TAU * (k + 1) / 3.0 - PI * 0.5
			segs.append([c + Vector2(cos(a0), sin(a0)) * R * 0.66, c + Vector2(cos(a1), sin(a1)) * R * 0.66, 1.4])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1290
	for k in range(24):
		var a: float = TAU * (k + 0.5) / 24.0
		var dirv := Vector2(cos(a), sin(a))
		var tan := Vector2(-dirv.y, dirv.x)
		var base: Vector2 = c + dirv * R * 0.8
		var h: float = R * 0.065
		var w: float = R * 0.045
		segs.append([base - dirv * h, base + dirv * h, 1.1])
		for j in range(rng.randi_range(1, 2)):
			var o: float = rng.randf_range(-0.7, 0.7)
			var side: float = -1.0 if rng.randf() < 0.5 else 1.0
			segs.append([base + dirv * h * o, base + dirv * h * (o + rng.randf_range(-0.6, 0.6)) + tan * w * side, 1.0])
	var buf := PackedFloat32Array()
	buf.resize(N * N)
	for y in range(N):
		for x in range(N):
			var r: float = Vector2(x + 0.5 - c.x, y + 0.5 - c.y).length() / R
			var v: float = 0.0
			for rr in [[0.95, 0.012], [0.9, 0.006], [0.69, 0.009], [0.66, 0.004], [0.22, 0.01], [0.18, 0.005]]:
				v = maxf(v, clampf(1.0 - absf(r - float(rr[0])) / float(rr[1]), 0.0, 1.0))
			# un voile doux entre les anneaux
			if r < 0.95:
				v = maxf(v, 0.10 * smoothstep(0.6, 0.94, r))
			buf[y * N + x] = v
	# les traits, pixel par pixel dans leur seul rectangle
	for sgm in segs:
		var a: Vector2 = sgm[0]
		var b: Vector2 = sgm[1]
		var wdt: float = float(sgm[2])
		var ab: Vector2 = b - a
		var x0: int = clampi(int(floor(minf(a.x, b.x) - 3.0)), 0, N - 1)
		var x1: int = clampi(int(ceil(maxf(a.x, b.x) + 3.0)), 0, N - 1)
		var y0: int = clampi(int(floor(minf(a.y, b.y) - 3.0)), 0, N - 1)
		var y1: int = clampi(int(ceil(maxf(a.y, b.y) + 3.0)), 0, N - 1)
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var p := Vector2(x + 0.5, y + 0.5)
				var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
				var d: float = p.distance_to(a + ab * t)
				var v2: float = clampf(wdt - d * 0.75, 0.0, 1.0)
				if v2 > buf[y * N + x]:
					buf[y * N + x] = v2
	for y in range(N):
		for x in range(N):
			img.set_pixel(x, y, Color(1, 1, 1, buf[y * N + x]))
	img.generate_mipmaps()
	_circle_tex = ImageTexture.create_from_image(img)
	return _circle_tex


## Étincelle étirée : deux quads en croix le long de Y (toujours visible).
static func streak_mesh() -> ArrayMesh:
	if _streak != null:
		return _streak
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w: float = 0.007
	var h: float = 0.12
	for ax in [Vector3.RIGHT, Vector3.BACK]:
		var o: Vector3 = ax * w
		var pts := [[-o + Vector3(0, -h, 0), Vector2(0, 1)], [o + Vector3(0, -h, 0), Vector2(1, 1)], [o + Vector3(0, h, 0), Vector2(1, 0)], [-o + Vector3(0, h, 0), Vector2(0, 0)]]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_uv(pts[idx][1])
			st.add_vertex(pts[idx][0])
	_streak = st.commit()
	return _streak


## Croissant d'énergie (vers -Z), alpha : vif au bord extérieur, nul au bord intérieur et aux bouts.
static func crescent_mesh(full: bool = false) -> ArrayMesh:
	if full and _comet != null:
		return _comet
	if not full and _crescent != null:
		return _crescent
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 40
	var a0: float = -1.25
	var a1: float = 1.25
	if full:
		a0 = 0.0
		a1 = TAU
	for i in range(n):
		var u0: float = float(i) / n
		var u1: float = float(i + 1) / n
		var pts: Array = []
		for u in [u0, u1]:
			var a: float = lerpf(a0, a1, u)
			var fade: float = sin(u * PI) if not full else u * u
			var wid: float = 0.35 * (sin(u * PI) if not full else (0.25 + 0.75 * u))
			var dirv := Vector3(sin(a), 0, -cos(a))
			pts.append([dirv * 1.0, Color(1, 1, 1, fade)])
			pts.append([dirv * (1.0 - wid), Color(1, 1, 1, 0.0)])
		for idx in [0, 2, 1, 1, 2, 3]:
			st.set_color(pts[idx][1])
			st.add_vertex(pts[idx][0])
	var m: ArrayMesh = st.commit()
	if full:
		_comet = m
	else:
		_crescent = m
	return m


static func ice_mesh() -> ArrayMesh:
	if _ice != null:
		return _ice
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Armes._add_gemme(st, 0.11, 0.62, 0.08, 6, Transform3D(Basis(), Vector3(0, 0.05, 0)))
	Armes._add_gemme(st, 0.07, 0.38, 0.06, 6, Transform3D(Basis(Vector3.FORWARD, 0.45), Vector3(0.1, 0.02, 0.02)))
	Armes._add_gemme(st, 0.06, 0.3, 0.05, 6, Transform3D(Basis(Vector3.RIGHT, -0.5) * Basis(Vector3.FORWARD, -0.3), Vector3(-0.07, 0.02, 0.06)))
	_ice = st.commit()
	_ice_mat = StandardMaterial3D.new()
	_ice_mat.albedo_color = Color(0.72, 0.9, 1.0, 0.78)
	_ice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ice_mat.roughness = 0.05
	_ice_mat.metallic = 0.1
	_ice_mat.clearcoat_enabled = true
	_ice_mat.rim_enabled = true
	_ice_mat.rim = 0.8
	_ice_mat.emission_enabled = true
	_ice_mat.emission = Color(0.35, 0.65, 1.0)
	_ice_mat.emission_energy_multiplier = 0.5
	return _ice


# =================================================================== petites briques

func _mat(col: Color, tex: Texture2D, billboard: bool, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	m.albedo_texture = tex
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.disable_receive_shadows = true
	return m


## Un objet éphémère : il grandit (s0 -> s1), s'efface (alpha : fade, pop, hold), tourne, file.
func _add(node: Node3D, life: float, col: Color, mat: StandardMaterial3D, s0: float, s1: float, alpha: String = "fade", extra: Dictionary = {}) -> Dictionary:
	var e: Dictionary = {"node": node, "t": 0.0, "life": life, "col": col, "mat": mat, "s0": s0, "s1": s1, "alpha": alpha}
	e.merge(extra)
	node.scale = Vector3.ONE * maxf(s0, 0.001)
	_fx.append(e)
	return e


func _quad(at: Vector3, tex: Texture2D, col: Color, size: float, billboard: bool = true, additive: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := _mat(col, tex, billboard, additive)
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = at
	mi.set_meta("mat", m)
	return mi


## Un quad posé à plat sur un plan de normale n (cercles, ondes au sol).
func _flat(at: Vector3, n: Vector3, tex: Texture2D, col: Color, size: float) -> MeshInstance3D:
	var mi := _quad(at, tex, col, size, false)
	var up: Vector3 = Vector3.UP if absf(n.normalized().dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	mi.global_basis = Basis.looking_at(-n.normalized(), up)
	return mi


func _light(at: Vector3, col: Color, energy: float, rng: float, life: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	add_child(l)
	l.global_position = at
	_fx.append({"node": l, "t": 0.0, "life": life, "light0": energy, "alpha": "light"})


## Une gerbe de particules qui se détruit seule. p : amount, life, v0, v1, dir, spread, grav,
## size, cols (Array de couleurs du dégradé), mesh ("dot", "streak", "box"), add (bool),
## damping, radius, grow (bool), local (Node3D à suivre).
func _burst(at: Vector3, p: Dictionary) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.amount = maxi(int(p.get("amount", 12)), 1)
	s.lifetime = float(p.get("life", 0.5))
	s.one_shot = not bool(p.get("loop", false))
	s.explosiveness = float(p.get("explo", 0.95))
	s.local_coords = false
	s.direction = p.get("dir", Vector3.UP)
	s.spread = float(p.get("spread", 180.0))
	s.gravity = p.get("grav", Vector3(0, -9.0, 0))
	s.initial_velocity_min = float(p.get("v0", 1.0))
	s.initial_velocity_max = float(p.get("v1", 3.0))
	s.damping_min = float(p.get("damping", 0.0))
	s.damping_max = float(p.get("damping", 0.0))
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	s.emission_sphere_radius = float(p.get("radius", 0.05))
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.2
	var kind: String = str(p.get("mesh", "dot"))
	var size: float = float(p.get("size", 0.08))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if bool(p.get("add", true)) else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	if kind == "streak":
		s.mesh = streak_mesh()
		s.particle_flag_align_y = true
		m.albedo_texture = Armes.dot()
		s.scale_amount_min = size / 0.2 * 0.7
		s.scale_amount_max = size / 0.2 * 1.3
		s.mesh = streak_mesh().duplicate()
		(s.mesh as ArrayMesh).surface_set_material(0, m)
	elif kind == "box":
		var b := BoxMesh.new()
		b.size = Vector3(size, size * 0.5, size * 0.7)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if not bool(p.get("add", true)) else BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if not bool(p.get("add", true)) else BaseMaterial3D.TRANSPARENCY_ALPHA
		b.material = m
		s.mesh = b
		s.angle_min = 0.0
		s.angle_max = 360.0
	else:
		var q := QuadMesh.new()
		q.size = Vector2(size, size)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.albedo_texture = Armes.dot()
		q.material = m
		s.mesh = q
	var cols: Array = p.get("cols", [Color.WHITE, Color(1, 1, 1, 0)])
	var g := Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, cols[cols.size() - 1])
	for i in range(1, cols.size() - 1):
		g.add_point(float(i) / (cols.size() - 1), cols[i])
	s.color_ramp = g
	if bool(p.get("grow", false)):
		var cr := Curve.new()
		cr.add_point(Vector2(0, 0.3))
		cr.add_point(Vector2(1, 1.0))
		s.scale_amount_curve = cr
		s.scale_amount_min *= 1.5
		s.scale_amount_max *= 1.5
	elif kind == "dot":
		var cr2 := Curve.new()
		cr2.add_point(Vector2(0, 1.0))
		cr2.add_point(Vector2(1, 0.2))
		s.scale_amount_curve = cr2
	var parent: Node = p.get("parent", self)
	parent.add_child(s)
	if parent == self:
		s.global_position = at
	else:
		s.position = at
	s.emitting = true
	if not bool(p.get("loop", false)):
		get_tree().create_timer(s.lifetime + 0.4).timeout.connect(s.queue_free)
	return s


## Fumée et poussière : des quads doux animés ici (pas de particules en mélange alpha : elles
## donnent des taches noires au tout premier instant de leur vie).
func _puffs(at: Vector3, n: int, col: Color, s0: float, s1: float, life: float, v0: float, v1: float, up: float = 0.5, radius: float = 0.1) -> void:
	for k in range(n):
		var d := Vector3(randf_range(-1, 1), randf_range(-0.2, 1.0) + up, randf_range(-1, 1)).normalized()
		var p: Vector3 = at + Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)) * radius
		var q := _quad(p, Armes.dot(), col, 1.0, true, false)
		var lf: float = life * randf_range(0.75, 1.2)
		_add(q, lf, col, q.get_meta("mat"), s0 * randf_range(0.8, 1.2), s1 * randf_range(0.8, 1.25), "pop", {"vel": d * randf_range(v0, v1)})


## Un émetteur de fumée qui suit un objet (la boule de feu) tant qu'il existe.
func _smoke_trail(node: Node3D, col: Color, every: float) -> void:
	_fx.append({"node": node, "t": 0.0, "life": 1.0e9, "alpha": "emit", "acc": 0.0, "every": every, "col": col})


func _player_pos() -> Vector3:
	if main == null:
		return Vector3.ZERO
	if bool(main.get("xr_active")) and main.get("vr_body") != null and main.vr_body != null:
		return main.vr_body.global_position
	if main.get("pc_body") != null and main.pc_body != null:
		return main.pc_body.global_position
	return main._player_pos_v27() if main.has_method("_player_pos_v27") else Vector3.ZERO


func _vr() -> bool:
	return main != null and bool(main.get("xr_active"))


# =================================================================== le poids des coups

func hitstop(sec: float) -> void:
	if _vr() or not hitstop_enabled or DisplayServer.get_name() == "headless":
		return
	Engine.time_scale = 0.07
	_hs_until = maxi(_hs_until, Time.get_ticks_msec() + int(sec * 1000.0))


func shake(amount: float) -> void:
	if _vr():
		return
	_shake = maxf(_shake, amount)


func haptic(amp: float, dur: float) -> void:
	if not _vr() or main.get("right_hand") == null or main.right_hand == null:
		return
	if main.right_hand.has_method("trigger_haptic_pulse"):
		main.right_hand.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)


func _cam() -> Camera3D:
	var h: Node = main.get("hero_v28") if main != null else null
	if h != null and h.get("camera") != null:
		return h.camera as Camera3D
	return null


# =================================================================== les coups

## Un coup qui porte, en `at`, venu de `from`, avec l'arme `item` (« » : les poings).
func impact(at: Vector3, crit: bool, item: String, from: Vector3 = Vector3.INF) -> void:
	var a: Dictionary = Armes.ame(item)
	var c: Color = a["c"]
	var c2: Color = a["c2"]
	var g: String = str(a["genre"])
	last_genre = g
	_n("impact")
	if crit:
		_n("critique")
	var big: float = 1.6 if crit else 1.0
	var dirv: Vector3 = Vector3.UP
	if from != Vector3.INF:
		dirv = at - from
		dirv.y = maxf(dirv.y, 0.0) + 0.25
		dirv = dirv.normalized() if dirv.length() > 0.01 else Vector3.UP
	var fl := _quad(at, Armes.dot(), c2, 0.5 * big)
	_add(fl, 0.12, c2, fl.get_meta("mat"), 0.6, 1.3)
	var rg := _quad(at, ring_tex(), c, 1.0)
	_add(rg, 0.24, c, rg.get_meta("mat"), 0.15 * big, 1.15 * big)
	if crit:
		var rg2 := _quad(at, ring_tex(), c2, 1.0)
		_add(rg2, 0.34, c2, rg2.get_meta("mat"), 0.3, 2.0)
	_burst(at, {"amount": int(18 * big), "life": 0.34, "v0": 3.5 * big, "v1": 8.0 * big, "dir": dirv, "spread": 75.0,
		"grav": Vector3(0, -9.0, 0), "size": 0.2, "mesh": "streak", "cols": [c2, c, Color(c.r, c.g, c.b, 0.0)], "damping": 2.0})
	_light(at, c, 2.2 * big, 3.2, 0.16)
	match g:
		"forge":
			_burst(at, {"amount": 14, "life": 1.1, "v0": 0.8, "v1": 2.6, "dir": Vector3.UP, "spread": 70.0, "grav": Vector3(0, 1.2, 0),
				"size": 0.05, "cols": [Color(1.0, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(0.6, 0.1, 0.02, 0.0)], "damping": 1.5})
		"foudre":
			_bolts(at, c2, c, 3 if not crit else 5)
			_burst(at, {"amount": 10, "life": 0.25, "v0": 2.0, "v1": 5.0, "size": 0.04, "cols": [Color(1, 1, 1), c, Color(c.r, c.g, c.b, 0)], "grav": Vector3.ZERO})
		"maree":
			_burst(at, {"amount": 18, "life": 0.8, "v0": 1.5, "v1": 4.0, "dir": Vector3.UP, "spread": 55.0, "grav": Vector3(0, -9.0, 0),
				"size": 0.06, "cols": [Color(0.9, 1.0, 1.0, 0.9), c, Color(c.r, c.g, c.b, 0.0)]})
			var sp := _flat(at + Vector3.DOWN * 0.4, Vector3.UP, ring_tex(), c, 1.0)
			_add(sp, 0.45, c, sp.get_meta("mat"), 0.2, 1.8)
		"or":
			_burst(at, {"amount": 12, "life": 0.9, "v0": 0.5, "v1": 2.0, "grav": Vector3(0, -1.0, 0), "size": 0.06,
				"cols": [Color(1, 1, 0.85), c, Color(c.r, c.g, c.b, 0.0)], "damping": 2.0})
		"coeur":
			_burst(at, {"amount": 10, "life": 0.9, "v0": 1.5, "v1": 3.5, "dir": dirv, "spread": 80.0, "grav": Vector3(0, -8.0, 0),
				"size": 0.035, "mesh": "box", "cols": [Color(1.0, 0.5, 0.4), Color(1.0, 0.25, 0.2, 0.0)]})
			var hr := _quad(at, ring_tex(), c2, 1.0)
			_add(hr, 0.5, c2, hr.get_meta("mat"), 0.4, 1.6, "pop")
		"arcane":
			var cc := _quad(at, circle_tex(), c, 0.7)
			_add(cc, 0.45, c, cc.get_meta("mat"), 0.3, 1.0, "pop", {"spin2d": 4.0})
			_burst(at, {"amount": 14, "life": 0.8, "v0": 0.5, "v1": 1.6, "grav": Vector3(0, 0.6, 0), "size": 0.06,
				"cols": [c2, c, Color(c.r, c.g, c.b, 0.0)], "damping": 1.0})
		"bois":
			_burst(at, {"amount": 9, "life": 0.9, "v0": 1.5, "v1": 3.2, "dir": dirv, "spread": 70.0, "grav": Vector3(0, -9.0, 0),
				"size": 0.035, "mesh": "box", "add": false, "cols": [Color(0.62, 0.44, 0.26), Color(0.5, 0.35, 0.2)]})
		"poing":
			_puffs(at, 5, Color(0.85, 0.82, 0.75, 0.3), 0.15, 0.5, 0.6, 0.3, 1.0)
	hitstop(0.085 if crit else 0.045)
	shake(0.07 if crit else 0.03)
	haptic(0.75 if crit else 0.4, 0.12 if crit else 0.06)


## Des éclairs brisés qui partent du point d'impact (orage).
func _bolts(at: Vector3, core: Color, glow: Color, n: int) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)
	mi.global_position = at
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(n):
		var d := Vector3(randf_range(-1, 1), randf_range(-0.4, 1.0), randf_range(-1, 1)).normalized()
		var L: float = randf_range(0.5, 1.1)
		var prev := Vector3.ZERO
		for i in range(1, 7):
			var p: Vector3 = d * L * i / 6.0 + Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), randf_range(-0.08, 0.08))
			for e in [[0.018, core], [0.05, Color(glow.r, glow.g, glow.b, 0.35)]]:
				var w: float = float(e[0]) * (1.0 - i / 8.0)
				for ax in [Vector3.UP, Vector3.RIGHT]:
					var o: Vector3 = (p - prev).cross(ax).normalized() * w
					if o.length() < 1e-5:
						continue
					im.surface_set_color(e[1])
					for v in [prev - o, prev + o, p + o, prev - o, p + o, p - o]:
						im.surface_add_vertex(v)
			prev = p
	im.surface_end()
	_fx.append({"node": mi, "t": 0.0, "life": 0.12, "alpha": "none"})


## Coup chargé : un croissant d'énergie part devant la lame.
func slash_wave(origin: Vector3, facing: Vector3, item: String) -> void:
	var a: Dictionary = Armes.ame(item)
	facing.y = 0.0
	facing = facing.normalized() if facing.length() > 0.01 else Vector3.FORWARD
	_n("croissant")
	for e in [[a["c"], 1.0], [a["c2"], 0.86]]:
		var mi := MeshInstance3D.new()
		mi.mesh = crescent_mesh()
		var m := _mat(e[0], null, false)
		m.vertex_color_use_as_albedo = true
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.global_position = origin + facing * 0.4
		mi.global_basis = Basis.looking_at(facing, Vector3.UP).rotated(facing, randf_range(-0.35, 0.35))
		_add(mi, 0.34, e[0], m, 0.8 * float(e[1]), 1.9 * float(e[1]), "fade", {"vel": facing * 7.5})
	_burst(origin + facing * 0.9, {"amount": 18, "life": 0.4, "v0": 4.0, "v1": 8.0, "dir": facing, "spread": 40.0, "grav": Vector3(0, -4, 0),
		"size": 0.14, "mesh": "streak", "cols": [a["c2"], a["c"], Color(1, 1, 1, 0)], "damping": 3.0})
	shake(0.05)


## Tournoyante : un anneau-comète qui tourne autour du héros.
func whirl(center: Vector3, item: String) -> void:
	var a: Dictionary = Armes.ame(item)
	_n("tourbillon")
	for e in [[a["c"], 1.0, 1.0, -16.0], [a["c2"], 0.8, 1.25, -20.0]]:
		var mi := MeshInstance3D.new()
		mi.mesh = crescent_mesh(true)
		var m := _mat(e[0], null, false)
		m.vertex_color_use_as_albedo = true
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.global_position = center + Vector3.UP * float(e[2])
		_add(mi, 0.42, e[0], m, 1.2 * float(e[1]), 2.2 * float(e[1]), "fade", {"spin": Vector3.UP * float(e[3])})
	var rg := _flat(center + Vector3.UP * 0.05, Vector3.UP, ring_tex(), a["c"], 1.0)
	_add(rg, 0.5, a["c"], rg.get_meta("mat"), 0.5, 5.0)
	_puffs(center + Vector3.UP * 0.25, 12, Color(0.85, 0.82, 0.75, 0.28), 0.25, 0.8, 0.7, 0.5, 1.5, 0.2, 1.2)
	shake(0.06)
	haptic(0.6, 0.15)


# =================================================================== la magie

## Le cercle de runes d'un sort (au sol, et devant les mains).
func cast_circle(col: Color, big: float = 1.0) -> void:
	_n("cercle")
	var pos: Vector3 = _player_pos()
	var g := _flat(pos + Vector3.UP * 0.04, Vector3.UP, circle_tex(), col, 1.0)
	_add(g, 1.1, col, g.get_meta("mat"), 0.3, 1.9 * big, "hold", {"spin_local": 1.2})
	var g2 := _flat(pos + Vector3.UP * 0.05, Vector3.UP, circle_tex(), col.lightened(0.3), 1.0)
	_add(g2, 1.1, col, g2.get_meta("mat"), 0.2, 1.05 * big, "hold", {"spin_local": -2.0})
	var at: Vector3
	var n: Vector3
	var size: float
	if _vr() and main.get("right_hand") != null and main.right_hand != null:
		n = -main.right_hand.global_basis.z
		at = main.right_hand.global_position + n * 0.22
		size = 0.5
	else:
		var h: Node = main.get("hero_v28")
		n = h.facing if h != null else Vector3.FORWARD
		n.y = 0.0
		n = n.normalized() if n.length() > 0.01 else Vector3.FORWARD
		at = pos + Vector3.UP * 1.15 + n * 0.75
		size = 0.95
	var f := _flat(at, n, circle_tex(), col, 1.0)
	_add(f, 0.75, col, f.get_meta("mat"), 0.2 * size, size * big, "hold", {"spin_local": 2.6})
	_light(at, col, 1.8, 4.0, 0.6)
	_burst(pos + Vector3.UP * 0.1, {"amount": 26, "life": 1.2, "v0": 0.4, "v1": 1.4, "radius": 0.8 * big, "dir": Vector3.UP, "spread": 15.0,
		"grav": Vector3(0, 0.6, 0), "size": 0.06, "explo": 0.4, "cols": [col.lightened(0.4), col, Color(col.r, col.g, col.b, 0.0)]})


## Un sort d'Arcanelle vient de partir (sorts_v67.cast).
func on_spell(id: String, col: Color) -> void:
	cast_circle(col)
	var pos: Vector3 = _player_pos()
	match id:
		"soin":
			_spiral(3, col, Color(1.0, 0.95, 0.6), 1.4, 0.8, 2.6, 7.0)
		"levitation":
			_spiral(2, col, Color(1, 1, 1), 1.1, 0.9, -0.2, -9.0)
			var rg := _flat(pos + Vector3.UP * 0.05, Vector3.UP, ring_tex(), col, 1.0)
			_add(rg, 0.6, col, rg.get_meta("mat"), 0.4, 3.5)
		"lumiere":
			var fl := _quad(pos + Vector3.UP * 1.9, Armes.dot(), Color(1.0, 0.95, 0.75), 1.0)
			_add(fl, 0.5, Color(1.0, 0.95, 0.75), fl.get_meta("mat"), 0.3, 2.4)
			_burst(pos + Vector3.UP * 1.9, {"amount": 28, "life": 0.9, "v0": 1.5, "v1": 3.5, "grav": Vector3.ZERO, "size": 0.12, "mesh": "streak",
				"cols": [Color(1, 1, 0.9), col, Color(col.r, col.g, col.b, 0)], "damping": 3.0})


## Un pouvoir des sceaux vient de partir (pouvoirs_v63.use).
func on_power(pid: String) -> void:
	cast_circle(POUVOIRS.get(pid, Color(1, 1, 1)), 0.85)


## Des feux-follets qui montent (ou descendent) en spirale autour du héros.
func _spiral(n: int, col: Color, core: Color, life: float, radius: float, rise: float, speed: float) -> void:
	_n("spirale")
	for k in range(n):
		var w := Node3D.new()
		add_child(w)
		var dot := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.2, 0.2)
		var m := _mat(core, Armes.dot(), true)
		q.material = m
		dot.mesh = q
		w.add_child(dot)
		w.global_position = _player_pos()
		_burst(Vector3.ZERO, {"amount": 26, "life": 0.6, "v0": 0.0, "v1": 0.15, "grav": Vector3(0, 0.3, 0), "size": 0.09, "explo": 0.0,
			"loop": true, "parent": w, "cols": [core, col, Color(col.r, col.g, col.b, 0.0)]})
		_fx.append({"node": w, "t": 0.0, "life": life, "alpha": "spiral", "mat": m, "col": core, "phase": TAU * k / n,
			"radius": radius, "rise": rise, "speed": speed})


## Boule de feu : on l'habille (cœur blanc, flammèches, fumée, braises).
func dress_fireball(ball: Node3D) -> void:
	if ball == null:
		return
	_n("boule")
	_burst(Vector3.ZERO, {"amount": 24, "life": 0.22, "v0": 0.0, "v1": 0.3, "radius": 0.06, "grav": Vector3.ZERO, "size": 0.2, "explo": 0.0,
		"loop": true, "parent": ball, "cols": [Color(1, 1, 0.9), Color(1.0, 0.8, 0.35, 0.8), Color(1.0, 0.5, 0.1, 0.0)]})
	_smoke_trail(ball, Color(0.36, 0.33, 0.31, 0.32), 0.035)
	_burst(Vector3.ZERO, {"amount": 14, "life": 0.6, "v0": 0.5, "v1": 1.6, "radius": 0.12, "grav": Vector3(0, -2.0, 0), "size": 0.08, "mesh": "streak", "explo": 0.0,
		"loop": true, "parent": ball, "cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})


## L'explosion de la boule de feu.
func explosion(at: Vector3) -> void:
	_n("explosion")
	var fl := _quad(at, Armes.dot(), Color(1.0, 0.8, 0.45), 1.0)
	_add(fl, 0.32, Color(1.0, 0.8, 0.45), fl.get_meta("mat"), 0.5, 3.2)
	_burst(at, {"amount": 36, "life": 0.6, "v0": 2.0, "v1": 5.5, "grav": Vector3(0, 1.5, 0), "size": 0.42, "damping": 5.0, "radius": 0.2,
		"cols": [Color(1, 0.95, 0.7), Color(1.0, 0.6, 0.15), Color(0.8, 0.2, 0.04, 0.6), Color(0.3, 0.05, 0.02, 0.0)]})
	_puffs(at + Vector3.UP * 0.2, 12, Color(0.3, 0.27, 0.25, 0.5), 0.5, 1.8, 1.6, 0.4, 1.3, 1.0, 0.35)
	_burst(at, {"amount": 24, "life": 0.7, "v0": 4.0, "v1": 9.0, "grav": Vector3(0, -7.0, 0), "size": 0.16, "mesh": "streak", "damping": 1.0,
		"cols": [Color(1, 0.95, 0.6), Color(1.0, 0.5, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})
	var gy: float = _ground_y(at, at.y - 1.2)
	if at.y - gy < 2.5:
		var rg := _flat(Vector3(at.x, gy + 0.06, at.z), Vector3.UP, ring_tex(), Color(1.0, 0.55, 0.2), 1.0)
		_add(rg, 0.45, Color(1.0, 0.55, 0.2), rg.get_meta("mat"), 0.4, 5.0)
	_light(at, Color(1.0, 0.6, 0.25), 6.0, 9.0, 0.5)
	var d: float = at.distance_to(_player_pos())
	if d < 14.0:
		shake(0.1 * (1.0 - d / 14.0) + 0.02)
		haptic(0.5, 0.12)


func _ground_y(p: Vector3, fallback: float) -> float:
	if not is_inside_tree():
		return fallback
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.5, p + Vector3.DOWN * 4.0, 1)
	var ex: Array = []
	for b in [main.get("pc_body") if main != null else null, main.get("vr_body") if main != null else null]:
		if b != null and is_instance_valid(b) and b.has_method("get_rid"):
			ex.append(b.get_rid())
	q.exclude = ex
	var hit: Dictionary = space.intersect_ray(q)
	return float(hit.position.y) if not hit.is_empty() else fallback


## Le gel : des pics de glace jaillissent du sol devant soi, puis éclatent.
func frost(o: Vector3, dir: Vector3) -> void:
	_n("glace")
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	var mesh: ArrayMesh = ice_mesh()
	for k in range(7):
		var dist: float = 1.3 + k * 0.85
		var off: float = (0.45 if k % 2 == 0 else -0.45) * (0.6 + 0.08 * k)
		var p: Vector3 = o + dir * dist + side * off
		p.y = _ground_y(p, o.y - 1.2)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _ice_mat
		add_child(mi)
		mi.global_position = p
		mi.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(0, TAU), randf_range(-0.2, 0.2))
		var sz: float = randf_range(1.1, 1.6) * (1.0 + k * 0.07)
		mi.scale = Vector3(sz, 0.001, sz)
		_fx.append({"node": mi, "t": -k * 0.045, "life": 1.15, "alpha": "pic", "size": sz})
	for k in range(14):
		var q := _quad(o + dir * 0.8 + Vector3.DOWN * 0.5, Armes.dot(), Color(0.85, 0.95, 1.0, 0.35), 1.0, true, false)
		var v: Vector3 = (dir + side * randf_range(-0.35, 0.35) + Vector3.UP * randf_range(-0.05, 0.15)).normalized() * randf_range(3.0, 6.0)
		_add(q, randf_range(0.8, 1.1), Color(0.85, 0.95, 1.0, 0.35), q.get_meta("mat"), 0.3, 1.4, "pop", {"vel": v})


func _shatter(at: Vector3) -> void:
	_burst(at + Vector3.UP * 0.25, {"amount": 10, "life": 0.9, "v0": 1.2, "v1": 3.0, "dir": Vector3.UP, "spread": 70.0, "grav": Vector3(0, -9.0, 0),
		"size": 0.06, "mesh": "box", "add": false, "cols": [Color(0.8, 0.93, 1.0), Color(0.7, 0.88, 1.0)]})
	_puffs(at + Vector3.UP * 0.3, 3, Color(0.9, 0.96, 1.0, 0.3), 0.2, 0.7, 0.7, 0.2, 0.6)


## Télékinésie : un halo violet suit l'objet qui vole (il disparaît avec lui).
func tk_aura(node: Node3D, col: Color) -> void:
	if node == null or not is_instance_valid(node):
		return
	_n("telekinesie")
	_burst(Vector3.ZERO, {"amount": 24, "life": 0.6, "v0": 0.0, "v1": 0.2, "radius": 0.18, "grav": Vector3(0, 0.4, 0), "size": 0.08, "explo": 0.0,
		"loop": true, "parent": node, "cols": [col.lightened(0.4), col, Color(col.r, col.g, col.b, 0.0)]})
	var c := _flat(node.global_position + Vector3.UP * 0.05, Vector3.UP, circle_tex(), col, 1.0)
	_add(c, 0.8, col, c.get_meta("mat"), 0.2, 1.2, "hold", {"spin_local": 3.0})


# =================================================================== chaque image

func _process(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var real_dt: float = clampf((now - _last_ms) / 1000.0, 0.0, 0.1)
	_last_ms = now
	if _hs_until > 0 and now >= _hs_until:
		Engine.time_scale = 1.0
		_hs_until = 0
	# secousse (temps réel, pour ne pas dépendre de l'arrêt sur image)
	var cam: Camera3D = _cam() if main != null else null
	if _shake > 0.0:
		_shake = maxf(_shake - real_dt * 0.45, 0.0)
		if cam != null:
			cam.h_offset = randf_range(-1.0, 1.0) * _shake
			cam.v_offset = randf_range(-1.0, 1.0) * _shake
			if _shake == 0.0:
				cam.h_offset = 0.0
				cam.v_offset = 0.0
	var dt: float = real_dt if _hs_until > 0 else delta
	for i in range(_fx.size() - 1, -1, -1):
		var e: Dictionary = _fx[i]
		if not is_instance_valid(e["node"]):
			_fx.remove_at(i)
			continue
		var node: Node3D = e["node"]
		e["t"] = float(e["t"]) + dt
		var t: float = float(e["t"])
		var life: float = float(e["life"])
		var k: float = clampf(t / life, 0.0, 1.0)
		var mode: String = str(e.get("alpha", "fade"))
		match mode:
			"light":
				(node as OmniLight3D).light_energy = float(e["light0"]) * pow(1.0 - k, 2.0)
			"pic":
				_tick_pic(e, node, t, life)
			"spiral":
				_tick_spiral(e, node, t, k)
			"none":
				pass
			"emit":
				e["acc"] = float(e["acc"]) + dt
				while float(e["acc"]) >= float(e["every"]):
					e["acc"] = float(e["acc"]) - float(e["every"])
					var c: Color = e["col"]
					var q := _quad(node.global_position + Vector3(randf_range(-0.06, 0.06), randf_range(-0.06, 0.06), randf_range(-0.06, 0.06)), Armes.dot(), c, 1.0, true, false)
					_add(q, randf_range(0.7, 1.0), c, q.get_meta("mat"), 0.15, 0.6, "pop", {"vel": Vector3(randf_range(-0.2, 0.2), randf_range(0.4, 0.9), randf_range(-0.2, 0.2))})
			_:
				var s: float = lerpf(float(e["s0"]), float(e["s1"]), 1.0 - pow(1.0 - k, 3.0))
				node.scale = Vector3.ONE * maxf(s, 0.001)
				var al: float = 1.0 - k
				if mode == "pop":
					al = k / 0.15 if k < 0.15 else 1.0 - (k - 0.15) / 0.85
				elif mode == "hold":
					al = minf(k / 0.12, 1.0) if k < 0.7 else (1.0 - k) / 0.3
				var m: StandardMaterial3D = e.get("mat")
				if m != null:
					var c: Color = e["col"]
					m.albedo_color = Color(c.r, c.g, c.b, c.a * clampf(al, 0.0, 1.0))
				if e.has("vel"):
					node.global_position += (e["vel"] as Vector3) * dt * (1.0 - k * 0.6)
				if e.has("spin"):
					node.rotate(Vector3.UP, (e["spin"] as Vector3).y * dt)
				if e.has("spin_local"):
					node.rotate_object_local(Vector3(0, 0, 1), float(e["spin_local"]) * dt)
		if t >= life and mode != "emit":
			if mode == "pic":
				_shatter(node.global_position)
			node.queue_free()
			_fx.remove_at(i)


func _tick_pic(e: Dictionary, node: Node3D, t: float, life: float) -> void:
	var sz: float = float(e["size"])
	if t < 0.0:
		node.scale = Vector3(sz, 0.001, sz)
		return
	var grow: float = clampf(t / 0.12, 0.0, 1.0)
	var y: float = 1.0 - pow(1.0 - grow, 3.0)
	if t > life - 0.15:
		y *= clampf((life - t) / 0.15, 0.0, 1.0) * 0.4 + 0.6
	node.scale = Vector3(sz, sz * maxf(y, 0.001), sz)


func _tick_spiral(e: Dictionary, node: Node3D, t: float, k: float) -> void:
	var a: float = float(e["phase"]) + t * float(e["speed"])
	var r: float = float(e["radius"]) * (1.0 - 0.45 * k)
	var rise: float = float(e["rise"])
	var y: float = (0.1 + rise * k) if rise >= 0.0 else (1.2 + rise * 6.0 * k)
	node.global_position = _player_pos() + Vector3(cos(a) * r, y, sin(a) * r)
	var m: StandardMaterial3D = e["mat"]
	var c: Color = e["col"]
	m.albedo_color = Color(c.r, c.g, c.b, clampf(minf(k / 0.1, (1.0 - k) / 0.2), 0.0, 1.0))

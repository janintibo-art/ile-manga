extends Node3D
## V93 : le Festival du Larsen, sur la Prairie du Festival de l'Île de Larsen.
##  - La quête « Le Festival du Larsen » (journal_v56, donnée par Jack, après « Le Soleil et la Pluie ») :
##    les cordes de Galet, la toile de Lune, le troisième bouton de Mégaphone… puis le premier concert.
##  - Quand la toile est tendue, elle est au fond de la scène (peinte : le soleil d'un côté, la pluie de
##    l'autre, un arc-en-ciel par-dessus).
##  - Une fois le festival rallumé, chaque soir de 20 h 30 à minuit : les deux villages jouent ensemble
##    (les Gouttières, Arc-en-Ciel et son djembé, Lune au chœur), tout le monde vient danser devant la
##    scène, les projecteurs tournent, la musique « Le Soleil et la Pluie » remplit la prairie, et à
##    23 heures, le feu d'artifice dont Clapotis rêvait.

const TOILE := "res://assets/textures/larsen/toile_scene_v93.png"
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const QUETE := "la_festival"
const DEBUT := 20.5
const ARTIFICE := 23.0
const ARTIFICE_DUREE := 42.0
const W := 22.0
const D := 12.0
const H := 1.6
const TH := 9.5
const COLS := [Color(1.0, 0.25, 0.3), Color(0.3, 0.55, 1.0), Color(0.35, 1.0, 0.45), Color(1.0, 0.82, 0.25), Color(0.9, 0.35, 1.0)]
const ART_COLS := [Color(1.0, 0.3, 0.25), Color(1.0, 0.85, 0.2), Color(0.35, 0.85, 1.0), Color(0.5, 1.0, 0.4), Color(1.0, 0.45, 0.9), Color(1.0, 1.0, 0.95)]

var L: Node3D                             # larsen_v91
var main: Node
var o: Vector3                            # le pied de la scène (au milieu)
var backdrop: MeshInstance3D
var lights: Array = []                    # les projecteurs (SpotLight3D)
var washes: Array = []                    # les bains de lumière (scène, public)
var crowd: Array = []                     # le public venu des yourtes (figurants)
var on: bool = false
var artifice_on: bool = false
var _art_t: float = 0.0
var _art_next: float = 0.0
var _art_day: int = -1
var _pool: Array = []
var _pool_i: int = 0
var _rockets: Array = []                  # [Node3D, t, apex, couleur]
var _t: float = 0.0
var _check: float = 0.0
var _said_day: int = -1
var _rng := RandomNumberGenerator.new()


func setup(larsen: Node3D) -> void:
	L = larsen
	main = larsen.main
	name = "Festival_larsen_v93"
	_rng.seed = 9393


func build() -> void:
	var sc: Vector3 = L._ground(L.scene_xz().x, L.scene_xz().y)
	o = sc
	# --- la toile de Lune, tendue au fond de la scène (devant la toile bleue, derrière les lettres)
	var q := QuadMesh.new()
	q.size = Vector2(W - 1.6, TH - H - 0.3)
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(TOILE):
		m.albedo_texture = load(TOILE)
	else:
		m.albedo_color = Color(0.9, 0.75, 0.45)
	m.roughness = 0.92
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	q.material = m
	backdrop = MeshInstance3D.new()
	backdrop.name = "Toile_de_Lune"
	backdrop.mesh = q
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(backdrop)
	backdrop.global_position = o + Vector3(0, H + (TH - H) * 0.5, -D * 0.5 + 0.735)
	backdrop.visible = false
	# --- les projecteurs : sous le treillis de devant, ils regardent la scène et le public
	for k in range(8):
		var px: float = -W * 0.5 + 2.2 + (k + 1) * (W - 4.4) / 9.0
		var s := SpotLight3D.new()
		s.name = "Projecteur_%d" % k
		s.light_color = COLS[k % COLS.size()]
		s.light_energy = 9.0
		s.spot_range = 26.0
		s.spot_angle = 16.0
		s.spot_attenuation = 0.6
		s.shadow_enabled = false
		s.visible = false
		add_child(s)
		var at: Vector3 = o + Vector3(px, TH - 0.8, D * 0.5 - 0.3)
		var aim: Vector3 = o + Vector3(px * 0.4, H, 1.5) if k % 2 == 0 else o + Vector3(px * 0.7, 0.0, D * 0.5 + 9.0)
		s.global_position = at
		s.look_at(aim, Vector3.UP)
		s.set_meta("base", s.global_transform)
		lights.append(s)
	for k2 in range(2):
		var w := OmniLight3D.new()
		w.light_color = [Color(1.0, 0.8, 0.58), Color(0.7, 0.55, 1.0)][k2]
		w.light_energy = [3.0, 1.5][k2]
		w.omni_range = [14.0, 20.0][k2]
		w.shadow_enabled = false
		w.visible = false
		add_child(w)
		w.global_position = o + (Vector3(0, H + 4.5, 0) if k2 == 0 else Vector3(0, 7.0, D * 0.5 + 10.0))
		washes.append(w)
	# --- la réserve des bouquets du feu d'artifice
	for k3 in range(8):
		var b := CPUParticles3D.new()
		b.name = "Bouquet_%d" % k3
		b.emitting = false
		b.one_shot = true
		b.amount = 240 if L.pc else 110
		b.lifetime = 2.4
		b.explosiveness = 0.96
		b.direction = Vector3.UP
		b.spread = 180.0
		b.initial_velocity_min = 12.0
		b.initial_velocity_max = 17.0
		b.gravity = Vector3(0, -4.5, 0)
		b.damping_min = 2.2
		b.damping_max = 3.2
		b.scale_amount_min = 0.6
		b.scale_amount_max = 1.2
		b.local_coords = false
		var bq := QuadMesh.new()
		bq.size = Vector2(0.95, 0.95)
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bm.vertex_color_use_as_albedo = true
		if main != null and main.has_method("_soft_dot_v24"):
			bm.albedo_texture = main._soft_dot_v24()
		bq.material = bm
		b.mesh = bq
		b.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
		var l := OmniLight3D.new()
		l.omni_range = 70.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		b.add_child(l)
		add_child(b)
		_pool.append(b)


# =================================================================== où en est le festival ?

func _journal() -> Node:
	return main.get("journal_v56") if main != null else null


func _step() -> int:
	var j: Node = _journal()
	if j == null:
		return -1
	var st: String = str(j.state(QUETE))
	if st == "finie":
		return 99
	if st != "en_cours":
		return -1
	return int((j.states.get(QUETE, {}) as Dictionary).get("etape", 0))


## La toile est tendue (Jack a reçu les cordes et la toile).
func toile_tendue() -> bool:
	return _step() >= 3 or bool(L.state.get("festival_toile", false))


## Le festival est rallumé (Mégaphone a appuyé sur son troisième bouton).
func pret() -> bool:
	return _step() >= 4 or bool(L.state.get("festival", false))


func concert_on() -> bool:
	if not pret():
		return false
	var h: float = L.hour()
	return h >= DEBUT and h < 24.0


func _day() -> int:
	var t: Node = main.get("temps_v56") if main != null else null
	return int(t.day_count) if t != null else 1


## Sur la prairie, devant la scène (la fosse et le public).
func in_public(p: Vector3) -> bool:
	var dz: float = p.z - (o.z + D * 0.5)
	return absf(p.x - o.x) < 20.0 and dz > -1.0 and dz < 34.0


func near(p: Vector3) -> bool:
	return Vector2(p.x - o.x, p.z - o.z).length() < 120.0


# =================================================================== la soirée

func _process(delta: float) -> void:
	if L == null or main == null or L.ile == null:
		return
	_t += delta
	var p: Vector3 = main._player_pos_v27()
	var close: bool = near(p)
	_check -= delta
	if _check <= 0.0:
		_check = 0.5
		backdrop.visible = toile_tendue()
		# la toile tendue : les grandes lettres montent en haut, pour laisser voir le soleil et la pluie
		if backdrop.visible and L.scene_labels.size() == 2 and is_instance_valid(L.scene_labels[1]) and (L.scene_labels[1] as Label3D).visible:
			var l0: Label3D = L.scene_labels[0]
			l0.global_position = o + Vector3(0, H + (TH - H) * 0.9, -D * 0.5 + 0.76)
			l0.pixel_size = 0.026
			(L.scene_labels[1] as Label3D).visible = false
		if _step() >= 3:
			L.state["festival_toile"] = true
		if _step() >= 4:
			L.state["festival"] = true
		var now: bool = concert_on()
		if now != on:
			on = now
			if now:
				L.state["concerts"] = int(L.state.get("concerts", 0)) + 1
			if L.ville != null:
				L.ville.festival_switch()
		for w in washes:
			(w as Light3D).visible = on and close
		if on and close and crowd.is_empty():
			_spawn_crowd()
		elif (not on or not close) and not crowd.is_empty():
			_free_crowd()
		if on and in_public(p):
			_public(p)
		if on and L.hour() >= ARTIFICE and _art_day != _day() and not artifice_on:
			_art_day = _day()
			if close:
				_start_artifice()
	# les projecteurs tournent et changent de couleur, en rythme (112 à la noire)
	var lit: bool = on and close
	for i in range(lights.size()):
		var s: SpotLight3D = lights[i]
		s.visible = lit
		if not lit:
			continue
		var beat: float = fmod(_t * 112.0 / 60.0 + i * 0.25, 1.0)
		s.light_color = COLS[(int(_t * 0.5) + i) % COLS.size()]
		s.light_energy = 9.0 * (0.6 + 0.7 * (1.0 - beat))
		var b: Transform3D = s.get_meta("base")
		s.global_transform = Transform3D(b.basis * Basis(Vector3.UP, sin(_t * 0.8 + i) * 0.4) * Basis(Vector3.RIGHT, sin(_t * 1.2 + i * 2.0) * 0.22), b.origin)
	if artifice_on:
		_artifice_tick(delta, p)


## Le joueur est dans le public pendant le concert.
func _public(_p: Vector3) -> void:
	if not bool(L.state.get("festival_vu", false)):
		L.state["festival_vu"] = true
		L.say("LE FESTIVAL DU LARSEN ! Sur la Grande Scène, les Gouttières et les tambours du Camp des Fleurs jouent ensemble. Au premier rang, Mamie Tournesol et Mère Averse se tiennent par la main et chantent faux, très fort.", 10.0)
		if main.has_method("jingle"):
			main.jingle("decouverte")
	elif _said_day != _day():
		_said_day = _day()
		var lines := [
			"Ce soir à la Grande Scène : « Le Soleil et la Pluie » ! Flanelle chante, Grésil fait siffler sa guitare, et Arc-en-Ciel répond à la batterie de Bourrasque.",
			"La prairie est pleine : des fleurs dans les cheveux, des chemises à carreaux, des parapluies troués. Tout le monde danse.",
			"Mégaphone pousse les boutons de la régie. Le rouge, le bleu… et celui du milieu, tout à fond.",
		]
		L.say(lines[_day() % lines.size()], 8.0)


func _spawn_crowd() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 93000 + _day()
	var n: int = 24 if L.pc else 12
	var front: float = o.z + D * 0.5
	for i in range(n):
		var style: String = "yourte_fleurs" if i % 2 == 0 else "yourte_rainville"
		var role: String = ["homme", "femme", "femme", "homme", "fille", "garcon", "vieille", "femme"][i % 8]
		var prof: Dictionary = Gens.pick(style, role, rng)
		prof["nom"] = Gens.prenom(style, role, rng)
		# (en rangs un peu désordonnés ; les places des habitants, au milieu des premiers rangs, restent libres)
		var x: float = rng.randf_range(-12.0, 12.0)
		var z: float = front + rng.randf_range(4.0, 19.0)
		if absf(x) < 6.5 and z < front + 9.5:
			x = (6.8 + rng.randf_range(0.0, 4.0)) * signf(x + 0.01)
		var at := Vector3(o.x + x, 0.0, z)
		at.y = L.ile.height(at.x, at.z)
		var face: Vector3 = (Vector3(o.x, at.y, o.z) - at).normalized()
		var pose: String = ["danse", "applaudir", "danse", "danse"][i % 4]
		var f: Node = Figurant.spawn(self, main, prof, at, face, pose)
		if f != null:
			crowd.append(f)


func _free_crowd() -> void:
	for f in crowd:
		if is_instance_valid(f):
			(f as Node).queue_free()
	crowd.clear()


# =================================================================== le feu d'artifice (23 h)

func _start_artifice() -> void:
	artifice_on = true
	_art_t = 0.0
	_art_next = 0.5
	L.say("Il est 23 heures… Les projecteurs s'éteignent un instant. Sur le côté de la scène, Clapotis tient la main de Bouton-d'Or, et il ne quitte pas le ciel des yeux. FFFIIIIIIUUU… BOUM !", 9.0)


func _artifice_tick(delta: float, p: Vector3) -> void:
	_art_t += delta
	_art_next -= delta
	if _art_t < ARTIFICE_DUREE and _art_next <= 0.0:
		_art_next = _rng.randf_range(0.5, 1.3) if _art_t < ARTIFICE_DUREE - 8.0 else _rng.randf_range(0.15, 0.35)   # le bouquet final
		_launch()
	# les fusées montent, laissant une traînée ; arrivées en haut, elles éclatent
	for r in _rockets.duplicate():
		var node: Node3D = r[0]
		r[1] = float(r[1]) + delta
		var t: float = float(r[1])
		node.global_position = (r[4] as Vector3) + Vector3(0, 30.0 * t - 3.0 * t * t, 0) + (r[5] as Vector3) * t
		if t >= float(r[2]):
			_burst(node.global_position, r[3])
			_rockets.erase(r)
			node.queue_free()
	for b in _pool:
		var l: OmniLight3D = (b as Node).get_child(0)
		l.light_energy = maxf(l.light_energy - delta * 3.5, 0.0)
	if _art_t >= ARTIFICE_DUREE + 4.0 and _rockets.is_empty():
		artifice_on = false
		if near(p):
			if not bool(L.state.get("artifice", false)):
				L.state["artifice"] = true
				L.say("Le dernier bouquet retombe en pluie d'or. Toute la prairie applaudit. Clapotis crie : « J'EN AI VU ! DES VRAIS ! » Et Bouton-d'Or lui pose une couronne de marguerites sur la tête.", 10.0)
				if main.has_method("jingle"):
					main.jingle("decouverte")


func _launch() -> void:
	var r := Node3D.new()
	r.name = "Fusee"
	var tr := CPUParticles3D.new()
	tr.amount = 40
	tr.lifetime = 0.6
	tr.local_coords = false
	tr.direction = Vector3.DOWN
	tr.spread = 12.0
	tr.initial_velocity_min = 1.0
	tr.initial_velocity_max = 2.5
	tr.gravity = Vector3(0, -2.0, 0)
	tr.scale_amount_min = 0.5
	tr.scale_amount_max = 0.9
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.22)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.75, 0.35)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	tr.mesh = q
	r.add_child(tr)
	add_child(r)
	var start: Vector3 = o + Vector3(_rng.randf_range(-16.0, 16.0), 0.5, _rng.randf_range(-18.0, -10.0))
	start.y = L.ile.height(start.x, start.z) + 0.5
	r.global_position = start
	var apex: float = _rng.randf_range(2.6, 3.6)
	var drift := Vector3(_rng.randf_range(-2.0, 2.0), 0, _rng.randf_range(-1.0, 2.0))
	_rockets.append([r, 0.0, apex, ART_COLS[_rng.randi() % ART_COLS.size()], start, drift])
	main.sfx("artifice_sifflet", null, _db(start) - 4.0)


func _burst(at: Vector3, c: Color) -> void:
	var b: CPUParticles3D = _pool[_pool_i % _pool.size()]
	_pool_i += 1
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.add_point(0.12, c)
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	b.color_ramp = grad
	b.global_position = at
	var l: OmniLight3D = b.get_child(0)
	l.light_color = c
	l.light_energy = 7.0
	b.restart()
	b.emitting = true
	main.sfx("artifice_boum" if _rng.randf() < 0.6 else "artifice_eclat", null, _db(at))


## Le volume d'un éclatement selon la distance (le son du ciel s'entend de loin, mais pas de partout).
func _db(at: Vector3) -> float:
	var d: float = main._player_pos_v27().distance_to(at)
	return clampf(-d / 12.0, -30.0, 0.0)

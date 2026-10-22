extends Node3D
## V63 : les pouvoirs des quatre sceaux (progression_v63.gd choisit le pouvoir, on le lance ici).
##  - Bourrasque (Sceau des Embruns) : un vent du large en éventail devant soi ; il repousse les
##    ennemis, renverse les carapaces, fait tourner les ailes de moulin et les éoliennes.
##  - Flamme (Sceau des Sables) : une boule de feu qui vole droit (un peu guidée vers une cible
##    proche) ; elle brûle les ennemis et les ronces, allume les braseros et les torches.
##  - Rouage (Sceau d'Airain) : une volée d'engrenages d'or ; les vieux mécanismes repartent de
##    loin, les automates et les armures se figent un moment.
##  - Lueur de lune (Sceau des Brumes) : une lumière de lune autour de soi, douze secondes ; elle
##    révèle les ponts, les dalles et les écritures cachés, et rend les spectres vulnérables.
## Les objets du monde qui réagissent aux pouvoirs s'inscrivent avec register() :
##   {id, power, pos (Vector3 ou Callable -> Vector3), radius, call (Callable), when (Callable)}
## Pour la Lueur, « call » reçoit true quand la lumière les touche, false quand elle s'en va ;
## une cible sans position (« partout ») est appelée à chaque Lueur, où que l'on soit.

const COOLDOWN := {"vent": 2.5, "flamme": 1.2, "rouage": 3.0, "lune": 16.0}
const MECHA := ["automate", "armure", "golem", "colosse", "gardien"]
const LUNE_TIME: float = 12.0

var main: Node
var targets: Array = []
var lune_t: float = 0.0
var lune_lit: Dictionary = {}           # id -> true (cibles éclairées par la Lueur)
var casts: Dictionary = {}              # pouvoir -> nombre de lancers (pour les tests)
var last_hits: Array = []               # ids des cibles touchées au dernier lancer (tests)
var last_explode: Vector3 = Vector3.INF  # où la dernière boule de feu a éclaté (tests)
var _cd: Dictionary = {}
var _cd_max: Dictionary = {}
var _uses: int = 0
var _balls: Array = []
var _gears: Array = []
var _lune_fx: Node3D
var _lune_light: OmniLight3D
var _lune_on: bool = false


func setup(main_node: Node) -> void:
	main = main_node


func register(t: Dictionary) -> void:
	unregister(str(t.get("id", "")))
	targets.append(t)


func unregister(id: String) -> void:
	for i in range(targets.size() - 1, -1, -1):
		if str(targets[i].get("id", "")) == id:
			targets.remove_at(i)


func unregister_prefix(prefix: String) -> void:
	for i in range(targets.size() - 1, -1, -1):
		if str(targets[i].get("id", "")).begins_with(prefix):
			targets.remove_at(i)


func cooldown_ratio(pid: String) -> float:
	var m: float = float(_cd_max.get(pid, 0.0))
	if m <= 0.0:
		return 1.0
	return clampf(1.0 - float(_cd.get(pid, 0.0)) / m, 0.0, 1.0)


func lune_active() -> bool:
	return lune_t > 0.0


func _talent(id: String) -> bool:
	var pr: Node = main.get("progression_v63")
	return pr != null and pr.has_talent(id)


## La poitrine du joueur (PC : le héros ; VR : sous la tête).
func origin() -> Vector3:
	if main.xr_active:
		return main.vr_body.global_position + Vector3.UP * 1.2
	return main.pc_body.global_position + Vector3.UP * 1.2


## Où l'on vise : PC, devant le héros ; VR, là où pointe la main droite.
func aim_dir(flat: bool = true) -> Vector3:
	var d: Vector3
	if main.xr_active:
		d = -main.right_hand.global_basis.z
	else:
		d = main.hero_v28.facing if main.hero_v28 != null else Vector3.FORWARD
	if flat:
		d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


func _tpos(t: Dictionary) -> Vector3:
	var p: Variant = t.get("pos", null)
	if p is Callable:
		return (p as Callable).call()
	if p is Vector3:
		return p
	return Vector3.INF


func _alive(t: Dictionary) -> bool:
	if t.has("when") and not bool((t["when"] as Callable).call()):
		return false
	return true


## Lance un pouvoir (renvoie false s'il se recharge encore, ou si l'on ne peut pas).
func use(pid: String) -> bool:
	if main == null or not bool(main.game_started):
		return false
	if float(_cd.get(pid, 0.0)) > 0.0:
		main.sfx("ui_erreur")
		return false
	var hero: Node = main.get("hero_v28")
	if hero != null and not main.xr_active and not (str(hero.state) in ["sol", "air", "charge"]):
		return false
	if hero != null and str(hero.state) == "nage":
		return false
	var k: float = 0.7 if _talent("sceaux_apaises") else 1.0
	_cd[pid] = float(COOLDOWN[pid]) * k
	_cd_max[pid] = float(COOLDOWN[pid]) * k
	casts[pid] = int(casts.get(pid, 0)) + 1
	last_hits = []
	if hero != null and not main.xr_active and str(hero.state) == "sol" and pid != "lune":
		hero.play_action("push", origin() + aim_dir() * 3.0)
		hero.action_length = 0.42
	match pid:
		"vent":
			_vent()
		"flamme":
			_flamme()
		"rouage":
			_rouage()
		"lune":
			_lune()
	if _talent("coeur_sceaux") and hero != null:
		_uses += 1
		hero.stamina = minf(float(hero.stamina) + 2.5, float(hero.STAMINA_MAX))
		if _uses % 4 == 0:
			hero.heal(1)
	return true


func _in_cone(from: Vector3, dir: Vector3, p: Vector3, reach: float, half_deg: float, dy_max: float = 4.0) -> bool:
	var off: Vector3 = p - from
	var dy: float = off.y
	off.y = 0.0
	var d: float = off.length()
	if d > reach or absf(dy) > dy_max:
		return false
	if d < 0.8:
		return true
	return rad_to_deg(dir.angle_to(off / d)) <= half_deg


func _monsters() -> Array:
	var out: Array = []
	for m in get_tree().get_nodes_in_group("monstres_v36"):
		if is_instance_valid(m) and str(m.get("state")) != "mort":
			out.append(m)
	return out


# =================================================================== Bourrasque

func _vent() -> void:
	var o: Vector3 = origin()
	var dir: Vector3 = aim_dir()
	var echo: bool = _talent("echo_sceaux")
	var reach: float = 12.0 if echo else 9.0
	var half: float = 55.0 if echo else 40.0
	main.sfx("bourrasque", o)
	_gust_fx(o, dir, reach)
	for m in _monsters():
		var n3: Node3D = m
		if not _in_cone(o, dir, n3.global_position + Vector3.UP * 0.6, reach, half):
			continue
		var away: Vector3 = n3.global_position - o
		away.y = 0.0
		away = away.normalized() if away.length() > 0.01 else dir
		if m.has_method("on_power"):
			m.on_power("vent", o)
		if m.has_method("take_hit"):
			m.take_hit(1, o)
		if m.get("_knock") != null and str(m.get("kind")) != "gardien_coeur":
			m.set("_knock", away * (11.0 if not (str(m.get("kind")) in ["golem", "colosse"]) else 3.0))
	for t in targets.duplicate():
		if str(t.get("power", "")) != "vent" or not _alive(t):
			continue
		var p: Vector3 = _tpos(t)
		if p != Vector3.INF and _in_cone(o, dir, p, reach + float(t.get("radius", 1.0)), half, 8.0):
			last_hits.append(str(t["id"]))
			(t["call"] as Callable).call()


func _gust_fx(o: Vector3, dir: Vector3, reach: float) -> void:
	var fx := CPUParticles3D.new()
	fx.name = "Bourrasque_v63"
	fx.amount = 90
	fx.lifetime = 0.75
	fx.one_shot = true
	fx.explosiveness = 0.75
	fx.local_coords = false
	fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fx.emission_sphere_radius = 0.4
	fx.direction = Vector3(0, 0, -1)
	fx.spread = 28.0
	fx.gravity = Vector3.ZERO
	fx.initial_velocity_min = reach * 1.1
	fx.initial_velocity_max = reach * 1.7
	fx.damping_min = 4.0
	fx.damping_max = 7.0
	fx.particle_flag_align_y = true
	fx.scale_amount_min = 0.6
	fx.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.85, 0.97, 1.0, 0.55)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	fx.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	fx.color_ramp = grad
	add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), o)
	fx.emitting = true
	# des feuilles et de la poussière emportées
	var dust := CPUParticles3D.new()
	dust.amount = 30
	dust.lifetime = 1.0
	dust.one_shot = true
	dust.explosiveness = 0.8
	dust.local_coords = false
	dust.direction = Vector3(0, 0.15, -1)
	dust.spread = 32.0
	dust.gravity = Vector3(0, -2.0, 0)
	dust.initial_velocity_min = reach * 0.6
	dust.initial_velocity_max = reach * 1.0
	dust.damping_min = 3.0
	dust.damping_max = 5.0
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.07, 0.07)
	var m2 := StandardMaterial3D.new()
	m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m2.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.albedo_color = Color(0.75, 0.72, 0.6, 0.7)
	q2.material = m2
	dust.mesh = q2
	add_child(dust)
	dust.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), o + Vector3.DOWN * 0.9)
	dust.emitting = true
	get_tree().create_timer(1.6).timeout.connect(func(): fx.queue_free(); dust.queue_free())


# =================================================================== Flamme

func _flamme() -> void:
	var o: Vector3 = origin() + aim_dir() * 0.6
	var dir: Vector3 = aim_dir(main.xr_active)
	# un peu guidée : vers l'ennemi ou la cible la plus proche dans un cône étroit
	var best_d: float = 22.0
	var aim: Vector3 = Vector3.INF
	for m in _monsters():
		var c: Vector3 = (m as Node3D).global_position + Vector3.UP * float(m.get("hit_height"))
		var off: Vector3 = c - o
		if off.length() < best_d and rad_to_deg(dir.angle_to(off.normalized())) < 22.0:
			best_d = off.length()
			aim = c
	for t in targets:
		if str(t.get("power", "")) != "flamme" or not _alive(t):
			continue
		var p: Vector3 = _tpos(t)
		if p == Vector3.INF:
			continue
		var off2: Vector3 = p - o
		if off2.length() < best_d and rad_to_deg(dir.angle_to(off2.normalized())) < 24.0:
			best_d = off2.length()
			aim = p
	if aim != Vector3.INF:
		dir = (aim - o).normalized()
	var ball := Node3D.new()
	ball.name = "Flamme_v63"
	add_child(ball)
	ball.global_position = o
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.34
	core.mesh = sm
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(1.0, 0.8, 0.4)
	cm.emission_enabled = true
	cm.emission = Color(1.0, 0.55, 0.15)
	cm.emission_energy_multiplier = 4.0
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 2.2
	light.omni_range = 6.0
	ball.add_child(light)
	var trail := CPUParticles3D.new()
	trail.amount = 50
	trail.lifetime = 0.45
	trail.local_coords = false
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.12
	trail.gravity = Vector3(0, 2.5, 0)
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.scale_amount_min = 0.6
	trail.scale_amount_max = 1.5
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.22)
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tm.vertex_color_use_as_albedo = true
	if main.has_method("_soft_dot_v24"):
		tm.albedo_texture = main._soft_dot_v24()
	q.material = tm
	trail.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.add_point(0.4, Color(1.0, 0.4, 0.08, 0.8))
	grad.set_color(grad.get_point_count() - 1, Color(0.25, 0.08, 0.04, 0.0))
	trail.color_ramp = grad
	ball.add_child(trail)
	_balls.append({"node": ball, "dir": dir, "speed": 17.0, "left": 24.0, "dmg": 6 if _talent("echo_sceaux") else 4})
	main.sfx("flamme_lance", o)


func _tick_balls(delta: float) -> void:
	for i in range(_balls.size() - 1, -1, -1):
		var b: Dictionary = _balls[i]
		var node: Node3D = b["node"]
		if not is_instance_valid(node):
			_balls.remove_at(i)
			continue
		var from: Vector3 = node.global_position
		var step: float = float(b["speed"]) * delta
		var to: Vector3 = from + (b["dir"] as Vector3) * step
		b["left"] = float(b["left"]) - step
		var hit_at: Vector3 = Vector3.INF
		# les monstres
		for m in _monsters():
			var c: Vector3 = (m as Node3D).global_position + Vector3.UP * maxf(float(m.get("hit_height")), 0.4)
			if Geometry3D.get_closest_point_to_segment(c, from, to).distance_to(c) < 0.45 + float(m.get("hit_radius")):
				if m.has_method("on_power"):
					m.on_power("flamme", from)
				var cb: Node = main.combat_v28
				if cb != null:
					cb.critical = true
				m.take_hit(int(b["dmg"]), from)
				if cb != null:
					cb.critical = false
				hit_at = c
				break
		# les cibles (braseros, torches, ronces…)
		if hit_at == Vector3.INF:
			for t in targets.duplicate():
				if str(t.get("power", "")) != "flamme" or not _alive(t):
					continue
				var p: Vector3 = _tpos(t)
				if p == Vector3.INF:
					continue
				if Geometry3D.get_closest_point_to_segment(p, from, to).distance_to(p) < float(t.get("radius", 0.8)):
					last_hits.append(str(t["id"]))
					(t["call"] as Callable).call()
					hit_at = p
					break
		# les murs et le sol
		if hit_at == Vector3.INF:
			var q := PhysicsRayQueryParameters3D.create(from, to, 1)
			var ex: Array = []
			if main.pc_body != null:
				ex.append(main.pc_body.get_rid())
			if main.vr_body != null:
				ex.append(main.vr_body.get_rid())
			q.exclude = ex
			var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty():
				hit_at = hit.position
		if hit_at != Vector3.INF or float(b["left"]) <= 0.0:
			_explode(hit_at if hit_at != Vector3.INF else to)
			node.queue_free()
			_balls.remove_at(i)
			continue
		node.global_position = to


func _explode(at: Vector3) -> void:
	last_explode = at
	main.sfx("flamme_impact", at)
	if main.combat_v28 != null:
		main.combat_v28.puff(at, Color(1.0, 0.55, 0.2))
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.6, 0.25)
	flash.light_energy = 4.0
	flash.omni_range = 7.0
	add_child(flash)
	flash.global_position = at
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.5)
	tw.tween_callback(flash.queue_free)
	var sp := CPUParticles3D.new()
	sp.amount = 36
	sp.lifetime = 0.6
	sp.one_shot = true
	sp.explosiveness = 0.9
	sp.local_coords = false
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.2
	sp.spread = 180.0
	sp.gravity = Vector3(0, 1.5, 0)
	sp.initial_velocity_min = 1.5
	sp.initial_velocity_max = 4.0
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.55, 0.15, 0.9)
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	sp.mesh = q
	add_child(sp)
	sp.global_position = at
	sp.emitting = true
	get_tree().create_timer(1.0).timeout.connect(sp.queue_free)


# =================================================================== Rouage

func _rouage() -> void:
	var o: Vector3 = origin()
	var dir: Vector3 = aim_dir()
	var echo: bool = _talent("echo_sceaux")
	var reach: float = 15.0
	var half: float = 45.0 if echo else 32.0
	main.sfx("rouage", o)
	for k in range(3):
		_gear_fx(o + Vector3(0, -0.2 + k * 0.2, 0), dir.rotated(Vector3.UP, (k - 1) * 0.18), reach, k)
	for m in _monsters():
		var n3: Node3D = m
		if not _in_cone(o, dir, n3.global_position + Vector3.UP * 0.8, reach, half):
			continue
		if m.has_method("on_power"):
			m.on_power("rouage", o)
		if str(m.get("kind")) in MECHA:
			var t: float = 5.0 if echo else 3.2
			if m.has_method("stun"):
				m.stun(t)
			else:
				m.set("state", "recul")
				m.set("timer", t)
			if main.combat_v28 != null:
				main.combat_v28.float_text(n3.global_position + Vector3.UP * 2.3, "Figé !", Color(1.0, 0.85, 0.4))
	for t2 in targets.duplicate():
		if str(t2.get("power", "")) != "rouage" or not _alive(t2):
			continue
		var p: Vector3 = _tpos(t2)
		if p != Vector3.INF and _in_cone(o, dir, p, reach + float(t2.get("radius", 1.0)), half + 8.0, 8.0):
			last_hits.append(str(t2["id"]))
			(t2["call"] as Callable).call()


static var _gear_mesh: ArrayMesh


## Un engrenage plat (moyeu, couronne dentée) : un seul maillage partagé.
static func gear_mesh() -> ArrayMesh:
	if _gear_mesh != null:
		return _gear_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var teeth: int = 12
	var r_in: float = 0.1
	var r_mid: float = 0.24
	var r_out: float = 0.3
	var h: float = 0.05
	var seg: int = teeth * 4
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var tooth: bool = (i % 4) < 2
		var ro: float = r_out if tooth else r_mid
		for side in [-1.0, 1.0]:
			var y: float = side * h * 0.5
			var n: Vector3 = Vector3(0, side, 0)
			var p0 := Vector3(cos(a0) * r_in, y, sin(a0) * r_in)
			var p1 := Vector3(cos(a1) * r_in, y, sin(a1) * r_in)
			var p2 := Vector3(cos(a1) * ro, y, sin(a1) * ro)
			var p3 := Vector3(cos(a0) * ro, y, sin(a0) * ro)
			for v in ([p0, p1, p2, p0, p2, p3] if side > 0.0 else [p0, p2, p1, p0, p3, p2]):
				st.set_normal(n)
				st.add_vertex(v)
		# le bord extérieur
		var o0 := Vector3(cos(a0) * ro, -h * 0.5, sin(a0) * ro)
		var o1 := Vector3(cos(a1) * ro, -h * 0.5, sin(a1) * ro)
		var n2 := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		for v2 in [o0, o1 + Vector3.UP * h, o1, o0, o0 + Vector3.UP * h, o1 + Vector3.UP * h]:
			st.set_normal(n2)
			st.add_vertex(v2)
	_gear_mesh = st.commit()
	return _gear_mesh


func _gear_fx(o: Vector3, dir: Vector3, reach: float, k: int) -> void:
	var g := MeshInstance3D.new()
	g.mesh = gear_mesh()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.8, 0.35, 0.95)
	m.metallic = 0.9
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = Color(1.0, 0.72, 0.25)
	m.emission_energy_multiplier = 2.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	g.material_override = m
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	g.global_position = o
	g.global_basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3.ONE * (1.4 - k * 0.3))
	_gears.append({"node": g, "dir": dir, "t": 0.0, "dur": 0.55 + k * 0.08, "reach": reach, "from": o, "mat": m})


func _tick_gears(delta: float) -> void:
	for i in range(_gears.size() - 1, -1, -1):
		var g: Dictionary = _gears[i]
		var node: MeshInstance3D = g["node"]
		g["t"] = float(g["t"]) + delta
		var u: float = float(g["t"]) / float(g["dur"])
		if u >= 1.0 or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			_gears.remove_at(i)
			continue
		node.global_position = (g["from"] as Vector3) + (g["dir"] as Vector3) * float(g["reach"]) * (1.0 - pow(1.0 - u, 2.0))
		node.rotate_object_local(Vector3.UP, delta * 14.0)
		(g["mat"] as StandardMaterial3D).albedo_color.a = 0.95 * (1.0 - u * u)


# =================================================================== Lueur de lune

func _lune() -> void:
	lune_t = LUNE_TIME * (1.5 if _talent("echo_sceaux") else 1.0)
	main.sfx("lueur", origin())
	if _lune_fx == null:
		_lune_fx = Node3D.new()
		_lune_fx.name = "Lueur_de_lune_v63"
		add_child(_lune_fx)
		_lune_light = OmniLight3D.new()
		_lune_light.light_color = Color(0.72, 0.82, 1.0)
		_lune_light.omni_range = 12.0
		_lune_light.shadow_enabled = false
		_lune_fx.add_child(_lune_light)
		var motes := CPUParticles3D.new()
		motes.name = "Poussiere"
		motes.amount = 60
		motes.lifetime = 2.2
		motes.local_coords = false
		motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		motes.emission_sphere_radius = 2.2
		motes.gravity = Vector3(0, 0.25, 0)
		motes.initial_velocity_min = 0.05
		motes.initial_velocity_max = 0.25
		motes.scale_amount_min = 0.4
		motes.scale_amount_max = 1.2
		var q := QuadMesh.new()
		q.size = Vector2(0.06, 0.06)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.8, 0.88, 1.0, 0.9)
		if main.has_method("_soft_dot_v24"):
			m.albedo_texture = main._soft_dot_v24()
		q.material = m
		motes.mesh = q
		_lune_fx.add_child(motes)
		var halo := MeshInstance3D.new()
		halo.name = "Halo"
		var hm := SphereMesh.new()
		hm.radius = 1.2
		hm.height = 2.4
		halo.mesh = hm
		var hmat := StandardMaterial3D.new()
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hmat.cull_mode = BaseMaterial3D.CULL_FRONT
		hmat.albedo_color = Color(0.45, 0.55, 0.85, 0.08)
		halo.material_override = hmat
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_lune_fx.add_child(halo)
	_lune_fx.visible = true
	(_lune_fx.get_node("Poussiere") as CPUParticles3D).emitting = true
	# les cibles « partout » (le journal de bord…)
	for t in targets.duplicate():
		if str(t.get("power", "")) == "lune" and _alive(t) and t.get("pos", null) == null:
			last_hits.append(str(t["id"]))
			(t["call"] as Callable).call(true)
	_tick_lune(0.0)


func _tick_lune(delta: float) -> void:
	if lune_t <= 0.0 and lune_lit.is_empty() and not _lune_on:
		return
	lune_t = maxf(lune_t - delta, 0.0)
	_lune_on = lune_t > 0.0
	var o: Vector3 = origin()
	if _lune_fx != null:
		_lune_fx.global_position = o
		var k: float = clampf(lune_t / 1.5, 0.0, 1.0)
		_lune_light.light_energy = 1.8 * k
		_lune_fx.get_node("Halo").visible = lune_t > 0.0
		if lune_t <= 0.0:
			(_lune_fx.get_node("Poussiere") as CPUParticles3D).emitting = false
	for t in targets.duplicate():
		if str(t.get("power", "")) != "lune" or t.get("pos", null) == null:
			continue
		var id: String = str(t["id"])
		var p: Vector3 = _tpos(t)
		var inside: bool = lune_t > 0.0 and p != Vector3.INF and _alive(t) and p.distance_to(o) < 14.0 + float(t.get("radius", 0.0))
		if inside and not lune_lit.has(id):
			lune_lit[id] = true
			last_hits.append(id)
			(t["call"] as Callable).call(true)
		elif not inside and lune_lit.has(id):
			lune_lit.erase(id)
			(t["call"] as Callable).call(false)
	# les spectres dans la lumière deviennent vulnérables
	for m in _monsters():
		if m.has_method("set_moonlit"):
			m.set_moonlit(lune_t > 0.0 and (m as Node3D).global_position.distance_to(o) < 11.0)


func _process(delta: float) -> void:
	if main == null:
		return
	for k in _cd:
		_cd[k] = maxf(float(_cd[k]) - delta, 0.0)
	_tick_balls(delta)
	_tick_gears(delta)
	_tick_lune(delta)


## Chargement d'une partie : plus de boule de feu en vol, plus de Lueur.
func reset() -> void:
	for b in _balls:
		if is_instance_valid(b["node"]):
			(b["node"] as Node).queue_free()
	_balls.clear()
	lune_t = 0.0
	_cd.clear()
	_cd_max.clear()
	_tick_lune(0.0)

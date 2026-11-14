extends Node3D
## V142 : une limace du potager des géants. À leur échelle, elle est aussi longue que nous sommes
## grands : un corps mou et luisant, son manteau, deux grandes cornes à yeux et deux petites. Elle
## rampe d'un chou à l'autre et le grignote (la tête qui va et vient), en laissant une traînée de
## bave brillante. Un bon coup : elle se recroqueville, fait « splotch », et file se cacher sous la
## clôture (elle disparaît). Elle ne fait de mal à personne.

signal chassee(limace: Node3D)

var main: Node
var ile: Node3D                           # le relief (ile_geants_v142)
var hit_radius: float = 0.8
var hit_height: float = 0.4
var cible := Vector3.ZERO                 # le chou qu'elle va grignoter
var sortie := Vector3.ZERO                # par où elle s'enfuit (la clôture)
var etat: String = "rampe"                # rampe, mange, fuit, partie
var _t: float = 0.0
var _body: MeshInstance3D
var _cornes: Array = []
var _shrink: float = 0.0
var _trail_t: float = 0.0
var _trail: Array = []
var _rng := RandomNumberGenerator.new()
static var _mats: Dictionary = {}


func setup(main_node: Node, relief: Node3D, at: Vector3, chou: Vector3, exit: Vector3, seed_value: int) -> void:
	main = main_node
	ile = relief
	cible = chou
	sortie = exit
	_rng.seed = seed_value
	name = "Limace_v142_%d" % seed_value
	_build()
	global_position = at
	_sol()
	add_to_group("cibles_v28")


static func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"peau":
			m.albedo_color = Color(0.36, 0.26, 0.16)
			m.roughness = 0.12
			m.metallic_specular = 0.9
			m.rim_enabled = true
			m.rim = 0.4
		"manteau":
			m.albedo_color = Color(0.28, 0.2, 0.12)
			m.roughness = 0.18
			m.metallic_specular = 0.8
		"oeil":
			m.albedo_color = Color(0.08, 0.06, 0.05)
			m.roughness = 0.1
		"bave":
			m.albedo_color = Color(0.85, 0.9, 0.95, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.02
			m.metallic_specular = 1.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mats[key] = m
	return m


func _build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# le corps : un long fuseau aplati (le long de +z), plus large sous le manteau
	var nu: int = 16
	var nv: int = 14
	var L: float = 1.9
	var grid: Array = []
	for j in range(nv + 1):
		var t: float = float(j) / nv
		var z: float = (t - 0.5) * L
		var w: float = 0.32 * pow(sin(PI * clampf(t * 0.98 + 0.01, 0.0, 1.0)), 0.6) * (1.0 + 0.25 * exp(-pow((t - 0.62) / 0.16, 2.0)))
		var h: float = 0.3 * pow(sin(PI * clampf(t, 0.02, 0.98)), 0.7) * (1.0 + 0.4 * exp(-pow((t - 0.62) / 0.15, 2.0)))
		var row: Array = []
		for i in range(nu + 1):
			var a: float = PI * float(i) / nu
			var x: float = -cos(a) * w
			var y: float = sin(a) * h
			# des rides sur le dos
			y += sin(t * 60.0) * 0.008 * sin(a)
			row.append(Vector3(x, y, z))
		grid.append(row)
	for j2 in range(nv):
		for i2 in range(nu):
			var q := [grid[j2][i2], grid[j2][i2 + 1], grid[j2 + 1][i2 + 1], grid[j2 + 1][i2]]
			var n: Vector3 = ((q[1] as Vector3) - (q[0] as Vector3)).cross((q[3] as Vector3) - (q[0] as Vector3)).normalized()
			if n.y < 0.0:
				n = -n
			for idx in [0, 2, 1, 0, 3, 2]:
				var p: Vector3 = q[idx]
				st.set_normal((Vector3(p.x, p.y * 1.6, 0.0).normalized() + n * 0.4).normalized())
				st.add_vertex(p)
	_body = MeshInstance3D.new()
	_body.mesh = st.commit()
	_body.material_override = _mat("peau")
	add_child(_body)
	# le manteau (une selle un peu plus sombre)
	var m2 := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.36
	sm.height = 0.42
	m2.mesh = sm
	m2.material_override = _mat("manteau")
	m2.scale = Vector3(1.05, 0.9, 1.6)
	m2.position = Vector3(0, 0.26, 0.2)
	_body.add_child(m2)
	# les cornes : deux grandes (les yeux au bout), deux petites
	for s in [-1.0, 1.0]:
		for big in [true, false]:
			var c := Node3D.new()
			c.position = Vector3(s * (0.09 if big else 0.13), 0.22 if big else 0.1, L * 0.47)
			c.rotation = Vector3(-0.75 if big else -0.2, 0, s * (0.35 if big else 0.6))
			var tube := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.025 if big else 0.02
			cm.bottom_radius = 0.045 if big else 0.035
			cm.height = 0.5 if big else 0.16
			tube.mesh = cm
			tube.material_override = _mat("peau")
			tube.position.y = cm.height * 0.5
			c.add_child(tube)
			if big:
				var eye := MeshInstance3D.new()
				var em := SphereMesh.new()
				em.radius = 0.05
				em.height = 0.1
				eye.mesh = em
				eye.material_override = _mat("oeil")
				eye.position.y = cm.height
				c.add_child(eye)
			_body.add_child(c)
			_cornes.append(c)


func _sol() -> void:
	var y: float = main._height_at(global_position.x, global_position.z) if main != null else global_position.y
	global_position.y = y


func is_hittable() -> bool:
	return etat == "rampe" or etat == "mange"


func take_hit(_damage: int, from_pos: Vector3) -> void:
	if not is_hittable():
		return
	etat = "fuit"
	_t = 0.0
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	# elle file vers la clôture la plus proche, à l'opposé du coup si possible
	if away.length() > 0.01:
		var d1: Vector3 = (sortie - global_position)
		d1.y = 0.0
		if d1.normalized().dot(away.normalized()) < -0.3:
			sortie = global_position + away.normalized() * 14.0
	if main != null and main.has_method("sfx"):
		main.sfx("limace_splotch", global_position)
	if main != null and main.get("combat_fx_v129") != null:
		main.combat_fx_v129._puffs(global_position + Vector3.UP * 0.3, 6, Color(0.85, 0.9, 0.95, 0.5), 0.15, 0.4, 0.6, 1.0, 2.0, 0.6, 0.3)
	remove_from_group("cibles_v28")
	chassee.emit(self)


func _process(delta: float) -> void:
	if main == null:
		return
	_t += delta
	match etat:
		"rampe":
			var to: Vector3 = cible - global_position
			to.y = 0.0
			if to.length() < 1.6:
				etat = "mange"
				_t = 0.0
			else:
				_avance(to, 0.35, delta)
		"mange":
			# la tête qui va et vient (elle grignote)
			_body.scale = Vector3(1.0, 1.0, 1.0 + 0.06 * sin(_t * 3.0))
			for c in _cornes:
				(c as Node3D).rotation.x += sin(_t * 2.0) * 0.002
			if _t > 14.0 + _rng.randf() * 10.0:
				# un autre chou
				cible += Vector3(_rng.randf_range(-6.0, 6.0), 0, _rng.randf_range(-6.0, 6.0))
				etat = "rampe"
		"fuit":
			# recroquevillée d'abord (les cornes rentrées), puis elle glisse vite
			_shrink = minf(_shrink + delta * 4.0, 1.0)
			for c in _cornes:
				(c as Node3D).scale = Vector3.ONE * (1.0 - _shrink * 0.85)
			_body.scale = Vector3(1.0 + 0.15 * _shrink, 1.0 + 0.2 * _shrink, 1.0 - 0.35 * _shrink)
			if _t > 0.8:
				var to2: Vector3 = sortie - global_position
				to2.y = 0.0
				_avance(to2, 4.5, delta)
				if to2.length() < 1.0 or _t > 6.0:
					etat = "partie"
					_t = 0.0
		"partie":
			scale = Vector3.ONE * maxf(1.0 - _t * 2.0, 0.01)
			if _t > 0.5:
				queue_free()
	# la bave : des petites flaques brillantes, qui sèchent
	_trail_t -= delta
	if _trail_t <= 0.0 and etat in ["rampe", "fuit"]:
		_trail_t = 0.6
		_bave()
	for i in range(_trail.size() - 1, -1, -1):
		var e: Array = _trail[i]
		e[1] = float(e[1]) - delta
		if float(e[1]) <= 0.0:
			if is_instance_valid(e[0]):
				(e[0] as Node).queue_free()
			_trail.remove_at(i)


func _avance(to: Vector3, v: float, delta: float) -> void:
	var dir: Vector3 = to.normalized()
	var yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * 2.0, 0.0, 1.0))
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	global_position += fwd * v * delta
	_sol()
	# le corps ondule un peu en avançant
	_body.scale = Vector3(1.0, 1.0, 1.0 + 0.05 * sin(_t * 4.0)) if etat == "rampe" else _body.scale


func _bave() -> void:
	if get_parent() == null:
		return
	var q := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.45, 0.8)
	q.mesh = pm
	q.material_override = _mat("bave")
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(q)
	q.global_position = global_position + Vector3.UP * 0.04
	q.rotation.y = rotation.y
	_trail.append([q, 18.0])


func _exit_tree() -> void:
	for e in _trail:
		if is_instance_valid(e[0]):
			(e[0] as Node).queue_free()
	_trail.clear()

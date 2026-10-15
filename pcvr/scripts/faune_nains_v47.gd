extends Node3D
## V47 : la faune de la Montagne de Feu (décor vivant, sans combat).
##  - chèvres des cendres : broutent sur les pentes et dans l'enclos de Hilda, s'écartent si
##    l'on court vers elles ;
##  - salamandres de feu : se chauffent près des fumerolles du sentier, taches incandescentes ;
##  - corbeaux des cendres : tournent autour du sommet, se posent sur les grands rochers et
##    s'envolent quand on approche ;
##  - crabes de lave : sur la plage noire, carapace de basalte fendue de rouge, filent de
##    côté.
## Tout s'arrête quand le joueur est loin de l'île ou sous terre.

var n: Node3D                 # nains_v46.gd
var main: Node
var animals: Array = []       # {kind, node, home, radius, target, state, timer, legs, ...}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}


func setup(nains: Node3D) -> void:
	n = nains
	main = n.main
	_rng.seed = 4790


func build() -> void:
	# Chèvres : deux dans l'enclos, quatre sur les pentes
	var pen: Vector3 = n.forge_root.to_global(Vector3(12.5, 0, 3.3))
	for k in range(2):
		_add("chevre", pen + Vector3(k * 1.2 - 0.6, 0, 0), 1.8, k)
	for k in range(4):
		var a: float = n.ile.BAY_ANGLE + 0.8 + k * 1.3
		var home := Vector3(n.ile.CENTER.x + cos(a) * 74.0, 0, n.ile.CENTER.z + sin(a) * 74.0)
		if n._ground(home.x, home.z) < 1.0:
			home = home.lerp(Vector3(n.ile.CENTER.x, 0, n.ile.CENTER.z), 0.15)
		_add("chevre", home, 9.0, k + 2)
	# Salamandres près des fumerolles
	var fi: int = 0
	for fp in n.fumaroles:
		_add("salamandre", fp + Vector3(1.2, 0, 0.8), 2.5, fi)
		fi += 1
	_add("salamandre", n.ile.trail_end + Vector3(1.5, 0, -1.0), 2.5, fi)
	# Corbeaux : quatre en vol, un sur chaque perchoir
	for k in range(4):
		_add("corbeau", n.ile.peak_world(), 0.0, k)
	var pi: int = 0
	for pp in n.perches:
		var c: Dictionary = _add("corbeau", pp, 0.0, 10 + pi)
		c["state"] = "perche"
		c["perch"] = pp
		(c["node"] as Node3D).global_position = pp
		pi += 1
	# Crabes de lave sur la plage noire
	var made: int = 0
	for k in range(40):
		if made >= 7:
			break
		var a2: float = n.ile.BAY_ANGLE + 0.35 + k * 0.29
		for rr in range(70, 135, 2):
			var q := Vector3(n.ile.CENTER.x + cos(a2) * rr, 0, n.ile.CENTER.z + sin(a2) * rr)
			var h: float = n._ground(q.x, q.z)
			if h > -0.1 and h < 0.9:
				if Vector2(q.x - n.ile.dock_start.x, q.z - n.ile.dock_start.z).length() > 6.0:
					_add("crabe", q, 3.0, made)
					made += 1
				break


# =================================================================== fabrication

func _mat(key: String, c: Color, rough: float = 0.8, glow: float = 0.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	_mats[key] = m
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _sph(r: float, segs: int = 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 4)
	return s


func _cyl(a: float, b: float, h: float, segs: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = h
	c.radial_segments = segs
	return c


func _add(kind: String, home: Vector3, radius: float, k: int) -> Dictionary:
	var node := Node3D.new()
	node.name = "%s_%d" % [kind, k]
	add_child(node)
	var a := {"kind": kind, "node": node, "home": home, "radius": radius, "target": home, "state": "repos",
		"timer": _rng.randf_range(0.5, 4.0), "legs": [], "phase": _rng.randf() * TAU, "speed": 0.0, "k": k}
	match kind:
		"chevre":
			_build_goat(a, k)
		"salamandre":
			_build_salamander(a)
		"corbeau":
			_build_crow(a)
		_:
			_build_crab(a)
	var p: Vector3 = home
	if kind != "corbeau":
		p.y = n._ground(p.x, p.z)
	node.global_position = p
	if kind == "corbeau" and not a.has("perch"):
		a["state"] = "vol"
		a["orbit_r"] = _rng.randf_range(22.0, 42.0)
		a["orbit_h"] = n.ile.peak_world().y + _rng.randf_range(14.0, 32.0)
		a["angle"] = _rng.randf() * TAU
	animals.append(a)
	return a


func _build_goat(a: Dictionary, k: int) -> void:
	var root: Node3D = a["node"]
	var body := Node3D.new()
	body.name = "Corps"
	root.add_child(body)
	var coats := [Color(0.92, 0.9, 0.86), Color(0.45, 0.42, 0.4), Color(0.18, 0.15, 0.14), Color(0.6, 0.42, 0.28)]
	var coat: StandardMaterial3D = _mat("chevre_%d" % (k % 4), coats[k % 4], 0.95)
	var horn: StandardMaterial3D = _mat("corne", Color(0.42, 0.36, 0.28), 0.6)
	var hoof: StandardMaterial3D = _mat("sabot", Color(0.12, 0.1, 0.09), 0.7)
	_part(body, _sph(0.3), coat, Vector3(0, 0.62, 0), Vector3(0.95, 0.9, 1.55))
	_part(body, _sph(0.2), coat, Vector3(0, 0.66, 0.36), Vector3(1.0, 1.0, 0.9))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.82, 0.5)
	body.add_child(head)
	_part(head, _cyl(0.07, 0.09, 0.3), coat, Vector3(0, 0.0, 0.0), Vector3.ONE, Vector3(0.6, 0, 0))
	_part(head, _sph(0.11), coat, Vector3(0, 0.12, 0.12), Vector3(0.85, 0.9, 1.25))
	_part(head, _sph(0.06), coat, Vector3(0, 0.08, 0.25), Vector3(0.9, 0.8, 1.0))
	for sx in [-1.0, 1.0]:
		_part(head, _cyl(0.008, 0.03, 0.28, 6), horn, Vector3(sx * 0.05, 0.28, 0.02), Vector3.ONE, Vector3(-0.9, 0, sx * 0.25))
		_part(head, _sph(0.035), coat, Vector3(sx * 0.1, 0.17, 0.08), Vector3(1.6, 0.5, 0.8))
		_part(head, _sph(0.015), _mat("oeil_chevre", Color(0.85, 0.65, 0.2), 0.3), Vector3(sx * 0.075, 0.16, 0.2))
	_part(head, _cyl(0.0, 0.03, 0.1, 6), coat, Vector3(0, -0.02, 0.24), Vector3.ONE, Vector3(PI, 0, 0))
	a["head"] = head
	for lz in [0.3, -0.3]:
		for sx2 in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(sx2 * 0.15, 0.5, lz)
			body.add_child(leg)
			_part(leg, _cyl(0.035, 0.03, 0.46), coat, Vector3(0, -0.23, 0))
			_part(leg, _cyl(0.035, 0.035, 0.05), hoof, Vector3(0, -0.47, 0))
			(a["legs"] as Array).append([leg, sx2 * (1.0 if lz > 0 else -1.0)])
	_part(body, _sph(0.05), coat, Vector3(0, 0.78, -0.45), Vector3(0.8, 1.6, 0.6), Vector3(-0.6, 0, 0))


func _build_salamander(a: Dictionary) -> void:
	var root: Node3D = a["node"]
	var skin: StandardMaterial3D = _mat("salamandre", Color(0.08, 0.06, 0.06), 0.4)
	var spot: StandardMaterial3D = _mat("tache_feu", Color(1.0, 0.45, 0.08), 0.4, 2.5)
	var segs: Array = []
	for k in range(7):
		var seg := Node3D.new()
		root.add_child(seg)
		var r: float = 0.06 - absf(k - 2.0) * 0.006
		_part(seg, _sph(maxf(r, 0.02)), skin, Vector3.ZERO, Vector3(1.0, 0.6, 1.4))
		if k % 2 == 1 and k < 6:
			_part(seg, _sph(0.022), spot, Vector3(0.03, 0.025, 0), Vector3(1.0, 0.5, 1.0))
			_part(seg, _sph(0.02), spot, Vector3(-0.03, 0.025, 0.01), Vector3(1.0, 0.5, 1.0))
		segs.append(seg)
	# Tête : yeux dorés
	for sx in [-1.0, 1.0]:
		_part(segs[0], _sph(0.014), _mat("oeil_sal", Color(1.0, 0.8, 0.2), 0.2, 1.5), Vector3(sx * 0.035, 0.03, 0.04))
	for k2 in [1, 4]:
		for sx2 in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(sx2 * 0.05, 0, 0)
			segs[k2].add_child(leg)
			_part(leg, _cyl(0.012, 0.012, 0.09, 5), skin, Vector3(sx2 * 0.04, -0.01, 0), Vector3.ONE, Vector3(0, 0, sx2 * 1.3))
			(a["legs"] as Array).append([leg, sx2])
	a["segs"] = segs


func _build_crow(a: Dictionary) -> void:
	var root: Node3D = a["node"]
	var black: StandardMaterial3D = _mat("corbeau", Color(0.04, 0.04, 0.06), 0.35)
	var beak: StandardMaterial3D = _mat("bec", Color(0.12, 0.12, 0.14), 0.3)
	var body := Node3D.new()
	body.name = "Corps"
	root.add_child(body)
	_part(body, _sph(0.12), black, Vector3(0, 0.0, 0), Vector3(0.85, 0.85, 1.6))
	_part(body, _sph(0.08), black, Vector3(0, 0.07, 0.18))
	_part(body, _cyl(0.0, 0.03, 0.12, 5), beak, Vector3(0, 0.06, 0.3), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(body, _sph(0.012), _mat("oeil_corbeau", Color(0.9, 0.9, 0.95), 0.2, 0.5), Vector3(sx * 0.05, 0.09, 0.23))
	_part(body, _sph(0.08), black, Vector3(0, -0.01, -0.25), Vector3(0.9, 0.2, 1.6))
	var wings: Array = []
	for sx2 in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(sx2 * 0.07, 0.03, 0.02)
		body.add_child(w)
		_part(w, _sph(0.2), black, Vector3(sx2 * 0.2, 0, -0.02), Vector3(1.2, 0.08, 0.5))
		wings.append([w, sx2])
	a["wings"] = wings
	for sx3 in [-1.0, 1.0]:
		_part(body, _cyl(0.006, 0.006, 0.1, 4), beak, Vector3(sx3 * 0.04, -0.12, 0.02))
	a["body"] = body


func _build_crab(a: Dictionary) -> void:
	var root: Node3D = a["node"]
	var shell: StandardMaterial3D = _mat("crabe_lave", Color(0.14, 0.11, 0.1), 0.6)
	var crack: StandardMaterial3D = _mat("fente_lave", Color(1.0, 0.35, 0.05), 0.5, 3.0)
	var body := Node3D.new()
	root.add_child(body)
	_part(body, _sph(0.2), shell, Vector3(0, 0.16, 0), Vector3(1.3, 0.55, 1.0))
	for k in range(5):
		_part(body, _cyl(0.008, 0.008, 0.2, 4), crack, Vector3(-0.15 + k * 0.075, 0.26, 0.0), Vector3.ONE, Vector3(PI * 0.5, 0.6 * (k - 2), 0))
	for sx in [-1.0, 1.0]:
		_part(body, _cyl(0.012, 0.012, 0.07, 5), shell, Vector3(sx * 0.06, 0.27, 0.15))
		_part(body, _sph(0.022), crack, Vector3(sx * 0.06, 0.31, 0.15))
		var claw := Node3D.new()
		claw.position = Vector3(sx * 0.22, 0.15, 0.17)
		body.add_child(claw)
		_part(claw, _sph(0.08), shell, Vector3(sx * 0.05, 0, 0.06), Vector3(1.0, 0.7, 1.3))
		_part(claw, _sph(0.02), crack, Vector3(sx * 0.05, 0.04, 0.1))
		for k2 in range(3):
			var leg := Node3D.new()
			leg.position = Vector3(sx * 0.2, 0.14, 0.06 - k2 * 0.09)
			body.add_child(leg)
			_part(leg, _cyl(0.012, 0.012, 0.22, 4), shell, Vector3(sx * 0.09, -0.05, 0), Vector3.ONE, Vector3(0, 0, sx * 1.1))
			(a["legs"] as Array).append([leg, sx * (1.0 if k2 % 2 == 0 else -1.0)])


# =================================================================== comportement

func _process(delta: float) -> void:
	if main == null or not main.game_started or n.ile == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var far: bool = Vector2(p.x - n.ile.CENTER.x, p.z - n.ile.CENTER.z).length() > 260.0 or p.y < -30.0
	visible = not far
	if far:
		return
	_clock += delta
	for a in animals:
		match str(a["kind"]):
			"corbeau":
				_tick_crow(a, delta, p)
			_:
				_tick_walker(a, delta, p)


## Chèvres, salamandres et crabes : errent autour de leur coin, fuient si l'on approche.
func _tick_walker(a: Dictionary, delta: float, p: Vector3) -> void:
	var node: Node3D = a["node"]
	var pos: Vector3 = node.global_position
	var kind: String = a["kind"]
	var to_p: Vector3 = (p - pos) * Vector3(1, 0, 1)
	var fear: float = 3.2 if kind == "chevre" else (2.2 if kind == "salamandre" else 2.8)
	var walk_speed: float = 0.7 if kind == "chevre" else (0.35 if kind == "salamandre" else 0.6)
	var run_speed: float = 3.2 if kind == "chevre" else (1.6 if kind == "salamandre" else 2.4)
	a["timer"] = float(a["timer"]) - delta
	var home: Vector3 = a["home"]
	var radius: float = float(a["radius"])
	if to_p.length() < fear and str(a["state"]) != "fuite":
		a["state"] = "fuite"
		a["timer"] = 1.4
		var away: Vector3 = -to_p.normalized() * 3.0
		var tgt: Vector3 = pos + away
		var off := Vector3(tgt.x - home.x, 0, tgt.z - home.z)
		if off.length() > radius + 2.0:
			tgt = home + off.normalized() * (radius + 2.0)
		a["target"] = tgt
	match str(a["state"]):
		"repos":
			if float(a["timer"]) <= 0.0:
				var ang: float = _rng.randf() * TAU
				var r: float = _rng.randf() * radius
				a["target"] = home + Vector3(cos(ang) * r, 0, sin(ang) * r)
				a["state"] = "marche"
				a["timer"] = 8.0
		"marche", "fuite":
			var tgt2: Vector3 = a["target"]
			var dv := Vector3(tgt2.x - pos.x, 0, tgt2.z - pos.z)
			var spd: float = run_speed if str(a["state"]) == "fuite" else walk_speed
			if dv.length() < 0.2 or float(a["timer"]) <= 0.0:
				a["state"] = "repos"
				a["timer"] = _rng.randf_range(2.0, 7.0)
				a["speed"] = 0.0
			else:
				var step: Vector3 = dv.normalized() * minf(spd * delta, dv.length())
				var nx: Vector3 = pos + step
				var gy: float = n._ground(nx.x, nx.z)
				# Pas dans la mer, pas dans les pentes trop raides
				if (kind != "crabe" and gy < 0.3) or absf(gy - pos.y) > spd * delta * 1.8 + 0.05:
					a["state"] = "repos"
					a["timer"] = 1.0
				else:
					nx.y = gy
					node.global_position = nx
					a["speed"] = spd
					var yaw: float = atan2(dv.x, dv.z)
					if kind == "crabe":
						yaw += PI * 0.5      # le crabe marche de côté
					node.rotation.y = lerp_angle(node.rotation.y, yaw, clampf(delta * 6.0, 0.0, 1.0))
	_animate_walker(a, delta)


func _animate_walker(a: Dictionary, delta: float) -> void:
	var spd: float = float(a["speed"])
	var t: float = _clock * (9.0 if str(a["kind"]) == "chevre" else 14.0) + float(a["phase"])
	var amp: float = clampf(spd, 0.0, 1.0)
	for l in a["legs"]:
		var leg: Node3D = l[0]
		leg.rotation.x = sin(t + (0.0 if float(l[1]) > 0 else PI)) * 0.5 * amp
	match str(a["kind"]):
		"chevre":
			var head: Node3D = a["head"]
			var graze: float = 1.0 if str(a["state"]) == "repos" and sin(_clock * 0.4 + float(a["phase"])) > 0.0 else 0.0
			head.rotation.x = lerpf(head.rotation.x, graze * 0.9 + sin(_clock * 3.0 + float(a["phase"])) * 0.04 * graze, clampf(delta * 3.0, 0.0, 1.0))
		"salamandre":
			var segs: Array = a["segs"]
			var wig: float = 0.15 + amp * 0.4
			for k in range(segs.size()):
				var seg: Node3D = segs[k]
				seg.position = Vector3(sin(_clock * 6.0 - k * 0.8 + float(a["phase"])) * 0.03 * wig * 3.0, 0.035, 0.12 - k * 0.07)


## Corbeaux : vol circulaire autour du sommet ; ceux des perchoirs s'envolent quand on
## approche, tournent un moment, puis reviennent se poser.
func _tick_crow(a: Dictionary, delta: float, p: Vector3) -> void:
	var node: Node3D = a["node"]
	var flap: float = 1.0
	match str(a["state"]):
		"perche":
			flap = 0.0
			if node.global_position.distance_to(p) < 7.0:
				a["state"] = "vol"
				a["orbit_r"] = _rng.randf_range(10.0, 18.0)
				a["orbit_h"] = (a["perch"] as Vector3).y + _rng.randf_range(10.0, 18.0)
				a["angle"] = _rng.randf() * TAU
				a["center"] = a["perch"]
				a["timer"] = _rng.randf_range(14.0, 24.0)
		"vol":
			a["angle"] = float(a["angle"]) + delta * 9.0 / float(a["orbit_r"])
			var c: Vector3 = a.get("center", n.ile.peak_world())
			var goal := Vector3(c.x + cos(float(a["angle"])) * float(a["orbit_r"]), float(a["orbit_h"]) + sin(_clock * 0.7 + float(a["phase"])) * 2.0, c.z + sin(float(a["angle"])) * float(a["orbit_r"]))
			var prev: Vector3 = node.global_position
			node.global_position = prev.lerp(goal, clampf(delta * 1.5, 0.0, 1.0))
			var v: Vector3 = node.global_position - prev
			if v.length() > 0.001:
				node.rotation.y = atan2(v.x, v.z)
				node.rotation.z = -0.35
			if a.has("perch"):
				a["timer"] = float(a["timer"]) - delta
				if float(a["timer"]) <= 0.0 and (a["perch"] as Vector3).distance_to(p) > 12.0:
					a["state"] = "retour"
		"retour":
			var pp: Vector3 = a["perch"]
			var dv: Vector3 = pp - node.global_position
			if dv.length() < 0.3:
				node.global_position = pp
				node.rotation.z = 0.0
				a["state"] = "perche"
			else:
				node.global_position += dv.normalized() * minf(9.0 * delta, dv.length())
				node.rotation.y = atan2(dv.x, dv.z)
				node.rotation.z = 0.0
	for w in a["wings"]:
		var hinge: Node3D = w[0]
		var sx: float = float(w[1])
		if flap > 0.0:
			hinge.rotation.z = sx * (sin(_clock * 11.0 + float(a["phase"])) * 0.7)
		else:
			hinge.rotation.z = sx * -0.15

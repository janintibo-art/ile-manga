extends Node3D
## V39 : Temple englouti, étape 5 — le Puits des Abysses.
## Au fond du Sanctuaire de l'Œil, le sceau ne cède qu'à l'Amulette du Serpent : il roule de
## côté et découvre le puits. Une rampe de pierre descend en spirale le long des parois,
## 40 m plus bas (un parapet du côté du vide, et un bassin d'eau noire au fond qui amortit
## les chutes). Une chaîne de bronze pend au centre : une fois en bas, on s'en sert pour
## remonter ou redescendre d'un coup.
## En bas : le Lac Noir. On le traverse sur des dalles gravées des quatre symboles ; seules
## celles qui suivent le chant de la fresque (lune, vague, soleil, serpent… deux fois)
## portent le marcheur, les autres s'enfoncent. Sur l'autre rive : la Porte de l'Abîme, ses
## deux serpents géants, le coffre des Abysses et la Pierre de l'Œil, qui réveille ce qui
## dort derrière la porte (le combat final, à l'étape suivante).
## Des vipères des abysses rôdent sur les deux rives.
## Repère : section « village » du temple (comme le sanctuaire).

const Rocks = preload("res://scripts/rocks_v26.gd")
const TOP_Y: float = -3.0                      # sol du sanctuaire
const BOTTOM_Y: float = -43.0                  # fond du puits et rives du lac
const SHAFT_C := Vector3(-0.5, 0.0, -105.0)    # axe du puits
const RAMP_R: float = 5.2                      # rayon de la rampe (milieu)
const RAMP_W: float = 2.0
const SLOPE: float = 0.3                       # pente de la rampe
const THETA0: float = 1.4745                   # départ de la rampe, côté sanctuaire
const POOL_R: float = 4.0
const ORDER := ["lune", "vague", "soleil", "serpent"]
## Symboles des dalles, rangée par rangée (de la rive sud vers la rive nord).
const ROWS := [
	["soleil", "lune", "serpent", "vague"],
	["lune", "serpent", "vague", "soleil"],
	["vague", "lune", "soleil", "serpent"],
	["soleil", "vague", "lune", "serpent"],
	["serpent", "soleil", "lune", "vague"],
	["lune", "vague", "serpent", "soleil"],
	["soleil", "serpent", "vague", "lune"],
	["vague", "serpent", "soleil", "lune"],
]
const LAKE_Z0: float = -134.2                  # rive nord
const LAKE_Z1: float = -118.0                  # rive sud
const LAKE_X0: float = -14.0
const LAKE_X1: float = 12.0

var d: Node
var main: Node
var _seal: Node3D
var _chains: Node3D
var _stones: Array = []                        # {node, body, row, col, symbol, glyph, sunk}
var _barrier: MeshInstance3D
var _barrier_mat: StandardMaterial3D
var _statue_eyes: Array = []
var _chest: Node3D
var _respawning: bool = false
var _on_wrong: float = 0.0
var _clock: float = 0.0
var _in_pool: bool = false


func setup(donjon: Node, main_node: Node) -> void:
	d = donjon
	main = main_node


func ramp_end() -> float:
	return THETA0 + (TOP_Y - BOTTOM_Y) / (RAMP_R * SLOPE)


## Point de la rampe (milieu) à l'angle « a » (repère « village »).
func ramp_point(a: float, r: float = RAMP_R) -> Vector3:
	var y: float = TOP_Y - (a - THETA0) * RAMP_R * SLOPE
	return Vector3(SHAFT_C.x + cos(a) * r, maxf(y, BOTTOM_Y), SHAFT_C.z + sin(a) * r)


func stone_x(col: int) -> float:
	return -0.5 + (col - 1.5) * 2.0


func stone_z(row: int) -> float:
	return -119.0 - row * 2.0


# =================================================================== état

func apply_state() -> void:
	var open: bool = bool(d.state["sceau"])
	if _seal != null:
		_seal.position.x = 5.0 if open else 0.0
		_seal.rotation.z = -5.0 / 2.6 if open else 0.0
		(_seal.get_node("Corps") as StaticBody3D).collision_layer = 0 if open else 1
		_chains.visible = not open
	var crossed: bool = bool(d.state["lac"])
	for st in _stones:
		var good: bool = str(st["symbol"]) == ORDER[int(st["row"]) % 4]
		var sunk: bool = crossed and not good
		st["sunk"] = sunk
		(st["node"] as Node3D).position.y = BOTTOM_Y - 1.55 - (1.4 if sunk else 0.0)
		(st["body"] as StaticBody3D).collision_layer = 0 if sunk else 1
		var gm: StandardMaterial3D = st["glyph_mat"]
		gm.emission_energy_multiplier = 1.2 if crossed and good else 0.0
	var awake: bool = bool(d.state["abime_eveil"])
	for e in _statue_eyes:
		(e as StandardMaterial3D).emission_energy_multiplier = 6.0 if awake else 0.6
	if _chest != null:
		(_chest.get_node("Charniere") as Node3D).rotation.x = -1.8 if bool(d.state["coffre_abysses"]) else 0.0


# =================================================================== matériaux et formes

func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _cyl(r_top: float, r_bottom: float, h: float, segs: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = segs
	return c


func _obsidian() -> StandardMaterial3D:
	if not d._mats.has("obsidienne"):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/textures/jungle/jungle_rock.png")
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.4, 0.4, 0.4)
		m.albedo_color = Color(0.16, 0.17, 0.18)
		m.roughness = 0.18
		m.metallic = 0.1
		d._mats["obsidienne"] = m
	return d._mats["obsidienne"]


func _crystal_mat() -> StandardMaterial3D:
	if not d._mats.has("cristal"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.3, 0.95, 0.6, 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.1
		m.emission_enabled = true
		m.emission = Color(0.25, 1.0, 0.55)
		m.emission_energy_multiplier = 2.2
		d._mats["cristal"] = m
	return d._mats["cristal"]


func _dark_water() -> StandardMaterial3D:
	if not d._mats.has("eau_noire"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.015, 0.04, 0.045, 0.94)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.03
		m.metallic = 0.35
		d._mats["eau_noire"] = m
	return d._mats["eau_noire"]


## Grappe de cristaux verts qui luisent, avec leur lumière.
func _crystals(s: Node3D, pos: Vector3, normal: Vector3, seed_v: int, energy: float = 1.4) -> void:
	var root := Node3D.new()
	s.add_child(root)
	root.position = pos
	var up: Vector3 = (normal + Vector3.UP * 0.6).normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in range(6):
		var h: float = rng.randf_range(0.35, 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = _cyl(0.0, rng.randf_range(0.06, 0.13), h, 6)
		mi.material_override = _crystal_mat()
		var tilt := Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
		var dir: Vector3 = (up + tilt).normalized()
		root.add_child(mi)
		mi.position = Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.15, 0.15), rng.randf_range(-0.25, 0.25)) + dir * h * 0.5
		mi.basis = Basis(Quaternion(Vector3.UP, dir))
	var light := OmniLight3D.new()
	light.light_color = Color(0.35, 1.0, 0.6)
	light.light_energy = energy
	light.omni_range = 9.0
	light.position = normal * 0.6 + Vector3.UP * 0.5
	root.add_child(light)


## Murs seuls (sans sol ni plafond), avec des ouvertures [côté, centre, largeur, bas, haut]
## à n'importe quelle hauteur.
func _walls(s: Node3D, x0: float, x1: float, z0: float, z1: float, y0: float, h: float, wall: String, openings: Array = []) -> void:
	var t: float = 0.6
	for side in ["n", "s", "e", "w"]:
		var along_x: bool = side in ["n", "s"]
		var a0: float = x0 - t if along_x else z0
		var a1: float = x1 + t if along_x else z1
		var fixed: float = (z0 - t * 0.5) if side == "n" else ((z1 + t * 0.5) if side == "s" else ((x1 + t * 0.5) if side == "e" else (x0 - t * 0.5)))
		var gaps: Array = []
		for o in openings:
			if str(o[0]) == side:
				gaps.append([float(o[1]) - float(o[2]) * 0.5, float(o[1]) + float(o[2]) * 0.5, float(o[3]), float(o[4])])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		var cur: float = a0
		for g in gaps:
			if g[0] > cur:
				d._wall_piece(s, along_x, fixed, cur, g[0], y0, h, t, wall)
			if float(g[2]) > y0:
				d._wall_piece(s, along_x, fixed, g[0], g[1], y0, float(g[2]) - y0, t, wall)
			if float(g[3]) < y0 + h:
				d._wall_piece(s, along_x, fixed, g[0], g[1], float(g[3]), y0 + h - float(g[3]), t, wall)
			cur = g[1]
		if cur < a1:
			d._wall_piece(s, along_x, fixed, cur, a1, y0, h, t, wall)


# =================================================================== construction

func build(s: Node3D) -> void:
	_build_seal(s)
	_build_shaft(s)
	_build_lake(s)
	_build_far_shore(s)


## Le sceau : un disque de pierre barré de chaînes, devant l'ouverture nord du sanctuaire.
func _build_seal(s: Node3D) -> void:
	var y0: float = TOP_Y
	# Le nœud est au centre du disque : il roule autour de son axe en s'écartant.
	_seal = Node3D.new()
	_seal.name = "Sceau_des_Abysses"
	_seal.position = Vector3(0, y0 + 2.4, -93.85)
	s.add_child(_seal)
	_mesh(_seal, _cyl(2.6, 2.6, 0.3, 40), d._mat("mur"), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	var g := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(3.0, 3.0)
	g.mesh = gq
	g.material_override = d._glyph_mat("serpent")
	g.position = Vector3(0, 0, 0.17)
	_seal.add_child(g)
	var body := StaticBody3D.new()
	body.name = "Corps"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.8, 5.0, 0.3)
	cs.shape = bs
	body.add_child(cs)
	_seal.add_child(body)
	_chains = Node3D.new()
	_chains.name = "Chaines"
	_chains.position = Vector3(0, y0 + 2.4, -93.6)
	s.add_child(_chains)
	for a in [0.75, -0.75]:
		d._box(_chains, Vector3(0.14, 5.8, 0.12), Vector3.ZERO, d._mat("bronze"), false, Vector3(0, 0, a))
	var txt := Label3D.new()
	txt.text = "« Le Puits des Abysses. Ici dort ce que les Anciens ont enchaîné. »"
	txt.font_size = 40
	txt.pixel_size = 0.003
	txt.modulate = Color(0.86, 0.78, 0.6)
	txt.outline_size = 0
	txt.position = Vector3(0, y0 + 7.2, -93.95)
	s.add_child(txt)
	d._interactions.append({"id": "sceau_abysses", "pos": s.to_global(Vector3(0, y0, -91.6)), "radius": 2.2,
		"text": "E : examiner le sceau", "vr": "Gâchette : examiner le sceau", "call": use_seal,
		"when": func(): return not bool(d.state["sceau"])})


func use_seal() -> void:
	if main.inventory_v28.count("amulette_serpent") <= 0:
		d._say("Un sceau de pierre barré de chaînes de bronze. Derrière, un souffle glacé… Il faudrait la clé des Anciens.", 5.0)
		return
	d._busy = true
	d._say("L'Amulette du Serpent s'illumine. Les chaînes se brisent net…", 3.0)
	var ct := create_tween()
	ct.tween_property(_chains, "position:y", BOTTOM_Y + 40.2, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ct.parallel().tween_property(_chains, "rotation:z", 0.3, 0.7)
	if main.combat_v28 != null:
		main.combat_v28.puff(_chains.global_position, Color(0.75, 0.6, 0.35))
	await get_tree().create_timer(1.4).timeout
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_seal, "position:x", 5.0, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_seal, "rotation:z", -5.0 / 2.6, 3.0).set_trans(Tween.TRANS_SINE)
	await tw.finished
	d.state["sceau"] = true
	apply_state()
	d._busy = false
	d._say("Le sceau roule sur le côté. Un escalier plonge dans le noir, autour d'un puits sans fond…", 5.0)


## Le puits : 16 m × 14 m, 46 m de haut ; rampe en spirale, parapet, bassin, chaîne.
func _build_shaft(s: Node3D) -> void:
	var c: Vector3 = SHAFT_C
	var x0: float = c.x - 7.5
	var x1: float = c.x + 7.5
	var z0: float = c.z - 7.0
	var z1: float = c.z + 7.0
	# Vestibule entre le sanctuaire et le puits
	d._room(s, -2.3, 2.3, -97.4, -94.6, TOP_Y, 4.8, "grotte", "sol", [["s", 0.0, 4.6, 4.8], ["n", 0.0, 4.6, 4.8]], "grotte")
	d._torch(s, Vector3(-2.25, TOP_Y + 2.6, -96.0), Vector3(1, 0, 0), 1.0)
	# Sol, plafond et parois du puits
	d._box(s, Vector3(x1 - x0 + 1.2, 0.5, z1 - z0 + 1.2), Vector3(c.x, BOTTOM_Y - 0.25, c.z), d._mat("grotte"))
	d._box(s, Vector3(x1 - x0 + 1.2, 0.6, z1 - z0 + 1.2), Vector3(c.x, TOP_Y + 8.3, c.z), d._mat("grotte"))
	_walls(s, x0, x1, z0, z1, BOTTOM_Y, TOP_Y + 8.0 - BOTTOM_Y, "grotte",
		[["s", 0.0, 4.6, TOP_Y, TOP_Y + 4.8], ["n", c.x, 4.0, BOTTOM_Y, BOTTOM_Y + 5.0]])
	# Palier en haut de la rampe
	d._box(s, Vector3(3.8, 0.4, 3.4), Vector3(0.0, TOP_Y - 0.2, -99.1), d._mat("sol"))
	# Rampe en spirale et parapet côté vide
	var a: float = THETA0
	var a_end: float = ramp_end()
	var step: float = deg_to_rad(10.0)
	var pitch: float = atan(SLOPE)
	while a < a_end:
		var am: float = minf(a + step * 0.5, a_end)
		var p: Vector3 = ramp_point(am)
		var yaw: float = atan2(-sin(am), cos(am))
		var seg_len: float = RAMP_R * step / cos(pitch) + 0.18
		d._box(s, Vector3(RAMP_W, 0.4, seg_len), p + Vector3.DOWN * 0.2, d._mat("sol"), true, Vector3(pitch, yaw, 0))
		var pr: Vector3 = ramp_point(am, RAMP_R - RAMP_W * 0.5 - 0.12)
		d._box(s, Vector3(0.24, 0.9, (RAMP_R - 1.1) * step / cos(pitch) + 0.1), pr + Vector3.UP * 0.35, d._mat("mur"), true, Vector3(pitch, yaw, 0))
		a += step
	# Cristaux et torches le long de la descente
	for k in range(9):
		var ak: float = THETA0 + 1.2 + k * 2.6
		if k % 3 == 1:
			# Torche fixée à la paroi, au-dessus de la rampe
			var dir := Vector3(cos(ak), 0, sin(ak))
			var reach: float = minf(7.47 / maxf(absf(dir.x), 0.001), 6.97 / maxf(absf(dir.z), 0.001))
			var hy: float = ramp_point(ak).y + 2.0
			var wp: Vector3 = Vector3(c.x, hy, c.z) + dir * reach
			d._torch(s, wp, -dir, 1.2)
		else:
			var pw: Vector3 = ramp_point(ak, RAMP_R + RAMP_W * 0.5 - 0.35)
			var n: Vector3 = (Vector3(c.x, pw.y, c.z) - pw).normalized()
			_crystals(s, pw, n, 3900 + k, 1.3)
	# Le bassin d'eau noire au fond, et la chaîne de bronze qui pend au centre
	_mesh(s, _cyl(POOL_R, POOL_R, 0.02, 40), _dark_water(), Vector3(c.x, BOTTOM_Y + 0.03, c.z))
	for k in range(24):
		var ak2: float = TAU * k / 24.0
		d._box(s, Vector3(1.15, 0.3, 0.4), Vector3(c.x + cos(ak2) * (POOL_R + 0.2), BOTTOM_Y + 0.15, c.z + sin(ak2) * (POOL_R + 0.2)), d._mat("sol"), false, Vector3(0, -ak2 + PI * 0.5, 0))
	var chain_len: float = TOP_Y + 8.0 - BOTTOM_Y
	var links := Node3D.new()
	links.name = "Chaine_du_puits"
	s.add_child(links)
	var n_links: int = int(chain_len / 0.22)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.07
	tm.outer_radius = 0.13
	tm.rings = 12
	tm.ring_segments = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tm
	mm.instance_count = n_links
	for k in range(n_links):
		var b := Basis(Vector3.RIGHT, PI * 0.5)
		if k % 2 == 1:
			b = Basis(Vector3.UP, PI * 0.5) * b
		mm.set_instance_transform(k, Transform3D(b, Vector3(c.x, BOTTOM_Y + 1.0 + k * 0.22, c.z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = d._mat("bronze")
	links.add_child(mmi)
	_crystals(s, Vector3(c.x + 6.9, BOTTOM_Y + 0.3, c.z - 4.0), Vector3(-1, 0, 0), 3931, 1.8)
	_crystals(s, Vector3(c.x - 6.9, BOTTOM_Y + 0.3, c.z + 3.0), Vector3(1, 0, 0), 3932, 1.8)
	var shaft_light := SpotLight3D.new()
	shaft_light.light_color = Color(0.45, 0.9, 0.7)
	shaft_light.light_energy = 2.5
	shaft_light.spot_range = 50.0
	shaft_light.spot_angle = 14.0
	shaft_light.position = Vector3(c.x, TOP_Y + 7.6, c.z)
	shaft_light.rotation.x = -PI * 0.5
	s.add_child(shaft_light)
	# Côté nord du bassin (au sud, le bas de la rampe arrive au sol)
	d._interactions.append({"id": "chaine_monter", "pos": s.to_global(Vector3(c.x, BOTTOM_Y, c.z - POOL_R - 0.9)), "radius": 1.6,
		"text": "E : remonter par la chaîne", "vr": "Gâchette : remonter par la chaîne", "call": _chain_up})
	d._interactions.append({"id": "chaine_descendre", "pos": s.to_global(Vector3(0.0, TOP_Y, -99.0)), "radius": 1.5,
		"text": "E : descendre par la chaîne", "vr": "Gâchette : descendre par la chaîne", "call": _chain_down,
		"when": func(): return bool(d.state["abysses_bas"])})


func _chain_up() -> void:
	var s: Node3D = d.sections["village"]
	d._say("Tu agrippes la chaîne et te hisses, maillon après maillon…", 3.0)
	await d._travel(s.to_global(Vector3(0.0, TOP_Y + 0.05, -98.2)), s.to_global(Vector3(0, 0, 1)) - s.to_global(Vector3.ZERO))


func _chain_down() -> void:
	var s: Node3D = d.sections["village"]
	d._say("Tu te laisses glisser le long de la chaîne, jusqu'au fond du puits…", 3.0)
	await d._travel(s.to_global(Vector3(SHAFT_C.x, BOTTOM_Y + 0.05, SHAFT_C.z - POOL_R - 1.0)), s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO))


## Le Lac Noir : rive sud, huit rangées de dalles, rive nord.
func _build_lake(s: Node3D) -> void:
	var floor_y: float = BOTTOM_Y - 3.0
	var top: float = BOTTOM_Y + 14.0
	d._box(s, Vector3(LAKE_X1 - LAKE_X0 + 1.2, 0.5, 40.6), Vector3((LAKE_X0 + LAKE_X1) * 0.5, floor_y - 0.25, -132.3), d._mat("grotte"))
	d._box(s, Vector3(LAKE_X1 - LAKE_X0 + 1.2, 0.6, 40.6), Vector3((LAKE_X0 + LAKE_X1) * 0.5, top + 0.3, -132.3), d._mat("grotte"))
	_walls(s, LAKE_X0, LAKE_X1, -152.0, -112.6, floor_y, top - floor_y, "grotte", [["s", SHAFT_C.x, 4.0, BOTTOM_Y, BOTTOM_Y + 5.0]])
	# Rives (le sol de la caverne est 3 m plus bas : c'est le fond du lac)
	d._box(s, Vector3(LAKE_X1 - LAKE_X0, 3.0, 112.6 - 118.0 + 10.8), Vector3((LAKE_X0 + LAKE_X1) * 0.5, BOTTOM_Y - 1.5, -115.3), d._mat("grotte"))
	d._box(s, Vector3(LAKE_X1 - LAKE_X0, 3.0, 152.0 + LAKE_Z0), Vector3((LAKE_X0 + LAKE_X1) * 0.5, BOTTOM_Y - 1.5, (LAKE_Z0 - 152.0) * 0.5), d._mat("grotte"))
	# L'eau noire
	var w := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(LAKE_X1 - LAKE_X0, LAKE_Z1 - LAKE_Z0)
	w.mesh = wp
	w.material_override = _dark_water()
	w.position = Vector3((LAKE_X0 + LAKE_X1) * 0.5, BOTTOM_Y - 0.45, (LAKE_Z0 + LAKE_Z1) * 0.5)
	s.add_child(w)
	var rock: Material = Rocks.material(Color(0.42, 0.42, 0.41), 0.1, 0.3)
	d._boulders(s, Vector3(-1.0, BOTTOM_Y, -132.3), Vector2(12.4, 19.0), 18, 3941, rock, 1.2, 2.6)
	d._stalactites(s, Vector3(-1.0, BOTTOM_Y, -132.3), Vector2(12.0, 19.0), top, 34, 3942)
	# Les dalles
	for r in range(ROWS.size()):
		for col in range(4):
			var sym: String = ROWS[r][col]
			var node := Node3D.new()
			node.name = "Dalle_%d_%d" % [r, col]
			s.add_child(node)
			node.position = Vector3(stone_x(col), BOTTOM_Y - 1.55, stone_z(r))
			var mi := MeshInstance3D.new()
			mi.mesh = Rocks.shape(3950 + r * 4 + col, Vector3(1.7, 2.9, 1.7), 0.25, 0.04)
			mi.material_override = rock
			node.add_child(mi)
			d._box(node, Vector3(1.6, 0.2, 1.6), Vector3(0, 1.35, 0), d._mat("sol"), false)
			var gm := StandardMaterial3D.new()
			gm.albedo_texture = load(d.TEX + "glyph_" + sym + ".png")
			gm.roughness = 0.85
			gm.emission_enabled = true
			gm.emission = Color(0.3, 1.0, 0.55)
			gm.emission_energy_multiplier = 0.0
			var glyph := MeshInstance3D.new()
			var gq := QuadMesh.new()
			gq.size = Vector2(1.3, 1.3)
			glyph.mesh = gq
			glyph.material_override = gm
			glyph.rotation.x = -PI * 0.5
			glyph.position.y = 1.455
			node.add_child(glyph)
			var body := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(1.6, 2.9, 1.6)
			cs.shape = bs
			body.add_child(cs)
			node.add_child(body)
			_stones.append({"node": node, "body": body, "row": r, "col": col, "symbol": sym, "glyph_mat": gm, "sunk": false})
	# Inscription sur la rive sud
	var txt := Label3D.new()
	txt.text = "« Le chemin des Anciens suit le chant de la fresque.\nDeux fois. »"
	txt.font_size = 40
	txt.pixel_size = 0.003
	txt.modulate = Color(0.86, 0.78, 0.6)
	txt.outline_size = 0
	txt.position = Vector3(LAKE_X0 + 0.05, BOTTOM_Y + 2.2, -116.0)
	txt.rotation.y = PI * 0.5
	s.add_child(txt)
	d._interactions.append({"id": "inscription_lac", "pos": s.to_global(Vector3(LAKE_X0 + 1.4, BOTTOM_Y, -116.0)), "radius": 2.0,
		"text": "E : lire l'inscription", "vr": "Gâchette : lire l'inscription",
		"call": func(): d._say("« Le chemin des Anciens suit le chant de la fresque. Deux fois. » Chaque dalle du lac porte un des quatre symboles.", 6.0)})
	for p in [[Vector3(LAKE_X0 + 0.3, BOTTOM_Y + 0.3, -126.0), Vector3(1, 0, 0)], [Vector3(LAKE_X1 - 0.3, BOTTOM_Y + 0.3, -122.0), Vector3(-1, 0, 0)],
			[Vector3(LAKE_X1 - 0.3, BOTTOM_Y + 0.3, -131.0), Vector3(-1, 0, 0)], [Vector3(-8.0, BOTTOM_Y + 0.1, -114.0), Vector3(0, 0, -1)]]:
		_crystals(s, p[0], p[1], 3960 + int(p[0].z), 1.6)
	d._torch(s, Vector3(SHAFT_C.x - 2.4, BOTTOM_Y + 2.6, -112.65), Vector3(0, 0, -1), 1.3)
	d._torch(s, Vector3(SHAFT_C.x + 2.4, BOTTOM_Y + 2.6, -112.65), Vector3(0, 0, -1), 1.3)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.5, 0.8, 0.7)
	fill.light_energy = 0.9
	fill.omni_range = 24.0
	fill.omni_attenuation = 0.6
	fill.light_specular = 0.2
	fill.position = Vector3(-1.0, BOTTOM_Y + 8.0, -126.0)
	s.add_child(fill)


## Rive nord : la Porte de l'Abîme, ses deux serpents, la Pierre de l'Œil et le coffre.
func _build_far_shore(s: Node3D) -> void:
	var y: float = BOTTOM_Y
	var gate := Node3D.new()
	gate.name = "Porte_de_l_Abime"
	s.add_child(gate)
	gate.position = Vector3(-1.0, y, -151.7)
	d._box(gate, Vector3(3.2, 9.0, 0.6), Vector3(-1.6, 4.5, 0), _obsidian(), false)
	d._box(gate, Vector3(3.2, 9.0, 0.6), Vector3(1.6, 4.5, 0), _obsidian(), false)
	d._box(gate, Vector3(0.06, 8.6, 0.62), Vector3(0, 4.5, 0.02), d._mat("noir"), false)
	d._box(gate, Vector3(9.0, 1.2, 1.0), Vector3(0, 9.6, 0.1), d._mat("mur"), false)
	for sx in [-1.0, 1.0]:
		d._box(gate, Vector3(1.2, 9.0, 1.0), Vector3(sx * 3.9, 4.5, 0.1), d._mat("mur"), false)
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.2, 0.8, 0.4)
	eye.emission_enabled = true
	eye.emission = Color(0.3, 1.0, 0.5)
	eye.emission_energy_multiplier = 0.6
	_statue_eyes.append(eye)
	_mesh(gate, SphereMesh.new(), eye, Vector3(0, 6.2, 0.33), Vector3.ZERO, Vector3(0.9, 0.5, 0.2))
	# La barrière verte devant la porte
	_barrier = MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(6.6, 9.0)
	_barrier.mesh = bq
	_barrier_mat = StandardMaterial3D.new()
	_barrier_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_barrier_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_barrier_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_barrier_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_barrier_mat.albedo_color = Color(0.2, 0.9, 0.45, 0.18)
	_barrier.material_override = _barrier_mat
	_barrier.position = Vector3(0, 4.5, 1.2)
	gate.add_child(_barrier)
	var gb := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(6.6, 9.0, 0.4)
	gcs.shape = gbs
	gcs.position = Vector3(0, 4.5, 1.2)
	gb.add_child(gcs)
	gate.add_child(gb)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.3, 1.0, 0.55)
	gl.light_energy = 2.0
	gl.omni_range = 12.0
	gl.position = Vector3(0, 4.0, 2.5)
	gate.add_child(gl)
	# Deux serpents géants de part et d'autre
	for sx in [-1.0, 1.0]:
		var root := Node3D.new()
		s.add_child(root)
		root.position = Vector3(-1.0 + sx * 6.5, y, -148.5)
		d._box(root, Vector3(2.6, 1.2, 2.6), Vector3(0, 0.6, 0), d._mat("mur"))
		d._box(root, Vector3(2.0, 6.0, 2.0), Vector3(0, 4.0, 0), d._mat("mur"), true).visible = false
		var snake := Node3D.new()
		snake.position = Vector3(0, 1.2, 0)
		snake.scale = Vector3.ONE * 2.6
		root.add_child(snake)
		var seye := StandardMaterial3D.new()
		seye.albedo_color = Color(0.2, 0.8, 0.4)
		seye.emission_enabled = true
		seye.emission = Color(0.3, 1.0, 0.5)
		seye.emission_energy_multiplier = 0.6
		_statue_eyes.append(seye)
		d.serpents._snake(snake, 1.0, d.serpents._patina_mat(), seye)
	# Fresque de l'histoire
	var lore := Label3D.new()
	lore.text = "« Ici les Anciens ont enchaîné Nâga, le Serpent des Abysses.\nTrois gardiens, trois yeux, une amulette :\nque nul ne les réunisse jamais. »"
	lore.font_size = 40
	lore.pixel_size = 0.003
	lore.modulate = Color(0.86, 0.78, 0.6)
	lore.outline_size = 0
	lore.position = Vector3(LAKE_X0 + 0.05, y + 2.6, -143.0)
	lore.rotation.y = PI * 0.5
	s.add_child(lore)
	# La Pierre de l'Œil
	d._box(s, Vector3(1.0, 1.1, 1.0), Vector3(-1.0, y + 0.55, -144.0), d._mat("mur"))
	_mesh(s, _cyl(0.3, 0.3, 0.06, 24), d._mat("noir"), Vector3(-1.0, y + 1.12, -144.0))
	d._interactions.append({"id": "pierre_oeil", "pos": s.to_global(Vector3(-1.0, y, -144.0)), "radius": 1.8,
		"text": "E : poser l'amulette sur la pierre", "vr": "Gâchette : poser l'amulette", "call": _wake,
		"when": func(): return not bool(d.state["abime_eveil"])})
	d._interactions.append({"id": "porte_abime", "pos": s.to_global(Vector3(-1.0, y, -149.6)), "radius": 2.6,
		"text": "E : examiner la Porte de l'Abîme", "vr": "Gâchette : examiner la porte",
		"call": func(): d._say("La Porte de l'Abîme, en pierre noire. Une lueur verte la protège. Derrière, quelque chose d'immense respire… (Le combat final, à l'étape suivante !)", 6.0)})
	# Le coffre des Abysses
	_chest = Node3D.new()
	_chest.name = "Coffre_abysses"
	s.add_child(_chest)
	_chest.position = Vector3(8.5, y, -140.0)
	_chest.rotation.y = -PI * 0.5
	d._box(_chest, Vector3(1.1, 0.6, 0.7), Vector3(0, 0.3, 0), _obsidian(), false)
	for x in [-0.4, 0.4]:
		d._box(_chest, Vector3(0.06, 0.62, 0.72), Vector3(x, 0.3, 0), d._mat("bronze"), false)
	var hinge := Node3D.new()
	hinge.name = "Charniere"
	hinge.position = Vector3(0, 0.6, -0.35)
	_chest.add_child(hinge)
	d._box(hinge, Vector3(1.1, 0.2, 0.7), Vector3(0, 0.1, 0.35), _obsidian(), false)
	d._interactions.append({"id": "coffre_abysses", "pos": s.to_global(Vector3(8.5, y, -140.0)), "radius": 2.0,
		"text": "E : ouvrir le coffre des Abysses", "vr": "Gâchette : ouvrir le coffre", "call": _open_chest,
		"when": func(): return not bool(d.state["coffre_abysses"])})
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.55, 0.85, 0.7)
	fill.light_energy = 0.9
	fill.omni_range = 18.0
	fill.omni_attenuation = 0.6
	fill.light_specular = 0.2
	fill.position = Vector3(-1.0, y + 7.0, -143.0)
	s.add_child(fill)
	for p in [[Vector3(LAKE_X0 + 0.3, y + 0.3, -147.0), Vector3(1, 0, 0)], [Vector3(LAKE_X1 - 0.3, y + 0.3, -146.0), Vector3(-1, 0, 0)], [Vector3(6.0, y + 0.1, -151.6), Vector3(0, 0, 1)]]:
		_crystals(s, p[0], p[1], 3980 + int(p[0].x), 1.8)


func _open_chest() -> void:
	d.state["coffre_abysses"] = true
	var hinge: Node3D = _chest.get_node("Charniere")
	create_tween().tween_property(hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var a: int = main.inventory_v28.add("piece", 80)
	var r: int = main.inventory_v28.add("rubis", 2)
	var p: int = main.inventory_v28.add("perle", 3)
	d._say("Le coffre des Abysses : %d pièces, %d rubis et %d perles noires comme l'eau du lac." % [a, r, p], 5.0)
	if main.combat_v28 != null:
		main.combat_v28.puff(_chest.global_position + Vector3.UP * 0.8, Color(0.5, 1.0, 0.7))


func _wake() -> void:
	if main.inventory_v28.count("amulette_serpent") <= 0:
		d._say("Une pierre noire, creusée d'une empreinte ronde… de la taille d'une amulette.", 4.0)
		return
	d._busy = true
	d.state["abime_eveil"] = true
	d._say("Tu poses l'amulette sur la pierre. Les yeux des serpents s'allument un à un…", 4.0)
	var tw := create_tween()
	for e in _statue_eyes:
		tw.tween_property(e, "emission_energy_multiplier", 6.0, 0.8)
	await tw.finished
	if main.combat_v28 != null:
		main.combat_v28.puff(_barrier.global_position, Color(0.4, 1.0, 0.6))
	await get_tree().create_timer(0.8).timeout
	d._busy = false
	d._say("Un grondement monte des profondeurs. Derrière la Porte de l'Abîme, NÂGA, LE SERPENT DES ABYSSES, ouvre les yeux… Tu reprends l'amulette. (Le combat final, à l'étape suivante !)", 8.0)


# =================================================================== chaque image : dalles, eau, chutes

func _process(delta: float) -> void:
	if d == null or main == null or not main.game_started or not bool(d.inside):
		return
	_clock += delta
	if _barrier_mat != null:
		var base_a: float = 0.32 if bool(d.state["abime_eveil"]) else 0.16
		_barrier_mat.albedo_color.a = base_a + sin(_clock * 2.2) * 0.05
	var s: Node3D = d.sections.get("village")
	if s == null:
		return
	var p: Vector3 = s.to_local(main._player_pos_v27())
	# Fond du puits atteint
	if not bool(d.state["abysses_bas"]) and p.y < BOTTOM_Y + 1.0 and absf(p.x - SHAFT_C.x) < 8.0 and absf(p.z - SHAFT_C.z) < 7.5:
		d.state["abysses_bas"] = true
		d._say("Le fond du puits. Au nord, une caverne s'ouvre sur une eau noire et immobile. (La chaîne permet de remonter d'un coup.)", 5.0)
	# Le bassin amortit les chutes
	var in_pool: bool = Vector2(p.x - SHAFT_C.x, p.z - SHAFT_C.z).length() < POOL_R + 0.3 and p.y < BOTTOM_Y + 6.0
	if in_pool and main.hero_v28 != null and not main.xr_active:
		main.hero_v28.fall_top = main.pc_body.position.y
		if not _in_pool and p.y > BOTTOM_Y + 2.0:
			d._say("Plouf ! L'eau noire du bassin amortit ta chute.", 3.0)
	_in_pool = in_pool
	if _respawning:
		return
	var on_lake: bool = p.x > LAKE_X0 and p.x < LAKE_X1 and p.z < LAKE_Z1 and p.z > LAKE_Z0
	# Tombé à l'eau : on se retrouve sur la rive sud
	if on_lake and p.y < BOTTOM_Y - 0.9:
		_fall_in()
		return
	# Sur une dalle ?
	var stone: Dictionary = {}
	if on_lake and p.y > BOTTOM_Y - 0.6:
		for st in _stones:
			if bool(st["sunk"]):
				continue
			var n: Node3D = st["node"]
			if absf(p.x - n.position.x) < 0.55 and absf(p.z - n.position.z) < 0.55:
				stone = st
				break
	if not stone.is_empty() and str(stone["symbol"]) != ORDER[int(stone["row"]) % 4]:
		_on_wrong += delta
		if _on_wrong > 0.15:
			_sink(stone)
	else:
		_on_wrong = 0.0
		if not stone.is_empty():
			var gm: StandardMaterial3D = stone["glyph_mat"]
			if gm.emission_energy_multiplier < 0.5:
				gm.emission_energy_multiplier = 1.2
				create_tween().tween_property(gm, "emission_energy_multiplier", 0.0 if not bool(d.state["lac"]) else 1.2, 1.5)
	# Rive nord atteinte
	if not bool(d.state["lac"]) and p.z < LAKE_Z0 - 0.3 and p.z > -152.0 and absf(p.y - BOTTOM_Y) < 1.0 and p.x > LAKE_X0 and p.x < LAKE_X1:
		d.state["lac"] = true
		apply_state()
		d._say("Tu as traversé le Lac Noir ! Derrière toi, les fausses dalles s'enfoncent pour de bon : le chemin des Anciens reste tracé.", 6.0)


func _sink(st: Dictionary) -> void:
	_on_wrong = 0.0
	st["sunk"] = true
	var n: Node3D = st["node"]
	var body: StaticBody3D = st["body"]
	d._say("La dalle s'enfonce sous ton poids !", 2.5)
	var tw := create_tween()
	tw.tween_property(n, "position:y", BOTTOM_Y - 1.55 - 1.4, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.15).timeout
	body.collision_layer = 0


func _fall_in() -> void:
	_respawning = true
	var s: Node3D = d.sections["village"]
	if main.hero_v28 != null:
		main.hero_v28.fall_top = main.pc_body.position.y if not main.xr_active else 0.0
	d._say("Brrr ! L'eau noire est glaciale… Tu regagnes la rive sud à la nage.", 4.0)
	await d._travel(s.to_global(Vector3(SHAFT_C.x, BOTTOM_Y + 0.05, -115.5)), s.to_global(Vector3(0, 0, -1)) - s.to_global(Vector3.ZERO))
	# Les fausses dalles remontent (sauf si le chemin est déjà tracé).
	if not bool(d.state["lac"]):
		for st in _stones:
			if bool(st["sunk"]):
				st["sunk"] = false
				(st["body"] as StaticBody3D).collision_layer = 1
				create_tween().tween_property(st["node"], "position:y", BOTTOM_Y - 1.55, 1.2).set_trans(Tween.TRANS_SINE)
	_respawning = false

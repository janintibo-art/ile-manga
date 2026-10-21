extends Node3D
## V54 : Ventaile, l'aigle géant des cendres (un aigle royal de 9 m d'envergure).
##  - Le modèle est construit ici : corps et tête en surfaces lissées (plumage en écailles,
##    nuque dorée), bec crochu, yeux d'ambre, ailes articulées (bras, avant-bras, main) portant
##    de vraies plumes (rémiges « en doigts » au bout des ailes, secondaires, couvertures),
##    queue en éventail, pattes emplumées et serres jaunes, selle de cuir quand il est apprivoisé.
##  - Animation procédurale : posé (ailes repliées, regards), envol, battements, vol plané
##    (inclinaison dans les virages), atterrissage, et la pose « enchaîné » au nid.
##  - Le vol : vitesse de croisière, virages, montée et descente ; il évite le sol, la mer, les
##    falaises et reste dans le monde. L'atterrissage cherche un sol ferme sous lui.
## Repère : l'avant est -Z, le haut +Y. L'origine est au sol, entre les pattes.

signal landed

const TEX := "res://assets/textures/aigle/"
const CRUISE: float = 17.0
const FAST: float = 30.0
const SLOW: float = 8.0
const CLIMB: float = 9.0
const TURN_RATE: float = 0.95
const WORLD_R: float = 760.0
const ALT_MAX: float = 290.0
const SEAT := Vector3(0.0, 2.08, 0.02)       # selle (repère du modèle), pieds du cavalier
const SCALE: float = 1.3                      # Ventaile : 12 m d'envergure, 4,5 m du bec à la queue

var main: Node
var state: String = "cache"           # cache, chaine, perche, envol, vol, atterrit, arrive
var speed: float = 0.0
var yaw: float = 0.0
var vspeed: float = 0.0
var tamed: bool = false
var obstacle_clock: float = 0.0
var last_warn: String = ""

var _model: Node3D
var _body: Node3D
var _head: Node3D
var _neck: Node3D
var _wings: Array = []                 # {root, elbow, wrist, side, prim:[], sec:[]}
var _tail: Node3D
var _tail_feathers: Array = []
var _legs: Array = []
var _saddle: Node3D
var _mats: Dictionary = {}
var _clock: float = 0.0
var _flap_phase: float = 0.0
var _flap_amp: float = 0.0
var _fold: float = 1.0
var _tuck: float = 0.0
var _tail_open: float = 0.0
var _bank: float = 0.0
var _pitch: float = 0.0
var _look: Vector2 = Vector2.ZERO
var _look_goal: Vector2 = Vector2.ZERO
var _look_clock: float = 2.0
var _path: Array = []                  # arrivée : [départ, contrôle, arrivée]
var _path_t: float = 0.0
var _path_len: float = 1.0
var _land_from: Vector3
var _land_to: Vector3
var _land_t: float = 0.0
var _land_yaw0: float = 0.0
var _land_yaw1: float = 0.0
var _takeoff_t: float = 0.0
var _turn_in: float = 0.0
var _lift_in: float = 0.0
var _gust: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Ventaile_v54"
	_model = Node3D.new()
	_model.name = "Modele"
	_model.scale = Vector3.ONE * SCALE
	add_child(_model)
	_build()
	visible = false


# =================================================================== matériaux

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	match key:
		"plumage":
			m.albedo_texture = load(TEX + "plumage.png")
			m.normal_enabled = true
			m.normal_texture = load(TEX + "plumage_n.png")
			m.normal_scale = 0.9
			m.albedo_color = Color(1.45, 1.28, 1.1)
			m.roughness = 0.84
			m.metallic_specular = 0.3
			m.uv1_scale = Vector3(3.0, 5.0, 1.0)
		"aile":
			m.albedo_texture = load(TEX + "plumage.png")
			m.albedo_color = Color(1.35, 1.18, 0.98)
			m.normal_enabled = true
			m.normal_texture = load(TEX + "plumage_n.png")
			m.roughness = 0.88
			m.metallic_specular = 0.2
			m.uv1_scale = Vector3(2.0, 2.0, 1.0)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.disable_receive_shadows = true
		"tete":
			m.albedo_texture = load(TEX + "tete.png")
			m.albedo_color = Color(1.25, 1.05, 0.75)
			m.roughness = 0.82
			m.uv1_scale = Vector3(2.0, 1.0, 1.0)
		"visage":
			m.albedo_texture = load(TEX + "tete.png")
			m.albedo_color = Color(0.82, 0.64, 0.44)
			m.roughness = 0.82
			m.uv1_scale = Vector3(2.0, 1.0, 1.0)
		"remige", "secondaire", "couverture", "rectrice", "couverture_claire":
			var file: String = {"remige": "remige.png", "secondaire": "rectrice.png", "couverture": "couverture.png",
				"couverture_claire": "couverture.png", "rectrice": "rectrice.png"}[key]
			m.albedo_texture = load(TEX + file)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.42
			m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.9
			m.metallic_specular = 0.12
			# Plumes fines et doubles faces : pas d'ombre portée sur elles-mêmes (acné d'ombre)
			m.disable_receive_shadows = true
			if key == "remige" or key == "rectrice":
				m.albedo_color = Color(1.4, 1.28, 1.15)
			if key == "secondaire":
				m.albedo_color = Color(0.8, 0.72, 0.62)
			elif key == "couverture_claire":
				m.albedo_color = Color(1.55, 1.3, 0.95)   # la barre fauve de l'aile
		"bec":
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.55
			m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		"oeil":
			m.albedo_color = Color(0.62, 0.36, 0.06)
			m.roughness = 0.05
			m.metallic_specular = 0.9
			m.emission_enabled = true
			m.emission = Color(0.25, 0.12, 0.0)
			m.emission_energy_multiplier = 0.4
		"pupille":
			m.albedo_color = Color(0.02, 0.02, 0.02)
			m.roughness = 0.05
		"sourcil":
			m.albedo_color = Color(0.2, 0.14, 0.09)
			m.roughness = 0.9
		"patte":
			m.albedo_color = Color(0.95, 0.74, 0.18)
			m.roughness = 0.55
		"serre":
			m.albedo_color = Color(0.06, 0.05, 0.05)
			m.roughness = 0.25
		"cuir":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.albedo_color = Color(0.55, 0.3, 0.16)
			m.roughness = 0.62
		"cuir_fonce":
			m.albedo_color = Color(0.26, 0.14, 0.07)
			m.roughness = 0.6
		"boucle":
			m.albedo_color = Color(0.85, 0.7, 0.35)
			m.metallic = 0.9
			m.roughness = 0.3
	_mats[key] = m
	return m


# =================================================================== formes

## Surface lissée le long d'un chemin : anneaux [centre, rayon x, rayon y], fermée aux bouts.
## Les anneaux sont perpendiculaires au chemin. colors : couleur par anneau (ou vide).
func _loft(rings: Array, segs: int, uv_v: float = 1.0, colors: Array = [], cap: bool = true) -> ArrayMesh:
	var n: int = rings.size()
	var pts: Array = []
	var nrm: Array = []
	for i in range(n):
		var c: Vector3 = rings[i][0]
		var prev: Vector3 = rings[maxi(i - 1, 0)][0]
		var next: Vector3 = rings[mini(i + 1, n - 1)][0]
		var t: Vector3 = (next - prev).normalized()
		var side: Vector3 = Vector3.UP.cross(t)
		if side.length() < 0.01:
			side = Vector3.RIGHT
		side = side.normalized()
		var up: Vector3 = t.cross(side).normalized()
		var ring_p: Array = []
		var ring_n: Array = []
		for j in range(segs + 1):
			var a: float = TAU * float(j) / segs
			var rx: float = float(rings[i][1])
			var ry: float = float(rings[i][2])
			ring_p.append(c + side * cos(a) * rx + up * sin(a) * ry)
			ring_n.append((side * cos(a) / maxf(rx, 0.001) + up * sin(a) / maxf(ry, 0.001)).normalized())
		pts.append(ring_p)
		nrm.append(ring_n)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Sens des triangles : on teste le premier quadrilatère (face visible : (v1-v0)x(v2-v0) = -normale).
	var p00: Vector3 = pts[0][0]
	var p10: Vector3 = pts[1][0]
	var p01: Vector3 = pts[0][1]
	var flip: bool = (p10 - p00).cross(p01 - p00).dot(nrm[0][0] + nrm[1][0]) > 0.0
	for i in range(n - 1):
		for j in range(segs):
			var q := [[i, j], [i + 1, j], [i, j + 1], [i + 1, j + 1]]
			var tris: Array = [[q[0], q[1], q[2]], [q[1], q[3], q[2]]]
			for tri in tris:
				var order: Array = tri if not flip else [tri[0], tri[2], tri[1]]
				for v in order:
					var ii: int = v[0]
					var jj: int = v[1]
					st.set_normal(nrm[ii][jj])
					st.set_uv(Vector2(float(jj) / segs, float(ii) / (n - 1) * uv_v))
					if not colors.is_empty():
						st.set_color(colors[ii])
					st.add_vertex(pts[ii][jj])
	if cap:
		for end in [0, n - 1]:
			var c2: Vector3 = rings[end][0]
			var dir: Vector3 = (rings[end][0] - rings[1 if end == 0 else n - 2][0]).normalized()
			for j in range(segs):
				var a1: Vector3 = pts[end][j]
				var a2: Vector3 = pts[end][j + 1]
				var tri2: Array = [c2, a1, a2]
				if (a1 - c2).cross(a2 - c2).dot(dir) > 0.0:
					tri2 = [c2, a2, a1]
				for v2 in tri2:
					st.set_normal(dir)
					st.set_uv(Vector2(0.5, 0.0 if end == 0 else uv_v))
					if not colors.is_empty():
						st.set_color(colors[end])
					st.add_vertex(v2)
	return st.commit()


## Une plume : bande légèrement cambrée, de la base (origine) à la pointe (+Z).
static func feather_mesh(w: float, l: float, droop: float, segs: int = 4) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in range(segs):
		var t0: float = float(s) / segs
		var t1: float = float(s + 1) / segs
		var y0: float = -droop * t0 * t0 * l
		var y1: float = -droop * t1 * t1 * l
		var a := Vector3(-w * 0.5, y0, t0 * l)
		var b := Vector3(w * 0.5, y0, t0 * l)
		var c := Vector3(-w * 0.5, y1, t1 * l)
		var d := Vector3(w * 0.5, y1, t1 * l)
		var ua := Vector2(0.0, 1.0 - t0)
		var ub := Vector2(1.0, 1.0 - t0)
		var uc := Vector2(0.0, 1.0 - t1)
		var ud := Vector2(1.0, 1.0 - t1)
		for v in [[a, ua], [c, uc], [b, ub], [b, ub], [c, uc], [d, ud]]:
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	return st.commit()


func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = 16
	s.rings = 10
	return s


# =================================================================== construction

func _build() -> void:
	_body = Node3D.new()
	_body.name = "Corps"
	_body.position = Vector3(0, 1.42, 0)
	_model.add_child(_body)
	# Le tronc, en goutte : large poitrail, dos plat, effilé vers la queue
	var torso: Array = [
		[Vector3(0, 0.04, 1.4), 0.12, 0.08], [Vector3(0, 0.03, 1.2), 0.24, 0.17],
		[Vector3(0, 0.0, 0.92), 0.38, 0.32], [Vector3(0, -0.02, 0.55), 0.5, 0.45],
		[Vector3(0, 0.0, 0.15), 0.56, 0.52], [Vector3(0, 0.04, -0.2), 0.57, 0.55],
		[Vector3(0, 0.12, -0.5), 0.5, 0.5], [Vector3(0, 0.27, -0.74), 0.38, 0.4],
		[Vector3(0, 0.42, -0.88), 0.3, 0.31],
	]
	_mi(_body, _loft(torso, 24, 1.0, [], true), _mat("plumage"))
	# Cou et tête : brune devant, nuque dorée (aigle royal)
	_neck = Node3D.new()
	_neck.name = "Cou"
	_neck.position = Vector3(0, 0.4, -0.84)
	_body.add_child(_neck)
	var neck_r: Array = [
		[Vector3(0, -0.06, 0.14), 0.32, 0.33], [Vector3(0, 0.06, -0.04), 0.27, 0.28],
		[Vector3(0, 0.16, -0.18), 0.23, 0.24],
	]
	_mi(_neck, _loft(neck_r, 18, 1.0, [], true), _mat("tete"))
	_head = Node3D.new()
	_head.name = "Tete"
	_head.position = Vector3(0, 0.2, -0.22)
	_neck.add_child(_head)
	var head_r: Array = [
		[Vector3(0, 0.0, 0.06), 0.2, 0.2], [Vector3(0, 0.03, -0.08), 0.21, 0.2],
		[Vector3(0, 0.04, -0.22), 0.19, 0.17], [Vector3(0, 0.01, -0.34), 0.14, 0.13],
		[Vector3(0, -0.02, -0.41), 0.1, 0.1],
	]
	_mi(_head, _loft(head_r, 18, 1.0, [], true), _mat("visage"))
	# Bec crochu : cire jaune à la base, corne gris-noir à la pointe
	var beak_path: Array = [
		[Vector3(0, -0.02, -0.38), 0.085, 0.09], [Vector3(0, -0.01, -0.47), 0.07, 0.085],
		[Vector3(0, -0.02, -0.55), 0.056, 0.07], [Vector3(0, -0.045, -0.62), 0.042, 0.054],
		[Vector3(0, -0.085, -0.665), 0.027, 0.037], [Vector3(0, -0.13, -0.67), 0.013, 0.018],
		[Vector3(0, -0.165, -0.65), 0.003, 0.005],
	]
	var beak_c: Array = [Color(0.96, 0.74, 0.18), Color(0.9, 0.68, 0.18), Color(0.3, 0.29, 0.27), Color(0.2, 0.19, 0.18),
		Color(0.13, 0.12, 0.12), Color(0.08, 0.08, 0.08), Color(0.06, 0.06, 0.06)]
	_mi(_head, _loft(beak_path, 14, 1.0, beak_c, true), _mat("bec"))
	var jaw: Array = [[Vector3(0, -0.07, -0.39), 0.06, 0.045], [Vector3(0, -0.085, -0.51), 0.042, 0.03], [Vector3(0, -0.095, -0.59), 0.018, 0.013]]
	_mi(_head, _loft(jaw, 10, 1.0, [Color(0.85, 0.66, 0.2), Color(0.3, 0.29, 0.27), Color(0.12, 0.12, 0.12)], true), _mat("bec"))
	for sx in [-1.0, 1.0]:
		var eye := _mi(_head, _sphere(0.042), _mat("oeil"), Vector3(sx * 0.14, 0.06, -0.25))
		_mi(eye, _sphere(0.022), _mat("pupille"), Vector3(sx * 0.024, 0.0, -0.01))
		# Arcade sourcilière : le regard sévère de l'aigle
		_mi(_head, _sphere(0.06), _mat("sourcil"), Vector3(sx * 0.125, 0.11, -0.26), Vector3(0, 0, sx * 0.3), Vector3(1.0, 0.42, 1.6))
	# Ailes
	for side in [-1.0, 1.0]:
		_build_wing(side)
	# Queue en éventail
	_tail = Node3D.new()
	_tail.name = "Queue"
	_tail.position = Vector3(0, 0.03, 1.28)
	_body.add_child(_tail)
	var rect: ArrayMesh = feather_mesh(0.26, 1.2, 0.06)
	for k in range(12):
		var f := _mi(_tail, rect, _mat("rectrice"), Vector3((k - 5.5) * 0.03, 0.003 * absf(k - 5.5), 0.0))
		f.set_meta("k", k)
		_tail_feathers.append(f)
	var cov_t: ArrayMesh = feather_mesh(0.22, 0.5, 0.04)
	for k in range(7):
		_mi(_tail, cov_t, _mat("couverture"), Vector3((k - 3) * 0.05, 0.05, -0.18), Vector3(0, (k - 3) * 0.1, 0))
	# Pattes emplumées (« culottes ») et serres jaunes
	for sx in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.name = "Hanche"
		hip.position = Vector3(sx * 0.25, -0.28, 0.22)
		_body.add_child(hip)
		var thigh: Array = [[Vector3(0, 0.12, 0.0), 0.26, 0.28], [Vector3(0, -0.22, 0.03), 0.25, 0.26],
			[Vector3(0, -0.5, 0.02), 0.17, 0.18], [Vector3(0, -0.78, 0.0), 0.11, 0.11], [Vector3(0, -0.95, -0.02), 0.085, 0.085]]
		_mi(hip, _loft(thigh, 14, 1.0, [], true), _mat("plumage"))
		var foot := Node3D.new()
		foot.name = "Pied"
		foot.position = Vector3(0, -1.0, -0.03)
		hip.add_child(foot)
		for t in range(4):
			var toe := Node3D.new()
			toe.rotation.y = [0.0, 0.45, -0.45, PI][t]
			foot.add_child(toe)
			var toe_len: float = 0.3 if t < 3 else 0.2
			_mi(toe, _loft([[Vector3(0, 0.02, 0.02), 0.06, 0.05], [Vector3(0, -0.01, -toe_len * 0.5), 0.05, 0.042], [Vector3(0, -0.03, -toe_len), 0.04, 0.035]], 8, 1.0, [], true), _mat("patte"))
			_mi(toe, _loft([[Vector3(0, -0.02, -toe_len), 0.03, 0.032], [Vector3(0, -0.035, -toe_len - 0.07), 0.018, 0.02], [Vector3(0, -0.075, -toe_len - 0.11), 0.002, 0.003]], 6, 1.0, [], true), _mat("serre"))
		_legs.append(hip)
	# La selle (visible quand Ventaile est apprivoisée)
	_saddle = Node3D.new()
	_saddle.name = "Selle"
	_saddle.position = Vector3(0, 0.53, -0.05)
	_body.add_child(_saddle)
	_mi(_saddle, _loft([[Vector3(0, 0.0, 0.42), 0.34, 0.05], [Vector3(0, 0.03, 0.0), 0.4, 0.08], [Vector3(0, 0.02, -0.38), 0.32, 0.06]], 16, 1.0, [], true), _mat("cuir"))
	_mi(_saddle, _sphere(0.09), _mat("cuir_fonce"), Vector3(0, 0.1, -0.34), Vector3.ZERO, Vector3(1.3, 1.2, 0.8))
	_mi(_saddle, _sphere(0.12), _mat("cuir_fonce"), Vector3(0, 0.09, 0.36), Vector3.ZERO, Vector3(1.6, 0.7, 0.6))
	for z in [-0.18, 0.22]:
		var strap := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.575
		tm.outer_radius = 0.62
		tm.rings = 28
		tm.ring_segments = 4
		strap.mesh = tm
		strap.material_override = _mat("cuir_fonce")
		strap.rotation.x = PI * 0.5
		strap.position = Vector3(0, -0.5, z)
		strap.scale = Vector3(1.0, 1.0, 0.96)
		_saddle.add_child(strap)
	_saddle.visible = false
	set_folded_instant()


## Une aile : épaule -> coude -> poignet, avec ses plumes. side = 1 : aile droite (+X).
## L'aile gauche est construite en miroir (positions et angles inversés, sans échelle négative).
func _build_wing(side: float) -> void:
	var root := Node3D.new()
	root.name = "Aile_d" if side > 0 else "Aile_g"
	root.position = Vector3(side * 0.4, 0.4, -0.32)
	_body.add_child(root)
	var panels: Array = []
	panels.append(_mi(root, _wing_panel(1.05, 0.66, 0.05, 0.02, side), _mat("aile"), Vector3(0, 0, -0.1)))
	var elbow := Node3D.new()
	elbow.name = "Coude"
	elbow.position = Vector3(side * 1.0, 0, 0)
	root.add_child(elbow)
	panels.append(_mi(elbow, _wing_panel(1.35, 0.6, 0.0, 0.02, side), _mat("aile"), Vector3(0, 0, -0.15)))
	var wrist := Node3D.new()
	wrist.name = "Poignet"
	wrist.position = Vector3(side * 1.32, 0, 0)
	elbow.add_child(wrist)
	panels.append(_mi(wrist, _wing_panel(0.85, 0.4, 0.0, 0.015, side), _mat("aile"), Vector3(0, 0, -0.14)))
	var info := {"root": root, "elbow": elbow, "wrist": wrist, "side": side, "prim": [], "feathers": [], "panels": panels}
	# Secondaires : larges, à bout arrondi, le long du bras et de l'avant-bras, vers l'arrière
	var sec_mesh: ArrayMesh = feather_mesh(0.34, 1.42, 0.05)
	for k in range(15):
		var t: float = float(k) / 14.0
		var on_arm: bool = k < 4
		var parent: Node3D = root if on_arm else elbow
		var x: float = lerpf(0.25, 0.95, float(k) / 3.0) if on_arm else lerpf(0.0, 1.3, float(k - 4) / 10.0)
		var f := _mi(parent, sec_mesh, _mat("secondaire"), Vector3(side * x, -0.01 - 0.003 * k, 0.34), Vector3(0, side * (-0.05 + t * 0.12), 0))
		f.set_meta("open_yaw", f.rotation.y)
		info["feathers"].append(f)
	# Rémiges primaires : en éventail sur la main, les plus longues au bout (les « doigts »)
	for k in range(10):
		var t2: float = float(k) / 9.0
		var length: float = lerpf(1.4, 2.0, sqrt(t2)) - (0.2 if k == 9 else 0.0)
		var pm: ArrayMesh = feather_mesh(lerpf(0.36, 0.3, t2), length, 0.05 + 0.04 * t2)
		var f2 := _mi(wrist, pm, _mat("remige"), Vector3(side * lerpf(0.0, 0.82, t2), -0.012 * k, lerpf(0.28, 0.05, t2)))
		f2.set_meta("base_yaw", side * lerpf(0.05, 1.32, pow(t2, 1.15)))
		f2.set_meta("open_yaw", float(f2.get_meta("base_yaw")))
		f2.rotation.y = float(f2.get_meta("base_yaw"))
		info["prim"].append(f2)
	# Couvertures : deux rangées sur le dessus (la barre fauve sur la rangée moyenne)
	var cov_mesh: ArrayMesh = feather_mesh(0.3, 0.66, 0.04)
	var cov2: ArrayMesh = feather_mesh(0.26, 0.44, 0.03)
	for k in range(16):
		var t3: float = float(k) / 15.0
		var x3: float = t3 * 3.0
		var parent3: Node3D = root if x3 < 1.0 else (elbow if x3 < 2.3 else wrist)
		var lx: float = x3 if parent3 == root else (x3 - 1.0 if parent3 == elbow else x3 - 2.3)
		var c1 := _mi(parent3, cov_mesh, _mat("couverture_claire" if k % 2 == 0 else "couverture"), Vector3(side * lx, 0.035, 0.14), Vector3(0, side * 0.15 * t3, 0))
		c1.set_meta("open_yaw", c1.rotation.y)
		info["feathers"].append(c1)
		var c2 := _mi(parent3, cov2, _mat("couverture"), Vector3(side * (lx + 0.05), 0.06, -0.04), Vector3(0, side * 0.1 * t3, 0))
		c2.set_meta("open_yaw", c2.rotation.y)
		info["feathers"].append(c2)
	# L'aile repliée (posée) : une cape de plumes plaquée sur le flanc, les rémiges croisées
	# au-dessus de la queue. Elle remplace l'aile articulée quand Ventaile est au repos.
	var folded := Node3D.new()
	folded.name = "Aile_repliee_d" if side > 0 else "Aile_repliee_g"
	_body.add_child(folded)
	_mi(folded, _cloak(side), _mat("aile"))
	var tip: ArrayMesh = feather_mesh(0.3, 1.55, 0.02)
	for k in range(6):
		var fz: float = 0.55 + k * 0.06
		var fy: float = 0.2 - k * 0.07
		var fe := _mi(folded, tip, _mat("remige"), Vector3(side * (_flank(fz) + 0.03 + 0.012 * k), fy, fz),
			Vector3(0.12 + 0.02 * k, side * -(0.14 + 0.012 * k), side * -1.25))
		fe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var sec_tip: ArrayMesh = feather_mesh(0.32, 0.8, 0.02)
	for k in range(5):
		_mi(folded, sec_tip, _mat("secondaire"), Vector3(side * (_flank(0.35 + k * 0.1) + 0.02), -0.18 + k * 0.03, 0.35 + k * 0.1),
			Vector3(0.25, side * -0.1, side * -1.35))
	info["folded"] = folded
	_wings.append(info)


## Demi-largeur du tronc à la profondeur z (pour plaquer l'aile repliée sur le flanc).
func _flank(z: float) -> float:
	var zs: Array = [-0.88, -0.74, -0.5, -0.2, 0.15, 0.55, 0.92, 1.2, 1.4]
	var rs: Array = [0.3, 0.38, 0.5, 0.57, 0.56, 0.5, 0.38, 0.24, 0.12]
	if z <= zs[0]:
		return rs[0]
	for i in range(zs.size() - 1):
		if z <= zs[i + 1]:
			return lerpf(rs[i], rs[i + 1], (z - zs[i]) / (zs[i + 1] - zs[i]))
	return rs[-1]


## La cape de l'aile repliée : nappe bombée sur le flanc, de l'épaule à la base de la queue.
func _cloak(side: float) -> ArrayMesh:
	var nu: int = 10
	var nv: int = 6
	var grid: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / nu
		var z: float = lerpf(-0.62, 1.18, u)
		var top: float = lerpf(0.42, 0.22, u * u)
		var bot: float = lerpf(-0.18, 0.02, pow(u, 1.5)) - 0.2 * sin(u * PI) * 0.6
		var row: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / nv
			var y: float = lerpf(top, bot, v)
			var bulge: float = 0.06 * sin(v * PI) * sin(clampf(u, 0.05, 0.95) * PI)
			row.append(Vector3(side * (_flank(z) + 0.035 + bulge - 0.05 * v * v), y, z))
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(nu):
		for j in range(nv):
			var a: Vector3 = grid[i][j]
			var b: Vector3 = grid[i + 1][j]
			var c: Vector3 = grid[i][j + 1]
			var d: Vector3 = grid[i + 1][j + 1]
			var n: Vector3 = (b - a).cross(c - a).normalized()
			if n.x * side < 0.0:
				n = -n
			var tri: Array = [a, b, c, b, d, c]
			if (b - a).cross(c - a).dot(n) > 0.0:
				tri = [a, c, b, b, c, d]
			for p in tri:
				st.set_normal(n)
				st.set_uv(Vector2(p.z * 0.8, p.y * 0.8))
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Panneau d'aile (dessus et dessous) : plaque arrondie de longueur l (le long de +X), corde c.
func _wing_panel(l: float, chord: float, taper: float, thick: float, side: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 6
	var nz: int = 4
	var grid: Array = []
	for i in range(nx + 1):
		var x: float = l * float(i) / nx
		var c: float = chord * (1.0 - taper * float(i) / nx)
		var row: Array = []
		for j in range(nz + 1):
			var v: float = float(j) / nz
			var z: float = -0.12 + v * c
			# profil : bord d'attaque épais et arrondi, bord de fuite fin
			var y: float = thick * 4.0 * sin(PI * clampf(1.0 - v, 0.0, 1.0) * 0.5)
			row.append(Vector3(x * side, y, z))
		grid.append(row)
	for top in [true, false]:
		for i in range(nx):
			for j in range(nz):
				var a: Vector3 = grid[i][j]
				var b: Vector3 = grid[i + 1][j]
				var c2: Vector3 = grid[i][j + 1]
				var d: Vector3 = grid[i + 1][j + 1]
				var off := Vector3(0, 0 if top else -thick * 0.8, 0)
				var n := Vector3.UP if top else Vector3.DOWN
				var quad: Array = [a, c2, b, b, c2, d] if top == (side > 0.0) else [a, b, c2, b, d, c2]
				for p in quad:
					var pp: Vector3 = p + off
					st.set_normal(n)
					st.set_uv(Vector2(absf(pp.x) / 1.5, pp.z / 1.5))
					st.add_vertex(pp)
	return st.commit()


# =================================================================== poses

func set_folded_instant() -> void:
	_fold = 1.0
	_tuck = 0.0
	_flap_amp = 0.0
	_tail_open = 0.0
	_apply_pose()


func show_saddle(on: bool) -> void:
	tamed = on
	_saddle.visible = on


## Où s'assied le cavalier (repère du monde) : pieds sur la selle, regard vers l'avant.
func seat_transform() -> Transform3D:
	var b: Transform3D = _body.global_transform
	var at: Vector3 = b * Vector3(0, 0.62, -0.05)
	var t: Transform3D = _model.global_transform
	return Transform3D(t.basis.orthonormalized(), at)


func _apply_pose() -> void:
	var flap: float = sin(_flap_phase) * _flap_amp
	var lag: float = sin(_flap_phase - 0.9) * _flap_amp
	var f: float = smoothstep(0.0, 1.0, _fold)
	# Posé : le corps se redresse (poitrail haut, queue basse) ; en vol il est à l'horizontale
	var posture: float = 0.5 * (1.0 - _tuck)
	_body.position.y = lerpf(1.32, 1.42, _tuck)
	_body.rotation = Vector3(_pitch + posture, 0.0, _bank)
	for w in _wings:
		var root: Node3D = w["root"]
		var elbow: Node3D = w["elbow"]
		var wrist: Node3D = w["wrist"]
		# Ailes ouvertes : légère dièdre, battement à l'épaule, retard au poignet
		var open_r := Vector3(0.0, -0.05, 0.1 + flap * 0.85)
		var open_e := Vector3(0.0, 0.12, -lag * 0.15)
		var open_w := Vector3(0.0, -0.22 + lag * 0.1, -lag * 0.35)
		# Ailes repliées : le bras part en arrière, l'avant-bras revient vers l'avant, la main
		# repart en arrière le long du flanc (pliage en Z), l'aile tombe sur le flanc
		var fold_r := Vector3(0.0, -1.25, -0.5)
		var fold_e := Vector3(0.0, 2.6, 0.0)
		var fold_w := Vector3(0.0, -2.55, 0.0)
		var sd: float = float(w["side"])
		var mir := Vector3(1.0, sd, sd)
		root.rotation = open_r.lerp(fold_r, f) * mir
		elbow.rotation = open_e.lerp(fold_e, f) * mir
		wrist.rotation = open_w.lerp(fold_w, f) * mir
		# Au repos, l'aile articulée laisse la place à l'aile repliée (plaquée sur le flanc)
		var show_folded: bool = f > 0.6
		(w["folded"] as Node3D).visible = show_folded
		root.visible = not show_folded
		for pnl in w["panels"]:
			(pnl as Node3D).scale = Vector3(1.0, 1.0, lerpf(1.0, 0.12, f))
		# Les « doigts » s'écartent en vol plané
		var spread: float = 1.0 - absf(flap) * 0.4
		var pr: Array = w["prim"]
		for k in range(pr.size()):
			var fe: MeshInstance3D = pr[k]
			fe.rotation.y = float(fe.get_meta("base_yaw")) * lerpf(0.75, 1.0, spread)
			fe.rotation.z = sd * ((k - 5) * 0.02 * spread - lag * 0.08 * float(k) / 9.0)
		# Repliée : chaque plume se couche vers l'arrière, le long du dos
		if f > 0.001:
			var back: Vector3 = _body.global_basis * Vector3(0.0, -0.12, 1.0)
			var all: Array = (w["feathers"] as Array) + pr
			for fe2 in all:
				var mi: MeshInstance3D = fe2
				var local: Vector3 = mi.get_parent().global_basis.inverse() * back
				var fold_yaw: float = atan2(local.x, local.z)
				mi.rotation.y = lerp_angle(float(mi.get_meta("open_yaw")) if not mi.has_meta("base_yaw") else mi.rotation.y, fold_yaw, f)
				if f > 0.5:
					mi.rotation.z = lerpf(mi.rotation.z, 0.0, f)
		else:
			for fe3 in w["feathers"]:
				(fe3 as Node3D).rotation.y = float(fe3.get_meta("open_yaw"))
	# Queue : éventail ouvert en vol, fermée posée ; elle sert de gouvernail dans les virages
	for f2 in _tail_feathers:
		var k2: int = int(f2.get_meta("k"))
		f2.rotation.y = (k2 - 5.5) * lerpf(0.02, 0.1, _tail_open) + _bank * 0.2
		f2.rotation.x = lerpf(0.0, -0.03, _tail_open)
	_tail.rotation.x = lerpf(0.05, -0.02, _tail_open) - _pitch * 0.3
	# Pattes : verticales posé (malgré le corps redressé), repliées vers l'arrière en vol
	for hip in _legs:
		(hip as Node3D).rotation.x = -posture + lerpf(0.0, 1.3, _tuck)
	# Tête : à l'horizontale malgré la posture, regards (posée), stabilisée en vol
	_neck.rotation = Vector3(-(_pitch + posture) * 0.85 + _look.y * 0.5 - 0.3 * _tuck, _look.x * 0.7, -_bank * 0.6)
	_head.rotation = Vector3(_look.y * 0.4, _look.x * 0.5, 0.0)


# =================================================================== comportement

## Posée au sol, en pos (sol), regard vers yaw_ang.
func perch_at(pos: Vector3, yaw_ang: float) -> void:
	global_position = pos
	yaw = yaw_ang
	rotation = Vector3(0, yaw, 0)
	speed = 0.0
	vspeed = 0.0
	_bank = 0.0
	_pitch = 0.0
	state = "perche"
	visible = true
	set_folded_instant()


func chain_at(pos: Vector3, yaw_ang: float) -> void:
	perch_at(pos, yaw_ang)
	state = "chaine"


## Appelée par le sifflet : elle arrive de loin, en planant, et se pose près de « to ».
func arrive_at(to: Vector3, from_dir: Vector3) -> void:
	var start: Vector3 = to + from_dir.normalized() * 140.0 + Vector3.UP * 70.0
	var ctrl: Vector3 = to + from_dir.normalized() * 40.0 + Vector3.UP * 30.0
	_path = [start, ctrl, to]
	_path_t = 0.0
	_path_len = start.distance_to(ctrl) + ctrl.distance_to(to)
	global_position = start
	state = "arrive"
	visible = true
	_fold = 0.0


func is_landed() -> bool:
	return state == "perche"


func flying() -> bool:
	return state in ["envol", "vol", "atterrit"]


func take_off() -> void:
	state = "envol"
	_takeoff_t = 0.0
	speed = 4.0
	vspeed = 0.0


## Le sol (ou la mer) sous un point : [hauteur, ferme ?]
func ground_below(p: Vector3) -> Array:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 400.0, 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return [-0.42, false]
	var y: float = hit.position.y
	if y < -0.2:
		return [-0.42, false]
	return [y, hit.normal.y > 0.55]


## Demande d'atterrissage : vrai si un sol ferme est assez proche dessous.
func request_land() -> String:
	if state != "vol":
		return "pas_en_vol"
	var g: Array = ground_below(global_position)
	if not bool(g[1]):
		return "eau"
	if global_position.y - float(g[0]) > 30.0:
		return "haut"
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	_land_from = global_position
	var spot: Vector3 = global_position + fwd * clampf(speed * 0.9, 4.0, 16.0)
	var g2: Array = ground_below(spot)
	if not bool(g2[1]):
		spot = global_position
		g2 = g
	spot.y = float(g2[0])
	_land_to = spot
	_land_t = 0.0
	_land_yaw0 = yaw
	_land_yaw1 = yaw
	state = "atterrit"
	return ""


func _physics_process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	match state:
		"chaine":
			_fold = move_toward(_fold, 0.65 + 0.12 * sin(_clock * 0.7), delta)
			_flap_amp = 0.0
			# Elle se débat de temps en temps : un coup d'aile, la tête qui tire sur la chaîne
			var fight: float = maxf(0.0, sin(_clock * 0.9)) ** 8.0
			_fold = lerpf(_fold, 0.15, fight)
			_flap_phase += delta * 9.0
			_flap_amp = fight * 0.6
			_look_goal = Vector2(sin(_clock * 0.37) * 0.7, -0.25 + 0.3 * fight)
		"perche":
			_fold = move_toward(_fold, 1.0, delta * 1.2)
			_flap_amp = move_toward(_flap_amp, 0.0, delta * 2.0)
			_tuck = move_toward(_tuck, 0.0, delta * 2.0)
			_tail_open = move_toward(_tail_open, 0.0, delta)
			_bank = move_toward(_bank, 0.0, delta)
			_pitch = move_toward(_pitch, 0.0, delta)
			_look_clock -= delta
			if _look_clock <= 0.0:
				_look_clock = randf_range(1.5, 4.5)
				_look_goal = Vector2(randf_range(-0.9, 0.9), randf_range(-0.25, 0.2))
		"arrive":
			_tick_arrive(delta)
		"envol":
			_tick_takeoff(delta)
		"vol":
			_tick_flight(delta)
		"atterrit":
			_tick_landing(delta)
	_look = _look.lerp(_look_goal, clampf(delta * 3.0, 0.0, 1.0))
	_apply_pose()


func _tick_arrive(delta: float) -> void:
	_path_t = minf(_path_t + delta * 26.0 / _path_len, 1.0)
	var t: float = _path_t
	var a: Vector3 = _path[0]
	var b: Vector3 = _path[1]
	var c: Vector3 = _path[2]
	var p: Vector3 = a.lerp(b, t).lerp(b.lerp(c, t), t)
	var tan: Vector3 = (b - a).lerp(c - b, t)
	if tan.length() > 0.01:
		var want: float = atan2(-tan.x, -tan.z)
		_bank = lerpf(_bank, clampf(angle_difference(yaw, want) * -3.0, -0.6, 0.6), delta * 2.0)
		yaw = want
	global_position = p
	rotation = Vector3(0, yaw, 0)
	_fold = move_toward(_fold, 0.0, delta * 2.0)
	_tuck = 1.0 if t < 0.85 else move_toward(_tuck, 0.0, delta * 3.0)
	_tail_open = 1.0
	_pitch = lerpf(_pitch, 0.25 if t > 0.8 else -0.08, delta * 2.0)
	# Elle plane, puis freine à grands battements avant de se poser
	if t > 0.82:
		_flap_amp = move_toward(_flap_amp, 0.75, delta * 3.0)
		_flap_phase += delta * 7.0
	else:
		_flap_amp = move_toward(_flap_amp, 0.05, delta)
		_flap_phase += delta * 2.0
	if _path_t >= 1.0:
		_settle()


func _tick_takeoff(delta: float) -> void:
	_takeoff_t += delta
	_fold = move_toward(_fold, 0.0, delta * 2.5)
	_flap_amp = move_toward(_flap_amp, 0.85, delta * 3.0)
	_flap_phase += delta * 7.5
	_tuck = move_toward(_tuck, 1.0, delta * 1.2)
	_tail_open = move_toward(_tail_open, 1.0, delta * 2.0)
	_pitch = lerpf(_pitch, -0.12, delta * 2.0)
	speed = move_toward(speed, CRUISE * 0.7, delta * 6.0)
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	global_position += fwd * speed * delta + Vector3.UP * lerpf(7.0, 2.0, clampf(_takeoff_t / 1.8, 0.0, 1.0)) * delta
	if _takeoff_t > 1.8:
		state = "vol"


## Un pas de vol. turn, lift, throttle dans -1..1 (entrées du cavalier).
func steer(turn: float, lift: float, throttle: float) -> void:
	_turn_in = clampf(turn, -1.0, 1.0)
	_lift_in = clampf(lift, -1.0, 1.0)
	_gust = clampf(throttle, -1.0, 1.0)


func _tick_flight(delta: float) -> void:
	var target_speed: float = CRUISE
	if _gust > 0.1:
		target_speed = lerpf(CRUISE, FAST, _gust)
	elif _gust < -0.1:
		target_speed = lerpf(CRUISE, SLOW, -_gust)
	speed = move_toward(speed, target_speed, delta * (5.0 if target_speed > speed else 7.0))
	var turn: float = _turn_in
	var p: Vector3 = global_position
	# Rester dans le monde : au bord, elle fait demi-tour d'elle-même
	var flat := Vector2(p.x, p.z)
	# V59 : le ciel s'étend jusqu'au-dessus de la grande île de l'est
	var east_d: float = flat.distance_to(Vector2(905.0, -150.0))
	if flat.length() > WORLD_R and east_d > 430.0:
		if east_d - 430.0 < flat.length() - WORLD_R:
			flat = flat - Vector2(905.0, -150.0)
		var home: float = atan2(flat.x, flat.y)        # cap vers le centre
		var diff: float = angle_difference(yaw, home)
		turn = clampf(-diff * 2.0, -1.0, 1.0)
		_warn("bord")
	yaw -= turn * TURN_RATE * delta * lerpf(1.1, 0.75, clampf((speed - SLOW) / (FAST - SLOW), 0.0, 1.0))
	var want_v: float = _lift_in * CLIMB
	if p.y > ALT_MAX and want_v > 0.0:
		want_v = 0.0
		_warn("haut")
	vspeed = move_toward(vspeed, want_v, delta * 10.0)
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var step: Vector3 = fwd * speed * delta + Vector3.UP * vspeed * delta
	# Obstacles devant (falaises, murs, tours) : écart et freinage
	var space := get_world_3d().direct_space_state
	var ahead: float = speed * 0.45 + 3.5
	var probe := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.4, p + Vector3.UP * 1.4 + fwd * ahead + Vector3.UP * vspeed * 0.3, 1)
	var hit := space.intersect_ray(probe)
	obstacle_clock = maxf(obstacle_clock - delta, 0.0)
	if not hit.is_empty():
		var n: Vector3 = hit.normal
		step = Vector3(n.x, 0, n.z).normalized() * 3.0 * delta + Vector3.UP * 6.0 * delta
		speed = maxf(speed * (1.0 - delta * 3.0), SLOW)
		yaw -= signf(fwd.cross(n).y + 0.001) * 1.6 * delta
		obstacle_clock = 0.6
		_warn("obstacle")
	p += step
	# Jamais sous le sol ni dans la mer
	var g: Array = ground_below(p)
	var floor_y: float = maxf(float(g[0]), -0.42) + 2.4
	if p.y < floor_y:
		p.y = move_toward(p.y, floor_y, delta * 14.0)
		vspeed = maxf(vspeed, 0.0)
	global_position = p
	rotation = Vector3(0, yaw, 0)
	# Allure : battements quand on monte ou accélère, sinon vol plané (quelques battements)
	var effort: float = clampf(maxf(_lift_in, 0.0) + maxf(_gust, 0.0) * 0.8 + (0.4 if speed < CRUISE - 2.0 else 0.0), 0.0, 1.0)
	var glide_flap: float = 0.08 + 0.12 * maxf(0.0, sin(_clock * 0.45)) ** 6.0
	_flap_amp = move_toward(_flap_amp, lerpf(glide_flap, 0.75, effort), delta * 1.5)
	_flap_phase += delta * lerpf(2.5, 7.0, effort)
	_fold = move_toward(_fold, 0.08 if _lift_in < -0.5 else 0.0, delta * 2.0)   # piqué : ailes un peu serrées
	_tuck = move_toward(_tuck, 1.0, delta)
	_tail_open = move_toward(_tail_open, 1.0, delta)
	_bank = lerpf(_bank, -turn * 0.55, clampf(delta * 2.5, 0.0, 1.0))
	_pitch = lerpf(_pitch, clampf(-vspeed / maxf(speed, 1.0) * 1.1, -0.45, 0.4), clampf(delta * 2.0, 0.0, 1.0))
	_look_goal = Vector2(turn * 0.35, 0.0)


func _tick_landing(delta: float) -> void:
	_land_t = minf(_land_t + delta / 2.2, 1.0)
	var t: float = smoothstep(0.0, 1.0, _land_t)
	var mid: Vector3 = _land_from.lerp(_land_to, 0.6) + Vector3.UP * 2.0
	var p: Vector3 = _land_from.lerp(mid, t).lerp(mid.lerp(_land_to, t), t)
	global_position = p
	rotation = Vector3(0, yaw, 0)
	_flap_amp = move_toward(_flap_amp, 0.8, delta * 3.0)
	_flap_phase += delta * 7.5
	_pitch = lerpf(_pitch, 0.35, delta * 3.0)
	_tuck = move_toward(_tuck, 0.0, delta * 1.5)
	_bank = lerpf(_bank, 0.0, delta * 3.0)
	if _land_t >= 1.0:
		_settle()


func _settle() -> void:
	state = "perche"
	speed = 0.0
	vspeed = 0.0
	_pitch = 0.0
	_bank = 0.0
	rotation = Vector3(0, yaw, 0)
	landed.emit()


func _warn(kind: String) -> void:
	if last_warn == kind and obstacle_clock > 0.2:
		return
	last_warn = kind

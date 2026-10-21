extends Node3D
## V60 : la Murène Noire, le galion des pirates, amarré au quai de Tazira.
## Un trois-mâts de 46 m à la coque noire et à la bande rouge sang, voiles noires carguées à
## moitié, pavillon à tête de mort au grand mât. Le pont se visite (les pirates y traînent) :
## le château arrière abrite la cabine du capitaine (une porte, des fenêtres de poupe), le
## gaillard d'avant porte la cloche ; huit canons, des tonneaux de rhum, des cordages.
## Repère du navire : x vers l'étrave, y vers le haut (quille à 0), z vers tribord.

const HL: float = 23.0
const HB: float = 6.2
const D: float = 6.5
const THICK: float = 0.22
const CASTLE_X: float = -13.0          # façade du château arrière
const QD_H: float = 2.5                # hauteur du château (et de la dunette)
const FC_X: float = 15.0               # le gaillard d'avant
const FC_H: float = 1.6
const MASTS := [[0.0, 24.0], [12.0, 20.0], [-16.5, 15.0]]     # x, hauteur au-dessus du pont

var xf := Transform3D()
var inv := Transform3D()
var body: StaticBody3D
var flag_nodes: Array = []             # pavillons qui flottent au vent
var lantern_mat: StandardMaterial3D
var stern_lights: Array = []
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}
var _clock: float = 0.0


func place(at: Vector3, yaw: float) -> void:
	xf = Transform3D(Basis(Vector3.UP, yaw), at)
	inv = xf.affine_inverse()
	transform = xf


func W(p: Vector3) -> Vector3:
	return xf * p


func Lc(p: Vector3) -> Vector3:
	return inv * p


# =================================================================== forme

func plan(x: float) -> float:
	var xn: float = clampf(x / HL, -1.0, 1.0)
	if xn >= 0.0:
		return maxf(0.0, 1.0 - pow(xn, 2.0))
	return 1.0 - 0.35 * pow(-xn, 3.0)


func keel(x: float) -> float:
	return 2.2 * pow(maxf(0.0, x / HL - 0.5), 2.0) * 4.0


func _sect(h: float, x: float) -> float:
	if h <= 0.0:
		return 0.0
	var p: float = 0.5 + 0.5 * pow(maxf(0.0, x / HL), 1.5)
	if h < 2.6:
		return pow(h / 2.6, p)
	return 1.0 - 0.12 * pow((h - 2.6) / (D - 2.6), 2.0)


func hb(x: float, y: float) -> float:
	return HB * plan(x) * _sect(y - keel(x), x)


func hb_in(x: float, y: float) -> float:
	return maxf(hb(x, y) - THICK, 0.05)


func deck_y(x: float) -> float:
	return D + 0.9 * pow(x / HL, 2.0)


func bul_y(x: float) -> float:
	return deck_y(x) + 1.1


## Le joueur (ou un pirate) est-il à bord ?
func aboard(p: Vector3) -> bool:
	var l: Vector3 = inv * p
	if absf(l.x) > HL + 1.0 or l.y < 0.5 or l.y > D + 30.0:
		return false
	return absf(l.z) < hb(clampf(l.x, -HL, HL), clampf(l.y, 1.0, D)) + 0.6


func blocks_boat(p: Vector3) -> bool:
	var l: Vector3 = inv * p
	if absf(l.x) > HL + 2.0:
		return false
	return absf(l.z) < HB * plan(clampf(l.x, -HL, HL)) + 1.4


## Le pont (repère du navire) à cet endroit, pour poser les gens.
func deck_at(x: float, z: float) -> Vector3:
	var y: float = deck_y(x)
	if x < CASTLE_X:
		y = D + QD_H
	elif x > FC_X:
		y = deck_y(x) + FC_H
	return W(Vector3(x, y, z))


# =================================================================== matériaux

func mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var T := "res://assets/textures/carene/"
	var m: Material
	match key:
		"coque":
			var sm := ShaderMaterial.new()
			sm.shader = load("res://shaders/coque_v59.gdshader")
			sm.set_shader_parameter("planks_tex", load(T + "bordage.png"))
			sm.set_shader_parameter("planks_n", load(T + "bordage_n.png"))
			sm.set_shader_parameter("fouling_tex", load(T + "salissures.png"))
			sm.set_shader_parameter("fouling_n", load(T + "salissures_n.png"))
			sm.set_shader_parameter("tint", Color(0.64, 0.52, 0.42))
			sm.set_shader_parameter("hull_paint", true)
			sm.set_shader_parameter("hull_inv", Projection(inv))
			sm.set_shader_parameter("deck_h", D)
			sm.set_shader_parameter("band_color", Color(0.52, 0.07, 0.05))
			sm.set_shader_parameter("band_scale", 0.42)
			sm.set_shader_parameter("fouling_top", 0.6)
			m = sm
		"pont", "pont_sombre":
			var s := StandardMaterial3D.new()
			s.albedo_texture = load(T + "pont.png")
			s.normal_enabled = true
			s.normal_texture = load(T + "pont_n.png")
			s.albedo_color = Color(0.8, 0.72, 0.62) if key == "pont" else Color(0.5, 0.42, 0.36)
			s.roughness = 0.85
			s.uv1_scale = Vector3(1, 1, 1)
			m = s
		"bois":
			var s2 := StandardMaterial3D.new()
			s2.albedo_texture = load(T + "bordage_int.png")
			s2.uv1_triplanar = true
			s2.uv1_scale = Vector3(0.3, 0.3, 0.3)
			s2.albedo_color = Color(0.7, 0.55, 0.45)
			s2.roughness = 0.88
			m = s2
		"noir":
			var s3 := StandardMaterial3D.new()
			s3.albedo_texture = load(T + "bordage_int.png")
			s3.uv1_triplanar = true
			s3.uv1_scale = Vector3(0.3, 0.3, 0.3)
			s3.albedo_color = Color(0.28, 0.24, 0.22)
			s3.roughness = 0.8
			m = s3
		"rouge":
			var s4 := StandardMaterial3D.new()
			s4.albedo_color = Color(0.5, 0.07, 0.05)
			s4.roughness = 0.6
			m = s4
		"or":
			var s5 := StandardMaterial3D.new()
			s5.albedo_color = Color(0.8, 0.6, 0.22)
			s5.metallic = 0.85
			s5.roughness = 0.35
			m = s5
		"fer":
			var s6 := StandardMaterial3D.new()
			s6.albedo_color = Color(0.09, 0.09, 0.1)
			s6.metallic = 0.7
			s6.roughness = 0.5
			m = s6
		"corde":
			var s7 := StandardMaterial3D.new()
			s7.albedo_color = Color(0.32, 0.26, 0.18)
			s7.roughness = 0.95
			m = s7
		"voile":
			var s8 := StandardMaterial3D.new()
			s8.albedo_texture = load("res://assets/textures/tazira/voile_noire.png")
			s8.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			s8.alpha_scissor_threshold = 0.5
			s8.cull_mode = BaseMaterial3D.CULL_DISABLED
			s8.roughness = 0.95
			m = s8
		"pavillon":
			var s9 := StandardMaterial3D.new()
			s9.albedo_texture = load("res://assets/textures/tazira/pavillon.png")
			s9.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			s9.alpha_scissor_threshold = 0.5
			s9.cull_mode = BaseMaterial3D.CULL_DISABLED
			s9.roughness = 0.9
			m = s9
		"vitre":
			var sa := StandardMaterial3D.new()
			sa.albedo_color = Color(0.9, 0.62, 0.3)
			sa.emission_enabled = true
			sa.emission = Color(1.0, 0.62, 0.3)
			sa.emission_energy_multiplier = 1.2
			m = sa
	_mats[key] = m
	return m


# =================================================================== géométrie

func _quad(st: SurfaceTool, a: Array, b: Array, c: Array, d: Array, want: Vector3, faces: PackedVector3Array = PackedVector3Array(), collide: bool = false) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	var order: Array = [a, b, c, a, c, d]
	if (pb - pa).cross(pc - pa).dot(want) > 0.0:
		order = [a, c, b, a, d, c]
	for v in order:
		st.set_uv(v[1])
		st.add_vertex(v[0])
		if collide:
			faces.append(v[0])


func _box(st: SurfaceTool, c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	var hx: Vector3 = b.x * size.x * 0.5
	var hy: Vector3 = b.y * size.y * 0.5
	var hz: Vector3 = b.z * size.z * 0.5
	var k := [c - hx - hy - hz, c + hx - hy - hz, c + hx + hy - hz, c - hx + hy - hz, c - hx - hy + hz, c + hx - hy + hz, c + hx + hy + hz, c - hx + hy + hz]
	var quads := [[0, 1, 2, 3, -b.z], [5, 4, 7, 6, b.z], [4, 0, 3, 7, -b.x], [1, 5, 6, 2, b.x], [3, 2, 6, 7, b.y], [4, 5, 1, 0, -b.y]]
	var s: float = maxf(size.x, maxf(size.y, size.z))
	for q in quads:
		_quad(st, [k[q[0]], Vector2(0, 0)], [k[q[1]], Vector2(s * 0.4, 0)], [k[q[2]], Vector2(s * 0.4, 0.4)], [k[q[3]], Vector2(0, 0.4)], q[4])


func _tube(st: SurfaceTool, path: Array, r0: float, r1: float, sides: int) -> void:
	var rings: Array = []
	var prev := Vector3.ZERO
	for i in range(path.size()):
		var f: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var sd: Vector3 = f.cross(Vector3.UP if absf(f.y) < 0.95 else Vector3.RIGHT).normalized()
		if prev != Vector3.ZERO and sd.dot(prev) < 0.0:
			sd = -sd
		prev = sd
		var up: Vector3 = sd.cross(f).normalized()
		var r: float = lerpf(r0, r1, float(i) / maxf(path.size() - 1, 1))
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / sides
			ring.append((path[i] as Vector3) + (sd * cos(a) + up * sin(a)) * r)
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a: Vector3 = rings[i][s]
			var b: Vector3 = rings[i][s + 1]
			var c: Vector3 = rings[i + 1][s + 1]
			var d: Vector3 = rings[i + 1][s]
			var out: Vector3 = ((a + b) * 0.5 - (path[i] as Vector3)).normalized()
			_quad(st, [a, Vector2(float(s) / sides, i * 0.5)], [b, Vector2(float(s + 1) / sides, i * 0.5)], [c, Vector2(float(s + 1) / sides, i * 0.5 + 0.5)], [d, Vector2(float(s) / sides, i * 0.5 + 0.5)], out)


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _commit(st: SurfaceTool, key: String, name_s: String, tangents: bool = false) -> MeshInstance3D:
	st.generate_normals()
	if tangents:
		st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = name_s
	mi.mesh = st.commit()
	mi.material_override = mat(key)
	add_child(mi)
	return mi


func _collide(faces: PackedVector3Array, backface: bool = true) -> void:
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = backface
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)


func _col_box(c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.transform = Transform3D(b, c)
	body.add_child(cs)


# =================================================================== construction

func build(high_quality: bool) -> void:
	_rng.seed = 6066
	body = StaticBody3D.new()
	body.name = "Murene_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_hull()
	_deck()
	_castle()
	_forecastle()
	_masts(high_quality)
	_cannons_and_props()
	print("ILE_MANGA_V60: la Murène Noire, galion pirate, à ", xf.origin)


func _hull() -> void:
	var outer := _st()
	var inner := _st()
	var faces := PackedVector3Array()
	var nx: int = 60
	var nr: int = 14
	for side in [-1.0, 1.0]:
		for i in range(nx):
			var x0: float = -HL + 2.0 * HL * i / nx
			var x1: float = -HL + 2.0 * HL * (i + 1) / nx
			for j in range(nr):
				var ya0: float = lerpf(keel(x0), bul_y(x0), float(j) / nr)
				var ya1: float = lerpf(keel(x0), bul_y(x0), float(j + 1) / nr)
				var yb0: float = lerpf(keel(x1), bul_y(x1), float(j) / nr)
				var yb1: float = lerpf(keel(x1), bul_y(x1), float(j + 1) / nr)
				var u := [Vector2(x0 * 0.12, -ya0 * 0.12), Vector2(x1 * 0.12, -yb0 * 0.12), Vector2(x1 * 0.12, -yb1 * 0.12), Vector2(x0 * 0.12, -ya1 * 0.12)]
				var o := [Vector3(x0, ya0, side * hb(x0, ya0)), Vector3(x1, yb0, side * hb(x1, yb0)), Vector3(x1, yb1, side * hb(x1, yb1)), Vector3(x0, ya1, side * hb(x0, ya1))]
				_quad(outer, [o[0], u[0]], [o[1], u[1]], [o[2], u[2]], [o[3], u[3]], Vector3(0, 0, side), faces, true)
				if ya1 > deck_y(x0) - 0.2:
					var n := [Vector3(x0, ya0, side * hb_in(x0, ya0)), Vector3(x1, yb0, side * hb_in(x1, yb0)), Vector3(x1, yb1, side * hb_in(x1, yb1)), Vector3(x0, ya1, side * hb_in(x0, ya1))]
					_quad(inner, [n[0], u[0]], [n[1], u[1]], [n[2], u[2]], [n[3], u[3]], Vector3(0, 0, -side))
		# le plat-bord
		for i in range(nx):
			var x0: float = -HL + 2.0 * HL * i / nx
			var x1: float = -HL + 2.0 * HL * (i + 1) / nx
			var q := [Vector3(x0, bul_y(x0), side * hb(x0, bul_y(x0))), Vector3(x1, bul_y(x1), side * hb(x1, bul_y(x1))),
				Vector3(x1, bul_y(x1), side * hb_in(x1, bul_y(x1))), Vector3(x0, bul_y(x0), side * hb_in(x0, bul_y(x0)))]
			_quad(inner, [q[0], Vector2(0, 0)], [q[1], Vector2(0.3, 0)], [q[2], Vector2(0.3, 0.05)], [q[3], Vector2(0, 0.05)], Vector3.UP, faces, true)
	# le tableau arrière
	for j in range(nr):
		var y0: float = lerpf(keel(-HL), bul_y(-HL), float(j) / nr)
		var y1: float = lerpf(keel(-HL), bul_y(-HL), float(j + 1) / nr)
		var q2 := [Vector3(-HL, y0, -hb(-HL, y0)), Vector3(-HL, y0, hb(-HL, y0)), Vector3(-HL, y1, hb(-HL, y1)), Vector3(-HL, y1, -hb(-HL, y1))]
		_quad(outer, [q2[0], Vector2(-q2[0].z * 0.12, -y0 * 0.12)], [q2[1], Vector2(-q2[1].z * 0.12, -y0 * 0.12)], [q2[2], Vector2(-q2[2].z * 0.12, -y1 * 0.12)], [q2[3], Vector2(-q2[3].z * 0.12, -y1 * 0.12)], Vector3(-1, 0, 0), faces, true)
	_commit(outer, "coque", "Coque_Murene", true)
	_commit(inner, "noir", "Vaigrage_Murene")
	_collide(faces)


func _deck() -> void:
	var st := _st()
	var faces := PackedVector3Array()
	var x: float = -HL + 0.3
	while x < HL - 1.2:
		var xb: float = minf(x + 1.0, HL - 1.2)
		var ya: float = deck_y(x)
		var yb: float = deck_y(xb)
		var wa: float = hb_in(x, ya) - 0.02
		var wb: float = hb_in(xb, yb) - 0.02
		var q := [Vector3(x, ya, -wa), Vector3(xb, yb, -wb), Vector3(xb, yb, wb), Vector3(x, ya, wa)]
		var u := []
		for p in q:
			u.append(Vector2((p as Vector3).z * 0.15, (p as Vector3).x * 0.15))
		_quad(st, [q[0], u[0]], [q[1], u[1]], [q[2], u[2]], [q[3], u[3]], Vector3.UP, faces, true)
		x = xb
	_commit(st, "pont", "Pont_Murene", true)
	_collide(faces, false)


## Le château arrière : la cabine du capitaine dessous, la dunette dessus, la galerie de poupe.
func _castle() -> void:
	var st := _st()
	var faces := PackedVector3Array()
	var y0: float = D
	var y1: float = D + QD_H
	# les flancs du château suivent la muraille ; la façade a une porte et deux fenêtres
	for side in [-1.0, 1.0]:
		var x: float = -HL + 0.2
		while x < CASTLE_X:
			var xn: float = minf(x + 1.0, CASTLE_X)
			var za: float = side * hb_in(x, D + 1.0)
			var zb: float = side * hb_in(xn, D + 1.0)
			var q := [Vector3(x, y0, za), Vector3(xn, y0, zb), Vector3(xn, y1, zb), Vector3(x, y1, za)]
			_quad(st, [q[0], Vector2(x * 0.15, 0)], [q[1], Vector2(xn * 0.15, 0)], [q[2], Vector2(xn * 0.15, 0.4)], [q[3], Vector2(x * 0.15, 0.4)], Vector3(0, 0, side), faces, true)
			_quad(st, [q[0], Vector2(x * 0.15, 0)], [q[1], Vector2(xn * 0.15, 0)], [q[2], Vector2(xn * 0.15, 0.4)], [q[3], Vector2(x * 0.15, 0.4)], Vector3(0, 0, -side))
			x = xn
	var wf: float = hb_in(CASTLE_X, D + 1.0)
	var door_w: float = 1.3
	var door_h: float = 2.1
	# façade : à gauche et à droite de la porte, au-dessus de la porte
	for seg in [[-wf, -door_w * 0.5], [door_w * 0.5, wf]]:
		var za: float = float(seg[0])
		var zb: float = float(seg[1])
		var c := Vector3(CASTLE_X, (y0 + y1) * 0.5, (za + zb) * 0.5)
		_box(st, c, Vector3(0.18, QD_H, zb - za))
		_col_box(c, Vector3(0.2, QD_H, zb - za))
	_box(st, Vector3(CASTLE_X, y0 + door_h + (QD_H - door_h) * 0.5, 0), Vector3(0.18, QD_H - door_h, door_w))
	_commit(st, "noir", "Chateau_Murene")
	_collide(faces)
	# fenêtres éclairées de la façade et de la poupe
	var glow := _st()
	for z in [-2.6, 2.6]:
		_box(glow, Vector3(CASTLE_X + 0.1, y0 + 1.5, z), Vector3(0.05, 0.7, 0.9))
	for k in range(4):
		_box(glow, Vector3(-HL - 0.05, D + 1.4, lerpf(-3.0, 3.0, float(k) / 3.0)), Vector3(0.05, 0.9, 0.9))
	_commit(glow, "vitre", "Fenetres_Murene")
	# la dunette (le toit du château) et ses garde-corps
	var roof := _st()
	var rf := PackedVector3Array()
	var hw: float = hb_in(-18.0, D + 1.0)
	var q3 := [Vector3(-HL, y1, -hb_in(-HL, D + 1.0)), Vector3(CASTLE_X, y1, -wf), Vector3(CASTLE_X, y1, wf), Vector3(-HL, y1, hb_in(-HL, D + 1.0))]
	_quad(roof, [q3[0], Vector2(0, 0)], [q3[1], Vector2(1.5, 0)], [q3[2], Vector2(1.5, 1.8)], [q3[3], Vector2(0, 1.8)], Vector3.UP, rf, true)
	_quad(roof, [q3[0], Vector2(0, 0)], [q3[1], Vector2(1.5, 0)], [q3[2], Vector2(1.5, 1.8)], [q3[3], Vector2(0, 1.8)], Vector3.DOWN)
	_commit(roof, "pont_sombre", "Dunette_Murene")
	_collide(rf, false)
	var rails := _st()
	var pts: Array = [Vector3(-HL + 0.1, y1, -hb_in(-HL, D + 1.0) + 0.1), Vector3(CASTLE_X, y1, -wf + 0.1), Vector3(CASTLE_X, y1, -1.6)]
	_rail(rails, pts)
	_rail(rails, [Vector3(CASTLE_X, y1, 1.6 + 1.4), Vector3(CASTLE_X, y1, wf - 0.1), Vector3(-HL + 0.1, y1, hb_in(-HL, D + 1.0) - 0.1), Vector3(-HL + 0.1, y1, -hb_in(-HL, D + 1.0) + 0.1)])
	# l'escalier de la dunette (à tribord, le long de la façade)
	var a := Vector3(CASTLE_X + 4.4, deck_y(CASTLE_X + 4.4), 2.3)
	var b := Vector3(CASTLE_X + 0.1, y1, 2.3)
	_stairs(rails, a, b, 1.3)
	_commit(rails, "bois", "Rambardes_Murene")
	# la grande lanterne de poupe, et deux plus petites
	lantern_mat = StandardMaterial3D.new()
	lantern_mat.albedo_color = Color(1.0, 0.85, 0.55, 0.9)
	lantern_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lantern_mat.emission_enabled = true
	lantern_mat.emission = Color(1.0, 0.7, 0.35)
	lantern_mat.emission_energy_multiplier = 0.4
	for z in [-2.0, 0.0, 2.0]:
		var big: bool = z == 0.0
		var lm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22 if big else 0.15
		cm.bottom_radius = 0.3 if big else 0.2
		cm.height = 0.9 if big else 0.55
		cm.radial_segments = 8
		lm.mesh = cm
		lm.material_override = lantern_mat
		lm.position = Vector3(-HL - 0.2, y1 + (1.4 if big else 0.9), z)
		add_child(lm)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.4)
		l.light_energy = 0.0
		l.omni_range = 9.0 if big else 6.0
		l.position = lm.position
		add_child(l)
		stern_lights.append(l)


func _rail(st: SurfaceTool, pts: Array) -> void:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var mid: Vector3 = (a + b) * 0.5
		var dir: Vector3 = b - a
		var f: Vector3 = dir.normalized()
		var side: Vector3 = f.cross(Vector3.UP).normalized()
		var bas := Basis(side, Vector3.UP, -f)
		_box(st, mid + Vector3.UP * 1.0, Vector3(0.1, 0.1, dir.length()), bas)
		var n: int = maxi(1, int(dir.length() / 0.7))
		for k in range(n + 1):
			_box(st, a.lerp(b, float(k) / n) + Vector3.UP * 0.5, Vector3(0.07, 1.0, 0.07))
		_col_box(mid + Vector3.UP * 0.55, Vector3(0.12, 1.1, dir.length()), bas)


func _stairs(st: SurfaceTool, a: Vector3, b: Vector3, w: float) -> void:
	var dir: Vector3 = b - a
	var hd: Vector3 = Vector3(dir.x, 0, dir.z).normalized()
	var sd: Vector3 = hd.cross(Vector3.UP).normalized()
	var steps: int = int(ceil(absf(dir.y) / 0.28))
	var run: float = Vector2(dir.x, dir.z).length()
	for k in range(steps):
		var p: Vector3 = a.lerp(b, (float(k) + 0.5) / steps)
		_box(st, p - Vector3.UP * 0.1, Vector3(w, 0.14, run / steps + 0.06), Basis(sd, Vector3.UP, -hd))
	var f: Vector3 = dir.normalized()
	var up: Vector3 = f.cross(sd).normalized()
	if up.y < 0.0:
		up = -up
	_col_box((a + b) * 0.5 - up * 0.12, Vector3(w, 0.24, a.distance_to(b)), Basis(sd, up, -f))


func _forecastle() -> void:
	var st := _st()
	var faces := PackedVector3Array()
	var x0: float = FC_X
	var x1: float = HL - 1.3
	var y: float = deck_y(x0) + FC_H
	var w0: float = hb_in(x0, D + 1.0) - 0.05
	var w1: float = hb_in(x1, D + 1.0) - 0.05
	var q := [Vector3(x0, y, -w0), Vector3(x1, y + 0.25, -w1), Vector3(x1, y + 0.25, w1), Vector3(x0, y, w0)]
	_quad(st, [q[0], Vector2(0, 0)], [q[1], Vector2(1, 0)], [q[2], Vector2(1, 1)], [q[3], Vector2(0, 1)], Vector3.UP, faces, true)
	_box(st, Vector3(x0, deck_y(x0) + FC_H * 0.5, 0), Vector3(0.16, FC_H, w0 * 2.0))
	_col_box(Vector3(x0, deck_y(x0) + FC_H * 0.5, -w0 * 0.5 - 0.7), Vector3(0.2, FC_H, w0 - 1.4))
	_col_box(Vector3(x0, deck_y(x0) + FC_H * 0.5, w0 * 0.5 + 0.7), Vector3(0.2, FC_H, w0 - 1.4))
	_commit(st, "pont_sombre", "Gaillard_Murene")
	_collide(faces, false)
	var r := _st()
	_stairs(r, Vector3(x0 - 3.4, deck_y(x0 - 3.4), 0.0), Vector3(x0 + 0.1, y, 0.0), 1.2)
	_commit(r, "bois", "Escalier_gaillard")
	# la cloche du bord
	var bell := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.26
	cm.height = 0.36
	bell.mesh = cm
	bell.material_override = mat("or")
	bell.position = Vector3(x0 + 1.5, y + 1.6, 0)
	add_child(bell)


func _masts(high_quality: bool) -> void:
	var wood := _st()
	var rope := _st()
	var sail := _st()
	for m in MASTS:
		var mx: float = float(m[0])
		var base_y: float = (D + QD_H) if mx < CASTLE_X else deck_y(mx)
		var top: float = deck_y(mx) + float(m[1])
		var path: Array = []
		for i in range(7):
			path.append(Vector3(mx, lerpf(D - 1.0, top, float(i) / 6.0), 0))
		_tube(wood, path, 0.36, 0.14, 10)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.36
		cyl.height = top - base_y
		cs.shape = cyl
		cs.position = Vector3(mx, (base_y + top) * 0.5, 0)
		body.add_child(cs)
		# deux vergues et deux voiles carrées (la basse à moitié carguée), une hune
		var h: float = float(m[1])
		var yards := [[base_y + h * 0.42, h * 0.52], [base_y + h * 0.75, h * 0.38]]
		for k in range(yards.size()):
			var yy: float = float(yards[k][0])
			var half: float = float(yards[k][1]) * 0.5 + 2.0
			_tube(wood, [Vector3(mx + 0.3, yy, -half), Vector3(mx + 0.3, yy, half)], 0.14, 0.1, 6)
			var drop: float = (h * 0.28) if k == 0 else (h * 0.22)
			if k == 0:
				drop *= 0.6
			_sail(sail, Vector3(mx + 0.35, yy - 0.2, 0), half * 1.8, drop, 0.9 if k == 1 else 0.5)
		var hune := Vector3(mx, base_y + h * 0.55, 0)
		_box(wood, hune, Vector3(2.2, 0.2, 2.2))
		# haubans et enfléchures
		for side in [-1.0, 1.0]:
			for k2 in range(4):
				var xb: float = mx - 1.5 + k2 * 1.0
				var foot := Vector3(xb, bul_y(xb), side * hb(xb, bul_y(xb)))
				_tube(rope, [foot, hune + Vector3(0, 0, side * 0.9)], 0.03, 0.03, 4)
			var yy2: float = bul_y(mx) + 0.6
			while yy2 < hune.y - 0.4 and high_quality:
				var t: float = (yy2 - bul_y(mx)) / (hune.y - bul_y(mx))
				var za: float = side * lerpf(hb(mx, bul_y(mx)), 0.9, t)
				_tube(rope, [Vector3(mx - 1.4 * (1 - t), yy2, za), Vector3(mx + 1.4 * (1 - t), yy2, za)], 0.018, 0.018, 3)
				yy2 += 0.5
		# le pavillon en tête de mât
		var fl := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.6, 1.6) if mx == 0.0 else Vector2(1.6, 1.0)
		fl.mesh = qm
		fl.material_override = mat("pavillon")
		fl.position = Vector3(mx - qm.size.x * 0.5, top - qm.size.y * 0.5 - 0.1, 0)
		add_child(fl)
		flag_nodes.append(fl)
	# beaupré, étais, foc
	var bs := Vector3(HL - 1.0, deck_y(HL) + 1.8, 0)
	var be := bs + Vector3(10.0, 3.0, 0)
	_tube(wood, [bs, be], 0.25, 0.12, 8)
	_tube(rope, [be, Vector3(12.0, deck_y(12.0) + 19.0, 0)], 0.04, 0.04, 4)
	_tube(rope, [Vector3(12.0, deck_y(12.0) + 15.0, 0), Vector3(0.0, deck_y(0.0) + 22.0, 0)], 0.04, 0.04, 4)
	_tube(rope, [Vector3(-16.5, D + QD_H + 13.0, 0), Vector3(0.0, deck_y(0.0) + 14.0, 0)], 0.04, 0.04, 4)
	var jib := [Vector3(HL + 7.0, deck_y(HL) + 3.6, 0), Vector3(HL + 0.5, deck_y(HL) + 2.6, 0), Vector3(14.0, deck_y(12.0) + 15.0, 0)]
	_quad(sail, [jib[0], Vector2(0.9, 0.95)], [jib[1], Vector2(0.1, 0.95)], [jib[2], Vector2(0.5, 0.1)], [jib[2], Vector2(0.5, 0.1)], Vector3(0, 0, 1))
	_commit(wood, "noir", "Mature_Murene")
	_commit(rope, "corde", "Gréement_Murene")
	_commit(sail, "voile", "Voiles_Murene")


func _sail(st: SurfaceTool, top_c: Vector3, width: float, height: float, belly: float) -> void:
	var nu: int = 8
	var nv: int = 5
	var g: Array = []
	for j in range(nv + 1):
		var row: Array = []
		var v: float = float(j) / nv
		for i in range(nu + 1):
			var u: float = float(i) / nu
			var p: Vector3 = top_c + Vector3(sin(u * PI) * sin(v * PI * 0.85) * belly, -v * height, (u - 0.5) * width)
			row.append([p, Vector2(u, v * 0.7)])
		g.append(row)
	for j in range(nv):
		for i in range(nu):
			_quad(st, g[j][i], g[j][i + 1], g[j + 1][i + 1], g[j + 1][i], Vector3(1, 0, 0))


func _cannons_and_props() -> void:
	var st := _st()
	var iron := _st()
	for k in range(4):
		var x: float = -9.0 + k * 5.5
		for side in [-1.0, 1.0]:
			var z: float = side * (hb_in(x, D + 0.6) - 1.3)
			var y: float = deck_y(x)
			_box(st, Vector3(x, y + 0.25, z), Vector3(0.9, 0.4, 1.4))
			_tube(iron, [Vector3(x, y + 0.6, z - side * 0.5), Vector3(x, y + 0.65, z + side * 1.2)], 0.22, 0.16, 10)
			_col_box(Vector3(x, y + 0.4, z), Vector3(1.0, 0.8, 1.6))
	# tonneaux de rhum, coffres, cordages lovés
	for p in [[6.0, -3.6], [6.8, -3.2], [-8.0, 3.8], [9.5, 3.4]]:
		var x2: float = float(p[0])
		var c := Vector3(x2, deck_y(x2) + 0.45, float(p[1]))
		var bm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.34
		cm.bottom_radius = 0.34
		cm.height = 0.9
		bm.mesh = cm
		bm.material_override = mat("bois")
		bm.position = c
		add_child(bm)
		_col_box(c, Vector3(0.68, 0.9, 0.68))
	var chest := Vector3(-19.0, D + QD_H + 0.3, 0.0)
	_box(st, chest, Vector3(1.0, 0.6, 0.7))
	_box(iron, chest + Vector3(0, 0.12, 0), Vector3(1.04, 0.08, 0.74))
	_col_box(chest, Vector3(1.0, 0.6, 0.7))
	# la barre (la roue du gouvernail) sur la dunette
	var wheel := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.65
	tm.ring_segments = 8
	wheel.mesh = tm
	wheel.material_override = mat("bois")
	wheel.position = Vector3(-17.0, D + QD_H + 1.1, 0)
	wheel.rotation.z = PI * 0.5
	add_child(wheel)
	_commit(st, "bois", "Affuts_Murene")
	_commit(iron, "fer", "Canons_Murene")


func set_night(on: bool) -> void:
	lantern_mat.emission_energy_multiplier = 3.5 if on else 0.4
	for l in stern_lights:
		(l as OmniLight3D).light_energy = 1.8 if on else 0.0


func _process(delta: float) -> void:
	_clock += delta
	for i in range(flag_nodes.size()):
		var f: Node3D = flag_nodes[i]
		f.rotation.y = sin(_clock * 1.7 + i) * 0.25

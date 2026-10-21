extends Node3D
## V59 : le Léviathan — l'épave géante échouée dans la baie ouest de la grande île de l'est.
## Un vaisseau de cent quarante mètres, venu d'on ne sait où, s'est échoué il y a deux siècles :
## l'étrave sur la plage, la poupe dans l'eau, un peu de gîte. Les naufragés n'en sont jamais
## repartis : ils ont bâti Carène dedans et dessus.
##  - La coque : bordé de chêne (extérieur) et vaigrage (intérieur), membrures, carène couverte de
##    coquillages sous la ligne d'eau. Deux grandes brèches : côté plage (l'entrée à pied, dans la
##    cale) et côté mer (l'eau entre dans l'arrière de la cale : le bassin intérieur).
##  - Trois niveaux : la cale (le marché ; l'arrière est inondé : le bassin), l'entrepont (les
##    logis, la forge), le pont (les cabanes, les étals, le grand mât) ; à la poupe, le château :
##    la taverne sous la dunette, la capitainerie au-dessus.
##  - Le grand mât, intact, porte deux hunes et une lanterne-phare ; le mât de misaine et
##    l'artimon sont brisés ; une voile déchirée pend encore à la grande vergue.
## Repère du navire : x vers l'étrave, y vers le haut, z vers tribord (le sud). Tout le décor
## de Carène qui suit le navire est posé dans ce repère (ponts inclinés avec lui).

const HL: float = 70.0                 # demi-longueur
const HB: float = 17.0                 # demi-largeur au maître-bau
const D: float = 19.5                  # hauteur du pont au-dessus de la quille
const HOLD_Y: float = 4.5              # plancher de la cale
const GUN_Y: float = 12.0              # plancher de l'entrepont
const QD_Y: float = 23.3               # dunette (toit de la taverne)
const PD_Y: float = 26.7               # toit de la capitainerie
const CASTLE_X: float = -42.0          # façade du château arrière
const CABIN_X: float = -57.0           # façade de la capitainerie
const THICK: float = 0.4
const MAIN_X: float = 4.0
const FORE_X: float = 44.0
const MIZZEN_X: float = -50.0
## Brèches : [x0, x1, y0, y1, bord (+1 tribord / sud, -1 bâbord / nord)]
const HOLES := [
	[35.0, 49.0, 2.8, 11.2, -1.0],      # la brèche de la plage (l'entrée de Carène)
	[-54.0, -36.0, 1.6, 9.6, 1.0],      # la brèche de la mer (le bassin intérieur)
	[12.0, 14.2, 14.5, 15.6, -1.0], [-14.0, -11.5, 15.0, 16.2, 1.0], [24.0, 26.8, 6.8, 7.7, 1.0],
	[-28.0, -25.6, 13.2, 14.0, -1.0], [52.0, 53.8, 13.6, 14.5, 1.0], [-6.0, -3.6, 6.2, 7.1, -1.0],
]
## Ouvertures dans les ponts (repère du navire) : [x0, x1, z0, z1]
const GUN_OPEN := [[16.0, 31.0, 6.6, 10.4], [-4.0, 14.0, -4.0, 4.0]]
const DECK_OPEN := [[-21.0, -6.0, -10.4, -6.6], [-4.0, 14.0, -4.0, 4.0]]
## Les escaliers : [départ (x, y, z), arrivée (x, y, z), largeur]
const RAMPS := [
	[Vector3(16.5, HOLD_Y, 8.5), Vector3(30.5, GUN_Y, 8.5), 3.0],
	[Vector3(-6.5, GUN_Y, -8.5), Vector3(-20.5, D, -8.5), 3.0],
	[Vector3(-31.0, D, 10.6), Vector3(-42.0, QD_Y, 10.6), 2.4],
	[Vector3(-46.0, QD_Y, -5.6), Vector3(-57.0, PD_Y, -5.6), 2.2],
]

var origin := Vector3(665.0, -4.8, -150.0)
var yaw: float = 0.06
var pitch: float = 0.052
var roll: float = 0.035
var xf := Transform3D()
var inv := Transform3D()
var pc: bool = true
var body: StaticBody3D
var lantern_light: OmniLight3D
var lantern_mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()
var _mats: Dictionary = {}


## Le repère du navire (avant même d'être dans l'arbre : l'île s'en sert pour l'ensabler).
func place(at: Vector3) -> void:
	origin = at
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3(0, 0, 1), pitch) * Basis(Vector3(1, 0, 0), roll)
	xf = Transform3D(b, origin)
	inv = xf.affine_inverse()
	transform = xf


# =================================================================== la forme de la coque

func keel(x: float) -> float:
	var xn: float = x / HL
	return 30.0 * pow(maxf(0.0, xn - 0.55), 2.0)


func plan(x: float) -> float:
	var xn: float = clampf(x / HL, -1.0, 1.0)
	if xn >= 0.0:
		return maxf(0.0, 1.0 - pow(xn, 2.3))
	return 1.0 - 0.32 * pow(-xn, 4.0)


func _sect(h: float, x: float) -> float:
	if h <= 0.0:
		return 0.0
	var p: float = 0.45 + 0.55 * pow(maxf(0.0, x / HL), 1.5)
	if h < 7.0:
		return pow(h / 7.0, p)
	return 1.0 - 0.1 * pow((h - 7.0) / (D - 7.0), 2.0)


## Demi-largeur extérieure de la coque à l'abscisse x et à la hauteur y (repère du navire).
func hb(x: float, y: float) -> float:
	return HB * plan(x) * _sect(y - keel(x), x)


func hb_in(x: float, y: float) -> float:
	return maxf(hb(x, y) - THICK, 0.05)


func deck_y(x: float) -> float:
	return D + 2.5 * pow(maxf(0.0, x / HL), 2.0)


func bul_y(x: float) -> float:
	return deck_y(x) + 1.0


func W(p: Vector3) -> Vector3:
	return xf * p


func Lc(p: Vector3) -> Vector3:
	return inv * p


## Hauteur (monde) du fond de la coque sous ce point, ou -INF hors de l'emprise.
func bottom_world(wx: float, wz: float) -> float:
	var wy: float = origin.y
	var out: float = -INF
	for it in range(2):
		var l: Vector3 = inv * Vector3(wx, wy, wz)
		if absf(l.x) > HL:
			return -INF
		var pb: float = plan(l.x)
		var az: float = absf(l.z)
		if pb <= 0.001 or az >= HB * pb:
			return -INF
		var pe: float = 0.45 + 0.55 * pow(maxf(0.0, l.x / HL), 1.5)
		var h: float = 7.0 * pow(az / (HB * pb), 1.0 / pe)
		var w: Vector3 = xf * Vector3(l.x, keel(l.x) + h, l.z)
		wy = w.y
		out = w.y
	return out


## Le point est-il dans l'emprise de la coque (vue de dessus), avec une marge ?
func footprint(wx: float, wz: float, margin: float = 0.0) -> bool:
	var l: Vector3 = inv * Vector3(wx, origin.y + 8.0, wz)
	if absf(l.x) > HL + margin:
		return false
	return absf(l.z) < HB * plan(clampf(l.x, -HL, HL)) + margin


## Le joueur est-il à bord (dans la coque, sur un pont, dans la mâture) ?
func aboard(p: Vector3) -> bool:
	var l: Vector3 = inv * p
	if absf(l.x) > HL + 1.0 or l.y < 0.0 or l.y > D + 50.0:
		return false
	var y: float = clampf(l.y, 1.0, D)
	return absf(l.z) < hb(clampf(l.x, -HL, HL), y) + 0.8 or (l.y > D + 2.0 and Vector2(l.x - MAIN_X, l.z).length() < 4.0)


## La barque ne traverse pas la coque.
func blocks_boat(p: Vector3) -> bool:
	return footprint(p.x, p.z, 1.6)


# =================================================================== construction

func build(high_quality: bool) -> void:
	pc = high_quality
	_rng.seed = 5959
	body = StaticBody3D.new()
	body.name = "Epave_collision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_build_hull()
	_build_gunports()
	_build_frames()
	_build_decks()
	_build_castle()
	_build_ramps()
	_build_masts()
	print("ILE_MANGA_V59: le Léviathan, %.0f m, à %s" % [HL * 2.0, str(origin)])


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
			sm.set_shader_parameter("hull_paint", true)
			sm.set_shader_parameter("hull_inv", Projection(inv))
			sm.set_shader_parameter("deck_h", D)
			m = sm
		"vaigrage":
			var s2 := StandardMaterial3D.new()
			s2.albedo_texture = load(T + "bordage_int.png")
			s2.normal_enabled = true
			s2.normal_texture = load(T + "bordage_int_n.png")
			s2.roughness = 0.92
			m = s2
		"pont":
			var s3 := StandardMaterial3D.new()
			s3.albedo_texture = load(T + "pont.png")
			s3.normal_enabled = true
			s3.normal_texture = load(T + "pont_n.png")
			s3.roughness = 0.85
			m = s3
		"pont_dessous":
			var s4 := StandardMaterial3D.new()
			s4.albedo_texture = load(T + "bordage_int.png")
			s4.albedo_color = Color(0.85, 0.82, 0.78)
			s4.roughness = 0.92
			m = s4
		"chene":
			var s5 := StandardMaterial3D.new()
			s5.albedo_texture = load(T + "bordage_int.png")
			s5.uv1_triplanar = true
			s5.uv1_scale = Vector3(0.18, 0.18, 0.18)
			s5.albedo_color = Color(0.9, 0.82, 0.74)
			s5.roughness = 0.9
			m = s5
		"mat":
			var s6 := StandardMaterial3D.new()
			s6.albedo_texture = load(T + "planches_cabane.png")
			s6.albedo_color = Color(0.62, 0.52, 0.42)
			s6.roughness = 0.88
			m = s6
		"fer":
			var s7 := StandardMaterial3D.new()
			s7.albedo_color = Color(0.2, 0.17, 0.15)
			s7.metallic = 0.6
			s7.roughness = 0.65
			m = s7
		"corde":
			var s8 := StandardMaterial3D.new()
			s8.albedo_color = Color(0.36, 0.29, 0.2)
			s8.roughness = 0.95
			m = s8
		"voile":
			var s9 := StandardMaterial3D.new()
			s9.albedo_texture = load(T + "voile.png")
			s9.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			s9.alpha_scissor_threshold = 0.5
			s9.cull_mode = BaseMaterial3D.CULL_DISABLED
			s9.roughness = 0.95
			s9.backlight_enabled = true
			s9.backlight = Color(0.35, 0.32, 0.26)
			m = s9
		"chateau":
			var sa := ShaderMaterial.new()
			sa.shader = load("res://shaders/coque_v59.gdshader")
			sa.set_shader_parameter("planks_tex", load(T + "bordage.png"))
			sa.set_shader_parameter("planks_n", load(T + "bordage_n.png"))
			sa.set_shader_parameter("fouling_tex", load(T + "salissures.png"))
			sa.set_shader_parameter("fouling_n", load(T + "salissures_n.png"))
			sa.set_shader_parameter("tint", Color(1.05, 0.82, 0.72))
			m = sa
		"vitre":
			var sb := StandardMaterial3D.new()
			sb.albedo_color = Color(0.32, 0.38, 0.36, 0.38)
			sb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sb.cull_mode = BaseMaterial3D.CULL_DISABLED
			sb.metallic = 0.3
			sb.roughness = 0.08
			sb.emission_enabled = true
			sb.emission = Color(1.0, 0.7, 0.35)
			sb.emission_energy_multiplier = 0.0
			m = sb
	_mats[key] = m
	return m


## Un quad (a, b, c, d dans l'ordre du contour), orienté selon la normale voulue.
func _quad(st: SurfaceTool, a: Array, b: Array, c: Array, d: Array, want: Vector3, faces: PackedVector3Array = PackedVector3Array(), collide: bool = false) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc2: Vector3 = c[0]
	var order: Array = [a, b, c, a, c, d]
	if (pb - pa).cross(pc2 - pa).dot(want) > 0.0:
		order = [a, c, b, a, d, c]
	for v in order:
		st.set_uv(v[1])
		st.add_vertex(v[0])
		if collide:
			faces.append(v[0])


func _in_hole(x: float, y: float, side: float) -> bool:
	for h in HOLES:
		if float(h[4]) != side:
			continue
		if x > float(h[0]) and x < float(h[1]) and y > float(h[2]) and y < float(h[3]):
			# bords déchiquetés : la brèche n'est pas un rectangle
			var j: float = sin(x * 3.1 + y * 1.7) * 0.5 + sin(y * 4.3 - x) * 0.4
			var mx: float = minf(x - float(h[0]), float(h[1]) - x)
			var my: float = minf(y - float(h[2]), float(h[3]) - y)
			if minf(mx, my * 1.6) > 0.45 + j * 0.45:
				return true
	return false


func _build_hull() -> void:
	var outer := SurfaceTool.new()
	outer.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := SurfaceTool.new()
	inner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var nx: int = 140
	var nr: int = 34 if pc else 22
	for side in [-1.0, 1.0]:
		for i in range(nx):
			var x0: float = -HL + 2.0 * HL * i / nx
			var x1: float = -HL + 2.0 * HL * (i + 1) / nx
			for j in range(nr):
				var t0: float = float(j) / nr
				var t1: float = float(j + 1) / nr
				var ya0: float = lerpf(keel(x0), bul_y(x0), t0)
				var ya1: float = lerpf(keel(x0), bul_y(x0), t1)
				var yb0: float = lerpf(keel(x1), bul_y(x1), t0)
				var yb1: float = lerpf(keel(x1), bul_y(x1), t1)
				if _in_hole((x0 + x1) * 0.5, (ya0 + ya1) * 0.5, side):
					continue
				var want := Vector3(0, 0, side)
				var o := [Vector3(x0, ya0, side * hb(x0, ya0)), Vector3(x1, yb0, side * hb(x1, yb0)), Vector3(x1, yb1, side * hb(x1, yb1)), Vector3(x0, ya1, side * hb(x0, ya1))]
				var uvs := [Vector2(x0 * 0.06, -ya0 * 0.06), Vector2(x1 * 0.06, -yb0 * 0.06), Vector2(x1 * 0.06, -yb1 * 0.06), Vector2(x0 * 0.06, -ya1 * 0.06)]
				_quad(outer, [o[0], uvs[0]], [o[1], uvs[1]], [o[2], uvs[2]], [o[3], uvs[3]], want, faces, true)
				var n := [Vector3(x0, ya0, side * hb_in(x0, ya0)), Vector3(x1, yb0, side * hb_in(x1, yb0)), Vector3(x1, yb1, side * hb_in(x1, yb1)), Vector3(x0, ya1, side * hb_in(x0, ya1))]
				_quad(inner, [n[0], uvs[0]], [n[1], uvs[1]], [n[2], uvs[2]], [n[3], uvs[3]], -want)
		# le plat-bord : le dessus de la muraille, entre l'extérieur et l'intérieur
		for i in range(nx):
			var x0: float = -HL + 2.0 * HL * i / nx
			var x1: float = -HL + 2.0 * HL * (i + 1) / nx
			var y0: float = bul_y(x0)
			var y1: float = bul_y(x1)
			var q := [Vector3(x0, y0, side * hb(x0, y0)), Vector3(x1, y1, side * hb(x1, y1)), Vector3(x1, y1, side * hb_in(x1, y1)), Vector3(x0, y0, side * hb_in(x0, y0))]
			_quad(inner, [q[0], Vector2(x0 * 0.1, 0)], [q[1], Vector2(x1 * 0.1, 0)], [q[2], Vector2(x1 * 0.1, 0.04)], [q[3], Vector2(x0 * 0.1, 0.04)], Vector3.UP, faces, true)
	# le tableau arrière (la poupe plate)
	var xs: float = -HL
	var ns: int = 14
	for j in range(nr):
		var y0: float = lerpf(keel(xs), bul_y(xs), float(j) / nr)
		var y1: float = lerpf(keel(xs), bul_y(xs), float(j + 1) / nr)
		for k in range(ns):
			var z0: float = lerpf(-1.0, 1.0, float(k) / ns)
			var z1: float = lerpf(-1.0, 1.0, float(k + 1) / ns)
			var q2 := [Vector3(xs, y0, z0 * hb(xs, y0)), Vector3(xs, y0, z1 * hb(xs, y0)), Vector3(xs, y1, z1 * hb(xs, y1)), Vector3(xs, y1, z0 * hb(xs, y1))]
			var u2 := [Vector2(q2[0].z * 0.06, -y0 * 0.06), Vector2(q2[1].z * 0.06, -y0 * 0.06), Vector2(q2[2].z * 0.06, -y1 * 0.06), Vector2(q2[3].z * 0.06, -y1 * 0.06)]
			_quad(outer, [q2[0], u2[0]], [q2[1], u2[1]], [q2[2], u2[2]], [q2[3], u2[3]], Vector3(-1, 0, 0), faces, true)
			var q3 := []
			for p in q2:
				q3.append((p as Vector3) + Vector3(THICK, 0, 0))
			_quad(inner, [q3[0], u2[0]], [q3[1], u2[1]], [q3[2], u2[2]], [q3[3], u2[3]], Vector3(1, 0, 0))
	outer.generate_normals()
	outer.generate_tangents()
	inner.generate_normals()
	inner.generate_tangents()
	var mo := MeshInstance3D.new()
	mo.name = "Coque_Leviathan"
	mo.mesh = outer.commit()
	mo.material_override = mat("coque")
	add_child(mo)
	var mi := MeshInstance3D.new()
	mi.name = "Vaigrage_Leviathan"
	mi.mesh = inner.commit()
	mi.material_override = mat("vaigrage")
	add_child(mi)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	_build_hole_edges()


## Bouts de bordages arrachés autour des brèches.
func _build_hole_edges() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for h in HOLES:
		var x0: float = float(h[0])
		var x1: float = float(h[1])
		var y0: float = float(h[2])
		var y1: float = float(h[3])
		var side: float = float(h[4])
		var big: bool = x1 - x0 > 6.0
		var strake: float = 0.45
		var y: float = y0
		while y < y1:
			# un bordage cassé de chaque côté, de longueur variable
			for e in [0, 1]:
				var length: float = _rng.randf_range(0.2, (x1 - x0) * (0.32 if big else 0.25))
				var xa: float = x0 + 0.2 if e == 0 else x1 - 0.2 - length
				var xb: float = xa + length
				var xm: float = (xa + xb) * 0.5
				var z: float = side * (hb(xm, y + strake * 0.5) - THICK * 0.5)
				_box(st, Vector3(xm, y + strake * 0.5, z), Vector3(length, strake * 0.85, THICK * 0.9), Basis(Vector3.UP, side * 0.02) if absf(z) > 0.0 else Basis())
			y += strake
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.name = "Bordages_arraches"
	m.mesh = st.commit()
	m.material_override = mat("chene")
	add_child(m)


## Une boîte (centre, taille, orientation) ajoutée à un SurfaceTool (faces vers l'extérieur).
func _box(st: SurfaceTool, c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	var hx: Vector3 = b.x * size.x * 0.5
	var hy: Vector3 = b.y * size.y * 0.5
	var hz: Vector3 = b.z * size.z * 0.5
	var corners := [c - hx - hy - hz, c + hx - hy - hz, c + hx + hy - hz, c - hx + hy - hz, c - hx - hy + hz, c + hx - hy + hz, c + hx + hy + hz, c - hx + hy + hz]
	var quads := [[0, 1, 2, 3, -b.z], [5, 4, 7, 6, b.z], [4, 0, 3, 7, -b.x], [1, 5, 6, 2, b.x], [3, 2, 6, 7, b.y], [4, 5, 1, 0, -b.y]]
	for q in quads:
		var n: Vector3 = q[4]
		var s: float = maxf(size.x, maxf(size.y, size.z))
		_quad(st, [corners[q[0]], Vector2(0, 0)], [corners[q[1]], Vector2(s * 0.3, 0)], [corners[q[2]], Vector2(s * 0.3, 0.3)], [corners[q[3]], Vector2(0, 0.3)], n)


## Les sabords : une rangée de trappes carrées dans la bande ocre, certaines entrouvertes.
func _build_gunports() -> void:
	var dark := _st_new()
	var lids := _st_new()
	var y: float = D - 3.2
	for side in [-1.0, 1.0]:
		var x: float = -38.0
		while x < 52.0:
			if _in_hole(x, y, side) or _in_hole(x + 0.5, y, side) or _in_hole(x - 0.5, y, side):
				x += 4.6
				continue
			var hw: float = 0.55
			var hh: float = 0.48
			var pts: Array = []
			for c in [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]]:
				var px: float = x + float(c[0])
				var py: float = y + float(c[1])
				pts.append(Vector3(px, py, side * (hb(px, py) + 0.04)))
			var nrm := Vector3(0, 0, side)
			_quad(dark, [pts[0], Vector2(0, 1)], [pts[1], Vector2(1, 1)], [pts[2], Vector2(1, 0)], [pts[3], Vector2(0, 0)], nrm)
			# le mantelet (la trappe), relevé ou pendant
			var open: float = _rng.randf_range(0.0, 1.0)
			var ang: float = 0.0 if open < 0.35 else (_rng.randf_range(0.6, 1.3) if open < 0.85 else -1.4)
			var hinge_y: float = y + hh
			var c0 := Vector3(x, hinge_y, side * (hb(x, hinge_y) + 0.06))
			var b := Basis(Vector3(1, 0, 0), -side * ang)
			_box(lids, c0 + b * Vector3(0, -hh - 0.02, side * 0.05), Vector3(hw * 2.1, hh * 2.1, 0.1), b)
			x += 4.6
	dark.generate_normals()
	lids.generate_normals()
	var md := MeshInstance3D.new()
	md.name = "Sabords"
	md.mesh = dark.commit()
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.03, 0.025, 0.02)
	dm.roughness = 1.0
	md.material_override = dm
	add_child(md)
	var ml := MeshInstance3D.new()
	ml.name = "Mantelets"
	ml.mesh = lids.commit()
	ml.material_override = mat("chene")
	add_child(ml)


func _st_new() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# =================================================================== membrures et baux

func _tube(st: SurfaceTool, path: Array, radius: float, sides: int) -> void:
	var prev_side := Vector3.ZERO
	var rings: Array = []
	for i in range(path.size()):
		var fwd: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var sd: Vector3 = fwd.cross(Vector3.UP if absf(fwd.y) < 0.95 else Vector3.RIGHT).normalized()
		if prev_side != Vector3.ZERO and sd.dot(prev_side) < 0.0:
			sd = -sd
		prev_side = sd
		var up: Vector3 = sd.cross(fwd).normalized()
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * float(s) / sides + PI / sides
			ring.append((path[i] as Vector3) + (sd * cos(a) + up * sin(a)) * radius)
		rings.append(ring)
	for i in range(rings.size() - 1):
		var c0: Vector3 = path[i]
		for s in range(sides):
			var a: Vector3 = rings[i][s]
			var b: Vector3 = rings[i][s + 1]
			var c: Vector3 = rings[i + 1][s + 1]
			var d: Vector3 = rings[i + 1][s]
			var out: Vector3 = ((a + b) * 0.5 - c0).normalized()
			_quad(st, [a, Vector2(0, i * 0.5)], [b, Vector2(0.25, i * 0.5)], [c, Vector2(0.25, i * 0.5 + 0.5)], [d, Vector2(0, i * 0.5 + 0.5)], out)


func _build_frames() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x: float = -66.0
	while x < 62.0:
		for side in [-1.0, 1.0]:
			var path: Array = []
			var y: float = keel(x) + 0.6
			while y < bul_y(x) - 0.2:
				path.append(Vector3(x, y, side * (hb_in(x, y) - 0.2)))
				y += 1.2
			path.append(Vector3(x, bul_y(x) - 0.2, side * (hb_in(x, bul_y(x) - 0.2) - 0.2)))
			if path.size() > 2:
				_tube(st, path, 0.24, 4)
		# baux sous les ponts (poutres en travers)
		for dy in [GUN_Y - 0.25, deck_y(x) - 0.25]:
			var w: float = hb_in(x, dy) - 0.1
			if w > 1.0:
				_box(st, Vector3(x, dy, 0), Vector3(0.36, 0.42, w * 2.0))
		x += 2.5
	# la carlingue (la poutre du fond, sur la quille)
	var kp: Array = []
	for i in range(40):
		var kx: float = lerpf(-66.0, 62.0, float(i) / 39.0)
		kp.append(Vector3(kx, keel(kx) + 0.7, 0))
	_tube(st, kp, 0.5, 6)
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.name = "Membrures"
	m.mesh = st.commit()
	m.material_override = mat("chene")
	add_child(m)


# =================================================================== les ponts

func _open(list: Array, x: float, z: float) -> bool:
	for o in list:
		if x > float(o[0]) and x < float(o[1]) and z > float(o[2]) and z < float(o[3]):
			return true
	return false


## Un pont : grille de planches entre les murailles ; skip(x, z) -> true : pas de plancher.
func _deck(name_s: String, y_of: Callable, x0: float, x1: float, skip: Callable, width_y: float = -1.0) -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var under := SurfaceTool.new()
	under.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var nz: int = 16
	var x: float = x0
	while x < x1 - 0.01:
		var xb: float = minf(x + 1.0, x1)
		var ya: float = y_of.call(x)
		var yb: float = y_of.call(xb)
		var wa: float = hb_in(x, ya if width_y < 0.0 else width_y) - 0.02
		var wb: float = hb_in(xb, yb if width_y < 0.0 else width_y) - 0.02
		for k in range(nz):
			var fa: float = lerpf(-1.0, 1.0, float(k) / nz)
			var fb: float = lerpf(-1.0, 1.0, float(k + 1) / nz)
			var zc: float = (fa + fb) * 0.25 * (wa + wb)
			if skip.call((x + xb) * 0.5, zc):
				continue
			var q := [Vector3(x, ya, fa * wa), Vector3(xb, yb, fa * wb), Vector3(xb, yb, fb * wb), Vector3(x, ya, fb * wa)]
			var u := []
			for p in q:
				u.append(Vector2((p as Vector3).x * 0.12, (p as Vector3).z * 0.12))
			_quad(top, [q[0], u[0]], [q[1], u[1]], [q[2], u[2]], [q[3], u[3]], Vector3.UP, faces, true)
			var qd := []
			for p in q:
				qd.append((p as Vector3) + Vector3.DOWN * 0.12)
			_quad(under, [qd[0], u[0]], [qd[1], u[1]], [qd[2], u[2]], [qd[3], u[3]], Vector3.DOWN)
		x = xb
	top.generate_normals()
	top.generate_tangents()
	under.generate_normals()
	var mt := MeshInstance3D.new()
	mt.name = name_s
	mt.mesh = top.commit()
	mt.material_override = mat("pont")
	add_child(mt)
	var mu := MeshInstance3D.new()
	mu.name = name_s + "_dessous"
	mu.mesh = under.commit()
	mu.material_override = mat("pont_dessous")
	add_child(mu)
	if faces.size() > 0:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)


## La cale est inondée là où son plancher passerait sous l'eau : le bassin intérieur.
func hold_flooded(x: float, z: float) -> bool:
	return (xf * Vector3(x, HOLD_Y, z)).y < -0.15


func _build_decks() -> void:
	_deck("Plancher_cale", func(_x): return HOLD_Y, -66.0, 56.0, func(x, z): return hold_flooded(x, z))
	_deck("Entrepont", func(_x): return GUN_Y, -67.0, 62.0, func(x, z): return _open(GUN_OPEN, x, z))
	_deck("Pont_Leviathan", func(x): return deck_y(x) if x > CASTLE_X else D, -69.6, 66.0, func(x, z): return _open(DECK_OPEN, x, z))


# =================================================================== le château arrière

func _wall_strip(st: SurfaceTool, faces: PackedVector3Array, pts: Array, y0: float, y1: float, want_out: bool, holes: Array = []) -> void:
	# pts : contour (repère du navire, en y=0) ; une bande verticale entre y0 et y1
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg: float = a.distance_to(b)
		var n_h: int = maxi(1, int(ceil(seg / 1.0)))
		for k in range(n_h):
			var pa: Vector3 = a.lerp(b, float(k) / n_h)
			var pb: Vector3 = a.lerp(b, float(k + 1) / n_h)
			var y: float = y0
			while y < y1 - 0.01:
				var yn: float = minf(y + 0.6, y1)
				var mid := Vector3((pa.x + pb.x) * 0.5, (y + yn) * 0.5, (pa.z + pb.z) * 0.5)
				var cut: bool = false
				for h in holes:
					var hc: Vector3 = h[0]
					var hs: Vector2 = h[1]
					if Vector2(mid.x - hc.x, mid.z - hc.z).length() < hs.x * 0.5 + 0.01 and absf(mid.y - hc.y) < hs.y * 0.5:
						cut = true
				if not cut:
					var nrm: Vector3 = (b - a).cross(Vector3.UP).normalized()
					if not want_out:
						nrm = -nrm
					var ua: float = (pa.x + pa.z) * 0.06
					var ub: float = (pb.x + pb.z) * 0.06
					_quad(st, [Vector3(pa.x, y, pa.z), Vector2(ua, -y * 0.06)], [Vector3(pb.x, y, pb.z), Vector2(ub, -y * 0.06)], [Vector3(pb.x, yn, pb.z), Vector2(ub, -yn * 0.06)], [Vector3(pa.x, yn, pa.z), Vector2(ua, -yn * 0.06)], nrm, faces, true)
				y = yn


func _build_castle() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	# contour de la taverne : flanc bâbord -> tableau -> flanc tribord (à l'intérieur de la muraille)
	var contour: Array = []
	var x: float = CASTLE_X
	while x > -HL:
		contour.append(Vector3(x, 0, -hb_in(x, D + 1.0)))
		x -= 2.0
	contour.append(Vector3(-HL + THICK, 0, -hb_in(-HL, D + 1.0)))
	contour.append(Vector3(-HL + THICK, 0, hb_in(-HL, D + 1.0)))
	x = -HL + 2.0
	var right: Array = []
	while x <= CASTLE_X:
		right.append(Vector3(x, 0, hb_in(x, D + 1.0)))
		x += 2.0
	contour += right
	# les grandes fenêtres de la poupe (la galerie) et des flancs
	var holes: Array = []
	for k in range(5):
		holes.append([Vector3(-HL + THICK, D + 2.0, lerpf(-6.0, 6.0, float(k) / 4.0)), Vector2(1.6, 1.6)])
	_wall_strip(st, faces, contour, D, QD_Y, true, holes)
	_wall_strip(st, faces, contour, D, QD_Y, false, holes)
	# la façade (porte au milieu, deux fenêtres)
	var wf: float = hb_in(CASTLE_X, D + 1.0)
	var facade := [Vector3(CASTLE_X, 0, -wf), Vector3(CASTLE_X, 0, wf)]
	var f_holes := [[Vector3(CASTLE_X, D + 1.4, 0.0), Vector2(2.4, 2.8)], [Vector3(CASTLE_X, D + 1.9, -6.0), Vector2(1.4, 1.2)], [Vector3(CASTLE_X, D + 1.9, 6.0), Vector2(1.4, 1.2)]]
	_wall_strip(st, faces, facade, D, QD_Y, true, f_holes)
	_wall_strip(st, faces, [Vector3(CASTLE_X - THICK, 0, wf), Vector3(CASTLE_X - THICK, 0, -wf)], D, QD_Y, true, [[Vector3(CASTLE_X - THICK, D + 1.4, 0.0), Vector2(2.4, 2.8)], [Vector3(CASTLE_X - THICK, D + 1.9, -6.0), Vector2(1.4, 1.2)], [Vector3(CASTLE_X - THICK, D + 1.9, 6.0), Vector2(1.4, 1.2)]])
	# la capitainerie, au-dessus (de CABIN_X à la poupe)
	var c2: Array = []
	for p in contour:
		if (p as Vector3).x <= CABIN_X + 0.01:
			c2.append(p)
	c2.insert(0, Vector3(CABIN_X, 0, -hb_in(CABIN_X, D + 1.0)))
	c2.append(Vector3(CABIN_X, 0, hb_in(CABIN_X, D + 1.0)))
	var h2: Array = []
	for k in range(3):
		h2.append([Vector3(-HL + THICK, QD_Y + 1.6, lerpf(-4.0, 4.0, float(k) / 2.0)), Vector2(1.3, 1.3)])
	h2.append([Vector3(CABIN_X, QD_Y + 1.3, 0.0), Vector2(1.8, 2.4)])
	h2.append([Vector3(CABIN_X, QD_Y + 1.7, -4.0), Vector2(1.2, 1.0)])
	h2.append([Vector3(CABIN_X, QD_Y + 1.7, 4.0), Vector2(1.2, 1.0)])
	c2.append(c2[0])
	_wall_strip(st, faces, c2, QD_Y, PD_Y, true, h2)
	_wall_strip(st, faces, c2, QD_Y, PD_Y, false, h2)
	st.generate_normals()
	st.generate_tangents()
	var m := MeshInstance3D.new()
	m.name = "Chateau_arriere"
	m.mesh = st.commit()
	m.material_override = mat("chateau")
	add_child(m)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	# planchers de la dunette et du toit de la capitainerie
	_deck("Dunette", func(_x): return QD_Y, -69.6, CASTLE_X, func(_x, _z): return false, D + 1.0)
	_deck("Toit_capitainerie", func(_x): return PD_Y, -69.6, CABIN_X, func(_x, _z): return false, D + 1.0)
	# vitres des fenêtres (elles s'allument le soir)
	var glass := QuadMesh.new()
	for h in holes + h2 + f_holes:
		var c: Vector3 = h[0]
		var s: Vector2 = h[1]
		if s.y > 2.0:
			continue
		var g := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = s * 0.92
		g.mesh = qm
		g.material_override = mat("vitre")
		g.position = c
		g.rotation.y = -PI * 0.5 if absf(c.x - (-HL + THICK)) < 0.05 else PI * 0.5
		add_child(g)
	# garde-corps de la dunette et de la capitainerie
	var rails := SurfaceTool.new()
	rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	# (une ouverture là où arrive l'escalier : z = 10,6 sur la dunette, z = -5,6 sur la capitainerie)
	for lvl in [[QD_Y, CASTLE_X, 10.6], [PD_Y, CABIN_X, -5.6]]:
		var yy: float = float(lvl[0])
		var xb: float = float(lvl[1])
		var gap: float = float(lvl[2])
		var w2: float = hb_in(xb, D + 1.0) - 0.2
		for seg in [[-w2, gap - 1.35], [gap + 1.35, w2]]:
			var za: float = float(seg[0])
			var zb: float = float(seg[1])
			if zb - za < 0.2:
				continue
			_box(rails, Vector3(xb - 0.1, yy + 1.0, (za + zb) * 0.5), Vector3(0.14, 0.12, zb - za))
			var zz: float = za
			while zz <= zb + 0.01:
				_box(rails, Vector3(xb - 0.1, yy + 0.5, zz), Vector3(0.1, 1.0, 0.1))
				zz += 0.5
			var cs2 := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(0.2, 1.1, zb - za)
			cs2.shape = bs
			cs2.position = Vector3(xb - 0.1, yy + 0.55, (za + zb) * 0.5)
			body.add_child(cs2)
	rails.generate_normals()
	var rm := MeshInstance3D.new()
	rm.name = "Garde_corps_chateau"
	rm.mesh = rails.commit()
	rm.material_override = mat("chene")
	add_child(rm)


func set_windows(lit: bool) -> void:
	(mat("vitre") as StandardMaterial3D).emission_energy_multiplier = 2.2 if lit else 0.0


# =================================================================== escaliers

func _build_ramps() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in RAMPS:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var w: float = float(r[2])
		var dir: Vector3 = b - a
		var run: float = Vector2(dir.x, dir.z).length()
		var steps: int = int(ceil(absf(dir.y) / 0.32))
		var hd: Vector3 = Vector3(dir.x, 0, dir.z).normalized()
		var sd: Vector3 = hd.cross(Vector3.UP).normalized()
		for k in range(steps):
			var t: float = (float(k) + 0.5) / steps
			var p: Vector3 = a.lerp(b, t)
			_box(st, p - Vector3.UP * 0.12, Vector3(0.0, 0.0, 0.0) + Vector3(w, 0.18, run / steps + 0.08), Basis(sd, Vector3.UP, -hd) if hd.length() > 0.1 else Basis())
		# limons de chaque côté
		for s in [-1.0, 1.0]:
			var ofs: Vector3 = sd * s * (w * 0.5 + 0.08)
			var mid: Vector3 = (a + b) * 0.5 + ofs - Vector3.UP * 0.25
			var length: float = a.distance_to(b)
			var fwd: Vector3 = dir.normalized()
			var up: Vector3 = fwd.cross(sd).normalized()
			if up.y < 0.0:
				up = -up
			_box(st, mid, Vector3(0.16, 0.5, length), Basis(sd, up, -fwd))
			# main courante
			_box(st, mid + up * 1.15, Vector3(0.08, 0.08, length), Basis(sd, up, -fwd))
		# collision : une rampe lisse
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var length2: float = a.distance_to(b)
		bs.size = Vector3(w, 0.3, length2)
		cs.shape = bs
		var f2: Vector3 = dir.normalized()
		var up2: Vector3 = f2.cross(sd).normalized()
		if up2.y < 0.0:
			up2 = -up2
		cs.transform = Transform3D(Basis(sd, up2, -f2), (a + b) * 0.5 - up2 * 0.15)
		body.add_child(cs)
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.name = "Escaliers"
	m.mesh = st.commit()
	m.material_override = mat("chene")
	add_child(m)


# =================================================================== la mâture

func _mast(st: SurfaceTool, x: float, y0: float, y1: float, r0: float, r1: float, broken: bool) -> void:
	var path: Array = []
	var radii: Array = []
	var n: int = 10
	for i in range(n + 1):
		path.append(Vector3(x, lerpf(y0, y1, float(i) / n), 0))
	# tronc conique (les rayons sont gérés par anneaux successifs)
	for i in range(n):
		var ra: float = lerpf(r0, r1, float(i) / n)
		var rb: float = lerpf(r0, r1, float(i + 1) / n)
		var pa: Vector3 = path[i]
		var pb: Vector3 = path[i + 1]
		for s in range(12):
			var a0: float = TAU * s / 12.0
			var a1: float = TAU * (s + 1) / 12.0
			var q := [pa + Vector3(cos(a0) * ra, 0, sin(a0) * ra), pa + Vector3(cos(a1) * ra, 0, sin(a1) * ra), pb + Vector3(cos(a1) * rb, 0, sin(a1) * rb), pb + Vector3(cos(a0) * rb, 0, sin(a0) * rb)]
			var out := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
			_quad(st, [q[0], Vector2(float(s) / 12.0, pa.y * 0.2)], [q[1], Vector2(float(s + 1) / 12.0, pa.y * 0.2)], [q[2], Vector2(float(s + 1) / 12.0, pb.y * 0.2)], [q[3], Vector2(float(s) / 12.0, pb.y * 0.2)], out)
	if broken:
		# le bout cassé : des échardes en pointe
		for s in range(9):
			var a: float = TAU * s / 9.0
			var h: float = _rng.randf_range(0.4, 2.2)
			var base := Vector3(x + cos(a) * r1 * 0.6, y1, sin(a) * r1 * 0.6)
			_box(st, base + Vector3.UP * h * 0.5, Vector3(r1 * 0.5, h, r1 * 0.35), Basis(Vector3.UP, a).rotated(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5)), _rng.randf_range(-0.25, 0.25)))


func _build_masts() -> void:
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var iron := SurfaceTool.new()
	iron.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rope := SurfaceTool.new()
	rope.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_main: float = D + 46.0
	_mast(wood, MAIN_X, HOLD_Y, top_main, 1.05, 0.42, false)
	_mast(wood, FORE_X, HOLD_Y, D + 14.0, 0.9, 0.7, true)
	_mast(wood, MIZZEN_X, D, D + 11.0, 0.75, 0.6, true)
	# cercles de fer tous les deux mètres
	for m in [[MAIN_X, HOLD_Y, top_main, 1.05, 0.42], [FORE_X, HOLD_Y, D + 14.0, 0.9, 0.7], [MIZZEN_X, D, D + 11.0, 0.75, 0.6]]:
		var y: float = float(m[1]) + 1.0
		while y < float(m[2]) - 0.5:
			var t: float = (y - float(m[1])) / (float(m[2]) - float(m[1]))
			var r: float = lerpf(float(m[3]), float(m[4]), t) + 0.04
			var ring: Array = []
			for s in range(13):
				var a: float = TAU * s / 12.0
				ring.append(Vector3(float(m[0]) + cos(a) * r, y, sin(a) * r))
			_tube(iron, ring, 0.05, 4)
			y += 2.0
		# collision : le mât
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = float(m[3])
		cyl.height = float(m[2]) - float(m[1])
		cs.shape = cyl
		cs.position = Vector3(float(m[0]), (float(m[1]) + float(m[2])) * 0.5, 0)
		body.add_child(cs)
	# les hunes (plates-formes) du grand mât
	for top in [[D + 18.0, 3.4], [D + 33.0, 2.3]]:
		var ty: float = float(top[0])
		var tr: float = float(top[1])
		var plat := CylinderMesh.new()
		plat.top_radius = tr
		plat.bottom_radius = tr * 0.85
		plat.height = 0.35
		plat.radial_segments = 20
		var pm := MeshInstance3D.new()
		pm.mesh = plat
		pm.material_override = mat("pont")
		pm.position = Vector3(MAIN_X, ty, 0)
		add_child(pm)
		var cs2 := CollisionShape3D.new()
		var cy2 := CylinderShape3D.new()
		cy2.radius = tr
		cy2.height = 0.35
		cs2.shape = cy2
		cs2.position = pm.position
		body.add_child(cs2)
		var ring2: Array = []
		for s in range(25):
			var a2: float = TAU * s / 24.0
			ring2.append(Vector3(MAIN_X + cos(a2) * (tr - 0.1), ty + 1.0, sin(a2) * (tr - 0.1)))
		_tube(wood, ring2, 0.07, 4)
		for s in range(12):
			var a3: float = TAU * s / 12.0
			_box(wood, Vector3(MAIN_X + cos(a3) * (tr - 0.1), ty + 0.5, sin(a3) * (tr - 0.1)), Vector3(0.08, 1.0, 0.08))
	# la lanterne-phare au sommet
	var lantern := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.55
	lm.bottom_radius = 0.7
	lm.height = 1.3
	lm.radial_segments = 8
	lantern.mesh = lm
	lantern_mat = StandardMaterial3D.new()
	lantern_mat.albedo_color = Color(1.0, 0.85, 0.5)
	lantern_mat.emission_enabled = true
	lantern_mat.emission = Color(1.0, 0.75, 0.35)
	lantern_mat.emission_energy_multiplier = 0.3
	lantern.material_override = lantern_mat
	lantern.position = Vector3(MAIN_X, top_main + 0.7, 0)
	add_child(lantern)
	var cap := MeshInstance3D.new()
	var cmm := CylinderMesh.new()
	cmm.top_radius = 0.05
	cmm.bottom_radius = 0.85
	cmm.height = 0.7
	cmm.radial_segments = 8
	cap.mesh = cmm
	cap.material_override = mat("fer")
	cap.position = Vector3(MAIN_X, top_main + 1.7, 0)
	add_child(cap)
	lantern_light = OmniLight3D.new()
	lantern_light.light_color = Color(1.0, 0.78, 0.45)
	lantern_light.light_energy = 0.0
	lantern_light.omni_range = 40.0
	lantern_light.position = lantern.position
	add_child(lantern_light)
	# vergues
	var yards := [[MAIN_X, D + 16.0, 30.0, 0.38, 0.2], [MAIN_X, D + 31.0, 20.0, 0.28, -0.12]]
	for yd in yards:
		var yy: float = float(yd[1])
		var half: float = float(yd[2]) * 0.5
		var ang: float = float(yd[4])
		var a := Vector3(float(yd[0]) + sin(ang) * half, yy, -cos(ang) * half)
		var b := Vector3(float(yd[0]) - sin(ang) * half, yy, cos(ang) * half)
		var pts: Array = []
		for i in range(9):
			pts.append(a.lerp(b, float(i) / 8.0) + Vector3(0, -absf(float(i) - 4.0) * 0.0, 0))
		_tube(wood, pts, float(yd[3]), 8)
	# la grande voile déchirée, gonflée par le vent, sous la grande vergue
	_build_sail(Vector3(MAIN_X, D + 16.0, 0), 25.0, 9.5, 0.2)
	# la vergue de misaine tombée sur le pont, en travers
	var fy: Array = []
	for i in range(9):
		fy.append(Vector3(29.0 + i * 2.4, deck_y(29.0 + i * 2.4) + 0.32 + i * 0.04, 9.6 - i * 0.35))
	_tube(wood, fy, 0.32, 8)
	# le beaupré
	var bs: Array = []
	for i in range(7):
		bs.append(Vector3(HL - 3.0 + i * 4.2, deck_y(HL) + 1.2 + i * 1.5, 0))
	_tube(wood, bs, 0.6 - 0.05 * 6, 10)
	# gréement : haubans (avec enfléchures), étai, galhaubans
	for side in [-1.0, 1.0]:
		for k in range(6):
			var xb: float = MAIN_X - 5.0 + k * 2.0
			var foot := Vector3(xb, bul_y(xb), side * hb(xb, bul_y(xb)))
			var head := Vector3(MAIN_X + (k - 2.5) * 0.15, D + 17.6, side * 1.2)
			_tube(rope, [foot, head], 0.05, 4)
		# enfléchures (les échelons de corde entre les haubans)
		var y2: float = bul_y(MAIN_X) + 0.8
		while y2 < D + 17.0:
			var t2: float = (y2 - bul_y(MAIN_X)) / (D + 17.6 - bul_y(MAIN_X))
			var za: float = side * lerpf(hb(MAIN_X - 5.0, bul_y(MAIN_X)), 1.2, t2)
			var p0 := Vector3(lerpf(MAIN_X - 5.0, MAIN_X - 0.4, t2), y2, za)
			var p1 := Vector3(lerpf(MAIN_X + 5.0, MAIN_X + 0.4, t2), y2, za)
			_tube(rope, [p0, p1], 0.03, 3)
			y2 += 0.55
		for k2 in range(4):
			var xf2: float = FORE_X - 3.0 + k2 * 2.0
			_tube(rope, [Vector3(xf2, bul_y(xf2), side * hb(xf2, bul_y(xf2))), Vector3(FORE_X, D + 13.0, side * 0.9)], 0.05, 4)
		for k3 in range(3):
			var xg: float = MAIN_X - 12.0 - k3 * 2.0
			_tube(rope, [Vector3(xg, bul_y(xg), side * hb(xg, bul_y(xg))), Vector3(MAIN_X, D + 32.5, side * 0.7)], 0.045, 4)
	_tube(rope, [Vector3(MAIN_X + 0.6, D + 33.0, 0), Vector3(FORE_X, D + 13.8, 0)], 0.07, 5)
	_tube(rope, [Vector3(MAIN_X + 0.6, D + 18.2, 0), Vector3(FORE_X, D + 12.0, 0)], 0.07, 5)
	_tube(rope, [Vector3(FORE_X, D + 13.5, 0), Vector3(HL + 18.0, deck_y(HL) + 12.0, 0)], 0.06, 5)
	# des cordages qui pendent, cassés
	for k4 in range(7):
		var px: float = MAIN_X + _rng.randf_range(-10.0, 10.0)
		var pz: float = _rng.randf_range(-12.0, 12.0)
		var top_y: float = D + 16.0 - 0.3
		var len: float = _rng.randf_range(4.0, 12.0)
		var p_top := Vector3(MAIN_X + _rng.randf_range(-1.0, 1.0) * 6.0, top_y, pz * 0.5)
		_tube(rope, [p_top, p_top + Vector3(_rng.randf_range(-0.6, 0.6), -len * 0.5, 0.3), p_top + Vector3(_rng.randf_range(-1.0, 1.0), -len, 0.5)], 0.035, 3)
	for st_m in [[wood, "mat"], [iron, "fer"], [rope, "corde"]]:
		var s: SurfaceTool = st_m[0]
		s.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "Mature_" + str(st_m[1])
		mi.mesh = s.commit()
		mi.material_override = mat(str(st_m[1]))
		add_child(mi)


## Une voile : une nappe de toile qui pend sous la vergue, creusée par le vent, déchirée.
func _build_sail(top_c: Vector3, width: float, height: float, yaw_s: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu: int = 14
	var nv: int = 8
	var side := Vector3(-sin(yaw_s), 0, cos(yaw_s))
	var fwd := Vector3(cos(yaw_s), 0, sin(yaw_s))
	var grid: Array = []
	for j in range(nv + 1):
		var row: Array = []
		var v: float = float(j) / nv
		for i in range(nu + 1):
			var u: float = float(i) / nu
			var belly: float = sin(u * PI) * sin(v * PI * 0.9) * 2.2
			var p: Vector3 = top_c + side * (u - 0.5) * width * (1.0 - v * 0.08) + Vector3.DOWN * (v * height + 0.4) + fwd * belly
			row.append([p, Vector2(u, v)])
		grid.append(row)
	for j in range(nv):
		for i in range(nu):
			_quad(st, grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i], fwd)
	st.generate_normals()
	st.generate_tangents()
	var m := MeshInstance3D.new()
	m.name = "Grande_voile"
	m.mesh = st.commit()
	m.material_override = mat("voile")
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(m)


## Repères utiles au village (repère du navire).
func hold_floor_x0() -> float:
	# la première abscisse où la cale est sèche (au milieu)
	var x: float = -60.0
	while x < 50.0 and hold_flooded(x, 0.0):
		x += 0.5
	return x

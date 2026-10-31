extends RefCounted
## V91 : la boîte à outils de l'Île de Larsen. Les yourtes (un maillage par quartier, posé en
## MultiMesh : chaque yourte garde sa couleur), et tout ce qui se construit en morceaux simples :
## les bus peints du Camp des Fleurs, les garages en tôle de Rainville, les amplis, les canapés
## défoncés, la rampe de skate, la Grande Scène, les fanions de prières, l'arbre à rubans, la
## corderie… Les morceaux sont rassemblés par matière dans un « lot » (Batch) : un seul maillage
## par quartier et par matière, pour garder peu d'appels de dessin.
## Pour Godot, la face avant d'un triangle tourne dans le sens des aiguilles d'une montre vue de
## devant : chaque triangle est remis dans le bon sens d'après la normale qu'il doit montrer.

const YSHADER := "res://shaders/yourte_v91.gdshader"

## La yourte (repère de la yourte : la porte vers +z)
const R: float = 3.4
const HW: float = 1.8
const HC: float = 3.55
const RC: float = 0.62
const DOOR_W: float = 0.95
const DOOR_H: float = 1.55

static var _cache: Dictionary = {}


# =================================================================== les matières

static func mat(key: String) -> Material:
	return Batch.mat(key)


# =================================================================== le lot (Batch)

class Batch:
	const Decor = preload("res://scripts/decor_v53.gd")
	const MSHADER := "res://shaders/larsen_matiere_v91.gdshader"
	static var _mcache: Dictionary = {}
	var sts: Dictionary = {}

	static func mat(key: String) -> Material:
		if _mcache.has("m_" + key):
			return _mcache["m_" + key]
		var m: Material
		match key:
			"bois":
				m = Decor.wood()
			"bois_gris":
				m = Decor.wood(Color(0.55, 0.52, 0.48))
			"bois_flotte":
				m = Decor.wood(Color(0.9, 0.86, 0.8))
			"bois_peint":
				m = Decor.planks(Color(0.95, 0.55, 0.25))
			"planches":
				m = Decor.planks()
			"planches_gris":
				m = Decor.planks(Color(0.58, 0.56, 0.52))
			"pierre":
				m = Decor.stone()
			"beton":
				m = Decor.stone(Color(0.6, 0.6, 0.58))
			"fer":
				m = Decor.iron()
			"lampe":
				var s := StandardMaterial3D.new()
				s.albedo_color = Color(1.0, 0.85, 0.55)
				s.emission_enabled = true
				s.emission = Color(1.0, 0.72, 0.38)
				s.emission_energy_multiplier = 2.2
				m = s
			"neon":
				var s2 := StandardMaterial3D.new()
				s2.albedo_color = Color(1.0, 0.3, 0.6)
				s2.emission_enabled = true
				s2.emission = Color(1.0, 0.25, 0.55)
				s2.emission_energy_multiplier = 3.0
				s2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m = s2
			"flaque":
				var s4 := StandardMaterial3D.new()
				s4.albedo_color = Color(0.08, 0.075, 0.07, 0.82)
				s4.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				s4.roughness = 0.04
				s4.metallic = 0.35
				s4.metallic_specular = 0.9
				m = s4
			"peau":
				var s3 := StandardMaterial3D.new()
				s3.albedo_color = Color(0.86, 0.78, 0.62)
				s3.roughness = 0.8
				m = s3
			_:
				m = _mshader(key)
		_mcache["m_" + key] = m
		return m


	static func _mshader(key: String) -> ShaderMaterial:
		var s := ShaderMaterial.new()
		s.shader = load(MSHADER)
		var spec: Array = {
			"tole_gris": [0, Color(0.55, 0.57, 0.58), Color.WHITE, 1.0],
			"tole_rouge": [0, Color(0.48, 0.13, 0.1), Color.WHITE, 2.0],
			"tole_vert": [0, Color(0.22, 0.33, 0.27), Color.WHITE, 3.0],
			"tole_bleu": [0, Color(0.2, 0.3, 0.42), Color.WHITE, 4.0],
			"bus_0": [1, Color(0.95, 0.62, 0.15), Color(0.2, 0.55, 0.8), 1.0],
			"bus_1": [1, Color(0.3, 0.62, 0.72), Color(0.97, 0.88, 0.3), 2.0],
			"bus_2": [1, Color(0.62, 0.32, 0.68), Color(0.95, 0.5, 0.25), 3.0],
			"bus_3": [1, Color(0.92, 0.9, 0.82), Color(0.9, 0.25, 0.2), 4.0],
			"grille": [2, Color(0.1, 0.1, 0.1), Color.WHITE, 0.0],
			"grille_beige": [2, Color(0.66, 0.58, 0.44), Color.WHITE, 0.0],
			"vinyle": [3, Color(0.05, 0.05, 0.05), Color.WHITE, 0.0],
			"vinyle_creme": [3, Color(0.8, 0.74, 0.6), Color.WHITE, 0.0],
			"fanion": [4, Color.WHITE, Color.WHITE, 0.0],
			"chrome": [5, Color.WHITE, Color.WHITE, 0.0],
			"pneu": [6, Color.WHITE, Color.WHITE, 0.0],
			"vitre": [7, Color.WHITE, Color.WHITE, 0.0],
			"toile_noire": [8, Color(0.06, 0.06, 0.07), Color(0.08, 0.08, 0.09), 1.0],
			"toile_rayee": [8, Color(0.92, 0.87, 0.76), Color(0.85, 0.28, 0.2), 2.0],
			"toile_bleue": [8, Color(0.9, 0.88, 0.8), Color(0.2, 0.4, 0.7), 3.0],
			"toile_canape": [8, Color(0.44, 0.31, 0.22), Color(0.4, 0.28, 0.2), 4.0],
			"toile_canape_2": [8, Color(0.25, 0.3, 0.22), Color(0.22, 0.27, 0.2), 5.0],
			"paille": [8, Color(0.74, 0.64, 0.4), Color(0.62, 0.52, 0.3), 6.0],
			"corde": [8, Color(0.55, 0.45, 0.3), Color(0.5, 0.4, 0.26), 7.0],
			"ruban": [4, Color.WHITE, Color.WHITE, 0.0],
		}.get(key, [8, Color(0.6, 0.6, 0.6), Color(0.6, 0.6, 0.6), 0.0])
		s.set_shader_parameter("mode", int(spec[0]))
		s.set_shader_parameter("color", spec[1])
		s.set_shader_parameter("color2", spec[2])
		s.set_shader_parameter("seed", float(spec[3]))
		return s




	func _st(key: String) -> SurfaceTool:
		if not sts.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[key] = st
		return sts[key]

	## Un triangle ; n : la normale qu'il doit montrer (le sens est remis d'après elle).
	func tri(key: String, p: Array, nrm: Array, uv: Array, col: Color = Color.WHITE) -> void:
		var st: SurfaceTool = _st(key)
		var face: Vector3 = ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
		var navg: Vector3 = (nrm[0] as Vector3) + (nrm[1] as Vector3) + (nrm[2] as Vector3)
		var order: Array = [0, 2, 1] if face.dot(navg) > 0.0 else [0, 1, 2]
		for k in order:
			st.set_color(col)
			st.set_normal(nrm[k])
			st.set_uv(uv[k])
			st.add_vertex(p[k])

	func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uva := Vector2(0, 0), uvb := Vector2(1, 0), uvc := Vector2(1, 1), uvd := Vector2(0, 1), col: Color = Color.WHITE) -> void:
		tri(key, [a, b, c], [n, n, n], [uva, uvb, uvc], col)
		tri(key, [a, c, d], [n, n, n], [uva, uvc, uvd], col)

	func quad_n(key: String, p: Array, n: Array, uv: Array, col: Color = Color.WHITE) -> void:
		tri(key, [p[0], p[1], p[2]], [n[0], n[1], n[2]], [uv[0], uv[1], uv[2]], col)
		tri(key, [p[0], p[2], p[3]], [n[0], n[2], n[3]], [uv[0], uv[2], uv[3]], col)

	## Une boîte (xf : sa position et son orientation ; size : ses dimensions ; UV en mètres).
	## swap : les UV des côtés tournés d'un quart (les lames d'un volet roulant, couchées).
	func box(key: String, xf: Transform3D, size: Vector3, swap: bool = false) -> void:
		var h: Vector3 = size * 0.5
		var bs: Basis = xf.basis
		for ax in range(3):
			for sg in [-1.0, 1.0]:
				var n := Vector3.ZERO
				n[ax] = sg
				var u := Vector3.ZERO
				var v := Vector3.ZERO
				if ax == 0:
					u = Vector3(0, 0, 1)
					v = Vector3(0, 1, 0)
				elif ax == 1:
					u = Vector3(1, 0, 0)
					v = Vector3(0, 0, 1)
				else:
					u = Vector3(1, 0, 0)
					v = Vector3(0, 1, 0)
				if swap and ax != 1:
					var t: Vector3 = u
					u = v
					v = t
				var c0: Vector3 = n * h
				var hu: float = absf(h.dot(u))
				var hv: float = absf(h.dot(v))
				var pts: Array = []
				var uvs: Array = []
				for cc in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					var lp: Vector3 = c0 + u * cc.x * hu + v * cc.y * hv
					pts.append(xf * lp)
					uvs.append(Vector2((cc.x + 1.0) * hu, (cc.y + 1.0) * hv))
				var wn: Vector3 = (bs * n).normalized()
				quad(key, pts[0], pts[1], pts[2], pts[3], wn, uvs[0], uvs[1], uvs[2], uvs[3])

	## Un cylindre (ou un cône) dressé sur l'axe y local, la base en xf.origin.
	func cyl(key: String, xf: Transform3D, r0: float, r1: float, h: float, sides: int = 12, caps: bool = true) -> void:
		var bs: Basis = xf.basis
		var slope: float = (r0 - r1) / maxf(h, 0.001)
		for i in range(sides):
			var a0: float = TAU * i / sides
			var a1: float = TAU * (i + 1) / sides
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var n0: Vector3 = (bs * (d0 + Vector3.UP * slope)).normalized()
			var n1: Vector3 = (bs * (d1 + Vector3.UP * slope)).normalized()
			var circ: float = TAU * maxf(r0, r1)
			quad_n(key, [xf * (d0 * r0), xf * (d1 * r0), xf * (d1 * r1 + Vector3.UP * h), xf * (d0 * r1 + Vector3.UP * h)],
				[n0, n1, n1, n0], [Vector2(circ * i / sides, 0), Vector2(circ * (i + 1) / sides, 0), Vector2(circ * (i + 1) / sides, h), Vector2(circ * i / sides, h)])
			if caps:
				var up: Vector3 = (bs * Vector3.UP).normalized()
				if r1 > 0.001:
					tri(key, [xf * (Vector3.UP * h), xf * (d0 * r1 + Vector3.UP * h), xf * (d1 * r1 + Vector3.UP * h)], [up, up, up],
						[Vector2(0, 0), Vector2(d0.x, d0.z) * r1, Vector2(d1.x, d1.z) * r1])
				if r0 > 0.001:
					tri(key, [xf.origin, xf * (d1 * r0), xf * (d0 * r0)], [-up, -up, -up],
						[Vector2(0, 0), Vector2(d1.x, d1.z) * r0, Vector2(d0.x, d0.z) * r0])

	## Un tube entre deux points (une corde, un barreau, un tuyau).
	func tube(key: String, a: Vector3, b: Vector3, r: float, sides: int = 6) -> void:
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.001:
			return
		var y: Vector3 = d / l
		var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
		var z: Vector3 = x.cross(y)
		cyl(key, Transform3D(Basis(x, y, z), a), r, r, l, sides, false)

	## Rassemble le lot dans un seul maillage (une surface par matière).
	func commit(parent: Node3D, label: String, shadows: bool = true) -> MeshInstance3D:
		if sts.is_empty():
			return null
		var mesh := ArrayMesh.new()
		for k in sts:
			var st: SurfaceTool = sts[k]
			st.index()
			st.generate_tangents()
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, Batch.mat(str(k)))
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		sts.clear()
		return mi



# =================================================================== la yourte

## Le maillage d'une yourte (style 0 : le Camp des Fleurs ; 1 : Rainville). Surfaces : le mur, le
## toit, le bois, la porte, les cordes, le lambrequin (et le tuyau du poêle, à Rainville).
static func yurt_mesh(style: int) -> ArrayMesh:
	var key := "yurt_%d" % style
	if _cache.has(key):
		return _cache[key]
	var b := Batch.new()
	var N: int = 56
	var door_a: float = PI * 0.5
	var door_half: float = asin(DOOR_W * 0.5 / R) + 0.02
	# --- le mur de feutre (il s'arrête autour de la porte)
	var ys: Array = [0.05, 0.4, 0.9, 1.4, HW]
	for i in range(N):
		var a0: float = TAU * i / N
		var a1: float = TAU * (i + 1) / N
		var am: float = (a0 + a1) * 0.5
		var in_door: bool = absf(wrapf(am - door_a, -PI, PI)) < door_half
		for k in range(ys.size() - 1):
			var y0: float = ys[k]
			var y1: float = ys[k + 1]
			if in_door and y0 < DOOR_H + 0.05:
				continue
			var r0: float = R + 0.03 * sin(PI * y0 / HW)
			var r1: float = R + 0.03 * sin(PI * y1 / HW)
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			b.quad_n("y_mur", [d0 * r0 + Vector3.UP * y0, d1 * r0 + Vector3.UP * y0, d1 * r1 + Vector3.UP * y1, d0 * r1 + Vector3.UP * y1],
				[d0, d1, d1, d0], [Vector2(a0 * R, y0), Vector2(a1 * R, y0), Vector2(a1 * R, y1), Vector2(a0 * R, y1)])
	# --- le toit : de l'avant-toit jusqu'à la couronne, un peu creusé entre les perches
	var rings: Array = []
	var nr: int = 6
	for k2 in range(nr + 1):
		var t: float = float(k2) / nr
		var rr: float = lerpf(R + 0.2, RC, t)
		var yy: float = lerpf(HW - 0.04, HC, t) - 0.1 * sin(PI * t)
		rings.append(Vector2(rr, yy))
	var panels: float = 16.0
	for i2 in range(N):
		var a0: float = TAU * i2 / N
		var a1: float = TAU * (i2 + 1) / N
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var sdist: float = 0.0
		for k3 in range(nr):
			var p0: Vector2 = rings[k3]
			var p1: Vector2 = rings[k3 + 1]
			var seg: float = p0.distance_to(p1)
			var tn := Vector2(p1.y - p0.y, p0.x - p1.x).normalized()      # (radial, haut)
			var n0: Vector3 = (d0 * tn.x + Vector3.UP * tn.y).normalized()
			var n1: Vector3 = (d1 * tn.x + Vector3.UP * tn.y).normalized()
			var u0: float = a0 / TAU * panels
			var u1: float = a1 / TAU * panels
			b.quad_n("y_toit", [d0 * p0.x + Vector3.UP * p0.y, d1 * p0.x + Vector3.UP * p0.y, d1 * p1.x + Vector3.UP * p1.y, d0 * p1.x + Vector3.UP * p1.y],
				[n0, n1, n1, n0], [Vector2(u0, sdist), Vector2(u1, sdist), Vector2(u1, sdist + seg), Vector2(u0, sdist + seg)])
			sdist += seg
		# le dessous de l'avant-toit
		var e0: Vector2 = rings[0]
		b.quad("y_toit", d0 * R + Vector3.UP * (HW + 0.02), d1 * R + Vector3.UP * (HW + 0.02), d1 * e0.x + Vector3.UP * e0.y, d0 * e0.x + Vector3.UP * e0.y, Vector3.DOWN,
			Vector2(a0 / TAU * panels, 0), Vector2(a1 / TAU * panels, 0), Vector2(a1 / TAU * panels, 0.2), Vector2(a0 / TAU * panels, 0.2))
		# --- le lambrequin festonné
		var lr: float = R + 0.205
		b.quad_n("y_lambrequin", [d0 * lr + Vector3.UP * (HW - 0.04), d1 * lr + Vector3.UP * (HW - 0.04), d1 * lr + Vector3.UP * (HW - 0.36), d0 * lr + Vector3.UP * (HW - 0.36)],
			[d0, d1, d1, d0], [Vector2(a0 * lr, 0), Vector2(a1 * lr, 0), Vector2(a1 * lr, 1), Vector2(a0 * lr, 1)])
	# --- la couronne et son petit chapeau de toile
	b.cyl("y_bois", Transform3D(Basis(), Vector3.UP * (HC - 0.12)), RC + 0.05, RC + 0.05, 0.2, 24, false)
	b.cyl("y_bois", Transform3D(Basis(), Vector3.UP * (HC + 0.08)), RC + 0.05, 0.25, 0.001, 24, true)
	b.cyl("y_toit", Transform3D(Basis(), Vector3.UP * (HC + 0.08)), RC + 0.02, 0.0, 0.32, 24, false)
	# --- les cordes : trois tours autour du mur, huit qui descendent du toit
	for yb in [0.45, 1.05, 1.62]:
		for i3 in range(N):
			var a0: float = TAU * i3 / N
			var a1: float = TAU * (i3 + 1) / N
			if absf(wrapf((a0 + a1) * 0.5 - door_a, -PI, PI)) < door_half and yb < DOOR_H:
				continue
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var rr2: float = R + 0.03 * sin(PI * yb / HW) + 0.03
			b.quad_n("y_corde", [d0 * rr2 + Vector3.UP * (yb - 0.025), d1 * rr2 + Vector3.UP * (yb - 0.025), d1 * rr2 + Vector3.UP * (yb + 0.025), d0 * rr2 + Vector3.UP * (yb + 0.025)],
				[d0, d1, d1, d0], [Vector2(a0 * R, 0), Vector2(a1 * R, 0), Vector2(a1 * R, 0.05), Vector2(a0 * R, 0.05)])
	for j in range(8):
		var a: float = TAU * (j + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var side: Vector3 = Vector3.UP.cross(d).normalized() * 0.025
		for k4 in range(nr):
			var p0: Vector2 = rings[k4]
			var p1: Vector2 = rings[k4 + 1]
			var tn := Vector2(p1.y - p0.y, p0.x - p1.x).normalized()
			var nn: Vector3 = (d * tn.x + Vector3.UP * tn.y).normalized()
			var q0: Vector3 = d * p0.x + Vector3.UP * p0.y + nn * 0.025
			var q1: Vector3 = d * p1.x + Vector3.UP * p1.y + nn * 0.025
			b.quad("y_corde", q0 - side, q0 + side, q1 + side, q1 - side, nn, Vector2(0, k4), Vector2(0.05, k4), Vector2(0.05, k4 + 1), Vector2(0, k4 + 1))
	# --- la porte : le cadre, les deux battants peints, le seuil
	var dz: float = R + 0.02
	var dn := Vector3(0, 0, 1)
	b.box("y_bois", Transform3D(Basis(), Vector3(-DOOR_W * 0.5 - 0.06, DOOR_H * 0.5 + 0.06, dz + 0.02)), Vector3(0.12, DOOR_H + 0.14, 0.16))
	b.box("y_bois", Transform3D(Basis(), Vector3(DOOR_W * 0.5 + 0.06, DOOR_H * 0.5 + 0.06, dz + 0.02)), Vector3(0.12, DOOR_H + 0.14, 0.16))
	b.box("y_bois", Transform3D(Basis(), Vector3(0, DOOR_H + 0.15, dz + 0.02)), Vector3(DOOR_W + 0.36, 0.14, 0.18))
	b.box("y_bois", Transform3D(Basis(), Vector3(0, 0.08, dz + 0.1)), Vector3(DOOR_W + 0.3, 0.1, 0.32))
	b.quad("y_porte", Vector3(-DOOR_W * 0.5, 0.13, dz + 0.04), Vector3(DOOR_W * 0.5, 0.13, dz + 0.04), Vector3(DOOR_W * 0.5, DOOR_H + 0.08, dz + 0.04), Vector3(-DOOR_W * 0.5, DOOR_H + 0.08, dz + 0.04), dn,
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	# --- le plancher, posé sur des cales (il descend dans le sol sur une pente)
	b.cyl("y_bois", Transform3D(Basis(), Vector3.UP * -0.9), R + 0.38, R + 0.38, 0.98, 40, true)
	b.box("y_bois", Transform3D(Basis(), Vector3(0, -0.1, R + 0.7)), Vector3(1.4, 0.2, 0.7))
	# --- à Rainville : le tuyau du poêle sort du toit, derrière
	if style == 1:
		var pp: Vector3 = Vector3(0.4, 0, -1.7)
		var ty: float = lerpf(HW, HC, 1.0 - (1.75 - RC) / (R + 0.2 - RC)) - 0.1
		b.cyl("y_metal", Transform3D(Basis(), Vector3(pp.x, ty - 0.4, pp.z)), 0.09, 0.09, 1.7, 12, false)
		b.cyl("y_metal", Transform3D(Basis(), Vector3(pp.x, ty + 1.3, pp.z)), 0.2, 0.05, 0.16, 12, true)
	var mesh := ArrayMesh.new()
	var parts := {"y_mur": 0, "y_toit": 1, "y_bois": 2, "y_porte": 3, "y_corde": 4, "y_lambrequin": 5, "y_metal": 6}
	for k5 in parts:
		if not b.sts.has(k5):
			continue
		var st: SurfaceTool = b.sts[k5]
		st.index()
		st.commit(mesh)
		var sm := ShaderMaterial.new()
		sm.shader = load(YSHADER)
		sm.set_shader_parameter("part", int(parts[k5]))
		sm.set_shader_parameter("style", style)
		sm.set_shader_parameter("wall_h", HW)
		mesh.surface_set_material(mesh.get_surface_count() - 1, sm)
	_cache[key] = mesh
	return mesh


## Pose des yourtes : chaque entrée {"at": Vector3 (le sol, au centre), "face": Vector3 (vers où
## s'ouvre la porte), "s": échelle, "col": Color (le feutre), "seed": 0..1}. Renvoie le nœud.
static func yurts(parent: Node3D, label: String, style: int, list: Array) -> Node3D:
	var root := Node3D.new()
	root.name = label
	parent.add_child(root)
	if list.is_empty():
		return root
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = yurt_mesh(style)
	mm.instance_count = list.size()
	var body := StaticBody3D.new()
	body.name = label + "_murs"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	for i in range(list.size()):
		var e: Dictionary = list[i]
		var f: Vector3 = e["face"]
		f.y = 0.0
		f = f.normalized()
		var s: float = float(e.get("s", 1.0))
		var bs := Basis(Vector3.UP, atan2(f.x, f.z)).scaled(Vector3.ONE * s)
		mm.set_instance_transform(i, Transform3D(bs, e["at"]))
		var c: Color = e["col"]
		mm.set_instance_custom_data(i, Color(c.r, c.g, c.b, float(e.get("seed", 0.5))))
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = (R + 0.15) * s
		sh.height = HC * s
		cs.shape = sh
		cs.position = (e["at"] as Vector3) + Vector3.UP * HC * s * 0.5
		body.add_child(cs)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label + "_yourtes"
	mmi.multimesh = mm
	mmi.visibility_range_end = 520.0
	root.add_child(mmi)
	return root


## Où est la porte d'une yourte (devant le seuil, au sol), pour les portes et les PNJ (V92).
static func yurt_door(at: Vector3, face: Vector3, s: float) -> Vector3:
	var f: Vector3 = Vector3(face.x, 0, face.z).normalized()
	return at + f * (R + 1.0) * s


# =================================================================== les morceaux

static func _xf(at: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), at)


## Un bus peint (vieux bus scolaire devenu maison roulante) ; xf : au sol, l'avant vers +x.
static func bus(b: Batch, xf: Transform3D, paint: String, awning: bool) -> void:
	var L: float = 8.6
	var W: float = 2.45
	b.box(paint, xf * Transform3D(Basis(), Vector3(-0.4, 1.7, 0)), Vector3(L - 1.2, 2.3, W))
	# le toit bombé
	for k in range(4):
		var y: float = 2.85 + 0.22 * sin(PI * (k + 0.5) / 8.0)
		b.box(paint, xf * Transform3D(Basis(), Vector3(-0.4, y, 0)), Vector3(L - 1.25, 0.08, W * cos(PI * 0.5 * float(k) / 4.0) * 0.98))
	# le capot, devant
	b.box(paint, xf * Transform3D(Basis(), Vector3(L * 0.5 - 0.15, 1.15, 0)), Vector3(1.3, 1.2, W - 0.25))
	b.box("chrome", xf * Transform3D(Basis(), Vector3(L * 0.5 + 0.55, 0.75, 0)), Vector3(0.12, 0.2, W + 0.05))
	b.box("chrome", xf * Transform3D(Basis(), Vector3(-L * 0.5 - 0.05, 0.75, 0)), Vector3(0.12, 0.2, W + 0.05))
	b.box("grille", xf * Transform3D(Basis(), Vector3(L * 0.5 + 0.51, 1.2, 0)), Vector3(0.03, 0.6, 1.2))
	for sz in [-1.0, 1.0]:
		b.cyl("lampe", xf * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(L * 0.5 + 0.5, 1.3, sz * 0.85)), 0.13, 0.13, 0.04, 10, true)
	# les vitres : le pare-brise, sept fenêtres de chaque côté, la porte
	b.box("vitre", xf * Transform3D(Basis(), Vector3(L * 0.5 - 0.82, 2.25, 0)), Vector3(0.04, 0.85, W - 0.3))
	for sz2 in [-1.0, 1.0]:
		for i in range(7):
			var x: float = -L * 0.5 + 0.9 + i * 0.95
			if sz2 > 0 and i == 6:
				continue
			b.box("vitre", xf * Transform3D(Basis(), Vector3(x, 2.2, sz2 * (W * 0.5 + 0.005))), Vector3(0.75, 0.62, 0.02))
	b.box("vitre", xf * Transform3D(Basis(), Vector3(L * 0.5 - 1.55, 1.75, W * 0.5 + 0.005)), Vector3(0.8, 1.9, 0.02))
	# les roues
	for wx in [-L * 0.5 + 1.6, L * 0.5 - 0.6]:
		for sz3 in [-1.0, 1.0]:
			var wxf: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(wx, 0.52, sz3 * (W * 0.5 - 0.12)))
			b.cyl("pneu", wxf * Transform3D(Basis(), Vector3(0, -0.17, 0)), 0.52, 0.52, 0.34, 16, true)
			b.cyl("chrome", wxf * Transform3D(Basis(), Vector3(0, 0.17 * sz3, 0)), 0.22, 0.22, 0.02, 10, true)
	# une galerie sur le toit, des caisses, une planche de surf
	b.box("fer", xf * Transform3D(Basis(), Vector3(-1.2, 3.18, W * 0.42)), Vector3(4.0, 0.04, 0.04))
	b.box("fer", xf * Transform3D(Basis(), Vector3(-1.2, 3.18, -W * 0.42)), Vector3(4.0, 0.04, 0.04))
	b.box("planches", xf * Transform3D(Basis(Vector3.UP, 0.1), Vector3(-2.2, 3.3, 0.1)), Vector3(0.9, 0.4, 0.7))
	b.box("toile_bleue", xf * Transform3D(Basis(), Vector3(-0.3, 3.22, 0.0)), Vector3(2.4, 0.06, 0.55))
	if awning:
		# un auvent rayé tendu sur le côté, deux perches
		var a: Vector3 = Vector3(-1.0, 2.75, W * 0.5)
		var tilt := Basis(Vector3.RIGHT, -0.22)
		b.box("toile_rayee", xf * Transform3D(tilt, a + Vector3(0, -0.28, 1.3)), Vector3(4.2, 0.03, 2.7))
		for px in [-3.0, 1.0]:
			b.tube("bois", xf * Vector3(px, 0, W * 0.5 + 2.55), xf * Vector3(px, 2.25, W * 0.5 + 2.55), 0.04)


## Une pile d'amplis : le gros baffle (quatre haut-parleurs derrière la toile), la tête et ses boutons.
static func amp(b: Batch, xf: Transform3D, n_cab: int = 1, creme: bool = false) -> void:
	var vin: String = "vinyle_creme" if creme else "vinyle"
	var gr: String = "grille_beige" if not creme else "grille"
	for i in range(n_cab):
		var y: float = 0.38 + i * 0.77
		b.box(vin, xf * Transform3D(Basis(), Vector3(0, y, 0)), Vector3(0.76, 0.76, 0.38))
		b.box(gr, xf * Transform3D(Basis(), Vector3(0, y, 0.192)), Vector3(0.66, 0.66, 0.01))
	var hy: float = n_cab * 0.77 + 0.14
	b.box(vin, xf * Transform3D(Basis(), Vector3(0, hy, 0)), Vector3(0.76, 0.26, 0.3))
	b.box("chrome", xf * Transform3D(Basis(), Vector3(0, hy, 0.152)), Vector3(0.7, 0.12, 0.01))
	for k in range(7):
		b.cyl("vinyle", xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.28 + k * 0.09, hy, 0.16)), 0.018, 0.018, 0.03, 8, true)


## Un vieux canapé défoncé (dehors, devant les garages).
static func couch(b: Batch, xf: Transform3D, fabric: String) -> void:
	b.box(fabric, xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(2.0, 0.42, 0.9))
	b.box(fabric, xf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.72, -0.38)), Vector3(2.0, 0.65, 0.22))
	for sx in [-1.0, 1.0]:
		b.box(fabric, xf * Transform3D(Basis(), Vector3(sx * 0.92, 0.55, 0.02)), Vector3(0.2, 0.32, 0.86))
	for k in range(2):
		b.box(fabric, xf * Transform3D(Basis(Vector3.FORWARD, 0.04 * (1 - 2 * k)), Vector3(-0.42 + k * 0.84, 0.52, 0.06)), Vector3(0.78, 0.14, 0.7))


## Un garage en tôle ondulée : trois murs, le toit en pente, un volet roulant à moitié levé.
static func garage(b: Batch, xf: Transform3D, tole: String, w: float = 6.0, d: float = 7.0, h: float = 3.1) -> void:
	var t: float = 0.06
	b.box("beton", xf * Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(w + 0.4, 0.14, d + 0.4))
	b.box(tole, xf * Transform3D(Basis(), Vector3(0, h * 0.5, -d * 0.5)), Vector3(w, h, t))
	for sx in [-1.0, 1.0]:
		b.box(tole, xf * Transform3D(Basis(), Vector3(sx * w * 0.5, h * 0.5 + 0.15, 0)), Vector3(t, h + 0.3, d))
	# le toit, en pente vers l'arrière
	b.box("tole_gris", xf * Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3(0, h + 0.2, 0)), Vector3(w + 0.5, 0.05, d + 0.6))
	# l'avant : le linteau, le volet roulant (lames couchées), son coffre
	b.box(tole, xf * Transform3D(Basis(), Vector3(0, h - 0.15, d * 0.5)), Vector3(w, 0.6, t))
	b.box("tole_gris", xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.75, d * 0.5 - 0.05)), Vector3(w - 0.4, h - 1.6, 0.04), true)
	b.box("tole_gris", xf * Transform3D(Basis(), Vector3(0, h - 0.25, d * 0.5 + 0.12)), Vector3(w - 0.3, 0.32, 0.3))
	# dedans : une étagère, des pneus, un vieil établi
	b.box("planches_gris", xf * Transform3D(Basis(), Vector3(-w * 0.5 + 0.4, 1.0, -d * 0.2)), Vector3(0.5, 2.0, 3.0))
	b.box("planches_gris", xf * Transform3D(Basis(), Vector3(w * 0.5 - 0.6, 0.45, -d * 0.3)), Vector3(0.9, 0.9, 2.2))
	for k in range(3):
		b.cyl("pneu", xf * Transform3D(Basis(), Vector3(w * 0.5 - 0.7, 0.12 + k * 0.24, d * 0.25)), 0.38, 0.38, 0.22, 14, true)


## La rampe de skate (un quart de lune en planches, son rebord de métal).
static func ramp(b: Batch, xf: Transform3D, w: float = 5.0) -> void:
	var r: float = 2.4
	var n: int = 8
	for k in range(n):
		var a0: float = PI * 0.5 * float(k) / n
		var a1: float = PI * 0.5 * float(k + 1) / n
		var p0 := Vector3(0, r - r * cos(a0), -r * sin(a0) + r)
		var p1 := Vector3(0, r - r * cos(a1), -r * sin(a1) + r)
		var mid: Vector3 = (p0 + p1) * 0.5
		var ang: float = atan2(p1.y - p0.y, -(p1.z - p0.z))
		b.box("planches", xf * Transform3D(Basis(Vector3.RIGHT, ang), mid), Vector3(w, 0.06, p0.distance_to(p1) + 0.02))
	b.box("planches_gris", xf * Transform3D(Basis(), Vector3(0, r * 0.5, -0.4)), Vector3(w, r, 0.8))
	b.box("planches", xf * Transform3D(Basis(), Vector3(0, r + 0.03, -0.4)), Vector3(w, 0.06, 0.9))
	b.tube("chrome", xf * Vector3(-w * 0.5, r + 0.04, 0.03), xf * Vector3(w * 0.5, r + 0.04, 0.03), 0.04, 8)
	# deux côtés en contreplaqué
	for sx in [-1.0, 1.0]:
		b.box("planches_gris", xf * Transform3D(Basis(), Vector3(sx * w * 0.5, r * 0.45, r * 0.25)), Vector3(0.04, r * 0.9, r * 1.4))


## Un fil de fanions de prières entre deux points (bleu, blanc, rouge, vert, jaune).
static func flags(b: Batch, a: Vector3, c: Vector3, sag: float, n: int) -> void:
	var cols: Array = [Color(0.15, 0.4, 0.85), Color(0.95, 0.95, 0.92), Color(0.88, 0.18, 0.14), Color(0.2, 0.62, 0.3), Color(0.98, 0.82, 0.16)]
	var prev: Vector3 = a
	var side: Vector3 = (c - a)
	side.y = 0.0
	var fw: Vector3 = side.normalized()
	var nrm: Vector3 = fw.cross(Vector3.UP).normalized()
	for i in range(n):
		var t0: float = (i + 0.15) / n
		var t1: float = (i + 0.85) / n
		var p0: Vector3 = a.lerp(c, t0) - Vector3.UP * sag * 4.0 * t0 * (1.0 - t0)
		var p1: Vector3 = a.lerp(c, t1) - Vector3.UP * sag * 4.0 * t1 * (1.0 - t1)
		var hgt: float = 0.32
		var col: Color = cols[i % cols.size()]
		var d0: Vector3 = p0 - Vector3.UP * hgt
		var d1: Vector3 = p1 - Vector3.UP * hgt
		b.quad("fanion", p0, p1, d1, d0, nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), col)
		b.quad("fanion", p0, p1, d1, d0, -nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), col)
	for k in range(12):
		var u0: float = float(k) / 12.0
		var u1: float = float(k + 1) / 12.0
		var q0: Vector3 = a.lerp(c, u0) - Vector3.UP * sag * 4.0 * u0 * (1.0 - u0)
		var q1: Vector3 = a.lerp(c, u1) - Vector3.UP * sag * 4.0 * u1 * (1.0 - u1)
		b.tube("corde", q0, q1, 0.008, 4)


## Une guirlande d'ampoules (elles s'allument le soir : leur matière brille).
static func bulbs(b: Batch, a: Vector3, c: Vector3, sag: float, n: int) -> void:
	for k in range(10):
		var u0: float = float(k) / 10.0
		var u1: float = float(k + 1) / 10.0
		b.tube("corde", a.lerp(c, u0) - Vector3.UP * sag * 4.0 * u0 * (1.0 - u0), a.lerp(c, u1) - Vector3.UP * sag * 4.0 * u1 * (1.0 - u1), 0.007, 4)
	for i in range(n):
		var t: float = (i + 0.5) / n
		var p: Vector3 = a.lerp(c, t) - Vector3.UP * (sag * 4.0 * t * (1.0 - t) + 0.08)
		b.cyl("lampe", Transform3D(Basis(), p - Vector3.UP * 0.05), 0.035, 0.05, 0.1, 6, true)


## Un poteau en bois (pour les fils de fanions, les guirlandes).
static func pole(b: Batch, at: Vector3, h: float, r: float = 0.07) -> Vector3:
	b.cyl("bois", Transform3D(Basis(), at - Vector3.UP * 0.4), r, r * 0.8, h + 0.4, 8, true)
	return at + Vector3.UP * h


## L'arbre à rubans : un grand mât fleuri, et ses rubans qui descendent jusqu'à des piquets en rond.
static func maypole(b: Batch, at: Vector3, h: float = 7.5, rr: float = 5.0) -> void:
	b.cyl("bois_peint", Transform3D(Basis(), at - Vector3.UP * 0.5), 0.13, 0.09, h + 0.5, 12, true)
	b.cyl("bois", Transform3D(Basis(), at + Vector3.UP * (h - 0.3)), 0.5, 0.5, 0.12, 16, true)
	var cols: Array = [Color(0.9, 0.2, 0.15), Color(0.98, 0.65, 0.12), Color(0.98, 0.9, 0.25), Color(0.22, 0.65, 0.35), Color(0.18, 0.45, 0.85), Color(0.6, 0.3, 0.7)]
	var top: Vector3 = at + Vector3.UP * (h - 0.25)
	for i in range(12):
		var a: float = TAU * i / 12.0
		var g: Vector3 = at + Vector3(cos(a), 0.0, sin(a)) * rr + Vector3.UP * 0.05
		var dir: Vector3 = (g - top).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized() * 0.05
		var nrm: Vector3 = dir.cross(side).normalized()
		var col: Color = cols[i % cols.size()]
		var tip: Vector3 = top + Vector3(cos(a), 0, sin(a)) * 0.45
		b.quad("ruban", tip - side, tip + side, g + side, g - side, nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), col)
		b.quad("ruban", tip - side, tip + side, g + side, g - side, -nrm, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), col)
		b.cyl("bois", Transform3D(Basis(), g - Vector3.UP * 0.3), 0.04, 0.03, 0.55, 6, true)
	# la couronne de fleurs en haut
	for k in range(14):
		var a2: float = TAU * k / 14.0
		b.cyl("toile_rayee" if k % 2 == 0 else "bois_peint", Transform3D(Basis(), top + Vector3(cos(a2), 0.02, sin(a2)) * 0.5), 0.09, 0.05, 0.12, 6, true)


## Un djembé (le fût de bois, la peau, les cordes).
static func djembe(b: Batch, at: Vector3) -> void:
	b.cyl("bois_peint", Transform3D(Basis(), at), 0.13, 0.08, 0.3, 12, true)
	b.cyl("bois_peint", Transform3D(Basis(), at + Vector3.UP * 0.3), 0.08, 0.17, 0.32, 12, false)
	b.cyl("peau", Transform3D(Basis(), at + Vector3.UP * 0.62), 0.175, 0.175, 0.02, 12, true)


## Un banc de rondins (un tronc couché sur deux cales).
static func log_bench(b: Batch, at: Vector3, yaw: float, l: float = 2.4) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.cyl("bois", xf * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(l * 0.5, 0.32, 0)), 0.24, 0.22, l, 10, true)
	for sx in [-1.0, 1.0]:
		b.box("bois", xf * Transform3D(Basis(), Vector3(sx * l * 0.35, 0.08, 0)), Vector3(0.18, 0.18, 0.6))


## Un foyer de pierres (le feu lui-même est ajouté par l'île).
static func fire_ring(b: Batch, at: Vector3, r: float = 1.1) -> void:
	for i in range(14):
		var a: float = TAU * i / 14.0
		b.box("pierre", Transform3D(Basis(Vector3.UP, a), at + Vector3(cos(a), 0.06, sin(a)) * r), Vector3(0.36, 0.26, 0.3))
	for k in range(4):
		var a2: float = TAU * k / 4.0 + 0.3
		b.cyl("bois", Transform3D(Basis(Vector3(cos(a2 + PI * 0.5), 0, sin(a2 + PI * 0.5)), 1.1), at + Vector3(cos(a2), 0.02, sin(a2)) * 0.35), 0.07, 0.06, 0.8, 7, true)


## Une meule de chanvre (les tiges coupées dressées en cône pour sécher).
static func stook(b: Batch, at: Vector3, yaw: float) -> void:
	b.cyl("paille", Transform3D(Basis(Vector3.UP, yaw), at - Vector3.UP * 0.05), 0.55, 0.06, 2.1, 10, false)
	b.cyl("corde", Transform3D(Basis(), at + Vector3.UP * 1.25), 0.25, 0.23, 0.08, 10, false)


## Un panneau en bois sur deux pieds (le texte est un Label3D posé par l'île).
static func sign_board(b: Batch, xf: Transform3D, w: float = 1.8, h: float = 0.9) -> void:
	for sx in [-1.0, 1.0]:
		b.box("bois", xf * Transform3D(Basis(), Vector3(sx * (w * 0.5 - 0.1), 0.85, 0)), Vector3(0.1, 1.7 + h * 0.5, 0.1))
	b.box("planches", xf * Transform3D(Basis(), Vector3(0, 1.4 + h * 0.5, 0.06)), Vector3(w, h, 0.06))


static func label(parent: Node3D, text: String, at: Vector3, face: Vector3, size: float = 0.012, col: Color = Color(0.18, 0.1, 0.05)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = size
	l.font_size = 64
	l.outline_size = 0
	l.modulate = col
	l.double_sided = false
	parent.add_child(l)
	l.global_position = at
	var f: Vector3 = Vector3(face.x, 0, face.z).normalized()
	l.global_rotation = Vector3(0, atan2(f.x, f.z), 0)
	return l

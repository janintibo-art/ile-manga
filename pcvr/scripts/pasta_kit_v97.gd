extends RefCounted
## V97 : la boîte à outils de l'Île Al Dente. La passoire géante du Temple-Passoire (un vrai maillage
## percé par son shader : les trous laissent passer le soleil), le Grand Spaghetti Volant (des nouilles
## en tubes qui se balancent, deux boulettes, deux yeux au bout de leurs tiges), et tout ce qui se
## construit en morceaux simples : la fourchette et la cuillère géantes en bronze, le couvercle sacré
## (un gong), la louche géante du cratère, les séchoirs à pâtes, les bancs, l'autel, la fontaine, les
## bannières vert-blanc-rouge, les boulettes de pierre du parvis…
## Les morceaux sont rassemblés par matière dans un « lot » (Batch) : un seul maillage par lieu et par
## matière. Pour Godot, la face avant d'un triangle tourne dans le sens des aiguilles d'une montre vue
## de devant : chaque triangle est remis dans le bon sens d'après la normale qu'il doit montrer.

const Decor = preload("res://scripts/decor_v53.gd")
const MSHADER := "res://shaders/pasta_matiere_v97.gdshader"
const PSHADER := "res://shaders/passoire_v97.gdshader"



# =================================================================== les matières

static func mat(key: String) -> Material:
	return Batch.mat(key)


# =================================================================== le lot (Batch)

class Batch:
	const BDecor = preload("res://scripts/decor_v53.gd")
	const BMSHADER := "res://shaders/pasta_matiere_v97.gdshader"
	const BPSHADER := "res://shaders/passoire_v97.gdshader"
	static var _mcache: Dictionary = {}
	var sts: Dictionary = {}

	static func mat(key: String) -> Material:
		if _mcache.has(key):
			return _mcache[key]
		var m: Material
		match key:
			"bois":
				m = BDecor.wood()
			"bois_clair":
				m = BDecor.wood(Color(0.92, 0.82, 0.66))
			"planches":
				m = BDecor.planks()
			"pierre":
				m = BDecor.stone()
			"calcaire":
				m = BDecor._tex_mat("calcaire_v97", "azur/calcaire.png", "azur/calcaire_n.png", Color(1.0, 0.97, 0.9), 0.45, 0.85)
			"dalles":
				m = BDecor._tex_mat("dalles_v97", "azur/dalles.png", "azur/dalles_n.png", Color(0.98, 0.93, 0.84), 0.32, 0.8)
			"moellons":
				m = BDecor._tex_mat("moellons_v97", "azur/moellons.png", "azur/moellons_n.png", Color(0.95, 0.86, 0.74), 0.4, 0.9)
			"fer":
				m = BDecor.iron()
			"terre_cuite":
				m = BDecor.terracotta()
			"cuivre":
				var c := StandardMaterial3D.new()
				c.albedo_color = Color(0.78, 0.45, 0.3)
				c.metallic = 0.95
				c.roughness = 0.3
				m = c
			"lampe":
				var l := StandardMaterial3D.new()
				l.albedo_color = Color(1.0, 0.85, 0.55)
				l.emission_enabled = true
				l.emission = Color(1.0, 0.72, 0.38)
				l.emission_energy_multiplier = 2.2
				m = l
			"toile_rouge", "toile_blanche", "toile_verte", "toile_creme":
				var t := StandardMaterial3D.new()
				t.albedo_color = {"toile_rouge": Color(0.72, 0.1, 0.1), "toile_blanche": Color(0.93, 0.91, 0.86),
					"toile_verte": Color(0.1, 0.45, 0.22), "toile_creme": Color(0.92, 0.84, 0.66)}[key]
				t.roughness = 0.95
				t.cull_mode = BaseMaterial3D.CULL_DISABLED
				m = t
			"nappe":
				# la nappe à carreaux rouges et blancs (celle des grandes tablées de pâtes)
				var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
				for y in range(64):
					for x in range(64):
						var a: bool = (x / 8) % 2 == 0
						var b: bool = (y / 8) % 2 == 0
						var col: Color = Color(0.94, 0.92, 0.88) if a != b else (Color(0.7, 0.08, 0.08) if a else Color(0.82, 0.5, 0.48))
						img.set_pixel(x, y, col)
				img.generate_mipmaps()
				var n := StandardMaterial3D.new()
				n.albedo_texture = ImageTexture.create_from_image(img)
				n.uv1_scale = Vector3(0.8, 0.8, 0.8)
				n.roughness = 0.9
				n.cull_mode = BaseMaterial3D.CULL_DISABLED
				m = n
			"pates", "pates_seches", "pates_vent", "nouille", "boulette", "oeil", "bronze", "or":
				var s := ShaderMaterial.new()
				s.shader = load(BMSHADER)
				var spec: Array = {"pates": [0, 0.0, 0.0], "pates_seches": [0, 0.0, 1.0], "pates_vent": [0, 0.06, 1.0],
					"nouille": [0, 0.9, 0.0], "boulette": [1, 0.0, 0.0], "oeil": [2, 0.0, 0.0], "bronze": [3, 0.0, 0.0], "or": [4, 0.0, 0.0]}[key]
				s.set_shader_parameter("mode", int(spec[0]))
				s.set_shader_parameter("sway", float(spec[1]))
				s.set_shader_parameter("dry", float(spec[2]))
				m = s
			"inox":
				var p := ShaderMaterial.new()
				p.shader = load(BPSHADER)
				p.set_shader_parameter("holes", false)
				m = p
			_:
				m = BDecor.stone(Color(0.6, 0.6, 0.6))
		_mcache[key] = m
		return m


	func _st(key: String) -> SurfaceTool:
		if not sts.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[key] = st
		return sts[key]

	## Un triangle ; nrm : les normales qu'il doit montrer (le sens est remis d'après elles).
	## col : la couleur des sommets (pour les pâtes : combien elles se balancent).
	func tri(key: String, p: Array, nrm: Array, uv: Array, col: Array = []) -> void:
		var st: SurfaceTool = _st(key)
		var face: Vector3 = ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
		var navg: Vector3 = (nrm[0] as Vector3) + (nrm[1] as Vector3) + (nrm[2] as Vector3)
		var order: Array = [0, 2, 1] if face.dot(navg) > 0.0 else [0, 1, 2]
		for k in order:
			st.set_color(col[k] if not col.is_empty() else Color.WHITE)
			st.set_normal(nrm[k])
			st.set_uv(uv[k])
			st.add_vertex(p[k])

	func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uva := Vector2(0, 0), uvb := Vector2(1, 0), uvc := Vector2(1, 1), uvd := Vector2(0, 1)) -> void:
		tri(key, [a, b, c], [n, n, n], [uva, uvb, uvc])
		tri(key, [a, c, d], [n, n, n], [uva, uvc, uvd])

	func quad_n(key: String, p: Array, n: Array, uv: Array, col: Array = []) -> void:
		var c1: Array = [] if col.is_empty() else [col[0], col[1], col[2]]
		var c2: Array = [] if col.is_empty() else [col[0], col[2], col[3]]
		tri(key, [p[0], p[1], p[2]], [n[0], n[1], n[2]], [uv[0], uv[1], uv[2]], c1)
		tri(key, [p[0], p[2], p[3]], [n[0], n[2], n[3]], [uv[0], uv[2], uv[3]], c2)

	## Une boîte (xf : sa position et son orientation ; size : ses dimensions ; UV en mètres).
	func box(key: String, xf: Transform3D, size: Vector3) -> void:
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
				var c0: Vector3 = n * h
				var hu: float = absf(h.dot(u))
				var hv: float = absf(h.dot(v))
				var pts: Array = []
				var uvs: Array = []
				for cc in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					pts.append(xf * (c0 + u * cc.x * hu + v * cc.y * hv))
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

	## Un tube entre deux points (une corde, un barreau, un brin de pâte).
	func tube(key: String, a: Vector3, b: Vector3, r: float, sides: int = 6, caps: bool = false) -> void:
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.001:
			return
		var y: Vector3 = d / l
		var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
		var z: Vector3 = x.cross(y)
		cyl(key, Transform3D(Basis(x, y, z), a), r, r, l, sides, caps)

	## Une sphère (squash : aplatie ou étirée sur y).
	func sphere(key: String, c: Vector3, r: float, squash: float = 1.0, rings: int = 8, segs: int = 14, basis: Basis = Basis()) -> void:
		for j in range(rings):
			var p0: float = PI * j / rings
			var p1: float = PI * (j + 1) / rings
			for i in range(segs):
				var a0: float = TAU * i / segs
				var a1: float = TAU * (i + 1) / segs
				var dirs: Array = [Vector3(sin(p0) * cos(a0), cos(p0), sin(p0) * sin(a0)), Vector3(sin(p0) * cos(a1), cos(p0), sin(p0) * sin(a1)),
					Vector3(sin(p1) * cos(a1), cos(p1), sin(p1) * sin(a1)), Vector3(sin(p1) * cos(a0), cos(p1), sin(p1) * sin(a0))]
				var pts: Array = []
				var ns: Array = []
				for d in dirs:
					var dd: Vector3 = d as Vector3
					pts.append(c + basis * Vector3(dd.x * r, dd.y * r * squash, dd.z * r))
					ns.append((basis * Vector3(dd.x, dd.y / maxf(squash, 0.01), dd.z)).normalized())
				var uvs: Array = [Vector2(a0 * r, p0 * r), Vector2(a1 * r, p0 * r), Vector2(a1 * r, p1 * r), Vector2(a0 * r, p1 * r)]
				if j == 0:
					tri(key, [pts[0], pts[2], pts[3]], [ns[0], ns[2], ns[3]], [uvs[0], uvs[2], uvs[3]])
				elif j == rings - 1:
					tri(key, [pts[0], pts[1], pts[2]], [ns[0], ns[1], ns[2]], [uvs[0], uvs[1], uvs[2]])
				else:
					quad_n(key, pts, ns, uvs)

	## Un tube qui suit une courbe (une nouille) ; flex : combien chaque point peut se balancer
	## (rangé dans la couleur des sommets, lue par le shader des pâtes).
	func noodle(key: String, pts: Array, r: float, flex: Array = [], sides: int = 6) -> void:
		if pts.size() < 2:
			return
		var frames: Array = []
		var prev_x := Vector3.ZERO
		for i in range(pts.size()):
			var t: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
			var x: Vector3
			if i == 0:
				x = t.cross(Vector3.UP if absf(t.y) < 0.95 else Vector3.RIGHT).normalized()
			else:
				x = (prev_x - t * prev_x.dot(t)).normalized()
				if x.length() < 0.5:
					x = t.cross(Vector3.UP if absf(t.y) < 0.95 else Vector3.RIGHT).normalized()
			prev_x = x
			frames.append([x, t.cross(x).normalized()])
		var acc: float = 0.0
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var seg: float = a.distance_to(b)
			var fa: Array = frames[i]
			var fb: Array = frames[i + 1]
			var ca: Color = Color(float(flex[i]), 0, 0) if not flex.is_empty() else Color.WHITE
			var cb: Color = Color(float(flex[i + 1]), 0, 0) if not flex.is_empty() else Color.WHITE
			for s in range(sides):
				var a0: float = TAU * s / sides
				var a1: float = TAU * (s + 1) / sides
				var na0: Vector3 = (fa[0] as Vector3) * cos(a0) + (fa[1] as Vector3) * sin(a0)
				var na1: Vector3 = (fa[0] as Vector3) * cos(a1) + (fa[1] as Vector3) * sin(a1)
				var nb0: Vector3 = (fb[0] as Vector3) * cos(a0) + (fb[1] as Vector3) * sin(a0)
				var nb1: Vector3 = (fb[0] as Vector3) * cos(a1) + (fb[1] as Vector3) * sin(a1)
				quad_n(key, [a + na0 * r, a + na1 * r, b + nb1 * r, b + nb0 * r], [na0, na1, nb1, nb0],
					[Vector2(float(s) / sides, acc), Vector2(float(s + 1) / sides, acc), Vector2(float(s + 1) / sides, acc + seg), Vector2(float(s) / sides, acc + seg)],
					[ca, ca, cb, cb])
			acc += seg

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


# =================================================================== la passoire géante

## Le profil de la passoire (repère local : le rebord au sol, à y = 0) : une calotte de sphère, de rayon
## Rs, coupée à la hauteur h ; sphere_y : où est le centre de la sphère.
static func colander_profile(radius: float, h: float) -> Dictionary:
	var rs: float = (radius * radius + h * h) / (2.0 * h)
	return {"rs": rs, "sphere_y": h - rs}


## La coque percée (une surface : la matière « passoire » est posée par l'appelant).
static func colander_shell(radius: float, h: float) -> ArrayMesh:
	var pr: Dictionary = colander_profile(radius, h)
	var rs: float = pr["rs"]
	var cy: float = pr["sphere_y"]
	var phi_max: float = acos(clampf(-cy / rs, -1.0, 1.0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 56
	var segs: int = 160
	for j in range(rings):
		var p0: float = phi_max * j / rings
		var p1: float = phi_max * (j + 1) / rings
		for i in range(segs):
			var a0: float = TAU * i / segs
			var a1: float = TAU * (i + 1) / segs
			var q: Array = []
			var uvs: Array = []
			for pa in [[p0, a0], [p0, a1], [p1, a1], [p1, a0]]:
				var ph: float = pa[0]
				var th: float = pa[1]
				q.append(Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th)))
				uvs.append(Vector2(th * rs, ph * rs))
			for k in [0, 2, 1, 0, 3, 2]:
				var d: Vector3 = q[k]
				st.set_normal(d)
				st.set_uv(uvs[k])
				st.add_vertex(Vector3(0, cy, 0) + d * rs)
	st.index()
	st.generate_tangents()
	return st.commit()


## Le rebord (un bourrelet qui s'évase), le pied (un anneau, en haut : la passoire est retournée) et les
## deux anses (deux grandes boucles près du sol) ; en inox.
static func colander_trim(b: Batch, xf: Transform3D, radius: float, h: float) -> void:
	# le rebord : un anneau roulé
	var segs: int = 64
	for i in range(segs):
		var a0: float = TAU * i / segs
		var a1: float = TAU * (i + 1) / segs
		for k in range(6):
			var t0: float = TAU * k / 6.0
			var t1: float = TAU * (k + 1) / 6.0
			var pts: Array = []
			var ns: Array = []
			for at in [[a0, t0], [a1, t0], [a1, t1], [a0, t1]]:
				var dir := Vector3(cos(float(at[0])), 0, sin(float(at[0])))
				var tn: Vector3 = dir * cos(float(at[1])) + Vector3.UP * sin(float(at[1]))
				pts.append(xf * (dir * (radius + 0.25) + Vector3.UP * 0.32 + tn * 0.32))
				ns.append((xf.basis * tn).normalized())
			b.quad_n("inox", pts, ns, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	# le pied, sur le dessus
	var pr: Dictionary = colander_profile(radius, h)
	var rs: float = pr["rs"]
	var cy: float = pr["sphere_y"]
	var fr: float = radius * 0.38
	var fy: float = cy + sqrt(maxf(rs * rs - fr * fr, 0.0))
	b.cyl("inox", xf * Transform3D(Basis(), Vector3(0, fy - 0.6, 0)), fr, fr * 1.04, 1.9, 48, false)
	b.cyl("inox", xf * Transform3D(Basis(), Vector3(0, fy + 1.25, 0)), fr * 1.04, fr * 1.08, 0.12, 48, true)
	# les anses : deux boucles à l'est et à l'ouest de la passoire (dans son repère : ±x)
	for sx in [-1.0, 1.0]:
		var pts2: Array = []
		for k2 in range(13):
			var u: float = PI * k2 / 12.0
			var y: float = 2.2 + sin(u) * 0.2
			var out: float = radius + 0.2 + sin(u) * 3.2
			var side: float = cos(u) * 2.4
			pts2.append(xf * Vector3(sx * out, y + cos(u) * 0.0, side))
		b.noodle("inox", pts2, 0.28, [], 10)


# =================================================================== les objets

## Une fourchette géante, dressée (les dents en haut) ; h : sa hauteur.
static func fork(b: Batch, xf: Transform3D, h: float, key: String = "bronze") -> void:
	var s: float = h / 12.0
	b.cyl(key, xf * Transform3D(Basis(), Vector3(0, 0, 0)), 0.32 * s, 0.25 * s, 6.5 * s, 12)
	b.box(key, xf * Transform3D(Basis(), Vector3(0, 7.0 * s, 0)), Vector3(1.2 * s, 1.0 * s, 0.24 * s))
	b.box(key, xf * Transform3D(Basis(), Vector3(0, 7.9 * s, 0)), Vector3(2.0 * s, 0.9 * s, 0.24 * s))
	for k in range(4):
		var x: float = (-0.75 + k * 0.5) * s
		b.box(key, xf * Transform3D(Basis(), Vector3(x, 9.9 * s, 0)), Vector3(0.24 * s, 3.2 * s, 0.22 * s))
		b.cyl(key, xf * Transform3D(Basis(), Vector3(x, 11.5 * s, 0)), 0.12 * s, 0.02 * s, 0.5 * s, 6)
	b.cyl(key, xf * Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.55 * s, 0.32 * s, 0.4 * s, 12)


## Une cuillère géante, dressée (le cuilleron en haut, son creux tourné vers +z).
static func spoon(b: Batch, xf: Transform3D, h: float, key: String = "bronze") -> void:
	var s: float = h / 12.0
	b.cyl(key, xf * Transform3D(Basis(), Vector3(0, 0, 0)), 0.32 * s, 0.25 * s, 7.6 * s, 12)
	b.cyl(key, xf * Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.55 * s, 0.32 * s, 0.4 * s, 12)
	b.sphere(key, xf * Vector3(0, 9.6 * s, -0.25 * s), 1.6 * s, 1.45, 10, 16, xf.basis * Basis.from_scale(Vector3(1.0, 1.0, 0.32)))


## Le couvercle sacré : un grand couvercle de marmite en cuivre, pendu entre deux poteaux (on frappe
## dessus comme sur un gong).
static func lid_gong(b: Batch, xf: Transform3D) -> void:
	for sx in [-1.0, 1.0]:
		b.box("bois", xf * Transform3D(Basis(), Vector3(sx * 1.9, 1.9, 0)), Vector3(0.3, 3.8, 0.3))
	b.box("bois", xf * Transform3D(Basis(), Vector3(0, 3.85, 0)), Vector3(4.5, 0.32, 0.36))
	for sx2 in [-0.5, 0.5]:
		b.tube("fer", xf * Vector3(sx2, 3.7, 0), xf * Vector3(sx2 * 0.6, 3.05, 0), 0.025, 5)
	var lid := xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.0, 0))
	b.cyl("cuivre", lid, 1.3, 1.1, 0.12, 40, true)
	b.cyl("cuivre", lid * Transform3D(Basis(), Vector3(0, 0.12, 0)), 1.1, 0.35, 0.22, 40, true)
	b.cyl("bois", lid * Transform3D(Basis(), Vector3(0, 0.34, 0)), 0.18, 0.24, 0.22, 12, true)
	# le maillet, pendu au poteau
	b.tube("bois", xf * Vector3(1.75, 1.6, 0.25), xf * Vector3(1.75, 0.5, 0.35), 0.04, 6)
	b.sphere("toile_rouge", xf * Vector3(1.75, 0.45, 0.36), 0.16, 1.0, 6, 10)


## La louche géante du cratère : posée sur un trépied, le cuilleron au-dessus de la sauce.
static func ladle(b: Batch, base: Vector3, toward: Vector3, reach: float = 4.5) -> void:
	var d: Vector3 = Vector3(toward.x, 0, toward.z).normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	var pivot: Vector3 = base + Vector3.UP * 1.6
	for a in [0.0, 2.1, 4.2]:
		var foot: Vector3 = base + (d * cos(a) + side * sin(a)) * 1.0
		b.tube("bois", foot, pivot, 0.07, 6)
	var tip: Vector3 = pivot + d * reach - Vector3.UP * 1.0
	var tail: Vector3 = pivot - d * 2.2 + Vector3.UP * 0.7
	b.tube("inox", tail, tip, 0.09, 8)
	var bowl_c: Vector3 = tip + d * 0.6 - Vector3.UP * 0.45
	b.cyl("inox", Transform3D(Basis(), bowl_c - Vector3.UP * 0.45), 0.25, 0.78, 0.6, 18, true)


## Un séchoir à pâtes : un cadre en bois, des baguettes, et des rideaux de spaghettis qui sèchent.
static func drying_rack(b: Batch, xf: Transform3D, w: float, rng: RandomNumberGenerator) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-0.6, 0.6]:
			b.box("bois_clair", xf * Transform3D(Basis(), Vector3(sx * w * 0.5, 1.15, sz)), Vector3(0.1, 2.3, 0.1))
	for sz2 in [-0.6, 0.0, 0.6]:
		var a: Vector3 = xf * Vector3(-w * 0.5, 2.15, sz2)
		var c: Vector3 = xf * Vector3(w * 0.5, 2.15, sz2)
		b.tube("bois_clair", a, c, 0.035, 6)
		var n: int = int(w * 14.0)
		for k in range(n):
			var x: float = -w * 0.5 + (k + 0.5) * w / n + rng.randf_range(-0.02, 0.02)
			var top: Vector3 = xf * Vector3(x, 2.15, sz2)
			var lng: float = rng.randf_range(0.75, 1.05)
			# un brin plié sur la baguette : deux moitiés qui pendent
			b.noodle("pates_vent", [top + xf.basis * Vector3(0, 0, 0.02), top + xf.basis * Vector3(0, -lng * 0.5, 0.03), top + xf.basis * Vector3(0.01, -lng, 0.035)], 0.011, [0.0, 0.5, 1.0], 3)
			b.noodle("pates_vent", [top - xf.basis * Vector3(0, 0, 0.02), top + xf.basis * Vector3(0, -lng * 0.5, -0.03), top + xf.basis * Vector3(-0.01, -lng * 0.97, -0.035)], 0.011, [0.0, 0.5, 1.0], 3)


## Un banc de temple (en arc de cercle, on le pose plusieurs fois).
static func pew(b: Batch, xf: Transform3D, l: float = 3.2) -> void:
	b.box("bois", xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(l, 0.08, 0.5))
	b.box("bois", xf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.85, -0.24)), Vector3(l, 0.6, 0.06))
	for sx in [-1.0, 1.0]:
		b.box("bois", xf * Transform3D(Basis(), Vector3(sx * (l * 0.5 - 0.15), 0.22, 0)), Vector3(0.08, 0.44, 0.44))


## Une bannière sur un mât : vert, blanc, rouge, et une fourchette brodée au milieu.
static func banner(b: Batch, at: Vector3, face: Vector3, h: float = 6.0) -> void:
	b.cyl("bois", Transform3D(Basis(), at), 0.08, 0.06, h, 8)
	b.sphere("or", at + Vector3.UP * (h + 0.1), 0.14, 1.0, 6, 10)
	var side: Vector3 = Vector3(face.x, 0, face.z).normalized().cross(Vector3.UP)
	var top: Vector3 = at + Vector3.UP * (h - 0.3)
	b.tube("bois", top - side * 0.7, top + side * 0.7, 0.03, 5)
	var keys: Array = ["toile_verte", "toile_blanche", "toile_rouge"]
	for k in range(3):
		var x0: float = -0.66 + k * 0.44
		var a: Vector3 = top + side * x0
		var c: Vector3 = top + side * (x0 + 0.44)
		var n: Vector3 = Vector3(face.x, 0, face.z).normalized()
		b.quad(keys[k], a, c, c - Vector3.UP * 2.6, a - Vector3.UP * 2.6, n, Vector2(0, 0), Vector2(0.44, 0), Vector2(0.44, 2.6), Vector2(0, 2.6))
	# la fourchette brodée (dorée), un peu devant la toile
	var fn: Vector3 = Vector3(face.x, 0, face.z).normalized() * 0.02
	b.box("or", Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), top - Vector3.UP * 1.6 + fn), Vector3(0.06, 0.9, 0.01))
	for k2 in range(3):
		b.box("or", Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), top - Vector3.UP * 0.95 + side * (-0.1 + k2 * 0.1) + fn), Vector3(0.04, 0.35, 0.01))


## Un panneau en bois sur deux pieds (le texte est un Label3D).
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

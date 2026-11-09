extends RefCounted
## V121 : la boîte à outils de Sombreval, la ville morte. Les matières (béton sale, brique,
## rouille, verre brisé, bois pourri, la pierre noire et l'ardoise du château, les fenêtres
## rouges du comte), le « lot » (Batch : des morceaux rassemblés par matière dans un seul
## maillage), et les objets de la ville abandonnée faits de morceaux simples : les carcasses de
## voitures et d'autobus, les réverbères tordus, les tas de gravats, les barricades de planches et
## de sacs de sable, les poubelles renversées, les tombes du vieux cimetière, les morceaux du
## château (remparts crénelés, tours rondes aux toits pointus, le grand donjon).
## Pour Godot, la face avant d'un triangle tourne dans le sens des aiguilles d'une montre vue de
## devant : chaque triangle est remis dans le bon sens d'après la normale qu'il doit montrer.

static var _mcache: Dictionary = {}
const TEX := "res://assets/textures/"


static func _std(albedo: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = albedo
	s.roughness = rough
	s.metallic = metal
	return s


static func _tex(albedo: String, normal: String, tint: Color, scale: float, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(TEX + albedo):
		m.albedo_texture = load(TEX + albedo)
	m.albedo_color = tint
	if normal != "" and ResourceLoader.exists(TEX + normal):
		m.normal_enabled = true
		m.normal_texture = load(TEX + normal)
		m.normal_scale = 0.9
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func _glow(col: Color, energy: float) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = col
	s.emission_enabled = true
	s.emission = col
	s.emission_energy_multiplier = energy
	return s


static func mat(key: String) -> Material:
	if _mcache.has(key):
		return _mcache[key]
	var m: Material
	match key:
		"beton":
			m = _tex("boucan/beton_brut.png", "boucan/beton_brut_n.png", Color(0.5, 0.49, 0.47), 0.3, 0.95)
		"beton_clair":
			m = _tex("boucan/beton.png", "boucan/beton_n.png", Color(0.62, 0.6, 0.57), 0.3, 0.92)
		"brique":
			m = _tex("boucan/brique.png", "boucan/brique_n.png", Color(0.7, 0.56, 0.48), 0.5, 0.92)
		"rouille":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.75, 0.6, 0.5), 0.6, 0.75, 0.35)
		"rouille_rouge":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.62, 0.3, 0.24), 0.6, 0.7, 0.35)
		"rouille_bleue":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.32, 0.38, 0.45), 0.6, 0.7, 0.35)
		"rouille_verte":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.35, 0.42, 0.3), 0.6, 0.7, 0.35)
		"rouille_jaune":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.62, 0.52, 0.25), 0.6, 0.7, 0.35)
		"rouille_creme":
			m = _tex("boucan/acier_rouille.png", "boucan/acier_rouille_n.png", Color(0.7, 0.66, 0.56), 0.6, 0.7, 0.35)
		"pneu":
			m = _std(Color(0.05, 0.05, 0.05), 0.95)
		"verre_brise":
			var v := _std(Color(0.12, 0.14, 0.14, 0.55), 0.1, 0.3)
			v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m = v
		"interieur":
			m = _std(Color(0.03, 0.028, 0.025), 1.0)
		"bois_pourri":
			m = _tex("doors/wood_plain.png", "", Color(0.4, 0.33, 0.26), 1.2, 0.95)
		"bois_sombre":
			m = _tex("doors/wood_plain.png", "", Color(0.28, 0.2, 0.15), 1.2, 0.9)
		"sac_sable":
			m = _tex("terrain/sand.jpg", "terrain/sand_n.png", Color(0.48, 0.42, 0.33), 1.6, 1.0)
		"fer_noir":
			m = _std(Color(0.06, 0.06, 0.065), 0.55, 0.75)
		"metal_gris":
			m = _std(Color(0.38, 0.38, 0.4), 0.5, 0.7)
		"plastique_vert":
			m = _std(Color(0.12, 0.22, 0.12), 0.7)
		"plastique_gris":
			m = _std(Color(0.25, 0.26, 0.27), 0.7)
		"ordures":
			m = _std(Color(0.2, 0.19, 0.16), 1.0)
		"pierre_tombe":
			m = _tex("terrain/stone.jpg", "terrain/stone_n.png", Color(0.45, 0.45, 0.44), 0.8, 0.95)
		"mousse":
			m = _tex("terrain/grass.jpg", "terrain/grass_n.png", Color(0.32, 0.4, 0.22), 0.6, 1.0)
		"pierre_chateau":
			m = _tex("chateau/pierre_chateau.png", "chateau/pierre_chateau_n.png", Color(0.36, 0.35, 0.37), 0.22, 0.92)
		"pierre_chateau_claire":
			m = _tex("chateau/pierre_chateau.png", "chateau/pierre_chateau_n.png", Color(0.5, 0.49, 0.5), 0.22, 0.9)
		"ardoise":
			m = _tex("chateau/ardoise.png", "chateau/ardoise_n.png", Color(0.22, 0.22, 0.27), 0.35, 0.55, 0.15)
		"fenetre_rouge":
			m = _glow(Color(1.0, 0.18, 0.06), 2.4)
		"fenetre_orange":
			m = _glow(Color(1.0, 0.45, 0.12), 1.8)
		"oeil_rouge":
			m = _glow(Color(1.0, 0.05, 0.02), 4.0)
		"tissu_rouge_sombre":
			var t := _std(Color(0.32, 0.03, 0.04), 0.85)
			t.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = t
		"lampe_morte":
			m = _std(Color(0.3, 0.32, 0.3), 0.3, 0.2)
		"lampe_faible":
			m = _glow(Color(1.0, 0.72, 0.4), 1.2)
		"bougie":
			m = _glow(Color(1.0, 0.7, 0.35), 3.0)
		"os":
			m = _std(Color(0.78, 0.74, 0.64), 0.7)
		# V124 : l'intérieur du château du comte
		"parquet":
			m = _tex("maisons/parquet_chevron.png", "", Color(0.46, 0.33, 0.25), 0.55, 0.42)
		"damas":
			m = _tex("maisons/pp_damas_bordeaux.png", "", Color(0.66, 0.52, 0.52), 0.42, 0.85)
		"lambris":
			m = _tex("maisons/lambris_sombre.png", "", Color(0.62, 0.5, 0.42), 0.5, 0.55)
		"marbre_damier":
			var md := _tex("maisons/damier_noir_blanc.png", "", Color(0.6, 0.57, 0.55), 0.3, 0.16)
			md.metallic_specular = 0.8
			m = md
		"tapis_rouge":
			m = _tex("chateau/tapis.png", "", Color(0.72, 0.36, 0.36), 0.45, 1.0)
		"pierre_int":
			m = _tex("chateau/pierre_chateau.png", "chateau/pierre_chateau_n.png", Color(0.56, 0.54, 0.53), 0.32, 0.9)
		"dalles_int":
			m = _tex("chateau/dalles_chateau.png", "chateau/dalles_chateau_n.png", Color(0.52, 0.5, 0.49), 0.3, 0.75)
		"dorure":
			m = _std(Color(0.72, 0.53, 0.26), 0.32, 1.0)
		"dorure_terne":
			m = _std(Color(0.45, 0.36, 0.22), 0.5, 0.85)
		"velours":
			var vv := _std(Color(0.3, 0.025, 0.04), 0.95)
			vv.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = vv
		"velours_noir":
			var vn := _std(Color(0.035, 0.028, 0.032), 0.95)
			vn.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = vn
		"bois_cire":
			m = _tex("doors/wood_plain.png", "", Color(0.32, 0.19, 0.13), 1.0, 0.38)
		"livres":
			m = _tex("chateau/livres.png", "", Color(0.92, 0.9, 0.88), 1.0, 0.75)
		"cuir":
			m = _std(Color(0.2, 0.1, 0.06), 0.55)
		"cire":
			m = _std(Color(0.86, 0.82, 0.72), 0.55)
		"nappe":
			m = _std(Color(0.7, 0.68, 0.62), 0.95)
		"drap_poussiere":
			m = _std(Color(0.58, 0.56, 0.52), 1.0)
		"acier":
			m = _std(Color(0.5, 0.51, 0.53), 0.3, 0.9)
		"acier_noir":
			m = _std(Color(0.12, 0.12, 0.13), 0.38, 0.85)
		"rubis":
			m = _glow(Color(0.95, 0.03, 0.06), 2.6)
		"rubis_eteint":
			m = _std(Color(0.18, 0.02, 0.03), 0.2, 0.3)
		"vitrail_comte":
			var vc := StandardMaterial3D.new()
			if ResourceLoader.exists(TEX + "chateau/vitrail_comte.png"):
				vc.albedo_texture = load(TEX + "chateau/vitrail_comte.png")
				vc.emission_texture = vc.albedo_texture
			vc.emission_enabled = true
			vc.albedo_color = Color(0.75, 0.72, 0.78)
			vc.emission = Color(0.42, 0.44, 0.62)
			vc.emission_energy_multiplier = 0.45
			vc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			vc.alpha_scissor_threshold = 0.5
			vc.cull_mode = BaseMaterial3D.CULL_DISABLED
			vc.roughness = 0.2
			m = vc
		"nuit_fenetre":
			m = _glow(Color(0.16, 0.2, 0.32), 0.6)
		_:
			m = _std(Color(0.4, 0.4, 0.4), 0.8)
	_mcache[key] = m
	return m


# =================================================================== le lot (Batch)

class Batch:
	var sts: Dictionary = {}

	func _st(key: String) -> SurfaceTool:
		if not sts.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[key] = st
		return sts[key]

	func tri(key: String, p: Array, nrm: Array, uv: Array) -> void:
		var st: SurfaceTool = _st(key)
		var face: Vector3 = ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
		var navg: Vector3 = (nrm[0] as Vector3) + (nrm[1] as Vector3) + (nrm[2] as Vector3)
		var order: Array = [0, 2, 1] if face.dot(navg) > 0.0 else [0, 1, 2]
		for k in order:
			st.set_normal(nrm[k])
			st.set_uv(uv[k])
			st.add_vertex(p[k])

	func quad(key: String, p: Array, n: Vector3, uv: Array) -> void:
		tri(key, [p[0], p[1], p[2]], [n, n, n], [uv[0], uv[1], uv[2]])
		tri(key, [p[0], p[2], p[3]], [n, n, n], [uv[0], uv[2], uv[3]])

	func box(key: String, xf: Transform3D, size: Vector3) -> void:
		var h: Vector3 = size * 0.5
		for ax in range(3):
			for sg in [-1.0, 1.0]:
				var n := Vector3.ZERO
				n[ax] = sg
				var u: Vector3 = Vector3(0, 0, 1) if ax == 0 else Vector3(1, 0, 0)
				var v: Vector3 = Vector3(0, 0, 1) if ax == 1 else Vector3(0, 1, 0)
				var c0: Vector3 = n * h
				var hu: float = absf(h.dot(u))
				var hv: float = absf(h.dot(v))
				var pts: Array = []
				var uvs: Array = []
				for cc in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					pts.append(xf * (c0 + u * cc.x * hu + v * cc.y * hv))
					uvs.append(Vector2((cc.x + 1.0) * hu, (cc.y + 1.0) * hv))
				quad(key, pts, (xf.basis * n).normalized(), uvs)

	func box_at(key: String, at: Vector3, size: Vector3, yaw: float = 0.0) -> void:
		box(key, Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * size.y * 0.5), size)

	func cyl(key: String, xf: Transform3D, r0: float, r1: float, h: float, sides: int = 12, caps: bool = true) -> void:
		var bs: Basis = xf.basis
		var slope: float = (r0 - r1) / maxf(h, 0.001)
		var up: Vector3 = (bs * Vector3.UP).normalized()
		for i in range(sides):
			var a0: float = TAU * i / sides
			var a1: float = TAU * (i + 1) / sides
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var n0: Vector3 = (bs * (d0 + Vector3.UP * slope)).normalized()
			var n1: Vector3 = (bs * (d1 + Vector3.UP * slope)).normalized()
			var circ: float = TAU * maxf(r0, r1)
			var p := [xf * (d0 * r0), xf * (d1 * r0), xf * (d1 * r1 + Vector3.UP * h), xf * (d0 * r1 + Vector3.UP * h)]
			var uv := [Vector2(circ * i / sides, 0), Vector2(circ * (i + 1) / sides, 0), Vector2(circ * (i + 1) / sides, h), Vector2(circ * i / sides, h)]
			tri(key, [p[0], p[1], p[2]], [n0, n1, n1], [uv[0], uv[1], uv[2]])
			tri(key, [p[0], p[2], p[3]], [n0, n1, n0], [uv[0], uv[2], uv[3]])
			if caps:
				if r1 > 0.001:
					tri(key, [xf * (Vector3.UP * h), xf * (d0 * r1 + Vector3.UP * h), xf * (d1 * r1 + Vector3.UP * h)], [up, up, up],
						[Vector2(0, 0), Vector2(d0.x, d0.z) * r1, Vector2(d1.x, d1.z) * r1])
				if r0 > 0.001:
					tri(key, [xf.origin, xf * (d1 * r0), xf * (d0 * r0)], [-up, -up, -up],
						[Vector2(0, 0), Vector2(d1.x, d1.z) * r0, Vector2(d0.x, d0.z) * r0])

	func cyl_at(key: String, at: Vector3, r0: float, r1: float, h: float, sides: int = 12) -> void:
		cyl(key, Transform3D(Basis(), at), r0, r1, h, sides)

	func tube(key: String, a: Vector3, b: Vector3, r: float, sides: int = 6) -> void:
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.001:
			return
		var y: Vector3 = d / l
		var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
		var z: Vector3 = x.cross(y)
		cyl(key, Transform3D(Basis(x, y, z), a), r, r, l, sides, false)

	func blob(key: String, c: Vector3, r: Vector3, seg: int = 8) -> void:
		for j in range(int(seg / 2.0)):
			var t0: float = PI * j / (seg / 2.0)
			var t1: float = PI * (j + 1) / (seg / 2.0)
			for i in range(seg):
				var a0: float = TAU * i / seg
				var a1: float = TAU * (i + 1) / seg
				var q := []
				var nn := []
				for tc in [[t0, a0], [t0, a1], [t1, a1], [t1, a0]]:
					var dd := Vector3(sin(tc[0]) * cos(tc[1]), cos(tc[0]), sin(tc[0]) * sin(tc[1]))
					q.append(c + dd * r)
					nn.append((dd / r).normalized())
				tri(key, [q[0], q[1], q[2]], [nn[0], nn[1], nn[2]], [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE])
				tri(key, [q[0], q[2], q[3]], [nn[0], nn[2], nn[3]], [Vector2.ZERO, Vector2.ONE, Vector2.DOWN])

	func commit(parent: Node3D, label: String, shadows: bool = true, vis_end: float = 0.0) -> MeshInstance3D:
		if sts.is_empty():
			return null
		var mesh := ArrayMesh.new()
		for k in sts:
			var st: SurfaceTool = sts[k]
			st.index()
			st.generate_tangents()
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, load("res://scripts/sombreval_kit_v121.gd").mat(str(k)))
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if vis_end > 0.0:
			mi.visibility_range_end = vis_end
			mi.visibility_range_end_margin = 15.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mi)
		sts.clear()
		return mi


# =================================================================== la rue abandonnée

const CAR_PAINTS := ["rouille_rouge", "rouille_bleue", "rouille_verte", "rouille_jaune", "rouille_creme", "rouille"]


## Une carcasse de voiture (yaw : sa direction ; roll : couchée sur le flanc, ou retournée)
static func car(b: Batch, at: Vector3, yaw: float, paint: String, roll: float = 0.0, rng: RandomNumberGenerator = null) -> void:
	var bs := Basis(Vector3.UP, yaw)
	if absf(roll) > 0.01:
		bs = bs * Basis(Vector3.FORWARD, roll)
	var lift: float = 0.0 if absf(roll) < 0.01 else (0.85 if absf(roll) < 2.0 else 1.25)
	var o: Vector3 = at + Vector3.UP * lift
	var xf := Transform3D(bs, o)
	var flat: bool = rng != null and rng.randf() < 0.5
	var dy: float = 0.0 if not flat else -0.12
	b.box(paint, xf * Transform3D(Basis(), Vector3(0, 0.62 + dy, 0)), Vector3(1.75, 0.62, 4.2))
	b.box(paint, xf * Transform3D(Basis(), Vector3(0, 1.18 + dy, -0.15)), Vector3(1.6, 0.5, 2.1))
	b.box("verre_brise", xf * Transform3D(Basis(), Vector3(0, 1.18 + dy, -0.15)), Vector3(1.62, 0.4, 1.8))
	b.box("interieur", xf * Transform3D(Basis(), Vector3(0, 1.0 + dy, -0.15)), Vector3(1.5, 0.3, 2.0))
	b.box("fer_noir", xf * Transform3D(Basis(), Vector3(0, 0.5 + dy, 2.12)), Vector3(1.7, 0.22, 0.12))
	b.box("fer_noir", xf * Transform3D(Basis(), Vector3(0, 0.5 + dy, -2.12)), Vector3(1.7, 0.22, 0.12))
	b.box("lampe_morte", xf * Transform3D(Basis(), Vector3(0.6, 0.72 + dy, 2.11)), Vector3(0.3, 0.14, 0.04))
	b.box("lampe_morte", xf * Transform3D(Basis(), Vector3(-0.6, 0.72 + dy, 2.11)), Vector3(0.3, 0.14, 0.04))
	for wx in [-0.82, 0.82]:
		for wz in [-1.35, 1.35]:
			if flat and wz < 0.0 and wx < 0.0:
				continue
			var wxf := xf * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(wx, 0.34 + dy * 0.5, wz))
			b.cyl("pneu", wxf * Transform3D(Basis(), Vector3(0, -0.11, 0)), 0.34, 0.34, 0.22, 10)


## Un autobus abandonné, sans vitres
static func bus(b: Batch, at: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	b.box("rouille_jaune", xf * Transform3D(Basis(), Vector3(0, 1.75, 0)), Vector3(2.5, 2.6, 11.0))
	b.box("interieur", xf * Transform3D(Basis(), Vector3(0, 2.1, 0)), Vector3(2.52, 1.1, 10.0))
	b.box("rouille", xf * Transform3D(Basis(), Vector3(0, 3.1, 0)), Vector3(2.4, 0.1, 10.8))
	for wz in [-4.0, 3.6]:
		for wx in [-1.12, 1.12]:
			var wxf := xf * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(wx, 0.5, wz))
			b.cyl("pneu", wxf * Transform3D(Basis(), Vector3(0, -0.15, 0)), 0.5, 0.5, 0.3, 10)


## Un réverbère tordu (bend : son inclinaison, en radians)
static func lamp(b: Batch, at: Vector3, face: Vector3, bend: float) -> void:
	var side: Vector3 = face.cross(Vector3.UP).normalized()
	var bs := Basis(side, bend)
	var top: Vector3 = at + bs * Vector3(0, 6.5, 0)
	b.tube("fer_noir", at, at + bs * Vector3(0, 3.2, 0), 0.09, 8)
	b.tube("fer_noir", at + bs * Vector3(0, 3.2, 0), top, 0.07, 8)
	var arm: Vector3 = top + bs * (face * 1.4)
	b.tube("fer_noir", top, arm, 0.05, 6)
	b.box("fer_noir", Transform3D(bs * Basis(Vector3.UP, atan2(face.x, face.z)), arm + Vector3.DOWN * 0.1), Vector3(0.4, 0.14, 0.7))
	b.box("lampe_morte", Transform3D(bs * Basis(Vector3.UP, atan2(face.x, face.z)), arm + Vector3.DOWN * 0.18), Vector3(0.32, 0.03, 0.6))


## Un tas de gravats (des blocs de béton et des briques, quelques barres de fer)
static func rubble(b: Batch, at: Vector3, r: float, rng: RandomNumberGenerator) -> void:
	for k in range(int(4 + r * 3.0)):
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf()) * r
		var p: Vector3 = at + Vector3(cos(a) * d, 0, sin(a) * d)
		var s: float = rng.randf_range(0.4, 1.3) * (1.0 - d / (r * 1.4))
		var key: String = ["beton", "beton", "brique", "beton_clair"][rng.randi() % 4]
		var xf := Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))), p + Vector3.UP * s * 0.25)
		b.box(key, xf, Vector3(s * rng.randf_range(0.8, 1.8), s * rng.randf_range(0.4, 0.9), s * rng.randf_range(0.8, 1.6)))
	b.blob("beton", at + Vector3.UP * r * 0.08, Vector3(r * 0.9, r * 0.38, r * 0.8), 8)
	for k2 in range(rng.randi_range(1, 3)):
		var p2: Vector3 = at + Vector3(rng.randf_range(-r, r) * 0.5, 0.3, rng.randf_range(-r, r) * 0.5)
		b.tube("rouille", p2, p2 + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.8, 1.6), rng.randf_range(-0.6, 0.6)), 0.025, 5)


## Une barricade : des planches clouées, des sacs de sable, un tonneau
static func barricade(b: Batch, at: Vector3, yaw: float, w: float, rng: RandomNumberGenerator) -> void:
	var bs := Basis(Vector3.UP, yaw)
	for k in range(int(w / 0.55)):
		var x: float = -w * 0.5 + 0.3 + k * 0.55
		b.box("sac_sable", Transform3D(bs, at + bs * Vector3(x, 0.18, 0)), Vector3(0.52, 0.32, 0.36))
		if k % 2 == 0:
			b.box("sac_sable", Transform3D(bs, at + bs * Vector3(x + 0.27, 0.5, 0)), Vector3(0.52, 0.3, 0.34))
	for k2 in range(3):
		var tilt: float = rng.randf_range(-0.2, 0.2)
		b.box("bois_pourri", Transform3D(bs * Basis(Vector3.FORWARD, tilt), at + bs * Vector3(0, 0.95 + k2 * 0.32, -0.25)), Vector3(w, 0.18, 0.05))
	for px in [-w * 0.5 + 0.2, w * 0.5 - 0.2]:
		b.box("bois_pourri", Transform3D(bs, at + bs * Vector3(px, 0.8, -0.28)), Vector3(0.1, 1.6, 0.1))


## Une poubelle renversée et ce qu'elle a vomi
static func trash(b: Batch, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * 0.5), at + Vector3.UP * 0.32)
	b.cyl(["plastique_vert", "plastique_gris"][rng.randi() % 2], xf * Transform3D(Basis(), Vector3(0, -0.5, 0)), 0.32, 0.36, 1.0, 10)
	for k in range(4):
		b.blob("ordures", at + Basis(Vector3.UP, yaw) * Vector3(rng.randf_range(-0.4, 0.4), 0.06, rng.randf_range(0.6, 1.6)), Vector3(0.25, 0.1, 0.2), 6)


## Une tombe (une stèle penchée, une dalle, de la mousse)
static func grave(b: Batch, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var tilt := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, rng.randf_range(-0.25, 0.15)) * Basis(Vector3.FORWARD, rng.randf_range(-0.15, 0.15))
	var hgt: float = rng.randf_range(0.8, 1.3)
	b.box("pierre_tombe", Transform3D(tilt, at + Vector3.UP * hgt * 0.5), Vector3(0.6, hgt, 0.14))
	if rng.randf() < 0.5:
		b.cyl("pierre_tombe", Transform3D(tilt * Basis(Vector3.RIGHT, PI * 0.5), at + Vector3.UP * hgt - tilt * Vector3(0, 0, 0.07)), 0.3, 0.3, 0.14, 12)
	b.box("pierre_tombe", Transform3D(Basis(Vector3.UP, yaw), at + Basis(Vector3.UP, yaw) * Vector3(0, 0.08, 1.0)), Vector3(0.8, 0.16, 1.8))
	b.box("mousse", Transform3D(Basis(Vector3.UP, yaw), at + Basis(Vector3.UP, yaw) * Vector3(0, 0.17, 1.0)), Vector3(0.7, 0.03, 1.6))


# =================================================================== le château du comte

## Un rempart crénelé entre deux points (au sol, base y), épaisseur ep, hauteur h
static func rampart(b: Batch, a: Vector3, c: Vector3, h: float, ep: float) -> void:
	var d: Vector3 = c - a
	d.y = 0.0
	var l: float = d.length()
	var yaw: float = atan2(d.x, d.z)
	var bs := Basis(Vector3.UP, yaw)
	var mid: Vector3 = (a + c) * 0.5
	b.box("pierre_chateau", Transform3D(bs, mid + Vector3.UP * (h * 0.5 - 1.0)), Vector3(ep, h + 2.0, l))
	# le chemin de ronde, les créneaux
	var n: int = int(l / 1.6)
	for k in range(n):
		if k % 2 == 1:
			continue
		var z: float = -l * 0.5 + (k + 0.5) * (l / n)
		for side in [-1.0, 1.0]:
			b.box("pierre_chateau", Transform3D(bs, mid + bs * Vector3(side * (ep * 0.5 - 0.25), h + 0.55, z)), Vector3(0.5, 1.1, l / n))
	# des contreforts, des meurtrières
	for k2 in range(int(l / 9.0)):
		var z2: float = -l * 0.5 + (k2 + 0.5) * (l / int(l / 9.0))
		b.box("pierre_chateau", Transform3D(bs, mid + bs * Vector3(ep * 0.5 + 0.5, h * 0.35 - 1.0, z2)), Vector3(1.0, h * 0.7 + 2.0, 1.4))
		b.box("interieur", Transform3D(bs, mid + bs * Vector3(ep * 0.5 + 0.02, h * 0.62, z2 + 2.2)), Vector3(0.05, 1.3, 0.22))


## Une tour ronde : le fût, le cordon, les mâchicoulis, et le toit pointu d'ardoise
static func tower(b: Batch, at: Vector3, r: float, h: float, roof: float, lit: bool, rng: RandomNumberGenerator) -> Array:
	b.cyl("pierre_chateau", Transform3D(Basis(), at + Vector3.DOWN * 2.0), r * 1.08, r, h + 2.0, 18)
	b.cyl("pierre_chateau_claire", Transform3D(Basis(), at + Vector3.UP * (h - 1.2)), r + 0.45, r + 0.55, 1.2, 18)
	b.cyl("ardoise", Transform3D(Basis(), at + Vector3.UP * h), r + 0.7, 0.05, roof, 18)
	b.tube("fer_noir", at + Vector3.UP * (h + roof - 0.3), at + Vector3.UP * (h + roof + 2.2), 0.05, 6)
	var lights: Array = []
	# des fenêtres étroites (certaines rougeoient)
	for k in range(int(h / 6.0)):
		var a: float = rng.randf() * TAU
		var y: float = 4.0 + k * 6.0 + rng.randf_range(-1.0, 1.0)
		if y > h - 2.5:
			break
		var dir := Vector3(cos(a), 0, sin(a))
		var key: String = "fenetre_rouge" if lit and rng.randf() < 0.55 else "interieur"
		b.box(key, Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), at + dir * (r - 0.05) + Vector3.UP * y), Vector3(0.5, 1.4, 0.2))
		if key == "fenetre_rouge":
			lights.append(at + dir * (r + 0.8) + Vector3.UP * y)
	return lights
